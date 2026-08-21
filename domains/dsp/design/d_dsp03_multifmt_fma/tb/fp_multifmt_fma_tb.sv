// =============================================================================
// fp_multifmt_fma_tb.sv  --  SCORING TESTBENCH for d_dsp03.
// =============================================================================
// EXPECTED VALUES COME FROM THE VENDORED ANCHOR, captured into
// vectors/vectors_w<WIDTH>.hex by tb/audit/capture_vectors_tb.sv. Nothing in
// this file computes what an answer should be -- rule 11.
//
// AND THE ANCHOR WAS CHECKED BEFORE IT WAS TRUSTED. tb/audit/ieee754_fma_model.py
// verifies all 13860 captured vectors against IEEE 754-2019 directly, and its
// own rounder is validated against a bracketing-pair property it does not
// compute. That step is not optional here: d_dsp01 satisfied rule 11 exactly
// and its anchor was wrong in four rounding modes of five (F54).
//
// WHERE THE WEIGHT SITS. With expected values safe by construction, the only
// remaining failure is a corner never generated -- nothing goes wrong loudly,
// the run passes, and the untested case is simply absent. So every floor below
// is STIMULUS-SIDE, measured from the vector file rather than from anything the
// candidate did (rule 4), and a floor miss prints COVERAGE HOLE, which the
// runner refuses to score as a pass.
//
// WIDTH IS STRUCTURALLY ENFORCED. It is not enough that a candidate declares
// WIDTH: at WIDTH = 64 a vectorial 16-bit operation has FOUR lanes, the vector
// set carries 1124 FP16 and 988 BF16 four-lane cases whose lanes are all
// DISTINCT, and their upper-lane result bits are compared like any other. A
// design that hardcodes two lanes is bit-exact at WIDTH = 32 and cannot pass
// here. That is the discrimination S0 is chosen for.
// =============================================================================

module fp_multifmt_fma_tb #(
  parameter int unsigned WIDTH = 64
);

  localparam int unsigned MAXV = 20000;
  localparam logic [287:0] SENTINEL = '1;   // fmt = 3 is out of scope, so safe

  logic clk = 0, rst_n = 0;
  always #5 clk = ~clk;

  logic             iv, ir, vec, ov, orr;
  logic [1:0]       fmt;
  logic [WIDTH-1:0] a, b, c, res;
  logic [2:0]       rnd;
  logic [4:0]       fl;

  fp_multifmt_fma #(.WIDTH(WIDTH)) dut (
    .clk_i(clk), .rst_ni(rst_n),
    .in_valid_i(iv), .in_ready_o(ir), .fmt_i(fmt), .vec_i(vec),
    .a_i(a), .b_i(b), .c_i(c), .rnd_i(rnd),
    .out_valid_o(ov), .out_ready_i(orr), .result_o(res), .flags_o(fl));

  // ---- vector store ---------------------------------------------------------
  logic [287:0] v [0:MAXV-1];
  int unsigned  n_vec;
  string        fname;

  function automatic logic [1:0]  f_fmt(input logic [287:0] w); f_fmt = w[267:266]; endfunction
  function automatic logic        f_w64(input logic [287:0] w); f_w64 = w[265];     endfunction
  function automatic logic        f_vec(input logic [287:0] w); f_vec = w[264];     endfunction
  function automatic logic [2:0]  f_rnd(input logic [287:0] w); f_rnd = w[263:261]; endfunction
  function automatic logic [63:0] f_a  (input logic [287:0] w); f_a   = w[260:197]; endfunction
  function automatic logic [63:0] f_b  (input logic [287:0] w); f_b   = w[196:133]; endfunction
  function automatic logic [63:0] f_c  (input logic [287:0] w); f_c   = w[132:69];  endfunction
  function automatic logic [63:0] f_r  (input logic [287:0] w); f_r   = w[68:5];    endfunction
  function automatic logic [4:0]  f_fl (input logic [287:0] w); f_fl  = w[4:0];     endfunction

  function automatic int unsigned fw(input logic [1:0] f);   fw = (f == 2'd0) ? 32 : 16; endfunction
  function automatic int unsigned eb(input logic [1:0] f);   eb = (f == 2'd0) ? 8 : (f == 2'd1) ? 5 : 8; endfunction
  function automatic int unsigned mb(input logic [1:0] f);   mb = (f == 2'd0) ? 23 : (f == 2'd1) ? 10 : 7; endfunction
  function automatic int unsigned nlanes(input logic [1:0] f, input logic vv);
    nlanes = vv ? (WIDTH / fw(f)) : 1;
  endfunction

  // ---- bookkeeping ----------------------------------------------------------
  int unsigned checks, fails, issued, retired;
  int unsigned cyc, lat_sum, lat_min, lat_max;
  string       first_fail;

  task automatic note_fail(input string why);
    fails++;
    if (fails <= 8) $display("[FAIL] %s", why);
    if (first_fail == "") first_fail = why;
  endtask

  // ---- coverage, measured from the FILE (rule 4) ----------------------------
  int unsigned cov_fmt [3], cov_rnd [5], cov_vecf [3];
  int unsigned cov_sub [3], cov_nx, cov_of, cov_uf, cov_nv;
  int unsigned cov_distinct [3];      // vectorial vectors whose lanes all differ
  int unsigned cov_zero, cov_inf, cov_nan;
  int unsigned holes;

  task automatic floor_chk(input string nm, input int unsigned got, input int unsigned want);
    if (got < want) begin
      holes++;
      $display("COVERAGE HOLE: %s = %0d, floor %0d", nm, got, want);
    end
  endtask

  function automatic logic [63:0] lane_of(input logic [63:0] x, input logic [1:0] f,
                                          input int unsigned k);
    lane_of = (x >> (k * fw(f))) & ((64'd1 << fw(f)) - 64'd1);
  endfunction

  // class of a lane value: 0 zero, 1 subnormal, 2 normal, 3 inf, 4 nan
  function automatic int unsigned lclass(input logic [63:0] x, input logic [1:0] f);
    int unsigned E, M;
    logic [63:0] e, m;
    E = eb(f); M = mb(f);
    e = (x >> M) & ((64'd1 << E) - 64'd1);
    m = x & ((64'd1 << M) - 64'd1);
    if (e == 0)                        lclass = (m == 0) ? 0 : 1;
    else if (e == (64'd1 << E) - 64'd1) lclass = (m == 0) ? 3 : 4;
    else                               lclass = 2;
  endfunction

  task automatic tally();
    int unsigned i, k, n, f;
    logic [63:0] L, prev;
    logic allq, distinct;
    for (i = 0; i < n_vec; i++) begin
      f = 32'(f_fmt(v[i]));
      cov_fmt[f]++;
      cov_rnd[f_rnd(v[i])]++;
      if (f_vec(v[i])) cov_vecf[f]++;
      if (f_fl(v[i])[0]) cov_nx++;
      if (f_fl(v[i])[1]) cov_uf++;
      if (f_fl(v[i])[2]) cov_of++;
      if (f_fl(v[i])[4]) cov_nv++;
      n = nlanes(f_fmt(v[i]), f_vec(v[i]));
      distinct = 1'b1;
      for (k = 0; k < n; k++) begin
        L = lane_of(f_r(v[i]), f_fmt(v[i]), k);
        case (lclass(L, f_fmt(v[i])))
          0: cov_zero++;
          1: cov_sub[f]++;
          3: cov_inf++;
          4: cov_nan++;
          default: ;
        endcase
        if (k > 0 && L == prev) distinct = 1'b0;
        prev = L;
      end
      if (n > 1 && distinct) cov_distinct[f]++;
    end
  endtask

  // ---- in-flight queue ------------------------------------------------------
  typedef struct { int unsigned idx; int unsigned t; } fly_t;
  fly_t q[$];

  // Backpressure is applied over a middle window: `orr` drops for a few cycles
  // at a time so H1's stability requirement is actually exercised rather than
  // asserted. A design that lets result_o move while out_valid_o is high and
  // out_ready_i is low fails here and passes a checker that never stalls.
  //
  // The window is a LEVEL and the stalling is driven by the free-running LFSR,
  // so out_ready_i keeps toggling while the driver waits. Latching a whole
  // stall decision for the duration of one issue() deadlocks instantly against
  // any design whose in_ready_o depends on out_ready_i -- which L4 permits and
  // which the reference, at zero pipeline depth, does. That cost 4200 of 6300
  // vectors and looked exactly like a candidate wedging.
  logic [15:0] bp_lfsr = 16'hACE1;
  logic        bp_on;
  logic [WIDTH-1:0] held_res;
  logic [4:0]       held_fl;
  logic             was_holding;

  always @(posedge clk) if (rst_n) begin
    cyc <= cyc + 1;
    bp_lfsr <= {bp_lfsr[14:0], bp_lfsr[15]^bp_lfsr[13]^bp_lfsr[12]^bp_lfsr[10]};
  end

  assign orr = !(bp_on && bp_lfsr[3]);

  // ---- the single monitor, at the POSEDGE -----------------------------------
  // The posedge IS the transfer instant, and every testbench drive happens at a
  // negedge, so nothing the testbench assigns can race what the monitor reads.
  //
  // Observing at the negedge instead -- "valid && ready here means the transfer
  // happens next" -- is equally true and unusable: `issue()` clears in_valid_i
  // with a blocking assignment on the same negedge the monitor fires, and the
  // two orders give different answers. That double-counted transfers, slid the
  // expected-value queue by one, and reported 6116 mismatches against a
  // reference that is bit-exact. Watching the edge the DUT itself samples
  // handles a combinational design and a deeply pipelined one identically --
  // L4 permits either.
  always @(posedge clk) if (rst_n) begin
    fly_t e;
    logic [63:0] exp_r, got_r;
    logic [4:0]  exp_f;
    int unsigned n, k, L;
    logic [287:0] w;

    // H1: while a result is offered and not taken, it must not move.
    if (was_holding && ov && (held_res !== res || held_fl !== fl))
      note_fail($sformatf("result_o/flags_o moved while out_valid_o held and out_ready_i low (cycle %0d)", cyc));
    was_holding <= ov && !orr;
    held_res    <= res;
    held_fl     <= fl;

    if (iv && ir) begin
      q.push_back('{issued, cyc});
      issued <= issued + 1;
    end
    if (ov && orr) begin
      if (q.size() == 0) begin
        note_fail("result produced with no operation in flight");
      end else begin
        e = q.pop_front();
        w = v[e.idx];
        exp_r = f_r(w); exp_f = f_fl(w);
        got_r = 64'(res);
        n = nlanes(f_fmt(w), f_vec(w));
        // compare the whole WIDTH: lanes in use AND the NaN-boxed bits above
        // them, which V3 pins and which a design that forgets them gets wrong.
        if (got_r[WIDTH-1:0] !== exp_r[WIDTH-1:0]) begin
          note_fail($sformatf("vec %0d fmt=%0d vec=%0b rnd=%0d lanes=%0d: result %h expected %h",
                              e.idx, f_fmt(w), f_vec(w), f_rnd(w), n,
                              res, exp_r[WIDTH-1:0]));
        end
        if (fl !== exp_f)
          note_fail($sformatf("vec %0d fmt=%0d vec=%0b rnd=%0d: flags %05b expected %05b",
                              e.idx, f_fmt(w), f_vec(w), f_rnd(w), fl, exp_f));
        checks++;
        retired++;
        lat_sum += (cyc - e.t);
        if ((cyc - e.t) < lat_min) lat_min = cyc - e.t;
        if ((cyc - e.t) > lat_max) lat_max = cyc - e.t;
      end
    end
  end

  task automatic issue(input int unsigned i);
    @(negedge clk);
    fmt = f_fmt(v[i]); vec = f_vec(v[i]); rnd = f_rnd(v[i]);
    a = f_a(v[i])[WIDTH-1:0]; b = f_b(v[i])[WIDTH-1:0]; c = f_c(v[i])[WIDTH-1:0];
    iv = 1'b1;
    #0;
    while (!ir) begin @(negedge clk); #0; end   // the next posedge takes it
    @(negedge clk);
    iv = 1'b0;
  endtask

  int unsigned i;
  initial begin
    iv = 0; vec = 0; fmt = 0; a = 0; b = 0; c = 0; rnd = 0;
    checks = 0; fails = 0; issued = 0; retired = 0; cyc = 0;
    lat_sum = 0; lat_min = 32'hFFFF_FFFF; lat_max = 0; holes = 0;
    bp_on = 0; was_holding = 0; first_fail = "";
    for (i = 0; i < 3; i++) begin cov_fmt[i]=0; cov_vecf[i]=0; cov_sub[i]=0; cov_distinct[i]=0; end
    for (i = 0; i < 5; i++) cov_rnd[i]=0;
    cov_nx=0; cov_of=0; cov_uf=0; cov_nv=0; cov_zero=0; cov_inf=0; cov_nan=0;

    for (i = 0; i < MAXV; i++) v[i] = SENTINEL;
    fname = $sformatf("vectors/vectors_w%0d.hex", WIDTH);
    $readmemh(fname, v);
    n_vec = 0;
    while (n_vec < MAXV && v[n_vec] !== SENTINEL) n_vec++;
    if (n_vec == 0) begin
      $display("[FAIL] no vectors loaded from %s", fname);
      $display("TEST_RESULT: FAIL"); $finish;
    end

    // The record carries the WIDTH it was captured at. Scope is not allowed to
    // ride on the filename -- a w32 file read by a WIDTH=64 run would otherwise
    // score a narrow sweep as a wide one.
    for (i = 0; i < n_vec; i++)
      if (f_w64(v[i]) !== (WIDTH == 64)) begin
        $display("[FAIL] vector %0d was captured at WIDTH=%0d, this run is WIDTH=%0d",
                 i, f_w64(v[i]) ? 64 : 32, WIDTH);
        $display("TEST_RESULT: FAIL"); $finish;
      end

    tally();

    repeat (8) @(negedge clk); rst_n = 1; repeat (4) @(negedge clk);

    for (i = 0; i < n_vec; i++) begin
      // backpressure over the middle third
      bp_on = (i > n_vec/3) && (i < 2*n_vec/3);
      issue(i);
    end
    bp_on = 0;

    // drain
    i = 0;
    while (q.size() != 0 && i < 200000) begin @(negedge clk); i++; end
    repeat (4) @(negedge clk);

    // ---- coverage floors, all stimulus-side ---------------------------------
    floor_chk("fp32 vectors",  cov_fmt[0], 500);
    floor_chk("fp16 vectors",  cov_fmt[1], 500);
    floor_chk("bf16 vectors",  cov_fmt[2], 500);
    for (i = 0; i < 5; i++)
      floor_chk($sformatf("rounding mode %0d", i), cov_rnd[i], 500);
    floor_chk("fp16 vectorial", cov_vecf[1], 500);
    floor_chk("bf16 vectorial", cov_vecf[2], 500);
    if (WIDTH == 64) floor_chk("fp32 vectorial", cov_vecf[0], 500);
    floor_chk("fp32 subnormal results", cov_sub[0], 100);
    floor_chk("fp16 subnormal results", cov_sub[1], 100);
    floor_chk("bf16 subnormal results", cov_sub[2], 100);
    floor_chk("inexact (NX)",   cov_nx, 2000);
    floor_chk("overflow (OF)",  cov_of, 300);
    floor_chk("underflow (UF)", cov_uf, 150);
    floor_chk("invalid (NV)",   cov_nv, 150);
    floor_chk("zero results",   cov_zero, 50);
    floor_chk("infinite results", cov_inf, 200);
    floor_chk("NaN results",    cov_nan, 200);
    // THE CAPACITY FLOOR. Without lanes that differ from each other, a design
    // that computes one lane and replicates it is indistinguishable from
    // correct, and WIDTH is not enforced by anything.
    floor_chk("fp16 vectorial with all lanes distinct", cov_distinct[1], 500);
    floor_chk("bf16 vectorial with all lanes distinct", cov_distinct[2], 500);
    if (WIDTH == 64)
      floor_chk("fp32 vectorial with all lanes distinct", cov_distinct[0], 500);

    if (retired != n_vec)
      note_fail($sformatf("only %0d of %0d vectors retired (forward progress, C1)",
                          retired, n_vec));
    if (checks != n_vec)
      note_fail($sformatf("only %0d of %0d vectors were checked", checks, n_vec));

    $display("METRIC: width=%0d vectors=%0d checks=%0d cycles=%0d", WIDTH, n_vec, checks, cyc);
    if (retired > 0)
      $display("METRIC: latency min=%0d max=%0d mean=%0d.%02d",
               lat_min, lat_max, lat_sum/retired, (100*(lat_sum%retired))/retired);
    $display("METRIC: throughput ops_per_1000cyc=%0d", (cyc > 0) ? (1000*retired)/cyc : 0);
    $display("METRIC: coverage fp32=%0d fp16=%0d bf16=%0d vecdistinct=%0d/%0d/%0d",
             cov_fmt[0], cov_fmt[1], cov_fmt[2],
             cov_distinct[0], cov_distinct[1], cov_distinct[2]);
    $display("METRIC: flags nx=%0d of=%0d uf=%0d nv=%0d subn=%0d/%0d/%0d",
             cov_nx, cov_of, cov_uf, cov_nv, cov_sub[0], cov_sub[1], cov_sub[2]);

    if (fails == 0 && holes == 0) $display("TEST_RESULT: PASS");
    else begin
      if (fails > 8) $display("[FAIL] ... and %0d more", fails - 8);
      $display("TEST_RESULT: FAIL");
    end
    $finish;
  end

  initial begin
    #400_000_000;
    $display("[FAIL] watchdog: %0d of %0d vectors retired, %0d in flight (C1 forward progress)",
             retired, n_vec, q.size());
    $display("TEST_RESULT: FAIL");
    $finish;
  end
endmodule
