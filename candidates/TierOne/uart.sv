// =============================================================================
// uart.sv  --  Full-Duplex UART Implementation
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

    // =========================================================================
    // LOCAL PARAMETERS
    // =========================================================================
    localparam int TOTAL_TX_BITS = 1 + DATA_BITS + (PARITY != 0 ? 1 : 0) + STOP_BITS;

    // =========================================================================
    // TRANSMITTER IMPLEMENTATION
    // =========================================================================
    logic [$clog2(BIT_CYCLES)-1:0]    tx_clk_cnt;
    logic [$clog2(TOTAL_TX_BITS)-1:0] tx_bit_cnt;
    logic [DATA_BITS-1:0]             tx_data_reg;
    logic                             tx_parity_bit;

    // Pre-compute TX Parity Bit
    always_comb begin
        if (PARITY == 1)      tx_parity_bit = ^tx_data_reg;       // EVEN
        else if (PARITY == 2) tx_parity_bit = ~(^tx_data_reg);    // ODD
        else                  tx_parity_bit = 1'b0;
    end

    // Helper function to resolve the current serial bit
    function automatic logic get_tx_bit(
        input int bit_idx,
        input logic [DATA_BITS-1:0] data,
        input logic parity
    );
        if (bit_idx == 0) begin
            return 1'b0; // START bit
        end else if (bit_idx >= 1 && bit_idx <= DATA_BITS) begin
            return data[bit_idx - 1]; // DATA bits (LSB first)
        end else if (PARITY != 0 && bit_idx == DATA_BITS + 1) begin
            return parity; // PARITY bit
        end else begin
            return 1'b1; // STOP bit(s)
        end
    endfunction

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            tx_busy     <= 1'b0;
            tx_serial   <= 1'b1;
            tx_clk_cnt  <= '0;
            tx_bit_cnt  <= '0;
            tx_data_reg <= '0;
        end else begin
            if (!tx_busy) begin
                if (tx_start) begin
                    tx_busy     <= 1'b1;
                    tx_data_reg <= tx_data;
                    tx_clk_cnt  <= '0;
                    tx_bit_cnt  <= '0;
                    tx_serial   <= 1'b0; // Start bit immediately
                end else begin
                    tx_serial   <= 1'b1; // Idle line
                end
            end else begin
                if (tx_clk_cnt == BIT_CYCLES - 1) begin
                    tx_clk_cnt <= '0;
                    if (tx_bit_cnt == TOTAL_TX_BITS - 1) begin
                        tx_busy   <= 1'b0;
                        tx_serial <= 1'b1;
                    end else begin
                        tx_bit_cnt <= tx_bit_cnt + 1'b1;
                        tx_serial  <= get_tx_bit(tx_bit_cnt + 1, tx_data_reg, tx_parity_bit);
                    end
                end else begin
                    tx_clk_cnt <= tx_clk_cnt + 1'b1;
                end
            end
        end
    end

    // =========================================================================
    // RECEIVER IMPLEMENTATION
    // =========================================================================
    typedef enum logic [2:0] {
        RX_STATE_IDLE,
        RX_STATE_START,
        RX_STATE_DATA,
        RX_STATE_PARITY,
        RX_STATE_STOP
    } rx_state_t;

    rx_state_t rx_state;

    logic [$clog2(BIT_CYCLES)-1:0] rx_clk_cnt;
    logic [3:0]                     rx_bit_cnt;
    logic [DATA_BITS-1:0]          rx_shift_reg;
    logic                          rx_parity_sampled;
    logic                          rx_frame_err_acc;
    logic                          rx_prev;

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            rx_state          <= RX_STATE_IDLE;
            rx_clk_cnt        <= '0;
            rx_bit_cnt        <= '0;
            rx_shift_reg      <= '0;
            rx_parity_sampled <= 1'b0;
            rx_frame_err_acc  <= 1'b0;
            rx_data           <= '0;
            rx_valid          <= 1'b0;
            rx_frame_err      <= 1'b0;
            rx_parity_err     <= 1'b0;
            rx_prev           <= 1'b1;
        end else begin
            rx_prev  <= rx_serial;
            rx_valid <= 1'b0; // Default pulse length = 1 cycle

            case (rx_state)
                RX_STATE_IDLE: begin
                    rx_clk_cnt       <= '0;
                    rx_bit_cnt       <= '0;
                    rx_frame_err_acc <= 1'b0;
                    // Detect candidate start bit (falling edge on rx_serial)
                    if (rx_prev == 1'b1 && rx_serial == 1'b0) begin
                        rx_state <= RX_STATE_START;
                    end
                end

                RX_STATE_START: begin
                    // Sample start bit at midpoint for glitch rejection
                    if (rx_clk_cnt == (BIT_CYCLES / 2)) begin
                        if (rx_serial == 1'b1) begin
                            // Glitch: return to IDLE without asserting rx_valid
                            rx_state   <= RX_STATE_IDLE;
                            rx_clk_cnt <= '0;
                        end else begin
                            rx_clk_cnt <= rx_clk_cnt + 1'b1;
                        end
                    end else if (rx_clk_cnt == BIT_CYCLES - 1) begin
                        rx_clk_cnt <= '0;
                        rx_bit_cnt <= '0;
                        rx_state   <= RX_STATE_DATA;
                    end else begin
                        rx_clk_cnt <= rx_clk_cnt + 1'b1;
                    end
                end

                RX_STATE_DATA: begin
                    // Sample data bit at midpoint (LSB first)
                    if (rx_clk_cnt == (BIT_CYCLES / 2)) begin
                        rx_shift_reg[rx_bit_cnt] <= rx_serial;
                    end

                    if (rx_clk_cnt == BIT_CYCLES - 1) begin
                        rx_clk_cnt <= '0;
                        if (rx_bit_cnt == DATA_BITS - 1) begin
                            rx_bit_cnt <= '0;
                            if (PARITY != 0) begin
                                rx_state <= RX_STATE_PARITY;
                            end else begin
                                rx_state <= RX_STATE_STOP;
                            end
                        end else begin
                            rx_bit_cnt <= rx_bit_cnt + 1'b1;
                        end
                    end else begin
                        rx_clk_cnt <= rx_clk_cnt + 1'b1;
                    end
                end

                RX_STATE_PARITY: begin
                    // Sample parity bit at midpoint
                    if (rx_clk_cnt == (BIT_CYCLES / 2)) begin
                        rx_parity_sampled <= rx_serial;
                    end

                    if (rx_clk_cnt == BIT_CYCLES - 1) begin
                        rx_clk_cnt <= '0;
                        rx_bit_cnt <= '0;
                        rx_state   <= RX_STATE_STOP;
                    end else begin
                        rx_clk_cnt <= rx_clk_cnt + 1'b1;
                    end
                end

                RX_STATE_STOP: begin
                    // Check stop bit(s) at midpoint
                    if (rx_clk_cnt == (BIT_CYCLES / 2)) begin
                        if (rx_serial == 1'b0) begin
                            rx_frame_err_acc <= 1'b1;
                        end
                    end

                    if (rx_clk_cnt == BIT_CYCLES - 1) begin
                        rx_clk_cnt <= '0;
                        if (rx_bit_cnt == STOP_BITS - 1) begin
                            // Complete frame received
                            rx_state     <= RX_STATE_IDLE;
                            rx_valid     <= 1'b1;
                            rx_data      <= rx_shift_reg;
                            rx_frame_err <= rx_frame_err_acc || (rx_clk_cnt == (BIT_CYCLES / 2) ? (rx_serial == 1'b0) : 1'b0);

                            // Evaluate parity error
                            if (PARITY == 1) begin
                                rx_parity_err <= (rx_parity_sampled != (^rx_shift_reg));
                            end else if (PARITY == 2) begin
                                rx_parity_err <= (rx_parity_sampled != ~(^rx_shift_reg));
                            end else begin
                                rx_parity_err <= 1'b0;
                            end
                        end else begin
                            rx_bit_cnt <= rx_bit_cnt + 1'b1;
                        end
                    end else begin
                        rx_clk_cnt <= rx_clk_cnt + 1'b1;
                    end
                end

                default: rx_state <= RX_STATE_IDLE;
            endcase
        end
    end

endmodule