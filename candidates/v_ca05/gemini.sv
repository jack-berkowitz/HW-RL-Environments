module tag_tracker_tb;
    parameter int TAG_W  = 3;
    parameter int SLOTS  = 8;
    parameter bit FULL_RATE   = 0;
    parameter bit CUT_POP_PATH = 0;
    parameter int N_MATCH = 1;
    parameter type payload_t   = logic[31:0];
    localparam type tag_t    = logic[TAG_W-1:0];

    // ---- DUT Ports -------------------------------------------------------------
    logic    push_req_i;
    logic    push_gnt_o;
    tag_t    push_tag_i;
    payload_t push_data_i;

    payload_t [N_MATCH-1:0] match_data_i;
    payload_t [N_MATCH-1:0] match_mask_i;
    logic     [N_MATCH-1:0] match_req_i;
    logic     [N_MATCH-1:0] match_hit_o;
    logic     [N_MATCH-1:0] match_gnt_o;

    tag_t    pop_tag_i;
    logic    pop_en_i;
    logic    pop_req_i;
    payload_t pop_data_o;
    logic    pop_data_valid_o;
    logic    pop_gnt_o;

    logic    full_o;
    logic    empty_o;

    // ---------------------------------------------------------------------------
    // PROVIDED PLUMBING -- clock, reset and watchdog only.
    // ---------------------------------------------------------------------------
    logic clk;
    initial begin clk = 1'b0; forever #5 clk = ~clk; end

    logic rst_n;
    initial rst_n = 1'b0;

    task automatic bfm_reset(input int cycles = 4);
        @(negedge clk);
        rst_n = 1'b0;
        repeat (cycles) @(posedge clk);
        @(negedge clk);
        rst_n = 1'b1;
    endtask

    task automatic bfm_drive_point();
        @(negedge clk);
    endtask

    task automatic bfm_tick();
        @(posedge clk);
    endtask

    initial begin
        #20_000_000;
        $display("RESULT: FAIL (watchdog: no forward progress)");
        $finish;
    end

    // ---- DUT Instantiation -----------------------------------------------------
    tag_tracker #(
        .TAG_W(TAG_W),
        .SLOTS(SLOTS),
        .FULL_RATE(FULL_RATE),
        .CUT_POP_PATH(CUT_POP_PATH),
        .N_MATCH(N_MATCH),
        .payload_t(payload_t)
    ) dut (
        .clk_i(clk),
        .rst_ni(rst_n),

        .push_tag_i(push_tag_i),
        .push_data_i(push_data_i),
        .push_req_i(push_req_i),
        .push_gnt_o(push_gnt_o),

        .match_data_i(match_data_i),
        .match_mask_i(match_mask_i),
        .match_req_i(match_req_i),
        .match_hit_o(match_hit_o),
        .match_gnt_o(match_gnt_o),

        .pop_tag_i(pop_tag_i),
        .pop_en_i(pop_en_i),
        .pop_req_i(pop_req_i),
        .pop_data_o(pop_data_o),
        .pop_data_valid_o(pop_data_valid_o),
        .pop_gnt_o(pop_gnt_o),

        .full_o(full_o),
        .empty_o(empty_o)
    );

    // ---- Testbench State & Helpers ---------------------------------------------
    int total_entries = 0;
    payload_t model[int][$];

    task automatic fail_test(string msg);
        $display("%s", msg);
        $display("RESULT: FAIL");
        $finish;
    endtask

    task automatic wait_status_update();
        // Allow time for outputs to update (combinational or registered)
        bfm_tick();
        bfm_tick();
    endtask

    task automatic check_status();
        wait_status_update();
        if (empty_o !== (total_entries == 0)) begin
            fail_test($sformatf("R14/R15: empty_o mismatch. Expected %b, got %b", (total_entries == 0), empty_o));
        end
        if (full_o !== (total_entries == SLOTS)) begin
            fail_test($sformatf("R14/R15: full_o mismatch. Expected %b, got %b", (total_entries == SLOTS), full_o));
        end
    endtask

    task automatic do_push(input tag_t tag, input payload_t data);
        int timeout_cnt;
        timeout_cnt = 0;
        
        bfm_drive_point();
        push_req_i = 1;
        push_tag_i = tag;
        push_data_i = data;
        
        while (1) begin
            @(posedge clk);
            if (push_gnt_o === 1'b1) break;
            
            timeout_cnt++;
            if (timeout_cnt > 2000) begin
                fail_test("R4/R6: push_req_i asserted but push_gnt_o not received within timeout");
            end
        end
        
        model[tag].push_back(data);
        total_entries++;
        
        bfm_drive_point();
        push_req_i = 0;
    endtask

    task automatic check_push_blocked();
        bfm_drive_point();
        push_req_i = 1;
        push_tag_i = 0;
        push_data_i = 32'hDEADBEEF;
        
        // Wait multiple cycles ensuring gnt is held low when full
        for (int i = 0; i < 20; i++) begin
            @(posedge clk);
            if (push_gnt_o === 1'b1) begin
                fail_test("R5: push_gnt_o asserted when store is full");
            end
        end
        
        bfm_drive_point();
        push_req_i = 0;
    endtask

    task automatic do_pop(input tag_t tag, input logic en, input logic expect_valid, input payload_t expect_data);
        int timeout_cnt;
        timeout_cnt = 0;
        
        bfm_drive_point();
        pop_req_i = 1;
        pop_tag_i = tag;
        pop_en_i = en;
        
        while (1) begin
            @(posedge clk);
            if (pop_gnt_o === 1'b1) begin
                // Check requirements on the completing cycle
                if (pop_data_valid_o !== expect_valid) begin
                    fail_test($sformatf("R8/R10: pop_data_valid_o mismatch. Expected %b, got %b", expect_valid, pop_data_valid_o));
                end
                
                if (expect_valid && pop_data_o !== expect_data) begin
                    fail_test($sformatf("R2/R8: pop_data_o mismatch. Expected %x, got %x", expect_data, pop_data_o));
                end
                
                if (expect_valid && en) begin
                    automatic payload_t dummy;
                    dummy = model[tag].pop_front();
                    total_entries--;
                end
                break;
            end
            
            timeout_cnt++;
            if (timeout_cnt > 2000) begin
                fail_test("R7: pop_req_i asserted but pop_gnt_o not received within timeout");
            end
        end
        
        bfm_drive_point();
        pop_req_i = 0;
    endtask

    task automatic do_match(input payload_t data, input payload_t mask, input logic expect_hit);
        int timeout_cnt;
        timeout_cnt = 0;
        
        bfm_drive_point();
        match_req_i[0] = 1;
        match_data_i[0] = data;
        match_mask_i[0] = mask;
        
        while (1) begin
            @(posedge clk);
            if (match_gnt_o[0] === 1'b1) begin
                if (match_hit_o[0] !== expect_hit) begin
                    fail_test($sformatf("R12/R13: match_hit_o mismatch. Expected %b, got %b", expect_hit, match_hit_o[0]));
                end
                break;
            end
            
            timeout_cnt++;
            if (timeout_cnt > 2000) begin
                fail_test("R11: match_req_i asserted but match_gnt_o not received within timeout");
            end
        end
        
        bfm_drive_point();
        match_req_i[0] = 0;
    endtask

    // ---- Main Test Sequence ----------------------------------------------------
    initial begin
        int i;
        
        // Initialize inputs
        push_req_i = 0;
        pop_req_i = 0;
        match_req_i = 0;
        
        // Assert Reset (R15 checks initial state naturally inside tasks)
        bfm_reset(4);
        total_entries = 0;
        
        // R15 Check: should be empty right after reset
        check_status();

        // Push mix of tags up to capacity (R1 capacity check)
        do_push(0, 32'hA1);
        do_push(0, 32'hA2);
        do_push(1, 32'hB1);
        do_push(2, 32'hC1);
        do_push(2, 32'hC2);
        do_push(2, 32'hC3);
        do_push(3, 32'hD1);
        do_push(4, 32'hE1);
        
        // Confirm full status updates (R14)
        check_status();
        
        // Try pushing when full to verify push_gnt_o is held low (R5)
        check_push_blocked();
        
        // Verify searches (R12, R13)
        do_match(32'hA1, 32'hFFFFFFFF, 1);       // Exact match present
        do_match(32'h00, 32'h00000000, 1);       // Mask zero matches anything (R13)
        do_match(32'hA3, 32'hFFFFFFFF, 0);       // Exact match absent
        do_match(32'h01, 32'h0F, 1);             // Masked match (matches hA1, hB1, etc)
        
        // Verify pop inspection without removal (R8, R9)
        do_pop(0, 0, 1, 32'hA1);
        check_status(); // Size shouldn't have changed

        // Verify pop removals and ordering (R2, R8, R9)
        do_pop(0, 1, 1, 32'hA1);
        do_pop(0, 1, 1, 32'hA2);
        
        // Pop an empty tag (R10)
        do_pop(0, 1, 0, 32'hx);
        
        // Clear remaining elements
        do_pop(1, 1, 1, 32'hB1);
        do_pop(2, 1, 1, 32'hC1);
        do_pop(2, 1, 1, 32'hC2);
        do_pop(2, 1, 1, 32'hC3);
        do_pop(3, 1, 1, 32'hD1);
        do_pop(4, 1, 1, 32'hE1);
        
        // Confirm empty status (R14)
        check_status();
        
        // Push single tag up to capacity (R1 single-tag capacity check)
        for (i = 0; i < 8; i++) begin
            do_push(7, 32'h100 + i);
        end
        
        check_status();
        check_push_blocked(); // R5 again on single-tag fullness
        
        // Pop them sequentially to ensure strict FIFO (R2 single-tag)
        for (i = 0; i < 8; i++) begin
            do_pop(7, 1, 1, 32'h100 + i);
        end
        
        // Final empty check on the abused tag (R10)
        do_pop(7, 1, 0, 32'hx);
        check_status();
        
        $display("RESULT: PASS");
        $finish;
    end

endmodule