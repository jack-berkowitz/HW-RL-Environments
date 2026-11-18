module tag_tracker_tb;

  localparam int TAG_W   = 3;
  localparam int SLOTS   = 8;
  localparam int N_MATCH = 1;
  localparam int WAIT_LIMIT = 128;

  typedef logic [31:0] payload_t;
  typedef logic [TAG_W-1:0] tag_t;

  logic clk;
  logic rst_n;

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

  tag_tracker #(
      .TAG_W        (TAG_W),
      .SLOTS        (SLOTS),
      .FULL_RATE    (1'b0),
      .CUT_POP_PATH (1'b0),
      .N_MATCH      (N_MATCH),
      .payload_t    (payload_t)
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
      .full_o           (full),
      .empty_o          (empty)
  );

  // ---------------------------------------------------------------------------
  // PROVIDED PLUMBING -- clock, reset and watchdog only.
  // ---------------------------------------------------------------------------
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

  // ---------------------------------------------------------------------------
  // Reference model.  Global insertion order is retained solely so that the
  // oldest entry for each individual tag can be identified.  No cross-tag
  // ordering requirement is imposed on the DUT.
  // ---------------------------------------------------------------------------
  typedef struct packed {
    tag_t     tag;
    payload_t data;
  } rec_t;

  rec_t model_q[$];
  int unsigned rng_state;

  task automatic fail(input string rule, input string message);
    begin
      $display("%s: %s", rule, message);
      $display("RESULT: FAIL");
      $finish;
    end
  endtask

  function automatic int unsigned next_rand();
    begin
      rng_state = rng_state * 32'd1664525 + 32'd1013904223;
      next_rand = rng_state;
    end
  endfunction

  function automatic int oldest_index(input tag_t tag);
    int i;
    begin
      oldest_index = -1;
      for (i = 0; i < model_q.size(); i++) begin
        if ((oldest_index < 0) && (model_q[i].tag == tag))
          oldest_index = i;
      end
    end
  endfunction

  function automatic bit expected_hit(
      input payload_t data,
      input payload_t mask
  );
    int i;
    bit hit;
    begin
      hit = 1'b0;
      for (i = 0; i < model_q.size(); i++) begin
        if ((model_q[i].data & mask) == (data & mask))
          hit = 1'b1;
      end
      expected_hit = hit;
    end
  endfunction

  task automatic check_status();
    bit exp_empty;
    bit exp_full;
    begin
      exp_empty = (model_q.size() == 0);
      exp_full  = (model_q.size() == SLOTS);

      if (empty !== exp_empty)
        fail("R14", $sformatf(
             "empty_o=%b, expected %b with %0d entries",
             empty, exp_empty, model_q.size()));

      if (full !== exp_full)
        fail("R14", $sformatf(
             "full_o=%b, expected %b with %0d entries",
             full, exp_full, model_q.size()));

      if (exp_full && (push_gnt !== 1'b0))
        fail("R5", "push_gnt_o was not low while the store was full");
    end
  endtask

  task automatic do_push(input tag_t tag, input payload_t data);
    rec_t rec;
    int waited;
    bit done;
    begin
      if (model_q.size() >= SLOTS)
        fail("R1", "testbench attempted an ordinary push while full");

      rec.tag  = tag;
      rec.data = data;

      bfm_drive_point();
      push_tag  = tag;
      push_data = data;
      push_req  = 1'b1;

      waited = 0;
      done   = 1'b0;
      while (!done && (waited < WAIT_LIMIT)) begin
        bfm_tick();
        if (push_gnt === 1'b1) begin
          model_q.push_back(rec);
          done = 1'b1;
        end
        waited++;
        bfm_drive_point();
      end

      push_req = 1'b0;
      if (!done)
        fail("R1", $sformatf(
             "push of tag %0d data %08x was not granted with %0d entries",
             tag, data, model_q.size()));

      check_status();
    end
  endtask

  task automatic do_pop(
      input tag_t tag,
      input bit remove_entry
  );
    int waited;
    int idx;
    bit done;
    bit exp_valid;
    payload_t exp_data;
    begin
      idx       = oldest_index(tag);
      exp_valid = (idx >= 0);
      exp_data  = '0;
      if (exp_valid)
        exp_data = model_q[idx].data;

      bfm_drive_point();
      pop_tag = tag;
      pop_en  = remove_entry;
      pop_req = 1'b1;

      waited = 0;
      done   = 1'b0;
      while (!done && (waited < WAIT_LIMIT)) begin
        bfm_tick();
        if (pop_gnt === 1'b1) begin
          if (pop_data_valid !== exp_valid)
            fail("R8", $sformatf(
                 "pop tag %0d: valid=%b, expected %b",
                 tag, pop_data_valid, exp_valid));

          if (exp_valid && (pop_data !== exp_data))
            fail("R8", $sformatf(
                 "pop tag %0d: data=%08x, oldest expected %08x",
                 tag, pop_data, exp_data));

          if (remove_entry && exp_valid)
            model_q.delete(idx);

          done = 1'b1;
        end
        waited++;
        bfm_drive_point();
      end

      pop_req = 1'b0;
      pop_en  = 1'b0;
      if (!done)
        fail("R7", $sformatf("pop of tag %0d was not granted", tag));

      check_status();
    end
  endtask

  task automatic do_match(input payload_t data, input payload_t mask);
    int waited;
    bit done;
    bit exp_hit;
    begin
      exp_hit = expected_hit(data, mask);

      bfm_drive_point();
      match_data[0] = data;
      match_mask[0] = mask;
      match_req[0]  = 1'b1;

      waited = 0;
      done   = 1'b0;
      while (!done && (waited < WAIT_LIMIT)) begin
        bfm_tick();
        if (match_gnt[0] === 1'b1) begin
          if (match_hit[0] !== exp_hit)
            fail("R12", $sformatf(
                 "search data=%08x mask=%08x: hit=%b, expected %b (%0d entries)",
                 data, mask, match_hit[0], exp_hit, model_q.size()));
          done = 1'b1;
        end
        waited++;
        bfm_drive_point();
      end

      match_req[0] = 1'b0;
      if (!done)
        fail("R11", "search request was not granted");

      check_status();
    end
  endtask

  task automatic check_full_push_reject(input tag_t tag, input payload_t data);
    int i;
    begin
      if (model_q.size() != SLOTS)
        fail("R5", "full-store rejection test invoked while not full");

      bfm_drive_point();
      push_tag  = tag;
      push_data = data;
      push_req  = 1'b1;

      for (i = 0; i < 3; i++) begin
        bfm_tick();
        if (push_gnt !== 1'b0)
          fail("R5", "push_gnt_o was high while the store held SLOTS entries");
        bfm_drive_point();
      end

      push_req = 1'b0;
      check_status();
    end
  endtask

  task automatic random_search();
    payload_t data;
    payload_t mask;
    int unsigned choice;
    int idx;
    begin
      data   = next_rand();
      mask   = 32'hffff_ffff;
      choice = next_rand() % 6;

      case (choice)
        0: mask = 32'h0000_0000;
        1: mask = 32'hffff_ffff;
        2: mask = 32'h0000_00ff;
        3: mask = 32'hffff_0000;
        default: mask = next_rand();
      endcase

      if ((model_q.size() != 0) && ((next_rand() & 1) != 0)) begin
        idx  = next_rand() % model_q.size();
        data = model_q[idx].data;
        if ((next_rand() & 1) != 0)
          data = data ^ next_rand();
      end

      do_match(data, mask);
    end
  endtask

  initial begin
    int i;
    int step;
    int unsigned op;
    tag_t tag;
    payload_t data;

    push_req     = 1'b0;
    push_tag     = '0;
    push_data    = '0;
    match_req    = '0;
    match_data   = '0;
    match_mask   = '0;
    pop_req      = 1'b0;
    pop_en       = 1'b0;
    pop_tag      = '0;
    rng_state    = 32'h4d59_5df4;

    bfm_reset();
    model_q.delete();

    if (empty !== 1'b1)
      fail("R15", "empty_o was not high after reset release");
    if (full !== 1'b0)
      fail("R15", "full_o was not low after reset release");
    check_status();

    // Empty-store pops and searches, including the all-zero mask.
    do_pop(3'd0, 1'b0);
    do_pop(3'd5, 1'b1);
    do_match(32'h0000_0000, 32'h0000_0000);
    do_match(32'h1234_5678, 32'hffff_ffff);

    // R1: fill every slot with the same tag.
    for (i = 0; i < SLOTS; i++)
      do_push(3'd2, 32'h1000_0000 + i);

    check_full_push_reject(3'd2, 32'hdead_beef);

    // Searches with guaranteed hits, misses, partial masks, and zero masks.
    do_match(32'h0000_0000, 32'h0000_0000);
    do_match(32'h1000_0003, 32'hffff_ffff);
    do_match(32'hffff_ff03, 32'h0000_00ff);
    do_match(32'h2000_0003, 32'hffff_ffff);
    do_match(32'h1000_0007, 32'hffff_fff0);
    do_match(32'h1000_0008, 32'hffff_ffff);

    // Peeks must not remove anything; removing pops must return FIFO order.
    do_pop(3'd2, 1'b0);
    do_pop(3'd2, 1'b0);
    do_pop(3'd2, 1'b1);
    do_match(32'h1000_0000, 32'hffff_ffff);
    do_match(32'h1000_0001, 32'hffff_ffff);

    for (i = 1; i < SLOTS; i++) begin
      if ((i & 1) != 0)
        do_pop(3'd2, 1'b0);
      do_pop(3'd2, 1'b1);
    end
    do_pop(3'd2, 1'b1);

    // Fill to capacity with several interleaved tags.
    do_push(3'd2, 32'ha000_0000);
    do_push(3'd1, 32'hb000_0001);
    do_push(3'd2, 32'ha000_0002);
    do_push(3'd3, 32'hc000_0003);
    do_push(3'd1, 32'hb000_0004);
    do_push(3'd2, 32'ha000_0005);
    do_push(3'd0, 32'hd000_0006);
    do_push(3'd3, 32'hc000_0007);

    check_full_push_reject(3'd7, 32'h1234_abcd);
    do_match(32'h0000_0000, 32'h0000_0000);
    do_match(32'ha000_0005, 32'hffff_ffff);
    do_match(32'hb000_0004, 32'hffff_ffff);
    do_match(32'he000_0000, 32'hf000_0000);

    do_pop(3'd2, 1'b0);
    do_pop(3'd2, 1'b1);
    do_pop(3'd1, 1'b1);
    do_pop(3'd2, 1'b1);
    do_pop(3'd3, 1'b0);
    do_pop(3'd3, 1'b1);
    do_pop(3'd1, 1'b1);
    do_pop(3'd2, 1'b1);
    do_pop(3'd0, 1'b1);
    do_pop(3'd3, 1'b1);
    do_pop(3'd3, 1'b0);

    // Reset must discard a non-empty store.
    do_push(3'd6, 32'h5555_aaaa);
    do_push(3'd7, 32'haaaa_5555);
    do_push(3'd6, 32'h0123_4567);
    model_q.delete();
    bfm_reset(3);

    if (empty !== 1'b1)
      fail("R15", "store was not empty after a subsequent reset");
    if (full !== 1'b0)
      fail("R15", "full_o asserted after a subsequent reset");
    check_status();
    do_pop(3'd6, 1'b1);
    do_match(32'h0000_0000, 32'h0000_0000);

    // Deterministic randomized sequential traffic.  Requests on different
    // paths are not overlapped, so no arbitration policy is assumed.
    for (step = 0; step < 400; step++) begin
      op = next_rand() % 100;

      if ((model_q.size() == 0) ||
          ((model_q.size() < SLOTS) && (op < 42))) begin
        tag  = tag_t'(next_rand() % (1 << TAG_W));
        data = next_rand();
        if ((next_rand() % 4) == 0)
          data = data & 32'h0000_00ff;
        do_push(tag, data);
      end
      else if ((model_q.size() == SLOTS) && (op < 50)) begin
        check_full_push_reject(tag_t'(next_rand()), next_rand());
      end
      else if (op < 75) begin
        tag = tag_t'(next_rand() % (1 << TAG_W));
        do_pop(tag, ((next_rand() % 4) != 0));
      end
      else begin
        random_search();
      end
    end

    // Drain using only specified per-tag ordering.
    while (model_q.size() != 0) begin
      tag = model_q[0].tag;
      if ((next_rand() & 1) != 0)
        do_pop(tag, 1'b0);
      do_pop(tag, 1'b1);
    end

    do_match(32'h0000_0000, 32'h0000_0000);
    check_status();

    $display("RESULT: PASS");
    $finish;
  end

endmodule
