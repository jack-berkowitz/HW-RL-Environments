// probe_handshake_tb.sv -- d_ai04 STEP 0, PROBE 1. Not a scoring rig.
//
// ONE QUESTION: what is the handshake, and how many cycles from an accepted
// input to a valid output?
//
// WHY A PROBE AT ALL, AND WHY EVERY CLAUSE WILL COME FROM ONE. The anchor is
// CATAPULT HLS OUTPUT -- 2,721 machine-generated lines whose readable part is
// the Mentor library wrappers, not the arithmetic. THE SOURCE IS NOT A
// SPECIFICATION. F54 is the precedent from the other direction: d_dsp01
// satisfied rule 11 exactly and its anchor was correctly rounded in no mode but
// RTZ, and the task was withdrawn rather than faked. So nothing here is inferred
// from reading the RTL.
//
// THE HANDSHAKE IS THE ONE THING THAT CAN BE READ, because the wrappers are
// library code rather than synthesis output:
//
//   SDP_Y_CVT_mgc_in_wire_wait_v1     assign d = z;  assign lz = ld;  assign vd = vz;
//   SDP_Y_CVT_mgc_out_stdreg_wait_v1  assign z = d;  assign lz = ld;  assign vd = vz;
//
// Both are pure passthroughs, and `vz` is ALWAYS the incoming signal while `lz`
// is ALWAYS the outgoing one. So at the module boundary:
//
//   chn_in_rsc_vz    IN   producer's VALID
//   chn_in_rsc_lz    OUT  design's READY
//   chn_out_rsc_vz   IN   consumer's READY
//   chn_out_rsc_lz   OUT  design's VALID
//
// That is read, not measured, and it is the only thing in this file that is.

`timescale 1ns/1ps

module probe_handshake_tb;

  logic        clk = 1'b0, rstn = 1'b0;
  always #5 clk = ~clk;

  logic [63:0]  chn_in;
  logic         chn_in_v, chn_in_r;
  logic         cfg_bypass;
  logic [31:0]  cfg_offset;
  logic [15:0]  cfg_scale;
  logic [5:0]   cfg_truncate;
  logic         cfg_nan_to_zero;
  logic [1:0]   cfg_precision;
  logic [127:0] chn_out;
  logic         chn_out_rdy, chn_out_v;

  NV_NVDLA_SDP_CORE_Y_cvt dut (
    .nvdla_core_clk        (clk),
    .nvdla_core_rstn       (rstn),
    .chn_in_rsc_z          (chn_in),
    .chn_in_rsc_vz         (chn_in_v),
    .chn_in_rsc_lz         (chn_in_r),
    .cfg_bypass_rsc_z      (cfg_bypass),
    .cfg_offset_rsc_z      (cfg_offset),
    .cfg_scale_rsc_z       (cfg_scale),
    .cfg_truncate_rsc_z    (cfg_truncate),
    .cfg_nan_to_zero_rsc_z (cfg_nan_to_zero),
    .cfg_precision_rsc_z   (cfg_precision),
    .chn_out_rsc_z         (chn_out),
    .chn_out_rsc_vz        (chn_out_rdy),
    .chn_out_rsc_lz        (chn_out_v)
  );

  int unsigned accepted, produced, first_out_cycle, cyc;
  logic [127:0] first_out;

  always_ff @(posedge clk) begin
    if (!rstn) begin
      accepted <= 0; produced <= 0; cyc <= 0; first_out_cycle <= 0;
    end else begin
      cyc <= cyc + 1;
      if (chn_in_v  && chn_in_r)   accepted <= accepted + 1;
      if (chn_out_v && chn_out_rdy) begin
        produced <= produced + 1;
        if (produced == 0) begin
          first_out_cycle <= cyc;
          first_out       <= chn_out;
        end
      end
    end
  end

  initial begin
    chn_in = 64'd0; chn_in_v = 1'b0; chn_out_rdy = 1'b1;
    cfg_bypass = 1'b0; cfg_offset = 32'd0; cfg_scale = 16'd1;
    cfg_truncate = 6'd0; cfg_nan_to_zero = 1'b0; cfg_precision = 2'd0;

    repeat (8) @(posedge clk);
    rstn = 1'b1;
    repeat (8) @(posedge clk);

    $display("MEASURE: after reset, ready=%0b valid=%0b", chn_in_r, chn_out_v);

    // ONE known word. identity config: offset 0, scale 1, truncate 0.
    @(negedge clk);
    chn_in   = 64'h0008_0007_0006_0005;
    chn_in_v = 1'b1;
    // wait for it to be taken, bounded
    for (int t = 0; t < 200; t++) begin
      @(posedge clk); #1;
      if (chn_in_r) break;
    end
    @(negedge clk);
    chn_in_v = 1'b0;

    repeat (300) @(posedge clk);

    $display("MEASURE: accepted=%0d produced=%0d", accepted, produced);
    if (produced > 0)
      $display("MEASURE: first output = %032h at cycle %0d", first_out, first_out_cycle);
    else
      $display("MEASURE: NO OUTPUT -- the handshake reading is wrong, or more input is needed");
    $display("TEST_RESULT: PROBE -- not a score");
    $finish;
  end

  initial begin
    #200000;
    $display("MEASURE: watchdog");
    $display("TEST_RESULT: PROBE -- not a score");
    $finish;
  end

endmodule
