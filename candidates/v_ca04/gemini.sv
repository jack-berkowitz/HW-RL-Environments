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
// TESTBENCH IMPLEMENTATION
// ---------------------------------------------------------------------------

  typedef struct {
    logic [31:0] data;
    logic [1:0] sel;
  } beat_t;

  beat_t stim_q [N_IN][$];
  int expected_data [N_IN][N_OUT][$];

  // Stimulus feeding logic
  always_comb begin
    for (int k = 0; k < N_IN; k++) begin
      if (stim_q[k].size() > 0) begin
        bfm_offer[k] = 1'b1;
        bfm_next_data[k] = stim_q[k][0].data;
        bfm_next_sel[k]  = stim_q[k][0].sel;
      end else begin
        bfm_offer[k] = 1'b0;
        bfm_next_data[k] = '0;
        bfm_next_sel[k]  = '0;
      end
    end
  end

  // Stimulus pop and Scoreboard push
  always @(posedge clk) begin
    if (!rst_n) begin
      for (int k = 0; k < N_IN; k++) begin
        stim_q[k].delete();
        for (int j = 0; j < N_OUT; j++) begin
          expected_data[k][j].delete();
        end
      end
    end else begin
      for (int k = 0; k < N_IN; k++) begin
        if (in_valid[k] && in_ready[k]) begin
          if (stim_q[k].size() > 0) begin
            void'(stim_q[k].pop_front());
          end
          expected_data[k][in_sel[k*SW+:SW]].push_back(in_data[k*DW+:DW]);
        end
      end
    end
  end

  // -------------------------------------------------------------------------
  // Checkers
  // -------------------------------------------------------------------------

  // X1: Reset origin checker
  always @(posedge clk) begin
    if (!rst_n && bfm_cycle > 0) begin
      for (int j = 0; j < N_OUT; j++) begin
        if (out_valid[j]) begin
          $display("RESULT: FAIL (X1: Output valid asserted while reset is low and inputs quiet)");
          $finish;
        end
      end
    end
  end

  // A3: Output hold checker
  logic [N_OUT-1:0]    prev_out_valid = '0;
  logic [N_OUT-1:0]    prev_out_ready = '0;
  logic [N_OUT*DW-1:0] prev_out_data = '0;
  logic [N_OUT*IW-1:0] prev_out_idx = '0;

  always @(posedge clk) begin
    if (!rst_n) begin
      prev_out_valid <= '0;
      prev_out_ready <= '0;
    end else begin
      for (int j = 0; j < N_OUT; j++) begin
        if (prev_out_valid[j] && !prev_out_ready[j]) begin
          if (!out_valid[j]) begin
            $display("RESULT: FAIL (A3: out_valid[%0d] dropped before out_ready was seen)", j);
            $finish;
          end
          if (out_data[j*DW+:DW] !== prev_out_data[j*DW+:DW]) begin
            $display("RESULT: FAIL (A3: out_data[%0d] changed before out_ready was seen)", j);
            $finish;
          end
          if (out_idx[j*IW+:IW] !== prev_out_idx[j*IW+:IW]) begin
            $display("RESULT: FAIL (A3: out_idx[%0d] changed before out_ready was seen)", j);
            $finish;
          end
        end
      end
      prev_out_valid <= out_valid;
      prev_out_ready <= out_ready;
      prev_out_data  <= out_data;
      prev_out_idx   <= out_idx;
    end
  end

  // Scoreboard Checkers: R1, R2, R3, R4, R5
  // A2: Fairness Checker
  int wait_transfers [N_IN];

  always @(posedge clk) begin
    automatic int src;
    automatic int exp_d;
    automatic int winner;
    automatic int active_count;

    if (!rst_n) begin
      for (int k = 0; k < N_IN; k++) wait_transfers[k] = 0;
    end else begin
      // Reset A2 counter for any input that is not actively offering
      for (int k = 0; k < N_IN; k++) begin
        if (!in_valid[k]) wait_transfers[k] = 0;
      end

      for (int j = 0; j < N_OUT; j++) begin
        if (out_valid[j] && out_ready[j]) begin
          src = out_idx[j*IW+:IW];
          
          // R4 check: Ensure we expected a beat from this source for this output
          if (expected_data[src][j].size() == 0) begin
            $display("RESULT: FAIL (R4: Unexpected or duplicate delivery on output %0d from source %0d)", j, src);
            $finish;
          end
          
          // R2, R5 check: Validate payload sequence
          exp_d = expected_data[src][j].pop_front();
          if (out_data[j*DW+:DW] !== exp_d) begin
            $display("RESULT: FAIL (R2/R5: Payload or ordering mismatch on out %0d. Exp:%h Got:%h)", j, exp_d, out_data[j*DW+:DW]);
            $finish;
          end

          // A2 Fairness evaluation
          winner = src;
          active_count = 0;
          for (int k = 0; k < N_IN; k++) begin
            if (in_valid[k] && in_sel[k*SW+:SW] == j) active_count++;
          end

          for (int k = 0; k < N_IN; k++) begin
            if (in_valid[k] && in_sel[k*SW+:SW] == j) begin
              if (k == winner) begin
                wait_transfers[k] = 0;
              end else begin
                wait_transfers[k]++;
                if (wait_transfers[k] >= active_count) begin
                  $display("RESULT: FAIL (A2: Fairness bound violated on output %0d for input %0d. Missed %0d transfers, active_count=%0d)", j, k, wait_transfers[k], active_count);
                  $finish;
                end
              end
            end
          end
        end
      end
    end
  end

  // X3: Liveness checker
  int x3_wait_cycles [N_IN];
  always @(posedge clk) begin
    automatic int bound_j;
    if (!rst_n) begin
      for (int k = 0; k < N_IN; k++) x3_wait_cycles[k] = 0;
    end else begin
      for (int k = 0; k < N_IN; k++) begin
        if (in_valid[k] && !in_ready[k]) begin
          bound_j = in_sel[k*SW+:SW];
          if (out_ready[bound_j]) begin
            x3_wait_cycles[k]++;
            if (x3_wait_cycles[k] > 32) begin
              $display("RESULT: FAIL (X3: Liveness bound exceeded for input %0d to output %0d)", k, bound_j);
              $finish;
            end
          end else begin
            x3_wait_cycles[k] = 0;
          end
        end else begin
          x3_wait_cycles[k] = 0;
        end
      end
    end
  end

  // -------------------------------------------------------------------------
  // Test Sequence Utilities
  // -------------------------------------------------------------------------

  int seq_num = 0;
  task automatic push_beat(input int k, input int j);
    beat_t b;
    // Embed source, dest, and a unique sequence ID to guarantee uniqueness
    b.data = {k[7:0], j[7:0], seq_num[15:0]};
    seq_num++;
    b.sel = j;
    stim_q[k].push_back(b);
  endtask

  task automatic wait_all_done();
    int timeout = 5000;
    automatic bit empty;
    while (timeout > 0) begin
      empty = 1;
      for (int k = 0; k < N_IN; k++) begin
        if (stim_q[k].size() > 0 || in_valid[k]) empty = 0;
        for (int j = 0; j < N_OUT; j++) begin
          if (expected_data[k][j].size() > 0) empty = 0;
        end
      end
      if (empty) return;
      @(posedge clk);
      timeout--;
    end
    $display("RESULT: FAIL (Test timeout: beats lost in flight or deadlock occurred)");
    $finish;
  endtask

  task automatic set_out_ready(input logic [N_OUT-1:0] v);
    @(negedge clk);
    out_ready = v;
  endtask

  // -------------------------------------------------------------------------
  // Main Sequence
  // -------------------------------------------------------------------------

  initial begin
    // Setup and wait out of reset
    repeat(10) @(posedge clk);
    set_out_ready(4'b1111);
    
    // Test 1: Sequential 1-to-1 routing
    for (int k = 0; k < N_IN; k++) begin
      push_beat(k, k);
    end
    wait_all_done();
    
    // Test 2: All inputs mapping to a single output (A1, A2 fairness, R5 ordering)
    for (int i = 0; i < 10; i++) begin
      push_beat(0, 0);
      push_beat(1, 0);
      push_beat(2, 0);
      push_beat(3, 0);
    end
    wait_all_done();
    
    // Test 3: Backpressure and Independence (I1, I2, A3)
    set_out_ready(4'b1110); // Output 0 is NOT ready
    for (int i = 0; i < 5; i++) push_beat(0, 0);
    repeat(10) @(posedge clk); // Allow traffic to clog the crossbar towards output 0
    
    // Test independent paths while output 0 is congested
    push_beat(1, 1);
    push_beat(2, 2);
    push_beat(3, 3);
    
    begin
      int timeout = 100;
      while (timeout > 0) begin
        if (stim_q[1].size() == 0 && stim_q[2].size() == 0 && stim_q[3].size() == 0 &&
            !in_valid[1] && !in_valid[2] && !in_valid[3] &&
            expected_data[1][1].size() == 0 && expected_data[2][2].size() == 0 && 
            expected_data[3][3].size() == 0) begin
          break;
        end
        @(posedge clk);
        timeout--;
      end
      if (timeout == 0) begin
        $display("RESULT: FAIL (I1/I2: Traffic blocked by unrelated stalled output)");
        $finish;
      end
    end
    
    set_out_ready(4'b1111); // Unblock and drain
    wait_all_done();

    // Test 4: Heavy uniform traffic
    for (int i = 0; i < 40; i++) begin
      for (int k = 0; k < N_IN; k++) begin
        push_beat(k, (k + i) % N_OUT);
      end
    end
    wait_all_done();

    // Test 5: Reset during flight (X1, X2 checks)
    set_out_ready(4'b0000); // Stall to build up state
    push_beat(0, 1);
    push_beat(1, 2);
    push_beat(2, 3);
    push_beat(3, 0);
    repeat(5) @(posedge clk); 
    
    // Assert reset while active
    bfm_reset(5);
    
    set_out_ready(4'b1111);
    repeat(5) @(posedge clk);
    
    // Check X2: After reset is released, no delivery owed
    for (int j = 0; j < N_OUT; j++) begin
      if (out_valid[j]) begin
        $display("RESULT: FAIL (X2: valid output asserted after reset without new stimulus)");
        $finish;
      end
    end
    wait_all_done();

    // Done
    $display("RESULT: PASS");
    $finish;
  end

endmodule