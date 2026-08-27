// =============================================================================
// fp16_gemm_array.sv
// 
// Complete and synthesizable implementation of the FP16 MAC array. 
// Features an exact 105-bit fixed-point FMA engine that eliminates the need for
// alignment shifting prior to multiplication. The design adheres strictly to the
// pipeline scheduling (operand skews, D=4 stage spacing, status_o timing) and 
// IEEE 754-2019 binary16 formatting required by the contract.
// =============================================================================

module fma_stage(
    input  logic        clk,
    input  logic        en_pipe,
    input  logic        en_clear,
    input  logic        rst_ni,
    input  logic        flush_i,
    input  logic [15:0] x,
    input  logic [15:0] w,
    input  logic [15:0] p_in,
    input  logic [2:0]  rnd_i,
    output logic [15:0] p_out,
    output logic [4:0]  status_out
);
    // -------------------------------------------------------------------------
    // Cycle 0: Unpack, Multiply, Shift, and Exact Accumulation
    // -------------------------------------------------------------------------
    logic sign_x; logic [4:0] exp_x; logic [9:0] frac_x;
    assign sign_x = x[15];
    assign exp_x  = x[14:10];
    assign frac_x = x[9:0];
    
    logic sign_w; logic [4:0] exp_w; logic [9:0] frac_w;
    assign sign_w = w[15];
    assign exp_w  = w[14:10];
    assign frac_w = w[9:0];
    
    logic sign_p; logic [4:0] exp_p; logic [9:0] frac_p;
    assign sign_p = p_in[15];
    assign exp_p  = p_in[14:10];
    assign frac_p = p_in[9:0];
    
    logic is_zero_x; logic is_inf_x; logic is_nan_x; logic is_snan_x;
    assign is_zero_x = (exp_x == 0) && (frac_x == 0);
    assign is_inf_x  = (exp_x == 31) && (frac_x == 0);
    assign is_nan_x  = (exp_x == 31) && (frac_x != 0);
    assign is_snan_x = is_nan_x && (frac_x[9] == 0);
    
    logic is_zero_w; logic is_inf_w; logic is_nan_w; logic is_snan_w;
    assign is_zero_w = (exp_w == 0) && (frac_w == 0);
    assign is_inf_w  = (exp_w == 31) && (frac_w == 0);
    assign is_nan_w  = (exp_w == 31) && (frac_w != 0);
    assign is_snan_w = is_nan_w && (frac_w[9] == 0);
    
    logic is_zero_p; logic is_inf_p; logic is_nan_p; logic is_snan_p;
    assign is_zero_p = (exp_p == 0) && (frac_p == 0);
    assign is_inf_p  = (exp_p == 31) && (frac_p == 0);
    assign is_nan_p  = (exp_p == 31) && (frac_p != 0);
    assign is_snan_p = is_nan_p && (frac_p[9] == 0);
    
    logic sign_prod;
    assign sign_prod = sign_x ^ sign_w;
    
    logic NV;
    assign NV = is_snan_x | is_snan_w | is_snan_p | 
                (is_inf_x & is_zero_w) | (is_zero_x & is_inf_w) |
                ((is_inf_x | is_inf_w) & is_inf_p & (sign_prod != sign_p));
                
    logic is_nan_any;
    assign is_nan_any = is_nan_x | is_nan_w | is_nan_p;
    
    logic invalid_mul;
    assign invalid_mul = (is_inf_x & is_zero_w) | (is_zero_x & is_inf_w);
    
    logic is_inf_prod;
    assign is_inf_prod = is_inf_x | is_inf_w;
    
    logic invalid_add;
    assign invalid_add = is_inf_prod & is_inf_p & (sign_prod != sign_p);
    
    logic [10:0] sig_x;
    assign sig_x = (exp_x == 0) ? {1'b0, frac_x} : {1'b1, frac_x};
    
    logic [10:0] sig_w;
    assign sig_w = (exp_w == 0) ? {1'b0, frac_w} : {1'b1, frac_w};
    
    logic [21:0] sig_prod;
    assign sig_prod = sig_x * sig_w;
    
    logic signed [6:0] weight_x;
    assign weight_x = is_zero_x ? 7'd0 : ((exp_x == 0) ? -7'sd14 : {2'b0, exp_x} - 7'sd15);
    
    logic signed [6:0] weight_w;
    assign weight_w = is_zero_w ? 7'd0 : ((exp_w == 0) ? -7'sd14 : {2'b0, exp_w} - 7'sd15);
    
    logic signed [7:0] weight_prod;
    assign weight_prod = weight_x + weight_w;
    
    logic [10:0] sig_p;
    assign sig_p = (exp_p == 0) ? {1'b0, frac_p} : {1'b1, frac_p};
    
    logic signed [6:0] weight_p;
    assign weight_p = is_zero_p ? 7'd0 : ((exp_p == 0) ? -7'sd14 : {2'b0, exp_p} - 7'sd15);
    
    logic [7:0] shift_prod;
    assign shift_prod = $signed(weight_prod) + 8'sd50;
    
    logic [7:0] shift_p;
    assign shift_p = $signed(weight_p) + 8'sd60;
    
    logic [104:0] val_prod;
    assign val_prod = (is_zero_x | is_zero_w) ? 105'b0 : ({83'b0, sig_prod} << shift_prod);
    
    logic [104:0] val_p;
    assign val_p = is_zero_p ? 105'b0 : ({94'b0, sig_p} << shift_p);
    
    logic [105:0] val_prod_tc;
    assign val_prod_tc = sign_prod ? -{1'b0, val_prod} : {1'b0, val_prod};
    
    logic [105:0] val_p_tc;
    assign val_p_tc = sign_p ? -{1'b0, val_p} : {1'b0, val_p};
    
    logic [105:0] sum_106;
    assign sum_106 = val_prod_tc + val_p_tc;
    
    logic sign_sum;
    assign sign_sum = sum_106[105];
    
    logic [104:0] mag_sum;
    assign mag_sum = sign_sum ? -sum_106 : sum_106;
    
    // -------------------------------------------------------------------------
    // First Pipeline Register
    // -------------------------------------------------------------------------
    logic NV_reg;
    logic is_nan_res_reg;
    logic is_inf_res_reg;
    logic sign_inf_reg;
    logic [104:0] mag_sum_reg;
    logic sign_sum_reg;
    logic sign_prod_reg;
    logic sign_p_reg;
    logic [2:0] rnd_reg;
    
    always_ff @(posedge clk or negedge rst_ni) begin
        if (!rst_ni) begin
            NV_reg <= 1'b0;
            is_nan_res_reg <= 1'b0;
            is_inf_res_reg <= 1'b0;
            sign_inf_reg <= 1'b0;
            mag_sum_reg <= 105'b0;
            sign_sum_reg <= 1'b0;
            sign_prod_reg <= 1'b0;
            sign_p_reg <= 1'b0;
            rnd_reg <= 3'b0;
        end else if (en_pipe) begin
            NV_reg <= NV;
            is_nan_res_reg <= is_nan_any | invalid_mul | invalid_add;
            is_inf_res_reg <= is_inf_prod | is_inf_p;
            sign_inf_reg <= is_inf_prod ? sign_prod : sign_p;
            mag_sum_reg <= mag_sum;
            sign_sum_reg <= sign_sum;
            sign_prod_reg <= sign_prod;
            sign_p_reg <= sign_p;
            rnd_reg <= rnd_i;
        end
    end
    
    // -------------------------------------------------------------------------
    // Cycle 1: LZD, Formatting, Rounding, and Exceptions
    // -------------------------------------------------------------------------
    logic [104:0] v;
    logic [6:0] lz;
    always_comb begin
        v = mag_sum_reg;
        lz = 0;
        // Unrolled static-bound logical tree safely synthesisable
        if (v[104:41] == 0) begin lz = lz + 64; v = v << 64; end
        if (v[104:73] == 0) begin lz = lz + 32; v = v << 32; end
        if (v[104:89] == 0) begin lz = lz + 16; v = v << 16; end
        if (v[104:97] == 0) begin lz = lz + 8;  v = v << 8;  end
        if (v[104:101]== 0) begin lz = lz + 4;  v = v << 4;  end
        if (v[104:103]== 0) begin lz = lz + 2;  v = v << 2;  end
        if (v[104]    == 0) begin lz = lz + 1;  v = v << 1;  end
        if (v[104]    == 0) begin lz = lz + 1; end
    end
    
    logic [7:0] pos;
    assign pos = 104 - lz;
    
    logic [7:0] eff_pos;
    assign eff_pos = (pos < 56) ? 8'd56 : pos; // Cap extraction scale at the subnormal edge
    
    logic signed [8:0] E_eff;
    assign E_eff = eff_pos - 70;
    
    logic [7:0] shift_amount;
    assign shift_amount = eff_pos - 11;
    
    logic [104:0] shifted_mag;
    assign shifted_mag = mag_sum_reg >> shift_amount;
    
    logic [11:0] extracted;
    assign extracted = shifted_mag[11:0];
    
    logic [104:0] mask;
    assign mask = (105'b1 << shift_amount) - 1'b1;
    
    logic sticky;
    assign sticky = |(mag_sum_reg & mask);
    
    logic G; logic [9:0] fraction; logic hidden; logic S;
    assign G = extracted[0];
    assign fraction = extracted[10:1];
    assign hidden = extracted[11];
    assign S = sticky;
    
    logic round_up;
    always_comb begin
        round_up = 0;
        case (rnd_reg)
            3'd0: round_up = G & (S | fraction[0]);
            3'd1: round_up = 1'b0;
            3'd2: round_up = sign_sum_reg & (G | S);
            3'd3: round_up = (!sign_sum_reg) & (G | S);
            3'd4: round_up = G;
            default: round_up = 1'b0;
        endcase
    end
    
    logic [11:0] sig_eff;
    assign sig_eff = {hidden, fraction};
    
    logic [11:0] sig_rounded;
    assign sig_rounded = sig_eff + round_up;
    
    logic signed [8:0] E_final;
    logic [9:0] fraction_final;
    always_comb begin
        if (sig_rounded[11]) begin
            E_final = E_eff + 1;
            fraction_final = 10'b0;
        end else begin
            E_final = E_eff;
            fraction_final = sig_rounded[9:0];
        end
    end
    
    logic [4:0] exp_encoded;
    always_comb begin
        if (E_final < -14) exp_encoded = 5'b0;
        else if (E_final == -14 && sig_rounded[10] == 0) exp_encoded = 5'b0;
        else exp_encoded = E_final + 15;
    end
    
    logic inexact;
    assign inexact = G | S;
    
    logic tiny;
    assign tiny = (exp_encoded == 0) && (mag_sum_reg != 0);
    
    logic UF;
    assign UF = tiny & inexact;
    
    logic OF;
    assign OF = (E_final > 15);
    
    logic NX;
    assign NX = inexact | OF;
    
    logic [15:0] computed_p_out;
    logic [4:0]  computed_status;
    logic s_zero;
    logic [15:0] overflow_res;
    
    always_comb begin
        s_zero = 1'b0;
        overflow_res = 16'b0;
        
        if (is_nan_res_reg) begin
            computed_p_out = 16'h7E00;
            computed_status = {NV_reg, 4'b0000};
        end else if (is_inf_res_reg) begin
            computed_p_out = {sign_inf_reg, 5'h1F, 10'h0};
            computed_status = 5'b0;
        end else if (mag_sum_reg == 0) begin
            if (sign_prod_reg == sign_p_reg) s_zero = sign_prod_reg;
            else s_zero = (rnd_reg == 3'd2) ? 1'b1 : 1'b0;
            computed_p_out = {s_zero, 15'b0};
            computed_status = 5'b0;
        end else if (OF) begin
            case (rnd_reg)
                3'd0: overflow_res = {sign_sum_reg, 5'h1F, 10'h0};
                3'd1: overflow_res = {sign_sum_reg, 5'h1E, 10'h3FF};
                3'd2: overflow_res = sign_sum_reg ? {1'b1, 5'h1F, 10'h0} : {1'b0, 5'h1E, 10'h3FF};
                3'd3: overflow_res = sign_sum_reg ? {1'b1, 5'h1E, 10'h3FF} : {1'b0, 5'h1F, 10'h0};
                3'd4: overflow_res = {sign_sum_reg, 5'h1F, 10'h0};
                default: overflow_res = {sign_sum_reg, 5'h1F, 10'h0};
            endcase
            computed_p_out = overflow_res;
            computed_status = {1'b0, 1'b0, 1'b1, 1'b0, 1'b1};
        end else begin
            computed_p_out = {sign_sum_reg, exp_encoded, fraction_final};
            computed_status = {1'b0, 1'b0, 1'b0, UF, NX};
        end
    end
    
    // -------------------------------------------------------------------------
    // Second Pipeline Register (Output and Exception)
    // -------------------------------------------------------------------------
    always_ff @(posedge clk or negedge rst_ni) begin
        if (!rst_ni) begin
            status_out <= 5'b0;
        end else if (en_pipe) begin
            status_out <= computed_status;
        end
    end
    
    always_ff @(posedge clk or negedge rst_ni) begin
        if (!rst_ni) begin
            p_out <= 16'b0;
        end else if (en_clear) begin
            if (flush_i) p_out <= 16'b0;
            else p_out <= computed_p_out;
        end
    end
endmodule


module fp16_gemm_array #(
  parameter int unsigned HEIGHT = 8,
  parameter int unsigned WIDTH  = 8
) (
  input  logic                                     clk_i,
  input  logic                                     rst_ni,
  input  logic [WIDTH-1:0][HEIGHT-1:0][15:0]       x_i,
  input  logic            [HEIGHT-1:0][15:0]       w_i,
  input  logic [WIDTH-1:0]            [15:0]       y_i,
  output logic [WIDTH-1:0]            [15:0]       z_o,
  input  logic [2:0]                               rnd_i,
  input  logic                                     accumulate_i,
  input  logic [WIDTH-1:0]                         row_clk_gate_en_i,
  input  logic                                     reg_enable_i,
  input  logic                                     flush_i,
  output logic [WIDTH-1:0][HEIGHT-1:0][4:0]        status_o
);

    logic [WIDTH-1:0][HEIGHT-1:0][15:0] p_out;
    logic [WIDTH-1:0][HEIGHT-1:0][4:0]  status_out;
    
    logic [WIDTH-1:0][HEIGHT-1:0][15:0] p_delay1;
    logic [WIDTH-1:0][HEIGHT-1:0][15:0] p_delay2;
    logic [WIDTH-1:0][HEIGHT-1:0][15:0] stage_p_in;
    
    integer r_idx, k_idx;
    
    // Partial-sum tracking shift-registers (spaced explicitly by 2 to hit D=4 delays)
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            for (r_idx = 0; r_idx < WIDTH; r_idx = r_idx + 1) begin
                for (k_idx = 0; k_idx < HEIGHT; k_idx = k_idx + 1) begin
                    p_delay1[r_idx][k_idx] <= 16'b0;
                    p_delay2[r_idx][k_idx] <= 16'b0;
                end
            end
        end else begin
            for (r_idx = 0; r_idx < WIDTH; r_idx = r_idx + 1) begin
                if (row_clk_gate_en_i[r_idx]) begin
                    if (flush_i) begin
                        for (k_idx = 0; k_idx < HEIGHT; k_idx = k_idx + 1) begin
                            p_delay1[r_idx][k_idx] <= 16'b0;
                            p_delay2[r_idx][k_idx] <= 16'b0;
                        end
                    end else if (reg_enable_i) begin
                        for (k_idx = 0; k_idx < HEIGHT; k_idx = k_idx + 1) begin
                            p_delay1[r_idx][k_idx] <= p_out[r_idx][k_idx];
                            p_delay2[r_idx][k_idx] <= p_delay1[r_idx][k_idx];
                        end
                    end
                end
            end
        end
    end

    // Input routing to individual stages
    always_comb begin
        for (int r = 0; r < WIDTH; r = r + 1) begin
            stage_p_in[r][0] = accumulate_i ? z_o[r] : y_i[r];
            for (int k = 1; k < HEIGHT; k = k + 1) begin
                stage_p_in[r][k] = p_delay2[r][k-1];
            end
        end
    end

    // FMA stage generation
    for (genvar r = 0; r < WIDTH; r = r + 1) begin : gen_row
        logic row_en_pipe;
        logic row_en_clear;
        assign row_en_pipe  = row_clk_gate_en_i[r] & reg_enable_i;
        assign row_en_clear = row_clk_gate_en_i[r] & (reg_enable_i | flush_i);
        
        for (genvar k = 0; k < HEIGHT; k = k + 1) begin : gen_stage
            fma_stage u_fma (
                .clk(clk_i),
                .en_pipe(row_en_pipe),
                .en_clear(row_en_clear),
                .rst_ni(rst_ni),
                .flush_i(flush_i),
                .x(x_i[r][k]),
                .w(w_i[k]),
                .p_in(stage_p_in[r][k]),
                .rnd_i(rnd_i),
                .p_out(p_out[r][k]),
                .status_out(status_out[r][k])
            );
        end
    end

    // Outputs routing
    always_comb begin
        for (int r = 0; r < WIDTH; r = r + 1) begin
            z_o[r] = p_out[r][HEIGHT-1];
            for (int k = 0; k < HEIGHT; k = k + 1) begin
                status_o[r][k] = status_out[r][k];
            end
        end
    end

endmodule