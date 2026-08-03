// =============================================================================
// uart_tb.sv -- self-checking testbench for `uart` (see uart_iface.sv)
// =============================================================================
// Reference model: the frame format itself, built from first principles in the
// testbench --
//   * TX direction: the TB constructs the expected bit sequence (start, data
//     LSB-first, parity from ^data, stop bits) and then checks tx_serial on
//     EVERY clk cycle of EVERY bit period. This validates value AND baud timing
//     exactly; a one-cycle error in the divider fails.
//   * RX direction: the TB synthesises the serial waveform itself, one bit at a
//     time, BIT_CYCLES clocks per bit, and predicts rx_data / rx_frame_err /
//     rx_parity_err arithmetically.
// No RTL model of a UART appears anywhere in this file.
//
// A background monitor records every rx_valid pulse with its timestamp, so
// "exactly one pulse, inside the required window" is checkable even for
// back-to-back frames.
//
// Override parameters at compile time, e.g.
//   iverilog -g2012 -o sim -P uart_tb.DATA_BITS=7 -P uart_tb.PARITY=2 \
//            -P uart_tb.STOP_BITS=2 uart_tb.sv uart.sv
//
// Final line is exactly one of:
//   TEST_RESULT: PASS
//   TEST_RESULT: FAIL: <reason>
// =============================================================================

`timescale 1ns/1ps

module uart_tb;

    // ---------------- configuration ----------------
    parameter int CLK_FREQ_HZ         = 16_000_000;
    parameter int BAUD_RATE           = 1_000_000;
    parameter int DATA_BITS           = 8;    // 7 or 8
    parameter int PARITY              = 0;    // 0 none, 1 even, 2 odd
    parameter int STOP_BITS           = 1;    // 1 or 2
    parameter int RANDOM_VECTORS      = 1200; // frames per direction; >= 1000
    parameter int MAX_ERRORS_REPORTED = 15;

    localparam int BIT_CYCLES  = CLK_FREQ_HZ / BAUD_RATE;
    localparam int HAS_PARITY  = (PARITY != 0) ? 1 : 0;
    localparam int FRAME_BITS  = 1 + DATA_BITS + HAS_PARITY + STOP_BITS;
    localparam int PARITY_IDX  = 1 + DATA_BITS;              // valid if HAS_PARITY
    localparam int STOP_IDX    = 1 + DATA_BITS + HAS_PARITY; // first stop bit
    localparam int NDATA       = 1 << DATA_BITS;

    localparam int CLK_PERIOD  = 10;                 // time units per clk cycle
    localparam int BIT_TIME    = BIT_CYCLES * CLK_PERIOD;

    // ---------------- DUT connections ----------------
    logic                 clk = 1'b0;
    logic                 rst_n;
    logic                 tx_start;
    logic [DATA_BITS-1:0] tx_data;
    logic                 tx_busy;
    logic                 tx_serial;
    logic                 rx_serial;
    logic [DATA_BITS-1:0] rx_data;
    logic                 rx_valid;
    logic                 rx_frame_err;
    logic                 rx_parity_err;

    uart #(
        .CLK_FREQ_HZ (CLK_FREQ_HZ),
        .BAUD_RATE   (BAUD_RATE),
        .DATA_BITS   (DATA_BITS),
        .PARITY      (PARITY),
        .STOP_BITS   (STOP_BITS)
    ) dut (
        .clk (clk), .rst_n (rst_n),
        .tx_start (tx_start), .tx_data (tx_data),
        .tx_busy (tx_busy), .tx_serial (tx_serial),
        .rx_serial (rx_serial), .rx_data (rx_data), .rx_valid (rx_valid),
        .rx_frame_err (rx_frame_err), .rx_parity_err (rx_parity_err)
    );

    always #(CLK_PERIOD/2) clk = ~clk;

    // ---------------- bookkeeping ----------------
    int    errors = 0;
    int    checks = 0;
    string fail_reason = "";
    string phase = "init";

    task automatic note_fail(input string why);
        errors++;
        if (fail_reason == "") fail_reason = why;
        if (errors <= MAX_ERRORS_REPORTED)
            $display("[FAIL] t=%0t phase=%s : %s", $time, phase, why);
        else if (errors == MAX_ERRORS_REPORTED + 1)
            $display("[FAIL] ... further failures suppressed");
    endtask

    // ---------------- parity reference (plain math) ----------------
    function automatic bit exp_parity(input logic [DATA_BITS-1:0] d);
        bit x;
        x = 1'b0;
        for (int i = 0; i < DATA_BITS; i++) x = x ^ d[i];
        return (PARITY == 1) ? x : ~x;   // even : odd
    endfunction

    // =========================================================================
    // rx_valid monitor -- records every pulse with its timestamp
    // =========================================================================
    localparam int MAXPULSE = 8;
    int  rxv_n = 0;
    time rxv_t    [0:MAXPULSE-1];
    int  rxv_data [0:MAXPULSE-1];
    bit  rxv_ferr [0:MAXPULSE-1];
    bit  rxv_perr [0:MAXPULSE-1];

    task automatic rxv_clear();
        rxv_n = 0;
    endtask

    always @(posedge clk) begin
        #1;
        if (rst_n === 1'b1 && rx_valid === 1'b1) begin
            if (rxv_n < MAXPULSE) begin
                rxv_t[rxv_n]    = $time;
                rxv_data[rxv_n] = int'(rx_data);
                rxv_ferr[rxv_n] = rx_frame_err;
                rxv_perr[rxv_n] = rx_parity_err;
            end
            rxv_n++;   // counts past MAXPULSE so overflow is detectable
        end
    end

    // ---------------- clock stepping ----------------
    task automatic tick(input int n);
        for (int i = 0; i < n; i++) begin
            @(posedge clk);
            #1;
        end
    endtask

    // =========================================================================
    // TRANSMITTER check: drive one frame, verify every clk cycle of every bit
    // =========================================================================
    task automatic tx_check(input logic [DATA_BITS-1:0] d, input string ctx);
        bit exp_bit [0:FRAME_BITS-1];
        int wait_cnt;
        bit bad;
        checks++;

        // build the expected frame from first principles
        exp_bit[0] = 1'b0;                                   // start
        for (int i = 0; i < DATA_BITS; i++)
            exp_bit[1+i] = d[i];                             // LSB first
        if (HAS_PARITY) exp_bit[PARITY_IDX] = exp_parity(d);
        for (int s = 0; s < STOP_BITS; s++)
            exp_bit[STOP_IDX+s] = 1'b1;                      // stop

        if (tx_busy !== 1'b0) begin
            note_fail($sformatf("%s: tx_busy set before transmit", ctx));
            return;
        end
        if (tx_serial !== 1'b1) begin
            note_fail($sformatf("%s: tx_serial not idle-high before transmit", ctx));
            return;
        end

        tx_start = 1'b1;
        tx_data  = d;
        @(posedge clk);
        #1;                     // drive strictly after the sampling edge
        tx_start = 1'b0;
        tx_data  = DATA_BITS'($urandom());   // must already be captured

        // start bit must begin within 2 clk cycles of the accepting edge
        wait_cnt = 0;
        while (tx_serial !== 1'b0) begin
            if (wait_cnt >= 2) begin
                note_fail($sformatf("%s: no start bit within 2 cycles of tx_start", ctx));
                return;
            end
            tick(1);
            wait_cnt++;
        end

        // we are now in the FIRST clk cycle of the start bit
        bad = 1'b0;
        for (int b = 0; b < FRAME_BITS; b++) begin
            for (int c = 0; c < BIT_CYCLES; c++) begin
                if (!bad && tx_serial !== exp_bit[b]) begin
                    note_fail($sformatf({"%s: data 0x%0h -- bit %0d (%s) wrong at cycle %0d ",
                                         "of %0d: tx_serial=%0b expected %0b"},
                                        ctx, d, b,
                                        (b == 0) ? "start" :
                                        (b <= DATA_BITS) ? "data" :
                                        (HAS_PARITY && b == PARITY_IDX) ? "parity" : "stop",
                                        c, BIT_CYCLES, tx_serial, exp_bit[b]));
                    bad = 1'b1;   // report once per frame
                end
                if (!bad && tx_busy !== 1'b1)
                    if (b < FRAME_BITS-1 || c < BIT_CYCLES-1) begin
                        note_fail($sformatf("%s: tx_busy dropped mid-frame (bit %0d cycle %0d)",
                                            ctx, b, c));
                        bad = 1'b1;
                    end
                // start-while-busy must be ignored: poke it during the frame
                if (b == 1 && c == 0) begin
                    tx_start = 1'b1;
                    tx_data  = ~d;
                end else if (b == 1 && c == 2) begin
                    tx_start = 1'b0;
                    tx_data  = DATA_BITS'($urandom());
                end
                tick(1);
            end
        end

        // tx_busy must clear within 2 cycles of the frame ending
        wait_cnt = 0;
        while (tx_busy !== 1'b0) begin
            if (wait_cnt >= 2) begin
                note_fail($sformatf("%s: tx_busy still set >2 cycles after frame end", ctx));
                return;
            end
            tick(1);
            wait_cnt++;
        end
        // line must stay idle high
        for (int c = 0; c < BIT_CYCLES; c++) begin
            if (tx_serial !== 1'b1) begin
                note_fail($sformatf("%s: tx_serial not idle-high after frame", ctx));
                return;
            end
            tick(1);
        end
    endtask

    // =========================================================================
    // RECEIVER drive: synthesise a waveform, then verify the reported frame
    // =========================================================================
    task automatic rx_drive_bit(input bit v);
        rx_serial = v;
        tick(BIT_CYCLES);
    endtask

    // corrupt_parity: invert the parity bit.  bad_stop_mask bit s: drive stop
    // bit s LOW instead of HIGH.
    task automatic rx_send(input logic [DATA_BITS-1:0] d,
                           input bit corrupt_parity,
                           input int bad_stop_mask,
                           output time t_start);
        t_start = $time;
        rx_drive_bit(1'b0);                                  // start
        for (int i = 0; i < DATA_BITS; i++)
            rx_drive_bit(d[i]);                              // LSB first
        if (HAS_PARITY)
            rx_drive_bit(corrupt_parity ? ~exp_parity(d) : exp_parity(d));
        for (int s = 0; s < STOP_BITS; s++)
            rx_drive_bit(((bad_stop_mask >> s) & 1) ? 1'b0 : 1'b1);
        rx_serial = 1'b1;
    endtask

    // Verify exactly one rx_valid pulse, in the required window, with the
    // expected payload and error flags.
    // allow_extra: tolerate additional rx_valid pulses AFTER the first one.
    // Required whenever the stimulus ends the frame with the line LOW (injected
    // framing error): what a receiver does with the trailing low period before
    // the line returns high is legitimately implementation-defined, so only the
    // first, in-window pulse is contractual.
    task automatic rx_expect(input logic [DATA_BITS-1:0] d,
                             input bit exp_perr,
                             input bit exp_ferr,
                             input time t_start,
                             input bit allow_extra,
                             input string ctx);
        time earliest, latest;
        checks++;
        // window: midpoint of the last stop bit .. 2 bit periods after frame end
        earliest = t_start + (FRAME_BITS-1)*BIT_TIME + BIT_TIME/2;
        latest   = t_start + FRAME_BITS*BIT_TIME + 2*BIT_TIME;

        if (rxv_n == 0) begin
            note_fail($sformatf("%s: no rx_valid pulse for data 0x%0h", ctx, d));
            return;
        end
        if (rxv_n > 1 && !allow_extra) begin
            note_fail($sformatf("%s: %0d rx_valid pulses for one frame (must be exactly 1)",
                                ctx, rxv_n));
            return;
        end
        if (rxv_t[0] < earliest || rxv_t[0] > latest)
            note_fail($sformatf({"%s: rx_valid at t=%0t outside window [%0t,%0t] ",
                                 "(frame started %0t)"},
                                ctx, rxv_t[0], earliest, latest, t_start));
        // data is only meaningful when the frame was not corrupted mid-payload
        if (!exp_ferr && rxv_data[0] != int'(d))
            note_fail($sformatf("%s: rx_data=0x%0h expected 0x%0h", ctx, rxv_data[0], d));
        if (rxv_perr[0] !== exp_perr)
            note_fail($sformatf("%s: rx_parity_err=%0b expected %0b (data 0x%0h)",
                                ctx, rxv_perr[0], exp_perr, d));
        if (rxv_ferr[0] !== exp_ferr)
            note_fail($sformatf("%s: rx_frame_err=%0b expected %0b (data 0x%0h)",
                                ctx, rxv_ferr[0], exp_ferr, d));
    endtask

    // convenience: idle, send a clean frame, check it
    task automatic rx_frame_check(input logic [DATA_BITS-1:0] d, input string ctx);
        time t0;
        rx_serial = 1'b1;
        tick(2);
        rxv_clear();
        rx_send(d, 1'b0, 0, t0);
        tick(3*BIT_CYCLES);
        rx_expect(d, 1'b0, 1'b0, t0, 1'b0, ctx);
    endtask

    task automatic do_reset();
        tx_start  = 1'b0;
        tx_data   = '0;
        rx_serial = 1'b1;
        rst_n     = 1'b0;
        repeat (4) @(posedge clk);
        #1;
        if (tx_serial !== 1'b1) note_fail("tx_serial not idle-high during reset");
        if (tx_busy   !== 1'b0) note_fail("tx_busy set during reset");
        if (rx_valid  !== 1'b0) note_fail("rx_valid set during reset");
        rst_n = 1'b1;
        tick(2);
        rxv_clear();
    endtask

    // ---------------- stimulus ----------------
    logic [DATA_BITS-1:0] d, d2;
    time                  t0, t1;
    int                   glitch_len;

    initial begin
        // config sanity
        if (DATA_BITS != 7 && DATA_BITS != 8) begin
            $display("TEST_RESULT: FAIL: illegal DATA_BITS=%0d", DATA_BITS); $finish;
        end
        if (PARITY < 0 || PARITY > 2) begin
            $display("TEST_RESULT: FAIL: illegal PARITY=%0d", PARITY); $finish;
        end
        if (STOP_BITS != 1 && STOP_BITS != 2) begin
            $display("TEST_RESULT: FAIL: illegal STOP_BITS=%0d", STOP_BITS); $finish;
        end
        if (CLK_FREQ_HZ % BAUD_RATE != 0) begin
            $display("TEST_RESULT: FAIL: CLK_FREQ_HZ=%0d is not a multiple of BAUD_RATE=%0d",
                     CLK_FREQ_HZ, BAUD_RATE); $finish;
        end
        if (BIT_CYCLES < 8) begin
            $display("TEST_RESULT: FAIL: BIT_CYCLES=%0d < 8", BIT_CYCLES); $finish;
        end

        do_reset();

        // ==================================================================
        // TRANSMITTER
        // ==================================================================

        // ---- T1: named data patterns ----
        phase = "T1-tx-patterns";
        tx_check(DATA_BITS'('h00), "tx-0x00");
        tx_check('1,               "tx-all-ones");
        tx_check(DATA_BITS'('h01), "tx-0x01");
        tx_check(DATA_BITS'(1 << (DATA_BITS-1)), "tx-msb-only");
        tx_check(DATA_BITS'('h55), "tx-0x55");
        tx_check(DATA_BITS'('h2A), "tx-0x2A");
        tx_check(DATA_BITS'('h7F), "tx-0x7F");

        // ---- T2: exhaustive over every payload value ----
        phase = "T2-tx-exhaustive";
        for (int v = 0; v < NDATA; v++)
            tx_check(DATA_BITS'(v), $sformatf("tx-exh-%0d", v));

        // ---- T3: back-to-back frames, tx_start on the first idle cycle ----
        phase = "T3-tx-back-to-back";
        for (int k = 0; k < 8; k++)
            tx_check(DATA_BITS'($urandom()), $sformatf("tx-b2b-%0d", k));

        // ---- T4: tx_start held high across a whole frame must not corrupt it,
        //          and must not be latched into a second unexpected frame ----
        phase = "T4-tx-start-held";
        d = DATA_BITS'('h5A);
        tx_check(d, "tx-start-held");   // tx_check already pokes tx_start mid-frame

        // ---- T5: reset in the middle of a transmission ----
        phase = "T5-tx-reset";
        tx_start = 1'b1; tx_data = '1;
        @(posedge clk); #1;
        tx_start = 1'b0;
        tick(2*BIT_CYCLES);             // partway through the frame
        rst_n = 1'b0;
        tick(3);
        if (tx_serial !== 1'b1) note_fail("reset did not force tx_serial idle-high");
        if (tx_busy   !== 1'b0) note_fail("reset did not clear tx_busy");
        rst_n = 1'b1;
        tick(2);
        tx_check(DATA_BITS'('h3C), "tx-after-reset");

        // ==================================================================
        // RECEIVER
        // ==================================================================

        // ---- R1: named data patterns ----
        phase = "R1-rx-patterns";
        rx_frame_check(DATA_BITS'('h00), "rx-0x00");
        rx_frame_check('1,               "rx-all-ones");
        rx_frame_check(DATA_BITS'('h01), "rx-0x01");
        rx_frame_check(DATA_BITS'(1 << (DATA_BITS-1)), "rx-msb-only");
        rx_frame_check(DATA_BITS'('h55), "rx-0x55");
        rx_frame_check(DATA_BITS'('h2A), "rx-0x2A");

        // ---- R2: exhaustive over every payload value ----
        phase = "R2-rx-exhaustive";
        for (int v = 0; v < NDATA; v++)
            rx_frame_check(DATA_BITS'(v), $sformatf("rx-exh-%0d", v));

        // ---- R3: parity error injection ----
        phase = "R3-rx-parity-err";
        if (HAS_PARITY) begin
            for (int k = 0; k < 16; k++) begin
                d = DATA_BITS'($urandom());
                rx_serial = 1'b1; tick(2); rxv_clear();
                rx_send(d, 1'b1, 0, t0);          // inverted parity bit
                tick(3*BIT_CYCLES);
                rx_expect(d, 1'b1, 1'b0, t0, 1'b0, $sformatf("rx-perr-%0d", k));
            end
            // and a clean frame straight afterwards must be clean
            rx_frame_check(DATA_BITS'('h6D), "rx-clean-after-perr");
        end else begin
            // PARITY==0: rx_parity_err must never assert
            for (int k = 0; k < 8; k++)
                rx_frame_check(DATA_BITS'($urandom()), $sformatf("rx-noparity-%0d", k));
        end

        // ---- R4: framing error -- each stop bit driven low individually ----
        phase = "R4-rx-frame-err";
        for (int s = 0; s < STOP_BITS; s++) begin
            d = DATA_BITS'('h96);
            rx_serial = 1'b1; tick(2); rxv_clear();
            rx_send(d, 1'b0, (1 << s), t0);
            // after a bad stop bit, give the line time to settle before judging
            rx_serial = 1'b1;
            tick(4*BIT_CYCLES);
            rx_expect(d, 1'b0, 1'b1, t0, 1'b1, $sformatf("rx-ferr-stop%0d", s));
        end
        if (STOP_BITS == 2) begin
            // both stop bits low
            d = DATA_BITS'('h96);
            rx_serial = 1'b1; tick(2); rxv_clear();
            rx_send(d, 1'b0, 2'b11, t0);
            rx_serial = 1'b1;
            tick(4*BIT_CYCLES);
            rx_expect(d, 1'b0, 1'b1, t0, 1'b1, "rx-ferr-both-stops");
        end
        rx_frame_check(DATA_BITS'('hA3), "rx-clean-after-ferr");

        // ---- R5: glitch rejection -- low pulses shorter than half a bit ----
        phase = "R5-rx-glitch";
        for (glitch_len = 1; glitch_len < BIT_CYCLES/2; glitch_len++) begin
            rx_serial = 1'b1; tick(3); rxv_clear();
            rx_serial = 1'b0; tick(glitch_len);
            rx_serial = 1'b1; tick(FRAME_BITS*BIT_CYCLES + 2*BIT_CYCLES);
            checks++;
            if (rxv_n != 0)
                note_fail($sformatf("glitch of %0d cycles (< half bit = %0d) produced %0d rx_valid pulse(s)",
                                    glitch_len, BIT_CYCLES/2, rxv_n));
        end
        // a real frame right after a glitch must still be received
        rx_serial = 1'b1; tick(3);
        rx_serial = 1'b0; tick(1);
        rx_serial = 1'b1; tick(2*BIT_CYCLES);
        rx_frame_check(DATA_BITS'('h7E), "rx-frame-after-glitch");

        // ---- R6: break condition -- line low for a whole frame ----
        phase = "R6-rx-break";
        rx_serial = 1'b1; tick(2); rxv_clear();
        t0 = $time;
        rx_serial = 1'b0;
        tick(FRAME_BITS*BIT_CYCLES);
        rx_serial = 1'b1;
        tick(4*BIT_CYCLES);
        checks++;
        if (rxv_n == 0)
            note_fail("break condition produced no rx_valid");
        else begin
            if (rxv_data[0] != 0)
                note_fail($sformatf("break: rx_data=0x%0h expected 0x0", rxv_data[0]));
            if (rxv_ferr[0] !== 1'b1)
                note_fail("break: rx_frame_err not asserted");
        end
        // must recover
        rx_frame_check(DATA_BITS'('hC7), "rx-clean-after-break");

        // ---- R7: back-to-back frames with zero idle between them ----
        phase = "R7-rx-back-to-back";
        for (int k = 0; k < 8; k++) begin
            d  = DATA_BITS'($urandom());
            d2 = DATA_BITS'($urandom());
            rx_serial = 1'b1; tick(2); rxv_clear();
            rx_send(d,  1'b0, 0, t0);   // second start bit begins immediately
            rx_send(d2, 1'b0, 0, t1);
            tick(3*BIT_CYCLES);
            checks++;
            if (rxv_n != 2)
                note_fail($sformatf("back-to-back: got %0d rx_valid pulses, expected 2", rxv_n));
            else begin
                if (rxv_data[0] != int'(d))
                    note_fail($sformatf("back-to-back frame 1: rx_data=0x%0h expected 0x%0h",
                                        rxv_data[0], d));
                if (rxv_data[1] != int'(d2))
                    note_fail($sformatf("back-to-back frame 2: rx_data=0x%0h expected 0x%0h",
                                        rxv_data[1], d2));
                if (rxv_ferr[0] || rxv_ferr[1])
                    note_fail("back-to-back: spurious frame error");
                if (rxv_perr[0] || rxv_perr[1])
                    note_fail("back-to-back: spurious parity error");
            end
        end

        // ---- R8: long idle between frames ----
        phase = "R8-rx-long-idle";
        rx_serial = 1'b1;
        tick(20*BIT_CYCLES);
        rx_frame_check(DATA_BITS'('h39), "rx-after-long-idle");

        // ---- R9: reset while receiving ----
        phase = "R9-rx-reset";
        rx_serial = 1'b1; tick(2); rxv_clear();
        rx_serial = 1'b0; tick(BIT_CYCLES);      // start bit
        rx_serial = 1'b1; tick(BIT_CYCLES);      // one data bit
        rst_n = 1'b0;
        tick(3);
        rst_n = 1'b1;
        rx_serial = 1'b1;
        tick(FRAME_BITS*BIT_CYCLES);
        rxv_clear();
        rx_frame_check(DATA_BITS'('h1B), "rx-after-reset");

        // ==================================================================
        // FULL DUPLEX: transmit and receive simultaneously
        // ==================================================================
        phase = "D1-full-duplex";
        for (int k = 0; k < 8; k++) begin
            d  = DATA_BITS'($urandom());
            d2 = DATA_BITS'($urandom());
            rx_serial = 1'b1; tick(2); rxv_clear();
            fork
                tx_check(d, $sformatf("duplex-tx-%0d", k));
                begin
                    rx_send(d2, 1'b0, 0, t0);
                    tick(3*BIT_CYCLES);
                    rx_expect(d2, 1'b0, 1'b0, t0, 1'b0, $sformatf("duplex-rx-%0d", k));
                end
            join
        end

        // ==================================================================
        // RANDOM REGRESSION
        // ==================================================================
        phase = "X1-random-tx";
        for (int v = 0; v < RANDOM_VECTORS; v++)
            tx_check(DATA_BITS'($urandom()), $sformatf("rand-tx-%0d", v));

        phase = "X2-random-rx";
        for (int v = 0; v < RANDOM_VECTORS; v++) begin
            bit cp, want_perr;
            int bsm;
            d   = DATA_BITS'($urandom());
            cp  = HAS_PARITY && ($urandom_range(0, 9) == 0);   // 10% parity errors
            bsm = ($urandom_range(0, 9) == 0)                  // 10% framing errors
                  ? $urandom_range(1, (1 << STOP_BITS) - 1) : 0;
            want_perr = cp;
            rx_serial = 1'b1;
            tick($urandom_range(2, 2*BIT_CYCLES));             // random idle gap
            rxv_clear();
            rx_send(d, cp, bsm, t0);
            rx_serial = 1'b1;
            tick(4*BIT_CYCLES);
            rx_expect(d, want_perr, (bsm != 0), t0, (bsm != 0), $sformatf("rand-rx-%0d", v));
        end

        // ------------------------------------------------------------------
        phase = "final";
        if (checks < 1000)
            note_fail($sformatf("insufficient coverage: only %0d checks executed", checks));

        if (errors == 0) begin
            $display("// info: %0d checks; BIT_CYCLES=%0d FRAME_BITS=%0d", checks,
                     BIT_CYCLES, FRAME_BITS);
            $display("TEST_RESULT: PASS");
        end else
            $display("TEST_RESULT: FAIL: %s (%0d failing checks of %0d)",
                     fail_reason, errors, checks);
        $finish;
    end

    initial begin
        #4_000_000_000;
        $display("TEST_RESULT: FAIL: timeout -- testbench did not complete");
        $finish;
    end

endmodule
