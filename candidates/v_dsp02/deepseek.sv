module fp_noncomp_tb;

  // ---------------------------------------------------------------------------
  // PROVIDED PLUMBING -- clock, reset, issue, ready, watchdog
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
  // DUT signals
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
  // DUT
  // ---------------------------------------------------------------------------
  fp_noncomp dut (
    .clk_i        (clk),
    .rst_ni       (rst_n),
    .operand_a_i  (operand_a_i),
    .operand_b_i  (operand_b_i),
    .op_i         (op_i),
    .op_mode_i    (op_mode_i),
    .in_valid_i   (in_valid_i),
    .in_ready_o   (in_ready_o),
    .result_o     (result_o),
    .class_mask_o (class_mask_o),
    .status_o     (status_o),
    .out_valid_o  (out_valid_o),
    .out_ready_i  (out_ready_i)
  );

  // ---------------------------------------------------------------------------
  // Bookkeeping queues
  // ---------------------------------------------------------------------------
  logic [31:0] exp_result_q[$];
  logic [9:0]  exp_class_q[$];
  logic [4:0]  exp_status_q[$];
  bit          exp_check_result_q[$];
  bit          exp_check_class_q[$];

  logic [31:0] observed_result_q[$];
  logic [9:0]  observed_class_q[$];
  logic [4:0]  observed_status_q[$];

  // Capture every delivered result, in order.
  always @(posedge clk) begin
    if (rst_n && out_valid_o === 1'b1 && out_ready_i === 1'b1) begin
      observed_result_q.push_back(result_o);
      observed_class_q.push_back(class_mask_o);
      observed_status_q.push_back(status_o);
    end
  end

  // ---------------------------------------------------------------------------
  // IEEE 754 / RISC-V reference helpers
  // ---------------------------------------------------------------------------
  function automatic logic isnan(input logic [31:0] x);
    return (x[30:23] == 8'hFF) && (x[22:0] != 23'h0);
  endfunction

  function automatic logic issnan(input logic [31:0] x);
    return isnan(x) && (x[22] == 1'b0);
  endfunction

  function automatic logic float_less(input logic [31:0] a, b);
    if (a[31] != b[31])
      return a[31] > b[31];                 // negative less than positive
    if (a[31] == 1'b0)
      return a[30:0] < b[30:0];             // positive: compare magnitude
    else
      return a[30:0] > b[30:0];             // negative: compare magnitude reversed
  endfunction

  function automatic logic float_equal(input logic [31:0] a, b);
    if ((a[30:0] == 0) && (b[30:0] == 0))
      return 1'b1;                          // +0 == -0
    return (a == b);
  endfunction

  function automatic logic [31:0] sign_inj(input logic [31:0] a, b,
                                           input logic [2:0] mode);
    logic s;
    case (mode)
      3'd0: s = b[31];
      3'd1: s = ~b[31];
      3'd2: s = a[31] ^ b[31];
      default: s = 1'bx;
    endcase
    return {s, a[30:0]};
  endfunction

  function automatic logic [31:0] ref_minmax(input logic [31:0] a, b,
                                             input logic is_min);
    logic a_nan = isnan(a);
    logic b_nan = isnan(b);

    if (!a_nan && !b_nan) begin
      if (is_min)
        return float_less(a, b) ? a : b;
      else
        return float_less(a, b) ? b : a;
    end
    else if (a_nan && !b_nan) return b;
    else if (!a_nan && b_nan) return a;
    else return 32'h7FC0_0000;              // both NaN -> canonical qNaN
  endfunction

  function automatic logic [31:0] ref_cmp(input logic [31:0] a, b,
                                          input logic [2:0] mode,
                                          output logic [4:0] st);
    logic a_nan = isnan(a);
    logic b_nan = isnan(b);
    logic any_nan = a_nan | b_nan;
    logic any_snan = issnan(a) | issnan(b);
    logic res;

    case (mode)
      3'd0: begin                            // <= signalling
        if (any_nan) res = 1'b0;
        else res = float_less(a, b) | float_equal(a, b);
        st = {any_nan, 4'b0};
      end
      3'd1: begin                            // < signalling
        if (any_nan) res = 1'b0;
        else res = float_less(a, b);
        st = {any_nan, 4'b0};
      end
      3'd2: begin                            // == quiet
        if (any_nan) res = 1'b0;
        else res = float_equal(a, b);
        st = {any_snan, 4'b0};
      end
      default: begin
        res = 1'b0;
        st = '0;
      end
    endcase

    return res ? 32'h0000_0001 : 32'h0000_0000;
  endfunction

  function automatic logic [9:0] ref_classify(input logic [31:0] a);
    logic exp_ones   = (a[30:23] == 8'hFF);
    logic exp_zero   = (a[30:23] == 8'h00);
    logic sig_zero   = (a[22:0] == 0);
    logic sig_nonzero = !sig_zero;
    logic sign       = a[31];

    if (exp_ones && sig_nonzero) begin
      if (a[22]) return 10'b10_0000_0000;   // bit 9 quiet NaN
      else       return 10'b01_0000_0000;   // bit 8 signalling NaN
    end
    if (exp_ones && sig_zero) begin
      if (sign) return 10'b00_0000_0001;    // bit 0 -inf
      else      return 10'b00_1000_0000;    // bit 7 +inf
    end
    if (exp_zero && sig_zero) begin
      if (sign) return 10'b00_0000_1000;    // bit 3 -zero
      else      return 10'b00_0001_0000;    // bit 4 +zero
    end
    if (exp_zero && sig_nonzero) begin
      if (sign) return 10'b00_0000_0100;    // bit 2 -subnormal
      else      return 10'b00_0010_0000;    // bit 5 +subnormal
    end
    if (sign) return 10'b00_0000_0010;      // bit 1 -normal
    else      return 10'b00_0100_0000;      // bit 6 +normal
  endfunction

  // ---------------------------------------------------------------------------
  // Testbench tasks
  // ---------------------------------------------------------------------------
  task automatic fail_test(input string req, msg);
    $display("FAIL %s: %s", req, msg);
    $display("RESULT: FAIL");
    $finish;
  endtask

  task automatic clear_queues();
    exp_result_q.delete();
    exp_class_q.delete();
    exp_status_q.delete();
    exp_check_result_q.delete();
    exp_check_class_q.delete();
    observed_result_q.delete();
    observed_class_q.delete();
    observed_status_q.delete();
  endtask

  task automatic issue_single(input logic [31:0] a,
                              input logic [31:0] b,
                              input logic [1:0]  op,
                              input logic [2:0]  mode);
    automatic logic [31:0] exp_r;
    automatic logic [9:0]  exp_c;
    automatic logic [4:0]  exp_s;
    automatic bit          chk_r;
    automatic bit          chk_c;

    if (op == 2'd0) begin                 // SGNJ
      exp_r = sign_inj(a, b, mode);
      exp_s = 5'b00000;
      chk_r = 1'b1;
      chk_c = 1'b0;
      exp_c = '0;
    end
    else if (op == 2'd1) begin            // MINMAX
      exp_r = ref_minmax(a, b, (mode[0] == 1'b0));
      exp_s = { (issnan(a) | issnan(b)), 4'b0000 };
      chk_r = 1'b1;
      chk_c = 1'b0;
      exp_c = '0;
    end
    else if (op == 2'd2) begin            // CMP
      exp_r = ref_cmp(a, b, mode, exp_s);
      chk_r = 1'b1;
      chk_c = 1'b0;
      exp_c = '0;
    end
    else begin                            // CLASSIFY
      exp_c = ref_classify(a);
      exp_s = 5'b00000;
      chk_r = 1'b0;
      chk_c = 1'b1;
      exp_r = '0;
    end

    exp_result_q.push_back(exp_r);
    exp_class_q.push_back(exp_c);
    exp_status_q.push_back(exp_s);
    exp_check_result_q.push_back(chk_r);
    exp_check_class_q.push_back(chk_c);

    bfm_issue(a, b, op, mode);
  endtask

  task automatic drain_checked(input int expected_count);
    automatic int timeout_cyc = 0;
    automatic int i;

    while (observed_result_q.size() < expected_count) begin
      @(posedge clk);
      timeout_cyc = timeout_cyc + 1;
      if (timeout_cyc > 1_000_000)
        fail_test("S16", "timeout waiting for results");
    end

    for (i = 0; i < expected_count; i++) begin
      automatic logic [31:0] exp_r;
      automatic logic [9:0]  exp_c;
      automatic logic [4:0]  exp_s;
      automatic bit          chk_r;
      automatic bit          chk_c;
      automatic logic [31:0] obs_r;
      automatic logic [9:0]  obs_c;
      automatic logic [4:0]  obs_s;

      exp_r = exp_result_q.pop_front();
      exp_c = exp_class_q.pop_front();
      exp_s = exp_status_q.pop_front();
      chk_r = exp_check_result_q.pop_front();
      chk_c = exp_check_class_q.pop_front();

      obs_r = observed_result_q.pop_front();
      obs_c = observed_class_q.pop_front();
      obs_s = observed_status_q.pop_front();

      if (chk_r && obs_r !== exp_r)
        fail_test("S1", $sformatf("result mismatch: got %h expected %h", obs_r, exp_r));
      if (chk_c && obs_c !== exp_c)
        fail_test("S12", $sformatf("class_mask mismatch: got %b expected %b", obs_c, exp_c));
      if (obs_s !== exp_s)
        fail_test("S14", $sformatf("status mismatch: got %b expected %b", obs_s, exp_s));
    end
  endtask

  task automatic stall_ready(input int cycles);
    bfm_out_ready(1'b0);
    repeat (cycles) @(posedge clk);
    bfm_out_ready(1'b1);
  endtask

  // ---------------------------------------------------------------------------
  // Main stimulus
  // ---------------------------------------------------------------------------
  initial begin
    // Initialise all driven inputs
    operand_a_i = 32'h0;
    operand_b_i = 32'h0;
    op_i        = 2'd0;
    op_mode_i   = 3'd0;
    in_valid_i  = 1'b0;
    out_ready_i = 1'b0;

    clear_queues();

    // Reset and initial idle
    bfm_reset(4);
    bfm_out_ready(1'b1);
    @(posedge clk);
    if (out_valid_o !== 1'b0)
      fail_test("S15", "out_valid_o not low after reset");

    repeat (3) @(posedge clk);
    if (observed_result_q.size() != 0)
      fail_test("S15", "output after reset with no accepted operation");

    // ------------------------------------------------------------------
    // SGNJ (S1, S2)
    // ------------------------------------------------------------------
    clear_queues();
    issue_single(32'h00000001, 32'h80000000, 2'd0, 3'd0);
    issue_single(32'h00000001, 32'h80000000, 2'd0, 3'd1);
    issue_single(32'h00000001, 32'h80000000, 2'd0, 3'd2);
    issue_single(32'h7FC12345, 32'h00000000, 2'd0, 3'd0);
    issue_single(32'h7F800001, 32'h80000000, 2'd0, 3'd2);
    bfm_idle();
    drain_checked(5);

    // ------------------------------------------------------------------
    // MINMAX (S3, S4, S5, S6)
    // ------------------------------------------------------------------
    clear_queues();
    issue_single(32'h3F800000, 32'h40000000, 2'd1, 3'd0); // min 1.0,2.0
    issue_single(32'h3F800000, 32'h40000000, 2'd1, 3'd1); // max 1.0,2.0
    issue_single(32'h80000000, 32'h00000000, 2'd1, 3'd0); // min -0,+0
    issue_single(32'h80000000, 32'h00000000, 2'd1, 3'd1); // max -0,+0
    issue_single(32'h00000000, 32'h80000000, 2'd1, 3'd0); // min +0,-0
    issue_single(32'h00000000, 32'h80000000, 2'd1, 3'd1); // max +0,-0
    issue_single(32'h7FC00000, 32'h3F800000, 2'd1, 3'd0); // qNaN min
    issue_single(32'h7FC00000, 32'h3F800000, 2'd1, 3'd1); // qNaN max
    issue_single(32'h7F800001, 32'h3F800000, 2'd1, 3'd0); // sNaN min
    issue_single(32'h7F800001, 32'h3F800000, 2'd1, 3'd1); // sNaN max
    issue_single(32'h7FC00000, 32'h7FC00000, 2'd1, 3'd0); // both qNaN
    issue_single(32'h7F800001, 32'h7FC00000, 2'd1, 3'd0); // sNaN + qNaN
    issue_single(32'h7F800001, 32'h7F800001, 2'd1, 3'd1); // both sNaN
    bfm_idle();
    drain_checked(13);

    // ------------------------------------------------------------------
    // CMP (S7, S8, S9, S10, S11)
    // ------------------------------------------------------------------
    clear_queues();
    issue_single(32'h3F800000, 32'h40000000, 2'd2, 3'd1); // LT true
    issue_single(32'h40000000, 32'h3F800000, 2'd2, 3'd1); // LT false
    issue_single(32'h3F800000, 32'h3F800000, 2'd2, 3'd0); // LE true
    issue_single(32'h40000000, 32'h3F800000, 2'd2, 3'd0); // LE false
    issue_single(32'h00000000, 32'h80000000, 2'd2, 3'd2); // EQ zeros true
    issue_single(32'h00000000, 32'h80000000, 2'd2, 3'd1); // LT zeros false
    issue_single(32'h00000000, 32'h80000000, 2'd2, 3'd0); // LE zeros true
    issue_single(32'h7FC00000, 32'h3F800000, 2'd2, 3'd1); // qNaN LT
    issue_single(32'h7FC00000, 32'h3F800000, 2'd2, 3'd0); // qNaN LE
    issue_single(32'h7FC00000, 32'h3F800000, 2'd2, 3'd2); // qNaN EQ
    issue_single(32'h7F800001, 32'h3F800000, 2'd2, 3'd1); // sNaN LT
    issue_single(32'h7F800001, 32'h3F800000, 2'd2, 3'd0); // sNaN LE
    issue_single(32'h7F800001, 32'h3F800000, 2'd2, 3'd2); // sNaN EQ
    bfm_idle();
    drain_checked(13);

    // ------------------------------------------------------------------
    // CLASSIFY (S12, S13)
    // ------------------------------------------------------------------
    clear_queues();
    issue_single(32'hFF800000, 32'h00000000, 2'd3, 3'd0); // -inf
    issue_single(32'hBF800000, 32'h00000000, 2'd3, 3'd0); // -normal
    issue_single(32'h80000001, 32'h00000000, 2'd3, 3'd0); // -subnormal
    issue_single(32'h80000000, 32'h00000000, 2'd3, 3'd0); // -zero
    issue_single(32'h00000000, 32'h00000000, 2'd3, 3'd0); // +zero
    issue_single(32'h00000001, 32'h00000000, 2'd3, 3'd0); // +subnormal
    issue_single(32'h3F800000, 32'h00000000, 2'd3, 3'd0); // +normal
    issue_single(32'h7F800000, 32'h00000000, 2'd3, 3'd0); // +inf
    issue_single(32'h7F800001, 32'h00000000, 2'd3, 3'd0); // signaling NaN
    issue_single(32'h7FC00000, 32'h00000000, 2'd3, 3'd0); // quiet NaN
    bfm_idle();
    drain_checked(10);

    // ------------------------------------------------------------------
    // H3: backpressure / no loss / no reordering
    // ------------------------------------------------------------------
    clear_queues();
    bfm_out_ready(1'b1);
    issue_single(32'h3F800000, 32'h00000000, 2'd0, 3'd0);
    issue_single(32'h40000000, 32'h00000000, 2'd0, 3'd0);
    issue_single(32'h3F800000, 32'h40000000, 2'd1, 3'd0);
    issue_single(32'h3F800000, 32'h40000000, 2'd2, 3'd1);
    issue_single(32'h3F800000, 32'h00000000, 2'd3, 3'd0);
    bfm_idle();
    stall_ready(10);
    drain_checked(5);

    // ------------------------------------------------------------------
    // S15: reset discards any work accepted before/during reset
    // ------------------------------------------------------------------
    clear_queues();
    bfm_out_ready(1'b1);
    issue_single(32'h3F800000, 32'h40000000, 2'd0, 3'd0);
    issue_single(32'h40000000, 32'h3F800000, 2'd0, 3'd0);
    bfm_idle();

    bfm_reset(4);
    @(posedge clk);
    if (out_valid_o !== 1'b0)
      fail_test("S15", "out_valid_o not low after reset in discard phase");

    clear_queues();
    repeat (19) @(posedge clk);
    if (observed_result_q.size() != 0)
      fail_test("S15", "operation accepted before reset produced result after reset");

    $display("RESULT: PASS");
    $finish;
  end

endmodule