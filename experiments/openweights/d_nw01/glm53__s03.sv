// =============================================================================
// axi4_xbar -- AXI4 crossbar, NUM_MST masters -> NUM_SLV slaves
//
// Architecture (chosen for deadlock/starvation freedom with ZERO beat
// buffering, satisfying the C3 ceiling trivially):
//   * AW/AR: one-deep registered request buffer per master (gives an H1-clean
//     aw_ready/ar_ready), then a round-robin grant per slave port.
//   * W:  per-master FIFO of write targets (pushed in AW order, so O3 holds).
//     Beats are steered cut-through to the slave named by the FIFO head, with
//     a round-robin lock per slave port so streams never interleave.  W is
//     held back until the matching AW has been accepted by that slave.
//   * R/B: cut-through from slave to the master named in the widened ID, with
//     a sticky round-robin source selection per master (H3 stability, and
//     per-ID burst contiguity).
//   * Ordering (O1/O4) is guaranteed by serialising per (master,ID): at most
//     one outstanding transaction per ID per master (16 IDs -> up to 16
//     outstanding per master, comfortably above the C1 floor).
//   * Unmapped addresses (D2) are completed by internal DECERR generators:
//     writes swallow their W beats and return one B; reads return len+1 R
//     beats from a small descriptor FIFO.
//   * Every arbiter is round-robin -> L2; no resource is acquired in
//     conflicting order -> L1; nothing is buffered -> C3.
// =============================================================================

import axi4_xbar_pkg::*;

module axi4_xbar
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

  localparam int WR_DEPTH = MAX_TRANS;
  localparam int DR_DEPTH = MAX_TRANS;
  localparam logic [2:0] WMASK  = WR_DEPTH - 1;
  localparam logic [2:0] DMASK  = DR_DEPTH - 1;
  localparam logic [1:0] MST_MSK = NUM_MST - 1;
  localparam logic [1:0] SLV_MSK = NUM_SLV - 1;

  // ---------------- helper functions ---------------------------------------
  // decode: returns {mapped, index[1:0]}
  function automatic logic [2:0] f_decode (input addr_t a);
    logic       v;
    logic [1:0] idx;
    v   = 1'b0;
    idx = 2'd0;
    for (int k = 0; k < NUM_SLV; k++) begin
      if (!v && (a >= addr_map[k].start_addr) && (a < addr_map[k].end_addr)) begin
        v   = 1'b1;
        idx = addr_map[k].mst_port[1:0];
      end
    end
    f_decode = {v, idx};
  endfunction

  // round-robin pick among masters (c[NUM_MST-1:0]); returns 0 if none
  function automatic logic [1:0] f_pick_m (input logic [1:0] ptr,
                                           input logic [NUM_MST-1:0] c);
    logic [1:0]  s;
    logic        f;
    logic [31:0] kk;
    s = 2'd0;
    f = 1'b0;
    for (int k = 0; k < NUM_MST; k++) begin
      kk = ptr + k;
      if (kk >= NUM_MST) kk = kk - NUM_MST;
      if (!f && c[kk[1:0]]) begin
        s = kk[1:0];
        f = 1'b1;
      end
    end
    f_pick_m = s;
  endfunction

  // round-robin pick among sources 0..NUM_SLV (slot NUM_SLV = internal decerr)
  function automatic logic [2:0] f_pick_s (input logic [2:0] ptr,
                                           input logic [4:0] c);
    logic [2:0]  s;
    logic        f;
    logic [31:0] kk;
    s = 3'd0;
    f = 1'b0;
    for (int k = 0; k <= NUM_SLV; k++) begin
      kk = ptr + k;
      if (kk > NUM_SLV) kk = kk - (NUM_SLV + 1);
      if (!f && c[kk[2:0]]) begin
        s = kk[2:0];
        f = 1'b1;
      end
    end
    f_pick_s = s;
  endfunction

  // ---------------- state ---------------------------------------------------
  slv_aw_t [NUM_MST-1:0]      aw_buf_q;
  logic    [NUM_MST-1:0]      aw_buf_v;
  logic    [NUM_MST-1:0][1:0] aw_buf_tgt;

  slv_ar_t [NUM_MST-1:0]      ar_buf_q;
  logic    [NUM_MST-1:0]      ar_buf_v;
  logic    [NUM_MST-1:0][1:0] ar_buf_tgt;

  // write-target fifo entry: [7]=decerr, [6:5]=target, [4:1]=id, [0]=user
  logic [NUM_MST-1:0][WR_DEPTH-1:0][7:0] wr_fifo;
  logic [NUM_MST-1:0][2:0] wr_head, wr_tail;
  logic [NUM_MST-1:0][3:0] wr_cnt;

  // decerr read descriptor: [12:9]=id, [8]=user, [7:0]=len
  logic [NUM_MST-1:0][DR_DEPTH-1:0][12:0] dr_fifo;
  logic [NUM_MST-1:0][2:0] dr_head, dr_tail;
  logic [NUM_MST-1:0][3:0] dr_cnt;
  logic [NUM_MST-1:0][7:0] dr_beat;

  logic [NUM_MST-1:0][15:0] idtab_r, idtab_w;

  logic    [NUM_MST-1:0] db_v;       // pending decerr write response
  slv_id_t [NUM_MST-1:0] db_id;
  user_t   [NUM_MST-1:0] db_user;

  logic [NUM_SLV-1:0]      awg_v, arg_v;   // registered AW/AR grant
  logic [NUM_SLV-1:0][1:0] awg_m, arg_m;
  logic [NUM_SLV-1:0][1:0] aw_ptr, ar_ptr;

  logic [NUM_SLV-1:0]      wl_v;           // registered W lock
  logic [NUM_SLV-1:0][1:0] wl_m, w_ptr;

  logic [NUM_MST-1:0]      rs_v, bs_v;     // sticky R/B source
  logic [NUM_MST-1:0][2:0] rs, bs;
  logic [NUM_MST-1:0][2:0] r_ptr, b_ptr;

  // ---------------- combinational nets --------------------------------------
  logic [NUM_MST-1:0][2:0] dec_aw, dec_ar;
  logic [NUM_MST-1:0]      aw_acc, ar_acc;
  logic [NUM_MST-1:0][7:0] wh;             // write fifo head entry
  logic [NUM_MST-1:0]      aw_block, w_elig, w_rdy, w_lasts;
  logic [NUM_MST-1:0][4:0] cnd_r, cnd_b;
  logic [NUM_MST-1:0][2:0] cur_rs, cur_bs;
  logic [NUM_MST-1:0]      r_vout, b_vout, r_hs, b_hs, r_last;
  logic [NUM_MST-1:0][3:0] r_bid, b_bid;
  logic [NUM_SLV-1:0][NUM_MST-1:0] aw_cnd, ar_cnd, w_cnd_m;
  logic [NUM_SLV-1:0]      aw_pickv, ar_pickv, aw_vout, ar_vout, aw_hs, ar_hs, w_hs;
  logic [NUM_SLV-1:0][1:0] aw_srv, ar_srv, w_srv, aw_pick, ar_pick;

  // ---------------- combinational -------------------------------------------
  always_comb begin
    logic [MST_IDX_W-1:0] mi;
    logic [1:0]           si;
    mi = '0;
    si = '0;

    // ==== phase 1: per-master ==============================================
    for (int i = 0; i < NUM_MST; i++) begin
      mi = MST_IDX_W'(i);

      mst_resp[i].aw_ready = rst_n && !aw_buf_v[i]
                             && !idtab_w[i][mst_req[i].aw.id]
                             && (wr_cnt[i] < WR_DEPTH);
      mst_resp[i].ar_ready = rst_n && !ar_buf_v[i]
                             && !idtab_r[i][mst_req[i].ar.id]
                             && (dr_cnt[i] < DR_DEPTH);
      aw_acc[i]  = mst_req[i].aw_valid && mst_resp[i].aw_ready;
      ar_acc[i]  = mst_req[i].ar_valid && mst_resp[i].ar_ready;
      dec_aw[i]  = f_decode(mst_req[i].aw.addr);
      dec_ar[i]  = f_decode(mst_req[i].ar.addr);
      wh[i]      = wr_fifo[i][wr_head[i][2:0]];
      aw_block[i] = aw_buf_v[i] && (wr_cnt[i] == 4'd1);
      w_elig[i]   = (wr_cnt[i] != 4'd0) && !aw_block[i];

      for (int j = 0; j < NUM_SLV; j++) begin
        cnd_r[i][j] = slv_resp[j].r_valid &&
                      (slv_resp[j].r.id[SLV_ID_W +: MST_IDX_W] == mi);
        cnd_b[i][j] = slv_resp[j].b_valid &&
                      (slv_resp[j].b.id[SLV_ID_W +: MST_IDX_W] == mi);
      end
      cnd_r[i][NUM_SLV] = (dr_cnt[i] != 4'd0);
      cnd_b[i][NUM_SLV] = db_v[i];
      for (int j = NUM_SLV + 1; j <= 4; j++) begin
        cnd_r[i][j] = 1'b0;
        cnd_b[i][j] = 1'b0;
      end

      // R source selection (sticky while the locked source has our beat)
      if (rs_v[i] && cnd_r[i][rs[i]]) begin
        cur_rs[i] = rs[i];
      end else begin
        cur_rs[i] = (|cnd_r[i]) ? f_pick_s(r_ptr[i], cnd_r[i]) : 3'd0;
      end
      r_vout[i] = cnd_r[i][cur_rs[i]];
      r_hs[i]   = r_vout[i] && mst_req[i].r_ready;
      if (cur_rs[i] == NUM_SLV) begin
        r_last[i] = (dr_beat[i] == dr_fifo[i][dr_head[i][2:0]][7:0]);
        r_bid[i]  = dr_fifo[i][dr_head[i][2:0]][12:9];
      end else begin
        si = cur_rs[i][1:0] & SLV_MSK;
        r_last[i] = slv_resp[si].r.last;
        r_bid[i]  = slv_resp[si].r.id[SLV_ID_W-1:0];
      end

      // B source selection
      if (bs_v[i] && cnd_b[i][bs[i]]) begin
        cur_bs[i] = bs[i];
      end else begin
        cur_bs[i] = (|cnd_b[i]) ? f_pick_s(b_ptr[i], cnd_b[i]) : 3'd0;
      end
      b_vout[i] = cnd_b[i][cur_bs[i]];
      b_hs[i]   = b_vout[i] && mst_req[i].b_ready;
      if (cur_bs[i] == NUM_SLV) begin
        b_bid[i] = db_id[i];
      end else begin
        si = cur_bs[i][1:0] & SLV_MSK;
        b_bid[i] = slv_resp[si].b.id[SLV_ID_W-1:0];
      end

      // R / B outputs toward the master
      mst_resp[i].r_valid = rst_n && r_vout[i];
      mst_resp[i].b_valid = rst_n && b_vout[i];
      if (cur_rs[i] == NUM_SLV) begin
        mst_resp[i].r.id   = dr_fifo[i][dr_head[i][2:0]][12:9];
        mst_resp[i].r.data = {dr_beat[i], dr_fifo[i][dr_head[i][2:0]][12:9],
                              {52{1'b1}}};
        mst_resp[i].r.resp = RESP_DECERR;
        mst_resp[i].r.last = (dr_beat[i] == dr_fifo[i][dr_head[i][2:0]][7:0]);
        mst_resp[i].r.user = dr_fifo[i][dr_head[i][2:0]][8];
      end else begin
        si = cur_rs[i][1:0] & SLV_MSK;
        mst_resp[i].r    = slv_resp[si].r;
        mst_resp[i].r.id = slv_resp[si].r.id[SLV_ID_W-1:0];
      end
      if (cur_bs[i] == NUM_SLV) begin
        mst_resp[i].b.id   = db_id[i];
        mst_resp[i].b.resp = RESP_DECERR;
        mst_resp[i].b.user = db_user[i];
      end else begin
        si = cur_bs[i][1:0] & SLV_MSK;
        mst_resp[i].b    = slv_resp[si].b;
        mst_resp[i].b.id = slv_resp[si].b.id[SLV_ID_W-1:0];
      end
    end

    // ==== phase 2: per-slave ================================================
    for (int j = 0; j < NUM_SLV; j++) begin
      aw_pick[j] = 2'd0;
      ar_pick[j] = 2'd0;
      for (int i = 0; i < NUM_MST; i++) begin
        aw_cnd[j][i]  = aw_buf_v[i] && (aw_buf_tgt[i] == j);
        ar_cnd[j][i]  = ar_buf_v[i] && (ar_buf_tgt[i] == j);
        w_cnd_m[j][i] = w_elig[i] && !wh[i][7] &&
                        ((wh[i][6:5] & SLV_MSK) == j);
      end
      aw_pickv[j] = |aw_cnd[j];
      ar_pickv[j] = |ar_cnd[j];

      if (awg_v[j]) begin
        aw_srv[j]  = awg_m[j];
        aw_vout[j] = aw_buf_v[awg_m[j]] && (aw_buf_tgt[awg_m[j]] == j);
      end else begin
        aw_pick[j] = aw_pickv[j] ? f_pick_m(aw_ptr[j], aw_cnd[j]) : 2'd0;
        aw_srv[j]  = aw_pick[j];
        aw_vout[j] = aw_pickv[j];
      end
      aw_hs[j] = aw_vout[j] && slv_resp[j].aw_ready;

      if (arg_v[j]) begin
        ar_srv[j]  = arg_m[j];
        ar_vout[j] = ar_buf_v[arg_m[j]] && (ar_buf_tgt[arg_m[j]] == j);
      end else begin
        ar_pick[j] = ar_pickv[j] ? f_pick_m(ar_ptr[j], ar_cnd[j]) : 2'd0;
        ar_srv[j]  = ar_pick[j];
        ar_vout[j] = ar_pickv[j];
      end
      ar_hs[j] = ar_vout[j] && slv_resp[j].ar_ready;

      if (wl_v[j]) begin
        w_srv[j] = wl_m[j];
      end else begin
        w_srv[j] = (|w_cnd_m[j]) ? f_pick_m(w_ptr[j], w_cnd_m[j]) : 2'd0;
      end
      w_hs[j] = (wl_v[j] || (|w_cnd_m[j])) && mst_req[w_srv[j]].w_valid
                && w_elig[w_srv[j]] && slv_resp[j].w_ready;

      // AW output
      slv_req[j].aw_valid = rst_n && aw_vout[j];
      slv_req[j].aw.id    = {aw_srv[j], aw_buf_q[aw_srv[j]].id};
      slv_req[j].aw.addr  = aw_buf_q[aw_srv[j]].addr;
      slv_req[j].aw.len   = aw_buf_q[aw_srv[j]].len;
      slv_req[j].aw.size  = aw_buf_q[aw_srv[j]].size;
      slv_req[j].aw.burst = aw_buf_q[aw_srv[j]].burst;
      slv_req[j].aw.lock  = aw_buf_q[aw_srv[j]].lock;
      slv_req[j].aw.cache = aw_buf_q[aw_srv[j]].cache;
      slv_req[j].aw.prot  = aw_buf_q[aw_srv[j]].prot;
      slv_req[j].aw.qos   = aw_buf_q[aw_srv[j]].qos;
      slv_req[j].aw.region= aw_buf_q[aw_srv[j]].region;
      slv_req[j].aw.atop  = aw_buf_q[aw_srv[j]].atop;
      slv_req[j].aw.user  = aw_buf_q[aw_srv[j]].user;

      // AR output
      slv_req[j].ar_valid = rst_n && ar_vout[j];
      slv_req[j].ar.id    = {ar_srv[j], ar_buf_q[ar_srv[j]].id};
      slv_req[j].ar.addr  = ar_buf_q[ar_srv[j]].addr;
      slv_req[j].ar.len   = ar_buf_q[ar_srv[j]].len;
      slv_req[j].ar.size  = ar_buf_q[ar_srv[j]].size;
      slv_req[j].ar.burst = ar_buf_q[ar_srv[j]].burst;
      slv_req[j].ar.lock  = ar_buf_q[ar_srv[j]].lock;
      slv_req[j].ar.cache = ar_buf_q[ar_srv[j]].cache;
      slv_req[j].ar.prot  = ar_buf_q[ar_srv[j]].prot;
      slv_req[j].ar.qos   = ar_buf_q[ar_srv[j]].qos;
      slv_req[j].ar.region= ar_buf_q[ar_srv[j]].region;
      slv_req[j].ar.user  = ar_buf_q[ar_srv[j]].user;

      // W output
      slv_req[j].w_valid = rst_n && (wl_v[j] || (|w_cnd_m[j]))
                           && mst_req[w_srv[j]].w_valid;
      slv_req[j].w = mst_req[w_srv[j]].w;

      // R/B ready back toward the slaves
      slv_req[j].r_ready = 1'b0;
      slv_req[j].b_ready = 1'b0;
      for (int i2 = 0; i2 < NUM_MST; i2++) begin
        if ((cur_rs[i2] == j) && r_vout[i2]) begin
          slv_req[j].r_ready = mst_req[i2].r_ready;
        end
        if ((cur_bs[i2] == j) && b_vout[i2]) begin
          slv_req[j].b_ready = mst_req[i2].b_ready;
        end
      end
    end

    // ==== phase 3: W ready toward masters ===================================
    for (int i = 0; i < NUM_MST; i++) begin
      if (wh[i][7]) begin
        // unmapped write: swallow beats internally, one decerr B at a time
        w_rdy[i] = w_elig[i] && !db_v[i];
      end else begin
        si = wh[i][6:5] & SLV_MSK;
        w_rdy[i] = w_elig[i] && (wl_v[si] || (|w_cnd_m[si]))
                   && (w_srv[si] == MST_IDX_W'(i))
                   && slv_resp[si].w_ready;
      end
      w_lasts[i]            = w_rdy[i] && mst_req[i].w_valid && mst_req[i].w.last;
      mst_resp[i].w_ready   = rst_n && w_rdy[i];
    end
  end

  // ---------------- sequential ----------------------------------------------
  always_ff @(posedge clk) begin
    if (!rst_n) begin
      aw_buf_v    <= '0;  ar_buf_v    <= '0;
      aw_buf_q    <= '0;  ar_buf_q    <= '0;
      aw_buf_tgt  <= '0;  ar_buf_tgt  <= '0;
      wr_head     <= '0;  wr_tail     <= '0;  wr_cnt <= '0;
      wr_fifo     <= '0;
      dr_head     <= '0;  dr_tail     <= '0;  dr_cnt <= '0;  dr_beat <= '0;
      dr_fifo     <= '0;
      idtab_r     <= '0;  idtab_w     <= '0;
      db_v        <= '0;  db_id       <= '0;  db_user <= '0;
      awg_v       <= '0;  arg_v       <= '0;
      awg_m       <= '0;  arg_m       <= '0;
      aw_ptr      <= '0;  ar_ptr      <= '0;
      wl_v        <= '0;  wl_m        <= '0;  w_ptr  <= '0;
      rs_v        <= '0;  bs_v        <= '0;
      rs          <= '0;  bs          <= '0;
      r_ptr       <= '0;  b_ptr       <= '0;
    end else begin
      // ---- per master ------------------------------------------------------
      for (int i = 0; i < NUM_MST; i++) begin
        // AW accept: push write target, mark ID, hold mapped AW for forwarding
        if (aw_acc[i]) begin
          idtab_w[i][mst_req[i].aw.id] <= 1'b1;
          wr_fifo[i][wr_tail[i][2:0]]  <= {~dec_aw[i][2], dec_aw[i][1:0],
                                           mst_req[i].aw.id, mst_req[i].aw.user};
          wr_tail[i] <= (wr_tail[i] + 3'd1) & WMASK;
          if (dec_aw[i][2]) begin
            aw_buf_q[i]   <= mst_req[i].aw;
            aw_buf_tgt[i] <= dec_aw[i][1:0];
            aw_buf_v[i]   <= 1'b1;
          end
        end
        // AR accept
        if (ar_acc[i]) begin
          idtab_r[i][mst_req[i].ar.id] <= 1'b1;
          if (dec_ar[i][2]) begin
            ar_buf_q[i]   <= mst_req[i].ar;
            ar_buf_tgt[i] <= dec_ar[i][1:0];
            ar_buf_v[i]   <= 1'b1;
          end else begin
            dr_fifo[i][dr_tail[i][2:0]] <= {mst_req[i].ar.id,
                                             mst_req[i].ar.user,
                                             mst_req[i].ar.len};
            dr_tail[i] <= (dr_tail[i] + 3'd1) & DMASK;
          end
        end
        // write stream advance
        if (w_lasts[i]) begin
          wr_head[i] <= (wr_head[i] + 3'd1) & WMASK;
          if (wh[i][7]) begin
            db_v[i]    <= 1'b1;
            db_id[i]   <= wh[i][4:1];
            db_user[i] <= wh[i][0];
          end
        end
        // occupancy counters (combined push/pop)
        wr_cnt[i] <= wr_cnt[i] + (aw_acc[i] ? 4'd1 : 4'd0)
                                 - (w_lasts[i] ? 4'd1 : 4'd0);
        dr_cnt[i] <= dr_cnt[i] + ((ar_acc[i] && !dec_ar[i][2]) ? 4'd1 : 4'd0)
                                - ((r_hs[i] && r_last[i] &&
                                    (cur_rs[i] == NUM_SLV)) ? 4'd1 : 4'd0);
        // R source state
        if (r_hs[i]) begin
          if (r_last[i]) begin
            rs_v[i]  <= 1'b0;
            r_ptr[i] <= (cur_rs[i] == NUM_SLV) ? 3'd0 : (cur_rs[i] + 3'd1);
            idtab_r[i][r_bid[i]] <= 1'b0;
            if (cur_rs[i] == NUM_SLV) begin
              dr_head[i] <= (dr_head[i] + 3'd1) & DMASK;
              dr_beat[i] <= 8'd0;
            end
          end else begin
            rs_v[i] <= 1'b1;
            rs[i]   <= cur_rs[i];
            if (cur_rs[i] == NUM_SLV) begin
              dr_beat[i] <= dr_beat[i] + 8'd1;
            end
          end
        end else if (r_vout[i]) begin
          rs_v[i] <= 1'b1;
          rs[i]   <= cur_rs[i];
        end else begin
          rs_v[i] <= 1'b0;
        end
        // B source state
        if (b_hs[i]) begin
          bs_v[i]  <= 1'b0;
          b_ptr[i] <= (cur_bs[i] == NUM_SLV) ? 3'd0 : (cur_bs[i] + 3'd1);
          idtab_w[i][b_bid[i]] <= 1'b0;
          if (cur_bs[i] == NUM_SLV) begin
            db_v[i] <= 1'b0;
          end
        end else if (b_vout[i]) begin
          bs_v[i] <= 1'b1;
          bs[i]   <= cur_bs[i];
        end else begin
          bs_v[i] <= 1'b0;
        end
      end

      // ---- per slave -------------------------------------------------------
      for (int j = 0; j < NUM_SLV; j++) begin
        if (awg_v[j]) begin
          if (aw_hs[j]) begin
            awg_v[j]           <= 1'b0;
            aw_ptr[j]          <= (awg_m[j] + 2'd1) & MST_MSK;
            aw_buf_v[awg_m[j]] <= 1'b0;
          end
        end else if (aw_pickv[j]) begin
          if (aw_hs[j]) begin
            aw_ptr[j]            <= (aw_pick[j] + 2'd1) & MST_MSK;
            aw_buf_v[aw_pick[j]] <= 1'b0;
          end else begin
            awg_v[j] <= 1'b1;
            awg_m[j] <= aw_pick[j];
          end
        end
        if (arg_v[j]) begin
          if (ar_hs[j]) begin
            arg_v[j]           <= 1'b0;
            ar_ptr[j]          <= (arg_m[j] + 2'd1) & MST_MSK;
            ar_buf_v[arg_m[j]] <= 1'b0;
          end
        end else if (ar_pickv[j]) begin
          if (ar_hs[j]) begin
            ar_ptr[j]            <= (ar_pick[j] + 2'd1) & MST_MSK;
            ar_buf_v[ar_pick[j]] <= 1'b0;
          end else begin
            arg_v[j] <= 1'b1;
            arg_m[j] <= ar_pick[j];
          end
        end
        if (wl_v[j]) begin
          if (w_hs[j] && mst_req[w_srv[j]].w.last) begin
            wl_v[j]  <= 1'b0;
            w_ptr[j] <= (wl_m[j] + 2'd1) & MST_MSK;
          end
        end else if (|w_cnd_m[j]) begin
          if (w_hs[j] && mst_req[w_srv[j]].w.last) begin
            w_ptr[j] <= (w_srv[j] + 2'd1) & MST_MSK;
          end else begin
            wl_v[j] <= 1'b1;
            wl_m[j] <= w_srv[j];
          end
        end
      end
    end
  end

endmodule
