// =============================================================================
// async_fifo_cdc.sv
//
// Asynchronous FIFO across two unrelated clocks.
//
// The only things that cross the boundary are the two pointers, each Gray
// coded so exactly one bit changes per increment, each resynchronised through
// SYNC_STAGES flops in the receiving domain before it is used. A value latched
// mid-transition on a Gray counter is either the old value or the new one --
// never a third value that was never present -- so the comparisons below are
// always made against a pointer position the other side genuinely occupied at
// some point.
//
// Both comparisons are conservative in the safe direction, which is what makes
// this correct at every clock ratio rather than at the ones that happen to be
// simulated:
//   * the write side sees a read pointer that is at worst STALE, so it can only
//     ever think the FIFO is FULLER than it is -- it may backpressure a cycle
//     early, never a cycle late (C4).
//   * the read side sees a write pointer that is at worst STALE, so it can only
//     ever think the FIFO is EMPTIER than it is -- it may hold rd_valid low a
//     cycle longer, never assert it for a beat that has not landed (C5).
//
// The payload is not synchronised and does not need to be: an entry is only
// read once the write pointer covering it has crossed SYNC_STAGES flops, by
// which time the memory write completed many source-clock edges earlier.
//
// Storage is the FIFO and nothing else -- no input registration, no output
// pipeline, no prefetch (B1).
//
// Reset: asserted together (R1), released per domain (R2). Each domain's
// pointer, and each domain's synchroniser chain, is reset by that domain's
// own reset, so whichever side leaves reset first sees the other side's
// pointer as zero: the write side can fill but not overflow, and the read side
// reads empty and holds rd_valid low. Warm reset of one domain alone is out of
// scope (R3) and is not supported.
// =============================================================================

module async_fifo_cdc #(
    parameter int DATA_W      = 32,   // 8 / 32 / 64
    parameter int LOG_DEPTH   = 3,    // 2 / 3 / 4  -> depth 4 / 8 / 16
    parameter int SYNC_STAGES = 2     // 2 / 3
) (
    // ---- write domain ----
    input  logic              wr_clk,
    input  logic              wr_rst_n,
    input  logic              wr_valid,
    output logic              wr_ready,
    input  logic [DATA_W-1:0] wr_data,

    // ---- read domain ----
    input  logic              rd_clk,
    input  logic              rd_rst_n,
    output logic              rd_valid,
    input  logic              rd_ready,
    output logic [DATA_W-1:0] rd_data
);

  localparam int DEPTH = 1 << LOG_DEPTH;
  localparam int PW    = LOG_DEPTH + 1;   // one extra bit distinguishes full from empty
  localparam logic [PW-1:0] PTR_ONE = {{(PW-1){1'b0}}, 1'b1};

  function automatic logic [PW-1:0] b2g(input logic [PW-1:0] b);
    return b ^ (b >> 1);
  endfunction

  function automatic logic [PW-1:0] g2b(input logic [PW-1:0] g);
    logic [PW-1:0] b;
    int i;
    b = '0;
    for (i = PW-1; i >= 0; i--) begin
      if (i == PW-1) b[i] = g[i];
      else           b[i] = b[i+1] ^ g[i];
    end
    return b;
  endfunction

  logic [DATA_W-1:0] mem [DEPTH];

  logic [PW-1:0] wbin, wgray;
  logic [PW-1:0] rbin, rgray;

  // synchroniser chains: [0] is the first flop in the receiving domain
  logic [PW-1:0] wgray_sync [SYNC_STAGES];   // write pointer, seen by the reader
  logic [PW-1:0] rgray_sync [SYNC_STAGES];   // read pointer, seen by the writer

  logic [PW-1:0] rbin_s, wbin_s;
  logic          full, empty;
  logic          wr_fire, rd_fire;

  // ---------------------------------------------------------------- write ---
  assign rbin_s   = g2b(rgray_sync[SYNC_STAGES-1]);
  // full when the two pointers differ only in the wrap bit
  assign full     = (wbin[LOG_DEPTH] != rbin_s[LOG_DEPTH]) &&
                    (wbin[LOG_DEPTH-1:0] == rbin_s[LOG_DEPTH-1:0]);
  assign wr_ready = wr_rst_n && !full;      // no dependence on wr_valid (H1)
  assign wr_fire  = wr_valid && wr_ready;

  always_ff @(posedge wr_clk or negedge wr_rst_n) begin
    int i;
    if (!wr_rst_n) begin
      wbin  <= '0;
      wgray <= '0;
      for (i = 0; i < SYNC_STAGES; i++) rgray_sync[i] <= '0;
    end else begin
      if (wr_fire) begin
        wbin  <= wbin + PTR_ONE;
        wgray <= b2g(wbin + PTR_ONE);
      end
      rgray_sync[0] <= rgray;
      for (i = 1; i < SYNC_STAGES; i++) rgray_sync[i] <= rgray_sync[i-1];
    end
  end

  always_ff @(posedge wr_clk) begin
    if (wr_fire) mem[wbin[LOG_DEPTH-1:0]] <= wr_data;
  end

  // ----------------------------------------------------------------- read ---
  assign wbin_s   = g2b(wgray_sync[SYNC_STAGES-1]);
  assign empty    = (rbin == wbin_s);
  assign rd_valid = rd_rst_n && !empty;     // no dependence on rd_ready (H1)
  assign rd_fire  = rd_valid && rd_ready;
  // The entry under rbin cannot be written while it is being read, so this is
  // stable for as long as rd_valid is held (H3).
  assign rd_data  = mem[rbin[LOG_DEPTH-1:0]];

  always_ff @(posedge rd_clk or negedge rd_rst_n) begin
    int i;
    if (!rd_rst_n) begin
      rbin  <= '0;
      rgray <= '0;
      for (i = 0; i < SYNC_STAGES; i++) wgray_sync[i] <= '0;
    end else begin
      if (rd_fire) begin
        rbin  <= rbin + PTR_ONE;
        rgray <= b2g(rbin + PTR_ONE);
      end
      wgray_sync[0] <= wgray;
      for (i = 1; i < SYNC_STAGES; i++) wgray_sync[i] <= wgray_sync[i-1];
    end
  end

endmodule