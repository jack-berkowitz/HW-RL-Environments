module fp_noncomp_tb;

  // ---- clock ----
  logic clk;
  initial begin clk = 1'b0; forever #5 clk = ~clk; end

  // ---- reset ----
  logic rst_n;
  initial rst_n = 1'b0;

  // ---- DUT signals ----
  logic [31:0] operand_a_i, operand_b_i;
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
    .clk_i(clk), .rst_ni(rst_n),
    .operand_a_i(operand_a_i), .operand_b_i(operand_b_i),
    .op_i(op_i), .op_mode_i(op_mode_i),
    .in_valid_i(in_valid_i), .in_ready_o(in_ready_o),
    .result_o(result_o), .class_mask_o(class_mask_o), .status_o(status_o),
    .out_valid_o(out_valid_o), .out_ready_i(out_ready_i)
  );

  // ---- BFM ----
  task automatic bfm_reset(input int cycles = 4);
    @(negedge clk);
    rst_n = 1'b0;
    repeat (cycles) @(posedge clk);
    @(negedge clk);
    rst_n = 1'b1;
  endtask

  task automatic bfm_issue(input logic [31:0] a, input logic [31:0] b,
                           input logic [1:0] op, input logic [2:0] mode);
    @(negedge clk);
    operand_a_i = a; operand_b_i = b; op_i = op; op_mode_i = mode;
    in_valid_i = 1'b1;
    forever begin
      @(posedge clk);
      if (in_ready_o) break;
    end
  endtask

  task automatic bfm_idle();
    @(negedge clk);
    in_valid_i = 1'b0;
  endtask

  task automatic bfm_out_ready(input logic v);
    @(negedge clk);
    out_ready_i = v;
  endtask

  // ---- Watchdog (S16) ----
  initial begin
    #200_000_000;
    $display("RESULT: FAIL (watchdog: no forward progress)");
    $finish;
  end

  // ---- Reference helpers ----
  function automatic logic is_nan(input logic [31:0] x);
    return (x[30:23] == 8'hFF) && (x[22:0] != 0);
  endfunction
  function automatic logic is_snan(input logic [31:0] x);
    return is_nan(x) && (x[22] == 0);
  endfunction
  function automatic logic is_zero_f(input logic [31:0] x);
    return (x[30:0] == 31'd0);
  endfunction
  function automatic logic is_inf_f(input logic [31:0] x);
    return (x[30:23] == 8'hFF) && (x[22:0] == 0);
  endfunction
  function automatic logic is_subn_f(input logic [31:0] x);
    return (x[30:23] == 8'h00) && (x[22:0] != 0);
  endfunction
  // Order-preserving key: -0.0 < +0.0 (for MINMAX)
  function automatic logic [31:0] fp_key(input logic [31:0] x);
    return x[31] ? ~x : (x | 32'h8000_0000);
  endfunction
  // Numeric comparison: -0.0 == +0.0 (for CMP)
  function automatic int fp_cmp(input logic [31:0] a, input logic [31:0] b);
    logic [31:0] ka, kb;
    if (is_zero_f(a) && is_zero_f(b)) return 0;
    ka = fp_key(a); kb = fp_key(b);
    if (ka < kb) return -1;
    else if (ka > kb) return 1;
    else return 0;
  endfunction
  function automatic logic [9:0] classify(input logic [31:0] a);
    logic [9:0] m;
    m = 10'd0;
    if (is_nan(a)) begin
      if (a[22]) m[9] = 1'b1; else m[8] = 1'b1;
    end else if (is_inf_f(a)) begin
      if (a[31]) m[0] = 1'b1; else m[7] = 1'b1;
    end else if (is_zero_f(a)) begin
      if (a[31]) m[3] = 1'b1; else m[4] = 1'b1;
    end else if (is_subn_f(a)) begin
      if (a[31]) m[2] = 1'b1; else m[5] = 1'b1;
    end else begin
      if (a[31]) m[1] = 1'b1; else m[6] = 1'b1;
    end
    return m;
  endfunction

  // ---- Reference model ----
  task automatic predict(
    input  logic [31:0] a,
    input  logic [31:0] b,
    input  logic [1:0]  op,
    input  logic [2:0]  mode,
    output logic [31:0] exp_result,
    output logic [9:0]  exp_class,
    output logic [4:0]  exp_status
  );
    logic a_nan, b_nan, sa, sb;
    logic [31:0] ka, kb;
    exp_result = 32'd0;
    exp_class  = 10'd0;
    exp_status = 5'd0;
    a_nan = is_nan(a);  b_nan = is_nan(b);
    sa    = is_snan(a); sb    = is_snan(b);
    case (op)
      2'd0: begin // SGNJ
        case (mode)
          3'd0: exp_result = {b[31],  a[30:0]};
          3'd1: exp_result = {~b[31], a[30:0]};
          3'd2: exp_result = {a[31] ^ b[31], a[30:0]};
          default: exp_result = 32'd0;
        endcase
      end
      2'd1: begin // MINMAX
        if (sa || sb) exp_status[4] = 1'b1;
        if (a_nan && b_nan)  exp_result = 32'h7FC0_0000;
        else if (a_nan)      exp_result = b;
        else if (b_nan)      exp_result = a;
        else begin
          ka = fp_key(a); kb = fp_key(b);
          if (mode == 3'd0) exp_result = (ka <= kb) ? a : b;
          else              exp_result = (ka >= kb) ? a : b;
        end
      end
      2'd2: begin // CMP
        case (mode)
          3'd0: begin // <=  (signalling)
            if (a_nan || b_nan) begin
              exp_result = 32'd0; exp_status[4] = 1'b1;
            end else begin
              exp_result = (fp_cmp(a, b) <= 0) ? 32'd1 : 32'd0;
            end
          end
          3'd1: begin // <  (signalling)
            if (a_nan || b_nan) begin
              exp_result = 32'd0; exp_status[4] = 1'b1;
            end else begin
              exp_result = (fp_cmp(a, b) < 0) ? 32'd1 : 32'd0;
            end
          end
          3'd2: begin // ==  (quiet)
            if (a_nan || b_nan) begin
              exp_result = 32'd0;
              if (sa || sb) exp_status[4] = 1'b1;
            end else begin
              exp_result = (fp_cmp(a, b) == 0) ? 32'd1 : 32'd0;
            end
          end
          default: exp_result = 32'd0;
        endcase
      end
      2'd3: exp_class = classify(a);
    endcase
  endtask

  // ---- Scoreboard ----
  logic [31:0] exp_result_q[$];
  logic [9:0]  exp_class_q[$];
  logic [4:0]  exp_status_q[$];
  logic [1:0]  exp_op_q[$];
  int errors = 0;
  int checks = 0;
  logic expect_no_output = 1'b0;

  always @(posedge clk) begin
    if (rst_n && out_valid_o && out_ready_i) begin
      if (expect_no_output) begin
        $display("FAIL S15: result appeared after reset (discard violation) r=%h c=%b s=%b",
                 result_o, class_mask_o, status_o);
        errors++;
      end else if (exp_result_q.size() == 0) begin
        $display("FAIL H2: unexpected output r=%h c=%b s=%b",
                 result_o, class_mask_o, status_o);
        errors++;
      end else begin
        automatic logic [31:0] e_res = exp_result_q.pop_front();
        automatic logic [9:0]  e_cls = exp_class_q.pop_front();
        automatic logic [4:0]  e_sts = exp_status_q.pop_front();
        automatic logic [1:0]  e_op  = exp_op_q.pop_front();
        checks++;
        if (e_op == 2'd3) begin
          if (class_mask_o !== e_cls) begin
            $display("FAIL S12: classify mask=%b expected=%b", class_mask_o, e_cls);
            errors++;
          end
          if ($countones(class_mask_o) != 1) begin
            $display("FAIL S12: classify mask not one-hot: %b", class_mask_o);
            errors++;
          end
          if (status_o !== 5'd0) begin
            $display("FAIL S13/S14: classify status=%b expected=0", status_o);
            errors++;
          end
        end else begin
          if (result_o !== e_res) begin
            $display("FAIL S-result (op=%0d): result=%h expected=%h",
                     e_op, result_o, e_res);
            errors++;
          end
          if (status_o !== e_sts) begin
            $display("FAIL S14 (op=%0d): status=%b expected=%b",
                     e_op, status_o, e_sts);
            errors++;
          end
        end
      end
    end
  end

  task automatic do_op(input logic [31:0] a, input logic [31:0] b,
                       input logic [1:0] op, input logic [2:0] mode);
    logic [31:0] r; logic [9:0] c; logic [4:0] s;
    predict(a, b, op, mode, r, c, s);
    exp_result_q.push_back(r);
    exp_class_q.push_back(c);
    exp_status_q.push_back(s);
    exp_op_q.push_back(op);
    bfm_issue(a, b, op, mode);
  endtask

  task automatic wait_drain(input int max_cycles = 2000);
    int c;
    c = 0;
    while (exp_result_q.size() > 0 && c < max_cycles) begin
      @(posedge clk);
      c++;
    end
    if (exp_result_q.size() > 0) begin
      $display("FAIL H2: queue not drained after %0d cycles (%0d entries)",
               max_cycles, exp_result_q.size());
      errors++;
      exp_result_q.delete(); exp_class_q.delete();
      exp_status_q.delete(); exp_op_q.delete();
    end
    repeat (2) @(posedge clk);
  endtask

  // ---- Main sequence ----
  initial begin
    operand_a_i = 32'd0; operand_b_i = 32'd0;
    op_i = 2'd0; op_mode_i = 3'd0;
    in_valid_i = 1'b0; out_ready_i = 1'b1;

    bfm_reset();

    // S15: out_valid_o low on first cycle after reset
    @(posedge clk);
    if (out_valid_o) begin
      $display("FAIL S15: out_valid_o high on first cycle after reset");
      errors++;
    end

    // ---- SGNJ (S1, S2) ----
    do_op(32'h3F80_0000, 32'hBF80_0000, 2'd0, 3'd0); // sign from b -> -1.0
    do_op(32'h3F80_0000, 32'h3F80_0000, 2'd0, 3'd1); // inverted -> -1.0
    do_op(32'h3F80_0000, 32'hBF80_0000, 2'd0, 3'd2); // XOR -> -1.0
    do_op(32'hBF80_0000, 32'hBF80_0000, 2'd0, 3'd2); // XOR -> +1.0
    do_op(32'h7FA1_2345, 32'h3F80_0000, 2'd0, 3'd0); // qNaN, b=+  -> payload kept, sign 0
    do_op(32'h7FA1_2345, 32'hBF80_0000, 2'd0, 3'd0); // qNaN, b=-  -> payload kept, sign 1
    do_op(32'h7F80_0001, 32'h3F80_0000, 2'd0, 3'd0); // sNaN, b=+  -> payload kept, sign 0
    do_op(32'h7F80_0001, 32'hBF80_0000, 2'd0, 3'd1); // sNaN, b=-, inverted -> sign 0
    wait_drain();

    // ---- MINMAX (S3-S6) ----
    do_op(32'h3F80_0000, 32'h4000_0000, 2'd1, 3'd0); // min 1.0
    do_op(32'h3F80_0000, 32'h4000_0000, 2'd1, 3'd1); // max 2.0
    do_op(32'h4000_0000, 32'h3F80_0000, 2'd1, 3'd0); // min 1.0 (rev)
    do_op(32'h4000_0000, 32'h3F80_0000, 2'd1, 3'd1); // max 2.0 (rev)
    do_op(32'hBF80_0000, 32'h3F80_0000, 2'd1, 3'd0); // min -1.0
    do_op(32'hBF80_0000, 32'h3F80_0000, 2'd1, 3'd1); // max 1.0
    // -0.0 < +0.0 (S3)
    do_op(32'h8000_0000, 32'h0000_0000, 2'd1, 3'd0); // min -0.0
    do_op(32'h8000_0000, 32'h0000_0000, 2'd1, 3'd1); // max +0.0
    do_op(32'h0000_0000, 32'h8000_0000, 2'd1, 3'd0); // min -0.0 (rev)
    do_op(32'h0000_0000, 32'h8000_0000, 2'd1, 3'd1); // max +0.0 (rev)
    // NaN (S4, S5, S6)
    do_op(32'h7FC0_0000, 32'h3F80_0000, 2'd1, 3'd0); // min(qNaN,1) = 1, NV=0
    do_op(32'h7FC0_0000, 32'h3F80_0000, 2'd1, 3'd1); // max(qNaN,1) = 1, NV=0
    do_op(32'h3F80_0000, 32'h7FC0_0000, 2'd1, 3'd0); // min(1,qNaN) = 1, NV=0
    do_op(32'h7F80_0001, 32'h3F80_0000, 2'd1, 3'd0); // min(sNaN,1) = 1, NV=1
    do_op(32'h7F80_0001, 32'h3F80_0000, 2'd1, 3'd1); // max(sNaN,1) = 1, NV=1
    do_op(32'h7FC0_0000, 32'h7F80_0001, 2'd1, 3'd0); // min(qNaN,sNaN) = canon, NV=1
    do_op(32'h7FC0_0000, 32'h7FC1_0000, 2'd1, 3'd0); // min(qNaN,qNaN) = canon, NV=0
    do_op(32'hFF80_0000, 32'h3F80_0000, 2'd1, 3'd0); // min(-inf,1) = -inf
    do_op(32'h7F80_0000, 32'h3F80_0000, 2'd1, 3'd1); // max(+inf,1) = +inf
    wait_drain();

    // ---- CMP (S7-S11) ----
    do_op(32'h3F80_0000, 32'h4000_0000, 2'd2, 3'd0); // 1<=2 -> 1
    do_op(32'h4000_0000, 32'h3F80_0000, 2'd2, 3'd0); // 2<=1 -> 0
    do_op(32'h3F80_0000, 32'h3F80_0000, 2'd2, 3'd0); // 1<=1 -> 1
    do_op(32'h3F80_0000, 32'h4000_0000, 2'd2, 3'd1); // 1<2  -> 1
    do_op(32'h4000_0000, 32'h3F80_0000, 2'd2, 3'd1); // 2<1  -> 0
    do_op(32'h3F80_0000, 32'h3F80_0000, 2'd2, 3'd1); // 1<1  -> 0
    do_op(32'h3F80_0000, 32'h3F80_0000, 2'd2, 3'd2); // 1==1 -> 1
    do_op(32'h3F80_0000, 32'h4000_0000, 2'd2, 3'd2); // 1==2 -> 0
    // -0.0 == +0.0 (S10)
    do_op(32'h8000_0000, 32'h0000_0000, 2'd2, 3'd2); // ==  -> 1
    do_op(32'h8000_0000, 32'h0000_0000, 2'd2, 3'd0); // <=  -> 1
    do_op(32'h8000_0000, 32'h0000_0000, 2'd2, 3'd1); // <   -> 0
    // NaN (S8, S9)
    do_op(32'h7FC0_0000, 32'h3F80_0000, 2'd2, 3'd0); // qNaN<=1 -> 0,NV=1
    do_op(32'h7FC0_0000, 32'h3F80_0000, 2'd2, 3'd1); // qNaN<1  -> 0,NV=1
    do_op(32'h7FC0_0000, 32'h3F80_0000, 2'd2, 3'd2); // qNaN==1 -> 0,NV=0
    do_op(32'h7F80_0001, 32'h3F80_0000, 2'd2, 3'd0); // sNaN<=1 -> 0,NV=1
    do_op(32'h7F80_0001, 32'h3F80_0000, 2'd2, 3'd1); // sNaN<1  -> 0,NV=1
    do_op(32'h7F80_0001, 32'h3F80_0000, 2'd2, 3'd2); // sNaN==1 -> 0,NV=1
    wait_drain();

    // ---- CLASSIFY (S12, S13) ----
    do_op(32'hFF80_0000, 32'd0, 2'd3, 3'd0); // -inf: bit 0
    do_op(32'hBF80_0000, 32'd0, 2'd3, 3'd0); // -normal: bit 1
    do_op(32'h807F_FFFF, 32'd0, 2'd3, 3'd0); // -subn: bit 2
    do_op(32'h8000_0000, 32'd0, 2'd3, 3'd0); // -zero: bit 3
    do_op(32'h0000_0000, 32'd0, 2'd3, 3'd0); // +zero: bit 4
    do_op(32'h007F_FFFF, 32'd0, 2'd3, 3'd0); // +subn: bit 5
    do_op(32'h3F80_0000, 32'd0, 2'd3, 3'd0); // +normal: bit 6
    do_op(32'h7F80_0000, 32'd0, 2'd3, 3'd0); // +inf: bit 7
    do_op(32'h7F80_0001, 32'd0, 2'd3, 3'd0); // sNaN: bit 8
    do_op(32'h7FC0_0000, 32'd0, 2'd3, 3'd0); // qNaN: bit 9
    // operand_b ignored
    do_op(32'h3F80_0000, 32'h7FC0_0000, 2'd3, 3'd0);
    do_op(32'h3F80_0000, 32'hFF80_0000, 2'd3, 3'd0);
    wait_drain();

    // ---- Backpressure (H3): hold out_ready low >=20 cycles ----
    begin : bp_test
      int c;
      bfm_out_ready(0);
      do_op(32'h3F80_0000, 32'h4000_0000, 2'd1, 3'd0); // min 1.0
      bfm_idle();
      c = 0;
      while (!out_valid_o && c < 300) begin
        @(posedge clk);
        c++;
      end
      if (!out_valid_o) begin
        $display("FAIL H3: no result after 300 cycles with out_ready low");
        errors++;
      end else begin
        repeat (25) begin
          @(posedge clk);
          if (!out_valid_o) begin
            $display("FAIL H3: out_valid_o dropped during backpressure");
            errors++;
          end
        end
      end
      bfm_out_ready(1);
      wait_drain();
    end

    // ---- Reset discard (S15) ----
    bfm_out_ready(0);
    do_op(32'h3F80_0000, 32'h4000_0000, 2'd1, 3'd0);
    bfm_idle();
    @(negedge clk);
    rst_n = 1'b0;
    exp_result_q.delete(); exp_class_q.delete();
    exp_status_q.delete(); exp_op_q.delete();
    repeat (4) @(posedge clk);
    @(negedge clk);
    rst_n = 1'b1;
    @(posedge clk);
    if (out_valid_o) begin
      $display("FAIL S15: out_valid_o high on first cycle after reset");
      errors++;
    end
    @(negedge clk);
    out_ready_i = 1'b1;
    expect_no_output = 1'b1;
    repeat (30) @(posedge clk);
    @(negedge clk);
    expect_no_output = 1'b0;
    // New op should work after reset
    do_op(32'h4000_0000, 32'h3F80_0000, 2'd1, 3'd1); // max(2,1)=2
    wait_drain();

    // ---- Final ----
    if (errors == 0) $display("RESULT: PASS");
    else             $display("RESULT: FAIL (%0d errors, %0d checks)", errors, checks);
    $finish;
  end

endmodule
