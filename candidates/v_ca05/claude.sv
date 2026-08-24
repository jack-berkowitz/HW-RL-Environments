// ===========================================================================
// tag_tracker_tb.sv -- specification-driven testbench for tag_tracker
//
// Every check is grounded in a numbered requirement.  The model is a set of
// per-tag queues, which is exactly what R2 constrains and no more: nothing here
// looks at ordering between tags (R3), at pop_data_o when pop_data_valid_o is
// low (R10), at arbitration policy, or at when within a cycle an output
// settles.
//
// Requests are issued one at a time -- never a push against a pop against a
// search -- so that no check ever depends on how the design arbitrates between
// ports, which is out of scope.  R6 is respected by never failing a request
// merely because the grant was slow: a request that never completes is reported
// against the requirement it made unachievable (capacity for push, R7 for pop,
// R11 for search), and every request loop is bounded so a design that never
// grants terminates with a verdict instead of hanging.
// ===========================================================================
module tag_tracker_tb;

  localparam int TAG_W   = 3;
  localparam int SLOTS   = 8;
  localparam int N_MATCH = 1;
  localparam int NTAG    = 1 << TAG_W;
  localparam int TMO     = 64;          // generous: R6 allows a slow grant

  typedef logic [31:0] payload_t;

  // -------------------------------------------------------------------------
  // PROVIDED PLUMBING -- clock, reset and watchdog only.
  // -------------------------------------------------------------------------
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

  // -------------------------------------------------------------------------
  // DUT
  // -------------------------------------------------------------------------
  logic [TAG_W-1:0]        push_tag;
  payload_t                push_data;
  logic                    push_req, push_gnt;

  payload_t [N_MATCH-1:0]  match_data, match_mask;   // packed, as the port is
  logic     [N_MATCH-1:0]  match_req, match_hit, match_gnt;

  logic [TAG_W-1:0]        pop_tag;
  logic                    pop_en, pop_req;
  payload_t                pop_data;
  logic                    pop_data_valid, pop_gnt;

  logic                    full, empty;

  tag_tracker #(
      .TAG_W(TAG_W), .SLOTS(SLOTS), .FULL_RATE(1'b0), .CUT_POP_PATH(1'b0),
      .N_MATCH(N_MATCH), .payload_t(payload_t)
  ) dut (
      .clk_i(clk), .rst_ni(rst_n),
      .push_tag_i(push_tag), .push_data_i(push_data),
      .push_req_i(push_req), .push_gnt_o(push_gnt),
      .match_data_i(match_data), .match_mask_i(match_mask),
      .match_req_i(match_req), .match_hit_o(match_hit), .match_gnt_o(match_gnt),
      .pop_tag_i(pop_tag), .pop_en_i(pop_en), .pop_req_i(pop_req),
      .pop_data_o(pop_data), .pop_data_valid_o(pop_data_valid),
      .pop_gnt_o(pop_gnt),
      .full_o(full), .empty_o(empty));

  int cyc = 0;
  always @(posedge clk) if (rst_n) cyc <= cyc + 1;

  // -------------------------------------------------------------------------
  // MODEL: one queue per tag.  R3 means nothing here relates one tag's queue
  // to another's; only the per-tag order (R2) and the total occupancy matter.
  // -------------------------------------------------------------------------
  payload_t mdl [NTAG][$];
  int       errs = 0;
  string    phase_name = "startup";

  task automatic oops(input string req_id, input string msg);
    errs = errs + 1;
    if (errs <= 20)
      $display("FAIL [%s] cycle %0d, phase '%s': %s", req_id, cyc, phase_name, msg);
    if (errs == 21)
      $display("... further diagnostics suppressed");
  endtask

  function automatic int mdl_count();
    int n;
    n = 0;
    for (int t = 0; t < NTAG; t++) n = n + mdl[t].size();
    return n;
  endfunction

  function automatic bit mdl_match(input payload_t d, input payload_t m);
    for (int t = 0; t < NTAG; t++)
      for (int i = 0; i < mdl[t].size(); i++)
        if ((mdl[t][i] & m) == (d & m)) return 1'b1;
    return 1'b0;
  endfunction

  task automatic mdl_clear();
    for (int t = 0; t < NTAG; t++) mdl[t].delete();
  endtask

  // -------------------------------------------------------------------------
  // REQUEST DRIVERS
  //   Every one drives at the falling edge and samples the grant, and whatever
  //   the grant qualifies, at the rising edge -- the value the design used.
  //   Requests are held unchanged until the grant, and only one port is ever
  //   requested at a time.
  // -------------------------------------------------------------------------
  task automatic do_push(input logic [TAG_W-1:0] tg, input payload_t dt,
                         output bit ok);
    int t;
    bfm_drive_point();
    push_tag = tg; push_data = dt; push_req = 1'b1;
    ok = 1'b0;
    for (t = 0; t < TMO; t++) begin
      @(posedge clk);
      if (push_gnt === 1'b1) begin ok = 1'b1; break; end
    end
    bfm_drive_point();
    push_req = 1'b0;
    if (ok) mdl[tg].push_back(dt);          // R4: committed on req && gnt
  endtask

  // R1: the store must take this entry.  A grant that never arrives is a
  // capacity failure, not an arbitration observation (R6).
  task automatic push_expect(input logic [TAG_W-1:0] tg, input payload_t dt);
    bit ok;
    do_push(tg, dt, ok);
    if (!ok)
      oops("R1", $sformatf(
        "a push of tag %0d was never granted in %0d cycles although the store held %0d of %0d entries",
        tg, TMO, mdl_count(), SLOTS));
  endtask

  // R5: while the store is full, push_gnt_o must stay low.
  task automatic push_must_refuse(input logic [TAG_W-1:0] tg, input payload_t dt,
                                  input int cycles);
    bit bad;
    bad = 1'b0;
    bfm_drive_point();
    push_tag = tg; push_data = dt; push_req = 1'b1;
    for (int t = 0; t < cycles; t++) begin
      @(posedge clk);
      if (push_gnt === 1'b1 && !bad) begin
        bad = 1'b1;
        oops("R5", $sformatf("push_gnt_o was asserted while the store held all %0d entries", SLOTS));
      end
    end
    bfm_drive_point();
    push_req = 1'b0;
  endtask

  task automatic do_pop(input logic [TAG_W-1:0] tg, input bit en);
    int       t;
    bit       ok, v, expv;
    payload_t d, expd;
    bfm_drive_point();
    pop_tag = tg; pop_en = en; pop_req = 1'b1;
    ok = 1'b0; v = 1'b0; d = '0;
    for (t = 0; t < TMO; t++) begin
      @(posedge clk);
      if (pop_gnt === 1'b1) begin
        ok = 1'b1;
        v  = pop_data_valid;                // sampled on the completing cycle
        d  = pop_data;
        break;
      end
    end
    bfm_drive_point();
    pop_req = 1'b0;
    if (!ok) begin
      oops("R7", $sformatf("a pop of tag %0d was never granted in %0d cycles", tg, TMO));
      return;
    end
    expv = (mdl[tg].size() > 0);
    if (v !== expv) begin
      if (expv)
        oops("R8", $sformatf(
          "pop of tag %0d returned pop_data_valid_o low although %0d entr(y/ies) with that tag are stored",
          tg, mdl[tg].size()));
      else
        oops("R10", $sformatf(
          "pop of tag %0d returned pop_data_valid_o high although no entry with that tag is stored", tg));
      return;
    end
    if (!expv) return;                      // R10: pop_data_o unconstrained here
    expd = mdl[tg][0];
    if (d !== expd)
      oops("R8/R2", $sformatf(
        "pop of tag %0d returned %08h; the oldest entry for that tag is %08h", tg, d, expd));
    if (en) void'(mdl[tg].pop_front());     // R9
  endtask

  task automatic do_match(input payload_t d, input payload_t m);
    int t;
    bit ok, h, exph;
    bfm_drive_point();
    match_data[0] = d; match_mask[0] = m; match_req[0] = 1'b1;
    ok = 1'b0; h = 1'b0;
    for (t = 0; t < TMO; t++) begin
      @(posedge clk);
      if (match_gnt[0] === 1'b1) begin ok = 1'b1; h = match_hit[0]; break; end
    end
    bfm_drive_point();
    match_req[0] = 1'b0;
    if (!ok) begin
      oops("R11", $sformatf("a search for %08h/%08h was never granted in %0d cycles", d, m, TMO));
      return;
    end
    exph = mdl_match(d, m);
    if (h !== exph)
      oops((m === '0) ? "R13" : "R12", $sformatf(
        "search %08h mask %08h returned hit=%b, expected %b (store holds %0d entries)",
        d, m, h, exph, mdl_count()));
  endtask

  // R14, checked with nothing in flight so that no in-cycle timing question
  // arises -- item 4 of what is out of scope.
  task automatic check_status();
    repeat (2) @(posedge clk);
    if (empty !== ((mdl_count() == 0) ? 1'b1 : 1'b0))
      oops("R14", $sformatf("empty_o is %b while the store holds %0d entries", empty, mdl_count()));
    if (full !== ((mdl_count() == SLOTS) ? 1'b1 : 1'b0))
      oops("R14", $sformatf("full_o is %b while the store holds %0d of %0d entries",
                            full, mdl_count(), SLOTS));
  endtask

  task automatic set_phase(input string nm);
    bfm_drive_point();
    phase_name = nm;
  endtask

  // -------------------------------------------------------------------------
  // STIMULUS
  // -------------------------------------------------------------------------
  int lfsr = 32'h1234_5678;

  function automatic int rnd_next();
    lfsr = (lfsr * 32'd1103515245 + 32'd12345);
    return (lfsr >>> 8) & 32'h00FF_FFFF;
  endfunction

  initial begin
    payload_t dv;
    int r, tsel;

    push_req = 1'b0; pop_req = 1'b0; match_req = '0;
    push_tag = '0; push_data = '0; pop_tag = '0; pop_en = 1'b0;
    match_data = '0; match_mask = '0;

    bfm_reset(4);

    // ---------------- R15: reset leaves the store empty --------------------
    set_phase("R15 state after reset");
    @(posedge clk);
    if (empty !== 1'b1) oops("R15", "empty_o is not high after reset");
    if (full  !== 1'b0) oops("R15", "full_o is not low after reset");
    for (int t = 0; t < NTAG; t++) do_pop(t[TAG_W-1:0], 1'b1);   // R10 on every tag
    do_match(32'hDEAD_BEEF, 32'hFFFF_FFFF);                      // R12 on an empty store
    do_match(32'h0000_0000, 32'h0000_0000);                      // R13 on an empty store
    check_status();

    // ---------------- R1/R14: SLOTS entries spread over tags ---------------
    set_phase("R1 capacity across distinct tags");
    for (int i = 0; i < SLOTS; i++) begin
      push_expect(i[TAG_W-1:0], 32'hA000_0000 + 32'(i));
      check_status();
    end
    set_phase("R5 no grant while full");
    push_must_refuse(3'd0, 32'hBAD0_0001, 20);
    check_status();

    set_phase("R8/R2 read the entries back");
    for (int i = 0; i < SLOTS; i++) do_pop(i[TAG_W-1:0], 1'b1);
    check_status();

    // ---------------- R1/R2: SLOTS entries all on one tag ------------------
    set_phase("R1 capacity with every entry on one tag");
    for (int i = 0; i < SLOTS; i++) push_expect(3'd5, 32'hC000_0000 + 32'(i) * 32'h11);
    check_status();
    set_phase("R5 no grant while full, one-tag fill");
    push_must_refuse(3'd5, 32'hBAD0_0002, 20);
    set_phase("R2 per-tag FIFO order");
    for (int i = 0; i < SLOTS; i++) do_pop(3'd5, 1'b1);
    check_status();

    // ---------------- R9: inspect without removing -------------------------
    set_phase("R9 pop_en_i low inspects and does not remove");
    push_expect(3'd2, 32'h1111_0000);
    push_expect(3'd2, 32'h2222_0000);
    for (int i = 0; i < 4; i++) begin
      do_pop(3'd2, 1'b0);          // same entry every time, count unchanged
      check_status();
    end
    do_pop(3'd2, 1'b1);            // now remove it
    check_status();
    do_pop(3'd2, 1'b0);            // the second entry is now the oldest
    do_pop(3'd2, 1'b1);
    check_status();
    do_pop(3'd2, 1'b1);            // R10: the tag is empty again

    // ---------------- R10: empty tag among occupied ones -------------------
    set_phase("R10 pop of an empty tag while other tags hold entries");
    push_expect(3'd1, 32'h5555_AAAA);
    push_expect(3'd6, 32'h6666_BBBB);
    for (int t = 0; t < NTAG; t++)
      if (t != 1 && t != 6) do_pop(t[TAG_W-1:0], 1'b1);
    check_status();

    // ---------------- R12/R13: search --------------------------------------
    set_phase("R12/R13 search over the stored payloads");
    do_match(32'h5555_AAAA, 32'hFFFF_FFFF);   // exact hit
    do_match(32'h6666_BBBB, 32'hFFFF_FFFF);   // exact hit
    do_match(32'h1234_5678, 32'hFFFF_FFFF);   // miss
    do_match(32'h5555_0000, 32'hFFFF_0000);   // masked hit
    do_match(32'h5555_0000, 32'hFFFF_FFFF);   // same value, full mask: miss
    do_match(32'h0000_AAAA, 32'h0000_FFFF);   // low half hit
    do_match(32'hFFFF_FFFF, 32'h0000_0000);   // R13: mask zero, store non-empty
    do_match(32'h0000_0000, 32'h0000_0000);   // R13 again, different data
    // a value that is present only in the masked-off bits must not hit
    do_match(32'h5555_FFFF, 32'h0000_FFFF);
    for (int t = 0; t < NTAG; t++) do_pop(t[TAG_W-1:0], 1'b1);
    check_status();
    set_phase("R13 mask zero on an empty store");
    do_match(32'h0000_0000, 32'h0000_0000);   // R12: no entry, so no hit

    // ---------------- R2 across interleaved tags ---------------------------
    set_phase("R2 interleaved tags keep their own order");
    push_expect(3'd3, 32'h0300_0001);
    push_expect(3'd4, 32'h0400_0001);
    push_expect(3'd3, 32'h0300_0002);
    push_expect(3'd4, 32'h0400_0002);
    push_expect(3'd3, 32'h0300_0003);
    check_status();
    do_pop(3'd4, 1'b1);
    do_pop(3'd3, 1'b1);
    do_pop(3'd3, 1'b0);
    do_pop(3'd4, 1'b1);
    do_pop(3'd3, 1'b1);
    do_pop(3'd3, 1'b1);
    check_status();

    // ---------------- R15: reset with entries in flight --------------------
    set_phase("R15 reset discards what was stored");
    push_expect(3'd0, 32'h7777_0001);
    push_expect(3'd7, 32'h7777_0002);
    push_expect(3'd7, 32'h7777_0003);
    check_status();
    bfm_reset(4);
    mdl_clear();
    @(posedge clk);
    if (empty !== 1'b1) oops("R15", "empty_o is not high after a reset with entries stored");
    if (full  !== 1'b0) oops("R15", "full_o is not low after a reset with entries stored");
    for (int t = 0; t < NTAG; t++) do_pop(t[TAG_W-1:0], 1'b1);
    do_match(32'h7777_0002, 32'hFFFF_FFFF);   // must not survive the reset
    check_status();

    // ---------------- randomised soak --------------------------------------
    set_phase("randomised mix of pushes, pops and searches");
    for (int i = 0; i < 500; i++) begin
      r    = rnd_next();
      tsel = r % NTAG;
      dv   = 32'((r << 5) ^ 32'h9E37_79B9) ^ 32'(i);
      if ((r % 100) < 45) begin
        if (mdl_count() < SLOTS) push_expect(tsel[TAG_W-1:0], dv);
        else push_must_refuse(tsel[TAG_W-1:0], dv, 3);
      end else if ((r % 100) < 80) begin
        do_pop(tsel[TAG_W-1:0], (((r >> 7) & 1) != 0) ? 1'b1 : 1'b0);
      end else begin
        case ((r >> 9) % 4)
          0: do_match(dv, 32'hFFFF_FFFF);
          1: do_match(dv, 32'h0000_00FF);
          2: do_match(32'h0000_0000, 32'h0000_0000);
          default: do_match(dv & 32'hFFFF_0000, 32'hFFFF_0000);
        endcase
      end
      if ((i % 16) == 0) check_status();
    end
    check_status();

    // drain and confirm the store empties cleanly
    set_phase("drain");
    for (int t = 0; t < NTAG; t++)
      for (int i = 0; i < SLOTS; i++)
        if (mdl[t].size() > 0) do_pop(t[TAG_W-1:0], 1'b1);
    check_status();
    if (mdl_count() != 0)
      oops("R9", "the model still holds entries after draining every tag");

    if (errs == 0) begin
      $display("all checks clean");
      $display("RESULT: PASS");
    end else begin
      $display("%0d failure(s)", errs);
      $display("RESULT: FAIL");
    end
    $finish;
  end

endmodule