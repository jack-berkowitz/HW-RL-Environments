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
+0. On deassertion the chain refills from the operand field then in force,
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
