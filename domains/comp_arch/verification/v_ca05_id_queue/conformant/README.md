# Conformant perturbations — a negative control for SPEC COMPLETENESS

**These are not mutants, and confusing the two inverts the result.**

| | ordinary mutant (`mutants/`) | conformant perturbation (`conformant/`) |
|---|---|---|
| relation to spec | **violates** it | **satisfies** it |
| what it exercises | the testbench's checking | the *specification's* completeness |
| desired outcome | **killed** by a good testbench | **survives** a good testbench |
| a failure means | the testbench is weak | **the spec is incomplete** |

Each perturbation changes behaviour the contract deliberately leaves open. A
correct implementation is free to behave this way, so a testbench that fails one
is relying on something the specification never promised — and that reliance is a
**spec defect found before a model trips over it**.

This is the only mechanical answer to *"I cannot prove I enumerated all the
load-bearing clauses."* You cannot enumerate them; you can perturb the open
behaviours and see which checks notice.

All are wrappers around the unmodified golden (per `CONVENTIONS.md`, mutants
perturb the anchor rather than reimplement it), so any observed difference is the
declared perturbation and nothing else.

## The set

| id | perturbation | licensed by |
|---|---|---|
| `c1` | `match_gnt_o` free-runs high regardless of `match_req_i` | R11 — completion is `req && gnt`; `gnt` alone promises nothing |
| `c2` | `pop_data_o` returns garbage whenever `pop_data_valid_o` is low | R10 — explicitly unconstrained |
| `c3` | `push_gnt_o` withheld on alternate cycles even when space exists | R6 — grant may be low for reasons other than fullness |
| `c4` | `pop_gnt_o` delayed by one cycle | latitude 6 — latency is unconstrained |

`c1` and `c2` are the two latent assumptions found by `sim/naive_tb.sv`: the
golden happens not to free-run `match_gnt_o`, and happens to return zero rather
than stale data when invalid. Neither is promised.

`c3` and `c4` perturb latitude that the spec states in prose but that no test had
ever exercised — which is rule 2 applied to the *latitude* rather than to the
requirements.

## Result

**All four survive. 1273 checks, 0 failures, on every one.**

| perturbation | non-equivalence witness | reference TB |
|---|---|---|
| `c1` | `match_gnt=1` vs `0` at t=40000 | **survives** |
| `c2` | `pop_data=59c2468b` vs `00000000` at t=40000 | **survives** |
| `c3` | `push_gnt=0` vs `1` at t=46000 | **survives** |
| `c4` | `pop_data=11110001` vs `00000000` at t=56000 | **survives** |

So the reference testbench relies on none of the four unpromised behaviours, and
this control found **no spec defect**. That is the desired outcome, and it is
weaker than it looks: it says these four open behaviours are not load-bearing,
not that the enumeration is complete. The method converts *"I might have missed
one"* from unfalsifiable into a list you can extend — it does not close it.

## Two things the control caught about itself

**`c4` was a no-op as first written** and would have "survived" while proving
nothing. It gated `pop_req_i & pop_req_d` — a throttle, not a delay — and every
output matched the golden exactly. Caught by `liveness_tb.sv`, which holds each
perturbation to the same non-equivalence bar as an ordinary mutant: a concrete
simulation counterexample, not an argument.

**A conformant perturbation that survives vacuously is worse than no control**,
because it reports the reassuring answer. This is the same shape as every
apparatus defect in `FINDINGS.md` and the reason the liveness check is not
optional.

**Random stimulus never reached `c4`'s distinguishing condition.** 300 cycles of
uniform random push/pop/match traffic produced no divergence; the witness needed
a *directed* single-cycle `pop_req_i` pulse with an entry present. Uniform random
drive both rarely hits that and tends to self-cancel, so the witness phase in
`liveness_tb.sv` is directed by construction.

