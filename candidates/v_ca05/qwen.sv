module tag_tracker_tb;

    typedef logic [31:0] payload_t;

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

    // DUT Signals
    logic [2:0] push_tag_i;
    payload_t push_data_i;
    logic push_req_i;
    logic push_gnt_o;

    payload_t [0:0] match_data_i;
    payload_t [0:0] match_mask_i;
    logic [0:0] match_req_i;
    logic [0:0] match_hit_o;
    logic [0:0] match_gnt_o;

    logic [2:0] pop_tag_i;
    logic pop_en_i;
    logic pop_req_i;
    payload_t pop_data_o;
    logic pop_data_valid_o;
    logic pop_gnt_o;

    logic full_o;
    logic empty_o;

    // DUT Instantiation
    tag_tracker #(
        .TAG_W(3),
        .SLOTS(8),
        .FULL_RATE(0),
        .CUT_POP_PATH(0),
        .N_MATCH(1),
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

    // Reference Model
    typedef struct {
        logic [2:0] tag;
        logic [31:0] payload;
    } entry_t;

    entry_t ref_store[$];
    logic test_fail = 1'b0;
    logic test_pass = 1'b0;

    // Reference Model Checker
    always @(posedge clk) begin
        if (!rst_n) begin
            ref_store.delete();
        end else begin
            automatic int sz = ref_store.size();
            automatic int match_idx = -1;
            automatic bit hit = 1'b0;
            automatic int i;
            automatic entry_t new_entry;

            // R5 check
            if (sz == 8) begin
                if (push_gnt_o) begin
                    $display("FAIL: R5 - push_gnt_o is high when store is full");
                    test_fail = 1'b1;
                end
            end

            // R14 check (only when no grant to avoid registered/combinational ambiguity)
            if (!push_gnt_o && !pop_gnt_o) begin
                if (sz == 0 && !empty_o) begin
                    $display("FAIL: R14 - empty_o should be high when store is empty");
                    test_fail = 1'b1;
                end
                if (sz != 0 && empty_o) begin
                    $display("FAIL: R14 - empty_o should be low when store is not empty");
                    test_fail = 1'b1;
                end
                if (sz == 8 && !full_o) begin
                    $display("FAIL: R14 - full_o should be high when store has 8 entries");
                    test_fail = 1'b1;
                end
                if (sz != 8 && full_o) begin
                    $display("FAIL: R14 - full_o should be low when store does not have 8 entries");
                    test_fail = 1'b1;
                end
            end

            // R7, R8, R9, R10: Pop (evaluate BEFORE push to be safe)
            if (pop_req_i && pop_gnt_o) begin
                match_idx = -1;
                for (i = 0; i < sz; i++) begin
                    if (ref_store[i].tag == pop_tag_i) begin
                        match_idx = i;
                        break;
                    end
                end

                if (match_idx != -1) begin
                    if (!pop_data_valid_o) begin
                        $display("FAIL: R8 - pop_data_valid_o should be high when entry exists");
                        test_fail = 1'b1;
                    end
                    if (pop_data_o != ref_store[match_idx].payload) begin
                        $display("FAIL: R8 - pop_data_o does not match oldest entry payload. Expected %0h, got %0h", ref_store[match_idx].payload, pop_data_o);
                        test_fail = 1'b1;
                    end
                    if (pop_en_i) begin
                        ref_store.delete(match_idx);
                    end
                end else begin
                    if (pop_data_valid_o) begin
                        $display("FAIL: R10 - pop_data_valid_o should be low when no entry exists");
                        test_fail = 1'b1;
                    end
                end
            end

            // R4: Push commit
            if (push_req_i && push_gnt_o) begin
                if (sz < 8) begin
                    new_entry.tag = push_tag_i;
                    new_entry.payload = push_data_i;
                    ref_store.push_back(new_entry);
                end else begin
                    $display("FAIL: R4/R5 - push granted when full");
                    test_fail = 1'b1;
                end
            end

            // R11, R12, R13: Search
            if (match_req_i[0] && match_gnt_o[0]) begin
                hit = 1'b0;
                for (i = 0; i < ref_store.size(); i++) begin
                    if ((ref_store[i].payload & match_mask_i[0]) == (match_data_i[0] & match_mask_i[0])) begin
                        hit = 1'b1;
                        break;
                    end
                end
                if (match_hit_o[0] !== hit) begin
                    $display("FAIL: R12 - match_hit_o[0] mismatch. Expected %0b, got %0b", hit, match_hit_o[0]);
                    test_fail = 1'b1;
                end
                if (match_mask_i[0] == 0) begin
                    if (ref_store.size() > 0 && !match_hit_o[0]) begin
                        $display("FAIL: R13 - match_hit_o[0] should be high for zero mask when non-empty");
                        test_fail = 1'b1;
                    end
                end
            end
        end
    end

    // Test Tasks
    task automatic test_r15();
        $display("Testing R15: Reset behavior");
        bfm_reset(4);
        bfm_drive_point();
        bfm_tick();
    endtask

    task automatic push_entry(input logic [2:0] tag, input logic [31:0] data, input int timeout = 100);
        bfm_drive_point();
        push_req_i = 1'b1;
        push_tag_i = tag;
        push_data_i = data;
        int count = 0;
        while (count < timeout) begin
            bfm_tick();
            if (push_gnt_o) begin
                push_req_i = 1'b0;
                return;
            end
            count++;
        end
        $display("FAIL: R4 - push timeout");
        test_fail = 1'b1;
    endtask

    task automatic pop_entry(input logic [2:0] tag, input logic en, output logic valid, output logic [31:0] data, input int timeout = 100);
        bfm_drive_point();
        pop_req_i = 1'b1;
        pop_tag_i = tag;
        pop_en_i = en;
        int count = 0;
        while (count < timeout) begin
            bfm_tick();
            if (pop_gnt_o) begin
                valid = pop_data_valid_o;
                data = pop_data_o;
                pop_req_i = 1'b0;
                return;
            end
            count++;
        end
        $display("FAIL: R7 - pop timeout");
        test_fail = 1'b1;
    endtask

    task automatic search_entry(input logic [31:0] m_data, input logic [31:0] m_mask, output logic hit, input int timeout = 100);
        bfm_drive_point();
        match_req_i[0] = 1'b1;
        match_data_i[0] = m_data;
        match_mask_i[0] = m_mask;
        int count = 0;
        while (count < timeout) begin
            bfm_tick();
            if (match_gnt_o[0]) begin
                hit = match_hit_o[0];
                match_req_i[0] = 1'b0;
                return;
            end
            count++;
        end
        $display("FAIL: R11 - search timeout");
        test_fail = 1'b1;
    endtask

    // Main Test Sequence
    initial begin
        bfm_drive_point();
        push_req_i = 1'b0;
        pop_req_i = 1'b0;
        match_req_i[0] = 1'b0;
        pop_en_i = 1'b0;

        test_r15();
        if (test_fail) return;

        // 1. Push 8 entries of tag 0 (R1, R4)
        $display("Testing R1, R4: Push 8 entries of tag 0");
        for (int i = 0; i < 8; i++) begin
            push_entry(3'h0, 32'h1000_0000 + i, 100);
            if (test_fail) return;
        end

        // 2. Verify full (R5, R14)
        $display("Testing R5, R14: Full store behavior");
        bfm_drive_point();
        push_req_i = 1'b1;
        bfm_tick();
        if (push_gnt_o) begin
            $display("FAIL: R5 - push_gnt_o is high when store is full");
            test_fail = 1'b1;
        end
        push_req_i = 1'b0;
        if (test_fail) return;

        // 3. Pop tag 0 with en=1, verify FIFO (R2, R8, R9)
        $display("Testing R2, R8, R9: Pop tag 0 with en=1, verify FIFO");
        logic valid;
        logic [31:0] data;
        pop_entry(3'h0, 1'b1, valid, data, 100);
        if (test_fail) return;
        if (!valid || data != 32'h1000_0000) begin
            $display("FAIL: R2, R8 - pop_data mismatch. Expected 32'h1000_0000, got %0h", data);
            test_fail = 1'b1;
        end
        if (test_fail) return;

        // 4. Pop tag 0 with en=0, verify inspection (R9)
        $display("Testing R9: Pop tag 0 with en=0 (inspect)");
        pop_entry(3'h0, 1'b0, valid, data, 100);
        if (test_fail) return;
        if (!valid || data != 32'h1000_0001) begin
            $display("FAIL: R9 - pop_data mismatch on inspect. Expected 32'h1000_0001, got %0h", data);
            test_fail = 1'b1;
        end
        if (test_fail) return;

        // 5. Pop tag 0 with en=1, verify it was not removed by en=0 (R9)
        $display("Testing R9: Pop tag 0 with en=1, verify previous inspect did not remove");
        pop_entry(3'h0, 1'b1, valid, data, 100);
        if (test_fail) return;
        if (!valid || data != 32'h1000_0001) begin
            $display("FAIL: R9 - pop_data mismatch. Expected 32'h1000_0001, got %0h", data);
            test_fail = 1'b1;
        end
        if (test_fail) return;

        // 6. Pop non-existent tag (R10)
        $display("Testing R10: Pop non-existent tag");
        pop_entry(3'h7, 1'b1, valid, data, 100);
        if (test_fail) return;
        if (valid) begin
            $display("FAIL: R10 - pop_data_valid_o should be low for non-existent tag");
            test_fail = 1'b1;
        end
        if (test_fail) return;

        // 7. Search with match (R12)
        $display("Testing R12: Search with match");
        logic hit;
        search_entry(32'h1000_0005, 32'hFFFF_FFFF, hit, 100);
        if (test_fail) return;
        if (!hit) begin
            $display("FAIL: R12 - match_hit_o should be high for matching payload");
            test_fail = 1'b1;
        end
        if (test_fail) return;

        // 8. Search with no match (R12)
        $display("Testing R12: Search with no match");
        search_entry(32'hDEAD_BEEF, 32'hFFFF_FFFF, hit, 100);
        if (test_fail) return;
        if (hit) begin
            $display("FAIL: R12 - match_hit_o should be low for non-matching payload");
            test_fail = 1'b1;
        end
        if (test_fail) return;

        // 9. Search with zero mask (R13)
        $display("Testing R13: Search with zero mask");
        search_entry(32'h0000_0000, 32'h0000_0000, hit, 100);
        if (test_fail) return;
        if (!hit) begin
            $display("FAIL: R13 - match_hit_o should be high for zero mask when non-empty");
            test_fail = 1'b1;
        end
        if (test_fail) return;

        // 10. Push more entries to verify shared capacity (R1)
        $display("Testing R1: Shared capacity across tags");
        push_entry(3'h1, 32'h2000_0000, 100);
        push_entry(3'h2, 32'h3000_0000, 100);
        if (test_fail) return;

        // Verify full again
        bfm_drive_point();
        push_req_i = 1'b1;
        bfm_tick();
        if (push_gnt_o) begin
            $display("FAIL: R5 - push_gnt_o is high when store is full");
            test_fail = 1'b1;
        end
        push_req_i = 1'b0;
        if (test_fail) return;

        $display("All tests passed!");
        test_pass = 1'b1;
    end

    // Final Result Reporter
    initial begin
        wait (test_pass || test_fail);
        #10;
        if (test_pass) begin
            $display("RESULT: PASS");
        end else begin
            $display("RESULT: FAIL");
        end
        $finish;
    end

endmodule