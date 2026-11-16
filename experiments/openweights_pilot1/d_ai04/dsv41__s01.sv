// =============================================================================
// d_ai04 -- sdp_requant : 4-lane requantise / convert unit
// =============================================================================
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
    // fp16 -> fp32 conversion (F7-F9)
    // -------------------------------------------------------------------------
    function automatic logic [31:0] cvt_fp16_to_fp32(
        input logic [15:0] h,
        input logic        nan_to_zero
    );
        logic        sign;
        logic [4:0]  exp;
        logic [9:0]  mant;
        logic [4:0]  k;
        logic [4:0]  shift;
        logic [31:0] mant_shifted;
        logic [31:0] result;
        begin
            sign = h[15];
            exp  = h[14:10];
            mant = h[9:0];
            result = 32'b0;

            if (exp == 5'd0) begin
                if (mant == 10'd0) begin
                    // signed zero
                    result = {sign, 31'b0};
                end else begin
                    // subnormal -> normal fp32
                    casez (mant)
                        10'b1?????????: k = 5'd9;
                        10'b01????????: k = 5'd8;
                        10'b001???????: k = 5'd7;
                        10'b0001??????: k = 5'd6;
                        10'b00001?????: k = 5'd5;
                        10'b000001????: k = 5'd4;
                        10'b0000001???: k = 5'd3;
                        10'b00000001??: k = 5'd2;
                        10'b000000001?: k = 5'd1;
                        10'b0000000001: k = 5'd0;
                        default:        k = 5'd0;
                    endcase
                    shift = 5'd23 - k;
                    mant_shifted = {22'b0, mant} << shift;
                    result = {sign, (8'd103 + {3'b0, k}), mant_shifted[22:0]};
                end
            end else if (exp == 5'd31) begin
                if (mant == 10'd0) begin
                    // infinity clamps to FLT_MAX
                    result = sign ? 32'hFF7FFFFF : 32'h7F7FFFFF;
                end else if (nan_to_zero) begin
                    // NaN to zero
                    result = 32'h00000000;
                end else begin
                    // NaN preserves sign and payload in low mantissa bits
                    result = {sign, 8'hFF, 13'b0, mant[9:0]};
                end
            end else begin
                // normal fp16 -> normal fp32
                result = {sign, (exp + 8'd112), mant[9:0], 13'b0};
            end

            cvt_fp16_to_fp32 = result;
        end
    endfunction

    // -------------------------------------------------------------------------
    // integer requantise (F3-F6)
    // -------------------------------------------------------------------------
    function automatic logic [31:0] int_requant(
        input logic signed [15:0] x,
        input logic signed [31:0] offset,
        input logic signed [15:0] scale,
        input logic [5:0]         truncate,
        input logic               bypass
    );
        logic signed [32:0] diff;
        logic signed [48:0] prod;
        logic [48:0]        mag;
        logic [63:0]        mag64;
        logic [63:0]        half;
        logic [63:0]        rounded_mag64;
        logic signed [63:0] q;
        begin
            if (bypass) begin
                int_requant = {{16{x[15]}}, x};
            end else begin
                // Exact (x - offset), then exact product.
                diff = $signed({{17{x[15]}}, x}) - $signed({offset[31], offset});
                prod = diff * scale;

                // Round to nearest, ties away from zero.
                if (truncate == 6'd0) begin
                    q = prod;
                end else begin
                    if (prod[48]) begin
                        mag = (~prod) + 49'd1;
                    end else begin
                        mag = prod;
                    end
                    mag64 = {15'b0, mag};
                    half = 64'd1 << (truncate - 6'd1);
                    rounded_mag64 = (mag64 + half) >> truncate;

                    if (prod[48]) begin
                        q = -$signed(rounded_mag64);
                    end else begin
                        q = $signed(rounded_mag64);
                    end
                end

                // Saturate to signed 32-bit, last.
                if (q > 64'sd2147483647) begin
                    int_requant = 32'h7FFFFFFF;
                end else if (q < -64'sd2147483648) begin
                    int_requant = 32'h80000000;
                end else begin
                    int_requant = q[31:0];
                end
            end
        end
    endfunction

    // -------------------------------------------------------------------------
    // Combinational lane processing, sampled at acceptance.
    // -------------------------------------------------------------------------
    logic [127:0] in_word_converted;

    always_comb begin
        if (cfg_precision == 2'd2) begin
            // FLOAT mode: all integer controls inert.
            in_word_converted[31:0]   = cvt_fp16_to_fp32(in_data[15:0],  cfg_nan_to_zero);
            in_word_converted[63:32]  = cvt_fp16_to_fp32(in_data[31:16], cfg_nan_to_zero);
            in_word_converted[95:64]  = cvt_fp16_to_fp32(in_data[47:32], cfg_nan_to_zero);
            in_word_converted[127:96] = cvt_fp16_to_fp32(in_data[63:48], cfg_nan_to_zero);
        end else if (cfg_bypass) begin
            // INTEGER bypass: sign-extend each 16-bit lane.
            in_word_converted[31:0]   = {{16{in_data[15]}}, in_data[15:0]};
            in_word_converted[63:32]  = {{16{in_data[31]}}, in_data[31:16]};
            in_word_converted[95:64]  = {{16{in_data[47]}}, in_data[47:32]};
            in_word_converted[127:96] = {{16{in_data[63]}}, in_data[63:48]};
        end else begin
            // INTEGER requantise.
            in_word_converted[31:0]   = int_requant($signed(in_data[15:0]),  cfg_offset, cfg_scale, cfg_truncate, 1'b0);
            in_word_converted[63:32]  = int_requant($signed(in_data[31:16]), cfg_offset, cfg_scale, cfg_truncate, 1'b0);
            in_word_converted[95:64]  = int_requant($signed(in_data[47:32]), cfg_offset, cfg_scale, cfg_truncate, 1'b0);
            in_word_converted[127:96] = int_requant($signed(in_data[63:48]), cfg_offset, cfg_scale, cfg_truncate, 1'b0);
        end
    end

    // -------------------------------------------------------------------------
    // Two-entry output FIFO.  in_ready is registered; the second slot provides
    // lossless operation when the consumer stalls in the acceptance cycle.
    // -------------------------------------------------------------------------
    logic [127:0] fifo_data [0:1];
    logic [1:0]   fifo_count;
    logic         fifo_head;
    logic         in_ready_reg;

    assign in_ready = in_ready_reg;
    assign out_valid = (fifo_count != 2'd0);
    assign out_data  = (fifo_count != 2'd0) ? fifo_data[fifo_head] : 128'b0;

    always_ff @(posedge clk or negedge rst_n) begin
        logic [1:0] next_count;
        logic       push_fire;
        logic       pop_fire;
        logic       push_index;

        if (!rst_n) begin
            fifo_count   <= 2'd0;
            fifo_head    <= 1'b0;
            in_ready_reg <= 1'b1;
            fifo_data[0] <= 128'b0;
            fifo_data[1] <= 128'b0;
        end else begin
            push_fire = in_valid && in_ready_reg;
            pop_fire  = (fifo_count != 2'd0) && out_ready;

            next_count = fifo_count
                       + (push_fire ? 2'd1 : 2'd0)
                       - (pop_fire  ? 2'd1 : 2'd0);

            // With depth 2, when count==1 the empty slot is the opposite of head.
            push_index = fifo_head ^ fifo_count[0];

            if (push_fire) begin
                fifo_data[push_index] <= in_word_converted;
            end

            if (pop_fire) begin
                fifo_head <= ~fifo_head;
            end

            fifo_count   <= next_count;
            in_ready_reg <= (next_count < 2'd2);
        end
    end

endmodule
