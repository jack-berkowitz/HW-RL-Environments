module route_xbar_tb;

  // ---------------------------------------------------------------------------
  // PROVIDED PLUMBING
  // ---------------------------------------------------------------------------
  localparam int N_IN = 4, N_OUT = 4, DW = 32, SW = 2, IW = 2;

  logic clk = 1'b0;
  always #5 clk = ~clk;

  int bfm_cycle = 0;
  always @(posedge clk) if (rst_n) bfm_cycle <= bfm_cycle + 1;

  logic rst_n = 1'b0;        // ASYNCHRONOUS, ACTIVE LOW

  task automatic bfm_reset(input int cycles = 5);
    @(negedge clk);
    rst_n = 1'b0;
    repeat (cycles) @(posedge clk);
    @(negedge clk);
    rst_n = 1'b1;
  endtask

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

  function automatic logic [DW-1:0] bfm_odata(input int j); return out_data[j*DW +: DW]; endfunction
  function automatic logic [IW-1:0] bfm_oidx (input int j); return out_idx [j*IW +: IW]; endfunction

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
        if (bfm_accepted[k]) in_valid[k] = 1'b0;
        if (!in_valid[k] && bfm_offer[k]) begin
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
  // CHECKER
  // ---------------------------------------------------------------------------
  // Bookkeeping: one FIFO per (input k, output j).  A beat accepted on k with
  // sel==j is pushed onto FIFO[k][j]; a transfer on output j claiming source k
  // pops FIFO[k][j].  This structurally enforces R1 (routing), R4 (exactly
  // once), R5 (order per input/output pair) and R6 (nothing delivered that was
  // not accepted); the payload compare enforces R2 and the index range R3.
  localparam int QD = 1024;
  logic [DW-1:0] buf_d [N_IN][N_OUT][QD];
  int buf_h [N_IN][N_OUT];
  int buf_t [N_IN][N_OUT];
  int age   [N_IN];          // cycles input k has been offering with bound output ready
  int accnt [N_IN];          // acceptances per input
  int xcnt  [N_OUT];         // transfers per output

  // previous-edge shadow for A3
  logic [N_OUT-1:0]    pv_v;
  logic [N_OUT*DW-1:0] pv_d;
  logic [N_OUT*IW-1:0] pv_i;
  logic [N_OUT-1:0]    pv_r;
  logic                pv_rstn;

  // fairness capture
  int    fair_seq [4096];
  int    fair_n;
  int    fair_j;
  logic  fair_en;

  int ck_k, ck_j;

  task automatic tb_fail(input string clause);
    $display("RESULT: FAIL (%s)", clause);
    $finish;
  endtask

  function automatic int outstanding();
    int s = 0;
    for (int k = 0; k < N_IN; k++)
      for (int j = 0; j < N_OUT; j++)
        s += buf_t[k][j] - buf_h[k][j];
    return s;
  endfunction

  always @(posedge clk) begin
    if (rst_n) begin
      // ---- acceptances: push into per-(k,j) FIFO, X3 bookkeeping ----
      for (ck_k = 0; ck_k < N_IN; ck_k++) begin
        if (in_valid[ck_k] && in_ready[ck_k]) begin
          ck_j = in_sel[ck_k*SW +: SW];
          buf_d[ck_k][ck_j][buf_t[ck_k][ck_j] % QD] = in_data[ck_k*DW +: DW];
          buf_t[ck_k][ck_j] = buf_t[ck_k][ck_j] + 1;
          accnt[ck_k]       = accnt[ck_k] + 1;
          age[ck_k]         = 0;
        end else if (in_valid[ck_k]) begin
          if (out_ready[in_sel[ck_k*SW +: SW]]) age[ck_k] = age[ck_k] + 1;
          else                                   age[ck_k] = 0;
          if (age[ck_k] > 32) tb_fail("X3: liveness bound violated (offer not accepted within 32 cycles)");
        end else begin
          age[ck_k] = 0;
        end
      end

      // ---- output transfers: pop and verify ----
      for (ck_j = 0; ck_j < N_OUT; ck_j++) begin
        if (out_valid[ck_j] && out_ready[ck_j]) begin
          xcnt[ck_j] = xcnt[ck_j] + 1;
          if (fair_en && ck_j == fair_j) begin
            fair_seq[fair_n] = out_idx[ck_j*IW +: IW];
            fair_n = fair_n + 1;
          end
          ck_k = out_idx[ck_j*IW +: IW];
          if (ck_k >= N_IN) tb_fail("R3: out_idx names a nonexistent input");
          else if (buf_h[ck_k][ck_j] == buf_t[ck_k][ck_j])
            tb_fail("R6/R4: delivered beat was never accepted (or delivered twice)");
          else begin
            if (buf_d[ck_k][ck_j][buf_h[ck_k][ck_j] % QD] !== out_data[ck_j*DW +: DW])
              tb_fail("R2/R5/R1: payload mismatch, corruption or reorder");
            buf_h[ck_k][ck_j] = buf_h[ck_k][ck_j] + 1;
          end
        end
      end

      // ---- A3: an offered output beat may not be withdrawn or changed ----
      if (pv_rstn) begin
        for (ck_j = 0; ck_j < N_OUT; ck_j++) begin
          if (pv_v[ck_j] && !pv_r[ck_j]) begin
            if (!out_valid[ck_j]) tb_fail("A3: output offer withdrawn before ready");
            else if (out_data[ck_j*DW +: DW] !== pv_d[ck_j*DW +: DW] ||
                     out_idx [ck_j*IW +: IW] !== pv_i[ck_j*IW +: IW])
              tb_fail("A3: output offer re-aimed or payload changed");
          end
        end
      end
    end
    pv_v    <= out_valid & {N_OUT{rst_n}};
    pv_d    <= out_data;
    pv_i    <= out_idx;
    pv_r    <= out_ready;
    pv_rstn <= rst_n;
  end

  // ---------------------------------------------------------------------------
  // STIMULUS
  // ---------------------------------------------------------------------------
  task automatic drain(input int maxc);
    int c = 0;
    @(negedge clk);
    bfm_offer = '0;
    out_ready = '1;
    while (c < maxc) begin
      @(posedge clk);
      if (outstanding() == 0 && in_valid == '0) return;
      c = c + 1;
    end
    tb_fail("R4: accepted beat never delivered");
  endtask

  task automatic wait_acc_k(input int k, input int target, input int maxc);
    int c = 0;
    while (c < maxc) begin
      @(posedge clk);
      if (accnt[k] >= target) return;
      c = c + 1;
    end
    tb_fail("X3: input never accepted (liveness)");
  endtask

  int c, b2, b3, s1, s2;
  int seen [4];

  initial begin
    for (int k = 0; k < N_IN; k++)
      for (int j = 0; j < N_OUT; j++) begin
        buf_h[k][j] = 0; buf_t[k][j] = 0;
      end
    for (int k = 0; k < N_IN; k++) begin age[k] = 0; accnt[k] = 0; end
    for (int j = 0; j < N_OUT; j++) xcnt[j] = 0;
    fair_n = 0; fair_en = 0; fair_j = 0;
    pv_v = '0; pv_r = '0; pv_rstn = 1'b0;

    bfm_reset(3);

    // ---- X2: after reset the unit holds no beat, owes no delivery ----
    repeat (10) begin
      @(posedge clk); @(negedge clk);
      if (out_valid !== '0) tb_fail("X2: beat offered immediately after reset");
    end

    // ---- phase A: one beat per input, all distinct outputs (R1/R2/R3) ----
    @(negedge clk);
    for (int k = 0; k < N_IN; k++) begin
      bfm_next_data[k] = 32'hA000_0000 + k;
      bfm_next_sel[k]  = SW'(k);
    end
    bfm_offer = '1; out_ready = '1;
    for (int k = 0; k < N_IN; k++) wait_acc_k(k, accnt[k] + 1, 200);
    drain(300);

    // ---- phase B: same input -> same output, in-order (R5) ----
    @(negedge clk);
    bfm_next_sel[0] = 2'd1;
    bfm_offer = 4'b0001;
    for (int m = 0; m < 8; m++) begin
      bfm_next_data[0] = 32'hC000_0000 + m;
      wait_acc_k(0, accnt[0] + 2, 200);
    end
    drain(300);

    // ---- phase C: fairness, |S| = 4, all inputs to output 0 (A2) ----
    @(negedge clk);
    for (int k = 0; k < N_IN; k++) begin
      bfm_next_data[k] = 32'hF000_0000 + k;
      bfm_next_sel[k]  = 2'd0;
    end
    bfm_offer = '1; out_ready = '1;
    fair_j = 0; fair_n = 0; fair_en = 1;
    c = 0;
    while (fair_n < 48 && c < 500) begin @(posedge clk); c = c + 1; end
    fair_en = 0;
    if (fair_n < 48) tb_fail("X3: no transfers under full contention");
    for (int w = 4; w + 4 <= fair_n; w++) begin
      seen[0] = 0; seen[1] = 0; seen[2] = 0; seen[3] = 0;
      for (int i = 0; i < 4; i++) seen[fair_seq[w+i]] = 1;
      if (!(seen[0] && seen[1] && seen[2] && seen[3]))
        tb_fail("A2: fairness bound violated (|S|=4, some input starved in a 4-transfer window)");
    end
    drain(500);

    // ---- phase D: fairness, |S| = 2, inputs 1 and 3 to output 2 (A2) ----
    @(negedge clk);
    bfm_offer = '0;
    bfm_next_data[1] = 32'hE000_0001; bfm_next_sel[1] = 2'd2;
    bfm_next_data[3] = 32'hE000_0003; bfm_next_sel[3] = 2'd2;
    bfm_offer = 4'b1010; out_ready = '1;
    fair_j = 2; fair_n = 0; fair_en = 1;
    c = 0;
    while (fair_n < 36 && c < 500) begin @(posedge clk); c = c + 1; end
    fair_en = 0;
    if (fair_n < 36) tb_fail("X3: no transfers under 2-way contention");
    for (int w = 4; w + 2 <= fair_n; w++)
      if (fair_seq[w] == fair_seq[w+1])
        tb_fail("A2: fairness bound violated (|S|=2, same input served twice in a row)");
    drain(500);

    // ---- phase E: independence (I1 / I2) ----
    // inputs 0,1 -> output 0 (stalled); inputs 2 -> out 2, 3 -> out 3 (ready)
    @(negedge clk);
    bfm_next_data[0] = 32'h1000_0000; bfm_next_sel[0] = 2'd0;
    bfm_next_data[1] = 32'h1000_0001; bfm_next_sel[1] = 2'd0;
    bfm_next_data[2] = 32'h1000_0002; bfm_next_sel[2] = 2'd2;
    bfm_next_data[3] = 32'h1000_0003; bfm_next_sel[3] = 2'd3;
    bfm_offer = '1;
    out_ready = 4'b1011;                       // output 0 not ready
    b2 = xcnt[2]; b3 = xcnt[3];
    s1 = accnt[2]; s2 = accnt[3];
    repeat (60) @(posedge clk);
    if (xcnt[2] == b2) tb_fail("I1: not-ready output 0 blocks transfers on output 2");
    if (xcnt[3] == b3) tb_fail("I1: not-ready output 0 blocks transfers on output 3");
    if (accnt[2] == s1) tb_fail("I2: input blocked on stalled output prevents acceptance of input 2");
    if (accnt[3] == s2) tb_fail("I2: input blocked on stalled output prevents acceptance of input 3");
    drain(500);

    // ---- phase F: random traffic (R1..R6, A3, X3 under contention) ----
    @(negedge clk);
    for (int it = 0; it < 400; it++) begin
      bfm_offer = $urandom();
      for (int k = 0; k < N_IN; k++) begin
        bfm_next_data[k] = $urandom();
        bfm_next_sel[k]  = $urandom_range(0, N_OUT-1);
      end
      if ($urandom_range(0, 7) == 0) out_ready = $urandom();
      else                           out_ready = '1;
      @(negedge clk);
    end
    drain(2000);

    // ---- phase G: reset behaviour (X1 / X2) ----
    @(negedge clk);
    bfm_offer = '0; out_ready = '1;
    c = 0;
    while ((in_valid != '0 || outstanding() != 0) && c < 300) begin
      @(posedge clk); c = c + 1;
    end
    if (outstanding() != 0) tb_fail("R4: accepted beat never delivered");
    @(negedge clk);
    rst_n = 1'b0;
    repeat (8) begin
      @(posedge clk); @(negedge clk);
      if (|out_valid) tb_fail("X1: transfer offered/completed while reset asserted");
    end
    @(negedge clk);
    rst_n = 1'b1;
    repeat (10) begin
      @(posedge clk); @(negedge clk);
      if (out_valid !== '0) tb_fail("X2: beat held across reset");
    end

    // ---- final verdict ----
    drain(200);
    if (outstanding() != 0) tb_fail("R4: accepted beat never delivered");
    $display("All checks completed.");
    $display("RESULT: PASS");
    $finish;
  end

endmodule
