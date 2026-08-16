# v_ca05 mutant set — these MUST BE KILLED

The discriminating measure for a submitted testbench. Opposite sign to
`conformant/`: those satisfy the spec and must survive; these violate it and
must be caught.

| | `conformant/` | `mutants/` |
|---|---|---|
| relation to spec | satisfies | **violates** |
| desired outcome | survives | **killed** |
| a failure means | the **spec** is incomplete | the **testbench** is weak |

All six wrap the unmodified golden with one thing changed, so anything observed
is the injected defect and nothing else.

## The set

| id | class | defect | violates |
|---|---|---|---|
| `m1` | boundary | accepts `SLOTS−1`, asserts `full_o` one entry early | R1 |
| `m2` | ordering | returns the **newest** entry for a tag, not the oldest | R2 |
| `m3` | capability | every transaction correct, **half** the capacity | R1 |
| `m4` | liveness | pushes to **tag 0** never granted; no deadlock | R1 |
| `m5` | data | masked compare **ignores bits [31:24]** | R12 |
| `m6` | boundary | `empty_o` high at exactly **one** entry | R14 |

`m3` is the class that motivated the benchmark: correct on every transaction
while carrying a fraction of the required capacity. `m4` is starvation rather
than deadlock on purpose — a deadlock stops everything and any timeout catches
it.

## Non-equivalence witnesses — every mutant is demonstrably killable

`nonequiv_tb.sv` compares outputs against the golden directly, so a mutant no
current testbench happens to catch is still shown to be catchable. **"Nothing
killed it yet" and "nothing can" are different claims**, and only the second
justifies withdrawing a mutant.

| id | witness |
|---|---|
| `m1` | `push_gnt 0 vs 1` @ t=106000 |
| `m2` | `pop_data a0000006 vs a0000000` @ t=136000 |
| `m3` | `push_gnt 0 vs 1` @ t=76000 |
| `m4` | `push_gnt 0 vs 1` @ t=40000 |
| `m5` | `match_hit 1 vs 0` @ t=146000 |
| `m6` | `empty 1 vs 0` @ t=46000 |

## Results — the set discriminates, and it caught us first

| testbench | golden | conformant | m1 | m2 | m3 | m4 | m5 | m6 |
|---|---|---|---|---|---|---|---|---|
| reference TB, **as first written** | PASS | 4/4 | kill | kill | kill | **miss** | **miss** | kill |
| reference TB, **corrected** | PASS | 4/4 | kill | kill | kill | kill | kill | kill |
| `chat` submission | PASS | 4/4 | **hung** | kill | **hung** | **hung** | **miss** | kill |

**The set found two holes in our own reference testbench on first use.** It
never pushed to tag 0 in a way that could expose starvation — the capacity fill
used tag 5 and the random phase never *required* a grant — and it never searched
with a mask covering the top byte. Both are now fixed and it kills 6/6.

**The corrected reference re-passes all four conformant perturbations.** That
check is not a formality: adding checks is exactly when a testbench starts
depending on things the spec never promised, and the perturbations are the
control for it. Specifically, the tag-0 check waits for a grant with a timeout
rather than requiring an immediate one, because **R6 licenses `push_gnt_o` being
low for reasons other than fullness** — requiring promptness would have been
checking something unpromised, and `c3` would have caught it.

`m5` is retained on that evidence. It was missed by both testbenches tried, which
raised the question of whether anything could kill it; the corrected reference
does, using a mask of `0xFF000000` that R12 licenses exactly as written. **A
mutant nobody kills compresses the score range and proves nothing** — the same
defect as one everybody kills, in the other direction.

**A submission is only interpretable against a 6/6 reference.** `chat`'s 2 kills
were scored before the reference was corrected; the number is unchanged but its
meaning is not, because the ceiling is now known to be 6.

## What is still missing

Per-mutant results are reported, never a rate. A total would average away the
informative part — *which* mutant survived — and `chat`'s row shows why: 2 kills,
3 hangs and 1 miss are four different problems and one number hides all of them.

**A kill from a submission that failed the golden carries no information** —
a testbench that rejects everything appears to kill everything. Rule 16.
