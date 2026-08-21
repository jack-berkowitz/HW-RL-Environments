// Two suspected defects, probed at the boundary.
module susp;
  logic clk=0, rst_n=0; always #5 clk=~clk;
  logic [31:0] a='0; logic [1:0] op=0; logic [2:0] rm=0;
  logic sgn=1, sf=0, df=0, iv=0, ir; logic [31:0] res; logic [4:0] fl;
  logic ov; logic orr=1;
  fp_convert dut(.clk_i(clk),.rst_ni(rst_n),.operand_i(a),.op_i(op),.rnd_i(rm),
    .signed_i(sgn),.src_fmt_i(sf),.dst_fmt_i(df),.in_valid_i(iv),.in_ready_o(ir),
    .result_o(res),.flags_o(fl),.out_valid_o(ov),.out_ready_i(orr));
  task automatic q(input string nm, input logic [31:0] v, input int o, input int r,
                   input bit s, input bit sfmt, input bit dfmt, input string want);
    @(negedge clk); a=v; op=2'(o); rm=3'(r); sgn=s; sf=sfmt; df=dfmt; iv=1;
    @(posedge clk); #1;
    $display("   %-40s res=%08x flags=%b   IEEE/RISC-V: %s", nm, res, fl, want);
    @(negedge clk) iv=0;
  endtask
  initial begin
    repeat(3)@(posedge clk); @(negedge clk) rst_n=1; repeat(2)@(posedge clk);
    $display("== SUSPECT 1: F2I signed at the negative saturation boundary ==");
    q("-2^31 exactly (0xCF000000)",        32'hCF000000, 1, 1, 1, 0, 0, "0x80000000, NO flags");
    q("-2^31 - 1ulp (0xCF000001)",         32'hCF000001, 1, 1, 1, 0, 0, "0x80000000, NV");
    q("-(2^31 - 128) (0xCEFFFFFF)",        32'hCEFFFFFF, 1, 1, 1, 0, 0, "0x80000080, NO flags");
    q("+2^31 - 128 (0x4EFFFFFF)",          32'h4EFFFFFF, 1, 1, 1, 0, 0, "0x7FFFFF80, NO flags");
    q("-1.0",                              32'hBF800000, 1, 1, 1, 0, 0, "0xFFFFFFFF, NO flags");
    $display("== the same via FP16 source: FP16 cannot reach 2^31, so nothing to see ==");
    $display("== SUSPECT 2: I2F overflow of the destination float ==");
    q("INT32 100000 -> FP16",              32'd100000,   2, 0, 1, 0, 1, "+inf, OF+NX");
    q("INT32 70000 -> FP16",               32'd70000,    2, 0, 1, 0, 1, "+inf, OF+NX");
    q("INT32 65504 -> FP16 (exactly max)", 32'd65504,    2, 0, 1, 0, 1, "0x7BFF, NO flags");
    q("INT32 65520 -> FP16 (rounds to max)",32'd65520,   2, 0, 1, 0, 1, "0x7BFF, NX");
    q("INT32 65536 -> FP16",               32'd65536,    2, 0, 1, 0, 1, "+inf, OF+NX");
    q("INT32 100000 -> FP32 (fits)",       32'd100000,   2, 0, 1, 0, 0, "0x47C35000, NO flags");
    $display("== control: F2F FP32->FP16 overflow sets OF, so OF exists on this path ==");
    q("F2F 100000.0 -> FP16",              32'h47C35000, 0, 0, 1, 0, 1, "+inf, OF+NX");
    $finish;
  end
  initial begin #100000; $finish; end
endmodule
