// =============================================================================
// nonblocking_dcache_alt_ref.sv  --  SECOND SOURCE. NEVER SHIPPED, NEVER SCORED.
// =============================================================================
// An independently written implementation of spec/nonblocking_dcache_iface.sv.
// It shares no code with ref/nonblocking_dcache_ref.sv and does not instantiate
// the anchor.
//
// *** ITS JOB IS TO FAIL THE CHECKER, NOT TO PASS IT. ***
// It is a falsifier. When it fails, rule 5's disambiguation runs BEFORE anything
// is changed: run the failing input through the anchor; if this design disagrees
// with the anchor, THIS design is wrong. A clean first-run pass is the weaker
// result -- d_dsp02 failed three times and every adjudication came out "the
// second source is wrong", which is what made that checker credible.
//
// THE THREE DECLARED DIFFERENCES, named in tb/audit/SECOND_SOURCE_DIFFERENCES.md
// before a line of this file existed:
//
//   D1  MISS TRACKING. A file of per-line miss records, and a new miss is
//       compared against EVERY outstanding record. The anchor holds a FIFO of
//       requests and recognises a secondary only against the one line it is
//       servicing right now (mhu.sv:193).
//
//   D2  REPLACEMENT. True LRU: a per-set rank updated on every access, evicting
//       the genuinely least-recently-used way. The anchor uses tree pseudo-LRU.
//
//   D3" FILL FORWARDING. The requested word is returned off the fill stream on
//       the beat that carries it. The anchor waits for the whole block to land
//       and then replays -- measured flat at 13 cycles across all four word
//       offsets, with a throttle control confirming the measurement moves.
//
// AN INCIDENTAL DIFFERENCE, recorded because it is observable and was NOT
// declared: on a dirty replacement this writes the victim back BEFORE fetching,
// where the anchor fetches first. It is not claimed as one of the three -- D3
// originally proposed fetch-first and was refuted precisely because the anchor
// already does that.
// =============================================================================

module nonblocking_dcache #(
  parameter int unsigned DATA_W     = 32,
  parameter int unsigned SETS       = 16,
  parameter int unsigned WAYS       = 4,
  parameter int unsigned MAX_MISSES = 8
) (
  input  logic                     clk_i,
  input  logic                     rst_ni,

  input  logic                     req_valid_i,
  output logic                     req_ready_o,
  input  logic [3:0]               req_id_i,
  input  logic                     req_op_i,
  input  logic [31:0]              req_addr_i,
  input  logic [DATA_W-1:0]        req_data_i,
  input  logic [(DATA_W/8)-1:0]    req_mask_i,

  output logic                     rsp_valid_o,
  input  logic                     rsp_ready_i,
  output logic [3:0]               rsp_id_o,
  output logic [DATA_W-1:0]        rsp_data_o,

  output logic                     mem_req_valid_o,
  input  logic                     mem_req_ready_i,
  output logic                     mem_req_we_o,
  output logic [31:0]              mem_req_addr_o,

  input  logic                     mem_rd_valid_i,
  output logic                     mem_rd_ready_o,
  input  logic [DATA_W-1:0]        mem_rd_data_i,

  output logic                     mem_wr_valid_o,
  input  logic                     mem_wr_ready_i,
  output logic [DATA_W-1:0]        mem_wr_data_o
);

  localparam int unsigned ADDR_W      = 32;
  localparam int unsigned NIDS        = 16;
  localparam int unsigned BLOCK_WORDS = 4;
  localparam int unsigned BYTES_W     = DATA_W/8;
  localparam int unsigned WORD_SEL_W  = $clog2(BYTES_W);
  localparam int unsigned LG_BLK      = 2;
  localparam int unsigned BLK_OFF     = WORD_SEL_W + LG_BLK;
  localparam int unsigned LG_SETS     = $clog2(SETS);
  localparam int unsigned LG_WAYS     = $clog2(WAYS);
  localparam int unsigned TAG_W       = ADDR_W - BLK_OFF - LG_SETS;
  localparam int unsigned NMSHR       = MAX_MISSES;

  // ---------------------------------------------------------------- storage
  logic [TAG_W-1:0]  tag_q   [SETS][WAYS];
  logic              valid_q [SETS][WAYS];
  logic              dirty_q [SETS][WAYS];
  logic [DATA_W-1:0] data_q  [SETS][WAYS][BLOCK_WORDS];
  // D2: true LRU rank. 0 = most recently used, WAYS-1 = least.
  logic [2:0]        rank_q  [SETS][WAYS];

  // ---------------------------------------------------------------- miss records (D1)
  logic              m_v      [NMSHR];
  logic [TAG_W-1:0]  m_tag    [NMSHR];
  logic [LG_SETS-1:0] m_idx   [NMSHR];
  logic [LG_WAYS-1:0] m_way   [NMSHR];
  logic              m_wb     [NMSHR];   // victim needs writing back
  logic [TAG_W-1:0]  m_wbtag  [NMSHR];
  logic              m_issued [NMSHR];   // the memory engine has taken it
  logic              m_filled [NMSHR];   // block is in the array

  // ---------------------------------------------------------------- pending requests
  // Acceptance order is the array order between head and tail. R6 guarantees at
  // most one request per id in flight, so 16 slots can never overflow.
  logic              p_v    [NIDS];
  logic [3:0]        p_id   [NIDS];
  logic              p_op   [NIDS];
  logic [ADDR_W-1:0] p_addr [NIDS];
  logic [DATA_W-1:0] p_data [NIDS];
  logic [BYTES_W-1:0] p_mask[NIDS];
  logic [3:0]        p_m    [NIDS];
  logic [4:0]        p_head, p_tail;

  wire p_empty = (p_head == p_tail);
  wire p_full  = ((p_tail - p_head) >= 5'(NIDS));

  // ---------------------------------------------------------------- decode
  wire [TAG_W-1:0]   req_tag = req_addr_i[ADDR_W-1 -: TAG_W];
  wire [LG_SETS-1:0] req_idx = req_addr_i[BLK_OFF +: LG_SETS];
  wire [LG_BLK-1:0]  req_wof = req_addr_i[WORD_SEL_W +: LG_BLK];

  logic             hit;
  logic [LG_WAYS-1:0] hit_way;
  always_comb begin
    hit = 1'b0; hit_way = '0;
    for (int w = 0; w < int'(WAYS); w++)
      if (valid_q[req_idx][w] && (tag_q[req_idx][w] == req_tag)) begin
        hit = 1'b1; hit_way = LG_WAYS'(w);
      end
  end

  // D1: does any outstanding record already cover this line?
  logic             m_match;
  logic [3:0]       m_match_i;
  logic             m_free;
  logic [3:0]       m_free_i;
  always_comb begin
    m_match = 1'b0; m_match_i = '0; m_free = 1'b0; m_free_i = '0;
    for (int k = int'(NMSHR)-1; k >= 0; k--) begin
      if (m_v[k] && (m_tag[k] == req_tag) && (m_idx[k] == req_idx) && !m_filled[k]) begin
        m_match = 1'b1; m_match_i = 4'(k);
      end
      if (!m_v[k]) begin m_free = 1'b1; m_free_i = 4'(k); end
    end
  end

  // true-LRU victim for the request's set, EXCLUDING WAYS AN IN-FLIGHT RECORD
  // HAS ALREADY CLAIMED.
  //
  // FOUND BY A PER-LINE EVENT LOG, iteration 6, after five hypotheses were
  // instrumented and refuted. The log for idx=7:
  //
  //   t=295145 ALLOC rec=0 victim_way=1 newtag=1e | valid=1 dirty=1 -> m_wb=1
  //   t=295355 ALLOC rec=1 victim_way=1 newtag=20 | valid=0 dirty=1 -> m_wb=0
  //   t=295565 FILL-DONE rec=0 way=1 tag=1e
  //   t=295575 STORE-REP way=1 word=0            <- store merged into tag 1e
  //   t=295675 FILL-DONE rec=1 way=1 tag=20      <- overwrites tag 1e AND the store
  //
  // TWO RECORDS OWNED WAY 1 AT ONCE. rank_q is not updated until a record
  // allocates, so the LRU picker returned way 1 again 210 time units later while
  // rec=0's fill was still in flight. rec=1 then captured m_wb=0 -- correctly,
  // since rec=0 had already set valid_q=0 -- so when its fill overwrote a line
  // that had since become resident AND dirty, no writeback carried the store.
  // That is why NO writeback in the whole run carries the merged byte.
  //
  // The collision is on the WAY, not the LINE, which is why m_match was right
  // not to match (tags 1e and 20 differ) and why every line-keyed probe read 0.
  logic [WAYS-1:0] way_busy;
  always_comb begin
    way_busy = '0;
    for (int k = 0; k < int'(NMSHR); k++)
      if (m_v[k] && (m_idx[k] == req_idx)) way_busy[m_way[k]] = 1'b1;
  end

  logic [LG_WAYS-1:0] victim_way;
  logic               victim_ok;
  always_comb begin
    victim_way = '0; victim_ok = 1'b0;
    // oldest first, skipping ways an outstanding record is already replacing
    for (int r = int'(WAYS)-1; r >= 0; r--)
      for (int w = 0; w < int'(WAYS); w++)
        if (!victim_ok && (rank_q[req_idx][w] == 3'(r)) && !way_busy[w]) begin
          victim_way = LG_WAYS'(w); victim_ok = 1'b1;
        end
  end

  // ---------------------------------------------------------------- response port
  logic              rsp_v_q;
  logic [3:0]        rsp_id_q;
  logic [DATA_W-1:0] rsp_d_q;
  assign rsp_valid_o = rsp_v_q;
  assign rsp_id_o    = rsp_id_q;
  assign rsp_data_o  = rsp_d_q;
  wire rsp_slot_free = ~rsp_v_q | rsp_ready_i;

  // ---------------------------------------------------------------- memory engine
  typedef enum logic [2:0] { E_IDLE, E_WB_REQ, E_WB_DATA, E_FL_REQ, E_FL_DATA } est_e;
  est_e              est_q;
  logic [3:0]        cur_m;
  logic [LG_BLK:0]   beat_q;

  assign mem_req_valid_o = (est_q == E_WB_REQ) || (est_q == E_FL_REQ);
  assign mem_req_we_o    = (est_q == E_WB_REQ);
  assign mem_req_addr_o  = (est_q == E_WB_REQ)
      ? {m_wbtag[cur_m], m_idx[cur_m], {BLK_OFF{1'b0}}}
      : {m_tag[cur_m],   m_idx[cur_m], {BLK_OFF{1'b0}}};
  assign mem_wr_valid_o  = (est_q == E_WB_DATA);
  assign mem_wr_data_o   = data_q[m_idx[cur_m]][m_way[cur_m]][beat_q[LG_BLK-1:0]];
  assign mem_rd_ready_o  = (est_q == E_FL_DATA);

  // ---------------------------------------------------------------- acceptance
  //
  // FIX, 2026-08-29, iteration 4. CONFIRMED BY INSTRUMENTATION, not reasoned:
  // counters over one failing run gave
  //     fills=850  +same-cycle request=60  +same index=38  +same tag=36  +MISS=36
  // i.e. of 36 requests that arrived in the very cycle their own line's fill
  // completed, ALL 36 were declared a miss. `hit` reads valid_q combinationally
  // while the fill sets it with a non-blocking assignment, so a same-cycle
  // request can never see the line it is asking for. It then ALLOCATES A SECOND
  // RECORD for a line that is already becoming resident, and the re-fetch
  // overwrites the block -- discarding a store already applied to it. That loses
  // exactly one word, which is the reported symptom (`got=..dd exp=..c9`).
  //
  // THE FIX IS TO DECLINE THE REQUEST FOR ONE CYCLE, not to bypass the data.
  // A bypass would have to forward valid_q AND tag_q AND the last fill beat,
  // since data_q's final word is written by the same non-blocking assignment;
  // three forwards to avoid one stall cycle. Latency is FREE here (L6) and this
  // fires on 36 of 850 fills, so the stall is the cheaper and far smaller
  // change. The request retries next cycle and hits normally.
  wire fill_last = (est_q == E_FL_DATA) & mem_rd_valid_i
                 & (beat_q == (LG_BLK+1)'(BLOCK_WORDS-1));
  wire fill_shadow = fill_last & (req_idx == m_idx[cur_m]) & (req_tag == m_tag[cur_m]);

  // R5, SAME-WORD ORDERING. accept_hit consulted the ARRAY only and never the
  // pending queue, so a load that hit could be answered while an OLDER store to
  // the same word was still queued and unreplayed -- returning the pre-store
  // value for a request the contract orders after it.
  //
  // FOUND BY LOGGING EVERY RESPONSE WITH ITS PRODUCER, iteration 8:
  //   t=210695 HIT    id=7 addr=00000f20 idx=2 way=0 word=0 data=599203c9
  //   t=210705 REPLAY id=1 addr=00000f20 idx=2 way=0 word=0 op=1
  // the hit is answered one cycle before the store to the same word replays.
  // Counted over a full run: 320 hits, exactly ONE over a pending same-word
  // entry, and that one is a store. A single occurrence, which is why every
  // aggregate probe missed it and why the response log found it immediately.
  //
  // The request is DECLINED for as long as the older entry is pending; it
  // retries and hits normally once the replay clears p_v. No circular wait: a
  // hit needs no record, and the pending store replays as soon as its own
  // record fills. Latency is free here (L6).
  logic pend_same_word;
  always_comb begin
    pend_same_word = 1'b0;
    for (int j = 0; j < int'(NIDS); j++)
      if (p_v[j] && (p_addr[j][31:WORD_SEL_W] == req_addr_i[31:WORD_SEL_W]))
        pend_same_word = 1'b1;
  end

  wire accept_hit  = req_valid_i & hit & rsp_slot_free & ~p_full & ~pend_same_word;
  // and a miss may not allocate when EVERY way in the set is already claimed by
  // an in-flight record -- there is nowhere to put the line. It retries.
  wire accept_miss = req_valid_i & ~hit & ~p_full & (m_match | (m_free & victim_ok))
                   & ~fill_shadow;
  assign req_ready_o = accept_hit | accept_miss;

  // ---------------------------------------------------------------- replay pick
  // Oldest pending entry whose record has filled.
  logic       rep_v;
  logic [4:0] rep_s;
  always_comb begin
    rep_v = 1'b0; rep_s = '0;
    for (int j = int'(NIDS)-1; j >= 0; j--) begin
      automatic logic [4:0] s = p_head + 5'(j);
      if (((p_tail - p_head) > 5'(j)) && p_v[s[3:0]] && m_filled[p_m[s[3:0]]]) begin
        rep_v = 1'b1; rep_s = s;
      end
    end
  end
  wire [3:0] rep_i = rep_s[3:0];

  // D3": the oldest pending entry attached to the record being filled. Only the
  // oldest is eligible, which is what keeps R5 safe -- no earlier request to the
  // same word can exist ahead of it.
  logic       fw_v;
  logic [3:0] fw_i;
  always_comb begin
    fw_v = 1'b0; fw_i = '0;
    if (est_q == E_FL_DATA) begin
      for (int j = int'(NIDS)-1; j >= 0; j--) begin
        automatic logic [4:0] s = p_head + 5'(j);
        if (((p_tail - p_head) > 5'(j)) && p_v[s[3:0]] && (p_m[s[3:0]] == cur_m)) begin
          fw_v = 1'b1; fw_i = s[3:0];
        end
      end
      // eligible only if it is a LOAD wanting exactly this beat
      if (fw_v && !(~p_op[fw_i] && (p_addr[fw_i][WORD_SEL_W +: LG_BLK] == beat_q[LG_BLK-1:0])))
        fw_v = 1'b0;
    end
  end
  wire fw_fire = fw_v & mem_rd_valid_i & rsp_slot_free & ~accept_hit;
  wire rep_fire = rep_v & rsp_slot_free & ~accept_hit & ~fw_fire;

  // ---------------------------------------------------------------- sequential
  integer i, w, k, b;
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      // P1: every line invalid at the first request. This design clears its own
      // tags on reset, which P1 states is equally conformant.
      for (i = 0; i < int'(SETS); i++)
        for (w = 0; w < int'(WAYS); w++) begin
          valid_q[i][w] <= 1'b0;
          dirty_q[i][w] <= 1'b0;
          tag_q[i][w]   <= '0;
          rank_q[i][w]  <= 3'(w);
        end
      for (k = 0; k < int'(NMSHR); k++) begin
        m_v[k] <= 1'b0; m_issued[k] <= 1'b0; m_filled[k] <= 1'b0; m_wb[k] <= 1'b0;
      end
      for (i = 0; i < int'(NIDS); i++) p_v[i] <= 1'b0;
      p_head <= '0; p_tail <= '0;
      rsp_v_q <= 1'b0; rsp_id_q <= '0; rsp_d_q <= '0;
      est_q <= E_IDLE; cur_m <= '0; beat_q <= '0;
    end
    else begin
      // ---- response register ------------------------------------------------
      if (rsp_v_q && rsp_ready_i) rsp_v_q <= 1'b0;

      // ---- accept -----------------------------------------------------------
      if (req_valid_i && req_ready_o) begin
        if (hit) begin
          // D2: true LRU update on every access
          for (w = 0; w < int'(WAYS); w++)
            if (rank_q[req_idx][w] < rank_q[req_idx][hit_way]) rank_q[req_idx][w] <= rank_q[req_idx][w] + 3'd1;
          rank_q[req_idx][hit_way] <= 3'd0;
          if (req_op_i) begin
            for (b = 0; b < int'(BYTES_W); b++)
              if (req_mask_i[b]) data_q[req_idx][hit_way][req_wof][b*8 +: 8] <= req_data_i[b*8 +: 8];
            dirty_q[req_idx][hit_way] <= 1'b1;
            rsp_d_q <= '0;
          end
          else rsp_d_q <= data_q[req_idx][hit_way][req_wof];
          rsp_v_q  <= 1'b1;
          rsp_id_q <= req_id_i;
        end
        else begin
          // miss: park it and attach to a record
          p_v   [p_tail[3:0]] <= 1'b1;
          p_id  [p_tail[3:0]] <= req_id_i;
          p_op  [p_tail[3:0]] <= req_op_i;
          p_addr[p_tail[3:0]] <= req_addr_i;
          p_data[p_tail[3:0]] <= req_data_i;
          p_mask[p_tail[3:0]] <= req_mask_i;
          p_tail              <= p_tail + 5'd1;
          if (m_match) begin
            // D1: merge against ANY outstanding record, not just the current one
            p_m[p_tail[3:0]] <= m_match_i;
          end
          else begin
            p_m[p_tail[3:0]]  <= m_free_i;
            m_v     [m_free_i] <= 1'b1;
            m_tag   [m_free_i] <= req_tag;
            m_idx   [m_free_i] <= req_idx;
            m_way   [m_free_i] <= victim_way;
            m_wb    [m_free_i] <= valid_q[req_idx][victim_way] & dirty_q[req_idx][victim_way];
            m_wbtag [m_free_i] <= tag_q[req_idx][victim_way];
            m_issued[m_free_i] <= 1'b0;
            m_filled[m_free_i] <= 1'b0;
            // the victim is being taken now; stop it being picked again
            valid_q[req_idx][victim_way] <= 1'b0;
            for (w = 0; w < int'(WAYS); w++)
              if (rank_q[req_idx][w] < rank_q[req_idx][victim_way]) rank_q[req_idx][w] <= rank_q[req_idx][w] + 3'd1;
            rank_q[req_idx][victim_way] <= 3'd0;
          end
        end
      end

      // ---- D3'': forward the requested word off the fill stream -------------
      if (fw_fire) begin
        rsp_v_q  <= 1'b1;
        rsp_id_q <= p_id[fw_i];
        rsp_d_q  <= mem_rd_data_i;
        p_v[fw_i] <= 1'b0;
      end

      // ---- replay -----------------------------------------------------------
      if (rep_fire) begin
        automatic logic [LG_SETS-1:0] ri = p_addr[rep_i][BLK_OFF +: LG_SETS];
        automatic logic [LG_BLK-1:0]  rw = p_addr[rep_i][WORD_SEL_W +: LG_BLK];
        automatic logic [LG_WAYS-1:0] rway = m_way[p_m[rep_i]];
        if (p_op[rep_i]) begin
          for (b = 0; b < int'(BYTES_W); b++)
            if (p_mask[rep_i][b]) data_q[ri][rway][rw][b*8 +: 8] <= p_data[rep_i][b*8 +: 8];
          dirty_q[ri][rway] <= 1'b1;
          rsp_d_q <= '0;
        end
        else rsp_d_q <= data_q[ri][rway][rw];
        rsp_v_q   <= 1'b1;
        rsp_id_q  <= p_id[rep_i];
        p_v[rep_i] <= 1'b0;
      end

      // ---- retire finished pending entries from the head --------------------
      if (!p_empty && !p_v[p_head[3:0]]) p_head <= p_head + 5'd1;

      // ---- memory engine ----------------------------------------------------
      case (est_q)
        E_IDLE: begin
          for (k = int'(NMSHR)-1; k >= 0; k--)
            if (m_v[k] && !m_issued[k]) begin
              cur_m   <= 4'(k);
              beat_q  <= '0;
              est_q   <= m_wb[k] ? E_WB_REQ : E_FL_REQ;
            end
        end
        E_WB_REQ: if (mem_req_ready_i) begin est_q <= E_WB_DATA; beat_q <= '0; end
        E_WB_DATA: if (mem_wr_ready_i) begin
          if (beat_q == (LG_BLK+1)'(BLOCK_WORDS-1)) begin est_q <= E_FL_REQ; beat_q <= '0; end
          else beat_q <= beat_q + 1'b1;
        end
        E_FL_REQ: if (mem_req_ready_i) begin est_q <= E_FL_DATA; beat_q <= '0; end
        E_FL_DATA: if (mem_rd_valid_i) begin
          data_q[m_idx[cur_m]][m_way[cur_m]][beat_q[LG_BLK-1:0]] <= mem_rd_data_i;
          if (beat_q == (LG_BLK+1)'(BLOCK_WORDS-1)) begin
            tag_q  [m_idx[cur_m]][m_way[cur_m]] <= m_tag[cur_m];
            valid_q[m_idx[cur_m]][m_way[cur_m]] <= 1'b1;
            dirty_q[m_idx[cur_m]][m_way[cur_m]] <= 1'b0;
            m_filled[cur_m] <= 1'b1;
            m_issued[cur_m] <= 1'b1;
            est_q  <= E_IDLE;
          end
          else beat_q <= beat_q + 1'b1;
        end
        default: est_q <= E_IDLE;
      endcase

      // ---- free a record once nothing references it -------------------------
      for (k = 0; k < int'(NMSHR); k++) begin
        automatic logic any_ref = 1'b0;
        for (i = 0; i < int'(NIDS); i++)
          if (p_v[i] && (p_m[i] == 4'(k))) any_ref = 1'b1;
        if (m_v[k] && m_filled[k] && !any_ref) m_v[k] <= 1'b0;
      end
    end
  end

endmodule
