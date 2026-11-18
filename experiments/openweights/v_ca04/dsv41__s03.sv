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

  // ---------------------------------------------------------------------------
  // OUR TESTBENCH
  // ---------------------------------------------------------------------------

  // ---- unique payload generator --------------------------------------------
  function automatic logic [31:0] make_data(input int k, input int seq);
    return 32'hA5000000 | ((k & 3) << 20) | (seq & 20'hFFFFF);
  endfunction

  // ---- bookkeeping ---------------------------------------------------------
  int rec_in       [$];
  int rec_out      [$];
  logic [31:0] rec_data [$];
  bit rec_delivered[$];
  int rec_by_data [longint];

  int order_q [N_IN*N_OUT][$];
  int total_acc [N_IN*N_OUT];
  int total_del [N_IN*N_OUT];

  int outstanding;
  int acc_count [N_IN];
  int deliv_count [N_OUT];
  int beat_seq [N_IN];
  int wait_cnt [N_IN];

  logic a3_active [N_OUT];
  logic [DW-1:0] a3_data [N_OUT];
  logic [IW-1:0] a3_idx  [N_OUT];

  logic fair_check_enable;
  int fair_window_size;
  bit [N_IN-1:0] fair_set;
  int fair_hist [$];

  // ---- failure -------------------------------------------------------------
  task automatic tb_fail(input string msg);
    $display("RESULT: FAIL (%s)", msg);
    $finish;
  endtask

  // ---- drain ---------------------------------------------------------------
  task automatic drain();
    automatic int timeout;
    @(posedge clk);
    bfm_offer = '0;
    @(negedge clk);
    out_ready = '1;
    timeout = 2000;
    while ((in_valid != '0 || outstanding != 0) && timeout > 0) begin
      @(posedge clk);
      timeout--;
    end
    if (timeout == 0) tb_fail("R4/X3: beats not drained");
  endtask

  // ---- basic routing / ordering --------------------------------------------
  task automatic run_basic();
    automatic int timeout;
    automatic int start_acc0, start_acc1, start_acc2, start_acc3;
    automatic int start_acc;

    drain();

    // one beat from each input to a different output
    @(posedge clk);
    bfm_offer = '0;
    for (int k = 0; k < N_IN; k++) begin
      bfm_next_data[k] = make_data(k, beat_seq[k]);
      bfm_next_sel[k]  = (k + 1) % N_OUT;
      bfm_offer[k]     = 1;
    end
    @(negedge clk); out_ready = '1;

    start_acc0 = acc_count[0];
    start_acc1 = acc_count[1];
    start_acc2 = acc_count[2];
    start_acc3 = acc_count[3];
    timeout = 200;
    while ((acc_count[0] < start_acc0+1 ||
            acc_count[1] < start_acc1+1 ||
            acc_count[2] < start_acc2+1 ||
            acc_count[3] < start_acc3+1) && timeout > 0) begin
      @(posedge clk);
      timeout--;
    end
    if (timeout == 0) tb_fail("X3: basic acceptance timeout");

    @(posedge clk);
    bfm_offer = '0;
    drain();

    // order test: input 0 sends three beats to output 0
    @(posedge clk);
    bfm_offer = '0;
    bfm_next_data[0] = make_data(0, beat_seq[0]);
    bfm_next_sel[0]  = 0;
    bfm_offer[0]     = 1;
    start_acc = acc_count[0];
    timeout = 200;
    while (acc_count[0] < start_acc + 3 && timeout > 0) begin
      @(posedge clk);
      timeout--;
    end
    if (timeout == 0) tb_fail("X3: order test acceptance timeout");

    @(posedge clk);
    bfm_offer[0] = 0;
    drain();
  endtask

  // ---- fairness ------------------------------------------------------------
  task automatic run_fairness(input int nsel);
    automatic bit [N_IN-1:0] set_mask;
    automatic int window;
    automatic int target;
    automatic int timeout;

    set_mask = '0;
    window   = nsel;
    for (int k = 0; k < nsel; k++) set_mask[k] = 1;

    drain();

    @(posedge clk);
    bfm_offer = '0;
    for (int k = 0; k < N_IN; k++) begin
      if (k < nsel) begin
        bfm_next_data[k] = make_data(k, beat_seq[k]);
        bfm_next_sel[k]  = 0;
        bfm_offer[k]     = 1;
      end else begin
        bfm_offer[k] = 0;
      end
    end

    @(negedge clk);
    out_ready = '1;
    fair_hist.delete();
    fair_set = set_mask;
    fair_window_size = window;
    fair_check_enable = 1;

    target  = 4 * window + 8;
    timeout = 2000;
    while (fair_hist.size() < target && timeout > 0) begin
      @(posedge clk);
      timeout--;
    end

    fair_check_enable = 0;
    if (fair_hist.size() < target) tb_fail("A2: not enough transfers for fairness test");

    @(posedge clk);
    bfm_offer = '0;
    drain();
    fair_hist.delete();
  endtask

  // ---- backpressure / A3 ---------------------------------------------------
  task automatic run_backpressure();
    automatic int timeout;
    automatic int start_acc;

    drain();

    @(posedge clk);
    bfm_offer = '0;
    bfm_next_data[0] = make_data(0, beat_seq[0]);
    bfm_next_sel[0]  = 0;
    bfm_offer[0]     = 1;

    @(negedge clk); out_ready = '1;

    start_acc = acc_count[0];
    timeout = 100;
    while (acc_count[0] < start_acc + 1 && timeout > 0) begin
      @(posedge clk);
      timeout--;
    end
    if (timeout == 0) tb_fail("X3: backpressure acceptance timeout");

    @(negedge clk);
    out_ready[0] = 0;

    timeout = 50;
    while (!out_valid[0] && timeout > 0) begin
      @(posedge clk);
      timeout--;
    end

    if (out_valid[0]) begin
      repeat (10) @(posedge clk);
      @(negedge clk);
      out_ready[0] = 1;
    end else begin
      @(negedge clk);
      out_ready[0] = 1;
    end

    @(posedge clk);
    bfm_offer[0] = 0;
    drain();
  endtask

  // ---- independence I1 / I2 ------------------------------------------------
  task automatic run_independence();
    automatic int timeout;
    automatic int start_acc1;
    automatic int start_del1;

    drain();

    @(posedge clk);
    bfm_offer = '0;
    bfm_next_data[0] = make_data(0, beat_seq[0]);
    bfm_next_sel[0]  = 0;
    bfm_offer[0]     = 1;
    bfm_next_data[1] = make_data(1, beat_seq[1]);
    bfm_next_sel[1]  = 1;
    bfm_offer[1]     = 1;

    @(negedge clk);
    out_ready = '1;
    out_ready[0] = 0;

    start_acc1 = acc_count[1];
    timeout = 100;
    while (acc_count[1] < start_acc1 + 1 && timeout > 0) begin
      @(posedge clk);
      timeout--;
    end
    if (timeout == 0) tb_fail("I2: input 1 blocked by input 0");

    start_del1 = deliv_count[1];
    timeout = 100;
    while (deliv_count[1] < start_del1 + 1 && timeout > 0) begin
      @(posedge clk);
      timeout--;
    end
    if (timeout == 0) tb_fail("I1: output 1 blocked by output 0");

    @(posedge clk);
    bfm_offer = '0;
    @(negedge clk);
    out_ready = '1;
    drain();
  endtask

  // ---- main checker --------------------------------------------------------
  always @(posedge clk) begin
    automatic int k;
    automatic int j;
    automatic logic [31:0] d;
    automatic int rec_id;
    automatic int qidx;

    if (!rst_n) begin
      if (out_valid !== '0) tb_fail("X1: output valid during reset");
      for (j = 0; j < N_OUT; j++) a3_active[j] <= 0;
    end else begin
      // A3: output valid/payload stability
      for (j = 0; j < N_OUT; j++) begin
        if (out_valid[j]) begin
          if (!a3_active[j]) begin
            if (!out_ready[j]) begin
              a3_active[j] <= 1;
              a3_data[j]   <= out_data[j*DW +: DW];
              a3_idx[j]    <= out_idx [j*IW +: IW];
            end
          end else begin
            if (out_data[j*DW +: DW] !== a3_data[j]) tb_fail("A3: data changed while valid");
            if (out_idx [j*IW +: IW] !== a3_idx [j]) tb_fail("A3: idx changed while valid");
            if (out_ready[j]) a3_active[j] <= 0;
          end
        end else begin
          if (a3_active[j]) tb_fail("A3: valid withdrawn before ready");
        end
      end

      // X3: liveness bound
      for (k = 0; k < N_IN; k++) begin
        if (in_valid[k] && out_ready[in_sel[k*SW +: SW]]) begin
          if (in_ready[k]) begin
            if (wait_cnt[k] > 32) tb_fail("X3: acceptance exceeded 32 cycles");
            wait_cnt[k] = 0;
          end else begin
            wait_cnt[k] = wait_cnt[k] + 1;
            if (wait_cnt[k] > 32) tb_fail("X3: acceptance exceeded 32 cycles");
          end
        end else begin
          wait_cnt[k] = 0;
        end
      end

      // acceptances
      for (k = 0; k < N_IN; k++) begin
        if (in_valid[k] && in_ready[k]) begin
          j = in_sel[k*SW +: SW];
          d = in_data[k*DW +: DW];

          rec_id = rec_in.size();
          rec_in.push_back(k);
          rec_out.push_back(j);
          rec_data.push_back(d);
          rec_delivered.push_back(0);
          rec_by_data[longint'(d)] = rec_id;
          order_q[k*N_OUT + j].push_back(rec_id);
          total_acc[k*N_OUT + j] = total_acc[k*N_OUT + j] + 1;

          outstanding = outstanding + 1;
          acc_count[k] = acc_count[k] + 1;

          beat_seq[k] = beat_seq[k] + 1;
          bfm_next_data[k] <= make_data(k, beat_seq[k]);
        end
      end

      // deliveries
      for (j = 0; j < N_OUT; j++) begin
        if (out_valid[j] && out_ready[j]) begin
          d = out_data[j*DW +: DW];
          k = out_idx [j*IW +: IW];

          if (rec_by_data.exists(longint'(d))) begin
            rec_id = rec_by_data[longint'(d)];

            if (rec_delivered[rec_id]) tb_fail("R4: duplicate delivery");
            if (rec_out[rec_id] != j) tb_fail("R1: beat delivered on wrong output");
            if (rec_in[rec_id] != k)  tb_fail("R3: out_idx wrong");

            qidx = rec_in[rec_id]*N_OUT + rec_out[rec_id];
            if (order_q[qidx].size() == 0) tb_fail("R4: order queue empty");
            if (order_q[qidx][0] != rec_id) tb_fail("R5: out of order");

            order_q[qidx].pop_front();
            rec_delivered[rec_id] = 1;
            total_del[qidx] = total_del[qidx] + 1;

            outstanding = outstanding - 1;
            deliv_count[j] = deliv_count[j] + 1;
          end else begin
            qidx = k*N_OUT + j;
            if (order_q[qidx].size() > 0) tb_fail("R2: payload modified");
            else if (total_acc[qidx] > 0) tb_fail("R4: duplicate or originated beat");
            else tb_fail("R6: delivered beat was not accepted");
          end
        end
      end
    end
  end

  // ---- fairness checker ----------------------------------------------------
  always @(posedge clk) begin
    automatic int idx;
    automatic bit [N_IN-1:0] seen;
    automatic int i;

    if (rst_n && fair_check_enable) begin
      if (out_valid[0] && out_ready[0]) begin
        idx = out_idx[0*IW +: IW];
        fair_hist.push_back(idx);

        if (fair_hist.size() >= fair_window_size) begin
          seen = '0;
          for (i = fair_hist.size() - fair_window_size; i < fair_hist.size(); i++) begin
            seen[fair_hist[i]] = 1;
          end
          if ((seen & fair_set) != fair_set) tb_fail("A2: fairness bound violated");
        end
      end
    end
  end

  // ---- test sequence -------------------------------------------------------
  initial begin
    for (int k = 0; k < N_IN; k++) begin
      beat_seq[k]  = 0;
      acc_count[k] = 0;
      wait_cnt[k]  = 0;
    end
    for (int j = 0; j < N_OUT; j++) begin
      deliv_count[j] = 0;
      a3_active[j]   = 0;
      a3_data[j]     = '0;
      a3_idx[j]      = '0;
    end
    for (int i = 0; i < N_IN*N_OUT; i++) begin
      total_acc[i] = 0;
      total_del[i] = 0;
      order_q[i].delete();
    end
    outstanding = 0;
    fair_check_enable = 0;
    fair_window_size  = 0;
    fair_set          = '0;
    fair_hist.delete();
    rec_in.delete();
    rec_out.delete();
    rec_data.delete();
    rec_delivered.delete();
    rec_by_data.delete();

    bfm_reset(5);

    // X2: no output after reset with no input
    repeat (5) @(posedge clk);
    if (out_valid !== '0) tb_fail("X2: output valid after reset with no input");

    run_basic();
    run_fairness(2);
    run_fairness(3);
    run_fairness(4);
    run_backpressure();
    run_independence();

    drain();
    if (outstanding != 0) tb_fail("R4: outstanding beats at end");

    $display("RESULT: PASS");
    $finish;
  end

endmodule
