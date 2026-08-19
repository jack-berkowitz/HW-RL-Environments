`timescale 1ns/1ps

module fp_noncomp_tb;

  // ---------------------------------------------------------------------------
  // DUT signals
  // ---------------------------------------------------------------------------
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


  // ---------------------------------------------------------------------------
  // PROVIDED PLUMBING
  // ---------------------------------------------------------------------------

  // ---- clock -----------------------------------------------------------------
  initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
  end

  // ---- reset (active low, synchronous) ---------------------------------------
  initial rst_n = 1'b0;

  task automatic bfm_reset(input int cycles = 4);
    @(negedge clk);
    rst_n = 1'b0;
    repeat (cycles) @(posedge clk);
    @(negedge clk);
    rst_n = 1'b1;
  endtask

  // ---- issue -----------------------------------------------------------------
  task automatic bfm_issue(
    input logic [31:0] a,
    input logic [31:0] b,
    input logic [1:0]  op,
    input logic [2:0]  mode
  );
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

  // ---- result side -----------------------------------------------------------
  task automatic bfm_out_ready(input logic value);
    @(negedge clk);
    out_ready_i = value;
  endtask

  // ---- watchdog (S16) --------------------------------------------------------
  initial begin
    #200_000_000;
    $display("FAIL S16: watchdog expired before the test completed");
    $display("RESULT: FAIL");
    $finish;
  end


  // ---------------------------------------------------------------------------
  // Binary32 reference helpers -- A1/A3
  // ---------------------------------------------------------------------------

  function automatic logic is_nan32(input logic [31:0] x);
    return (x[30:23] == 8'hff) &&
           (x[22:0]  != 23'h0);
  endfunction

  // A3: signalling iff exponent=all ones, fraction!=0, quiet bit=0.
  function automatic logic is_snan32(input logic [31:0] x);
    return is_nan32(x) && (x[22] == 1'b0);
  endfunction

  function automatic logic is_zero32(input logic [31:0] x);
    return (x[30:0] == 31'h0);
  endfunction


  // ---------------------------------------------------------------------------
  // Comparison reference
  //
  // These functions are only used for non-arithmetic comparisons.  No host
  // floating-point is used, avoiding host NaN/rounding behavior entirely.
  // ---------------------------------------------------------------------------

  function automatic logic fp_eq_ref(
    input logic [31:0] a,
    input logic [31:0] b
  );
    if (is_nan32(a) || is_nan32(b)) begin
      return 1'b0;
    end

    // S10: +0 and -0 compare equal.
    if (is_zero32(a) && is_zero32(b)) begin
      return 1'b1;
    end

    return (a == b);
  endfunction


  function automatic logic fp_lt_ref(
    input logic [31:0] a,
    input logic [31:0] b
  );
    if (is_nan32(a) || is_nan32(b)) begin
      return 1'b0;
    end

    // S10: neither zero is less than the other.
    if (is_zero32(a) && is_zero32(b)) begin
      return 1'b0;
    end

    // Opposite signs: negative is less.
    if (a[31] != b[31]) begin
      return a[31];
    end

    // Same-sign positive values order by exponent/fraction encoding.
    if (a[31] == 1'b0) begin
      return (a[30:0] < b[30:0]);
    end

    // Same-sign negative values have reversed magnitude ordering.
    return (a[30:0] > b[30:0]);
  endfunction


  // ---------------------------------------------------------------------------
  // MINMAX reference -- S3/S4/S5/A2
  // ---------------------------------------------------------------------------

  function automatic logic [31:0] minmax_ref(
    input logic [31:0] a,
    input logic [31:0] b,
    input logic        is_max
  );
    logic nan_a;
    logic nan_b;
    logic a_lt_b;

    nan_a = is_nan32(a);
    nan_b = is_nan32(b);

    // S5 / A2
    if (nan_a && nan_b) begin
      return 32'h7fc0_0000;
    end

    // S4: exactly one NaN is ignored, including an sNaN.
    if (nan_a) begin
      return b;
    end

    if (nan_b) begin
      return a;
    end

    // S3: MINMAX specifically orders -0 below +0.
    if (is_zero32(a) && is_zero32(b)) begin
      if (is_max) begin
        return ((!a[31]) || (!b[31]))
             ? 32'h0000_0000
             : 32'h8000_0000;
      end

      return (a[31] || b[31])
           ? 32'h8000_0000
           : 32'h0000_0000;
    end

    a_lt_b = fp_lt_ref(a, b);

    if (is_max) begin
      return a_lt_b ? b : a;
    end

    return a_lt_b ? a : b;
  endfunction


  // ---------------------------------------------------------------------------
  // CMP reference -- S7/S8/S9/S10
  // ---------------------------------------------------------------------------

  function automatic logic [31:0] cmp_ref(
    input logic [31:0] a,
    input logic [31:0] b,
    input logic [2:0]  mode
  );
    logic pred;

    pred = 1'b0;

    // S8/S9: every NaN comparison returns false.
    if (!(is_nan32(a) || is_nan32(b))) begin
      case (mode)
        3'd0:
          pred = fp_lt_ref(a, b) || fp_eq_ref(a, b); // <=

        3'd1:
          pred = fp_lt_ref(a, b);                    // <

        3'd2:
          pred = fp_eq_ref(a, b);                    // ==

        default:
          pred = 1'b0; // invalid modes are never driven
      endcase
    end

    // S7
    return pred ? 32'h0000_0001 : 32'h0000_0000;
  endfunction


  // ---------------------------------------------------------------------------
  // CLASSIFY reference -- S12
  // ---------------------------------------------------------------------------

  function automatic logic [9:0] classify_ref(
    input logic [31:0] x
  );
    logic [9:0] c;

    c = 10'b0;

    if (x[30:23] == 8'hff) begin

      if (x[22:0] == 23'h0) begin
        // Infinity
        if (x[31]) c[0] = 1'b1;
        else       c[7] = 1'b1;

      end else if (x[22]) begin
        // A3: quiet NaN
        c[9] = 1'b1;

      end else begin
        // A3: signalling NaN
        c[8] = 1'b1;
      end

    end else if (x[30:23] == 8'h00) begin

      if (x[22:0] == 23'h0) begin
        // Zero
        if (x[31]) c[3] = 1'b1;
        else       c[4] = 1'b1;

      end else begin
        // Subnormal
        if (x[31]) c[2] = 1'b1;
        else       c[5] = 1'b1;
      end

    end else begin

      // Normal
      if (x[31]) c[1] = 1'b1;
      else       c[6] = 1'b1;

    end

    return c;
  endfunction


  // ---------------------------------------------------------------------------
  // Expected-operation record
  //
  // result is checked only for SGNJ/MINMAX/CMP.
  // class_mask is checked only for CLASSIFY.
  //
  // That deliberately respects the named latitude in section 10.
  // ---------------------------------------------------------------------------

  typedef struct {
    logic [31:0] result;
    logic [9:0]  class_mask;

    logic        exp_nv;

    logic        check_result;
    logic        check_class;

    int unsigned seq_no;

    int          result_req;
    int          nv_req;
  } exp_rec_t;

  exp_rec_t exp_q[$];


  function automatic exp_rec_t make_expected(
    input logic [31:0] a,
    input logic [31:0] b,
    input logic [1:0]  op,
    input logic [2:0]  mode,
    input int unsigned seq_no
  );
    exp_rec_t e;
    logic nan_a;
    logic nan_b;
    logic snan_any;
    logic sign_bit;

    nan_a    = is_nan32(a);
    nan_b    = is_nan32(b);
    snan_any = is_snan32(a) || is_snan32(b);

    e.result       = 32'h0000_0000;
    e.class_mask   = 10'h000;
    e.exp_nv       = 1'b0;
    e.check_result = 1'b0;
    e.check_class  = 1'b0;
    e.seq_no       = seq_no;
    e.result_req   = 0;
    e.nv_req       = 14;

    sign_bit = 1'b0;

    case (op)

      // -----------------------------------------------------------------------
      // SGNJ -- S1/S2
      // -----------------------------------------------------------------------
      2'd0: begin

        case (mode)
          3'd0:
            sign_bit = b[31];

          3'd1:
            sign_bit = ~b[31];

          3'd2:
            sign_bit = a[31] ^ b[31];

          default:
            sign_bit = 1'b0; // never driven
        endcase

        // S1: preserve bits 30:0 exactly, including NaN payloads.
        e.result       = {sign_bit, a[30:0]};
        e.check_result = 1'b1;
        e.result_req   = 1;

        // S2
        e.exp_nv = 1'b0;
        e.nv_req = 2;
      end


      // -----------------------------------------------------------------------
      // MINMAX -- S3/S4/S5/S6
      // -----------------------------------------------------------------------
      2'd1: begin

        e.result       = minmax_ref(a, b, mode == 3'd1);
        e.check_result = 1'b1;

        if (nan_a && nan_b)
          e.result_req = 5;
        else if (nan_a || nan_b)
          e.result_req = 4;
        else
          e.result_req = 3;

        // S6
        e.exp_nv = snan_any;
        e.nv_req = 6;
      end


      // -----------------------------------------------------------------------
      // CMP -- S7/S8/S9/S10/S11
      // -----------------------------------------------------------------------
      2'd2: begin

        e.result       = cmp_ref(a, b, mode);
        e.check_result = 1'b1;

        if (nan_a || nan_b) begin
          if (mode == 3'd2)
            e.result_req = 9;
          else
            e.result_req = 8;

        end else if (is_zero32(a) && is_zero32(b)) begin
          e.result_req = 10;

        end else begin
          e.result_req = 7;
        end

        // FLE/FLT are signalling comparisons -- S8.
        // FEQ is a quiet comparison -- S9.
        if (mode == 3'd2) begin
          e.exp_nv = snan_any;

          if (nan_a || nan_b)
            e.nv_req = 9;
          else
            e.nv_req = 11;

        end else begin
          e.exp_nv = nan_a || nan_b;

          if (nan_a || nan_b)
            e.nv_req = 8;
          else
            e.nv_req = 11;
        end
      end


      // -----------------------------------------------------------------------
      // CLASSIFY -- S12/S13
      // -----------------------------------------------------------------------
      2'd3: begin

        e.class_mask  = classify_ref(a);
        e.check_class = 1'b1;

        // S13
        e.exp_nv = 1'b0;
        e.nv_req = 13;
      end

      default: begin
      end

    endcase

    return e;
  endfunction


  // ---------------------------------------------------------------------------
  // Deterministic pseudo-random generator
  // ---------------------------------------------------------------------------

  function automatic logic [31:0] prng_step(
    input logic [31:0] x
  );
    logic [31:0] y;

    y = x;
    y = y ^ (y << 13);
    y = y ^ (y >> 17);
    y = y ^ (y << 5);

    return y;
  endfunction


  // ---------------------------------------------------------------------------
  // Checker / scoreboard
  // ---------------------------------------------------------------------------

  integer      fail_count;
  int unsigned accepted_seq;

  logic        prev_rst_n;
  integer      reset_low_cycles;


  task automatic fail_req(
    input string req_name,
    input string detail
  );
    fail_count = fail_count + 1;
    $display("FAIL %s: %s", req_name, detail);
  endtask


  initial begin
    fail_count       = 0;
    accepted_seq     = 0;
    prev_rst_n       = 1'b0;
    reset_low_cycles = 0;
  end


  always @(posedge clk) begin
    automatic exp_rec_t e;
    automatic exp_rec_t new_e;

    if (!rst_n) begin

      // S15:
      // Any work accepted before reset is discarded.  Transactions accepted
      // during reset are also outside the post-reset scoreboard.
      exp_q.delete();

      // Synchronous reset means the state changes on the reset clock edge.
      // Therefore do not inspect pre-reset output state on the very first edge
      // where reset becomes active.  Starting with the next reset edge, the
      // DUT has already had a clock edge on which to enter idle.
      if (reset_low_cycles > 0) begin
        if (out_valid_o !== 1'b0) begin
          fail_req(
            "S15",
            "out_valid_o was not low while the DUT was held in synchronous reset"
          );
        end
      end

      reset_low_cycles = reset_low_cycles + 1;

    end else begin

      reset_low_cycles = 0;

      // S15: first cycle after reset release must have no output valid.
      //
      // No request is driven by this testbench on this first release cycle, so
      // skipping normal handshake bookkeeping here cannot hide a legal request.
      if (!prev_rst_n) begin

        if (out_valid_o !== 1'b0) begin
          fail_req(
            "S15",
            "out_valid_o was not low on the first cycle after reset release"
          );
        end

      end else begin

        // ---------------------------------------------------------------------
        // H1:
        // Create bookkeeping only for a real input handshake.
        // ---------------------------------------------------------------------
        if (in_valid_i && in_ready_o) begin

          new_e = make_expected(
            operand_a_i,
            operand_b_i,
            op_i,
            op_mode_i,
            accepted_seq
          );

          exp_q.push_back(new_e);

          accepted_seq = accepted_seq + 1;
        end


        // ---------------------------------------------------------------------
        // H2/H3:
        //
        // out_valid_o identifies the next result.  We compare against the
        // oldest accepted transaction.  We DO NOT pop it while out_ready_i=0,
        // so arbitrary output stalls are supported.
        //
        // This also accommodates zero-cycle/pass-through behavior: if an input
        // is accepted and a corresponding output is valid on the same edge,
        // the input was pushed immediately above before the output is checked.
        // ---------------------------------------------------------------------
        if (out_valid_o) begin

          if (exp_q.size() == 0) begin

            fail_req(
              "H2/H3",
              "spurious or duplicated output: no accepted operation is pending"
            );

          end else begin

            e = exp_q[0];


            // ---------------------------------------------------------------
            // result_o is specified for SGNJ/MINMAX/CMP only.
            // ---------------------------------------------------------------
            if (e.check_result && (result_o !== e.result)) begin

              if (e.result_req == 5) begin

                fail_req(
                  "S5/A2",
                  $sformatf(
                    "seq=%0d result exp=%08x got=%08x",
                    e.seq_no,
                    e.result,
                    result_o
                  )
                );

              end else begin

                fail_req(
                  $sformatf("S%0d", e.result_req),
                  $sformatf(
                    "seq=%0d result exp=%08x got=%08x (transaction ordering per H2)",
                    e.seq_no,
                    e.result,
                    result_o
                  )
                );

              end
            end


            // ---------------------------------------------------------------
            // class_mask_o is specified for CLASSIFY only -- S12.
            // ---------------------------------------------------------------
            if (e.check_class &&
                (class_mask_o !== e.class_mask)) begin

              fail_req(
                "S12",
                $sformatf(
                  "seq=%0d class exp=%03x got=%03x",
                  e.seq_no,
                  e.class_mask,
                  class_mask_o
                )
              );
            end


            // ---------------------------------------------------------------
            // NV semantics -- S2/S6/S8/S9/S11/S13.
            // ---------------------------------------------------------------
            if (status_o[4] !== e.exp_nv) begin

              fail_req(
                $sformatf("S%0d", e.nv_req),
                $sformatf(
                  "seq=%0d NV exp=%0b got=%0b status=%02x",
                  e.seq_no,
                  e.exp_nv,
                  status_o[4],
                  status_o
                )
              );
            end


            // ---------------------------------------------------------------
            // S14: DZ/OF/UF/NX are always zero.
            // ---------------------------------------------------------------
            if (status_o[3:0] !== 4'b0000) begin

              fail_req(
                "S14",
                $sformatf(
                  "seq=%0d DZ/OF/UF/NX must all be zero, status=%02x",
                  e.seq_no,
                  status_o
                )
              );
            end


            // ---------------------------------------------------------------
            // H2/H3:
            // Only a real output handshake consumes an entry.
            // ---------------------------------------------------------------
            if (out_ready_i) begin
              void'(exp_q.pop_front());
            end

          end
        end
      end
    end

    prev_rst_n = rst_n;
  end


  // ---------------------------------------------------------------------------
  // Stimulus helpers
  // ---------------------------------------------------------------------------

  logic [31:0] prng_state;


  task automatic run_pseudorandom(input int count);
    automatic int          k;
    automatic logic [31:0] a;
    automatic logic [31:0] b;
    automatic logic [1:0]  op_sel;
    automatic logic [2:0]  mode_sel;

    for (k = 0; k < count; k = k + 1) begin

      prng_state = prng_step(prng_state);
      a = prng_state;

      prng_state = prng_step(prng_state);
      b = prng_state;

      op_sel = k[1:0];

      case (op_sel)

        2'd0:
          mode_sel = prng_state % 3;

        2'd1:
          mode_sel = prng_state % 2;

        2'd2:
          mode_sel = prng_state % 3;

        default:
          // CLASSIFY: every op_mode is specified to be ignored.
          mode_sel = prng_state[2:0];

      endcase

      bfm_issue(a, b, op_sel, mode_sel);
    end

    // Important: do not leave the last transaction presented after its
    // acceptance while another fork branch continues running.
    bfm_idle();
  endtask


  // H3 stress.  No assumption is made that the DUT can accept inputs while
  // out_ready_i is low; a legal design may backpressure the input.
  task automatic ready_stress(input int rounds);
    automatic int k;

    for (k = 0; k < rounds; k = k + 1) begin

      bfm_out_ready(1'b0);
      repeat ((k % 7) + 1) @(posedge clk);

      bfm_out_ready(1'b1);
      repeat ((k % 5) + 1) @(posedge clk);

    end

    bfm_out_ready(1'b1);
  endtask


  // ---------------------------------------------------------------------------
  // Main stimulus
  // ---------------------------------------------------------------------------

  initial begin

    operand_a_i = 32'h0000_0000;
    operand_b_i = 32'h0000_0000;
    op_i        = 2'd0;
    op_mode_i   = 3'd0;
    in_valid_i  = 1'b0;
    out_ready_i = 1'b0;

    prng_state = 32'h1a2b_3c4d;


    // -------------------------------------------------------------------------
    // S15: initial synchronous reset.
    // -------------------------------------------------------------------------
    bfm_reset(4);

    bfm_out_ready(1'b1);

    repeat (2) @(posedge clk);


    // -------------------------------------------------------------------------
    // S15: reset with potentially in-flight work.
    //
    // If this DUT has nonzero latency, the operation accepted immediately
    // before reset can be in flight and must be discarded.  A legal zero-
    // latency implementation may already have delivered it, which is also fine.
    //
    // bfm_idle and reset both act on the same following falling edge but modify
    // different signals, so the source is withdrawn at the same time reset is
    // asserted, never on a sampling edge.
    // -------------------------------------------------------------------------
    bfm_issue(
      32'h3f80_0000,
      32'h8000_0000,
      2'd0,
      3'd0
    );

    fork

      begin
        bfm_idle();
      end

      begin
        bfm_reset(4);
      end

    join

    // No new transaction here: expose any stale result surviving reset.
    repeat (4) @(posedge clk);


    // =========================================================================
    // SGNJ -- S1/S2
    // =========================================================================

    // Copy sign of B.
    bfm_issue(
      32'h3f80_0001,
      32'h8000_0000,
      2'd0,
      3'd0
    );

    // Invert sign of B.
    bfm_issue(
      32'h3f80_0001,
      32'h8000_0000,
      2'd0,
      3'd1
    );

    // XOR signs.
    bfm_issue(
      32'hbf80_0001,
      32'h8000_0000,
      2'd0,
      3'd2
    );

    // S1/S2: signalling NaN payload must pass unchanged except sign and
    // must not raise NV.
    bfm_issue(
      32'h7fa1_2345,
      32'h8000_0000,
      2'd0,
      3'd0
    );

    // Quiet NaN payload, negative A.
    bfm_issue(
      32'hffc5_4321,
      32'h0000_0000,
      2'd0,
      3'd1
    );

    // Infinity.
    bfm_issue(
      32'h7f80_0000,
      32'h8000_0000,
      2'd0,
      3'd2
    );

    // Signed zero.
    bfm_issue(
      32'h8000_0000,
      32'h0000_0000,
      2'd0,
      3'd0
    );

    bfm_idle();


    // =========================================================================
    // MINMAX -- S3/S4/S5/S6/A2
    // =========================================================================

    // Ordinary positives.
    bfm_issue(
      32'h3f80_0000, // +1
      32'h4000_0000, // +2
      2'd1,
      3'd0
    );

    bfm_issue(
      32'h3f80_0000,
      32'h4000_0000,
      2'd1,
      3'd1
    );

    // Ordinary negatives.
    bfm_issue(
      32'hbf80_0000, // -1
      32'hc000_0000, // -2
      2'd1,
      3'd0
    );

    bfm_issue(
      32'hbf80_0000,
      32'hc000_0000,
      2'd1,
      3'd1
    );

    // Infinities.
    bfm_issue(
      32'hff80_0000,
      32'h7f80_0000,
      2'd1,
      3'd0
    );

    bfm_issue(
      32'hff80_0000,
      32'h7f80_0000,
      2'd1,
      3'd1
    );

    // S3: signed-zero ordering, both operand orders.
    bfm_issue(
      32'h8000_0000,
      32'h0000_0000,
      2'd1,
      3'd0
    );

    bfm_issue(
      32'h0000_0000,
      32'h8000_0000,
      2'd1,
      3'd0
    );

    bfm_issue(
      32'h8000_0000,
      32'h0000_0000,
      2'd1,
      3'd1
    );

    bfm_issue(
      32'h0000_0000,
      32'h8000_0000,
      2'd1,
      3'd1
    );

    // Positive subnormal/normal boundary.
    bfm_issue(
      32'h007f_ffff,
      32'h0080_0000,
      2'd1,
      3'd0
    );

    // Negative subnormal/normal boundary.
    bfm_issue(
      32'h807f_ffff,
      32'h8080_0000,
      2'd1,
      3'd0
    );

    // S4: one qNaN -- numeric operand must be returned.
    bfm_issue(
      32'h7fc1_2345,
      32'h3f80_0000,
      2'd1,
      3'd0
    );

    bfm_issue(
      32'h3f80_0000,
      32'hffc5_4321,
      2'd1,
      3'd1
    );

    // S4/S6: one sNaN -- numeric operand returned, NV set.
    bfm_issue(
      32'h7f81_2345,
      32'h4000_0000,
      2'd1,
      3'd0
    );

    bfm_issue(
      32'hc000_0000,
      32'hff81_2345,
      2'd1,
      3'd1
    );

    // S5/A2: both qNaN -> canonical qNaN.
    bfm_issue(
      32'h7fc1_2345,
      32'hffc5_4321,
      2'd1,
      3'd0
    );

    // S5/A2/S6: sNaN + qNaN -> canonical qNaN, NV.
    bfm_issue(
      32'h7f81_2345,
      32'h7fc5_4321,
      2'd1,
      3'd1
    );

    // Both signalling.
    bfm_issue(
      32'h7f81_2345,
      32'hff81_0001,
      2'd1,
      3'd0
    );

    bfm_idle();


    // =========================================================================
    // CMP -- S7/S8/S9/S10/S11
    // =========================================================================

    // +1 <= +2 : true
    bfm_issue(
      32'h3f80_0000,
      32'h4000_0000,
      2'd2,
      3'd0
    );

    // +1 < +2 : true
    bfm_issue(
      32'h3f80_0000,
      32'h4000_0000,
      2'd2,
      3'd1
    );

    // +1 == +2 : false
    bfm_issue(
      32'h3f80_0000,
      32'h4000_0000,
      2'd2,
      3'd2
    );

    // +2 <= +1 : false
    bfm_issue(
      32'h4000_0000,
      32'h3f80_0000,
      2'd2,
      3'd0
    );

    // Negative ordering.
    bfm_issue(
      32'hbf80_0000, // -1
      32'h8000_0001, // tiny negative
      2'd2,
      3'd1
    );

    // S10: -0 <= +0
    bfm_issue(
      32'h8000_0000,
      32'h0000_0000,
      2'd2,
      3'd0
    );

    // S10: -0 < +0 is false
    bfm_issue(
      32'h8000_0000,
      32'h0000_0000,
      2'd2,
      3'd1
    );

    // S10: -0 == +0
    bfm_issue(
      32'h8000_0000,
      32'h0000_0000,
      2'd2,
      3'd2
    );

    // Reverse zero order.
    bfm_issue(
      32'h0000_0000,
      32'h8000_0000,
      2'd2,
      3'd2
    );

    // -inf < +inf
    bfm_issue(
      32'hff80_0000,
      32'h7f80_0000,
      2'd2,
      3'd1
    );

    // +inf == +inf
    bfm_issue(
      32'h7f80_0000,
      32'h7f80_0000,
      2'd2,
      3'd2
    );


    // S8: FLE with qNaN -> false, NV=1.
    bfm_issue(
      32'h7fc1_2345,
      32'h3f80_0000,
      2'd2,
      3'd0
    );

    // S8: FLT with qNaN -> false, NV=1.
    bfm_issue(
      32'h3f80_0000,
      32'hffc5_4321,
      2'd2,
      3'd1
    );

    // S9: FEQ with qNaN -> false, NV=0.
    bfm_issue(
      32'h7fc1_2345,
      32'h3f80_0000,
      2'd2,
      3'd2
    );


    // S8: FLE with sNaN -> false, NV=1.
    bfm_issue(
      32'h7f81_2345,
      32'h3f80_0000,
      2'd2,
      3'd0
    );

    // S8: FLT with sNaN -> false, NV=1.
    bfm_issue(
      32'h3f80_0000,
      32'hff81_2345,
      2'd2,
      3'd1
    );

    // S9: FEQ with sNaN -> false, NV=1.
    bfm_issue(
      32'h7f81_2345,
      32'h3f80_0000,
      2'd2,
      3'd2
    );

    // FEQ qNaN vs sNaN -> false, NV=1 because one is signalling.
    bfm_issue(
      32'h7fc1_2345,
      32'hff81_2345,
      2'd2,
      3'd2
    );

    bfm_idle();


    // =========================================================================
    // CLASSIFY -- S12/S13
    //
    // operand_b is deliberately an sNaN in every case.  S12 says B is ignored,
    // and S13 says CLASSIFY raises no flags.
    //
    // op_mode_i is deliberately varied across its full three-bit range because
    // CLASSIFY explicitly ignores it.
    // =========================================================================

    // bit 0: -infinity
    bfm_issue(
      32'hff80_0000,
      32'h7f80_0001,
      2'd3,
      3'd0
    );

    // bit 1: -normal
    bfm_issue(
      32'hbf80_0000,
      32'h7f80_0001,
      2'd3,
      3'd1
    );

    // bit 2: -subnormal
    bfm_issue(
      32'h8000_0001,
      32'h7f80_0001,
      2'd3,
      3'd2
    );

    // bit 3: -zero
    bfm_issue(
      32'h8000_0000,
      32'h7f80_0001,
      2'd3,
      3'd3
    );

    // bit 4: +zero
    bfm_issue(
      32'h0000_0000,
      32'h7f80_0001,
      2'd3,
      3'd4
    );

    // bit 5: +subnormal
    bfm_issue(
      32'h0000_0001,
      32'h7f80_0001,
      2'd3,
      3'd5
    );

    // bit 6: +normal
    bfm_issue(
      32'h3f80_0000,
      32'h7f80_0001,
      2'd3,
      3'd6
    );

    // bit 7: +infinity
    bfm_issue(
      32'h7f80_0000,
      32'h7f80_0001,
      2'd3,
      3'd7
    );

    // bit 8: signalling NaN; sign is irrelevant to NaN class.
    bfm_issue(
      32'hff81_2345,
      32'h7f80_0001,
      2'd3,
      3'd5
    );

    // bit 9: quiet NaN.
    bfm_issue(
      32'hffc1_2345,
      32'h7f80_0001,
      2'd3,
      3'd2
    );

    bfm_idle();


    // =========================================================================
    // Broad deterministic coverage + H2/H3 backpressure
    //
    // The source BFM continues to satisfy H4: once valid is asserted, every
    // operation input remains stable until acceptance.
    // =========================================================================
    fork

      begin
        run_pseudorandom(320);
      end

      begin
        ready_stress(48);
      end

    join


    // -------------------------------------------------------------------------
    // Drain.
    //
    // Latency is deliberately not bounded.  out_ready is left asserted and the
    // scoreboard waits for every accepted operation.  S16's independent
    // watchdog is the only absolute time limit.
    // -------------------------------------------------------------------------
    bfm_out_ready(1'b1);

    while (exp_q.size() != 0) begin
      @(posedge clk);
    end


    // A short post-drain observation window catches immediate output
    // duplication/spurious-valid bugs after the final legal delivery.  It does
    // not impose any latency bound on a pending legal transaction because the
    // scoreboard was already empty before entering this window.
    repeat (8) @(posedge clk);

    // Finish on the opposite edge so the checker from the preceding posedge has
    // completed before fail_count is inspected.
    @(negedge clk);

    if (fail_count == 0) begin
      $display("RESULT: PASS");
    end else begin
      $display("RESULT: FAIL");
    end

    $finish;
  end

endmodule