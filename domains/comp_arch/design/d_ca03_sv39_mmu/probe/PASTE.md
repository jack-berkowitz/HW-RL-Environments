# d_ca03 — RISC-V Sv39 memory management unit

Implement `sv39_mmu` in synthesisable SystemVerilog.

A three-level Sv39 page-table walker with an instruction TLB and a data TLB,
permission checking, fault generation, and physical memory protection. The page
table lives outside the unit: the walker reads it through `mem_*`, so a request
resolves to a physical address or to a fault, depending on what the entries say.

Four things about this contract are worth reading before choosing an
architecture:

* **The G clauses set out how you are graded**, in what order, and which
  optimisation levers are already closed. Read them first.
* **Two axes are scored and reported separately** — correctness (a gate), and
  **total cycles** over a fixed request sequence, alongside area. Serialising work
  to save area costs cycles; pipelining harder costs area at a fixed clock period.
  Neither is free.
* **Translation storage is normative, not a design choice.** P2 pins 16+16
  fully-associative entries and no second-level TLB. What you choose is how to
  implement that budget, not how much of it to provide.
* **PMP is in the page-walk path.** Every address the walker reads is checked, and
  an access fault from that check takes precedence over any page fault the entry
  would have caused. A design that treats PMP as an afterthought fails A7 and A8.

Everything normative is in the interface below.

```systemverilog
// =============================================================================
// sv39_mmu_iface.sv -- d_ca03 CONTRACT.
//
// A RISC-V Sv39 memory management unit: a three-level page-table walker, an
// instruction TLB and a data TLB, permission checking, fault generation, and
// physical memory protection on the walker's own accesses.
//
// Implement `sv39_mmu` to this contract. Everything asserted below about
// delivered addresses, fault causes and control behaviour was MEASURED against
// the reference -- see MEASUREMENTS.md. Where RISC-V permits more than one
// implementation, the choice is stated here rather than left to the reference.
//
// -----------------------------------------------------------------------------
// F -- ADDRESS AND PAGE-TABLE FORMAT
// -----------------------------------------------------------------------------
// F1. Sv39 VIRTUAL ADDRESS. 39 significant bits:
//       va[38:30] VPN[2]   va[29:21] VPN[1]   va[20:12] VPN[0]   va[11:0] offset
//     Bits 63:39 must be a sign extension of bit 38. A virtual address that is
//     not correctly sign-extended is not a legal Sv39 address; behaviour for
//     such an address is NOT SCORED (see T3).
//     AUTHORITY: RISC-V Privileged Architecture, Sv39 section.
//
// F2. PHYSICAL ADDRESS is 56 bits. PPN is 44 bits.
//
// F3. PAGE TABLE ENTRY, 64 bits:
//       [0] V   valid
//       [1] R   readable
//       [2] W   writable
//       [3] X   executable
//       [4] U   accessible in user mode
//       [5] G   global
//       [6] A   accessed
//       [7] D   dirty
//       [9:8]   RSW, ignored
//       [53:10] PPN
//       [63:54] reserved, ignored
//     A PTE with V=0 is invalid. A PTE with W=1 and R=0 is a reserved encoding.
//     AUTHORITY: RISC-V Privileged Architecture.
//
// -----------------------------------------------------------------------------
// V -- INTERFACE
// -----------------------------------------------------------------------------
// V1. Ports, exactly as declared at the foot of this file.
//
// V2. rst_ni asserted low empties both TLBs and returns the walker to idle. No
//     translation is delivered while it is low.
//
// V3. THE PAGE TABLE IS EXTERNAL. The walker reads it through mem_*: it asserts
//     mem_req_o with mem_addr_o, waits for mem_gnt_i, then waits for
//     mem_rvalid_i and takes the entry from mem_rdata_i. Only 8-byte aligned
//     reads are issued and the unit never writes. mem_addr_o is a full 56-bit
//     physical address.
//
// -----------------------------------------------------------------------------
// A -- TRANSLATION
// -----------------------------------------------------------------------------
// A1. THE WALK. With translation enabled, a request for virtual address va is
//     resolved by descending the table from the root at satp_ppn_i:
//       a = satp_ppn_i << 12
//       for level i from 2 down to 0:
//         pte = memory[a + VPN[i]*8]
//         if pte.V = 0                     -> page fault (A5)
//         if pte.R = 1 or pte.X = 1        -> leaf, stop
//         else                             -> a = pte.PPN << 12, continue
//       running past level 0 without a leaf -> page fault (A5)
//     AUTHORITY: RISC-V Privileged Architecture.
//
// A2. THE DELIVERED ADDRESS. For a leaf found at level i:
//       pa[55:12] = pte.PPN, with the low 9*i bits REPLACED by va's
//                   corresponding VPN bits
//       pa[11:0]  = va[11:0]
//     So a level-0 leaf contributes its whole PPN; a level-1 leaf (2 MiB) takes
//     VPN[0] from the virtual address; a level-2 leaf (1 GiB) takes VPN[1:0].
//     Measured: a 1 GiB leaf with PPN 0x40000 translates va 0x4000_0001 to
//     pa 0x4000_0001 -- the offset within the superpage is preserved.
//
// A3. MISALIGNED SUPERPAGE. A leaf at level i>0 whose PPN has any of its low
//     9*i bits set is misaligned and raises a page fault, not a translation.
//     AUTHORITY: RISC-V Privileged Architecture.
//
// A4. PERMISSION CHECKS, applied to the leaf PTE:
//       * a load requires R=1, or X=1 with mxr_i=1;
//       * a store requires W=1;
//       * an instruction fetch requires X=1;
//       * in user mode (priv 2'b00) the entry requires U=1;
//       * in supervisor mode (priv 2'b01) an entry with U=1 is accessible only
//         when sum_i=1, and is never executable.
//     A failing check raises a page fault (A5). ld_st_priv_lvl_i is the
//     privilege applied to load/store translation; priv_lvl_i applies to fetch.
//     AUTHORITY: RISC-V Privileged Architecture.
//
// A5. A AND D BITS -- FAULT, DO NOT UPDATE. This contract takes the
//     fault-on-unset choice, and RISC-V permits either:
//       * a leaf with A=0 raises a page fault for any access;
//       * a leaf with D=0 raises a page fault for a store;
//       * THE UNIT NEVER WRITES A PAGE TABLE ENTRY. mem_* is read-only.
//     Software is expected to set the bits and retry.
//     Measured: load through a leaf with A=0 gives cause 13 and leaves the entry
//     byte-identical in memory; store through a leaf with A=1,D=0 gives cause 15
//     and likewise does not modify it.
//     AUTHORITY: RISC-V Privileged Architecture permits both; this is the choice.
//
// A6. FAULT CAUSES, longhand, and these are the delivered values:
//       12  instruction page fault
//       13  load page fault
//       15  store/AMO page fault
//        1  instruction access fault      (PMP, see A8)
//        5  load access fault             (PMP, see A8)
//        7  store/AMO access fault        (PMP, see A8)
//     A load raises 13 and a store raises 15 for every page-fault condition in
//     A1, A3, A4 and A5. A fetch raises 12.
//     AUTHORITY: RISC-V Privileged Architecture, machine cause encodings.
//
// A7. FAULT PRIORITY. When more than one condition holds, an ACCESS fault from
//     A8 takes precedence over a PAGE fault: the walker's own read is checked
//     before the entry it returns can be interpreted. Measured: with no PMP
//     region matching, a walk that would otherwise page-fault reports cause 5,
//     and the same walk reports 13 once a permitting PMP region exists.
//
// A8. PHYSICAL MEMORY PROTECTION IS IN THE WALK PATH, AND ONLY THERE. Eight
//     entries, each pmpcfg_i[n] packed as
//       {locked, reserved[1:0], addr_mode[1:0], X, W, R}
//     with addr_mode 0 OFF, 1 TOR, 2 NA4, 3 NAPOT. A failing check raises an
//     ACCESS fault per A6, not a page fault.
//
//     WHAT IS CHECKED, and this is measured rather than assumed:
//       * EVERY ADDRESS THE WALKER READS, and the check requires R. The walker
//         only ever reads, so R is the only bit that can matter to it.
//       * NO PERMISSION CHECK IS APPLIED TO THE FINAL TRANSLATED ADDRESS, by any
//         access type. A translation delivered from a TLB hit issues no
//         page-table read and is therefore never PMP-checked at all.
//       * A REGION MATCHING NOTHING DENIES. With no entry matching, the walker's
//         read fails and the request takes an access fault.
//
//     Measured over seven configurations (tb/audit/probe_pmp_tb.sv):
//       load  through R+W+X            -> translates
//       load  through W+X, R denied    -> cause 5
//       store through R+X, W denied    -> TRANSLATES
//       fetch through R+W, X denied    -> TRANSLATES
//       fetch through R+W+X            -> translates
//       load  with no region at all    -> cause 5
//       load  through R denied, TLB warm, ZERO page-table reads -> TRANSLATES
//     The last line is the one that settles it: with the entry already resident
//     no read is issued, and the request succeeds through a region that denies
//     R. If the final address were checked it would have faulted.
//
//     AN EARLIER DRAFT OF THIS CLAUSE SAID "and so is the final translated
//     address", which is false. It was written from the architectural rule
//     rather than from measurement, and it survived because the sequence pinned
//     pmpcfg_i and pmpaddr_i at one permitting region for its whole length, so
//     no request ever discriminated. An independent implementation took the
//     architectural reading, checked the final address by access type, and was
//     correct against the text and wrong against the reference.
//
//     The consequence for a submission: causes 1, 5 and 7 arise ONLY from a
//     denied walker read, and the cause reflects the ORIGINAL access type, not
//     the walker's.
//     AUTHORITY: RISC-V Privileged Architecture, PMP section, for the entry
//     encoding. The scope of the check is this contract's, and is measured.
//
// A9. TLB TRANSPARENCY. A translation delivered from a TLB entry is identical to
//     the one the walk would have produced. Capacity and organisation are NOT
//     free choices -- they are pinned in P2, for the reason given there.
//
//     WHAT REMAINS UNSPECIFIED AND UNSCORED IS THE REPLACEMENT POLICY. Which
//     resident entry is displaced when a new translation must be installed is an
//     implementation choice. It is left free deliberately: the storage is already
//     fixed by P2, so no area is won by choosing one policy over another, and
//     pinning it would mandate a specific victim-selection circuit for no
//     measured benefit.
//
//     THAT FREEDOM IS WIDER THAN IT LOOKS, AND IT COSTS T4 ITS POLICY
//     INDEPENDENCE. The reference's own policy is a PLRU tree that advances only
//     on a lookup HIT (cva6_tlb.sv:436) and not on an install, so a cold fill of
//     N distinct pages with no intervening hit writes all N into ONE entry.
//     Measured, filling n distinct pages and then replaying all n:
//
//       n:              1   2   4   8  16  17
//       data TLB     hits: 1   2   4   8  16   0
//       instr TLB    hits: 1   0   0   0   0   0
//
//     The data TLB reaches 16 because the scored sequence's first eleven
//     requests produce hits that spread the tree before the fill begins; the
//     instruction TLB, reached cold, retains exactly one. BOTH ARE THE SAME
//     16-ENTRY STRUCTURE, and the difference is entirely the replacement policy
//     this clause declines to pin. So USABLE capacity is not a behavioural
//     property of a conforming design, and no residency test can establish it in
//     general. T4 and T9 say what is done about that instead of pretending
//     otherwise.
//
//     lsu_dtlb_hit_o, itlb_miss_o and dtlb_miss_o report this implementation's
//     own behaviour and are NOT SCORED (T2) -- scoring them would pin the
//     replacement policy A9 just declined to pin.
//
// A10. GLOBAL PAGES AND ASID. A leaf with G=1 is valid for every ASID. A leaf
//     with G=0 is valid only for the ASID current when it was installed.
//     AUTHORITY: RISC-V Privileged Architecture.
//
// A11. RETIREMENT SIGNALLING, and this clause exists because the contract did
//     not decide it. lsu_valid_o MEANS "THIS REQUEST HAS RETIRED", NOT "A
//     TRANSLATION WAS PRODUCED":
//       * a request that translates retires with lsu_valid_o = 1,
//         lsu_exc_valid_o = 0, and lsu_paddr_o carrying the address of A2;
//       * A REQUEST THAT FAULTS RETIRES WITH lsu_valid_o = 1 AS WELL, in the
//         same cycle as lsu_exc_valid_o = 1 and the cause of A6.
//     The fetch port behaves identically on fetch_valid_o / fetch_exc_valid_o.
//     Measured: every one of the four faulting requests in the scored sequence
//     asserts both, in one cycle.
//
//     lsu_paddr_o AND fetch_paddr_o ARE NOT CONSTRAINED WHEN THE MATCHING
//     exc_valid_o IS ASSERTED, and T2 does not score them there. The reason is
//     not convenience. Their value on a fault reports WHERE the failing check
//     was made: a design that rejects an A=0 or D=0 leaf inside the walker has
//     no translated address to present and delivers zero, while one that
//     installs the leaf and applies A4/A5 on the TLB hit path has computed the
//     address and delivers it. A5 permits both -- it requires a fault and
//     forbids a page-table write, and says nothing about where the check sits.
//     Scoring the address would therefore have scored an internal choice, which
//     is exactly what T2 exists to prevent.
//
//     HOW THIS WAS FOUND. An independent implementation written against this
//     specification alone read the earlier text the other way -- L2's "either
//     with a translation or with a fault" reads as an exclusive or -- and
//     asserted exc_valid_o without valid_o. It failed all four faulting
//     requests and passed the other 114, so the contract as written admitted
//     two readings on a surface T1 declares scored. Both readings satisfied
//     every clause in F, V, A and C. The paddr divergence surfaced the same
//     way, one step behind it. See rule 5 branch three: ambiguous
//     specification, both implementations legal, and the specification is what
//     changes.
//
// -----------------------------------------------------------------------------
// C -- CONTROL
// -----------------------------------------------------------------------------
// C1. TRANSLATION ENABLES. enable_translation_i governs fetch, and
//     en_ld_st_translation_i governs load/store. With the relevant enable low
//     the unit is in BARE mode: pa = va[55:0], delivered without a walk, no
//     TLB involvement, and no page fault. Measured: va 0xDEAD_B000 delivers
//     pa 0xDEAD_B000 in one cycle.
//
// C2. flush_tlb_i EMPTIES BOTH TLBs. A subsequent translation of a
//     previously-cached page must walk the table again and deliver the same
//     result. asid_to_be_flushed_i and vaddr_to_be_flushed_i narrow the flush;
//     a design may treat any flush as a full flush, since a full flush is a
//     conservative implementation of a narrowed one and delivers identical
//     translations.
//
// C3. flush_i ABORTS AN IN-FLIGHT WALK, AND THE UNIT RESTARTS IT. It does not
//     empty the TLBs.
//
//     THE REQUESTER'S OBLIGATION IS TO HOLD lsu_req_i, AND NOTHING MORE. A
//     request whose lsu_req_i stays asserted across and after the flush is
//     RE-WALKED by the unit and retires normally, delivering the translation the
//     page table then describes. The requester does not observe the flush, does
//     not deassert, and does not re-issue. THE REQUEST IS NOT DROPPED.
//
//     Measured both ways, because the difference IS the obligation:
//       * lsu_req_i HELD across flush_i -- retires after 15 cycles with the
//         correct address, the unit having re-walked of its own accord;
//       * deasserted and then re-issued -- also retires, in 1 cycle, from the
//         entry that re-walk installed.
//     Both disciplines work, which is why this clause requires only the first
//     and a submission may not assume the second.
//
// C4. RESULTS ARE SCORED ACROSS CONTROL TRANSITIONS; LATENCY IS NOT. Every
//     transition measured -- flush_tlb_i while idle, flush_tlb_i during a walk,
//     flush_i during a walk -- delivered the CORRECT translation. What changed
//     was how long it took. So no transition window excludes results; the
//     latency exclusion of L1 covers the timing.
//     This is narrower than the blanket exclusion an earlier draft of this
//     clause carried, and deliberately so: a first measurement of flush_i
//     mid-walk read lsu_valid_o as a level and picked up a stale assertion from
//     the previous request, which looked like an ambiguous result and was not.
//
// C5. CHANGING satp_ppn_i OR asid_i WITHOUT AN INTERVENING FLUSH IS OUT OF
//     SCOPE. RISC-V requires an SFENCE.VMA after writing satp before the new
//     translation regime may be relied upon, so a change with a walk in flight
//     and no flush is architecturally undefined rather than merely unspecified
//     here. Not scored, and not because it was hard to measure.
//     AUTHORITY: RISC-V Privileged Architecture, SFENCE.VMA.
//
// -----------------------------------------------------------------------------
// L -- LATENCY
// -----------------------------------------------------------------------------
// L1. CYCLES ARE SCORED, over a fixed probe sequence, and reported SEPARATELY
//     from area. They are not combined into a single figure -- a scalar would
//     need a weighting between a cycle and a square micron that nobody can
//     defend, and rule 22 refuses that trade for area against frequency for the
//     same reason.
//
//     WHAT IS COUNTED. The total cycles the design takes to retire the whole
//     scored sequence: every request from the first to the last, including the
//     walks, the TLB hits, the faulting requests and the flush windows. The
//     sequence, the page-table contents and the memory response timing are FIXED
//     BY THE HARNESS and identical for every submission, so the count is
//     deterministic and comparable.
//
//     AN EARLIER DRAFT LEFT CYCLES UNSCORED, and the stated reason -- that
//     per-request latency depends on a testbench-controlled handshake -- was
//     true but not the real one. The real reason was that no cycle-count axis
//     existed, and with area charged and time free, SERIALISING ANY WORK WAS
//     FREE: one comparator swept across the 16 TLB entries beat sixteen parallel
//     ones, one PMP comparator beat eight, and a per-entry flush clear beat a
//     generation counter. Every one of those was a dominant strategy rather than
//     a trade. With cycles scored they are trades again: on the scored sequence
//     a swept comparator costs roughly 16 cycles on every hit, a single PMP
//     comparator roughly 8 on every check, and the measured flush is 139 cycles
//     against a generation counter's one.
//
//     NOT constrained: the latency of any INDIVIDUAL request. Only the total over
//     the sequence is compared, so a design may spend cycles unevenly -- fast
//     hits and slow walks, or the reverse -- however it likes.
// L2. FORWARD PROGRESS IS scored, WITH NO EXCEPTION. Every request must
//     eventually retire -- asserting valid_o per A11, with exc_valid_o and a
//     cause alongside it if the request faults -- INCLUDING a request whose walk
//     was aborted by flush_i, which C3 requires the unit to restart. A request
//     that never retires fails.
//
//     AN EARLIER DRAFT SAID "either with a translation or with a fault", which
//     reads as an exclusive or and is not what the reference does: a faulting
//     request asserts BOTH. A11 now states the handshake, and that phrasing is
//     gone. It cost an independent implementation four of 175 requests.
//
//     AN EARLIER DRAFT CARVED OUT flush_i-CANCELLED REQUESTS, AND THAT WAS
//     WRONG. The carve-out rested on a recorded reference value showing neither
//     lsu_valid_o nor lsu_exc_valid_o for the flush-mid step. That was a HARNESS
//     DEFECT, not a design behaviour: the rig sampled lsu_valid_o as a LEVEL once
//     per cycle and missed the assertion. The rig was fixed to latch retirement,
//     and the same step now records valid=1 with the correct address -- but the
//     clause written from the bad reading was not revisited until the obligation
//     was measured directly. FIXING AN INSTRUMENT OBLIGES RE-DERIVING WHATEVER
//     WAS CONCLUDED WITH IT; see rule 27.
//
// -----------------------------------------------------------------------------
// P -- PARAMETERS
// -----------------------------------------------------------------------------
// P1. The scored configuration is Sv39 with XLEN=64, VLEN=64, PLEN=56, a 16-bit
//     ASID and eight PMP entries. There is one configuration; this task does not
//     parameterise geometry.
//
// P2. TRANSLATION STORAGE IS NORMATIVE, NOT A DESIGN CHOICE. A conforming design
//     provides exactly:
//
//       instruction TLB   16 entries, FULLY ASSOCIATIVE
//       data TLB          16 entries, FULLY ASSOCIATIVE
//       second-level TLB  NONE -- there is no shared or L2 TLB in this
//                         configuration
//
//     These match the harvested reference configuration exactly:
//     `InstrTlbEntries: 16`, `DataTlbEntries: 16`, `UseSharedTlb: 0`. The
//     reference does instantiate a shared-TLB module, but with `UseSharedTlb: 0`
//     it is bypassed and constant-folded away; a conforming design must not
//     provide one.
//
//     WHY THIS IS PINNED RATHER THAN LEFT FREE. Correctness never depends on TLB
//     capacity -- every request a TLB misses is resolved by the walk, and A9
//     requires the two paths to agree. Latency is unscored (L1). So if capacity
//     were a free choice, the dominant strategy would be ZERO ENTRIES: walk every
//     request, satisfy every clause in F, V, A and C, and take the smallest area
//     on the board. The same reasoning defeats free associativity -- direct-mapped
//     strictly dominates fully-associative when hit rate is unmeasured -- and free
//     second-level sizing, where deleting the level is free area. The comparison
//     would then rank submissions by who read A9 closely, not by design quality.
//     Pinning the budget is what makes the area figure mean "implemented this
//     storage well" instead of "provisioned least".
//     See rule 25: an unpriced axis is bounded in the specification, not given a
//     metric of its own.
//
// -----------------------------------------------------------------------------
// T -- SCORING
// -----------------------------------------------------------------------------
// T1. Scored surface: lsu_valid_o, lsu_paddr_o, lsu_exc_valid_o,
//     lsu_exc_cause_o, and the fetch equivalents, compared against the
//     reference for the same stimulus and the same page-table contents.
//     BOTH PORTS ARE ACTUALLY DRIVEN -- see T8, which exists because an earlier
//     sequence declared the fetch surface scored and never exercised it.
//     valid_o, exc_valid_o and exc_cause_o are compared on EVERY request.
//     paddr_o is compared only on requests that do not fault, per A11 and T2.
//
// T2. NOT scored: lsu_dtlb_hit_o, lsu_dtlb_ppn_o, itlb_miss_o, dtlb_miss_o
//     (A9), and the number and order of memory accesses a walk issues -- these
//     report an implementation's own choices. Cycles ARE scored, per L1, but
//     only as a total over the sequence and never per request.
//
//     ALSO NOT scored: lsu_paddr_o and fetch_paddr_o ON A REQUEST THAT FAULTS,
//     for the reason A11 gives -- the value reports where the failing check was
//     made, and A5 leaves that free. Everything else about a faulting request
//     IS scored: that it retires, that it raises an exception, and the cause.
//
//     ALSO NOT scored: mem_tag_valid_o and mem_kill_o. They are in the port list
//     because V1 fixes the port list, and V3 defines the memory protocol without
//     them. No clause constrains them and none should be inferred.
//
// T3. NOT scored: virtual addresses that are not correctly sign-extended per F1,
//     and satp_ppn_i or asid_i changes without an intervening flush per C5.
//
// T4. THE DATA TLB'S ENTRY COUNT IS CHECKED, not taken on trust. Without a
//     check, nothing distinguishes a design that provides 16 usable entries from
//     one that declares the arrays and never fills them -- and the second is
//     smaller after synthesis, so the incentive runs the wrong way. On the DATA
//     TLB:
//       * translate 16 distinct pages, then translate all 16 again. The second
//         pass must issue NO page-table read on mem_*.
//       * translate a 17th distinct page, then translate all 17. This pass MUST
//         issue at least one page-table read.
//     Which of the 17 is displaced is not checked.
//
//     FOR THIS CHECK ONLY, the presence or absence of mem_* activity during the
//     replay is scored, as an exception to T2. The COUNT and ORDER of accesses
//     remain unscored.
//
//     THIS CHECK IS NOT POLICY-INDEPENDENT, AND AN EARLIER DRAFT CLAIMED IT WAS.
//     The claim was that not checking WHICH entry is displaced keeps the test
//     free of policy assumptions. It does not: passing the 16-page replay
//     requires a replacement policy that spreads a cold fill across 16 distinct
//     entries, and A9 permits policies that do not -- the reference's own is one
//     of them. What makes the reference pass here is that the eleven requests
//     preceding the fill generate hits that advance its replacement tree first.
//     SO THIS CHECK DEPENDS ON THE SEQUENCE'S PREAMBLE. Reorder the sequence and
//     it can fail on a conforming design. It is kept because it does catch the
//     declare-and-never-fill cheat and the reference passes it, and it is
//     labelled rather than trusted. The instruction side is T9.
//
// T5. THE CANCELLED-REQUEST OBLIGATION IS CHECKED. The scored sequence contains
//     a request whose walk is aborted mid-flight by flush_i with lsu_req_i held
//     asserted throughout, and the reference retires it with the correct address.
//     A design that drops it -- leaving the requester waiting -- fails L2, and one
//     that retires it with a stale address fails C3.
//
// T6. THE SUBMISSION MUST ELABORATE UNDER BOTH slang AND Verilator. Passing
//     simulation is not sufficient: the synthesis frontend is slang, and a
//     construct Verilator accepts silently can be a hard error there, in which
//     case a correct submission produces NO PPA NUMBER AT ALL. slang enforces
//     an unroll budget of 4000 iterations across nested loops:
//         error: unroll limit of 4000 exhausted [--unroll-limit=]
//     A per-bit search nested inside a per-entry loop reaches it quickly. Give
//     every loop a small constant bound. This is reproduced history: two earlier
//     tasks in this repository hit that exact error.
//
// T7. A submission must pass every clause above; there is no partial credit.
// T8. EVERY INPUT THIS CONTRACT GIVES MEANING TO MUST TAKE MORE THAN ONE VALUE
//     over the scored sequence, and an input permitted to stay constant must be
//     NAMED HERE WITH THE CLAUSE THAT PERMITS IT. This is a scoring requirement,
//     not a remark about the harness, and an undeclared constant FAILS.
//
//     VARIATION, NOT ASSIGNMENT, and the difference is the whole clause. An
//     earlier draft required only that fetch_req_i be DRIVEN. That catches an
//     input nobody assigns and misses an input assigned every cycle at a fixed
//     value -- which is what asid_i was, so A10 went unexercised while a
//     driven-at-least-once test passed. Five further inputs were frozen the same
//     way, taking A4's supervisor, SUM and MXR rules and the whole of A8 with
//     them. An input that never changes has not been tested, however
//     continuously it was assigned.
//
//     PERMITTED CONSTANTS, each with its reason:
//       satp_ppn_i               one root page table; C5 puts changing it out of
//                                scope, so one value is the whole scored regime.
//       asid_to_be_flushed_i     C2 lets any flush be treated as a full flush,
//       vaddr_to_be_flushed_i    which makes both narrowing inputs non-load-bearing.
//     Everything else varies: both request ports, both address ports, is_store,
//     the two enables, both flushes, priv_lvl_i, ld_st_priv_lvl_i, sum_i, mxr_i,
//     asid_i, pmpcfg_i, pmpaddr_i, and the three memory response inputs.
//
//     What the sequence reaches as a result: an instruction walk, an instruction
//     TLB hit, a superpage fetch, two instruction faults reaching cause 12, bare
//     mode on both sides, the capacity replay on both TLBs, all three PMP access
//     causes, supervisor mode with SUM set and clear, MXR set and clear, and a
//     global page hit under a second ASID.
//
//     WHY IT IS WRITTEN DOWN. An earlier sequence left fetch_req_i tied to zero
//     for all 118 of its requests while T1 declared the fetch surface scored and
//     A6 pinned causes 12 and 1. A submission could have tied fetch_valid_o low
//     and provided a ONE-ENTRY instruction TLB and passed everything -- which
//     reopens, on half of P2's pinned storage, precisely the incentive T4 was
//     written to close. T4's own text says "for each TLB independently"; only
//     the data TLB was ever reached. Nothing had to be built to close this: the
//     page table already planted X=1 U=1 leaves, so the instruction phases are
//     seven functional requests and a fifty-request capacity replay over the
//     table that was already there. See rule 25: a clause that pins a budget
//     needs the check that makes the budget real, and the check has to run.
//
//
// T9. THE INSTRUCTION TLB'S ENTRY COUNT IS CHECKED, by the same replay T4 uses
//     on the data side, with one difference that makes it possible at all: THE
//     FILL RE-TOUCHES EACH PAGE after installing it.
//
//     Why that detail is load-bearing. The reference's replacement tree advances
//     only on a lookup HIT, so a COLD fill of 16 distinct pages puts every
//     install in one entry and the reference itself retains ONE. Measured, filling
//     n pages then replaying all n:
//
//       n:                  1   2   4   8  16  17
//       cold fill,   instr: 1   0   0   0   0   0
//       hit-interleaved:    1   2   4   8  16  15
//
//     With the re-touch the reference retains all 16 and 17 pages thrash it to
//     15, so the check discriminates. It is also MORE policy-tolerant than the
//     cold fill, not less: the reference's PLRU-on-hit and a
//     prefer-invalid-then-round-robin policy both pass, and those are two
//     genuinely different policies.
//
//     VALIDATED BY A CONTROL, not by passing. controls/nc_g_itlb_one_entry.sv is
//     the second source with its instruction TLB pinned to one entry and its
//     ports left full width, so it answers every request correctly and merely
//     discards capacity. At 16 entries it passes; at 1 it FAILS THIS CHECK ALONE,
//     with zero per-step failures on the T1 surface -- a miss walks and returns
//     the same translation, so nothing else can catch it.
//
//     AN EARLIER DRAFT SAID THIS COULD NOT BE CHECKED and downgraded the budget
//     to "priced, not enforced". That was wrong, and wrong in the expensive
//     direction: the probe behind it filled cold, so it measured the replacement
//     policy and not the capacity. A structural flip-flop count was proposed to
//     stand in its place and has been DROPPED -- a check requiring synthesis
//     cannot gate correctness without inverting G1's order, in which a failing
//     submission produces no PPA number at all.
//
// T10. ASID AND GLOBAL PAGES ARE CHECKED, and the check reads mem_* activity
//     rather than the T1 surface, as a stated exception to T2 alongside T4 and T9.
//
//     THE REASON IT CANNOT BE SCORED ON T1. One page table serves every ASID
//     here, because satp_ppn_i is fixed. So a design that ignores asid_i and
//     reuses a stale non-global entry returns EXACTLY THE SAME ADDRESS as one
//     that re-walks. The difference is not observable in what is delivered, only
//     in whether a page-table read happened.
//
//     The check, after a flush, with a global leaf and a non-global leaf both
//     installed under ASID 1:
//       * the GLOBAL page, requested under ASID 2, must issue NO page-table read;
//       * the NON-GLOBAL page, requested under ASID 2, MUST issue at least one.
//
//     Neither half was reachable before. asid_i was driven at the constant zero
//     for the whole sequence, and the page-table constructor had no G argument at
//     all -- PTE bit 5 was hardcoded to zero, so no planted entry was ever
//     global. A10 was pinned longhand and unexercised in both halves.

//
//     Run the T4 replay against the instruction TLB and the REFERENCE ITSELF
//     issues 96 page-table reads where the data TLB issues none -- every replay
//     walks, because that TLB is reached cold and A9's free replacement policy
//     leaves all sixteen installs in one entry. A submission providing a
//     ONE-ENTRY instruction TLB would be behaviourally indistinguishable from
//     the reference on the whole scored sequence while saving roughly 1,500
//     flip-flops. No residency assertion can separate them.
//
//     TWO THINGS STAND IN ITS PLACE, and only the first is live today.
//       1. THE CYCLE AXIS PRICES IT. L1 counts cycles over the sequence, and
//          phase 9 is 50 instruction requests over 17 pages. A design whose
//          instruction TLB actually retains 16 entries pays 273 page-table reads
//          across the sequence against the reference's 642, and finishes in 899
//          cycles against 1,513. Under-provisioning is therefore CHARGED rather
//          than prohibited -- which is the same trade G4 describes everywhere
//          else, and is why this hole is tolerable rather than fatal.
//       2. A STRUCTURAL CHECK, which is the only thing that can actually enforce
//          P2 here: flip-flop count after synthesis against the field-list floor
//          G4 already quotes -- 3,467 in the reference against a floor of about
//          3,168 for 32 entries. That measurement belongs to whoever runs PPA
//          and IS NOT IN PLACE. UNTIL IT IS, P2's instruction-side budget is
//          priced but not enforced. Recorded so that nobody reads T4 and
//          concludes both TLBs are covered.
//
// -----------------------------------------------------------------------------
// G -- GRADING
// -----------------------------------------------------------------------------
// G1. THE ORDER, and correctness is a GATE rather than a weighting.
//     1. CORRECTNESS. Bit-exact on the T1 surface against the reference. There
//        is no partial credit and no tolerance.
//     2. THE GATE. A submission that fails correctness produces NO PPA NUMBER
//        AT ALL, recorded as a failure rather than as a missing measurement.
//     3. PPA, measured only for submissions that passed, ONCE AT A PINNED CLOCK
//        PERIOD rather than by sweeping for a maximum frequency, so every
//        submission is compared at one frequency.
//
// G2. WHAT IS COMPARED: area post-synthesis and post-place-and-route, power at
//     the pinned period, and this task's own cycle axis.
//
//     TIMING CLOSURE IS A GATE, NOT AN AXIS, AND SLACK IS NOT SCORED. A build
//     that misses the pinned period yields no comparable area or power figure --
//     an area number from a build that did not close is not a smaller design, it
//     is an unfinished one -- so its PPA is withheld rather than reported.
//
//     Slack ABOVE zero earns nothing either, and the reason is that it is not a
//     separate quantity from area. Meeting timing with margin is bought WITH
//     area: the tools upsize cells, insert buffers and duplicate logic to close
//     faster. A design sitting well clear of the pinned period spent silicon
//     getting there that a design sitting just inside it did not. Area already
//     charges for that, so scoring slack as well would count one tradeoff twice
//     and in opposite directions -- rewarding a design for the very spending the
//     area axis penalises. Closure is pass or fail, and everything above the
//     line is the same result.
//
//     Fmax is NOT a scored axis. It is measured once per task, on the REFERENCE
//     ONLY, and its sole job is to set the pinned period above. Submissions are
//     not swept. A design that could run faster than the pinned period earns
//     nothing for it, exactly as a design handed a frequency target in practice
//     earns nothing for exceeding it; and a per-design Fmax could not be combined
//     with the area and power above in any case, because those come from a build
//     at the pinned period and an Fmax comes from a different build at a
//     different one.
//
// G3. WHAT IS NOT AVAILABLE TO OPTIMISE.
//       * THE TRANSLATION ITSELF. Every delivered address and every fault cause
//         is pinned by F1-F3 and A1-A10. There is no accuracy trade.
//       * THE MEMORY PROTOCOL. mem_* is a read-only request/grant/valid
//         handshake; a design cannot batch, reorder or cache table reads in a
//         way that changes what T1 observes.
//
// G4. WHAT IS ACTUALLY LEFT: IMPLEMENTING A FIXED STORAGE BUDGET WELL, NOT
//     CHOOSING IT -- AND THE CYCLE AXIS CHARGES FOR BUYING AREA WITH TIME.
//     P2 pins the budget at 16+16 fully-associative entries and no second level,
//     so a submission cannot compete by provisioning less. About 45% of the
//     reference's area is that storage and is close to irreducible -- 3,467
//     flip-flops against a field-list floor of roughly 3,168. The remaining ~55%
//     is the logic around it, and that is where the area difference comes from:
//
//       * MULTI-PAGE-SIZE TAG COMPARISON. Three page sizes plus Svnapot, checked
//         against 16 entries. Mask logic per entry, separate arrays per size, or
//         one array with size bits are all conforming and do not cost the same.
//       * COMBINATIONAL VERSUS REGISTERED LOOKUP, real because PPA is measured at
//         a PINNED period: register only as much as meeting the period requires.
//       * PER-ENTRY WIDTH. P2 fixes the entry COUNT, not the LAYOUT. Only the
//         fields F3, A4 and A10 require need storing.
//       * PMP STRUCTURE across the eight regions, and whether the walker's own
//         checks (A8) reuse the same comparators.
//       * WALKER SEQUENCING across the three levels.
//
//     TIME IS CHARGED, SO AREA CANNOT BE BOUGHT WITH IT. Every one of those
//     choices can be made smaller by doing the work over more cycles, and L1
//     counts cycles over the scored sequence. A swept comparator, a single PMP
//     comparator or a slow flush all show up there. Neither axis dominates: a
//     small-and-slow submission and a large-and-fast one are both legitimate, and
//     both are visible because the two axes are reported separately.
//
//     A submission that meets the pinned period with less area and less power
//     scores better. There is no credit for slack beyond zero.
// G5. THERE IS NO SINGLE COMBINED SCORE, and that is deliberate rather than
//     unfinished. Nothing in this project establishes what a unit of
//     capability is worth in square micrometres, so no weighted sum of area,
//     power and capability is computed, and none should be inferred from the
//     phrase "scores better" above. Each axis is reported separately, and a
//     submission that wins on one and loses on another is reported as exactly
//     that.
//
//     WHAT A SUBMISSION IS COMPARED AGAINST. The reference implementation,
//     built from the same contract at the same pinned period and the same
//     scored configuration, and the other submissions to this task on the
//     same axes. The reference is an ANCHOR, not a target: beating it is not
//     required and losing to it is not disqualifying. It exists so that a
//     number has something to be a ratio of.
//
//     EVERY REPORTED METRIC CARRIES A ROLE, and the role decides how a
//     difference from the reference is read:
//
//       * FIXED -- the contract requires a value. Deviating is a specification
//       violation, not a design choice, and it fails correctness.
//       * CHOICE -- the contract leaves it free and it moves PPA. Where a
//       submission chose differently from the reference, the area ratio is
//       marked NOT LIKE-FOR-LIKE rather than presented as a quality gap.
//       Choosing differently from the reference is not penalised; it is
//       disclosed.
//       * CAPABILITY -- more is better and area buys it. Reported both raw and
//       per unit of area, because raw area credits a design for being small
//       when it was actually doing less.
//
//     So the honest summary of the whole scheme: correctness gates, timing
//     closure gates, and what survives both is described on several axes at one
//     operating point, with the free choices named so that a difference in area
//     can be read as the trade it is rather than as a verdict.
//
// =============================================================================
module sv39_mmu (
  input  logic        clk_i,
  input  logic        rst_ni,
  input  logic        flush_i,

  input  logic        enable_translation_i,
  input  logic        en_ld_st_translation_i,

  input  logic        lsu_req_i,
  input  logic [63:0] lsu_vaddr_i,
  input  logic        lsu_is_store_i,
  output logic        lsu_valid_o,
  output logic [55:0] lsu_paddr_o,
  output logic        lsu_dtlb_hit_o,
  output logic [43:0] lsu_dtlb_ppn_o,
  output logic        lsu_exc_valid_o,
  output logic [63:0] lsu_exc_cause_o,
  output logic [63:0] lsu_exc_tval_o,

  input  logic        fetch_req_i,
  input  logic [63:0] fetch_vaddr_i,
  output logic        fetch_valid_o,
  output logic [55:0] fetch_paddr_o,
  output logic        fetch_exc_valid_o,
  output logic [63:0] fetch_exc_cause_o,
  output logic [63:0] fetch_exc_tval_o,

  input  logic [1:0]  priv_lvl_i,
  input  logic [1:0]  ld_st_priv_lvl_i,
  input  logic        sum_i,
  input  logic        mxr_i,
  input  logic [43:0] satp_ppn_i,
  input  logic [15:0] asid_i,

  input  logic        flush_tlb_i,
  input  logic [15:0] asid_to_be_flushed_i,
  input  logic [63:0] vaddr_to_be_flushed_i,
  output logic        itlb_miss_o,
  output logic        dtlb_miss_o,

  output logic        mem_req_o,
  output logic [55:0] mem_addr_o,
  output logic        mem_tag_valid_o,
  output logic        mem_kill_o,
  input  logic        mem_gnt_i,
  input  logic        mem_rvalid_i,
  input  logic [63:0] mem_rdata_i,

  input  logic [7:0][7:0]  pmpcfg_i,
  input  logic [7:0][53:0] pmpaddr_i
);
endmodule
```
