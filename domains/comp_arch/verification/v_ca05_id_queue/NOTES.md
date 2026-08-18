# v_ca05 `tag_tracker` — evidence trail

**Reference ceiling 10 of 10** against the expanded mutant set; golden PASS,
4/4 conformant, `dut2` PASS. Second DUT in `dut2/tag_tracker_alt.sv`.

## The harder mutant set found a real hole in the reference

Four mutants added after the first blind run on the sibling tasks. The six
originals were kept: the goal is range, not replacement.

| id | violates | why a competent testbench misses it |
|---|---|---|
| `tt_m7_per_tag_cap` | R1 | total capacity is right; a *single* tag caps at SLOTS/2, and R1's "including SLOTS entries all carrying the same tag" is the clause it breaks |
| `tt_m8_peek_removes_last` | R9 | a peek is destructive only when the tag holds exactly one entry |
| `tt_m9_zero_mask_no_hit` | R13 | the degenerate mask, which R13 names explicitly and a testbench skips as uninteresting |
| `tt_m10_full_asserts_late` | R14 | `full_o` is a cycle late rising and correct everywhere else |

**`tt_m8` survived the reference testbench on first run.** The existing R9 peek
check ran on a tag holding all SLOTS entries, so a design that destroys only the
*last* entry of a tag passed it untouched. A boundary phase was added — push one
entry, peek it twice, confirm it is still there, then remove it — and the
reference now reaches 10/10. That is the mutant set doing its job on the
reference, which is the second time this task's mutants have found a hole in it.

## The rule this set is now built on

**Discriminating mutants come from clauses stated as checkable bounds.** A
qualitative promise yields a mutant everybody catches or nobody can; a stated
bound yields one a competent testbench can plausibly miss. The evidence is
`fm_m9` on the sibling task: an independent author caught 9 of 10 and missed
exactly the mutant targeting a *bounded* fairness clause, because the testbench
had implemented "eventually" instead of the window. The clause and the mutant
justified each other.

Applied here: `tt_m7` and `tt_m10` attack bounds (a capacity distribution, a
flag's exact transition point); `tt_m8` and `tt_m9` attack cases a clause names
explicitly. **It is also a design instruction for future specs — prefer a stated
bound over a qualitative promise wherever the property admits one.**

## Second DUT — built, and now actually run

`dut2/tag_tracker_alt.sv`. Passes the reference testbench: 1305 checks, 0
failures, zero rule-5 adjudications. Three differences, and difference 2 is the
load-bearing one: `push_gnt_o` is request-gated here, where the reference
implementation's grant is a space-available flag high with no request pending.
Witness measured rather than declared — over 82 cycles with a long idle stretch
the reference implementation grants unasked on **79** cycles, the alt on **0**.

`sim_verification.sh` now runs a `dut2` row and it passes, so this is no longer
an unwired declaration.

## A defect this work exposed

**The reference testbench declared `tag_tracker_spec_tb` while `task.yaml`
required `tag_tracker_tb`, so it had never been runnable through the scored
path.** Every previously reported figure for it — including the 6/6 ceiling —
was produced by an ad-hoc invocation. Same shape as F22. The module is renamed
and the 10/10 above was measured through `sim_verification.sh`.
