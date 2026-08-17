`timescale 1ns/1ps

module frame_arb_mux_tb;

    // ------------------------------------------------------------------------
    // Parameters & Signals
    // ------------------------------------------------------------------------
    parameter int S_COUNT    = 4;
    parameter int DATA_WIDTH = 32;
    parameter int USER_WIDTH = 1;
    parameter int KEEP_WIDTH = DATA_WIDTH / 8;

    logic clk = 0;
    logic rst = 1;

    logic [S_COUNT-1:0][DATA_WIDTH-1:0]     s_tdata;
    logic [S_COUNT-1:0][KEEP_WIDTH-1:0]     s_tkeep;
    logic [S_COUNT-1:0]                     s_tvalid;
    logic [S_COUNT-1:0]                     s_tready;
    logic [S_COUNT-1:0]                     s_tlast;
    logic [S_COUNT-1:0][USER_WIDTH-1:0]     s_tuser;

    logic [DATA_WIDTH-1:0]                  m_tdata;
    logic [KEEP_WIDTH-1:0]                  m_tkeep;
    logic                                   m_tvalid;
    logic                                   m_tready;
    logic                                   m_tlast;
    logic [USER_WIDTH-1:0]                  m_tuser;

    // ------------------------------------------------------------------------
    // DUT Instantiation
    // ------------------------------------------------------------------------
    frame_arb_mux #(
        .S_COUNT(S_COUNT),
        .DATA_WIDTH(DATA_WIDTH),
        .USER_WIDTH(USER_WIDTH)
    ) dut (
        .clk_i(clk),
        .rst_i(rst),
        .s_tdata_i(s_tdata),
        .s_tkeep_i(s_tkeep),
        .s_tvalid_i(s_tvalid),
        .s_tready_o(s_tready),
        .s_tlast_i(s_tlast),
        .s_tuser_i(s_tuser),
        .m_tdata_o(m_tdata),
        .m_tkeep_o(m_tkeep),
        .m_tvalid_o(m_tvalid),
        .m_tready_i(m_tready),
        .m_tlast_o(m_tlast),
        .m_tuser_o(m_tuser)
    );

    // ------------------------------------------------------------------------
    // Infrastructure
    // ------------------------------------------------------------------------
    always #5 clk = ~clk;

    task fail();
        $display("RESULT: FAIL");
        $finish;
    endtask

    // Watchdog to ensure unconditional termination
    initial begin
        #500000;
        $display("Timeout: Watchdog triggered. Likely a stall or lost packet.");
        fail();
    end

    // ------------------------------------------------------------------------
    // Reference Model & Structures
    // ------------------------------------------------------------------------
    typedef struct packed {
        logic [DATA_WIDTH-1:0] tdata;
        logic [KEEP_WIDTH-1:0] tkeep;
        logic [USER_WIDTH-1:0] tuser;
        logic                  tlast;
    } beat_t;

    beat_t ref_queues [S_COUNT][$];

    logic continuous_load_mode = 0;
    logic load_stable = 0;
    logic stop_generation = 0;
    int   frames_completed = 0;

    // ------------------------------------------------------------------------
    // Input Stimulus (State Machine for race-free driving & S7 compliance)
    // ------------------------------------------------------------------------
    int frame_len [S_COUNT];
    int beat_cnt  [S_COUNT];
    int frame_cnt [S_COUNT];
    int delay_cnt [S_COUNT];

    typedef enum {IDLE, DRIVE, DELAY} state_t;
    state_t state [S_COUNT];

    always @(posedge clk) begin
        if (rst) begin
            for (int i = 0; i < S_COUNT; i++) begin
                s_tvalid[i] <= 0;
                state[i]    <= IDLE;
                frame_cnt[i]<= 0;
            end
        end else begin
            for (int i = 0; i < S_COUNT; i++) begin
                if (stop_generation) begin
                    s_tvalid[i] <= 0;
                    state[i]    <= IDLE;
                end else begin
                    case (state[i])
                        IDLE: begin
                            frame_len[i] = $urandom_range(1, 10);
                            beat_cnt[i]  = 0;
                            state[i]     <= DRIVE;
                            s_tvalid[i]  <= 1;
                            
                            // Tag: [31:28] = source_id, [27:16] = frame_cnt, [15:0] = beat_cnt
                            s_tdata[i]   <= {i[3:0], frame_cnt[i][11:0], 16'd0};
                            s_tkeep[i]   <= $urandom;
                            s_tuser[i]   <= $urandom;
                            s_tlast[i]   <= (frame_len[i] == 1);
                        end

                        DRIVE: begin
                            // Hold S7 stable until transfer
                            if (s_tvalid[i] && s_tready[i]) begin
                                beat_cnt[i]++;
                                if (beat_cnt[i] == frame_len[i]) begin
                                    // Frame complete
                                    frame_cnt[i]++;
                                    if (continuous_load_mode) begin
                                        // Immediately start next frame to ensure continuous load
                                        frame_len[i] = $urandom_range(1, 10);
                                        beat_cnt[i]  = 0;
                                        s_tvalid[i]  <= 1;
                                        s_tdata[i]   <= {i[3:0], frame_cnt[i][11:0], 16'd0};
                                        s_tkeep[i]   <= $urandom;
                                        s_tuser[i]   <= $urandom;
                                        s_tlast[i]   <= (frame_len[i] == 1);
                                    end else begin
                                        s_tvalid[i] <= 0;
                                        delay_cnt[i] = $urandom_range(0, 5);
                                        if (delay_cnt[i] == 0) state[i] <= IDLE;
                                        else                   state[i] <= DELAY;
                                    end
                                end else begin
                                    // Advance to next beat in frame
                                    s_tdata[i] <= {i[3:0], frame_cnt[i][11:0], beat_cnt[i][15:0]};
                                    s_tkeep[i] <= $urandom;
                                    s_tuser[i] <= $urandom;
                                    s_tlast[i] <= (beat_cnt[i] == frame_len[i] - 1);
                                end
                            end
                        end

                        DELAY: begin
                            delay_cnt[i]--;
                            if (delay_cnt[i] == 0) state[i] <= IDLE;
                        end
                    endcase
                end
            end
        end
    end

    // ------------------------------------------------------------------------
    // Synchronous Transfer Recording
    // ------------------------------------------------------------------------
    always @(posedge clk) begin
        if (rst) begin
            for (int i = 0; i < S_COUNT; i++) ref_queues[i].delete();
        end else begin
            for (int i = 0; i < S_COUNT; i++) begin
                if (s_tvalid[i] && s_tready[i]) begin
                    beat_t b;
                    b.tdata = s_tdata[i];
                    b.tkeep = s_tkeep[i];
                    b.tuser = s_tuser[i];
                    b.tlast = s_tlast[i];
                    ref_queues[i].push_back(b);
                end
            end
        end
    end

    // ------------------------------------------------------------------------
    // Backpressure Driver (S8)
    // ------------------------------------------------------------------------
    always @(posedge clk) begin
        if (rst) m_tready <= 0;
        else if (continuous_load_mode) m_tready <= 1; // S10 requires high m_tready
        else m_tready <= ($urandom_range(0, 100) < 70); // 70% ready rate
    end

    // ------------------------------------------------------------------------
    // Output Monitor & Checks
    // ------------------------------------------------------------------------
    int current_source = -1;
    bit in_frame = 0;
    int frame_history[$];
    logic rst_q;

    always @(posedge clk) rst_q <= rst;

    always @(posedge clk) begin
        if (rst) begin
            in_frame <= 0;
            current_source <= -1;
            frame_history.delete();
        end else begin
            // S12 Reset Check: Outputs must be quiet immediately after reset
            if (rst_q && !rst) begin
                if (m_tvalid !== 1'b0) begin
                    $display("S12: m_tvalid_o is not low on the first cycle after reset release");
                    fail();
                end
            end

            if (m_tvalid && m_tready) begin
                int src = m_tdata[31:28];

                // S3 Check: Atomicity
                if (!in_frame) begin
                    current_source = src;
                    in_frame = 1;
                end else begin
                    if (src != current_source) begin
                        $display("S3: Frame atomicity violated! Expected src %0d, got %0d", current_source, src);
                        fail();
                    end
                end

                // S4 & S5 Check: Integrity, order, and ghost beats
                if (ref_queues[src].size() == 0) begin
                    $display("S5: Unexpected output beat from src %0d (or duplicate/stale beat)", src);
                    fail();
                end else begin
                    beat_t exp = ref_queues[src].pop_front();
                    if (exp.tdata !== m_tdata) begin $display("S4: tdata mismatch"); fail(); end
                    if (exp.tkeep !== m_tkeep) begin $display("S4: tkeep mismatch"); fail(); end
                    if (exp.tuser !== m_tuser) begin $display("S4: tuser mismatch"); fail(); end
                    if (exp.tlast !== m_tlast) begin $display("S4: tlast mismatch"); fail(); end
                end

                if (m_tlast) begin
                    in_frame = 0;
                    frames_completed++;

                    // S10 Check: Bounded Fairness (tracked on frame completion)
                    if (continuous_load_mode && load_stable) begin
                        int dummy;
                        frame_history.push_back(current_source);
                        if (frame_history.size() > 16) dummy = frame_history.pop_front();
                        
                        if (frame_history.size() == 16) begin
                            int counts[S_COUNT];
                            for (int i = 0; i < S_COUNT; i++) counts[i] = 0;
                            foreach (frame_history[i]) counts[frame_history[i]]++;
                            
                            for (int i = 0; i < S_COUNT; i++) begin
                                if (counts[i] == 0) begin
                                    $display("S10: Source %0d was starved during a 16-frame window under continuous load", i);
                                    fail();
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    // ------------------------------------------------------------------------
    // Main Test Sequence
    // ------------------------------------------------------------------------
    initial begin
        rst = 1;
        continuous_load_mode = 0;
        load_stable = 0;
        stop_generation = 0;
        frames_completed = 0;

        repeat(15) @(posedge clk);
        rst = 0;

        // Phase 1: Normal traffic with random backpressure
        wait(frames_completed > 50);

        // Phase 2: Assert Reset Mid-Flight to test S12
        @(posedge clk);
        rst = 1;
        repeat(10) @(posedge clk);
        rst = 0;
        frames_completed = 0;

        // Phase 3: Traffic resumes
        wait(frames_completed > 20);

        // Phase 4: Continuous Load mode (Tests S10 bounded fairness)
        continuous_load_mode = 1;
        repeat(50) @(posedge clk); // Give drivers time to saturate links
        load_stable = 1;
        
        frames_completed = 0;
        wait(frames_completed > 200); // Plenty of time to fill 16-frame windows

        // Phase 5: Drain and Shutdown
        stop_generation = 1;

        fork
            begin
                // Wait for all state machines to return to IDLE and queues to clear
                for (int i = 0; i < S_COUNT; i++) begin
                    wait(state[i] == IDLE);
                    wait(ref_queues[i].size() == 0);
                end
            end
            begin
                repeat(10000) @(posedge clk);
                $display("S5: Drain timeout. Lost beats or design stalled.");
                fail();
            end
        join_any

        // Verify no stray beats or leftover state
        for (int i = 0; i < S_COUNT; i++) begin
            if (ref_queues[i].size() != 0) begin
                $display("S5: Queue %0d not empty after drain", i);
                fail();
            end
        end

        $display("RESULT: PASS");
        $finish;
    end

endmodule