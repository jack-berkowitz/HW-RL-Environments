module route_xbar_tb;
  // ---------------------------------------------------------------------------
  // PROVIDED PLUMBING -- moves beats, checks nothing.
  // ---------------------------------------------------------------------------
  localparam int N_IN = 4, N_OUT = 4, DW = 32, SW = 2, IW = 2;

  // ---- clock ---------------------------------------------------------------
  logic clk = 1'b0;
  always #5 clk = ~clk;

  int bfm_cycle = 0;
  always @(posedge clk) if (rst_n) bfm_cycle <= bfm_cycle + 1;

  // ---- reset ---------------------------------------------------------------
  logic rst_n = 1'b0;        // ASYNCHRONOUS, ACTIVE LOW

  task automatic bfm_reset(input int cycles = 5);
    @(negedge clk);
    rst_n = 1'b0;
    repeat (cycles) @(posedge clk);
    @(negedge clk);
    rst_n = 1'b1;
  endtask

  // ---- signals and the design under test -----------------------------------
  logic [N_IN*DW-1:0]  in_data;
  logic [N_IN*SW-1:0]  in_sel;
  logic [N_IN-1:0]     in_valid, in_ready;
  logic [N_OUT*DW-1:0] out_data;
  logic [N_OUT*IW-1:0] out_idx;
  logic [N_OUT-1:0]    out_valid, out_ready;

  route_xbar #(.N_IN(N_IN), .N_OUT(N_OUT), .DATA_W(DW), .SEL_W(SW), .IDX_W(IW)) dut (
    .clk_i(clk), .rst_ni(rst_n),
    .in_data_i(in_data), .in_sel_i(in_sel), .in_valid_i(in_valid), .in_ready_o(in_ready),
    .out_data_o(out_data), .out_idx_o(out_idx), .out_valid_o(out_valid),
    .out_ready_i(out_ready));

  // Convenience slicers.
  function automatic logic [DW-1:0] bfm_odata(input int j); return out_data[j*DW +: DW]; endfunction
  function automatic logic [IW-1:0] bfm_oidx (input int j); return out_idx [j*IW +: IW]; endfunction

  // ---- what you drive ------------------------------------------------------
  logic [N_IN-1:0]  bfm_offer;
  logic [DW-1:0]    bfm_next_data [N_IN];
  logic [SW-1:0]    bfm_next_sel  [N_IN];

  // Registered handshake: bfm_accepted[k] is high for the cycle following the
  // rising edge on which input k's beat was taken.
  logic [N_IN-1:0]  bfm_accepted;
  always @(posedge clk) bfm_accepted <= (rst_n ? (in_valid & in_ready) : '0);

  always @(negedge clk) begin
    if (!rst_n) begin
      in_valid = '0;
    end else begin
      for (int k = 0; k < N_IN; k++) begin
        if (bfm_accepted[k]) in_valid[k] = 1'b0;          // that beat is gone
        if (!in_valid[k] && bfm_offer[k]) begin           // start the next one
          in_data[k*DW +: DW] = bfm_next_data[k];
          in_sel [k*SW +: SW] = bfm_next_sel[k];
          in_valid[k]         = 1'b1;
        end
      end
    end
  end

  task automatic bfm_ready(input logic [N_OUT-1:0] v); out_ready = v; endtask

  // ---- idle everything at time zero ----------------------------------------
  initial begin
    in_data = '0; in_sel = '0; in_valid = '0; out_ready = '1; bfm_offer = '0;
    for (int k = 0; k < N_IN; k++) begin bfm_next_data[k] = '0; bfm_next_sel[k] = '0; end
  end

  // ---- watchdog ------------------------------------------------------------
  initial begin
    #2_000_000;
    $display("RESULT: FAIL (watchdog: no verdict reached)");
    $finish;
  end

  // ===========================================================================
  // OUR TESTBENCH
  // ===========================================================================

  typedef struct {
    int id;
    int in_idx;
    int out_idx;
    logic [31:0] data;
    bit delivered;
  } rec_t;

  rec_t all_beats[$];
  int order_q[16][$];
  int fair_hist[4][$];
  bit fair_en[4];
  logic [3:0] fair_mask[4];
  int acc_count[4];
  int out_count[4];
  bit failed = 0;
  int data_counter = 0;
  int beat_id_counter = 0;
  int next_sel_pattern[4];
  bit cycle_sel[4];

  logic [3:0] prev_valid, prev_ready;
  logic [31:0] prev_data[4];
  logic [1:0] prev_idx[4];

  function automatic int countones4(input logic [3:0] v);
    return v[0] + v[1] + v[2] + v[3];
  endfunction

  function automatic bit all_delivered();
    int i;
    for (i = 0; i < all_beats.size(); i++) begin
      if (!all_beats[i].delivered) return 0;
    end
    return 1;
  endfunction

  task automatic fail(input string msg);
    if (!failed) begin
      $display("FAIL: %s", msg);
      failed = 1;
    end
  endtask

  // ---------------------------------------------------------------------------
  // Monitor: scoreboard, routing, ordering, arbitration, stability, fairness
  // ---------------------------------------------------------------------------
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      all_beats.delete();
      for (int i = 0; i < 16; i++) order_q[i].delete();
      for (int j = 0; j < 4; j++) begin
        fair_hist[j].delete();
        prev_valid[j] = 0;
        prev_ready[j] = 0;
        prev_data[j] = 0;
        prev_idx[j] = 0;
        acc_count[j] = 0;
        out_count[j] = 0;
      end
      beat_id_counter = 0;
    end else begin
      automatic int i;
      automatic int j;
      automatic int k;
      automatic int match_idx;
      automatic int need;
      automatic int pos;
      automatic int idx;
      automatic int t;
      automatic logic [3:0] seen;
      automatic rec_t r;

      // ---- input acceptances ------------------------------------------------
      for (k = 0; k < 4; k++) begin
        if (in_valid[k] && in_ready[k]) begin
          r.id = beat_id_counter;
          beat_id_counter = beat_id_counter + 1;
          r.in_idx = k;
          r.out_idx = in_sel[k*2 +: 2];
          r.data = in_data[k*32 +: 32];
          r.delivered = 0;
          all_beats.push_back(r);
          order_q[k*4 + r.out_idx].push_back(r.id);
          acc_count[k] = acc_count[k] + 1;
        end
      end

      // ---- output deliveries ------------------------------------------------
      for (j = 0; j < 4; j++) begin
        if (out_valid[j] && out_ready[j]) begin
          match_idx = -1;
          for (i = 0; i < all_beats.size(); i++) begin
            if (!all_beats[i].delivered &&
                all_beats[i].data == out_data[j*32 +: 32] &&
                all_beats[i].in_idx == out_idx[j*2 +: 2] &&
                all_beats[i].out_idx == j) begin
              match_idx = i;
              break;
            end
          end
          if (match_idx < 0) begin
            fail("R6/R1/R2/R3: delivered beat not matching any accepted beat");
          end else begin
            k = all_beats[match_idx].in_idx;
            idx = k*4 + j;
            if (order_q[idx].size() == 0) begin
              fail("R5: order queue empty");
            end else if (order_q[idx][0] != all_beats[match_idx].id) begin
              fail("R5: out-of-order delivery for same input/output");
            end
            all_beats[match_idx].delivered = 1;
            if (order_q[idx].size() > 0) order_q[idx].pop_front();
            out_count[j] = out_count[j] + 1;
          end
        end
      end

      // ---- A3: stability of offered beats -----------------------------------
      for (j = 0; j < 4; j++) begin
        if (prev_valid[j] && !prev_ready[j]) begin
          if (!out_valid[j]) fail("A3: out_valid withdrawn before ready");
          else if (out_data[j*32 +: 32] != prev_data[j] || out_idx[j*2 +: 2] != prev_idx[j])
            fail("A3: out payload changed before ready");
        end
      end

      // ---- A2: fairness windows ---------------------------------------------
      for (j = 0; j < 4; j++) begin
        if (!fair_en[j]) begin
          fair_hist[j].delete();
        end else if (out_valid[j] && out_ready[j]) begin
          idx = out_idx[j*2 +: 2];
          fair_hist[j].push_back(idx);
          need = countones4(fair_mask[j]);
          if (fair_hist[j].size() >= need) begin
            seen = 0;
            for (t = 0; t < need; t++) begin
              pos = fair_hist[j].size() - need + t;
              seen[fair_hist[j][pos]] = 1'b1;
            end
            if ((seen & fair_mask[j]) != fair_mask[j]) begin
              fail("A2: fairness window violated");
            end
          end
        end
      end

      // ---- remember previous output state -----------------------------------
      for (j = 0; j < 4; j++) begin
        prev_valid[j] = out_valid[j];
        prev_ready[j] = out_ready[j];
        prev_data[j] = out_data[j*32 +: 32];
        prev_idx[j] = out_idx[j*2 +: 2];
      end
    end
  end

  // ---------------------------------------------------------------------------
  // Update next payload/selector after each acceptance
  // ---------------------------------------------------------------------------
  always @(posedge clk) begin
    if (rst_n) begin
      for (int k = 0; k < 4; k++) begin
        if (in_valid[k] && in_ready[k]) begin
          bfm_next_data[k] = data_counter;
          data_counter = data_counter + 1;
          if (cycle_sel[k]) begin
            bfm_next_sel[k] = next_sel_pattern[k];
            next_sel_pattern[k] = (next_sel_pattern[k] + 1) % 4;
          end
        end
      end
    end
  end

  // ---------------------------------------------------------------------------
  // Testbench tasks
  // ---------------------------------------------------------------------------
  task automatic do_reset(input int cycles = 5);
    @(negedge clk);
    bfm_offer = '0;
    bfm_ready('1);
    rst_n = 1'b0;
    repeat (cycles) @(posedge clk);
    if (out_valid !== '0) fail("X1: out_valid not low during reset");
    @(negedge clk);
    rst_n = 1'b1;
  endtask

  task automatic wait_accept_count(input int k, input int start, input int max_cycles, output bit ok);
    int cnt;
    cnt = 0;
    ok = 0;
    while (cnt < max_cycles) begin
      @(negedge clk);
      if (acc_count[k] > start) begin
        ok = 1;
        break;
      end
      cnt = cnt + 1;
    end
  endtask

  task automatic wait_out_count(input int j, input int start, input int max_cycles, output bit ok);
    int cnt;
    cnt = 0;
    ok = 0;
    while (cnt < max_cycles) begin
      @(negedge clk);
      if (out_count[j] > start) begin
        ok = 1;
        break;
      end
      cnt = cnt + 1;
    end
  endtask

  task automatic wait_valid_mask(input logic [3:0] mask, input int max_cycles, output bit ok);
    int cnt;
    cnt = 0;
    ok = 0;
    while (cnt < max_cycles) begin
      @(negedge clk);
      if ((in_valid & mask) == mask) begin
        ok = 1;
        break;
      end
      cnt = cnt + 1;
    end
  endtask

  task automatic drain_and_check(input int max_cycles);
    int cnt;
    cnt = 0;
    bfm_offer = '0;
    bfm_ready('1);
    while (cnt < max_cycles) begin
      @(negedge clk);
      if (all_delivered()) break;
      cnt = cnt + 1;
    end
    if (!all_delivered()) begin
      fail("R4: accepted beat not delivered");
    end
  endtask

  // ---------------------------------------------------------------------------
  // Stimulus
  // ---------------------------------------------------------------------------
  initial begin
    int k;
    int start_acc1;
    int start_out1;
    int start_acc[4];
    bit ok_acc;
    bit ok_out;
    bit ok_valid;

    cycle_sel = '0;
    for (k = 0; k < 4; k++) next_sel_pattern[k] = 0;

    // ---- Phase 0: reset and X2 --------------------------------------------
    do_reset(5);
    bfm_ready('1);
    repeat (10) @(negedge clk);
    if (out_valid !== '0) fail("X2: out_valid after reset with no input");

    // ---- Phase 1: routing, payload, idx, exactly once ----------------------
    cycle_sel = '1;
    @(negedge clk);
    for (k = 0; k < 4; k++) begin
      bfm_next_data[k] = data_counter;
      data_counter = data_counter + 1;
      bfm_next_sel[k] = k;
      next_sel_pattern[k] = (k + 1) % 4;
      bfm_offer[k] = 1;
    end
    repeat (80) @(negedge clk);
    bfm_offer = '0;
    drain_and_check(200);
    if (failed) begin
      $display("RESULT: FAIL");
      $finish;
    end

    // ---- Phase 2: fairness all 4 to out0 ----------------------------------
    do_reset(5);
    bfm_ready('1);
    cycle_sel = '0;
    @(negedge clk);
    for (k = 0; k < 4; k++) begin
      bfm_next_data[k] = data_counter;
      data_counter = data_counter + 1;
      bfm_next_sel[k] = 0;
      bfm_offer[k] = 1;
    end
    wait_valid_mask(4'b1111, 20, ok_valid);
    if (!ok_valid) fail("X3: inputs did not become valid");
    fair_mask[0] = 4'b1111;
    fair_en[0] = 1;
    repeat (100) @(negedge clk);
    fair_en[0] = 0;
    bfm_offer = '0;
    drain_and_check(200);
    if (failed) begin
      $display("RESULT: FAIL");
      $finish;
    end

    // ---- Phase 3: fairness subset 2 to out1 -------------------------------
    do_reset(5);
    bfm_ready('1);
    cycle_sel = '0;
    @(negedge clk);
    for (k = 0; k < 4; k++) begin
      bfm_offer[k] = (k < 2);
      if (k < 2) begin
        bfm_next_data[k] = data_counter;
        data_counter = data_counter + 1;
        bfm_next_sel[k] = 1;
      end
    end
    wait_valid_mask(4'b0011, 20, ok_valid);
    if (!ok_valid) fail("X3: inputs did not become valid");
    fair_mask[1] = 4'b0011;
    fair_en[1] = 1;
    repeat (100) @(negedge clk);
    fair_en[1] = 0;
    bfm_offer = '0;
    drain_and_check(200);
    if (failed) begin
      $display("RESULT: FAIL");
      $finish;
    end

    // ---- Phase 4: fairness subset 3 to out2 -------------------------------
    do_reset(5);
    bfm_ready('1);
    cycle_sel = '0;
    @(negedge clk);
    for (k = 0; k < 4; k++) begin
      bfm_offer[k] = (k < 3);
      if (k < 3) begin
        bfm_next_data[k] = data_counter;
        data_counter = data_counter + 1;
        bfm_next_sel[k] = 2;
      end
    end
    wait_valid_mask(4'b0111, 20, ok_valid);
    if (!ok_valid) fail("X3: inputs did not become valid");
    fair_mask[2] = 4'b0111;
    fair_en[2] = 1;
    repeat (100) @(negedge clk);
    fair_en[2] = 0;
    bfm_offer = '0;
    drain_and_check(200);
    if (failed) begin
      $display("RESULT: FAIL");
      $finish;
    end

    // ---- Phase 5: I1 / I2 -------------------------------------------------
    do_reset(5);
    bfm_ready(4'b1110); // out0 not ready
    cycle_sel = '0;
    @(negedge clk);
    bfm_next_data[0] = data_counter;
    data_counter = data_counter + 1;
    bfm_next_sel[0] = 0;
    bfm_offer[0] = 1;
    bfm_next_data[1] = data_counter;
    data_counter = data_counter + 1;
    bfm_next_sel[1] = 1;
    bfm_offer[1] = 1;
    start_acc1 = acc_count[1];
    start_out1 = out_count[1];
    wait_accept_count(1, start_acc1, 32, ok_acc);
    if (!ok_acc) fail("I2/X3: input1 not accepted while out0 not ready");
    wait_out_count(1, start_out1, 50, ok_out);
    if (!ok_out) fail("I1: out1 did not deliver while out0 not ready");
    bfm_ready('1);
    bfm_offer = '0;
    drain_and_check(200);
    if (failed) begin
      $display("RESULT: FAIL");
      $finish;
    end

    // ---- Phase 6: R5 ordering, with possible buffering --------------------
    do_reset(5);
    bfm_ready(4'b0111); // out3 not ready
    cycle_sel = '0;
    @(negedge clk);
    bfm_next_data[0] = data_counter;
    data_counter = data_counter + 1;
    bfm_next_sel[0] = 3;
    bfm_offer[0] = 1;
    repeat (40) @(negedge clk);
    bfm_ready('1);
    repeat (40) @(negedge clk);
    bfm_offer = '0;
    drain_and_check(200);
    if (failed) begin
      $display("RESULT: FAIL");
      $finish;
    end

    // ---- Phase 7: X3 liveness, all 4 competing for out0 -------------------
    do_reset(5);
    bfm_ready('1);
    cycle_sel = '0;
    @(negedge clk);
    for (k = 0; k < 4; k++) begin
      bfm_next_data[k] = data_counter;
      data_counter = data_counter + 1;
      bfm_next_sel[k] = 0;
      bfm_offer[k] = 1;
    end
    for (k = 0; k < 4; k++) start_acc[k] = acc_count[k];
    repeat (32) @(negedge clk);
    for (k = 0; k < 4; k++) begin
      if (acc_count[k] <= start_acc[k]) fail("X3: input not accepted within 32 cycles");
    end
    bfm_offer = '0;
    drain_and_check(200);
    if (failed) begin
      $display("RESULT: FAIL");
      $finish;
    end

    // ---- Final verdict ----------------------------------------------------
    if (failed) $display("RESULT: FAIL");
    else        $display("RESULT: PASS");
    $finish;
  end

endmodule
