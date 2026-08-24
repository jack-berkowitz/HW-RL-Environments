# d_ca03 negative controls -- measured discrimination

Six controls, each wrapping `sv39_mmu_ref_inner` and perturbing one thing.
Measured over sequence C, 118 requests, `vectors/vectors_sv39.hex`.

| control | targets | verdict | failures | total_cycles | area (um^2) |
|---|---|---|---|---|---|
| *(reference)* | -- | PASS | 0 | **832** | **190,561** |
| `nc_a_stuck_output` | floor case | FAIL | 118 / 118 | 832 | -- |
| `nc_b_serial_response` | **the CYCLE axis** | PASS | **0** | **2,651 (3.19x)** | ~unchanged |
| `nc_c_bloat_storage` | **the AREA axis** | PASS | **0** | 832 (identical) | **329,980 (1.73x)** |
| `nc_d_no_resident_tlb` | T4 capacity | FAIL | 119 | 70,201 | -- |
| `nc_e_super_offset` | A2 superpage offset | FAIL | **2** | 832 | -- |
| `nc_f_ad_ignored` | A5 fault-on-unset A/D | FAIL | **4** | 832 | -- |

## One control per scored axis, each in the direction that axis must catch

`nc_b` and `nc_c` are not correctness controls -- both PASS correctness by
design. They exist to prove the two scored axes are live and INDEPENDENT:

* **`nc_b` moves cycles and nothing else.** It delays every retirement by 15
  cycles, which is what one comparator swept across 16 TLB entries costs on every
  lookup. Delivered values are unchanged; total cycles go 832 -> 2,651.
* **`nc_c` moves area and nothing else.** It adds 4,096 flip-flops -- exactly
  what over-provisioning looks like. Cycles are byte-identical at 832; flop count
  goes 3,467 -> 7,563 (+4,096, exactly as declared) and area 190,561 -> 329,980.

Without both, a broken measurement on either axis would pass silently.

## The area control failed first, which is why it is worth having

The first `nc_c` terminated its register chain in a local wire. Synthesis deleted
all 4,096 flops and the "bloated" build measured **190,469 um^2 against the
reference's 190,561 -- SMALLER**. An area-axis control that gets optimised away
validates nothing.

Rewritten to drive `lsu_dtlb_ppn_o`, which spec T2 does not score: the storage is
then load-bearing for a real output and survives synthesis, while the scored
surface is untouched. The flop delta is exact, which is how the fix is known to
have worked rather than merely changed the number.

## nc_b needed two corrections, both recorded

Its first cut reset its delay counter whenever the inner assertion was low. A
fault can be a single-cycle pulse, so the counter never reached its target and
the three fault cases were corrupted -- turning an axis probe into a correctness
perturbation as well. Latching the assertion fixed the retirement but left
`cause` reading 0, because the inner drops it long before the delayed retirement:
a design that retires late must present the value it retired WITH. Holding
`paddr` and `cause` fixed that, and `nc_b` now passes correctness with 0 failures.

## T4 was validated against the reference before it was allowed to gate

Rule 24: the assertion had to reproduce a known-good answer first.

* steps 27-42, the 16-page replay: **every request issued 0 page-table reads**,
  1 cycle each -- 16 entries simultaneously resident.
* steps 44-60, the 17-page replay: **every request issued 6 reads** -- 17 pages
  cannot be resident in 16 entries.

Only then was it wired as a gate. `nc_d_no_resident_tlb`, which holds `flush_tlb_i`
high so nothing is ever resident, fires it.

## The narrow ones

`nc_e` at 2 failures and `nc_f` at 4 are the useful correctness controls: each
fires only on the requests its clause governs -- the superpage request for A2, the
A=0 and D=0 requests for A5 -- so passing them is evidence about that clause
rather than about the harness.

## Identifier join, validated against the harness's own code

`ppa_candidate.sh` already computes the submission's sha256-16 and refuses to
build unless a `runs/<task>/*__sim.json` carries the same `submission_sha256_16`
with `all_passed`. Its gate snippet was run verbatim against two files with
different hashes and one sim record:

    sha c6eb4df3199b831c -> ACCEPTED, paired with x__sim.json
    sha 5e8d792b3ca14f0a -> REFUSED (no matching sim record)

So a cycle count from one build cannot be paired with an area figure from
another. The key and the gate exist; what does not yet exist is
`report_table.py` USING that key to show the two axes side by side. That is a
requirement on the reporting side, not a suggestion -- see the note in task.yaml.
