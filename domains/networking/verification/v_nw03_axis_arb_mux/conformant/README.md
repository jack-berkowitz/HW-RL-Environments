# v_nw03 conformant perturbations — these MUST SURVIVE

Each wraps the unmodified golden and changes something
`spec/frame_arb_mux_spec.md` deliberately leaves open. A submitted testbench
must accept all five. A failure here means the testbench checked something the
specification never promised — a defect in the submission, or a gap in the
spec's §7, never in these files.

| | `conformant/` | `mutants/` |
|---|---|---|
| relation to spec | satisfies | **violates** |
| desired outcome | **survives** | killed |
| a failure means | the **spec** is incomplete | the **testbench** is weak |

## Clause-by-clause enumeration

Not a candidate list. Every clause in the specification is listed and marked,
because `d_dsp02` declared its conformant set empty and two open behaviours were
found on the first challenge.

| clause | open? | pinned / perturbed |
|---|---|---|
| S1 beat = valid && ready | no | **pinned** — protocol definition |
| S2 frame = beats through tlast | no | **pinned** |
| S3 frame atomicity | no | **pinned** — the property under test |
| S4 payload integrity and order | no | **pinned** |
| S5 no loss, no duplication | no | **pinned** |
| S6 ready is not a grant | **yes** | **perturbed → `fm_c1`** |
| S7 source stability | n/a | constrains the testbench, not the design |
| S8 backpressure tolerated | no | **pinned** |
| S9 selection order | **yes** | **perturbed → `fm_c2`** |
| S10 bounded fairness, window 16 | no | **pinned** — the bound is the contract |
| S11 latency | **yes** | **perturbed → `fm_c3`** |
| S12 reset | no | **pinned** |
| S13 termination | n/a | constrains the testbench |
| §7.4 output lines while invalid | **yes** | **perturbed → `fm_c4`** |
| §7.5 back-to-back frames | **yes** | **perturbed → `fm_c5`** |
| §7.6 internal structure | **yes** | covered by `fm_c3`'s extra register stage |
| §7.7 tkeep on non-final beats | **yes** | *not perturbed* — see below |

**§7.7 is the one open clause with no perturbation, and that is deliberate.**
The clause says only that whatever arrived with a beat leaves with it, which is
already S4; there is no separate behaviour to vary that would not also violate
S4. Recorded rather than silently omitted.

## The set

| id | licence | change |
|---|---|---|
| `fm_c1_ready_withheld` | S6, §7.3 | each input's ready is withheld on a rolling 1-in-4 schedule |
| `fm_c2_reversed_order` | S9, §7.1 | inputs served in the opposite rotation (port permutation) |
| `fm_c3_extra_latency` | S11, §7.2 | one extra output register stage |
| `fm_c4_garbage_when_invalid` | §7.4 | LFSR noise on tdata/tkeep/tuser while `m_tvalid_o` is low |
| `fm_c5_idle_between_frames` | §7.5 | one forced idle cycle after every frame |

`fm_c1` and `fm_c5` gate the valid and the ready **together**, so no cycle
exists in which one side believes a beat transferred and the other does not. A
wrapper that gated only one of them would inject a real data defect and would be
a mutant, not a perturbation.

## Non-equivalence witnesses (rule 16)

A perturbation that is secretly a no-op survives and reports the reassuring
answer, which is worse than having no control at all. `mutants/nonequiv_tb.sv`
drives the golden and the perturbation from identical input streams and reports
the first output beat where the value, the transfer cycle, or the behaviour of
the idle lines differs.

| id | witness |
|---|---|
| `fm_c1` | value differs at beat 0; transfer cycle differs at beat 1 (golden 4, variant 5) |
| `fm_c2` | value differs at beat 0 — different input served first; cycles identical |
| `fm_c3` | transfer cycle differs at beat 0 (golden 3, variant 4) — one added cycle |
| `fm_c4` | values and cycles identical over 400 beats; **idle-line changes 0 vs 4** — its entire effect is on cycles the contract does not constrain, which is exactly its licence |
| `fm_c5` | transfer cycle differs at beat 5 (golden 8, variant 9); 97 idle-line changes |

`fm_c4` is the instructive row. Its non-equivalence exists *only* where the spec
is silent, so any harness comparing valid beats alone would call it a no-op. The
idle-line counter is the reason it can be shown to do something at all.

## Result

The reference testbench accepts all five. No neutralisation run was triggered —
that control fires when a perturbation *fails* and the question is whether the
wrapper or the checker is broken. Nothing failed, so nothing needed it.
