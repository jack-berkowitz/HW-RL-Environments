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

  // ---------------------------------------------------------------------------
  // TB bookkeeping
  // ---------------------------------------------------------------------------
  // per-input FIFO of accepted-but-not-yet-delivered beats (bookkeeping, not
  // value matching: each beat carries a unique id in its payload)
  logic [DW-1:0] qd [N_IN][$];
  logic [SW-1:0] qs [N_IN][$];

  // A3 shadow: what the output offered last cycle
  logic             prev_ov [N_OUT];
  logic             prev_ox [N_OUT];
  logic [DW-1:0]    prev_od [N_OUT];
  logic [IW-1:0]    prev_oi [N_OUT];

  // per-output history of recent transfers: served input + who was offering
  int               hsrc [N_OUT][8];
  logic [N_IN-1:0]  hoff [N_OUT][8];
  int               hlen [N_OUT];

  // per-output transfer counter (used by stimulus to measure progress)
  int               xlen [N_OUT];

  int acc_cnt = 0;
  int del_cnt = 0;
  int age   [N_IN];       // cycles input k has been offering with its bound output ready
  int fail  = 0;
  int uid   = 1;
  int sent  [N_IN];
  int ph_w;

  task automatic fail_now(input string cl);
    if (fail == 0) begin
      fail = 1;
      $display("TB FAIL: %s", cl);
    end
  endtask

  task automatic wrap_up;
    if (fail == 0) begin
      if (del_cnt != acc_cnt) fail_now("R4: accepted and delivered counts differ");
      for (int k = 0; k < N_IN; k++)
        if (qd[k].size() != 0) fail_now("R4: accepted beats left undelivered");
    end
    if (fail == 0) $display("RESULT: PASS");
    else           $display("RESULT: FAIL");
    $finish;
  endtask

  task automatic drain_all(input int tmo);
    bfm_ready(4'b1111);
    ph_w = 0;
    while (del_cnt < acc_cnt && fail == 0 && ph_w < tmo) begin
      @(negedge clk);
      ph_w = ph_w + 1;
    end
    if (del_cnt < acc_cnt && fail == 0)
      fail_now("R4: accepted beat never delivered");
  endtask

  // ---------------------------------------------------------------------------
  // Checker: runs at the rising edge, samples the handshakes the design sees
  // ---------------------------------------------------------------------------
  always @(posedge clk) begin
    logic             xfer;
    logic [IW-1:0]    oi;
    logic [N_IN-1:0]  offj;
    logic [DW-1:0]    bd;
    logic [SW-1:0]    bs;
    logic [N_IN-1:0]  smask;
    int               c2;
    int               m2;
    if (!fail) begin
      if (rst_n) begin
        // ---- input side: record acceptances, watch the X3 bound ----
        for (int k = 0; k < N_IN; k++) begin
          if (in_valid[k] && in_ready[k]) begin
            qd[k].push_back(in_data[k*DW +: DW]);
            qs[k].push_back(in_sel[k*SW +: SW]);
            acc_cnt = acc_cnt + 1;
            age[k]  = 0;
          end else if (in_valid[k]) begin
            if (out_ready[int'(in_sel[k*SW +: SW])]) age[k] = age[k] + 1;
            else age[k] = 0;
            if (age[k] > 32)
              fail_now("X3: offered beat not accepted within 32 cycles");
          end else begin
            age[k] = 0;
          end
        end
        // ---- output side ----
        for (int j = 0; j < N_OUT; j++) begin
          xfer = out_valid[j] & out_ready[j];
          // A3: an offer, once made, may not be withdrawn or re-aimed
          if (prev_ov[j] && !prev_ox[j]) begin
            if (!out_valid[j])
              fail_now("A3: output offer withdrawn before ready was seen");
            else if (out_data[j*DW +: DW] != prev_od[j] ||
                     out_idx [j*IW +: IW] != prev_oi[j])
              fail_now("A3: offered payload/index changed before ready was seen");
          end
          prev_ov[j] = out_valid[j];
          prev_ox[j] = xfer;
          prev_od[j] = out_data[j*DW +: DW];
          prev_oi[j] = out_idx [j*IW +: IW];
          if (xfer) begin
            del_cnt = del_cnt + 1;
            oi = out_idx[j*IW +: IW];
            // R4/R6: every delivered beat was accepted and is still owed
            if (qd[oi].size() == 0) begin
              fail_now("R4/R6: delivered beat with no pending acceptance (invented, duplicated or lost-origin beat)");
            end else begin
              bd = qd[oi].pop_front();
              bs = qs[oi].pop_front();
              if (bs != SW'(j))
                fail_now("R1: beat delivered on the wrong output");
              if (bd != out_data[j*DW +: DW])
                fail_now("R2/R5: payload modified or same-input beats reordered");
            end
            // who is offering toward j right now
            offj = '0;
            for (int k = 0; k < N_IN; k++)
              offj[k] = in_valid[k] & (int'(in_sel[k*SW +: SW]) == j);
            // A2: k, continuously offering, must not be passed over for
            // |S|+ transfers.  A slack of 3 covers beats already in flight
            // inside registered implementations (L3), while any persistent
            // starvation (c2 saturates at 9) is always caught.
            for (int k = 0; k < N_IN; k++) begin
              if (offj[k] && int'(oi) != k) begin
                c2 = 1;
                for (int h = 0; h < hlen[j] && h < 8; h++) begin
                  if (hoff[j][h][k] && hsrc[j][h] != k) c2 = c2 + 1;
                  else break;
                end
                if (c2 >= 2) begin
                  smask = offj;
                  for (int h = 0; h < c2 - 1 && h < 8; h++)
                    smask = smask & hoff[j][h];
                  m2 = 0;
                  for (int kk = 0; kk < N_IN; kk++) if (smask[kk]) m2 = m2 + 1;
                  if (c2 >= m2 + 3)
                    fail_now("A2: continuously offering input starved of service");
                end
              end
            end
            // push the history record
            for (int h = 7; h > 0; h--) begin
              hsrc[j][h] = hsrc[j][h-1];
              hoff[j][h] = hoff[j][h-1];
            end
            hsrc[j][0] = int'(oi);
            hoff[j][0] = offj;
            if (hlen[j] < 8) hlen[j] = hlen[j] + 1;
            if (xlen[j] < 1000) xlen[j] = xlen[j] + 1;
          end
        end
      end else begin
        // ---- reset is asserted (asynchronously) ----
        if ((out_valid & out_ready) != '0)
          fail_now("X1: transfer completed while reset was asserted");
        for (int k = 0; k < N_IN; k++) begin
          qd[k].delete(); qs[k].delete(); age[k] = 0;
        end
        for (int j = 0; j < N_OUT; j++) begin
          prev_ov[j] = 1'b0;
          hlen[j]    = 0;
        end
        acc_cnt = 0;
        del_cnt = 0;
      end
    end
  end

  // ---------------------------------------------------------------------------
  // Stimulus
  // ---------------------------------------------------------------------------
  initial begin
    // ---- Phase 0: reset ----
    bfm_reset(5);

    // ---- Phase 1: X2 -- after reset the unit owes nothing ----
    $display("TB: phase 1 (post-reset idle)");
    for (ph_w = 0; ph_w < 10; ph_w++) begin
      @(negedge clk);
      if (|out_valid) fail_now("X2: spurious output offer after reset");
    end
    if (fail) wrap_up;

    // ---- Phase 2: every (input, output) pair, one beat at a time ----
    $display("TB: phase 2 (routing of every pair)");
    for (int k = 0; k < N_IN; k++) begin
      for (int j = 0; j < N_OUT; j++) begin
        @(negedge clk);
        bfm_next_data[k] = DW'(uid); uid = uid + 1;
        bfm_next_sel[k]  = SW'(j);
        bfm_offer[k]     = 1'b1;
        ph_w = 0;
        while (!bfm_accepted[k] && fail == 0 && ph_w < 200) begin
          @(negedge clk);
          ph_w = ph_w + 1;
        end
        bfm_offer[k] = 1'b0;
        if (fail) wrap_up;
        if (!bfm_accepted[k]) fail_now("H1/X3: beat never accepted");
        drain_all(500);
        if (fail) wrap_up;
      end
    end

    // ---- Phase 3: four parallel streams, input k -> output k ----
    $display("TB: phase 3 (parallel streams)");
    @(negedge clk);
    for (int k = 0; k < N_IN; k++) begin
      sent[k] = 0;
      bfm_next_sel[k]  = SW'(k);
      bfm_next_data[k] = DW'(uid); uid = uid + 1;
      bfm_offer[k]     = 1'b1;
    end
    ph_w = 0;
    while ((sent[0] < 20 || sent[1] < 20 || sent[2] < 20 || sent[3] < 20) &&
           fail == 0 && ph_w < 3000) begin
      @(negedge clk);
      for (int k = 0; k < N_IN; k++) begin
        if (bfm_accepted[k]) begin
          sent[k] = sent[k] + 1;
          if (sent[k] < 20) begin
            bfm_next_data[k] = DW'(uid); uid = uid + 1;
          end else begin
            bfm_offer[k] = 1'b0;
          end
        end
      end
      ph_w = ph_w + 1;
    end
    for (int k = 0; k < N_IN; k++) bfm_offer[k] = 1'b0;
    if (fail) wrap_up;
    if (sent[0] < 20 || sent[1] < 20 || sent[2] < 20 || sent[3] < 20)
      fail_now("X3: parallel stream stalled");
    drain_all(1000);
    if (fail) wrap_up;

    // ---- Phase 4: four-way contention on output 0 (A2, R5, X3) ----
    $display("TB: phase 4 (four-way contention)");
    @(negedge clk);
    bfm_ready(4'b1111);
    for (int j = 0; j < N_OUT; j++) begin hlen[j] = 0; xlen[j] = 0; end
    for (int k = 0; k < N_IN; k++) begin
      sent[k] = 0;
      bfm_next_sel[k]  = SW'(0);
      bfm_next_data[k] = DW'(uid); uid = uid + 1;
      bfm_offer[k]     = 1'b1;
    end
    ph_w = 0;
    while (xlen[0] < 44 && fail == 0 && ph_w < 3000) begin
      @(negedge clk);
      for (int k = 0; k < N_IN; k++) begin
        if (bfm_accepted[k]) begin
          sent[k] = sent[k] + 1;
          if (sent[k] < 12) begin
            bfm_next_data[k] = DW'(uid); uid = uid + 1;
          end else begin
            bfm_offer[k] = 1'b0;
          end
        end
      end
      ph_w = ph_w + 1;
    end
    for (int k = 0; k < N_IN; k++) bfm_offer[k] = 1'b0;
    if (fail) wrap_up;
    if (xlen[0] < 44) fail_now("X3/A2: contended output made no progress");
    drain_all(2000);
    if (fail) wrap_up;

    // ---- Phase 5: two-way contention on output 0 (A2 exact window) ----
    $display("TB: phase 5 (two-way contention)");
    @(negedge clk);
    bfm_ready(4'b1111);
    for (int j = 0; j < N_OUT; j++) begin hlen[j] = 0; xlen[j] = 0; end
    for (int k = 0; k < 2; k++) begin
      sent[k] = 0;
      bfm_next_sel[k]  = SW'(0);
      bfm_next_data[k] = DW'(uid); uid = uid + 1;
      bfm_offer[k]     = 1'b1;
    end
    for (int k = 2; k < N_IN; k++) bfm_offer[k] = 1'b0;
    ph_w = 0;
    while (xlen[0] < 40 && fail == 0 && ph_w < 3000) begin
      @(negedge clk);
      for (int k = 0; k < 2; k++) begin
        if (bfm_accepted[k]) begin
          sent[k] = sent[k] + 1;
          if (sent[k] < 20) begin
            bfm_next_data[k] = DW'(uid); uid = uid + 1;
          end else begin
            bfm_offer[k] = 1'b0;
          end
        end
      end
      ph_w = ph_w + 1;
    end
    for (int k = 0; k < 2; k++) bfm_offer[k] = 1'b0;
    if (fail) wrap_up;
    if (xlen[0] < 40) fail_now("A2/X3: two-way contention made no progress");
    drain_all(1000);
    if (fail) wrap_up;

    // ---- Phase 6: backpressure, A3 hold, I1 ----
    $display("TB: phase 6 (backpressure / A3 / I1)");
    @(negedge clk);
    bfm_ready(4'b1110);                 // output 0 backpressured from the start
    xlen[1] = 0;
    bfm_next_data[0] = DW'(uid); uid = uid + 1;
    bfm_next_sel[0]  = SW'(0);
    bfm_offer[0]     = 1'b1;
    bfm_next_data[1] = DW'(uid); uid = uid + 1;
    bfm_next_sel[1]  = SW'(1);
    bfm_offer[1]     = 1'b1;            // input 1 streams to the ready output 1
    ph_w = 0;
    while (!out_valid[0] && fail == 0 && ph_w < 60) begin
      @(negedge clk);
      ph_w = ph_w + 1;
    end
    // hold output 0 backpressured: the A3 monitor checks the offer is neither
    // withdrawn nor re-aimed; input 1 must keep flowing (I1)
    for (ph_w = 0; ph_w < 12; ph_w++) @(negedge clk);
    if (xlen[1] == 0)
      fail_now("I1: backpressured output stalled a ready output");
    bfm_offer[0] = 1'b0;
    bfm_offer[1] = 1'b0;
    bfm_ready(4'b1111);
    drain_all(500);
    if (fail) wrap_up;

    // ---- Phase 7: no head-of-line blocking across inputs (I2) ----
    $display("TB: phase 7 (independence across inputs)");
    @(negedge clk);
    bfm_ready(4'b1110);
    xlen[1] = 0; xlen[2] = 0; xlen[3] = 0;
    bfm_next_data[0] = DW'(uid); uid = uid + 1;
    bfm_next_sel[0]  = SW'(0);
    bfm_offer[0]     = 1'b1;           // bound for the blocked output
    for (int k = 1; k < N_IN; k++) begin
      bfm_next_data[k] = DW'(uid); uid = uid + 1;
      bfm_next_sel[k]  = SW'(k);
      bfm_offer[k]     = 1'b1;
    end
    for (ph_w = 0; ph_w < 20; ph_w++) @(negedge clk);
    if (xlen[1] == 0 || xlen[2] == 0 || xlen[3] == 0)
      fail_now("I2: input bound for a blocked output blocked the other inputs");
    for (int k = 0; k < N_IN; k++) bfm_offer[k] = 1'b0;
    bfm_ready(4'b1111);
    drain_all(500);
    if (fail) wrap_up;

    // ---- Phase 8: reset (X1, X2), including a possibly pending beat ----
    $display("TB: phase 8 (reset)");
    @(negedge clk);
    bfm_ready(4'b1110);                 // block output 0
    bfm_next_data[0] = DW'(uid); uid = uid + 1;
    bfm_next_sel[0]  = SW'(0);
    bfm_offer[0]     = 1'b1;
    ph_w = 0;
    while (!bfm_accepted[0] && fail == 0 && ph_w < 60) begin
      @(negedge clk);
      ph_w = ph_w + 1;
    end
    bfm_offer[0] = 1'b0;
    if (!bfm_accepted[0]) begin
      // the unit would not accept against a blocked output: let the beat go,
      // so that reset is entered with the inputs quiet
      bfm_ready(4'b1111);
      drain_all(500);
    end
    if (fail) wrap_up;
    // make sure no input is offering before reset is asserted
    ph_w = 0;
    while ((|in_valid) && fail == 0 && ph_w < 100) begin
      @(negedge clk);
      ph_w = ph_w + 1;
    end
    bfm_ready(4'b1110);
    @(negedge clk);
    rst_n = 1'b0;
    // X1: while reset is low (inputs quiet) nothing is offered or completed
    for (ph_w = 0; ph_w < 5; ph_w++) begin
      @(negedge clk);
      if (|out_valid) fail_now("X1: output offered a beat during reset");
    end
    if (fail) wrap_up;
    @(negedge clk);
    rst_n = 1'b1;
    // X2: after release the unit holds no beat and owes no delivery
    for (ph_w = 0; ph_w < 10; ph_w++) begin
      @(negedge clk);
      if (|out_valid) fail_now("X2: stale beat offered after reset release");
    end
    bfm_ready(4'b1111);
    for (ph_w = 0; ph_w < 5; ph_w++) begin
      @(negedge clk);
      if (|out_valid) fail_now("X2: stale beat offered after reset release");
      if (del_cnt != 0 || acc_cnt != 0)
        fail_now("X2/R4: unit delivered a beat it held across reset");
    end
    if (fail) wrap_up;

    // ---- Phase 9: the unit still works after reset ----
    $display("TB: phase 9 (post-reset sanity)");
    for (int k = 0; k < N_IN; k++) begin
      @(negedge clk);
      bfm_next_data[k] = DW'(uid); uid = uid + 1;
      bfm_next_sel[k]  = SW'((k + 1) % 4);
      bfm_offer[k]     = 1'b1;
      ph_w = 0;
      while (!bfm_accepted[k] && fail == 0 && ph_w < 200) begin
        @(negedge clk);
        ph_w = ph_w + 1;
      end
      bfm_offer[k] = 1'b0;
      if (fail) wrap_up;
      if (!bfm_accepted[k]) fail_now("X3: no acceptance after reset");
    end
    drain_all(500);
    if (fail) wrap_up;

    $display("TB: all phases complete");
    wrap_up;
  end

  // ---------------------------------------------------------------------------
  // Watchdog -- a hang is not a verdict
  // ---------------------------------------------------------------------------
  initial begin
    #2_000_000;
    $display("TB FAIL: watchdog timeout, no verdict reached by the stimulus");
    $display("RESULT: FAIL");
    $finish;
  end

endmodule
