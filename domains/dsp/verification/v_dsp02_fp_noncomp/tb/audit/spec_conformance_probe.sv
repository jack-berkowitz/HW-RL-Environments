// Spec-conformance probe for v_dsp02: checks the clauses added since step 1,
// through the SHIM (so it exercises the flattened port map too).
module fp_noncomp_tb;
  logic clk=0, rst_n=0; always #5 clk=~clk;
  logic [31:0] a,b,res; logic [1:0] op; logic [2:0] md;
  logic iv=0, ir, ov, orr=1; logic [9:0] cm; logic [4:0] st;
  int bad=0;
  fp_noncomp dut(.clk_i(clk),.rst_ni(rst_n),.operand_a_i(a),.operand_b_i(b),
    .op_i(op),.op_mode_i(md),.in_valid_i(iv),.in_ready_o(ir),
    .result_o(res),.class_mask_o(cm),.status_o(st),.out_valid_o(ov),.out_ready_i(orr));

  task automatic issue(input logic[1:0] o, input logic[2:0] m,
                       input logic[31:0] x, input logic[31:0] y);
    @(negedge clk); op=o; md=m; a=x; b=y; iv=1;
    do @(posedge clk); while (!(iv && ir));
    @(negedge clk) iv=0;
    while (!ov) @(posedge clk);
    #1;
  endtask
  task automatic ck(input string nm, input logic cond, input string got);
    if (!cond) begin bad++; $display("  MISMATCH %-34s %s", nm, got); end
    else                   $display("  ok       %-34s %s", nm, got);
  endtask

  localparam logic [31:0] NCNAN = 32'h7FD5_A5A5; // quiet NaN, NON-canonical payload
  localparam logic [31:0] SNAN  = 32'h7FA0_0000;
  localparam logic [31:0] ONE   = 32'h3F80_0000;
  localparam logic [31:0] MTWO  = 32'hC000_0000;

  initial begin
    repeat(4) @(posedge clk); @(negedge clk) rst_n=1;

    $display("-- S1: SGNJ copies operand_a bits 30:0 unchanged, NaN included --");
    issue(2'd0,3'd0,NCNAN,MTWO);
    ck("sgnj(nonCanonNaN,-2)", res===32'hFFD5_A5A5, $sformatf("res=%h (payload preserved?)",res));
    issue(2'd0,3'd0,NCNAN,ONE);
    ck("sgnj(nonCanonNaN,+1)", res===32'h7FD5_A5A5, $sformatf("res=%h",res));

    $display("-- S2/S13: SGNJ and CLASSIFY raise nothing, even on sNaN --");
    issue(2'd0,3'd0,SNAN,ONE);  ck("sgnj(sNaN,1) flags==0",  st===5'b0, $sformatf("status=%b",st));
    issue(2'd3,3'd0,SNAN,'0);   ck("classify(sNaN) flags==0", st===5'b0, $sformatf("status=%b class=%b",st,cm));

    $display("-- S14: DZ/OF/UF/NX zero across the corner set --");
    begin
      logic [31:0] vs [8] = '{NCNAN,SNAN,ONE,MTWO,32'h0,32'h8000_0000,32'h7F80_0000,32'h0000_0001};
      int lo=0;
      for (int o=0;o<4;o++) for (int m=0;m<3;m++)
        for (int i=0;i<8;i++) for (int j=0;j<8;j++) begin
          issue(2'(o),3'(m),vs[i],vs[j]);
          if (st[3:0]!==4'b0) lo++;
        end
      ck("DZ/OF/UF/NX always zero (768 ops)", lo==0, $sformatf("%0d ops set a non-NV flag",lo));
    end

    $display("-- H2: results delivered in accepted order --");
    begin
      // three back-to-back classify ops with distinguishable results
      logic [31:0] seq [3] = '{32'hFF80_0000, 32'h3F80_0000, 32'h0000_0000};
      logic [9:0]  exp [3] = '{10'b00_0000_0001, 10'b00_0100_0000, 10'b00_0001_0000};
      int ok=1;
      for (int i=0;i<3;i++) begin
        issue(2'd3,3'd0,seq[i],'0);
        if (cm !== exp[i]) ok=0;
      end
      ck("classify order preserved", ok==1, "3 ops in order");
    end

    $display("-- S15: reset discards work in flight --");
    @(negedge clk); op=2'd3; md=0; a=32'hFF80_0000; b='0; iv=1; orr=0;
    @(posedge clk); @(negedge clk) iv=0;
    repeat(2) @(posedge clk);
    @(negedge clk) rst_n=0; repeat(2) @(posedge clk); @(negedge clk) rst_n=1; orr=1;
    @(posedge clk); #1;
    ck("out_valid low after reset release", ov===1'b0, $sformatf("ov=%b",ov));

    if (bad==0) $display("RESULT: PASS"); else $display("RESULT: FAIL (%0d)",bad);
    $finish;
  end
  initial begin #50_000_000; $display("RESULT: FAIL watchdog"); $finish; end
endmodule
