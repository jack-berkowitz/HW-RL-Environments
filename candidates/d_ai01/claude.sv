// =============================================================================
// fp16_gemm_array
// 
// Synthesizable SystemVerilog implementation of the d_ai01 FP16 GEMM array.
// Compliant with all arithmetic (A1-A10), control (C1-C5), and elaboration 
// constraints (T5), delivering cycle-accurate responses against the reference.
// =============================================================================

function logic [6:0] get_msb_86(input logic [85:0] val);
    // Tree-based priority encoder to circumvent Slang unroll limits (T5).
    // All variables declared at block scope before assignment.
    logic [127:0] v;
    logic [63:0]  v64; logic [6:0] idx64;
    logic [31:0]  v32; logic [6:0] idx32;
    logic [15:0]  v16; logic [6:0] idx16;
    logic [7:0]   v8;  logic [6:0] idx8;
    logic [3:0]   v4;  logic [6:0] idx4;
    logic [1:0]   v2;  logic [6:0] idx2;
    logic         v1;  logic [6:0] idx1;

    v = {42'd0, val};

    idx64 = v[127:64] != 0 ? 7'd64 : 7'd0;
    v64   = v[127:64] != 0 ? v[127:64] : v[63:0];

    idx32 = v64[63:32] != 0 ? 7'd32 : 7'd0;
    v32   = v64[63:32] != 0 ? v64[63:32] : v64[31:0];

    idx16 = v32[31:16] != 0 ? 7'd16 : 7'd0;
    v16   = v32[31:16] != 0 ? v32[31:16] : v32[15:0];

    idx8  = v16[15:8] != 0 ? 7'd8 : 7'd0;
    v8    = v16[15:8] != 0 ? v16[15:8] : v16[7:0];

    idx4  = v8[7:4] != 0 ? 7'd4 : 7'd0;
    v4    = v8[7:4] != 0 ? v8[7:4] : v8[3:0];

    idx2  = v4[3:2] != 0 ? 7'd2 : 7'd0;
    v2    = v4[3:2] != 0 ? v4[3:2] : v4[1:0];

    idx1  = v2[1] != 0 ? 7'd1 : 7'd0;

    return idx64 | idx32 | idx16 | idx8 | idx4 | idx2 | idx1;
endfunction

module fma_stage (
    input  logic        clk_i,
    input  logic        rst_ni,
    input  logic        row_en_i,
    input  logic        reg_en_i,
    input  logic        flush_i,
    input  logic [15:0] x_i,
    input  logic [15:0] w_i,
    input  logic [15:0] p_in_i,
    input  logic [2:0]  rnd_i,
    output logic [15:0] p_out_o,
    output logic [15:0] inter_stage_o,
    output logic [4:0]  status_o
);

    // =========================================================================
    // COMBINATIONAL 1: Unpack, Shift, and Exact Align
    // =========================================================================
    logic sign_x, sign_w, sign_y;
    logic [4:0] exp_x, exp_w, exp_y;
    logic [9:0] frac_x, frac_w, frac_y;
    
    assign {sign_x, exp_x, frac_x} = x_i;
    assign {sign_w, exp_w, frac_w} = w_i;
    assign {sign_y, exp_y, frac_y} = p_in_i;

    logic is_zero_x, is_zero_w, is_zero_y;
    logic is_inf_x, is_inf_w, is_inf_y;
    logic is_nan_x, is_nan_w, is_nan_y;

    assign is_zero_x = (exp_x == 0) && (frac_x == 0);
    assign is_zero_w = (exp_w == 0) && (frac_w == 0);
    assign is_zero_y = (exp_y == 0) && (frac_y == 0);

    assign is_inf_x = (exp_x == 31) && (frac_x == 0);
    assign is_inf_w = (exp_w == 31) && (frac_w == 0);
    assign is_inf_y = (exp_y == 31) && (frac_y == 0);

    assign is_nan_x = (exp_x == 31) && (frac_x != 0);
    assign is_nan_w = (exp_w == 31) && (frac_w != 0);
    assign is_nan_y = (exp_y == 31) && (frac_y != 0);

    logic [4:0] ep_x, ep_w, ep_y;
    assign ep_x = (exp_x == 0) ? 5'd1 : exp_x;
    assign ep_w = (exp_w == 0) ? 5'd1 : exp_w;
    assign ep_y = (exp_y == 0) ? 5'd1 : exp_y;

    logic [10:0] f_x, f_w, f_y;
    assign f_x = {(exp_x != 0 && !is_zero_x), frac_x};
    assign f_w = {(exp_w != 0 && !is_zero_w), frac_w};
    assign f_y = {(exp_y != 0 && !is_zero_y), frac_y};

    logic [21:0] prod22;
    assign prod22 = f_x * f_w;

    logic [5:0] sh_p, sh_y;
    assign sh_p = ep_x + ep_w;
    assign sh_y = ep_y + 6'd25;

    logic [85:0] prod86, y86;
    assign prod86 = {64'd0, prod22} << sh_p;
    assign y86    = {75'd0, f_y} << sh_y;

    logic sign_p;
    assign sign_p = sign_x ^ sign_w;

    logic signed [86:0] signed_p, signed_y, sum87;
    assign signed_p = sign_p ? -$signed({1'b0, prod86}) : $signed({1'b0, prod86});
    assign signed_y = sign_y ? -$signed({1'b0, y86})    : $signed({1'b0, y86});
    assign sum87    = signed_p + signed_y;

    logic is_inf_p, is_nan_p;
    assign is_inf_p = is_inf_x | is_inf_w;
    assign is_nan_p = is_nan_x | is_nan_w;

    logic c1_nan_flag, c1_nv_flag, c1_inf_flag, c1_inf_sign;
    assign c1_nan_flag = is_nan_p | is_nan_y;
    assign c1_nv_flag  = (is_inf_x & is_zero_w) | (is_zero_x & is_inf_w) |
                         (is_inf_p & is_inf_y & (sign_p != sign_y));
    assign c1_inf_flag = is_inf_p | is_inf_y;
    assign c1_inf_sign = is_inf_p ? sign_p : sign_y;

    logic [95:0] next_reg1;
    assign next_reg1 = {
        sum87,       // 87 bits [95:9]
        c1_nan_flag, // 1 bit   [8]
        c1_nv_flag,  // 1 bit   [7]
        c1_inf_flag, // 1 bit   [6]
        c1_inf_sign, // 1 bit   [5]
        sign_p,      // 1 bit   [4]
        sign_y,      // 1 bit   [3]
        rnd_i        // 3 bits  [2:0]
    };

    // =========================================================================
    // REGISTERS 
    // =========================================================================
    logic [95:0] reg1;
    logic [15:0] reg2_z;
    logic [4:0]  reg2_status;
    logic [15:0] reg3_z;
    logic [15:0] reg4_z;
    logic        flush_active_q;

    // Output associations (z_o tapped at reg3 per A3/L2 logic)
    assign p_out_o       = reg3_z;
    assign inter_stage_o = reg4_z;
    assign status_o      = reg2_status;

    // =========================================================================
    // COMBINATIONAL 2: Normalization and Rounding (Resolves at reg2!)
    // =========================================================================
    logic signed [86:0] r1_sum87;
    logic r1_nan, r1_nv, r1_inf, r1_inf_sign, r1_sign_p, r1_sign_y;
    logic [2:0] r1_rnd;
    assign {r1_sum87, r1_nan, r1_nv, r1_inf, r1_inf_sign, r1_sign_p, r1_sign_y, r1_rnd} = reg1;

    logic r1_sign_sum;
    logic [85:0] abs_sum;
    assign r1_sign_sum = r1_sum87[86];
    assign abs_sum     = r1_sign_sum ? -r1_sum87 : r1_sum87;

    logic [6:0] idx;
    assign idx = get_msb_86(abs_sum);

    logic [6:0] norm_sh;
    assign norm_sh = (idx >= 7'd36) ? (7'd81 - idx) : 7'd45;

    logic [85:0] shifted;
    assign shifted = abs_sum << norm_sh;

    logic [10:0] frac11;
    logic G, S, L;
    assign frac11 = shifted[81:71];
    assign G      = shifted[70];
    assign S      = (shifted[69:0] != 0);
    assign L      = frac11[0];

    logic [6:0] pre_round_E;
    assign pre_round_E = (idx >= 7'd36) ? (idx - 7'd35) : 7'd0;

    logic sign_final;
    always_comb begin
        if (abs_sum == 0) begin
            if (r1_sign_p == r1_sign_y) sign_final = r1_sign_p;
            else                        sign_final = (r1_rnd == 3'd2);
        end else begin
            sign_final = r1_sign_sum;
        end
    end

    logic round_up;
    always_comb begin
        case (r1_rnd)
            3'd0: round_up = G & (L | S);
            3'd1: round_up = 1'b0;
            3'd2: round_up = sign_final ? (G | S) : 1'b0;
            3'd3: round_up = sign_final ? 1'b0 : (G | S);
            3'd4: round_up = G;
            default: round_up = 1'b0;
        endcase
    end

    logic [11:0] frac_rounded;
    assign frac_rounded = {1'b0, frac11} + round_up;

    logic [6:0] E_final;
    assign E_final = pre_round_E + frac_rounded[11] + ((pre_round_E == 0) && frac_rounded[10]);

    logic [9:0] final_frac;
    assign final_frac = frac_rounded[11] ? 10'd0 : frac_rounded[9:0];

    logic is_overflow;
    assign is_overflow = (E_final >= 7'd31);

    logic [15:0] overflow_val;
    always_comb begin
        case (r1_rnd)
            3'd0: overflow_val = sign_final ? 16'xFC00 : 16'x7C00;
            3'd1: overflow_val = sign_final ? 16'xFBFF : 16'x7BFF;
            3'd2: overflow_val = sign_final ? 16'xFC00 : 16'x7BFF;
            3'd3: overflow_val = sign_final ? 16'xFBFF : 16'x7C00;
            3'd4: overflow_val = sign_final ? 16'xFC00 : 16'x7C00;
            default: overflow_val = sign_final ? 16'xFC00 : 16'x7C00;
        endcase
    end

    logic [15:0] next_z_val;
    always_comb begin
        if (r1_nan || r1_nv)  next_z_val = 16'x7E00;
        else if (r1_inf)      next_z_val = {r1_inf_sign, 5'd31, 10'd0};
        else if (is_overflow) next_z_val = overflow_val;
        else                  next_z_val = {sign_final, E_final[4:0], final_frac};
    end

    logic inexact, is_tiny;
    assign inexact = G | S;
    assign is_tiny = (E_final == 0);

    logic out_NV, out_DZ, out_OF, out_UF, out_NX;
    assign out_NV = r1_nv;
    assign out_DZ = 1'b0;
    assign out_OF = is_overflow & !r1_nan & !r1_inf & !r1_nv;
    assign out_UF = is_tiny & inexact & !r1_nan & !r1_inf & !r1_nv;
    assign out_NX = (inexact | out_OF | out_UF) & !r1_nan & !r1_inf & !r1_nv;

    logic [4:0] next_status;
    assign next_status = {out_NV, out_DZ, out_OF, out_UF, out_NX};

    // =========================================================================
    // STATE UPDATE (C1, C2, C4)
    // =========================================================================
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            reg1           <= 96'd0;
            reg2_z         <= 16'd0;
            reg2_status    <= 5'd0;
            reg3_z         <= 16'd0;
            reg4_z         <= 16'd0;
            flush_active_q <= 1'b0;
        end else if (row_en_i) begin
            if (flush_i) begin
                reg3_z <= 16'd0;
                reg4_z <= 16'd0;
                if (!flush_active_q) begin
                    reg2_status <= next_status;
                end
                flush_active_q <= 1'b1;
            end else if (reg_en_i) begin
                reg1           <= next_reg1;
                reg2_z         <= next_z_val;
                reg3_z         <= reg2_z;
                reg4_z         <= reg3_z;
                reg2_status    <= next_status;
                flush_active_q <= 1'b0;
            end
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
    logic [WIDTH-1:0][HEIGHT-1:0][15:0] inter_stage;

    genvar r, k;
    generate
        for (r = 0; r < WIDTH; r++) begin : gen_rows
            for (k = 0; k < HEIGHT; k++) begin : gen_stages
                logic [15:0] p_in;
                if (k == 0) begin
                    assign p_in = accumulate_i ? p_out[r][HEIGHT-1] : y_i[r];
                end else begin
                    assign p_in = inter_stage[r][k-1];
                end

                fma_stage u_fma (
                    .clk_i(clk_i),
                    .rst_ni(rst_ni),
                    .row_en_i(row_clk_gate_en_i[r]),
                    .reg_en_i(reg_enable_i),
                    .flush_i(flush_i),
                    .x_i(x_i[r][k]),
                    .w_i(w_i[k]),
                    .p_in_i(p_in),
                    .rnd_i(rnd_i),
                    .p_out_o(p_out[r][k]),
                    .inter_stage_o(inter_stage[r][k]),
                    .status_o(status_o[r][k])
                );
            end
            
            // Output maps to Stage (H-1)'s tap point implicitly defined by latency requirements 
            assign z_o[r] = p_out[r][HEIGHT-1];
        end
    endgenerate

endmodule