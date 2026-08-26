// ca05_amo_flush_probe.sv -- d_ca05 STEP 0, PROBE 2. Not a scoring rig.
//
// The landscape names d_ca05's mechanism as "AMO atomicity is mechanism B ...
// an AMO that is not atomic returns the correct value in the uncontended case."
// That was written from port names, which is the method that produced a FALSE
// mechanism and MISSED the best one on d_ai04. So it is measured.
//
// Reading the FSM suggests something more specific and more discriminating than
// atomicity. miss_handler.sv:233-263 is a priority cascade of ifs with NO else,
// so the LAST match wins:
//
//   if (amo_req_i.req && !busy_i)      -> FLUSH_REQ_STATUS, serve_amo_d = 1
//   if (flush_i && !busy_i)            -> FLUSH_REQ_STATUS   (serve_amo_d UNTOUCHED)
//   for (i) if (miss_req_valid[i] ...) -> MISS,              serve_amo_d = 0
//
// and at :404, when the flush walk completes,
//
//   flush_ack_o = ~serve_amo_q;   // "only acknowledge if the flush wasn't an atomic"
//
// Three questions follow, and only the first is in the landscape:
//   Q1 does an AMO force a whole-cache flush before it is served?
//   Q2 is flush_ack_o SUPPRESSED for that flush, and asserted for a real one?
//   Q3 THE CORNER: flush_i and amo_req_i together. The second if does not clear
//      serve_amo_d, so a genuine flush request should get NO acknowledgement.
//      If that holds it is a clause no one writes by accident.
//   Q4 does an incoming miss defer a pending AMO (serve_amo_d = 0)?

`include "axi/typedef.svh"
`timescale 1ns/1ps

module ca05_amo_flush_probe
  import ariane_pkg::*;
  import std_cache_pkg::*;
#();

  localparam int unsigned NR_PORTS = 4;
  localparam config_pkg::cva6_cfg_t CVA6Cfg =
      build_config_pkg::build_config(cva6_config_pkg::cva6_cfg);

  typedef logic [63:0] axi_addr_t; typedef logic [3:0] axi_id_t;
  typedef logic [63:0] axi_data_t; typedef logic [7:0] axi_strb_t;
  typedef logic [ 0:0] axi_user_t;
  `AXI_TYPEDEF_ALL(cva6_axi, axi_addr_t, axi_id_t, axi_data_t, axi_strb_t, axi_user_t)

  localparam type cache_line_t = struct packed {
    logic [CVA6Cfg.DCACHE_TAG_WIDTH-1:0]  tag;
    logic [CVA6Cfg.DCACHE_LINE_WIDTH-1:0] data;
    logic valid; logic dirty;
  };
  localparam type cl_be_t = struct packed {
    logic [(CVA6Cfg.DCACHE_TAG_WIDTH+7)/8-1:0]  tag;
    logic [(CVA6Cfg.DCACHE_LINE_WIDTH+7)/8-1:0] data;
    logic [CVA6Cfg.DCACHE_SET_ASSOC-1:0]        vldrty;
  };

  logic clk = 1'b0, rst_ni = 1'b0;
  always #5 clk = ~clk;

  logic flush_i = 1'b0, flush_ack_o, miss_o, busy_i = 1'b0;
  logic [NR_PORTS-1:0][$bits(miss_req_t)-1:0] miss_req_i = '0;
  logic [NR_PORTS-1:0] bypass_gnt_o, bypass_valid_o, miss_gnt_o, active_serving_o;
  logic [NR_PORTS-1:0][63:0] bypass_data_o;
  cva6_axi_req_t  axi_bypass_o, axi_data_o;
  cva6_axi_resp_t axi_bypass_i, axi_data_i;
  logic [63:0] critical_word_o; logic critical_word_valid_o;
  logic [NR_PORTS-1:0][55:0] mshr_addr_i = '0;
  logic [NR_PORTS-1:0] mshr_addr_matches_o, mshr_index_matches_o;
  amo_req_t  amo_req_i = '0;
  amo_resp_t amo_resp_o;
  logic [CVA6Cfg.DCACHE_SET_ASSOC-1:0]   req_o;
  logic [CVA6Cfg.DCACHE_INDEX_WIDTH-1:0] addr_o;
  cache_line_t data_o; cl_be_t be_o; logic we_o;
  cache_line_t [CVA6Cfg.DCACHE_SET_ASSOC-1:0] data_i = '0;  // clean, non-dirty lines

  miss_handler #(
      .CVA6Cfg(CVA6Cfg), .NR_PORTS(NR_PORTS),
      .axi_req_t(cva6_axi_req_t), .axi_rsp_t(cva6_axi_resp_t),
      .cache_line_t(cache_line_t), .cl_be_t(cl_be_t)
  ) dut (
      .clk_i(clk), .rst_ni(rst_ni), .flush_i, .flush_ack_o, .miss_o, .busy_i,
      .miss_req_i, .bypass_gnt_o, .bypass_valid_o, .bypass_data_o,
      .axi_bypass_o, .axi_bypass_i, .miss_gnt_o, .active_serving_o,
      .critical_word_o, .critical_word_valid_o, .axi_data_o, .axi_data_i,
      .mshr_addr_i, .mshr_addr_matches_o, .mshr_index_matches_o,
      .amo_req_i, .amo_resp_o, .req_o, .addr_o, .data_o, .be_o, .data_i, .we_o
  );

  // ---- AXI responder. The FIRST version of this hung the DUT in AMO_WAIT_RESP
  // and the probe REFUSED its own rows rather than reporting the zeros as data.
  // An ATOP write returns BOTH a B beat and an R beat carrying the old value;
  // returning only B leaves axi_adapter waiting forever. ----
  logic [3:0] byp_id_q;  logic [5:0] byp_atop_q;  logic byp_aw_seen_q;
  logic [3:0] dat_id_q;  logic dat_ar_seen_q;

  always_ff @(posedge clk) begin
    if (!rst_ni) begin
      axi_bypass_i <= '0; axi_data_i <= '0;
      byp_id_q <= '0; byp_atop_q <= '0; byp_aw_seen_q <= 1'b0;
      dat_id_q <= '0; dat_ar_seen_q <= 1'b0;
    end else begin
      // always ready to take a request
      axi_bypass_i.aw_ready <= 1'b1;
      axi_bypass_i.w_ready  <= 1'b1;
      axi_bypass_i.ar_ready <= 1'b1;
      axi_data_i.aw_ready   <= 1'b1;
      axi_data_i.w_ready    <= 1'b1;
      axi_data_i.ar_ready   <= 1'b1;

      // An ATOP write must return BOTH B and R. The first attempt qualified the
      // R beat with a REGISTERED copy of aw.atop, which is still stale in the
      // cycle W handshakes -- AW and W complete together here -- so R never
      // fired and the DUT sat in AMO_WAIT_RESP. Measured, not reasoned: the
      // channel monitor showed aw v/r=11 atop=20, b v=1, r v=0 forever.
      if (axi_bypass_o.aw_valid && axi_bypass_i.aw_ready) begin
        byp_id_q   <= axi_bypass_o.aw.id;
        byp_atop_q <= axi_bypass_o.aw.atop;
        if (axi_bypass_o.aw.atop != 6'd0) byp_aw_seen_q <= 1'b1;   // atomic pending
      end

      // B on the last write beat
      axi_bypass_i.b_valid <= axi_bypass_o.w_valid & axi_bypass_o.w.last;
      axi_bypass_i.b.id    <= axi_bypass_o.aw_valid ? axi_bypass_o.aw.id : byp_id_q;
      axi_bypass_i.b.resp  <= 2'b00;

      // R for a plain read, or for a pending atomic
      axi_bypass_i.r_valid <= axi_bypass_o.ar_valid | byp_aw_seen_q;
      axi_bypass_i.r.id    <= axi_bypass_o.ar_valid ? axi_bypass_o.ar.id : byp_id_q;
      axi_bypass_i.r.data  <= 64'hA5A5_1234_DEAD_BEEF;
      axi_bypass_i.r.last  <= 1'b1;
      axi_bypass_i.r.resp  <= 2'b00;
      if (byp_aw_seen_q && axi_bypass_i.r_valid) byp_aw_seen_q <= 1'b0;

      // the refill port: answer a cacheline read so a MISS can retire
      if (axi_data_o.ar_valid) begin dat_id_q <= axi_data_o.ar.id; dat_ar_seen_q <= 1'b1; end
      axi_data_i.r_valid <= dat_ar_seen_q;
      axi_data_i.r.id    <= dat_id_q;
      axi_data_i.r.data  <= 64'hC0DE_0000_0000_C0DE;
      axi_data_i.r.last  <= 1'b1;
      axi_data_i.r.resp  <= 2'b00;
      if (dat_ar_seen_q && axi_data_o.r_ready) dat_ar_seen_q <= 1'b0;
      axi_data_i.b_valid <= axi_data_o.w_valid & axi_data_o.w.last;
      axi_data_i.b.id    <= axi_data_o.aw.id;
      axi_data_i.b.resp  <= 2'b00;
    end
  end

  // ---- AXI channel monitor. Added after TWO failed guesses at why the DUT sits
  // in AMO_WAIT_RESP. Prints the handshake rather than reasoning about it. ----
  int unsigned mon_n = 0;
  always_ff @(posedge clk) begin
    if (rst_ni && (dut.state_q == 4'hC || dut.state_q == 4'hD) && mon_n < 12) begin
      mon_n <= mon_n + 1;
      $display("MEASURE:   AXI st=%0h | aw v/r=%0b%0b id=%0h atop=%02h | w v/r=%0b%0b last=%0b | b v=%0b id=%0h | ar v/r=%0b%0b | r v=%0b id=%0h | gnt=%0b rvalid=%0b",
        dut.state_q,
        axi_bypass_o.aw_valid, axi_bypass_i.aw_ready, axi_bypass_o.aw.id, axi_bypass_o.aw.atop,
        axi_bypass_o.w_valid,  axi_bypass_i.w_ready,  axi_bypass_o.w.last,
        axi_bypass_i.b_valid,  axi_bypass_i.b.id,
        axi_bypass_o.ar_valid, axi_bypass_i.ar_ready,
        axi_bypass_i.r_valid,  axi_bypass_i.r.id,
        dut.amo_bypass_rsp.gnt, dut.amo_bypass_rsp.valid);
    end
  end

  int unsigned ack_count, amo_ack_count;
  always_ff @(posedge clk) begin
    if (!rst_ni) begin ack_count <= 0; amo_ack_count <= 0; end
    else begin
      if (flush_ack_o)   ack_count     <= ack_count + 1;
      if (amo_resp_o.ack) amo_ack_count <= amo_ack_count + 1;
    end
  end

  // wait for the FSM to leave INIT, bounded, and SAY whether it got there
  task automatic settle(output bit ok);
    int unsigned t = 0;
    begin
      ok = 0;
      while (t < 20000) begin
        @(posedge clk); t++;
        if (dut.state_q == 4'h0) begin ok = 1; break; end   // IDLE
      end
      $display("MEASURE: settle -> state=%0h after %0d cycles  reached_IDLE=%0b", dut.state_q, t, ok);
    end
  endtask

  task automatic run_until_idle(input string tag, input int unsigned limit);
    int unsigned t = 0; bit reached = 0;
    begin
      while (t < limit) begin
        @(posedge clk); t++;
        if (dut.state_q == 4'h0) begin reached = 1; break; end
      end
      if (!reached)
        $display("MEASURE: %-22s DID NOT RETURN TO IDLE in %0d cycles (state=%0h) -- NOT A MEASUREMENT",
                 tag, limit, dut.state_q);
      else
        $display("MEASURE: %-22s returned to IDLE after %0d cycles", tag, t);
    end
  endtask

  // Deassert EVERYTHING, then wait for IDLE, then report the state the next
  // experiment actually starts from. The first version of Q4 sampled a leftover
  // flush: run_until_idle() returned the cycle the FSM reached IDLE while
  // amo_req_i.req was STILL HIGH, so the FSM re-triggered its own AMO before the
  // deassert landed. The stimulus was wrong, not the reading -- so the
  // precondition is now asserted and printed rather than assumed.
  task automatic quiesce(input string tag);
    int unsigned t = 0; bit ok = 0;
    begin
      @(negedge clk);
      amo_req_i = '0; flush_i = 1'b0; miss_req_i = '0;
      while (t < 60000) begin
        @(posedge clk); t++;
        if (dut.state_q == 4'h0) begin ok = 1; break; end
      end
      repeat (5) @(posedge clk);
      $display("MEASURE: %-20s precondition: state=%0h serve_amo_q=%0b reached_idle=%0b",
               tag, dut.state_q, dut.serve_amo_q, ok);
    end
  endtask

  int unsigned a0, a1;
  bit settled;

  initial begin
    repeat (10) @(posedge clk); rst_ni = 1'b1;
    settle(settled);
    if (!settled) begin
      $display("MEASURE: FSM never reached IDLE -- everything below would be meaningless");
      $display("TEST_RESULT: PROBE"); $finish;
    end

    // ---- Q2a: a REAL flush must acknowledge ----
    a0 = ack_count;
    @(negedge clk); flush_i = 1'b1;
    @(posedge clk); @(negedge clk); flush_i = 1'b0;
    run_until_idle("Q2a real flush", 20000);
    a1 = ack_count;
    $display("MEASURE: Q2a real flush          -> flush_ack pulses = %0d (want >=1)", a1 - a0);

    repeat (20) @(posedge clk);

    // ---- Q1/Q2b: an AMO forces a flush, and that flush must NOT acknowledge ----
    a0 = ack_count;
    @(negedge clk);
    amo_req_i.req = 1'b1; amo_req_i.amo_op = AMO_ADD;
    amo_req_i.size = 2'b11; amo_req_i.operand_a = 64'h0000_0000_8000_0040;
    amo_req_i.operand_b = 64'd7;
    @(posedge clk); #1;
    $display("MEASURE: Q1  after AMO asserted  -> state=%0h (1=FLUSHING 4=FLUSH_REQ_STATUS)", dut.state_q);
    run_until_idle("Q1/Q2b amo flush", 40000);
    a1 = ack_count;
    $display("MEASURE: Q2b AMO-induced flush   -> flush_ack pulses = %0d (want 0)", a1 - a0);
    $display("MEASURE: Q1  amo_resp acks       = %0d (want >=1: the AMO was served)", amo_ack_count);
    @(negedge clk); amo_req_i.req = 1'b0;

    repeat (20) @(posedge clk);

    // ---- Q3 THE CORNER: flush_i AND amo_req_i together ----
    a0 = ack_count;
    @(negedge clk);
    flush_i = 1'b1;
    amo_req_i.req = 1'b1; amo_req_i.amo_op = AMO_ADD;
    amo_req_i.size = 2'b11; amo_req_i.operand_a = 64'h0000_0000_8000_0080;
    amo_req_i.operand_b = 64'd9;
    @(posedge clk); @(negedge clk); flush_i = 1'b0;
    run_until_idle("Q3 flush+amo together", 40000);
    a1 = ack_count;
    $display("MEASURE: Q3  flush_i WITH amo    -> flush_ack pulses = %0d", a1 - a0);
    $display("MEASURE: Q3  reading predicts 0 -- a genuine flush request gets no ack");
    @(negedge clk); amo_req_i.req = 1'b0;

    quiesce("before Q4");

    // ---- Q4: does a miss request defer a pending AMO? ----
    a0 = amo_ack_count;
    @(negedge clk);
    amo_req_i.req = 1'b1; amo_req_i.amo_op = AMO_ADD;
    amo_req_i.size = 2'b11; amo_req_i.operand_a = 64'h0000_0000_8000_00C0;
    amo_req_i.operand_b = 64'd11;
    // port 2 raises a non-bypass miss in the SAME cycle
    miss_req_i[2] = {1'b1, 64'h0000_0000_9000_0000, 8'hFF, 2'b11, 1'b0, 64'd0, 1'b0};
    @(posedge clk); #1;
    $display("MEASURE: Q4  amo+miss same cycle -> state=%0h serve_amo_q=%0b  (7=MISS 4=FLUSH_REQ_STATUS)",
             dut.state_q, dut.serve_amo_q);
    $display("MEASURE: Q4  what the DUT saw: miss_valid=%04b miss_bypass=%04b amo_req=%0b busy=%0b",
             dut.miss_req_valid, dut.miss_req_bypass, amo_req_i.req, busy_i);
    $display("MEASURE: Q4  reading predicts state=7 and serve_amo_q=0 -- the miss clears the AMO");
    @(negedge clk); miss_req_i[2] = '0;
    repeat (40) @(posedge clk);
    quiesce("after Q4");

    // ---- Q5: is NR_PORTS a REAL arbitration axis, or fixed priority? ----
    // The landscape calls NR_PORTS "a real capability axis, and ignoring it is a
    // plausible mistake -- a design that services one requester at a time is
    // something a model writes." That decides the SCORED configuration, so it is
    // measured: all four ports raise a BYPASS request at once and the grant
    // pattern is recorded over 40 cycles.
    begin
      int unsigned seen[4]; string order = "";
      for (int k = 0; k < 4; k++) seen[k] = 0;
      @(negedge clk);
      for (int k = 0; k < 4; k++)
        miss_req_i[k] = {1'b1, 64'h0000_0000_A000_0000 + (k << 6), 8'hFF, 2'b11, 1'b0, 64'd0, 1'b1};
      for (int c = 0; c < 60; c++) begin
        @(posedge clk); #1;
        for (int k = 0; k < 4; k++)
          if (bypass_gnt_o[k]) begin
            seen[k]++;
            order = {order, $sformatf("%0d", k)};
          end
      end
      @(negedge clk); miss_req_i = '0;
      $display("MEASURE: Q5  bypass grants per port over 60 cycles: p0=%0d p1=%0d p2=%0d p3=%0d",
               seen[0], seen[1], seen[2], seen[3]);
      $display("MEASURE: Q5  grant order = %s", (order == "") ? "NONE -- no port was ever granted" : order);
      $display("MEASURE: Q5  fixed priority => only p0 nonzero; real arbitration => several move");
    end
    quiesce("after Q5");

    // ---- Q6: THE CONTROL for Q5. "only p0 granted" has two explanations:
    // fixed priority with starvation, or a malformed stimulus on ports 1-3.
    // Drive ONLY ports 1,2,3 with port 0 idle. If they are granted, the stimulus
    // was fine and Q5 measured priority. If they are not, Q5 measured my bug.
    begin
      int unsigned seen[4];
      for (int k = 0; k < 4; k++) seen[k] = 0;
      @(negedge clk);
      for (int k = 1; k < 4; k++)
        miss_req_i[k] = {1'b1, 64'h0000_0000_B000_0000 + (k << 6), 8'hFF, 2'b11, 1'b0, 64'd0, 1'b1};
      for (int c = 0; c < 60; c++) begin
        @(posedge clk); #1;
        for (int k = 0; k < 4; k++) if (bypass_gnt_o[k]) seen[k]++;
      end
      @(negedge clk); miss_req_i = '0;
      $display("MEASURE: Q6  CONTROL, port 0 idle: p0=%0d p1=%0d p2=%0d p3=%0d",
               seen[0], seen[1], seen[2], seen[3]);
      if (seen[1] + seen[2] + seen[3] == 0)
        $display("MEASURE: Q6  ports 1-3 NEVER granted even alone -- Q5 measured MY STIMULUS, not priority");
      else
        $display("MEASURE: Q6  ports 1-3 are grantable -- so Q5 measured real port-0 precedence");
    end
    quiesce("after Q6");

    $display("MEASURE: totals: flush_acks=%0d amo_acks=%0d", ack_count, amo_ack_count);
    $display("TEST_RESULT: PROBE -- not a score");
    $finish;
  end

  initial begin #4000000; $display("MEASURE: watchdog"); $display("TEST_RESULT: PROBE"); $finish; end

endmodule
