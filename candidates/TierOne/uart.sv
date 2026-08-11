module uart #(
    parameter int CLK_FREQ_HZ = 16_000_000,
    parameter int BAUD_RATE   = 1_000_000,
    parameter int DATA_BITS   = 8,
    parameter int PARITY      = 0,
    parameter int STOP_BITS   = 1,
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
    output logic                 rx_valid,
    output logic                 rx_frame_err,
    output logic                 rx_parity_err
);

    // -------------------------------------------------------------------------
    // Derived constants
    // -------------------------------------------------------------------------

    localparam int HALF_BIT = BIT_CYCLES / 2;
    localparam int FRAME_BITS = 1 + DATA_BITS +
                                ((PARITY != 0) ? 1 : 0) +
                                STOP_BITS;

    localparam int TX_BIT_W =
        (FRAME_BITS <= 2) ? 1 : $clog2(FRAME_BITS);

    localparam int DATA_CNT_W =
        (DATA_BITS <= 2) ? 1 : $clog2(DATA_BITS);

    localparam int STOP_CNT_W =
        (STOP_BITS <= 2) ? 1 : $clog2(STOP_BITS);

    localparam int TIMER_W =
        (BIT_CYCLES <= 2) ? 1 : $clog2(BIT_CYCLES);

    // -------------------------------------------------------------------------
    // Transmitter
    //
    // tx_frame layout:
    //
    //   bit 0                 = START
    //   bits 1..DATA_BITS    = DATA, LSB first
    //   next bit              = PARITY, if enabled
    //   remaining bits        = STOP, all 1
    // -------------------------------------------------------------------------

    logic [FRAME_BITS-1:0] tx_frame;
    logic [TX_BIT_W-1:0]   tx_bit_index;
    logic [TIMER_W-1:0]    tx_timer;

    integer tx_i;

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            tx_busy      <= 1'b0;
            tx_serial    <= 1'b1;
            tx_frame     <= '1;
            tx_bit_index <= '0;
            tx_timer     <= '0;
        end
        else begin
            if (!tx_busy) begin
                tx_serial <= 1'b1;
                tx_timer  <= '0;

                // A start request is accepted only while idle.
                if (tx_start) begin
                    tx_busy      <= 1'b1;
                    tx_bit_index <= '0;
                    tx_timer     <= '0;

                    // Start bit.
                    tx_frame[0] <= 1'b0;

                    // Data bits, LSB first.
                    for (tx_i = 0; tx_i < DATA_BITS; tx_i = tx_i + 1) begin
                        tx_frame[1 + tx_i] <= tx_data[tx_i];
                    end

                    // Parity.
                    if (PARITY == 1) begin
                        // Even parity: XOR of data.
                        tx_frame[1 + DATA_BITS] <= ^tx_data;
                    end
                    else if (PARITY == 2) begin
                        // Odd parity.
                        tx_frame[1 + DATA_BITS] <= ~(^tx_data);
                    end

                    // Stop bits are HIGH.
                    for (tx_i = 0; tx_i < STOP_BITS; tx_i = tx_i + 1) begin
                        tx_frame[
                            1 + DATA_BITS +
                            ((PARITY != 0) ? 1 : 0) +
                            tx_i
                        ] <= 1'b1;
                    end

                    // First LOW cycle begins on the accepting edge.
                    tx_serial <= 1'b0;
                end
            end
            else begin
                // Current bit remains unchanged for exactly BIT_CYCLES
                // clock cycles.
                if (tx_timer == BIT_CYCLES - 1) begin
                    tx_timer <= '0;

                    if (tx_bit_index == FRAME_BITS - 1) begin
                        // Final stop bit has just completed.
                        tx_busy      <= 1'b0;
                        tx_serial    <= 1'b1;
                        tx_bit_index <= '0;
                    end
                    else begin
                        tx_bit_index <= tx_bit_index + 1'b1;
                        tx_serial    <= tx_frame[tx_bit_index + 1'b1];
                    end
                end
                else begin
                    tx_timer <= tx_timer + 1'b1;
                end
            end
        end
    end

    // -------------------------------------------------------------------------
    // Receiver state machine
    // -------------------------------------------------------------------------

    typedef enum logic [2:0] {
        RX_IDLE,
        RX_START,
        RX_DATA,
        RX_PARITY,
        RX_STOP
    } rx_state_t;

    rx_state_t rx_state;

    logic [TIMER_W-1:0] rx_timer;

    logic [DATA_CNT_W-1:0] rx_data_count;
    logic [STOP_CNT_W-1:0] rx_stop_count;

    logic [DATA_BITS-1:0] rx_data_work;

    logic rx_parity_work;
    logic rx_frame_err_work;

    // -------------------------------------------------------------------------
    // Receiver
    //
    // RX_IDLE:
    //   Detect a LOW as a candidate start.
    //
    // RX_START:
    //   Wait HALF_BIT cycles, then verify that the line is still LOW.
    //   HIGH => glitch, abort.
    //
    // RX_DATA:
    //   Sample each data bit at its midpoint.
    //
    // RX_PARITY:
    //   Sample parity at its midpoint.
    //
    // RX_STOP:
    //   Sample every stop bit. rx_valid is generated on the midpoint of
    //   the final stop bit.
    // -------------------------------------------------------------------------

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            rx_state         <= RX_IDLE;
            rx_timer         <= '0;
            rx_data_count    <= '0;
            rx_stop_count    <= '0;
            rx_data_work     <= '0;
            rx_parity_work   <= 1'b0;
            rx_frame_err_work <= 1'b0;

            rx_data          <= '0;
            rx_valid         <= 1'b0;
            rx_frame_err     <= 1'b0;
            rx_parity_err    <= 1'b0;
        end
        else begin
            // rx_valid is a one-clock pulse.
            rx_valid <= 1'b0;

            case (rx_state)

                // -------------------------------------------------------------
                // IDLE
                // -------------------------------------------------------------
                RX_IDLE: begin
                    rx_timer          <= '0;
                    rx_data_count     <= '0;
                    rx_stop_count     <= '0;
                    rx_frame_err_work <= 1'b0;
                    rx_parity_work    <= 1'b0;

                    if (!rx_serial) begin
                        // Falling edge / LOW level is only a candidate.
                        // Verify it at the start-bit midpoint.
                        rx_state <= RX_START;
                        rx_timer <= '0;
                    end
                end

                // -------------------------------------------------------------
                // START BIT VALIDATION
                // -------------------------------------------------------------
                RX_START: begin
                    if (HALF_BIT <= 1) begin
                        // BIT_CYCLES >= 8 by contract, so this branch is
                        // primarily defensive.
                        if (rx_serial) begin
                            rx_state <= RX_IDLE;
                            rx_timer <= '0;
                        end
                        else begin
                            rx_state      <= RX_DATA;
                            rx_timer      <= '0;
                            rx_data_count <= '0;
                            rx_data_work  <= '0;
                        end
                    end
                    else if (rx_timer == HALF_BIT - 1) begin
                        rx_timer <= '0;

                        if (rx_serial) begin
                            // Glitch: line returned HIGH before midpoint.
                            rx_state <= RX_IDLE;
                        end
                        else begin
                            // Valid start bit.
                            rx_state      <= RX_DATA;
                            rx_data_count <= '0;
                            rx_data_work  <= '0;
                            rx_timer      <= '0;
                        end
                    end
                    else begin
                        rx_timer <= rx_timer + 1'b1;
                    end
                end

                // -------------------------------------------------------------
                // DATA BITS
                // -------------------------------------------------------------
                RX_DATA: begin
                    if (rx_timer == BIT_CYCLES - 1) begin
                        rx_timer <= '0;

                        rx_data_work[rx_data_count] <= rx_serial;

                        if (rx_data_count == DATA_BITS - 1) begin
                            rx_data_count <= '0;

                            if (PARITY != 0) begin
                                rx_state <= RX_PARITY;
                            end
                            else begin
                                rx_state      <= RX_STOP;
                                rx_stop_count <= '0;
                            end
                        end
                        else begin
                            rx_data_count <= rx_data_count + 1'b1;
                        end
                    end
                    else begin
                        rx_timer <= rx_timer + 1'b1;
                    end
                end

                // -------------------------------------------------------------
                // PARITY
                // -------------------------------------------------------------
                RX_PARITY: begin
                    if (rx_timer == BIT_CYCLES - 1) begin
                        rx_timer <= '0;

                        // Store received parity temporarily.
                        rx_parity_work <= rx_serial;

                        rx_state      <= RX_STOP;
                        rx_stop_count <= '0;
                    end
                    else begin
                        rx_timer <= rx_timer + 1'b1;
                    end
                end

                // -------------------------------------------------------------
                // STOP BITS
                // -------------------------------------------------------------
                RX_STOP: begin
                    if (rx_timer == BIT_CYCLES - 1) begin
                        rx_timer <= '0;

                        // Accumulate framing error across all stop bits.
                        if (!rx_serial)
                            rx_frame_err_work <= 1'b1;

                        if (rx_stop_count == STOP_BITS - 1) begin
                            // Final stop bit sampled. All required stop bits
                            // have now been examined, so report the frame.
                            rx_valid     <= 1'b1;
                            rx_data      <= rx_data_work;

                            if (!rx_serial)
                                rx_frame_err <= 1'b1;
                            else
                                rx_frame_err <= rx_frame_err_work;

                            if (PARITY == 0) begin
                                rx_parity_err <= 1'b0;
                            end
                            else if (PARITY == 1) begin
                                // Even parity: data XOR received parity
                                // must equal zero.
                                rx_parity_err <= (^rx_data_work) ^ rx_parity_work;
                            end
                            else begin
                                // Odd parity: data XOR received parity
                                // must equal one.
                                rx_parity_err <= ~((^rx_data_work) ^ rx_parity_work);
                            end

                            // Return directly to IDLE. If the line is already
                            // LOW for the next start bit, it can be detected
                            // on the following clock, allowing back-to-back
                            // frames.
                            rx_state      <= RX_IDLE;
                            rx_stop_count <= '0;
                        end
                        else begin
                            rx_stop_count <= rx_stop_count + 1'b1;
                        end
                    end
                    else begin
                        rx_timer <= rx_timer + 1'b1;
                    end
                end

                default: begin
                    rx_state <= RX_IDLE;
                    rx_timer <= '0;
                end

            endcase
        end
    end

endmodule
