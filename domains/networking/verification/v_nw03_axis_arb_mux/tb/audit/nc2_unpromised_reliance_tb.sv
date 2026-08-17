// NEGATIVE CONTROL 2 -- the one with power. Never scored.
// Relies on behaviour the specification does not promise: it requires
// s_tready_o to be high on every input while the design is idle. The golden
// satisfies that incidentally (its input registers are empty), so this control
// PASSES the golden -- and fm_c1, which withholds ready on a rolling schedule
// under the licence of S6 and latitude 3, must REJECT it.
//
// This is the shape that exposed F25: an always-FAIL control cannot tell a
// discriminating harness from one that reports whatever the submission says.
// This one must pass some rows and fail exactly the row it targets.
module frame_arb_mux_tb;
  localparam int S = 4, DW = 32, UW = 1, KW = DW/8;
  logic clk = 0, rst = 1; always #5 clk = ~clk;
  logic [S-1:0][DW-1:0] sd = '0; logic [S-1:0][KW-1:0] sk = '1;
  logic [S-1:0] sv = '0, sr, sl = '0; logic [S-1:0][UW-1:0] su = '0;
  logic [DW-1:0] md; logic [KW-1:0] mk; logic mv, ml, mr = 1; logic [UW-1:0] mu;
  int unsigned bad = 0;
  frame_arb_mux #(.S_COUNT(S), .DATA_WIDTH(DW), .USER_WIDTH(UW)) dut (
    .clk_i(clk), .rst_i(rst), .s_tdata_i(sd), .s_tkeep_i(sk), .s_tvalid_i(sv),
    .s_tready_o(sr), .s_tlast_i(sl), .s_tuser_i(su),
    .m_tdata_o(md), .m_tkeep_o(mk), .m_tvalid_o(mv), .m_tready_i(mr),
    .m_tlast_o(ml), .m_tuser_o(mu));
  initial begin
    repeat (4) @(posedge clk); @(negedge clk) rst = 0;
    repeat (60) begin
      @(posedge clk);
      if (sr !== {S{1'b1}}) begin
        if (bad == 0) $display("UNPROMISED: s_tready_o = %b while idle, expected all ones", sr);
        bad++;
      end
    end
    if (bad == 0) $display("RESULT: PASS");
    else          $display("RESULT: FAIL (%0d cycles with an input not ready while idle)", bad);
    $finish;
  end
endmodule
