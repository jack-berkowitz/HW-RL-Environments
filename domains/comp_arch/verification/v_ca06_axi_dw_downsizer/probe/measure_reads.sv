`ifndef DUT_MOD
  `define DUT_MOD dw_downsizer
`endif
// STEP 1 -- semantic confirmation, measured not read.
module dw_probe;
  localparam int SW=64, MW=16;
  logic clk=0, rst_n=0; always #5 clk=~clk;
  logic [3:0] s_awid=0,s_arid=0,s_bid,s_rid,m_awid,m_arid,m_bid=0,m_rid=0;
  logic [31:0] s_awaddr=0,s_araddr=0,m_awaddr,m_araddr;
  logic [7:0] s_awlen=0,s_arlen=0,m_awlen,m_arlen;
  logic [2:0] s_awsize=0,s_arsize=0,m_awsize,m_arsize;
  logic [1:0] s_awburst=1,s_arburst=1,m_awburst,m_arburst,s_bresp,s_rresp,m_bresp=0,m_rresp=0;
  logic s_awvalid=0,s_awready,s_wvalid=0,s_wready,s_wlast=0,s_bvalid,s_bready=1;
  logic s_arvalid=0,s_arready,s_rlast,s_rvalid,s_rready=1;
  logic m_awvalid,m_awready=1,m_wvalid,m_wready=1,m_wlast,m_bvalid=0,m_bready;
  logic m_arvalid,m_arready=1,m_rlast=0,m_rvalid=0,m_rready;
  logic [SW-1:0] s_wdata=0,s_rdata; logic [SW/8-1:0] s_wstrb=0;
  logic [MW-1:0] m_wdata,m_rdata=0; logic [MW/8-1:0] m_wstrb;
  `DUT_MOD dut(.clk_i(clk), .rst_ni(rst_n), .*);

  // downstream slave: answer every AR with len+1 beats, data = addr-derived
  int q_len[$]; int q_id[$]; int q_addr[$];
  int beat=0;
  always @(posedge clk) if (rst_n && m_arvalid && m_arready) begin
    q_len.push_back(m_arlen); q_id.push_back(m_arid); q_addr.push_back(m_araddr);
  end
  always_comb begin
    m_rvalid = (q_len.size()>0);
    m_rid    = (q_len.size()>0) ? 4'(q_id[0]) : '0;
    m_rdata  = (q_len.size()>0) ? MW'(q_addr[0] + beat*2) : '0;
    m_rlast  = (q_len.size()>0) && (beat == q_len[0]);
    m_rresp  = 2'b00;
  end
  always @(posedge clk) if (rst_n && m_rvalid && m_rready) begin
    if (beat == q_len[0]) begin
      void'(q_len.pop_front()); void'(q_id.pop_front()); void'(q_addr.pop_front()); beat<=0;
    end else beat <= beat+1;
  end

  int n_rbeat, n_ar; logic saw_ar; string resps;
  task automatic probe_read(input string label, input int id, input logic [31:0] a,
                            input int len, input int size, input logic [1:0] burst);
    int t; n_rbeat=0; saw_ar=0; n_ar=0; resps="";
    // Each case is measured from a clean machine: a probe that lets one case
    // leave state behind reports the NEXT case's behaviour as this one's.
    @(negedge clk) rst_n=0; q_len.delete(); q_id.delete(); q_addr.delete(); beat=0;
    repeat(3) @(posedge clk); @(negedge clk) rst_n=1; repeat(2) @(posedge clk);
    @(negedge clk); s_arid=4'(id); s_araddr=a; s_arlen=8'(len); s_arsize=3'(size);
                    s_arburst=burst; s_arvalid=1;
    for (t=0;t<400;t++) begin @(posedge clk); if (s_arready) break; end
    @(negedge clk) s_arvalid=0;
    if (t>=40) begin $display("  %-30s AR NOT ACCEPTED", label); return; end
    for (t=0;t<4000;t++) begin
      @(posedge clk);
      if (s_rvalid && s_rready) begin
        n_rbeat++;
        resps = {resps, $sformatf("%0b ", s_rresp)};
        if (s_rlast) break;
      end
    end
    $display("  %-32s dsAR=%0d  ds{len=%0d size=%0d addr=%08x}  upR=%0d  resp/beat: %s",
             label, n_ar, m_arlen_q, m_arsize_q, m_araddr_q, n_rbeat, resps);
  endtask
  // latch the downstream AR as issued
  logic [7:0] m_arlen_q; logic [2:0] m_arsize_q; logic [31:0] m_araddr_q; logic [1:0] m_arburst_q;
  always @(posedge clk) if (rst_n && m_arvalid && m_arready)
    begin n_ar<=n_ar+1; m_arlen_q<=m_arlen; m_arsize_q<=m_arsize; m_araddr_q<=m_araddr; m_arburst_q<=m_arburst; end

  initial begin
    repeat(4) @(posedge clk); @(negedge clk) rst_n=1; repeat(2) @(posedge clk);
    $display("== READS: upstream 64-bit, downstream 16-bit (ratio 4) ==");
    probe_read("INCR len=0 size=3 (1x8B)",  1, 32'h1000, 0, 3, 2'b01);
    probe_read("INCR len=1 size=3 (2x8B)",  2, 32'h1000, 1, 3, 2'b01);
    probe_read("INCR len=3 size=3 (4x8B)",  3, 32'h1000, 3, 3, 2'b01);
    probe_read("INCR len=0 size=1 (1x2B)",  4, 32'h1000, 0, 1, 2'b01);
    probe_read("INCR len=3 size=1 (4x2B)",  5, 32'h1000, 3, 1, 2'b01);
    probe_read("INCR len=0 size=0 (1x1B)",  6, 32'h1000, 0, 0, 2'b01);
    probe_read("INCR len=1 size=3 UNALIGNED",7,32'h1004, 1, 3, 2'b01);
    probe_read("FIXED len=0 size=3",        8, 32'h1000, 0, 3, 2'b00);
    probe_read("FIXED len=1 size=3 (multi)",9, 32'h1000, 1, 3, 2'b00);
    probe_read("WRAP len=3 size=3",        10, 32'h1000, 3, 3, 2'b10);
    $finish;
  end
  initial begin #500000; $display("PROBE watchdog"); $finish; end
endmodule
