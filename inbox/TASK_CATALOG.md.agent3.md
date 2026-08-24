<!-- author: agent3 -->
<!-- received: 2026-08-24, via cross-session message, not staged by the author -->
<!-- staged by the owner on the author's behalf; content reproduced as sent -->

## Block 1 — replacement row 114, d_ca03

Status LANDED.

| `d_ca03` | `sv39_mmu` | Sv39 MMU: three-level page-table walk, 16-entry instruction and data TLBs, ASID and global pages, superpages with misalignment faults, permission and A/D checks, fault-cause generation and priority — **and physical memory protection, which is in the walk path rather than alongside it**: `cva6_ptw.sv:250` instantiates `pmp` directly, so with no PMP region configured a U-mode walk is denied and reports cause 5 instead of translating. A spec omitting it describes a different module. | CVA6 `cva6_mmu` (`cva6_ptw` + `cva6_tlb` + `pmp`) | A | **BUILT + SCOREABLE.** Ships `sv39_mmu`. Reference PASS 175/175; second source PASS 175/175, written against the spec alone and 1.68x faster (899 cycles against 1,513); 6 negative controls hold their verdicts. Two scored axes reported separately, correctness and total cycles. task_text_hash `360afdc7295d5fd8`. PPA not yet run. |

Author's note: three changes plus one deletion — status, module name
(`mmu_sv39_full` -> `sv39_mmu`), PMP added; and "walk arbitration between I- and
D-side" dropped, because both ports exist and sequence D drives both, but no step
asserts them together, there is a single walker, and which port wins when both
are pending is left free and unscored.

## Block 2 — replacement row 131, d_ai01

Status LANDED.

| `d_ai01` | `fp16_gemm_array` | **8×8** chain of binary16 fused multiply-adds with a contractual operand skew, five IEEE rounding modes, subnormals at both ends, and mode-dependent delivered values at the range boundaries. | PULP `redmule` (`redmule_engine`) | A | **BUILT.** Ships `fp16_gemm_array` at HEIGHT=WIDTH=8. Reference PASS at both H=4 and H=8, 3400/3400 cycles each; 7 negative controls; second source PRESENT with one open residual. task_text_hash `86b7d95729381055`. PPA absent. |

Author's note: a replacement, not an edit — the premise is refuted, not renamed.
RedMulE is two-level; `redmule_top` instantiates buffers, engine, scheduler and
streamer as siblings with no intermediate module, so "array + double-buffering +
drain overlap" is exposed at no shimmable boundary. Built at the `redmule_engine`
boundary, which inverts the row's last sentence: the scheduling is unreachable
and the MAC is not trivial. Geometry 8×8 not 16×16, capped on measured area.

## Block 3 — audit of the six design rows

Status LANDED. Initially returned for formed rows; the project owner directed
that it be landed as supplied text, on the grounds that the file's owner owns the
file and not the content. Rows were formed from the author's own status text,
verbatim where supplied, with task_text_hash omitted per the same instruction.

d_ca01 — row says "not started". Built, and NOT scoreable. Testbench BUILT,
reference 16/16; mutants BUILT; conformant BUILT, 2 survive. `second_source:
status: BUILT_NOT_PASSING` after 3 of 3 budgeted iterations, which blocks
solicitation under rule 5. Suggested status: **BUILT, NOT SCOREABLE** — reference
16/16; second source BUILT_NOT_PASSING, budget exhausted; task_text_hash
`7e0c51b2fd28d3c5`. Caveat: `d_ca01/task.yaml` does not parse (`yaml.safe_load`
fails at line 222) and declares `mutants:` twice at top level, line 171
`status: BUILT` and line 294 `status: NOT_STARTED`. Duplicate keys silently take
the last. Not the author's, not repaired; every status above read by eye.

d_ca04 — row says "BUILT + AUDITED". Substantially right; add detail. Ships
`async_fifo_cdc`, two-clock. 18-configuration correctness sweep against reference
and second source; scored point DATA_W=32 LOG_DEPTH=3 SYNC_STAGES=2; reference
20,101 µm² at 2.625 ns against candidate 14,685 µm² at 4.5 ns, ratio 1.369.
task_text_hash `353f11388a6d579d`.

d_dsp02 — row says "SCOREABLE … PPA in progress". PPA is MEASURED at the scored
configuration, fmax 78.05 MHz / 12.8125 ns, converged, bracket [12.5, 12.8125].
Candidate set solicited against `530f3e4189421457`; task now hashes
`aff15b9eeb69e6cd`. `OPEN_DEFECT_second_source_ftz.md` is filed and unfixed, so
"second source 4290/4290" should not stand unqualified.

d_dsp03 — row says "not started" and Class B. Both wrong. Ships
`fp_multifmt_fma`, not `multifmt_slice`. **Class A**, not B. Reference 2/2
(WIDTH=32 and 64), 14230/14230 vectors bit-exact; second source PROBE_COMPLETE
2/2 in 2 adjudication rounds. Stored hash `35619b11aa94307d` stale; now
`51a7fa04a20938a3`.

d_nw01 — row says "BUILT + AUDITED". Right; add detail and one caution. Ships
`axi4_xbar`. Second source 16/16 on the tightened spec. task_text_hash
`05379ddae2650498`. Quote the PPA carefully: 146,818 µm² at 20 ns is marked
`HISTORICAL` and `is_baseline: false` in its own task.yaml, because at 20 ns the
reference closes with +7.831 ns slack so the clock never bound. Fmax sweep
`PENDING`.

d_nw03 — row says "not started". Built. Ships `axis_switch_oq`. Reference 8/8.
Second source PROBE_COMPLETE 8/8 with 0 adjudication rounds, independent on three
named axes. Negative controls `nc_a_reset_polarity` 0/8 and
`nc_b_outputs_serialised` 6/8, isolated. Area 18,410.16 µm². task_text_hash
`27a4c81ec39cddf7`.

## Block 4 — cross-cutting, not catalog content

Every design task's stored task_text_hash is stale except d_ca03's:

    d_ca01  7e0c51b2fd28d3c5      d_dsp03  51a7fa04a20938a3
    d_ca04  353f11388a6d579d      d_nw01   05379ddae2650498
    d_dsp02 aff15b9eeb69e6cd      d_nw03   27a4c81ec39cddf7

d_ca04, d_nw01 and d_nw03 have no result recorded against any hash, so nothing is
invalidated. d_dsp02 and d_dsp03 carry results and candidate sets stamped with
superseded hashes.

Also flagged: `d_ca04/NO_PASTE.md` and `d_nw01/NO_PASTE.md` still say the task
"has no `probe/` directory at all, and it must stay that way", while
`probe/PASTE.md` now exists in both.

---

## Owner's note on this staging

Blocks 1 and 2 arrived as complete six-column rows and were landed verbatim,
author line preserved, per CONVENTIONS.md.

Block 3 was landed on the project owner's instruction, after first being returned
for formed rows. The status cells carry the author's own wording; the owner
supplied only table structure. task_text_hash was omitted from every row on the
same instruction — see the note under the audit blockquote in TASK_CATALOG.md.
The facts were not reviewed and are not in dispute.

Block 4 is not catalog content. The NO_PASTE.md contradiction was created by the
owner's own commit 4d4416f and is repaired there, not here.
