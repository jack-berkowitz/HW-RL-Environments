module tag_tracker_tb;
  // ---------------------------------------------------------------------------
  // Parameters
  // ---------------------------------------------------------------------------
  localparam int TAG_W   = 3;
  localparam int SLOTS   = 8;
  localparam int N_MATCH = 1;
  typedef logic [31:0] payload_t;
  typedef logic [TAG_W-1:0] tag_t;

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
    $display("RESULT: FAIL (watchdog: no forward progress)");
    $finish;
  end

  // ---------------------------------------------------------------------------
  // DUT connections (packed dimensions before the name, matching the ports)
  // ---------------------------------------------------------------------------
  tag_t     push_tag;
  payload_t push_data;
  logic     push_req, push_gnt;

  payload_t [N_MATCH-1:0] match_data, match_mask;
  logic     [N_MATCH-1:0] match_req, match_hit, match_gnt;

  tag_t     pop_tag;
  logic     pop_en, pop_req, pop_gnt, pop_data_valid;
  payload_t pop_data;

  logic full_o, empty_o;

  tag_tracker #(
    .TAG_W(TAG_W), .SLOTS(SLOTS), .FULL_RATE(1'b0), .CUT_POP_PATH(1'b0),
    .N_MATCH(N_MATCH), .payload_t(payload_t)
  ) dut (
    .clk_i(clk), .rst_ni(rst_n),
    .push_tag_i(push_tag), .push_data_i(push_data),
    .push_req_i(push_req), .push_gnt_o(push_gnt),
    .match_data_i(match_data), .match_mask_i(match_mask),
    .match_req_i(match_req), .match_hit_o(match_hit), .match_gnt_o(match_gnt),
    .pop_tag_i(pop_tag), .pop_eni(), // placeholder fixed below
    .pop_req_i(pop_req), .pop_data_o(pop_data),
    .pop_data_valid_o(pop_data_valid), .pop_gnt_o(pop_gnt),
    .full_o(full_o), .empty_o(empty_o)
  );

  // ---------------------------------------------------------------------------
  // Reference model: flat FIFO of (tag, payload), oldest-first.
  // ---------------------------------------------------------------------------
  tag_t     m_tag[$];
  payload_t m_dat[$];

  function automatic int m_count();
    return m_tag.size();
  endfunction

  function automatic int m_find_oldest(input tag_t t);
    for (int i = 0; i < m_tag.size(); i++)
      if (m_tag[i] == t) return i;
    return -1;
  endfunction

  logic failed;

  task automatic fail_msg(input string req_id, input string msg);
    begin
      $display("FAIL %s: %s", req_id, msg);
      failed = 1'b1;
    end
  endtask

  // R14: empty_o / full_o must track the model exactly.
  task automatic chk_status();
    if (empty_o !== (m_count() == 0))
      fail_msg("R14", $sformatf("empty_o=%b, model count=%0d", empty_o, m_count()));
    if (full_o !== (m_count() == SLOTS))
      fail_msg("R14", $sformatf("full_o=%b, model count=%0d", full_o, m_count()));
  endtask

  // ---------------------------------------------------------------------------
  // Transactors: drive at negedge, sample grants/results at the following
  // negedge (inputs held stable across the sampling posedge). Each waits a
  // bounded number of cycles for a grant and aborts the run if none comes.
  // ---------------------------------------------------------------------------
  localparam int GNT_TIMEOUT = 200;

  task automatic do_push(input tag_t t, input payload_t d);
    int cyc;
    begin
      push_tag  = t;
      push_data = d;
      push_req  = 1'b1;
      cyc = 0;
      forever begin
        @(negedge clk);
        if (push_gnt === 1'b1) break;
        cyc++;
        if (cyc > GNT_TIMEOUT) begin
          fail_msg("R4", "push never granted (timeout)");
          $display("RESULT: FAIL");
          $finish;
        end
      end
      // committed at the posedge that just passed
      m_tag.push_back(t);
      m_dat.push_back(d);
      push_req = 1'b0;
      chk_status();
    end
  endtask

  task automatic do_pop(input tag_t t, input bit en);
    int  idx;
    bit  exp_valid;
    payload_t exp_data;
    int cyc;
    begin
      idx = m_find_oldest(t);
      exp_valid = (idx >= 0);
      if (exp_valid) exp_data = m_dat[idx];
      pop_tag = t;
      pop_en  = en;
      pop_req = 1'b1;
      cyc = 0;
      forever begin
        @(negedge clk);
        if (pop_gnt === 1'b1) break;
        cyc++;
        if (cyc > GNT_TIMEOUT) begin
          fail_msg("R7", "pop never granted (timeout)");
          $display("RESULT: FAIL");
          $finish;
        end
      end
      if (pop_data_valid !== exp_valid)
        fail_msg("R8", $sformatf("pop_data_valid=%b, expected %b for tag %0d",
                                 pop_data_valid, exp_valid, t));
      if (exp_valid && pop_data !== exp_data)
        fail_msg("R8", $sformatf("pop_data=%h, expected oldest %h for tag %0d",
                                 pop_data, exp_data, t));
      if (exp_valid && en) begin
        m_tag.delete(idx);
        m_dat.delete(idx);
      end
      pop_req = 1'b0;
      pop_en  = 1'b0;
      chk_status();
    end
  endtask

  task automatic do_match(input payload_t d, input payload_t m);
    bit got, exp;
    int cyc;
    begin
      match_data[0] = d;
      match_mask[0] = m;
      match_req[0]  = 1'b1;
      cyc = 0;
      forever begin
        @(negedge clk);
        if (match_gnt[0] === 1'b1) break;
        cyc++;
        if (cyc > GNT_TIMEOUT) begin
          fail_msg("R11", "match never granted (timeout)");
          $display("RESULT: FAIL");
          $finish;
        end
      end
      exp = 1'b0;
      for (int i = 0; i < m_dat.size(); i++)
        if ((m_dat[i] & m) == (d & m)) exp = 1'b1;
      got = match_hit[0];
      if (got !== exp)
        fail_msg("R12", $sformatf("match_hit=%b, expected %b (data=%h mask=%h)",
                                 got, exp, d, m));
      match_req[0] = 1'b0;
      chk_status();
    end
  endtask

  // ---------------------------------------------------------------------------
  // Main sequence
  // ---------------------------------------------------------------------------
  initial begin
    failed    = 1'b0;
    push_req  = 1'b0;  push_tag = '0; push_data = '0;
    pop_req   = 1'b0;  pop_en   = 1'b0; pop_tag  = '0;
    match_req = '0;    match_data = '0; match_mask = '0;

    // ---- R15: reset behaviour --------------------------------------------
    bfm_reset();
    bfm_drive_point();
    if (empty_o !== 1'b1) fail_msg("R15", "empty_o not high after reset");
    if (full_o  !== 1'b0) fail_msg("R15", "full_o not low after reset");
    chk_status();

    // ---- R1 / R2 / R4: fill all SLOTS, several sharing a tag --------------
    do_push(tag_t'(1), 32'h0000_0100);
    do_push(tag_t'(1), 32'h0000_0101);
    do_push(tag_t'(2), 32'h0000_0102);
    do_push(tag_t'(1), 32'h0000_0103);
    do_push(tag_t'(3), 32'h0000_0104);
    do_push(tag_t'(2), 32'h0000_0105);
    do_push(tag_t'(1), 32'h0000_0106);
    do_push(tag_t'(3), 32'h0000_0107);
    if (full_o !== 1'b1) fail_msg("R1", "full_o not high at SLOTS entries");

    // ---- R5: no grant while full ------------------------------------------
    begin
      int cyc;
      push_tag = tag_t'(0);
      push_data = 32'hdead_beef;
      push_req = 1'b1;
      for (cyc = 0; cyc < 10; cyc++) begin
        @(negedge clk);
        if (push_gnt !== 1'b0)
          fail_msg("R5", "push_gnt high while store holds SLOTS entries");
      end
      push_req = 1'b0;
    end

    // ---- R9 (via R8): peek does not remove ---------------------------------
    do_pop(tag_t'(1), 1'b0);   // peek oldest of tag 1 -> 0x100, kept
    do_pop(tag_t'(1), 1'b1);   // real pop -> 0x100 again
    do_pop(tag_t'(1), 1'b1);   // next -> 0x101 (per-tag FIFO order, R2/R8)

    // ---- R10 (via R8): pop of an absent tag is not an error ----------------
    do_pop(tag_t'(5), 1'b1);   // tag 5 never pushed -> valid low

    // ---- R12 / R13: searches ----------------------------------------------
    // model now: 0x102(t2) 0x103(t1) 0x104(t3) 0x105(t2) 0x106(t1) 0x107(t3)
    do_match(32'h0000_0102, 32'hFFFF_FFFF); // exact hit
    do_match(32'h0000_0199, 32'hFFFF_FFFF); // exact miss
    do_match(32'h1234_5678, 32'h0000_0000); // R13: zero mask, non-empty -> hit
    do_match(32'h0000_0100, 32'hFFFF_FF00); // masked hit (0x1xx match)
    do_match(32'h0000_0200, 32'hFFFF_FF00); // masked miss
    do_match(32'h0000_0107, 32'h0000_00FF); // low-byte hit

    // ---- drain per tag, checking per-tag FIFO order (R2/R8) ----------------
    while (m_find_oldest(tag_t'(1)) >= 0) do_pop(tag_t'(1), 1'b1);
    while (m_find_oldest(tag_t'(2)) >= 0) do_pop(tag_t'(2), 1'b1);
    while (m_find_oldest(tag_t'(3)) >= 0) do_pop(tag_t'(3), 1'b1);
    if (empty_o !== 1'b1) fail_msg("R14", "empty_o not high after draining");
    do_pop(tag_t'(2), 1'b1);   // empty now -> valid low
    chk_status();

    // ---- R15: mid-run reset empties the store ------------------------------
    do_push(tag_t'(6), 32'h0000_0200);
    do_push(tag_t'(6), 32'h0000_0201);
    bfm_reset();
    bfm_drive_point();
    m_tag.delete();
    m_dat.delete();
    if (empty_o !== 1'b1) fail_msg("R15", "empty_o not high after mid-run reset");
    if (full_o  !== 1'b0) fail_msg("R15", "full_o not low after mid-run reset");
    chk_status();
    do_pop(tag_t'(6), 1'b1);   // must report absent after reset

    // ---- a final push/pop round --------------------------------------------
    do_push(tag_t'(7), 32'h0000_0300);
    do_match(32'h0000_0300, 32'hFFFF_FFFF);
    do_pop(tag_t'(7), 1'b1);
    chk_status();

    if (failed) $display("RESULT: FAIL");
    else        $display("RESULT: PASS");
    $finish;
  end

endmodule
