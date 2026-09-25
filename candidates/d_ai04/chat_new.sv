// Four-lane SDP conversion, with a two-word registered-ready output FIFO.
// Arithmetic is evaluated from the inputs/configuration at acceptance.
// Empty-FIFO acceptance becomes visible immediately after that clock edge.
module sdp_requant (
    input  logic         clk,
    input  logic         rst_n,
    input  logic [63:0]  in_data,
    input  logic         in_valid,
    output logic         in_ready,
    input  logic [1:0]   cfg_precision,
    input  logic [31:0]  cfg_offset,
    input  logic [15:0]  cfg_scale,
    input  logic [5:0]   cfg_truncate,
    input  logic         cfg_bypass,
    input  logic         cfg_nan_to_zero,
    output logic [127:0] out_data,
    output logic         out_valid,
    input  logic         out_ready
);
    logic signed [47:0] offset_product;
    logic [127:0] converted;
    logic [127:0] spare_data;
    logic [1:0] count_q, count_d;
    logic push, pop;

    // (x-offset)*scale = x*scale - offset*scale, exactly over integers.
    // One shared 32x16 product replaces four separate 33x16 products.
    // |x-offset| <= 2^31+32768 and |scale| <= 2^15, so the
    // product magnitude is <= 2^46+2^30: signed 48 bits suffice.
    assign offset_product = $signed(cfg_offset) * $signed({{16{cfg_scale[15]}},cfg_scale});

    function automatic logic [31:0] requantize (
        input logic signed [47:0] product,
        input logic [5:0] truncate
    );
        logic negative;
        logic [47:0] magnitude, quotient, rounded;
        logic increment;
        begin
            negative = product[47];
            magnitude = negative ? (~$unsigned(product) + 48'd1) : $unsigned(product);
            // Logical shifts >=48 return zero. No signed-shift floor bias.
            quotient = magnitude >> truncate;
            increment = 1'b0;
            if ((truncate != 0) && (truncate <= 6'd48))
                increment = magnitude[truncate - 6'd1];
            rounded = quotient + {47'b0, increment};
            if (!negative) begin
                if (rounded > 48'h00007fffffff) requantize = 32'h7fffffff;
                else requantize = rounded[31:0];
            end else begin
                if (rounded >= 48'h000080000000) requantize = 32'h80000000;
                else requantize = ~rounded[31:0] + 32'd1;
            end
        end
    endfunction

    function automatic logic [31:0] convert_float (
        input logic [15:0] half_value,
        input logic nan_to_zero
    );
        logic sign_bit;
        logic [4:0] exponent;
        logic [9:0] fraction;
        logic [3:0] top_bit;
        logic [7:0] exponent32;
        logic [22:0] fraction32;
        begin
            sign_bit = half_value[15];
            exponent = half_value[14:10];
            fraction = half_value[9:0];
            top_bit = 0;
            exponent32 = 0;
            fraction32 = 0;
            if (exponent == 5'd31) begin
                if (fraction == 0)
                    convert_float = {sign_bit, 31'h7f7fffff};
                else if (nan_to_zero)
                    convert_float = 32'b0;
                else
                    convert_float = {sign_bit, 8'hff, 13'b0, fraction};
            end else if (exponent != 0) begin
                exponent32 = {3'b0,exponent} + 8'd112;
                convert_float = {sign_bit, exponent32, fraction, 13'b0};
            end else if (fraction == 0) begin
                convert_float = {sign_bit,31'b0};
            end else begin
                // Highest set fraction bit j represents 2^(j-24).
                // The FP32 biased exponent is therefore j+103.
                casez (fraction)
                    10'b1?????????: top_bit = 4'd9;
                    10'b01????????: top_bit = 4'd8;
                    10'b001???????: top_bit = 4'd7;
                    10'b0001??????: top_bit = 4'd6;
                    10'b00001?????: top_bit = 4'd5;
                    10'b000001????: top_bit = 4'd4;
                    10'b0000001???: top_bit = 4'd3;
                    10'b00000001??: top_bit = 4'd2;
                    10'b000000001?: top_bit = 4'd1;
                    default: top_bit = 4'd0;
                endcase
                exponent32 = 8'd103 + {4'b0,top_bit};
                // Shifting the leading one to bit 23 discards the hidden bit.
                fraction32 = {13'b0,fraction} << (5'd23 - {1'b0,top_bit});
                convert_float = {sign_bit,exponent32,fraction32};
            end
        end
    endfunction

    for (genvar k=0; k<4; k++) begin : lanes
        logic signed [31:0] lane_product;
        logic signed [47:0] exact_product;
        assign lane_product = $signed(in_data[k*16 +: 16]) * $signed(cfg_scale);
        assign exact_product = $signed({{16{lane_product[31]}},lane_product}) - offset_product;
        always_comb begin
            if (cfg_precision == 2'd2)
                converted[k*32 +: 32] = convert_float(in_data[k*16 +: 16],cfg_nan_to_zero);
            else if (cfg_bypass)
                converted[k*32 +: 32] = {{16{in_data[k*16+15]}},in_data[k*16 +: 16]};
            else
                converted[k*32 +: 32] = requantize(exact_product,cfg_truncate);
        end
    end

    assign push = in_valid && in_ready;
    assign pop = out_valid && out_ready;
    assign out_valid = (count_q != 0);
    always_comb begin
        count_d = count_q;
        case ({push,pop})
            2'b10: count_d = count_q + 2'd1;
            2'b01: count_d = count_q - 2'd1;
            default: count_d = count_q;
        endcase
    end

    // in_ready is a flip-flop, never a combinational function of out_ready.
    // One extra slot absorbs an accepted word at a sudden consumer stall.
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count_q <= 0;
            in_ready <= 1'b1;
            out_data <= 0;
            spare_data <= 0;
        end else begin
            count_q <= count_d;
            in_ready <= (count_d < 2);
            if (pop && (count_q == 2)) out_data <= spare_data;
            if (push) begin
                if ((count_q == 0) || (pop && (count_q == 1)))
                    out_data <= converted;
                else spare_data <= converted;
            end
        end
    end
endmodule
