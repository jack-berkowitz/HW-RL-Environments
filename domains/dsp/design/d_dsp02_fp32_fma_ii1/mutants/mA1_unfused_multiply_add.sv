// =============================================================================
// mA1_unfused_multiply_add -- MUTANT. NEVER SHIPPED.
// class: fused-vs-unfused (the defining property, A1)
// =============================================================================
// injected defect: rounds the PRODUCT before adding, i.e. round(round(a*b) + c)
//                  instead of round(a*b + c). Two roundings where the spec
//                  requires one.
//
// Built from TWO instances of the vendored anchor rather than by hand: a MUL
// followed by an ADD. So every individual step is externally-authored correct
// arithmetic, and the ONLY defect is the extra rounding between them. That
// matters -- a hand-written unfused unit would risk failing for incidental
// reasons and would not isolate the property.
//
// Upstream operand adjustment, from fpnew_fma's own table:
//     MUL : operand C is forced to +/-0, so it computes a * b
//     ADD : operand A is forced to +1.0, so it computes b + c
// which is why the second instance takes the product in the B position.
//
// This is the class the A1 discriminator vector was written for: with
// a = b = 1 + 2^-12 the exact product is 1 + 2^-11 + 2^-24, and the 2^-24 term
// falls off the mantissa when the product is rounded early. The subsequent
// c = -(1 + 2^-11) then cancels to EXACTLY ZERO here, where a fused unit
// returns 2^-24.
//
// It is otherwise a completely reasonable multiply-add, which is the point:
// nothing about it looks wrong except on cases constructed to separate them.
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

    // ---- stage 1: p = round(a * b) -- THE INJECTED EXTRA ROUNDING -----------
    logic [2:0][31:0]   ops_mul;
    logic [31:0]        prod;
    fpnew_pkg::status_t st_mul;
    assign ops_mul = {32'h00000000, b, a};

    fpnew_fma #(.FpFormat(fpnew_pkg::FP32), .NumPipeRegs(0),
                .PipeConfig(fpnew_pkg::BEFORE)) u_mul (
        .clk_i(clk), .rst_ni(rst_n), .operands_i(ops_mul), .is_boxed_i(3'b111),
        .rnd_mode_i(rnd_e), .op_i(fpnew_pkg::MUL), .op_mod_i(1'b0),
        .tag_i(1'b0), .mask_i(1'b1), .aux_i(1'b0),
        .in_valid_i(in_valid), .in_ready_o(in_ready), .flush_i(1'b0),
        .result_o(prod), .status_o(st_mul), .extension_bit_o(),
        .tag_o(), .mask_o(), .aux_o(),
        .out_valid_o(), .out_ready_i(out_ready), .busy_o());

    // ---- stage 2: result = round(p + c) ------------------------------------
    logic [2:0][31:0]   ops_add;
    logic [31:0]        sum;
    fpnew_pkg::status_t st_add;
    assign ops_add = {c, prod, 32'h3F800000};   // ADD forces operand A to +1.0

    fpnew_fma #(.FpFormat(fpnew_pkg::FP32), .NumPipeRegs(0),
                .PipeConfig(fpnew_pkg::BEFORE)) u_add (
        .clk_i(clk), .rst_ni(rst_n), .operands_i(ops_add), .is_boxed_i(3'b111),
        .rnd_mode_i(rnd_e), .op_i(fpnew_pkg::ADD), .op_mod_i(1'b0),
        .tag_i(1'b0), .mask_i(1'b1), .aux_i(1'b0),
        .in_valid_i(in_valid), .in_ready_o(), .flush_i(1'b0),
        .result_o(sum), .status_o(st_add), .extension_bit_o(),
        .tag_o(), .mask_o(), .aux_o(),
        .out_valid_o(out_valid), .out_ready_i(out_ready), .busy_o());

    assign result         = sum;
    assign flag_invalid   = st_mul.NV | st_add.NV;
    assign flag_overflow  = st_mul.OF | st_add.OF;
    assign flag_underflow = st_mul.UF | st_add.UF;
    assign flag_inexact   = st_mul.NX | st_add.NX;

endmodule
