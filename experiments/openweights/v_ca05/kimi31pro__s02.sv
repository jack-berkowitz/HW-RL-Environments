module tag_tracker_tb;

  localparam int TAG_W   = 3;
  localparam int SLOTS   = 8;
  localparam int N_MATCH = 1;
  localparam int TAGS    = (1 << TAG_W);

  // A generous bounded wait prevents a non-granting implementation from
  // hanging the run without requiring immediate arbitration success.
  localparam int REQ_TIMEOUT = 1000;

  typedef logic [TAG_W-1:0] tag_t;
  typedef logic [31:0]      payload_t;

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

  // The reference store retains insertion order. Searches for a tag always
  // select the first matching entry, which gives per-tag FIFO behavior without
  // imposing any ordering between different tags.
  tag_t     model_tags[$];
  payload_t model_payloads[$];

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

  task automatic fail_now(input string rule_id, input string detail);
    begin
      $display("%s: %s", rule_id, detail);
      $display("RESULT: FAIL");
      $finish;
    end
  endtask

  function automatic logic compute_hit(
      input payload_t data_value,
      input payload_t mask_value
  );
    logic hit_value;
    int j;
    begin
      hit_value = 1'b0;
      for (j = 0; j < model_payloads.size(); j = j + 1) begin
        if ((model_payloads[j] & mask_value) ==
            (data_value & mask_value)) begin
          hit_value = 1'b1;
        end
      end
      compute_hit = hit_value;
    end
  endfunction

  // R14, and the unqualified full-store part of R5.
  task automatic check_status();
    logic expected_empty;
    logic expected_full;
    begin
      expected_empty = (model_tags.size() == 0);
      expected_full  = (model_tags.size() == SLOTS);

      if (empty !== expected_empty) begin
        fail_now("R14",
                 $sformatf("empty_o=%b, expected=%b, occupancy=%0d",
                           empty, expected_empty, model_tags.size()));
      end
      if (full !== expected_full) begin
        fail_now("R14",
                 $sformatf("full_o=%b, expected=%b, occupancy=%0d",
                           full, expected_full, model_tags.size()));
      end
      if (expected_full && (push_gnt !== 1'b0)) begin
        fail_now("R5", "push_gnt_o was not low while the store was full");
      end
    end
  endtask

  task automatic reset_and_check();
    begin
      push_req  = 1'b0;
      pop_req   = 1'b0;
      match_req = '0;

      bfm_reset();
      model_tags.delete();
      model_payloads.delete();

      // Allow one post-release sampling edge, then inspect status away from
      // the sampling edge.
      bfm_tick();
      bfm_drive_point();

      if ((empty !== 1'b1) || (full !== 1'b0)) begin
        fail_now("R15",
                 $sformatf("after reset empty_o=%b full_o=%b", empty, full));
      end
    end
  endtask

  task automatic do_push(input tag_t tag_value, input payload_t data_value);
    logic done;
    int waited;
    begin
      bfm_drive_point();
      push_tag  = tag_value;
      push_data = data_value;
      push_req  = 1'b1;
      pop_req   = 1'b0;
      match_req = '0;

      done   = 1'b0;
      waited = 0;
      while (!done && (waited < REQ_TIMEOUT)) begin
        bfm_tick();
        waited = waited + 1;

        if ((model_tags.size() == SLOTS) && (push_gnt !== 1'b0)) begin
          fail_now("R5", "push_gnt_o was not low at SLOTS occupancy");
        end

        if (push_gnt === 1'b1) begin
          if (model_tags.size() >= SLOTS) begin
            fail_now("R5", "a push completed while the store was full");
          end
          // R4: the request/grant cycle is the commitment point.
          model_tags.push_back(tag_value);
          model_payloads.push_back(data_value);
          done = 1'b1;
        end
      end

      if (!done) begin
        fail_now("R4",
                 $sformatf("push timed out at occupancy=%0d tag=%0d data=%08x",
                           model_tags.size(), tag_value, data_value));
      end

      bfm_drive_point();
      push_req = 1'b0;
      check_status();
    end
  endtask

  task automatic do_pop(input tag_t tag_value, input logic en_value);
    logic done;
    int waited;
    int found_idx;
    int j;
    payload_t expected_data;
    begin
      bfm_drive_point();
      pop_tag   = tag_value;
      pop_en    = en_value;
      pop_req   = 1'b1;
      push_req  = 1'b0;
      match_req = '0;

      done   = 1'b0;
      waited = 0;
      while (!done && (waited < REQ_TIMEOUT)) begin
        bfm_tick();
        waited = waited + 1;

        if (pop_gnt === 1'b1) begin
          found_idx    = -1;
          expected_data = '0;

          // First entry with this tag is the oldest entry for that tag.
          for (j = 0; j < model_tags.size(); j = j + 1) begin
            if ((found_idx < 0) && (model_tags[j] == tag_value)) begin
              found_idx = j;
            end
          end

          if (found_idx < 0) begin
            // R8/R10: an absent tag completes with valid low. Data is free.
            if (pop_data_valid !== 1'b0) begin
              fail_now("R8",
                       $sformatf("absent-tag pop returned valid=%b tag=%0d",
                                 pop_data_valid, tag_value));
            end
          end else begin
            expected_data = model_payloads[found_idx];

            if (pop_data_valid !== 1'b1) begin
              fail_now("R8",
                       $sformatf("valid was %b for present tag=%0d",
                                 pop_data_valid, tag_value));
            end
            if (pop_data !== expected_data) begin
              fail_now("R8",
                       $sformatf("tag=%0d pop_data=%08x expected_oldest=%08x",
                                 tag_value, pop_data, expected_data));
            end

            // R9: removal occurs only for an enabled, valid completing pop.
            if (en_value) begin
              model_tags.delete(found_idx);
              model_payloads.delete(found_idx);
            end
          end

          done = 1'b1;
        end
      end

      if (!done) begin
        fail_now("R7",
                 $sformatf("pop timed out tag=%0d pop_en=%b occupancy=%0d",
                           tag_value, en_value, model_tags.size()));
      end

      bfm_drive_point();
      pop_req = 1'b0;
      check_status();
    end
  endtask

  task automatic do_match(
      input payload_t data_value,
      input payload_t mask_value
  );
    logic done;
    logic expected_hit;
    int waited;
    begin
      bfm_drive_point();
      match_data[0] = data_value;
      match_mask[0] = mask_value;
      match_req[0]  = 1'b1;
      push_req      = 1'b0;
      pop_req       = 1'b0;

      done   = 1'b0;
      waited = 0;
      while (!done && (waited < REQ_TIMEOUT)) begin
        bfm_tick();
        waited = waited + 1;

        if (match_gnt[0] === 1'b1) begin
          expected_hit = compute_hit(data_value, mask_value);
          if (match_hit[0] !== expected_hit) begin
            fail_now("R12",
                     $sformatf("data=%08x mask=%08x hit=%b expected=%b occupancy=%0d",
                               data_value, mask_value, match_hit[0],
                               expected_hit, model_tags.size()));
          end
          done = 1'b1;
        end
      end

      if (!done) begin
        fail_now("R11",
                 $sformatf("search timed out data=%08x mask=%08x",
                           data_value, mask_value));
      end

      bfm_drive_point();
      match_req = '0;
      check_status();
    end
  endtask

  // Attempt pushes while full, but never require such a push to be granted.
  task automatic check_full_push();
    int waited;
    begin
      bfm_drive_point();
      push_tag  = 3'd6;
      push_data = 32'hfeed_face;
      push_req  = 1'b1;
      pop_req   = 1'b0;
      match_req = '0;

      for (waited = 0; waited < 4; waited = waited + 1) begin
        bfm_tick();
        if (push_gnt !== 1'b0) begin
          fail_now("R5", "push_gnt_o was high during a full-store push attempt");
        end
      end

      bfm_drive_point();
      push_req = 1'b0;
      check_status();
    end
  endtask

  initial begin : main_test
    automatic int i;
    automatic int op;
    automatic int idx;
    automatic tag_t rand_tag;
    automatic payload_t rand_data;
    automatic payload_t rand_mask;
    automatic logic rand_en;

    push_tag  = '0;
    push_data = '0;
    push_req  = 1'b0;
    match_data = '0;
    match_mask = '0;
    match_req  = '0;
    pop_tag   = '0;
    pop_en    = 1'b0;
    pop_req   = 1'b0;

    // R15 and empty-store behavior.
    reset_and_check();
    do_match(32'h0000_0000, 32'h0000_0000);
    do_match(32'hdead_beef, 32'hffff_ffff);
    do_pop(3'd0, 1'b1);
    do_pop(3'd7, 1'b0);

    // R1: all SLOTS entries carried by one tag must be accepted.
    for (i = 0; i < SLOTS; i = i + 1) begin
      do_push(3'd3, 32'h1000_0000 + i);
    end
    check_full_push();

    // R12/R13: empty mask, exact hit/miss, and masked hit/miss.
    do_match(32'h1234_5678, 32'h0000_0000);
    do_match(32'h1000_0003, 32'hffff_ffff);
    do_match(32'hdead_beef, 32'hffff_ffff);
    do_match(32'h1000_000a, 32'hffff_fff0);
    do_match(32'h2000_0000, 32'hffff_fff0);

    // Repeated peeks must not remove the oldest entry.
    do_pop(3'd3, 1'b0);
    do_pop(3'd3, 1'b0);
    do_match(32'h1000_0000, 32'hffff_ffff);

    // An enabled pop removes exactly that oldest entry.
    do_pop(3'd3, 1'b1);
    do_match(32'h1000_0000, 32'hffff_ffff);
    do_pop(3'd2, 1'b1);

    for (i = 1; i < SLOTS; i = i + 1) begin
      do_pop(3'd3, 1'b1);
    end
    do_pop(3'd3, 1'b1);
    do_match(32'h0000_0000, 32'h0000_0000);

    // R1 with entries shared across tags, inserted interleaved. Subsequent
    // checks require only per-tag FIFO order, never cross-tag order.
    do_push(3'd5, 32'ha000_0000);
    do_push(3'd1, 32'hb000_0000);
    do_push(3'd5, 32'ha000_0001);
    do_push(3'd7, 32'hc000_0000);
    do_push(3'd1, 32'hb000_0001);
    do_push(3'd5, 32'ha000_0002);
    do_push(3'd0, 32'hd000_0000);
    do_push(3'd5, 32'ha000_0003);
    check_full_push();

    do_match(32'hb000_0001, 32'hffff_ffff);
    do_match(32'h0000_0000, 32'h0000_0000);

    do_pop(3'd5, 1'b0);  // a000_0000, retained
    do_pop(3'd1, 1'b1);  // b000_0000
    do_pop(3'd5, 1'b1);  // a000_0000
    do_pop(3'd5, 1'b0);  // a000_0001, retained
    do_pop(3'd1, 1'b1);  // b000_0001
    do_pop(3'd7, 1'b1);  // c000_0000
    do_pop(3'd5, 1'b1);  // a000_0001
    do_pop(3'd0, 1'b1);  // d000_0000
    do_pop(3'd5, 1'b1);  // a000_0002
    do_pop(3'd5, 1'b1);  // a000_0003

    // Model-based randomized traffic. Only one request path is active at a
    // time, so no unspecified arbitration policy is assumed.
    for (i = 0; i < 400; i = i + 1) begin
      if (model_tags.size() == 0) begin
        op = 0;
      end else if (model_tags.size() == SLOTS) begin
        if ($urandom_range(0, 3) == 0) begin
          op = 3;
        end else begin
          op = $urandom_range(1, 2);
        end
      end else begin
        op = $urandom_range(0, 2);
      end

      case (op)
        0: begin
          rand_tag  = tag_t'($urandom_range(0, TAGS - 1));
          rand_data = $urandom;
          do_push(rand_tag, rand_data);
        end

        1: begin
          rand_tag = tag_t'($urandom_range(0, TAGS - 1));
          rand_en  = ($urandom_range(0, 1) != 0);
          do_pop(rand_tag, rand_en);
        end

        2: begin
          rand_data = $urandom;
          rand_mask = $urandom;

          if ($urandom_range(0, 3) == 0) begin
            rand_mask = 32'h0000_0000;
          end else if ($urandom_range(0, 3) == 0) begin
            rand_mask = 32'hffff_ffff;
          end

          // Frequently choose a stored payload, guaranteeing a hit under the
          // selected mask; other searches use unconstrained random data.
          if ((model_payloads.size() > 0) &&
              ($urandom_range(0, 1) != 0)) begin
            idx = $urandom_range(0, model_payloads.size() - 1);
            rand_data = model_payloads[idx];
          end
          do_match(rand_data, rand_mask);
        end

        default: begin
          check_full_push();
        end
      endcase
    end

    // Drain using only per-tag expectations.
    while (model_tags.size() > 0) begin
      rand_tag = model_tags[0];
      do_pop(rand_tag, 1'b1);
    end

    // Reset a non-empty store and verify that all entries disappear.
    do_push(3'd2, 32'haaaa_0000);
    do_push(3'd2, 32'haaaa_0001);
    do_push(3'd6, 32'h6666_0000);
    reset_and_check();
    do_pop(3'd2, 1'b1);
    do_match(32'h0000_0000, 32'h0000_0000);

    // Basic operation after reset recovery.
    do_push(3'd4, 32'h4444_1234);
    do_pop(3'd4, 1'b0);
    do_pop(3'd4, 1'b1);
    do_pop(3'd4, 1'b1);

    $display("RESULT: PASS");
    $finish;
  end

endmodule
