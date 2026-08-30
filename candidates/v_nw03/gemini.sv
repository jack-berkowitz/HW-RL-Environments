module frame_arb_mux_tb;

    localparam int S_COUNT = 4;
    localparam int DATA_WIDTH = 32;
    localparam int USER_WIDTH = 1;

    logic                                   clk;
    logic                                   rst;

    logic [S_COUNT-1:0][DATA_WIDTH-1:0]     s_tdata;
    logic [S_COUNT-1:0][(DATA_WIDTH/8)-1:0] s_tkeep;
    logic [S_COUNT-1:0]                     s_tvalid;
    logic [S_COUNT-1:0]                     s_tready;
    logic [S_COUNT-1:0]                     s_tlast;
    logic [S_COUNT-1:0][USER_WIDTH-1:0]     s_tuser;

    logic [DATA_WIDTH-1:0]                  m_tdata;
    logic [(DATA_WIDTH/8)-1:0]              m_tkeep;
    logic                                   m_tvalid;
    logic                                   m_tready;
    logic                                   m_tlast;
    logic [USER_WIDTH-1:0]                  m_tuser;

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

    // ---------------------------------------------------------------------------
    // PROVIDED PLUMBING -- moves beats, checks nothing.
    // ---------------------------------------------------------------------------
    initial begin clk = 1'b0; forever #5 clk = ~clk; end
    initial rst = 1'b1;

    task automatic bfm_reset(input int cycles = 4);
        @(negedge clk);
        rst = 1'b1;
        repeat (cycles) @(posedge clk);
        @(negedge clk);
        rst = 1'b0;
    endtask

    task automatic bfm_send(input int                          k,
                            input logic [DATA_WIDTH-1:0]       data,
                            input logic [(DATA_WIDTH/8)-1:0]   keep,
                            input logic                        last,
                            input logic [USER_WIDTH-1:0]       user);
        @(negedge clk);
        s_tdata[k]  = data;
        s_tkeep[k]  = keep;
        s_tlast[k]  = last;
        s_tuser[k]  = user;
        s_tvalid[k] = 1'b1;
        forever begin
            @(posedge clk);
            if (s_tready[k]) break;
        end
    endtask

    task automatic bfm_idle(input int k);
        @(negedge clk);
        s_tvalid[k] = 1'b0;
    endtask

    task automatic bfm_ready(input logic value);
        @(negedge clk);
        m_tready = value;
    endtask

    initial begin
        #20_000_000;
        $display("RESULT: FAIL (watchdog: no forward progress)");
        $finish;
    end

    // ---------------------------------------------------------------------------
    // Testbench structures and state
    // ---------------------------------------------------------------------------
    typedef struct {
        logic [DATA_WIDTH-1:0]     data;
        logic [(DATA_WIDTH/8)-1:0] keep;
        logic [USER_WIDTH-1:0]     user;
        logic                      last;
        int                        src_id;
    } beat_t;

    beat_t expected_queues[S_COUNT][$];
    beat_t inflight_frame[$];

    int active_source = -1;
    bit in_frame = 0;
    int completed_frames_count = 0;
    int source_last_frame_stamp[S_COUNT];
    
    // Backpressure tracker state (S8)
    logic [DATA_WIDTH-1:0]     expected_data_hold;
    logic [(DATA_WIDTH/8)-1:0] expected_keep_hold;
    logic [USER_WIDTH-1:0]     expected_user_hold;
    logic                      expected_last_hold;
    logic                      expected_valid_hold;
    
    task automatic check_fail(string msg);
        $display("RESULT: FAIL (%s)", msg);
        $finish;
    endtask

    // ---------------------------------------------------------------------------
    // Monitors and Checkers
    // ---------------------------------------------------------------------------

    // Track Acceptance (S5 handling setup)
    always @(posedge clk) begin
        if (!rst) begin
            for (int k = 0; k < S_COUNT; k++) begin
                if (s_tvalid[k] && s_tready[k]) begin
                    automatic beat_t b;
                    b.data = s_tdata[k];
                    b.keep = s_tkeep[k];
                    b.user = s_tuser[k];
                    b.last = s_tlast[k];
                    b.src_id = k;
                    expected_queues[k].push_back(b);
                end
            end
        end
    end

    // Track Output Delivery and Atomicity (S3, S4, S5, S8, S10)
    always @(posedge clk) begin
        if (rst) begin
            active_source <= -1;
            in_frame <= 0;
            completed_frames_count <= 0;
            for (int i=0; i<S_COUNT; i++) source_last_frame_stamp[i] <= 0;
            expected_valid_hold <= 0;
            inflight_frame.delete();
        end else begin
            // Stability check under backpressure (S8 subset)
            if (expected_valid_hold && !m_tready) begin
                if (!m_tvalid) check_fail("S8: Valid dropped while waiting for ready");
                if (m_tdata !== expected_data_hold ||
                    m_tkeep !== expected_keep_hold ||
                    m_tuser !== expected_user_hold ||
                    m_tlast !== expected_last_hold) begin
                    check_fail("S8: Payload changed while waiting for ready");
                end
            end
            
            expected_valid_hold <= m_tvalid;
            expected_data_hold <= m_tdata;
            expected_keep_hold <= m_tkeep;
            expected_user_hold <= m_tuser;
            expected_last_hold <= m_tlast;

            if (m_tvalid && m_tready) begin
                automatic beat_t match_b;
                
                // Identify source of beat if starting new frame
                if (!in_frame) begin
                    automatic int found_src = -1;
                    for (int k = 0; k < S_COUNT; k++) begin
                        if (expected_queues[k].size() > 0 && 
                            expected_queues[k][0].data === m_tdata &&
                            expected_queues[k][0].keep === m_tkeep &&
                            expected_queues[k][0].user === m_tuser &&
                            expected_queues[k][0].last === m_tlast) begin
                            found_src = k;
                            break;
                        end
                    end
                    if (found_src == -1) begin
                        check_fail("S5/S4: Output beat does not match head of any input queue");
                    end
                    
                    active_source <= found_src;
                    in_frame <= 1;
                    match_b = expected_queues[found_src].pop_front();
                    
                    if (match_b.last) begin
                        in_frame <= 0;
                        active_source <= -1;
                        completed_frames_count <= completed_frames_count + 1;
                        source_last_frame_stamp[found_src] <= completed_frames_count + 1;
                    end
                end else begin
                    // Verify atomicity - must continue from active_source
                    if (expected_queues[active_source].size() == 0) begin
                        check_fail("S3: Output beat interleaved or active source ran dry unexpectedly");
                    end
                    
                    match_b = expected_queues[active_source].pop_front();
                    
                    if (match_b.data !== m_tdata ||
                        match_b.keep !== m_tkeep ||
                        match_b.user !== m_tuser ||
                        match_b.last !== m_tlast) begin
                        check_fail("S4/S3: Interleaved beat or modified payload detected mid-frame");
                    end
                    
                    if (m_tlast) begin
                        in_frame <= 0;
                        completed_frames_count <= completed_frames_count + 1;
                        source_last_frame_stamp[active_source] <= completed_frames_count + 1;
                        active_source <= -1;
                    end
                end
            end
        end
    end

    // Fairness monitoring (S10)
    always @(posedge clk) begin
        if (!rst && completed_frames_count >= 16) begin
            // This is a strictly simplified check running continuously. 
            // In the main thread, we generate uniform continuous load.
            // If any source falls behind by more than 16 frames while load is offered, it's a violation.
            // The main test loop manages the exact conditions for this check.
        end
    end

    // Reset monitoring (S12)
    always @(posedge clk) begin
        if (rst) begin
            if (m_tvalid) check_fail("S12: Output valid asserted during reset");
        end
    end

    // ---------------------------------------------------------------------------
    // Stimulus
    // ---------------------------------------------------------------------------
    initial begin
        s_tvalid = 0; s_tdata = 0; s_tkeep = 0; s_tlast = 0; s_tuser = 0;
        m_tready = 1;

        // Reset
        bfm_reset();
        
        @(posedge clk);
        if (m_tvalid) check_fail("S12: Output valid asserted on first cycle after reset release");

        // PHASE 1: Basic disjoint frames
        for (int k = 0; k < S_COUNT; k++) begin
            bfm_send(k, 32'hAAAA_0000 + k, 4'hF, 0, 1'b0);
            bfm_send(k, 32'hBBBB_0000 + k, 4'hF, 0, 1'b0);
            bfm_send(k, 32'hCCCC_0000 + k, 4'hF, 1, 1'b0);
            bfm_idle(k);
        end
        
        // Wait for all deliveries
        begin
            automatic int watchdog = 0;
            while (expected_queues[0].size() > 0 || expected_queues[1].size() > 0 || 
                   expected_queues[2].size() > 0 || expected_queues[3].size() > 0) begin
                @(posedge clk);
                watchdog++;
                if (watchdog > 500) check_fail("S5: Missing frames");
            end
        end

        // PHASE 2: Backpressure during frame (S8)
        bfm_ready(0);
        
        // Push concurrent frames
        fork
            begin
                bfm_send(0, 32'hDDDD_0000, 4'hF, 0, 0);
                bfm_send(0, 32'hEEEE_0000, 4'hF, 1, 0);
                bfm_idle(0);
            end
            begin
                bfm_send(1, 32'hDDDD_0001, 4'hF, 0, 0);
                bfm_send(1, 32'hEEEE_0001, 4'hF, 1, 0);
                bfm_idle(1);
            end
        join

        repeat(10) @(posedge clk);
        
        // Throttle ready
        for (int i=0; i<10; i++) begin
            bfm_ready(1);
            @(posedge clk);
            bfm_ready(0);
            repeat(3) @(posedge clk);
        end
        bfm_ready(1);
        
        // Wait for delivery
        begin
            automatic int watchdog = 0;
            while (expected_queues[0].size() > 0 || expected_queues[1].size() > 0) begin
                @(posedge clk);
                watchdog++;
                if (watchdog > 500) check_fail("S8: Delivery failed under backpressure");
            end
        end

        // PHASE 3: S10 Fairness Check (Continuous Load)
        // Setup state for fairness check
        completed_frames_count = 0;
        for (int i=0; i<S_COUNT; i++) source_last_frame_stamp[i] = 0;
        
        fork
            // Continuous offered load for S_COUNT ports
            begin
                for(int j=0; j<20; j++) begin
                    bfm_send(0, 32'hF0F0_0000 + j, 4'hF, 1, 0);
                end
                bfm_idle(0);
            end
            begin
                for(int j=0; j<20; j++) begin
                    bfm_send(1, 32'hF1F1_0000 + j, 4'hF, 1, 0);
                end
                bfm_idle(1);
            end
            begin
                for(int j=0; j<20; j++) begin
                    bfm_send(2, 32'hF2F2_0000 + j, 4'hF, 1, 0);
                end
                bfm_idle(2);
            end
            begin
                for(int j=0; j<20; j++) begin
                    bfm_send(3, 32'hF3F3_0000 + j, 4'hF, 1, 0);
                end
                bfm_idle(3);
            end
        join_none

        // Monitor while continuous load processes
        begin
            automatic int watchdog = 0;
            while(completed_frames_count < 60) begin
                @(posedge clk);
                if (completed_frames_count > 16) begin
                    for (int k=0; k<S_COUNT; k++) begin
                        if ((completed_frames_count - source_last_frame_stamp[k]) > 16) begin
                            check_fail("S10: Fairness bound violated");
                        end
                    end
                end
                watchdog++;
                if (watchdog > 2000) check_fail("S10/S5: Stalled during fairness test");
            end
        end
        
        // Wait for queues to flush cleanly
        begin
            automatic int watchdog = 0;
            while (expected_queues[0].size() > 0 || expected_queues[1].size() > 0 || 
                   expected_queues[2].size() > 0 || expected_queues[3].size() > 0) begin
                @(posedge clk);
                watchdog++;
                if (watchdog > 500) check_fail("S5: Missing frames after fairness phase");
            end
        end

        // PHASE 4: Reset Discard (S12)
        // Inject a partial frame and assert reset
        bfm_send(2, 32'h9999_9999, 4'hF, 0, 0);
        
        bfm_reset();
        
        expected_queues[2].delete(); // clear expectation model since we expect discard
        
        repeat (10) @(posedge clk);
        if (m_tvalid) check_fail("S12: Transaction survived reset");

        $display("RESULT: PASS");
        $finish;
    end

endmodule