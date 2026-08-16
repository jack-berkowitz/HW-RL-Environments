// Measures what the spec's LATITUDE clauses are absorbing, by testing the
// assumptions a blind spec-reader would plausibly make instead.
// Each is an assumption the spec does not license -- but also does not warn
// against unless you already knew the answer.
`timescale 1ns/1ps
module naive_tb;
  localparam int TAG_W = 3, SLOTS = 8, NM = 1;
  typedef logic [31:0] payload_t;

  logic clk = 0, rst_n = 0;
  always #5 clk = ~clk;

  logic [TAG_W-1:0] push_tag = '0;
  payload_t push_data = '0;
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

  task automatic push1(input logic [TAG_W-1:0] tg, input payload_t d);
    push_tag = tg; push_data = d; push_req = 1;
    @(posedge clk);
    @(negedge clk); push_req = 0;
  endtask

  initial begin
    repeat (4) @(posedge clk);
    rst_n = 1; @(negedge clk);

    // A1: "grant implies a transaction" -- is push_gnt_o high with req LOW?
    $display("A1  push_req=0 -> push_gnt=%b   %s", push_gnt,
             push_gnt ? "ASSUMPTION BROKEN (gnt is a space flag, not an ack)"
                      : "assumption holds");

    // A2: "no grant for a pop of an absent tag"
    pop_tag = 3'd1; pop_en = 1; pop_req = 1;
    @(posedge clk);
    $display("A2  pop absent tag -> pop_gnt=%b valid=%b   %s", pop_gnt, pop_data_valid,
             pop_gnt ? "grant given for absent tag" : "ASSUMPTION HOLDS (no grant)");
    @(negedge clk); pop_req = 0; pop_en = 0;

    // A3: "match_gnt_o is high only when match_req_i is high"
    $display("A3  match_req=0 -> match_gnt=%b   %s", match_gnt[0],
             match_gnt[0] ? "ASSUMPTION BROKEN (gnt free-runs)" : "assumption holds");

    // A4: "a peek (pop_en=0) on an absent tag is harmless"
    push1(3'd2, 32'hCAFE0001);
    pop_tag = 3'd3; pop_en = 0; pop_req = 1;
    @(posedge clk);
    $display("A4  peek absent tag -> gnt=%b valid=%b (entries still present: empty=%b)",
             pop_gnt, pop_data_valid, empty);
    @(negedge clk); pop_req = 0;

    // A5: "pop_data_o is zero/stable when pop_data_valid_o is low"
    pop_tag = 3'd7; pop_en = 0; pop_req = 1;
    @(posedge clk);
    $display("A5  pop absent tag -> valid=%b data=%08h   %s", pop_data_valid, pop_data,
             (pop_data_valid == 0 && pop_data != 0)
               ? "ASSUMPTION BROKEN (stale data on invalid)" : "data was zero");
    @(negedge clk); pop_req = 0;

    $finish;
  end
endmodule
