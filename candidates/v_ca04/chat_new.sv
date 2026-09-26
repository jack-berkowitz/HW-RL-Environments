module route_xbar_tb;
  logic rst_n = 1'b0;
  localparam int N_IN = 4, N_OUT = 4, DW = 32, SW = 2, IW = 2;
  // ---- clock ---------------------------------------------------------------
  logic clk = 1'b0;
  always #5 clk = ~clk;
  int bfm_cycle = 0;
  always @(posedge clk) if (rst_n) bfm_cycle <= bfm_cycle + 1;
  // ---- reset ---------------------------------------------------------------
  // rst_n declared above;        // ASYNCHRONOUS, ACTIVE LOW
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
  // Bookkeeping is indexed by output-reported source AND destination, never
  // by searching for payload values. Repeated data is intentional.
  logic [31:0] pending[4][4][$];
  logic [3:0] held_valid='0;
  logic [31:0] held_data[4];
  logic [1:0] held_idx[4];
  int age[4];
  int accepted_count=0,delivered_count=0;
  bit ended=0, idle_state=0;
  logic [3:0] wanted_ready=4'hf;
  bit fair_active=0, wanted_fair=0;
  logic [3:0] wanted_mask=0;
  int wanted_output=0;
  logic [3:0] fair_mask=0;
  int fair_output=0, fair_window[$], fair_transfers=0;
  int data_tick=0;

  task automatic fail(input string clause,input string detail);
    if(!ended)begin
      ended=1;
      $display("%s: %s (cycle %0d)",clause,detail,bfm_cycle);
      $display("RESULT: FAIL");
      $finish;
    end
  endtask

  // Stimulus controls change at posedges; actual DUT inputs change at negedges.
  // The checker samples only posedges. No stimulus delta-delay is required.
  always @(negedge clk)begin
    bfm_ready(wanted_ready);
    fair_active=wanted_fair;fair_mask=wanted_mask;fair_output=wanted_output;
  end
  always @(posedge clk)begin
    data_tick++;
    for(int k=0;k<4;k++)begin
      case(data_tick%8)
        0,1: bfm_next_data[k]=32'h55aa55aa;
        2: bfm_next_data[k]=0;
        3: bfm_next_data[k]='1;
        default: bfm_next_data[k]=32'(data_tick)*32'h01010101 ^ (32'(k)<<28);
      endcase
    end
  end

  always @(posedge clk)begin : checks
    automatic int src,dst,total,n,junk;
    automatic logic [31:0] value;
    automatic logic [3:0] seen;
    total=0;
    if(!rst_n)begin
      // Inputs are deliberately quiet while reset is low (X1's qualification).
      if((|(in_valid&in_ready)) || (|(out_valid&out_ready)))
        fail("X1","transfer during reset with quiet inputs");
      for(int k=0;k<4;k++)begin
        age[k]=0;
        for(int j=0;j<4;j++)pending[k][j].delete();
      end
      held_valid=0;fair_window.delete();fair_transfers=0;
      accepted_count=0;delivered_count=0;idle_state<=0;
    end else begin
      // Enqueue inputs first: a combinational crossbar may deliver a beat on
      // the exact same edge that accepts it.
      for(int k=0;k<4;k++)begin
        dst=int'(in_sel[k*SW+:SW]);
        if(in_valid[k]&&in_ready[k])begin
          pending[k][dst].push_back(in_data[k*DW+:DW]);
          accepted_count++;age[k]=0;
        end else if(in_valid[k]&&out_ready[dst])begin
          age[k]++;
          if(age[k]>=32)fail("X3","offer not accepted within 32 continuously-ready cycles (I1/I2)");
        end else age[k]=0;
      end
      for(int j=0;j<4;j++)begin
        if(held_valid[j])begin
          if(!out_valid[j] || bfm_odata(j)!==held_data[j] || bfm_oidx(j)!==held_idx[j])
            fail("A3","stalled output offer withdrawn, payload changed, or source changed");
        end
        held_valid[j]=out_valid[j]&&!out_ready[j];
        if(held_valid[j])begin held_data[j]=bfm_odata(j);held_idx[j]=bfm_oidx(j);end
        if(out_valid[j]&&out_ready[j])begin
          src=int'(bfm_oidx(j));
          if(pending[src][j].size()==0)
            fail("R6","output has no corresponding acceptance on reported source/route (R1/R3/R4)");
          else begin
            value=pending[src][j].pop_front();delivered_count++;
            if(bfm_odata(j)!==value)fail("R2","payload mismatch or same-source same-route reorder (R5)");
          end
          // These phases have exactly the selected contenders, all offering
          // without bubbles to one output. Check every sliding |S|-transfer
          // window, independent of the initial phase of rotation and stalls.
          if(fair_active&&j==fair_output)begin
            if(!fair_mask[src])fail("R3","noncontending source reported in fairness phase");
            fair_transfers++;fair_window.push_back(src);
            n=$countones(fair_mask);
            if(fair_window.size()>n)junk=fair_window.pop_front();
            if(fair_window.size()==n)begin
              seen=0;
              for(int q=0;q<n;q++)seen[fair_window[q]]=1;
              if(seen!=fair_mask)fail("A2","not every continuous contender served in a sliding |S|-transfer window");
            end
          end
        end
      end
      for(int k=0;k<4;k++)for(int j=0;j<4;j++)total+=pending[k][j].size();
      idle_state <= (in_valid==0 && total==0);
      if(!fair_active)begin fair_window.delete();fair_transfers=0;end
    end
  end

  task automatic wait_cycles(input int count);
    repeat(count)@(posedge clk);
  endtask

  task automatic drain;
    @(posedge clk);bfm_offer=0;wanted_ready=4'hf;wanted_fair=0;
    // There is no local input-to-output latency bound. The global watchdog
    // detects a loss or a permanently stuck implementation (R4).
    @(negedge clk);
    while(!idle_state)@(negedge clk);
    repeat(8)@(posedge clk);
    if(accepted_count!=delivered_count)fail("R4","accepted/delivered totals differ after drain");
  endtask

  task automatic fairness_phase(input logic [3:0] members,input int output_no);
    drain();
    @(posedge clk);
    for(int k=0;k<4;k++)bfm_next_sel[k]=2'(output_no);
    bfm_offer=members;wanted_ready=4'hf;
    wanted_mask=members;wanted_output=output_no;wanted_fair=1;
    // Run enough cycles for many windows, while periodically stalling the
    // selected output. Stalls must neither count as service nor change offers.
    for(int c=0;c<180;c++)begin
      @(posedge clk);
      wanted_ready=4'hf;
      if((c%23)>=12 && (c%23)<19)wanted_ready[output_no]=0;
    end
    // Require observed windows, not a particular cycle latency.
    @(posedge clk);wanted_ready=4'hf;
    @(negedge clk);
    while(fair_transfers<24)@(negedge clk);
    drain();
  endtask

  task automatic independence_phase(input int blocked_output);
    drain();
    @(posedge clk);
    for(int k=0;k<4;k++)bfm_next_sel[k]=2'(k);
    bfm_offer=4'hf;wanted_ready=4'hf;wanted_ready[blocked_output]=0;
    wait_cycles(120);
    // Three continuously-ready routes must keep accepting, via X3. No bound
    // is imposed on how many entries the blocked route can buffer internally.
    @(posedge clk);wanted_ready=4'hf;
    wait_cycles(60);drain();
  endtask

  initial begin : stimulus
    automatic logic [31:0] prng;
    bfm_reset();
    // No input offers: reject unsolicited output transfers (R6/X2).
    wait_cycles(20);
    // Exercise all sixteen routes individually, including repeating data.
    for(int k=0;k<4;k++)for(int j=0;j<4;j++)begin
      @(posedge clk);bfm_next_sel[k]=2'(j);bfm_offer=4'(1<<k);
      wait_cycles(12);drain();
    end
    // Every nonempty contender subset, for every output. No particular
    // starting winner is required, and no comparison is made across outputs.
    for(int j=0;j<4;j++)for(int mask_no=1;mask_no<16;mask_no++)
      fairness_phase(4'(mask_no),j);
    for(int j=0;j<4;j++)independence_phase(j);

    // Bring new contenders into a stalled output after an offer is visible.
    // The source that wins is learned, not assumed from an arbiter policy.
    for(int j=0;j<4;j++)begin
      drain();
      @(posedge clk);
      for(int k=0;k<4;k++)bfm_next_sel[k]=2'(j);
      bfm_offer=4'b1000;wanted_ready=4'hf;wanted_ready[j]=0;
      @(negedge clk);
      // If the DUT waits for READY before it originates VALID, that is not
      // itself forbidden. The fixed stall phase still exercises A3 whenever
      // an offer appears; don't demand an offer under backpressure.
      repeat(8)@(posedge clk);
      bfm_offer=4'hf;
      wait_cycles(20);
      @(posedge clk);wanted_ready=4'hf;
      wait_cycles(80);drain();
    end

    // Route changes affect only NEXT offers. The BFM holds every pending beat
    // unchanged until its actual input handshake, honoring H2 throughout.
    prng=32'h6a09e667;
    for(int c=0;c<2500;c++)begin
      @(posedge clk);
      prng={prng[30:0],prng[31]^prng[21]^prng[1]^prng[0]};
      bfm_offer=prng[3:0];wanted_ready=prng[7:4];
      for(int k=0;k<4;k++)bfm_next_sel[k]=prng[8+2*k+:2];
      if((c%64)<8)wanted_ready=4'hf;
    end
    drain();
    // Accept exactly one final beat, then block its destination before the
    // next rising edge. Buffered implementations now retain data for reset;
    // a combinational implementation may already have delivered it (L1/L3).
    // In either case no unaccepted source offer is withdrawn.
    @(posedge clk);
    bfm_next_sel[0]=2;bfm_offer=1;wanted_ready=4'hf;
    do @(posedge clk); while(!(in_valid[0]&&in_ready[0]));
    bfm_offer=0;wanted_ready=4'b1011;
    // At the next falling edge the BFM removes only the accepted offer.
    @(posedge clk);
    bfm_reset();
    @(posedge clk);wanted_ready=4'hf;
    wait_cycles(24);
    fairness_phase(4'hf,2);
    drain();
    if(!ended)begin ended=1;$display("RESULT: PASS");$finish;end
  end

  initial begin
    #2_000_000;
    fail("R4/X3","watchdog: no verdict / missing delivery or forward progress");
  end
endmodule
