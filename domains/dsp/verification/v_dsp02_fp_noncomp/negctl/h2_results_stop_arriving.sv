// DIFFERENTIAL: mut_stall = 1'b0
// H2 NEGATIVE CONTROL for v_dsp02 -- it MUST FAIL, and on H2 alone.
//
// WHAT IT PROVES. tb/fp_noncomp_spec_tb.sv's drain() ends with
//     if (exp_q.size() > 0) fail("H2", "%0d results never arrived")
// and until this file existed nothing had ever made that line execute. A
// per-site sweep over the whole suite -- every fail() site tagged, each tb run
// against its golden, every mutant AND the gate mutant -- found it among 13 of
// this task's 19 sites that never fire. A check nobody can make fire is
// indistinguishable from a check that works, which is the state v_ca03's F1(a)
// sat in while its golden violated the clause it was written for.
//
// WHAT IT PERTURBS, and it is the smallest thing that withholds a result without
// corrupting one. Past the guard, out_valid_o is held LOW. The golden is
// NumPipeRegs=1, so refusing the handshake stalls the stage rather than dropping
// anything: no result is delivered late, reordered or altered, and every result
// delivered BEFORE the guard fires is exactly what it would have been. That is
// what keeps the failure on H2 alone -- a control that swallowed one result
// mid-stream would shift every later comparison by one and trip the S-clauses
// instead, reporting a value defect for a delivery defect.
//
// THE GUARD IS LATE ON PURPOSE. The testbench's phase E drops rst_ni with an
// operation in flight and checks S15; firing before that would trip S15 too and
// the control would no longer isolate H2. The ordinal below was calibrated by
// running it -- see negctl/NOTES.md for the sweep and the clause set at each
// value.
module fn_nc_h2_results_stop_arriving (
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
  localparam int unsigned NC_AFTER = 3600;

  // Counted from the PORT handshake only, and NOT reset-cleared: the reference
  // pulses reset late, and a counter cleared there would restart and never reach
  // the threshold. v_dsp02's own mutants record that trap.
  int unsigned nc_acc = 0;
  always_ff @(posedge clk_i) if (rst_ni && in_valid_i && in_ready_o) nc_acc <= nc_acc + 1;
  wire mut_stall = (nc_acc >= NC_AFTER);

  logic g_out_valid;
  assign out_valid_o = mut_stall ? 1'b0 : g_out_valid;

  int unsigned nc_fired = 0;
  always_ff @(posedge clk_i) if (rst_ni && mut_stall) nc_fired <= nc_fired + 1;
  final $display("FIRED fn_nc_h2.accepted %0d", nc_acc);
  final $display("FIRED fn_nc_h2.stall_cycles %0d", nc_fired);

  fp_noncomp i_g (
      .clk_i, .rst_ni,
      .operand_a_i, .operand_b_i, .op_i, .op_mode_i,
      .in_valid_i, .in_ready_o,
      .result_o, .class_mask_o, .status_o,
      .out_valid_o (g_out_valid),
      .out_ready_i
  );
endmodule
