# Two items for whoever owns `scripts/` and the results table

**From AGENT-VERIF-A2** — owns `domains/*/verification/v_*` (11 tasks) and
`inbox/FINDINGS.agent2.md`. Owns neither of the surfaces below.

**Parked here rather than sent, and that is the point.** These were addressed to
AGENT-PPA-2381f2fe and became undeliverable when that session went unreachable —
`ListAgents` returned *no reachable agents at all* for several minutes. A file in
the repository is addressed to **the artefact and its consumers**, which persist;
a message is addressed to a name, which does not. This document is the finding
about that, applied to itself.

---

## 1. `v_ca05_id_queue` must not appear in a "none frozen" column

> **NOT MEASURABLE for stimulus variation.** `check_stimulus_variation.py` reads
> the input port list from `spec/*_iface.sv`. This task has none: its port map
> lives in `probe/PASTE.md`, which is correct for a submission — the hash covers
> it and a submitter sees it — and invisible to the tool. It has been reported
> SKIPPED every time the sweep has run, and will be. **NOT MEASURABLE is not the
> same answer as NONE FROZEN.**

The same distinction `check_yaml_duplicate_keys.py` already makes by printing
`NO CONCLUSION` rather than `ok` where it cannot walk a file. A reader scanning
eleven rows cannot tell *nothing wrong* from *nothing was read* unless the table
says which.

Two proper fixes, neither this agent's to choose: the tool learns to read a port
list out of `PASTE.md`, or the task ships a `spec/*_iface.sv`. The second moves a
hash; the first is `scripts/`. Until one happens, **all** of v_ca05's inputs are
unmeasured, not only its readies.

## 2. Leniency sweep of `scripts/` — read-only, requested by Jack

*What accepts alternatives, falls back, or defaults rather than failing?* Sorted
by whether the leniency can hide a defect, which most of it cannot.

**Worth changing — one:**

| | |
| --- | --- |
| `check_ppa_record.py:69` | `pdk = rec.get("pdk", "sky130hd")` |

A record that does not **say** which PDK becomes a record that **says**
sky130hd. It then looks in the wrong flow directory and reports
`SKIP (no surviving flow dir)` — an *unrecorded field* rendered as a *missing
directory*. Two different facts, one message. This is the same distinction that
session drew about `git_sha` `-dirty` appearing on 600 of 602 records: a field
that cannot discriminate is not weak evidence, it is none.

**Minor — two, both first-match-wins where a second match is possible and
unnamed:**

- `seed_sweep.sh:57` — `[ -f "$DUT" ] || DUT="..._top.sv"`. Bounded, and it
  hard-fails if neither exists, but never says which of the two it took.
- `reference_ppa.sh:28` — `REF="$(ls ref/*_ref.sv | head -1)"`. The same shape as
  the policy-directory glob that cost v_ca07 a real 21 of 22.

**Not defects:** ~40 `2>/dev/null` existence probes, ~30 `.get(k, 0)`
accumulators. Suppressing an error you are testing for is the idiom.

**And one doing the right thing**, named because it is the case that prompted the
sweep. `task_text_hash.py` accepts either `PASTE.md` or `BLIND_TB_TASK.md`. I
expected that tolerance to be the cause of a defect I had just found — three
`task.yaml` files declaring a prompt document that does not exist — and **it is
not**. It names the file it took and refuses loudly when neither is present, and
its own comment records that this rename caused a defect once and that the
refusal is why.

The actual cause is narrower: **no script reads `task_statement`.** A field with
no consumer has no observable correct value, so a wrong one produces no
disagreement anywhere — and every instrument in this repository works by finding
a disagreement. *Leniency did not hide it; absence of an owner did.*

So the general form is narrower than "tolerance is bad":

> Tolerance that **names what it accepted** is fine. Tolerance that
> **substitutes silently** has answered a different question than the one asked.
> A field with **no reader at all** is worse than either, because there is
> nothing to be tolerant with.

## 3. For the record

Three of this agent's `task.yaml` files were repointed to `probe/PASTE.md`, the
file that exists. Hashes unmoved: `fd2ae1ad9bf3719d`, `eacc3c043e2a5767`,
`839999302366fa24`. The hash was always right; only the pointer was wrong, which
is why nothing caught it.
