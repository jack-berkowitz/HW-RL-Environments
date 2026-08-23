# v_ca03 `id_width_conv` — evidence trail

**STATUS: steps 1-4 complete. Reference ceiling 5 of 5, second DUT built and
independent.** The conformant set is NOT built, so the task is not yet
scoreable end to end.

**Selected after `fpnew_divsqrt_multi` failed step 1** — see §0.

---

## 0. Why not divsqrt: the rejected anchor

`fpnew_divsqrt_multi` elaborated cleanly (12-file closure, SIMD ports a clean
tie-off at `vectorial_op_i = 0`) and **failed semantic confirmation on the axis
its difficulty rested on**:

| finding | evidence |
|---|---|
| does not round correctly | 3 of 6 RNE divisions off by one ulp against an exact-rational reference — `1/3`, `2/3`, `1/7` all truncate |
| two rounding modes wired to the wrong meaning | `roundmode_e` has RDN=2/RUP=3; the divider's own header defines `PLUSINF=2/MINUSINF=3`. Passed through unmapped at line 295, so **RDN and RUP are swapped** |
| one rounding mode does not exist | RMM=4 has no counterpart in a 2-bit field |
| an inexact result reports NX=0 | `1.0/49.0` |
| latency less variable than assumed | 1 cycle for special cases, **10 for everything else** — fixed-iteration with short-circuiting, not operand-dependent |

A spec this anchor satisfies would have to write RDN where IEEE says RUP, omit
RMM, and pin a truncation as round-to-nearest — inheriting defects as contract
terms, which is rule 15's prohibition and F14's shape. Corroborated by the
catalog: `d_dsp01` is the only DSP task marked **Class B**, and verification
tasks require Class A.

---

## 1. Anchor — step 1

| | |
|---|---|
| repo | `pulp-platform/axi`, SHL-0.51 |
| SHA | `4da15979747f326bde2f9869c64e587ce599772c` |
| file | `refs/axi/src/axi_iw_converter.sv` |
| closure | **18 files** — 10 from `axi`, 8 from `common_cells` |

**Provenance caveat.** Files present at the paths `refs.manifest.yaml` names, in
a repo `refs.lock` pins. Contents not verified against upstream at that SHA —
needs network, egress closed. Attests local state only.

### Elaboration — clean, and the closure is not readable off the source

`refs.lock` records this repo as `elaborates: partial`, and the converter is one
of the modules it warns "need concrete types". **A concrete-type wrapper built
with the vendored `AXI_TYPEDEF_ALL` macros resolves that**: 7 configurations
lint clean, covering both of the anchor's internal paths.

| config | path taken | |
|---|---|---|
| SLV 4 → MST 2, MAX_UNIQ 4 / 2 | remap | ok |
| SLV 6 → MST 2, MAX_UNIQ 4 | remap | ok |
| SLV 4 → MST 3, MAX_UNIQ 8 | remap | ok |
| SLV 4 → MST 2, MAX_UNIQ 8 | serialize | ok |
| SLV 5 → MST 1, MAX_UNIQ 4 | serialize | ok |
| SLV 6 → MST 2, MAX_UNIQ 16 | serialize | ok |

Data/address widths 32/64 in all four combinations: clean.

**`axi_demux_id_counters` is required and is invisible from reading** — nothing
in any module header mentions it, and it surfaced only when the serialize path
failed to elaborate. Recorded because a reader assembling this closure by
inspection will miss it.

### Semantic confirmation — every catalog claim holds

Reported separately from elaboration. Driven on the read path at
SLV_ID_W=4 → MST_ID_W=2, MAX_UNIQ_IDS=4:

| catalog claim | measured |
|---|---|
| ID-width conversion | 4-bit slave IDs carried on 4 distinct 2-bit master IDs — the maximum `MST_ID_W` allows |
| **table pressure, stall when no free ID** | four distinct slave IDs accepted; a **fifth distinct ID (9) was refused for the full 40-cycle budget** with nothing drained |
| responses under the original ID | R returned ids `0 1 2 3` at the slave port — the slave's own IDs, not the master's |
| recovery | after draining, slave ID 9 was accepted |

**This is the property the task is for.** A submission cannot check it by
comparing outputs: it has to maintain a model of which slave IDs currently hold
a table entry, and predict the stall.

---

## 2. Plumbing — wired before any content

`sim_verification.sh v_ca03` resolves the task, builds the golden and runs a
placeholder end to end. F22's order.

`dut/` is self-contained: **26 `include directives across 18 files replaced
verbatim** by the included text, because the harness passes no `-I` and the
verification half still has no `sim_flags` equivalent. Third task to need this.

The shim flattens four `parameter type` structs into a plain port map and ties
off `size`, `burst`, `lock`, `cache`, `prot`, `qos`, `region`, `user` and
`atop` — none participates in ID conversion, ordering or table occupancy, so
none could carry a clause.

---

## 3. What is NOT built

Spec, port map, reference testbench, second DUT, conformant set, mutants,
`probe/PASTE.md`. **No kill ceiling exists.**

**The mutant set will be built in the first pass with boundary-of-a-named-clause
members**, per the recipe. The boundaries this module offers are unusually good:
the table at `MAX_UNIQ_IDS` entries against one fewer, the per-ID transaction
count at `MAX_TXNS_PER_ID`, and the cycle an entry is freed against the cycle
after. Each is a state a clause can name and a mutant can sit exactly on.

---

## 4. Step 2 — which clauses force a MODEL, not a comparison

The selection criterion for this task was headroom, and headroom comes from
clauses a submission cannot discharge by comparing an output against an
expected value. Enumerated deliberately:

| clause | what a submission must maintain | model or compare |
|---|---|---|
| A2, A3 table size and the stall boundary | the **set** of slave ids currently outstanding, per direction | **MODEL** |
| A4 retirement frees an entry | the exact edge each id's last transaction completes on | **MODEL** |
| A5 depth per identifier | a **count** per id, not just membership | **MODEL** |
| B1 per-identifier ordering | a FIFO per id of accepted requests | **MODEL** |
| B3 write data ordering | the address-acceptance order, against the data stream | **MODEL** |
| C1, C2 identifier restoration | which transaction produced each response | **MODEL** |
| D1 distinct while co-outstanding | the live slave-id to master-id **mapping** | **MODEL** |
| D2 reuse only after retirement | that mapping *plus* retirement timing | **MODEL** |
| D4 one in, one out | a count on both ports | model (weak) |
| E1 payload integrity | — | compare |
| F1 reset | — | compare |

**Nine of eleven require state.** That is the difference from the three earlier
tasks, where a scoreboard plus an expected value per transaction was enough.

### The boundaries these clauses put in reach, for the first-pass mutant set

Every one is a state a clause names, with a design that can be right everywhere
except on it — the shape that produced `fn_m8` and `tt_m8`:

1. the table at `MAX_UNIQ_IDS` entries against one fewer (A3)
2. the per-id count at `MAX_TXNS_PER_ID` against one fewer (A5)
3. the cycle an entry is freed against the cycle after (A4, D2)
4. a same-id request at a full table, which A3 explicitly does **not** block
5. reads against writes at the shared boundary, which A1 counts separately

## 5. The spec was checked against the artefact before anything was built on it

Eight assertions the spec makes beyond step 1, all verified through the shipped
port map — `tb/audit/spec_conformance_probe.sv`:

| clause | check | result |
|---|---|---|
| A3 | at `MAX_UNIQ-1` distinct ids a new id is accepted | ok |
| A3 | at `MAX_UNIQ` distinct ids a new id is refused | ok |
| D1 | 4 co-outstanding slave ids use 4 **distinct** master ids | ok |
| A1 | a write with a 5th id is accepted while 4 reads are outstanding — reads and writes are counted separately | ok |
| A4 | after the reads drain, a new id is accepted | ok |
| A5 | a 2nd transaction with the same id is accepted | ok |
| A5 | a 3rd is refused at `MAX_TXNS_PER_ID = 2` | ok |
| C1 | responses carry slave ids 7 and 3, not master ids | ok |

A clause the golden does not satisfy would otherwise surface later as the
reference testbench failing its own validity gate, and be read as a checker
defect.

---

## 6. Step 3 — mutants built FIRST, then the model

The five boundary mutants were written **before** the reference testbench, so
the model was developed against the cases it has to distinguish rather than
against the golden alone. `tt_m8` survived v_ca05's reference precisely because
its boundary was not in view when that checker was written.

| mutant | violates | the boundary it sits on |
|---|---|---|
| `iw_m1_table_one_too_small` | A3 | stalls at `MAX_UNIQ-1` distinct ids instead of `MAX_UNIQ` |
| `iw_m2_depth_one_too_small` | A5 | refuses the 2nd transaction on an id where 2 are allowed |
| `iw_m3_entry_freed_late` | A4 | holds a retired entry three cycles past the freeing edge |
| `iw_m4_same_id_blocked_when_full` | A3 | blocks an **already-outstanding** id at a full table, which A3's second sentence forbids |
| `iw_m5_reads_and_writes_share` | A1 | counts reads and writes in one table where A1 counts them separately |

Each gates the slave-side valid and ready **together**, so the injected defect
is a stall that should not happen or the absence of one that should — never a
protocol violation. Each wrapper's occupancy tracker watches the **slave-port
handshakes only** and never reads inside the golden, so a mutant cannot inherit
the golden's blind spots.

### Ordering it this way changed the specification

Writing `iw_m3` first exposed that **A4 as originally drafted could not catch
it.** The clause said an entry is free "on that same edge" but latitude 3 lets
ready be low for arbitration, so a design holding the entry three cycles and
then accepting satisfied both. Measured on the golden: acceptance happens **0
cycles** after the retiring edge. A4 now states a **2-cycle window**, with that
measurement as its rationale — margin for a design that needs a cycle of
arbitration, and still a bound a testbench can check.

Had the mutant been written after the checker, the clause would have shipped
unfalsifiable and the mutant would have been unkillable.

### Result on first attempt: **5 of 5**

| mutant | first failure | all clauses |
|---|---|---|
| `iw_m1` | A3 | A3 |
| `iw_m2` | A3 | A3, then A5 |
| `iw_m3` | A4 | A4 only |
| `iw_m4` | A3 | A3 |
| `iw_m5` | A1 | A1 only |

`iw_m2` reports A3 before A5 because the A3 phase runs first and its
same-id-at-a-full-table case is also a second transaction on one id — one defect
with two symptoms, recorded rather than called clean isolation. Reordering the
phases would sharpen the attribution.

**Getting 5 of 5 first time is a weaker signal here than it looks**, and for the
reason this ordering was chosen: the model was written with the five boundaries
in hand. It says the model is right at the cases it was shown, not that it is
right at cases nobody has thought of. The conformant set and a submission are
what test that.

## 7. A rule-4 defect in the reference testbench, found by the mutants

Every mutant initially failed a **FLOOR** check as well as its own clause. The
coverage counters incremented only when the design **accepted** the offered
stimulus, so a design that wrongly refused work drove its own coverage to zero.

That is rule 4 exactly: *could a correct implementation score zero here?* — and
worse, a faulty one could. The floors now count what the testbench **offered**,
which is the only thing it controls. The mutants found this, not review.

---

## 8. Step 4 — the second DUT, and why its clean pass is evidence this time

It passes the reference testbench on the first attempt with zero rule-5
adjudications, which is the fourth in a row across four tasks. **That pattern is
ambiguous on its own** — it is equally consistent with a model that tracks the
contract and with a second implementation written by someone holding the same
picture of the table. So the difference was measured rather than asserted.

### The policies genuinely differ

Allocate two slave ids, retire the first, then allocate a new one:

| | master ids chosen |
|---|---|
| reference implementation | `0 1 0` then `0 1 0 2` — reuses the just-freed id (lowest-free) |
| this second DUT | `0 1 2` then `0 1 2 3` — takes the next in rotation, leaving the freed id alone |

**2 of 4 address handshakes differ in the master id chosen.** The reference
testbench accepted both, so it is not encoding "lowest-free" anywhere — which is
the specific way a model of this contract would most easily become a model of
*this implementation*. On the evidence, the clean pass is independence rather
than agreement.

**It does not show the model is complete.** It shows it is not policy-bound.

### The first measurement was wrong, and the probe was at fault

The first attempt reported *"same choices throughout — paraphrase risk"*. With
the table full, **only one master id is ever free**, so there is no choice to
differ on: both must pick it. A divergence requires two or more free ids with
the rotating pointer past the lowest, and the probe never created that state.
Same class as the v_dsp02 witness harness that could not see the thing it was
witnessing — the alarm was real, the cause was the instrument.

## 9. Sharpening rule 4, from what the mutants did here

Rule 4 says a coverage floor must measure stimulus, and tests it by asking
*could a correct implementation score zero here?* **This task produced the
sharper form of the same defect, and it is worse than the rule currently
states.**

Every one of the five mutants initially failed a FLOOR check as well as its own
clause, because the counters incremented only when the design **accepted** the
offered stimulus. So:

> **A faulty design can suppress the very coverage that would convict it.** The
> floor fires instead of the clause, and the defect is misattributed — a
> capacity bug reads as "the testbench never reached the state", which is
> exactly the diagnosis that sends a reader looking at the testbench instead of
> the design.

The existing test — *could a correct implementation score zero?* — does not
catch this, because a correct implementation scores fine. The test that does is:
**can the DUT influence this counter at all?** If the answer is yes, the floor
is measuring the design.

Floors here now count what the testbench **offered**, which is the only quantity
it controls. Found by running the mutants, not by review.
## The difficulty pivot — the mutant set was rebuilt

The five previous mutants were boundary-shaped, which was the right instinct,
but every one of them was **total**: it held on every transaction of its class
and so fired on the first one any testbench drove. That measures coverage, not
checking.

Ten guarded defects replace them. Each pairs a wrong behaviour with a rare
predicate over contract-level state — a burst length, how many identifiers are
outstanding, how long the table has been full, an ordinal beat or response, how
busy the table was at a retirement. Guards read the slave port handshakes and
the golden's own response stream, never its table, so each can be restated
against an independent design.

### The reference was the weaker half

It killed **three of ten**. It was read-only and single-beat: the master-side
responder returned one constant beat with `rlast` always high, so a correct
response and a wrong one looked identical. C1, E1 and D4 were unchecked, and
nothing on the write side had ever been driven.

Rebuilt, it honours `arlen`, derives each beat's data from the address its own
transaction carried — which E1 forwards unmodified, so the expectation follows
from the contract rather than from the design — checks every beat rather than
only the last, drives writes and checks their responses, and sustains enough
traffic to pass a count in the dozens. 10/10, with all five conformant
perturbations still passing.

### Two silent instruments

`BOUNDARY 5` accepted a write address and never supplied its `W` burst. That
transaction stayed outstanding for the rest of the run holding a table entry, so
every later write boundary was measured one entry short — and the failure was
reported against the design.

The witness runner used `sed` with `\b`, which BSD sed does not support. The
rename that substitutes a mutant for the golden matched nothing, so every
witness ran the **golden** and reported "no failure observed" for ten mutants
the harness kills. Both are the same shape as F26: a check whose stated scope
exceeds its reach, reporting silence as a result.

