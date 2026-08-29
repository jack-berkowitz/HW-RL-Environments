// DIFFERENTIAL: nc_survive = 1'b0
// S15 NEGATIVE CONTROL for v_dsp02 -- it MUST FAIL, and on S15 alone.
//
// WHAT IT PROVES, and why it had to be written in the same change as the check.
// S15's third obligation -- no operation accepted before or during reset produces
// a result afterwards -- had NO check until 2026-08-28. discarded_tag was filled
// on every reset for S15's benefit and never read, and a surviving result landed
// on H2's "delivered with no operation outstanding": a true sentence about the
// wrong clause, since the design did not invent a result, it failed to discard
// one. The S15 line that did exist could never fire for any DUT.
//
// Replacing dead code with untested code would be no better, so this control
// exists to make the new survivor window fire on demand.
//
// WHAT IT PERTURBS. One cycle after rst_ni is released, out_valid_o is asserted
// once. Nothing else is touched. The testbench's model was cleared on the edge
// that reset the design and nothing has been issued since, so the result can
// only be a survivor -- which is the attribution the window makes and this
// control checks.
module fn_nc_s15_result_survives_reset (
    input  logic        clk_i,
    input  logic        rst_ni,
    input  logic [31:0] operand_a_i,
    input  logic [31:0] operand_b_i,
    input  logic [1:0]  op_i,
    input  logic [2:0]  op_mode_i,
    input  logic        in_valid_i,
    output logic        in_ready_o,
    output logic [31:0] result_o,
    output logic [9:0]  class_mask_o,
    output logic [4:0]  status_o,
    output logic        out_valid_o,
    input  logic        out_ready_i
);
  logic        g_out_valid;
  logic [31:0] g_result;
  logic [9:0]  g_class;
  logic [4:0]  g_status;

  // Reset release, from the port alone.
  logic rst_q;
  always_ff @(posedge clk_i) rst_q <= rst_ni;
  wire  nc_release = rst_ni && !rst_q;

  // IN FLIGHT AT THE MOMENT OF RESET, counted from the port handshakes only:
  // accepted minus delivered. A first version armed on EVERY release, including
  // the one at time zero when nothing had been accepted -- the forced result
  // then landed where a real expectation was waiting and the control failed on
  // H2 and S1 as well as S15. A control that trips three clauses proves none of
  // them. Arming only when the reset actually discarded something is what makes
  // the delivered result a survivor rather than an invention.
  // A SECOND VERSION OF THIS GUARD SUPPRESSED ITS OWN TRIGGER and read zero every
  // time: it cleared nc_inflight on !rst_ni and then sampled it while !rst_ni, so
  // the sample always saw the cleared value. FIRED read 0 survivors on a run in
  // which the control was armed for exactly the reset it was written for. This
  // task's own mutants record the identical trap one step earlier -- af_m11's
  // counter counted acceptances while the defect drove ready low. The count is
  // now CAPTURED on the falling edge and cleared in the same assignment, so the
  // capture reads the value the reset is about to destroy.
  wire nc_assert = !rst_ni && rst_q;
  int unsigned nc_inflight = 0;
  logic nc_had_work;
  always_ff @(posedge clk_i) begin
    if (nc_assert) begin
      nc_had_work <= (nc_inflight != 0);
      nc_inflight <= 0;
    end else if (rst_ni) begin
      if (in_valid_i && in_ready_o && !(g_out_valid && out_ready_i)) nc_inflight <= nc_inflight + 1;
      else if (g_out_valid && out_ready_i && !(in_valid_i && in_ready_o) && nc_inflight != 0)
        nc_inflight <= nc_inflight - 1;
    end
  end

  logic nc_arm, nc_spent;
  always_ff @(posedge clk_i) begin
    if (nc_release && nc_had_work && !nc_spent) nc_arm <= 1'b1;
    else if (nc_arm && out_ready_i) begin nc_arm <= 1'b0; nc_spent <= 1'b1; end
  end
  wire nc_survive = nc_arm;

  assign out_valid_o  = nc_survive ? 1'b1        : g_out_valid;
  assign result_o     = nc_survive ? 32'h5EC0_1D5 : g_result;
  assign class_mask_o = g_class;
  assign status_o     = nc_survive ? 5'd0        : g_status;

  int unsigned nc_fired = 0;
  always_ff @(posedge clk_i) if (rst_ni && nc_survive && out_ready_i) nc_fired <= nc_fired + 1;
  final $display("FIRED fn_nc_s15.survivors %0d", nc_fired);

  fp_noncomp i_g (
      .clk_i, .rst_ni,
      .operand_a_i, .operand_b_i, .op_i, .op_mode_i,
      .in_valid_i, .in_ready_o,
      .result_o (g_result), .class_mask_o (g_class), .status_o (g_status),
      .out_valid_o (g_out_valid),
      .out_ready_i (out_ready_i && !nc_survive)
  );
endmodule
