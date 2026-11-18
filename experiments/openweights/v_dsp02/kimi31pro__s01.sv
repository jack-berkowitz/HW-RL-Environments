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
    $display("FAIL S16: watchdog expired without testbench termination");
    $display("RESULT: FAIL");
    $finish;
  end

  assign clk_i  = clk;
  assign rst_ni = rst_n;

  // ---------------------------------------------------------------------------
  // Reference model
  // ---------------------------------------------------------------------------
  function automatic logic ref_is_nan(input logic [31:0] a);
    ref_is_nan = (&a[30:23]) && (a[22:0] != 23'b0);
  endfunction

  function automatic logic ref_is_snan(input logic [31:0] a);
    ref_is_snan = (&a[30:23]) && (a[22:0] != 23'b0) && !a[22];
  endfunction

  function automatic logic ref_is_zero(input logic [31:0] a);
    ref_is_zero = (a[30:0] == 31'b0);
  endfunction

  function automatic logic [4:0] ref_status(
      input logic [31:0] a,
      input logic [31:0] b,
      input logic [1:0]  op,
      input logic [2:0]  mode);
    begin
      ref_status = 5'b0;
      case (op)
        2'd1: begin
          if (ref_is_snan(a) || ref_is_snan(b))
            ref_status[4] = 1'b1;
        end
        2'd2: begin
          if ((mode == 3'd0) || (mode == 3'd1)) begin
            if (ref_is_nan(a) || ref_is_nan(b))
              ref_status[4] = 1'b1;
          end else if (mode == 3'd2) begin
            if (ref_is_snan(a) || ref_is_snan(b))
              ref_status[4] = 1'b1;
          end
        end
        default: ref_status = 5'b0;
      endcase
    end
  endfunction

  function automatic logic [9:0] ref_class(input logic [31:0] a);
    begin
      ref_class = 10'b0;
      if (&a[30:23]) begin
        if (a[22:0] == 23'b0) begin
          if (a[31]) ref_class[0] = 1'b1;
          else       ref_class[7] = 1'b1;
        end else if (a[22]) begin
          ref_class[9] = 1'b1;
        end else begin
          ref_class[8] = 1'b1;
        end
      end else if (a[30:23] == 8'b0) begin
        if (a[22:0] == 23'b0) begin
          if (a[31]) ref_class[3] = 1'b1;
          else       ref_class[4] = 1'b1;
        end else begin
          if (a[31]) ref_class[2] = 1'b1;
          else       ref_class[5] = 1'b1;
        end
      end else begin
        if (a[31]) ref_class[1] = 1'b1;
        else       ref_class[6] = 1'b1;
      end
    end
  endfunction

  function automatic logic [31:0] ref_result(
      input logic [31:0] a,
      input logic [31:0] b,
      input logic [1:0]  op,
      input logic [2:0]  mode);
    logic a_nan;
    logic b_nan;
    logic a_less;
    logic numeric_equal;
    logic pick_a;
    begin
      a_nan        = ref_is_nan(a);
      b_nan        = ref_is_nan(b);
      a_less       = 1'b0;
      numeric_equal = 1'b0;
      pick_a       = 1'b0;
      ref_result   = 32'b0;

      case (op)
        2'd0: begin
          case (mode)
            3'd0: ref_result = {b[31], a[30:0]};
            3'd1: ref_result = {~b[31], a[30:0]};
            3'd2: ref_result = {a[31] ^ b[31], a[30:0]};
            default: ref_result = 32'b0;
          endcase
        end

        2'd1: begin
          if (a_nan && b_nan) begin
            ref_result = 32'h7FC0_0000;
          end else if (a_nan) begin
            ref_result = b;
          end else if (b_nan) begin
            ref_result = a;
          end else if (ref_is_zero(a) && ref_is_zero(b)) begin
            if (mode == 3'd0)
              ref_result = a[31] ? a : b;
            else
              ref_result = a[31] ? b : a;
          end else begin
            if (a[31] != b[31]) begin
              a_less = a[31];
            end else if (!a[31]) begin
              a_less = (a[30:0] < b[30:0]);
            end else begin
              a_less = (a[30:0] > b[30:0]);
            end

            if (mode == 3'd0)
              pick_a = a_less;
            else
              pick_a = !a_less;

            ref_result = pick_a ? a : b;
          end
        end

        2'd2: begin
          if (a_nan || b_nan) begin
            ref_result = 32'b0;
          end else begin
            numeric_equal = (a == b) ||
                            (ref_is_zero(a) && ref_is_zero(b));

            if (ref_is_zero(a) && ref_is_zero(b)) begin
              a_less = 1'b0;
            end else if (a[31] != b[31]) begin
              a_less = a[31];
            end else if (!a[31]) begin
              a_less = (a[30:0] < b[30:0]);
            end else begin
              a_less = (a[30:0] > b[30:0]);
            end

            case (mode)
              3'd0: ref_result = {31'b0, (a_less || numeric_equal)};
              3'd1: ref_result = {31'b0, a_less};
              3'd2: ref_result = {31'b0, numeric_equal};
              default: ref_result = 32'b0;
            endcase
          end
        end

        default: ref_result = 32'b0;
      endcase
    end
  endfunction

  // ---------------------------------------------------------------------------
  // Ordered scoreboard
  // ---------------------------------------------------------------------------
  typedef struct packed {
    logic [31:0] result;
    logic [9:0]  class_mask;
    logic [4:0]  status;
    logic [1:0]  op;
    logic [31:0] seq_no;
  } rec_t;

  rec_t exp_q[$];
  logic prev_rst_n = 1'b0;
  integer accepted_count = 0;
  integer stall_cycles = 0;

  task automatic fail(input string req_id, input string msg);
    begin
      $display("FAIL %s: %s", req_id, msg);
      $display("RESULT: FAIL");
      $finish;
    end
  endtask

  always @(posedge clk) begin : scoreboard
    automatic rec_t e;
    automatic rec_t n;

    if (!rst_n) begin
      exp_q.delete();
      prev_rst_n = 1'b0;
    end else begin
      if (!prev_rst_n && out_valid_o) begin
        fail("S15", "out_valid_o was high on the first cycle after reset release");
      end

      if (in_valid_i && in_ready_o) begin
        n.result     = ref_result(operand_a_i, operand_b_i, op_i, op_mode_i);
        n.class_mask = ref_class(operand_a_i);
        n.status     = ref_status(operand_a_i, operand_b_i, op_i, op_mode_i);
        n.op         = op_i;
        n.seq_no     = accepted_count;
        accepted_count = accepted_count + 1;
        exp_q.push_back(n);
      end

      if (out_valid_o && out_ready_i) begin
        if (exp_q.size() == 0) begin
          fail("H2", "a result was delivered with no accepted operation outstanding");
        end else begin
          e = exp_q.pop_front();

          if (status_o !== e.status) begin
            case (e.op)
              2'd0: fail("S2", $sformatf(
                         "SGNJ status mismatch seq=%0d got=%b expected=%b",
                         e.seq_no, status_o, e.status));
              2'd1: fail("S6", $sformatf(
                         "MINMAX status mismatch seq=%0d got=%b expected=%b",
                         e.seq_no, status_o, e.status));
              2'd2: fail("S8/S9/S11", $sformatf(
                         "CMP status mismatch seq=%0d got=%b expected=%b",
                         e.seq_no, status_o, e.status));
              default: fail("S13", $sformatf(
                         "CLASSIFY status mismatch seq=%0d got=%b expected=%b",
                         e.seq_no, status_o, e.status));
            endcase
          end

          if (e.op == 2'd3) begin
            if (class_mask_o !== e.class_mask) begin
              fail("S12", $sformatf(
                   "CLASSIFY mask mismatch seq=%0d got=%b expected=%b",
                   e.seq_no, class_mask_o, e.class_mask));
            end
          end else begin
            if (result_o !== e.result) begin
              case (e.op)
                2'd0: fail("S1", $sformatf(
                           "SGNJ result mismatch seq=%0d got=%08x expected=%08x",
                           e.seq_no, result_o, e.result));
                2'd1: fail("S3/S4/S5", $sformatf(
                           "MINMAX result mismatch seq=%0d got=%08x expected=%08x",
                           e.seq_no, result_o, e.result));
                default: fail("S7/S8/S9/S10", $sformatf(
                           "CMP result mismatch seq=%0d got=%08x expected=%08x",
                           e.seq_no, result_o, e.result));
              endcase
            end
          end
        end
      end

      prev_rst_n = 1'b1;
    end
  end

  always @(posedge clk) begin
    if (rst_n && out_valid_o && !out_ready_i)
      stall_cycles = stall_cycles + 1;
  end

  // ---------------------------------------------------------------------------
  // Result-ready generation, including sustained and pseudorandom backpressure
  // ---------------------------------------------------------------------------
  integer sink_mode = 1; // 0: ready, 1: stalled, 2: pseudorandom
  logic [15:0] ready_lfsr = 16'h1ACE;

  initial begin
    out_ready_i = 1'b0;
    forever begin
      @(negedge clk);
      if (!rst_n) begin
        out_ready_i = 1'b0;
      end else begin
        case (sink_mode)
          0: out_ready_i = 1'b1;
          1: out_ready_i = 1'b0;
          default: begin
            ready_lfsr = {ready_lfsr[14:0],
                          ready_lfsr[15] ^ ready_lfsr[13] ^
                          ready_lfsr[12] ^ ready_lfsr[10]};
            out_ready_i = ready_lfsr[0];
          end
        endcase
      end
    end
  end

  task automatic send(input logic [31:0] a,
                      input logic [31:0] b,
                      input logic [1:0]  op,
                      input logic [2:0]  mode);
    bfm_issue(a, b, op, mode);
  endtask

  task automatic wait_empty(input integer max_cycles);
    integer n;
    begin
      n = 0;
      while ((exp_q.size() != 0) && (n < max_cycles)) begin
        @(negedge clk);
        n = n + 1;
      end
      if (exp_q.size() != 0)
        fail("H2", $sformatf("timed out with %0d undelivered results",
                             exp_q.size()));
    end
  endtask

  task automatic wait_out_valid(input integer max_cycles);
    integer n;
    begin
      n = 0;
      while (!out_valid_o && (n < max_cycles)) begin
        @(negedge clk);
        n = n + 1;
      end
      if (!out_valid_o)
        fail("H2", "timed out waiting for a result under backpressure");
    end
  endtask

  // ---------------------------------------------------------------------------
  // Stimulus
  // ---------------------------------------------------------------------------
  initial begin : stimulus
    integer i;
    logic [31:0] ra;
    logic [31:0] rb;
    logic [1:0]  rop;
    logic [2:0]  rmode;

    operand_a_i = 32'b0;
    operand_b_i = 32'b0;
    op_i        = 2'b0;
    op_mode_i   = 3'b0;
    in_valid_i  = 1'b0;

    bfm_reset(5);
    sink_mode = 0;

    // S1/S2: payload preservation, all sign variants, and no NaN exceptions.
    send(32'h3F80_0000, 32'h0000_0000, 2'd0, 3'd0);
    send(32'h3F80_0000, 32'h8000_0000, 2'd0, 3'd0);
    send(32'hBF80_0000, 32'h0000_0000, 2'd0, 3'd1);
    send(32'hBF80_0000, 32'h8000_0000, 2'd0, 3'd1);
    send(32'h3F80_0000, 32'h8000_0000, 2'd0, 3'd2);
    send(32'hBF80_0000, 32'h8000_0000, 2'd0, 3'd2);
    send(32'h7FC1_2345, 32'h8000_0000, 2'd0, 3'd0);
    send(32'h7FA1_2345, 32'h0000_0000, 2'd0, 3'd1);
    send(32'hFFA0_0001, 32'h8000_0000, 2'd0, 3'd2);

    // S3: ordinary ordering, signed zeros, infinities and subnormals.
    send(32'h3F80_0000, 32'h4000_0000, 2'd1, 3'd0);
    send(32'h3F80_0000, 32'h4000_0000, 2'd1, 3'd1);
    send(32'hBF80_0000, 32'hC000_0000, 2'd1, 3'd0);
    send(32'hBF80_0000, 32'hC000_0000, 2'd1, 3'd1);
    send(32'hBF80_0000, 32'h3F80_0000, 2'd1, 3'd0);
    send(32'hBF80_0000, 32'h3F80_0000, 2'd1, 3'd1);
    send(32'h8000_0000, 32'h0000_0000, 2'd1, 3'd0);
    send(32'h8000_0000, 32'h0000_0000, 2'd1, 3'd1);
    send(32'h0000_0000, 32'h8000_0000, 2'd1, 3'd0);
    send(32'h0000_0000, 32'h8000_0000, 2'd1, 3'd1);
    send(32'hFF80_0000, 32'h7F80_0000, 2'd1, 3'd0);
    send(32'hFF80_0000, 32'h7F80_0000, 2'd1, 3'd1);
    send(32'h0000_0001, 32'h0000_0002, 2'd1, 3'd0);
    send(32'h8000_0001, 32'h8000_0002, 2'd1, 3'd1);

    // S4/S5/S6: quiet/signalling NaNs in either position and both NaNs.
    send(32'h7FC0_0000, 32'h3F80_0000, 2'd1, 3'd0);
    send(32'h3F80_0000, 32'h7FC0_0000, 2'd1, 3'd1);
    send(32'h7FA0_0000, 32'h4000_0000, 2'd1, 3'd0);
    send(32'h4000_0000, 32'hFFA0_0001, 2'd1, 3'd1);
    send(32'h7FC1_2345, 32'hFFC0_0001, 2'd1, 3'd0);
    send(32'h7FA0_0001, 32'h7FC0_0000, 2'd1, 3'd1);

    // S7-S11: all comparisons, zeros, infinities and both NaN kinds.
    send(32'h3F80_0000, 32'h4000_0000, 2'd2, 3'd0);
    send(32'h4000_0000, 32'h3F80_0000, 2'd2, 3'd0);
    send(32'h3F80_0000, 32'h4000_0000, 2'd2, 3'd1);
    send(32'h4000_0000, 32'h3F80_0000, 2'd2, 3'd1);
    send(32'hC000_0000, 32'hBF80_0000, 2'd2, 3'd0);
    send(32'hBF80_0000, 32'hC000_0000, 2'd2, 3'd1);
    send(32'h3F80_0000, 32'h3F80_0000, 2'd2, 3'd0);
    send(32'h3F80_0000, 32'h3F80_0000, 2'd2, 3'd1);
    send(32'h3F80_0000, 32'h3F80_0000, 2'd2, 3'd2);
    send(32'h8000_0000, 32'h0000_0000, 2'd2, 3'd0);
    send(32'h0000_0000, 32'h8000_0000, 2'd2, 3'd1);
    send(32'h8000_0000, 32'h0000_0000, 2'd2, 3'd2);
    send(32'hFF80_0000, 32'h7F80_0000, 2'd2, 3'd0);
    send(32'h7F80_0000, 32'h7F80_0000, 2'd2, 3'd2);
    send(32'h7FC0_0000, 32'h3F80_0000, 2'd2, 3'd0);
    send(32'h3F80_0000, 32'h7FC0_0000, 2'd2, 3'd1);
    send(32'h7FC0_0000, 32'h3F80_0000, 2'd2, 3'd2);
    send(32'h7FA0_0000, 32'h3F80_0000, 2'd2, 3'd2);
    send(32'h3F80_0000, 32'hFFA0_0001, 2'd2, 3'd0);

    // S12/S13: every classification, including both NaN kinds.
    send(32'hFF80_0000, 32'h1234_5678, 2'd3, 3'd0);
    send(32'hBF80_0000, 32'h0000_0000, 2'd3, 3'd1);
    send(32'h8000_0001, 32'h7FC0_0000, 2'd3, 3'd2);
    send(32'h8000_0000, 32'hFFFF_FFFF, 2'd3, 3'd3);
    send(32'h0000_0000, 32'h7FA0_0000, 2'd3, 3'd4);
    send(32'h0000_0001, 32'h0000_0000, 2'd3, 3'd5);
    send(32'h3F80_0000, 32'h8000_0000, 2'd3, 3'd6);
    send(32'h7F80_0000, 32'h0000_0000, 2'd3, 3'd7);
    send(32'h7FA0_0001, 32'h0000_0000, 2'd3, 3'd0);
    send(32'hFFC1_2345, 32'h0000_0000, 2'd3, 3'd7);

    bfm_idle();
    wait_empty(100000);

    // H2/H3: sustained backpressure for at least twenty result-valid cycles.
    sink_mode = 1;
    send(32'h7FC1_2345, 32'h8000_0000, 2'd0, 3'd0);
    bfm_idle();
    wait_out_valid(100000);
    repeat (30) @(negedge clk);
    sink_mode = 0;
    wait_empty(100000);
    if (stall_cycles < 20)
      fail("H3", "stimulus did not provide twenty stalled result cycles");

    // Randomized operand patterns and randomized result-side backpressure.
    sink_mode = 2;
    for (i = 0; i < 400; i = i + 1) begin
      ra = $urandom;
      rb = $urandom;
      rop = i % 4;
      case (rop)
        2'd0: rmode = i % 3;
        2'd1: rmode = i % 2;
        2'd2: rmode = i % 3;
        default: rmode = i % 8;
      endcase

      case (i % 20)
        0: begin ra = 32'h0000_0000; rb = 32'h8000_0000; end
        1: begin ra = 32'h8000_0000; rb = 32'h0000_0000; end
        2: begin ra = 32'h7FC0_0000; rb = 32'h3F80_0000; end
        3: begin ra = 32'h3F80_0000; rb = 32'h7FC0_0000; end
        4: begin ra = 32'h7FA0_0000; rb = 32'hBF80_0000; end
        5: begin ra = 32'hFFC1_2345; rb = 32'h7FA0_0001; end
        6: begin ra = 32'hFF80_0000; rb = 32'h7F80_0000; end
        7: begin ra = 32'h0000_0001; rb = 32'h8000_0001; end
        8: begin ra = 32'h7F7F_FFFF; rb = 32'hFF7F_FFFF; end
        9: begin rb = ra; end
        10: begin ra = 32'h7FC1_2345; rb = 32'h7FC5_4321; end
        11: begin ra = 32'h8000_0000; rb = 32'h8000_0000; end
        default: begin end
      endcase

      send(ra, rb, rop, rmode);
    end
    bfm_idle();
    sink_mode = 0;
    wait_empty(100000);

    // S15: an accepted, stalled operation must be discarded by reset.
    sink_mode = 1;
    send(32'h7FA0_0001, 32'h3F80_0000, 2'd1, 3'd0);
    bfm_idle();
    repeat (4) @(negedge clk);
    bfm_reset(3);
    sink_mode = 0;
    repeat (20) @(negedge clk);

    // Confirm ordinary operation after reset.
    send(32'h8000_0000, 32'h0000_0000, 2'd1, 3'd0);
    send(32'h0000_0000, 32'h8000_0000, 2'd2, 3'd2);
    send(32'h7FA0_0001, 32'h0000_0000, 2'd3, 3'd7);
    send(32'hFFA0_0001, 32'h8000_0000, 2'd0, 3'd2);
    bfm_idle();
    wait_empty(100000);

    repeat (5) @(negedge clk);
    $display("RESULT: PASS");
    $finish;
  end

endmodule
