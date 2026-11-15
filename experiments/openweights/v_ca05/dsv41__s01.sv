module tag_tracker_tb;

  // Parameters
  localparam int TAG_W = 3;
  localparam int SLOTS = 8;
  localparam int N_MATCH = 1;
  localparam int TIMEOUT = 1000;

  typedef logic [TAG_W-1:0] tag_t;
  typedef logic [31:0] payload_t;

  // DUT signals
  logic clk;
  logic rst_n;
  tag_t push_tag_i;
  payload_t push_data_i;
  logic push_req_i;
  logic push_gnt_o;
  payload_t [N_MATCH-1:0] match_data_i;
  payload_t [N_MATCH-1:0] match_mask_i;
  logic [N_MATCH-1:0] match_req_i;
  logic [N_MATCH-1:0] match_hit_o;
  logic [N_MATCH-1:0] match_gnt_o;
  tag_t pop_tag_i;
  logic pop_en_i;
  logic pop_req_i;
  payload_t pop_data_o;
  logic pop_data_valid_o;
  logic pop_gnt_o;
  logic full_o;
  logic empty_o;

  // Model
  payload_t tag_q[8][$];
  int total_count = 0;
  int errors = 0;

  // Instantiate DUT
  tag_tracker #(
    .TAG_W(TAG_W),
    .SLOTS(SLOTS),
    .FULL_RATE(1'b0),
    .CUT_POP_PATH(1'b0),
    .N_MATCH(N_MATCH),
    .payload_t(payload_t)
  ) u_dut (
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
  // Model reset and failure reporting
  // ---------------------------------------------------------------------------
  task automatic model_reset();
    int i;
    for (i = 0; i < 8; i++) begin
      tag_q[i].delete();
    end
    total_count = 0;
  endtask

  task automatic report_fail(input string req, input string msg);
    errors++;
    $display("FAIL: %s - %s", req, msg);
  endtask

  // ---------------------------------------------------------------------------
  // Checker and model update
  // ---------------------------------------------------------------------------
  always @(posedge clk) begin
    int i;
    int j;
    logic expected_hit;
    int push_idx;
    int pop_idx;

    if (!rst_n) begin
      model_reset();
    end else begin
      // R14 status
      if (empty_o !== (total_count == 0)) begin
        report_fail("R14", "empty_o mismatch");
      end
      if (full_o !== (total_count == SLOTS)) begin
        report_fail("R14", "full_o mismatch");
      end

      // Push commit and R5
      if (push_req_i && push_gnt_o) begin
        if (total_count == SLOTS) begin
          report_fail("R5", "push_gnt_o high when full");
        end
        push_idx = push_tag_i;
        tag_q[push_idx].push_back(push_data_i);
        total_count++;
      end

      // Pop commit and R8/R9/R10
      if (pop_req_i && pop_gnt_o) begin
        pop_idx = pop_tag_i;
        if (tag_q[pop_idx].size() > 0) begin
          if (pop_data_valid_o !== 1'b1) begin
            report_fail("R8", "pop_data_valid_o low when entry present");
          end else if (pop_data_o !== tag_q[pop_idx][0]) begin
            report_fail("R8", "pop_data_o does not match oldest entry");
          end
          if (pop_en_i) begin
            tag_q[pop_idx].pop_front();
            total_count--;
          end
        end else begin
          if (pop_data_valid_o !== 1'b0) begin
            report_fail("R8", "pop_data_valid_o high when no entry");
          end
        end
      end

      // Match commit and R12/R13
      if (match_req_i[0] && match_gnt_o[0]) begin
        expected_hit = 1'b0;
        for (i = 0; i < 8; i++) begin
          for (j = 0; j < tag_q[i].size(); j++) begin
            if ((tag_q[i][j] & match_mask_i[0]) == (match_data_i[0] & match_mask_i[0])) begin
              expected_hit = 1'b1;
            end
          end
        end
        if (match_hit_o[0] !== expected_hit) begin
          report_fail("R12", "match_hit_o mismatch");
        end
      end
    end
  end

  // ---------------------------------------------------------------------------
  // Request drivers
  // ---------------------------------------------------------------------------
  task automatic do_push(input tag_t tag, input payload_t data);
    int i;
    bfm_drive_point();
    push_tag_i = tag;
    push_data_i = data;
    push_req_i = 1'b1;
    for (i = 0; i < TIMEOUT; i++) begin
      @(posedge clk);
      if (rst_n && push_req_i && push_gnt_o) begin
        @(negedge clk);
        push_req_i = 1'b0;
        return;
      end
    end
    if (total_count < SLOTS) begin
      report_fail("R1", "push timeout when space exists");
    end else begin
      report_fail("R4", "push timeout");
    end
    @(negedge clk);
    push_req_i = 1'b0;
  endtask

  task automatic do_pop(input tag_t tag, input logic en);
    int i;
    bfm_drive_point();
    pop_tag_i = tag;
    pop_en_i = en;
    pop_req_i = 1'b1;
    for (i = 0; i < TIMEOUT; i++) begin
      @(posedge clk);
      if (rst_n && pop_req_i && pop_gnt_o) begin
        @(negedge clk);
        pop_req_i = 1'b0;
        pop_en_i = 1'b0;
        return;
      end
    end
    report_fail("R7", "pop timeout");
    @(negedge clk);
    pop_req_i = 1'b0;
    pop_en_i = 1'b0;
  endtask

  task automatic do_match(input payload_t data, input payload_t mask);
    int i;
    bfm_drive_point();
    match_data_i[0] = data;
    match_mask_i[0] = mask;
    match_req_i[0] = 1'b1;
    for (i = 0; i < TIMEOUT; i++) begin
      @(posedge clk);
      if (rst_n && match_req_i[0] && match_gnt_o[0]) begin
        @(negedge clk);
        match_req_i[0] = 1'b0;
        return;
      end
    end
    report_fail("R11", "match timeout");
    @(negedge clk);
    match_req_i[0] = 1'b0;
  endtask

  // ---------------------------------------------------------------------------
  // Test sequence
  // ---------------------------------------------------------------------------
  initial begin
    int k;

    // Initialize inputs
    push_tag_i = 0;
    push_data_i = 0;
    push_req_i = 0;
    match_data_i = '0;
    match_mask_i = '0;
    match_req_i = '0;
    pop_tag_i = 0;
    pop_en_i = 0;
    pop_req_i = 0;

    // Reset
    bfm_reset();
    @(posedge clk);
    if (empty_o !== 1'b1) report_fail("R15", "empty_o not high after reset");
    if (full_o !== 1'b0) report_fail("R15", "full_o not low after reset");

    // Phase 1: all same tag, fill to capacity
    for (k = 0; k < SLOTS; k++) begin
      do_push(3'd0, k);
    end
    @(posedge clk);
    if (full_o !== 1'b1) report_fail("R14", "full_o not high after filling");
    if (empty_o !== 1'b0) report_fail("R14", "empty_o high when full");

    // Push when full: should not grant
    bfm_drive_point();
    push_tag_i = 3'd0;
    push_data_i = 32'hDEADBEEF;
    push_req_i = 1'b1;
    repeat (5) begin
      @(posedge clk);
      if (push_gnt_o !== 1'b0) report_fail("R5", "push_gnt_o high when full");
    end
    @(negedge clk);
    push_req_i = 1'b0;

    // Peek oldest tag 0 (should be 0)
    do_pop(3'd0, 1'b0);
    // Pop oldest tag 0 (remove 0)
    do_pop(3'd0, 1'b1);
    // Pop remaining 1..7
    for (k = 1; k < SLOTS; k++) begin
      do_pop(3'd0, 1'b1);
    end
    @(posedge clk);
    if (empty_o !== 1'b1) report_fail("R14", "empty_o not high after popping all");
    if (full_o !== 1'b0) report_fail("R14", "full_o high when empty");

    // Pop absent tag
    do_pop(3'd1, 1'b1);
    // Search when empty with all-zero mask
    do_match(32'h0, 32'h0);

    // Phase 2: reset and push mixed tags
    bfm_reset();
    @(posedge clk);
    if (empty_o !== 1'b1) report_fail("R15", "empty_o not high after second reset");
    if (full_o !== 1'b0) report_fail("R15", "full_o not low after second reset");

    // Push 8 entries with mixed tags
    do_push(3'd0, 32'h000000A0);
    do_push(3'd1, 32'h000000B1);
    do_push(3'd0, 32'h000000A2);
    do_push(3'd2, 32'h000000C3);
    do_push(3'd1, 32'h000000B4);
    do_push(3'd0, 32'h000000A5);
    do_push(3'd3, 32'h000000D6);
    do_push(3'd2, 32'h000000C7);

    @(posedge clk);
    if (full_o !== 1'b1) report_fail("R14", "full_o not high after mixed fill");
    if (empty_o !== 1'b0) report_fail("R14", "empty_o high after mixed fill");

    // Search tests
    do_match(32'h0, 32'h0); // all-zero mask, non-empty -> hit high
    do_match(32'h000000A2, 32'hFFFFFFFF); // exact match A2 -> high
    do_match(32'hDEADBEEF, 32'hFFFFFFFF); // no match -> low
    do_match(32'h000000A0, 32'h000000FF); // mask low byte, A0 -> high
    do_match(32'h000000A1, 32'h000000FF); // mask low byte, A1 -> low
    do_match(32'h0000000A, 32'h0000000F); // low nibble A -> low
    do_match(32'h00000002, 32'h0000000F); // low nibble 2 -> high (A2)

    // Pop by tag order tests
    // Tag 1: B1 then B4 then empty
    do_pop(3'd1, 1'b1);
    do_pop(3'd1, 1'b1);
    do_pop(3'd1, 1'b1); // absent
    // Tag 0: peek A0, then remove A0, A2, A5, then empty
    do_pop(3'd0, 1'b0); // peek A0
    do_pop(3'd0, 1'b1); // remove A0
    do_pop(3'd0, 1'b1); // remove A2
    do_pop(3'd0, 1'b1); // remove A5
    do_pop(3'd0, 1'b1); // absent
    // Tag 2: C3 then C7 then empty
    do_pop(3'd2, 1'b1);
    do_pop(3'd2, 1'b1);
    do_pop(3'd2, 1'b1); // absent
    // Tag 3: D6 then empty
    do_pop(3'd3, 1'b1);
    do_pop(3'd3, 1'b1); // absent

    @(posedge clk);
    if (empty_o !== 1'b1) report_fail("R14", "empty_o not high after mixed pops");
    if (full_o !== 1'b0) report_fail("R14", "full_o high after mixed pops");

    // Final result
    if (errors == 0) begin
      $display("RESULT: PASS");
    end else begin
      $display("RESULT: FAIL");
    end
    $finish;
  end

endmodule
