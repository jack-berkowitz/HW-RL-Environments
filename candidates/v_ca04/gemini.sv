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

  initial begin
    in_data = '0; in_sel = '0; in_valid = '0; out_ready = '1; bfm_offer = '0;
    for (int k = 0; k < N_IN; k++) begin bfm_next_data[k] = '0; bfm_next_sel[k] = '0; end
  end

  initial begin
    #2_000_000;
    $display("RESULT: FAIL (watchdog: no verdict reached)");
    $finish;
  end

// ---------------------------------------------------------------------------
// CHECKERS & MONITORING
// ---------------------------------------------------------------------------
  
  logic fail = 0;
  task automatic fail_with(string msg);
    if (!fail) begin
      $display("RESULT: FAIL (%s)", msg);
      fail = 1;
      $finish;
    end
  endtask

  logic [DW-1:0] expected_beats [N_IN][N_OUT][$];

  // A3 and Delivery States
  logic [N_OUT-1:0] prev_out_valid;
  logic [N_OUT-1:0] prev_out_ready;
  logic [DW-1:0]    prev_out_data [N_OUT];
  logic [IW-1:0]    prev_out_idx  [N_OUT];

  // A2 and X3 track state
  int served_while_offering[N_IN][N_IN];
  int wait_time[N_IN];

  initial begin
    prev_out_valid = '0;
    prev_out_ready = '0;
  end

  // Reset checker (X1, X2)
  always @(negedge rst_n) begin
    for (int k=0; k<N_IN; k++) begin
      for (int j=0; j<N_OUT; j++) begin
        expected_beats[k][j].delete();
      end
    end
  end

  always @* begin
    if (!rst_n && out_valid !== '0) begin
      $display("RESULT: FAIL (X1: out_valid_o asserted during reset)");
      $finish;
    end
  end

  // Synchronous checks
  always @(posedge clk) begin
    if (!rst_n) begin
      for (int k=0; k<N_IN; k++) begin
        wait_time[k] = 0;
        for (int m=0; m<N_IN; m++) served_while_offering[k][m] = 0;
      end
    end else begin
      // A3: No withdrawal of offered beats
      for (int j=0; j<N_OUT; j++) begin
        if (prev_out_valid[j] && !prev_out_ready[j]) begin
          if (!out_valid[j]) fail_with($sformatf("A3: Output %0d valid withdrawn", j));
          if (bfm_odata(j) !== prev_out_data[j]) fail_with($sformatf("A3: Output %0d data changed", j));
          if (bfm_oidx(j) !== prev_out_idx[j]) fail_with($sformatf("A3: Output %0d idx changed", j));
        end
      end

      // A2 (Fairness) and X3 (Liveness)
      for (int k=0; k<N_IN; k++) begin
        if (in_valid[k] && !in_ready[k]) begin
          automatic int j_sel = in_sel[k*SW +: SW];
          
          // X3: Wait time bounded by 32 if output is continuously ready
          if (out_ready[j_sel]) begin
            wait_time[k]++;
            if (wait_time[k] > 32) fail_with($sformatf("X3: Input %0d waited >32 cycles for ready output %0d", k, j_sel));
          end else begin
            wait_time[k] = 0;
          end
          
          // A2: Fairness bound check
          if (out_valid[j_sel] && out_ready[j_sel]) begin
            automatic int m = bfm_oidx(j_sel);
            served_while_offering[k][m]++;
            if (served_while_offering[k][m] > 1) begin
               fail_with($sformatf("A2: Input %0d bypassed by input %0d multiple times", k, m));
            end
          end
        end else begin
          wait_time[k] = 0;
          for (int m=0; m<N_IN; m++) served_while_offering[k][m] = 0;
        end
      end

      // Record accepted beats (R1, R4)
      for (int k=0; k<N_IN; k++) begin
        if (in_valid[k] && in_ready[k]) begin
          automatic int j_sel = in_sel[k*SW +: SW];
          expected_beats[k][j_sel].push_back(in_data[k*DW +: DW]);
        end
      end
      
      // Verify delivered beats (R2, R3, R4, R5)
      for (int j=0; j<N_OUT; j++) begin
        if (out_valid[j] && out_ready[j]) begin
          automatic int k_idx = bfm_oidx(j);
          automatic logic [DW-1:0] d = bfm_odata(j);
          
          if (k_idx >= N_IN) begin
            fail_with($sformatf("R3: Output %0d delivered beat from invalid input %0d", j, k_idx));
          end else if (expected_beats[k_idx][j].size() == 0) begin
            fail_with($sformatf("R4: Output %0d delivered unexpected beat from input %0d", j, k_idx));
          end else begin
            automatic logic [DW-1:0] exp_d = expected_beats[k_idx][j].pop_front();
            if (exp_d !== d) begin
              fail_with($sformatf("R2/R5: Output %0d data mismatch or order broken. Exp %h, got %h", j, exp_d, d));
            end
          end
        end
      end
    end
    
    // Register outputs for next cycle A3 check
    for (int j=0; j<N_OUT; j++) begin
      prev_out_valid[j] = out_valid[j];
      prev_out_ready[j] = out_ready[j];
      prev_out_data[j]  = bfm_odata(j);
      prev_out_idx[j]   = bfm_oidx(j);
    end
  end

// ---------------------------------------------------------------------------
// STIMULUS GENERATION
// ---------------------------------------------------------------------------

  // Sends 'count' back-to-back beats on input 'k'.
  task automatic run_traffic(input int k, input int count, input logic random_dest);
    automatic int j = random_dest ? (k % N_OUT) : 0;
    
    @(negedge clk);
    bfm_next_sel[k]  = j;
    bfm_next_data[k] = (k << 16) | 0;
    bfm_offer[k]     = 1'b1;
    
    for (int i=1; i<count; i++) begin
      // Wait exactly for the cycle it is accepted
      do begin
        @(posedge clk);
      end while (!(in_valid[k] && in_ready[k]));
      
      // Provide the next payload instantly at posedge, ready for BFM negedge pickup
      if (random_dest) j = (k + i) % N_OUT;
      bfm_next_sel[k]  = j;
      bfm_next_data[k] = (k << 16) | i;
    end
    
    // Wait for the final beat to be taken
    do begin
      @(posedge clk);
    end while (!(in_valid[k] && in_ready[k]));
    
    @(negedge clk);
    bfm_offer[k] = 1'b0;
  endtask

  task automatic run_output_ready_toggle();
    automatic logic [N_OUT-1:0] r;
    for (int i=0; i<150; i++) begin
      @(negedge clk);
      r[0] = (i % 3) != 0;
      r[1] = (i % 4) != 0;
      r[2] = (i % 5) != 0;
      r[3] = (i % 2) != 0;
      bfm_ready(r);
    end
    bfm_ready('1);
  endtask

  initial begin
    bfm_reset(5);
    @(negedge clk);

    // TEST 1: Absolute Contention (A2, R5, X3, R1-R4)
    // Hammer output 0 continuously from all 4 inputs to test scheduling fairness.
    fork
      run_traffic(0, 30, 0); 
      run_traffic(1, 30, 0);
      run_traffic(2, 30, 0);
      run_traffic(3, 30, 0);
    join

    repeat(20) @(negedge clk);

    // TEST 2: Independence and HoL Blocking (I1, I2)
    // Block output 0 entirely.
    bfm_ready('b1110);
    @(negedge clk);
    
    // Input 0 aims for Output 0 (will block in the crossbar).
    bfm_next_sel[0] = 0;
    bfm_next_data[0] = 'hDEAD;
    bfm_offer[0] = 1'b1;
    
    // Inputs 1, 2, 3 aim for their respective unblocked outputs.
    fork
      run_traffic(1, 15, 1);
      run_traffic(2, 15, 1);
      run_traffic(3, 15, 1);
    join

    // Unblock output 0 so Input 0 can finally proceed.
    bfm_ready('b1111);
    
    // Wait for Input 0's blocked payload to finish
    do begin @(posedge clk); end while (!(in_valid[0] && in_ready[0]));
    @(negedge clk);
    bfm_offer[0] = 1'b0;

    repeat(20) @(negedge clk);

    // TEST 3: Random traffic and dynamic backpressure
    fork
      run_traffic(0, 50, 1);
      run_traffic(1, 50, 1);
      run_traffic(2, 50, 1);
      run_traffic(3, 50, 1);
      run_output_ready_toggle();
    join

    repeat(50) @(negedge clk);

    // Final checks for lost/stuck beats (R4)
    for (int k=0; k<N_IN; k++) begin
      for (int j=0; j<N_OUT; j++) begin
        if (expected_beats[k][j].size() > 0) begin
          fail_with($sformatf("R4: Missing %0d beats from input %0d to output %0d", expected_beats[k][j].size(), k, j));
        end
      end
    end

    $display("RESULT: PASS");
    $finish;
  end

endmodule