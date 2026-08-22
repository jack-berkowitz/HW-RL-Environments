# PROPOSED RULE — measurement apparatus must reproduce a known answer first

**Status: PROPOSED, NOT LANDED.** `RULES.md` is not edited by this file.
**From:** F60 (and F59 for the adjacent scope defect).

## The rule

> **Any apparatus used to produce a number must first reproduce known-good
> reference output, and that reproduction must be RECORDED alongside the numbers
> it licenses.**
>
> This covers every surface that produces a measurement: simulation probes and
> capture rigs, checkers and coverage floors, and ad-hoc measurement scripts.
> A number read off an apparatus that has not reproduced a known answer is not a
> measurement and may not be quoted.

## Why "measurement apparatus" and not "probe"

The wording was going to be "probe". It is not, because of F60's sixth instance.

Five of the six defects were probes or testbenches: drive/observe alignment,
buffered output lost on a watchdog, a monitor racing its own driver. The sixth
was **a bash loop that reused one `--Mdir` across every artifact it measured**.
A failed build leaves the previous binary in place, `[ -x ]` still passes, and
the loop silently re-runs the previous artifact. It reported a capability
mutant killing **6** vectors when the true number was **907** — it had re-run the
previous mutant and printed its number under the wrong name.

That loop was written in the same hour, for the express purpose of auditing this
class, in shell rather than RTL. **A probe-scoped rule would not have covered
the surface where the rule was actually needed.** The three surfaces are:

| surface | instance | would "probe" have covered it? |
|---|---|---|
| probes and capture rigs | one-cycle window missed; `iv=1` during reset | yes |
| checkers and coverage floors | negedge monitor race; the first band detector | arguably |
| ad-hoc measurement scripts | shared `--Mdir` loop, 6 reported vs 907 actual | **no** |

## Why the recording half is not optional

Reproducing a known answer is a habit that decays silently, and its decay is
invisible: nothing about a run says whether the operator checked first. Recording
the reproduction next to the numbers is what makes the check auditable later —
by someone who was not there, reading a table of results months on.

Both halves were done this session and the difference is visible in the record:

```
COUNTER VALIDATION: the reference must score 0 before any number below is read
  reference -> 0 kills on the pre-band 4290
  reference W=32 -> 0   W=64 -> 0
```

and per-artifact build directories replacing the shared one. Without the
recorded line, a later reader sees seven mutant kill counts and has no way to
know whether the counter was ever pointed at something whose answer was known.

## Relationship to the existing rules

This GENERALISES the standing requirement that **a check whose failure mode is
ABSENCE must be validated against a known-failing input** — moving it from
checkers to every instrument that produces a number, and adding the recording
obligation.

The two are the same idea seen from opposite ends:

* a check that cannot fail proves nothing when it passes;
* an apparatus that has not reproduced a known answer proves nothing when it
  reports one.

Floors 1 and 2 on `d_dsp03`'s band coverage are this rule applied to a FLOOR
rather than a probe: the floor was validated against two known-failing inputs —
a set with zero band coverage, and a synthetic set with 8 to 24 band hits per
format confined to a single rounding mode — and both validations are recorded in
the checker source next to the floor they license.

## What it would cost

Close to nothing where a reference exists, which is everywhere in this project:
one extra run and one line of output. The cost is real only where no known-good
answer exists yet, and that is exactly the case where an unvalidated number is
least defensible.

## What it does not claim

It does not claim the reproduction is sufficient. `nc_d` reproduced correctly on
the band vectors and was still wrong outside them — that is F59's defect, not
this one, and it needs the separate discipline of stating the region a
measurement covers.

---

# PROPOSED CONVENTION — committing a shared append-only file

**Status: PROPOSED, NOT LANDED.** `CONVENTIONS.md` is not edited by this file.
**From:** operational, twice this session.

## The problem

`FINDINGS.md`, `RULES.md` and `CONVENTIONS.md` are append-only files that every
agent writes to and nobody owns. Git stages whole files. So **whoever commits
carries whatever else is in the file at that moment** — another agent's finished
work, or worse, their half-written work — under a commit message describing
something else entirely.

This happened twice today. The first time was a finding-number collision (F50,
renumbered to F52). The second was this commit: `FINDINGS.md` contained Agent 2's
completed F55 and F56, 243 lines of v_nw02 work, and there is no way to stage
F57–F60 without them.

Interactive staging is not available in this environment, and reconstructing the
file to exclude another agent's content would *delete their uncommitted work* —
strictly worse than carrying it.

## The convention

> **When committing a shared append-only file, the commit message must NAME the
> other agents' content it carries, and the committer must VERIFY BY DIFF — not
> assert — that none of it was altered.**
>
> ```
> git diff HEAD -- FINDINGS.md | grep '^-' | grep -v '^---'
> ```
>
> Every removed line must be one the committer wrote. A removal anywhere else is
> a stop-and-report, not a merge conflict to resolve in passing.

## Why attribution and not avoidance

The instinct is to hold the file back until the other agent commits. That is
worse: it leaves findings unlanded, and a finding that is not in `FINDINGS.md`
cannot be cited by a rule, so `check_rule_linkage.py` cannot validate it. The
work does not exist as far as the graph is concerned.

Carrying the content is correct. Carrying it *silently* is what makes the
history unreadable later — a reader doing archaeology on F55 finds it in a
commit about floating-point underflow, with no explanation.

## Why the diff check is the load-bearing half

"I did not touch their content" is exactly the kind of claim that is true right
up until it isn't, and nothing about a commit reveals a stray edit inside a
region the committer was not thinking about. The diff makes it checkable in one
line, and it is the same discipline as the proposed measurement rule above:
**verify, then record the verification, rather than remember to be careful.**
