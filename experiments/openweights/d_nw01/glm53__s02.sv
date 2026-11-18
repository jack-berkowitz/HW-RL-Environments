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

  // ------------------------------------------------------------------
  // Local geometry
  // ------------------------------------------------------------------
  localparam int DEC       = NUM_SLV;          // internal "decode error" target
  localparam int NSRC      = NUM_SLV + 1;      // response sources per master
  localparam int TGT_W     = 3;                // fits DEC (<=4)
  localparam int MST_PTR_W = (NUM_MST > 2) ? 2 : 1;
  localparam int SLV_IDX_W = (NUM_SLV > 2) ? 2 : 1;

  typedef logic [TGT_W-1:0]     tgt_t;
  typedef logic [MST_PTR_W-1:0] mptr_t;
  typedef logic [2:0]           sel_t;

  // ------------------------------------------------------------------
  // Helpers
  // ------------------------------------------------------------------
  function automatic tgt_t f_decode(input logic [ADDR_W-1:0] a);
    tgt_t t;
    t = DEC;
    for (int r = 0; r < NUM_SLV; r++)
      if ((a >= addr_map[r].start_addr) && (a < addr_map[r].end_addr) &&
          (addr_map[r].mst_port < NUM_SLV))
        t = addr_map[r].mst_port;
    return t;
  endfunction

  function automatic logic [MST_IDX_W-1:0] f_midx(input mst_id_t id);
    logic [MST_IDX_W-1:0] r;
    r = id[SLV_ID_W +: MST_IDX_W];
    return r;
  endfunction

  // ------------------------------------------------------------------
  // State (all reset to zero)
  // ------------------------------------------------------------------
  // per-(master,id) ordering tables: outstanding count + locked target
  logic [15:0][3:0]     rd_cnt_tbl [NUM_MST];
  logic [15:0][TGT_W-1:0] rd_tgt_tbl [NUM_MST];
  logic [15:0][3:0]     wr_cnt_tbl [NUM_MST];
  logic [15:0][TGT_W-1:0] wr_tgt_tbl [NUM_MST];
  // per-master outstanding totals
  logic [3:0]           rd_cnt [NUM_MST];
  logic [3:0]           wr_cnt [NUM_MST];
  // per-master write-target queue (AW order): {tgt, aw.id}
  logic [MAX_TRANS-1:0][6:0] qw_e [NUM_MST];
  logic [3:0]           qw_h [NUM_MST];
  logic [3:0]           qw_n [NUM_MST];
  // per-master decerr read queue: {id, len}
  logic [MAX_TRANS-1:0][11:0] dr_e [NUM_MST];
  logic [3:0]           dr_h [NUM_MST];
  logic [3:0]           dr_n [NUM_MST];
  logic [7:0]           dr_beat [NUM_MST];
  // per-master decerr write-response queue: {id}
  logic [MAX_TRANS-1:0][SLV_ID_W-1:0] db_e [NUM_MST];
  logic [3:0]           db_h [NUM_MST];
  logic [3:0]           db_n [NUM_MST];
  // per-master response arbitration
  logic                 r_act [NUM_MST];
  sel_t                 r_sel [NUM_MST];
  sel_t                 b_sel [NUM_MST];
  // per-slave request path
  logic                 ar_v [NUM_SLV];
  mst_ar_t              ar_q [NUM_SLV];
  mptr_t                arptr [NUM_SLV];
  logic                 aw_v [NUM_SLV];
  mst_aw_t              aw_q [NUM_SLV];
  mptr_t                awptr [NUM_SLV];
  // per-slave write data path (2-beat skid)
  mptr_t                wptr [NUM_SLV];
  logic                 w_active [NUM_SLV];
  w_t                   wf0 [NUM_SLV];
  w_t                   wf1 [NUM_SLV];
  logic [1:0]           wcnt [NUM_SLV];

  // ------------------------------------------------------------------
  // Combinational nets
  // ------------------------------------------------------------------
  tgt_t   aw_tgt [NUM_MST];
  tgt_t   ar_tgt [NUM_MST];
  logic   ar_pre [NUM_MST];
  logic   aw_pre [NUM_MST];
  logic   ar_rdy [NUM_MST];
  logic   aw_rdy [NUM_MST];
  logic   w_rdy  [NUM_MST];
  logic   ar_acc [NUM_MST];
  logic   aw_acc [NUM_MST];
  logic   w_acc  [NUM_MST];
  logic   qw_ne  [NUM_MST];
  tgt_t   qw_head [NUM_MST];
  slv_id_t qw_hid [NUM_MST];
  logic [NSRC-1:0] rsrc_v [NUM_MST];
  logic [NSRC-1:0] bsrc_v [NUM_MST];
  sel_t   rsel_nxt [NUM_MST];
  sel_t   bsel_nxt [NUM_MST];
  logic   r_vld  [NUM_MST];
  slv_r_t r_pl   [NUM_MST];
  logic   r_last [NUM_MST];
  slv_id_t r_id  [NUM_MST];
  logic   r_acc  [NUM_MST];
  logic   b_vld  [NUM_MST];
  slv_b_t b_pl   [NUM_MST];
  slv_id_t b_id  [NUM_MST];
  logic   b_acc  [NUM_MST];
  logic   ar_load [NUM_SLV];
  logic   aw_load [NUM_SLV];
  logic   ar_hold [NUM_SLV];
  logic   aw_hold [NUM_SLV];
  logic   w_push  [NUM_SLV];
  w_t     w_push_data [NUM_SLV];
  logic   w_pop   [NUM_SLV];
  mptr_t  arptr_nxt [NUM_SLV];
  mptr_t  awptr_nxt [NUM_SLV];
  mptr_t  wptr_nxt  [NUM_SLV];

  // ==================================================================
  // Combinational: decode, arbitration, muxing
  // ==================================================================
  always_comb begin
    for (int m = 0; m < NUM_MST; m++) begin
      aw_tgt[m] = f_decode(mst_req[m].aw.addr);
      ar_tgt[m] = f_decode(mst_req[m].ar.addr);

      // capacity + per-ID single-target restriction
      ar_pre[m] = (rd_cnt[m] < MAX_TRANS) &&
                  ((rd_cnt_tbl[m][mst_req[m].ar.id] == 0) ||
                   (rd_tgt_tbl[m][mst_req[m].ar.id] == ar_tgt[m]));
      aw_pre[m] = (wr_cnt[m] < MAX_TRANS) &&
                  ((wr_cnt_tbl[m][mst_req[m].aw.id] == 0) ||
                   (wr_tgt_tbl[m][mst_req[m].aw.id] == aw_tgt[m]));

      // readies: function of registers / payload / slave readies only
      ar_rdy[m] = 1'b0;
      aw_rdy[m] = 1'b0;
      if (rst_n && ar_pre[m]) begin
        if (ar_tgt[m] == DEC)
          ar_rdy[m] = 1'b1;
        else if (arptr[ar_tgt[m][SLV_IDX_W-1:0]] == m)
          ar_rdy[m] = (!ar_v[ar_tgt[m][SLV_IDX_W-1:0]]) ||
                      slv_resp[ar_tgt[m][SLV_IDX_W-1:0]].ar_ready;
      end
      if (rst_n && aw_pre[m]) begin
        if (aw_tgt[m] == DEC)
          aw_rdy[m] = 1'b1;
        else if (awptr[aw_tgt[m][SLV_IDX_W-1:0]] == m)
          aw_rdy[m] = (!aw_v[aw_tgt[m][SLV_IDX_W-1:0]]) ||
                      slv_resp[aw_tgt[m][SLV_IDX_W-1:0]].aw_ready;
      end

      // write-data routing: head of the AW-order target queue
      qw_ne[m]   = (qw_n[m] != 0);
      qw_head[m] = qw_e[m][qw_h[m]][6:4];
      qw_hid[m]  = qw_e[m][qw_h[m]][3:0];
      w_rdy[m] = 1'b0;
      if (rst_n && qw_ne[m]) begin
        if (qw_head[m] == DEC)
          w_rdy[m] = 1'b1;   // decerr write data is consumed and dropped
        else if (wptr[qw_head[m][SLV_IDX_W-1:0]] == m)
          w_rdy[m] = (wcnt[qw_head[m][SLV_IDX_W-1:0]] < 2);
      end

      ar_acc[m] = mst_req[m].ar_valid && ar_rdy[m];
      aw_acc[m] = mst_req[m].aw_valid && aw_rdy[m];
      w_acc[m]  = mst_req[m].w_valid  && w_rdy[m];

      // response sources valid for this master (id upper bits name m)
      for (int s = 0; s < NUM_SLV; s++) begin
        rsrc_v[m][s] = slv_resp[s].r_valid &&
                       (f_midx(slv_resp[s].r.id) == MST_IDX_W'(m));
        bsrc_v[m][s] = slv_resp[s].b_valid &&
                       (f_midx(slv_resp[s].b.id) == MST_IDX_W'(m));
      end
      rsrc_v[m][DEC] = (dr_n[m] != 0);
      bsrc_v[m][DEC] = (db_n[m] != 0);

      // R mux (locked source while a burst is in flight)
      r_vld[m]  = rst_n && r_act[m] && rsrc_v[m][r_sel[m]];
      r_pl[m]   = '0;
      r_last[m] = 1'b0;
      r_id[m]   = '0;
      if (r_sel[m] == DEC) begin
        r_pl[m].id   = dr_e[m][dr_h[m]][11:8];
        r_pl[m].resp = RESP_DECERR;
        r_pl[m].last = (dr_beat[m] == dr_e[m][dr_h[m]][7:0]);
        r_last[m]    = (dr_beat[m] == dr_e[m][dr_h[m]][7:0]);
        r_id[m]      = dr_e[m][dr_h[m]][11:8];
      end else begin
        r_pl[m].id   = slv_resp[r_sel[m][SLV_IDX_W-1:0]].r.id[SLV_ID_W-1:0];
        r_pl[m].data = slv_resp[r_sel[m][SLV_IDX_W-1:0]].r.data;
        r_pl[m].resp = slv_resp[r_sel[m][SLV_IDX_W-1:0]].r.resp;
        r_pl[m].last = slv_resp[r_sel[m][SLV_IDX_W-1:0]].r.last;
        r_pl[m].user = slv_resp[r_sel[m][SLV_IDX_W-1:0]].r.user;
        r_last[m]    = slv_resp[r_sel[m][SLV_IDX_W-1:0]].r.last;
        r_id[m]      = slv_resp[r_sel[m][SLV_IDX_W-1:0]].r.id[SLV_ID_W-1:0];
      end
      r_acc[m] = mst_req[m].r_ready && r_vld[m];

      // B mux
      b_vld[m] = rst_n && bsrc_v[m][b_sel[m]];
      b_pl[m]  = '0;
      b_id[m]  = '0;
      if (b_sel[m] == DEC) begin
        b_pl[m].id   = db_e[m][db_h[m]];
        b_pl[m].resp = RESP_DECERR;
        b_id[m]      = db_e[m][db_h[m]];
      end else begin
        b_pl[m].id   = slv_resp[b_sel[m][SLV_IDX_W-1:0]].b.id[SLV_ID_W-1:0];
        b_pl[m].resp = slv_resp[b_sel[m][SLV_IDX_W-1:0]].b.resp;
        b_pl[m].user = slv_resp[b_sel[m][SLV_IDX_W-1:0]].b.user;
        b_id[m]      = slv_resp[b_sel[m][SLV_IDX_W-1:0]].b.id[SLV_ID_W-1:0];
      end
      b_acc[m] = mst_req[m].b_ready && b_vld[m];

      // next response source (round robin, skip empty)
      rsel_nxt[m] = (r_sel[m] == DEC) ? sel_t'(0) : (r_sel[m] + 3'd1);
      bsel_nxt[m] = (b_sel[m] == DEC) ? sel_t'(0) : (b_sel[m] + 3'd1);
      for (int k = NSRC; k >= 1; k--) begin
        if (rsrc_v[m][(r_sel[m] + k) % NSRC])
          rsel_nxt[m] = ((r_sel[m] + k) % NSRC);
        if (bsrc_v[m][(b_sel[m] + k) % NSRC])
          bsel_nxt[m] = ((b_sel[m] + k) % NSRC);
      end
    end

    for (int t = 0; t < NUM_SLV; t++) begin
      ar_load[t] = ar_acc[arptr[t]] && (ar_tgt[arptr[t]] == t);
      aw_load[t] = aw_acc[awptr[t]] && (aw_tgt[awptr[t]] == t);
      ar_hold[t] = mst_req[arptr[t]].ar_valid && (ar_tgt[arptr[t]] == t) &&
                   ar_pre[arptr[t]] && !ar_load[t];
      aw_hold[t] = mst_req[awptr[t]].aw_valid && (aw_tgt[awptr[t]] == t) &&
                   aw_pre[awptr[t]] && !aw_load[t];

      w_push[t] = 1'b0;
      w_push_data[t] = '0;
      for (int m = 0; m < NUM_MST; m++) begin
        if (w_acc[m] && (qw_head[m] == t)) begin
          w_push[t] = 1'b1;
          w_push_data[t] = mst_req[m].w;
        end
      end
      w_pop[t] = (wcnt[t] != 0) && slv_resp[t].w_ready;

      // next request grant (round robin over requesters)
      arptr_nxt[t] = (arptr[t] == NUM_MST-1) ? mptr_t'(0) : mptr_t'(arptr[t] + 1);
      awptr_nxt[t] = (awptr[t] == NUM_MST-1) ? mptr_t'(0) : mptr_t'(awptr[t] + 1);
      wptr_nxt[t]  = (wptr[t]  == NUM_MST-1) ? mptr_t'(0) : mptr_t'(wptr[t]  + 1);
      for (int k = NUM_MST; k >= 1; k--) begin
        if (mst_req[(arptr[t] + k) % NUM_MST].ar_valid &&
            (ar_tgt[(arptr[t] + k) % NUM_MST] == t) &&
            ar_pre[(arptr[t] + k) % NUM_MST])
          arptr_nxt[t] = mptr_t'((arptr[t] + k) % NUM_MST);
        if (mst_req[(awptr[t] + k) % NUM_MST].aw_valid &&
            (aw_tgt[(awptr[t] + k) % NUM_MST] == t) &&
            aw_pre[(awptr[t] + k) % NUM_MST])
          awptr_nxt[t] = mptr_t'((awptr[t] + k) % NUM_MST);
        if (qw_ne[(wptr[t] + k) % NUM_MST] &&
            (qw_head[(wptr[t] + k) % NUM_MST] == t))
          wptr_nxt[t] = mptr_t'((wptr[t] + k) % NUM_MST);
      end
    end
  end

  // ==================================================================
  // Output ports
  // ==================================================================
  always_comb begin
    for (int m = 0; m < NUM_MST; m++) begin
      mst_resp[m].aw_ready = aw_rdy[m];
      mst_resp[m].w_ready  = w_rdy[m];
      mst_resp[m].ar_ready = ar_rdy[m];
      mst_resp[m].b_valid  = b_vld[m];
      mst_resp[m].b        = b_pl[m];
      mst_resp[m].r_valid  = r_vld[m];
      mst_resp[m].r        = r_pl[m];
    end
    for (int t = 0; t < NUM_SLV; t++) begin
      slv_req[t].aw_valid = rst_n && aw_v[t];
      slv_req[t].aw       = aw_q[t];
      slv_req[t].w_valid  = rst_n && (wcnt[t] != 0);
      slv_req[t].w        = wf0[t];
      slv_req[t].b_ready  = 1'b0;
      slv_req[t].ar_valid = rst_n && ar_v[t];
      slv_req[t].ar       = ar_q[t];
      slv_req[t].r_ready  = 1'b0;
      for (int m = 0; m < NUM_MST; m++) begin
        if (r_acc[m] && (r_sel[m] == t)) slv_req[t].r_ready = 1'b1;
        if (b_acc[m] && (b_sel[m] == t)) slv_req[t].b_ready = 1'b1;
      end
    end
  end

  // ==================================================================
  // Sequential: master-side tracking / ordering / response arbitration
  // ==================================================================
  always_ff @(posedge clk) begin
    if (!rst_n) begin
      for (int m = 0; m < NUM_MST; m++) begin
        rd_cnt[m] <= '0;
        wr_cnt[m] <= '0;
        r_act[m]  <= 1'b0;
        r_sel[m]  <= '0;
        b_sel[m]  <= '0;
        qw_n[m]   <= '0;
        qw_h[m]   <= '0;
        dr_n[m]   <= '0;
        dr_h[m]   <= '0;
        dr_beat[m] <= '0;
        db_n[m]   <= '0;
        db_h[m]   <= '0;
        for (int i = 0; i < 16; i++) begin
          rd_cnt_tbl[m][i] <= '0;
          wr_cnt_tbl[m][i] <= '0;
          rd_tgt_tbl[m][i] <= '0;
          wr_tgt_tbl[m][i] <= '0;
        end
      end
    end else begin
      for (int m = 0; m < NUM_MST; m++) begin
        // outstanding totals
        rd_cnt[m] <= rd_cnt[m] + (ar_acc[m] ? 4'd1 : 4'd0)
                               - ((r_acc[m] && r_last[m]) ? 4'd1 : 4'd0);
        wr_cnt[m] <= wr_cnt[m] + (aw_acc[m] ? 4'd1 : 4'd0)
                               - (b_acc[m] ? 4'd1 : 4'd0);
        // per-ID tables
        for (int i = 0; i < 16; i++) begin
          rd_cnt_tbl[m][i] <= rd_cnt_tbl[m][i]
            + ((ar_acc[m] && (mst_req[m].ar.id == i)) ? 4'd1 : 4'd0)
            - ((r_acc[m] && r_last[m] && (r_id[m] == i)) ? 4'd1 : 4'd0);
          wr_cnt_tbl[m][i] <= wr_cnt_tbl[m][i]
            + ((aw_acc[m] && (mst_req[m].aw.id == i)) ? 4'd1 : 4'd0)
            - ((b_acc[m] && (b_id[m] == i)) ? 4'd1 : 4'd0);
          if (ar_acc[m] && (mst_req[m].ar.id == i) && (rd_cnt_tbl[m][i] == 0))
            rd_tgt_tbl[m][i] <= ar_tgt[m];
          if (aw_acc[m] && (mst_req[m].aw.id == i) && (wr_cnt_tbl[m][i] == 0))
            wr_tgt_tbl[m][i] <= aw_tgt[m];
        end
        // write-target queue
        if (aw_acc[m]) begin
          if (qw_h[m] + qw_n[m] >= MAX_TRANS)
            qw_e[m][qw_h[m] + qw_n[m] - MAX_TRANS] <= {aw_tgt[m], mst_req[m].aw.id};
          else
            qw_e[m][qw_h[m] + qw_n[m]] <= {aw_tgt[m], mst_req[m].aw.id};
        end
        if (w_acc[m] && mst_req[m].w.last)
          qw_h[m] <= (qw_h[m] == MAX_TRANS-1) ? '0 : (qw_h[m] + 4'd1);
        if (aw_acc[m] && !(w_acc[m] && mst_req[m].w.last))
          qw_n[m] <= qw_n[m] + 4'd1;
        else if (!aw_acc[m] && w_acc[m] && mst_req[m].w.last)
          qw_n[m] <= qw_n[m] - 4'd1;
        // decerr read queue
        if (ar_acc[m] && (ar_tgt[m] == DEC)) begin
          if (dr_h[m] + dr_n[m] >= MAX_TRANS)
            dr_e[m][dr_h[m] + dr_n[m] - MAX_TRANS] <= {mst_req[m].ar.id, mst_req[m].ar.len};
          else
            dr_e[m][dr_h[m] + dr_n[m]] <= {mst_req[m].ar.id, mst_req[m].ar.len};
        end
        if (r_acc[m] && r_last[m] && (r_sel[m] == DEC))
          dr_h[m] <= (dr_h[m] == MAX_TRANS-1) ? '0 : (dr_h[m] + 4'd1);
        if ((ar_acc[m] && (ar_tgt[m] == DEC)) &&
            !(r_acc[m] && r_last[m] && (r_sel[m] == DEC)))
          dr_n[m] <= dr_n[m] + 4'd1;
        else if (!(ar_acc[m] && (ar_tgt[m] == DEC)) &&
                 (r_acc[m] && r_last[m] && (r_sel[m] == DEC)))
          dr_n[m] <= dr_n[m] - 4'd1;
        if (r_acc[m] && (r_sel[m] == DEC)) begin
          if (r_last[m]) dr_beat[m] <= '0;
          else dr_beat[m] <= dr_beat[m] + 8'd1;
        end
        // decerr write-response queue
        if (w_acc[m] && mst_req[m].w.last && (qw_head[m] == DEC)) begin
          if (db_h[m] + db_n[m] >= MAX_TRANS)
            db_e[m][db_h[m] + db_n[m] - MAX_TRANS] <= qw_hid[m];
          else
            db_e[m][db_h[m] + db_n[m]] <= qw_hid[m];
        end
        if (b_acc[m] && (b_sel[m] == DEC))
          db_h[m] <= (db_h[m] == MAX_TRANS-1) ? '0 : (db_h[m] + 4'd1);
        if ((w_acc[m] && mst_req[m].w.last && (qw_head[m] == DEC)) &&
            !(b_acc[m] && (b_sel[m] == DEC)))
          db_n[m] <= db_n[m] + 4'd1;
        else if (!(w_acc[m] && mst_req[m].w.last && (qw_head[m] == DEC)) &&
                 (b_acc[m] && (b_sel[m] == DEC)))
          db_n[m] <= db_n[m] - 4'd1;
        // R arbitration: lock source for the duration of a burst
        if (r_acc[m] && r_last[m]) begin
          r_act[m] <= 1'b0;
          r_sel[m] <= rsel_nxt[m];
        end else if (!r_act[m]) begin
          if (rsrc_v[m][r_sel[m]])
            r_act[m] <= 1'b1;
          else
            r_sel[m] <= rsel_nxt[m];
        end
        // B arbitration: round robin, hold while presenting
        if (b_acc[m] || !bsrc_v[m][b_sel[m]])
          b_sel[m] <= bsel_nxt[m];
      end
    end
  end

  // ==================================================================
  // Sequential: slave-side request path
  // ==================================================================
  always_ff @(posedge clk) begin
    if (!rst_n) begin
      for (int t = 0; t < NUM_SLV; t++) begin
        ar_v[t] <= 1'b0;
        aw_v[t] <= 1'b0;
        arptr[t] <= '0;
        awptr[t] <= '0;
        wptr[t] <= '0;
        w_active[t] <= 1'b0;
        wcnt[t] <= '0;
        ar_q[t] <= '0;
        aw_q[t] <= '0;
        wf0[t] <= '0;
        wf1[t] <= '0;
      end
    end else begin
      for (int t = 0; t < NUM_SLV; t++) begin
        // AR
        if (ar_load[t]) begin
          ar_q[t].id    <= {MST_IDX_W'(arptr[t]), mst_req[arptr[t]].ar.id};
          ar_q[t].addr  <= mst_req[arptr[t]].ar.addr;
          ar_q[t].len   <= mst_req[arptr[t]].ar.len;
          ar_q[t].size  <= mst_req[arptr[t]].ar.size;
          ar_q[t].burst <= mst_req[arptr[t]].ar.burst;
          ar_q[t].lock  <= mst_req[arptr[t]].ar.lock;
          ar_q[t].cache <= mst_req[arptr[t]].ar.cache;
          ar_q[t].prot  <= mst_req[arptr[t]].ar.prot;
          ar_q[t].qos   <= mst_req[arptr[t]].ar.qos;
          ar_q[t].region <= mst_req[arptr[t]].ar.region;
          ar_q[t].user  <= mst_req[arptr[t]].ar.user;
          ar_v[t] <= 1'b1;
        end else if (slv_resp[t].ar_ready) begin
          ar_v[t] <= 1'b0;
        end
        if (ar_load[t] || !ar_hold[t])
          arptr[t] <= arptr_nxt[t];
        // AW
        if (aw_load[t]) begin
          aw_q[t].id    <= {MST_IDX_W'(awptr[t]), mst_req[awptr[t]].aw.id};
          aw_q[t].addr  <= mst_req[awptr[t]].aw.addr;
          aw_q[t].len   <= mst_req[awptr[t]].aw.len;
          aw_q[t].size  <= mst_req[awptr[t]].aw.size;
          aw_q[t].burst <= mst_req[awptr[t]].aw.burst;
          aw_q[t].lock  <= mst_req[awptr[t]].aw.lock;
          aw_q[t].cache <= mst_req[awptr[t]].aw.cache;
          aw_q[t].prot  <= mst_req[awptr[t]].aw.prot;
          aw_q[t].qos   <= mst_req[awptr[t]].aw.qos;
          aw_q[t].region <= mst_req[awptr[t]].aw.region;
          aw_q[t].atop  <= mst_req[awptr[t]].aw.atop;
          aw_q[t].user  <= mst_req[awptr[t]].aw.user;
          aw_v[t] <= 1'b1;
        end else if (slv_resp[t].aw_ready) begin
          aw_v[t] <= 1'b0;
        end
        if (aw_load[t] || !aw_hold[t])
          awptr[t] <= awptr_nxt[t];
        // W skid (2 beats, burst-atomic per master)
        case ({w_push[t], w_pop[t]})
          2'b10: begin
            if (wcnt[t] == 0) wf0[t] <= w_push_data[t];
            else wf1[t] <= w_push_data[t];
            wcnt[t] <= wcnt[t] + 2'd1;
          end
          2'b01: begin
            wf0[t] <= wf1[t];
            wcnt[t] <= wcnt[t] - 2'd1;
          end
          2'b11: begin
            wf0[t] <= wf1[t];
            wf1[t] <= w_push_data[t];
          end
          default: ;
        endcase
        // W arbitration: stick for a whole burst, rotate at burst end
        if (w_push[t] && w_push_data[t].last) begin
          w_active[t] <= 1'b0;
          wptr[t] <= wptr_nxt[t];
        end else if (w_push[t]) begin
          w_active[t] <= 1'b1;
        end else if (!w_active[t]) begin
          if (!(qw_ne[wptr[t]] && (qw_head[wptr[t]] == t)))
            wptr[t] <= (wptr[t] == NUM_MST-1) ? mptr_t'(0) : mptr_t'(wptr[t] + 1);
        end
      end
    end
  end

endmodule
