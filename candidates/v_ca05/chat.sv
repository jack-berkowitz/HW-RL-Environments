module tag_tracker_tb;

  // ---------------------------------------------------------------------------
  // Configuration required by the specification.
  // ---------------------------------------------------------------------------
  localparam int TAG_W   = 3;
  localparam int SLOTS   = 8;
  localparam int N_MATCH = 1;

  typedef logic [31:0] payload_t;

  // ---------------------------------------------------------------------------
  // PROVIDED PLUMBING -- clock, reset and watchdog discipline.
  // ---------------------------------------------------------------------------
  logic clk;
  initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
  end

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

  // ---------------------------------------------------------------------------
  // DUT signals.  The match arrays are PACKED, matching the port declaration.
  // ---------------------------------------------------------------------------
  logic [TAG_W-1:0] push_tag;
  payload_t         push_data;
  logic             push_req;
  logic             push_gnt;

  payload_t [N_MATCH-1:0] match_data;
  payload_t [N_MATCH-1:0] match_mask;
  logic     [N_MATCH-1:0] match_req;
  logic     [N_MATCH-1:0] match_hit;
  logic     [N_MATCH-1:0] match_gnt;

  logic [TAG_W-1:0] pop_tag;
  logic             pop_en;
  logic             pop_req;
  payload_t         pop_data;
  logic             pop_data_valid;
  logic             pop_gnt;

  logic             full_s;
  logic             empty_s;

  tag_tracker #(
    .TAG_W(TAG_W),
    .SLOTS(SLOTS),
    .FULL_RATE(1'b0),
    .CUT_POP_PATH(1'b0),
    .N_MATCH(N_MATCH),
    .payload_t(payload_t)
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

    .full_o(full_s),
    .empty_o(empty_s)
  );

  // ---------------------------------------------------------------------------
  // Reference model.
  //
  // Entries are kept in global insertion order.  A per-tag FIFO pop is modeled
  // by finding the first entry carrying the requested tag and removing only
  // that entry.  No cross-tag order is ever checked.
  // ---------------------------------------------------------------------------
  logic [TAG_W-1:0] model_tag  [0:SLOTS-1];
  payload_t         model_data [0:SLOTS-1];
  int               model_count;

  bit verdict_printed;

  function automatic int model_find_tag(input logic [TAG_W-1:0] tag_v);
    int i;
    begin
      model_find_tag = -1;
      for (i = 0; i < model_count; i = i + 1) begin
        if (model_tag[i] == tag_v) begin
          model_find_tag = i;
          break;
        end
      end
    end
  endfunction

  function automatic bit model_has_match(
    input payload_t data_v,
    input payload_t mask_v
  );
    int i;
    begin
      model_has_match = 1'b0;
      for (i = 0; i < model_count; i = i + 1) begin
        if ((model_data[i] & mask_v) == (data_v & mask_v)) begin
          model_has_match = 1'b1;
          break;
        end
      end
    end
  endfunction

  task automatic model_remove_index(input int idx);
    int i;
    begin
      for (i = idx; i < model_count - 1; i = i + 1) begin
        model_tag[i]  = model_tag[i+1];
        model_data[i] = model_data[i+1];
      end
      model_count = model_count - 1;
    end
  endtask

  // ---------------------------------------------------------------------------
  // Verdict and common checks.
  // ---------------------------------------------------------------------------
  task automatic fail_now(input string req_name, input string msg);
    begin
      if (!verdict_printed) begin
        verdict_printed = 1'b1;
        $display("FAIL %s: %s", req_name, msg);
        $display("RESULT: FAIL");
        $finish;
      end
    end
  endtask

  task automatic pass_now();
    begin
      if (!verdict_printed) begin
        verdict_printed = 1'b1;
        $display("RESULT: PASS");
        $finish;
      end
    end
  endtask

  task automatic check_status_now(input string req_name);
    logic exp_empty;
    logic exp_full;
    begin
      exp_empty = (model_count == 0);
      exp_full  = (model_count == SLOTS);

      if (empty_s !== exp_empty) begin
        fail_now(
          req_name,
          $sformatf(
            "empty_o=%0b, expected %0b for model_count=%0d",
            empty_s, exp_empty, model_count
          )
        );
      end

      if (full_s !== exp_full) begin
        fail_now(
          req_name,
          $sformatf(
            "full_o=%0b, expected %0b for model_count=%0d",
            full_s, exp_full, model_count
          )
        );
      end
    end
  endtask

  // ---------------------------------------------------------------------------
  // Serialized request drivers.
  //
  // The specification leaves arbitration and latency open.  Each task therefore
  // presents exactly one request, holds it unchanged, and recognizes completion
  // only from that request's grant at a rising edge.  The generous finite bound
  // prevents a deliberately inert faulty implementation from hanging the run.
  // ---------------------------------------------------------------------------
  localparam int REQ_TIMEOUT = 10000;

  task automatic push_checked(
    input logic [TAG_W-1:0] tag_v,
    input payload_t data_v
  );
    int t;
    bit got_grant;
    begin
      if (model_count >= SLOTS)
        fail_now("R1", "testbench attempted push_checked while model was full");

      bfm_drive_point();
      push_tag  = tag_v;
      push_data = data_v;
      push_req  = 1'b1;

      got_grant = 1'b0;
      for (t = 0; t < REQ_TIMEOUT; t = t + 1) begin
        bfm_tick();
        if (push_req && push_gnt) begin
          got_grant = 1'b1;
          break;
        end
      end

      if (!got_grant) begin
        bfm_drive_point();
        push_req = 1'b0;
        fail_now(
          "R1",
          $sformatf(
            "store did not accept required push tag=%0d data=%08h",
            tag_v, data_v
          )
        );
      end

      // R4: this entry is committed only on the observed request/grant cycle.
      model_tag[model_count]  = tag_v;
      model_data[model_count] = data_v;
      model_count = model_count + 1;

      bfm_drive_point();
      check_status_now("R14");
      push_req = 1'b0;
    end
  endtask

  task automatic pop_checked(
    input logic [TAG_W-1:0] tag_v,
    input logic remove_v
  );
    int t;
    int idx;
    bit got_grant;
    bit exp_valid;
    payload_t exp_data;
    begin
      idx = model_find_tag(tag_v);
      exp_valid = (idx >= 0);
      exp_data = '0;
      if (exp_valid)
        exp_data = model_data[idx];

      bfm_drive_point();
      pop_tag = tag_v;
      pop_en  = remove_v;
      pop_req = 1'b1;

      got_grant = 1'b0;
      for (t = 0; t < REQ_TIMEOUT; t = t + 1) begin
        bfm_tick();
        if (pop_req && pop_gnt) begin
          got_grant = 1'b1;

          if (pop_data_valid !== exp_valid) begin
            if (exp_valid) begin
              fail_now(
                "R8",
                $sformatf(
                  "pop tag=%0d returned valid=%0b, expected valid=1",
                  tag_v, pop_data_valid
                )
              );
            end else begin
              fail_now(
                "R10",
                $sformatf(
                  "empty-tag pop tag=%0d returned valid=%0b, expected 0",
                  tag_v, pop_data_valid
                )
              );
            end
          end

          if (exp_valid && (pop_data !== exp_data)) begin
            fail_now(
              "R2/R8",
              $sformatf(
                "pop tag=%0d returned %08h, expected oldest payload %08h",
                tag_v, pop_data, exp_data
              )
            );
          end

          break;
        end
      end

      if (!got_grant) begin
        bfm_drive_point();
        pop_req = 1'b0;
        fail_now(
          exp_valid ? "R7/R8" : "R7/R10",
          $sformatf("pop request for tag=%0d never completed", tag_v)
        );
      end

      // R9: removal happens only for completing, valid pops with pop_en_i high.
      if (remove_v && exp_valid)
        model_remove_index(idx);

      bfm_drive_point();
      check_status_now("R14");
      pop_req = 1'b0;
      pop_en  = 1'b0;
    end
  endtask

  task automatic search_checked(
    input payload_t data_v,
    input payload_t mask_v
  );
    int t;
    bit got_grant;
    bit hit_exp;
    begin
      hit_exp = model_has_match(data_v, mask_v);

      bfm_drive_point();
      match_data[0] = data_v;
      match_mask[0] = mask_v;
      match_req[0]  = 1'b1;

      got_grant = 1'b0;
      for (t = 0; t < REQ_TIMEOUT; t = t + 1) begin
        bfm_tick();
        if (match_req[0] && match_gnt[0]) begin
          got_grant = 1'b1;

          if (match_hit[0] !== hit_exp) begin
            if ((mask_v == '0) && (model_count > 0)) begin
              fail_now(
                "R13",
                $sformatf(
                  "zero-mask search returned hit=%0b with model_count=%0d",
                  match_hit[0], model_count
                )
              );
            end else begin
              fail_now(
                "R12",
                $sformatf(
                  "search data=%08h mask=%08h returned hit=%0b expected=%0b",
                  data_v, mask_v, match_hit[0], hit_exp
                )
              );
            end
          end

          break;
        end
      end

      if (!got_grant) begin
        bfm_drive_point();
        match_req[0] = 1'b0;
        fail_now("R11", "search request never completed");
      end

      bfm_drive_point();
      check_status_now("R14");
      match_req[0] = 1'b0;
    end
  endtask

  task automatic push_must_be_blocked_when_full(
    input logic [TAG_W-1:0] tag_v,
    input payload_t data_v
  );
    int t;
    begin
      if (model_count != SLOTS)
        fail_now("R5", "full-block test started while model was not full");

      bfm_drive_point();
      push_tag  = tag_v;
      push_data = data_v;
      push_req  = 1'b1;

      for (t = 0; t < 32; t = t + 1) begin
        bfm_tick();
        if (push_req && push_gnt) begin
          fail_now(
            "R5",
            $sformatf(
              "push_gnt_o asserted while store already held %0d entries",
              SLOTS
            )
          );
        end
      end

      bfm_drive_point();
      check_status_now("R14");
      push_req = 1'b0;
    end
  endtask

  task automatic reset_model_and_check();
    begin
      bfm_reset(4);
      model_count = 0;

      // Move through a complete sampled cycle before checking post-reset status.
      bfm_tick();
      bfm_drive_point();
      check_status_now("R15/R14");
    end
  endtask

  task automatic reset_live_store_and_check();
    begin
      // Inputs are idle when this task is called.  Assert reset away from the
      // sampling edge, check status while reset is still low, then release it
      // away from the sampling edge and check the post-reset state again.
      bfm_drive_point();
      rst_n = 1'b0;
      model_count = 0;

      repeat (4) @(posedge clk);
      bfm_drive_point();
      check_status_now("R15");

      rst_n = 1'b1;
      bfm_tick();
      bfm_drive_point();
      check_status_now("R15/R14");
    end
  endtask

  // ---------------------------------------------------------------------------
  // Initial stimulus values.
  // ---------------------------------------------------------------------------
  initial begin
    push_tag = '0;
    push_data = '0;
    push_req = 1'b0;

    match_data = '0;
    match_mask = '0;
    match_req = '0;

    pop_tag = '0;
    pop_en = 1'b0;
    pop_req = 1'b0;

    model_count = 0;
    verdict_printed = 1'b0;
  end

  // ---------------------------------------------------------------------------
  // Directed tests.
  // ---------------------------------------------------------------------------
  initial begin
    int i;

    // R15/R14: reset starts empty and not full.
    reset_model_and_check();

    // R10: an empty-tag pop is a normal completion with data_valid low.
    pop_checked(3'd6, 1'b1);

    // R12/R13 on an empty store: even the all-zero mask must miss when empty.
    search_checked(32'hDEAD_BEEF, 32'h0000_0000);
    search_checked(32'h0000_0000, 32'hFFFF_FFFF);

    // -----------------------------------------------------------------------
    // Mixed-tag functional set.
    // R2 is checked only within a tag; no cross-tag ordering is assumed.
    // -----------------------------------------------------------------------
    push_checked(3'd1, 32'h1122_3344);
    push_checked(3'd2, 32'hA5C3_5A7E);
    push_checked(3'd1, 32'h5566_7788);

    // R12: exact hit, exact miss, and a partial-mask hit across all tags.
    search_checked(32'h5566_7788, 32'hFFFF_FFFF);
    search_checked(32'h1234_5678, 32'hFFFF_FFFF);
    search_checked(32'hA000_007E, 32'hF000_00FF);

    // R13: zero mask matches every stored payload when non-empty.
    search_checked(32'hCAFE_BABE, 32'h0000_0000);

    // R9: inspect tag 1 without removing it.
    pop_checked(3'd1, 1'b0);

    // R2/R8/R9: same oldest value remains, then removal exposes the next one.
    pop_checked(3'd1, 1'b1);
    pop_checked(3'd1, 1'b0);
    pop_checked(3'd1, 1'b1);

    // R10: tag 1 is empty even though tag 2 still contains an entry.
    pop_checked(3'd1, 1'b1);

    // Search is across all tags; tag 2's entry must remain.
    search_checked(32'hA5C3_5A7E, 32'hFFFF_FFFF);

    // -----------------------------------------------------------------------
    // R15: reset while live entries exist must erase the store.
    // -----------------------------------------------------------------------
    reset_live_store_and_check();

    pop_checked(3'd2, 1'b1);
    search_checked(32'h0000_0000, 32'h0000_0000);

    // -----------------------------------------------------------------------
    // R1: all eight entries may carry the SAME tag.
    // -----------------------------------------------------------------------
    for (i = 0; i < SLOTS; i = i + 1) begin
      push_checked(3'd3, 32'h3000_0000 + i);
    end

    // R14: eighth committed entry must make full_o high.
    bfm_drive_point();
    check_status_now("R14");

    // R13 when full.
    search_checked(32'hFFFF_FFFF, 32'h0000_0000);

    // R5: ninth push cannot be granted.
    push_must_be_blocked_when_full(3'd4, 32'h9999_9999);

    // R9: inspection cannot create free space.
    pop_checked(3'd3, 1'b0);

    if (model_count != SLOTS)
      fail_now("R9", "inspection unexpectedly changed model occupancy");

    bfm_drive_point();
    check_status_now("R9/R14");

    // R2: remove all eight same-tag entries in insertion order.
    for (i = 0; i < SLOTS; i = i + 1) begin
      pop_checked(3'd3, 1'b1);
    end

    // R14 after final removal.
    bfm_drive_point();
    check_status_now("R14");

    // R10/R13 after draining.
    pop_checked(3'd3, 1'b1);
    search_checked(32'h1234_5678, 32'h0000_0000);

    // -----------------------------------------------------------------------
    // Shared capacity across tags and reuse of freed space.
    // -----------------------------------------------------------------------
    reset_model_and_check();

    push_checked(3'd0, 32'h0101_0000);
    push_checked(3'd1, 32'h0202_0001);
    push_checked(3'd2, 32'h0303_0002);
    push_checked(3'd3, 32'h0404_0003);
    push_checked(3'd4, 32'h0505_0004);
    push_checked(3'd5, 32'h0606_0005);
    push_checked(3'd6, 32'h0707_0006);
    push_checked(3'd7, 32'h0808_0007);

    bfm_drive_point();
    check_status_now("R1/R14");

    // Remove one middle-tag entry.
    pop_checked(3'd4, 1'b1);

    // Freed globally shared slot must be reusable by any tag.
    push_checked(3'd0, 32'h0A0A_00A0);

    bfm_drive_point();
    check_status_now("R1/R14");

    // Per-tag FIFO for tag 0.
    pop_checked(3'd0, 1'b1);
    pop_checked(3'd0, 1'b1);

    // Final reset proves no live state leaks past reset.
    reset_model_and_check();

    pop_checked(3'd7, 1'b1);
    search_checked(32'h0000_0000, 32'h0000_0000);

    pass_now();
  end

  // ---------------------------------------------------------------------------
  // Independent watchdog.
  // ---------------------------------------------------------------------------
  initial begin
    #20_000_000;
    if (!verdict_printed) begin
      verdict_printed = 1'b1;
      $display("FAIL R1/R7/R11: watchdog: no forward progress");
      $display("RESULT: FAIL");
      $finish;
    end
  end

endmodule