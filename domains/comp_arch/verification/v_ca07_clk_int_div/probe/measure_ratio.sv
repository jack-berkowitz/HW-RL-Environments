// STEP 1 -- semantic confirmation, MEASURED not read.
//
// Correctness here is about INTERVALS BETWEEN EDGES, not sampled values, so the
// probe measures in units of clk_i cycles: it samples clk_o at the negedge of
// clk_i (a stable point) and records the cycle number of every transition.
// Sampling clk_o as a value would see nothing that matters.
module ratio_probe;
  logic clk=0, rst_n=0; always #5 clk=~clk;
  logic en=1, tm=0, div_valid=0; logic [3:0] div=0;
  logic div_ready, clk_o; logic [3:0] cyc_cnt;
  clk_ratio_div dut(.clk_i(clk), .rst_ni(rst_n), .en_i(en), .test_mode_en_i(tm),
                    .div_i(div), .div_valid_i(div_valid), .div_ready_o(div_ready),
                    .clk_o(clk_o), .cycl_count_o(cyc_cnt));

  // EDGES ARE RECORDED DIRECTLY, not sampled.
  //
  // The first version of this probe sampled clk_o at the negedge of clk_i. That
  // aliases the whole pass-through case: when clk_o IS clk_i, it is low at every
  // negedge of clk_i, so the probe saw no rising edges and reported "no output
  // clock" for div=0 and div=1 -- which the anchor's own header says are
  // pass-through. A sampled measurement of a clock measures the sampling phase.
  int cyc = 0;
  always @(negedge clk) cyc++;
  int rise[$], fall[$];
  always @(posedge clk_o) if (rst_n) rise.push_back($time);
  always @(negedge clk_o) if (rst_n) fall.push_back($time);

  task automatic clear_edges(); rise.delete(); fall.delete(); endtask

  // report the period and the high/low split, in clk_i cycles
  task automatic report(input string label);
    int p1, p2, hi, lo;
    if (rise.size() < 3) begin
      $display("  %-30s NO OUTPUT CLOCK (%0d rising edges in the window)", label, rise.size());
      return;
    end
    p1 = (rise[1] - rise[0]) / 10;
    p2 = (rise[2] - rise[1]) / 10;
    hi = -1; lo = -1;
    foreach (fall[i]) if (fall[i] > rise[0] && hi < 0) begin
      hi = (fall[i] - rise[0]) / 10; lo = p1 - hi;
    end
    $display("  %-30s period=%0d,%0d clk_i   high=%0d low=%0d   duty=%0d%%   (%0d rises)",
             label, p1, p2, hi, lo, (p1>0) ? (hi*100)/p1 : 0, rise.size());
  endtask

  // set a divisor and report how the handshake and the gating behave
  task automatic set_div(input string label, input int d, input bit expect_same);
    int t, t_ready, gate_start, gate_len, last_rise_before;
    last_rise_before = (rise.size() > 0) ? rise[rise.size()-1] : -1;
    @(negedge clk); div = 4'(d); div_valid = 1;
    t_ready = -1;
    for (t = 0; t < 200; t++) begin
      @(posedge clk);
      if (div_ready) begin t_ready = t; break; end
    end
    @(negedge clk) div_valid = 0;
    clear_edges();
    repeat (160) @(posedge clk);
    $display("  set div=%-2d %-18s ready after %0d clk_i cycle(s); %0d output edge(s) in the next 160",
             d, label, t_ready, rise.size());
  endtask

  initial begin
    repeat (4) @(posedge clk); @(negedge clk) rst_n = 1; repeat (2) @(posedge clk);

    $display("== (A) the divisor ladder: period and duty, in clk_i cycles ==");
    for (int d = 0; d <= 8; d++) begin
      @(negedge clk); div = 4'(d); div_valid = 1;
      for (int t = 0; t < 200; t++) begin @(posedge clk); if (div_ready) break; end
      @(negedge clk) div_valid = 0;
      repeat (80) @(posedge clk);          // let the change settle
      clear_edges();
      repeat (120) @(posedge clk);
      report($sformatf("div=%0d", d));
    end

    $display("");
    $display("== (B) the handshake and the gating on a CHANGE ==");
    // walk to a known value first
    @(negedge clk); div = 4'd2; div_valid = 1;
    for (int t = 0; t < 200; t++) begin @(posedge clk); if (div_ready) break; end
    @(negedge clk) div_valid = 0; repeat (80) @(posedge clk);
    set_div("(2 -> 4, a change)",  4, 1'b0);
    set_div("(4 -> 4, SAME value)", 4, 1'b1);
    set_div("(4 -> 3, a change)",  3, 1'b0);
    set_div("(3 -> 3, SAME value)", 3, 1'b1);

    $display("");
    $display("== (C) en_i, and reset ==");
    @(negedge clk); div = 4'd4; div_valid = 1;
    for (int t = 0; t < 200; t++) begin @(posedge clk); if (div_ready) break; end
    @(negedge clk) div_valid = 0; repeat (60) @(posedge clk);
    clear_edges(); repeat (100) @(posedge clk);
    $display("  en=1: %0d rising edge(s) in 100 cycles", rise.size());
    @(negedge clk) en = 0;
    clear_edges(); repeat (100) @(posedge clk);
    $display("  en=0: %0d rising edge(s) in 100 cycles", rise.size());
    @(negedge clk) en = 1;
    clear_edges(); repeat (100) @(posedge clk);
    $display("  en back to 1: %0d rising edge(s) in 100 cycles", rise.size());
    @(negedge clk) rst_n = 0;
    clear_edges(); repeat (40) @(posedge clk);
    $display("  during reset: %0d rising edge(s) in 40 cycles", rise.size());
    @(negedge clk) rst_n = 1;
    clear_edges(); repeat (100) @(posedge clk);
    report("after reset (divisor?)");
    $finish;
  end
  initial begin #500000; $display("PROBE watchdog"); $finish; end
endmodule
