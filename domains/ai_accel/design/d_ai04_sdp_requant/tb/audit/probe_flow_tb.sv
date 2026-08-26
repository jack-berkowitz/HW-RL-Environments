// probe_flow_tb.sv -- d_ai04 STEP 0, PROBE 4. Not a scoring rig.
//
// Probes 1-3 measured the ARITHMETIC. Every clause they support is combinational
// in character, and a task made only of those is a Mechanism-C task -- ordinary
// data-path arithmetic, the kind models already do well. Whether d_ai04 is worth
// building at all turns on what is measured HERE, because backpressure is the
// only axis with sequential content in it.
//
//   Q10 BUFFER DEPTH   with the consumer stalled, how many words are accepted
//                      before ready drops? that is the storage the design owes.
//   Q11 LOSSLESS       when the stall lifts, do exactly the accepted words come
//                      out, in order, unduplicated? a stall that drops or repeats
//                      is the classic HLS handshake defect.
//   Q12 STEADY II      with both sides open, is it one word per cycle?
//   Q13 READY PATH     is chn_in_lz combinational from chn_out_vz, or registered?
//                      this is the difference between "add a skid buffer" and
//                      "wire it through", and it is invisible in the arithmetic.

`timescale 1ns/1ps

module probe_flow_tb;

  logic clk = 1'b0, rstn = 1'b0;
  always #5 clk = ~clk;

  logic [63:0]  chn_in;  logic chn_in_v = 0, chn_in_r;
  logic [127:0] chn_out; logic chn_out_rdy = 1, chn_out_v;

  NV_NVDLA_SDP_CORE_Y_cvt dut (
    .nvdla_core_clk(clk), .nvdla_core_rstn(rstn),
    .chn_in_rsc_z(chn_in), .chn_in_rsc_vz(chn_in_v), .chn_in_rsc_lz(chn_in_r),
    .cfg_bypass_rsc_z(1'b0), .cfg_offset_rsc_z(32'd0),
    .cfg_scale_rsc_z(16'd1), .cfg_truncate_rsc_z(6'd0),
    .cfg_nan_to_zero_rsc_z(1'b0), .cfg_precision_rsc_z(2'd0),
    .chn_out_rsc_z(chn_out), .chn_out_rsc_vz(chn_out_rdy), .chn_out_rsc_lz(chn_out_v)
  );

  int unsigned sent, rcvd, expect_q[$];
  bit          order_ok = 1;
  int unsigned n_mismatch = 0;

  // scoreboard: every accepted word's lane0 is queued; every produced word checked
  always @(posedge clk) begin
    if (rstn) begin
      if (chn_in_v && chn_in_r) begin expect_q.push_back(chn_in[15:0]); sent++; end
      if (chn_out_v && chn_out_rdy) begin
        rcvd++;
        if (expect_q.size() == 0) begin order_ok = 0; n_mismatch++; end
        else begin
          automatic int unsigned e = expect_q.pop_front();
          if (chn_out[31:0] !== e) begin order_ok = 0; n_mismatch++; end
        end
      end
    end
  end

  int unsigned depth, i;
  logic r_before, r_after;

  initial begin
    chn_in = 0;
    repeat (8) @(posedge clk); rstn = 1'b1; repeat (8) @(posedge clk);

    // ---- Q10: stall the consumer, feed until ready drops ----
    @(negedge clk); chn_out_rdy = 1'b0;
    depth = 0;
    for (i = 1; i <= 64; i++) begin
      @(negedge clk); chn_in = {16'd0,16'd0,16'd0,i[15:0]}; chn_in_v = 1'b1;
      @(posedge clk); #1;
      if (!chn_in_r) begin @(negedge clk); chn_in_v = 1'b0; break; end
      depth++;
    end
    @(negedge clk); chn_in_v = 1'b0;
    $display("MEASURE: Q10 words accepted with consumer stalled = %0d (ready now %0b)",
             depth, chn_in_r);

    // ---- Q11: lift the stall, drain, check count and order ----
    @(negedge clk); chn_out_rdy = 1'b1;
    repeat (64) @(posedge clk);
    $display("MEASURE: Q11 after drain: sent=%0d rcvd=%0d order_ok=%0b mismatches=%0d queue_left=%0d",
             sent, rcvd, order_ok, n_mismatch, expect_q.size());

    // ---- Q12: steady state, both sides open ----
    sent = 0; rcvd = 0; expect_q.delete(); order_ok = 1; n_mismatch = 0;
    @(negedge clk); chn_out_rdy = 1'b1;
    for (i = 1; i <= 32; i++) begin
      @(negedge clk); chn_in = {16'd0,16'd0,16'd0,i[15:0]}; chn_in_v = 1'b1;
      @(posedge clk); #1;
      while (!chn_in_r) begin @(posedge clk); #1; end
    end
    @(negedge clk); chn_in_v = 1'b0;
    repeat (32) @(posedge clk);
    $display("MEASURE: Q12 open-flow: sent=%0d rcvd=%0d in 32 offers -> II=%s",
             sent, rcvd, (sent == 32) ? "1" : "greater than 1");
    $display("MEASURE: Q12 order_ok=%0b mismatches=%0d", order_ok, n_mismatch);

    // ---- Q13: is input ready combinational from output ready? ----
    @(negedge clk); chn_out_rdy = 1'b1; chn_in_v = 1'b1; chn_in = 64'd7;
    #1; r_before = chn_in_r;
    chn_out_rdy = 1'b0; #1; r_after = chn_in_r;
    $display("MEASURE: Q13 same-instant toggle of out_rdy 1->0: in_ready %0b -> %0b => %s",
             r_before, r_after,
             (r_before !== r_after) ? "COMBINATIONAL path" : "no same-cycle path seen");
    @(negedge clk); chn_in_v = 1'b0; chn_out_rdy = 1'b1;

    $display("TEST_RESULT: PROBE -- not a score");
    $finish;
  end

  initial begin #400000; $display("MEASURE: watchdog"); $display("TEST_RESULT: PROBE"); $finish; end

endmodule
