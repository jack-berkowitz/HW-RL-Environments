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
// TESTBENCH LOGIC
// ---------------------------------------------------------------------------

  typedef struct {
      logic [DW-1:0] data;
  } beat_t;

  beat_t expected_q [N_IN][N_OUT][$];

  int wait_cycles [N_IN];
  logic [N_OUT-1:0] prev_out_valid;
  logic [DW-1:0] prev_out_data [N_OUT];
  logic [IW-1:0] prev_out_idx [N_OUT];
  logic [N_OUT-1:0] prev_out_ready;

  int recent_src [N_IN];
  int a2_transfers = 0;
  int a2_check_enable = 0;
  int a2_target_out = 0;

  task automatic abort(string msg);
      $display("RESULT: FAIL (%s)", msg);
      $finish;
  endtask

  task automatic drain();
      automatic int max_wait = 1000;
      automatic int q_size;
      while (max_wait > 0) begin
          @(posedge clk);
          q_size = 0;
          for (int k = 0; k < N_IN; k++) begin
              if (in_valid[k]) q_size++;
              for (int j = 0; j < N_OUT; j++) begin
                  q_size += expected_q[k][j].size();
              end
          end
          if (q_size == 0) return;
          max_wait--;
      end
      abort("R4/X3: Draining timed out (Lost beats or deadlock)");
  endtask

  // X1 Check: Accepts nothing and completes nothing during reset
  always @(posedge clk) begin
      if (!rst_n && bfm_cycle > 0) begin
          for (int k = 0; k < N_IN; k++) begin
              if (in_valid[k] && in_ready[k]) abort("X1: Accepted beat during reset");
          end
          if (|out_valid) abort("X1: Delivered beat during reset");
      end
  end

  // X3 Check: Liveness bound (Accepted within 32 cycles)
  always @(posedge clk) begin
      if (rst_n) begin
          for (int k = 0; k < N_IN; k++) begin
              if (in_valid[k] && !in_ready[k]) begin
                  automatic int sel = in_sel[k*SW +: SW];
                  if (out_ready[sel]) begin
                      wait_cycles[k]++;
                      if (wait_cycles[k] > 32) abort("X3: Liveness bound exceeded");
                  end else begin
                      wait_cycles[k] = 0;
                  end
              end else begin
                  wait_cycles[k] = 0;
              end
          end
      end else begin
          for (int k = 0; k < N_IN; k++) wait_cycles[k] = 0;
      end
  end

  // A3 Check: Output stability under backpressure
  always @(posedge clk) begin
      if (rst_n && bfm_cycle > 0) begin
          for (int j = 0; j < N_OUT; j++) begin
              if (prev_out_valid[j] && !prev_out_ready[j]) begin
                  if (!out_valid[j]) abort("A3: Valid dropped while not ready");
                  if (bfm_odata(j) !== prev_out_data[j]) abort("A3: Data changed while not ready");
                  if (bfm_oidx(j) !== prev_out_idx[j]) abort("A3: Idx changed while not ready");
              end
          end
      end
      prev_out_valid <= out_valid;
      prev_out_ready <= out_ready;
      for (int j = 0; j < N_OUT; j++) begin
          prev_out_data[j] <= bfm_odata(j);
          prev_out_idx[j]  <= bfm_oidx(j);
      end
  end

  // A2 Check: Fairness
  always @(posedge clk) begin
      if (rst_n && a2_check_enable) begin
          automatic int j = a2_target_out;
          if (out_valid[j] && out_ready[j]) begin
              recent_src[3] = recent_src[2];
              recent_src[2] = recent_src[1];
              recent_src[1] = recent_src[0];
              recent_src[0] = bfm_oidx(j);
              a2_transfers++;
              if (a2_transfers >= 4) begin
                  automatic int seen[4] = '{0,0,0,0};
                  seen[recent_src[0]] = 1;
                  seen[recent_src[1]] = 1;
                  seen[recent_src[2]] = 1;
                  seen[recent_src[3]] = 1;
                  if (seen[0] + seen[1] + seen[2] + seen[3] != 4) abort("A2: Fairness bound violated");
              end
          end
      end else begin
          a2_transfers = 0;
      end
  end

  // R1-R6 Checking: Acceptance tracking and Delivery Validation
  always @(posedge clk) begin
      if (rst_n) begin
          // Track Acceptance
          for (int k = 0; k < N_IN; k++) begin
              if (in_valid[k] && in_ready[k]) begin
                  automatic beat_t b;
                  b.data = in_data[k*DW +: DW];
                  expected_q[k][in_sel[k*SW +: SW]].push_back(b);
              end
          end
          
          // Validate Delivery
          for (int j = 0; j < N_OUT; j++) begin
              if (out_valid[j] && out_ready[j]) begin
                  automatic int src = bfm_oidx(j);
                  if (src >= N_IN) abort("R3: out_idx out of bounds");
                  if (expected_q[src][j].size() == 0) abort("R4/R6: Delivered unexpected or extra beat");
                  begin
                      automatic beat_t exp_b = expected_q[src][j].pop_front();
                      if (bfm_odata(j) !== exp_b.data) abort("R2/R5: Payload mismatch or out of order");
                  end
              end
          end
      end
  end

  // Main Stimulus Sequence
  initial begin
      wait(rst_n === 1'b1);
      @(posedge clk);
      
      // --- X2 initial check ---
      out_ready = '1;
      repeat (10) @(posedge clk);
      if (|out_valid) abort("X2: Delivered beat after reset without input");

      // --- Phase 1: Basic Routing (R1-R6, A1) ---
      for (int i = 0; i < 10; i++) begin
          for (int k = 0; k < N_IN; k++) begin
              bfm_next_data[k] = k * 1000 + i;
              bfm_next_sel[k]  = (k + i) % N_OUT;
              bfm_offer[k]     = 1'b1;
          end
          @(posedge clk);
          @(posedge clk);
          bfm_offer = '0;
          for (int k = 0; k < N_IN; k++) begin
              while (in_valid[k]) @(posedge clk);
          end
      end
      drain();

      // --- Phase 2: A3 Stability & Backpressure ---
      out_ready = '0;
      for (int k = 0; k < N_IN; k++) begin
          bfm_next_data[k] = 32'hCAFE0000 + k;
          bfm_next_sel[k]  = k;
          bfm_offer[k]     = 1'b1;
      end
      repeat (20) @(posedge clk);
      out_ready = '1;
      @(posedge clk);
      @(posedge clk);
      bfm_offer = '0;
      drain();

      // --- Phase 3: HOL blocking (I1, I2) ---
      out_ready = 4'b1110; // Output 0 blocked
      bfm_next_sel[0] = 0; bfm_next_data[0] = 32'h1000; bfm_offer[0] = 1'b1;
      bfm_next_sel[1] = 1; bfm_next_data[1] = 32'h1001; bfm_offer[1] = 1'b1;
      bfm_next_sel[2] = 2; bfm_next_data[2] = 32'h1002; bfm_offer[2] = 1'b1;
      bfm_next_sel[3] = 3; bfm_next_data[3] = 32'h1003; bfm_offer[3] = 1'b1;
      
      // Wait to ensure paths not blocked by Output 0 can proceed
      repeat (40) @(posedge clk);
      bfm_offer = '0;
      out_ready = '1;
      drain();

      // --- Phase 4: Fairness (A2) ---
      a2_target_out = 0;
      a2_check_enable = 1;
      out_ready = '1;
      for (int k = 0; k < N_IN; k++) begin
          bfm_next_sel[k] = 0;
          bfm_next_data[k] = 32'hFA180000 + k;
          bfm_offer[k] = 1'b1;
      end
      repeat (100) begin
          @(posedge clk);
          for (int k = 0; k < N_IN; k++) begin
              bfm_next_data[k] = 32'hFA180000 + bfm_cycle + k;
          end
      end
      bfm_offer = '0;
      a2_check_enable = 0;
      drain();

      // --- Phase 5: Mid-flight Reset (X1, X2 discard property) ---
      out_ready = '0;
      for (int k = 0; k < N_IN; k++) begin
          bfm_next_sel[k] = (k + 1) % N_OUT;
          bfm_next_data[k] = 32'hDEADBEEF;
          bfm_offer[k] = 1'b1;
      end
      repeat (15) @(posedge clk);
      
      bfm_reset();
      
      // Clear expectations since beats were discarded
      for (int k = 0; k < N_IN; k++) begin
          for (int j = 0; j < N_OUT; j++) begin
              expected_q[k][j].delete();
          end
      end
      bfm_offer = '0;
      out_ready = '1;
      
      repeat (20) @(posedge clk);
      if (|out_valid) abort("X2: Delivered beat after reset from prior transaction");

      $display("RESULT: PASS");
      $finish;
  end

endmodule