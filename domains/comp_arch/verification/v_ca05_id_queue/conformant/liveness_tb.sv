// Non-equivalence witness for the conformant perturbations.
//
// "It survived the testbench" proves nothing if the wrapper is a no-op. Each
// perturbation must be shown to actually differ from the golden on some cycle;
// only then does survival mean the testbench declined to rely on the changed
// behaviour rather than never having reached it.
//
// Same bar the ordinary mutants are held to: a concrete simulation
// counterexample, not an argument.
`timescale 1ns/1ps
module liveness_tb;
  localparam int TAG_W = 3, SLOTS = 8, NM = 1;
  typedef logic [31:0] payload_t;

  logic clk = 0, rst_n = 0;
  always #5 clk = ~clk;

  logic [TAG_W-1:0] push_tag = '0;
  payload_t push_data = '0;
  logic push_req = 0;
  payload_t [NM-1:0] match_data = '0, match_mask = '0;
  logic [NM-1:0] match_req = '0;
  logic [TAG_W-1:0] pop_tag = '0;
  logic pop_en = 0, pop_req = 0;

  // per-DUT outputs
  logic [4:0] push_gnt, pop_data_valid, pop_gnt, full, empty;
  logic [4:0][NM-1:0] match_hit, match_gnt;
  payload_t pop_data [5];

  `define MK(IDX, MOD) \
    MOD #(.TAG_W(TAG_W), .SLOTS(SLOTS), .N_MATCH(NM), .payload_t(payload_t)) u``IDX ( \
      .clk_i(clk), .rst_ni(rst_n), .push_tag_i(push_tag), .push_data_i(push_data), \
      .push_req_i(push_req), .push_gnt_o(push_gnt[IDX]), \
      .match_data_i(match_data), .match_mask_i(match_mask), .match_req_i(match_req), \
      .match_hit_o(match_hit[IDX]), .match_gnt_o(match_gnt[IDX]), \
      .pop_tag_i(pop_tag), .pop_en_i(pop_en), .pop_req_i(pop_req), \
      .pop_data_o(pop_data[IDX]), .pop_data_valid_o(pop_data_valid[IDX]), \
      .pop_gnt_o(pop_gnt[IDX]), .full_o(full[IDX]), .empty_o(empty[IDX]));

  `MK(0, tag_tracker)
  `MK(1, tt_c1_match_gnt_freerun)
  `MK(2, tt_c2_pop_data_garbage)
  `MK(3, tt_c3_push_gnt_throttled)
  `MK(4, tt_c4_pop_gnt_delayed)

  string names [5] = '{"golden", "c1_match_gnt_freerun", "c2_pop_data_garbage",
                       "c3_push_gnt_throttled", "c4_pop_gnt_delayed"};
  bit    seen  [5];
  string witness [5];

  task automatic snap();
    for (int k = 1; k < 5; k++) begin
      if (seen[k]) continue;
      if (push_gnt[k] !== push_gnt[0])
        begin seen[k]=1; witness[k]=$sformatf("push_gnt %b vs %b", push_gnt[k], push_gnt[0]); end
      else if (match_gnt[k] !== match_gnt[0])
        begin seen[k]=1; witness[k]=$sformatf("match_gnt %b vs %b", match_gnt[k], match_gnt[0]); end
      else if (pop_gnt[k] !== pop_gnt[0])
        begin seen[k]=1; witness[k]=$sformatf("pop_gnt %b vs %b", pop_gnt[k], pop_gnt[0]); end
      else if (pop_data[k] !== pop_data[0])
        begin seen[k]=1; witness[k]=$sformatf("pop_data %08h vs %08h", pop_data[k], pop_data[0]); end
      else if (pop_data_valid[k] !== pop_data_valid[0])
        begin seen[k]=1; witness[k]=$sformatf("pop_valid %b vs %b", pop_data_valid[k], pop_data_valid[0]); end
      else if (empty[k] !== empty[0])
        begin seen[k]=1; witness[k]=$sformatf("empty %b vs %b", empty[k], empty[0]); end
      else if (full[k] !== full[0])
        begin seen[k]=1; witness[k]=$sformatf("full %b vs %b", full[k], full[0]); end
      if (seen[k]) witness[k] = $sformatf("t=%0t  %s", $time, witness[k]);
    end
  endtask

  int seed = 32'hC0FFEE;
  initial begin
    repeat (4) @(posedge clk);
    rst_n = 1; @(negedge clk);
    snap();

    // ---- directed phase: reach the conditions that distinguish each wrapper.
    // Random traffic did not reach c4's -- a one-cycle pop_req pulse with an
    // entry present is the only stimulus that separates a delayed grant from a
    // prompt one, and uniform random drive hits it rarely and self-cancels.
    push_tag = 3'd4; push_data = 32'h1111_0001; push_req = 1;
    @(posedge clk); #1; snap();
    @(negedge clk); push_req = 0;

    pop_tag = 3'd4; pop_en = 1; pop_req = 1;      // single-cycle pop request
    @(posedge clk); #1; snap();
    @(negedge clk); pop_req = 0; snap();
    @(posedge clk); #1; snap();                    // golden has popped, c4 has not
    @(negedge clk); pop_en = 0; snap();

    for (int n = 0; n < 300; n++) begin
      push_tag  = TAG_W'($urandom(seed));
      push_data = payload_t'($urandom(seed));
      push_req  = $urandom(seed) % 2;
      pop_tag   = TAG_W'($urandom(seed));
      pop_req   = $urandom(seed) % 2;
      pop_en    = $urandom(seed) % 2;
      match_req = ($urandom(seed) % 2);
      match_data = payload_t'($urandom(seed));
      match_mask = 32'h0000_00FF;
      @(posedge clk); #1;
      snap();
      @(negedge clk);
      snap();
    end

    $display("");
    for (int k = 1; k < 5; k++)
      if (seen[k]) $display("  LIVE     %-24s %s", names[k], witness[k]);
      else         $display("  NO-OP    %-24s no observable difference -- INVALID", names[k]);
    $finish;
  end
endmodule
