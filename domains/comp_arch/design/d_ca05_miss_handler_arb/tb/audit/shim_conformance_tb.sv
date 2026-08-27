// shim_conformance_tb.sv -- d_ca05: is the reference shim BEHAVIOUR-FREE?
//
// ref/miss_handler_arb_ref.sv claims to contain no behaviour -- it binds
// parameters and bitcasts two structs. That claim is worth exactly nothing
// asserted. The five measurements below were taken against the RAW ANCHOR in
// tb/audit/ca05_amo_flush_probe.sv and recorded in MEASUREMENTS.md; this rig
// takes the same five THROUGH THE SHIM. Every answer must be identical.
//
// If one differs, the shim has behaviour and the oracle claim collapses -- the
// reference would no longer be "real RTL nobody here wrote".
//
//   expected, from MEASUREMENTS.md, measured against the raw anchor:
//     Q2a  a real flush acknowledges                     1 pulse
//     Q1   an AMO forces a whole-cache flush first       state 4, then served
//     Q2b  the AMO-induced flush does NOT acknowledge    0 pulses
//     Q3   flush_i concurrent with amo_req_i             0 pulses
//     Q4   a concurrent miss defers the AMO              state 7, serve_amo 0
//     Q5/6 bypass arbitration is lowest-index priority   p0 20/20; p1 alone 20/20

`timescale 1ns/1ps

module shim_conformance_tb;
  import miss_handler_arb_pkg::*;

  localparam int unsigned NR_PORTS = 4;

  logic clk = 1'b0, rst_n = 1'b0;
  always #5 clk = ~clk;

  logic flush_i = 1'b0, flush_ack_o, miss_o, busy_i = 1'b0;
  logic [NR_PORTS-1:0][$bits(miss_req_t)-1:0] miss_req_i = '0;
  logic [NR_PORTS-1:0] bypass_gnt_o, bypass_valid_o, miss_gnt_o, active_serving_o;
  logic [NR_PORTS-1:0][63:0] bypass_data_o;
  logic [63:0] critical_word_o; logic critical_word_valid_o;
  logic [NR_PORTS-1:0][55:0] mshr_addr_i = '0;
  logic [NR_PORTS-1:0] mshr_addr_matches_o, mshr_index_matches_o;
  amo_req_t  amo_req_i = '0;
  amo_resp_t amo_resp_o;
  axi_req_t  byp_req, dat_req;
  axi_rsp_t  byp_rsp, dat_rsp;
  logic [SET_ASSOC-1:0]   req_o;
  logic [INDEX_WIDTH-1:0] addr_o;
  cache_line_t data_o; cl_be_t be_o; logic we_o;
  cache_line_t [SET_ASSOC-1:0] data_i = '0;

  miss_handler_arb #(.NR_PORTS(NR_PORTS)) dut (
    .clk, .rst_n, .flush_i, .flush_ack_o, .miss_o, .busy_i,
    .miss_req_i, .bypass_gnt_o, .bypass_valid_o, .bypass_data_o,
    .miss_gnt_o, .active_serving_o, .critical_word_o, .critical_word_valid_o,
    .mshr_addr_i, .mshr_addr_matches_o, .mshr_index_matches_o,
    .amo_req_i, .amo_resp_o,
    .axi_bypass_req_o(byp_req), .axi_bypass_rsp_i(byp_rsp),
    .axi_data_req_o(dat_req),   .axi_data_rsp_i(dat_rsp),
    .req_o, .addr_o, .data_o, .be_o, .data_i, .we_o
  );

  // The AXI responder, carried over verbatim from the anchor probe. An ATOP
  // write returns BOTH B and R; qualifying the R beat with a REGISTERED copy of
  // aw.atop leaves the design stuck in AMO_WAIT_RESP, which cost two wrong
  // guesses before the channel was instrumented rather than reasoned about.
  logic [3:0] byp_id_q; logic byp_atop_pend_q;
  logic [3:0] dat_id_q; logic dat_ar_seen_q;

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      byp_rsp <= '0; dat_rsp <= '0;
      byp_id_q <= '0; byp_atop_pend_q <= 1'b0; dat_id_q <= '0; dat_ar_seen_q <= 1'b0;
    end else begin
      byp_rsp.aw_ready <= 1'b1; byp_rsp.w_ready <= 1'b1; byp_rsp.ar_ready <= 1'b1;
      dat_rsp.aw_ready <= 1'b1; dat_rsp.w_ready <= 1'b1; dat_rsp.ar_ready <= 1'b1;

      if (byp_req.aw_valid) begin
        byp_id_q <= byp_req.aw.id;
        if (byp_req.aw.atop != 6'd0) byp_atop_pend_q <= 1'b1;
      end
      byp_rsp.b_valid <= byp_req.w_valid & byp_req.w.last;
      byp_rsp.b.id    <= byp_req.aw_valid ? byp_req.aw.id : byp_id_q;
      byp_rsp.b.resp  <= 2'b00;
      byp_rsp.r_valid <= byp_req.ar_valid | byp_atop_pend_q;
      byp_rsp.r.id    <= byp_req.ar_valid ? byp_req.ar.id : byp_id_q;
      byp_rsp.r.data  <= 64'hA5A5_1234_DEAD_BEEF;
      byp_rsp.r.last  <= 1'b1; byp_rsp.r.resp <= 2'b00;
      if (byp_atop_pend_q && byp_rsp.r_valid) byp_atop_pend_q <= 1'b0;

      if (dat_req.ar_valid) begin dat_id_q <= dat_req.ar.id; dat_ar_seen_q <= 1'b1; end
      dat_rsp.r_valid <= dat_ar_seen_q;
      dat_rsp.r.id    <= dat_id_q;
      dat_rsp.r.data  <= 64'hC0DE_0000_0000_C0DE;
      dat_rsp.r.last  <= 1'b1; dat_rsp.r.resp <= 2'b00;
      if (dat_ar_seen_q && dat_req.r_ready) dat_ar_seen_q <= 1'b0;
      dat_rsp.b_valid <= dat_req.w_valid & dat_req.w.last;
      dat_rsp.b.id    <= dat_req.aw.id;
      dat_rsp.b.resp  <= 2'b00;
    end
  end

  int unsigned acks, amo_acks;
  always_ff @(posedge clk) begin
    if (!rst_n) begin acks <= 0; amo_acks <= 0; end
    else begin
      if (flush_ack_o)    acks     <= acks + 1;
      if (amo_resp_o.ack) amo_acks <= amo_acks + 1;
    end
  end

  int unsigned errs = 0;
  task automatic expect_eq(input string tag, input int got, input int want);
    begin
      if (got !== want) begin
        errs++;
        $display("[FAIL] %s: shim gives %0d, the raw anchor gave %0d", tag, got, want);
      end else
        $display("MEASURE: %-26s %0d  (matches the raw anchor)", tag, got);
    end
  endtask

  task automatic quiesce(input string tag);
    int unsigned t = 0; bit ok = 0;
    begin
      @(negedge clk); amo_req_i = '0; flush_i = 1'b0; miss_req_i = '0;
      while (t < 60000) begin @(posedge clk); t++;
        if (dut.i_miss_handler.state_q == 4'h0) begin ok = 1; break; end end
      repeat (5) @(posedge clk);
      if (!ok) begin errs++; $display("[FAIL] %s: never returned to IDLE", tag); end
    end
  endtask

  task automatic run_idle(input string tag, input int unsigned lim);
    int unsigned t = 0; bit ok = 0;
    begin
      while (t < lim) begin @(posedge clk); t++;
        if (dut.i_miss_handler.state_q == 4'h0) begin ok = 1; break; end end
      if (!ok) begin errs++; $display("[FAIL] %s: no return to IDLE in %0d", tag, lim); end
    end
  endtask

  int unsigned a0, i, seen[4];

  initial begin
    repeat (10) @(posedge clk); rst_n = 1'b1;
    run_idle("reset settle", 20000);

    // Q2a -- a real flush acknowledges
    a0 = acks;
    @(negedge clk); flush_i = 1'b1; @(posedge clk); @(negedge clk); flush_i = 1'b0;
    run_idle("Q2a", 20000);
    expect_eq("Q2a real flush acks", acks - a0, 1);
    quiesce("after Q2a");

    // Q1/Q2b -- an AMO forces a flush that does NOT acknowledge
    a0 = acks;
    @(negedge clk);
    amo_req_i.req = 1'b1; amo_req_i.amo_op = AMO_ADD; amo_req_i.size = 2'b11;
    amo_req_i.operand_a = 64'h0000_0000_8000_0040; amo_req_i.operand_b = 64'd7;
    @(posedge clk); #1;
    expect_eq("Q1 state after AMO", dut.i_miss_handler.state_q, 4);
    run_idle("Q1", 40000);
    expect_eq("Q2b amo-flush acks", acks - a0, 0);
    expect_eq("Q1 amo served", (amo_acks > 0) ? 1 : 0, 1);
    quiesce("after Q1");

    // Q3 -- flush_i concurrent with amo_req_i gets NO acknowledgement
    a0 = acks;
    @(negedge clk);
    flush_i = 1'b1;
    amo_req_i.req = 1'b1; amo_req_i.amo_op = AMO_ADD; amo_req_i.size = 2'b11;
    amo_req_i.operand_a = 64'h0000_0000_8000_0080; amo_req_i.operand_b = 64'd9;
    @(posedge clk); @(negedge clk); flush_i = 1'b0;
    run_idle("Q3", 40000);
    expect_eq("Q3 flush+amo acks", acks - a0, 0);
    quiesce("after Q3");

    // Q4 -- a concurrent miss defers the AMO
    @(negedge clk);
    amo_req_i.req = 1'b1; amo_req_i.amo_op = AMO_ADD; amo_req_i.size = 2'b11;
    amo_req_i.operand_a = 64'h0000_0000_8000_00C0; amo_req_i.operand_b = 64'd11;
    miss_req_i[2] = {1'b1, 64'h0000_0000_9000_0000, 8'hFF, 2'b11, 1'b0, 64'd0, 1'b0};
    @(posedge clk); #1;
    expect_eq("Q4 state (7=MISS)",  dut.i_miss_handler.state_q, 7);
    expect_eq("Q4 serve_amo_q",     dut.i_miss_handler.serve_amo_q, 0);
    @(negedge clk); miss_req_i[2] = '0;
    quiesce("after Q4");

    // Q5 -- all four ports request: strict lowest-index priority
    for (int k = 0; k < 4; k++) seen[k] = 0;
    @(negedge clk);
    for (int k = 0; k < 4; k++)
      miss_req_i[k] = {1'b1, 64'h0000_0000_A000_0000 + (k << 6), 8'hFF, 2'b11, 1'b0, 64'd0, 1'b1};
    for (i = 0; i < 60; i++) begin @(posedge clk); #1;
      for (int k = 0; k < 4; k++) if (bypass_gnt_o[k]) seen[k]++; end
    @(negedge clk); miss_req_i = '0;
    expect_eq("Q5 p0 grants", seen[0], 20);
    expect_eq("Q5 p1 grants", seen[1], 0);
    expect_eq("Q5 p3 grants", seen[3], 0);
    quiesce("after Q5");

    // Q6 -- control: p0 idle, p1 takes everything and p2/p3 still starve
    for (int k = 0; k < 4; k++) seen[k] = 0;
    @(negedge clk);
    for (int k = 1; k < 4; k++)
      miss_req_i[k] = {1'b1, 64'h0000_0000_B000_0000 + (k << 6), 8'hFF, 2'b11, 1'b0, 64'd0, 1'b1};
    for (i = 0; i < 60; i++) begin @(posedge clk); #1;
      for (int k = 0; k < 4; k++) if (bypass_gnt_o[k]) seen[k]++; end
    @(negedge clk); miss_req_i = '0;
    expect_eq("Q6 p1 grants", seen[1], 20);
    expect_eq("Q6 p2 grants", seen[2], 0);

    if (errs == 0) $display("TEST_RESULT: PASS -- the shim reproduces the anchor on all five");
    else           $display("TEST_RESULT: FAIL: %0d divergences -- the shim has behaviour", errs);
    $finish;
  end

  initial begin #6000000; $display("[FAIL] watchdog");
                $display("TEST_RESULT: FAIL: watchdog"); $finish; end
endmodule
