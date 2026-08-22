// Non-equivalence witness harness -- rule 16. Scoring support, never shipped.
//
// Drives the golden and ONE mutant from a SHARED input sequence and compares
// their observable outputs every cycle. The output payload is masked by
// pop_valid_o and push_ready_o by push_valid_i, because clause L2 leaves the
// payload free while valid is low and clause H3 says a ready bit carries no
// meaning while nothing is offered. Comparing them raw reports differences
// nothing can observe.
//
// Build once per mutant:  -DMUT_MOD=sr_mN_...
`ifndef MUT_MOD
  `define MUT_MOD sr_m1_rotation_off_by_one
`endif

module nonequiv_tb;
  logic clk = 1'b0; always #5 clk = ~clk;
  logic rst_n = 1'b0, clr = 1'b0;
  logic ra = 1'b0, fst = 1'b0, lst = 1'b0;
  logic [3:0]  strb = 4'hF;
  logic [31:0] pdata = '0; logic [3:0] pstrb = 4'hF; logic pvalid = 1'b0;
  logic [3:0]  pstrb_drive = 4'hF;   // what the SOURCE puts on push_strb_i
  logic pready_g, pready_m;
  logic [31:0] qdata_g, qdata_m; logic [3:0] qstrb_g, qstrb_m;
  logic qvalid_g, qvalid_m; logic qready = 1'b1;

  `define CONN(rdy, qd, qs, qv) \
    .clk_i(clk), .rst_ni(rst_n), .clear_i(clr), .realign_i(ra), .first_i(fst), \
    .last_i(lst), .strb_i(strb), .push_data_i(pdata), .push_strb_i(pstrb), \
    .push_valid_i(pvalid), .push_ready_o(rdy), .pop_data_o(qd), .pop_strb_o(qs), \
    .pop_valid_o(qv), .pop_ready_i(qready)

  stream_realign i_g (`CONN(pready_g, qdata_g, qstrb_g, qvalid_g));
  `MUT_MOD       i_m (`CONN(pready_m, qdata_m, qstrb_m, qvalid_m));

  int cyc = 0; always @(posedge clk) if (rst_n) cyc <= cyc + 1;

  int    diff_cyc = -1;
  string diff_what = "";
  always @(posedge clk) if (rst_n && diff_cyc < 0) begin
    if (qvalid_g !== qvalid_m) begin
      diff_cyc = cyc;
      diff_what = $sformatf("pop_valid_o: golden %b / mutant %b", qvalid_g, qvalid_m);
    end else if (qvalid_g && (qdata_g !== qdata_m || qstrb_g !== qstrb_m)) begin
      diff_cyc = cyc;
      diff_what = $sformatf("output beat: golden data=%08x strb=%b / mutant data=%08x strb=%b",
                            qdata_g, qstrb_g, qdata_m, qstrb_m);
    end else if (pvalid && (pready_g !== pready_m)) begin
      diff_cyc = cyc;
      diff_what = $sformatf("push_ready_o while offering: golden %b / mutant %b",
                            pready_g, pready_m);
    end
  end

  // A beat advances only once BOTH sides have taken it, so the two see an
  // identical input sequence and a difference in ready timing is itself a
  // witness.
  task automatic beat(input logic [31:0] d, input bit is_first, input bit is_last);
    @(negedge clk); pdata = d; pstrb = pstrb_drive; fst = is_first; lst = is_last; pvalid = 1'b1;
    forever begin @(posedge clk); if (pready_g && pready_m) break; end
    @(negedge clk) pvalid = 1'b0; fst = 1'b0; lst = 1'b0;
  endtask

  task automatic line(input logic [3:0] s, input int n, input logic [31:0] base);
    @(negedge clk); strb = s;
    for (int i = 0; i < n; i++) beat(base + 32'(i * 32'h04040404), i == 0, i == n - 1);
    repeat (4) @(posedge clk);
  endtask

  initial begin
    repeat (4) @(posedge clk); @(negedge clk) rst_n = 1'b1; repeat (2) @(posedge clk);

    // 1. pass-through
    @(negedge clk) ra = 1'b0;
    line(4'hF, 4, 32'h03020100);

    // 2. realigning at every offset the strobe can name
    @(negedge clk) ra = 1'b1;
    line(4'b1111, 4, 32'h13121110);      // rotation 0 -- the degenerate case
    @(negedge clk) clr = 1'b1; @(negedge clk) clr = 1'b0;
    line(4'b1110, 4, 32'h23222120);
    @(negedge clk) clr = 1'b1; @(negedge clk) clr = 1'b0;
    line(4'b1100, 5, 32'h33323130);
    @(negedge clk) clr = 1'b1; @(negedge clk) clr = 1'b0;
    line(4'b1000, 5, 32'h43424140);

    // 3. a PARTIAL input strobe while realigning. R3 fixes the output strobe at
    //    all ones whatever the input carried, and an implementation that simply
    //    forwards push_strb_i is indistinguishable from a correct one until the
    //    source drives something other than a full strobe.
    @(negedge clk) clr = 1'b1; @(negedge clk) clr = 1'b0;
    @(negedge clk) pstrb_drive = 4'b0011;
    line(4'b1100, 4, 32'h73727170);
    @(negedge clk) pstrb_drive = 4'hF;

    // 4. a final beat whose strobe is empty
    @(negedge clk) clr = 1'b1; @(negedge clk) clr = 1'b0;
    @(negedge clk) strb = 4'b1100;
    beat(32'h53525150, 1, 0);
    beat(32'h57565554, 0, 0);
    @(negedge clk) strb = 4'b0000;
    beat(32'h5B5A5958, 0, 1);
    repeat (6) @(posedge clk);

    // 4. the sink stalls mid-line
    @(negedge clk) clr = 1'b1; @(negedge clk) clr = 1'b0;
    @(negedge clk) strb = 4'b1110;
    beat(32'h63626160, 1, 0);
    @(negedge clk) qready = 1'b0;
    repeat (6) @(posedge clk);
    @(negedge clk) qready = 1'b1;
    beat(32'h67666564, 0, 0);
    beat(32'h6B6A6968, 0, 1);
    repeat (8) @(posedge clk);

    if (diff_cyc >= 0)
      $display("WITNESS %s: first difference at cycle %0d -- %s", `"`MUT_MOD`", diff_cyc, diff_what);
    else
      $display("WITNESS %s: NO DIFFERENCE OBSERVED -- treat the HARNESS as suspect, not the mutant",
               `"`MUT_MOD`");
    $finish;
  end
  initial begin #300000;
    $display("WITNESS %s: watchdog, diff_cyc=%0d -- %s", `"`MUT_MOD`", diff_cyc,
             (diff_cyc >= 0) ? diff_what : "NO DIFFERENCE OBSERVED, harness suspect");
    $finish; end
endmodule
