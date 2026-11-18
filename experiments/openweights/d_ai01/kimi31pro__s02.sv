// Exact, one-rounding binary16 FMA used by the array stages.
module fp16_gemm_array_fma (
  input  logic [15:0] a_i,
  input  logic [15:0] b_i,
  input  logic [15:0] c_i,
  input  logic [2:0]  rnd_i,
  output logic [15:0] z_o,
  output logic [4:0]  status_o
);

  logic       sign_a, sign_b, sign_c;
  logic [4:0] exp_a, exp_b, exp_c;
  logic [9:0] frac_a, frac_b, frac_c;

  logic a_nan, b_nan, c_nan;
  logic a_snan, b_snan, c_snan;
  logic a_inf, b_inf, c_inf;
  logic a_zero, b_zero;

  logic [10:0] sig_a, sig_b, sig_c;
  logic [5:0]  ea, eb, ec;

  logic [21:0] product_sig;
  logic [6:0]  product_shift;
  logic [6:0]  addend_shift;

  // All finite FMA results are exactly representable as mag * 2^-48.
  logic [81:0] product_mag;
  logic [81:0] addend_mag;
  logic [81:0] mag;
  logic        product_sign;
  logic        result_sign;

  logic [6:0]  leading;
  logic [81:0] normalized;

  logic [10:0] significand;
  logic [10:0] final_significand;
  logic [11:0] rounded_significand;
  logic [6:0]  exp_out;
  logic        normal_guard;
  logic        normal_sticky;
  logic        normal_inexact;
  logic        normal_increment;

  logic [9:0]  sub_significand;
  logic [10:0] sub_rounded;
  logic        sub_guard;
  logic        sub_sticky;
  logic        sub_inexact;
  logic        sub_increment;

  logic overflow_to_inf;

  // Priority encode without an elaboration-time iterative bit scan.
  function automatic logic [6:0] msb82(input logic [81:0] v);
    logic [83:0] u;
    logic [4:0]  group_index;
    logic [3:0]  group_value;
    logic [1:0]  group_offset;
    begin
      u = {2'b00, v};

      if      (|u[83:80]) group_index = 5'd20;
      else if (|u[79:76]) group_index = 5'd19;
      else if (|u[75:72]) group_index = 5'd18;
      else if (|u[71:68]) group_index = 5'd17;
      else if (|u[67:64]) group_index = 5'd16;
      else if (|u[63:60]) group_index = 5'd15;
      else if (|u[59:56]) group_index = 5'd14;
      else if (|u[55:52]) group_index = 5'd13;
      else if (|u[51:48]) group_index = 5'd12;
      else if (|u[47:44]) group_index = 5'd11;
      else if (|u[43:40]) group_index = 5'd10;
      else if (|u[39:36]) group_index = 5'd9;
      else if (|u[35:32]) group_index = 5'd8;
      else if (|u[31:28]) group_index = 5'd7;
      else if (|u[27:24]) group_index = 5'd6;
      else if (|u[23:20]) group_index = 5'd5;
      else if (|u[19:16]) group_index = 5'd4;
      else if (|u[15:12]) group_index = 5'd3;
      else if (|u[11:8])  group_index = 5'd2;
      else if (|u[7:4])   group_index = 5'd1;
      else                group_index = 5'd0;

      group_value = u[(group_index * 4) +: 4];

      casez (group_value)
        4'b1???: group_offset = 2'd3;
        4'b01??: group_offset = 2'd2;
        4'b001?: group_offset = 2'd1;
        default: group_offset = 2'd0;
      endcase

      msb82 = {group_index, 2'b00} + {5'b00000, group_offset};
    end
  endfunction

  always_comb begin
    sign_a = a_i[15];
    sign_b = b_i[15];
    sign_c = c_i[15];

    exp_a = a_i[14:10];
    exp_b = b_i[14:10];
    exp_c = c_i[14:10];

    frac_a = a_i[9:0];
    frac_b = b_i[9:0];
    frac_c = c_i[9:0];

    a_nan = (exp_a == 5'h1f) && (frac_a != 0);
    b_nan = (exp_b == 5'h1f) && (frac_b != 0);
    c_nan = (exp_c == 5'h1f) && (frac_c != 0);

    a_snan = a_nan && !frac_a[9];
    b_snan = b_nan && !frac_b[9];
    c_snan = c_nan && !frac_c[9];

    a_inf = (exp_a == 5'h1f) && (frac_a == 0);
    b_inf = (exp_b == 5'h1f) && (frac_b == 0);
    c_inf = (exp_c == 5'h1f) && (frac_c == 0);

    a_zero = (exp_a == 0) && (frac_a == 0);
    b_zero = (exp_b == 0) && (frac_b == 0);

    sig_a = (exp_a == 0) ? {1'b0, frac_a} : {1'b1, frac_a};
    sig_b = (exp_b == 0) ? {1'b0, frac_b} : {1'b1, frac_b};
    sig_c = (exp_c == 0) ? {1'b0, frac_c} : {1'b1, frac_c};

    ea = (exp_a == 0) ? 6'd1 : {1'b0, exp_a};
    eb = (exp_b == 0) ? 6'd1 : {1'b0, exp_b};
    ec = (exp_c == 0) ? 6'd1 : {1'b0, exp_c};

    product_sig = sig_a * sig_b;
    product_shift = {1'b0, ea} + {1'b0, eb} - 7'd2;
    addend_shift = {1'b0, ec} + 7'd23;

    product_mag = {{60{1'b0}}, product_sig} << product_shift;
    addend_mag  = {{71{1'b0}}, sig_c}       << addend_shift;

    product_sign = sign_a ^ sign_b;
    mag = 82'd0;
    result_sign = 1'b0;

    if (product_sign == sign_c) begin
      mag = product_mag + addend_mag;
      result_sign = product_sign;
    end else if (product_mag > addend_mag) begin
      mag = product_mag - addend_mag;
      result_sign = product_sign;
    end else if (addend_mag > product_mag) begin
      mag = addend_mag - product_mag;
      result_sign = sign_c;
    end else begin
      // Exact cancellation, including opposite-signed zeros.
      mag = 82'd0;
      result_sign = (rnd_i == 3'd2);
    end

    z_o = 16'h0000;
    status_o = 5'b00000;

    leading = 7'd0;
    normalized = 82'd0;
    significand = 11'd0;
    final_significand = 11'd0;
    rounded_significand = 12'd0;
    exp_out = 7'd0;
    normal_guard = 1'b0;
    normal_sticky = 1'b0;
    normal_inexact = 1'b0;
    normal_increment = 1'b0;

    sub_significand = 10'd0;
    sub_rounded = 11'd0;
    sub_guard = 1'b0;
    sub_sticky = 1'b0;
    sub_inexact = 1'b0;
    sub_increment = 1'b0;
    overflow_to_inf = 1'b0;

    if (a_nan || b_nan || c_nan) begin
      z_o = 16'h7e00;
      status_o[4] = a_snan || b_snan || c_snan;
    end else if ((a_inf && b_zero) || (b_inf && a_zero)) begin
      z_o = 16'h7e00;
      status_o[4] = 1'b1;
    end else if (a_inf || b_inf) begin
      if (c_inf && (sign_c != product_sign)) begin
        z_o = 16'h7e00;
        status_o[4] = 1'b1;
      end else begin
        z_o = {product_sign, 15'h7c00};
      end
    end else if (c_inf) begin
      z_o = {sign_c, 15'h7c00};
    end else if (mag == 0) begin
      z_o = {result_sign, 15'd0};
    end else begin
      leading = msb82(mag);

      if (leading >= 7'd34) begin
        // Normal-range rounding. The leading bit is moved to bit 80.
        normalized = mag << (7'd80 - leading);
        significand = normalized[80:70];
        normal_guard = normalized[69];
        normal_sticky = |normalized[68:0];
        normal_inexact = normal_guard || normal_sticky;

        case (rnd_i)
          3'd0: normal_increment =
                  normal_guard && (normal_sticky || significand[0]);
          3'd1: normal_increment = 1'b0;
          3'd2: normal_increment = result_sign && normal_inexact;
          3'd3: normal_increment = !result_sign && normal_inexact;
          3'd4: normal_increment = normal_guard;
          default: normal_increment =
                  normal_guard && (normal_sticky || significand[0]);
        endcase

        rounded_significand =
            {1'b0, significand} + {{11{1'b0}}, normal_increment};
        exp_out = leading - 7'd33;
        final_significand = rounded_significand[10:0];

        if (rounded_significand[11]) begin
          exp_out = exp_out + 7'd1;
          final_significand = 11'd1024;
        end

        if (exp_out > 7'd30) begin
          overflow_to_inf =
              (rnd_i == 3'd0) || (rnd_i == 3'd4) ||
              ((rnd_i == 3'd3) && !result_sign) ||
              ((rnd_i == 3'd2) && result_sign);

          z_o = {result_sign,
                 overflow_to_inf ? 15'h7c00 : 15'h7bff};
          status_o[2] = 1'b1;
          status_o[0] = 1'b1;
        end else begin
          z_o = {result_sign, exp_out[4:0], final_significand[9:0]};
          status_o[0] = normal_inexact;
        end
      end else begin
        // Tiny results are rounded directly to the 2^-24 quantum.
        sub_significand = mag[33:24];
        sub_guard = mag[23];
        sub_sticky = |mag[22:0];
        sub_inexact = sub_guard || sub_sticky;

        case (rnd_i)
          3'd0: sub_increment =
                  sub_guard && (sub_sticky || sub_significand[0]);
          3'd1: sub_increment = 1'b0;
          3'd2: sub_increment = result_sign && sub_inexact;
          3'd3: sub_increment = !result_sign && sub_inexact;
          3'd4: sub_increment = sub_guard;
          default: sub_increment =
                  sub_guard && (sub_sticky || sub_significand[0]);
        endcase

        sub_rounded =
            {1'b0, sub_significand} + {{10{1'b0}}, sub_increment};

        if (sub_rounded[10]) begin
          z_o = {result_sign, 5'd1, 10'd0};
        end else begin
          z_o = {result_sign, 5'd0, sub_rounded[9:0]};
        end

        // Tininess is determined from the exact, pre-rounded result.
        status_o[1] = sub_inexact;
        status_o[0] = sub_inexact;
      end
    end
  end
endmodule


module fp16_gemm_array #(
  parameter int unsigned HEIGHT = 8,
  parameter int unsigned WIDTH  = 8
) (
  input  logic                               clk_i,
  input  logic                               rst_ni,
  input  logic [WIDTH-1:0][HEIGHT-1:0][15:0] x_i,
  input  logic            [HEIGHT-1:0][15:0] w_i,
  input  logic [WIDTH-1:0]            [15:0] y_i,
  output logic [WIDTH-1:0]            [15:0] z_o,
  input  logic [2:0]                         rnd_i,
  input  logic                               accumulate_i,
  input  logic [WIDTH-1:0]                   row_clk_gate_en_i,
  input  logic                               reg_enable_i,
  input  logic                               flush_i,
  output logic [WIDTH-1:0][HEIGHT-1:0][4:0]  status_o
);

  logic [WIDTH-1:0][HEIGHT-1:0][15:0] a_q;
  logic [WIDTH-1:0][HEIGHT-1:0][15:0] b_q;
  logic [WIDTH-1:0][HEIGHT-1:0][15:0] c_q;
  logic [WIDTH-1:0][HEIGHT-1:0][2:0]  rnd_q;

  logic [WIDTH-1:0][HEIGHT-1:0][15:0] addend_w;
  logic [WIDTH-1:0][HEIGHT-1:0][15:0] fma_z;
  logic [WIDTH-1:0][HEIGHT-1:0][4:0]  fma_status;

  // An operation is sampled into a_q/b_q/c_q at tick s.
  // result_q[...,2] then contains its value at tick s+3.
  logic [WIDTH-1:0][HEIGHT-1:0][2:0][15:0] result_q;

  // flag_q[...,1] contains the status of the operation sampled at s-2.
  logic [WIDTH-1:0][HEIGHT-1:0][1:0][4:0] flag_q;

  logic [WIDTH-1:0] flush_q;

  integer rr;
  integer kk;

  genvar gr;
  genvar gs;
  generate
    for (gr = 0; gr < WIDTH; gr = gr + 1) begin : g_rows
      assign z_o[gr] = result_q[gr][HEIGHT-1][2];

      for (gs = 0; gs < HEIGHT; gs = gs + 1) begin : g_stages
        if (gs == 0) begin : g_bias
          // Reading the registered output here supplies z_o from one
          // enabled tick earlier than stage 0's external operands.
          assign addend_w[gr][gs] =
              accumulate_i ? z_o[gr] : y_i[gr];
        end else begin : g_chain
          assign addend_w[gr][gs] = result_q[gr][gs-1][2];
        end

        fp16_gemm_array_fma u_fma (
          .a_i      (a_q[gr][gs]),
          .b_i      (b_q[gr][gs]),
          .c_i      (c_q[gr][gs]),
          .rnd_i    (rnd_q[gr][gs]),
          .z_o      (fma_z[gr][gs]),
          .status_o (fma_status[gr][gs])
        );

        assign status_o[gr][gs] = flag_q[gr][gs][1];
      end
    end
  endgenerate

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      a_q       <= '0;
      b_q       <= '0;
      c_q       <= '0;
      rnd_q     <= '0;
      result_q  <= '0;
      flag_q    <= '0;
      flush_q   <= '0;
    end else begin
      for (rr = 0; rr < WIDTH; rr = rr + 1) begin
        // flush overrides reg_enable, but never overrides the row clock gate.
        if (row_clk_gate_en_i[rr] && (reg_enable_i || flush_i)) begin
          if (flush_i) begin
            flush_q[rr] <= 1'b1;

            for (kk = 0; kk < HEIGHT; kk = kk + 1) begin
              a_q[rr][kk]      <= 16'd0;
              b_q[rr][kk]      <= 16'd0;
              c_q[rr][kk]      <= 16'd0;
              rnd_q[rr][kk]    <= 3'd0;
              result_q[rr][kk][0] <= 16'd0;
              result_q[rr][kk][1] <= 16'd0;
              result_q[rr][kk][2] <= 16'd0;

              // The first flushed tick updates status normally. Subsequent
              // flushed ticks leave both status registers untouched.
              if (!flush_q[rr]) begin
                flag_q[rr][kk][0] <= fma_status[rr][kk];
                flag_q[rr][kk][1] <= flag_q[rr][kk][0];
              end
            end
          end else begin
            flush_q[rr] <= 1'b0;

            for (kk = 0; kk < HEIGHT; kk = kk + 1) begin
              a_q[rr][kk]   <= x_i[rr][kk];
              b_q[rr][kk]   <= w_i[kk];
              c_q[rr][kk]   <= addend_w[rr][kk];
              rnd_q[rr][kk] <= rnd_i;

              result_q[rr][kk][0] <= fma_z[rr][kk];
              result_q[rr][kk][1] <= result_q[rr][kk][0];
              result_q[rr][kk][2] <= result_q[rr][kk][1];

              flag_q[rr][kk][0] <= fma_status[rr][kk];
              flag_q[rr][kk][1] <= flag_q[rr][kk][0];
            end
          end
        end
      end
    end
  end

endmodule
