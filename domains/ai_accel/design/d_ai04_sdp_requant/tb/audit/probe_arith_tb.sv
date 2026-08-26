// probe_arith_tb.sv -- d_ai04 STEP 0, PROBE 2. Not a scoring rig.
//
// PROBE 1 ESTABLISHED: 4x16b in -> 4x32b out, one output word per input word,
// in order; identity config (offset 0, scale 1, truncate 0) is a passthrough.
//
// THIS PROBE ASKS FOUR QUESTIONS THAT READING CANNOT ANSWER:
//   Q1 ORDER      (x+offset)*scale>>t   or   (x*scale>>t)+offset ?
//                 disambiguated only when scale != 1.
//   Q2 ROUNDING   does the >>t truncate, or round? d_dsp01 died on exactly this
//                 question, so it is asked before any clause is written.
//   Q3 SIGNEDNESS of x, of offset, of scale -- three separate questions.
//   Q4 SATURATION where are the bounds, and do they move with cfg_precision?
//
// Each vector drives ONE 16b lane value into all four lanes and drains fully
// between vectors, so no result can be attributed to a stale config.

`timescale 1ns/1ps

module probe_arith_tb;

  logic clk = 1'b0, rstn = 1'b0;
  always #5 clk = ~clk;

  logic [63:0]  chn_in;
  logic         chn_in_v, chn_in_r;
  logic         cfg_bypass, cfg_nan_to_zero;
  logic [31:0]  cfg_offset;
  logic [15:0]  cfg_scale;
  logic [5:0]   cfg_truncate;
  logic [1:0]   cfg_precision;
  logic [127:0] chn_out;
  logic         chn_out_rdy = 1'b1, chn_out_v;

  NV_NVDLA_SDP_CORE_Y_cvt dut (
    .nvdla_core_clk(clk), .nvdla_core_rstn(rstn),
    .chn_in_rsc_z(chn_in), .chn_in_rsc_vz(chn_in_v), .chn_in_rsc_lz(chn_in_r),
    .cfg_bypass_rsc_z(cfg_bypass), .cfg_offset_rsc_z(cfg_offset),
    .cfg_scale_rsc_z(cfg_scale), .cfg_truncate_rsc_z(cfg_truncate),
    .cfg_nan_to_zero_rsc_z(cfg_nan_to_zero), .cfg_precision_rsc_z(cfg_precision),
    .chn_out_rsc_z(chn_out), .chn_out_rsc_vz(chn_out_rdy), .chn_out_rsc_lz(chn_out_v)
  );

  logic [127:0] got;
  int unsigned  lat;

  // drive one word, wait for its output, report lane 0 as signed
  task automatic shot(input string tag, input [15:0] x, input [31:0] off,
                      input [15:0] sc, input [5:0] tr, input [1:0] pr);
    int unsigned t;
    begin
      @(negedge clk);
      cfg_offset = off; cfg_scale = sc; cfg_truncate = tr; cfg_precision = pr;
      repeat (4) @(negedge clk);
      chn_in = {x, x, x, x};
      chn_in_v = 1'b1;
      t = 0;
      forever begin
        @(posedge clk); #1;
        if (chn_in_r) break;
        t++; if (t > 100) break;
      end
      @(negedge clk);
      chn_in_v = 1'b0;
      lat = 0; got = 128'hx;
      forever begin
        @(posedge clk); #1;
        lat++;
        if (chn_out_v && chn_out_rdy) begin got = chn_out; break; end
        if (lat > 200) break;
      end
      $display("MEASURE: %-14s x=%6d off=%6d sc=%6d tr=%0d pr=%0d -> lane0=%11d (0x%08h) lat=%0d",
               tag, $signed(x), $signed(off), $signed(sc), tr, pr,
               $signed(got[31:0]), got[31:0], lat);
      repeat (20) @(negedge clk);
    end
  endtask

  initial begin
    chn_in = 0; chn_in_v = 0; cfg_bypass = 0; cfg_nan_to_zero = 0;
    cfg_offset = 0; cfg_scale = 1; cfg_truncate = 0; cfg_precision = 0;
    repeat (8) @(posedge clk); rstn = 1'b1; repeat (8) @(posedge clk);

    $display("MEASURE: --- Q1 ORDER: (x+off)*sc  vs  x*sc+off ---");
    shot("base",     16'd4,  32'd0, 16'd1, 6'd0, 2'd0);  // 4
    shot("off_only", 16'd4,  32'd3, 16'd1, 6'd0, 2'd0);  // 7 either way
    shot("sc_only",  16'd4,  32'd0, 16'd2, 6'd0, 2'd0);  // 8 either way
    shot("ORDER",    16'd4,  32'd3, 16'd2, 6'd0, 2'd0);  // 14 = (x+off)*sc ; 11 = x*sc+off

    $display("MEASURE: --- Q2 ROUNDING on >>t ---");
    shot("t1_even",  16'd4,  32'd0, 16'd1, 6'd1, 2'd0);  // 2 either way
    shot("t1_odd5",  16'd5,  32'd0, 16'd1, 6'd1, 2'd0);  // 2 trunc ; 3 round-half-up
    shot("t1_odd3",  16'd3,  32'd0, 16'd1, 6'd1, 2'd0);  // 1 trunc ; 2 round-half-up
    shot("t1_odd7",  16'd7,  32'd0, 16'd1, 6'd1, 2'd0);  // 3 trunc ; 4 round-half-up
    shot("t2_x6",    16'd6,  32'd0, 16'd1, 6'd2, 2'd0);  // 1 trunc ; 2 round (6/4=1.5)
    shot("t2_x5",    16'd5,  32'd0, 16'd1, 6'd2, 2'd0);  // 1 trunc ; 1 round (5/4=1.25)

    $display("MEASURE: --- Q3 SIGNEDNESS ---");
    shot("x_neg",    16'hFFFB, 32'd0, 16'd1, 6'd0, 2'd0);        // -5 signed ; 65531 unsigned
    shot("x_neg_t1", 16'hFFFB, 32'd0, 16'd1, 6'd1, 2'd0);        // -3 arith-trunc ; -2 round
    shot("off_neg",  16'd10, 32'hFFFFFFFB, 16'd1, 6'd0, 2'd0);   // 5 if offset signed
    shot("sc_neg",   16'd4,  32'd0, 16'hFFFF, 6'd0, 2'd0);       // -4 if scale signed ; 262140 if not

    $display("MEASURE: --- Q4 SATURATION vs cfg_precision ---");
    shot("big_p0",   16'h7FFF, 32'd0, 16'h7FFF, 6'd0, 2'd0);
    shot("big_p1",   16'h7FFF, 32'd0, 16'h7FFF, 6'd0, 2'd1);
    shot("big_p2",   16'h7FFF, 32'd0, 16'h7FFF, 6'd0, 2'd2);
    shot("big_p3",   16'h7FFF, 32'd0, 16'h7FFF, 6'd0, 2'd3);
    shot("neg_p0",   16'h8000, 32'd0, 16'h7FFF, 6'd0, 2'd0);
    shot("neg_p1",   16'h8000, 32'd0, 16'h7FFF, 6'd0, 2'd1);
    shot("neg_p2",   16'h8000, 32'd0, 16'h7FFF, 6'd0, 2'd2);
    shot("neg_p3",   16'h8000, 32'd0, 16'h7FFF, 6'd0, 2'd3);

    $display("TEST_RESULT: PROBE -- not a score");
    $finish;
  end

  initial begin #400000; $display("MEASURE: watchdog"); $display("TEST_RESULT: PROBE"); $finish; end

endmodule
