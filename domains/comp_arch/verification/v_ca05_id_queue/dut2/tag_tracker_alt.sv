// =============================================================================
// tag_tracker_alt.sv -- SECOND DUT for v_ca05. Locally written.
// =============================================================================
// An independent implementation of spec/tag_tracker_spec.md, written from the
// specification and making different choices wherever it leaves one open.
//
// *** NOTHING IN THE HARNESS RUNS THIS. *** sim_verification.sh gates on the
// DECLARATION in task.yaml and never compiles or runs dut2/. Exercised only by
// running the reference testbench against it by hand.
//
// THE THREE DIFFERENCES (rule 5), named before writing:
//
//   1. STORAGE AND ORDERING. A flat array of SLOTS entries, each carrying a
//      monotonically increasing sequence number; the oldest entry for a tag is
//      the one with the smallest sequence number, found by a scan. The anchor
//      uses per-tag linked lists with head and tail pointers and a free list.
//      Internal, so licensed by latitude 5, and it is the axis where a shared
//      misconception about R2 would be most likely -- so it is built from the
//      specification's wording rather than from any pointer scheme.
//
//   2. push_gnt_o IS REQUEST-GATED. This design asserts push_gnt_o only when
//      push_req_i is high. *** THE ANCHOR DOES THE OPPOSITE *** -- its grant is
//      a space-available flag that is high with no request pending, which is
//      the single fact R4 exists to state and the one the pilot identified as
//      load-bearing. R6 licenses a grant being low for reasons other than
//      fullness, so both are legal. A testbench that learned "grant means space
//      is available" from the anchor's behaviour, or that counts grants as
//      commits, breaks here and passes there.
//
//   3. SAME-CYCLE PUSH AND POP OF ONE TAG. With FULL_RATE = 0 the two may not
//      complete together; this design resolves that by denying the push and
//      letting the pop proceed. The choice of which to deny is arbitration
//      policy, explicitly unconstrained by latitude 1.
// =============================================================================

module tag_tracker_alt #(
    parameter int TAG_W  = 0,
    parameter int SLOTS  = 0,
    parameter bit FULL_RATE    = 0,
    parameter bit CUT_POP_PATH = 0,
    parameter int N_MATCH = 1,
    parameter type payload_t   = logic[31:0],

    localparam type tag_t    = logic[TAG_W-1:0]
) (
    input  logic    clk_i,
    input  logic    rst_ni,

    input  tag_t     push_tag_i,
    input  payload_t   push_data_i,
    input  logic    push_req_i,
    output logic    push_gnt_o,

    input  payload_t [N_MATCH-1:0] match_data_i,
    input  payload_t [N_MATCH-1:0] match_mask_i,
    input  logic  [N_MATCH-1:0] match_req_i,
    output logic  [N_MATCH-1:0] match_hit_o,
    output logic  [N_MATCH-1:0] match_gnt_o,

    input  tag_t     pop_tag_i,
    input  logic    pop_en_i,
    input  logic    pop_req_i,
    output payload_t   pop_data_o,
    output logic    pop_data_valid_o,
    output logic    pop_gnt_o,

    output logic    full_o,
    output logic    empty_o
);

  localparam int SEQ_W = 32;

  // Difference 1: flat storage, ordering carried by a sequence number.
  logic             ent_v   [SLOTS];
  tag_t             ent_tag [SLOTS];
  payload_t         ent_pl  [SLOTS];
  logic [SEQ_W-1:0] ent_seq [SLOTS];

  logic [SEQ_W-1:0] seq_ctr;
  int unsigned      occupancy;

  // ---- oldest entry for pop_tag_i (R2, R8) ---------------------------------
  logic        pop_found;
  int unsigned pop_idx;

  always_comb begin
    pop_found = 1'b0;
    pop_idx   = 0;
    for (int s = 0; s < SLOTS; s++) begin
      if (ent_v[s] && ent_tag[s] == pop_tag_i) begin
        if (!pop_found || ent_seq[s] < ent_seq[pop_idx]) begin
          pop_found = 1'b1;
          pop_idx   = s;
        end
      end
    end
  end

  // ---- first free slot ------------------------------------------------------
  logic        free_found;
  int unsigned free_idx;

  always_comb begin
    free_found = 1'b0;
    free_idx   = 0;
    for (int s = SLOTS - 1; s >= 0; s--) begin
      if (!ent_v[s]) begin
        free_found = 1'b1;
        free_idx   = s;
      end
    end
  end

  // ---- outputs --------------------------------------------------------------
  // R7, R10: a pop always completes; an absent tag simply reports valid low.
  assign pop_gnt_o        = pop_req_i;
  assign pop_data_valid_o = pop_req_i & pop_found;
  assign pop_data_o       = pop_found ? ent_pl[pop_idx] : '0;

  // Difference 3: with FULL_RATE = 0, a push of the tag being popped this
  // cycle is denied and the pop proceeds (latitude 1).
  wire same_tag_conflict = (FULL_RATE == 0) && pop_req_i && pop_found
                        && (pop_tag_i == push_tag_i);

  // Difference 2: request-gated grant, the opposite of the anchor's
  // space-available flag. R6 licenses it.
  assign push_gnt_o = push_req_i && (occupancy < SLOTS) && !same_tag_conflict;

  assign full_o  = (occupancy == SLOTS);
  assign empty_o = (occupancy == 0);

  // ---- content-addressed search (R11, R12, R13) -----------------------------
  for (genvar k = 0; k < N_MATCH; k++) begin : g_match
    logic hit;
    always_comb begin
      hit = 1'b0;
      for (int s = 0; s < SLOTS; s++)
        if (ent_v[s] &&
            ((ent_pl[s] & match_mask_i[k]) == (match_data_i[k] & match_mask_i[k])))
          hit = 1'b1;
    end
    assign match_hit_o[k] = hit;
    assign match_gnt_o[k] = match_req_i[k];
  end

  // ---- state ----------------------------------------------------------------
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin                                   // R15
      for (int s = 0; s < SLOTS; s++) ent_v[s] <= 1'b0;
      seq_ctr   <= '0;
      occupancy <= 0;
    end else begin
      automatic logic did_pop  = pop_req_i && pop_found && pop_en_i;   // R9
      automatic logic did_push = push_gnt_o && push_req_i;             // R4

      if (did_pop)  ent_v[pop_idx] <= 1'b0;

      if (did_push && free_found) begin
        ent_v  [free_idx] <= 1'b1;
        ent_tag[free_idx] <= push_tag_i;
        ent_pl [free_idx] <= push_data_i;
        ent_seq[free_idx] <= seq_ctr;
        seq_ctr           <= seq_ctr + 1;
      end

      // A pop of the slot being reused in the same cycle cannot happen: the
      // free scan only returns invalid slots and did_pop clears a valid one.
      occupancy <= occupancy + (did_push ? 1 : 0) - (did_pop ? 1 : 0);
    end
  end

endmodule
