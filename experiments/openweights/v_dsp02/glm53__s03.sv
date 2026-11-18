// ---------------------------------------------------------------------------
// fp_noncomp_tb -- self-checking testbench for the fp_noncomp contract
// ---------------------------------------------------------------------------
module fp_noncomp_tb;

  // ---- DUT connections ------------------------------------------------------
  logic        clk;
  logic        rst_n;
  logic [31:0] operand_a_i;
  logic [31:0] operand_b_i;
  logic [1:0]  op_i;
  logic [2:0]  op_mode_i;
  logic        in_valid_i  = 1'b0;
  logic        in_ready_o;
  logic [31:0] result_o;
  logic [9:0]  class_mask_o;
  logic [4:0]  status_o;
  logic        out_valid_o;
  logic        out_ready_i = 1'b1;

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

  logic rst_n_probe; // (unused, keeps structure clear)
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
  // Golden model
  // ---------------------------------------------------------------------------
  function automatic logic f_isnan (input logic [31:0] x);
    return (x[30:23] == 8'hFF) && (x[22:0] != 23'h0);
  endfunction

  function automatic logic f_issnan(input logic [31:0] x);
    return f_isnan(x) && !x[22];
  endfunction

  function automatic logic f_iszero(input logic [31:0] x);
    return (x[30:23] == 8'h00) && (x[22:0] == 23'h0);
  endfunction

  // strict less-than for CMP: -0 and +0 compare equal (S10)
  function automatic logic f_lt_ordered(input logic [31:0] a, input logic [31:0] b);
    if (f_iszero(a) && f_iszero(b)) return 1'b0;
    if (a[31] != b[31])             return a[31];
    if (!a[31])                     return (a[30:0] < b[30:0]);
    return (a[30:0] > b[30:0]);
  endfunction

  // less-than for MINMAX: -0.0 < +0.0 (S3)
  function automatic logic f_lt_minmax(input logic [31:0] a, input logic [31:0] b);
    if (f_iszero(a) && f_iszero(b)) return a[31] && !b[31];
    if (a[31] != b[31])             return a[31];
    if (!a[31])                     return (a[30:0] < b[30:0]);
    return (a[30:0] > b[30:0]);
  endfunction

  function automatic logic f_eq(input logic [31:0] a, input logic [31:0] b);
    return (a == b) || (f_iszero(a) && f_iszero(b));
  endfunction

  function automatic logic [9:0] f_class(input logic [31:0] x);
    if ((x[30:23] == 8'hFF) && (x[22:0] == 23'h0))
      return x[31] ? 10'h001 : 10'h080;                     // -inf / +inf
    if (x[30:23] == 8'hFF)
      return x[22] ? 10'h200 : 10'h100;                     // qNaN / sNaN
    if ((x[30:23] == 8'h00) && (x[22:0] == 23'h0))
      return x[31] ? 10'h008 : 10'h010;                     // -0 / +0
    if (x[30:23] == 8'h00)
      return x[31] ? 10'h004 : 10'h020;                     // -sub / +sub
    return x[31] ? 10'h002 : 10'h040;                       // -norm / +norm
  endfunction

  typedef struct packed {
    logic [31:0] res;
    logic [9:0]  cls;
    logic [4:0]  sts;
    logic [1:0]  op;
  } exp_t;

  function automatic exp_t f_golden(input logic [31:0] a,
                                    input logic [31:0] b,
                                    input logic [1:0]  op,
                                    input logic [2:0]  mode);
    exp_t e;
    e = '0;
    e.op = op;
    case (op)
      2'd0: begin // SGNJ (S1, S2)
        case (mode)
          3'd0: e.res = {b[31],       a[30:0]};
          3'd1: e.res = {~b[31],      a[30:0]};
          3'd2: e.res = {a[31]^b[31], a[30:0]};
          default: e.res = a;
        endcase
        e.sts = 5'h00;
      end
      2'd1: begin // MINMAX (S3-S6)
        if (f_isnan(a) && f_isnan(b))
          e.res = 32'h7FC0_0000;
        else if (f_isnan(a))
          e.res = b;
        else if (f_isnan(b))
          e.res = a;
        else if (mode == 3'd0)
          e.res = f_lt_minmax(a, b) ? a : b;
        else
          e.res = f_lt_minmax(b, a) ? a : b;
        e.sts = (f_issnan(a) || f_issnan(b)) ? 5'h10 : 5'h00;
      end
      2'd2: begin // CMP (S7-S11)
        if (f_isnan(a) || f_isnan(b)) begin
          e.res = 32'h0;
          if (mode == 3'd2)
            e.sts = (f_issnan(a) || f_issnan(b)) ? 5'h10 : 5'h00; // S9
          else
            e.sts = 5'h10;                                       // S8
        end else begin
          case (mode)
            3'd0: e.res = (f_lt_ordered(a, b) || f_eq(a, b)) ? 32'h1 : 32'h0;
            3'd1: e.res = f_lt_ordered(a, b) ? 32'h1 : 32'h0;
            3'd2: e.res = f_eq(a, b) ? 32'h1 : 32'h0;
            default: e.res = 32'h0;
          endcase
          e.sts = 5'h00;
        end
      end
      2'd3: begin // CLASSIFY (S12, S13)
        e.cls = f_class(a);
        e.sts = 5'h00;
      end
    endcase
    return e;
  endfunction

  // ---------------------------------------------------------------------------
  // Scoreboard / checker
  // ---------------------------------------------------------------------------
  int  errcount = 0;
  int  sent = 0;
  int  recv = 0;
  exp_t exp_q[$];

  task automatic fail(input string req, input string msg);
    errcount++;
    $display("FAIL %0s: %0s", req, msg);
  endtask

  always @(posedge clk) begin
    automatic exp_t e;
    if (!rst_n) begin
      if (out_valid_o !== 1'b0)
        fail("S15", "out_valid high while in reset");
    end else begin
      // H1: acceptance -- inputs are driven at the negative edge, stable here
      if (in_valid_i && in_ready_o) begin
        e = f_golden(operand_a_i, operand_b_i, op_i, op_mode_i);
        exp_q.push_back(e);
        sent++;
      end
      // H2: delivery, in order
      if (out_valid_o && out_ready_i) begin
        if (exp_q.size() == 0) begin
          fail("H2", "result delivered with no operation pending");
        end else begin
          e = exp_q.pop_front();
          recv++;
          if (e.op == 2'd3) begin
            if (class_mask_o !== e.cls)
              fail("S12", $sformatf("class_mask %b expected %b", class_mask_o, e.cls));
          end else begin
            if (result_o !== e.res)
              fail(e.op == 2'd0 ? "S1" : (e.op == 2'd1 ? "S3" : "S7"),
                   $sformatf("result %h expected %h", result_o, e.res));
          end
          if (status_o !== e.sts)
            fail(e.op == 2'd0 ? "S2" : (e.op == 2'd1 ? "S6" :
                 (e.op == 2'd2 ? "S11" : "S13")),
                 $sformatf("status %b expected %b", status_o, e.sts));
        end
      end
    end
  end

  // ---------------------------------------------------------------------------
  // Stimulus
  // ---------------------------------------------------------------------------
  logic [31:0] vals [0:19];

  initial begin : main
    automatic int guard;

    vals[ 0] = 32'h7F80_0000; // +inf
    vals[ 1] = 32'hFF80_0000; // -inf
    vals[ 2] = 32'h0000_0000; // +0
    vals[ 3] = 32'h8000_0000; // -0
    vals[ 4] = 32'h007F_FFFF; // +subnormal
    vals[ 5] = 32'h807F_FFFF; // -subnormal
    vals[ 6] = 32'h0080_0000; // +min normal
    vals[ 7] = 32'h8080_0000; // -min normal
    vals[ 8] = 32'h3F80_0000; // +1.0
    vals[ 9] = 32'hBF80_0000; // -1.0
    vals[10] = 32'h7F7F_FFFF; // +max finite
    vals[11] = 32'hFF7F_FFFF; // -max finite
    vals[12] = 32'h7FC0_0000; // +qNaN
    vals[13] = 32'hFFC0_0000; // -qNaN
    vals[14] = 32'h7F80_0001; // +sNaN
    vals[15] = 32'hFF80_0001; // -sNaN
    vals[16] = 32'h7FA0_0000; // +sNaN (payload in low bits)
    vals[17] = 32'h4049_0FDB; // +pi
    vals[18] = 32'hC049_0FDB; // -pi
    vals[19] = 32'h3F40_0000; // +0.75

    // ---- reset, then S15 post-release check ---------------------------------
    bfm_reset(4);
    @(negedge clk);
    if (out_valid_o !== 1'b0)
      fail("S15", "out_valid not low on first cycle after reset release");

    // ---- backpressure phase (H3): accept one op, then stall the sink --------
    bfm_issue(32'h3F80_0000, 32'hC049_0FDB, 2'd1, 3'd0); // min(1.0, -pi)
    bfm_out_ready(1'b0);
    repeat (30) @(negedge clk);          // >= 20 stall cycles with a result pending
    bfm_out_ready(1'b1);
    guard = 0;
    while ((exp_q.size() > 0) && (guard < 2000)) begin
      @(negedge clk); guard++;
    end
    if (exp_q.size() > 0)
      fail("H2", "result not delivered after backpressure released");

    // ---- full cross-product sweep ------------------------------------------
    for (int i = 0; i < 20; i++) begin
      for (int j = 0; j < 20; j++) begin
        bfm_issue(vals[i], vals[j], 2'd0, 3'd0); // SGNJ
        bfm_issue(vals[i], vals[j], 2'd0, 3'd1); // SGNJN
        bfm_issue(vals[i], vals[j], 2'd0, 3'd2); // SGNJX
        bfm_issue(vals[i], vals[j], 2'd1, 3'd0); // FMIN
        bfm_issue(vals[i], vals[j], 2'd1, 3'd1); // FMAX
        bfm_issue(vals[i], vals[j], 2'd2, 3'd0); // FLE
        bfm_issue(vals[i], vals[j], 2'd2, 3'd1); // FLT
        bfm_issue(vals[i], vals[j], 2'd2, 3'd2); // FEQ
        bfm_issue(vals[i], vals[j], 2'd3, 3'd0); // FCLASS
      end
      // periodic short stalls (H3)
      if ((i % 5) == 2) begin
        bfm_out_ready(1'b0);
        repeat (5) @(negedge clk);
        bfm_out_ready(1'b1);
      end
    end

    // ---- drain ---------------------------------------------------------------
    bfm_idle();
    guard = 0;
    while ((exp_q.size() > 0) && (guard < 20000)) begin
      @(negedge clk); guard++;
    end
    if (exp_q.size() > 0)
      fail("H2", "results lost or never delivered");

    // ---- mid-flight reset (S15): in-flight work must be discarded ------------
    bfm_issue(vals[8],  vals[9],  2'd1, 3'd1);
    bfm_issue(vals[9],  vals[8],  2'd1, 3'd0);
    bfm_issue(vals[2],  vals[3],  2'd2, 3'd2);
    bfm_issue(vals[12], vals[14], 2'd2, 3'd1);
    bfm_issue(vals[0],  vals[3],  2'd3, 3'd0);
    bfm_idle();
    repeat (3) @(negedge clk);
    bfm_reset(3);
    exp_q.delete();                       // anything still in flight is discarded
    @(negedge clk);
    if (out_valid_o !== 1'b0)
      fail("S15", "out_valid high after mid-test reset");
    repeat (10) begin
      @(negedge clk);
      if (out_valid_o !== 1'b0)
        fail("S15", "stale result delivered after reset");
    end

    // ---- verdict ---------------------------------------------------------------
    $display("Checked %0d results, %0d errors.", recv, errcount);
    if (errcount == 0)
      $display("RESULT: PASS");
    else
      $display("RESULT: FAIL");
    $finish;
  end

endmodule
