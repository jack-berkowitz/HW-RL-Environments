# v_nw03 `frame_arb_mux` — evidence trail

**Oracle class A.** The golden is a port shim over vendored RTL nobody on this
project wrote. What this task claims is that the reference testbench passed
externally-authored correct RTL and rejected six deliberate faults. What it does
**not** claim is anything about the reference testbench's coverage of defects
nobody here thought of — see "What the ceiling is worth" below.

**Ships no RTL.** `spec/frame_arb_mux_iface.sv` and `spec/frame_arb_mux_spec.md`
are the whole task. `dut/` holds the anchor verbatim plus a shim, used for
scoring only.

---

## 1. Anchor

| | |
|---|---|
| repo | `alexforencich/verilog-axis`, MIT |
| SHA | `48ff7a7e2ef782cf778d47910cf85835c64b1bce` (`refs.lock`) |
| file | `refs/verilog-axis/rtl/axis_arb_mux.v` |
| closure | `arbiter.v`, `priority_encoder.v` — same repo, same SHA |

`refs.manifest.yaml:237` records this exact path vendored for `nw_v05`, the v2
id for this task, with both support files named as its anticipated closure.

**Provenance caveat.** The files are present at the paths the manifest names, in
a repo `refs.lock` pins. Their *contents* have not been verified against upstream
at that SHA — that needs network and egress is closed. This attests local state
only.

### Elaboration — clean

18 configurations (`S_COUNT` 2/4/8 × `DATA_WIDTH` 8/32/64 ×
`ARB_TYPE_ROUND_ROBIN` 0/1) plus `ID_ENABLE=1, UPDATE_TID=1`. All exit 0 under
Verilator 5.046. Warnings only, all in the anchor's own width handling.

### Semantic confirmation — and a catalog defect

Reported separately from elaboration: "it compiles" and "it is the module the
catalog says it is" are different findings.

`TASK_CATALOG.md` gives the difficulty as *"frame atomicity, arbitration
fairness over long horizons, tlast under backpressure."* Measured on the anchor
with four permanently-backlogged inputs, distinct frame lengths including
single-beat, and three directed phases:

| | `ARB_TYPE_ROUND_ROBIN=1` | `=0` (**the anchor's default**) |
|---|---|---|
| frames observed | 407 | 406 |
| frames per input | 102 / 102 / 102 / 101 | **406 / 0 / 0 / 0** |
| atomicity violations | 0 | 0 |
| beat-order / frame-start | 0 / 0 | 0 / 0 |
| lost or reordered frames | 0 | 0 |
| `tlast` misplacements | 0 | 0 |

Atomicity and `tlast`-under-backpressure hold at both settings. **Fairness holds
only at `=1`** — at the default, three of four inputs were served zero frames.
Structural cause is `arbiter.v:115`: the grant is released only on
`acknowledge`, and with round-robin off the re-grant is a plain priority pick.

That is a **catalog defect**, not a parameter note, and it is why S10 exists as a
bounded clause and why `ARB_TYPE_ROUND_ROBIN=1` is pinned inside the shim rather
than exposed.

The atomicity checker in that probe was validated against a known-failing input
before its zeros were believed: one mid-frame beat corrupted monitor-side, DUT
untouched, fired exactly once and tripped nothing else.

---

## 2. Scored configuration (rule 18)

`S_COUNT = 4`, `DATA_WIDTH = 32`, `USER_WIDTH = 1`. Rationale is in spec §8.

Three further axes are bound **inside the shim** and are not parameters of the
shipped port map at all: `ARB_TYPE_ROUND_ROBIN=1`, `LAST_ENABLE=1`,
`ARB_LSB_HIGH_PRIORITY=1`.

- **`ARB_TYPE_ROUND_ROBIN=1`** because S10 is a property of it, measured above.
  A spec demanding no starvation while leaving the axis free would demand
  behaviour a legal configuration cannot deliver.
- **`LAST_ENABLE=1`** because **frame atomicity is a property of this setting**,
  not an incidental default: at 0 the anchor drops `tlast` from its arbiter
  acknowledge term and the grant releases every beat, so S3 would be false of a
  correct build.
- **`ARB_LSB_HIGH_PRIORITY=1`** is unobservable under S10 as written, and is
  bound rather than freed because a freed axis with no measurement on it buys
  nothing.

Exposing any of the three would let a submission build the golden off-spec,
observe legal behaviour the spec does not describe, and fail the validity gate
for a configuration error — a scoring defect, not a testbench defect.

---

## 3. The load-bearing clause

`v_ca05` established that a spec-only verification task's bar is set by a small
number of clauses that answer questions you only know to ask after seeing an
implementation. This task's is **S6, "ready is not a grant"**, and it is the
direct analogue of `v_ca05`'s R4.

`s_tready_o[k]` is high for a **non-selected** input whenever that input's
internal register is empty. A testbench that treats a beat accepted at an input
as a beat forwarded to the output diverges from correct hardware immediately.
Found by reading the anchor at step 1, not by writing prose.

`fm_c1` perturbs it and the second DUT takes the **opposite** choice on it, so
the clause is exercised from both directions.

---

## 4. Second DUT — BUILT, NOT WIRED

`dut2/frame_arb_mux_alt.sv`. Independent implementation written against the
spec.

**Nothing in the harness runs it.** `sim_verification.sh` gates on the
*declaration* — it refuses when `task.yaml` claims a second DUT and `dut2/` is
absent — but it never compiles the file and never adds a row for it. Every
result below came from running the reference testbench against it **by hand**.
No claim about any submission rests on it, and it must not be assumed working
as a gate.

### Three differences (rule 5), named before writing

1. **Selection mechanism** — a single rotating pointer scanned combinationally
   from `next_ptr`, against the anchor's masked-priority tree with its own mask
   register.
2. **No input registers** — `s_tready_o[k]` is high only for the currently
   selected input. This is the opposite choice from the anchor on S6/§7.3, and
   it is the one that matters: a testbench that learned the anchor's ready
   behaviour rather than reading S6 breaks here.
3. **Output depth** — one output register with `s_tready_o` combinationally
   dependent on `m_tready_i`, against the anchor's two-deep output datapath and
   registered ready.

### Non-equivalence witness

A second DUT that is secretly equivalent proves nothing, so the difference was
measured rather than asserted. Under identical stimulus over 200 cycles: the
golden asserts `s_tready_o` on more than one input simultaneously on **2**
cycles; the alt does so on **0**. Difference 2 is real and externally
observable.

### Result

**Passes the reference testbench on the first attempt. Zero rule-5
adjudications.**

That is the opposite of this project's base rate — `CONVENTIONS.md` records
`d_dsp02` going three for three the other way, and budgets three debug
iterations as normal cost. One data point, and the honest reading is that this
design is far simpler than an FMA rather than that the prior is wrong.

---

## 5. Conformant perturbations — 5, all survive

Full clause-by-clause enumeration, the licence each perturbation claims, and the
non-equivalence witnesses are in `conformant/README.md`. Every clause in the
spec is marked pinned or perturbed; one open clause (§7.7) is deliberately not
perturbed and the reason is recorded there.

---

## 6. Mutants — 6, all caught

Table, witnesses, and per-mutant clause isolation are in `mutants/README.md`.
Includes the required CAPABILITY-class member (`fm_m1`, silently supports half
the declared `DATA_WIDTH`).

Five of six trip exactly one clause. `fm_m3` trips S3 first and S10 later — one
defect, two symptoms — and that is recorded rather than described as clean
isolation.

---

## 7. What the reference testbench got wrong, and what found it

Expect a reference testbench to be incomplete on first use. This one was, in
four places, and **none of the four was found by reading it**:

1. **Drain deadlock read as data loss.** The first full run failed S5 with one
   beat outstanding on three inputs. The testbench had stopped offering beats
   mid-frame, leaving the design holding an incomplete frame — and nothing in
   the contract obliges a design to emit a frame whose source abandoned it. The
   testbench now quiesces on frame boundaries. **A testbench defect that
   presented as a design defect**, which is the failure mode a spec-only task
   is most exposed to.
2. **S10 reported an S3 violation.** The fairness counter's frame-start detector
   was derived from the atomicity checker's owner state, so interleaving kept
   the owner asserted, no start was ever registered, and every input's counter
   ran away. `fm_m3` was killed under the wrong clause. The two are now
   independent.
3. **The reset mutant was attributed to the payload check.** A stale beat
   surviving reset misaligns the stream, so S4 fired before anything
   reset-specific. The checker now retains the beats discarded at reset and
   recognises one when it reappears; `fm_m6` reports S12.
4. **The witness harness could not see two of the things it was witnessing.** It
   compared only tdata and tlast, so `fm_m4` — a tuser-only mutant — reported
   *"NO DIFFERENCE OBSERVED, this wrapper may be a no-op"*; and it never reset
   mid-stream, so `fm_m6` had nothing to violate.

Also walked into a documented pothole: a comment line beginning with the word
`verilator` is parsed as a metacomment pragma and hard-errors with
`BADVLTPRAGMA`. `CONVENTIONS.md` records it. Knowing about it did not help.

### What the ceiling is worth

**6 of 6**, and report submissions against that, never as a bare fraction.

**It is weaker evidence than the same number on `v_ca05`.** There the mutants
found two genuine holes in the reference testbench on first use and the 6/6 was
earned by fixing them. Here the reference killed all six on the first run — the
mutants did not do their job on the reference, because one author wrote the
spec, the checker and the mutants in one sitting and every mutant targets a
clause the checker was built around. What the controls *did* find were the four
defects above, three of them in the checker and one in the witness harness.

The set has not yet been challenged by anything its author did not anticipate.
The first submission is the real test.

---

## 8. Measured margins

| | value |
|---|---|
| reference TB simulated time | ~21 µs against a 20 ms testbench watchdog — ~950× |
| reference TB wall time | 0.21 s cold, <0.01 s warm, against `sim_timeout_s: 25` — ≥119× |

Both are deliberately generous. A watchdog tuned near real runtime stops being a
liveness check and becomes a performance check on the submission, which nothing
in the spec licenses.

---

## 9. Wired into the scored path before any content was built

`sim_verification.sh` resolved the task, built the golden and ran a placeholder
testbench end to end **before** the spec was written — the order `d_dsp02`
(F22) got wrong. The smoke-test run record was deleted afterwards: it recorded
`golden_accepted: PASS` for a testbench that checks nothing, which reads like a
result and is not one.

## 10. Reported separately, not fixed here

- `TASK_CATALOG.md:166`'s fairness claim is wrong for the module as it stands
  (§1 above). Agent 1 is correcting the catalog.
- The second-DUT gate checks the declaration, not the measurement. Nothing runs
  `dut2/`.
