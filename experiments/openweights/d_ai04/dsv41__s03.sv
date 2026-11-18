module sdp_requant (
    input  logic         clk,
    input  logic         rst_n,           // active-low, asynchronous assert

    // input stream -- one 64b word carrying four 16b lanes
    input  logic [63:0]  in_data,
    input  logic         in_valid,
    output logic         in_ready,

    // configuration. Sampled with the word it applies to.
    input  logic [ 1:0]  cfg_precision,
    input  logic [31:0]  cfg_offset,      // SIGNED, and SUBTRACTED
    input  logic [15:0]  cfg_scale,       // SIGNED
    input  logic [ 5:0]  cfg_truncate,    // 0..63
    input  logic         cfg_bypass,
    input  logic         cfg_nan_to_zero,

    // output stream -- one 128b word carrying four 32b lanes
    output logic [127:0] out_data,
    output logic         out_valid,
    input  logic         out_ready
);

    // -------------------------------------------------------------------------
    // Two-entry output buffer.  A single output register would lose a word at
    // the stall boundary; two entries satisfy A2/A3 while keeping in_ready
    // registered.
    // -------------------------------------------------------------------------
    logic [127:0] data0;
    logic [127:0] data1;
    logic [1:0]   count;
    logic         in_ready_r;
    logic [127:0] new_word;

    logic         accept;
    logic         consume;
    logic [1:0]   next_count;

    assign in_ready = in_ready_r;
    assign out_valid = (count != 2'd0);
    assign out_data  = data0;

    // -------------------------------------------------------------------------
    // Integer requantise lane
    //   out = sat32( round_ties_away( (x - offset) * scale / 2^trunc ) )
    // -------------------------------------------------------------------------
    function automatic logic [31:0] int_requant (
        input logic signed [15:0] x,
        input logic signed [31:0] offset,
        input logic signed [15:0] scale,
        input logic        [5:0]  trunc
    );
        logic signed [32:0] diff;
        logic signed [47:0] diff_ext;
        logic signed [47:0] scale_ext;
        logic signed [47:0] prod;
        logic signed [63:0] prod64;
        logic signed [63:0] abs_prod;
        logic signed [63:0] half;
        logic signed [63:0] abs_round;
        logic signed [63:0] q64;
        logic               neg;
        begin
            // x - offset must not wrap in 32 bits.
            diff = $signed({{17{x[15]}}, x}) -
                   $signed({{1{offset[31]}}, offset});

            // Exact product: 33-bit signed * 16-bit signed fits in 48 bits.
            diff_ext  = {{15{diff[32]}}, diff};
            scale_ext = {{32{scale[15]}}, scale};
            prod      = diff_ext * scale_ext;
            prod64    = {{16{prod[47]}}, prod};

            if (trunc == 6'd0) begin
                q64 = prod64;
            end else begin
                // Round magnitude to nearest, ties away from zero.
                neg      = prod64[63];
                abs_prod = neg ? -prod64 : prod64;
                half     = 64'sd1 << (trunc - 6'd1);
                abs_round = (abs_prod + half) >> trunc;
                q64      = neg ? -abs_round : abs_round;
            end

            // Saturation happens last.
            if (q64 > 64'sd2147483647) begin
                int_requant = 32'h7FFFFFFF;
            end else if (q64 < -64'sd2147483648) begin
                int_requant = 32'h80000000;
            end else begin
                int_requant = q64[31:0];
            end
        end
    endfunction

    // -------------------------------------------------------------------------
    // binary16 -> binary32 conversion, with the measured special cases:
    //   infinity clamps to FLT_MAX
    //   NaN payload lands in low mantissa bits
    //   subnormals are normalised into normal binary32 values
    // -------------------------------------------------------------------------
    function automatic logic [31:0] fp16_to_fp32 (
        input logic [15:0] h,
        input logic        nan_to_zero
    );
        logic        s;
        logic [4:0]  exp16;
        logic [9:0]  frac16;
        logic [7:0]  exp32;
        logic [22:0] mant32;
        logic [31:0] res;
        logic [4:0]  k;
        logic [31:0] shifted;
        integer      i;
        begin
            s     = h[15];
            exp16 = h[14:10];
            frac16 = h[9:0];

            if (exp16 == 5'd0) begin
                if (frac16 == 10'd0) begin
                    // signed zero
                    res = {s, 31'd0};
                end else begin
                    // subnormal: normalise frac16 * 2^-24
                    k = 5'd0;
                    for (i = 0; i < 10; i = i + 1) begin
                        if (frac16[i]) begin
                            k = i[4:0];
                        end
                    end

                    exp32  = 8'd103 + {3'b000, k};
                    shifted = {22'd0, frac16} << (23 - k);
                    mant32 = shifted[22:0];
                    res    = {s, exp32, mant32};
                end
            end else if (exp16 == 5'd31) begin
                if (frac16 == 10'd0) begin
                    // infinity clamps to FLT_MAX
                    res = s ? 32'hFF7FFFFF : 32'h7F7FFFFF;
                end else begin
                    // NaN
                    if (nan_to_zero) begin
                        res = 32'h00000000;
                    end else begin
                        res = {s, 8'hFF, 13'b0, frac16};
                    end
                end
            end else begin
                // normal
                exp32  = 8'd112 + {3'b000, exp16};
                mant32 = {frac16, 13'b0};
                res    = {s, exp32, mant32};
            end

            fp16_to_fp32 = res;
        end
    endfunction

    // -------------------------------------------------------------------------
    // One lane dispatch
    // -------------------------------------------------------------------------
    function automatic logic [31:0] process_lane (
        input logic        [15:0] raw,
        input logic        [1:0]  precision,
        input logic signed [31:0] offset,
        input logic signed [15:0] scale,
        input logic        [5:0]  trunc,
        input logic               bypass,
        input logic               nan_zero
    );
        logic signed [15:0] x;
        logic        [31:0] res;
        begin
            x = raw;

            if (precision == 2'd2) begin
                // Float mode: offset, scale, truncate and bypass are inert.
                res = fp16_to_fp32(raw, nan_zero);
            end else if (bypass) begin
                // Integer bypass: sign-extend the input lane.
                res = {{16{raw[15]}}, raw};
            end else begin
                res = int_requant(x, offset, scale, trunc);
            end

            process_lane = res;
        end
    endfunction

    // -------------------------------------------------------------------------
    // Combinational lane computation.  cfg_* are sampled at acceptance time
    // because new_word is stored into the buffer on accept.
    // -------------------------------------------------------------------------
    always_comb begin
        new_word = {
            process_lane(in_data[63:48], cfg_precision, $signed(cfg_offset), $signed(cfg_scale), cfg_truncate, cfg_bypass, cfg_nan_to_zero),
            process_lane(in_data[47:32], cfg_precision, $signed(cfg_offset), $signed(cfg_scale), cfg_truncate, cfg_bypass, cfg_nan_to_zero),
            process_lane(in_data[31:16], cfg_precision, $signed(cfg_offset), $signed(cfg_scale), cfg_truncate, cfg_bypass, cfg_nan_to_zero),
            process_lane(in_data[15:0],  cfg_precision, $signed(cfg_offset), $signed(cfg_scale), cfg_truncate, cfg_bypass, cfg_nan_to_zero)
        };
    end

    // -------------------------------------------------------------------------
    // Flow-control next state
    // -------------------------------------------------------------------------
    always_comb begin
        accept = in_valid && in_ready_r;
        consume = (count != 2'd0) && out_ready;
        next_count = count + (accept ? 2'd1 : 2'd0) - (consume ? 2'd1 : 2'd0);
    end

    // -------------------------------------------------------------------------
    // Buffer update.  in_ready_r is registered; there is no combinational path
    // from out_ready to in_ready.
    // -------------------------------------------------------------------------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data0      <= 128'd0;
            data1      <= 128'd0;
            count      <= 2'd0;
            in_ready_r <= 1'b1;
        end else begin
            if (consume) begin
                if (count == 2'd2) begin
                    data0 <= data1;
                    if (accept) begin
                        data1 <= new_word;
                    end
                end else begin // count == 1
                    if (accept) begin
                        data0 <= new_word;
                    end
                end
            end else begin
                if (count == 2'd0) begin
                    if (accept) begin
                        data0 <= new_word;
                    end
                end else if (count == 2'd1) begin
                    if (accept) begin
                        data1 <= new_word;
                    end
                end
                // count == 2: in_ready_r is low, so accept is false
            end

            count      <= next_count;
            in_ready_r <= (next_count < 2'd2);
        end
    end

endmodule
