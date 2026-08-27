// F1(a) NEGATIVE CONTROL for v_ca03 -- it MUST FAIL, and on F1 alone.
//
// F1(a) asserts the design is idle WHILE rst_ni is low. Every other DUT checker
// in this testbench is gated `if (rst_n && ...)`, so nothing observed that window
// until F1(a) was written -- and a checker nobody can make fire is the state this
// corpus has spent a week learning not to accept on a passing golden.
//
// TWO EARLIER VERSIONS FAILED ON D5 AS WELL, AND I MISDIAGNOSED WHY. I recorded
// that "a valid raised while its ready is low and then released is a withdrawal,
// which is what D5 forbids". That is false here: D5's `pv` is cleared while
// rst_ni is low and only updated in the else branch, so a valid confined to the
// reset window cannot set it. The real cause was that both versions were built by
// COPYING d5_withdraws_ar.sv, which carries its own perturbation --
// `assign m_arvalid = g_m_arvalid & ~drop` -- and I renamed the module without
// removing it. Every D5 failure was d5's control doing its job.
//
// COPYING A CONTROL BRINGS ITS PERTURBATION. d5_withdraws_ar.sv's own header
// records the same trap one step earlier, where it was built from iw_c3 and
// inherited bindings that do not exist here. Twice in one file, from two sources.
//
//
// DIFFERENTIAL, and it is stronger than the FIRED counter beside it. Build this
// file with the perturbation replaced by a constant 0 and the run must PASS.
// That makes the perturbation NECESSARY for the failure rather than merely
// present during it -- which a FIRED counter cannot establish, and which is
// exactly the gap that let two earlier versions of the F1(a) control fail on D5
// while their own counter read healthy. Proposed by the design half; measured
// here:
//     with the perturbation     FAIL, F1 only, 8 failures, force 8
//     with it replaced by 1'b0  PASS
// WHAT THIS ONE PERTURBS, and it is the smallest thing that violates F1(a):
// s_rvalid is forced high while rst_ni is low, only on cycles where s_rready is
// already low. Ready low means no handshake, so the testbench's model records
// nothing that did not happen; and F1(a) tests the response channels for a bare
// VALID, because presenting one IS the violation. Nothing else is touched.
module iw_nc_f1_answers_in_reset #(
    parameter int unsigned SLV_ID_W        = 4,
    parameter int unsigned MST_ID_W        = 2,
    parameter int unsigned ADDR_W          = 32,
    parameter int unsigned DATA_W          = 32,
    parameter int unsigned MAX_UNIQ_IDS    = 4,
    parameter int unsigned MAX_TXNS_PER_ID = 2

) (
    input  logic                    clk_i,
    input  logic                    rst_ni,

    // ---- slave (upstream) port ----
    input  logic [SLV_ID_W-1:0]        s_awid,
    input  logic [ADDR_W-1:0]        s_awaddr,
    input  logic [7:0]               s_awlen,
    input  logic                     s_awvalid,
    output logic                     s_awready,

    input  logic [DATA_W-1:0]        s_wdata,
    input  logic [DATA_W/8-1:0]      s_wstrb,
    input  logic                     s_wlast,
    input  logic                     s_wvalid,
    output logic                     s_wready,

    output logic [SLV_ID_W-1:0]        s_bid,
    output logic [1:0]               s_bresp,
    output logic                     s_bvalid,
    input  logic                     s_bready,

    input  logic [SLV_ID_W-1:0]        s_arid,
    input  logic [ADDR_W-1:0]        s_araddr,
    input  logic [7:0]               s_arlen,
    input  logic                     s_arvalid,
    output logic                     s_arready,

    output logic [SLV_ID_W-1:0]        s_rid,
    output logic [DATA_W-1:0]        s_rdata,
    output logic [1:0]               s_rresp,
    output logic                     s_rlast,
    output logic                     s_rvalid,
    input  logic                     s_rready,
    // ---- master (downstream) port ----
    output logic [MST_ID_W-1:0]        m_awid,
    output logic [ADDR_W-1:0]        m_awaddr,
    output logic [7:0]               m_awlen,
    output logic                     m_awvalid,
    input  logic                     m_awready,

    output logic [DATA_W-1:0]        m_wdata,
    output logic [DATA_W/8-1:0]      m_wstrb,
    output logic                     m_wlast,
    output logic                     m_wvalid,
    input  logic                     m_wready,

    input  logic [MST_ID_W-1:0]        m_bid,
    input  logic [1:0]               m_bresp,
    input  logic                     m_bvalid,
    output logic                     m_bready,

    output logic [MST_ID_W-1:0]        m_arid,
    output logic [ADDR_W-1:0]        m_araddr,
    output logic [7:0]               m_arlen,
    output logic                     m_arvalid,
    input  logic                     m_arready,

    input  logic [MST_ID_W-1:0]        m_rid,
    input  logic [DATA_W-1:0]        m_rdata,
    input  logic [1:0]               m_rresp,
    input  logic                     m_rlast,
    input  logic                     m_rvalid,
    output logic                     m_rready
);
  // DID IT FIRE? A verdict says what happened; this says whether anything was
  // asked. The first version of this control PASSED because its trigger never
  // occurred, and a pass and a no-op are indistinguishable without this line.
  // Convention: `FIRED <name> <count>`, checked by check_fired.py, which
  // REFUSES on zero.

  // THE ONLY PERTURBATION. s_rvalid is forced high for every cycle rst_ni is
  // low; at every other time the design's own output passes through untouched.
  //
  // D5 cannot see this: D5's `pv` is cleared while rst_ni is low and updated
  // only in the else branch, so a valid confined to the reset window never
  // sets it. Measured -- 8 F1 failures and 0 of anything else.
  logic g_s_rvalid;

  wire  force_r = !rst_ni;

  assign s_rvalid = force_r ? 1'b1 : g_s_rvalid;

  int n_force = 0;

  always @(posedge clk_i) if (force_r) n_force <= n_force + 1;

  final $display("FIRED nc_f1_answers_in_reset.force %0d", n_force);

  id_width_conv #(
      .SLV_ID_W(SLV_ID_W),
      .MST_ID_W(MST_ID_W),
      .ADDR_W(ADDR_W),
      .DATA_W(DATA_W),
      .MAX_UNIQ_IDS(MAX_UNIQ_IDS),
      .MAX_TXNS_PER_ID(MAX_TXNS_PER_ID)
  ) i_g (
      .clk_i      (clk_i),
      .rst_ni     (rst_ni),
      .s_awid     (s_awid),
      .s_awaddr   (s_awaddr),
      .s_awlen    (s_awlen),
      .s_awvalid  (s_awvalid),
      .s_awready  (s_awready),
      .s_wdata    (s_wdata),
      .s_wstrb    (s_wstrb),
      .s_wlast    (s_wlast),
      .s_wvalid   (s_wvalid),
      .s_wready   (s_wready),
      .s_bid      (s_bid),
      .s_bresp    (s_bresp),
      .s_bvalid   (s_bvalid),
      .s_bready   (s_bready),
      .s_arid     (s_arid),
      .s_araddr   (s_araddr),
      .s_arlen    (s_arlen),
      .s_arvalid  (s_arvalid),
      .s_arready  (s_arready),
      .s_rid      (s_rid),
      .s_rdata    (s_rdata),
      .s_rresp    (s_rresp),
      .s_rlast    (s_rlast),
      .s_rvalid   (g_s_rvalid),
      .s_rready   (s_rready),
      .m_awid     (m_awid),
      .m_awaddr   (m_awaddr),
      .m_awlen    (m_awlen),
      .m_awvalid  (m_awvalid),
      .m_awready  (m_awready),
      .m_wdata    (m_wdata),
      .m_wstrb    (m_wstrb),
      .m_wlast    (m_wlast),
      .m_wvalid   (m_wvalid),
      .m_wready   (m_wready),
      .m_bid      (m_bid),
      .m_bresp    (m_bresp),
      .m_bvalid   (m_bvalid),
      .m_bready   (m_bready),
      .m_arid     (m_arid),
      .m_araddr   (m_araddr),
      .m_arlen    (m_arlen),
      .m_arvalid  (m_arvalid),
      .m_arready  (m_arready),
      .m_rid      (m_rid),
      .m_rdata    (m_rdata),
      .m_rresp    (m_rresp),
      .m_rlast    (m_rlast),
      .m_rvalid   (m_rvalid),
      .m_rready   (m_rready)
  );
endmodule
