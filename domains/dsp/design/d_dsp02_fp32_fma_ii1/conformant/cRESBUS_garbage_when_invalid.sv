// =============================================================================
// cRESBUS -- CONFORMANT PERTURBATION. Must PASS the checker, not be killed.
// =============================================================================
// Drives the result bus and the flag bus with GARBAGE whenever out_valid is low.
//
// LICENCE: H3 constrains result and flags to be STABLE only when out_valid is
// HIGH and out_ready is low. Nothing in the spec says what the buses carry when
// out_valid is LOW, so a correct implementation may drive anything there --
// including whatever the pipeline happens to be computing, which is what real
// designs do.
//
// This is the direct analogue of v_ca05's c2 (pop_data_o garbage when
// pop_data_valid_o is low), and it survives the pinning of LATENCY because its
// licence is H3's scope, not the latency clause.
//
// A checker that samples result while out_valid is low fails this, and that
// failure indicts the CHECKER -- it would be relying on behaviour the contract
// never promised.
//
// Latency, initiation interval and every produced value are unchanged, so this
// perturbation is conformant with S1 as well.
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
        .result_o        ( inner_result    ),
        .status_o        ( status    ),
        .extension_bit_o (           ),
        .tag_o           (           ),
        .mask_o          (           ),
        .aux_o           (           ),
        .out_valid_o     ( out_valid ),
        .out_ready_i     ( out_ready ),
        .busy_o          (           )
    );

    // ---- THE PERTURBATION -------------------------------------------------
    // Garbage on both buses whenever out_valid is low. Free-running LFSR so the
    // value differs cycle to cycle -- a constant would be indistinguishable
    // from a design that simply holds, and would risk being a no-op control.
    // Declared EXPLICITLY. Left implicit it became a 1-BIT wire and silently
    // truncated the 32-bit result to bit 0 -- the design still elaborated and
    // still ran, it just returned garbage. Caught by neutralising the
    // perturbation and finding the file failed anyway.
    logic [31:0] inner_result;

    // SYNCHRONOUS reset, per R1. The first version used
    // `@(posedge clk or negedge rst_n)`, which is asynchronous and would have
    // made this perturbation a spec violation rather than a conformant variant.
    logic [31:0] lfsr;
    always_ff @(posedge clk) begin
        if (!rst_n) lfsr <= 32'hF00D_1234;
        else        lfsr <= {lfsr[30:0], lfsr[31] ^ lfsr[21] ^ lfsr[1] ^ lfsr[0]};
    end

    assign result         = out_valid ? inner_result : lfsr;
    assign flag_invalid   = out_valid ? status.NV : lfsr[0];
    assign flag_overflow  = out_valid ? status.OF : lfsr[1];
    assign flag_underflow = out_valid ? status.UF : lfsr[2];
    assign flag_inexact   = out_valid ? status.NX : lfsr[3];
    // status.DZ is unused: an FMA cannot raise divide-by-zero.

endmodule
