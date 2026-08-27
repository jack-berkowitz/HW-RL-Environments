// probe_mshr_flush_tb.sv -- d_ca05 STEP 0, PROBE 3. Not a scoring rig.
//
// MEASUREMENTS.md lists "the MSHR address-match paths" and the flush walk under
// Not measured. The spec is about to be written and a clause covering something
// nobody measured is the d_dsp01 failure, so they are pinned first.
//
// READING THE CODE SUGGESTS TWO THINGS THAT MUST BE CHECKED RATHER THAN TRUSTED
// (miss_handler.sv:509-519):
//
//   addr  match:  mshr_q.valid && mshr_addr_i[i][55:4]  == mshr_q.addr[55:4]
//   index match:  mshr_q.valid && mshr_addr_i[i][11:4]  == mshr_q.addr[11:4]
//
//   (a) THE INDEX FIELD IS A SUBSET OF THE ADDRESS FIELD, so an address match
//       IMPLIES an index match. The comment reads "same as previous, but
//       checking only the index", whose natural implementation makes the two
//       MUTUALLY EXCLUSIVE. If the anchor really asserts both together, that
//       is a clause a submission is likely to get wrong.
//   (b) THE COMMENT SAYS "exclude the unit currently being served" AND THE CODE
//       DOES NOT DO THAT. Comment and code disagree; only one of them can be
//       the contract, and measurement decides which.

`timescale 1ns/1ps

module probe_mshr_flush_tb;
  import miss_handler_arb_pkg::*;

  localparam int unsigned NR_PORTS = 4;

  logic clk = 1'b0, rst_n = 1'b0;
  always #5 clk = ~clk;

  logic flush_i = 1'b0, flush_ack_o, miss_o, busy_i = 1'b0;
  logic [NR_PORTS-1:0][$bits(miss_req_t)-1:0] miss_req_i = '0;
  logic [NR_PORTS-1:0] bypass_gnt_o, bypass_valid_o, miss_gnt_o, active_serving_o;
  logic [NR_PORTS-1:0][63:0] bypass_data_o;
  logic [63:0] critical_word_o; logic critical_word_valid_o;
  logic [NR_PORTS-1:0][55:0] mshr_addr_i = '0;
  logic [NR_PORTS-1:0] mshr_addr_matches_o, mshr_index_matches_o;
  amo_req_t amo_req_i = '0; amo_resp_t amo_resp_o;
  axi_req_t byp_req, dat_req; axi_rsp_t byp_rsp, dat_rsp;
  logic [SET_ASSOC-1:0] req_o; logic [INDEX_WIDTH-1:0] addr_o;
  cache_line_t data_o; cl_be_t be_o; logic we_o;
  cache_line_t [SET_ASSOC-1:0] data_i = '0;

  // hold the refill response off so a taken miss STAYS in flight and mshr_q
  // remains valid while it is probed
  logic refill_answer = 1'b0;

  miss_handler_arb #(.NR_PORTS(NR_PORTS)) dut (
    .clk, .rst_n, .flush_i, .flush_ack_o, .miss_o, .busy_i,
    .miss_req_i, .bypass_gnt_o, .bypass_valid_o, .bypass_data_o,
    .miss_gnt_o, .active_serving_o, .critical_word_o, .critical_word_valid_o,
    .mshr_addr_i, .mshr_addr_matches_o, .mshr_index_matches_o,
    .amo_req_i, .amo_resp_o,
    .axi_bypass_req_o(byp_req), .axi_bypass_rsp_i(byp_rsp),
    .axi_data_req_o(dat_req), .axi_data_rsp_i(dat_rsp),
    .req_o, .addr_o, .data_o, .be_o, .data_i, .we_o
  );

  logic [3:0] dat_id_q; logic dat_ar_seen_q;
  always_ff @(posedge clk) begin
    if (!rst_n) begin byp_rsp <= '0; dat_rsp <= '0; dat_id_q <= '0; dat_ar_seen_q <= 1'b0; end
    else begin
      byp_rsp.aw_ready <= 1'b1; byp_rsp.w_ready <= 1'b1; byp_rsp.ar_ready <= 1'b1;
      dat_rsp.aw_ready <= 1'b1; dat_rsp.w_ready <= 1'b1; dat_rsp.ar_ready <= 1'b1;
      if (dat_req.ar_valid) begin dat_id_q <= dat_req.ar.id; dat_ar_seen_q <= 1'b1; end
      dat_rsp.r_valid <= dat_ar_seen_q && refill_answer;
      dat_rsp.r.id <= dat_id_q; dat_rsp.r.data <= 64'hC0DE_C0DE_C0DE_C0DE;
      dat_rsp.r.last <= 1'b1; dat_rsp.r.resp <= 2'b00;
      if (dat_ar_seen_q && refill_answer && dat_req.r_ready) dat_ar_seen_q <= 1'b0;
    end
  end

  // flush-walk observation
  int unsigned walk_writes, walk_reqs;
  logic [INDEX_WIDTH-1:0] first_addr, last_addr;
  logic [SET_ASSOC-1:0]   seen_vldrty;
  bit                     watching = 0;
  always_ff @(posedge clk) if (rst_n && watching) begin
    if (|req_o) begin
      walk_reqs++;
      if (walk_reqs == 1) first_addr <= addr_o;
      last_addr <= addr_o;
    end
    if (|req_o && we_o) begin walk_writes++; seen_vldrty <= seen_vldrty | be_o.vldrty; end
  end

  task automatic show(input string tag);
    $display("MEASURE: %-22s addr_match=%04b index_match=%04b",
             tag, mshr_addr_matches_o, mshr_index_matches_o);
  endtask

  int unsigned t;

  initial begin
    repeat (10) @(posedge clk); rst_n = 1'b1;
    repeat (300) @(posedge clk);          // let INIT finish

    $display("MEASURE: --- with NO miss in flight, mshr_q.valid = 0 ---");
    @(negedge clk);
    for (int k = 0; k < NR_PORTS; k++) mshr_addr_i[k] = 56'h00_0000_0001_2340;
    repeat (2) @(posedge clk); #1;
    show("no miss in flight");

    // ---- take a miss on port 0 and hold it in flight ----
    @(negedge clk);
    refill_answer = 1'b0;
    miss_req_i[0] = {1'b1, 64'h0000_0000_0001_2340, 8'hFF, 2'b11, 1'b0, 64'd0, 1'b0};
    t = 0; while (t < 500 && dut.i_miss_handler.mshr_q.valid !== 1'b1) begin @(posedge clk); t++; end
    @(negedge clk); miss_req_i[0] = '0;
    $display("MEASURE: mshr valid=%0b addr=%014h after %0d cycles",
             dut.i_miss_handler.mshr_q.valid, dut.i_miss_handler.mshr_q.addr, t);

    $display("MEASURE: --- the match matrix, mshr addr = 0x00000000012340 ---");
    @(negedge clk);
    mshr_addr_i[0] = 56'h00_0000_0001_2340;   // identical
    mshr_addr_i[1] = 56'h00_0000_0001_234C;   // same line, different offset bits [3:0]
    mshr_addr_i[2] = 56'hAA_BBBB_CCC1_2340;   // SAME index [11:4], different tag
    mshr_addr_i[3] = 56'h00_0000_0009_9990;   // different index
    repeat (2) @(posedge clk); #1;
    show("p0=same p1=+offset");
    $display("MEASURE:   p2 = same index, different tag -> addr=%0b index=%0b",
             mshr_addr_matches_o[2], mshr_index_matches_o[2]);
    $display("MEASURE:   p3 = different index          -> addr=%0b index=%0b",
             mshr_addr_matches_o[3], mshr_index_matches_o[3]);
    $display("MEASURE: (a) does an address match IMPLY an index match? p0 addr=%0b index=%0b",
             mshr_addr_matches_o[0], mshr_index_matches_o[0]);
    $display("MEASURE: (b) is the SERVED port (p0) excluded, as the comment says? addr_match[0]=%0b",
             mshr_addr_matches_o[0]);

    // let the miss retire
    @(negedge clk); refill_answer = 1'b1;
    repeat (200) @(posedge clk);
    @(negedge clk);
    for (int k = 0; k < NR_PORTS; k++) mshr_addr_i[k] = 56'h00_0000_0001_2340;
    repeat (2) @(posedge clk); #1;
    show("after the miss retired");

    // ---- the flush walk ----
    $display("MEASURE: --- the flush walk on the cache array ---");
    @(negedge clk);
    mshr_addr_i = '0;
    walk_reqs = 0; walk_writes = 0; seen_vldrty = '0; watching = 1;
    @(negedge clk); flush_i = 1'b1;
    @(posedge clk); @(negedge clk); flush_i = 1'b0;
    t = 0; while (t < 20000 && dut.i_miss_handler.state_q !== 4'h0) begin @(posedge clk); t++; end
    watching = 0;
    $display("MEASURE: flush walk: cycles=%0d array_reqs=%0d array_writes=%0d", t, walk_reqs, walk_writes);
    $display("MEASURE: flush walk: first addr=0x%03h last addr=0x%03h  NUM_WORDS=%0d",
             first_addr, last_addr, NUM_WORDS);
    $display("MEASURE: flush walk: be_o.vldrty bits seen = %08b (all-ones = invalidate every way)",
             seen_vldrty);

    $display("TEST_RESULT: PROBE -- not a score");
    $finish;
  end

  initial begin #4000000; $display("MEASURE: watchdog"); $display("TEST_RESULT: PROBE"); $finish; end
endmodule
