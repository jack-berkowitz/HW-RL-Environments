// Non-equivalence witness harness -- rule 16. Scoring support, never shipped.
//
// Drives the golden and ONE mutant from a SHARED input sequence and compares
// the ENTIRE output vector of both, every cycle. It does not compare a chosen
// subset: a harness that watches only the fields it expects to move reports
// "no difference observed" for a mutant that changes something else, and that
// reassuring answer is a statement about the harness, not the mutant.
//
// The driver advances an input beat only when BOTH sides have accepted it, so
// the two see an identical input sequence. Any difference in ready timing is
// therefore itself a witness, which is what the two bound mutants need.
//
// Build once per mutant:  -DMUT_MOD=af_mN_...
`ifndef MUT_MOD
  `define MUT_MOD af_m1_budget_off_by_one
`endif

module nonequiv_tb;
  localparam int unsigned BDELAY = 12;   // downstream B lag, so W4 is observable

  logic clk = 1'b0, rst_n = 1'b0;
  always #5 clk = ~clk;

  // ---- shared stimulus (inputs to both sides) ----
  logic [3:0]  awid;  logic [31:0] awaddr; logic [7:0] awlen;  logic [5:0] awatop;
  logic        awvalid;
  logic [31:0] wdata; logic [3:0]  wstrb;  logic        wlast; logic wvalid;
  logic [3:0]  arid;  logic [31:0] araddr; logic [7:0] arlen;  logic arvalid;
  logic        bready, rready;

  `define SIGS(p) \
    logic p``_awready, p``_wready, p``_arready; \
    logic [3:0] p``_bid; logic [1:0] p``_bresp; logic p``_buser, p``_bvalid; \
    logic [3:0] p``_rid; logic [31:0] p``_rdata; logic [1:0] p``_rresp; \
    logic p``_rlast, p``_ruser, p``_rvalid; \
    logic [3:0] p``_mawid; logic [31:0] p``_mawaddr; logic [7:0] p``_mawlen; \
    logic [2:0] p``_mawsize; logic [1:0] p``_mawburst; logic p``_mawlock; \
    logic [3:0] p``_mawcache; logic [2:0] p``_mawprot; logic [3:0] p``_mawqos, p``_mawregion; \
    logic [5:0] p``_mawatop; logic p``_mawuser, p``_mawvalid; \
    logic [31:0] p``_mwdata; logic [3:0] p``_mwstrb; logic p``_mwlast, p``_mwuser, p``_mwvalid; \
    logic p``_mbready; \
    logic [3:0] p``_marid; logic [31:0] p``_maraddr; logic [7:0] p``_marlen; \
    logic [2:0] p``_marsize; logic [1:0] p``_marburst; logic p``_marlock; \
    logic [3:0] p``_marcache; logic [2:0] p``_marprot; logic [3:0] p``_marqos, p``_marregion; \
    logic p``_maruser, p``_marvalid, p``_mrready; \
    logic p``_mawready, p``_mwready, p``_marready; \
    logic [3:0] p``_mbid; logic [1:0] p``_mbresp; logic p``_mbuser, p``_mbvalid; \
    logic [3:0] p``_mrid; logic [31:0] p``_mrdata; logic [1:0] p``_mrresp; \
    logic p``_mrlast, p``_mruser, p``_mrvalid;

  `SIGS(g)
  `SIGS(m)

  `define CONN(p) \
    .clk_i(clk), .rst_ni(rst_n), \
    .s_awid_i(awid), .s_awaddr_i(awaddr), .s_awlen_i(awlen), .s_awsize_i(3'd2), \
    .s_awburst_i(2'd1), .s_awlock_i(1'b0), .s_awcache_i(4'd0), .s_awprot_i(3'd0), \
    .s_awqos_i(4'd0), .s_awregion_i(4'd0), .s_awatop_i(awatop), .s_awuser_i(1'b0), \
    .s_awvalid_i(awvalid), .s_awready_o(p``_awready), \
    .s_wdata_i(wdata), .s_wstrb_i(wstrb), .s_wlast_i(wlast), .s_wuser_i(1'b0), \
    .s_wvalid_i(wvalid), .s_wready_o(p``_wready), \
    .s_bid_o(p``_bid), .s_bresp_o(p``_bresp), .s_buser_o(p``_buser), \
    .s_bvalid_o(p``_bvalid), .s_bready_i(bready), \
    .s_arid_i(arid), .s_araddr_i(araddr), .s_arlen_i(arlen), .s_arsize_i(3'd2), \
    .s_arburst_i(2'd1), .s_arlock_i(1'b0), .s_arcache_i(4'd0), .s_arprot_i(3'd0), \
    .s_arqos_i(4'd0), .s_arregion_i(4'd0), .s_aruser_i(1'b0), \
    .s_arvalid_i(arvalid), .s_arready_o(p``_arready), \
    .s_rid_o(p``_rid), .s_rdata_o(p``_rdata), .s_rresp_o(p``_rresp), \
    .s_rlast_o(p``_rlast), .s_ruser_o(p``_ruser), .s_rvalid_o(p``_rvalid), \
    .s_rready_i(rready), \
    .m_awid_o(p``_mawid), .m_awaddr_o(p``_mawaddr), .m_awlen_o(p``_mawlen), \
    .m_awsize_o(p``_mawsize), .m_awburst_o(p``_mawburst), .m_awlock_o(p``_mawlock), \
    .m_awcache_o(p``_mawcache), .m_awprot_o(p``_mawprot), .m_awqos_o(p``_mawqos), \
    .m_awregion_o(p``_mawregion), .m_awatop_o(p``_mawatop), .m_awuser_o(p``_mawuser), \
    .m_awvalid_o(p``_mawvalid), .m_awready_i(p``_mawready), \
    .m_wdata_o(p``_mwdata), .m_wstrb_o(p``_mwstrb), .m_wlast_o(p``_mwlast), \
    .m_wuser_o(p``_mwuser), .m_wvalid_o(p``_mwvalid), .m_wready_i(p``_mwready), \
    .m_bid_i(p``_mbid), .m_bresp_i(p``_mbresp), .m_buser_i(p``_mbuser), \
    .m_bvalid_i(p``_mbvalid), .m_bready_o(p``_mbready), \
    .m_arid_o(p``_marid), .m_araddr_o(p``_maraddr), .m_arlen_o(p``_marlen), \
    .m_arsize_o(p``_marsize), .m_arburst_o(p``_marburst), .m_arlock_o(p``_marlock), \
    .m_arcache_o(p``_marcache), .m_arprot_o(p``_marprot), .m_arqos_o(p``_marqos), \
    .m_arregion_o(p``_marregion), .m_aruser_o(p``_maruser), \
    .m_arvalid_o(p``_marvalid), .m_arready_i(p``_marready), \
    .m_rid_i(p``_mrid), .m_rdata_i(p``_mrdata), .m_rresp_i(p``_mrresp), \
    .m_rlast_i(p``_mrlast), .m_ruser_i(p``_mruser), .m_rvalid_i(p``_mrvalid), \
    .m_rready_o(p``_mrready)

  atop_filter  #(.ID_W(4), .ADDR_W(32), .DATA_W(32), .USER_W(1)) i_g (`CONN(g));
  `MUT_MOD     #(.ID_W(4), .ADDR_W(32), .DATA_W(32), .USER_W(1)) i_m (`CONN(m));

  // ---- downstream responder, one per side ------------------------------------
  // Accepts AW and W immediately; returns B a fixed lag AFTER the AW, so that a
  // debt freed by a B is distinguishable from a debt freed by a W burst.
  `define RESP(p) \
    assign p``_mawready = 1'b1; \
    assign p``_mwready  = 1'b1; \
    assign p``_marready = 1'b1; \
    int p``_bq_id [$]; int p``_bq_t [$]; int p``_rq_id [$]; int p``_rq_n [$]; \
    always @(posedge clk) if (rst_n) begin \
      if (p``_mawvalid && p``_mawready) begin p``_bq_id.push_back(int'(p``_mawid)); \
                                              p``_bq_t.push_back(cyc + BDELAY); end \
      if (p``_marvalid && p``_marready) begin p``_rq_id.push_back(int'(p``_marid)); \
                                              p``_rq_n.push_back(int'(p``_marlen) + 1); end \
      if (p``_mbvalid && p``_mbready) begin void'(p``_bq_id.pop_front()); void'(p``_bq_t.pop_front()); end \
      if (p``_mrvalid && p``_mrready) begin \
        if (p``_rq_n[0] <= 1) begin void'(p``_rq_id.pop_front()); void'(p``_rq_n.pop_front()); end \
        else p``_rq_n[0] = p``_rq_n[0] - 1; \
      end \
    end \
    always_comb begin \
      p``_mbvalid = (p``_bq_id.size() > 0) && (cyc >= p``_bq_t[0]); \
      p``_mbid = 4'(p``_bq_id.size() ? p``_bq_id[0] : 0); p``_mbresp = 2'b00; p``_mbuser = 1'b0; \
      p``_mrvalid = (p``_rq_id.size() > 0); \
      p``_mrid = 4'(p``_rq_id.size() ? p``_rq_id[0] : 0); \
      p``_mrdata = 32'hA0A0_0000 ^ 32'(p``_rq_id.size()); p``_mrresp = 2'b00; \
      p``_mrlast = (p``_rq_id.size() > 0) && (p``_rq_n[0] <= 1); p``_mruser = 1'b0; \
    end

  int cyc = 0;
  always @(posedge clk) if (rst_n) cyc <= cyc + 1;
  `RESP(g)
  `RESP(m)

  // ---- the observable output vector, both sides -------------------------------
  // Each channel's PAYLOAD is masked by its own valid. An AXI payload while
  // valid is low is not observable by anything, and comparing it raw reports a
  // difference no testbench could legitimately see: one mutant perturbs an AW
  // field that is never asserted valid, and unmasked this harness "witnessed"
  // that instead of the missing R beat it actually causes.
  `define VEC(p) { p``_awready, p``_wready, p``_arready, p``_mbready, p``_mrready, \
      p``_bvalid, (p``_bvalid ? {p``_bid, p``_bresp, p``_buser} : 7'd0), \
      p``_rvalid, (p``_rvalid ? {p``_rid, p``_rdata, p``_rresp, p``_rlast, p``_ruser} : 40'd0), \
      p``_mawvalid, (p``_mawvalid ? {p``_mawid, p``_mawaddr, p``_mawlen, p``_mawsize, \
        p``_mawburst, p``_mawlock, p``_mawcache, p``_mawprot, p``_mawqos, p``_mawregion, \
        p``_mawatop, p``_mawuser} : 68'd0), \
      p``_mwvalid, (p``_mwvalid ? {p``_mwdata, p``_mwstrb, p``_mwlast, p``_mwuser} : 38'd0), \
      p``_marvalid, (p``_marvalid ? {p``_marid, p``_maraddr, p``_marlen, p``_marsize, \
        p``_marburst, p``_marlock, p``_marcache, p``_marprot, p``_marqos, p``_marregion, \
        p``_maruser} : 62'd0) }

  int  diff_cyc = -1;
  string diff_what = "";
  always @(posedge clk) if (rst_n && diff_cyc < 0) begin
    if (`VEC(g) !== `VEC(m)) begin
      diff_cyc = cyc;
      if (g_awready !== m_awready) diff_what = "s_awready (the write-admission bound)";
      else if (g_wready !== m_wready) diff_what = "s_wready";
      else if (g_bvalid !== m_bvalid || g_bid !== m_bid || g_bresp !== m_bresp)
        diff_what = $sformatf("slave B: golden valid=%b id=%0d resp=%b / mutant valid=%b id=%0d resp=%b",
                              g_bvalid, g_bid, g_bresp, m_bvalid, m_bid, m_bresp);
      else if (g_rvalid !== m_rvalid || g_rid !== m_rid || g_rresp !== m_rresp || g_rlast !== m_rlast)
        diff_what = $sformatf("slave R: golden valid=%b id=%0d resp=%b last=%b / mutant valid=%b id=%0d resp=%b last=%b",
                              g_rvalid, g_rid, g_rresp, g_rlast, m_rvalid, m_rid, m_rresp, m_rlast);
      else if (g_mawvalid !== m_mawvalid || (g_mawvalid && g_mawatop !== m_mawatop))
        diff_what = $sformatf("master AW: golden valid=%b atop=%b / mutant valid=%b atop=%b",
                              g_mawvalid, g_mawatop, m_mawvalid, m_mawatop);
      else if (g_mwvalid !== m_mwvalid || (g_mwvalid && (g_mwdata !== m_mwdata || g_mwlast !== m_mwlast)))
        diff_what = $sformatf("master W: golden valid=%b data=%08x last=%b / mutant valid=%b data=%08x last=%b",
                              g_mwvalid, g_mwdata, g_mwlast, m_mwvalid, m_mwdata, m_mwlast);
      else if (g_mrready !== m_mrready)
        diff_what = $sformatf("m_rready: golden %b / mutant %b -- one side is still injecting R beats while the other has finished",
                              g_mrready, m_mrready);
      else if ((g_rvalid && g_rdata !== m_rdata) || (g_rvalid && g_ruser !== m_ruser) || (g_bvalid && g_buser !== m_buser))
        diff_what = "a manufactured-response field that clause L2 leaves unconstrained";
      else if (g_mbready !== m_mbready)
        diff_what = $sformatf("m_bready: golden %b / mutant %b", g_mbready, m_mbready);
      else diff_what = "some other output bit";
    end
  end

  // ---- shared stimulus: advance only when BOTH sides accept -------------------
  task automatic do_aw(input logic [3:0] id, input logic [7:0] len, input logic [5:0] atop);
    @(negedge clk); awid=id; awaddr=32'h1000; awlen=len; awatop=atop; awvalid=1'b1;
    forever begin @(posedge clk); if (g_awready && m_awready) break; end
    @(negedge clk) awvalid=1'b0;
  endtask
  task automatic do_w(input int n);
    for (int i=0;i<n;i++) begin
      @(negedge clk); wdata=32'hD000_0000 + i; wstrb=4'hF; wlast=(i==n-1); wvalid=1'b1;
      forever begin @(posedge clk); if (g_wready && m_wready) break; end
      @(negedge clk) wvalid=1'b0;
    end
  endtask
  task automatic do_ar(input logic [3:0] id, input logic [7:0] len);
    @(negedge clk); arid=id; araddr=32'h2000; arlen=len; arvalid=1'b1;
    forever begin @(posedge clk); if (g_arready && m_arready) break; end
    @(negedge clk) arvalid=1'b0;
  endtask

  initial begin
    awid=0; awaddr=0; awlen=0; awatop=0; awvalid=0;
    wdata=0; wstrb=4'hF; wlast=0; wvalid=0;
    arid=0; araddr=0; arlen=0; arvalid=0; bready=1; rready=1;
    repeat (4) @(posedge clk); @(negedge clk) rst_n = 1'b1; repeat (2) @(posedge clk);

    // 1. ordinary write, then an atomic store, then an atomic load, len 0 and 3
    do_aw(4'd1, 8'd0, 6'b000000); do_w(1); repeat (4) @(posedge clk);
    do_aw(4'd2, 8'd0, 6'b010000); do_w(1); repeat (20) @(posedge clk);
    do_aw(4'd3, 8'd0, 6'b100000); do_w(1); repeat (20) @(posedge clk);
    do_aw(4'd4, 8'd3, 6'b100000); do_w(4); repeat (25) @(posedge clk);
    // 2. two atomic loads with DIFFERENT ids, back to back
    do_aw(4'd9, 8'd1, 6'b100000); do_w(2); repeat (20) @(posedge clk);
    do_aw(4'd5, 8'd1, 6'b100000); do_w(2); repeat (20) @(posedge clk);
    // 3. fill the write budget: AWs with the W bursts withheld
    for (int i=0;i<6;i++) do_aw(4'(i), 8'd0, 6'b000000);
    repeat (10) @(posedge clk);
    for (int i=0;i<6;i++) do_w(1);
    repeat (30) @(posedge clk);
    // 4. a read passing through, and an atomic load with a read in flight
    do_ar(4'd7, 8'd1); repeat (8) @(posedge clk);
    do_aw(4'd8, 8'd2, 6'b110000); do_w(3); repeat (30) @(posedge clk);

    if (diff_cyc >= 0)
      $display("WITNESS %s: first difference at cycle %0d -- %s", `"`MUT_MOD`", diff_cyc, diff_what);
    else
      $display("WITNESS %s: NO DIFFERENCE OBSERVED -- treat the HARNESS as suspect, not the mutant", `"`MUT_MOD`");
    $finish;
  end
  // Once the two sides differ they are no longer driven in lockstep -- the
  // shared driver waits for BOTH to accept, and after a divergence in ready
  // timing that may never happen again. Report and stop rather than deadlock.
  initial begin
    wait (diff_cyc >= 0);
    repeat (4) @(posedge clk);
    $display("WITNESS %s: first difference at cycle %0d -- %s", `"`MUT_MOD`", diff_cyc, diff_what);
    $finish;
  end
  initial begin #500000;
    $display("WITNESS %s: watchdog with diff_cyc=%0d -- %s", `"`MUT_MOD`", diff_cyc,
             (diff_cyc >= 0) ? diff_what : "NO DIFFERENCE OBSERVED, treat the HARNESS as suspect");
    $finish; end
endmodule
