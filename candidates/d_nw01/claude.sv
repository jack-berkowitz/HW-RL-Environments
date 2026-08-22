// =============================================================================
// axi4_xbar.sv -- NUM_MST x NUM_SLV AXI4 crossbar
// -----------------------------------------------------------------------------
// Topology: a demux per master port and an arbiter per slave port, so disjoint
// master/slave pairs share no datapath and no arbiter (C2). Each master port
// additionally owns a decode-error slave that retires unmapped transactions
// itself (D2).
//
// The three structural hazards this design has to close:
//
//  * H1 (no *_ready combinationally on the corresponding *_valid). Every channel
//    entering the crossbar -- AW/W/AR from each master, B/R from each slave --
//    lands in a two-entry FIFO first. The ready the crossbar drives is that
//    FIFO's !full, which is a register. Arbitration then runs entirely on
//    registered valids, so the internal combinational paths are unconstrained.
//
//  * W-channel deadlock. AW acceptance order defines W order at both ends, and
//    the two orders can form a cycle: slave A waiting on master 1's W while
//    master 1 waits to drain a burst into slave B, which is waiting on master 0,
//    which is waiting on slave A. The fix is at the master demux: a port may
//    only accept an AW whose target matches the target of the W bursts it
//    already owes (wp_sel/wp_cnt). A master therefore never owes W to two
//    slaves at once, and the cycle cannot close. Bursts to the same slave still
//    pipeline freely.
//
//  * Per-ID ordering across slaves (O1). Per master, per ID, a counter and a
//    target: a request whose ID is already outstanding to a DIFFERENT target
//    stalls until that ID drains. Same-ID responses then come from one slave,
//    which orders them itself. Distinct IDs never interact, so this costs
//    nothing on the capacity test.
//
// Capacity (C1): the request path is a pure pass-through -- nothing is reserved
// or buffered per transaction -- so outstanding depth is whatever the slaves
// accept, per ID and per master. The R mux locks to one source until `last`
// (O4); the B mux locks only across a stall (H3).
//
// Fairness (L2): rotating-priority arbitration at every slave AW/AR and at
// every master B/R mux, with the pointer advanced past the winner on transfer.
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
  // Derived geometry
  // ---------------------------------------------------------------------------
  localparam int NST  = NUM_SLV + 1;              // targets: slaves + error slave
  localparam int ERRT = NUM_SLV;                  // index of the error slave
  localparam int MIW  = (NUM_MST <= 1) ? 1 : $clog2(NUM_MST);
  localparam int NID  = 1 << SLV_ID_W;

  localparam int WPD  = MAX_TRANS;                // W bursts a master may owe
  localparam int WFD  = NUM_MST * WPD;            // never overflows: see below
  localparam int WPCW = $clog2(WPD + 1);
  localparam int IDCW = $clog2(MAX_TRANS + 1) + 2;
  localparam int ERD  = 4;                        // pending decode-error reads
  localparam int EBD  = 4;                        // pending decode-error B beats

  localparam int AWB = $bits(slv_aw_t);
  localparam int ARB = $bits(slv_ar_t);
  localparam int WB  = $bits(w_t);
  localparam int BB  = $bits(mst_b_t);
  localparam int RB  = $bits(mst_r_t);

  // rotating-priority pick: `ptr` has highest priority, wrapping upward.
  function automatic int rr_pick(input logic [7:0] req, input int n, input int ptr);
    int i, j;
    rr_pick = ptr;
    for (i = 7; i >= 0; i = i - 1) begin
      if (i < n) begin
        j = ptr + i;
        if (j >= n) j = j - n;
        if (req[j]) rr_pick = j;
      end
    end
  endfunction

  // ---------------------------------------------------------------------------
  // Registered channel inputs (this is what satisfies H1)
  // ---------------------------------------------------------------------------
  slv_aw_t maw [NUM_MST];  logic maw_v [NUM_MST], maw_r [NUM_MST];
  w_t      mw  [NUM_MST];  logic mw_v  [NUM_MST], mw_r  [NUM_MST];
  slv_ar_t mar [NUM_MST];  logic mar_v [NUM_MST], mar_r [NUM_MST];
  mst_b_t  sb  [NUM_SLV];  logic sb_v  [NUM_SLV], sb_r  [NUM_SLV];
  mst_r_t  sr  [NUM_SLV];  logic sr_v  [NUM_SLV], sr_r  [NUM_SLV];

  slv_resp_t [NUM_MST-1:0] mst_resp_c;
  mst_req_t  [NUM_SLV-1:0] slv_req_c;
  assign mst_resp = mst_resp_c;
  assign slv_req  = slv_req_c;

  // ---------------------------------------------------------------------------
  // Per-master demux state
  // ---------------------------------------------------------------------------
  int              aw_sel  [NUM_MST];        // decoded AW target (0..NUM_SLV)
  int              ar_sel  [NUM_MST];
  logic            aw_ok   [NUM_MST];        // AW qualified to move
  logic            ar_ok   [NUM_MST];
  logic [WPCW-1:0] wp_cnt  [NUM_MST];        // W bursts owed
  int              wp_sel  [NUM_MST];        // and their (single) target
  logic [IDCW-1:0] wid_cnt [NUM_MST][NID];
  int              wid_sel [NUM_MST][NID];
  logic [IDCW-1:0] rid_cnt [NUM_MST][NID];
  int              rid_sel [NUM_MST][NID];

  // per-slave arbitration
  logic [7:0] awreq_v [NUM_SLV];
  logic [7:0] arreq_v [NUM_SLV];
  int         aw_gsel [NUM_SLV], ar_gsel [NUM_SLV];
  logic       aw_do   [NUM_SLV], ar_do   [NUM_SLV], w_do [NUM_SLV];
  logic       aw_lock [NUM_SLV], ar_lock [NUM_SLV];
  int         aw_lsel [NUM_SLV], ar_lsel [NUM_SLV], aw_ptr [NUM_SLV], ar_ptr [NUM_SLV];

  // per-slave W order queue (master index, in AW acceptance order at that slave)
  logic [MIW-1:0] wf_dout [NUM_SLV];
  logic           wf_empty[NUM_SLV], wf_full[NUM_SLV], wf_push[NUM_SLV], wf_pop[NUM_SLV];
  logic [MIW-1:0] wf_din  [NUM_SLV];

  // per-master response mux
  int   r_gsel [NUM_MST], b_gsel [NUM_MST];
  logic r_take [NUM_MST], b_take [NUM_MST];
  logic r_lock [NUM_MST], b_lock [NUM_MST];
  int   r_lsel [NUM_MST], b_lsel [NUM_MST], r_ptr [NUM_MST], b_ptr [NUM_MST];

  // decode-error slave, per master port
  logic            ew_push[NUM_MST], ew_pop[NUM_MST], ew_empty[NUM_MST], ew_full[NUM_MST];
  slv_id_t         ew_din [NUM_MST], ew_dout[NUM_MST];
  logic            eb_push[NUM_MST], eb_pop[NUM_MST], eb_empty[NUM_MST], eb_full[NUM_MST];
  slv_id_t         eb_din [NUM_MST], eb_dout[NUM_MST];
  logic            er_push[NUM_MST], er_pop [NUM_MST], er_empty[NUM_MST], er_full[NUM_MST];
  logic [11:0]     er_din [NUM_MST], er_dout[NUM_MST];
  logic [7:0]      er_beat[NUM_MST];
  logic            errw_rdy[NUM_MST];

  // ===========================================================================
  // Master ports
  // ===========================================================================
  genvar m, s;
  generate
    for (m = 0; m < NUM_MST; m = m + 1) begin : g_mst
      logic [AWB-1:0] awd; logic awf_e, awf_f;
      logic [WB-1:0]  wd;  logic wf_e,  wf_f;
      logic [ARB-1:0] ard; logic arf_e, arf_f;

      axi4_xbar_fifo #(.W(AWB), .DEPTH(2)) i_awf (
        .clk(clk), .rst_n(rst_n),
        .push(mst_req[m].aw_valid), .din(mst_req[m].aw), .full(awf_f),
        .pop(maw_r[m]), .dout(awd), .empty(awf_e));
      axi4_xbar_fifo #(.W(WB), .DEPTH(2)) i_wf (
        .clk(clk), .rst_n(rst_n),
        .push(mst_req[m].w_valid), .din(mst_req[m].w), .full(wf_f),
        .pop(mw_r[m]), .dout(wd), .empty(wf_e));
      axi4_xbar_fifo #(.W(ARB), .DEPTH(2)) i_arf (
        .clk(clk), .rst_n(rst_n),
        .push(mst_req[m].ar_valid), .din(mst_req[m].ar), .full(arf_f),
        .pop(mar_r[m]), .dout(ard), .empty(arf_e));

      assign maw[m]   = slv_aw_t'(awd);
      assign maw_v[m] = !awf_e;
      assign mw[m]    = w_t'(wd);
      assign mw_v[m]  = !wf_e;
      assign mar[m]   = slv_ar_t'(ard);
      assign mar_v[m] = !arf_e;

      assign mst_resp_c[m].aw_ready = rst_n && !awf_f;
      assign mst_resp_c[m].w_ready  = rst_n && !wf_f;
      assign mst_resp_c[m].ar_ready = rst_n && !arf_f;

      // decode-error slave queues
      axi4_xbar_fifo #(.W(SLV_ID_W), .DEPTH(WPD < 2 ? 2 : WPD)) i_ew (
        .clk(clk), .rst_n(rst_n), .push(ew_push[m]), .din(ew_din[m]), .full(ew_full[m]),
        .pop(ew_pop[m]), .dout(ew_dout[m]), .empty(ew_empty[m]));
      axi4_xbar_fifo #(.W(SLV_ID_W), .DEPTH(EBD)) i_eb (
        .clk(clk), .rst_n(rst_n), .push(eb_push[m]), .din(eb_din[m]), .full(eb_full[m]),
        .pop(eb_pop[m]), .dout(eb_dout[m]), .empty(eb_empty[m]));
      axi4_xbar_fifo #(.W(12), .DEPTH(ERD)) i_er (
        .clk(clk), .rst_n(rst_n), .push(er_push[m]), .din(er_din[m]), .full(er_full[m]),
        .pop(er_pop[m]), .dout(er_dout[m]), .empty(er_empty[m]));

      // ---- address decode ---------------------------------------------------
      always_comb begin
        int i;
        aw_sel[m] = ERRT;
        ar_sel[m] = ERRT;
        for (i = 0; i < NUM_SLV; i = i + 1) begin
          if ((maw[m].addr >= addr_map[i].start_addr) &&
              (maw[m].addr <  addr_map[i].end_addr)   &&
              (int'(addr_map[i].mst_port) < NUM_SLV))
            aw_sel[m] = int'(addr_map[i].mst_port);
          if ((mar[m].addr >= addr_map[i].start_addr) &&
              (mar[m].addr <  addr_map[i].end_addr)   &&
              (int'(addr_map[i].mst_port) < NUM_SLV))
            ar_sel[m] = int'(addr_map[i].mst_port);
        end
      end

      // ---- request qualification -------------------------------------------
      // ID must not already be outstanding to a different target (O1); the port
      // must not already owe W to a different target (deadlock rule); the error
      // slave must have room for a read it would have to synthesise.
      always_comb begin
        logic ord, room, wok, wroom;
        ord   = (wid_cnt[m][maw[m].id] == '0) || (wid_sel[m][maw[m].id] == aw_sel[m]);
        room  = (wid_cnt[m][maw[m].id] != {IDCW{1'b1}});
        wok   = (wp_cnt[m] == '0) || (wp_sel[m] == aw_sel[m]);
        wroom = (wp_cnt[m] != WPD[WPCW-1:0]);
        aw_ok[m] = maw_v[m] && ord && room && wok && wroom &&
                   ((aw_sel[m] != ERRT) || !ew_full[m]);
      end

      always_comb begin
        logic ord, room;
        ord  = (rid_cnt[m][mar[m].id] == '0) || (rid_sel[m][mar[m].id] == ar_sel[m]);
        room = (rid_cnt[m][mar[m].id] != {IDCW{1'b1}});
        ar_ok[m] = mar_v[m] && ord && room &&
                   ((ar_sel[m] != ERRT) || !er_full[m]);
      end

      // ---- accept (pop the input FIFO) -------------------------------------
      always_comb begin
        int i;
        maw_r[m] = 1'b0;
        mar_r[m] = 1'b0;
        if (aw_sel[m] == ERRT) maw_r[m] = aw_ok[m];
        else for (i = 0; i < NUM_SLV; i = i + 1)
          if ((aw_sel[m] == i) && aw_do[i] && (aw_gsel[i] == m)) maw_r[m] = 1'b1;
        if (ar_sel[m] == ERRT) mar_r[m] = ar_ok[m];
        else for (i = 0; i < NUM_SLV; i = i + 1)
          if ((ar_sel[m] == i) && ar_do[i] && (ar_gsel[i] == m)) mar_r[m] = 1'b1;
      end

      // ---- W steering -------------------------------------------------------
      assign errw_rdy[m] = !ew_empty[m] && (!mw[m].last || !eb_full[m]);

      always_comb begin
        int i;
        mw_r[m] = 1'b0;
        if (wp_cnt[m] != '0) begin
          if (wp_sel[m] == ERRT) mw_r[m] = mw_v[m] && errw_rdy[m];
          else for (i = 0; i < NUM_SLV; i = i + 1)
            if ((wp_sel[m] == i) && w_do[i] && (int'(wf_dout[i]) == m)) mw_r[m] = 1'b1;
        end
      end

      // ---- decode-error slave ----------------------------------------------
      always_comb begin
        logic wlast;
        wlast      = mw_v[m] && mw_r[m] && mw[m].last && (wp_sel[m] == ERRT);
        ew_push[m] = maw_r[m] && (aw_sel[m] == ERRT);
        ew_din [m] = maw[m].id;
        ew_pop [m] = wlast;
        eb_push[m] = wlast;
        eb_din [m] = ew_dout[m];
        eb_pop [m] = b_take[m] && (b_gsel[m] == ERRT);
        er_push[m] = mar_r[m] && (ar_sel[m] == ERRT);
        er_din [m] = {mar[m].id, mar[m].len};
        er_pop [m] = r_take[m] && (r_gsel[m] == ERRT) && (er_beat[m] == er_dout[m][7:0]);
      end

      always_ff @(posedge clk) begin
        if (!rst_n) er_beat[m] <= '0;
        else if (r_take[m] && (r_gsel[m] == ERRT))
          er_beat[m] <= (er_beat[m] == er_dout[m][7:0]) ? 8'd0 : (er_beat[m] + 8'd1);
      end

      // ---- W-owed tracking (the anti-deadlock rule) ------------------------
      always_ff @(posedge clk) begin
        if (!rst_n) begin
          wp_cnt[m] <= '0;
          wp_sel[m] <= 0;
        end else begin
          if (maw_r[m]) wp_sel[m] <= aw_sel[m];
          case ({maw_r[m], mw_v[m] && mw_r[m] && mw[m].last})
            2'b10:   wp_cnt[m] <= wp_cnt[m] + 1'b1;
            2'b01:   wp_cnt[m] <= wp_cnt[m] - 1'b1;
            default: ;
          endcase
        end
      end

      // ---- per-ID outstanding tables ---------------------------------------
      always_ff @(posedge clk) begin
        int i;
        if (!rst_n) begin
          for (i = 0; i < NID; i = i + 1) begin
            wid_cnt[m][i] <= '0; wid_sel[m][i] <= 0;
            rid_cnt[m][i] <= '0; rid_sel[m][i] <= 0;
          end
        end else begin
          logic winc, wdec, rinc, rdec;
          for (i = 0; i < NID; i = i + 1) begin
            winc = maw_r[m] && (int'(maw[m].id) == i);
            wdec = b_take[m] && (int'(mst_resp_c[m].b.id) == i);
            rinc = mar_r[m] && (int'(mar[m].id) == i);
            rdec = r_take[m] && mst_resp_c[m].r.last && (int'(mst_resp_c[m].r.id) == i);
            if (winc) wid_sel[m][i] <= aw_sel[m];
            if (rinc) rid_sel[m][i] <= ar_sel[m];
            case ({winc, wdec})
              2'b10: wid_cnt[m][i] <= wid_cnt[m][i] + 1'b1;
              2'b01: wid_cnt[m][i] <= wid_cnt[m][i] - 1'b1;
              default: ;
            endcase
            case ({rinc, rdec})
              2'b10: rid_cnt[m][i] <= rid_cnt[m][i] + 1'b1;
              2'b01: rid_cnt[m][i] <= rid_cnt[m][i] - 1'b1;
              default: ;
            endcase
          end
        end
      end

      // ---- R mux: rotating priority, locked to one source until `last` -----
      always_comb begin
        int i;
        logic [7:0] req;
        req = '0;
        for (i = 0; i < NUM_SLV; i = i + 1)
          req[i] = sr_v[i] && (int'(sr[i].id[MST_ID_W-1 -: MST_IDX_W]) == m);
        req[ERRT] = !er_empty[m];

        r_gsel[m] = r_lock[m] ? r_lsel[m] : rr_pick(req, NST, r_ptr[m]);

        mst_resp_c[m].r_valid = req[r_gsel[m]];
        mst_resp_c[m].r       = '0;
        if (r_gsel[m] == ERRT) begin
          mst_resp_c[m].r.id   = er_dout[m][11:8];
          mst_resp_c[m].r.data = '0;
          mst_resp_c[m].r.resp = RESP_DECERR;
          mst_resp_c[m].r.last = (er_beat[m] == er_dout[m][7:0]);
          mst_resp_c[m].r.user = '0;
        end else begin
          for (i = 0; i < NUM_SLV; i = i + 1) if (r_gsel[m] == i) begin
            mst_resp_c[m].r.id   = sr[i].id[SLV_ID_W-1:0];
            mst_resp_c[m].r.data = sr[i].data;
            mst_resp_c[m].r.resp = sr[i].resp;
            mst_resp_c[m].r.last = sr[i].last;
            mst_resp_c[m].r.user = sr[i].user;
          end
        end
        r_take[m] = mst_resp_c[m].r_valid && mst_req[m].r_ready;
      end

      always_ff @(posedge clk) begin
        if (!rst_n) begin
          r_lock[m] <= 1'b0; r_lsel[m] <= 0; r_ptr[m] <= 0;
        end else if (mst_resp_c[m].r_valid) begin
          if (r_take[m] && mst_resp_c[m].r.last) begin
            r_lock[m] <= 1'b0;
            r_ptr [m] <= (r_gsel[m] + 1 >= NST) ? 0 : (r_gsel[m] + 1);
          end else begin
            r_lock[m] <= 1'b1;
            r_lsel[m] <= r_gsel[m];
          end
        end
      end

      // ---- B mux ------------------------------------------------------------
      always_comb begin
        int i;
        logic [7:0] req;
        req = '0;
        for (i = 0; i < NUM_SLV; i = i + 1)
          req[i] = sb_v[i] && (int'(sb[i].id[MST_ID_W-1 -: MST_IDX_W]) == m);
        req[ERRT] = !eb_empty[m];

        b_gsel[m] = b_lock[m] ? b_lsel[m] : rr_pick(req, NST, b_ptr[m]);

        mst_resp_c[m].b_valid = req[b_gsel[m]];
        mst_resp_c[m].b       = '0;
        if (b_gsel[m] == ERRT) begin
          mst_resp_c[m].b.id   = eb_dout[m];
          mst_resp_c[m].b.resp = RESP_DECERR;
          mst_resp_c[m].b.user = '0;
        end else begin
          for (i = 0; i < NUM_SLV; i = i + 1) if (b_gsel[m] == i) begin
            mst_resp_c[m].b.id   = sb[i].id[SLV_ID_W-1:0];
            mst_resp_c[m].b.resp = sb[i].resp;
            mst_resp_c[m].b.user = sb[i].user;
          end
        end
        b_take[m] = mst_resp_c[m].b_valid && mst_req[m].b_ready;
      end

      always_ff @(posedge clk) begin
        if (!rst_n) begin
          b_lock[m] <= 1'b0; b_lsel[m] <= 0; b_ptr[m] <= 0;
        end else if (mst_resp_c[m].b_valid) begin
          if (b_take[m]) begin
            b_lock[m] <= 1'b0;
            b_ptr [m] <= (b_gsel[m] + 1 >= NST) ? 0 : (b_gsel[m] + 1);
          end else begin
            b_lock[m] <= 1'b1;
            b_lsel[m] <= b_gsel[m];
          end
        end
      end
    end
  endgenerate

  // ===========================================================================
  // Slave ports
  // ===========================================================================
  generate
    for (s = 0; s < NUM_SLV; s = s + 1) begin : g_slv
      logic [BB-1:0] bd; logic bf_e, bf_f;
      logic [RB-1:0] rd; logic rf_e, rf_f;

      axi4_xbar_fifo #(.W(BB), .DEPTH(2)) i_bf (
        .clk(clk), .rst_n(rst_n),
        .push(slv_resp[s].b_valid), .din(slv_resp[s].b), .full(bf_f),
        .pop(sb_r[s]), .dout(bd), .empty(bf_e));
      axi4_xbar_fifo #(.W(RB), .DEPTH(2)) i_rf (
        .clk(clk), .rst_n(rst_n),
        .push(slv_resp[s].r_valid), .din(slv_resp[s].r), .full(rf_f),
        .pop(sr_r[s]), .dout(rd), .empty(rf_e));

      assign sb[s]   = mst_b_t'(bd);
      assign sb_v[s] = !bf_e;
      assign sr[s]   = mst_r_t'(rd);
      assign sr_v[s] = !rf_e;
      assign slv_req_c[s].b_ready = rst_n && !bf_f;
      assign slv_req_c[s].r_ready = rst_n && !rf_f;

      // W order queue. Bounded by construction: entries from master m never
      // exceed wp_cnt[m] <= WPD, so WFD = NUM_MST*WPD can never overflow and
      // AW never has to be stalled on it (which would break H3).
      axi4_xbar_fifo #(.W(MIW), .DEPTH(WFD)) i_wof (
        .clk(clk), .rst_n(rst_n), .push(wf_push[s]), .din(wf_din[s]), .full(wf_full[s]),
        .pop(wf_pop[s]), .dout(wf_dout[s]), .empty(wf_empty[s]));

      // ---- AW arbitration ---------------------------------------------------
      always_comb begin
        int i;
        awreq_v[s] = '0;
        for (i = 0; i < NUM_MST; i = i + 1) awreq_v[s][i] = aw_ok[i] && (aw_sel[i] == s);
        aw_gsel[s] = aw_lock[s] ? aw_lsel[s] : rr_pick(awreq_v[s], NUM_MST, aw_ptr[s]);

        slv_req_c[s].aw_valid = awreq_v[s][aw_gsel[s]];
        slv_req_c[s].aw       = '0;
        for (i = 0; i < NUM_MST; i = i + 1) if (aw_gsel[s] == i) begin
          slv_req_c[s].aw.id     = {{(MST_ID_W-SLV_ID_W-MIW){1'b0}}, i[MIW-1:0], maw[i].id};
          slv_req_c[s].aw.addr   = maw[i].addr;
          slv_req_c[s].aw.len    = maw[i].len;
          slv_req_c[s].aw.size   = maw[i].size;
          slv_req_c[s].aw.burst  = maw[i].burst;
          slv_req_c[s].aw.lock   = maw[i].lock;
          slv_req_c[s].aw.cache  = maw[i].cache;
          slv_req_c[s].aw.prot   = maw[i].prot;
          slv_req_c[s].aw.qos    = maw[i].qos;
          slv_req_c[s].aw.region = maw[i].region;
          slv_req_c[s].aw.atop   = maw[i].atop;
          slv_req_c[s].aw.user   = maw[i].user;
        end
        aw_do[s] = slv_req_c[s].aw_valid && slv_resp[s].aw_ready;
      end

      always_ff @(posedge clk) begin
        if (!rst_n) begin
          aw_lock[s] <= 1'b0; aw_lsel[s] <= 0; aw_ptr[s] <= 0;
        end else if (slv_req_c[s].aw_valid) begin
          if (slv_resp[s].aw_ready) begin
            aw_lock[s] <= 1'b0;
            aw_ptr [s] <= (aw_gsel[s] + 1 >= NUM_MST) ? 0 : (aw_gsel[s] + 1);
          end else begin
            aw_lock[s] <= 1'b1;
            aw_lsel[s] <= aw_gsel[s];
          end
        end
      end

      // ---- AR arbitration ---------------------------------------------------
      always_comb begin
        int i;
        arreq_v[s] = '0;
        for (i = 0; i < NUM_MST; i = i + 1) arreq_v[s][i] = ar_ok[i] && (ar_sel[i] == s);
        ar_gsel[s] = ar_lock[s] ? ar_lsel[s] : rr_pick(arreq_v[s], NUM_MST, ar_ptr[s]);

        slv_req_c[s].ar_valid = arreq_v[s][ar_gsel[s]];
        slv_req_c[s].ar       = '0;
        for (i = 0; i < NUM_MST; i = i + 1) if (ar_gsel[s] == i) begin
          slv_req_c[s].ar.id     = {{(MST_ID_W-SLV_ID_W-MIW){1'b0}}, i[MIW-1:0], mar[i].id};
          slv_req_c[s].ar.addr   = mar[i].addr;
          slv_req_c[s].ar.len    = mar[i].len;
          slv_req_c[s].ar.size   = mar[i].size;
          slv_req_c[s].ar.burst  = mar[i].burst;
          slv_req_c[s].ar.lock   = mar[i].lock;
          slv_req_c[s].ar.cache  = mar[i].cache;
          slv_req_c[s].ar.prot   = mar[i].prot;
          slv_req_c[s].ar.qos    = mar[i].qos;
          slv_req_c[s].ar.region = mar[i].region;
          slv_req_c[s].ar.user   = mar[i].user;
        end
        ar_do[s] = slv_req_c[s].ar_valid && slv_resp[s].ar_ready;
      end

      always_ff @(posedge clk) begin
        if (!rst_n) begin
          ar_lock[s] <= 1'b0; ar_lsel[s] <= 0; ar_ptr[s] <= 0;
        end else if (slv_req_c[s].ar_valid) begin
          if (slv_resp[s].ar_ready) begin
            ar_lock[s] <= 1'b0;
            ar_ptr [s] <= (ar_gsel[s] + 1 >= NUM_MST) ? 0 : (ar_gsel[s] + 1);
          end else begin
            ar_lock[s] <= 1'b1;
            ar_lsel[s] <= ar_gsel[s];
          end
        end
      end

      // ---- W follows the AW order recorded at this slave --------------------
      assign wf_push[s] = aw_do[s];
      assign wf_din [s] = aw_gsel[s][MIW-1:0];

      always_comb begin
        int i;
        slv_req_c[s].w_valid = 1'b0;
        slv_req_c[s].w       = '0;
        if (!wf_empty[s]) begin
          for (i = 0; i < NUM_MST; i = i + 1) if (int'(wf_dout[s]) == i) begin
            slv_req_c[s].w_valid = mw_v[i] && (wp_cnt[i] != '0) && (wp_sel[i] == s);
            slv_req_c[s].w       = mw[i];
          end
        end
        w_do[s]   = slv_req_c[s].w_valid && slv_resp[s].w_ready;
        wf_pop[s] = w_do[s] && slv_req_c[s].w.last;
      end

      // ---- response channels back to the masters ---------------------------
      always_comb begin
        int i;
        sb_r[s] = 1'b0;
        sr_r[s] = 1'b0;
        for (i = 0; i < NUM_MST; i = i + 1) begin
          if (b_take[i] && (b_gsel[i] == s)) sb_r[s] = 1'b1;
          if (r_take[i] && (r_gsel[i] == s)) sr_r[s] = 1'b1;
        end
      end
    end
  endgenerate

endmodule


// =============================================================================
// Two-or-more entry FIFO. `full` and `empty` are registered, which is what lets
// every crossbar-driven ready be free of a combinational path from its valid.
// =============================================================================
module axi4_xbar_fifo #(
  parameter int W     = 8,
  parameter int DEPTH = 2
) (
  input  logic         clk,
  input  logic         rst_n,
  input  logic         push,
  input  logic [W-1:0] din,
  output logic         full,
  input  logic         pop,
  output logic [W-1:0] dout,
  output logic         empty
);
  localparam int PW = (DEPTH < 2) ? 1 : $clog2(DEPTH);
  localparam int CW = $clog2(DEPTH + 1);

  logic [W-1:0]  mem [DEPTH];
  logic [PW-1:0] rp, wp;
  logic [CW-1:0] cnt;
  logic          do_push, do_pop;

  assign full    = (cnt == DEPTH[CW-1:0]);
  assign empty   = (cnt == '0);
  assign dout    = mem[rp];
  assign do_push = push && !full;
  assign do_pop  = pop  && !empty;

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      rp <= '0; wp <= '0; cnt <= '0;
    end else begin
      if (do_push) begin
        mem[wp] <= din;
        wp <= (int'(wp) == DEPTH-1) ? '0 : (wp + 1'b1);
      end
      if (do_pop) rp <= (int'(rp) == DEPTH-1) ? '0 : (rp + 1'b1);
      case ({do_push, do_pop})
        2'b10:   cnt <= cnt + 1'b1;
        2'b01:   cnt <= cnt - 1'b1;
        default: ;
      endcase
    end
  end
endmodule