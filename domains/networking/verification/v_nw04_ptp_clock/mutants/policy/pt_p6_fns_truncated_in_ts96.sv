// v_nw04 POLICY-DIVERGENT PERTURBATION -- this MUST BE ACCEPTED.
//
// Opposite sign to mutants/: this satisfies the contract and must survive.
//
// It is NOT a wrapper. It is an independent implementation written from
// spec/ptp_time_base_spec.md alone, and it takes the OPPOSITE choice on both
// named latitude clauses:
//
//   L1  the golden registers a control input before acting on it -- a new
//       period is first reflected two cycles after period_valid_i, and
//       adj_active_o rises one cycle after adj_valid_i. This one acts on every
//       control input in the SAME cycle its valid is asserted: zero latency.
//   L2  the golden hands ts96_o its increment one cycle after ts64_o, so the
//       drift lands on different cycles in the two bases and adj_active_o is
//       offset from the adjusted increments. This one drives both bases from
//       the same increment on the same cycle, with adj_active_o exactly in
//       phase with the increments it marks.
//
// A reference testbench that fails this is encoding the golden's pipeline
// rather than the contract, and the testbench is what needs fixing.
module ptp_time_base (
  input  logic        clk_i,
  input  logic        rst_i,
  input  logic [95:0] set_ts96_i,
  input  logic        set_ts96_valid_i,
  input  logic [63:0] set_ts64_i,
  input  logic        set_ts64_valid_i,
  input  logic [3:0]  period_ns_i,
  input  logic [15:0] period_fns_i,
  input  logic        period_valid_i,
  input  logic [3:0]  adj_ns_i,
  input  logic [15:0] adj_fns_i,
  input  logic [15:0] adj_count_i,
  input  logic        adj_valid_i,
  output logic        adj_active_o,
  input  logic [3:0]  drift_ns_i,
  input  logic [15:0] drift_fns_i,
  input  logic [15:0] drift_rate_i,
  input  logic        drift_valid_i,
  output logic [95:0] ts96_o,
  output logic [63:0] ts64_o,
  output logic        ts_step_o,
  output logic        pps_o
);
  localparam [45:0] FNS_PER_SEC = 46'd65_536_000_000_000;   // 1e9 ns, in fns
  localparam [19:0] DEF_PERIOD  = {4'h6, 16'h6666};
  localparam [19:0] DEF_DRIFT   = {4'h0, 16'h0002};
  localparam [15:0] DEF_RATE    = 16'd5;

  logic [19:0] period_q, adj_q, drift_q;
  logic [15:0] adj_cnt_q, rate_q, drift_cnt_q;
  logic [47:0] s_q;
  logic [45:0] nsfns_q;        // ts96 ns.fns, combined
  logic [63:0] ts64_q;
  logic        pps_q;

  // ---- zero latency: a control input takes effect in its own cycle (L1) -----
  wire [19:0] period_now = period_valid_i ? {period_ns_i, period_fns_i} : period_q;
  wire [19:0] adj_now    = adj_valid_i    ? {adj_ns_i, adj_fns_i}       : adj_q;
  wire [15:0] cnt_now    = adj_valid_i    ? adj_count_i                 : adj_cnt_q;
  wire [19:0] drift_now  = drift_valid_i  ? {drift_ns_i, drift_fns_i}   : drift_q;
  wire [15:0] rate_now   = drift_valid_i  ? drift_rate_i                : rate_q;

  wire adj_on   = (cnt_now != 16'd0);
  wire drift_on = drift_valid_i ? 1'b1 : (drift_cnt_q == 16'd0);

  // increment, as a signed sum (I1); adj and drift are signed 20-bit (A5, D3)
  wire signed [22:0] inc = $signed({3'b000, period_now})
                         + (adj_on   ? $signed({{3{adj_now[19]}},   adj_now})   : 23'sd0)
                         + (drift_on ? $signed({{3{drift_now[19]}}, drift_now}) : 23'sd0);

  wire [46:0] nsfns_next = {1'b0, nsfns_q} + {{24{inc[22]}}, (inc & 23'sh7FFFF0)};
  wire        wrap_now   = (nsfns_next >= {1'b0, FNS_PER_SEC});

  // adj_active_o is exactly in phase with the increments it marks (L2)
  assign adj_active_o = adj_on;
  assign ts_step_o    = adj_on || set_ts96_valid_i || set_ts64_valid_i;   // A4, S3
  assign ts96_o       = {s_q, 2'b00, nsfns_q[45:16], nsfns_q[15:0]};
  assign ts64_o       = ts64_q;
  assign pps_o        = pps_q;

  always_ff @(posedge clk_i) begin
    // ---- the 96-bit base ----
    if (wrap_now) begin
      nsfns_q <= nsfns_next[45:0] - FNS_PER_SEC;                 // W1
      s_q     <= s_q + 48'd1;
    end else begin
      nsfns_q <= nsfns_next[45:0];
    end
    pps_q <= wrap_now;                                            // W3

    // ---- the 64-bit base, same increment, same cycle (L2) ----
    ts64_q <= ts64_q + {{40{inc[22]}}, inc[22:0]};                // W2: no wrap

    // ---- control state ----
    period_q <= period_now;
    adj_q    <= adj_now;
    drift_q  <= drift_now;
    rate_q   <= rate_now;
    adj_cnt_q <= (cnt_now != 16'd0) ? cnt_now - 16'd1 : 16'd0;    // A2
    drift_cnt_q <= drift_on ? (rate_now - 16'd1) : (drift_cnt_q - 16'd1);  // D2

    // ---- setting a base disturbs only that base (S1, S2, S4) ----
    if (set_ts96_valid_i) begin
      s_q     <= set_ts96_i[95:48];
      nsfns_q <= {set_ts96_i[45:16], set_ts96_i[15:0]};
      pps_q   <= 1'b0;
    end
    if (set_ts64_valid_i) ts64_q <= set_ts64_i;

    // ---- synchronous, active high (R1, R2) ----
    if (rst_i) begin
      period_q <= DEF_PERIOD; adj_q <= 20'd0; drift_q <= DEF_DRIFT;
      adj_cnt_q <= 16'd0; rate_q <= DEF_RATE; drift_cnt_q <= 16'd0;
      s_q <= 48'd0; nsfns_q <= 46'd0; ts64_q <= 64'd0; pps_q <= 1'b0;
    end
  end
endmodule
