# d_ai01 -- step 0 anchor audit: measured facts

Every number the spec asserts about the anchor comes from one of the three
probes below. Nothing here is inferred from IEEE 754 prose or from reading the
anchor's source. Rule 24: the apparatus is recorded alongside the numbers it
licenses.

Anchor: `refs/redmule/rtl/redmule_engine.sv` (PULP RedMulE, SHL-0.51), reached
through the shim `ref/fp16_gemm_array_ref.sv`.

## 0. Structural finding that set the boundary

RedMulE is TWO-LEVEL: `redmule_top` instantiates `redmule_x_buffer`,
`redmule_w_buffer`, `redmule_z_buffer`, `redmule_engine`, `redmule_scheduler`
and `redmule_streamer` as siblings. There is no intermediate module. Verified by
grepping every instantiation site in `refs/redmule/rtl`.

Consequence: the composition "array + weight double-buffering + drain
overlapping compute" is not exposed at any shimmable boundary. Reaching it means
either taking all of `redmule_top` (an HWPE memory-mapped accelerator with TCDM
master ports, a register file and an XIF control interface) or writing a
sequencer inside the shim, which would put behaviour in the reference. The
original d_ai01 premise was refuted on this basis and the task retargeted to the
`redmule_engine` boundary.

## 1. Elaboration

| frontend | result |
|---|---|
| Verilator 5.046, `--lint-only`, top `fp16_gemm_array` | 0 errors |
| yosys 0.67 `read_slang`, `--top fp16_gemm_array`, openroad/orfs:latest | exit 0, 45.4 s, 1292 MB peak |

`read_slang` is built into the Yosys in that image; `plugin -i slang` fails
because there is no `slang.so` to load.

All 10 Verilator WIDTHTRUNC warnings are internal to `redmule_fma.sv` (37/38-bit
alignment widths and int-literal shift amounts, the same set cvfpu's
`fpnew_fma` emits). None touches a shim binding. The 37/38 widths are consistent
with FP16, and the format was confirmed independently by measurement below
rather than by reading warnings -- d_dsp01's FP4 elaboration is why.

slang `stat` reported **256 `$mul`** at the 16x16 geometry, i.e. one multiplier
per computing element and the full array elaborated. A collapsed geometry or a
dead generate branch would show as a smaller count.

## 2. `probe_schedule_tb.sv` -- format, settled value, stage spacing

Constant operand field: x[k]=1.0, w[k]=2.0, y=+0, `accumulate`=0, all row clocks
enabled.

At H=16, W=16 the observed z[0] trace is a pure FP16 arithmetic progression:

```
cycle  2 -> 0x4000 (2.0)     cycle 34 -> 0x4C80 (18.0)
cycle  6 -> 0x4400 (4.0)     cycle 38 -> 0x4D00 (20.0)
cycle 10 -> 0x4600 (6.0)     cycle 42 -> 0x4D80 (22.0)
cycle 14 -> 0x4800 (8.0)     cycle 46 -> 0x4E00 (24.0)
cycle 18 -> 0x4900 (10.0)    cycle 50 -> 0x4E80 (26.0)
cycle 22 -> 0x4A00 (12.0)    cycle 54 -> 0x4F00 (28.0)
cycle 26 -> 0x4B00 (14.0)    cycle 58 -> 0x4F80 (30.0)
cycle 30 -> 0x4C00 (16.0)    cycle 62 -> 0x5000 (32.0)
```

Established:
* the arithmetic format is **binary16** -- this encoding sequence is FP16 and
  nothing else;
* the settled value is `H*(x*w) + y`, so a row is a **length-H dot product plus
  bias**;
* one further product joins the sum every **4** cycles;
* `z[0] == z[W-1]`: all rows behave identically;
* status flags clean throughout.

Also run at H=4, W=2: settles 0x4800 (8.0) at cycle 14. Same spacing.

## 3. `probe_skew_tb.sv` -- operand-to-output delay per stage

Impulse response. x[k]=1.0 everywhere, w[k]=+0 everywhere so each element
evaluates `1.0*0 + addend` and the chain is a delay line; then w[K] is raised to
1.0 for exactly one enabled tick and the emergence cycle on z is recorded
against a free-running absolute cycle counter.

> **THE MIXED CONVENTION IS RIGHT HERE, AND IT RESOLVES THE +2/+3 DISCREPANCY.
> 2026-08-27.** The impulse is APPLIED in enabled ticks and the emergence is
> RECORDED in absolute clock cycles. Sec 12's delay, and A3/L2/L3's `d(k)`, are
> stated in enabled ticks (A1). So `probe_skew_tb`'s `D*(H-1-k)+2` and the
> contract's `D*(H-1-k)+3` are **not two measurements disagreeing by one** — they
> are one quantity counted on two clocks, offset by the probe's own
> `t_emerge = cyc - 1`. Both are correct in their own unit. The mixing was stated
> at the point of measurement, in these two sentences, and never propagated to
> the sites that consumed the number — which is how it survived as an open
> discrepancy. The open item is closed; `probe_skew_tb`'s `+2` stays, and 14 is
> still not the contract's number.

**The first model was wrong and the probe said so.** The initial guess
`delay(K) = D*(H-K)` produced a uniform 2-cycle shortfall at every stage. The
stage-to-stage spacing came back as exactly 4, which is origin-independent and
agrees with probe 2, so the formula was wrong rather than the instrument.

Corrected and re-measured, **0 mismatches out of 6 trials at H=4 and 0 out of 10
at H=8**:

```
delay(k) = D*(H-1-k) + 2,    D = NumPipeRegs+1 = 4
```

H=8 measured: k=7 -> 2, k=6 -> 6, k=5 -> 10, k=4 -> 14, k=3 -> 18,
k=2 -> 22, k=1 -> 26, k=0 -> 30.

The bias path was measured, not assumed: an impulse on `y` emerges with stage
0's delay, `D*(H-1) + 2` (30 at H=8, 14 at H=4). MATCH at both.

Sampling convention: z_o read immediately after a rising edge.

## 4. `probe_corners_tb.sv` -- delivered value at and beyond the range ends

Injected at the LAST stage (k=H-1) with every upstream stage driven to +0, so
the corner result reaches z without surviving H-1 pass-through adds. Injecting
at stage 0 would have destroyed the signed-zero evidence, since (+0)+(-0) is +0
in every rounding mode except roundTowardNegative.

**The first cut of this probe read z=0 for every case** while the status flags
varied correctly -- a one-edge-early sample, not an anchor returning zero. Fixed
by holding the operands stable across several edges so the value settles.

### Above the range: `65504 * 2`

| rnd | positive | negative | flags |
|---|---|---|---|
| RNE | 0x7C00 (+inf) | 0xFC00 (-inf) | OF, NX |
| RTZ | 0x7BFF (+65504) | 0xFBFF (-65504) | OF, NX |
| RDN | 0x7BFF (+65504) | 0xFC00 (-inf) | OF, NX |
| RUP | 0x7C00 (+inf) | 0xFBFF (-65504) | OF, NX |
| RMM | 0x7C00 (+inf) | 0xFC00 (-inf) | OF, NX |

### Below the range: `2^-24 * 0.5` = 2^-25, exactly half the min subnormal

| rnd | positive | negative | flags |
|---|---|---|---|
| RNE | 0x0000 (+0) | 0x8000 (-0) | UF, NX |
| RTZ | 0x0000 (+0) | 0x8000 (-0) | UF, NX |
| RDN | 0x0000 (+0) | 0x8001 (-min subnormal) | UF, NX |
| RUP | 0x0001 (+min subnormal) | 0x8000 (-0) | UF, NX |
| RMM | 0x0001 (+min subnormal) | 0x8001 (-min subnormal) | UF, NX |

**The sign of the exact result survives the flush to zero** in every mode.

### Exactly representable subnormal: `2^-14 * 0.5` = 2^-15

Delivers 0x0200 / 0x8200 in all five modes, with **UF=0 and NX=0**. Tininess
without inexactness raises nothing.

### Exact-zero sign: `(-0) * (+1.0) + (+0)`

+0 (0x0000) in RNE, RTZ, RUP, RMM; **-0 (0x8000) in RDN alone**.

### Non-finite

| case | delivered | flags |
|---|---|---|
| `inf * 2 + 0` | 0x7C00 (+inf) | none |
| `inf * 0 + 0` | 0x7E00 (canonical qNaN) | NV |
| `qNaN * 2 + 0` | 0x7E00 | none |

All five rounding modes agree in each of these three rows.

## 5. Area, for geometry selection

sky130hd, yosys `synth -flatten` + `dfflibmap` + `abc`, tt_025C_1v80:

* one `redmule_ce`: **23,034.59 um^2**
* `redmule_engine` at Height=8, Width=8: **1,631,831.31 um^2** (measured, not
  scaled)

The scored geometry was chosen on the MEASURED 8x8 number. Per-element scaling
alone would have predicted 64 * 23,034 = 1.47 mm^2; the real figure is 1.63
mm^2, about 11% higher, the difference being the row output registers and
fanout that do not exist inside a lone computing element. Extrapolating from one
element would have understated it.

Against this repo's own build history -- `d_nw01_axi4_xbar` is the largest
design ever built here, at 2.09 mm^2:

| geometry | elements | area | basis | verdict |
|---|---|---|---|---|
| 16x16 | 256 | ~5.9 mm^2 | scaled | ~2.8x anything built here |
| 8x8 | 64 | **1.63 mm^2** | measured | inside the proven envelope |
| 4x8 | 32 | ~0.74 mm^2 | scaled | comfortable |

The scored geometry is capped by synthesis feasibility, not by the anchor.

### CORRECTION: "the proven envelope" is proven for SYNTHESIS, not for ROUTING

The table above is sound on the axis it was written for and was then used for an
axis it does not cover. Both numbers in "1.63 against 2.09" are yosys
`synth -flatten` figures, and the comparison licenses one conclusion only: **8x8
synthesises at a size this repo has synthesised before.** It says nothing about
place-and-route, and it was subsequently cited as though it did.

Counted across all 53 PPA records in `runs/`:

* **6 records carry a `drc` field at all.** The other 47 do not, so for those the
  question was never recorded either way.
* The largest area with a **recorded clean DRC** is **294,555 um^2 --
  0.29 mm^2** (`d_nw01_second_source`, `own_fmax_9ns`).
* The 2.09 mm^2 figure is real and sourced -- `d_nw01_axi4_xbar [chat_at_9p0]`,
  with `[chat_scored]` larger still at 2.14 mm^2 -- but **both carry no `drc`
  field.** `status: completed` establishes that the flow finished, not that the
  design routed clean.
* The one `d_nw01_axi4_xbar` record that IS `drc = 0` is `config: CUT_ALL_AX`
  at 154,245 um^2, a cut-down configuration.

So the routing envelope this repository has actually demonstrated is **0.29
mm^2**. On that axis:

| geometry | area | vs the DRC-clean envelope |
|---|---|---|
| 8x8 | 1.63 mm^2 | **5.5x over** |
| 4x8 | ~0.74 mm^2 | **~2.8x over** |

This is stated as an absence of evidence, NOT as a claim that the 2.09 mm^2 runs
were dirty -- nothing here measures that, and asserting it would be inventing a
result from a missing field. What it does mean is that **no data point exists
anywhere between 0.29 mm^2 and 1.63 mm^2**, so a geometry chosen to land inside
a routing envelope has no measurement to land inside of. Halving the array moves
it from 5.5x over to 2.8x over; it does not bring it in.

The remedy is a measurement, not a smaller table: `orfs_runs/d_ai01_h4/`.

### THE MEASUREMENT CAME BACK, AND IT MOVES THE ENVELOPE THIS SECTION CORRECTS

`orfs_runs/d_ai01_h4/` completed: **0 DRC violations, exit 0, 710,752 um^2 at 33%
utilisation.** Run by AGENT-PPA-2381f2fe at 50 ns from the task's own
`constraint.sdc`, against **76,253-83,445 violations on three separate 8x8
floorplans** at the same relaxed constraint.

**Two things follow, and the second corrects a number written above.**

**Geometry was the lever, and the prediction recorded here was wrong.** The
failure signature -- 73% (corrected: 80%) of violations on met1, mass shorts
directly above the cells, global route clean, antennas driven to zero -- reads as
PIN ESCAPE, which is LOCAL: the same cells with the same pins, just fewer of
them. That predicted **~35,000-40,000 violations at 4x8, roughly half of 76,253**.
The measured answer is **zero**. Halving the array did not halve the violations,
it eliminated them, which is congestion-like and not pin-access-like. The
diagnosis was endorsed here and the measurement refutes it.

**The DRC-clean envelope is no longer 0.29 mm^2.** The table above says the
largest area with a recorded clean DRC is 294,555 um^2 and that 4x8 at ~0.74 mm^2
is "~2.8x over" it. **This run IS a recorded clean DRC at 710,752 um^2 --
0.71 mm^2, 2.4x the previous maximum** -- so the envelope moved, and it moved
because someone measured the gap rather than arguing about it. The correction
above was right that no data point existed between 0.29 and 1.63 mm^2. There is
one now, and it is inside.

**What this does NOT establish, and the asymmetry is the reason.** 50 ns is the
most RELAXED constraint the spec allows; G1 records that the pinned period is not
yet set and that this 50 ns is a starting constraint, not the pin. A failure at
50 ns would have been decisive. **A pass at 50 ns is necessary and not
sufficient**, because the eventual pin is tighter and closure is bought with
area -- upsizing, buffering, duplication -- so the routed design at the pin will
be larger than 710,752 um^2 and must be re-checked before any PPA number is
published from it.

**The comparison that does hold is like-for-like.** 8x8 and 4x8 were both routed
at 50 ns. At matched, favourable conditions one routes clean and the other does
not, three floorplans deep. That is a statement about the GEOMETRY and it does not
depend on what the pin turns out to be.

## 6. `probe_control_tb.sv` -- the control inputs

Probes 2-4 held `accumulate_i`=0, `row_clk_gate_en_i`=all-ones, `in_valid_i`=1
and `out_ready_i`=1 throughout, so none of them was characterised by those runs.
Measured here at H=4, W=2, with x=1.0, w=2.0 (a row settles to 8.0 = 0x4800).

### `flush_i`

**The first reading of this was wrong and is corrected here.** probe_control_tb
sampled after DEASSERTING flush and saw 0x4800, which reads as "flush does
nothing". A direct cycle-by-cycle trace shows the opposite:

```
settled z=0x4800
  cyc=35 flush=1 z=0x0000     <- cleared
  cyc=36 flush=1 z=0x0000
  cyc=37 flush=1 z=0x0000
  cyc=38 flush=0 z=0x4800     <- refills as soon as flush drops
  cyc=41 flush=0 z=0x4000     <- transient while the chain refills
  cyc=42 flush=0 z=0x4800
```

So: while `flush_i` is asserted every inter-stage register reads zero and z_o is
+0.

> **QUALIFIED 2026-08-27, left as written.** That "every" is false as a universal
> over ROWS. It means every inter-stage register *of a clock-enabled row*: Sec 7
> below measures a gated row holding `0x4800` straight through an assertion,
> because the row registers are clocked by the gated `row_clk` and a row with its
> gate off receives no edge. This sentence predates Sec 7 and was never amended
> when Sec 7 corrected the clause. **C2 p1 already carries the qualifier** — the
> live false universal was here, in the measurement narrative, not in the clause.

On deassertion the chain refills from the operand field then in force,
passing through a transient before settling. The earlier reading was a sampling
error, not an anchor behaviour.

### `accumulate_i`

Baseline settled z0 = 0x4800 (8.0). With `accumulate_i` raised, sampled once per
further D*H window:

```
0x4C00 (16.0)  0x4E00 (24.0)  0x5000 (32.0)
0x5100 (40.0)  0x5200 (48.0)  0x5300 (56.0)
```

Each chain-fill adds a further 8.0. So `accumulate_i` replaces the row's bias
input with the row's OWN PREVIOUS z, and the partial product carries forward.
This is the mechanism for operands taller than the array. The feedback is broken
by the output register, so it is not a combinational loop.

### `row_clk_gate_en_i`

Both rows settled at 0x4800. With `row_gate = 2'b01` (row 0 clocked, row 1
frozen) and the operand field changed to 2.0*2.0:

```
z0 = 0x4C00 (16.0)   <- row 0 tracked the new field
z1 = 0x4800 ( 8.0)   <- row 1 held
```

Re-enabling row 1 brought it to 0x4C00. A gated row's state freezes entirely and
resumes from where it stopped; it is a clock gate, not a reset.

### `reg_enable_i`

With `reg_enable_i` low and the operand field changed, z0 held at 0x4800 for the
whole window; on restore it advanced to 0x4C00. `reg_enable_i` is the advance /
stall control, and the "enabled tick" of the latency model is a rising edge with
`reg_enable_i` high and that row's clock gate enabled.

### Handshake

| condition | in_ready[0] | out_valid[0] | busy[0] | z |
|---|---|---|---|---|
| steady, both high | 0xF | 0xF | 0xF | tracks |
| `in_valid_i` low | -- | 0x0 | 0x0 | holds |
| `out_ready_i` low | 0x0 | -- | 0xF | holds |

A genuine per-element valid/ready with backpressure: dropping `in_valid_i`
clears out_valid and busy; dropping `out_ready_i` deasserts in_ready while busy
stays high.

**Characterised only to first order.** The interaction between backpressure and
chain advance was not separated from `reg_enable_i` in this run. The spec
therefore binds `in_valid_i` and `out_ready_i` HIGH -- the condition under which
every other measurement in this file was taken -- and excludes `in_ready_o`,
`out_valid_o` and `busy_o` from the scored surface. Scoring a port whose
protocol is not fully characterised would be a clause the anchor decides and the
text only appears to.


## 7. flush against clock gating and against the stall

Added after a clause-by-clause re-read of the spec asking, of each clause,
whether the reference decides anything the text does not. C2 did.

H=4, W=2, rows settled at 0x4800:

| condition | z[0] (clocked) | z[1] | reading |
|---|---|---|---|
| settled | 0x4800 | 0x4800 | -- |
| `flush`=1, `row_gate`=2'b01 | **0x0000** | **0x4800** | a GATED row does not flush |
| `flush`=1, `reg_enable`=0 | 0x0000 | 0x0000 | flush outranks the stall |

**The spec was wrong before this measurement.** C2 said flush "forces every
inter-stage register of every row to zero". It does not: the row registers are
clocked by the gated `row_clk`, so a row with its clock gate off receives no edge
and is untouched. Corrected in C2, with the precedence over `reg_enable_i` --
which the same run confirms -- stated separately because the two are different
questions and only one of them was true as written.


## 8. The accumulate feedback delay (spec C3)

Same clause-by-clause re-read that produced section 7. C3 asserted that the
fed-back z_o is sampled at stage 0's tick, d(0) = D*(H-1)+2. It is not.

Method: settle the chain, raise `accumulate_i` on a known edge against a
free-running counter, record the first edge at which z_o changes.

| H | accumulate raised | z first changed | delta | d(0) | D*(H-1)+3 |
|---|---|---|---|---|---|
| 4 | cyc 45 | cyc 60 | **15** | 14 | 15 |
| 8 | cyc 45 | cyc 76 | **31** | 30 | 31 |

Both candidate formulas -- `d(0)+1` and `D*(H-1)+3` -- are the same expression,
and both geometries agree with it. The extra tick over d(0) is structural: z_o is
already a registered value when the feedback multiplexer selects it, so it is one
register deeper into the past than an operand presented at the same edge.

C3 was corrected to state `dfb = D*(H-1)+3` explicitly, with the H=4 and H=8
values written out.


## 9. Timing, for the SDC starting constraint

sky130hd, yosys `synth -flatten` + `dfflibmap` + `abc`, then OpenSTA at two
periods with a 20% I/O budget each side.

| top | period | data arrival | data required |
|---|---|---|---|
| `redmule_ce` alone | 4 ns | 15.672 | 3.700 |
| `redmule_ce` alone | 10 ns | 15.672 | 9.700 |
| `fp16_gemm_array` 8x8 | 20 ns | 39.385 | 19.689 |
| `fp16_gemm_array` 8x8 | 40 ns | 43.385 | 39.689 |

For the array the two arrivals differ by exactly 4.000 ns -- the change in input
delay -- so they are ONE path through two budgets, and both reconcile to a logic
delay of **35.385 ns**. Closing it needs `period >= 44.62 ns`; the SDC pins 50.

A lone computing element is 15.672 ns and the array is 35.385. The difference is
the operand broadcast: `w_i` fans out to all 64 elements and `x_i` to a whole row
each, unbuffered at synthesis, so the boundary paths carry the array's fanout
before reaching the first register.

Two tool notes, both found here rather than inherited:
* `remove_from_collection` is not implemented by the OpenSTA in
  openroad/orfs:latest -- use `all_inputs -no_clocks`.
* OpenSTA cannot read yosys's default `write_verilog` output for this design
  (syntax error). `-noattr -noexpr -nodec` after `opt_clean -purge; splitnets
  -ports; opt_clean -purge` produces a netlist it accepts.

## 10. Apparatus defect: a git pathspec glob that returned a false empty

Recorded here so it is not lost; the finding number and any backward audit are
Jack's to scope.

Checking whether another agent's working tree had been disturbed, I ran
`git status --porcelain -- 'domains/*/verification'` and got **no output at all**,
which reads as "nothing modified, nothing staged, nothing untracked". Re-run
with the four directory paths written out explicitly
(`domains/ai_accel/verification domains/comp_arch/verification
domains/dsp/verification domains/networking/verification`) the same query
returns **140 lines**. Git pathspec globbing does not behave like shell globbing
here, and the quoted `*` did not match across the path segment as intended. The
failure mode is the dangerous one: an empty result from a scoped status query is
indistinguishable from a clean tree, and I was one step from reporting a
verified-clean result that the command had never actually checked. Same shape as
the array scans in F62 and the shared `--Mdir` in F60 -- an instrument that
reports confidently while measuring something other than what was asked.


## 11. HEIGHT discrimination (spec P1), via nc_g

task.yaml recorded `measured: PARTIAL` because nothing had established that
HEIGHT is load-bearing. Measured here.

`controls/nc_g_height_blind_depth.sv` pins the chain depth to the literal 4
rather than deriving it from HEIGHT, keeping HEIGHT-wide ports.

| geometry | result | z kills | first z kill | status kills | first status kill |
|---|---|---|---|---|---|
| HEIGHT=4 | PASS | 0 / 3400 | -- | 0 / 3400 | -- |
| HEIGHT=8 | FAIL | 3208 / 3400 | cycle 14 | 3189 / 3400 | cycle 13 |

Witness, directed and hand-checkable rather than decoded from the random stream
-- HEIGHT=8, x=1.0, w=2.0 on every stage, y=+0, held until settled:

```
reference z[0] = 0x4C00 = 16.0 = 8 * 2.0
nc_g      z[0] = 0x4800 =  8.0 = 4 * 2.0
```

The prediction was written into the control's header before the run: PASS at 4
because the pin equals the parameter and the mapping is the identity, FAIL at 8
because four products are delivered where eight are required. Both held.

`measured:` in task.yaml moved from PARTIAL to true on this result.


## 12. A10's timing, and a correction to the instruction rather than to the text

The instruction that produced the A10 pin was "pin it to the REFERENCE's
behavior". Taken literally that would have written a POINTER into the contract
instead of a contract: "whatever redmule_engine does" leaves exactly the gap the
pin exists to close -- a requirement the oracle determines and the text only
appears to specify, which is F57's shape. **The correction here was to the
instruction, not only to the clause.** What makes A10 normative is the measured
number, not the deference.

Measured with a four-tick overflow burst driven at one stage at a time, all
stages, both geometries:

```
drive OF on ticks   0-3,  8-11, 16-19
reference status    1-5, 10-13, 18-21
```

> **Unit note, 2026-08-27.** This delay is in ENABLED TICKS (A1). `probe_skew_tb`
> reports the same physical quantity in RAW CLOCK CYCLES and is therefore one
> lower; see the note in Sec 3. Neither is stale.

Steady state: **delay 2 enabled ticks, uniform across k, one operation latched,
consecutive operations never ORed**, and NOT aligned with the z_o the operation
contributes to. A single-tick impulse from a quiescent chain reports delay 1 and
a wider response; that is a startup regime, visible above as the first burst
being five ticks wide instead of four, and it is not the steady-state rule.

## 13. Procedure note: a stated expected result is not a clean test until the instrument is

Cross-reference: F64, which is the same shape applied to apparatus.

The A10/C2 re-run carried an externally stated falsification condition -- "the
~2900 status mismatches should disappear; if they don't, the clause fixes are
wrong". They did not disappear on the first re-run: status stayed at 2523/2703.
Taken literally, that condition would have reverted a correct clause. Measuring
the second source's own status latency first showed it landing on ticks
0-4/9-12/17-20 against the reference's 1-5/10-13/18-21 -- **the measuring
implementation was one pipeline stage short**, and the clause was never in
question.

The general form: **an externally stated expected-result condition must be
checked against the measuring instrument before it is allowed to falsify the
thing being measured.** A prediction and an instrument can both be wrong, and a
failed prediction is evidence about the pair, not about the hypothesis alone.
Rule 24 requires an apparatus to reproduce a known-good answer before its numbers
are read; this is the same requirement one level up, on the apparatus that a
prediction is being evaluated through. Recorded as procedure rather than as a
finding.


## 14. H5: isolating the second-source residual

After the A10 pin and the C2 narrowing the second source still differs from the
reference on z (196 at H=4, 178 at H=8) and on status (224 / 260).

### The z and status residuals do NOT co-occur, so they are not one cause

| | both | z only | status only |
|---|---|---|---|
| H=4 | 158 | 38 | 66 |
| H=8 | 137 | 41 | 123 |

A large status-only population at both geometries rules out a single shared
cause on the evidence, without needing a mechanism.

### Two classification errors of mine, both corrected by measurement

**First error: bucketing by the control state AT the divergent cycle.** That
produced a "43 row-gated cases" class and a "~50 unclassified" class, and both
were artifacts. The pipeline carries LZ ticks of history, so a control event
changes the output for LZ ticks AFTER it ends; reading the control state at the
divergent cycle sees the wrong tick.

**Second error, in the opposite direction.** Re-checking whether the diverging
ROW was the GATED row gave 2 of 23 -- which read as "gating is not a cause", and
I said so. That was also wrong. At cycle 2242, `gate=10111111` gates row 6 while
row 5 diverges; row 5 had been gated over 2223-2241 and diverges from **2242, the
first cycle after its release**. The gate state at the divergent cycle shows the
NEXT row in the walking pattern, not the responsible one.

### Classified over the history window, nothing is left over

For each (cycle, row) divergence event, asking whether that row was gated, or
accumulate was active, at any point in the preceding LZ cycles:

| | events | gated within LZ | accumulate within LZ | neither |
|---|---|---|---|---|
| H=4 (LZ=15) | 1320 | 19 | 1301 | **0** |
| H=8 (LZ=31) | 1119 | 23 | 1096 | **0** |

**There is no unclassified residue at either geometry.** Two causes only:
accumulate transitions (~98%) and row-gate transitions (~2%).

### Both are transitions, not steady states

Directed side-by-side probes with CONSTANT operands show NO divergence in either
class: gating a row and releasing it agrees cycle-for-cycle, and toggling
accumulate on and off agrees cycle-for-cycle (both settle to 0x4C00). The
divergence requires TIME-VARYING operands, which is what makes it a
transition-with-in-flight-state effect rather than an arithmetic one.

Magnitudes confirm that: of 1119 disagreeing values at H=8, 1104 are far apart
and only 15 are within 4 ulp. This is not rounding.

Steady-state feedback delay is identical in both implementations -- 15 enabled
ticks at H=4, 31 at H=8 -- so C3's pinned dfb is not what differs.

### A signedness bug in my own verdict line

The refill-duration probe printed "*** OUTSIDE the named window ***" while its own
numbers (13 at H=4, 29 at H=8) are INSIDE the window (15, 31). `WIN` was declared
`int unsigned`, so comparing the sentinel `-1` against it promoted to unsigned and
made a never-diverged result read as a violation. Caught only because the numbers
were read rather than the verdict. Same family as F64.


## 15. The flush-status residual: CLOSED as a second-source defect, no clause change

> **SUPERSEDED 2026-08-27. NOT REWRITTEN — the text below stands as written so the
> reasoning can be audited.**
>
> **Why the reasoning fails.** It rules out *clearing* and then treats *advancing*
> as the remainder, without establishing that the text says the arithmetic keeps
> running during flush. That is an argument from silence: "A10 says nothing about
> flush" licenses neither reading over the other.
>
> **And it identifies the hole and stops rather than reporting it.** It concludes
> that reproducing the reference exactly "would mean modelling the reference's
> per-stage internal registers, which is the thing this contract deliberately does
> not do" — which is precisely C2's own stated reason for excluding the window
> after flush_i FALLS. That reasoning is symmetric in the edge. Meeting it on the
> RISING side and filing the result as an accepted residual, rather than as a
> contract hole of the same shape one edge over, is the error.
>
> **And its factual claim is now measured false.** It says the reference
> "evidently keeps ADVANCING its status pipeline through the flush."
> `tb/audit/probe_flush_status_tb.sv`, under an alternating stimulus that a
> constant field could not have discriminated, measures the opposite at both
> geometries: with flush LOW, status_o[r][0] toggles `00101/00000` in step with
> the stimulus; with flush HIGH it is frozen at `00101` for the whole assertion.
> **The reference HOLDS.** Probe (ii) additionally shows stage 0 differing between
> flush and no-flush runs — 56 samples — so the flush reaches status_o[r][0],
> which this section's argument assumes it does not.
>
> Superseding entry: `probe_flush_status_tb` results, and the C2 rewrite that
> follows from them.


The only surviving status divergence sat at exactly the flush cycles -- 200/201,
430/431, 601/602, 1403/1404, 2205/2206, 2606/2607 and nowhere else. The reference
keeps reporting each stage's in-flight flags through a flush; the second source
zeroed them.

**Nothing requires that.** C2 zeroes the INTER-STAGE registers of the chain; the
status pipeline is not one of them, and A10 -- which is what governs status_o --
says nothing about flush. The clearing was invented.

**Action taken: the second source was FIXED, not the clause.** A10 is unchanged.
Removing the clear took the status residual from 12 to 10 at HEIGHT=4 and 15 to
13 at HEIGHT=8, and removed the 430/431 cycles entirely. It did NOT remove the
rest: holding the pipeline through flush is closer than zeroing it but still not
what the reference does, which evidently keeps ADVANCING its status pipeline
through the flush.

> **THAT SENTENCE IS FALSE. MEASURED FALSE 2026-08-27, marked here rather than
> only at the section header.** `tb/audit/probe_flush_status_tb.sv`, alternating
> stimulus, both geometries: with flush LOW `status_o[r][0]` toggles
> `00101 / 00000` in step with the operand field; with flush HIGH it is frozen at
> `00101` for the whole assertion. **The reference HOLDS.** Holding is not
> "closer than zeroing" — it is exactly what the reference does, and this
> sentence asserts the opposite. Landed into spec C2 on 2026-08-27 as
> "flush_i SUSPENDS status_o". Left as written so the reasoning can be audited.
>
> Marked at the sentence because the block header at the top of this section is
> not visible to a reader who arrives here by grep or by line number.

Reproducing that exactly would mean modelling the reference's
per-stage internal registers, which is the thing this contract deliberately does
not do. The remaining flush-cycle status divergence is therefore left in place
and stated, not chased.

## 16. Two probes agreeing was not two pieces of evidence

Cross-references: F63 (the observable measured versus the observable required)
and F64 (an instrument must reproduce a known answer before it is believed).

The second source's accumulate feedback tapped z(t-1) where the reference taps
z(t) -- a one-tick error that made it disagree on 100% of steady-state accumulate
ticks. Two separate probes had already been run against that path and both
reported it correct:

* the first-change latency probe, which raises accumulate from a settled state
  and records when z first moves;
* the directed toggle probe, which drives accumulate on and off against a
  CONSTANT operand field.

**Both share one assumption: a static operand field.** Under a static field
z(t) == z(t-1) identically, so the two taps are indistinguishable -- not merely
hard to tell apart, but exactly equal. Neither probe could have detected the
defect, and their agreement carried no information about it at all.

**The general form: probes that share a stimulus assumption do not corroborate
each other.** Two instruments agreeing is evidence only to the extent their
failure modes are independent, and a shared stimulus is a shared failure mode.
When a defect can only manifest under a condition no probe creates, every probe
returns a clean result and the count of clean results is irrelevant. The question
to ask of a corroborating pair is not "do they agree" but "what would each have
to see to disagree, and does anything generate it".

Here nothing did until the full time-varying vector set was run, which is also
why the defect survived four earlier rounds of measurement.

## 17. OPEN: 4-6 z cycles that no directed probe reproduces

**Status: OPEN. Not closed, not absorbed into an adjacent class.**

After every fix above, a small z residual remains:

* HEIGHT=4: 4 cycles, 2637-2640, a single row
* HEIGHT=8: 6 cycles, 1472-1478, several rows

It does not reproduce under any directed probe built so far. Post-rise and
post-fall accumulate transients both measure ZERO divergence; steady-state
accumulate measures zero over 90 and 186 sampled ticks; gating and flush probes
are clean. The cycles sit inside an accumulate-high stretch but outside the C3
exclusion window, and the directed probes carry band-0 operands with no stalls
and no corner injections, so whatever distinguishes these cycles is something the
probes do not generate.

**What that means procedurally: this needs a differently-shaped instrument, not
more adjudication rounds.** Repeating the existing probes cannot resolve it --
see section 16 for why running more of the same probes is not more evidence.

**The prior, WEAKENED 2026-08-27, and the section stays OPEN.** This is a note on
the prior, not a new conclusion.
>
> The "four of four" count below is built partly on section 15, which has since
> been SUPERSEDED: its central claim about the reference is measured false, and
> the residual it closed as a second-source defect is now a live contract
> question. One of the four is therefore not a resolved second-source defect.
>
> The count is also built on a second source that has since been DISQUALIFIED for
> contamination — its flush behaviour was re-derived by a reader who had already
> seen the reference's flush values, and it is not currently usable as an
> independent instrument. A prior assembled from an instrument later found
> unreliable inherits that unreliability; it does not survive as a frequency.
>
> **What this does NOT do:** it does not make a task defect likely. It removes
> the grounds for calling a second-source defect likely. Section 17 was already
> OPEN and remains exactly as open as it was — the prior that made one answer
> look probable is what has weakened, not the evidence for either answer.

**The prior as originally stated.** Four of four previous second-source residuals on
this task resolved as defects in the second source, not in the task: a truncated
self-determined product, a missing output pipeline stage, a status pipeline one
stage short, and a feedback tap one tick early. Every one was an off-by-one or a
width/signedness slip invisible to at least one probe that had been trusted. On
that record the likely reading is a fifth second-source defect rather than a
task problem, and it is recorded that way -- but it is recorded as OPEN, because
"likely" is not a measurement.

## 18. The reg_enable regime: on which edge flush clears z_o. 2026-08-27

`tb/audit/probe_flush_stall_edge_tb.sv`. Sec 7 recorded that flush outranks the
stall — `0x0000` in every clocked row with `reg_enable_i` low — and recorded no
**edge**. A1 makes an enabled tick require `reg_enable_i` high, so in this regime
no enabled tick passes and A10's timebase does not advance, yet z_o clears. That
gap was named in the search spec for this file and had never been measured.

Four arms, two of them Rule 24 controls, because a probe that discriminates on
**when** a value appears is fooled equally by an instrument that never sees a
clear and by one that reports clears everywhere.

| arm | `reg_enable` | `flush` | gates | expected | H=4 | H=8 |
|---|---|---|---|---|---|---|
| E control | 1 | 1 | on | MUST clear | edge **1** | edge **1** |
| G control | 1 | 1 | **off** | MUST NOT clear | never (8 edges) | never (8 edges) |
| S regime | **0** | 1 | on | — | edge **1** | edge **1** |
| Q regime | **0**, stall established first | 1 | on | — | edge **1** | edge **1** |

Settled `0x4400` (H=4) / `0x4800` (H=8), vacuity guard OK on every arm — a clear
is only observable from a nonzero start. Uniform across all 8 rows in every arm.

**`reg_enable_i` does not affect the clearing at all — not whether, and not
when.** z_o reads `0x0000` on the FIRST edge of the assertion in both the stalled
and the unstalled case, and entering the regime as an established stall rather
than as a simultaneous change of two inputs makes no difference either. The
asymmetry A1 predicts is real for status_o's timebase and absent for z_o's
clearing.

**AND IT MEASURES C2's SIMULTANEITY PARAGRAPH, which was argued rather than
measured when it landed.** z_o is `p[H-1]`, the last register in the chain. Were
the zeros to march down one stage per tick, z_o could not read `0x0000` until
edge `H-1` — 3 at H=4, 7 at H=8. It reads it on edge 1 at both. The paragraph
inserted into C2 on 2026-08-27 says the force is simultaneous across the chain
and says it is stated because that is what "forces the inter-stage registers to
zero" has to mean; it is now also what the reference does. **No scoring window
depends on that paragraph and none should be reintroduced from it** — this
measurement does not change that.

**What this does not settle**, stated so silence is not read as completeness: it
measures the reference. It does not establish what the contract should say, and
no clause was written from it.
