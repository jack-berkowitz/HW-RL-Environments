// =============================================================================
// axi4_xbar.sv -- AXI4 crossbar: NUM_MST masters x NUM_SLV slaves
// =============================================================================
// Topology: one demultiplexer per master port (1 -> NUM_SLV+1, the extra
// destination being a per-master decode-error responder) fully crossed into one
// multiplexer per slave port (NUM_MST -> 1, which widens the id).  Disjoint
// master/slave pairs therefore share no logic at all (C2).
//
// Design notes against the specification:
//
//  H1  No ready is a combinational function of the corresponding valid.  Every
//      arbiter in this design carries a REGISTERED grant: the grant register is
//      updated from the requests seen in the previous cycle, so a port's ready
//      depends on register state and on the downstream ready, never on the
//      valid arriving with it.  This is what lets the whole datapath stay
//      combinational without violating H1 -- the usual alternative, a skid
//      buffer per channel, would spend storage that C3 prices.
//
//  C3  Zero R beats and zero W beats are stored anywhere in the crossbar.  Both
//      data paths are wires; back-pressure from a stalled response propagates
//      to the slave in the same cycle.  The only state is tracking state:
//      per-id outstanding counters, destination selects, and grant registers.
//
//  O1  Per-id ordering is enforced at each master port by per-id outstanding
//      counters: a request whose id already has transactions in flight to a
//      different destination is held until that id drains.  Responses for one
//      id therefore come from exactly one slave at a time and arrive in issue
//      order.  Distinct ids are never blocked by one another (C1).
//
//  O3  W beats follow their AWs by a destination fifo at the master port and a
//      source fifo at the slave port, both in AW-acceptance order.  Because an
//      AW enters both fifos in the same cycle, the oldest outstanding AW in the
//      system is at the head of both its master's and its slave's fifo, so some
//      write can always make progress: the W channel cannot deadlock (L1).
//
//  L2  Every arbiter is round-robin and rotates on each transfer.
// =============================================================================

// -----------------------------------------------------------------------------
// small synchronous fifo (tracking state only -- never carries W or R data)
// -----------------------------------------------------------------------------
module axi4_xbar_trk_fifo #(
    parameter int WIDTH = 4,
    parameter int DEPTH = 8      // power of two
) (
    input  logic             clk,
    input  logic             rst_n,
    input  logic             push,
    input  logic [WIDTH-1:0] din,
    input  logic             pop,
    output logic [WIDTH-1:0] dout,
    output logic             empty,
    output logic             full
);
  localparam int PW = (DEPTH <= 2) ? 1 : $clog2(DEPTH);

  logic [WIDTH-1:0] mem [DEPTH];
  logic [PW-1:0]    rp, wp;
  logic [PW:0]      cnt, cnt_n;
  logic             do_push, do_pop;

  assign empty   = (cnt == '0);
  assign full    = (cnt == (PW+1)'(DEPTH));
  assign dout    = mem[rp];
  assign do_push = push && !full;
  assign do_pop  = pop  && !empty;

  always_comb begin
    cnt_n = cnt;
    if (do_push && !do_pop) cnt_n = cnt + 1'b1;
    if (do_pop  && !do_push) cnt_n = cnt - 1'b1;
  end

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      rp  <= '0;
      wp  <= '0;
      cnt <= '0;
    end else begin
      if (do_push) begin
        mem[wp] <= din;
        wp      <= wp + 1'b1;
      end
      if (do_pop) rp <= rp + 1'b1;
      cnt <= cnt_n;
    end
  end
endmodule

// -----------------------------------------------------------------------------
// decode-error responder -- one per master port
// Completes an unmapped transaction itself (D2): a write is absorbed through
// its last W beat and answered with one DECERR B, a read is answered with
// len+1 DECERR R beats.  Manufactured beats are not stored beats, so this
// costs no data buffering.
// -----------------------------------------------------------------------------
module axi4_xbar_err_slv
  import axi4_xbar_pkg::*;
#(
    parameter int DEPTH = 8
) (
    input  logic      clk,
    input  logic      rst_n,
    input  slv_req_t  req_i,
    output slv_resp_t resp_o
);
  logic            awf_push, awf_pop, awf_empty, awf_full;
  logic [SLV_ID_W-1:0] awf_dout;
  logic            bf_push, bf_pop, bf_empty, bf_full;
  logic [SLV_ID_W-1:0] bf_dout;
  logic            arf_push, arf_pop, arf_empty, arf_full;
  logic [SLV_ID_W+8-1:0] arf_din, arf_dout;

  logic [7:0] rbeat_q;
  logic       aw_ready_c, w_ready_c, ar_ready_c;
  logic       b_valid_c, r_valid_c, r_last_c;

  axi4_xbar_trk_fifo #(.WIDTH(SLV_ID_W), .DEPTH(DEPTH)) i_awf (
      .clk, .rst_n, .push(awf_push), .din(req_i.aw.id), .pop(awf_pop),
      .dout(awf_dout), .empty(awf_empty), .full(awf_full));

  axi4_xbar_trk_fifo #(.WIDTH(SLV_ID_W), .DEPTH(DEPTH)) i_bf (
      .clk, .rst_n, .push(bf_push), .din(awf_dout), .pop(bf_pop),
      .dout(bf_dout), .empty(bf_empty), .full(bf_full));

  assign arf_din = {req_i.ar.id, req_i.ar.len};
  axi4_xbar_trk_fifo #(.WIDTH(SLV_ID_W+8), .DEPTH(DEPTH)) i_arf (
      .clk, .rst_n, .push(arf_push), .din(arf_din), .pop(arf_pop),
      .dout(arf_dout), .empty(arf_empty), .full(arf_full));

  // ---- write ----------------------------------------------------------------
  assign aw_ready_c = !awf_full;
  assign awf_push   = req_i.aw_valid && aw_ready_c;

  assign w_ready_c  = !awf_empty && !bf_full;
  assign bf_push    = req_i.w_valid && w_ready_c && req_i.w.last;
  assign awf_pop    = bf_push;

  assign b_valid_c  = !bf_empty;
  assign bf_pop     = b_valid_c && req_i.b_ready;

  // ---- read -----------------------------------------------------------------
  assign ar_ready_c = !arf_full;
  assign arf_push   = req_i.ar_valid && ar_ready_c;

  assign r_valid_c  = !arf_empty;
  assign r_last_c   = (rbeat_q == arf_dout[7:0]);
  assign arf_pop    = r_valid_c && req_i.r_ready && r_last_c;

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      rbeat_q <= 8'd0;
    end else if (r_valid_c && req_i.r_ready) begin
      rbeat_q <= r_last_c ? 8'd0 : (rbeat_q + 8'd1);
    end
  end

  always_comb begin
    resp_o          = '0;
    resp_o.aw_ready = aw_ready_c;
    resp_o.w_ready  = w_ready_c;
    resp_o.ar_ready = ar_ready_c;
    resp_o.b_valid  = b_valid_c;
    resp_o.b.id     = bf_dout;
    resp_o.b.resp   = RESP_DECERR;
    resp_o.b.user   = '0;
    resp_o.r_valid  = r_valid_c;
    resp_o.r.id     = arf_dout[SLV_ID_W+8-1:8];
    resp_o.r.data   = '0;
    resp_o.r.resp   = RESP_DECERR;
    resp_o.r.last   = r_last_c;
    resp_o.r.user   = '0;
  end
endmodule

// -----------------------------------------------------------------------------
// per-master demultiplexer, 1 -> NUM_SLV+1
// -----------------------------------------------------------------------------
module axi4_xbar_demux
  import axi4_xbar_pkg::*;
#(
    parameter int NUM_SLV  = 2,
    parameter int WFIFO_D  = 16
) (
    input  logic                    clk,
    input  logic                    rst_n,
    input  slv_req_t                m_req,
    output slv_resp_t               m_resp,
    output slv_req_t  [NUM_SLV:0]   d_req,     // [NUM_SLV] is the error responder
    input  slv_resp_t [NUM_SLV:0]   d_resp,
    input  xbar_rule_t [NUM_SLV-1:0] addr_map
);
  localparam int NSEL = NUM_SLV + 1;
  localparam int SW   = (NSEL <= 2) ? 1 : $clog2(NSEL);
  localparam int NID  = 1 << SLV_ID_W;
  localparam int CW   = 5;                       // per-id outstanding counter

  // ---- address decode (D1/D3: address only) ---------------------------------
  function automatic logic [SW-1:0] decode_addr(input addr_t a);
    logic [SW-1:0] s;
    s = SW'(NUM_SLV);                            // no rule matched -> error (D2)
    for (int k = 0; k < NUM_SLV; k++)
      if ((a >= addr_map[k].start_addr) && (a < addr_map[k].end_addr))
        s = SW'(addr_map[k].mst_port);
    return s;
  endfunction

  function automatic int rr_next(input logic [NSEL-1:0] reqs, input int cur);
    int k;
    for (int n = 1; n <= NSEL; n++) begin
      k = (cur + n) % NSEL;
      if (reqs[k]) return k;
    end
    return cur;
  endfunction

  // ---- per-id outstanding tracking (O1) -------------------------------------
  logic [CW-1:0] wcnt [NID];
  logic [SW-1:0] wdst [NID];
  logic [CW-1:0] rcnt [NID];
  logic [SW-1:0] rdst [NID];

  logic [SW-1:0] aw_sel, ar_sel;
  logic          aw_ok, ar_ok;

  assign aw_sel = decode_addr(m_req.aw.addr);
  assign ar_sel = decode_addr(m_req.ar.addr);

  logic wf_push, wf_pop, wf_empty, wf_full;
  logic [SW-1:0] wf_head;

  assign aw_ok = ((wcnt[m_req.aw.id] == '0) || (wdst[m_req.aw.id] == aw_sel))
                 && (wcnt[m_req.aw.id] != {CW{1'b1}})
                 && !wf_full;
  assign ar_ok = ((rcnt[m_req.ar.id] == '0) || (rdst[m_req.ar.id] == ar_sel))
                 && (rcnt[m_req.ar.id] != {CW{1'b1}});

  // ---- request paths --------------------------------------------------------
  logic            aw_ready_c, w_ready_c, ar_ready_c;
  logic [NSEL-1:0] aw_valid_c, w_valid_c, ar_valid_c;

  assign aw_ready_c = aw_ok && d_resp[aw_sel].aw_ready;
  assign ar_ready_c = ar_ok && d_resp[ar_sel].ar_ready;
  assign w_ready_c  = !wf_empty && d_resp[wf_head].w_ready;

  always_comb begin
    aw_valid_c = '0;
    ar_valid_c = '0;
    w_valid_c  = '0;
    if (m_req.aw_valid && aw_ok)   aw_valid_c[aw_sel]  = 1'b1;
    if (m_req.ar_valid && ar_ok)   ar_valid_c[ar_sel]  = 1'b1;
    if (m_req.w_valid  && !wf_empty) w_valid_c[wf_head] = 1'b1;
  end

  // W destination fifo, in AW-acceptance order (O3)
  assign wf_push = m_req.aw_valid && aw_ready_c;
  assign wf_pop  = m_req.w_valid  && w_ready_c && m_req.w.last;
  axi4_xbar_trk_fifo #(.WIDTH(SW), .DEPTH(WFIFO_D)) i_wf (
      .clk, .rst_n, .push(wf_push), .din(aw_sel), .pop(wf_pop),
      .dout(wf_head), .empty(wf_empty), .full(wf_full));

  // ---- response paths: registered round-robin grants (H1) -------------------
  logic [NSEL-1:0] b_req_v, r_req_v;
  logic [SW-1:0]   b_sel_q, r_sel_q;
  logic            r_busy_q;
  logic            b_xfer, r_xfer, r_hold;

  always_comb begin
    for (int k = 0; k < NSEL; k++) begin
      b_req_v[k] = d_resp[k].b_valid;
      r_req_v[k] = d_resp[k].r_valid;
    end
  end

  assign b_xfer = d_resp[b_sel_q].b_valid && m_req.b_ready;
  assign r_xfer = d_resp[r_sel_q].r_valid && m_req.r_ready;
  assign r_hold = r_busy_q || (d_resp[r_sel_q].r_valid && !m_req.r_ready);

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      b_sel_q  <= '0;
      r_sel_q  <= '0;
      r_busy_q <= 1'b0;
    end else begin
      // B: hold the grant only while the selected source is waiting for ready
      if (!(d_resp[b_sel_q].b_valid && !m_req.b_ready))
        b_sel_q <= SW'(rr_next(b_req_v, int'(b_sel_q)));
      // R: additionally locked for the duration of a burst (O4)
      if (r_xfer) r_busy_q <= ~d_resp[r_sel_q].r.last;
      if (r_xfer ? d_resp[r_sel_q].r.last : !r_hold)
        r_sel_q <= SW'(rr_next(r_req_v, int'(r_sel_q)));
    end
  end

  // ---- outstanding counters -------------------------------------------------
  logic aw_acc, ar_acc, b_acc, rl_acc;
  logic [SLV_ID_W-1:0] b_id, r_id;

  assign aw_acc = m_req.aw_valid && aw_ready_c;
  assign ar_acc = m_req.ar_valid && ar_ready_c;
  assign b_acc  = b_xfer;
  assign b_id   = d_resp[b_sel_q].b.id;
  assign rl_acc = r_xfer && d_resp[r_sel_q].r.last;
  assign r_id   = d_resp[r_sel_q].r.id;

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      for (int k = 0; k < NID; k++) begin
        wcnt[k] <= '0;
        rcnt[k] <= '0;
        wdst[k] <= '0;
        rdst[k] <= '0;
      end
    end else begin
      for (int k = 0; k < NID; k++) begin
        if (aw_acc && (int'(m_req.aw.id) == k)) wdst[k] <= aw_sel;
        if (ar_acc && (int'(m_req.ar.id) == k)) rdst[k] <= ar_sel;
        case ({aw_acc && (int'(m_req.aw.id) == k), b_acc && (int'(b_id) == k)})
          2'b10:   wcnt[k] <= wcnt[k] + 1'b1;
          2'b01:   wcnt[k] <= wcnt[k] - 1'b1;
          default: ;
        endcase
        case ({ar_acc && (int'(m_req.ar.id) == k), rl_acc && (int'(r_id) == k)})
          2'b10:   rcnt[k] <= rcnt[k] + 1'b1;
          2'b01:   rcnt[k] <= rcnt[k] - 1'b1;
          default: ;
        endcase
      end
    end
  end

  // ---- port assembly --------------------------------------------------------
  always_comb begin
    for (int k = 0; k < NSEL; k++) begin
      d_req[k]          = '0;
      d_req[k].aw       = m_req.aw;
      d_req[k].aw_valid = aw_valid_c[k];
      d_req[k].w        = m_req.w;
      d_req[k].w_valid  = w_valid_c[k];
      d_req[k].b_ready  = (k == int'(b_sel_q)) && m_req.b_ready;
      d_req[k].ar       = m_req.ar;
      d_req[k].ar_valid = ar_valid_c[k];
      d_req[k].r_ready  = (k == int'(r_sel_q)) && m_req.r_ready;
    end
  end

  always_comb begin
    m_resp          = '0;
    m_resp.aw_ready = aw_ready_c;
    m_resp.ar_ready = ar_ready_c;
    m_resp.w_ready  = w_ready_c;
    m_resp.b_valid  = d_resp[b_sel_q].b_valid;
    m_resp.b        = d_resp[b_sel_q].b;
    m_resp.r_valid  = d_resp[r_sel_q].r_valid;
    m_resp.r        = d_resp[r_sel_q].r;
  end
endmodule

// -----------------------------------------------------------------------------
// per-slave multiplexer, NUM_MST -> 1, widening the id
// -----------------------------------------------------------------------------
module axi4_xbar_mux
  import axi4_xbar_pkg::*;
#(
    parameter int NUM_MST = 2,
    parameter int WFIFO_D = 32
) (
    input  logic                     clk,
    input  logic                     rst_n,
    input  slv_req_t  [NUM_MST-1:0]  s_req,
    output slv_resp_t [NUM_MST-1:0]  s_resp,
    output mst_req_t                 m_req,
    input  mst_resp_t                m_resp
);
  localparam int MW = (NUM_MST <= 2) ? 1 : $clog2(NUM_MST);

  function automatic int rr_next(input logic [NUM_MST-1:0] reqs, input int cur);
    int k;
    for (int n = 1; n <= NUM_MST; n++) begin
      k = (cur + n) % NUM_MST;
      if (reqs[k]) return k;
    end
    return cur;
  endfunction

  logic [NUM_MST-1:0] aw_req_v, ar_req_v;
  logic [MW-1:0]      aw_gnt_q, ar_gnt_q;

  logic wf_push, wf_pop, wf_empty, wf_full;
  logic [MW-1:0] wf_head;

  logic aw_go, ar_go, aw_xfer, ar_xfer;

  always_comb begin
    for (int k = 0; k < NUM_MST; k++) begin
      aw_req_v[k] = s_req[k].aw_valid;
      ar_req_v[k] = s_req[k].ar_valid;
    end
  end

  assign aw_go   = s_req[aw_gnt_q].aw_valid && !wf_full;
  assign ar_go   = s_req[ar_gnt_q].ar_valid;
  assign aw_xfer = aw_go && m_resp.aw_ready;
  assign ar_xfer = ar_go && m_resp.ar_ready;

  // W source fifo, in AW-grant order (O3)
  assign wf_push = aw_xfer;
  assign wf_pop  = m_req.w_valid && m_resp.w_ready && m_req.w.last;
  axi4_xbar_trk_fifo #(.WIDTH(MW), .DEPTH(WFIFO_D)) i_wf (
      .clk, .rst_n, .push(wf_push), .din(aw_gnt_q), .pop(wf_pop),
      .dout(wf_head), .empty(wf_empty), .full(wf_full));

  // ---- registered round-robin grants (H1, L2) -------------------------------
  always_ff @(posedge clk) begin
    if (!rst_n) begin
      aw_gnt_q <= '0;
      ar_gnt_q <= '0;
    end else begin
      if (!(s_req[aw_gnt_q].aw_valid && !aw_xfer))
        aw_gnt_q <= MW'(rr_next(aw_req_v, int'(aw_gnt_q)));
      if (!(s_req[ar_gnt_q].ar_valid && !ar_xfer))
        ar_gnt_q <= MW'(rr_next(ar_req_v, int'(ar_gnt_q)));
    end
  end

  // ---- response routing by the master index carried in the id ---------------
  logic [MST_IDX_W-1:0] b_idx_raw, r_idx_raw;
  logic [MW-1:0]        b_idx, r_idx;

  assign b_idx_raw = m_resp.b.id[SLV_ID_W+MST_IDX_W-1:SLV_ID_W];
  assign r_idx_raw = m_resp.r.id[SLV_ID_W+MST_IDX_W-1:SLV_ID_W];
  assign b_idx     = MW'(b_idx_raw);
  assign r_idx     = MW'(r_idx_raw);

  // ---- port assembly --------------------------------------------------------
  always_comb begin
    m_req           = '0;

    m_req.aw.id     = {2'(aw_gnt_q), s_req[aw_gnt_q].aw.id};
    m_req.aw.addr   = s_req[aw_gnt_q].aw.addr;
    m_req.aw.len    = s_req[aw_gnt_q].aw.len;
    m_req.aw.size   = s_req[aw_gnt_q].aw.size;
    m_req.aw.burst  = s_req[aw_gnt_q].aw.burst;
    m_req.aw.lock   = s_req[aw_gnt_q].aw.lock;
    m_req.aw.cache  = s_req[aw_gnt_q].aw.cache;
    m_req.aw.prot   = s_req[aw_gnt_q].aw.prot;
    m_req.aw.qos    = s_req[aw_gnt_q].aw.qos;
    m_req.aw.region = s_req[aw_gnt_q].aw.region;
    m_req.aw.atop   = s_req[aw_gnt_q].aw.atop;
    m_req.aw.user   = s_req[aw_gnt_q].aw.user;
    m_req.aw_valid  = aw_go;

    m_req.w         = s_req[wf_head].w;
    m_req.w_valid   = !wf_empty && s_req[wf_head].w_valid;

    m_req.ar.id     = {2'(ar_gnt_q), s_req[ar_gnt_q].ar.id};
    m_req.ar.addr   = s_req[ar_gnt_q].ar.addr;
    m_req.ar.len    = s_req[ar_gnt_q].ar.len;
    m_req.ar.size   = s_req[ar_gnt_q].ar.size;
    m_req.ar.burst  = s_req[ar_gnt_q].ar.burst;
    m_req.ar.lock   = s_req[ar_gnt_q].ar.lock;
    m_req.ar.cache  = s_req[ar_gnt_q].ar.cache;
    m_req.ar.prot   = s_req[ar_gnt_q].ar.prot;
    m_req.ar.qos    = s_req[ar_gnt_q].ar.qos;
    m_req.ar.region = s_req[ar_gnt_q].ar.region;
    m_req.ar.user   = s_req[ar_gnt_q].ar.user;
    m_req.ar_valid  = ar_go;

    m_req.b_ready   = s_req[b_idx].b_ready;
    m_req.r_ready   = s_req[r_idx].r_ready;
  end

  always_comb begin
    for (int k = 0; k < NUM_MST; k++) begin
      s_resp[k]          = '0;
      s_resp[k].aw_ready = (k == int'(aw_gnt_q)) && !wf_full && m_resp.aw_ready;
      s_resp[k].ar_ready = (k == int'(ar_gnt_q)) && m_resp.ar_ready;
      s_resp[k].w_ready  = !wf_empty && (k == int'(wf_head)) && m_resp.w_ready;

      s_resp[k].b_valid  = m_resp.b_valid && (k == int'(b_idx));
      s_resp[k].b.id     = m_resp.b.id[SLV_ID_W-1:0];
      s_resp[k].b.resp   = m_resp.b.resp;
      s_resp[k].b.user   = m_resp.b.user;

      s_resp[k].r_valid  = m_resp.r_valid && (k == int'(r_idx));
      s_resp[k].r.id     = m_resp.r.id[SLV_ID_W-1:0];
      s_resp[k].r.data   = m_resp.r.data;
      s_resp[k].r.resp   = m_resp.r.resp;
      s_resp[k].r.last   = m_resp.r.last;
      s_resp[k].r.user   = m_resp.r.user;
    end
  end
endmodule

// =============================================================================
// the crossbar
// =============================================================================
module axi4_xbar
  import axi4_xbar_pkg::*;
#(
    parameter int NUM_MST   = 2,   // masters attached   (2 / 4)
    parameter int NUM_SLV   = 2,   // slaves attached    (2 / 4)
    parameter int MAX_TRANS = 8,   // REQUIRED outstanding per master port (2 / 8)
    parameter int MAX_BURST_LEN = 3 // largest ARLEN/AWLEN to support (3 / 255)
) (
    input  logic clk,
    input  logic rst_n,

    input  slv_req_t  [NUM_MST-1:0] mst_req,
    output slv_resp_t [NUM_MST-1:0] mst_resp,

    output mst_req_t  [NUM_SLV-1:0] slv_req,
    input  mst_resp_t [NUM_SLV-1:0] slv_resp,

    input  xbar_rule_t [NUM_SLV-1:0] addr_map
);

  // The W-destination fifo bounds how many AWs a master may have accepted with
  // their write data still to come; it holds selects, not beats, so honouring
  // MAX_TRANS here is cheap (C1 vs C3).
  localparam int WFIFO_M = (MAX_TRANS < 16) ? 16 : 32;
  localparam int WFIFO_S = 32;

  slv_req_t  [NUM_MST-1:0][NUM_SLV:0]     d_req;
  slv_resp_t [NUM_MST-1:0][NUM_SLV:0]     d_resp;
  slv_req_t  [NUM_SLV-1:0][NUM_MST-1:0]   x_req;
  slv_resp_t [NUM_SLV-1:0][NUM_MST-1:0]   x_resp;

  slv_resp_t [NUM_MST-1:0]                m_resp_i;
  mst_req_t  [NUM_SLV-1:0]                s_req_i;

  // ---- the full crossing ----------------------------------------------------
  for (genvar i = 0; i < NUM_MST; i++) begin : g_cross_m
    for (genvar j = 0; j < NUM_SLV; j++) begin : g_cross_s
      assign x_req[j][i]  = d_req[i][j];
      assign d_resp[i][j] = x_resp[j][i];
    end
  end

  // ---- one demultiplexer and one error responder per master port ------------
  for (genvar i = 0; i < NUM_MST; i++) begin : g_mst
    axi4_xbar_demux #(
        .NUM_SLV (NUM_SLV),
        .WFIFO_D (WFIFO_M)
    ) i_demux (
        .clk      (clk),
        .rst_n    (rst_n),
        .m_req    (mst_req[i]),
        .m_resp   (m_resp_i[i]),
        .d_req    (d_req[i]),
        .d_resp   (d_resp[i]),
        .addr_map (addr_map)
    );

    axi4_xbar_err_slv #(.DEPTH(8)) i_err (
        .clk    (clk),
        .rst_n  (rst_n),
        .req_i  (d_req[i][NUM_SLV]),
        .resp_o (d_resp[i][NUM_SLV])
    );
  end

  // ---- one multiplexer per slave port ---------------------------------------
  for (genvar j = 0; j < NUM_SLV; j++) begin : g_slv
    axi4_xbar_mux #(
        .NUM_MST (NUM_MST),
        .WFIFO_D (WFIFO_S)
    ) i_mux (
        .clk    (clk),
        .rst_n  (rst_n),
        .s_req  (x_req[j]),
        .s_resp (x_resp[j]),
        .m_req  (s_req_i[j]),
        .m_resp (slv_resp[j])
    );
  end

  // ---- R1: no output valid is asserted while reset is low --------------------
  always_comb begin
    mst_resp = m_resp_i;
    slv_req  = s_req_i;
    if (!rst_n) begin
      for (int i = 0; i < NUM_MST; i++) begin
        mst_resp[i].b_valid  = 1'b0;
        mst_resp[i].r_valid  = 1'b0;
        mst_resp[i].aw_ready = 1'b0;
        mst_resp[i].w_ready  = 1'b0;
        mst_resp[i].ar_ready = 1'b0;
      end
      for (int j = 0; j < NUM_SLV; j++) begin
        slv_req[j].aw_valid = 1'b0;
        slv_req[j].w_valid  = 1'b0;
        slv_req[j].ar_valid = 1'b0;
        slv_req[j].b_ready  = 1'b0;
        slv_req[j].r_ready  = 1'b0;
      end
    end
  end

endmodule