// =============================================================================
// tag_tracker_tb.sv
// -----------------------------------------------------------------------------
// Self-checking testbench for tag_tracker, TAG_W=3 SLOTS=8 N_MATCH=1,
// FULL_RATE=0, CUT_POP_PATH=0.
//
// How it decides things
// ---------------------
// A golden model holds the stored entries as a single queue of {tag,payload} in
// insertion order. Per-tag FIFO order (R2) falls out of scanning that queue
// front-to-back for a tag; cross-tag order (R3) is never consulted, so no check
// can depend on it.
//
// A transaction is deemed complete on the rising edge where its req and gnt are
// both high, and the response ports are sampled on THAT edge. Stimulus is only
// ever changed at the falling edge, so the design's inputs are stable across
// every edge that samples them and the values read back are the ones that were
// live during the cycle.
//
// Only ONE of push / pop / match is ever requested at a time. Arbitration
// between the three ports is out of scope, and asserting them together would
// make a withheld grant indistinguishable from a fault. This also keeps
// FULL_RATE=0 (no same-cycle push+pop of a tag) trivially satisfied.
//
// Deliberately NOT checked, because the spec leaves them free
// -----------------------------------------------------------
//   * Latency. Every wait is a bounded poll for gnt, never an assumption that
//     gnt arrives in any particular cycle.
//   * push_gnt_o being high merely because space exists (R6). A grant is only
//     ever *required* over a long window, and only for the request that is the
//     sole one outstanding; that is liveness, not a rate.
//   * pop_data_o when pop_data_valid_o is low (R10).
//   * empty_o / full_o during a transaction cycle, where a registered and a
//     combinational implementation legitimately differ (out of scope item 4).
//     They are sampled only in quiet cycles with all requests deasserted.
//   * Arbitration policy, internal structure, cross-tag ordering.
//
// Termination: every poll loop is bounded, and an independent watchdog reports
// failure and finishes regardless of what the design does. A design that never
// grants is reported as a failure, not a hang.
// =============================================================================

module tag_tracker_tb;

  // ---- configuration ---------------------------------------------------------
  localparam int TAG_W  = 3;
  localparam int SLOTS  = 8;
  localparam int NM     = 1;
  localparam int NTAGS  = 1 << TAG_W;
  localparam int TO_CYC = 200;   // generous bound on how long a grant may take

  typedef logic [31:0]      pl_t;
  typedef logic [TAG_W-1:0] tg_t;

// ---------------------------------------------------------------------------
// PROVIDED PLUMBING -- clock, reset and watchdog only.
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
  task automatic bfm_drive_point();
    @(negedge clk);
  endtask

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
// END OF PROVIDED PLUMBING
// ---------------------------------------------------------------------------

  // ---- DUT connections. The match ports are PACKED arrays; declared the same.
  tg_t          push_tag;
  pl_t          push_data;
  logic         push_req;
  logic         push_gnt;

  pl_t  [NM-1:0] match_data;
  pl_t  [NM-1:0] match_mask;
  logic [NM-1:0] match_req;
  logic [NM-1:0] match_hit;
  logic [NM-1:0] match_gnt;

  tg_t          pop_tag;
  logic         pop_en;
  logic         pop_req;
  pl_t          pop_data;
  logic         pop_dv;
  logic         pop_gnt;

  logic         full_w;
  logic         empty_w;

  initial begin
    push_tag  = '0;
    push_data = '0;
    push_req  = 1'b0;
    match_data = '0;
    match_mask = '0;
    match_req  = '0;
    pop_tag   = '0;
    pop_en    = 1'b0;
    pop_req   = 1'b0;
  end

  tag_tracker #(
    .TAG_W(TAG_W), .SLOTS(SLOTS), .FULL_RATE(1'b0), .CUT_POP_PATH(1'b0),
    .N_MATCH(NM), .payload_t(pl_t)
  ) dut (
    .clk_i(clk), .rst_ni(rst_n),
    .push_tag_i(push_tag), .push_data_i(push_data),
    .push_req_i(push_req), .push_gnt_o(push_gnt),
    .match_data_i(match_data), .match_mask_i(match_mask),
    .match_req_i(match_req), .match_hit_o(match_hit), .match_gnt_o(match_gnt),
    .pop_tag_i(pop_tag), .pop_en_i(pop_en), .pop_req_i(pop_req),
    .pop_data_o(pop_data), .pop_data_valid_o(pop_dv), .pop_gnt_o(pop_gnt),
    .full_o(full_w), .empty_o(empty_w)
  );

  // ---- golden model ----------------------------------------------------------
  typedef struct packed {
    tg_t tag;
    pl_t data;
  } ent_t;

  ent_t mstore [$];          // insertion order; per-tag order is the scan order

  int errors = 0;

  task automatic chk(input bit ok, input string req_id, input string msg);
    begin
      if (!ok) begin
        errors = errors + 1;
        if (errors <= 60)
          $display("FAIL [%s] t=%0t : %s", req_id, $time, msg);
      end
    end
  endtask

  // NOTE: the loop variable is deliberately not named `i`, and callers hoist
  // this call out of any loop condition. A function with a loop, invoked from
  // a loop CONDITION, is where this testbench previously wedged.
  function automatic int m_find(input tg_t t);
    int fi;
    begin
      m_find = -1;
      for (fi = 0; fi < mstore.size(); fi = fi + 1)
        if ((m_find < 0) && (mstore[fi].tag === t)) m_find = fi;
    end
  endfunction

  function automatic bit m_match(input pl_t d, input pl_t m);
    int mi;
    begin
      m_match = 1'b0;
      for (mi = 0; mi < mstore.size(); mi = mi + 1)
        if ((mstore[mi].data & m) === (d & m)) m_match = 1'b1;
    end
  endfunction

  // ---- bus tasks -------------------------------------------------------------
  task automatic quiet_inputs();
    begin
      push_req  = 1'b0;
      pop_req   = 1'b0;
      match_req = '0;
    end
  endtask

  // Push, polling for a grant. `granted` is 0 if none arrived within TO_CYC.
  task automatic do_push(input tg_t tag, input pl_t data, output bit granted);
    int t;
    ent_t e;
    begin
      granted = 1'b0;
      bfm_drive_point();
      quiet_inputs();
      push_tag  = tag;
      push_data = data;
      push_req  = 1'b1;
      for (t = 0; t < TO_CYC; t = t + 1) begin
        bfm_tick();
        if (push_gnt === 1'b1) begin
          granted = 1'b1;
          break;
        end
      end
      bfm_drive_point();
      push_req = 1'b0;
      if (granted) begin
        e.tag  = tag;
        e.data = data;
        mstore.push_back(e);
      end
    end
  endtask

  // Hold a push request for a short window and require that it is NOT granted.
  task automatic push_must_be_denied(input tg_t tag, input pl_t data,
                                     input int cycles, input string req_id,
                                     input string msg);
    int t;
    begin
      bfm_drive_point();
      quiet_inputs();
      push_tag  = tag;
      push_data = data;
      push_req  = 1'b1;
      for (t = 0; t < cycles; t = t + 1) begin
        bfm_tick();
        chk(push_gnt !== 1'b1, req_id, msg);
      end
      bfm_drive_point();
      push_req = 1'b0;
    end
  endtask

  // Pop / inspect. Samples pop_data_valid_o and pop_data_o on the granting edge.
  task automatic do_pop(input tg_t tag, input bit en, output bit granted,
                        output bit dvalid, output pl_t ddata);
    int t;
    begin
      granted = 1'b0;
      dvalid  = 1'b0;
      ddata   = '0;
      bfm_drive_point();
      quiet_inputs();
      pop_tag = tag;
      pop_en  = en;
      pop_req = 1'b1;
      for (t = 0; t < TO_CYC; t = t + 1) begin
        bfm_tick();
        if (pop_gnt === 1'b1) begin
          granted = 1'b1;
          dvalid  = pop_dv;
          ddata   = pop_data;
          break;
        end
      end
      bfm_drive_point();
      pop_req = 1'b0;
    end
  endtask

  // Search on port 0.
  task automatic do_match(input pl_t d, input pl_t m, output bit granted,
                          output bit hit);
    int t;
    begin
      granted = 1'b0;
      hit     = 1'b0;
      bfm_drive_point();
      quiet_inputs();
      match_data[0] = d;
      match_mask[0] = m;
      match_req[0]  = 1'b1;
      for (t = 0; t < TO_CYC; t = t + 1) begin
        bfm_tick();
        if (match_gnt[0] === 1'b1) begin
          granted = 1'b1;
          hit     = match_hit[0];
          break;
        end
      end
      bfm_drive_point();
      match_req[0] = 1'b0;
    end
  endtask

  // R14: sampled only with every request deasserted, so a registered and a
  // combinational implementation agree here.
  task automatic check_status(input string ctx);
    begin
      bfm_drive_point();
      quiet_inputs();
      bfm_tick();
      bfm_tick();
      chk(empty_w === (mstore.size() == 0), "R14",
          $sformatf("%s: empty_o=%b with %0d entries stored", ctx, empty_w, mstore.size()));
      chk(full_w === (mstore.size() == SLOTS), "R14",
          $sformatf("%s: full_o=%b with %0d entries stored", ctx, full_w, mstore.size()));
    end
  endtask

  // Quiet sample of the status ports, for checks that need the VALUE rather
  // than a comparison against the model.
  task automatic sample_status(output bit e, output bit f);
    begin
      bfm_drive_point();
      quiet_inputs();
      bfm_tick();
      bfm_tick();
      e = empty_w;
      f = full_w;
    end
  endtask

  // ---- composite helpers -----------------------------------------------------
  // A push that the model says there is room for. Not granting it at all,
  // for TO_CYC cycles with nothing else requested, is a capacity failure.
  task automatic push_expect_ok(input tg_t tag, input pl_t data, input string ctx);
    bit g;
    begin
      do_push(tag, data, g);
      chk(g, "R1", $sformatf("%s: push of tag %0d never granted in %0d cycles with %0d/%0d slots used",
                             ctx, tag, TO_CYC, mstore.size(), SLOTS));
    end
  endtask

  // A pop/inspect checked against the model.
  task automatic pop_expect(input tg_t tag, input bit en, input string ctx);
    bit  g, dv;
    pl_t dd;
    int  idx;
    bit  exp_dv;
    pl_t exp_d;
    begin
      idx    = m_find(tag);
      exp_dv = (idx >= 0);
      exp_d  = (idx >= 0) ? mstore[idx].data : '0;
      do_pop(tag, en, g, dv, dd);
      chk(g, "R7", $sformatf("%s: pop of tag %0d never granted in %0d cycles", ctx, tag, TO_CYC));
      if (g) begin
        chk(dv === exp_dv, "R8",
            $sformatf("%s: pop tag %0d gave pop_data_valid_o=%b, model says %b (%0d entries of that tag)",
                      ctx, tag, dv, exp_dv, (idx >= 0) ? 1 : 0));
        if (exp_dv && dv) begin
          // R2: the oldest entry for this tag, and only that one
          chk(dd === exp_d, "R2",
              $sformatf("%s: pop tag %0d returned %08h, oldest entry for that tag is %08h",
                        ctx, tag, dd, exp_d));
        end
        // R9: removal only when pop_en_i is high AND the entry existed
        if (en && exp_dv && dv) mstore.delete(idx);
      end
    end
  endtask

  task automatic match_expect(input pl_t d, input pl_t m, input string req_id,
                              input string ctx);
    bit g, h;
    bit exp_h;
    begin
      exp_h = m_match(d, m);
      do_match(d, m, g, h);
      chk(g, "R11", $sformatf("%s: search never granted in %0d cycles", ctx, TO_CYC));
      if (g)
        chk(h === exp_h, req_id,
            $sformatf("%s: search data=%08h mask=%08h gave hit=%b, model says %b (%0d entries stored)",
                      ctx, d, m, h, exp_h, mstore.size()));
    end
  endtask

  // ---- test program ----------------------------------------------------------
  initial begin
    int  i, j, k, op, idx2;
    bit  g, dv, h;
    pl_t dd;
    tg_t tg;
    pl_t pd, pm;
    pl_t seen_first;
    pl_t seen_second;
    bit  bit_e, bit_f;

    bfm_reset(4);

    // -------------------------------------------------------------- R15 ------
    bfm_drive_point();
    quiet_inputs();
    bfm_tick();
    bfm_tick();
    chk(empty_w === 1'b1, "R15", "empty_o not high after reset release");
    chk(full_w  === 1'b0, "R15", "full_o not low after reset release");

    // -------------------------------------------------- R1 / R14 / R5 --------
    // Capacity with every entry carrying the SAME tag.
    for (i = 0; i < SLOTS; i = i + 1) begin
      push_expect_ok(3, 32'hA000_0000 + i, "fill-same-tag");
      if (i == 0) check_status("after first push");
    end
    check_status("full with one tag");
    chk(full_w === 1'b1, "R14", "full_o low after SLOTS pushes of one tag");

    // R5: no grant while the store is full.
    push_must_be_denied(5, 32'hDEAD_0001, 12, "R5",
                        "push_gnt_o high while the store holds SLOTS entries");
    check_status("after denied push");

    // -------------------------------------------------------------- R9 -------
    // Removal is governed by pop_en_i, and it is tested against OCCUPANCY, not
    // only against the next value read back: a design that removes on an
    // inspect and one that never removes at all both corrupt the data stream,
    // but the clause they break is this one.
    do_pop(3, 1'b0, g, dv, dd);
    chk(g,            "R7", "inspect of the full store never granted");
    chk(dv === 1'b1,  "R8", "inspect of tag 3 gave pop_data_valid_o low with 8 entries of that tag");
    if (g && dv)
      chk(dd === 32'hA000_0000, "R2",
          $sformatf("inspect of tag 3 returned %08h, oldest is a0000000", dd));
    seen_first = dd;

    // Occupancy is probed through the PUSH path, not through full_o, so that a
    // wrong full_o is reported as R14 and a wrong removal as R9 rather than the
    // two clauses shadowing each other.
    push_must_be_denied(5, 32'hDEAD_0003, 6, "R9",
        "a push was granted after an inspect -- a pop with pop_en_i LOW must not free a slot");

    do_pop(3, 1'b0, g, dv, dd);
    chk(g, "R7", "second inspect never granted");
    if (g && dv)
      chk(dd === seen_first, "R9",
          $sformatf("two consecutive inspects returned %08h then %08h", seen_first, dd));

    pop_expect(3, 1'b1, "R9-remove");
    do_push(3, 32'hA000_0008, g);
    chk(g, "R9",
        "no push was granted after a pop with pop_en_i HIGH -- the entry was not removed");

    // -------------------------------------------------------------- R2 -------
    // Drain: same tag, so this is per-tag FIFO order end to end.
    for (i = 0; i < SLOTS; i = i + 1)
      pop_expect(3, 1'b1, "drain-same-tag");
    check_status("after draining one tag");
    chk(empty_w === 1'b1, "R14", "empty_o low after draining every entry");

    // ------------------------------------------------------------- R10 -------
    // A tag with no entries completes with pop_data_valid_o low; pop_data_o is
    // unconstrained here and is not examined.
    pop_expect(4, 1'b1, "pop-empty-tag-en1");
    pop_expect(4, 1'b0, "pop-empty-tag-en0");
    check_status("after popping an empty tag");

    // ---------------------------------------------------- R1 / R2 mixed ------
    // Capacity spread across tags, then per-tag drain in an order that
    // interleaves tags. Nothing here depends on order BETWEEN tags (R3).
    push_expect_ok(0, 32'h1000_0000, "mixed");
    push_expect_ok(1, 32'h1100_0000, "mixed");
    push_expect_ok(1, 32'h1100_0001, "mixed");
    push_expect_ok(2, 32'h1200_0000, "mixed");
    push_expect_ok(2, 32'h1200_0001, "mixed");
    push_expect_ok(2, 32'h1200_0002, "mixed");
    push_expect_ok(7, 32'h1700_0000, "mixed");
    push_expect_ok(7, 32'h1700_0001, "mixed");
    check_status("full across tags");
    chk(full_w === 1'b1, "R14", "full_o low after SLOTS pushes across tags");
    push_must_be_denied(6, 32'hDEAD_0002, 8, "R5",
                        "push_gnt_o high while full (mixed tags)");

    // ------------------------------------------------------- R9 / R8 ---------
    // Inspect without removing: twice in a row must give the same entry and
    // must not change occupancy.
    do_pop(2, 1'b0, g, dv, dd);
    chk(g, "R7", "inspect of tag 2 never granted");
    chk(dv === 1'b1, "R8", "inspect of tag 2 gave pop_data_valid_o low");
    seen_first = dd;
    if (g && dv)
      chk(dd === 32'h1200_0000, "R2", $sformatf("inspect tag 2 returned %08h, oldest is 12000000", dd));
    check_status("after inspect (pop_en low)");
    chk(full_w === 1'b1, "R9", "occupancy changed by a pop with pop_en_i low");

    do_pop(2, 1'b0, g, dv, dd);
    chk(g, "R7", "second inspect of tag 2 never granted");
    if (g) begin
      chk(dv === 1'b1, "R8", "second inspect of tag 2 gave pop_data_valid_o low");
      chk(dd === seen_first, "R9",
          $sformatf("entry changed between two inspects (%08h then %08h) -- pop_en_i low must not remove",
                    seen_first, dd));
    end

    // Now remove it and confirm the next-oldest of that tag surfaces (R2/R9).
    pop_expect(2, 1'b1, "remove-tag2-first");
    do_pop(2, 1'b0, g, dv, dd);
    chk(g, "R7", "inspect after removal never granted");
    if (g) begin
      chk(dv === 1'b1, "R8", "inspect after removal gave pop_data_valid_o low");
      seen_second = dd;
      chk(dd === 32'h1200_0001, "R2",
          $sformatf("after removing the oldest of tag 2, inspect returned %08h, expected 12000001", dd));
    end
    check_status("after one removal");

    // ------------------------------------------------------- R12 / R13 -------
    // Store now holds: 10000000, 11000000, 11000001, 12000001, 12000002,
    //                  17000000, 17000001
    match_expect(32'h1100_0001, 32'hFFFF_FFFF, "R12", "exact hit on a stored payload");
    match_expect(32'h1700_0001, 32'hFFFF_FFFF, "R12", "exact hit on another stored payload");
    match_expect(32'h1200_0000, 32'hFFFF_FFFF, "R12", "exact miss on a removed payload");
    match_expect(32'hDEAD_BEEF, 32'hFFFF_FFFF, "R12", "exact miss on a never-stored payload");
    // masked: top byte 0x17 present, 0x99 absent
    match_expect(32'h1700_0000, 32'hFF00_0000, "R12", "masked hit on the tag-7 payloads");
    match_expect(32'h9900_0000, 32'hFF00_0000, "R12", "masked miss on an absent prefix");
    // a mask that ignores exactly the bits that differ
    match_expect(32'h1100_00FF, 32'hFFFF_FF00, "R12", "masked hit ignoring the low byte");
    match_expect(32'h1300_00FF, 32'hFFFF_FF00, "R12", "masked miss ignoring the low byte");
    // R13: an all-zero mask matches anything, so hit iff non-empty
    match_expect(32'h0000_0000, 32'h0000_0000, "R13", "zero mask, store non-empty");
    match_expect(32'hFFFF_FFFF, 32'h0000_0000, "R13", "zero mask with unrelated data, store non-empty");

    // drain everything, then the zero-mask search must miss
    for (i = 0; i < NTAGS; i = i + 1) begin
      k = 0;
      idx2 = m_find(tg_t'(i));
      while ((idx2 >= 0) && (k < SLOTS + 2)) begin
        pop_expect(tg_t'(i), 1'b1, "drain-all");
        k = k + 1;
        idx2 = m_find(tg_t'(i));
      end
      chk(m_find(tg_t'(i)) < 0, "R9",
          $sformatf("tag %0d still holds entries after %0d removing pops", i, k));
    end
    check_status("after draining everything");
    match_expect(32'h0000_0000, 32'h0000_0000, "R13", "zero mask, store empty");
    match_expect(32'h1100_0000, 32'hFFFF_FFFF, "R12", "exact search on an empty store");

    // ------------------------------------------------------------- R15 -------
    // Reset with entries in the store: it must come back empty.
    for (i = 0; i < 5; i = i + 1)
      push_expect_ok(tg_t'(i % 4), 32'hB000_0000 + i, "prefill-before-reset");
    check_status("before mid-run reset");
    bfm_reset(4);
    mstore.delete();
    bfm_drive_point();
    quiet_inputs();
    bfm_tick();
    bfm_tick();
    chk(empty_w === 1'b1, "R15", "empty_o not high after a reset with entries stored");
    chk(full_w  === 1'b0, "R15", "full_o high after a reset with entries stored");
    for (i = 0; i < 4; i = i + 1)
      pop_expect(tg_t'(i), 1'b1, "post-reset-drain");
    match_expect(32'h0000_0000, 32'h0000_0000, "R13", "zero mask after reset");

    // --------------------------------------------------- randomised mix ------
    // Model-driven, one operation at a time, every response checked.
    for (i = 0; i < 500; i = i + 1) begin
      op = $urandom_range(0, 9);
      if (op <= 3) begin
        tg = tg_t'($urandom_range(0, NTAGS-1));
        // small, colliding payload space so masked searches see real hits
        pd = (pl_t'($urandom_range(0, 7)) << 24) | pl_t'($urandom_range(0, 255));
        if (mstore.size() < SLOTS) push_expect_ok(tg, pd, "rand-push");
        else push_must_be_denied(tg, pd, 4, "R5", "rand: push granted while full");
      end else if (op <= 7) begin
        tg = tg_t'($urandom_range(0, NTAGS-1));
        pop_expect(tg, $urandom_range(0, 1), "rand-pop");
      end else begin
        pd = pl_t'($urandom_range(0, 255));
        pm = ($urandom_range(0, 3) == 0) ? 32'h0 :
             (($urandom_range(0, 1) == 0) ? 32'hFFFF_FFFF : 32'h0000_00FF);
        match_expect(pd, pm, (pm == 32'h0) ? "R13" : "R12", "rand-search");
      end
      if ((i % 25) == 0) check_status("rand");
    end
    check_status("end of randomised mix");

    // ---- verdict --------------------------------------------------------------
    if (errors == 0) $display("RESULT: PASS");
    else             $display("RESULT: FAIL");
    $finish;
  end

endmodule