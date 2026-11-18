module tag_tracker_tb;

  // Parameters
  localparam int TAG_W = 3;
  localparam int SLOTS = 8;
  localparam int N_MATCH = 1;
  localparam int PAYLOAD_W = 32;

  // Signals
  logic clk;
  logic rst_n;

  logic [TAG_W-1:0] push_tag;
  logic [PAYLOAD_W-1:0] push_data;
  logic push_req;
  logic push_gnt;

  logic [PAYLOAD_W-1:0] [N_MATCH-1:0] match_data;
  logic [PAYLOAD_W-1:0] [N_MATCH-1:0] match_mask;
  logic [N_MATCH-1:0] match_req;
  logic [N_MATCH-1:0] match_hit;
  logic [N_MATCH-1:0] match_gnt;

  logic [TAG_W-1:0] pop_tag;
  logic pop_en;
  logic pop_req;
  logic [PAYLOAD_W-1:0] pop_data;
  logic pop_data_valid;
  logic pop_gnt;

  logic full;
  logic empty;

  // Model
  typedef struct packed {
    logic [TAG_W-1:0] tag;
    logic [PAYLOAD_W-1:0] data;
  } entry_t;

  entry_t model_q [$];

  int error_count;
  logic fatal;

  // DUT instantiation
  tag_tracker #(
      .TAG_W(TAG_W),
      .SLOTS(SLOTS),
      .FULL_RATE(1'b0),
      .CUT_POP_PATH(1'b0),
      .N_MATCH(N_MATCH),
      .payload_t(logic [PAYLOAD_W-1:0])
  ) dut (
      .clk_i(clk),
      .rst_ni(rst_n),
      .push_tag_i(push_tag),
      .push_data_i(push_data),
      .push_req_i(push_req),
      .push_gnt_o(push_gnt),
      .match_data_i(match_data),
      .match_mask_i(match_mask),
      .match_req_i(match_req),
      .match_hit_o(match_hit),
      .match_gnt_o(match_gnt),
      .pop_tag_i(pop_tag),
      .pop_en_i(pop_en),
      .pop_req_i(pop_req),
      .pop_data_o(pop_data),
      .pop_data_valid_o(pop_data_valid),
      .pop_gnt_o(pop_gnt),
      .full_o(full),
      .empty_o(empty)
  );

  // ---------------------------------------------------------------------------
  // PROVIDED PLUMBING -- clock, reset and watchdog only.
  // ---------------------------------------------------------------------------
  initial begin clk = 1'b0; forever #5 clk = ~clk; end

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
  // Testbench tasks
  // ---------------------------------------------------------------------------
  task automatic report_fail(input string req, input string msg);
    $display("FAIL: %s: %s", req, msg);
    error_count++;
  endtask

  task automatic check_status();
    if (model_q.size() == 0) begin
      if (empty !== 1'b1) report_fail("R14", "empty_o should be high when empty");
      if (full !== 1'b0) report_fail("R14", "full_o should be low when empty");
    end else if (model_q.size() == SLOTS) begin
      if (empty !== 1'b0) report_fail("R14", "empty_o should be low when full");
      if (full !== 1'b1) report_fail("R14", "full_o should be high when full");
    end else begin
      if (empty !== 1'b0) report_fail("R14", "empty_o should be low when not empty");
      if (full !== 1'b0) report_fail("R14", "full_o should be low when not full");
    end
  endtask

  task automatic do_push(input logic [TAG_W-1:0] tag, input logic [PAYLOAD_W-1:0] data, input int timeout = 1000);
    automatic int count = 0;
    automatic logic success = 0;
    @(negedge clk);
    push_tag = tag;
    push_data = data;
    push_req = 1'b1;
    while (count < timeout) begin
      @(posedge clk);
      if (push_gnt) begin
        model_q.push_back('{tag: tag, data: data});
        success = 1;
        @(negedge clk);
        push_req = 1'b0;
        break;
      end
      @(negedge clk);
      count++;
    end
    if (!success) begin
      report_fail("R4", $sformatf("push timeout for tag=%0d data=%0d", tag, data));
      push_req = 1'b0;
      fatal = 1;
    end
    check_status();
  endtask

  task automatic check_push_blocked(input logic [TAG_W-1:0] tag, input logic [PAYLOAD_W-1:0] data, input int cycles = 10);
    automatic int i;
    @(negedge clk);
    push_tag = tag;
    push_data = data;
    push_req = 1'b1;
    for (i = 0; i < cycles; i++) begin
      @(posedge clk);
      if (push_gnt) begin
        report_fail("R5", $sformatf("push_gnt_o high when full (tag=%0d data=%0d)", tag, data));
        fatal = 1;
        @(negedge clk);
        push_req = 1'b0;
        return;
      end
      @(negedge clk);
    end
    push_req = 1'b0;
    check_status();
  endtask

  task automatic do_pop(input logic [TAG_W-1:0] tag, input logic en, input int timeout = 1000);
    automatic int count = 0;
    automatic logic success = 0;
    automatic logic exp_valid;
    automatic logic [PAYLOAD_W-1:0] exp_data;
    automatic int idx;
    exp_valid = 0;
    exp_data = 0;
    idx = -1;
    for (int i = 0; i < model_q.size(); i++) begin
      if (model_q[i].tag == tag) begin
        exp_valid = 1;
        exp_data = model_q[i].data;
        idx = i;
        break;
      end
    end
    @(negedge clk);
    pop_tag = tag;
    pop_en = en;
    pop_req = 1'b1;
    while (count < timeout) begin
      @(posedge clk);
      if (pop_gnt) begin
        automatic logic valid = pop_data_valid;
        automatic logic [PAYLOAD_W-1:0] data = pop_data;
        if (valid !== exp_valid) begin
          report_fail("R8", $sformatf("pop valid mismatch: tag=%0d en=%0d exp_valid=%0d got=%0d", tag, en, exp_valid, valid));
        end else if (exp_valid && (data !== exp_data)) begin
          report_fail("R8", $sformatf("pop data mismatch: tag=%0d en=%0d exp_data=%0d got=%0d", tag, en, exp_data, data));
        end
        if (en && exp_valid) begin
          model_q.delete(idx);
        end
        success = 1;
        @(negedge clk);
        pop_req = 1'b0;
        break;
      end
      @(negedge clk);
      count++;
    end
    if (!success) begin
      report_fail("R7", $sformatf("pop timeout for tag=%0d en=%0d", tag, en));
      pop_req = 1'b0;
      fatal = 1;
    end
    check_status();
  endtask

  task automatic do_match(input logic [PAYLOAD_W-1:0] data, input logic [PAYLOAD_W-1:0] mask, input int timeout = 1000);
    automatic int count = 0;
    automatic logic success = 0;
    automatic logic exp_hit = 0;
    for (int i = 0; i < model_q.size(); i++) begin
      if ((model_q[i].data & mask) == (data & mask)) begin
        exp_hit = 1;
        break;
      end
    end
    @(negedge clk);
    match_data[0] = data;
    match_mask[0] = mask;
    match_req[0] = 1'b1;
    while (count < timeout) begin
      @(posedge clk);
      if (match_gnt[0]) begin
        automatic logic hit = match_hit[0];
        if (hit !== exp_hit) begin
          report_fail("R12", $sformatf("match hit mismatch: data=%08x mask=%08x exp=%0d got=%0d", data, mask, exp_hit, hit));
        end
        success = 1;
        @(negedge clk);
        match_req[0] = 1'b0;
        break;
      end
      @(negedge clk);
      count++;
    end
    if (!success) begin
      report_fail("R11", $sformatf("match timeout: data=%08x mask=%08x", data, mask));
      match_req[0] = 1'b0;
      fatal = 1;
    end
  endtask

  // ---------------------------------------------------------------------------
  // Main test sequence
  // ---------------------------------------------------------------------------
  initial begin
    // Initialize
    push_tag = '0;
    push_data = '0;
    push_req = 1'b0;
    match_data = '0;
    match_mask = '0;
    match_req = '0;
    pop_tag = '0;
    pop_en = 1'b0;
    pop_req = 1'b0;
    error_count = 0;
    fatal = 0;
    model_q.delete();

    // R15: reset check
    bfm_reset();
    @(posedge clk);
    @(negedge clk);
    if (empty !== 1'b1) report_fail("R15", "empty_o not high after reset");
    if (full !== 1'b0) report_fail("R15", "full_o not low after reset");
    check_status();

    // Phase 1: Fill with 8 entries same tag 0
    for (int i = 0; i < SLOTS; i++) begin
      do_push(3'd0, i, 1000);
      if (fatal) break;
    end
    if (!fatal) begin
      if (full !== 1'b1) report_fail("R14", "full_o not high after filling");
      if (empty !== 1'b0) report_fail("R14", "empty_o not low after filling");
      check_push_blocked(3'd1, 32'hDEADBEEF, 10);
    end

    // Phase 2: Search while full
    if (!fatal) begin
      do_match(32'h00000000, 32'h00000000, 1000); // R13
      do_match(32'h00000003, 32'hFFFFFFFF, 1000); // exact match 3
      do_match(32'h00000009, 32'hFFFFFFFF, 1000); // exact miss 9
      do_match(32'h00000004, 32'hFFFFFFF0, 1000); // masked match
      do_match(32'h00000008, 32'hFFFFFFF8, 1000); // masked miss
    end

    // Phase 3: Pop peek and pop FIFO order for tag 0
    if (!fatal) begin
      do_pop(3'd0, 1'b0, 1000); // peek 0
      do_pop(3'd0, 1'b1, 1000); // pop 0
      do_pop(3'd0, 1'b0, 1000); // peek 1
      do_pop(3'd0, 1'b1, 1000); // pop 1
      for (int i = 2; i < SLOTS; i++) begin
        do_pop(3'd0, 1'b1, 1000);
        if (fatal) break;
      end
      if (!fatal) begin
        if (empty !== 1'b1) report_fail("R14", "empty_o not high after emptying");
        if (full !== 1'b0) report_fail("R14", "full_o not low after emptying");
        do_pop(3'd1, 1'b1, 1000); // R10: pop absent tag
      end
    end

    // Phase 4: Mixed tags and per-tag FIFO
    if (!fatal) begin
      do_push(3'd1, 32'd10, 1000);
      do_push(3'd2, 32'd20, 1000);
      do_push(3'd1, 32'd11, 1000);
      do_push(3'd3, 32'd30, 1000);
      do_push(3'd2, 32'd21, 1000);
      do_push(3'd1, 32'd12, 1000);
      do_push(3'd4, 32'd40, 1000);
      do_push(3'd5, 32'd50, 1000);
      if (!fatal) begin
        if (full !== 1'b1) report_fail("R14", "full_o not high after mixed fill");
        do_pop(3'd1, 1'b1, 1000); // 10
        do_pop(3'd2, 1'b1, 1000); // 20
        do_pop(3'd1, 1'b1, 1000); // 11
        do_pop(3'd3, 1'b1, 1000); // 30
        do_pop(3'd1, 1'b1, 1000); // 12
        do_pop(3'd2, 1'b1, 1000); // 21
        do_pop(3'd4, 1'b1, 1000); // 40
        do_pop(3'd5, 1'b1, 1000); // 50
        if (empty !== 1'b1) report_fail("R14", "empty_o not high after mixed empty");
        if (full !== 1'b0) report_fail("R14", "full_o not low after mixed empty");
      end
    end

    // Phase 5: Reset again
    if (!fatal) begin
      do_push(3'd0, 32'd100, 1000);
      do_push(3'd1, 32'd200, 1000);
      bfm_reset();
      @(posedge clk);
      @(negedge clk);
      if (empty !== 1'b1) report_fail("R15", "empty_o not high after reset");
      if (full !== 1'b0) report_fail("R15", "full_o not low after reset");
      model_q.delete();
      check_status();
    end

    // Final result
    if (error_count == 0) begin
      $display("RESULT: PASS");
    end else begin
      $display("RESULT: FAIL");
    end
    $finish;
  end

endmodule
