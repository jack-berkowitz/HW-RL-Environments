// =============================================================================
// softmax.sv  --  Fixed-Point Softmax Implementation
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

    // =========================================================================
    // STATE DEFINITION
    // =========================================================================
    typedef enum logic [2:0] {
        STATE_IDLE,
        STATE_MAX,
        STATE_EXP_SUM,
        STATE_DIVIDE,
        STATE_MULTIPLY,
        STATE_DONE
    } state_t;

    state_t state;

    // =========================================================================
    // LOOKUP TABLE FOR 2^F (F in [0, 1.0)) IN Q1.23 FORMAT
    // =========================================================================
    logic [24:0] exp2_lut [0:256];

    initial begin
        for (int i = 0; i <= 256; i++) begin
            exp2_lut[i] = $rtoi($pow(2.0, i / 256.0) * 8388608.0 + 0.5);
        end
    end

    // =========================================================================
    // INTERNAL REGISTERS & SIGNALS
    // =========================================================================
    logic signed [15:0] in_reg [0:NUM_ELEMENTS-1];
    logic signed [15:0] x_max;
    logic [3:0]         element_idx;

    logic [23:0]        E_reg [0:NUM_ELEMENTS-1];
    logic [27:0]        sum_E;

    // Division registers for computing reciprocal R = 2^55 / sum_E
    logic [28:0]        div_rem;
    logic [32:0]        R_reg;
    logic [5:0]         div_cnt;

    // Output holding register
    logic [NUM_ELEMENTS*OUT_W-1:0] out_vec_reg;
    assign out_vec = out_vec_reg;

    // =========================================================================
    // COMBINATIONAL LOGIC
    // =========================================================================

    // 1. Max Finder
    always_comb begin
        x_max = in_reg[0];
        for (int i = 1; i < NUM_ELEMENTS; i++) begin
            if (in_reg[i] > x_max) begin
                x_max = in_reg[i];
            end
        end
    end

    // 2. Exponential Calculation for current element_idx
    logic signed [31:0] y_ext;
    logic signed [63:0] K_full;
    logic [63:0]        neg_K;
    logic [27:0]        frac_bits;
    logic [7:0]         M;
    logic [27:0]        F_raw;
    logic [7:0]         lut_idx;
    logic [7:0]         frac_rem;
    logic [24:0]        val0, val1;
    logic [24:0]        slope;
    logic [24:0]        interpolated_2F;
    logic [23:0]        E_i;

    always_comb begin
        y_ext  = $signed(in_reg[element_idx]) - $signed(x_max); // y_ext <= 0
        K_full = y_ext * 32'sd94548;                           // Q7.28 (LOG2_E = 1.442695 in Q2.16)
        neg_K  = -K_full;                                      // >= 0

        frac_bits = neg_K[27:0];
        if (frac_bits == 28'd0) begin
            M     = neg_K[35:28];
            F_raw = 28'd0;
        end else begin
            M     = neg_K[35:28] + 8'd1;
            F_raw = 28'd268435456 - frac_bits;                 // 2^28 - frac_bits
        end

        lut_idx  = F_raw[27:20];
        frac_rem = F_raw[19:12];

        val0  = EXP2_LUT[lut_idx];
        val1  = EXP2_LUT[lut_idx + 1];
        slope = val1 - val0;

        interpolated_2F = val0 + ((slope * frac_rem) >> 8);

        if (M >= 8'd24) begin
            E_i = 24'd0;
        end else begin
            E_i = interpolated_2F[23:0] >> M;
        end
    end

    // 3. Output Scaling for current element_idx
    logic [56:0] prod;
    logic [16:0] val;
    logic [15:0] out_elem;

    always_comb begin
        prod     = 57'(E_reg[element_idx]) * 57'(R_reg);
        val      = (prod + 57'h40_0000_0000) >> 39; // Rounding (+ 2^38)
        out_elem = (val > 17'hFFFF) ? 16'hFFFF : val[15:0];
    end

    // =========================================================================
    // CONTROL & SEQUENTIAL FSM
    // =========================================================================
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            state       <= STATE_IDLE;
            busy        <= 1'b0;
            done        <= 1'b0;
            element_idx <= '0;
            sum_E       <= '0;
            div_rem     <= '0;
            R_reg       <= '0;
            div_cnt     <= '0;
            out_vec_reg <= '0;
            for (int i = 0; i < NUM_ELEMENTS; i++) begin
                in_reg[i] <= '0;
                E_reg[i]  <= '0;
            end
        end else begin
            case (state)
                STATE_IDLE: begin
                    done <= 1'b0;
                    if (start && !busy) begin
                        busy  <= 1'b1;
                        state <= STATE_MAX;
                        for (int i = 0; i < NUM_ELEMENTS; i++) begin
                            in_reg[i] <= in_vec[i*IN_W +: IN_W];
                        end
                    end
                end

                STATE_MAX: begin
                    element_idx <= '0;
                    sum_E       <= '0;
                    state       <= STATE_EXP_SUM;
                end

                STATE_EXP_SUM: begin
                    E_reg[element_idx] <= E_i;
                    sum_E              <= sum_E + E_i;

                    if (element_idx == NUM_ELEMENTS - 1) begin
                        state   <= STATE_DIVIDE;
                        div_rem <= 29'd8388608; // Initial remainder 2^23
                        div_cnt <= 6'd32;
                        R_reg   <= 33'd0;
                    end else begin
                        element_idx <= element_idx + 1'b1;
                    end
                end

                STATE_DIVIDE: begin
                    if (div_rem >= sum_E) begin
                        div_rem <= (div_rem - sum_E) << 1;
                        R_reg   <= {R_reg[31:0], 1'b1};
                    end else begin
                        div_rem <= div_rem << 1;
                        R_reg   <= {R_reg[31:0], 1'b0};
                    end

                    if (div_cnt == 6'd0) begin
                        state       <= STATE_MULTIPLY;
                        element_idx <= '0;
                    end else begin
                        div_cnt <= div_cnt - 1'b1;
                    end
                end

                STATE_MULTIPLY: begin
                    out_vec_reg[element_idx*OUT_W +: OUT_W] <= out_elem;

                    if (element_idx == NUM_ELEMENTS - 1) begin
                        state <= STATE_DONE;
                        done  <= 1'b1;
                    end else begin
                        element_idx <= element_idx + 1'b1;
                    end
                end

                STATE_DONE: begin
                    state <= STATE_IDLE;
                    busy  <= 1'b0;
                    done  <= 1'b0;
                end

                default: state <= STATE_IDLE;
            endcase
        end
    end

endmodule