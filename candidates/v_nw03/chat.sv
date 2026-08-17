`timescale 1ns/1ps

module frame_arb_mux_tb;

    localparam int S_COUNT    = 4;
    localparam int DATA_WIDTH = 32;
    localparam int USER_WIDTH = 1;
    localparam int KEEP_WIDTH = DATA_WIDTH/8;

    logic clk_i;
    logic rst_i;

    logic [S_COUNT-1:0][DATA_WIDTH-1:0] s_tdata_i;
    logic [S_COUNT-1:0][KEEP_WIDTH-1:0] s_tkeep_i;
    logic [S_COUNT-1:0]                 s_tvalid_i;
    logic [S_COUNT-1:0]                 s_tready_o;
    logic [S_COUNT-1:0]                 s_tlast_i;
    logic [S_COUNT-1:0][USER_WIDTH-1:0] s_tuser_i;

    logic [DATA_WIDTH-1:0] m_tdata_o;
    logic [KEEP_WIDTH-1:0] m_tkeep_o;
    logic                  m_tvalid_o;
    logic                  m_tready_i;
    logic                  m_tlast_o;
    logic [USER_WIDTH-1:0] m_tuser_o;


    // ========================================================================
    // DUT
    // ========================================================================

    frame_arb_mux #(
        .S_COUNT    (S_COUNT),
        .DATA_WIDTH (DATA_WIDTH),
        .USER_WIDTH (USER_WIDTH)
    ) dut (
        .clk_i      (clk_i),
        .rst_i      (rst_i),

        .s_tdata_i  (s_tdata_i),
        .s_tkeep_i  (s_tkeep_i),
        .s_tvalid_i (s_tvalid_i),
        .s_tready_o (s_tready_o),
        .s_tlast_i  (s_tlast_i),
        .s_tuser_i  (s_tuser_i),

        .m_tdata_o  (m_tdata_o),
        .m_tkeep_o  (m_tkeep_o),
        .m_tvalid_o (m_tvalid_o),
        .m_tready_i (m_tready_i),
        .m_tlast_o  (m_tlast_o),
        .m_tuser_o  (m_tuser_o)
    );


    // ========================================================================
    // Clock
    // ========================================================================

    initial begin
        clk_i = 1'b0;
        forever #5 clk_i = ~clk_i;
    end


    // ========================================================================
    // Watchdog
    //
    // This is deliberately independent of all DUT progress.
    // ========================================================================

    integer failure_count;
    logic   finished;

    task automatic fail_req(
        input string req,
        input string msg
    );
        begin
            failure_count = failure_count + 1;
            $display("FAIL %s: %s", req, msg);
        end
    endtask

    task automatic finish_test;
        begin
            if (!finished) begin
                finished = 1'b1;

                if (failure_count == 0)
                    $display("RESULT: PASS");
                else
                    $display("RESULT: FAIL");

                $finish;
            end
        end
    endtask

    initial begin
        #2000000;

        if (!finished) begin
            fail_req(
                "S5",
                "watchdog expired; accepted traffic did not make required forward progress"
            );
            finish_test();
        end
    end


    // ========================================================================
    // Beat representation used by the scoreboard
    // ========================================================================

    typedef struct packed {
        logic [DATA_WIDTH-1:0] data;
        logic [KEEP_WIDTH-1:0] keep;
        logic                  last;
        logic [USER_WIDTH-1:0] user;
    } beat_t;

    beat_t expected_q[S_COUNT][$];

    // Beats discarded by reset are retained here solely so that stale output
    // after reset can be diagnosed specifically as S12.
    beat_t stale_q[$];


    // ========================================================================
    // Deterministic source generators
    //
    // The generated payload uniquely identifies:
    //
    //   reset generation / source / frame / beat
    //
    // This lets the scoreboard identify which input an output beat came from
    // WITHOUT using s_tready_o as an arbitration grant (S6).
    // ========================================================================

    logic   prod_active     [S_COUNT];
    logic   prod_continuous [S_COUNT];
    logic   prod_stop_req   [S_COUNT];

    integer prod_generation [S_COUNT];
    integer prod_frame_seq  [S_COUNT];
    integer prod_beat_idx   [S_COUNT];
    integer prod_frames_left[S_COUNT];

    integer accepted_count  [S_COUNT];


    function automatic integer frame_length(
        input integer src,
        input integer frame_no
    );
        begin
            // Produces lengths 1,2,3,4 and therefore explicitly exercises
            // single-beat frames as required by S2.
            frame_length = 1 + ((src + frame_no) % 4);
        end
    endfunction


    function automatic logic [31:0] make_data(
        input integer src,
        input integer generation,
        input integer frame_no,
        input integer beat_no
    );
        begin
            make_data = {
                8'hA5,
                generation[3:0],
                src[3:0],
                frame_no[7:0],
                beat_no[7:0]
            };
        end
    endfunction


    function automatic logic [KEEP_WIDTH-1:0] make_keep(
        input integer src,
        input integer frame_no,
        input integer beat_no
    );
        integer v;
        begin
            v = (src + frame_no + beat_no) % 7;

            case (v)
                0: make_keep = 4'b1111;
                1: make_keep = 4'b0001;
                2: make_keep = 4'b0011;
                3: make_keep = 4'b0101;
                4: make_keep = 4'b1010;
                5: make_keep = 4'b1000;
                default:
                   make_keep = 4'b0110;
            endcase
        end
    endfunction


    function automatic logic make_user(
        input integer src,
        input integer frame_no,
        input integer beat_no
    );
        begin
            make_user = (src ^ frame_no ^ beat_no) & 1;
        end
    endfunction


    integer gi;

    always_comb begin
        for (gi = 0; gi < S_COUNT; gi = gi + 1) begin

            s_tvalid_i[gi] = prod_active[gi];

            s_tdata_i[gi] =
                make_data(
                    gi,
                    prod_generation[gi],
                    prod_frame_seq[gi],
                    prod_beat_idx[gi]
                );

            s_tkeep_i[gi] =
                make_keep(
                    gi,
                    prod_frame_seq[gi],
                    prod_beat_idx[gi]
                );

            s_tuser_i[gi] =
                make_user(
                    gi,
                    prod_frame_seq[gi],
                    prod_beat_idx[gi]
                );

            s_tlast_i[gi] =
                (
                    prod_beat_idx[gi] ==
                    frame_length(
                        gi,
                        prod_frame_seq[gi]
                    ) - 1
                );
        end
    end


    // Advance a source ONLY after a real input transfer (S1).
    //
    // Otherwise every source field remains unchanged, satisfying the
    // testbench obligation in S7.
    integer pi;

    always @(posedge clk_i) begin
        for (pi = 0; pi < S_COUNT; pi = pi + 1) begin

            if (
                prod_active[pi] &&
                s_tvalid_i[pi] &&
                s_tready_o[pi]
            ) begin

                accepted_count[pi] <= accepted_count[pi] + 1;

                if (s_tlast_i[pi]) begin

                    prod_beat_idx[pi] <= 0;

                    if (
                        prod_continuous[pi] &&
                        !prod_stop_req[pi]
                    ) begin

                        prod_frame_seq[pi] <=
                            prod_frame_seq[pi] + 1;

                    end
                    else if (
                        prod_continuous[pi] &&
                        prod_stop_req[pi]
                    ) begin

                        // Stop only at a frame boundary so the testbench
                        // itself never truncates a frame.
                        prod_active[pi] <= 1'b0;

                    end
                    else if (prod_frames_left[pi] > 1) begin

                        prod_frames_left[pi] <=
                            prod_frames_left[pi] - 1;

                        prod_frame_seq[pi] <=
                            prod_frame_seq[pi] + 1;

                    end
                    else begin

                        prod_frames_left[pi] <= 0;
                        prod_active[pi]      <= 1'b0;

                    end

                end
                else begin

                    prod_beat_idx[pi] <=
                        prod_beat_idx[pi] + 1;

                end
            end
        end
    end


    // ========================================================================
    // Output-ready generation
    //
    // Backpressure phase intentionally contains multi-cycle stalls.
    // Other phases can force READY high.
    // ========================================================================

    logic   force_ready;
    logic   backpressure_enable;
    integer cycle_count;

    always @(posedge clk_i)
        cycle_count <= cycle_count + 1;

    always_comb begin
        if (force_ready) begin
            m_tready_i = 1'b1;
        end
        else if (backpressure_enable) begin

            // Several consecutive low-ready cycles occur in each pattern.
            if (
                ((cycle_count % 17) >= 5) &&
                ((cycle_count % 17) <= 9)
            )
                m_tready_i = 1'b0;
            else if (
                ((cycle_count % 31) >= 21) &&
                ((cycle_count % 31) <= 24)
            )
                m_tready_i = 1'b0;
            else
                m_tready_i = 1'b1;

        end
        else begin
            m_tready_i = 1'b0;
        end
    end


    // ========================================================================
    // Input source-obligation checker -- S7
    //
    // This is primarily a guard against a bug in this testbench.
    // ========================================================================

    logic [S_COUNT-1:0]                 prev_s_valid;
    logic [S_COUNT-1:0]                 prev_s_ready;
    logic [S_COUNT-1:0][DATA_WIDTH-1:0] prev_s_data;
    logic [S_COUNT-1:0][KEEP_WIDTH-1:0] prev_s_keep;
    logic [S_COUNT-1:0]                 prev_s_last;
    logic [S_COUNT-1:0][USER_WIDTH-1:0] prev_s_user;

    integer si;

    always @(posedge clk_i) begin

        if (!rst_i) begin
            for (si = 0; si < S_COUNT; si = si + 1) begin

                if (
                    prev_s_valid[si] &&
                    !prev_s_ready[si]
                ) begin

                    if (!s_tvalid_i[si])
                        fail_req(
                            "S7",
                            "testbench source deasserted VALID before transfer"
                        );

                    if (
                        (s_tdata_i[si] != prev_s_data[si]) ||
                        (s_tkeep_i[si] != prev_s_keep[si]) ||
                        (s_tlast_i[si] != prev_s_last[si]) ||
                        (s_tuser_i[si] != prev_s_user[si])
                    )
                        fail_req(
                            "S7",
                            "testbench changed a source beat while VALID was stalled"
                        );
                end
            end
        end

        prev_s_valid <= s_tvalid_i;
        prev_s_ready <= s_tready_o;
        prev_s_data  <= s_tdata_i;
        prev_s_keep  <= s_tkeep_i;
        prev_s_last  <= s_tlast_i;
        prev_s_user  <= s_tuser_i;
    end


    // ========================================================================
    // Output stall stability -- S8 / AXI4-Stream backpressure
    // ========================================================================

    logic                  prev_m_valid;
    logic                  prev_m_ready;
    logic [DATA_WIDTH-1:0] prev_m_data;
    logic [KEEP_WIDTH-1:0] prev_m_keep;
    logic                  prev_m_last;
    logic [USER_WIDTH-1:0] prev_m_user;

    always @(posedge clk_i) begin

        if (
            !rst_i &&
            prev_m_valid &&
            !prev_m_ready
        ) begin

            if (!m_tvalid_o)
                fail_req(
                    "S8",
                    "m_tvalid_o dropped while an output beat was backpressured"
                );

            if (
                (m_tdata_o != prev_m_data) ||
                (m_tkeep_o != prev_m_keep) ||
                (m_tlast_o != prev_m_last) ||
                (m_tuser_o != prev_m_user)
            )
                fail_req(
                    "S8",
                    "output beat changed while m_tvalid_o was stalled by m_tready_i"
                );
        end

        prev_m_valid <= m_tvalid_o;
        prev_m_ready <= m_tready_i;
        prev_m_data  <= m_tdata_o;
        prev_m_keep  <= m_tkeep_o;
        prev_m_last  <= m_tlast_o;
        prev_m_user  <= m_tuser_o;
    end


    // ========================================================================
    // Scoreboard
    //
    // Each INPUT transfer appends to that input's queue.
    //
    // On the first transferred OUTPUT beat of a frame, the checker searches
    // only the HEAD beat of each input queue. This imposes no arbitration
    // order and does not use READY as a grant (S6/S9).
    //
    // Once a non-last first beat transfers, frame_source_locked is asserted.
    // Every following transferred output beat must then come from that same
    // input until TLAST (S3).
    // ========================================================================

    logic   frame_source_locked;
    integer locked_source;

    integer current_frame_source;

    logic fairness_enable;
    integer fair_completed_frames;
    integer fairness_window[$];

    integer qi;
    integer qj;


    function automatic logic beat_equal(
        input beat_t x,
        input beat_t y
    );
        begin
            beat_equal =
                (x.data == y.data) &&
                (x.keep == y.keep) &&
                (x.last == y.last) &&
                (x.user == y.user);
        end
    endfunction


    task automatic record_completed_frame(
        input integer src
    );
        integer wi;
        integer wj;
        logic found;
        begin
            if (fairness_enable) begin

                fairness_window.push_back(src);
                fair_completed_frames =
                    fair_completed_frames + 1;

                if (fairness_window.size() > 16)
                    void'(fairness_window.pop_front());

                // S10:
                // In EVERY window of 16 consecutive completed frames,
                // every continuously-loaded input must have begun a frame.
                if (fairness_window.size() == 16) begin

                    for (wi = 0; wi < S_COUNT; wi = wi + 1) begin

                        found = 1'b0;

                        for (
                            wj = 0;
                            wj < fairness_window.size();
                            wj = wj + 1
                        ) begin
                            if (fairness_window[wj] == wi)
                                found = 1'b1;
                        end

                        if (!found)
                            fail_req(
                                "S10",
                                $sformatf(
                                    "input %0d did not begin a frame in a window of 16 completed frames",
                                    wi
                                )
                            );
                    end
                end
            end
        end
    endtask


    always @(posedge clk_i) begin : scoreboard

        beat_t in_beat;
        beat_t out_beat;

        integer src;
        integer match_src;
        integer other_src;

        logic found_match;
        logic found_other;
        logic stale_match;


        // --------------------------------------------------------------------
        // RESET -- S12
        //
        // Anything accepted before reset is discarded.
        // Anything accepted while reset is asserted is also discarded.
        // --------------------------------------------------------------------
        if (rst_i) begin

            frame_source_locked <= 1'b0;
            locked_source       <= -1;
            current_frame_source <= -1;

            for (src = 0; src < S_COUNT; src = src + 1) begin

                while (expected_q[src].size() != 0)
                    stale_q.push_back(expected_q[src].pop_front());

                // A beat transferring during reset must not emerge later.
                if (s_tvalid_i[src] && s_tready_o[src]) begin

                    in_beat.data = s_tdata_i[src];
                    in_beat.keep = s_tkeep_i[src];
                    in_beat.last = s_tlast_i[src];
                    in_beat.user = s_tuser_i[src];

                    stale_q.push_back(in_beat);
                end
            end

        end

        else begin

            // ----------------------------------------------------------------
            // Capture every real input transfer -- S1, S4, S5.
            //
            // Input capture occurs before output matching intentionally:
            // a legal zero-latency implementation may accept and emit a beat
            // on the same clock edge.
            // ----------------------------------------------------------------
            for (src = 0; src < S_COUNT; src = src + 1) begin

                if (s_tvalid_i[src] && s_tready_o[src]) begin

                    in_beat.data = s_tdata_i[src];
                    in_beat.keep = s_tkeep_i[src];
                    in_beat.last = s_tlast_i[src];
                    in_beat.user = s_tuser_i[src];

                    expected_q[src].push_back(in_beat);
                end
            end


            // ----------------------------------------------------------------
            // Output transfer -- S1
            // ----------------------------------------------------------------
            if (m_tvalid_o && m_tready_i) begin

                out_beat.data = m_tdata_o;
                out_beat.keep = m_tkeep_o;
                out_beat.last = m_tlast_o;
                out_beat.user = m_tuser_o;


                // ============================================================
                // Already inside a frame: ONLY the locked source is legal.
                // ============================================================
                if (frame_source_locked) begin

                    if (expected_q[locked_source].size() == 0) begin

                        // Check whether the beat is actually from another
                        // source, allowing an explicit S3 diagnosis.
                        found_other = 1'b0;

                        for (
                            other_src = 0;
                            other_src < S_COUNT;
                            other_src = other_src + 1
                        ) begin

                            if (
                                (other_src != locked_source) &&
                                (expected_q[other_src].size() != 0) &&
                                beat_equal(
                                    out_beat,
                                    expected_q[other_src][0]
                                )
                            )
                                found_other = 1'b1;
                        end

                        if (found_other)
                            fail_req(
                                "S3",
                                "output switched inputs before the current frame completed"
                            );
                        else
                            fail_req(
                                "S5",
                                "output produced a beat when the selected input had no corresponding accepted beat"
                            );

                    end

                    else if (
                        !beat_equal(
                            out_beat,
                            expected_q[locked_source][0]
                        )
                    ) begin

                        found_other = 1'b0;

                        for (
                            other_src = 0;
                            other_src < S_COUNT;
                            other_src = other_src + 1
                        ) begin

                            if (
                                (other_src != locked_source) &&
                                (expected_q[other_src].size() != 0) &&
                                beat_equal(
                                    out_beat,
                                    expected_q[other_src][0]
                                )
                            )
                                found_other = 1'b1;
                        end

                        if (found_other) begin

                            fail_req(
                                "S3",
                                "beat from another input appeared in the middle of a frame"
                            );

                        end
                        else begin

                            fail_req(
                                "S4",
                                "output payload/TKEEP/TUSER/TLAST did not equal the next accepted beat of the active input"
                            );

                        end

                    end

                    else begin

                        // Correct next beat of the locked frame.
                        void'(expected_q[locked_source].pop_front());

                        if (out_beat.last) begin

                            record_completed_frame(
                                locked_source
                            );

                            frame_source_locked <= 1'b0;
                            locked_source       <= -1;
                            current_frame_source <= -1;

                        end
                    end
                end


                // ============================================================
                // No frame active: any input's HEAD beat may legally be next.
                // ============================================================
                else begin

                    found_match = 1'b0;
                    match_src   = -1;

                    for (
                        src = 0;
                        src < S_COUNT;
                        src = src + 1
                    ) begin

                        if (
                            !found_match &&
                            (expected_q[src].size() != 0) &&
                            beat_equal(
                                out_beat,
                                expected_q[src][0]
                            )
                        ) begin

                            found_match = 1'b1;
                            match_src   = src;

                        end
                    end


                    if (!found_match) begin

                        // Was this a beat that reset explicitly discarded?
                        stale_match = 1'b0;

                        for (
                            qj = 0;
                            qj < stale_q.size();
                            qj = qj + 1
                        ) begin

                            if (beat_equal(out_beat, stale_q[qj]))
                                stale_match = 1'b1;

                        end

                        if (stale_match) begin

                            fail_req(
                                "S12",
                                "a beat accepted before or during reset appeared after reset"
                            );

                        end
                        else begin

                            // Could be corruption, duplication, or an output
                            // with no accepted input counterpart.
                            fail_req(
                                "S4",
                                "output beat did not match the head beat of any input stream"
                            );

                            fail_req(
                                "S5",
                                "output beat had no unique unconsumed accepted-input counterpart"
                            );

                        end

                    end

                    else begin

                        void'(expected_q[match_src].pop_front());

                        current_frame_source <= match_src;

                        if (out_beat.last) begin

                            // Single-beat frame -- S2.
                            record_completed_frame(
                                match_src
                            );

                            current_frame_source <= -1;

                        end
                        else begin

                            // Frame now becomes atomic to this source -- S3.
                            frame_source_locked <= 1'b1;
                            locked_source       <= match_src;

                        end
                    end
                end
            end
        end
    end


    // ========================================================================
    // Reset-idle observation
    //
    // Checked on falling edges so the synchronous-reset state update from the
    // preceding rising edge has completed.
    // ========================================================================

    logic reset_idle_failure_reported;

    always @(negedge clk_i) begin
        if (
            rst_i &&
            m_tvalid_o &&
            !reset_idle_failure_reported
        ) begin

            reset_idle_failure_reported = 1'b1;

            fail_req(
                "S12",
                "m_tvalid_o was high while the synchronously-reset design should be idle"
            );
        end
    end


    // ========================================================================
    // End quickly after any detected fault.
    //
    // The independent watchdog remains necessary for faults that simply stop
    // making progress and never directly violate a sampled property.
    // ========================================================================

    always @(negedge clk_i) begin
        if (
            (failure_count != 0) &&
            !finished
        )
            finish_test();
    end


    // ========================================================================
    // Main stimulus
    // ========================================================================

    integer i;
    integer base_accept;
    logic   drained;


    initial begin

        failure_count = 0;
        finished      = 1'b0;

        rst_i = 1'b1;

        force_ready        = 1'b1;
        backpressure_enable = 1'b0;

        cycle_count = 0;

        fairness_enable         = 1'b0;
        fair_completed_frames   = 0;

        frame_source_locked  = 1'b0;
        locked_source        = -1;
        current_frame_source = -1;

        reset_idle_failure_reported = 1'b0;

        prev_s_valid = '0;
        prev_s_ready = '0;
        prev_s_data  = '0;
        prev_s_keep  = '0;
        prev_s_last  = '0;
        prev_s_user  = '0;

        prev_m_valid = 1'b0;
        prev_m_ready = 1'b0;
        prev_m_data  = '0;
        prev_m_keep  = '0;
        prev_m_last  = 1'b0;
        prev_m_user  = '0;


        for (i = 0; i < S_COUNT; i = i + 1) begin

            prod_active[i]      = 1'b0;
            prod_continuous[i]  = 1'b0;
            prod_stop_req[i]    = 1'b0;

            prod_generation[i]  = 0;
            prod_frame_seq[i]   = 0;
            prod_beat_idx[i]    = 0;
            prod_frames_left[i] = 0;

            accepted_count[i]   = 0;

        end


        // ====================================================================
        // INITIAL RESET -- S12
        // ====================================================================

        repeat (4)
            @(posedge clk_i);

        @(negedge clk_i);
        rst_i = 1'b0;

        // First active clock after reset release.
        @(posedge clk_i);
        @(negedge clk_i);

        if (m_tvalid_o)
            fail_req(
                "S12",
                "m_tvalid_o was not low on the first cycle after reset release"
            );


        // ====================================================================
        // PHASE 1:
        //
        // Finite traffic from all four inputs with:
        //   - single and multi-beat frames
        //   - varied TKEEP/TUSER
        //   - sustained output backpressure
        //
        // No arbitration-order or latency assumption is made.
        // ====================================================================

        force_ready         = 1'b0;
        backpressure_enable = 1'b1;

        for (i = 0; i < S_COUNT; i = i + 1) begin

            prod_generation[i]  = 1;
            prod_frame_seq[i]   = 0;
            prod_beat_idx[i]    = 0;

            prod_continuous[i]  = 1'b0;
            prod_stop_req[i]    = 1'b0;

            // Different finite quantities prevent accidental symmetry.
            prod_frames_left[i] = 6 + i;
            prod_active[i]      = 1'b1;

        end


        // Wait until every source has finished OFFERING its complete frames.
        while (
            prod_active[0] ||
            prod_active[1] ||
            prod_active[2] ||
            prod_active[3]
        )
            @(negedge clk_i);


        // Wait for every accepted beat to emerge.
        //
        // No finite latency bound is imposed (S11). A design that loses a beat
        // will eventually be caught by the independent watchdog as S5.
        drained = 1'b0;

        while (!drained) begin
            @(negedge clk_i);

            drained =
                (expected_q[0].size() == 0) &&
                (expected_q[1].size() == 0) &&
                (expected_q[2].size() == 0) &&
                (expected_q[3].size() == 0) &&
                !frame_source_locked;
        end


        // ====================================================================
        // PHASE 2:
        //
        // Reset while traffic exists.
        // Any accepted-but-not-yet-emitted traffic must disappear permanently.
        // ====================================================================

        force_ready         = 1'b1;
        backpressure_enable = 1'b0;

        @(negedge clk_i);

        prod_generation[0]  = 2;
        prod_frame_seq[0]   = 0;
        prod_beat_idx[0]    = 0;
        prod_frames_left[0] = 8;
        prod_continuous[0]  = 1'b0;
        prod_stop_req[0]    = 1'b0;
        prod_active[0]      = 1'b1;

        base_accept = accepted_count[0];

        // Establish real pre-reset accepted traffic.
        while (accepted_count[0] < base_accept + 3)
            @(negedge clk_i);


        // Assert synchronous reset.
        @(negedge clk_i);
        rst_i = 1'b1;

        // Leave the source active during reset for two clocks. Any transfers
        // during this interval must also be discarded by S12.
        repeat (2)
            @(posedge clk_i);

        @(negedge clk_i);
        prod_active[0] = 1'b0;

        repeat (2)
            @(posedge clk_i);

        @(negedge clk_i);
        rst_i = 1'b0;

        // Explicit first-cycle-after-release check.
        @(posedge clk_i);
        @(negedge clk_i);

        if (m_tvalid_o)
            fail_req(
                "S12",
                "m_tvalid_o was high on the first cycle after the second reset release"
            );


        // Send post-reset traffic with a different generation identifier.
        for (i = 0; i < S_COUNT; i = i + 1) begin

            prod_generation[i]  = 3;
            prod_frame_seq[i]   = 0;
            prod_beat_idx[i]    = 0;

            prod_frames_left[i] = 4;
            prod_continuous[i]  = 1'b0;
            prod_stop_req[i]    = 1'b0;
            prod_active[i]      = 1'b1;

        end


        while (
            prod_active[0] ||
            prod_active[1] ||
            prod_active[2] ||
            prod_active[3]
        )
            @(negedge clk_i);


        drained = 1'b0;

        while (!drained) begin
            @(negedge clk_i);

            drained =
                (expected_q[0].size() == 0) &&
                (expected_q[1].size() == 0) &&
                (expected_q[2].size() == 0) &&
                (expected_q[3].size() == 0) &&
                !frame_source_locked;
        end


        // ====================================================================
        // PHASE 3:
        //
        // S10 bounded-fairness test.
        //
        // Preconditions are maintained exactly:
        //
        //   * every input VALID continuously
        //   * every input has further complete frames available
        //   * m_tready_i continuously high
        //
        // We check every rolling window of 16 completed output frames.
        // ====================================================================

        @(negedge clk_i);

        force_ready         = 1'b1;
        backpressure_enable = 1'b0;

        fairness_window.delete();
        fair_completed_frames = 0;
        fairness_enable       = 1'b1;

        for (i = 0; i < S_COUNT; i = i + 1) begin

            prod_generation[i] = 4;
            prod_frame_seq[i]  = 0;
            prod_beat_idx[i]   = 0;

            prod_continuous[i] = 1'b1;
            prod_stop_req[i]   = 1'b0;
            prod_active[i]     = 1'b1;

        end


        // Forty completed frames gives 25 separate rolling windows of 16.
        while (fair_completed_frames < 40)
            @(negedge clk_i);


        // End the fairness observation before withdrawing continuous load.
        fairness_enable = 1'b0;

        // Ask each producer to stop only after finishing its current frame.
        for (i = 0; i < S_COUNT; i = i + 1)
            prod_stop_req[i] = 1'b1;


        while (
            prod_active[0] ||
            prod_active[1] ||
            prod_active[2] ||
            prod_active[3]
        )
            @(negedge clk_i);


        // Drain everything that transferred on an input before producers
        // stopped. This is the final S4/S5 accounting check.
        drained = 1'b0;

        while (!drained) begin
            @(negedge clk_i);

            drained =
                (expected_q[0].size() == 0) &&
                (expected_q[1].size() == 0) &&
                (expected_q[2].size() == 0) &&
                (expected_q[3].size() == 0) &&
                !frame_source_locked;
        end


        // A few idle clocks are intentionally allowed. Nothing is checked
        // about payload values while m_tvalid_o is low.
        repeat (4)
            @(posedge clk_i);


        finish_test();
    end

endmodule