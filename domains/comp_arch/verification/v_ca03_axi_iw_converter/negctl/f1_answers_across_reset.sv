// F1(c) NEGATIVE CONTROL for v_ca03 -- it MUST FAIL, and on F1 alone.
//
// F1(c) is the half that says no transaction outstanding before a reset produces
// a response after it. Until the F1(c) phase existed no stimulus reached it at
// all, and the checker was only ever demonstrated by ACCIDENT: the testbench's
// own downstream responder was not cleared on reset, so it kept answering and the
// design forwarded it. That demonstrated the checker fires. It is not a control:
// the cause was a defect in the harness, not a design violating the clause.
//
//
// DIFFERENTIAL, and it is stronger than the FIRED counter beside it. Build this
// file with the perturbation replaced by a constant 0 and the run must PASS.
// That makes the perturbation NECESSARY for the failure rather than merely
// present during it -- which a FIRED counter cannot establish, and which is
// exactly the gap that let two earlier versions of the F1(a) control fail on D5
// while their own counter read healthy. Proposed by the design half; measured
// here:
//     with the perturbation     FAIL, F1 only, 1 failure, force 2
//     with it replaced by 1'b0  PASS
// WHAT THIS PERTURBS: exactly one write response, carried across the reset. The
// wrapper latches the id of a B response in flight when rst_ni falls and presents
// it once after release. Nothing else is touched.
//
// WHY IT CANNOT FIRE ON THE INITIAL RESET, which is the trap that would make it
// die on the wrong clause: nothing has been offered before the first release, so
// the arming condition is never met there. If it did fire, surv_win would be 0,
// F1(c)'s branch would not be taken, and the response would land on C2 -- which
// is the exact confusion the precedence at the site exists to prevent.
module iw_nc_f1_answers_across_reset #(
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
  // REFUSES on zero. s_rvalid is forced high for every cycle rst_ni is
  // low; at every other time the design's own output passes through untouched.
  //
  // D5 cannot see this: D5's `pv` is cleared while rst_ni is low and updated
  // only in the else branch, so a valid confined to the reset window never
  // sets it. Measured -- 8 F1 failures and 0 of anything else.
  // THE ONLY PERTURBATION: one write response is carried ACROSS a reset.
  //
  // `armed` remembers that a B response was in flight when rst_ni fell, and the
  // id it carried. After release the wrapper presents that id once. The design
  // itself is untouched -- its own s_bvalid passes through at every other time.
  //
  // IT CANNOT FIRE ON THE INITIAL RESET. Nothing has been offered before the
  // first release, so `armed` is low and the wrapper is transparent. That
  // matters: at the initial release surv_win is 0, F1(c)'s branch would not be
  // taken, and the forced response would land on C2 instead -- a control that
  // dies on the wrong clause.
  logic g_s_bvalid;
  logic [SLV_ID_W-1:0] g_s_bid;
  logic armed = 1'b0, fired = 1'b0;
  logic [SLV_ID_W-1:0] held_id = '0;
  // ARMING HAS TO HAPPEN BEFORE THE RESET EDGE, NOT ON IT. A first version armed
  // on `!rst_ni && g_s_bvalid` and fired ZERO times: the design's reset is
  // synchronous, so s_bvalid is already low by the cycle !rst_ni is sampled --
  // there was nothing to latch. `seen_b` instead records, during normal running,
  // that write responses flow at all: false before the first release, true by the
  // time the F1(c) phase drops reset.
  logic seen_b = 1'b0;
  always_ff @(posedge clk_i) begin
    if (!rst_ni) begin
      armed <= seen_b;
      fired <= 1'b0;
    end else begin
      if (g_s_bvalid) begin seen_b <= 1'b1; held_id <= g_s_bid; end
      // HOLD THE OFFER UNTIL ITS READY IS SEEN. A version that pulsed for one
      // cycle produced a D5 failure and no F1 one: D5 forbids withdrawing a
      // valid without a handshake, and the slave-side checker only evaluates on
      // `s_bvalid && s_bready`, so a pulse that missed ready was a withdrawal
      // the checker never got to read. Holding makes the transfer happen, which
      // is what the clause is about anyway -- a response DELIVERED across a
      // reset, not one merely offered.
      if (armed && !fired && s_bready) begin
        fired <= 1'b1;
        armed <= 1'b0;
      end
    end
  end
  wire force_b = rst_ni && armed && !fired;
  assign s_bvalid = force_b ? 1'b1     : g_s_bvalid;
  assign s_bid    = force_b ? held_id  : g_s_bid;
  int n_force = 0;
  always @(posedge clk_i) if (force_b) n_force <= n_force + 1;
  final $display("FIRED nc_f1_answers_across_reset.force %0d", n_force);

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
      .s_bid      (g_s_bid),
      .s_bresp    (s_bresp),
      .s_bvalid   (g_s_bvalid),
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
