// ---------------------------------------------------------------------------
// PORT MAP -- stream_realign
//
// This is the complete interface. It is the ONLY structural information you
// are given: there is no reference implementation, and none will be provided.
// Write your testbench against spec/stream_realign_spec.md and this file.
// ---------------------------------------------------------------------------
module stream_realign (
  input  logic        clk_i,
  input  logic        rst_ni,
  input  logic        clear_i,
  // ---- control ----
  input  logic        realign_i,
  input  logic        first_i,
  input  logic        last_i,
  input  logic [3:0]  strb_i,
  // ---- input stream ----
  input  logic [31:0] push_data_i,
  input  logic [3:0]  push_strb_i,
  input  logic        push_valid_i,
  output logic        push_ready_o,
  // ---- output stream ----
  output logic [31:0] pop_data_o,
  output logic [3:0]  pop_strb_o,
  output logic        pop_valid_o,
  input  logic        pop_ready_i
);

  // no body -- see spec/stream_realign_spec.md for required behaviour
endmodule
