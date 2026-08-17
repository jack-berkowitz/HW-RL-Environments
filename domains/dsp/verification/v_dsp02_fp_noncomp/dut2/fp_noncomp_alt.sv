// =============================================================================
// fp_noncomp_alt.sv -- SECOND DUT for v_dsp02. Locally written.
// =============================================================================
// An independent implementation of spec/fp_noncomp_spec.md, written from the
// specification and making different choices wherever it leaves one open.
//
// *** NOTHING IN THE HARNESS RUNS THIS. *** sim_verification.sh gates on the
// DECLARATION in task.yaml -- it refuses when a second DUT is claimed and dut2/
// is absent -- but it never compiles this file and never adds a row for it.
// Exercised only by running the reference testbench against it by hand.
//
// THE THREE DIFFERENCES (rule 5), named before writing:
//
//   1. ORDERING MECHANISM. Both operands are mapped through a monotone
//      transform to an unsigned key -- negative values inverted, positives with
//      the sign bit set -- and ordered with ONE unsigned compare. The anchor
//      compares the raw patterns and then corrects with
//      `(a < b) ^ (sign_a || sign_b)`. Same ordering, entirely different
//      arithmetic, and the -0/+0 boundary falls out of the map here rather than
//      being a special case.
//
//   2. CLASSIFICATION. A direct one-hot decode from the exponent and
//      significand fields. The anchor computes an info struct in a separate
//      classifier module and re-encodes it into the mask. This is the axis
//      where a shared misconception would be most likely, so it is the one
//      built from the specification's table rather than from any decomposition.
//
//   3. DECLARED: PIPELINE PLACEMENT -- one register stage on the OUTPUTS
//      against the anchor's registered INPUTS, expected to give a different
//      handshake timing and backpressure signature.
//
//      *** THIS DIFFERENCE DID NOT SURVIVE MEASUREMENT, and the record is kept
//      rather than back-fitted. *** Measured over 3178 cycles of mixed
//      operations with random backpressure: in_ready_o differs on ZERO cycles
//      and out_valid_o on ZERO. The register moved, but the handshake did not
//      change, because cvfpu's ready path is combinational through every stage
//      ("Ready signal is combinatorial for all stages", in the anchor). A
//      difference in register placement that no external observer can see is
//      not a difference under rule 5.
//
//   3'. WHAT SURVIVED, measured rather than declared. The two disagree on
//      1450 cycles, and EVERY disagreement is inside the latitude:
//        result_o     differs on 333 cycles, all 333 with op = CLASSIFY   (10.4)
//        class_mask_o differs on 1117 cycles, all with op != CLASSIFY     (10.5)
//        status_o     differs on 0
//      This second DUT drives zero on the outputs the contract leaves
//      unconstrained where the anchor drives datapath residue. It therefore
//      probes 10.4 and 10.5 from the opposite side to fn_c4 and fn_c5, and a
//      testbench that samples an unconstrained output is caught from both
//      directions.
// =============================================================================

module fp_noncomp_alt (
    input  logic        clk_i,
    input  logic        rst_ni,

    input  logic [31:0] operand_a_i,
    input  logic [31:0] operand_b_i,
    input  logic [1:0]  op_i,
    input  logic [2:0]  op_mode_i,

    input  logic        in_valid_i,
    output logic        in_ready_o,

    output logic [31:0] result_o,
    output logic [9:0]  class_mask_o,
    output logic [4:0]  status_o,

    output logic        out_valid_o,
    input  logic        out_ready_i
);

  localparam logic [31:0] CANON_QNAN = 32'h7FC0_0000;

  // ---- format predicates (A1, A3) -------------------------------------------
  function automatic bit f_nan (input logic [31:0] x); return (x[30:23] == 8'hFF) && (x[22:0] != 0); endfunction
  function automatic bit f_snan(input logic [31:0] x); return f_nan(x) && !x[22]; endfunction
  function automatic bit f_inf (input logic [31:0] x); return (x[30:23] == 8'hFF) && (x[22:0] == 0); endfunction
  function automatic bit f_zero(input logic [31:0] x); return x[30:0] == 0; endfunction
  function automatic bit f_sub (input logic [31:0] x); return (x[30:23] == 0) && (x[22:0] != 0); endfunction

  // Difference 1: monotone map, then a single unsigned compare.
  function automatic logic [31:0] f_key(input logic [31:0] x);
    return x[31] ? ~x : (x | 32'h8000_0000);
  endfunction

  logic [31:0] a, b;
  assign a = operand_a_i;
  assign b = operand_b_i;

  wire a_nan  = f_nan(a),  b_nan  = f_nan(b);
  wire a_snan = f_snan(a), b_snan = f_snan(b);
  wire both_zero = f_zero(a) && f_zero(b);

  // MINMAX ordering: -0 below +0, which the key map already gives.
  wire a_below_b = f_key(a) < f_key(b);
  // CMP ordering: the two zeros are EQUAL (S10), so they are special-cased out.
  wire cmp_eq = (a == b) || both_zero;
  wire cmp_lt = both_zero ? 1'b0 : a_below_b;

  logic [31:0] res_c;
  logic [9:0]  cls_c;
  logic [4:0]  st_c;

  always_comb begin
    res_c = '0;
    cls_c = '0;
    st_c  = '0;

    unique case (op_i)
      2'd0: begin                                        // SGNJ  -- S1, S2
        logic s;
        unique case (op_mode_i)
          3'd0:    s =  b[31];
          3'd1:    s = ~b[31];
          default: s =  a[31] ^ b[31];
        endcase
        res_c = {s, a[30:0]};
      end

      2'd1: begin                                        // MINMAX -- S3..S6
        if (a_nan && b_nan)  res_c = CANON_QNAN;         // S5
        else if (a_nan)      res_c = b;                  // S4
        else if (b_nan)      res_c = a;                  // S4
        else if (op_mode_i == 3'd0) res_c = a_below_b ? a : b;   // min, S3
        else                        res_c = a_below_b ? b : a;   // max, S3
        st_c[4] = a_snan | b_snan;                       // S6
      end

      2'd2: begin                                        // CMP -- S7..S11
        logic tv;
        unique case (op_mode_i)
          3'd0:    tv = cmp_lt | cmp_eq;                 // LE
          3'd1:    tv = cmp_lt;                          // LT
          default: tv = cmp_eq;                          // EQ
        endcase
        if (a_nan || b_nan) tv = 1'b0;
        res_c   = {31'b0, tv};
        st_c[4] = (op_mode_i == 3'd2) ? (a_snan | b_snan)     // S9 quiet
                                      : (a_nan  | b_nan);     // S8 signalling
      end

      default: begin                                     // CLASSIFY -- S12, S13
        // Difference 2: one-hot straight off the fields, in the order the
        // specification's table gives them.
        cls_c[0] = f_inf(a)  &&  a[31];
        cls_c[1] = !f_nan(a) && !f_inf(a) && !f_zero(a) && !f_sub(a) &&  a[31];
        cls_c[2] = f_sub(a)  &&  a[31];
        cls_c[3] = f_zero(a) &&  a[31];
        cls_c[4] = f_zero(a) && !a[31];
        cls_c[5] = f_sub(a)  && !a[31];
        cls_c[6] = !f_nan(a) && !f_inf(a) && !f_zero(a) && !f_sub(a) && !a[31];
        cls_c[7] = f_inf(a)  && !a[31];
        cls_c[8] = f_snan(a);
        cls_c[9] = f_nan(a)  &&  a[22];
      end
    endcase
  end

  // ---- Difference 3: one register stage on the OUTPUTS ----------------------
  logic        o_valid;
  logic [31:0] o_res;
  logic [9:0]  o_cls;
  logic [4:0]  o_st;

  wire fire = o_valid & out_ready_i;
  wire free = ~o_valid | fire;

  assign in_ready_o  = free;
  assign out_valid_o = o_valid;
  assign result_o    = o_res;
  assign class_mask_o= o_cls;
  assign status_o    = o_st;

  always_ff @(posedge clk_i) begin
    if (!rst_ni) begin
      o_valid <= 1'b0;
    end else begin
      if (fire) o_valid <= 1'b0;
      if (free && in_valid_i) begin
        o_valid <= 1'b1;
        o_res   <= res_c;
        o_cls   <= cls_c;
        o_st    <= st_c;
      end
    end
  end

endmodule
