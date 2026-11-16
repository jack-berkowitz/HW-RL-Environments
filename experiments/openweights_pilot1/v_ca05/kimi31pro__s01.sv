`timescale 1ns/1ps

module tag_tracker_tb;

  localparam int TAG_W   = 3;
  localparam int SLOTS   = 8;
  localparam int N_MATCH = 1;
  localparam int NTAGS   = 1 << TAG_W;

  // A generous transaction timeout is used only to guarantee forward progress
  // and termination; no particular grant latency is otherwise checked.
  localparam int unsigned MAX_WAIT = 512;

  typedef logic [TAG_W-1:0] tag_t;
  typedef logic [31:0]      payload_t;

  typedef struct packed {
    tag_t     tag;
    payload_t data;
  } entry_t;

  tag_t     push_tag;
  payload_t push_data;
  logic     push_req;
  logic     push_gnt;

  // These are packed arrays, matching the DUT port declarations exactly.
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

  // Global insertion order is used only to find the oldest entry for a tag.
  // No ordering between different tags is ever checked.
  entry_t model_q[$];

  // ---------------------------------------------------------------------------
  // PROVIDED PLUMBING -- clock, reset and watchdog only.
  // ---------------------------------------------------------------------------
  // NO TRANSACTOR IS PROVIDED FOR THE REQUEST/GRANT PORTS. Driving them, and
  // deciding when a request has completed, is part of the task.
  //
  // What is provided is the timing discipline, because getting it wrong is
  // silent: reset is asserted and released away from the sampling edge, and the
  // helper below moves you to the point in the cycle where it is safe to change
  // stimulus. It has been compiled and run against a correct implementation.
  // ---------------------------------------------------------------------------
  // ---- clock -----------------------------------------------------------------
  logic clk;
  initial begin clk = 1'b0; forever #5 clk = ~clk; end

  // ---- reset (active low) ----------------------------------------------------
  logic rst_n;
  initial rst_n = 1'b0;

  task automatic bfm_reset(input int cycles = 4);
    @(negedge clk);
    rst_n = 1'b0;
    repeat (cycles) @(posedge clk);
    @(negedge clk);
    rst_n = 1'b1;
  endtask

  // ---- timing discipline -----------------------------------------------------
  // Advance to the point in the cycle where it is safe to change stimulus.
  // Drive your inputs immediately after calling this, never straight after a
  // @(posedge clk): an assignment in the same timestep as the sampling edge
  // races the design and makes correct hardware look inert.
  task automatic bfm_drive_point();
    @(negedge clk);
  endtask

  // Advance one full cycle and return after the design has sampled.
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
  // DUT
  // ---------------------------------------------------------------------------
  tag_tracker #(
    .TAG_W        (TAG_W),
    .SLOTS        (SLOTS),
    .FULL_RATE    (1'b0),
    .CUT_POP_PATH (1'b0),
    .N_MATCH      (N_MATCH),
    .payload_t    (payload_t)
  ) dut (
    .clk_i             (clk),
    .rst_ni            (rst_n),

    .push_tag_i        (push_tag),
    .push_data_i       (push_data),
    .push_req_i        (push_req),
    .push_gnt_o        (push_gnt),

    .match_data_i      (match_data),
    .match_mask_i      (match_mask),
    .match_req_i       (match_req),
    .match_hit_o       (match_hit),
    .match_gnt_o       (match_gnt),

    .pop_tag_i         (pop_tag),
    .pop_en_i          (pop_en),
    .pop_req_i         (pop_req),
    .pop_data_o        (pop_data),
    .pop_data_valid_o  (pop_data_valid),
    .pop_gnt_o         (pop_gnt),

    .full_o            (full),
    .empty_o           (empty)
  );

  // ---------------------------------------------------------------------------
  // Checking utilities
  // ---------------------------------------------------------------------------
  task automatic fail_now(input string rule, input string detail);
    $display("FAIL %s: %s", rule, detail);
    $display("RESULT: FAIL");
    $finish;
  endtask

  task automatic check_status(input string phase_name);
    int unsigned count_now;
    logic expected_empty;
    logic expected_full;

    count_now      = model_q.size();
    expected_empty = (count_now == 0);
    expected_full  = (count_now == SLOTS);

    if (empty !== expected_empty) begin
      fail_now(
        "R14",
        $sformatf("%s: model count=%0d, empty_o=%0b, expected=%0b",
                  phase_name, count_now, empty, expected_empty)
      );
    end

    if (full !== expected_full) begin
      fail_now(
        "R14",
        $sformatf("%s: model count=%0d, full_o=%0b, expected=%0b",
                  phase_name, count_now, full, expected_full)
      );
    end

    if ((count_now == SLOTS) && (push_gnt !== 1'b0)) begin
      fail_now(
        "R5",
        $sformatf("%s: push_gnt_o=%0b while all %0d slots are occupied",
                  phase_name, push_gnt, SLOTS)
      );
    end
  endtask

  task automatic reset_and_clear();
    bfm_drive_point();
    push_req  = 1'b0;
    pop_req   = 1'b0;
    match_req = '0;

    bfm_reset();
    model_q.delete();

    if (empty !== 1'b1) begin
      fail_now("R15",
               $sformatf("empty_o=%0b after reset release", empty));
    end
    if (full !== 1'b0) begin
      fail_now("R15",
               $sformatf("full_o=%0b after reset release", full));
    end

    check_status("after reset");
  endtask

  // ---------------------------------------------------------------------------
  // Sequential transactors. Only one access path is requested at a time, so no
  // arbitration policy is assumed or checked.
  // ---------------------------------------------------------------------------
  task automatic do_push(input tag_t tag_value,
                         input payload_t data_value);
    entry_t new_entry;
    int unsigned waited;
    bit completed;

    completed = 1'b0;
    waited    = 0;

    bfm_drive_point();
    pop_req   = 1'b0;
    match_req = '0;
    push_tag  = tag_value;
    push_data = data_value;
    push_req  = 1'b1;

    while (!completed && (waited < MAX_WAIT)) begin
      bfm_tick();
      waited = waited + 1;

      if (push_gnt === 1'b1) begin
        // R4: the model commits an entry only on request && grant.
        new_entry.tag  = tag_value;
        new_entry.data = data_value;
        model_q.push_back(new_entry);
        completed = 1'b1;
      end
      else if (push_gnt !== 1'b0) begin
        fail_now("R4",
                 $sformatf("push_gnt_o is unknown (%0b)", push_gnt));
      end
    end

    bfm_drive_point();
    push_req = 1'b0;

    if (!completed) begin
      fail_now(
        "R4",
        $sformatf("push of tag=%0d data=%08x made no forward progress",
                  tag_value, data_value)
      );
    end

    check_status("after push");
  endtask

  task automatic do_pop(input tag_t tag_value, input bit remove_en);
    entry_t expected_entry;
    int found_idx;
    int i;
    int unsigned waited;
    bit expected_valid;
    bit completed;

    expected_valid = 1'b0;
    expected_entry = '0;
    found_idx      = -1;
    completed      = 1'b0;
    waited         = 0;

    // Find the oldest model entry for this tag, irrespective of other tags.
    for (i = 0; i < model_q.size(); i = i + 1) begin
      if (!expected_valid && (model_q[i].tag == tag_value)) begin
        expected_valid = 1'b1;
        expected_entry = model_q[i];
        found_idx      = i;
      end
    end

    bfm_drive_point();
    push_req  = 1'b0;
    match_req = '0;
    pop_tag   = tag_value;
    pop_en    = remove_en;
    pop_req   = 1'b1;

    while (!completed && (waited < MAX_WAIT)) begin
      bfm_tick();
      waited = waited + 1;

      if (pop_gnt === 1'b1) begin
        // R8/R10: validity is checked on every completing pop. Data is checked
        // only when valid; pop_data_o is deliberately free otherwise.
        if (pop_data_valid !== expected_valid) begin
          fail_now(
            "R8",
            $sformatf("pop tag=%0d en=%0d: valid=%0b, expected=%0b",
                      tag_value, remove_en, pop_data_valid, expected_valid)
          );
        end

        if (expected_valid) begin
          if (pop_data !== expected_entry.data) begin
            fail_now(
              "R8",
              $sformatf(
                "pop tag=%0d en=%0d: data=%08x, oldest expected=%08x",
                tag_value, remove_en, pop_data, expected_entry.data)
            );
          end

          // R9: inspection leaves the model unchanged; removal deletes exactly
          // the identified oldest entry.
          if (remove_en) begin
            model_q.delete(found_idx);
          end
        end

        completed = 1'b1;
      end
      else if (pop_gnt !== 1'b0) begin
        fail_now("R7",
                 $sformatf("pop_gnt_o is unknown (%0b)", pop_gnt));
      end
    end

    bfm_drive_point();
    pop_req = 1'b0;
    pop_en  = 1'b0;

    if (!completed) begin
      fail_now(
        "R7",
        $sformatf("pop of tag=%0d en=%0d made no forward progress",
                  tag_value, remove_en)
      );
    end

    check_status("after pop/peek");
  endtask

  task automatic do_search(input payload_t data_value,
                           input payload_t mask_value);
    int i;
    int unsigned waited;
    bit expected_hit;
    bit completed;

    expected_hit = 1'b0;
    completed    = 1'b0;
    waited       = 0;

    // R12: search every stored payload, without filtering by tag.
    for (i = 0; i < model_q.size(); i = i + 1) begin
      if ((model_q[i].data & mask_value) == (data_value & mask_value)) begin
        expected_hit = 1'b1;
      end
    end

    bfm_drive_point();
    push_req     = 1'b0;
    pop_req      = 1'b0;
    match_data[0] = data_value;
    match_mask[0] = mask_value;
    match_req     = '0;
    match_req[0]  = 1'b1;

    while (!completed && (waited < MAX_WAIT)) begin
      bfm_tick();
      waited = waited + 1;

      if (match_gnt[0] === 1'b1) begin
        if (match_hit[0] !== expected_hit) begin
          fail_now(
            "R12",
            $sformatf(
              "search data=%08x mask=%08x count=%0d: hit=%0b, expected=%0b",
              data_value, mask_value, model_q.size(),
              match_hit[0], expected_hit)
          );
        end
        completed = 1'b1;
      end
      else if (match_gnt[0] !== 1'b0) begin
        fail_now("R11",
                 $sformatf("match_gnt_o[0] is unknown (%0b)",
                           match_gnt[0]));
      end
    end

    bfm_drive_point();
    match_req = '0;

    if (!completed) begin
      fail_now(
        "R11",
        $sformatf("search data=%08x mask=%08x made no forward progress",
                  data_value, mask_value)
      );
    end

    check_status("after search");
  endtask

  task automatic check_full_push_reject(input tag_t tag_value,
                                        input payload_t data_value);
    int unsigned cycle_idx;

    if (model_q.size() != SLOTS) begin
      fail_now("R1", "internal test error: full-store test is not full");
    end

    bfm_drive_point();
    pop_req   = 1'b0;
    match_req = '0;
    push_tag  = tag_value;
    push_data = data_value;
    push_req  = 1'b1;

    // This is not a wait for a grant: every grant while full is a violation.
    for (cycle_idx = 0; cycle_idx < 4; cycle_idx = cycle_idx + 1) begin
      bfm_tick();
      if (push_gnt !== 1'b0) begin
        fail_now(
          "R5",
          $sformatf("push_gnt_o=%0b while full, attempted tag=%0d data=%08x",
                    push_gnt, tag_value, data_value)
        );
      end
    end

    bfm_drive_point();
    push_req = 1'b0;
    check_status("after full push rejection");
  endtask

  // ---------------------------------------------------------------------------
  // Directed requirements coverage
  // ---------------------------------------------------------------------------
  task automatic run_directed();
    int i;
    payload_t data_value;

    // R1: all SLOTS entries carrying one tag must be accepted.
    for (i = 0; i < SLOTS; i = i + 1) begin
      data_value = 32'hA500_0000 + i;
      do_push(tag_t'(5), data_value);
    end

    check_full_push_reject(tag_t'(6), 32'hDEAD_BEEF);

    // R12/R13: zero, exact and partial masks, both hit and miss cases.
    do_search(32'h0000_0000, 32'h0000_0000);
    do_search(32'hA500_0003, 32'hFFFF_FFFF);
    do_search(32'hDEAD_BEEF, 32'hFFFF_FFFF);
    do_search(32'h1234_0003, 32'h0000_00FF);
    do_search(32'hA500_0000, 32'hFFFF_0000);
    do_search(32'hB500_0003, 32'hFFFF_0000);

    // R8/R9: repeated peeks must preserve the oldest entry.
    do_pop(tag_t'(5), 1'b0);
    do_pop(tag_t'(5), 1'b0);
    do_pop(tag_t'(5), 1'b1);

    // The removed payload must no longer produce an exact-match hit.
    do_search(32'hA500_0000, 32'hFFFF_FFFF);

    // The next peek must observe the second inserted entry.
    do_pop(tag_t'(5), 1'b0);

    // Drain the remaining entries in per-tag FIFO order.
    for (i = 1; i < SLOTS; i = i + 1) begin
      do_pop(tag_t'(5), 1'b1);
    end
    do_pop(tag_t'(5), 1'b1);
    do_search(32'h0000_0000, 32'h0000_0000);

    // R1: a mixed distribution using the same shared capacity.
    do_push(tag_t'(0), 32'h1111_0000);
    do_push(tag_t'(1), 32'h2222_0000);
    do_push(tag_t'(0), 32'h1111_0001);
    do_push(tag_t'(2), 32'h3333_0000);
    do_push(tag_t'(1), 32'h2222_0001);
    do_push(tag_t'(7), 32'h7777_0000);
    do_push(tag_t'(0), 32'h1111_0002);
    do_push(tag_t'(2), 32'h3333_0001);

    // An absent-tag pop is legal and must not disturb a full store.
    do_pop(tag_t'(3), 1'b1);
    do_search(32'h0000_0000, 32'h0000_0000);

    // Interleave pops, peeks and pushes to exercise slot reuse.
    do_pop(tag_t'(1), 1'b1);       // 2222_0000
    do_push(tag_t'(3), 32'h4444_0000);
    do_pop(tag_t'(0), 1'b0);       // 1111_0000 remains
    do_pop(tag_t'(0), 1'b1);       // remove 1111_0000
    do_push(tag_t'(0), 32'h1111_0003);
    do_pop(tag_t'(1), 1'b0);       // 2222_0001 remains

    // Per-tag FIFO checks after reuse. The order among these different-tag
    // operations is stimulus order, not an expected DUT cross-tag ordering.
    do_pop(tag_t'(0), 1'b1);       // 1111_0001
    do_pop(tag_t'(0), 1'b1);       // 1111_0002
    do_pop(tag_t'(0), 1'b1);       // 1111_0003
    do_pop(tag_t'(1), 1'b1);       // 2222_0001
    do_pop(tag_t'(2), 1'b1);       // 3333_0000
    do_pop(tag_t'(2), 1'b1);       // 3333_0001
    do_pop(tag_t'(7), 1'b1);       // 7777_0000
    do_pop(tag_t'(3), 1'b1);       // 4444_0000
    do_pop(tag_t'(0), 1'b1);       // absent, store empty

    // Duplicate payloads under different tags: search is over all tags, and a
    // pop must remove only the requested tag's entry.
    do_push(tag_t'(6), 32'hCAFE_BABE);
    do_push(tag_t'(4), 32'hCAFE_BABE);
    do_search(32'hCAFE_BABE, 32'hFFFF_FFFF);
    do_pop(tag_t'(6), 1'b1);
    do_search(32'hCAFE_BABE, 32'hFFFF_FFFF);
    do_pop(tag_t'(4), 1'b1);
    do_search(32'hCAFE_BABE, 32'hFFFF_FFFF);
    do_search(32'h0000_0000, 32'h0000_0000);
  endtask

  // ---------------------------------------------------------------------------
  // Model-based randomized sequential stress
  // ---------------------------------------------------------------------------
  task automatic run_random(input int unsigned num_ops);
    int unsigned op_idx;
    int unsigned choice;
    int unsigned size_now;
    int unsigned pick_idx;
    tag_t tag_value;
    payload_t data_value;
    payload_t mask_value;

    for (op_idx = 0; op_idx < num_ops; op_idx = op_idx + 1) begin
      choice    = $urandom_range(0, 99);
      size_now  = model_q.size();
      tag_value = tag_t'($urandom_range(0, NTAGS - 1));
      data_value = $urandom;

      if ((size_now < SLOTS) && (choice < 38)) begin
        // Repeated values ensure that checking never relies on unique payloads.
        if ((op_idx % 9) == 0) begin
          data_value = 32'h1234_5678;
        end
        do_push(tag_value, data_value);
      end
      else if (choice < 62) begin
        do_pop(tag_value, 1'b1);
      end
      else if (choice < 78) begin
        do_pop(tag_value, 1'b0);
      end
      else begin
        // Often select an existing entry by its model index, guaranteeing a
        // useful search stimulus without identifying results by value.
        if ((size_now > 0) && ((choice % 2) == 0)) begin
          pick_idx   = $urandom_range(0, size_now - 1);
          data_value = model_q[pick_idx].data;
        end

        case (op_idx % 5)
          0: mask_value = 32'h0000_0000;
          1: mask_value = 32'hFFFF_FFFF;
          2: mask_value = 32'h0000_00FF;
          3: mask_value = 32'hFFFF_0000;
          default: mask_value = $urandom;
        endcase

        do_search(data_value, mask_value);
      end
    end

    // Drain using only per-tag ordering expectations.
    while (model_q.size() > 0) begin
      tag_value = model_q[0].tag;
      do_pop(tag_value, 1'b1);
    end
  endtask

  // ---------------------------------------------------------------------------
  // Main sequence
  // ---------------------------------------------------------------------------
  initial begin : main_sequence
    push_tag   = '0;
    push_data  = '0;
    push_req   = 1'b0;
    match_data = '0;
    match_mask = '0;
    match_req  = '0;
    pop_tag    = '0;
    pop_en     = 1'b0;
    pop_req    = 1'b0;

    model_q.delete();
    reset_and_clear();

    // Empty-store search and absent-tag inspection/removal.
    do_search(32'h0000_0000, 32'h0000_0000);
    do_search(32'hFFFF_FFFF, 32'hFFFF_FFFF);
    do_pop(tag_t'(0), 1'b0);
    do_pop(tag_t'(0), 1'b1);

    run_directed();

    // R15: reset a non-empty store, then confirm searches and pops see it empty.
    do_push(tag_t'(1), 32'h5555_0000);
    do_push(tag_t'(1), 32'h5555_0001);
    do_push(tag_t'(2), 32'h6666_0000);
    reset_and_clear();
    do_search(32'h0000_0000, 32'h0000_0000);
    do_pop(tag_t'(1), 1'b1);

    run_random(320);

    do_search(32'h0000_0000, 32'h0000_0000);
    do_pop(tag_t'(7), 1'b1);
    check_status("end of test");

    $display("RESULT: PASS");
    $finish;
  end

endmodule
