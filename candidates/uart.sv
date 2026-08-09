// =============================================================================
// uart.sv -- full-duplex UART, independent transmitter and receiver, one clock.
// Implements the interface and semantics of interfaces/uart_iface.sv exactly.
// =============================================================================
//
// Both halves are the same shape: a free-running modulo-BIT_CYCLES cycle
// counter plus a bit counter, driven off one shift register.
//
// TX: the whole frame (start, data LSB-first, optional parity, stop bits) is
//     built combinationally from tx_data and loaded at the accepting edge, so
//     tx_data need not stay stable. tx_serial is a register that changes only
//     on bit boundaries, which is what makes every clk cycle of every bit
//     period identical. tx_start is only examined while tx_busy==0, so
//     start-while-busy is ignored structurally.
//
// RX: IDLE watches for a 1->0 transition on rx_serial (rx_prev holds the
//     previous sample). That is only a CANDIDATE start: state START waits
//     BIT_CYCLES/2 cycles and re-samples. High there means glitch -> abort back
//     to IDLE with no rx_valid. Low there anchors the bit grid, and every
//     following bit is sampled BIT_CYCLES later, i.e. at its own midpoint.
//     rx_valid pulses for one cycle at the last stop bit's midpoint -- after
//     every stop bit has been examined -- for every frame that gets that far,
//     errored or not.
// =============================================================================

module uart #(
    parameter int CLK_FREQ_HZ = 16_000_000,
    parameter int BAUD_RATE   = 1_000_000,
    parameter int DATA_BITS   = 8,   // 7 or 8
    parameter int PARITY      = 0,   // 0 = none, 1 = even, 2 = odd
    parameter int STOP_BITS   = 1,   // 1 or 2
    // derived -- do not override
    parameter int BIT_CYCLES  = CLK_FREQ_HZ / BAUD_RATE
) (
    input  logic                 clk,
    input  logic                 rst_n,

    // ---- transmitter ----
    input  logic                 tx_start,
    input  logic [DATA_BITS-1:0] tx_data,
    output logic                 tx_busy,
    output logic                 tx_serial,

    // ---- receiver ----
    input  logic                 rx_serial,
    output logic [DATA_BITS-1:0] rx_data,
    output logic                 rx_valid,       // one-cycle pulse
    output logic                 rx_frame_err,
    output logic                 rx_parity_err
);

    localparam int HAS_PARITY = (PARITY != 0) ? 1 : 0;
    localparam int FRAME_BITS = 1 + DATA_BITS + HAS_PARITY + STOP_BITS;
    localparam int PARITY_IDX = 1 + DATA_BITS;               // within the frame
    localparam int STOP_IDX   = 1 + DATA_BITS + HAS_PARITY;  // first stop bit

    // post-start bits the receiver has to collect: data + parity + stop
    localparam int NPOST     = DATA_BITS + HAS_PARITY + STOP_BITS;
    localparam int RSTOP_IDX = DATA_BITS + HAS_PARITY;       // within NPOST

    localparam int CYC_W  = $clog2(BIT_CYCLES);
    localparam int TXB_W  = $clog2(FRAME_BITS);
    localparam int RXB_W  = $clog2(NPOST);
    localparam int HALF   = BIT_CYCLES / 2;

    // =====================================================================
    // TRANSMITTER
    // =====================================================================
    logic [FRAME_BITS-1:0] tx_frame;   // combinational, bit 0 = start bit
    logic [FRAME_BITS-1:0] tx_shift;
    logic [CYC_W-1:0]      tx_cyc;
    logic [TXB_W-1:0]      tx_bit;

    always_comb begin
        tx_frame    = '1;              // stop bits (and unused MSBs) idle high
        tx_frame[0] = 1'b0;            // start bit
        for (int i = 0; i < DATA_BITS; i++)
            tx_frame[1+i] = tx_data[i];               // LSB first
        if (HAS_PARITY != 0)
            tx_frame[PARITY_IDX] = (PARITY == 1) ? (^tx_data) : ~(^tx_data);
    end

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            tx_busy   <= 1'b0;
            tx_serial <= 1'b1;
            tx_cyc    <= '0;
            tx_bit    <= '0;
        end else if (!tx_busy) begin
            tx_serial <= 1'b1;
            if (tx_start) begin
                tx_busy   <= 1'b1;
                tx_cyc    <= '0;
                tx_bit    <= '0;
                tx_shift  <= tx_frame;
                tx_serial <= tx_frame[0];    // start bit begins immediately
            end
        end else if (tx_cyc == CYC_W'(BIT_CYCLES-1)) begin
            tx_cyc <= '0;
            if (tx_bit == TXB_W'(FRAME_BITS-1)) begin
                tx_busy   <= 1'b0;           // frame complete, back to idle
                tx_serial <= 1'b1;
            end else begin
                tx_bit    <= tx_bit + TXB_W'(1);
                tx_shift  <= {1'b1, tx_shift[FRAME_BITS-1:1]};
                tx_serial <= tx_shift[1];
            end
        end else begin
            tx_cyc <= tx_cyc + CYC_W'(1);
        end
    end

    // =====================================================================
    // RECEIVER
    // =====================================================================
    localparam logic [1:0] RX_IDLE  = 2'd0;
    localparam logic [1:0] RX_START = 2'd1;
    localparam logic [1:0] RX_DATA  = 2'd2;

    logic [1:0]        rx_state;
    logic              rx_prev;
    logic [CYC_W-1:0]  rx_cyc;
    logic [RXB_W-1:0]  rx_bit;
    logic [NPOST-1:0]  rx_bits, rx_bits_nxt;

    // the sampled bit enters at the top; after NPOST samples, sample i sits at
    // position i, so rx_bits[DATA_BITS-1:0] is the payload, LSB first
    assign rx_bits_nxt = {rx_serial, rx_bits[NPOST-1:1]};

    logic rx_ferr_nxt, rx_perr_nxt;

    always_comb begin
        rx_ferr_nxt = ~(&rx_bits_nxt[RSTOP_IDX +: STOP_BITS]);
        if (HAS_PARITY != 0)
            rx_perr_nxt = (rx_bits_nxt[DATA_BITS] !=
                           ((PARITY == 1) ? (^rx_bits_nxt[DATA_BITS-1:0])
                                          : ~(^rx_bits_nxt[DATA_BITS-1:0])));
        else
            rx_perr_nxt = 1'b0;
    end

    always_ff @(posedge clk) begin
        rx_prev <= rx_serial;   // no reset: this only tracks the line

        if (!rst_n) begin
            rx_state      <= RX_IDLE;
            rx_valid      <= 1'b0;
            rx_cyc        <= '0;
            rx_bit        <= '0;
            rx_data       <= '0;
            rx_frame_err  <= 1'b0;
            rx_parity_err <= 1'b0;
        end else begin
            rx_valid <= 1'b0;   // one-cycle pulse by default

            case (rx_state)
                RX_IDLE: begin
                    if (rx_prev && !rx_serial) begin   // candidate start bit
                        rx_state <= RX_START;
                        rx_cyc   <= '0;
                    end
                end

                RX_START: begin
                    if (rx_cyc == CYC_W'(HALF-1)) begin
                        // midpoint of the start bit: still low means a real
                        // frame, high means the candidate was a glitch
                        if (rx_serial) begin
                            rx_state <= RX_IDLE;
                        end else begin
                            rx_state <= RX_DATA;
                            rx_cyc   <= '0;
                            rx_bit   <= '0;
                        end
                    end else begin
                        rx_cyc <= rx_cyc + CYC_W'(1);
                    end
                end

                RX_DATA: begin
                    if (rx_cyc == CYC_W'(BIT_CYCLES-1)) begin
                        rx_cyc  <= '0;
                        rx_bits <= rx_bits_nxt;
                        if (rx_bit == RXB_W'(NPOST-1)) begin
                            // last stop bit sampled -- report the frame
                            rx_state      <= RX_IDLE;
                            rx_valid      <= 1'b1;
                            rx_data       <= rx_bits_nxt[DATA_BITS-1:0];
                            rx_frame_err  <= rx_ferr_nxt;
                            rx_parity_err <= rx_perr_nxt;
                        end else begin
                            rx_bit <= rx_bit + RXB_W'(1);
                        end
                    end else begin
                        rx_cyc <= rx_cyc + CYC_W'(1);
                    end
                end

                default: rx_state <= RX_IDLE;
            endcase
        end
    end

endmodule
