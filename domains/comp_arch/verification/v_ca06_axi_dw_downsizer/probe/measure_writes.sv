`ifndef DUT_MOD
  `define DUT_MOD dw_downsizer
`endif
// STEP 1 -- write path, measured not read.
module dw_wprobe;
  localparam int SW=64, MW=16;
  logic clk=0, rst_n=0; always #5 clk=~clk;
  logic [3:0] s_awid=0,s_arid=0,s_bid,s_rid,m_awid,m_arid,m_rid=0;
  logic [31:0] s_awaddr=0,s_araddr=0,m_awaddr,m_araddr;
  logic [7:0] s_awlen=0,s_arlen=0,m_awlen,m_arlen;
  logic [2:0] s_awsize=0,s_arsize=0,m_awsize,m_arsize;
  logic [1:0] s_awburst=1,s_arburst=1,m_awburst,m_arburst,s_bresp,s_rresp,m_rresp=0;
  logic [1:0] m_bresp_drv=0;
  logic s_awvalid=0,s_awready,s_wvalid=0,s_wready,s_wlast=0,s_bvalid,s_bready=1;
  logic s_arvalid=0,s_arready,s_rlast,s_rvalid,s_rready=1;
  logic m_awvalid,m_awready=1,m_wvalid,m_wready=1,m_wlast,m_bready;
  logic m_arvalid,m_arready=1,m_rlast=0,m_rvalid=0,m_rready;
  logic [SW-1:0] s_wdata=0,s_rdata; logic [SW/8-1:0] s_wstrb=0;
  logic [MW-1:0] m_wdata,m_rdata=0; logic [MW/8-1:0] m_wstrb;
  logic [3:0] m_bid_drv=0; logic m_bvalid_drv=0;
  wire [3:0] m_bid = m_bid_drv; wire [1:0] m_bresp = m_bresp_drv; wire m_bvalid = m_bvalid_drv;

  `DUT_MOD dut(.clk_i(clk), .rst_ni(rst_n), .*);

  // ---- downstream slave: log W beats, return one B per completed W burst ----
  int    n_aw, n_wbeat, n_dsb; string wlog; int aw_id_q[$]; int pend_b;
  logic [7:0] m_awlen_q; logic [2:0] m_awsize_q; logic [31:0] m_awaddr_q; logic [1:0] m_awburst_q;
  // ONE ordered block. For a len=0 downstream burst the AW handshake and the
  // final W beat can land in the SAME cycle; with the capture and the wlast
  // test in two separate always blocks, whether aw_id_q was non-empty came
  // down to scheduling order -- so no B was ever returned and the DUT looked
  // like it withholds B on single-beat size-1 writes. It does not.
  always @(posedge clk) if (rst_n) begin
    if (m_awvalid && m_awready) begin
      n_aw<=n_aw+1; m_awlen_q<=m_awlen; m_awsize_q<=m_awsize;
      m_awaddr_q<=m_awaddr; m_awburst_q<=m_awburst; aw_id_q.push_back(m_awid);
    end
    if (m_wvalid && m_wready) begin
      n_wbeat <= n_wbeat + 1;
      wlog = {wlog, $sformatf("%04x/%02b%s ", m_wdata, m_wstrb, m_wlast?"L":"")};
      if (m_wlast) pend_b <= pend_b + 1;
    end
    // B driver lives HERE, in the same ordered block: pend_b written by one
    // always block and read by another is a race, and for a len=0 burst the
    // increment and the read land in the same cycle.
    if (m_bvalid_drv && m_bready) begin
      m_bvalid_drv <= 0; n_dsb <= n_dsb + 1;
      if (aw_id_q.size()>0) void'(aw_id_q.pop_front());
    end else if (!m_bvalid_drv && (pend_b>0)) begin
      m_bvalid_drv <= 1; m_bresp_drv <= 2'b00;
      m_bid_drv <= (aw_id_q.size()>0) ? 4'(aw_id_q[0]) : '0;
      pend_b <= pend_b - 1;
    end
  end

  task automatic probe_write(input string label, input int id, input logic [31:0] a,
                             input int len, input int size, input logic [1:0] burst,
                             input logic [7:0] strb);
    int t; int got_b; logic [1:0] bresp;
    @(negedge clk) rst_n=0; aw_id_q.delete(); n_aw=0; n_wbeat=0; n_dsb=0; wlog=""; pend_b=0;
    repeat(3) @(posedge clk); @(negedge clk) rst_n=1; repeat(2) @(posedge clk);
    @(negedge clk); s_awid=4'(id); s_awaddr=a; s_awlen=8'(len); s_awsize=3'(size);
                    s_awburst=burst; s_awvalid=1;
    for (t=0;t<400;t++) begin @(posedge clk); if (s_awready) break; end
    @(negedge clk) s_awvalid=0;
    if (t>=40) begin $display("  %-34s AW NOT ACCEPTED", label); return; end
    // drive len+1 upstream beats; byte i of beat k = (k<<4)|i
    for (int k=0;k<=len;k++) begin
      @(negedge clk);
      for (int i=0;i<8;i++) s_wdata[8*i +: 8] = 8'((k<<4)|i);
      s_wstrb=strb; s_wlast=(k==len); s_wvalid=1;
      for (t=0;t<2000;t++) begin @(posedge clk); if (s_wready) break; end
    end
    @(negedge clk) s_wvalid=0; s_wlast=0;
    got_b=0;
    for (t=0;t<6000;t++) begin
      @(posedge clk);
      if (s_bvalid && s_bready) begin got_b=1; bresp=s_bresp; break; end
    end
    $display("  %-34s dsAW=%0d ds{len=%0d size=%0d} dsW=%0d dsB_sent=%0d upB=%0d resp=%0b",
             label, n_aw, m_awlen_q, m_awsize_q, n_wbeat, n_dsb, got_b, bresp);
    if (wlog.len() < 150) $display("       dsW beats: %s", wlog);
  endtask

  initial begin
    repeat(4) @(posedge clk); @(negedge clk) rst_n=1; repeat(2) @(posedge clk);
    $display("== WRITES: upstream 64-bit, downstream 16-bit (ratio 4) ==");
    probe_write("INCR len=0 size=1 strb=03 (recheck)", 5, 32'h1000, 0, 1, 2'b01, 8'h03);
    probe_write("INCR len=0 size=1 strb=01", 5, 32'h1000, 0, 1, 2'b01, 8'h01);
    probe_write("INCR len=1 size=1 strb=03", 5, 32'h1000, 1, 1, 2'b01, 8'h03);
    probe_write("INCR len=0 size=3 strb=FF",  1, 32'h1000, 0, 3, 2'b01, 8'hFF);
    probe_write("INCR len=1 size=3 strb=FF",  2, 32'h1000, 1, 3, 2'b01, 8'hFF);
    probe_write("INCR len=0 size=3 strb=0F",  3, 32'h1000, 0, 3, 2'b01, 8'h0F);
    probe_write("INCR len=0 size=3 strb=81",  4, 32'h1000, 0, 3, 2'b01, 8'h81);
    probe_write("INCR len=0 size=1 strb=03",  5, 32'h1000, 0, 1, 2'b01, 8'h03);
    probe_write("INCR len=1 size=3 @1004",    6, 32'h1004, 1, 3, 2'b01, 8'hFF);
    probe_write("FIXED len=0 size=3",         7, 32'h1000, 0, 3, 2'b00, 8'hFF);
    probe_write("FIXED len=1 size=3 (multi)", 8, 32'h1000, 1, 3, 2'b00, 8'hFF);
    probe_write("WRAP len=3 size=3",          9, 32'h1000, 3, 3, 2'b10, 8'hFF);
    $finish;
  end
  initial begin #900000; $display("PROBE watchdog"); $finish; end
endmodule
