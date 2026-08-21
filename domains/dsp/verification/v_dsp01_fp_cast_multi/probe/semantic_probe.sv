// STEP-1 SEMANTIC PROBE -- fpnew_cast_multi. Every expected value below is
// computed by hand from IEEE 754 and the RISC-V F extension, not read off the
// design. If the design disagrees, the design is what is wrong.
module cast_sem;
  import fpnew_pkg::*;
  localparam fmt_logic_t  FPCFG  = 9'b101_000_000;   // ASCENDING [0:8]: FP32(0) and FP16(2)
  localparam ifmt_logic_t INTCFG = 4'b0110;          // ASCENDING [0:3]: INT16(1) and INT32(2)

  logic clk=0, rst_n=0; always #5 clk=~clk;
  logic [31:0] op_in = '0;
  logic [8:0]  boxed = '1;
  roundmode_e  rnd   = RNE;
  operation_e  op    = F2F;
  logic        opmod = 1'b0;
  fp_format_e  sfmt  = FP32, dfmt = FP32;
  int_format_e ifmt  = INT32;
  logic in_v=0, in_r; logic [31:0] res; status_t st;
  logic out_v; logic out_r=1'b1;

  fpnew_cast_multi #(.FpFmtConfig(FPCFG), .IntFmtConfig(INTCFG), .NumPipeRegs(0),
                     .PipeConfig(BEFORE)) dut (
    .clk_i(clk), .rst_ni(rst_n), .operands_i(op_in), .is_boxed_i(boxed),
    .rnd_mode_i(rnd), .op_i(op), .op_mod_i(opmod), .src_fmt_i(sfmt), .dst_fmt_i(dfmt),
    .int_fmt_i(ifmt), .tag_i(1'b0), .mask_i(1'b1), .aux_i(1'b0),
    .in_valid_i(in_v), .in_ready_o(in_r), .flush_i(1'b0),
    .result_o(res), .status_o(st), .extension_bit_o(), .tag_o(), .mask_o(), .aux_o(),
    .out_valid_o(out_v), .out_ready_i(out_r), .busy_o());

  int bad = 0;
  task automatic go(input string name, input logic [31:0] a, input operation_e o,
                    input logic mod, input fp_format_e sf, input fp_format_e df,
                    input int_format_e itf, input roundmode_e rm,
                    input logic [31:0] want_res, input logic [4:0] want_st);
    @(negedge clk);
    op_in = a; op = o; opmod = mod; sfmt = sf; dfmt = df; ifmt = itf; rnd = rm; in_v = 1'b1;
    @(posedge clk);
    #1;
    begin
      automatic logic ok = (res === want_res) && ({st.NV,st.DZ,st.OF,st.UF,st.NX} === want_st);
      $display("  %-34s got %08x [%b] want %08x [%b]  %s", name, res,
               {st.NV,st.DZ,st.OF,st.UF,st.NX}, want_res, want_st, ok ? "ok" : "<-- MISMATCH");
      if (!ok) bad++;
    end
    @(negedge clk) in_v = 1'b0;
  endtask

  initial begin
    repeat(3)@(posedge clk); @(negedge clk) rst_n=1; repeat(2)@(posedge clk);
    $display("== F2F: FP32 -> FP16 (narrow results are NaN-boxed into the 32-bit port) ==");
    go("1.0 -> 1.0",            32'h3F800000, F2F, 0, FP32, FP16, INT32, RNE, 32'hFFFF3C00, 5'b00000);
    go("65536 -> +inf (OF,NX)", 32'h47800000, F2F, 0, FP32, FP16, INT32, RNE, 32'hFFFF7C00, 5'b00101);
    go("65504 -> FP16 max",     32'h477FE000, F2F, 0, FP32, FP16, INT32, RNE, 32'hFFFF7BFF, 5'b00000);
    go("1e-8 -> +0 (UF,NX)",    32'h322BCC77, F2F, 0, FP32, FP16, INT32, RNE, 32'hFFFF0000, 5'b00011);
    go("qNaN -> qNaN",          32'h7FC00000, F2F, 0, FP32, FP16, INT32, RNE, 32'hFFFF7E00, 5'b00000);
    go("sNaN -> qNaN (NV)",     32'h7F800001, F2F, 0, FP32, FP16, INT32, RNE, 32'hFFFF7E00, 5'b10000);

    $display("== F2F: FP16 -> FP32 (always exact) ==");
    go("FP16 1.0 -> FP32 1.0",  32'h00003C00, F2F, 0, FP16, FP32, INT32, RNE, 32'h3F800000, 5'b00000);

    $display("== F2I: FP32 -> INT32 signed ==");
    go("3.5 RTZ -> 3 (NX)",     32'h40600000, F2I, 0, FP32, FP32, INT32, RTZ, 32'd3,        5'b00001);
    go("3.5 RNE -> 4 (NX)",     32'h40600000, F2I, 0, FP32, FP32, INT32, RNE, 32'd4,        5'b00001);
    go("2.5 RNE -> 2 (NX)",     32'h40200000, F2I, 0, FP32, FP32, INT32, RNE, 32'd2,        5'b00001);
    go("2.5 RMM -> 3 (NX)",     32'h40200000, F2I, 0, FP32, FP32, INT32, RMM, 32'd3,        5'b00001);
    go("-3.5 RDN -> -4 (NX)",   32'hC0600000, F2I, 0, FP32, FP32, INT32, RDN, -32'sd4,      5'b00001);
    go("1e10 -> INT32_MAX (NV)",32'h501502F9, F2I, 0, FP32, FP32, INT32, RTZ, 32'h7FFFFFFF, 5'b10000);
    go("-1e10 -> INT32_MIN(NV)",32'hD01502F9, F2I, 0, FP32, FP32, INT32, RTZ, 32'h80000000, 5'b10000);
    go("NaN -> INT32_MAX (NV)", 32'h7FC00000, F2I, 0, FP32, FP32, INT32, RTZ, 32'h7FFFFFFF, 5'b10000);

    $display("== F2I: FP32 -> INT32 UNSIGNED (op_mod=1) ==");
    go("-1.0 -> 0 (NV)",        32'hBF800000, F2I, 1, FP32, FP32, INT32, RTZ, 32'h00000000, 5'b10000);
    go("4e9 -> 4000000000",     32'h4F6E6B28, F2I, 1, FP32, FP32, INT32, RTZ, 32'hEE6B2800, 5'b00000);

    $display("== I2F: INT32 -> FP32 ==");
    go("1 -> 1.0",              32'd1,        I2F, 0, FP32, FP32, INT32, RNE, 32'h3F800000, 5'b00000);
    go("2^24+1 -> rounds (NX)", 32'd16777217, I2F, 0, FP32, FP32, INT32, RNE, 32'h4B800000, 5'b00001);
    go("-1 -> -1.0",            -32'sd1,      I2F, 0, FP32, FP32, INT32, RNE, 32'hBF800000, 5'b00000);
    go("unsigned 4e9 -> FP32",  32'hEE6B2800, I2F, 1, FP32, FP32, INT32, RNE, 32'h4F6E6B28, 5'b00000);

    $display("");
    $display("MISMATCHES: %0d", bad);
    $finish;
  end
  initial begin #100000; $display("watchdog"); $finish; end
endmodule
