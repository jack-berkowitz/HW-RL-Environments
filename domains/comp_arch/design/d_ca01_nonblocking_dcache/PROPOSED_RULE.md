# PROPOSED for RULES.md — NOT LANDED. Agent 3 does not edit RULES.md.

> **LANDED. Rule 21 is in `RULES.md` at line 347; marked 2026-08-27.** The
> heading above is stale and says the opposite of the truth to anyone who opens
> this file. Kept as written: this is the proposal text, and `RULES.md` is the
> authority for what the rule now says — the two differ slightly in wording.

Text ready to paste. Numbered 21 on the assumption nothing else is pending.

---

21. **Every mutant carries recorded evidence of non-equivalence, and the TYPE is
    recorded per mutant.** Two accepted values:

    - **`witness`** — a named clause fails at a named configuration under a
      named stimulus. This demonstrates non-equivalence *under that stimulus*.
    - **`bmc_cex`** — a bounded counterexample: a concrete input sequence on
      which mutant and reference differ from an **identical initial state**.
      This is a proof of non-equivalence.

    **The kill rate is not evidence and never implies the type.** A mutant that
    every checker kills may still be equivalent to the reference on the axis the
    checker measures; a mutant nothing kills may be profoundly non-equivalent
    and merely unexercised. The two quantities answer different questions and a
    results table that carries one must not be read as carrying the other.

    **A mutant that can obtain neither is CUT from the set, and the cut is
    recorded** with the reason. A mutant of unknown status is worse than no
    mutant: it inflates the denominator of every kill rate computed from the set.

    **A `bmc_cex` depth is the depth at which the counterexample was FOUND.** It
    is not a statement about how far the miter has been shown sound. Where a
    control establishes miter soundness to a different depth, that figure is
    recorded separately and the two are never combined into one number.

    **From:** `no-smt-backend-behind-sby-and-eqy`, and the diff-rate retraction
    — which refused exactly the claim that "non-equivalent under this stimulus"
    and "non-equivalent" are the same statement.

---

## Consequences for existing tasks, if this lands

| task | current evidence | action |
|---|---|---|
| `d_ca01` | `bmc_cex` on all six, depths recorded | none |
| `d_dsp02` | `witness: "vector N"` on all six | already compliant — `witness` is an accepted type |
| `d_ca04` | not recorded in a machine-readable field | needs a field, not new work |

The rule does **not** require anyone to redo `d_dsp02`. `witness` is accepted;
what the rule forbids is leaving the type *unrecorded* so a reader cannot tell
which claim a kill count rests on.
