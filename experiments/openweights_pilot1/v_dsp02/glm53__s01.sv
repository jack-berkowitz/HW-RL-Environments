// ---------------------------------------------------------------------------
// fp_noncomp_tb -- self-checking testbench for the fp_noncomp binary32
// non-computational unit (SGNJ / MINMAX / CMP / CLASSIFY).
//
// Checks are grounded in the numbered requirements S1..S16, H1..H4, A1..A3.
// Results are identified by bookkeeping (a FIFO scoreboard keyed to the
// acceptance order, H2), never by matching on values.
// ---------------------------------------------------------------------------
module fp_noncomp_tb;

  // -------------------------------------------------------------------------
  // TB-side copies of the DUT ports.
  // Driven only from the negedge (the edge opposite to the one that samples),
  // never from the rising edge.
  // -------------------------------------------------------------------------
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

  // ---- watchdog (S16) --------------------------------------------------------
  initial begin
    #200_000_000;
    $display("RESULT: FAIL (watchdog: no forward progress)");
    $finish;
  end

  // -------------------------------------------------------------------------
  // Scoreboard bookkeeping.
  // -------------------------------------------------------------------------
  typedef struct packed {
    logic [31:0] res;   // expected result_o       (CLASSIFY: not checked, latitude 4)
    logic [9:0]  cls;   // expected class_mask_o   (non-CLASSIFY: not checked, latitude 5)
    logic [4:0]  sts;   // expected status_o      (S14: checked for every op)
    logic [1:0]  op;
    logic [2:0]  mode;
    logic [1:0]  cid;   // NaN-case id, for precise diagnostics
  } exp_t;

  exp_t exp_q[$];       // expectations in acceptance order (H2)
  exp_t mon_e;

  int unsigned n_fails;
  int unsigned n_ops;
  int unsigned n_results;
  int unsigned total_stall;

  localparam int NVALS = 19;
  logic [31:0] vals [0:NVALS-1];

  int          i, j, k;
  logic [31:0] ra, rb;
  logic [1:0]  rop;
  logic [2:0]  rmode;

  // -------------------------------------------------------------------------
  // DUT
  // -------------------------------------------------------------------------
  fp_noncomp dut (
    .clk_i         (clk),
    .rst_ni        (rst_n),
    .operand_a_i   (operand_a_i),
    .operand_b_i   (operand_b_i),
    .op_i          (op_i),
    .op_mode_i     (op_mode_i),
    .in_valid_i    (in_valid_i),
    .in_ready_o    (in_ready_o),
    .result_o      (result_o),
    .class_mask_o  (class_mask_o),
    .status_o      (status_o),
    .out_valid_o   (out_valid_o),
    .out_ready_i   (out_ready_i)
  );

  // -------------------------------------------------------------------------
  // Reference model helpers.
  // -------------------------------------------------------------------------
  // A1: binary32 = sign | biased exp | trailing significand.
  // A3: sNaN iff exp==0xFF, frac!=0, bit22==0.
  function automatic logic f_is_nan(input logic [31:0] x);
    f_is_nan = (x[30:23] == 8'hFF) && (x[22:0] != 23'h0);
  endfunction

  function automatic logic f_is_snan(input logic [31:0] x);
    f_is_snan = (x[30:23] == 8'hFF) && (x[22:0] != 23'h0) && !x[22];
  endfunction

  function automatic logic f_is_zero(input logic [31:0] x);
    f_is_zero = (x[30:23] == 8'h00) && (x[22:0] == 23'h0);
  endfunction

  // Total order over non-NaN binary32 (zeros compare equal here; S10).
  function automatic logic signed [32:0] f_key(input logic [31:0] x);
    logic signed [32:0] m;
    m = $signed({1'b0, x[30:0]});
    f_key = x[31] ? -m : m;
  endfunction

  // Expected outputs for one operation (S1..S14).
  function automatic exp_t f_model(input logic [31:0] a, input logic [31:0] b,
                                   input logic [1:0] op, input logic [2:0] mode);
    exp_t e;
    logic signed [32:0] ka, kb;
    e.res  = 32'h0;
    e.cls  = 10'h0;
    e.sts  = 5'h0;          // S14: DZ/OF/UF/NX are always zero
    e.op   = op;
    e.mode = mode;
    e.cid  = 2'h0;
    ka = f_key(a);
    kb = f_key(b);
    case (op)
      2'd0: begin // SGNJ (S1, S2)
        e.res = a;
        case (mode)
          3'd0: e.res[31] = b[31];
          3'd1: e.res[31] = ~b[31];
          3'd2: e.res[31] = a[31] ^ b[31];
          default: ; // never driven (latitude 6)
        endcase
      end
      2'd1: begin // MINMAX (S3..S6)
        if (f_is_nan(a) && f_is_nan(b)) begin
          e.res = 32'h7FC0_0000;      // S5 + A2: canonical quiet NaN
          e.cid = 2'd2;
        end else if (f_is_nan(a)) begin
          e.res = b;                  // S4: return the non-NaN operand
          e.cid = 2'd1;
        end else if (f_is_nan(b)) begin
          e.res = a;                  // S4
          e.cid = 2'd1;
        end else begin
          e.cid = 2'd0;
          if (f_is_zero(a) && f_is_zero(b)) begin
            // S3: -0.0 orders below +0.0 for MINMAX, in either operand order
            if (mode == 3'd0) e.res = a[31]  ? a : (b[31] ? b : a);
            else              e.res = (!a[31]) ? a : b;
          end else begin
            if (mode == 3'd0) e.res = (ka <= kb) ? a : b;
            else              e.res = (ka >= kb) ? a : b;
          end
        end
        if (f_is_snan(a) || f_is_snan(b)) e.sts = 5'h10; // S6
      end
      2'd2: begin // CMP (S7..S11)
        if (f_is_nan(a) || f_is_nan(b)) begin
          e.cid = 2'd1;
          e.res = 32'h0;              // any NaN -> false
          if (mode == 3'd2) begin     // S9: FEQ is quiet
            if (f_is_snan(a) || f_is_snan(b)) e.sts = 5'h10;
          end else begin              // S8: FLT/FLE are signalling
            e.sts = 5'h10;
          end
        end else begin
          e.cid = 2'd0;
          case (mode)
            3'd0: e.res = (ka <= kb) ? 32'h1 : 32'h0; // FLE
            3'd1: e.res = (ka <  kb) ? 32'h1 : 32'h0; // FLT
            3'd2: e.res = (ka == kb) ? 32'h1 : 32'h0; // FEQ (S10: +/-0 equal)
            default: e.res = 32'h0;
          endcase
        end
      end
      2'd3: begin // CLASSIFY (S12, S13); operand_b and op_mode ignored
        if (f_is_nan(a))            e.cls = a[22] ? 10'h200 : 10'h100;
        else if (a[30:23] == 8'hFF) e.cls = a[31] ? 10'h001 : 10'h080;
        else if (a[30:23] == 8'h00) begin
          if (a[22:0] == 23'h0) e.cls = a[31] ? 10'h008 : 10'h010;
          else                  e.cls = a[31] ? 10'h004 : 10'h020;
        end
        else                        e.cls = a[31] ? 10'h002 : 10'h040;
      end
      default: ;
    endcase
    f_model = e;
  endfunction

  function automatic logic [31:0] rnd_operand();
    int unsigned r;
    r = $urandom_range(0, 9);
    if (r < 4) rnd_operand = vals[$urandom_range(0, NVALS-1)];
    else        rnd_operand = $urandom();
  endfunction

  // -------------------------------------------------------------------------
  // Failure reporting.
  // -------------------------------------------------------------------------
  task automatic tb_fail(input string req, input string msg);
    n_fails = n_fails + 1;
    $display("FAIL %s: %s (time %0t)", req, msg, $time);
  endtask

  // -------------------------------------------------------------------------
  // Stimulus / handshake tasks.
  // -------------------------------------------------------------------------
  // Presents one operation at the negative edge, queues its expected result
  // before the first sampling edge (so a zero-latency design cannot race the
  // scoreboard), holds all inputs stable until acceptance (H4), then
  // withdraws valid at the next negative edge so no duplicate acceptance can
  // occur.
  task automatic do_op(input logic [31:0] a, input logic [31:0] b,
                       input logic [1:0] op, input logic [2:0] mode);
    exp_t e;
    int unsigned waited;
    e = f_model(a, b, op, mode);
    @(negedge clk);
    operand_a_i = a;
    operand_b_i = b;
    op_i        = op;
    op_mode_i   = mode;
    in_valid_i  = 1'b1;
    exp_q.push_back(e);
    waited = 0;
    forever begin
      @(posedge clk);
      if (in_ready_o === 1'b1) break; // H1: accepted on this edge
      waited = waited + 1;
      if (waited >= 100000) begin
        tb_fail("H1", "design never accepted an operation (in_ready_o never high)");
        $display("RESULT: FAIL");
        $finish;
      end
    end
    @(negedge clk);
    in_valid_i = 1'b0;
    n_ops = n_ops + 1;
  endtask

  // H3: hold the sink ready low for a bounded number of cycles.
  task automatic stall_out(input int unsigned cycles);
    @(negedge clk);
    out_ready_i = 1'b0;
    repeat (cycles) @(posedge clk);
    @(negedge clk);
    out_ready_i = 1'b1;
    total_stall = total_stall + cycles;
  endtask

  task automatic maybe_stall();
    int unsigned r;
    r = $urandom_range(0, 15);
    if (r < 3) stall_out($urandom_range(2, 6));
  endtask

  // Wait for all outstanding results; bounded so a broken design cannot
  // hang the run (S16). Any late/extra delivery is flagged by the monitor.
  task automatic wait_drain(input int unsigned max_cyc);
    int unsigned waited;
    waited = 0;
    while ((exp_q.size() > 0) && (waited < max_cyc)) begin
      @(posedge clk);
      waited = waited + 1;
    end
    if (exp_q.size() > 0) begin
      tb_fail("H2", $sformatf("no result for %0d outstanding operation(s) within %0d cycles",
                              exp_q.size(), max_cyc));
      exp_q.delete();
    end
    repeat (4) @(posedge clk);
  endtask

  // -------------------------------------------------------------------------
  // Output monitor / scoreboard.
  // A result is delivered on the rising edge where out_valid && out_ready
  // (H2). Values are read at that edge (pre-edge, i.e. the values offered
  // during the delivery cycle) and compared against the head of the FIFO,
  // which is the acceptance order (H2).
  // -------------------------------------------------------------------------
  always @(posedge clk) begin
    if (rst_n === 1'b1) begin
      if ((out_valid_o === 1'b1) && (out_ready_i === 1'b1)) begin
        if (exp_q.size() == 0) begin
          tb_fail("H2/S15", "result delivered with no operation outstanding");
        end else begin
          mon_e = exp_q.pop_front();
          n_results = n_results + 1;
          if (mon_e.op == 2'd0) begin
            if (result_o !== mon_e.res)
              tb_fail("S1", "SGNJ result mismatch (bits 30:0 must copy operand_a)");
            if (status_o !== mon_e.sts)
              tb_fail("S2/S14", "SGNJ status flags mismatch (must be zero)");
          end else if (mon_e.op == 2'd1) begin
            if (result_o !== mon_e.res) begin
              if (mon_e.cid == 2'd0)
                tb_fail("S3", "MINMAX result mismatch (non-NaN operands)");
              else if (mon_e.cid == 2'd1)
                tb_fail("S4", "MINMAX result mismatch (one NaN operand)");
              else
                tb_fail("S5", "MINMAX result mismatch (both NaN: canonical quiet NaN)");
            end
            if (status_o !== mon_e.sts)
              tb_fail("S6/S14", "MINMAX status flags mismatch (NV iff sNaN operand)");
          end else if (mon_e.op == 2'd2) begin
            if (result_o !== mon_e.res) begin
              if (mon_e.cid != 2'd0) begin
                if (mon_e.mode == 3'd2)
                  tb_fail("S9", "FEQ result mismatch with a NaN operand");
                else
                  tb_fail("S8", "FLT/FLE result mismatch with a NaN operand");
              end else begin
                tb_fail("S7/S10", "comparison result mismatch");
              end
            end
            if (status_o !== mon_e.sts) begin
              if (mon_e.mode == 3'd2)
                tb_fail("S9/S11/S14", "FEQ status flags mismatch");
              else
                tb_fail("S8/S11/S14", "FLT/FLE status flags mismatch");
            end
          end else begin
            if (class_mask_o !== mon_e.cls)
              tb_fail("S12", "CLASSIFY mask mismatch");
            if (status_o !== mon_e.sts)
              tb_fail("S13/S14", "CLASSIFY status flags mismatch (must be zero)");
          end
        end
      end
    end
  end

  // -------------------------------------------------------------------------
  // Main sequence.
  // -------------------------------------------------------------------------
  initial begin
    operand_a_i = 32'h0;
    operand_b_i = 32'h0;
    op_i        = 2'd0;
    op_mode_i   = 3'd0;
    in_valid_i  = 1'b0;
    out_ready_i = 1'b1;
    n_fails     = 0;
    n_ops       = 0;
    n_results   = 0;
    total_stall = 0;
    exp_q.delete();

    vals[0]  = 32'hFF800000;  // -infinity
    vals[1]  = 32'hFF000001;  // -large normal
    vals[2]  = 32'hBF800000;  // -1.0
    vals[3]  = 32'h807FFFFF;  // -max subnormal
    vals[4]  = 32'h80000001;  // -min subnormal
    vals[5]  = 32'h80000000;  // -zero
    vals[6]  = 32'h00000000;  // +zero
    vals[7]  = 32'h00000001;  // +min subnormal
    vals[8]  = 32'h007FFFFF;  // +max subnormal
    vals[9]  = 32'h3F800000;  // +1.0
    vals[10] = 32'h3F400000;  // +0.75
    vals[11] = 32'h40490FDB;  // +pi
    vals[12] = 32'h7F000001;  // +large normal
    vals[13] = 32'h7F800000;  // +infinity
    vals[14] = 32'h7FC00000;  // canonical quiet NaN (A2)
    vals[15] = 32'h7FC00001;  // +quiet NaN with payload
    vals[16] = 32'hFFC00001;  // -quiet NaN with payload
    vals[17] = 32'h7FA00000;  // +signalling NaN (A3)
    vals[18] = 32'hFFA00000;  // -signalling NaN (A3)

    // ---- initial reset and S15 ------------------------------------------
    bfm_reset(4);
    @(posedge clk);
    @(negedge clk);
    if (out_valid_o !== 1'b0)
      tb_fail("S15", "out_valid_o high on first cycle after initial reset release");

    // ---- directed smoke tests -------------------------------------------
    // MINMAX basics (S3)
    do_op(32'h3F800000, 32'hBF800000, 2'd1, 3'd0); // min(+1,-1) = -1
    do_op(32'h3F800000, 32'hBF800000, 2'd1, 3'd1); // max(+1,-1) = +1
    // MINMAX signed zeros, both operand orders (S3)
    do_op(32'h80000000, 32'h00000000, 2'd1, 3'd0); // min(-0,+0) = -0
    do_op(32'h00000000, 32'h80000000, 2'd1, 3'd0); // min(+0,-0) = -0
    do_op(32'h80000000, 32'h00000000, 2'd1, 3'd1); // max(-0,+0) = +0
    do_op(32'h00000000, 32'h80000000, 2'd1, 3'd1); // max(+0,-0) = +0
    // MINMAX NaN handling (S4/S5/S6)
    do_op(32'h7FC00001, 32'h3F800000, 2'd1, 3'd0); // min(qNaN,1.0) = 1.0, no flag
    do_op(32'h3F800000, 32'hFFC00001, 2'd1, 3'd1); // max(1.0,-qNaN) = 1.0, no flag
    do_op(32'h7FA00000, 32'hBF800000, 2'd1, 3'd0); // min(sNaN,-1.0) = -1.0, NV
    do_op(32'h7FC00001, 32'hFFC00001, 2'd1, 3'd1); // max(qNaN,-qNaN) = canonical, no flag
    do_op(32'hFFA00000, 32'h7FA00001, 2'd1, 3'd0); // min(sNaN,sNaN) = canonical, NV
    // CMP basics (S7/S10)
    do_op(32'h3F800000, 32'hBF800000, 2'd2, 3'd0); // fle(+1,-1) = 0
    do_op(32'h3F800000, 32'hBF800000, 2'd2, 3'd1); // flt(+1,-1) = 0
    do_op(32'hBF800000, 32'h3F800000, 2'd2, 3'd1); // flt(-1,+1) = 1
    do_op(32'h3F800000, 32'h3F800000, 2'd2, 3'd2); // feq(+1,+1) = 1
    do_op(32'h80000000, 32'h00000000, 2'd2, 3'd0); // fle(-0,+0) = 1
    do_op(32'h80000000, 32'h00000000, 2'd2, 3'd1); // flt(-0,+0) = 0
    do_op(32'h80000000, 32'h00000000, 2'd2, 3'd2); // feq(-0,+0) = 1
    // CMP NaN handling (S8/S9)
    do_op(32'h7FC00001, 32'h3F800000, 2'd2, 3'd0); // fle(qNaN,1.0) = 0, NV
    do_op(32'h7FC00001, 32'h3F800000, 2'd2, 3'd1); // flt(qNaN,1.0) = 0, NV
    do_op(32'h7FC00001, 32'h3F800000, 2'd2, 3'd2); // feq(qNaN,1.0) = 0, no flag
    do_op(32'h7FA00000, 32'h3F800000, 2'd2, 3'd2); // feq(sNaN,1.0) = 0, NV
    // SGNJ (S1/S2)
    do_op(32'h3F800000, 32'hBF800000, 2'd0, 3'd0);
    do_op(32'h3F800000, 32'hBF800000, 2'd0, 3'd1);
    do_op(32'h3F800000, 32'hBF800000, 2'd0, 3'd2);
    do_op(32'h7FA00000, 32'hFF800000, 2'd0, 3'd0); // sNaN payload copied, no flags (S1/S2)
    // CLASSIFY spot checks (S12/S13)
    do_op(32'hFF800000, 32'h0, 2'd3, 3'd0); // -inf -> bit 0
    do_op(32'h00000000, 32'h0, 2'd3, 3'd0); // +zero -> bit 4
    do_op(32'hFFA00000, 32'h0, 2'd3, 3'd4); // -sNaN -> bit 8, no flags (S13)
    wait_drain(100_000);

    // ---- CLASSIFY of every interesting value, several op_mode values ----
    for (i = 0; i < NVALS; i++) begin
      do_op(vals[i], 32'hDEADBEEF, 2'd3, 3'd0); // operand_b ignored (S12)
      do_op(vals[i], 32'h0,        2'd3, 3'd5); // op_mode ignored (S12)
      do_op(vals[i], vals[NVALS-1-i], 2'd3, 3'd7);
    end
    wait_drain(100_000);

    // ---- full cross product: MINMAX, CMP, SGNJ (with H3 backpressure) ---
    for (i = 0; i < NVALS; i++) begin
      for (j = 0; j < NVALS; j++) begin
        do_op(vals[i], vals[j], 2'd1, 3'd0); // FMIN
        do_op(vals[i], vals[j], 2'd1, 3'd1); // FMAX
        do_op(vals[i], vals[j], 2'd2, 3'd0); // FLE
        do_op(vals[i], vals[j], 2'd2, 3'd1); // FLT
        do_op(vals[i], vals[j], 2'd2, 3'd2); // FEQ
        do_op(vals[i], vals[j], 2'd0, 3'd0); // SGNJ
        do_op(vals[i], vals[j], 2'd0, 3'd1); // SGNJN
        do_op(vals[i], vals[j], 2'd0, 3'd2); // SGNJX
        if (((i * NVALS + j) % 23) == 7) maybe_stall(); // H3
        if ((i == 5) && (j == 5)) stall_out(25);        // H3: long stall, results in flight
      end
    end
    wait_drain(100_000);

    // ---- random phase ----------------------------------------------------
    for (k = 0; k < 600; k++) begin
      ra  = rnd_operand();
      rb  = rnd_operand();
      rop = $urandom_range(0, 3);
      case (rop) // only op_mode values listed in section 0 are driven
        2'd0:    rmode = $urandom_range(0, 2);
        2'd1:    rmode = $urandom_range(0, 1);
        2'd2:    rmode = $urandom_range(0, 2);
        default: rmode = $urandom_range(0, 7); // CLASSIFY: any
      endcase
      do_op(ra, rb, rop, rmode);
      if ((k % 17) == 3) maybe_stall();
    end
    wait_drain(100_000);

    // ---- S15: reset discards accepted-but-undelivered work --------------
    do_op(32'h40490FDB, 32'hFFA00000, 2'd1, 3'd1); // accepted; may be in flight
    do_op(32'h3F800000, 32'h7FA00000, 2'd2, 3'd1); // accepted
    do_op(32'hBF800000, 32'h3F400000, 2'd0, 3'd2); // accepted
    // We are at the negedge immediately after the last acceptance: reset now,
    // before any further sampling edge, so the last result cannot escape.
    out_ready_i = 1'b0;
    rst_n       = 1'b0;
    exp_q.delete(); // expectations for pre-reset work are void (S15)
    repeat (3) @(posedge clk);
    @(negedge clk);
    rst_n       = 1'b1;
    out_ready_i = 1'b1;
    @(posedge clk);
    @(negedge clk);
    if (out_valid_o !== 1'b0)
      tb_fail("S15", "out_valid_o high on first cycle after mid-run reset release");
    repeat (12) @(posedge clk); // any stale delivery is flagged by the monitor (S15/H2)

    // ---- functional re-check after reset ---------------------------------
    do_op(32'hBF800000, 32'h3F800000, 2'd1, 3'd0); // min(-1,+1) = -1
    do_op(32'h4F800000, 32'h4F800000, 2'd2, 3'd2); // feq(x,x) = 1
    do_op(32'h7FC00001, 32'h7FA00001, 2'd1, 3'd0); // min(qNaN,sNaN) = canonical, NV
    do_op(32'h00000001, 32'hFFFFFFFF, 2'd3, 3'd2); // classify(+min subnormal) = bit 5
    wait_drain(100_000);

    // ---- H3 floor: this testbench must have held out_ready low >= 20 ----
    if (total_stall < 20)
      tb_fail("H3", $sformatf("testbench held out_ready_i low for only %0d cycles", total_stall));

    $display("Info: %0d ops issued, %0d results checked, %0d stall cycles, %0d failures",
             n_ops, n_results, total_stall, n_fails);
    if (n_fails == 0)
      $display("RESULT: PASS");
    else
      $display("RESULT: FAIL");
    $finish;
  end

endmodule
