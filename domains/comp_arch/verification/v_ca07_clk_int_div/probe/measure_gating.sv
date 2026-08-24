// The gating bound, measured FROM THE ACCEPTANCE EDGE so the handshake wait is
// not folded into it, across every ordered pair of divisors in 0..8.
module gate3;
  logic clk=0, rst_n=0; always #5 clk=~clk;
  logic en=1, tm=0, div_valid=0; logic [3:0] div=0;
  logic div_ready, clk_o; logic [3:0] cyc_cnt;
  clk_ratio_div dut(.clk_i(clk), .rst_ni(rst_n), .en_i(en), .test_mode_en_i(tm),
                    .div_i(div), .div_valid_i(div_valid), .div_ready_o(div_ready),
                    .clk_o(clk_o), .cycl_count_o(cyc_cnt));
  int cyc=0; always @(negedge clk) cyc++;
  int rise[$];
  always @(posedge clk_o) if (rst_n) rise.push_back(cyc);

  function automatic int per(input int d); return (d < 2) ? 1 : d; endfunction

  task automatic settle(input int d);
    @(negedge clk); div = 4'(d); div_valid = 1;
    for (int t=0;t<300;t++) begin @(posedge clk); if (div_ready) break; end
    @(negedge clk) div_valid = 0;
    repeat (120) @(posedge clk);
  endtask

  int worst = 0; int worst_from, worst_to;
  task automatic one(input int a, input int b, input bit show);
    int accept_cyc, first_after, gap;
    settle(a);
    @(negedge clk); div = 4'(b); div_valid = 1;
    accept_cyc = -1;
    for (int t=0;t<300;t++) begin @(posedge clk); if (div_ready) begin accept_cyc = cyc; break; end end
    @(negedge clk) div_valid = 0;
    rise.delete();
    repeat (140) @(posedge clk);
    first_after = (rise.size()>0) ? rise[0] : -1;
    gap = (first_after>0 && accept_cyc>0) ? (first_after - accept_cyc) : -1;
    if (gap > worst) begin worst = gap; worst_from = a; worst_to = b; end
    // check the HEADER'S bound on every pair, and report only what breaks it
    if (gap > 3*per(b))
      $display("  VIOLATION  %2d -> %-2d  gap %2d  >  3x new period %2d", a, b, gap, 3*per(b));
    if (gap == 3*per(b))
      $display("  tight      %2d -> %-2d  gap %2d  =  3x new period %2d", a, b, gap, 3*per(b));
  endtask

  initial begin
    repeat (4) @(posedge clk); @(negedge clk) rst_n = 1; repeat (2) @(posedge clk);
    $display("== bound check: gap-from-accept vs 3x new period, all 72 ordered pairs ==");
    for (int a = 0; a <= 8; a++)
      for (int b = 0; b <= 8; b++)
        if (a != b) one(a, b, 1'b1);
    $display("");
    $display("  WORST observed gap over all 72 ordered pairs: %0d clk_i cycles (%0d -> %0d)",
             worst, worst_from, worst_to);
    $display("  (only VIOLATION and tight lines are printed above; silence means slack)");
    $finish;
  end
  initial begin #4000000; $display("watchdog"); $finish; end
endmodule
