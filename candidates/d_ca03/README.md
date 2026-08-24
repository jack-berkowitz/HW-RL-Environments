# candidates/d_ca03

Drop model answers here as `<model>.sv`, one file each. Score with:

    scripts/sim_candidate.sh domains/comp_arch/design/d_ca03_sv39_mmu candidates/d_ca03

The task text to paste is
`domains/comp_arch/design/d_ca03_sv39_mmu/probe/PASTE.md`. It is the contract and
nothing else: no reference, no vectors, no testbench.

## Task text hash

    7bc21e751be26fa2

It supersedes `b05dbe9522c9ff2e`, `360afdc7295d5fd8` and `c2265a1e480ab767`.

**All three boundaries are BEHAVIOURAL and nothing measured against them is
comparable to anything measured here.** The scored stimulus went from 118
requests to 207 across them, and normative clauses changed with it:

* **A8 was WRONG and is rewritten from measurement.** It said the final
  translated address is PMP-checked. It is not checked at all -- only the
  walker's own reads are, and only for R. A design built against the earlier
  text, checking the final address by access type as the RISC-V standard
  describes, FAILS here and is correct to have been rejected.
* **A11 did not exist.** Whether `lsu_valid_o` accompanies a fault was unstated
  and scored. It does accompany one.
* **T2** no longer scores `paddr_o` on a faulting request.
* **T8, T9 and T10** are new or replaced: every input must VARY, the instruction
  TLB's capacity is checked, and ASID and global pages are checked.

A submission conformant against any earlier text is not conformant here. Re-solicit
rather than re-scoring.

## Configuration

ONE configuration. P1 and P2 pin it and the task does not parameterise geometry:

| | |
|---|---|
| Sv39, XLEN=64, VLEN=64, PLEN=56 | 16-bit ASID, 8 PMP entries |
| instruction TLB | 16 entries, fully associative |
| data TLB | 16 entries, fully associative |
| second-level TLB | none |

## What is scored, and on how many axes

**Two axes, reported separately, never combined into one figure.**

1. **CORRECTNESS**, bit-exact on the T1 surface over 207 requests. This is a
   GATE: a submission that fails it produces no PPA number at all.
2. **TOTAL CYCLES** over the scored sequence (`metrics.total_cycles` in the sim
   record). Reference 1,269; the second source 977.

Area and power are the third comparison and are **not final yet** -- see below.

## PPA is PENDING, and the areas on record will move

`ppa: ABSENT`. Nothing here has been placed and routed.

The figures quoted elsewhere -- 190,561 um^2 for the reference and 329,980 for
`nc_c_bloat_storage` -- were measured after synthesis at the **25 ns starting
constraint** in `orfs/constraint.sdc`, which is a derived logic-path figure and
not a reference sweep. The pinned period is due to change to 1.5x the
reference's measured period rounded up to 0.25 ns, and this design closes at
>=21.33 ns, so the pin lands near 32 ns. **At a looser period both areas move.**

Correctness scoring does not depend on any of that, so candidates can be
solicited and scored on the two axes above now. Do not quote an area from this
task until the PPA boundary lands with its own record.

## Reference and second source

| | verdict | cycles | PTE reads |
|---|---|---|---|
| reference (`ref/`, CVA6 `cva6_mmu` behind a shim) | PASS 207/207 | 1,269 | 502 |
| second source (`tb/sv39_mmu_alt_ref.sv`) | PASS 207/207 | 977 | 292 |

The second source was written against `spec/` alone and found four contract
defects. Two conforming designs 1.30x apart on cycles is the evidence that the
cycle axis discriminates between real implementations rather than only between
the reference and a control.

## Seven negative controls, all holding

`nc_a` floor case, `nc_d` no resident TLB, `nc_e` superpage offset and `nc_f`
A/D ignored all FAIL correctness. `nc_b` and `nc_c` PASS correctness and move
one axis each -- cycles 2.58x and area 1.73x respectively -- so a broken axis
cannot pass silently. `nc_g_itlb_one_entry` fails T9 ALONE at one entry with
zero per-step failures, which is what makes the instruction TLB's pinned
capacity enforceable rather than merely asserted.
