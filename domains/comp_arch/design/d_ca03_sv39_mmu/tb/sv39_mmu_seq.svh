// sv39_mmu_seq.svh -- d_ca03 SEQUENCE C, and the vector record layout.
//
// INCLUDED BY BOTH the capture rig (tb/audit/capture_vectors_tb.sv) and the
// scoring testbench. One definition, two readers: if the sequence lived
// separately in each, a silent divergence would present as a mismatch on every
// request, which is the most expensive kind of false signal to chase.
//
// SEQUENCE D, 175 requests. The mix is a SCORING CONSTRUCT, not a workload
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

typedef struct packed {
  logic [63:0] va;
  logic        is_store;
  logic [2:0]  ev;
  logic        is_fetch;   // 0 = load/store port, 1 = instruction fetch port
} step_t;

localparam logic [63:0] SEQ_BASE  = 64'h0000_0000_8000_0000;  // 4 KiB leaves
localparam logic [63:0] SEQ_SUPER = 64'h0000_0000_4000_0001;  // 1 GiB superpage
localparam logic [63:0] SEQ_INVAL = 64'h0000_0000_C000_0000;  // V=0 PTE
localparam logic [63:0] SEQ_NOU   = 64'h0000_0000_0000_0000;  // leaf without U
localparam logic [63:0] SEQ_BARE  = 64'h0000_0000_DEAD_B000;  // bare-mode passthrough
localparam logic [63:0] SEQ_ANOA  = 64'h0000_0001_0000_0000;  // leaf with A=0
localparam logic [63:0] SEQ_DNOD  = 64'h0000_0001_4000_0000;  // leaf A=1 D=0

// D side: 7 functional + 2 bare + 2 flush + 16 fill + 16 replay + 1 + 17 replay
//          + 48 reuse + 9 tail                                          = 118
// I side: 7 functional + 16 fill + 16 replay + 1 + 17 replay            =  57
//                                                                  total 175
// Counted, not estimated; the phase boundaries below index into this and are
// wrong by one if the arithmetic is.
localparam int unsigned NSTEP = 175;

function automatic void build_sequence(ref step_t s [0:NSTEP-1]);
  int k;
  begin
    k = 0;
    // ---- phase 1: the functional cases, 7 requests ----
    s[k++] = '{SEQ_BASE,  1'b0, EV_NONE[2:0], 1'b0};       // cold three-level walk
    s[k++] = '{SEQ_BASE,  1'b0, EV_NONE[2:0], 1'b0};       // same page, must hit
    s[k++] = '{SEQ_SUPER, 1'b0, EV_NONE[2:0], 1'b0};       // 1 GiB superpage
    s[k++] = '{SEQ_INVAL, 1'b0, EV_NONE[2:0], 1'b0};       // invalid PTE -> fault
    s[k++] = '{SEQ_NOU,   1'b0, EV_NONE[2:0], 1'b0};       // no U bit in U mode -> fault
    s[k++] = '{SEQ_ANOA,  1'b0, EV_NONE[2:0], 1'b0};       // A=0 -> fault, no PTE write
    s[k++] = '{SEQ_DNOD,  1'b1, EV_NONE[2:0], 1'b0};       // store, D=0 -> fault

    // ---- phase 2: bare mode, in and out ----
    s[k++] = '{SEQ_BARE,  1'b0, EV_BARE_ON[2:0], 1'b0};
    s[k++] = '{SEQ_BASE,  1'b0, EV_BARE_OFF[2:0], 1'b0};

    // ---- phase 3: flush and refill, then a mid-walk abort ----
    s[k++] = '{SEQ_BASE,  1'b0, EV_FLUSH_TLB[2:0], 1'b0};  // flushed, must re-walk
    s[k++] = '{SEQ_BASE,  1'b0, EV_FLUSH_MID[2:0], 1'b0};  // abort in flight, then serve

    // ---- phase 4: T4 capacity -- fill 16 distinct pages ----
    for (int i = 0; i < 16; i++) s[k++] = '{SEQ_BASE + i*4096, 1'b0, EV_FLUSH_TLB[2:0], 1'b0};
    // only the first of the fill carries the flush; clear the rest
    for (int i = 1; i < 16; i++) s[11+i].ev = EV_NONE[2:0];

    // ---- phase 5: T4 replay -- all 16 must be resident, no PTE read ----
    for (int i = 0; i < 16; i++) s[k++] = '{SEQ_BASE + i*4096, 1'b0, EV_NONE[2:0], 1'b0};

    // ---- phase 6: the 17th page, then replay 17 -- at least one must miss ----
    s[k++] = '{SEQ_BASE + 16*4096, 1'b0, EV_NONE[2:0], 1'b0};
    for (int i = 0; i < 17; i++) s[k++] = '{SEQ_BASE + i*4096, 1'b0, EV_NONE[2:0], 1'b0};

    // ---- phase 7: reuse passes. THIS is what makes the cycle axis bite. ----
    for (int p = 0; p < 3; p++)
      for (int i = 0; i < 16; i++) s[k++] = '{SEQ_BASE + i*4096, 1'b0, EV_NONE[2:0], 1'b0};
    for (int i = 0; i < 9; i++)  s[k++] = '{SEQ_BASE + i*4096, 1'b0, EV_NONE[2:0], 1'b0};

    // ---- phase 8: the INSTRUCTION port, 7 requests ----
    // The SEQ_BASE leaves are planted X=1 U=1, so a U-mode fetch through them
    // translates; SEQ_NOU has U=0 and SEQ_INVAL has V=0, so both fault with
    // cause 12. No page-table change was needed to reach any of this, which is
    // part of why the gap went unnoticed -- nothing had to be built to close it.
    s[k++] = '{SEQ_BASE,  1'b0, EV_NONE[2:0],     1'b1};  // cold three-level walk
    s[k++] = '{SEQ_BASE,  1'b0, EV_NONE[2:0],     1'b1};  // same page, must hit
    s[k++] = '{SEQ_SUPER, 1'b0, EV_NONE[2:0],     1'b1};  // 1 GiB superpage
    s[k++] = '{SEQ_NOU,   1'b0, EV_NONE[2:0],     1'b1};  // no U in U mode -> 12
    s[k++] = '{SEQ_INVAL, 1'b0, EV_NONE[2:0],     1'b1};  // invalid PTE   -> 12
    s[k++] = '{SEQ_BARE,  1'b0, EV_BARE_ON[2:0],  1'b1};  // C1 on the I side
    s[k++] = '{SEQ_BASE,  1'b0, EV_BARE_OFF[2:0], 1'b1};

    // ---- phase 9: T4 on the INSTRUCTION TLB, same shape as phases 4-6 ----
    for (int i = 0; i < 16; i++) s[k++] = '{SEQ_BASE + i*4096, 1'b0, EV_FLUSH_TLB[2:0], 1'b1};
    for (int i = 1; i < 16; i++) s[I4_FILL_LO+i].ev = EV_NONE[2:0];
    for (int i = 0; i < 16; i++) s[k++] = '{SEQ_BASE + i*4096, 1'b0, EV_NONE[2:0], 1'b1};
    s[k++] = '{SEQ_BASE + 16*4096, 1'b0, EV_NONE[2:0], 1'b1};
    for (int i = 0; i < 17; i++) s[k++] = '{SEQ_BASE + i*4096, 1'b0, EV_NONE[2:0], 1'b1};
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
localparam int unsigned I4_FILL_LO   = 125;
localparam int unsigned I4_REPLAY_LO = 141;
localparam int unsigned I4_REPLAY_HI = 156;
localparam int unsigned I4_17TH      = 157;
localparam int unsigned I4_R17_LO    = 158;
localparam int unsigned I4_R17_HI    = 174;

// One record per request: the stimulus, then what the reference delivered.
typedef struct packed {
  logic [63:0] va;
  logic        is_store;
  logic [2:0]  ev;
  logic        is_fetch;
  logic        valid;
  logic [55:0] paddr;
  logic        exc_valid;
  logic [63:0] exc_cause;
} rec_t;

localparam int unsigned REC_W = $bits(rec_t);

// The page table both rigs plant. Identical contents or the vectors mean nothing.
function automatic logic [63:0] mk_pte(input logic [43:0] ppn,
                                       input bit v, r, w, x, u, a, d);
  return {10'd0, ppn, 2'd0, d, a, 1'b0, u, x, w, r, v};
endfunction

`endif
