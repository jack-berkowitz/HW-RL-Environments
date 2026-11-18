module fp_noncomp_tb;

  logic        clk_i;
  logic        rst_ni;
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
      .clk_i        (clk_i),
      .rst_ni       (rst_ni),
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
  // PROVIDED PLUMBING -- issues operations, checks nothing.
  // ---------------------------------------------------------------------------
  logic clk;
  initial begin clk = 1'b0; forever #5 clk = ~clk; end

  logic rst_n;
  initial rst_n = 1'b0;

  assign clk_i  = clk;
  assign rst_ni = rst_n;

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

  // Independent, unconditional termination required by S16.
  initial begin
    #200_000_000;
    $display("FAIL [S16] watchdog: no forward progress");
    $display("RESULT: FAIL");
    $finish;
  end

  // ---------------------------------------------------------------------------
  // Reference model
  // ---------------------------------------------------------------------------
  typedef struct {
    logic [31:0] res;
    logic [9:0]  mask;
    logic [4:0]  flags;
    logic        check_res;
    logic        check_mask;
    int          seq_no;
    logic [31:0] a;
    logic [31:0] b;
    logic [1:0]  op_code;
    logic [2:0]  mode;
  } exp_t;

  exp_t exp_q[$];
  exp_t monitor_exp;

  integer error_count;
  integer next_seq;
  integer stall_cycles;
  integer post_reset_cycles;
  logic   reset_active_seen;

  function automatic logic is_nan(input logic [31:0] value);
    begin
      is_nan = (value[30:23] == 8'hff) && (value[22:0] != 23'b0);
    end
  endfunction

  function automatic logic is_snan(input logic [31:0] value);
    begin
      is_snan = (value[30:23] == 8'hff) &&
                (value[22:0] != 23'b0) && !value[22];
    end
  endfunction

  function automatic logic is_zero(input logic [31:0] value);
    begin
      is_zero = (value[30:0] == 31'b0);
    end
  endfunction

  // Numeric equality for non-NaN operands.  The explicit zero case implements
  // S10; all other non-NaN binary32 values have a unique representation.
  function automatic logic fp_equal(input logic [31:0] a,
                                    input logic [31:0] b);
    begin
      if (is_nan(a) || is_nan(b))
        fp_equal = 1'b0;
      else if (is_zero(a) && is_zero(b))
        fp_equal = 1'b1;
      else
        fp_equal = (a == b);
    end
  endfunction

  // IEEE numeric less-than for non-NaN operands, with zeros comparing equal.
  function automatic logic fp_less(input logic [31:0] a,
                                   input logic [31:0] b);
    begin
      if (is_nan(a) || is_nan(b))
        fp_less = 1'b0;
      else if (is_zero(a) && is_zero(b))
        fp_less = 1'b0;
      else if (a[31] != b[31])
        fp_less = a[31];
      else if (!a[31])
        fp_less = (a[30:0] < b[30:0]);
      else
        fp_less = (a[30:0] > b[30:0]);
    end
  endfunction

  function automatic exp_t predict(input logic [31:0] a,
                                   input logic [31:0] b,
                                   input logic [1:0]  op,
                                   input logic [2:0]  mode);
    exp_t e;
    logic nv;
    logic truth;
    logic lt_ab;
    logic eq_ab;
    logic [31:0] res;
    logic [9:0] mask;
    begin
      e.res        = 32'b0;
      e.mask       = 10'b0;
      e.flags      = 5'b0;
      e.check_res  = 1'b1;
      e.check_mask = 1'b0;
      e.seq_no     = 0;
      e.a          = a;
      e.b          = b;
      e.op_code    = op;
      e.mode       = mode;

      nv    = 1'b0;
      truth = 1'b0;
      lt_ab = 1'b0;
      eq_ab = 1'b0;
      res   = 32'b0;
      mask  = 10'b0;

      case (op)
        2'd0: begin : model_sgnj
          case (mode)
            3'd0: res = {b[31], a[30:0]};
            3'd1: res = {~b[31], a[30:0]};
            3'd2: res = {a[31] ^ b[31], a[30:0]};
            default: res = {b[31], a[30:0]};
          endcase
          nv = 1'b0;
        end

        2'd1: begin : model_minmax
          nv = is_snan(a) || is_snan(b);

          if (is_nan(a) && is_nan(b)) begin
            res = 32'h7fc0_0000;
          end else if (is_nan(a)) begin
            res = b;
          end else if (is_nan(b)) begin
            res = a;
          end else if (is_zero(a) && is_zero(b)) begin
            // MIN treats -0 as below +0; MAX consequently prefers +0.
            if (mode == 3'd0)
              res = {(a[31] | b[31]), 31'b0};
            else
              res = {(a[31] & b[31]), 31'b0};
          end else begin
            lt_ab = fp_less(a, b);
            if (mode == 3'd0)
              res = lt_ab ? a : b;
            else
              res = lt_ab ? b : a;
          end
        end

        2'd2: begin : model_cmp
          if (mode == 3'd2) begin
            // FEQ is quiet except for a signalling-NaN operand.
            nv = is_snan(a) || is_snan(b);
            if (is_nan(a) || is_nan(b))
              truth = 1'b0;
            else
              truth = fp_equal(a, b);
          end else begin
            // FLE and FLT are signalling for either kind of NaN.
            if (is_nan(a) || is_nan(b)) begin
              nv    = 1'b1;
              truth = 1'b0;
            end else begin
              nv    = 1'b0;
              lt_ab = fp_less(a, b);
              eq_ab = fp_equal(a, b);
              if (mode == 3'd0)
                truth = lt_ab || eq_ab;
              else
                truth = lt_ab;
            end
          end
          res = truth ? 32'h0000_0001 : 32'h0000_0000;
        end

        2'd3: begin : model_classify
          e.check_res  = 1'b0;
          e.check_mask = 1'b1;
          nv           = 1'b0;
          mask         = 10'b0;

          if (a[30:23] == 8'hff) begin
            if (a[22:0] == 23'b0) begin
              if (a[31]) mask[0] = 1'b1;
              else       mask[7] = 1'b1;
            end else if (!a[22]) begin
              mask[8] = 1'b1;
            end else begin
              mask[9] = 1'b1;
            end
          end else if (a[30:23] == 8'h00) begin
            if (a[22:0] == 23'b0) begin
              if (a[31]) mask[3] = 1'b1;
              else       mask[4] = 1'b1;
            end else begin
              if (a[31]) mask[2] = 1'b1;
              else       mask[5] = 1'b1;
            end
          end else begin
            if (a[31]) mask[1] = 1'b1;
            else       mask[6] = 1'b1;
          end
        end
      endcase

      e.res   = res;
      e.mask  = mask;
      e.flags = {nv, 4'b0000};
      predict = e;
    end
  endfunction

  // ---------------------------------------------------------------------------
  // Scoreboard and output checking
  // ---------------------------------------------------------------------------
  task automatic report_failure(input string req, input string detail);
    begin
      error_count = error_count + 1;
      $display("FAIL [%s] %s", req, detail);
    end
  endtask

  task automatic send_op(input logic [31:0] a,
                         input logic [31:0] b,
                         input logic [1:0]  op,
                         input logic [2:0]  mode);
    exp_t new_exp;
    begin
      new_exp = predict(a, b, op, mode);
      new_exp.seq_no = next_seq;
      next_seq = next_seq + 1;

      // Enqueue before presenting the request.  This also supports an
      // implementation whose result handshake coincides with acceptance.
      exp_q.push_back(new_exp);
      bfm_issue(a, b, op, mode);
    end
  endtask

  task automatic wait_all_results();
    begin
      while (exp_q.size() != 0)
        @(posedge clk);
    end
  endtask

  always @(posedge clk) begin
    if (!rst_n) begin
      exp_q.delete();
      reset_active_seen = 1'b1;
      post_reset_cycles = 0;
    end else begin
      if (!out_ready_i)
        stall_cycles = stall_cycles + 1;

      if (reset_active_seen) begin
        if (out_valid_o !== 1'b0)
          report_failure("S15",
            $sformatf("out_valid_o was not low on the first cycle after reset release (value=%b)",
                      out_valid_o));
        reset_active_seen = 1'b0;
        post_reset_cycles = 40;
      end else if (post_reset_cycles > 0) begin
        post_reset_cycles = post_reset_cycles - 1;
      end

      if ((out_valid_o === 1'b1) && (out_ready_i === 1'b1)) begin
        if (exp_q.size() == 0) begin
          if (post_reset_cycles > 0)
            report_failure("S15",
              "an operation discarded by reset produced a post-reset result");
          else
            report_failure("H2",
              "result handshake with an empty scoreboard: duplicated, lost, or reordered result");
        end else begin
          monitor_exp = exp_q.pop_front();

          if (monitor_exp.check_res && (result_o !== monitor_exp.res)) begin
            case (monitor_exp.op_code)
              2'd0:
                report_failure("S1",
                  $sformatf("seq=%0d SGNJ result=%08x expected=%08x a=%08x b=%08x mode=%0d",
                            monitor_exp.seq_no, result_o, monitor_exp.res,
                            monitor_exp.a, monitor_exp.b, monitor_exp.mode));
              2'd1: begin
                if (is_nan(monitor_exp.a) && is_nan(monitor_exp.b))
                  report_failure("S5",
                    $sformatf("seq=%0d two-NaN MINMAX result=%08x expected=%08x",
                              monitor_exp.seq_no, result_o, monitor_exp.res));
                else if (is_nan(monitor_exp.a) || is_nan(monitor_exp.b))
                  report_failure("S4",
                    $sformatf("seq=%0d one-NaN MINMAX result=%08x expected=%08x a=%08x b=%08x",
                              monitor_exp.seq_no, result_o, monitor_exp.res,
                              monitor_exp.a, monitor_exp.b));
                else
                  report_failure("S3",
                    $sformatf("seq=%0d MINMAX result=%08x expected=%08x a=%08x b=%08x mode=%0d",
                              monitor_exp.seq_no, result_o, monitor_exp.res,
                              monitor_exp.a, monitor_exp.b, monitor_exp.mode));
              end
              2'd2:
                report_failure("S7",
                  $sformatf("seq=%0d CMP result=%08x expected=%08x a=%08x b=%08x mode=%0d",
                            monitor_exp.seq_no, result_o, monitor_exp.res,
                            monitor_exp.a, monitor_exp.b, monitor_exp.mode));
              default:
                report_failure("H2",
                  $sformatf("seq=%0d unexpected checked result mismatch",
                            monitor_exp.seq_no));
            endcase
          end

          if (monitor_exp.check_mask &&
              (class_mask_o !== monitor_exp.mask)) begin
            report_failure("S12",
              $sformatf("seq=%0d CLASSIFY mask=%03x expected=%03x a=%08x b=%08x",
                        monitor_exp.seq_no, class_mask_o, monitor_exp.mask,
                        monitor_exp.a, monitor_exp.b));
          end

          if (status_o !== monitor_exp.flags) begin
            case (monitor_exp.op_code)
              2'd0:
                report_failure("S2",
                  $sformatf("seq=%0d SGNJ status=%02x expected=%02x",
                            monitor_exp.seq_no, status_o, monitor_exp.flags));
              2'd1:
                report_failure("S6",
                  $sformatf("seq=%0d MINMAX status=%02x expected=%02x a=%08x b=%08x",
                            monitor_exp.seq_no, status_o, monitor_exp.flags,
                            monitor_exp.a, monitor_exp.b));
              2'd2: begin
                if (monitor_exp.mode == 3'd2)
                  report_failure("S9",
                    $sformatf("seq=%0d FEQ status=%02x expected=%02x a=%08x b=%08x",
                              monitor_exp.seq_no, status_o, monitor_exp.flags,
                              monitor_exp.a, monitor_exp.b));
                else
                  report_failure("S8",
                    $sformatf("seq=%0d FLT/FLE status=%02x expected=%02x a=%08x b=%08x",
                              monitor_exp.seq_no, status_o, monitor_exp.flags,
                              monitor_exp.a, monitor_exp.b));
              end
              default:
                report_failure("S13",
                  $sformatf("seq=%0d CLASSIFY status=%02x expected=%02x",
                            monitor_exp.seq_no, status_o, monitor_exp.flags));
            endcase
          end

          if (status_o[3:0] !== 4'b0000) begin
            report_failure("S14",
              $sformatf("seq=%0d DZ/OF/UF/NX were not all zero: status=%02x",
                        monitor_exp.seq_no, status_o));
          end
        end
      end
    end
  end

  // ---------------------------------------------------------------------------
  // Stimulus
  // ---------------------------------------------------------------------------
  localparam integer SPECIAL_COUNT = 24;

  function automatic logic [31:0] special_value(input integer idx);
    begin
      case (idx)
         0: special_value = 32'h0000_0000; // +0
         1: special_value = 32'h8000_0000; // -0
         2: special_value = 32'h3f80_0000; // +1
         3: special_value = 32'hbf80_0000; // -1
         4: special_value = 32'h4000_0000; // +2
         5: special_value = 32'hc000_0000; // -2
         6: special_value = 32'h3f00_0000; // +0.5
         7: special_value = 32'hbf00_0000; // -0.5
         8: special_value = 32'h7f80_0000; // +infinity
         9: special_value = 32'hff80_0000; // -infinity
        10: special_value = 32'h7fc0_0000; // canonical qNaN
        11: special_value = 32'hffc0_0000; // negative qNaN
        12: special_value = 32'h7f80_0001; // sNaN
        13: special_value = 32'hff80_0001; // negative sNaN
        14: special_value = 32'h7fc0_0001; // qNaN with payload
        15: special_value = 32'h7fbf_ffff; // sNaN with payload
        16: special_value = 32'h0000_0001; // minimum +subnormal
        17: special_value = 32'h8000_0001; // minimum -subnormal
        18: special_value = 32'h007f_ffff; // maximum +subnormal
        19: special_value = 32'h807f_ffff; // maximum -subnormal
        20: special_value = 32'h0080_0000; // minimum +normal
        21: special_value = 32'h8080_0000; // minimum -normal
        22: special_value = 32'h7f7f_ffff; // maximum finite +
        23: special_value = 32'hff7f_ffff; // maximum finite -
        default: special_value = 32'h0000_0000;
      endcase
    end
  endfunction

  task automatic run_directed_tests();
    integer i;
    integer j;
    integer m;
    logic [31:0] av;
    logic [31:0] bv;
    begin
      // Exhaustive pairs over the special-value set exercise NaN kinds and
      // payloads, infinities, subnormals, normals, and both signed zeros.
      for (i = 0; i < SPECIAL_COUNT; i = i + 1) begin
        av = special_value(i);
        for (j = 0; j < SPECIAL_COUNT; j = j + 1) begin
          bv = special_value(j);

          for (m = 0; m < 3; m = m + 1)
            send_op(av, bv, 2'd0, m[2:0]);

          for (m = 0; m < 2; m = m + 1)
            send_op(av, bv, 2'd1, m[2:0]);

          for (m = 0; m < 3; m = m + 1)
            send_op(av, bv, 2'd2, m[2:0]);
        end
      end

      // Vary operand_b and op_mode to verify that CLASSIFY ignores both.
      for (i = 0; i < SPECIAL_COUNT; i = i + 1) begin
        av = special_value(i);
        for (j = 0; j < SPECIAL_COUNT; j = j + 1) begin
          bv = special_value(j);
          send_op(av, bv, 2'd3, (i + j) % 8);
        end
      end

      bfm_idle();
      wait_all_results();
    end
  endtask

  task automatic run_single_long_stall();
    begin
      bfm_out_ready(1'b0);
      send_op(32'h3f80_0000, 32'h4000_0000, 2'd1, 3'd0);
      bfm_idle();

      // More than the required twenty cycles of result-side backpressure.
      repeat (35) @(posedge clk);

      bfm_out_ready(1'b1);
      wait_all_results();
    end
  endtask

  task automatic run_random_ops(input integer count);
    integer n;
    integer op_pick;
    integer mode_pick;
    logic [31:0] av;
    logic [31:0] bv;
    logic [1:0] op_val;
    logic [2:0] mode_val;
    begin
      for (n = 0; n < count; n = n + 1) begin
        av = $urandom();
        bv = $urandom();

        if ((n % 5) == 0)
          av = special_value(n % SPECIAL_COUNT);
        if ((n % 7) == 0)
          bv = special_value((3 * n + 1) % SPECIAL_COUNT);

        op_pick = $urandom_range(3, 0);
        op_val  = op_pick[1:0];

        case (op_val)
          2'd0, 2'd2: mode_pick = $urandom_range(2, 0);
          2'd1:       mode_pick = $urandom_range(1, 0);
          default:    mode_pick = $urandom_range(7, 0);
        endcase
        mode_val = mode_pick[2:0];

        send_op(av, bv, op_val, mode_val);
      end
      bfm_idle();
    end
  endtask

  task automatic run_ready_wave();
    integer n;
    begin
      for (n = 0; n < 16; n = n + 1) begin
        bfm_out_ready(1'b0);
        repeat (3 + (n % 4)) @(posedge clk);
        bfm_out_ready(1'b1);
        repeat (2) @(posedge clk);
      end
      bfm_out_ready(1'b1);
    end
  endtask

  task automatic run_reset_discard_test();
    begin
      // Accept an operation and prevent its result from being delivered.
      bfm_out_ready(1'b0);
      send_op(32'h7fc0_0001, 32'h3f80_0000, 2'd1, 3'd0);
      bfm_idle();
      repeat (6) @(posedge clk);

      // The monitor discards the corresponding expectation on reset.  Any
      // subsequent result from this operation is therefore reported under S15.
      bfm_reset(3);
      bfm_out_ready(1'b1);
      repeat (20) @(posedge clk);

      // Confirm normal operation after reset as well.
      send_op(32'h7fc0_0001, 32'h8000_0000, 2'd0, 3'd0);
      bfm_idle();
      wait_all_results();
    end
  endtask

  initial begin : main_test
    operand_a_i = 32'b0;
    operand_b_i = 32'b0;
    op_i        = 2'b0;
    op_mode_i   = 3'b0;
    in_valid_i  = 1'b0;
    out_ready_i = 1'b0;

    error_count       = 0;
    next_seq          = 0;
    stall_cycles      = 0;
    post_reset_cycles = 0;
    reset_active_seen = 1'b0;

    bfm_reset(4);
    bfm_out_ready(1'b1);

    run_directed_tests();
    run_single_long_stall();

    fork
      run_ready_wave();
      run_random_ops(600);
    join
    wait_all_results();

    run_reset_discard_test();

    bfm_idle();
    bfm_out_ready(1'b1);
    repeat (3) @(posedge clk);

    if (stall_cycles < 20)
      report_failure("H3",
        $sformatf("insufficient backpressure stimulus: only %0d ready-low cycles",
                  stall_cycles));

    if (exp_q.size() != 0)
      report_failure("H2",
        $sformatf("%0d accepted operations remained undelivered at end of test",
                  exp_q.size()));

    if (error_count == 0)
      $display("RESULT: PASS");
    else
      $display("RESULT: FAIL");

    $finish;
  end

endmodule
