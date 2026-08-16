# d_dsp02 conformant perturbations — RETIRED, and the reason is the finding

**There is no conformant perturbation set for this task, and that is a
consequence of rule 18 rather than an omission.**

## What happened to `cPIPE3`

`cPIPE3` was a three-stage pipelined binding, licensed by the spec clause
*"LATENCY IS NOT CONSTRAINED AND NOT CHECKED."* Spec clause **S1 now pins
latency at 3 cycles**, so:

- **its licence clause no longer exists**, and
- **it is no longer a perturbation at all** — three stages is now the scored
  configuration, so `cPIPE3` and the reference are the same design.

It is deleted rather than kept, because a "perturbation" identical to the
reference is the purest form of the no-op control this project keeps finding
(F25): it would pass every run and prove nothing, while looking like a control.

## Why nothing replaced it

Rule 18 requires re-deriving the set against the new spec — every perturbation's
licence clause must still exist. Working through what the spec still leaves
open:

| candidate perturbation | licence | why it is not usable |
|---|---|---|
| register placement within the 3 stages | **S1a**, genuinely open | **not simulation-observable.** Same latency, same results, same II. Only PPA distinguishes them. |
| deeper or shallower pipeline | none — S1 pins it | now a spec violation, i.e. a mutant |
| `in_ready` timing | H1 pins it | closed |
| output stability under backpressure | H3 pins it | closed |
| result ordering | H4 pins it | closed |

**S1a's freedom is real but lives in the wrong dimension.** A placement-only
perturbation would be simulation-identical to the reference, so running it
through the checker measures nothing — the F25 failure mode exactly, where four
of five rows silently ran the same design and reported PASS.

The one candidate that *would* be simulation-observable — varying how much the
design keeps accepting while the output is backpressured — was rejected because
**I could not establish that it is conformant rather than a C3 violation.**
Shipping a violation labelled "conformant" is worse than shipping no control:
the conformant set's whole purpose is that a failure indicts the spec, and a
mislabelled member would indict the spec for a real defect.

## What this costs, stated plainly

The conformant set is the control for *spec completeness* — it catches a checker
relying on something the contract never promised. **This task no longer has that
control**, and the honest reason is that its contract is now tight enough to
leave nothing simulation-observable open.

That is a real trade rule 18 makes: pinning an axis buys a tractable baseline
and gives up the perturbation that axis licensed. Worth knowing rather than
discovering later.

**If a control is wanted here, it belongs in the PPA comparison**, not the
checker: two register placements at the same pinned depth are the same contract
built two ways, and a large PPA gap between them would be informative about the
flow rather than about the spec.
