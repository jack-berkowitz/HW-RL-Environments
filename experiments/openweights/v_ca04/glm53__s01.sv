module route_xbar_tb;

  // ---------------------------------------------------------------------------
  // PROVIDED PLUMBING -- moves beats, checks nothing.
  ---------------------------------------------------------------------------
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
  // TB STATE
  ---------------------------------------------------------------------------
  string phase_name;

  int tag_ctr;            // unique tag == payload of each beat
  int seq_ctr;            // global acceptance sequence number
  int live_cnt;           // accepted-but-undelivered beats
  int settled;            // consecutive fully-quiet posedges (for drain)
  bit rst_active_seen;
  int acc_total;
  int acc_per_in   [N_IN];
  int xfer_per_out [N_OUT];
  int x3_cnt [N_IN];
  bit x3_cont [N_IN];

  logic [N_OUT-1:0]     pv_valid, pv_ready;   // previous-edge samples for A3
  logic [N_OUT*DW-1:0]  pv_data;
  logic [N_OUT*IW-1:0]  pv_idx;

  int fair_m    [N_OUT];  // fairness contract: set of inputs bound for this output
  int fair_sz   [N_OUT];  // |S|
  int fair_skip [N_OUT];  // transfers to skip while the phase ramps up
  int fhist     [N_OUT][4];

  int tag_out      [int];  // tag -> destination output   (live beats)
  int tag_src      [int];  // tag -> source input
  int tag_seq      [int];  // tag -> acceptance seq no.
  int tag_next_seq [int];  // seq -> next seq from same (input,output)  (R5 chain)
  bit tag_done     [int];  // delivered tags (double-delivery detection)
  bit amnesty      [int];  // beats offered-but-never-accepted at reset assertion

  int io_exp       [N_IN][N_OUT];  // oldest undelivered seq per (input,output)
  int io_last      [N_IN][N_OUT];  // newest accepted seq per (input,output)
  bit io_exp_valid [N_IN][N_OUT];

  logic [N_IN-1:0]  feed_en;
  logic [N_IN-1:0]  single_shot;
  int   feed_dst [N_IN];
  int   feed_mode;                 // 0 = fixed dst, 1 = rotating dst
  int   feed_cnt [N_IN];
  logic [N_OUT-1:0] ready_cmd;

  int c_tag, c_dst, c_src, c_idx, c_seq, c_sel, c_cov;

  // ---------------------------------------------------------------------------
  task automatic fail(input string m);
    begin
      $display("TB-FAIL: phase=%s : %s", phase_name, m);
      $display("RESULT: FAIL");
      $finish;
    end
  endtask

  // out_ready is driven from the negedge opposite the sampling edge.
  always @(negedge clk) out_ready = ready_cmd;

  // Feeder: on acceptance, supply the next beat for streaming inputs.
  always @(posedge clk) begin
    if (rst_n) begin
      for (int k = 0; k < N_IN; k++) begin
        if (feed_en[k] && in_valid[k] && in_ready[k]) begin
          feed_cnt[k] = feed_cnt[k] + 1;
          bfm_next_data[k] = tag_ctr;
          tag_ctr = tag_ctr + 1;
          if (feed_mode == 0) bfm_next_sel[k] = feed_dst[k];
          else                bfm_next_sel[k] = (k + feed_cnt[k]) % N_OUT;
        end
      end
    end
  end

  // Single-beat offers: stop offering on the edge the beat is accepted.
  always @(posedge clk) begin
    if (rst_n) begin
      for (int k = 0; k < N_IN; k++) begin
        if (single_shot[k] && in_valid[k] && in_ready[k]) begin
          bfm_offer[k]  = 1'b0;
          single_shot[k] = 1'b0;
        end
      end
    end
  end

  // ---------------------------------------------------------------------------
  // MAIN CHECKER -- samples all handshakes at the rising edge.
  // ---------------------------------------------------------------------------
  always @(posedge clk) begin
    if (!rst_n) begin
      // X1: with the inputs quiet, the unit may present nothing while in reset.
      if (in_valid == '0 && out_valid != '0)
        fail("X1: out_valid asserted while rst_ni low and inputs quiet");
      if (!rst_active_seen) begin
        rst_active_seen = 1'b1;
        amnesty.delete();
        // forgive beats that were merely offered (never accepted) at reset time
        for (int k = 0; k < N_IN; k++)
          if (in_valid[k]) amnesty[in_data[k*DW +: DW]] = 1'b1;
        // X2: after reset the unit owes nothing; drop all expectations
        tag_out.delete(); tag_src.delete(); tag_seq.delete();
        tag_next_seq.delete(); tag_done.delete();
        live_cnt = 0;
        for (int k = 0; k < N_IN; k++)
          for (int j = 0; j < N_OUT; j++)
            io_exp_valid[k][j] = 1'b0;
      end
      for (int k = 0; k < N_IN; k++) begin
        x3_cnt[k]  = 0;
        x3_cont[k] = 1'b1;
      end
      pv_valid <= '0; pv_ready <= '0; pv_data <= '0; pv_idx <= '0;
    end else begin
      if (rst_active_seen) rst_active_seen = 1'b0;

      // ---- A3: an offered output beat may not be withdrawn or re-aimed ----
      for (int j = 0; j < N_OUT; j++) begin
        if (pv_valid[j] && !pv_ready[j]) begin
          if (!out_valid[j])
            fail("A3: out_valid withdrawn before out_ready was seen");
          if (out_data[j*DW +: DW] != pv_data[j*DW +: DW] ||
              out_idx [j*IW +: IW] != pv_idx [j*IW +: IW])
            fail("A3: offered beat changed (data or idx) while waiting for out_ready");
        end
      end

      // ---- acceptances (bookkeeping) ----
      for (int k = 0; k < N_IN; k++) begin
        if (in_valid[k] && in_ready[k]) begin
          acc_total       = acc_total + 1;
          acc_per_in[k]   = acc_per_in[k] + 1;
          c_tag = in_data[k*DW +: DW];
          c_dst = in_sel [k*SW +: SW];
          if (tag_out.exists(c_tag))
            fail("TB internal error: tag collision");
          seq_ctr = seq_ctr + 1;
          tag_out[c_tag] = c_dst;
          tag_src[c_tag] = k;
          tag_seq[c_tag] = seq_ctr;
          if (io_exp_valid[k][c_dst]) begin
            tag_next_seq[io_last[k][c_dst]] = seq_ctr;
          end else begin
            io_exp_valid[k][c_dst] = 1'b1;
            io_exp[k][c_dst]       = seq_ctr;
          end
          io_last[k][c_dst] = seq_ctr;
          live_cnt = live_cnt + 1;
          if (amnesty.exists(c_tag)) amnesty.delete(c_tag);
        end
      end

      // ---- deliveries ----
      for (int j = 0; j < N_OUT; j++) begin
        if (out_valid[j] && out_ready[j]) begin
          xfer_per_out[j] = xfer_per_out[j] + 1;
          c_tag = out_data[j*DW +: DW];
          c_idx = out_idx [j*IW +: IW];
          if (amnesty.exists(c_tag)) begin
            amnesty.delete(c_tag);          // murky reset-boundary case: forgive
          end else if (tag_out.exists(c_tag)) begin
            if (tag_out[c_tag] != j)
              fail("R1: beat delivered on the wrong output");
            if (tag_src[c_tag] != c_idx)
              fail("R3: out_idx does not name the input the beat came from");
            c_src = tag_src[c_tag];
            c_seq = tag_seq[c_tag];
            if (!io_exp_valid[c_src][j] || io_exp[c_src][j] != c_seq)
              fail("R5: beats from one input to one output delivered out of order");
            if (tag_next_seq.exists(c_seq)) begin
              io_exp[c_src][j] = tag_next_seq[c_seq];
              tag_next_seq.delete(c_seq);
            end else begin
              io_exp_valid[c_src][j] = 1'b0;
            end
            tag_out.delete(c_tag);
            tag_src.delete(c_tag);
            tag_seq.delete(c_tag);
            tag_done[c_tag] = 1'b1;
            live_cnt = live_cnt - 1;
          end else if (tag_done.exists(c_tag)) begin
            fail("R4: beat delivered more than once");
          end else begin
            fail("R6: delivered beat matches no accepted beat (fabricated beat, modified payload (R2), or stale beat held across reset (X2))");
          end

          // ---- A2: fairness window on this output ----
          if (fair_m[j] != 0) begin
            fhist[j][3] = fhist[j][2];
            fhist[j][2] = fhist[j][1];
            fhist[j][1] = fhist[j][0];
            fhist[j][0] = c_idx;
            if (fair_skip[j] > 0) begin
              fair_skip[j] = fair_skip[j] - 1;
            end else begin
              c_cov = 0;
              for (int i = 0; i < fair_sz[j]; i++)
                c_cov = c_cov | (1 << fhist[j][i]);
              if ((c_cov & fair_m[j]) != fair_m[j])
                fail("A2: a continuously offering input was not served within the fairness window");
            end
          end
        end
      end

      // ---- X3: liveness bound on acceptance ----
      for (int k = 0; k < N_IN; k++) begin
        if (in_valid[k] && in_ready[k]) begin
          x3_cnt[k]  = 0;
          x3_cont[k] = 1'b1;
        end else if (in_valid[k]) begin
          c_sel = in_sel[k*SW +: SW];
          if (out_ready[c_sel]) begin
            if (x3_cont[k]) begin
              x3_cnt[k] = x3_cnt[k] + 1;
              if (x3_cnt[k] >= 32)
                fail("X3: offered beat not accepted within 32 cycles although its bound output was continuously ready");
            end
          end else begin
            x3_cont[k] = 1'b0;   // readiness continuity broken: bound not applicable
          end
        end else begin
          x3_cnt[k]  = 0;
          x3_cont[k] = 1'b1;
        end
      end

      pv_valid <= out_valid;
      pv_ready <= out_ready;
      pv_data  <= out_data;
      pv_idx   <= out_idx;
    end

    settled <= (live_cnt == 0 && out_valid == '0 && in_valid == '0) ? (settled + 1) : 0;
  end

  // ---------------------------------------------------------------------------
  // STIMULUS HELPERS
  // ---------------------------------------------------------------------------
  task automatic offer_beat(input int k, input int dst);
    begin
      @(negedge clk);
      feed_en[k]     = 1'b0;
      single_shot[k] = 1'b1;
      bfm_next_data[k] = tag_ctr;
      tag_ctr = tag_ctr + 1;
      bfm_next_sel[k] = dst;
      bfm_offer[k] = 1'b1;
    end
  endtask

  task automatic send_one(input int k, input int dst);
    begin
      automatic int w = 0;
      automatic bit got = 0;
      offer_beat(k, dst);
      while (w < 300 && !got) begin
        @(negedge clk);
        w = w + 1;
        if (bfm_accepted[k]) got = 1'b1;
      end
      if (!got)
        fail("liveness: an offered beat was never accepted although its output was ready (X3)");
    end
  endtask

  task automatic str_start(input int k, input int dst);
    begin
      @(negedge clk);
      single_shot[k] = 1'b0;
      feed_cnt[k] = 0;
      feed_dst[k] = dst;
      bfm_next_data[k] = tag_ctr;
      tag_ctr = tag_ctr + 1;
      if (feed_mode == 0) bfm_next_sel[k] = dst;
      else                bfm_next_sel[k] = k % N_OUT;
      bfm_offer[k] = 1'b1;
      feed_en[k]   = 1'b1;
    end
  endtask

  task automatic str_stop(input int k);
    begin
      @(negedge clk);
      feed_en[k]   = 1'b0;
      bfm_offer[k] = 1'b0;
    end
  endtask

  task automatic fair_begin(input int j, input int m, input int sz);
    begin
      @(negedge clk);
      fair_m[j]    = m;
      fair_sz[j]   = sz;
      fair_skip[j] = 2 * sz;
      for (int i = 0; i < 4; i++) fhist[j][i] = 0;
    end
  endtask

  task automatic fair_end(input int j);
    begin
      @(negedge clk);
      fair_m[j] = 0;
    end
  endtask

  task automatic wait_for_acc(input int n, input int tmo);
    begin
      automatic int base = 0;
      automatic int w = 0;
      @(negedge clk);
      base = acc_total;
      while (acc_total < base + n) begin
        @(negedge clk);
        w = w + 1;
        if (w > tmo)
          fail("liveness: expected input acceptances did not occur (X3)");
      end
    end
  endtask

  task automatic wait_for_xfer(input int j, input int n, input int tmo);
    begin
      automatic int base = 0;
      automatic int w = 0;
      @(negedge clk);
      base = xfer_per_out[j];
      while (xfer_per_out[j] < base + n) begin
        @(negedge clk);
        w = w + 1;
        if (w > tmo)
          fail("liveness: expected output transfers did not occur (X3/A2/R4)");
      end
    end
  endtask

  task automatic xbar_drain(input int tmo);
    begin
      automatic int w = 0;
      ready_cmd = '1;
      @(negedge clk);
      while (settled < 2) begin
        @(negedge clk);
        w = w + 1;
        if (w > tmo) begin
          if (live_cnt > 0)
            fail("R4: an accepted beat was never delivered (lost)");
          else
            fail("liveness: traffic did not drain (offer never accepted or delivery stuck: X3/R4)");
        end
      end
    end
  endtask

  task automatic post_reset_quiet(input int cycles);
    begin
      automatic int i2 = 0;
      ready_cmd = '1;
      while (i2 < cycles) begin
        @(posedge clk);
        if (in_valid == '0 && out_valid != '0)
          fail("X2: out_valid asserted after reset with no beat owed (stale state held across reset)");
        i2 = i2 + 1;
      end
    end
  endtask

  // ---------------------------------------------------------------------------
  // STIMULUS
  // ---------------------------------------------------------------------------
  initial begin : stim
    int a1, a2, a3, x1, x2, x3;

    phase_name = "init";
    tag_ctr = 1;
    seq_ctr = 0;
    live_cnt = 0;
    settled = 0;
    rst_active_seen = 1'b0;
    acc_total = 0;
    feed_mode = 0;
    ready_cmd = '1;
    for (int k = 0; k < N_IN; k++) begin
      acc_per_in[k] = 0; x3_cnt[k] = 0; x3_cont[k] = 1'b1;
      feed_en[k] = 1'b0; single_shot[k] = 1'b0;
      feed_cnt[k] = 0; feed_dst[k] = 0;
    end
    for (int j = 0; j < N_OUT; j++) begin
      xfer_per_out[j] = 0; fair_m[j] = 0; fair_sz[j] = 0; fair_skip[j] = 0;
      for (int i = 0; i < 4; i++) fhist[j][i] = 0;
    end
    for (int k = 0; k < N_IN; k++)
      for (int j = 0; j < N_OUT; j++)
        io_exp_valid[k][j] = 1'b0;

    // ---- P0: reset, then quiet (X1 checked by the always block, X2 here) ----
    phase_name = "P0-reset";
    bfm_reset(5);
    post_reset_quiet(8);

    // ---- P1: basic routing, one beat at a time (R1/R2/R3/R6 smoke) ----
    phase_name = "P1-basic";
    for (int k = 0; k < N_IN; k++) begin
      send_one(k, k);
      send_one(k, (k + 1) % N_OUT);
    end
    xbar_drain(300);

    // ---- P2: parallel streams to distinct outputs ----
    phase_name = "P2-parallel";
    for (int k = 0; k < N_IN; k++) str_start(k, k);
    wait_for_acc(48, 400);
    for (int k = 0; k < N_IN; k++) str_stop(k);
    xbar_drain(400);

    // ---- P3: fairness |S|=4 (all inputs continuously offer to output 0) ----
    phase_name = "P3-fair4";
    fair_begin(0, 4'b1111, 4);
    for (int k = 0; k < N_IN; k++) str_start(k, 0);
    wait_for_xfer(0, 24, 500);
    fair_end(0);
    for (int k = 0; k < N_IN; k++) str_stop(k);
    xbar_drain(400);

    // ---- P4: fairness |S|=2 (inputs 0,1 -> output 2) ----
    phase_name = "P4-fair2";
    fair_begin(2, 4'b0011, 2);
    str_start(0, 2);
    str_start(1, 2);
    wait_for_xfer(2, 16, 500);
    fair_end(2);
    str_stop(0);
    str_stop(1);
    xbar_drain(400);

    // ---- P5: fairness |S|=3 (inputs 1,2,3 -> output 1) ----
    phase_name = "P5-fair3";
    fair_begin(1, 4'b1110, 3);
    str_start(1, 1);
    str_start(2, 1);
    str_start(3, 1);
    wait_for_xfer(1, 20, 500);
    fair_end(1);
    str_stop(1);
    str_stop(2);
    str_stop(3);
    xbar_drain(400);

    // ---- P6: I1/I2 (output 0 unready while everything else flows) ----
    phase_name = "P6-independence";
    @(negedge clk);
    ready_cmd = 4'b1110;
    str_start(0, 0);   // bound to the unready output
    str_start(1, 1);
    str_start(2, 2);
    str_start(3, 3);
    @(negedge clk);
    a1 = acc_per_in[1]; a2 = acc_per_in[2]; a3 = acc_per_in[3];
    x1 = xfer_per_out[1]; x2 = xfer_per_out[2]; x3 = xfer_per_out[3];
    repeat (100) @(negedge clk);
    if (acc_per_in[1] == a1 || acc_per_in[2] == a2 || acc_per_in[3] == a3)
      fail("I2: an input was not accepted while another input's bound output was unready (head-of-line blocking across inputs)");
    if (xfer_per_out[1] == x1 || xfer_per_out[2] == x2 || xfer_per_out[3] == x3)
      fail("I1: a ready output made no transfer while another output was unready");
    for (int k = 0; k < N_IN; k++) str_stop(k);
    xbar_drain(800);

    // ---- P6b: A3 re-aim (stalled outputs, second contender joins) ----
    phase_name = "P6b-reaim";
    @(negedge clk);
    ready_cmd = '0;
    offer_beat(0, 1);
    offer_beat(1, 2);
    repeat (5) @(negedge clk);
    offer_beat(2, 1);   // contender for the already-offered output 1
    offer_beat(3, 2);   // contender for the already-offered output 2
    repeat (20) @(negedge clk);
    xbar_drain(400);

    // ---- P7: ready toggling (A3 under repeated stalls) ----
    phase_name = "P7-toggle";
    for (int k = 0; k < N_IN; k++) str_start(k, k);
    for (int p = 0; p < 10; p++) begin
      @(negedge clk);
      case (p % 5)
        0:       ready_cmd = 4'b1110;
        1:       ready_cmd = 4'b0011;
        2:       ready_cmd = 4'b1101;
        3:       ready_cmd = 4'b1011;
        default: ready_cmd = 4'b0000;
      endcase
      repeat (5) @(negedge clk);
    end
    for (int k = 0; k < N_IN; k++) str_stop(k);
    xbar_drain(800);

    // ---- P8: rotating destinations (contention + R5 across bindings) ----
    phase_name = "P8-rotate";
    feed_mode = 1;
    for (int k = 0; k < N_IN; k++) str_start(k, 0);
    wait_for_acc(80, 600);
    for (int k = 0; k < N_IN; k++) str_stop(k);
    xbar_drain(600);
    feed_mode = 0;

    // ---- P9: mid-run reset with a pending beat on a stalled output ----
    phase_name = "P9-reset";
    xbar_drain(300);
    @(negedge clk);
    ready_cmd = 4'b1100;      // outputs 0 and 1 unready
    offer_beat(0, 0);
    offer_beat(1, 1);
    repeat (24) @(negedge clk);  // let a buffered design accept them
    bfm_offer   = '0;          // withdraw in the same breath as reset
    single_shot = '0;
    rst_n       = 1'b0;
    repeat (4) @(posedge clk); // X1 is checked by the always block here
    @(negedge clk);
    rst_n = 1'b1;
    post_reset_quiet(10);      // X2: no stale beat after release
    for (int k = 0; k < N_IN; k++) send_one(k, (k + 1) % N_OUT);
    xbar_drain(300);

    // ---- P10: final crossed traffic ----
    phase_name = "P10-final";
    for (int k = 0; k < N_IN; k++) str_start(k, (k + 2) % N_OUT);
    wait_for_acc(32, 400);
    for (int k = 0; k < N_IN; k++) str_stop(k);
    xbar_drain(600);

    if (live_cnt != 0)
      fail("R4: accepted beats left undelivered at end of test");

    $display("RESULT: PASS");
    $finish;
  end

endmodule
