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
module tag_tracker #(
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

    // ---- mutant guard state: contract-level only -------------------------
    // Counted from the PORT handshakes alone -- occupancy, per-tag occupancy,
    // completed pushes, pops and searches, and how many times the store has
    // filled. Nothing inside the golden is read, so every guard can be
    // restated against an independent implementation of the same contract.
    int unsigned g_occ, g_push_q, g_pop_q, g_match_q, g_fullage_q, g_fullcnt_q;
    int unsigned g_tcnt [(1<<TAG_W)];
    logic        g_wasfull_q, g_everfull_q;
    function automatic int unsigned g_ntags();
        g_ntags = 0;
        for (int i = 0; i < (1<<TAG_W); i++) if (g_tcnt[i] != 0) g_ntags++;
    endfunction
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            g_occ <= 0; g_push_q <= 0; g_pop_q <= 0; g_match_q <= 0;
            g_fullage_q <= 0; g_fullcnt_q <= 0;
            g_wasfull_q <= 1'b0; g_everfull_q <= 1'b0;
            for (int i = 0; i < (1<<TAG_W); i++) g_tcnt[i] <= 0;
        end else begin
            if (push_req_i && push_gnt_o) begin
                g_occ <= g_occ + 1; g_push_q <= g_push_q + 1;
                g_tcnt[push_tag_i] <= g_tcnt[push_tag_i] + 1;
            end
            if (pop_req_i && pop_gnt_o && pop_en_i && pop_data_valid_o) begin
                g_occ <= g_occ - 1; g_pop_q <= g_pop_q + 1;
                g_tcnt[pop_tag_i] <= g_tcnt[pop_tag_i] - 1;
            end
            for (int k = 0; k < N_MATCH; k++)
                if (match_req_i[k] && match_gnt_o[k]) g_match_q <= g_match_q + 1;
            if (g_occ >= SLOTS) begin
                g_fullage_q <= g_fullage_q + 1;
                g_everfull_q <= 1'b1;
                if (!g_wasfull_q) g_fullcnt_q <= g_fullcnt_q + 1;
                g_wasfull_q <= 1'b1;
            end else begin
                g_fullage_q <= 0; g_wasfull_q <= 1'b0;
            end
        end
    end

    int unsigned occ;
    logic inner_push_gnt, block;
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) occ <= 0;
        else begin
            if (push_req_i && push_gnt_o)                       occ <= occ + 1;
            if (pop_req_i && pop_gnt_o && pop_en_i && pop_data_valid_o) occ <= occ - 1;
        end
    end
    // GUARD: three or more distinct tags are present.
    assign block = (occ >= (SLOTS / 2)) && (g_ntags() >= 3);

    tag_tracker_alt #(.TAG_W(TAG_W), .SLOTS(SLOTS), .FULL_RATE(FULL_RATE),
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
