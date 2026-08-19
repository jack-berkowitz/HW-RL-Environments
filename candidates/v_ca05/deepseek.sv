module tag_tracker_tb;

  // ---------------------------------------------------------------------------
  // Parameters
  // ---------------------------------------------------------------------------
  localparam int TAG_W      = 3;
  localparam int SLOTS      = 8;
  localparam int N_MATCH    = 1;
  localparam bit FULL_RATE   = 0;
  localparam bit CUT_POP_PATH = 0;
  localparam int NUM_TAGS   = 1 << TAG_W;
  localparam int MAX_WAIT   = 10000;

  typedef logic [31:0] payload_t;
  typedef logic [TAG_W-1:0] tag_t;

  // ---------------------------------------------------------------------------
  // Provided plumbing
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
  // DUT signals
  // ---------------------------------------------------------------------------
  tag_t     push_tag;
  payload_t push_data;
  logic     push_req;
  logic     push_gnt;

  payload_t [N_MATCH-1:0] match_data;
  payload_t [N_MATCH-1:0] match_mask;
  logic     [N_MATCH-1:0] match_req;
  logic     [N_MATCH-1:0] match_hit;
  logic     [N_MATCH-1:0] match_gnt;

  tag_t     pop_tag;
  logic     pop_en;
  logic     pop_req;
  payload_t pop_data;
  logic     pop_data_valid;
  logic     pop_gnt;

  logic full;
  logic empty;

  // ---------------------------------------------------------------------------
  // DUT
  // ---------------------------------------------------------------------------
  tag_tracker #(
    .TAG_W        (TAG_W),
    .SLOTS        (SLOTS),
    .FULL_RATE    (FULL_RATE),
    .CUT_POP_PATH (CUT_POP_PATH),
    .N_MATCH      (N_MATCH),
    .payload_t    (payload_t)
  ) dut (
    .clk_i           (clk),
    .rst_ni          (rst_n),
    .push_tag_i      (push_tag),
    .push_data_i     (push_data),
    .push_req_i      (push_req),
    .push_gnt_o      (push_gnt),
    .match_data_i    (match_data),
    .match_mask_i    (match_mask),
    .match_req_i     (match_req),
    .match_hit_o     (match_hit),
    .match_gnt_o     (match_gnt),
    .pop_tag_i       (pop_tag),
    .pop_en_i        (pop_en),
    .pop_req_i       (pop_req),
    .pop_data_o      (pop_data),
    .pop_data_valid_o(pop_data_valid),
    .pop_gnt_o       (pop_gnt),
    .full_o          (full),
    .empty_o         (empty)
  );

  // ---------------------------------------------------------------------------
  // Reference model
  // ---------------------------------------------------------------------------
  typedef payload_t payload_queue[$];
  payload_queue tag_q [NUM_TAGS];
  int           total_entries;

  task automatic model_clear();
    automatic int i;
    for (i = 0; i < NUM_TAGS; i++) begin
      tag_q[i].delete();
    end
    total_entries = 0;
  endtask

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------
  task automatic idle_inputs();
    push_req_i <=? 1'b0;  // intentional blocking, called at drive point
    pop_req_i  = 1'b0;
    match_req_i = '0;
    pop_en_i   = 1'b0;
    push_tag_i = '0;
    push_data_i = '0;
    pop_tag_i  = '0;
    match_data = '0;
    match_mask = '0;
  endtask

  task automatic fail_r(input string req, input string detail);
    $display("FAIL %s: %s", req, detail);
    $display("RESULT: FAIL");
    $finish;
  endtask

  task automatic check_status(input logic exp_empty, input logic exp_full,
                              input string req);
    if (empty !== exp_empty || full !== exp_full) begin
      fail_r(req, $sformatf("empty_o=%b full_o=%b expected empty=%b full=%b",
                            empty, full, exp_empty, exp_full));
    end
  endtask

  task automatic wait_for_push_gnt(input string req);
    int cycles = 0;
    while (cycles < MAX_WAIT) begin
      bfm_tick();
      if (push_req && push_gnt) return;
      cycles++;
      bfm_drive_point();
    end
    fail_r(req, "timeout waiting for push_gnt_o");
  endtask

  task automatic wait_for_pop_gnt(input string req);
    int cycles = 0;
    while (cycles < MAX_WAIT) begin
      bfm_tick();
      if (pop_req && pop_gnt) return;
      cycles++;
      bfm_drive_point();
    end
    fail_r(req, "timeout waiting for pop_gnt_o");
  endtask

  task automatic wait_for_match_gnt(input string req);
    int cycles = 0;
    while (cycles < MAX_WAIT) begin
      bfm_tick();
      if (match_req[0] && match_gnt[0]) return;
      cycles++;
      bfm_drive_point();
    end
    fail_r(req, "timeout waiting for match_gnt_o");
  endtask

  // ---------------------------------------------------------------------------
  // Operations
  // ---------------------------------------------------------------------------
  task automatic do_push(input tag_t tag, input payload_t data, input string req);
    bfm_drive_point();
    idle_inputs();
    push_tag_i  = tag;
    push_data_i = data;
    push_req_i  = 1'b1;
    wait_for_push_gnt(req);
    tag_q[tag].push_back(data);
    total_entries++;
    bfm_drive_point();
    idle_inputs();
  endtask

  task automatic do_pop(input tag_t tag, input logic en,
                        input logic exp_valid, input payload_t exp_data,
                        input string req);
    automatic payload_t d;
    bfm_drive_point();
    idle_inputs();
    pop_tag_i = tag;
    pop_en_i  = en;
    pop_req_i = 1'b1;
    wait_for_pop_gnt(req);

    if (pop_data_valid !== exp_valid) begin
      fail_r(req, $sformatf("pop_data_valid_o=%b expected %b",
                            pop_data_valid, exp_valid));
    end
    if (exp_valid) begin
      if (pop_data !== exp_data) begin
        fail_r(req, $sformatf("pop_data_o=%h expected %h", pop_data, exp_data));
      end
    end

    if (en && pop_data_valid) begin
      if (tag_q[tag].size() == 0) begin
        fail_r("R8", $sformatf("internal model empty for tag %0d but pop valid", tag));
      end
      d = tag_q[tag].pop_front();
      total_entries--;
      if (d !== exp_data) begin
        fail_r("R2", "internal model mismatch after pop");
      end
    end

    bfm_drive_point();
    idle_inputs();
  endtask

  task automatic do_search(input payload_t data, input payload_t mask,
                           input logic exp_hit, input string req);
    bfm_drive_point();
    idle_inputs();
    match_data = data;
    match_mask = mask;
    match_req[0] = 1'b1;
    wait_for_match_gnt(req);
    if (match_hit[0] !== exp_hit) begin
      fail_r(req, $sformatf("match_hit_o=%b expected %b", match_hit[0], exp_hit));
    end
    bfm_drive_point();
    idle_inputs();
  endtask

  // ---------------------------------------------------------------------------
  // Stimulus
  // ---------------------------------------------------------------------------
  localparam tag_t TAG0 = 3'd0;
  localparam tag_t TAG1 = 3'd1;
  localparam tag_t TAG2 = 3'd2;

  initial begin
    int i;

    // Initialize inputs
    push_req_i  = 1'b0;
    pop_req_i   = 1'b0;
    match_req_i = '0;
    pop_en_i    = 1'b0;
    push_tag_i  = '0;
    push_data_i = '0;
    pop_tag_i   = '0;
    match_data  = '0;
    match_mask  = '0;
    model_clear();

    // Reset and check empty/full
    bfm_reset(4);
    bfm_tick();
    check_status(1'b1, 1'b0, "R15");

    // R1/R4: fill all slots with the same tag
    for (i = 0; i < SLOTS; i++) begin
      do_push(TAG0, payload_t'(32'hA0 + i), "R1");
      bfm_tick();
      if (i == SLOTS-1)
        check_status(1'b0, 1'b1, "R14");
      else
        check_status(1'b0, 1'b0, "R14");
    end

    // R5: push_gnt_o must be low when full
    bfm_drive_point();
    idle_inputs();
    push_tag_i  = TAG0;
    push_data_i = 32'hDEADBEEF;
    push_req_i  = 1'b1;
    bfm_tick();
    if (push_gnt !== 1'b0) begin
      fail_r("R5", "push_gnt_o high when full");
    end
    if (full !== 1'b1) begin
      fail_r("R14", "full_o not high when full");
    end
    bfm_drive_point();
    idle_inputs();
    bfm_tick();

    // R2/R8: same-tag FIFO order on removal
    for (i = 0; i < SLOTS; i++) begin
      do_pop(TAG0, 1'b1, 1'b1, payload_t'(32'hA0 + i), "R2");
      bfm_tick();
      if (i == SLOTS-1)
        check_status(1'b1, 1'b0, "R14");
      else
        check_status(1'b0, 1'b0, "R14");
    end

    // R10: pop of missing tag completes with valid low
    do_pop(TAG1, 1'b1, 1'b0, '0, "R10");
    bfm_tick();
    check_status(1'b1, 1'b0, "R14");

    // R13: all-zero mask on empty store -> hit low
    do_search(32'h0, 32'h0, 1'b0, "R13");
    bfm_tick();

    // R9: inspect (pop_en=0) does not remove
    do_push(TAG1, 32'hB0, "R4");
    do_push(TAG1, 32'hB1, "R4");
    bfm_tick();
    check_status(1'b0, 1'b0, "R14");

    do_pop(TAG1, 1'b0, 1'b1, 32'hB0, "R9");
    bfm_tick();
    check_status(1'b0, 1'b0, "R9");

    do_pop(TAG1, 1'b1, 1'b1, 32'hB0, "R9");
    bfm_tick();
    check_status(1'b0, 1'b0, "R14");

    do_pop(TAG1, 1'b1, 1'b1, 32'hB1, "R9");
    bfm_tick();
    check_status(1'b1, 1'b0, "R14");

    // R11/R12/R13: search across tags
    do_push(TAG0, 32'h0000_0010, "R12");
    do_push(TAG1, 32'h0000_0020, "R12");
    do_push(TAG2, 32'h0000_0030, "R12");
    bfm_tick();
    check_status(1'b0, 1'b0, "R14");

    do_search(32'h0000_0020, 32'hFFFF_FFFF, 1'b1, "R12");
    do_search(32'h0000_0040, 32'hFFFF_FFFF, 1'b0, "R12");
    do_search(32'h0000_0000, 32'h0000_0000, 1'b1, "R13");
    do_search(32'h0000_0020, 32'hFFFF_FFF0, 1'b1, "R12");
    bfm_tick();

    // Cleanup search entries
    do_pop(TAG0, 1'b1, 1'b1, 32'h0000_0010, "R2");
    do_pop(TAG1, 1'b1, 1'b1, 32'h0000_0020, "R2");
    do_pop(TAG2, 1'b1, 1'b1, 32'h0000_0030, "R2");
    bfm_tick();
    check_status(1'b1, 1'b0, "R14");

    // R15: reset clears entries
    do_push(TAG0, 32'hAAAA_AAAA, "R15");
    do_push(TAG1, 32'hBBBB_BBBB, "R15");
    bfm_tick();
    check_status(1'b0, 1'b0, "R15");

    bfm_reset(2);
    model_clear();
    bfm_tick();
    check_status(1'b1, 1'b0, "R15");

    do_pop(TAG0, 1'b1, 1'b0, '0, "R15");
    bfm_tick();
    check_status(1'b1, 1'b0, "R15");

    $display("RESULT: PASS");
    $finish;
  end

endmodule