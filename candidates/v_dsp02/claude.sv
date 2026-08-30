// ===========================================================================
// fp_noncomp_tb.sv -- self-checking testbench for fp_noncomp.
//
// THE TWO ORDERINGS ARE DIFFERENT, AND KEEPING THEM APART IS THE POINT.
// MINMAX (S3) orders -0.0 BELOW +0.0, as RISC-V requires; CMP (S10) treats the
// two zeros as EQUAL, as IEEE 754 comparison requires. This file therefore has
// two distinct monotone keys, okey() and ckey(), and never uses one where the
// other belongs. A single shared key would break whichever clause it did not
// match.
//
// S4 IS THE FORECLOSED ALTERNATIVE. The model implements IEEE 754-2008
// minNum/maxNum, as RISC-V adopts them: a NaN operand of EITHER kind is
// ignored and the other operand is returned, so min(qNaN, 1.0) is 1.0. The
// 2019 minimum/maximum operations propagate NaN instead and are explicitly out
// of scope; expecting them here would reject correct hardware.
//
// WHAT IS DELIBERATELY NOT CHECKED, because §10 frees it:
//   1  latency between acceptance and result -- every wait is a bounded retry,
//      never a required cycle count;
//   2  result_o / class_mask_o / status_o while out_valid_o is low -- outputs
//      are sampled ONLY on a delivery, never otherwise;
//   3  promptness of in_ready_o -- a refusal is only reported after a very long
//      budget, never merely because the design looked idle;
//   4  result_o when the operation is CLASSIFY;
//   5  class_mask_o when the operation is anything other than CLASSIFY;
//   6  op_mode_i values not listed in §0 -- none is ever driven;
//   7  internal structure, including whether the unit pipelines at all.
//
// H4 is honoured: once in_valid_i is asserted the four operation inputs are
// held stable until the operation is accepted, and valid is dropped on the
// negative edge immediately after acceptance so no operation is ever offered
// twice.
// ===========================================================================

`timescale 1ns/1ps

module fp_noncomp_tb;

  localparam logic [31:0] CANON_QNAN = 32'h7FC0_0000;   // A2

  // =========================================================================
  // DUT connections
  // =========================================================================
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

  // =========================================================================
  // PROVIDED PLUMBING -- issues operations, checks nothing.
  // =========================================================================
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

  task automatic bfm_idle();
    @(negedge clk);
    in_valid_i = 1'b0;
  endtask

  initial begin
    #200_000_000;
    $display("RESULT: FAIL (watchdog: no forward progress)");
    $finish;
  end

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

  // =========================================================================
  // reporting
  // =========================================================================
  int nerr;
  int nprint;

  task automatic fail(input string cl, input string msg);
    nerr = nerr + 1;
    if (nprint < 40) begin
      nprint = nprint + 1;
      $display("FAIL [%0s] t=%0t : %0s", cl, $time, msg);
    end
  endtask

  // =========================================================================
  // Reference model
  // =========================================================================
  function automatic bit is_nan(input logic [31:0] v);      // A3
    return (v[30:23] == 8'hFF) && (v[22:0] != 23'd0);
  endfunction

  function automatic bit is_snan(input logic [31:0] v);     // A3
    return is_nan(v) && (v[22] == 1'b0);
  endfunction

  function automatic bit is_inf(input logic [31:0] v);
    return (v[30:23] == 8'hFF) && (v[22:0] == 23'd0);
  endfunction

  function automatic bit is_zero(input logic [31:0] v);
    return (v[30:23] == 8'd0) && (v[22:0] == 23'd0);
  endfunction

  function automatic bit is_sub(input logic [31:0] v);
    return (v[30:23] == 8'd0) && (v[22:0] != 23'd0);
  endfunction

  // MINMAX ordering (S3): monotone in value, and -0.0 sorts BELOW +0.0.
  function automatic logic [31:0] okey(input logic [31:0] v);
    return v[31] ? ~v : (v | 32'h8000_0000);
  endfunction

  // CMP ordering (S10): the same map, but the two zeros are folded together
  // first so they compare EQUAL. This is where CMP and MINMAX differ.
  function automatic logic [31:0] ckey(input logic [31:0] v);
    logic [31:0] t;
    t = is_zero(v) ? 32'h0000_0000 : v;
    return t[31] ? ~t : (t | 32'h8000_0000);
  endfunction

  function automatic logic [9:0] cls_of(input logic [31:0] v);   // S12
    logic [9:0] m;
    m = 10'd0;
    if (is_nan(v))       m[v[22] ? 9 : 8] = 1'b1;
    else if (is_inf(v))  m[v[31] ? 0 : 7] = 1'b1;
    else if (is_zero(v)) m[v[31] ? 3 : 4] = 1'b1;
    else if (is_sub(v))  m[v[31] ? 2 : 5] = 1'b1;
    else                 m[v[31] ? 1 : 6] = 1'b1;
    return m;
  endfunction

  function automatic logic [31:0] exp_result(input logic [31:0] a, input logic [31:0] b,
                                             input logic [1:0] op, input logic [2:0] md);
    logic sgn;
    case (op)
      2'd0: begin                                   // SGNJ -- S1
        sgn = (md == 3'd0) ? b[31] : ((md == 3'd1) ? ~b[31] : (a[31] ^ b[31]));
        return {sgn, a[30:0]};        // bits 30:0 copied unchanged
      end
      2'd1: begin                                   // MINMAX
        if (is_nan(a) && is_nan(b)) return CANON_QNAN;            // S5
        if (is_nan(a))              return b;                     // S4 (2008 minNum)
        if (is_nan(b))              return a;                     // S4
        if (md == 3'd0)             return (okey(a) <= okey(b)) ? a : b;   // S3 min
        else                        return (okey(a) >= okey(b)) ? a : b;   // S3 max
      end
      2'd2: begin                                   // CMP -- S7
        if (is_nan(a) || is_nan(b)) return 32'd0;                  // S8/S9: false
        case (md)
          3'd0:    return (ckey(a) <= ckey(b)) ? 32'd1 : 32'd0;    // LE
          3'd1:    return (ckey(a) <  ckey(b)) ? 32'd1 : 32'd0;    // LT
          default: return (ckey(a) == ckey(b)) ? 32'd1 : 32'd0;    // EQ
        endcase
      end
      default: return 32'd0;                        // CLASSIFY: result_o free
    endcase
  endfunction

  // S14: only NV can ever be set; DZ/OF/UF/NX are zero for every operation.
  function automatic logic [4:0] exp_status(input logic [31:0] a, input logic [31:0] b,
                                            input logic [1:0] op, input logic [2:0] md);
    case (op)
      2'd0:    return 5'd0;                                              // S2
      2'd1:    return (is_snan(a) || is_snan(b)) ? 5'b10000 : 5'd0;      // S6
      2'd2: begin
        if (md == 3'd2) return (is_snan(a) || is_snan(b)) ? 5'b10000 : 5'd0;  // S9 quiet
        else            return (is_nan(a)  || is_nan(b))  ? 5'b10000 : 5'd0;  // S8 signalling
      end
      default: return 5'd0;                                              // S13
    endcase
  endfunction

  function automatic string res_clause(input logic [31:0] a, input logic [31:0] b,
                                       input logic [1:0] op, input logic [2:0] md);
    case (op)
      2'd0: return "S1";
      2'd1: begin
        if (is_nan(a) && is_nan(b)) return "S5";
        if (is_nan(a) || is_nan(b)) return "S4";
        return "S3";
      end
      2'd2: begin
        if (is_nan(a) || is_nan(b)) return (md == 3'd2) ? "S9" : "S8";
        return "S7";
      end
      default: return "S12";
    endcase
  endfunction

  function automatic string st_clause(input logic [1:0] op, input logic [2:0] md);
    case (op)
      2'd0:    return "S2";
      2'd1:    return "S6";
      2'd2:    return (md == 3'd2) ? "S9" : "S8";
      default: return "S13";
    endcase
  endfunction

  function automatic string op_name(input logic [1:0] op, input logic [2:0] md);
    case (op)
      2'd0:    return (md == 3'd0) ? "SGNJ" : ((md == 3'd1) ? "SGNJN" : "SGNJX");
      2'd1:    return (md == 3'd0) ? "MIN" : "MAX";
      2'd2:    return (md == 3'd0) ? "LE" : ((md == 3'd1) ? "LT" : "EQ");
      default: return "CLASSIFY";
    endcase
  endfunction

  // =========================================================================
  // Expectation record.  Written only by the stimulus process; the monitor
  // reads it by index and owns rd_ptr, so no queue is written from two places.
  // =========================================================================
  logic [31:0] exp_a   [$];
  logic [31:0] exp_b   [$];
  logic [1:0]  exp_op  [$];
  logic [2:0]  exp_md  [$];
  logic [31:0] exp_res [$];
  logic [9:0]  exp_cls [$];
  logic [4:0]  exp_st  [$];

  int  flush_req;                // stimulus-owned
  int  flush_to;                 // stimulus-owned
  int  rd_ptr;                   // monitor-owned
  int  flush_ack;                // monitor-owned
  int  pr_watch;                 // monitor-owned
  int  stall_cyc;                // monitor-owned
  int  rst_low_cnt;              // monitor-owned
  logic rst_n_q;                 // monitor-owned

  // =========================================================================
  // Result-side ready.  Driven ONLY here, at the negative edge, so it is
  // stable when the monitor samples at the rising edge.  The pattern is
  // free-running so backpressure can never deadlock the stimulus.
  // =========================================================================
  int  rdy_mode;                 // stimulus-owned: 0 = always ready, 1 = pattern
  int  rdy_cnt;

  always @(negedge clk) begin
    rdy_cnt <= rdy_cnt + 1;
    if (rdy_mode == 0) out_ready_i <= 1'b1;
    else               out_ready_i <= ((rdy_cnt % 20) >= 12);   // H3: 12 low, 8 high
  end

  // =========================================================================
  // MONITOR.  Samples at the rising edge, so it reads the values that were
  // valid during the cycle the transfer completed on.  Outputs are examined
  // ONLY on a delivery -- never while out_valid_o is low (§10.2).
  // =========================================================================
  always @(posedge clk) begin
    logic [31:0] ea, eb;
    logic [1:0]  eop;
    logic [2:0]  emd;

    // A reset discards work in flight, so the model skips past it.
    if (flush_req != flush_ack) begin
      rd_ptr    = flush_to;
      flush_ack = flush_req;
      pr_watch  = 30;
    end

    if (!rst_n) begin
      rst_low_cnt <= rst_low_cnt + 1;
      // S15: while reset is low the design is idle.
      if ((rst_low_cnt >= 2) && (out_valid_o === 1'b1))
        fail("S15", "out_valid_o high while rst_ni was low");
    end
    else begin
      rst_low_cnt <= 0;
      // S15: low on the first cycle after release.
      if (!rst_n_q && (out_valid_o === 1'b1))
        fail("S15", "out_valid_o high on the first cycle after reset release");

      if (out_valid_o && out_ready_i) begin
        if (pr_watch > 0) begin
          fail("S15", "result delivered after reset for an operation accepted before it");
        end
        else if (rd_ptr >= exp_op.size()) begin
          fail("H2", "a result was delivered with no operation outstanding");
        end
        else begin
          ea  = exp_a[rd_ptr];
          eb  = exp_b[rd_ptr];
          eop = exp_op[rd_ptr];
          emd = exp_md[rd_ptr];

          // result_o: not examined for CLASSIFY (§10.4)
          if (eop != 2'd3) begin
            if (result_o !== exp_res[rd_ptr])
              fail(res_clause(ea, eb, eop, emd),
                   $sformatf("op %0d (%0s) a=%08h b=%08h: result_o=%08h, expected %08h",
                             rd_ptr, op_name(eop, emd), ea, eb, result_o, exp_res[rd_ptr]));
          end

          // class_mask_o: examined ONLY for CLASSIFY (§10.5)
          if (eop == 2'd3) begin
            if (class_mask_o !== exp_cls[rd_ptr])
              fail("S12",
                   $sformatf("op %0d CLASSIFY a=%08h: class_mask_o=%010b, expected %010b",
                             rd_ptr, ea, class_mask_o, exp_cls[rd_ptr]));
          end

          // status_o, for every operation
          if (status_o !== exp_st[rd_ptr]) begin
            if (status_o[3:0] !== 4'd0)
              fail("S14",
                   $sformatf("op %0d (%0s) a=%08h b=%08h: status_o=%05b, DZ/OF/UF/NX must be zero",
                             rd_ptr, op_name(eop, emd), ea, eb, status_o));
            else
              fail(st_clause(eop, emd),
                   $sformatf("op %0d (%0s) a=%08h b=%08h: status_o=%05b, expected %05b",
                             rd_ptr, op_name(eop, emd), ea, eb, status_o, exp_st[rd_ptr]));
          end

          rd_ptr = rd_ptr + 1;
        end
      end

      if (out_valid_o && !out_ready_i) stall_cyc = stall_cyc + 1;   // H3 coverage
      if (pr_watch > 0) pr_watch = pr_watch - 1;
    end
    rst_n_q <= rst_n;
  end

  // =========================================================================
  // Stimulus
  // =========================================================================
  bit          give_up;
  int          n_i, n_j, n_k, w_i, guard;
  logic [31:0] va, vb;
  logic [1:0]  vop;
  logic [2:0]  vmd;
  logic [31:0] vals [20];
  int          combo_op   [8];
  int          combo_mode [8];

  // One operation, with the expectation queued BEFORE the offer so a
  // zero-latency delivery can never arrive ahead of its record.
  task automatic do_op(input logic [31:0] a, input logic [31:0] b,
                       input logic [1:0] op, input logic [2:0] md);
    int w;
    exp_a.push_back(a);
    exp_b.push_back(b);
    exp_op.push_back(op);
    exp_md.push_back(md);
    exp_res.push_back(exp_result(a, b, op, md));
    exp_cls.push_back(cls_of(a));
    exp_st.push_back(exp_status(a, b, op, md));
    @(negedge clk);
    operand_a_i = a;
    operand_b_i = b;
    op_i        = op;
    op_mode_i   = md;
    in_valid_i  = 1'b1;
    w = 0;
    // §10.3: promptness of in_ready_o is free, so this budget is enormous.
    // It exists only so a design that never accepts cannot hang the run.
    while (w < 20000) begin
      @(posedge clk);
      if (in_ready_o) break;
      w = w + 1;
    end
    if (w >= 20000) begin
      fail("H1", "in_ready_o never rose in 20000 cycles: operation not accepted");
      give_up = 1'b1;
    end
  endtask

  initial begin
    nerr = 0; nprint = 0;
    rd_ptr = 0; flush_req = 0; flush_ack = 0; flush_to = 0;
    pr_watch = 0; stall_cyc = 0; rst_low_cnt = 0; rst_n_q = 1'b0;
    rdy_mode = 0; rdy_cnt = 0; give_up = 1'b0;
    operand_a_i = 32'd0; operand_b_i = 32'd0; op_i = 2'd0; op_mode_i = 3'd0;
    in_valid_i = 1'b0;

    vals = '{32'h0000_0000,   // +0
             32'h8000_0000,   // -0
             32'h0000_0001,   // + smallest subnormal
             32'h8000_0001,   // - smallest subnormal
             32'h007F_FFFF,   // + largest subnormal
             32'h807F_FFFF,   // - largest subnormal
             32'h0080_0000,   // + smallest normal
             32'h8080_0000,   // - smallest normal
             32'h3F80_0000,   // +1.0
             32'hBF80_0000,   // -1.0
             32'h4049_0FDB,   // +pi
             32'hC049_0FDB,   // -pi
             32'h7F7F_FFFF,   // + largest normal
             32'hFF7F_FFFF,   // - largest normal
             32'h7F80_0000,   // +inf
             32'hFF80_0000,   // -inf
             32'h7FC0_0000,   // canonical qNaN
             32'hFFC0_0001,   // qNaN, sign set, other payload
             32'h7F80_0001,   // sNaN, smallest payload
             32'h7FBF_FFFF};  // sNaN, largest payload

    combo_op   = '{0, 0, 0, 1, 1, 2, 2, 2};
    combo_mode = '{0, 1, 2, 0, 1, 0, 1, 2};

    bfm_reset(6);
    repeat (4) @(posedge clk);

    // ---- phase 1: full cross product, under BACKPRESSURE (H2/H3) ---------
    @(posedge clk) rdy_mode = 1;
    for (n_k = 0; (n_k < 8) && !give_up; n_k++) begin
      for (n_i = 0; (n_i < 20) && !give_up; n_i++) begin
        for (n_j = 0; (n_j < 20) && !give_up; n_j++) begin
          do_op(vals[n_i], vals[n_j], combo_op[n_k][1:0], combo_mode[n_k][2:0]);
        end
      end
    end
    bfm_idle();

    // ---- phase 2: CLASSIFY over every operand (S12, S13) -----------------
    for (n_i = 0; (n_i < 20) && !give_up; n_i++)
      do_op(vals[n_i], vals[(n_i + 7) % 20], 2'd3, 3'd0);
    bfm_idle();

    // ---- phase 3: random operands, full rate -----------------------------
    @(posedge clk) rdy_mode = 0;
    for (n_i = 0; (n_i < 400) && !give_up; n_i++) begin
      va  = ($urandom_range(0, 2) == 0) ? vals[$urandom_range(0, 19)] : $urandom;
      vb  = ($urandom_range(0, 2) == 0) ? vals[$urandom_range(0, 19)] : $urandom;
      vop = 2'($urandom_range(0, 3));
      // §10.6: only op_mode values listed in §0 are ever driven.
      case (vop)
        2'd0:    vmd = 3'($urandom_range(0, 2));
        2'd1:    vmd = 3'($urandom_range(0, 1));
        2'd2:    vmd = 3'($urandom_range(0, 2));
        default: vmd = 3'd0;
      endcase
      do_op(va, vb, vop, vmd);
    end
    bfm_idle();

    // ---- phase 4: random operands, under backpressure --------------------
    @(posedge clk) rdy_mode = 1;
    for (n_i = 0; (n_i < 300) && !give_up; n_i++) begin
      va  = ($urandom_range(0, 1) == 0) ? vals[$urandom_range(0, 19)] : $urandom;
      vb  = ($urandom_range(0, 1) == 0) ? vals[$urandom_range(0, 19)] : $urandom;
      vop = 2'($urandom_range(0, 3));
      case (vop)
        2'd0:    vmd = 3'($urandom_range(0, 2));
        2'd1:    vmd = 3'($urandom_range(0, 1));
        2'd2:    vmd = 3'($urandom_range(0, 2));
        default: vmd = 3'd0;
      endcase
      do_op(va, vb, vop, vmd);
    end
    bfm_idle();

    // ---- drain what is still in flight -----------------------------------
    @(posedge clk) rdy_mode = 0;
    guard = 0;
    while ((rd_ptr < exp_op.size()) && (guard < 8000)) begin
      @(posedge clk);
      guard = guard + 1;
    end
    if (rd_ptr < exp_op.size())
      fail("H2", $sformatf("%0d operation(s) accepted but only %0d result(s) delivered",
                           exp_op.size(), rd_ptr));

    // ---- phase 5: reset with work in flight (S15) ------------------------
    if (!give_up) begin
      @(posedge clk) rdy_mode = 1;          // let results back up
      for (n_i = 0; (n_i < 12) && !give_up; n_i++)
        do_op(vals[n_i], vals[19 - n_i], 2'd1, 3'd0);
      bfm_idle();
      // Reset first, THEN tell the model to discard. Flushing earlier would
      // start the S15 watch window while pre-reset results are still draining
      // legitimately, and those would be misreported as stale.
      @(negedge clk);
      rst_n     = 1'b0;
      flush_to  = exp_op.size();
      flush_req = flush_req + 1;
      repeat (5) @(posedge clk);
      @(negedge clk);
      rst_n = 1'b1;
      @(posedge clk) rdy_mode = 0;          // ready high: any stale result WILL show
      repeat (40) @(posedge clk);

      // ---- phase 6: the unit works again after reset ---------------------
      for (n_i = 0; (n_i < 20) && !give_up; n_i++)
        do_op(vals[n_i], vals[(n_i + 3) % 20], 2'd2, 3'd0);
      bfm_idle();
      guard = 0;
      while ((rd_ptr < exp_op.size()) && (guard < 4000)) begin
        @(posedge clk);
        guard = guard + 1;
      end
      if (rd_ptr < exp_op.size())
        fail("H2", $sformatf("after reset, %0d operation(s) accepted but only %0d delivered",
                             exp_op.size(), rd_ptr));
    end

    // ---- no extra results after everything is accounted for --------------
    w_i = rd_ptr;
    repeat (30) @(posedge clk);
    if (rd_ptr != w_i)
      fail("H2", "extra result(s) delivered after every operation was accounted for");

    // ---- verdict ---------------------------------------------------------
    $display("summary: %0d operation(s) issued, %0d result(s) checked, %0d backpressure stall cycle(s), %0d failure(s)",
             exp_op.size(), rd_ptr, stall_cyc, nerr);
    if (stall_cyc < 20)
      $display("note: only %0d stall cycle(s) observed; H3 backpressure was barely exercised",
               stall_cyc);
    if (nerr == 0) $display("RESULT: PASS");
    else           $display("RESULT: FAIL");
    $finish;
  end

endmodule