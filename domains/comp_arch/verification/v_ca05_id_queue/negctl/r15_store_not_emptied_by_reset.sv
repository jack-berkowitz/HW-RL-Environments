// DIFFERENTIAL: nc_hold = 1'b0
// R15 NEGATIVE CONTROL for v_ca05 -- it MUST FAIL, and on R15 alone.
//
// WHAT IT PROVES. tb/tag_tracker_spec_tb.sv checks R15 at four sites and a
// per-site sweep over the whole suite found ALL FOUR among the 14 of this task's
// 27 sites that never fire. The sweep ran each tb against its golden, every
// mutant AND the gate mutant, so "never fires" here is not an accident of one
// stimulus: no shipped defect in this task drives R15 at all. A clause checked
// four times and never once exercised is the state v_ca03's F1(a) sat in while
// its golden violated the clause those checks were written for.
//
// WHAT IT PERTURBS, and it is the smallest thing that violates R15. For four
// cycles after rst_ni is released, empty_o is held LOW. Nothing else is touched:
// full_o, the grants, the payloads and every handshake are the golden's. The
// design therefore reports a store that reset did not empty, which is exactly
// what R15 forbids and exactly what the testbench's "empty_o low after a reset
// that was asserted on a NON-EMPTY store" line was written to catch.
//
// WHY empty_o AND NOT THE STORE ITSELF. Clearing the entries would change pop
// and match behaviour and trip R1, R2 and R14 as well, and a control that fails
// on four clauses proves none of them. This one moves a single status line for
// four cycles.
//
// ONE HAZARD, RECORDED: tb/tag_tracker_spec_tb.sv reads `dut.linked_data_free`,
// a signal internal to the golden. It sits under `ifdef PROBE, so ordinary
// builds do not reach it -- but ANY wrapper for this task, this control and the
// mutants alike, fails to compile under -DPROBE. The reference is the only DUT
// that satisfies that reference.
module tt_nc_r15_store_not_emptied_by_reset #(
    parameter int  TAG_W   = 3,
    parameter int  SLOTS   = 8,
    parameter int  N_MATCH = 2,
    parameter type payload_t = logic [31:0]
) (
    input  logic clk_i,
    input  logic rst_ni,
    input  logic [TAG_W-1:0] push_tag_i,
    input  payload_t         push_data_i,
    input  logic             push_req_i,
    output logic             push_gnt_o,
    input  payload_t [N_MATCH-1:0] match_data_i,
    input  payload_t [N_MATCH-1:0] match_mask_i,
    input  logic     [N_MATCH-1:0] match_req_i,
    output logic     [N_MATCH-1:0] match_hit_o,
    output logic     [N_MATCH-1:0] match_gnt_o,
    input  logic [TAG_W-1:0] pop_tag_i,
    input  logic             pop_en_i,
    input  logic             pop_req_i,
    output payload_t         pop_data_o,
    output logic             pop_data_valid_o,
    output logic             pop_gnt_o,
    output logic             full_o,
    output logic             empty_o
);
  localparam int unsigned NC_HOLD_CYCLES = 4;

  // Reset release, seen from the port alone.
  logic rst_q;
  always_ff @(posedge clk_i) rst_q <= rst_ni;
  wire  nc_release = rst_ni && !rst_q;

  int unsigned nc_left = 0;
  always_ff @(posedge clk_i) begin
    if (nc_release)          nc_left <= NC_HOLD_CYCLES;
    else if (nc_left != 0)   nc_left <= nc_left - 1;
  end
  wire nc_hold = (nc_left != 0);

  logic g_empty;
  assign empty_o = nc_hold ? 1'b0 : g_empty;

  int unsigned nc_fired = 0;
  always_ff @(posedge clk_i) if (rst_ni && nc_hold) nc_fired <= nc_fired + 1;
  final $display("FIRED tt_nc_r15.hold_cycles %0d", nc_fired);

  tag_tracker #(
      .TAG_W(TAG_W), .SLOTS(SLOTS), .N_MATCH(N_MATCH), .payload_t(payload_t)
  ) i_g (
      .clk_i, .rst_ni,
      .push_tag_i, .push_data_i, .push_req_i, .push_gnt_o,
      .match_data_i, .match_mask_i, .match_req_i, .match_hit_o, .match_gnt_o,
      .pop_tag_i, .pop_en_i, .pop_req_i, .pop_data_o, .pop_data_valid_o, .pop_gnt_o,
      .full_o,
      .empty_o (g_empty)
  );
endmodule
