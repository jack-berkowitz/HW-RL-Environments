// =============================================================================
// fp16_gemm_array -- d_ai01 submission
// =============================================================================
// Implements the WIDTH x HEIGHT binary16 FMA array as specified in the
// contract.  The per-stage delay D is 4 enabled ticks, and the operand
// skew is handled by the pipeline structure described in the contract.
// =============================================================================

module fp16_fma (
    input  logic [15:0] a,
    input  logic [15:0] b,
    input  logic [15:0] c,
    input  logic [2:0]  rnd,
    output logic [15:0] result,
    output logic [4:0]  status
);

    // Unpack
    logic sa, sb, sc;
    logic [4:0] ea, eb, ec;
    logic [9:0] fa, fb, fc;
    logic is_nan_a, is_nan_b, is_nan_c;
    logic is_inf_a, is_inf_b, is_inf_c;
    logic is_zero_a, is_zero_b, is_zero_c;
    
    assign sa = a[15]; assign ea = a[14:10]; assign fa = a[9:0];
    assign sb = b[15]; assign eb = b[14:10]; assign fb = b[9:0];
    assign sc = c[15]; assign ec = c[14:10]; assign fc = c[9:0];
    
    assign is_nan_a = (ea == 5'h1F) && (fa != 0);
    assign is_nan_b = (eb == 5'h1F) && (fb != 0);
    assign is_nan_c = (ec == 5'h1F) && (fc != 0);
    assign is_inf_a = (ea == 5'h1F) && (fa == 0);
    assign is_inf_b = (eb == 5'h1F) && (fb == 0);
    assign is_inf_c = (ec == 5'h1F) && (fc == 0);
    assign is_zero_a = (ea == 0) && (fa == 0);
    assign is_zero_b = (eb == 0) && (fb == 0);
    assign is_zero_c = (ec == 0) && (fc == 0);
    
    // Internal signals
    logic [15:0] res;
    logic [4:0] st;
    
    int exp_a, exp_b, exp_c;
    logic [10:0] mant_a, mant_b, mant_c;
    logic sign_p;
    logic [21:0] P;
    int exp_p;
    logic [127:0] M_p, M_c, S;
    int e_common, shift_p, shift_c;
    logic sign_s;
    int msb_pos;
    logic found;
    int e_res;
    logic [10:0] M_int;
    logic guard, round_bit, sticky;
    logic [11:0] M_rounded;
    logic inexact;
    int shift_norm;
    int E_sub, sh_sub;
    logic [10:0] M_int_sub;
    logic guard_sub, round_sub, sticky_sub;
    logic [11:0] M_rounded_sub;
    logic inexact_sub;
    int i;
    
    // Rounding function
    function automatic void round_mant(
        input  logic [10:0] M_int_in,
        input  logic guard_in,
        input  logic round_in,
        input  logic sticky_in,
        input  logic [2:0] rnd_in,
        input  logic sign_in,
        output logic [11:0] M_rounded_out,
        output logic inexact_out
    );
        logic round_up;
        logic any_frac;
        any_frac = guard_in | round_in | sticky_in;
        inexact_out = any_frac;
        
        case (rnd_in)
            3'b000: begin // RNE
                if (guard_in) begin
                    if (round_in | sticky_in | M_int_in[0]) round_up = 1;
                    else round_up = 0;
                end else round_up = 0;
            end
            3'b001: round_up = 0; // RTZ
            3'b010: begin // RDN
                if (sign_in) round_up = any_frac;
                else round_up = 0;
            end
            3'b011: begin // RUP
                if (sign_in) round_up = 0;
                else round_up = any_frac;
            end
            3'b100: begin // RMM
                if (guard_in) round_up = 1;
                else round_up = 0;
            end
            default: round_up = 0;
        endcase
        
        if (round_up) M_rounded_out = M_int_in + 1;
        else M_rounded_out = M_int_in;
    endfunction
    
    always_comb begin
        // Default
        res = 16'h0000;
        st = 5'b0;
        
        // Effective values
        exp_a = (ea == 0) ? -14 : (ea - 15);
        mant_a = (ea == 0) ? {1'b0, fa} : {1'b1, fa};
        exp_b = (eb == 0) ? -14 : (eb - 15);
        mant_b = (eb == 0) ? {1'b0, fb} : {1'b1, fb};
        exp_c = (ec == 0) ? -14 : (ec - 15);
        mant_c = (ec == 0) ? {1'b0, fc} : {1'b1, fc};
        
        // Special cases
        if (is_nan_a || is_nan_b || is_nan_c) begin
            res = 16'h7E00;
            st = 5'b0;
        end else if (is_inf_a || is_inf_b) begin
            if (is_zero_a || is_zero_b) begin
                res = 16'h7E00;
                st[4] = 1'b1;
            end else begin
                sign_p = sa ^ sb;
                if (is_inf_c) begin
                    if (sign_p != sc) begin
                        res = 16'h7E00;
                        st[4] = 1'b1;
                    end else begin
                        res = {sign_p, 5'h1F, 10'b0};
                    end
                end else begin
                    res = {sign_p, 5'h1F, 10'b0};
                end
            end
        end else if (is_inf_c) begin
            res = c;
        end else begin
            // Finite
            sign_p = sa ^ sb;
            P = mant_a * mant_b;
            exp_p = exp_a + exp_b;
            
            if (P == 0) begin
                // product zero
                if (is_zero_c) begin
                    if (sign_p == sc) begin
                        res = {sign_p, 15'b0};
                    end else begin
                        if (rnd == 3'b010) res = 16'h8000;
                        else res = 16'h0000;
                    end
                end else begin
                    res = c;
                end
            end else begin
                // General FMA
                if (exp_p - 20 <= exp_c - 10) begin
                    e_common = exp_p - 20;
                end else begin
                    e_common = exp_c - 10;
                end
                shift_p = exp_p - 20 - e_common;
                shift_c = exp_c - 10 - e_common;
                
                M_p = {106'b0, P} << shift_p;
                M_c = {117'b0, mant_c} << shift_c;
                
                if (sign_p == sc) begin
                    S = M_p + M_c;
                    sign_s = sign_p;
                end else begin
                    if (M_p >= M_c) begin
                        S = M_p - M_c;
                        sign_s = sign_p;
                    end else begin
                        S = M_c - M_p;
                        sign_s = sc;
                    end
                end
                
                if (S == 0) begin
                    if (rnd == 3'b010) res = 16'h8000;
                    else res = 16'h0000;
                end else begin
                    // Find MSB
                    msb_pos = 0;
                    found = 0;
                    for (i = 127; i >= 0; i--) begin
                        if (!found && S[i]) begin
                            msb_pos = i;
                            found = 1;
                        end
                    end
                    
                    e_res = e_common + msb_pos;
                    
                    if (e_res > 15) begin
                        // Overflow
                        st[1] = 1'b1;
                        st[0] = 1'b1;
                        case (rnd)
                            3'b000: res = sign_s ? 16'hFC00 : 16'h7C00;
                            3'b001: res = sign_s ? 16'hFBFF : 16'h7BFF;
                            3'b010: res = sign_s ? 16'hFC00 : 16'h7BFF;
                            3'b011: res = sign_s ? 16'hFBFF : 16'h7C00;
                            3'b100: res = sign_s ? 16'hFC00 : 16'h7C00;
                            default: res = sign_s ? 16'hFC00 : 16'h7C00;
                        endcase
                    end else if (e_res < -14) begin
                        // Subnormal
                        E_sub = e_common + 24;
                        if (E_sub >= 0) begin
                            M_int_sub = S << E_sub;
                            guard_sub = 0;
                            round_sub = 0;
                            sticky_sub = 0;
                        end else begin
                            sh_sub = -E_sub;
                            if (sh_sub >= 128) begin
                                M_int_sub = 0;
                                guard_sub = 0;
                                round_sub = 0;
                                sticky_sub = |S;
                            end else if (sh_sub >= 3) begin
                                M_int_sub = S >> sh_sub;
                                guard_sub = S[sh_sub-1];
                                round_sub = S[sh_sub-2];
                                sticky_sub = |(S & ((128'd1 << (sh_sub-2)) - 1));
                            end else if (sh_sub == 2) begin
                                M_int_sub = S >> 2;
                                guard_sub = S[1];
                                round_sub = S[0];
                                sticky_sub = 0;
                            end else if (sh_sub == 1) begin
                                M_int_sub = S >> 1;
                                guard_sub = S[0];
                                round_sub = 0;
                                sticky_sub = 0;
                            end else begin
                                M_int_sub = S;
                                guard_sub = 0;
                                round_sub = 0;
                                sticky_sub = 0;
                            end
                        end
                        
                        round_mant(M_int_sub, guard_sub, round_sub, sticky_sub,
                                   rnd, sign_s, M_rounded_sub, inexact_sub);
                        
                        if (M_rounded_sub >= 1024) begin
                            res = {sign_s, 5'd1, 10'b0};
                            st[4] = 0;
                            st[1] = 0;
                            st[3] = 0;
                            st[0] = inexact_sub;
                        end else begin
                            res = {sign_s, 5'd0, M_rounded_sub[9:0]};
                            st[4] = 0;
                            st[1] = 0;
                            st[3] = inexact_sub;
                            st[0] = inexact_sub;
                        end
                    end else begin
                        // Normal
                        shift_norm = msb_pos - 10;
                        if (shift_norm >= 3) begin
                            M_int = S >> shift_norm;
                            guard = S[shift_norm-1];
                            round_bit = S[shift_norm-2];
                            sticky = |(S & ((128'd1 << (shift_norm-2)) - 1));
                        end else if (shift_norm == 2) begin
                            M_int = S >> 2;
                            guard = S[1];
                            round_bit = S[0];
                            sticky = 0;
                        end else if (shift_norm == 1) begin
                            M_int = S >> 1;
                            guard = S[0];
                            round_bit = 0;
                            sticky = 0;
                        end else if (shift_norm == 0) begin
                            M_int = S;
                            guard = 0;
                            round_bit = 0;
                            sticky = 0;
                        end else begin
                            M_int = S << (-shift_norm);
                            guard = 0;
                            round_bit = 0;
                            sticky = 0;
                        end
                        
                        round_mant(M_int, guard, round_bit, sticky,
                                   rnd, sign_s, M_rounded, inexact);
                        
                        if (M_rounded >= 2048) begin
                            M_rounded = 1024;
                            e_res = e_res + 1;
                        end
                        
                        if (e_res > 15) begin
                            st[1] = 1'b1;
                            st[0] = 1'b1;
                            case (rnd)
                                3'b000: res = sign_s ? 16'hFC00 : 16'h7C00;
                                3'b001: res = sign_s ? 16'hFBFF : 16'h7BFF;
                                3'b010: res = sign_s ? 16'hFC00 : 16'h7BFF;
                                3'b011: res = sign_s ? 16'hFBFF : 16'h7C00;
                                3'b100: res = sign_s ? 16'hFC00 : 16'h7C00;
                                default: res = sign_s ? 16'hFC00 : 16'h7C00;
                            endcase
                        end else begin
                            res = {sign_s, (e_res + 15), M_rounded[9:0]};
                            st[4] = 0;
                            st[1] = 0;
                            st[3] = 0;
                            st[0] = inexact;
                        end
                    end
                end
            end
        end
    end
    
    assign result = res;
    assign status = st;
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

  localparam int D = 4;
  localparam int DFB = 4 * HEIGHT;

  genvar r, k;
  generate
    for (r = 0; r < WIDTH; r++) begin : row_gen
      // Row-specific signals
      logic [15:0] p_reg [0:HEIGHT-1];
      logic [15:0] p_dly [0:HEIGHT-2][0:2];
      logic [15:0] z_dly [0:1];
      logic [4:0] status_reg1 [0:HEIGHT-1];
      logic [4:0] status_reg2 [0:HEIGHT-1];
      logic [15:0] z_fb_pipe [0:DFB-1];
      logic flush_hold;
      
      // FMA outputs
      logic [15:0] fma_out [0:HEIGHT-1];
      logic [4:0] fma_status [0:HEIGHT-1];
      
      // Addend for stage 0
      logic [15:0] addend0;
      assign addend0 = accumulate_i ? z_fb_pipe[DFB-1] : y_i[r];
      
      // Stage 0
      fp16_fma fma0 (
          .a(x_i[r][0]),
          .b(w_i[0]),
          .c(addend0),
          .rnd(rnd_i),
          .result(fma_out[0]),
          .status(fma_status[0])
      );
      
      // Stages 1..HEIGHT-1
      for (k = 1; k < HEIGHT; k++) begin : stage_gen
          fp16_fma fma_k (
              .a(x_i[r][k]),
              .b(w_i[k]),
              .c(p_dly[k-1][2]),
              .rnd(rnd_i),
              .result(fma_out[k]),
              .status(fma_status[k])
          );
      end
      
      // Output z_o
      assign z_o[r] = z_dly[1];
      
      // status_o
      for (k = 0; k < HEIGHT; k++) begin : status_gen
          assign status_o[r][k] = status_reg2[k];
      end
      
      // Clock enable logic
      logic row_clk_en;
      assign row_clk_en = row_clk_gate_en_i[r];
      
      // Sequential logic
      always_ff @(posedge clk_i or negedge rst_ni) begin
          int i, j;
          if (!rst_ni) begin
              for (i = 0; i < HEIGHT; i++) begin
                  p_reg[i] <= 16'b0;
                  status_reg1[i] <= 5'b0;
                  status_reg2[i] <= 5'b0;
              end
              for (i = 0; i < HEIGHT-1; i++) begin
                  for (j = 0; j < 3; j++) begin
                      p_dly[i][j] <= 16'b0;
                  end
              end
              z_dly[0] <= 16'b0;
              z_dly[1] <= 16'b0;
              for (i = 0; i < DFB; i++) begin
                  z_fb_pipe[i] <= 16'b0;
              end
              flush_hold <= 1'b0;
          end else if (row_clk_en) begin
              if (flush_i) begin
                  // Flush: clear all pipeline registers
                  for (i = 0; i < HEIGHT; i++) begin
                      p_reg[i] <= 16'b0;
                  end
                  for (i = 0; i < HEIGHT-1; i++) begin
                      for (j = 0; j < 3; j++) begin
                          p_dly[i][j] <= 16'b0;
                      end
                  end
                  z_dly[0] <= 16'b0;
                  z_dly[1] <= 16'b0;
                  for (i = 0; i < DFB; i++) begin
                      z_fb_pipe[i] <= 16'b0;
                  end
                  // Status: first tick updates normally, then holds
                  if (!flush_hold) begin
                      for (i = 0; i < HEIGHT; i++) begin
                          status_reg1[i] <= fma_status[i];
                          status_reg2[i] <= status_reg1[i];
                      end
                      flush_hold <= 1'b1;
                  end
              end else begin
                  // Normal operation (or frozen by reg_enable_i)
                  flush_hold <= 1'b0;
                  if (reg_enable_i) begin
                      // Shift pipeline
                      for (i = 0; i < HEIGHT; i++) begin
                          p_reg[i] <= fma_out[i];
                          status_reg1[i] <= fma_status[i];
                          status_reg2[i] <= status_reg1[i];
                      end
                      for (i = 0; i < HEIGHT-1; i++) begin
                          p_dly[i][0] <= p_reg[i];
                          p_dly[i][1] <= p_dly[i][0];
                          p_dly[i][2] <= p_dly[i][1];
                      end
                      z_dly[0] <= p_reg[HEIGHT-1];
                      z_dly[1] <= z_dly[0];
                      // Shift feedback pipe
                      z_fb_pipe[0] <= z_dly[1];
                      for (i = 1; i < DFB; i++) begin
                          z_fb_pipe[i] <= z_fb_pipe[i-1];
                      end
                  end
              end
          end
      end
    end
  endgenerate

endmodule
