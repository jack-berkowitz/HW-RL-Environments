module frame_arb_mux_tb;

    localparam int S_COUNT = 4;
    localparam int DATA_WIDTH = 32;
    localparam int USER_WIDTH = 1;

    logic                                     clk;
    logic                                     rst;
    logic [S_COUNT-1:0][DATA_WIDTH-1:0]       s_tdata;
    logic [S_COUNT-1:0][(DATA_WIDTH/8)-1:0]   s_tkeep;
    logic [S_COUNT-1:0]                       s_tvalid;
    logic [S_COUNT-1:0]                       s_tready;
    logic [S_COUNT-1:0]                       s_tlast;
    logic [S_COUNT-1:0][USER_WIDTH-1:0]       s_tuser;

    logic [DATA_WIDTH-1:0]                    m_tdata;
    logic [(DATA_WIDTH/8)-1:0]                m_tkeep;
    logic                                     m_tvalid;
    logic                                     m_tready;
    logic                                     m_tlast;
    logic [USER_WIDTH-1:0]                    m_tuser;

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
    // PROVIDED PLUMBING
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

    // Scoreboard
    typedef struct {
        int id;
        int k;
        logic [DATA_WIDTH-1:0] data;
        logic [(DATA_WIDTH/8)-1:0] keep;
        logic [USER_WIDTH-1:0] user;
        logic last;
    } beat_t;

    beat_t input_queue[S_COUNT][$];
    int active_input = -1;
    int completed_frames[$];
    logic in_fairness_test = 1'b0;
    logic test_failed = 1'b0;

    always @(posedge clk) begin
        int found_k;
        bit seen[4];

        if (rst) begin
            for (int i = 0; i < S_COUNT; i++) input_queue[i].delete();
            active_input = -1;
            completed_frames.delete();
        end else begin
            if (m_tvalid && m_tready) begin
                found_k = -1;
                for (int i = 0; i < S_COUNT; i++) begin
                    if (input_queue[i].size() > 0 && input_queue[i][0].id == m_tdata) begin
                        found_k = i;
                        break;
                    end
                end
                
                if (found_k == -1) begin
                    $display("FAIL: S4/S5/S12 - Output beat ID %0d not found at head of any input queue", m_tdata);
                    test_failed = 1'b1;
                end else begin
                    if (active_input != -1 && active_input != found_k) begin
                        $display("FAIL: S3 - Frame atomicity violated. Expected input %0d, got %0d", active_input, found_k);
                        test_failed = 1'b1;
                    end
                    
                    if (active_input == -1) begin
                        active_input = found_k;
                    end
                    
                    if (input_queue[found_k][0].last !== m_tlast) begin
                        $display("FAIL: S4 - m_tlast mismatch. Expected %0d, got %0d", input_queue[found_k][0].last, m_tlast);
                        test_failed = 1'b1;
                    end
                    
                    if (input_queue[found_k][0].keep !== m_tkeep) begin
                        $display("FAIL: S4 - m_tkeep mismatch. Expected %h, got %h", input_queue[found_k][0].keep, m_tkeep);
                        test_failed = 1'b1;
                    end

                    if (input_queue[found_k][0].user !== m_tuser) begin
                        $display("FAIL: S4 - m_tuser mismatch. Expected %h, got %h", input_queue[found_k][0].user, m_tuser);
                        test_failed = 1'b1;
                    end
                    
                    input_queue[found_k].pop_front();
                    
                    if (m_tlast) begin
                        active_input = -1;
                        completed_frames.push_back(found_k);
                        if (in_fairness_test && completed_frames.size() >= 16) begin
                            seen = '{0,0,0,0};
                            for (int i = completed_frames.size() - 16; i < completed_frames.size(); i++) begin
                                seen[completed_frames[i]] = 1'b1;
                            end
                            if (!seen[0] || !seen[1] || !seen[2] || !seen[3]) begin
                                $display("FAIL: S10 - Bounded fairness violated. Not all inputs seen in last 16 frames.");
                                test_failed = 1'b1;
                            end
                        end
                    end
                end
            end
        end
    end

    initial begin
        int id0, id1, id2, id3;

        s_tdata = '0;
        s_tkeep = '0;
        s_tvalid = '0;
        s_tlast = '0;
        s_tuser = '0;
        m_tready = '0;

        bfm_reset(4);

        $display("Testing S12: Reset behavior...");
        bfm_ready(1);
        bfm_send(0, 9000, 4'hF, 1'b0, 1'b0);
        input_queue[0].push_back('{id: 9000, k: 0, data: 9000, keep: 4'hF, user: 1'b0, last: 1'b0});
        
        @(negedge clk);
        rst = 1'b1;
        repeat (4) @(posedge clk);
        @(negedge clk);
        rst = 1'b0;
        repeat (10) @(posedge clk);

        $display("Testing S5a: Abandoned frame...");
        bfm_ready(1);
        bfm_send(1, 60000, 4'hF, 1'b0, 1'b0);
        input_queue[1].push_back('{id: 60000, k: 1, data: 60000, keep: 4'hF, user: 1'b0, last: 1'b0});
        bfm_send(1, 60001, 4'hF, 1'b0, 1'b0);
        input_queue[1].push_back('{id: 60001, k: 1, data: 60001, keep: 4'hF, user: 1'b0, last: 1'b0});
        
        bfm_idle(1);
        bfm_send(2, 60002, 4'hF, 1'b1, 1'b0);
        input_queue[2].push_back('{id: 60002, k: 2, data: 60002, keep: 4'hF, user: 1'b0, last: 1'b1});
        
        fork
            wait (completed_frames.size() >= 1);
            begin
                repeat (100) @(posedge clk);
                $display("FAIL: S5a - Timeout waiting for abandoned frame test to complete");
                test_failed = 1'b1;
            end
        join_any
        disable fork;

        $display("Testing S8: Backpressure...");
        bfm_ready(1);
        bfm_send(0, 50000, 4'hF, 1'b0, 1'b0);
        input_queue[0].push_back('{id: 50000, k: 0, data: 50000, keep: 4'hF, user: 1'b0, last: 1'b0});
        
        bfm_ready(0);
        fork
            begin
                bfm_send(0, 50001, 4'hF, 1'b1, 1'b0);
                input_queue[0].push_back('{id: 50001, k: 0, data: 50001, keep: 4'hF, user: 1'b0, last: 1'b1});
            end
            begin
                repeat (20) @(posedge clk);
                bfm_ready(1);
            end
        join

        $display("Testing S3: Frame atomicity with multi-beat frames...");
        bfm_ready(1);
        fork
            begin
                bfm_send(0, 70000, 4'hF, 1'b0, 1'b0);
                input_queue[0].push_back('{id: 70000, k: 0, data: 70000, keep: 4'hF, user: 1'b0, last: 1'b0});
                bfm_send(0, 70001, 4'hF, 1'b1, 1'b0);
                input_queue[0].push_back('{id: 70001, k: 0, data: 70001, keep: 4'hF, user: 1'b0, last: 1'b1});
            end
            begin
                bfm_send(1, 70002, 4'hF, 1'b0, 1'b0);
                input_queue[1].push_back('{id: 70002, k: 1, data: 70002, keep: 4'hF, user: 1'b0, last: 1'b0});
                bfm_send(1, 70003, 4'hF, 1'b1, 1'b0);
                input_queue[1].push_back('{id: 70003, k: 1, data: 70003, keep: 4'hF, user: 1'b0, last: 1'b1});
            end
        join

        $display("Testing S10: Bounded fairness...");
        in_fairness_test = 1'b1;
        bfm_ready(1);
        
        id0 = 10000;
        id1 = 20000;
        id2 = 30000;
        id3 = 40000;
        
        fork
            begin
                for (int i = 0; i < 64; i++) begin
                    bfm_send(0, id0, 4'hF, 1'b1, id0[0]);
                    input_queue[0].push_back('{id: id0, k: 0, data: id0, keep: 4'hF, user: id0[0], last: 1'b1});
                    id0++;
                end
            end
            begin
                for (int i = 0; i < 64; i++) begin
                    bfm_send(1, id1, 4'hF, 1'b1, id1[0]);
                    input_queue[1].push_back('{id: id1, k: 1, data: id1, keep: 4'hF, user: id1[0], last: 1'b1});
                    id1++;
                end
            end
            begin
                for (int i = 0; i < 64; i++) begin
                    bfm_send(2, id2, 4'hF, 1'b1, id2[0]);
                    input_queue[2].push_back('{id: id2, k: 2, data: id2, keep: 4'hF, user: id2[0], last: 1'b1});
                    id2++;
                end
            end
            begin
                for (int i = 0; i < 64; i++) begin
                    bfm_send(3, id3, 4'hF, 1'b1, id3[0]);
                    input_queue[3].push_back('{id: id3, k: 3, data: id3, keep: 4'hF, user: id3[0], last: 1'b1});
                    id3++;
                end
            end
        join
        
        fork
            wait (completed_frames.size() == 256);
            begin
                repeat (2000) @(posedge clk);
                $display("FAIL: S10 - Timeout waiting for frames to complete.");
                test_failed = 1'b1;
            end
        join_any
        disable fork;
        
        in_fairness_test = 1'b0;

        $display("RESULT: %s", test_failed ? "FAIL" : "PASS");
        $finish;
    end

endmodule