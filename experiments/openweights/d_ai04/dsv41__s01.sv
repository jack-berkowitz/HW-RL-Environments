// =============================================================================
// d_ai04 -- sdp_requant
// =============================================================================
module sdp_requant (
    input  logic         clk,
    input  logic         rst_n,           // active-low async assert

    input  logic [63:0]  in_data,
    input  logic         in_valid,
    output logic         in_ready,

    input  logic [ 1:0]  cfg_precision,
    input  logic [31:0]  cfg_offset,      // SIGNED, SUBTRACTED
    input  logic [15:0]  cfg_scale,       // SIGNED
    input  logic [ 5:0]  cfg_truncate,
    input  logic         cfg_bypass,
    input  logic         cfg_nan_to_zero,

    output logic [127:0] out_data,
    output logic         out_valid,
    input  logic         out_ready
);

    // -------------------------------------------------------------------------
    // Arithmetic intermediates (module scope so always_comb blocks are pure)
    // -------------------------------------------------------------------------
    logic [127:0] computed_out;

    // Integer path intermediates (per lane)
    logic signed [63:0] idiff   [0:3];   // 33 bits used: x - offset
    logic signed [63:0] iprod   [0:3];   // 49 bits used: diff * scale
    logic signed [63:0] imag    [0:3];   // |iprod|
    logic        [63:0] ishift  [0:3];
    logic signed [63:0] iround  [0:3];
    logic signed [31:0] iout    [0:3];

    // Float path intermediates (per lane)
    logic [15:0] fh         [0:3];
    logic        fsign      [0:3];
    logic [4:0]  fhexp      [0:3];
    logic [9:0]  fhmant     [0:3];
    logic        fis_nan    [0:3];
    logic        fis_inf    [0:3];
    logic        fis_zero   [0:3];
    logic        fis_sub    [0:3];
    logic [7:0]  ffexp      [0:3];
    logic [22:0] ffmant     [0:3];
    logic [3:0]  fk         [0:3];
    logic [32:0] fshifted   [0:3];
    logic [31:0] fout       [0:3];

    // Shared helper: (truncate - 1), computed in 6-bit; safe because the
    // rounding branch only uses it when cfg_truncate != 0.
    logic [5:0] t_m1;
    assign t_m1 = cfg_truncate - 6'd1;

    // -------------------------------------------------------------------------
    // Per-lane datapath (purely combinational; registered by the skid buffer)
    // -------------------------------------------------------------------------
    genvar gi;
    generate
        for (gi = 0; gi < 4; gi = gi + 1) begin : gen_lane

            assign fh[gi] = in_data[16*gi +: 16];

            // ---------------- Integer mode (F3-F6) ----------------
            always_comb begin
                // 64-bit signed intermediate; only 33 bits of value used,
                // high bits are sign-extension.
                idiff[gi] = $signed({{48{fh[gi][15]}}, fh[gi]})
                          - $signed({{32{cfg_offset[31]}}, cfg_offset});

                // Exact product: 33-bit * 16-bit signed fits comfortably
                // in 49 bits of value (spec F5's -2^31 * 32767 case).
                iprod[gi] = idiff[gi] * $signed({{48{cfg_scale[15]}}, cfg_scale});

                if (cfg_truncate == 6'd0) begin
                    // F4: truncate=0 is a no-op, not a rounding step.
                    iround[gi] = iprod[gi];
                end else begin
                    // Magnitude-domain ties-AWAY rounding (F4).
                    imag[gi]   = iprod[gi][63] ? -iprod[gi] : iprod[gi];
                    ishift[gi] = imag[gi] >> cfg_truncate;
                    // Round up iff the low `t` bits >= 2^(t-1),
                    // i.e. iff bit (t-1) of the magnitude is set.
                    if (imag[gi][t_m1]) begin
                        ishift[gi] = ishift[gi] + 64'd1;
                    end
                    iround[gi] = iprod[gi][63]
                               ? -$signed(ishift[gi])
                               :  $signed(ishift[gi]);
                end

                // Saturate to signed 32 (F5: saturation happens last).
                if (iround[gi] > 64'sh000000007FFFFFFF) begin
                    iout[gi] = 32'sh7FFFFFFF;
                end else if (iround[gi] < -64'sh0000000080000000) begin
                    iout[gi] = 32'sh80000000;
                end else begin
                    iout[gi] = iround[gi][31:0];
                end

                // F6: bypass overrides the entire integer path.
                if (cfg_bypass) begin
                    iout[gi] = {{16{fh[gi][15]}}, fh[gi]};
                end
            end

            // ---------------- Float mode (F7-F9) ----------------
            always_comb begin
                fsign[gi]  = fh[gi][15];
                fhexp[gi]  = fh[gi][14:10];
                fhmant[gi] = fh[gi][9:0];

                fis_nan[gi]  = (fhexp[gi] == 5'h1F) && (fhmant[gi] != 10'd0);
                fis_inf[gi]  = (fhexp[gi] == 5'h1F) && (fhmant[gi] == 10'd0);
                fis_zero[gi] = (fhexp[gi] == 5'd0)  && (fhmant[gi] == 10'd0);
                fis_sub[gi]  = (fhexp[gi] == 5'd0)  && (fhmant[gi] != 10'd0);

                ffexp[gi]    = 8'd0;
                ffmant[gi]   = 23'd0;
                fk[gi]       = 4'd0;
                fshifted[gi] = 33'd0;
                fout[gi]     = 32'd0;

                if (fis_nan[gi]) begin
                    // F9: {sign, 8'hFF, 13'b0, mant[9:0]}, or 0 if n2z.
                    if (cfg_nan_to_zero) begin
                        fout[gi] = 32'h00000000;
                    end else begin
                        fout[gi] = {fsign[gi], 8'hFF, 13'b0, fhmant[gi]};
                    end
                end else if (fis_inf[gi]) begin
                    // F8: infinity clamps to FLT_MAX (with sign), not propagate.
                    fout[gi] = {fsign[gi], 8'hFF, 23'h7FFFFF};
                end else if (fis_zero[gi]) begin
                    // Signed zero preserved.
                    fout[gi] = {fsign[gi], 31'b0};
                end else if (fis_sub[gi]) begin
                    // F7: subnormal -> find leading one, normalise.
                    case (1'b1)
                        fhmant[gi][9]: fk[gi] = 4'd9;
                        fhmant[gi][8]: fk[gi] = 4'd8;
                        fhmant[gi][7]: fk[gi] = 4'd7;
                        fhmant[gi][6]: fk[gi] = 4'd6;
                        fhmant[gi][5]: fk[gi] = 4'd5;
                        fhmant[gi][4]: fk[gi] = 4'd4;
                        fhmant[gi][3]: fk[gi] = 4'd3;
                        fhmant[gi][2]: fk[gi] = 4'd2;
                        fhmant[gi][1]: fk[gi] = 4'd1;
                        default:       fk[gi] = 4'd0;
                    endcase
                    // binary16 subnormal value = mant * 2^-24.
                    // Leading 1 at bit k  =>  value = 1.f * 2^(k-24).
                    // biased fp32 exp = k - 24 + 127 = k + 103.
                    ffexp[gi]    = 8'(fk[gi]) + 8'd103;
                    fshifted[gi] = {23'b0, fhmant[gi]} << (6'd23 - {2'b0, fk[gi]});
                    ffmant[gi]   = fshifted[gi][22:0];
                    fout[gi]     = {fsign[gi], ffexp[gi], ffmant[gi]};
                end else begin
                    // Normal binary16: exponent -15 + 127 = exp + 112.
                    ffexp[gi]  = 8'(fhexp[gi]) + 8'd112;
                    ffmant[gi] = {fhmant[gi], 13'b0};
                    fout[gi]   = {fsign[gi], ffexp[gi], ffmant[gi]};
                end
            end

            // ---------------- Mode select (F2) ----------------
            // precision == 2 -> FLOAT, anything else -> INTEGER.
            assign computed_out[32*gi +: 32] =
                (cfg_precision == 2'd2) ? fout[gi] : iout[gi];
        end
    endgenerate

    // -------------------------------------------------------------------------
    // Skid buffer: two slots.  in_ready is a flop; the extra skid slot is
    // what keeps A2 (registered ready) and A3 (no loss on stall-on-accept)
    // compatible with A4 (II=1 on open flow).
    // -------------------------------------------------------------------------
    logic [127:0] o_data, s_data;
    logic         o_valid, s_valid;
    logic [127:0] n_o_data, n_s_data;
    logic         n_o_valid, n_s_valid;
    logic         n_in_ready;

    logic i_accept, o_transfer;
    assign i_accept   = in_valid && in_ready;
    assign o_transfer = o_valid  && out_ready;

    always_comb begin
        n_o_data  = o_data;
        n_o_valid = o_valid;
        n_s_data  = s_data;
        n_s_valid = s_valid;

        if (i_accept) begin
            // Word accepted: goes to output slot if it is free or will
            // vacate this cycle; otherwise to the skid slot.
            if (!o_valid || o_transfer) begin
                n_o_data  = computed_out;
                n_o_valid = 1'b1;
                n_s_valid = 1'b0;
            end else begin
                n_s_data  = computed_out;
                n_s_valid = 1'b1;
            end
        end else if (o_transfer) begin
            // Output slot vacated; refill from skid if present.
            if (s_valid) begin
                n_o_data  = s_data;
                n_o_valid = 1'b1;
                n_s_valid = 1'b0;
            end else begin
                n_o_valid = 1'b0;
            end
        end

        // A2: in_ready is a function of flop state only, never of out_ready
        // combinationally.  A3: !s_valid guarantees a slot exists.
        n_in_ready = !n_s_valid;
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            o_data   <= 128'd0;
            o_valid  <= 1'b0;
            s_data   <= 128'd0;
            s_valid  <= 1'b0;
            in_ready <= 1'b1;
        end else begin
            o_data   <= n_o_data;
            o_valid  <= n_o_valid;
            s_data   <= n_s_data;
            s_valid  <= n_s_valid;
            in_ready <= n_in_ready;
        end
    end

    assign out_data  = o_data;
    assign out_valid = o_valid;

endmodule
