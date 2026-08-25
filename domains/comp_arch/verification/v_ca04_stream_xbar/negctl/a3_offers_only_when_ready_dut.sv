// ---------------------------------------------------------------------------
// SUPPRESSING CONTROL for A3's vacuity question.
//
// NOT a mutant, and not a positive control either. It gates out_valid_o on
// out_ready_i, so an offer is never held against a stalled sink and A3 --
// "once out_valid_o[j] is asserted it stays asserted ... until out_ready_i[j]
// is seen" -- HAS NO CYCLE TO BE JUDGED ON. A3's consequent is never violated
// because its antecedent is never entered.
//
// Nothing in the contract objects. There is no clause forbidding out_valid_o
// from depending combinationally on out_ready_i, which is the same hole
// AGENT-DESIGN-43a92055 found on d_dsp02's H3 -- the identical clause shape on
// a different bus, and the first evidence it is a class rather than one task's
// oversight.
//
// WHAT THIS CONTROL ESTABLISHES, and it is two things that must not be
// conflated:
//
//   it PASSES              -> the evasion is conforming, so A3 is
//                             UNFALSIFIABLE and needs a mirror clause
//   cov_a3_held reads 0    -> it actually SUPPRESSED, so the pass is evidence
//
// A suppressing control that passes WITHOUT the zero proves nothing: its two
// arms produce the same observable. That is not hypothetical -- the first
// suppressing control written on v_ca07 passed and did not suppress, and would
// have confirmed a vacuity claim it had no bearing on.
//
// The counter is NAMED here rather than left as "a zero was observed", per the
// control-enumeration contract: h3_guard_true == 0 and cov_a3_held == 0 are
// different facts and a record that says only "zero" cannot tell them apart.
// ---------------------------------------------------------------------------
module route_xbar #(
  parameter int unsigned N_IN    = 4,
  parameter int unsigned N_OUT   = 4,
  parameter int unsigned DATA_W  = 32,
  parameter int unsigned SEL_W   = 2,
  parameter int unsigned IDX_W   = 2
) (
  input  logic                       clk_i,
  input  logic                       rst_ni,
  input  logic [N_IN*DATA_W-1:0]     in_data_i,
  input  logic [N_IN*SEL_W-1:0]      in_sel_i,
  input  logic [N_IN-1:0]            in_valid_i,
  output logic [N_IN-1:0]            in_ready_o,
  output logic [N_OUT*DATA_W-1:0]    out_data_o,
  output logic [N_OUT*IDX_W-1:0]     out_idx_o,
  output logic [N_OUT-1:0]           out_valid_o,
  input  logic [N_OUT-1:0]           out_ready_i
);
  logic [N_OUT-1:0] g_valid;
  route_xbar_golden #(.N_IN(N_IN), .N_OUT(N_OUT), .DATA_W(DATA_W),
                      .SEL_W(SEL_W), .IDX_W(IDX_W)) i_g (
    .clk_i, .rst_ni, .in_data_i, .in_sel_i, .in_valid_i, .in_ready_o,
    .out_data_o, .out_idx_o,
    .out_valid_o (g_valid),
    .out_ready_i
  );
  // the whole of the evasion
  assign out_valid_o = g_valid & out_ready_i;
endmodule
