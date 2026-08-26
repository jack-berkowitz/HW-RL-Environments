// probe_modes_tb.sv -- d_ai04 STEP 0, PROBE 3. Not a scoring rig.
//
// PROBE 2 RETURNED TWO RESULTS THAT CONTRADICT WHAT THE PORT NAMES SUGGEST, so
// neither is written down until it survives a second, differently-shaped probe:
//
//   (a) offset SUBTRACTS.  x=4 off=3 sc=1 -> 1, not 7.  x=10 off=-5 -> 15.
//       so the candidate law is (x - offset) * scale >> truncate.
//   (b) cfg_precision==2 IS NOT AN INTEGER MODE.  x=0x8000 -> 0x80000000, which
//       is fp16 -0.0 -> fp32 -0.0, and x=0x7FFF (an fp16 NaN) -> 0x7F8003FF,
//       a NaN. p0/p1/p3 were byte-identical to each other on both vectors.
//
// QUESTIONS HERE:
//   Q5 is the rounding half-away-from-zero, or is +5->3 / -5->-3 a coincidence
//      of two different rules? asked with the halves on both signs.
//   Q6 does saturation exist at all? probe 2 never overflowed 32 bits, so its
//      "no saturation" reading is worth nothing. this pushes past 2^31.
//   Q7 in p2, do offset/scale/truncate do ANYTHING, or is it pure conversion?
//   Q8 are p0, p1, p3 actually the same mode wearing three codes?
//   Q9 nan_to_zero and bypass, on a real fp16 NaN rather than an integer.

`timescale 1ns/1ps

module probe_modes_tb;

  logic clk = 1'b0, rstn = 1'b0;
  always #5 clk = ~clk;

  logic [63:0]  chn_in;   logic chn_in_v, chn_in_r;
  logic         cfg_bypass, cfg_nan_to_zero;
  logic [31:0]  cfg_offset;   logic [15:0] cfg_scale;
  logic [5:0]   cfg_truncate; logic [1:0]  cfg_precision;
  logic [127:0] chn_out;  logic chn_out_rdy = 1'b1, chn_out_v;

  NV_NVDLA_SDP_CORE_Y_cvt dut (
    .nvdla_core_clk(clk), .nvdla_core_rstn(rstn),
    .chn_in_rsc_z(chn_in), .chn_in_rsc_vz(chn_in_v), .chn_in_rsc_lz(chn_in_r),
    .cfg_bypass_rsc_z(cfg_bypass), .cfg_offset_rsc_z(cfg_offset),
    .cfg_scale_rsc_z(cfg_scale), .cfg_truncate_rsc_z(cfg_truncate),
    .cfg_nan_to_zero_rsc_z(cfg_nan_to_zero), .cfg_precision_rsc_z(cfg_precision),
    .chn_out_rsc_z(chn_out), .chn_out_rsc_vz(chn_out_rdy), .chn_out_rsc_lz(chn_out_v)
  );

  logic [127:0] got;

  task automatic shot(input string tag, input [15:0] x, input [31:0] off,
                      input [15:0] sc, input [5:0] tr, input [1:0] pr,
                      input bit n2z, input bit byp, input bit as_float);
    int unsigned t; shortreal f;
    begin
      @(negedge clk);
      cfg_offset=off; cfg_scale=sc; cfg_truncate=tr; cfg_precision=pr;
      cfg_nan_to_zero=n2z; cfg_bypass=byp;
      repeat (4) @(negedge clk);
      chn_in = {x,x,x,x}; chn_in_v = 1'b1;
      t=0; forever begin @(posedge clk); #1; if (chn_in_r) break; t++; if (t>100) break; end
      @(negedge clk); chn_in_v = 1'b0;
      t=0; got=128'hx;
      forever begin @(posedge clk); #1; t++;
        if (chn_out_v && chn_out_rdy) begin got = chn_out; break; end
        if (t>200) break; end
      if (as_float) begin
        f = $bitstoshortreal(got[31:0]);
        $display("MEASURE: %-12s in=0x%04h -> 0x%08h  (as f32: %f)", tag, x, got[31:0], f);
      end else
        $display("MEASURE: %-12s x=%7d off=%8d sc=%7d tr=%0d pr=%0d -> %12d (0x%08h)",
                 tag, $signed(x), $signed(off), $signed(sc), tr, pr,
                 $signed(got[31:0]), got[31:0]);
      repeat (20) @(negedge clk);
    end
  endtask

  initial begin
    chn_in=0; chn_in_v=0; cfg_bypass=0; cfg_nan_to_zero=0;
    cfg_offset=0; cfg_scale=1; cfg_truncate=0; cfg_precision=0;
    repeat (8) @(posedge clk); rstn=1'b1; repeat (8) @(posedge clk);

    $display("MEASURE: --- Q5 ROUNDING, halves on both signs (t=1) ---");
    shot("p_1.5",  16'd3,   32'd0,16'd1,6'd1,2'd0,0,0,0);
    shot("n_1.5",  16'hFFFD,32'd0,16'd1,6'd1,2'd0,0,0,0); // -3
    shot("p_3.5",  16'd7,   32'd0,16'd1,6'd1,2'd0,0,0,0);
    shot("n_3.5",  16'hFFF9,32'd0,16'd1,6'd1,2'd0,0,0,0); // -7
    shot("p_0.5",  16'd1,   32'd0,16'd1,6'd1,2'd0,0,0,0);
    shot("n_0.5",  16'hFFFF,32'd0,16'd1,6'd1,2'd0,0,0,0); // -1
    shot("n_2.25", 16'hFFF7,32'd0,16'd1,6'd2,2'd0,0,0,0); // -9,t2

    $display("MEASURE: --- Q6 SATURATION: force past 2^31 ---");
    shot("ovf_pos", 16'h7FFF,32'hFFFF0001,16'h7FFF,6'd0,2'd0,0,0,0); // (32767+65535)*32767
    shot("ovf_neg", 16'h8000,32'h0000FFFF,16'h7FFF,6'd0,2'd0,0,0,0); // (-32768-65535)*32767
    shot("ovf_p1",  16'h7FFF,32'hFFFF0001,16'h7FFF,6'd0,2'd1,0,0,0);
    shot("ovf_p3",  16'h7FFF,32'hFFFF0001,16'h7FFF,6'd0,2'd3,0,0,0);

    $display("MEASURE: --- Q8 are p0/p1/p3 one mode in three codes? ---");
    shot("mid_p0", 16'h1234,32'd291,16'd37,6'd3,2'd0,0,0,0);
    shot("mid_p1", 16'h1234,32'd291,16'd37,6'd3,2'd1,0,0,0);
    shot("mid_p3", 16'h1234,32'd291,16'd37,6'd3,2'd3,0,0,0);

    $display("MEASURE: --- Q7 p2 is fp16->fp32? and do off/sc/tr apply there? ---");
    shot("f_1.0",   16'h3C00,32'd0,16'd1,6'd0,2'd2,0,0,1);
    shot("f_2.5",   16'h4100,32'd0,16'd1,6'd0,2'd2,0,0,1);
    shot("f_-3.0",  16'hC200,32'd0,16'd1,6'd0,2'd2,0,0,1);
    shot("f_0.5",   16'h3800,32'd0,16'd1,6'd0,2'd2,0,0,1);
    shot("f_inf",   16'h7C00,32'd0,16'd1,6'd0,2'd2,0,0,1);
    shot("f_sc2.0", 16'h3C00,32'd0,16'h4000,6'd0,2'd2,0,0,1); // scale as fp16 2.0
    shot("f_off",   16'h3C00,32'h3F800000,16'd1,6'd0,2'd2,0,0,1); // offset as fp32 1.0
    shot("f_tr1",   16'h4100,32'd0,16'd1,6'd1,2'd2,0,0,1);

    $display("MEASURE: --- Q9 nan_to_zero and bypass ---");
    shot("nan_off", 16'h7E00,32'd0,16'd1,6'd0,2'd2,0,0,1);
    shot("nan_on",  16'h7E00,32'd0,16'd1,6'd0,2'd2,1,0,1);
    shot("nan_int", 16'h7E00,32'd0,16'd1,6'd0,2'd0,1,0,0);
    shot("byp_p0",  16'd4,   32'd3,16'd2,6'd1,2'd0,0,1,0);
    shot("byp_p2",  16'h4100,32'd0,16'd1,6'd0,2'd2,0,1,1);

    $display("TEST_RESULT: PROBE -- not a score");
    $finish;
  end

  initial begin #600000; $display("MEASURE: watchdog"); $display("TEST_RESULT: PROBE"); $finish; end

endmodule
