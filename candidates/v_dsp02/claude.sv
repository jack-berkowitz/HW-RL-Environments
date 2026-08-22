// ===========================================================================
//  fp_noncomp_tb -- specification-driven testbench for fp_noncomp
//
//  Checks A1-A3, S1-S16, H1-H4.  Deliberately blind to every item of named
//  latitude in section 10: latency, the output pins while out_valid_o is low,
//  the promptness of in_ready_o, result_o under CLASSIFY, class_mask_o under
//  anything else, unlisted op_mode_i values, and internal structure.
// ===========================================================================
module fp_noncomp_tb;

  // ---- design-under-test pins ---------------------------------------------
  logic [31:0] operand_a_i, operand_b_i;
  logic [1:0]  op_i;
  logic [2:0]  op_mode_i;
  logic        in_valid_i, in_ready_o;
  logic [31:0] result_o;
  logic [9:0]  class_mask_o;
  logic [4:0]  status_o;
  logic        out_valid_o, out_ready_i;

  // -------------------------------------------------------------------------
  // PROVIDED PLUMBING -- issues operations, checks nothing.
  // -------------------------------------------------------------------------

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

  // ---- watchdog (S16) --------------------------------------------------------
  initial begin
    #200_000_000;
    $display("RESULT: FAIL (watchdog: no forward progress)");
    $finish;
  end

  // -------------------------------------------------------------------------
  //  Instance
  // -------------------------------------------------------------------------
  fp_noncomp dut (
    .clk_i(clk), .rst_ni(rst_n),
    .operand_a_i(operand_a_i), .operand_b_i(operand_b_i),
    .op_i(op_i), .op_mode_i(op_mode_i),
    .in_valid_i(in_valid_i), .in_ready_o(in_ready_o),
    .result_o(result_o), .class_mask_o(class_mask_o), .status_o(status_o),
    .out_valid_o(out_valid_o), .out_ready_i(out_ready_i)
  );

  // -------------------------------------------------------------------------
  //  Operation encoding (section 0)
  // -------------------------------------------------------------------------
  localparam logic [1:0] OP_SGNJ   = 2'd0;
  localparam logic [1:0] OP_MINMAX = 2'd1;
  localparam logic [1:0] OP_CMP    = 2'd2;
  localparam logic [1:0] OP_CLASS  = 2'd3;

  localparam logic [31:0] CANON_QNAN = 32'h7FC0_0000;   // A2

  // -------------------------------------------------------------------------
  //  Format predicates (A1, A3)
  // -------------------------------------------------------------------------
  function automatic bit f_is_nan (input logic [31:0] x);
    return (x[30:23] == 8'hFF) && (x[22:0] != 23'd0);
  endfunction
  function automatic bit f_is_snan(input logic [31:0] x);
    return f_is_nan(x) && (x[22] == 1'b0);
  endfunction
  function automatic bit f_is_inf (input logic [31:0] x);
    return (x[30:23] == 8'hFF) && (x[22:0] == 23'd0);
  endfunction
  function automatic bit f_is_zero(input logic [31:0] x);
    return (x[30:23] == 8'h00) && (x[22:0] == 23'd0);
  endfunction
  function automatic bit f_is_sub (input logic [31:0] x);
    return (x[30:23] == 8'h00) && (x[22:0] != 23'd0);
  endfunction

  // Ordering used by MINMAX (S3): the IEEE ordering, except that -0.0 sits
  // below +0.0.  Both arguments must be non-NaN.
  function automatic bit f_lt_mm(input logic [31:0] a, input logic [31:0] b);
    if (a[31] != b[31]) return a[31];          // negative side is the lesser
    if (a[31])          return (a[30:0] > b[30:0]);
    return (a[30:0] < b[30:0]);
  endfunction

  // Ordering used by CMP (S10): the two zeros compare equal.
  function automatic bit f_lt_cmp(input logic [31:0] a, input logic [31:0] b);
    if (f_is_zero(a) && f_is_zero(b)) return 1'b0;
    return f_lt_mm(a, b);
  endfunction
  function automatic bit f_eq_cmp(input logic [31:0] a, input logic [31:0] b);
    if (f_is_zero(a) && f_is_zero(b)) return 1'b1;
    return (a == b);
  endfunction

  // S12
  function automatic logic [9:0] f_class(input logic [31:0] x);
    logic [9:0] m;
    m = 10'd0;
    if (f_is_nan(x))       m[f_is_snan(x) ? 8 : 9] = 1'b1;
    else if (f_is_inf(x))  m[x[31] ? 0 : 7]        = 1'b1;
    else if (f_is_zero(x)) m[x[31] ? 3 : 4]        = 1'b1;
    else if (f_is_sub(x))  m[x[31] ? 2 : 5]        = 1'b1;
    else                   m[x[31] ? 1 : 6]        = 1'b1;
    return m;
  endfunction

  // -------------------------------------------------------------------------
  //  The reference model.  rc / sc carry the requirement number that the
  //  result field and the flag field are owed to, so a mismatch can name it.
  // -------------------------------------------------------------------------
  typedef struct packed {
    logic [31:0] res;
    logic [9:0]  cmask;
    logic [4:0]  st;
    logic [31:0] a;
    logic [31:0] b;
    logic [1:0]  op;
    logic [2:0]  mode;
    logic [7:0]  rc;
    logic [7:0]  sc;
  } rec_t;

  function automatic string clause_name(input logic [7:0] c);
    case (c)
      8'd1:  return "S1";   8'd2:  return "S2";   8'd3:  return "S3";
      8'd4:  return "S4";   8'd5:  return "S5";   8'd6:  return "S6";
      8'd7:  return "S7";   8'd8:  return "S8";   8'd9:  return "S9";
      8'd10: return "S10";  8'd11: return "S11";  8'd12: return "S12";
      8'd13: return "S13";  default: return "S14";
    endcase
  endfunction

  function automatic string op_name(input logic [1:0] op, input logic [2:0] mode);
    case (op)
      OP_SGNJ:   return (mode == 3'd0) ? "SGNJ" : ((mode == 3'd1) ? "SGNJN" : "SGNJX");
      OP_MINMAX: return (mode == 3'd0) ? "MIN"  : "MAX";
      OP_CMP:    return (mode == 3'd0) ? "LE"   : ((mode == 3'd1) ? "LT" : "EQ");
      default:   return "CLASSIFY";
    endcase
  endfunction

  function automatic rec_t f_predict(input logic [31:0] a, input logic [31:0] b,
                                     input logic [1:0]  op, input logic [2:0] mode);
    rec_t r;
    bit   anan, bnan, asn, bsn;
    r.res   = 32'd0;
    r.cmask = 10'd0;
    r.st    = 5'd0;
    r.a     = a;
    r.b     = b;
    r.op    = op;
    r.mode  = mode;
    r.rc    = 8'd0;
    r.sc    = 8'd0;
    anan = f_is_nan(a);  bnan = f_is_nan(b);
    asn  = f_is_snan(a); bsn  = f_is_snan(b);

    case (op)
      // ---- SGNJ: bits 30:0 straight through, NaN payloads untouched -------
      OP_SGNJ: begin
        r.res[30:0] = a[30:0];
        case (mode)
          3'd0:    r.res[31] = b[31];
          3'd1:    r.res[31] = ~b[31];
          default: r.res[31] = a[31] ^ b[31];
        endcase
        r.st = 5'd0;                                     // S2
        r.rc = 8'd1;
        r.sc = 8'd2;
      end

      // ---- MINMAX: IEEE 754-2008 minNum/maxNum, -0.0 below +0.0 -----------
      OP_MINMAX: begin
        if (anan && bnan) begin
          r.res = CANON_QNAN;                            // S5
          r.rc  = 8'd5;
        end else if (anan) begin
          r.res = b;                                     // S4
          r.rc  = 8'd4;
        end else if (bnan) begin
          r.res = a;                                     // S4
          r.rc  = 8'd4;
        end else begin
          r.res = (mode == 3'd0) ? (f_lt_mm(a, b) ? a : b)   // S3
                                 : (f_lt_mm(a, b) ? b : a);
          r.rc  = 8'd3;
        end
        r.st = (asn || bsn) ? 5'b10000 : 5'b00000;       // S6
        r.sc = 8'd6;
      end

      // ---- CMP ------------------------------------------------------------
      OP_CMP: begin
        if (anan || bnan) begin
          r.res = 32'd0;
          if (mode == 3'd2) begin
            r.st = (asn || bsn) ? 5'b10000 : 5'b00000;   // S9, quiet compare
            r.rc = 8'd9;
            r.sc = 8'd9;
          end else begin
            r.st = 5'b10000;                             // S8, signalling
            r.rc = 8'd8;
            r.sc = 8'd8;
          end
        end else begin
          case (mode)
            3'd0:    r.res = (f_lt_cmp(a, b) || f_eq_cmp(a, b)) ? 32'd1 : 32'd0;
            3'd1:    r.res = f_lt_cmp(a, b)                     ? 32'd1 : 32'd0;
            default: r.res = f_eq_cmp(a, b)                     ? 32'd1 : 32'd0;
          endcase
          r.st = 5'd0;                                   // S11
          r.rc = (f_is_zero(a) && f_is_zero(b)) ? 8'd10 : 8'd7;
          r.sc = 8'd11;
        end
      end

      // ---- CLASSIFY -------------------------------------------------------
      default: begin
        r.cmask = f_class(a);                            // S12
        r.st    = 5'd0;                                  // S13
        r.rc    = 8'd12;
        r.sc    = 8'd13;
      end
    endcase
    return r;
  endfunction

  // =========================================================================
  //  Scoreboard
  // =========================================================================
  rec_t q [$];
  int   issued    = 0;
  int   delivered = 0;
  int   err_cnt   = 0;
  bit   sb_en        = 1'b1;   // record and check
  bit   expect_quiet = 1'b0;   // S15 window: nothing may come out at all

  task automatic flag(input string cl, input string msg);
    err_cnt = err_cnt + 1;
    if (err_cnt <= 25) $display("[%0t] FAIL %s: %s", $time, cl, msg);
    if (err_cnt == 25) $display("(further diagnostics suppressed)");
    if (err_cnt >= 200) begin
      $display("RESULT: FAIL");
      $finish;
    end
  endtask

  // The verdict is always the strict FIFO comparison below -- H2 leaves no tag
  // on the result with which it could be anything else.  This is only a hint
  // added to the diagnostic when the outputs happen to match the operation
  // AFTER the one that was due, which is what a reordering looks like.
  function automatic string order_hint();
    rec_t nx;
    if (q.size() == 0) return "";
    nx = q[0];
    if ((nx.op != OP_CLASS) && (result_o === nx.res) && (status_o === nx.st))
      return " -- these outputs match the NEXT operation, so results may be out of order (H2)";
    if ((nx.op == OP_CLASS) && (class_mask_o === nx.cmask) && (status_o === nx.st))
      return " -- these outputs match the NEXT operation, so results may be out of order (H2)";
    return "";
  endfunction

  task automatic check_result(input rec_t e);
    // ---- result_o -------------------------------------------------------
    // Not checked for CLASSIFY: section 10.4 leaves it unconstrained there.
    if (e.op != OP_CLASS) begin
      if ((e.op == OP_CMP) && (result_o[31:1] !== 31'd0))
        flag("S7", $sformatf(
          "%s(%08h,%08h): bits 31:1 of result_o must be zero, got %08h",
          op_name(e.op, e.mode), e.a, e.b, result_o));
      else if (result_o !== e.res)
        flag(clause_name(e.rc), $sformatf(
          "%s(%08h,%08h): expected result_o=%08h, got %08h%s",
          op_name(e.op, e.mode), e.a, e.b, e.res, result_o, order_hint()));
    end

    // ---- class_mask_o ---------------------------------------------------
    // Only meaningful for CLASSIFY: section 10.5 leaves it unconstrained
    // for every other operation.
    if (e.op == OP_CLASS) begin
      if (class_mask_o !== e.cmask)
        flag("S12", $sformatf(
          "CLASSIFY(%08h): expected class_mask_o=%010b, got %010b%s",
          e.a, e.cmask, class_mask_o, order_hint()));
      else if ($countones(class_mask_o) != 1)
        flag("S12", $sformatf(
          "CLASSIFY(%08h): class_mask_o must be one-hot, got %010b",
          e.a, class_mask_o));
    end

    // ---- status_o -------------------------------------------------------
    if (status_o[3:0] !== 4'd0)
      flag("S14", $sformatf(
        "%s(%08h,%08h): DZ/OF/UF/NX must be zero for every operation in this contract, status_o=%05b",
        op_name(e.op, e.mode), e.a, e.b, status_o));
    else if (status_o[4] !== e.st[4])
      flag(clause_name(e.sc), $sformatf(
        "%s(%08h,%08h): expected NV=%0b, got %0b",
        op_name(e.op, e.mode), e.a, e.b, e.st[4], status_o[4]));
  endtask

  // Sampled AT the rising edge: these are the values the design itself used.
  // Acceptance is handled before delivery so that a zero-latency design, which
  // may do both on one edge, is scored in the right order.
  always @(posedge clk) begin
    automatic rec_t e;
    if (rst_n) begin
      if (sb_en && in_valid_i && in_ready_o) begin
        q.push_back(f_predict(operand_a_i, operand_b_i, op_i, op_mode_i));
        issued = issued + 1;
      end
      if (expect_quiet && out_valid_o)
        flag("S15", "out_valid_o is asserted after reset, but no operation accepted before or during reset may produce a result");
      if (sb_en && out_valid_o && out_ready_i) begin
        delivered = delivered + 1;
        if (q.size() == 0)
          flag("H2", "a result was delivered while no operation was outstanding (a result was duplicated or invented)");
        else begin
          e = q.pop_front();
          check_result(e);
        end
      end
    end
  end

  // =========================================================================
  //  Result-side ready.  Driven from one process only, at the falling edge,
  //  the opposite edge from the one that samples it.  Every mode guarantees
  //  forward progress, so no stimulus can deadlock against backpressure.
  // =========================================================================
  int rdy_mode = 0;
  int rdy_tick = 0;

  initial begin
    out_ready_i = 1'b1;
    forever begin
      @(negedge clk);
      rdy_tick = rdy_tick + 1;
      case (rdy_mode)
        0:       out_ready_i = 1'b1;                       // always ready
        1:       out_ready_i = ($urandom_range(0, 2) != 0);// ~2/3 of cycles
        2:       out_ready_i = ((rdy_tick % 12) == 0);     // one cycle in 12
        3:       out_ready_i = ((rdy_tick % 40) < 4);      // long stalls
        default: out_ready_i = 1'b1;
      endcase
    end
  end

  // =========================================================================
  //  Stimulus
  // =========================================================================
  localparam int NVEC = 28;
  logic [31:0] vec [NVEC];

  task automatic load_vectors();
    vec[0]  = 32'h0000_0000;   // +0
    vec[1]  = 32'h8000_0000;   // -0
    vec[2]  = 32'h0000_0001;   // + smallest subnormal
    vec[3]  = 32'h8000_0001;   // - smallest subnormal
    vec[4]  = 32'h007F_FFFF;   // + largest subnormal
    vec[5]  = 32'h807F_FFFF;   // - largest subnormal
    vec[6]  = 32'h0080_0000;   // + smallest normal
    vec[7]  = 32'h8080_0000;   // - smallest normal
    vec[8]  = 32'h3F80_0000;   // +1.0
    vec[9]  = 32'hBF80_0000;   // -1.0
    vec[10] = 32'h4000_0000;   // +2.0
    vec[11] = 32'hC000_0000;   // -2.0
    vec[12] = 32'h3F00_0000;   // +0.5
    vec[13] = 32'hBF00_0000;   // -0.5
    vec[14] = 32'h7F7F_FFFF;   // + largest normal
    vec[15] = 32'hFF7F_FFFF;   // - largest normal
    vec[16] = 32'h7F80_0000;   // +inf
    vec[17] = 32'hFF80_0000;   // -inf
    vec[18] = 32'h7FC0_0000;   // canonical qNaN
    vec[19] = 32'h7FC1_2345;   // qNaN, other payload
    vec[20] = 32'hFFC0_0001;   // qNaN, sign set
    vec[21] = 32'h7F80_0001;   // sNaN, minimal payload
    vec[22] = 32'h7FA5_A5A5;   // sNaN, other payload
    vec[23] = 32'hFF80_0001;   // sNaN, sign set
    vec[24] = 32'h4049_0FDB;   // +pi
    vec[25] = 32'hC049_0FDB;   // -pi
    vec[26] = 32'h006C_E3EE;   // + mid subnormal
    vec[27] = 32'h449A_5000;   // +1234.5
  endtask

  // Issue with a bound, so that a design which simply never accepts ends the
  // run with a verdict instead of leaning on the watchdog (S16).  The bound is
  // deliberately far larger than any plausible latency, because section 10.3
  // leaves the promptness of in_ready_o unconstrained.
  task automatic do_issue(input logic [31:0] a, input logic [31:0] b,
                          input logic [1:0]  op, input logic [2:0] mode);
    int guard;
    guard = 0;
    @(negedge clk);
    operand_a_i = a;
    operand_b_i = b;
    op_i        = op;
    op_mode_i   = mode;
    in_valid_i  = 1'b1;
    forever begin
      @(posedge clk);
      if (in_ready_o) break;
      guard = guard + 1;
      if (guard > 20000) begin
        flag("H1", "in_ready_o has stayed low for 20000 cycles with in_valid_i held; the design is not accepting operations");
        $display("RESULT: FAIL");
        $finish;
      end
    end
  endtask

  task automatic drain(input int max_cycles);
    int guard;
    guard = 0;
    bfm_idle();
    rdy_mode = 0;
    while ((q.size() > 0) && (guard < max_cycles)) begin
      @(posedge clk);
      guard = guard + 1;
    end
    if (q.size() > 0) begin
      flag("H2", $sformatf(
        "%0d accepted operation(s) never produced a result after %0d idle cycles",
        q.size(), max_cycles));
      $display("RESULT: FAIL");
      $finish;
    end
  endtask

  function automatic logic [31:0] rnd_operand();
    int          s;
    logic [31:0] t;
    s = $urandom_range(0, 3);
    t = $urandom();
    case (s)
      0:       return vec[$urandom_range(0, NVEC-1)];
      1:       return t;
      2:       return {t[31], 8'hFF, (t[22:0] == 23'd0) ? 23'd1 : t[22:0]};  // NaN
      default: return {t[31], 8'h00, t[22:0]};                               // zero/subnormal
    endcase
  endfunction

  task automatic rnd_opmode(output logic [1:0] op, output logic [2:0] mode);
    op = 2'($urandom_range(0, 3));
    case (op)
      OP_SGNJ:   mode = 3'($urandom_range(0, 2));
      OP_MINMAX: mode = 3'($urandom_range(0, 1));
      OP_CMP:    mode = 3'($urandom_range(0, 2));
      default:   mode = 3'($urandom_range(0, 7));   // CLASSIFY ignores it
    endcase
  endtask

  // Every (op, op_mode) pair that section 0 lists, in order.
  task automatic get_combo(input int i, output logic [1:0] op, output logic [2:0] mode);
    case (i)
      0: begin op = OP_SGNJ;   mode = 3'd0; end
      1: begin op = OP_SGNJ;   mode = 3'd1; end
      2: begin op = OP_SGNJ;   mode = 3'd2; end
      3: begin op = OP_MINMAX; mode = 3'd0; end
      4: begin op = OP_MINMAX; mode = 3'd1; end
      5: begin op = OP_CMP;    mode = 3'd0; end
      6: begin op = OP_CMP;    mode = 3'd1; end
      7: begin op = OP_CMP;    mode = 3'd2; end
      default: begin op = OP_CLASS; mode = 3'd0; end
    endcase
  endtask

  // -------------------------------------------------------------------------
  //  The run
  // -------------------------------------------------------------------------
  initial begin
    logic [1:0] op;
    logic [2:0] mode;
    int         i, ia, ib, c, n;

    operand_a_i = 32'd0;
    operand_b_i = 32'd0;
    op_i        = 2'd0;
    op_mode_i   = 3'd0;
    in_valid_i  = 1'b0;
    load_vectors();

    bfm_reset(4);
    rdy_mode = 0;
    repeat (4) @(posedge clk);

    // ---- exhaustive cross of the corner vectors, every listed op/mode -----
    for (c = 0; c < 9; c++) begin
      get_combo(c, op, mode);
      for (ia = 0; ia < NVEC; ia++)
        for (ib = 0; ib < NVEC; ib++)
          do_issue(vec[ia], vec[ib], op, mode);
    end
    drain(2000);

    // ---- the same corners again under random backpressure (H3) ------------
    rdy_mode = 1;
    for (c = 0; c < 9; c++) begin
      get_combo(c, op, mode);
      for (ia = 0; ia < 14; ia++)
        for (ib = 0; ib < 14; ib++)
          do_issue(vec[ia], vec[ib], op, mode);
    end
    drain(4000);

    // ---- random operations, sparse ready ----------------------------------
    rdy_mode = 2;
    for (n = 0; n < 400; n++) begin
      rnd_opmode(op, mode);
      do_issue(rnd_operand(), rnd_operand(), op, mode);
    end
    drain(4000);

    // ---- random operations, long stalls (H3) ------------------------------
    rdy_mode = 3;
    for (n = 0; n < 600; n++) begin
      rnd_opmode(op, mode);
      do_issue(rnd_operand(), rnd_operand(), op, mode);
    end
    drain(4000);

    // ---- random operations, full rate -------------------------------------
    rdy_mode = 0;
    for (n = 0; n < 3000; n++) begin
      rnd_opmode(op, mode);
      do_issue(rnd_operand(), rnd_operand(), op, mode);
    end
    drain(4000);

    // ---- S15: reset discards work in flight -------------------------------
    // Operations are pushed in with the sink mostly closed, so a design that
    // buffers has results pending when reset lands.  The scoreboard is off
    // across the window because those operations are legitimately discarded.
    sb_en    = 1'b0;
    rdy_mode = 2;
    for (n = 0; n < 8; n++) begin
      rnd_opmode(op, mode);
      do_issue(rnd_operand(), rnd_operand(), op, mode);
    end
    bfm_idle();
    bfm_reset(4);
    expect_quiet = 1'b1;          // checked from the first cycle after release
    rdy_mode     = 0;
    repeat (40) @(posedge clk);
    @(negedge clk);
    expect_quiet = 1'b0;
    q.delete();
    sb_en = 1'b1;

    // ---- the design must still work after that reset ----------------------
    for (n = 0; n < 400; n++) begin
      rnd_opmode(op, mode);
      do_issue(rnd_operand(), rnd_operand(), op, mode);
    end
    drain(4000);

    // ---- verdict -----------------------------------------------------------
    if (delivered != issued)
      flag("H2", $sformatf(
        "%0d operations were accepted but %0d results were delivered",
        issued, delivered));
    if (issued < 1000)
      flag("H1", $sformatf("only %0d operations were ever accepted", issued));

    $display("--- %0d operations issued, %0d results checked, %0d failures ---",
             issued, delivered, err_cnt);
    if (err_cnt == 0) $display("RESULT: PASS");
    else              $display("RESULT: FAIL");
    $finish;
  end

endmodule