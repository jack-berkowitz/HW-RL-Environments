module ptp_time_base_tb;

  // ---------------------------------------------------------------------------
  // PROVIDED PLUMBING -- drives the module, checks nothing.
  // ---------------------------------------------------------------------------
  logic clk = 1'b0;
  always #5 clk = ~clk;

  int bfm_cycle = 0;
  always @(posedge clk) if (!rst) bfm_cycle <= bfm_cycle + 1;

  logic rst = 1'b1;

  task automatic bfm_reset(input int cycles = 5);
    @(negedge clk);
    rst = 1'b1;
    repeat (cycles) @(posedge clk);
    @(negedge clk);
    rst = 1'b0;
  endtask

  logic [95:0] set_ts96;   logic set_ts96_valid;
  logic [63:0] set_ts64;   logic set_ts64_valid;
  logic [3:0]  period_ns;  logic [15:0] period_fns; logic period_valid;
  logic [3:0]  adj_ns;     logic [15:0] adj_fns;    logic [15:0] adj_count;
  logic        adj_valid;  logic adj_active;
  logic [3:0]  drift_ns;   logic [15:0] drift_fns;  logic [15:0] drift_rate;
  logic        drift_valid;
  logic [95:0] ts96;       logic [63:0] ts64;
  logic        ts_step,    pps;

  ptp_time_base dut (
    .clk_i(clk), .rst_i(rst),
    .set_ts96_i(set_ts96), .set_ts96_valid_i(set_ts96_valid),
    .set_ts64_i(set_ts64), .set_ts64_valid_i(set_ts64_valid),
    .period_ns_i(period_ns), .period_fns_i(period_fns), .period_valid_i(period_valid),
    .adj_ns_i(adj_ns), .adj_fns_i(adj_fns), .adj_count_i(adj_count),
    .adj_valid_i(adj_valid), .adj_active_o(adj_active),
    .drift_ns_i(drift_ns), .drift_fns_i(drift_fns), .drift_rate_i(drift_rate),
    .drift_valid_i(drift_valid),
    .ts96_o(ts96), .ts64_o(ts64), .ts_step_o(ts_step), .pps_o(pps));

  task automatic bfm_period(input logic [3:0] ns, input logic [15:0] fns);
    @(negedge clk); period_ns = ns; period_fns = fns; period_valid = 1'b1;
    @(negedge clk); period_valid = 1'b0;
  endtask

  task automatic bfm_adjust(input logic [3:0] ns, input logic [15:0] fns,
                            input logic [15:0] count);
    @(negedge clk); adj_ns = ns; adj_fns = fns; adj_count = count; adj_valid = 1'b1;
    @(negedge clk); adj_valid = 1'b0;
  endtask

  task automatic bfm_drift(input logic [3:0] ns, input logic [15:0] fns,
                           input logic [15:0] rate);
    @(negedge clk); drift_ns = ns; drift_fns = fns; drift_rate = rate; drift_valid = 1'b1;
    @(negedge clk); drift_valid = 1'b0;
  endtask

  task automatic bfm_set96(input logic [47:0] sec, input logic [29:0] ns,
                           input logic [15:0] fns);
    @(negedge clk); set_ts96 = {sec, 2'b00, ns, fns}; set_ts96_valid = 1'b1;
    @(negedge clk); set_ts96_valid = 1'b0;
  endtask

  task automatic bfm_set64(input logic [47:0] ns, input logic [15:0] fns);
    @(negedge clk); set_ts64 = {ns, fns}; set_ts64_valid = 1'b1;
    @(negedge clk); set_ts64_valid = 1'b0;
  endtask

  task automatic bfm_wait(input int cycles); repeat (cycles) @(posedge clk); endtask

  initial begin
    set_ts96 = '0; set_ts96_valid = 1'b0; set_ts64 = '0; set_ts64_valid = 1'b0;
    period_ns = '0; period_fns = '0; period_valid = 1'b0;
    adj_ns = '0; adj_fns = '0; adj_count = '0; adj_valid = 1'b0;
    drift_ns = '0; drift_fns = '0; drift_rate = '0; drift_valid = 1'b0;
  end

  initial begin
    #3_000_000;
    $display("RESULT: FAIL (watchdog: no verdict reached)");
    $finish;
  end

  // ---------------------------------------------------------------------------
  // Testbench bookkeeping
  // ---------------------------------------------------------------------------
  localparam longint ONE_SEC_FNS = 64'd1000000000 * 64'd65536;

  typedef struct {
    int cyc;
    logic rst;
    logic [95:0] ts96;
    logic [63:0] ts64;
    logic ts_step;
    logic pps;
    logic adj_active;
    logic sh_set96_valid;
    logic [95:0] sh_set96;
    logic sh_set64_valid;
    logic [63:0] sh_set64;
    logic sh_period_valid;
    logic [3:0] sh_period_ns;
    logic [15:0] sh_period_fns;
    logic sh_adj_valid;
    logic [3:0] sh_adj_ns;
    logic [15:0] sh_adj_fns;
    logic [15:0] sh_adj_count;
    logic sh_drift_valid;
    logic [3:0] sh_drift_ns;
    logic [15:0] sh_drift_fns;
    logic [15:0] sh_drift_rate;
  } rec_t;

  rec_t recs[$];
  int fail_count = 0;

  int cyc_num = 0;
  always @(posedge clk) begin
    if (rst) cyc_num <= 0;
    else cyc_num <= cyc_num + 1;
  end

  logic sh_set96_valid;
  logic [95:0] sh_set96;
  logic sh_set64_valid;
  logic [63:0] sh_set64;
  logic sh_period_valid;
  logic [3:0] sh_period_ns;
  logic [15:0] sh_period_fns;
  logic sh_adj_valid;
  logic [3:0] sh_adj_ns;
  logic [15:0] sh_adj_fns;
  logic [15:0] sh_adj_count;
  logic sh_drift_valid;
  logic [3:0] sh_drift_ns;
  logic [15:0] sh_drift_fns;
  logic [15:0] sh_drift_rate;

  always @(posedge clk) begin
    sh_set96_valid <= set_ts96_valid;
    sh_set96       <= set_ts96;
    sh_set64_valid <= set_ts64_valid;
    sh_set64       <= set_ts64;
    sh_period_valid <= period_valid;
    sh_period_ns    <= period_ns;
    sh_period_fns   <= period_fns;
    sh_adj_valid    <= adj_valid;
    sh_adj_ns       <= adj_ns;
    sh_adj_fns      <= adj_fns;
    sh_adj_count    <= adj_count;
    sh_drift_valid  <= drift_valid;
    sh_drift_ns     <= drift_ns;
    sh_drift_fns    <= drift_fns;
    sh_drift_rate   <= drift_rate;
  end

  always @(negedge clk) begin
    automatic rec_t r;
    r.cyc = cyc_num;
    r.rst = rst;
    r.ts96 = ts96;
    r.ts64 = ts64;
    r.ts_step = ts_step;
    r.pps = pps;
    r.adj_active = adj_active;
    r.sh_set96_valid = sh_set96_valid;
    r.sh_set96 = sh_set96;
    r.sh_set64_valid = sh_set64_valid;
    r.sh_set64 = sh_set64;
    r.sh_period_valid = sh_period_valid;
    r.sh_period_ns = sh_period_ns;
    r.sh_period_fns = sh_period_fns;
    r.sh_adj_valid = sh_adj_valid;
    r.sh_adj_ns = sh_adj_ns;
    r.sh_adj_fns = sh_adj_fns;
    r.sh_adj_count = sh_adj_count;
    r.sh_drift_valid = sh_drift_valid;
    r.sh_drift_ns = sh_drift_ns;
    r.sh_drift_fns = sh_drift_fns;
    r.sh_drift_rate = sh_drift_rate;
    recs.push_back(r);
  end

  // ---------------------------------------------------------------------------
  // Helper functions
  // ---------------------------------------------------------------------------
  function automatic longint ts96_total(input logic [95:0] v);
    longint sec, ns, fns;
    begin
      sec = v[95:48];
      ns  = v[45:16];
      fns = v[15:0];
      return (sec * 1000000000 + ns) * 65536 + fns;
    end
  endfunction

  function automatic longint ts64_total(input logic [63:0] v);
    longint ns, fns;
    begin
      ns  = v[63:16];
      fns = v[15:0];
      return ns * 65536 + fns;
    end
  endfunction

  function automatic longint get_delta(input int base, input int idx);
    if (base == 0)
      return ts96_total(recs[idx].ts96) - ts96_total(recs[idx-1].ts96);
    else
      return ts64_total(recs[idx].ts64) - ts64_total(recs[idx-1].ts64);
  endfunction

  function automatic int find_first_cycle(input int cyc);
    int i;
    for (i = 0; i < recs.size(); i++) begin
      if (recs[i].rst == 0 && recs[i].cyc == cyc) return i;
    end
    return -1;
  endfunction

  function automatic int find_period(input logic [3:0] ns, input logic [15:0] fns);
    int i;
    for (i = 0; i < recs.size(); i++) begin
      if (recs[i].sh_period_valid && recs[i].sh_period_ns == ns && recs[i].sh_period_fns == fns)
        return i;
    end
    return -1;
  endfunction

  function automatic int find_adj(input logic [3:0] ns, input logic [15:0] fns,
                                  input logic [15:0] count);
    int i;
    for (i = 0; i < recs.size(); i++) begin
      if (recs[i].sh_adj_valid && recs[i].sh_adj_ns == ns &&
          recs[i].sh_adj_fns == fns && recs[i].sh_adj_count == count)
        return i;
    end
    return -1;
  endfunction

  function automatic int find_set96_val(input logic [95:0] val);
    int i;
    for (i = 0; i < recs.size(); i++) begin
      if (recs[i].sh_set96_valid && recs[i].sh_set96 == val) return i;
    end
    return -1;
  endfunction

  function automatic int find_set64_val(input logic [63:0] val);
    int i;
    for (i = 0; i < recs.size(); i++) begin
      if (recs[i].sh_set64_valid && recs[i].sh_set64 == val) return i;
    end
    return -1;
  endfunction

  function automatic int find_drift_from(input logic [3:0] ns, input logic [15:0] fns,
                                         input logic [15:0] rate, input int start);
    int i;
    for (i = start; i < recs.size(); i++) begin
      if (recs[i].sh_drift_valid && recs[i].sh_drift_ns == ns &&
          recs[i].sh_drift_fns == fns && recs[i].sh_drift_rate == rate)
        return i;
    end
    return -1;
  endfunction

  // ---------------------------------------------------------------------------
  // Checking tasks
  // ---------------------------------------------------------------------------
  task automatic fail(input string clause, input string msg);
    begin
      $display("FAIL: %s - %s", clause, msg);
      fail_count++;
    end
  endtask

  task automatic check_drift_spacing(input int base, input int start_idx, input int end_idx,
                                     input longint base_inc, input longint drift_inc,
                                     input int rate, input string clause);
    int i, first_occ;
    longint d;
    begin
      if (end_idx <= start_idx) begin
        fail(clause, "drift window too short");
        return;
      end

      first_occ = -1;
      for (i = start_idx; i < start_idx + rate && i <= end_idx; i++) begin
        d = get_delta(base, i);
        if (d == base_inc + drift_inc) begin
          first_occ = i;
          break;
        end
      end

      if (first_occ == -1) begin
        fail(clause, "no drift occurrence in first rate window");
        return;
      end

      for (i = start_idx; i <= end_idx; i++) begin
        d = get_delta(base, i);
        if (i >= first_occ && ((i - first_occ) % rate == 0)) begin
          if (d != base_inc + drift_inc) begin
            fail(clause, $sformatf("expected drift at offset %0d, got delta %0d",
                                   i - start_idx, d));
            return;
          end
        end else begin
          if (d != base_inc) begin
            fail(clause, $sformatf("unexpected delta %0d at offset %0d",
                                   d, i - start_idx));
            return;
          end
        end
      end
    end
  endtask

  task automatic check_period_both(input int valid_idx, input int start_off, input int num,
                                   input longint period, input string clause);
    int base, k;
    longint d;
    begin
      for (base = 0; base < 2; base++) begin
        for (k = start_off; k < start_off + num; k++) begin
          d = get_delta(base, valid_idx + k);
          if (d != period) begin
            fail(clause, $sformatf("base %0d period mismatch at offset %0d: got %0d expected %0d",
                                   base, k, d, period));
            return;
          end
        end
      end
    end
  endtask

  task automatic check_set96(input int set_idx, input logic [95:0] expected_set,
                             input longint period);
    int k;
    longint d;
    begin
      if (recs[set_idx].ts96 !== expected_set)
        fail("S1/F1", $sformatf("ts96 set mismatch: got %h expected %h",
                                recs[set_idx].ts96, expected_set));
      if (recs[set_idx].ts_step !== 1)
        fail("S3", "ts_step not high on set96");

      for (k = 1; k <= 10; k++) begin
        if (recs[set_idx + k].ts_step !== 0)
          fail("S3", $sformatf("ts_step high after set96 at k=%0d", k));
        d = get_delta(1, set_idx + k);
        if (d != period)
          fail("S4", $sformatf("ts64 disturbed by set96 at k=%0d: got %0d expected %0d",
                               k, d, period));
      end

      for (k = 5; k <= 10; k++) begin
        d = get_delta(0, set_idx + k);
        if (d != period)
          fail("I1/X2c", $sformatf("ts96 increment after set96 at k=%0d: got %0d expected %0d",
                                   k, d, period));
      end
    end
  endtask

  task automatic check_set64(input int set_idx, input logic [63:0] expected_set,
                             input longint period);
    int k;
    longint d;
    begin
      if (recs[set_idx].ts64 !== expected_set)
        fail("S2/F2", $sformatf("ts64 set mismatch: got %h expected %h",
                                recs[set_idx].ts64, expected_set));
      if (recs[set_idx].ts_step !== 1)
        fail("S3", "ts_step not high on set64");

      for (k = 1; k <= 10; k++) begin
        if (recs[set_idx + k].ts_step !== 0)
          fail("S3", $sformatf("ts_step high after set64 at k=%0d", k));
        d = get_delta(0, set_idx + k);
        if (d != period)
          fail("S4", $sformatf("ts96 disturbed by set64 at k=%0d: got %0d expected %0d",
                               k, d, period));
      end

      for (k = 5; k <= 10; k++) begin
        d = get_delta(1, set_idx + k);
        if (d != period)
          fail("I1/X2c", $sformatf("ts64 increment after set64 at k=%0d: got %0d expected %0d",
                                   k, d, period));
      end
    end
  endtask

  task automatic check_adj(input int valid_idx, input int count, input longint adj_fns,
                           input longint period, input string clause);
    int base, k, j, first_adj, first_active;
    longint adjusted_delta, d;
    begin
      adjusted_delta = period + adj_fns;

      for (base = 0; base < 2; base++) begin
        first_adj = -1;
        for (k = 0; k <= 8; k++) begin
          d = get_delta(base, valid_idx + k);
          if (d == adjusted_delta) begin
            first_adj = k;
            break;
          end
        end

        if (first_adj == -1) begin
          fail(clause, $sformatf("base %0d no adjusted increment within 8 cycles", base));
          return;
        end

        for (j = 0; j < count; j++) begin
          d = get_delta(base, valid_idx + first_adj + j);
          if (d != adjusted_delta) begin
            fail(clause, $sformatf("base %0d adjusted block broken at j=%0d", base, j));
            return;
          end
        end

        d = get_delta(base, valid_idx + first_adj + count);
        if (d == adjusted_delta) begin
          fail(clause, $sformatf("base %0d too many adjusted increments", base));
          return;
        end

        for (k = first_adj + count + 1; k <= 50; k++) begin
          d = get_delta(base, valid_idx + k);
          if (d == adjusted_delta) begin
            fail(clause, $sformatf("base %0d extra adjusted increment at offset %0d", base, k));
            return;
          end
        end

        for (k = 0; k <= 50; k++) begin
          d = get_delta(base, valid_idx + k);
          if (d != adjusted_delta && d != period) begin
            fail(clause, $sformatf("base %0d unexpected delta %0d at offset %0d", base, d, k));
            return;
          end
        end
      end

      first_active = -1;
      for (k = 0; k <= 50; k++) begin
        if (recs[valid_idx + k].adj_active) begin
          first_active = k;
          break;
        end
      end

      if (first_active == -1) begin
        fail("A3", "no adj_active pulse");
        return;
      end

      if (first_active + count > 50) begin
        fail("A3", "adj_active too late");
        return;
      end

      for (j = 0; j < count; j++) begin
        if (recs[valid_idx + first_active + j].adj_active !== 1) begin
          fail("A3", $sformatf("adj_active not consecutive at j=%0d", j));
          return;
        end
      end

      if (recs[valid_idx + first_active + count].adj_active !== 0) begin
        fail("A3", "adj_active too long");
        return;
      end

      for (k = 0; k <= 50; k++) begin
        if (k < first_active || k >= first_active + count) begin
          if (recs[valid_idx + k].adj_active !== 0) begin
            fail("A3", $sformatf("extra adj_active at offset %0d", k));
            return;
          end
        end
      end

      for (k = 0; k <= 50; k++) begin
        if (recs[valid_idx + k].ts_step !== recs[valid_idx + k].adj_active) begin
          fail("A4", $sformatf("ts_step mismatch at offset %0d", k));
          return;
        end
      end
    end
  endtask

  task automatic check_drift_event(input int valid_idx, input int start_off, input int num,
                                   input longint period, input longint drift_fns,
                                   input int rate, input string clause);
    int base;
    begin
      for (base = 0; base < 2; base++) begin
        check_drift_spacing(base, valid_idx + start_off,
                            valid_idx + start_off + num - 1,
                            period, drift_fns, rate, clause);
      end
    end
  endtask

  task automatic check_ts64_no_wrap(input int set_idx, input longint period);
    int k;
    longint d;
    logic crossed;
    begin
      crossed = 0;
      for (k = 5; k <= 50; k++) begin
        d = get_delta(1, set_idx + k);
        if (d != period)
          fail("W2/I1", $sformatf("ts64 delta mismatch at k=%0d: got %0d expected %0d",
                                  k, d, period));
        if (recs[set_idx + k].ts64[63:16] >= 1000000000)
          crossed = 1;
        if (recs[set_idx + k].pps !== 0)
          fail("W3", $sformatf("pps high during ts64 test at k=%0d", k));
      end
      if (!crossed)
        fail("W2", "ts64 did not cross 1e9");
    end
  endtask

  task automatic check_ts96_wrap(input int set_idx, input longint period);
    int k, wrap_count;
    longint prev_total, cur_total, delta, prev_ns_fns, cur_ns_fns;
    logic [47:0] prev_sec, cur_sec;
    begin
      wrap_count = 0;
      for (k = 1; k <= 50; k++) begin
        prev_total = ts96_total(recs[set_idx + k - 1].ts96);
        cur_total  = ts96_total(recs[set_idx + k].ts96);
        delta = cur_total - prev_total;

        prev_ns_fns = longint'(recs[set_idx + k - 1].ts96[45:16]) * 65536 +
                      longint'(recs[set_idx + k - 1].ts96[15:0]);
        cur_ns_fns  = longint'(recs[set_idx + k].ts96[45:16]) * 65536 +
                      longint'(recs[set_idx + k].ts96[15:0]);

        prev_sec = recs[set_idx + k - 1].ts96[95:48];
        cur_sec  = recs[set_idx + k].ts96[95:48];

        if (prev_ns_fns + delta >= ONE_SEC_FNS) begin
          wrap_count++;
          if (cur_sec != prev_sec + 1)
            fail("W1", $sformatf("seconds mismatch on wrap at k=%0d", k));
          if (cur_ns_fns != prev_ns_fns + delta - ONE_SEC_FNS)
            fail("W1", $sformatf("ns subtraction mismatch on wrap at k=%0d", k));
          if (cur_ns_fns >= ONE_SEC_FNS)
            fail("W1", $sformatf("ns still >= 1e9 after wrap at k=%0d", k));
          if (recs[set_idx + k].pps !== 1)
            fail("W3", $sformatf("pps not high on wrap at k=%0d", k));
        end else begin
          if (recs[set_idx + k].pps !== 0)
            fail("W3", $sformatf("pps high without wrap at k=%0d", k));
        end

        if (recs[set_idx + k].ts96[45:16] >= 1000000000)
          fail("W1", $sformatf("ns field reached 1e9 at k=%0d", k));
      end

      if (wrap_count == 0)
        fail("W1/W3", "no wrap occurred in ts96 test");
    end
  endtask

  // ---------------------------------------------------------------------------
  // Main analysis
  // ---------------------------------------------------------------------------
  task automatic analyze_all;
    int i, idx;
    int first_drift_idx, p1_idx, p2_idx, p3_idx;
    int set96_7_idx, set64_123_idx, adj_pos_idx, adj_neg_idx;
    int drift_pos_idx, drift_neg_idx, drift_comb_idx, adj_comb_idx;
    int set96_0_idx, set64_999_idx, set96_wrap_idx;
    int last_rst_idx, reset9_idx;
    int wrap_set_idx;
    longint P1, P2, P3;
    logic [95:0] exp_set96;
    logic [63:0] exp_set64;
    begin
      P1 = 10 * 65536 + 16'h1234;
      P2 = 8 * 65536 + 16'h8000;
      P3 = 10 * 65536;

      // Default period and drift after first reset
      first_drift_idx = find_drift_from(0, 0, 1, 0);
      if (first_drift_idx == -1) begin
        fail("D1", "no first drift_valid");
        return;
      end

      idx = find_first_cycle(9);
      if (idx == -1) begin
        fail("X2a", "no cycle 9 after first reset");
        return;
      end

      check_drift_spacing(0, idx, first_drift_idx - 1, 419430, 2, 5,
                          "I1/D2 default ts96");
      check_drift_spacing(1, idx, first_drift_idx - 1, 419430, 2, 5,
                          "I1/D2 default ts64");

      // Period P1
      p1_idx = find_period(10, 16'h1234);
      if (p1_idx == -1)
        fail("I2", "no P1 period_valid");
      else
        check_period_both(p1_idx, 10, 10, P1, "I2 P1");

      // Set ts96
      exp_set96 = {48'd7, 2'b00, 30'd123456789, 16'hABCD};
      set96_7_idx = find_set96_val(exp_set96);
      if (set96_7_idx == -1)
        fail("S1", "no set96 event");
      else
        check_set96(set96_7_idx, exp_set96, P1);

      // Set ts64
      exp_set64 = {48'd123456789, 16'h1234};
      set64_123_idx = find_set64_val(exp_set64);
      if (set64_123_idx == -1)
        fail("S2", "no set64 event");
      else
        check_set64(set64_123_idx, exp_set64, P1);

      // Positive counted adjustment
      adj_pos_idx = find_adj(5, 0, 7);
      if (adj_pos_idx == -1)
        fail("A1", "no adj positive event");
      else
        check_adj(adj_pos_idx, 7, 5 * 65536, P1, "A2/A3/A4 positive");

      // Negative counted adjustment
      adj_neg_idx = find_adj(4'hD, 0, 5);
      if (adj_neg_idx == -1)
        fail("A1", "no adj negative event");
      else
        check_adj(adj_neg_idx, 5, -3 * 65536, P1, "A2/A3/A4 negative");

      // Period P2
      p2_idx = find_period(8, 16'h8000);
      if (p2_idx == -1)
        fail("I2", "no P2 period_valid");
      else
        check_period_both(p2_idx, 10, 10, P2, "I2 P2");

      // Drift +3 rate 7
      drift_pos_idx = find_drift_from(0, 3, 7, 0);
      if (drift_pos_idx == -1)
        fail("D1", "no drift +3 event");
      else
        check_drift_event(drift_pos_idx, 20, 100, P2, 3, 7, "D2 drift +3");

      // Drift -2 rate 5
      drift_neg_idx = find_drift_from(4'hF, 16'hFFFE, 5, 0);
      if (drift_neg_idx == -1)
        fail("D1", "no drift -2 event");
      else
        check_drift_event(drift_neg_idx, 20, 100, P2, -2, 5, "D2 drift -2");

      // Combined period + drift + adjustment
      drift_comb_idx = find_drift_from(0, 5, 1, 0);
      if (drift_comb_idx == -1)
        fail("D1", "no drift +5 event");
      adj_comb_idx = find_adj(2, 0, 4);
      if (adj_comb_idx == -1)
        fail("A1", "no combined adj event");
      else
        check_adj(adj_comb_idx, 4, 2 * 65536, P2 + 5, "I1 combined");

      // Period P3
      p3_idx = find_period(10, 0);
      if (p3_idx == -1)
        fail("I2", "no P3 period_valid");
      else
        check_period_both(p3_idx, 10, 10, P3, "I2 P3");

      // Set ts96 to zero
      exp_set96 = 96'd0;
      set96_0_idx = find_set96_val(exp_set96);
      if (set96_0_idx == -1)
        fail("S1", "no set96 zero event");

      // ts64 crossing 1e9 without wrapping
      exp_set64 = {48'd999999900, 16'd0};
      set64_999_idx = find_set64_val(exp_set64);
      if (set64_999_idx == -1)
        fail("S2", "no set64 999999900 event");
      else
        check_ts64_no_wrap(set64_999_idx, P3);

      // ts96 wrap and pps
      exp_set96 = {48'd5, 2'b00, 30'd999999900, 16'd0};
      set96_wrap_idx = find_set96_val(exp_set96);
      if (set96_wrap_idx == -1)
        fail("S1", "no set96 wrap event");
      else
        check_ts96_wrap(set96_wrap_idx, P3);
      wrap_set_idx = set96_wrap_idx;

      // pps must only be high during the wrap test
      for (i = 0; i < recs.size(); i++) begin
        if (recs[i].rst == 0 && recs[i].pps == 1) begin
          if (i < wrap_set_idx || i > wrap_set_idx + 50) begin
            fail("W3", $sformatf("pps asserted outside wrap test at index %0d", i));
            break;
          end
        end
      end

      // ts_step must only be high on set valid or adj_active
      for (i = 0; i < recs.size(); i++) begin
        if (recs[i].rst == 0 && recs[i].ts_step == 1) begin
          if (!(recs[i].sh_set96_valid || recs[i].sh_set64_valid || recs[i].adj_active)) begin
            fail("A4/S3", $sformatf("unexpected ts_step at index %0d", i));
            break;
          end
        end
      end

      // Reset cancellation and default restoration
      last_rst_idx = -1;
      for (i = 0; i < recs.size(); i++)
        if (recs[i].rst == 1) last_rst_idx = i;

      if (last_rst_idx == -1) begin
        fail("R1", "no reset asserted");
      end else begin
        if (last_rst_idx + 1 >= recs.size()) begin
          fail("R1", "no deassert record");
        end else begin
          if (recs[last_rst_idx + 1].ts96 !== 0)
            fail("R2", "ts96 not zero after reset");
          if (recs[last_rst_idx + 1].ts64 !== 0)
            fail("R2", "ts64 not zero after reset");
          if (recs[last_rst_idx + 1].adj_active !== 0)
            fail("R2", "adj_active not zero after reset");
          if (recs[last_rst_idx + 1].ts_step !== 0)
            fail("R2", "ts_step not zero after reset");
          if (recs[last_rst_idx + 1].pps !== 0)
            fail("R2", "pps not zero after reset");

          reset9_idx = -1;
          for (i = last_rst_idx + 1; i < recs.size(); i++) begin
            if (recs[i].rst == 0 && recs[i].cyc == 9) begin
              reset9_idx = i;
              break;
            end
          end

          if (reset9_idx == -1) begin
            fail("X2a", "no cycle 9 after last reset");
          end else begin
            check_drift_spacing(0, reset9_idx, recs.size() - 1, 419430, 2, 5,
                                "R2 default after reset ts96");
            check_drift_spacing(1, reset9_idx, recs.size() - 1, 419430, 2, 5,
                                "R2 default after reset ts64");
          end

          for (i = last_rst_idx + 1; i < recs.size(); i++) begin
            if (recs[i].adj_active !== 0)
              fail("A3/R2", "adj_active after reset");
            if (recs[i].ts_step !== 0)
              fail("A4/R2", "ts_step after reset");
          end
        end
      end
    end
  endtask

  // ---------------------------------------------------------------------------
  // Stimulus
  // ---------------------------------------------------------------------------
  initial begin
    bfm_reset(5);

    if (ts96 !== 0 || ts64 !== 0 || adj_active || ts_step || pps)
      fail("R2", "reset state not zero");

    // Default period/drift observation
    bfm_wait(100);

    // Zero drift, rate 1
    bfm_drift(0, 0, 1);
    bfm_wait(20);

    // Period P1
    bfm_period(10, 16'h1234);
    bfm_wait(20);

    // Set ts96
    bfm_set96(48'd7, 30'd123456789, 16'hABCD);
    bfm_wait(10);

    // Set ts64
    bfm_set64(48'd123456789, 16'h1234);
    bfm_wait(10);

    // Positive counted adjustment
    bfm_adjust(5, 0, 7);
    bfm_wait(60);

    // Negative counted adjustment
    bfm_adjust(4'hD, 0, 5);
    bfm_wait(60);

    // Period P2
    bfm_period(8, 16'h8000);
    bfm_wait(20);

    // Drift +3, rate 7
    bfm_drift(0, 3, 7);
    bfm_wait(20);
    bfm_wait(100);

    // Drift -2, rate 5
    bfm_drift(4'hF, 16'hFFFE, 5);
    bfm_wait(20);
    bfm_wait(100);

    // Combined period + drift + adjustment
    bfm_drift(0, 5, 1);
    bfm_wait(20);
    bfm_adjust(2, 0, 4);
    bfm_wait(60);

    // Back to zero drift
    bfm_drift(0, 0, 1);
    bfm_wait(20);

    // Period P3
    bfm_period(10, 0);
    bfm_wait(20);

    // ts64 crossing 1e9 without wrapping
    bfm_set96(0, 0, 0);
    bfm_wait(10);
    bfm_set64(48'd999999900, 0);
    bfm_wait(50);

    // ts96 wrap and pps
    bfm_set96(48'd5, 30'd999999900, 0);
    bfm_wait(50);

    // Start a long adjustment, then reset to cancel it
    bfm_adjust(5, 0, 100);
    bfm_wait(5);
    bfm_reset(5);

    if (ts96 !== 0 || ts64 !== 0 || adj_active || ts_step || pps)
      fail("R2", "reset state not zero after cancel");

    bfm_wait(50);

    analyze_all();

    if (fail_count == 0)
      $display("RESULT: PASS");
    else
      $display("RESULT: FAIL");

    $finish;
  end

endmodule
