// Non-equivalence witness harness -- rule 16. Scoring support, never shipped.
//
// Drives the golden and ONE mutant from the SAME input sequence and compares
// the ENTIRE output vector every cycle. Every output of this module is
// meaningful on every cycle -- there is no valid to qualify against -- so the
// comparison is the whole vector, not a chosen subset.
//
// Build once per mutant:  -DMUT_MOD=pt_mN_...
`ifndef MUT_MOD
  `define MUT_MOD pt_m1_drift_period_off_by_one
`endif

module nonequiv_tb;
  logic clk = 1'b0; always #5 clk = ~clk;
  logic rst = 1'b1;
  logic [95:0] set96 = '0; logic set96_v = 1'b0;
  logic [63:0] set64 = '0; logic set64_v = 1'b0;
  logic [3:0]  per_ns = '0; logic [15:0] per_fns = '0; logic per_v = 1'b0;
  logic [3:0]  adj_ns = '0; logic [15:0] adj_fns = '0; logic [15:0] adj_cnt = '0;
  logic        adj_v = 1'b0;
  logic [3:0]  dr_ns = '0; logic [15:0] dr_fns = '0; logic [15:0] dr_rate = '0;
  logic        dr_v = 1'b0;

  `define OUTS(p) logic [95:0] p``_ts96; logic [63:0] p``_ts64; \
                  logic p``_step, p``_pps, p``_adja;
  `OUTS(g)
  `OUTS(m)

  `define CONN(p) \
    .clk_i(clk), .rst_i(rst), \
    .set_ts96_i(set96), .set_ts96_valid_i(set96_v), \
    .set_ts64_i(set64), .set_ts64_valid_i(set64_v), \
    .period_ns_i(per_ns), .period_fns_i(per_fns), .period_valid_i(per_v), \
    .adj_ns_i(adj_ns), .adj_fns_i(adj_fns), .adj_count_i(adj_cnt), \
    .adj_valid_i(adj_v), .adj_active_o(p``_adja), \
    .drift_ns_i(dr_ns), .drift_fns_i(dr_fns), .drift_rate_i(dr_rate), \
    .drift_valid_i(dr_v), \
    .ts96_o(p``_ts96), .ts64_o(p``_ts64), .ts_step_o(p``_step), .pps_o(p``_pps)

  ptp_time_base i_g (`CONN(g));
  `MUT_MOD      i_m (`CONN(m));

  int cyc = 0;
  always @(posedge clk) if (!rst) cyc <= cyc + 1;

  int    diff_cyc = -1;
  string diff_what = "";
  always @(posedge clk) if (!rst && diff_cyc < 0) begin
    if ({g_ts96, g_ts64, g_step, g_pps, g_adja} !== {m_ts96, m_ts64, m_step, m_pps, m_adja}) begin
      diff_cyc = cyc;
      if (g_pps !== m_pps)
        diff_what = $sformatf("pps_o: golden %b / mutant %b", g_pps, m_pps);
      else if (g_adja !== m_adja)
        diff_what = $sformatf("adj_active_o: golden %b / mutant %b", g_adja, m_adja);
      else if (g_step !== m_step)
        diff_what = $sformatf("ts_step_o: golden %b / mutant %b", g_step, m_step);
      else if (g_ts96[95:48] !== m_ts96[95:48])
        diff_what = $sformatf("ts96 SECONDS: golden %0d / mutant %0d", g_ts96[95:48], m_ts96[95:48]);
      else if (g_ts96[45:16] !== m_ts96[45:16])
        diff_what = $sformatf("ts96 ns: golden %0d / mutant %0d (delta %0d)",
                              g_ts96[45:16], m_ts96[45:16],
                              $signed({1'b0,m_ts96[45:16]} - {1'b0,g_ts96[45:16]}));
      else if (g_ts96[15:0] !== m_ts96[15:0])
        diff_what = $sformatf("ts96 fns: golden %0d / mutant %0d (delta %0d fns)",
                              g_ts96[15:0], m_ts96[15:0],
                              $signed({1'b0,m_ts96[15:0]} - {1'b0,g_ts96[15:0]}));
      else if (g_ts64 !== m_ts64)
        diff_what = $sformatf("ts64: golden %0d / mutant %0d (delta %0d fns)",
                              g_ts64, m_ts64, $signed(m_ts64 - g_ts64));
      else diff_what = "some other output bit";
    end
  end

  task automatic step(input int n); repeat (n) @(posedge clk); endtask

  initial begin
    repeat (5) @(posedge clk);
    @(negedge clk) rst = 1'b0;
    step(20);                                   // nominal running

    // a new period
    @(negedge clk); per_ns = 4'd8; per_fns = 16'h1000; per_v = 1'b1;
    @(negedge clk) per_v = 1'b0;
    step(20);

    // a POSITIVE counted offset adjustment
    @(negedge clk); adj_ns = 4'h0; adj_fns = 16'd700; adj_cnt = 16'd6; adj_v = 1'b1;
    @(negedge clk) adj_v = 1'b0;
    step(20);

    // a NEGATIVE counted offset adjustment
    @(negedge clk); adj_ns = 4'hF; adj_fns = 16'hF830; adj_cnt = 16'd5; adj_v = 1'b1;
    @(negedge clk) adj_v = 1'b0;
    step(20);

    // a different drift rate
    @(negedge clk); dr_ns = 4'h0; dr_fns = 16'd48; dr_rate = 16'd3; dr_v = 1'b1;
    @(negedge clk) dr_v = 1'b0;
    step(40);

    // set the 64-bit base
    @(negedge clk); set64 = 64'd5555 << 16; set64_v = 1'b1;
    @(negedge clk) set64_v = 1'b0;
    step(10);

    // walk the 96-bit base up to the one-second wrap
    @(negedge clk); set96 = {48'd11, 2'b00, 30'd999_999_800, 16'd0}; set96_v = 1'b1;
    @(negedge clk) set96_v = 1'b0;
    step(60);

    // a LONG counted offset adjustment. The guarded set distinguishes long
    // adjustments from short ones at adj_count_i >= 8; every adjustment above
    // is shorter than that, so a defect conditioned on length stays invisible.
    @(negedge clk); adj_ns = 4'h0; adj_fns = 16'd400; adj_cnt = 16'd12; adj_v = 1'b1;
    @(negedge clk) adj_v = 1'b0;
    step(30);

    // TWO FURTHER one-second wraps. One wrap does not discriminate a defect
    // that only appears on later wraps -- pps_o stretching on the third wrap
    // looks exactly like correct behaviour if only the first is ever reached.
    @(negedge clk); set96 = {48'd12, 2'b00, 30'd999_999_800, 16'd0}; set96_v = 1'b1;
    @(negedge clk) set96_v = 1'b0;
    step(60);
    @(negedge clk); set96 = {48'd13, 2'b00, 30'd999_999_800, 16'd0}; set96_v = 1'b1;
    @(negedge clk) set96_v = 1'b0;
    step(60);

    // reset after programming a non-default period
    @(negedge clk); per_ns = 4'd9; per_fns = 16'h2000; per_v = 1'b1;
    @(negedge clk) per_v = 1'b0;
    step(6);
    @(negedge clk) rst = 1'b1;
    step(4);
    @(negedge clk) rst = 1'b0;
    step(40);

    if (diff_cyc >= 0)
      $display("WITNESS %s: first difference at cycle %0d -- %s", `"`MUT_MOD`", diff_cyc, diff_what);
    else
      $display("WITNESS %s: NO DIFFERENCE OBSERVED -- treat the HARNESS as suspect, not the mutant",
               `"`MUT_MOD`");
    $finish;
  end
  initial begin #200000; $display("WITNESS %s: watchdog, diff_cyc=%0d", `"`MUT_MOD`", diff_cyc); $finish; end
endmodule
