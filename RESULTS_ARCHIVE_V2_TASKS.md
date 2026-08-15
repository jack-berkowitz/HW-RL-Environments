# Archived results — three superseded v2 design tasks

`ai_d01`, `ca_d08` and `nw_d01` were removed from `domains/` as too easy to carry
forward. Their measured results are preserved here because they are still
evidence about **where the difficulty floor sits**, which is the claim the v3
catalog rests on.

The task directories are recoverable from git history at commit `1e9c455`. What
survives outside them: `candidates/{ai_d01,ca_d08,nw_d01}/`,
`orfs_runs/nw_d01_cand_chatgpt/`, and the ORFS flow reports under
`$ORFS_FLOW_DIR/reports/sky130hd/{ai_d01_int8_requant,nw_d01_axis_width_adapter,nw_d01_cand_chatgpt}/`.

## PPA, sky130hd

| task | design area | synth area | WNS | power | notes |
|---|---|---|---|---|---|
| `ai_d01` `int8_requant` | 275 995 µm² | 193 269 µm² | **−6.41 ns** | 1.47 W | does NOT close; 100 % combinational |
| `nw_d01` `axis_width_adapter` | 3 115 µm² | 2 079 µm² | +14.30 ns | 245 µW | closes with room to spare |
| `ca_d08` `tiny_core` | — | — | — | — | ORFS deferred (Class B) |

## `nw_d01` reference vs candidate — the v3 trigger, re-derived

| metric | reference | candidate | |
|---|---|---|---|
| synth area | 2 079 µm² | 2 117 µm² | candidate **1.8 % larger** |
| design area | 3 115 µm² | 3 014 µm² | candidate 3.2 % smaller |
| power | 245 µW | 184 µW | candidate 25 % lower |
| WNS | +14.30 ns | +13.71 ns | candidate slightly worse |
| **throughput, matched widths** | full rate | **half rate** | candidate 0.50 |

Three-way decomposition: **no off-spec configuration**, a **real capability gap**
(half throughput at matched widths, `k/(k+1)` narrow-to-wide), and **essentially
no genuine optimisation** — the area figures disagree in sign, and normalised for
delivered throughput the candidate is 21 % worse on area and 6 % better on power.

**Both reference and candidate pass 16/16** on the corrected gate. The earlier
comparison was invalid because the reference had never passed at all: its
`sim_flags` file was empty, so it failed every config on `MODMISSING`.

## Why these three were retired

`nw_d01` and `ai_d01` are small dataflow and arithmetic blocks; `ca_d08` is a
scoped single-issue core. All three were solved by a frontier model on the first
attempt. They mark the **floor**, not the band worth measuring — which is the
finding, and is why they are archived rather than simply discarded.

Caveat on every number above: WNS is comfortably positive for `nw_d01` and
negative for `ai_d01`, so in neither case was the design pushed against a binding
constraint. These are not evidence about difficulty until rerun at a period that
actually binds.
