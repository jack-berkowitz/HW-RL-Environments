`timescale 1ns/1ps

module tag_tracker_tb;

  localparam int TAG_W     = 3;
  localparam int SLOTS     = 8;
  localparam int N_MATCH   = 1;
  localparam int TAG_COUNT = (1 << TAG_W);

  typedef logic [31:0] payload_t;
  typedef logic [TAG_W-1:0] tag_t;

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

  tag_tracker #(
    .TAG_W       (TAG_W),
    .SLOTS       (SLOTS),
    .FULL_RATE   (1'b0),
    .CUT_POP_PATH(1'b0),
    .N_MATCH     (N_MATCH),
    .payload_t   (payload_t)
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

  // --------------------------------------------------------------------------
  // Clock.  This is the only # delay used by the testbench.
  // --------------------------------------------------------------------------

  initial clk_i = 1'b0;
  always #5 clk_i = ~clk_i;

  // --------------------------------------------------------------------------
  // Reference model.
  //
  // Only per-tag ordering is modeled.  There is deliberately no cross-tag
  // ordering model because R3 explicitly leaves that unspecified.
  // --------------------------------------------------------------------------

  payload_t model_mem       [0:TAG_COUNT-1][0:SLOTS-1];
  integer   model_head      [0:TAG_COUNT-1];
  integer   model_tail      [0:TAG_COUNT-1];
  integer   model_tag_count [0:TAG_COUNT-1];
  integer   model_count;

  integer failures;
  logic   done;

  // Watchdog context.  Every potentially unbounded request wait supplies the
  // requirement being exercised so a wedged DUT produces a useful diagnostic.
  logic   waiting_active;
  integer waiting_rule;
  string  waiting_desc;

  task automatic fail_req(input integer rule_num, input string msg);
    begin
      failures = failures + 1;
      $display("FAIL R%0d: %s", rule_num, msg);
    end
  endtask

  task automatic set_wait_context(
    input integer rule_num,
    input string  desc
  );
    begin
      waiting_active = 1'b1;
      waiting_rule   = rule_num;
      waiting_desc   = desc;
    end
  endtask

  task automatic clear_wait_context;
    begin
      waiting_active = 1'b0;
      waiting_rule   = 15;
      waiting_desc   = "test completion";
    end
  endtask

  task automatic clear_model;
    integer t;
    begin
      model_count = 0;
      for (t = 0; t < TAG_COUNT; t = t + 1) begin
        model_head[t]      = 0;
        model_tail[t]      = 0;
        model_tag_count[t] = 0;
      end
    end
  endtask

  task automatic model_push(
    input tag_t     tag,
    input payload_t data
  );
    integer idx;
    begin
      idx = tag;
      model_mem[idx][model_tail[idx]] = data;
      model_tail[idx] =
          (model_tail[idx] + 1) % SLOTS;
      model_tag_count[idx] =
          model_tag_count[idx] + 1;
      model_count = model_count + 1;
    end
  endtask

  task automatic model_pop(input tag_t tag);
    integer idx;
    begin
      idx = tag;
      model_head[idx] =
          (model_head[idx] + 1) % SLOTS;
      model_tag_count[idx] =
          model_tag_count[idx] - 1;
      model_count = model_count - 1;
    end
  endtask

  function automatic payload_t model_front(input tag_t tag);
    integer idx;
    begin
      idx = tag;
      model_front = model_mem[idx][model_head[idx]];
    end
  endfunction

  function automatic logic model_has_match(
    input payload_t data,
    input payload_t mask
  );
    integer t;
    integer n;
    integer slot;
    begin
      model_has_match = 1'b0;

      for (t = 0; t < TAG_COUNT; t = t + 1) begin
        for (n = 0; n < model_tag_count[t]; n = n + 1) begin
          slot = (model_head[t] + n) % SLOTS;

          if ( (model_mem[t][slot] & mask) ==
               (data               & mask) ) begin
            model_has_match = 1'b1;
          end
        end
      end
    end
  endfunction

  // R14: status is checked only after a transaction has completed and the DUT
  // has had the remainder of the cycle to settle.
  task automatic check_status(input string where_s);
    logic expected_empty;
    logic expected_full;
    begin
      expected_empty = (model_count == 0);
      expected_full  = (model_count == SLOTS);

      if (empty_o !== expected_empty) begin
        fail_req(
          14,
          $sformatf(
            "%s: empty_o=%0b, expected %0b for occupancy %0d",
            where_s, empty_o, expected_empty, model_count
          )
        );
      end

      if (full_o !== expected_full) begin
        fail_req(
          14,
          $sformatf(
            "%s: full_o=%0b, expected %0b for occupancy %0d",
            where_s, full_o, expected_full, model_count
          )
        );
      end
    end
  endtask

  // --------------------------------------------------------------------------
  // Reset helper -- R15.
  // --------------------------------------------------------------------------

  task automatic reset_and_check(input string where_s);
    integer n;
    begin
      @(negedge clk_i);

      push_req_i     = 1'b0;
      pop_req_i      = 1'b0;
      pop_en_i       = 1'b0;
      match_req_i[0] = 1'b0;

      rst_ni = 1'b0;
      clear_model();

      // Give both synchronous-reset and asynchronous-reset implementations
      // several active clock edges.  No reset-output timing finer than a cycle
      // is assumed.
      for (n = 0; n < 3; n = n + 1) begin
        @(posedge clk_i);
        @(negedge clk_i);

        if (empty_o !== 1'b1) begin
          fail_req(
            15,
            $sformatf(
              "%s: empty_o must be high while reset is asserted",
              where_s
            )
          );
        end

        if (full_o !== 1'b0) begin
          fail_req(
            15,
            $sformatf(
              "%s: full_o must be low while reset is asserted",
              where_s
            )
          );
        end
      end

      rst_ni = 1'b1;

      // Check the post-reset state after a complete released-reset cycle.
      @(posedge clk_i);
      @(negedge clk_i);

      if (empty_o !== 1'b1) begin
        fail_req(
          15,
          $sformatf(
            "%s: empty_o must be high after reset release",
            where_s
          )
        );
      end

      if (full_o !== 1'b0) begin
        fail_req(
          15,
          $sformatf(
            "%s: full_o must be low after reset release",
            where_s
          )
        );
      end
    end
  endtask

  // --------------------------------------------------------------------------
  // Push helper.
  //
  // The request is held until grant because latency is unspecified.  R1 is
  // used as the watchdog requirement: while fewer than SLOTS entries are
  // present, the capacity requirement requires that the store be capable of
  // accepting the requested entries.
  // --------------------------------------------------------------------------

  task automatic push_accept(
    input tag_t     tag,
    input payload_t data,
    input string    where_s
  );
    logic granted;
    begin
      @(negedge clk_i);

      push_tag_i  = tag;
      push_data_i = data;
      push_req_i  = 1'b1;

      set_wait_context(
        1,
        $sformatf("%s: waiting for push grant", where_s)
      );

      granted = 1'b0;

      while (!granted) begin
        @(posedge clk_i);

        if (push_gnt_o === 1'b1) begin
          // R4: this handshake commits the entry in the reference model.
          model_push(tag, data);
          granted = 1'b1;
        end
      end

      @(negedge clk_i);
      push_req_i = 1'b0;
      clear_wait_context();

      check_status(where_s);
    end
  endtask

  // --------------------------------------------------------------------------
  // Pop helper.
  //
  // pop_data_o is intentionally never inspected when pop_data_valid_o is low,
  // as required by R10.
  // --------------------------------------------------------------------------

  task automatic pop_expect(
    input tag_t     tag,
    input logic     remove_en,
    input logic     expected_valid,
    input payload_t expected_data,
    input integer   grant_rule,
    input integer   valid_rule,
    input integer   data_rule,
    input string    where_s
  );
    logic granted;
    begin
      @(negedge clk_i);

      pop_tag_i = tag;
      pop_en_i  = remove_en;
      pop_req_i = 1'b1;

      set_wait_context(
        grant_rule,
        $sformatf("%s: waiting for pop grant", where_s)
      );

      granted = 1'b0;

      while (!granted) begin
        @(posedge clk_i);

        if (pop_gnt_o === 1'b1) begin
          granted = 1'b1;

          if (pop_data_valid_o !== expected_valid) begin
            fail_req(
              valid_rule,
              $sformatf(
                "%s: pop_data_valid_o=%0b, expected %0b for tag %0d",
                where_s, pop_data_valid_o, expected_valid, tag
              )
            );
          end
          else if (expected_valid) begin
            // R10 explicitly says not to perform this comparison when valid=0.
            if (pop_data_o !== expected_data) begin
              fail_req(
                data_rule,
                $sformatf(
                  "%s: pop_data_o=0x%08x, expected 0x%08x for tag %0d",
                  where_s, pop_data_o, expected_data, tag
                )
              );
            end
          end

          // The reference model follows the specified transaction, not any
          // possibly faulty indication produced by the DUT.
          if (remove_en && expected_valid) begin
            model_pop(tag);
          end
        end
      end

      @(negedge clk_i);

      pop_req_i = 1'b0;
      pop_en_i  = 1'b0;
      clear_wait_context();

      check_status(where_s);
    end
  endtask

  // --------------------------------------------------------------------------
  // Search helper -- R11/R12/R13.
  //
  // Search is performed with no concurrent store mutation, avoiding all
  // unspecified arbitration interactions.
  // --------------------------------------------------------------------------

  task automatic match_expect(
    input payload_t data,
    input payload_t mask,
    input string    where_s
  );
    logic   granted;
    logic   expected_hit;
    integer check_rule;
    begin
      expected_hit = model_has_match(data, mask);

      // R13 is the special non-empty zero-mask property.  All other hit/miss
      // comparisons are the general R12 predicate.
      if ((mask == '0) && (model_count != 0))
        check_rule = 13;
      else
        check_rule = 12;

      @(negedge clk_i);

      match_data_i[0] = data;
      match_mask_i[0] = mask;
      match_req_i[0]  = 1'b1;

      set_wait_context(
        11,
        $sformatf("%s: waiting for search grant", where_s)
      );

      granted = 1'b0;

      while (!granted) begin
        @(posedge clk_i);

        if (match_gnt_o[0] === 1'b1) begin
          granted = 1'b1;

          if (match_hit_o[0] !== expected_hit) begin
            fail_req(
              check_rule,
              $sformatf(
                "%s: match_hit_o=%0b, expected %0b, data=0x%08x mask=0x%08x",
                where_s,
                match_hit_o[0],
                expected_hit,
                data,
                mask
              )
            );
          end
        end
      end

      @(negedge clk_i);
      match_req_i[0] = 1'b0;
      clear_wait_context();

      // Search must not modify occupancy.
      check_status(where_s);
    end
  endtask

  // --------------------------------------------------------------------------
  // R5: once occupancy is SLOTS, push_gnt_o must be low.
  //
  // No pop or other request is active, so no unspecified arbitration issue is
  // involved.  If a faulty DUT grants, this scenario is followed by reset so
  // any illegal extra entry cannot contaminate later tests.
  // --------------------------------------------------------------------------

  task automatic check_push_denied_when_full;
    integer n;
    logic reported;
    begin
      @(negedge clk_i);

      push_tag_i  = 3'd7;
      push_data_i = 32'hDEAD_BEEF;
      push_req_i  = 1'b1;
      reported    = 1'b0;

      for (n = 0; n < 3; n = n + 1) begin
        @(posedge clk_i);

        if ((push_gnt_o !== 1'b0) && !reported) begin
          fail_req(
            5,
            $sformatf(
              "push_gnt_o=%0b while reference occupancy is SLOTS (%0d)",
              push_gnt_o, SLOTS
            )
          );
          reported = 1'b1;
        end
      end

      @(negedge clk_i);
      push_req_i = 1'b0;
    end
  endtask

  // --------------------------------------------------------------------------
  // Independent watchdog.
  //
  // This is intentionally cycle based, so the only # delay in the whole
  // testbench remains the clock generator.
  // --------------------------------------------------------------------------

  initial begin : watchdog
    repeat (5000) @(posedge clk_i);

    if (!done) begin
      done = 1'b1;
      failures = failures + 1;

      if (waiting_active) begin
        $display(
          "FAIL R%0d: watchdog expired: %s",
          waiting_rule, waiting_desc
        );
      end
      else begin
        $display(
          "FAIL R15: watchdog expired before the testbench completed"
        );
      end

      $display("RESULT: FAIL");
      $finish;
    end
  end

  // --------------------------------------------------------------------------
  // Test sequence.
  // --------------------------------------------------------------------------

  initial begin : main_test
    integer i;

    failures       = 0;
    done           = 1'b0;
    waiting_active = 1'b0;
    waiting_rule   = 15;
    waiting_desc   = "initialization";

    rst_ni = 1'b0;

    push_tag_i  = '0;
    push_data_i = '0;
    push_req_i  = 1'b0;

    match_data_i[0] = '0;
    match_mask_i[0] = '0;
    match_req_i[0]  = 1'b0;

    pop_tag_i = '0;
    pop_en_i  = 1'b0;
    pop_req_i = 1'b0;

    clear_model();

    // ----------------------------------------------------------------------
    // R15 -- initial reset state.
    // ----------------------------------------------------------------------
    reset_and_check("initial reset");

    // ----------------------------------------------------------------------
    // R10 -- popping an absent tag is legal and must complete with valid=0.
    // First test a completely empty store.
    // ----------------------------------------------------------------------
    pop_expect(
      3'd5,
      1'b1,
      1'b0,
      '0,
      10,
      10,
      10,
      "R10 empty-store pop"
    );

    // ----------------------------------------------------------------------
    // R1 -- all SLOTS entries must be usable by one tag.
    // R14 -- status checked after every accepted push.
    // ----------------------------------------------------------------------
    for (i = 0; i < SLOTS; i = i + 1) begin
      push_accept(
        3'd3,
        32'hA000_0000 + i,
        $sformatf("R1 same-tag capacity entry %0d", i)
      );
    end

    // R5 -- no ninth push may be granted while full.
    check_push_denied_when_full();

    // A faulty R5 implementation may have accepted the illegal request.
    reset_and_check("reset after R5 full-capacity test");

    // ----------------------------------------------------------------------
    // R1 -- shared capacity with a mixed tag distribution.
    // No cross-tag removal order is assumed or checked.
    // ----------------------------------------------------------------------
    push_accept(3'd0, 32'hB000_0000, "R1 mixed capacity 0");
    push_accept(3'd1, 32'hB000_0001, "R1 mixed capacity 1");
    push_accept(3'd0, 32'hB000_0002, "R1 mixed capacity 2");
    push_accept(3'd2, 32'hB000_0003, "R1 mixed capacity 3");
    push_accept(3'd1, 32'hB000_0004, "R1 mixed capacity 4");
    push_accept(3'd7, 32'hB000_0005, "R1 mixed capacity 5");
    push_accept(3'd7, 32'hB000_0006, "R1 mixed capacity 6");
    push_accept(3'd3, 32'hB000_0007, "R1 mixed capacity 7");

    check_status("R1 mixed-tag store full");

    reset_and_check("reset after mixed-capacity test");

    // ----------------------------------------------------------------------
    // R4 -- an accepted push is committed and is subsequently observable.
    //
    // Use an inspecting pop so this check does not mutate the entry.
    // ----------------------------------------------------------------------
    push_accept(
      3'd4,
      32'h4444_A55A,
      "R4 committed push"
    );

    pop_expect(
      3'd4,
      1'b0,
      1'b1,
      32'h4444_A55A,
      7,
      4,
      4,
      "R4 accepted push remains observable"
    );

    reset_and_check("reset after R4 commit test");

    // ----------------------------------------------------------------------
    // R2/R8 -- per-tag FIFO order.
    // ----------------------------------------------------------------------
    for (i = 0; i < 5; i = i + 1) begin
      push_accept(
        3'd6,
        32'hC000_1000 + i,
        $sformatf("R2 FIFO push %0d", i)
      );
    end

    for (i = 0; i < 5; i = i + 1) begin
      pop_expect(
        3'd6,
        1'b1,
        1'b1,
        32'hC000_1000 + i,
        7,
        8,
        2,
        $sformatf("R2 FIFO pop %0d", i)
      );
    end

    // The tag is now empty.  R10 requires a valid=0 completion.
    pop_expect(
      3'd6,
      1'b1,
      1'b0,
      '0,
      10,
      10,
      10,
      "R10 pop after FIFO drained"
    );

    // ----------------------------------------------------------------------
    // R9 -- pop_en_i=0 must inspect without removing.
    // ----------------------------------------------------------------------
    push_accept(
      3'd2,
      32'h9100_0001,
      "R9 first entry"
    );

    push_accept(
      3'd2,
      32'h9100_0002,
      "R9 second entry"
    );

    // Initial inspection returns the oldest entry under R8.
    pop_expect(
      3'd2,
      1'b0,
      1'b1,
      32'h9100_0001,
      7,
      8,
      8,
      "R9 non-removing inspection"
    );

    // Because the preceding operation had pop_en_i=0, the same oldest entry
    // must still be present.  Failure here is specifically the R9 property.
    pop_expect(
      3'd2,
      1'b1,
      1'b1,
      32'h9100_0001,
      7,
      9,
      9,
      "R9 inspected entry must not have been removed"
    );

    // The second entry must now be the oldest.
    pop_expect(
      3'd2,
      1'b1,
      1'b1,
      32'h9100_0002,
      7,
      8,
      2,
      "R2 order after R9 inspection"
    );

    reset_and_check("reset before search tests");

    // ----------------------------------------------------------------------
    // R12 -- zero-mask search of an empty store must miss because there is no
    // entry satisfying the existential match condition.
    // ----------------------------------------------------------------------
    match_expect(
      32'h0000_0000,
      32'h0000_0000,
      "R12 zero-mask search of empty store"
    );

    // Two entries under different tags demonstrate that search spans all tags.
    push_accept(
      3'd1,
      32'h1234_5678,
      "R12 search entry tag 1"
    );

    push_accept(
      3'd6,
      32'hABCD_EF00,
      "R12 search entry tag 6"
    );

    // Exact hit.
    match_expect(
      32'h1234_5678,
      32'hFFFF_FFFF,
      "R12 exact search hit"
    );

    // Exact miss.
    match_expect(
      32'h1234_5679,
      32'hFFFF_FFFF,
      "R12 exact search miss"
    );

    // Masked hit: low 16 bits are don't-care.
    match_expect(
      32'hABCD_1234,
      32'hFFFF_0000,
      "R12 masked search hit"
    );

    // Masked miss.
    match_expect(
      32'hDEAD_1234,
      32'hFFFF_0000,
      "R12 masked search miss"
    );

    // R13 -- all-zero mask must hit whenever the store is non-empty.
    match_expect(
      32'hFFFF_FFFF,
      32'h0000_0000,
      "R13 zero-mask non-empty search"
    );

    // ----------------------------------------------------------------------
    // R10 -- absent-tag pop while other tags are populated.
    // The unrelated entries must not make pop_data_valid_o true for tag 7.
    // ----------------------------------------------------------------------
    pop_expect(
      3'd7,
      1'b1,
      1'b0,
      '0,
      10,
      10,
      10,
      "R10 absent tag in non-empty store"
    );

    // ----------------------------------------------------------------------
    // R15 -- reset must discard a populated store.
    // ----------------------------------------------------------------------
    push_accept(
      3'd3,
      32'hF00D_0001,
      "entry before populated reset"
    );

    reset_and_check("R15 reset populated store");

    // Final R14 stable-empty check.
    check_status("final empty state");

    done = 1'b1;

    if (failures == 0)
      $display("RESULT: PASS");
    else
      $display("RESULT: FAIL");

    $finish;
  end

endmodule