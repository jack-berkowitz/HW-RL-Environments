`timescale 1ns/1ps

module fp_noncomp_tb;
  logic clk_i, rst_ni;
  logic [31:0] operand_a_i, operand_b_i;
  logic [1:0]  op_i;
  logic [2:0]  op_mode_i;
  logic        in_valid_i, in_ready_o;
  logic [31:0] result_o;
  logic [9:0]  class_mask_o;
  logic [4:0]  status_o;
  logic        out_valid_o, out_ready_i;

  fp_noncomp dut (
    .clk_i(clk_i),
    .rst_ni(rst_ni),
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

  initial begin
    clk_i = 0;
    forever #5 clk_i = ~clk_i;
  end

  initial begin
    #200000;
    $display("RESULT: FAIL");
    $display("Watchdog timeout");
    $finish;
  end

  function logic is_nan(input logic [31:0] x);
    return (x[30:23] == 8'hFF) && (x[22:0] != 0);
  endfunction

  function logic is_snan(input logic [31:0] x);
    return (x[30:23] == 8'hFF) && (x[22:0] != 0) && (x[22] == 0);
  endfunction

  function logic is_qnan(input logic [31:0] x);
    return (x[30:23] == 8'hFF) && (x[22] == 1);
  endfunction

  function logic is_inf(input logic [31:0] x);
    return (x[30:23] == 8'hFF) && (x[22:0] == 0);
  endfunction

  function logic is_zero(input logic [31:0] x);
    return (x[30:23] == 0) && (x[22:0] == 0);
  endfunction

  function logic is_subnormal(input logic [31:0] x);
    return (x[30:23] == 0) && (x[22:0] != 0);
  endfunction

  function logic is_normal(input logic [31:0] x);
    return (x[30:23] != 0) && (x[30:23] != 8'hFF);
  endfunction

  function logic [31:0] sgnj(input logic [31:0] a, b, input logic [2:0] mode);
    logic [31:0] res;
    res = a;
    case (mode)
      3'd0: res[31] = b[31];
      3'd1: res[31] = ~b[31];
      3'd2: res[31] = a[31] ^ b[31];
    endcase
    return res;
  endfunction

  function logic fp_lt(input logic [31:0] a, b);
    if (is_zero(a) && is_zero(b)) begin
      return (a[31] && !b[31]);
    end
    if (a[31] != b[31]) return a[31];
    if (a[31]) begin
      if (a[30:23] != b[30:23]) return a[30:23] > b[30:23];
      return a[22:0] > b[22:0];
    end else begin
      if (a[30:23] != b[30:23]) return a[30:23] < b[30:23];
      return a[22:0] < b[22:0];
    end
  endfunction

  function logic fp_eq(input logic [31:0] a, b);
    if (is_zero(a) && is_zero(b)) return 1;
    return (a == b);
  endfunction

  function logic [31:0] minmax(input logic [31:0] a, b, input logic mode);
    logic a_nan, b_nan;
    a_nan = is_nan(a);
    b_nan = is_nan(b);
    if (a_nan && b_nan) return 32'h7FC0_0000;
    if (a_nan) return b;
    if (b_nan) return a;
    if (mode == 0) begin
      if (fp_lt(a, b) || fp_eq(a, b)) return a;
      else return b;
    end else begin
      if (fp_lt(b, a) || fp_eq(a, b)) return a;
      else return b;
    end
  endfunction

  function logic [31:0] cmp(input logic [31:0] a, b, input logic [2:0] mode);
    if (is_nan(a) || is_nan(b)) return 32'h0;
    case (mode)
      3'd0: return (fp_lt(a, b) || fp_eq(a, b)) ? 32'h1 : 32'h0;
      3'd1: return fp_lt(a, b) ? 32'h1 : 32'h0;
      3'd2: return fp_eq(a, b) ? 32'h1 : 32'h0;
    endcase
    return 32'h0;
  endfunction

  function logic [9:0] classify(input logic [31:0] a);
    logic [9:0] mask;
    mask = 0;
    if (is_inf(a)) mask = a[31] ? 10'h001 : 10'h080;
    else if (is_normal(a)) mask = a[31] ? 10'h002 : 10'h040;
    else if (is_subnormal(a)) mask = a[31] ? 10'h004 : 10'h020;
    else if (is_zero(a)) mask = a[31] ? 10'h008 : 10'h010;
    else if (is_snan(a)) mask = 10'h100;
    else if (is_qnan(a)) mask = 10'h200;
    return mask;
  endfunction

  function logic [4:0] get_status(input logic [1:0] op, input logic [31:0] a, b, input logic [2:0] mode);
    logic [4:0] status;
    status = 0;
    if (op == 2'd1) begin
      if (is_snan(a) || is_snan(b)) status[4] = 1;
    end else if (op == 2'd2) begin
      if (mode == 3'd2) begin
        if (is_snan(a) || is_snan(b)) status[4] = 1;
      end else begin
        if (is_nan(a) || is_nan(b)) status[4] = 1;
      end
    end
    return status;
  endfunction

  typedef struct {
    logic [31:0] a, b;
    logic [1:0] op;
    logic [2:0] mode;
    logic [31:0] exp_result;
    logic [9:0] exp_class;
    logic [4:0] exp_status;
  } testcase_t;

  testcase_t queue[$];

  logic [31:0] pos_zero = 32'h0000_0000;
  logic [31:0] neg_zero = 32'h8000_0000;
  logic [31:0] pos_one = 32'h3F80_0000;
  logic [31:0] neg_one = 32'hBF80_0000;
  logic [31:0] pos_two = 32'h4000_0000;
  logic [31:0] neg_two = 32'hC000_0000;
  logic [31:0] pos_inf = 32'h7F80_0000;
  logic [31:0] neg_inf = 32'hFF80_0000;
  logic [31:0] snan = 32'h7F80_0001;
  logic [31:0] qnan = 32'h7FC0_0000;
  logic [31:0] pos_sub = 32'h0000_0001;
  logic [31:0] neg_sub = 32'h8000_0001;

  task automatic add_test(input logic [31:0] a, b, input logic [1:0] op, input logic [2:0] mode);
    testcase_t tc;
    tc.a = a;
    tc.b = b;
    tc.op = op;
    tc.mode = mode;
    tc.exp_result = 0;
    tc.exp_class = 0;
    tc.exp_status = 0;
    
    if (op == 2'd0) begin
      tc.exp_result = sgnj(a, b, mode);
      tc.exp_status = 0;
    end else if (op == 2'd1) begin
      tc.exp_result = minmax(a, b, mode);
      tc.exp_status = get_status(op, a, b, mode);
    end else if (op == 2'd2) begin
      tc.exp_result = cmp(a, b, mode);
      tc.exp_status = get_status(op, a, b, mode);
    end else if (op == 2'd3) begin
      tc.exp_class = classify(a);
      tc.exp_status = 0;
    end
    
    queue.push_back(tc);
  endtask

  integer test_count;
  integer pass_count;

  initial begin
    rst_ni = 0;
    in_valid_i = 0;
    out_ready_i = 1;
    operand_a_i = 0;
    operand_b_i = 0;
    op_i = 0;
    op_mode_i = 0;
    test_count = 0;
    pass_count = 0;

    repeat(10) @(posedge clk_i);
    rst_ni = 1;
    repeat(5) @(posedge clk_i);

    // SGNJ tests
    add_test(pos_one, neg_one, 2'd0, 3'd0);
    add_test(neg_one, pos_one, 2'd0, 3'd1);
    add_test(pos_one, neg_one, 2'd0, 3'd2);
    add_test(qnan, pos_one, 2'd0, 3'd0);
    add_test(pos_one, qnan, 2'd0, 3'd1);
    add_test(snan, neg_one, 2'd0, 3'd2);
    add_test(pos_zero, neg_zero, 2'd0, 3'd0);
    add_test(pos_inf, neg_inf, 2'd0, 3'd2);

    // MINMAX tests
    add_test(pos_one, pos_two, 2'd1, 3'd0);
    add_test(pos_one, pos_two, 2'd1, 3'd1);
    add_test(neg_one, neg_two, 2'd1, 3'd0);
    add_test(neg_zero, pos_zero, 2'd1, 3'd0);
    add_test(neg_zero, pos_zero, 2'd1, 3'd1);
    add_test(qnan, pos_one, 2'd1, 3'd0);
    add_test(pos_one, qnan, 2'd1, 3'd1);
    add_test(snan, pos_one, 2'd1, 3'd0);
    add_test(qnan, qnan, 2'd1, 3'd0);
    add_test(snan, qnan, 2'd1, 3'd1);
    add_test(pos_inf, neg_inf, 2'd1, 3'd0);
    add_test(pos_sub, neg_sub, 2'd1, 3'd1);

    // CMP tests
    add_test(pos_one, pos_two, 2'd2, 3'd0);
    add_test(pos_one, pos_one, 2'd2, 3'd2);
    add_test(pos_two, pos_one, 2'd2, 3'd1);
    add_test(neg_zero, pos_zero, 2'd2, 3'd2);
    add_test(pos_zero, neg_zero, 2'd2, 3'd0);
    add_test(qnan, pos_one, 2'd2, 3'd0);
    add_test(pos_one, snan, 2'd2, 3'd1);
    add_test(qnan, qnan, 2'd2, 3'd2);
    add_test(pos_inf, neg_inf, 2'd2, 3'd1);

    // CLASSIFY tests
    add_test(neg_inf, 0, 2'd3, 3'd0);
    add_test(neg_one, 0, 2'd3, 3'd0);
    add_test(neg_sub, 0, 2'd3, 3'd0);
    add_test(neg_zero, 0, 2'd3, 3'd0);
    add_test(pos_zero, 0, 2'd3, 3'd0);
    add_test(pos_sub, 0, 2'd3, 3'd0);
    add_test(pos_one, 0, 2'd3, 3'd0);
    add_test(pos_inf, 0, 2'd3, 3'd0);
    add_test(snan, 0, 2'd3, 3'd0);
    add_test(qnan, 0, 2'd3, 3'd0);

    test_count = queue.size();

    foreach (queue[i]) begin
      operand_a_i = queue[i].a;
      operand_b_i = queue[i].b;
      op_i = queue[i].op;
      op_mode_i = queue[i].mode;
      in_valid_i = 1;
      
      do @(posedge clk_i);
      while (!in_ready_o);
      
      in_valid_i = 0;
      
      if (i == 20) begin
        repeat(3) @(posedge clk_i);
        out_ready_i = 0;
        repeat(5) @(posedge clk_i);
        out_ready_i = 1;
      end
    end

    wait (queue.size() == 0);
    
    if (pass_count == test_count) begin
      $display("RESULT: PASS");
    end else begin
      $display("RESULT: FAIL");
      $display("Passed %0d/%0d tests", pass_count, test_count);
    end
    $finish;
  end

  always @(posedge clk_i) begin
    if (rst_ni && out_valid_o && out_ready_i) begin
      if (queue.size() == 0) begin
        $display("RESULT: FAIL");
        $display("Unexpected output");
        $finish;
      end
      
      testcase_t exp = queue.pop_front();
      logic fail;
      fail = 0;
      
      if (exp.op != 2'd3) begin
        if (result_o !== exp.exp_result) begin
          $display("FAIL: Result mismatch for op=%0d mode=%0d a=%h b=%h", exp.op, exp.mode, exp.a, exp.b);
          $display("  Expected: %h, Got: %h", exp.exp_result, result_o);
          fail = 1;
        end
      end
      
      if (exp.op == 2'd3) begin
        if (class_mask_o !== exp.exp_class) begin
          $display("FAIL: Class mask mismatch for a=%h", exp.a);
          $display("  Expected: %b, Got: %b", exp.exp_class, class_mask_o);
          fail = 1;
        end
      end
      
      if (status_o !== exp.exp_status) begin
        $display("FAIL: Status mismatch for op=%0d mode=%0d", exp.op, exp.mode);
        $display("  Expected: %b, Got: %b", exp.exp_status, status_o);
        fail = 1;
      end
      
      if (fail) begin
        $display("RESULT: FAIL");
        $finish;
      end else begin
        pass_count++;
      end
    end
  end
endmodule