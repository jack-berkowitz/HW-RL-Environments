// =============================================================================
// v_ca05 MUTANT SET -- these VIOLATE the specification and MUST BE KILLED.
// =============================================================================
// Opposite sign to conformant/: those satisfy the spec and must survive. A
// submitted testbench is graded on killing these; a failure to kill is a weak
// testbench, where a failure to accept a conformant perturbation is an
// incomplete spec.
//
// Every mutant WRAPS the unmodified golden with one thing changed (CONVENTIONS:
// mutants perturb the anchor, they do not reimplement it), so anything a
// testbench observes is the injected defect and nothing else. A hand-written
// queue would fail for incidental reasons and isolate nothing.
//
// The wrapper presents itself as `tag_tracker` and delegates to
// `tag_tracker_golden`; the harness does the renaming. Same mechanism as the
// conformant set.
//
// CLASSES, per the verification build prompt:
//   m1 boundary   -- off-by-one at full
//   m2 ordering   -- LIFO within a tag; global behaviour still looks right
//   m3 capability -- correct on every transaction, a fraction of the capacity
//   m4 liveness   -- starvation of one tag, not a deadlock
//   m5 data       -- search misses on a masked compare
//   m6 boundary   -- empty/full flags correct except at exactly one occupancy
// =============================================================================
`timescale 1ns/1ps

// -----------------------------------------------------------------------------
// m1 -- BOUNDARY. Accepts SLOTS-1 entries and then refuses, so `full_o` asserts
// one entry early. Violates R1 (the design shall accept SLOTS entries).
// Kills any testbench that fills to capacity and counts.
// -----------------------------------------------------------------------------
module tt_m1_capacity_off_by_one #(
    parameter int TAG_W=0, parameter int SLOTS=0, parameter bit FULL_RATE=0,
    parameter bit CUT_POP_PATH=0, parameter int N_MATCH=1,
    parameter type payload_t=logic[31:0], localparam type tag_t=logic[TAG_W-1:0]
)(input logic clk_i, rst_ni, input tag_t push_tag_i, input payload_t push_data_i,
  input logic push_req_i, output logic push_gnt_o,
  input payload_t [N_MATCH-1:0] match_data_i, match_mask_i,
  input logic [N_MATCH-1:0] match_req_i, output logic [N_MATCH-1:0] match_hit_o, match_gnt_o,
  input tag_t pop_tag_i, input logic pop_en_i, pop_req_i,
  output payload_t pop_data_o, output logic pop_data_valid_o, pop_gnt_o,
  output logic full_o, empty_o);

    int unsigned occ;
    logic inner_push_gnt, block;
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) occ <= 0;
        else begin
            if (push_req_i && push_gnt_o)                       occ <= occ + 1;
            if (pop_req_i && pop_gnt_o && pop_en_i && pop_data_valid_o) occ <= occ - 1;
        end
    end
    assign block = (occ >= SLOTS - 1);          // INJECTED: one too early

    tag_tracker_golden #(.TAG_W(TAG_W), .SLOTS(SLOTS), .FULL_RATE(FULL_RATE),
        .CUT_POP_PATH(CUT_POP_PATH), .N_MATCH(N_MATCH), .payload_t(payload_t)) u (
        .clk_i, .rst_ni, .push_tag_i, .push_data_i,
        .push_req_i(push_req_i & ~block), .push_gnt_o(inner_push_gnt),
        .match_data_i, .match_mask_i, .match_req_i, .match_hit_o, .match_gnt_o,
        .pop_tag_i, .pop_en_i, .pop_req_i, .pop_data_o, .pop_data_valid_o,
        .pop_gnt_o, .full_o(), .empty_o);
    assign push_gnt_o = inner_push_gnt & ~block;
    assign full_o     = block;
endmodule


// -----------------------------------------------------------------------------
// m2 -- ORDERING. Returns the NEWEST entry for a tag instead of the oldest.
// Violates R2 (per-tag FIFO order). Counts, flags and capacity are all correct,
// so only a testbench that checks WHICH value comes back catches it.
//
// Implemented by keeping a shadow copy of what was pushed per tag and
// presenting the newest on pop_data_o. The golden still owns all control.
// -----------------------------------------------------------------------------
module tt_m2_lifo_within_tag #(
    parameter int TAG_W=0, parameter int SLOTS=0, parameter bit FULL_RATE=0,
    parameter bit CUT_POP_PATH=0, parameter int N_MATCH=1,
    parameter type payload_t=logic[31:0], localparam type tag_t=logic[TAG_W-1:0]
)(input logic clk_i, rst_ni, input tag_t push_tag_i, input payload_t push_data_i,
  input logic push_req_i, output logic push_gnt_o,
  input payload_t [N_MATCH-1:0] match_data_i, match_mask_i,
  input logic [N_MATCH-1:0] match_req_i, output logic [N_MATCH-1:0] match_hit_o, match_gnt_o,
  input tag_t pop_tag_i, input logic pop_en_i, pop_req_i,
  output payload_t pop_data_o, output logic pop_data_valid_o, pop_gnt_o,
  output logic full_o, empty_o);

    payload_t inner_data;
    payload_t newest [(1<<TAG_W)];
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) for (int i = 0; i < (1<<TAG_W); i++) newest[i] <= '0;
        else if (push_req_i && push_gnt_o)     newest[push_tag_i] <= push_data_i;
    end

    tag_tracker_golden #(.TAG_W(TAG_W), .SLOTS(SLOTS), .FULL_RATE(FULL_RATE),
        .CUT_POP_PATH(CUT_POP_PATH), .N_MATCH(N_MATCH), .payload_t(payload_t)) u (
        .clk_i, .rst_ni, .push_tag_i, .push_data_i, .push_req_i, .push_gnt_o,
        .match_data_i, .match_mask_i, .match_req_i, .match_hit_o, .match_gnt_o,
        .pop_tag_i, .pop_en_i, .pop_req_i,
        .pop_data_o(inner_data), .pop_data_valid_o, .pop_gnt_o, .full_o, .empty_o);

    // INJECTED: newest rather than oldest
    assign pop_data_o = pop_data_valid_o ? newest[pop_tag_i] : inner_data;
endmodule


// -----------------------------------------------------------------------------
// m3 -- CAPABILITY. Every transaction is correct; the store holds SLOTS/2.
// This is the class that motivated the whole benchmark: a design that passes
// every functional check while carrying a fraction of the required capacity.
// Violates R1. A testbench that never fills to SLOTS cannot see it.
// -----------------------------------------------------------------------------
module tt_m3_half_capacity #(
    parameter int TAG_W=0, parameter int SLOTS=0, parameter bit FULL_RATE=0,
    parameter bit CUT_POP_PATH=0, parameter int N_MATCH=1,
    parameter type payload_t=logic[31:0], localparam type tag_t=logic[TAG_W-1:0]
)(input logic clk_i, rst_ni, input tag_t push_tag_i, input payload_t push_data_i,
  input logic push_req_i, output logic push_gnt_o,
  input payload_t [N_MATCH-1:0] match_data_i, match_mask_i,
  input logic [N_MATCH-1:0] match_req_i, output logic [N_MATCH-1:0] match_hit_o, match_gnt_o,
  input tag_t pop_tag_i, input logic pop_en_i, pop_req_i,
  output payload_t pop_data_o, output logic pop_data_valid_o, pop_gnt_o,
  output logic full_o, empty_o);

    int unsigned occ;
    logic inner_push_gnt, block;
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) occ <= 0;
        else begin
            if (push_req_i && push_gnt_o)                       occ <= occ + 1;
            if (pop_req_i && pop_gnt_o && pop_en_i && pop_data_valid_o) occ <= occ - 1;
        end
    end
    assign block = (occ >= (SLOTS / 2));         // INJECTED: half the capacity

    tag_tracker_golden #(.TAG_W(TAG_W), .SLOTS(SLOTS), .FULL_RATE(FULL_RATE),
        .CUT_POP_PATH(CUT_POP_PATH), .N_MATCH(N_MATCH), .payload_t(payload_t)) u (
        .clk_i, .rst_ni, .push_tag_i, .push_data_i,
        .push_req_i(push_req_i & ~block), .push_gnt_o(inner_push_gnt),
        .match_data_i, .match_mask_i, .match_req_i, .match_hit_o, .match_gnt_o,
        .pop_tag_i, .pop_en_i, .pop_req_i, .pop_data_o, .pop_data_valid_o,
        .pop_gnt_o, .full_o(), .empty_o);
    assign push_gnt_o = inner_push_gnt & ~block;
    assign full_o     = block;
endmodule


// -----------------------------------------------------------------------------
// m4 -- LIVENESS / STARVATION, not deadlock. Pushes to tag 0 are never granted;
// every other tag works perfectly and the store never wedges. Violates R1 (any
// distribution summing to SLOTS shall be accepted).
//
// Deliberately starvation rather than deadlock: a deadlock stops everything and
// any timeout catches it. This one only shows up if the testbench exercises
// tag 0 specifically and notices it makes no progress.
// -----------------------------------------------------------------------------
module tt_m4_tag0_starved #(
    parameter int TAG_W=0, parameter int SLOTS=0, parameter bit FULL_RATE=0,
    parameter bit CUT_POP_PATH=0, parameter int N_MATCH=1,
    parameter type payload_t=logic[31:0], localparam type tag_t=logic[TAG_W-1:0]
)(input logic clk_i, rst_ni, input tag_t push_tag_i, input payload_t push_data_i,
  input logic push_req_i, output logic push_gnt_o,
  input payload_t [N_MATCH-1:0] match_data_i, match_mask_i,
  input logic [N_MATCH-1:0] match_req_i, output logic [N_MATCH-1:0] match_hit_o, match_gnt_o,
  input tag_t pop_tag_i, input logic pop_en_i, pop_req_i,
  output payload_t pop_data_o, output logic pop_data_valid_o, pop_gnt_o,
  output logic full_o, empty_o);

    logic starve, inner_push_gnt;
    assign starve = (push_tag_i == '0);          // INJECTED

    tag_tracker_golden #(.TAG_W(TAG_W), .SLOTS(SLOTS), .FULL_RATE(FULL_RATE),
        .CUT_POP_PATH(CUT_POP_PATH), .N_MATCH(N_MATCH), .payload_t(payload_t)) u (
        .clk_i, .rst_ni, .push_tag_i, .push_data_i,
        .push_req_i(push_req_i & ~starve), .push_gnt_o(inner_push_gnt),
        .match_data_i, .match_mask_i, .match_req_i, .match_hit_o, .match_gnt_o,
        .pop_tag_i, .pop_en_i, .pop_req_i, .pop_data_o, .pop_data_valid_o,
        .pop_gnt_o, .full_o, .empty_o);
    assign push_gnt_o = inner_push_gnt & ~starve;
endmodule


// -----------------------------------------------------------------------------
// m5 -- DATA / SEARCH. The masked compare ignores the top byte, so a search
// whose mask covers bits [31:24] reports a hit it should not. Violates R12.
// Invisible to any testbench that only searches with a full or zero mask.
// -----------------------------------------------------------------------------
module tt_m5_match_ignores_high_byte #(
    parameter int TAG_W=0, parameter int SLOTS=0, parameter bit FULL_RATE=0,
    parameter bit CUT_POP_PATH=0, parameter int N_MATCH=1,
    parameter type payload_t=logic[31:0], localparam type tag_t=logic[TAG_W-1:0]
)(input logic clk_i, rst_ni, input tag_t push_tag_i, input payload_t push_data_i,
  input logic push_req_i, output logic push_gnt_o,
  input payload_t [N_MATCH-1:0] match_data_i, match_mask_i,
  input logic [N_MATCH-1:0] match_req_i, output logic [N_MATCH-1:0] match_hit_o, match_gnt_o,
  input tag_t pop_tag_i, input logic pop_en_i, pop_req_i,
  output payload_t pop_data_o, output logic pop_data_valid_o, pop_gnt_o,
  output logic full_o, empty_o);

    payload_t [N_MATCH-1:0] masked;
    always_comb
        for (int k = 0; k < N_MATCH; k++)
            masked[k] = match_mask_i[k] & ~(payload_t'(32'hFF00_0000));  // INJECTED

    tag_tracker_golden #(.TAG_W(TAG_W), .SLOTS(SLOTS), .FULL_RATE(FULL_RATE),
        .CUT_POP_PATH(CUT_POP_PATH), .N_MATCH(N_MATCH), .payload_t(payload_t)) u (
        .clk_i, .rst_ni, .push_tag_i, .push_data_i, .push_req_i, .push_gnt_o,
        .match_data_i, .match_mask_i(masked), .match_req_i,
        .match_hit_o, .match_gnt_o,
        .pop_tag_i, .pop_en_i, .pop_req_i, .pop_data_o, .pop_data_valid_o,
        .pop_gnt_o, .full_o, .empty_o);
endmodule


// -----------------------------------------------------------------------------
// m6 -- BOUNDARY on the status flags only. empty_o is correct everywhere except
// at exactly one entry, where it reads high. Violates R14. Storage, ordering
// and capacity are all untouched, so only a testbench that checks the flags
// against occupancy at every step catches it -- checking them at empty and at
// full is not enough.
// -----------------------------------------------------------------------------
module tt_m6_empty_wrong_at_one #(
    parameter int TAG_W=0, parameter int SLOTS=0, parameter bit FULL_RATE=0,
    parameter bit CUT_POP_PATH=0, parameter int N_MATCH=1,
    parameter type payload_t=logic[31:0], localparam type tag_t=logic[TAG_W-1:0]
)(input logic clk_i, rst_ni, input tag_t push_tag_i, input payload_t push_data_i,
  input logic push_req_i, output logic push_gnt_o,
  input payload_t [N_MATCH-1:0] match_data_i, match_mask_i,
  input logic [N_MATCH-1:0] match_req_i, output logic [N_MATCH-1:0] match_hit_o, match_gnt_o,
  input tag_t pop_tag_i, input logic pop_en_i, pop_req_i,
  output payload_t pop_data_o, output logic pop_data_valid_o, pop_gnt_o,
  output logic full_o, empty_o);

    int unsigned occ;
    logic inner_empty;
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) occ <= 0;
        else begin
            if (push_req_i && push_gnt_o)                       occ <= occ + 1;
            if (pop_req_i && pop_gnt_o && pop_en_i && pop_data_valid_o) occ <= occ - 1;
        end
    end

    tag_tracker_golden #(.TAG_W(TAG_W), .SLOTS(SLOTS), .FULL_RATE(FULL_RATE),
        .CUT_POP_PATH(CUT_POP_PATH), .N_MATCH(N_MATCH), .payload_t(payload_t)) u (
        .clk_i, .rst_ni, .push_tag_i, .push_data_i, .push_req_i, .push_gnt_o,
        .match_data_i, .match_mask_i, .match_req_i, .match_hit_o, .match_gnt_o,
        .pop_tag_i, .pop_en_i, .pop_req_i, .pop_data_o, .pop_data_valid_o,
        .pop_gnt_o, .full_o, .empty_o(inner_empty));

    assign empty_o = (occ == 1) ? 1'b1 : inner_empty;   // INJECTED
endmodule


// =============================================================================
// HARDER SET -- added after the first blind run on the sibling tasks.
// =============================================================================
// The six above gave no range: our reference and an independent author both
// caught all of them. These four target corners a competent testbench plausibly
// misses, and each targets a corner a CLAUSE NAMES.
// =============================================================================

// -----------------------------------------------------------------------------
// m7 -- PER-TAG CAP. Total capacity is the full SLOTS and every mixed
// distribution is accepted; a SINGLE tag is capped at SLOTS/2. Violates R1,
// which says any distribution summing to SLOTS shall be accepted "including
// SLOTS entries all carrying the same tag".
//
// A testbench that spreads its pushes over several tags -- the natural way to
// exercise a tagged store -- never reaches the clause R1 spells out.
// -----------------------------------------------------------------------------
module tt_m7_per_tag_cap #(
    parameter int TAG_W=0, parameter int SLOTS=0, parameter bit FULL_RATE=0,
    parameter bit CUT_POP_PATH=0, parameter int N_MATCH=1,
    parameter type payload_t=logic[31:0], localparam type tag_t=logic[TAG_W-1:0]
)(input logic clk_i, rst_ni, input tag_t push_tag_i, input payload_t push_data_i,
  input logic push_req_i, output logic push_gnt_o,
  input payload_t [N_MATCH-1:0] match_data_i, match_mask_i,
  input logic [N_MATCH-1:0] match_req_i, output logic [N_MATCH-1:0] match_hit_o, match_gnt_o,
  input tag_t pop_tag_i, input logic pop_en_i, pop_req_i,
  output payload_t pop_data_o, output logic pop_data_valid_o, pop_gnt_o,
  output logic full_o, empty_o);

    int unsigned tcnt [(1<<TAG_W)];
    logic inner_push_gnt, block;

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) for (int i = 0; i < (1<<TAG_W); i++) tcnt[i] <= 0;
        else begin
            if (push_req_i && push_gnt_o)                                tcnt[push_tag_i] <= tcnt[push_tag_i] + 1;
            if (pop_req_i && pop_gnt_o && pop_en_i && pop_data_valid_o)  tcnt[pop_tag_i]  <= tcnt[pop_tag_i]  - 1;
        end
    end
    assign block = (tcnt[push_tag_i] >= (SLOTS / 2));   // INJECTED: per-tag cap

    tag_tracker_golden #(.TAG_W(TAG_W), .SLOTS(SLOTS), .FULL_RATE(FULL_RATE),
        .CUT_POP_PATH(CUT_POP_PATH), .N_MATCH(N_MATCH), .payload_t(payload_t)) u (
        .clk_i, .rst_ni, .push_tag_i, .push_data_i,
        .push_req_i(push_req_i & ~block), .push_gnt_o(inner_push_gnt),
        .match_data_i, .match_mask_i, .match_req_i, .match_hit_o, .match_gnt_o,
        .pop_tag_i, .pop_en_i, .pop_req_i, .pop_data_o, .pop_data_valid_o,
        .pop_gnt_o, .full_o, .empty_o);
    assign push_gnt_o = inner_push_gnt & ~block;
endmodule


// -----------------------------------------------------------------------------
// m8 -- PEEK REMOVES, but only the last entry of a tag. Violates R9, which
// says an inspect with pop_en_i low leaves the entry in place.
//
// Every peek of a tag holding two or more entries behaves perfectly. Only the
// one-entry case is destructive, so a testbench that peeks a well-stocked tag
// and moves on sees nothing wrong.
// -----------------------------------------------------------------------------
module tt_m8_peek_removes_last #(
    parameter int TAG_W=0, parameter int SLOTS=0, parameter bit FULL_RATE=0,
    parameter bit CUT_POP_PATH=0, parameter int N_MATCH=1,
    parameter type payload_t=logic[31:0], localparam type tag_t=logic[TAG_W-1:0]
)(input logic clk_i, rst_ni, input tag_t push_tag_i, input payload_t push_data_i,
  input logic push_req_i, output logic push_gnt_o,
  input payload_t [N_MATCH-1:0] match_data_i, match_mask_i,
  input logic [N_MATCH-1:0] match_req_i, output logic [N_MATCH-1:0] match_hit_o, match_gnt_o,
  input tag_t pop_tag_i, input logic pop_en_i, pop_req_i,
  output payload_t pop_data_o, output logic pop_data_valid_o, pop_gnt_o,
  output logic full_o, empty_o);

    int unsigned tcnt [(1<<TAG_W)];
    logic force_en, eff_en;

    assign force_en = pop_req_i && !pop_en_i && (tcnt[pop_tag_i] == 1);  // INJECTED
    assign eff_en   = pop_en_i | force_en;

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) for (int i = 0; i < (1<<TAG_W); i++) tcnt[i] <= 0;
        else begin
            if (push_req_i && push_gnt_o)                                tcnt[push_tag_i] <= tcnt[push_tag_i] + 1;
            if (pop_req_i && pop_gnt_o && eff_en && pop_data_valid_o)     tcnt[pop_tag_i]  <= tcnt[pop_tag_i]  - 1;
        end
    end

    tag_tracker_golden #(.TAG_W(TAG_W), .SLOTS(SLOTS), .FULL_RATE(FULL_RATE),
        .CUT_POP_PATH(CUT_POP_PATH), .N_MATCH(N_MATCH), .payload_t(payload_t)) u (
        .clk_i, .rst_ni, .push_tag_i, .push_data_i, .push_req_i, .push_gnt_o,
        .match_data_i, .match_mask_i, .match_req_i, .match_hit_o, .match_gnt_o,
        .pop_tag_i, .pop_en_i(eff_en), .pop_req_i, .pop_data_o, .pop_data_valid_o,
        .pop_gnt_o, .full_o, .empty_o);
endmodule


// -----------------------------------------------------------------------------
// m9 -- A ZERO MASK MATCHES NOTHING. Violates R13, which states that a mask of
// all zeros matches every stored entry, so the search hits whenever the store
// is non-empty.
//
// R13 is a consequence of R12 rather than an independent rule, and it names the
// degenerate case explicitly -- which is exactly the case a testbench skips as
// uninteresting. Every non-zero mask behaves perfectly.
// -----------------------------------------------------------------------------
module tt_m9_zero_mask_no_hit #(
    parameter int TAG_W=0, parameter int SLOTS=0, parameter bit FULL_RATE=0,
    parameter bit CUT_POP_PATH=0, parameter int N_MATCH=1,
    parameter type payload_t=logic[31:0], localparam type tag_t=logic[TAG_W-1:0]
)(input logic clk_i, rst_ni, input tag_t push_tag_i, input payload_t push_data_i,
  input logic push_req_i, output logic push_gnt_o,
  input payload_t [N_MATCH-1:0] match_data_i, match_mask_i,
  input logic [N_MATCH-1:0] match_req_i, output logic [N_MATCH-1:0] match_hit_o, match_gnt_o,
  input tag_t pop_tag_i, input logic pop_en_i, pop_req_i,
  output payload_t pop_data_o, output logic pop_data_valid_o, pop_gnt_o,
  output logic full_o, empty_o);

    logic [N_MATCH-1:0] inner_hit;
    always_comb
        for (int k = 0; k < N_MATCH; k++)
            match_hit_o[k] = (match_mask_i[k] == '0) ? 1'b0 : inner_hit[k];  // INJECTED

    tag_tracker_golden #(.TAG_W(TAG_W), .SLOTS(SLOTS), .FULL_RATE(FULL_RATE),
        .CUT_POP_PATH(CUT_POP_PATH), .N_MATCH(N_MATCH), .payload_t(payload_t)) u (
        .clk_i, .rst_ni, .push_tag_i, .push_data_i, .push_req_i, .push_gnt_o,
        .match_data_i, .match_mask_i, .match_req_i,
        .match_hit_o(inner_hit), .match_gnt_o,
        .pop_tag_i, .pop_en_i, .pop_req_i, .pop_data_o, .pop_data_valid_o,
        .pop_gnt_o, .full_o, .empty_o);
endmodule


// -----------------------------------------------------------------------------
// m10 -- full_o ASSERTS ONE CYCLE LATE. Violates R14, which says full_o is high
// exactly when the store holds SLOTS. It deasserts correctly and it is right in
// the steady state; only the transition into full is a cycle behind.
//
// A testbench that fills the store and then samples the flag catches nothing --
// by the time it looks, the flag is right. It needs to check the flag against
// occupancy on the cycle the store becomes full.
// -----------------------------------------------------------------------------
module tt_m10_full_asserts_late #(
    parameter int TAG_W=0, parameter int SLOTS=0, parameter bit FULL_RATE=0,
    parameter bit CUT_POP_PATH=0, parameter int N_MATCH=1,
    parameter type payload_t=logic[31:0], localparam type tag_t=logic[TAG_W-1:0]
)(input logic clk_i, rst_ni, input tag_t push_tag_i, input payload_t push_data_i,
  input logic push_req_i, output logic push_gnt_o,
  input payload_t [N_MATCH-1:0] match_data_i, match_mask_i,
  input logic [N_MATCH-1:0] match_req_i, output logic [N_MATCH-1:0] match_hit_o, match_gnt_o,
  input tag_t pop_tag_i, input logic pop_en_i, pop_req_i,
  output payload_t pop_data_o, output logic pop_data_valid_o, pop_gnt_o,
  output logic full_o, empty_o);

    logic inner_full, full_q;
    always_ff @(posedge clk_i or negedge rst_ni)
        if (!rst_ni) full_q <= 1'b0;
        else         full_q <= inner_full;

    assign full_o = inner_full & full_q;      // INJECTED: rises a cycle late

    tag_tracker_golden #(.TAG_W(TAG_W), .SLOTS(SLOTS), .FULL_RATE(FULL_RATE),
        .CUT_POP_PATH(CUT_POP_PATH), .N_MATCH(N_MATCH), .payload_t(payload_t)) u (
        .clk_i, .rst_ni, .push_tag_i, .push_data_i, .push_req_i, .push_gnt_o,
        .match_data_i, .match_mask_i, .match_req_i, .match_hit_o, .match_gnt_o,
        .pop_tag_i, .pop_en_i, .pop_req_i, .pop_data_o, .pop_data_valid_o,
        .pop_gnt_o, .full_o(inner_full), .empty_o);
endmodule
