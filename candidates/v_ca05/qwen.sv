module tag_tracker_tb;

    localparam int TAG_W      = 3;
    localparam int SLOTS      = 8;
    localparam int N_MATCH    = 1;
    localparam int PAYLOAD_W  = 32;

    typedef logic [TAG_W-1:0]     tag_t;
    typedef logic [PAYLOAD_W-1:0] payload_t;

    logic clk_i;
    logic rst_ni;

    tag_t     push_tag_i;
    payload_t push_data_i;
    logic     push_req_i;
    logic     push_gnt_o;

    payload_t [N_MATCH-1:0] match_data_i;
    payload_t [N_MATCH-1:0] match_mask_i;
    logic     [N_MATCH-1:0] match_req_i;
    logic     [N_MATCH-1:0] match_hit_o;
    logic     [N_MATCH-1:0] match_gnt_o;

    tag_t     pop_tag_i;
    logic     pop_en_i;
    logic     pop_req_i;
    payload_t pop_data_o;
    logic     pop_data_valid_o;
    logic     pop_gnt_o;

    logic full_o;
    logic empty_o;

    int fail_count = 0;

    initial begin
        clk_i = 0;
        forever #5 clk_i = ~clk_i;
    end

    initial begin
        #1000000;
        $display("WATCHDOG TIMEOUT - testbench hung");
        $display("RESULT: FAIL");
        $finish;
    end

    tag_tracker #(
        .TAG_W        (TAG_W),
        .SLOTS        (SLOTS),
        .FULL_RATE    (0),
        .CUT_POP_PATH (0),
        .N_MATCH      (N_MATCH),
        .payload_t    (payload_t)
    ) dut (
        .clk_i             (clk_i),
        .rst_ni            (rst_ni),
        .push_tag_i        (push_tag_i),
        .push_data_i       (push_data_i),
        .push_req_i        (push_req_i),
        .push_gnt_o        (push_gnt_o),
        .match_data_i      (match_data_i),
        .match_mask_i      (match_mask_i),
        .match_req_i       (match_req_i),
        .match_hit_o       (match_hit_o),
        .match_gnt_o       (match_gnt_o),
        .pop_tag_i         (pop_tag_i),
        .pop_en_i          (pop_en_i),
        .pop_req_i         (pop_req_i),
        .pop_data_o        (pop_data_o),
        .pop_data_valid_o  (pop_data_valid_o),
        .pop_gnt_o         (pop_gnt_o),
        .full_o            (full_o),
        .empty_o           (empty_o)
    );

    task automatic check(input string req, input logic condition);
        if (!condition) begin
            $display("FAIL: %s", req);
            fail_count++;
        end
    endtask

    task automatic push_entry(input tag_t tag, input payload_t data);
        push_tag_i  = tag;
        push_data_i = data;
        push_req_i  = 1;
        forever begin
            @(posedge clk_i);
            if (push_gnt_o) break;
        end
        @(posedge clk_i);
        push_req_i = 0;
    endtask

    task automatic pop_entry(input tag_t tag, input logic en,
                             output payload_t data, output logic valid);
        pop_tag_i = tag;
        pop_en_i  = en;
        pop_req_i = 1;
        forever begin
            @(posedge clk_i);
            if (pop_gnt_o) begin
                data  = pop_data_o;
                valid = pop_data_valid_o;
                break;
            end
        end
        @(posedge clk_i);
        pop_req_i = 0;
    endtask

    task automatic search_entry(input payload_t data, input payload_t mask,
                                output logic hit);
        match_data_i[0] = data;
        match_mask_i[0] = mask;
        match_req_i[0]  = 1;
        forever begin
            @(posedge clk_i);
            if (match_gnt_o[0]) begin
                hit = match_hit_o[0];
                break;
            end
        end
        @(posedge clk_i);
        match_req_i[0] = 0;
    endtask

    initial begin
        rst_ni        = 0;
        push_tag_i    = 0;
        push_data_i   = 0;
        push_req_i    = 0;
        match_data_i  = 0;
        match_mask_i  = 0;
        match_req_i   = 0;
        pop_tag_i     = 0;
        pop_en_i      = 0;
        pop_req_i     = 0;

        repeat (5) @(posedge clk_i);

        // ---------------------------------------------------------------
        // R15: Reset behavior
        // ---------------------------------------------------------------
        check("R15", empty_o == 1'b1);
        check("R15", full_o  == 1'b0);

        rst_ni = 1;
        repeat (2) @(posedge clk_i);

        check("R15", empty_o == 1'b1);
        check("R15", full_o  == 1'b0);

        // ---------------------------------------------------------------
        // R14: Status after reset
        // ---------------------------------------------------------------
        check("R14", empty_o == 1'b1);
        check("R14", full_o  == 1'b0);

        // ---------------------------------------------------------------
        // R1, R2, R4, R8, R14: Push SLOTS entries (same tag), verify FIFO
        // ---------------------------------------------------------------
        for (int i = 0; i < SLOTS - 1; i++) begin
            push_entry(tag_t'(0), payload_t'(i * 100));
        end
        check("R14", full_o  == 1'b0);
        check("R14", empty_o == 1'b0);

        push_entry(tag_t'(0), payload_t'((SLOTS - 1) * 100));
        check("R1",  full_o  == 1'b1);
        check("R14", empty_o == 1'b0);
        check("R14", full_o  == 1'b1);

        for (int i = 0; i < SLOTS; i++) begin
            payload_t data;
            logic     valid;
            pop_entry(tag_t'(0), 1'b1, data, valid);
            check("R8", valid == 1'b1);
            check("R2", data == payload_t'(i * 100));
        end

        check("R14", empty_o == 1'b1);
        check("R14", full_o  == 1'b0);

        // ---------------------------------------------------------------
        // R9: pop_en_i = 0 inspects but does not remove
        // ---------------------------------------------------------------
        push_entry(tag_t'(1), payload_t'(200));

        payload_t data;
        logic     valid;

        pop_entry(tag_t'(1), 1'b0, data, valid);
        check("R8", valid == 1'b1);
        check("R2", data == payload_t'(200));

        pop_entry(tag_t'(1), 1'b1, data, valid);
        check("R8", valid == 1'b1);
        check("R2", data == payload_t'(200));

        pop_entry(tag_t'(1), 1'b1, data, valid);
        check("R10", valid == 1'b0);

        // ---------------------------------------------------------------
        // R10: Pop of empty tag completes with valid low
        // ---------------------------------------------------------------
        pop_entry(tag_t'(7), 1'b1, data, valid);
        check("R10", valid == 1'b0);

        // ---------------------------------------------------------------
        // R1, R5, R14: Fill store, verify push_gnt_o low when full
        // ---------------------------------------------------------------
        for (int i = 0; i < SLOTS; i++) begin
            push_entry(tag_t'(i % 8), payload_t'(i * 10));
        end

        check("R1",  full_o  == 1'b1);
        check("R14", empty_o == 1'b0);

        push_tag_i  = tag_t'(0);
        push_data_i = payload_t'(999);
        push_req_i  = 1;
        repeat (5) begin
            @(posedge clk_i);
            check("R5", push_gnt_o == 1'b0);
        end
        push_req_i = 0;
        @(posedge clk_i);

        pop_entry(tag_t'(0), 1'b1, data, valid);

        push_entry(tag_t'(0), payload_t'(888));
        check("R14", full_o == 1'b1);

        // ---------------------------------------------------------------
        // R11, R12, R13: Search
        // Store contents: tag 0 -> 888, tags 1..7 -> 10,20,...,70
        // ---------------------------------------------------------------
        logic hit;

        search_entry(payload_t'(32'h888), payload_t'(32'hFFFFFFFF), hit);
        check("R12", hit == 1'b1);

        search_entry(payload_t'(32'h12345678), payload_t'(32'hFFFFFFFF), hit);
        check("R12", hit == 1'b0);

        search_entry(payload_t'(32'h00000000), payload_t'(32'h00000000), hit);
        check("R13", hit == 1'b1);

        search_entry(payload_t'(32'h0000000A), payload_t'(32'hFFFFFFFF), hit);
        check("R12", hit == 1'b1);

        search_entry(payload_t'(32'h00000000), payload_t'(32'hFFFFFFF0), hit);
        check("R12", hit == 1'b1);

        search_entry(payload_t'(32'hFFFF0000), payload_t'(32'hFFFF0000), hit);
        check("R12", hit == 1'b0);

        // ---------------------------------------------------------------
        // Final result
        // ---------------------------------------------------------------
        if (fail_count == 0) begin
            $display("RESULT: PASS");
        end else begin
            $display("RESULT: FAIL");
        end
        $finish;
    end

endmodule