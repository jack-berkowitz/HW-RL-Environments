// ---------------------------------------------------------------------------
// tag_tracker_tb -- self-checking testbench for tag_tracker
// Config: TAG_W=3, SLOTS=8, N_MATCH=1, payload_t=logic[31:0]
// ---------------------------------------------------------------------------
module tag_tracker_tb;

  localparam int TAG_W    = 3;
  localparam int SLOTS    = 8;
  localparam int N_MATCH  = 1;

  typedef logic [31:0] pl_t;
  typedef struct packed { logic [TAG_W-1:0] t; pl_t d; } rec_t;

  // ---- PROVIDED PLUMBING -- clock, reset and watchdog only -----------------
  logic clk;
  initial begin clk = 1'b0; forever #5 clk = ~clk; end

  logic rst_n;
  initial rst_n = 1'b0;

  task automatic bfm_reset(input int cycles = 4);
    begin
      @(negedge clk);
      rst_n = 1'b0;
      repeat (cycles) @(posedge clk);
      @(negedge clk);
      rst_n = 1'b1;
    end
  endtask

  task automatic bfm_drive_point();
    begin @(negedge clk); end
  endtask

  task automatic bfm_tick();
    begin @(posedge clk); end
  endtask

  initial begin
    #20_000_000;
    $display("RESULT: FAIL (watchdog: no forward progress)");
    $finish;
  end

  // ---- DUT I/O (packed dimensions match the port map exactly) --------------
  logic [TAG_W-1:0] push_tag, pop_tag;
  pl_t              push_data, pop_data_w;
  logic             push_req, push_gnt;
  logic             pop_req, pop_gnt, pop_en, pop_valid;
  pl_t              [N_MATCH-1:0] match_data, match_mask;
  logic             [N_MATCH-1:0] match_req, match_hit, match_gnt;
  logic             full_o, empty_o;

  tag_tracker #(
    .TAG_W(TAG_W), .SLOTS(SLOTS), .FULL_RATE(1'b0), .CUT_POP_PATH(1'b0),
    .N_MATCH(N_MATCH), .payload_t(pl_t)
  ) dut (
    .clk_i(clk), .rst_ni(rst_n),
    .push_tag_i(push_tag), .push_data_i(push_data),
    .push_req_i(push_req), .push_gnt_o(push_gnt),
    .match_data_i(match_data), .match_mask_i(match_mask),
    .match_req_i(match_req), .match_hit_o(match_hit), .match_gnt_o(match_gnt),
    .pop_tag_i(pop_tag), .pop_en_i(pop_en), .pop_req_i(pop_req),
    .pop_data_o(pop_data_w), .pop_data_valid_o(pop_valid), .pop_gnt_o(pop_gnt),
    .full_o(full_o), .empty_o(empty_o)
  );

  // ---- reference model: flat queue of (tag,payload), count = size ----------
  rec_t m_store [$];
  int   errors;

  task automatic fail(input string req, input string msg);
    begin
      errors++;
      $display("FAIL %s: %s", req, msg);
    end
  endtask

  // ---- push: hold request until grant (bounded), then commit model ---------
  task automatic do_push(input logic [TAG_W-1:0] tag, input pl_t data);
    automatic int   tries   = 0;
    automatic bit   granted = 0;
    automatic bit   aborted = 0;
    automatic rec_t r;
    begin
      push_tag  = tag;
      push_data = data;
      @(negedge clk);
      push_req  = 1'b1;
      while (!granted && !aborted) begin
        @(posedge clk);
        if (push_gnt === 1'b1) granted = 1;
        else begin
          tries++;
          if (tries > 500) begin
            fail("R4", "push request never granted");
            aborted = 1;
          end
        end
      end
      @(negedge clk);
      push_req = 1'b0;
      if (granted) begin
        r.t = tag;
        r.d = data;
        m_store.push_back(r);
      end
    end
  endtask

  // ---- pop: hold request until grant; check valid/data against model -------
  task automatic do_pop(input logic [TAG_W-1:0] tag, input bit en);
    automatic int tries   = 0;
    automatic bit granted = 0;
    automatic bit aborted = 0;
    automatic bit exp_valid;
    automatic pl_t exp_data;
    automatic int idx;
    begin
      pop_tag = tag;
      pop_en  = en;
      @(negedge clk);
      pop_req = 1'b1;
      while (!granted && !aborted) begin
        @(posedge clk);
        if (pop_gnt === 1'b1) granted = 1;
        else begin
          tries++;
          if (tries > 500) begin
            fail("R7", "pop request never granted");
            aborted = 1;
          end
        end
      end
      if (granted) begin
        // oldest entry for this tag in the model
        idx = -1;
        for (int i = 0; i < m_store.size(); i++) begin
          if (m_store[i].t == tag) begin idx = i; break; end
        end
        exp_valid = (idx >= 0);
        if (exp_valid) exp_data = m_store[idx].d;
        if (pop_valid !== exp_valid)
          fail("R8", $sformatf("pop_data_valid mismatch for tag %0d", tag))
        else if (exp_valid) begin
          if (pop_data_w !== exp_data)
            fail("R8", $sformatf("pop_data not oldest entry for tag %0d", tag));
          if (en) m_store.delete(idx);   // R9: remove only when pop_en
        end
      end
      @(negedge clk);
      pop_req = 1'b0;
    end
  endtask

  // ---- match: hold request until grant; check hit against model -------------
  task automatic do_match(input pl_t data, input pl_t mask);
    automatic int tries   = 0;
    automatic bit granted = 0;
    automatic bit aborted = 0;
    automatic bit exp_hit = 0;
    begin
      match_data[0] = data;
      match_mask[0] = mask;
      @(negedge clk);
      match_req[0] = 1'b1;
      while (!granted && !aborted) begin
        @(posedge clk);
        if (match_gnt[0] === 1'b1) granted = 1;
        else begin
          tries++;
          if (tries > 500) begin
            fail("R11", "match request never granted");
            aborted = 1;
          end
        end
      end
      if (granted) begin
        for (int i = 0; i < m_store.size(); i++) begin
          if ((m_store[i].d & mask) == (data & mask)) exp_hit = 1;
        end
        if (match_hit[0] !== exp_hit)
          fail("R12", $sformatf("match_hit mismatch (expected %b)", exp_hit));
      end
      @(negedge clk);
      match_req[0] = 1'b0;
    end
  endtask

  // ---- status check (quiet cycles first so outputs are settled) ------------
  task automatic check_status();
    automatic bit e_exp, f_exp;
    begin
      @(negedge clk);
      push_req = 1'b0; pop_req = 1'b0; match_req = '0;
      @(posedge clk);
      @(negedge clk);
      @(posedge clk);
      e_exp = (m_store.size() == 0);
      f_exp = (m_store.size() == SLOTS);
      if (empty_o !== e_exp)
        fail("R14", $sformatf("empty_o mismatch (model count %0d)", m_store.size()));
      if (full_o !== f_exp)
        fail("R14", $sformatf("full_o mismatch (model count %0d)", m_store.size()));
    end
  endtask

  // ---- R5: no push grant while full -----------------------------------------
  task automatic check_full_no_gnt();
    begin
      @(negedge clk);
      push_tag  = '0;
      push_data = '0;
      push_req  = 1'b1;
      repeat (4) begin
        @(posedge clk);
        if (push_gnt === 1'b1)
          fail("R5", "push_gnt high while store holds SLOTS entries");
      end
      @(negedge clk);
      push_req = 1'b0;
    end
  endtask

  // ---- main sequence ---------------------------------------------------------
  initial begin
    errors    = 0;
    push_req  = 1'b0; pop_req = 1'b0; pop_en = 1'b0;
    push_tag  = '0;   pop_tag = '0;   push_data = '0;
    match_req = '0;   match_data = '0; match_mask = '0;
    m_store.delete();

    bfm_reset();
    check_status();                                // R15: empty after reset

    // searches on an empty store (R12/R13)
    do_match(32'h0000_0000, 32'h0000_0000);       // all-zero mask, empty -> miss
    do_match(32'hDEAD_BEEF, 32'hFFFF_FFFF);        // empty -> miss

    // R1: SLOTS entries all with the same tag
    for (int i = 0; i < SLOTS; i++) do_push(3, 32'h0000_0100 + i);
    check_status();                                // full
    check_full_no_gnt();                           // R5
    do_match(32'h0000_0000, 32'h0000_0000);        // non-empty -> hit (R13)

    // R2/R8: per-tag FIFO order
    for (int i = 0; i < SLOTS; i++) do_pop(3, 1'b1);
    check_status();                                // empty again
    do_pop(3, 1'b1);                               // R10: absent tag, not an error

    // R9 (observed via R8): peek does not remove
    do_push(5, 32'hAAAA0001);
    do_push(5, 32'hAAAA0002);
    do_pop(5, 1'b0);                               // peek -> oldest
    do_pop(5, 1'b0);                               // still oldest
    do_pop(5, 1'b1);                               // remove oldest
    do_pop(5, 1'b1);                               // second entry
    do_pop(5, 1'b1);                               // absent
    check_status();

    // multi-tag storage + search (R12/R13)
    do_push(0, 32'hDEAD_0000);
    do_push(1, 32'hDEAD_0001);
    do_push(2, 32'hBEEF_0000);
    do_push(2, 32'hDEAD_0002);
    do_match(32'hDEAD_0000, 32'hFFFF_FFFF);        // exact hit
    do_match(32'hDEAD_0009, 32'hFFFF_FFFF);        // exact miss
    do_match(32'hDEAD_0000, 32'hFFFF_0000);        // masked hit
    do_match(32'h0000_0000, 32'h0000_0000);        // zero mask -> hit
    do_match(32'hDEAD_0000, 32'h0000_FFFF);        // low-half mask hit
    do_match(32'hCAFE_0000, 32'hFFFF_0000);        // masked miss
    do_match(32'h0000_0000, 32'h0000_0000);        // still non-empty -> hit
    do_pop(2, 1'b1);                               // per-tag FIFO across tags
    do_pop(2, 1'b1);
    do_pop(0, 1'b1);
    do_pop(1, 1'b1);
    check_status();
    do_match(32'h0000_0000, 32'h0000_0000);        // empty -> miss

    // R1: mixed distribution summing to SLOTS
    do_push(0, 32'h0000_0010);
    do_push(0, 32'h0000_0011);
    do_push(0, 32'h0000_0012);
    do_push(7, 32'h0000_0070);
    do_push(7, 32'h0000_0071);
    do_push(1, 32'h0000_0020);
    do_push(1, 32'h0000_0021);
    do_push(1, 32'h0000_0022);
    check_status();                                // full
    check_full_no_gnt();                           // R5
    do_pop(0, 1'b1); do_pop(0, 1'b1); do_pop(0, 1'b1);
    do_pop(7, 1'b1); do_pop(7, 1'b1);
    do_pop(1, 1'b1); do_pop(1, 1'b1); do_pop(1, 1'b1);
    check_status();                                // empty

    // R15: reset while non-empty clears the store
    do_push(2, 32'h0000_0099);
    do_push(4, 32'h0000_0088);
    bfm_reset();
    m_store.delete();
    check_status();
    do_pop(2, 1'b1);                               // absent after reset
    do_match(32'h0000_0000, 32'h0000_0000);        // miss after reset

    if (errors == 0) $display("RESULT: PASS");
    else             $display("RESULT: FAIL");
    $finish;
  end

endmodule
