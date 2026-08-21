// STEP-1 CORNER PROBE -- the places where IEEE 754 is rounding-mode dependent
// and where the spec must therefore be pinned rather than assumed.
module corner;
  logic clk=0, rst_n=0; always #5 clk=~clk;
  logic [31:0] a='0; logic [1:0] op=0; logic [2:0] rm=0;
  logic sgn=1, sf=0, df=0, iv=0, ir; logic [31:0] res; logic [4:0] fl;
  logic ov; logic orr=1;
  fp_convert dut(.clk_i(clk),.rst_ni(rst_n),.operand_i(a),.op_i(op),.rnd_i(rm),
    .signed_i(sgn),.src_fmt_i(sf),.dst_fmt_i(df),.in_valid_i(iv),.in_ready_o(ir),
    .result_o(res),.flags_o(fl),.out_valid_o(ov),.out_ready_i(orr));
  string RM [5] = '{"RNE","RTZ","RDN","RUP","RMM"};
  task automatic q(input logic [31:0] v, input int o, input int r, input bit s,
                   input bit sfmt, input bit dfmt);
    @(negedge clk); a=v; op=2'(o); rm=3'(r); sgn=s; sf=sfmt; df=dfmt; iv=1;
    @(posedge clk); #1;
    $display("      %-4s -> res=%08x flags(NV DZ OF UF NX)=%b", RM[r], res, fl);
    @(negedge clk) iv=0;
  endtask
  initial begin
    repeat(3)@(posedge clk); @(negedge clk) rst_n=1; repeat(2)@(posedge clk);

    $display("== F2F FP32->FP16 OVERFLOW: 100000.0 (0x47C35000). IEEE makes the");
    $display("   result mode dependent: RTZ and RDN give +max, others +inf ==");
    for (int r=0;r<5;r++) q(32'h47C35000, 0, r, 1, 0, 1);
    $display("== the same, negative: -100000.0 ==");
    for (int r=0;r<5;r++) q(32'hC7C35000, 0, r, 1, 0, 1);

    $display("== F2F FP32->FP16 SUBNORMAL: 1e-6 (0x358637BD), below FP16 normal min ==");
    for (int r=0;r<5;r++) q(32'h358637BD, 0, r, 1, 0, 1);

    $display("== F2F FP16 subnormal -> FP32 (0x0001, the smallest FP16 subnormal) ==");
    q(32'h00000001, 0, 0, 1, 1, 0);

    $display("== F2I FP32->INT32 at the saturation boundary ==");
    $display("   2147483648.0 = 0x4F000000, exactly INT32_MAX+1");
    for (int r=0;r<5;r++) q(32'h4F000000, 1, r, 1, 0, 0);
    $display("   2147483520.0 = 0x4EFFFFFF, the largest FP32 below 2^31");
    for (int r=0;r<5;r++) q(32'h4EFFFFFF, 1, r, 1, 0, 0);
    $display("   -2147483648.0 = 0xCF000000, exactly INT32_MIN");
    for (int r=0;r<5;r++) q(32'hCF000000, 1, r, 1, 0, 0);

    $display("== F2I of -0.5: rounds to 0 or -1 by mode; unsigned must flag NV? ==");
    for (int r=0;r<5;r++) q(32'hBF000000, 1, r, 1, 0, 0);
    $display("   the same, UNSIGNED ==");
    for (int r=0;r<5;r++) q(32'hBF000000, 1, r, 0, 0, 0);

    $display("== F2I +inf and -inf, signed ==");
    q(32'h7F800000, 1, 1, 1, 0, 0);
    q(32'hFF800000, 1, 1, 1, 0, 0);

    $display("== I2F INT32 -> FP16: 100000 overflows FP16 ==");
    for (int r=0;r<5;r++) q(32'd100000, 2, r, 1, 0, 1);
    $finish;
  end
  initial begin #200000; $display("watchdog"); $finish; end
endmodule
