// =============================================================================
// nonequiv_tb.sv -- NON-EQUIVALENCE WITNESSES. Never shipped, never scored.
// =============================================================================
// Shows, for every conformant perturbation and every mutant, a concrete point
// at which its behaviour differs from the golden's. Two different jobs:
//
//   conformant/  a perturbation that is secretly a no-op SURVIVES and reports
//                the reassuring answer. Worse than having no control at all.
//   mutants/     "nothing has killed it yet" and "nothing can" are different
//                claims, and only the second justifies withdrawing a mutant.
//
// METHOD. Beat contents are a pure function of (input, sequence number), so the
// two instances receive identical input STREAMS however their ready timing
// differs. The witness is then the first output beat at which either the value
// or the cycle of transfer differs. Both are reported: a timing-only difference
// is a real difference and is what the latency and stall perturbations produce.
//
//   $ verilator ... --top-module nonequiv_tb -GVARIANT=n
// =============================================================================

module nonequiv_tb #(parameter int VARIANT = 1);

  localparam int S = 4, DW = 32, UW = 1, KW = DW/8;
  localparam int MAXBEATS = 400;

  logic clk = 1'b0, rst = 1'b1;
  always #5 clk = ~clk;

  // deterministic content: a function of (k, n) only
  function automatic logic [31:0] mix(input int unsigned k, input int unsigned n);
    logic [31:0] x = 32'h9E37_79B9 ^ (32'(k) * 32'h0100_0193) ^ (32'(n) * 32'h85EB_CA6B);
    x ^= x << 13; x ^= x >> 17; x ^= x << 5;
    return x;
  endfunction
  function automatic int unsigned flen(input int unsigned k, input int unsigned f);
    return 1 + (mix(k + 32'd77, f) % 5);
  endfunction

  // ---- one independent driver per instance --------------------------------
  logic [S-1:0][DW-1:0] ad, bd;
  logic [S-1:0][KW-1:0] ak, bk;
  logic [S-1:0]         av, bv, ar, br, al, bl;
  logic [S-1:0][UW-1:0] au, bu;
  int unsigned an [S], bn [S], af [S], bf [S], ab [S], bb [S];

  logic [DW-1:0] amd, bmd; logic [KW-1:0] amk, bmk;
  logic amv, bmv, aml, bml; logic [UW-1:0] amu, bmu;
  logic mr = 1'b1;

  // golden
  frame_arb_mux #(.S_COUNT(S), .DATA_WIDTH(DW), .USER_WIDTH(UW)) i_gold (
    .clk_i(clk), .rst_i(rst), .s_tdata_i(ad), .s_tkeep_i(ak), .s_tvalid_i(av),
    .s_tready_o(ar), .s_tlast_i(al), .s_tuser_i(au),
    .m_tdata_o(amd), .m_tkeep_o(amk), .m_tvalid_o(amv), .m_tready_i(mr),
    .m_tlast_o(aml), .m_tuser_o(amu));

  // variant under witness
  generate
    case (VARIANT)
      1: fm_c1_ready_withheld       #(.S_COUNT(S), .DATA_WIDTH(DW), .USER_WIDTH(UW)) i_v (.clk_i(clk), .rst_i(rst), .s_tdata_i(bd), .s_tkeep_i(bk), .s_tvalid_i(bv), .s_tready_o(br), .s_tlast_i(bl), .s_tuser_i(bu), .m_tdata_o(bmd), .m_tkeep_o(bmk), .m_tvalid_o(bmv), .m_tready_i(mr), .m_tlast_o(bml), .m_tuser_o(bmu));
      2: fm_c2_reversed_order       #(.S_COUNT(S), .DATA_WIDTH(DW), .USER_WIDTH(UW)) i_v (.clk_i(clk), .rst_i(rst), .s_tdata_i(bd), .s_tkeep_i(bk), .s_tvalid_i(bv), .s_tready_o(br), .s_tlast_i(bl), .s_tuser_i(bu), .m_tdata_o(bmd), .m_tkeep_o(bmk), .m_tvalid_o(bmv), .m_tready_i(mr), .m_tlast_o(bml), .m_tuser_o(bmu));
      3: fm_c3_extra_latency        #(.S_COUNT(S), .DATA_WIDTH(DW), .USER_WIDTH(UW)) i_v (.clk_i(clk), .rst_i(rst), .s_tdata_i(bd), .s_tkeep_i(bk), .s_tvalid_i(bv), .s_tready_o(br), .s_tlast_i(bl), .s_tuser_i(bu), .m_tdata_o(bmd), .m_tkeep_o(bmk), .m_tvalid_o(bmv), .m_tready_i(mr), .m_tlast_o(bml), .m_tuser_o(bmu));
      4: fm_c4_garbage_when_invalid #(.S_COUNT(S), .DATA_WIDTH(DW), .USER_WIDTH(UW)) i_v (.clk_i(clk), .rst_i(rst), .s_tdata_i(bd), .s_tkeep_i(bk), .s_tvalid_i(bv), .s_tready_o(br), .s_tlast_i(bl), .s_tuser_i(bu), .m_tdata_o(bmd), .m_tkeep_o(bmk), .m_tvalid_o(bmv), .m_tready_i(mr), .m_tlast_o(bml), .m_tuser_o(bmu));
      5: fm_c5_idle_between_frames  #(.S_COUNT(S), .DATA_WIDTH(DW), .USER_WIDTH(UW)) i_v (.clk_i(clk), .rst_i(rst), .s_tdata_i(bd), .s_tkeep_i(bk), .s_tvalid_i(bv), .s_tready_o(br), .s_tlast_i(bl), .s_tuser_i(bu), .m_tdata_o(bmd), .m_tkeep_o(bmk), .m_tvalid_o(bmv), .m_tready_i(mr), .m_tlast_o(bml), .m_tuser_o(bmu));
      11: fm_m1_drops_high_payload  #(.S_COUNT(S), .DATA_WIDTH(DW), .USER_WIDTH(UW)) i_v (.clk_i(clk), .rst_i(rst), .s_tdata_i(bd), .s_tkeep_i(bk), .s_tvalid_i(bv), .s_tready_o(br), .s_tlast_i(bl), .s_tuser_i(bu), .m_tdata_o(bmd), .m_tkeep_o(bmk), .m_tvalid_o(bmv), .m_tready_i(mr), .m_tlast_o(bml), .m_tuser_o(bmu));
      12: fm_m2_priority_arbitration#(.S_COUNT(S), .DATA_WIDTH(DW), .USER_WIDTH(UW)) i_v (.clk_i(clk), .rst_i(rst), .s_tdata_i(bd), .s_tkeep_i(bk), .s_tvalid_i(bv), .s_tready_o(br), .s_tlast_i(bl), .s_tuser_i(bu), .m_tdata_o(bmd), .m_tkeep_o(bmk), .m_tvalid_o(bmv), .m_tready_i(mr), .m_tlast_o(bml), .m_tuser_o(bmu));
      13: fm_m3_frame_interleaved   #(.S_COUNT(S), .DATA_WIDTH(DW), .USER_WIDTH(UW)) i_v (.clk_i(clk), .rst_i(rst), .s_tdata_i(bd), .s_tkeep_i(bk), .s_tvalid_i(bv), .s_tready_o(br), .s_tlast_i(bl), .s_tuser_i(bu), .m_tdata_o(bmd), .m_tkeep_o(bmk), .m_tvalid_o(bmv), .m_tready_i(mr), .m_tlast_o(bml), .m_tuser_o(bmu));
      14: fm_m4_tuser_crossed       #(.S_COUNT(S), .DATA_WIDTH(DW), .USER_WIDTH(UW)) i_v (.clk_i(clk), .rst_i(rst), .s_tdata_i(bd), .s_tkeep_i(bk), .s_tvalid_i(bv), .s_tready_o(br), .s_tlast_i(bl), .s_tuser_i(bu), .m_tdata_o(bmd), .m_tkeep_o(bmk), .m_tvalid_o(bmv), .m_tready_i(mr), .m_tlast_o(bml), .m_tuser_o(bmu));
      15: fm_m5_early_tlast          #(.S_COUNT(S), .DATA_WIDTH(DW), .USER_WIDTH(UW)) i_v (.clk_i(clk), .rst_i(rst), .s_tdata_i(bd), .s_tkeep_i(bk), .s_tvalid_i(bv), .s_tready_o(br), .s_tlast_i(bl), .s_tuser_i(bu), .m_tdata_o(bmd), .m_tkeep_o(bmk), .m_tvalid_o(bmv), .m_tready_i(mr), .m_tlast_o(bml), .m_tuser_o(bmu));
      16: fm_m6_reset_ignored       #(.S_COUNT(S), .DATA_WIDTH(DW), .USER_WIDTH(UW)) i_v (.clk_i(clk), .rst_i(rst), .s_tdata_i(bd), .s_tkeep_i(bk), .s_tvalid_i(bv), .s_tready_o(br), .s_tlast_i(bl), .s_tuser_i(bu), .m_tdata_o(bmd), .m_tkeep_o(bmk), .m_tvalid_o(bmv), .m_tready_i(mr), .m_tlast_o(bml), .m_tuser_o(bmu));
      default: initial $fatal(1, "no such VARIANT");
    endcase
  endgenerate

  for (genvar k = 0; k < S; k++) begin : g_drv
    assign ad[k] = {mix(k, an[k])[31:16], 12'(an[k]), 4'(k)};
    assign bd[k] = {mix(k, bn[k])[31:16], 12'(bn[k]), 4'(k)};
    assign ak[k] = mix(k + 32'd11, an[k])[KW-1:0];
    assign bk[k] = mix(k + 32'd11, bn[k])[KW-1:0];
    assign au[k] = mix(k + 32'd23, an[k])[UW-1:0];
    assign bu[k] = mix(k + 32'd23, bn[k])[UW-1:0];
    assign al[k] = (ab[k] == flen(k, af[k]) - 1);
    assign bl[k] = (bb[k] == flen(k, bf[k]) - 1);
    assign av[k] = ~rst;
    assign bv[k] = ~rst;
  end

  always @(posedge clk) if (!rst) begin
    for (int k = 0; k < S; k++) begin
      if (av[k] && ar[k]) begin
        an[k] <= an[k] + 1;
        if (ab[k] == flen(k, af[k]) - 1) begin ab[k] <= 0; af[k] <= af[k] + 1; end
        else                                    ab[k] <= ab[k] + 1;
      end
      if (bv[k] && br[k]) begin
        bn[k] <= bn[k] + 1;
        if (bb[k] == flen(k, bf[k]) - 1) begin bb[k] <= 0; bf[k] <= bf[k] + 1; end
        else                                    bb[k] <= bb[k] + 1;
      end
    end
  end

  // ---- capture output beat sequences ---------------------------------------
  logic [DW+KW+UW:0] a_seq [$], b_seq [$];   // {tdata,tkeep,tuser,tlast}
  int unsigned   a_cyc [$], b_cyc [$];
  logic          a_lst [$], b_lst [$];
  int unsigned   cyc = 0;
  int unsigned   a_invalid_changes = 0, b_invalid_changes = 0;
  logic [DW-1:0] a_prev_idle, b_prev_idle;

  always @(posedge clk) if (!rst) begin
    cyc = cyc + 1;
    if (amv && mr) begin a_seq.push_back({amd, amk, amu, aml}); a_cyc.push_back(cyc); a_lst.push_back(aml); end
    if (bmv && mr) begin b_seq.push_back({bmd, bmk, bmu, bml}); b_cyc.push_back(cyc); b_lst.push_back(bml); end
    // latitude-4 witness: does the variant move its data lines while invalid?
    if (!amv) begin if (amd !== a_prev_idle) a_invalid_changes = a_invalid_changes + 1; a_prev_idle = amd; end
    if (!bmv) begin if (bmd !== b_prev_idle) b_invalid_changes = b_invalid_changes + 1; b_prev_idle = bmd; end
  end

  initial begin
    for (int k = 0; k < S; k++) begin an[k]=0; bn[k]=0; af[k]=0; bf[k]=0; ab[k]=0; bb[k]=0; end
    repeat (4) @(posedge clk);
    @(negedge clk) rst = 1'b0;
    while (a_seq.size() < 100 && b_seq.size() < 100) @(posedge clk);
    // Mid-stream reset. Without it the reset mutant is never provoked and its
    // witness reports an incidental one-cycle difference instead of the defect.
    @(negedge clk) rst = 1'b1;
    repeat (3) @(posedge clk);
    @(negedge clk) rst = 1'b0;
    while (a_seq.size() < MAXBEATS && b_seq.size() < MAXBEATS) @(posedge clk);

    begin
      automatic int n = (a_seq.size() < b_seq.size()) ? a_seq.size() : b_seq.size();
      automatic int first_val = -1, first_cyc = -1;
      for (int i = 0; i < n; i++) begin
        if (first_val < 0 && a_seq[i] !== b_seq[i]) first_val = i;
        if (first_cyc < 0 &&  a_cyc[i] !== b_cyc[i])                          first_cyc = i;
      end
      $display("VARIANT %0d", VARIANT);
      $display("  beats compared            : %0d", n);
      if (first_val >= 0)
        $display("  WITNESS value  @beat %0d : golden {data,keep,user,last}=%h   variant=%h",
                 first_val, a_seq[first_val], b_seq[first_val]);
      else
        $display("  value sequence identical over %0d beats", n);
      if (first_cyc >= 0)
        $display("  WITNESS timing @beat %0d : golden cycle=%0d   variant cycle=%0d",
                 first_cyc, a_cyc[first_cyc], b_cyc[first_cyc]);
      else
        $display("  transfer cycles identical over %0d beats", n);
      $display("  idle-line changes         : golden=%0d variant=%0d", a_invalid_changes, b_invalid_changes);
      if (first_val >= 0 || first_cyc >= 0 || a_invalid_changes !== b_invalid_changes)
        $display("  NON-EQUIVALENCE ESTABLISHED");
      else
        $display("  *** NO DIFFERENCE OBSERVED -- this wrapper may be a no-op ***");
    end
    $finish;
  end

  initial begin #5_000_000; $display("  watchdog"); $finish; end

endmodule
