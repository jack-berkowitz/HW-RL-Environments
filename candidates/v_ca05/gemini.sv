module tag_tracker_tb;

    parameter int TAG_W = 3;
    parameter int SLOTS = 8;
    parameter bit FULL_RATE = 0;
    parameter bit CUT_POP_PATH = 0;
    parameter int N_MATCH = 1;

    typedef logic [31:0] payload_t;
    typedef logic [TAG_W-1:0] tag_t;

    // Clock and reset
    logic clk_i = 0;
    logic rst_ni;

    // Push interface
    tag_t     push_tag_i;
    payload_t push_data_i;
    logic     push_req_i;
    logic     push_gnt_o;

    // Search interface
    payload_t [N_MATCH-1:0] match_data_i;
    payload_t [N_MATCH-1:0] match_mask_i;
    logic     [N_MATCH-1:0] match_req_i;
    logic     [N_MATCH-1:0] match_hit_o;
    logic     [N_MATCH-1:0] match_gnt_o;

    // Pop interface
    tag_t     pop_tag_i;
    logic     pop_en_i;
    logic     pop_req_i;
    payload_t pop_data_o;
    logic     pop_data_valid_o;
    logic     pop_gnt_o;

    // Status interface
    logic     full_o;
    logic     empty_o;

    // Clock generator (only allowed use of # delay)
    always #5 clk_i = ~clk_i;

    // DUT Instantiation
    tag_tracker #(
        .TAG_W(TAG_W),
        .SLOTS(SLOTS),
        .FULL_RATE(FULL_RATE),
        .CUT_POP_PATH(CUT_POP_PATH),
        .N_MATCH(N_MATCH),
        .payload_t(payload_t)
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

    // Reference model & error tracking
    payload_t ref_queue [0:7][$];
    bit reset_active = 1'b0;
    int err_count = 0;
    int req_err_cnt [16];

    task automatic log_error(int req_num, string msg);
        err_count++;
        if (req_err_cnt[req_num] < 5) begin
            $display("[FAIL] R%0d: %s", req_num, msg);
        end
        req_err_cnt[req_num]++;
    endtask

    function automatic int get_total_count();
        int cnt = 0;
        for (int i = 0; i < 8; i++) begin
            cnt += ref_queue[i].size();
        end
        return cnt;
    endfunction

    function automatic bit check_match(payload_t m_data, payload_t m_mask);
        for (int t = 0; t < 8; t++) begin
            for (int e = 0; e < ref_queue[t].size(); e++) begin
                if ((ref_queue[t][e] & m_mask) == (m_data & m_mask)) begin
                    return 1'b1;
                end
            end
        end
        return 1'b0;
    endfunction

    // Continuous passive monitor and reference model checker
    always @(posedge clk_i) begin
        if (!rst_ni) begin
            reset_active <= 1'b1;
            for (int t = 0; t < 8; t++) begin
                ref_queue[t].delete();
            end
            if (empty_o !== 1'b1) begin
                log_error(15, "empty_o was not 1 during reset");
            end
            if (full_o !== 1'b0) begin
                log_error(15, "full_o was not 0 during reset");
            end
        end else begin
            if (reset_active) begin
                reset_active <= 1'b0;
                if (empty_o !== 1'b1) begin
                    log_error(15, "empty_o was not 1 immediately after reset release");
                end
                if (full_o !== 1'b0) begin
                    log_error(15, "full_o was not 0 immediately after reset release");
                end
            end

            begin
                int cur_total = get_total_count();

                // R14: empty_o and full_o status flags
                if (cur_total == 0) begin
                    if (empty_o !== 1'b1) log_error(14, "empty_o should be 1 when store is empty");
                    if (full_o !== 1'b0)  log_error(14, "full_o should be 0 when store is empty");
                end else if (cur_total == SLOTS) begin
                    if (empty_o !== 1'b0) log_error(14, "empty_o should be 0 when store is full");
                    if (full_o !== 1'b1)  log_error(14, "full_o should be 1 when store is full");
                end else begin
                    if (empty_o !== 1'b0) log_error(14, "empty_o should be 0 when partially filled");
                    if (full_o !== 1'b0)  log_error(14, "full_o should be 0 when partially filled");
                end

                // R5: push_gnt_o low when store holds SLOTS entries
                if (cur_total == SLOTS && push_req_i) begin
                    if (push_gnt_o !== 1'b0) begin
                        log_error(5, "push_gnt_o was high when store held SLOTS entries");
                    end
                end

                // R8, R10, R2: Pop output checks on completing pop
                if (pop_req_i && pop_gnt_o) begin
                    int tag_cnt = ref_queue[pop_tag_i].size();
                    if (tag_cnt > 0) begin
                        if (pop_data_valid_o !== 1'b1) begin
                            log_error(8, "pop_data_valid_o should be 1 for tag with entries");
                        end
                        if (pop_data_o !== ref_queue[pop_tag_i][0]) begin
                            log_error(8, "pop_data_o mismatch with oldest tag entry (R2/R8)");
                        end
                    end else begin
                        if (pop_data_valid_o !== 1'b0) begin
                            log_error(8, "pop_data_valid_o should be 0 for empty tag (R8/R10)");
                        end
                    end
                end

                // R12, R13: Search checks on completing match
                if (match_req_i[0] && match_gnt_o[0]) begin
                    bit exp_hit = check_match(match_data_i[0], match_mask_i[0]);
                    if (match_hit_o[0] !== exp_hit) begin
                        if (match_mask_i[0] == 32'd0) begin
                            log_error(13, "match_hit_o[0] incorrect for zero mask");
                        end else begin
                            log_error(12, "match_hit_o[0] incorrect for search mask/data");
                        end
                    end
                end

                // State updates on clock edge
                if (push_req_i && push_gnt_o) begin
                    ref_queue[push_tag_i].push_back(push_data_i);
                end

                if (pop_req_i && pop_gnt_o && pop_en_i) begin
                    if (ref_queue[pop_tag_i].size() > 0) begin
                        void'(ref_queue[pop_tag_i].pop_front());
                    end
                end
            end
        end
    end

    // Unified driver task
    task automatic concurrent_op(
        input bit do_push,
        input tag_t p_tag,
        input payload_t p_data,

        input bit do_pop,
        input tag_t o_tag,
        input bit o_en,

        input bit do_match,
        input payload_t m_data,
        input payload_t m_mask,

        output bit p_ok,
        output bit o_ok,
        output bit m_ok,
        output bit o_valid,
        output bit m_hit,
        output payload_t o_data
    );
        int timeout = 50;
        bit p_act = do_push;
        bit o_act = do_pop;
        bit m_act = do_match;

        p_ok = !do_push;
        o_ok = !do_pop;
        m_ok = !do_match;
        o_valid = 1'b0;
        m_hit = 1'b0;
        o_data = '0;

        @(negedge clk_i);
        if (p_act) begin
            push_req_i  = 1'b1;
            push_tag_i  = p_tag;
            push_data_i = p_data;
        end
        if (o_act) begin
            pop_req_i = 1'b1;
            pop_tag_i = o_tag;
            pop_en_i  = o_en;
        end
        if (m_act) begin
            match_req_i[0]  = 1'b1;
            match_data_i[0] = m_data;
            match_mask_i[0] = m_mask;
        end

        while (timeout > 0 && (p_act || o_act || m_act)) begin
            @(posedge clk_i);

            begin
                bit p_g = p_act && push_gnt_o;
                bit o_g = o_act && pop_gnt_o;
                bit m_g = m_act && match_gnt_o[0];

                if (p_g) p_ok = 1'b1;
                if (o_g) begin
                    o_ok = 1'b1;
                    o_valid = pop_data_valid_o;
                    o_data = pop_data_o;
                end
                if (m_g) begin
                    m_ok = 1'b1;
                    m_hit = match_hit_o[0];
                end

                @(negedge clk_i);
                if (p_g) begin p_act = 1'b0; push_req_i = 1'b0; end
                if (o_g) begin o_act = 1'b0; pop_req_i = 1'b0; pop_en_i = 1'b0; end
                if (m_g) begin m_act = 1'b0; match_req_i[0] = 1'b0; end
            end

            timeout--;
        end

        push_req_i = 1'b0;
        pop_req_i  = 1'b0;
        pop_en_i   = 1'b0;
        match_req_i[0] = 1'b0;
    endtask

    // Helper wrappers
    task automatic push_single(input tag_t tag, input payload_t data, output bit ok);
        bit dummy_o_ok, dummy_m_ok, dummy_v, dummy_h;
        payload_t dummy_d;
        concurrent_op(1'b1, tag, data, 1'b0, '0, 1'b0, 1'b0, '0, '0, ok, dummy_o_ok, dummy_m_ok, dummy_v, dummy_h, dummy_d);
    endtask

    task automatic pop_single(input tag_t tag, input bit en, output bit ok, output bit valid_out, output payload_t data_out);
        bit dummy_p_ok, dummy_m_ok, dummy_h;
        concurrent_op(1'b0, '0, '0, 1'b1, tag, en, 1'b0, '0, '0, dummy_p_ok, ok, dummy_m_ok, valid_out, dummy_h, data_out);
    endtask

    task automatic match_single(input payload_t m_data, input payload_t m_mask, output bit ok, output bit hit_out);
        bit dummy_p_ok, dummy_o_ok, dummy_v;
        payload_t dummy_d;
        concurrent_op(1'b0, '0, '0, 1'b0, '0, 1'b0, 1'b1, m_data, m_mask, dummy_p_ok, dummy_o_ok, ok, dummy_v, hit_out, dummy_d);
    endtask

    task automatic do_reset();
        @(negedge clk_i);
        rst_ni = 1'b0;
        push_req_i = 1'b0;
        pop_req_i = 1'b0;
        pop_en_i = 1'b0;
        match_req_i[0] = 1'b0;
        match_data_i[0] = '0;
        match_mask_i[0] = '0;
        repeat (3) @(negedge clk_i);
        rst_ni = 1'b1;
        @(negedge clk_i);
    endtask

    // Main Test Sequence
    initial begin
        rst_ni = 1'b1;
        push_req_i = 1'b0;
        push_tag_i = '0;
        push_data_i = '0;
        pop_req_i = 1'b0;
        pop_tag_i = '0;
        pop_en_i = 1'b0;
        match_req_i[0] = 1'b0;
        match_data_i[0] = '0;
        match_mask_i[0] = '0;

        // Phase 1: Reset Test (R15, R14)
        do_reset();

        // Phase 2: Single Tag Capacity & FIFO Order (R1, R2, R5, R8, R9, R14)
        for (int i = 0; i < 8; i++) begin
            bit ok;
            payload_t val = 32'hA000_0001 + i;
            push_single(3'd0, val, ok);
            if (!ok) begin
                log_error(1, "Failed to push entry to store when not full");
            end
        end

        // Full status check
        if (full_o !== 1'b1) begin
            log_error(14, "full_o not set when store reached capacity");
        end

        // R5: Attempt push when full
        @(negedge clk_i);
        push_req_i = 1'b1;
        push_tag_i = 3'd0;
        push_data_i = 32'hFFFF_FFFF;
        repeat (3) begin
            @(posedge clk_i);
            if (push_gnt_o !== 1'b0) begin
                log_error(5, "push_gnt_o was high when store was full");
            end
        end
        @(negedge clk_i);
        push_req_i = 1'b0;

        // R9: Inspect (pop_en_i = 0) vs Remove (pop_en_i = 1)
        begin
            bit ok, v;
            payload_t d;

            // Inspect entry 1
            pop_single(3'd0, 1'b0, ok, v, d);
            if (!ok || !v || d !== 32'hA000_0001) begin
                log_error(9, "Inspection pop (pop_en_i=0) failed or returned incorrect data");
            end

            // Inspect entry 1 again (verify non-removal)
            pop_single(3'd0, 1'b0, ok, v, d);
            if (!ok || !v || d !== 32'hA000_0001) begin
                log_error(9, "Second inspection pop failed or entry was removed on pop_en_i=0");
            end

            // Remove entry 1
            pop_single(3'd0, 1'b1, ok, v, d);
            if (!ok || !v || d !== 32'hA000_0001) begin
                log_error(9, "Pop with pop_en_i=1 failed");
            end
        end

        // Pop remaining entries on Tag 0 (R2 FIFO order check)
        for (int i = 1; i < 8; i++) begin
            bit ok, v;
            payload_t d;
            payload_t exp_v = 32'hA000_0001 + i;
            pop_single(3'd0, 1'b1, ok, v, d);
            if (!ok || !v || d !== exp_v) begin
                log_error(2, "Per-tag FIFO order violated on pop");
            end
        end

        // R10: Pop empty tag
        begin
            bit ok, v;
            payload_t d;
            pop_single(3'd0, 1'b1, ok, v, d);
            if (!ok || v !== 1'b0) begin
                log_error(10, "Pop of empty tag returned pop_data_valid_o=1");
            end
        end

        // Phase 3: Multi-Tag Distribution Capacity Test (R1, R14)
        for (int t = 0; t < 8; t++) begin
            bit ok;
            push_single(t[2:0], 32'hB000_0000 | t, ok);
            if (!ok) begin
                log_error(1, "Store failed to accept multi-tag distribution entries");
            end
        end

        if (full_o !== 1'b1) begin
            log_error(14, "full_o not set for multi-tag full store");
        end

        // Pop multi-tag entries in reverse tag order
        for (int t = 7; t >= 0; t--) begin
            bit ok, v;
            payload_t d;
            pop_single(t[2:0], 1'b1, ok, v, d);
            if (!ok || !v || d !== (32'hB000_0000 | t)) begin
                log_error(2, "Multi-tag pop returned incorrect data");
            end
        end

        // Phase 4: Content Addressable Match Tests (R11, R12, R13)
        // Zero mask on empty store
        begin
            bit ok, h;
            match_single(32'h0, 32'h0, ok, h);
            if (!ok || h !== 1'b0) begin
                log_error(13, "Match with zero mask on empty store returned hit=1");
            end
        end

        // Push test payloads for search
        begin
            bit ok;
            push_single(3'd1, 32'h1234_5678, ok);
            push_single(3'd3, 32'hABCD_EF00, ok);
            push_single(3'd5, 32'h1234_9999, ok);
        end

        // Zero mask on non-empty store (R13)
        begin
            bit ok, h;
            match_single(32'h0, 32'h0, ok, h);
            if (!ok || h !== 1'b1) begin
                log_error(13, "Match with zero mask on non-empty store returned hit=0");
            end
        end

        // Exact match (R12)
        begin
            bit ok, h;
            match_single(32'hABCD_EF00, 32'hFFFF_FFFF, ok, h);
            if (!ok || h !== 1'b1) begin
                log_error(12, "Exact payload match failed");
            end
        end

        // Masked match (R12)
        begin
            bit ok, h;
            match_single(32'h1234_0000, 32'hFFFF_0000, ok, h);
            if (!ok || h !== 1'b1) begin
                log_error(12, "Partial mask match failed");
            end
        end

        // Non-matching query (R12)
        begin
            bit ok, h;
            match_single(32'h9999_0000, 32'hFFFF_0000, ok, h);
            if (!ok || h !== 1'b0) begin
                log_error(12, "Search returned hit=1 for non-existent payload");
            end
        end

        // Empty store after match tests
        begin
            bit ok, v; payload_t d;
            pop_single(3'd1, 1'b1, ok, v, d);
            pop_single(3'd3, 1'b1, ok, v, d);
            pop_single(3'd5, 1'b1, ok, v, d);
        end

        // Phase 5: Concurrent Operations Test
        begin
            bit p_ok, o_ok, m_ok, v, h;
            payload_t d;
            concurrent_op(
                1'b1, 3'd2, 32'hC000_1111,
                1'b0, 3'd0, 1'b0,
                1'b1, 32'hC000_1111, 32'hFFFF_FFFF,
                p_ok, o_ok, m_ok, v, h, d
            );
        end

        begin
            bit p_ok, o_ok, m_ok, v, h;
            payload_t d;
            concurrent_op(
                1'b0, 3'd0, 32'd0,
                1'b1, 3'd2, 1'b1,
                1'b1, 32'hC000_1111, 32'hFFFF_FFFF,
                p_ok, o_ok, m_ok, v, h, d
            );
        end

        // Phase 6: Mid-Operation Reset Test (R15)
        for (int i = 0; i < 5; i++) begin
            bit ok;
            push_single(i[2:0], 32'hDEAD_0000 | i, ok);
        end

        do_reset();

        for (int t = 0; t < 8; t++) begin
            bit ok, v;
            payload_t d;
            pop_single(t[2:0], 1'b1, ok, v, d);
            if (v !== 1'b0) begin
                log_error(15, "Tag entries persisted across reset");
            end
        end

        // Completion & Result Output
        repeat (5) @(posedge clk_i);
        if (err_count == 0) begin
            $display("RESULT: PASS");
        end else begin
            $display("RESULT: FAIL");
        end
        $finish;
    end

endmodule