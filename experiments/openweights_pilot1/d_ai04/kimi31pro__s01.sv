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

    // -------------------------------------------------------------------------
    // Integer lane conversion
    // -------------------------------------------------------------------------
    // x-offset needs 33 signed bits.  The exact 33-by-16 product is kept in
    // 49 signed bits.  Rounding is performed on the magnitude so that ties
    // round away from zero for both signs.
    function automatic logic [31:0] integer_lane (
        input logic signed [15:0] x,
        input logic signed [31:0] offset,
        input logic signed [15:0] scale,
        input logic        [ 5:0] truncate
    );
        logic signed [32:0] difference;
        logic signed [48:0] product;
        logic        [48:0] magnitude;
        logic        [48:0] rounded_magnitude;
        begin
            difference = $signed({{17{x[15]}}, x})
                       - $signed({offset[31], offset});
            product = difference * scale;

            if (product[48])
                magnitude = (~product) + 49'd1;
            else
                magnitude = product;

            if (truncate == 6'd0) begin
                rounded_magnitude = magnitude;
            end
            else if (truncate >= 6'd49) begin
                // The exact product is smaller than 2^47, so these shifts
                // cannot produce a nonzero rounded result.
                rounded_magnitude = 49'd0;
            end
            else begin
                rounded_magnitude = magnitude >> truncate;

                // Bit t-1 is set exactly when the discarded remainder is
                // at least one half of the divisor.  Incrementing the
                // magnitude implements nearest, ties away from zero.
                if (magnitude[truncate - 6'd1])
                    rounded_magnitude = rounded_magnitude + 49'd1;
            end

            if (!product[48]) begin
                if (rounded_magnitude > 49'd2147483647)
                    integer_lane = 32'h7FFFFFFF;
                else
                    integer_lane = rounded_magnitude[31:0];
            end
            else begin
                if (rounded_magnitude > 49'd2147483648)
                    integer_lane = 32'h80000000;
                else
                    integer_lane = (~rounded_magnitude[31:0]) + 32'd1;
            end
        end
    endfunction

    // -------------------------------------------------------------------------
    // Exact binary16 to binary32 conversion
    // -------------------------------------------------------------------------
    function automatic logic [31:0] float_lane (
        input logic [15:0] half,
        input logic        nan_to_zero
    );
        logic        sign;
        logic [9:0]  mantissa;
        logic [3:0]  leading;
        logic [7:0]  exponent;
        logic [31:0] shifted;
        begin
            sign     = half[15];
            mantissa = half[9:0];

            if (half[14:10] == 5'd0) begin
                if (mantissa == 10'd0) begin
                    // Preserve signed zero.
                    float_lane = {sign, 31'd0};
                end
                else begin
                    // A subnormal half has value mantissa * 2^-24.  If its
                    // leading one is at bit p, the unbiased exponent is p-24
                    // and the binary32 exponent field is therefore p+103.
                    casez (mantissa)
                        10'b1?????????: leading = 4'd9;
                        10'b01????????: leading = 4'd8;
                        10'b001???????: leading = 4'd7;
                        10'b0001??????: leading = 4'd6;
                        10'b00001?????: leading = 4'd5;
                        10'b000001????: leading = 4'd4;
                        10'b0000001???: leading = 4'd3;
                        10'b00000001??: leading = 4'd2;
                        10'b000000001?: leading = 4'd1;
                        default:        leading = 4'd0;
                    endcase

                    exponent = 8'd103 + {4'd0, leading};

                    // The leading one moves to bit 23 and is omitted from
                    // the stored binary32 mantissa.
                    shifted = {22'd0, mantissa}
                            << (5'd23 - {1'b0, leading});
                    float_lane = {sign, exponent, shifted[22:0]};
                end
            end
            else if (half[14:10] == 5'h1F) begin
                if (mantissa == 10'd0) begin
                    // Infinity is clamped to the largest finite magnitude.
                    float_lane = {sign, 8'hFE, 23'h7FFFFF};
                end
                else if (nan_to_zero) begin
                    float_lane = 32'h00000000;
                end
                else begin
                    // Preserve sign and place the payload in the low bits.
                    float_lane = {sign, 8'hFF, 13'd0, mantissa};
                end
            end
            else begin
                // Normal binary16: rebias the exponent and append 13 zeroes.
                exponent = {3'd0, half[14:10]} + 8'd112;
                float_lane = {sign, exponent, mantissa, 13'd0};
            end
        end
    endfunction

    // -------------------------------------------------------------------------
    // Conversion is completed before storage, so all configuration inputs are
    // sampled on the same edge that accepts the corresponding input word.
    // -------------------------------------------------------------------------
    logic [127:0] converted_data;

    genvar lane;
    generate
        for (lane = 0; lane < 4; lane = lane + 1) begin : g_lanes
            assign converted_data[32*lane +: 32] =
                (cfg_precision == 2'd2)
                    ? float_lane(in_data[16*lane +: 16], cfg_nan_to_zero)
                    : (cfg_bypass
                        ? {{16{in_data[16*lane+15]}},
                           in_data[16*lane +: 16]}
                        : integer_lane(
                              $signed(in_data[16*lane +: 16]),
                              $signed(cfg_offset),
                              $signed(cfg_scale),
                              cfg_truncate));
        end
    endgenerate

    // -------------------------------------------------------------------------
    // Two-slot elastic buffer.
    //
    // in_ready is changed only in the sequential block.  The second slot
    // absorbs a word accepted immediately before or during the transition to
    // a full backpressured state, while the head register holds out_data
    // stable throughout a stall.
    // -------------------------------------------------------------------------
    logic [127:0] head_data;
    logic [127:0] tail_data;
    logic [1:0]   count;
    logic [1:0]   count_next;
    logic         push;
    logic         pop;

    assign out_valid = (count != 2'd0);
    assign out_data  = head_data;

    assign push = in_valid && in_ready;
    assign pop  = out_valid && out_ready;

    always_comb begin
        count_next = count;
        case ({push, pop})
            2'b10:   count_next = count + 2'd1;
            2'b01:   count_next = count - 2'd1;
            default: count_next = count;
        endcase
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count     <= 2'd0;
            in_ready  <= 1'b1;
            head_data <= 128'd0;
            tail_data <= 128'd0;
        end
        else begin
            count    <= count_next;
            in_ready <= (count_next < 2'd2);

            case ({push, pop})
                2'b10: begin
                    if (count == 2'd0)
                        head_data <= converted_data;
                    else
                        tail_data <= converted_data;
                end

                2'b01: begin
                    if (count == 2'd2)
                        head_data <= tail_data;
                end

                2'b11: begin
                    if (count == 2'd1) begin
                        // The old head is consumed and the new word becomes
                        // the head without interrupting one-word-per-cycle
                        // operation.
                        head_data <= converted_data;
                    end
                    else begin
                        head_data <= tail_data;
                        tail_data <= converted_data;
                    end
                end

                default: begin
                    // Hold both storage slots.
                end
            endcase
        end
    end

endmodule
