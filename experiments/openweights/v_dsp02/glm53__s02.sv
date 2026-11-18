module fp_noncomp_tb;

  // ---- DUT connections ------------------------------------------------------
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
    .result_o(result_o), .class_mask_o(class_mask_o),
    .status_o(status_o),
    .out_valid_o(out_valid_o), .out_ready_i(out_ready_i)
  );

  // ---- scoreboard ------------------------------------------------------------
  typedef struct packed {
    logic [31:0] res;
    logic [9:0]  cls;
    logic [4:0]  sts;
    logic        is_cls;
    logic [1:0]  op;
    logic [2:0]  mode;
  } exp_t;

  exp_t exp_q[$];
  int   err_cnt  = 0;
  int   stall_cycles = 0;
  logic forced_stall = 0;

  // ---- reference model helpers ------------------------------------------------
  function automatic logic is_nan(input logic [31:0] x);
    return (x[30:23] == 8'hFF) && (x[22:0] != 23'd0);
  endfunction

  function automatic logic is_snan(input logic [31:0] x);
    return (x[30:23] == 8'hFF) && (x[22:0] != 23'd0) && (x[22] == 1'b0);
  endfunction

  // a <= b under total order with -0 < +0 (S3), non-NaN operands assumed
  function automatic logic le_ord(input logic [31:0] a, input logic [31:0] b);
    if (a[31] != b[31]) return a[31];
    return a[30:0] <= b[30:0];
  endfunction

  // a < b, non-NaN operands assumed, -0 and +0 equal (S10)
  function automatic logic lt_val(input logic [31:0] a, input logic [31:0] b);
    if (a[31] != b[31]) return a[31];
    if (a[31]) return a[30:0] > b[30:0];
    return a[30:0] < b[30:0];
  endfunction

  function automatic logic [9:0] fclass(input logic [31:0] a);
    if (a[30:23] == 8'hFF) begin
      if (a[22:0] == 23'd0) return a[31] ? 10'd1 << 0 : 10'd1 << 7;
      else if (a[22] == 1'b0) return 10'd1 << 8; // signalling NaN (A3)
      else return 10'd1 << 9;                    // quiet NaN (A3)
    end else if (a[30:23] == 8'd0) begin
      if (a[22:0] == 23'd0) return a[31] ? 10'd1 << 3 : 10'd1 << 4;
      else return a[31] ? 10'd1 << 2 : 10'd1 << 5;
    end else begin
      return a[31] ? 10'd1 << 1 : 10'd1 << 6;
    end
  endfunction

  function automatic exp_t mk(input logic [31:0] a, input logic [31:0] b,
                              input logic [1:0] op, input logic [2:0] mode);
    exp_t e;
    logic na, nb, sa, sb;
    logic eqv, ltv, boolv, nv;
    logic [31:0] r;
    na = is_nan(a); nb = is_nan(b);
    sa = is_snan(a); sb = is_snan(b);
    e.res = 32'd0; e.cls = 10'd0; e.sts = 5'd0; e.is_cls = 1'b0;
    e.op = op; e.mode = mode;
    case (op)
      2'd0: begin // SGNJ (S1, S2)
        case (mode)
          3'd0: e.res = {b[31],           a[30:0]};
          3'd1: e.res = {~b[31],          a[30:0]};
          default: e.res = {a[31] ^ b[31], a[30:0]};
        endcase
      end
      2'd1: begin // MINMAX (S3-S6)
        if (na && nb)      r = 32'h7FC0_0000;      // S5, A2
        else if (na)       r = b;                    // S4
        else if (nb)       r = a;                    // S4
        else if (mode == 3'd0) r = le_ord(a, b) ? a : b; // min, S3
        else                  r = le_ord(b, a) ? a : b; // max, S3
        e.res = r;
        if (sa || sb) e.sts[4] = 1'b1;               // S6
      end
      2'd2: begin // CMP (S7-S11)
        eqv = (!na && !nb) &&
              ((a == b) || ((a[30:23]==8'd0)&&(a[22:0]==23'd0)&&
                            (b[30:23]==8'd0)&&(b[22:0]==23'd0))); // S10
        ltv = (!na && !nb) && lt_val(a, b);
        case (mode)
          3'd0: begin boolv = ltv || eqv; nv = na || nb; end // S8
          3'd1: begin boolv = ltv;        nv = na || nb; end // S8
          default: begin boolv = eqv;     nv = sa || sb; end // S9
        endcase
        e.res = boolv ? 32'h0000_0001 : 32'h0000_0000; // S7
        if (nv) e.sts[4] = 1'b1;
      end
      default: begin // CLASSIFY (S12, S13)
        e.is_cls = 1'b1;
        e.cls    = fclass(a);
      end
    endcase
    return e;
  endfunction

  // ---------------------------------------------------------------------------
  // PROVIDED PLUMBING
  // ---------------------------------------------------------------------------
  initial begin clk = 1'b0; forever #5 clk = ~clk; end

  logic rst_n_init_done;
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

  // ---- result-side ready with backpressure (H3) -------------------------------
  always @(negedge clk) begin
    if (!out_ready_i) stall_cycles++;
    if (forced_stall || (stall_cycles < 20))
      out_ready_i <= 1'b0;
    else
      out_ready_i <= ($urandom_range(0, 3) != 0);
  end

  // ---- checker ----------------------------------------------------------------
  exp_t ck_e;
  always @(posedge clk) begin
    if (rst_n && out_valid_o && out_ready_i) begin
      if (exp_q.size() == 0) begin
        $display("FAIL H2: spurious result with no operation outstanding (t=%0t)", $time);
        err_cnt++;
      end else begin
        ck_e = exp_q.pop_front();
        if (status_o !== ck_e.sts) begin
          $display("FAIL S14: op=%0d mode=%0d status=%05b expected=%05b (t=%0t)",
                   ck_e.op, ck_e.mode, status_o, ck_e.sts, $time);
          err_cnt++;
        end
        if (ck_e.is_cls) begin
          if (class_mask_o !== ck_e.cls) begin
            $display("FAIL S12: FCLASS a=%08h mask=%010b expected=%010b (t=%0t)",
                     operand_a_i, class_mask_o, ck_e.cls, $time);
            err_cnt++;
          end
        end else begin
          if (result_o !== ck_e.res) begin
            $display("FAIL: op=%0d mode=%0d a=%08h b=%08h result=%08h expected=%08h (t=%0t)",
                     ck_e.op, ck_e.mode, operand_a_i, operand_b_i,
                     result_o, ck_e.res, $time);
            err_cnt++;
          end
        end
      end
    end
  end

  // ---- drain with bounded wait -------------------------------------------------
  task automatic drain();
    int w;
    w = 0;
    while ((exp_q.size() > 0) && (w < 20000)) begin
      @(posedge clk);
      w++;
    end
    if (exp_q.size() > 0) begin
      $display("FAIL H2: results not delivered (stuck, %0d outstanding)", exp_q.size());
      err_cnt++;
    end else begin
      repeat (30) @(posedge clk);
    end
  endtask

  // ---- stimulus ------------------------------------------------------------------
  logic [31:0] vals [];
  int          nvals;
  exp_t        e;
  int          i, j, k;
  logic [1:0]  ops [4];
  int          nmodes [4];

  initial begin
    ops    = '{2'd0, 2'd1, 2'd2, 2'd3};
    nmodes = '{3, 2, 3, 1};

    vals = '{
      32'h0000_0000, // +0
      32'h8000_0000, // -0
      32'h3F80_0000, //  1.0
      32'hBF80_0000, // -1.0
      32'h4000_0000, //  2.0
      32'hC000_0000, // -2.0
      32'h3EAA_AAAA, //  ~0.333
      32'hBE4C_CCCD, // ~-0.333
      32'h4120_0000, // 10.0
      32'h7F7F_FFFF, // max finite
      32'hFF7F_FFFF, // -max finite
      32'h0080_0000, // min normal
      32'h8080_0000, // -min normal
      32'h0000_0001, // +subnormal
      32'h8000_0001, // -subnormal
      32'h0000_1234, // +subnormal
      32'h7F80_0000, // +inf
      32'hFF80_0000, // -inf
      32'h7FC0_0000, // canonical qNaN
      32'hFFC0_0000, // -qNaN
      32'h7FA0_0000, // qNaN (payload bit22=1)
      32'h7F80_0001, // sNaN
      32'hFF80_0001, // -sNaN
      32'h7F80_0100, // sNaN (payload bit22=0)
      32'h3F00_0000, // 0.5
      32'hBF00_0000, // -0.5
      32'h0000_0000  // filler (replaced below)
    };
    nvals = 26;
    for (i = 0; i < 8; i++)
      vals[nvals + i] = $urandom();
    nvals = nvals + 8;

    bfm_reset(4);

    // main sweep: every (pair, op, mode)
    for (i = 0; i < nvals; i++) begin
      for (j = 0; j < nvals; j++) begin
        for (k = 0; k < 4; k++) begin
          for (int m = 0; m < nmodes[k]; m++) begin
            e = mk(vals[i], vals[j], ops[k], m[2:0]);
            exp_q.push_back(e);
            bfm_issue(vals[i], vals[j], ops[k], m[2:0]);
          end
        end
      end
    end

    bfm_idle();
    drain();

    // ---- reset test (S15) ----
    @(negedge clk);
    forced_stall = 1'b1;
    bfm_issue(32'h3F80_0000, 32'hBF80_0000, 2'd1, 3'd0); // accepted, no result expected
    bfm_reset(4);
    // first cycle after release: out_valid must be low
    @(posedge clk);
    if (out_valid_o !== 1'b0) begin
      $display("FAIL S15: out_valid high on first cycle after reset release");
      err_cnt++;
    end
    // no discarded result may ever appear
    for (i = 0; i < 100; i++) begin
      @(posedge clk);
      if (out_valid_o !== 1'b0) begin
        $display("FAIL S15: result delivered for operation discarded by reset");
        err_cnt++;
      end
    end

    // ---- design must still work after reset ----
    @(negedge clk);
    forced_stall = 0;
    e = mk(32'h3F80_0000, 32'h3F80_0000, 2'd2, 3'd2);
    exp_q.push_back(e);
    bfm_issue(32'h3F80_0000, 32'h3F80_0000, 2'd2, 3'd2);
    e = mk(32'h8000_0000, 32'h0000_0000, 2'd0, 3'd0);
    exp_q.push_back(e);
    bfm_issue(32'h8000_0000, 32'h0000_0000, 2'd0, 3'd0);
    e = mk(32'h7F80_0001, 32'h3F80_0000, 2'd3, 3'd0);
    exp_q.push_back(e);
    bfm_issue(32'h7F80_0001, 32'h3F80_0000, 2'd3, 3'd0);
    bfm_idle();
    drain();

    if (stall_cycles < 20) begin
      $display("FAIL H3: insufficient backpressure applied (%0d stall cycles)", stall_cycles);
      err_cnt++;
    end

    if (err_cnt == 0)
      $display("RESULT: PASS");
    else
      $display("RESULT: FAIL");
    $finish;
  end

endmodule
