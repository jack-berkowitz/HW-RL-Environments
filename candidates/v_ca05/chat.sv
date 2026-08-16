module tag_tracker_tb;

  localparam int TAG_W  = 3;
  localparam int SLOTS  = 8;
  localparam int N_MATCH = 1;
  localparam int NUM_TAGS = (1 << TAG_W);

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

  int errors;
  int model_count;

  // One FIFO per tag.  There is deliberately no ordering model between tags.
  payload_t model_q [0:NUM_TAGS-1][$];

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

  // The only # delay in the testbench is the clock generator.
  initial begin
    clk_i = 1'b0;
    forever #5 clk_i = ~clk_i;
  end

  task automatic fail_check(
    input string requirement,
    input string message
  );
    begin
      errors++;
      $display("FAIL %s: %s", requirement, message);
    end
  endtask

  task automatic clear_model;
    begin
      for (int t = 0; t < NUM_TAGS; t++)
        model_q[t].delete();
      model_count = 0;
    end
  endtask

  // R14: status is purely a function of current occupancy.
  task automatic check_status(input string context);
    logic exp_empty;
    logic exp_full;
    begin
      exp_empty = (model_count == 0);
      exp_full  = (model_count == SLOTS);

      if (empty_o !== exp_empty) begin
        fail_check(
          "R14",
          $sformatf("%s: empty_o=%0b, expected %0b for occupancy %0d",
                    context, empty_o, exp_empty, model_count)
        );
      end

      if (full_o !== exp_full) begin
        fail_check(
          "R14",
          $sformatf("%s: full_o=%0b, expected %0b for occupancy %0d",
                    context, full_o, exp_full, model_count)
        );
      end
    end
  endtask

  function automatic logic model_match(
    input payload_t data,
    input payload_t mask
  );
    logic hit;
    begin
      hit = 1'b0;

      for (int t = 0; t < NUM_TAGS; t++) begin
        for (int j = 0; j < model_q[t].size(); j++) begin
          if ((model_q[t][j] & mask) == (data & mask))
            hit = 1'b1;
        end
      end

      model_match = hit;
    end
  endfunction

  /*
   * R1/R4:
   * Hold a push request until an actual grant occurs.  No maximum grant
   * latency is assumed because latency and arbitration are explicitly
   * unspecified.
   */
  task automatic push_one(
    input tag_t tag,
    input payload_t data
  );
    int ti;
    begin
      ti = int'(tag);

      @(negedge clk_i);
      push_tag_i  = tag;
      push_data_i = data;
      push_req_i  = 1'b1;

      forever begin
        @(posedge clk_i);

        // R4: only req && gnt commits the reference entry.
        if (push_gnt_o === 1'b1) begin
          model_q[ti].push_back(data);
          model_count++;

          @(negedge clk_i);
          push_req_i = 1'b0;

          check_status("after accepted push");
          return;
        end
      end
    end
  endtask

  /*
   * R2/R7/R8/R9/R10:
   * The expected entry is the head of the FIFO for this particular tag only.
   * pop_data_o is never inspected when the expected validity is false.
   */
  task automatic pop_one(
    input tag_t tag,
    input logic remove_entry
  );
    int ti;
    logic exp_valid;
    payload_t exp_data;
    payload_t discarded;
    begin
      ti = int'(tag);

      @(negedge clk_i);
      pop_tag_i = tag;
      pop_en_i  = remove_entry;
      pop_req_i = 1'b1;

      forever begin
        @(posedge clk_i);

        if (pop_gnt_o === 1'b1) begin
          exp_valid = (model_q[ti].size() != 0);

          if (exp_valid) begin
            // R8: a present tag must report valid.
            if (pop_data_valid_o !== 1'b1) begin
              fail_check(
                "R8",
                $sformatf("pop of tag %0d completed with data_valid=%0b, expected 1",
                          ti, pop_data_valid_o)
              );
            end

            // R2/R8: when valid, return the oldest entry for this tag.
            if (pop_data_valid_o === 1'b1) begin
              exp_data = model_q[ti][0];
              if (pop_data_o !== exp_data) begin
                fail_check(
                  "R2",
                  $sformatf("tag %0d FIFO order/data mismatch: got %08x, expected %08x",
                            ti, pop_data_o, exp_data)
                );
              end
            end
          end
          else begin
            // R10: empty-tag pop completes invalid.  Do not inspect data.
            if (pop_data_valid_o !== 1'b0) begin
              fail_check(
                "R10",
                $sformatf("pop of empty tag %0d completed with data_valid=%0b, expected 0",
                          ti, pop_data_valid_o)
              );
            end
          end

          // R9: mutate the model only for a valid removing pop.
          if (remove_entry && exp_valid) begin
            discarded = model_q[ti].pop_front();
            model_count--;
          end

          @(negedge clk_i);
          pop_req_i = 1'b0;
          pop_en_i  = 1'b0;

          check_status("after completing pop");
          return;
        end
      end
    end
  endtask

  /*
   * An isolated one-entry peek makes R9 directly observable through empty_o:
   * an inspect-only pop must leave the sole entry present.
   */
  task automatic peek_singleton(
    input tag_t tag,
    input payload_t expected_data
  );
    int ti;
    begin
      ti = int'(tag);

      @(negedge clk_i);
      pop_tag_i = tag;
      pop_en_i  = 1'b0;
      pop_req_i = 1'b1;

      forever begin
        @(posedge clk_i);

        if (pop_gnt_o === 1'b1) begin
          if (pop_data_valid_o !== 1'b1) begin
            fail_check(
              "R8",
              $sformatf("singleton peek of tag %0d was not valid", ti)
            );
          end

          if ((pop_data_valid_o === 1'b1) &&
              (pop_data_o !== expected_data)) begin
            fail_check(
              "R2",
              $sformatf("singleton peek returned %08x, expected %08x",
                        pop_data_o, expected_data)
            );
          end

          @(negedge clk_i);
          pop_req_i = 1'b0;

          // R9: with one total entry, a non-removing pop cannot make empty true.
          if (empty_o !== 1'b0) begin
            fail_check(
              "R9",
              "pop_en_i=0 removed or lost the singleton entry"
            );
          end

          check_status("after non-removing singleton pop");
          return;
        end
      end
    end
  endtask

  // R11/R12/R13.  Only inspect match_hit on an actual completion.
  task automatic search_one(
    input payload_t data,
    input payload_t mask
  );
    logic expected_hit;
    begin
      @(negedge clk_i);
      match_data_i[0] = data;
      match_mask_i[0] = mask;
      match_req_i[0]  = 1'b1;

      forever begin
        @(posedge clk_i);

        if (match_gnt_o[0] === 1'b1) begin
          expected_hit = model_match(data, mask);

          if (match_hit_o[0] !== expected_hit) begin
            if ((mask == '0) && (model_count != 0)) begin
              fail_check(
                "R13",
                $sformatf("zero-mask search in non-empty store returned hit=%0b, expected 1",
                          match_hit_o[0])
              );
            end
            else begin
              fail_check(
                "R12",
                $sformatf("search data=%08x mask=%08x returned hit=%0b, expected %0b",
                          data, mask, match_hit_o[0], expected_hit)
              );
            end
          end

          @(negedge clk_i);
          match_req_i[0] = 1'b0;

          // R11/R12: search has no removal/insertion side effect.
          check_status("after completing search");
          return;
        end
      end
    end
  endtask

  // R5: while occupancy is exactly SLOTS, push_gnt_o must be low.
  task automatic check_push_denied_when_full;
    begin
      @(negedge clk_i);
      push_tag_i  = tag_t'(7);
      push_data_i = 32'hFEED_FACE;
      push_req_i  = 1'b1;

      @(posedge clk_i);

      if (push_gnt_o !== 1'b0) begin
        fail_check(
          "R5",
          $sformatf("push_gnt_o=%0b while store holds SLOTS=%0d entries",
                    push_gnt_o, SLOTS)
        );
      end

      @(negedge clk_i);
      push_req_i = 1'b0;
      check_status("after push attempt while full");
    end
  endtask

  // R15: reset an already-used store and verify both during and after reset.
  task automatic reset_store;
    begin
      @(negedge clk_i);

      push_req_i     = 1'b0;
      pop_req_i      = 1'b0;
      pop_en_i       = 1'b0;
      match_req_i    = '0;
      rst_ni         = 1'b0;

      clear_model();

      repeat (2) @(posedge clk_i);
      @(negedge clk_i);

      if (empty_o !== 1'b1) begin
        fail_check("R15", "empty_o was not high while reset was asserted");
      end

      if (full_o !== 1'b0) begin
        fail_check("R15", "full_o was not low while reset was asserted");
      end

      rst_ni = 1'b1;

      @(posedge clk_i);
      @(negedge clk_i);

      if (empty_o !== 1'b1) begin
        fail_check("R15", "empty_o was not high after reset release");
      end

      if (full_o !== 1'b0) begin
        fail_check("R15", "full_o was not low after reset release");
      end

      check_status("after reset release");
    end
  endtask

  initial begin
    errors      = 0;
    model_count = 0;

    rst_ni      = 1'b0;

    push_tag_i  = '0;
    push_data_i = '0;
    push_req_i  = 1'b0;

    match_data_i = '0;
    match_mask_i = '0;
    match_req_i  = '0;

    pop_tag_i = '0;
    pop_en_i  = 1'b0;
    pop_req_i = 1'b0;

    clear_model();

    // ------------------------------------------------------------
    // R15: initial reset.
    // ------------------------------------------------------------
    repeat (2) @(posedge clk_i);
    @(negedge clk_i);

    if (empty_o !== 1'b1)
      fail_check("R15", "empty_o was not high during initial reset");

    if (full_o !== 1'b0)
      fail_check("R15", "full_o was not low during initial reset");

    rst_ni = 1'b1;

    @(posedge clk_i);
    @(negedge clk_i);

    if (empty_o !== 1'b1)
      fail_check("R15", "empty_o was not high after initial reset release");

    if (full_o !== 1'b0)
      fail_check("R15", "full_o was not low after initial reset release");

    check_status("initial reset complete");

    // ------------------------------------------------------------
    // R10: empty-tag pop is legal and returns invalid.
    // ------------------------------------------------------------
    pop_one(tag_t'(0), 1'b1);

    // R12: zero-mask search on an empty store must miss, because there
    // are no stored entries to satisfy the predicate.
    search_one(32'h1234_5678, 32'h0000_0000);

    // ------------------------------------------------------------
    // R1/R2/R4/R5/R14:
    // Fill all SLOTS with one tag.  This specifically exercises the
    // requirement that a single tag can consume the entire capacity.
    // ------------------------------------------------------------
    for (int i = 0; i < SLOTS; i++) begin
      push_one(tag_t'(3), payload_t'(32'hA500_0000 + i));
    end

    check_status("all-same-tag store full");
    check_push_denied_when_full();

    // Remove the same-tag entries and verify strict FIFO order.
    for (int i = 0; i < SLOTS; i++) begin
      pop_one(tag_t'(3), 1'b1);
    end

    check_status("all-same-tag FIFO drained");

    // ------------------------------------------------------------
    // R9: inspect without removal.
    // Use a singleton so removal would be directly visible.
    // ------------------------------------------------------------
    push_one(tag_t'(6), 32'h0C0F_FEE0);
    peek_singleton(tag_t'(6), 32'h0C0F_FEE0);

    // It must still be the head after the non-removing pop.
    pop_one(tag_t'(6), 1'b1);
    check_status("singleton removed after peek");

    // ------------------------------------------------------------
    // R1: shared capacity with a mixed distribution of tags.
    // Each tag's queue is modeled independently; no cross-tag ordering
    // assumption is made.
    // ------------------------------------------------------------
    push_one(tag_t'(0), 32'h1234_5678);
    push_one(tag_t'(1), 32'hDEAD_BEEF);
    push_one(tag_t'(2), 32'hCAFE_BABE);
    push_one(tag_t'(0), 32'h1234_ABCD);
    push_one(tag_t'(7), 32'h1357_9BDF);
    push_one(tag_t'(1), 32'h00FF_00FF);
    push_one(tag_t'(7), 32'h2468_ACE0);
    push_one(tag_t'(7), 32'hAAAA_5555);

    check_status("mixed-tag store full");

    // ------------------------------------------------------------
    // R12/R13: content-addressed searches across all tags.
    // ------------------------------------------------------------

    // R13: zero mask matches every stored payload.
    search_one(32'hFFFF_FFFF, 32'h0000_0000);

    // R12: exact hit.
    search_one(32'hDEAD_BEEF, 32'hFFFF_FFFF);

    // R12: exact miss.
    search_one(32'h0BAD_F00D, 32'hFFFF_FFFF);

    // R12: masked hit: both 0x1234_xxxx entries qualify.
    search_one(32'h1234_FFFF, 32'hFFFF_0000);

    // R12: masked miss.
    search_one(32'h0000_1234, 32'h0000_FFFF);

    // Searches must not change occupancy.
    check_status("after mixed-tag searches");

    // ------------------------------------------------------------
    // R2/R3/R8:
    // Drain tags in an arbitrary cross-tag order.  Within each tag,
    // the reference queue enforces FIFO.  No relationship between
    // different tags is checked.
    // ------------------------------------------------------------
    pop_one(tag_t'(7), 1'b1);
    pop_one(tag_t'(7), 1'b1);
    pop_one(tag_t'(7), 1'b1);

    pop_one(tag_t'(1), 1'b1);
    pop_one(tag_t'(1), 1'b1);

    pop_one(tag_t'(0), 1'b1);
    pop_one(tag_t'(0), 1'b1);

    pop_one(tag_t'(2), 1'b1);

    check_status("mixed-tag store drained");

    // Another absent-tag pop: R10.
    pop_one(tag_t'(5), 1'b1);

    // ------------------------------------------------------------
    // R15: reset must discard existing stored entries.
    // ------------------------------------------------------------
    push_one(tag_t'(1), 32'h1111_1111);
    push_one(tag_t'(4), 32'h4444_4444);
    push_one(tag_t'(1), 32'h1111_2222);

    reset_store();

    // Confirm that tags populated before reset are now absent.
    pop_one(tag_t'(1), 1'b1);
    pop_one(tag_t'(4), 1'b1);

    // R12: store is empty after reset, so even zero mask misses.
    search_one(32'h0000_0000, 32'h0000_0000);

    check_status("final state");

    if (errors == 0)
      $display("RESULT: PASS");
    else
      $display("RESULT: FAIL");

    $finish;
  end

endmodule