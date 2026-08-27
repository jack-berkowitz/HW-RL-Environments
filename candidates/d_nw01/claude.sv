// =============================================================================
// axi4_xbar.sv -- AXI4 crossbar, NUM_MST masters x NUM_SLV slaves.
//
// THE TWO INVARIANTS THAT CARRY LIVENESS (L1), because routing is the easy part.
//
// (1) THE W-PATH CYCLE.  W beats carry no ID.  At a master port they belong to
//     that port's AWs in acceptance order (O3); at a slave port they must
//     arrive in THAT slave's AW acceptance order and may not interleave.  Two
//     FIFO orders established by different arbiters is a deadlock waiting to
//     happen:
//
//       Y accepted AW->s1 then AW->s0 ; s0 accepted AW from Y then from Z
//       Z accepted AW->s0             ; s1 accepted AW from Z then from Y
//       Y waits on s1, s1 waits on Z, Z waits on s0, s0 waits on Y.
//
//     Every transaction is routed correctly and nothing moves.  The usual two
//     escapes are closed here: buffering the burst (C3 caps storage at 4 beats)
//     and one global AW order (C2 requires disjoint pairs to run at 150%).
//
//     INVARIANT: all of a master port's W-incomplete AWs target ONE slave.
//     Enforced by w_dst/w_cnt below -- an AW may leave only if w_cnt == 0 or
//     its destination equals w_dst.  Then the master at the head of any slave's
//     W queue is waiting on THAT slave and no other, so the wait graph has no
//     edge leaving a {master, slave} pair and cannot contain a cycle.
//
//     It does NOT bound outstanding transactions: AWs awaiting B are
//     unrestricted, and consecutive AWs to the SAME slave are never delayed.
//     What it costs is running AW ahead of W across a destination change, which
//     is why the AW input FIFO is MAX_TRANS deep -- that is where C1's capacity
//     is honoured.  Measured, not assumed: with a 1-deep AW register this
//     design needed ~1500 cycles to reach C1's floor under 256-beat bursts with
//     round-robin destinations, and reaches it immediately with the FIFO.
//
// (2) PER-ID ORDERING (O1) is the same shape one level down: a request with ID
//     x may only go to a destination x is not already outstanding at.  Same ID
//     therefore never spans two slaves, so each slave's own per-ID ordering is
//     sufficient end to end, for both R and B.
//
// NO STARVATION (L2): every arbiter is round-robin with the pointer advanced
// past the winner.  AW/AR arbiters are per SLAVE and B/R arbiters per MASTER,
// so disjoint pairs share nothing (C2).
//
// BUFFERING (C3 ceiling: 4 R beats, 4 W beats per master port):
//     W: one 1-entry input register per master port  -> 1 beat
//     R: one 2-entry output FIFO   per master port   -> 2 beats
// Nothing else anywhere stores an R or a W beat.  AW/AR/B storage is not
// counted by C3.
//
// H1 (*_ready must not follow the corresponding *_valid): every master-facing
// ready is the fullness of a local register or FIFO, a function of state and of
// downstream ready only.  That also isolates us from a slave model whose
// w_ready follows its own w_valid, which would otherwise close a combinational
// loop from a master's w_valid back to its own w_ready.
//
// Declarations precede statements in every procedural block (T2); every loop
// bound is a constant and every array index is either constant or into a packed
// vector (T5, and no out-of-range elaboration).
// =============================================================================

module axi4_xbar
  import axi4_xbar_pkg::*;
#(
    parameter int NUM_MST   = 2,
    parameter int NUM_SLV   = 2,
    parameter int MAX_TRANS = 8,
    parameter int MAX_BURST_LEN = 3
) (
    input  logic clk,
    input  logic rst_n,

    input  slv_req_t  [NUM_MST-1:0] mst_req,
    output slv_resp_t [NUM_MST-1:0] mst_resp,

    output mst_req_t  [NUM_SLV-1:0] slv_req,
    input  mst_resp_t [NUM_SLV-1:0] slv_resp,

    input  xbar_rule_t [NUM_SLV-1:0] addr_map
);

  // ---------------------------------------------------------------------------
  // geometry.  Every depth below is a power of two so pointers wrap naturally.
  // ---------------------------------------------------------------------------
  localparam int NID    = 1 << SLV_ID_W;            // 16 tracked IDs
  localparam int ERR_S  = NUM_SLV;                  // pseudo-destination: decode error
  localparam int NSEL   = NUM_SLV + 1;
  localparam int SEL_W  = $clog2(NSEL);
  localparam int CNT_W  = $clog2(MAX_TRANS + 1);
  localparam int MIDX_W = (NUM_MST > 1) ? $clog2(NUM_MST) : 1;

  localparam int AWD    = MAX_TRANS;                // AW input FIFO depth (C1)
  localparam int AWP_W  = $clog2(AWD);
  localparam int AWC_W  = $clog2(AWD + 1);
  localparam int ARD    = 2;
  localparam int ARC_W  = 2;

  localparam int WFD    = NUM_MST * MAX_TRANS;      // W order queue per slave
  localparam int WFP_W  = $clog2(WFD);
  localparam int WFC_W  = $clog2(WFD + 1);

  localparam int NSRC   = NUM_SLV + 1;              // response sources per master
  localparam int SRC_W  = $clog2(NSRC);

  // ===========================================================================
  // state
  // ===========================================================================
  slv_aw_t [NUM_MST-1:0][AWD-1:0]   awf_d;
  logic    [NUM_MST-1:0][AWC_W-1:0] awf_cnt;
  logic    [NUM_MST-1:0][AWP_W-1:0] awf_rp, awf_wp;

  slv_ar_t [NUM_MST-1:0][ARD-1:0]   arf_d;
  logic    [NUM_MST-1:0][ARC_W-1:0] arf_cnt;
  logic    [NUM_MST-1:0]            arf_rp, arf_wp;

  w_t   [NUM_MST-1:0] wq_d;
  logic [NUM_MST-1:0] wq_v;

  logic [NUM_MST-1:0][NID-1:0][CNT_W-1:0] w_id_cnt, r_id_cnt;
  logic [NUM_MST-1:0][NID-1:0][SEL_W-1:0] w_id_sel, r_id_sel;
  logic [NUM_MST-1:0][SEL_W-1:0]          w_dst;
  logic [NUM_MST-1:0][CNT_W-1:0]          w_cnt;

  logic [NUM_MST-1:0][1:0]          errw_st;    // 0 idle, 1 eat W, 2 present B
  logic [NUM_MST-1:0][SLV_ID_W-1:0] errw_id;
  logic [NUM_MST-1:0]               errr_busy;
  logic [NUM_MST-1:0][SLV_ID_W-1:0] errr_id;
  logic [NUM_MST-1:0][8:0]          errr_rem;   // up to 256 beats

  slv_b_t [NUM_MST-1:0][1:0] bq_d;
  logic   [NUM_MST-1:0][1:0] bq_cnt;
  logic   [NUM_MST-1:0]      bq_rp, bq_wp;

  slv_r_t [NUM_MST-1:0][1:0] rq_d;              // 2 R beats per master (C3)
  logic   [NUM_MST-1:0][1:0] rq_cnt;
  logic   [NUM_MST-1:0]      rq_rp, rq_wp;

  logic [NUM_SLV-1:0]             aw_lk_v, ar_lk_v;
  logic [NUM_SLV-1:0][MIDX_W-1:0] aw_lk_i, ar_lk_i, aw_rr, ar_rr;

  logic [NUM_SLV-1:0][WFD-1:0][MIDX_W-1:0] wf_d;
  logic [NUM_SLV-1:0][WFC_W-1:0]           wf_cnt;
  logic [NUM_SLV-1:0][WFP_W-1:0]           wf_rp, wf_wp;

  logic [NUM_MST-1:0][SRC_W-1:0] b_rr, r_rr, r_lk_s;
  logic [NUM_MST-1:0]            r_lk_v;

  // ===========================================================================
  // combinational
  // ===========================================================================
  slv_aw_t [NUM_MST-1:0]           awh;
  slv_ar_t [NUM_MST-1:0]           arh;
  logic    [NUM_MST-1:0]           awh_v, arh_v;
  logic    [NUM_MST-1:0][SEL_W-1:0] aw_sel, ar_sel;
  logic    [NUM_MST-1:0]           aw_ok, ar_ok;

  logic [NUM_SLV-1:0][NUM_MST-1:0] aw_req, ar_req;
  logic [NUM_SLV-1:0][MIDX_W-1:0]  aw_win, ar_win;
  logic [NUM_SLV-1:0]              aw_win_v, ar_win_v;
  logic [NUM_SLV-1:0]              aw_drv, ar_drv, aw_hs, ar_hs;

  logic [NUM_MST-1:0] aw_err_hs, ar_err_hs, aw_pop, ar_pop;

  logic [NUM_SLV-1:0][MIDX_W-1:0] w_src;
  logic [NUM_SLV-1:0]             w_src_v, w_slv_hs, w_slv_last;
  logic [NUM_MST-1:0]             w_hs, w_last_hs;

  logic [NUM_MST-1:0][NSRC-1:0]  b_src_req, r_src_req;
  logic [NUM_MST-1:0]            b_take_v, r_take_v;
  logic [NUM_MST-1:0][SRC_W-1:0] b_take_s, r_take_s;
  slv_b_t [NUM_MST-1:0]          b_take_d;
  slv_r_t [NUM_MST-1:0]          r_take_d;
  logic [NUM_SLV-1:0]            slv_b_rdy, slv_r_rdy;

  logic [NUM_MST-1:0][NID-1:0] w_inc, w_dec, r_inc, r_dec;

  // ---------------------------------------------------------------------------
  // FIFO heads
  // ---------------------------------------------------------------------------
  always_comb begin
    int unsigned m;
    for (m = 0; m < NUM_MST; m++) begin
      awh[m]   = awf_d[m][awf_rp[m]];
      arh[m]   = arf_d[m][arf_rp[m]];
      awh_v[m] = (awf_cnt[m] != '0);
      arh_v[m] = (arf_cnt[m] != '0);
    end
  end

  // ---------------------------------------------------------------------------
  // D1/D2: decode on the ADDRESS ONLY.  qos, cache, prot and region are carried
  // through unmodified and never consulted (D3).  No rule match -> ERR_S, which
  // is answered internally rather than forwarded anywhere.
  // ---------------------------------------------------------------------------
  always_comb begin
    int unsigned m, s;
    for (m = 0; m < NUM_MST; m++) begin
      aw_sel[m] = SEL_W'(ERR_S);
      ar_sel[m] = SEL_W'(ERR_S);
      for (s = 0; s < NUM_SLV; s++) begin
        if ((addr_map[s].mst_port < NUM_SLV) &&
            (awh[m].addr >= addr_map[s].start_addr) &&
            (awh[m].addr <  addr_map[s].end_addr)) begin
          aw_sel[m] = SEL_W'(addr_map[s].mst_port);
        end
        if ((addr_map[s].mst_port < NUM_SLV) &&
            (arh[m].addr >= addr_map[s].start_addr) &&
            (arh[m].addr <  addr_map[s].end_addr)) begin
          ar_sel[m] = SEL_W'(addr_map[s].mst_port);
        end
      end
    end
  end

  // ---------------------------------------------------------------------------
  // Forwarding eligibility: the per-ID rule (O1) and, for writes, the single-W-
  // destination invariant (L1).
  // ---------------------------------------------------------------------------
  always_comb begin
    int unsigned m;
    logic id_ok, w_ok;
    for (m = 0; m < NUM_MST; m++) begin
      id_ok = (w_id_cnt[m][awh[m].id] == '0) ||
              ((w_id_sel[m][awh[m].id] == aw_sel[m]) &&
               (w_id_cnt[m][awh[m].id] < CNT_W'(MAX_TRANS)));
      w_ok  = ((w_cnt[m] == '0) || (w_dst[m] == aw_sel[m])) &&
              (w_cnt[m] < CNT_W'(MAX_TRANS));
      aw_ok[m] = awh_v[m] && id_ok && w_ok;
      ar_ok[m] = arh_v[m] &&
                 ((r_id_cnt[m][arh[m].id] == '0) ||
                  ((r_id_sel[m][arh[m].id] == ar_sel[m]) &&
                   (r_id_cnt[m][arh[m].id] < CNT_W'(MAX_TRANS))));
    end
  end

  // ---------------------------------------------------------------------------
  // per-slave AW/AR round-robin.  NUM_MST is a power of two, so the rotate is a
  // mask.  aw_req is a packed vector, so the runtime index is a mux.
  // ---------------------------------------------------------------------------
  always_comb begin
    int unsigned m, s, i;
    logic [MIDX_W-1:0] k;
    for (s = 0; s < NUM_SLV; s++) begin
      aw_req[s] = '0;
      ar_req[s] = '0;
      for (m = 0; m < NUM_MST; m++) begin
        if (aw_ok[m] && (aw_sel[m] == SEL_W'(s)) && (wf_cnt[s] < WFC_W'(WFD))) begin
          aw_req[s][m] = 1'b1;
        end
        if (ar_ok[m] && (ar_sel[m] == SEL_W'(s))) begin
          ar_req[s][m] = 1'b1;
        end
      end
      aw_win_v[s] = 1'b0;  aw_win[s] = '0;
      ar_win_v[s] = 1'b0;  ar_win[s] = '0;
      for (i = 0; i < NUM_MST; i++) begin
        k = MIDX_W'(aw_rr[s] + MIDX_W'(i));
        if (!aw_win_v[s] && aw_req[s][k]) begin
          aw_win_v[s] = 1'b1;
          aw_win[s]   = k;
        end
        k = MIDX_W'(ar_rr[s] + MIDX_W'(i));
        if (!ar_win_v[s] && ar_req[s][k]) begin
          ar_win_v[s] = 1'b1;
          ar_win[s]   = k;
        end
      end
      // The grant is registered and held while a transfer is pending, so the
      // slave-side valid and payload are stable until ready (H3).
      aw_drv[s] = aw_lk_v[s] && aw_req[s][aw_lk_i[s]];
      ar_drv[s] = ar_lk_v[s] && ar_req[s][ar_lk_i[s]];
      aw_hs[s]  = aw_drv[s] && slv_resp[s].aw_ready;
      ar_hs[s]  = ar_drv[s] && slv_resp[s].ar_ready;
    end
  end

  // ---------------------------------------------------------------------------
  // decode-error acceptance (per master; no arbitration)
  // ---------------------------------------------------------------------------
  always_comb begin
    int unsigned m;
    for (m = 0; m < NUM_MST; m++) begin
      aw_err_hs[m] = aw_ok[m] && (aw_sel[m] == SEL_W'(ERR_S)) && (errw_st[m] == 2'd0);
      ar_err_hs[m] = ar_ok[m] && (ar_sel[m] == SEL_W'(ERR_S)) && !errr_busy[m];
    end
  end

  // ---------------------------------------------------------------------------
  // W routing.  A slave takes W from the master at the head of its W order
  // queue; that master's own w_dst necessarily names this slave (the L1
  // invariant), so the two ends cannot disagree.
  // ---------------------------------------------------------------------------
  always_comb begin
    int unsigned m, s;
    for (s = 0; s < NUM_SLV; s++) begin
      w_src[s]      = wf_d[s][wf_rp[s]];
      w_src_v[s]    = 1'b0;
      w_slv_hs[s]   = 1'b0;
      w_slv_last[s] = 1'b0;
      if (wf_cnt[s] != '0) begin
        if (wq_v[w_src[s]] && (w_cnt[w_src[s]] != '0) &&
            (w_dst[w_src[s]] == SEL_W'(s))) begin
          w_src_v[s] = 1'b1;
        end
      end
      w_slv_hs[s]   = w_src_v[s] && slv_resp[s].w_ready;
      w_slv_last[s] = w_slv_hs[s] && wq_d[w_src[s]].last;
    end
    for (m = 0; m < NUM_MST; m++) begin
      w_hs[m]      = 1'b0;
      w_last_hs[m] = 1'b0;
      for (s = 0; s < NUM_SLV; s++) begin
        if (w_slv_hs[s] && (w_src[s] == MIDX_W'(m))) begin
          w_hs[m]      = 1'b1;
          w_last_hs[m] = wq_d[m].last;
        end
      end
      // swallowed by the decode-error responder
      if (wq_v[m] && (w_cnt[m] != '0) && (w_dst[m] == SEL_W'(ERR_S)) &&
          (errw_st[m] == 2'd1)) begin
        w_hs[m]      = 1'b1;
        w_last_hs[m] = wq_d[m].last;
      end
    end
  end

  // ---------------------------------------------------------------------------
  // B and R collection per master.  Source indices are CONSTANT in these loops,
  // so slv_resp is never indexed out of range.  B is a single beat and needs no
  // lock; R is LOCKED to its source for the whole burst so a burst's beats are
  // never split across sources (O4).
  // ---------------------------------------------------------------------------
  always_comb begin
    int unsigned m, i, s;
    logic [SRC_W-1:0] cand;
    logic found;

    for (m = 0; m < NUM_MST; m++) begin
      // request vectors
      for (i = 0; i < NSRC; i++) begin
        if (i == ERR_S) begin
          b_src_req[m][i] = (errw_st[m] == 2'd2);
          r_src_req[m][i] = errr_busy[m];
        end else if (i < NUM_SLV) begin
          b_src_req[m][i] = slv_resp[i].b_valid &&
                            (slv_resp[i].b.id[SLV_ID_W +: MST_IDX_W] == MST_IDX_W'(m));
          r_src_req[m][i] = slv_resp[i].r_valid &&
                            (slv_resp[i].r.id[SLV_ID_W +: MST_IDX_W] == MST_IDX_W'(m));
        end else begin
          b_src_req[m][i] = 1'b0;
          r_src_req[m][i] = 1'b0;
        end
      end

      // ---- B: round robin, two passes over CONSTANT indices ----
      b_take_v[m] = 1'b0;
      b_take_s[m] = '0;
      found       = 1'b0;
      if (bq_cnt[m] < 2'd2) begin
        for (i = 0; i < NSRC; i++) begin
          if (!found && (SRC_W'(i) >= b_rr[m]) && b_src_req[m][i]) begin
            found = 1'b1;  b_take_s[m] = SRC_W'(i);
          end
        end
        for (i = 0; i < NSRC; i++) begin
          if (!found && (SRC_W'(i) < b_rr[m]) && b_src_req[m][i]) begin
            found = 1'b1;  b_take_s[m] = SRC_W'(i);
          end
        end
        b_take_v[m] = found;
      end

      // ---- R: honour the lock, else round robin ----
      r_take_v[m] = 1'b0;
      r_take_s[m] = '0;
      if (rq_cnt[m] < 2'd2) begin
        if (r_lk_v[m]) begin
          if (r_src_req[m][r_lk_s[m]]) begin
            r_take_v[m] = 1'b1;
            r_take_s[m] = r_lk_s[m];
          end
        end else begin
          found = 1'b0;
          for (i = 0; i < NSRC; i++) begin
            if (!found && (SRC_W'(i) >= r_rr[m]) && r_src_req[m][i]) begin
              found = 1'b1;  r_take_s[m] = SRC_W'(i);
            end
          end
          for (i = 0; i < NSRC; i++) begin
            if (!found && (SRC_W'(i) < r_rr[m]) && r_src_req[m][i]) begin
              found = 1'b1;  r_take_s[m] = SRC_W'(i);
            end
          end
          r_take_v[m] = found;
        end
      end

      // ---- payload mux, again over CONSTANT source indices ----
      b_take_d[m]      = '0;
      b_take_d[m].id   = errw_id[m];
      b_take_d[m].resp = RESP_DECERR;
      r_take_d[m]      = '0;
      r_take_d[m].id   = errr_id[m];
      r_take_d[m].resp = RESP_DECERR;
      r_take_d[m].last = (errr_rem[m] == 9'd1);
      for (i = 0; i < NSRC; i++) begin
        if (i < NUM_SLV) begin
          if (b_take_s[m] == SRC_W'(i)) begin
            b_take_d[m].id   = slv_resp[i].b.id[SLV_ID_W-1:0];
            b_take_d[m].resp = slv_resp[i].b.resp;
            b_take_d[m].user = slv_resp[i].b.user;
          end
          if (r_take_s[m] == SRC_W'(i)) begin
            r_take_d[m].id   = slv_resp[i].r.id[SLV_ID_W-1:0];
            r_take_d[m].data = slv_resp[i].r.data;
            r_take_d[m].resp = slv_resp[i].r.resp;
            r_take_d[m].last = slv_resp[i].r.last;
            r_take_d[m].user = slv_resp[i].r.user;
          end
        end
      end
    end

    // ready back toward each slave's response channels
    for (s = 0; s < NUM_SLV; s++) begin
      slv_b_rdy[s] = 1'b0;
      slv_r_rdy[s] = 1'b0;
      for (m = 0; m < NUM_MST; m++) begin
        if (b_take_v[m] && (b_take_s[m] == SRC_W'(s))) slv_b_rdy[s] = 1'b1;
        if (r_take_v[m] && (r_take_s[m] == SRC_W'(s))) slv_r_rdy[s] = 1'b1;
      end
    end
  end

  // ---------------------------------------------------------------------------
  // AW/AR pop, one place, so w_cnt and the FIFOs agree on what left.
  // ---------------------------------------------------------------------------
  always_comb begin
    int unsigned m, s;
    for (m = 0; m < NUM_MST; m++) begin
      aw_pop[m] = aw_err_hs[m];
      ar_pop[m] = ar_err_hs[m];
      for (s = 0; s < NUM_SLV; s++) begin
        if (aw_hs[s] && (aw_lk_i[s] == MIDX_W'(m))) aw_pop[m] = 1'b1;
        if (ar_hs[s] && (ar_lk_i[s] == MIDX_W'(m))) ar_pop[m] = 1'b1;
      end
    end
  end

  // ---------------------------------------------------------------------------
  // SLAVE-SIDE OUTPUT ASSEMBLY -- the only driver of slv_req.
  // ---------------------------------------------------------------------------
  always_comb begin
    int unsigned s;
    slv_aw_t aw_s;
    slv_ar_t ar_s;
    for (s = 0; s < NUM_SLV; s++) begin
      aw_s = awh[aw_lk_i[s]];
      ar_s = arh[ar_lk_i[s]];

      slv_req[s]          = '0;

      slv_req[s].aw_valid = aw_drv[s] && rst_n;              // R1
      slv_req[s].aw.id    = {MST_IDX_W'(aw_lk_i[s]), aw_s.id};
      slv_req[s].aw.addr  = aw_s.addr;
      slv_req[s].aw.len   = aw_s.len;
      slv_req[s].aw.size  = aw_s.size;
      slv_req[s].aw.burst = aw_s.burst;
      slv_req[s].aw.lock  = aw_s.lock;
      slv_req[s].aw.cache = aw_s.cache;
      slv_req[s].aw.prot  = aw_s.prot;
      slv_req[s].aw.qos   = aw_s.qos;
      slv_req[s].aw.region= aw_s.region;
      slv_req[s].aw.atop  = aw_s.atop;
      slv_req[s].aw.user  = aw_s.user;

      slv_req[s].ar_valid = ar_drv[s] && rst_n;              // R1
      slv_req[s].ar.id    = {MST_IDX_W'(ar_lk_i[s]), ar_s.id};
      slv_req[s].ar.addr  = ar_s.addr;
      slv_req[s].ar.len   = ar_s.len;
      slv_req[s].ar.size  = ar_s.size;
      slv_req[s].ar.burst = ar_s.burst;
      slv_req[s].ar.lock  = ar_s.lock;
      slv_req[s].ar.cache = ar_s.cache;
      slv_req[s].ar.prot  = ar_s.prot;
      slv_req[s].ar.qos   = ar_s.qos;
      slv_req[s].ar.region= ar_s.region;
      slv_req[s].ar.user  = ar_s.user;

      slv_req[s].w        = wq_d[w_src[s]];
      slv_req[s].w_valid  = w_src_v[s] && rst_n;             // R1
      slv_req[s].b_ready  = slv_b_rdy[s];
      slv_req[s].r_ready  = slv_r_rdy[s];
    end
  end

  // ---------------------------------------------------------------------------
  // MASTER-SIDE OUTPUT ASSEMBLY -- the only driver of mst_resp.  Every ready is
  // local fullness, never the matching valid (H1).
  // ---------------------------------------------------------------------------
  always_comb begin
    int unsigned m;
    for (m = 0; m < NUM_MST; m++) begin
      mst_resp[m]          = '0;
      mst_resp[m].aw_ready = (awf_cnt[m] < AWC_W'(AWD)) || aw_pop[m];
      mst_resp[m].ar_ready = (arf_cnt[m] < ARC_W'(ARD)) || ar_pop[m];
      mst_resp[m].w_ready  = (!wq_v[m]) || w_hs[m];
      mst_resp[m].b_valid  = (bq_cnt[m] != 2'd0) && rst_n;   // R1
      mst_resp[m].b        = bq_d[m][bq_rp[m]];
      mst_resp[m].r_valid  = (rq_cnt[m] != 2'd0) && rst_n;   // R1
      mst_resp[m].r        = rq_d[m][rq_rp[m]];
    end
  end

  // ---------------------------------------------------------------------------
  // per-ID counter events: +1 when the request is forwarded, -1 when its
  // response is captured toward the master, so "outstanding" spans the round
  // trip and O1 cannot be broken by a response still in the output FIFO.
  // ---------------------------------------------------------------------------
  always_comb begin
    int unsigned m, s;
    w_inc = '0;  w_dec = '0;  r_inc = '0;  r_dec = '0;
    for (s = 0; s < NUM_SLV; s++) begin
      if (aw_hs[s]) w_inc[aw_lk_i[s]][awh[aw_lk_i[s]].id] = 1'b1;
      if (ar_hs[s]) r_inc[ar_lk_i[s]][arh[ar_lk_i[s]].id] = 1'b1;
    end
    for (m = 0; m < NUM_MST; m++) begin
      if (aw_err_hs[m]) w_inc[m][awh[m].id] = 1'b1;
      if (ar_err_hs[m]) r_inc[m][arh[m].id] = 1'b1;
      if (b_take_v[m]) w_dec[m][b_take_d[m].id] = 1'b1;
      if (r_take_v[m] && r_take_d[m].last) r_dec[m][r_take_d[m].id] = 1'b1;
    end
  end

  // ===========================================================================
  // sequential.  rst_n is ACTIVE-LOW and SYNCHRONOUS (R1/R2): reset discards
  // everything in flight, so no pre-reset response can be emitted afterwards.
  // ===========================================================================
  always_ff @(posedge clk) begin
    int unsigned m, s, i;
    logic push_aw, push_ar;
    if (!rst_n) begin
      awf_cnt   <= '0;  awf_rp <= '0;  awf_wp <= '0;
      arf_cnt   <= '0;  arf_rp <= '0;  arf_wp <= '0;
      wq_v      <= '0;
      w_id_cnt  <= '0;  r_id_cnt <= '0;
      w_id_sel  <= '0;  r_id_sel <= '0;
      w_dst     <= '0;  w_cnt    <= '0;
      errw_st   <= '0;  errw_id  <= '0;
      errr_busy <= '0;  errr_id  <= '0;  errr_rem <= '0;
      bq_cnt    <= '0;  bq_rp <= '0;  bq_wp <= '0;
      rq_cnt    <= '0;  rq_rp <= '0;  rq_wp <= '0;
      aw_lk_v   <= '0;  ar_lk_v <= '0;
      aw_lk_i   <= '0;  ar_lk_i <= '0;
      aw_rr     <= '0;  ar_rr <= '0;
      wf_cnt    <= '0;  wf_rp <= '0;  wf_wp <= '0;
      b_rr      <= '0;  r_rr  <= '0;
      r_lk_v    <= '0;  r_lk_s <= '0;
    end else begin
      for (m = 0; m < NUM_MST; m++) begin
        push_aw = mst_req[m].aw_valid && mst_resp[m].aw_ready;
        push_ar = mst_req[m].ar_valid && mst_resp[m].ar_ready;

        // ---- AW input FIFO (depth MAX_TRANS: this is C1's capacity) -------
        if (push_aw && !aw_pop[m])      awf_cnt[m] <= awf_cnt[m] + AWC_W'(1);
        else if (!push_aw && aw_pop[m]) awf_cnt[m] <= awf_cnt[m] - AWC_W'(1);
        if (push_aw) begin
          awf_d[m][awf_wp[m]] <= mst_req[m].aw;
          awf_wp[m]           <= awf_wp[m] + AWP_W'(1);
        end
        if (aw_pop[m]) awf_rp[m] <= awf_rp[m] + AWP_W'(1);

        // ---- AR input FIFO ------------------------------------------------
        if (push_ar && !ar_pop[m])      arf_cnt[m] <= arf_cnt[m] + ARC_W'(1);
        else if (!push_ar && ar_pop[m]) arf_cnt[m] <= arf_cnt[m] - ARC_W'(1);
        if (push_ar) begin
          arf_d[m][arf_wp[m]] <= mst_req[m].ar;
          arf_wp[m]           <= ~arf_wp[m];
        end
        if (ar_pop[m]) arf_rp[m] <= ~arf_rp[m];

        // ---- W input register: 1 beat per master port (C3) ----------------
        if (w_hs[m]) wq_v[m] <= 1'b0;
        if (mst_req[m].w_valid && mst_resp[m].w_ready) begin
          wq_v[m] <= 1'b1;
          wq_d[m] <= mst_req[m].w;
        end

        // ---- per-ID outstanding counters (O1) -----------------------------
        for (i = 0; i < NID; i++) begin
          if (w_inc[m][i] && !w_dec[m][i])      w_id_cnt[m][i] <= w_id_cnt[m][i] + CNT_W'(1);
          else if (!w_inc[m][i] && w_dec[m][i]) w_id_cnt[m][i] <= w_id_cnt[m][i] - CNT_W'(1);
          if (r_inc[m][i] && !r_dec[m][i])      r_id_cnt[m][i] <= r_id_cnt[m][i] + CNT_W'(1);
          else if (!r_inc[m][i] && r_dec[m][i]) r_id_cnt[m][i] <= r_id_cnt[m][i] - CNT_W'(1);
        end

        // ---- destination bookkeeping (L1 invariant + O1 selects) ----------
        if (aw_pop[m]) begin
          w_id_sel[m][awh[m].id] <= aw_sel[m];
          w_dst[m]               <= aw_sel[m];
        end
        if (ar_pop[m]) begin
          r_id_sel[m][arh[m].id] <= ar_sel[m];
        end
        if (aw_pop[m] && !w_last_hs[m])      w_cnt[m] <= w_cnt[m] + CNT_W'(1);
        else if (!aw_pop[m] && w_last_hs[m]) w_cnt[m] <= w_cnt[m] - CNT_W'(1);

        // ---- decode-error responders (D2) ---------------------------------
        if (aw_err_hs[m]) begin
          errw_st[m] <= 2'd1;
          errw_id[m] <= awh[m].id;
        end else if ((errw_st[m] == 2'd1) && w_hs[m] && w_last_hs[m]) begin
          errw_st[m] <= 2'd2;
        end else if ((errw_st[m] == 2'd2) && b_take_v[m] &&
                     (b_take_s[m] == SRC_W'(ERR_S))) begin
          errw_st[m] <= 2'd0;
        end
        if (ar_err_hs[m]) begin
          errr_busy[m] <= 1'b1;
          errr_id[m]   <= arh[m].id;
          errr_rem[m]  <= {1'b0, arh[m].len} + 9'd1;
        end else if (errr_busy[m] && r_take_v[m] &&
                     (r_take_s[m] == SRC_W'(ERR_S))) begin
          errr_rem[m] <= errr_rem[m] - 9'd1;
          if (errr_rem[m] == 9'd1) errr_busy[m] <= 1'b0;
        end

        // ---- B output FIFO -------------------------------------------------
        if (b_take_v[m] && !(mst_resp[m].b_valid && mst_req[m].b_ready)) begin
          bq_cnt[m] <= bq_cnt[m] + 2'd1;
        end else if (!b_take_v[m] && mst_resp[m].b_valid && mst_req[m].b_ready) begin
          bq_cnt[m] <= bq_cnt[m] - 2'd1;
        end
        if (b_take_v[m]) begin
          bq_d[m][bq_wp[m]] <= b_take_d[m];
          bq_wp[m]          <= ~bq_wp[m];
          b_rr[m]           <= (b_take_s[m] == SRC_W'(NSRC-1)) ? '0
                                                               : (b_take_s[m] + SRC_W'(1));
        end
        if (mst_resp[m].b_valid && mst_req[m].b_ready) bq_rp[m] <= ~bq_rp[m];

        // ---- R output FIFO: 2 R beats per master port (C3) -----------------
        if (r_take_v[m] && !(mst_resp[m].r_valid && mst_req[m].r_ready)) begin
          rq_cnt[m] <= rq_cnt[m] + 2'd1;
        end else if (!r_take_v[m] && mst_resp[m].r_valid && mst_req[m].r_ready) begin
          rq_cnt[m] <= rq_cnt[m] - 2'd1;
        end
        if (r_take_v[m]) begin
          rq_d[m][rq_wp[m]] <= r_take_d[m];
          rq_wp[m]          <= ~rq_wp[m];
          if (r_take_d[m].last) begin
            r_lk_v[m] <= 1'b0;
            r_rr[m]   <= (r_take_s[m] == SRC_W'(NSRC-1)) ? '0
                                                         : (r_take_s[m] + SRC_W'(1));
          end else begin
            r_lk_v[m] <= 1'b1;
            r_lk_s[m] <= r_take_s[m];
          end
        end
        if (mst_resp[m].r_valid && mst_req[m].r_ready) rq_rp[m] <= ~rq_rp[m];
      end

      for (s = 0; s < NUM_SLV; s++) begin
        // ---- W order queue: push the granted master, pop on its last beat --
        if (aw_hs[s] && !w_slv_last[s])      wf_cnt[s] <= wf_cnt[s] + WFC_W'(1);
        else if (!aw_hs[s] && w_slv_last[s]) wf_cnt[s] <= wf_cnt[s] - WFC_W'(1);
        if (aw_hs[s]) begin
          wf_d[s][wf_wp[s]] <= aw_lk_i[s];
          wf_wp[s]          <= wf_wp[s] + WFP_W'(1);
        end
        if (w_slv_last[s]) wf_rp[s] <= wf_rp[s] + WFP_W'(1);

        // ---- arbiter locks: hold while a transfer is pending, else
        //      re-arbitrate.  The pointer moves past the winner (L2).
        if (!(aw_drv[s] && !slv_resp[s].aw_ready)) begin
          aw_lk_v[s] <= aw_win_v[s];
          if (aw_win_v[s]) begin
            aw_lk_i[s] <= aw_win[s];
            aw_rr[s]   <= aw_win[s] + MIDX_W'(1);
          end
        end
        if (!(ar_drv[s] && !slv_resp[s].ar_ready)) begin
          ar_lk_v[s] <= ar_win_v[s];
          if (ar_win_v[s]) begin
            ar_lk_i[s] <= ar_win[s];
            ar_rr[s]   <= ar_win[s] + MIDX_W'(1);
          end
        end
      end
    end
  end

endmodule