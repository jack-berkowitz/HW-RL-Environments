module fp_noncomp_tb;

  // ---- DUT signals -----------------------------------------------------------
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

  // ---- DUT Instantiation -----------------------------------------------------
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
  // TESTBENCH LOGIC AND CHECKERS
  // ---------------------------------------------------------------------------

  typedef struct {
    logic [31:0] op_a;
    logic [31:0] op_b;
    logic [1:0]  op;
    logic [2:0]  mode;
    logic [31:0] exp_res;
    logic [9:0]  exp_class;
    logic [4:0]  exp_status;
  } expect_t;

  expect_t exp_q[$];

  // Failure reporter
  task automatic fail_test(string msg);
    $display("FAIL: %s", msg);
    $display("RESULT: FAIL");
    $finish;
  endtask

  // Compute Expected Outcomes (Ground Truth Model)
  function automatic expect_t get_expected(logic [31:0] a, logic [31:0] b, logic [1:0] op, logic [2:0] mode);
    expect_t e;
    logic sign_a, sign_b;
    logic [7:0] exp_a, exp_b;
    logic [22:0] frac_a, frac_b;
    
    logic is_nan_a, is_snan_a, is_qnan_a;
    logic is_nan_b, is_snan_b, is_qnan_b;
    logic is_zero_a, is_zero_b;
    logic a_lt_b, a_eq_b;

    sign_a = a[31]; exp_a = a[30:23]; frac_a = a[22:0];
    sign_b = b[31]; exp_b = b[30:23]; frac_b = b[22:0];

    is_nan_a = (exp_a == 8'hFF) && (frac_a != 0);
    is_snan_a = is_nan_a && (frac_a[22] == 1'b0);
    is_qnan_a = is_nan_a && (frac_a[22] == 1'b1);

    is_nan_b = (exp_b == 8'hFF) && (frac_b != 0);
    is_snan_b = is_nan_b && (frac_b[22] == 1'b0);
    is_qnan_b = is_nan_b && (frac_b[22] == 1'b1);

    is_zero_a = (exp_a == 0) && (frac_a == 0);
    is_zero_b = (exp_b == 0) && (frac_b == 0);

    // Magnitude and Sign Magnitude Comparisons
    a_lt_b = 1'b0;
    if (sign_a != sign_b) begin
      a_lt_b = sign_a;
    end else begin
      if (sign_a == 1'b0) begin
        a_lt_b = (a[30:0] < b[30:0]);
      end else begin
        a_lt_b = (a[30:0] > b[30:0]);
      end
    end

    a_eq_b = (a[30:0] == b[30:0]) && (sign_a == sign_b);

    e.op_a = a; e.op_b = b; e.op = op; e.mode = mode;
    e.exp_res = 0; e.exp_class = 0; e.exp_status = 0;

    case (op)
      2'd0: begin // SGNJ
        if (mode == 3'd0) e.exp_res = {sign_b, a[30:0]};
        if (mode == 3'd1) e.exp_res = {~sign_b, a[30:0]};
        if (mode == 3'd2) e.exp_res = {sign_a ^ sign_b, a[30:0]};
        e.exp_status = 5'h00; // S2
      end
      
      2'd1: begin // MINMAX
        if (is_nan_a && is_nan_b) begin
          e.exp_res = 32'h7FC0_0000; // S5: Canonical qNaN
          if (is_snan_a || is_snan_b) e.exp_status = 5'h10; // S6
        end else if (is_nan_a) begin
          e.exp_res = b; // S4
          if (is_snan_a) e.exp_status = 5'h10; // S6
        end else if (is_nan_b) begin
          e.exp_res = a; // S4
          if (is_snan_b) e.exp_status = 5'h10; // S6
        end else begin
          logic min_sel_a, max_sel_a;
          if (is_zero_a && is_zero_b && (sign_a != sign_b)) begin // S3 (-0.0 < +0.0)
            min_sel_a = sign_a;
            max_sel_a = ~sign_a;
          end else begin
            min_sel_a = a_lt_b;
            max_sel_a = ~a_lt_b && ~a_eq_b;
            if (a_eq_b) begin
              min_sel_a = 1'b1;
              max_sel_a = 1'b1;
            end
          end
          
          if (mode == 3'd0) e.exp_res = min_sel_a ? a : b;
          if (mode == 3'd1) e.exp_res = max_sel_a ? a : b;
          e.exp_status = 5'h00;
        end
      end
      
      2'd2: begin // CMP
        if (is_nan_a || is_nan_b) begin
          e.exp_res = 32'h0;
          if (mode == 3'd2) begin // EQ (S9)
            if (is_snan_a || is_snan_b) e.exp_status = 5'h10;
          end else begin // LE, LT (S8)
            e.exp_status = 5'h10;
          end
        end else begin
          logic is_eq, is_lt;
          is_eq = (is_zero_a && is_zero_b) ? 1'b1 : a_eq_b; // S10
          is_lt = (is_zero_a && is_zero_b) ? 1'b0 : a_lt_b; // S10

          if (mode == 3'd0) e.exp_res = {31'd0, (is_lt || is_eq)};
          if (mode == 3'd1) e.exp_res = {31'd0, is_lt};
          if (mode == 3'd2) e.exp_res = {31'd0, is_eq};
          e.exp_status = 5'h00; // S11
        end
      end
      
      2'd3: begin // CLASSIFY
        if (is_nan_a) begin
          if (is_snan_a) e.exp_class[8] = 1'b1;
          if (is_qnan_a) e.exp_class[9] = 1'b1;
        end else if (exp_a == 8'hFF) begin
          if (sign_a) e.exp_class[0] = 1'b1;
          else e.exp_class[7] = 1'b1;
        end else if (is_zero_a) begin
          if (sign_a) e.exp_class[3] = 1'b1;
          else e.exp_class[4] = 1'b1;
        end else if (exp_a == 0) begin
          if (sign_a) e.exp_class[2] = 1'b1;
          else e.exp_class[5] = 1'b1;
        end else begin
          if (sign_a) e.exp_class[1] = 1'b1;
          else e.exp_class[6] = 1'b1;
        end
        e.exp_status = 5'h00; // S13
      end
    endcase
    
    return e;
  endfunction

  // ---- Result Status Checking ------------------------------------------------
  task automatic check_flags(expect_t e, logic [4:0] act_status);
    if (act_status[3:0] != 4'b0000) fail_test("S14: DZ, OF, UF, NX must be zero");
    if (act_status[4] != e.exp_status[4]) begin
      if (e.op == 2'd0) fail_test("S2: SGNJ must raise no exception flags");
      if (e.op == 2'd1) fail_test("S6: MINMAX flags incorrect");
      if (e.op == 2'd2) begin
        if (e.mode == 3'd2) fail_test("S9: CMP EQ flags incorrect");
        else fail_test("S8: CMP LE/LT flags incorrect");
      end
      if (e.op == 2'd3) fail_test("S13: CLASSIFY must raise no exception flags");
    end
  endtask

  // ---- Result Value Checking -------------------------------------------------
  task automatic check_result(expect_t e, logic [31:0] act_res, logic [9:0] act_class);
    logic is_nan_a, is_nan_b;
    is_nan_a = (e.op_a[30:23] == 8'hFF) && (e.op_a[22:0] != 0);
    is_nan_b = (e.op_b[30:23] == 8'hFF) && (e.op_b[22:0] != 0);

    if (e.op == 2'd3) begin
      if (act_class !== e.exp_class) fail_test("S12: CLASSIFY mask incorrect");
    end else begin
      if (act_res !== e.exp_res) begin
        if (e.op == 2'd0) fail_test("S1: SGNJ result incorrect");
        if (e.op == 2'd1) begin
          if (is_nan_a && is_nan_b) fail_test("S5: MINMAX 2 NaNs result incorrect");
          else if (is_nan_a || is_nan_b) fail_test("S4: MINMAX 1 NaN result incorrect");
          else fail_test("S3: MINMAX result incorrect");
        end
        if (e.op == 2'd2) begin
          if (is_nan_a || is_nan_b) begin
            if (e.mode == 3'd2) fail_test("S9: CMP EQ with NaN result incorrect");
            else fail_test("S8: CMP LE/LT with NaN result incorrect");
          end else fail_test("S7/S10: CMP result incorrect");
        end
      end
    end
  endtask

  // ---- Output Monitoring Process ---------------------------------------------
  initial begin
    forever begin
      @(posedge clk);
      if (out_valid_o && out_ready_i) begin
        if (exp_q.size() == 0) begin
          fail_test("H2/S15: Unexpected output transfer when no operation expected.");
        end else begin
          automatic expect_t e = exp_q.pop_front();
          check_flags(e, status_o);
          check_result(e, result_o, class_mask_o);
        end
      end
    end
  end

  // ---- Random Out-Ready Toggler ----------------------------------------------
  initial begin
    bfm_out_ready(1'b0);
    repeat(25) @(posedge clk); // Allow reset phase checks to execute
    forever begin
      bfm_out_ready($urandom_range(0, 1));
      repeat($urandom_range(1, 4)) @(posedge clk);
    end
  end

  // ---- Main Stimulus Process -------------------------------------------------
  task automatic issue_and_expect(logic [31:0] a, logic [31:0] b, logic [1:0] op, logic [2:0] mode);
    expect_t e;
    e = get_expected(a, b, op, mode);
    exp_q.push_back(e);
    bfm_issue(a, b, op, mode);
  endtask

  logic [31:0] tvals [12];

  initial begin
    tvals[0]  = 32'h0000_0000; // +0.0
    tvals[1]  = 32'h8000_0000; // -0.0
    tvals[2]  = 32'h3F80_0000; // +1.0
    tvals[3]  = 32'hBF80_0000; // -1.0
    tvals[4]  = 32'h7F80_0000; // +inf
    tvals[5]  = 32'hFF80_0000; // -inf
    tvals[6]  = 32'h7FC0_0000; // canonical qNaN (A2)
    tvals[7]  = 32'h7FC0_0001; // other qNaN
    tvals[8]  = 32'h7F80_0001; // sNaN
    tvals[9]  = 32'hFF80_0001; // negative sNaN
    tvals[10] = 32'h0000_0001; // +subnormal
    tvals[11] = 32'h8000_0001; // -subnormal

    in_valid_i = 1'b0;

    // Wait for the clock to start
    repeat(2) @(posedge clk);

    // -------------------------------------------------------------------------
    // Phase 1: Reset Check (S15)
    // -------------------------------------------------------------------------
    bfm_reset(4);
    
    // Issue some ops
    fork
      begin
        bfm_issue(tvals[2], tvals[3], 2'd0, 3'd0);
        bfm_issue(tvals[2], tvals[3], 2'd1, 3'd0);
        bfm_issue(tvals[2], tvals[3], 2'd2, 3'd0);
      end
    join_none

    // Interrupt with reset mid-flight
    repeat(5) @(posedge clk);
    bfm_reset(4);

    // Check that reset cleared inflight items
    @(posedge clk);
    if (out_valid_o !== 1'b0) begin
      fail_test("S15: out_valid_o was high immediately following reset");
    end
    
    exp_q.delete(); // Flush the expectations queue

    // -------------------------------------------------------------------------
    // Phase 2: Comprehensive Test Generation
    // -------------------------------------------------------------------------
    for (int i=0; i<12; i++) begin
      for (int j=0; j<12; j++) begin
        
        // OP=0 (SGNJ), modes 0,1,2
        for (int m=0; m<3; m++) issue_and_expect(tvals[i], tvals[j], 2'd0, m[2:0]);
        
        // OP=1 (MINMAX), modes 0,1
        for (int m=0; m<2; m++) issue_and_expect(tvals[i], tvals[j], 2'd1, m[2:0]);
        
        // OP=2 (CMP), modes 0,1,2
        for (int m=0; m<3; m++) issue_and_expect(tvals[i], tvals[j], 2'd2, m[2:0]);
        
        // OP=3 (CLASSIFY), mode doesn't matter, just issue 0
        issue_and_expect(tvals[i], tvals[j], 2'd3, 3'd0);
        
      end
    end

    bfm_idle();

    // -------------------------------------------------------------------------
    // Phase 3: Wait for drain and Finish
    // -------------------------------------------------------------------------
    while (exp_q.size() > 0) @(posedge clk);
    repeat(20) @(posedge clk);

    $display("RESULT: PASS");
    $finish;
  end

endmodule