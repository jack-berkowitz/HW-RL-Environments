module tag_tracker_tb;

  localparam int TAG_W   = 3;
  localparam int SLOTS   = 8;
  localparam int N_MATCH = 1;
  localparam int MAX_WAIT = 1000;

  typedef logic [31:0] payload_t;
  typedef logic [TAG_W-1:0] tag_t;

  typedef struct {
    tag_t     tag;
    payload_t data;
  } rec_t;

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

  rec_t model_store[$];

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
    $display("R4/R7/R11: watchdog expired with no forward progress");
    $display("RESULT: FAIL");
    $finish;
  end
  // ---------------------------------------------------------------------------

  task automatic fail(input string rule_id, input string detail);
    $display("%s: %s", rule_id, detail);
    $display("RESULT: FAIL");
    $finish;
  endtask

  task automatic idle_requests();
    push_req      = 1'b0;
    push_tag      = '0;
    push_data     = '0;
    match_req     = '0;
    match_data    = '0;
    match_mask    = '0;
    pop_req       = 1'b0;
    pop_en        = 1'b0;
    pop_tag       = '0;
  endtask

  // Call only at a negedge, after the DUT has settled following any commit.
  task automatic check_status();
    bit expected_empty;
    bit expected_full;
    begin
      expected_empty = (model_store.size() == 0);
      expected_full  = (model_store.size() == SLOTS);

      if (empty !== expected_empty)
        fail("R14", $sformatf("empty_o=%0b, expected %0b with %0d entries",
                              empty, expected_empty, model_store.size()));

      if (full !== expected_full)
        fail("R14", $sformatf("full_o=%0b, expected %0b with %0d entries",
                              full, expected_full, model_store.size()));

      if (expected_full && (push_gnt !== 1'b0))
        fail("R5", "push_gnt_o was not low while the store was full");
    end
  endtask

  task automatic reset_and_clear_model();
    begin
      bfm_drive_point();
      idle_requests();
      model_store.delete();
      bfm_reset();
      check_status();
    end
  endtask

  task automatic do_push(input tag_t tag_value, input payload_t data_value);
    int waited;
    rec_t ent;
    begin
      if (model_store.size() >= SLOTS)
        fail("R1", "testbench attempted an ordinary push while full");

      ent.tag  = tag_value;
      ent.data = data_value;
      waited   = 0;

      bfm_drive_point();
      push_tag  = tag_value;
      push_data = data_value;
      push_req  = 1'b1;

      while (1) begin
        bfm_tick();

        if (push_gnt === 1'b1) begin
          model_store.push_back(ent);
          break;
        end

        if (push_gnt !== 1'b0)
          fail("R4", "push_gnt_o contained an unknown value");

        waited++;
        if (waited >= MAX_WAIT)
          fail("R4", "timeout waiting for a requested push to complete");
      end

      bfm_drive_point();
      push_req = 1'b0;
      check_status();
    end
  endtask

  task automatic do_pop(input tag_t tag_value, input bit remove_entry);
    int waited;
    int found_index;
    bit expected_valid;
    payload_t expected_data;
    begin
      waited         = 0;
      found_index    = -1;
      expected_valid = 1'b0;
      expected_data  = '0;

      foreach (model_store[i]) begin
        if (!expected_valid && model_store[i].tag == tag_value) begin
          expected_valid = 1'b1;
          expected_data  = model_store[i].data;
          found_index    = i;
        end
      end

      bfm_drive_point();
      pop_tag = tag_value;
      pop_en  = remove_entry;
      pop_req = 1'b1;

      while (1) begin
        bfm_tick();

        if (pop_gnt === 1'b1) begin
          if (pop_data_valid !== expected_valid)
            fail("R8", $sformatf(
              "pop tag %0d: pop_data_valid_o=%0b, expected %0b",
              tag_value, pop_data_valid, expected_valid));

          if (expected_valid && (pop_data !== expected_data))
            fail("R8", $sformatf(
              "pop tag %0d: pop_data_o=%08x, expected oldest data %08x",
              tag_value, pop_data, expected_data));

          if (expected_valid && remove_entry)
            model_store.delete(found_index);

          break;
        end

        if (pop_gnt !== 1'b0)
          fail("R7", "pop_gnt_o contained an unknown value");

        waited++;
        if (waited >= MAX_WAIT)
          fail("R7", "timeout waiting for a requested pop to complete");
      end

      bfm_drive_point();
      pop_req = 1'b0;
      pop_en  = 1'b0;
      check_status();
    end
  endtask

  task automatic do_search(input payload_t data_value,
                           input payload_t mask_value);
    int waited;
    bit expected_hit;
    begin
      waited       = 0;
      expected_hit = 1'b0;

      foreach (model_store[i]) begin
        if ((model_store[i].data & mask_value) ==
            (data_value & mask_value))
          expected_hit = 1'b1;
      end

      bfm_drive_point();
      match_data[0] = data_value;
      match_mask[0] = mask_value;
      match_req[0]  = 1'b1;

      while (1) begin
        bfm_tick();

        if (match_gnt[0] === 1'b1) begin
          if (match_hit[0] !== expected_hit)
            fail("R12", $sformatf(
              "search data=%08x mask=%08x: hit=%0b, expected %0b",
              data_value, mask_value, match_hit[0], expected_hit));
          break;
        end

        if (match_gnt[0] !== 1'b0)
          fail("R11", "match_gnt_o contained an unknown value");

        waited++;
        if (waited >= MAX_WAIT)
          fail("R11", "timeout waiting for a requested search to complete");
      end

      bfm_drive_point();
      match_req[0] = 1'b0;
    end
  endtask

  task automatic verify_full_push_rejected();
    int waited;
    begin
      if (model_store.size() != SLOTS)
        fail("R1", "full-push test called without a full reference store");

      bfm_drive_point();
      push_tag  = tag_t'(3);
      push_data = 32'hdead_beef;
      push_req  = 1'b1;

      for (waited = 0; waited < 4; waited++) begin
        bfm_tick();
        if (push_gnt !== 1'b0)
          fail("R5", "a push was granted while all SLOTS entries were occupied");
      end

      bfm_drive_point();
      push_req = 1'b0;
      check_status();
    end
  endtask

  initial begin : main_sequence
    automatic int i;
    automatic int op;
    automatic int idx;
    automatic tag_t tag_value;
    automatic payload_t data_value;
    automatic payload_t mask_value;

    idle_requests();
    reset_and_clear_model();

    // Empty-store pop and all-zero-mask search behavior.
    do_pop(tag_t'(3), 1'b0);
    do_pop(tag_t'(3), 1'b1);
    do_search(32'h0000_0000, 32'h0000_0000);

    // Interleaved tags, per-tag FIFO order, and non-removing peeks.
    do_push(tag_t'(2), 32'h1111_0000);
    do_push(tag_t'(2), 32'h1111_0001);
    do_push(tag_t'(1), 32'h2222_0000);
    do_push(tag_t'(2), 32'h1111_0002);

    do_pop(tag_t'(2), 1'b0);
    do_pop(tag_t'(2), 1'b0);
    do_pop(tag_t'(2), 1'b1);
    do_pop(tag_t'(2), 1'b1);
    do_pop(tag_t'(2), 1'b0);

    do_search(32'h1111_0002, 32'hffff_ffff);
    do_search(32'h1111_00ff, 32'hffff_ff00);
    do_search(32'h3333_0000, 32'hffff_ffff);
    do_search(32'h0000_0000, 32'h0000_0000);

    // Reset must discard a non-empty store.
    reset_and_clear_model();
    do_pop(tag_t'(2), 1'b1);
    do_search(32'h0000_0000, 32'h0000_0000);

    // R1: all SLOTS entries with one tag must be accepted.
    for (i = 0; i < SLOTS; i++)
      do_push(tag_t'(4), 32'h1000_0000 + i);

    verify_full_push_rejected();
    do_search(32'h0000_0000, 32'h0000_0000);
    do_search(32'h1000_0003, 32'hffff_ffff);
    do_search(32'h1000_00ff, 32'hffff_ff00);
    do_search(32'h9000_0000, 32'hffff_0000);

    do_pop(tag_t'(4), 1'b0);
    for (i = 0; i < SLOTS; i++)
      do_pop(tag_t'(4), 1'b1);
    do_pop(tag_t'(4), 1'b1);

    // A mixed distribution must also reach capacity and preserve each tag's FIFO.
    for (i = 0; i < SLOTS; i++)
      do_push(tag_t'(i % 3), 32'h2000_0000 + i);

    verify_full_push_rejected();
    do_pop(tag_t'(0), 1'b1);
    do_pop(tag_t'(1), 1'b1);
    do_pop(tag_t'(2), 1'b1);
    do_pop(tag_t'(0), 1'b1);
    do_pop(tag_t'(1), 1'b1);
    do_pop(tag_t'(2), 1'b1);
    do_pop(tag_t'(0), 1'b1);
    do_pop(tag_t'(1), 1'b1);

    // Randomized sequential traffic against the reference store.
    for (op = 0; op < 400; op++) begin
      if ((model_store.size() < SLOTS) &&
          (($urandom_range(0, 99) < 45) || (model_store.size() == 0))) begin
        tag_value  = tag_t'($urandom_range(0, 7));
        data_value = payload_t'($urandom);
        do_push(tag_value, data_value);
      end
      else if ($urandom_range(0, 99) < 70) begin
        tag_value = tag_t'($urandom_range(0, 7));
        do_pop(tag_value, bit'($urandom_range(0, 1)));
      end
      else begin
        if ((model_store.size() != 0) && ($urandom_range(0, 1) == 1)) begin
          idx        = $urandom_range(0, model_store.size() - 1);
          data_value = model_store[idx].data;
        end
        else begin
          data_value = payload_t'($urandom);
        end

        case ($urandom_range(0, 3))
          0: mask_value = 32'h0000_0000;
          1: mask_value = 32'hffff_ffff;
          2: mask_value = 32'hffff_0000;
          default: mask_value = payload_t'($urandom);
        endcase

        do_search(data_value, mask_value);
      end
    end

    // Drain every remaining entry and recheck the empty state.
    while (model_store.size() != 0) begin
      tag_value = model_store[0].tag;
      do_pop(tag_value, 1'b1);
    end

    do_pop(tag_t'(7), 1'b0);
    do_search(32'h0000_0000, 32'h0000_0000);
    reset_and_clear_model();

    $display("RESULT: PASS");
    $finish;
  end

endmodule
