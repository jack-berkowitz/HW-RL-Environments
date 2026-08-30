module tag_tracker_tb;

    // ---------------------------------------------------------------------------
    // PARAMETERS
    // ---------------------------------------------------------------------------
    localparam int TAG_W  = 3;
    localparam int SLOTS  = 8;
    localparam bit FULL_RATE = 0;
    localparam bit CUT_POP_PATH = 0;
    localparam int N_MATCH = 1;
    typedef logic[31:0] payload_t;
    localparam type tag_t = logic[TAG_W-1:0];

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

    // ---------------------------------------------------------------------------
    // SIGNALS AND INSTANTIATION
    // ---------------------------------------------------------------------------
    tag_t push_tag;
    payload_t push_data;
    logic push_req;
    logic push_gnt;

    payload_t [N_MATCH-1:0] match_data;
    payload_t [N_MATCH-1:0] match_mask;
    logic [N_MATCH-1:0] match_req;
    logic [N_MATCH-1:0] match_hit;
    logic [N_MATCH-1:0] match_gnt;

    tag_t pop_tag;
    logic pop_en;
    logic pop_req;
    payload_t pop_data;
    logic pop_data_valid;
    logic pop_gnt;

    logic full;
    logic empty;

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
        .push_tag_i(push_tag),
        .push_data_i(push_data),
        .push_req_i(push_req),
        .push_gnt_o(push_gnt),
        .match_data_i(match_data),
        .match_mask_i(match_mask),
        .match_req_i(match_req),
        .match_hit_o(match_hit),
        .match_gnt_o(match_gnt),
        .pop_tag_i(pop_tag),
        .pop_en_i(pop_en),
        .pop_req_i(pop_req),
        .pop_data_o(pop_data),
        .pop_data_valid_o(pop_data_valid),
        .pop_gnt_o(pop_gnt),
        .full_o(full),
        .empty_o(empty)
    );

    // ---------------------------------------------------------------------------
    // TESTBENCH MODEL & TRACKING
    // ---------------------------------------------------------------------------
    payload_t shadow_model [int][$];
    int total_entries;

    task automatic report_fail(string msg);
        $display("RESULT: FAIL (%s)", msg);
        $finish;
    endtask

    // ---------------------------------------------------------------------------
    // DRIVERS AND TRANSACTORS
    // ---------------------------------------------------------------------------
    
    // Issues a push request and returns 1 if completed, 0 otherwise
    task automatic try_push(input tag_t tag, input payload_t data, output logic success);
        bfm_drive_point();
        push_req = 1'b1;
        push_tag = tag;
        push_data = data;
        bfm_tick();
        success = (push_req && push_gnt);
        bfm_drive_point();
        push_req = 1'b0;
    endtask

    // Drives a pop request. Blocks until pop_gnt is seen, ensuring completion.
    // Collects output validation signals.
    task automatic do_pop(input tag_t tag, input logic en, output logic valid, output payload_t data);
        bfm_drive_point();
        pop_req = 1'b1;
        pop_tag = tag;
        pop_en = en;
        
        forever begin
            bfm_tick();
            if (pop_gnt) begin
                valid = pop_data_valid;
                data = pop_data;
                break;
            end
        end
        bfm_drive_point();
        pop_req = 1'b0;
    endtask

    // Performs a search/match and waits for grant. Returns hit result.
    task automatic do_match(input payload_t data, input payload_t mask, output logic hit);
        bfm_drive_point();
        match_req[0] = 1'b1;
        match_data[0] = data;
        match_mask[0] = mask;
        
        forever begin
            bfm_tick();
            if (match_gnt[0]) begin
                hit = match_hit[0];
                break;
            end
        end
        bfm_drive_point();
        match_req[0] = 1'b0;
    endtask

    // Helper logic to clear expected tracking models
    task automatic clear_model();
        shadow_model.delete();
        total_entries = 0;
    endtask

    // ---------------------------------------------------------------------------
    // PASSIVE MONITORS AND CHECKS
    // ---------------------------------------------------------------------------
    always @(posedge clk) begin
        if (rst_n) begin
            // R14: Check empty_o and full_o mapping identically to tracked sizes
            if (empty && total_entries != 0) report_fail("R14: empty_o asserted while model holds items");
            if (!empty && total_entries == 0) report_fail("R14: empty_o low while model is empty");
            if (full && total_entries != SLOTS) report_fail("R14: full_o asserted while model is not full");
            if (!full && total_entries == SLOTS) report_fail("R14: full_o low while model is full");

            // R5: Check push_gnt logic bounds. Cannot grant if previously full.
            // Using total_entries BEFORE any pop logic updates to test R5 constraint strictly.
            if (push_gnt && push_req && total_entries == SLOTS) begin
                report_fail("R5: push_gnt_o asserted while store holds SLOTS entries");
            end

            // Monitor state transitions
            if (push_req && push_gnt) begin
                shadow_model[push_tag].push_back(push_data);
                total_entries++;
            end

            if (pop_req && pop_gnt) begin
                automatic int model_has_tag = shadow_model.exists(pop_tag) && (shadow_model[pop_tag].size() > 0);
                
                // R8, R10: pop_data_valid checks mapping 
                if (pop_data_valid != model_has_tag) begin
                    report_fail("R8/R10: pop_data_valid_o incorrect based on tag existence");
                end

                if (pop_data_valid) begin
                    automatic payload_t expected_data = shadow_model[pop_tag][0];
                    // R8, R2: Ensures FIFO ordering correctness 
                    if (pop_data !== expected_data) begin
                        report_fail("R8/R2: pop_data_o mismatched oldest tag entry payload");
                    end

                    // R9: Remove only if pop_en is 1
                    if (pop_en) begin
                        automatic payload_t trash = shadow_model[pop_tag].pop_front();
                        total_entries--;
                    end
                end
            end
        end
    end

    // ---------------------------------------------------------------------------
    // STIMULUS AND TESTS
    // ---------------------------------------------------------------------------
    initial begin
        automatic logic success;
        automatic logic valid;
        automatic payload_t rdata;
        automatic logic hit;

        push_req = 0; pop_req = 0; match_req = 0;
        push_tag = 0; push_data = 0;
        pop_tag = 0; pop_en = 0;
        match_data = 0; match_mask = 0;
        clear_model();

        bfm_reset();

        // R15: Verify states post reset
        if (!empty || full) report_fail("R15: State tracking not cleared after reset");

        // Test Phase 1: Push Operations bounded by SLOTS (R1)
        for (int i = 0; i < SLOTS; i++) begin
            automatic int watchdog = 0;
            success = 0;
            while (!success && watchdog < 20) begin
                try_push(3'd2, i, success);
                watchdog++;
            end
            if (!success) report_fail("R1/R4: Failed to push to free slot within tolerance");
        end

        // Capacity bounds validation (R1, R5 verified implicitly via passive monitor)
        try_push(3'd2, 999, success);
        if (success) report_fail("R5: Accepted push when store was full");

        // Test Phase 2: Search validations (R12, R13)
        // Store presently has tag=2 populated with {0..7}
        do_match(32'd4, 32'hFFFFFFFF, hit);
        if (!hit) report_fail("R12: match_hit_o low when exact match should exist");

        do_match(32'd15, 32'hFFFFFFFF, hit);
        if (hit) report_fail("R12: match_hit_o high when match should not exist");

        do_match(32'hAAAA_AAAA, 32'h0000_0000, hit);
        if (!hit) report_fail("R12/R13: match_hit_o low with all-zero mask");

        // Test Phase 3: Peek Operations and Valid pop responses (R8, R9)
        do_pop(3'd2, 1'b0, valid, rdata);
        if (!valid) report_fail("R8: pop_data_valid_o low on valid tag");
        if (rdata !== 32'd0) report_fail("R8/R2: pop_data_o gave wrong value on peek");
        if (total_entries != SLOTS) report_fail("R9: pop_en low but entry was removed");

        // Test Phase 4: Valid pops preserving per-tag ordering (R2, R8, R9)
        for (int i = 0; i < SLOTS; i++) begin
            do_pop(3'd2, 1'b1, valid, rdata);
            if (!valid || rdata !== i) report_fail("R8/R2: Mismatched valid or data on sequenced pop");
        end
        
        // Storage should be fully empty now
        if (total_entries != 0) report_fail("R14: Sync mismatch between actual testing and models");

        // Test Phase 5: Invalid pop tracking (R10)
        do_pop(3'd5, 1'b1, valid, rdata);
        if (valid) report_fail("R8/R10: pop_data_valid_o high on empty tag pop");

        // Test Phase 6: Reset interaction (R15)
        success = 0;
        while (!success) try_push(3'd4, 32'd100, success);
        
        bfm_reset();
        clear_model(); // Model aligned back to 0
        
        if (!empty || full) report_fail("R15: Reset didn't properly emit correct status logic bounds");
        
        // Pushing should be fine again after reset 
        success = 0;
        while (!success) try_push(3'd5, 32'd200, success);
        if (!success) report_fail("R15: Store failed to recover post reset functionality");

        $display("RESULT: PASS");
        $finish;
    end

endmodule