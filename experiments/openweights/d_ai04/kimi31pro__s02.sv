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

    // Two entries are required with registered in_ready: one can be presented
    // at the output while the other absorbs a word accepted during a stall.
    logic [127:0] storage0;
    logic [127:0] storage1;
    logic [127:0] converted_word;

    logic [1:0] count;
    logic [1:0] count_next;
    logic       push;
    logic       pop;

    integer lane_index;

    // Integer-mode lane operation.
    //
    // x-offset needs 33 signed bits.  The subsequent signed 33-by-16 product
    // needs 49 bits.  Rounding is performed on the unsigned magnitude so that
    // negative ties round away from zero rather than toward positive infinity.
    function automatic logic [31:0] integer_result (
        input logic signed [15:0] x,
        input logic signed [31:0] offset,
        input logic signed [15:0] scale,
        input logic        [ 5:0] shift_amount,
        input logic               bypass
    );
        logic signed [32:0] difference;
        logic signed [48:0] difference_wide;
        logic signed [48:0] product;
        logic        [48:0] magnitude;
        logic        [63:0] magnitude_ext;
        logic        [63:0] rounded;
        logic               negative;
        begin
            difference      = '0;
            difference_wide = '0;
            product         = '0;
            magnitude       = '0;
            magnitude_ext   = '0;
            rounded         = '0;
            negative        = 1'b0;

            if (bypass) begin
                integer_result = {{16{x[15]}}, x};
            end else begin
                difference = $signed({{17{x[15]}}, x})
                           - $signed({offset[31], offset});

                // The widened operand makes the multiplication expression
                // 49 bits wide; the mathematical product fits in those bits.
                difference_wide = {{16{difference[32]}}, difference};
                product         = difference_wide * scale;

                negative  = product[48];
                magnitude = negative ? (~product + 49'd1) : product;

                magnitude_ext = {15'b0, magnitude};
                rounded       = magnitude_ext;

                if (shift_amount != 6'd0) begin
                    rounded = (magnitude_ext
                               + (64'd1 << (shift_amount - 6'd1)))
                              >> shift_amount;
                end

                if (!negative) begin
                    if (rounded > 64'h000000007FFFFFFF)
                        integer_result = 32'h7FFFFFFF;
                    else
                        integer_result = rounded[31:0];
                end else begin
                    if (rounded > 64'h0000000080000000)
                        integer_result = 32'h80000000;
                    else
                        integer_result = 32'd0 - rounded[31:0];
                end
            end
        end
    endfunction

    // Exact binary16 to binary32 conversion, including normalisation of
    // binary16 subnormals.
    function automatic logic [31:0] float_result (
        input logic [15:0] half,
        input logic        nan_to_zero
    );
        logic [7:0]  exponent32;
        logic [22:0] fraction32;
        begin
            exponent32 = 8'd0;
            fraction32 = 23'd0;

            if (half[14:10] == 5'd0) begin
                if (half[9:0] == 10'd0) begin
                    // Preserve signed zero.
                    float_result = {half[15], 31'b0};
                end else begin
                    // A subnormal with leading one at bit p has binary32
                    // exponent field p+103.  The remaining bits are aligned
                    // directly into the binary32 fraction field.
                    casez (half[9:0])
                        10'b1?????????: begin
                            exponent32 = 8'd112;
                            fraction32 = {half[8:0], 14'b0};
                        end
                        10'b01????????: begin
                            exponent32 = 8'd111;
                            fraction32 = {half[7:0], 15'b0};
                        end
                        10'b001???????: begin
                            exponent32 = 8'd110;
                            fraction32 = {half[6:0], 16'b0};
                        end
                        10'b0001??????: begin
                            exponent32 = 8'd109;
                            fraction32 = {half[5:0], 17'b0};
                        end
                        10'b00001?????: begin
                            exponent32 = 8'd108;
                            fraction32 = {half[4:0], 18'b0};
                        end
                        10'b000001????: begin
                            exponent32 = 8'd107;
                            fraction32 = {half[3:0], 19'b0};
                        end
                        10'b0000001???: begin
                            exponent32 = 8'd106;
                            fraction32 = {half[2:0], 20'b0};
                        end
                        10'b00000001??: begin
                            exponent32 = 8'd105;
                            fraction32 = {half[1:0], 21'b0};
                        end
                        10'b000000001?: begin
                            exponent32 = 8'd104;
                            fraction32 = {half[0], 22'b0};
                        end
                        10'b0000000001: begin
                            exponent32 = 8'd103;
                            fraction32 = 23'b0;
                        end
                        default: begin
                            exponent32 = 8'd0;
                            fraction32 = 23'd0;
                        end
                    endcase

                    float_result = {half[15], exponent32, fraction32};
                end
            end else if (half[14:10] == 5'h1F) begin
                if (half[9:0] == 10'd0) begin
                    // Infinity clamps to the largest finite binary32 value.
                    float_result = {half[15], 8'hFE, 23'h7FFFFF};
                end else if (nan_to_zero) begin
                    float_result = 32'h00000000;
                end else begin
                    // Preserve sign and place the payload in the low bits.
                    float_result = {half[15], 8'hFF, 13'b0, half[9:0]};
                end
            end else begin
                // Rebias the exponent from 15 to 127: add 112.
                exponent32  = {3'b000, half[14:10]} + 8'd112;
                float_result = {half[15], exponent32, half[9:0], 13'b0};
            end
        end
    endfunction

    // Configuration is used only when the corresponding input word is accepted
    // and written into the FIFO, so it is naturally sampled with that word.
    always_comb begin
        converted_word = 128'b0;

        for (lane_index = 0; lane_index < 4; lane_index = lane_index + 1) begin
            if (cfg_precision == 2'd2) begin
                converted_word[lane_index*32 +: 32] =
                    float_result(in_data[lane_index*16 +: 16],
                                 cfg_nan_to_zero);
            end else begin
                converted_word[lane_index*32 +: 32] =
                    integer_result(
                        $signed(in_data[lane_index*16 +: 16]),
                        $signed(cfg_offset),
                        $signed(cfg_scale),
                        cfg_truncate,
                        cfg_bypass
                    );
            end
        end
    end

    assign out_data  = storage0;
    assign out_valid = (count != 2'd0);

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
            storage0 <= 128'b0;
            storage1 <= 128'b0;
            count    <= 2'd0;
            in_ready <= 1'b1;
        end else begin
            count    <= count_next;
            in_ready <= (count_next < 2'd2);

            case ({push, pop})
                2'b10: begin
                    if (count == 2'd0)
                        storage0 <= converted_word;
                    else if (count == 2'd1)
                        storage1 <= converted_word;
                end

                2'b01: begin
                    if (count == 2'd2)
                        storage0 <= storage1;
                end

                2'b11: begin
                    if (count == 2'd1) begin
                        // The old head is consumed and the new word becomes
                        // the head without interrupting one-word-per-cycle flow.
                        storage0 <= converted_word;
                    end else if (count == 2'd2) begin
                        storage0 <= storage1;
                        storage1 <= converted_word;
                    end
                end

                default: begin
                end
            endcase
        end
    end

endmodule
