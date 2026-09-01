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
        end else if (y_exp >= 9'd23) begin
            shifted_m = {1'b1, y_val[22:0]} << (y_exp - 9'd23);
        end else if (y_exp >= 0) begin
            shifted_m = {8'b0, 1'b1, y_val[22:0]} << y_exp;
        end else if (y_exp > -9'd24) begin
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
                            DataOut <= {1'b0, result_exp[7:0], h_acc[22:0]};
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