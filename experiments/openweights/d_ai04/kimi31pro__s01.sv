module sdp_requant (
    input  logic         clk,
    input  logic         rst_n,

    input  logic [63:0]  in_data,
    input  logic         in_valid,
    output logic         in_ready,

    input  logic [ 1:0]  cfg_precision,
    input  logic [31:0]  cfg_offset,
    input  logic [15:0]  cfg_scale,
    input  logic [ 5:0]  cfg_truncate,
    input  logic         cfg_bypass,
    input  logic         cfg_nan_to_zero,

    output logic [127:0] out_data,
    output logic         out_valid,
    input  logic         out_ready
);

    logic [127:0] converted_word;
    logic [127:0] slot0;
    logic [127:0] slot1;
    logic [1:0]   count;
    logic [1:0]   next_count;
    logic         push;
    logic         pop;
    integer       lane_index;

    // Exact integer-mode lane operation. The difference needs 33 signed bits
    // and the product needs 49 signed bits.
    function automatic logic [31:0] integer_lane (
        input logic [15:0]        lane,
        input logic signed [31:0] offset,
        input logic signed [15:0] scale,
        input logic [5:0]         truncate,
        input logic               bypass
    );
        logic signed [32:0] difference;
        logic signed [48:0] product;
        logic [48:0]        magnitude;
        logic [63:0]        magnitude_ext;
        logic [63:0]        rounded_magnitude;
        logic               negative;
        begin
            if (bypass) begin
                integer_lane = {{16{lane[15]}}, lane};
            end else begin
                difference = $signed({{17{lane[15]}}, lane})
                           - $signed({offset[31], offset});
                product = difference * scale;

                negative = product[48];
                if (negative)
                    magnitude = ~product + 49'd1;
                else
                    magnitude = product;

                magnitude_ext = {15'd0, magnitude};

                // Rounding in the magnitude domain implements nearest,
                // ties away from zero for both signs.
                if (truncate == 0) begin
                    rounded_magnitude = magnitude_ext;
                end else begin
                    rounded_magnitude =
                        (magnitude_ext + (64'h1 << (truncate - 1'b1)))
                        >> truncate;
                end

                if (!negative) begin
                    if (rounded_magnitude > 64'h000000007fffffff)
                        integer_lane = 32'h7fffffff;
                    else
                        integer_lane = rounded_magnitude[31:0];
                end else begin
                    if (rounded_magnitude > 64'h0000000080000000)
                        integer_lane = 32'h80000000;
                    else
                        integer_lane = 32'd0 - rounded_magnitude[31:0];
                end
            end
        end
    endfunction

    function automatic logic [31:0] float_lane (
        input logic [15:0] half,
        input logic        nan_to_zero
    );
        logic       sign;
        logic [4:0] exponent;
        logic [9:0] fraction;
        logic [7:0] exponent32;
        logic [3:0] normalise_shift;
        logic [9:0] normalised;
        begin
            sign      = half[15];
            exponent  = half[14:10];
            fraction  = half[9:0];
            exponent32 = 8'd0;
            normalise_shift = 4'd0;
            normalised = 10'd0;

            if (exponent == 5'h1f) begin
                if (fraction == 0) begin
                    // Measured infinity behaviour: clamp to finite FLT_MAX.
                    float_lane = {sign, 8'hfe, 23'h7fffff};
                end else if (nan_to_zero) begin
                    float_lane = 32'h00000000;
                end else begin
                    float_lane = {sign, 8'hff, 13'd0, fraction};
                end
            end else if (exponent == 0) begin
                if (fraction == 0) begin
                    float_lane = {sign, 31'd0};
                end else begin
                    // Put the highest set fraction bit at bit 9. The binary32
                    // exponent is then 103 + original highest-bit position.
                    casez (fraction)
                        10'b1?????????: begin
                            normalise_shift = 4'd0;
                            exponent32 = 8'd112;
                        end
                        10'b01????????: begin
                            normalise_shift = 4'd1;
                            exponent32 = 8'd111;
                        end
                        10'b001???????: begin
                            normalise_shift = 4'd2;
                            exponent32 = 8'd110;
                        end
                        10'b0001??????: begin
                            normalise_shift = 4'd3;
                            exponent32 = 8'd109;
                        end
                        10'b00001?????: begin
                            normalise_shift = 4'd4;
                            exponent32 = 8'd108;
                        end
                        10'b000001????: begin
                            normalise_shift = 4'd5;
                            exponent32 = 8'd107;
                        end
                        10'b0000001???: begin
                            normalise_shift = 4'd6;
                            exponent32 = 8'd106;
                        end
                        10'b00000001??: begin
                            normalise_shift = 4'd7;
                            exponent32 = 8'd105;
                        end
                        10'b000000001?: begin
                            normalise_shift = 4'd8;
                            exponent32 = 8'd104;
                        end
                        default: begin
                            normalise_shift = 4'd9;
                            exponent32 = 8'd103;
                        end
                    endcase

                    normalised = fraction << normalise_shift;
                    float_lane = {sign, exponent32,
                                  normalised[8:0], 14'd0};
                end
            end else begin
                exponent32 = {3'd0, exponent} + 8'd112;
                float_lane = {sign, exponent32, fraction, 13'd0};
            end
        end
    endfunction

    // Configuration is used only when the corresponding input word is accepted;
    // the converted result, rather than the live configuration, is buffered.
    always_comb begin
        for (lane_index = 0; lane_index < 4; lane_index = lane_index + 1) begin
            if (cfg_precision == 2'd2) begin
                converted_word[32*lane_index +: 32] =
                    float_lane(in_data[16*lane_index +: 16],
                               cfg_nan_to_zero);
            end else begin
                converted_word[32*lane_index +: 32] =
                    integer_lane(in_data[16*lane_index +: 16],
                                 $signed(cfg_offset),
                                 $signed(cfg_scale),
                                 cfg_truncate,
                                 cfg_bypass);
            end
        end
    end

    assign out_valid = (count != 0);
    assign out_data  = slot0;
    assign push      = in_valid && in_ready;
    assign pop       = out_valid && out_ready;

    always_comb begin
        next_count = count;
        case ({push, pop})
            2'b10: next_count = count + 2'd1;
            2'b01: next_count = count - 2'd1;
            default: next_count = count;
        endcase
    end

    // Two slots provide a registered input-ready signal while retaining a word
    // accepted on the same cycle that the consumer begins stalling.
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count    <= 2'd0;
            in_ready <= 1'b1;
            slot0    <= 128'd0;
            slot1    <= 128'd0;
        end else begin
            count    <= next_count;
            in_ready <= (next_count != 2'd2);

            case ({push, pop})
                2'b10: begin
                    if (count == 0)
                        slot0 <= converted_word;
                    else
                        slot1 <= converted_word;
                end

                2'b01: begin
                    if (count == 2)
                        slot0 <= slot1;
                end

                2'b11: begin
                    if (count == 1) begin
                        slot0 <= converted_word;
                    end else if (count == 2) begin
                        slot0 <= slot1;
                        slot1 <= converted_word;
                    end
                end

                default: begin
                end
            endcase
        end
    end

endmodule
