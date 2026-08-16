// Non-equivalence witness for every mutant: a concrete input sequence on which
// golden and mutant differ. This is the shipping bar from the verification build
// prompt -- a mutant nobody can distinguish from the golden is unkillable, and
// penalising a submission for not killing it is unfair.
//
// Deliberately NOT a testbench. It compares outputs directly, so a mutant that
// no current testbench happens to catch is still shown to be catchable. Two of
// these (m4, m5) survived both testbenches tried so far, which is exactly when
// this distinction matters: "nothing killed it yet" and "nothing can" are
// different claims.
`timescale 1ns/1ps
module nonequiv_tb;
  localparam int TAG_W=3, SLOTS=8, NM=1;
  typedef logic [31:0] payload_t;
  logic clk=0, rst_n=0; always #5 clk=~clk;

  logic [TAG_W-1:0] push_tag='0; payload_t push_data='0; logic push_req=0;
  payload_t [NM-1:0] match_data='0, match_mask='0; logic [NM-1:0] match_req='0;
  logic [TAG_W-1:0] pop_tag='0; logic pop_en=0, pop_req=0;

  localparam int N = 7;   // golden + 6 mutants
  logic [N-1:0] push_gnt, pop_dv, pop_gnt, full, empty;
  logic [N-1:0][NM-1:0] match_hit, match_gnt;
  payload_t pop_data [N];

  `define MK(I, MOD) \
    MOD #(.TAG_W(TAG_W),.SLOTS(SLOTS),.N_MATCH(NM),.payload_t(payload_t)) u``I ( \
      .clk_i(clk),.rst_ni(rst_n),.push_tag_i(push_tag),.push_data_i(push_data), \
      .push_req_i(push_req),.push_gnt_o(push_gnt[I]), \
      .match_data_i(match_data),.match_mask_i(match_mask),.match_req_i(match_req), \
      .match_hit_o(match_hit[I]),.match_gnt_o(match_gnt[I]), \
      .pop_tag_i(pop_tag),.pop_en_i(pop_en),.pop_req_i(pop_req), \
      .pop_data_o(pop_data[I]),.pop_data_valid_o(pop_dv[I]),.pop_gnt_o(pop_gnt[I]), \
      .full_o(full[I]),.empty_o(empty[I]));

  `MK(0, tag_tracker_golden)
  `MK(1, tt_m1_capacity_off_by_one)
  `MK(2, tt_m2_lifo_within_tag)
  `MK(3, tt_m3_half_capacity)
  `MK(4, tt_m4_tag0_starved)
  `MK(5, tt_m5_match_ignores_high_byte)
  `MK(6, tt_m6_empty_wrong_at_one)

  string names [N] = '{"golden","m1_capacity_off_by_one","m2_lifo_within_tag",
                       "m3_half_capacity","m4_tag0_starved",
                       "m5_match_ignores_high_byte","m6_empty_wrong_at_one"};
  bit seen [N]; string wit [N];

  task automatic snap();
    for (int k=1;k<N;k++) begin
      if (seen[k]) continue;
      if (push_gnt[k]!==push_gnt[0])
        begin seen[k]=1; wit[k]=$sformatf("push_gnt %b vs %b",push_gnt[k],push_gnt[0]); end
      else if (pop_data[k]!==pop_data[0])
        begin seen[k]=1; wit[k]=$sformatf("pop_data %08h vs %08h",pop_data[k],pop_data[0]); end
      else if (match_hit[k]!==match_hit[0])
        begin seen[k]=1; wit[k]=$sformatf("match_hit %b vs %b",match_hit[k],match_hit[0]); end
      else if (empty[k]!==empty[0])
        begin seen[k]=1; wit[k]=$sformatf("empty %b vs %b",empty[k],empty[0]); end
      else if (full[k]!==full[0])
        begin seen[k]=1; wit[k]=$sformatf("full %b vs %b",full[k],full[0]); end
      if (seen[k]) wit[k]=$sformatf("t=%0t  %s",$time,wit[k]);
    end
  endtask

  task automatic push1(input logic [TAG_W-1:0] tg, input payload_t d);
    push_tag=tg; push_data=d; push_req=1;
    @(posedge clk); #1; snap();
    @(negedge clk); push_req=0; snap();
  endtask

  initial begin
    repeat(4) @(posedge clk); rst_n=1; @(negedge clk); snap();

    // m4: a push to TAG 0 specifically -- the only stimulus that separates it.
    push1(3'd0, 32'h1111_0001);

    // m1 / m3 / m6: fill past SLOTS/2 and up to SLOTS on a mix of tags.
    for (int i=0;i<SLOTS;i++) push1(TAG_W'(1 + (i % 3)), payload_t'(32'hA000_0000+i));

    // m2: two entries on one tag, then read the head.
    pop_tag=3'd1; pop_en=0; pop_req=1;
    @(posedge clk); #1; snap(); @(negedge clk); pop_req=0; snap();

    // m5: a masked search whose mask covers the TOP BYTE and whose value
    // differs from every stored entry ONLY there. The golden misses; a mutant
    // that drops [31:24] from the mask reports a hit.
    match_data[0]=32'hB000_0000; match_mask[0]=32'hFF00_0000; match_req[0]=1;
    @(posedge clk); #1; snap(); @(negedge clk); match_req[0]=0; snap();

    $display("");
    for (int k=1;k<N;k++)
      if (seen[k]) $display("  DISTINGUISHED  %-30s %s", names[k], wit[k]);
      else         $display("  NO WITNESS     %-30s -- withdraw or restimulate", names[k]);
    $finish;
  end
endmodule
