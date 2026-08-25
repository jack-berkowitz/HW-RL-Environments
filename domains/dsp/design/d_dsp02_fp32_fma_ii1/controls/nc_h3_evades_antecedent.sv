// nc_h3_evades_antecedent -- d_dsp02 NEGATIVE CONTROL for H3. Never shipped.
//
// H3 says: when out_valid is high and out_ready is low, out_valid must remain
// high and the result and flags must remain stable. This drops out_valid the
// moment the consumer stalls, and is otherwise the reference verbatim.
//
// WHY IT EXISTS. H3's checker was never run -- out_ready was assigned once, to
// 1, and never driven low (F82) -- and when the stimulus was finally written the
// checker failed the REFERENCE, because its guard compared a latched out_valid
// against a fresh out_ready and so reported a legally accepted beat as a
// violation. Both were repaired. A check that has just been repaired is a check
// nobody has seen discriminate, so this control exists to show that it does.
//
// PREDICTION, before running: PASSES every clause except H3, and FAILS H3.
// Dropping out_valid under backpressure loses no result and reorders nothing --
// the consumer simply never sees the beat it was owed -- so nothing else should
// trip. If other checks fail too, this control perturbs more than H3.

`timescale 1ns/1ps

// =============================================================================
// fp32_fma_ii1_ref.sv -- REFERENCE SHIM for d_dsp02. NEVER SHIPPED.
// =============================================================================
// Binds the vendored PULP cvfpu `fpnew_fma` to the flat interface the spec
// ships. Renaming and enum mapping only -- no arithmetic, no buffering, no
// handshake logic of its own.
//
// CONFIGURATION CHOICES THIS SHIM MAKES, recorded because they are NOT part of
// the contract and a candidate never had to compete with them:
//
//   FpFormat    = FP32          fixed by the task
//   NumPipeRegs = 3             PINNED BY SPEC S1 (rule 18). Was 0; a
//                               combinational FMA misses timing at 30 ns and
//                               no submission would ship it, so a baseline
//                               there measured nothing.
//                               the spec does not constrain latency. Zero is
//                               the SPEC-MINIMAL choice: it adds nothing the
//                               contract does not ask for. Compare d_nw01,
//                               where a shim bound CUT_ALL_AX and handed the
//                               reference 45% of its area in pipelining the
//                               spec never required.
//   PipeConfig  = DISTRIBUTED   spreads the three boundaries across the four
//                               dataflow segments. S1a leaves placement free,
//                               so this is the reference's choice, not a
//                               requirement.
//
// The rounding-mode mapping is the one non-trivial part: the spec defines FIVE
// modes with a fixed encoding, the anchor's enum defines eight. Modes 5-7 are
// out of scope, are never driven, and map to RNE here purely so the case is
// total -- not because the spec assigns them meaning.
// =============================================================================

`timescale 1ns/1ps

module fp32_fma_ii1_h3_inner (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        in_valid,
    output logic        in_ready,
    input  logic [31:0] a,
    input  logic [31:0] b,
    input  logic [31:0] c,
    input  logic [2:0]  rnd_mode,
    output logic        out_valid,
    input  logic        out_ready,
    output logic [31:0] result,
    output logic        flag_invalid,
    output logic        flag_overflow,
    output logic        flag_underflow,
    output logic        flag_inexact
);

    fpnew_pkg::roundmode_e rnd_e;
    always_comb begin
        case (rnd_mode)
            3'd0:    rnd_e = fpnew_pkg::RNE;
            3'd1:    rnd_e = fpnew_pkg::RTZ;
            3'd2:    rnd_e = fpnew_pkg::RDN;
            3'd3:    rnd_e = fpnew_pkg::RUP;
            3'd4:    rnd_e = fpnew_pkg::RMM;
            default: rnd_e = fpnew_pkg::RNE;   // 5-7 out of scope, never driven
        endcase
    end

    logic [2:0][31:0]     operands;
    fpnew_pkg::status_t   status;
    assign operands = {c, b, a};    // upstream order is {operand_c, operand_b, operand_a}

    fpnew_fma #(
        .FpFormat    ( fpnew_pkg::FP32 ),
        .NumPipeRegs ( 3               ),   // S1: the SCORED configuration
        .PipeConfig  ( fpnew_pkg::DISTRIBUTED )
    ) u_fma (
        .clk_i           ( clk       ),
        .rst_ni          ( rst_n     ),
        .operands_i      ( operands  ),
        .is_boxed_i      ( 3'b111    ),   // all three are genuine fp32, not NaN-boxed
        .rnd_mode_i      ( rnd_e     ),
        .op_i            ( fpnew_pkg::FMADD ),
        .op_mod_i        ( 1'b0      ),
        .tag_i           ( 1'b0      ),
        .mask_i          ( 1'b1      ),
        .aux_i           ( 1'b0      ),
        .in_valid_i      ( in_valid  ),
        .in_ready_o      ( in_ready  ),
        .flush_i         ( 1'b0      ),
        .result_o        ( result    ),
        .status_o        ( status    ),
        .extension_bit_o (           ),
        .tag_o           (           ),
        .mask_o          (           ),
        .aux_o           (           ),
        .out_valid_o     ( out_valid ),
        .out_ready_i     ( out_ready ),
        .busy_o          (           )
    );

    assign flag_invalid   = status.NV;
    assign flag_overflow  = status.OF;
    assign flag_underflow = status.UF;
    assign flag_inexact   = status.NX;
    // status.DZ is unused: an FMA cannot raise divide-by-zero.

endmodule


module fp32_fma_ii1 (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        in_valid,
    output logic        in_ready,
    input  logic [31:0] a,
    input  logic [31:0] b,
    input  logic [31:0] c,
    input  logic [2:0]  rnd_mode,
    output logic        out_valid,
    input  logic        out_ready,
    output logic [31:0] result,
    output logic        flag_invalid,
    output logic        flag_overflow,
    output logic        flag_underflow,
    output logic        flag_inexact
);
    logic inner_out_valid;
    // THE DEFECT, and the only one: having OFFERED a beat and been stalled,
    // withdraw it on the next cycle. That is exactly what H3 forbids.
    //
    // NOT `out_valid = inner_out_valid & out_ready`, which was the first attempt.
    // That gates out_valid combinationally on out_ready, which makes H3's
    // ANTECEDENT unsatisfiable rather than violating its consequent -- out_valid
    // is never high while out_ready is low, so the check has nothing to catch and
    // the control PASSES. It evades H3 rather than failing it, and NOTHING IN
    // THE CONTRACT FORBIDS IT: H1 bans in_ready depending combinationally on
    // in_valid, and there is no mirror clause on the output side.
// EVADING VARIANT -- rebuilt to MEASURE what it does, not to ship.
    // Gates out_valid combinationally on out_ready. Claimed in F86 to make
    // H3's antecedent unsatisfiable; this run is that claim measured.
    assign out_valid = inner_out_valid & out_ready;

    fp32_fma_ii1_h3_inner u_inner (
        .clk(clk), .rst_n(rst_n),
        .in_valid(in_valid), .in_ready(in_ready),
        .a(a), .b(b), .c(c), .rnd_mode(rnd_mode),
        .out_valid(inner_out_valid), .out_ready(out_ready), .result(result),
        .flag_invalid(flag_invalid), .flag_overflow(flag_overflow),
        .flag_underflow(flag_underflow), .flag_inexact(flag_inexact)
    );
endmodule
