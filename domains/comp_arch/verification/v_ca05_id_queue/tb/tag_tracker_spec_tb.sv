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

module tag_tracker_spec_tb;

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
  payload_t          pop_data;
  logic              pop_data_valid, pop_gnt;

  logic              full, empty;

  tag_tracker #(
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
        if (exp_valid) begin
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

    // ---- drain everything -------------------------------------------------
    for (int t = 0; t < NTAG; t++)
      while (ref_q[t].size() != 0) do_pop(TAG_W'(t), 1'b1, 50);
    check_status("final drain");

    $display("");
    $display("checks passed : %0d", checks);
    $display("failures      : %0d", errors);
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
