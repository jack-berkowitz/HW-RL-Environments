// Does the anchor actually propagate a downstream error, and how? D6 and E6 were
// written without ever being driven, so they are measured here before any
// checker asserts them.
module err_probe;
  localparam int SW=64, MW=16;
  logic clk=0, rst_n=0; always #5 clk=~clk;
  logic [3:0] s_awid=0,s_arid=0,s_bid,s_rid,m_awid,m_arid;
  logic [31:0] s_awaddr=0,s_araddr=0,m_awaddr,m_araddr;
  logic [7:0] s_awlen=0,s_arlen=0,m_awlen,m_arlen;
  logic [2:0] s_awsize=0,s_arsize=0,m_awsize,m_arsize;
  logic [1:0] s_awburst=1,s_arburst=1,m_awburst,m_arburst,s_bresp,s_rresp;
  logic s_awvalid=0,s_awready,s_wvalid=0,s_wready,s_wlast=0,s_bvalid,s_bready=1;
  logic s_arvalid=0,s_arready,s_rlast,s_rvalid,s_rready=1;
  logic m_awvalid,m_awready=1,m_wvalid,m_wready=1,m_wlast,m_bready;
  logic m_arvalid,m_arready=1,m_rready;
  logic [SW-1:0] s_wdata=0,s_rdata; logic [SW/8-1:0] s_wstrb=0;
  logic [MW-1:0] m_wdata,m_rdata=0; logic [MW/8-1:0] m_wstrb;
  logic [3:0] m_rid_d=0, m_bid_d=0; logic [1:0] m_rresp_d=0, m_bresp_d=0;
  logic m_rlast_d=0, m_rvalid_d=0, m_bvalid_d=0;
  wire [3:0] m_rid=m_rid_d, m_bid=m_bid_d;
  wire [1:0] m_rresp=m_rresp_d, m_bresp=m_bresp_d;
  wire m_rlast=m_rlast_d, m_rvalid=m_rvalid_d, m_bvalid=m_bvalid_d;

  dw_downsizer dut(.clk_i(clk), .rst_ni(rst_n), .*);

  // downstream read slave with per-beat error injection
  int q_len[$], q_id[$]; int rbeat=0;
  int err_beat = -1;        // which downstream beat errors; -1 = none
  logic [1:0] err_code = 2'b10;
  always @(posedge clk) if (rst_n && m_arvalid && m_arready) begin
    q_len.push_back(int'(m_arlen)); q_id.push_back(int'(m_arid));
  end
  always @(posedge clk) begin
    if (!rst_n) begin m_rvalid_d<=0; rbeat<=0; end
    else if (m_rvalid_d && m_rready) begin
      if (rbeat == q_len[0]) begin
        void'(q_len.pop_front()); void'(q_id.pop_front()); rbeat<=0; m_rvalid_d<=0;
      end else begin
        rbeat<=rbeat+1; m_rvalid_d<=1;
        m_rlast_d <= ((rbeat+1)==q_len[0]);
        m_rresp_d <= ((rbeat+1)==err_beat) ? err_code : 2'b00;
        m_rid_d   <= 4'(q_id[0]);
      end
    end else if (!m_rvalid_d && q_len.size()>0) begin
      m_rvalid_d<=1; m_rlast_d <= (rbeat==q_len[0]);
      m_rresp_d <= (rbeat==err_beat) ? err_code : 2'b00;
      m_rid_d   <= 4'(q_id[0]);
    end
  end
  // downstream write slave
  int wq[$]; int pend=0;
  logic [1:0] werr = 2'b00;
  always @(posedge clk) if (rst_n) begin
    if (m_awvalid && m_awready) wq.push_back(int'(m_awid));
    if (m_wvalid && m_wready && m_wlast) pend++;
    if (m_bvalid_d && m_bready) begin m_bvalid_d<=0; if (wq.size()>0) void'(wq.pop_front()); end
    else if (!m_bvalid_d && pend>0) begin
      m_bvalid_d<=1; m_bresp_d<=werr; m_bid_d<=(wq.size()>0)?4'(wq[0]):'0; pend--;
    end
  end

  task automatic rd(input string label, input int len, input int eb, input logic [1:0] ec);
    string resps=""; int n=0;
    err_beat = eb; err_code = ec;
    @(negedge clk); s_arid=4'h5; s_araddr=32'h1000; s_arlen=8'(len); s_arsize=3'd3;
                    s_arburst=2'b01; s_arvalid=1;
    for (int t=0;t<200;t++) begin @(posedge clk); if (s_arready) break; end
    @(negedge clk) s_arvalid=0;
    for (int t=0;t<800;t++) begin
      @(posedge clk);
      if (s_rvalid && s_rready) begin
        n++; resps = {resps, $sformatf("%0b ", s_rresp)};
        if (s_rlast) break;
      end
    end
    $display("  %-38s upstream R resp per beat: %s (%0d beats)", label, resps, n);
  endtask

  initial begin
    repeat(4) @(posedge clk); @(negedge clk) rst_n=1; repeat(2) @(posedge clk);
    $display("== D6: a downstream READ error, len=1 size=3 -> 8 downstream beats ==");
    rd("no error at all",              1, -1, 2'b00);
    rd("SLVERR on downstream beat 0",  1,  0, 2'b10);
    rd("SLVERR on downstream beat 3",  1,  3, 2'b10);
    rd("SLVERR on downstream beat 7 (last)", 1, 7, 2'b10);
    rd("DECERR on downstream beat 3",  1,  3, 2'b11);
    $display("");
    $display("== E6: a downstream WRITE error ==");
    err_beat = -1;
    for (int k=0;k<2;k++) begin
      werr = (k==0) ? 2'b00 : 2'b10;
      @(negedge clk); s_awid=4'h6; s_awaddr=32'h2000; s_awlen=8'd0; s_awsize=3'd3;
                      s_awburst=2'b01; s_awvalid=1;
      for (int t=0;t<200;t++) begin @(posedge clk); if (s_awready) break; end
      @(negedge clk) s_awvalid=0;
      @(negedge clk); s_wdata=64'hCAFE; s_wstrb='1; s_wlast=1; s_wvalid=1;
      for (int t=0;t<200;t++) begin @(posedge clk); if (s_wready) break; end
      @(negedge clk) s_wvalid=0; s_wlast=0;
      for (int t=0;t<800;t++) begin @(posedge clk); if (s_bvalid && s_bready) break; end
      $display("  downstream B = %0b  ->  upstream B = %0b", werr, s_bresp);
    end
    $finish;
  end
  initial begin #900000; $display("watchdog"); $finish; end
endmodule
