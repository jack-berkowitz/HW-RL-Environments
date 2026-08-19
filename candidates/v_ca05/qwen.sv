module tag_tracker_tb;

    // Parameters
    localparam int TAG_W = 3;
    localparam int SLOTS = 8;
    localparam bit FULL_RATE = 0;
    localparam bit CUT_POP_PATH = 0;
    localparam int N_MATCH = 1;
    typedef logic [31:0] payload_t;
    typedef logic [TAG_W-1:0] tag_t;

    // Signals
    logic clk;
    logic rst_n;

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

    logic full_o;
    logic empty_o;

    // DUT instantiation
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
        .full_o(full_o),
        .empty_o(empty_o)
    );

    // ---------------------------------------------------------------------------
    // PROVIDED PLUMBING -- clock, reset and watchdog only.
    // ---------------------------------------------------------------------------
    initial begin clk = 1'b0; forever #5 clk = ~clk; end

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

    // Reference model
    typedef struct {
        tag_t tag;
        payload_t payload;
    } entry_t;

    entry_t ref_store[$];
    logic test_failed = 1'b0;

    // Reference model updates and continuous checks
    always @(posedge clk) begin
        if (!rst_n) begin
            ref_store.delete();
        end else begin
            int i;
            int k;
            automatic int match_idx = -1;
            bit expected_hit;

            // R5: push_gnt_o shall be low when the store holds SLOTS entries.
            if (ref_store.size() == SLOTS) begin
                if (push_gnt) begin
                    $display("FAIL: R5 - push_gnt_o high when store is full");
                    test_failed = 1'b1;
                end
            end
            
            // R14: empty_o and full_o
            if (empty_o !== (ref_store.size() == 0)) begin
                $display("FAIL: R14 - empty_o mismatch");
                test_failed = 1'b1;
            end
            if (full_o !== (ref_store.size() == SLOTS)) begin
                $display("FAIL: R14 - full_o mismatch");
                test_failed = 1'b1;
            end

            // R4: Push completion
            if (push_req && push_gnt) begin
                entry_t new_entry;
                new_entry.tag = push_tag;
                new_entry.payload = push_data;
                ref_store.push_back(new_entry);
            end

            // R7, R8, R9, R10: Pop completion
            if (pop_req && pop_gnt) begin
                match_idx = -1;
                for (i = 0; i < ref_store.size(); i++) begin
                    if (ref_store[i].tag == pop_tag) begin
                        match_idx = i;
                        break;
                    end
                end
                
                if (match_idx != -1) begin
                    if (!pop_data_valid) begin
                        $display("FAIL: R8 - pop_data_valid low when entry exists for tag %0d", pop_tag);
                        test_failed = 1'b1;
                    end
                    if (pop_data !== ref_store[match_idx].payload) begin
                        $display("FAIL: R8 - pop_data mismatch for tag %0d (expected %h, got %h)", pop_tag, ref_store[match_idx].payload, pop_data);
                        test_failed = 1'b1;
                    end
                    if (pop_en) begin
                        ref_store.delete(match_idx);
                    end
                end else begin
                    if (pop_data_valid) begin
                        $display("FAIL: R10 - pop_data_valid high when no entry exists for tag %0d", pop_tag);
                        test_failed = 1'b1;
                    end
                end
            end

            // R11, R12, R13: Search completion
            for (k = 0; k < N_MATCH; k++) begin
                if (match_req[k] && match_gnt[k]) begin
                    expected_hit = 1'b0;
                    for (i = 0; i < ref_store.size(); i++) begin
                        if ((ref_store[i].payload & match_mask[k]) == (match_data[k] & match_mask[k])) begin
                            expected_hit = 1'b1;
                            break;
                        end
                    end
                    if (match_hit[k] !== expected_hit) begin
                        $display("FAIL: R12 - match_hit mismatch on port %0d (expected %0d, got %0d)", k, expected_hit, match_hit[k]);
                        test_failed = 1'b1;
                    end
                    if (match_mask[k] == 0) begin
                        if (ref_store.size() > 0 && !match_hit[k]) begin
                            $display("FAIL: R13 - match_hit low with zero mask and non-empty store on port %0d", k);
                            test_failed = 1'b1;
                        end
                    end
                end
            end
        end
    end

    // Test tasks
    task automatic push_with_timeout(input tag_t tag, input payload_t data, input int timeout);
        int count = 0;
        bfm_drive_point();
        push_tag = tag;
        push_data = data;
        push_req = 1'b1;
        while (!push_gnt) begin
            bfm_tick();
            count++;
            if (count > timeout) begin
                $display("FAIL: R4 - Push timeout");
                test_failed = 1'b1;
                return;
            end
        end
        bfm_drive_point();
        push_req = 1'b0;
    endtask

    task automatic pop_with_timeout(input tag_t tag, input logic en, input int timeout);
        int count = 0;
        bfm_drive_point();
        pop_tag = tag;
        pop_en = en;
        pop_req = 1'b1;
        while (!pop_gnt) begin
            bfm_tick();
            count++;
            if (count > timeout) begin
                $display("FAIL: R7 - Pop timeout");
                test_failed = 1'b1;
                return;
            end
        end
        bfm_drive_point();
        pop_req = 1'b0;
    endtask

    task automatic match_with_timeout(input int k, input payload_t data, input payload_t mask, input logic expected_hit, input int timeout);
        int count = 0;
        bfm_drive_point();
        match_req[k] = 1'b1;
        match_data[k] = data;
        match_mask[k] = mask;
        while (!match_gnt[k]) begin
            bfm_tick();
            count++;
            if (count > timeout) begin
                $display("FAIL: R11 - Match timeout on port %0d", k);
                test_failed = 1'b1;
                return;
            end
        end
        bfm_drive_point();
        match_req[k] = 1'b0;
    endtask

    // Main test sequence
    initial begin
        push_tag = '0;
        push_data = '0;
        push_req = 1'b0;
        match_data = '0;
        match_mask = '0;
        match_req = '0;
        pop_tag = '0;
        pop_en = 1'b0;
        pop_req = 1'b0;

        bfm_drive_point();
        bfm_reset(4);

        // Test 1: Push SLOTS entries with the SAME tag to verify R1 (shared capacity, same tag)
        $display("Test 1: Pushing %0d entries with same tag", SLOTS);
        for (int i = 0; i < SLOTS; i++) begin
            push_with_timeout(1, 32'h1000 + i, 200);
        end
        
        if (ref_store.size() != SLOTS) begin
            $display("FAIL: R1 - Store did not accept SLOTS entries");
            test_failed = 1'b1;
        end
        
        // Test 2: Attempt push when full (R5)
        $display("Test 2: Attempting push when full");
        push_req = 1'b1;
        push_tag = 1;
        push_data = 32'hFFFF;
        repeat (5) begin
            bfm_tick();
            if (push_gnt) begin
                $display("FAIL: R5 - push_gnt_o went high when store is full");
                test_failed = 1'b1;
            end
        end
        bfm_drive_point();
        push_req = 1'b0;
        
        // Test 3: Pop all entries and verify per-tag FIFO (R2, R8, R9)
        $display("Test 3: Popping all entries");
        for (int i = 0; i < SLOTS; i++) begin
            pop_with_timeout(1, 1, 200);
        end
        
        if (ref_store.size() != 0) begin
            $display("FAIL: R1/R9 - Store not empty after popping all entries");
            test_failed = 1'b1;
        end
        
        // Test 4: Pop when empty (R10)
        $display("Test 4: Popping when empty");
        pop_with_timeout(5, 1, 200);
        
        // Test 5: Search (R11, R12, R13)
        $display("Test 5: Search");
        push_with_timeout(1, 32'hAABBCCDD, 200);
        push_with_timeout(2, 32'h11223344, 200);
        push_with_timeout(1, 32'hAABB0000, 200);
        
        // Search for exact match
        match_with_timeout(0, 32'hAABBCCDD, 32'hFFFFFFFF, 1, 200);
        
        // Search for masked match
        match_with_timeout(0, 32'hAABB0000, 32'hFFFF0000, 1, 200);
        
        // Search for non-existent
        match_with_timeout(0, 32'h00000000, 32'hFFFFFFFF, 0, 200);
        
        // Search with mask 0 (R13)
        match_with_timeout(0, 32'h00000000, 32'h00000000, 1, 200);
        
        // Test 6: Pop with pop_en = 0 (R9)
        $display("Test 6: Pop with pop_en = 0");
        pop_with_timeout(1, 0, 200); // Peek
        if (ref_store.size() != 3) begin
            $display("FAIL: R9 - Entry removed when pop_en = 0");
            test_failed = 1'b1;
        end
        
        // Now actually pop it
        pop_with_timeout(1, 1, 200);
        if (ref_store.size() != 2) begin
            $display("FAIL: R9 - Entry not removed when pop_en = 1");
            test_failed = 1'b1;
        end
        
        // Test 7: Per-tag FIFO order (R2)
        $display("Test 7: Per-tag FIFO order");
        pop_with_timeout(1, 1, 200);
        
        // Test 8: Reset (R15)
        $display("Test 8: Reset");
        bfm_drive_point();
        rst_n = 1'b0;
        repeat (2) bfm_tick();
        rst_n = 1'b1;
        bfm_tick();
        if (ref_store.size() != 0) begin
            $display("FAIL: R15 - Store not emptied on reset");
            test_failed = 1'b1;
        end
        
        $display("RESULT: %s", test_failed ? "FAIL" : "PASS");
        $finish;
    end

endmodule