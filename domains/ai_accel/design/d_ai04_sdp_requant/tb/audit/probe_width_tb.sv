// probe_width_tb.sv -- d_ai04 STEP 0, PROBE 6. Not a scoring rig.
//
// Q14 HOW WIDE IS THE INTERNAL PRODUCT?
//
// x is 16b signed and offset is 32b signed, so (x - offset) already spans ~2^33
// and cannot live in 32 bits. Times a 16b scale it reaches ~2^48. A design that
// carries 32-bit intermediates passes every small vector and fails only out here.
// That makes the intermediate width a quantity a candidate must DERIVE rather
// than read off, which is the one thing worth grading -- so it has to be right.
//
// Probe 3 showed saturation at 0x7FFFFFFF, but ONLY on a product of ~2^31.6.
// That is too close to the boundary to distinguish saturation from wraparound
// by inspection, so each vector below is paired with the value a 32-bit
// wrapping implementation would emit instead.

`timescale 1ns/1ps

module probe_width_tb;

  logic clk = 1'b0, rstn = 1'b0;
  always #5 clk = ~clk;

  logic [63:0]  chn_in = 0; logic chn_in_v = 0, chn_in_r;
  logic [31:0]  cfg_offset = 0; logic [15:0] cfg_scale = 1; logic [5:0] cfg_truncate = 0;
  logic [127:0] chn_out;    logic chn_out_rdy = 1, chn_out_v;

  NV_NVDLA_SDP_CORE_Y_cvt dut (
    .nvdla_core_clk(clk), .nvdla_core_rstn(rstn),
    .chn_in_rsc_z(chn_in), .chn_in_rsc_vz(chn_in_v), .chn_in_rsc_lz(chn_in_r),
    .cfg_bypass_rsc_z(1'b0), .cfg_offset_rsc_z(cfg_offset), .cfg_scale_rsc_z(cfg_scale),
    .cfg_truncate_rsc_z(cfg_truncate), .cfg_nan_to_zero_rsc_z(1'b0), .cfg_precision_rsc_z(2'd0),
    .chn_out_rsc_z(chn_out), .chn_out_rsc_vz(chn_out_rdy), .chn_out_rsc_lz(chn_out_v)
  );

  logic [127:0] got;

  task automatic shot(input string tag, input [15:0] x, input [31:0] off,
                      input [15:0] sc, input [5:0] tr, input string note);
    int unsigned t;
    begin
      @(negedge clk); cfg_offset=off; cfg_scale=sc; cfg_truncate=tr;
      repeat (4) @(negedge clk);
      chn_in = {x,x,x,x}; chn_in_v = 1'b1;
      t=0; forever begin @(posedge clk); #1; if (chn_in_r) break; t++; if (t>100) break; end
      @(negedge clk); chn_in_v = 1'b0;
      t=0; got=128'hx;
      forever begin @(posedge clk); #1; t++;
        if (chn_out_v && chn_out_rdy) begin got = chn_out; break; end
        if (t>200) break; end
      $display("MEASURE: %-12s x=%6d off=%12d sc=%6d tr=%0d -> 0x%08h (%13d)   %s",
               tag, $signed(x), $signed(off), $signed(sc), tr,
               got[31:0], $signed(got[31:0]), note);
      repeat (16) @(negedge clk);
    end
  endtask

  initial begin
    repeat (8) @(posedge clk); rstn = 1'b1; repeat (8) @(posedge clk);

    $display("MEASURE: --- Q14 does (x - offset) itself survive past 32 bits? ---");
    // 0 - (-2^31) = +2^31, one past int32 max. sat=0x7FFFFFFF, wrap=0x80000000
    shot("sub_ovf_p", 16'd0, 32'h80000000, 16'd1, 6'd0, "sat->0x7fffffff wrap->0x80000000");
    // -32768 - (2^31-1) = -2147516415, past int32 min. sat=0x80000000, wrap=0x7FFF8001
    shot("sub_ovf_n", 16'h8000, 32'h7FFFFFFF, 16'd1, 6'd0, "sat->0x80000000 wrap->0x7fff8001");

    $display("MEASURE: --- is the FULL product kept before the shift? ---");
    // (0 - (-2^31)) * 1 >> 31 = 1 exactly, IF the product is wider than 32b.
    // a 32-bit intermediate saturates first and then gives 0x7fffffff>>31 = 0.
    shot("wide_t31",  16'd0, 32'h80000000, 16'd1, 6'd31, "wide->1  narrow(sat-then-shift)->0");
    // (0 - (-2^31)) * 4 >> 33 = 1 exactly. needs ~34 bits of product.
    shot("wide_t33",  16'd0, 32'h80000000, 16'd4, 6'd33, "wide->1  narrow->0");
    // (0 - (-2^31)) * 32767 >> 46 = 2^31*32767/2^46 = 0.999... -> rounds to 1
    shot("wide_t46",  16'd0, 32'h80000000, 16'h7FFF, 6'd46, "wide->1 (0.9999 rounds up)");
    shot("wide_t45",  16'd0, 32'h80000000, 16'h7FFF, 6'd45, "wide->2 (1.9999 rounds up)");

    $display("MEASURE: --- truncate beyond the data: shift of 63 ---");
    shot("t63_big",   16'h7FFF, 32'd0, 16'h7FFF, 6'd63, "expect 0");
    shot("t63_neg",   16'h8000, 32'd0, 16'h7FFF, 6'd63, "expect 0 or -1");

    $display("TEST_RESULT: PROBE -- not a score");
    $finish;
  end

  initial begin #400000; $display("MEASURE: watchdog"); $display("TEST_RESULT: PROBE"); $finish; end

endmodule
