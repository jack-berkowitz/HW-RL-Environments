// probe_capacity_tb.sv -- d_ai04 STEP 0, PROBE 5. Not a scoring rig.
//
// PROBE 4 RETURNED TWO NUMBERS THAT CANNOT BOTH BE THE CAPACITY: it counted 2
// accepts after the stall and then drained 3. The difference is an artefact of
// where probe 4 sampled, not of the DUT -- but "how many words fit behind a
// stalled consumer" is going to be a SPEC CLAUSE, and a spec clause that is off
// by one fails every correct candidate or passes every incorrect one. So it is
// measured again, from a clean start, with the consumer stalled from before the
// first word rather than part-way in.

`timescale 1ns/1ps

module probe_capacity_tb;

  logic clk = 1'b0, rstn = 1'b0;
  always #5 clk = ~clk;

  logic [63:0]  chn_in = 0; logic chn_in_v = 0, chn_in_r;
  logic [127:0] chn_out;    logic chn_out_rdy = 0, chn_out_v;

  NV_NVDLA_SDP_CORE_Y_cvt dut (
    .nvdla_core_clk(clk), .nvdla_core_rstn(rstn),
    .chn_in_rsc_z(chn_in), .chn_in_rsc_vz(chn_in_v), .chn_in_rsc_lz(chn_in_r),
    .cfg_bypass_rsc_z(1'b0), .cfg_offset_rsc_z(32'd0), .cfg_scale_rsc_z(16'd1),
    .cfg_truncate_rsc_z(6'd0), .cfg_nan_to_zero_rsc_z(1'b0), .cfg_precision_rsc_z(2'd0),
    .chn_out_rsc_z(chn_out), .chn_out_rsc_vz(chn_out_rdy), .chn_out_rsc_lz(chn_out_v)
  );

  int unsigned acc = 0, prod = 0, q[$];
  bit ok = 1;

  always @(posedge clk) if (rstn) begin
    if (chn_in_v  && chn_in_r)   begin q.push_back(chn_in[15:0]); acc++; end
    if (chn_out_v && chn_out_rdy) begin
      prod++;
      if (q.size()==0 || chn_out[31:0] !== q[0]) ok = 0;
      if (q.size()) void'(q.pop_front());
    end
  end

  int unsigned i, cap;

  initial begin
    repeat (8) @(posedge clk); rstn = 1'b1; repeat (8) @(posedge clk);

    // consumer stalled from BEFORE the first word. offer forever, distinct data.
    @(negedge clk); chn_out_rdy = 1'b0;
    for (i = 1; i <= 40; i++) begin
      @(negedge clk); chn_in = {16'hAAAA,16'hBBBB,16'hCCCC,i[15:0]}; chn_in_v = 1'b1;
      @(posedge clk);
    end
    @(negedge clk); chn_in_v = 1'b0;
    cap = acc;
    $display("MEASURE: capacity with consumer stalled throughout = %0d words (ready=%0b)", cap, chn_in_r);

    // is the stall stable? offer 20 more cycles, nothing must be taken.
    @(negedge clk); chn_in_v = 1'b1; chn_in = {16'h0,16'h0,16'h0,16'hFFFF};
    repeat (20) @(posedge clk);
    @(negedge clk); chn_in_v = 1'b0;
    $display("MEASURE: further accepts while still stalled = %0d (want 0)", acc - cap);

    // lift the stall and drain
    @(negedge clk); chn_out_rdy = 1'b1;
    repeat (60) @(posedge clk);
    $display("MEASURE: drained: accepted=%0d produced=%0d in_order_and_valued=%0b leftover=%0d",
             acc, prod, ok, q.size());
    $display("MEASURE: lossless=%0s", (acc == prod && ok && q.size()==0) ? "YES" : "NO");

    $display("TEST_RESULT: PROBE -- not a score");
    $finish;
  end

  initial begin #400000; $display("MEASURE: watchdog"); $display("TEST_RESULT: PROBE"); $finish; end

endmodule
