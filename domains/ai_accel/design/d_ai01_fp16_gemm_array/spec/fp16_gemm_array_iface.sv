// =============================================================================
// fp16_gemm_array_iface.sv -- d_ai01 CONTRACT.
//
// A WIDTH-row by HEIGHT-deep binary16 multiply-accumulate array. Each row is a
// serial chain of HEIGHT fused-multiply-add stages separated by registers; the
// weight vector is broadcast to every row; each row carries its own activation
// slice and its own bias.
//
// This file is the contract. Implement `fp16_gemm_array` to it. Everything
// asserted below about delivered values, flags and timing was MEASURED against
// the reference at the shim boundary -- see MEASUREMENTS.md, which records the
// probes, the two readings that came back wrong, and the corrections. Nothing
// here is derived from IEEE 754 prose alone.
//
// -----------------------------------------------------------------------------
// F -- FORMAT
// -----------------------------------------------------------------------------
// F1. Every operand and every result is IEEE 754-2019 binary16: 1 sign bit,
//     5 exponent bits, 10 trailing significand bits. Largest finite magnitude
//     0x7BFF (65504). Smallest positive normal 0x0400 (2^-14). Smallest
//     positive subnormal 0x0001 (2^-24). Subnormals are SUPPORTED, both as
//     operands and as delivered results; flush-to-zero is NOT permitted.
//
// F2. The canonical quiet NaN is 0x7E00. Any NaN the unit generates is 0x7E00.
//
// F3. rnd_i selects the rounding attribute, encoded
//       0 RNE roundTiesToEven      3 RUP roundTowardPositive
//       1 RTZ roundTowardZero      4 RMM roundTiesToAway
//       2 RDN roundTowardNegative
//     Values 5-7 are not exercised and carry no requirement.
//
// -----------------------------------------------------------------------------
// V -- INTERFACE
// -----------------------------------------------------------------------------
// V1. Ports, exactly:
//       clk_i               1
//       rst_ni              1        asynchronous, active low
//       x_i                 [WIDTH][HEIGHT][16]   activations, per row per stage
//       w_i                 [HEIGHT][16]          weights, BROADCAST to all rows
//       y_i                 [WIDTH][16]           bias, one per row
//       z_o                 [WIDTH][16]           result, one per row
//       rnd_i               3
//       accumulate_i        1
//       row_clk_gate_en_i   [WIDTH]
//       reg_enable_i        1
//       flush_i             1
//       status_o            [WIDTH][HEIGHT][5]
//
// V2. rst_ni asserted low clears every inter-stage register; z_o reads +0
//     (0x0000) and every status_o field reads 0.
//
// V3. status_o[r][k] is the IEEE exception state of the fused multiply-add at
//     row r, stage k, packed {NV, DZ, OF, UF, NX} with NV in bit 4 and NX in
//     bit 0. DZ is never raised by this unit -- there is no division.
//
// -----------------------------------------------------------------------------
// A -- ARITHMETIC
// -----------------------------------------------------------------------------
// A1. ENABLED TICK. For row r, an enabled tick is a rising edge of clk_i at
//     which both reg_enable_i and row_clk_gate_en_i[r] are high. All timing
//     below is counted in enabled ticks of the row in question, not in raw
//     clock edges. (Measured: with reg_enable_i low the row holds its state
//     across an arbitrary number of edges and resumes where it stopped.)
//
// A2. ROW FUNCTION. Each row evaluates a chain of HEIGHT fused multiply-adds in
//     ASCENDING stage order, seeded by the bias:
//
//       p[r][0] = fma( x_i[r][0], w_i[0], y_i[r] )
//       p[r][k] = fma( x_i[r][k], w_i[k], p[r][k-1] )      for k = 1 .. H-1
//       z_o[r]  = p[r][H-1]
//
//     where fma(a,b,c) is a SINGLE fused multiply-add: a*b+c computed with one
//     rounding, under the attribute selected by rnd_i. The product is NOT
//     rounded before the addition.
//
//     The order is contractual, not incidental. Floating-point addition is not
//     associative, so a chain evaluated in any other order delivers different
//     bits for the same inputs.
//
// A3. TEMPORAL INDEXING -- the operand skew. A2 alone does not say WHICH
//     cycle's x_i and w_i a given z_o depends on, and the stages do not consume
//     their operands simultaneously. Writing A2 without this clause would leave
//     the question to the reference. Let
//
//       D     = 4                          per-stage delay, in enabled ticks
//       d(k)  = D * (H - 1 - k) + 2        stage-k operand delay
//
//     Then the value delivered on z_o[r] at enabled tick t is the chain of A2
//     evaluated with each stage's operands taken from ITS OWN earlier tick:
//
//       z_o[r](t) = p[r][H-1] where
//         p[r][0] = fma( x_i[r][0](t-d(0)), w_i[0](t-d(0)), y_i[r](t-d(0)) )
//         p[r][k] = fma( x_i[r][k](t-d(k)), w_i[k](t-d(k)), p[r][k-1] )
//
//     Stage 0 consumes the OLDEST operands, d(0) = D*(H-1)+2, and stage H-1 the
//     newest, d(H-1) = 2. Successive stages are exactly D apart. The bias y_i
//     is sampled with stage 0's delay, d(0) -- measured, not assumed.
//
//     For H=8: d = 30, 26, 22, 18, 14, 10, 6, 2 for k = 0 .. 7.
//     For H=4: d = 14, 10, 6, 2.
//
//     A consequence worth stating plainly: to compute one coherent dot product
//     the operand pairs must be presented STAGGERED, stage 0 first and each
//     later stage D ticks after the one before it.
//
// A4. ROUNDING. Every fused multiply-add rounds once, under rnd_i as it stands
//     at that stage's own sampling tick per A3.
//
// A5. DELIVERED VALUE ABOVE THE REPRESENTABLE RANGE. When the exact result of
//     an individual stage's fused multiply-add has magnitude at or above the
//     binary16 overflow threshold, the value delivered by that stage is set out
//     here in full, in both directions, for every rounding mode. It is NOT to
//     be inferred from A4 and F1.
//
//       rnd   exact result positive        exact result negative
//       ---   ---------------------        ---------------------
//       RNE   +infinity      0x7C00        -infinity      0xFC00
//       RTZ   +65504         0x7BFF        -65504         0xFBFF
//       RDN   +65504         0x7BFF        -infinity      0xFC00
//       RUP   +infinity      0x7C00        -65504         0xFBFF
//       RMM   +infinity      0x7C00        -infinity      0xFC00
//
//     In every one of these ten cases that stage raises OF and NX. UF and NV
//     stay low.
//
// A6. DELIVERED VALUE BELOW THE REPRESENTABLE RANGE. When the exact result of a
//     stage is nonzero and its magnitude is below the smallest positive
//     subnormal, the delivered value is set out here in full, in both
//     directions, for every rounding mode. As with A5 this is stated, not left
//     to inference.
//
//     Taking the representative case of an exact result of magnitude 2^-25,
//     exactly half the smallest subnormal:
//
//       rnd   exact result positive        exact result negative
//       ---   ---------------------        ---------------------
//       RNE   +0             0x0000        -0             0x8000
//       RTZ   +0             0x0000        -0             0x8000
//       RDN   +0             0x0000        -2^-24         0x8001
//       RUP   +2^-24         0x0001        -0             0x8000
//       RMM   +2^-24         0x0001        -2^-24         0x8001
//
//     THE SIGN OF THE EXACT RESULT IS PRESERVED when the magnitude collapses to
//     zero: a negative exact result delivers -0, never +0. In every one of these
//     ten cases that stage raises UF and NX; OF and NV stay low.
//
//     Between the two ends, an exact result whose magnitude lies below the
//     smallest normal but at or above the smallest subnormal is delivered as the
//     correctly rounded SUBNORMAL under rnd_i. It is not flushed to zero.
//
// A7. TINY BUT EXACT. If a stage's result is subnormal and EXACTLY
//     representable, no flag is raised at all -- UF and NX both stay low.
//     (Measured: 2^-14 * 0.5 delivers 0x0200 with all five flags low in every
//     rounding mode.) Underflow is signalled only when the result is both tiny
//     and inexact.
//
// A8. SIGN OF AN EXACT ZERO. When a stage's exact result is zero and that zero
//     arises as the sum of two zeros of opposite sign, the delivered value is
//     +0 (0x0000) under RNE, RTZ, RUP and RMM, and -0 (0x8000) under RDN alone.
//     No flag is raised.
//
// A9. NON-FINITE OPERANDS.
//       infinity * finite-nonzero + finite  delivers the correctly signed
//                                           infinity, no flag raised.
//       infinity * zero                     delivers canonical qNaN 0x7E00 and
//                                           raises NV.
//       any quiet NaN operand               delivers 0x7E00 and raises NO flag.
//     A NaN entering a stage propagates as 0x7E00 down the remainder of the
//     chain.
//
// A10. FLAG SCOPE AND TIMING. status_o[r][k] reports the exceptions of THAT
//     STAGE'S fused multiply-add alone. Flags are not accumulated along the
//     chain and not ORed across stages or rows.
//
//     THE TIMING IS PINNED, AND IT IS NOT THE SKEW OF A3. status_o[r][k](t)
//     reports the operation whose operands were sampled 2 ENABLED TICKS EARLIER
//     -- the SAME delay for every k, independent of d(k). It is NOT aligned with
//     the z_o that operation contributes to, so at any tick the HEIGHT entries
//     of a row generally describe HEIGHT DIFFERENT operations, one per stage in
//     flight.
//
//     Measured: with stage k driven to overflow in a four-tick burst, OF appears
//     on status_o[r][k] two enabled ticks later and for exactly the burst width,
//     at every k and at both legal HEIGHTs. One operation is latched; two
//     consecutive operations are never ORed together. (A single-tick impulse
//     from a quiescent chain shows a wider, one-tick-earlier response; that is a
//     startup regime and not the steady-state rule stated here.)
//
//     AN EARLIER DRAFT LEFT THE TIMING UNSTATED, and that was a defect in this
//     text rather than in any implementation. Two readings satisfied the words
//     -- this one, and "aligned with the z_o it contributed to" -- and an
//     independent implementation of the same clause took the other reading and
//     disagreed with the reference on roughly 2900 of 3400 cycles. Both were
//     legal. The clause was wrong to permit both.
//
// -----------------------------------------------------------------------------
// C -- CONTROL
// -----------------------------------------------------------------------------
// C1. reg_enable_i low freezes every row: no inter-stage register advances, z_o
//     holds, and the chain resumes from its held state when reg_enable_i
//     returns high. Operand changes during the freeze have no effect.
//
// C2. flush_i high forces the inter-stage registers to zero, so z_o reads +0
//     (0x0000) for as long as it is asserted, IN EVERY ROW WHOSE CLOCK IS
//     ENABLED. A row with row_clk_gate_en_i[r] low is NOT cleared by flush: it
//     holds its state, and flush is not an exception to C4.
//
//     Measured, and this clause was wrong before it was measured. With one row
//     gated off and flush asserted, the clocked row went to 0x0000 while the
//     gated row held 0x4800. An earlier draft of C2 said flush clears "every
//     row", which the reference would have quietly decided differently.
//
//     flush_i DOES take precedence over reg_enable_i: with reg_enable_i low and
//     flush_i high, every clocked row clears. Also measured.
//
//     THE REFILL WINDOW IS NOT SCORED. On deassertion the chain refills from the
//     operand field then in force. The values delivered on z_o and status_o
//     during the first D*(HEIGHT-1)+3 ENABLED TICKS after flush_i falls -- 31 at
//     HEIGHT=8, 15 at HEIGHT=4 -- are UNSPECIFIED, and are excluded from
//     scoring.
//
//     An earlier draft asserted the opposite: that the refill passes through the
//     partial sums of A3 and that those intermediate values are contractual
//     because they "follow from A3 with the flushed zeros as the starting
//     state". That was a CONTRACT DEFECT. The reference holds per-stage internal
//     state that this contract deliberately does not model, so its refill
//     sequence is not derivable from A3, and an independent implementation that
//     did derive it from A3 produced a different -- and equally legal -- refill.
//     Nothing is scored that this text cannot specify.
//
// C3. accumulate_i high replaces the bias input of every row with THAT ROW'S
//     OWN z_o. y_i is ignored while it is high. This is how operands deeper
//     than HEIGHT are folded: each further pass adds its dot product to the
//     running total. The feedback is broken by the output register and is not a
//     combinational loop.
//
//     THE FED-BACK VALUE IS SAMPLED ONE TICK EARLIER THAN STAGE 0's OPERANDS.
//     Writing z_o[r](t - dfb) for the value used,
//
//       dfb = D*(H-1) + 3 = d(0) + 1
//
//     so at HEIGHT=8 the feedback carries 31 enabled ticks and at HEIGHT=4 it
//     carries 15. The extra tick over d(0) is because z_o is already a
//     registered value when the multiplexer selects it, so it is one register
//     deeper into the past than an operand presented at the same edge.
//
//     Measured at both geometries -- 15 at H=4 and 31 at H=8 -- after an earlier
//     draft of this clause asserted d(0) and was wrong by exactly one tick in
//     both. A contract that said "the row's own z_o" without pinning WHICH z_o
//     would have left the reference to decide it.
//
//     TRANSITIONS ARE NOT SCORED. The rule above is a STEADY-STATE rule. When
//     accumulate_i changes, in either direction, partial sums seeded with y_i
//     are still travelling down the chain, and this contract does not model them
//     -- it describes what a row delivers, not the pipeline that delivers it.
//     The values on z_o and status_o during the first D*(HEIGHT-1)+3 ENABLED
//     TICKS after any change of accumulate_i -- 31 at HEIGHT=8, 15 at HEIGHT=4 --
//     are therefore UNSPECIFIED and excluded from scoring.
//
//     Measured: two implementations agreeing exactly on dfb, and agreeing
//     cycle-for-cycle when accumulate_i is toggled against a CONSTANT operand
//     field, still diverge under a time-varying field for exactly one pipeline
//     depth after each toggle. That difference is in state this text declines to
//     specify, so it is not scored. Modelling it instead would put a pipeline
//     structure into the contract and hand every submission a required
//     microarchitecture, which is the freedom this task exists to measure.
//
// C4. row_clk_gate_en_i[r] low freezes row r alone. Its registers hold, its
//     z_o holds, and it resumes from where it stopped when re-enabled. It is a
//     clock gate, NOT a reset: nothing is cleared. Other rows are unaffected.
//
//     The freeze is TOTAL and outranks flush_i -- see C2. rst_ni is the only
//     input that clears a gated row, because it is asynchronous (V2).
//
//     "RESUMES" IS DEFINED FOR THE REGISTERS, NOT FOR THE PIPELINE. A row holds
//     its own registers across the freeze and continues from them -- that much is
//     scored. What is NOT specified is the relationship between the resumed row's
//     in-flight partial sums and an operand stream that kept advancing while the
//     row was frozen: the contract does not model where in the chain each sum
//     had reached. The values on z_o[r] and status_o[r][*] during the first
//     D*(HEIGHT-1)+3 ENABLED TICKS after row_clk_gate_en_i[r] changes are
//     UNSPECIFIED and excluded from scoring, PER ROW -- other rows are unaffected
//     and stay scored throughout.
//
//     Measured: gating a row and releasing it against a CONSTANT operand field
//     agrees cycle-for-cycle between independent implementations; under a
//     time-varying field the released row diverges for one pipeline depth,
//     starting on the first tick after release.
//
// -----------------------------------------------------------------------------
// L -- LATENCY
// -----------------------------------------------------------------------------
// L1. The per-stage delay D is exactly 4 enabled ticks and is contractual. It
//     is not an implementation choice: it sets the operand skew of A3, so a
//     different D delivers different results for the same input stream.
//
// L2. The delay from a stage's operands to z_o is d(k) = D*(H-1-k)+2 enabled
//     ticks, per A3.
//
// L3. Total latency from stage 0's operands to z_o is D*(H-1)+2 enabled ticks:
//     30 at HEIGHT=8, 14 at HEIGHT=4.
//
// -----------------------------------------------------------------------------
// P -- PARAMETERS
// -----------------------------------------------------------------------------
// P1. HEIGHT is legal at 4 and 8. WIDTH is fixed at 8. HEIGHT changes the
//     observable schedule -- it sets both the chain latency and the operand
//     skew -- so it is the parameterised axis; WIDTH is pure replication.
//
// P2. The scored configuration is HEIGHT=8, WIDTH=8, which is also the default.
//     The cap is synthesis feasibility rather than anything in the contract:
//     one computing element measures 23,034 um^2 on sky130hd, so a 16x16 array
//     would be roughly 5.9 mm^2, about 2.8x the largest design this repository
//     has ever built. See MEASUREMENTS.md section 5.
//
// -----------------------------------------------------------------------------
// T -- SCORING
// -----------------------------------------------------------------------------
// T1. Scored surface: z_o and status_o, cycle by cycle, against the reference.
//
// T2. Not scored: the reference's per-element valid/ready and busy outputs are
//     not surfaced at this boundary, and in_valid / out_ready are bound high.
//     Every measurement the contract rests on was taken under that binding.
//     The handshake protocol is characterised only to first order, so scoring it
//     would be scoring the reference rather than this text. Deliberate scope,
//     recorded in MEASUREMENTS.md section 6.
//
// T3. A submission must hold at BOTH legal HEIGHT values, not only the scored
//     one.
//
// T4. Subnormal support (F1), the range tables (A5, A6), the tiny-but-exact
//     rule (A7) and the exact-zero sign rule (A8) are all separately exercised.
//     A design that flushes subnormals to zero, or that delivers infinity in
//     every overflow mode, fails on vectors written specifically for them.
//
// T5. THE SUBMISSION MUST ELABORATE UNDER BOTH slang AND Verilator. Passing
//     simulation is not sufficient: the synthesis frontend is slang, and a
//     design Verilator accepts without comment can be rejected there, in which
//     case a bit-exact submission scores full correctness and produces NO PPA
//     NUMBER AT ALL, with the cause surfacing much later as an unexplained
//     mid-pipeline failure.
//
//     The construct that exposes this is an UNBOUNDED-LOOKING LOOP whose bound
//     slang cannot resolve at elaboration. slang enforces an unroll budget of
//     4000 iterations across nested loops, and exceeding it is a hard error:
//
//         error: unroll limit of 4000 exhausted [--unroll-limit=]
//
//     A per-bit search over a wide accumulator -- a leading-one scan, a priority
//     encode, a normalisation loop -- nested inside a per-row and a per-stage
//     loop reaches that budget quickly: 176 x HEIGHT x WIDTH is far past it.
//     Give every loop a small CONSTANT bound, or express the search as indexed
//     logic rather than iteration.
//
//     THIS IS REPRODUCED HISTORY, NOT A HYPOTHETICAL. d_dsp03's second source
//     passed every simulation configuration and was then rejected by the
//     synthesis frontend with this exact error, which is why that task carries
//     the same clause. This task's own second source hit it again, on the same
//     construct, before this clause existed.
//
// -----------------------------------------------------------------------------
// G -- GRADING
// -----------------------------------------------------------------------------
// G1. THE ORDER, and correctness is a GATE rather than a weighting.
//
//     1. CORRECTNESS, at BOTH legal HEIGHT values. The submission is driven with
//        a recorded stimulus stream and compared against the reference cycle by
//        cycle on z_o and status_o, over the scored cycles only -- that is, every
//        cycle except those excluded by C2, C3 and C4. The comparison is
//        BIT-EXACT. There is no partial credit and no tolerance: a value that is
//        one ulp out fails exactly as a value that is nonsense fails.
//
//     2. THE GATE. A submission that fails correctness at EITHER geometry
//        produces NO PPA NUMBER AT ALL. It is recorded as a failure, not as a
//        missing measurement, and it scores zero on every PPA axis. Passing at
//        the scored geometry alone is not sufficient -- see T3.
//
//     3. PPA, measured only for submissions that already passed, and measured
//        ONCE AT A PINNED CLOCK PERIOD rather than by sweeping for a maximum
//        frequency. At the time of writing that period is 50 ns on sky130hd. The
//        number is the harness's to set and may be re-pinned; what does not
//        change is that it is FIXED for every submission, so all designs are
//        compared at one frequency rather than at each design's own best.
//
// G2. WHAT IS COMPARED. Three axes, all measured from the same build:
//       * AREA, post-synthesis and post-place-and-route.
//       * POWER, at the pinned period.
//       * TIMING SLACK, the worst negative slack against the pinned period. A
//         build that does not meet timing does not yield a comparable area or
//         power number -- an area figure from a build that missed timing is not
//         a smaller design, it is an unfinished one.
//
// G3. WHAT IS NOT AVAILABLE TO OPTIMISE. Read this before choosing an
//     architecture, because the lever most designs reach for first is absent.
//
//       * LATENCY IS NOT FREE. The per-stage delay D is fixed at 4 by L1 and the
//         operand skew d(k) by A3. Adding pipeline stages to shorten the
//         critical path CHANGES THE DELIVERED VALUES and fails correctness. You
//         cannot buy frequency with depth here, which is the usual trade and is
//         not on offer.
//       * THROUGHPUT IS NOT FREE. One result per row per enabled tick, fixed by
//         A3. There is no rate to raise.
//       * THE ARITHMETIC IS NOT FREE. Every delivered value is pinned to the bit
//         by F1 and A1-A10, including both range tables. There is no
//         accuracy-for-area trade, and narrowing an internal datapath to save
//         area will fail on the vectors written for A5, A6 and A7.
//
// G4. WHAT IS ACTUALLY LEFT, and it is where the whole PPA difference comes from.
//     The contract fixes WHAT is delivered and WHEN. It says nothing about HOW,
//     and every remaining choice is an implementation one:
//
//       * how the fused multiply-add is built -- shared versus replicated
//         datapath, how alignment and normalisation are structured, how much
//         logic is common across the HEIGHT stages of a row;
//       * how the WIDTH rows share or replicate that logic, given that w_i is
//         broadcast to every row and is the same value in each;
//       * how state is held -- what is registered where, within the fixed
//         per-stage delay budget;
//       * whether and how clock gating is used. row_clk_gate_en_i is part of the
//         contract; what a design does with it internally is not.
//
//     A submission that meets the pinned period with less area and less power
//     scores better. Meeting it comfortably buys nothing extra -- there is no
//     credit for slack beyond zero, because the period is fixed for everyone.
// =============================================================================
