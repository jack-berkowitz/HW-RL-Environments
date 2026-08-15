# Recognition probe — does decontamination actually work?

The whole verification half rests on an assumption carried since Phase 0: that a
shipped DUT, renamed and stripped of commentary, is not recognisable as the
upstream module it derives from. **That assumption has never been measured.**

Licence retention now bounds how far decontamination can go — every vendored
project requires its notices retained, so a shipped DUT must carry a third-party
notice naming the corpus. The notice is deliberately corpus-level (all 18
projects, one block) rather than per-file, so it says "this derives from one of
these" rather than "this is PULP".

This probe converts the assumption into a number **before** fifteen more
verification tasks are built on top of it.

## Method

Give a model **only** `dut/tag_tracker.sv` and ask, verbatim:

> Below is a SystemVerilog module. Answer three questions as specifically as you
> can, and say "unknown" rather than guessing if you are not reasonably
> confident.
>
> 1. What does this module do? Describe its function in two or three sentences.
> 2. Is this derived from a specific open-source hardware project? If so, which
>    project and which file?
> 3. What is this module conventionally called — its original module name?
>
> \<contents of dut/tag_tracker.sv\>

Run it against several frontier models, one fresh conversation each, no
follow-ups, temperature at the provider default.

## Scoring

| question | correct answer | what it tells us |
|---|---|---|
| 1. function | an ID-indexed queue / per-ID linked-list tracker with exists-lookup | **not contamination** — a capable model should get this from the code, and needs to for the task to be doable at all |
| 2. project | `pulp-platform/common_cells`, `src/id_queue.sv` | **contamination** — the corpus notice lists 18 projects; naming the right one is recall, not reading |
| 3. original name | `id_queue` | **strongest contamination signal** — the name is nowhere in the shipped file |

Score **Q2 and Q3 only**. Q1 correct is expected and desirable.

    recognition rate = (models naming id_queue OR common_cells) / models asked

## Reading the result

- **Low (0 of N)** — decontamination is working within the licence bound, and
  the verification half proceeds as planned.
- **High (most of N)** — the verification half is partly a recall benchmark. We
  learn this having built ONE task, not sixteen, and can decide what to do while
  it is still cheap. Options at that point: prefer anchors from less-reproduced
  projects, restructure DUTs more aggressively than renaming, or state the
  limitation and measure per-task recognition as a covariate.

Either way the number goes in `FINDINGS.md`: *we measured contamination instead
of assuming it away* is a materially stronger claim than *we renamed the
signals*.

## Status

**NOT YET RUN.** Egress has been closed since Phase 0 and this needs model API
access. It requires an explicit decision to re-open egress for this purpose, or
for the probe to be run outside this environment and the results pasted back.

## What the shipped file already guarantees

- Corpus-level notice, 18 projects, licences listed — retention satisfied
- Module renamed `id_queue` → `tag_tracker`; every port and internal signal
  renamed; the upstream `inp_`/`oup_` idiom eliminated
- Every comment stripped — the original explains the algorithm and names the
  head-tail table structure
- **Functionally identical to the anchor: 160 000 comparisons, 0 differences**,
  by a cycle-by-cycle equivalence harness against the untouched original
