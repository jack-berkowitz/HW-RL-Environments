// D5 NEGATIVE CONTROL for v_ca03 -- it MUST FAIL, and on D5 alone.
//
// Why it is needed: D5's checker fired on the GOLDEN before the testbench's own
// responder was repaired, which is evidence the checker works but is not a
// recorded control (rule 24). And the obvious candidate is not one -- `iw_c3`
// before its repair withdraws a valid going INTO the design, and that fails C2
// twenty times, because the design's accounting diverges from the testbench's.
// D5 binds the design's OUTPUTS, so a control for it has to withdraw one.
//
// IT WITHDRAWS ONLY WHERE THE TRANSFER COULD NOT HAVE HAPPENED. `drop` asserts
// only on a cycle when `m_arready` is already low, so no handshake is lost and
// the wrapped design sees a bit-identical environment -- its ready is passed
// through untouched. The only observable difference is that `m_arvalid` falls
// while its ready is low, which is precisely and solely what D5 forbids.
//
// A first version gated the design's ready too, to avoid a phantom handshake,
// AND was built by copying iw_c3's instantiation -- which binds `g_awvalid` and
// `g_arvalid`, signals that do not exist here. It hung the A4 phase and reported
// A3, A4 and A5. The control was measuring itself. A control whose blast radius
// exceeds the clause it is for cannot license a claim about that clause, and a
// control assembled by copying a neighbour inherits the neighbour's wiring.
//
// It deliberately violates D5's second sentence as well -- `m_arvalid` here IS
// combinational on `m_arready`. That is a property of the control, not of the
// clause; the testbench's readies are LFSR-driven and read no design output, so
// no combinational loop is closed.
module iw_nc_d5_withdraws_ar #(
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
  logic g_m_arvalid;
  logic [1:0] cnt;
  always_ff @(posedge clk_i)
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

  // DID IT FIRE? A verdict says what happened; this says whether anything was
  // asked. The first version of this control PASSED because its trigger never
  // occurred, and a pass and a no-op are indistinguishable without this line.
  // Convention: `FIRED <name> <count>`, checked by check_fired.py, which
  // REFUSES on zero.
  int n_drop = 0;
  always @(posedge clk_i) if (rst_ni && drop) n_drop <= n_drop + 1;
  final $display("FIRED nc_d5_withdraws_ar.drop %0d", n_drop);

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
      .s_rvalid   (s_rvalid),
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
