// A5 NEGATIVE CONTROL for v_ca06 -- it MUST FAIL, and on A5 alone.
//
// A5 was landed with a checker that passed everything the task ships, which is
// what a correct clause looks like and also what a clause with no instrument
// looks like. Rule 24 wants a control that REFUSES, and there was none: every
// mutant here dies on some other clause, so none of them licenses a claim that
// A5's checker fires at all.
//
// IT WITHDRAWS ONLY WHERE THE TRANSFER COULD NOT HAVE HAPPENED. `drop` asserts
// only on a cycle when `m_arready` is already low, so no handshake is lost and
// the wrapped design sees a bit-identical environment -- its ready is passed
// through untouched. The only observable difference is that `m_arvalid` falls
// while its ready is low, which is precisely and solely what A5 forbids. The
// twin control on v_ca03 is negctl/d5_withdraws_ar.sv; on the first attempt
// there, a version that also gated the design's ready hung a phase and reported
// three unrelated clauses. A control whose blast radius exceeds the clause it is
// for cannot license a claim about that clause.
//
// It deliberately violates A5's second sentence too -- `m_arvalid` here IS
// combinational on `m_arready`. That is a property of the control; the
// testbench's readies are LFSR-driven and read no design output, so no
// combinational loop is closed.
module dw_nc_a5_withdraws_ar #(
    parameter int unsigned ADDR_W     = 32,
    parameter int unsigned ID_W       = 4,
    parameter int unsigned SLV_DATA_W = 64,   // upstream, wide
    parameter int unsigned MST_DATA_W = 16,   // downstream, narrow
    parameter int unsigned MAX_READS  = 4

) (
    input  logic clk_i,
    input  logic rst_ni,

    // ---- slave (upstream, WIDE) port ----
    input  logic [ID_W-1:0]          s_awid,
    input  logic [ADDR_W-1:0]        s_awaddr,
    input  logic [7:0]               s_awlen,
    input  logic [2:0]               s_awsize,
    input  logic [1:0]               s_awburst,
    input  logic                     s_awvalid,
    output logic                     s_awready,
    input  logic [SLV_DATA_W-1:0]    s_wdata,
    input  logic [SLV_DATA_W/8-1:0]  s_wstrb,
    input  logic                     s_wlast,
    input  logic                     s_wvalid,
    output logic                     s_wready,
    output logic [ID_W-1:0]          s_bid,
    output logic [1:0]               s_bresp,
    output logic                     s_bvalid,
    input  logic                     s_bready,
    input  logic [ID_W-1:0]          s_arid,
    input  logic [ADDR_W-1:0]        s_araddr,
    input  logic [7:0]               s_arlen,
    input  logic [2:0]               s_arsize,
    input  logic [1:0]               s_arburst,
    input  logic                     s_arvalid,
    output logic                     s_arready,
    output logic [ID_W-1:0]          s_rid,
    output logic [SLV_DATA_W-1:0]    s_rdata,
    output logic [1:0]               s_rresp,
    output logic                     s_rlast,
    output logic                     s_rvalid,
    input  logic                     s_rready,

    // ---- master (downstream, NARROW) port ----
    output logic [ID_W-1:0]          m_awid,
    output logic [ADDR_W-1:0]        m_awaddr,
    output logic [7:0]               m_awlen,
    output logic [2:0]               m_awsize,
    output logic [1:0]               m_awburst,
    output logic                     m_awvalid,
    input  logic                     m_awready,
    output logic [MST_DATA_W-1:0]    m_wdata,
    output logic [MST_DATA_W/8-1:0]  m_wstrb,
    output logic                     m_wlast,
    output logic                     m_wvalid,
    input  logic                     m_wready,
    input  logic [ID_W-1:0]          m_bid,
    input  logic [1:0]               m_bresp,
    input  logic                     m_bvalid,
    output logic                     m_bready,
    output logic [ID_W-1:0]          m_arid,
    output logic [ADDR_W-1:0]        m_araddr,
    output logic [7:0]               m_arlen,
    output logic [2:0]               m_arsize,
    output logic [1:0]               m_arburst,
    output logic                     m_arvalid,
    input  logic                     m_arready,
    input  logic [ID_W-1:0]          m_rid,
    input  logic [MST_DATA_W-1:0]    m_rdata,
    input  logic [1:0]               m_rresp,
    input  logic                     m_rlast,
    input  logic                     m_rvalid,
    output logic                     m_rready
);
  logic g_m_arvalid;
  logic [1:0] cnt;
  always_ff @(posedge clk_i or negedge rst_ni)
    if (!rst_ni)                        cnt <= 2'd0;
    else if (g_m_arvalid && !m_arready) cnt <= cnt + 2'd1;
    else                                cnt <= 2'd0;
  // THRESHOLD ONE, NOT TWO, AND THE FIRST VALUE WAS WRONG IN A WAY THAT PASSED.
  // At `cnt >= 2` -- three consecutive stalled cycles -- this control PASSED on
  // v_ca06, because backpressure is aperiodic and `m_arvalid` reaches the
  // antecedent only 18 times in the whole run. A control that passes is not
  // evidence that the clause holds; it is evidence that the control never ran.
  // One stalled cycle is needed before the withdrawal so that A5/D5's antecedent
  // is actually entered, and the second is the withdrawal itself.
  wire drop = (cnt >= 2'd1) && g_m_arvalid && !m_arready;
  assign m_arvalid = g_m_arvalid & ~drop;

  dw_downsizer #(
      .ADDR_W(ADDR_W),
      .ID_W(ID_W),
      .SLV_DATA_W(SLV_DATA_W),
      .MST_DATA_W(MST_DATA_W),
      .MAX_READS(MAX_READS)
  ) i_g (
      .clk_i      (clk_i),
      .rst_ni     (rst_ni),
      .s_awid     (s_awid),
      .s_awaddr   (s_awaddr),
      .s_awlen    (s_awlen),
      .s_awsize   (s_awsize),
      .s_awburst  (s_awburst),
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
      .s_arsize   (s_arsize),
      .s_arburst  (s_arburst),
      .s_arvalid  (s_arvalid),
      .s_arready  (s_arready),
      .s_rid      (s_rid),
      .s_rdata    (s_rdata),
      .s_rresp    (s_rresp),
      .s_rlast    (s_rlast),
      .s_rvalid   (s_rvalid),
      .s_rready   (s_rready),
      .m_awid     (m_awid),
      .m_awaddr   (m_awaddr),
      .m_awlen    (m_awlen),
      .m_awsize   (m_awsize),
      .m_awburst  (m_awburst),
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
      .m_arsize   (m_arsize),
      .m_arburst  (m_arburst),
      .m_arvalid  (g_m_arvalid),
      .m_arready  (m_arready),
      .m_rid      (m_rid),
      .m_rdata    (m_rdata),
      .m_rresp    (m_rresp),
      .m_rlast    (m_rlast),
      .m_rvalid   (m_rvalid),
      .m_rready   (m_rready)
  );
endmodule
