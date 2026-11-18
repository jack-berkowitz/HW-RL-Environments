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

    // ------------------------------------------------------------------------
    // Integer lane: exact product, ties-away rounding, final saturation
    // ------------------------------------------------------------------------
    function automatic logic [31:0] int_lane(
        input logic [15:0]       x_bits,
        input logic signed [31:0] offset,
        input logic signed [15:0] scale,
        input logic [5:0]        trunc,
        input logic              bypass
    );
        logic signed [15:0] x;
        logic signed [32:0] diff;
        logic signed [48:0] prod;
        logic signed [63:0] prod64;
        logic [63:0]        mag;
        logic [63:0]        half;
        logic [63:0]        rounded_mag;
        logic signed [63:0] rounded;
        logic               sign;

        begin
            x = x_bits;

            if (bypass) begin
                int_lane = {{16{x_bits[15]}}, x_bits};
            end else begin
                // diff = x - offset, with enough width for the full range
                diff = $signed({{17{x_bits[15]}}, x_bits}) -
                       $signed({offset[31], offset});

                // exact product: 33-bit signed * 16-bit signed -> 49-bit signed
                prod = $signed(diff) * $signed(scale);

                if (trunc == 6'd0) begin
                    rounded = prod;
                end else begin
                    prod64 = {{15{prod[48]}}, prod};
                    sign   = prod64[63];

                    if (sign) begin
                        mag = (~prod64) + 64'd1;
                    end else begin
                        mag = prod64;
                    end

                    half        = 64'd1 << (trunc - 6'd1);
                    rounded_mag = (mag + half) >> trunc;

                    if (sign) begin
                        rounded = -$signed(rounded_mag);
                    end else begin
                        rounded = $signed(rounded_mag);
                    end
                end

                if (rounded > 64'sd2147483647) begin
                    int_lane = 32'h7FFFFFFF;
                end else if (rounded < -64'sd2147483648) begin
                    int_lane = 32'h80000000;
                end else begin
                    int_lane = rounded[31:0];
                end
            end
        end
    endfunction

    // ------------------------------------------------------------------------
    // Float lane: exact binary16 -> binary32 conversion
    // ------------------------------------------------------------------------
    function automatic logic [31:0] float_lane(
        input logic [15:0] x,
        input logic        nan_to_zero
    );
        logic        sign;
        logic [4:0]  exp16;
        logic [9:0]  mant16;
        logic [7:0]  exp32;
        logic [22:0] frac32;
        logic [4:0]  k;
        integer      i;
        logic [22:0] shifted;

        begin
            sign   = x[15];
            exp16  = x[14:10];
            mant16 = x[9:0];

            if (exp16 == 5'd0) begin
                if (mant16 == 10'd0) begin
                    // signed zero
                    float_lane = {sign, 31'b0};
                end else begin
                    // subnormal: normalise into binary32
                    k = 5'd0;
                    for (i = 0; i < 10; i = i + 1) begin
                        if (mant16[i]) begin
                            k = i;
                        end
                    end

                    exp32  = 8'd103 + {3'b0, k};
                    shifted = {13'b0, mant16} << (23 - k);
                    frac32 = shifted;

                    float_lane = {sign, exp32, frac32};
                end
            end else if (exp16 == 5'd31) begin
                if (mant16 == 10'd0) begin
                    // infinity clamps to FLT_MAX
                    float_lane = {sign, 8'hFE, 23'h7FFFFF};
                end else begin
                    // NaN
                    if (nan_to_zero) begin
                        float_lane = 32'h00000000;
                    end else begin
                        float_lane = {sign, 8'hFF, 13'b0, mant16};
                    end
                end
            end else begin
                // normal
                exp32  = {3'b0, exp16} + 8'd112;
                frac32 = {mant16, 13'b0};
                float_lane = {sign, exp32, frac32};
            end
        end
    endfunction

    // ------------------------------------------------------------------------
    // Internal state
    // ------------------------------------------------------------------------
    logic [1:0]   count;
    logic [0:0]   head;
    logic [127:0] mem [0:1];
    logic         in_ready_r;

    logic [127:0] result;
    logic [31:0]  lane0;
    logic [31:0]  lane1;
    logic [31:0]  lane2;
    logic [31:0]  lane3;

    logic         do_enq;
    logic         do_deq;
    logic [1:0]   count_next;
    logic [0:0]   enq_idx;

    // ------------------------------------------------------------------------
    // Outputs and handshake
    // ------------------------------------------------------------------------
    assign in_ready  = in_ready_r;
    assign out_valid = (count != 2'd0);
    assign out_data  = mem[head];

    assign do_enq    = in_valid && in_ready_r;
    assign do_deq    = (count != 2'd0) && out_ready;
    assign count_next = count + (do_enq ? 2'd1 : 2'd0) -
                               (do_deq ? 2'd1 : 2'd0);
    assign enq_idx   = head ^ count[0];

    // ------------------------------------------------------------------------
    // Datapath
    // ------------------------------------------------------------------------
    always_comb begin
        if (cfg_precision == 2'd2) begin
            lane0 = float_lane(in_data[15:0],  cfg_nan_to_zero);
            lane1 = float_lane(in_data[31:16], cfg_nan_to_zero);
            lane2 = float_lane(in_data[47:32], cfg_nan_to_zero);
            lane3 = float_lane(in_data[63:48], cfg_nan_to_zero);
        end else begin
            lane0 = int_lane(in_data[15:0],  $signed(cfg_offset), $signed(cfg_scale), cfg_truncate, cfg_bypass);
            lane1 = int_lane(in_data[31:16], $signed(cfg_offset), $signed(cfg_scale), cfg_truncate, cfg_bypass);
            lane2 = int_lane(in_data[47:32], $signed(cfg_offset), $signed(cfg_scale), cfg_truncate, cfg_bypass);
            lane3 = int_lane(in_data[63:48], $signed(cfg_offset), $signed(cfg_scale), cfg_truncate, cfg_bypass);
        end

        result = {lane3, lane2, lane1, lane0};
    end

    // ------------------------------------------------------------------------
    // Two-entry FIFO / skid buffer
    // ------------------------------------------------------------------------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count      <= 2'd0;
            head       <= 1'b0;
            in_ready_r <= 1'b1;
        end else begin
            if (do_enq) begin
                mem[enq_idx] <= result;
            end

            if (do_deq) begin
                head <= head + 1'b1;
            end

            count      <= count_next;
            in_ready_r <= (count_next < 2'd2);
        end
    end

endmodule
