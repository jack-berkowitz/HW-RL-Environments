// =============================================================================
// d_ai01 SECOND SOURCE -- fp16_gemm_array, independent implementation.
//
// Not a submission. Not scored. Written as an ORACLE: a second opinion on what
// the contract requires, derived from the contract text alone.
//
// -----------------------------------------------------------------------------
// PINNED INPUTS
// -----------------------------------------------------------------------------
// Derived against commit  9da6e62bfecb8d5a94dcf366c67ea5da07729d74
//
//   domains/ai_accel/design/d_ai01_fp16_gemm_array/spec/fp16_gemm_array_iface.sv
//     804 lines  sha256 7c0b815de4ac8ea0a2a99f17f434e402b224d176ca49c1d95087fd567e376583
//   domains/ai_accel/design/d_ai01_fp16_gemm_array/probe/PASTE.md
//     843 lines  sha256 7a05fe8803cdb8c9547778382e8395f6a1331047c4a48e1226f6e3a423df51f8
//   RULES.md
//     1021 lines sha256 7cd223f6c64b033932df9159f53da1c12d943738f0b1686f21ff7bdec5182863
//   CONVENTIONS.md
//     935 lines  sha256 108b4ee8093422df6165e0be254e7fcdb914830b43030b6764a1598e3478ffa5
//
// PASTE.md's fenced systemverilog block and spec/fp16_gemm_array_iface.sv are
// BYTE-IDENTICAL at this commit (verified by diff, 0 differences, both 804
// lines). There is one contract text, not two that could drift apart.
//
// All reads were done through `git show <SHA>:<path>`, never through the
// working tree, because the tree is written concurrently by other agents.
//
// -----------------------------------------------------------------------------
// CLAUSE-REGION HASHES -- sha256 of the exact clause text this work rests on
// -----------------------------------------------------------------------------
// Regions are contiguous line spans of the pinned iface.sv, each running from
// its clause's first line to the line before the next clause. Recomputed and
// re-verified immediately before this file was reported; a changed hash voids
// the derivation rather than amending it.
//
//   F1        486a96d6f5cc120914a7840928542f683167d938bd86eb734fe29873e76b0eac
//   F2        f3bfe700d13281fe5523b0a1beae7e6458dee8359cb8ab5b9bbcf40ef16ff4c7
//   F3        9f11b9901f6de665f6364420b54e098f5f46d229ecb0f4089a6dd753d50aef71
//   V1        900f08ed998c4d39409b20c52ed08be294bb356779dc3342374aef64a8702db1
//   V2        ff181490824f038b09a2ca83abc4af6bf509f259c0eee581b8f5fcf76a4656c3
//   V3        2d4d0ec3ea996db99c39437a817363373d82e30280eeb9953ac0aac1cf1720d4
//   Aanon     0e1c467b0e5a3ec5b23af953b1ebbb2d26b9547e0295a448a9d8dfebfb8db845
//   A1        70265d45b59635e3ecf24aa7cd9fd294402ca8d98f1ce215bca39756d3da6b12
//   A2        0dabd09d16070a7bfbf382ce2dd1bd8bb0088f51fbf74561c7026f0b5601a302
//   A3        6a4fcd5d4eea731dd10c0d441ca78b6aa8147c4c4702877f3739bb107ec26f81
//   A4        e671740ca94b9dc9c41587ac75c528b6f9c73d7cd0fb2b96bd2910063abcfdd7
//   A5        c80fdfe6959a79fb961a84258ba54356a0464fc736c8bf0fe5fb34c9c0244ae3
//   A6        94db18cebe21eb0bd7456453edf60f5f930dfc986fa7742326d08c7f98a09a94
//   A7        9f06a378ab1580560fef61c383cc7b68f7f9f673e99058b546a25667ad6756ad
//   A8        54dc414236243bbee85b9b239e9bfd077e11c957ef3049cd7001ac4988df2b1c
//   A9        c706cd0763330be828d5422c9075667578f8807554434b15b6338aeaacb00daa
//   A10       2fbafec30dab232de5c10f9d747caab5cae0420a52743d8872579d9a64afcaaf
//   C1        290aa1dc1cefe7b6bdc90d83170eae26887b40883c89b977506379fdbd17e5a7
//   C2        f4d272faa4784b9598a7620c493931ea6f471d6ef121f5a7bd26cc91c02e06af
//   C3        9142f9c815b2f135c1aca6f5dc98244d030465663108df704c9aa9f1d4dc41de
//   C4        e4281b5a9d84d4202c2cf76ec611f4201ce806a2467de35be74d7a22f62a0ce8
//   C5        9890933dcfee7f7bf9469123e92e5f9090185e60cf52783ce742be999ff7f005
//   L1        c1bf1251d861e87029ebf28bc1976b2cae04b254752c83e4a6d1a6f7b4a671d6
//   L2        86bc0a5834a6a1ae9f3f8610bda5ba41fb01c13c13a2595d16651e8b03df4a89
//   L3        d21180fb00fc26e65a1bbb8f806eafd93bfdcb656aad97861c4094b68219a322
//   P1        519ae3beed01d4f2aba0848c7ad3aef96bf5e43e2c38a6716125115c46b1f78b
//   P2        cab20168c75cfc1eb9206a332af82661d2dabbb41288cff5dd3182bf219308e6
//   T3        cca8cdd7af0f93c300d4989abc7004ef3f2c6fc2ed079f963489bb4f149d1830
//   T4        7bf1b8cf979c179bb81e6ae5b4aa9ee7dfecb6c9c69e6a77d5cbd9e607ee0bef
//   T5        8704a93fef24e9a5abf27433fd7c09271051d8e6c4993ddc6243e36df28b6dcd
//   MODDECL   fbb3415fc98f3daa2f0c9d2cda09c9a530cf1fd2de1fa82b3981a6c2928b3046
//
// -----------------------------------------------------------------------------
// THE TEXT MOVED DURING THIS DERIVATION -- TWO REGIONS ARE VOID
// -----------------------------------------------------------------------------
// HEAD advanced 9da6e62 -> e312ee3 while this file was being written. Commit
// 1bbc5bd "The simultaneity premise is measured, the maintenance grep is
// narrowed, and the narrowing costs the grep" edited the contract: 804 -> 818
// lines, in two hunks located BY LINE NUMBER ONLY -- the new prose was not
// read, because a moved text voids the work rather than amending it.
//
//   a 10-line insertion at old line 266  -> inside C2 (247-344)
//   a 3->7 line replacement at old 453   -> inside C5 (431-497)
//
//   VOID   : C2, C5. With them decisions D5, D6, D7 and finding CF-1.
//   STANDS : all of F, V, A1-A10, C1, C3, C4, L, P, T and the port
//            declaration. Every arithmetic and latency clause is intact.
//
// A SECOND EDIT LANDED LATER, commit 77ac97f "CF-4 closed by recomputation,
// three items recorded open, ...", which moved C3: one line at old 361 plus an
// 8-line insertion after old 365, again located by line number only. That is
// THIS DERIVATION'S OWN FINDING being landed -- C3 quoted dfb as 15/31 when
// those are the d(0) values. So the tally at HEAD 2e1d63d is:
//
//   MOVED  : C2, C3, C5.   INTACT : the other 28 of 31 regions.
//
// C3 IS A WEAKER VOID THAN C2 AND C5, AND IT IS RESOLVABLE BY ONE LOOKUP.
//
// The edit closed a defect this reader reported, BY RECOMPUTATION rather than
// by altering the relation. The relation is what this implementation encodes:
//
//     dfb = D*(HEIGHT-1) + 4 = d(0) + 1
//
// measured in this design as 16 enabled ticks at HEIGHT=4 and 32 at HEIGHT=8.
// The pinned C3 stated that relation twice, with its derivation, and closed it
// independently through its own transition window d(0) + dfb = 2*D*(H-1)+7,
// which forces dfb = 16 at H=4 from d(0) = 15. Only the quoted numbers beside
// it were stale, and recomputing stale numbers from a correct relation lands
// on 16 and 32.
//
//   >>> CHECK BEFORE RUNNING THE COMPARISON: does the NEW C3 still state
//   >>> dfb = D*(HEIGHT-1)+4, equivalently d(0)+1?
//   >>>
//   >>>   IF YES  -- C3 is NOT void for this work. The relation is unchanged,
//   >>>             this implementation encodes it, and any dfb disagreement
//   >>>             is a real finding rather than a stale derivation.
//   >>>   IF NO   -- C3 is void exactly as C2 and C5 are, the accumulate
//   >>>             behaviour here is derived against superseded text, and it
//   >>>             needs a fresh clean reader like they do.
//
// This reader has not read the new C3 and will not. The lookup is one line and
// belongs to whoever runs the comparison.
//
// The flush behaviour in this file (D5: z_o forced combinationally, so it
// reads +0 at tick 1 of an assertion) is therefore FLAGGED, NOT CORRECTED.
// Correcting it would mean adjusting to a text this reader is not entitled to
// have read. C2 needs a redo by a FRESH clean reader, not by this one.
//

// -----------------------------------------------------------------------------
// DISCLOSURE
// -----------------------------------------------------------------------------
// The author of this file has NOT seen, in this session or any prior one:
//   (a) ref/ or any recorded value the reference produces;
//   (b) any statement of reference behaviour outside the contract text above;
//   (c) any submission, prior second source, or alternative implementation;
//   (d) any mismatch enumeration, disagreement count, verdict, or score;
//   (e) any content from MEASUREMENTS.md, headings included.
//
// INCIDENTAL EXPOSURE, disclosed rather than adjudicated:
//
//   1. CONTROL FILENAMES. `git ls-tree` run to pin the tree listed
//      controls/nc_{a..i}_*.sv. Those names describe each mutant's defect and
//      so, by negation, assert things about the reference: flush_subnormal,
//      overflow_always_inf, positive_zero_only, reversed_chain,
//      height_blind_depth, echo_band_only, band_unstable, stuck_output,
//      extra_pipe_stage. No file in controls/ was opened. Every axis those
//      names touch is ALSO pinned explicitly by the contract (F1, A5, A6, A8,
//      A2, P1), so no decision below rests on them -- but the strength
//      statement marks which decisions they overlap.
//   2. COMMIT SUBJECT LINES for other tasks (ca04/ca05/ca06) present in the
//      session's git status block. No d_ai01 content.
//   3. Session memory index naming other tasks. No d_ai01 content.
//   4. RULES.md line 923 names d_ai01 once, in a table cell reading
//      "HEIGHT load-bearing? | a capability-reduced control (nc_g)". Read
//      incidentally while screening RULES.md for d_ai01 mentions. It restates
//      P1, which already says HEIGHT sets the observable schedule.
//   5. D_AI01_SPEC_FIX.md exists at repo root. NOT opened; not in scope.
//
// THE ALLOWED SPEC ITSELF CARRIES TWO DISAGREEMENT COUNTS -- A10's "roughly
// 2900 of 3400 cycles" and C3's "three independent implementations ... all
// differed from the reference". Both are attached to readings the normative
// text now pins outright, so neither adds information beyond the clause. Noted
// because a contamination protocol that forbids (d) while the mandated input
// contains (d) is under-specified, not because it changed anything here.
//
// -----------------------------------------------------------------------------
// PRE-COMMITMENT, recorded before the first line of RTL was written
// -----------------------------------------------------------------------------
// This implementation will not be tuned toward any other implementation,
// result, or expectation, and will not be revised after any comparison. If it
// disagrees with the reference, a submission, or a scoring run, that
// disagreement is a datum ABOUT THE CONTRACT TEXT and gets reported as one.
// Where the text left latitude a deliberately different legal choice was taken
// and logged. Where the text does not determine behaviour at all, something
// legal was implemented and marked free -- no microarchitecture was invented
// to close a gap the contract declines to model.
//
// COMPANION FILES, all under inbox/:
//   d_ai01_COMPARISON_TRIAGE.md  READ FIRST if you are running the comparison.
//                                What each disagreement shape implies, in the
//                                order to test it, plus the C3 lookup above.
//   d_ai01_TEXT_DEFECTS.md       The three undecided points in the contract,
//                                written standalone for a fresh reader, with
//                                runnable witnesses W1-W10.
//   d_ai01_T5_CHECK.md           The slang gate, which has NOT been run.
//   d_ai01_second_source_REPORT.md   Pinning, strength statement, freeze.
//
// The free-choice log and the frozen disagreement predictions are BELOW, in
// this file, deliberately -- a prediction that lives only in a commentary file
// can be edited after a result lands and nothing would show it.
//
// -----------------------------------------------------------------------------
// FREE-CHOICE LOG -- every point at which the text did not determine the answer
// -----------------------------------------------------------------------------
// Each entry: the choice taken, the alternative rejected, and NI -- whether the
// decision touches an axis named by the leaked control filenames (DISCLOSURE
// item 1), so the discount can be read off directly rather than reconstructed.
//
// D1  SAMPLING CONVENTION -- inference, and the most load-bearing line here.
//     TAKEN     "signal at enabled tick t" is its value at the sampling instant
//               of edge t, so d(k) is the COUNT OF ENABLED-TICK REGISTERS
//               between an input and z_o.
//     REJECTED  the post-edge convention, under which every path needs d(k)+1
//               registers and L3's 15 becomes 16 registers of latency.
//     NI        pipeline depth (nc_b "extra_pipe_stage"). The name says a
//               mutant carries one extra stage; it does not say where the count
//               is anchored, which is the open question.
//
// D2  REGISTER SPLIT -- free under G4.
//     TAKEN     1 operand-input register per stage + 3 partial-sum registers,
//               2 on the last stage.  1+3 = 4 = D,  1+2 = 3 = d(H-1).
//     REJECTED  0 input registers and 4 (resp. 3) partial-sum registers --
//               identical d(k) and dfb. Deliberately the less obvious split, so
//               a structural disagreement shows up as one.
//     NI        pipeline depth (nc_b). Same caveat as D1.
//
// D3  EXACT FIXED-POINT FMA -- free under G4.
//     TAKEN     exact product and exact addend on a common 2^-48 grid, 84-bit
//               exact signed sum, then ONE rounding. No alignment shift, no
//               normalisation loop, no intermediate rounding.
//     REJECTED  a conventional align/normalise datapath.
//     NI        none.
//
// D4  LEADING-ONE SEARCH -- free, constrained by T5.
//     TAKEN     chunked 7 x 12 = 19 iterations; rows and stages are `generate`,
//               never procedural loops.
//     REJECTED  an 84-iteration per-bit scan: 84 x HEIGHT x WIDTH approaches
//               slang's 4000 unroll budget at HEIGHT=8.
//     NI        none.
//
// D5  FLUSH AND z_o AT TICK 1 -- **VOID**, C2 moved.
//     TAKEN     z_o forced COMBINATIONALLY to +0 while flush_i & gate, so it
//               reads +0 at tick 1 of an assertion rather than from tick 2.
//     REJECTED  registered-only forcing, +0 from tick 2. Both were legal
//               against the pinned C2 -- this was finding CF-1.
//     NI        stuck output (nc_a). Disregard: the region is void.
//
// D6  FLUSH SCOPE -- **VOID**, C2 moved.
//     TAKEN     flush zeroes the operand input registers as well as the
//               partial sums.
//     REJECTED  zero only the partial sums. Unobservable either way.
//     NI        none.
//
// D7  STATUS FREEZE -- **VOID**, C2 moved.
//     TAKEN     the whole flag path freezes during an assertion.
//     REJECTED  freeze only the output register. With one flag register per
//               stage the two coincide, so this was not really available.
//     NI        possibly the "band" output (nc_h "echo_band_only", nc_i
//               "band_unstable") IF "band" denotes status_o. What "band" means
//               cannot be resolved without reading, and will not be. Treat D7
//               as possibly name-informed.
//
// D8  TININESS DETECTION -- FREE. Nothing in the contract names it.
//     TAKEN     tininess detected BEFORE rounding.
//     REJECTED  after rounding. Deliberately the opposite of the project's
//               other spec (d_dsp02 says "after rounding"), so the choice is
//               visible rather than inherited.
//     NI        subnormals (nc_c "flush_subnormal"). The name says the
//               reference does not flush subnormals, which F1 states outright.
//               It says nothing about the UF flag at the subnormal/normal
//               boundary, which is the open question.
//
// D9  NaN HANDLING -- FREE. Unmentioned.
//     TAKEN     ANY NaN operand, quiet or signalling, delivers 0x7E00 with NO
//               flag, checked BEFORE inf x 0. So fma(inf, 0, qNaN) raises
//               nothing.
//     REJECTED  sNaN raises NV; or inf x 0 checked first so that case raises
//               NV. IEEE 754-2019 makes the ordering implementation-defined.
//     NI        none.
//
// D10 INFINITY MINUS INFINITY -- INFERRED. Unmentioned.
//     TAKEN     infinite product plus infinite addend of opposite sign delivers
//               0x7E00 and raises NV.
//     REJECTED  deliver an infinity, or raise nothing.
//     NI        overflow (nc_d "overflow_always_inf"). The name says the
//               reference does not always deliver infinity on overflow, which
//               A5's table already states; it says nothing about an infinite
//               ADDEND.
//
// D11 SIGN OF AN EXACT ZERO -- INFERRED beyond A8.
//     TAKEN     A8's rule generalised to ANY exact zero, including cancellation
//               of non-zeros; two zeros of the same sign keep that sign in
//               every mode.
//     REJECTED  A8 read literally, leaving cancellation unspecified.
//     NI        zero sign (nc_e "positive_zero_only"). The name says the
//               reference emits signed zeros, which A6 and A8 already state; it
//               says nothing about which zeros A8's rule reaches.
//
// D12 OVERFLOW CONDITION -- INFERRED. See TEXT_DEFECTS defect 2.
//     TAKEN     IEEE's condition: overflow iff the result rounded with
//               UNBOUNDED EXPONENT exceeds 65504 in magnitude. Mode- and
//               sign-dependent.
//     REJECTED  a single constant threshold applied to the EXACT result.
//     NI        overflow (nc_d). The name addresses the delivered VALUE, and
//               the two readings agree on every delivered value. They differ
//               only in the OF bit, which the name does not reach.
//
// D13 A6 TABLE SCOPE -- INFERRED. See TEXT_DEFECTS defect 1.
//     TAKEN     A6's table read as the worked example at 2^-25 under correct
//               rounding.
//     REJECTED  the table applied literally to every magnitude below 2^-24.
//     NI        subnormals (nc_c), and possibly "band" (nc_h / nc_i) if band
//               denotes the subnormal range. Same caveat as D8: the names
//               address flushing, not scope.
//
// D14 rnd_i VALUES 5-7 -- free. TAKEN: behave as RNE. F3 imposes nothing.
//     REJECTED: anything else. NI: none.
//
// D15 accumulate_i SAMPLING -- free. TAKEN: sampled at stage 0's own tick.
//     REJECTED: any other point; C3 leaves all transitions unscored. NI: none.
//
// D16 UNIFORM PIPE DEPTH -- free. TAKEN: a 3-deep pipe declared at every stage,
//     last stage taps [1], pz[H-1][2] driven but unused -- wellformedness (C5)
//     over minimality. REJECTED: per-stage depths. NI: pipeline depth (nc_b).
//
// NOT DECISIONS, recorded because a control name touches them: CHAIN ORDER
// (nc_f "reversed_chain") is FORCED by A2, written as equations, and
// HEIGHT-DEPENDENCE (nc_g "height_blind_depth") is FORCED by P1 and A3, written
// as a formula and two tables. No latitude was exercised at either, so there is
// nothing there to discount.
//
// -----------------------------------------------------------------------------
// RANKED DISAGREEMENT PREDICTIONS -- frozen, in the artifact, before comparison
// -----------------------------------------------------------------------------
// Recorded HERE rather than only in the report so the prediction cannot be
// back-fitted to a result. No comparison against ref/ or tb/ has been run by
// this author, none will be, and this author will not see the outcome.
//
//   1. D8  tininess. A single UF bit, on exact 2047 x 2^-25 under RNE.
//   2. D9  sNaN, and the NaN-versus-invalid ordering. Flags only.
//   3. D12 the OF bit for exact magnitudes in (65504, 65536) under RTZ (both
//          signs), RDN positive, RUP negative. Delivered values agree.
//   4. D10 infinity minus infinity.
//   5. D1  the sampling convention. THIS ONE HAS A SIGNATURE: a UNIFORM
//          ONE-TICK SHIFT on everything -- every row, every stage, both
//          heights -- with the arithmetic otherwise exact. If the disagreement
//          looks like that, it is D1 and not an arithmetic defect. Check for it
//          before anything else.
//   6. D5  flush at tick 1 only. VOID region; disregard.
//
// A DIAGNOSTIC THAT COMES FREE FROM THE RANKING: predictions 1-4 are FLAG-ONLY.
// They move status_o and leave z_o identical. So if z_o disagrees broadly while
// status_o does not, NONE of 1-4 is the cause and the fault is D1 or D2 --
// structural, not arithmetic. If status_o disagrees while z_o matches, it is
// 1-4 and the arithmetic core is sound.
// =============================================================================

module fp16_gemm_array #(
  parameter int unsigned HEIGHT = 8,
  parameter int unsigned WIDTH  = 8
) (
  input  logic                                     clk_i,
  input  logic                                     rst_ni,
  input  logic [WIDTH-1:0][HEIGHT-1:0][15:0]       x_i,
  input  logic            [HEIGHT-1:0][15:0]       w_i,
  input  logic [WIDTH-1:0]            [15:0]       y_i,
  output logic [WIDTH-1:0]            [15:0]       z_o,
  input  logic [2:0]                               rnd_i,
  input  logic                                     accumulate_i,
  input  logic [WIDTH-1:0]                         row_clk_gate_en_i,
  input  logic                                     reg_enable_i,
  input  logic                                     flush_i,
  output logic [WIDTH-1:0][HEIGHT-1:0][4:0]        status_o
);

  // ---------------------------------------------------------------------------
  // Register budget, derived from A3 / L1 / L2 / L3 and from decision D1.
  //
  // Under D1 a signal "at enabled tick t" is its value at the sampling instant
  // of edge t, so the operand-to-output delay in A3 is exactly the NUMBER OF
  // ENABLED-TICK REGISTERS between an input and z_o. That gives
  //     d(k) = 4*(H-1-k) + 3      registers from x_i[k] to z_o.
  //
  // This build spends that budget as one OPERAND-INPUT register per stage plus
  // a partial-sum pipe behind each FMA (decision D2):
  //
  //   x_i[k],w_i[k],rnd_i -> ireg -> FMA_k -> pz[k][0..2] -> ireg of stage k+1
  //                          (1)              (3)
  //   last stage:            ireg -> FMA -> pz[H-1][0..1] -> z_o
  //                          (1)            (2)
  //
  //   per non-last stage: 1 + 3 = 4 == D            (L1)
  //   last stage:         1 + 2 = 3 == d(H-1)       (A3)
  //   total:              4*(H-1) + 3 == d(0)       (L3)
  //
  // The feedback of C3 adds exactly one more register (zfb), giving
  //   dfb = d(0) + 1 = 4*(H-1) + 4.
  //
  // Flags take the SHORT path of A10, which is not the z path: one operand
  // register plus one flag register is 2 enabled ticks at every k.
  // ---------------------------------------------------------------------------

  genvar gr, gk;
  generate
    for (gr = 0; gr < int'(WIDTH); gr++) begin : g_row

      logic        row_en;      // A1: an enabled tick for this row
      logic        row_clr;     // C2: flush, but only where the clock is on
      logic        st_en;       // C2: status advances only outside an assertion
      logic [15:0] ireg_x [HEIGHT];
      logic [15:0] ireg_w [HEIGHT];
      logic [2:0]  ireg_r [HEIGHT];
      logic [15:0] ireg_c [HEIGHT];
      logic [15:0] fma_z  [HEIGHT];
      logic [4:0]  fma_f  [HEIGHT];
      logic [15:0] pz     [HEIGHT][3];
      logic [4:0]  sreg   [HEIGHT];
      logic [15:0] zfb;
      logic [15:0] c0_sel;
      logic [15:0] z_row;

      assign row_en  = reg_enable_i & row_clk_gate_en_i[gr];
      assign row_clr = flush_i      & row_clk_gate_en_i[gr];
      assign st_en   = row_en & ~flush_i;

      // C3: accumulate replaces the bias with this row's own delayed z_o.
      assign c0_sel  = accumulate_i ? zfb : y_i[gr];

      assign z_row   = pz[HEIGHT-1][1];

      // C2 paragraph 1, taken literally: z_o reads +0 for as long as flush_i is
      // asserted, including the first enabled tick of the assertion. See D5.
      assign z_o[gr] = row_clr ? 16'h0000 : z_row;

      for (gk = 0; gk < int'(HEIGHT); gk++) begin : g_stage
        fp16_fma_exact u_fma (
          .a_i   (ireg_x[gk]),
          .b_i   (ireg_w[gk]),
          .c_i   (ireg_c[gk]),
          .rnd_i (ireg_r[gk]),
          .z_o   (fma_z[gk]),
          .fl_o  (fma_f[gk])
        );
        assign status_o[gr][gk] = sreg[gk];
      end

      always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
          // V2: asynchronous, and it is the only thing that reaches a gated row.
          for (int k = 0; k < int'(HEIGHT); k++) begin
            ireg_x[k] <= 16'h0000;
            ireg_w[k] <= 16'h0000;
            ireg_r[k] <= 3'b000;
            ireg_c[k] <= 16'h0000;
            pz[k][0]  <= 16'h0000;
            pz[k][1]  <= 16'h0000;
            pz[k][2]  <= 16'h0000;
            sreg[k]   <= 5'b00000;
          end
          zfb <= 16'h0000;
        end
        else begin
          // C2 outranks C1: the clear does not need reg_enable_i.
          // C4 outranks both: a gated row is untouched by either.
          if (row_clr) begin
            for (int k = 0; k < int'(HEIGHT); k++) begin
              ireg_x[k] <= 16'h0000;
              ireg_w[k] <= 16'h0000;
              ireg_r[k] <= 3'b000;
              ireg_c[k] <= 16'h0000;
              pz[k][0]  <= 16'h0000;
              pz[k][1]  <= 16'h0000;
              pz[k][2]  <= 16'h0000;
            end
            zfb <= 16'h0000;
          end
          else if (row_en) begin
            for (int k = 0; k < int'(HEIGHT); k++) begin
              ireg_x[k] <= x_i[gr][k];
              ireg_w[k] <= w_i[k];
              ireg_r[k] <= rnd_i;     // A4: rnd as it stands at THIS stage's tick
              pz[k][0]  <= fma_z[k];
              pz[k][1]  <= pz[k][0];
              pz[k][2]  <= pz[k][1];
              if (k == 0) ireg_c[k] <= c0_sel;
              else        ireg_c[k] <= pz[k-1][2];
            end
            zfb <= z_row;
          end

          // C2: the flag path suspends on the SAME edge that first sees flush,
          // so status_o(1) is still A10's value and status_o(t>=2) holds it.
          if (st_en) begin
            for (int k = 0; k < int'(HEIGHT); k++) begin
              sreg[k] <= fma_f[k];
            end
          end
        end
      end

    end
  endgenerate

endmodule

// =============================================================================
// fp16_fma_exact -- combinational binary16 fused multiply-add, one rounding.
//
// Method: form the EXACT product and the EXACT addend in a common fixed-point
// grid whose LSB is 2^-48 (the smallest product exponent: 2^-24 * 2^-24), add
// them exactly, then round the exact 84-bit sum ONCE under rnd_i. No alignment
// shift, no normalisation loop, no intermediate rounding anywhere.
//
// Widths, derived rather than guessed:
//   product  significand 11x11 -> 22 bits, exponent in [-48, 10]
//            fixed-point shift in [0, 58], top bit index <= 79
//   addend   significand 11 bits, exponent in [-24, 5]
//            fixed-point shift in [24, 53], top bit index <= 63
//   sum      |sum| < 2^80 + 2^64 < 2^81, so 84 signed bits is comfortable.
// =============================================================================
module fp16_fma_exact (
  input  logic [15:0] a_i,
  input  logic [15:0] b_i,
  input  logic [15:0] c_i,
  input  logic [2:0]  rnd_i,
  output logic [15:0] z_o,
  output logic [4:0]  fl_o     // {NV, DZ, OF, UF, NX}, NV in bit 4
);

  localparam int FXW = 84;
  localparam int NCH = 7;      // 7 chunks of 12 == 84; keeps the leading-one
  localparam int CHW = 12;     // search at 19 iterations, not 84 (clause T5)

  localparam logic [FXW-1:0] FX_ONE = {{(FXW-1){1'b0}}, 1'b1};

  localparam logic [2:0] RNE = 3'd0;
  localparam logic [2:0] RTZ = 3'd1;
  localparam logic [2:0] RDN = 3'd2;
  localparam logic [2:0] RUP = 3'd3;
  localparam logic [2:0] RMM = 3'd4;

  logic              sa, sb, sc, sp;
  logic [4:0]        ea, eb, ec;
  logic [9:0]        fa, fb, fc;
  logic              za, zb, zc;      // is zero
  logic              ia, ib, ic;      // is infinity
  logic              na, nb, nc;      // is NaN (quiet or signalling)
  logic [10:0]       ma, mb, mc;
  logic signed [8:0] xa, xb, xc, xp;
  logic [21:0]       mp;
  logic [6:0]        shp, shc;
  logic [FXW-1:0]    pfx, cfx, sumu, mag, lowmask;
  logic signed [FXW-1:0] pfs, cfs, sumfx;
  logic              res_sgn, sum_zero, prod_zero, both_zero, zero_sgn;
  logic [2:0]        hi_ch;
  logic [3:0]        hi_bt;
  logic [6:0]        base, topbit, qsh;
  logic [CHW-1:0]    ch;
  logic signed [8:0] ev, ev_f;
  logic [11:0]       trunc, sig;
  logic              rbit, sticky, inex, inc, sub_path, ovf, want_inf;
  logic [4:0]        e_enc;
  logic [15:0]       z_norm, z_sub, z_ovf;

  // --- decode (F1, F2) ----------------------------------------------------
  assign sa = a_i[15];  assign ea = a_i[14:10];  assign fa = a_i[9:0];
  assign sb = b_i[15];  assign eb = b_i[14:10];  assign fb = b_i[9:0];
  assign sc = c_i[15];  assign ec = c_i[14:10];  assign fc = c_i[9:0];

  assign za = (ea == 5'd0)  && (fa == 10'd0);
  assign zb = (eb == 5'd0)  && (fb == 10'd0);
  assign zc = (ec == 5'd0)  && (fc == 10'd0);
  assign ia = (ea == 5'd31) && (fa == 10'd0);
  assign ib = (eb == 5'd31) && (fb == 10'd0);
  assign ic = (ec == 5'd31) && (fc == 10'd0);
  assign na = (ea == 5'd31) && (fa != 10'd0);
  assign nb = (eb == 5'd31) && (fb != 10'd0);
  assign nc = (ec == 5'd31) && (fc != 10'd0);

  // integer significand, and the exponent that scales it. Subnormals fall out
  // of the same expression: E==0 gives significand f and exponent -24, and
  // E==1 gives significand 1024+f and exponent -24 as well.
  assign ma = {(ea != 5'd0), fa};
  assign mb = {(eb != 5'd0), fb};
  assign mc = {(ec != 5'd0), fc};

  // declared at the full signed working width; the only concatenation here
  // widens an UNSIGNED field, per the project convention on signedness.
  assign xa = (ea == 5'd0) ? -9'sd24 : ($signed({4'd0, ea}) - 9'sd25);
  assign xb = (eb == 5'd0) ? -9'sd24 : ($signed({4'd0, eb}) - 9'sd25);
  assign xc = (ec == 5'd0) ? -9'sd24 : ($signed({4'd0, ec}) - 9'sd25);

  // --- exact product and exact sum (A2: one rounding, product not rounded) --
  assign sp  = sa ^ sb;
  assign mp  = ma * mb;
  assign xp  = xa + xb;
  assign shp = 7'(xp + 9'sd48);
  assign shc = 7'(xc + 9'sd48);

  assign pfx = {{(FXW-22){1'b0}}, mp} << shp;
  assign cfx = {{(FXW-11){1'b0}}, mc} << shc;
  assign pfs = sp ? -$signed(pfx) : $signed(pfx);
  assign cfs = sc ? -$signed(cfx) : $signed(cfx);

  assign sumfx    = pfs + cfs;
  assign sumu     = sumfx;
  assign res_sgn  = sumfx[FXW-1];
  assign mag      = res_sgn ? (~sumu + FX_ONE) : sumu;
  assign sum_zero = (sumu == {FXW{1'b0}});

  // --- A8: sign of an exact zero ------------------------------------------
  assign prod_zero = za | zb;
  assign both_zero = prod_zero & zc;
  assign zero_sgn  = (both_zero && (sp == sc)) ? sp : (rnd_i == RDN);

  // --- leading-one position, chunked 7 x 12 -------------------------------
  always_comb begin
    hi_ch = 3'd0;
    for (int ci = 0; ci < NCH; ci++) begin
      if (|mag[ci*CHW +: CHW]) hi_ch = 3'(ci);
    end
  end
  assign base = 7'(hi_ch) * 7'd12;
  assign ch   = mag[base +: CHW];
  always_comb begin
    hi_bt = 4'd0;
    for (int bi = 0; bi < CHW; bi++) begin
      if (ch[bi]) hi_bt = 4'(bi);
    end
  end
  assign topbit = base + {3'd0, hi_bt};

  // --- single rounding (A4), quantum chosen by binade ---------------------
  assign ev       = $signed({2'd0, topbit}) - 9'sd48;
  assign sub_path = (ev < -9'sd14);
  assign qsh      = sub_path ? 7'd24 : 7'(ev + 9'sd38);
  assign trunc    = 12'(mag >> qsh);
  assign rbit     = mag[qsh - 7'd1];
  assign lowmask  = (FX_ONE << (qsh - 7'd1)) - FX_ONE;
  assign sticky   = |(mag & lowmask);
  assign inex     = rbit | sticky;

  always_comb begin
    case (rnd_i)
      RTZ:     inc = 1'b0;
      RDN:     inc = res_sgn      & inex;
      RUP:     inc = (~res_sgn)   & inex;
      RMM:     inc = rbit;
      RNE:     inc = rbit & (sticky | trunc[0]);
      default: inc = rbit & (sticky | trunc[0]);   // 5-7 are free (F3)
    endcase
  end

  assign sig    = trunc + {11'd0, inc};
  assign ev_f   = sig[11] ? (ev + 9'sd1) : ev;     // carry out of the binade
  assign ovf    = (~sub_path) & (ev_f > 9'sd15);
  assign e_enc  = 5'(ev_f + 9'sd15);
  assign z_norm = {res_sgn, e_enc, (sig[11] ? 10'd0 : sig[9:0])};
  assign z_sub  = {res_sgn, 4'd0, sig[10], sig[9:0]};

  // --- A5: delivered value above the representable range ------------------
  always_comb begin
    case (rnd_i)
      RTZ:     want_inf = 1'b0;
      RDN:     want_inf = res_sgn;
      RUP:     want_inf = ~res_sgn;
      default: want_inf = 1'b1;                    // RNE, RMM, and 5-7
    endcase
  end
  assign z_ovf = want_inf ? {res_sgn, 5'h1F, 10'h000}
                          : {res_sgn, 5'h1E, 10'h3FF};

  // --- delivered value and flags ------------------------------------------
  always_comb begin
    if (na | nb | nc) begin
      z_o  = 16'h7E00;  fl_o = 5'b00000;           // A9: NaN operand, no flag
    end
    else if ((ia & zb) | (ib & za)) begin
      z_o  = 16'h7E00;  fl_o = 5'b10000;           // A9: infinity * zero -> NV
    end
    else if (ia | ib) begin
      if (ic && (sc != sp)) begin
        z_o  = 16'h7E00;  fl_o = 5'b10000;         // inf - inf: INFERRED
      end else begin
        z_o  = {sp, 5'h1F, 10'h000};  fl_o = 5'b00000;
      end
    end
    else if (ic) begin
      z_o  = {sc, 5'h1F, 10'h000};  fl_o = 5'b00000;
    end
    else if (sum_zero) begin
      z_o  = {zero_sgn, 15'd0};     fl_o = 5'b00000;   // A8
    end
    else if (ovf) begin
      z_o  = z_ovf;                 fl_o = 5'b00101;   // A5: OF and NX
    end
    else if (sub_path) begin
      z_o  = z_sub;                 fl_o = {3'b000, inex, inex};  // A6/A7
    end
    else begin
      z_o  = z_norm;                fl_o = {4'b0000, inex};
    end
  end

endmodule
