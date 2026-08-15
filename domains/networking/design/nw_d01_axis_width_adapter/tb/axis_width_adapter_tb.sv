// =============================================================================
// axis_width_adapter_tb.sv -- self-checking checker for nw_d01
// =============================================================================
// NEVER SHIPPED TO A SUBMISSION.
//
// The scoreboard is a BYTE-STREAM scoreboard, deliberately. It records the
// keep-enabled bytes of every ACCEPTED input beat and compares the
// keep-enabled bytes of every accepted output beat against them in order. It
// models nothing about beats, segments, or pipelining -- those are exactly the
// free choices a width adapter is allowed to make differently, and encoding
// them here is what would make a correct alternative implementation fail.
//
// Both sides are recorded by OBSERVING the real valid/ready handshake, never by
// predicting which edge will transfer. Driver-side accounting cannot stay in
// step with a DUT whose backpressure it does not model.
//
// Build with --binary --timing --x-assign unique --x-initial unique, top module
// axis_width_adapter_tb, -GS_BYTES / -GM_BYTES / -GUSER_W. See NOTES.md.
//
// Final line is exactly one of:
//   TEST_RESULT: PASS
//   TEST_RESULT: FAIL: <reason>
// =============================================================================

`timescale 1ns/1ps

module axis_width_adapter_tb;

    parameter int S_BYTES = 1;
    parameter int M_BYTES = 4;
    parameter int USER_W  = 1;
    parameter int MAX_ERRORS_REPORTED = 20;
    parameter int MIN_CHECKS = 400;
    parameter int SOAK_PACKETS = 900;

    localparam int MAXB = 400000;   // byte store
    localparam int MAXP = 20000;    // packet store
    localparam int MAX_PKT_BEATS = 40;

    logic                 clk = 1'b0;
    logic                 rst_n;
    logic                 s_valid, s_ready, s_last;
    logic [S_BYTES*8-1:0] s_data;
    logic [S_BYTES-1:0]   s_keep;
    logic [USER_W-1:0]    s_user;
    logic                 m_valid, m_ready, m_last;
    logic [M_BYTES*8-1:0] m_data;
    logic [M_BYTES-1:0]   m_keep;
    logic [USER_W-1:0]    m_user;

    axis_width_adapter #(.S_BYTES(S_BYTES), .M_BYTES(M_BYTES), .USER_W(USER_W)) dut (
        .clk(clk), .rst_n(rst_n),
        .s_valid(s_valid), .s_ready(s_ready), .s_data(s_data),
        .s_keep(s_keep), .s_last(s_last), .s_user(s_user),
        .m_valid(m_valid), .m_ready(m_ready), .m_data(m_data),
        .m_keep(m_keep), .m_last(m_last), .m_user(m_user));

    always #5 clk = ~clk;

    int    errors = 0, checks = 0;
    string fail_reason = "", phase = "init";

    task automatic note_fail(input string why);
        errors++;
        if (fail_reason == "") fail_reason = why;
        if (errors <= MAX_ERRORS_REPORTED)
            $display("[FAIL] t=%0t phase=%s : %s", $time, phase, why);
        else if (errors == MAX_ERRORS_REPORTED + 1)
            $display("[FAIL] ... further failures suppressed");
    endtask

    // ---------------- byte-stream scoreboard ----------------
    logic [7:0] in_bytes  [0:MAXB-1];
    int         in_pkt_end[0:MAXP-1];
    logic [USER_W-1:0] in_pkt_user[0:MAXP-1];
    int in_ptr = 0, in_pkts = 0;
    int out_ptr = 0, out_pkts = 0;

    // ---------------- coverage ----------------
    int cov_partial_last = 0;   // output packet ended on a partial beat
    int cov_full_last    = 0;   // output packet ended on a full beat
    int cov_single_beat  = 0;   // output packet was one beat
    int cov_multi_beat   = 0;
    int cov_bp           = 0;   // m_valid held under m_ready low
    int cov_in_stall     = 0;   // s_valid held under s_ready low
    int cov_reset_mid    = 0;
    int cov_reset_pending = 0;  // reset applied while an output beat was pending
    bit d8_reachable = 1'b0;    // DUT can hold an output beat under backpressure at all
    int cov_gap          = 0;
    int cov_minpkt       = 0;   // 1-byte packet
    int cov_bigpkt       = 0;   // packet spanning many beats

    int beats_out = 0, cycles_active = 0;

    logic prev_m_valid, prev_m_ready, prev_m_last;
    logic [M_BYTES*8-1:0] prev_m_data;
    logic [M_BYTES-1:0]   prev_m_keep;

    function automatic bit keep_contiguous(input logic [M_BYTES-1:0] k);
        bit seen_zero;
        seen_zero = 1'b0;
        for (int i = 0; i < M_BYTES; i++) begin
            if (!k[i]) seen_zero = 1'b1;
            else if (seen_zero) return 1'b0;   // a 1 after a 0 => hole
        end
        return 1'b1;
    endfunction

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            prev_m_valid <= 1'b0;
            prev_m_ready <= 1'b0;
        end else begin
            cycles_active++;

            // ---- H3: output stability while unaccepted --------------------
            if (prev_m_valid && !prev_m_ready) begin
                cov_bp++;
                if (!m_valid)
                    note_fail("m_valid dropped while the beat was unaccepted (H3)");
                else if (m_data !== prev_m_data || m_keep !== prev_m_keep ||
                         m_last !== prev_m_last)
                    note_fail("output beat changed under backpressure (H3)");
            end

            if (s_valid && !s_ready) cov_in_stall++;

            // ---- record accepted INPUT beats ------------------------------
            if (s_valid && s_ready) begin
                for (int i = 0; i < S_BYTES; i++)
                    if (s_keep[i]) begin
                        in_bytes[in_ptr] = s_data[i*8 +: 8];
                        in_ptr++;
                    end
                if (s_last) begin
                    in_pkt_end [in_pkts] = in_ptr;
                    in_pkt_user[in_pkts] = s_user;
                    in_pkts++;
                end
            end

            // ---- check accepted OUTPUT beats ------------------------------
            if (m_valid && m_ready) begin
                int live;
                checks++;
                beats_out++;
                live = 0;
                for (int i = 0; i < M_BYTES; i++) if (m_keep[i]) live++;

                // C4: keep well-formedness
                if (live == 0)
                    note_fail("output beat with m_keep all zero (C4)");
                if (!keep_contiguous(m_keep))
                    note_fail($sformatf("m_keep not contiguous from bit 0: 0x%0h (C4)", m_keep));
                if (!m_last && live != M_BYTES)
                    note_fail($sformatf("partial beat (keep=0x%0h) without m_last (C4)", m_keep));

                // C1: byte preservation, in order
                for (int i = 0; i < M_BYTES; i++) begin
                    if (m_keep[i]) begin
                        if (out_ptr >= in_ptr) begin
                            note_fail($sformatf(
                                "output byte %0d emitted before any matching input byte (C1)",
                                out_ptr));
                            out_ptr++;
                        end else begin
                            if (m_data[i*8 +: 8] !== in_bytes[out_ptr])
                                note_fail($sformatf(
                                    "byte %0d: got 0x%02h expected 0x%02h (C1)",
                                    out_ptr, m_data[i*8 +: 8], in_bytes[out_ptr]));
                            out_ptr++;
                        end
                    end
                end

                // C2/C3/C5: framing and sideband at end of packet
                if (m_last) begin
                    if (out_pkts >= in_pkts) begin
                        note_fail($sformatf(
                            "output packet %0d completed before input packet %0d did (C2)",
                            out_pkts, in_pkts));
                    end else begin
                        if (out_ptr != in_pkt_end[out_pkts])
                            note_fail($sformatf(
                                "packet %0d length mismatch: %0d bytes out, %0d in (C1/C2)",
                                out_pkts, out_ptr, in_pkt_end[out_pkts]));
                        if (m_user !== in_pkt_user[out_pkts])
                            note_fail($sformatf(
                                "packet %0d tuser: got 0x%0h expected 0x%0h (C5)",
                                out_pkts, m_user, in_pkt_user[out_pkts]));
                    end
                    if (live == M_BYTES) cov_full_last++; else cov_partial_last++;
                    out_pkts++;
                end
            end

            prev_m_valid <= m_valid;
            prev_m_ready <= m_ready;
            prev_m_data  <= m_data;
            prev_m_keep  <= m_keep;
            prev_m_last  <= m_last;
        end
    end

    // per-output-packet beat counting, for coverage only
    int beats_this_pkt = 0;
    always_ff @(posedge clk) begin
        if (!rst_n) beats_this_pkt <= 0;
        else if (m_valid && m_ready) begin
            if (m_last) begin
                if (beats_this_pkt == 0) cov_single_beat++; else cov_multi_beat++;
                beats_this_pkt <= 0;
            end else beats_this_pkt <= beats_this_pkt + 1;
        end
    end

    // ---------------- backpressure generator ----------------
    bit bp_auto = 1'b0;
    int bp_weight = 0;
    bit m_ready_man = 1'b1;
    bit m_ready_auto = 1'b1;
    assign m_ready = bp_auto ? m_ready_auto : m_ready_man;
    always_ff @(posedge clk) m_ready_auto <= ($urandom_range(0,99) >= bp_weight);

    // ---------------- driver ----------------
    // Sends one packet of nbytes. Beats are full except possibly the last, per
    // the spec's input preconditions -- the checker must obey the contract it
    // requires of the producer.
    task automatic send_packet(input int nbytes, input logic [USER_W-1:0] user,
                               input int gap_pct, input int max_wait);
        int remaining, n, waited, target;
        remaining = nbytes;
        while (remaining > 0) begin
            n = (remaining > S_BYTES) ? S_BYTES : remaining;
            s_data = '0; s_keep = '0;
            for (int i = 0; i < S_BYTES; i++)
                if (i < n) begin
                    s_data[i*8 +: 8] = $urandom_range(0,255);
                    s_keep[i] = 1'b1;
                end
            s_last = (remaining - n == 0);
            s_user = user;
            s_valid = 1'b1;
            target = in_ptr + n;
            waited = 0;
            while (in_ptr < target && waited < max_wait) begin
                @(posedge clk); #1; waited++;
            end
            if (in_ptr < target) begin
                note_fail($sformatf("input beat not accepted within %0d cycles", max_wait));
                s_valid = 1'b0;
                return;
            end
            s_valid = 1'b0;
            remaining -= n;
            if (gap_pct > 0 && $urandom_range(0,99) < gap_pct) begin
                cov_gap++;
                repeat (1 + $urandom_range(0,2)) begin @(posedge clk); #1; end
            end
        end
        if (nbytes == 1) cov_minpkt++;
        if (nbytes > 8 * S_BYTES) cov_bigpkt++;
    endtask

    task automatic idle_cycles(input int n);
        s_valid = 1'b0;
        for (int i = 0; i < n; i++) begin @(posedge clk); #1; end
    endtask

    task automatic drain(input int max_wait);
        int waited;
        waited = 0;
        bp_auto = 1'b0; m_ready_man = 1'b1;
        while (out_pkts < in_pkts && waited < max_wait) begin
            @(posedge clk); #1; waited++;
        end
        if (out_pkts < in_pkts)
            note_fail($sformatf("drain timeout: %0d of %0d packets emitted",
                                out_pkts, in_pkts));
    endtask

    task automatic do_reset();
        s_valid = 1'b0; bp_auto = 1'b0; m_ready_man = 1'b1;
        s_data = '0; s_keep = '0; s_last = 1'b0; s_user = '0;
        rst_n = 1'b0;
        repeat (3) begin @(posedge clk); #1; end
        if (m_valid !== 1'b0) note_fail("m_valid non-zero during reset (R1)");
        rst_n = 1'b1;
        @(posedge clk); #1;
        if (m_valid !== 1'b0) note_fail("m_valid non-zero in first cycle after reset (R1)");
        in_ptr = 0; in_pkts = 0; out_ptr = 0; out_pkts = 0;
    endtask

    task automatic sync_check(input string tag);
        if (in_pkts != out_pkts)
            note_fail($sformatf("%s ended desynced: %0d packets in, %0d out",
                                tag, in_pkts, out_pkts));
    endtask

    int L;

    initial begin
        // ---- illegal-parameter guard ----------------------------------
        if (S_BYTES != 1 && S_BYTES != 2 && S_BYTES != 4 && S_BYTES != 8) begin
            $display("TEST_RESULT: FAIL: illegal S_BYTES=%0d (legal: 1,2,4,8)", S_BYTES); $finish;
        end
        if (M_BYTES != 1 && M_BYTES != 2 && M_BYTES != 4 && M_BYTES != 8) begin
            $display("TEST_RESULT: FAIL: illegal M_BYTES=%0d (legal: 1,2,4,8)", M_BYTES); $finish;
        end
        if (USER_W < 1 || USER_W > 8) begin
            $display("TEST_RESULT: FAIL: illegal USER_W=%0d (legal: 1..8)", USER_W); $finish;
        end
        if ((S_BYTES % M_BYTES != 0) && (M_BYTES % S_BYTES != 0)) begin
            $display("TEST_RESULT: FAIL: illegal ratio S_BYTES=%0d M_BYTES=%0d", S_BYTES, M_BYTES); $finish;
        end

        // ------------------------------------------------------------------
        phase = "D1-reset";
        do_reset();
        idle_cycles(3);
        if (m_valid !== 1'b0) note_fail("m_valid asserted with no input offered (R1)");

        // ------------------------------------------------------------------
        // D2: smallest possible packet -- one byte. On an upsizing adapter this
        //     is the partial-first-and-last beat case.
        // ------------------------------------------------------------------
        phase = "D2-single-byte";
        send_packet(1, USER_W'(1), 0, 200);
        drain(2000);
        sync_check("D2");

        // ------------------------------------------------------------------
        // D3: exact-multiple packets -- no partial beat anywhere. Separates
        //     "handles the common case" from "handles the remainder".
        // ------------------------------------------------------------------
        phase = "D3-exact-multiple";
        L = (S_BYTES > M_BYTES ? S_BYTES : M_BYTES);
        send_packet(L,     USER_W'(0), 0, 400);
        send_packet(2*L,   USER_W'(1), 0, 400);
        send_packet(4*L,   USER_W'(0), 0, 400);
        drain(4000);
        sync_check("D3");

        // ------------------------------------------------------------------
        // D4: every remainder modulo the wider datapath. This is the partial
        //     final beat sweep, and the place an off-by-one in the keep
        //     generation shows up.
        // ------------------------------------------------------------------
        phase = "D4-remainder-sweep";
        for (int n = 1; n <= 4*L + 1; n++)
            send_packet(n, USER_W'(n[0]), 0, 800);
        drain(20000);
        sync_check("D4");

        // ------------------------------------------------------------------
        // D5: output backpressure held across packet boundaries
        // ------------------------------------------------------------------
        phase = "D5-backpressure";
        bp_auto = 1'b1; bp_weight = 70;
        for (int p = 0; p < 24; p++)
            send_packet(1 + (p % (3*L)), USER_W'(p[0]), 0, 4000);
        bp_auto = 1'b0; m_ready_man = 1'b1;
        drain(20000);
        sync_check("D5");

        // ------------------------------------------------------------------
        // D6: input gaps -- s_valid deasserted mid-packet
        // ------------------------------------------------------------------
        phase = "D6-input-gaps";
        for (int p = 0; p < 24; p++)
            send_packet(1 + (p % (3*L)), USER_W'(p[0]), 60, 4000);
        drain(20000);
        sync_check("D6");

        // ------------------------------------------------------------------
        // D7: reset asserted MID-PACKET must discard the partial packet (R3).
        //     A design that keeps a half-assembled beat across reset emits a
        //     corrupt first packet afterwards.
        // ------------------------------------------------------------------
        phase = "D7-reset-midpacket";
        bp_auto = 1'b0; m_ready_man = 1'b0;
        // drive one beat of a multi-beat packet, then reset with it in flight
        s_data = '0; s_keep = '1; s_last = 1'b0; s_user = '0; s_valid = 1'b1;
        for (int i = 0; i < S_BYTES; i++) s_data[i*8 +: 8] = 8'hA5;
        repeat (3) begin @(posedge clk); #1; end
        cov_reset_mid++;
        s_valid = 1'b0;
        rst_n = 1'b0;
        repeat (3) begin @(posedge clk); #1; end
        if (m_valid !== 1'b0) note_fail("m_valid survived reset (R3)");
        rst_n = 1'b1;
        m_ready_man = 1'b1;
        @(posedge clk); #1;
        in_ptr = 0; in_pkts = 0; out_ptr = 0; out_pkts = 0;   // fresh stream
        // a clean packet afterwards must be byte-exact
        send_packet(3*L + 1, USER_W'(1), 0, 4000);
        drain(20000);
        sync_check("D7");

        // ------------------------------------------------------------------
        // D8: reset while a COMPLETE output beat is pending and unaccepted.
        //     Distinct from D7: there the adapter is mid-assembly and m_valid
        //     is still low, so a reset that fails to clear the output-valid
        //     register has nothing to preserve and goes unnoticed. Here we
        //     first back up the output until m_valid is genuinely high, and
        //     only then reset. R1 requires m_valid==0 out of reset regardless
        //     of what was pending.
        // ------------------------------------------------------------------
        phase = "D8-reset-with-pending-output";
        // Distinct from D7: there the adapter is mid-assembly and m_valid is
        // still low, so a reset that fails to clear the output-valid register
        // has nothing to preserve and goes unnoticed. Here we first try to back
        // the output up until m_valid is genuinely high, then reset.
        //
        // The checker must not break its own input contract while doing it.
        // s_data is set ONCE and held (H2 forbids changing it under an
        // unaccepted beat), and s_valid is withdrawn only simultaneously with
        // reset (H2 forbids withdrawing it otherwise). A zero-storage
        // pass-through propagates its input straight to its output, so either
        // violation would show up as an H3 failure blamed on the DUT.
        bp_auto = 1'b0; m_ready_man = 1'b0;
        s_keep = '1; s_last = 1'b0; s_user = '0;
        for (int b = 0; b < S_BYTES; b++) s_data[b*8 +: 8] = 8'h5A + 8'(b);
        s_valid = 1'b1;
        for (int i = 0; i < 64; i++) begin
            @(posedge clk); #1;
            if (m_valid) break;
        end

        // Whether a completed beat can be held at all is an implementation
        // choice the spec does not constrain -- the reference's own S==M branch
        // wires s_ready straight to m_ready and therefore cannot. Record it,
        // do not require it.
        d8_reachable = (m_valid === 1'b1);
        if (d8_reachable) cov_reset_pending++;
        else $display("// note: DUT holds no output beat under backpressure; D8 precondition not applicable");

        // Reset regardless. R1 is unconditional: m_valid must be 0 while rst_n
        // is low, whatever was pending.
        rst_n = 1'b0;
        s_valid = 1'b0;
        repeat (3) begin @(posedge clk); #1; end
        if (m_valid !== 1'b0) note_fail("m_valid non-zero during reset (R1)");
        rst_n = 1'b1;
        m_ready_man = 1'b1;
        @(posedge clk); #1;
        if (m_valid !== 1'b0) note_fail("stale output beat emitted after reset (R3)");

        in_ptr = 0; in_pkts = 0; out_ptr = 0; out_pkts = 0;   // fresh stream
        send_packet(2*L + 1, USER_W'(0), 0, 4000);
        drain(20000);
        sync_check("D8");

        // ------------------------------------------------------------------
        // R1: randomised soak, traffic re-biased every 200 packets
        // ------------------------------------------------------------------
        phase = "R1-soak";
        begin
            int gap;
            for (int p = 0; p < SOAK_PACKETS; p++) begin
                case ((p / 200) % 4)
                    0: begin gap =  5; bp_weight =  5; end   // flat out
                    1: begin gap = 60; bp_weight = 10; end   // input-starved
                    2: begin gap =  5; bp_weight = 65; end   // output-blocked
                    3: begin gap = 40; bp_weight = 40; end   // both
                endcase
                bp_auto = 1'b1;
                send_packet(1 + $urandom_range(0, MAX_PKT_BEATS*S_BYTES - 1),
                            USER_W'($urandom_range(0, (1<<USER_W)-1)), gap, 8000);
                if ((p % 61) == 60) begin
                    bp_auto = 1'b0; m_ready_man = 1'b1;
                    drain(20000);
                end
            end
        end
        bp_auto = 1'b0; m_ready_man = 1'b1;
        drain(40000);
        sync_check("R1");

        // ------------------------------------------------------------------
        phase = "final";
        idle_cycles(4);

        $display("METRIC: packets=%0d bytes=%0d out_beats=%0d", out_pkts, out_ptr, beats_out);
        $display("METRIC: active_cycles=%0d beats_per_100cyc=%0d",
                 cycles_active, (cycles_active == 0) ? 0 : (beats_out*100)/cycles_active);
        $display("METRIC: backpressure_cycles=%0d input_stall_cycles=%0d", cov_bp, cov_in_stall);

        begin
            int cov_missing;
            cov_missing = 0;
            $display("// coverage: partial_last=%0d full_last=%0d single_beat=%0d multi_beat=%0d",
                     cov_partial_last, cov_full_last, cov_single_beat, cov_multi_beat);
            $display("// coverage: bp=%0d in_stall=%0d reset_mid=%0d gap=%0d minpkt=%0d bigpkt=%0d",
                     cov_bp, cov_in_stall, cov_reset_mid, cov_gap, cov_minpkt, cov_bigpkt);
            $display("// coverage: reset_pending=%0d", cov_reset_pending);
            if (cov_full_last    == 0) begin cov_missing++; $display("// COVERAGE HOLE: no packet ended on a full beat"); end
            if (cov_single_beat  == 0) begin cov_missing++; $display("// COVERAGE HOLE: no single-beat output packet"); end
            if (cov_multi_beat   == 0) begin cov_missing++; $display("// COVERAGE HOLE: no multi-beat output packet"); end
            if (cov_bp           == 0) begin cov_missing++; $display("// COVERAGE HOLE: output backpressure never applied"); end
            // cov_in_stall is deliberately NOT a coverage gate. Whether the
            // DUT ever deasserts s_ready is a function of how deeply it
            // buffers, and the spec constrains buffering nowhere -- R2 says
            // s_ready may be 0 or 1 and says nothing about depth. Gating on it
            // demanded a shallow implementation.
            //
            // Caught by the mandatory second source (Step 5): the alternative
            // implementation uses a 32-byte FIFO and, when upsizing from
            // S_BYTES=1, legitimately never fills it, so it never backpressures
            // the input and was failed by a checker it should have passed.
            // Reported as a METRIC instead.
            if (cov_reset_mid    == 0) begin cov_missing++; $display("// COVERAGE HOLE: no mid-packet reset"); end
            // Gated on reachability, not asserted unconditionally -- see D8.
            if (d8_reachable && cov_reset_pending == 0) begin cov_missing++; $display("// COVERAGE HOLE: no reset with a pending output beat"); end
            if (cov_gap          == 0) begin cov_missing++; $display("// COVERAGE HOLE: no input gap"); end
            if (cov_minpkt       == 0) begin cov_missing++; $display("// COVERAGE HOLE: no 1-byte packet"); end
            if (cov_bigpkt       == 0) begin cov_missing++; $display("// COVERAGE HOLE: no long multi-beat packet"); end
            // A partial final beat is only reachable when the output datapath is
            // wider than one byte; with M_BYTES==1 every beat is inherently full.
            if (M_BYTES > 1 && cov_partial_last == 0) begin
                cov_missing++; $display("// COVERAGE HOLE: no partial final output beat");
            end
            if (cov_missing > 0)
                note_fail($sformatf("%0d coverage holes -- run did not exercise the target hazards",
                                    cov_missing));
        end

        if (checks < MIN_CHECKS)
            note_fail($sformatf("insufficient coverage: only %0d checks executed", checks));

        if (errors == 0) $display("TEST_RESULT: PASS");
        else $display("TEST_RESULT: FAIL: %s (%0d failing checks of %0d)",
                      fail_reason, errors, checks);
        $finish;
    end

    initial begin
        #60_000_000;
        $display("// watchdog fired in phase=%s in_pkts=%0d out_pkts=%0d in_ptr=%0d out_ptr=%0d",
                 phase, in_pkts, out_pkts, in_ptr, out_ptr);
        $display("TEST_RESULT: FAIL: timeout -- checker did not complete (phase=%s)", phase);
        $finish;
    end

endmodule
