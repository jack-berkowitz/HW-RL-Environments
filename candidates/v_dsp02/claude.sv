// ===========================================================================
// fp_noncomp_tb.sv
//
// Self-checking testbench for the fp_noncomp non-computational FP unit,
// written against the specification only.  Every check names the clause it
// decides.
//
// STRUCTURE
//   * One posedge monitor holds all the checking.  It samples the input
//     handshake and the output handshake at the edge the design uses, and it
//     folds an accepted operation into the model BEFORE it checks a delivered
//     result, so an implementation with zero latency (result in the same cycle
//     it accepts) is handled exactly like a deeply pipelined one (L1).
//   * Results are identified by bookkeeping -- a FIFO of predicted records in
//     acceptance order -- never by matching on payload, so repeated values
//     cannot mis-attribute (H2).
//   * Nothing the contract leaves open is checked: latency, in_ready_o
//     promptness, outputs while out_valid_o is low, result_o under CLASSIFY,
//     class_mask_o under anything else, unlisted op_mode_i values, and
//     internal structure (L1-L7) are all free.
//   * Every wait is bounded, so the run always reaches a verdict (S16).
//
// NOTE ON THE PROVIDED PLUMBING.  Clock, reset and watchdog are kept verbatim.
// bfm_issue is kept but wrapped: as shipped its acceptance loop is `forever`,
// which is exactly the hang S16 forbids against an implementation that never
// asserts in_ready_o, so `issue` below is the same task with a cycle budget.
// bfm_out_ready is left defined but never called -- out_ready_i is driven from
// a single mode-controlled negedge block, because two processes driving it
// from the same edge would race.
// ===========================================================================

module fp_noncomp_tb;

  // ---- operation encodings (§0) -------------------------------------------
  localparam logic [1:0] OP_SGNJ = 2'd0;
  localparam logic [1:0] OP_MINMAX = 2'd1;
  localparam logic [1:0] OP_CMP = 2'd2;
  localparam logic [1:0] OP_CLASSIFY = 2'd3;

  localparam logic [31:0] CANON_QNAN = 32'h7FC0_0000;   // A2
  localparam logic [4:0]  NV_ONLY = 5'b1_0000;          // S14 field order

  localparam int RN   = 2048;   // result-model ring depth
  localparam int NOPS = 24;     // curated operand count

  // ---- DUT signals ---------------------------------------------------------
  logic [31:0] operand_a_i, operand_b_i;
  logic [1:0]  op_i;
  logic [2:0]  op_mode_i;
  logic        in_valid_i, in_ready_o;
  logic [31:0] result_o;
  logic [9:0]  class_mask_o;
  logic [4:0]  status_o;
  logic        out_valid_o, out_ready_i;

  // ---------------------------------------------------------------------------
  // PROVIDED PLUMBING
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

  // Kept from the plumbing but never called; see the header note.
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

  // ---- device under test ---------------------------------------------------
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

  // ===========================================================================
  // VERDICT BOOKKEEPING
  // ===========================================================================
  int err_cnt = 0;
  int msg_cnt = 0;

  task automatic fail(input string req_id, input string msg);
    err_cnt = err_cnt + 1;
    if (msg_cnt < 50) begin
      msg_cnt = msg_cnt + 1;
      $display("FAIL [%s] t=%0t : %s", req_id, $time, msg);
    end
    if (err_cnt == 200) begin
      $display("STATS: stopping after %0d violations", err_cnt);
      $display("RESULT: FAIL");
      $finish;
    end
  endtask

  // ===========================================================================
  // THE REFERENCE MODEL
  // ===========================================================================
  function automatic bit f_is_nan (input logic [31:0] x);
    return (x[30:23] == 8'hFF) && (x[22:0] != 23'd0);          // A1
  endfunction
  function automatic bit f_is_snan(input logic [31:0] x);
    return f_is_nan(x) && (x[22] == 1'b0);                     // A3
  endfunction
  function automatic bit f_is_qnan(input logic [31:0] x);
    return f_is_nan(x) && (x[22] == 1'b1);                     // A3
  endfunction
  function automatic bit f_is_inf (input logic [31:0] x);
    return (x[30:23] == 8'hFF) && (x[22:0] == 23'd0);
  endfunction
  function automatic bit f_is_zero(input logic [31:0] x);
    return (x[30:0] == 31'd0);
  endfunction
  function automatic bit f_is_sub (input logic [31:0] x);
    return (x[30:23] == 8'd0) && (x[22:0] != 23'd0);
  endfunction

  // Ordering used by MINMAX (S3): magnitude order, negatives below positives,
  // and -0.0 strictly below +0.0 because the sign bits differ.
  function automatic bit f_lt_mm(input logic [31:0] a, input logic [31:0] b);
    if (a[31] != b[31]) return a[31];
    if (a[31] == 1'b0)  return (a[30:0] < b[30:0]);
    else                return (a[30:0] > b[30:0]);
  endfunction

  // Ordering used by CMP (S10): the two zeros compare equal.
  function automatic bit f_eq_num(input logic [31:0] a, input logic [31:0] b);
    if (f_is_zero(a) && f_is_zero(b)) return 1'b1;
    return (a == b);
  endfunction
  function automatic bit f_lt_num(input logic [31:0] a, input logic [31:0] b);
    if (f_is_zero(a) && f_is_zero(b)) return 1'b0;
    if (a[31] != b[31]) return a[31];
    if (a[31] == 1'b0)  return (a[30:0] < b[30:0]);
    else                return (a[30:0] > b[30:0]);
  endfunction

  // S12 bit assignment
  function automatic logic [9:0] f_class(input logic [31:0] x);
    if (f_is_snan(x)) return 10'b01_0000_0000;   // bit 8
    if (f_is_qnan(x)) return 10'b10_0000_0000;   // bit 9
    if (f_is_inf(x))  return x[31] ? 10'b00_0000_0001    // bit 0
                                   : 10'b00_1000_0000;   // bit 7
    if (f_is_zero(x)) return x[31] ? 10'b00_0000_1000    // bit 3
                                   : 10'b00_0001_0000;   // bit 4
    if (f_is_sub(x))  return x[31] ? 10'b00_0000_0100    // bit 2
                                   : 10'b00_0010_0000;   // bit 5
    return x[31] ? 10'b00_0000_0010                      // bit 1
                 : 10'b00_0100_0000;                     // bit 6
  endfunction

  typedef struct {
    logic [31:0] a;
    logic [31:0] b;
    logic [1:0]  op;
    logic [2:0]  mode;
    logic [31:0] res;
    logic [9:0]  cmask;
    logic [4:0]  st;
    bit          chk_res;
    bit          chk_cm;
    int          seq;
  } rec_t;

  task automatic predict(input  logic [31:0] a, input logic [31:0] b,
                         input  logic [1:0]  op, input logic [2:0] mode,
                         output logic [31:0] res, output logic [9:0] cm,
                         output logic [4:0]  st,
                         output bit chk_res, output bit chk_cm);
    automatic bit na = f_is_nan(a);
    automatic bit nb = f_is_nan(b);
    automatic bit sa = f_is_snan(a);
    automatic bit sb = f_is_snan(b);
    automatic logic sgn = 1'b0;
    res     = 32'd0;
    cm      = 10'd0;
    st      = 5'd0;
    chk_res = 1'b1;
    chk_cm  = 1'b0;
    case (op)
      OP_SGNJ: begin
        // S1: bits 30:0 of operand_a unchanged, NaN payloads included.
        case (mode)
          3'd0:    sgn = b[31];
          3'd1:    sgn = ~b[31];
          default: sgn = a[31] ^ b[31];
        endcase
        res = {sgn, a[30:0]};
        st  = 5'd0;                                   // S2
      end
      OP_MINMAX: begin
        if (na && nb)      res = CANON_QNAN;           // S5
        else if (na)       res = b;                    // S4
        else if (nb)       res = a;                    // S4
        else if (mode == 3'd0) res = f_lt_mm(a, b) ? a : b;   // S3 minimum
        else                   res = f_lt_mm(a, b) ? b : a;   // S3 maximum
        st = (sa || sb) ? NV_ONLY : 5'd0;              // S6
      end
      OP_CMP: begin
        if (mode == 3'd2) begin                        // S9 equal, quiet
          res = (na || nb) ? 32'd0 : (f_eq_num(a, b) ? 32'd1 : 32'd0);
          st  = (sa || sb) ? NV_ONLY : 5'd0;
        end else begin                                 // S8 le/lt, signalling
          if (na || nb) begin
            res = 32'd0;
            st  = NV_ONLY;
          end else begin
            if (mode == 3'd0) res = (f_lt_num(a, b) || f_eq_num(a, b)) ? 32'd1 : 32'd0;
            else              res = f_lt_num(a, b) ? 32'd1 : 32'd0;
            st  = 5'd0;
          end
        end
      end
      default: begin                                   // CLASSIFY
        cm      = f_class(a);                          // S12
        st      = 5'd0;                                // S13
        chk_res = 1'b0;                                // L4: result_o is free
        chk_cm  = 1'b1;
      end
    endcase
  endtask

  // Which clause a wrong result violates, for the diagnostic.
  function automatic string res_req(input rec_t e);
    case (e.op)
      OP_SGNJ:   return "S1";
      OP_MINMAX: begin
        if (f_is_nan(e.a) && f_is_nan(e.b)) return "S5";
        if (f_is_nan(e.a) || f_is_nan(e.b)) return "S4";
        if (f_is_zero(e.a) && f_is_zero(e.b)) return "S3";
        return "S3";
      end
      OP_CMP: begin
        if (f_is_nan(e.a) || f_is_nan(e.b)) return (e.mode == 3'd2) ? "S9" : "S8";
        if (f_is_zero(e.a) && f_is_zero(e.b)) return "S10";
        return "S7";
      end
      default: return "S12";
    endcase
  endfunction

  // Which clause a wrong NV violates.
  function automatic string nv_req(input rec_t e);
    case (e.op)
      OP_SGNJ:   return "S2";
      OP_MINMAX: return "S6";
      OP_CMP:    return (e.mode == 3'd2) ? "S9" : "S8";
      default:   return "S13";
    endcase
  endfunction

  function automatic string op_name(input rec_t e);
    case (e.op)
      OP_SGNJ:   return (e.mode == 3'd0) ? "SGNJ" : ((e.mode == 3'd1) ? "SGNJN" : "SGNJX");
      OP_MINMAX: return (e.mode == 3'd0) ? "MIN" : "MAX";
      OP_CMP:    return (e.mode == 3'd0) ? "LE" : ((e.mode == 3'd1) ? "LT" : "EQ");
      default:   return "CLASSIFY";
    endcase
  endfunction

  // ===========================================================================
  // RESULT MODEL -- a FIFO in acceptance order (H2)
  // ===========================================================================
  rec_t ring [RN];
  int   r_head = 0;      // next result expected
  int   r_tail = 0;      // next slot to fill
  int   n_acc  = 0;
  int   n_out  = 0;
  int   n_disc = 0;      // accepted, then correctly discarded by reset (S15)
  int   n_seq  = 0;

  bit  quiet_win = 1'b0;   // nothing may be delivered in this window (S15)
  logic rst_d = 1'b0;

  // ===========================================================================
  // OUR READINESS.  Single driver, mode-controlled, changed only at the
  // falling edge.  out_ready_i may be low whenever we like (H3).
  // ===========================================================================
  int unsigned lfsr = 32'h1ADE_5C0F;

  function automatic int unsigned rnd();
    lfsr = lfsr ^ (lfsr << 13);
    lfsr = lfsr ^ (lfsr >> 17);
    lfsr = lfsr ^ (lfsr << 5);
    return lfsr;
  endfunction

  // 0 = always ready, 1 = random, 2 = held low, 3 = long low stretches
  int or_mode = 0;
  int or_phase = 0;

  always @(negedge clk) begin
    automatic int unsigned r = rnd();
    or_phase = (or_phase + 1) % 32;
    case (or_mode)
      0:       out_ready_i = 1'b1;
      1:       out_ready_i = (r[0] | r[1]);      // ready ~75% of cycles
      3:       out_ready_i = (or_phase >= 26);   // low 26 cycles, high 6
      default: out_ready_i = 1'b0;
    endcase
  end

  // ===========================================================================
  // THE MONITOR
  // ===========================================================================
  always @(posedge clk) begin
    rst_d <= rst_n;
    if (!rst_n) begin
      // S15: reset returns the design to idle and discards work in flight.
      // Those operations are owed no result, so they are counted out of the
      // delivery tally rather than treated as lost.
      n_disc = n_disc + (r_tail - r_head);
      r_head = 0;
      r_tail = 0;
    end else begin
      // S15: out_valid_o is low on the first cycle after release.
      if (!rst_d && out_valid_o !== 1'b0)
        fail("S15", "out_valid_o is high on the first cycle after reset release");

      // S15: nothing accepted before or during reset may be delivered after it.
      if (quiet_win && out_valid_o === 1'b1)
        fail("S15", "a result appeared after reset for an operation accepted before it");

      // ---- H1: an operation is accepted here -----------------------------
      if (in_valid_i === 1'b1 && in_ready_o === 1'b1) begin
        automatic rec_t e;
        e.a    = operand_a_i;
        e.b    = operand_b_i;
        e.op   = op_i;
        e.mode = op_mode_i;
        e.seq  = n_seq;
        predict(e.a, e.b, e.op, e.mode, e.res, e.cmask, e.st, e.chk_res, e.chk_cm);
        if ((r_tail - r_head) >= RN) begin
          fail("H3", "more operations are outstanding than the model can hold");
        end else begin
          ring[r_tail % RN] = e;
          r_tail = r_tail + 1;
        end
        n_acc = n_acc + 1;
        n_seq = n_seq + 1;
      end

      // ---- H2: a result is delivered here --------------------------------
      if (out_valid_o === 1'b1 && out_ready_i === 1'b1) begin
        if (r_head == r_tail) begin
          fail("H3", "a result was delivered with no operation outstanding (duplicated or invented)");
        end else begin
          automatic rec_t e = ring[r_head % RN];
          r_head = r_head + 1;
          n_out  = n_out + 1;
          // result_o -- checked for every operation except CLASSIFY (L4)
          if (e.chk_res && result_o !== e.res)
            fail(res_req(e), $sformatf("%s(a=%08h,b=%08h): result_o=%08h, expected %08h",
                                       op_name(e), e.a, e.b, result_o, e.res));
          // class_mask_o -- checked only for CLASSIFY (L5)
          if (e.chk_cm && class_mask_o !== e.cmask)
            fail("S12", $sformatf("CLASSIFY(a=%08h): class_mask_o=%010b, expected %010b",
                                  e.a, class_mask_o, e.cmask));
          // status_o -- S14 pins the four non-NV flags off for every operation
          if (status_o[3:0] !== 4'b0000)
            fail("S14", $sformatf("%s(a=%08h,b=%08h): status_o=%05b, DZ/OF/UF/NX must all be zero",
                                  op_name(e), e.a, e.b, status_o));
          if (status_o[4] !== e.st[4])
            fail(nv_req(e), $sformatf("%s(a=%08h,b=%08h): NV=%0b, expected %0b",
                                      op_name(e), e.a, e.b, status_o[4], e.st[4]));
        end
      end
    end
  end

  // ===========================================================================
  // STIMULUS HELPERS
  // ===========================================================================
  int timeouts = 0;

  function automatic int issue_budget();
    return (timeouts >= 2) ? 64 : 8000;    // the fault is established; keep moving
  endfunction

  // bfm_issue with a bound (S16).  L3 says in_ready_o may be low for any
  // reason, so the budget is generous; only never-accepting is a failure.
  task automatic issue(input logic [31:0] a, input logic [31:0] b,
                       input logic [1:0] op, input logic [2:0] mode);
    automatic int w = 0;
    automatic bit acc = 1'b0;
    automatic int budg = issue_budget();
    @(negedge clk);
    operand_a_i = a;
    operand_b_i = b;
    op_i        = op;
    op_mode_i   = mode;
    in_valid_i  = 1'b1;                    // H4: held stable until accepted
    while (w < budg) begin
      @(posedge clk);
      if (in_ready_o === 1'b1) begin acc = 1'b1; break; end
      w = w + 1;
    end
    if (!acc) begin
      timeouts = timeouts + 1;
      fail("H1", $sformatf("operation op=%0d mode=%0d was offered for %0d cycles and never accepted",
                           op, mode, budg));
      @(negedge clk);
      in_valid_i = 1'b0;
    end
  endtask

  // Offer an operation but accept a refusal: used only where the output side is
  // deliberately stalled, since L3 permits in_ready_o to be low for any reason.
  task automatic try_issue(input logic [31:0] a, input logic [31:0] b,
                           input logic [1:0] op, input logic [2:0] mode,
                           input int budg, output bit accepted);
    automatic int w = 0;
    accepted = 1'b0;
    @(negedge clk);
    operand_a_i = a;
    operand_b_i = b;
    op_i        = op;
    op_mode_i   = mode;
    in_valid_i  = 1'b1;                    // H4: held stable while offered
    while (w < budg) begin
      @(posedge clk);
      if (in_ready_o === 1'b1) begin accepted = 1'b1; break; end
      w = w + 1;
    end
    if (!accepted) begin
      @(negedge clk);
      in_valid_i = 1'b0;
    end
  endtask

  task automatic idle_cycles(input int n);
    @(negedge clk);
    in_valid_i = 1'b0;
    repeat (n) @(posedge clk);
  endtask

  // Wait for every accepted operation to be delivered.  Bounded (S16).
  task automatic drain(input string ctx);
    automatic int i;
    automatic int budg = (timeouts >= 2) ? 200 : 20000;
    @(negedge clk);
    in_valid_i = 1'b0;
    or_mode = 0;
    for (i = 0; i < budg; i++) begin
      @(posedge clk);
      if (r_head == r_tail) break;
    end
    if (r_head != r_tail) begin
      timeouts = timeouts + 1;
      fail("H2", $sformatf("%s: %0d accepted operations never produced a result", ctx, r_tail - r_head));
      r_head = r_tail;                       // abandon them and keep going
    end
  endtask

  // ---- curated operands ----------------------------------------------------
  function automatic logic [31:0] opv(input int i);
    case (i)
      0:  return 32'h0000_0000;   // +0
      1:  return 32'h8000_0000;   // -0
      2:  return 32'h3F80_0000;   // +1.0
      3:  return 32'hBF80_0000;   // -1.0
      4:  return 32'h4000_0000;   // +2.0
      5:  return 32'hC000_0000;   // -2.0
      6:  return 32'h3F00_0000;   // +0.5
      7:  return 32'hBF00_0000;   // -0.5
      8:  return 32'h7F80_0000;   // +inf
      9:  return 32'hFF80_0000;   // -inf
      10: return 32'h0000_0001;   // +smallest subnormal
      11: return 32'h8000_0001;   // -smallest subnormal
      12: return 32'h007F_FFFF;   // +largest subnormal
      13: return 32'h807F_FFFF;   // -largest subnormal
      14: return 32'h0080_0000;   // +smallest normal
      15: return 32'h8080_0000;   // -smallest normal
      16: return 32'h7F7F_FFFF;   // +largest normal
      17: return 32'hFF7F_FFFF;   // -largest normal
      18: return 32'h7FC0_0000;   // canonical qNaN
      19: return 32'h7FD5_5555;   // qNaN, other payload
      20: return 32'hFFC0_0001;   // negative qNaN
      21: return 32'h7F80_0001;   // sNaN, smallest payload
      22: return 32'h7FBF_FFFF;   // sNaN, largest payload
      default: return 32'hFF80_0001; // negative sNaN
    endcase
  endfunction

  function automatic logic [31:0] rand_operand();
    automatic int unsigned r1 = rnd();
    automatic int unsigned r2 = rnd();
    case (r1[1:0])
      2'd0:    return opv(int'(r1[9:4]) % NOPS);
      2'd1:    return r2;                                 // anything at all
      2'd2:    return {r2[31], 8'hFF, r2[22:0]};          // inf or a NaN
      default: return {r2[31], 8'd0, r2[22:0]};           // zero or subnormal
    endcase
  endfunction

  // op/mode pairs the contract defines (§0); nothing else is ever driven (L6).
  function automatic logic [1:0] combo_op(input int k);
    case (k)
      0,1,2:   return OP_SGNJ;
      3,4:     return OP_MINMAX;
      5,6,7:   return OP_CMP;
      default: return OP_CLASSIFY;
    endcase
  endfunction
  function automatic logic [2:0] combo_mode(input int k);
    case (k)
      0: return 3'd0; 1: return 3'd1; 2: return 3'd2;
      3: return 3'd0; 4: return 3'd1;
      5: return 3'd0; 6: return 3'd1; 7: return 3'd2;
      default: return 3'd0;
    endcase
  endfunction
  localparam int NCOMBO = 9;

  // ===========================================================================
  // THE RUN
  // ===========================================================================
  initial begin
    automatic int k;
    automatic int ia;
    automatic int ib;

    operand_a_i = 32'd0;
    operand_b_i = 32'd0;
    op_i        = 2'd0;
    op_mode_i   = 3'd0;
    in_valid_i  = 1'b0;
    or_mode     = 0;

    // ---- S15: reset, and idle immediately after release -------------------
    bfm_reset(6);
    quiet_win = 1'b1;
    repeat (12) @(posedge clk);
    @(negedge clk);
    quiet_win = 1'b0;

    // ---- every defined op/mode over every pair of curated operands --------
    // out_ready_i high throughout, issue back to back.
    for (ia = 0; ia < NOPS; ia++)
      for (ib = 0; ib < NOPS; ib++)
        for (k = 0; k < NCOMBO; k++)
          issue(opv(ia), opv(ib), combo_op(k), combo_mode(k));
    drain("curated cross product, no backpressure");

    // ---- H3: the same traffic under random backpressure and issue gaps ----
    or_mode = 1;
    for (ia = 0; ia < NOPS; ia++) begin
      for (ib = 0; ib < NOPS; ib++)
        for (k = 0; k < NCOMBO; k++)
          issue(opv(ia), opv(ib), combo_op(k), combo_mode(k));
      if (ia % 5 == 0) idle_cycles(3);
    end
    drain("curated cross product, random backpressure");

    // ---- H3: long stretches with out_ready_i low --------------------------
    // The stretches end, so acceptance is never required while stalled (L3);
    // what is required is that nothing is lost, duplicated or reordered.
    or_mode = 3;
    for (k = 0; k < 60; k++)
      issue(rand_operand(), rand_operand(), combo_op(k % NCOMBO), combo_mode(k % NCOMBO));
    idle_cycles(30);
    drain("results released after long stalls");

    // ---- randomised traffic ----------------------------------------------
    or_mode = 1;
    for (k = 0; k < 3000; k++) begin
      automatic int unsigned r = rnd();
      automatic int c = int'(r[7:4]) % NCOMBO;
      issue(rand_operand(), rand_operand(), combo_op(c), combo_mode(c));
      if (r[11:8] == 4'd0) idle_cycles(2);
    end
    drain("randomised traffic");

    // ---- S15: reset with operations in flight -----------------------------
    or_mode = 3;                            // let some work in, then stall it
    for (k = 0; k < 12; k++) begin
      automatic bit got;
      try_issue(opv(k % NOPS), opv((k + 7) % NOPS), combo_op(k % NCOMBO), combo_mode(k % NCOMBO), 400, got);
    end
    or_mode = 2;                            // now hold the output blocked
    @(negedge clk);
    in_valid_i = 1'b0;
    repeat (6) @(posedge clk);
    bfm_reset(6);                           // discard everything in flight
    or_mode   = 0;                          // and now accept anything offered
    quiet_win = 1'b1;
    repeat (40) @(posedge clk);             // nothing may appear
    @(negedge clk);
    quiet_win = 1'b0;

    // ---- the unit still works afterwards ---------------------------------
    for (ia = 0; ia < NOPS; ia++)
      for (k = 0; k < NCOMBO; k++)
        issue(opv(ia), opv((ia + 3) % NOPS), combo_op(k), combo_mode(k));
    drain("after reset");

    // ---- H3: nothing lost or duplicated across the whole run --------------
    if (n_acc != n_out + n_disc)
      fail("H3", $sformatf("%0d operations were accepted, %0d results delivered, %0d discarded by reset: %0d unaccounted for",
                           n_acc, n_out, n_disc, n_acc - n_out - n_disc));

    // ---- verdict ----------------------------------------------------------
    $display("STATS: %0d operations accepted, %0d results checked, %0d discarded by reset, %0d violations",
             n_acc, n_out, n_disc, err_cnt);
    if (n_out == 0)
      fail("H2", "no result was ever delivered");
    if (err_cnt == 0) $display("RESULT: PASS");
    else              $display("RESULT: FAIL");
    $finish;
  end

endmodule