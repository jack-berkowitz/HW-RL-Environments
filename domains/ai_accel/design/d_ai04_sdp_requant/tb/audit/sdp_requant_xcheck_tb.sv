// sdp_requant_xcheck_tb.sv -- d_ai04 CROSS-CHECK against the vendored anchor.
// NOT the scoring rig. Deliberately under tb/audit/ so sim_candidate.sh cannot
// pick it up: the scoring testbench is tb/sdp_requant_tb.sv and nothing else.
//
// WHY THIS EXISTS. task.yaml records the oracle honestly and the record is
// unflattering:
//
//     "Captured-vector oracle, not co-simulation ... The 800-word sweep is
//      checked against a MODEL BY THE SAME AUTHOR as the reference, and can
//      share a misreading with it."
//
// 44 anchor-measured words carry the contract, and 800 swept words carry only as
// much authority as my own model. This rig removes that limit for the sweep by
// running the REAL NVDLA RTL beside the reference on identical stimulus and
// comparing the delivered word sequences. What it proves is the strong claim
// d_dsp02 can make and d_ai04's scoring rig cannot: the reference agrees with
// RTL nobody here wrote, on inputs nobody chose in advance.
//
// WHAT IT DOES NOT PROVE, said before the results rather than after. It compares
// VALUE SEQUENCES, not cycle behaviour. The anchor holds three words behind a
// stalled consumer and the reference holds two -- both conform (spec A4, G4) --
// so their timing legitimately differs and a cycle-by-cycle comparison would
// report differences that are not defects. Flow control is checked by T5 in the
// scoring rig and by tb/audit/probe_capacity_tb.sv against the anchor directly.
//
// THE INTERFACE MAPPING IS MEASURED, NOT ASSUMED. From probe 1 and the Mentor
// library wrappers, which are the one readable part of Catapult output:
//     chn_in_rsc_vz  = valid in     chn_in_rsc_lz  = ready out
//     chn_out_rsc_vz = ready in     chn_out_rsc_lz = valid out

`timescale 1ns/1ps

module sdp_requant_xcheck_tb;

  logic clk = 1'b0, rst_n = 1'b0;
  always #5 clk = ~clk;

  // shared stimulus
  logic [63:0] w_data = 64'd0;
  logic [ 1:0] c_pr = 2'd0;
  logic [31:0] c_off = 32'd0;
  logic [15:0] c_sc  = 16'd1;
  logic [ 5:0] c_tr  = 6'd0;
  logic        c_byp = 1'b0, c_n2z = 1'b0;

  // ---- device under test: the reference ----
  logic         d_in_v = 1'b0, d_in_r;
  logic [127:0] d_out;
  logic         d_out_v, d_out_rdy = 1'b1;

  sdp_requant dut (
    .clk(clk), .rst_n(rst_n),
    .in_data(w_data), .in_valid(d_in_v), .in_ready(d_in_r),
    .cfg_precision(c_pr), .cfg_offset(c_off), .cfg_scale(c_sc),
    .cfg_truncate(c_tr), .cfg_bypass(c_byp), .cfg_nan_to_zero(c_n2z),
    .out_data(d_out), .out_valid(d_out_v), .out_ready(d_out_rdy)
  );

  // ---- the anchor: real NVDLA RTL, unmodified ----
  logic         a_in_v = 1'b0, a_in_r;
  logic [127:0] a_out;
  logic         a_out_v, a_out_rdy = 1'b1;

  NV_NVDLA_SDP_CORE_Y_cvt anchor (
    .nvdla_core_clk(clk), .nvdla_core_rstn(rst_n),
    .chn_in_rsc_z(w_data), .chn_in_rsc_vz(a_in_v), .chn_in_rsc_lz(a_in_r),
    .cfg_bypass_rsc_z(c_byp), .cfg_offset_rsc_z(c_off), .cfg_scale_rsc_z(c_sc),
    .cfg_truncate_rsc_z(c_tr), .cfg_nan_to_zero_rsc_z(c_n2z), .cfg_precision_rsc_z(c_pr),
    .chn_out_rsc_z(a_out), .chn_out_rsc_vz(a_out_rdy), .chn_out_rsc_lz(a_out_v)
  );

  logic [127:0] d_q[$], a_q[$];
  int unsigned  n_sent = 0, n_cmp = 0, n_diff = 0, errs = 0;

  always @(posedge clk) if (rst_n) begin
    if (d_out_v && d_out_rdy) d_q.push_back(d_out);
    if (a_out_v && a_out_rdy) a_q.push_back(a_out);
  end

  // drive one word into BOTH, each at its own pace, then release
  task automatic both(input logic [63:0] w);
    int unsigned t;
    begin
      @(negedge clk);
      w_data = w; d_in_v = 1'b1; a_in_v = 1'b1;
      t = 0;
      // hold until each has taken it; drop each valid as it is accepted
      while ((d_in_v || a_in_v) && t < 500) begin
        @(posedge clk); #1;
        if (d_in_v && d_in_r) d_in_v = 1'b0;
        if (a_in_v && a_in_r) a_in_v = 1'b0;
        t++;
      end
      if (t >= 500) begin
        $display("[FAIL] word %0d was never accepted by both (dut_v=%0b anchor_v=%0b)",
                 n_sent, d_in_v, a_in_v);
        errs++;
        d_in_v = 1'b0; a_in_v = 1'b0;
      end
      n_sent++;
      @(negedge clk);
    end
  endtask

  task automatic compare(input string tag);
    int unsigned t;
    begin
      // let both drain
      t = 0;
      while ((d_q.size() < n_sent || a_q.size() < n_sent) && t < 2000) begin
        @(posedge clk); t++;
      end
      if (d_q.size() != a_q.size()) begin
        $display("[FAIL] %s: reference produced %0d words, anchor produced %0d",
                 tag, d_q.size(), a_q.size());
        errs++;
      end
      while (d_q.size() > 0 && a_q.size() > 0) begin
        automatic logic [127:0] dv = d_q.pop_front();
        automatic logic [127:0] av = a_q.pop_front();
        n_cmp++;
        if (dv !== av) begin
          n_diff++;
          if (n_diff <= 8)
            $display("[FAIL] %s word %0d: reference=%032h anchor=%032h", tag, n_cmp, dv, av);
          errs++;
        end
      end
      d_q.delete(); a_q.delete(); n_sent = 0;
      repeat (8) @(posedge clk);
    end
  endtask

  logic [63:0] w;

  initial begin
    void'($urandom(32'hA1_04_C0DE));   // fixed seed: a differing word must be reproducible
    repeat (8) @(posedge clk); rst_n = 1'b1; repeat (8) @(posedge clk);

    // ---- integer modes, random configuration, random data ----
    for (int cfg = 0; cfg < 60; cfg++) begin
      @(negedge clk);
      c_pr  = (cfg % 7 == 3) ? 2'd3 : ((cfg % 5 == 1) ? 2'd1 : 2'd0);
      c_off = $urandom; c_sc = 16'($urandom); c_tr = 6'($urandom % 48);
      c_byp = (cfg % 11 == 0); c_n2z = (cfg % 6 == 0);
      for (int i = 0; i < 16; i++) begin
        w = {32'($urandom), 32'($urandom)};
        both(w);
      end
      compare($sformatf("int cfg %0d", cfg));
    end

    // ---- float mode, including the exponent corners ----
    for (int cfg = 0; cfg < 40; cfg++) begin
      @(negedge clk);
      c_pr  = 2'd2;
      c_off = $urandom; c_sc = 16'($urandom); c_tr = 6'($urandom % 48);
      c_byp = (cfg % 5 == 0); c_n2z = (cfg % 3 == 0);
      for (int i = 0; i < 16; i++) begin
        if (i < 6) begin
          // steer at the corners: subnormal, zero, inf, NaN, the normal edges
          automatic logic [15:0] corner[6] =
            '{16'h0000, 16'h0001, 16'h03FF, 16'h0400, 16'h7C00, 16'h7E00};
          w = {corner[i], corner[(i+1)%6] ^ 16'h8000, corner[(i+2)%6], 16'($urandom)};
        end else
          w = {32'($urandom), 32'($urandom)};
        both(w);
      end
      compare($sformatf("flt cfg %0d", cfg));
    end

    // ---- exhaustive over every binary16 exponent/mantissa boundary ----
    @(negedge clk); c_pr = 2'd2; c_off = 32'd0; c_sc = 16'd1; c_tr = 6'd0;
    c_byp = 1'b0; c_n2z = 1'b0;
    for (int e = 0; e < 32; e++) begin
      for (int m = 0; m < 4; m++) begin
        automatic logic [9:0] mant = (m == 0) ? 10'd0 : (m == 1) ? 10'd1 :
                                     (m == 2) ? 10'h3FF : 10'h200;
        w = {1'b0, e[4:0], mant, 1'b1, e[4:0], mant,
             1'b0, e[4:0], mant, 1'b1, e[4:0], mant};
        both(w);
      end
    end
    compare("fp16 exponent sweep");

    $display("MEASURE: cross-check compared %0d words against the anchor", n_cmp);
    $display("MEASURE: differing words = %0d", n_diff);
    if (n_cmp < 1500) begin
      $display("[FAIL] FLOOR: only %0d words compared -- the rig did not run", n_cmp);
      errs++;
    end
    if (errs == 0) $display("TEST_RESULT: PASS");
    else           $display("TEST_RESULT: FAIL: %0d failing checks", errs);
    $finish;
  end

  initial begin
    #20000000;
    $display("[FAIL] watchdog");
    $display("TEST_RESULT: FAIL: watchdog");
    $finish;
  end

endmodule
