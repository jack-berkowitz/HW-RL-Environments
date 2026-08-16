// Does removal actually require pop_req_i, as R7 states?
`timescale 1ns/1ps
module r7_probe_tb;
  localparam int TAG_W = 3, SLOTS = 8, NM = 1;
  typedef logic [31:0] payload_t;
  logic clk = 0, rst_n = 0;
  always #5 clk = ~clk;

  logic [TAG_W-1:0] push_tag = 3'd4;
  payload_t push_data = 32'h1111_0001;
  logic push_req = 0, push_gnt;
  payload_t [NM-1:0] match_data = '0, match_mask = '0;
  logic [NM-1:0] match_req = '0, match_hit, match_gnt;
  logic [TAG_W-1:0] pop_tag = 3'd4;
  logic pop_en = 0, pop_req = 0;
  payload_t pop_data; logic pop_data_valid, pop_gnt;
  logic full, empty;

  tag_tracker #(.TAG_W(TAG_W), .SLOTS(SLOTS), .N_MATCH(NM), .payload_t(payload_t)) dut (
      .clk_i(clk), .rst_ni(rst_n), .push_tag_i(push_tag), .push_data_i(push_data),
      .push_req_i(push_req), .push_gnt_o(push_gnt),
      .match_data_i(match_data), .match_mask_i(match_mask), .match_req_i(match_req),
      .match_hit_o(match_hit), .match_gnt_o(match_gnt),
      .pop_tag_i(pop_tag), .pop_en_i(pop_en), .pop_req_i(pop_req),
      .pop_data_o(pop_data), .pop_data_valid_o(pop_data_valid), .pop_gnt_o(pop_gnt),
      .full_o(full), .empty_o(empty));

  initial begin
    repeat (4) @(posedge clk);
    rst_n = 1; @(negedge clk);

    // one entry in
    push_req = 1; @(posedge clk); @(negedge clk); push_req = 0;
    $display("after push      : empty=%b", empty);

    // ---- pop_en asserted, pop_req LOW. R7 says nothing should complete. ----
    pop_en = 1; pop_req = 0;
    repeat (3) @(posedge clk);
    @(negedge clk);
    $display("pop_en=1 req=0  : empty=%b  <-- R7 says the entry must SURVIVE", empty);
    if (empty) $display("   *** R7 VIOLATED BY THE GOLDEN: removal ignores pop_req_i");
    else       $display("   R7 holds: pop_req_i is required");
    pop_en = 0;

    // ---- proper handshake ----
    pop_en = 1; pop_req = 1; @(posedge clk); @(negedge clk); pop_req = 0; pop_en = 0;
    $display("proper pop      : empty=%b", empty);
    $finish;
  end
endmodule
