// axi_demux_lockin_repro_tb.sv -- MINIMAL REPRODUCER, not a scoring rig.
//
// ONE QUESTION, AND IT STOPS THERE:
//
//   Under legal AXI read-response backpressure, does `axi_demux_simple`'s own
//   internal `rr_arb_tree` (LockIn=1) violate the ASSUME its instantiation
//   carries -- "It is disallowed to deassert unserved request signals when
//   LockIn is enabled"?
//
// WHY IT EXISTS. F81 records that a genuine anchor defect is "the reading most
// consistent with the evidence, AND IT IS NOT PROVEN", and names exactly what
// would prove it: a minimal reproducer against `axi_demux` alone, protocol-
// correct, showing the ASSUME violated by the anchor's own internals. That is
// also what an upstream report would need, so it is the same artefact either
// way. Four alternatives were ruled out before the anchor was suspected -- not
// a documented constraint, not a known issue, the stimulus is legal, and not the
// sustained stall itself (a staggered release trips it identically).
//
// WHAT IS AND IS NOT BEING CLAIMED. This rig does not assert the anchor is
// wrong. It puts the anchor in the condition L3 and C3 turn on and reports what
// its own assertions say. A clean run is as informative as a firing one: it
// would move the reading from "most consistent with the evidence" to "refuted",
// and L3/C3's untestability would then be ours to explain.
//
// THE MECHANISM UNDER TEST, from the anchor's source:
//   rr_arb_tree.sv:167  ASSERT(lock, req_o && !gnt_i && !flush_i |=> idx_o == $past(idx_o))
//   rr_arb_tree.sv:173  ASSUME(lock_req, lock_d |=> req_tmp == req_q)
// In axi_demux_simple the arbiter's `req_i` is `mst_r_valids` -- a PASSTHROUGH,
// `assign mst_r_valids[i] = mst_resps_i[i].r_valid` -- and its `gnt_i` is the
// downstream `r_ready`. Holding `r_ready` low is permitted: ready carries no
// stability requirement in AXI. That locks the arbiter.
//
// The direct observation is therefore: WITH THE ARBITER LOCKED (a request up,
// grant low), DOES ANY UNSERVED REQUEST BIT FALL? That is read off
// `mst_r_valids` hierarchically rather than inferred from a downstream symptom,
// so a hit names the mechanism and not a consequence of it.

`timescale 1ns/1ps

`include "axi/typedef.svh"
`include "axi/assign.svh"

module axi_demux_lockin_repro_tb;

  localparam int unsigned AW      = 32;
  localparam int unsigned DW      = 64;
  localparam int unsigned IW      = 4;
  localparam int unsigned UW      = 1;
  localparam int unsigned NO_MST  = 2;     // two ports: the minimum that arbitrates
  localparam int unsigned MAXTR   = 8;
  localparam int unsigned SEL_W   = (NO_MST > 1) ? $clog2(NO_MST) : 1;

  typedef logic [AW-1:0]   addr_t;
  typedef logic [DW-1:0]   data_t;
  typedef logic [IW-1:0]   id_t;
  typedef logic [DW/8-1:0] strb_t;
  typedef logic [UW-1:0]   user_t;
  typedef logic [SEL_W-1:0] select_t;

  `AXI_TYPEDEF_ALL(axi, addr_t, id_t, data_t, strb_t, user_t)

  logic clk = 1'b0, rst_n = 1'b0;
  always #5 clk = ~clk;

  axi_req_t                 slv_req;
  axi_resp_t                slv_resp;
  axi_req_t  [NO_MST-1:0]   mst_reqs;
  axi_resp_t [NO_MST-1:0]   mst_resps;
  select_t                  ar_select, aw_select;

  axi_demux_simple #(
    .AxiIdWidth  (IW),
    .AtopSupport (1'b0),
    .axi_req_t   (axi_req_t),
    .axi_resp_t  (axi_resp_t),
    .NoMstPorts  (NO_MST),
    .MaxTrans    (MAXTR),
    .AxiLookBits (3),
    .UniqueIds   (1'b0)
  ) dut (
    .clk_i           (clk),
    .rst_ni          (rst_n),
    .test_i          (1'b0),
    .slv_req_i       (slv_req),
    .slv_aw_select_i (aw_select),
    .slv_ar_select_i (ar_select),
    .slv_resp_o      (slv_resp),
    .mst_reqs_o      (mst_reqs),
    .mst_resps_i     (mst_resps)
  );

  // ---------------------------------------------------------------------------
  // Slave models. Each accepts every AR immediately and then offers R beats.
  //
  // PROTOCOL-CORRECT BY CONSTRUCTION, because a rig that drives the anchor
  // illegally proves nothing about the anchor -- F81's own first mistake was an
  // apparatus that violated the protocol it imposed and reported the result as a
  // design failure. Once `r_valid` rises it is HELD until `r_ready`, per AXI, and
  // nothing else about the R channel moves in the meantime.
  // ---------------------------------------------------------------------------
  localparam int unsigned BEATS = 4;

  int unsigned beat_cnt [NO_MST];
  logic        rv_q     [NO_MST];
  id_t         rid_q    [NO_MST];

  always_ff @(posedge clk or negedge rst_n) begin
    for (int m = 0; m < NO_MST; m++) begin
      if (!rst_n) begin
        beat_cnt[m] <= 0;
        rv_q[m]     <= 1'b0;
        rid_q[m]    <= '0;
      end else begin
        // accept an AR whenever offered
        if (mst_reqs[m].ar_valid && !rv_q[m]) begin
          rv_q[m]     <= 1'b1;
          rid_q[m]    <= mst_reqs[m].ar.id;
          beat_cnt[m] <= BEATS;
        // HOLD r_valid until the handshake completes -- the AXI requirement
        end else if (rv_q[m] && mst_reqs[m].r_ready) begin
          if (beat_cnt[m] > 1) beat_cnt[m] <= beat_cnt[m] - 1;
          else                 rv_q[m]     <= 1'b0;
        end
      end
    end
  end

  always_comb begin
    for (int m = 0; m < NO_MST; m++) begin
      mst_resps[m]            = '0;
      mst_resps[m].ar_ready   = !rv_q[m];
      mst_resps[m].aw_ready   = 1'b1;
      mst_resps[m].w_ready    = 1'b1;
      mst_resps[m].r_valid    = rv_q[m];
      mst_resps[m].r.id       = rid_q[m];
      mst_resps[m].r.data     = {DW{1'b0}} | (m + 1);
      mst_resps[m].r.resp     = 2'b00;
      mst_resps[m].r.last     = (beat_cnt[m] == 1);
      mst_resps[m].r.user     = '0;
    end
  end

  // ---------------------------------------------------------------------------
  // THE OBSERVATION. Read the arbiter's own request and grant, not a symptom.
  // ---------------------------------------------------------------------------
  logic [NO_MST-1:0] req_now, req_prev;
  logic              gnt_now;
  int unsigned       violations, locked_cycles, served;
  logic              armed;

  assign req_now = {mst_resps[1].r_valid, mst_resps[0].r_valid};  // the arbiter's req_i
  assign gnt_now = slv_req.r_ready;                               // the arbiter's gnt_i

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      req_prev <= '0; violations <= 0; locked_cycles <= 0; armed <= 1'b0; served <= 0;
    end else begin
      // LOCKED: a request is up and the grant is low. In that state the ASSUME
      // says no unserved request bit may fall.
      if (armed && |req_prev && !gnt_now) begin
        locked_cycles <= locked_cycles + 1;
        if ((req_prev & ~req_now) != '0) begin
          violations <= violations + 1;
          $display("LOCKIN VIOLATION t=%0t: req %b -> %b with gnt=0 (an unserved request was deasserted)",
                   $time, req_prev, req_now);
        end
      end
      if (slv_resp.r_valid && slv_req.r_ready) served <= served + 1;
      req_prev <= req_now;
      armed    <= 1'b1;
    end
  end

  // ---------------------------------------------------------------------------
  // Stimulus: two reads, one per master port, then hold r_ready LOW.
  // ---------------------------------------------------------------------------
  task automatic send_ar(input select_t sel, input id_t id);
    @(negedge clk);
    slv_req.ar_valid = 1'b1;
    slv_req.ar.id    = id;
    slv_req.ar.addr  = 32'h1000 + (sel << 8);
    slv_req.ar.len   = BEATS - 1;
    slv_req.ar.size  = 3'd3;
    slv_req.ar.burst = 2'b01;
    ar_select        = sel;
    do @(posedge clk); while (!slv_resp.ar_ready);
    @(negedge clk);
    slv_req.ar_valid = 1'b0;
  endtask

  initial begin
    slv_req = '0; aw_select = '0; ar_select = '0;
    slv_req.r_ready = 1'b0;
    slv_req.b_ready = 1'b1;
    repeat (4) @(posedge clk);
    rst_n = 1'b1;
    @(posedge clk);

    // Both ports get an outstanding read, so the arbiter has two requests.
    send_ar(select_t'(0), id_t'(1));
    send_ar(select_t'(1), id_t'(2));

    // THE CONDITION L3 AND C3 TURN ON: the master stalls the read response.
    // r_ready stays low. Legal AXI, indefinitely.
    slv_req.r_ready = 1'b0;
    repeat (200) @(posedge clk);

    // Release, so the run also shows the anchor makes progress afterwards --
    // otherwise a clean result could mean the rig never reached the R channel.
    slv_req.r_ready = 1'b1;
    repeat (200) @(posedge clk);

    $display("METRIC: locked_cycles=%0d  r_beats_served=%0d  lockin_violations=%0d",
             locked_cycles, served, violations);

    // BOTH FLOORS, because either alone can report a clean run that measured
    // nothing: the arbiter must actually have been locked, AND the R channel
    // must actually have carried traffic once released.
    if (locked_cycles == 0) begin
      $display("TEST_RESULT: FAIL: the arbiter was never locked -- no request was up while the grant was low, so nothing was tested");
    end else if (served == 0) begin
      $display("TEST_RESULT: FAIL: no R beat was ever served -- the rig never reached the read channel, so a clean result means nothing");
    end else if (violations == 0) begin
      $display("TEST_RESULT: PASS: %0d locked cycles, %0d beats served, no unserved request deasserted -- the ASSUME HOLDS here", locked_cycles, served);
    end else begin
      $display("TEST_RESULT: FAIL: %0d LockIn ASSUME violations in %0d locked cycles",
               violations, locked_cycles);
    end
    $finish;
  end

  initial begin
    #200000;
    $display("TEST_RESULT: FAIL: watchdog -- the reproducer hung");
    $finish;
  end

endmodule
