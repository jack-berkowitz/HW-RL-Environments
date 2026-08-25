module fp_noncomp_tb;

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

  // ---------------------------------------------------------------------------
  // Reference model helpers
  // ---------------------------------------------------------------------------

  localparam logic [31:0] CANON_QNAN = 32'h7FC0_0000;
  localparam int QDEPTH = 512;

  function automatic bit fp_is_nan(input logic [31:0] x);
    begin
      fp_is_nan = (&x[30:23]) && (x[22:0] != 23'b0);
    end
  endfunction

  function automatic bit fp_is_snan(input logic [31:0] x);
    begin
      fp_is_snan = fp_is_nan(x) && (x[22] == 1'b0);
    end
  endfunction

  function automatic bit fp_is_zero(input logic [31:0] x);
    begin
      fp_is_zero = (x[30:0] == 31'b0);
    end
  endfunction

  // IEEE numeric less-than for non-NaN binary32 operands.  The two zeros are
  // equal for CMP, so neither is less than the other.
  function automatic bit fp_lt_non_nan(
      input logic [31:0] a,
      input logic [31:0] b
  );
    begin
      if (fp_is_zero(a) && fp_is_zero(b)) begin
        fp_lt_non_nan = 1'b0;
      end else if (a == b) begin
        fp_lt_non_nan = 1'b0;
      end else if (a[31] != b[31]) begin
        fp_lt_non_nan = a[31];
      end else if (a[31] == 1'b0) begin
        fp_lt_non_nan = (a[30:0] < b[30:0]);
      end else begin
        fp_lt_non_nan = (a[30:0] > b[30:0]);
      end
    end
  endfunction

  function automatic bit fp_eq_non_nan(
      input logic [31:0] a,
      input logic [31:0] b
  );
    begin
      if (fp_is_zero(a) && fp_is_zero(b))
        fp_eq_non_nan = 1'b1;
      else
        fp_eq_non_nan = (a == b);
    end
  endfunction

  function automatic logic [31:0] model_sgnj(
      input logic [31:0] a,
      input logic [31:0] b,
      input logic [2:0] mode
  );
    logic sign_v;
    begin
      sign_v = 1'b0;
      case (mode)
        3'd0: sign_v = b[31];
        3'd1: sign_v = ~b[31];
        3'd2: sign_v = a[31] ^ b[31];
        default: sign_v = 1'b0;
      endcase
      model_sgnj = {sign_v, a[30:0]};
    end
  endfunction

  function automatic logic [31:0] model_minmax(
      input logic [31:0] a,
      input logic [31:0] b,
      input logic        is_max
  );
    bit nan_a;
    bit nan_b;
    bit less_ab;
    begin
      nan_a = fp_is_nan(a);
      nan_b = fp_is_nan(b);
      less_ab = 1'b0;

      if (nan_a && nan_b) begin
        model_minmax = CANON_QNAN;
      end else if (nan_a) begin
        model_minmax = b;
      end else if (nan_b) begin
        model_minmax = a;
      end else if (fp_is_zero(a) && fp_is_zero(b)) begin
        // For MINMAX only, -0 is ordered below +0.  Preserve the correct
        // endpoint even when both operands have the same zero sign.
        if (is_max)
          model_minmax = (a[31] && b[31]) ? 32'h8000_0000 : 32'h0000_0000;
        else
          model_minmax = (a[31] || b[31]) ? 32'h8000_0000 : 32'h0000_0000;
      end else begin
        less_ab = fp_lt_non_nan(a, b);
        if (is_max)
          model_minmax = less_ab ? b : a;
        else
          model_minmax = less_ab ? a : b;
      end
    end
  endfunction

  function automatic logic [31:0] model_cmp(
      input logic [31:0] a,
      input logic [31:0] b,
      input logic [2:0]  mode
  );
    bit nan_any;
    bit pred_v;
    begin
      nan_any = fp_is_nan(a) || fp_is_nan(b);
      pred_v = 1'b0;

      if (!nan_any) begin
        case (mode)
          3'd0: pred_v = fp_lt_non_nan(a, b) || fp_eq_non_nan(a, b);
          3'd1: pred_v = fp_lt_non_nan(a, b);
          3'd2: pred_v = fp_eq_non_nan(a, b);
          default: pred_v = 1'b0;
        endcase
      end

      model_cmp = pred_v ? 32'h0000_0001 : 32'h0000_0000;
    end
  endfunction

  function automatic logic [9:0] model_class(input logic [31:0] a);
    logic [9:0] mask_v;
    begin
      mask_v = 10'b0;

      if (a[30:23] == 8'hFF) begin
        if (a[22:0] == 23'b0) begin
          if (a[31]) mask_v[0] = 1'b1;
          else       mask_v[7] = 1'b1;
        end else if (a[22] == 1'b0) begin
          mask_v[8] = 1'b1;
        end else begin
          mask_v[9] = 1'b1;
        end
      end else if (a[30:23] == 8'h00) begin
        if (a[22:0] == 23'b0) begin
          if (a[31]) mask_v[3] = 1'b1;
          else       mask_v[4] = 1'b1;
        end else begin
          if (a[31]) mask_v[2] = 1'b1;
          else       mask_v[5] = 1'b1;
        end
      end else begin
        if (a[31]) mask_v[1] = 1'b1;
        else       mask_v[6] = 1'b1;
      end

      model_class = mask_v;
    end
  endfunction

  function automatic logic [4:0] model_status(
      input logic [31:0] a,
      input logic [31:0] b,
      input logic [1:0]  op,
      input logic [2:0]  mode
  );
    bit nv_v;
    bit nan_any;
    bit snan_any;
    begin
      nv_v = 1'b0;
      nan_any = fp_is_nan(a) || fp_is_nan(b);
      snan_any = fp_is_snan(a) || fp_is_snan(b);

      case (op)
        2'd0: nv_v = 1'b0;
        2'd1: nv_v = snan_any;
        2'd2: begin
          case (mode)
            3'd0, 3'd1: nv_v = nan_any;
            3'd2:       nv_v = snan_any;
            default:    nv_v = 1'b0;
          endcase
        end
        2'd3: nv_v = 1'b0;
        default: nv_v = 1'b0;
      endcase

      model_status = {nv_v, 4'b0000};
    end
  endfunction

  // ---------------------------------------------------------------------------
  // Expected-result FIFO.  Results are identified strictly by acceptance order
  // as H2 requires; payload values are never used to search for an operation.
  // ---------------------------------------------------------------------------

  logic [31:0] exp_result [0:QDEPTH-1];
  logic [9:0]  exp_class  [0:QDEPTH-1];
  logic [4:0]  exp_status [0:QDEPTH-1];
  logic [1:0]  exp_op     [0:QDEPTH-1];
  logic [2:0]  exp_mode   [0:QDEPTH-1];
  logic        exp_check_result [0:QDEPTH-1];
  logic        exp_check_class  [0:QDEPTH-1];

  int q_head;
  int q_tail;
  int accepted_count;
  int delivered_count;
  int tb_cycle;
  bit verdict_done;
  bit prev_rst_low;

  integer q_slot;

  task automatic fail_clause(
      input string clause_name,
      input string detail
  );
    begin
      if (!verdict_done) begin
        verdict_done = 1'b1;
        $display("FAIL [%s] cycle=%0d: %s", clause_name, tb_cycle, detail);
        $display("RESULT: FAIL");
        $finish;
      end
    end
  endtask

  task automatic check_result_entry(input int slot);
    begin
      if (status_o !== exp_status[slot]) begin
        case (exp_op[slot])
          2'd0: fail_clause("S2/S14", "SGNJ status flags were incorrect");
          2'd1: fail_clause("S6/S14", "MINMAX status flags were incorrect");
          2'd2: fail_clause("S8/S9/S11/S14", "CMP status flags were incorrect");
          2'd3: fail_clause("S13/S14", "CLASSIFY status flags were incorrect");
          default: fail_clause("S14", "status flags were incorrect");
        endcase
      end

      if (exp_check_result[slot] && (result_o !== exp_result[slot])) begin
        case (exp_op[slot])
          2'd0: fail_clause("S1", "SGNJ result bits/sign were incorrect");
          2'd1: fail_clause("S3/S4/S5", "MINMAX result was incorrect");
          2'd2: fail_clause("S7/S8/S9/S10", "CMP boolean result was incorrect");
          default: fail_clause("H2", "result mismatch for a constrained operation");
        endcase
      end

      if (exp_check_class[slot] && (class_mask_o !== exp_class[slot]))
        fail_clause("S12", "CLASSIFY mask was not the required one-hot class");
    end
  endtask

  always @(posedge clk) begin
    if (!rst_n) begin
      tb_cycle = 0;
      q_head = 0;
      q_tail = 0;
      prev_rst_low = 1'b1;
    end else begin
      tb_cycle = tb_cycle + 1;

      // S15 pins the first cycle after reset release: no old result may remain.
      if (prev_rst_low && out_valid_o)
        fail_clause("S15", "out_valid_o was high on the first cycle after reset release");

      prev_rst_low = 1'b0;

      // H1: enqueue exactly the operation accepted on this edge.
      if (in_valid_i && in_ready_o) begin
        if ((q_tail - q_head) >= QDEPTH)
          fail_clause("H1/H2", "expected-result FIFO overflowed");

        q_slot = q_tail % QDEPTH;
        exp_op[q_slot] = op_i;
        exp_mode[q_slot] = op_mode_i;
        exp_status[q_slot] = model_status(operand_a_i, operand_b_i, op_i, op_mode_i);
        exp_check_result[q_slot] = (op_i != 2'd3);
        exp_check_class[q_slot] = (op_i == 2'd3);
        exp_class[q_slot] = model_class(operand_a_i);

        case (op_i)
          2'd0: exp_result[q_slot] = model_sgnj(operand_a_i, operand_b_i, op_mode_i);
          2'd1: exp_result[q_slot] = model_minmax(operand_a_i, operand_b_i,
                                                 (op_mode_i == 3'd1));
          2'd2: exp_result[q_slot] = model_cmp(operand_a_i, operand_b_i, op_mode_i);
          default: exp_result[q_slot] = 32'b0;
        endcase

        q_tail = q_tail + 1;
        accepted_count = accepted_count + 1;
      end

      // H2/H3: a delivered result must be exactly the oldest accepted operation.
      // Input enqueue is done first, so zero-latency same-edge accept/deliver is legal.
      if (out_valid_o && out_ready_i) begin
        if (q_head >= q_tail)
          fail_clause("H2/H3", "a result was duplicated or delivered with no accepted operation owed");

        q_slot = q_head % QDEPTH;
        check_result_entry(q_slot);
        q_head = q_head + 1;
        delivered_count = delivered_count + 1;
      end
    end
  end

  // ---------------------------------------------------------------------------
  // Bounded test helpers
  // ---------------------------------------------------------------------------

  task automatic wait_empty(input int max_cycles, input string clause_name);
    int n;
    begin
      n = 0;
      while ((q_head != q_tail) && (n < max_cycles)) begin
        @(negedge clk);
        n = n + 1;
      end

      if (q_head != q_tail)
        fail_clause(clause_name, "accepted operations did not all produce results within the bounded test window");
    end
  endtask

  task automatic issue_one(
      input logic [31:0] a,
      input logic [31:0] b,
      input logic [1:0]  op,
      input logic [2:0]  mode
  );
    begin
      bfm_issue(a, b, op, mode);
      bfm_idle();
    end
  endtask

  task automatic issue_batch_3(
      input logic [31:0] a0, input logic [31:0] b0, input logic [1:0] op0, input logic [2:0] m0,
      input logic [31:0] a1, input logic [31:0] b1, input logic [1:0] op1, input logic [2:0] m1,
      input logic [31:0] a2, input logic [31:0] b2, input logic [1:0] op2, input logic [2:0] m2
  );
    begin
      bfm_issue(a0, b0, op0, m0);
      bfm_issue(a1, b1, op1, m1);
      bfm_issue(a2, b2, op2, m2);
      bfm_idle();
    end
  endtask

  task automatic test_sgnj;
    begin
      // Normal operands, all three variants.
      issue_one(32'h3F80_0001, 32'hBF00_0000, 2'd0, 3'd0);
      issue_one(32'hBF80_0001, 32'h3F00_0000, 2'd0, 3'd1);
      issue_one(32'hBF80_1234, 32'h8000_0000, 2'd0, 3'd2);

      // NaN payloads must be copied unchanged except for the selected sign.
      issue_one(32'h7FC1_2345, 32'h8000_0000, 2'd0, 3'd0);
      issue_one(32'h7FA1_2345, 32'h0000_0000, 2'd0, 3'd1);
      issue_one(32'hFFA1_1111, 32'h8000_0000, 2'd0, 3'd2);

      wait_empty(4096, "S1/S2/H2");
    end
  endtask

  task automatic test_minmax;
    begin
      // Ordinary positive/negative ordering and infinities.
      issue_one(32'h3F80_0000, 32'h4000_0000, 2'd1, 3'd0); // min 1,2
      issue_one(32'h3F80_0000, 32'h4000_0000, 2'd1, 3'd1); // max 1,2
      issue_one(32'hC040_0000, 32'hBF80_0000, 2'd1, 3'd0); // min -3,-1
      issue_one(32'hC040_0000, 32'hBF80_0000, 2'd1, 3'd1); // max -3,-1
      issue_one(32'hFF80_0000, 32'h7F80_0000, 2'd1, 3'd0);
      issue_one(32'hFF80_0000, 32'h7F80_0000, 2'd1, 3'd1);

      // RISC-V zero ordering for MINMAX, in both operand orders.
      issue_one(32'h8000_0000, 32'h0000_0000, 2'd1, 3'd0);
      issue_one(32'h0000_0000, 32'h8000_0000, 2'd1, 3'd0);
      issue_one(32'h8000_0000, 32'h0000_0000, 2'd1, 3'd1);
      issue_one(32'h0000_0000, 32'h8000_0000, 2'd1, 3'd1);

      // Exactly one NaN: return the other operand, including qNaN and sNaN.
      issue_one(32'h7FC1_0001, 32'h4040_0000, 2'd1, 3'd0);
      issue_one(32'h4040_0000, 32'h7FC1_0001, 2'd1, 3'd1);
      issue_one(32'h7FA1_0001, 32'hC0A0_0000, 2'd1, 3'd0);
      issue_one(32'hC0A0_0000, 32'hFFA1_0001, 2'd1, 3'd1);

      // Both NaN: canonical qNaN, with NV iff at least one is signalling.
      issue_one(32'h7FC0_1111, 32'hFFC2_2222, 2'd1, 3'd0);
      issue_one(32'h7FA0_1111, 32'h7FC2_2222, 2'd1, 3'd1);
      issue_one(32'hFFA0_1111, 32'h7FA2_2222, 2'd1, 3'd0);

      wait_empty(4096, "S3/S4/S5/S6/H2");
    end
  endtask

  task automatic test_cmp;
    begin
      // Basic numeric comparisons.
      issue_one(32'h3F80_0000, 32'h4000_0000, 2'd2, 3'd0); // 1 <= 2
      issue_one(32'h4000_0000, 32'h3F80_0000, 2'd2, 3'd0); // 2 <= 1
      issue_one(32'hBF80_0000, 32'hC000_0000, 2'd2, 3'd1); // -1 < -2 false
      issue_one(32'hC000_0000, 32'hBF80_0000, 2'd2, 3'd1); // -2 < -1 true
      issue_one(32'h4040_0000, 32'h4040_0000, 2'd2, 3'd2); // equal

      // CMP treats +0 and -0 as equal and neither is less.
      issue_one(32'h8000_0000, 32'h0000_0000, 2'd2, 3'd2);
      issue_one(32'h8000_0000, 32'h0000_0000, 2'd2, 3'd1);
      issue_one(32'h0000_0000, 32'h8000_0000, 2'd2, 3'd0);

      // FLE/FLT are signalling comparisons: either NaN kind raises NV.
      issue_one(32'h7FC0_1234, 32'h3F80_0000, 2'd2, 3'd0);
      issue_one(32'h3F80_0000, 32'h7FC0_1234, 2'd2, 3'd1);
      issue_one(32'h7FA0_1234, 32'h3F80_0000, 2'd2, 3'd0);
      issue_one(32'h3F80_0000, 32'hFFA0_1234, 2'd2, 3'd1);

      // FEQ is quiet: qNaN -> false/no NV, sNaN -> false/NV.
      issue_one(32'h7FC0_5678, 32'h3F80_0000, 2'd2, 3'd2);
      issue_one(32'h3F80_0000, 32'h7FC0_5678, 2'd2, 3'd2);
      issue_one(32'h7FA0_5678, 32'h3F80_0000, 2'd2, 3'd2);

      wait_empty(4096, "S7/S8/S9/S10/S11/H2");
    end
  endtask

  task automatic test_classify;
    begin
      // One representative of every class.  operand_b and mode are deliberately
      // varied because CLASSIFY must ignore both.
      issue_one(32'hFF80_0000, 32'h1234_5678, 2'd3, 3'd0); // -inf
      issue_one(32'hBF80_0000, 32'h8765_4321, 2'd3, 3'd1); // -normal
      issue_one(32'h8000_0001, 32'hFFFF_FFFF, 2'd3, 3'd2); // -subnormal
      issue_one(32'h8000_0000, 32'h0000_0001, 2'd3, 3'd3); // -zero
      issue_one(32'h0000_0000, 32'h8000_0001, 2'd3, 3'd4); // +zero
      issue_one(32'h0000_0001, 32'h7FC0_0000, 2'd3, 3'd5); // +subnormal
      issue_one(32'h3F80_0000, 32'h7FA0_0001, 2'd3, 3'd6); // +normal
      issue_one(32'h7F80_0000, 32'h0000_0000, 2'd3, 3'd7); // +inf
      issue_one(32'h7FA0_0001, 32'hDEAD_BEEF, 2'd3, 3'd0); // sNaN
      issue_one(32'h7FC0_0001, 32'hCAFE_BABE, 2'd3, 3'd7); // qNaN

      wait_empty(4096, "S12/S13/S14/H2");
    end
  endtask

  task automatic test_backpressure_and_order;
    int start_delivered;
    int n;
    begin
      wait_empty(4096, "H2");

      bfm_out_ready(1'b0);

      // One accepted result is held back for a substantial interval.  The sink
      // makes no assumption about when out_valid appears while stalled.
      issue_one(32'h7FC1_1111, 32'h8000_0000, 2'd0, 3'd0);
      start_delivered = delivered_count;

      repeat (20) @(negedge clk);

      if (delivered_count != start_delivered)
        fail_clause("H3", "a result transferred while out_ready_i was low");

      bfm_out_ready(1'b1);
      wait_empty(4096, "H3");

      // Back-to-back accepted operations must emerge in acceptance order.  The
      // scoreboard is FIFO-based, so any reorder is caught regardless of latency.
      issue_batch_3(
          32'h3F80_0000, 32'h4000_0000, 2'd2, 3'd1,
          32'h8000_0000, 32'h0000_0000, 2'd1, 3'd0,
          32'h7FC0_1234, 32'h3F80_0000, 2'd2, 3'd2
      );

      wait_empty(4096, "H2/H3");

      // With no operation owed, any extra transfer is a duplicate.
      n = 0;
      while (n < 6) begin
        @(negedge clk);
        n = n + 1;
      end
    end
  endtask

  task automatic test_status_not_sticky;
    begin
      // First operation must raise NV; immediately following SGNJ must report
      // zero status.  This catches an accumulating/sticky status implementation.
      issue_batch_3(
          32'h7FA0_0001, 32'h3F80_0000, 2'd2, 3'd2,
          32'h3F80_0000, 32'h0000_0000, 2'd0, 3'd0,
          32'h7FC0_0001, 32'h3F80_0000, 2'd2, 3'd2
      );
      wait_empty(4096, "S14/H2");
    end
  endtask

  task automatic test_reset_discard;
    int n;
    begin
      wait_empty(4096, "H2");

      // Prevent the accepted operation from transferring before reset.
      bfm_out_ready(1'b0);
      issue_one(32'h4000_0000, 32'h3F80_0000, 2'd2, 3'd1);

      // Let the implementation place the result anywhere in its pipeline, then
      // synchronously reset it.  The scoreboard is cleared on reset edges.
      repeat (6) @(negedge clk);
      bfm_reset(4);

      // The first post-release rising edge is checked by the always block for
      // out_valid_o == 0.  Keep the source idle and re-enable the sink.
      bfm_out_ready(1'b1);

      for (n = 0; n < 12; n = n + 1) begin
        @(negedge clk);
        if (q_head != q_tail)
          fail_clause("S15", "a pre-reset operation re-entered the expected queue after reset");
      end

      // Prove the post-reset datapath still accepts and returns fresh work.
      issue_one(32'h3F80_0000, 32'h4000_0000, 2'd2, 3'd1);
      wait_empty(4096, "S15/H2");
    end
  endtask

  // ---------------------------------------------------------------------------
  // Initialization, watchdog, and top-level stimulus
  // ---------------------------------------------------------------------------

  initial begin
    operand_a_i = 32'b0;
    operand_b_i = 32'b0;
    op_i = 2'b0;
    op_mode_i = 3'b0;
    in_valid_i = 1'b0;
    out_ready_i = 1'b1;

    q_head = 0;
    q_tail = 0;
    accepted_count = 0;
    delivered_count = 0;
    tb_cycle = 0;
    verdict_done = 1'b0;
    prev_rst_low = 1'b1;
  end

  // Watchdog required by S16.  It is independent of DUT progress.
  initial begin
    #200_000_000;
    if (!verdict_done) begin
      verdict_done = 1'b1;
      $display("FAIL [S16]: watchdog: no forward progress");
      $display("RESULT: FAIL");
      $finish;
    end
  end

  initial begin
    // Initial synchronous reset.  Do not inspect invalid payload outputs.
    bfm_reset(4);

    // First cycle after reset release is checked automatically by S15 logic.
    repeat (2) @(negedge clk);

    test_sgnj();
    test_minmax();
    test_cmp();
    test_classify();
    test_backpressure_and_order();
    test_status_not_sticky();
    test_reset_discard();

    wait_empty(4096, "H2/H3");

    if (!verdict_done) begin
      verdict_done = 1'b1;
      $display("RESULT: PASS");
      $finish;
    end
  end

endmodule