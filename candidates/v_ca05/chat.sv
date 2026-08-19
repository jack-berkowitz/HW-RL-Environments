module tag_tracker_tb;

  // ---------------------------------------------------------------------------
  // Configuration
  // ---------------------------------------------------------------------------
  localparam int TAG_W       = 3;
  localparam int SLOTS       = 8;
  localparam int N_MATCH     = 1;
  localparam int N_TAGS      = (1 << TAG_W);
  localparam int OP_TIMEOUT  = 20_000;

  typedef logic [31:0] payload_t;
  typedef logic [TAG_W-1:0] tag_t;

  // ---------------------------------------------------------------------------
  // DUT signals
  // ---------------------------------------------------------------------------
  tag_t      push_tag_i;
  payload_t  push_data_i;
  logic      push_req_i;
  logic      push_gnt_o;

  payload_t [N_MATCH-1:0] match_data_i;
  payload_t [N_MATCH-1:0] match_mask_i;
  logic     [N_MATCH-1:0] match_req_i;
  logic     [N_MATCH-1:0] match_hit_o;
  logic     [N_MATCH-1:0] match_gnt_o;

  tag_t      pop_tag_i;
  logic      pop_en_i;
  logic      pop_req_i;
  payload_t  pop_data_o;
  logic      pop_data_valid_o;
  logic      pop_gnt_o;

  logic      full_o;
  logic      empty_o;

  // ---------------------------------------------------------------------------
  // PROVIDED PLUMBING -- clock, reset and watchdog only.
  // ---------------------------------------------------------------------------
  // NO TRANSACTOR IS PROVIDED FOR THE REQUEST/GRANT PORTS. Driving them, and
  // deciding when a request has completed, is part of the task.
  //
  // What is provided is the timing discipline, because getting it wrong is
  // silent: reset is asserted and released away from the sampling edge, and the
  // helper below moves you to the point in the cycle where it is safe to change
  // stimulus.
  // ---------------------------------------------------------------------------

  // ---- clock ----------------------------------------------------------------
  logic clk;
  initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
  end

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
  task automatic bfm_drive_point();
    @(negedge clk);
  endtask

  task automatic bfm_tick();
    @(posedge clk);
  endtask

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
    .clk_i              (clk),
    .rst_ni             (rst_n),

    .push_tag_i         (push_tag_i),
    .push_data_i        (push_data_i),
    .push_req_i         (push_req_i),
    .push_gnt_o         (push_gnt_o),

    .match_data_i       (match_data_i),
    .match_mask_i       (match_mask_i),
    .match_req_i        (match_req_i),
    .match_hit_o        (match_hit_o),
    .match_gnt_o        (match_gnt_o),

    .pop_tag_i          (pop_tag_i),
    .pop_en_i           (pop_en_i),
    .pop_req_i          (pop_req_i),
    .pop_data_o         (pop_data_o),
    .pop_data_valid_o   (pop_data_valid_o),
    .pop_gnt_o          (pop_gnt_o),

    .full_o             (full_o),
    .empty_o            (empty_o)
  );

  // ---------------------------------------------------------------------------
  // Edge samples
  //
  // Requests are driven on a negedge.  On each following posedge these
  // registers capture the values belonging to the transaction that can
  // complete at that edge.  The BFM examines the samples at the next negedge.
  //
  // This is important for a removing pop: pop_data_o might change immediately
  // after the posedge because the head entry has just been removed.  Sampling
  // it here preserves the value associated with the completing transaction.
  // ---------------------------------------------------------------------------
  logic                 samp_push_gnt;
  logic [N_MATCH-1:0]   samp_match_gnt;
  logic [N_MATCH-1:0]   samp_match_hit;
  logic                 samp_pop_gnt;
  logic                 samp_pop_valid;
  payload_t             samp_pop_data;

  always @(posedge clk) begin
    samp_push_gnt   <= push_gnt_o;
    samp_match_gnt  <= match_gnt_o;
    samp_match_hit  <= match_hit_o;
    samp_pop_gnt    <= pop_gnt_o;
    samp_pop_valid  <= pop_data_valid_o;
    samp_pop_data   <= pop_data_o;
  end

  // ---------------------------------------------------------------------------
  // Reference model
  //
  // Static per-tag FIFOs are sufficient because total legal occupancy is at
  // most SLOTS.  There is intentionally no global ordering model: R3 says
  // ordering between different tags is unspecified.
  // ---------------------------------------------------------------------------
  payload_t ref_fifo [0:N_TAGS-1][0:SLOTS-1];
  int       ref_count[0:N_TAGS-1];
  int       ref_total;

  int failures;

  task automatic note_fail(
    input string requirement,
    input string message
  );
    begin
      failures = failures + 1;
      $display("FAIL %s: %s", requirement, message);
    end
  endtask

  task automatic ref_clear();
    integer t;
    integer s;
    begin
      ref_total = 0;

      for (t = 0; t < N_TAGS; t = t + 1) begin
        ref_count[t] = 0;

        for (s = 0; s < SLOTS; s = s + 1) begin
          ref_fifo[t][s] = '0;
        end
      end
    end
  endtask

  task automatic ref_push(
    input tag_t     tag,
    input payload_t data
  );
    integer idx;
    begin
      idx = int'(tag);

      if ((ref_total < SLOTS) && (ref_count[idx] < SLOTS)) begin
        ref_fifo[idx][ref_count[idx]] = data;
        ref_count[idx] = ref_count[idx] + 1;
        ref_total = ref_total + 1;
      end
    end
  endtask

  task automatic ref_remove_head(
    input tag_t tag
  );
    integer idx;
    integer j;
    begin
      idx = int'(tag);

      if (ref_count[idx] > 0) begin
        for (j = 0; j < ref_count[idx]-1; j = j + 1) begin
          ref_fifo[idx][j] = ref_fifo[idx][j+1];
        end

        ref_fifo[idx][ref_count[idx]-1] = '0;
        ref_count[idx] = ref_count[idx] - 1;
        ref_total = ref_total - 1;
      end
    end
  endtask

  function automatic logic ref_search(
    input payload_t data,
    input payload_t mask
  );
    integer t;
    integer j;
    begin
      ref_search = 1'b0;

      for (t = 0; t < N_TAGS; t = t + 1) begin
        for (j = 0; j < ref_count[t]; j = j + 1) begin
          if ((ref_fifo[t][j] & mask) == (data & mask)) begin
            ref_search = 1'b1;
          end
        end
      end
    end
  endfunction

  // ---------------------------------------------------------------------------
  // R14 -- occupancy status is exact.
  // Called only at safe negedge observation points after state/model updates.
  // ---------------------------------------------------------------------------
  task automatic check_status();
    logic exp_empty;
    logic exp_full;
    begin
      exp_empty = (ref_total == 0);
      exp_full  = (ref_total == SLOTS);

      if (empty_o !== exp_empty) begin
        note_fail(
          "R14",
          $sformatf(
            "empty_o=%0b, expected %0b at occupancy %0d",
            empty_o, exp_empty, ref_total
          )
        );
      end

      if (full_o !== exp_full) begin
        note_fail(
          "R14",
          $sformatf(
            "full_o=%0b, expected %0b at occupancy %0d",
            full_o, exp_full, ref_total
          )
        );
      end
    end
  endtask

  // ---------------------------------------------------------------------------
  // Reset helper.
  // ---------------------------------------------------------------------------
  task automatic reset_to_empty();
    begin
      bfm_reset(4);
      ref_clear();

      if (empty_o !== 1'b1) begin
        note_fail("R15", "empty_o was not high after reset release");
      end

      if (full_o !== 1'b0) begin
        note_fail("R15", "full_o was not low after reset release");
      end

      check_status();
    end
  endtask

  // ---------------------------------------------------------------------------
  // Push BFM.
  //
  // R4: the model changes only on req && gnt.
  // R6: no immediate-grant assumption is made.
  // The large timeout is solely a finite-run safeguard.
  // ---------------------------------------------------------------------------
  task automatic do_push(
    input tag_t     tag,
    input payload_t data,
    input string    timeout_requirement
  );
    integer i;
    logic done;
    begin
      done = 1'b0;

      bfm_drive_point();
      push_tag_i  = tag;
      push_data_i = data;
      push_req_i  = 1'b1;

      for (i = 0; (i < OP_TIMEOUT) && !done; i = i + 1) begin
        bfm_tick();
        bfm_drive_point();

        if (samp_push_gnt === 1'b1) begin
          if (ref_total >= SLOTS) begin
            note_fail(
              "R5",
              "push completed while the reference store was full"
            );
          end
          else begin
            // R4 -- commit precisely on the completing push.
            ref_push(tag, data);
          end

          done = 1'b1;
        end

        check_status();
      end

      push_req_i = 1'b0;

      if (!done) begin
        note_fail(
          timeout_requirement,
          $sformatf(
            "push tag %0d did not complete within the finite test timeout",
            tag
          )
        );
      end
    end
  endtask

  // ---------------------------------------------------------------------------
  // Pop BFM.
  //
  // result_requirement lets directed tests attribute the semantic check to
  // R8, R9, R10, R2, or R15 as appropriate.
  //
  // pop_data_o is deliberately NOT examined if expected validity is false
  // (R10).
  // ---------------------------------------------------------------------------
  task automatic do_pop(
    input tag_t  tag,
    input logic  remove_entry,
    input string result_requirement
  );
    integer i;
    integer idx;
    logic done;
    logic exp_valid;
    payload_t exp_data;
    begin
      idx = int'(tag);

      exp_valid = (ref_count[idx] > 0);
      exp_data  = '0;

      if (exp_valid) begin
        exp_data = ref_fifo[idx][0];
      end

      done = 1'b0;

      bfm_drive_point();
      pop_tag_i = tag;
      pop_en_i  = remove_entry;
      pop_req_i = 1'b1;

      for (i = 0; (i < OP_TIMEOUT) && !done; i = i + 1) begin
        bfm_tick();
        bfm_drive_point();

        if (samp_pop_gnt === 1'b1) begin
          if (samp_pop_valid !== exp_valid) begin
            note_fail(
              result_requirement,
              $sformatf(
                "pop tag %0d valid=%0b, expected %0b",
                tag, samp_pop_valid, exp_valid
              )
            );
          end
          else if (exp_valid) begin
            if (samp_pop_data !== exp_data) begin
              note_fail(
                result_requirement,
                $sformatf(
                  "pop tag %0d data=%08x, expected oldest=%08x",
                  tag, samp_pop_data, exp_data
                )
              );
            end
          end

          // Model the state required by the specification, even if a faulty
          // DUT returned an incorrect valid bit.
          if (remove_entry && exp_valid) begin
            ref_remove_head(tag);
          end

          done = 1'b1;
        end

        check_status();
      end

      pop_req_i = 1'b0;
      pop_en_i  = 1'b0;

      if (!done) begin
        if (!exp_valid) begin
          // R10 explicitly requires an empty-tag pop to complete.
          note_fail(
            "R10",
            $sformatf(
              "pop of empty tag %0d did not complete within the finite test timeout",
              tag
            )
          );
        end
        else begin
          note_fail(
            "R7",
            $sformatf(
              "pop tag %0d did not complete within the finite test timeout",
              tag
            )
          );
        end
      end
    end
  endtask

  // ---------------------------------------------------------------------------
  // Search BFM.
  //
  // No mutations occur concurrently, so the expected result is stable for the
  // entire request regardless of how long arbitration delays the grant.
  // ---------------------------------------------------------------------------
  task automatic do_search(
    input payload_t data,
    input payload_t mask,
    input string    result_requirement
  );
    integer i;
    logic done;
    logic exp_hit;
    begin
      exp_hit = ref_search(data, mask);
      done = 1'b0;

      bfm_drive_point();
      match_data_i[0] = data;
      match_mask_i[0] = mask;
      match_req_i[0]  = 1'b1;

      for (i = 0; (i < OP_TIMEOUT) && !done; i = i + 1) begin
        bfm_tick();
        bfm_drive_point();

        if (samp_match_gnt[0] === 1'b1) begin
          if (samp_match_hit[0] !== exp_hit) begin
            note_fail(
              result_requirement,
              $sformatf(
                "search data=%08x mask=%08x hit=%0b, expected %0b",
                data, mask, samp_match_hit[0], exp_hit
              )
            );
          end

          done = 1'b1;
        end

        check_status();
      end

      match_req_i[0] = 1'b0;

      if (!done) begin
        note_fail(
          "R11",
          $sformatf(
            "search data=%08x mask=%08x did not complete within the finite test timeout",
            data, mask
          )
        );
      end
    end
  endtask

  // ---------------------------------------------------------------------------
  // R5 -- when occupancy is exactly SLOTS, push_gnt_o must stay low.
  //
  // No pop is present, so occupancy remains full throughout this test.
  // ---------------------------------------------------------------------------
  task automatic check_push_blocked_when_full(
    input tag_t     tag,
    input payload_t data
  );
    integer i;
    begin
      if (ref_total == SLOTS) begin
        bfm_drive_point();
        push_tag_i  = tag;
        push_data_i = data;
        push_req_i  = 1'b1;

        for (i = 0; i < 4; i = i + 1) begin
          bfm_tick();
          bfm_drive_point();

          if (samp_push_gnt !== 1'b0) begin
            note_fail(
              "R5",
              $sformatf(
                "push_gnt_o asserted while occupancy was SLOTS=%0d",
                SLOTS
              )
            );
          end

          check_status();
        end

        push_req_i = 1'b0;
      end
    end
  endtask

  // ---------------------------------------------------------------------------
  // R15 -- assert reset while entries are actually present and check that the
  // store is empty while reset remains asserted and after release.
  // ---------------------------------------------------------------------------
  task automatic reset_while_nonempty();
    integer i;
    begin
      bfm_drive_point();
      rst_n = 1'b0;

      // R15 defines the required architectural state under reset.
      ref_clear();

      for (i = 0; i < 3; i = i + 1) begin
        bfm_tick();
        bfm_drive_point();

        if (empty_o !== 1'b1) begin
          note_fail(
            "R15",
            "empty_o was not high while rst_ni was asserted low"
          );
        end

        if (full_o !== 1'b0) begin
          note_fail(
            "R15",
            "full_o was not low while rst_ni was asserted low"
          );
        end
      end

      // We are at a negedge, so release is away from the sampling edge.
      rst_n = 1'b1;

      bfm_tick();
      bfm_drive_point();

      if (empty_o !== 1'b1) begin
        note_fail(
          "R15",
          "empty_o was not high after reset release"
        );
      end

      if (full_o !== 1'b0) begin
        note_fail(
          "R15",
          "full_o was not low after reset release"
        );
      end

      check_status();
    end
  endtask

  // ---------------------------------------------------------------------------
  // Independent watchdog.
  //
  // The diagnostic does not impose an ordinary transaction-latency check; it
  // guarantees unconditional simulation termination even if something outside
  // the normal BFMs prevents forward progress.
  // ---------------------------------------------------------------------------
  initial begin
    #20_000_000;
    $display(
      "FAIL R1/R7/R11: watchdog expired before the testbench completed"
    );
    $display("RESULT: FAIL");
    $finish;
  end

  // ---------------------------------------------------------------------------
  // Main test
  // ---------------------------------------------------------------------------
  initial begin

    failures = 0;

    push_tag_i  = '0;
    push_data_i = '0;
    push_req_i  = 1'b0;

    match_data_i = '0;
    match_mask_i = '0;
    match_req_i  = '0;

    pop_tag_i = '0;
    pop_en_i  = 1'b0;
    pop_req_i = 1'b0;

    ref_clear();

    // =======================================================================
    // R15 / R14 -- initial reset state.
    // =======================================================================
    reset_to_empty();

    // =======================================================================
    // R10 -- popping a tag with no entries is legal, completes, and returns
    // invalid.  pop_data_o is intentionally ignored in this case.
    // =======================================================================
    do_pop(
      tag_t'(3),
      1'b1,
      "R10"
    );

    // =======================================================================
    // R12/R13 -- searches of an empty store.
    // An all-zero mask must NOT hit because no entry exists.
    // =======================================================================
    do_search(
      32'h1234_5678,
      32'h0000_0000,
      "R13"
    );

    do_search(
      32'h1234_5678,
      32'hffff_ffff,
      "R12"
    );

    // =======================================================================
    // R8/R9 -- inspect without removal, then removal.
    //
    // The second pop proves pop_en=0 did not remove the item.
    // The third pop proves pop_en=1 did remove it.
    // =======================================================================
    reset_to_empty();

    do_push(
      tag_t'(2),
      32'hcafe_1234,
      "R4"
    );

    if (ref_count[2] == 1) begin
      do_pop(
        tag_t'(2),
        1'b0,
        "R8"
      );

      do_pop(
        tag_t'(2),
        1'b1,
        "R9"
      );

      do_pop(
        tag_t'(2),
        1'b1,
        "R9"
      );
    end

    // =======================================================================
    // R2 -- simple per-tag FIFO order.
    // =======================================================================
    reset_to_empty();

    do_push(
      tag_t'(3),
      32'h1010_0001,
      "R4"
    );

    do_push(
      tag_t'(3),
      32'h2020_0002,
      "R4"
    );

    do_push(
      tag_t'(3),
      32'h3030_0003,
      "R4"
    );

    if (ref_count[3] == 3) begin
      do_pop(
        tag_t'(3),
        1'b1,
        "R2"
      );

      do_pop(
        tag_t'(3),
        1'b1,
        "R2"
      );

      do_pop(
        tag_t'(3),
        1'b1,
        "R2"
      );
    end

    // =======================================================================
    // R1 -- all SLOTS entries may carry the SAME tag.
    // R14 -- full_o must become exact at occupancy SLOTS.
    // =======================================================================
    reset_to_empty();

    do_push(tag_t'(5), 32'ha500_0000, "R1");
    do_push(tag_t'(5), 32'ha500_0001, "R1");
    do_push(tag_t'(5), 32'ha500_0002, "R1");
    do_push(tag_t'(5), 32'ha500_0003, "R1");
    do_push(tag_t'(5), 32'ha500_0004, "R1");
    do_push(tag_t'(5), 32'ha500_0005, "R1");
    do_push(tag_t'(5), 32'ha500_0006, "R1");
    do_push(tag_t'(5), 32'ha500_0007, "R1");

    if (ref_total == SLOTS) begin

      // R5 -- no push grant is legal at full occupancy.
      check_push_blocked_when_full(
        tag_t'(6),
        32'hdead_beef
      );

      // Make one legal slot available.
      do_pop(
        tag_t'(5),
        1'b1,
        "R2"
      );

      // R4 -- the request that received no grant while full must not have
      // silently committed an entry.
      do_search(
        32'hdead_beef,
        32'hffff_ffff,
        "R4"
      );

      // Capacity becomes reusable after a removal.
      do_push(
        tag_t'(5),
        32'ha500_0008,
        "R1"
      );

      // Remaining legal FIFO sequence is 1..8.  This also stresses FIFO order
      // at the maximum same-tag occupancy.
      if (ref_count[5] == SLOTS) begin
        do_pop(tag_t'(5), 1'b1, "R2");
        do_pop(tag_t'(5), 1'b1, "R2");
        do_pop(tag_t'(5), 1'b1, "R2");
        do_pop(tag_t'(5), 1'b1, "R2");
        do_pop(tag_t'(5), 1'b1, "R2");
        do_pop(tag_t'(5), 1'b1, "R2");
        do_pop(tag_t'(5), 1'b1, "R2");
        do_pop(tag_t'(5), 1'b1, "R2");
      end
    end

    // =======================================================================
    // R12/R13 -- content-addressed search over ALL tags.
    //
    // Entries are intentionally interleaved by tag.  No cross-tag removal
    // ordering is inferred or checked (R3).
    // =======================================================================
    reset_to_empty();

    do_push(tag_t'(0), 32'h0011_0011, "R4");
    do_push(tag_t'(1), 32'h1122_0022, "R4");
    do_push(tag_t'(0), 32'h0033_0033, "R4");
    do_push(tag_t'(2), 32'h2244_0044, "R4");
    do_push(tag_t'(1), 32'h1155_0055, "R4");
    do_push(tag_t'(3), 32'h3366_0066, "R4");

    if (ref_total == 6) begin

      // Exact hit.
      do_search(
        32'h2244_0044,
        32'hffff_ffff,
        "R12"
      );

      // Exact miss.
      do_search(
        32'hdead_beef,
        32'hffff_ffff,
        "R12"
      );

      // Only the high byte matters.  Unmasked bits of match_data differ from
      // the stored payloads.
      do_search(
        32'h11ab_cdef,
        32'hff00_0000,
        "R12"
      );

      // High-byte miss.
      do_search(
        32'h77ab_cdef,
        32'hff00_0000,
        "R12"
      );

      // Low-byte masked hit.
      do_search(
        32'h0000_0055,
        32'h0000_00ff,
        "R12"
      );

      // R13 -- zero mask matches every stored entry.
      do_search(
        32'hdead_beef,
        32'h0000_0000,
        "R13"
      );

      // Per-tag FIFO checks.  The tags themselves are popped in an arbitrary
      // order; only order WITHIN an individual tag is checked.
      do_pop(tag_t'(1), 1'b1, "R2");
      do_pop(tag_t'(1), 1'b1, "R2");

      do_pop(tag_t'(0), 1'b1, "R2");
      do_pop(tag_t'(0), 1'b1, "R2");

      do_pop(tag_t'(2), 1'b1, "R8");
      do_pop(tag_t'(3), 1'b1, "R8");

      // R13 -- after the final removal, zero mask no longer hits.
      do_search(
        32'hffff_ffff,
        32'h0000_0000,
        "R13"
      );
    end

    // =======================================================================
    // R15 -- reset must discard entries that were already stored.
    // =======================================================================
    reset_to_empty();

    do_push(tag_t'(7), 32'h7000_0001, "R4");
    do_push(tag_t'(7), 32'h7000_0002, "R4");
    do_push(tag_t'(1), 32'h1000_0003, "R4");

    reset_while_nonempty();

    // Check for stale storage even if a faulty implementation lies on its
    // empty_o status.
    do_search(
      32'hffff_ffff,
      32'h0000_0000,
      "R15"
    );

    do_pop(
      tag_t'(7),
      1'b1,
      "R15"
    );

    // -----------------------------------------------------------------------
    // Final result -- exactly one RESULT line.
    // -----------------------------------------------------------------------
    if (failures == 0) begin
      $display("RESULT: PASS");
    end
    else begin
      $display("RESULT: FAIL");
    end

    $finish;
  end

endmodule