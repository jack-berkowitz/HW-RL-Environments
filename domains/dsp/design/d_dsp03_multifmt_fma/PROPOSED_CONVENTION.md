# PROPOSED CONVENTION — committing a shared append-only file

**Status: PROPOSED, NOT LANDED.** `CONVENTIONS.md` is not edited by this file.
**From:** operational, three times in one session.

> The measurement-apparatus rule that used to head this file has LANDED as
> **rule 24** in `RULES.md`. It is not restated here: rule text lives in
> `RULES.md` and nowhere else (rule 13). What remains below is convention —
> how to avoid a known pothole — and is destined for `CONVENTIONS.md`.

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

## Attribution must be ESTABLISHED, not inferred from subject matter

The convention above says to NAME the other agent's content you carry. That is
only useful if the name is right, and getting it wrong is easy in a way that
feels like knowledge.

**Instance.** `d6d3423` and `409f4a1` both attributed F55, F56, rule 23 and a
rule-20 amendment to Agent 2. The reasoning was never stated because it was
never examined: F55 and F56 are about `v_nw02`, `v_nw02` is Agent 2's task,
therefore Agent 2 wrote them. Subject matter is not authorship. Agent 1 wrote
all four, in that session; what is Agent 2's is the DEFECT — they stopped on it
at `v_nw02` (`612f803`), reported that `negctl/null_tb.sv` drives nothing,
observes nothing and was being scored VALID, and re-verified the fix across five
tasks afterwards.

The same commit misattributed the five staged deletions under `candidates/` to
Agent 2 on the same reasoning — they are Agent 2's *files*. Agent 1 staged them.

Both halves matter, and flipping the name wholesale would have been a second
error in the opposite direction: **the defect is Agent 2's, the writeup and the
mechanism are Agent 1's.**

> **Before writing another agent's name in a commit message, ask them. A
> teammate is one message away and the cost of asking is a round trip; the cost
> of guessing is a permanent record that credits the wrong person for work and
> the wrong person for a mistake.**

Provenance and authorship are separate fields and a commit message should carry
both when it carries either.

## Why the diff check is the load-bearing half

"I did not touch their content" is exactly the kind of claim that is true right
up until it isn't, and nothing about a commit reveals a stray edit inside a
region the committer was not thinking about. The diff makes it checkable in one
line, and it is the same discipline as the proposed measurement rule above:
**verify, then record the verification, rather than remember to be careful.**

## Addendum — the unit is the finding-and-rule PAIR, not the file

Attribution and a no-alteration diff are **necessary and not sufficient**.

`check_rule_linkage.py` enforces a BIDIRECTIONAL invariant across two files:
every finding cites a rule that exists, and every rule cites a finding that
exists. So **any commit boundary that cuts between a finding and the rule it
cites yields a tree that fails its own check** — no matter how carefully either
half was staged.

**Instance: `d6d3423`.** That commit was staged correctly, attributed
explicitly, and diff-checked (`git diff HEAD -- FINDINGS.md` showed zero removed
lines, so nothing pre-existing was altered). It carried Agent 2's completed F55
and F56 because the file cannot be staged per-hunk. It still broke the
invariant: F55 and F56 cite rule 23, which lived only in Agent 2's uncommitted
`RULES.md`. Against the committed tree:

```
rules: 22   findings: 65   conventions: 29
LINKAGE BROKEN -- 2 problem(s):
  finding F55 cites rule 23, which does not exist in RULES.md
  finding F56 cites rule 23, which does not exist in RULES.md
```

Clean in the working tree, broken in the tree anyone else would fetch. Every
individual precaution held and the result was still a repository that fails its
own consistency check.

So the convention needs a third clause:

> **When carrying another agent's content in a shared file, carry the whole
> citation graph it participates in.** A finding and the rule it cites are ONE
> unit. Check the tree, not the file: extract the commit and run
> `check_rule_linkage.py` against the extraction before considering the commit
> done.

## Addendum — committing when the shared index holds another agent's staging

Also worth requiring rather than improvising, because it came up in the same
commit and the obvious moves are both wrong.

The shared index held five staged deletions of `candidates/v_*/reference.sv`
belonging to Agent 2, in flight. `git add` + `git commit` would have carried
them into an unrelated commit. `git restore --staged` would have undone their
staging. `git commit -- <paths>` cannot add untracked files, so it is not an
escape either.

What works, and should be the standing answer:

```bash
export GIT_INDEX_FILE=/tmp/myidx        # a PRIVATE index
git read-tree HEAD
git add <explicit paths>                 # never -A
TREE=$(git write-tree)
unset GIT_INDEX_FILE
NEW=$(git commit-tree $TREE -p HEAD -F msg.txt)
git update-ref HEAD $NEW
```

**A FOURTH STEP IS REQUIRED, and omitting it is what made this dangerous.** The
procedure above protects the other agent's staging AT COMMIT TIME and then
leaves the real index stale against the new HEAD, because `commit-tree` +
`update-ref` never touch it. Measured: after two temp-index commits the shared
index still held the previous `RULES.md` and `FINDINGS.md` blobs, so a plain
`git commit` from it would have REVERTED a rule that had just landed.

    git read-tree HEAD                       # refresh the real index
    git add -A -- <the other agent's paths>  # re-stage what was there

`git update-index --force-remove` is NOT the way to re-stage a deletion: it
fails silently and leaves the deletion unstaged. `git add -A --` with explicit
paths works.

> **The failure is silent in BOTH directions and neither agent saw their own.**
> One index carried staged deletions of seven of the other agent's files; the
> other carried blobs that would have reverted a just-landed rule. Same root
> cause, opposite sign, and in both cases `git status` showed something that
> looked entirely ordinary. Each was found by the other agent, not by its owner.

then **verify the real index is untouched, do not assume it**:

```bash
cmp .git/index /tmp/real_index.bak
```

The shared index is shared mutable state and nothing about a commit reveals that
another agent was mid-stage in it. The `cmp` is the same discipline as the
no-alteration diff and the apparatus reproduction above: verify, and record the
verification.

## Addendum — candidate artefacts are committed ON ARRIVAL

Not when the surrounding work is ready, not when the batch is complete, not
when the scoring run finishes. **On arrival.**

This is the same shape as the two collisions above, and it is the one that
actually cost something. Three instances in one session:

1. Agent 1's F55, F56, rule 23 and the rule-20 amendment sat uncommitted in
   shared files, and were carried into someone else's commit — recoverable,
   and only because a diff showed what was there.
2. This convention draft sat uncommitted in a file that a literal reading of
   "delete PROPOSED_RULE.md" would have removed — caught by reading the
   instruction against the file rather than executing it.
3. **A candidate submission was lost.** `candidates/d_dsp02/claude.sv` existed
   on disk, was never committed, and re-solicitation overwrote it. Its identity
   survives in a run record (`submission_sha256_16 7b3240027cc7837c`); its
   content is gone permanently.

> **The first two were caught by a diff. The third had no diff to catch it —
> the file had never been in git, so nothing anywhere registered a change. The
> loss was silent and total.**

That is why this addendum is not "commit more often". A submission is an
EXTERNAL ARTEFACT: it cannot be regenerated, because the model that produced it
is not deterministic and its version may no longer be reachable. Losing a
derived file costs a rebuild. Losing a solicited answer costs the answer.

**The practical rule:** a file arriving from outside the project — a model
submission, a vendored drop, a hand-collected log — is committed before any
work is done ON it, including before it is scored. A commit whose message is
only "land <model>.sv as received" is a complete and correct commit.

The consequence in the record is visible now: `deepseek` and `qwen` carry
withdrawal rationales and `claude` does not, because claude's prior artefact was
not withdrawn, it was lost. Recording that distinction after the fact required
reconstructing intent from a run record. Committing on arrival would have made
it a one-line diff instead.
