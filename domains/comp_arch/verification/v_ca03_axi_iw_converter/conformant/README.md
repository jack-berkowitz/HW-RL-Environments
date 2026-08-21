# v_ca03 conformant perturbations — these MUST SURVIVE

Each wraps the unmodified golden and changes something the specification
deliberately leaves open. A submitted testbench must accept all five.

## Clause-by-clause enumeration

Every clause is listed and marked. `d_dsp02` declared its conformant set empty
and two open behaviours were found on the first challenge, so this is an
enumeration and not a candidate list.

| clause | open? | disposition |
|---|---|---|
| A1 outstanding, reads and writes counted separately | no | **pinned** |
| A2 table size | no | **pinned** |
| A3 the stall boundary | no | **pinned** — the property under test |
| A4 retirement, 2-cycle window | no | **pinned** — the bound *is* the contract |
| A5 depth per identifier | no | **pinned** |
| B1 per-identifier ordering | no | **pinned** |
| B2 no ordering between identifiers | **yes** | *not perturbed* — see below |
| B3 write data ordering | no | **pinned** |
| C1, C2 identifier restoration | no | **pinned** |
| D1 distinct while co-outstanding | no | **pinned** |
| D2 reuse only after retirement | no | **pinned** |
| D3 which master identifier is chosen | **yes** | **perturbed → `iw_c1`** |
| D4 one transaction in, one out | no | **pinned** |
| E1 payload integrity | no | **pinned** |
| F1 reset | no | **pinned** |
| G1 termination | n/a | constrains the testbench |
| §8.1 allocation order | **yes** | **perturbed → `iw_c1`** |
| §8.2 latency | **yes** | **perturbed → `iw_c2`** |
| §8.3 ready promptness outside A4 | **yes** | **perturbed → `iw_c3`, `iw_c5`** |
| §8.4 order between identifiers | **yes** | *not perturbed* — same as B2 |
| §8.5 outputs while valid is low | **yes** | **perturbed → `iw_c4`** |
| §8.6 shared or separate tables | **yes** | *not perturbed* — see below |
| §8.7 internal structure | **yes** | covered by `iw_c1` and `iw_c2` |

**B2 / §8.4 is open and deliberately not perturbed.** The order of responses
between different identifiers is chosen by whatever drives the master port —
the testbench — not by this design. There is no DUT-side behaviour to vary, so
a perturbation would be theatre. Recorded rather than silently omitted.

**§8.6 is open in wording only.** A1 already requires reads and writes to be
counted separately, which forecloses a genuinely shared table; the clause as
drafted is looser than A1 and nothing can be varied inside it without violating
A1. **This is a spec defect of the harmless kind — a latitude clause that
grants nothing** — and it is recorded here rather than quietly dropped.

## The set

| id | licence | change |
|---|---|---|
| `iw_c1_permuted_allocation` | D3, §8.1 | master identifiers permuted through a bijection (0↔2, 1↔3), inverse applied to responses |
| `iw_c2_extra_latency` | §8.2 | one register stage on the master read-address path |
| `iw_c3_ready_withheld` | §8.3 | ready withheld one cycle in four |
| `iw_c4_garbage_when_invalid` | §8.5 | LFSR noise on every output while its valid is low |
| `iw_c5_channel_arbitration` | §8.3 | when both address channels offer, only one is admitted, alternating |

`iw_c3` and `iw_c5` are bounded so that the worst delay either adds is a single
cycle, which keeps **A4's two-cycle window intact**. A perturbation that broke a
clause it was not licensed against would be a mutant, not a perturbation.

`iw_c1` is the one rule 16 is really aimed at. Most of this task's latitude is
allocation policy, and **a policy change the table cannot express is a silent
no-op**. A bijection on the master identifier space is expressible: it preserves
D1 (distinct stays distinct) and D2 (a value is free exactly when its image is),
and it is measurably different.

## Non-equivalence witnesses (rule 16)

`nonequiv_tb.sv`, golden and perturbation driven by independent drivers walking
the same deterministic request sequence.

| id | witness |
|---|---|
| `iw_c1` | master id at request 0: golden **0**, perturbation **2** — all 40 differ |
| `iw_c2` | master request cycle at 0: golden **1**, perturbation **2** — all 40 differ |
| `iw_c3` | acceptance cycle at 0: golden **1**, perturbation **2** — 30 of 40 differ; idle-line changes 10 vs 20 |
| `iw_c4` | values and cycles identical throughout; **idle-line changes 10 vs 130** — its whole effect is where the contract is silent, which is exactly its licence |
| `iw_c5` | master id at request 3: golden **3**, perturbation **0** — 19 differ; acceptance cycle at 1: golden **2**, perturbation **3** |

### Two of these first reported as no-ops, and the harness was at fault

`iw_c2` and `iw_c5` initially reported *"NO DIFFERENCE OBSERVED — may be a
no-op"*. Neither was:

* the harness compared master **identifiers** and slave **acceptance** cycles,
  and `iw_c2` changes only when the master request is *issued*. Master-request
  timing is now captured.
* the harness drove reads only, so the two address channels never contended and
  `iw_c5`'s arbitration was **unreachable**. Writes are now driven.

Third time an instrument has reported the reassuring answer because it could not
see the thing it was measuring — after the v_dsp02 witness harness and the
v_ca03 second-DUT probe. The alarm was right both times; the cause was the
instrument.

## Result

The reference testbench accepts all five, and still catches 5 of 5 mutants. No
neutralisation run was triggered: that control fires when a perturbation
*fails*, and none did.
