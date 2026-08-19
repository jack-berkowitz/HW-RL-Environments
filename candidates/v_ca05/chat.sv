`timescale 1ns/1ps

module tag_tracker_tb;

  localparam int TAG_W_P   = 3;
  localparam int SLOTS_P   = 8;
  localparam int N_MATCH_P = 1;

  typedef logic [31:0] payload_t;
  typedef logic [TAG_W_P-1:0] tag_t;

  typedef struct packed {
    tag_t     tag;
    payload_t data;
  } rec_t;

  // ---------------------------------------------------------------------------
  // DUT signals
  // ---------------------------------------------------------------------------

  tag_t     push_tag;
  payload_t push_data;
  logic     push_req;
  logic     push_gnt;

  // These are PACKED dimensions, matching the DUT port map exactly.
  payload_t [N_MATCH_P-1:0] match_data;
  payload_t [N_MATCH_P-1:0] match_mask;
  logic     [N_MATCH_P-1:0] match_req;
  logic     [N_MATCH_P-1:0] match_hit;
  logic     [N_MATCH_P-1:0] match_gnt;

  tag_t     pop_tag;
  logic     pop_en;
  logic     pop_req;
  payload_t pop_data;
  logic     pop_data_valid;
  logic     pop_gnt;

  logic full;
  logic empty;

  // ---------------------------------------------------------------------------
  // Reference model / reporting
  // ---------------------------------------------------------------------------

  rec_t model_q[$];
  int   model_count;
  int   fail_count;

  // Used only so the independent watchdog can name the requirement associated
  // with a request that has stopped making forward progress.
  string active_req_name;
  string active_req_desc;

  // ---------------------------------------------------------------------------
  // PROVIDED PLUMBING -- clock, reset and timing discipline.
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

  // Independent unconditional watchdog.  It is deliberately the only bound
  // placed on grant latency, because the specification otherwise leaves
  // request-to-grant latency unconstrained.
  initial begin
    #20_000_000;

    if (active_req_name != "") begin
      $display(
        "FAIL %s: watchdog: no forward progress while %s",
        active_req_name,
        active_req_desc
      );
    end
    else begin
      $display("FAIL R15: watchdog: testbench did not terminate");
    end

    $display("RESULT: FAIL");
    $finish;
  end

  // ---------------------------------------------------------------------------
  // DUT
  // ---------------------------------------------------------------------------

  tag_tracker #(
    .TAG_W        (TAG_W_P),
    .SLOTS        (SLOTS_P),
    .FULL_RATE    (1'b0),
    .CUT_POP_PATH (1'b0),
    .N_MATCH      (N_MATCH_P),
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
  // Failure helper
  // ---------------------------------------------------------------------------

  task automatic note_fail(
    input string req_name,
    input string msg
  );
    fail_count = fail_count + 1;
    $display("FAIL %s: %s", req_name, msg);
  endtask

  // ---------------------------------------------------------------------------
  // R14 -- exact occupancy status
  // ---------------------------------------------------------------------------

  task automatic check_status(input string req_name);
    automatic logic want_empty;
    automatic logic want_full;

    want_empty = (model_count == 0);
    want_full  = (model_count == SLOTS_P);

    if (empty !== want_empty) begin
      note_fail(
        req_name,
        $sformatf(
          "empty_o=%0b, expected %0b at occupancy %0d",
          empty, want_empty, model_count
        )
      );
    end

    if (full !== want_full) begin
      note_fail(
        req_name,
        $sformatf(
          "full_o=%0b, expected %0b at occupancy %0d",
          full, want_full, model_count
        )
      );
    end
  endtask

  // ---------------------------------------------------------------------------
  // Push transaction
  //
  // R4: the reference model changes only on push_req_i && push_gnt_o.
  // R6: no assumption is made that grant must immediately assert merely
  //     because capacity is available.
  // ---------------------------------------------------------------------------

  task automatic push_one(
    input tag_t     tag_v,
    input payload_t data_v,
    input string    progress_req_name
  );
    automatic logic done;
    automatic logic sampled_gnt;
    automatic rec_t item;

    done        = 1'b0;
    sampled_gnt = 1'b0;

    active_req_name = progress_req_name;
    active_req_desc = $sformatf("waiting for push grant, tag %0d", tag_v);

    bfm_drive_point();
    push_tag  = tag_v;
    push_data = data_v;
    push_req  = 1'b1;

    while (!done) begin
      // Sample the handshake value at the sampling edge, before changing any
      // request signal.
      bfm_tick();
      sampled_gnt = push_gnt;

      if (sampled_gnt) begin
        // R4
        item.tag  = tag_v;
        item.data = data_v;
        model_q.push_back(item);
        model_count = model_count + 1;
        done = 1'b1;
      end
    end

    // Move away from the sampling edge before withdrawing the request.
    bfm_drive_point();
    push_req = 1'b0;

    active_req_name = "";
    active_req_desc = "";

    // R14
    check_status("R14");
  endtask

  // ---------------------------------------------------------------------------
  // R5 -- grant must remain low while the store is full.
  // ---------------------------------------------------------------------------

  task automatic check_push_blocked_when_full(
    input tag_t     tag_v,
    input payload_t data_v
  );
    automatic int i;
    automatic logic sampled_gnt;

    sampled_gnt = 1'b0;

    bfm_drive_point();
    push_tag  = tag_v;
    push_data = data_v;
    push_req  = 1'b1;

    for (i = 0; i < 4; i = i + 1) begin
      bfm_tick();
      sampled_gnt = push_gnt;

      if (sampled_gnt !== 1'b0) begin
        note_fail(
          "R5",
          $sformatf(
            "push_gnt_o asserted while occupancy was SLOTS=%0d",
            SLOTS_P
          )
        );
      end
    end

    bfm_drive_point();
    push_req = 1'b0;

    check_status("R14");
  endtask

  // ---------------------------------------------------------------------------
  // Pop transaction
  //
  // The expected entry is selected by bookkeeping: the first modeled entry
  // having the requested tag.  No cross-tag ordering is assumed.
  //
  // Two response snapshots are retained:
  //   pre_*  : values visible at the completing sampling edge
  //   post_* : values visible later in the same cycle
  //
  // Accepting either permits combinational or registered response timing
  // without imposing an out-of-scope timing choice.
  // ---------------------------------------------------------------------------

  task automatic pop_once(
    input tag_t  tag_v,
    input logic  remove_v,
    input string valid_req_name,
    input string data_req_name
  );
    automatic int       i;
    automatic int       found_idx;
    automatic logic     done;
    automatic logic     sampled_gnt;
    automatic logic     want_valid;
    automatic payload_t want_data;

    automatic logic     pre_valid;
    automatic payload_t pre_data;
    automatic logic     post_valid;
    automatic payload_t post_data;

    automatic logic     pre_ok;
    automatic logic     post_ok;

    found_idx   = -1;
    done        = 1'b0;
    sampled_gnt = 1'b0;
    want_valid  = 1'b0;
    want_data   = '0;

    pre_valid   = 1'b0;
    pre_data    = '0;
    post_valid  = 1'b0;
    post_data   = '0;

    pre_ok      = 1'b0;
    post_ok     = 1'b0;

    // R2/R8: oldest entry for THIS tag only.
    for (i = 0; i < model_q.size(); i = i + 1) begin
      if ((found_idx < 0) && (model_q[i].tag == tag_v)) begin
        found_idx = i;
      end
    end

    if (found_idx >= 0) begin
      want_valid = 1'b1;
      want_data  = model_q[found_idx].data;
    end

    active_req_name = "R7";
    active_req_desc = $sformatf("waiting for pop grant, tag %0d", tag_v);

    bfm_drive_point();
    pop_tag = tag_v;
    pop_en  = remove_v;
    pop_req = 1'b1;

    while (!done) begin
      bfm_tick();

      sampled_gnt = pop_gnt;

      if (sampled_gnt) begin
        // Snapshot response at the completing edge.
        pre_valid = pop_data_valid;
        pre_data  = pop_data;
        done      = 1'b1;
      end
    end

    // Snapshot again later in the same cycle before changing the request.
    bfm_drive_point();

    post_valid = pop_data_valid;
    post_data  = pop_data;

    pop_req = 1'b0;
    pop_en  = 1'b0;

    active_req_name = "";
    active_req_desc = "";

    // R8/R10.  pop_data_o is explicitly ignored whenever valid is low.
    if (want_valid) begin
      pre_ok  = ((pre_valid  === 1'b1) && (pre_data  === want_data));
      post_ok = ((post_valid === 1'b1) && (post_data === want_data));

      if (!(pre_ok || post_ok)) begin
        if ((pre_valid !== 1'b1) && (post_valid !== 1'b1)) begin
          note_fail(
            valid_req_name,
            $sformatf(
              "pop tag %0d did not return valid for an existing entry",
              tag_v
            )
          );
        end
        else begin
          note_fail(
            data_req_name,
            $sformatf(
              "pop tag %0d did not return oldest payload 0x%08x "
              // continued below
              ,
              tag_v,
              want_data
            )
          );
        end
      end
    end
    else begin
      // For an absent tag, both reasonable observation points must not claim
      // a valid entry.  pop_data itself is intentionally never inspected.
      if ((pre_valid === 1'b1) || (post_valid === 1'b1)) begin
        note_fail(
          valid_req_name,
          $sformatf(
            "pop tag %0d reported valid although that tag had no entries",
            tag_v
          )
        );
      end
    end

    // R9: state changes only for a valid completing removal.
    if (remove_v && want_valid) begin
      model_q.delete(found_idx);
      model_count = model_count - 1;
    end

    // R14
    check_status("R14");
  endtask

  // ---------------------------------------------------------------------------
  // Search transaction
  // ---------------------------------------------------------------------------

  task automatic search_once(
    input payload_t data_v,
    input payload_t mask_v,
    input string    req_name
  );
    automatic int   i;
    automatic logic done;
    automatic logic sampled_gnt;
    automatic logic want_hit;
    automatic logic pre_hit;
    automatic logic post_hit;

    done        = 1'b0;
    sampled_gnt = 1'b0;
    want_hit    = 1'b0;
    pre_hit     = 1'b0;
    post_hit    = 1'b0;

    // R12: existential masked comparison over every stored payload,
    // independent of tag.
    for (i = 0; i < model_q.size(); i = i + 1) begin
      if (
        (model_q[i].data & mask_v) ==
        (data_v          & mask_v)
      ) begin
        want_hit = 1'b1;
      end
    end

    active_req_name = "R11";
    active_req_desc = "waiting for search grant";

    bfm_drive_point();

    match_data[0] = data_v;
    match_mask[0] = mask_v;
    match_req[0]  = 1'b1;

    while (!done) begin
      bfm_tick();

      sampled_gnt = match_gnt[0];

      if (sampled_gnt) begin
        pre_hit = match_hit[0];
        done    = 1'b1;
      end
    end

    bfm_drive_point();

    post_hit = match_hit[0];
    match_req[0] = 1'b0;

    active_req_name = "";
    active_req_desc = "";

    // Permit either combinational or registered presentation within the
    // completion cycle.
    if (!((pre_hit === want_hit) || (post_hit === want_hit))) begin
      note_fail(
        req_name,
        $sformatf(
          "search data=0x%08x mask=0x%08x did not return expected hit=%0b",
          data_v, mask_v, want_hit
        )
      );
    end
  endtask

  // ---------------------------------------------------------------------------
  // R15 reset while state is live.
  // ---------------------------------------------------------------------------

  task automatic reset_store_and_check();
    active_req_name = "R15";
    active_req_desc = "performing reset";

    bfm_drive_point();

    push_req  = 1'b0;
    pop_req   = 1'b0;
    pop_en    = 1'b0;
    match_req = '0;
    rst_n     = 1'b0;

    repeat (4) begin
      bfm_tick();
    end

    // Observe away from the sampling edge while reset remains asserted.
    bfm_drive_point();

    model_q.delete();
    model_count = 0;

    if (empty !== 1'b1) begin
      note_fail(
        "R15",
        "empty_o was not high after reset emptied the store"
      );
    end

    if (full !== 1'b0) begin
      note_fail(
        "R15",
        "full_o was not low after reset emptied the store"
      );
    end

    // Release reset at the safe drive point.
    rst_n = 1'b1;

    // Observe after a released sampling edge and away from that edge.
    bfm_tick();
    bfm_drive_point();

    if (empty !== 1'b1) begin
      note_fail(
        "R15",
        "empty_o was not high after reset release"
      );
    end

    if (full !== 1'b0) begin
      note_fail(
        "R15",
        "full_o was not low after reset release"
      );
    end

    active_req_name = "";
    active_req_desc = "";
  endtask

  // ---------------------------------------------------------------------------
  // Main test
  // ---------------------------------------------------------------------------

  initial begin : main_test
    automatic int i;

    fail_count      = 0;
    model_count     = 0;
    active_req_name = "";
    active_req_desc = "";

    model_q.delete();

    push_tag  = '0;
    push_data = '0;
    push_req  = 1'b0;

    match_data = '0;
    match_mask = '0;
    match_req  = '0;

    pop_tag = '0;
    pop_en  = 1'b0;
    pop_req = 1'b0;

    // -------------------------------------------------------------------------
    // R15: initial reset.
    // -------------------------------------------------------------------------

    active_req_name = "R15";
    active_req_desc = "performing initial reset";

    bfm_reset();

    model_q.delete();
    model_count = 0;

    // Do not inspect in the same timestep as reset release.
    bfm_tick();
    bfm_drive_point();

    if (empty !== 1'b1) begin
      note_fail(
        "R15",
        "empty_o was not high after initial reset"
      );
    end

    if (full !== 1'b0) begin
      note_fail(
        "R15",
        "full_o was not low after initial reset"
      );
    end

    active_req_name = "";
    active_req_desc = "";

    // -------------------------------------------------------------------------
    // R4: with no push handshake, changing push inputs must not create state.
    // R14 provides the direct occupancy observation.
    // -------------------------------------------------------------------------

    bfm_drive_point();
    push_req  = 1'b0;
    push_tag  = 3'd6;
    push_data = 32'h1111_2222;

    bfm_tick();

    bfm_drive_point();
    push_tag  = 3'd2;
    push_data = 32'h3333_4444;

    bfm_tick();

    bfm_drive_point();

    if (empty !== 1'b1) begin
      note_fail(
        "R4",
        "store became non-empty without a push_req_i && push_gnt_o handshake"
      );
    end

    if (full !== 1'b0) begin
      note_fail(
        "R14",
        "full_o asserted while modeled occupancy was zero"
      );
    end

    // -------------------------------------------------------------------------
    // R10: an empty-tag pop is legal and returns valid low.
    // pop_data_o is deliberately not checked.
    // -------------------------------------------------------------------------

    pop_once(
      3'd5,
      1'b1,
      "R10",
      "R10"
    );

    // -------------------------------------------------------------------------
    // R12: zero mask over an empty store has no matching entry.
    // -------------------------------------------------------------------------

    search_once(
      32'hDEAD_BEEF,
      32'h0000_0000,
      "R12"
    );

    // -------------------------------------------------------------------------
    // R1: all SLOTS entries must be usable by ONE tag.
    // -------------------------------------------------------------------------

    for (i = 0; i < SLOTS_P; i = i + 1) begin
      push_one(
        3'd3,
        32'h1000_0000 + i,
        "R1"
      );
    end

    // R5: no additional push grant while at exact capacity.
    check_push_blocked_when_full(
      3'd4,
      32'hDEAD_BEEF
    );

    // -------------------------------------------------------------------------
    // R2/R8: same-tag entries must leave in FIFO order.
    // -------------------------------------------------------------------------

    for (i = 0; i < SLOTS_P; i = i + 1) begin
      pop_once(
        3'd3,
        1'b1,
        "R8",
        "R2"
      );
    end

    // R10 after draining that tag.
    pop_once(
      3'd3,
      1'b1,
      "R10",
      "R10"
    );

    // -------------------------------------------------------------------------
    // R9: inspection must not remove.
    // -------------------------------------------------------------------------

    push_one(
      3'd1,
      32'hAAAA_0001,
      "R1"
    );

    push_one(
      3'd1,
      32'hBBBB_0002,
      "R1"
    );

    // Inspect A; it remains present.
    pop_once(
      3'd1,
      1'b0,
      "R8",
      "R2"
    );

    // Must still remove A, not B.
    pop_once(
      3'd1,
      1'b1,
      "R9",
      "R9"
    );

    // B is now oldest, but this is another inspection.
    pop_once(
      3'd1,
      1'b0,
      "R9",
      "R9"
    );

    // B must still be present and removable.
    pop_once(
      3'd1,
      1'b1,
      "R9",
      "R9"
    );

    // Re-isolate state before the interleaved-tag test.
    reset_store_and_check();

    // -------------------------------------------------------------------------
    // R2/R3/R8:
    // Interleave tags, then request them in an order different from global
    // insertion order.  This checks only FIFO ordering WITHIN each requested
    // tag; no cross-tag removal order is assumed.
    // -------------------------------------------------------------------------

    push_one(3'd0, 32'hA000_0000, "R1");
    push_one(3'd1, 32'hB000_0000, "R1");
    push_one(3'd0, 32'hA000_0001, "R1");
    push_one(3'd1, 32'hB000_0001, "R1");

    // Globally A0 is oldest, but requesting tag 1 must return B0.
    pop_once(
      3'd1,
      1'b1,
      "R8",
      "R2"
    );

    // Oldest tag-0 entry is A0.
    pop_once(
      3'd0,
      1'b1,
      "R8",
      "R2"
    );

    // Remaining tag-1 entry is B1.
    pop_once(
      3'd1,
      1'b1,
      "R8",
      "R2"
    );

    // Remaining tag-0 entry is A1.
    pop_once(
      3'd0,
      1'b1,
      "R8",
      "R2"
    );

    reset_store_and_check();

    // -------------------------------------------------------------------------
    // Search population across several tags.
    // -------------------------------------------------------------------------

    push_one(3'd0, 32'h1234_5678, "R1");
    push_one(3'd1, 32'hA5A5_5A5A, "R1");
    push_one(3'd2, 32'hFFFF_0000, "R1");
    push_one(3'd0, 32'h0000_ABCD, "R1");

    // R12 exact hit.
    search_once(
      32'hA5A5_5A5A,
      32'hFFFF_FFFF,
      "R12"
    );

    // R12 exact miss.
    search_once(
      32'hDEAD_BEEF,
      32'hFFFF_FFFF,
      "R12"
    );

    // R12 partial-mask hit.
    search_once(
      32'h1234_9999,
      32'hFFFF_0000,
      "R12"
    );

    // R12 partial-mask miss.
    search_once(
      32'h5678_9999,
      32'hFFFF_0000,
      "R12"
    );

    // R12 lower-half partial-mask hit.
    search_once(
      32'hFFFF_ABCD,
      32'h0000_FFFF,
      "R12"
    );

    // R13: zero mask must hit whenever the store is non-empty.
    search_once(
      32'hCAFE_BABE,
      32'h0000_0000,
      "R13"
    );

    // -------------------------------------------------------------------------
    // R10: absent requested tag remains invalid even though other tags exist.
    // -------------------------------------------------------------------------

    pop_once(
      3'd7,
      1'b1,
      "R10",
      "R10"
    );

    // -------------------------------------------------------------------------
    // R1: use the remaining four slots with four more tags.  This verifies
    // capacity is shared across arbitrary tag distributions rather than being
    // partitioned into a smaller fixed capacity per tag.
    // -------------------------------------------------------------------------

    push_one(3'd3, 32'h3000_0003, "R1");
    push_one(3'd4, 32'h4000_0004, "R1");
    push_one(3'd5, 32'h5000_0005, "R1");
    push_one(3'd6, 32'h6000_0006, "R1");

    // R13 at full capacity.
    search_once(
      32'hFFFF_FFFF,
      32'h0000_0000,
      "R13"
    );

    // R5 at full mixed-tag occupancy.
    check_push_blocked_when_full(
      3'd7,
      32'h7777_7777
    );

    // -------------------------------------------------------------------------
    // R15: reset a full live store.
    // -------------------------------------------------------------------------

    reset_store_and_check();

    // -------------------------------------------------------------------------
    // Final result -- exactly one final RESULT line.
    // -------------------------------------------------------------------------

    if (fail_count == 0) begin
      $display("RESULT: PASS");
    end
    else begin
      $display("RESULT: FAIL");
    end

    $finish;
  end

endmodule