module tag_tracker_tb;

  timeunit 1ns;
  timeprecision 1ps;

  localparam int TAG_W  = 3;
  localparam int SLOTS  = 8;
  localparam int N_MATCH = 1;
  localparam int N_TAGS = (1 << TAG_W);

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

  // --------------------------------------------------------------------------
  // DUT
  // --------------------------------------------------------------------------

  tag_tracker #(
    .TAG_W        (TAG_W),
    .SLOTS        (SLOTS),
    .FULL_RATE    (1'b0),
    .CUT_POP_PATH (1'b0),
    .N_MATCH      (N_MATCH),
    .payload_t    (payload_t)
  ) dut (
    .clk_i              (clk_i),
    .rst_ni             (rst_ni),

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

  // The only # delay in the testbench.
  initial clk_i = 1'b0;
  always #5 clk_i = ~clk_i;

  // --------------------------------------------------------------------------
  // Reference model
  //
  // There is one FIFO queue per tag.  No ordering relationship is modeled
  // between different tags, per R3.
  // --------------------------------------------------------------------------

  payload_t model_q [0:N_TAGS-1][$];
  int model_count;
  int errors;

  task automatic record_failure(
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
      for (int t = 0; t < N_TAGS; t++)
        model_q[t].delete();
      model_count = 0;
    end
  endtask

  function automatic bit model_has_match(
    input payload_t data,
    input payload_t mask
  );
    bit result;
    begin
      result = 1'b0;

      for (int t = 0; t < N_TAGS; t++) begin
        for (int j = 0; j < model_q[t].size(); j++) begin
          if ( (model_q[t][j] & mask) == (data & mask) )
            result = 1'b1;
        end
      end

      return result;
    end
  endfunction

  // R14: status outputs must exactly reflect occupancy.
  task automatic check_status;
    logic expected_empty;
    logic expected_full;
    begin
      expected_empty = (model_count == 0);
      expected_full  = (model_count == SLOTS);

      if (empty_o !== expected_empty) begin
        record_failure(
          "R14",
          $sformatf("empty_o=%b with modeled occupancy %0d",
                    empty_o, model_count)
        );
      end

      if (full_o !== expected_full) begin
        record_failure(
          "R14",
          $sformatf("full_o=%b with modeled occupancy %0d",
                    full_o, model_count)
        );
      end
    end
  endtask

  // --------------------------------------------------------------------------
  // Reset
  // --------------------------------------------------------------------------

  task automatic reset_dut;
    begin
      // Change stimulus away from an active clock edge.
      @(negedge clk_i);

      rst_ni       = 1'b0;
      push_req_i   = 1'b0;
      pop_req_i    = 1'b0;
      match_req_i  = '0;
      pop_en_i     = 1'b0;

      clear_model();

      // Permit synchronous reset implementations.
      repeat (2)
        @(posedge clk_i);

      @(negedge clk_i);

      // R15: while reset is asserted the store is empty.
      if (empty_o !== 1'b1)
        record_failure("R15", "empty_o is not high during reset");

      if (full_o !== 1'b0)
        record_failure("R15", "full_o is not low during reset");

      rst_ni = 1'b1;

      // Observe the first complete post-reset cycle.
      @(posedge clk_i);
      @(negedge clk_i);

      // R15: after reset release, empty high and full low.
      if (empty_o !== 1'b1)
        record_failure("R15", "empty_o is not high after reset");

      if (full_o !== 1'b0)
        record_failure("R15", "full_o is not low after reset");

      check_status();
    end
  endtask

  // --------------------------------------------------------------------------
  // Push helper
  //
  // R4: model insertion happens only on push_req_i && push_gnt_o.
  //
  // No grant-latency limit is imposed: R6 explicitly permits grant to be
  // withheld for reasons other than fullness and latency is out of scope.
  // --------------------------------------------------------------------------

  task automatic push_one(
    input tag_t     tag,
    input payload_t data
  );
    int ti;
    bit bad_grant_reported;
    bit accepted;
    begin
      ti = tag;
      bad_grant_reported = 1'b0;
      accepted = 1'b0;

      @(negedge clk_i);
      push_tag_i  = tag;
      push_data_i = data;
      push_req_i  = 1'b1;

      while (!accepted) begin
        // A synchronous transfer is determined from values presented at
        // the active edge.
        @(posedge clk_i);

        if (push_gnt_o === 1'b1) begin
          accepted = 1'b1;
        end
        else if ((push_gnt_o !== 1'b0) && !bad_grant_reported) begin
          record_failure(
            "R4",
            "push_gnt_o is X/Z while a push request is pending"
          );
          bad_grant_reported = 1'b1;
        end
      end

      // Do not change the request on the same active edge at which it was
      // sampled.  Update the reference model for that completed transfer.
      @(negedge clk_i);
      push_req_i = 1'b0;

      model_q[ti].push_back(data);
      model_count++;

      if (model_count > SLOTS) begin
        record_failure(
          "R1",
          $sformatf("modeled accepted occupancy exceeded SLOTS (%0d > %0d)",
                    model_count, SLOTS)
        );
      end

      check_status();
    end
  endtask

  // R5: grant must be low whenever the store holds SLOTS entries.
  task automatic check_push_denied_when_full;
    begin
      check_status();

      if (model_count != SLOTS) begin
        record_failure(
          "R1",
          "internal test error: full-store check attempted before SLOTS pushes"
        );
      end

      // R5 is unconditional: check grant with no request as well.
      if (push_gnt_o !== 1'b0) begin
        record_failure(
          "R5",
          "push_gnt_o is not low while the store is full"
        );
      end

      @(negedge clk_i);
      push_tag_i  = 3'd7;
      push_data_i = 32'hDEAD_BEEF;
      push_req_i  = 1'b1;

      // Keep the store full; no competing pop is issued.
      repeat (3) begin
        @(posedge clk_i);

        if (push_gnt_o !== 1'b0) begin
          record_failure(
            "R5",
            "push_gnt_o asserted while occupancy equals SLOTS"
          );
        end
      end

      @(negedge clk_i);
      push_req_i = 1'b0;
    end
  endtask

  // --------------------------------------------------------------------------
  // Pop helper
  //
  // R7: result is examined only on pop_req_i && pop_gnt_o.
  // R8: validity and oldest same-tag payload are checked.
  // R9: model is removed from only when pop_en_i is high.
  // R10: data is deliberately ignored if validity is low.
  // --------------------------------------------------------------------------

  task automatic pop_one(
    input tag_t tag,
    input bit   remove_entry,
    input bit   attribute_retention_to_r9
  );
    int ti;
    bit expected_valid;
    payload_t expected_data;
    bit bad_grant_reported;
    bit completed;
    begin
      ti = tag;
      expected_valid = (model_q[ti].size() != 0);
      expected_data  = '0;

      if (expected_valid)
        expected_data = model_q[ti][0];

      bad_grant_reported = 1'b0;
      completed = 1'b0;

      @(negedge clk_i);
      pop_tag_i = tag;
      pop_en_i  = remove_entry;
      pop_req_i = 1'b1;

      while (!completed) begin
        @(posedge clk_i);

        if (pop_gnt_o === 1'b1) begin
          completed = 1'b1;

          if (expected_valid) begin
            // R8: a present tag must report valid.
            if (pop_data_valid_o !== 1'b1) begin
              if (attribute_retention_to_r9) begin
                record_failure(
                  "R9",
                  "an inspected entry was no longer present on a later pop"
                );
              end
              else begin
                record_failure(
                  "R8",
                  $sformatf("pop of tag %0d returned valid=%b but entry exists",
                            ti, pop_data_valid_o)
                );
              end
            end
            else begin
              // R2/R8: only compare data when valid is required to be high.
              if (pop_data_o !== expected_data) begin
                if (attribute_retention_to_r9) begin
                  record_failure(
                    "R9",
                    $sformatf(
                      "inspect changed stored entry: expected %08x, got %08x",
                      expected_data, pop_data_o
                    )
                  );
                end
                else begin
                  record_failure(
                    "R2",
                    $sformatf(
                      "tag %0d FIFO violation: expected oldest %08x, got %08x",
                      ti, expected_data, pop_data_o
                    )
                  );
                end
              end
            end
          end
          else begin
            // R10: empty-tag pop completes invalid. pop_data_o is not checked.
            if (pop_data_valid_o !== 1'b0) begin
              record_failure(
                "R10",
                $sformatf(
                  "pop of absent tag %0d returned pop_data_valid_o=%b",
                  ti, pop_data_valid_o
                )
              );
            end
          end
        end
        else if ((pop_gnt_o !== 1'b0) && !bad_grant_reported) begin
          record_failure(
            "R7",
            "pop_gnt_o is X/Z while a pop request is pending"
          );
          bad_grant_reported = 1'b1;
        end
      end

      @(negedge clk_i);
      pop_req_i = 1'b0;
      pop_en_i  = 1'b0;

      // R9: only an enabled, valid completing pop removes an entry.
      if (remove_entry && expected_valid) begin
        void'(model_q[ti].pop_front());
        model_count--;
      end

      check_status();
    end
  endtask

  // --------------------------------------------------------------------------
  // Search helper
  //
  // R11: evaluate only a requested-and-granted search.
  // R12: exact masked existence predicate.
  // R13: zero-mask/nonempty special case.
  // --------------------------------------------------------------------------

  task automatic search_one(
    input payload_t data,
    input payload_t mask,
    input string    requirement
  );
    bit expected_hit;
    bit completed;
    bit bad_grant_reported;
    begin
      expected_hit = model_has_match(data, mask);
      completed = 1'b0;
      bad_grant_reported = 1'b0;

      @(negedge clk_i);
      match_data_i[0] = data;
      match_mask_i[0] = mask;
      match_req_i[0]  = 1'b1;

      while (!completed) begin
        @(posedge clk_i);

        if (match_gnt_o[0] === 1'b1) begin
          completed = 1'b1;

          if (match_hit_o[0] !== expected_hit) begin
            record_failure(
              requirement,
              $sformatf(
                "search data=%08x mask=%08x expected hit=%0b, got %b",
                data, mask, expected_hit, match_hit_o[0]
              )
            );
          end
        end
        else if ((match_gnt_o[0] !== 1'b0) && !bad_grant_reported) begin
          record_failure(
            "R11",
            "match_gnt_o[0] is X/Z while a search request is pending"
          );
          bad_grant_reported = 1'b1;
        end
      end

      @(negedge clk_i);
      match_req_i[0] = 1'b0;
    end
  endtask

  // --------------------------------------------------------------------------
  // Main test
  // --------------------------------------------------------------------------

  initial begin
    errors = 0;
    model_count = 0;

    rst_ni = 1'b0;

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

    // ========================================================================
    // R15 / R14: reset and initial status
    // ========================================================================

    reset_dut();

    // ========================================================================
    // R4: values on the push payload/tag wires without push_req_i must not
    //     create an entry.
    // ========================================================================

    @(negedge clk_i);
    push_tag_i  = 3'd6;
    push_data_i = 32'hCAFE_BABE;
    push_req_i  = 1'b0;

    repeat (2)
      @(posedge clk_i);

    @(negedge clk_i);

    if (empty_o !== 1'b1) begin
      record_failure(
        "R4",
        "store changed even though no push request was asserted"
      );
    end

    check_status();

    // R12: the unrequested value must not have appeared in storage.
    search_one(32'hCAFE_BABE, 32'hFFFF_FFFF, "R12");

    // R10: popping an absent tag must complete invalid.
    pop_one(3'd7, 1'b1, 1'b0);

    // R12: zero-mask search of an empty store is still a miss because there is
    // no stored entry satisfying the existential predicate.
    search_one(32'hFFFF_FFFF, 32'h0000_0000, "R12");

    // ========================================================================
    // R1 / R2 / R5 / R8 / R14
    //
    // Fill all SLOTS with the SAME tag.  This specifically checks R1's
    // requirement that capacity is shared rather than partitioned per tag.
    // Then drain it and verify same-tag FIFO order.
    // ========================================================================

    push_one(3'd3, 32'hA500_0000);
    push_one(3'd3, 32'hA500_0001);
    push_one(3'd3, 32'hA500_0002);
    push_one(3'd3, 32'hA500_0003);
    push_one(3'd3, 32'hA500_0004);
    push_one(3'd3, 32'hA500_0005);
    push_one(3'd3, 32'hA500_0006);
    push_one(3'd3, 32'hA500_0007);

    // R1/R14: eight accepted entries must produce the full state.
    if (model_count != SLOTS)
      record_failure("R1", "failed to model SLOTS accepted same-tag entries");

    check_status();

    // R5: no further push may be granted while full.
    check_push_denied_when_full();

    // R2/R8: remove in insertion order for tag 3.
    pop_one(3'd3, 1'b1, 1'b0);
    pop_one(3'd3, 1'b1, 1'b0);
    pop_one(3'd3, 1'b1, 1'b0);
    pop_one(3'd3, 1'b1, 1'b0);
    pop_one(3'd3, 1'b1, 1'b0);
    pop_one(3'd3, 1'b1, 1'b0);
    pop_one(3'd3, 1'b1, 1'b0);
    pop_one(3'd3, 1'b1, 1'b0);

    check_status();

    // ========================================================================
    // R9: inspect must not remove.
    //
    // Use a one-entry store so an erroneous removal is also immediately
    // observable through empty_o.
    // ========================================================================

    reset_dut();

    push_one(3'd4, 32'h4455_6677);

    // First inspection: ordinary R8 result, but reference queue is retained.
    pop_one(3'd4, 1'b0, 1'b0);

    // R9: after an inspection, the sole entry must still exist.
    if (empty_o !== 1'b0) begin
      record_failure(
        "R9",
        "store became empty after pop_en_i=0 inspection"
      );
    end

    // A second inspection must see the exact same entry.  Attribute a missing
    // or changed result specifically to R9.
    pop_one(3'd4, 1'b0, 1'b1);

    // Finally remove it; this also proves that it remained available.
    pop_one(3'd4, 1'b1, 1'b1);

    if (empty_o !== 1'b1)
      record_failure("R9", "inspected entry was not correctly retained/removable");

    // ========================================================================
    // R11 / R12 / R13 plus further R2/R8/R10
    // ========================================================================

    reset_dut();

    push_one(3'd1, 32'h1234_5678);
    push_one(3'd2, 32'h89AB_CDEF);
    push_one(3'd1, 32'h1234_AA78);
    push_one(3'd5, 32'h0F0F_0F0F);

    // Exact hit.
    search_one(32'h89AB_CDEF, 32'hFFFF_FFFF, "R12");

    // Exact miss.
    search_one(32'h89AB_CDEE, 32'hFFFF_FFFF, "R12");

    // Masked hit: both tag-1 values become 1234_0078 under this mask.
    search_one(32'h1234_0078, 32'hFFFF_00FF, "R12");

    // Masked miss.
    search_one(32'h1235_0078, 32'hFFFF_00FF, "R12");

    // Match is global across tags.
    search_one(32'h0F0F_0F0F, 32'hFFFF_FFFF, "R12");

    // R13: all-zero mask must hit whenever any entry exists.
    search_one(32'hDEAD_BEEF, 32'h0000_0000, "R13");

    // R10: absent tag is invalid even though other tags contain entries.
    pop_one(3'd6, 1'b1, 1'b0);

    // R2: the two tag-1 entries must come out in tag-1 insertion order.
    pop_one(3'd1, 1'b1, 1'b0);
    pop_one(3'd1, 1'b1, 1'b0);

    // R12: once both tag-1 entries are removed, their payload is no longer
    // searchable.
    search_one(32'h1234_5678, 32'hFFFF_FFFF, "R12");

    // ========================================================================
    // R1: shared capacity with a mixed tag distribution.
    //
    // No cross-tag removal ordering is assumed or checked.
    // ========================================================================

    reset_dut();

    push_one(3'd0, 32'h1000_0000);
    push_one(3'd1, 32'h2000_0000);
    push_one(3'd0, 32'h1000_0001);
    push_one(3'd2, 32'h3000_0000);
    push_one(3'd3, 32'h4000_0000);
    push_one(3'd2, 32'h3000_0001);
    push_one(3'd7, 32'h8000_0000);
    push_one(3'd4, 32'h5000_0000);

    if (model_count != SLOTS) begin
      record_failure(
        "R1",
        $sformatf("mixed-tag store accepted only %0d modeled entries", model_count)
      );
    end

    check_status();
    check_push_denied_when_full();

    // Verify FIFO order independently within two tags.  We deliberately make
    // no statement about relative ordering between tag 0 and tag 2.
    pop_one(3'd2, 1'b1, 1'b0);
    pop_one(3'd2, 1'b1, 1'b0);
    pop_one(3'd0, 1'b1, 1'b0);
    pop_one(3'd0, 1'b1, 1'b0);

    // ========================================================================
    // R15: assert reset while entries are still present.
    // ========================================================================

    reset_dut();

    // R15/R10: a tag populated before reset must now be absent.
    pop_one(3'd1, 1'b1, 1'b0);

    check_status();

    // ------------------------------------------------------------------------
    // Exactly one final result line.
    // ------------------------------------------------------------------------

    if (errors == 0)
      $display("RESULT: PASS");
    else
      $display("RESULT: FAIL");

    $finish;
  end

endmodule