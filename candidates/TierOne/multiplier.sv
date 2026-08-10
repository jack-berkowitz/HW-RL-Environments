// =============================================================================
// multiplier.sv -- integer multiplier with a start/done handshake.
// Implements the interface and semantics of interfaces/multiplier_iface.sv.
// =============================================================================
//
// Structure: a single combinational full-width multiply whose result is
// registered at the accepting edge, i.e. latency L == 1 (legal: the contract
// only requires 1 <= L <= 4*BIT_WIDTH + 8). That makes the operand "capture"
// requirement fall out for free -- product is sampled from a and b at exactly
// the accepting edge, so later scrambling of the inputs cannot disturb it.
//
// Signedness is handled by widening both operands to BIT_WIDTH+1 bits (sign-
// extend when SIGNED_MODE==1, zero-extend otherwise) and doing one signed
// multiply. The extra bit is what makes the most-negative operand behave:
// min * min and min * -1 both stay positive rather than wrapping.
//
// Handshake: busy is the whole state machine. start is only looked at while
// busy==0, so start-while-busy is ignored structurally.
// =============================================================================

module multiplier #(
    parameter int BIT_WIDTH   = 16,  // 8 / 16 / 32
    parameter int SIGNED_MODE = 1,   // 0 = unsigned, 1 = signed
    // derived -- do not override
    parameter int PROD_W      = 2*BIT_WIDTH
) (
    input  logic                 clk,
    input  logic                 rst_n,

    input  logic                 start,
    input  logic [BIT_WIDTH-1:0] a,
    input  logic [BIT_WIDTH-1:0] b,

    output logic                 busy,
    output logic                 done,     // one-cycle pulse
    output logic [PROD_W-1:0]    product
);

    localparam int EXT_W = BIT_WIDTH + 1;

    // ---------------------------------------------------------------------
    // combinational exact product
    // ---------------------------------------------------------------------
    logic signed [EXT_W-1:0]   a_ext, b_ext;
    logic signed [2*EXT_W-1:0] prod_full;

    assign a_ext = (SIGNED_MODE != 0) ? $signed({a[BIT_WIDTH-1], a})
                                      : $signed({1'b0,           a});
    assign b_ext = (SIGNED_MODE != 0) ? $signed({b[BIT_WIDTH-1], b})
                                      : $signed({1'b0,           b});

    assign prod_full = a_ext * b_ext;

    // ---------------------------------------------------------------------
    // handshake + result register -- synchronous active-low reset
    // ---------------------------------------------------------------------
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            busy <= 1'b0;
            done <= 1'b0;
        end else if (!busy) begin
            // idle: accept a transaction and finish it in this same edge
            done <= start;
            busy <= start;
            if (start)
                product <= prod_full[PROD_W-1:0];
        end else begin
            // the done cycle -- return to idle, product holds
            busy <= 1'b0;
            done <= 1'b0;
        end
    end

endmodule
