// =============================================================================
// nonblocking_dcache
//
// Set-associative, write-back, write-allocate data cache that keeps accepting
// requests while misses are outstanding.
//
// STRUCTURE (L2 leaves this free; this is one choice, not a required one)
//
//   * MSHR file, MAX_MISSES entries. Each entry owns one block address, a
//     BLOCK_WORDS fill buffer, a dirty flag, and a count of pending requests
//     bound to it. A miss to a line already covered by an entry MERGES into it,
//     so at most one entry per line exists at any time.
//
//   * Pending request FIFO, 2*MAX_MISSES entries, drained in order. Each entry
//     names the MSHR it waits on. The head drains when its MSHR has its data.
//
//   * FILL DATA LANDS IN THE MSHR BUFFER, NOT THE ARRAY. Pending requests are
//     served out of that buffer; the line is installed into the array only once
//     the MSHR's pending count reaches zero. No way is reserved at allocation
//     time, so MAX_MISSES misses can be outstanding no matter how they map onto
//     sets -- capacity is bounded by C1's parameter and by nothing else.
//
//   * Hits bypass the FIFO entirely and are answered from the array (C2).
//
// KEY INVARIANTS
//
//   R5 (same-address order). A line covered by a live MSHR NEVER reports a hit,
//   so every request to such a line enters the FIFO behind the earlier ones and
//   the FIFO's in-order drain orders them. Conversely a hit implies no queued
//   request to that word exists. The two paths therefore cannot race.
//
//   Writeback-before-refill. The victim is chosen at install time, its data is
//   captured into a single global writeback slot, and the way is overwritten in
//   the same cycle -- so the evicted line reads as absent from that instant on.
//   Only one writeback may be in flight (an install needing a second one waits),
//   and a pending writeback takes strict priority over every fill in the memory
//   arbiter. An MSHR for the evicted line can only be allocated after the
//   install, hence strictly after the writeback was already pending, hence its
//   fill is ordered behind that writeback. Stale refill is therefore impossible.
//
//   Forward progress (C3). req_ready_o is withheld only while the response slot
//   is occupied, the FIFO is full, or the MSHR file is full. All three clear
//   without any further requests being accepted: memory eventually responds, the
//   FIFO drains one entry per cycle, and drained entries free their MSHRs.
//   Fill arbitration is rotating, so no MSHR is starved by a busier neighbour.
//
// L1 replacement: invalid way first, else per-set round robin.
// L4 store misses allocate. L3 fills are strictly ascending (M1).
// P1 valid bits are cleared on reset -- conformant, though not required.
// =============================================================================

module nonblocking_dcache #(
  parameter int unsigned DATA_W     = 32,   // {32, 64}
  parameter int unsigned SETS       = 16,   // {8, 16}
  parameter int unsigned WAYS       = 4,    // {2, 4}
  parameter int unsigned MAX_MISSES = 8     // {2, 8}
) (
  input  logic                     clk_i,
  input  logic                     rst_ni,        // active low, asynchronous assert

  // ---- request ------------------------------------------------------------
  input  logic                     req_valid_i,
  output logic                     req_ready_o,
  input  logic [3:0]               req_id_i,      // ID_W = 4
  input  logic                     req_op_i,      // 0 = LOAD, 1 = STORE
  input  logic [31:0]              req_addr_i,    // ADDR_W = 32, byte address, word aligned
  input  logic [DATA_W-1:0]        req_data_i,    // STORE data
  input  logic [(DATA_W/8)-1:0]    req_mask_i,    // STORE byte enables

  // ---- response -----------------------------------------------------------
  output logic                     rsp_valid_o,
  input  logic                     rsp_ready_i,
  output logic [3:0]               rsp_id_o,
  output logic [DATA_W-1:0]        rsp_data_o,

  // ---- memory: request ----------------------------------------------------
  output logic                     mem_req_valid_o,
  input  logic                     mem_req_ready_i,
  output logic                     mem_req_we_o,  // 0 = fill, 1 = writeback
  output logic [31:0]              mem_req_addr_o,// block aligned

  // ---- memory: fill data in ----------------------------------------------
  input  logic                     mem_rd_valid_i,
  output logic                     mem_rd_ready_o,
  input  logic [DATA_W-1:0]        mem_rd_data_i,

  // ---- memory: writeback data out ----------------------------------------
  output logic                     mem_wr_valid_o,
  input  logic                     mem_wr_ready_i,
  output logic [DATA_W-1:0]        mem_wr_data_o
);

  // ---------------------------------------------------------------- geometry
  localparam int unsigned BLOCK_WORDS = 4;

  localparam int unsigned WBYTES = DATA_W / 8;          // 4 or 8
  localparam int unsigned BOFF_W = $clog2(WBYTES);      // byte offset in word
  localparam int unsigned WOFF_W = $clog2(BLOCK_WORDS); // word offset in block
  localparam int unsigned SET_W  = $clog2(SETS);
  localparam int unsigned LOFF_W = BOFF_W + WOFF_W;     // byte offset in block
  localparam int unsigned TAG_W  = 32 - LOFF_W - SET_W;
  localparam int unsigned WAY_W  = $clog2(WAYS);

  localparam int unsigned NMS   = MAX_MISSES;
  localparam int unsigned MS_W  = $clog2(NMS);
  localparam int unsigned PN    = 2 * MAX_MISSES;       // pending FIFO depth
  localparam int unsigned PW    = $clog2(PN);
  localparam int unsigned CNT_W = PW + 1;

  // MSHR state
  localparam logic [1:0] S_FILLW   = 2'd0;  // waiting for its turn at memory
  localparam logic [1:0] S_FILLING = 2'd1;  // fill beats arriving
  localparam logic [1:0] S_SERVE   = 2'd2;  // data resident in the MSHR buffer

  // memory port state
  localparam logic [2:0] M_IDLE = 3'd0;
  localparam logic [2:0] M_FREQ = 3'd1;
  localparam logic [2:0] M_FDAT = 3'd2;
  localparam logic [2:0] M_WREQ = 3'd3;
  localparam logic [2:0] M_WDAT = 3'd4;

  // ------------------------------------------------------------- byte merge
  function automatic logic [DATA_W-1:0] merge_bytes(
      input logic [DATA_W-1:0] old_w,
      input logic [DATA_W-1:0] new_w,
      input logic [WBYTES-1:0] be
  );
    logic [DATA_W-1:0] r;
    r = old_w;
    for (int unsigned b = 0; b < WBYTES; b++) begin
      if (be[b]) r[b*8 +: 8] = new_w[b*8 +: 8];
    end
    return r;
  endfunction

  // ---------------------------------------------------------------- storage
  logic [TAG_W-1:0]  tag_q [SETS][WAYS];
  logic              vld_q [SETS][WAYS];
  logic              drt_q [SETS][WAYS];
  logic [DATA_W-1:0] dat_q [SETS][WAYS][BLOCK_WORDS];
  logic [WAY_W-1:0]  rrw_q [SETS];

  // ------------------------------------------------------------------ MSHRs
  logic              ms_vld  [NMS];
  logic [1:0]        ms_st   [NMS];
  logic [31:0]       ms_line [NMS];
  logic              ms_drt  [NMS];
  logic [DATA_W-1:0] ms_buf  [NMS][BLOCK_WORDS];
  logic [CNT_W-1:0]  ms_cnt  [NMS];

  // ---------------------------------------------------------- pending FIFO
  logic [3:0]        pq_id   [PN];
  logic              pq_op   [PN];
  logic [WOFF_W-1:0] pq_word [PN];
  logic [DATA_W-1:0] pq_data [PN];
  logic [WBYTES-1:0] pq_mask [PN];
  logic [MS_W-1:0]   pq_ms   [PN];
  logic [PW-1:0]     pq_head;
  logic [PW-1:0]     pq_tail;
  logic [CNT_W-1:0]  pq_cnt;

  // ------------------------------------------------------------ memory port
  logic [2:0]        mst;
  logic [MS_W-1:0]   msel;
  logic [WOFF_W-1:0] beat;
  logic [31:0]       mreq_addr;
  logic              mreq_we;
  logic [MS_W-1:0]   rr_ms;
  logic              wb_pend;
  logic [31:0]       wb_addr;
  logic [DATA_W-1:0] wb_buf [BLOCK_WORDS];

  // ------------------------------------------------------- request decoding
  logic [SET_W-1:0]  rq_set;
  logic [TAG_W-1:0]  rq_tag;
  logic [WOFF_W-1:0] rq_word;
  logic [31:0]       rq_line;

  assign rq_set  = req_addr_i[LOFF_W +: SET_W];
  assign rq_tag  = req_addr_i[LOFF_W + SET_W +: TAG_W];
  assign rq_word = req_addr_i[BOFF_W +: WOFF_W];
  assign rq_line = {req_addr_i[31:LOFF_W], {LOFF_W{1'b0}}};

  logic             hit_v;
  logic [WAY_W-1:0] hit_w;

  always_comb begin
    hit_v = 1'b0;
    hit_w = '0;
    for (int unsigned w = 0; w < WAYS; w++) begin
      if (vld_q[rq_set][w] && (tag_q[rq_set][w] == rq_tag)) begin
        hit_v = 1'b1;
        hit_w = WAY_W'(w);
      end
    end
  end

  logic            ms_match;
  logic [MS_W-1:0] ms_match_i;
  logic            ms_freev;
  logic [MS_W-1:0] ms_free_i;

  always_comb begin
    ms_match   = 1'b0;
    ms_match_i = '0;
    ms_freev   = 1'b0;
    ms_free_i  = '0;
    for (int unsigned m = 0; m < NMS; m++) begin
      if (ms_vld[m] && (ms_line[m] == rq_line)) begin
        ms_match   = 1'b1;
        ms_match_i = MS_W'(m);
      end
      if (!ms_vld[m] && !ms_freev) begin
        ms_freev  = 1'b1;
        ms_free_i = MS_W'(m);
      end
    end
  end

  // ------------------------------------------------- install / victim select
  logic            inst_v;
  logic [MS_W-1:0] inst_i;

  always_comb begin
    inst_v = 1'b0;
    inst_i = '0;
    for (int unsigned m = 0; m < NMS; m++) begin
      if (!inst_v && ms_vld[m] && (ms_st[m] == S_SERVE) && (ms_cnt[m] == '0)) begin
        inst_v = 1'b1;
        inst_i = MS_W'(m);
      end
    end
  end

  logic [SET_W-1:0] inst_set;
  logic [WAY_W-1:0] vic_way;
  logic             vic_inv;
  logic             vic_drt;
  logic             inst_fire;

  assign inst_set = ms_line[inst_i][LOFF_W +: SET_W];

  always_comb begin
    vic_inv = 1'b0;
    vic_way = rrw_q[inst_set];
    for (int unsigned w = 0; w < WAYS; w++) begin
      if (!vic_inv && !vld_q[inst_set][w]) begin
        vic_inv = 1'b1;
        vic_way = WAY_W'(w);
      end
    end
  end

  assign vic_drt   = !vic_inv && vld_q[inst_set][vic_way] && drt_q[inst_set][vic_way];
  assign inst_fire = inst_v && (!vic_drt || !wb_pend);

  // ------------------------------------------------------ fill arbitration
  // Rotating priority so that no MSHR is starved of the memory port.
  logic            fill_v;
  logic [MS_W-1:0] fill_i;

  always_comb begin
    int unsigned idx;
    fill_v = 1'b0;
    fill_i = '0;
    for (int unsigned k = 0; k < NMS; k++) begin
      idx = k + 32'(rr_ms);
      if (idx >= NMS) idx = idx - NMS;
      if (!fill_v && ms_vld[idx] && (ms_st[idx] == S_FILLW)) begin
        fill_v = 1'b1;
        fill_i = MS_W'(idx);
      end
    end
  end

  // ------------------------------------------------- response arbitration
  logic [MS_W-1:0] dr_ms;
  logic            rsp_slot;
  logic            drain_fire;

  assign dr_ms      = pq_ms[pq_head];
  assign rsp_slot   = !rsp_valid_o || rsp_ready_i;
  assign drain_fire = (pq_cnt != '0) && ms_vld[dr_ms] &&
                      (ms_st[dr_ms] == S_SERVE) && rsp_slot;

  // ------------------------------------------------------ request acceptance
  // L5: req_ready_o may depend combinationally on req_valid_i, and does.
  logic acc_hit;
  logic acc_merge;
  logic acc_alloc;
  logic enq_fire;
  logic [MS_W-1:0] enq_ms;

  assign acc_hit   = req_valid_i && !inst_fire && !ms_match &&  hit_v &&
                     rsp_slot && !drain_fire;
  assign acc_merge = req_valid_i && !inst_fire &&  ms_match && (pq_cnt != CNT_W'(PN));
  assign acc_alloc = req_valid_i && !inst_fire && !ms_match && !hit_v &&
                     ms_freev && (pq_cnt != CNT_W'(PN));

  assign req_ready_o = acc_hit || acc_merge || acc_alloc;
  assign enq_fire    = acc_merge || acc_alloc;
  assign enq_ms      = acc_alloc ? ms_free_i : ms_match_i;

  // ----------------------------------------------------------- memory drive
  assign mem_req_valid_o = (mst == M_FREQ) || (mst == M_WREQ);
  assign mem_req_we_o    = mreq_we;
  assign mem_req_addr_o  = mreq_addr;
  assign mem_rd_ready_o  = (mst == M_FDAT);
  assign mem_wr_valid_o  = (mst == M_WDAT);
  assign mem_wr_data_o   = wb_buf[beat];

  // =========================================================================
  // sequential state
  // =========================================================================
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      for (int unsigned s = 0; s < SETS; s++) begin
        rrw_q[s] <= '0;
        for (int unsigned w = 0; w < WAYS; w++) begin
          vld_q[s][w] <= 1'b0;
          drt_q[s][w] <= 1'b0;
        end
      end
      for (int unsigned m = 0; m < NMS; m++) begin
        ms_vld[m] <= 1'b0;
        ms_st[m]  <= S_FILLW;
        ms_drt[m] <= 1'b0;
        ms_cnt[m] <= '0;
      end
      pq_head     <= '0;
      pq_tail     <= '0;
      pq_cnt      <= '0;
      mst         <= M_IDLE;
      msel        <= '0;
      beat        <= '0;
      mreq_addr   <= '0;
      mreq_we     <= 1'b0;
      rr_ms       <= '0;
      wb_pend     <= 1'b0;
      wb_addr     <= '0;
      rsp_valid_o <= 1'b0;
      rsp_id_o    <= '0;
      rsp_data_o  <= '0;
    end else begin

      // ---- response register: drained miss first, then hit ----------------
      if (rsp_slot) begin
        if (drain_fire) begin
          rsp_valid_o <= 1'b1;
          rsp_id_o    <= pq_id[pq_head];
          rsp_data_o  <= ms_buf[dr_ms][pq_word[pq_head]];
        end else if (acc_hit) begin
          rsp_valid_o <= 1'b1;
          rsp_id_o    <= req_id_i;
          rsp_data_o  <= dat_q[rq_set][hit_w][rq_word];
        end else begin
          rsp_valid_o <= 1'b0;
        end
      end

      // ---- hit-side store: byte merge into the array ----------------------
      if (acc_hit && req_op_i) begin
        dat_q[rq_set][hit_w][rq_word] <=
            merge_bytes(dat_q[rq_set][hit_w][rq_word], req_data_i, req_mask_i);
        drt_q[rq_set][hit_w] <= 1'b1;
      end

      // ---- pending FIFO ---------------------------------------------------
      if (enq_fire) begin
        pq_id[pq_tail]   <= req_id_i;
        pq_op[pq_tail]   <= req_op_i;
        pq_word[pq_tail] <= rq_word;
        pq_data[pq_tail] <= req_data_i;
        pq_mask[pq_tail] <= req_mask_i;
        pq_ms[pq_tail]   <= enq_ms;
        pq_tail          <= pq_tail + 1'b1;
      end
      if (drain_fire) begin
        pq_head <= pq_head + 1'b1;
      end
      if (enq_fire && !drain_fire)      pq_cnt <= pq_cnt + 1'b1;
      else if (!enq_fire && drain_fire) pq_cnt <= pq_cnt - 1'b1;

      // ---- drained store: byte merge into the MSHR buffer ------------------
      if (drain_fire && pq_op[pq_head]) begin
        ms_buf[dr_ms][pq_word[pq_head]] <=
            merge_bytes(ms_buf[dr_ms][pq_word[pq_head]],
                        pq_data[pq_head], pq_mask[pq_head]);
        ms_drt[dr_ms] <= 1'b1;
      end

      // ---- MSHR allocate, and pending-count maintenance -------------------
      if (acc_alloc) begin
        ms_vld[ms_free_i]  <= 1'b1;
        ms_st[ms_free_i]   <= S_FILLW;
        ms_line[ms_free_i] <= rq_line;
        ms_drt[ms_free_i]  <= 1'b0;
        ms_cnt[ms_free_i]  <= CNT_W'(1);
      end
      if (acc_merge && !(drain_fire && (dr_ms == ms_match_i))) begin
        ms_cnt[ms_match_i] <= ms_cnt[ms_match_i] + 1'b1;
      end
      if (drain_fire && !(acc_merge && (ms_match_i == dr_ms))) begin
        ms_cnt[dr_ms] <= ms_cnt[dr_ms] - 1'b1;
      end

      // ---- install: MSHR retires its line into the array -------------------
      // The victim is captured and overwritten in the same cycle, so it reads
      // as absent from here on. req_ready_o is low this cycle, so no request
      // can race the array update.
      if (inst_fire) begin
        if (vic_drt) begin
          wb_pend <= 1'b1;
          wb_addr <= {tag_q[inst_set][vic_way], inst_set, {LOFF_W{1'b0}}};
          for (int unsigned k = 0; k < BLOCK_WORDS; k++) begin
            wb_buf[k] <= dat_q[inst_set][vic_way][k];
          end
        end
        for (int unsigned k = 0; k < BLOCK_WORDS; k++) begin
          dat_q[inst_set][vic_way][k] <= ms_buf[inst_i][k];
        end
        tag_q[inst_set][vic_way] <= ms_line[inst_i][LOFF_W + SET_W +: TAG_W];
        vld_q[inst_set][vic_way] <= 1'b1;
        drt_q[inst_set][vic_way] <= ms_drt[inst_i];
        ms_vld[inst_i]           <= 1'b0;
        rrw_q[inst_set]          <= (rrw_q[inst_set] == WAY_W'(WAYS-1)) ?
                                    '0 : rrw_q[inst_set] + 1'b1;
      end

      // ---- memory port: one transaction outstanding (M3) -------------------
      case (mst)
        M_IDLE: begin
          if (wb_pend) begin
            // strict priority over fills: this is what keeps a refill from
            // overtaking the writeback of the line it is refilling.
            mst       <= M_WREQ;
            mreq_we   <= 1'b1;
            mreq_addr <= wb_addr;
            beat      <= '0;
          end else if (fill_v) begin
            mst        <= M_FREQ;
            mreq_we    <= 1'b0;
            mreq_addr  <= ms_line[fill_i];
            msel       <= fill_i;
            beat       <= '0;
            ms_st[fill_i] <= S_FILLING;
            rr_ms      <= (fill_i == MS_W'(NMS-1)) ? '0 : fill_i + 1'b1;
          end
        end

        M_FREQ: begin
          if (mem_req_ready_i) mst <= M_FDAT;
        end

        M_FDAT: begin
          if (mem_rd_valid_i) begin
            ms_buf[msel][beat] <= mem_rd_data_i;
            if (beat == WOFF_W'(BLOCK_WORDS-1)) begin
              ms_st[msel] <= S_SERVE;
              mst         <= M_IDLE;
            end else begin
              beat <= beat + 1'b1;
            end
          end
        end

        M_WREQ: begin
          if (mem_req_ready_i) mst <= M_WDAT;
        end

        M_WDAT: begin
          if (mem_wr_ready_i) begin
            if (beat == WOFF_W'(BLOCK_WORDS-1)) begin
              wb_pend <= 1'b0;
              mst     <= M_IDLE;
            end else begin
              beat <= beat + 1'b1;
            end
          end
        end

        default: mst <= M_IDLE;
      endcase
    end
  end

endmodule