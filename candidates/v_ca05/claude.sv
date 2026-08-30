// ===========================================================================
// tag_tracker_tb.sv -- self-checking testbench for tag_tracker.
//
// THE MODEL is two parallel queues holding (tag, payload) in global push order.
// The oldest entry for a tag is the first element found scanning from the
// front, so per-tag FIFO order falls out without an array of queues.  Every
// payload is a bijective hash of a counter and therefore unique, so a returned
// payload names exactly one pushed entry -- bookkeeping, not content matching.
//
// WHAT IS DELIBERATELY NOT CHECKED, because the specification frees it and a
// check would reject correct hardware:
//   R3   cross-tag ordering -- the model only ever asks for the oldest entry
//        OF THE REQUESTED TAG and never compares entries of different tags;
//   R6   push_gnt_o is never required high merely because space exists.  A
//        refusal is only ever reported after a long timeout with no other
//        request asserted, which is the "cannot accept SLOTS entries" case
//        that R1 does require;
//   R10  pop_data_o is never examined when pop_data_valid_o is low;
//   arbitration -- only ONE of push, pop and search is requested at a time, so
//        no arbitration policy between the ports is ever required.  That also
//        sidesteps FULL_RATE=0 (push and pop of one tag never coincide here)
//        and CUT_POP_PATH=0 (push_gnt_o may depend on pop_req_i);
//   latency -- every wait is a bounded retry loop, never a required cycle count.
//
// Per the specification's own grouping, the R8 check carries R2, R9 and R10,
// and the R12 check carries R13.
//
// TIMING: stimulus changes only after @(negedge clk); grants and outputs are
// sampled at @(posedge clk), which reads the pre-edge values -- the ones that
// were valid during the cycle the transfer completed on.  Status is read at a
// negedge with every request line already low, so no checker ever runs in the
// same timestep as a signal change.
// ===========================================================================

`timescale 1ns/1ps

module tag_tracker_tb;

  // ---- scored configuration ------------------------------------------------
  localparam int TAG_W   = 3;
  localparam int SLOTS   = 8;
  localparam int N_MATCH = 1;
  localparam int TMO     = 100;   // generous: only one request is ever asserted

  typedef logic [31:0] pay_t;

  // =========================================================================
  // PROVIDED PLUMBING -- clock, reset and watchdog only.
  // =========================================================================
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

  // =========================================================================
  // DUT connections.  The three match ports are PACKED, matching the port map.
  // =========================================================================
  logic [TAG_W-1:0]     push_tag;
  pay_t                 push_data;
  logic                 push_req;
  logic                 push_gnt;

  pay_t [N_MATCH-1:0]   match_data;
  pay_t [N_MATCH-1:0]   match_mask;
  logic [N_MATCH-1:0]   match_req;
  logic [N_MATCH-1:0]   match_hit;
  logic [N_MATCH-1:0]   match_gnt;

  logic [TAG_W-1:0]     pop_tag;
  logic                 pop_en;
  logic                 pop_req;
  pay_t                 pop_data;
  logic                 pop_data_valid;
  logic                 pop_gnt;

  logic                 dut_full;
  logic                 dut_empty;

  tag_tracker #(
    .TAG_W        (TAG_W),
    .SLOTS        (SLOTS),
    .FULL_RATE    (1'b0),
    .CUT_POP_PATH (1'b0),
    .N_MATCH      (N_MATCH),
    .payload_t    (pay_t)
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
    .full_o           (dut_full),
    .empty_o          (dut_empty)
  );

  // =========================================================================
  // Model and bookkeeping
  // =========================================================================
  int   mdl_tag [$];
  pay_t mdl_pay [$];

  int nerr;
  int nprint;

  task automatic fail(input string rq, input string msg);
    nerr = nerr + 1;
    if (nprint < 30) begin
      nprint = nprint + 1;
      $display("FAIL [%0s] t=%0t : %0s", rq, $time, msg);
    end
  endtask

  // Unique payloads: multiplication by an odd constant is a bijection, so no
  // two pushes ever carry the same value and a returned payload is unambiguous.
  function automatic pay_t mk_pay(input int unsigned s);
    return (s * 32'h9E37_79B1) ^ 32'h1357_9BDF;
  endfunction

  // Index of the OLDEST entry carrying this tag, or -1.  Only ever asked about
  // one tag at a time: nothing here compares entries of different tags (R3).
  function automatic int find_oldest(input int tg);
    int i;
    for (i = 0; i < mdl_tag.size(); i++)
      if (mdl_tag[i] == tg) return i;
    return -1;
  endfunction

  function automatic int count_tag(input int tg);
    int i;
    int n;
    n = 0;
    for (i = 0; i < mdl_tag.size(); i++)
      if (mdl_tag[i] == tg) n = n + 1;
    return n;
  endfunction

  // R12 exactly as written: over payloads, across all tags.
  function automatic bit exp_match(input pay_t dat, input pay_t msk);
    int i;
    for (i = 0; i < mdl_pay.size(); i++)
      if ((mdl_pay[i] & msk) == (dat & msk)) return 1'b1;
    return 1'b0;
  endfunction

  // =========================================================================
  // Transactors.  Every one is a BOUNDED retry loop: latency is unconstrained,
  // so a request is held until granted, but never forever.
  // =========================================================================
  task automatic do_push(input int tg, input pay_t dat, input int tmo, output bit done);
    int c;
    done = 1'b0;
    bfm_drive_point();
    push_tag  = tg[TAG_W-1:0];
    push_data = dat;
    push_req  = 1'b1;
    for (c = 0; c < tmo; c++) begin
      @(posedge clk);
      if (push_gnt === 1'b1) begin
        // R5: a grant while the store already holds SLOTS entries.
        if (mdl_pay.size() >= SLOTS)
          fail("R5", $sformatf("push granted while the store already held %0d entries (SLOTS=%0d)",
                               mdl_pay.size(), SLOTS));
        mdl_tag.push_back(tg);
        mdl_pay.push_back(dat);
        done = 1'b1;
        break;
      end
    end
    bfm_drive_point();
    push_req = 1'b0;
  endtask

  // Hold a push offered and require it to be refused for the whole window (R5).
  task automatic push_must_be_refused(input int tg, input pay_t dat, input int cycles);
    int c;
    bfm_drive_point();
    push_tag  = tg[TAG_W-1:0];
    push_data = dat;
    push_req  = 1'b1;
    for (c = 0; c < cycles; c++) begin
      @(posedge clk);
      if (push_gnt === 1'b1) begin
        fail("R5", $sformatf("push_gnt_o high with tag %0d while the store held %0d entries (SLOTS=%0d)",
                             tg, mdl_pay.size(), SLOTS));
        mdl_tag.push_back(tg);   // keep the model alongside the design
        mdl_pay.push_back(dat);
        break;
      end
    end
    bfm_drive_point();
    push_req = 1'b0;
  endtask

  // R8, and with it R2 (oldest first), R9 (peek does not remove) and R10
  // (absent tag completes with valid low).  pop_data_o is NOT examined when
  // pop_data_valid_o is low -- that value is free.
  task automatic do_pop(input int tg, input bit en, input int tmo, output bit done);
    int   c;
    int   idx;
    bit   exp_v;
    pay_t exp_d;
    done  = 1'b0;
    idx   = 0;
    exp_v = 1'b0;
    exp_d = '0;
    bfm_drive_point();
    pop_tag = tg[TAG_W-1:0];
    pop_en  = en;
    pop_req = 1'b1;
    for (c = 0; c < tmo; c++) begin
      @(posedge clk);
      if (pop_gnt === 1'b1) begin
        idx   = find_oldest(tg);
        exp_v = (idx >= 0);
        if (idx >= 0) exp_d = mdl_pay[idx];
        if (pop_data_valid !== exp_v)
          fail("R8", $sformatf("pop tag %0d (en=%0b): pop_data_valid_o=%0b but the store holds %0d entr(ies) for that tag",
                               tg, en, pop_data_valid, count_tag(tg)));
        else if (exp_v && (pop_data !== exp_d))
          fail("R8", $sformatf("pop tag %0d (en=%0b): pop_data_o=%08h but the oldest stored entry for that tag is %08h",
                               tg, en, pop_data, exp_d));
        // R9: removal happens only on a completing pop with en high and the
        // design reporting valid.
        if (en && exp_v && (pop_data_valid === 1'b1)) begin
          mdl_tag.delete(idx);
          mdl_pay.delete(idx);
        end
        done = 1'b1;
        break;
      end
    end
    bfm_drive_point();
    pop_req = 1'b0;
    pop_en  = 1'b0;
  endtask

  // R12, and with it R13 (the all-zero mask is one input to R12's iff).
  task automatic do_match(input pay_t dat, input pay_t msk, input int tmo, output bit done);
    int c;
    bit exp_h;
    done  = 1'b0;
    exp_h = 1'b0;
    bfm_drive_point();
    match_data[0] = dat;
    match_mask[0] = msk;
    match_req[0]  = 1'b1;
    for (c = 0; c < tmo; c++) begin
      @(posedge clk);
      if (match_gnt[0] === 1'b1) begin
        exp_h = exp_match(dat, msk);
        if (match_hit[0] !== exp_h)
          fail("R12", $sformatf("search data=%08h mask=%08h: match_hit_o=%0b, expected %0b over %0d stored entries",
                                dat, msk, match_hit[0], exp_h, mdl_pay.size()));
        done = 1'b1;
        break;
      end
    end
    bfm_drive_point();
    match_req[0] = 1'b0;
  endtask

  // R14.  Read at a negedge with every request line low and a full cycle of
  // settling, so this cannot depend on whether the flags are registered.
  task automatic check_status(input string what);
    bfm_tick();
    @(negedge clk);
    if (dut_empty !== ((mdl_pay.size() == 0) ? 1'b1 : 1'b0))
      fail("R14", $sformatf("empty_o=%0b while the store holds %0d entries (%0s)",
                            dut_empty, mdl_pay.size(), what));
    if (dut_full !== ((mdl_pay.size() == SLOTS) ? 1'b1 : 1'b0))
      fail("R14", $sformatf("full_o=%0b while the store holds %0d entries, SLOTS=%0d (%0s)",
                            dut_full, mdl_pay.size(), SLOTS, what));
  endtask

  // R15.  Also used between phases so one phase's divergence cannot cascade.
  task automatic resync(input string what);
    bfm_reset(4);
    mdl_tag.delete();
    mdl_pay.delete();
    @(negedge clk);
    if (dut_empty !== 1'b1)
      fail("R15", $sformatf("empty_o=%0b after reset release (%0s)", dut_empty, what));
    if (dut_full !== 1'b0)
      fail("R15", $sformatf("full_o=%0b after reset release (%0s)", dut_full, what));
  endtask

  // =========================================================================
  // Stimulus
  // =========================================================================
  initial begin
    int unsigned pseq;
    int   i;
    int   k;
    int   tg;
    int   trips;
    bit   ok;
    pay_t d;
    pay_t msk;

    push_req   = 1'b0;
    push_tag   = '0;
    push_data  = '0;
    pop_req    = 1'b0;
    pop_en     = 1'b0;
    pop_tag    = '0;
    match_req  = '0;
    match_data = '0;
    match_mask = '0;
    nerr       = 0;
    nprint     = 0;
    pseq       = 0;

    // ---- phase 1: reset, and an empty store ------------------------------
    resync("initial reset");
    for (tg = 0; tg < 3; tg++) begin
      do_pop(tg, 1'b1, TMO, ok);
      if (!ok) fail("R7", $sformatf("pop of tag %0d never granted in %0d cycles", tg, TMO));
    end
    // R12/R13 on an empty store: a zero mask must NOT hit when nothing is held.
    do_match(32'hDEAD_BEEF, 32'h0000_0000, TMO, ok);
    if (!ok) fail("R11", "search never granted in an idle empty store");
    check_status("empty store");

    // ---- phase 2: capacity with mixed tags (R1), then fullness (R5) -------
    for (i = 0; i < SLOTS; i++) begin
      pseq = pseq + 1;
      d    = mk_pay(pseq);
      tg   = i % 3;                       // tags 0,1,2 repeat: exercises R2
      do_push(tg, d, TMO, ok);
      if (!ok)
        fail("R1", $sformatf("push %0d of %0d refused for %0d cycles with only %0d entries stored",
                             i, SLOTS, TMO, mdl_pay.size()));
      check_status("during mixed fill");
    end
    pseq = pseq + 1;
    push_must_be_refused(3, mk_pay(pseq), 12);
    check_status("full, mixed tags");

    // ---- phase 3: search over a full store (R12, R13) ---------------------
    do_match(32'h0000_0000, 32'h0000_0000, TMO, ok);   // R13: zero mask, non-empty
    if (!ok) fail("R11", "search never granted");
    // Guarded: a design that refused every push leaves the model empty, and
    // indexing an empty queue is undefined rather than a useful check.
    if (mdl_pay.size() > 0) begin
      do_match(mdl_pay[0], 32'hFFFF_FFFF, TMO, ok);    // exact hit, oldest
      if (!ok) fail("R11", "search never granted");
      do_match(mdl_pay[mdl_pay.size()-1], 32'hFFFF_FFFF, TMO, ok);  // exact hit, newest
      if (!ok) fail("R11", "search never granted");
      do_match(mdl_pay[0] ^ 32'h0000_0001, 32'hFFFF_FFFF, TMO, ok); // near miss
      if (!ok) fail("R11", "search never granted");
      do_match(mdl_pay[mdl_pay.size()/2], 32'h0000_FFFF, TMO, ok);  // partial mask
      if (!ok) fail("R11", "search never granted");
    end
    for (i = 0; i < 24; i++) begin
      if ((mdl_pay.size() > 0) && ($urandom_range(0, 1) == 0))
        d = mdl_pay[$urandom_range(0, mdl_pay.size()-1)];
      else
        d = pay_t'($urandom);
      msk = pay_t'($urandom) >> $urandom_range(0, 24);
      do_match(d, msk, TMO, ok);
      if (!ok) fail("R11", "search never granted");
    end
    check_status("after searches");

    // ---- phase 4: drain, checking oldest-first per tag (R8 -> R2) ---------
    for (tg = 0; tg < 8; tg++) begin
      trips = 0;
      while ((find_oldest(tg) >= 0) && (trips < SLOTS + 2)) begin
        do_pop(tg, 1'b1, TMO, ok);
        if (!ok) begin
          fail("R7", $sformatf("pop of tag %0d never granted in %0d cycles", tg, TMO));
          trips = SLOTS + 2;               // stop; the design is not responding
        end
        trips = trips + 1;
      end
    end
    check_status("after drain");

    // ---- phase 5: peek versus pop (R9, reported under R8) -----------------
    resync("before peek test");
    for (i = 0; i < 3; i++) begin
      pseq = pseq + 1;
      do_push(2, mk_pay(pseq), TMO, ok);
      if (!ok) fail("R1", $sformatf("push %0d refused with %0d entries stored", i, mdl_pay.size()));
    end
    // Three peeks must all return the same oldest entry and remove nothing.
    for (i = 0; i < 3; i++) begin
      do_pop(2, 1'b0, TMO, ok);
      if (!ok) fail("R7", "peek never granted");
      check_status("after peek");
    end
    do_pop(2, 1'b1, TMO, ok);              // removes the oldest
    if (!ok) fail("R7", "pop never granted");
    do_pop(2, 1'b0, TMO, ok);              // must now show the second entry
    if (!ok) fail("R7", "peek never granted");
    do_pop(2, 1'b1, TMO, ok);
    if (!ok) fail("R7", "pop never granted");
    do_pop(2, 1'b1, TMO, ok);
    if (!ok) fail("R7", "pop never granted");
    do_pop(2, 1'b1, TMO, ok);              // now empty for this tag: valid low
    if (!ok) fail("R7", "pop never granted");
    check_status("after peek/pop sequence");

    // ---- phase 6: SLOTS entries all on one tag (R1), then FIFO order ------
    resync("before same-tag fill");
    for (i = 0; i < SLOTS; i++) begin
      pseq = pseq + 1;
      do_push(5, mk_pay(pseq), TMO, ok);
      if (!ok)
        fail("R1", $sformatf("same-tag push %0d of %0d refused with %0d entries stored",
                             i, SLOTS, mdl_pay.size()));
    end
    check_status("full, all one tag");
    pseq = pseq + 1;
    push_must_be_refused(5, mk_pay(pseq), 8);   // same tag, store full
    pseq = pseq + 1;
    push_must_be_refused(1, mk_pay(pseq), 8);   // different tag, store full
    for (i = 0; i < SLOTS; i++) begin
      do_pop(5, 1'b1, TMO, ok);
      if (!ok) fail("R7", "pop never granted while draining one tag");
    end
    check_status("after same-tag drain");

    // ---- phase 7: a tag with no entries, store non-empty (R8 -> R10) ------
    resync("before absent-tag test");
    for (i = 0; i < 2; i++) begin
      pseq = pseq + 1;
      do_push(1, mk_pay(pseq), TMO, ok);
      if (!ok) fail("R1", "push refused with space available");
    end
    do_pop(6, 1'b1, TMO, ok);              // absent tag, en high
    if (!ok) fail("R7", "pop of an absent tag never granted");
    do_pop(6, 1'b0, TMO, ok);              // absent tag, en low
    if (!ok) fail("R7", "peek of an absent tag never granted");
    check_status("after absent-tag pops");
    do_pop(1, 1'b1, TMO, ok);              // the present entries are untouched
    if (!ok) fail("R7", "pop never granted");
    do_pop(1, 1'b1, TMO, ok);
    if (!ok) fail("R7", "pop never granted");
    check_status("after absent-tag test");

    // ---- phase 8: mixed random traffic ------------------------------------
    resync("before random traffic");
    for (i = 0; i < 400; i++) begin
      k = $urandom_range(0, 9);
      if (k <= 3) begin
        pseq = pseq + 1;
        d    = mk_pay(pseq);
        tg   = $urandom_range(0, 7);
        if (mdl_pay.size() < SLOTS) begin
          do_push(tg, d, TMO, ok);
          if (!ok)
            fail("R1", $sformatf("push refused for %0d cycles with only %0d entries stored",
                                 TMO, mdl_pay.size()));
        end
        else begin
          push_must_be_refused(tg, d, 4);
        end
      end
      else if (k <= 6) begin
        tg = $urandom_range(0, 7);
        do_pop(tg, 1'b1, TMO, ok);
        if (!ok) fail("R7", $sformatf("pop of tag %0d never granted in %0d cycles", tg, TMO));
      end
      else if (k == 7) begin
        tg = $urandom_range(0, 7);
        do_pop(tg, 1'b0, TMO, ok);
        if (!ok) fail("R7", $sformatf("peek of tag %0d never granted in %0d cycles", tg, TMO));
      end
      else begin
        if ((mdl_pay.size() > 0) && ($urandom_range(0, 1) == 0))
          d = mdl_pay[$urandom_range(0, mdl_pay.size()-1)];
        else
          d = pay_t'($urandom);
        msk = ($urandom_range(0, 5) == 0) ? 32'h0000_0000
                                          : (pay_t'($urandom) >> $urandom_range(0, 24));
        do_match(d, msk, TMO, ok);
        if (!ok) fail("R11", "search never granted");
      end
      if ((i % 8) == 0) check_status("random traffic");
    end
    check_status("after random traffic");

    // ---- phase 9: reset with entries stored (R15) -------------------------
    resync("before mid-run reset test");
    for (i = 0; i < 5; i++) begin
      pseq = pseq + 1;
      do_push(i % 4, mk_pay(pseq), TMO, ok);
      if (!ok) fail("R1", "push refused with space available");
    end
    check_status("before mid-run reset");
    bfm_reset(3);
    mdl_tag.delete();
    mdl_pay.delete();
    @(negedge clk);
    if (dut_empty !== 1'b1)
      fail("R15", $sformatf("empty_o=%0b after a reset that had 5 entries stored", dut_empty));
    if (dut_full !== 1'b0)
      fail("R15", $sformatf("full_o=%0b after a reset that had 5 entries stored", dut_full));
    // and the store really is emptied, not merely reporting empty
    for (tg = 0; tg < 4; tg++) begin
      do_pop(tg, 1'b1, TMO, ok);
      if (!ok) fail("R7", $sformatf("pop of tag %0d never granted after reset", tg));
    end
    do_match(32'h0000_0000, 32'h0000_0000, TMO, ok);
    if (!ok) fail("R11", "search never granted after reset");
    check_status("after mid-run reset");

    // ---- verdict -----------------------------------------------------------
    $display("summary: %0d failure(s) reported", nerr);
    if (nerr == 0) $display("RESULT: PASS");
    else           $display("RESULT: FAIL");
    $finish;
  end

endmodule