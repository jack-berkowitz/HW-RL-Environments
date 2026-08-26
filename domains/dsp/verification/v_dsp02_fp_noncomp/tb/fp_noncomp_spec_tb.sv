// =============================================================================
// fp_noncomp_spec_tb.sv -- REFERENCE TESTBENCH for v_dsp02. NEVER SHIPPED.
// =============================================================================
// Establishes the kill ceiling. Written against spec/fp_noncomp_spec.md only.
//
// ON RULE 11 AND WHY IT DOES NOT FORBID THIS FILE
// -----------------------------------------------
// Rule 11 says locally authored code generates INPUTS, never expected values.
// That is a rule about DESIGN tasks, where the submission is the DUT and a local
// model producing expected values would let a shared misconception survive.
// A VERIFICATION task inverts the relationship: the checker IS the artefact
// under test, so it necessarily encodes the contract locally, and the anchor
// validates the checker rather than the other way round. The two risks are
// covered by the two sets rather than by the oracle: the conformant set catches
// over-constraint, the mutant set catches under-constraint.
//
// DRIVER DISCIPLINE. H4 is honoured: in_valid_i is asserted with stable operands
// and held until accepted, and nothing is driven in the same timestep the design
// samples -- stimulus changes on the negative edge only.
// =============================================================================

module fp_noncomp_tb;


  // VCD on demand, for the rule-34 stimulus-variation check. Plusarg-guarded, so
  // a normal scoring run is byte-for-byte unaffected.
  initial if ($test$plusargs("vcd")) begin
    $dumpfile("dump.vcd");
    $dumpvars(0, fp_noncomp_tb);
  end
  localparam logic [31:0] CANON_QNAN = 32'h7FC0_0000;

  // op_i encoding -- this task's own, see spec section 0
  localparam logic [1:0] OP_SGNJ = 2'd0, OP_MINMAX = 2'd1, OP_CMP = 2'd2, OP_CLASS = 2'd3;

  logic clk = 1'b0, rst_n = 1'b0;
  always #5 clk = ~clk;

  logic [31:0] a_i, b_i, result;
  logic [1:0]  op;
  logic [2:0]  mode;
  logic        in_valid = 1'b0, in_ready, out_valid;
  logic        out_ready = 1'b1;
  logic [9:0]  class_mask;
  logic [4:0]  status;

  fp_noncomp dut (
    .clk_i(clk), .rst_ni(rst_n),
    .operand_a_i(a_i), .operand_b_i(b_i), .op_i(op), .op_mode_i(mode),
    .in_valid_i(in_valid), .in_ready_o(in_ready),
    .result_o(result), .class_mask_o(class_mask), .status_o(status),
    .out_valid_o(out_valid), .out_ready_i(out_ready)
  );

  int unsigned n_fail = 0;
  task automatic fail(input string clause, input string msg);
    n_fail = n_fail + 1;
    if (n_fail <= 40) $display("FAIL [%s] %s", clause, msg);
  endtask

  // ---- format predicates (A1, A3) -------------------------------------------
  function automatic bit is_nan (input logic [31:0] x); return (x[30:23] == 8'hFF) && (x[22:0] != 0); endfunction
  function automatic bit is_snan(input logic [31:0] x); return is_nan(x) && !x[22]; endfunction
  function automatic bit is_qnan(input logic [31:0] x); return is_nan(x) &&  x[22]; endfunction
  function automatic bit is_inf (input logic [31:0] x); return (x[30:23] == 8'hFF) && (x[22:0] == 0); endfunction
  function automatic bit is_zero(input logic [31:0] x); return  x[30:0] == 0; endfunction
  function automatic bit is_sub (input logic [31:0] x); return (x[30:23] == 0) && (x[22:0] != 0); endfunction

  // Monotone map to an unsigned key: ordering matches IEEE with -0 BELOW +0,
  // which is what S3 requires of MINMAX (and NOT what S10 requires of CMP).
  function automatic logic [31:0] key(input logic [31:0] x);
    return x[31] ? ~x : (x | 32'h8000_0000);
  endfunction

  // ---- the contract, clause by clause ---------------------------------------
  // chk_res / chk_cls say which outputs the contract constrains for this op.
  task automatic model(input  logic [1:0] o, input logic [2:0] m,
                       input  logic [31:0] x, input logic [31:0] y,
                       output logic [31:0] res, output logic [9:0] cls,
                       output logic [4:0]  st,
                       output bit chk_res, output bit chk_cls);
    res = '0; cls = '0; st = '0; chk_res = 1'b1; chk_cls = 1'b0;
    unique case (o)
      OP_SGNJ: begin                                   // S1, S2
        automatic logic sgn;
        unique case (m)
          3'd0:    sgn =  y[31];
          3'd1:    sgn = ~y[31];
          default: sgn =  x[31] ^ y[31];
        endcase
        res = {sgn, x[30:0]};                          // payload preserved
        st  = '0;
      end
      OP_MINMAX: begin                                 // S3-S6
        if (is_nan(x) && is_nan(y))       res = CANON_QNAN;      // S5
        else if (is_nan(x))               res = y;               // S4
        else if (is_nan(y))               res = x;               // S4
        else begin                                               // S3
          automatic bit x_smaller = key(x) < key(y);
          res = (m == 3'd0) ? (x_smaller ? x : y) : (x_smaller ? y : x);
        end
        st[4] = is_snan(x) | is_snan(y);               // S6
      end
      OP_CMP: begin                                    // S7-S11
        automatic bit eq = (x == y) || (is_zero(x) && is_zero(y));   // S10
        automatic bit lt = (is_zero(x) && is_zero(y)) ? 1'b0 : (key(x) < key(y));
        automatic bit tv;
        unique case (m)
          3'd0:    tv = lt | eq;                       // LE
          3'd1:    tv = lt;                            // LT
          default: tv = eq;                            // EQ
        endcase
        if (is_nan(x) || is_nan(y)) tv = 1'b0;
        res   = {31'b0, tv};                           // S7
        st[4] = (m == 3'd2) ? (is_snan(x) | is_snan(y))            // S9 quiet
                            : (is_nan(x)  | is_nan(y));            // S8 signalling
      end
      default: begin                                   // S12, S13
        chk_res = 1'b0;                                // latitude 4
        chk_cls = 1'b1;
        if      (is_snan(x))            cls = 10'b01_0000_0000;
        else if (is_qnan(x))            cls = 10'b10_0000_0000;
        else if (is_inf(x) &&  x[31])   cls = 10'b00_0000_0001;
        else if (is_inf(x))             cls = 10'b00_1000_0000;
        else if (is_zero(x) && x[31])   cls = 10'b00_0000_1000;
        else if (is_zero(x))            cls = 10'b00_0001_0000;
        else if (is_sub(x)  && x[31])   cls = 10'b00_0000_0100;
        else if (is_sub(x))             cls = 10'b00_0010_0000;
        else if (x[31])                 cls = 10'b00_0000_0010;
        else                            cls = 10'b00_0100_0000;
        st = '0;
      end
    endcase
  endtask

  // ---- expectation queue (H2: results come back in order) -------------------
  typedef struct packed {
    logic [31:0] res; logic [9:0] cls; logic [4:0] st;
    logic        chk_res, chk_cls;
    logic [1:0]  op;  logic [2:0] mode;
    logic [31:0] a;   logic [31:0] b;
  } exp_t;
  exp_t exp_q [$];
  logic [31:0] discarded_tag [$];      // ops accepted before a reset (S15)

  int unsigned n_issued = 0, n_checked = 0;

  // stimulus-side coverage (rule 4 -- a correct design cannot score zero here)
  int unsigned cov_class [10];
  int unsigned cov_nan_a = 0, cov_nan_b = 0, cov_snan = 0, cov_qnan = 0;
  int unsigned cov_zero_pair = 0, cov_noncanon_nan = 0, cov_stall = 0, cov_reset = 0;
  int unsigned cov_op [4];
  int unsigned cov_signed_zero_eq = 0;

  // ---- checker --------------------------------------------------------------
  always @(posedge clk) begin
    if (!rst_n) begin
      while (exp_q.size() > 0) begin
        automatic exp_t e = exp_q.pop_front();
        discarded_tag.push_back(e.a);
      end
    end else if (out_valid && out_ready) begin
      if (exp_q.size() == 0) begin
        fail("H2", $sformatf("a result was delivered with no operation outstanding (result=%h)", result));
      end else begin
        automatic exp_t e = exp_q.pop_front();
        n_checked = n_checked + 1;
        if (e.chk_res && result !== e.res) begin
          automatic string cl;
          unique case (e.op)
            OP_SGNJ:   cl = "S1";
            OP_MINMAX: cl = (is_nan(e.a) && is_nan(e.b)) ? "S5" :
                            ((is_nan(e.a) || is_nan(e.b)) ? "S4" : "S3");
            OP_CMP:    cl = "S7";
            default:   cl = "S12";
          endcase
          fail(cl, $sformatf("op=%0d mode=%0d a=%h b=%h : result expected %h got %h",
                             e.op, e.mode, e.a, e.b, e.res, result));
        end
        if (e.chk_cls && class_mask !== e.cls)
          fail("S12", $sformatf("classify a=%h : mask expected %b got %b", e.a, e.cls, class_mask));
        if (status[3:0] !== 4'b0)
          fail("S14", $sformatf("op=%0d a=%h b=%h : DZ/OF/UF/NX must be zero, status=%b",
                                e.op, e.a, e.b, status));
        if (status[4] !== e.st[4])
          // S8 and S9 differ only in whether the comparison is signalling, so
          // the NV clause depends on the MODE, not just the operation.
          fail(e.op == OP_MINMAX ? "S6" :
               (e.op == OP_CMP ? (e.mode == 3'd2 ? "S9" : "S8") : "S2"),
               $sformatf("op=%0d mode=%0d a=%h b=%h : NV expected %b got %b",
                         e.op, e.mode, e.a, e.b, e.st[4], status[4]));
      end
    end
  end

  // ---- driver ---------------------------------------------------------------
  task automatic issue(input logic [1:0] o, input logic [2:0] m,
                       input logic [31:0] x, input logic [31:0] y);
    exp_t e;
    logic [31:0] r; logic [9:0] c; logic [4:0] s; bit cr, cc;
    model(o, m, x, y, r, c, s, cr, cc);
    e.res = r; e.cls = c; e.st = s; e.chk_res = cr; e.chk_cls = cc;
    e.op = o; e.mode = m; e.a = x; e.b = y;

    @(negedge clk);
    op = o; mode = m; a_i = x; b_i = y; in_valid = 1'b1;
    // H4: hold until accepted. The expectation is queued on the accepting edge
    // so it cannot race ahead of the design.
    forever begin
      @(posedge clk);
      if (in_ready) break;
    end
    exp_q.push_back(e);
    n_issued = n_issued + 1;
    cov_op[o]++;
    if (is_nan(x)) cov_nan_a++;
    if (is_nan(y)) cov_nan_b++;
    if (is_snan(x) || is_snan(y)) cov_snan++;
    if (is_qnan(x) || is_qnan(y)) cov_qnan++;
    if (is_zero(x) && is_zero(y)) cov_zero_pair++;
    if (is_nan(x) && x[22:0] != 23'h400000 && x[22:0] != 23'h200000) cov_noncanon_nan++;
    if (o == OP_CLASS) begin
      automatic logic [9:0] c2; automatic logic [31:0] r2; automatic logic [4:0] s2;
      automatic bit cr2, cc2;
      model(OP_CLASS, 3'd0, x, y, r2, c2, s2, cr2, cc2);
      for (int i = 0; i < 10; i++) if (c2[i]) cov_class[i]++;
    end
    @(negedge clk);
    in_valid = 1'b0;
  endtask

  task automatic drain(input int unsigned n = 200);
    int unsigned g = 0;
    while (exp_q.size() > 0 && g < n) begin @(posedge clk); g++; end
    if (exp_q.size() > 0) fail("H2", $sformatf("%0d results never arrived", exp_q.size()));
  endtask

  // ---- corner pool ----------------------------------------------------------
  localparam int NV_ = 20;
  logic [31:0] pool [NV_] = '{
    32'h0000_0000, 32'h8000_0000,   // +0, -0
    32'h0000_0001, 32'h8000_0001,   // +/- min subnormal
    32'h007F_FFFF, 32'h807F_FFFF,   // +/- max subnormal
    32'h0080_0000, 32'h8080_0000,   // +/- min normal
    32'h3F80_0000, 32'hBF80_0000,   // +/- 1.0
    32'h4000_0000, 32'hC000_0000,   // +/- 2.0
    32'h7F7F_FFFF, 32'hFF7F_FFFF,   // +/- max normal
    32'h7F80_0000, 32'hFF80_0000,   // +/- inf
    32'h7FC0_0000, 32'hFFD5_A5A5,   // canonical qNaN, non-canonical qNaN (negative)
    32'h7FA0_0000, 32'hFF81_2345    // sNaN, another sNaN (negative)
  };

  string phase = "init";

  initial begin
    for (int i = 0; i < 10; i++) cov_class[i] = 0;
    for (int i = 0; i < 4;  i++) cov_op[i]    = 0;
    a_i = '0; b_i = '0; op = '0; mode = '0;
    repeat (4) @(posedge clk);
    @(negedge clk) rst_n = 1'b1;

    // -- A: every operation and legal mode over the full corner pool ----------
    phase = "A:corners";
    foreach (pool[i]) foreach (pool[j]) begin
      issue(OP_SGNJ,   3'd0, pool[i], pool[j]);
      issue(OP_SGNJ,   3'd1, pool[i], pool[j]);
      issue(OP_SGNJ,   3'd2, pool[i], pool[j]);
      issue(OP_MINMAX, 3'd0, pool[i], pool[j]);
      issue(OP_MINMAX, 3'd1, pool[i], pool[j]);
      issue(OP_CMP,    3'd0, pool[i], pool[j]);
      issue(OP_CMP,    3'd1, pool[i], pool[j]);
      issue(OP_CMP,    3'd2, pool[i], pool[j]);
    end
    drain();

    // -- B: classify over the pool, so all ten classes are driven -------------
    phase = "B:classify";
    foreach (pool[i]) begin
      issue(OP_CLASS, 3'd0, pool[i], 32'hDEAD_BEEF);
      issue(OP_CLASS, 3'd1, pool[i], 32'h0000_0000);   // mode ignored
    end
    drain();

    // -- C: backpressure, directed rather than hoped for ----------------------
    phase = "C:backpressure";
    fork
      begin
        for (int k = 0; k < 6; k++) begin
          @(negedge clk) out_ready = 1'b0;
          repeat (3 + k) begin @(posedge clk); cov_stall = cov_stall + 1; end
          @(negedge clk) out_ready = 1'b1;
          repeat (4) @(posedge clk);
        end
      end
      begin
        foreach (pool[i]) begin
          issue(OP_MINMAX, 3'd0, pool[i], pool[(i+7) % NV_]);
          issue(OP_CMP,    3'd2, pool[i], pool[(i+3) % NV_]);
          issue(OP_CLASS,  3'd0, pool[i], '0);
        end
      end
    join
    @(negedge clk) out_ready = 1'b1;
    drain();

    // -- C2: the signed-zero pair, driven REPEATEDLY --------------------------
    // +0 and -0 compare EQUAL, and the clause holds on every comparison, not
    // only the first one a sweep happens to reach. A pool sweep drives this
    // pair once or twice; a design that is right the first few times and wrong
    // afterwards is invisible to that.
    phase = "C2:signed-zero equality";
    for (int k = 0; k < 8; k++) begin
      issue(OP_CMP, 3'd2, 32'h0000_0000, 32'h8000_0000);   // +0 == -0
      issue(OP_CMP, 3'd2, 32'h8000_0000, 32'h0000_0000);   // -0 == +0
      cov_signed_zero_eq = cov_signed_zero_eq + 1;
    end
    drain();

    // -- D: random pairs ------------------------------------------------------
    phase = "D:random";
    for (int k = 0; k < 400; k++) begin
      automatic logic [1:0] ro = 2'($urandom_range(0,3));
      automatic logic [2:0] rm;
      // Legal modes per operation, section 0. MINMAX has only two; driving a
      // third is out of scope under 10.6, and the design is entitled to return
      // anything at all for it.
      unique case (ro)
        OP_MINMAX: rm = 3'($urandom_range(0,1));
        OP_CLASS:  rm = 3'($urandom_range(0,7));   // ignored, so anything is legal
        default:   rm = 3'($urandom_range(0,2));
      endcase
      issue(ro, rm, $urandom, $urandom);
    end
    drain();

    // -- E: reset with an operation in flight (S15) ---------------------------
    phase = "E:reset";
    @(negedge clk) out_ready = 1'b0;
    issue(OP_CLASS, 3'd0, 32'hFF80_0000, '0);
    repeat (2) @(posedge clk);
    @(negedge clk) rst_n = 1'b0;
    cov_reset = cov_reset + 1;
    repeat (3) @(posedge clk);
    @(negedge clk); rst_n = 1'b1; out_ready = 1'b1;
    @(posedge clk);
    if (out_valid !== 1'b0)
      fail("S15", "out_valid_o high on the first cycle after reset release");
    repeat (10) @(posedge clk);
    if (exp_q.size() != 0) fail("S15", "model still holds an expectation after reset");
    // and the design must be usable again
    issue(OP_CMP, 3'd2, 32'h3F80_0000, 32'h3F80_0000);
    drain();

    // ---- coverage floors, all stimulus-side ---------------------------------
    for (int i = 0; i < 10; i++)
      if (cov_class[i] < 1)
        fail("FLOOR", $sformatf("classify class bit %0d never driven", i));
    for (int i = 0; i < 4; i++)
      if (cov_op[i] < 20)
        fail("FLOOR", $sformatf("op %0d issued only %0d times", i, cov_op[i]));
    if (cov_snan < 50)         fail("FLOOR", $sformatf("signalling-NaN operands: %0d < 50", cov_snan));
    if (cov_qnan < 50)         fail("FLOOR", $sformatf("quiet-NaN operands: %0d < 50", cov_qnan));
    if (cov_zero_pair < 8)     fail("FLOOR", $sformatf("both-operands-zero cases: %0d < 8", cov_zero_pair));
    if (cov_signed_zero_eq < 4)
      fail("COVERAGE", "the +0/-0 pair was compared fewer than four times -- a clause that holds on EVERY comparison is checked on one");
    if (cov_noncanon_nan < 10) fail("FLOOR", $sformatf("non-canonical NaN operands: %0d < 10", cov_noncanon_nan));
    if (cov_stall < 20)        fail("FLOOR", $sformatf("output stall cycles: %0d < 20", cov_stall));
    if (cov_reset < 1)         fail("FLOOR", "no reset applied with an operation in flight");

    $display("METRIC: ops_issued %0d", n_issued);
    $display("METRIC: ops_checked %0d", n_checked);
    $display("METRIC: cov snan=%0d qnan=%0d zeropair=%0d noncanon=%0d stalls=%0d",
             cov_snan, cov_qnan, cov_zero_pair, cov_noncanon_nan, cov_stall);
    // ---- FIRED: did the artefacts that must fire, fire? ---------------------
    // Every counter here GATES A FLOOR. The floor already refuses on zero, so
    // these lines add one thing the floor cannot: they distinguish a floor that
    // ran and read zero from a floor that IS NOT IN THIS RUN AT ALL -- deleted,
    // renamed, or skipped. Absent is not zero (rule 20), and v_ca03's read
    // coverage floor sat behind a dangling `else` and was skipped on exactly the
    // runs that were otherwise clean. check_fired.py refuses on both, separately.
    $display("FIRED v_dsp02.cov_noncanon_nan %0d", cov_noncanon_nan);
    $display("FIRED v_dsp02.cov_qnan %0d", cov_qnan);
    $display("FIRED v_dsp02.cov_reset %0d", cov_reset);
    $display("FIRED v_dsp02.cov_signed_zero_eq %0d", cov_signed_zero_eq);
    $display("FIRED v_dsp02.cov_snan %0d", cov_snan);
    $display("FIRED v_dsp02.cov_stall %0d", cov_stall);
    $display("FIRED v_dsp02.cov_zero_pair %0d", cov_zero_pair);

    if (n_fail == 0) $display("RESULT: PASS");
    else             $display("RESULT: FAIL (%0d failures)", n_fail);
    $finish;
  end

  initial begin
    #200_000_000;
    $display("RESULT: FAIL (watchdog fired in phase %s)", phase);
    $finish;
  end

endmodule
