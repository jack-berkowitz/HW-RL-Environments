# d_ca03 -- step 0 anchor audit: measured facts

Every number this task's spec asserts comes from a probe recorded here. Nothing
is inferred from the RISC-V specification alone, and nothing from reading the
anchor's source. Rule 24: the apparatus is recorded beside the numbers it
licenses.

Anchor: `refs/cva6/core/cva6_mmu/cva6_mmu.sv` (OpenHW CVA6, Solderpad 0.51),
reached through `ref/sv39_mmu_ref.sv`.

## 0. Why this boundary was chosen

`cva6_mmu` instantiates two `cva6_tlb`, one `cva6_shared_tlb`, one `cva6_ptw`
and one `pmp` -- **the composition is itself a module**. That is the property
d_ai01 lacked: RedMulE's array-plus-buffers composition existed only as siblings
under `redmule_top`, so no shimmable boundary exposed it and the task premise was
refuted. Here one port list covers 2,869 lines of walker, TLB and PMP.

**The page table is external.** `req_port_o`/`req_port_i` are ports, so the
walker's memory accesses are driven by the testbench. The contract can therefore
be stated as "given these page-table entries, deliver this address or this
fault", which is directly testable without a memory model inside the reference.

## 1. Elaboration

| frontend | result |
|---|---|
| Verilator 5.046 `--lint-only`, top `sv39_mmu` | 0 errors |
| yosys 0.67 `read_slang`, openroad/orfs:latest | clean, **0.61 s**, 108 MB peak |

Closure is 14 source files: the four `cva6_mmu/` files, `pmp` and `pmp_entry`,
`lzc`, `lfsr`, `cf_math_pkg`, and five packages. Extracted from Verilator's own
dependency output, not assembled by hand.

Two dependencies were not obvious and are recorded so the next reader does not
rediscover them: `pmp.sv` lives under `core/pmp/src/`, and `cbo_t` is not a
package type at all -- it is `logic [7:0]`, declared at `cva6.sv:174`.

## 2. The configuration is the one intended -- checked, not assumed

`cv64a6_imafdc_sv39_config_pkg` is a PREBUILT configuration. `imafdc` carries no
`h`, and the package sets `CVA6ConfigHExtEn = 0; // always disabled`. Confirmed
by running rather than by reading the filename:

```
XLEN=64 VLEN=64 PLEN=56 RVH=0 SV=39 PtLevels=3
InstrTlb=16 DataTlb=16 UseSharedTlb=0 SharedTlbDepth=64 Svnapot=1
NrPMPEntries=8 ASID_WIDTH=16 TvalEn=1  DCACHE_INDEX_W=12 DCACHE_TAG_W=44
```

`SV=39` with `PtLevels=3` is a genuine three-level walk. The shim asserts all of
these at elaboration and `$fatal`s on any of them, because a silently misbound
configuration is the failure mode this task inherits from d_dsp01 (F53).

**Port structs are the standing hazard.** `cva6_mmu` takes its port types as
`parameter type`, and the concrete types are in no package: `cva6.sv` declares
them as anonymous `localparam type` structs inside its own parameter list. The
shim reproduces them field for field and then checks each with `$bits()` against
the width its field list must produce. Copying carefully is not the control; the
assertion is.

## 3. `probe_walk_tb.sv` -- translation and faults

Page table planted in the testbench, `satp_ppn=1` so the root table sits at
0x1000. All five cases pass.

| case | result | cycles |
|---|---|---|
| three-level walk to a U leaf | pa 0x5000 | 14 |
| same page again | pa 0x5000 | 1 |
| 1 GiB superpage, PPN 0x40000 | pa 0x4000_0001 | 6 |
| invalid PTE, V=0 | cause 13 | -- |
| leaf without U, accessed in U mode | cause 13 | -- |

The cycle counts are themselves evidence the mechanisms are distinguishable by
observation: 14 for three memory accesses, 6 for the single access a level-2 leaf
needs, 1 for a TLB hit. The superpage case also shows the offset within the
superpage preserved -- 0x4000_0001, not 0x4000_0000.

**PMP IS IN THE WALK PATH, and finding that out cost the first run.** With all
eight `pmpcfg_i` entries zero, no region matches and U-mode access is denied, so
the probe returned pa=0 with cause 5 -- a load ACCESS fault -- and looked exactly
like a broken walker. After entry 0 was set NAPOT-over-everything with RWX the
same walk delivered 0x5000 and the invalid-PTE case moved from cause 5 to cause
13. **That 5 -> 13 transition is the evidence that both mechanisms are live and
separable**, and it is why spec A7 states the priority and A8 states that PMP
covers the walker's own reads.

## 4. `probe_ad_tb.sv` -- the A/D policy, which RISC-V leaves open

RISC-V permits either hardware A/D update during the walk, or a fault leaving
software to set the bits. Which one an implementation does is a contract term, so
it was measured.

| case | delivered | page-table entry afterwards |
|---|---|---|
| load through a leaf with A=0 | **cause 13** | `0x241f`, A bit still 0 |
| store through a leaf with A=1, D=0 | **cause 15** | `0x305f`, D bit still 0 |

So this anchor **faults and never writes a page-table entry**. Pinned in spec A5,
with the note that the standard permits the other choice.

## 5. `probe_ctrl_tb.sv` and `probe_window_tb.sv` -- control transitions

Rule 26 requires every control input of a pipelined design to have its
transition behaviour stated, scored or explicitly unscored with a window. The
walker is multi-cycle, so it applies.

**The first measurement was wrong, and in the direction that would have widened
the contract.** Reading `lsu_valid_o` as a level after pulsing `flush_i`
mid-walk showed `valid=1, exc=0`, which looked like an ambiguous result and led
to a plan to declare results unscored across transitions. A second instrument
that deasserts `lsu_req_i` between attempts -- so `lsu_valid_o` cannot be read
stale from the previous request -- gives a different and unambiguous answer:

| event | result | cycles |
|---|---|---|
| baseline, cold | correct | 14 |
| baseline, warm | correct | 1 |
| after `flush_tlb_i` while idle | **correct** | 139 |
| after `flush_i` during a walk | **correct** | 1 |
| after `flush_tlb_i` during a walk | **correct** | 139 |
| translation disabled (bare mode) | pa = va | 1 |

**Every transition delivers the right answer. Only the latency moves.** So the
spec excludes LATENCY (L1) and scores results across transitions (C4) -- a
narrower exclusion than the blanket one first planned, and the narrowing is what
the measurement supports. `flush_i` aborts an in-flight walk without emptying the
TLBs, which is why the following access hits in one cycle; that is stated in C3.

`satp_ppn_i` or `asid_i` changing with a walk in flight and no intervening flush
is declared OUT OF SCOPE in C5 -- not because it was hard to measure, but because
RISC-V requires an SFENCE.VMA after writing `satp`, which makes the case
architecturally undefined rather than merely unspecified here.

## 6. Area, for the scored configuration

sky130hd, yosys `read_slang` + `synth -flatten` + `dfflibmap` + `abc`,
tt_025C_1v80:

* `sv39_mmu` at the Sv39 configuration: **190,656.60 um^2**, about 0.19 mm^2.

For scale against this repository's own history: `d_nw01_axi4_xbar` is the
largest built here at 2.09 mm^2 and `d_ai01` is 1.63 mm^2, so this is roughly an
eighth of d_ai01 and well inside the proven envelope. Unlike d_ai01, no geometry
cap is needed -- there is one configuration and it is comfortable.

## 7. Spread estimate under pinned storage -- and why the number flatters the task

Run before pinning TLB capacity, to decide whether pinning leaves a real
optimisation problem or a trivial one.

### The split

sky130hd, after `dfflibmap` + `abc`:

| | |
|---|---|
| flip-flops | **3,467**, all `sky130_fd_sc_hd__dfrtp_1` at 25.02 um^2 |
| storage area | **86,744 um^2** |
| total area | 190,657 um^2 |
| storage fraction | **45.5%** |
| logic fraction | 54.5% |
| spread ceiling if logic went to zero | **2.20x** |

The storage number is close to irreducible for the pinned entry count. From the
RTL field list, a 16+16 design needs about 47 tag bits (asid 16, vpn 27, is_page
2, valid, napot) plus about 52 content bits (PPN 44 plus the eight permission
bits) per entry -- roughly 99 bits x 32 entries = 3,168 flops. The measured 3,467
is within 9% of that floor, because the declared-but-unused `gpte` field and the
whole shared TLB are constant-folded away at `RVH=0` and `UseSharedTlb=0`.

So pinning capacity fixes about 45% of the area and leaves about 55% in play.
A realistic minimum-area implementation lands near 100,000 um^2, giving roughly
**1.9x** spread against the anchor's 190,657.

### The number clears the bar. The MECHANISM does not.

**Most of the route to the low end is the same exploit that pinning was meant to
close, one level down.** With latency unscored (L1), a submission may serialise
anything:

* the TLB lookup itself -- one comparator swept across 16 entries instead of 16
  parallel comparators, collapsing the widest logic block in the design;
* the PMP check -- one comparator across eight regions instead of eight;
* the walker datapath -- already naturally shared, so no spread either way;
* flush -- per-entry clear beats a generation counter on area, and the counter's
  only benefit is latency.

Each of those is dominant-strategy under unscored latency, exactly as zero TLB
entries was dominant under unscored capacity. The ~1.9x is therefore substantially
a measure of **who noticed that serialising is free**, not of design quality.

Two levers survive that are genuinely about implementation quality:

* **multi-page-size tag comparison** at a fixed entry count -- mask logic versus
  per-size arrays versus a unified array with size bits;
* **combinational versus registered lookup**, which is real precisely because PPA
  is measured at a PINNED period: register only as much as meeting the period
  needs.

### What this means

Pinning capacity is still strictly better than leaving it free, and is applied.
But it does not by itself make the area metric measure design skill, because the
root cause is not capacity -- it is that the benefit side is unscored at all.
Recorded here rather than buried: the honest reading of 1.9x is "wide enough to be
worth pinning, not wide enough to claim the task measures microarchitectural
judgement".

## 8. Hit/walk mix of the scoring sequence -- the precondition for the cycle axis

Measured BEFORE adding the cycle axis, because a cycle axis over a miss-heavy
sequence is close to no axis at all: if nearly every request is a cold walk, a
serialised TLB lookup costs almost nothing and the axis cannot discriminate.

A request that issues no page-table read was served from a TLB; one that issues
reads was walked. `mem_gnt` pulses are counted, so each PTE read is one access.
`tb/audit/probe_mix_tb.sv`.

| sequence | requests | hits | walks | PTE reads | cycles |
|---|---|---|---|---|---|
| A -- functional probes only | 5 | **1 (20%)** | 4 | 12 | 32 |
| B -- A + the T4 capacity replays | 55 | 18 (32%) | 37 | 210 | 511 |
| C -- B + four reuse passes | 119 | **66 (55%)** | 53 | 306 | 783 |

**A would not have worked.** At 20% hits the sequence is almost all cold walks,
and the serialisation exploits the cycle axis exists to charge for would barely
register.

**B is better than it looks and still not enough.** The replays do not all hit:
the 16-page fill evicts entries the functional probes installed, and the 17-page
replay thrashes a 16-entry TLB by construction -- that is what T4 is testing, so
it is correct behaviour rather than a flaw in the sequence.

**C is the sequence to score.** At 55% hits, against the 783-cycle baseline:

| serialisation choice | cost on sequence C |
|---|---|
| one comparator swept across 16 TLB entries | 66 hits x ~15 extra cycles = ~+990, **2.26x** |
| one PMP comparator instead of eight | (306 reads + 119 finals) x 7 = ~+3,000 |
| per-entry flush clear vs a generation counter | 139 cycles per flush against ~1 |

All three were dominant strategies while cycles were unscored. None is now. The
ratio is tunable -- more reuse passes raise it further -- and 55% is where four
passes land.

## 9. Sequence C's 55% hit rate is a SCORING CONSTRUCT, not a workload claim

Stated explicitly because someone will read the number later as a workload
characteristic, and it is not one.

The mix was chosen to PRICE SERIALISATION. With cycles scored (spec L1), the
question a sequence has to answer is "does a design that serialises its TLB
lookup pay for it here?", and the answer depends entirely on how often a lookup
hits. At the functional probes' 20% hit rate a swept comparator costs almost
nothing; four reuse passes lift it to about 55% (51% in the final committed
sequence, which adds the A/D fault cases and bare mode), and the swept comparator
then costs measurably.

**Nothing about 51% is a claim that real software translates addresses this way.**
No working set is modelled, no address trace is replayed, the page table is a
handful of hand-planted entries, and the reuse passes exist purely to give the
cycle axis something to charge for. A representative-workload argument needs a
real trace and a real memory model, and that is a different and heavier task --
the one where workload realism gets argued rather than asserted.

If the number is ever quoted, it should be quoted as "the scored sequence is 51%
TLB hits by construction", never as "the MMU sees 51% hit rates".

## 10. Both scored axes validated, independently

One control per axis, each in the direction that axis exists to catch, and each
moving ONLY its own axis:

| | correctness | total_cycles | flops | area (um^2) |
|---|---|---|---|---|
| reference | PASS | **832** | 3,467 | **190,561** |
| `nc_b_serial_response` | PASS | **2,651 (3.19x)** | ~same | ~same |
| `nc_c_bloat_storage` | PASS | 832 (identical) | **7,563 (+4,096)** | **329,980 (1.73x)** |

The +4,096 flop delta is exact, which is the evidence the bloat survived
synthesis rather than the area number merely having moved.

**The area control failed on its first attempt and that is the reason to have
it.** Terminating the register chain in a local wire let synthesis delete all
4,096 flops, and the "bloated" build measured 190,469 um^2 -- SMALLER than the
reference's 190,561. Had the control been declared working on the strength of
"it's a big array, area must rise", a broken area measurement would have passed
silently. It now drives `lsu_dtlb_ppn_o`, unscored per T2.

## 11. Timing, for the SDC starting constraint

sky130hd, yosys `read_slang` + `synth -flatten` + `dfflibmap` + `abc`, then
OpenSTA at two periods with a 20% I/O budget each side:

| period | data arrival | data required |
|---|---|---|
| 10 ns | 18.852 | 9.787 |
| 20 ns | 20.852 | 19.787 |

The arrivals differ by exactly 2.000 ns -- the change in input delay -- so they
are ONE path through two budgets, and both reconcile to a logic delay of
**16.852 ns**. Required is period - 0.213, so the path closes at
`period >= 21.33 ns`. The SDC pins **25 ns**, leaving +2.94 ns for
place-and-route.

Same two tool notes as d_ai01, confirmed again here rather than assumed:
`remove_from_collection` is not implemented by this OpenSTA (use
`all_inputs -no_clocks`), and OpenSTA cannot read yosys's default `write_verilog`
output -- `-noattr -noexpr -nodec` after `opt_clean; splitnets -ports; opt_clean`
produces a netlist it accepts.

---

## 12. The second source, and the four contract defects it found

Written against `spec/sv39_mmu_iface.sv` alone. `ref/sv39_mmu_ref.sv` was not
opened while it was written and neither was anything under `refs/cva6/`;
adjudication happened afterwards. The constraint is recorded in `task.yaml`
under `second_source.authoring_constraint` so it survives a handoff, together
with the contamination that was present anyway and is not claimed away: I wrote
the shim, so the port semantics, the memory handshake, the TLB field list and
the PMP config layout were already known. The walker FSM and the lookup were
not.

Nine spec gaps were written into the file's header **before** it was ever run,
so the record cannot be back-filled from what the reference turned out to do.
Four of them were then reached by the scored sequence.

### Defect 1 -- the retirement handshake was never stated, and it was scored

First run: **114 of 118 passed, 4 failed, all the same shape.** Every faulting
request expected `valid=1 exc=1`; the second source delivered `valid=0 exc=1`.

The specification did not say which. L2 said a request retires "either with a
translation or with a fault", which reads as an exclusive or, and T1 scores
`lsu_valid_o` and `lsu_exc_valid_o` separately. So the contract admitted two
readings on a scored surface, the text pointed at the wrong one, and every
faulting request in the sequence discriminated between them. Rule 5 branch
three. **A11** now states it: `valid_o` means the request retired, and a
faulting request asserts it too.

### Defect 2 -- `paddr_o` on a fault reports an internal choice, and was scored

Asserting `valid_o` on faults fixed two of the four. The other two still
differed, and only in the address:

| step | condition | reference | second source |
|---|---|---|---|
| 4 | leaf without U, U-mode | `0x80000000` | `0x80000000` after fix |
| 5 | leaf with A=0 | `0` | `0x9000` |
| 6 | store through A=1 D=0 | `0` | `0xc000` |

The pattern is exact and it is not arbitrary. A fault raised **inside the
walker** has no translated address to present and delivers zero; a fault raised
**on the TLB hit path** has computed one and delivers it. The reference rejects
A=0 and D=0 leaves in the walker and applies A4's permission checks on the hit
path. The second source installs any well-formed leaf and applies both there.
**A5 permits both** -- it requires a fault and forbids a page-table write, and
says nothing about where the check sits. So T1 was scoring where an
implementation puts a check, which is the one thing T2 exists to prevent.
**T2** now unscores `paddr_o` on a faulting request; everything else about that
request -- that it retires, that it excepts, and the cause -- is still scored.

### Defect 3 -- the instruction port was declared scored and never driven

`fetch_req` was initialised to zero in the harness and never assigned. So across
all 118 requests of sequence C:

* `fetch_valid_o`, `fetch_paddr_o`, `fetch_exc_valid_o`, `fetch_exc_cause_o`
  were never observed, though T1 declares them scored;
* A6's causes **12** and **1** were never reached, though A6 pins them longhand;
* T4's capacity check says "for each TLB independently" and **only ever reached
  the data TLB**.

A submission could have tied `fetch_valid_o` low and provided a one-entry
instruction TLB and passed everything. That reopens, on half of P2's pinned
storage, exactly the incentive T4 was written to close. **T8** now requires both
ports to be driven, and sequence D adds 57 instruction requests: seven
functional (walk, hit, superpage, two faults reaching cause 12, bare mode in and
out) and a fifty-request capacity phase. Nothing had to be built to reach any of
it -- the page table already planted `X=1 U=1` leaves -- which is part of why it
went unnoticed.

### Defect 4 -- the rig read a level as an event, for the third time

With the instruction port driven, every fetch retired with **cause 1**, an
access fault, including the ones that translate correctly. `tb/audit/probe_fetch_tb.sv`
printed the port cycle by cycle:

```
c= 0 ivalid=0 iexc=1 icause=1 ipaddr=0        mreq=1 maddr=0x1010
c= 4 ivalid=0 iexc=1 icause=1 ipaddr=0        mreq=1 maddr=0x2000
c= 8 ivalid=0 iexc=1 icause=1 ipaddr=0        mreq=1 maddr=0x3000
c=12 ivalid=1 iexc=0 icause=0 ipaddr=0x100000 mreq=0
```

The reference holds `fetch_exc_valid_o` asserted for the **whole** of an
in-flight walk -- its instruction-side PMP check runs against a `fetch_paddr`
that is not valid yet, so it reports "not permitted" for twelve cycles and then
retires correctly on the thirteenth. `do_step` latched whichever output rose
first, so it recorded every fetch as an access fault at cycle 0.

This is the third level-versus-event defect in this task and the second in this
rig. The previous one missed a pulse by sampling a level; this one caught a
level that was not completion. Retirement is now taken from `valid_o` on both
ports, which is what A11 defines it to be. See rule 27.

## 13. Chasing defect 4 refuted T4's central claim

With retirement fixed, fetches translate -- and the instruction-side T4 replay
issued **96 page-table reads where the data side issues 0**. Every replay
walked. `tb/audit/probe_capacity_tb.sv` fills n distinct pages, replays all n,
and counts how many took no read:

```
   n    1   2   4   8  16  17
 data   1   2   4   8  16   0
 instr  1   0   0   0   0   0
```

**The data TLB retains 16. The instruction TLB retains one.** They are the same
16-entry structure. The difference is entirely the replacement policy, and the
mechanism is in the anchor: `cva6_tlb.sv:436` advances the PLRU tree only on
`lu_hit[i] & lu_access_i` -- on a lookup **hit**, never on an install. A cold
fill with no intervening hit therefore writes all N entries into one slot. The
data TLB escapes it because the scored sequence's first eleven requests produce
hits that spread the tree before the fill begins.

A9 leaves the replacement policy free and unscored, deliberately. So that policy
is conforming, and **T4's claim to be "BEHAVIOURAL AND POLICY-INDEPENDENT" was
false**. Not checking *which* entry is displaced does not make a test
policy-free: passing the 16-page replay requires a policy that spreads a cold
fill, and A9 permits policies that do not. The check also depends on the
sequence's preamble, so reordering the sequence can fail a conforming design.

The consequence is worse than the wording. **No residency test can establish the
instruction TLB's capacity against this anchor**, because a submission with a
one-entry instruction TLB is behaviourally indistinguishable from the reference
across the whole sequence while saving roughly 1,500 flip-flops.

What was done, and what was not:

* **T4** keeps the data-side check -- it does catch declare-and-never-fill, and
  the reference passes it -- with the policy-independence claim removed and the
  preamble dependency stated.
* **T9** records that the instruction side is **priced, not enforced**: the
  cycle axis charges under-provisioning (899 cycles against 1,513, 273 reads
  against 642 for a design whose instruction TLB actually retains 16), and the
  only thing that can enforce P2 there is a structural flip-flop count after
  synthesis, which belongs to whoever runs PPA and **is not in place**.

This is a stated hole, not a closed one. It is written into the specification
rather than into this file alone so that nobody reads T4 and concludes both TLBs
are covered.

## 14. Sequence D, re-measured end to end

| design | verdict | cycles | PTE reads | hits | instr replay reads |
|---|---|---|---|---|---|
| reference | PASS 175/175 | 1,513 | 642 | 36% | 96 |
| second source | PASS 175/175 | **899** | **273** | 45% | **0** |
| `nc_a_stuck_output` | FAIL 114 | 1,513 | 642 | 36% | 96 |
| `nc_b_serial_response` | PASS (axis) | **3,332** | 660 | 36% | 96 |
| `nc_c_bloat_storage` | PASS (axis) | 1,513 | 642 | 36% | 96 |
| `nc_d_no_resident_tlb` | FAIL 175 | 103,802 | 0 | -- | 0 |
| `nc_e_super_offset` | FAIL 2 | 1,513 | 642 | 36% | 96 |
| `nc_f_ad_ignored` | FAIL 4 | 1,513 | 642 | 36% | 96 |

Two conforming designs, 1.68x apart on cycles. That spread is the argument for
L1 having a cycle axis at all, and it is now measured between two real
implementations rather than between the reference and a control.

The hit fraction fell from 51% to 36% because sequence D's added phase is
dominated by cold instruction walks. Section 9's warning stands and now applies
to a different number: **36% is a scoring construct, not a claim about
representative workloads.**

---

## 15. Sequence F: what six frozen inputs were hiding

STEP 2's variation monitor found seven contract inputs held at one value for the
whole run. Three were legitimate and are now declared with the clause that
permits them. The other four, plus `asid_i`, were hiding clauses:

| input | clause it starved | reached now by |
|---|---|---|
| `pmpcfg_i`, `pmpaddr_i` | A8 entirely; A6 causes 1, 5, 7; A7's no-match case | phase 10 |
| `priv_lvl_i`, `ld_st_priv_lvl_i` | A4 supervisor rules | phase 11 |
| `sum_i` | A4's SUM exception | phase 11 |
| `mxr_i` | A4's execute-as-read | phase 11 |
| `asid_i` (+ `mk_pte` having no `G` argument) | A10, both halves | phase 12 |

Eleven of the twelve new requests behaved exactly as predicted before running.

### The twelfth rewrote a normative clause

Step 195 fetches through a PMP region granting R+W but not X. Predicted: cause 1.
Measured: **it translates.** `tb/audit/probe_pmp_tb.sv` then swept the matrix:

```
load  through R+W+X                              -> translates
load  through W+X, R denied                      -> cause 5
store through R+X, W denied                      -> TRANSLATES
fetch through R+W, X denied                      -> TRANSLATES
load  with no region at all                      -> cause 5
load  R denied, TLB WARM, zero page-table reads  -> TRANSLATES
```

The last line settles it. With the entry already resident no read is issued, and
the request succeeds through a region that denies R — so **the final translated
address is not permission-checked at all.** Only the walker's own reads are, and
only for R, which is the only bit a reader can need.

A8 had said "Every address the walker reads is checked ... and so is the final
translated address." That was written from the architectural rule rather than
from measurement, and it survived review because the sequence pinned `pmpcfg_i`
at one permitting region for its whole length, so no request could discriminate.
The second source recorded the ambiguity as gap G-3 before it was ever run, took
the architectural reading, and was correct against the text and wrong against the
reference. One measurement resolved four of its nine recorded gaps: G-3 answered,
G-4 and G-5 dissolved (there is no final-address check to prioritise, and bare
mode issues no walk), G-6 confirmed.

## 16. The flush-mid step was not aborting anything

Making four coverage flags outcome-derived instead of schedule-derived (F75) cost
one line and immediately failed the reference:

    controls: bare=1 flush_tlb=1 flush_mid=0

Step 10 carried `EV_FLUSH_MID`, and the flag had been set from `seq[i].ev` — the
array the testbench had just built — so it could not be false. Derived instead
from what the reference did, it went to zero. The trace says why:

    step=10 va=0000000080000000 acc=0 cyc=1 v=1 e=0 pa=00000000100000

**acc=0, cyc=1.** The step requested `SEQ_BASE`, which step 9 had just installed,
so it HIT THE TLB and retired in one cycle. `do_step` pulses `flush_i` three
cycles after asserting the request — long after retirement, with nothing in
flight to abort. C3's abort-and-restart and T5's cancelled-request check were
both unexercised, in a task where C3 had already been rewritten twice and T5
written specifically to check it.

Pointing the step at a non-resident page fixes it:

    step=10 va=0000000080012000 acc=8 cyc=15 v=1 e=0 pa=00000000112000

Eight reads — a partial walk aborted, then a full re-walk — and 15 cycles, which
is the figure C3 quotes for the held-request discipline. The clause now has the
stimulus it always claimed.

This is the strongest argument in the task for the F75 rule. The flag was not
merely weak; it was reporting coverage of the one clause this task has revised
most, and it reported it green for the whole life of the sequence.

## 17. Sequence F, measured end to end

| design | verdict | cycles | PTE reads | hits |
|---|---|---|---|---|
| reference | PASS 207/207 | 1,269 | 502 | 55% |
| second source | PASS 207/207 | **977** | **292** | 50% |
| `nc_a_stuck_output` | FAIL 122 | 1,269 | 502 | |
| `nc_b_serial_response` | PASS (axis) | **3,278** | | |
| `nc_c_bloat_storage` | PASS (axis) | 1,269 | | |
| `nc_d_no_resident_tlb` | FAIL 212 | 123,002 | | |
| `nc_e_super_offset` | FAIL 2 | 1,269 | | |
| `nc_f_ad_ignored` | FAIL 6 | 1,269 | | |
| `nc_g_itlb_one_entry` @1 | FAIL 1 (T9 alone) | 1,627 | | |
| `nc_g_itlb_one_entry` @16 | PASS | 977 | | |

Two conforming designs 1.30x apart on cycles — narrower than sequence D's 1.68x,
because the second source's advantage was concentrated in the instruction fill
that sequence F now hit-interleaves for both.

**The A5 check can fail now.** `+mutate_pte` flips one bit in a planted entry at
step 50 and the table comparison fires. Its predecessor was a counter that was
declared, compared, printed and never incremented — see F75.
