// Spec-conformance probe: checks the clauses step 1 did not cover, through the
// SHIPPED port map. Anything asserted here that the golden does not satisfy is
// a spec defect, and would otherwise surface later as the reference testbench
// failing its own validity gate.
module id_width_conv_tb;
  localparam int SLV_ID_W=4, MST_ID_W=2, MAX_UNIQ=4, MAX_TXN=2;
  logic clk=0, rst_n=0; always #5 clk=~clk;
  logic [3:0] s_awid=0,s_arid=0,s_bid,s_rid; logic [31:0] s_awaddr=0,s_araddr=0,s_wdata=0,s_rdata;
  logic [7:0] s_awlen=0,s_arlen=0; logic [3:0] s_wstrb=0; logic [1:0] s_bresp,s_rresp;
  logic s_awvalid=0,s_awready,s_wlast=0,s_wvalid=0,s_wready,s_bvalid,s_bready=1;
  logic s_arvalid=0,s_arready,s_rlast,s_rvalid,s_rready=1;
  logic [1:0] m_awid,m_arid,m_bid=0,m_rid=0; logic [31:0] m_awaddr,m_araddr,m_wdata,m_rdata=0;
  logic [7:0] m_awlen,m_arlen; logic [3:0] m_wstrb; logic [1:0] m_bresp=0,m_rresp=0;
  logic m_awvalid,m_awready=1,m_wlast,m_wvalid,m_wready=1,m_bvalid=0,m_bready;
  logic m_arvalid,m_arready=1,m_rlast=0,m_rvalid=0,m_rready;
  id_width_conv dut(.clk_i(clk),.rst_ni(rst_n),
    .s_awid,.s_awaddr,.s_awlen,.s_awvalid,.s_awready,.s_wdata,.s_wstrb,.s_wlast,.s_wvalid,.s_wready,
    .s_bid,.s_bresp,.s_bvalid,.s_bready,.s_arid,.s_araddr,.s_arlen,.s_arvalid,.s_arready,
    .s_rid,.s_rdata,.s_rresp,.s_rlast,.s_rvalid,.s_rready,
    .m_awid,.m_awaddr,.m_awlen,.m_awvalid,.m_awready,.m_wdata,.m_wstrb,.m_wlast,.m_wvalid,.m_wready,
    .m_bid,.m_bresp,.m_bvalid,.m_bready,.m_arid,.m_araddr,.m_arlen,.m_arvalid,.m_arready,
    .m_rid,.m_rdata,.m_rresp,.m_rlast,.m_rvalid,.m_rready);

  int bad=0;
  task automatic ck(input string nm, input bit cond, input string got);
    if(cond) $display("  ok   %-44s %s",nm,got);
    else begin bad++; $display("  MISMATCH %-40s %s",nm,got); end
  endtask

  // master-side read slave: capture AR, reply on demand
  logic [1:0] rq_mid [$]; logic reply=0;
  int n_mar=0; logic [1:0] mid_of [$];
  always @(posedge clk) if(rst_n && m_arvalid && m_arready) begin
    rq_mid.push_back(m_arid); mid_of.push_back(m_arid); n_mar++; end
  always_comb begin
    m_rvalid = reply && (rq_mid.size()>0);
    m_rid    = (rq_mid.size()>0)? rq_mid[0] : 2'd0;
    m_rdata  = 32'hAAAA_0000 + ((rq_mid.size()>0)? rq_mid[0]:0);
    m_rlast  = 1'b1;
  end
  always @(posedge clk) if(rst_n && m_rvalid && m_rready) void'(rq_mid.pop_front());
  // master-side write slave
  logic [1:0] wq_mid [$]; logic wreply=0;
  always @(posedge clk) if(rst_n && m_awvalid && m_awready) wq_mid.push_back(m_awid);
  always_comb begin
    m_bvalid = wreply && (wq_mid.size()>0);
    m_bid    = (wq_mid.size()>0)? wq_mid[0] : 2'd0;
  end
  always @(posedge clk) if(rst_n && m_bvalid && m_bready) void'(wq_mid.pop_front());

  task automatic ar(input logic [3:0] id, output bit acc, input int budget);
    int w=0; acc=0;
    @(negedge clk); s_arvalid=1; s_arid=id; s_araddr=32'h1000+id; s_arlen=0;
    while(w<budget) begin @(posedge clk); if(s_arready) begin acc=1; break; end w++; end
    @(negedge clk) s_arvalid=0;
  endtask
  task automatic aw(input logic [3:0] id, output bit acc, input int budget);
    int w=0; acc=0;
    @(negedge clk); s_awvalid=1; s_awid=id; s_awaddr=32'h2000+id; s_awlen=0;
    while(w<budget) begin @(posedge clk); if(s_awready) begin acc=1; break; end w++; end
    @(negedge clk) s_awvalid=0;
  endtask

  initial begin
    bit a; int uniq; logic [1:0] seen [$];
    repeat(4)@(posedge clk); @(negedge clk) rst_n=1; repeat(2)@(posedge clk);

    $display("-- A3: the boundary is exact --");
    for(int i=0;i<MAX_UNIQ-1;i++) ar(4'(i),a,40);
    ar(4'(MAX_UNIQ-1),a,40);
    ck("at MAX_UNIQ-1 distinct, a new id IS accepted", a==1, $sformatf("acc=%0b",a));
    ar(4'd9,a,40);
    ck("at MAX_UNIQ distinct, a new id is REFUSED", a==0, $sformatf("acc=%0b",a));

    $display("-- A4/D1: distinct master ids while co-outstanding --");
    uniq=0; foreach(mid_of[i]) begin
      bit dup=0; foreach(seen[j]) if(seen[j]==mid_of[i]) dup=1;
      if(!dup) begin seen.push_back(mid_of[i]); uniq++; end end
    ck("4 co-outstanding slave ids -> 4 distinct master ids", uniq==4, $sformatf("distinct=%0d",uniq));

    $display("-- A1: reads and writes counted SEPARATELY --");
    aw(4'd9,a,40);
    ck("a WRITE with a 5th id accepted while 4 reads outstanding", a==1, $sformatf("acc=%0b",a));

    $display("-- A4: retirement frees an entry --");
    reply=1; repeat(40)@(posedge clk); reply=0;
    ar(4'd9,a,40);
    ck("after the reads drain, a new id is accepted", a==1, $sformatf("acc=%0b",a));

    $display("-- A5: MAX_TXNS_PER_ID --");
    reply=1; repeat(40)@(posedge clk); reply=0;
    ar(4'd5,a,40); ar(4'd5,a,40);
    ck("2nd txn with the same id accepted", a==1, $sformatf("acc=%0b",a));
    ar(4'd5,a,30);
    ck("3rd txn with the same id REFUSED (MAX_TXNS_PER_ID=2)", a==0, $sformatf("acc=%0b",a));
    reply=1; repeat(40)@(posedge clk); reply=0;

    $display("-- C1: responses carry the SLAVE id --");
    begin
      logic [3:0] got [$]; int n=0;
      ar(4'd7,a,40); ar(4'd3,a,40);
      fork begin reply=1; repeat(40)@(posedge clk); reply=0; end
           begin repeat(40) begin @(posedge clk); if(s_rvalid&&s_rready) begin got.push_back(s_rid); n++; end end end
      join
      ck("read responses carry slave ids 7 and 3", (n==2)&&((got[0]==7&&got[1]==3)||(got[0]==3&&got[1]==7)),
          $sformatf("n=%0d ids=%p",n,got));
    end

    if(bad==0) $display("RESULT: PASS"); else $display("RESULT: FAIL (%0d)",bad);
    $finish;
  end
  initial begin #400000; $display("RESULT: FAIL watchdog"); $finish; end
endmodule
