// =============================================================================
// softmax.sv -- fixed-point softmax over NUM_ELEMENTS values.
// Implements the interface and semantics of interfaces/softmax_iface.sv.
// =============================================================================
//
// out[i] = exp(in[i] - m) / sum_j exp(in[j] - m),  m = max_j in[j]
//
// Subtracting the maximum first is what makes this work in fixed point at all:
// every exponent argument is <= 0, so every exp() lands in (0, 1] and the
// largest element is exactly 1.0. It also makes shift invariance (A5) exact
// rather than approximate -- a constant added to every input cancels in
// (in[i] - m) before anything lossy happens, so a shifted vector produces a
// bit-identical result.
//
// EXPONENTIAL
//   exp(-t) is evaluated as 2^-(t*log2(e)). The product u = t * LOG2E splits
//   into an integer part k (a right shift) and a fraction f, and 2^-f -- which
//   only ever spans [0.5, 1] -- comes from a 32-segment piecewise-linear table.
//   Each entry stores the segment's left value and its drop to the next entry,
//   so one table read and one small multiply cover the interpolation.
//   Measured worst per-element error over the tolerance-relevant input space is
//   ~11 LSB against tolerance A1 = 656 LSB.
//
// NORMALISATION
//   The reciprocal R = floor(2^32 / S) is computed once by restoring division
//   (17 iterations), then each output is e[i]*R >> 16. Dividing by the ACTUAL
//   computed sum rather than an idealised one is what keeps A2 tight: the
//   outputs sum to 1.0 up to rounding regardless of how good exp() was.
//   The one clamp needed is p == 1.0, which is not representable in Q0.16 and
//   is emitted as 16'hFFFF.
//
// SEQUENCING
//   One shared datapath walks the vector: N cycles to find the max, 2N to
//   build the exponentials (split across two cycles per element to keep the
//   multiplier off the same path as the table), 17 to invert the sum, N to
//   scale. Latency L = 4*NUM_ELEMENTS + 18, inside the 64*NUM_ELEMENTS + 64
//   bound for every legal NUM_ELEMENTS. start is only examined while idle, so
//   start-while-busy is ignored structurally.
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

    localparam int IDX_W = $clog2(NUM_ELEMENTS);
    localparam int SUM_W = 17 + IDX_W;          // N * 2^16 fits in 17+log2(N) bits

    // log2(e) in Q0.12. The exponent conversion tolerates far more error than
    // this; 12 fractional bits keeps the multiplier small.
    localparam logic [12:0] LOG2E_Q12 = 13'd5909;

    // ---------------------------------------------------------------------
    // state
    // ---------------------------------------------------------------------
    localparam logic [2:0] S_IDLE  = 3'd0,
                           S_MAX   = 3'd1,
                           S_EXP1  = 3'd2,
                           S_EXP2  = 3'd3,
                           S_RECIP = 3'd4,
                           S_SCALE = 3'd5,
                           S_DONE  = 3'd6;

    logic [2:0]              state;
    logic [IDX_W-1:0]        idx;
    logic [4:0]              bitcnt;

    logic signed [IN_W-1:0]  xs   [NUM_ELEMENTS];   // captured inputs
    logic [OUT_W-1:0]        outs [NUM_ELEMENTS];   // results
    logic [16:0]             evals[NUM_ELEMENTS];   // exp values, units of 2^-16

    logic signed [IN_W-1:0]  maxv;
    logic [28:0]             uval;                  // t*LOG2E, Q5.24
    logic [SUM_W-1:0]        sum;
    logic [16:0]             recip;                 // floor(2^32 / sum)
    logic [SUM_W:0]          rem;                   // restoring-division remainder

    // ---------------------------------------------------------------------
    // 2^-f piecewise-linear table: 32 segments over f in [0,1).
    // entry = { value at the segment's left edge (Q1.16), drop to the next }
    // ---------------------------------------------------------------------
    function automatic logic [27:0] exp_seg(input logic [4:0] s);
        case (s)
            5'd0 : exp_seg = {17'd65536, 11'd1404};
            5'd1 : exp_seg = {17'd64132, 11'd1375};
            5'd2 : exp_seg = {17'd62757, 11'd1344};
            5'd3 : exp_seg = {17'd61413, 11'd1316};
            5'd4 : exp_seg = {17'd60097, 11'd1288};
            5'd5 : exp_seg = {17'd58809, 11'd1260};
            5'd6 : exp_seg = {17'd57549, 11'd1233};
            5'd7 : exp_seg = {17'd56316, 11'd1207};
            5'd8 : exp_seg = {17'd55109, 11'd1181};
            5'd9 : exp_seg = {17'd53928, 11'd1155};
            5'd10: exp_seg = {17'd52773, 11'd1131};
            5'd11: exp_seg = {17'd51642, 11'd1107};
            5'd12: exp_seg = {17'd50535, 11'd1083};
            5'd13: exp_seg = {17'd49452, 11'd1059};
            5'd14: exp_seg = {17'd48393, 11'd1037};
            5'd15: exp_seg = {17'd47356, 11'd1015};
            5'd16: exp_seg = {17'd46341, 11'd993};
            5'd17: exp_seg = {17'd45348, 11'd972};
            5'd18: exp_seg = {17'd44376, 11'd951};
            5'd19: exp_seg = {17'd43425, 11'd930};
            5'd20: exp_seg = {17'd42495, 11'd911};
            5'd21: exp_seg = {17'd41584, 11'd891};
            5'd22: exp_seg = {17'd40693, 11'd872};
            5'd23: exp_seg = {17'd39821, 11'd853};
            5'd24: exp_seg = {17'd38968, 11'd835};
            5'd25: exp_seg = {17'd38133, 11'd817};
            5'd26: exp_seg = {17'd37316, 11'd800};
            5'd27: exp_seg = {17'd36516, 11'd782};
            5'd28: exp_seg = {17'd35734, 11'd766};
            5'd29: exp_seg = {17'd34968, 11'd749};
            5'd30: exp_seg = {17'd34219, 11'd733};
            5'd31: exp_seg = {17'd33486, 11'd718};
            default: exp_seg = {17'd65536, 11'd1404};
        endcase
    endfunction

    // ---------------------------------------------------------------------
    // combinational datapath slices, one per FSM state
    // ---------------------------------------------------------------------

    // S_EXP1 : t = maxv - xs[idx]  (always >= 0, fits unsigned in IN_W bits)
    logic [IN_W-1:0] tdiff;
    assign tdiff = IN_W'(maxv - xs[idx]);

    // S_EXP1 : the exponent-base conversion multiply, t * log2(e)
    logic [28:0] uval_nxt;
    assign uval_nxt = tdiff * LOG2E_Q12;      // 16 x 13 -> 29 bits

    // S_EXP2 : split u into 2^-k and the interpolated 2^-f
    logic [4:0]  k_int, f_seg;
    logic [7:0]  f_frac;
    logic [27:0] seg;
    logic [16:0] e_base, e_frac;
    logic [10:0] e_drop;
    logic [18:0] e_interp;

    assign k_int    = uval[28:24];
    assign f_seg    = uval[23:19];
    assign f_frac   = uval[18:11];
    assign seg      = exp_seg(f_seg);
    assign e_base   = seg[27:11];
    assign e_drop   = seg[10:0];
    assign e_interp = e_drop * f_frac;        // 11 x 8 -> 19 bits
    assign e_frac   = e_base - 17'(e_interp >> 8);
    // k >= 17 shifts everything out on its own -- no explicit clamp needed
    logic [16:0] e_val;
    assign e_val = e_frac >> k_int;

    // S_RECIP : one restoring-division step
    logic [SUM_W:0] rem_shift, rem_sub;
    logic           rem_ge;
    assign rem_shift = {rem[SUM_W-1:0], 1'b0};
    assign rem_ge    = (rem_shift >= {1'b0, sum});
    assign rem_sub   = rem_shift - {1'b0, sum};

    // S_SCALE : e[idx] * R >> 16, rounded, saturated at 16'hFFFF
    logic [33:0] scaled, scaled_up;
    logic [17:0] scaled_rnd;
    assign scaled     = evals[idx] * recip;   // 17 x 17 -> 34 bits
    assign scaled_up  = scaled + 34'd32768;   // round-to-nearest
    assign scaled_rnd = scaled_up[33:16];

    // ---------------------------------------------------------------------
    // output packing
    // ---------------------------------------------------------------------
    always_comb begin
        for (int i = 0; i < NUM_ELEMENTS; i++)
            out_vec[i*OUT_W +: OUT_W] = outs[i];
    end

    // ---------------------------------------------------------------------
    // control + datapath registers -- synchronous active-low reset
    // ---------------------------------------------------------------------
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            state <= S_IDLE;
            busy  <= 1'b0;
            done  <= 1'b0;
        end else begin
            case (state)
                S_IDLE: begin
                    done <= 1'b0;
                    if (start) begin
                        for (int i = 0; i < NUM_ELEMENTS; i++)
                            xs[i] <= $signed(in_vec[i*IN_W +: IN_W]);
                        busy  <= 1'b1;
                        idx   <= '0;
                        sum   <= '0;
                        state <= S_MAX;
                    end
                end

                // running maximum, one element per cycle
                S_MAX: begin
                    if (idx == '0 || $signed(xs[idx]) > maxv)
                        maxv <= xs[idx];
                    if (idx == IDX_W'(NUM_ELEMENTS-1)) begin
                        idx   <= '0;
                        state <= S_EXP1;
                    end else begin
                        idx <= idx + IDX_W'(1);
                    end
                end

                // exponent conversion (the multiply gets a cycle of its own)
                S_EXP1: begin
                    uval  <= uval_nxt;
                    state <= S_EXP2;
                end

                // table lookup + interpolation + accumulate
                S_EXP2: begin
                    evals[idx] <= e_val;
                    sum        <= sum + SUM_W'(e_val);
                    if (idx == IDX_W'(NUM_ELEMENTS-1)) begin
                        idx    <= '0;
                        // dividend is 2^32; its top SUM_W bits seed the remainder
                        rem    <= (SUM_W+1)'(32768);
                        bitcnt <= 5'd16;
                        state  <= S_RECIP;
                    end else begin
                        idx   <= idx + IDX_W'(1);
                        state <= S_EXP1;
                    end
                end

                // restoring division: 17 quotient bits of 2^32 / sum
                S_RECIP: begin
                    rem   <= rem_ge ? rem_sub : rem_shift;
                    recip <= {recip[15:0], rem_ge};   // MSB-first quotient
                    if (bitcnt == 5'd0) begin
                        idx   <= '0;
                        state <= S_SCALE;
                    end else begin
                        bitcnt <= bitcnt - 5'd1;
                    end
                end

                // scale each exponential by the reciprocal
                S_SCALE: begin
                    outs[idx] <= (scaled_rnd > 18'd65535) ? 16'hFFFF
                                                          : OUT_W'(scaled_rnd);
                    if (idx == IDX_W'(NUM_ELEMENTS-1)) begin
                        done  <= 1'b1;
                        state <= S_DONE;
                    end else begin
                        idx <= idx + IDX_W'(1);
                    end
                end

                // the single done cycle; busy is still high here
                S_DONE: begin
                    done  <= 1'b0;
                    busy  <= 1'b0;
                    state <= S_IDLE;
                end

                default: state <= S_IDLE;
            endcase
        end
    end

endmodule
