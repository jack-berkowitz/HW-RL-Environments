// =============================================================================
// nonequiv_tb.sv -- NON-EQUIVALENCE WITNESSES. Never shipped, never scored.
// =============================================================================
// A perturbation that is secretly a no-op survives and reports the reassuring
// answer; a mutant nobody can kill compresses the score range and proves
// nothing. Both need a concrete point of difference.
//
// Golden and variant are driven with the SAME operation sequence -- the operands
// and operation are a pure function of the index, so each side advances on its
// OWN ready and the two streams are still identical. Results are captured by
// monitors on the transfer edge and compared in order afterwards.
//
// Two things this harness got wrong on first use, both in the harness rather
// than in any wrapper, and both found by its own output:
//   * it polled out_valid_o from the driver instead of capturing on the
//     transfer edge, so a perturbation that DELAYS acceptance made it miss the
//     one-cycle pulse and hang. The ready perturbation produced a watchdog
//     rather than a witness.
//   * it compared only the outputs while out_valid_o was HIGH, so a
//     perturbation licensed to drive the IDLE lines reported "no difference
//     observed -- may be a no-op". The idle-line counter below exists for it.
//
//   $ verilator ... --top-module nonequiv_tb -GVARIANT=n
// =============================================================================
module nonequiv_tb #(parameter int VARIANT = 1);

  logic clk = 1'b0, rst_n = 1'b0;
  always #5 clk = ~clk;

  logic        av, bv, ar, br, aov, bov;
  logic [1:0]  op_a;
  logic        orr = 1'b1;
  logic [31:0] a_res, b_res;
  logic [9:0]  a_cls, b_cls;
  logic [4:0]  a_st,  b_st;

  fp_noncomp i_gold (.clk_i(clk), .rst_ni(rst_n), .operand_a_i(aa), .operand_b_i(ab),
    .op_i(aop), .op_mode_i(amd), .in_valid_i(av), .in_ready_o(ar),
    .result_o(a_res), .class_mask_o(a_cls), .status_o(a_st),
    .out_valid_o(aov), .out_ready_i(orr));

  generate
    case (VARIANT)
      1: fn_c1_extra_latency i_v (.clk_i(clk), .rst_ni(rst_n), .operand_a_i(ba), .operand_b_i(bb), .op_i(bop), .op_mode_i(bmd), .in_valid_i(bv), .in_ready_o(br), .result_o(b_res), .class_mask_o(b_cls), .status_o(b_st), .out_valid_o(bov), .out_ready_i(orr));
      2: fn_c2_garbage_when_invalid i_v (.clk_i(clk), .rst_ni(rst_n), .operand_a_i(ba), .operand_b_i(bb), .op_i(bop), .op_mode_i(bmd), .in_valid_i(bv), .in_ready_o(br), .result_o(b_res), .class_mask_o(b_cls), .status_o(b_st), .out_valid_o(bov), .out_ready_i(orr));
      3: fn_c3_ready_withheld i_v (.clk_i(clk), .rst_ni(rst_n), .operand_a_i(ba), .operand_b_i(bb), .op_i(bop), .op_mode_i(bmd), .in_valid_i(bv), .in_ready_o(br), .result_o(b_res), .class_mask_o(b_cls), .status_o(b_st), .out_valid_o(bov), .out_ready_i(orr));
      4: fn_c4_garbage_result_on_classify i_v (.clk_i(clk), .rst_ni(rst_n), .operand_a_i(ba), .operand_b_i(bb), .op_i(bop), .op_mode_i(bmd), .in_valid_i(bv), .in_ready_o(br), .result_o(b_res), .class_mask_o(b_cls), .status_o(b_st), .out_valid_o(bov), .out_ready_i(orr));
      5: fn_c5_garbage_class_when_not_classify i_v (.clk_i(clk), .rst_ni(rst_n), .operand_a_i(ba), .operand_b_i(bb), .op_i(bop), .op_mode_i(bmd), .in_valid_i(bv), .in_ready_o(br), .result_o(b_res), .class_mask_o(b_cls), .status_o(b_st), .out_valid_o(bov), .out_ready_i(orr));
      11: fn_m1_classify_subnormal_as_zero i_v (.clk_i(clk), .rst_ni(rst_n), .operand_a_i(ba), .operand_b_i(bb), .op_i(bop), .op_mode_i(bmd), .in_valid_i(bv), .in_ready_o(br), .result_o(b_res), .class_mask_o(b_cls), .status_o(b_st), .out_valid_o(bov), .out_ready_i(orr));
      12: fn_m2_ieee2019_minmax i_v (.clk_i(clk), .rst_ni(rst_n), .operand_a_i(ba), .operand_b_i(bb), .op_i(bop), .op_mode_i(bmd), .in_valid_i(bv), .in_ready_o(br), .result_o(b_res), .class_mask_o(b_cls), .status_o(b_st), .out_valid_o(bov), .out_ready_i(orr));
      13: fn_m3_minmax_ignores_zero_sign i_v (.clk_i(clk), .rst_ni(rst_n), .operand_a_i(ba), .operand_b_i(bb), .op_i(bop), .op_mode_i(bmd), .in_valid_i(bv), .in_ready_o(br), .result_o(b_res), .class_mask_o(b_cls), .status_o(b_st), .out_valid_o(bov), .out_ready_i(orr));
      14: fn_m4_feq_is_signalling i_v (.clk_i(clk), .rst_ni(rst_n), .operand_a_i(ba), .operand_b_i(bb), .op_i(bop), .op_mode_i(bmd), .in_valid_i(bv), .in_ready_o(br), .result_o(b_res), .class_mask_o(b_cls), .status_o(b_st), .out_valid_o(bov), .out_ready_i(orr));
      15: fn_m5_sgnjx_becomes_sgnj i_v (.clk_i(clk), .rst_ni(rst_n), .operand_a_i(ba), .operand_b_i(bb), .op_i(bop), .op_mode_i(bmd), .in_valid_i(bv), .in_ready_o(br), .result_o(b_res), .class_mask_o(b_cls), .status_o(b_st), .out_valid_o(bov), .out_ready_i(orr));
      16: fn_m6_sgnj_canonicalises_nan i_v (.clk_i(clk), .rst_ni(rst_n), .operand_a_i(ba), .operand_b_i(bb), .op_i(bop), .op_mode_i(bmd), .in_valid_i(bv), .in_ready_o(br), .result_o(b_res), .class_mask_o(b_cls), .status_o(b_st), .out_valid_o(bov), .out_ready_i(orr));
      default: initial $fatal(1, "no such VARIANT");
    endcase
  endgenerate

  localparam int NV_ = 12;
  logic [31:0] pool [NV_] = '{
    32'h0000_0000, 32'h8000_0000, 32'h0000_0001, 32'h8000_0001,
    32'h0080_0000, 32'h3F80_0000, 32'hBF80_0000, 32'h7F80_0000,
    32'hFF80_0000, 32'h7FC0_0000, 32'hFFD5_A5A5, 32'h7FA0_0000 };

  localparam int NCOMBO = 7;
  localparam int NOPS   = NV_ * NV_ * NCOMBO;

  function automatic logic [1:0] seq_op(input int n);
    case (n % NCOMBO) 0,1: return 2'd0; 2,3: return 2'd1; 4,5: return 2'd2; default: return 2'd3; endcase
  endfunction
  function automatic logic [2:0] seq_md(input int n);
    case (n % NCOMBO) 0: return 3'd0; 1: return 3'd2; 2: return 3'd0; 3: return 3'd1;
                      4: return 3'd1; 5: return 3'd2; default: return 3'd0; endcase
  endfunction
  function automatic logic [31:0] seq_a(input int n); return pool[(n / NCOMBO) % NV_]; endfunction
  function automatic logic [31:0] seq_b(input int n); return pool[(n / NCOMBO) / NV_]; endfunction

  int unsigned an = 0, bn = 0, cyc = 0;
  assign op_a = seq_op(an);

  // each side drives its own copy of the same stream
  logic [31:0] aa, ab, ba, bb;
  logic [1:0]  aop, bop;
  logic [2:0]  amd, bmd;
  assign aa = seq_a(an); assign ab = seq_b(an); assign aop = seq_op(an); assign amd = seq_md(an);
  assign ba = seq_a(bn); assign bb = seq_b(bn); assign bop = seq_op(bn); assign bmd = seq_md(bn);
  // Periodic idle windows. Without them the pipeline never goes idle under a
  // permanently-ready sink, out_valid_o is high on almost every cycle, and a
  // perturbation licensed to drive the IDLE lines has nowhere to show itself --
  // it reported "no difference observed" purely for want of an idle cycle.
  wire pause = (cyc % 16) < 5;
  assign av = (an < NOPS) && !rst_n_low && !pause;
  assign bv = (bn < NOPS) && !rst_n_low && !pause;
  wire rst_n_low = !rst_n;

  always @(posedge clk) if (rst_n) begin
    cyc <= cyc + 1;
    if (av && ar) an <= an + 1;
    if (bv && br) bn <= bn + 1;
  end

  // ---- monitors: capture on the TRANSFER edge, never by polling -------------
  typedef struct packed { logic [31:0] r; logic [9:0] c; logic [4:0] s; int unsigned t; } rec_t;
  rec_t aq [$], bq [$];
  int unsigned a_idle_chg = 0, b_idle_chg = 0;
  logic [46:0] a_prev_idle, b_prev_idle;

  always @(posedge clk) if (rst_n) begin
    if (aov && orr) aq.push_back('{a_res, a_cls, a_st, cyc});
    if (bov && orr) bq.push_back('{b_res, b_cls, b_st, cyc});
    if (!aov) begin
      if ({a_res, a_cls, a_st} !== a_prev_idle) a_idle_chg <= a_idle_chg + 1;
      a_prev_idle <= {a_res, a_cls, a_st};
    end
    if (!bov) begin
      if ({b_res, b_cls, b_st} !== b_prev_idle) b_idle_chg <= b_idle_chg + 1;
      b_prev_idle <= {b_res, b_cls, b_st};
    end
  end

  initial begin
    repeat (4) @(posedge clk);
    @(negedge clk) rst_n = 1'b1;
    while ((aq.size() < NOPS || bq.size() < NOPS) && cyc < 200000) @(posedge clk);
    begin
      automatic int n = (aq.size() < bq.size()) ? aq.size() : bq.size();
      automatic int fv = -1, ft = -1, nv = 0, nt = 0;
      for (int i = 0; i < n; i++) begin
        if (aq[i].r !== bq[i].r || aq[i].c !== bq[i].c || aq[i].s !== bq[i].s) begin
          if (fv < 0) fv = i;
          nv++;
        end
        if (aq[i].t !== bq[i].t) begin if (ft < 0) ft = i; nt++; end
      end
      $display("VARIANT %0d", VARIANT);
      $display("  operations compared : %0d", n);
      if (fv >= 0)
        $display("  WITNESS value  @op %0d : op=%0d mode=%0d a=%h b=%h | golden res=%h cls=%b st=%b | variant res=%h cls=%b st=%b",
                 fv, seq_op(fv), seq_md(fv), seq_a(fv), seq_b(fv),
                 aq[fv].r, aq[fv].c, aq[fv].s, bq[fv].r, bq[fv].c, bq[fv].s);
      else $display("  value outputs identical on all %0d operations", n);
      if (ft >= 0)
        $display("  WITNESS timing @op %0d : golden cycle %0d, variant cycle %0d (%0d ops differ)",
                 ft, aq[ft].t, bq[ft].t, nt);
      else $display("  result timing identical on all %0d operations", n);
      $display("  idle-line changes   : golden=%0d variant=%0d", a_idle_chg, b_idle_chg);
      if (fv >= 0 || ft >= 0 || a_idle_chg !== b_idle_chg)
        $display("  NON-EQUIVALENCE ESTABLISHED (%0d value, %0d timing, idle %0d vs %0d)",
                 nv, nt, a_idle_chg, b_idle_chg);
      else
        $display("  *** NO DIFFERENCE OBSERVED -- this wrapper may be a no-op ***");
    end
    $finish;
  end
  initial begin #500_000_000; $display("  watchdog"); $finish; end
endmodule
