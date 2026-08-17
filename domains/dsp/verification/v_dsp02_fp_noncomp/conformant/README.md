# v_dsp02 conformant perturbations — these MUST SURVIVE

Each wraps the unmodified golden and changes something `spec/fp_noncomp_spec.md`
§10 leaves open. A submitted testbench must accept all five; a failure here
means it checked something the specification never promised.

## Clause-by-clause enumeration

Every clause is listed and marked, not a candidate list.

| clause | open? | disposition |
|---|---|---|
| §0 op / op_mode encodings | no | **pinned** |
| A1–A3 format, canonical NaN, sNaN | no | **pinned** |
| S1, S2 SGNJ result and flags | no | **pinned** |
| S3–S6 MINMAX | no | **pinned** |
| S7–S11 CMP | no | **pinned** |
| S12, S13 CLASSIFY | no | **pinned** |
| S14 flags | no | **pinned** |
| H1–H3 handshake and ordering | no | **pinned** |
| H4 source obligation | n/a | constrains the testbench |
| S15 reset | no | **pinned** |
| S16 termination | n/a | constrains the testbench |
| §10.1 latency | **yes** | **perturbed → `fn_c1`** |
| §10.2 outputs while `out_valid_o` low | **yes** | **perturbed → `fn_c2`** |
| §10.3 `in_ready_o` promptness | **yes** | **perturbed → `fn_c3`** |
| §10.4 `result_o` during CLASSIFY | **yes** | **perturbed → `fn_c4`** |
| §10.5 `class_mask_o` for non-CLASSIFY | **yes** | **perturbed → `fn_c5`** |
| §10.6 unlisted `op_mode_i` values | **yes** | *not perturbed* — never driven, so there is no behaviour to vary. Confirmed load-bearing: the reference testbench drove MINMAX with mode 2 on its first run and the golden returned a don't-care value. |
| §10.7 internal structure | **yes** | covered by `fn_c1`'s extra stage |

## Non-equivalence witnesses (rule 16)

`mutants/nonequiv_tb.sv`, golden and perturbation on the same operation stream.

| id | licence | witness |
|---|---|---|
| `fn_c1` | §10.1 | 1008 of 1008 results arrive one cycle later; values identical |
| `fn_c2` | §10.2 | values and timing identical; **idle-line changes 92 vs 461** |
| `fn_c3` | §10.3 | 1005 of 1008 results shift in time; values identical |
| `fn_c4` | §10.4 | 144 CLASSIFY results differ on `result_o` only |
| `fn_c5` | §10.5 | 864 non-CLASSIFY results differ on `class_mask_o` only |

`fn_c2` is the instructive one. Its entire effect is on cycles the contract does
not constrain, so a harness comparing only valid results calls it a no-op — and
this one did, twice, for two different reasons. See `mutants/README.md`.

## Result

The reference testbench accepts all five. No neutralisation run was triggered:
that control fires when a perturbation *fails* and the question is whether the
wrapper or the checker is broken. Nothing failed.

The eleven wrappers here and in `mutants/` have machine-emitted port lists and
golden instantiations, identical outside each one's injected change. A
hand-copied port list is where a wrapper defect hides, and a broken wrapper
reads as a checker defect.
