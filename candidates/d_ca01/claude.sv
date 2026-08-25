// =============================================================================
// nonblocking_dcache.sv
// -----------------------------------------------------------------------------
// Set-associative, write-back, write-allocate data cache that keeps accepting
// requests while misses are outstanding.
//
// STRUCTURE (contract names none of this; it is a design choice per L2)
//
//   * MSHR FIFO, depth MAX_MISSES. A miss allocates at the tail and is answered
//     from the head. Because M3 permits only ONE memory transaction outstanding,
//     misses are necessarily serviced one at a time, so a circular FIFO is both
//     sufficient and starvation-free by construction (C3): the head is always
//     the oldest accepted miss, and it is freed before the next is serviced.
//     Each entry holds line address, id, op, word offset and -- for a store --
//     ONE merged store word plus its byte mask (the C4 allowance).
//
//   * LAZY VICTIM SELECTION. The victim way is chosen when the memory engine
//     starts servicing a miss, NOT when the MSHR is allocated. Nothing is
//     reserved at allocation, so MAX_MISSES misses may target the same set even
//     when MAX_MISSES > WAYS -- required to meet C1's floor at SETS=8/WAYS=2/
//     MAX_MISSES=8. At most one way is ever reserved, because at most one fill
//     is ever in flight.
//
//   * BLOCK-DATA BUFFERING: ONE line (the writeback buffer). Fill beats are
//     written straight into the reserved way as they arrive, so there is no
//     fill line buffer at all -- one line below C4's ceiling of two.
//
//   * The victim way is INVALIDATED when the memory engine commits to it. That
//     is what makes the writeback safe without a lock: the line cannot be hit,
//     so it cannot be stored to after its data was captured, so the captured
//     copy cannot go stale. A later request to the evicted line simply misses
//     and allocates, and its fill is necessarily ordered after the writeback.
//
//   * Requests to a line that already has an MSHR are not accepted until that
//     miss resolves. This is what gives R5 for free and bounds the merged store
//     data to one word per pending miss.
//
//   * Hits are answered from a registered response slot, one cycle after
//     acceptance, independently of miss state (C2). The fill path has priority
//     on that slot, so a stream of hits cannot starve a completing miss.
// =============================================================================

/* verilator lint_off WIDTH */
/* verilator lint_off UNUSED */
/* verilator lint_off DECLFILENAME */
/* verilator lint_off UNOPTFLAT */
/* verilator lint_off SYNCASYNCNET */
/* verilator lint_off CASEINCOMPLETE */

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

  // ---------------------------------------------------------------------------
  // Derived constants
  // ---------------------------------------------------------------------------
  localparam int unsigned BLOCK_WORDS = 4;
  localparam int unsigned NBYTES      = DATA_W / 8;
  localparam int unsigned BOFF_W      = $clog2(NBYTES);       // byte-in-word bits
  localparam int unsigned WOFF_W      = $clog2(BLOCK_WORDS);  // word-in-block bits
  localparam int unsigned SET_W       = $clog2(SETS);
  localparam int unsigned WAY_W       = $clog2(WAYS);
  localparam int unsigned LINE_W      = 32 - WOFF_W - BOFF_W; // {tag, set}
  localparam int unsigned TAG_W       = LINE_W - SET_W;
  localparam int unsigned IDX_W       = $clog2(MAX_MISSES);
  localparam int unsigned CNT_W       = $clog2(MAX_MISSES + 1);

  // Memory engine states
  localparam logic [2:0] M_IDLE  = 3'd0;
  localparam logic [2:0] M_WBREQ = 3'd1;
  localparam logic [2:0] M_WBDAT = 3'd2;
  localparam logic [2:0] M_FREQ  = 3'd3;
  localparam logic [2:0] M_FDAT  = 3'd4;
  localparam logic [2:0] M_FDONE = 3'd5;

  // ---------------------------------------------------------------------------
  // Storage
  // ---------------------------------------------------------------------------
  logic [WAYS-1:0]                    valid_q [SETS];
  logic [WAYS-1:0]                    dirty_q [SETS];
  // Tag and data arrays are indexed by the flat {set, way} pair. WAYS is a power
  // of two, so the concatenation IS set*WAYS + way; keeping the arrays
  // single-dimension also keeps the file readable by frontends that do not
  // accept multi-dimensional unpacked arrays.
  logic [TAG_W-1:0]                   tag_q   [SETS*WAYS];
  logic [BLOCK_WORDS*DATA_W-1:0]      data_q  [SETS*WAYS];
  logic [WAY_W-1:0]                   rr_q    [SETS];   // round-robin replacement

  // MSHR file, used as a circular FIFO
  logic                  mshr_v    [MAX_MISSES];
  logic [LINE_W-1:0]     mshr_line [MAX_MISSES];
  logic [3:0]            mshr_id   [MAX_MISSES];
  logic                  mshr_op   [MAX_MISSES];
  logic [WOFF_W-1:0]     mshr_woff [MAX_MISSES];
  logic [DATA_W-1:0]     mshr_data [MAX_MISSES];   // one merged store word (C4)
  logic [NBYTES-1:0]     mshr_mask [MAX_MISSES];
  logic [IDX_W-1:0]      mshr_head_q, mshr_tail_q;
  logic [CNT_W-1:0]      mshr_cnt_q;

  // Memory engine
  logic [2:0]                         mem_state_q;
  logic [WOFF_W-1:0]                  beat_q;
  logic [WAY_W-1:0]                   fill_way_q;
  logic [LINE_W-1:0]                  wb_line_q;
  logic [BLOCK_WORDS*DATA_W-1:0]      wb_buf_q;   // the single block-data buffer

  // Response slot
  logic              rsp_valid_q;
  logic [3:0]        rsp_id_q;
  logic [DATA_W-1:0] rsp_data_q;

  // ---------------------------------------------------------------------------
  // Request decode and tag lookup
  // ---------------------------------------------------------------------------
  logic [WOFF_W-1:0] req_woff;
  logic [SET_W-1:0]  req_set;
  logic [TAG_W-1:0]  req_tag;
  logic [LINE_W-1:0] req_line;

  assign req_woff = req_addr_i[BOFF_W               +: WOFF_W];
  assign req_set  = req_addr_i[BOFF_W+WOFF_W        +: SET_W];
  assign req_tag  = req_addr_i[BOFF_W+WOFF_W+SET_W  +: TAG_W];
  assign req_line = req_addr_i[BOFF_W+WOFF_W        +: LINE_W];

  localparam int unsigned IX_W = SET_W + WAY_W;

  logic             req_hit;
  logic [WAY_W-1:0] hit_way;

  always_comb begin
    req_hit = 1'b0;
    hit_way = '0;
    for (int unsigned w = 0; w < WAYS; w++) begin
      if (valid_q[req_set][w] && (tag_q[{req_set, WAY_W'(w)}] == req_tag)) begin
        req_hit = 1'b1;
        hit_way = WAY_W'(w);
      end
    end
  end

  // A line that already has an MSHR must not take a second one: two fills of one
  // line would install two copies. Blocking here is also what delivers R5.
  logic mshr_line_busy;
  always_comb begin
    mshr_line_busy = 1'b0;
    for (int unsigned i = 0; i < MAX_MISSES; i++) begin
      if (mshr_v[i] && (mshr_line[i] == req_line)) mshr_line_busy = 1'b1;
    end
  end

  // ---------------------------------------------------------------------------
  // Head-of-FIFO miss being serviced
  // ---------------------------------------------------------------------------
  logic [LINE_W-1:0] head_line;
  logic [SET_W-1:0]  head_set;
  logic [TAG_W-1:0]  head_tag;
  logic [WOFF_W-1:0] head_woff;
  logic              head_op;
  logic [3:0]        head_id;
  logic [DATA_W-1:0] head_data;
  logic [NBYTES-1:0] head_mask;

  assign head_line = mshr_line[mshr_head_q];
  assign head_set  = head_line[SET_W-1:0];
  assign head_tag  = head_line[LINE_W-1:SET_W];
  assign head_woff = mshr_woff[mshr_head_q];
  assign head_op   = mshr_op  [mshr_head_q];
  assign head_id   = mshr_id  [mshr_head_q];
  assign head_data = mshr_data[mshr_head_q];
  assign head_mask = mshr_mask[mshr_head_q];

  // Victim: an invalid way if one exists, else round-robin. Evaluated only in
  // M_IDLE, where exactly one miss is about to be serviced.
  logic [WAY_W-1:0] victim_way;
  logic             victim_dirty;

  always_comb begin
    logic found;
    victim_way = rr_q[head_set];
    found      = 1'b0;
    for (int unsigned w = 0; w < WAYS; w++) begin
      if (!found && !valid_q[head_set][w]) begin
        victim_way = WAY_W'(w);
        found      = 1'b1;
      end
    end
  end

  assign victim_dirty = valid_q[head_set][victim_way] & dirty_q[head_set][victim_way];

  // ---------------------------------------------------------------------------
  // Memory engine control strobes
  // ---------------------------------------------------------------------------
  logic rsp_free;
  logic mem_start;      // committing to a victim this cycle
  logic fill_beat;      // a fill beat is landing in the array this cycle
  logic fill_commit;    // fill finishing: install tag, merge store, answer
  logic mem_rd_port;    // memory engine owns the data-array read port

  assign rsp_free    = ~rsp_valid_q | rsp_ready_i;
  assign mem_start   = (mem_state_q == M_IDLE) & mshr_v[mshr_head_q];
  assign fill_beat   = (mem_state_q == M_FDAT) & mem_rd_valid_i;
  assign fill_commit = (mem_state_q == M_FDONE) & rsp_free;
  assign mem_rd_port = mem_start | (mem_state_q == M_FDONE);

  // ---------------------------------------------------------------------------
  // Shared data-array read port (one full line). Memory engine has priority; the
  // request pipeline yields for the single cycle it is taken.
  // ---------------------------------------------------------------------------
  logic [SET_W-1:0] rd_set;
  logic [WAY_W-1:0] rd_way;

  always_comb begin
    if (mem_start) begin
      rd_set = head_set;
      rd_way = victim_way;
    end else if (mem_state_q == M_FDONE) begin
      rd_set = head_set;
      rd_way = fill_way_q;
    end else begin
      rd_set = req_set;
      rd_way = hit_way;
    end
  end

  logic [IX_W-1:0] rd_ix, hit_ix, victim_ix, fill_ix;
  assign rd_ix     = {rd_set,   rd_way};
  assign hit_ix    = {req_set,  hit_way};
  assign victim_ix = {head_set, victim_way};
  assign fill_ix   = {head_set, fill_way_q};

  logic [BLOCK_WORDS*DATA_W-1:0] rd_line;
  assign rd_line = data_q[rd_ix];

  // Word returned for a completing miss, with the merged store applied.
  logic [DATA_W-1:0] merged_word;
  always_comb begin
    merged_word = rd_line[head_woff*DATA_W +: DATA_W];
    if (head_op) begin
      for (int unsigned b = 0; b < NBYTES; b++) begin
        if (head_mask[b]) merged_word[8*b +: 8] = head_data[8*b +: 8];
      end
    end
  end

  // ---------------------------------------------------------------------------
  // Acceptance. Hits never depend on MSHR occupancy (C2); misses never depend on
  // the response slot (C1).
  // ---------------------------------------------------------------------------
  logic hit_ok, miss_ok;
  logic req_fire, hit_accept, miss_accept, store_hit_wr;

  assign hit_ok  = rsp_free & ~mem_rd_port & ~(req_op_i & fill_beat);
  assign miss_ok = (mshr_cnt_q != CNT_W'(MAX_MISSES)) & ~mshr_line_busy;

  always_comb begin
    req_ready_o = 1'b0;
    if (req_valid_i) req_ready_o = req_hit ? hit_ok : miss_ok;
  end

  assign req_fire     = req_valid_i & req_ready_o;
  assign hit_accept   = req_fire &  req_hit;
  assign miss_accept  = req_fire & ~req_hit;
  assign store_hit_wr = hit_accept & req_op_i;

  // ---------------------------------------------------------------------------
  // Memory port outputs
  // ---------------------------------------------------------------------------
  assign mem_req_valid_o = (mem_state_q == M_WBREQ) | (mem_state_q == M_FREQ);
  assign mem_req_we_o    = (mem_state_q == M_WBREQ);
  assign mem_req_addr_o  = (mem_state_q == M_WBREQ)
                         ? {wb_line_q, {(WOFF_W+BOFF_W){1'b0}}}
                         : {head_line, {(WOFF_W+BOFF_W){1'b0}}};
  assign mem_wr_valid_o  = (mem_state_q == M_WBDAT);
  assign mem_wr_data_o   = wb_buf_q[beat_q*DATA_W +: DATA_W];
  assign mem_rd_ready_o  = (mem_state_q == M_FDAT);

  assign rsp_valid_o = rsp_valid_q;
  assign rsp_id_o    = rsp_id_q;
  assign rsp_data_o  = rsp_data_q;

  // ---------------------------------------------------------------------------
  // Memory engine FSM. A new mem_req_valid_o is only ever raised in a state
  // entered after the previous transaction's last beat transferred (M3).
  // ---------------------------------------------------------------------------
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      mem_state_q <= M_IDLE;
      beat_q      <= '0;
    end else begin
      case (mem_state_q)
        M_IDLE: begin
          if (mem_start) begin
            beat_q      <= '0;
            mem_state_q <= victim_dirty ? M_WBREQ : M_FREQ;
          end
        end
        M_WBREQ: begin
          if (mem_req_ready_i) begin
            beat_q      <= '0;
            mem_state_q <= M_WBDAT;
          end
        end
        M_WBDAT: begin
          if (mem_wr_ready_i) begin
            if (beat_q == WOFF_W'(BLOCK_WORDS-1)) mem_state_q <= M_FREQ;
            beat_q <= WOFF_W'(beat_q + 1);
          end
        end
        M_FREQ: begin
          if (mem_req_ready_i) begin
            beat_q      <= '0;
            mem_state_q <= M_FDAT;
          end
        end
        M_FDAT: begin
          if (mem_rd_valid_i) begin
            if (beat_q == WOFF_W'(BLOCK_WORDS-1)) mem_state_q <= M_FDONE;
            beat_q <= WOFF_W'(beat_q + 1);
          end
        end
        M_FDONE: begin
          if (rsp_free) mem_state_q <= M_IDLE;
        end
        default: mem_state_q <= M_IDLE;
      endcase
    end
  end

  // Victim bookkeeping, captured once at mem_start.
  always_ff @(posedge clk_i) begin
    if (mem_start) begin
      fill_way_q <= victim_way;
      wb_line_q  <= {tag_q[victim_ix], head_set};
      wb_buf_q   <= rd_line;
    end
  end

  // ---------------------------------------------------------------------------
  // Tag / valid / dirty
  // ---------------------------------------------------------------------------
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      for (int unsigned s = 0; s < SETS; s++) valid_q[s] <= '0;
    end else begin
      if (mem_start) begin
        valid_q[head_set][victim_way] <= 1'b0;
      end else if (fill_commit) begin
        valid_q[head_set][fill_way_q] <= 1'b1;
      end
    end
  end

  always_ff @(posedge clk_i) begin
    if (fill_commit) begin
      tag_q  [fill_ix] <= head_tag;
      dirty_q[head_set][fill_way_q] <= head_op;
    end else if (store_hit_wr) begin
      dirty_q[req_set][hit_way] <= 1'b1;
    end
  end

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      for (int unsigned s = 0; s < SETS; s++) rr_q[s] <= '0;
    end else if (mem_start) begin
      rr_q[head_set] <= WAY_W'(victim_way + 1);
    end
  end

  // ---------------------------------------------------------------------------
  // Data array: one write port. Fill beats > store merge > store hit. The first
  // two are mutually exclusive with the third by the acceptance conditions.
  // ---------------------------------------------------------------------------
  always_ff @(posedge clk_i) begin
    if (fill_beat) begin
      data_q[fill_ix][beat_q*DATA_W +: DATA_W] <= mem_rd_data_i;
    end else if (fill_commit && head_op) begin
      for (int unsigned b = 0; b < NBYTES; b++) begin
        if (head_mask[b])
          data_q[fill_ix][head_woff*DATA_W + 8*b +: 8] <= head_data[8*b +: 8];
      end
    end else if (store_hit_wr) begin
      for (int unsigned b = 0; b < NBYTES; b++) begin
        if (req_mask_i[b])
          data_q[hit_ix][req_woff*DATA_W + 8*b +: 8] <= req_data_i[8*b +: 8];
      end
    end
  end

  // ---------------------------------------------------------------------------
  // MSHR FIFO
  // ---------------------------------------------------------------------------
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      mshr_head_q <= '0;
      mshr_tail_q <= '0;
      mshr_cnt_q  <= '0;
      for (int unsigned i = 0; i < MAX_MISSES; i++) mshr_v[i] <= 1'b0;
    end else begin
      if (miss_accept) begin
        mshr_v   [mshr_tail_q] <= 1'b1;
        mshr_line[mshr_tail_q] <= req_line;
        mshr_id  [mshr_tail_q] <= req_id_i;
        mshr_op  [mshr_tail_q] <= req_op_i;
        mshr_woff[mshr_tail_q] <= req_woff;
        mshr_data[mshr_tail_q] <= req_data_i;
        mshr_mask[mshr_tail_q] <= req_mask_i;
        mshr_tail_q <= (mshr_tail_q == IDX_W'(MAX_MISSES-1)) ? '0
                                                             : IDX_W'(mshr_tail_q + 1);
      end
      if (fill_commit) begin
        mshr_v[mshr_head_q] <= 1'b0;
        mshr_head_q <= (mshr_head_q == IDX_W'(MAX_MISSES-1)) ? '0
                                                             : IDX_W'(mshr_head_q + 1);
      end
      if (miss_accept & ~fill_commit)      mshr_cnt_q <= CNT_W'(mshr_cnt_q + 1);
      else if (~miss_accept & fill_commit) mshr_cnt_q <= CNT_W'(mshr_cnt_q - 1);
    end
  end

  // ---------------------------------------------------------------------------
  // Response slot. Fill completion outranks a hit, so a hit stream cannot starve
  // a miss; a hit is otherwise answered the cycle after acceptance.
  // ---------------------------------------------------------------------------
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      rsp_valid_q <= 1'b0;
    end else begin
      if (fill_commit) begin
        rsp_valid_q <= 1'b1;
      end else if (hit_accept) begin
        rsp_valid_q <= 1'b1;
      end else if (rsp_ready_i) begin
        rsp_valid_q <= 1'b0;
      end
    end
  end

  always_ff @(posedge clk_i) begin
    if (fill_commit) begin
      rsp_id_q   <= head_id;
      rsp_data_q <= merged_word;
    end else if (hit_accept) begin
      rsp_id_q   <= req_id_i;
      rsp_data_q <= rd_line[req_woff*DATA_W +: DATA_W];
    end
  end

endmodule

/* verilator lint_on CASEINCOMPLETE */
/* verilator lint_on SYNCASYNCNET */
/* verilator lint_on UNOPTFLAT */
/* verilator lint_on DECLFILENAME */
/* verilator lint_on UNUSED */
/* verilator lint_on WIDTH */