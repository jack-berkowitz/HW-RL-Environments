// v_ca07 CONFORMANT PERTURBATIONS -- these MUST BE ACCEPTED.
//
// Each satisfies spec/clk_ratio_div_spec.md and differs from the anchor ONLY on
// a named latitude clause. A testbench that rejects any of them is encoding the
// anchor's timing rather than the contract.
//
// L1 -- the phase of clk_o against clk_i -- is NOT perturbed here, because a
// wrapper cannot shift the phase of a clock it did not generate. dut2 covers L1:
// it is an independent implementation and its phase is its own.
//
// GATED IN PAIRS. Where acceptance is delayed, the valid presented to the anchor
// and the ready presented outward carry the SAME gate. Masking only the ready
// would desynchronise the handshake: the anchor grants internally while the
// requester never sees it, re-offers, and one change is accepted several times.

// --------------------------------------------------------------------------
// c1 -- ACCEPTANCE DELAYED, four cycles on and four off (clauses L3, L4).
//   div_ready_o rises later than the anchor would for the same offer, and a
//   second offer during a transition is deferred for longer. Both are free: L3
//   fixes the rise time only for the same-value case, and L4 fixes that a
//   deferred request is eventually accepted, not when.
// --------------------------------------------------------------------------
module cdc_c1_accept_window_4 (
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
  wire win = tick[2];
  logic g_ready;
  assign div_ready_o = g_ready & win;
  clk_ratio_div i_g (
    .clk_i, .rst_ni, .en_i, .test_mode_en_i,
    .div_i,
    .div_valid_i (div_valid_i & win),
    .div_ready_o (g_ready),
    .clk_o, .cycl_count_o
  );
endmodule

// --------------------------------------------------------------------------
// c2 -- ACCEPTANCE DELAYED HARDER, eight on and eight off (L3, L4).
//   The same knob at a different setting. Two perturbations on one clause are
//   deliberate: a testbench that pinned a particular acceptance latency fails
//   whichever of the two it did not fit.
// --------------------------------------------------------------------------
module cdc_c2_accept_window_8 (
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
  logic [4:0] tick;
  always_ff @(posedge clk_i or negedge rst_ni)
    if (!rst_ni) tick <= '0; else tick <= tick + 5'd1;
  wire win = tick[3];
  logic g_ready;
  assign div_ready_o = g_ready & win;
  clk_ratio_div i_g (
    .clk_i, .rst_ni, .en_i, .test_mode_en_i,
    .div_i,
    .div_valid_i (div_valid_i & win),
    .div_ready_o (g_ready),
    .clk_o, .cycl_count_o
  );
endmodule

// --------------------------------------------------------------------------
// c3 -- GATING EXTENDED, still inside G1's bound (clause L2).
//   After a change is accepted the output stays low one cycle longer than the
//   anchor would hold it. The extra gate is applied through a NEGEDGE register so
//   it can never truncate a high phase -- G2 says gated means idle low, and E3
//   forbids a partial pulse, so an extension applied combinationally would break
//   the contract rather than exercise latitude.
// --------------------------------------------------------------------------
module cdc_c3_extra_gating (
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
  logic accepted, hold_q;
  assign accepted = div_valid_i & div_ready_o;
  always_ff @(posedge clk_i or negedge rst_ni)
    if (!rst_ni) hold_q <= 1'b0; else hold_q <= accepted;
  logic hold_n;
  always_ff @(negedge clk_i or negedge rst_ni)
    if (!rst_ni) hold_n <= 1'b0; else hold_n <= hold_q | accepted;
  assign clk_o = g_clk & ~hold_n;
  clk_ratio_div i_g (
    .clk_i, .rst_ni, .en_i, .test_mode_en_i,
    .div_i, .div_valid_i, .div_ready_o,
    .clk_o (g_clk), .cycl_count_o
  );
endmodule

// --------------------------------------------------------------------------
// c4 -- cycl_count_o FORCED TO ZERO while the output is disabled (clause L5).
//   L5 leaves the counter free while the clock is stopped; C1 fixes it only while
//   the clock runs. A testbench that checks the counter without gating on en_i
//   fails this and is checking a value the contract does not define.
// --------------------------------------------------------------------------
module cdc_c4_count_zero_when_disabled (
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
  logic [3:0] g_cnt;
  assign cycl_count_o = en_i ? g_cnt : 4'd0;
  clk_ratio_div i_g (
    .clk_i, .rst_ni, .en_i, .test_mode_en_i,
    .div_i, .div_valid_i, .div_ready_o,
    .clk_o, .cycl_count_o (g_cnt)
  );
endmodule

// --------------------------------------------------------------------------
// c5 -- cycl_count_o HELD AT ITS LAST VALUE while disabled (clause L5).
//   The opposite legal reading of L5 from c4. Both are conforming, and having two
//   makes the point that L5 permits a range rather than one alternative: a
//   testbench fitted to either specific behaviour fails the other.
// --------------------------------------------------------------------------
module cdc_c5_count_frozen_when_disabled (
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
  logic [3:0] g_cnt, frozen;
  always_ff @(posedge clk_i or negedge rst_ni)
    if (!rst_ni) frozen <= 4'd0; else if (en_i) frozen <= g_cnt;
  assign cycl_count_o = en_i ? g_cnt : frozen;
  clk_ratio_div i_g (
    .clk_i, .rst_ni, .en_i, .test_mode_en_i,
    .div_i, .div_valid_i, .div_ready_o,
    .clk_o, .cycl_count_o (g_cnt)
  );
endmodule
