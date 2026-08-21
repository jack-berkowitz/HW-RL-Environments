// NEGATIVE CONTROL (b1) -- a KNOWN-BAD DUT. The reference testbench MUST catch it.
//
// Every output is tied low: time never advances. Generated from the port map so
// no output can be left out by hand and accidentally leave a working path.
module ptp_time_base (
  input  logic        clk_i,
  input  logic        rst_i,              // SYNCHRONOUS, ACTIVE HIGH
  // ---- set the time base ----
  input  logic [95:0] set_ts96_i,
  input  logic        set_ts96_valid_i,
  input  logic [63:0] set_ts64_i,
  input  logic        set_ts64_valid_i,
  // ---- nominal period ----
  input  logic [3:0]  period_ns_i,
  input  logic [15:0] period_fns_i,
  input  logic        period_valid_i,
  // ---- counted offset adjustment ----
  input  logic [3:0]  adj_ns_i,
  input  logic [15:0] adj_fns_i,
  input  logic [15:0] adj_count_i,
  input  logic        adj_valid_i,
  output logic        adj_active_o,
  // ---- periodic drift adjustment ----
  input  logic [3:0]  drift_ns_i,
  input  logic [15:0] drift_fns_i,
  input  logic [15:0] drift_rate_i,
  input  logic        drift_valid_i,
  // ---- outputs ----
  output logic [95:0] ts96_o,
  output logic [63:0] ts64_o,
  output logic        ts_step_o,
  output logic        pps_o
);
  assign adj_active_o = '0;
  assign ts96_o = '0;
  assign ts64_o = '0;
  assign ts_step_o = '0;
  assign pps_o = '0;
endmodule
