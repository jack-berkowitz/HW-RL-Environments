`timescale 1ns/1ps

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
  // PROVIDED PLUMBING
  // ---------------------------------------------------------------------------
  logic clk;
  initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
  end

  assign clk_i = clk;

  logic rst_n;
  initial rst_n = 1'b0;
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

  // Independent, unconditional watchdog required by S16.
  initial begin
    #5_000_000;
    $display("FAIL S16: watchdog expired without testbench completion");
    $display("RESULT: FAIL");
    $finish;
  end

  // ---------------------------------------------------------------------------
  // IEEE-754 binary32 reference functions
  // ---------------------------------------------------------------------------
  function automatic logic is_nan(input logic [31:0] x);
    is_nan = (x[30:23] == 8'hff) && (x[22:0] != 23'b0);
  endfunction

  function automatic logic is_snan(input logic [31:0] x);
    is_snan = (x[30:23] == 8'hff) &&
              (x[22:0] != 23'b0) && (x[22] == 1'b0);
  endfunction

  function automatic logic fp_equal(input logic [31:0] a,
                                    input logic [31:0] b);
    fp_equal = (a == b) ||
               ((a[30:0] == 31'b0) && (b[30:0] == 31'b0));
  endfunction

  // Numeric less-than for non-NaN operands. Both zero encodings compare equal.
  function automatic logic fp_less(input logic [31:0] a,
                                   input logic [31:0] b);
    begin
      if ((a[30:0] == 31'b0) && (b[30:0] == 31'b0))
        fp_less = 1'b0;
      else if (a[31] != b[31])
        fp_less = a[31];
      else if (!a[31])
        fp_less = (a[30:0] < b[30:0]);
      else
        fp_less = (a[30:0] > b[30:0]);
    end
  endfunction

  function automatic logic [9:0] classify_bits(input logic [31:0] a);
    begin
      if (is_nan(a)) begin
        if (is_snan(a))
          classify_bits = 10'h100;       // bit 8: signalling NaN
        else
          classify_bits = 10'h200;       // bit 9: quiet NaN
      end else if (a[30:23] == 8'hff) begin
        if (a[31])
          classify_bits = 10'h001;       // bit 0: -infinity
        else
          classify_bits = 10'h080;       // bit 7: +infinity
      end else if (a[30:23] == 8'h00) begin
        if (a[22:0] == 23'b0) begin
          if (a[31])
            classify_bits = 10'h008;     // bit 3: -zero
          else
            classify_bits = 10'h010;     // bit 4: +zero
        end else begin
          if (a[31])
            classify_bits = 10'h004;     // bit 2: -subnormal
          else
            classify_bits = 10'h020;     // bit 5: +subnormal
        end
      end else begin
        if (a[31])
          classify_bits = 10'h002;       // bit 1: -normal
        else
          classify_bits = 10'h040;       // bit 6: +normal
      end
    end
  endfunction

  // ---------------------------------------------------------------------------
  // Expected-result queue. Entries are queued in issue order, never matched by
  // result value. CLASSIFY results and non-CLASSIFY class masks are ignored.
  // ---------------------------------------------------------------------------
  typedef struct {
    logic [31:0] exp_result;
    logic [9:0]  exp_mask;
    logic [4:0]  exp_status;
    logic [31:0] a;
    logic [31:0] b;
    logic [1:0]  op;
    logic [2:0]  mode;
    int unsigned seq_id;
  } exp_t;

  exp_t exp_q[$];
  int unsigned next_id;
  integer errors;
  integer stall_cycles;
  integer valid_stall_cycles;

  task automatic report_fail(input string req, input string detail);
    begin
      if (errors < 60)
        $display("FAIL %s: %s", req, detail);
      errors = errors + 1;
    end
  endtask

  task automatic build_expected(input logic [31:0] a,
                                input logic [31:0] b,
                                input logic [1:0]  op,
                                input logic [2:0]  mode,
                                output exp_t e);
    logic nv;
    logic result_sign;
    logic nan_any;
    logic eq_value;
    logic lt_value;
    logic truth_value;
    begin
      e.a          = a;
      e.b          = b;
      e.op         = op;
      e.mode       = mode;
      e.seq_id     = next_id;
      e.exp_result = 32'b0;
      e.exp_mask   = 10'b0;
      e.exp_status = 5'b0;
      nv            = 1'b0;
      result_sign   = 1'b0;
      nan_any       = 1'b0;
      eq_value      = 1'b0;
      lt_value      = 1'b0;
      truth_value   = 1'b0;

      case (op)
        2'd0: begin                         // SGNJ: S1, S2
          case (mode)
            3'd0: result_sign = b[31];
            3'd1: result_sign = ~b[31];
            default: result_sign = a[31] ^ b[31];
          endcase
          e.exp_result = {result_sign, a[30:0]};
          e.exp_status = 5'b0;
        end

        2'd1: begin                         // MINMAX: S3-S6
          nv = is_snan(a) || is_snan(b);
          e.exp_status = {nv, 4'b0000};

          if (is_nan(a) && is_nan(b)) begin
            e.exp_result = 32'h7fc0_0000;
          end else if (is_nan(a)) begin
            e.exp_result = b;
          end else if (is_nan(b)) begin
            e.exp_result = a;
          end else if ((a[30:0] == 31'b0) &&
                       (b[30:0] == 31'b0)) begin
            if (mode == 3'd0)
              e.exp_result = {(a[31] | b[31]), 31'b0};
            else
              e.exp_result = {(a[31] & b[31]), 31'b0};
          end else if (mode == 3'd0) begin
            if (fp_less(b, a))
              e.exp_result = b;
            else
              e.exp_result = a;
          end else begin
            if (fp_less(a, b))
              e.exp_result = b;
            else
              e.exp_result = a;
          end
        end

        2'd2: begin                         // CMP: S7-S11
          nan_any = is_nan(a) || is_nan(b);
          if (nan_any) begin
            truth_value = 1'b0;
            if (mode == 3'd2)
              nv = is_snan(a) || is_snan(b);
            else
              nv = 1'b1;
          end else begin
            eq_value = fp_equal(a, b);
            lt_value = fp_less(a, b);
            case (mode)
              3'd0: truth_value = lt_value || eq_value;
              3'd1: truth_value = lt_value;
              default: truth_value = eq_value;
            endcase
            nv = 1'b0;
          end
          e.exp_result = {31'b0, truth_value};
          e.exp_status = {nv, 4'b0000};
        end

        default: begin                      // CLASSIFY: S12, S13
          e.exp_mask   = classify_bits(a);
          e.exp_status = 5'b0;
        end
      endcase
    end
  endtask

  task automatic send_checked(input logic [31:0] a,
                              input logic [31:0] b,
                              input logic [1:0]  op,
                              input logic [2:0]  mode);
    exp_t e;
    begin
      build_expected(a, b, op, mode, e);
      exp_q.push_back(e);
      next_id = next_id + 1;
      bfm_issue(a, b, op, mode);
    end
  endtask

  // Check only on actual result-delivery edges.
  always @(posedge clk) begin : result_monitor
    automatic exp_t e;
    if (!rst_n) begin
      exp_q.delete();
    end else begin
      if (out_ready_i === 1'b0)
        stall_cycles = stall_cycles + 1;
      if ((out_valid_o === 1'b1) && (out_ready_i === 1'b0))
        valid_stall_cycles = valid_stall_cycles + 1;

      if ((out_valid_o === 1'b1) && (out_ready_i === 1'b1)) begin
        if (exp_q.size() == 0) begin
          report_fail("H2",
            $sformatf("unexpected/duplicate result: result=%08h mask=%03h status=%02h",
                      result_o, class_mask_o, status_o));
        end else begin
          e = exp_q.pop_front();

          if (e.op != 2'd3 && result_o !== e.exp_result) begin
            case (e.op)
              2'd0:
                report_fail("S1",
                  $sformatf("seq=%0d SGNJ a=%08h b=%08h mode=%0d got=%08h expected=%08h",
                            e.seq_id, e.a, e.b, e.mode,
                            result_o, e.exp_result));
              2'd1: begin
                if (is_nan(e.a) && is_nan(e.b))
                  report_fail("S5",
                    $sformatf("seq=%0d two-NaN MINMAX got=%08h expected=%08h",
                              e.seq_id, result_o, e.exp_result));
                else if (is_nan(e.a) || is_nan(e.b))
                  report_fail("S4",
                    $sformatf("seq=%0d one-NaN MINMAX a=%08h b=%08h mode=%0d got=%08h expected=%08h",
                              e.seq_id, e.a, e.b, e.mode,
                              result_o, e.exp_result));
                else
                  report_fail("S3",
                    $sformatf("seq=%0d MINMAX a=%08h b=%08h mode=%0d got=%08h expected=%08h",
                              e.seq_id, e.a, e.b, e.mode,
                              result_o, e.exp_result));
              end
              default: begin
                if (is_nan(e.a) || is_nan(e.b)) begin
                  if (e.mode == 3'd2)
                    report_fail("S9",
                      $sformatf("seq=%0d FEQ with NaN got=%08h expected=%08h",
                                e.seq_id, result_o, e.exp_result));
                  else
                    report_fail("S8",
                      $sformatf("seq=%0d signalling CMP with NaN got=%08h expected=%08h",
                                e.seq_id, result_o, e.exp_result));
                end else if ((e.a[30:0] == 31'b0) &&
                             (e.b[30:0] == 31'b0)) begin
                  report_fail("S10",
                    $sformatf("seq=%0d zero CMP a=%08h b=%08h mode=%0d got=%08h expected=%08h",
                              e.seq_id, e.a, e.b, e.mode,
                              result_o, e.exp_result));
                end else begin
                  report_fail("S7",
                    $sformatf("seq=%0d CMP a=%08h b=%08h mode=%0d got=%08h expected=%08h",
                              e.seq_id, e.a, e.b, e.mode,
                              result_o, e.exp_result));
                end
              end
            endcase
          end

          if (e.op == 2'd3 && class_mask_o !== e.exp_mask)
            report_fail("S12",
              $sformatf("seq=%0d CLASSIFY a=%08h b=%08h got=%03h expected=%03h",
                        e.seq_id, e.a, e.b, class_mask_o, e.exp_mask));

          if (status_o !== e.exp_status) begin
            case (e.op)
              2'd0:
                report_fail("S2",
                  $sformatf("seq=%0d SGNJ flags got=%02h expected=%02h",
                            e.seq_id, status_o, e.exp_status));
              2'd1:
                report_fail("S6",
                  $sformatf("seq=%0d MINMAX a=%08h b=%08h flags got=%02h expected=%02h",
                            e.seq_id, e.a, e.b, status_o, e.exp_status));
              2'd2: begin
                if (e.mode == 3'd2)
                  report_fail("S9",
                    $sformatf("seq=%0d FEQ flags got=%02h expected=%02h",
                              e.seq_id, status_o, e.exp_status));
                else
                  report_fail("S8",
                    $sformatf("seq=%0d FLT/FLE flags got=%02h expected=%02h",
                              e.seq_id, status_o, e.exp_status));
              end
              default:
                report_fail("S13",
                  $sformatf("seq=%0d CLASSIFY flags got=%02h expected=%02h",
                            e.seq_id, status_o, e.exp_status));
            endcase
          end

          if (status_o[3:0] !== 4'b0000)
            report_fail("S14",
              $sformatf("seq=%0d non-NV status bits nonzero: status=%02h",
                        e.seq_id, status_o));
        end
      end
    end
  end

  // ---------------------------------------------------------------------------
  // Result-side backpressure. All ready changes occur at negedge. The initial
  // forced stretch is finite, so even a design that refuses input while ready is
  // low cannot deadlock the testbench.
  // ---------------------------------------------------------------------------
  logic bp_random;
  logic ready_default;
  logic stall_hold;
  logic [3:0] bp_tick;
  integer stretch_count;

  always @(negedge clk) begin
    if (!rst_n) begin
      stretch_count = 0;
      out_ready_i   = ready_default;
    end else if (stall_hold && stretch_count < 40) begin
      out_ready_i   = 1'b0;
      stretch_count = stretch_count + 1;
    end else if (bp_random) begin
      bp_tick = bp_tick + 1'b1;
      case (bp_tick[2:0])
        3'd0, 3'd3, 3'd6: out_ready_i = 1'b0;
        default:          out_ready_i = 1'b1;
      endcase
    end else begin
      out_ready_i = ready_default;
    end
  end

  task automatic wait_for_drain(input int limit);
    integer waited;
    begin
      waited = 0;
      while ((exp_q.size() != 0) && (waited < limit)) begin
        @(negedge clk);
        waited = waited + 1;
      end
      if (exp_q.size() != 0)
        report_fail("H2",
          $sformatf("drain timeout with %0d undelivered operations",
                    exp_q.size()));
    end
  endtask

  task automatic reset_and_check(input int cycles);
    begin
      bfm_reset(cycles);
      @(posedge clk);
      @(negedge clk);
      if (out_valid_o !== 1'b0)
        report_fail("S15", "out_valid_o high on first cycle after reset release");
    end
  endtask

  // ---------------------------------------------------------------------------
  // Directed and randomized stimulus
  // ---------------------------------------------------------------------------
  localparam int NUM_CORNERS = 24;
  logic [31:0] corner [0:NUM_CORNERS-1];

  initial begin : test_sequence
    integer i;
    integer j;
    logic [31:0] ra;
    logic [31:0] rb;
    logic [1:0]  rop;
    logic [2:0]  rmode;

    operand_a_i = 32'b0;
    operand_b_i = 32'b0;
    op_i        = 2'b0;
    op_mode_i   = 3'b0;
    in_valid_i  = 1'b0;
    out_ready_i = 1'b0;

    next_id            = 0;
    errors             = 0;
    stall_cycles       = 0;
    valid_stall_cycles = 0;
    bp_random          = 1'b0;
    ready_default      = 1'b1;
    stall_hold         = 1'b0;
    bp_tick            = 4'b0;
    stretch_count      = 0;

    corner[ 0] = 32'h0000_0000;  // +zero
    corner[ 1] = 32'h8000_0000;  // -zero
    corner[ 2] = 32'h0000_0001;  // +minimum subnormal
    corner[ 3] = 32'h8000_0001;  // -minimum subnormal
    corner[ 4] = 32'h007f_ffff;  // +maximum subnormal
    corner[ 5] = 32'h807f_ffff;  // -maximum subnormal
    corner[ 6] = 32'h0080_0000;  // +minimum normal
    corner[ 7] = 32'h8080_0000;  // -minimum normal
    corner[ 8] = 32'h3f80_0000;  // +1.0
    corner[ 9] = 32'hbf80_0000;  // -1.0
    corner[10] = 32'h4000_0000;  // +2.0
    corner[11] = 32'hc000_0000;  // -2.0
    corner[12] = 32'h7f7f_ffff;  // +maximum finite
    corner[13] = 32'hff7f_ffff;  // -maximum finite
    corner[14] = 32'h7f80_0000;  // +infinity
    corner[15] = 32'hff80_0000;  // -infinity
    corner[16] = 32'h7fc0_0000;  // canonical quiet NaN
    corner[17] = 32'hffc1_2345;  // negative quiet NaN with payload
    corner[18] = 32'h7fa0_0000;  // signalling NaN
    corner[19] = 32'hffa0_0001;  // negative signalling NaN
    corner[20] = 32'h3f00_0000;  // +0.5
    corner[21] = 32'hbf00_0000;  // -0.5
    corner[22] = 32'h7fc0_0001;  // quiet NaN with another payload
    corner[23] = 32'h7f80_0001;  // minimal-payload signalling NaN

    reset_and_check(4);

    // Force at least 40 cycles of result-side backpressure while issuing a mix
    // that exercises payloads, NaN handling, flags, and signed zeros.
    stall_hold = 1'b1;
    send_checked(32'h7fa1_2345, 32'h8000_0000, 2'd0, 3'd0);
    send_checked(32'h7fc0_0000, 32'h3f80_0000, 2'd1, 3'd0);
    send_checked(32'h7fa0_0000, 32'h3f80_0000, 2'd1, 3'd1);
    send_checked(32'h7fc0_0000, 32'h0000_0000, 2'd2, 3'd0);
    send_checked(32'h7fc0_0000, 32'h0000_0000, 2'd2, 3'd2);
    send_checked(32'h7f80_0001, 32'hdead_beef, 2'd3, 3'd7);
    send_checked(32'h8000_0000, 32'h0000_0000, 2'd1, 3'd0);
    send_checked(32'h8000_0000, 32'h0000_0000, 2'd1, 3'd1);
    bfm_idle();

    while (stall_cycles < 30)
      @(negedge clk);
    stall_hold = 1'b0;
    bp_random  = 1'b1;
    wait_for_drain(20000);

    // Every pairing of the corner set for MINMAX and all three comparisons.
    // This includes both operand orders for zeros and NaNs.
    for (i = 0; i < NUM_CORNERS; i = i + 1) begin
      for (j = 0; j < NUM_CORNERS; j = j + 1) begin
        send_checked(corner[i], corner[j], 2'd1, 3'd0);
        send_checked(corner[i], corner[j], 2'd1, 3'd1);
        send_checked(corner[i], corner[j], 2'd2, 3'd0);
        send_checked(corner[i], corner[j], 2'd2, 3'd1);
        send_checked(corner[i], corner[j], 2'd2, 3'd2);
      end

      // All SGNJ variants, including NaN payload preservation.
      send_checked(corner[i], corner[(i*5+1) % NUM_CORNERS], 2'd0, 3'd0);
      send_checked(corner[i], corner[(i*5+1) % NUM_CORNERS], 2'd0, 3'd1);
      send_checked(corner[i], corner[(i*5+1) % NUM_CORNERS], 2'd0, 3'd2);

      // Every CLASSIFY mode is legal and ignored; operand B is varied too.
      for (j = 0; j < 8; j = j + 1) begin
        rmode = j;
        send_checked(corner[i], corner[(i+j) % NUM_CORNERS], 2'd3, rmode);
      end
    end

    // Additional arbitrary bit patterns, with only specified operation modes.
    for (i = 0; i < 400; i = i + 1) begin
      ra = $urandom();
      rb = $urandom();
      if ((i % 5) == 0)
        ra = corner[i % NUM_CORNERS];
      if ((i % 7) == 0)
        rb = corner[(i*3) % NUM_CORNERS];

      case (i % 4)
        0: begin
          rop   = 2'd0;
          rmode = i % 3;
        end
        1: begin
          rop   = 2'd1;
          rmode = i % 2;
        end
        2: begin
          rop   = 2'd2;
          rmode = i % 3;
        end
        default: begin
          rop   = 2'd3;
          rmode = i % 8;
        end
      endcase
      send_checked(ra, rb, rop, rmode);
    end

    bfm_idle();
    bp_random     = 1'b0;
    ready_default = 1'b1;
    wait_for_drain(20000);
    repeat (10) @(negedge clk);

    // S15: accept an operation, then synchronously reset before any later
    // result is allowed to survive. Any pre-reset expected entry is discarded.
    send_checked(32'h7fa0_0000, 32'h3f80_0000, 2'd1, 3'd0);
    @(negedge clk);
    in_valid_i = 1'b0;
    rst_n      = 1'b0;
    repeat (3) @(posedge clk);
    @(negedge clk);
    rst_n = 1'b1;

    @(posedge clk);
    @(negedge clk);
    if (out_valid_o !== 1'b0)
      report_fail("S15", "out_valid_o high on first cycle after flush reset");

    // No pre-reset operation may subsequently emerge.
    for (i = 0; i < 20; i = i + 1) begin
      @(negedge clk);
      if (out_valid_o !== 1'b0)
        report_fail("S15", "result or non-idle out_valid_o observed after reset");
    end

    if (exp_q.size() != 0)
      report_fail("H2", "scoreboard not empty at end of test");

    if (stall_cycles < 20)
      report_fail("H3",
        $sformatf("insufficient backpressure: only %0d ready-low cycles",
                  stall_cycles));

    if (errors == 0)
      $display("RESULT: PASS");
    else
      $display("RESULT: FAIL");
    $finish;
  end

endmodule
