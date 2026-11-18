module tag_tracker_tb;

  // -------------------------------------------------------------------------
  // Testbench parameters and types
  // -------------------------------------------------------------------------
  localparam int TAG_W   = 3;
  localparam int SLOTS   = 8;
  localparam int N_MATCH = 1;
  localparam int MAX_WAIT = 10000;

  typedef logic [31:0] payload_tb_t;

  // -------------------------------------------------------------------------
  // DUT signals
  // -------------------------------------------------------------------------
  logic clk;
  logic rst_n;

  logic [TAG_W-1:0] push_tag;
  payload_tb_t      push_data;
  logic             push_req;
  logic             push_gnt;

  payload_tb_t [N_MATCH-1:0] match_data;
  payload_tb_t [N_MATCH-1:0] match_mask;
  logic        [N_MATCH-1:0] match_req;
  logic        [N_MATCH-1:0] match_hit;
  logic        [N_MATCH-1:0] match_gnt;

  logic [TAG_W-1:0] pop_tag;
  logic             pop_en;
  logic             pop_req;
  payload_tb_t      pop_data;
  logic             pop_data_valid;
  logic             pop_gnt;

  logic             full_sig;
  logic             empty_sig;

  // -------------------------------------------------------------------------
  // Reference model: one FIFO queue per tag
  // -------------------------------------------------------------------------
  payload_tb_t tag_q [0:7][$];
  int          total_count;

  // -------------------------------------------------------------------------
  // PROVIDED PLUMBING -- clock, reset and watchdog only.
  // -------------------------------------------------------------------------
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

  // -------------------------------------------------------------------------
  // DUT instantiation
  // -------------------------------------------------------------------------
  tag_tracker #(
    .TAG_W        (TAG_W),
    .SLOTS        (SLOTS),
    .FULL_RATE    (1'b0),
    .CUT_POP_PATH (1'b0),
    .N_MATCH      (N_MATCH),
    .payload_t    (payload_tb_t)
  ) dut (
    .clk_i            (clk),
    .rst_ni           (rst_n),

    .push_tag_i       (push_tag),
    .push_data_i      (push_data),
    .push_req_i       (push_req),
    .push_gnt_o       (push_gnt),

    .match_data_i     (match_data),
    .match_mask_i     (match_mask),
    .match_req_i      (match_req),
    .match_hit_o      (match_hit),
    .match_gnt_o      (match_gnt),

    .pop_tag_i        (pop_tag),
    .pop_en_i         (pop_en),
    .pop_req_i        (pop_req),
    .pop_data_o       (pop_data),
    .pop_data_valid_o (pop_data_valid),
    .pop_gnt_o        (pop_gnt),

    .full_o           (full_sig),
    .empty_o          (empty_sig)
  );

  // -------------------------------------------------------------------------
  // Failure helper
  // -------------------------------------------------------------------------
  task automatic fail(input string req, input string msg);
    $display("FAIL %s: %s", req, msg);
    $display("RESULT: FAIL");
    $finish;
  endtask

  // -------------------------------------------------------------------------
  // Model reset
  // -------------------------------------------------------------------------
  task automatic reset_model();
    int i;
    for (i = 0; i < 8; i++) begin
      tag_q[i].delete();
    end
    total_count = 0;
  endtask

  // -------------------------------------------------------------------------
  // Status check (R14)
  // -------------------------------------------------------------------------
  task automatic check_status(input string where);
    logic exp_empty;
    logic exp_full;

    exp_empty = (total_count == 0);
    exp_full  = (total_count == SLOTS);

    if (empty_sig !== exp_empty) begin
      fail("R14", $sformatf("empty_o mismatch at %s: got %0b exp %0b (count=%0d)",
                            where, empty_sig, exp_empty, total_count));
    end
    if (full_sig !== exp_full) begin
      fail("R14", $sformatf("full_o mismatch at %s: got %0b exp %0b (count=%0d)",
                            where, full_sig, exp_full, total_count));
    end
  endtask

  // -------------------------------------------------------------------------
  // Push one entry, wait for grant, update model (R1, R4, R5, R6)
  // -------------------------------------------------------------------------
  task automatic push_entry(input logic [TAG_W-1:0] tag,
                            input payload_tb_t data,
                            input string where);
    int cyc;

    bfm_drive_point();
    push_req  = 1'b1;
    push_tag  = tag;
    push_data = data;

    for (cyc = 0; cyc < MAX_WAIT; cyc++) begin
      bfm_tick();
      if (push_gnt) begin
        if (total_count >= SLOTS) begin
          fail("R5", $sformatf("push granted when full at %s", where));
        end
        tag_q[tag].push_back(data);
        total_count++;

        bfm_drive_point();
        push_req = 1'b0;
        check_status(where);
        return;
      end
    end

    fail("R1", $sformatf("push not granted within %0d cycles at %s", MAX_WAIT, where));
  endtask

  // -------------------------------------------------------------------------
  // Pop/peek one entry, wait for grant, check and update model (R7-R10)
  // -------------------------------------------------------------------------
  task automatic pop_entry(input logic [TAG_W-1:0] tag,
                           input logic do_remove,
                           input string where);
    int cyc;
    logic exp_valid;
    payload_tb_t exp_data;

    bfm_drive_point();
    pop_req = 1'b1;
    pop_tag = tag;
    pop_en  = do_remove;

    for (cyc = 0; cyc < MAX_WAIT; cyc++) begin
      bfm_tick();
      if (pop_gnt) begin
        exp_valid = (tag_q[tag].size() > 0);
        if (exp_valid) begin
          exp_data = tag_q[tag][0];
        end

        if (pop_data_valid !== exp_valid) begin
          fail("R8", $sformatf("pop_data_valid mismatch at %s tag=%0d: got %0b exp %0b",
                               where, tag, pop_data_valid, exp_valid));
        end

        if (exp_valid) begin
          if (pop_data !== exp_data) begin
            fail("R8", $sformatf("pop_data mismatch at %s tag=%0d: got %08h exp %08h",
                                 where, tag, pop_data, exp_data));
          end
        end

        if (do_remove && exp_valid) begin
          tag_q[tag].pop_front();
          total_count--;
        end

        bfm_drive_point();
        pop_req = 1'b0;
        pop_en  = 1'b0;
        check_status(where);
        return;
      end
    end

    if (tag_q[tag].size() == 0) begin
      fail("R10", $sformatf("pop of empty tag not granted within %0d cycles at %s",
                            MAX_WAIT, where));
    end else begin
      fail("R7", $sformatf("pop not granted within %0d cycles at %s", MAX_WAIT, where));
    end
  endtask

  // -------------------------------------------------------------------------
  // Search one match port, wait for grant, check hit (R11-R13)
  // -------------------------------------------------------------------------
  task automatic do_match(input payload_tb_t data,
                          input payload_tb_t mask,
                          input string where);
    int cyc;
    int t;
    int i;
    logic exp_hit;

    bfm_drive_point();
    match_req[0]  = 1'b1;
    match_data[0] = data;
    match_mask[0] = mask;

    for (cyc = 0; cyc < MAX_WAIT; cyc++) begin
      bfm_tick();
      if (match_gnt[0]) begin
        exp_hit = 1'b0;
        for (t = 0; t < 8; t++) begin
          for (i = 0; i < tag_q[t].size(); i++) begin
            if ((tag_q[t][i] & mask) == (data & mask)) begin
              exp_hit = 1'b1;
            end
          end
        end

        if (match_hit[0] !== exp_hit) begin
          fail("R12", $sformatf("match_hit mismatch at %s data=%08h mask=%08h: got %0b exp %0b",
                                where, data, mask, match_hit[0], exp_hit));
        end

        bfm_drive_point();
        match_req[0] = 1'b0;
        return;
      end
    end

    fail("R11", $sformatf("match not granted within %0d cycles at %s", MAX_WAIT, where));
  endtask

  // -------------------------------------------------------------------------
  // Push-when-full test (R5)
  // -------------------------------------------------------------------------
  task automatic test_push_full(input string where);
    int cyc;

    bfm_drive_point();
    push_req  = 1'b1;
    push_tag  = 3'd0;
    push_data = 32'hDEADBEEF;

    for (cyc = 0; cyc < 5; cyc++) begin
      bfm_tick();
      if (push_gnt) begin
        fail("R5", $sformatf("push_gnt high when full at %s", where));
      end
      bfm_drive_point();
      check_status(where);
    end

    push_req = 1'b0;
    bfm_drive_point();
  endtask

  // -------------------------------------------------------------------------
  // Main test sequence
  // -------------------------------------------------------------------------
  initial begin
    // Initialise inputs
    push_tag  = '0;
    push_data = '0;
    push_req  = 1'b0;

    match_data = '0;
    match_mask = '0;
    match_req  = '0;

    pop_tag = '0;
    pop_en  = 1'b0;
    pop_req = 1'b0;

    total_count = 0;
    reset_model();

    // ---------------------------------------------------------------------
    // R15: reset
    // ---------------------------------------------------------------------
    bfm_reset();
    bfm_tick();
    bfm_drive_point();
    check_status("after reset");
    if (empty_sig !== 1'b1) fail("R15", "empty_o not high after reset");
    if (full_sig  !== 1'b0) fail("R15", "full_o not low after reset");

    // ---------------------------------------------------------------------
    // R1: fill exactly SLOTS entries with a mix of tags
    // ---------------------------------------------------------------------
    push_entry(3'd0, 32'h0000_0010, "push1");
    push_entry(3'd1, 32'h0000_0020, "push2");
    push_entry(3'd0, 32'h0000_0030, "push3");
    push_entry(3'd2, 32'h0000_0040, "push4");
    push_entry(3'd0, 32'h0000_0050, "push5");
    push_entry(3'd1, 32'h0000_0060, "push6");
    push_entry(3'd3, 32'h0000_0070, "push7");
    push_entry(3'd0, 32'h0000_0080, "push8");

    check_status("after fill");
    if (full_sig  !== 1'b1) fail("R14", "full_o not high after filling SLOTS");
    if (empty_sig !== 1'b0) fail("R14", "empty_o high when full");

    // ---------------------------------------------------------------------
    // R5: push must not be granted when full
    // ---------------------------------------------------------------------
    test_push_full("full push test");

    // ---------------------------------------------------------------------
    // R11-R13: search tests while full
    // ---------------------------------------------------------------------
    do_match(32'h0000_0000, 32'h0000_0000, "match all-zero mask");
    do_match(32'h0000_0030, 32'hFFFF_FFFF, "match exact 0x30");
    do_match(32'h0000_0090, 32'hFFFF_FFFF, "match exact 0x90 absent");
    do_match(32'h0000_0020, 32'h0000_00F0, "match masked 0x20");
    do_match(32'h0000_000A, 32'h0000_000F, "match masked 0x0A absent");
    do_match(32'h0000_0080, 32'h0000_00FF, "match masked 0x80");
    do_match(32'h0000_0081, 32'h0000_00FF, "match masked 0x81 absent");

    // ---------------------------------------------------------------------
    // R2/R8/R9/R10: pop/peek tests
    // ---------------------------------------------------------------------
    pop_entry(3'd0, 1'b0, "peek tag0 first");   // expect 0x10, no remove
    pop_entry(3'd0, 1'b1, "pop tag0 first");    // expect 0x10, remove
    pop_entry(3'd0, 1'b1, "pop tag0 second");   // expect 0x30
    pop_entry(3'd0, 1'b0, "peek tag0 third");   // expect 0x50, no remove
    pop_entry(3'd1, 1'b1, "pop tag1 first");    // expect 0x20
    pop_entry(3'd2, 1'b1, "pop tag2 first");    // expect 0x40
    pop_entry(3'd2, 1'b1, "pop tag2 absent");   // expect valid 0
    pop_entry(3'd3, 1'b1, "pop tag3 first");    // expect 0x70
    pop_entry(3'd1, 1'b1, "pop tag1 second");   // expect 0x60
    pop_entry(3'd0, 1'b1, "pop tag0 third");    // expect 0x50
    pop_entry(3'd0, 1'b1, "pop tag0 fourth");   // expect 0x80

    check_status("after empty");
    if (empty_sig !== 1'b1) fail("R14", "empty_o not high after emptying");
    if (full_sig  !== 1'b0) fail("R14", "full_o high when empty");

    // Pop/peek when empty
    pop_entry(3'd0, 1'b1, "pop empty tag0");
    pop_entry(3'd5, 1'b0, "peek empty tag5");

    // Search when empty
    do_match(32'h0000_0000, 32'h0000_0000, "match all-zero mask empty");
    do_match(32'h0000_0010, 32'hFFFF_FFFF, "match exact empty");

    // ---------------------------------------------------------------------
    // Push/pop after empty
    // ---------------------------------------------------------------------
    push_entry(3'd4, 32'hABCD_1234, "push after empty");
    check_status("after push after empty");
    pop_entry(3'd4, 1'b1, "pop after empty");
    check_status("after pop after empty");

    // ---------------------------------------------------------------------
    // R15: reset again while non-empty
    // ---------------------------------------------------------------------
    push_entry(3'd5, 32'h1111_1111, "push before reset");
    push_entry(3'd5, 32'h2222_2222, "push before reset 2");

    bfm_reset();
    reset_model();
    bfm_tick();
    bfm_drive_point();
    check_status("after second reset");
    if (empty_sig !== 1'b1) fail("R15", "empty_o not high after second reset");
    if (full_sig  !== 1'b0) fail("R15", "full_o not low after second reset");

    // ---------------------------------------------------------------------
    // Done
    // ---------------------------------------------------------------------
    $display("RESULT: PASS");
    $finish;
  end

endmodule
