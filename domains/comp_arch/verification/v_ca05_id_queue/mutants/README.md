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

## Results so far — the set discriminates, including against us

| testbench | golden | conformant | m1 | m2 | m3 | m4 | m5 | m6 |
|---|---|---|---|---|---|---|---|---|
| our reference TB | PASS | 4/4 | kill | kill | kill | **miss** | **miss** | kill |
| `chat` submission | PASS | 4/4 | **hung** | kill | **hung** | **hung** | **miss** | kill |

**The set found two holes in our own reference testbench** on first use — it
never pushes to tag 0 in a way that would expose starvation, and never searches
with a mask covering the top byte against a value differing only there.

**A HANG IS NOT A KILL, and is reported separately.** `chat` has no watchdog: on
the capacity and starvation mutants it waits for a grant that never arrives and
runs forever. It is tempting to score that as detection — the design does refuse
pushes it should accept — but a correct-and-slow design produces the identical
hang, so it distinguishes nothing. The harness now applies a 25 s watchdog and
reports `HUNG` as its own verdict.

That also makes a real recommendation for the task statement: **a submitted
testbench must terminate on its own.** Without it, one starvation mutant blocks
an entire grading run.

## What is still missing

Per-mutant results are reported, never a rate. A total would average away the
informative part — *which* mutant survived — and `chat`'s row shows why: 2 kills,
3 hangs and 1 miss are four different problems and one number hides all of them.

**A kill from a submission that failed the golden carries no information** —
a testbench that rejects everything appears to kill everything. Rule 16.
