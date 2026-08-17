module fp_noncomp_tb;

  localparam int REQ_S1  = 1;
  localparam int REQ_S2  = 2;
  localparam int REQ_S3  = 3;
  localparam int REQ_S4  = 4;
  localparam int REQ_S5  = 5;
  localparam int REQ_S6  = 6;
  localparam int REQ_S7  = 7;
  localparam int REQ_S8  = 8;
  localparam int REQ_S9  = 9;
  localparam int REQ_S10 = 10;
  localparam int REQ_S11 = 11;
  localparam int REQ_S12 = 12;
  localparam int REQ_S13 = 13;
  localparam int REQ_S14 = 14;
  localparam int REQ_S15 = 15;
  localparam int REQ_S16 = 16;
  localparam int REQ_H1  = 41;
  localparam int REQ_H2  = 42;
  localparam int REQ_H3  = 43;
  localparam int REQ_H4  = 44;

  logic        clk_i;
  logic        rst_ni;
  logic [31:0] operand_a_i;
  logic [31:0] operand_b_i;
  logic [1:0]  op_i;
  logic [2:0]  op_mode_i;
  logic        in_valid_i;
  logic        in_ready_o;
  logic [31:0] result_o;
  logic [9:0]  class_mask_o;
  logic [4:0]  status_o;
  logic        out_valid_o;
  logic        out_ready_i;

  fp_noncomp dut (
    .clk_i        (clk_i),
    .rst_ni       (rst_ni),
    .operand_a_i  (operand_a_i),
    .operand_b_i  (operand_b_i),
    .op_i         (op_i),
    .op_mode_i    (op_mode_i),
    .in_valid_i   (in_valid_i),
    .in_ready_o   (in_ready_o),
    .result_o     (result_o),
    .class_mask_o (class_mask_o),
    .status_o     (status_o),
    .out_valid_o  (out_valid_o),
    .out_ready_i  (out_ready_i)
  );

  typedef struct packed {
    logic [31:0] a;
    logic [31:0] b;
    logic [1:0]  op;
    logic [2:0]  mode;
  } stim_t;

  typedef struct packed {
    logic        check_result;
    logic        check_class;
    logic [31:0] result;
    logic [9:0]  class_mask;
    logic        nv;
    logic [7:0]  result_req;
    logic [7:0]  nv_req;
    logic [15:0] seq;
  } exp_t;

  stim_t stim_q[$];
  exp_t  exp_q[$];

  integer fail_count = 0;
  integer accepted_count = 0;
  integer delivered_count = 0;
  integer bp_cycle = 0;
  integer seq_counter = 0;

  bit done = 0;
  bit driver_active = 0;
  bit accepted_last_edge = 0;
  bit prev_reset_low = 1;
  bit post_reset_guard = 1;
  bit stalled_front = 0;

  bit src_waiting = 0;
  logic [31:0] src_a_hold;
  logic [31:0] src_b_hold;
  logic [1:0]  src_op_hold;
  logic [2:0]  src_mode_hold;

  // Clock: # delay is permitted by the task only for the clock and watchdog.
  initial begin
    clk_i = 1'b0;
    forever #5 clk_i = ~clk_i;
  end

  task automatic fail_code(input int code, input string msg);
    begin
      fail_count = fail_count + 1;
      case (code)
        REQ_S1:  $display("FAIL [S1] %s", msg);
        REQ_S2:  $display("FAIL [S2] %s", msg);
        REQ_S3:  $display("FAIL [S3] %s", msg);
        REQ_S4:  $display("FAIL [S4] %s", msg);
        REQ_S5:  $display("FAIL [S5] %s", msg);
        REQ_S6:  $display("FAIL [S6] %s", msg);
        REQ_S7:  $display("FAIL [S7] %s", msg);
        REQ_S8:  $display("FAIL [S8] %s", msg);
        REQ_S9:  $display("FAIL [S9] %s", msg);
        REQ_S10: $display("FAIL [S10] %s", msg);
        REQ_S11: $display("FAIL [S11] %s", msg);
        REQ_S12: $display("FAIL [S12] %s", msg);
        REQ_S13: $display("FAIL [S13] %s", msg);
        REQ_S14: $display("FAIL [S14] %s", msg);
        REQ_S15: $display("FAIL [S15] %s", msg);
        REQ_S16: $display("FAIL [S16] %s", msg);
        REQ_H1:  $display("FAIL [H1] %s", msg);
        REQ_H2:  $display("FAIL [H2] %s", msg);
        REQ_H3:  $display("FAIL [H3] %s", msg);
        REQ_H4:  $display("FAIL [H4] %s", msg);
        default: $display("FAIL [S16] internal checker error: %s", msg);
      endcase
    end
  endtask

  function automatic bit fp_is_nan(input logic [31:0] x);
    fp_is_nan = (&x[30:23]) && (|x[22:0]);
  endfunction

  function automatic bit fp_is_snan(input logic [31:0] x);
    fp_is_snan = (&x[30:23]) && (|x[22:0]) && !x[22];
  endfunction

  function automatic bit fp_is_zero(input logic [31:0] x);
    fp_is_zero = (x[30:0] == 31'd0);
  endfunction

  // IEEE comparison ordering for non-NaNs; +0 and -0 compare equal.
  function automatic bit fp_lt(input logic [31:0] a, input logic [31:0] b);
    begin
      if (fp_is_zero(a) && fp_is_zero(b)) begin
        fp_lt = 1'b0;
      end else if (a[31] != b[31]) begin
        fp_lt = a[31];
      end else if (!a[31]) begin
        fp_lt = (a[30:0] < b[30:0]);
      end else begin
        fp_lt = (a[30:0] > b[30:0]);
      end
    end
  endfunction

  function automatic bit fp_eq(input logic [31:0] a, input logic [31:0] b);
    fp_eq = (a == b) || (fp_is_zero(a) && fp_is_zero(b));
  endfunction

  // MINMAX uses the RISC-V special ordering -0 < +0.
  function automatic bit minmax_lt(input logic [31:0] a, input logic [31:0] b);
    begin
      if (fp_is_zero(a) && fp_is_zero(b)) begin
        minmax_lt = a[31] && !b[31];
      end else begin
        minmax_lt = fp_lt(a, b);
      end
    end
  endfunction

  function automatic logic [9:0] classify_ref(input logic [31:0] a);
    logic [9:0] c;
    begin
      c = 10'b0;
      if (a[30:23] == 8'hff) begin
        if (a[22:0] == 23'd0)
          c[a[31] ? 0 : 7] = 1'b1;
        else if (a[22])
          c[9] = 1'b1;
        else
          c[8] = 1'b1;
      end else if (a[30:23] == 8'h00) begin
        if (a[22:0] == 23'd0)
          c[a[31] ? 3 : 4] = 1'b1;
        else
          c[a[31] ? 2 : 5] = 1'b1;
      end else begin
        c[a[31] ? 1 : 6] = 1'b1;
      end
      classify_ref = c;
    end
  endfunction

  function automatic exp_t make_exp(
    input logic [31:0] a,
    input logic [31:0] b,
    input logic [1:0]  op,
    input logic [2:0]  mode
  );
    exp_t e;
    bit an, bn, asn, bsn;
    bit sign_res;
    begin
      e = '0;
      an  = fp_is_nan(a);
      bn  = fp_is_nan(b);
      asn = fp_is_snan(a);
      bsn = fp_is_snan(b);

      case (op)
        2'd0: begin : model_sgnj
          e.check_result = 1'b1;
          e.check_class  = 1'b0;
          case (mode)
            3'd0: sign_res = b[31];
            3'd1: sign_res = ~b[31];
            3'd2: sign_res = a[31] ^ b[31];
            default: sign_res = a[31];
          endcase
          e.result     = {sign_res, a[30:0]};
          e.nv         = 1'b0;
          e.result_req = REQ_S1;
          e.nv_req     = REQ_S2;
        end

        2'd1: begin : model_minmax
          e.check_result = 1'b1;
          e.check_class  = 1'b0;
          e.nv           = asn || bsn;
          e.nv_req       = REQ_S6;

          if (an && bn) begin
            e.result     = 32'h7fc0_0000;
            e.result_req = REQ_S5;
          end else if (an) begin
            e.result     = b;
            e.result_req = REQ_S4;
          end else if (bn) begin
            e.result     = a;
            e.result_req = REQ_S4;
          end else begin
            if (mode == 3'd0) begin
              if (minmax_lt(a, b))
                e.result = a;
              else
                e.result = b;
            end else begin
              if (minmax_lt(a, b))
                e.result = b;
              else
                e.result = a;
            end
            e.result_req = REQ_S3;
          end
        end

        2'd2: begin : model_cmp
          e.check_result = 1'b1;
          e.check_class  = 1'b0;
          e.result       = 32'd0;

          if ((mode == 3'd0) || (mode == 3'd1)) begin
            // FLE/FLT are signalling comparisons.
            e.nv     = an || bn;
            e.nv_req = REQ_S8;

            if (an || bn) begin
              e.result     = 32'd0;
              e.result_req = REQ_S8;
            end else begin
              if (mode == 3'd0)
                e.result = {31'd0, (fp_lt(a,b) || fp_eq(a,b))};
              else
                e.result = {31'd0, fp_lt(a,b)};

              if (fp_is_zero(a) && fp_is_zero(b))
                e.result_req = REQ_S10;
              else
                e.result_req = REQ_S7;
            end

          end else begin
            // FEQ is a quiet comparison.
            e.nv     = asn || bsn;
            e.nv_req = REQ_S9;

            if (an || bn) begin
              e.result     = 32'd0;
              e.result_req = REQ_S9;
            end else begin
              e.result = {31'd0, fp_eq(a,b)};

              if (fp_is_zero(a) && fp_is_zero(b))
                e.result_req = REQ_S10;
              else
                e.result_req = REQ_S7;
            end
          end
        end

        2'd3: begin : model_classify
          // result_o is explicitly unconstrained for CLASSIFY.
          e.check_result = 1'b0;
          e.check_class  = 1'b1;
          e.class_mask   = classify_ref(a);
          e.nv           = 1'b0;
          e.result_req   = REQ_S12;
          e.nv_req       = REQ_S13;
        end

        default: begin
          e = '0;
        end
      endcase

      make_exp = e;
    end
  endfunction

  function automatic bit observation_matches(
    input exp_t e,
    input logic [31:0] r,
    input logic [9:0]  c,
    input logic [4:0]  s
  );
    bit ok;
    begin
      ok = 1'b1;

      if (s[3:0] != 4'b0000)
        ok = 1'b0;

      if (s[4] != e.nv)
        ok = 1'b0;

      if (e.check_result && (r != e.result))
        ok = 1'b0;

      if (e.check_class && (c != e.class_mask))
        ok = 1'b0;

      observation_matches = ok;
    end
  endfunction

  task automatic add_stim(
    input logic [31:0] a,
    input logic [31:0] b,
    input logic [1:0]  op,
    input logic [2:0]  mode
  );
    stim_t s;
    begin
      s.a    = a;
      s.b    = b;
      s.op   = op;
      s.mode = mode;
      stim_q.push_back(s);
    end
  endtask

  task automatic add_sgnj3(
    input logic [31:0] a,
    input logic [31:0] b
  );
    begin
      add_stim(a, b, 2'd0, 3'd0);
      add_stim(a, b, 2'd0, 3'd1);
      add_stim(a, b, 2'd0, 3'd2);
    end
  endtask

  task automatic add_minmax2(
    input logic [31:0] a,
    input logic [31:0] b
  );
    begin
      add_stim(a, b, 2'd1, 3'd0);
      add_stim(a, b, 2'd1, 3'd1);
    end
  endtask

  task automatic add_cmp3(
    input logic [31:0] a,
    input logic [31:0] b
  );
    begin
      add_stim(a, b, 2'd2, 3'd0);
      add_stim(a, b, 2'd2, 3'd1);
      add_stim(a, b, 2'd2, 3'd2);
    end
  endtask

  task automatic add_class(
    input logic [31:0] a,
    input logic [31:0] b,
    input logic [2:0] mode
  );
    begin
      add_stim(a, b, 2'd3, mode);
    end
  endtask

  task automatic add_directed;
    begin

      // ------------------------------------------------------------
      // S1/S2: SGNJ
      // Ordinary values, zeros, infinities, subnormals and NaN
      // payloads. NaNs must not be canonicalized.
      // ------------------------------------------------------------

      add_sgnj3(32'h3f80_0001, 32'h8000_0000);
      add_sgnj3(32'hbf80_0001, 32'h0000_0000);
      add_sgnj3(32'h7f80_0000, 32'hff80_0000);
      add_sgnj3(32'h0000_0001, 32'h8000_0001);

      add_sgnj3(32'h7fc1_2345, 32'h8000_0000);
      add_sgnj3(32'h7f81_2345, 32'h0000_0000);
      add_sgnj3(32'hff81_2345, 32'h8000_0000);

      // ------------------------------------------------------------
      // S3: MIN/MAX numeric ordering
      // ------------------------------------------------------------

      add_minmax2(32'h3f80_0000, 32'h4000_0000); // +1, +2
      add_minmax2(32'h4000_0000, 32'h3f80_0000);

      add_minmax2(32'hbf80_0000, 32'hc000_0000); // -1, -2
      add_minmax2(32'hc000_0000, 32'hbf80_0000);

      add_minmax2(32'hbf80_0000, 32'h3f80_0000);

      add_minmax2(32'hff80_0000, 32'h7f80_0000);

      add_minmax2(32'h0000_0001, 32'h0000_0002);
      add_minmax2(32'h8000_0001, 32'h8000_0002);

      // Signed-zero special ordering for MINMAX.
      add_minmax2(32'h8000_0000, 32'h0000_0000);
      add_minmax2(32'h0000_0000, 32'h8000_0000);

      // ------------------------------------------------------------
      // S4/S5/S6 + A2/A3:
      // One-NaN and two-NaN MINMAX cases.
      // ------------------------------------------------------------

      // qNaN + number
      add_minmax2(32'h7fc1_1111, 32'h3f80_0000);
      add_minmax2(32'h3f80_0000, 32'hffc2_2222);

      // sNaN + number
      add_minmax2(32'h7f81_1111, 32'h4000_0000);
      add_minmax2(32'hc000_0000, 32'hff82_2222);

      // both quiet NaNs
      add_minmax2(32'h7fc1_1111, 32'hffc2_2222);

      // signalling + quiet
      add_minmax2(32'h7f81_1111, 32'h7fc2_2222);

      // both signalling
      add_minmax2(32'hff81_1111, 32'h7f82_2222);

      // ------------------------------------------------------------
      // S7/S10: ordinary comparisons and signed-zero comparison.
      // ------------------------------------------------------------

      add_cmp3(32'h3f80_0000, 32'h4000_0000);
      add_cmp3(32'h4000_0000, 32'h3f80_0000);

      add_cmp3(32'hbf80_0000, 32'hc000_0000);
      add_cmp3(32'hc000_0000, 32'hbf80_0000);

      add_cmp3(32'h3f80_0000, 32'h3f80_0000);

      add_cmp3(32'h8000_0000, 32'h0000_0000);
      add_cmp3(32'h0000_0000, 32'h8000_0000);

      add_cmp3(32'h7f80_0000, 32'hff80_0000);

      add_cmp3(32'h0000_0001, 32'h0000_0002);
      add_cmp3(32'h8000_0001, 32'h8000_0002);

      // ------------------------------------------------------------
      // S8/S9/S11:
      // Signalling versus quiet comparison NaN behavior.
      // ------------------------------------------------------------

      add_cmp3(32'h7fc1_2345, 32'h3f80_0000);
      add_cmp3(32'h3f80_0000, 32'hffc1_2345);

      add_cmp3(32'h7f81_2345, 32'h4000_0000);
      add_cmp3(32'h4000_0000, 32'hff81_2345);

      add_cmp3(32'h7fc1_2345, 32'h7f81_2345);

      // ------------------------------------------------------------
      // S12/S13: CLASSIFY
      // Exercise every one of the ten classes.
      // operand_b deliberately varies because it must be ignored.
      // op_mode deliberately varies because it must be ignored.
      // ------------------------------------------------------------

      add_class(32'hff80_0000, 32'h7fc0_0001, 3'd0); // -infinity
      add_class(32'hbf80_0000, 32'h0000_0000, 3'd1); // -normal
      add_class(32'h8000_0001, 32'hffff_ffff, 3'd2); // -subnormal
      add_class(32'h8000_0000, 32'h7f81_0001, 3'd3); // -zero
      add_class(32'h0000_0000, 32'hff81_0001, 3'd4); // +zero
      add_class(32'h0000_0001, 32'h7fc0_0001, 3'd5); // +subnormal
      add_class(32'h3f80_0000, 32'hdead_beef, 3'd6); // +normal
      add_class(32'h7f80_0000, 32'h8000_0000, 3'd7); // +infinity
      add_class(32'h7f80_0001, 32'h7fc0_0000, 3'd0); // signalling NaN
      add_class(32'h7fc0_0001, 32'h7f80_0001, 3'd7); // quiet NaN

    end
  endtask

  function automatic logic [31:0] lcg(input logic [31:0] x);
    lcg = x * 32'd1664525 + 32'd1013904223;
  endfunction

  task automatic init_stimuli;
    logic [31:0] seed;
    logic [31:0] a;
    logic [31:0] b;
    integer i;
    begin

      add_directed();

      // Deterministic broad bit-pattern coverage.
      // Every op/mode combination driven here is legal under the spec.
      seed = 32'h6d2b_79f5;

      for (i = 0; i < 32; i = i + 1) begin

        seed = lcg(seed);
        a = seed;

        seed = lcg(seed);
        b = seed;

        add_sgnj3(a, b);
        add_minmax2(a, b);
        add_cmp3(a, b);

        if ((i & 3) == 0)
          add_class(a, b, i[2:0]);

      end

      // Repeat the high-value directed corner cases so that a substantial
      // directed set is also exercised after the mid-test reset.
      add_directed();

    end
  endtask


  // ================================================================
  // SOURCE DRIVER
  //
  // Once in_valid is asserted, it remains asserted with all operation
  // inputs stable until an actual valid/ready acceptance.
  //
  // This satisfies H4 and does not assume any promptness from ready.
  // ================================================================

  always @(negedge clk_i) begin : source_driver
    stim_t s;

    if (driver_active && accepted_last_edge) begin
      driver_active = 1'b0;
      in_valid_i     = 1'b0;
    end

    if (rst_ni &&
        !driver_active &&
        (stim_q.size() != 0)) begin

      s = stim_q.pop_front();

      operand_a_i = s.a;
      operand_b_i = s.b;
      op_i        = s.op;
      op_mode_i   = s.mode;

      in_valid_i   = 1'b1;
      driver_active = 1'b1;

    end
  end


  // ================================================================
  // OUTPUT BACKPRESSURE
  //
  // Generate deterministic single- and multi-cycle ready stalls.
  // ================================================================

  always @(negedge clk_i) begin : sink_driver

    if (!rst_ni) begin
      out_ready_i = 1'b0;
      bp_cycle    = 0;
    end else begin

      bp_cycle = bp_cycle + 1;

      if (((bp_cycle % 19) >= 11 &&
           (bp_cycle % 19) <= 15) ||
          ((bp_cycle % 53) >= 31 &&
           (bp_cycle % 53) <= 40))
        out_ready_i = 1'b0;
      else
        out_ready_i = 1'b1;

    end
  end


  // ================================================================
  // H4 SOURCE-OBLIGATION SELF CHECK
  //
  // This checks the behavior of the testbench itself.
  // ================================================================

  always @(posedge clk_i) begin : source_obligation_check

    if (src_waiting) begin

      if (!in_valid_i ||
          (operand_a_i !== src_a_hold) ||
          (operand_b_i !== src_b_hold) ||
          (op_i        !== src_op_hold) ||
          (op_mode_i   !== src_mode_hold)) begin

        fail_code(
          REQ_H4,
          "testbench changed/withdrew a request before acceptance"
        );

      end
    end

    if (in_valid_i && !in_ready_o) begin

      src_waiting   = 1'b1;
      src_a_hold    = operand_a_i;
      src_b_hold    = operand_b_i;
      src_op_hold   = op_i;
      src_mode_hold = op_mode_i;

    end else begin

      src_waiting = 1'b0;

    end
  end


  // ================================================================
  // ACCEPTANCE-DRIVEN SCOREBOARD
  //
  // No DUT latency is assumed.
  //
  // Outputs are inspected only on an actual output handshake, except
  // for the explicit S15 first-cycle-after-reset out_valid rule.
  // ================================================================

  always @(posedge clk_i) begin : scoreboard

    exp_t e;
    exp_t got_exp;
    bit later_match;
    integer k;

    accepted_last_edge = in_valid_i && in_ready_o;

    if (!rst_ni) begin

      // S15:
      // All work accepted before or during reset must be discarded.
      exp_q.delete();

      prev_reset_low  = 1'b1;
      post_reset_guard = 1'b1;
      stalled_front   = 1'b0;

    end else begin

      // ------------------------------------------------------------
      // S15 first cycle after reset release.
      // ------------------------------------------------------------

      if (prev_reset_low) begin

        if (out_valid_o !== 1'b0) begin

          fail_code(
            REQ_S15,
            "out_valid_o was high on the first cycle after reset release"
          );

        end

        prev_reset_low = 1'b0;

      end


      // ------------------------------------------------------------
      // H1
      //
      // An input operation enters the reference scoreboard only when
      // valid && ready at the rising edge.
      // ------------------------------------------------------------

      if (in_valid_i && in_ready_o) begin

        e = make_exp(
          operand_a_i,
          operand_b_i,
          op_i,
          op_mode_i
        );

        e.seq = seq_counter[15:0];
        seq_counter = seq_counter + 1;

        exp_q.push_back(e);

        accepted_count = accepted_count + 1;
        post_reset_guard = 1'b0;

      end


      // Remember that the current head operation has encountered
      // output backpressure. If that operation is later corrupted or
      // lost, identify H3 in addition to its functional requirement.
      if (out_valid_o &&
          !out_ready_i &&
          (exp_q.size() != 0)) begin

        stalled_front = 1'b1;

      end


      // ------------------------------------------------------------
      // H2
      //
      // A result is delivered only when out_valid && out_ready.
      // Results are compared to the accepted operations in FIFO order.
      // ------------------------------------------------------------

      if (out_valid_o && out_ready_i) begin

        delivered_count = delivered_count + 1;

        if (exp_q.size() == 0) begin

          if (post_reset_guard) begin

            fail_code(
              REQ_S15,
              "a result was delivered after reset with no post-reset operation accepted"
            );

          end else begin

            fail_code(
              REQ_H2,
              "spurious or duplicated output handshake with no accepted operation pending"
            );

          end

        end else begin

          got_exp = exp_q.pop_front();


          // Check whether this observed output exactly matches one of
          // the later expected transactions. This gives a useful H2
          // diagnostic for a common explicit reordering failure.
          later_match = 1'b0;

          for (k = 0; k < exp_q.size(); k = k + 1) begin

            if (observation_matches(
                  exp_q[k],
                  result_o,
                  class_mask_o,
                  status_o
                )) begin

              later_match = 1'b1;

            end
          end

          if (later_match) begin

            fail_code(
              REQ_H2,
              $sformatf(
                "output matched a later accepted operation instead of seq %0d",
                got_exp.seq
              )
            );

          end


          // --------------------------------------------------------
          // S14
          //
          // DZ, OF, UF and NX must always be zero.
          // --------------------------------------------------------

          if (status_o[3:0] !== 4'b0000) begin

            fail_code(
              REQ_S14,
              $sformatf(
                "seq %0d status lower flags were %b",
                got_exp.seq,
                status_o[3:0]
              )
            );

          end


          // --------------------------------------------------------
          // Operation-specific NV behavior.
          // --------------------------------------------------------

          if (status_o[4] !== got_exp.nv) begin

            fail_code(
              got_exp.nv_req,
              $sformatf(
                "seq %0d NV got %b expected %b",
                got_exp.seq,
                status_o[4],
                got_exp.nv
              )
            );

          end


          // --------------------------------------------------------
          // Functional result check.
          //
          // CLASSIFY deliberately skips result_o because it is
          // explicitly unconstrained for that operation.
          // --------------------------------------------------------

          if (got_exp.check_result &&
              (result_o !== got_exp.result)) begin

            if (stalled_front) begin

              fail_code(
                REQ_H3,
                $sformatf(
                  "seq %0d result changed/lost across output backpressure",
                  got_exp.seq
                )
              );

            end

            fail_code(
              got_exp.result_req,
              $sformatf(
                "seq %0d result got %08x expected %08x",
                got_exp.seq,
                result_o,
                got_exp.result
              )
            );

          end


          // --------------------------------------------------------
          // CLASSIFY mask.
          //
          // class_mask_o is not checked for any other operation.
          // --------------------------------------------------------

          if (got_exp.check_class &&
              (class_mask_o !== got_exp.class_mask)) begin

            if (stalled_front) begin

              fail_code(
                REQ_H3,
                $sformatf(
                  "seq %0d classification changed/lost across output backpressure",
                  got_exp.seq
                )
              );

            end

            fail_code(
              REQ_S12,
              $sformatf(
                "seq %0d class_mask got %03x expected %03x",
                got_exp.seq,
                class_mask_o,
                got_exp.class_mask
              )
            );

          end

          stalled_front = 1'b0;

        end
      end
    end
  end


  // ================================================================
  // MAIN FINITE TEST SCHEDULE
  //
  // We deliberately do NOT wait indefinitely for:
  //   * in_ready_o to rise, or
  //   * every accepted transaction to produce a result.
  //
  // The specification explicitly leaves both ready promptness and
  // result latency unconstrained. The test therefore runs for a finite
  // number of cycles and checks everything the DUT actually accepts
  // and delivers during that period.
  // ================================================================

  initial begin : main_test

    rst_ni      = 1'b0;
    operand_a_i = 32'd0;
    operand_b_i = 32'd0;
    op_i        = 2'd0;
    op_mode_i   = 3'd0;
    in_valid_i  = 1'b0;
    out_ready_i = 1'b0;

    init_stimuli();


    // --------------------------------------------------------------
    // Initial synchronous reset.
    // --------------------------------------------------------------

    repeat (4)
      @(posedge clk_i);

    @(negedge clk_i);
    rst_ni <= 1'b1;


    // --------------------------------------------------------------
    // Run a substantial prefix.
    // --------------------------------------------------------------

    repeat (450)
      @(posedge clk_i);


    // --------------------------------------------------------------
    // Assert reset while transactions may still be in flight.
    // This explicitly exercises S15's discard requirement.
    // --------------------------------------------------------------

    @(negedge clk_i);
    rst_ni <= 1'b0;

    repeat (3)
      @(posedge clk_i);

    @(negedge clk_i);
    rst_ni <= 1'b1;


    // --------------------------------------------------------------
    // Continue long enough for the complete directed + deterministic
    // suite on ordinary implementations.
    //
    // Completion itself is not used as a correctness requirement
    // because latency and ready promptness are unconstrained.
    // --------------------------------------------------------------

    repeat (2200)
      @(posedge clk_i);

    @(negedge clk_i);


    // --------------------------------------------------------------
    // Exactly one final RESULT line.
    // --------------------------------------------------------------

    done = 1'b1;

    if (fail_count == 0)
      $display("RESULT: PASS");
    else
      $display("RESULT: FAIL");

    $finish;

  end


  // ================================================================
  // S16 INDEPENDENT WATCHDOG
  //
  // This initial block terminates the simulation regardless of what
  // the DUT does.
  // ================================================================

  initial begin : watchdog

    #1000000;

    if (!done) begin

      fail_code(
        REQ_S16,
        "watchdog expired before normal testbench termination"
      );

      done = 1'b1;

      $display("RESULT: FAIL");
      $finish;

    end
  end

endmodule