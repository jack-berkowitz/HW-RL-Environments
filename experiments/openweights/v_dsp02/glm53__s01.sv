module fp_noncomp_tb;

  // ---------------------------------------------------------------------------
  // DUT connections
  // ---------------------------------------------------------------------------
  logic        clk;
  logic        rst_n;
  logic [31:0] operand_a_i, operand_b_i;
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

  // ---------------------------------------------------------------------------
  // Reference model
  // ---------------------------------------------------------------------------
  function automatic bit is_nan(input logic [31:0] x);
    return (x[30:23] == 8'hFF) && (x[22:0] != 23'h0);
  endfunction

  function automatic bit is_snan(input logic [31:0] x);
    return (x[30:23] == 8'hFF) && (x[22:0] != 23'h0) && !x[22];
  endfunction

  // A3 / S12 classifier
  function automatic logic [9:0] fclass(input logic [31:0] x);
    logic [9:0] c;
    c = 10'h0;
    if (x[30:23] == 8'hFF && x[22:0] != 23'h0)
      c = x[22] ? 10'b1000000000 : 10'b0100000000;      // qNaN : sNaN
    else if (x[30:23] == 8'hFF)
      c = x[31] ? 10'b0000000001 : 10'b0010000000;      // -inf : +inf
    else if (x[30:23] == 8'h00)
      c = (x[22:0] == 23'h0) ? (x[31] ? 10'b0000001000 : 10'b0000010000)  // -0 : +0
                             : (x[31] ? 10'b0000000100 : 10'b0000100000); // -sub : +sub
    else
      c = x[31] ? 10'b0000000010 : 10'b0001000000;      // -normal : +normal
    return c;
  endfunction

  // less-than; zz=1 => -0 < +0 (S3), zz=0 => zeros equal (S10)
  function automatic bit lt32(input logic [31:0] a, input logic [31:0] b, input bit zz);
    if (is_nan(a) || is_nan(b)) return 1'b0;
    if (a[30:0] == 31'h0 && b[30:0] == 31'h0) begin
      if (a[31] == b[31]) return 1'b0;
      return zz ? a[31] : 1'b0;
    end
    if (a[31] != b[31]) return a[31];
    if (a[30:0] == b[30:0]) return 1'b0;
    if (a[31]) return a[30:0] > b[30:0];
    else       return a[30:0] < b[30:0];
  endfunction

  function automatic bit eq32(input logic [31:0] a, input logic [31:0] b);
    if (is_nan(a) || is_nan(b)) return 1'b0;
    if (a[30:0] == 31'h0 && b[30:0] == 31'h0) return 1'b1; // -0 == +0 (S10)
    return (a == b);
  endfunction

  // ---------------------------------------------------------------------------
  // Scoreboard
  // ---------------------------------------------------------------------------
  typedef struct {
    logic [31:0] a, b;
    logic [1:0]  op;
    logic [2:0]  mode;
    logic [31:0] exp_res;
    logic [9:0]  exp_cls;
    logic [4:0]  exp_st;
  } exp_t;

  exp_t expq[$];
  int   errors  = 0;
  int   issued  = 0;
  int   retired = 0;

  // Compute expectation and enqueue it.
  task automatic expect_op(input logic [31:0] a, input logic [31:0] b,
                           input logic [1:0] op, input logic [2:0] mode);
    automatic exp_t e;
    e = '{default: '0, a: a, b: b, op: op, mode: mode};
    case (op)
      2'd0: begin // SGNJ (S1, S2)
        logic s;
        case (mode)
          3'd0: s =  b[31];
          3'd1: s = ~b[31];
          3'd2: s =  a[31] ^ b[31];
          default: s = 1'b0;
        endcase
        e.exp_res = {s, a[30:0]};
      end
      2'd1: begin // MINMAX (S3-S6)
        if (is_nan(a) && is_nan(b))      e.exp_res = 32'h7FC0_0000; // S5
        else if (is_nan(a))              e.exp_res = b;             // S4
        else if (is_nan(b))              e.exp_res = a;             // S4
        else if (mode == 3'd0)           e.exp_res = lt32(a, b, 1'b1) ? a : b;
        else                             e.exp_res = lt32(b, a, 1'b1) ? b : a;
        if (is_snan(a) || is_snan(b))    e.exp_st[4] = 1'b1;        // S6
      end
      2'd2: begin // CMP (S7-S11)
        bit r;
        r = 1'b0;
        case (mode)
          3'd0: r = (!is_nan(a) && !is_nan(b)) && (eq32(a, b) || lt32(a, b, 1'b0));
          3'd1: r = lt32(a, b, 1'b0);
          3'd2: r = eq32(a, b);
        endcase
        e.exp_res = r ? 32'h0000_0001 : 32'h0000_0000;
        if (mode == 3'd2) begin // S9: quiet comparison
          if (is_snan(a) || is_snan(b)) e.exp_st[4] = 1'b1;
        end else begin          // S8: signalling comparison
          if (is_nan(a) || is_nan(b))   e.exp_st[4] = 1'b1;
        end
      end
      2'd3: begin // CLASSIFY (S12, S13)
        e.exp_cls = fclass(a);
      end
    endcase
    expq.push_back(e);
  endtask

  // Issue one operation: predict, enqueue, drive.
  task automatic do_op(input logic [31:0] a, input logic [31:0] b,
                       input logic [1:0] op, input logic [2:0] mode);
    expect_op(a, b, op, mode);
    bfm_issue(a, b, op, mode);
    issued++;
  endtask

  // ---------------------------------------------------------------------------
  // Checker: retire in acceptance order (H2)
  // ---------------------------------------------------------------------------
  always @(posedge clk) begin
    if (rst_n && out_valid_o && out_ready_i) begin
      automatic exp_t e;
      if (expq.size() == 0) begin
        errors++;
        $display("H2: unexpected result with empty scoreboard (result=%h)", result_o);
      end else begin
        e = expq.pop_front();
        retired++;
        if (e.op == 2'd3) begin
          if (class_mask_o != e.exp_cls) begin
            errors++;
            $display("S12: CLASSIFY a=%h class=%b expected=%b", e.a, class_mask_o, e.exp_cls);
          end
          if (status_o != 5'h0) begin
            errors++;
            $display("S13/S14: CLASSIFY a=%h status=%b expected 0", e.a, status_o);
          end
        end else begin
          if (result_o != e.exp_res) begin
            errors++;
            $display("op=%0d mode=%0d a=%h b=%h: result=%h expected=%h (S1/S3/S4/S5/S7)",
                     e.op, e.mode, e.a, e.b, result_o, e.exp_res);
          end
          if (status_o != e.exp_st) begin
            errors++;
            $display("S6/S8/S9/S14: op=%0d mode=%0d a=%h b=%h status=%b expected=%b",
                     e.op, e.mode, e.a, e.b, status_o, e.exp_st);
          end
        end
      end
    end
  end

  // ---------------------------------------------------------------------------
  // Stimulus
  // ---------------------------------------------------------------------------
  logic [31:0] sgnj_a [8];
  logic [31:0] pair_a [20];
  logic [31:0] pair_b [20];
  logic [31:0] cls_v  [10];
  int i, j, k;

  initial begin
    in_valid_i  = 1'b0;
    out_ready_i = 1'b1;
    operand_a_i = 32'h0;
    operand_b_i = 32'h0;
    op_i        = 2'd0;
    op_mode_i   = 3'd0;

    bfm_reset(4);

    // ---- SGNJ (S1, S2): every a value incl. NaNs, both b signs, 3 modes ----
    sgnj_a[0]=32'h3F80_0000; sgnj_a[1]=32'h7FC0_0000; sgnj_a[2]=32'h7F80_0001;
    sgnj_a[3]=32'h8000_0000; sgnj_a[4]=32'h7F80_0000; sgnj_a[5]=32'h0000_0001;
    sgnj_a[6]=32'hFF7F_FFFF; sgnj_a[7]=32'hFFC0_0000;
    for (i = 0; i < 8; i++) begin
      for (j = 0; j < 2; j++) begin
        for (k = 0; k < 3; k++) begin
          do_op(sgnj_a[i], j ? 32'h8000_0000 : 32'h0000_0000, 2'd0, k[2:0]);
        end
      end
    end

    // ---- backpressure round 1 (H3): stall the sink while issuing ----
    bfm_out_ready(1'b0);
    for (i = 0; i < 6; i++)
      do_op(32'h3F80_0000 + i, 32'hBF80_0000 + i, 2'd1, i[0] ? 3'd1 : 3'd0);
    repeat (30) @(posedge clk);          // >20 stall cycles
    bfm_out_ready(1'b1);

    // ---- MINMAX (S3-S6) ----
    pair_a[0]=32'h8000_0000;  pair_b[0]=32'h0000_0000;  // -0 vs +0
    pair_a[1]=32'h0000_0000;  pair_b[1]=32'h8000_0000;
    pair_a[2]=32'hFF80_0000;  pair_b[2]=32'h7F80_0000;  // -inf vs +inf
    pair_a[3]=32'h7F80_0000;  pair_b[3]=32'hFF80_0000;
    pair_a[4]=32'h3F80_0000;  pair_b[4]=32'h40_00_0000; // 1.0 vs 2.0
    pair_a[5]=32'hBF80_0000;  pair_b[5]=32'h3F80_0000;  // -1.0 vs 1.0
    pair_a[6]=32'h8000_0001;  pair_b[6]=32'h0000_0001;  // subnormals
    pair_a[7]=32'h7FC0_0000;  pair_b[7]=32'h3F80_0000;  // qNaN vs 1.0
    pair_a[8]=32'h3F80_0000;  pair_b[8]=32'h7FC0_0000;
    pair_a[9]=32'h7F80_0001;  pair_b[9]=32'h3F80_0000;  // sNaN vs 1.0
    pair_a[10]=32'h3F80_0000; pair_b[10]=32'h7F80_0001;
    pair_a[11]=32'h7FC0_0000; pair_b[11]=32'h7F80_0001;  // qNaN vs sNaN
    pair_a[12]=32'h7F80_0001; pair_b[12]=32'hFFC0_0000; // sNaN vs -qNaN
    pair_a[13]=32'h7FC0_0000; pair_b[13]=32'hFFC0_0000; // qNaN vs qNaN
    pair_a[14]=32'h8000_0000; pair_b[14]=32'h8000_0000; // -0 vs -0
    pair_a[15]=32'h0000_0000; pair_b[15]=32'h0000_0000; // +0 vs +0
    pair_a[16]=32'hFF7F_FFFF; pair_b[16]=32'h7F7F_FFFF;
    pair_a[17]=32'h007F_FFFF; pair_b[17]=32'h0080_0000; // largest sub vs min normal
    pair_a[18]=32'h7F7F_FFFF; pair_b[18]=32'hFF80_0000;
    pair_a[19]=32'h0000_0001; pair_b[19]=32'h8000_0000;
    for (i = 0; i < 20; i++) begin
      do_op(pair_a[i], pair_b[i], 2'd1, 3'd0);
      do_op(pair_a[i], pair_b[i], 2'd1, 3'd1);
    end

    // ---- backpressure round 2 (H3) ----
    bfm_out_ready(1'b0);
    for (i = 0; i < 5; i++)
      do_op(32'h4040_0000, 32'hC040_0000, 2'd2, i[1:0] % 3);
    repeat (25) @(posedge clk);
    bfm_out_ready(1'b1);

    // ---- CMP (S7-S11) ----
    for (i = 0; i < 20; i++) begin
      do_op(pair_a[i], pair_b[i], 2'd2, 3'd0);
      do_op(pair_a[i], pair_b[i], 2'd2, 3'd1);
      do_op(pair_a[i], pair_b[i], 2'd2, 3'd2);
    end
    do_op(32'h0000_0000, 32'h8000_0000, 2'd2, 3'd2); // S10: +0 == -0
    do_op(32'h8000_0000, 32'h0000_0000, 2'd2, 3'd2);

    // ---- CLASSIFY (S12, S13): one value per class ----
    cls_v[0]=32'hFF80_0000; cls_v[1]=32'h8080_0000; cls_v[2]=32'h8000_0001;
    cls_v[3]=32'h8000_0000; cls_v[4]=32'h0000_0000; cls_v[5]=32'h0000_0001;
    cls_v[6]=32'h0080_0000; cls_v[7]=32'h7F80_0000; cls_v[8]=32'h7F80_0001;
    cls_v[9]=32'h7FC0_0000;
    for (i = 0; i < 10; i++)
      do_op(cls_v[i], 32'hDEAD_BEEF, 2'd3, 3'd0);

    // ---- random cross-product (all valid op/mode combos) ----
    for (i = 0; i < 400; i++) begin
      automatic logic [31:0] ra, rb;
      automatic int sel;
      automatic logic [1:0] rop;
      automatic logic [2:0] rmode;
      ra  = $urandom();
      rb  = $urandom();
      sel = $urandom_range(0, 8);
      case (sel)
        0: begin rop = 2'd0; rmode = 3'd0; end
        1: begin rop = 2'd0; rmode = 3'd1; end
        2: begin rop = 2'd0; rmode = 3'd2; end
        3: begin rop = 2'd1; rmode = 3'd0; end
        4: begin rop = 2'd1; rmode = 3'd1; end
        5: begin rop = 2'd2; rmode = 3'd0; end
        6: begin rop = 2'd2; rmode = 3'd1; end
        7: begin rop = 2'd2; rmode = 3'd2; end
        8: begin rop = 2'd3; rmode = 3'd0; end
      endcase
      do_op(ra, rb, rop, rmode);
    end

    // ---- drain (H2: every accepted op produces exactly one result) ----
    bfm_idle();
    begin
      automatic int guard;
      guard = 0;
      while (expq.size() > 0 && guard < 5000) begin
        @(posedge clk);
        guard++;
      end
      if (expq.size() > 0) begin
        errors++;
        $display("H2: %0d result(s) never delivered", expq.size());
      end
    end

    // ---- S15: work in flight is discarded by reset ----
    bfm_out_ready(1'b0);
    bfm_issue(32'h3F80_0000, 32'h40_00_0000, 2'd1, 3'd0); // accepted, undeliverable
    bfm_idle();
    bfm_reset(4);
    @(posedge clk);                       // first cycle after release
    if (out_valid_o) begin
      errors++;
      $display("S15: out_valid_o high on first cycle after reset release");
    end
    bfm_out_ready(1'b1);
    repeat (20) begin
      @(posedge clk);
      if (out_valid_o) begin
        errors++;
        $display("S15: result delivered after reset (discarded work survived)");
      end
    end

    if (errors == 0)
      $display("RESULT: PASS");
    else
      $display("RESULT: FAIL");
    $finish;
  end

endmodule
