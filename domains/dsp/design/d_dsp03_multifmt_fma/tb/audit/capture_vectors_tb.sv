// =============================================================================
// capture_vectors_tb.sv -- VECTOR CAPTURE for d_dsp03. Never scored, never
// shipped.
// =============================================================================
// Rule 11's inversion. LOCALLY AUTHORED, GENERATES INPUTS ONLY. Expected values
// are whatever the vendored anchor produces, so a bug here costs COVERAGE and
// can never produce a wrong expected value.
//
// *** AND THAT IS NOT ENOUGH. *** d_dsp01 satisfied rule 11 exactly and its
// anchor was wrong in four rounding modes out of five (F54). Rule 11 makes
// fabrication impossible; it says nothing about whether the vendored RTL knows
// the right answer. `tb/audit/ieee754_model.py` checks THIS anchor against the
// standard the contract cites, and nothing downstream is built until it passes.
//
// HANDSHAKE OBSERVATION. Both sides are watched by one negedge-synchronised
// monitor, and the operations in flight are held in a queue rather than being
// tracked by the driver. That is deliberate: at a negedge, `valid && ready`
// means the transfer happens at the NEXT posedge, so a COMBINATIONAL design
// (NumPipeRegs = 0 makes this one nearly that) and a deeply pipelined one are
// observed identically. d_dsp01's driver instead waited for its own input
// transfer and then looked for a result, which cannot see a result presented in
// the same cycle the operation was accepted.
//
// Output: vectors/vectors_w<WIDTH>.hex, one 288-bit word per line:
//   [267:266] fmt  [265] w64  [264] vec  [263:261] rnd
//   [260:197] a    [196:133] b  [132:69] c  [68:5] result  [4:0] flags
//
// Operand fields are 64 bits whatever WIDTH is, and the record carries the
// WIDTH IT WAS CAPTURED AT. Scope is not allowed to ride on the filename.
// =============================================================================
module capture_vectors_tb #(
  parameter int unsigned WIDTH = 64
);

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

  // ---- format geometry ------------------------------------------------------
  // FP32 (8,23), FP16 (5,10), BF16 = FP16ALT (8,7).
  function automatic int unsigned ebits(input logic [1:0] f);
    ebits = (f == 2'd0) ? 8 : (f == 2'd1) ? 5 : 8;
  endfunction
  function automatic int unsigned mbits(input logic [1:0] f);
    mbits = (f == 2'd0) ? 23 : (f == 2'd1) ? 10 : 7;
  endfunction
  function automatic int unsigned fwidth(input logic [1:0] f);
    fwidth = 1 + ebits(f) + mbits(f);
  endfunction
  // Lane count is the contract's rule, not the anchor's: WIDTH divided by the
  // selected format's width when vectorial, one otherwise.
  function automatic int unsigned lanes(input logic [1:0] f, input logic v);
    lanes = v ? (WIDTH / fwidth(f)) : 1;
  endfunction

  // Corners built from the geometry rather than tabulated per format, so the
  // same boundary is exercised in all three and none is quietly missing.
  localparam int unsigned NCORNER = 18;
  function automatic logic [31:0] corner(input logic [1:0] f, input int unsigned k);
    int unsigned E, M, bias, sgn;
    logic [31:0] v;
    E = ebits(f); M = mbits(f); bias = (1 << (E-1)) - 1;
    case (k % 15)
      0:  v = 32'd0;                                          // +0
      1:  v = 32'd1;                                          // smallest subnormal
      2:  v = (32'd1 << M) - 32'd1;                           // largest subnormal
      3:  v = 32'd1 << M;                                     // smallest normal
      4:  v = (32'd1 << M) + 32'd1;
      5:  v = 32'(bias) << M;                                 // 1.0
      6:  v = (32'(bias) << M) | 32'd1;                       // 1.0 + 1ulp
      7:  v = 32'(bias + 1) << M;                             // 2.0
      8:  v = 32'(bias - 1) << M;                             // 0.5
      9:  v = ((32'd1 << E) - 32'd2) << M | ((32'd1 << M) - 32'd1); // largest normal
      10: v = ((32'd1 << E) - 32'd1) << M;                    // +inf
      11: v = (((32'd1 << E) - 32'd1) << M) | (32'd1 << (M-1)); // qNaN
      12: v = (((32'd1 << E) - 32'd1) << M) | 32'd1;          // sNaN
      13: v = 32'(bias + 3) << M;                             // 8.0
      default: v = (32'(bias) << M) | (32'd1 << (M-1));       // 1.5
    endcase
    sgn = (k >= 15) ? 1 : 0;                                  // negatives above 15
    corner = v | (32'(sgn) << (E + M));
  endfunction

  // ---- biased random --------------------------------------------------------
  logic [31:0] lfsr = 32'h1F2E_3D4C;
  function automatic logic [31:0] nxt(input logic [31:0] s);
    nxt = {s[30:0], s[31]^s[21]^s[1]^s[0]};
  endfunction
  task automatic roll(); lfsr = nxt(lfsr); endtask

  // Biased toward exponents where the product lands near the addend, which is
  // where cancellation and the wide alignment shift actually get exercised. A
  // uniform draw over 2^W puts the product astronomically far from c almost
  // every time and the aligner is never stressed.
  function automatic logic [31:0] rnd_fp(input logic [1:0] f, input logic [31:0] s);
    int unsigned E, M, bias;
    logic [31:0] e;
    E = ebits(f); M = mbits(f); bias = (1 << (E-1)) - 1;
    case (s[30:29])
      2'b00: e = 32'(s[7:0]) % 32'd6;                             // subnormal / tiny
      2'b01: e = 32'(bias) + (32'(s[3:0]) % 32'd9) - 32'd4;       // around 1.0
      2'b10: e = ((32'd1 << E) - 32'd2) - (32'(s[3:0]) % 32'd4);  // near overflow
      default: e = 32'(s[15:8]) % 32'((1 << E) - 1);
    endcase
    rnd_fp = (32'(s[31]) << (E+M)) | (e << M) | (32'(s[22:0]) & ((32'd1 << M) - 32'd1));
  endfunction

  // ---- targeted bands -------------------------------------------------------
  // Two stimulus shapes the random draw does not produce in useful quantity,
  // both aimed at what actually breaks an FMA.
  //
  // NEAR-CANCELLATION. c is set to the negation of the product's leading M+1
  // significand bits, so a*b + c is the product's own tail: tiny next to either
  // term, and reached only by an aligner and normaliser that keep the full
  // 2M+2-bit product. A design that rounds the product before adding gets these
  // wrong wholesale. `jit` perturbs the low mantissa bits so the cancellation
  // is partial as well as total.
  //
  // This is INPUT GENERATION, not oracle generation -- rule 11. Nothing here
  // computes what the answer should be; it only chooses operands that make the
  // answer hard.
  function automatic logic [31:0] neg_prod(input logic [1:0] f,
                                           input logic [31:0] av, input logic [31:0] bv,
                                           input logic [31:0] jit);
    int unsigned E, M, bias;
    logic [63:0] pm;
    logic [31:0] ea, eb, ma, mb, mant, ec;
    E = ebits(f); M = mbits(f); bias = (1 << (E-1)) - 1;
    ea = (av >> M) & ((32'd1 << E) - 32'd1);
    eb = (bv >> M) & ((32'd1 << E) - 32'd1);
    ma = av & ((32'd1 << M) - 32'd1);
    mb = bv & ((32'd1 << M) - 32'd1);
    // only meaningful for two normals; otherwise hand back something benign
    if (ea == 0 || eb == 0 || ea >= (32'd1 << E) - 32'd1 || eb >= (32'd1 << E) - 32'd1) begin
      neg_prod = av ^ 32'h8000_0000;
    end else begin
      pm = 64'((ma | (32'd1 << M))) * 64'((mb | (32'd1 << M)));
      ec = ea + eb - 32'(bias);
      if (pm[2*M+1]) begin pm = pm >> 1; ec = ec + 32'd1; end
      mant = 32'(pm >> M) & ((32'd1 << M) - 32'd1);
      if (ec == 0 || ec >= (32'd1 << E) - 32'd1) neg_prod = av ^ 32'h8000_0000;
      else neg_prod = (32'(~(av[E+M] ^ bv[E+M])) << (E+M)) | (ec << M)
                      | ((mant ^ (jit & 32'd7)) & ((32'd1 << M) - 32'd1));
    end
  endfunction

  // UNDERFLOW BAND. Exponents arranged so the product lands within a few ulps
  // of the smallest normal, with mantissa bits guaranteeing inexactness. UF is
  // "tiny AND inexact" and a uniform draw almost never lands there -- the first
  // capture produced 27 underflows in 3800 vectors.
  function automatic logic [31:0] tiny_pair(input logic [1:0] f, input logic [31:0] s,
                                            input logic [31:0] other_e);
    int unsigned E, M, bias;
    logic [31:0] e;
    E = ebits(f); M = mbits(f); bias = (1 << (E-1)) - 1;
    // want ea + eb - bias ~= 1, so eb ~= bias + 1 - ea
    e = 32'(bias) + 32'd1 - other_e + (32'(s[3:0]) % 32'd5) - 32'd2;
    if (e == 0 || e >= (32'd1 << E) - 32'd1) e = 32'd1;
    tiny_pair = (32'(s[31]) << (E+M)) | (e << M)
                | ((32'(s[22:0]) | 32'd1) & ((32'd1 << M) - 32'd1));
  endfunction

  // Pack an operand into the WIDTH-bit word. Bits above the lanes in use are
  // GARBAGE on purpose -- the contract says they are ignored, so a design that
  // lets them reach the datapath is caught rather than excused. Lanes above the
  // first are decorrelated from lane 0 (they are separate draws), which is what
  // makes a design that computes one lane and replicates it visible.
  function automatic logic [WIDTH-1:0] pack(input logic [1:0] f, input logic v,
                                            input logic [31:0] s0);
    int unsigned FW, N, i;
    logic [31:0] t;
    logic [WIDTH-1:0] r;
    FW = fwidth(f); N = lanes(f, v);
    r = '0; t = s0;
    for (i = 0; i < N; i++) begin
      r[i*FW +: 32] = r[i*FW +: 32] | (t & ((32'd1 << FW) - 32'd1));
      t = nxt(nxt(t ^ 32'h9E37_79B9));        // decorrelate lane to lane
    end
    for (i = N*FW; i < WIDTH; i++) r[i] = ~r[i % (N*FW)];   // garbage above
    pack = r;
  endfunction

  // ---- in-flight queue and the one monitor ----------------------------------
  typedef struct { logic [1:0] f; logic v; logic [2:0] r;
                   logic [WIDTH-1:0] a, b, c; } rec_t;
  rec_t q[$];
  int fd, nvec;

  always @(negedge clk) if (rst_n) begin
    rec_t e;
    logic [287:0] w;
    if (iv && ir) q.push_back('{fmt, vec, rnd, a, b, c});
    if (ov && orr) begin
      if (q.size() == 0) begin
        $display("CAPTURE: result with nothing in flight -- harness defect");
        $finish;
      end
      e = q.pop_front();
      w = {20'b0, e.f, (WIDTH == 64), e.v, e.r,
           64'(e.a), 64'(e.b), 64'(e.c), 64'(res), fl};
      $fwrite(fd, "%072h\n", w);
      nvec++;
    end
  end

  task automatic issue(input logic [1:0] f, input logic v, input logic [2:0] r,
                       input logic [WIDTH-1:0] av, input logic [WIDTH-1:0] bv,
                       input logic [WIDTH-1:0] cv);
    @(negedge clk);
    fmt = f; vec = v; rnd = r; a = av; b = bv; c = cv; iv = 1'b1;
    #0;
    while (!ir) begin @(negedge clk); #0; end   // the next posedge takes it
    @(negedge clk);
    iv = 1'b0;
  endtask

  int i, j, k, f, vsel, nv;
  logic [31:0] x, y, z;
  string fname;
  initial begin
    iv = 0; orr = 1'b1; vec = 0; fmt = 0; a = 0; b = 0; c = 0; rnd = 0; nvec = 0;
    fname = $sformatf("vectors/vectors_w%0d.hex", WIDTH);
    fd = $fopen(fname, "w");
    if (fd == 0) begin $display("CAPTURE: cannot open %s", fname); $finish; end
    repeat (8) @(negedge clk); rst_n = 1; repeat (4) @(negedge clk);

    // ---- directed corners, every format, every rounding mode ---------------
    // vectorial FP32 exists only where WIDTH leaves room for more than one lane
    for (f = 0; f < 3; f++) begin
      nv = ((f == 0) && (WIDTH == 32)) ? 1 : 2;
      for (vsel = 0; vsel < nv; vsel++)
        for (k = 0; k < 5; k++)
          for (i = 0; i < int'(NCORNER); i++)
            for (j = 0; j < int'(NCORNER); j = j + 5) begin
              roll();
              x = corner(2'(f), i); y = corner(2'(f), j);
              z = corner(2'(f), (i + j) % NCORNER);
              issue(2'(f), 1'(vsel), 3'(k),
                    pack(2'(f), 1'(vsel), x),
                    pack(2'(f), 1'(vsel), y),
                    pack(2'(f), 1'(vsel), z));
            end
    end

    // ---- randomized ---------------------------------------------------------
    for (f = 0; f < 3; f++) begin
      nv = ((f == 0) && (WIDTH == 32)) ? 1 : 2;
      for (vsel = 0; vsel < nv; vsel++)
        for (i = 0; i < 400; i++) begin
          roll(); x = rnd_fp(2'(f), lfsr);
          roll(); y = rnd_fp(2'(f), lfsr);
          roll(); z = rnd_fp(2'(f), lfsr);
          issue(2'(f), 1'(vsel), 3'(i % 5),
                pack(2'(f), 1'(vsel), x),
                pack(2'(f), 1'(vsel), y),
                pack(2'(f), 1'(vsel), z));
        end
    end

    // ---- near-cancellation band --------------------------------------------
    for (f = 0; f < 3; f++) begin
      nv = ((f == 0) && (WIDTH == 32)) ? 1 : 2;
      for (vsel = 0; vsel < nv; vsel++)
        for (i = 0; i < 250; i++) begin
          roll(); x = rnd_fp(2'(f), lfsr);
          roll(); y = rnd_fp(2'(f), lfsr);
          roll(); z = neg_prod(2'(f), x, y, lfsr);
          issue(2'(f), 1'(vsel), 3'(i % 5),
                pack(2'(f), 1'(vsel), x),
                pack(2'(f), 1'(vsel), y),
                pack(2'(f), 1'(vsel), z));
        end
    end

    // ---- underflow band -----------------------------------------------------
    for (f = 0; f < 3; f++) begin
      nv = ((f == 0) && (WIDTH == 32)) ? 1 : 2;
      for (vsel = 0; vsel < nv; vsel++)
        for (i = 0; i < 250; i++) begin
          roll(); x = rnd_fp(2'(f), lfsr);
          roll(); y = tiny_pair(2'(f), lfsr,
                                (x >> mbits(2'(f))) & ((32'd1 << ebits(2'(f))) - 32'd1));
          roll(); z = (i % 3 == 0) ? 32'd0 : rnd_fp(2'(f), lfsr);
          if (i % 3 == 1) z = neg_prod(2'(f), x, y, lfsr);
          issue(2'(f), 1'(vsel), 3'(i % 5),
                pack(2'(f), 1'(vsel), x),
                pack(2'(f), 1'(vsel), y),
                pack(2'(f), 1'(vsel), z));
        end
    end

    // drain everything still in flight before closing the file
    while (q.size() != 0) @(negedge clk);
    repeat (4) @(negedge clk);
    $fclose(fd);
    $display("CAPTURE: wrote %0d vectors", nvec);
    $finish;
  end

  initial begin
    #40_000_000;
    $display("CAPTURE: watchdog at nvec=%0d inflight=%0d fmt=%0d vec=%b ir=%b ov=%b",
             nvec, q.size(), fmt, vec, ir, ov);
    $fclose(fd);
    $finish;
  end
endmodule
