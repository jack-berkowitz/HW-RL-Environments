// NEGATIVE CONTROL (b1) -- a KNOWN-BAD DUT. The reference testbench MUST catch it.
// Every output tied low: nothing is ever accepted or produced. Generated from
// the port map so no output can be left out by hand.
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
  assign push_ready_o = '0;
  assign pop_data_o = '0;
  assign pop_strb_o = '0;
  assign pop_valid_o = '0;
endmodule
