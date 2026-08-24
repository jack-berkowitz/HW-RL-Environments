# candidates/d_ca03

Drop model answers here as `<model>.sv`, one file each. Score with:

    scripts/sim_candidate.sh domains/comp_arch/design/d_ca03_sv39_mmu candidates/d_ca03

The task text to paste is
`domains/comp_arch/design/d_ca03_sv39_mmu/probe/PASTE.md`. It is the contract and
nothing else: no reference, no vectors, no testbench.

## Task text hash

    32dab6d0eca816dc

It supersedes five earlier texts: `b05dbe9522c9ff2e`, `360afdc7295d5fd8`,
`c2265a1e480ab767`, `7bc21e751be26fa2` and `83b793dff2273998`.

**Not all five boundaries are equal, and the distinction decides whether a
result can be carried across one.**

**BEHAVIOURAL, up to `7bc21e751be26fa2`.** The scored stimulus went from 118
requests to 207, and normative clauses changed with it. Nothing measured before
this point is comparable to anything measured here:

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

A submission conformant against any of those is not conformant here. Re-solicit
rather than re-scoring.

**NOT BEHAVIOURAL, `83b793dff2273998` and `32dab6d0eca816dc`.** Both are scoring
policy, and every clause in F, V, A, C, L, P and T is byte-identical across them.
A design conformant against `7bc21e751be26fa2` is still conformant here, and
re-running reproduces every number exactly.

* `83b793d` restated **G2**: timing closure is a GATE, not an axis, and slack is
  not scored. An area figure from a build that did not close is not a smaller
  design, it is an unfinished one, so its PPA is withheld rather than reported —
  and slack above zero earns nothing, because meeting timing with margin is
  bought with area and charging for both counts one tradeoff twice.
* `32dab6d` restated **G1**: a submission that fails to build scores zero on
  every PPA axis, so a design the simulator accepts and the synthesis frontend
  rejects gets full correctness and no PPA. It also records that the pinned
  period is NOT YET SET, pending the queued reference sweep.

The hash changed both times because the shipped text changed, which is what the
hash is for. **A submission cannot infer comparability from the hash alone** —
only from which clauses moved.

## A caution about quoting this hash

It moved three times in twelve minutes, twice by a second author correcting the
same file. **Recompute it at the point of use** rather than carrying one that was
quoted in a message: run `scripts/task_text_hash.py` on the task directory when
you write a record. A hash in a message is a snapshot and the message outlives
the snapshot.

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
