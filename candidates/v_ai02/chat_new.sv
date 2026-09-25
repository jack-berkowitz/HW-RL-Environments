`timescale 1ns/1ps
module stream_realign_tb;
  // ---- clock ---------------------------------------------------------------

  logic clk = 1'b0;

  always #5 clk = ~clk;

  int bfm_cycle = 0;

  always @(posedge clk) if (rst_n) bfm_cycle <= bfm_cycle + 1;

  // ---- reset ---------------------------------------------------------------

  logic rst_n = 1'b0;          // ASYNCHRONOUS, ACTIVE LOW

  logic clr   = 1'b0;          // synchronous, active high

  task automatic bfm_reset(input int cycles = 5);

    @(negedge clk);

    rst_n = 1'b0;

    repeat (cycles) @(posedge clk);

    @(negedge clk);

    rst_n = 1'b1;

  endtask

  task automatic bfm_clear();

    @(negedge clk) clr = 1'b1;

    @(negedge clk) clr = 1'b0;

    repeat (2) @(posedge clk);

  endtask

  // ---- signals and the design under test ------------------------------------

  logic        ra = 1'b0, fst = 1'b0, lst = 1'b0;

  logic [3:0]  strb = 4'hF;

  logic [31:0] pdata = '0;

  logic [3:0]  pstrb = 4'hF;

  logic        pvalid = 1'b0, pready;

  logic [31:0] qdata;

  logic [3:0]  qstrb;

  logic        qvalid;

  logic        qready = 1'b1;

  stream_realign dut (

    .clk_i(clk), .rst_ni(rst_n), .clear_i(clr), .realign_i(ra), .first_i(fst),

    .last_i(lst), .strb_i(strb), .push_data_i(pdata), .push_strb_i(pstrb),

    .push_valid_i(pvalid), .push_ready_o(pready), .pop_data_o(qdata),

    .pop_strb_o(qstrb), .pop_valid_o(qvalid), .pop_ready_i(qready));

  // ---- what you queue --------------------------------------------------------

  typedef struct packed {

    logic [31:0] data;   // push_data_i

    logic [3:0]  dstrb;  // push_strb_i

    logic        first;  // first_i

    logic        last;   // last_i

    logic        realign;// realign_i

    logic [3:0]  lstrb;  // strb_i presented with this beat

  } bfm_beat_t;

  bfm_beat_t bfm_q [$];

  task automatic bfm_send(input logic [31:0] data, input bit first, input bit last,

                          input bit do_realign, input logic [3:0] lstrb,

                          input logic [3:0] dstrb = 4'hF);

    bfm_beat_t b;

    b.data = data; b.dstrb = dstrb; b.first = first; b.last = last;

    b.realign = do_realign; b.lstrb = lstrb;

    bfm_q.push_back(b);

  endtask

  task automatic bfm_ready(input bit v); qready = v; endtask

  // Waits until everything queued has been offered and taken.

  task automatic bfm_idle(input int max_cycles = 400);

    for (int t = 0; t < max_cycles; t++) begin

      @(posedge clk);

      if (bfm_q.size() == 0 && !pvalid) break;

    end

    repeat (6) @(posedge clk);

  endtask

  // ---- the driver ------------------------------------------------------------

  logic bfm_hs;

  always @(posedge clk) bfm_hs <= (rst_n && !clr) ? (pvalid & pready) : 1'b0;

  always @(negedge clk) begin

    if (!rst_n) begin

      pvalid = 1'b0;

    end else begin

      if (bfm_hs && bfm_q.size() > 0) begin void'(bfm_q.pop_front()); pvalid = 1'b0; end

      if (!pvalid && bfm_q.size() > 0) begin

        pdata = bfm_q[0].data;  pstrb = bfm_q[0].dstrb; fst = bfm_q[0].first;

        lst   = bfm_q[0].last;  strb  = bfm_q[0].lstrb; ra  = bfm_q[0].realign;

        pvalid = 1'b1;

      end

    end

  end

  // ---- watchdog --------------------------------------------------------------

  // Yours to keep. It fires regardless of what the design does: one of the

  // faulty designs never accepts anything, and without this your testbench

  // hangs instead of reporting. A hang is not a verdict.

  initial begin

    #2_000_000;

    verdict_fail("X3 / output accounting", "watchdog expired before all traffic completed");

  end

  // The reference model advances on INPUT HANDSHAKES only. Output records
  // are consumed in FIFO order, never identified by their data values.
  // An L4-suppressed input may retain the old word OR replace it. Preserve
  // every possible retained word until the next productive input.
  typedef struct packed {
    bit aligned;
    int unsigned alternatives;
  } expected_t;
  expected_t expected_q[$];
  logic [31:0] allowed_q[$];
  logic [31:0] retained_q[$];
  int rotation = 0;
  bit line_known = 0;
  bit clock_seen = 0;
  bit finished = 0;
  int offered_wait = 0;
  int accepted_count = 0;
  int produced_count = 0;
  int suppressed_count = 0;
  int checked_count = 0;
  int first_count = 0;
  int rotation_hits[5];

  task automatic verdict_fail(input string clause, input string detail);
    if (!finished) begin
      finished = 1;
      $display("Violation %s at cycle %0d: %s",clause,bfm_cycle,detail);
      $display("RESULT: FAIL");
      $finish;
    end
  endtask

  function automatic int popcount4(input logic [3:0] v);
    return int'(v[0])+int'(v[1])+int'(v[2])+int'(v[3]);
  endfunction

  function automatic logic [31:0] join_bytes(
      input logic [31:0] old_word, input logic [31:0] new_word,
      input int r);
    logic [31:0] joined;
    int byte_index;
    joined = 0;
    // Independent byte indexing, including the two non-modulo endpoints.
    for (int b=0;b<4;b++) begin
      byte_index = 4-r+b;
      if (byte_index<4) joined[b*8 +: 8] = old_word[byte_index*8 +: 8];
      else joined[b*8 +: 8] = new_word[(byte_index-4)*8 +: 8];
    end
    return joined;
  endfunction

  always @(posedge clk) begin : monitor
    automatic expected_t record_item;
    automatic logic [31:0] option_word;
    automatic bit matched;
    if (!rst_n || clr) begin
      if (clock_seen && !rst_n && !pvalid && qvalid !== 1'b0)
        verdict_fail("X1", "output originated while reset held and input quiet");
      expected_q.delete(); allowed_q.delete(); retained_q.delete();
      line_known = 0; rotation = 0; offered_wait = 0;
    end else begin
      // H3: never inspect ready when the source has no offer.
      if (!ra) begin
        if (qvalid !== pvalid)
          verdict_fail("P1", "transparent output valid does not follow input valid");
        if (pvalid && pready !== qready)
          verdict_fail("P1", "transparent input ready does not follow sink ready");
        if (pvalid && qvalid && qdata !== pdata)
          verdict_fail("P1", "transparent data differs from offered data");
        // P2/L3 deliberately impose NO check on qstrb in this mode.
      end
      if (pvalid && qready) begin
        if (pready === 1'b1) offered_wait = 0;
        else begin
          offered_wait++;
          if (offered_wait >= 16)
            verdict_fail("X3", "offered beat not accepted within 16 ready cycles");
        end
      end else offered_wait = 0;

      if (pvalid && pready) begin
        accepted_count++;
        if (!ra) begin
          record_item.aligned = 0; record_item.alternatives = 1;
          expected_q.push_back(record_item); allowed_q.push_back(pdata);
          produced_count++;
        end else if (fst) begin
          first_count++; rotation = popcount4(strb);
          rotation_hits[rotation]++;
          retained_q.delete(); retained_q.push_back(pdata);
          line_known = 1;
          // R1: no expected output record for the first beat.
        end else begin
          if (!line_known) verdict_fail("testbench", "stimulus omitted line first beat");
          if (lst || (strb != 0)) begin
            record_item.aligned = 1;
            record_item.alternatives = retained_q.size();
            expected_q.push_back(record_item);
            foreach (retained_q[j])
              allowed_q.push_back(join_bytes(retained_q[j],pdata,rotation));
            produced_count++;
            retained_q.delete(); retained_q.push_back(pdata);
          end else begin
            // L4: do NOT choose whether the silent beat replaces retention.
            retained_q.push_back(pdata); suppressed_count++;
          end
          if (lst) line_known = 0;
        end
      end
      if (qvalid && qready) begin
        if (expected_q.size()==0)
          verdict_fail("R1/R2/H1", "unexpected output: first/suppressed beat or duplication");
        else begin
          record_item = expected_q.pop_front();
          matched = 0;
          for (int j=0;j<int'(record_item.alternatives);j++) begin
            option_word = allowed_q.pop_front();
            if (qdata === option_word) matched = 1;
          end
          if (!matched)
            verdict_fail(record_item.aligned ? "R2/R4/R5/R6" : "P1",
                         $sformatf("output %0d has incorrect bytes: %08x",checked_count,qdata));
          if (record_item.aligned && qstrb !== 4'hf)
            verdict_fail("R3", "realigned output strobe is not all ones");
          checked_count++;
        end
      end
      // L2: payloads with valid low are never checked.
    end
    clock_seen = 1;
  end

  // This routine waits for acceptance AND all owed outputs. There is no
  // invented per-output latency requirement; the global watchdog terminates
  // a design that never delivers an owed output. Mode changes occur drained.
  task automatic drain();
    bfm_idle(2000);
    while (bfm_q.size()!=0 || pvalid || expected_q.size()!=0)
      @(posedge clk);
    repeat (20) @(posedge clk);
  endtask

  task automatic ready_at_fall(input bit value);
    @(negedge clk);
    bfm_ready(value);
  endtask

  function automatic logic [31:0] pattern(input int seed);
    logic [31:0] v;
    // Every lane differs, while some whole words repeat intentionally.
    v[7:0]   = 8'(seed*13+7);
    v[15:8]  = 8'(seed*29+53);
    v[23:16] = 8'(seed*47+109);
    v[31:24] = 8'(seed*71+193);
    return v;
  endfunction

  task automatic send_line(input logic [3:0] initial_mask,
                           input int seed, input bit silent_beats);
    bfm_send(pattern(seed),1,0,1,initial_mask,4'h0);
    bfm_send(pattern(seed+1),0,0,1,4'h1,4'h2);
    bfm_send(pattern(seed+2),0,0,1,4'hf,4'h0);
    if (silent_beats) begin
      bfm_send(pattern(seed+3),0,0,1,4'h0,4'hf);
      bfm_send(pattern(seed+4),0,0,1,4'h0,4'h1);
    end
    bfm_send(pattern(seed+5),0,0,1,4'ha,4'h4);
    bfm_send(pattern(seed+5),0,0,1,4'h4,4'h8);
    bfm_send(pattern(seed+6),0,0,1,4'h7,4'h5);
    // R6: final beat owes output even with a zero line strobe.
    bfm_send(pattern(seed+7),0,1,1,4'h0,4'h0);
  endtask

  initial begin : stimulus
    bfm_reset();
    // Pass-through has exact combinational handshake requirements. Data
    // strobes span all masks but output strobes are deliberately ignored.
    for (int m=0;m<16;m++)
      bfm_send(pattern(m),0,0,0,4'(15-m),4'(m));
    ready_at_fall(0);
    repeat (7) @(posedge clk);
    ready_at_fall(1);
    drain();

    // All 16 first-beat masks, including noncontiguous masks, test POPCOUNT,
    // not a leading-one position, a shift value, or a modulo-4 rotation.
    // Later masks change repeatedly without changing the captured rotation.
    for (int m=0;m<16;m++) begin
      send_line(4'(m),m*11,0);
      send_line(4'(15-m),m*17+101,1);
    end
    drain();

    // R1 takes priority even when the first beat is also marked last.
    for (int r=0;r<5;r++)
      bfm_send(pattern(350+r),1,1,1,4'((1<<r)-1),4'hf);
    drain();

    // First-beat backpressure: both accept-now and wait-for-ready are legal.
    // No assertion about ready or acceptance is made during these stalls.
    for (int r=0;r<5;r++) begin
      ready_at_fall(0);
      bfm_send(pattern(400+r),1,0,1,4'((1<<r)-1),4'h0);
      repeat (8) @(posedge clk);
      ready_at_fall(1);
      bfm_send(pattern(410+r),0,0,1,4'hf,4'h1);
      bfm_send(pattern(420+r),0,1,1,4'h0,4'h2);
      drain();
    end

    // Multi-beat streams under repeated sink stalls. Queueing never changes
    // an outstanding offer; the provided driver enforces H2.
    for (int n=0;n<40;n++) send_line(4'((n*7)&15),n*19+500,(n%3)==0);
    for (int n=0;n<30;n++) begin
      ready_at_fall(0);
      repeat (3+(n%5)) @(posedge clk);
      ready_at_fall(1);
      repeat (2+(n%7)) @(posedge clk);
    end
    drain();

    // Quiet clear/reset after a retained first beat; restart with an explicit
    // first beat because behaviour without one is outside this contract.
    bfm_send(32'hd3a27109,1,0,1,4'hb,4'h0);
    drain();
    bfm_clear();
    send_line(4'h1,1700,0);
    drain();
    bfm_send(32'h2c5e80b7,1,0,1,4'hf,4'hf);
    drain();
    bfm_reset(4);
    send_line(4'h0,1800,0);
    send_line(4'hf,1900,0);
    drain();

    // Return to transparent mode only after the realigned stream drains.
    for (int m=0;m<16;m++) bfm_send(pattern(2000+m),0,0,0,4'(m),4'(15-m));
    drain();
    for (int r=0;r<5;r++)
      if(rotation_hits[r]==0) verdict_fail("testbench", "missing rotation coverage");
    if (expected_q.size()!=0 || allowed_q.size()!=0 || produced_count!=checked_count)
      verdict_fail("R2/R5/H1", "missing output or inconsistent output count");
    if (!finished) begin
      finished = 1;
      $display("Checked %0d outputs from %0d inputs; %0d first beats, %0d silent beats",
               checked_count,accepted_count,first_count,suppressed_count);
      $display("RESULT: PASS");
      $finish;
    end
  end
endmodule
