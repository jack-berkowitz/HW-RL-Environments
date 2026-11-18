// =============================================================================
// axi4_xbar -- NUM_MST x NUM_SLV AXI4 crossbar.
//
// Architecture (per contract):
//   * Per-master outstanding-ID table (MAX_TRANS entries).  A master may not
//     have two outstanding transactions with the SAME id; this makes per-ID
//     response ordering (O1/O4) structural and still allows MAX_TRANS
//     concurrent transactions with distinct ids (C1).
//   * AW/AR payload FIFOs (depth 2) decouple the master ports from the
//     per-slave round-robin arbiters, so no *_ready depends combinationally
//     on the matching *_valid (H1).
//   * W beats are routed by a per-master write-target FIFO in AW order (O3),
//     forwarded only after the corresponding AW reached the slave, through a
//     one-deep output register per slave port (<= 1 buffered W beat per
//     master port, C3).
//   * R/B responses are routed by the master index carried in the widened id,
//     with round-robin arbitration per master port and burst-contiguity
//     holds (O4).  No response data is buffered at all (C3).
//   * Unmapped addresses are answered internally with RESP_DECERR (D2).
//   * All arbiters are round-robin (L1/L2).
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

  localparam int SLVW = (NUM_SLV > 1) ? $clog2(NUM_SLV) : 1;
  localparam int MSTW = $clog2(NUM_MST);
  localparam int TW   = $clog2(MAX_TRANS);
  localparam int NSRC = NUM_SLV + 1;      // response sources: slaves + internal
  localparam int SRCW = $clog2(NSRC);

  // ---------------------------------------------------------------------------
  // round-robin pick: index of first set bit at or after ptr (wrapping)
  // ---------------------------------------------------------------------------
  function automatic int unsigned rr_pick(input int unsigned n,
                                          input logic [31:0] rq,
                                          input int unsigned ptr);
    logic [31:0] rot;
    int unsigned p;
    int unsigned sel;
    rot = (rq >> ptr) | (rq << (n - ptr));
    p  = 0;
    for (int unsigned k = 31; k > 0; k--) begin
      if (rot[k]) p = k;
    end
    if (rot[0]) p = 0;
    sel = p + ptr;
    if (sel >= n) sel = sel - n;
    return sel;
  endfunction

  // ---------------------------------------------------------------------------
  // state
  // ---------------------------------------------------------------------------
  // per master: AW payload fifo (depth 2)
  mst_aw_t [NUM_MST-1:0][1:0]            awf_q;
  logic    [NUM_MST-1:0][1:0][SLVW-1:0]  awf_t;
  logic    [NUM_MST-1:0][1:0]            awf_cnt;
  logic    [NUM_MST-1:0]                 awf_head;

  // per master: AR payload fifo (depth 2)
  mst_ar_t [NUM_MST-1:0][1:0]            arf_q;
  logic    [NUM_MST-1:0][1:0][SLVW-1:0]  arf_t;
  logic    [NUM_MST-1:0][1:0]            arf_cnt;
  logic    [NUM_MST-1:0]                 arf_head;

  // per master: outstanding-id table
  logic    [NUM_MST-1:0][MAX_TRANS-1:0]  t_v;
  slv_id_t [NUM_MST-1:0][MAX_TRANS-1:0]  t_id;

  // per master: write-target fifo (AW order, pops on W last)
  logic    [NUM_MST-1:0][MAX_TRANS-1:0]          wr_de;
  logic    [NUM_MST-1:0][MAX_TRANS-1:0][SLVW-1:0] wr_tgt;
  logic    [NUM_MST-1:0][TW-1:0]                 wr_head;
  logic    [NUM_MST-1:0][TW:0]                   wr_cnt;   // total entries
  logic    [NUM_MST-1:0][TW:0]                   wr_mcnt;  // mapped entries

  // per master: decode-error slot (one at a time)
  logic    [NUM_MST-1:0]   d_v, d_wr, d_wd;
  slv_id_t [NUM_MST-1:0]   d_id;
  logic    [NUM_MST-1:0][7:0] d_len, d_cnt;

  // per master: response-channel arbitration
  logic    [NUM_MST-1:0]              rg_act, bg_act;
  logic    [NUM_MST-1:0][SRCW-1:0]    rg_cur, bg_cur, r_ptr, b_ptr;

  // per slave: AW/AR/W grant holds + rr pointers + W output register
  logic    [NUM_SLV-1:0]              ag_act, arg_act, wg_act;
  logic    [NUM_SLV-1:0][MSTW-1:0]    ag_cur, arg_cur, wg_cur;
  logic    [NUM_SLV-1:0][MSTW-1:0]    aw_ptr, ar_ptr, w_ptr;
  logic    [NUM_SLV-1:0]              wv;
  w_t      [NUM_SLV-1:0]              wq;

  // ---------------------------------------------------------------------------
  // combinational signals (module scope)
  // ---------------------------------------------------------------------------
  logic [NUM_MST-1:0]              aw_hit, ar_hit;
  logic [NUM_MST-1:0][SLVW-1:0]    aw_tgt_c, ar_tgt_c;
  logic [NUM_MST-1:0]              aw_rdy, ar_rdy, aw_fire, ar_fire;
  logic [NUM_MST-1:0]              aw_idbusy, ar_idbusy, ar_free_ok;
  logic [NUM_MST-1:0][TW-1:0]      t_alloc_aw, t_alloc_ar;
  logic [NUM_MST-1:0][TW:0]        t_cnt;
  logic [NUM_MST-1:0]              awf_tl, arf_tl;
  logic [NUM_MST-1:0][TW-1:0]      wr_tl;
  logic [NUM_MST-1:0]              awf_pop, arf_pop, wr_pop;
  logic [NUM_MST-1:0]              w_rdy, w_fire;
  logic [NUM_MST-1:0]              r_gv, b_gv, r_fire, b_fire, r_last;
  logic [NUM_MST-1:0]              r_sel, b_sel, r_free_en, b_free_en;
  logic [NUM_MST-1:0][SRCW-1:0]    r_src, b_src;
  logic [NUM_MST-1:0][SLV_ID_W-1:0] r_free_id, b_free_id;
  logic [NUM_SLV-1:0][NUM_MST-1:0] aw_rq, ar_rq, w_rq;
  logic [NUM_SLV-1:0]              aw_gv, ar_gv, w_gv, aw_sh, ar_sh, w_cap;
  logic [NUM_SLV-1:0][MSTW-1:0]    aw_gm, ar_gm, w_gm;
  logic [NUM_SLV-1:0]              r_rdy_s, b_rdy_s;

  // ---------------------------------------------------------------------------
  // decode / acceptance / table scan (per master)
  // ---------------------------------------------------------------------------
  always_comb begin
    for (int m = 0; m < NUM_MST; m++) begin
      aw_hit[m]   = 1'b0;
      aw_tgt_c[m] = '0;
      ar_hit[m]   = 1'b0;
      ar_tgt_c[m] = '0;
      for (int i = 0; i < NUM_SLV; i++) begin
        if ((mst_req[m].aw.addr >= addr_map[i].start_addr) &&
            (mst_req[m].aw.addr <  addr_map[i].end_addr)) begin
          aw_hit[m] = 1'b1;
          if (addr_map[i].mst_port < NUM_SLV)
            aw_tgt_c[m] = addr_map[i].mst_port[SLVW-1:0];
          else
            aw_tgt_c[m] = i;
        end
        if ((mst_req[m].ar.addr >= addr_map[i].start_addr) &&
            (mst_req[m].ar.addr <  addr_map[i].end_addr)) begin
          ar_hit[m] = 1'b1;
          if (addr_map[i].mst_port < NUM_SLV)
            ar_tgt_c[m] = addr_map[i].mst_port[SLVW-1:0];
          else
            ar_tgt_c[m] = i;
        end
      end

      t_cnt[m] = d_v[m] ? 1 : 0;
      for (int e = 0; e < MAX_TRANS; e++)
        if (t_v[m][e]) t_cnt[m] = t_cnt[m] + 1;

      aw_idbusy[m] = d_v[m] && (d_id[m] == mst_req[m].aw.id);
      ar_idbusy[m] = d_v[m] && (d_id[m] == mst_req[m].ar.id);
      for (int e = 0; e < MAX_TRANS; e++) begin
        if (t_v[m][e] && (t_id[m][e] == mst_req[m].aw.id)) aw_idbusy[m] = 1'b1;
        if (t_v[m][e] && (t_id[m][e] == mst_req[m].ar.id)) ar_idbusy[m] = 1'b1;
      end

      aw_rdy[m] = (t_cnt[m] < MAX_TRANS) && !aw_idbusy[m] &&
                  (awf_cnt[m] < 2) && (wr_cnt[m] < MAX_TRANS) && !d_v[m];
      aw_fire[m] = mst_req[m].aw_valid && aw_rdy[m];

      t_alloc_aw[m] = '0;
      for (int e = MAX_TRANS-1; e >= 0; e--)
        if (!t_v[m][e]) t_alloc_aw[m] = e;

      t_alloc_ar[m] = '0;
      ar_free_ok[m] = 1'b0;
      for (int e = MAX_TRANS-1; e >= 0; e--)
        if (!t_v[m][e] && !(aw_fire[m] && (e == t_alloc_aw[m]))) begin
          t_alloc_ar[m] = e;
          ar_free_ok[m] = 1'b1;
        end

      ar_rdy[m] = (t_cnt[m] < MAX_TRANS) && !ar_idbusy[m] &&
                  (arf_cnt[m] < 2) && !d_v[m] && ar_free_ok[m] &&
                  !(aw_fire[m] && (mst_req[m].aw.id == mst_req[m].ar.id)) &&
                  !(aw_fire[m] && !aw_hit[m]);
      ar_fire[m] = mst_req[m].ar_valid && ar_rdy[m];

      awf_tl[m] = awf_head[m] ^ (awf_cnt[m] == 2'd1);
      arf_tl[m] = arf_head[m] ^ (arf_cnt[m] == 2'd1);
      wr_tl[m]  = wr_head[m] + wr_cnt[m][TW-1:0];
    end
  end

  // ---------------------------------------------------------------------------
  // per-slave AW / AR / W arbitration and forwarding
  // ---------------------------------------------------------------------------
  always_comb begin
    for (int s = 0; s < NUM_SLV; s++) begin
      for (int m = 0; m < NUM_MST; m++) begin
        aw_rq[s][m] = (awf_cnt[m] != 2'd0) && (awf_t[m][awf_head[m]] == s);
        ar_rq[s][m] = (arf_cnt[m] != 2'd0) && (arf_t[m][arf_head[m]] == s);
        w_rq[s][m]  = (wr_cnt[m] != '0) && !wr_de[m][wr_head[m]] &&
                      (wr_tgt[m][wr_head[m]] == s) &&
                      (wr_mcnt[m] > awf_cnt[m]);
      end

      if (ag_act[s]) begin
        aw_gv[s] = 1'b1;
        aw_gm[s] = ag_cur[s];
      end else if (aw_rq[s] != '0) begin
        aw_gv[s] = 1'b1;
        aw_gm[s] = rr_pick(NUM_MST, aw_rq[s], aw_ptr[s]);
      end else begin
        aw_gv[s] = 1'b0;
        aw_gm[s] = '0;
      end

      if (arg_act[s]) begin
        ar_gv[s] = 1'b1;
        ar_gm[s] = arg_cur[s];
      end else if (ar_rq[s] != '0) begin
        ar_gv[s] = 1'b1;
        ar_gm[s] = rr_pick(NUM_MST, ar_rq[s], ar_ptr[s]);
      end else begin
        ar_gv[s] = 1'b0;
        ar_gm[s] = '0;
      end

      if (wg_act[s]) begin
        w_gv[s] = 1'b1;
        w_gm[s] = wg_cur[s];
      end else if (w_rq[s] != '0) begin
        w_gv[s] = 1'b1;
        w_gm[s] = rr_pick(NUM_MST, w_rq[s], w_ptr[s]);
      end else begin
        w_gv[s] = 1'b0;
        w_gm[s] = '0;
      end

      aw_sh[s] = rst_n && aw_gv[s] && slv_resp[s].aw_ready;
      ar_sh[s] = rst_n && ar_gv[s] && slv_resp[s].ar_ready;
      w_cap[s] = rst_n && w_gv[s] && mst_req[w_gm[s]].w_valid &&
                 (!wv[s] || slv_resp[s].w_ready);
    end

    for (int m = 0; m < NUM_MST; m++) begin
      awf_pop[m] = 1'b0;
      arf_pop[m] = 1'b0;
      for (int s = 0; s < NUM_SLV; s++) begin
        if (aw_sh[s] && (aw_gm[s] == m)) awf_pop[m] = 1'b1;
        if (ar_sh[s] && (ar_gm[s] == m)) arf_pop[m] = 1'b1;
      end
    end
  end

  // ---------------------------------------------------------------------------
  // per-master write-data path (route by write-target fifo head)
  // ---------------------------------------------------------------------------
  always_comb begin
    for (int m = 0; m < NUM_MST; m++) begin
      if (wr_cnt[m] == '0) begin
        w_rdy[m] = 1'b0;
      end else if (wr_de[m][wr_head[m]]) begin
        w_rdy[m] = 1'b1;                       // swallow DECERR write data
      end else begin
        w_rdy[m] = 1'b0;
        for (int s = 0; s < NUM_SLV; s++) begin
          if (w_gv[s] && (w_gm[s] == m) && (wr_tgt[m][wr_head[m]] == s))
            w_rdy[m] = !wv[s] || slv_resp[s].w_ready;
        end
      end
      w_fire[m] = rst_n && mst_req[m].w_valid && w_rdy[m];
      wr_pop[m] = w_fire[m] && mst_req[m].w.last;
    end
  end

  // ---------------------------------------------------------------------------
  // per-master R / B response arbitration (sources: slaves + internal DECERR)
  // ---------------------------------------------------------------------------
  always_comb begin
    logic [NSRC-1:0] r_rq;
    logic [NSRC-1:0] b_rq;
    logic [SRCW-1:0] rsrc;
    logic [SRCW-1:0] bsrc;
    logic rsrc_v;
    logic bsrc_v;
    for (int m = 0; m < NUM_MST; m++) begin
      r_rq = '0;
      b_rq = '0;
      for (int s = 0; s < NUM_SLV; s++) begin
        r_rq[s] = slv_resp[s].r_valid &&
                  (slv_resp[s].r.id[MST_ID_W-1:SLV_ID_W] == m);
        b_rq[s] = slv_resp[s].b_valid &&
                  (slv_resp[s].b.id[MST_ID_W-1:SLV_ID_W] == m);
      end
      r_rq[NUM_SLV] = d_v[m] && !d_wr[m];
      b_rq[NUM_SLV] = d_v[m] &&  d_wr[m] && d_wd[m];

      if (rg_act[m]) begin
        rsrc = rg_cur[m];
      end else if (r_rq != '0) begin
        rsrc = rr_pick(NSRC, r_rq, r_ptr[m]);
      end else begin
        rsrc = '0;
      end
      r_src[m] = rsrc;
      r_sel[m] = rg_act[m] || (r_rq != '0);
      if (rsrc == NUM_SLV) rsrc_v = 1'b1;
      else rsrc_v = slv_resp[rsrc].r_valid;
      r_gv[m]   = rst_n && r_sel[m] && rsrc_v;
      r_fire[m] = r_gv[m] && mst_req[m].r_ready;
      if (rsrc == NUM_SLV) r_last[m] = (d_cnt[m] == d_len[m]);
      else r_last[m] = slv_resp[rsrc].r.last;
      r_free_en[m] = r_fire[m] && r_last[m] && (rsrc != NUM_SLV);
      r_free_id[m] = '0;
      if (rsrc != NUM_SLV) r_free_id[m] = slv_resp[rsrc].r.id[SLV_ID_W-1:0];

      if (bg_act[m]) begin
        bsrc = bg_cur[m];
      end else if (b_rq != '0) begin
        bsrc = rr_pick(NSRC, b_rq, b_ptr[m]);
      end else begin
        bsrc = '0;
      end
      b_src[m] = bsrc;
      b_sel[m] = bg_act[m] || (b_rq != '0);
      if (bsrc == NUM_SLV) bsrc_v = 1'b1;
      else bsrc_v = slv_resp[bsrc].b_valid;
      b_gv[m]   = rst_n && b_sel[m] && bsrc_v;
      b_fire[m] = b_gv[m] && mst_req[m].b_ready;
      b_free_en[m] = b_fire[m] && (bsrc != NUM_SLV);
      b_free_id[m] = '0;
      if (bsrc != NUM_SLV) b_free_id[m] = slv_resp[bsrc].b.id[SLV_ID_W-1:0];
    end
  end

  // response ready toward slaves (ready-to-ready only, no valid dependence)
  always_comb begin
    for (int s = 0; s < NUM_SLV; s++) begin
      r_rdy_s[s] = 1'b0;
      b_rdy_s[s] = 1'b0;
      for (int m = 0; m < NUM_MST; m++) begin
        if (r_sel[m] && (r_src[m] == s) && mst_req[m].r_ready) r_rdy_s[s] = 1'b1;
        if (b_sel[m] && (b_src[m] == s) && mst_req[m].b_ready) b_rdy_s[s] = 1'b1;
      end
    end
  end

  // ---------------------------------------------------------------------------
  // outputs toward masters
  // ---------------------------------------------------------------------------
  always_comb begin
    for (int m = 0; m < NUM_MST; m++) begin
      mst_resp[m].aw_ready = aw_rdy[m];
      mst_resp[m].ar_ready = ar_rdy[m];
      mst_resp[m].w_ready  = w_rdy[m];
      mst_resp[m].r_valid  = r_gv[m];
      mst_resp[m].b_valid  = b_gv[m];
      if (r_src[m] == NUM_SLV) begin
        mst_resp[m].r.id   = d_id[m];
        mst_resp[m].r.data = '0;
        mst_resp[m].r.resp = RESP_DECERR;
        mst_resp[m].r.last = (d_cnt[m] == d_len[m]);
        mst_resp[m].r.user = '0;
      end else begin
        mst_resp[m].r.id   = slv_resp[r_src[m]].r.id[SLV_ID_W-1:0];
        mst_resp[m].r.data = slv_resp[r_src[m]].r.data;
        mst_resp[m].r.resp = slv_resp[r_src[m]].r.resp;
        mst_resp[m].r.last = slv_resp[r_src[m]].r.last;
        mst_resp[m].r.user = slv_resp[r_src[m]].r.user;
      end
      if (b_src[m] == NUM_SLV) begin
        mst_resp[m].b.id   = d_id[m];
        mst_resp[m].b.resp = RESP_DECERR;
        mst_resp[m].b.user = '0;
      end else begin
        mst_resp[m].b.id   = slv_resp[b_src[m]].b.id[SLV_ID_W-1:0];
        mst_resp[m].b.resp = slv_resp[b_src[m]].b.resp;
        mst_resp[m].b.user = slv_resp[b_src[m]].b.user;
      end
    end
  end

  // ---------------------------------------------------------------------------
  // outputs toward slaves
  // ---------------------------------------------------------------------------
  always_comb begin
    for (int s = 0; s < NUM_SLV; s++) begin
      slv_req[s].aw_valid = rst_n && aw_gv[s];
      slv_req[s].aw       = awf_q[aw_gm[s]][awf_head[aw_gm[s]]];
      slv_req[s].ar_valid = rst_n && ar_gv[s];
      slv_req[s].ar       = arf_q[ar_gm[s]][arf_head[ar_gm[s]]];
      slv_req[s].w_valid  = rst_n && wv[s];
      slv_req[s].w        = wq[s];
      slv_req[s].b_ready  = b_rdy_s[s];
      slv_req[s].r_ready  = r_rdy_s[s];
    end
  end

  // ---------------------------------------------------------------------------
  // per-master sequential logic
  // ---------------------------------------------------------------------------
  genvar gi;
  generate
    for (gi = 0; gi < NUM_MST; gi++) begin : g_mst
      localparam logic [MST_IDX_W-1:0] GM = gi;

      always_ff @(posedge clk) begin
        if (!rst_n) begin
          awf_cnt[gi]  <= 2'd0;
          awf_head[gi] <= 1'b0;
          arf_cnt[gi]  <= 2'd0;
          arf_head[gi] <= 1'b0;
          wr_head[gi]  <= '0;
          wr_cnt[gi]   <= '0;
          wr_mcnt[gi]  <= '0;
          t_v[gi]      <= '0;
          d_v[gi]      <= 1'b0;
          d_wr[gi]     <= 1'b0;
          d_wd[gi]     <= 1'b0;
          d_cnt[gi]    <= '0;
          rg_act[gi]   <= 1'b0;
          bg_act[gi]   <= 1'b0;
          rg_cur[gi]   <= '0;
          bg_cur[gi]   <= '0;
          r_ptr[gi]    <= '0;
          b_ptr[gi]    <= '0;
        end else begin
          // ---- AW payload fifo ----
          if (aw_fire[gi] && aw_hit[gi]) begin
            awf_q[gi][awf_tl[gi]].id    <= {GM, mst_req[gi].aw.id};
            awf_q[gi][awf_tl[gi]].addr  <= mst_req[gi].aw.addr;
            awf_q[gi][awf_tl[gi]].len    <= mst_req[gi].aw.len;
            awf_q[gi][awf_tl[gi]].size   <= mst_req[gi].aw.size;
            awf_q[gi][awf_tl[gi]].burst  <= mst_req[gi].aw.burst;
            awf_q[gi][awf_tl[gi]].lock   <= mst_req[gi].aw.lock;
            awf_q[gi][awf_tl[gi]].cache  <= mst_req[gi].aw.cache;
            awf_q[gi][awf_tl[gi]].prot   <= mst_req[gi].aw.prot;
            awf_q[gi][awf_tl[gi]].qos    <= mst_req[gi].aw.qos;
            awf_q[gi][awf_tl[gi]].region <= mst_req[gi].aw.region;
            awf_q[gi][awf_tl[gi]].atop   <= mst_req[gi].aw.atop;
            awf_q[gi][awf_tl[gi]].user   <= mst_req[gi].aw.user;
            awf_t[gi][awf_tl[gi]]        <= aw_tgt_c[gi];
          end
          if (awf_pop[gi]) awf_head[gi] <= ~awf_head[gi];
          if (aw_fire[gi] && aw_hit[gi] && !awf_pop[gi])
            awf_cnt[gi] <= awf_cnt[gi] + 2'd1;
          if (!(aw_fire[gi] && aw_hit[gi]) && awf_pop[gi])
            awf_cnt[gi] <= awf_cnt[gi] - 2'd1;

          // ---- AR payload fifo ----
          if (ar_fire[gi] && ar_hit[gi]) begin
            arf_q[gi][arf_tl[gi]].id    <= {GM, mst_req[gi].ar.id};
            arf_q[gi][arf_tl[gi]].addr  <= mst_req[gi].ar.addr;
            arf_q[gi][arf_tl[gi]].len    <= mst_req[gi].ar.len;
            arf_q[gi][arf_tl[gi]].size   <= mst_req[gi].ar.size;
            arf_q[gi][arf_tl[gi]].burst  <= mst_req[gi].ar.burst;
            arf_q[gi][arf_tl[gi]].lock   <= mst_req[gi].ar.lock;
            arf_q[gi][arf_tl[gi]].cache  <= mst_req[gi].ar.cache;
            arf_q[gi][arf_tl[gi]].prot   <= mst_req[gi].ar.prot;
            arf_q[gi][arf_tl[gi]].qos    <= mst_req[gi].ar.qos;
            arf_q[gi][arf_tl[gi]].region <= mst_req[gi].ar.region;
            arf_q[gi][arf_tl[gi]].user   <= mst_req[gi].ar.user;
            arf_t[gi][arf_tl[gi]]        <= ar_tgt_c[gi];
          end
          if (arf_pop[gi]) arf_head[gi] <= ~arf_head[gi];
          if (ar_fire[gi] && ar_hit[gi] && !arf_pop[gi])
            arf_cnt[gi] <= arf_cnt[gi] + 2'd1;
          if (!(ar_fire[gi] && ar_hit[gi]) && arf_pop[gi])
            arf_cnt[gi] <= arf_cnt[gi] - 2'd1;

          // ---- write-target fifo ----
          if (aw_fire[gi]) begin
            wr_de[gi][wr_tl[gi]]  <= !aw_hit[gi];
            wr_tgt[gi][wr_tl[gi]] <= aw_tgt_c[gi];
          end
          if (wr_pop[gi]) wr_head[gi] <= wr_head[gi] + 1;
          if (aw_fire[gi] && !wr_pop[gi]) wr_cnt[gi] <= wr_cnt[gi] + 1;
          if (!aw_fire[gi] && wr_pop[gi]) wr_cnt[gi] <= wr_cnt[gi] - 1;
          if (aw_fire[gi] && aw_hit[gi] && !(wr_pop[gi] && !wr_de[gi][wr_head[gi]]))
            wr_mcnt[gi] <= wr_mcnt[gi] + 1;
          if (!(aw_fire[gi] && aw_hit[gi]) && wr_pop[gi] && !wr_de[gi][wr_head[gi]])
            wr_mcnt[gi] <= wr_mcnt[gi] - 1;

          // ---- outstanding-id table ----
          if (aw_fire[gi] && aw_hit[gi]) begin
            t_v[gi][t_alloc_aw[gi]]  <= 1'b1;
            t_id[gi][t_alloc_aw[gi]] <= mst_req[gi].aw.id;
          end
          if (ar_fire[gi] && ar_hit[gi]) begin
            t_v[gi][t_alloc_ar[gi]]  <= 1'b1;
            t_id[gi][t_alloc_ar[gi]] <= mst_req[gi].ar.id;
          end
          for (int e = 0; e < MAX_TRANS; e++) begin
            if (r_free_en[gi] && t_v[gi][e] && (t_id[gi][e] == r_free_id[gi]))
              t_v[gi][e] <= 1'b0;
            if (b_free_en[gi] && t_v[gi][e] && (t_id[gi][e] == b_free_id[gi]))
              t_v[gi][e] <= 1'b0;
          end

          // ---- decode-error slot ----
          if (aw_fire[gi] && !aw_hit[gi]) begin
            d_v[gi]  <= 1'b1;
            d_wr[gi] <= 1'b1;
            d_id[gi] <= mst_req[gi].aw.id;
            d_wd[gi] <= 1'b0;
          end
          if (ar_fire[gi] && !ar_hit[gi]) begin
            d_v[gi]   <= 1'b1;
            d_wr[gi]  <= 1'b0;
            d_id[gi]  <= mst_req[gi].ar.id;
            d_len[gi] <= mst_req[gi].ar.len;
            d_cnt[gi] <= '0;
          end
          if (wr_pop[gi] && wr_de[gi][wr_head[gi]]) d_wd[gi] <= 1'b1;
          if (r_fire[gi] && (r_src[gi] == NUM_SLV) && !r_last[gi])
            d_cnt[gi] <= d_cnt[gi] + 1;
          if (r_fire[gi] && r_last[gi] && (r_src[gi] == NUM_SLV)) d_v[gi] <= 1'b0;
          if (b_fire[gi] && (b_src[gi] == NUM_SLV)) d_v[gi] <= 1'b0;

          // ---- response-channel arbitration state ----
          if (r_fire[gi] && r_last[gi]) begin
            rg_act[gi] <= 1'b0;
            r_ptr[gi]  <= (r_src[gi] == NSRC-1) ? '0 : (r_src[gi] + 1);
          end else if (!rg_act[gi] && r_sel[gi]) begin
            rg_act[gi] <= 1'b1;
            rg_cur[gi] <= r_src[gi];
          end
          if (b_fire[gi]) begin
            bg_act[gi] <= 1'b0;
            b_ptr[gi]  <= (b_src[gi] == NSRC-1) ? '0 : (b_src[gi] + 1);
          end else if (!bg_act[gi] && b_sel[gi]) begin
            bg_act[gi] <= 1'b1;
            bg_cur[gi] <= b_src[gi];
          end
        end
      end
    end
  endgenerate

  // ---------------------------------------------------------------------------
  // per-slave sequential logic
  // ---------------------------------------------------------------------------
  genvar gj;
  generate
    for (gj = 0; gj < NUM_SLV; gj++) begin : g_slv
      always_ff @(posedge clk) begin
        if (!rst_n) begin
          ag_act[gj]  <= 1'b0;
          arg_act[gj] <= 1'b0;
          wg_act[gj]  <= 1'b0;
          ag_cur[gj]  <= '0;
          arg_cur[gj] <= '0;
          wg_cur[gj]  <= '0;
          aw_ptr[gj]  <= '0;
          ar_ptr[gj]  <= '0;
          w_ptr[gj]   <= '0;
          wv[gj]      <= 1'b0;
        end else begin
          if (aw_sh[gj]) begin
            ag_act[gj] <= 1'b0;
            aw_ptr[gj] <= (aw_gm[gj] == NUM_MST-1) ? '0 : (aw_gm[gj] + 1);
          end else if (!ag_act[gj] && (aw_rq[gj] != '0)) begin
            ag_act[gj] <= 1'b1;
            ag_cur[gj] <= aw_gm[gj];
          end

          if (ar_sh[gj]) begin
            arg_act[gj] <= 1'b0;
            ar_ptr[gj] <= (ar_gm[gj] == NUM_MST-1) ? '0 : (ar_gm[gj] + 1);
          end else if (!arg_act[gj] && (ar_rq[gj] != '0)) begin
            arg_act[gj] <= 1'b1;
            arg_cur[gj] <= ar_gm[gj];
          end

          if (w_cap[gj] && mst_req[w_gm[gj]].w.last) begin
            wg_act[gj] <= 1'b0;
            w_ptr[gj]  <= (w_gm[gj] == NUM_MST-1) ? '0 : (w_gm[gj] + 1);
          end else if (!wg_act[gj] && (w_rq[gj] != '0)) begin
            wg_act[gj] <= 1'b1;
            wg_cur[gj] <= w_gm[gj];
          end

          if (w_cap[gj]) begin
            wv[gj] <= 1'b1;
            wq[gj] <= mst_req[w_gm[gj]].w;
          end else if (slv_resp[gj].w_ready) begin
            wv[gj] <= 1'b0;
          end
        end
      end
    end
  endgenerate

endmodule
