// =============================================================================
// fp16_gemm_array.sv 
// =============================================================================

module fma_stage (
    input  logic        clk_i,
    input  logic        rst_ni,
    input  logic        enable_i,
    input  logic        flush_i,
    input  logic [15:0] x_i,
    input  logic [15:0] w_i,
    input  logic [15:0] p_in,
    input  logic [2:0]  rnd_i,
    
    output logic [15:0] p_out,
    output logic [15:0] res_out,
    output logic [4:0]  status_o
);

    // -------------------------------------------------------------------------
    // 1. INPUT PIPELINE REGISTER (Tick 0)
    // -------------------------------------------------------------------------
    logic [15:0] reg_x, reg_w, reg_p;
    logic [2:0]  reg_rnd;

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            reg_x <= 16'd0;
            reg_w <= 16'd0;
            reg_p <= 16'd0;
            reg_rnd <= 3'd0;
        end else if (enable_i) begin
            if (flush_i) begin
                reg_x <= 16'd0;
                reg_w <= 16'd0;
                reg_p <= 16'd0;
                reg_rnd <= 3'd0;
            end else begin
                reg_x <= x_i;
                reg_w <= w_i;
                reg_p <= p_in;
                reg_rnd <= rnd_i;
            end
        end
    end

    // -------------------------------------------------------------------------
    // 2. COMBINATIONAL EXACT FMA
    // -------------------------------------------------------------------------
    logic sign_x, sign_w, sign_y;
    logic [4:0] exp_x, exp_w, exp_y;
    logic [9:0] frac_x, frac_w, frac_y;

    assign {sign_x, exp_x, frac_x} = reg_x;
    assign {sign_w, exp_w, frac_w} = reg_w;
    assign {sign_y, exp_y, frac_y} = reg_p;

    // Decoding Exponents and Mantissas
    logic is_zero_x = (exp_x == 0 && frac_x == 0);
    logic is_zero_w = (exp_w == 0 && frac_w == 0);
    logic is_zero_y = (exp_y == 0 && frac_y == 0);
    logic is_zero_p = is_zero_x | is_zero_w;

    logic is_inf_x = (exp_x == 31 && frac_x == 0);
    logic is_inf_w = (exp_w == 31 && frac_w == 0);
    logic is_inf_y = (exp_y == 31 && frac_y == 0);

    logic is_nan_x = (exp_x == 31 && frac_x != 0);
    logic is_nan_w = (exp_w == 31 && frac_w != 0);
    logic is_nan_y = (exp_y == 31 && frac_y != 0);

    logic is_nan_any = is_nan_x | is_nan_w | is_nan_y;
    logic is_inf_mul_zero = (is_inf_x & is_zero_w) | (is_zero_x & is_inf_w);
    
    logic is_inf_p = is_inf_x | is_inf_w;
    logic sign_p = sign_x ^ sign_w;
    logic is_inf_add_inf = is_inf_p & is_inf_y & (sign_p != sign_y);

    logic invalid = is_inf_mul_zero | is_inf_add_inf;
    logic is_nan_out = is_nan_any | invalid;

    // Calculate True Exponents and fractions
    logic signed [6:0] E_x = (exp_x == 0) ? -7'sd14 : signed'({2'b0, exp_x}) - 7'sd15;
    logic signed [6:0] E_w = (exp_w == 0) ? -7'sd14 : signed'({2'b0, exp_w}) - 7'sd15;
    logic signed [6:0] E_y = (exp_y == 0) ? -7'sd14 : signed'({2'b0, exp_y}) - 7'sd15;

    logic [10:0] m_x = {(exp_x != 0), frac_x};
    logic [10:0] m_w = {(exp_w != 0), frac_w};
    logic [10:0] m_y = {(exp_y != 0), frac_y};

    logic [21:0] M_p = m_x * m_w;
    logic signed [7:0] E_p = E_x + E_w;

    // Shift to align radix point such that bit 48 represents 2^0
    logic [5:0] sh_p = 6'(E_p + 8'sd28);
    logic [5:0] sh_y = 6'(E_y + 8'sd38);

    logic [104:0] V_p = is_zero_p ? 105'd0 : (105'(M_p) << sh_p);
    logic [104:0] V_y = is_zero_y ? 105'd0 : (105'(m_y) << sh_y);

    logic signed [105:0] S_p = sign_p ? -signed'({1'b0, V_p}) : signed'({1'b0, V_p});
    logic signed [105:0] S_y = sign_y ? -signed'({1'b0, V_y}) : signed'({1'b0, V_y});

    logic signed [105:0] S_sum = S_p + S_y;

    // -------------------------------------------------------------------------
    // 3. NORMALIZATION & ROUNDING
    // -------------------------------------------------------------------------
    logic sign_res;
    logic [104:0] U;
    
    always_comb begin
        if (S_sum == 0) begin
            if (is_zero_p && is_zero_y) sign_res = (sign_p == sign_y) ? sign_p : (reg_rnd == 3'd2);
            else sign_res = (reg_rnd == 3'd2);
            U = 105'd0;
        end else begin
            sign_res = S_sum[105];
            U = sign_res ? -S_sum : S_sum;
        end
    end

    // Binary search Priority Encoder for MSB (Synthesizable and Unrolled)
    logic [127:0] U_ext;
    logic [127:0] scan_U;
    logic [6:0]   msb;

    assign U_ext = {23'd0, U};
    
    always_comb begin
        scan_U = U_ext;
        msb = 7'd0;
        if (|scan_U[127:64]) begin msb[6] = 1'b1; scan_U = {64'd0,  scan_U[127:64]}; end
        if (|scan_U[63:32])  begin msb[5] = 1'b1; scan_U = {96'd0,  scan_U[63:32]};  end
        if (|scan_U[31:16])  begin msb[4] = 1'b1; scan_U = {112'd0, scan_U[31:16]};  end
        if (|scan_U[15:8])   begin msb[3] = 1'b1; scan_U = {120'd0, scan_U[15:8]};   end
        if (|scan_U[7:4])    begin msb[2] = 1'b1; scan_U = {124'd0, scan_U[7:4]};    end
        if (|scan_U[3:2])    begin msb[1] = 1'b1; scan_U = {126'd0, scan_U[3:2]};    end
        if (scan_U[1])       begin msb[0] = 1'b1; end
    end

    logic [6:0] target_msb;
    logic [6:0] shift;
    assign target_msb = (msb > 7'd34) ? msb : 7'd34;
    assign shift      = target_msb - 7'd10;

    logic [127:0] shifted_U;
    logic [9:0]   frac_unrounded;
    logic         round_bit;
    logic [127:0] sticky_mask;
    logic         sticky_bit;

    assign shifted_U      = U_ext >> shift;
    assign frac_unrounded = shifted_U[9:0];
    assign round_bit      = (shift > 0) ? U_ext[shift - 1] : 1'b0;
    assign sticky_mask    = ~( (~128'd0) << (shift > 0 ? (shift - 1) : 0) );
    assign sticky_bit     = (U_ext & sticky_mask) != 0;

    logic is_inexact = round_bit | sticky_bit;
    logic round_up;
    always_comb begin
        case (reg_rnd)
            3'd0: round_up = round_bit & (sticky_bit | frac_unrounded[0]); // RNE
            3'd1: round_up = 1'b0;                                         // RTZ
            3'd2: round_up =  sign_res ? is_inexact : 1'b0;                // RDN
            3'd3: round_up = ~sign_res ? is_inexact : 1'b0;                // RUP
            3'd4: round_up = round_bit;                                    // RMM
            default: round_up = 1'b0;
        endcase
    end

    logic [10:0] frac_rounded_ext;
    logic        carry;
    logic [9:0]  frac_rounded;
    logic [6:0]  E_unrounded;
    logic [6:0]  E_rounded;

    assign frac_rounded_ext = {1'b0, frac_unrounded} + {10'd0, round_up};
    assign carry            = frac_rounded_ext[10];
    assign frac_rounded     = frac_rounded_ext[9:0];
    
    assign E_unrounded = (msb >= 7'd34) ? (msb - 7'd34 + 7'd1) : 7'd0;
    assign E_rounded   = E_unrounded + {6'd0, carry};

    logic is_overflow = (E_rounded >= 7'd31);
    logic is_tiny     = (E_rounded == 7'd0);

    logic [15:0] res_next;
    logic [4:0]  flags_next;

    always_comb begin
        if (is_nan_out) begin
            res_next   = 16'h7E00;
            flags_next = {invalid, 4'd0}; // NV=invalid, DZ,OF,UF,NX=0
        end else if (is_inf_p | is_inf_y) begin
            res_next   = {(is_inf_p ? sign_p : sign_y), 5'h1F, 10'd0};
            flags_next = 5'd0;
        end else if (S_sum == 0) begin
            res_next   = {sign_res, 15'd0};
            flags_next = 5'd0;
        end else if (is_overflow) begin
            logic return_inf;
            case (reg_rnd)
                3'd0, 3'd4: return_inf = 1'b1;
                3'd1:       return_inf = 1'b0;
                3'd2:       return_inf = sign_res ? 1'b1 : 1'b0;
                3'd3:       return_inf = ~sign_res ? 1'b1 : 1'b0;
                default:    return_inf = 1'b0;
            endcase
            res_next   = return_inf ? {sign_res, 5'h1F, 10'd0} : {sign_res, 5'h1E, 10'h3FF};
            flags_next = 5'b00101; // OF=1, NX=1
        end else begin
            res_next   = {sign_res, E_rounded[4:0], frac_rounded};
            flags_next = {3'b000, is_tiny & is_inexact, is_inexact}; // UF and NX
        end
    end

    // -------------------------------------------------------------------------
    // 4. PIPELINE REGISTERS (Ticks 1-4)
    // -------------------------------------------------------------------------
    logic [15:0] reg_res1, reg_res2, reg_res3;
    logic [4:0]  reg_flags1, reg_flags2;

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            reg_res1 <= 16'd0; reg_res2 <= 16'd0; reg_res3 <= 16'd0;
            reg_flags1 <= 5'd0; reg_flags2 <= 5'd0;
        end else if (enable_i) begin
            if (flush_i) begin
                reg_res1 <= 16'd0; reg_res2 <= 16'd0; reg_res3 <= 16'd0;
                reg_flags1 <= 5'd0; reg_flags2 <= 5'd0;
            end else begin
                reg_res1 <= res_next;
                reg_res2 <= reg_res1;
                reg_res3 <= reg_res2;

                reg_flags1 <= flags_next;
                reg_flags2 <= reg_flags1;
            end
        end
    end

    assign status_o = reg_flags2; // Available exactly 2 edges after operand read (d(k)+2)
    assign res_out  = reg_res2;   // Evaluated dot output for z_o
    assign p_out    = reg_res3;   // Shifted for next FMA stage (creating D=4 interval)

endmodule


// =============================================================================
// Top Level Matrix 
// =============================================================================

module fp16_gemm_array #(
    parameter int WIDTH = 8,
    parameter int HEIGHT = 8
) (
    input  logic                                      clk_i,
    input  logic                                      rst_ni,
    input  logic [WIDTH-1:0][HEIGHT-1:0][15:0]        x_i,
    input  logic [HEIGHT-1:0][15:0]                   w_i,
    input  logic [WIDTH-1:0][15:0]                    y_i,
    
    output logic [WIDTH-1:0][15:0]                    z_o,
    
    input  logic [2:0]                                rnd_i,
    input  logic                                      accumulate_i,
    input  logic [WIDTH-1:0]                          row_clk_gate_en_i,
    input  logic                                      reg_enable_i,
    input  logic                                      flush_i,
    
    output logic [WIDTH-1:0][HEIGHT-1:0][4:0]         status_o
);

    genvar r, k;
    generate
        for (r = 0; r < WIDTH; r++) begin : row_gen
            logic [15:0] p_chain [HEIGHT+1];
            logic [15:0] stage_res_out [HEIGHT];

            // Multiplexer handles accumulation feedback directly per Clause C3
            // Since it connects synchronously, feedback is inherently resolved 1 tick earlier
            assign p_chain[0] = accumulate_i ? stage_res_out[HEIGHT-1] : y_i[r];
            assign z_o[r]     = stage_res_out[HEIGHT-1];
            
            // FMA Stages
            for (k = 0; k < HEIGHT; k++) begin : stg
                fma_stage fma_inst (
                    .clk_i(clk_i),
                    .rst_ni(rst_ni),
                    .enable_i(row_clk_gate_en_i[r] & (reg_enable_i | flush_i)),
                    .flush_i(flush_i),
                    .x_i(x_i[r][k]),
                    .w_i(w_i[k]),
                    .p_in(p_chain[k]),
                    .rnd_i(rnd_i),
                    .p_out(p_chain[k+1]),
                    .res_out(stage_res_out[k]),
                    .status_o(status_o[r][k])
                );
            end
        end
    endgenerate

endmodule