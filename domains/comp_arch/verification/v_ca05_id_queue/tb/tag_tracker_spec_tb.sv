// =============================================================================
// tag_tracker_spec_tb -- PILOT: written from spec/tag_tracker_spec.md ALONE.
// =============================================================================
// Protocol for this pilot: the DUT body was not opened while writing this file.
// Every check below cites the requirement it enforces, and NO check exists that
// cannot be traced to a numbered requirement. That constraint is the point --
// it prevents smuggling in "obvious" behaviour that the spec never stated,
// which is exactly the leakage the pilot is trying to measure.
// =============================================================================
`timescale 1ns/1ps

// The DUT module name is overridable so the SAME testbench can be run against
// the golden and against each conformant perturbation. Ordinary mutants must be
// killed; these must SURVIVE.
`ifndef DUT_MODULE
  `define DUT_MODULE tag_tracker
`endif

module tag_tracker_tb;   // name required by the scoring path

  localparam int TAG_W = 3;
  localparam int SLOTS = 8;
  localparam int NM    = 1;
  localparam int NTAG  = 1 << TAG_W;

  typedef logic [31:0] payload_t;

  logic clk = 1'b0;
  logic rst_n = 1'b0;
  always #5 clk = ~clk;

  logic [TAG_W-1:0]  push_tag;
  payload_t          push_data;
  logic              push_req, push_gnt;

  payload_t [NM-1:0] match_data, match_mask;
  logic     [NM-1:0] match_req, match_hit, match_gnt;

  logic [TAG_W-1:0]  pop_tag;
  logic              pop_en, pop_req;
  // ---- COVERAGE, and this testbench had NONE ------------------------------
  // Measured: no cov_ counter and no fail("FLOOR") anywhere in this file, so
  // nothing asserted that its own stimulus reached anything. Six clause ids are
  // emittable of fifteen stated, and FOUR MORE are grouped -- R2, R9 and R10
  // report under R8, R13 under R12 -- which means their antecedents are the only
  // thing standing between those clauses and being unexercised, and no floor was
  // watching them. Grouped plus unguarded is the pair that covers for itself:
  // grouping hides WHICH clause was tested, an unguarded antecedent hides
  // WHETHER ANYTHING was, and the floor that would read zero sits on the other
  // clause and is satisfied.
  //
  // These four count the antecedents of the four grouped clauses. They are
  // driven today -- by inspection of the source, not by measurement, which is
  // exactly the gap: nothing would notice if an edit removed them.
  int cov_peek = 0;        // R9  -- a pop with pop_en_i low on a PRESENT entry
  int cov_pop_absent = 0;  // R10 -- a pop of a tag with no entries
  int cov_zero_mask = 0;   // R13 -- an all-zero mask against a NON-EMPTY store
  int cov_order = 0;       // R2  -- a pop from a tag holding two or more
  int cov_reset_nonempty = 0; // R15 -- a reset asserted on a NON-EMPTY store
  payload_t          pop_data;
  logic              pop_data_valid, pop_gnt;

  logic              full, empty;

  `DUT_MODULE #(
      .TAG_W(TAG_W), .SLOTS(SLOTS), .N_MATCH(NM), .payload_t(payload_t)
  ) dut (
      .clk_i(clk), .rst_ni(rst_n),
      .push_tag_i(push_tag), .push_data_i(push_data),
      .push_req_i(push_req), .push_gnt_o(push_gnt),
      .match_data_i(match_data), .match_mask_i(match_mask),
      .match_req_i(match_req), .match_hit_o(match_hit), .match_gnt_o(match_gnt),
      .pop_tag_i(pop_tag), .pop_en_i(pop_en), .pop_req_i(pop_req),
      .pop_data_o(pop_data), .pop_data_valid_o(pop_data_valid),
      .pop_gnt_o(pop_gnt),
      .full_o(full), .empty_o(empty)
  );

  // ---- reference model (R1, R2) -------------------------------------------
  payload_t ref_q [NTAG][$];
  int       ref_count;

  int errors;
  int checks;

  task automatic fail(input string req, input string msg);
    $display("[FAIL] %s : %s   (t=%0t)", req, msg, $time);
    errors++;
  endtask

  task automatic ok();
    checks++;
  endtask

  // ---- bus idle ------------------------------------------------------------
  task automatic idle();
    push_req = 1'b0; pop_req = 1'b0; match_req = '0; pop_en = 1'b0;
  endtask

  // ---- R4/R5: push, holding request until grant ---------------------------
  task automatic do_push(input logic [TAG_W-1:0] tg, input payload_t d,
                         input int timeout, output bit granted);
    int waited;
    granted = 1'b0;
    waited  = 0;
    push_tag = tg; push_data = d; push_req = 1'b1;
    while (waited < timeout) begin
      @(posedge clk);
      if (push_gnt) begin           // R4: commit on req && gnt
        granted = 1'b1;
        ref_q[tg].push_back(d);     // R2: per-tag FIFO order
        ref_count++;
        `ifdef PROBE
        $display("  [dbg] push commit t=%0t req=%b gnt=%b free=%b empty=%b",
                 $time, push_req, push_gnt, dut.linked_data_free, empty);
        `endif
        break;
      end
      waited++;
    end
    // Leave the sampling edge BEFORE changing stimulus. Deasserting in the
    // same timestep as the posedge races the DUT's sampling of it.
    @(negedge clk);
    push_req = 1'b0;
  endtask

  // ---- R7/R8/R9/R10: pop or peek ------------------------------------------
  task automatic do_pop(input logic [TAG_W-1:0] tg, input bit remove,
                        input int timeout);
    int  waited;
    bit  exp_valid;
    payload_t exp_data;
    waited  = 0;
    pop_tag = tg; pop_en = remove; pop_req = 1'b1;
    while (waited < timeout) begin
      @(posedge clk);
      if (pop_gnt) begin
        exp_valid = (ref_q[tg].size() != 0);          // R8
        // R8: valid high iff an entry with this tag is present
        if (pop_data_valid !== exp_valid) begin
          fail("R8", $sformatf("tag %0d: pop_data_valid=%0b expected %0b",
                               tg, pop_data_valid, exp_valid));
        end else ok();
        if (!exp_valid) cov_pop_absent++;             // R10's antecedent
        if (exp_valid) begin
          if (!remove)             cov_peek++;         // R9's antecedent
          if (ref_q[tg].size() > 1) cov_order++;       // R2's antecedent
          exp_data = ref_q[tg][0];                    // R8: oldest entry
          if (pop_data !== exp_data) begin
            fail("R8", $sformatf("tag %0d: pop_data=%08h expected %08h",
                                 tg, pop_data, exp_data));
          end else ok();
          // R9: removal only when pop_en_i is high
          if (remove) begin
            void'(ref_q[tg].pop_front());
            ref_count--;
          end
        end
        // R10: pop of absent tag completes, data unconstrained -- not checked
        break;
      end
      waited++;
    end
    @(negedge clk);
    pop_req = 1'b0; pop_en = 1'b0;
  endtask

  // ---- R11/R12/R13: search ------------------------------------------------
  function automatic bit ref_match(input payload_t d, input payload_t m);
    for (int t = 0; t < NTAG; t++)
      for (int i = 0; i < ref_q[t].size(); i++)
        if ((ref_q[t][i] & m) == (d & m)) return 1'b1;
    return 1'b0;
  endfunction

  task automatic do_match(input payload_t d, input payload_t m, input int timeout);
    int waited;
    bit exp_hit;
    waited = 0;
    match_data[0] = d; match_mask[0] = m; match_req[0] = 1'b1;
    while (waited < timeout) begin
      @(posedge clk);
      if (match_gnt[0]) begin
        if (m == '0 && ref_count > 0) cov_zero_mask++;  // R13's antecedent
        exp_hit = ref_match(d, m);                    // R12
        if (match_hit[0] !== exp_hit) begin
          fail("R12", $sformatf("data=%08h mask=%08h hit=%0b expected %0b",
                                d, m, match_hit[0], exp_hit));
        end else ok();
        break;
      end
      waited++;
    end
    @(negedge clk);
    match_req[0] = 1'b0;
  endtask

  task automatic ref_q_clear();
    for (int i = 0; i < NTAG; i++) ref_q[i].delete();
  endtask

  // ---- R14: status --------------------------------------------------------
  task automatic check_status(input string ctx);
    if (empty !== (ref_count == 0))
      fail("R14", $sformatf("%s: empty=%0b with %0d entries", ctx, empty, ref_count));
    else ok();
    if (full !== (ref_count == SLOTS))
      fail("R14", $sformatf("%s: full=%0b with %0d entries", ctx, full, ref_count));
    else ok();
  endtask

  // ---- stimulus ------------------------------------------------------------
  bit granted;
  payload_t d;
  int seed = 32'h5CA05;

  initial begin
    errors = 0; checks = 0; ref_count = 0;
    idle();
    push_tag = '0; push_data = '0; pop_tag = '0;
    match_data = '0; match_mask = '0;

    repeat (4) @(posedge clk);
    rst_n = 1'b1;
    @(negedge clk);

    // ---- R15: reset state ------------------------------------------------
    if (empty !== 1'b1) fail("R15", "empty low after reset"); else ok();
    if (full  !== 1'b0) fail("R15", "full high after reset");  else ok();

    // ---- R10: pop from an empty store ------------------------------------
    do_pop(3'd0, 1'b1, 50);

    // ---- R1/R14/R5: fill to capacity on ONE tag --------------------------
    for (int i = 0; i < SLOTS; i++) begin
      d = payload_t'(32'hA000_0000 + i);
      do_push(3'd5, d, 50, granted);
      if (!granted) fail("R1", $sformatf("push %0d of %0d refused on one tag", i+1, SLOTS));
      else ok();
      check_status($sformatf("after push %0d", i+1));
    end

    // R14: full asserted at SLOTS
    if (full !== 1'b1) fail("R14", "full not asserted at SLOTS entries"); else ok();

    // R5: push must be refused when full
    push_tag = 3'd2; push_data = 32'hDEAD_BEEF; push_req = 1'b1;
    repeat (5) @(posedge clk);
    if (push_gnt !== 1'b0) fail("R5", "push granted while full"); else ok();
    @(negedge clk);
    push_req = 1'b0;

    // ---- R13: zero mask matches any stored entry -------------------------
    do_match(32'h0000_0000, 32'h0000_0000, 50);

    // ---- R12: exact match present and absent -----------------------------
    do_match(32'hA000_0003, 32'hFFFF_FFFF, 50);
    do_match(32'h1234_5678, 32'hFFFF_FFFF, 50);

    // ---- R9: peek does not remove ----------------------------------------
    do_pop(3'd5, 1'b0, 50);
    do_pop(3'd5, 1'b0, 50);
    check_status("after two peeks");

    // ---- R2/R8: drain in insertion order ---------------------------------
    for (int i = 0; i < SLOTS; i++) begin
      do_pop(3'd5, 1'b1, 50);
      check_status($sformatf("after pop %0d", i+1));
    end
    if (empty !== 1'b1) fail("R14", "not empty after draining every entry"); else ok();

    // ---- R9 AT THE BOUNDARY: peek a tag holding EXACTLY ONE entry ---------
    // The peek check above runs on a tag holding SLOTS entries, so a design
    // that destroys only the LAST entry of a tag passes it untouched. One
    // entry is the case R9 actually has to be checked at, and a mutant that
    // removes on peek only at that occupancy survived this testbench until
    // this phase was added.
    do_push(3'd2, 32'hFEED_0001, 50, granted);
    if (!granted) fail("R5", "push refused into an empty store");
    check_status("one entry on tag 2");
    do_pop(3'd2, 1'b0, 50);            // peek -- must not remove
    do_pop(3'd2, 1'b0, 50);            // peek again -- must still be there
    check_status("after peeking the only entry twice");
    do_pop(3'd2, 1'b1, 50);            // now remove it
    check_status("after removing the only entry");

    // ---- R1: EVERY tag must be accepted, not just the ones we happened to
    // use. Added after the mutant set showed this testbench could not see a
    // design that starves exactly one tag: the capacity fill used tag 5 and the
    // random phase never *required* a grant, so a permanently-refused tag was
    // invisible.
    //
    // Note what is and is not checked. R6 licenses push_gnt_o being low for
    // reasons other than fullness, so requiring an IMMEDIATE grant would be
    // checking something unpromised. What R1 does promise is that the entry is
    // eventually accepted while space exists -- so this waits, and fails only
    // on a timeout.
    for (int t = 0; t < NTAG; t++) begin
      d = payload_t'(32'hB000_0000 + t);
      do_push(TAG_W'(t), d, 50, granted);
      if (!granted)
        fail("R1", $sformatf("tag %0d never granted with %0d/%0d slots free -- starved",
                             t, SLOTS - ref_count, SLOTS));
      else ok();
    end
    for (int t = 0; t < NTAG; t++)
      while (ref_q[t].size() != 0) do_pop(TAG_W'(t), 1'b1, 50);
    check_status("after per-tag acceptance sweep");

    // ---- R12: a mask covering the TOP BYTE against a value that differs from
    // every stored entry ONLY there. The earlier searches used 0xFFFFFFFF,
    // 0x000000FF and 0x0, none of which can see a compare that silently drops
    // the high byte from the mask.
    //
    // R12 states the compare as (payload & mask) == (data & mask) for any mask,
    // so this is squarely within the contract rather than an inference from it.
    do_push(3'd2, 32'hA1B2_C3D4, 50, granted);
    do_match(32'h71B2_C3D4, 32'hFF00_0000, 50);   // differs only in [31:24]
    do_match(32'hA100_0000, 32'hFF00_0000, 50);   // matches in [31:24]
    do_pop(3'd2, 1'b1, 50);
    check_status("after high-byte mask search");

    // ---- R1/R2/R3: mixed tags, random traffic ----------------------------
    for (int n = 0; n < 400; n++) begin
      int op;
      logic [TAG_W-1:0] tg;
      op = $urandom(seed) % 3;
      tg = TAG_W'($urandom(seed) % NTAG);
      if (op == 0 && ref_count < SLOTS) begin
        d = payload_t'($urandom(seed));
        do_push(tg, d, 50, granted);
      end else if (op == 1) begin
        do_pop(tg, 1'b1, 50);
      end else begin
        do_match(payload_t'($urandom(seed)), 32'h0000_00FF, 50);
      end
      check_status("random");
    end

    // ---- the SAME clauses, at occupancies and repetitions the phases above
    // never construct -----------------------------------------------------
    // Every check here duplicates a clause already checked. What differs is
    // the configuration it is checked in: a half-full store rather than an
    // empty one, more than SLOTS/2 entries on one tag, a single-entry tag
    // peeked while the store is busy, a SECOND fill to capacity, and the
    // discriminating search run after the store has been searched many times.
    // A design that is correct in the easy configuration and wrong in these is
    // invisible to everything above.
    begin
      for (int t = 0; t < NTAG; t++)
        while (ref_q[t].size() != 0) do_pop(TAG_W'(t), 1'b1, 50);
      check_status("drained before the busy-store phase");

      // R1: entries are SHARED, not reserved per tag. More than SLOTS/2 on one
      // tag, with another tag present, is the case that separates a shared
      // pool from a per-tag quota.
      do_push(3'd7, 32'hC000_0000, 50, granted);
      if (!granted) fail("R1", "push refused into an empty store"); else ok();
      for (int i = 0; i < 6; i++) begin
        d = payload_t'(32'hC100_0000 + i);
        do_push(3'd0, d, 50, granted);
        if (!granted)
          fail("R1", $sformatf("entry %0d on tag 0 refused with %0d of %0d slots free -- entries are shared between tags, not reserved",
                               i+1, SLOTS - ref_count, SLOTS));
        else ok();
      end
      check_status("seven entries, six of them on one tag");

      // R9: a peek of a tag holding EXACTLY ONE entry, in a BUSY store. The
      // earlier boundary phase does this in a nearly empty one.
      do_pop(3'd7, 1'b0, 50);
      do_pop(3'd7, 1'b0, 50);
      check_status("after peeking a single-entry tag in a busy store");

      // R14: full_o on a SECOND fill to capacity. The first fill is the only
      // one anything above reaches.
      d = payload_t'(32'hC200_0000);
      do_push(3'd3, d, 50, granted);
      if (!granted) fail("R1", "the eighth entry was refused with the store not yet full");
      else ok();
      check_status("full for the SECOND time");

      // R12/R13: the discriminating high-byte search, run once the store has
      // already been searched many times.
      for (int k = 0; k < 10; k++)
        do_match(payload_t'(32'hC100_0000 + k), 32'h0000_00FF, 50);
      do_match(32'h71B2_C3D4, 32'hFF00_0000, 50);   // differs only in [31:24]
      do_match(32'hC100_0000, 32'hFF00_0000, 50);   // agrees in [31:24]

      for (int t = 0; t < NTAG; t++)
        while (ref_q[t].size() != 0) do_pop(TAG_W'(t), 1'b1, 50);
      check_status("drained after the busy-store phase");
    end

    // ---- drain everything -------------------------------------------------
    for (int t = 0; t < NTAG; t++)
      while (ref_q[t].size() != 0) do_pop(TAG_W'(t), 1'b1, 50);
    check_status("final drain");

    // ---- R15: RESET ON A NON-EMPTY STORE, WITH THE ANTECEDENT GATED -------
    // R15 says "while rst_ni is low the store shall be emptied; after release
    // empty_o shall be high and full_o low". Both halves were CHECKED -- lines
    // 201-202 read empty_o and full_o right after the initial reset -- and the
    // check was VACUOUS, because the only reset in this testbench happened on a
    // store that had never held anything. A design that ignores rst_ni entirely
    // passed it for the life of this task.
    //
    // R15 IS EMITTABLE AND IS EMITTED. The emittability scan reports it as fine
    // and it is fine, in the only sense that scan can measure: a fail() exists
    // that can name it. What the scan cannot see is that the observation behind
    // it is empty. A clause can be emittable, emitted, and unexercised.
    //
    // STEP 1 IS THE GATE. If the store is not actually non-empty when reset is
    // asserted, this phase reports that R15 WAS NEVER EXERCISED and fails,
    // rather than passing for the wrong reason -- which is the state it sat in
    // until now. Appended after the final drain, so no existing measurement
    // moves.
    for (int i = 0; i < 3; i++) begin
      do_push(3'd4, payload_t'(32'h_15_0000 + i), 50, granted);
      if (!granted) fail("R15", "could not fill the store to set up the reset test");
    end
    if (ref_count == 0 || empty !== 1'b0) begin
      fail("R15", $sformatf("R15 WAS NEVER EXERCISED: the store held %0d entries and empty_o=%0b when reset was about to be asserted. Resetting an already-empty store cannot distinguish a design that clears on reset from one that ignores it.", ref_count, empty));
    end else begin
      cov_reset_nonempty++;
      @(negedge clk) rst_n = 1'b0;
      repeat (4) @(posedge clk);
      @(negedge clk) rst_n = 1'b1;
      ref_q_clear(); ref_count = 0;
      repeat (2) @(posedge clk);
      if (empty !== 1'b1)
        fail("R15", "empty_o low after a reset that was asserted on a NON-EMPTY store -- the store was not emptied");
      else ok();
      if (full !== 1'b0)
        fail("R15", "full_o high after a reset asserted on a non-empty store");
      else ok();
      // and the entries must be gone, not merely uncounted
      do_pop(3'd4, 1'b1, 50);
    end

    // ---- FLOORS. The four clauses that report under another id ------------
    // Gated on the STIMULUS half only -- each counts an event this testbench
    // chooses to drive, and reads no design output, so none of them can reject
    // correct hardware.
    if (cov_peek < 2)
      fail("FLOOR", $sformatf("only %0d peek(s) driven -- R9 says an entry inspected with pop_en_i low is NOT removed, and it reports under R8; without a peek there is nothing to report", cov_peek));
    if (cov_pop_absent < 1)
      fail("FLOOR", "no pop of an absent tag was driven -- R10's only checkable half, that pop_data_valid_o is low, reports under R8 and goes unexercised");
    if (cov_zero_mask < 1)
      fail("FLOOR", "no all-zero mask was driven against a non-empty store -- R13 reports under R12 and is untested without one");
    if (cov_reset_nonempty < 1)
      fail("FLOOR", "no reset was asserted on a non-empty store -- R15 says the store SHALL BE EMPTIED, and resetting an empty one cannot tell a design that clears from one that ignores rst_ni");
    if (cov_order < 2)
      fail("FLOOR", $sformatf("only %0d pop(s) from a tag holding two or more -- R2's per-tag FIFO order reports under R8 and cannot be judged on a one-deep tag", cov_order));

    $display("");
    $display("checks passed : %0d", checks);
    $display("failures      : %0d", errors);
    $display("  [coverage] peek=%0d pop-absent=%0d zero-mask=%0d multi-deep pop=%0d",
             cov_peek, cov_pop_absent, cov_zero_mask, cov_order);
    // ---- FIRED: see check_fired.py. Absent is not zero (rule 20).
    $display("FIRED v_ca05.cov_peek %0d", cov_peek);
    $display("FIRED v_ca05.cov_pop_absent %0d", cov_pop_absent);
    $display("FIRED v_ca05.cov_zero_mask %0d", cov_zero_mask);
    $display("FIRED v_ca05.cov_order %0d", cov_order);
    $display("FIRED v_ca05.cov_reset_nonempty %0d", cov_reset_nonempty);
    if (errors == 0) $display("RESULT: PASS");
    else             $display("RESULT: FAIL");
    $finish;
  end

  initial begin
    #500000;
    $display("RESULT: TIMEOUT");
    $finish;
  end

endmodule
