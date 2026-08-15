module int8_requant #(
    parameter int LANES = 4          // 1 / 2 / 4 / 8
) (
    input  logic                  clk,
    input  logic                  rst_n,

    // input stream
    input  logic                  in_valid,
    output logic                  in_ready,
    input  logic [LANES*32-1:0]   acc,
    input  logic [LANES*32-1:0]   mult,
    input  logic [LANES*5-1:0]    shift,
    input  logic [LANES*8-1:0]    zp,

    // output stream
    output logic                  out_valid,
    input  logic                  out_ready,
    output logic [LANES*8-1:0]    result
);

    // Goes high one cycle after reset is released.
    // This guarantees out_valid == 0 for the first post-reset cycle.
    logic active;

    // -------------------------------------------------------------------------
    // Per-lane requantisation
    // -------------------------------------------------------------------------
    function automatic logic signed [7:0] requant_lane (
        input logic signed [31:0] acc_i,
        input logic signed [31:0] mult_i,
        input logic        [4:0]  shift_i,
        input logic signed [7:0]  zp_i
    );

        logic signed [63:0] acc64;
        logic signed [63:0] mult64;

        logic signed [63:0] p;
        logic signed [63:0] nudge;
        logic signed [63:0] numerator;
        logic signed [63:0] dhim;

        logic signed [63:0] mask;
        logic signed [63:0] remainder;
        logic signed [63:0] threshold;
        logic signed [63:0] shifted;

        logic signed [63:0] zp64;
        logic signed [63:0] biased;

        begin
            // Explicit sign extension is important: it guarantees that the
            // multiplication is performed at 64-bit width.
            acc64  = {{32{acc_i[31]}},  acc_i};
            mult64 = {{32{mult_i[31]}}, mult_i};

            // -----------------------------------------------------------------
            // STEP 1: DHIMUL
            //
            // p = acc * mult
            //
            // Positive nudge:  2^30
            // Negative nudge:  1 - 2^30 = -1073741823
            //
            // Signed SystemVerilog division truncates toward zero.
            // -----------------------------------------------------------------
            p = acc64 * mult64;

            if (p >= 64'sd0)
                nudge = 64'sd1073741824;
            else
                nudge = -64'sd1073741823;

            numerator = p + nudge;

            dhim = numerator / 64'sd2147483648;   // 2^31

            // -----------------------------------------------------------------
            // STEP 2: rounded arithmetic right shift
            // -----------------------------------------------------------------
            if (shift_i == 5'd0) begin
                shifted = dhim;
            end
            else begin
                mask =
                    (64'sd1 <<< shift_i) - 64'sd1;

                // Two's-complement bitwise AND, exactly as specified.
                remainder = dhim & mask;

                threshold =
                    (mask >>> 1)
                    + ((dhim < 64'sd0) ? 64'sd1 : 64'sd0);

                shifted =
                    (dhim >>> shift_i)
                    + ((remainder > threshold) ?
                       64'sd1 : 64'sd0);
            end

            // -----------------------------------------------------------------
            // STEP 3: per-lane zero-point bias
            // -----------------------------------------------------------------
            zp64 = {{56{zp_i[7]}}, zp_i};

            biased = shifted + zp64;

            // -----------------------------------------------------------------
            // STEP 4: saturate to signed INT8
            // -----------------------------------------------------------------
            if (biased > 64'sd127)
                requant_lane = 8'sh7f;       // +127
            else if (biased < -64'sd128)
                requant_lane = 8'sh80;       // -128
            else
                requant_lane = biased[7:0];
        end
    endfunction


    // -------------------------------------------------------------------------
    // One-entry elastic output buffer.
    //
    // We can accept an input when:
    //   1. the output slot is currently empty, or
    //   2. the existing output will be consumed on this edge.
    //
    // There is intentionally no dependence on in_valid, satisfying H1.
    // -------------------------------------------------------------------------
    always_comb begin
        in_ready = active && (!out_valid || out_ready);
    end


    // -------------------------------------------------------------------------
    // Stream state
    // -------------------------------------------------------------------------
    always_ff @(posedge clk) begin : stream_regs
        integer lane;

        if (!rst_n) begin
            active    <= 1'b0;
            out_valid <= 1'b0;

            // result is don't-care when out_valid == 0.
        end
        else if (!active) begin
            // Mandatory first post-reset cycle:
            // no stale output may appear.
            active    <= 1'b1;
            out_valid <= 1'b0;
        end
        else begin
            // A new beat is accepted.
            if (in_valid && in_ready) begin
                for (lane = 0; lane < LANES; lane = lane + 1) begin
                    result[lane*8 +: 8] <= requant_lane(
                        $signed(acc  [lane*32 +: 32]),
                        $signed(mult [lane*32 +: 32]),
                                shift[lane*5  +: 5 ],
                        $signed(zp    [lane*8  +: 8 ])
                    );
                end

                out_valid <= 1'b1;
            end

            // No replacement beat, but current output was consumed.
            else if (out_valid && out_ready) begin
                out_valid <= 1'b0;
            end

            // Otherwise hold both out_valid and result unchanged.
            // In particular, this covers out_valid && !out_ready.
        end
    end

endmodule
