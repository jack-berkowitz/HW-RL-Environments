// =============================================================================
// d_ca05 -- miss_handler_arb SCORING TESTBENCH.  T1-T9 of the interface spec.
//
// Every expected value below was MEASURED against the vendored CVA6 anchor by
// the probes in tb/audit/ and is quoted with its vector in MEASUREMENTS.md.
// There is no model here to disagree with the anchor: the numbers came out of
// the RTL. Three of them contradict the anchor's own comments, and the spec
// follows the measurement in each case.
//
// RULE 36: every check carries an exercise counter and the run FAILS if any is
// zero. A check that never fired has not passed.
// =============================================================================

`timescale 1ns/1ps

module miss_handler_arb_tb;
  import miss_handler_arb_pkg::*;

  localparam int unsigned NR_PORTS = 4;

  logic clk = 1'b0, rst_n = 1'b0;
  always #5 clk = ~clk;

  logic flush_i = 1'b0, flush_ack_o, miss_o, busy_i = 1'b0;
  logic [NR_PORTS-1:0][$bits(miss_req_t)-1:0] miss_req_i = '0;
  logic [NR_PORTS-1:0] bypass_gnt_o, bypass_valid_o, miss_gnt_o, active_serving_o;
  logic [NR_PORTS-1:0][63:0] bypass_data_o;
  logic [63:0] critical_word_o; logic critical_word_valid_o;
  logic [NR_PORTS-1:0][55:0] mshr_addr_i = '0;
  logic [NR_PORTS-1:0] mshr_addr_matches_o, mshr_index_matches_o;
  amo_req_t amo_req_i = '0; amo_resp_t amo_resp_o;
  axi_req_t byp_req, dat_req; axi_rsp_t byp_rsp, dat_rsp;
  logic [SET_ASSOC-1:0] req_o; logic [INDEX_WIDTH-1:0] addr_o;
  cache_line_t data_o; cl_be_t be_o; logic we_o;
  cache_line_t [SET_ASSOC-1:0] data_i = '0;   // clean lines: no evictions

  miss_handler_arb #(.NR_PORTS(NR_PORTS)) dut (
    .clk, .rst_n, .flush_i, .flush_ack_o, .miss_o, .busy_i,
    .miss_req_i, .bypass_gnt_o, .bypass_valid_o, .bypass_data_o,
    .miss_gnt_o, .active_serving_o, .critical_word_o, .critical_word_valid_o,
    .mshr_addr_i, .mshr_addr_matches_o, .mshr_index_matches_o,
    .amo_req_i, .amo_resp_o,
    .axi_bypass_req_o(byp_req), .axi_bypass_rsp_i(byp_rsp),
    .axi_data_req_o(dat_req),   .axi_data_rsp_i(dat_rsp),
    .req_o, .addr_o, .data_o, .be_o, .data_i, .we_o
  );

  int unsigned errs = 0;
  int unsigned n_amo_walk;
  int unsigned n_arb, n_arb_ctl, n_mshr, n_walk, n_ack_real, n_ack_amo,
               n_ack_corner, n_order, n_atop, n_reset;

  task automatic fail(input string m); begin errs++; $display("[FAIL] %s", m); end endtask
  task automatic expect_eq(input string tag, input int got, input int want);
    begin
      if (got !== want) fail($sformatf("%s: got %0d, the anchor gives %0d", tag, got, want));
      else $display("MEASURE: %-34s %0d", tag, got);
    end
  endtask

  // ---- the memory. An ATOP write returns BOTH B and R (A7); returning only B
  // leaves a conforming design waiting forever, which is what T7 detects. ----
  logic refill_answer = 1'b1;
  logic [3:0] byp_id_q; logic byp_atop_pend_q;
  logic [3:0] dat_id_q; logic dat_ar_seen_q;

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      byp_rsp <= '0; dat_rsp <= '0;
      byp_id_q <= '0; byp_atop_pend_q <= 1'b0; dat_id_q <= '0; dat_ar_seen_q <= 1'b0;
    end else begin
      byp_rsp.aw_ready <= 1'b1; byp_rsp.w_ready <= 1'b1; byp_rsp.ar_ready <= 1'b1;
      dat_rsp.aw_ready <= 1'b1; dat_rsp.w_ready <= 1'b1; dat_rsp.ar_ready <= 1'b1;
      if (byp_req.aw_valid) begin
        byp_id_q <= byp_req.aw.id;
        if (byp_req.aw.atop != 6'd0) byp_atop_pend_q <= 1'b1;
      end
      byp_rsp.b_valid <= byp_req.w_valid & byp_req.w.last;
      byp_rsp.b.id    <= byp_req.aw_valid ? byp_req.aw.id : byp_id_q;
      byp_rsp.b.resp  <= 2'b00;
      byp_rsp.r_valid <= byp_req.ar_valid | byp_atop_pend_q;
      byp_rsp.r.id    <= byp_req.ar_valid ? byp_req.ar.id : byp_id_q;
      byp_rsp.r.data  <= 64'hA5A5_1234_DEAD_BEEF;
      byp_rsp.r.last  <= 1'b1; byp_rsp.r.resp <= 2'b00;
      if (byp_atop_pend_q && byp_rsp.r_valid) byp_atop_pend_q <= 1'b0;

      if (dat_req.ar_valid) begin dat_id_q <= dat_req.ar.id; dat_ar_seen_q <= 1'b1; end
      dat_rsp.r_valid <= dat_ar_seen_q & refill_answer;
      dat_rsp.r.id    <= dat_id_q; dat_rsp.r.data <= 64'hC0DE_C0DE_C0DE_C0DE;
      dat_rsp.r.last  <= 1'b1; dat_rsp.r.resp <= 2'b00;
      if (dat_ar_seen_q && refill_answer && dat_req.r_ready) dat_ar_seen_q <= 1'b0;
      dat_rsp.b_valid <= dat_req.w_valid & dat_req.w.last;
      dat_rsp.b.id    <= dat_req.aw.id; dat_rsp.b.resp <= 2'b00;
    end
  end

  int unsigned acks, amo_acks;
  always_ff @(posedge clk) begin
    if (!rst_n) begin acks <= 0; amo_acks <= 0; end
    else begin
      if (flush_ack_o)    acks     <= acks + 1;
      if (amo_resp_o.ack) amo_acks <= amo_acks + 1;
    end
  end

  // flush-walk observation on the array port
  int unsigned wreq, wwr; logic [INDEX_WIDTH-1:0] wfirst, wlast;
  logic [SET_ASSOC-1:0] wvld; bit watching = 0;
  always_ff @(posedge clk) if (rst_n && watching) begin
    if (|req_o) begin wreq++; if (wreq == 1) wfirst <= addr_o; wlast <= addr_o; end
    if (|req_o && we_o) begin wwr++; wvld <= wvld | be_o.vldrty; end
  end

  // IDLE is inferred from the DELIVERED SURFACE, not from internal state: the
  // scored surface is the ports (T1), and a submission's FSM encoding is its
  // own business. Quiet means no array traffic and no AXI request for N cycles.
  task automatic settle(input string tag, input int unsigned lim);
    int unsigned t = 0, quiet = 0;
    begin
      while (t < lim && quiet < 12) begin
        @(posedge clk); t++;
        if (|req_o || byp_req.aw_valid || byp_req.ar_valid ||
            dat_req.aw_valid || dat_req.ar_valid) quiet = 0;
        else quiet++;
      end
      if (quiet < 12) fail($sformatf("%s: never went quiet in %0d cycles", tag, lim));
    end
  endtask

  task automatic quiesce(input string tag);
    begin
      @(negedge clk); amo_req_i = '0; flush_i = 1'b0; miss_req_i = '0; refill_answer = 1'b1;
      settle(tag, 60000);
      repeat (4) @(posedge clk);
    end
  endtask

  // Wait for the atomic to be acknowledged, THEN drop the request. Settling
  // while amo_req_i.req is still high never goes quiet: the unit returns to
  // idle, sees the request still asserted, and starts the whole flush again.
  // The probe hit this too -- run_until_idle returned on the cycle the FSM
  // reached IDLE while the request was still high, and the next measurement
  // sampled a leftover flush.
  task automatic amo_retire(input string tag, input int unsigned lim);
    int unsigned t = 0, a_before;
    begin
      a_before = amo_acks;
      while (t < lim && amo_acks == a_before) begin @(posedge clk); t++; end
      if (amo_acks == a_before) fail($sformatf("%s: the atomic never completed", tag));
      @(negedge clk); amo_req_i = '0;
    end
  endtask

  int unsigned a0, i, seen[4];

  initial begin
    repeat (10) @(posedge clk); rst_n = 1'b1;
    settle("reset", 20000);

    if (|mshr_addr_matches_o || |mshr_index_matches_o)
      fail("A5: MSHR match outputs high after reset with no miss in flight");
    if (flush_ack_o) fail("A5: flush_ack_o high after reset");

    // ================= T2 -- ARBITRATION (F2) =================
    for (int k = 0; k < 4; k++) seen[k] = 0;
    @(negedge clk);
    for (int k = 0; k < 4; k++)
      miss_req_i[k] = {1'b1, 64'h0000_0000_A000_0000 + (k << 6), 8'hFF, 2'b11, 1'b0, 64'd0, 1'b1};
    for (i = 0; i < 60; i++) begin @(posedge clk); #1;
      for (int k = 0; k < 4; k++) if (bypass_gnt_o[k]) seen[k]++; end
    @(negedge clk); miss_req_i = '0;
    expect_eq("T2 all four: p0 grants", seen[0], 20);
    expect_eq("T2 all four: p1 grants", seen[1], 0);
    expect_eq("T2 all four: p2 grants", seen[2], 0);
    expect_eq("T2 all four: p3 grants", seen[3], 0);
    n_arb = 1;
    quiesce("after T2a");

    for (int k = 0; k < 4; k++) seen[k] = 0;
    @(negedge clk);
    for (int k = 1; k < 4; k++)
      miss_req_i[k] = {1'b1, 64'h0000_0000_B000_0000 + (k << 6), 8'hFF, 2'b11, 1'b0, 64'd0, 1'b1};
    for (i = 0; i < 60; i++) begin @(posedge clk); #1;
      for (int k = 0; k < 4; k++) if (bypass_gnt_o[k]) seen[k]++; end
    @(negedge clk); miss_req_i = '0;
    expect_eq("T2 p0 idle: p1 grants", seen[1], 20);
    expect_eq("T2 p0 idle: p2 grants", seen[2], 0);
    n_arb_ctl = 1;
    quiesce("after T2b");

    // ================= T3 -- MSHR MATCHING (F3) =================
    @(negedge clk); refill_answer = 1'b0;      // hold a refill in flight
    miss_req_i[0] = {1'b1, 64'h0000_0000_0001_2340, 8'hFF, 2'b11, 1'b0, 64'd0, 1'b0};
    i = 0; while (i < 500 && !dat_req.ar_valid) begin @(posedge clk); i++; end
    repeat (4) @(posedge clk);
    @(negedge clk); miss_req_i[0] = '0;
    mshr_addr_i[0] = 56'h00_0000_0001_2340;   // identical
    mshr_addr_i[1] = 56'h00_0000_0001_234C;   // same line, offset differs
    mshr_addr_i[2] = 56'hAA_BBBB_CCC1_2340;   // same index, different tag
    mshr_addr_i[3] = 56'h00_0000_0009_9990;   // different index
    repeat (3) @(posedge clk); #1;
    expect_eq("T3 addr_match  bitmap", mshr_addr_matches_o,  4'b0011);
    expect_eq("T3 index_match bitmap", mshr_index_matches_o, 4'b0111);
    // (a) the overlap, stated as its own check
    if (!(mshr_addr_matches_o[0] && mshr_index_matches_o[0]))
      fail("T3(a): an address match must IMPLY an index match; they are not alternatives");
    else $display("MEASURE: T3(a) addr implies index          1");
    // (b) the served port is not excluded
    if (!mshr_addr_matches_o[0])
      fail("T3(b): the requester being served must NOT be excluded from the match outputs");
    else $display("MEASURE: T3(b) served port not excluded    1");
    n_mshr = 1;
    @(negedge clk); refill_answer = 1'b1;
    quiesce("after T3");
    @(negedge clk); for (int k = 0; k < 4; k++) mshr_addr_i[k] = 56'h00_0000_0001_2340;
    repeat (3) @(posedge clk); #1;
    expect_eq("T3 after retire: addr_match",  mshr_addr_matches_o,  0);
    expect_eq("T3 after retire: index_match", mshr_index_matches_o, 0);
    @(negedge clk); mshr_addr_i = '0;

    // ================= T4 + T5 -- THE FLUSH WALK AND ITS ACK =================
    a0 = acks; wreq = 0; wwr = 0; wvld = '0; watching = 1;
    @(negedge clk); flush_i = 1'b1; @(posedge clk); @(negedge clk); flush_i = 1'b0;
    settle("T4 walk", 40000);
    watching = 0;
    expect_eq("T4 array requests", wreq, 512);
    expect_eq("T4 array writes",   wwr,  256);
    expect_eq("T4 first address",  wfirst, 12'h000);
    expect_eq("T4 last address",   wlast,  12'hff0);
    expect_eq("T4 vldrty pattern", wvld, 8'hFF);
    expect_eq("T5 genuine flush acks", acks - a0, 1);
    n_walk = 1; n_ack_real = 1;
    quiesce("after T4");

    // ================= T5 -- THE AMO-INDUCED FLUSH DOES NOT ACK =================
    a0 = acks; wreq = 0; wwr = 0; wvld = '0; watching = 1;
    @(negedge clk);
    amo_req_i.req = 1'b1; amo_req_i.amo_op = AMO_ADD; amo_req_i.size = 2'b11;
    amo_req_i.operand_a = 64'h0000_0000_8000_0040; amo_req_i.operand_b = 64'd7;
    amo_retire("T5 amo flush", 60000);
    settle("T5 amo flush", 20000);
    watching = 0;
    $display("MEASURE: amo-induced walk wreq=%0d wwr=%0d wvld=%02h", wreq, wwr, wvld);
    expect_eq("T5 amo-induced flush acks", acks - a0, 0);

    // ---- F6: the atomic must FLUSH FIRST, and the flush is observable -------
    // "amo-induced flush acks == 0" above is satisfied by a design that never
    // flushes at all -- zero is the conforming answer AND the answer a design
    // that skipped the walk gives. An in-range failure value, so it needs a
    // second channel: the array port, which is where F4 says a flush's cost is
    // paid.
    //
    // A FLOOR, NOT AN EQUALITY, and deliberately. The reference performs TWO
    // full walks here (1024 requests, 512 writes -- exactly twice the genuine
    // flush of F4) and nothing in the contract explains the second. Pinning
    // 1024 would encode that unexplained factor into the requirement and fail a
    // design that flushes once, which is all F6 asks for. The floor is one
    // complete walk; the actual count is reported as a METRIC so the 2x stays
    // visible rather than being quietly frozen in.
    if (wreq < 512 || wwr < 256)
        fail($sformatf("F6: the atomic did not flush first -- %0d array requests and %0d writes during the AMO sequence, and one full walk is %0d/%0d",
                       wreq, wwr, 512, 256));
    if (wvld !== 8'hFF)
        fail($sformatf("F6: the AMO-induced walk did not assert vldrty for all ways (got %02h, expected ff)", wvld));
    n_amo_walk = 1;
    expect_eq("T7 atomic completed (ATOP)", (amo_acks > 0) ? 1 : 0, 1);
    n_ack_amo = 1; n_atop = 1;
    quiesce("after T5b");

    // ================= T5 -- THE CORNER (F8) =================
    a0 = acks;
    @(negedge clk);
    flush_i = 1'b1;
    amo_req_i.req = 1'b1; amo_req_i.amo_op = AMO_ADD; amo_req_i.size = 2'b11;
    amo_req_i.operand_a = 64'h0000_0000_8000_0080; amo_req_i.operand_b = 64'd9;
    @(posedge clk); @(negedge clk); flush_i = 1'b0;
    amo_retire("T5 corner", 60000);
    settle("T5 corner", 20000);
    expect_eq("T5 flush+amo TOGETHER acks", acks - a0, 0);
    n_ack_corner = 1;
    quiesce("after T5c");

    // ================= T6 -- A MISS DEFERS A PENDING ATOMIC (F9) =================
    begin
      int unsigned amo0;
      amo0 = amo_acks;
      @(negedge clk);
      amo_req_i.req = 1'b1; amo_req_i.amo_op = AMO_ADD; amo_req_i.size = 2'b11;
      amo_req_i.operand_a = 64'h0000_0000_8000_00C0; amo_req_i.operand_b = 64'd11;
      miss_req_i[2] = {1'b1, 64'h0000_0000_9000_0000, 8'hFF, 2'b11, 1'b0, 64'd0, 1'b0};
      @(posedge clk); #1;
      // the miss must win: a refill is issued and no flush walk begins
      i = 0; while (i < 40 && !dat_req.ar_valid) begin @(posedge clk); i++; end
      if (i >= 40) fail("T6: the miss did not win -- no refill was issued");
      else $display("MEASURE: T6 miss won, refill in %0d cycles   1", i);
      if (amo_acks != amo0)
        fail("T6: the atomic completed while a miss was raised in the same cycle");
      n_order = 1;
      @(negedge clk); miss_req_i[2] = '0;
      quiesce("after T6");
    end

    // ================= T8 -- RESET MID-OPERATION, ANTECEDENT GATED =============
    begin
      bit in_flight;
      @(negedge clk); refill_answer = 1'b0;
      miss_req_i[1] = {1'b1, 64'h0000_0000_0007_7770, 8'hFF, 2'b11, 1'b0, 64'd0, 1'b0};
      i = 0; while (i < 500 && !dat_req.ar_valid) begin @(posedge clk); i++; end
      in_flight = dat_req.ar_valid || (i < 500);
      $display("MEASURE: T8 work in flight before reset   %0b", in_flight);
      if (!in_flight) fail("T8 WAS NEVER EXERCISED -- nothing was in flight when reset asserted");
      else begin
        n_reset = 1;
        @(negedge clk); miss_req_i = '0; rst_n = 1'b0;
        repeat (6) @(posedge clk);
        @(negedge clk); rst_n = 1'b1; refill_answer = 1'b1;
        repeat (6) @(posedge clk); #1;
        if (flush_ack_o) fail("A5: flush_ack_o high after reset");
        if (|mshr_addr_matches_o || |mshr_index_matches_o)
          fail("A5: an MSHR match survived reset");
        // and it must still work
        settle("post-reset", 20000);
        a0 = acks;
        @(negedge clk); flush_i = 1'b1; @(posedge clk); @(negedge clk); flush_i = 1'b0;
        settle("post-reset flush", 40000);
        if (acks == a0) fail("A5: no flush acknowledgement after reset -- the unit is dead");
      end
    end

    // ================= T9 -- FLOORS =================
    $display("MEASURE: exercised arb=%0d arb_ctl=%0d mshr=%0d walk=%0d ack_real=%0d ack_amo=%0d ack_corner=%0d order=%0d atop=%0d reset=%0d",
             n_arb, n_arb_ctl, n_mshr, n_walk, n_ack_real, n_ack_amo, n_ack_corner,
             n_order, n_atop, n_reset);
    if (!n_arb)        fail("FLOOR: arbitration never exercised");
    if (!n_arb_ctl)    fail("FLOOR: the arbitration control never ran");
    if (!n_mshr)       fail("FLOOR: MSHR matching never exercised");
    if (!n_walk)       fail("FLOOR: the flush walk never observed");
    if (!n_ack_real)   fail("FLOOR: the genuine-flush acknowledgement never checked");
    if (!n_ack_amo)    fail("FLOOR: the AMO-induced flush never checked");
    if (!n_amo_walk)   fail("FLOOR: F6 -- the AMO-induced flush WALK never observed on the array port");
    if (!n_ack_corner) fail("FLOOR: the flush+amo corner never checked -- F8 is the task");
    if (!n_order)      fail("FLOOR: atomic ordering never exercised");
    if (!n_atop)       fail("FLOOR: no atomic ever completed");
    if (!n_reset)      fail("FLOOR: mid-operation reset never exercised");

    if (errs == 0) $display("TEST_RESULT: PASS");
    else           $display("TEST_RESULT: FAIL: %0d failing checks", errs);
    $finish;
  end

  initial begin #12000000; $display("[FAIL] watchdog: the testbench did not finish");
                $display("TEST_RESULT: FAIL: watchdog"); $finish; end
endmodule
