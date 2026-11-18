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

    // x-offset needs 33 signed bits.  A 33-by-16-bit signed product is
    // represented exactly in 49 bits.
    function automatic logic [31:0] integer_lane (
        input logic [15:0] x,
        input logic [31:0] offset,
        input logic [15:0] scale,
        input logic [ 5:0] truncate,
        input logic        bypass
    );
        logic signed [32:0] diff;
        logic signed [48:0] product;
        logic        [48:0] magnitude;
        logic        [48:0] shifted;
        logic        [48:0] rounded;
        logic               round_up;
        logic        [31:0] lane_result;

        begin
            if (bypass) begin
                lane_result = {{16{x[15]}}, x};
            end else begin
                diff = $signed({{17{x[15]}}, x})
                     - $signed({offset[31], offset});

                // Explicit extension makes the multiplication expression
                // 49 bits wide, independently of expression-sizing rules.
                product = $signed({{16{diff[32]}}, diff})
                        * $signed(scale);

                // Round the magnitude, then restore the sign.  For a right
                // shift by t, bit t-1 of the magnitude is precisely the
                // "fraction >= 1/2" bit, including exact ties.
                magnitude = product[48]
                          ? (~product + 49'd1)
                          : product;

                shifted  = magnitude;
                round_up = 1'b0;

                if (truncate != 6'd0) begin
                    shifted = magnitude >> truncate;
                    if (truncate <= 6'd49)
                        round_up = magnitude[truncate - 6'd1];
                end

                rounded = shifted + (round_up ? 49'd1 : 49'd0);

                if (product[48]) begin
                    if (rounded > 49'd2147483648)
                        lane_result = 32'h80000000;
                    else
                        lane_result = 32'd0 - rounded[31:0];
                end else begin
                    if (rounded > 49'd2147483647)
                        lane_result = 32'h7FFFFFFF;
                    else
                        lane_result = rounded[31:0];
                end
            end

            integer_lane = lane_result;
        end
    endfunction


    function automatic logic [31:0] float_lane (
        input logic [15:0] half,
        input logic        nan_to_zero
    );
        logic       sign;
        logic [4:0] exponent;
        logic [9:0] fraction;
        logic [3:0] msb;
        logic [9:0] normalised;
        logic [7:0] exp32;
        integer     i;

        begin
            sign       = half[15];
            exponent   = half[14:10];
            fraction   = half[9:0];
            msb        = 4'd0;
            normalised = 10'd0;
            exp32      = 8'd0;

            if (exponent == 5'd0) begin
                if (fraction == 10'd0) begin
                    float_lane = {sign, 31'd0};
                end else begin
                    // A half subnormal with highest set bit p has value
                    // 2^(p-24) times a normalised significand.  Its binary32
                    // exponent field is therefore p + 103.
                    for (i = 0; i < 10; i = i + 1) begin
                        if (fraction[i])
                            msb = i[3:0];
                    end

                    normalised = fraction << (4'd9 - msb);
                    exp32      = 8'd103 + {4'd0, msb};
                    float_lane = {sign, exp32,
                                  normalised[8:0], 14'd0};
                end
            end else if (exponent == 5'd31) begin
                if (fraction == 10'd0) begin
                    // Infinity is clamped to the largest finite value.
                    float_lane = {sign, 8'hFE, 23'h7FFFFF};
                end else if (nan_to_zero) begin
                    float_lane = 32'h00000000;
                end else begin
                    float_lane = {sign, 8'hFF, 13'd0, fraction};
                end
            end else begin
                // Rebias from binary16's 15 to binary32's 127.
                exp32      = {3'd0, exponent} + 8'd112;
                float_lane = {sign, exp32, fraction, 13'd0};
            end
        end
    endfunction


    logic [127:0] converted_data;

    genvar lane;
    generate
        for (lane = 0; lane < 4; lane = lane + 1) begin : g_lanes
            assign converted_data[lane*32 +: 32] =
                (cfg_precision == 2'd2)
                    ? float_lane(in_data[lane*16 +: 16],
                                 cfg_nan_to_zero)
                    : integer_lane(in_data[lane*16 +: 16],
                                   cfg_offset,
                                   cfg_scale,
                                   cfg_truncate,
                                   cfg_bypass);
        end
    endgenerate


    // Two-entry FIFO.  The second entry accepts a word when the output entry
    // is occupied and the consumer stalls.  in_ready depends combinationally
    // only on registered state at its output; out_ready affects only its next
    // registered value.
    logic [127:0] storage [0:1];
    logic         read_ptr;
    logic         write_ptr;
    logic [1:0]   count;
    logic [1:0]   count_next;
    logic         push;
    logic         pop;

    assign out_valid = (count != 2'd0);
    assign out_data  = storage[read_ptr];

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
            read_ptr  <= 1'b0;
            write_ptr <= 1'b0;
            count     <= 2'd0;
            in_ready  <= 1'b1;
        end else begin
            count    <= count_next;
            in_ready <= (count_next != 2'd2);

            if (push) begin
                storage[write_ptr] <= converted_data;
                write_ptr          <= write_ptr + 1'b1;
            end

            if (pop)
                read_ptr <= read_ptr + 1'b1;
        end
    end

endmodule
