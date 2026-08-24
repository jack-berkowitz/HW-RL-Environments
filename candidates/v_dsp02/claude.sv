// ===========================================================================
//  fp_noncomp_tb.sv
//
//  Self-checking testbench for fp_noncomp.
//
//  Method
//  ------
//  A reference model computes, for every operation at the moment it is
//  ACCEPTED, exactly what the contract requires of it.  The record is pushed
//  onto a queue; every delivered result is matched against the head of that
//  queue, which is what makes H2 (order), H3 (no loss, duplication or
//  reordering under backpressure) and S15 (nothing survives a reset)
//  checkable at all -- the port map carries no tag, so bookkeeping is the only
//  way to attribute a result to an operation.
//
//  Acceptance is processed before delivery within a clock edge, so a design
//  with zero latency -- one that delivers in the same cycle it accepts -- is
//  judged the same way as a pipelined one.
//
//  What is deliberately NOT checked (§10)
//  --------------------------------------
//    1  latency: no result is expected in any particular cycle.
//    2  result_o / class_mask_o / status_o while out_valid_o is low: sampled
//       only on a delivery edge.
//    3  promptness of in_ready_o: never required high.
//    4  result_o under CLASSIFY.
//    5  class_mask_o under anything other than CLASSIFY.
//    6  op_mode_i values not listed for the selected operation: never driven.
//
//  The one trap named in §10 is S4: MINMAX returns the OTHER operand when one
//  operand is a NaN of either kind (IEEE 754-2008 minNum/maxNum, as RISC-V
//  adopts), NOT the NaN-propagating 2019 minimum/maximum.
// ===========================================================================
`timescale 1ns/1ps

module fp_noncomp_tb;

  // ---- signals -------------------------------------------------------------
  logic        clk;
  logic        rst_n;

  logic [31:0] operand_a_i, operand_b_i;
  logic [1:0]  op_i;
  logic [2:0]  op_mode_i;
  logic        in_valid_i, in_ready_o;
  logic [31:0] result_o;
  logic [9:0]  class_mask_o;
  logic [4:0]  status_o;
  logic        out_valid_o, out_ready_i;

  fp_noncomp dut (
    .clk_i(clk), .rst_ni(rst_n),
    .operand_a_i(operand_a_i), .operand_b_i(operand_b_i),
    .op_i(op_i), .op_mode_i(op_mode_i),
    .in_valid_i(in_valid_i), .in_ready_o(in_ready_o),
    .result_o(result_o), .class_mask_o(class_mask_o), .status_o(status_o),
    .out_valid_o(out_valid_o), .out_ready_i(out_ready_i));

  // -------------------------------------------------------------------------
  // PROVIDED PLUMBING -- issues operations, checks nothing.
  // (clk and rst_n are declared above, with the rest of the signals.)
  // -------------------------------------------------------------------------
  initial begin clk = 1'b0; forever #5 clk = ~clk; end
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
    $display("RESULT: FAIL (watchdog: no forward progress)");
    $finish;
  end

  // -------------------------------------------------------------------------
  // END OF PROVIDED PLUMBING -- everything below is the testbench proper.
  // -------------------------------------------------------------------------

  localparam logic [31:0] QNAN_CANON = 32'h7FC0_0000;   // A2

  // ---- verdict -------------------------------------------------------------
  int err_count = 0;
  int msg_count = 0;
  int n_checked = 0;

  task automatic note_fail(input string clause, input string msg);
    err_count = err_count + 1;
    if (msg_count < 40) begin
      msg_count = msg_count + 1;
      $display("VIOLATION [%s] %s", clause, msg);
    end
  endtask

  // ---- format helpers (A1, A3) ---------------------------------------------
  function automatic logic fp_is_nan(input logic [31:0] x);
    return (x[30:23] == 8'hFF) && (x[22:0] != 23'd0);
  endfunction
  function automatic logic fp_is_snan(input logic [31:0] x);
    return fp_is_nan(x) && (x[22] == 1'b0);
  endfunction
  function automatic logic fp_is_qnan(input logic [31:0] x);
    return fp_is_nan(x) && (x[22] == 1'b1);
  endfunction
  function automatic logic fp_is_inf(input logic [31:0] x);
    return (x[30:23] == 8'hFF) && (x[22:0] == 23'd0);
  endfunction
  function automatic logic fp_is_zero(input logic [31:0] x);
    return (x[30:23] == 8'd0) && (x[22:0] == 23'd0);
  endfunction
  function automatic logic fp_is_sub(input logic [31:0] x);
    return (x[30:23] == 8'd0) && (x[22:0] != 23'd0);
  endfunction

  // Ordering key for MINMAX (S3): monotone in the float value, and -0.0 sits
  // strictly below +0.0.  Injective over all non-NaN encodings.
  function automatic longint ord_mm(input logic [31:0] x);
    longint mag;
    mag = longint'({1'b0, x[30:0]});
    if (x[31]) return -(mag + 64'd1);
    else       return mag;
  endfunction

  // Ordering key for CMP (S10): the two zeros compare equal.
  function automatic longint ord_cmp(input logic [31:0] x);
    longint mag;
    mag = longint'({1'b0, x[30:0]});
    if (x[31]) return -mag;
    else       return mag;
  endfunction

  // S12
  function automatic logic [9:0] fp_class(input logic [31:0] x);
    logic [9:0] m;
    m = 10'd0;
    if (fp_is_nan(x))       m[x[22] ? 9 : 8] = 1'b1;
    else if (fp_is_inf(x))  m[x[31] ? 0 : 7] = 1'b1;
    else if (fp_is_zero(x)) m[x[31] ? 3 : 4] = 1'b1;
    else if (fp_is_sub(x))  m[x[31] ? 2 : 5] = 1'b1;
    else                    m[x[31] ? 1 : 6] = 1'b1;
    return m;
  endfunction

  // ---- the reference model -------------------------------------------------
  typedef struct {
    int          idx;
    logic [31:0] a;
    logic [31:0] b;
    logic [1:0]  op;
    logic [2:0]  mode;
    logic [31:0] res;      // expected result_o
    logic        chk_res;  // ... and whether it is constrained at all
    logic [9:0]  cls;      // expected class_mask_o
    logic        chk_cls;
    logic [4:0]  st;       // expected status_o
    int          res_cl;   // clause to name if the result is wrong
    int          st_cl;    // clause to name if NV is wrong
  } rec_t;

  function automatic rec_t model(input logic [31:0] a, input logic [31:0] b,
                                 input logic [1:0] op, input logic [2:0] mode);
    rec_t r;
    logic sgn, anan, bnan, asn, bsn, tru;
    longint oa, ob;

    r.a = a; r.b = b; r.op = op; r.mode = mode;
    r.res = 32'd0; r.chk_res = 1'b0;
    r.cls = 10'd0; r.chk_cls = 1'b0;
    r.st  = 5'd0;
    r.res_cl = 0; r.st_cl = 14;
    r.idx = 0;

    anan = fp_is_nan(a);  bnan = fp_is_nan(b);
    asn  = fp_is_snan(a); bsn  = fp_is_snan(b);

    case (op)
      2'd0: begin                                   // ---- SGNJ (S1, S2)
        sgn = (mode == 3'd0) ? b[31] :
              (mode == 3'd1) ? ~b[31] : (a[31] ^ b[31]);
        r.res     = {sgn, a[30:0]};                 // payload copied, not canonicalised
        r.chk_res = 1'b1;
        r.st      = 5'd0;                           // S2: never any flag
        r.res_cl  = 1;
        r.st_cl   = 2;
      end

      2'd1: begin                                   // ---- MINMAX (S3-S6)
        if (anan && bnan) begin
          r.res    = QNAN_CANON;                    // S5
          r.res_cl = 5;
        end else if (anan) begin
          r.res    = b;                             // S4: the OTHER operand
          r.res_cl = 4;
        end else if (bnan) begin
          r.res    = a;                             // S4
          r.res_cl = 4;
        end else begin
          oa = ord_mm(a); ob = ord_mm(b);           // S3, -0.0 below +0.0
          if (mode == 3'd0) r.res = (oa <= ob) ? a : b;
          else              r.res = (oa >= ob) ? a : b;
          r.res_cl = 3;
        end
        r.chk_res = 1'b1;
        r.st      = {(asn | bsn), 4'b0000};         // S6: signalling NaN only
        r.st_cl   = 6;
      end

      2'd2: begin                                   // ---- CMP (S7-S11)
        if (mode == 3'd2) begin                     // EQ, quiet (S9)
          if (anan || bnan) begin
            tru     = 1'b0;
            r.st    = {(asn | bsn), 4'b0000};
            r.res_cl = 9;
          end else begin
            tru     = (ord_cmp(a) == ord_cmp(b));   // S10: -0.0 == +0.0
            r.res_cl = 10;
          end
          r.st_cl = 9;
        end else begin                              // LE / LT, signalling (S8)
          if (anan || bnan) begin
            tru     = 1'b0;
            r.st    = 5'b10000;                     // NV for a NaN of either kind
            r.res_cl = 8;
          end else begin
            tru     = (mode == 3'd0) ? (ord_cmp(a) <= ord_cmp(b))
                                     : (ord_cmp(a) <  ord_cmp(b));
            r.res_cl = 10;
          end
          r.st_cl = 8;
        end
        r.res     = tru ? 32'h0000_0001 : 32'h0000_0000;   // S7
        r.chk_res = 1'b1;
      end

      default: begin                                // ---- CLASSIFY (S12, S13)
        r.cls     = fp_class(a);                    // operand_b_i ignored
        r.chk_cls = 1'b1;
        r.chk_res = 1'b0;                           // latitude 4
        r.st      = 5'd0;                           // S13
        r.st_cl   = 13;
      end
    endcase
    return r;
  endfunction

  function automatic string cl_name(input int n);
    return $sformatf("S%0d", n);
  endfunction

  function automatic string op_name(input rec_t r);
    string s;
    case (r.op)
      2'd0: s = $sformatf("SGNJ mode %0d", r.mode);
      2'd1: s = (r.mode == 3'd0) ? "MIN" : "MAX";
      2'd2: s = (r.mode == 3'd0) ? "LE" : ((r.mode == 3'd1) ? "LT" : "EQ");
      default: s = "CLASSIFY";
    endcase
    return $sformatf("%s a=%08h b=%08h (op %0d)", s, r.a, r.b, r.idx);
  endfunction

  // ---- the scoreboard ------------------------------------------------------
  rec_t q [$];
  int   issue_idx = 0;
  int   n_deliv   = 0;
  int   quiet_out = 0;      // after a reset, nothing may be delivered until an
                            // operation has been accepted (S15)

  always @(posedge clk) begin : mon_blk
    rec_t r, e;
    int   k, later;
    if (rst_n !== 1'b1) begin
      q.delete();
      quiet_out = 1;
    end else begin
      // ---- acceptance (H1).  Processed BEFORE delivery so a zero-latency
      //      design, which delivers on the very edge it accepts, is handled.
      if (in_valid_i === 1'b1 && in_ready_o === 1'b1) begin
        r = model(operand_a_i, operand_b_i, op_i, op_mode_i);
        r.idx = issue_idx;
        issue_idx = issue_idx + 1;
        q.push_back(r);
        quiet_out = 0;
      end

      // ---- delivery (H2, H3)
      if (out_valid_o === 1'b1 && out_ready_i === 1'b1) begin
        if (quiet_out == 1) begin
          note_fail("S15", "a result was delivered after reset for an operation accepted before it");
        end else if (q.size() == 0) begin
          note_fail("H2", "a result was delivered with no operation outstanding (invented or duplicated)");
        end else begin
          e = q.pop_front();
          n_deliv = n_deliv + 1;
          n_checked = n_checked + 1;
          if (e.chk_res && (result_o !== e.res)) begin
            later = -1;
            for (k = 0; k < q.size(); k++)
              if ((later < 0) && q[k].chk_res && (q[k].res === result_o) &&
                  (q[k].st === status_o)) later = k;
            if (later >= 0)
              note_fail($sformatf("H2/%s", cl_name(e.res_cl)),
                        $sformatf("%s: result_o is %08h, expected %08h -- that value belongs to an operation accepted %0d later, so either the result is wrong or results are out of order",
                                  op_name(e), result_o, e.res, later + 1));
            else
              note_fail(cl_name(e.res_cl),
                        $sformatf("%s: result_o is %08h, expected %08h", op_name(e), result_o, e.res));
          end
          if (e.chk_cls && (class_mask_o !== e.cls))
            note_fail("S12",
                      $sformatf("%s: class_mask_o is %010b, expected %010b", op_name(e), class_mask_o, e.cls));
          if (status_o[3:0] !== 4'b0000)
            note_fail("S14",
                      $sformatf("%s: status_o is %05b; DZ, OF, UF and NX are zero for every operation here",
                                op_name(e), status_o));
          if (status_o[4] !== e.st[4])
            note_fail(cl_name(e.st_cl),
                      $sformatf("%s: NV is %0b, expected %0b", op_name(e), status_o[4], e.st[4]));
        end
      end

      // S15: nothing may appear between a reset and the next acceptance
      if (quiet_out == 1 && out_valid_o === 1'b1 &&
          !(in_valid_i === 1'b1 && in_ready_o === 1'b1))
        note_fail("S15", "out_valid_o is asserted after reset with no operation accepted since");
    end
  end

  // ---- forward-progress detector (S16) -------------------------------------
  // Latitude 3 lets in_ready_o be low for any reason, so this bound is set far
  // beyond anything a working design needs; the offer is never withdrawn.
  int stall_cnt = 0;
  always @(posedge clk) begin
    if (rst_n !== 1'b1 || in_valid_i !== 1'b1 || in_ready_o === 1'b1) stall_cnt <= 0;
    else begin
      stall_cnt <= stall_cnt + 1;
      if (stall_cnt == 20000) begin
        $display("VIOLATION [H1] in_valid_i has been held for 20000 cycles without in_ready_o ever rising");
        $display("RESULT: FAIL (no operation was ever accepted)");
        $finish;
      end
    end
  end

  // ---- result-side ready ---------------------------------------------------
  // Driven at the falling edge only; the monitor samples it at the rising edge.
  int bp_mode = 0;          // 0 = always ready, 1 = random, 2 = never ready
  always @(negedge clk) begin
    case (bp_mode)
      0: out_ready_i = 1'b1;
      2: out_ready_i = 1'b0;
      default: out_ready_i = ($urandom_range(0, 2) != 0);
    endcase
  end

  // ---- operand pool --------------------------------------------------------
  localparam int POOL_N = 24;
  logic [31:0] pool [POOL_N];

  task automatic fill_pool();
    pool[0]  = 32'h0000_0000;   // +0
    pool[1]  = 32'h8000_0000;   // -0
    pool[2]  = 32'h3F80_0000;   // +1.0
    pool[3]  = 32'hBF80_0000;   // -1.0
    pool[4]  = 32'h4000_0000;   // +2.0
    pool[5]  = 32'hC000_0000;   // -2.0
    pool[6]  = 32'h7F80_0000;   // +inf
    pool[7]  = 32'hFF80_0000;   // -inf
    pool[8]  = 32'h7FC0_0000;   // canonical qNaN
    pool[9]  = 32'h7FC1_2345;   // qNaN, payload
    pool[10] = 32'hFFC0_0000;   // qNaN, negative
    pool[11] = 32'h7F80_0001;   // sNaN, smallest payload
    pool[12] = 32'h7FBF_FFFF;   // sNaN, largest payload
    pool[13] = 32'hFF80_0001;   // sNaN, negative
    pool[14] = 32'h0080_0000;   // +min normal
    pool[15] = 32'h807F_FFFF;   // -max subnormal
    pool[16] = 32'h0000_0001;   // +min subnormal
    pool[17] = 32'h007F_FFFF;   // +max subnormal
    pool[18] = 32'h7F7F_FFFF;   // +max normal
    pool[19] = 32'hFF7F_FFFF;   // -max normal
    pool[20] = 32'h8080_0000;   // -min normal
    pool[21] = 32'h8000_0001;   // -min subnormal
    pool[22] = 32'h3F80_0001;   // just above +1.0
    pool[23] = 32'h3380_0000;   // a small normal
  endtask

  function automatic logic [31:0] rnd_operand();
    int k;
    logic [22:0] man;
    logic        sg;
    k  = $urandom_range(0, 9);
    sg = 1'($urandom_range(0, 1));
    man = 23'($urandom_range(1, 8388607));
    case (k)
      0, 1, 2, 3: return pool[$urandom_range(0, POOL_N-1)];
      4:          return {sg, 8'hFF, 1'b0, man[21:0]};        // sNaN
      5:          return {sg, 8'hFF, 1'b1, man[21:0]};        // qNaN
      6:          return {sg, 8'h00, man};                    // subnormal
      7:          return {sg, 8'hFF, 23'd0};                  // infinity
      default:    return $urandom;
    endcase
  endfunction

  // op / mode combinations that §0 defines
  localparam int NCOMB = 9;
  logic [1:0] comb_op   [NCOMB];
  logic [2:0] comb_mode [NCOMB];

  task automatic fill_combs();
    comb_op[0] = 2'd0; comb_mode[0] = 3'd0;
    comb_op[1] = 2'd0; comb_mode[1] = 3'd1;
    comb_op[2] = 2'd0; comb_mode[2] = 3'd2;
    comb_op[3] = 2'd1; comb_mode[3] = 3'd0;
    comb_op[4] = 2'd1; comb_mode[4] = 3'd1;
    comb_op[5] = 2'd2; comb_mode[5] = 3'd0;
    comb_op[6] = 2'd2; comb_mode[6] = 3'd1;
    comb_op[7] = 2'd2; comb_mode[7] = 3'd2;
    comb_op[8] = 2'd3; comb_mode[8] = 3'd0;
  endtask

  // ---- drain ---------------------------------------------------------------
  task automatic drain(input int limit, input string tag);
    int i;
    for (i = 0; i < limit; i++) begin
      @(posedge clk);
      if (q.size() == 0) return;
    end
    note_fail("H2/H3", $sformatf("%s: %0d accepted operations never produced a result", tag, q.size()));
  endtask

  // ---- stimulus ------------------------------------------------------------
  initial begin : main
    int c, ia, ib, i;
    logic [31:0] a, b;

    operand_a_i = 32'd0; operand_b_i = 32'd0;
    op_i = 2'd0; op_mode_i = 3'd0; in_valid_i = 1'b0; out_ready_i = 1'b1;
    fill_pool();
    fill_combs();

    bfm_reset(6);

    // =================== directed: every defined op/mode over the pool =====
    bp_mode = 0;
    for (c = 0; c < NCOMB; c++) begin
      for (ia = 0; ia < POOL_N; ia++) begin
        for (ib = 0; ib < POOL_N; ib++) begin
          bfm_issue(pool[ia], pool[ib], comb_op[c], comb_mode[c]);
        end
      end
    end
    bfm_idle();
    drain(2000, "directed sweep");

    // =================== the same sweep under backpressure (H3) ===========
    bp_mode = 1;
    for (c = 0; c < NCOMB; c++) begin
      for (ia = 0; ia < POOL_N; ia++) begin
        for (ib = 0; ib < POOL_N; ib++) begin
          if ($urandom_range(0, 2) == 0)
            bfm_issue(pool[ia], pool[ib], comb_op[c], comb_mode[c]);
        end
      end
    end
    bfm_idle();
    bp_mode = 0;
    drain(4000, "backpressure sweep");

    // =================== random operands ==================================
    bp_mode = 1;
    for (i = 0; i < 4000; i++) begin
      c = $urandom_range(0, NCOMB-1);
      a = rnd_operand();
      b = rnd_operand();
      bfm_issue(a, b, comb_op[c], comb_mode[c]);
    end
    bfm_idle();
    bp_mode = 0;
    drain(8000, "random operands");

    // =================== a long stall (H3) ================================
    // The sink refuses everything for 60 cycles.  How many operations the
    // design can hold meanwhile is its own business (latitude 3 and 7), so the
    // issuer simply keeps its offer up -- H4 forbids withdrawing it -- and the
    // stall is lifted on a timer rather than after a fixed number of accepts.
    bp_mode = 2;
    fork
      begin : stall_issuer
        automatic int si, sc;
        for (si = 0; si < 6; si++) begin
          sc = $urandom_range(0, NCOMB-1);
          bfm_issue(rnd_operand(), rnd_operand(), comb_op[sc], comb_mode[sc]);
        end
        bfm_idle();
      end
      begin : stall_timer
        repeat (60) @(posedge clk);                // held, not lost
        bp_mode = 1;
      end
    join
    bp_mode = 0;
    drain(4000, "long stall");

    // =================== reset discards in-flight work (S15) ==============
    bp_mode = 2;                                   // leave work stuck in flight
    fork
      begin : rst_issuer
        automatic int ri, rc;
        for (ri = 0; ri < 3; ri++) begin
          rc = $urandom_range(0, NCOMB-1);
          bfm_issue(rnd_operand(), rnd_operand(), comb_op[rc], comb_mode[rc]);
        end
        bfm_idle();
      end
      begin : rst_timer
        repeat (10) @(posedge clk);
        bfm_reset(6);                              // the monitor clears the queue
        bp_mode = 0;                               // and lets the issuer finish
      end
    join
    repeat (40) @(posedge clk);                    // nothing stale may come out

    // =================== and it still works afterwards ====================
    bp_mode = 1;
    for (i = 0; i < 600; i++) begin
      c = $urandom_range(0, NCOMB-1);
      bfm_issue(rnd_operand(), rnd_operand(), comb_op[c], comb_mode[c]);
    end
    bfm_idle();
    bp_mode = 0;
    drain(4000, "post-reset");

    $display("INFO: %0d operations issued, %0d results checked", issue_idx, n_checked);
    if (n_checked < 5000)
      note_fail("H2", $sformatf("only %0d results were delivered for %0d operations", n_checked, issue_idx));
    if (err_count == 0) $display("RESULT: PASS");
    else                $display("RESULT: FAIL (%0d violation%s)", err_count, (err_count == 1) ? "" : "s");
    $finish;
  end

endmodule