// ===========================================================================
// tag_tracker_tb.sv
//
// Self-checking testbench for tag_tracker, written against the specification
// only.  Every check is tied to a numbered requirement; nothing that the
// specification leaves open (arbitration policy, cross-tag order, pop_data_o
// when pop_data_valid_o is low, output timing within a cycle, latency,
// internal structure) is checked anywhere.
//
// Structure
//   * A reference model (per-tag ring buffers, no dynamic types) is updated
//     only by *completed* transactions -- req && gnt sampled at the rising
//     edge, which is the value the design itself used.
//   * All checking lives in one always @(posedge clk) monitor.  It checks the
//     outputs FIRST and applies the model updates AFTERWARDS, so every check
//     is made against the contents the store held during that cycle.
//   * Stimulus is driven only at the falling edge, and learns whether a
//     request completed from flags the monitor set at the preceding rising
//     edge, so it never samples an edge it is also driving.
//   * Every request is bounded: if a grant does not arrive within
//     REQ_TIMEOUT cycles the request is abandoned and reported.  Nothing in
//     this testbench can wait forever.
// ===========================================================================

module tag_tracker_tb;

  // ---- configuration -------------------------------------------------------
  localparam int TAG_W        = 3;
  localparam int SLOTS        = 8;
  localparam int N_MATCH      = 1;
  localparam bit FULL_RATE    = 1'b0;
  localparam bit CUT_POP_PATH = 1'b0;

  localparam int NTAG        = 1 << TAG_W;
  localparam int REQ_TIMEOUT = 512;   // cycles one request may wait for a grant
  localparam int MDEPTH      = 32;    // per-tag depth of the model ring

  typedef logic [31:0]      payload_t;
  typedef logic [TAG_W-1:0] tag_t;

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

  // ===========================================================================
  //                          FROM HERE ON: MY OWN CODE
  // ===========================================================================

  // ---- device under test ---------------------------------------------------
  tag_t                   push_tag;
  payload_t               push_data;
  logic                   push_req;
  logic                   push_gnt;

  payload_t [N_MATCH-1:0] match_data;      // packed, exactly as the port is
  payload_t [N_MATCH-1:0] match_mask;      // packed
  logic     [N_MATCH-1:0] match_req;       // packed
  logic     [N_MATCH-1:0] match_hit;
  logic     [N_MATCH-1:0] match_gnt;

  tag_t                   pop_tag;
  logic                   pop_en;
  logic                   pop_req;
  payload_t               pop_data;
  logic                   pop_data_valid;
  logic                   pop_gnt;

  logic                   full;
  logic                   empty;

  tag_tracker #(
    .TAG_W        (TAG_W),
    .SLOTS        (SLOTS),
    .FULL_RATE    (FULL_RATE),
    .CUT_POP_PATH (CUT_POP_PATH),
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

  // ---- verdict bookkeeping -------------------------------------------------
  int err_cnt  = 0;
  int msg_cnt  = 0;

  task automatic rpt(input string req_id, input string msg);
    err_cnt = err_cnt + 1;
    if (msg_cnt < 60) begin
      msg_cnt = msg_cnt + 1;
      $display("FAIL [%s] t=%0t : %s", req_id, $time, msg);
    end
    if (err_cnt == 400) begin
      $display("STATS: stopping after %0d violations", err_cnt);
      $display("RESULT: FAIL");
      $finish;
    end
  endtask

  // ---- reference model -----------------------------------------------------
  // One ring buffer per tag: per-tag FIFO order (R2) is modelled, order
  // between tags (R3) is never represented and so can never be checked.
  payload_t mq [NTAG][MDEPTH];
  int       mh [NTAG];
  int       mt [NTAG];
  int       model_cnt;

  function automatic int msize(input int t);
    return mt[t] - mh[t];
  endfunction

  function automatic payload_t mfront(input int t);
    return mq[t][mh[t] % MDEPTH];
  endfunction

  function automatic bit mhas_match(input payload_t d, input payload_t m);
    for (int t = 0; t < NTAG; t++)
      for (int i = mh[t]; i < mt[t]; i++)
        if ((mq[t][i % MDEPTH] & m) == (d & m)) return 1'b1;
    return 1'b0;
  endfunction

  task automatic mclear();
    for (int t = 0; t < NTAG; t++) begin
      mh[t] = 0;
      mt[t] = 0;
    end
    model_cnt = 0;
  endtask

  task automatic mpush(input int t, input payload_t d);
    if (msize(t) >= MDEPTH) begin
      rpt("R5", "the design keeps granting pushes far past SLOTS entries");
      return;
    end
    mq[t][mt[t] % MDEPTH] = d;
    mt[t]     = mt[t] + 1;
    model_cnt = model_cnt + 1;
  endtask

  task automatic mpop(input int t);
    mh[t]     = mh[t] + 1;
    model_cnt = model_cnt - 1;
  endtask

  // ---- what the monitor tells the stimulus ---------------------------------
  logic               mon_push_done;
  logic               mon_pop_done;
  logic [N_MATCH-1:0] mon_match_done;
  logic               s_empty, s_full;
  logic               prev_e_bad, prev_f_bad;

  // ---- coverage-ish counters, printed at the end ---------------------------
  int n_push = 0, n_pop_hit = 0, n_pop_miss = 0, n_inspect = 0;
  int n_match_hit = 0, n_match_miss = 0;

  // ===========================================================================
  // THE MONITOR.  Sampling at the rising edge gives the values the design used
  // during the cycle that is ending; outputs are checked against the model
  // BEFORE this cycle's transactions are applied to it.
  // ===========================================================================
  always @(posedge clk) begin
    if (!rst_n) begin
      // R15: while reset is low the store is emptied.
      mclear();
      mon_push_done  = 1'b0;
      mon_pop_done   = 1'b0;
      mon_match_done = '0;
      s_empty        = 1'b1;
      s_full         = 1'b0;
      prev_e_bad     = 1'b0;
      prev_f_bad     = 1'b0;
    end else begin
      automatic bit exp_valid;
      automatic bit exp_hit;
      automatic bit e_bad;
      automatic bit f_bad;
      automatic int pt;

      // ---- R14: status reflects the occupancy exactly --------------------
      // Reported once per episode rather than once per cycle, so a stuck
      // status flag does not bury every other diagnostic.
      e_bad = (empty !== (model_cnt == 0));
      f_bad = (full  !== (model_cnt == SLOTS));
      if (e_bad && !prev_e_bad)
        rpt("R14", $sformatf("empty_o=%0b but the store holds %0d entries", empty, model_cnt));
      if (f_bad && !prev_f_bad)
        rpt("R14", $sformatf("full_o=%0b but the store holds %0d entries (SLOTS=%0d)", full, model_cnt, SLOTS));
      prev_e_bad = e_bad;
      prev_f_bad = f_bad;
      s_empty = empty;
      s_full  = full;

      // ---- R5: no push grant while the store holds SLOTS entries ---------
      if (push_req === 1'b1 && push_gnt === 1'b1 && model_cnt >= SLOTS)
        rpt("R5", $sformatf("push_gnt_o high while the store already holds %0d entries", model_cnt));

      // ---- R7/R8/R10: a completing pop -----------------------------------
      if (pop_req === 1'b1 && pop_gnt === 1'b1) begin
        pt        = int'(pop_tag);
        exp_valid = (msize(pt) > 0);
        if (pop_data_valid !== exp_valid) begin
          if (exp_valid)
            rpt("R8", $sformatf("pop of tag %0d completed with pop_data_valid_o low, but %0d entries with that tag are stored", pt, msize(pt)));
          else
            rpt("R10", $sformatf("pop of tag %0d completed with pop_data_valid_o high, but no entry with that tag is stored", pt));
        end
        if (exp_valid && pop_data_valid === 1'b1) begin
          // R8 + R2: the oldest entry of that tag, and no other.
          if (pop_data !== mfront(pt))
            rpt("R2/R8", $sformatf("pop of tag %0d returned %08h; the oldest entry inserted with that tag and not yet removed is %08h", pt, pop_data, mfront(pt)));
        end
        if (exp_valid) begin
          n_pop_hit = n_pop_hit + 1;
          if (pop_en !== 1'b1) n_inspect = n_inspect + 1;
        end else begin
          n_pop_miss = n_pop_miss + 1;
        end
      end

      // ---- R11/R12/R13: a completing search ------------------------------
      for (int k = 0; k < N_MATCH; k++) begin
        if (match_req[k] === 1'b1 && match_gnt[k] === 1'b1) begin
          exp_hit = mhas_match(match_data[k], match_mask[k]);
          if (match_hit[k] !== exp_hit) begin
            if (match_mask[k] === '0)
              rpt("R13", $sformatf("search port %0d with an all-zero mask reported hit=%0b; the store holds %0d entries so every entry matches", k, match_hit[k], model_cnt));
            else
              rpt("R12", $sformatf("search port %0d (data %08h mask %08h) reported hit=%0b, expected %0b over the %0d stored entries", k, match_data[k], match_mask[k], match_hit[k], exp_hit, model_cnt));
          end
          if (exp_hit) n_match_hit = n_match_hit + 1;
          else         n_match_miss = n_match_miss + 1;
        end
      end

      // ---- tell the stimulus what completed ------------------------------
      mon_push_done = (push_req === 1'b1) && (push_gnt === 1'b1);
      mon_pop_done  = (pop_req  === 1'b1) && (pop_gnt  === 1'b1);
      for (int k = 0; k < N_MATCH; k++)
        mon_match_done[k] = (match_req[k] === 1'b1) && (match_gnt[k] === 1'b1);

      // ---- now apply this cycle's transactions to the model --------------
      // R9: removal only when pop_en_i is high on a completing pop that had
      // an entry to return.  Otherwise the entry is inspected, not removed.
      if (mon_pop_done && pop_en === 1'b1 && msize(int'(pop_tag)) > 0)
        mpop(int'(pop_tag));
      // R4: the entry is committed on a cycle where push_req_i && push_gnt_o.
      if (mon_push_done) begin
        mpush(int'(push_tag), push_data);
        n_push = n_push + 1;
      end
    end
  end

  // ===========================================================================
  // STIMULUS.  Requests are held until granted (R6: a low grant is not an
  // error, it just has not happened yet) but never for longer than
  // REQ_TIMEOUT cycles, so a design that never grants is reported, not waited
  // on.  Everything is driven at the falling edge.
  // ===========================================================================
  logic               pend_push;
  logic               pend_pop;
  logic [N_MATCH-1:0] pend_match;

  // Drives whatever is pending until it all completes.  Enters and leaves at a
  // falling edge, i.e. at the drive point.
  int timeouts = 0;

  // A design that has already failed to grant twice will not be given the full
  // window again: the fault is established, and the run must still terminate.
  function automatic int cur_timeout();
    return (timeouts >= 2) ? 16 : REQ_TIMEOUT;
  endfunction

  task automatic run_reqs(input string ctx);
    automatic int i;
    automatic int lim = cur_timeout();
    for (i = 0; i < lim; i++) begin
      if (!pend_push && !pend_pop && (pend_match == '0)) break;
      push_req  = pend_push;
      pop_req   = pend_pop;
      match_req = pend_match;
      @(posedge clk);      // the design samples here; the monitor checks here
      @(negedge clk);      // safe point: the monitor's flags are settled
      if (mon_push_done) pend_push = 1'b0;
      if (mon_pop_done)  pend_pop  = 1'b0;
      pend_match = pend_match & ~mon_match_done;
    end
    push_req  = 1'b0;
    pop_req   = 1'b0;
    match_req = '0;
    if (pend_push) begin
      timeouts = timeouts + 1;
      rpt("R1", $sformatf("push (%s) was requested for %0d cycles with the store holding %0d of %0d entries and was never granted", ctx, lim, model_cnt, SLOTS));
    end
    if (pend_pop) begin
      timeouts = timeouts + 1;
      rpt("R7", $sformatf("pop (%s) was requested for %0d cycles and was never granted", ctx, lim));
    end
    if (|pend_match) begin
      timeouts = timeouts + 1;
      rpt("R11", $sformatf("search (%s) was requested for %0d cycles and was never granted", ctx, lim));
    end
    pend_push  = 1'b0;
    pend_pop   = 1'b0;
    pend_match = '0;
  endtask

  // ---- recently pushed payloads, so searches can aim at real content -------
  payload_t recent [16];
  int       recent_n = 0;

  task automatic note_payload(input payload_t d);
    recent[recent_n % 16] = d;
    recent_n = recent_n + 1;
  endtask

  task automatic push_one(input tag_t t, input payload_t d);
    push_tag  = t;
    push_data = d;
    pend_push = 1'b1;
    note_payload(d);
    run_reqs("push");
  endtask

  task automatic pop_one(input tag_t t, input logic en);
    pop_tag  = t;
    pop_en   = en;
    pend_pop = 1'b1;
    run_reqs("pop");
  endtask

  task automatic match_one(input payload_t d, input payload_t m);
    match_data[0] = d;
    match_mask[0] = m;
    pend_match[0] = 1'b1;
    run_reqs("search");
  endtask

  // A push that is expected NOT to be granted (store full, R5).  Bounded, and
  // it does not treat a missing grant as an error -- that is the point.
  task automatic push_expect_no_grant(input tag_t t, input payload_t d, input int cycles);
    push_tag  = t;
    push_data = d;
    push_req  = 1'b1;
    for (int i = 0; i < cycles; i++) begin
      @(posedge clk);
      @(negedge clk);
      if (mon_push_done) begin
        // the monitor has already reported R5; stop before the model drifts
        rpt("R5", "a push was granted and committed while the store was full");
        break;
      end
    end
    push_req = 1'b0;
  endtask

  task automatic drain_all();
    for (int t = 0; t < NTAG; t++) begin
      automatic int guard = 0;
      while (msize(t) > 0 && guard < SLOTS + 4) begin
        pop_one(tag_t'(t), 1'b1);
        guard = guard + 1;
      end
    end
    if (model_cnt != 0)
      rpt("R9", $sformatf("%0d entries could not be removed by popping with pop_en_i high", model_cnt));
  endtask

  // ---- deterministic pseudo-random source ---------------------------------
  int unsigned rnd_s = 32'h1357_9BDF;
  function automatic int unsigned rnd();
    rnd_s = rnd_s ^ (rnd_s << 13);
    rnd_s = rnd_s ^ (rnd_s >> 17);
    rnd_s = rnd_s ^ (rnd_s << 5);
    return rnd_s;
  endfunction

  // Payloads drawn from a structured, low-entropy space so that masked
  // searches produce both hits and misses in quantity.
  function automatic payload_t pool_data(input int unsigned r);
    return {4'hC, r[3:0], 4'h5, r[7:4], 8'h3C, r[11:8], 4'hA};
  endfunction

  function automatic payload_t pool_mask(input int unsigned r);
    case (r[18:16] )
      3'd0: return 32'hFFFF_FFFF;
      3'd1: return 32'h0000_0000;
      3'd2: return 32'h0000_00FF;
      3'd3: return 32'hFFFF_0000;
      3'd4: return 32'h0F0F_0F0F;
      3'd5: return 32'h00FF_0000;
      3'd6: return 32'h0000_F0F0;
      default: return 32'hFF00_00FF;
    endcase
  endfunction

  // ===========================================================================
  // THE RUN
  // ===========================================================================
  initial begin
    automatic int unsigned r;
    automatic tag_t        t;
    automatic payload_t    d;

    push_tag   = '0;  push_data = '0;  push_req = 1'b0;
    pop_tag    = '0;  pop_en    = 1'b0; pop_req = 1'b0;
    match_data = '0;  match_mask = '0; match_req = '0;
    pend_push  = 1'b0; pend_pop = 1'b0; pend_match = '0;
    for (int i = 0; i < 16; i++) recent[i] = '0;

    // ---- R15: reset empties the store ------------------------------------
    bfm_reset(4);
    @(posedge clk);
    @(negedge clk);
    if (s_empty !== 1'b1 || s_full !== 1'b0)
      rpt("R15", $sformatf("after reset release empty_o=%0b full_o=%0b, expected 1 and 0", s_empty, s_full));

    // ---- R1/R2/R14: SLOTS entries all carrying the same tag --------------
    for (int i = 0; i < SLOTS; i++)
      push_one(3'd5, 32'h1000_0000 + payload_t'(i));
    if (model_cnt != SLOTS)
      rpt("R1", $sformatf("only %0d of %0d entries with a single tag could be stored", model_cnt, SLOTS));

    // ---- R5: full means no more grants -----------------------------------
    // Only meaningful if SLOTS entries really did go in: with fewer stored, a
    // grant would be perfectly legal and demanding its absence would be wrong.
    if (model_cnt == SLOTS) begin
      push_expect_no_grant(3'd5, 32'hDEAD_BEEF, 24);
      push_expect_no_grant(3'd2, 32'hDEAD_BEE2, 12); // a different tag is no different
    end

    // ---- R13/R12 with a full store ---------------------------------------
    match_one(32'h0000_0000, 32'h0000_0000);         // all-zero mask, non-empty -> hit
    match_one(32'h1000_0003, 32'hFFFF_FFFF);         // exact, stored          -> hit
    match_one(32'h1000_00FF, 32'hFFFF_FFFF);         // exact, not stored      -> miss

    // ---- R2: they come back in insertion order ---------------------------
    for (int i = 0; i < SLOTS; i++)
      pop_one(3'd5, 1'b1);
    if (model_cnt != 0)
      rpt("R9", $sformatf("after popping %0d entries with pop_en_i high the store still holds %0d", SLOTS, model_cnt));

    // ---- R12: nothing stored, nothing matches (even an all-zero mask) ----
    match_one(32'h0000_0000, 32'h0000_0000);
    match_one(32'h1000_0000, 32'hFFFF_FFFF);

    // ---- R10: popping a tag that holds nothing is not an error -----------
    pop_one(3'd5, 1'b1);
    pop_one(3'd0, 1'b1);
    pop_one(3'd7, 1'b0);

    // ---- R9: pop_en_i low inspects without removing ----------------------
    push_one(3'd1, 32'hAAAA_0001);
    push_one(3'd1, 32'hAAAA_0002);
    push_one(3'd4, 32'hBBBB_0001);
    pop_one(3'd1, 1'b0);      // -> AAAA_0001, still there
    pop_one(3'd1, 1'b0);      // -> AAAA_0001 again
    pop_one(3'd1, 1'b1);      // -> AAAA_0001, removed
    pop_one(3'd1, 1'b0);      // -> AAAA_0002 now at the head
    pop_one(3'd1, 1'b1);      // -> AAAA_0002, removed
    pop_one(3'd1, 1'b1);      // -> nothing left for this tag (R10)
    if (timeouts == 0 && msize(4) != 1)
      rpt("R9", "an entry under a different tag disappeared while tag 1 was being popped");

    // ---- R2 interleaved across tags (R3: no cross-tag order checked) -----
    push_one(3'd0, 32'h0700_0001);
    push_one(3'd3, 32'h0700_0002);
    push_one(3'd0, 32'h0700_0003);
    push_one(3'd3, 32'h0700_0004);
    push_one(3'd0, 32'h0700_0005);
    pop_one(3'd0, 1'b1);      // 0700_0001
    pop_one(3'd3, 1'b1);      // 0700_0002
    pop_one(3'd0, 1'b1);      // 0700_0003
    pop_one(3'd3, 1'b1);      // 0700_0004
    pop_one(3'd0, 1'b1);      // 0700_0005

    // ---- R12/R13: masked search over known content -----------------------
    push_one(3'd2, 32'h1234_5678);
    push_one(3'd6, 32'hFFFF_0000);
    match_one(32'h0000_0078, 32'h0000_00FF);   // hit  (1234_5678)
    match_one(32'h0000_0079, 32'h0000_00FF);   // miss
    match_one(32'hFFFF_9999, 32'hFFFF_0000);   // hit  (FFFF_0000)
    match_one(32'hFFFE_0000, 32'hFFFF_0000);   // miss
    match_one(32'hDEAD_BEEF, 32'h0000_0000);   // hit  (R13, store non-empty)
    match_one(32'h1234_5678, 32'hFFFF_FFFF);   // hit  exact
    drain_all();
    match_one(32'h1234_5678, 32'hFFFF_FFFF);   // miss, it was removed
    match_one(32'h1234_5678, 32'h0000_0000);   // miss, store is empty

    // ---- concurrent requests (R6: arbitration policy is not checked, only
    //      that each request eventually completes and answers correctly) ----
    push_one(3'd2, 32'h5555_0001);
    pend_push = 1'b1; push_tag = 3'd2; push_data = 32'h5555_0002; note_payload(32'h5555_0002);
    pend_match[0] = 1'b1; match_data[0] = 32'h5555_0001; match_mask[0] = 32'hFFFF_FFFF;
    run_reqs("push+search");

    pend_pop = 1'b1; pop_tag = 3'd2; pop_en = 1'b1;
    pend_match[0] = 1'b1; match_data[0] = 32'h5555_0002; match_mask[0] = 32'hFFFF_FFFF;
    run_reqs("pop+search");

    pend_push = 1'b1; push_tag = 3'd7; push_data = 32'h6666_0001; note_payload(32'h6666_0001);
    pend_pop  = 1'b1; pop_tag  = 3'd2; pop_en = 1'b1;
    run_reqs("push+pop");

    pend_push = 1'b1; push_tag = 3'd7; push_data = 32'h6666_0002; note_payload(32'h6666_0002);
    pend_pop  = 1'b1; pop_tag  = 3'd7; pop_en = 1'b1;
    pend_match[0] = 1'b1; match_data[0] = 32'h6666_0001; match_mask[0] = 32'hFFFF_FFFF;
    run_reqs("push+pop+search");
    drain_all();

    // ---- randomised mixed traffic ----------------------------------------
    for (int it = 0; it < 600; it++) begin
      r = rnd();
      t = r[6:4];
      d = pool_data(r);
      case (r[1:0])
        2'd0: begin
          if (model_cnt < SLOTS) push_one(t, d);
          else                   pop_one(t, 1'b1);
        end
        2'd1: pop_one(t, r[8]);
        2'd2: begin
          if (r[9] && recent_n > 0) match_one(recent[int'(r[12:10])], pool_mask(r));
          else                      match_one(d, pool_mask(r));
        end
        default: begin
          // several ports at once
          if (model_cnt < SLOTS) begin
            pend_push = 1'b1; push_tag = t; push_data = d; note_payload(d);
          end
          pend_pop = 1'b1; pop_tag = r[22:20]; pop_en = r[23];
          pend_match[0] = 1'b1;
          match_data[0] = (r[13] && recent_n > 0) ? recent[int'(r[16:14])] : d;
          match_mask[0] = pool_mask(r);
          run_reqs("random mix");
        end
      endcase
    end

    // ---- R5 again, from a randomly reached state -------------------------
    for (int g = 0; g < 4*SLOTS && model_cnt < SLOTS; g++)
      push_one(tag_t'(rnd() % NTAG), pool_data(rnd()));
    // (full_o itself is checked every cycle by the monitor, which compares it
    //  against the occupancy of the same cycle; s_full lags the model by one
    //  cycle here and must not be compared with it.)
    if (model_cnt == SLOTS) begin
      push_expect_no_grant(3'd3, 32'hFEED_FACE, 16);
    end else begin
      rpt("R1", $sformatf("the store would not take SLOTS entries: it stopped at %0d", model_cnt));
    end

    // ---- R15: reset in the middle of a populated store -------------------
    bfm_reset(3);
    @(posedge clk);
    @(negedge clk);
    if (s_empty !== 1'b1 || s_full !== 1'b0)
      rpt("R15", $sformatf("after a reset with entries stored empty_o=%0b full_o=%0b, expected 1 and 0", s_empty, s_full));
    // anything that survived the reset would show up here as a pop that
    // returns data, or as a search hit
    match_one(32'h0000_0000, 32'h0000_0000);
    for (int t2 = 0; t2 < NTAG; t2++) pop_one(tag_t'(t2), 1'b1);
    if (model_cnt != 0)
      rpt("R15", "the store was not emptied by reset");

    // ---- the store still works afterwards --------------------------------
    push_one(3'd1, 32'h9999_1111);
    match_one(32'h9999_1111, 32'hFFFF_FFFF);
    pop_one(3'd1, 1'b1);

    // ---- verdict ---------------------------------------------------------
    $display("STATS: pushes=%0d pops-with-data=%0d pops-empty=%0d inspects=%0d searches hit/miss=%0d/%0d",
             n_push, n_pop_hit, n_pop_miss, n_inspect, n_match_hit, n_match_miss);
    if (n_push == 0)
      rpt("R4", "no push was ever granted, so nothing could be verified");
    if (n_match_hit == 0 || n_match_miss == 0)
      rpt("R12", "searches never produced both a hit and a miss");
    if (err_cnt == 0) $display("RESULT: PASS");
    else              $display("RESULT: FAIL");
    $finish;
  end

endmodule