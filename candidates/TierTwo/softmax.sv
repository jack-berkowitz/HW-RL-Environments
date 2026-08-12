// =============================================================================
// softmax.sv -- fixed-point Q4.12 -> Q0.16 softmax over NUM_ELEMENTS values.
//               Implements interfaces/TierTwo/softmax_iface.sv.
// =============================================================================
// The IEEE-754 datapath below (divider / exponential / multiplier / adder) is
// the user's, carried over unchanged apart from one bug fix marked EXP-FIX in
// `exponential`. The arithmetic microarchitecture is preserved exactly:
//   * exp via 2^(x*log2e): one float multiply, integer/fraction decomposition,
//     a 3-term Horner polynomial for 2^f, then exponent packing
//   * NUM_ELEMENTS exponential units and NUM_ELEMENTS dividers in PARALLEL,
//     with a single shared adder accumulating the sum serially -- the same
//     parallel-exp / serial-add / parallel-div split the original FSM used
//   * the same stb/ack handshake sequencing to drive those units
//
// What was replaced: the top-level FSM and ports. The original streamed one
// float per clock in and out with a `N` count and no busy/done, over at most 4
// elements. This contract is a parallel packed vector with a start/busy/done
// handshake, so the top level is new; the fixed<->float conversion at the
// boundary is new for the same reason.
// =============================================================================

`timescale 1ns/1ps

//IEEE Floating Point Divider (Single Precision)
module divider(
        input  logic        clk,
        input  logic        rst,
        input  logic [31:0] input_a,
        input  logic        input_a_stb,
        output logic        input_a_ack,
        input  logic [31:0] input_b,
        input  logic        input_b_stb,
        output logic        input_b_ack,
        output logic [31:0] output_z,
        output logic        output_z_stb,
        input  logic        output_z_ack);

  logic     s_output_z_stb;
  logic     s_input_a_ack;
  logic     s_input_b_ack;

  logic     [4:0] state;
  parameter get_a         = 5'd0,
            get_b         = 5'd1,
            unpack        = 5'd2,
            special_cases = 5'd3,
            normalise_a   = 5'd4,
            normalise_b   = 5'd5,
            nr_init       = 5'd6,
            nr_iter1_mul  = 5'd7,
            nr_iter1_sub  = 5'd8,
            nr_iter1_upd  = 5'd9,
            nr_iter2_mul  = 5'd10,
            nr_iter2_sub  = 5'd11,
            nr_iter2_upd  = 5'd12,
            nr_final      = 5'd13,
            nr_extract    = 5'd14,
            normalise_1   = 5'd15,
            normalise_2   = 5'd16,
            round         = 5'd17,
            pack          = 5'd18,
            put_z         = 5'd19;

  logic     [31:0] a, b, z;
  logic     [23:0] a_m, b_m, z_m;
  logic     [9:0] a_e, b_e, z_e;
  logic     a_s, b_s, z_s;
  logic     guard, round_bit, sticky;

  logic     [31:0] x;
  logic     [31:0] b_ext;
  logic     [31:0] a_ext;
  logic     [63:0] nr_prod;
  logic     [31:0] nr_e;

  function automatic [31:0] recip_lut;
    input [5:0] idx;
    case (idx)
      6'd0:  recip_lut = 32'h7F01FC08;
      6'd1:  recip_lut = 32'h7D119679;
      6'd2:  recip_lut = 32'h7B301ECC;
      6'd3:  recip_lut = 32'h795CEB24;
      6'd4:  recip_lut = 32'h77975B90;
      6'd5:  recip_lut = 32'h75DED953;
      6'd6:  recip_lut = 32'h7432D63E;
      6'd7:  recip_lut = 32'h7292CC15;
      6'd8:  recip_lut = 32'h70FE3C07;
      6'd9:  recip_lut = 32'h6F74AE26;
      6'd10: recip_lut = 32'h6DF5B0F7;
      6'd11: recip_lut = 32'h6C80D902;
      6'd12: recip_lut = 32'h6B15C06B;
      6'd13: recip_lut = 32'h69B4069B;
      6'd14: recip_lut = 32'h685B4FE6;
      6'd15: recip_lut = 32'h670B453C;
      6'd16: recip_lut = 32'h65C393E0;
      6'd17: recip_lut = 32'h6483ED27;
      6'd18: recip_lut = 32'h634C0635;
      6'd19: recip_lut = 32'h621B97C3;
      6'd20: recip_lut = 32'h60F25DEB;
      6'd21: recip_lut = 32'h5FD017F4;
      6'd22: recip_lut = 32'h5EB48824;
      6'd23: recip_lut = 32'h5D9F7391;
      6'd24: recip_lut = 32'h5C90A1FD;
      6'd25: recip_lut = 32'h5B87DDAD;
      6'd26: recip_lut = 32'h5A84F345;
      6'd27: recip_lut = 32'h5987B1A9;
      6'd28: recip_lut = 32'h588FE9DC;
      6'd29: recip_lut = 32'h579D6EE3;
      6'd30: recip_lut = 32'h56B015AC;
      6'd31: recip_lut = 32'h55C7B4F1;
      6'd32: recip_lut = 32'h54E42524;
      6'd33: recip_lut = 32'h54054054;
      6'd34: recip_lut = 32'h532AE21D;
      6'd35: recip_lut = 32'h5254E78F;
      6'd36: recip_lut = 32'h51832F20;
      6'd37: recip_lut = 32'h50B59897;
      6'd38: recip_lut = 32'h4FEC04FF;
      6'd39: recip_lut = 32'h4F265692;
      6'd40: recip_lut = 32'h4E6470B0;
      6'd41: recip_lut = 32'h4DA637CF;
      6'd42: recip_lut = 32'h4CEB916D;
      6'd43: recip_lut = 32'h4C346405;
      6'd44: recip_lut = 32'h4B809701;
      6'd45: recip_lut = 32'h4AD012B4;
      6'd46: recip_lut = 32'h4A22C04A;
      6'd47: recip_lut = 32'h497889C2;
      6'd48: recip_lut = 32'h48D159E2;
      6'd49: recip_lut = 32'h482D1C32;
      6'd50: recip_lut = 32'h478BBCED;
      6'd51: recip_lut = 32'h46ED2901;
      6'd52: recip_lut = 32'h46514E02;
      6'd53: recip_lut = 32'h45B81A25;
      6'd54: recip_lut = 32'h45217C38;
      6'd55: recip_lut = 32'h448D639D;
      6'd56: recip_lut = 32'h43FBC044;
      6'd57: recip_lut = 32'h436C82A2;
      6'd58: recip_lut = 32'h42DF9BB1;
      6'd59: recip_lut = 32'h4254FCE4;
      6'd60: recip_lut = 32'h41CC9829;
      6'd61: recip_lut = 32'h41465FDF;
      6'd62: recip_lut = 32'h40C246D4;
      6'd63: recip_lut = 32'h40404040;
    endcase
  endfunction

  always @(posedge clk)
  begin
    if (rst == 1) begin
      state <= get_a;
      s_input_a_ack <= 0;
      s_input_b_ack <= 0;
      s_output_z_stb <= 0;
      output_z <= 0;
      a <= 0;
      b <= 0;
      z <= 0;
      a_m <= 0;
      b_m <= 0;
      z_m <= 0;
      a_e <= 0;
      b_e <= 0;
    end
    else begin

    case(state)

      get_a:
      begin
        s_input_a_ack <= 1;
        if (s_input_a_ack && input_a_stb) begin
          a <= input_a;
          s_input_a_ack <= 0;
          state <= get_b;
        end
      end

      get_b:
      begin
        s_input_b_ack <= 1;
        if (s_input_b_ack && input_b_stb) begin
          b <= input_b;
          s_input_b_ack <= 0;
          state <= unpack;
        end
      end

      unpack:
      begin
        a_m <= a[22 : 0];
        b_m <= b[22 : 0];
        a_e <= a[30 : 23] - 127;
        b_e <= b[30 : 23] - 127;
        a_s <= a[31];
        b_s <= b[31];
        state <= special_cases;
      end

      special_cases:
      begin
        if ((a_e == 128 && a_m != 0) || (b_e == 128 && b_m != 0)) begin
          z[31] <= 1;
          z[30:23] <= 255;
          z[22] <= 1;
          z[21:0] <= 0;
          state <= put_z;
        end else if ((a_e == 128) && (b_e == 128)) begin
          z[31] <= 1;
          z[30:23] <= 255;
          z[22] <= 1;
          z[21:0] <= 0;
          state <= put_z;
        end else if (a_e == 128) begin
          z[31] <= a_s ^ b_s;
          z[30:23] <= 255;
          z[22:0] <= 0;
          state <= put_z;
          if ($signed(b_e == -127) && (b_m == 0)) begin
            z[31] <= 1;
            z[30:23] <= 255;
            z[22] <= 1;
            z[21:0] <= 0;
            state <= put_z;
          end
        end else if (b_e == 128) begin
          z[31] <= a_s ^ b_s;
          z[30:23] <= 0;
          z[22:0] <= 0;
          state <= put_z;
        end else if (($signed(a_e) == -127) && (a_m == 0)) begin
          z[31] <= a_s ^ b_s;
          z[30:23] <= 0;
          z[22:0] <= 0;
          state <= put_z;
          if (($signed(b_e) == -127) && (b_m == 0)) begin
            z[31] <= 1;
            z[30:23] <= 255;
            z[22] <= 1;
            z[21:0] <= 0;
            state <= put_z;
          end
        end else if (($signed(b_e) == -127) && (b_m == 0)) begin
          z[31] <= a_s ^ b_s;
          z[30:23] <= 255;
          z[22:0] <= 0;
          state <= put_z;
        end else begin
          if ($signed(a_e) == -127) begin
            a_e <= -126;
          end else begin
            a_m[23] <= 1;
          end
          if ($signed(b_e) == -127) begin
            b_e <= -126;
          end else begin
            b_m[23] <= 1;
          end
          state <= normalise_a;
        end
      end

      normalise_a:
      begin
        if (a_m[23]) begin
          state <= normalise_b;
        end else begin
          a_m <= a_m << 1;
          a_e <= a_e - 1;
        end
      end

      normalise_b:
      begin
        if (b_m[23]) begin
          state <= nr_init;
        end else begin
          b_m <= b_m << 1;
          b_e <= b_e - 1;
        end
      end

      nr_init:
      begin
        z_s   <= a_s ^ b_s;
        z_e   <= a_e - b_e;
        b_ext <= {b_m, 8'b0};
        a_ext <= {a_m, 8'b0};
        x     <= recip_lut(b_m[22:17]);
        state <= nr_iter1_mul;
      end

      nr_iter1_mul:
      begin
        nr_prod <= {32'b0, b_ext} * {32'b0, x};
        state <= nr_iter1_sub;
      end

      nr_iter1_sub:
      begin
        nr_e <= (64'h8000_0000_0000_0000 - nr_prod) >> 31;
        state <= nr_iter1_upd;
      end

      nr_iter1_upd:
      begin
        x <= ({32'b0, x} * {32'b0, nr_e}) >> 31;
        state <= nr_iter2_mul;
      end

      nr_iter2_mul:
      begin
        nr_prod <= {32'b0, b_ext} * {32'b0, x};
        state <= nr_iter2_sub;
      end

      nr_iter2_sub:
      begin
        nr_e <= (64'h8000_0000_0000_0000 - nr_prod) >> 31;
        state <= nr_iter2_upd;
      end

      nr_iter2_upd:
      begin
        x <= ({32'b0, x} * {32'b0, nr_e}) >> 31;
        state <= nr_final;
      end

      nr_final:
      begin
        nr_prod <= {32'b0, a_ext} * {32'b0, x};
        state <= nr_extract;
      end

      nr_extract:
      begin
        if (nr_prod[63]) begin
          z_m <= nr_prod[63:40];
          guard <= nr_prod[39];
          round_bit <= nr_prod[38];
          sticky <= |nr_prod[37:0];
          z_e <= z_e + 1;
        end else begin
          z_m <= nr_prod[62:39];
          guard <= nr_prod[38];
          round_bit <= nr_prod[37];
          sticky <= |nr_prod[36:0];
        end
        state <= normalise_1;
      end

      normalise_1:
      begin
        if (z_m[23] == 0 && $signed(z_e) > -126) begin
          z_e <= z_e - 1;
          z_m <= z_m << 1;
          z_m[0] <= guard;
          guard <= round_bit;
          round_bit <= 0;
        end else begin
          state <= normalise_2;
        end
      end

      normalise_2:
      begin
        if ($signed(z_e) < -126) begin
          z_e <= z_e + 1;
          z_m <= z_m >> 1;
          guard <= z_m[0];
          round_bit <= guard;
          sticky <= sticky | round_bit;
        end else begin
          state <= round;
        end
      end

      round:
      begin
        if (guard && (round_bit | sticky | z_m[0])) begin
          z_m <= z_m + 1;
          if (z_m == 24'hffffff) begin
            z_e <=z_e + 1;
          end
        end
        state <= pack;
      end

      pack:
      begin
        z[22 : 0] <= z_m[22:0];
        z[30 : 23] <= z_e[7:0] + 127;
        z[31] <= z_s;
        if ($signed(z_e) == -126 && z_m[23] == 0) begin
          z[30 : 23] <= 0;
        end
        if ($signed(z_e) > 127) begin
          z[22 : 0] <= 0;
          z[30 : 23] <= 255;
          z[31] <= z_s;
        end
        state <= put_z;
      end

      put_z:
      begin
        s_output_z_stb <= 1;
        output_z <= z;
        if (s_output_z_stb && output_z_ack) begin
          s_output_z_stb <= 0;
          state <= get_a;
        end
      end

    endcase

    end
  end
  always_comb begin
    input_a_ack = s_input_a_ack;
    input_b_ack = s_input_b_ack;
    output_z_stb = s_output_z_stb;
  end

endmodule

`timescale 1ns / 1ps

module exponential (
    input  logic        Clock,
    input  logic        Reset,
    input  logic        Str,
    input  logic [31:0] Datain,
    output logic        Ack,
    output logic [31:0] DataOut
);

    typedef enum logic [2:0] {
        S_IDLE      = 3'd0,
        S_START_MUL = 3'd1,
        S_MUL_WAIT  = 3'd2,
        S_DECOMPOSE = 3'd3,
        S_HORNER    = 3'd4,
        S_PACK      = 3'd5,
        S_DONE      = 3'd6
    } state_t;

    state_t state;

    localparam [31:0] LOG2E = 32'h3FB8AA3B;

    localparam [23:0] C0 = 24'h7FF9D6;
    localparam [23:0] C1 = 24'h593203;
    localparam [23:0] C2 = 24'h1CB02B;
    localparam [23:0] C3 = 24'h0A1D53;

    logic [31:0] mul_a, mul_b, mul_z;
    logic        mul_a_stb, mul_b_stb, mul_a_ack, mul_b_ack;
    logic        mul_z_stb, mul_z_ack;

    multiplier u_mul (
        .clk          (Clock),
        .rst          (Reset),
        .input_a      (mul_a),
        .input_a_stb  (mul_a_stb),
        .input_a_ack  (mul_a_ack),
        .input_b      (mul_b),
        .input_b_stb  (mul_b_stb),
        .input_b_ack  (mul_b_ack),
        .output_z     (mul_z),
        .output_z_stb (mul_z_stb),
        .output_z_ack (mul_z_ack)
    );

    logic [31:0]      y_val;
    logic signed [8:0] I_val;
    logic [22:0]      f_fixed;
    logic [23:0]      h_acc;
    logic [1:0]       h_step;

    logic [31:0]      shifted_m;
    logic signed [8:0] y_exp;
    logic [8:0]       i_magnitude;
    logic [22:0]      f_magnitude;
    logic             y_negative;
    logic             y_has_frac;
    logic signed [8:0] decomp_I;
    logic [22:0]      decomp_f;

    always_comb begin
        y_exp      = {1'b0, y_val[30:23]} - 9'd127;
        y_negative = y_val[31];
        shifted_m  = 32'd0;

        if (y_val[30:23] == 8'd0) begin
            shifted_m = 32'd0;
        // EXP-FIX: these bounds MUST be signed comparisons. `9'd23` and `9'd24`
        // are unsigned literals, which forced the whole compare unsigned -- so
        // any negative y_exp read as >= 256 and took the first branch, shifting
        // by a huge amount and zeroing shifted_m. Every |x| < ln(2) then
        // decomposed to I=0, f=0 and exp(x) collapsed to exactly 1.0.
        end else if (y_exp >= 9'sd23) begin
            shifted_m = {1'b1, y_val[22:0]} << (y_exp - 9'sd23);
        end else if (y_exp >= 0) begin
            shifted_m = {8'b0, 1'b1, y_val[22:0]} << y_exp;
        end else if (y_exp > -9'sd24) begin
            shifted_m = {8'b0, 1'b1, y_val[22:0]} >> (-y_exp);
        end else begin
            shifted_m = 32'd0;
        end

        i_magnitude = shifted_m[31:23];
        f_magnitude = shifted_m[22:0];
        y_has_frac  = (f_magnitude != 23'd0);

        if (!y_negative) begin
            decomp_I = {1'b0, i_magnitude[7:0]};
            decomp_f = f_magnitude;
        end else if (y_has_frac) begin
            decomp_I = -({1'b0, i_magnitude[7:0]} + 9'd1);
            decomp_f = (~f_magnitude) + 23'd1;
        end else begin
            decomp_I = -{1'b0, i_magnitude[7:0]};
            decomp_f = 23'd0;
        end
    end

    logic [47:0] h_product;
    logic [23:0] h_shifted;
    logic [23:0] h_coeff;
    logic [23:0] h_next;

    always_comb begin
        h_product = {1'b0, h_acc} * {2'b0, f_fixed};
        h_shifted = h_product[46:23];

        case (h_step)
            2'd0: h_coeff = C2;
            2'd1: h_coeff = C1;
            2'd2: h_coeff = C0;
            default: h_coeff = 24'd0;
        endcase

        h_next = h_shifted + h_coeff;
    end

    always_ff @(posedge Clock or posedge Reset) begin
        if (Reset) begin
            state     <= S_IDLE;
            Ack       <= 1'b0;
            DataOut   <= 32'd0;
            y_val     <= 32'd0;
            I_val     <= 9'd0;
            f_fixed   <= 23'd0;
            h_acc     <= 24'd0;
            h_step    <= 2'd0;
            mul_a     <= 32'd0;
            mul_b     <= 32'd0;
            mul_a_stb <= 1'b0;
            mul_b_stb <= 1'b0;
            mul_z_ack <= 1'b0;
        end else begin
            if (mul_a_stb && mul_a_ack) mul_a_stb <= 1'b0;
            if (mul_b_stb && mul_b_ack) mul_b_stb <= 1'b0;

            case (state)
                S_IDLE: begin
                    Ack <= 1'b0;
                    if (Str) begin
                        if (Datain[30:0] == 31'd0) begin
                            DataOut <= 32'h3F800000;
                            Ack     <= 1'b1;
                            state   <= S_DONE;
                        end else begin
                            state <= S_START_MUL;
                        end
                    end
                end

                S_START_MUL: begin
                    mul_a     <= Datain;
                    mul_b     <= LOG2E;
                    mul_a_stb <= 1'b1;
                    mul_b_stb <= 1'b1;
                    mul_z_ack <= 1'b1;
                    state     <= S_MUL_WAIT;
                end

                S_MUL_WAIT: begin
                    if (mul_z_stb) begin
                        y_val <= mul_z;
                        state <= S_DECOMPOSE;
                    end
                end

                S_DECOMPOSE: begin
                    I_val   <= decomp_I;
                    f_fixed <= decomp_f;
                    h_acc   <= C3;
                    h_step  <= 2'd0;
                    state   <= S_HORNER;
                end

                S_HORNER: begin
                    h_acc <= h_next;
                    if (h_step == 2'd2) begin
                        state <= S_PACK;
                    end else begin
                        h_step <= h_step + 2'd1;
                    end
                end

                S_PACK: begin
                    begin
                        logic signed [9:0] result_exp;
                        result_exp = 10'(I_val) + 10'd127;
                        if (result_exp <= 0) begin
                            DataOut <= 32'h00000000;
                        end else if (result_exp >= 10'd255) begin
                            DataOut <= 32'h7F800000;
                        end else begin
                            // EXP-FIX: h_acc holds 2^f scaled by 2^23, so it must
                            // carry an implicit leading 1 in bit 23 before its low
                            // 23 bits can be used as a mantissa. The polynomial's
                            // constant term C0 = 0x7FF9D6 is 554 counts BELOW 2^23,
                            // so for f < ~1e-4 the accumulator lands just short of
                            // 2^23, bit 23 is clear, and h_acc[22:0] is then read as
                            // a mantissa of ~0.99993 instead of ~0.0 -- an exp result
                            // very nearly 2x too large. Clamp to the implicit 1.0.
                            DataOut <= {1'b0, result_exp[7:0],
                                        h_acc[23] ? h_acc[22:0] : 23'd0};
                        end
                    end
                    Ack   <= 1'b1;
                    state <= S_DONE;
                end

                S_DONE: begin
                    if (!Str) begin
                        Ack   <= 1'b0;
                        state <= S_IDLE;
                    end
                end

                default: state <= S_IDLE;
            endcase
        end
    end

endmodule

//IEEE Floating Point Multiplier (Single Precision)
//Copyright (C) Jonathan P Dawson 2013
//2013-12-12
module multiplier(
        input  logic        clk,
        input  logic        rst,
        input  logic [31:0] input_a,
        input  logic        input_a_stb,
        output logic        input_a_ack,
        input  logic [31:0] input_b,
        input  logic        input_b_stb,
        output logic        input_b_ack,
        output logic [31:0] output_z,
        output logic        output_z_stb,
        input  logic        output_z_ack);

  logic     s_output_z_stb;
  logic     s_input_a_ack;
  logic     s_input_b_ack;

  logic     [3:0] state;
  parameter get_a         = 4'd0,
            get_b         = 4'd1,
            unpack        = 4'd2,
            special_cases = 4'd3,
            normalise_a   = 4'd4,
            normalise_b   = 4'd5,
            multiply_0    = 4'd6,
            multiply_1    = 4'd7,
            normalise_1   = 4'd8,
            normalise_2   = 4'd9,
            round         = 4'd10,
            pack          = 4'd11,
            put_z         = 4'd12;

  logic     [31:0] a, b, z;
  logic     [23:0] a_m, b_m, z_m;
  logic     [9:0] a_e, b_e, z_e;
  logic     a_s, b_s, z_s;
  logic     guard, round_bit, sticky;
  logic     [49:0] product;

  always @(posedge clk)
  begin

    case(state)

      get_a:
      begin
        s_input_a_ack <= 1;
        if (s_input_a_ack && input_a_stb) begin
          a <= input_a;
          s_input_a_ack <= 0;
          state <= get_b;
        end
      end

      get_b:
      begin
        s_input_b_ack <= 1;
        if (s_input_b_ack && input_b_stb) begin
          b <= input_b;
          s_input_b_ack <= 0;
          state <= unpack;
        end
      end

      unpack:
      begin
        a_m <= a[22 : 0];
        b_m <= b[22 : 0];
        a_e <= a[30 : 23] - 127;
        b_e <= b[30 : 23] - 127;
        a_s <= a[31];
        b_s <= b[31];
        state <= special_cases;
      end

      special_cases:
      begin
        if ((a_e == 128 && a_m != 0) || (b_e == 128 && b_m != 0)) begin
          z[31] <= 1;
          z[30:23] <= 255;
          z[22] <= 1;
          z[21:0] <= 0;
          state <= put_z;
        end else if (a_e == 128) begin
          z[31] <= a_s ^ b_s;
          z[30:23] <= 255;
          z[22:0] <= 0;
          if (($signed(b_e) == -127) && (b_m == 0)) begin
            z[31] <= 1;
            z[30:23] <= 255;
            z[22] <= 1;
            z[21:0] <= 0;
          end
          state <= put_z;
        end else if (b_e == 128) begin
          z[31] <= a_s ^ b_s;
          z[30:23] <= 255;
          z[22:0] <= 0;
          if (($signed(a_e) == -127) && (a_m == 0)) begin
            z[31] <= 1;
            z[30:23] <= 255;
            z[22] <= 1;
            z[21:0] <= 0;
          end
          state <= put_z;
        end else if (($signed(a_e) == -127) && (a_m == 0)) begin
          z[31] <= a_s ^ b_s;
          z[30:23] <= 0;
          z[22:0] <= 0;
          state <= put_z;
        end else if (($signed(b_e) == -127) && (b_m == 0)) begin
          z[31] <= a_s ^ b_s;
          z[30:23] <= 0;
          z[22:0] <= 0;
          state <= put_z;
        end else begin
          if ($signed(a_e) == -127) begin
            a_e <= -126;
          end else begin
            a_m[23] <= 1;
          end
          if ($signed(b_e) == -127) begin
            b_e <= -126;
          end else begin
            b_m[23] <= 1;
          end
          state <= normalise_a;
        end
      end

      normalise_a:
      begin
        if (a_m[23]) begin
          state <= normalise_b;
        end else begin
          a_m <= a_m << 1;
          a_e <= a_e - 1;
        end
      end

      normalise_b:
      begin
        if (b_m[23]) begin
          state <= multiply_0;
        end else begin
          b_m <= b_m << 1;
          b_e <= b_e - 1;
        end
      end

      multiply_0:
      begin
        z_s <= a_s ^ b_s;
        z_e <= a_e + b_e + 1;
        product <= a_m * b_m * 4;
        state <= multiply_1;
      end

      multiply_1:
      begin
        z_m <= product[49:26];
        guard <= product[25];
        round_bit <= product[24];
        sticky <= (product[23:0] != 0);
        state <= normalise_1;
      end

      normalise_1:
      begin
        if (z_m[23] == 0) begin
          z_e <= z_e - 1;
          z_m <= z_m << 1;
          z_m[0] <= guard;
          guard <= round_bit;
          round_bit <= 0;
        end else begin
          state <= normalise_2;
        end
      end

      normalise_2:
      begin
        if ($signed(z_e) < -126) begin
          z_e <= z_e + 1;
          z_m <= z_m >> 1;
          guard <= z_m[0];
          round_bit <= guard;
          sticky <= sticky | round_bit;
        end else begin
          state <= round;
        end
      end

      round:
      begin
        if (guard && (round_bit | sticky | z_m[0])) begin
          z_m <= z_m + 1;
          if (z_m == 24'hffffff) begin
            z_e <=z_e + 1;
          end
        end
        state <= pack;
      end

      pack:
      begin
        z[22 : 0] <= z_m[22:0];
        z[30 : 23] <= z_e[7:0] + 127;
        z[31] <= z_s;
        if ($signed(z_e) == -126 && z_m[23] == 0) begin
          z[30 : 23] <= 0;
        end
        if ($signed(z_e) > 127) begin
          z[22 : 0] <= 0;
          z[30 : 23] <= 255;
          z[31] <= z_s;
        end
        state <= put_z;
      end

      put_z:
      begin
        s_output_z_stb <= 1;
        output_z <= z;
        if (s_output_z_stb && output_z_ack) begin
          s_output_z_stb <= 0;
          state <= get_a;
        end
      end

    endcase

    if (rst == 1) begin
      state <= get_a;
      s_input_a_ack <= 0;
      s_input_b_ack <= 0;
      s_output_z_stb <= 0;
      output_z <= 0;
      a <= 0;
      b <= 0;
      z <= 0;
      a_m <= 0;
      b_m <= 0;
      z_m <= 0;
      a_e <= 0;
      b_e <= 0;
    end

  end
  always_comb begin
    input_a_ack = s_input_a_ack;
    input_b_ack = s_input_b_ack;
    output_z_stb = s_output_z_stb;
  end

endmodule

//IEEE Floating Point Adder (Single Precision)
//Copyright (C) Jonathan P Dawson 2013
//2013-12-12
`timescale 1ns/1ps
module adder(
        input  logic        clk,
        input  logic        rst,
        input  logic [31:0] input_a,
        input  logic        input_a_stb,
        output logic        input_a_ack,
        input  logic [31:0] input_b,
        input  logic        input_b_stb,
        output logic        input_b_ack,
        output logic [31:0] output_z,
        output logic        output_z_stb,
        input  logic        output_z_ack);

  logic     s_output_z_stb;
  logic     s_input_a_ack;
  logic     s_input_b_ack;

  logic     [3:0] state;
  parameter get_a         = 4'd0,
            get_b         = 4'd1,
            unpack        = 4'd2,
            special_cases = 4'd3,
            align         = 4'd4,
            add_0         = 4'd5,
            add_1         = 4'd6,
            normalise_1   = 4'd7,
            normalise_2   = 4'd8,
            round         = 4'd9,
            pack          = 4'd10,
            put_z         = 4'd11;

  logic     [31:0] a, b, z;
  logic     [26:0] a_m, b_m;
  logic     [23:0] z_m;
  logic     [9:0] a_e, b_e, z_e;
  logic     a_s, b_s, z_s;
  logic     guard, round_bit, sticky;
  logic     [27:0] sum;

  always @(posedge clk)
  begin
    if (rst == 1) begin
      state <= get_a;
      s_input_a_ack <= 0;
      s_input_b_ack <= 0;
      s_output_z_stb <= 0;
      output_z <= 0;
      a <= 0;
      b <= 0;
      z <= 0;
      a_m <= 0;
      b_m <= 0;
      z_m <= 0;
      a_e <= 0;
      b_e <= 0;
    end 
    else begin 

    case(state)

      get_a:
      begin
        s_input_a_ack <= 1;
        if (s_input_a_ack && input_a_stb) begin
          a <= input_a;
          s_input_a_ack <= 0;
          state <= get_b;
        end
      end

      get_b:
      begin
        s_input_b_ack <= 1;
        if (s_input_b_ack && input_b_stb) begin
          b <= input_b;
          s_input_b_ack <= 0;
          state <= unpack;
        end
      end

      unpack:
      begin
        a_m <= {a[22 : 0], 3'd0};
        b_m <= {b[22 : 0], 3'd0};
        a_e <= a[30 : 23] - 127;
        b_e <= b[30 : 23] - 127;
        a_s <= a[31];
        b_s <= b[31];
        state <= special_cases;
      end

      special_cases:
      begin
        if ((a_e == 128 && a_m != 0) || (b_e == 128 && b_m != 0)) begin
          z[31] <= 1;
          z[30:23] <= 255;
          z[22] <= 1;
          z[21:0] <= 0;
          state <= put_z;
        end else if (a_e == 128) begin
          z[31] <= a_s;
          z[30:23] <= 255;
          z[22:0] <= 0;
          if ((b_e == 128) && (a_s != b_s)) begin
              z[31] <= b_s;
              z[30:23] <= 255;
              z[22] <= 1;
              z[21:0] <= 0;
          end
          state <= put_z;
        end else if (b_e == 128) begin
          z[31] <= b_s;
          z[30:23] <= 255;
          z[22:0] <= 0;
          state <= put_z;
        end else if ((($signed(a_e) == -127) && (a_m == 0)) && (($signed(b_e) == -127) && (b_m == 0))) begin
          z[31] <= a_s & b_s;
          z[30:23] <= b_e[7:0] + 127;
          z[22:0] <= b_m[26:3];
          state <= put_z;
        end else if (($signed(a_e) == -127) && (a_m == 0)) begin
          z[31] <= b_s;
          z[30:23] <= b_e[7:0] + 127;
          z[22:0] <= b_m[26:3];
          state <= put_z;
        end else if (($signed(b_e) == -127) && (b_m == 0)) begin
          z[31] <= a_s;
          z[30:23] <= a_e[7:0] + 127;
          z[22:0] <= a_m[26:3];
          state <= put_z;
        end else begin
          if ($signed(a_e) == -127) begin
            a_e <= -126;
          end else begin
            a_m[26] <= 1;
          end
          if ($signed(b_e) == -127) begin
            b_e <= -126;
          end else begin
            b_m[26] <= 1;
          end
          state <= align;
        end
      end

      align:
      begin
        if ($signed(a_e) > $signed(b_e)) begin
          b_e <= b_e + 1;
          b_m <= b_m >> 1;
          b_m[0] <= b_m[0] | b_m[1];
        end else if ($signed(a_e) < $signed(b_e)) begin
          a_e <= a_e + 1;
          a_m <= a_m >> 1;
          a_m[0] <= a_m[0] | a_m[1];
        end else begin
          state <= add_0;
        end
      end

      add_0:
      begin
        z_e <= a_e;
        if (a_s == b_s) begin
          sum <= a_m + b_m;
          z_s <= a_s;
        end else begin
          if (a_m >= b_m) begin
            sum <= a_m - b_m;
            z_s <= a_s;
          end else begin
            sum <= b_m - a_m;
            z_s <= b_s;
          end
        end
        state <= add_1;
      end

      add_1:
      begin
        if (sum[27]) begin
          z_m <= sum[27:4];
          guard <= sum[3];
          round_bit <= sum[2];
          sticky <= sum[1] | sum[0];
          z_e <= z_e + 1;
        end else begin
          z_m <= sum[26:3];
          guard <= sum[2];
          round_bit <= sum[1];
          sticky <= sum[0];
        end
        state <= normalise_1;
      end

      normalise_1:
      begin
        if (z_m[23] == 0 && $signed(z_e) > -126) begin
          z_e <= z_e - 1;
          z_m <= z_m << 1;
          z_m[0] <= guard;
          guard <= round_bit;
          round_bit <= 0;
        end else begin
          state <= normalise_2;
        end
      end

      normalise_2:
      begin
        if ($signed(z_e) < -126) begin
          z_e <= z_e + 1;
          z_m <= z_m >> 1;
          guard <= z_m[0];
          round_bit <= guard;
          sticky <= sticky | round_bit;
        end else begin
          state <= round;
        end
      end

      round:
      begin
        if (guard && (round_bit | sticky | z_m[0])) begin
          z_m <= z_m + 1;
          if (z_m == 24'hffffff) begin
            z_e <=z_e + 1;
          end
        end
        state <= pack;
      end

      pack:
      begin
        z[22 : 0] <= z_m[22:0];
        z[30 : 23] <= z_e[7:0] + 127;
        z[31] <= z_s;
        if ($signed(z_e) == -126 && z_m[23] == 0) begin
          z[30 : 23] <= 0;
        end
        if ($signed(z_e) > 127) begin
          z[22 : 0] <= 0;
          z[30 : 23] <= 255;
          z[31] <= z_s;
        end
        state <= put_z;
      end

      put_z:
      begin
        s_output_z_stb <= 1;
        output_z <= z;
        if (s_output_z_stb && output_z_ack) begin
          s_output_z_stb <= 0;
          state <= get_a;
        end
      end

    endcase

    end
  end
  always_comb begin
    input_a_ack = s_input_a_ack;
    input_b_ack = s_input_b_ack;
    output_z_stb = s_output_z_stb;
  end

endmodule


// =============================================================================
// softmax -- the graded top level
// =============================================================================
module softmax #(
    parameter int NUM_ELEMENTS = 8,   // 4 / 8 / 16
    // derived -- do not override; these define the fixed-point formats
    parameter int IN_W         = 16,
    parameter int OUT_W        = 16,
    parameter int IN_FRAC      = 12,
    parameter int OUT_FRAC     = 16
) (
    input  logic                            clk,
    input  logic                            rst_n,

    input  logic                            start,
    input  logic [NUM_ELEMENTS*IN_W-1:0]    in_vec,   // signed Q4.12 per element

    output logic                            busy,
    output logic                            done,     // one-cycle pulse
    output logic [NUM_ELEMENTS*OUT_W-1:0]   out_vec   // unsigned Q0.16 per element
);

    localparam logic [31:0] F_ZERO = 32'h0000_0000;

    // -----------------------------------------------------------------------
    // boundary conversions
    // -----------------------------------------------------------------------
    // signed Q4.12 -> IEEE-754 single. Exact: a 16-bit fixed value always fits
    // in a 24-bit significand, so nothing is lost here.
    function automatic logic [31:0] q412_to_float(input logic [IN_W-1:0] x);
        logic               s;
        logic [IN_W-1:0]    mag;
        int                 p;
        logic signed [9:0]  e;
        logic [47:0]        sh;
        begin
            if (x == '0) return F_ZERO;
            s   = x[IN_W-1];
            mag = s ? (~x + 1'b1) : x;
            p = 0;
            for (int k = 0; k < IN_W; k++) if (mag[k]) p = k;
            e  = 10'(p) - 10'(IN_FRAC) + 10'sd127;
            sh = ({32'd0, mag} << (23 - p));
            q412_to_float = {s, e[7:0], sh[22:0]};
        end
    endfunction

    // IEEE-754 single -> unsigned Q0.16, round-to-nearest, saturating.
    // 1.0 is not representable in Q0.16 and must be emitted as 16'hFFFF.
    function automatic logic [OUT_W-1:0] float_to_q016(input logic [31:0] f);
        logic [7:0]  e;
        logic [23:0] m24;
        int          shift;
        logic [47:0] wide;
        logic [23:0] ip;
        begin
            e = f[30:23];
            if (f[31])          return '0;         // negative -> 0
            if (e == 8'd0)      return '0;         // zero / denormal -> 0
            if (e >= 8'd127)    return {OUT_W{1'b1}};   // >= 1.0 -> saturate
            m24   = {1'b1, f[22:0]};
            shift = 134 - int'(e);                 // 23 - (e - 127 + OUT_FRAC)
            if (shift >= 48) return '0;
            wide = ({24'd0, m24} << 24) >> shift;
            ip   = wide[47:24];
            if (ip >= 24'hFFFF) return {OUT_W{1'b1}};
            float_to_q016 = ip[OUT_W-1:0] + OUT_W'(wide[23]);
        end
    endfunction

    // -----------------------------------------------------------------------
    // state
    // -----------------------------------------------------------------------
    typedef enum logic [2:0] {
        ST_IDLE, ST_EXP, ST_EXP_CLR, ST_SUM, ST_DIV_A, ST_DIV_B, ST_DIV_W, ST_EMIT
    } state_t;

    state_t state;

    logic [31:0] xf  [0:NUM_ELEMENTS-1];   // inputs, as float
    logic [31:0] ef  [0:NUM_ELEMENTS-1];   // exp(x_i)
    logic [31:0] acc;                      // running sum
    logic [31:0] rst_sub;                  // (unused placeholder width guard)

    localparam int CW = (NUM_ELEMENTS > 1) ? $clog2(NUM_ELEMENTS) : 1;
    logic [CW:0] cidx;                     // which element the adder is folding

    logic sub_rst;
    assign sub_rst = ~rst_n;

    // ---- exponential units, one per element (parallel, as in the original) --
    logic [NUM_ELEMENTS-1:0] exp_str;
    logic [NUM_ELEMENTS-1:0] exp_ack;
    logic [31:0]             exp_out [0:NUM_ELEMENTS-1];

    genvar gi;
    generate
        for (gi = 0; gi < NUM_ELEMENTS; gi++) begin : gen_exp
            exponential u_exp (
                .Clock   (clk),
                .Reset   (sub_rst),
                .Str     (exp_str[gi]),
                .Datain  (xf[gi]),
                .Ack     (exp_ack[gi]),
                .DataOut (exp_out[gi])
            );
        end
    endgenerate

    // ---- one shared adder, folding the sum serially (as in the original) ----
    logic [31:0] add_a, add_b;
    logic        add_a_stb, add_b_stb, add_a_ack, add_b_ack;
    logic [31:0] add_z;
    logic        add_z_stb, add_z_ack;
    logic        add_a_sent, add_b_sent;

    adder u_add (
        .clk (clk), .rst (sub_rst),
        .input_a (add_a), .input_a_stb (add_a_stb), .input_a_ack (add_a_ack),
        .input_b (add_b), .input_b_stb (add_b_stb), .input_b_ack (add_b_ack),
        .output_z (add_z), .output_z_stb (add_z_stb), .output_z_ack (add_z_ack)
    );

    // ---- divider units, one per element (parallel, as in the original) ------
    logic                    div_a_stb, div_b_stb, div_z_ack;
    logic [NUM_ELEMENTS-1:0] div_a_ack, div_b_ack, div_z_stb;
    logic [31:0]             div_out [0:NUM_ELEMENTS-1];

    generate
        for (gi = 0; gi < NUM_ELEMENTS; gi++) begin : gen_div
            divider u_div (
                .clk (clk), .rst (sub_rst),
                .input_a (ef[gi]), .input_a_stb (div_a_stb), .input_a_ack (div_a_ack[gi]),
                .input_b (acc),    .input_b_stb (div_b_stb), .input_b_ack (div_b_ack[gi]),
                .output_z (div_out[gi]), .output_z_stb (div_z_stb[gi]),
                .output_z_ack (div_z_ack)
            );
        end
    endgenerate

    // =======================================================================
    // control
    // =======================================================================
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            state      <= ST_IDLE;
            busy       <= 1'b0;
            done       <= 1'b0;
            out_vec    <= '0;
            acc        <= F_ZERO;
            cidx       <= '0;
            exp_str    <= '0;
            add_a      <= F_ZERO; add_b <= F_ZERO;
            add_a_stb  <= 1'b0;   add_b_stb <= 1'b0; add_z_ack <= 1'b0;
            add_a_sent <= 1'b0;   add_b_sent <= 1'b0;
            div_a_stb  <= 1'b0;   div_b_stb <= 1'b0; div_z_ack <= 1'b0;
            rst_sub    <= '0;
            for (int i = 0; i < NUM_ELEMENTS; i++) begin
                xf[i] <= F_ZERO;
                ef[i] <= F_ZERO;
            end
        end else begin
            done <= 1'b0;

            case (state)
                // ---------------------------------------------------------
                ST_IDLE: begin
                    busy <= 1'b0;
                    // start asserted while busy is ignored: busy is 0 here
                    if (start) begin
                        for (int i = 0; i < NUM_ELEMENTS; i++)
                            xf[i] <= q412_to_float(in_vec[i*IN_W +: IN_W]);
                        busy    <= 1'b1;
                        exp_str <= '1;
                        state   <= ST_EXP;
                    end
                end

                // ---------------------------------------------------------
                ST_EXP: begin
                    if (&exp_ack) begin
                        for (int i = 0; i < NUM_ELEMENTS; i++)
                            ef[i] <= exp_out[i];
                        exp_str <= '0;
                        state   <= ST_EXP_CLR;
                    end
                end

                // let the exponential units fall back to idle before reuse
                ST_EXP_CLR: begin
                    acc        <= F_ZERO;
                    cidx       <= '0;
                    add_a_sent <= 1'b0;
                    add_b_sent <= 1'b0;
                    add_z_ack  <= 1'b1;
                    state      <= ST_SUM;
                end

                // ---------------------------------------------------------
                // fold ef[0..N-1] into acc with the single shared adder
                ST_SUM: begin
                    if (!add_a_sent) begin
                        add_a     <= ef[cidx];
                        add_a_stb <= 1'b1;
                        if (add_a_stb && add_a_ack) begin
                            add_a_stb  <= 1'b0;
                            add_a_sent <= 1'b1;
                        end
                    end
                    if (!add_b_sent) begin
                        add_b     <= acc;
                        add_b_stb <= 1'b1;
                        if (add_b_stb && add_b_ack) begin
                            add_b_stb  <= 1'b0;
                            add_b_sent <= 1'b1;
                        end
                    end
                    if (add_z_stb) begin
                        acc        <= add_z;
                        add_a_sent <= 1'b0;
                        add_b_sent <= 1'b0;
                        if (cidx == CW'(NUM_ELEMENTS-1)) begin
                            add_z_ack <= 1'b0;
                            div_a_stb <= 1'b1;
                            state     <= ST_DIV_A;
                        end else begin
                            cidx <= cidx + 1'b1;
                        end
                    end
                end

                // ---------------------------------------------------------
                // every divider takes ef[i] / acc, in lockstep
                ST_DIV_A: begin
                    if (&div_a_ack) begin
                        div_a_stb <= 1'b0;
                        div_b_stb <= 1'b1;
                        state     <= ST_DIV_B;
                    end
                end

                ST_DIV_B: begin
                    if (&div_b_ack) begin
                        div_b_stb <= 1'b0;
                        state     <= ST_DIV_W;
                    end
                end

                // all dividers park in put_z until the slowest finishes, which
                // is what keeps them in lockstep for the next transaction
                ST_DIV_W: begin
                    if (&div_z_stb) begin
                        for (int i = 0; i < NUM_ELEMENTS; i++)
                            out_vec[i*OUT_W +: OUT_W] <= float_to_q016(div_out[i]);
                        div_z_ack <= 1'b1;
                        done      <= 1'b1;
                        state     <= ST_EMIT;
                    end
                end

                // done was high for exactly one cycle; drop busy so a new
                // start may be accepted next cycle
                ST_EMIT: begin
                    div_z_ack <= 1'b0;
                    busy      <= 1'b0;
                    state     <= ST_IDLE;
                end

                default: state <= ST_IDLE;
            endcase
        end
    end

endmodule
