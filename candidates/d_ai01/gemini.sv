// =============================================================================
// fp16_gemm_array -- FP16 weight-broadcast multiply-accumulate array
// 
// Implements the D=4 delayed pipeline, with exactly 3 ticks to z_o,
// properly staggered FMA execution, correct rounding, IEEE subnormals,
// and exact alignment of the flush / freeze / accumulate constraints.
// =============================================================================

typedef struct packed {
    logic signed [83:0] sum;
    logic Sp;
    logic Sy;
    logic p_inf;
    logic p_nan;
    logic p_nv;
    logic p_zero;
    logic y_inf;
    logic y_nan;
    logic y_zero;
    logic [2:0] rnd;
} stage1_t;

typedef struct packed {
    logic [15:0] res;
    logic [4:0] flags;
} stage2_t;


module fp16_fma_stage1 (
    input  logic [15:0] x,
    input  logic [15:0] w,
    input  logic [15:0] y,
    input  logic [2:0]  rnd,
    output stage1_t     out
);
    logic Sx, Sw, Sy;
    logic [4:0] Ex, Ew, Ey;
    logic [10:0] Mx, Mw, My;
    
    assign Sx = x[15];
    assign Ex = x[14:10];
    assign Mx = (Ex == 0) ? {1'b0, x[9:0]} : {1'b1, x[9:0]};
    
    assign Sw = w[15];
    assign Ew = w[14:10];
    assign Mw = (Ew == 0) ? {1'b0, w[9:0]} : {1'b1, w[9:0]};
    
    assign Sy = y[15];
    assign Ey = y[14:10];
    assign My = (Ey == 0) ? {1'b0, y[9:0]} : {1'b1, y[9:0]};
    
    logic [5:0] Ep_shift;
    assign Ep_shift = (Ex == 0 ? 6'd1 : {1'b0, Ex}) + (Ew == 0 ? 6'd1 : {1'b0, Ew}) - 6'd2;
    
    logic [21:0] Mp;
    assign Mp = Mx * Mw;
    
    logic [81:0] p_mag;
    assign p_mag = {60'b0, Mp} << Ep_shift;
    
    logic [5:0] Ey_shift;
    assign Ey_shift = (Ey == 0 ? 6'd1 : {1'b0, Ey}) + 6'd23;
    
    logic [81:0] y_mag;
    assign y_mag = {71'b0, My} << Ey_shift;
    
    logic Sp;
    assign Sp = Sx ^ Sw;
    
    logic x_inf, x_nan, x_zero;
    assign x_inf  = (Ex == 5'h1f) && (x[9:0] == 0);
    assign x_nan  = (Ex == 5'h1f) && (x[9:0] != 0);
    assign x_zero = (Ex == 0) && (Mx == 0);
    
    logic w_inf, w_nan, w_zero;
    assign w_inf  = (Ew == 5'h1f) && (w[9:0] == 0);
    assign w_nan  = (Ew == 5'h1f) && (w[9:0] != 0);
    assign w_zero = (Ew == 0) && (Mw == 0);
    
    logic y_inf, y_nan, y_zero;
    assign y_inf  = (Ey == 5'h1f) && (y[9:0] == 0);
    assign y_nan  = (Ey == 5'h1f) && (y[9:0] != 0);
    assign y_zero = (Ey == 0) && (My == 0);
    
    logic p_inf, p_nan, p_nv, p_zero;
    assign p_inf  = (x_inf && !w_zero) || (w_inf && !x_zero);
    assign p_nan  = x_nan || w_nan;
    assign p_nv   = (x_inf && w_zero) || (x_zero && w_inf);
    assign p_zero = x_zero || w_zero;
    
    logic signed [82:0] p_tc;
    logic signed [82:0] y_tc;
    
    assign p_tc = (p_zero) ? 83'sd0 : (Sp ? -$signed({1'b0, p_mag}) : $signed({1'b0, p_mag}));
    assign y_tc = (y_zero) ? 83'sd0 : (Sy ? -$signed({1'b0, y_mag}) : $signed({1'b0, y_mag}));
    
    logic signed [83:0] sum;
    assign sum = p_tc + y_tc;
    
    assign out.sum = sum;
    assign out.Sp = Sp;
    assign out.Sy = Sy;
    assign out.p_inf = p_inf;
    assign out.p_nan = p_nan;
    assign out.p_nv = p_nv;
    assign out.p_zero = p_zero;
    assign out.y_inf = y_inf;
    assign out.y_nan = y_nan;
    assign out.y_zero = y_zero;
    assign out.rnd = rnd;
endmodule


module fp16_fma_stage2 (
    input  stage1_t in,
    output stage2_t out
);
    logic sum_sign;
    logic [82:0] sum_mag;
    assign sum_sign = in.sum[83];
    assign sum_mag  = sum_sign ? -in.sum[82:0] : in.sum[82:0];
    
    logic zero_sign;
    assign zero_sign = (in.p_zero && in.y_zero && (in.Sp == in.Sy)) ? in.Sp : ((in.rnd == 3'd2) ? 1'b1 : 1'b0);
    
    logic final_sign;
    assign final_sign = (sum_mag == 0) ? zero_sign : sum_sign;
    
    logic [127:0] mag_ext;
    assign mag_ext = {45'b0, sum_mag};
    
    logic [6:0] lz;
    logic [63:0] s64;
    logic [31:0] s32;
    logic [15:0] s16;
    logic [7:0] s8;
    logic [3:0] s4;
    logic [1:0] s2;
    
    always_comb begin
        lz = 7'b0;
        if (mag_ext[127:64] == 0) begin lz[6] = 1'b1; s64 = mag_ext[63:0]; end else begin lz[6] = 1'b0; s64 = mag_ext[127:64]; end
        if (s64[63:32] == 0)      begin lz[5] = 1'b1; s32 = s64[31:0];     end else begin lz[5] = 1'b0; s32 = s64[63:32];      end
        if (s32[31:16] == 0)      begin lz[4] = 1'b1; s16 = s32[15:0];     end else begin lz[4] = 1'b0; s16 = s32[31:16];      end
        if (s16[15:8] == 0)       begin lz[3] = 1'b1; s8 = s16[7:0];       end else begin lz[3] = 1'b0; s8 = s16[15:8];        end
        if (s8[7:4] == 0)         begin lz[2] = 1'b1; s4 = s8[3:0];        end else begin lz[2] = 1'b0; s4 = s8[7:4];          end
        if (s4[3:2] == 0)         begin lz[1] = 1'b1; s2 = s4[1:0];        end else begin lz[1] = 1'b0; s2 = s4[3:2];          end
        if (s2[1] == 0)           begin lz[0] = 1'b1;                      end else begin lz[0] = 1'b0;                        end
    end
    
    logic [6:0] pos;
    assign pos = 7'd127 - lz;
    
    logic [6:0] eff_pos;
    assign eff_pos = (pos >= 7'd34) ? pos : 7'd34;
    
    logic [6:0] lshift;
    assign lshift = 7'd127 - eff_pos;
    
    logic [127:0] sum_mag_shifted;
    assign sum_mag_shifted = mag_ext << lshift;
    
    logic implicit_bit;
    logic [9:0] frac_bits;
    logic round_bit;
    logic sticky_bit;
    
    assign implicit_bit = sum_mag_shifted[127];
    assign frac_bits    = sum_mag_shifted[126:117];
    assign round_bit    = sum_mag_shifted[116];
    assign sticky_bit   = |sum_mag_shifted[115:0];
    
    logic rnd_up;
    always_comb begin
        rnd_up = 1'b0;
        case (in.rnd)
            3'd0: rnd_up = round_bit & (sticky_bit | frac_bits[0]);
            3'd1: rnd_up = 1'b0;
            3'd2: rnd_up = final_sign & (round_bit | sticky_bit);
            3'd3: rnd_up = ~final_sign & (round_bit | sticky_bit);
            3'd4: rnd_up = round_bit;
            default: rnd_up = 1'b0;
        endcase
    end
    
    logic [11:0] rounded_mant;
    assign rounded_mant = {1'b0, implicit_bit, frac_bits} + {11'b0, rnd_up};
    
    logic [5:0] pre_E;
    assign pre_E = eff_pos - 7'd33;
    
    logic [5:0] final_E;
    logic [9:0] final_frac;
    
    always_comb begin
        if (rounded_mant[11]) begin
            final_E = pre_E + 6'd1;
            final_frac = rounded_mant[10:1];
        end else begin
            final_E = pre_E;
            final_frac = rounded_mant[9:0];
        end
    end
    
    logic [4:0] pack_E;
    assign pack_E = (final_E == 6'd1 && rounded_mant[11:10] == 2'b00) ? 5'd0 : final_E[4:0];
    
    logic tiny;
    assign tiny = (pack_E == 5'd0) && (sum_mag != 0);
    
    logic nx_flag;
    assign nx_flag = round_bit | sticky_bit;
    
    logic uf_flag;
    assign uf_flag = tiny & nx_flag;
    
    logic overflow;
    assign overflow = (final_E >= 6'd31);
    
    logic [15:0] ovf_val;
    always_comb begin
        case (in.rnd)
            3'd0: ovf_val = final_sign ? 16'hFC00 : 16'h7C00;
            3'd1: ovf_val = final_sign ? 16'hFBFF : 16'h7BFF;
            3'd2: ovf_val = final_sign ? 16'hFC00 : 16'h7BFF;
            3'd3: ovf_val = final_sign ? 16'hFBFF : 16'h7C00;
            3'd4: ovf_val = final_sign ? 16'hFC00 : 16'h7C00;
            default: ovf_val = final_sign ? 16'hFC00 : 16'h7C00;
        endcase
    end
    
    logic is_nan, is_inf, nv_flag;
    logic inf_minus_inf;
    assign inf_minus_inf = in.p_inf && in.y_inf && (in.Sp != in.Sy);
    
    assign is_nan = in.p_nan || in.y_nan || in.p_nv || inf_minus_inf;
    assign is_inf = in.p_inf || in.y_inf;
    assign nv_flag = in.p_nv || inf_minus_inf;
    
    logic [15:0] final_res;
    logic [4:0] final_flags;
    
    always_comb begin
        final_flags = 5'b0;
        if (is_nan) begin
            final_res = 16'h7E00;
            final_flags[4] = nv_flag;
        end else if (is_inf) begin
            logic inf_sign;
            inf_sign = in.p_inf ? in.Sp : in.Sy;
            final_res = {inf_sign, 15'h7C00};
        end else if (overflow) begin
            final_res = ovf_val;
            final_flags[2] = 1'b1; // OF
            final_flags[0] = 1'b1; // NX
        end else begin
            final_res = {final_sign, pack_E, final_frac};
            final_flags[1] = uf_flag; // UF
            final_flags[0] = nx_flag; // NX
        end
    end
    
    assign out.res = final_res;
    assign out.flags = final_flags;
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

    stage1_t R1 [WIDTH][HEIGHT];
    stage2_t R2 [WIDTH][HEIGHT];
    logic [15:0] R3 [WIDTH][HEIGHT];
    logic [15:0] R4 [WIDTH][HEIGHT];
    
    logic prev_flush [WIDTH];

    genvar r, k;
    generate
        for (r = 0; r < WIDTH; r++) begin : row_gen
            wire row_clk_en = row_clk_gate_en_i[r];
            
            always_ff @(posedge clk_i or negedge rst_ni) begin
                if (!rst_ni) begin 
                    prev_flush[r] <= 1'b0;
                end else if (row_clk_en) begin
                    if (reg_enable_i || flush_i) begin
                        prev_flush[r] <= flush_i;
                    end
                end
            end
            
            wire status_en = (reg_enable_i & ~flush_i) | (flush_i & ~prev_flush[r]);
            
            for (k = 0; k < HEIGHT; k++) begin : stage_gen
                logic [15:0] stg_x;
                logic [15:0] stg_w;
                logic [15:0] stg_y;
                
                assign stg_x = x_i[r][k];
                assign stg_w = w_i[k];
                
                if (k == 0) begin
                    assign stg_y = accumulate_i ? z_o[r] : y_i[r];
                end else begin
                    assign stg_y = R4[r][k-1];
                end
                
                stage1_t s1_out;
                fp16_fma_stage1 u_stg1 (
                    .x(stg_x),
                    .w(stg_w),
                    .y(stg_y),
                    .rnd(rnd_i),
                    .out(s1_out)
                );
                
                stage2_t s2_out;
                fp16_fma_stage2 u_stg2 (
                    .in(R1[r][k]),
                    .out(s2_out)
                );
                
                always_ff @(posedge clk_i or negedge rst_ni) begin
                    if (!rst_ni) begin
                        R1[r][k] <= '0;
                        R2[r][k] <= '0;
                        R3[r][k] <= '0;
                        R4[r][k] <= '0;
                    end else if (row_clk_en) begin
                        if (flush_i) begin
                            R1[r][k] <= '0;
                            R2[r][k] <= '0;
                            R3[r][k] <= '0;
                            R4[r][k] <= '0;
                        end else if (reg_enable_i) begin
                            R1[r][k] <= s1_out;
                            R2[r][k] <= s2_out;
                            R3[r][k] <= R2[r][k].res;
                            R4[r][k] <= R3[r][k];
                        end
                    end
                end
                
                always_ff @(posedge clk_i or negedge rst_ni) begin
                    if (!rst_ni) begin
                        status_o[r][k] <= 5'b0;
                    end else if (row_clk_en) begin
                        if (status_en) begin
                            status_o[r][k] <= s2_out.flags;
                        end
                    end
                end
            end
            
            assign z_o[r] = R3[r][HEIGHT-1];
        end
    endgenerate

endmodule