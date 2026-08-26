// probe_fp_edges_tb.sv -- d_ai04 STEP 0, PROBE 8. Not a scoring rig.
//
// MEASUREMENTS.md listed "the fp16 subnormal boundary" under Not measured. The
// spec is about to be written, and a spec clause covering a case nobody measured
// is the d_dsp01 failure with extra steps. So the float mode's edges are pinned
// before anything is written down about them.
//
// Each row carries the transfer count, per probe 7: zero is a legitimate output
// of this DUT, so a value alone cannot say whether a measurement happened.

`timescale 1ns/1ps

module probe_fp_edges_tb;

  logic clk = 1'b0, rstn = 1'b0;
  always #5 clk = ~clk;

  logic [63:0]  chn_in = 0; logic chn_in_v = 0, chn_in_r;
  logic         cfg_n2z = 0;
  logic [127:0] chn_out;    logic chn_out_rdy = 1, chn_out_v;

  NV_NVDLA_SDP_CORE_Y_cvt dut (
    .nvdla_core_clk(clk), .nvdla_core_rstn(rstn),
    .chn_in_rsc_z(chn_in), .chn_in_rsc_vz(chn_in_v), .chn_in_rsc_lz(chn_in_r),
    .cfg_bypass_rsc_z(1'b0), .cfg_offset_rsc_z(32'd0), .cfg_scale_rsc_z(16'd1),
    .cfg_truncate_rsc_z(6'd0), .cfg_nan_to_zero_rsc_z(cfg_n2z), .cfg_precision_rsc_z(2'd2),
    .chn_out_rsc_z(chn_out), .chn_out_rsc_vz(chn_out_rdy), .chn_out_rsc_lz(chn_out_v)
  );

  logic [127:0] got; int unsigned nx;

  task automatic shot(input string tag, input [15:0] x, input bit n2z, input string want);
    int unsigned t;
    begin
      @(negedge clk); cfg_n2z = n2z; repeat (3) @(negedge clk);
      chn_in = {x,x,x,x}; chn_in_v = 1'b1;
      t=0; forever begin @(posedge clk); #1; if (chn_in_r) break; t++; if (t>100) break; end
      @(negedge clk); chn_in_v = 1'b0;
      t=0; got=0; nx=0;
      forever begin @(posedge clk); #1; t++;
        if (chn_out_v && chn_out_rdy) begin got=chn_out; nx=1; break; end
        if (t>200) break; end
      if (nx==0) $display("MEASURE: %-12s NO TRANSFER -- not a measurement", tag);
      else $display("MEASURE: %-12s in=0x%04h -> 0x%08h   want %s", tag, x, got[31:0], want);
      repeat (12) @(negedge clk);
    end
  endtask

  initial begin
    repeat (8) @(posedge clk); rstn = 1'b1; repeat (8) @(posedge clk);

    $display("MEASURE: --- zeros ---");
    shot("pos_zero",  16'h0000, 0, "0x00000000");
    shot("neg_zero",  16'h8000, 0, "0x80000000");

    $display("MEASURE: --- subnormals: converted exactly, or flushed to zero? ---");
    shot("sub_min",   16'h0001, 0, "exact 2^-24 = 0x33800000 ; FTZ = 0x00000000");
    shot("sub_mid",   16'h0200, 0, "exact 2^-15 = 0x38000000 ; FTZ = 0");
    shot("sub_max",   16'h03FF, 0, "exact = 0x387FC000 ; FTZ = 0");
    shot("sub_neg",   16'h8001, 0, "exact = 0xB3800000 ; FTZ = 0x80000000");

    $display("MEASURE: --- the normal boundary ---");
    shot("norm_min",  16'h0400, 0, "2^-14 = 0x38800000");
    shot("norm_max",  16'h7BFF, 0, "65504 = 0x477FE000");
    shot("neg_nmax",  16'hFBFF, 0, "-65504 = 0xC77FE000");

    $display("MEASURE: --- infinities and NaN payloads ---");
    shot("pos_inf",   16'h7C00, 0, "FLT_MAX 0x7F7FFFFF (measured earlier)");
    shot("neg_inf",   16'hFC00, 0, "-FLT_MAX 0xFF7FFFFF if symmetric");
    shot("nan_q",     16'h7E00, 0, "0x7F800200 (measured earlier)");
    shot("nan_s",     16'h7C01, 0, "payload in low bits => 0x7F800001");
    shot("nan_neg",   16'hFE00, 0, "sign preserved => 0xFF800200");
    shot("nan_q_n2z", 16'h7E00, 1, "0x00000000");
    shot("nan_neg_n2z", 16'hFE00, 1, "0x00000000");
    shot("inf_n2z",   16'h7C00, 1, "inf is NOT NaN -- expect FLT_MAX, unchanged");

    $display("TEST_RESULT: PROBE -- not a score");
    $finish;
  end

  initial begin #500000; $display("MEASURE: watchdog"); $display("TEST_RESULT: PROBE"); $finish; end

endmodule
