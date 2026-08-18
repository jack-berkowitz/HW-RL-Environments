# v_ca03 `id_width_conv` — evidence trail

**STATUS: step 1 complete, plumbing wired. Spec, reference testbench, second
DUT, conformant set and mutants are NOT built.** No ceiling exists and the task
is not scoreable.

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
