// Self-checking testbench for tag_tracker
// Covers R1-R15 as written in the specification.
// It intentionally does NOT check:
//   - arbitration policy
//   - cross-tag ordering
//   - pop_data_o when pop_data_valid_o is low
//   - combinational vs registered timing (beyond handshakes)
//   - internal structure
//   - latency (except a generous timeout)
module tb_tag_tracker;

  // ------------------------------------------------------------
  // Testbench parameters (match the DUT's expected parameter names)
  // ------------------------------------------------------------
  localparam int unsigned TAG_W       = 4;
  localparam int unsigned SLOTS       = 8;
  localparam int unsigned N_MATCH     = 2;
  localparam type payload_t           = logic [31:0];
  localparam bit FULL_RATE            = 1;
  localparam bit CUT_POP_PATH         = 1;

  // Number of distinct tags used by the directed test patterns
  localparam int unsigned NUM_TEST_TAGS = 4;

  // ------------------------------------------------------------
  // DUT signals
  // ------------------------------------------------------------
  logic clk;
  logic rst_ni;

  logic                   push_req;
  logic [TAG_W-1:0]       push_tag;
  payload_t               push_data;
  logic                   push_gnt;

  logic                   pop_req;
  logic [TAG_W-1:0]       pop_tag;
  logic                   pop_en;
  logic                   pop_gnt;
  logic                   pop_valid;
  payload_t               pop_data;

  logic [N_MATCH-1:0]     match_req;
  payload_t               match_data [N_MATCH];
  payload_t               match_mask [N_MATCH];
  logic [N_MATCH-1:0]     match_gnt;
  logic [N_MATCH-1:0]     match_hit;

  logic                   empty_o;
  logic                   full_o;

  // ------------------------------------------------------------
  // Reference model
  // ------------------------------------------------------------
  typedef payload_t payload_queue_t [$];
  payload_queue_t tag_q [int unsigned]; // per-tag FIFO queues

  int unsigned cnt    = 0;
  int unsigned checks = 0;
  int unsigned errors = 0;

  // ------------------------------------------------------------
  // Clock and reset
  // ------------------------------------------------------------
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  // ------------------------------------------------------------
  // DUT instance
  // ------------------------------------------------------------
  tag_tracker #(
    .TAG_W        (TAG_W),
    .SLOTS        (SLOTS),
    .N_MATCH      (N_MATCH),
    .payload_t    (payload_t),
    .FULL_RATE    (FULL_RATE),
    .CUT_POP_PATH (CUT_POP_PATH)
  ) dut (
    .clk             (clk),
    .rst_ni          (rst_ni),
    .push_req_i      (push_req),
    .push_tag_i      (push_tag),
    .push_data_i     (push_data),
    .push_gnt_o      (push_gnt),
    .pop_req_i       (pop_req),
    .pop_tag_i       (pop_tag),
    .pop_en_i        (pop_en),
    .pop_gnt_o       (pop_gnt),
    .pop_data_valid_o(pop_valid),
    .pop_data_o      (pop_data),
    .match_req_i     (match_req),
    .match_data_i    (match_data),
    .match_mask_i    (match_mask),
    .match_gnt_o     (match_gnt),
    .match_hit_o     (match_hit),
    .empty_o         (empty_o),
    .full_o          (full_o)
  );

  // ------------------------------------------------------------
  // Helper functions / tasks
  // ------------------------------------------------------------
  function automatic bit payload_match(payload_t p, payload_t d, payload_t m);
    return ((p & m) == (d & m));
  endfunction

  function automatic bit model_hit(payload_t d, payload_t m);
    foreach (tag_q[tag]) begin
      foreach (tag_q[tag][i]) begin
        if (payload_match(tag_q[tag][i], d, m))
          return 1;
      end
    end
    return 0;
  endfunction

  task automatic check(input logic cond, input string msg);
    checks++;
    if (cond !== 1'b1) begin
      errors++;
      $error("CHECK FAILED [%0t]: %s", $time, msg);
      if (errors > 20) $finish;
    end
  endtask

  task automatic wait_cycles(input int unsigned n);
    repeat (n) @(posedge clk);
  endtask

  task automatic clear_model();
    tag_q.delete();
    cnt = 0;
  endtask

  task automatic check_status();
    wait_cycles(1);
    check(empty_o === ((cnt == 0) ? 1'b1 : 1'b0),
          "empty_o exactly when zero entries");
    check(full_o === ((cnt == SLOTS) ? 1'b1 : 1'b0),
          "full_o exactly when SLOTS entries");
    if (full_o === 1'b1 && push_gnt_o === 1'b1) begin
      check(1'b0, "push_gnt_o high while full_o high");
    end
  endtask

  // ------------------------------------------------------------
  // Transaction-level tasks
  // ------------------------------------------------------------
  task automatic wait_push_handshake();
    int timeout = 10000;
    while ((push_req !== 1'b1 || push_gnt !== 1'b1) && timeout > 0) begin
      @(posedge clk);
      timeout--;
    end
    if (timeout == 0) begin
      $error("Timeout waiting for push handshake");
      $finish;
    end
  endtask

  task automatic do_push(input logic [TAG_W-1:0] tag, input payload_t data);
    push_req  <= 1'b1;
    push_tag  <= tag;
    push_data <= data;

    wait_push_handshake();

    push_req <= 1'b0;
    @(posedge clk);
  endtask

  task automatic wait_pop_handshake();
    int timeout = 10000;
    while ((pop_req !== 1'b1 || pop_gnt !== 1'b1) && timeout > 0) begin
      @(posedge clk);
      timeout--;
    end
    if (timeout == 0) begin
      $error("Timeout waiting for pop handshake");
      $finish;
    end
  endtask

  task automatic do_pop(input logic [TAG_W-1:0] tag,
                        input logic             en,
                        output logic            valid,
                        output payload_t        data);
    pop_req <= 1'b1;
    pop_tag <= tag;
    pop_en  <= en;

    wait_pop_handshake();

    valid = pop_valid;
    data  = pop_data;

    pop_req <= 1'b0;
    @(posedge clk);
  endtask

  task automatic wait_match_handshake(input int unsigned k);
    int timeout = 10000;
    while ((match_req[k] !== 1'b1 || match_gnt[k] !== 1'b1) && timeout > 0) begin
      @(posedge clk);
      timeout--;
    end
    if (timeout == 0) begin
      $error("Timeout waiting for match handshake on port %0d", k);
      $finish;
    end
  endtask

  task automatic do_search(input int unsigned k,
                           input payload_t     data,
                           input payload_t     mask,
                           output logic        hit);
    match_req[k]  <= 1'b1;
    match_data[k] <= data;
    match_mask[k] <= mask;

    wait_match_handshake(k);

    hit = match_hit[k];

    match_req[k] <= 1'b0;
    @(posedge clk);
  endtask

  // ------------------------------------------------------------
  // Central monitor / reference-model update
  // ------------------------------------------------------------
  always_ff @(posedge clk) begin
    if (!rst_ni) begin
      tag_q.delete();
      cnt = 0;
    end else begin
      // Push commit
      if (push_req === 1'b1 && push_gnt === 1'b1) begin
        if (cnt >= SLOTS) begin
          check(1'b0, "push granted while model is full");
        end
        if (!tag_q.exists(int'(push_tag)))
          tag_q[int'(push_tag)] = {};
        tag_q[int'(push_tag)].push_back(push_data);
        cnt = cnt + 1;
      end

      // Pop completion
      if (pop_req === 1'b1 && pop_gnt === 1'b1) begin
        if (tag_q.exists(int'(pop_tag)) && tag_q[int'(pop_tag)].size() > 0) begin
          check(pop_valid === 1'b1, "pop_data_valid_o high when entry exists");
          if (pop_valid === 1'b1) begin
            check(pop_data === tag_q[int'(pop_tag)][0],
                  "pop_data_o carries oldest entry for tag");
          end
          if (pop_en === 1'b1) begin
            tag_q[int'(pop_tag)].pop_front();
            cnt = cnt - 1;
          end
        end else begin
          check(pop_valid === 1'b0, "pop_data_valid_o low for absent tag");
        end
      end

      // Search completions
      for (int k = 0; k < N_MATCH; k++) begin
        if (match_req[k] === 1'b1 && match_gnt[k] === 1'b1) begin
          check(match_hit[k] === model_hit(match_data[k], match_mask[k]),
                "search hit matches reference model");
        end
      end
    end
  end

  // ------------------------------------------------------------
  // Main test sequence
  // ------------------------------------------------------------
  initial begin
    // Initialize inputs and hold reset
    rst_ni    = 1'b0;
    push_req  = 1'b0;
    push_tag  = {TAG_W{1'b0}};
    push_data = '0;
    pop_req   = 1'b0;
    pop_tag   = {TAG_W{1'b0}};
    pop_en    = 1'b0;
    match_req = '0;
    for (int k = 0; k < N_MATCH; k++) begin
      match_data[k] = '0;
      match_mask[k] = '0;
    end

    repeat (4) @(posedge clk);
    rst_ni = 1'b1;
    repeat (2) @(posedge clk);

    clear_model();
    check_status();

    // ---------------------------------------------------------
    // Capacity, full, and per-tag FIFO
    // ---------------------------------------------------------
    for (int i = 0; i < SLOTS; i++) begin
      automatic int tag = i % NUM_TEST_TAGS;
      do_push(tag, payload_t'(i));
    end

    wait_cycles(2);
    check_status();
    check(full_o === 1'b1, "full_o high after filling SLOTS entries");
    check(empty_o === 1'b0, "empty_o low after filling SLOTS entries");

    // R5: push_gnt_o must be low when full, even if request is pending.
    push_req  <= 1'b1;
    push_tag  <= {TAG_W{1'b0}};
    push_data <= '0;
    wait_cycles(1);
    check(push_gnt === 1'b0, "push_gnt_o low while full with pending request");
    push_req <= 1'b0;
    wait_cycles(1);

    // R2/R8: per-tag FIFO removal
    for (int tag = 0; tag < NUM_TEST_TAGS; tag++) begin
      for (int j = tag; j < SLOTS; j += NUM_TEST_TAGS) begin
        logic       valid;
        payload_t   data;

        do_pop(tag, 1'b1, valid, data);
        check(valid === 1'b1, $sformatf("pop valid for tag %0d", tag));
        check(data === payload_t'(j),
              $sformatf("FIFO data mismatch for tag %0d: expected %0d", tag, j));
      end

      // Pop from now-absent tag
      begin
        logic       valid;
        payload_t   data;
        do_pop(tag, 1'b1, valid, data);
        check(valid === 1'b0, $sformatf("absent pop valid low for tag %0d", tag));
      end
    end

    wait_cycles(2);
    check_status();

    // ---------------------------------------------------------
    // Reset during operation
    // ---------------------------------------------------------
    do_push(0, 'hA5);
    do_push(1, 'h5A);
    wait_cycles(1);

    rst_ni = 1'b0;
    wait_cycles(3);
    rst_ni = 1'b1;
    wait_cycles(3);

    clear_model();
    check_status();

    // ---------------------------------------------------------
    // Peek vs pop (R9)
    // ---------------------------------------------------------
    do_push(1, 'h10);
    do_push(1, 'h20);
    do_push(2, 'h30);
    wait_cycles(1);
    check_status();

    begin
      logic       valid;
      payload_t   data;

      // Peek: should return oldest entry but not remove it.
      do_pop(1, 1'b0, valid, data);
      check(valid === 1'b1, "peek valid high");
      check(data === 'h10,  "peek returns oldest entry");

      // Remove the peeked entry.
      do_pop(1, 1'b1, valid, data);
      check(valid === 1'b1, "pop after peek valid high");
      check(data === 'h10,  "pop after peek returns same oldest entry");

      do_pop(1, 1'b1, valid, data);
      check(valid === 1'b1, "second pop valid high");
      check(data === 'h20,  "second pop returns next entry");

      do_pop(1, 1'b1, valid, data);
      check(valid === 1'b0, "pop from emptied tag valid low");

      do_pop(2, 1'b1, valid, data);
      check(valid === 1'b1, "pop other tag valid high");
      check(data === 'h30,  "pop other tag data correct");
    end

    wait_cycles(2);
    check_status();

    // ---------------------------------------------------------
    // Search (R11/R12/R13)
    // ---------------------------------------------------------
    do_push(0, 'h1010);
    do_push(1, 'h1020);
    do_push(2, 'h2020);
    do_push(3, 'hFFFF);
    wait_cycles(1);
    check_status();

    begin
      logic hit;

      do_search(0, 'h1010, 'hFFFF, hit);
      check(hit === 1'b1, "exact search hit");

      do_search(0, 'h9999, 'hFFFF, hit);
      check(hit === 1'b0, "exact search miss");

      // Masked match: high nibble 1 matches 1010 and 1020.
      do_search(1, 'h1000, 'hF000, hit);
      check(hit === 1'b1, "masked search hit");

      // Masked miss: no payload has high nibble A.
      do_search(1, 'hA000, 'hF000, hit);
      check(hit === 1'b0, "masked search miss");

      // Zero mask matches every stored entry when store is non-empty.
      do_search(0, 'h0, 'h0, hit);
      check(hit === 1'b1, "zero mask hits non-empty store");

      // Search across tags.
      do_search(0, 'h1020, 'hFFFF, hit);
      check(hit === 1'b1, "search across tags");
    end

    // Pop all search-test entries.
    begin
      logic       valid;
      payload_t   data;

      do_pop(0, 1'b1, valid, data);
      check(valid === 1'b1 && data === 'h1010, "pop search entry tag0");
      do_pop(1, 1'b1, valid, data);
      check(valid === 1'b1 && data === 'h1020, "pop search entry tag1");
      do_pop(2, 1'b1, valid, data);
      check(valid === 1'b1 && data === 'h2020, "pop search entry tag2");
      do_pop(3, 1'b1, valid, data);
      check(valid === 1'b1 && data === 'hFFFF, "pop search entry tag3");
    end

    wait_cycles(2);
    check_status();

    // Zero mask on empty store must miss.
    begin
      logic hit;
      do_search(0, 'h0, 'h0, hit);
      check(hit === 1'b0, "zero mask misses empty store");
    end

    // ---------------------------------------------------------
    // Concurrent push / pop / search smoke test
    // ---------------------------------------------------------
    do_push(0, 'hAAAA);
    do_push(1, 'hBBBB);
    wait_cycles(1);
    check_status();

    begin
      logic       valid;
      payload_t   data;
      logic       hit;

      fork
        do_push(2, 'hCCCC);
        do_pop(0, 1'b1, valid, data);
        do_search(0, 'hBBBB, 'hFFFF, hit);
      join

      check(valid === 1'b1, "concurrent pop valid");
      check(data === 'hAAAA, "concurrent pop data");
      check(hit === 1'b1, "concurrent search hit");

      wait_cycles(1);
      check_status();

      if (cnt != 2) begin
        check(1'b0, $sformatf("concurrent model count expected 2, got %0d", cnt));
      end

      do_pop(1, 1'b1, valid, data);
      check(valid === 1'b1 && data === 'hBBBB, "pop remaining tag1");
      do_pop(2, 1'b1, valid, data);
      check(valid === 1'b1 && data === 'hCCCC, "pop remaining tag2");
    end

    wait_cycles(2);
    check_status();

    // ---------------------------------------------------------
    // Final result
    // ---------------------------------------------------------
    $display("tag_tracker testbench finished: %0d checks, %0d errors", checks, errors);
    if (errors == 0)
      $display("PASS");
    else
      $display("FAIL");

    $finish;
  end

endmodule