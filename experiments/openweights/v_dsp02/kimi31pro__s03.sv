`timescale 1ns/1ps

module fp_noncomp_tb;

  logic        clk;
  logic        rst_n;

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

  // -------------------------------------------------------------------------
  // Reference model and scoreboard
  // -------------------------------------------------------------------------

  typedef struct packed {
    logic [31:0] res;
    logic [9:0]  mask;
    logic [4:0]  flags;
    logic        check_res;
    logic [1:0]  op;
    logic [2:0]  mode;
    logic [31:0] a;
    logic [31:0] b;
    logic [31:0] id;
  } exp_t;

  exp_t exp_q[$];

  int unsigned errors;
  int unsigned accept_total;
  int unsigned delivered_total;
  int unsigned flushed_total;
  int unsigned stall_cycles;
  logic        prev_rst_n;

  function automatic logic is_nan(input logic [31:0] a);
    begin
      is_nan = (&a[30:23]) && (|a[22:0]);
    end
  endfunction

  function automatic logic is_snan(input logic [31:0] a);
    begin
      is_snan = is_nan(a) && !a[22];
    end
  endfunction

  function automatic logic is_zero(input logic [31:0] a);
    begin
      is_zero = (a[30:0] == 31'b0);
    end
  endfunction

  // Called only for non-NaN operands.
  function automatic logic fp_equal(input logic [31:0] a,
                                    input logic [31:0] b);
    begin
      fp_equal = (a == b) || (is_zero(a) && is_zero(b));
    end
  endfunction

  // Called only for non-NaN operands.  Zeros compare equal here.
  function automatic logic fp_less(input logic [31:0] a,
                                   input logic [31:0] b);
    begin
      if (is_zero(a) && is_zero(b)) begin
        fp_less = 1'b0;
      end else if (a[31] != b[31]) begin
        fp_less = a[31];
      end else if (!a[31]) begin
        fp_less = (a[30:0] < b[30:0]);
      end else begin
        fp_less = (a[30:0] > b[30:0]);
      end
    end
  endfunction

  function automatic logic [9:0] class_bits(input logic [31:0] a);
    begin
      if (is_nan(a)) begin
        if (a[22])
          class_bits = 10'h200;  // quiet NaN
        else
          class_bits = 10'h100;  // signalling NaN
      end else if (a[30:23] == 8'hff) begin
        if (a[31])
          class_bits = 10'h001;  // -infinity
        else
          class_bits = 10'h080;  // +infinity
      end else if (a[30:23] == 8'h00) begin
        if (a[22:0] == 23'b0) begin
          if (a[31])
            class_bits = 10'h008;  // -zero
          else
            class_bits = 10'h010;  // +zero
        end else begin
          if (a[31])
            class_bits = 10'h004;  // -subnormal
          else
            class_bits = 10'h020;  // +subnormal
        end
      end else begin
        if (a[31])
          class_bits = 10'h002;  // -normal
        else
          class_bits = 10'h040;  // +normal
      end
    end
  endfunction

  function automatic exp_t predict(input logic [31:0] a,
                                   input logic [31:0] b,
                                   input logic [1:0]  op,
                                   input logic [2:0]  mode);
    exp_t e;
    logic nv;
    logic a_nan;
    logic b_nan;
    logic a_snan;
    logic b_snan;
    logic new_sign;
    begin
      e       = '0;
      e.op    = op;
      e.mode  = mode;
      e.a     = a;
      e.b     = b;
      e.id    = accept_total;
      e.check_res = 1'b1;

      nv      = 1'b0;
      a_nan   = is_nan(a);
      b_nan   = is_nan(b);
      a_snan  = is_snan(a);
      b_snan  = is_snan(b);
      new_sign = 1'b0;

      case (op)
        2'd0: begin  // SGNJ
          case (mode)
            3'd0: new_sign = b[31];
            3'd1: new_sign = ~b[31];
            3'd2: new_sign = a[31] ^ b[31];
            default: new_sign = 1'b0;
          endcase
          e.res = {new_sign, a[30:0]};
        end

        2'd1: begin  // MINMAX
          nv = a_snan || b_snan;

          if (a_nan && b_nan) begin
            e.res = 32'h7fc0_0000;
          end else if (a_nan) begin
            e.res = b;
          end else if (b_nan) begin
            e.res = a;
          end else if (is_zero(a) && is_zero(b)) begin
            if (mode == 3'd0) begin
              // Minimum: -0 wins if either operand is -0.
              e.res = (a[31] || b[31]) ? 32'h8000_0000
                                       : 32'h0000_0000;
            end else begin
              // Maximum: +0 wins if either operand is +0.
              e.res = (a[31] && b[31]) ? 32'h8000_0000
                                       : 32'h0000_0000;
            end
          end else if (mode == 3'd0) begin
            e.res = fp_less(a, b) ? a : b;
          end else begin
            e.res = fp_less(a, b) ? b : a;
          end
        end

        2'd2: begin  // CMP
          if (mode == 3'd2) begin
            // FEQ-style quiet equality.
            if (a_nan || b_nan) begin
              e.res = 32'h0000_0000;
              nv    = a_snan || b_snan;
            end else begin
              e.res = fp_equal(a, b) ? 32'h0000_0001
                                     : 32'h0000_0000;
            end
          end else begin
            // FLE/FLT-style signalling comparisons.
            if (a_nan || b_nan) begin
              e.res = 32'h0000_0000;
              nv    = 1'b1;
            end else if (mode == 3'd0) begin
              e.res = (fp_equal(a, b) || fp_less(a, b))
                      ? 32'h0000_0001 : 32'h0000_0000;
            end else begin
              e.res = fp_less(a, b) ? 32'h0000_0001
                                    : 32'h0000_0000;
            end
          end
        end

        2'd3: begin  // CLASSIFY
          e.mask      = class_bits(a);
          e.check_res = 1'b0;  // result_o is unconstrained for CLASSIFY
        end

        default: begin
          e.check_res = 1'b0;
        end
      endcase

      e.flags = {nv, 4'b0000};
      predict = e;
    end
  endfunction

  task automatic record_failure(input string req, input string why);
    begin
      errors = errors + 1;
      $display("FAIL %s: %s", req, why);
    end
  endtask

  // -------------------------------------------------------------------------
  // PROVIDED PLUMBING -- issues operations, checks nothing.
  // -------------------------------------------------------------------------

  // ---- clock ----------------------------------------------------------------
  initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
  end

  // ---- reset (active low, synchronous) --------------------------------------
  initial rst_n = 1'b0;

  task automatic bfm_reset(input int cycles = 4);
    @(negedge clk);
    rst_n = 1'b0;
    repeat (cycles) @(posedge clk);
    @(negedge clk);
    rst_n = 1'b1;
  endtask

  // ---- issue ----------------------------------------------------------------
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

  // ---- result side ----------------------------------------------------------
  task automatic bfm_out_ready(input logic value);
    @(negedge clk);
    out_ready_i = value;
  endtask

  // ---- watchdog (S16) -------------------------------------------------------
  initial begin
    #200_000_000;
    $display("FAIL S16: watchdog expired without forward progress");
    $display("RESULT: FAIL");
    $finish;
  end

  // -------------------------------------------------------------------------
  // Testbench helpers
  // -------------------------------------------------------------------------

  task automatic do_op(input logic [31:0] a,
                       input logic [31:0] b,
                       input logic [1:0]  op,
                       input logic [2:0]  mode);
    begin
      bfm_issue(a, b, op, mode);
    end
  endtask

  task automatic wait_all_results;
    begin
      while (exp_q.size() != 0)
        @(negedge clk);
    end
  endtask

  task automatic run_random(input int unsigned count);
    int unsigned i;
    logic [31:0] ra;
    logic [31:0] rb;
    logic [1:0]  rop;
    logic [2:0]  rmode;
    begin
      for (i = 0; i < count; i = i + 1) begin
        ra = $urandom();
        rb = $urandom();

        // Regularly inject boundary values in addition to random bit patterns.
        case (i % 16)
          0:  ra = 32'h0000_0000;
          1:  ra = 32'h8000_0000;
          2:  ra = 32'h7fc0_0000;
          3:  ra = 32'h7f80_0001;
          4:  ra = 32'h7f80_0000;
          5:  ra = 32'hff80_0000;
          6:  ra = 32'h0000_0001;
          7:  ra = 32'h8000_0001;
          default: ra = ra;
        endcase

        case (i % 12)
          0:  rb = 32'h0000_0000;
          1:  rb = 32'h8000_0000;
          2:  rb = 32'hffc1_2345;
          3:  rb = 32'hff80_0001;
          4:  rb = 32'h3f80_0000;
          5:  rb = 32'hbf80_0000;
          default: rb = rb;
        endcase

        case (i % 4)
          0: begin
            rop = 2'd0;
            case (i % 3)
              0: rmode = 3'd0;
              1: rmode = 3'd1;
              default: rmode = 3'd2;
            endcase
          end
          1: begin
            rop   = 2'd1;
            rmode = i[0] ? 3'd1 : 3'd0;
          end
          2: begin
            rop = 2'd2;
            case (i % 3)
              0: rmode = 3'd0;
              1: rmode = 3'd1;
              default: rmode = 3'd2;
            endcase
          end
          default: begin
            rop   = 2'd3;
            rmode = ra[2:0];  // Every mode is legal for CLASSIFY.
          end
        endcase

        do_op(ra, rb, rop, rmode);
      end
    end
  endtask

  // -------------------------------------------------------------------------
  // Acceptance bookkeeping and result checking
  // -------------------------------------------------------------------------

  always @(posedge clk) begin
    if (!rst_n) begin
      // S15: operations still in flight are discarded by reset.
      flushed_total = flushed_total + exp_q.size();
      exp_q.delete();
    end else begin
      // S15: out_valid_o must be low on the first cycle after reset release.
      if (!prev_rst_n && (out_valid_o !== 1'b0)) begin
        record_failure("S15",
          $sformatf("out_valid_o was not low on first cycle after reset (value=%b)",
                    out_valid_o));
      end

      // H1: only a valid/ready rising edge accepts an operation.
      if (in_valid_i && in_ready_o) begin
        exp_q.push_back(predict(operand_a_i, operand_b_i, op_i, op_mode_i));
        accept_total = accept_total + 1;
      end

      // H2: compare only delivered results, in acceptance order.
      if (out_valid_o && out_ready_i) begin
        if (exp_q.size() == 0) begin
          record_failure("H2",
            $sformatf("unexpected or duplicate result: result=%h mask=%h status=%h",
                      result_o, class_mask_o, status_o));
        end else begin
          if (exp_q[0].check_res && (result_o !== exp_q[0].res)) begin
            case (exp_q[0].op)
              2'd0: record_failure("S1",
                $sformatf("SGNJ result mismatch id=%0d a=%h b=%h mode=%0d got=%h expected=%h",
                          exp_q[0].id, exp_q[0].a, exp_q[0].b, exp_q[0].mode,
                          result_o, exp_q[0].res));
              2'd1: record_failure("S3/S4/S5/A2",
                $sformatf("MINMAX result mismatch id=%0d a=%h b=%h mode=%0d got=%h expected=%h",
                          exp_q[0].id, exp_q[0].a, exp_q[0].b, exp_q[0].mode,
                          result_o, exp_q[0].res));
              2'd2: record_failure("S7/S8/S9/S10",
                $sformatf("CMP result mismatch id=%0d a=%h b=%h mode=%0d got=%h expected=%h",
                          exp_q[0].id, exp_q[0].a, exp_q[0].b, exp_q[0].mode,
                          result_o, exp_q[0].res));
              default: record_failure("H2",
                $sformatf("unexpected checked result id=%0d", exp_q[0].id));
            endcase
          end

          if (exp_q[0].op == 2'd3 &&
              (class_mask_o !== exp_q[0].mask)) begin
            record_failure("S12/A3",
              $sformatf("CLASSIFY mask mismatch id=%0d a=%h b=%h got=%h expected=%h",
                        exp_q[0].id, exp_q[0].a, exp_q[0].b,
                        class_mask_o, exp_q[0].mask));
          end

          if (status_o !== exp_q[0].flags) begin
            case (exp_q[0].op)
              2'd0: record_failure("S2/S14",
                $sformatf("SGNJ flags mismatch id=%0d got=%b expected=%b",
                          exp_q[0].id, status_o, exp_q[0].flags));
              2'd1: record_failure("S6/S14",
                $sformatf("MINMAX flags mismatch id=%0d a=%h b=%h got=%b expected=%b",
                          exp_q[0].id, exp_q[0].a, exp_q[0].b,
                          status_o, exp_q[0].flags));
              2'd2: record_failure("S8/S9/S11/S14",
                $sformatf("CMP flags mismatch id=%0d a=%h b=%h mode=%0d got=%b expected=%b",
                          exp_q[0].id, exp_q[0].a, exp_q[0].b, exp_q[0].mode,
                          status_o, exp_q[0].flags));
              default: record_failure("S13/S14",
                $sformatf("CLASSIFY flags mismatch id=%0d got=%b expected=%b",
                          exp_q[0].id, status_o, exp_q[0].flags));
            endcase
          end

          delivered_total = delivered_total + 1;
          exp_q.delete(0);
        end
      end
    end

    if (rst_n && !out_ready_i)
      stall_cycles = stall_cycles + 1;

    prev_rst_n = rst_n;
  end

  // -------------------------------------------------------------------------
  // Directed and randomized stimulus
  // -------------------------------------------------------------------------

  initial begin
    errors          = 0;
    accept_total    = 0;
    delivered_total = 0;
    flushed_total   = 0;
    stall_cycles    = 0;
    prev_rst_n      = 1'b0;

    operand_a_i = 32'b0;
    operand_b_i = 32'b0;
    op_i        = 2'b0;
    op_mode_i   = 3'b0;
    in_valid_i  = 1'b0;
    out_ready_i = 1'b1;

    bfm_reset(4);
    bfm_out_ready(1'b1);

    // -----------------------------------------------------------------------
    // S15: leave an operation undelivered, then reset the design.
    // -----------------------------------------------------------------------
    do_op(32'h7f80_0001, 32'h3f80_0000, 2'd1, 3'd0);
    bfm_idle();
    out_ready_i = 1'b0;
    bfm_reset(3);
    bfm_out_ready(1'b1);
    repeat (24) @(posedge clk);

    // -----------------------------------------------------------------------
    // S1/S2: SGNJ, including NaN payload preservation and all sign variants.
    // -----------------------------------------------------------------------
    do_op(32'h3fc0_0000, 32'h4000_0000, 2'd0, 3'd0);
    do_op(32'h3fc0_0000, 32'hc000_0000, 2'd0, 3'd0);
    do_op(32'hbfc0_0000, 32'h4000_0000, 2'd0, 3'd1);
    do_op(32'hbfc0_0000, 32'hc000_0000, 2'd0, 3'd1);
    do_op(32'h3fc0_0000, 32'hc000_0000, 2'd0, 3'd2);
    do_op(32'hbfc0_0000, 32'hc000_0000, 2'd0, 3'd2);
    do_op(32'h7f80_0001, 32'h8000_0000, 2'd0, 3'd0);
    do_op(32'hffc1_2345, 32'h0000_0000, 2'd0, 3'd1);
    do_op(32'h8000_0000, 32'h7fc0_0000, 2'd0, 3'd2);
    do_op(32'h7fc1_2345, 32'hff80_0001, 2'd0, 3'd0);

    // -----------------------------------------------------------------------
    // S3: ordinary MIN/MAX ordering, infinities, subnormals and signed zeros.
    // -----------------------------------------------------------------------
    do_op(32'h3f80_0000, 32'h4000_0000, 2'd1, 3'd0);
    do_op(32'h3f80_0000, 32'h4000_0000, 2'd1, 3'd1);
    do_op(32'hc000_0000, 32'hbf80_0000, 2'd1, 3'd0);
    do_op(32'hc000_0000, 32'hbf80_0000, 2'd1, 3'd1);
    do_op(32'hbf80_0000, 32'h3f80_0000, 2'd1, 3'd0);
    do_op(32'hbf80_0000, 32'h3f80_0000, 2'd1, 3'd1);

    do_op(32'h8000_0000, 32'h0000_0000, 2'd1, 3'd0);
    do_op(32'h0000_0000, 32'h8000_0000, 2'd1, 3'd0);
    do_op(32'h8000_0000, 32'h0000_0000, 2'd1, 3'd1);
    do_op(32'h0000_0000, 32'h8000_0000, 2'd1, 3'd1);
    do_op(32'h0000_0000, 32'h0000_0000, 2'd1, 3'd0);
    do_op(32'h8000_0000, 32'h8000_0000, 2'd1, 3'd1);

    do_op(32'hff80_0000, 32'h7f80_0000, 2'd1, 3'd0);
    do_op(32'hff80_0000, 32'h7f80_0000, 2'd1, 3'd1);
    do_op(32'h7f80_0000, 32'h7f80_0000, 2'd1, 3'd0);
    do_op(32'hff80_0000, 32'hff80_0000, 2'd1, 3'd1);
    do_op(32'h0000_0001, 32'h0000_0000, 2'd1, 3'd0);
    do_op(32'h8000_0001, 32'h8000_0000, 2'd1, 3'd1);
    do_op(32'h0080_0000, 32'h0000_0001, 2'd1, 3'd0);
    do_op(32'h8080_0000, 32'h8000_0001, 2'd1, 3'd1);

    // -----------------------------------------------------------------------
    // S4/S5/S6: one NaN, two NaNs, quiet/signalling NaNs and flag clearing.
    // -----------------------------------------------------------------------
    do_op(32'h7fc1_2345, 32'h3f80_0000, 2'd1, 3'd0);
    do_op(32'h3f80_0000, 32'h7fc1_2345, 2'd1, 3'd1);
    do_op(32'hffc0_0001, 32'hbf80_0000, 2'd1, 3'd1);
    do_op(32'hbf80_0000, 32'hffc0_0001, 2'd1, 3'd0);

    do_op(32'h7f80_0001, 32'h4000_0000, 2'd1, 3'd0);
    do_op(32'h4000_0000, 32'h7f80_0001, 2'd1, 3'd1);
    do_op(32'hff80_0001, 32'h0000_0000, 2'd1, 3'd1);
    do_op(32'h0000_0000, 32'hff80_0001, 2'd1, 3'd0);

    do_op(32'h7fc0_0000, 32'hffc1_2345, 2'd1, 3'd0);
    do_op(32'h7f80_0001, 32'h7fc0_0000, 2'd1, 3'd1);
    do_op(32'h7fc0_0000, 32'hff80_0001, 2'd1, 3'd0);
    do_op(32'h7f80_0001, 32'hff80_0001, 2'd1, 3'd1);

    // A non-NaN operation immediately after NV must report no accumulated NV.
    do_op(32'h3f80_0000, 32'h4000_0000, 2'd1, 3'd0);

    // -----------------------------------------------------------------------
    // S7-S11: comparisons, including zeros, infinities and every NaN case.
    // -----------------------------------------------------------------------
    do_op(32'h3f80_0000, 32'h4000_0000, 2'd2, 3'd0);
    do_op(32'h4000_0000, 32'h3f80_0000, 2'd2, 3'd0);
    do_op(32'h3f80_0000, 32'h3f80_0000, 2'd2, 3'd0);
    do_op(32'h3f80_0000, 32'h4000_0000, 2'd2, 3'd1);
    do_op(32'h3f80_0000, 32'h3f80_0000, 2'd2, 3'd1);
    do_op(32'h3f80_0000, 32'h3f80_0000, 2'd2, 3'd2);
    do_op(32'h3f80_0000, 32'h4000_0000, 2'd2, 3'd2);

    do_op(32'hc000_0000, 32'hbf80_0000, 2'd2, 3'd1);
    do_op(32'hbf80_0000, 32'hc000_0000, 2'd2, 3'd0);
    do_op(32'hff80_0000, 32'h7f80_0000, 2'd2, 3'd0);
    do_op(32'h7f80_0000, 32'hff80_0000, 2'd2, 3'd1);
    do_op(32'h7f80_0000, 32'h7f80_0000, 2'd2, 3'd1);
    do_op(32'hff80_0000, 32'hff80_0000, 2'd2, 3'd2);

    do_op(32'h8000_0000, 32'h0000_0000, 2'd2, 3'd2);
    do_op(32'h0000_0000, 32'h8000_0000, 2'd2, 3'd2);
    do_op(32'h8000_0000, 32'h0000_0000, 2'd2, 3'd1);
    do_op(32'h0000_0000, 32'h8000_0000, 2'd2, 3'd1);
    do_op(32'h8000_0000, 32'h0000_0000, 2'd2, 3'd0);
    do_op(32'h0000_0000, 32'h8000_0000, 2'd2, 3'd0);

    // Quiet NaNs: LE/LT raise NV, EQ does not.
    do_op(32'h7fc0_0000, 32'h3f80_0000, 2'd2, 3'd0);
    do_op(32'h3f80_0000, 32'h7fc0_0000, 2'd2, 3'd1);
    do_op(32'h7fc0_0000, 32'h3f80_0000, 2'd2, 3'd2);
    do_op(32'h3f80_0000, 32'hffc1_2345, 2'd2, 3'd2);

    // Signalling NaNs: every comparison variant raises NV.
    do_op(32'h7f80_0001, 32'h3f80_0000, 2'd2, 3'd0);
    do_op(32'h3f80_0000, 32'hff80_0001, 2'd2, 3'd1);
    do_op(32'h7f80_0001, 32'h3f80_0000, 2'd2, 3'd2);
    do_op(32'h3f80_0000, 32'hff80_0001, 2'd2, 3'd2);
    do_op(32'h7fc0_0000, 32'h7fc0_0000, 2'd2, 3'd0);
    do_op(32'h7fc0_0000, 32'h7fc0_0000, 2'd2, 3'd2);

    // Check that a preceding signalling comparison does not accumulate NV.
    do_op(32'h3f80_0000, 32'h3f80_0000, 2'd2, 3'd2);

    // -----------------------------------------------------------------------
    // S12/S13: every classification, operand_b ignored, no flags for sNaN.
    // -----------------------------------------------------------------------
    do_op(32'hff80_0000, 32'h0000_0000, 2'd3, 3'd0);
    do_op(32'hbf80_0000, 32'h7fc0_0000, 2'd3, 3'd1);
    do_op(32'h8000_0001, 32'h7f80_0001, 2'd3, 3'd2);
    do_op(32'h8000_0000, 32'h3f80_0000, 2'd3, 3'd3);
    do_op(32'h0000_0000, 32'hff80_0000, 2'd3, 3'd4);
    do_op(32'h0000_0001, 32'h8000_0000, 2'd3, 3'd5);
    do_op(32'h3f80_0000, 32'h7fc0_0000, 2'd3, 3'd6);
    do_op(32'h7f80_0000, 32'hff80_0001, 2'd3, 3'd7);
    do_op(32'h7f80_0001, 32'h0000_0000, 2'd3, 3'd0);
    do_op(32'hff80_0001, 32'h7fc0_0000, 2'd3, 3'd7);
    do_op(32'h7fc0_0000, 32'h7f80_0001, 2'd3, 3'd0);
    do_op(32'hffc1_2345, 32'h3f80_0000, 2'd3, 3'd7);

    bfm_idle();
    wait_all_results();

    // -----------------------------------------------------------------------
    // H2/H3: hold out_ready_i low for well over 20 cycles with an operation
    // accepted or in flight, then verify that its result is delivered once.
    // -----------------------------------------------------------------------
    do_op(32'h7f80_0001, 32'h4000_0000, 2'd1, 3'd1);
    bfm_idle();
    out_ready_i = 1'b0;
    repeat (40) @(posedge clk);
    bfm_out_ready(1'b1);
    wait_all_results();

    // Back-to-back legal operations with randomized operands and modes.
    run_random(160);
    bfm_idle();
    wait_all_results();

    // Allow any erroneous duplicate or stale result to become visible.
    repeat (12) @(negedge clk);

    if (stall_cycles < 20) begin
      record_failure("H3",
        $sformatf("testbench generated only %0d stall cycles", stall_cycles));
    end

    if (accept_total != (delivered_total + flushed_total)) begin
      record_failure("H2",
        $sformatf("accepted=%0d delivered=%0d reset-flushed=%0d",
                  accept_total, delivered_total, flushed_total));
    end

    if (errors == 0)
      $display("RESULT: PASS");
    else
      $display("RESULT: FAIL");

    $finish;
  end

endmodule
