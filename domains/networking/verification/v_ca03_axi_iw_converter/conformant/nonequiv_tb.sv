// =============================================================================
// nonequiv_tb.sv -- NON-EQUIVALENCE WITNESSES for the conformant set.
// =============================================================================
// A perturbation that is secretly a no-op survives and reports the reassuring
// answer, which is worse than having no control at all. On this task that risk
// is sharper than usual: most of the latitude is ALLOCATION POLICY, and a
// policy change the table cannot express is invisible.
//
// Method: golden and perturbation are driven by INDEPENDENT drivers walking the
// SAME deterministic id sequence, so each advances on its own ready and the two
// still see identical request streams. Captured on transfer edges, never polled.
//
//   $ verilator ... --top-module iw_ne -GVARIANT=n
// =============================================================================
module iw_ne #(parameter int VARIANT = 1);
  localparam int SLV=4, MST=2, MAXU=4, MAXT=2, NREQ=40;
  logic clk=0, rst_n=0; always #5 clk=~clk;

  function automatic logic [3:0] seq_id(input int n); return 4'((n*5+1) % 6); endfunction

  int gn=0, an=0, cyc=0;
  logic [3:0] g_arid_s, a_arid_s;
  assign g_arid_s = seq_id(gn);
  assign a_arid_s = seq_id(an);
  logic g_arvalid, a_arvalid;
  assign g_arvalid = (gn < NREQ) && rst_n;
  assign a_arvalid = (an < NREQ) && rst_n;

  logic g_arready,a_arready, g_awready,a_awready, g_wready,a_wready;
  logic [3:0] g_rid,a_rid,g_bid,a_bid; logic [31:0] g_rdata,a_rdata;
  logic [1:0] g_rresp,a_rresp,g_bresp,a_bresp;
  logic g_rlast,a_rlast,g_rvalid,a_rvalid,g_bvalid,a_bvalid;
  logic [1:0] g_marid,a_marid,g_mawid,a_mawid;
  logic [31:0] g_maraddr,a_maraddr,g_mawaddr,a_mawaddr,g_mwdata,a_mwdata;
  logic [7:0] g_marlen,a_marlen,g_mawlen,a_mawlen;
  logic [3:0] g_mwstrb,a_mwstrb;
  logic g_marvalid,a_marvalid,g_mawvalid,a_mawvalid,g_mwvalid,a_mwvalid,g_mwlast,a_mwlast;
  logic g_mbready,a_mbready,g_mrready,a_mrready;
  logic [1:0] gmr_id=0, amr_id=0; logic gmr_v=0, amr_v=0;
  logic reply=0;

  `define PORTS(P,VD,RD,MARID,MARV) \
    .clk_i(clk), .rst_ni(rst_n), \
    .s_awid(VD), .s_awaddr({28'h200, VD}), .s_awlen(8'd0), .s_awvalid(RD), .s_awready(P``_awready), \
    .s_wdata(32'd0), .s_wstrb(4'd0), .s_wlast(1'b0), .s_wvalid(1'b0), .s_wready(P``_wready), \
    .s_bid(P``_bid), .s_bresp(P``_bresp), .s_bvalid(P``_bvalid), .s_bready(1'b1), \
    .s_arid(VD), .s_araddr({28'h100, VD}), .s_arlen(8'd0), .s_arvalid(RD), .s_arready(P``_arready), \
    .s_rid(P``_rid), .s_rdata(P``_rdata), .s_rresp(P``_rresp), .s_rlast(P``_rlast), \
    .s_rvalid(P``_rvalid), .s_rready(1'b1), \
    .m_awid(P``_mawid), .m_awaddr(P``_mawaddr), .m_awlen(P``_mawlen), \
    .m_awvalid(P``_mawvalid), .m_awready(1'b1), \
    .m_wdata(P``_mwdata), .m_wstrb(P``_mwstrb), .m_wlast(P``_mwlast), \
    .m_wvalid(P``_mwvalid), .m_wready(1'b1), \
    .m_bid(2'd0), .m_bresp(2'd0), .m_bvalid(1'b0), .m_bready(P``_mbready), \
    .m_arid(MARID), .m_araddr(P``_maraddr), .m_arlen(P``_marlen), \
    .m_arvalid(MARV), .m_arready(1'b1), \
    .m_rid(P``mr_id_w), .m_rdata(32'hBEEF0000), .m_rresp(2'd0), .m_rlast(1'b1), \
    .m_rvalid(P``mr_v_w), .m_rready(P``_mrready)

  wire [1:0] gmr_id_w = gmr_id; wire gmr_v_w = gmr_v;
  wire [1:0] amr_id_w = amr_id; wire amr_v_w = amr_v;

  id_width_conv #(.SLV_ID_W(SLV),.MST_ID_W(MST),.MAX_UNIQ_IDS(MAXU),.MAX_TXNS_PER_ID(MAXT))
    G (`PORTS(g, g_arid_s, g_arvalid, g_marid, g_marvalid));

  generate
    case (VARIANT)
      1: iw_c1_permuted_allocation  #(.SLV_ID_W(SLV),.MST_ID_W(MST),.MAX_UNIQ_IDS(MAXU),.MAX_TXNS_PER_ID(MAXT)) A (`PORTS(a, a_arid_s, a_arvalid, a_marid, a_marvalid));
      2: iw_c2_extra_latency        #(.SLV_ID_W(SLV),.MST_ID_W(MST),.MAX_UNIQ_IDS(MAXU),.MAX_TXNS_PER_ID(MAXT)) A (`PORTS(a, a_arid_s, a_arvalid, a_marid, a_marvalid));
      3: iw_c3_ready_withheld       #(.SLV_ID_W(SLV),.MST_ID_W(MST),.MAX_UNIQ_IDS(MAXU),.MAX_TXNS_PER_ID(MAXT)) A (`PORTS(a, a_arid_s, a_arvalid, a_marid, a_marvalid));
      4: iw_c4_garbage_when_invalid #(.SLV_ID_W(SLV),.MST_ID_W(MST),.MAX_UNIQ_IDS(MAXU),.MAX_TXNS_PER_ID(MAXT)) A (`PORTS(a, a_arid_s, a_arvalid, a_marid, a_marvalid));
      5: iw_c5_channel_arbitration  #(.SLV_ID_W(SLV),.MST_ID_W(MST),.MAX_UNIQ_IDS(MAXU),.MAX_TXNS_PER_ID(MAXT)) A (`PORTS(a, a_arid_s, a_arvalid, a_marid, a_marvalid));
      default: initial $fatal(1,"no such VARIANT");
    endcase
  endgenerate

  // master-side read slave, common queue per instance
  logic [1:0] gq [$], aq [$];
  always @(posedge clk) if (rst_n) begin
    cyc++;
    if (g_marvalid) gq.push_back(g_marid);
    if (a_marvalid) aq.push_back(a_marid);
  end
  always_comb begin gmr_id = (gq.size()>0)? gq[0]:2'd0; gmr_v = reply && (gq.size()>0); end
  always_comb begin amr_id = (aq.size()>0)? aq[0]:2'd0; amr_v = reply && (aq.size()>0); end
  always @(posedge clk) if (rst_n) begin
    if (gmr_v && g_mrready) void'(gq.pop_front());
    if (amr_v && a_mrready) void'(aq.pop_front());
  end

  int mid_diff=0, acc_diff=0, mt_diff=0, idle_g=0, idle_a=0, n_cmp=0;
  logic [1:0] gmid [$], amid [$]; int gacc [$], aacc [$];
  int gmt [$], amt [$];   // cycle each MASTER request is issued -- what latency moves
  logic [31:0] gprev, aprev;
  always @(posedge clk) if (rst_n) begin
    if (g_arvalid && g_arready) begin gn <= gn+1; gacc.push_back(cyc); end
    if (a_arvalid && a_arready) begin an <= an+1; aacc.push_back(cyc); end
    if (g_marvalid) begin gmid.push_back(g_marid); gmt.push_back(cyc); end
    if (a_marvalid) begin amid.push_back(a_marid); amt.push_back(cyc); end
    if (!g_marvalid) begin if (g_maraddr !== gprev) idle_g++; gprev <= g_maraddr; end
    if (!a_marvalid) begin if (a_maraddr !== aprev) idle_a++; aprev <= a_maraddr; end
  end

  initial begin
    repeat(4)@(posedge clk); @(negedge clk) rst_n=1;
    fork
      begin forever begin repeat(6)@(posedge clk); reply=1; repeat(4)@(posedge clk); reply=0; end end
      begin while (gn<NREQ || an<NREQ) @(posedge clk); repeat(80)@(posedge clk); end
    join_any
    disable fork;
    begin
      automatic int n = (gmid.size()<amid.size())? gmid.size():amid.size();
      automatic int na = (gacc.size()<aacc.size())? gacc.size():aacc.size();
      automatic int fv=-1, ft=-1, fm=-1;
      automatic int nm = (gmt.size()<amt.size())? gmt.size():amt.size();
      for (int i=0;i<n;i++) if (gmid[i]!==amid[i]) begin if(fv<0) fv=i; mid_diff++; end
      for (int i=0;i<na;i++) if (gacc[i]!==aacc[i]) begin if(ft<0) ft=i; acc_diff++; end
      for (int i=0;i<nm;i++) if (gmt[i]!==amt[i]) begin if(fm<0) fm=i; mt_diff++; end
      $display("VARIANT %0d", VARIANT);
      $display("  master requests compared : %0d", n);
      if (fv>=0) $display("  WITNESS master id  @%0d : golden=%0d perturbation=%0d (%0d differ)",
                          fv, gmid[fv], amid[fv], mid_diff);
      else       $display("  master ids identical over %0d requests", n);
      if (ft>=0) $display("  WITNESS acceptance @%0d : golden cycle %0d, perturbation %0d (%0d differ)",
                          ft, gacc[ft], aacc[ft], acc_diff);
      else       $display("  acceptance cycles identical over %0d requests", na);
      if (fm>=0) $display("  WITNESS master timing @%0d : golden cycle %0d, perturbation %0d (%0d differ)",
                          fm, gmt[fm], amt[fm], mt_diff);
      else       $display("  master request cycles identical over %0d requests", nm);
      $display("  idle-line changes        : golden=%0d perturbation=%0d", idle_g, idle_a);
      if (mid_diff>0 || acc_diff>0 || mt_diff>0 || idle_g!==idle_a)
        $display("  NON-EQUIVALENCE ESTABLISHED");
      else
        $display("  *** NO DIFFERENCE OBSERVED -- this perturbation may be a no-op ***");
    end
    $finish;
  end
  initial begin #1_000_000; $display("  watchdog"); $finish; end
endmodule
