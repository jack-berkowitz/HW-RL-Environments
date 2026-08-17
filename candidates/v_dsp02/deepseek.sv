`timescale 1ns/1ps
module fp_noncomp_tb;

  logic clk = 0;
  logic rst_ni = 0;
  logic [31:0] operand_a_i = 32'h0;
  logic [31:0] operand_b_i = 32'h0;
  logic [1:0]  op_i = 2'd0;
  logic [2:0]  op_mode_i = 3'd0;
  logic        in_valid_i = 0;
  logic        in_ready_o;
  logic [31:0] result_o;
  logic [9:0]  class_mask_o;
  logic [4:0]  status_o;
  logic        out_valid_o;
  logic        out_ready_i = 0;

  // DUT
  fp_noncomp dut (
    .clk_i       (clk),
    .rst_ni      (rst_ni),
    .operand_a_i (operand_a_i),
    .operand_b_i (operand_b_i),
    .op_i        (op_i),
    .op_mode_i   (op_mode_i),
    .in_valid_i  (in_valid_i),
    .in_ready_o  (in_ready_o),
    .result_o    (result_o),
    .class_mask_o(class_mask_o),
    .status_o    (status_o),
    .out_valid_o (out_valid_o),
    .out_ready_i (out_ready_i)
  );

  // Clock generator
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  // Watchdog (S16)
  initial begin
    #5_000_000;
    $display("FAIL: Watchdog timeout (S16)");
    $display("RESULT: FAIL");
    $finish;
  end

  // ------------------------------------------------------------
  // Test data types
  // ------------------------------------------------------------
  typedef struct packed {
    logic [1:0]  op;
    logic [2:0]  mode;
    logic [31:0] a;
    logic [31:0] b;
  } input_t;

  typedef struct {
    logic [31:0] result;
    logic [9:0]  class_mask;
    logic [4:0]  status;
    bit          check_result;
    bit          check_class;
    int          result_req;
    int          class_req;
    int          status_req;
  } exp_t;

  input_t ops[$];
  exp_t    exp_q[$];

  int errors = 0;

  // Requirement IDs
  localparam int REQ_S1  = 1;
  localparam int REQ_S2  = 2;
  localparam int REQ_S3  = 3;
  localparam int REQ_S4  = 4;
  localparam int REQ_S5  = 5;
  localparam int REQ_S6  = 6;
  localparam int REQ_S7  = 7;
  localparam int REQ_S8  = 8;
  localparam int REQ_S9  = 9;
  localparam int REQ_S11 = 11;
  localparam int REQ_S12 = 12;
  localparam int REQ_S13 = 13;
  localparam int REQ_S15 = 15;

  // Constants
  localparam logic [31:0] PZERO     = 32'h0000_0000;
  localparam logic [31:0] NZERO     = 32'h8000_0000;
  localparam logic [31:0] POS_INF   = 32'h7F80_0000;
  localparam logic [31:0] NEG_INF   = 32'hFF80_0000;
  localparam logic [31:0] CAN_QNAN  = 32'h7FC0_0000;
  localparam logic [31:0] QNAN_1    = 32'h7FC0_0001;
  localparam logic [31:0] QNAN_NEG  = 32'hFFC0_1234;
  localparam logic [31:0] SNAN      = 32'h7F80_0001;
  localparam logic [31:0] SNAN_NEG  = 32'hFF80_0001;
  localparam logic [31:0] ONE       = 32'h3F80_0000;
  localparam logic [31:0] NEG_ONE   = 32'hBF80_0000;
  localparam logic [31:0] TWO       = 32'h4000_0000;
  localparam logic [31:0] NEG_TWO   = 32'hC000_0000;
  localparam logic [31:0] HALF      = 32'h3F00_0000;
  localparam logic [31:0] NEG_HALF  = 32'hBF00_0000;
  localparam logic [31:0] POS_SUB   = 32'h0000_0001;
  localparam logic [31:0] NEG_SUB   = 32'h8000_0001;
  localparam logic [31:0] LARGE     = 32'h7F7F_FFFF;
  localparam logic [31:0] NEG_LARGE = 32'hFF7F_FFFF;
  localparam logic [31:0] DEAD      = 32'hdeadbeef;
  localparam logic [31:0] RANDOM    = 32'h12345678;

  // ------------------------------------------------------------
  // Helper functions
  // ------------------------------------------------------------
  function automatic string req_name(int id);
    case (id)
      REQ_S1 : return "S1";
      REQ_S2 : return "S2";
      REQ_S3 : return "S3";
      REQ_S4 : return "S4";
      REQ_S5 : return "S5";
      REQ_S6 : return "S6";
      REQ_S7 : return "S7";
      REQ_S8 : return "S8";
      REQ_S9 : return "S9";
      REQ_S11: return "S11";
      REQ_S12: return "S12";
      REQ_S13: return "S13";
      REQ_S15: return "S15";
      default: return "S??";
    endcase
  endfunction

  function automatic bit is_nan(logic [31:0] x);
    return (x[30:23] == 8'hFF) && (x[22:0] != 0);
  endfunction

  function automatic bit is_snan(logic [31:0] x);
    return is_nan(x) && (x[22] == 1'b0);
  endfunction

  function automatic bit is_qnan(logic [31:0] x);
    return is_nan(x) && (x[22] == 1'b1);
  endfunction

  function automatic bit is_inf(logic [31:0] x);
    return (x[30:23] == 8'hFF) && (x[22:0] == 0);
  endfunction

  function automatic bit is_zero(logic [31:0] x);
    return (x[30:23] == 8'h00) && (x[22:0] == 0);
  endfunction

  function automatic bit is_subnormal(logic [31:0] x);
    return (x[30:23] == 8'h00) && (x[22:0] != 0);
  endfunction

  function automatic bit is_normal(logic [31:0] x);
    return (x[30:23] != 8'hFF) && (x[30:23] != 8'h00);
  endfunction

  function automatic bit fp_less_ieee(logic [31:0] a, logic [31:0] b);
    if (is_zero(a) && is_zero(b)) return 1'b0;
    if (a[31] != b[31]) return a[31];
    if (a[31] == 1'b0) return a[30:0] < b[30:0];
    else return a[30:0] > b[30:0];
  endfunction

  function automatic bit fp_less_minmax(logic [31:0] a, logic [31:0] b);
    if (is_zero(a) && is_zero(b)) return a[31] && !b[31]; // -0 < +0
    if (a[31] != b[31]) return a[31];
    if (a[31] == 1'b0) return a[30:0] < b[30:0];
    else return a[30:0] > b[30:0];
  endfunction

  function automatic bit fp_equal_ieee(logic [31:0] a, logic [31:0] b);
    if (is_nan(a) || is_nan(b)) return 1'b0;
    if (is_zero(a) && is_zero(b)) return 1'b1;
    return a == b;
  endfunction

  function automatic logic [9:0] classify_mask(logic [31:0] x);
    logic [9:0] mask;
    mask = 10'h0;

    if (is_inf(x)) begin
      if (x[31]) mask[0] = 1'b1;
      else       mask[7] = 1'b1;
    end else if (is_normal(x)) begin
      if (x[31]) mask[1] = 1'b1;
      else       mask[6] = 1'b1;
    end else if (is_subnormal(x)) begin
      if (x[31]) mask[2] = 1'b1;
      else       mask[5] = 1'b1;
    end else if (is_zero(x)) begin
      if (x[31]) mask[3] = 1'b1;
      else       mask[4] = 1'b1;
    end else if (is_snan(x)) begin
      mask[8] = 1'b1;
    end else if (is_qnan(x)) begin
      mask[9] = 1'b1;
    end

    return mask;
  endfunction

  function automatic bit ready_pattern(int cycle);
    return (cycle % 7 != 0);
  endfunction

  // ------------------------------------------------------------
  // Reference model
  // ------------------------------------------------------------
  function automatic exp_t compute_expected(input_t in);
    exp_t e;
    e.result = 32'h0;
    e.class_mask = 10'h0;
    e.status = 5'h0;
    e.check_result = 1'b0;
    e.check_class = 1'b0;
    e.result_req = 0;
    e.class_req = 0;
    e.status_req = 0;

    case (in.op)
      2'd0: begin // SGNJ
        logic sign;
        case (in.mode)
          3'd0: sign = in.b[31];
          3'd1: sign = ~in.b[31];
          3'd2: sign = in.a[31] ^ in.b[31];
          default: sign = in.b[31];
        endcase
        e.result = {sign, in.a[30:0]};
        e.status = 5'b00000;
        e.check_result = 1'b1;
        e.result_req = REQ_S1;
        e.status_req = REQ_S2;
      end

      2'd1: begin // MINMAX
        e.check_result = 1'b1;

        if (is_nan(in.a) && is_nan(in.b)) begin
          e.result = CAN_QNAN;
          e.result_req = REQ_S5;
        end else if (is_nan(in.a)) begin
          e.result = in.b;
          e.result_req = REQ_S4;
        end else if (is_nan(in.b)) begin
          e.result = in.a;
          e.result_req = REQ_S4;
        end else begin
          bit less = fp_less_minmax(in.a, in.b);
          if (in.mode == 3'd0) e.result = less ? in.a : in.b;
          else                 e.result = less ? in.b : in.a;
          e.result_req = REQ_S3;
        end

        if (is_snan(in.a) || is_snan(in.b))
          e.status = 5'b10000;
        else
          e.status = 5'b00000;

        e.status_req = REQ_S6;
      end

      2'd2: begin // CMP
        e.check_result = 1'b1;
        e.result_req = REQ_S7;

        case (in.mode)
          3'd0: begin // FLE
            if (is_nan(in.a) || is_nan(in.b)) begin
              e.result = 32'h0;
              e.status = 5'b10000;
              e.status_req = REQ_S8;
            end else begin
              e.result = (fp_less_ieee(in.a, in.b) || fp_equal_ieee(in.a, in.b)) ? 32'h1 : 32'h0;
              e.status = 5'b00000;
              e.status_req = REQ_S11;
            end
          end

          3'd1: begin // FLT
            if (is_nan(in.a) || is_nan(in.b)) begin
              e.result = 32'h0;
              e.status = 5'b10000;
              e.status_req = REQ_S8;
            end else begin
              e.result = fp_less_ieee(in.a, in.b) ? 32'h1 : 32'h0;
              e.status = 5'b00000;
              e.status_req = REQ_S11;
            end
          end

          3'd2: begin // FEQ
            if (is_nan(in.a) || is_nan(in.b)) begin
              e.result = 32'h0;
              if (is_snan(in.a) || is_snan(in.b)) begin
                e.status = 5'b10000;
                e.status_req = REQ_S9;
              end else begin
                e.status = 5'b00000;
                e.status_req = REQ_S9;
              end
            end else begin
              e.result = fp_equal_ieee(in.a, in.b) ? 32'h1 : 32'h0;
              e.status = 5'b00000;
              e.status_req = REQ_S11;
            end
          end

          default: begin
            e.result = 32'h0;
            e.status = 5'b00000;
            e.status_req = REQ_S11;
          end
        endcase
      end

      2'd3: begin // CLASSIFY
        e.check_class = 1'b1;
        e.class_mask = classify_mask(in.a);
        e.class_req = REQ_S12;
        e.status = 5'b00000;
        e.status_req = REQ_S13;
      end

      default: begin
        e.result = 32'h0;
        e.class_mask = 10'h0;
        e.status = 5'b00000;
      end
    endcase

    return e;
  endfunction

  // ------------------------------------------------------------
  // Check / fail helpers
  // ------------------------------------------------------------
  task automatic fail(string req);
    $display("FAIL: %s", req);
    errors++;
  endtask

  task automatic check_output();
    if (exp_q.size() == 0) begin
      fail("H2");
      return;
    end

    exp_t e = exp_q.pop_front();

    if (e.check_result && result_o !== e.result) begin
      fail(req_name(e.result_req));
    end

    if (e.check_class && class_mask_o !== e.class_mask) begin
      fail(req_name(e.class_req));
    end

    if (status_o !== e.status) begin
      fail(req_name(e.status_req));
    end
  endtask

  // ------------------------------------------------------------
  // Stimulus / drain tasks
  // ------------------------------------------------------------
  task automatic run_ops(input input_t ops[$]);
    int cycle_count = 0;

    out_ready_i <= 1'b1;
    in_valid_i  <= 1'b0;
    @(posedge clk); // settle

    for (int i = 0; i < ops.size(); i++) begin
      in_valid_i  <= 1'b1;
      operand_a_i <= ops[i].a;
      operand_b_i <= ops[i].b;
      op_i        <= ops[i].op;
      op_mode_i   <= ops[i].mode;

      bit accepted = 0;
      while (!accepted) begin
        @(posedge clk);

        // Input handshake
        if (in_ready_o === 1'b1) begin
          exp_q.push_back(compute_expected(ops[i]));
          accepted = 1;
        end

        // Output handshake
        if (out_valid_o === 1'b1 && out_ready_i === 1'b1) begin
          check_output();
        end

        cycle_count++;
        out_ready_i <= ready_pattern(cycle_count);
      end
    end

    in_valid_i <= 1'b0;

    // Drain remaining outputs
    while (exp_q.size() > 0) begin
      @(posedge clk);

      if (out_valid_o === 1'b1 && out_ready_i === 1'b1) begin
        check_output();
      end

      cycle_count++;
      out_ready_i <= ready_pattern(cycle_count);
    end

    out_ready_i <= 1'b0;
  endtask

  task automatic check_no_output(int cycles);
    out_ready_i <= 1'b1;
    repeat (cycles) begin
      @(posedge clk);
      if (out_valid_o !== 1'b0) begin
        fail("H2");
      end
      out_ready_i <= 1'b1;
    end
    out_ready_i <= 1'b0;
  endtask

  task automatic reset_and_check();
    rst_ni      <= 1'b0;
    in_valid_i  <= 1'b0;
    out_ready_i <= 1'b0;

    repeat (5) @(posedge clk);

    rst_ni <= 1'b1;
    @(posedge clk); // first posedge after release
    if (out_valid_o !== 1'b0) begin
      fail(req_name(REQ_S15));
    end
  endtask

  task automatic backpressure_hold_test();
    input_t bops[$];
    bops.push_back('{op:2'd0, mode:3'd0, a:ONE, b:NEG_ONE});
    bops.push_back('{op:2'd1, mode:3'd0, a:ONE, b:TWO});

    // First operation: accepted while out_ready is low
    out_ready_i <= 1'b0;
    in_valid_i  <= 1'b0;
    @(posedge clk);

    in_valid_i  <= 1'b1;
    operand_a_i <= bops[0].a;
    operand_b_i <= bops[0].b;
    op_i        <= bops[0].op;
    op_mode_i   <= bops[0].mode;

    begin
      bit accepted = 0;
      while (!accepted) begin
        @(posedge clk);
        if (in_ready_o === 1'b1) begin
          exp_q.push_back(compute_expected(bops[0]));
          accepted = 1;
        end
        out_ready_i <= 1'b0;
      end
    end

    in_valid_i <= 1'b0;

    // Hold out_ready low for many consecutive cycles (H3)
    repeat (30) begin
      @(posedge clk);
      out_ready_i <= 1'b0;
    end

    // Drain first operation
    out_ready_i <= 1'b1;
    while (exp_q.size() > 0) begin
      @(posedge clk);
      if (out_valid_o === 1'b1 && out_ready_i === 1'b1) begin
        check_output();
      end
      out_ready_i <= 1'b1;
    end
    out_ready_i <= 1'b0;

    // Second operation: check still works after backpressure
    in_valid_i  <= 1'b1;
    operand_a_i <= bops[1].a;
    operand_b_i <= bops[1].b;
    op_i        <= bops[1].op;
    op_mode_i   <= bops[1].mode;

    begin
      bit accepted = 0;
      while (!accepted) begin
        @(posedge clk);
        if (in_ready_o === 1'b1) begin
          exp_q.push_back(compute_expected(bops[1]));
          accepted = 1;
        end
        out_ready_i <= 1'b1;
      end
    end

    in_valid_i <= 1'b0;

    out_ready_i <= 1'b1;
    while (exp_q.size() > 0) begin
      @(posedge clk);
      if (out_valid_o === 1'b1 && out_ready_i === 1'b1) begin
        check_output();
      end
      out_ready_i <= 1'b1;
    end
    out_ready_i <= 1'b0;
  endtask

  task automatic reset_discard_test();
    input_t rop;
    rop = '{op:2'd0, mode:3'd0, a:ONE, b:NEG_ONE};

    out_ready_i <= 1'b0;
    in_valid_i  <= 1'b0;
    @(posedge clk);

    in_valid_i  <= 1'b1;
    operand_a_i <= rop.a;
    operand_b_i <= rop.b;
    op_i        <= rop.op;
    op_mode_i   <= rop.mode;

    begin
      bit accepted = 0;
      while (!accepted) begin
        @(posedge clk);
        if (in_ready_o === 1'b1) begin
          exp_q.push_back(compute_expected(rop));
          accepted = 1;
        end
        out_ready_i <= 1'b0;
      end
    end

    in_valid_i <= 1'b0;

    // Allow a couple of cycles, then clear expected: reset must discard this op.
    repeat (2) @(posedge clk);
    exp_q.delete();

    rst_ni      <= 1'b0;
    out_ready_i <= 1'b0;
    repeat (5) @(posedge clk);

    rst_ni <= 1'b1;
    @(posedge clk); // first posedge after release
    if (out_valid_o !== 1'b0) begin
      fail(req_name(REQ_S15));
    end

    out_ready_i <= 1'b1;
    repeat (20) begin
      @(posedge clk);
      if (out_valid_o !== 1'b0) begin
        fail(req_name(REQ_S15));
      end
      out_ready_i <= 1'b1;
    end
    out_ready_i <= 1'b0;
  endtask

  // ------------------------------------------------------------
  // Main test sequence
  // ------------------------------------------------------------
  initial begin
    // Build comprehensive operation list
    // SGNJ
    ops.push_back('{op:2'd0, mode:3'd0, a:ONE,     b:NEG_ONE});
    ops.push_back('{op:2'd0, mode:3'd1, a:ONE,     b:NEG_ONE});
    ops.push_back('{op:2'd0, mode:3'd2, a:ONE,     b:NEG_ONE});
    ops.push_back('{op:2'd0, mode:3'd0, a:SNAN,    b:ONE});
    ops.push_back('{op:2'd0, mode:3'd1, a:SNAN,    b:ONE});
    ops.push_back('{op:2'd0, mode:3'd2, a:SNAN,    b:NEG_ONE});
    ops.push_back('{op:2'd0, mode:3'd0, a:QNAN_1,  b:NEG_ONE});
    ops.push_back('{op:2'd0, mode:3'd2, a:ONE,     b:ONE});
    ops.push_back('{op:2'd0, mode:3'd0, a:NZERO,   b:POS_INF});
    ops.push_back('{op:2'd0, mode:3'd1, a:PZERO,   b:POS_INF});

    // MINMAX: non-NaN
    ops.push_back('{op:2'd1, mode:3'd0, a:ONE,     b:TWO});
    ops.push_back('{op:2'd1, mode:3'd1, a:ONE,     b:TWO});
    ops.push_back('{op:2'd1, mode:3'd0, a:TWO,     b:ONE});
    ops.push_back('{op:2'd1, mode:3'd1, a:TWO,     b:ONE});
    ops.push_back('{op:2'd1, mode:3'd0, a:NEG_ONE, b:TWO});
    ops.push_back('{op:2'd1, mode:3'd1, a:NEG_ONE, b:TWO});
    ops.push_back('{op:2'd1, mode:3'd0, a:NEG_TWO, b:NEG_ONE});
    ops.push_back('{op:2'd1, mode:3'd1, a:NEG_TWO, b:NEG_ONE});
    ops.push_back('{op:2'd1, mode:3'd0, a:NZERO,   b:PZERO});
    ops.push_back('{op:2'd1, mode:3'd1, a:NZERO,   b:PZERO});
    ops.push_back('{op:2'd1, mode:3'd0, a:PZERO,   b:NZERO});
    ops.push_back('{op:2'd1, mode:3'd1, a:PZERO,   b:NZERO});
    ops.push_back('{op:2'd1, mode:3'd0, a:NZERO,   b:ONE});
    ops.push_back('{op:2'd1, mode:3'd1, a:NZERO,   b:ONE});
    ops.push_back('{op:2'd1, mode:3'd0, a:NEG_INF, b:POS_INF});
    ops.push_back('{op:2'd1, mode:3'd1, a:NEG_INF, b:POS_INF});

    // MINMAX: exactly one NaN
    ops.push_back('{op:2'd1, mode:3'd0, a:CAN_QNAN, b:ONE});
    ops.push_back('{op:2'd1, mode:3'd1, a:ONE,      b:CAN_QNAN});
    ops.push_back('{op:2'd1, mode:3'd0, a:SNAN,     b:ONE});
    ops.push_back('{op:2'd1, mode:3'd1, a:ONE,      b:SNAN});
    ops.push_back('{op:2'd1, mode:3'd0, a:QNAN_1,   b:NEG_INF});
    ops.push_back('{op:2'd1, mode:3'd1, a:NEG_INF,  b:QNAN_1});

    // MINMAX: both NaN
    ops.push_back('{op:2'd1, mode:3'd0, a:CAN_QNAN, b:QNAN_1});
    ops.push_back('{op:2'd1, mode:3'd1, a:CAN_QNAN, b:QNAN_NEG});
    ops.push_back('{op:2'd1, mode:3'd0, a:SNAN,     b:CAN_QNAN});
    ops.push_back('{op:2'd1, mode:3'd1, a:SNAN,     b:SNAN_NEG});

    // CMP
    ops.push_back('{op:2'd2, mode:3'd0, a:ONE,     b:TWO});
    ops.push_back('{op:2'd2, mode:3'd0, a:TWO,     b:ONE});
    ops.push_back('{op:2'd2, mode:3'd1, a:ONE,     b:TWO});
    ops.push_back('{op:2'd2, mode:3'd1, a:TWO,     b:ONE});
    ops.push_back('{op:2'd2, mode:3'd0, a:ONE,     b:ONE});
    ops.push_back('{op:2'd2, mode:3'd1, a:ONE,     b:ONE});
    ops.push_back('{op:2'd2, mode:3'd2, a:ONE,     b:ONE});
    ops.push_back('{op:2'd2, mode:3'd2, a:ONE,     b:TWO});
    ops.push_back('{op:2'd2, mode:3'd2, a:NZERO,   b:PZERO});
    ops.push_back('{op:2'd2, mode:3'd2, a:PZERO,   b:NZERO});
    ops.push_back('{op:2'd2, mode:3'd1, a:NZERO,   b:PZERO});
    ops.push_back('{op:2'd2, mode:3'd0, a:NZERO,   b:PZERO});
    ops.push_back('{op:2'd2, mode:3'd1, a:NEG_ONE, b:PZERO});
    ops.push_back('{op:2'd2, mode:3'd0, a:PZERO,   b:NEG_ONE});
    ops.push_back('{op:2'd2, mode:3'd1, a:NEG_INF, b:POS_INF});
    ops.push_back('{op:2'd2, mode:3'd0, a:POS_INF, b:NEG_INF});
    ops.push_back('{op:2'd2, mode:3'd1, a:NEG_TWO, b:NEG_ONE});
    ops.push_back('{op:2'd2, mode:3'd1, a:NEG_ONE, b:NEG_TWO});
    ops.push_back('{op:2'd2, mode:3'd0, a:NEG_TWO, b:NEG_ONE});
    ops.push_back('{op:2'd2, mode:3'd0, a:NEG_ONE, b:NEG_TWO});

    // CMP: NaN
    ops.push_back('{op:2'd2, mode:3'd1, a:CAN_QNAN, b:ONE});
    ops.push_back('{op:2'd2, mode:3'd0, a:ONE,      b:CAN_QNAN});
    ops.push_back('{op:2'd2, mode:3'd1, a:SNAN,     b:ONE});
    ops.push_back('{op:2'd2, mode:3'd0, a:ONE,      b:SNAN});
    ops.push_back('{op:2'd2, mode:3'd2, a:CAN_QNAN, b:ONE});
    ops.push_back('{op:2'd2, mode:3'd2, a:SNAN,     b:ONE});
    ops.push_back('{op:2'd2, mode:3'd2, a:CAN_QNAN, b:QNAN_1});
    ops.push_back('{op:2'd2, mode:3'd2, a:SNAN,     b:CAN_QNAN});

    // CLASSIFY
    ops.push_back('{op:2'd3, mode:3'd0, a:NEG_INF,   b:DEAD});
    ops.push_back('{op:2'd3, mode:3'd0, a:NEG_ONE,   b:RANDOM});
    ops.push_back('{op:2'd3, mode:3'd0, a:NEG_SUB,   b:PZERO});
    ops.push_back('{op:2'd3, mode:3'd0, a:NZERO,     b:ONE});
    ops.push_back('{op:2'd3, mode:3'd0, a:PZERO,     b:NEG_ONE});
    ops.push_back('{op:2'd3, mode:3'd0, a:POS_SUB,   b:SNAN});
    ops.push_back('{op:2'd3, mode:3'd0, a:ONE,       b:QNAN_1});
    ops.push_back('{op:2'd3, mode:3'd0, a:POS_INF,   b:NZERO});
    ops.push_back('{op:2'd3, mode:3'd0, a:SNAN,      b:ONE});
    ops.push_back('{op:2'd3, mode:3'd0, a:QNAN_1,    b:ONE});
    ops.push_back('{op:2'd3, mode:3'd5, a:SNAN_NEG,  b:ONE});
    ops.push_back('{op:2'd3, mode:3'd7, a:QNAN_NEG,  b:ONE});

    // Run main sequence
    reset_and_check();
    run_ops(ops);
    check_no_output(20);

    backpressure_hold_test();
    check_no_output(20);

    reset_discard_test();
    check_no_output(20);

    // Post-reset operations
    begin
      input_t post_ops[$];
      post_ops.push_back('{op:2'd0, mode:3'd0, a:ONE,   b:NEG_ONE});
      post_ops.push_back('{op:2'd1, mode:3'd0, a:ONE,   b:TWO});
      post_ops.push_back('{op:2'd2, mode:3'd2, a:NZERO, b:PZERO});
      post_ops.push_back('{op:2'd3, mode:3'd0, a:SNAN,  b:NEG_ONE});
      run_ops(post_ops);
      check_no_output(20);
    end

    if (errors == 0) $display("RESULT: PASS");
    else             $display("RESULT: FAIL");
    $finish;
  end

endmodule