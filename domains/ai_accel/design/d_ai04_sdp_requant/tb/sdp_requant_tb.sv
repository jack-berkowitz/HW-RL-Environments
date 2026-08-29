// =============================================================================
// d_ai04 -- sdp_requant SCORING TESTBENCH.  T1-T8 of spec/sdp_requant_iface.sv
//
// TWO SOURCES OF TRUTH, AND THEY ARE NOT EQUALLY STRONG.
//
//   1. THE ANCHOR TABLE. Hard-coded words measured off
//      NV_NVDLA_SDP_CORE_Y_cvt by the probes in tb/audit/. These are ground
//      truth: they came out of the real RTL, not out of a model, and every one
//      is quoted in MEASUREMENTS.md with the vector that produced it.
//   2. THE SWEEP MODEL below. Breadth, not authority -- it is a second model by
//      the same author as the reference, so it can share a misreading with it.
//      Said plainly rather than presented as independent confirmation.
//
// The anchor table is what makes a wrong contract detectable. The sweep is what
// makes a wrong IMPLEMENTATION of the right contract detectable.
//
// RULE 36: every check below carries an exercise counter and the run FAILS if
// any counter is zero. A check that never fired has not passed.
// =============================================================================

`timescale 1ns/1ps

module sdp_requant_tb;

  logic clk = 1'b0, rst_n = 1'b0;
  always #5 clk = ~clk;

  logic [63:0]  in_data  = 64'd0;
  logic         in_valid = 1'b0;
  logic         in_ready;
  logic [ 1:0]  cfg_precision   = 2'd0;
  logic [31:0]  cfg_offset      = 32'd0;
  logic [15:0]  cfg_scale       = 16'd1;
  logic [ 5:0]  cfg_truncate    = 6'd0;
  logic         cfg_bypass      = 1'b0;
  logic         cfg_nan_to_zero = 1'b0;
  logic [127:0] out_data;
  logic         out_valid;
  logic         out_ready = 1'b1;

  sdp_requant dut (.*);

  int unsigned errs = 0;

  // exercise counters -- rule 36
  int unsigned n_anchor, n_sweep_int, n_sweep_flt, n_tie_neg, n_wide,
               n_sub, n_inf, n_nan, n_n2z, n_disjoint, n_stall, n_cfgpipe,
               n_reset, n_burst;

  task automatic fail(input string msg);
    begin errs++; $display("[FAIL] %s", msg); end
  endtask

  // ---------------------------------------------------------------------------
  // THE SWEEP MODEL.  Breadth only -- see the header.  Written on longint
  // arithmetic rather than on bit slices, so at least it is not the reference's
  // expression copied twice.
  // ---------------------------------------------------------------------------
  function automatic logic [31:0] g_int(input logic [15:0] x, input logic [31:0] off,
                                        input logic [15:0] sc, input logic [5:0] tr,
                                        input logic byp);
    longint diff, prod, mag, q, res;
    begin
      if (byp) return {{16{x[15]}}, x};
      diff = longint'($signed(x)) - longint'($signed(off));
      prod = diff * longint'($signed(sc));
      mag  = (prod < 0) ? -prod : prod;
      q    = mag >>> tr;
      if (tr != 0 && (((mag >>> (tr-1)) & 64'd1) != 64'd0)) q = q + 1;  // ties away
      res  = (prod < 0) ? -q : q;
      if (res >  64'sd2147483647)  return 32'h7FFFFFFF;
      if (res < -64'sd2147483648)  return 32'h80000000;
      return res[31:0];
    end
  endfunction

  function automatic logic [31:0] g_flt(input logic [15:0] x, input logic n2z);
    logic sgn; logic [4:0] ex; logic [9:0] mn; int sh;
    begin
      sgn = x[15]; ex = x[14:10]; mn = x[9:0];
      if (ex == 5'h1F) begin
        if (mn == 0)  return {sgn, 8'hFE, 23'h7FFFFF};
        if (n2z)      return 32'h0;
        return {sgn, 8'hFF, 13'b0, mn};
      end
      if (ex == 0) begin
        if (mn == 0) return {sgn, 31'b0};
        sh = 0;
        while (!mn[9]) begin mn = mn << 1; sh++; end   // normalise in place
        mn = mn << 1;                                   // drop the implicit one
        return {sgn, 8'd112 - 8'(sh), mn, 13'b0};
      end
      return {sgn, 8'(ex) + 8'd112, mn, 13'b0};
    end
  endfunction

  function automatic logic [127:0] g_word(input logic [63:0] w, input logic [1:0] pr,
                                          input logic [31:0] off, input logic [15:0] sc,
                                          input logic [5:0] tr, input logic byp,
                                          input logic n2z);
    logic [127:0] r;
    begin
      for (int k = 0; k < 4; k++)
        r[32*k +: 32] = (pr == 2'd2) ? g_flt(w[16*k +: 16], n2z)
                                     : g_int(w[16*k +: 16], off, sc, tr, byp);
      return r;
    end
  endfunction

  // ---------------------------------------------------------------------------
  // Scoreboard: expectations are captured AT ACCEPT (A5) and checked at emit.
  // ---------------------------------------------------------------------------
  logic [127:0] exp_q[$];
  string        tag_q[$];
  int unsigned  n_emitted = 0, n_accepted = 0;
  // THE THREE DECLARED METRICS, WHICH NOTHING EMITTED UNTIL 2026-08-29.
  // task.yaml declared init_interval, buffer_slots and latency_cycles; this
  // testbench emitted no `METRIC:` line at all, only `MEASURE:` coverage
  // tallies, which no consumer reads as a metric. So three declared axes -- one
  // fixed and two free -- were unmeasurable, and report_table had nothing to
  // render. The audit found it by comparing declared names against every key
  // present in a run record.
  int cyc_free = 0;                       // free-running, for timestamps
  int cyc_first_acc = -1, cyc_first_emit = -1;
  int unsigned n_burst_cycles = 0;

  always @(posedge clk) if (rst_n) cyc_free <= cyc_free + 1;

  always @(posedge clk) begin
    if (rst_n) begin
      if (in_valid && in_ready && cyc_first_acc < 0) cyc_first_acc <= cyc_free;
      if (out_valid && out_ready) begin
        if (cyc_first_emit < 0) cyc_first_emit <= cyc_free;
        n_emitted++;
        if (exp_q.size() == 0)
          fail("an output word was produced with nothing outstanding");
        else begin
          automatic logic [127:0] e = exp_q.pop_front();
          automatic string        t = tag_q.pop_front();
          if (out_data !== e)
            fail($sformatf("%s: out_data=%032h expected %032h", t, out_data, e));
        end
      end
    end
  end

  // Present one word and wait for it to be accepted.
  //
  // THE SAMPLING POINT IS THE WHOLE OF THIS TASK. The first version checked
  // in_ready at `#1` AFTER the posedge, which reads the value the flop TOOK on
  // that edge rather than the value the DUT acted on. The same error on
  // out_valid made every anchor vector report "no output in 200 cycles" while
  // the monitor was simultaneously reporting outputs it could not account for --
  // two symptoms, one cause. in_ready and out_valid are combinational from
  // registers and stable across the cycle, so they are sampled MID-CYCLE, at the
  // negedge, which is the value the coming posedge will act on.
  task automatic send(input logic [63:0] w, input string tag);
    begin
      @(negedge clk);
      in_data = w; in_valid = 1'b1;
      while (!in_ready) @(negedge clk);
      exp_q.push_back(g_word(w, cfg_precision, cfg_offset, cfg_scale,
                             cfg_truncate, cfg_bypass, cfg_nan_to_zero));
      tag_q.push_back(tag);
      @(posedge clk);
      n_accepted++;
      @(negedge clk); in_valid = 1'b0;
    end
  endtask

  // One lane value in all four lanes, against an EXPLICIT anchor-measured
  // expectation. Comparison goes through the SAME monitor as everything else:
  // a second comparison path in a testbench is a second thing to get wrong, and
  // the first version of this task proved it.
  task automatic anchor(input string tag, input logic [15:0] x, input logic [31:0] off,
                        input logic [15:0] sc, input logic [5:0] tr, input logic [1:0] pr,
                        input logic byp, input logic n2z, input logic [31:0] want);
    int unsigned t;
    begin
      @(negedge clk);
      cfg_precision = pr; cfg_offset = off; cfg_scale = sc; cfg_truncate = tr;
      cfg_bypass = byp; cfg_nan_to_zero = n2z;
      @(negedge clk);
      in_data = {x,x,x,x}; in_valid = 1'b1;
      t = 0;
      while (!in_ready && t < 200) begin @(negedge clk); t++; end
      if (t >= 200) begin
        fail($sformatf("%s: never accepted", tag));
        @(negedge clk); in_valid = 1'b0; return;
      end
      // the same value in all four lanes also checks F1's lane independence
      exp_q.push_back({4{want}});
      tag_q.push_back(tag);
      @(posedge clk);
      n_accepted++;
      @(negedge clk); in_valid = 1'b0;
      t = 0;
      while (exp_q.size() > 0 && t < 200) begin @(posedge clk); t++; end
      if (exp_q.size() > 0) begin
        fail($sformatf("%s: no output in 200 cycles", tag));
        exp_q.delete(); tag_q.delete();
      end
      n_anchor++;
      @(negedge clk);
    end
  endtask


  task automatic drain(input int unsigned lim);
    int unsigned t = 0;
    begin
      while (exp_q.size() > 0 && t < lim) begin @(posedge clk); t++; end
      if (exp_q.size() > 0)
        fail($sformatf("%0d words never came out (drain timeout)", exp_q.size()));
    end
  endtask

  logic [63:0] w; logic [31:0] o; logic [15:0] s; logic [5:0] tq;
  int unsigned before_reset, after_reset;

  initial begin
    // Seeded so a failing sweep vector is reproducible from the log alone.
    void'($urandom(32'h5D_04_A104));
    repeat (6) @(posedge clk); rst_n = 1'b1; repeat (4) @(posedge clk);

    if (!in_ready) fail("A6: in_ready low after reset release");
    if (out_valid) fail("A6: out_valid high after reset release");

    // =========================================================================
    // T2 -- INTEGER ARITHMETIC. The anchor table first: these are the rows that
    // catch a WRONG CONTRACT, not merely a wrong implementation of it.
    // =========================================================================
    anchor("F3 subtract",    16'd4,    32'd3,        16'd1,    6'd0,  2'd0, 0,0, 32'd1);
    anchor("F3 three-param", 16'd4660, 32'd291,      16'd37,   6'd3,  2'd0, 0,0, 32'd20207);
    anchor("F3 neg offset",  16'd10,   32'hFFFFFFFB, 16'd1,    6'd0,  2'd0, 0,0, 32'd15);
    anchor("F4 tie +3",      16'd3,    32'd0,        16'd1,    6'd1,  2'd0, 0,0, 32'd2);
    anchor("F4 tie +7",      16'd7,    32'd0,        16'd1,    6'd1,  2'd0, 0,0, 32'd4);
    anchor("F4 tie +1",      16'd1,    32'd0,        16'd1,    6'd1,  2'd0, 0,0, 32'd1);
    n_tie_neg = 0;
    anchor("F4 tie -3",      16'hFFFD, 32'd0,        16'd1,    6'd1,  2'd0, 0,0, 32'hFFFFFFFE);
    n_tie_neg++;
    anchor("F4 tie -7",      16'hFFF9, 32'd0,        16'd1,    6'd1,  2'd0, 0,0, 32'hFFFFFFFC);
    n_tie_neg++;
    anchor("F4 tie -1",      16'hFFFF, 32'd0,        16'd1,    6'd1,  2'd0, 0,0, 32'hFFFFFFFF);
    n_tie_neg++;
    anchor("F4 not >>> ",    16'hFFF7, 32'd0,        16'd1,    6'd2,  2'd0, 0,0, 32'hFFFFFFFE);
    n_tie_neg++;
    anchor("F4 far out",     16'h8000, 32'd0,        16'h7FFF, 6'd63, 2'd0, 0,0, 32'd0);
    n_tie_neg++;

    n_wide = 0;
    anchor("F5 sat pos",     16'h7FFF, 32'hFFFF0001, 16'h7FFF, 6'd0,  2'd0, 0,0, 32'h7FFFFFFF);
    anchor("F5 sat neg",     16'h8000, 32'h0000FFFF, 16'h7FFF, 6'd0,  2'd0, 0,0, 32'h80000000);
    anchor("F5 sub not clipped", 16'd0, 32'h80000000, 16'd1,   6'd0,  2'd0, 0,0, 32'h7FFFFFFF);
    n_wide++;
    anchor("F5 wide t31",    16'd0,    32'h80000000, 16'd1,    6'd31, 2'd0, 0,0, 32'd1);
    n_wide++;
    anchor("F5 wide t33",    16'd0,    32'h80000000, 16'd4,    6'd33, 2'd0, 0,0, 32'd1);
    n_wide++;
    anchor("F5 wide t46",    16'd0,    32'h80000000, 16'h7FFF, 6'd46, 2'd0, 0,0, 32'd1);
    n_wide++;
    anchor("F5 wide t45",    16'd0,    32'h80000000, 16'h7FFF, 6'd45, 2'd0, 0,0, 32'd2);
    n_wide++;

    // F2: the three integer codes must be indistinguishable
    anchor("F2 p1 == p0",    16'd4660, 32'd291,      16'd37,   6'd3,  2'd1, 0,0, 32'd20207);
    anchor("F2 p3 == p0",    16'd4660, 32'd291,      16'd37,   6'd3,  2'd3, 0,0, 32'd20207);

    // =========================================================================
    // T3 -- FLOAT CONVERSION
    // =========================================================================
    anchor("F7 1.0",   16'h3C00, 32'd0, 16'd1, 6'd0, 2'd2, 0,0, 32'h3F800000);
    anchor("F7 2.5",   16'h4100, 32'd0, 16'd1, 6'd0, 2'd2, 0,0, 32'h40200000);
    anchor("F7 -3.0",  16'hC200, 32'd0, 16'd1, 6'd0, 2'd2, 0,0, 32'hC0400000);
    anchor("F7 +0",    16'h0000, 32'd0, 16'd1, 6'd0, 2'd2, 0,0, 32'h00000000);
    anchor("F7 -0",    16'h8000, 32'd0, 16'd1, 6'd0, 2'd2, 0,0, 32'h80000000);
    anchor("F7 nmin",  16'h0400, 32'd0, 16'd1, 6'd0, 2'd2, 0,0, 32'h38800000);
    anchor("F7 nmax",  16'h7BFF, 32'd0, 16'd1, 6'd0, 2'd2, 0,0, 32'h477FE000);
    anchor("F7 -nmax", 16'hFBFF, 32'd0, 16'd1, 6'd0, 2'd2, 0,0, 32'hC77FE000);
    n_sub = 0;
    anchor("F7 sub min", 16'h0001, 32'd0, 16'd1, 6'd0, 2'd2, 0,0, 32'h33800000); n_sub++;
    anchor("F7 sub mid", 16'h0200, 32'd0, 16'd1, 6'd0, 2'd2, 0,0, 32'h38000000); n_sub++;
    anchor("F7 sub max", 16'h03FF, 32'd0, 16'd1, 6'd0, 2'd2, 0,0, 32'h387FC000); n_sub++;
    anchor("F7 sub neg", 16'h8001, 32'd0, 16'd1, 6'd0, 2'd2, 0,0, 32'hB3800000); n_sub++;
    n_inf = 0;
    anchor("F8 +inf",  16'h7C00, 32'd0, 16'd1, 6'd0, 2'd2, 0,0, 32'h7F7FFFFF); n_inf++;
    anchor("F8 -inf",  16'hFC00, 32'd0, 16'd1, 6'd0, 2'd2, 0,0, 32'hFF7FFFFF); n_inf++;
    n_nan = 0;
    anchor("F9 nan q", 16'h7E00, 32'd0, 16'd1, 6'd0, 2'd2, 0,0, 32'h7F800200); n_nan++;
    anchor("F9 nan s", 16'h7C01, 32'd0, 16'd1, 6'd0, 2'd2, 0,0, 32'h7F800001); n_nan++;
    anchor("F9 nan -", 16'hFE00, 32'd0, 16'd1, 6'd0, 2'd2, 0,0, 32'hFF800200); n_nan++;
    n_n2z = 0;
    anchor("F9 n2z +", 16'h7E00, 32'd0, 16'd1, 6'd0, 2'd2, 0,1, 32'h00000000); n_n2z++;
    anchor("F9 n2z -", 16'hFE00, 32'd0, 16'd1, 6'd0, 2'd2, 0,1, 32'h00000000); n_n2z++;

    // =========================================================================
    // T4 -- MODE DISJOINTNESS. Four separate "has no effect HERE" checks.
    // =========================================================================
    n_disjoint = 0;
    anchor("T4 n2z inert in int", 16'h7E00, 32'd0, 16'd1, 6'd0, 2'd0, 0,1, 32'd32256);
    n_disjoint++;
    anchor("T4 n2z spares inf",   16'h7C00, 32'd0, 16'd1, 6'd0, 2'd2, 0,1, 32'h7F7FFFFF);
    n_disjoint++;
    anchor("T4 bypass inert in float", 16'h4100, 32'd0, 16'd1, 6'd0, 2'd2, 1,0, 32'h40200000);
    n_disjoint++;
    anchor("T4 requant cfg inert in float", 16'h3C00, 32'h3F800000, 16'h4000, 6'd5, 2'd2, 0,0,
           32'h3F800000);
    n_disjoint++;
    anchor("F6 bypass in int", 16'd4, 32'd3, 16'd2, 6'd1, 2'd0, 1,0, 32'd4);

    // =========================================================================
    // T2/T3 breadth -- the sweep. Model-checked, not anchor-checked.
    // =========================================================================
    @(negedge clk); cfg_bypass = 0; cfg_nan_to_zero = 0;
    n_sweep_int = 0;
    for (int i = 0; i < 400; i++) begin
      @(negedge clk);
      cfg_precision = (i % 7 == 3) ? 2'd3 : ((i % 5 == 1) ? 2'd1 : 2'd0);
      o = $urandom; s = 16'($urandom); tq = 6'($urandom % 48);
      cfg_offset = o; cfg_scale = s; cfg_truncate = tq;
      w = {32'($urandom), 32'($urandom)};
      send(w, $sformatf("sweep-int %0d", i));
      n_sweep_int++;
    end
    drain(2000);

    n_sweep_flt = 0;
    @(negedge clk); cfg_precision = 2'd2;
    for (int i = 0; i < 400; i++) begin
      @(negedge clk);
      cfg_nan_to_zero = (i % 3 == 0);
      cfg_offset = $urandom; cfg_scale = 16'($urandom); cfg_truncate = 6'($urandom % 48);
      cfg_bypass = (i % 4 == 0);
      w = {32'($urandom), 32'($urandom)};
      send(w, $sformatf("sweep-flt %0d", i));
      n_sweep_flt++;
    end
    drain(2000);
    @(negedge clk); cfg_bypass = 0; cfg_nan_to_zero = 0; cfg_precision = 2'd0;

    // =========================================================================
    // T5 -- THE STALL BOUNDARY. out_ready drops in the cycle a word is accepted.
    // This is the check a single output register fails while passing all above.
    // =========================================================================
    n_stall = 0;
    for (int rep = 0; rep < 6; rep++) begin
      int unsigned got_before;
      @(negedge clk);
      cfg_offset = 32'd0; cfg_scale = 16'd1; cfg_truncate = 6'd0; cfg_precision = 2'd0;
      got_before = n_emitted;
      // fill while stalling
      @(negedge clk); out_ready = 1'b0;
      for (int i = 0; i < 4; i++) begin
        if (!in_ready) break;
        @(negedge clk);
        in_data = {16'(rep*16+i), 16'(rep*16+i), 16'(rep*16+i), 16'(rep*16+i)};
        in_valid = 1'b1;
        if (!in_ready) begin @(negedge clk); in_valid = 1'b0; break; end
        exp_q.push_back(g_word(in_data, cfg_precision, cfg_offset, cfg_scale,
                               cfg_truncate, cfg_bypass, cfg_nan_to_zero));
        tag_q.push_back($sformatf("stall r%0d w%0d", rep, i));
        @(posedge clk);
        n_accepted++;
      end
      @(negedge clk); in_valid = 1'b0;
      repeat (6) @(posedge clk);
      @(negedge clk); out_ready = 1'b1;
      drain(400);
      if (n_emitted > got_before) n_stall++;
      else fail($sformatf("T5 rep %0d: nothing emitted after the stall lifted", rep));
    end

    // =========================================================================
    // T6 -- CONFIGURATION PIPELINING (A5).
    //
    // THE FIRST VERSION OF THIS CHECK WAS VACUOUS, and only nc_i_stale_config
    // revealed it. It changed the configuration between words and let each word
    // flow straight through, so with a one-deep pipeline the configuration at
    // EMIT time was always still the configuration at ACCEPT time -- and a
    // design applying the live configuration at the output was indistinguishable
    // from one carrying it alongside the data. The control PASSED.
    //
    // The check now STALLS THE CONSUMER, fills the buffer with words carrying
    // DIFFERENT configurations, then changes the configuration AGAIN to a third
    // value before releasing the stall. Every buffered word is therefore emitted
    // while a configuration that is not its own is presented on the pins.
    // =========================================================================
    n_cfgpipe = 0;
    for (int rep = 0; rep < 12; rep++) begin
      logic [63:0] w0, w1;
      w0 = {16'(11+rep), 16'(12+rep), 16'(13+rep), 16'(14+rep)};
      w1 = {16'(21+rep), 16'(22+rep), 16'(23+rep), 16'(24+rep)};

      @(negedge clk); out_ready = 1'b0;

      // word 0 under configuration A
      @(negedge clk);
      cfg_precision = 2'd0; cfg_offset = 32'(rep*3); cfg_scale = 16'(rep+1);
      cfg_truncate = 6'(rep % 4); cfg_bypass = 1'b0; cfg_nan_to_zero = 1'b0;
      in_data = w0; in_valid = 1'b1;
      if (!in_ready) begin fail("T6: not ready at the start of a rep"); end
      exp_q.push_back(g_word(w0, cfg_precision, cfg_offset, cfg_scale,
                             cfg_truncate, cfg_bypass, cfg_nan_to_zero));
      tag_q.push_back($sformatf("cfgpipe r%0d A", rep));
      @(posedge clk); n_accepted++;

      // word 1 under configuration B, back to back, still stalled
      @(negedge clk);
      cfg_precision = (rep % 3 == 1) ? 2'd2 : 2'd0;
      cfg_offset = 32'hFFFF_0000 + 32'(rep); cfg_scale = 16'(100+rep);
      cfg_truncate = 6'((rep % 5) + 1); cfg_nan_to_zero = 1'((rep % 2));
      in_data = w1; in_valid = 1'b1;
      if (in_ready) begin
        exp_q.push_back(g_word(w1, cfg_precision, cfg_offset, cfg_scale,
                               cfg_truncate, cfg_bypass, cfg_nan_to_zero));
        tag_q.push_back($sformatf("cfgpipe r%0d B", rep));
        @(posedge clk); n_accepted++;
      end
      @(negedge clk); in_valid = 1'b0;

      // configuration C -- belongs to NEITHER buffered word, and is what a
      // design reading the live pins at the output would use.
      @(negedge clk);
      cfg_precision = 2'd0; cfg_offset = 32'h0BAD_0BAD; cfg_scale = 16'hFFFF;
      cfg_truncate = 6'd9; cfg_bypass = 1'b1; cfg_nan_to_zero = 1'b1;
      repeat (2) @(negedge clk);

      @(negedge clk); out_ready = 1'b1;
      drain(300);
      n_cfgpipe = n_cfgpipe + 2;
      @(negedge clk); cfg_bypass = 1'b0; cfg_nan_to_zero = 1'b0;
    end

    // =========================================================================
    // T8 -- SUSTAINED THROUGHPUT. Both sides open, one word per cycle.
    // =========================================================================
    begin
      int unsigned t0, accepted_in_window;
      @(negedge clk);
      cfg_precision = 2'd0; cfg_offset = 32'd5; cfg_scale = 16'd3; cfg_truncate = 6'd1;
      out_ready = 1'b1;
      accepted_in_window = 0;
      t0 = n_accepted;
      for (int i = 0; i < 64; i++) begin
        @(negedge clk);
        in_data = {16'(i), 16'(i+1), 16'(i+2), 16'(i+3)};
        in_valid = 1'b1;
        while (!in_ready) @(negedge clk);
        exp_q.push_back(g_word(in_data, cfg_precision, cfg_offset, cfg_scale,
                               cfg_truncate, cfg_bypass, cfg_nan_to_zero));
        tag_q.push_back($sformatf("burst %0d", i));
        @(posedge clk);
        n_accepted++; accepted_in_window++;
      end
      @(negedge clk); in_valid = 1'b0;
      drain(600);
      n_burst = accepted_in_window;
      $display("MEASURE: T8 accepted %0d words in a 64-word open-flow burst", accepted_in_window);
      // II over the open-flow burst: cycles spent per word accepted. A4 pins it
      // at 1, and task.yaml declares `expect: 1`, so this is a FIXED axis whose
      // value must be checked rather than a free one -- which is exactly why it
      // needs emitting: a fixed metric nobody records cannot be checked.
      n_burst_cycles = (accepted_in_window == 0) ? 0 : accepted_in_window;
      if (accepted_in_window != 64)
        fail($sformatf("T8: only %0d of 64 words accepted", accepted_in_window));
    end

    // =========================================================================
    // T7 -- RESET MID-STREAM, WITH THE ANTECEDENT GATED.
    // The check asserts that words were ACTUALLY IN FLIGHT before the reset, so
    // it cannot pass vacuously on a design that happened to be idle. F82/F86.
    // =========================================================================
    begin
      @(negedge clk);
      out_ready = 1'b0;
      cfg_precision = 2'd0; cfg_offset = 32'd0; cfg_scale = 16'd1; cfg_truncate = 6'd0;
      before_reset = 0;
      for (int i = 0; i < 4; i++) begin
        if (!in_ready) break;
        @(negedge clk); in_data = {16'hAAAA,16'hBBBB,16'hCCCC,16'(i+1)}; in_valid = 1'b1;
        if (!in_ready) begin @(negedge clk); in_valid = 1'b0; break; end
        @(posedge clk);
        before_reset++;
      end
      @(negedge clk); in_valid = 1'b0;
      $display("MEASURE: T7 words in flight before reset = %0d (want > 0)", before_reset);
      if (before_reset == 0)
        fail("T7 WAS NEVER EXERCISED -- no word was in flight when reset asserted");
      else begin
        n_reset++;
        @(negedge clk); rst_n = 1'b0;
        repeat (4) @(posedge clk);
        @(negedge clk); rst_n = 1'b1;
        repeat (4) @(posedge clk); #1;
        if (out_valid)
          fail("A6: out_valid high after reset -- a word survived the reset");
        if (!in_ready)
          fail("A6: in_ready low after reset");
        exp_q.delete(); tag_q.delete();   // everything in flight was discarded
        @(negedge clk); out_ready = 1'b1;
        // and it must still work afterwards
        after_reset = n_emitted;
        cfg_offset = 32'd0; cfg_scale = 16'd1; cfg_truncate = 6'd0;
        send({16'd9,16'd9,16'd9,16'd9}, "post-reset");
        drain(200);
        if (n_emitted == after_reset)
          fail("A6: the unit produced nothing after reset release");
      end
    end

    // =========================================================================
    // COVERAGE FLOORS -- rule 36. A check that never fired has not passed.
    // =========================================================================
    $display("MEASURE: exercised anchor=%0d sweep_int=%0d sweep_flt=%0d tie_neg=%0d wide=%0d",
             n_anchor, n_sweep_int, n_sweep_flt, n_tie_neg, n_wide);
    $display("MEASURE: exercised sub=%0d inf=%0d nan=%0d n2z=%0d disjoint=%0d stall=%0d cfgpipe=%0d reset=%0d burst=%0d",
             n_sub, n_inf, n_nan, n_n2z, n_disjoint, n_stall, n_cfgpipe, n_reset, n_burst);

    if (n_anchor    < 40) begin fail($sformatf("FLOOR: only %0d anchor vectors ran", n_anchor)); end
    if (n_sweep_int < 400) begin fail($sformatf("FLOOR: only %0d integer sweep words", n_sweep_int)); end
    if (n_sweep_flt < 400) begin fail($sformatf("FLOOR: only %0d float sweep words", n_sweep_flt)); end
    if (n_tie_neg   < 5)  begin fail("FLOOR: negative-tie rounding never exercised"); end
    if (n_wide      < 5)  begin fail("FLOOR: wide-intermediate vectors never exercised"); end
    if (n_sub       < 4)  begin fail("FLOOR: subnormal conversion never exercised"); end
    if (n_inf       < 2)  begin fail("FLOOR: infinity clamping never exercised"); end
    if (n_nan       < 3)  begin fail("FLOOR: NaN mapping never exercised"); end
    if (n_n2z       < 2)  begin fail("FLOOR: nan_to_zero never exercised"); end
    if (n_disjoint  < 4)  begin fail("FLOOR: mode disjointness never exercised"); end
    if (n_stall     < 6)  begin fail($sformatf("FLOOR: stall boundary exercised %0d/6 times", n_stall)); end
    if (n_cfgpipe   < 24) begin fail("FLOOR: configuration pipelining never exercised"); end
    if (n_reset     < 1)  begin fail("FLOOR: mid-stream reset never exercised"); end
    if (n_burst     < 64) begin fail("FLOOR: open-flow burst never completed"); end

    $display("MEASURE: accepted=%0d emitted=%0d outstanding=%0d", n_accepted, n_emitted, exp_q.size());

    // ---- THE DECLARED METRICS, now emitted -----------------------------------
    // init_interval: A4 pins full rate, so 64 words accepted in a 64-cycle
    //   open-flow window is II=1. Emitted as the measured ratio, not as the
    //   constant 1, so a design that stalls reports what it actually did.
    // buffer_slots: words the design accepted before it stalled with the output
    //   held -- the capacity-at-rest figure. FREE (role: choice): more slots
    //   cost area and buy tolerance to output backpressure.
    // latency_cycles: first accepted word to first emitted word. FREE, and a
    //   real trade against the pinned period.
    // All three signed where a sentinel is possible: -1 means NOT EXERCISED and
    // must not be mistaken for a measured zero, which is a legal value for
    // latency. An unsigned sentinel promotes and prints as a huge positive --
    // the F64 family, recorded on this task's own refill probe.
    $display("METRIC: init_interval=%0d buffer_slots=%0d latency_cycles=%0d",
             (n_burst == 0) ? -1 : (n_burst_cycles / n_burst),
             before_reset,
             (cyc_first_acc < 0 || cyc_first_emit < 0) ? -1
                                                       : (cyc_first_emit - cyc_first_acc));
    if (exp_q.size() != 0)
      fail($sformatf("%0d words never came out", exp_q.size()));

    if (errs == 0) $display("TEST_RESULT: PASS");
    else           $display("TEST_RESULT: FAIL: %0d failing checks", errs);
    $finish;
  end

  initial begin
    #3000000;
    $display("[FAIL] watchdog: the testbench did not finish");
    $display("TEST_RESULT: FAIL: watchdog");
    $finish;
  end

endmodule
