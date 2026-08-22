// =============================================================================
// mA6_underflow_ignores_inexact -- MUTANT. NEVER SHIPPED.
// class: contract-underflow
// =============================================================================
// injected defect: raises underflow from the RESULT FORM ALONE -- any subnormal
//                  result -- dropping A6's requirement that the result also be
//                  INEXACT. An exact subnormal result gets UF; the reference
//                  correctly clears it.
//
// WHAT THIS MUTANT IS FOR, restated. It used to be described as "the other
// reading IEEE-754 permits", detecting tininess before rounding. That was wrong
// on both counts. The code does not implement before-rounding detection -- it
// ORs "result is subnormal" into the anchor's own UF -- and A6 no longer cites
// IEEE-754 at all: underflow is PINNED BY THIS TASK, longhand, precisely
// because "tininess after rounding" names two incompatible rules.
//
// So this is a mutant against a TASK-PINNED CONVENTION, and what it tests is
// condition (1) of that convention: UF requires inexactness, not merely a
// subnormal result. It differs from the reference only on flags, never on the
// result value.
//
// Built as a WRAPPER around the vendored anchor, so the arithmetic is correct
// everywhere except the injected defect, and so it remains a standalone
// fp32_fma_ii1 module that differential simulation can instantiate beside the
// reference.
// =============================================================================
`timescale 1ns/1ps

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
    fpnew_pkg::roundmode_e rnd_e;
    always_comb begin
        case (rnd_mode)
            3'd0:    rnd_e = fpnew_pkg::RNE;
            3'd1:    rnd_e = fpnew_pkg::RTZ;
            3'd2:    rnd_e = fpnew_pkg::RDN;
            3'd3:    rnd_e = fpnew_pkg::RUP;
            3'd4:    rnd_e = fpnew_pkg::RMM;
            default: rnd_e = fpnew_pkg::RNE;
        endcase
    end

    function automatic bit is_subn(input logic [31:0] x);
        return (x[30:23] == 8'd0) && (x[22:0] != 23'd0);
    endfunction
    function automatic bit is_nan(input logic [31:0] x);
        return (x[30:23] == 8'hFF) && (x[22:0] != 23'd0);
    endfunction

    logic [2:0][31:0] ops_in;
    assign ops_in = {c, b, a};
    logic [31:0]        raw_result;
    fpnew_pkg::status_t raw_status;

    fpnew_fma #(.FpFormat(fpnew_pkg::FP32), .NumPipeRegs(0),
                .PipeConfig(fpnew_pkg::BEFORE)) u_fma (
        .clk_i(clk), .rst_ni(rst_n), .operands_i(ops_in), .is_boxed_i(3'b111),
        .rnd_mode_i(rnd_e), .op_i(fpnew_pkg::FMADD), .op_mod_i(1'b0),
        .tag_i(1'b0), .mask_i(1'b1), .aux_i(1'b0),
        .in_valid_i(in_valid), .in_ready_o(in_ready), .flush_i(1'b0),
        .result_o(raw_result), .status_o(raw_status), .extension_bit_o(),
        .tag_o(), .mask_o(), .aux_o(),
        .out_valid_o(out_valid), .out_ready_i(out_ready), .busy_o());

    assign result         = raw_result;
    assign flag_invalid   = raw_status.NV;
    assign flag_overflow  = raw_status.OF;
    // INJECTED: underflow from result form alone, ignoring inexactness
    assign flag_underflow = is_subn(raw_result) | raw_status.UF;
    assign flag_inexact   = raw_status.NX;
endmodule
