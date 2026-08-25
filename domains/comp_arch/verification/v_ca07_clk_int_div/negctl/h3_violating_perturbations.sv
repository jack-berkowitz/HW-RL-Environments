// ---------------------------------------------------------------------------
// NEGATIVE CONTROLS -- and the strongest two this task has, because neither was
// BUILT to be caught.
//
// These are the FIRST DRAFTS of conformant perturbations c1 and c3, preserved
// verbatim. Both were written as legal variants, exercising the latitude L3 and
// L2 genuinely leave free: c1 throttles when div_ready_o may rise, c3 gates the
// output for longer across a change. Both were wrong, in the same way and for
// the same reason -- the latitude they turn is the timing of a REAL change, and
// neither draft distinguished a real change from a request for the value already
// in force, so both broke H3, which pins the same-value case to a same-cycle
// grant with no gating.
//
// The reference refused both. It was written to accept legal variants and it
// rejected two artefacts constructed to be legal, on the clause they actually
// broke rather than by timing out or by noticing a difference from the anchor.
// A gate mutant with every output tied high demonstrates a floor; this
// demonstrates DISCRIMINATION, and it cost nothing to obtain because the two
// mistakes were already made.
//
// The shipped c1 and c3 are the corrected versions, which track div_q from the
// handshake and leave a same-value request untouched. They pass.
// ---------------------------------------------------------------------------

// c1's first draft: the accept window applied to EVERY request, including one
// for the value already in force.
module h3_nc1_throttle_hits_same_value (
  input  logic       clk_i,
  input  logic       rst_ni,
  input  logic       en_i,
  input  logic       test_mode_en_i,
  input  logic [3:0] div_i,
  input  logic       div_valid_i,
  output logic       div_ready_o,
  output logic       clk_o,
  output logic [3:0] cycl_count_o
);
  logic [3:0] tick;
  always_ff @(posedge clk_i or negedge rst_ni)
    if (!rst_ni) tick <= '0; else tick <= tick + 4'd1;
  wire win = tick[2];                 // no is_same term -- this is the defect
  logic g_ready;
  assign div_ready_o = g_ready & win;
  clk_ratio_div_golden i_g (
    .clk_i, .rst_ni, .en_i, .test_mode_en_i,
    .div_i,
    .div_valid_i (div_valid_i & win),
    .div_ready_o (g_ready),
    .clk_o, .cycl_count_o
  );
endmodule

// c3's first draft: the extra gating applied to EVERY accepted handshake,
// including a same-value one, which H3 says is not gated at all.
module h3_nc2_extra_gating_hits_same_value (
  input  logic       clk_i,
  input  logic       rst_ni,
  input  logic       en_i,
  input  logic       test_mode_en_i,
  input  logic [3:0] div_i,
  input  logic       div_valid_i,
  output logic       div_ready_o,
  output logic       clk_o,
  output logic [3:0] cycl_count_o
);
  logic g_clk;
  logic accepted, hold_q, hold_n;
  assign accepted = div_valid_i & div_ready_o;    // no ~is_same -- the defect
  always_ff @(posedge clk_i or negedge rst_ni)
    if (!rst_ni) hold_q <= 1'b0; else hold_q <= accepted;
  always_ff @(negedge clk_i or negedge rst_ni)
    if (!rst_ni) hold_n <= 1'b0; else hold_n <= hold_q | accepted;
  assign clk_o = g_clk & ~hold_n;
  clk_ratio_div_golden i_g (
    .clk_i, .rst_ni, .en_i, .test_mode_en_i,
    .div_i, .div_valid_i, .div_ready_o,
    .clk_o (g_clk), .cycl_count_o
  );
endmodule
