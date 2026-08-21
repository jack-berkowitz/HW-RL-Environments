// ---------------------------------------------------------------------------
// GOLDEN -- scoring only. NEVER shipped to a submission.
//
// Class A port shim: renames the anchor's ports to the names the task's port
// map declares and pins the configuration. Renaming only -- no logic, no
// re-timing, no defaulting.
//
// Pinned inside the shim, deliberately NOT exposed as parameters: the whole
// configuration. Clauses about the nominal rate, the drift period and the
// one-second rollover are properties of specific numbers; exposing them would
// let a submission build the golden at a different configuration and fail the
// validity gate for a configuration error rather than a verification error.
// ---------------------------------------------------------------------------
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
  ptp_clock #(
    .PERIOD_NS_WIDTH (4),
    .OFFSET_NS_WIDTH (4),
    .DRIFT_NS_WIDTH  (4),
    .FNS_WIDTH       (16),
    .PERIOD_NS       (4'h6),      // 6.4 ns nominal -> 156.25 MHz
    .PERIOD_FNS      (16'h6666),
    .DRIFT_ENABLE    (1),
    .DRIFT_NS        (4'h0),
    .DRIFT_FNS       (16'h0002),  // +2/65536 ns every DRIFT_RATE cycles
    .DRIFT_RATE      (16'h0005),
    .PIPELINE_OUTPUT (0)
  ) i_clock (
    .clk (clk_i), .rst (rst_i),
    .input_ts_96 (set_ts96_i), .input_ts_96_valid (set_ts96_valid_i),
    .input_ts_64 (set_ts64_i), .input_ts_64_valid (set_ts64_valid_i),
    .input_period_ns (period_ns_i), .input_period_fns (period_fns_i),
    .input_period_valid (period_valid_i),
    .input_adj_ns (adj_ns_i), .input_adj_fns (adj_fns_i),
    .input_adj_count (adj_count_i), .input_adj_valid (adj_valid_i),
    .input_adj_active (adj_active_o),
    .input_drift_ns (drift_ns_i), .input_drift_fns (drift_fns_i),
    .input_drift_rate (drift_rate_i), .input_drift_valid (drift_valid_i),
    .output_ts_96 (ts96_o), .output_ts_64 (ts64_o),
    .output_ts_step (ts_step_o), .output_pps (pps_o)
  );
endmodule
