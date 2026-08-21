module route_xbar_tb;
// ---------------------------------------------------------------------------
// PROVIDED PLUMBING -- moves beats, checks nothing.
// ---------------------------------------------------------------------------
// This exists so you spend your effort on checking rather than on handshake
// mechanics. It has been compiled and run against a correct design.
//
// What it does: generates the clock, sequences reset, connects the design, and
// keeps each input offering the beat you have put in front of it -- holding the
// offer unchanged until it is taken, which is what clause H2 requires of a
// source, and starting the next one the moment it is.
//
// What it does NOT do: it chooses no payloads, keeps no model of what went
// where, counts nothing, and draws no conclusion from any signal. Routing,
// ordering, delivery, fairness and every check are yours to write.
//
// TWO THINGS WORTH KNOWING, both of which cost real time to find:
//
//   * The driver below is an ALWAYS BLOCK, not a loop you pump from your
//     stimulus. A pumped loop only services the edges it happens to be waiting
//     on, and every edge you wait on elsewhere -- to change a ready line, to
//     bring another input in -- is an edge where a beat can be accepted
//     unnoticed. Keep presenting a beat that has already been taken and the
//     design takes it again, which looks exactly like the design delivering it
//     twice.
//
//   * Sample a handshake AT the rising edge. `in_ready_o` read at the falling
//     edge is not necessarily the value the design used.
// ---------------------------------------------------------------------------

  localparam int N_IN = 4, N_OUT = 4, DW = 32, SW = 2, IW = 2;

  // ---- clock ---------------------------------------------------------------
  logic clk = 1'b0;
  always #5 clk = ~clk;

  int bfm_cycle = 0;
  always @(posedge clk) if (rst_n) bfm_cycle <= bfm_cycle + 1;

  // ---- reset ---------------------------------------------------------------
  logic rst_n = 1'b0;        // ASYNCHRONOUS, ACTIVE LOW

  task automatic bfm_reset(input int cycles = 5);
    @(negedge clk);
    rst_n = 1'b0;
    repeat (cycles) @(posedge clk);
    @(negedge clk);
    rst_n = 1'b1;
  endtask

  // ---- signals and the design under test -----------------------------------
  logic [N_IN*DW-1:0]  in_data;
  logic [N_IN*SW-1:0]  in_sel;
  logic [N_IN-1:0]     in_valid, in_ready;
  logic [N_OUT*DW-1:0] out_data;
  logic [N_OUT*IW-1:0] out_idx;
  logic [N_OUT-1:0]    out_valid, out_ready;

  route_xbar #(.N_IN(N_IN), .N_OUT(N_OUT), .DATA_W(DW), .SEL_W(SW), .IDX_W(IW)) dut (
    .clk_i(clk), .rst_ni(rst_n),
    .in_data_i(in_data), .in_sel_i(in_sel), .in_valid_i(in_valid), .in_ready_o(in_ready),
    .out_data_o(out_data), .out_idx_o(out_idx), .out_valid_o(out_valid),
    .out_ready_i(out_ready));

  // Convenience slicers.
  function automatic logic [DW-1:0] bfm_odata(input int j); return out_data[j*DW +: DW]; endfunction
  function automatic logic [IW-1:0] bfm_oidx (input int j); return out_idx [j*IW +: IW]; endfunction

  // ---- what you drive ------------------------------------------------------
  // Set bfm_offer[k] to keep input k offering. Put the payload and selector for
  // the NEXT beat in bfm_next_data[k] / bfm_next_sel[k]; the driver picks them
  // up when it starts a beat, and never mid-offer.
  logic [N_IN-1:0]  bfm_offer;
  logic [DW-1:0]    bfm_next_data [N_IN];
  logic [SW-1:0]    bfm_next_sel  [N_IN];

  // Registered handshake: bfm_accepted[k] is high for the cycle following the
  // rising edge on which input k's beat was taken.
  logic [N_IN-1:0]  bfm_accepted;
  always @(posedge clk) bfm_accepted <= (rst_n ? (in_valid & in_ready) : '0);

  always @(negedge clk) begin
    if (!rst_n) begin
      in_valid = '0;
    end else begin
      for (int k = 0; k < N_IN; k++) begin
        if (bfm_accepted[k]) in_valid[k] = 1'b0;          // that beat is gone
        if (!in_valid[k] && bfm_offer[k]) begin           // start the next one
          in_data[k*DW +: DW] = bfm_next_data[k];
          in_sel [k*SW +: SW] = bfm_next_sel[k];
          in_valid[k]         = 1'b1;
        end
      end
    end
  end

  task automatic bfm_ready(input logic [N_OUT-1:0] v); out_ready = v; endtask

  // ---- idle everything at time zero ----------------------------------------
  initial begin
    in_data = '0; in_sel = '0; in_valid = '0; out_ready = '1; bfm_offer = '0;
    for (int k = 0; k < N_IN; k++) begin bfm_next_data[k] = '0; bfm_next_sel[k] = '0; end
  end

  // ---- watchdog ------------------------------------------------------------
  // Yours to keep. It fires regardless of what the design does: one of the
  // faulty designs never accepts anything at all, and without this your
  // testbench hangs instead of reporting. A hang is not a verdict.
  initial begin
    #2_000_000;
    $display("RESULT: FAIL (watchdog: no verdict reached)");
    $finish;
  end

  // ---- smoke: does the plumbing move beats? --------------------------------
  int seq [N_IN];
  int n_del = 0;
  always @(posedge clk) if (rst_n)
    for (int j = 0; j < N_OUT; j++) if (out_valid[j] && out_ready[j]) n_del++;
  always @(negedge clk) if (rst_n)
    for (int k = 0; k < N_IN; k++)
      if (bfm_accepted[k]) begin seq[k]++; bfm_next_data[k] = {4'(k), 28'(seq[k])}; end

  initial begin
    for (int k = 0; k < N_IN; k++) seq[k] = 0;
    bfm_reset();
    for (int k = 0; k < N_IN; k++) begin
      bfm_next_data[k] = {4'(k), 28'd0};
      bfm_next_sel[k]  = SW'(0);
      bfm_offer[k]     = 1'b1;
    end
    repeat (40) @(posedge clk);
    $display("SMOKE: four inputs all bound for output 0, 40 cycles -> %0d delivered", n_del);
    for (int k = 0; k < N_IN; k++) bfm_next_sel[k] = SW'(k);
    repeat (40) @(posedge clk);
    $display("SMOKE: then each to its own output -> %0d delivered in total", n_del);
    bfm_ready(4'b1110);
    repeat (20) @(posedge clk);
    $display("SMOKE: with output 0 stalled, in_ready_o = %b", in_ready);
    $display("RESULT: PASS");
    $finish;
  end
endmodule
