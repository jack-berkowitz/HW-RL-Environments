module tag_tracker_tb;

  localparam int TAG_W = 3;
  localparam int SLOTS = 8;
  localparam int N_MATCH = 1;

  typedef logic [31:0] payload_t;
  typedef logic [TAG_W-1:0] tag_t;

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
  // Signals and DUT
  // ---------------------------------------------------------------------------
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

  logic     full_o;
  logic     empty_o;

  tag_tracker #(
    .TAG_W(TAG_W),
    .SLOTS(SLOTS),
    .FULL_RATE(0),
    .CUT_POP_PATH(0),
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

  // ---------------------------------------------------------------------------
  // Checkers and Tasks
  // ---------------------------------------------------------------------------
  task automatic fail(input string msg);
    $display("RESULT: FAIL (%s)", msg);
    $finish;
  endtask

  // Executes a push, waiting indefinitely for a grant if necessary (R4, R6)
  task automatic do_push(input tag_t tag, input payload_t data);
    bfm_drive_point();
    push_tag_i = tag;
    push_data_i = data;
    push_req_i = 1'b1;
    
    forever begin
      @(posedge clk);
      if (push_req_i && push_gnt_o) break;
    end
    
    bfm_drive_point();
    push_req_i = 1'b0;
  endtask

  // Executes a pop, retrieving the validity and payload (R7)
  task automatic do_pop(input tag_t tag, input bit en, output bit valid, output payload_t data);
    bfm_drive_point();
    pop_tag_i = tag;
    pop_en_i = en;
    pop_req_i = 1'b1;
    
    forever begin
      @(posedge clk);
      if (pop_req_i && pop_gnt_o) begin
        valid = pop_data_valid_o;
        data = pop_data_o;
        break;
      end
    end
    
    bfm_drive_point();
    pop_req_i = 1'b0;
  endtask

  // Executes a search on port 0, retrieving the hit status (R11)
  task automatic do_search(input payload_t data, input payload_t mask, output bit hit);
    bfm_drive_point();
    match_data_i[0] = data;
    match_mask_i[0] = mask;
    match_req_i[0] = 1'b1;
    
    forever begin
      @(posedge clk);
      if (match_req_i[0] && match_gnt_o[0]) begin
        hit = match_hit_o[0];
        break;
      end
    end
    
    bfm_drive_point();
    match_req_i[0] = 1'b0;
  endtask

  // Verifies empty_o and full_o match the expected entry count (R14)
  task automatic check_status(input int expected_count);
    if (expected_count == 0) begin
      if (empty_o !== 1'b1) fail("R14: empty_o not high when store is empty");
    end else begin
      if (empty_o !== 1'b0) fail("R14: empty_o high when store is not empty");
    end
    
    if (expected_count == SLOTS) begin
      if (full_o !== 1'b1) fail("R14: full_o not high when store is full");
    end else begin
      if (full_o !== 1'b0) fail("R14: full_o high when store is not full");
    end
  endtask

  // ---------------------------------------------------------------------------
  // Main Sequence
  // ---------------------------------------------------------------------------
  initial begin
    automatic bit valid;
    automatic payload_t data;
    automatic bit hit;
    automatic int i;

    push_tag_i = 0;
    push_data_i = 0;
    push_req_i = 0;
    
    match_data_i[0] = 0;
    match_mask_i[0] = 0;
    match_req_i[0] = 0;
    
    pop_tag_i = 0;
    pop_en_i = 0;
    pop_req_i = 0;
    
    bfm_reset();
    
    // Check reset state (R15)
    bfm_drive_point();
    if (empty_o !== 1'b1) fail("R15: empty_o not high after reset");
    if (full_o !== 1'b0) fail("R15: full_o not low after reset");
    
    // Scenario 1: Fill with same tag
    // R1: accepts SLOTS entries, including same tag
    for (i = 0; i < 8; i++) begin
      do_push(3'd2, i * 100);
      check_status(i + 1);
    end
    
    // Check R5: push_gnt_o shall be low when full.
    bfm_drive_point();
    push_tag_i = 3'd2;
    push_req_i = 1'b1;
    repeat (10) begin
      @(posedge clk);
      if (push_gnt_o !== 1'b0) fail("R5: push_gnt_o not low when full");
    end
    bfm_drive_point();
    push_req_i = 1'b0;

    // Verify it's globally full, not just tag 2 full.
    bfm_drive_point();
    push_tag_i = 3'd1;
    push_req_i = 1'b1;
    repeat (10) begin
      @(posedge clk);
      if (push_gnt_o !== 1'b0) fail("R5: push_gnt_o not low when full (cross-tag)");
    end
    bfm_drive_point();
    push_req_i = 1'b0;
    
    // Test popping an empty tag when store is full (R10)
    do_pop(3'd1, 1'b1, valid, data);
    if (valid !== 1'b0) fail("R10: pop_data_valid_o high when empty tag popped");
    
    // Scenario 2: pop without en (inspect)
    // R9: pop_en_i low -> inspected, not removed
    do_pop(3'd2, 1'b0, valid, data);
    if (valid !== 1'b1) fail("R8: pop_data_valid_o low but entry exists");
    if (data !== 0) fail("R8: pop_data_o not oldest entry");
    check_status(8);
    
    // Scenario 3: Pop all 8, verify FIFO order (R2)
    for (i = 0; i < 8; i++) begin
      do_pop(3'd2, 1'b1, valid, data);
      if (valid !== 1'b1) fail("R8: pop_data_valid_o low but entry exists");
      if (data !== i * 100) fail("R2: popped data not in FIFO order");
      check_status(7 - i);
    end
    
    // Empty pop check (R10)
    do_pop(3'd2, 1'b1, valid, data);
    if (valid !== 1'b0) fail("R10: pop_data_valid_o high when no entry exists");
    
    // Scenario 4: Different tags, search requirements
    do_push(3'd1, 32'hAAAA);
    do_push(3'd2, 32'hBBBB);
    do_push(3'd1, 32'hCCCC);
    do_push(3'd3, 32'hDDDD);
    check_status(4);
    
    // Search matching all zeros mask (R13)
    do_search(32'h0, 32'h0, hit);
    if (hit !== 1'b1) fail("R13: match_hit_o low for all-zero mask when non-empty");
    
    // Search matching specific data (R12)
    do_search(32'hBBBB, 32'hFFFFFFFF, hit);
    if (hit !== 1'b1) fail("R12: match_hit_o low when matching entry exists");
    
    do_search(32'h0000BB00, 32'h0000FF00, hit);
    if (hit !== 1'b1) fail("R12: match_hit_o low for partial mask match");
    
    do_search(32'h0000EE00, 32'h0000FF00, hit);
    if (hit !== 1'b0) fail("R12: match_hit_o high when no matching entry exists");
    
    // Pop tag 1
    do_pop(3'd1, 1'b1, valid, data);
    if (valid !== 1'b1 || data !== 32'hAAAA) fail("R2: FIFO order failed for tag 1");
    do_pop(3'd1, 1'b1, valid, data);
    if (valid !== 1'b1 || data !== 32'hCCCC) fail("R2: FIFO order failed for tag 1");
    
    check_status(2);
    
    // Fill it up again with diverse tags
    do_push(3'd4, 32'h1111);
    do_push(3'd5, 32'h2222);
    do_push(3'd6, 32'h3333);
    do_push(3'd7, 32'h4444);
    do_push(3'd0, 32'h5555);
    do_push(3'd1, 32'h6666);
    check_status(8);
    
    // Reset and check it empties properly (R15)
    bfm_reset();
    bfm_drive_point();
    if (empty_o !== 1'b1) fail("R15: empty_o not high after second reset");
    if (full_o !== 1'b0) fail("R15: full_o not low after second reset");
    
    // Search on empty store ensures hit stays low (R12 / R13)
    do_search(32'h0, 32'h0, hit);
    if (hit !== 1'b0) fail("R12: match_hit_o high when store is empty");

    // Pop on reset-cleared store
    do_pop(3'd1, 1'b1, valid, data);
    if (valid !== 1'b0) fail("R15: store not empty after reset (pop succeeded)");

    $display("RESULT: PASS");
    $finish;
  end

endmodule