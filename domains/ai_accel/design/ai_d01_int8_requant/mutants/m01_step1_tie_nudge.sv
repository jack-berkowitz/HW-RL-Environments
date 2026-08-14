// =============================================================================
// m01_step1_tie_nudge -- MUTANT. NEVER SHIPPED.
// class: arithmetic-rounding
// injected bug: step-1 negative nudge loses its +1, so step-1 ties round away from zero instead of toward +inf
// Derived from ref/int8_requant_ref.sv by exactly one edit.
// =============================================================================
`timescale 1ns/1ps

module int8_requant #(
    parameter int LANES = 4
) (
    input  logic                  clk,
    input  logic                  rst_n,

    input  logic                  in_valid,
    output logic                  in_ready,
    input  logic [LANES*32-1:0]   acc,
    input  logic [LANES*32-1:0]   mult,
    input  logic [LANES*5-1:0]    shift,
    input  logic [LANES*8-1:0]    zp,

    output logic                  out_valid,
    input  logic                  out_ready,
    output logic [LANES*8-1:0]    result
);

    // -------------------------------------------------------------------------
    // Per-lane combinational datapath. Mirrors the four numbered spec steps.
    // -------------------------------------------------------------------------
    function automatic logic signed [7:0] requant_lane(
        input logic signed [31:0] acc_i,
        input logic signed [31:0] mult_i,
        input logic        [4:0]  sh_i,
        input logic signed [7:0]  zp_i
    );
        logic signed [63:0] p, nudge, sum, floor_hi, hi;
        logic signed [63:0] mask, remainder, threshold, shifted;
        logic signed [63:0] biased;

        // ---- STEP 1: doubling high multiply, rounded ------------------------
        p     = 64'(acc_i) * 64'(mult_i);
        nudge = (p >= 0) ? 64'sd1073741824               //  2^30
                         : (-64'sd1073741824);           //  MUTANT: dropped the +1
        sum   = p + nudge;

        // sum / 2^31 TRUNCATING TOWARD ZERO. An arithmetic shift alone floors,
        // which is wrong for negative sums with a non-zero remainder, so add
        // the correction back in.
        floor_hi = sum >>> 31;
        hi = (sum < 0 && (sum & 64'sh7FFF_FFFF) != 0) ? floor_hi + 64'sd1
                                                      : floor_hi;

        // ---- STEP 2: arithmetic right shift, ties away from zero ------------
        if (sh_i == 5'd0) begin
            shifted = hi;
        end else begin
            mask      = (64'sd1 << sh_i) - 64'sd1;
            remainder = hi & mask;
            threshold = (mask >>> 1) + ((hi < 0) ? 64'sd1 : 64'sd0);
            shifted   = (hi >>> sh_i) + ((remainder > threshold) ? 64'sd1 : 64'sd0);
        end

        // ---- STEP 3: bias ---------------------------------------------------
        biased = shifted + 64'(zp_i);

        // ---- STEP 4: saturating clamp to int8 -------------------------------
        // Written without a part-select on `biased`: a constant select inside
        // an always_* process is not fully supported by Icarus, and the harness
        // must reach the same verdict under both simulators.
        if (biased > 64'sd127)       requant_lane = 8'sd127;
        else if (biased < -64'sd128) requant_lane = -8'sd128;
        else                         requant_lane = 8'(biased);
    endfunction

    logic [LANES*8-1:0] result_c;
    always_comb begin
        for (int unsigned i = 0; i < LANES; i++) begin
            result_c[i*8 +: 8] = requant_lane(
                $signed(acc  [i*32 +: 32]),
                $signed(mult [i*32 +: 32]),
                        shift[i*5  +:  5],
                $signed(zp[i*8 +: 8])
            );
        end
    end

    // -------------------------------------------------------------------------
    // Output register + backpressure. in_ready depends on out_ready but never
    // on in_valid (spec H1).
    // -------------------------------------------------------------------------
    assign in_ready = !out_valid || out_ready;

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            out_valid <= 1'b0;
            result    <= '0;
        end else begin
            if (in_valid && in_ready) begin
                out_valid <= 1'b1;
                result    <= result_c;
            end else if (out_valid && out_ready) begin
                out_valid <= 1'b0;
            end
        end
    end

endmodule
