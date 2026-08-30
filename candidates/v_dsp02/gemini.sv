module fp_noncomp_tb;

  // ---------------------------------------------------------------------------
  // PROVIDED PLUMBING -- issues operations, checks nothing.
  // ---------------------------------------------------------------------------
  logic clk;
  initial begin clk = 1'b0; forever #5 clk = ~clk; end

  logic rst_n;
  initial rst_n = 1'b0;

  task automatic bfm_reset(input int cycles = 4);
    @(negedge clk);
    rst_n = 1'b0;
    repeat (cycles) @(posedge clk);
    @(negedge clk);
    rst_n = 1'b1;
  endtask

  logic [31:0] operand_a_i;
  logic [31:0] operand_b_i;
  logic [1:0]  op_i;
  logic [2:0]  op_mode_i;
  logic        in_valid_i;
  logic        in_ready_o;

  logic [31:0] result_o;
  logic [9:0]  class_mask_o;
  logic [4:0]  status_o;
  logic        out_valid_o;
  logic        out_ready_i;

  fp_noncomp dut (
      .clk_i(clk),
      .rst_ni(rst_n),
      .operand_a_i(operand_a_i),
      .operand_b_i(operand_b_i),
      .op_i(op_i),
      .op_mode_i(op_mode_i),
      .in_valid_i(in_valid_i),
      .in_ready_o(in_ready_o),
      .result_o(result_o),
      .class_mask_o(class_mask_o),
      .status_o(status_o),
      .out_valid_o(out_valid_o),
      .out_ready_i(out_ready_i)
  );

  task automatic bfm_issue(input logic [31:0] a,
                           input logic [31:0] b,
                           input logic [1:0]  op,
                           input logic [2:0]  mode);
    @(negedge clk);
    operand_a_i = a;
    operand_b_i = b;
    op_i        = op;
    op_mode_i   = mode;
    in_valid_i  = 1'b1;
    forever begin
      @(posedge clk);
      if (in_ready_o) break;
    end
  endtask

  task automatic bfm_idle();
    @(negedge clk);
    in_valid_i = 1'b0;
  endtask

  task automatic bfm_out_ready(input logic value);
    @(negedge clk);
    out_ready_i = value;
  endtask

  initial begin
    #200_000_000;
    $display("RESULT: FAIL (watchdog: no forward progress)");
    $finish;
  end

  // ---------------------------------------------------------------------------
  // TESTBENCH LOGIC
  // ---------------------------------------------------------------------------

  typedef struct {
      logic [31:0] result;
      logic [9:0]  mask;
      logic [4:0]  status;
      logic [1:0]  op;
      bit          chk_res;
      bit          chk_mask;
  } expected_val_t;

  expected_val_t expected_q[$];

  // The Oracle
  function automatic expected_val_t calc_expected(logic [31:0] a, logic [31:0] b, logic [1:0] op, logic [2:0] mode);
      expected_val_t exp;
      logic a_sign, b_sign;
      logic [7:0] a_exp, b_exp;
      logic [22:0] a_frac, b_frac;
      logic a_nan, b_nan, a_snan, b_snan, a_qnan, b_qnan;
      logic a_inf, b_inf, a_zero, b_zero, a_sub, b_sub, a_norm, b_norm;
      logic minmax_a_lt_b, cmp_a_lt_b, is_eq;

      exp.result   = 32'd0;
      exp.mask     = 10'd0;
      exp.status   = 5'd0;
      exp.op       = op;
      exp.chk_res  = 1;
      exp.chk_mask = 0;

      a_sign = a[31]; a_exp = a[30:23]; a_frac = a[22:0];
      b_sign = b[31]; b_exp = b[30:23]; b_frac = b[22:0];

      a_nan = (a_exp == 8'hFF) && (a_frac != 0);
      b_nan = (b_exp == 8'hFF) && (b_frac != 0);

      a_snan = a_nan && (a_frac[22] == 0);
      b_snan = b_nan && (b_frac[22] == 0);

      a_qnan = a_nan && (a_frac[22] == 1);
      b_qnan = b_nan && (b_frac[22] == 1);

      a_inf = (a_exp == 8'hFF) && (a_frac == 0);
      b_inf = (b_exp == 8'hFF) && (b_frac == 0);

      a_zero = (a_exp == 0) && (a_frac == 0);
      b_zero = (b_exp == 0) && (b_frac == 0);

      a_sub = (a_exp == 0) && (a_frac != 0);
      b_sub = (b_exp == 0) && (b_frac != 0);

      a_norm = (a_exp > 0) && (a_exp < 8'hFF);
      b_norm = (b_exp > 0) && (b_exp < 8'hFF);

      is_eq = (a[30:0] == b[30:0] || (a_zero && b_zero)) && (a_sign == b_sign || (a_zero && b_zero));

      // Separate less-than semantics for MINMAX (S3) vs CMP (S10)
      if (a_zero && b_zero) begin
          minmax_a_lt_b = (a_sign && !b_sign); // S3: -0.0 < +0.0
          cmp_a_lt_b    = 1'b0;                // S10: -0.0 == +0.0
      end else if (a_sign != b_sign) begin
          minmax_a_lt_b = a_sign;
          cmp_a_lt_b    = a_sign;
      end else begin
          if (a_sign) begin
              minmax_a_lt_b = (a[30:0] > b[30:0]);
              cmp_a_lt_b    = (a[30:0] > b[30:0]);
          end else begin
              minmax_a_lt_b = (a[30:0] < b[30:0]);
              cmp_a_lt_b    = (a[30:0] < b[30:0]);
          end
      end

      case(op)
          2'd0: begin // SGNJ
              exp.result[30:0] = a[30:0];
              if (mode == 3'd0) exp.result[31] = b_sign;
              else if (mode == 3'd1) exp.result[31] = ~b_sign;
              else if (mode == 3'd2) exp.result[31] = a_sign ^ b_sign;
          end
          2'd1: begin // MINMAX
              exp.status[4] = (a_snan || b_snan); // S6: NV iff signaling NaN
              if (a_nan && b_nan) begin
                  exp.result = 32'h7FC0_0000; // S5: Canonical QNaN
              end else if (a_nan) begin
                  exp.result = b; // S4: exactly one NaN -> other operand
              end else if (b_nan) begin
                  exp.result = a;
              end else begin
                  if (mode == 3'd0) exp.result = minmax_a_lt_b ? a : b;
                  else if (mode == 3'd1) exp.result = minmax_a_lt_b ? b : a;
              end
          end
          2'd2: begin // CMP
              if (mode == 3'd0) begin // LE
                  exp.status[4] = (a_nan || b_nan); // S8: LE is signaling
                  exp.result = (!a_nan && !b_nan && (cmp_a_lt_b || is_eq)) ? 32'h1 : 32'h0;
              end else if (mode == 3'd1) begin // LT
                  exp.status[4] = (a_nan || b_nan); // S8: LT is signaling
                  exp.result = (!a_nan && !b_nan && cmp_a_lt_b) ? 32'h1 : 32'h0;
              end else if (mode == 3'd2) begin // EQ
                  exp.status[4] = (a_snan || b_snan); // S9: EQ is quiet
                  exp.result = (!a_nan && !b_nan && is_eq) ? 32'h1 : 32'h0;
              end
          end
          2'd3: begin // CLASSIFY
              exp.chk_res  = 0;
              exp.chk_mask = 1;
              exp.mask[0] = a_sign && a_inf;
              exp.mask[1] = a_sign && a_norm;
              exp.mask[2] = a_sign && a_sub;
              exp.mask[3] = a_sign && a_zero;
              exp.mask[4] = !a_sign && a_zero;
              exp.mask[5] = !a_sign && a_sub;
              exp.mask[6] = !a_sign && a_norm;
              exp.mask[7] = !a_sign && a_inf;
              exp.mask[8] = a_snan;
              exp.mask[9] = a_qnan;
          end
      endcase

      return exp;
  endfunction

  task automatic issue_and_expect(logic [31:0] a, logic [31:0] b, logic [1:0] op, logic [2:0] mode);
      automatic expected_val_t exp;
      exp = calc_expected(a, b, op, mode);
      expected_q.push_back(exp);
      bfm_issue(a, b, op, mode);
  endtask

  // Backpressure thread for H3 and H2 check coverage
  initial begin
      out_ready_i = 1'b1;
      wait(rst_n === 1'b1);
      forever begin
          repeat (35) @(posedge clk);
          bfm_out_ready(1'b0);
          repeat (25) @(posedge clk); // More than 20 cycles as required by H3 checks
          bfm_out_ready(1'b1);
      end
  end

  // Monitor thread
  always @(posedge clk) begin
      if (rst_n && out_valid_o && out_ready_i) begin
          if (expected_q.size() == 0) begin
              $display("RESULT: FAIL (H2 - Unexpected result delivered)");
              $finish;
          end
          
          begin
              automatic expected_val_t exp = expected_q.pop_front();
              
              if (status_o[3:0] !== 4'b0000) begin
                  $display("RESULT: FAIL (S14 - Flags DZ/OF/UF/NX must be 0)");
                  $finish;
              end
              
              if (exp.chk_res && result_o !== exp.result) begin
                  if (exp.op == 2'd0) $display("RESULT: FAIL (S1/A1 - SGNJ incorrect result)");
                  else if (exp.op == 2'd1) $display("RESULT: FAIL (S3/S4/S5/A2 - MINMAX incorrect result)");
                  else if (exp.op == 2'd2) $display("RESULT: FAIL (S7/S10 - CMP incorrect result)");
                  else $display("RESULT: FAIL (Unknown result mismatch)");
                  $finish;
              end
              
              if (exp.chk_mask && class_mask_o !== exp.mask) begin
                  $display("RESULT: FAIL (S12 - CLASSIFY incorrect mask)");
                  $finish;
              end
              
              if (status_o[4] !== exp.status[4]) begin
                  if (exp.op == 2'd0) $display("RESULT: FAIL (S2 - SGNJ should not raise flags)");
                  else if (exp.op == 2'd1) $display("RESULT: FAIL (S6 - MINMAX NV flag incorrect)");
                  else if (exp.op == 2'd2) $display("RESULT: FAIL (S8/S9/S11 - CMP NV flag incorrect)");
                  else if (exp.op == 2'd3) $display("RESULT: FAIL (S13 - CLASSIFY should not raise flags)");
                  $finish;
              end
          end
      end
  end

  logic [31:0] test_vals [] = '{
      32'h0000_0000, // +0.0
      32'h8000_0000, // -0.0
      32'h3f80_0000, // +1.0
      32'hbf80_0000, // -1.0
      32'h7f80_0000, // +inf
      32'hff80_0000, // -inf
      32'h0000_0001, // +min_sub
      32'h807f_ffff, // -max_sub
      32'h0080_0000, // +min_norm
      32'h7f7f_ffff, // +max_norm
      32'h7fc0_0000, // canonical qNaN
      32'h7fc0_0001, // another qNaN
      32'h7f80_0001, // sNaN
      32'hff80_0001  // -sNaN
  };

  initial begin
      operand_a_i = 32'd0;
      operand_b_i = 32'd0;
      op_i        = 2'd0;
      op_mode_i   = 3'd0;
      in_valid_i  = 1'b0;

      bfm_reset();

      // Exhaustively test all pairs, operations, and modes
      for (int i = 0; i < test_vals.size(); i++) begin
          for (int j = 0; j < test_vals.size(); j++) begin
              automatic logic [31:0] a = test_vals[i];
              automatic logic [31:0] b = test_vals[j];
              
              for (int m = 0; m < 3; m++) issue_and_expect(a, b, 2'd0, m[2:0]); // SGNJ
              for (int m = 0; m < 2; m++) issue_and_expect(a, b, 2'd1, m[2:0]); // MINMAX
              for (int m = 0; m < 3; m++) issue_and_expect(a, b, 2'd2, m[2:0]); // CMP
              issue_and_expect(a, b, 2'd3, 3'd0);                               // CLASSIFY
          end
      end

      bfm_idle();

      // Wait for completion (H2 / S16 check indirectly)
      begin
          automatic int wait_count = 0;
          while(expected_q.size() > 0) begin
              @(posedge clk);
              wait_count++;
              if (wait_count > 100_000) begin
                  $display("RESULT: FAIL (H2 - Results not delivered / stuck in pipeline)");
                  $finish;
              end
          end
      end
      
      repeat(20) @(posedge clk);

      // S15 Check: Pre-reset transactions discarded and output stays low immediately after reset
      expected_q.delete(); 
      bfm_issue(test_vals[0], test_vals[1], 2'd0, 3'd0);
      bfm_issue(test_vals[2], test_vals[3], 2'd1, 3'd0);
      
      bfm_reset();
      
      @(posedge clk);
      if (out_valid_o) begin
          $display("RESULT: FAIL (S15 - out_valid_o high immediately after reset release)");
          $finish;
      end
      
      repeat (20) begin
          @(posedge clk);
          if (out_valid_o) begin
              $display("RESULT: FAIL (S15 - Pre-reset transaction survived reset)");
              $finish;
          end
      end

      $display("RESULT: PASS");
      $finish;
  end

endmodule