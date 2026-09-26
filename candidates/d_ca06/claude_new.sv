// =============================================================================
// queue -- d_ca06 concurrent multi-port FIFO
//
// Contract behaviour (F2-F7):
//   * occupancy = tail - head, except tail == head -> DEPTH if full_q else 0
//   * write_accept[i] = i < vacancy (independent of write_valid)
//   * accepted writes compact from tail in port order
//   * head advances to one past the highest accepted-and-valid read port;
//     skipped entries are discarded
//   * full_q is rewritten only on cycles where writes != reads
//   * synchronous active-low reset clears pointers, flag and every entry
//
// Datapath (P3 / G4 choice): the PORTS consecutive addresses touched from a
// pointer land in PORTS distinct banks under NB-way low-order interleaving
// (NB = 2^ceil(log2 PORTS)). So
//   * read : NB bank muxes of DEPTH/NB:1 (bank j reads the row holding the
//            unique address in [head, head+NB) congruent to j), then an NB:1
//            crossbar per port -- instead of PORTS full DEPTH:1 muxes;
//   * write: one datum is pre-selected per bank (AND-OR over the ports whose
//            compacted position lands in that bank), so every storage entry
//            sees a single hold-or-load choice -- instead of a PORTS:1 data
//            mux on every entry.
// Both bank address sets need only one row incrementer each.
// =============================================================================
module queue #(
    parameter int  DW        = 64,
    parameter type T         = logic [DW-1:0],
    parameter int  PTR_WIDTH = 7,
    parameter int  PORTS     = 3
) (
    input  logic             clk,
    input  logic             rst_n,

    input  T     [PORTS-1:0] write_data,
    input  logic [PORTS-1:0] write_valid,
    output logic [PORTS-1:0] write_accept,

    output T     [PORTS-1:0] read_data,
    output logic [PORTS-1:0] read_valid,
    input  logic [PORTS-1:0] read_accept
);

  // ---------------------------------------------------------------------------
  // Derived parameters
  // ---------------------------------------------------------------------------
  localparam int unsigned DEPTH      = 1 << PTR_WIDTH;
  localparam int unsigned NPORT      = PORTS;
  localparam int unsigned OW         = PTR_WIDTH + 1;                   // occupancy width
  localparam int unsigned CW         = $clog2(PORTS + 1);               // per-cycle count width
  localparam int unsigned LOG_NB_RAW = (PORTS > 1) ? $clog2(PORTS) : 0;
  localparam int unsigned LOG_NB     = (int'(LOG_NB_RAW) < PTR_WIDTH) ? LOG_NB_RAW : PTR_WIDTH;
  localparam int unsigned NB         = 1 << LOG_NB;                     // banks

  typedef logic [PTR_WIDTH-1:0] ptr_t;

  localparam ptr_t NB_MASK = ptr_t'(NB - 1);

  // ---------------------------------------------------------------------------
  // Declarations
  // ---------------------------------------------------------------------------
  T                     mem [DEPTH];
  ptr_t                 head_q, tail_q;
  logic                 full_q;

  logic [OW-1:0]        occ, vac;

  logic [PORTS-1:0]           stored;
  logic [PORTS-1:0][CW-1:0]   rank;
  logic [CW-1:0]              wcnt, n_w, n_r;

  ptr_t                 head_lo, head_hi, tail_lo, tail_hi;
  ptr_t [NB-1:0]        raddr, waddr, woff;
  T     [NB-1:0]        bank_rd, bank_wd;
  logic [NB-1:0]        bank_we;

  // ---------------------------------------------------------------------------
  // Occupancy, acceptance, validity (F2, F3, F5)
  // ---------------------------------------------------------------------------
  always_comb begin
    occ = {1'b0, tail_q - head_q};
    if (tail_q == head_q && full_q) occ = OW'(DEPTH);
    vac = OW'(DEPTH) - occ;
    for (int unsigned i = 0; i < NPORT; i++) begin
      write_accept[i] = i < 32'(vac);
      read_valid[i]   = i < 32'(occ);
    end
  end

  // ---------------------------------------------------------------------------
  // Write compaction (F4): rank = number of lower ports stored this cycle
  // ---------------------------------------------------------------------------
  always_comb begin
    wcnt = '0;
    for (int unsigned i = 0; i < NPORT; i++) begin
      stored[i] = write_valid[i] & write_accept[i];
      rank[i]   = wcnt;
      wcnt      = wcnt + CW'(stored[i]);
    end
    n_w = wcnt;
  end

  // ---------------------------------------------------------------------------
  // Head advance (F6): one past the highest accepted-and-valid port
  // ---------------------------------------------------------------------------
  always_comb begin
    n_r = '0;
    for (int unsigned i = 0; i < NPORT; i++) begin
      if (read_accept[i] && read_valid[i]) n_r = CW'(i + 1);
    end
  end

  // ---------------------------------------------------------------------------
  // Bank addressing: bank j serves the address in [ptr, ptr+NB) that is
  // congruent to j; its row is ptr's row, or the next one if j < ptr's bank.
  // ---------------------------------------------------------------------------
  always_comb begin
    head_lo = head_q & NB_MASK;
    head_hi = head_q >> LOG_NB;
    tail_lo = tail_q & NB_MASK;
    tail_hi = tail_q >> LOG_NB;
    for (int unsigned j = 0; j < NB; j++) begin
      raddr[j] = ((head_hi + ptr_t'(ptr_t'(j) < head_lo)) << LOG_NB) | ptr_t'(j);
      waddr[j] = ((tail_hi + ptr_t'(ptr_t'(j) < tail_lo)) << LOG_NB) | ptr_t'(j);
      woff[j]  = (ptr_t'(j) - tail_lo) & NB_MASK;            // compacted position landing here
    end
  end

  // ---------------------------------------------------------------------------
  // Read datapath (F5, A1)
  // ---------------------------------------------------------------------------
  always_comb begin
    for (int unsigned j = 0; j < NB; j++) bank_rd[j] = mem[raddr[j]];
    for (int unsigned i = 0; i < NPORT; i++)
      read_data[i] = bank_rd[(head_lo + ptr_t'(i)) & NB_MASK];
  end

  // ---------------------------------------------------------------------------
  // Write datapath: one datum per bank (at most one stored port matches)
  // ---------------------------------------------------------------------------
  always_comb begin
    for (int unsigned j = 0; j < NB; j++) begin
      bank_we[j] = 32'(woff[j]) < 32'(n_w);
      bank_wd[j] = '0;
      for (int unsigned i = 0; i < NPORT; i++) begin
        if (stored[i] && (32'(rank[i]) == 32'(woff[j])))
          bank_wd[j] = bank_wd[j] | write_data[i];
      end
    end
  end

  // ---------------------------------------------------------------------------
  // State (V3: synchronous reset clears pointers, flag and storage)
  // ---------------------------------------------------------------------------
  always_ff @(posedge clk) begin
    if (!rst_n) begin
      mem <= '{default: '0};
    end else begin
      for (int unsigned j = 0; j < NB; j++) begin
        if (bank_we[j]) mem[waddr[j]] <= bank_wd[j];
      end
    end
  end

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      head_q <= '0;
      tail_q <= '0;
      full_q <= 1'b0;
    end else begin
      head_q <= head_q + ptr_t'(n_r);
      tail_q <= tail_q + ptr_t'(n_w);
      if (n_w != n_r) full_q <= (n_w > n_r);     // F7
    end
  end

endmodule