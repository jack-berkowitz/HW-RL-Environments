// The remaining questions, before any of them becomes a clause.
module rest_probe;
  logic clk=0, rst_n=0; always #5 clk=~clk;
  logic en=1, tm=0, div_valid=0; logic [3:0] div=0;
  logic div_ready, clk_o; logic [3:0] cyc_cnt;
  clk_ratio_div dut(.clk_i(clk), .rst_ni(rst_n), .en_i(en), .test_mode_en_i(tm),
                    .div_i(div), .div_valid_i(div_valid), .div_ready_o(div_ready),
                    .clk_o(clk_o), .cycl_count_o(cyc_cnt));
  task automatic settle(input int d);
    @(negedge clk); div=4'(d); div_valid=1;
    for (int t=0;t<300;t++) begin @(posedge clk); if (div_ready) break; end
    @(negedge clk) div_valid=0; repeat (100) @(posedge clk);
  endtask
  initial begin
    repeat(4) @(posedge clk); @(negedge clk) rst_n=1; repeat(2) @(posedge clk);

    $display("== (1) is a SECOND change accepted while the first is still gating? ==");
    settle(2);
    begin int r1=-1, r2=-1;
      @(negedge clk); div=4'd8; div_valid=1;
      for (int t=0;t<300;t++) begin @(posedge clk); if (div_ready) begin r1=t; break; end end
      @(negedge clk) div_valid=0;
      // immediately request another, while the first should still be gating
      @(negedge clk); div=4'd3; div_valid=1;
      for (int t=0;t<40;t++) begin @(posedge clk); if (div_ready) begin r2=t; break; end end
      @(negedge clk) div_valid=0;
      $display("  first change accepted after %0d; SECOND accepted after %0d (-1 = refused within 40)", r1, r2);
      repeat (120) @(posedge clk);
    end

    $display("== (2) cycl_count_o during pass-through and while gating ==");
    settle(0);
    begin string s="";
      for (int t=0;t<8;t++) begin @(posedge clk); s={s,$sformatf("%0d ",cyc_cnt)}; end
      $display("  div=0 (pass-through): %s", s);
    end
    settle(4);
    begin string s="";
      @(negedge clk); div=4'd8; div_valid=1;
      for (int t=0;t<300;t++) begin @(posedge clk); if (div_ready) break; end
      @(negedge clk) div_valid=0;
      for (int t=0;t<14;t++) begin @(posedge clk); s={s,$sformatf("%0d ",cyc_cnt)}; end
      $display("  across a 4->8 change:  %s", s);
    end
    repeat (60) @(posedge clk);

    $display("== (3) does en_i=0 cut a pulse short, or gate cleanly? ==");
    settle(4);
    begin
      int hi=0, lo=0; logic prev;
      // drop en at a random-ish phase and look for a short high pulse
      @(posedge clk); @(posedge clk); @(negedge clk) en=0;
      prev = clk_o;
      for (int t=0;t<40;t++) begin
        @(posedge clk);
        if (clk_o) hi++; else lo++;
      end
      $display("  after en=0: clk_o high on %0d of 40 input edges, low on %0d", hi, lo);
      @(negedge clk) en=1; repeat (40) @(posedge clk);
    end

    $display("== (4) div_i changed while div_valid_i is HELD high ==");
    settle(2);
    begin int n0, n1;
      @(negedge clk); div=4'd4; div_valid=1;          // hold valid, change div
      repeat (60) @(posedge clk);
      n0 = 0; for (int t=0;t<80;t++) begin @(posedge clk); if (clk_o) n0++; end
      @(negedge clk); div=4'd8;                        // change div, valid still high
      repeat (60) @(posedge clk);
      n1 = 0; for (int t=0;t<80;t++) begin @(posedge clk); if (clk_o) n1++; end
      @(negedge clk) div_valid=0;
      $display("  valid held high: high-samples at div=4 -> %0d, after switching to div=8 -> %0d", n0, n1);
    end
    $finish;
  end
  initial begin #900000; $display("watchdog"); $finish; end
endmodule
