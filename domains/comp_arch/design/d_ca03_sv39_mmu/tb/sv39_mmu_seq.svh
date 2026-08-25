// sv39_mmu_seq.svh -- d_ca03 SEQUENCE C, and the vector record layout.
//
// INCLUDED BY BOTH the capture rig (tb/audit/capture_vectors_tb.sv) and the
// scoring testbench. One definition, two readers: if the sequence lived
// separately in each, a silent divergence would present as a mismatch on every
// request, which is the most expensive kind of false signal to chase.
//
// SEQUENCE E, 192 requests. The mix is a SCORING CONSTRUCT, not a workload
// model -- see MEASUREMENTS.md section 9. It is built to price serialisation:
// at a high TLB hit rate a swept comparator costs about 2.26x on total cycles,
// where the functional probes alone (20% hits) would barely register it.
//
// SEQUENCE C DROVE THE LOAD/STORE PORT ONLY. fetch_req was initialised to zero
// and never asserted, so the entire instruction surface T1 declares scored --
// fetch_valid_o, fetch_paddr_o, fetch_exc_valid_o, fetch_exc_cause_o, and A6's
// causes 12 and 1 -- was never exercised, and T4's capacity check only ever
// reached the DATA TLB. A submission could have tied fetch_valid_o low and
// provided a one-entry instruction TLB and passed, which reopens on half of
// P2's pinned storage exactly the incentive T4 exists to close. Sequence D adds
// phases 8 and 9 to drive it. Found by the second source, not by review.

`ifndef SV39_MMU_SEQ_SVH
`define SV39_MMU_SEQ_SVH

// control event applied BEFORE the request at this step
localparam int unsigned EV_NONE      = 0;
localparam int unsigned EV_FLUSH_TLB = 1;
localparam int unsigned EV_FLUSH_MID = 2;  // pulse flush_i with a walk in flight
localparam int unsigned EV_BARE_ON   = 3;
localparam int unsigned EV_BARE_OFF  = 4;

// PMP configurations the sequence selects between. A8 puts PMP in the walk path,
// so these change what a walk is permitted to read, not just the final address.
localparam int unsigned PMP_ALL   = 0;  // NAPOT over everything, RWX -- the default
localparam int unsigned PMP_NONE  = 1;  // no region configured at all -> deny
localparam int unsigned PMP_NOX   = 2;  // NAPOT over everything, RW but not X

typedef struct packed {
  logic [63:0] va;
  logic        is_store;
  logic [2:0]  ev;
  logic        is_fetch;   // 0 = load/store port, 1 = instruction fetch port
  // MACHINE STATE applied before the request. Every pre-existing step carries the
  // values the sequence used before these fields existed, so adding them changes
  // no recorded behaviour -- verified by re-capturing and comparing the metrics.
  logic [1:0]  priv;       // priv_lvl_i and ld_st_priv_lvl_i together
  logic        sum;
  logic        mxr;
  logic [15:0] asid;
  logic [1:0]  pmp;
} step_t;

// the defaults every pre-existing step carries
`define DFLT 2'b00, 1'b0, 1'b0, 16'd0, PMP_ALL[1:0]

localparam logic [63:0] SEQ_BASE  = 64'h0000_0000_8000_0000;  // 4 KiB leaves
localparam logic [63:0] SEQ_SUPER = 64'h0000_0000_4000_0001;  // 1 GiB superpage
localparam logic [63:0] SEQ_INVAL = 64'h0000_0000_C000_0000;  // V=0 PTE
localparam logic [63:0] SEQ_NOU   = 64'h0000_0000_0000_0000;  // leaf without U
localparam logic [63:0] SEQ_BARE  = 64'h0000_0000_DEAD_B000;  // bare-mode passthrough
localparam logic [63:0] SEQ_ANOA  = 64'h0000_0001_0000_0000;  // leaf with A=0
localparam logic [63:0] SEQ_DNOD  = 64'h0000_0001_4000_0000;  // leaf A=1 D=0
localparam logic [63:0] SEQ_GLOB  = 64'h0000_0001_8000_0000;  // GLOBAL leaf, G=1
localparam logic [63:0] SEQ_XONLY = 64'h0000_0001_C000_0000;  // execute-only leaf

// D side: 7 functional + 2 bare + 2 flush + 16 fill + 16 replay + 1 + 17 replay
//          + 48 reuse + 9 tail                                          = 118
// I side: 7 functional + 32 hit-interleaved fill + 16 replay + 2 + 17    =  74
// PMP (A6 causes 1/5/7, A7 no-matching-region)                          =   5
// privilege, SUM and MXR (A4)                                           =   6
// ASID and global pages (A10)                                           =   4
//                                                                  total 207
// Counted, not estimated; the phase boundaries below index into this and are
// wrong by one if the arithmetic is.
localparam int unsigned NSTEP = 207;

function automatic void build_sequence(ref step_t s [0:NSTEP-1]);
  int k;
  begin
    k = 0;
    // ---- phase 1: the functional cases, 7 requests ----
    s[k++] = '{SEQ_BASE,  1'b0, EV_NONE[2:0], 1'b0, `DFLT};       // cold three-level walk
    s[k++] = '{SEQ_BASE,  1'b0, EV_NONE[2:0], 1'b0, `DFLT};       // same page, must hit
    s[k++] = '{SEQ_SUPER, 1'b0, EV_NONE[2:0], 1'b0, `DFLT};       // 1 GiB superpage
    s[k++] = '{SEQ_INVAL, 1'b0, EV_NONE[2:0], 1'b0, `DFLT};       // invalid PTE -> fault
    s[k++] = '{SEQ_NOU,   1'b0, EV_NONE[2:0], 1'b0, `DFLT};       // no U bit in U mode -> fault
    s[k++] = '{SEQ_ANOA,  1'b0, EV_NONE[2:0], 1'b0, `DFLT};       // A=0 -> fault, no PTE write
    s[k++] = '{SEQ_DNOD,  1'b1, EV_NONE[2:0], 1'b0, `DFLT};       // store, D=0 -> fault

    // ---- phase 2: bare mode, in and out ----
    s[k++] = '{SEQ_BARE,  1'b0, EV_BARE_ON[2:0], 1'b0, `DFLT};
    s[k++] = '{SEQ_BASE,  1'b0, EV_BARE_OFF[2:0], 1'b0, `DFLT};

    // ---- phase 3: flush and refill, then a mid-walk abort ----
    s[k++] = '{SEQ_BASE,  1'b0, EV_FLUSH_TLB[2:0], 1'b0, `DFLT};  // flushed, must re-walk
    // A PAGE THAT IS NOT RESIDENT, and that is the whole point. This step used
    // SEQ_BASE, which the step before it had just installed -- so the request hit
    // the TLB and retired in ONE cycle, and the flush_i pulse arrived three
    // cycles later with nothing in flight to abort. C3's abort-and-restart and
    // T5's cancelled-request check were both unexercised while a schedule-derived
    // coverage flag reported them covered, because a step carrying the event
    // existed. See F75. Page 18 is planted and untouched by every other phase.
    s[k++] = '{SEQ_BASE + 18*4096, 1'b0, EV_FLUSH_MID[2:0], 1'b0, `DFLT};

    // ---- phase 4: T4 capacity -- fill 16 distinct pages ----
    for (int i = 0; i < 16; i++) s[k++] = '{SEQ_BASE + i*4096, 1'b0, EV_FLUSH_TLB[2:0], 1'b0, `DFLT};
    // only the first of the fill carries the flush; clear the rest
    for (int i = 1; i < 16; i++) s[11+i].ev = EV_NONE[2:0];

    // ---- phase 5: T4 replay -- all 16 must be resident, no PTE read ----
    for (int i = 0; i < 16; i++) s[k++] = '{SEQ_BASE + i*4096, 1'b0, EV_NONE[2:0], 1'b0, `DFLT};

    // ---- phase 6: the 17th page, then replay 17 -- at least one must miss ----
    s[k++] = '{SEQ_BASE + 16*4096, 1'b0, EV_NONE[2:0], 1'b0, `DFLT};
    for (int i = 0; i < 17; i++) s[k++] = '{SEQ_BASE + i*4096, 1'b0, EV_NONE[2:0], 1'b0, `DFLT};

    // ---- phase 7: reuse passes. THIS is what makes the cycle axis bite. ----
    for (int p = 0; p < 3; p++)
      for (int i = 0; i < 16; i++) s[k++] = '{SEQ_BASE + i*4096, 1'b0, EV_NONE[2:0], 1'b0, `DFLT};
    for (int i = 0; i < 9; i++)  s[k++] = '{SEQ_BASE + i*4096, 1'b0, EV_NONE[2:0], 1'b0, `DFLT};

    // ---- phase 8: the INSTRUCTION port, 7 requests ----
    // The SEQ_BASE leaves are planted X=1 U=1, so a U-mode fetch through them
    // translates; SEQ_NOU has U=0 and SEQ_INVAL has V=0, so both fault with
    // cause 12. No page-table change was needed to reach any of this, which is
    // part of why the gap went unnoticed -- nothing had to be built to close it.
    s[k++] = '{SEQ_BASE,  1'b0, EV_NONE[2:0],     1'b1, `DFLT};  // cold three-level walk
    s[k++] = '{SEQ_BASE,  1'b0, EV_NONE[2:0],     1'b1, `DFLT};  // same page, must hit
    s[k++] = '{SEQ_SUPER, 1'b0, EV_NONE[2:0],     1'b1, `DFLT};  // 1 GiB superpage
    s[k++] = '{SEQ_NOU,   1'b0, EV_NONE[2:0],     1'b1, `DFLT};  // no U in U mode -> 12
    s[k++] = '{SEQ_INVAL, 1'b0, EV_NONE[2:0],     1'b1, `DFLT};  // invalid PTE   -> 12
    s[k++] = '{SEQ_BARE,  1'b0, EV_BARE_ON[2:0],  1'b1, `DFLT};  // C1 on the I side
    s[k++] = '{SEQ_BASE,  1'b0, EV_BARE_OFF[2:0], 1'b1, `DFLT};

    // ---- phase 9: capacity on the INSTRUCTION TLB, HIT-INTERLEAVED fill ----
    // Every install is followed immediately by a re-touch of the same page, and
    // that detail is what makes the check possible at all. The anchor's
    // replacement tree advances only on lu_hit & lu_access (cva6_tlb.sv:436),
    // never on an install, so a COLD fill of 16 distinct pages leaves all
    // sixteen in ONE entry and the reference retains 1. With the re-touch it
    // retains all 16, and 17 pages thrash it to 15. Measured both ways in
    // tb/audit/probe_capacity_tb.sv; the data side reaches 16 either way because
    // its own phases are preceded by eleven hit-generating requests.
    //
    // The re-touch also widens which policies pass rather than narrowing it: the
    // anchor's PLRU-on-hit and a prefer-invalid-then-round-robin policy both
    // retain 16 here, and those are two genuinely different policies (rule 29).
    for (int i = 0; i < 16; i++) begin
      s[k++] = '{SEQ_BASE + i*4096, 1'b0, EV_NONE[2:0], 1'b1, `DFLT};   // install
      s[k++] = '{SEQ_BASE + i*4096, 1'b0, EV_NONE[2:0], 1'b1, `DFLT};   // re-touch, hits
    end
    s[I4_FILL_LO].ev = EV_FLUSH_TLB[2:0];      // only the first of the fill flushes
    for (int i = 0; i < 16; i++) s[k++] = '{SEQ_BASE + i*4096, 1'b0, EV_NONE[2:0], 1'b1, `DFLT};
    s[k++] = '{SEQ_BASE + 16*4096, 1'b0, EV_NONE[2:0], 1'b1, `DFLT};    // 17th, install
    s[k++] = '{SEQ_BASE + 16*4096, 1'b0, EV_NONE[2:0], 1'b1, `DFLT};    // 17th, re-touch
    for (int i = 0; i < 17; i++) s[k++] = '{SEQ_BASE + i*4096, 1'b0, EV_NONE[2:0], 1'b1, `DFLT};

    // ---- phase 10: PHYSICAL MEMORY PROTECTION, 5 requests ----
    // A6 pins causes 1, 5 and 7 longhand and nothing reached any of them: pmpcfg
    // and pmpaddr were frozen at one permitting region for the whole sequence.
    // A7's "with no PMP region matching" described a configuration the sequence
    // never visited.
    s[k++] = '{SEQ_BASE, 1'b0, EV_NONE[2:0], 1'b0, 2'b00,1'b0,1'b0,16'd0, PMP_NONE[1:0]};  // load  -> 5
    s[k++] = '{SEQ_BASE, 1'b1, EV_NONE[2:0], 1'b0, 2'b00,1'b0,1'b0,16'd0, PMP_NONE[1:0]};  // store -> 7
    s[k++] = '{SEQ_BASE, 1'b0, EV_NONE[2:0], 1'b1, 2'b00,1'b0,1'b0,16'd0, PMP_NONE[1:0]};  // fetch -> 1
    s[k++] = '{SEQ_BASE, 1'b0, EV_NONE[2:0], 1'b1, 2'b00,1'b0,1'b0,16'd0, PMP_NOX[1:0]};   // X denied -> 1
    s[k++] = '{SEQ_BASE, 1'b0, EV_NONE[2:0], 1'b0, `DFLT};                                 // restored

    // ---- phase 11: PRIVILEGE, SUM and MXR, 6 requests ----
    // priv_lvl_i, ld_st_priv_lvl_i, sum_i and mxr_i were all frozen, so every
    // supervisor-mode rule in A4 was unexercised.
    s[k++] = '{SEQ_BASE,  1'b0, EV_NONE[2:0], 1'b0, 2'b01,1'b0,1'b0,16'd0, PMP_ALL[1:0]}; // S, U=1, sum=0 -> 13
    s[k++] = '{SEQ_BASE,  1'b0, EV_NONE[2:0], 1'b0, 2'b01,1'b1,1'b0,16'd0, PMP_ALL[1:0]}; // S, U=1, sum=1 -> ok
    s[k++] = '{SEQ_BASE,  1'b0, EV_NONE[2:0], 1'b1, 2'b01,1'b1,1'b0,16'd0, PMP_ALL[1:0]}; // S fetch U=1 -> 12
    s[k++] = '{SEQ_NOU,   1'b0, EV_NONE[2:0], 1'b0, 2'b01,1'b0,1'b0,16'd0, PMP_ALL[1:0]}; // S, U=0 -> ok
    s[k++] = '{SEQ_XONLY, 1'b0, EV_NONE[2:0], 1'b0, 2'b00,1'b0,1'b0,16'd0, PMP_ALL[1:0]}; // load X-only mxr=0 -> 13
    s[k++] = '{SEQ_XONLY, 1'b0, EV_NONE[2:0], 1'b0, 2'b00,1'b0,1'b1,16'd0, PMP_ALL[1:0]}; // mxr=1 -> ok

    // ---- phase 12: ASID and GLOBAL pages, 4 requests ----
    s[k++] = '{SEQ_GLOB, 1'b0, EV_FLUSH_TLB[2:0], 1'b0, 2'b00,1'b0,1'b0,16'd1, PMP_ALL[1:0]};
    s[k++] = '{SEQ_BASE, 1'b0, EV_NONE[2:0],      1'b0, 2'b00,1'b0,1'b0,16'd1, PMP_ALL[1:0]};
    s[k++] = '{SEQ_GLOB, 1'b0, EV_NONE[2:0],      1'b0, 2'b00,1'b0,1'b0,16'd2, PMP_ALL[1:0]}; // global: hits
    s[k++] = '{SEQ_BASE, 1'b0, EV_NONE[2:0],      1'b0, 2'b00,1'b0,1'b0,16'd2, PMP_ALL[1:0]}; // ASID 1: misses
  end
endfunction

// Phase boundaries, for the T4 assertions.
localparam int unsigned T4_FILL_LO   = 11;        // first of the 16-page fill
localparam int unsigned T4_REPLAY_LO = 27;        // first of the 16-page replay
localparam int unsigned T4_REPLAY_HI = 42;        // last of it
localparam int unsigned T4_17TH      = 43;        // the 17th distinct page
localparam int unsigned T4_R17_LO    = 44;        // first of the 17-page replay
localparam int unsigned T4_R17_HI    = 60;        // last of it

// and the same four phases on the INSTRUCTION TLB, added in sequence D
localparam int unsigned I4_FILL_LO   = 125;   // 16 installs, each with a re-touch
localparam int unsigned I4_REPLAY_LO = 157;
localparam int unsigned I4_REPLAY_HI = 172;
localparam int unsigned I4_17TH      = 173;   // and 174, its re-touch
localparam int unsigned I4_R17_LO    = 175;
localparam int unsigned I4_R17_HI    = 191;

// A10's two mem-activity checks. Like T4 and T9 these read the PRESENCE of a
// page-table read rather than a scored output, because with one page table
// serving every ASID a stale non-global entry returns the SAME translation --
// so ASID correctness is not observable on the T1 surface at all, only in
// whether the unit re-walked.
localparam int unsigned A10_GLOB_HIT     = 205;   // global page, new ASID: 0 reads
localparam int unsigned A10_NONGLOB_MISS = 206;   // non-global, new ASID: >0 reads

// One record per request: the stimulus, then what the reference delivered.
typedef struct packed {
  logic [63:0] va;
  logic        is_store;
  logic [2:0]  ev;
  logic        is_fetch;
  logic [1:0]  priv;
  logic        sum;
  logic        mxr;
  logic [15:0] asid;
  logic [1:0]  pmp;
  logic        valid;
  logic [55:0] paddr;
  logic        exc_valid;
  logic [63:0] exc_cause;
} rec_t;

localparam int unsigned REC_W = $bits(rec_t);

// The page table both rigs plant. Identical contents or the vectors mean nothing.
// G IS AN ARGUMENT NOW. It used to be hardcoded 1'b0, so no planted entry was
// ever global and A10's "a leaf with G=1 is valid for every ASID" was
// unexercised in both halves -- see F72.
function automatic logic [63:0] mk_pte(input logic [43:0] ppn,
                                       input bit v, r, w, x, u, a, d, g = 1'b0);
  return {10'd0, ppn, 2'd0, d, a, g, u, x, w, r, v};
endfunction

`endif
