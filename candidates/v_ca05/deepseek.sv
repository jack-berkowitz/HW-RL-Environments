module tag_tracker_tb;

    localparam int TAG_W = 3;
    localparam int SLOTS = 8;
    localparam int N_MATCH = 1;
    localparam bit FULL_RATE = 0;
    localparam bit CUT_POP_PATH = 0;

    localparam int unsigned GRANT_TIMEOUT = 200000;
    localparam int unsigned WATCHDOG_LIMIT = 1000000;

    typedef logic[31:0] payload_t;
    typedef logic[TAG_W-1:0] tag_t;

    logic clk_i;
    logic rst_ni;

    tag_t  push_tag_i;
    payload_t push_data_i;
    logic  push_req_i;
    logic  push_gnt_o;

    payload_t match_data_i [0:0];
    payload_t match_mask_i [0:0];
    logic [0:0] match_req_i;
    logic [0:0] match_hit_o;
    logic [0:0] match_gnt_o;

    tag_t  pop_tag_i;
    logic  pop_en_i;
    logic  pop_req_i;
    payload_t pop_data_o;
    logic  pop_data_valid_o;
    logic  pop_gnt_o;

    logic  full_o;
    logic  empty_o;

    // Reference model
    payload_t q[8][$];
    int unsigned total_entries = 0;

    bit watchdog_done = 0;

    tag_tracker #(
        .TAG_W(TAG_W),
        .SLOTS(SLOTS),
        .FULL_RATE(FULL_RATE),
        .CUT_POP_PATH(CUT_POP_PATH),
        .N_MATCH(N_MATCH),
        .payload_t(logic[31:0])
    ) dut (
        .clk_i(clk_i),
        .rst_ni(rst_ni),
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

    // Clock generator
    initial begin
        clk_i = 1'b0;
        forever #5 clk_i = ~clk_i;
    end

    // Watchdog: must never allow the testbench to hang forever
    initial begin
        repeat (WATCHDOG_LIMIT) @(posedge clk_i);
        if (!watchdog_done) begin
            $display("FAIL [watchdog] timeout waiting for test completion");
            $display("RESULT: FAIL");
            $finish;
        end
    end

    task automatic fail(string req, string msg);
        $display("FAIL [%s] %s", req, msg);
        $display("RESULT: FAIL");
        $finish;
    endtask

    task automatic check_status(string req);
        logic exp_empty = (total_entries == 0);
        logic exp_full  = (total_entries == SLOTS);
        if (empty_o !== exp_empty) fail(req, "empty_o/full_o mismatch");
        if (full_o  !== exp_full)  fail(req, "empty_o/full_o mismatch");
    endtask

    task automatic reset_dut();
        rst_ni = 1'b0;
        push_req_i = 1'b0;
        pop_req_i = 1'b0;
        match_req_i[0] = 1'b0;
        push_tag_i = '0;
        push_data_i = '0;
        pop_tag_i = '0;
        pop_en_i = 1'b0;
        match_data_i[0] = '0;
        match_mask_i[0] = '0;
        for (int i = 0; i < 8; i++) q[i].delete();
        total_entries = 0;
        repeat (4) @(posedge clk_i);
        rst_ni = 1'b1;
        repeat (2) @(posedge clk_i);
    endtask

    task automatic do_push(tag_t tag, payload_t data, int timeout_cycles, string req);
        int idx = int'(tag);
        @(negedge clk_i);
        push_tag_i = tag;
        push_data_i = data;
        push_req_i = 1'b1;
        for (int i = 0; i < timeout_cycles; i++) begin
            @(posedge clk_i);
            if (push_req_i === 1'b1 && push_gnt_o === 1'b1) begin
                q[idx].push_back(data);
                total_entries++;
                push_req_i = 1'b0;
                return;
            end
        end
        fail(req, "push_gnt not asserted within timeout");
    endtask

    task automatic do_pop(tag_t tag, logic pop_en, logic expected_valid,
                          payload_t expected_data, int timeout_cycles, string req);
        int idx = int'(tag);
        @(negedge clk_i);
        pop_tag_i = tag;
        pop_en_i = pop_en;
        pop_req_i = 1'b1;
        for (int i = 0; i < timeout_cycles; i++) begin
            @(posedge clk_i);
            if (pop_req_i === 1'b1 && pop_gnt_o === 1'b1) begin
                if (expected_valid) begin
                    if (pop_data_valid_o !== 1'b1)
                        fail(req, "pop_data_valid_o expected high");
                    if (pop_data_o !== expected_data)
                        fail(req, "pop_data_o did not match expected oldest entry");
                end else begin
                    if (pop_data_valid_o !== 1'b0)
                        fail(req, "pop_data_valid_o expected low for empty tag");
                end

                if (pop_en === 1'b1 && expected_valid) begin
                    if (q[idx].size() == 0)
                        fail(req, "internal model queue unexpectedly empty");
                    payload_t d = q[idx].pop_front();
                    if (d !== expected_data)
                        fail(req, "internal model mismatch on pop_front");
                    total_entries--;
                end

                pop_req_i = 1'b0;
                pop_en_i = 1'b0;
                return;
            end
        end
        fail(req, "pop_gnt not asserted within timeout");
    endtask

    task automatic do_search(payload_t data, payload_t mask, logic exp_hit, string req);
        @(negedge clk_i);
        match_data_i[0] = data;
        match_mask_i[0] = mask;
        match_req_i[0] = 1'b1;
        for (int i = 0; i < GRANT_TIMEOUT; i++) begin
            @(posedge clk_i);
            if (match_req_i[0] === 1'b1 && match_gnt_o[0] === 1'b1) begin
                if (match_hit_o[0] !== exp_hit)
                    fail(req, "match_hit_o mismatch");
                match_req_i[0] = 1'b0;
                return;
            end
        end
        fail(req, "match_gnt not asserted within timeout");
    endtask

    initial begin
        reset_dut();
        if (empty_o !== 1'b1) fail("R15", "empty_o not high after reset");
        if (full_o  !== 1'b0) fail("R15", "full_o not low after reset");
        check_status("R14/R15");

        // R1/R2: capacity, and per-tag FIFO order for a single tag
        for (int i = 0; i < SLOTS; i++) begin
            payload_t p;
            p = 32'h100 + i;
            do_push(3'd0, p, GRANT_TIMEOUT, "R1");
            check_status("R1/R14");
        end
        if (full_o !== 1'b1) fail("R5/R14", "full_o not high after SLOTS pushes");
        if (empty_o !== 1'b0) fail("R14", "empty_o not low after SLOTS pushes");

        // R13: all-zero mask matches every entry when store is non-empty
        do_search(32'h0, 32'h0, 1'b1, "R13");
        check_status("R13");

        // R5: push_gnt must be low when the store is full
        begin
            @(negedge clk_i);
            push_tag_i = 3'd1;
            push_data_i = 32'hDEADBEEF;
            push_req_i = 1'b1;
            for (int i = 0; i < 4; i++) begin
                @(posedge clk_i);
                if (push_gnt_o !== 1'b0)
                    fail("R5", "push_gnt_o high when full");
            end
            push_req_i = 1'b0;
            @(posedge clk_i);
        end
        check_status("R5/R14");

        // R2/R9: pop all entries of tag0 in FIFO order
        for (int i = 0; i < SLOTS; i++) begin
            payload_t expected;
            expected = 32'h100 + i;
            do_pop(3'd0, 1'b1, 1'b1, expected, GRANT_TIMEOUT, "R2");
            check_status("R2/R14");
        end
        if (empty_o !== 1'b1) fail("R14", "empty_o not high after popping all");
        if (full_o  !== 1'b0) fail("R14", "full_o not low after popping all");

        // R10: pop of a tag with no entries completes with valid low
        do_pop(3'd3, 1'b1, 1'b0, '0, GRANT_TIMEOUT, "R10");
        check_status("R10");

        // R13: all-zero mask on empty store: hit low
        do_search(32'h0, 32'h0, 1'b0, "R13 empty");
        check_status("R13 empty");

        // R9: pop_en=0 inspects but does not remove
        do_push(3'd4, 32'hAAAA5555, GRANT_TIMEOUT, "R9");
        check_status("R9 push");
        do_pop(3'd4, 1'b0, 1'b1, 32'hAAAA5555, GRANT_TIMEOUT, "R9 inspect");
        check_status("R9 inspect");
        do_pop(3'd4, 1'b1, 1'b1, 32'hAAAA5555, GRANT_TIMEOUT, "R9 remove");
        check_status("R9 remove");
        if (empty_o !== 1'b1) fail("R14", "empty_o not high after inspect/remove");
        if (full_o  !== 1'b0) fail("R14", "full_o not low after inspect/remove");

        // R2: per-tag FIFO order with interleaved tags
        do_push(3'd1, 32'hB1, GRANT_TIMEOUT, "R2");
        do_push(3'd2, 32'hC1, GRANT_TIMEOUT, "R2");
        do_push(3'd1, 32'hB2, GRANT_TIMEOUT, "R2");
        do_push(3'd2, 32'hC2, GRANT_TIMEOUT, "R2");
        do_push(3'd1, 32'hB3, GRANT_TIMEOUT, "R2");
        check_status("R2 interleaved push");
        do_pop(3'd1, 1'b1, 1'b1, 32'hB1, GRANT_TIMEOUT, "R2");
        do_pop(3'd1, 1'b1, 1'b1, 32'hB2, GRANT_TIMEOUT, "R2");
        do_pop(3'd1, 1'b1, 1'b1, 32'hB3, GRANT_TIMEOUT, "R2");
        do_pop(3'd2, 1'b1, 1'b1, 32'hC1, GRANT_TIMEOUT, "R2");
        do_pop(3'd2, 1'b1, 1'b1, 32'hC2, GRANT_TIMEOUT, "R2");
        check_status("R2 interleaved pop");
        if (empty_o !== 1'b1) fail("R14", "empty_o not high after interleaved pops");

        // R12: content-addressed search across all tags
        reset_dut();
        if (empty_o !== 1'b1) fail("R15", "empty_o not high after reset");
        if (full_o  !== 1'b0) fail("R15", "full_o not low after reset");
        check_status("R14/R15 reset2");

        do_push(3'd0, 32'h0000000F, GRANT_TIMEOUT, "R12 setup");
        do_push(3'd1, 32'h000000F0, GRANT_TIMEOUT, "R12 setup");
        do_push(3'd2, 32'hF0000000, GRANT_TIMEOUT, "R12 setup");
        do_push(3'd1, 32'h000000FF, GRANT_TIMEOUT, "R12 setup");
        check_status("R12 setup");

        do_search(32'h0000000F, 32'h0000000F, 1'b1, "R12 hit low nibble F");
        do_search(32'h00000000, 32'h0000000F, 1'b1, "R12 hit low nibble 0");
        do_search(32'h000000AB, 32'h000000FF, 1'b0, "R12 no match byte AB");
        do_search(32'h12345678, 32'h00000000, 1'b1, "R13 mask zero");
        do_search(32'hF0000000, 32'hF0000000, 1'b1, "R12 high nibble F");
        do_search(32'h00000000, 32'h80000000, 1'b1, "R12 bit31 zero");
        do_search(32'h80000000, 32'h80000000, 1'b1, "R12 bit31 one");
        do_search(32'h0000000F, 32'hF000000F, 1'b1, "R12 combined mask");

        do_pop(3'd1, 1'b1, 1'b1, 32'h000000F0, GRANT_TIMEOUT, "R12 after pop");
        do_pop(3'd1, 1'b1, 1'b1, 32'h000000FF, GRANT_TIMEOUT, "R12 after pop");
        do_search(32'h0000000F, 32'h0000000F, 1'b1, "R12 after removing tag1");
        do_search(32'hF0000000, 32'hF0000000, 1'b1, "R12 high after removing tag1");
        do_search(32'h000000FF, 32'h000000FF, 1'b0, "R12 no match FF after removal");
        check_status("R12 after pops");

        watchdog_done = 1;
        $display("RESULT: PASS");
        $finish;
    end

endmodule