// Throwaway probe: one push, print the handshake and status each cycle.
`timescale 1ns/1ps
module probe_tb;
  localparam int TAG_W = 3, SLOTS = 8, NM = 1;
  typedef logic [31:0] payload_t;

  logic clk = 0, rst_n = 0;
  always #5 clk = ~clk;

  logic [TAG_W-1:0] push_tag = 3'd5;
  payload_t push_data = 32'hA0000000;
  logic push_req = 0, push_gnt;
  payload_t [NM-1:0] match_data = '0, match_mask = '0;
  logic [NM-1:0] match_req = '0, match_hit, match_gnt;
  logic [TAG_W-1:0] pop_tag = '0;
  logic pop_en = 0, pop_req = 0;
  payload_t pop_data; logic pop_data_valid, pop_gnt;
  logic full, empty;

  tag_tracker #(.TAG_W(TAG_W), .SLOTS(SLOTS), .N_MATCH(NM), .payload_t(payload_t)) dut (
      .clk_i(clk), .rst_ni(rst_n),
      .push_tag_i(push_tag), .push_data_i(push_data),
      .push_req_i(push_req), .push_gnt_o(push_gnt),
      .match_data_i(match_data), .match_mask_i(match_mask),
      .match_req_i(match_req), .match_hit_o(match_hit), .match_gnt_o(match_gnt),
      .pop_tag_i(pop_tag), .pop_en_i(pop_en), .pop_req_i(pop_req),
      .pop_data_o(pop_data), .pop_data_valid_o(pop_data_valid), .pop_gnt_o(pop_gnt),
      .full_o(full), .empty_o(empty));

  initial begin
    repeat (4) @(posedge clk);
    rst_n = 1;
    @(negedge clk);
    $display("t=%0t after reset: empty=%b full=%b push_gnt=%b free=%b",
             $time, empty, full, push_gnt, dut.linked_data_free);
    // EXPERIMENT A: single-cycle pulse, exactly as the spec TB drives it
    $display("--- A: one-cycle pulses ---");
    for (int i = 0; i < 3; i++) begin
      push_data = 32'hA0000000 + i;
      push_req = 1;
      @(posedge clk);
      push_req = 0;
      @(negedge clk);
      $display("t=%0t pulse%0d: empty=%b full=%b free=%b",
               $time, i, empty, full, dut.linked_data_free);
    end

    // EXPERIMENT B: held request, as the first probe did
    $display("--- B: held request ---");
    push_req = 1;
    for (int i = 0; i < 3; i++) begin
      @(posedge clk); #1;
      $display("t=%0t held%0d: empty=%b full=%b free=%b",
               $time, i, empty, full, dut.linked_data_free);
    end
    push_req = 0;
    @(negedge clk);
    $finish;
  end
endmodule
