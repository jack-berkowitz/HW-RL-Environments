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
// A8. PHYSICAL MEMORY PROTECTION IS IN THE WALK PATH. Every address the walker
//     reads is checked against pmpcfg_i/pmpaddr_i, and so is the final
//     translated address. Eight entries, each pmpcfg_i[n] packed as
//       {locked, reserved[1:0], addr_mode[1:0], X, W, R}
//     with addr_mode 0 OFF, 1 TOR, 2 NA4, 3 NAPOT. A failing check raises an
//     ACCESS fault per A6, not a page fault.
//     AUTHORITY: RISC-V Privileged Architecture, PMP section.
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
//     lsu_dtlb_hit_o, itlb_miss_o and dtlb_miss_o report this implementation's
//     own behaviour and are NOT SCORED (T2) -- scoring them would pin the
//     replacement policy A9 just declined to pin.
//
// A10. GLOBAL PAGES AND ASID. A leaf with G=1 is valid for every ASID. A leaf
//     with G=0 is valid only for the ASID current when it was installed.
//     AUTHORITY: RISC-V Privileged Architecture.
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
// C3. flush_i ABORTS AN IN-FLIGHT WALK. It does NOT empty the TLBs. A request
//     issued after the abort is served normally. Measured: a walk aborted
//     mid-flight by flush_i is followed by a correct translation of the same
//     page in one cycle, from the TLB entry the abort left intact.
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
// L2. FORWARD PROGRESS IS scored, WITH ONE EXCEPTION. Every request must
//     eventually retire, either with a translation or with a fault, EXCEPT a
//     request cancelled by flush_i while its walk is in flight: that request is
//     abandoned and never retires. The requester is expected to reissue it.
//
//     Measured, and this clause was wrong before it was measured. The reference
//     leaves a flush_i-cancelled request with neither lsu_valid_o nor
//     lsu_exc_valid_o asserted, indefinitely -- confirmed by the recorded
//     reference behaviour for the flush-mid step of the scored sequence, which
//     carries valid=0 and exc_valid=0. An earlier draft of L2 required every
//     request to retire, which the reference itself does not satisfy. C3 already
//     said flush_i aborts the walk; it did not say the aborted request is
//     abandoned, and that omission is what made L2 wrong.
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
//
// T2. NOT scored: lsu_dtlb_hit_o, itlb_miss_o, dtlb_miss_o (A9), and the number
//     and order of memory accesses a walk issues -- these report an
//     implementation's own choices. Cycles ARE scored, per L1, but only as a
//     total over the sequence and never per request.
//
// T3. NOT scored: virtual addresses that are not correctly sign-extended per F1,
//     and satp_ppn_i or asid_i changes without an intervening flush per C5.
//
// T4. THE PINNED ENTRY COUNTS ARE CHECKED, not taken on trust. Without a check,
//     nothing distinguishes a design that provides 16 usable entries from one that
//     declares the arrays and never fills them -- and the second is smaller after
//     synthesis, so the incentive runs the wrong way.
//
//     The check is BEHAVIOURAL AND POLICY-INDEPENDENT, so it does not smuggle in
//     the replacement policy A9 leaves free. For each TLB independently:
//       * translate 16 distinct pages, then translate all 16 again. The second
//         pass must issue NO page-table read on mem_*: 16 entries must all be
//         simultaneously resident, whatever order they were installed in.
//       * translate a 17th distinct page, then translate all 17. This pass MUST
//         issue at least one page-table read: 17 cannot be resident in 16 entries.
//     Which of the 17 is displaced is not checked, and that is what keeps the
//     test free of any policy assumption.
//
//     FOR THIS CHECK ONLY, the presence or absence of mem_* activity during the
//     replay is scored, as an exception to T2. The COUNT and ORDER of accesses
//     remain unscored.
//
// T5. THE SUBMISSION MUST ELABORATE UNDER BOTH slang AND Verilator. Passing
//     simulation is not sufficient: the synthesis frontend is slang, and a
//     construct Verilator accepts silently can be a hard error there, in which
//     case a correct submission produces NO PPA NUMBER AT ALL. slang enforces
//     an unroll budget of 4000 iterations across nested loops:
//         error: unroll limit of 4000 exhausted [--unroll-limit=]
//     A per-bit search nested inside a per-entry loop reaches it quickly. Give
//     every loop a small constant bound. This is reproduced history: two earlier
//     tasks in this repository hit that exact error.
//
// T6. A submission must pass every clause above; there is no partial credit.
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
// G2. WHAT IS COMPARED: area post-synthesis and post-place-and-route; power at
//     the pinned period; and worst negative slack against it. A build that
//     misses timing yields no comparable area or power figure.
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
