module tag_tracker_tb;

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
  // Testbench configuration
  // ---------------------------------------------------------------------------
  localparam int TIMEOUT = 1_000_000;
  localparam int SLOTS = 8;
  localparam int TAGS = 8;

  // DUT signals
  logic [2:0] push_tag;
  logic [31:0] push_data;
  logic push_req;
  logic push_gnt;

  logic [31:0] [0:0] match_data;
  logic [31:0] [0:0] match_mask;
  logic [0:0] match_req;
  logic [0:0] match_hit;
  logic [0:0] match_gnt;

  logic [2:0] pop_tag;
  logic pop_en;
  logic pop_req;
  logic [31:0] pop_data;
  logic pop_data_valid;
  logic pop_gnt;

  logic full;
  logic empty;

  // Reference model: per-tag FIFO queues
  logic [31:0] model_q [8][$];
  int total_entries = 0;

  // DUT
  tag_tracker #(
    .TAG_W(3),
    .SLOTS(8),
    .FULL_RATE(1'b0),
    .CUT_POP_PATH(1'b0),
    .N_MATCH(1)
  ) dut (
    .clk_i(clk),
    .rst_ni(rst_n),

    .push_tag_i(push_tag),
    .push_data_i(push_data),
    .push_req_i(push_req),
    .push_gnt_o(push_gnt),

    .match_data_i(match_data),
    .match_mask_i(match_mask),
    .match_req_i(match_req),
    .match_hit_o(match_hit),
    .match_gnt_o(match_gnt),

    .pop_tag_i(pop_tag),
    .pop_en_i(pop_en),
    .pop_req_i(pop_req),
    .pop_data_o(pop_data),
    .pop_data_valid_o(pop_data_valid),
    .pop_gnt_o(pop_gnt),

    .full_o(full),
    .empty_o(empty)
  );

  // ---------------------------------------------------------------------------
  // Helper tasks
  // ---------------------------------------------------------------------------
  task automatic wait_cycles(input int n);
    repeat (n) begin
      @(posedge clk);
      @(negedge clk);
    end
  endtask

  task automatic fail_test(input string req, input string msg);
    $display("FAIL %s: %s", req, msg);
    $display("RESULT: FAIL");
    $finish;
  endtask

  task automatic check_true(input logic cond, input string req, input string msg);
    if (cond !== 1'b1) fail_test(req, msg);
  endtask

  task automatic check_status(input string req, input logic exp_empty, input logic exp_full);
    if (empty !== exp_empty) begin
      $display("FAIL %s: empty_o=%b expected=%b", req, empty, exp_empty);
      $display("RESULT: FAIL");
      $finish;
    end
    if (full !== exp_full) begin
      $display("FAIL %s: full_o=%b expected=%b", req, full, exp_full);
      $display("RESULT: FAIL");
      $finish;
    end
  endtask

  task automatic clear_model();
    int t;
    for (t = 0; t < TAGS; t++) begin
      model_q[t].delete();
    end
    total_entries = 0;
  endtask

  task automatic do_push(input logic [2:0] tag, input logic [31:0] data);
    int wait_cnt;
    push_req = 1'b1;
    push_tag = tag;
    push_data = data;
    wait_cnt = 0;

    while (1) begin
      @(negedge clk);
      wait_cnt = wait_cnt + 1;
      if (push_gnt === 1'b1) break;
      if (wait_cnt >= TIMEOUT) fail_test("R1", "push not granted while space exists");
    end

    model_q[tag].push_back(data);
    total_entries = total_entries + 1;
    push_req = 1'b0;
  endtask

  task automatic do_pop(
    input logic [2:0] tag,
    input logic en,
    output logic [31:0] data_o,
    output logic valid_o
  );
    int wait_cnt;
    logic [31:0] expected_data;

    pop_req = 1'b1;
    pop_tag = tag;
    pop_en = en;
    wait_cnt = 0;

    while (1) begin
      @(negedge clk);
      wait_cnt = wait_cnt + 1;
      if (pop_gnt === 1'b1) break;
      if (wait_cnt >= TIMEOUT) fail_test("R7", "pop not granted");
    end

    valid_o = pop_data_valid;
    data_o = pop_data;

    if (valid_o === 1'b1) begin
      if (model_q[tag].size() == 0)
        fail_test("R8", "pop_data_valid high but model has no entry for tag");

      expected_data = model_q[tag][0];
      if (data_o !== expected_data)
        fail_test("R2", "pop_data_o not oldest entry for tag");

      if (en === 1'b1) begin
        model_q[tag].pop_front();
        total_entries = total_entries - 1;
      end
    end else begin
      if (model_q[tag].size() != 0)
        fail_test("R8", "pop_data_valid low but model has entries for tag");
    end

    pop_req = 1'b0;
  endtask

  task automatic do_search(
    input logic [31:0] mdata,
    input logic [31:0] mmask,
    output logic hit_o
  );
    int wait_cnt;

    match_req[0] = 1'b1;
    match_data[0] = mdata;
    match_mask[0] = mmask;
    wait_cnt = 0;

    while (1) begin
      @(negedge clk);
      wait_cnt = wait_cnt + 1;
      if (match_gnt[0] === 1'b1) break;
      if (wait_cnt >= TIMEOUT) fail_test("R11", "search not granted");
    end

    hit_o = match_hit[0];
    match_req[0] = 1'b0;
  endtask

  function automatic logic search_model(
    input logic [31:0] mdata,
    input logic [31:0] mmask
  );
    int t, i;
    for (t = 0; t < TAGS; t++) begin
      for (i = 0; i < model_q[t].size(); i++) begin
        if ((model_q[t][i] & mmask) == (mdata & mmask))
          return 1'b1;
      end
    end
    return 1'b0;
  endfunction

  // ---------------------------------------------------------------------------
  // Main stimulus
  // ---------------------------------------------------------------------------
  initial begin
    // Local variables -- declare first
    logic search_hit;
    logic expected_hit;
    logic pop_valid;
    logic [31:0] pop_data_local;
    int i;

    // Initialize inputs
    push_req = 1'b0;
    push_tag = 3'b0;
    push_data = 32'h0;
    pop_req = 1'b0;
    pop_tag = 3'b0;
    pop_en = 1'b0;
    match_req[0] = 1'b0;
    match_data[0] = 32'h0;
    match_mask[0] = 32'h0;

    clear_model();

    // Reset and initial status
    bfm_reset(4);
    wait_cycles(1);
    check_status("R15", 1'b1, 1'b0);

    // ---------------------------------------------------------------------
    // Phase 1: capacity and per-tag FIFO with all entries under one tag
    // ---------------------------------------------------------------------
    for (i = 0; i < 8; i++) begin
      do_push(3'd0, 32'hA0 + i[31:0]);
      check_status("R14", 1'b0, (total_entries == SLOTS) ? 1'b1 : 1'b0);
    end
    check_status("R14", 1'b0, 1'b1);

    // R5: push_gnt must be low when full
    push_req = 1'b1;
    push_tag = 3'd0;
    push_data = 32'hDEAD_BEEF;
    for (i = 0; i < 4; i++) begin
      @(negedge clk);
      check_true(full === 1'b1, "R14", "full_o low while store full");
      check_true(push_gnt === 1'b0, "R5", "push_gnt high while store full");
    end
    push_req = 1'b0;

    // R11/R12/R13: search across all tags
    do_search(32'hA0, 32'hFFFF_FFFF, search_hit);
    expected_hit = search_model(32'hA0, 32'hFFFF_FFFF);
    check_true(search_hit === expected_hit, "R12", "search A0 hit mismatch");

    do_search(32'hA7, 32'hFFFF_FFFF, search_hit);
    expected_hit = search_model(32'hA7, 32'hFFFF_FFFF);
    check_true(search_hit === expected_hit, "R12", "search A7 hit mismatch");

    do_search(32'hC0, 32'hFFFF_FFFF, search_hit);
    expected_hit = search_model(32'hC0, 32'hFFFF_FFFF);
    check_true(search_hit === expected_hit, "R12", "search C0 miss mismatch");

    do_search(32'h0000_0000, 32'h0000_0000, search_hit);
    expected_hit = search_model(32'h0000_0000, 32'h0000_0000);
    check_true(search_hit === expected_hit, "R13", "zero-mask search mismatch");
    check_true(expected_hit === 1'b1, "R13", "zero-mask should hit when non-empty");

    // R2/R7/R8: pop all tag 0 entries in FIFO order
    for (i = 0; i < 8; i++) begin
      do_pop(3'd0, 1'b1, pop_data_local, pop_valid);
      check_true(pop_valid === 1'b1, "R8", "pop valid not high for existing tag");
      check_true(pop_data_local === 32'hA0 + i[31:0], "R2", "tag0 FIFO order mismatch");
    end
    check_status("R14", 1'b1, 1'b0);

    // R13 on empty store
    do_search(32'h0000_0000, 32'h0000_0000, search_hit);
    expected_hit = search_model(32'h0000_0000, 32'h0000_0000);
    check_true(search_hit === expected_hit, "R13", "zero-mask empty mismatch");
    check_true(search_hit === 1'b0, "R13", "zero-mask should miss on empty");

    // ---------------------------------------------------------------------
    // Phase 2: multi-tag operation, inspect, missing-tag pop
    // ---------------------------------------------------------------------
    for (i = 0; i < 4; i++) begin
      do_push(3'd1, 32'hB0 + i[31:0]);
      check_status("R14", 1'b0, (total_entries == SLOTS) ? 1'b1 : 1'b0);
    end
    for (i = 0; i < 4; i++) begin
      do_push(3'd2, 32'hC0 + i[31:0]);
      check_status("R14", 1'b0, (total_entries == SLOTS) ? 1'b1 : 1'b0);
    end
    check_status("R14", 1'b0, 1'b1);

    // Search across multiple tags
    do_search(32'hB2, 32'hFFFF_FFFF, search_hit);
    expected_hit = search_model(32'hB2, 32'hFFFF_FFFF);
    check_true(search_hit === expected_hit, "R12", "search B2 mismatch");

    do_search(32'hC3, 32'hFFFF_FFFF, search_hit);
    expected_hit = search_model(32'hC3, 32'hFFFF_FFFF);
    check_true(search_hit === expected_hit, "R12", "search C3 mismatch");

    do_search(32'hA0, 32'hFFFF_FFFF, search_hit);
    expected_hit = search_model(32'hA0, 32'hFFFF_FFFF);
    check_true(search_hit === expected_hit, "R12", "search removed A0 mismatch");

    // Partial mask check
    do_search(32'h0000_0000, 32'h0000_000F, search_hit);
    expected_hit = search_model(32'h0000_0000, 32'h0000_000F);
    check_true(search_hit === expected_hit, "R12", "partial mask hit mismatch");

    do_search(32'h0000_000F, 32'h0000_000F, search_hit);
    expected_hit = search_model(32'h0000_000F, 32'h0000_000F);
    check_true(search_hit === expected_hit, "R12", "partial mask miss mismatch");

    do_search(32'h0000_0000, 32'h0000_0000, search_hit);
    expected_hit = search_model(32'h0000_0000, 32'h0000_0000);
    check_true(search_hit === expected_hit, "R13", "zero-mask non-empty mismatch");
    check_true(expected_hit === 1'b1, "R13", "zero-mask should hit when non-empty");

    // R9: pop_en=0 inspects but does not remove
    do_pop(3'd1, 1'b0, pop_data_local, pop_valid);
    check_true(pop_valid === 1'b1, "R8", "pop inspect valid not high");
    check_true(pop_data_local === 32'hB0, "R2", "pop inspect data not oldest");
    check_true(total_entries == 8, "R9", "pop with pop_en=0 removed entry");
    check_true(model_q[1].size() == 4, "R9", "pop with pop_en=0 removed entry");

    // Remove oldest tag1 after inspect
    do_pop(3'd1, 1'b1, pop_data_local, pop_valid);
    check_true(pop_valid === 1'b1, "R8", "pop valid not high after inspect");
    check_true(pop_data_local === 32'hB0, "R2", "pop data not B0 after inspect");
    check_status("R14", 1'b0, 1'b0);

    // Pop remaining tag1 FIFO
    for (i = 1; i < 4; i++) begin
      do_pop(3'd1, 1'b1, pop_data_local, pop_valid);
      check_true(pop_valid === 1'b1, "R8", "pop valid not high for tag1");
      check_true(pop_data_local === 32'hB0 + i[31:0], "R2", "tag1 FIFO order mismatch");
    end
    check_status("R14", 1'b0, 1'b0);

    // R10: pop of a tag with no entries completes with valid low
    do_pop(3'd3, 1'b1, pop_data_local, pop_valid);
    check_true(pop_valid === 1'b0, "R10", "pop missing tag valid not low");

    // Pop tag2 FIFO
    for (i = 0; i < 4; i++) begin
      do_pop(3'd2, 1'b1, pop_data_local, pop_valid);
      check_true(pop_valid === 1'b1, "R8", "pop valid not high for tag2");
      check_true(pop_data_local === 32'hC0 + i[31:0], "R2", "tag2 FIFO order mismatch");
    end
    check_status("R14", 1'b1, 1'b0);

    // ---------------------------------------------------------------------
    // R15: reset clears store
    // ---------------------------------------------------------------------
    do_push(3'd4, 32'hD0);
    do_push(3'd4, 32'hD1);
    check_status("R14", 1'b0, 1'b0);

    push_req = 1'b0;
    pop_req = 1'b0;
    match_req[0] = 1'b0;
    pop_en = 1'b0;

    bfm_reset(4);
    clear_model();
    wait_cycles(1);
    check_status("R15", 1'b1, 1'b0);

    $display("RESULT: PASS");
    $finish;
  end

endmodule