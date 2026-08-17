module tag_tracker_tb;

    // Parameters matching specification
    parameter int TAG_W  = 3;
    parameter int SLOTS  = 8;
    parameter bit FULL_RATE = 0;
    parameter bit CUT_POP_PATH = 0;
    parameter int N_MATCH = 1;
    typedef logic [31:0] payload_t;

    // DUT Signals
    logic clk_i;
    logic rst_ni;

    logic [TAG_W-1:0] push_tag_i;
    payload_t         push_data_i;
    logic             push_req_i;
    logic             push_gnt_o;

    payload_t [N_MATCH-1:0] match_data_i;
    payload_t [N_MATCH-1:0] match_mask_i;
    logic     [N_MATCH-1:0] match_req_i;
    logic     [N_MATCH-1:0] match_hit_o;
    logic     [N_MATCH-1:0] match_gnt_o;

    logic [TAG_W-1:0] pop_tag_i;
    logic             pop_en_i;
    logic             pop_req_i;
    payload_t         pop_data_o;
    logic             pop_data_valid_o;
    logic             pop_gnt_o;

    logic full_o;
    logic empty_o;

    // Instantiate DUT
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

    // Clock Generation
    initial begin
        clk_i = 0;
        forever #5 clk_i = ~clk_i;
    end

    // Error tracking
    int err_count = 0;
    
    task fail(string req, string msg);
        $display("FAIL %s: %s", req, msg);
        err_count++;
    endtask

    // Watchdog Timer
    initial begin
        #100000;
        $display("FAIL Watchdog: Timeout reached. A request likely stalled forever.");
        $display("RESULT: FAIL");
        $finish;
    end

    // Task: Perform Push
    task automatic do_push(input [TAG_W-1:0] tag, input payload_t data);
        @(negedge clk_i);
        push_tag_i = tag;
        push_data_i = data;
        push_req_i = 1;
        forever begin
            @(posedge clk_i);
            if (push_gnt_o === 1'b1) break;
        end
        @(negedge clk_i);
        push_req_i = 0;
    endtask

    // Task: Check Push rejection (R5)
    task automatic check_push_full();
        @(negedge clk_i);
        push_tag_i = 0;
        push_data_i = 32'hDEAD_DEAD;
        push_req_i = 1;
        for (int i = 0; i < 5; i++) begin
            @(posedge clk_i);
            if (push_gnt_o === 1'b1) begin
                fail("R5", "push_gnt_o went high when store was full");
                break;
            end
        end
        @(negedge clk_i);
        push_req_i = 0;
    endtask

    // Task: Perform Pop and optionally verify results
    task automatic check_pop(input [TAG_W-1:0] tag, input logic en, input logic exp_valid, input payload_t exp_data);
        logic valid;
        payload_t data;
        
        @(negedge clk_i);
        pop_tag_i = tag;
        pop_en_i = en;
        pop_req_i = 1;
        forever begin
            @(posedge clk_i);
            if (pop_gnt_o === 1'b1) break;
        end
        @(negedge clk_i);
        valid = pop_data_valid_o;
        data = pop_data_o;
        pop_req_i = 0;
        
        if (valid !== exp_valid) 
            fail("R8/R10", $sformatf("Tag %0d valid mismatch. Exp: %0d, Got: %0d", tag, exp_valid, valid));
            
        // R10: If valid is low, data is unconstrained and shall not be checked.
        if (exp_valid && (data !== exp_data)) 
            fail("R8", $sformatf("Tag %0d data mismatch. Exp: %h, Got: %h", tag, exp_data, data));
    endtask

    // Task: Perform Match
    task automatic do_match(input payload_t data, input payload_t mask, output logic hit);
        @(negedge clk_i);
        match_data_i[0] = data;
        match_mask_i[0] = mask;
        match_req_i[0] = 1;
        forever begin
            @(posedge clk_i);
            if (match_gnt_o[0] === 1'b1) break;
        end
        @(negedge clk_i);
        hit = match_hit_o[0];
        match_req_i[0] = 0;
    endtask

    // Main Test Sequence
    initial begin
        logic hit;
        
        // Initialize inputs
        rst_ni = 0;
        push_req_i = 0;
        pop_req_i = 0;
        match_req_i = 0;
        
        // ------------- R15: Reset Test -------------
        @(negedge clk_i);
        @(negedge clk_i);
        if (empty_o !== 1'b1) fail("R15", "empty_o not high during reset");
        if (full_o !== 1'b0) fail("R15", "full_o high during reset");
        
        rst_ni = 1;
        @(negedge clk_i);
        if (empty_o !== 1'b1) fail("R15", "empty_o not high after reset release");
        if (full_o !== 1'b0) fail("R15", "full_o high after reset release");

        // ------------- Basic Push & Inspect (R4, R7, R8, R9, R14) -------------
        do_push(3'd1, 32'hAAAA_1111); // Push completes (R4)
        @(negedge clk_i);
        if (empty_o !== 1'b0) fail("R14", "empty_o is high but store has 1 entry");
        if (full_o !== 1'b0) fail("R14", "full_o is high but store has 1 entry");
        
        // Inspect without removing (R9)
        check_pop(3'd1, 1'b0, 1'b1, 32'hAAAA_1111);
        @(negedge clk_i);
        if (empty_o !== 1'b0) fail("R9", "Entry was removed despite pop_en_i=0");
        
        // Remove (R9)
        check_pop(3'd1, 1'b1, 1'b1, 32'hAAAA_1111);
        @(negedge clk_i);
        if (empty_o !== 1'b1) fail("R9/R14", "Entry was not removed with pop_en_i=1");

        // ------------- Capacity & FIFO Order (R1, R2, R5, R14) -------------
        // Push SLOTS (8) entries across various tags
        do_push(3'd2, 32'hB000_0001); // Tag 2, oldest
        do_push(3'd2, 32'hB000_0002); // Tag 2, middle
        do_push(3'd3, 32'hC000_0001); // Tag 3, oldest
        do_push(3'd2, 32'hB000_0003); // Tag 2, newest
        do_push(3'd4, 32'hD000_0001); // Tag 4, oldest
        do_push(3'd4, 32'hD000_0002); // Tag 4
        do_push(3'd4, 32'hD000_0003); // Tag 4
        do_push(3'd4, 32'hD000_0004); // Tag 4, newest
        
        @(negedge clk_i);
        if (full_o !== 1'b1) fail("R1/R14", "full_o not 1 after 8 pushes (SLOTS=8)");
        if (empty_o !== 1'b0) fail("R14", "empty_o is 1 while store is full");
        
        // Test Push when full (R5)
        check_push_full();
        
        // Pop and verify strict per-tag FIFO (R2, R3)
        check_pop(3'd2, 1'b1, 1'b1, 32'hB000_0001); // Tag 2, oldest
        check_pop(3'd4, 1'b1, 1'b1, 32'hD000_0001); // Tag 4, oldest
        check_pop(3'd2, 1'b1, 1'b1, 32'hB000_0002); // Tag 2, middle
        check_pop(3'd3, 1'b1, 1'b1, 32'hC000_0001); // Tag 3, oldest
        check_pop(3'd2, 1'b1, 1'b1, 32'hB000_0003); // Tag 2, newest
        check_pop(3'd4, 1'b1, 1'b1, 32'hD000_0002); // Tag 4
        check_pop(3'd4, 1'b1, 1'b1, 32'hD000_0003); // Tag 4
        check_pop(3'd4, 1'b1, 1'b1, 32'hD000_0004); // Tag 4, newest
        
        @(negedge clk_i);
        if (empty_o !== 1'b1) fail("R14", "empty_o not 1 after popping all entries");

        // ------------- Empty Pop (R10) -------------
        check_pop(3'd7, 1'b1, 1'b0, 32'h0); // Valid must be 0, data unconstrained

        // ------------- Search / Match (R11, R12, R13) -------------
        do_push(3'd5, 32'hDEAD_BEEF);
        do_push(3'd6, 32'hCAFE_F00D);
        
        // Exact match
        do_match(32'hDEAD_BEEF, 32'hFFFF_FFFF, hit);
        if (hit !== 1'b1) fail("R12", "Match failed for exact payload match");
        
        // Masked match
        do_match(32'hCAFE_0000, 32'hFFFF_0000, hit);
        if (hit !== 1'b1) fail("R12", "Match failed for masked payload match");
        
        // Match miss
        do_match(32'hBEEF_0000, 32'hFFFF_0000, hit);
        if (hit !== 1'b0) fail("R12", "Match hit on missing payload");
        
        // Zero mask matches anything if not empty (R13)
        do_match(32'h0000_0000, 32'h0000_0000, hit);
        if (hit !== 1'b1) fail("R13", "Zero mask did not hit non-empty store");
        
        // Empty store and check zero mask again
        check_pop(3'd5, 1'b1, 1'b1, 32'hDEAD_BEEF);
        check_pop(3'd6, 1'b1, 1'b1, 32'hCAFE_F00D);
        
        // Zero mask on empty store must fail (R12/R13)
        do_match(32'h0000_0000, 32'h0000_0000, hit);
        if (hit !== 1'b0) fail("R12/R13", "Zero mask hit on an empty store");

        // ------------- Final Evaluation -------------
        if (err_count == 0) begin
            $display("RESULT: PASS");
        end else begin
            $display("RESULT: FAIL");
        end
        
        $finish;
    end
endmodule