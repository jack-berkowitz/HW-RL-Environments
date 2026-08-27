// =============================================================================
// d_ai04 -- sdp_requant
// =============================================================================

module sdp_requant (
    input  logic         clk,
    input  logic         rst_n,

    // input stream -- one 64b word carrying four 16b lanes
    input  logic [63:0]  in_data,
    input  logic         in_valid,
    output logic         in_ready,

    // configuration
    input  logic [ 1:0]  cfg_precision,
    input  logic [31:0]  cfg_offset,
    input  logic [15:0]  cfg_scale,
    input  logic [ 5:0]  cfg_truncate,
    input  logic         cfg_bypass,
    input  logic         cfg_nan_to_zero,

    // output stream -- one 128b word carrying four 32b lanes
    output logic [127:0] out_data,
    output logic         out_valid,
    input  logic         out_ready
);

    // =========================================================================
    // INTEGER LANE
    //
    //   sat32(
    //       round_ties_away(
    //           (x - offset) * scale / 2^truncate
    //       )
    //   )
    //
    // x-offset requires 33 signed bits.
    //
    // Maximum magnitude:
    //
    //   (2^31 + 32767) * 32768
    //
    // which is > 2^46 but < 2^47, so a signed 48-bit product is sufficient.
    // =========================================================================

    function automatic logic [31:0] requant_int_lane (
        input logic [15:0] lane_i,
        input logic [31:0] offset_i,
        input logic [15:0] scale_i,
        input logic [ 5:0] truncate_i,
        input logic        bypass_i
    );

        logic signed [32:0] x_ext_s;
        logic signed [32:0] offset_ext_s;
        logic signed [32:0] diff_s;

        logic signed [47:0] diff_mul_s;
        logic signed [15:0] scale_s;
        logic signed [47:0] product_s;
        logic signed [48:0] product_ext_s;

        logic [48:0] magnitude_u;
        logic [48:0] quotient_u;
        logic [48:0] remainder_u;
        logic [48:0] remainder_mask_u;
        logic [48:0] half_u;
        logic [48:0] rounded_mag_u;

        logic signed [49:0] rounded_s;

        begin
            x_ext_s          = 33'sd0;
            offset_ext_s     = 33'sd0;
            diff_s           = 33'sd0;
            diff_mul_s       = 48'sd0;
            scale_s          = 16'sd0;
            product_s        = 48'sd0;
            product_ext_s    = 49'sd0;

            magnitude_u      = 49'd0;
            quotient_u       = 49'd0;
            remainder_u      = 49'd0;
            remainder_mask_u = 49'd0;
            half_u           = 49'd0;
            rounded_mag_u    = 49'd0;

            rounded_s        = 50'sd0;

            // -------------------------------------------------------------
            // Integer bypass: raw signed input lane extended to 32 bits.
            // -------------------------------------------------------------
            if (bypass_i) begin
                requant_int_lane = {{16{lane_i[15]}}, lane_i};
            end
            else begin
                // ---------------------------------------------------------
                // Exact subtraction.
                //
                // x is signed 16-bit.
                // offset is signed 32-bit.
                // Difference requires signed 33 bits.
                // ---------------------------------------------------------
                x_ext_s      = {{17{lane_i[15]}}, lane_i};
                offset_ext_s = {offset_i[31], offset_i};

                diff_s = x_ext_s - offset_ext_s;

                // ---------------------------------------------------------
                // Exact multiplication.
                //
                // Sign extend the 33-bit difference before multiplication
                // so the expression has enough width for the exact result.
                // ---------------------------------------------------------
                diff_mul_s = {{15{diff_s[32]}}, diff_s};
                scale_s    = $signed(scale_i);

                product_s = diff_mul_s * scale_s;

                // One extra bit makes taking the absolute value safe.
                product_ext_s = {product_s[47], product_s};

                if (product_ext_s < 49'sd0) begin
                    magnitude_u = $unsigned(-product_ext_s);
                end
                else begin
                    magnitude_u = $unsigned(product_ext_s);
                end

                // ---------------------------------------------------------
                // Round to nearest, ties AWAY from zero.
                //
                // Perform rounding on the magnitude:
                //
                //     q = |v| >> t
                //
                // and increment q whenever the discarded portion is
                // >= 2^(t-1).
                //
                // Sign is restored only after rounding.
                // ---------------------------------------------------------
                if (truncate_i == 6'd0) begin
                    rounded_mag_u = magnitude_u;
                end
                else if (truncate_i >= 6'd48) begin
                    // |product| < 2^47.  Therefore for t >= 48 the
                    // magnitude is strictly below the half-way point.
                    rounded_mag_u = 49'd0;
                end
                else begin
                    quotient_u = magnitude_u >> truncate_i;

                    remainder_mask_u =
                        (49'd1 << truncate_i) - 49'd1;

                    remainder_u =
                        magnitude_u & remainder_mask_u;

                    half_u =
                        49'd1 << (truncate_i - 6'd1);

                    if (remainder_u >= half_u) begin
                        rounded_mag_u = quotient_u + 49'd1;
                    end
                    else begin
                        rounded_mag_u = quotient_u;
                    end
                end

                // Restore sign after magnitude-domain rounding.
                if (product_s[47]) begin
                    rounded_s = -$signed({1'b0, rounded_mag_u});
                end
                else begin
                    rounded_s = $signed({1'b0, rounded_mag_u});
                end

                // ---------------------------------------------------------
                // Signed 32-bit saturation happens LAST.
                // ---------------------------------------------------------
                if (rounded_s > 50'sd2147483647) begin
                    requant_int_lane = 32'h7FFF_FFFF;
                end
                else if (rounded_s < -50'sd2147483648) begin
                    requant_int_lane = 32'h8000_0000;
                end
                else begin
                    requant_int_lane = rounded_s[31:0];
                end
            end
        end
    endfunction


    // =========================================================================
    // FLOAT LANE
    //
    // Exact binary16 -> binary32 conversion with the contract's special
    // infinity and NaN behavior.
    // =========================================================================

    function automatic logic [31:0] fp16_to_fp32 (
        input logic [15:0] half_i,
        input logic        nan_to_zero_i
    );

        logic        sign;
        logic [4:0]  exp;
        logic [9:0]  frac;

        logic [7:0]  exp32;
        logic [22:0] frac32;

        begin
            sign   = half_i[15];
            exp    = half_i[14:10];
            frac   = half_i[9:0];

            exp32  = 8'd0;
            frac32 = 23'd0;

            // -------------------------------------------------------------
            // Zero / subnormal
            // -------------------------------------------------------------
            if (exp == 5'h00) begin
                if (frac == 10'h000) begin
                    // Preserve signed zero.
                    fp16_to_fp32 = {sign, 31'd0};
                end
                else begin
                    // -----------------------------------------------------
                    // Every binary16 subnormal becomes a NORMAL binary32
                    // value.
                    //
                    // Decode the leading one.  For leading-one position p:
                    //
                    //     unbiased exponent = p - 24
                    //     fp32 exponent     = p + 103
                    //
                    // The leading one itself is removed from the fp32
                    // mantissa.
                    // -----------------------------------------------------
                    casez (frac)
                        10'b1?????????: begin
                            exp32  = 8'd112;
                            frac32 = {frac[8:0], 14'b0};
                        end

                        10'b01????????: begin
                            exp32  = 8'd111;
                            frac32 = {frac[7:0], 15'b0};
                        end

                        10'b001???????: begin
                            exp32  = 8'd110;
                            frac32 = {frac[6:0], 16'b0};
                        end

                        10'b0001??????: begin
                            exp32  = 8'd109;
                            frac32 = {frac[5:0], 17'b0};
                        end

                        10'b00001?????: begin
                            exp32  = 8'd108;
                            frac32 = {frac[4:0], 18'b0};
                        end

                        10'b000001????: begin
                            exp32  = 8'd107;
                            frac32 = {frac[3:0], 19'b0};
                        end

                        10'b0000001???: begin
                            exp32  = 8'd106;
                            frac32 = {frac[2:0], 20'b0};
                        end

                        10'b00000001??: begin
                            exp32  = 8'd105;
                            frac32 = {frac[1:0], 21'b0};
                        end

                        10'b000000001?: begin
                            exp32  = 8'd104;
                            frac32 = {frac[0], 22'b0};
                        end

                        10'b0000000001: begin
                            exp32  = 8'd103;
                            frac32 = 23'd0;
                        end

                        default: begin
                            exp32  = 8'd0;
                            frac32 = 23'd0;
                        end
                    endcase

                    fp16_to_fp32 = {sign, exp32, frac32};
                end
            end

            // -------------------------------------------------------------
            // Infinity / NaN
            // -------------------------------------------------------------
            else if (exp == 5'h1F) begin
                if (frac == 10'h000) begin
                    // Infinity is CLAMPED to FLT_MAX.
                    fp16_to_fp32 = {
                        sign,
                        8'hFE,
                        23'h7F_FFFF
                    };
                end
                else if (nan_to_zero_i) begin
                    // NaN of either sign becomes +0.
                    fp16_to_fp32 = 32'h0000_0000;
                end
                else begin
                    // Preserve sign and place the 10-bit half payload
                    // in the LOW bits of the fp32 mantissa.
                    fp16_to_fp32 = {
                        sign,
                        8'hFF,
                        13'b0,
                        frac
                    };
                end
            end

            // -------------------------------------------------------------
            // Normal binary16 value
            // -------------------------------------------------------------
            else begin
                // Bias conversion:
                //
                //     E32 = E16 - 15 + 127
                //         = E16 + 112
                //
                exp32  = 8'd112 + {3'b000, exp};
                frac32 = {frac, 13'b0};

                fp16_to_fp32 = {sign, exp32, frac32};
            end
        end
    endfunction


    // =========================================================================
    // FOUR-LANE WORD CONVERSION
    // =========================================================================

    function automatic logic [127:0] convert_word (
        input logic [63:0] data_i,
        input logic [ 1:0] precision_i,
        input logic [31:0] offset_i,
        input logic [15:0] scale_i,
        input logic [ 5:0] truncate_i,
        input logic        bypass_i,
        input logic        nan_to_zero_i
    );

        integer k;
        logic [15:0] lane;

        begin
            convert_word = 128'd0;
            lane         = 16'd0;

            for (k = 0; k < 4; k = k + 1) begin
                lane = data_i[(16*k) +: 16];

                if (precision_i == 2'd2) begin
                    // Float mode.  offset/scale/truncate/bypass are inert.
                    convert_word[(32*k) +: 32] =
                        fp16_to_fp32(
                            lane,
                            nan_to_zero_i
                        );
                end
                else begin
                    // Precision encodings 0, 1 and 3 are identical integer
                    // mode.
                    convert_word[(32*k) +: 32] =
                        requant_int_lane(
                            lane,
                            offset_i,
                            scale_i,
                            truncate_i,
                            bypass_i
                        );
                end
            end
        end
    endfunction


    // =========================================================================
    // TWO-ENTRY ELASTIC OUTPUT FIFO
    //
    // A single output register is insufficient because in_ready must itself
    // be registered.  If the consumer stalls while in_ready is still high,
    // one additional accepted word needs somewhere to go.
    //
    // The two-entry FIFO is the minimum storage needed here.
    // =========================================================================

    logic [127:0] slot0;
    logic [127:0] slot1;

    logic [1:0] count;
    logic [1:0] next_count;

    logic       push;
    logic       pop;
    logic       in_ready_next;

    logic [127:0] converted_word;


    // Arithmetic/configuration are sampled from the values present for the
    // input transfer.  Once accepted, only the converted result is buffered.
    assign converted_word =
        convert_word(
            in_data,
            cfg_precision,
            cfg_offset,
            cfg_scale,
            cfg_truncate,
            cfg_bypass,
            cfg_nan_to_zero
        );


    // Current output is always the oldest buffered word.
    assign out_valid = (count != 2'd0);
    assign out_data  = slot0;

    assign push = in_valid && in_ready;
    assign pop  = out_valid && out_ready;


    // =========================================================================
    // NEXT OCCUPANCY / REGISTERED READY
    //
    // in_ready is NOT combinationally assigned from this expression.  Only
    // in_ready_next depends on the current-cycle handshakes; in_ready itself
    // changes solely on clk edges.
    // =========================================================================

    always_comb begin
        next_count = count;

        case ({push, pop})
            2'b10: begin
                next_count = count + 2'd1;
            end

            2'b01: begin
                next_count = count - 2'd1;
            end

            default: begin
                next_count = count;
            end
        endcase

        if (next_count < 2'd2) begin
            in_ready_next = 1'b1;
        end
        else begin
            in_ready_next = 1'b0;
        end
    end


    // =========================================================================
    // FIFO STATE
    // =========================================================================

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            slot0    <= 128'd0;
            slot1    <= 128'd0;
            count    <= 2'd0;
            in_ready <= 1'b1;
        end
        else begin
            count    <= next_count;
            in_ready <= in_ready_next;

            case ({push, pop})

                // ---------------------------------------------------------
                // Push only
                // ---------------------------------------------------------
                2'b10: begin
                    if (count == 2'd0) begin
                        slot0 <= converted_word;
                    end
                    else if (count == 2'd1) begin
                        slot1 <= converted_word;
                    end
                end

                // ---------------------------------------------------------
                // Pop only
                // ---------------------------------------------------------
                2'b01: begin
                    if (count == 2'd2) begin
                        slot0 <= slot1;
                    end
                end

                // ---------------------------------------------------------
                // Simultaneous push + pop
                //
                // Normally this occurs with count==1 during open flow:
                // replace the word being consumed with the new word.
                //
                // The count==2 case is included defensively and implements
                // the natural full-FIFO pop/push behavior.
                // ---------------------------------------------------------
                2'b11: begin
                    if (count == 2'd1) begin
                        slot0 <= converted_word;
                    end
                    else if (count == 2'd2) begin
                        slot0 <= slot1;
                        slot1 <= converted_word;
                    end
                end

                default: begin
                    // Hold FIFO contents.
                end
            endcase
        end
    end

endmodule