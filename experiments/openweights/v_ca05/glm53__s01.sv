module tag_tracker_tb;
  localparam int TAG_W = 3;
  localparam int SLOTS = 8;
  localparam int N_MATCH = 1;
  typedef logic [31:0] payload_t;
  typedef logic [TAG_W-1:0] tag_t;
  typedef struct packed { tag_t t; payload_t d; } ent_t;

  // ---- clock / reset / watchdog (provided plumbing) ------------------------
  logic clk_i;
  initial begin clk_i = 1'b0; forever #5 clk_i = ~clk_i; end
  logic rst_ni;
  initial rst_ni = 1'b0;
  task automatic bfm_reset(input int cycles = 4);
    @(negedge clk_i); rst_ni = 1'b0;
    repeat (cycles) @(posedge clk_i);
    @(negedge clk_i); rst_ni = 1'b1;
  endtask
  task automatic bfm_drive_point(); @(negedge clk_i); endtask
  initial begin
    #20_000_000;
    $display("RESULT: FAIL (watchdog: no forward progress)");
    $finish;
  end

  // ---- error bookkeeping ----------------------------------------------------
  int errors = 0;
  task automatic fail(input string r, input string m);
    errors++;
    $display("FAIL %0s: %0s", r, m);
  endtask

  // ---- DUT signals (names match ports for .* connection) --------------------
  tag_t     push_tag_i;
  payload_t push_data_i;
  logic     push_req_i, push_gnt_o;
  payload_t [N_MATCH-1:0] match_data_i, match_mask_i;
  logic     [N_MATCH-1:0] match_req_i, match_hit_o, match_gnt_o;
  tag_t     pop_tag_i;
  logic     pop_en_i, pop_req_i;
  payload_t pop_data_o;
  logic     pop_data_valid_o, pop_gnt_o;
  logic     full_o, empty_o;

  tag_tracker #(
    .TAG_W(TAG_W), .SLOTS(SLOTS), .FULL_RATE(1'b0), .CUT_POP_PATH(1'b0),
    .N_MATCH(N_MATCH), .payload_t(payload_t)
  ) dut (.*);

  // ---- reference model: single queue of (tag,payload) ----------------------
  ent_t m_q[$];

  function automatic int m_oldest(input tag_t t);
    for (int i = 0; i < m_q.size(); i++)
      if (m_q[i].t == t) return i;
    return -1;
  endfunction

  // R14: status flags vs model (call at a negedge, inputs stable)
  task automatic check_status(input string r);
    if (empty_o !== (m_q.size() == 0))      fail(r, "empty_o mismatch");
    if (full_o  !== (m_q.size() == SLOTS))  fail(r, "full_o mismatch");
  endtask

  // R4: push, hold until granted, commit on the granting edge
  task automatic do_push(input tag_t t, input payload_t d);
    bfm_drive_point();
    push_tag_i = t; push_data_i = d; push_req_i = 1'b1;
    for (int i = 0; i < 200; i++) begin
      @(posedge clk_i);
      if (push_gnt_o) begin
        ent_t e; e.t = t; e.d = d; m_q.push_back(e);
        break;
      end
      @(negedge clk_i);
    end
    if (!push_gnt_o) begin
      fail("R4", "push request never granted");
      $finish;
    end
    @(negedge clk_i); push_req_i = 1'b0;
    check_status("R14");
  endtask

  // R7/R8 (covers R2, R9, R10): pop or peek, check valid/data against model
  task automatic do_pop(input tag_t t, input logic en, input string r);
    int idx;
    logic expv;
    bfm_drive_point();
    pop_tag_i = t; pop_en_i = en; pop_req_i = 1'b1;
    for (int i = 0; i < 200; i++) begin
      @(posedge clk_i);
      if (pop_gnt_o) begin
        idx  = m_oldest(t);
        expv = (idx >= 0);
        if (pop_data_valid_o !== expv)
          fail(r, $sformatf("pop_data_valid tag=%0d got=%0b exp=%0b",
                            t, pop_data_valid_o, expv));
        else if (expv && pop_data_o !== m_q[idx].d)
          fail(r, $sformatf("pop_data tag=%0d got=0x%0h exp=0x%0h (FIFO order)",
                            t, pop_data_o, m_q[idx].d));
        if (expv && en) m_q.delete(idx);   // R9: remove only when pop_en
        break;
      end
      @(negedge clk_i);
    end
    if (!pop_gnt_o) begin
      fail(r, "pop request never granted");
      $finish;
    end
    @(negedge clk_i); pop_req_i = 1'b0;
    check_status("R14");
  endtask

  // R11/R12 (covers R13): search, check hit against model
  task automatic do_match(input payload_t d, input payload_t msk);
    bit exph;
    exph = 1'b0;
    for (int i = 0; i < m_q.size(); i++)
      if ((m_q[i].d & msk) == (d & msk)) exph = 1'b1;
    bfm_drive_point();
    match_data_i[0] = d; match_mask_i[0] = msk; match_req_i[0] = 1'b1;
    for (int i = 0; i < 200; i++) begin
      @(posedge clk_i);
      if (match_gnt_o[0]) begin
        if (match_hit_o[0] !== exph)
          fail("R12", $sformatf("match_hit got=%0b exp=%0b data=0x%0h mask=0x%0h",
                                match_hit_o[0], exph, d, msk));
        break;
      end
      @(negedge clk_i);
    end
    if (!match_gnt_o[0]) begin
      fail("R11", "match request never granted");
      $finish;
    end
    @(negedge clk_i); match_req_i[0] = 1'b0;
  endtask

  // ---- main sequence --------------------------------------------------------
  initial begin
    push_req_i = 0; pop_req_i = 0; pop_en_i = 0;
    match_req_i = '0; match_data_i = '0; match_mask_i = '0;
    push_tag_i = '0; push_data_i = '0; pop_tag_i = '0;

    bfm_reset();
    bfm_drive_point();
    if (empty_o !== 1'b1) fail("R15", "empty_o not high after reset");
    if (full_o  !== 1'b0) fail("R15", "full_o not low after reset");

    // R8/R10: pop of an absent tag completes with valid low
    do_pop(3'd3, 1'b1, "R8");

    // R1: SLOTS entries all with the same tag
    for (int i = 0; i < SLOTS; i++) do_push(3'd0, 32'h100 + i);

    // R5: push_gnt must be low while full
    bfm_drive_point();
    push_tag_i = 3'd0; push_data_i = 32'hdead; push_req_i = 1'b1;
    for (int i = 0; i < 16; i++) begin
      @(posedge clk_i);
      if (push_gnt_o) fail("R5", "push_gnt_o high while store full");
      @(negedge clk_i);
    end
    push_req_i = 1'b0;

    // R9 (via R8): peek does not remove
    do_pop(3'd0, 1'b0, "R8");   // expect 0x100, kept
    do_pop(3'd0, 1'b0, "R8");   // still 0x100
    // R2/R8: per-tag FIFO drain
    for (int i = 0; i < SLOTS; i++) do_pop(3'd0, 1'b1, "R8");
    bfm_drive_point();
    if (empty_o !== 1'b1) fail("R14", "empty_o not high after drain");

    // R12/R13 on an empty store
    do_match(32'h0, 32'h0);        // zero mask, empty -> miss
    do_match(32'h1234, 32'hffff);  // miss

    // mixed tags
    do_push(3'd1, 32'hA0);
    do_push(3'd2, 32'hB0);
    do_push(3'd1, 32'hA1);
    do_push(3'd2, 32'hB1);
    do_push(3'd1, 32'hA2);
    // R12: exact, masked, and zero-mask searches
    do_match(32'hA1, 32'hffffffff);       // hit
    do_match(32'hA5, 32'hffffffff);       // miss
    do_match(32'hA0, 32'h000000ff);        // hit (low byte)
    do_match(32'h00ff00, 32'h00ff00);     // miss
    do_match(32'h0, 32'h0);               // R13: non-empty -> hit
    // R2/R8: interleaved per-tag FIFO
    do_pop(3'd1, 1'b1, "R8");   // A0
    do_pop(3'd2, 1'b1, "R8");   // B0
    do_pop(3'd1, 1'b1, "R8");   // A1
    do_pop(3'd2, 1'b1, "R8");   // B1
    do_pop(3'd1, 1'b1, "R8");   // A2
    do_pop(3'd1, 1'b1, "R8");   // absent -> valid 0
    do_pop(3'd2, 1'b1, "R8");   // absent -> valid 0

    // R1: mixed distribution summing to SLOTS
    for (int i = 0; i < 3; i++) do_push(3'd5, 32'h50 + i);
    for (int i = 0; i < 5; i++) do_push(3'd6, 32'h60 + i);
    bfm_drive_point();
    if (full_o !== 1'b1) fail("R14", "full_o not high with SLOTS entries");
    do_match(32'h62, 32'h000000ff);       // hit
    do_match(32'h0, 32'h0);               // R13 hit
    for (int i = 0; i < 3; i++) do_pop(3'd5, 1'b1, "R8");
    for (int i = 0; i < 5; i++) do_pop(3'd6, 1'b1, "R8");

    // R15: reset clears a non-empty store
    for (int i = 0; i < 4; i++) do_push(3'd7, 32'h70 + i);
    bfm_drive_point();
    push_req_i = 0; pop_req_i = 0; match_req_i = '0;
    bfm_reset();
    m_q.delete();
    bfm_drive_point();
    if (empty_o !== 1'b1) fail("R15", "empty_o not high after mid-run reset");
    if (full_o  !== 1'b0) fail("R15", "full_o not low after mid-run reset");
    do_pop(3'd7, 1'b1, "R8");   // absent after reset

    if (errors == 0) $display("RESULT: PASS");
    else              $display("RESULT: FAIL");
    $finish;
  end
endmodule
