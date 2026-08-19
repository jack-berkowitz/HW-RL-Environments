module tag_tracker_tb;

  parameter int TAG_W = 3;
  parameter int SLOTS = 8;
  parameter bit FULL_RATE = 0;
  parameter bit CUT_POP_PATH = 0;
  parameter int N_MATCH = 1;
  typedef logic[31:0] payload_t;
  typedef logic[TAG_W-1:0] tag_t;

  logic clk;
  logic rst_ni; // Mapped to the provided rst_n

  tag_t     push_tag_i;
  payload_t push_data_i;
  logic     push_req_i;
  logic     push_gnt_o;

  // Packed dimensions must be declared exactly matching the port specification
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
    .FULL_RATE(FULL_RATE),
    .CUT_POP_PATH(CUT_POP_PATH),
    .N_MATCH(N_MATCH),
    .payload_t(payload_t)
  ) dut (
    .clk_i(clk),
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

  // ---------------------------------------------------------------------------
  // PROVIDED PLUMBING -- clock, reset and watchdog only.
  // ---------------------------------------------------------------------------
  // ---- clock -----------------------------------------------------------------
  initial begin clk = 1'b0; forever #5 clk = ~clk; end

  // ---- reset (active low) ----------------------------------------------------
  logic rst_n;
  initial rst_n = 1'b0;
  assign rst_ni = rst_n;

  task automatic bfm_reset(input int cycles = 4);
    @(negedge clk);
    rst_n = 1'b0;
    repeat (cycles) @(posedge clk);
    @(negedge clk);
    rst_n = 1'b1;
  endtask

  // ---- timing discipline -----------------------------------------------------
  task automatic bfm_drive_point();
    @(negedge clk);
  endtask

  task automatic bfm_tick();
    @(posedge clk);
  endtask

  // ---- watchdog --------------------------------------------------------------
  initial begin
    #20_000_000;
    $display("RESULT: FAIL (watchdog: no forward progress)");
    $finish;
  end
  // ---------------------------------------------------------------------------

  // Handshake synchronization flags for drivers
  logic push_done = 0;
  logic pop_done = 0;
  logic match_done = 0;

  always @(posedge clk) begin
    if (!rst_ni) begin
      push_done <= 0;
      pop_done <= 0;
      match_done <= 0;
    end else begin
      push_done  <= (push_req_i && push_gnt_o);
      pop_done   <= (pop_req_i && pop_gnt_o);
      match_done <= (match_req_i[0] && match_gnt_o[0]);
    end
  end

  // ---- Transaction Tasks ----------------------------------------------------
  task automatic do_push(input tag_t tag, input payload_t data);
    bfm_drive_point();
    push_req_i = 1'b1;
    push_tag_i = tag;
    push_data_i = data;
    forever begin
      bfm_tick();
      bfm_drive_point();
      if (push_done) begin
        push_req_i = 1'b0;
        break;
      end
    end
  endtask

  task automatic do_pop(input tag_t tag, input logic en);
    bfm_drive_point();
    pop_req_i = 1'b1;
    pop_tag_i = tag;
    pop_en_i = en;
    forever begin
      bfm_tick();
      bfm_drive_point();
      if (pop_done) begin
        pop_req_i = 1'b0;
        break;
      end
    end
  endtask

  task automatic do_search(input payload_t mask, input payload_t data);
    bfm_drive_point();
    match_req_i[0] = 1'b1;
    match_mask_i[0] = mask;
    match_data_i[0] = data;
    forever begin
      bfm_tick();
      bfm_drive_point();
      if (match_done) begin
        match_req_i[0] = 1'b0;
        break;
      end
    end
  endtask

  // ---- Scoreboard & Monitor -------------------------------------------------
  localparam int NUM_TAGS = 1 << TAG_W;
  payload_t store [NUM_TAGS] [$];
  int total_entries = 0;
  bit fail_flag = 0;

  always @(posedge clk) begin
    automatic int tag_count;
    automatic logic exp_hit;
    automatic int i;
    
    if (!rst_ni) begin
      for (i = 0; i < NUM_TAGS; i++) store[i].delete();
      total_entries = 0;
      fail_flag = 0;
    end else begin
      // (R14) Status flag integrity
      if (empty_o !== (total_entries == 0)) begin
        $display("RESULT: FAIL (R14: empty_o is %b, expected %b)", empty_o, (total_entries == 0));
        fail_flag = 1;
      end
      if (full_o !== (total_entries == SLOTS)) begin
        $display("RESULT: FAIL (R14: full_o is %b, expected %b)", full_o, (total_entries == SLOTS));
        fail_flag = 1;
      end

      // (R5) Cannot grant pushes when full
      if ((total_entries == SLOTS) && push_gnt_o) begin
        $display("RESULT: FAIL (R5: push_gnt_o asserted when store is full)");
        fail_flag = 1;
      end

      // (R7, R8, R9, R10) Pop logic
      if (pop_req_i && pop_gnt_o) begin
        tag_count = store[pop_tag_i].size();
        if (tag_count > 0) begin
          if (pop_data_valid_o !== 1'b1) begin
            $display("RESULT: FAIL (R8: pop_data_valid_o low for non-empty tag %0d)", pop_tag_i);
            fail_flag = 1;
          end else if (pop_data_o !== store[pop_tag_i][0]) begin
            $display("RESULT: FAIL (R8: pop_data_o ordering mismatch. expected %x, got %x)", store[pop_tag_i][0], pop_data_o);
            fail_flag = 1;
          end
          // Only pop/remove if pop_en_i is high
          if (pop_en_i && pop_data_valid_o) begin
            automatic payload_t p = store[pop_tag_i].pop_front();
            total_entries--;
          end
        end else begin
          if (pop_data_valid_o !== 1'b0) begin
            $display("RESULT: FAIL (R10: pop_data_valid_o high for empty tag %0d)", pop_tag_i);
            fail_flag = 1;
          end
        end
      end

      // (R4) Push commit
      if (push_req_i && push_gnt_o) begin
        store[push_tag_i].push_back(push_data_i);
        total_entries++;
      end

      // (R11, R12, R13) Match logic
      if (match_req_i[0] && match_gnt_o[0]) begin
        exp_hit = 0;
        foreach (store[t]) begin
          foreach (store[t][idx]) begin
            if ((store[t][idx] & match_mask_i[0]) == (match_data_i[0] & match_mask_i[0])) begin
              exp_hit = 1;
            end
          end
        end
        if (match_hit_o[0] !== exp_hit) begin
          $display("RESULT: FAIL (R12: match_hit_o logic mismatch. expected %b, got %b)", exp_hit, match_hit_o[0]);
          fail_flag = 1;
        end
        if (match_mask_i[0] == 0 && total_entries > 0 && match_hit_o[0] !== 1'b1) begin
          $display("RESULT: FAIL (R13: match_hit_o not high for all-zeros mask on non-empty store)");
          fail_flag = 1;
        end
      end

      if (fail_flag) $finish;
    end
  end

  // ---- Main Stimulus Sequence -----------------------------------------------
  initial begin
    push_req_i = 0; pop_req_i = 0; match_req_i[0] = 0;
    push_tag_i = 0; push_data_i = 0; pop_tag_i = 0; pop_en_i = 0;
    match_data_i[0] = 0; match_mask_i[0] = 0;

    bfm_reset(4);

    // Verify initial state
    bfm_drive_point();
    if (empty_o !== 1'b1 || full_o !== 1'b0) begin
      $display("RESULT: FAIL (R15: invalid reset state)");
      $finish;
    end

    // Fill store to capacity, iterating through tags
    for (int i = 0; i < SLOTS; i++) begin
      do_push(i % 3, i * 10);
    end

    // Test R5 logic: Request push when store is verifiably full (monitor will catch an illegal grant)
    bfm_drive_point();
    push_req_i  = 1'b1;
    push_tag_i  = 1;
    push_data_i = 32'hDEADBEEF;
    repeat (5) bfm_tick();
    bfm_drive_point();
    push_req_i  = 1'b0;

    // Execute match queries (monitor tracks accuracy directly)
    do_search(32'hFFFFFFFF, 32'd30);  // Exact positive match on stored item
    do_search(32'h00000000, 32'd999); // R13 all-zero mask sweep
    do_search(32'hFFFFFFFF, 32'd999); // Negative match

    // Execute pop permutations
    do_pop(0, 0); // Inspect without dropping
    do_pop(0, 1); // Extract safely
    for (int i = 1; i < SLOTS; i++) begin
      do_pop(i % 3, 1);
    end

    // R10 logic checks (Pop from empty tag bounds)
    do_pop(0, 1);
    do_pop(1, 1);

    // R1 constraints (Fill identically bound subset and drain safely)
    for (int i = 0; i < SLOTS; i++) begin
      do_push(7, i * 111);
    end
    for (int i = 0; i < SLOTS; i++) begin
      do_pop(7, 1);
    end

    $display("RESULT: PASS");
    $finish;
  end

endmodule