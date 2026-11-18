module fp_noncomp_tb;

  // ---------------------------------------------------------------------------
  // Signals (clk and rst_n are declared in the provided plumbing below)
  // ---------------------------------------------------------------------------
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

  // ---------------------------------------------------------------------------
  // PROVIDED PLUMBING -- issues operations, checks nothing.
  // ---------------------------------------------------------------------------
  // ---- clock -----------------------------------------------------------------
  logic clk;
  initial begin clk = 1'b0; forever #5 clk = ~clk; end

  // ---- reset (active low, synchronous) ---------------------------------------
  logic rst_n;
  initial rst_n = 1'b0;

  task automatic bfm_reset(input int cycles = 4);
    @(negedge clk);
    rst_n = 1'b0;
    repeat (cycles) @(posedge clk);
    @(negedge clk);
    rst_n = 1'b1;
  endtask

  // ---- issue -----------------------------------------------------------------
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

  // Stops issuing.
  task automatic bfm_idle();
    @(negedge clk);
    in_valid_i = 1'b0;
  endtask

  // ---- result side -----------------------------------------------------------
  task automatic bfm_out_ready(input logic value);
    @(negedge clk);
    out_ready_i = value;
  endtask

  // ---- watchdog (S16) --------------------------------------------------------
  initial begin
    #200_000_000;
    $display("RESULT: FAIL (watchdog: no forward progress)");
    $finish;
  end

  // ---------------------------------------------------------------------------
  // DUT
  // ---------------------------------------------------------------------------
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

  // ---------------------------------------------------------------------------
  // Testbench additions
  // ---------------------------------------------------------------------------
  typedef struct packed {
    logic [1:0]  op;
    logic [31:0] exp_result;
    logic [9:0]  exp_class;
    logic [4:0]  exp_status;
  } exp_rec_t;

  exp_rec_t exp_q[$];
  integer errors = 0;

  // Ready generator: provides backpressure with long stalls.
  logic force_stall;
  int   ready_cnt;
  initial force_stall = 1'b0;

  always @(negedge clk) begin
    if (!rst_n) begin
      out_ready_i <= 1'b0;
      ready_cnt   <= 0;
    end else if (force_stall) begin
      out_ready_i <= 1'b0;
    end else begin
      ready_cnt <= ready_cnt + 1;
      if (ready_cnt % 100 < 30)       out_ready_i <= 1'b0;
      else if (ready_cnt % 100 < 40)  out_ready_i <= 1'b1;
      else if (ready_cnt % 100 < 45)  out_ready_i <= 1'b0;
      else                            out_ready_i <= 1'b1;
    end
  end

  task automatic set_force_stall(input logic v);
    @(posedge clk);
    force_stall = v;
  endtask

  // ---------------------------------------------------------------------------
  // Prediction functions
  // ---------------------------------------------------------------------------
  function automatic logic is_nan(input logic [31:0] x);
    return (x[30:23] == 8'hFF) && (x[22:0] != 0);
  endfunction

  function automatic logic is_snan(input logic [31:0] x);
    return is_nan(x) && (x[22] == 1'b0);
  endfunction

  function automatic logic is_qnan(input logic [31:0] x);
    return is_nan(x) && (x[22] == 1'b1);
  endfunction

  function automatic logic is_zero(input logic [31:0] x);
    return (x[30:0] == 31'h0);
  endfunction

  function automatic logic is_inf(input logic [31:0] x);
    return (x[30:23] == 8'hFF) && (x[22:0] == 0);
  endfunction

  function automatic logic is_subnormal(input logic [31:0] x);
    return (x[30:23] == 8'h0) && (x[22:0] != 0);
  endfunction

  function automatic logic is_normal(input logic [31:0] x);
    return (x[30:23] != 8'h0) && (x[30:23] != 8'hFF);
  endfunction

  function automatic logic [9:0] classify(input logic [31:0] x);
    logic [9:0] mask;
    mask = 10'b0;
    if (is_nan(x)) begin
      if (is_snan(x)) mask[8] = 1'b1;
      else            mask[9] = 1'b1;
    end else if (is_inf(x)) begin
      if (x[31]) mask[0] = 1'b1;
      else       mask[7] = 1'b1;
    end else if (is_zero(x)) begin
      if (x[31]) mask[3] = 1'b1;
      else       mask[4] = 1'b1;
    end else if (is_subnormal(x)) begin
      if (x[31]) mask[2] = 1'b1;
      else       mask[5] = 1'b1;
    end else if (is_normal(x)) begin
      if (x[31]) mask[1] = 1'b1;
      else       mask[6] = 1'b1;
    end
    return mask;
  endfunction

  function automatic logic [31:0] sgnj_result(input logic [31:0] a,
                                               input logic [31:0] b,
                                               input logic [2:0]  mode);
    logic sign;
    case (mode)
      3'd0: sign = b[31];
      3'd1: sign = ~b[31];
      3'd2: sign = a[31] ^ b[31];
      default: sign = 1'b0;
    endcase
    return {sign, a[30:0]};
  endfunction

  function automatic logic is_less_minmax(input logic [31:0] a,
                                          input logic [31:0] b);
    logic sa, sb;
    logic [30:0] ma, mb;
    sa = a[31]; sb = b[31];
    ma = a[30:0]; mb = b[30:0];
    if (sa != sb) begin
      return sa;
    end else if (sa == 1'b0) begin
      return (ma < mb);
    end else begin
      return (ma > mb);
    end
  endfunction

  function automatic logic [31:0] minmax_result(input logic [31:0] a,
                                                 input logic [31:0] b,
                                                 input logic [2:0]  mode);
    logic a_nan, b_nan;
    a_nan = is_nan(a);
    b_nan = is_nan(b);
    if (a_nan && b_nan) return 32'h7FC0_0000;
    else if (a_nan)     return b;
    else if (b_nan)     return a;
    else begin
      if (mode == 3'd0) begin
        if (is_less_minmax(a, b)) return a;
        else                      return b;
      end else begin
        if (is_less_minmax(a, b)) return b;
        else                      return a;
      end
    end
  endfunction

  function automatic logic minmax_nv(input logic [31:0] a,
                                     input logic [31:0] b);
    return is_snan(a) || is_snan(b);
  endfunction

  function automatic logic is_less_cmp(input logic [31:0] a,
                                       input logic [31:0] b);
    logic sa, sb;
    logic [30:0] ma, mb;
    if (is_zero(a) && is_zero(b)) return 1'b0;
    sa = a[31]; sb = b[31];
    ma = a[30:0]; mb = b[30:0];
    if (sa != sb) begin
      return sa;
    end else if (sa == 1'b0) begin
      return (ma < mb);
    end else begin
      return (ma > mb);
    end
  endfunction

  function automatic logic [31:0] cmp_result(input logic [31:0] a,
                                              input logic [31:0] b,
                                              input logic [2:0]  mode);
    logic a_nan, b_nan;
    a_nan = is_nan(a);
    b_nan = is_nan(b);
    if (mode == 3'd0) begin
      if (a_nan || b_nan) return 32'h0;
      else if (!is_less_cmp(b, a)) return 32'h1;
      else return 32'h0;
    end else if (mode == 3'd1) begin
      if (a_nan || b_nan) return 32'h0;
      else if (is_less_cmp(a, b)) return 32'h1;
      else return 32'h0;
    end else if (mode == 3'd2) begin
      if (a_nan || b_nan) return 32'h0;
      else if (!is_less_cmp(a, b) && !is_less_cmp(b, a)) return 32'h1;
      else return 32'h0;
    end else return 32'h0;
  endfunction

  function automatic logic cmp_nv(input logic [31:0] a,
                                  input logic [31:0] b,
                                  input logic [2:0]  mode);
    if (mode == 3'd0 || mode == 3'd1) begin
      return is_nan(a) || is_nan(b);
    end else if (mode == 3'd2) begin
      return is_snan(a) || is_snan(b);
    end else return 1'b0;
  endfunction

  // ---------------------------------------------------------------------------
  // Issue one operation and record its expected result.
  // ---------------------------------------------------------------------------
  task automatic issue_op(input logic [31:0] a,
                          input logic [31:0] b,
                          input logic [1:0]  op,
                          input logic [2:0]  mode);
    exp_rec_t rec;
    rec.op         = op;
    rec.exp_result = 32'h0;
    rec.exp_class  = 10'h0;
    rec.exp_status = 5'h0;
    case (op)
      2'd0: begin // SGNJ
        rec.exp_result = sgnj_result(a, b, mode);
        rec.exp_status = 5'h0;
      end
      2'd1: begin // MINMAX
        rec.exp_result = minmax_result(a, b, mode);
        rec.exp_status = {minmax_nv(a, b), 4'h0};
      end
      2'd2: begin // CMP
        rec.exp_result = cmp_result(a, b, mode);
        rec.exp_status = {cmp_nv(a, b, mode), 4'h0};
      end
      2'd3: begin // CLASSIFY
        rec.exp_class  = classify(a);
        rec.exp_status = 5'h0;
      end
    endcase
    exp_q.push_back(rec);
    bfm_issue(a, b, op, mode);
  endtask

  // ---------------------------------------------------------------------------
  // Wait until all expected results have been delivered.
  // ---------------------------------------------------------------------------
  task automatic wait_drain();
    set_force_stall(0);
    while (exp_q.size() > 0) @(posedge clk);
    repeat (2) @(posedge clk);
    if (out_valid_o) begin
      $display("FAIL: H2 out_valid_o still high after drain");
      errors++;
    end
  endtask

  // ---------------------------------------------------------------------------
  // Checker
  // ---------------------------------------------------------------------------
  logic        prev_out_valid;
  logic        prev_out_ready;
  logic [31:0] prev_result;
  logic [9:0]  prev_class;
  logic [4:0]  prev_status;

  always @(posedge clk) begin
    if (rst_n) begin
      // Backpressure stability (H3)
      if (prev_out_valid && !prev_out_ready) begin
        if (!out_valid_o) begin
          $display("FAIL: H3 out_valid_o dropped under backpressure");
          errors++;
        end else begin
          if (result_o !== prev_result) begin
            $display("FAIL: H3 result_o changed under backpressure");
            errors++;
          end
          if (class_mask_o !== prev_class) begin
            $display("FAIL: H3 class_mask_o changed under backpressure");
            errors++;
          end
          if (status_o !== prev_status) begin
            $display("FAIL: H3 status_o changed under backpressure");
            errors++;
          end
        end
      end

      // Result handshake and checking
      if (out_valid_o && out_ready_i) begin
        if (exp_q.size() == 0) begin
          $display("FAIL: H2 unexpected result (no expected operation)");
          errors++;
        end else begin
          automatic exp_rec_t e = exp_q.pop_front();
          if (status_o !== e.exp_status) begin
            $display("FAIL: S14 status_o mismatch: got %b expected %b",
                     status_o, e.exp_status);
            errors++;
          end
          if (e.op == 2'd3) begin // CLASSIFY
            if (class_mask_o !== e.exp_class) begin
              $display("FAIL: S12 class_mask_o mismatch: got %b expected %b",
                       class_mask_o, e.exp_class);
              errors++;
            end
          end else begin
            if (result_o !== e.exp_result) begin
              $display("FAIL: result_o mismatch for op %0d: got %h expected %h",
                       e.op, result_o, e.exp_result);
              errors++;
            end
          end
        end
      end

      prev_out_valid <= out_valid_o;
      prev_out_ready <= out_ready_i;
      prev_result    <= result_o;
      prev_class     <= class_mask_o;
      prev_status    <= status_o;
    end else begin
      prev_out_valid <= 1'b0;
      prev_out_ready <= 1'b0;
    end
  end

  // ---------------------------------------------------------------------------
  // Main test sequence
  // ---------------------------------------------------------------------------
  initial begin
    in_valid_i  = 1'b0;
    operand_a_i = 32'h0;
    operand_b_i = 32'h0;
    op_i        = 2'h0;
    op_mode_i   = 3'h0;

    bfm_reset();
    exp_q.delete();

    // S15: out_valid must be low on first cycle after reset release
    repeat (5) begin
      @(posedge clk);
      if (out_valid_o) begin
        $display("FAIL: S15 out_valid_o high after initial reset");
        errors++;
      end
    end

    // -----------------------------------------------------------------------
    // SGNJ tests
    // -----------------------------------------------------------------------
    issue_op(32'h3F80_0000, 32'h0000_0000, 2'd0, 3'd0);
    issue_op(32'h3F80_0000, 32'h8000_0000, 2'd0, 3'd0);
    issue_op(32'h3F80_0000, 32'h0000_0000, 2'd0, 3'd1);
    issue_op(32'h3F80_0000, 32'h8000_0000, 2'd0, 3'd1);
    issue_op(32'h3F80_0000, 32'h0000_0000, 2'd0, 3'd2);
    issue_op(32'h3F80_0000, 32'h8000_0000, 2'd0, 3'd2);
    issue_op(32'hBF80_0000, 32'h8000_0000, 2'd0, 3'd2);
    issue_op(32'h7FC0_1234, 32'h8000_0000, 2'd0, 3'd0);
    issue_op(32'h7F80_0001, 32'h0000_0000, 2'd0, 3'd0);
    issue_op(32'hFF80_0001, 32'h0000_0000, 2'd0, 3'd1);
    issue_op(32'h7FC0_1234, 32'hFF80_0001, 2'd0, 3'd2);

    // -----------------------------------------------------------------------
    // MINMAX tests
    // -----------------------------------------------------------------------
    issue_op(32'h3F80_0000, 32'h4000_0000, 2'd1, 3'd0);
    issue_op(32'h3F80_0000, 32'h4000_0000, 2'd1, 3'd1);
    issue_op(32'hBF80_0000, 32'h4000_0000, 2'd1, 3'd0);
    issue_op(32'hBF80_0000, 32'h4000_0000, 2'd1, 3'd1);
    issue_op(32'hBF80_0000, 32'hC000_0000, 2'd1, 3'd0);
    issue_op(32'hBF80_0000, 32'hC000_0000, 2'd1, 3'd1);
    issue_op(32'h8000_0000, 32'h0000_0000, 2'd1, 3'd0);
    issue_op(32'h0000_0000, 32'h8000_0000, 2'd1, 3'd0);
    issue_op(32'h8000_0000, 32'h0000_0000, 2'd1, 3'd1);
    issue_op(32'h0000_0000, 32'h8000_0000, 2'd1, 3'd1);
    issue_op(32'h7F80_0000, 32'h3F80_0000, 2'd1, 3'd0);
    issue_op(32'h7F80_0000, 32'h3F80_0000, 2'd1, 3'd1);
    issue_op(32'hFF80_0000, 32'h3F80_0000, 2'd1, 3'd0);
    issue_op(32'hFF80_0000, 32'h3F80_0000, 2'd1, 3'd1);
    issue_op(32'h0000_0001, 32'h0000_0000, 2'd1, 3'd0);
    issue_op(32'h8000_0001, 32'h8000_0000, 2'd1, 3'd0);
    issue_op(32'h7FC0_0000, 32'h3F80_0000, 2'd1, 3'd0);
    issue_op(32'h7FC0_0000, 32'h3F80_0000, 2'd1, 3'd1);
    issue_op(32'h3F80_0000, 32'h7FC0_0000, 2'd1, 3'd0);
    issue_op(32'h3F80_0000, 32'h7FC0_0000, 2'd1, 3'd1);
    issue_op(32'h7F80_0001, 32'h3F80_0000, 2'd1, 3'd0);
    issue_op(32'h7F80_0001, 32'h3F80_0000, 2'd1, 3'd1);
    issue_op(32'h3F80_0000, 32'h7F80_0001, 2'd1, 3'd0);
    issue_op(32'h3F80_0000, 32'h7F80_0001, 2'd1, 3'd1);
    issue_op(32'h7FC0_0000, 32'h7FC0_0000, 2'd1, 3'd0);
    issue_op(32'h7FC0_0000, 32'h7FC0_0000, 2'd1, 3'd1);
    issue_op(32'h7FC0_0000, 32'h7F80_0001, 2'd1, 3'd0);
    issue_op(32'h7FC0_0000, 32'h7F80_0001, 2'd1, 3'd1);
    issue_op(32'h7F80_0001, 32'h7F80_0001, 2'd1, 3'd0);
    issue_op(32'h7F80_0001, 32'h7F80_0001, 2'd1, 3'd1);
    issue_op(32'h7FC0_1234, 32'h7F80_0001, 2'd1, 3'd0);

    // -----------------------------------------------------------------------
    // CMP tests
    // -----------------------------------------------------------------------
    issue_op(32'h3F80_0000, 32'h4000_0000, 2'd2, 3'd0);
    issue_op(32'h4000_0000, 32'h3F80_0000, 2'd2, 3'd0);
    issue_op(32'h3F80_0000, 32'h3F80_0000, 2'd2, 3'd0);
    issue_op(32'h3F80_0000, 32'h4000_0000, 2'd2, 3'd1);
    issue_op(32'h4000_0000, 32'h3F80_0000, 2'd2, 3'd1);
    issue_op(32'h3F80_0000, 32'h3F80_0000, 2'd2, 3'd1);
    issue_op(32'h3F80_0000, 32'h3F80_0000, 2'd2, 3'd2);
    issue_op(32'h3F80_0000, 32'h4000_0000, 2'd2, 3'd2);
    issue_op(32'h8000_0000, 32'h0000_0000, 2'd2, 3'd0);
    issue_op(32'h0000_0000, 32'h8000_0000, 2'd2, 3'd0);
    issue_op(32'h8000_0000, 32'h0000_0000, 2'd2, 3'd1);
    issue_op(32'h0000_0000, 32'h8000_0000, 2'd2, 3'd1);
    issue_op(32'h8000_0000, 32'h0000_0000, 2'd2, 3'd2);
    issue_op(32'h0000_0000, 32'h8000_0000, 2'd2, 3'd2);
    issue_op(32'h7FC0_0000, 32'h3F80_0000, 2'd2, 3'd0);
    issue_op(32'h7F80_0001, 32'h3F80_0000, 2'd2, 3'd0);
    issue_op(32'h7FC0_0000, 32'h3F80_0000, 2'd2, 3'd1);
    issue_op(32'h7F80_0001, 32'h3F80_0000, 2'd2, 3'd1);
    issue_op(32'h7FC0_0000, 32'h3F80_0000, 2'd2, 3'd2);
    issue_op(32'h7F80_0001, 32'h3F80_0000, 2'd2, 3'd2);
    issue_op(32'h7FC0_0000, 32'h7FC0_0000, 2'd2, 3'd2);
    issue_op(32'h7FC0_0000, 32'h7F80_0001, 2'd2, 3'd2);
    issue_op(32'h7FC0_0000, 32'h7F80_0001, 2'd2, 3'd0);
    issue_op(32'h7FC0_0000, 32'h7F80_0001, 2'd2, 3'd1);

    // -----------------------------------------------------------------------
    // CLASSIFY tests
    // -----------------------------------------------------------------------
    issue_op(32'hFF80_0000, 32'h0, 2'd3, 3'd0);
    issue_op(32'hBF80_0000, 32'h0, 2'd3, 3'd0);
    issue_op(32'h8000_0001, 32'h0, 2'd3, 3'd0);
    issue_op(32'h8000_0000, 32'h0, 2'd3, 3'd0);
    issue_op(32'h0000_0000, 32'h0, 2'd3, 3'd0);
    issue_op(32'h0000_0001, 32'h0, 2'd3, 3'd0);
    issue_op(32'h3F80_0000, 32'h0, 2'd3, 3'd0);
    issue_op(32'h7F80_0000, 32'h0, 2'd3, 3'd0);
    issue_op(32'h7F80_0001, 32'h0, 2'd3, 3'd0);
    issue_op(32'h7FC0_0000, 32'h0, 2'd3, 3'd0);
    issue_op(32'hFF80_0001, 32'h0, 2'd3, 3'd0);
    issue_op(32'h7FC0_1234, 32'h0, 2'd3, 3'd0);
    issue_op(32'h3F80_0000, 32'hDEAD_BEEF, 2'd3, 3'd0);

    bfm_idle();
    wait_drain();

    // -----------------------------------------------------------------------
    // S15 reset test: operations accepted before reset must not emerge.
    // -----------------------------------------------------------------------
    issue_op(32'h3F80_0000, 32'h4000_0000, 2'd1, 3'd0);
    issue_op(32'h7FC0_0000, 32'h3F80_0000, 2'd2, 3'd2);
    issue_op(32'h0000_0001, 32'h0, 2'd3, 3'd0);
    bfm_idle();
    set_force_stall(1);
    repeat (10) @(posedge clk);
    bfm_reset();
    exp_q.delete();

    repeat (10) begin
      @(posedge clk);
      if (out_valid_o) begin
        $display("FAIL: S15 out_valid_o high after reset release");
        errors++;
      end
    end

    set_force_stall(0);
    repeat (10) @(posedge clk);
    if (out_valid_o) begin
      $display("FAIL: S15 stale result after reset");
      errors++;
    end

    wait_drain();

    if (errors == 0) $display("RESULT: PASS");
    else             $display("RESULT: FAIL");
    $finish;
  end

endmodule
