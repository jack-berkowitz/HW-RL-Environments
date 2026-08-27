module clause_check;
  logic [15:0] a, b, c, z;
  logic [2:0]  r;
  logic [4:0]  f;
  int          fails = 0;
  int          checks = 0;
  string       tag;

  fp16_fma_exact dut (.a_i(a), .b_i(b), .c_i(c), .rnd_i(r), .z_o(z), .fl_o(f));

  task automatic ck(input string nm, input [15:0] ea, eb, ec, input [2:0] er,
                    input [15:0] wz, input [4:0] wf);
    a = ea; b = eb; c = ec; r = er;
    #1;
    checks++;
    if (z !== wz || f !== wf) begin
      fails++;
      $display("FAIL %s rnd=%0d : got z=%04h f=%05b  want z=%04h f=%05b",
               nm, er, z, f, wz, wf);
    end
  endtask

  initial begin
    // ---- A5, exact result +65536 (256 * 256 + 0) ----------------------
    ck("A5.pos", 16'h5C00, 16'h5C00, 16'h0000, 3'd0, 16'h7C00, 5'b00101);
    ck("A5.pos", 16'h5C00, 16'h5C00, 16'h0000, 3'd1, 16'h7BFF, 5'b00101);
    ck("A5.pos", 16'h5C00, 16'h5C00, 16'h0000, 3'd2, 16'h7BFF, 5'b00101);
    ck("A5.pos", 16'h5C00, 16'h5C00, 16'h0000, 3'd3, 16'h7C00, 5'b00101);
    ck("A5.pos", 16'h5C00, 16'h5C00, 16'h0000, 3'd4, 16'h7C00, 5'b00101);
    ck("A5.neg", 16'hDC00, 16'h5C00, 16'h0000, 3'd0, 16'hFC00, 5'b00101);
    ck("A5.neg", 16'hDC00, 16'h5C00, 16'h0000, 3'd1, 16'hFBFF, 5'b00101);
    ck("A5.neg", 16'hDC00, 16'h5C00, 16'h0000, 3'd2, 16'hFC00, 5'b00101);
    ck("A5.neg", 16'hDC00, 16'h5C00, 16'h0000, 3'd3, 16'hFBFF, 5'b00101);
    ck("A5.neg", 16'hDC00, 16'h5C00, 16'h0000, 3'd4, 16'hFC00, 5'b00101);

    // ---- A6, exact result +/- 2^-25 (2^-24 * 0.5 + 0) ------------------
    ck("A6.pos", 16'h0001, 16'h3800, 16'h0000, 3'd0, 16'h0000, 5'b00011);
    ck("A6.pos", 16'h0001, 16'h3800, 16'h0000, 3'd1, 16'h0000, 5'b00011);
    ck("A6.pos", 16'h0001, 16'h3800, 16'h0000, 3'd2, 16'h0000, 5'b00011);
    ck("A6.pos", 16'h0001, 16'h3800, 16'h0000, 3'd3, 16'h0001, 5'b00011);
    ck("A6.pos", 16'h0001, 16'h3800, 16'h0000, 3'd4, 16'h0001, 5'b00011);
    ck("A6.neg", 16'h8001, 16'h3800, 16'h0000, 3'd0, 16'h8000, 5'b00011);
    ck("A6.neg", 16'h8001, 16'h3800, 16'h0000, 3'd1, 16'h8000, 5'b00011);
    ck("A6.neg", 16'h8001, 16'h3800, 16'h0000, 3'd2, 16'h8001, 5'b00011);
    ck("A6.neg", 16'h8001, 16'h3800, 16'h0000, 3'd3, 16'h8000, 5'b00011);
    ck("A6.neg", 16'h8001, 16'h3800, 16'h0000, 3'd4, 16'h8001, 5'b00011);

    // ---- A6 mid band: below smallest normal, at/above smallest subnormal
    //      3 * 2^-24 must be delivered exactly, not flushed (F1).
    ck("A6.mid", 16'h0003, 16'h3C00, 16'h0000, 3'd0, 16'h0003, 5'b00000);

    // ---- A7, tiny but exact: 2^-14 * 0.5 -> 0x0200, all flags low -------
    for (int m = 0; m < 5; m++)
      ck("A7", 16'h0400, 16'h3800, 16'h0000, m[2:0], 16'h0200, 5'b00000);

    // ---- A8, sum of two zeros of opposite sign --------------------------
    ck("A8", 16'h0000, 16'h3C00, 16'h8000, 3'd0, 16'h0000, 5'b00000);
    ck("A8", 16'h0000, 16'h3C00, 16'h8000, 3'd1, 16'h0000, 5'b00000);
    ck("A8", 16'h0000, 16'h3C00, 16'h8000, 3'd2, 16'h8000, 5'b00000);
    ck("A8", 16'h0000, 16'h3C00, 16'h8000, 3'd3, 16'h0000, 5'b00000);
    ck("A8", 16'h0000, 16'h3C00, 16'h8000, 3'd4, 16'h0000, 5'b00000);

    // ---- A9 -------------------------------------------------------------
    ck("A9.inf", 16'h7C00, 16'h3C00, 16'h3C00, 3'd0, 16'h7C00, 5'b00000);
    ck("A9.inf", 16'hFC00, 16'h3C00, 16'h3C00, 3'd0, 16'hFC00, 5'b00000);
    ck("A9.i0",  16'h7C00, 16'h0000, 16'h0000, 3'd0, 16'h7E00, 5'b10000);
    ck("A9.nan", 16'h3C00, 16'h3C00, 16'h7E00, 3'd0, 16'h7E00, 5'b00000);

    // ---- A2/A4 sanity: 1*1+0, and an ordinary inexact rounding ----------
    ck("unit",   16'h3C00, 16'h3C00, 16'h0000, 3'd0, 16'h3C00, 5'b00000);
    // 2^-10 * 1 + 1 is EXACT (1+2^-10 is representable) -- no flag at all
    ck("exact",  16'h1400, 16'h3C00, 16'h3C00, 3'd0, 16'h3C01, 5'b00000);
    // 2^-11 * 1 + 1 sits exactly halfway between 1 and 1+2^-10
    ck("tie",    16'h1000, 16'h3C00, 16'h3C00, 3'd0, 16'h3C00, 5'b00001);
    ck("tie",    16'h1000, 16'h3C00, 16'h3C00, 3'd4, 16'h3C01, 5'b00001);

    // =====================================================================
    // BEYOND THE TABULATED TEXT.  Each of these records THIS ORACLE'S free
    // choice at a point the contract does not determine.  A disagreement
    // here is a finding about the text, not a defect in the design.
    // =====================================================================

    // D8 tininess detection.  exact = 2047*2^-25, which is BELOW 2^-14 but
    // rounds up to exactly 2^-14 (the smallest normal).
    //   tininess BEFORE rounding -> UF and NX   <-- chosen here
    //   tininess AFTER  rounding -> NX only
    ck("D8.tiny", 16'h0001, 16'h3800, 16'h03FF, 3'd0, 16'h0400, 5'b00011);

    // D12 overflow condition.  exact = 65530, strictly between the largest
    // finite (65504) and 2^16.
    //   IEEE, mode-dependent -> RTZ delivers 65504 with NX and NO OF  <-- chosen
    //   a single fixed threshold at or below 65530 -> OF as well
    ck("D12.rtz", 16'h4E80, 16'h3C00, 16'h7BFF, 3'd1, 16'h7BFF, 5'b00001);
    // the same exact value under RNE is past the midpoint, so it does overflow
    ck("D12.rne", 16'h4E80, 16'h3C00, 16'h7BFF, 3'd0, 16'h7C00, 5'b00101);

    // D10 infinity minus infinity: not covered by A9 at all.
    ck("D10.inf", 16'h7C00, 16'h3C00, 16'hFC00, 3'd0, 16'h7E00, 5'b10000);

    // D9 signalling NaN operand: A9 names only QUIET NaN.
    ck("D9.snan", 16'h7D00, 16'h3C00, 16'h3C00, 3'd0, 16'h7E00, 5'b00000);
    // D9 a NaN addend alongside an invalid product suppresses NV here.
    ck("D9.pri",  16'h7C00, 16'h0000, 16'h7E00, 3'd0, 16'h7E00, 5'b00000);

    // D11 exact zero by CANCELLATION of nonzeros: A8 names only zeros.
    ck("D11.can", 16'h3C00, 16'h3C00, 16'hBC00, 3'd0, 16'h0000, 5'b00000);
    ck("D11.can", 16'h3C00, 16'h3C00, 16'hBC00, 3'd2, 16'h8000, 5'b00000);
    // D11 two zeros of the SAME sign keep it, in every mode.
    ck("D11.neg", 16'h8000, 16'h3C00, 16'h8000, 3'd0, 16'h8000, 5'b00000);
    ck("D11.neg", 16'h8000, 16'h3C00, 16'h8000, 3'd3, 16'h8000, 5'b00000);

    // =====================================================================
    // DIVERGENCE WITNESSES for inbox/d_ai01_TEXT_DEFECTS.md.
    // Each is an input on which two legal readings of the contract give
    // DIFFERENT answers.  The expected value below is THIS ORACLE'S reading;
    // the other reading is named in the comment.  These are the inputs a
    // fixer should run once the text is decided.
    // =====================================================================

    // -- defect 1, A6 table scope.  Divergence is confined to the two
    //    round-to-nearest modes, on opposite halves of the interval.
    // exact = 0.75 * 2^-24, strictly between 2^-25 and 2^-24, under RNE:
    //   A4 correct rounding -> 0x0001   <-- taken
    //   A6 table read literally -> 0x0000
    ck("W1.a6.rne", 16'h0003, 16'h3400, 16'h0000, 3'd0, 16'h0001, 5'b00011);
    // exact = 0.25 * 2^-24, strictly between 0 and 2^-25, under RMM:
    //   A4 correct rounding -> 0x0000   <-- taken
    //   A6 table read literally -> 0x0001
    ck("W2.a6.rmm", 16'h0001, 16'h3400, 16'h0000, 3'd4, 16'h0000, 5'b00011);
    // and the tie point itself, where both readings agree -- this is the
    // evidence that the table is a worked example of correct rounding.
    ck("W3.a6.tie", 16'h0001, 16'h3800, 16'h0000, 3'd0, 16'h0000, 5'b00011);

    // -- defect 2, A5 overflow trigger.  exact = +/- 65530.  Delivered value
    //    is the same under both readings; only the OF bit moves.
    //      IEEE, mode-dependent  -> NX only, 00001   <-- taken
    //      single threshold      -> OF and NX, 00101
    ck("W4.a5.rtz+", 16'h4E80, 16'h3C00, 16'h7BFF, 3'd1, 16'h7BFF, 5'b00001);
    ck("W5.a5.rtz-", 16'hCE80, 16'h3C00, 16'hFBFF, 3'd1, 16'hFBFF, 5'b00001);
    ck("W6.a5.rdn+", 16'h4E80, 16'h3C00, 16'h7BFF, 3'd2, 16'h7BFF, 5'b00001);
    ck("W7.a5.rup-", 16'hCE80, 16'h3C00, 16'hFBFF, 3'd3, 16'hFBFF, 5'b00001);
    // the same exact value in the modes where BOTH readings agree it overflows
    ck("W8.a5.rne-", 16'hCE80, 16'h3C00, 16'hFBFF, 3'd0, 16'hFC00, 5'b00101);
    ck("W9.a5.rdn-", 16'hCE80, 16'h3C00, 16'hFBFF, 3'd2, 16'hFC00, 5'b00101);

    // -- defect 3, tininess.  exact = 2047 * 2^-25, rounds up to the smallest
    //    normal.  Delivered value identical; UF alone moves.
    //      tininess BEFORE rounding -> 00011   <-- taken
    //      tininess AFTER  rounding -> 00001
    ck("W10.tiny",  16'h0001, 16'h3800, 16'h03FF, 3'd0, 16'h0400, 5'b00011);

    $display("clause_check: %0d checks, %0d failures", checks, fails);
    if (fails == 0) $display("ALL CONTRACT-TABULATED CASES REPRODUCED");
    $finish;
  end
endmodule
