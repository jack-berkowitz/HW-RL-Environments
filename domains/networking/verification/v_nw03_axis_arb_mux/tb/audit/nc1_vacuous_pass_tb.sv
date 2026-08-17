// NEGATIVE CONTROL 1 -- checks nothing, always passes. Never scored.
// Establishes that the MUTANT rows have power: this must be accepted on the
// golden and every conformant perturbation, and must SURVIVE all six mutants.
// A crude control like this is weak on its own (F25) -- see nc2.
module frame_arb_mux_tb;
  localparam int S = 4, DW = 32, UW = 1, KW = DW/8;
  logic clk = 0, rst = 1; always #5 clk = ~clk;
  logic [S-1:0][DW-1:0] sd = '0; logic [S-1:0][KW-1:0] sk = '1;
  logic [S-1:0] sv = '0, sr, sl = '0; logic [S-1:0][UW-1:0] su = '0;
  logic [DW-1:0] md; logic [KW-1:0] mk; logic mv, ml, mr = 1; logic [UW-1:0] mu;
  frame_arb_mux #(.S_COUNT(S), .DATA_WIDTH(DW), .USER_WIDTH(UW)) dut (
    .clk_i(clk), .rst_i(rst), .s_tdata_i(sd), .s_tkeep_i(sk), .s_tvalid_i(sv),
    .s_tready_o(sr), .s_tlast_i(sl), .s_tuser_i(su),
    .m_tdata_o(md), .m_tkeep_o(mk), .m_tvalid_o(mv), .m_tready_i(mr),
    .m_tlast_o(ml), .m_tuser_o(mu));
  initial begin
    repeat (4) @(posedge clk); @(negedge clk) rst = 0;
    repeat (50) @(posedge clk);
    $display("RESULT: PASS");
    $finish;
  end
endmodule
