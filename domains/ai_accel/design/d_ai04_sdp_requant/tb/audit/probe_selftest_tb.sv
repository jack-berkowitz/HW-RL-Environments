// probe_selftest_tb.sv -- d_ai04 STEP 0, PROBE 7. This one probes THE PROBES.
//
// A2 found that check_artefact_warnings.py returned "OK: no task-owned artefact
// drew a warning" when handed an EMPTY log -- true, useless, and indistinguishable
// from a clean build. Their reading: validating an instrument against the inputs
// it was designed for is not validating it, and the third input -- neither a
// defect nor a repair -- is where it breaks.
//
// PROBES 2, 3 AND 6 HAVE THAT DEFECT. Their shot() task does this:
//
//     got = 128'hx;
//     forever begin @(posedge clk); if (out_v && out_rdy) begin got=...; break; end
//                   if (t>200) break; end
//     $display("MEASURE: ... -> 0x%08h", got[31:0]);
//
// On timeout the loop breaks and the MEASURE line prints ANYWAY, in exactly the
// shape of a real result. Nothing in the line declares whether a transfer
// happened. Every row of the evidence table in MEASUREMENTS.md is one of those
// lines, so if one had timed out the table would carry it as data.
//
// This file does two things:
//   PART A  runs a vector in a DEGENERATE configuration where no output can
//           occur, and shows what the old form prints versus the new form.
//   PART B  re-runs the six load-bearing vectors from the evidence table with
//           the transfer count printed beside each, so an empty answer has to
//           declare that it is empty.

`timescale 1ns/1ps

module probe_selftest_tb;

  logic clk = 1'b0, rstn = 1'b0;
  always #5 clk = ~clk;

  logic [63:0]  chn_in = 0; logic chn_in_v = 0, chn_in_r;
  logic [31:0]  cfg_offset = 0; logic [15:0] cfg_scale = 1; logic [5:0] cfg_truncate = 0;
  logic [1:0]   cfg_precision = 0; logic cfg_bypass = 0, cfg_nan_to_zero = 0;
  logic [127:0] chn_out;    logic chn_out_rdy = 1, chn_out_v;

  NV_NVDLA_SDP_CORE_Y_cvt dut (
    .nvdla_core_clk(clk), .nvdla_core_rstn(rstn),
    .chn_in_rsc_z(chn_in), .chn_in_rsc_vz(chn_in_v), .chn_in_rsc_lz(chn_in_r),
    .cfg_bypass_rsc_z(cfg_bypass), .cfg_offset_rsc_z(cfg_offset), .cfg_scale_rsc_z(cfg_scale),
    .cfg_truncate_rsc_z(cfg_truncate), .cfg_nan_to_zero_rsc_z(cfg_nan_to_zero),
    .cfg_precision_rsc_z(cfg_precision),
    .chn_out_rsc_z(chn_out), .chn_out_rsc_vz(chn_out_rdy), .chn_out_rsc_lz(chn_out_v)
  );

  logic [127:0] got;
  int unsigned  n_xfer, n_timeout = 0;

  // The corrected form: the transfer count travels WITH the value, and a vector
  // that produced nothing says so instead of printing x's in a data-shaped row.
  task automatic shot(input string tag, input [15:0] x, input [31:0] off,
                      input [15:0] sc, input [5:0] tr, input [1:0] pr, input string want);
    int unsigned t;
    begin
      @(negedge clk); cfg_offset=off; cfg_scale=sc; cfg_truncate=tr; cfg_precision=pr;
      repeat (4) @(negedge clk);
      chn_in = {x,x,x,x}; chn_in_v = 1'b1;
      t=0; forever begin @(posedge clk); #1; if (chn_in_r) break; t++; if (t>100) break; end
      @(negedge clk); chn_in_v = 1'b0;
      t=0; got=128'hx; n_xfer=0;
      forever begin @(posedge clk); #1; t++;
        if (chn_out_v && chn_out_rdy) begin got = chn_out; n_xfer=1; break; end
        if (t>200) break; end
      if (n_xfer == 0) begin
        n_timeout++;
        $display("MEASURE: %-11s NO TRANSFER in 200 cycles -- THIS IS NOT A MEASUREMENT", tag);
      end else
        $display("MEASURE: %-11s xfers=%0d -> 0x%08h (%12d)   want %s",
                 tag, n_xfer, got[31:0], $signed(got[31:0]), want);
      repeat (16) @(negedge clk);
    end
  endtask

  initial begin
    repeat (8) @(posedge clk); rstn = 1'b1; repeat (8) @(posedge clk);

    $display("MEASURE: === PART A: the degenerate input, consumer never ready ===");
    @(negedge clk); chn_out_rdy = 1'b0; repeat (2) @(negedge clk);
    // First, what the OLD form would have printed for this same vector.
    begin
      int unsigned t; logic [127:0] g = 128'hx;
      @(negedge clk); cfg_offset=32'd291; cfg_scale=16'd37; cfg_truncate=6'd3;
      chn_in = {4{16'd4660}}; chn_in_v = 1'b1;
      t=0; forever begin @(posedge clk); #1; if (chn_in_r) break; t++; if (t>100) break; end
      @(negedge clk); chn_in_v = 1'b0;
      t=0; forever begin @(posedge clk); #1; t++;
        if (chn_out_v && chn_out_rdy) begin g = chn_out; break; end
        if (t>200) break; end
      $display("MEASURE: OLD FORM  -> 0x%08h (%12d)      <-- a data-shaped row, no transfer occurred",
               g[31:0], $signed(g[31:0]));
    end
    shot("degenerate", 16'd4660, 32'd291, 16'd37, 6'd3, 2'd0, "nothing");
    @(negedge clk); chn_out_rdy = 1'b1;

    $display("MEASURE: === PART B: the six load-bearing rows, re-run with xfer counts ===");
    shot("offset_sub",  16'd4,    32'd3,        16'd1,    6'd0,  2'd0, "1  (7 if added)");
    shot("offset_3par", 16'd4660, 32'd291,      16'd37,   6'd3,  2'd0, "20207 (22898 if added)");
    shot("ties_away",   16'hFFF7, 32'd0,        16'd1,    6'd2,  2'd0, "-2 (-3 if arith shift)");
    shot("sat_int32",   16'h7FFF, 32'hFFFF0001, 16'h7FFF, 6'd0,  2'd0, "0x7fffffff");
    shot("wide_t46",    16'd0,    32'h80000000, 16'h7FFF, 6'd46, 2'd0, "1 (0 if 32b intermediate)");
    shot("p3_eq_p0",    16'd4660, 32'd291,      16'd37,   6'd3,  2'd3, "20207, same as p0");

    $display("MEASURE: timeouts across this run = %0d (PART A must contribute exactly 1)", n_timeout);
    $display("TEST_RESULT: PROBE -- not a score");
    $finish;
  end

  initial begin #600000; $display("MEASURE: watchdog"); $display("TEST_RESULT: PROBE"); $finish; end

endmodule
