// Reference testbench for v_ca04 route_xbar. Scoring reference, not shipped.
//
// It carries a MODEL: for every (input, output) pair a queue of the beats
// accepted from that input and bound for that output, plus a record of every
// beat already delivered and, per output, how many transfers have passed since
// each contender was last served. Nothing is read from a DUT internal.
//
// Payloads are unique -- the top four bits name the source input and the rest
// are a per-input sequence number -- so the source of a delivered beat is known
// independently of what out_idx_o claims, which is what makes R3 checkable at
// all rather than self-certifying.
module route_xbar_tb;

  // VCD on demand, for the rule-34 stimulus-variation check. Plusarg-guarded, so
  // a normal scoring run is byte-for-byte unaffected.
  initial if ($test$plusargs("vcd")) begin
    $dumpfile("dump.vcd");
    $dumpvars(0, route_xbar_tb);
  end
  // A3's antecedent counter, declared here because the checker below uses it.
  int  cov_a3_held = 0;
  localparam int N_IN = 4, N_OUT = 4, DW = 32, SW = 2, IW = 2;
  localparam int LIVE = 32;                 // clause X3

  int errors = 0;
  task automatic fail(input string clause, input string detail);
    if (errors < 24) $display("FAIL %s: %s", clause, detail);
    errors++;
  endtask

  logic clk = 1'b0; always #5 clk = ~clk;
  logic rst_n = 1'b0;
  logic [N_IN*DW-1:0] in_data;
  logic [N_IN*SW-1:0] in_sel;
  logic [N_IN-1:0]    in_valid, in_ready;
  logic [N_OUT*DW-1:0] out_data;
  logic [N_OUT*IW-1:0] out_idx;
  logic [N_OUT-1:0]    out_valid, out_ready;

  route_xbar #(.N_IN(N_IN), .N_OUT(N_OUT), .DATA_W(DW), .SEL_W(SW), .IDX_W(IW)) dut (
    .clk_i(clk), .rst_ni(rst_n),
    .in_data_i(in_data), .in_sel_i(in_sel), .in_valid_i(in_valid), .in_ready_o(in_ready),
    .out_data_o(out_data), .out_idx_o(out_idx), .out_valid_o(out_valid),
    .out_ready_i(out_ready));

  int cyc = 0; always @(posedge clk) if (rst_n) cyc <= cyc + 1;

  function automatic logic [DW-1:0] odata(input int j); return out_data[j*DW +: DW]; endfunction
  function automatic logic [IW-1:0] oidx (input int j); return out_idx [j*IW +: IW]; endfunction
  function automatic logic [DW-1:0] mk(input int k, input int seq);
    return {4'(k), 28'(seq)};
  endfunction
  function automatic int src_of(input logic [DW-1:0] d); return int'(d[31:28]); endfunction

  // ---------------- the model ----------------
  logic [DW-1:0] pair_q [N_IN][N_OUT][$];   // accepted, bound for that output, in order

  // ---- the delivery selector, EXTRACTED so it can be tested ------------------
  // This decision used to be inline in the checker, and an inline decision can
  // only be exercised by driving the whole design into the state it decides on.
  // Attribution is a property of the TESTBENCH -- which name a path reports
  // under -- and no mutation of the design can move it, so the mutant set cannot
  // reach this at all. Naming the selector is what makes it callable with the
  // state constructed, which is the only way the branch that no stimulus reaches
  // gets a case.
  //
  // REFACTORING FOR TESTABILITY IS EXPECTED HERE, NOT A SMELL. Every inline id
  // choice in this corpus has the same property: it is correct by construction
  // and measured by nothing until it has a name. Extracting it is the first step
  // of writing its attribution cases, and it will recur on every selector that
  // was written as an if/else in a checker.
  function automatic int bound_output_for(input int s, input int j, input logic [DW-1:0] d);
    for (int jo = 0; jo < N_OUT; jo++)
      if (jo != j)
        for (int q = 0; q < pair_q[s][jo].size(); q++)
          if (pair_q[s][jo][q] === d) return jo;
    return -1;
  endfunction

  // R1 vs R6, and the two are not the same kind of fault. R1 is a beat accepted
  // bound for one output and delivered on another. R6 is a beat nothing ever
  // accepted -- neither a routing fault nor a delivery-count fault, because both
  // presuppose acceptance and a fabricated beat satisfies them vacuously.
  function automatic string gov_delivery(input int s, input int j, input logic [DW-1:0] d);
    return (bound_output_for(s, j, d) >= 0) ? "R1" : "R6";
  endfunction
  bit            seen [logic [DW-1:0]];      // every beat ever delivered
  int            n_acc = 0, n_del = 0;
  bit            checking = 1'b0;

  // fairness bookkeeping, per output
  int  since [N_OUT][N_IN];                  // transfers on j since k was last served
  bit  contend [N_OUT][N_IN];                // k is currently offering to j
  int  n_contend [N_OUT];
  bit  fair_on = 1'b0;

  // A3 stability. BOTH valid and ready are remembered from the previous cycle:
  // the obligation is "it was offered and did not move", and pairing last
  // cycle's valid with THIS cycle's ready reports a violation on the very cycle
  // a beat legitimately moved and a stall began.
  logic [N_OUT-1:0]    pv, pr;
  logic [N_OUT*DW-1:0] pd;
  logic [N_OUT*IW-1:0] px;

  // ---------------- deliver side: R1..R5, A2, A3 ----------------
  // ONE always block, and the accept side is recorded FIRST. With no register
  // on the output path a beat can be accepted and delivered in the SAME cycle;
  // if the delivery check runs before the accept has been recorded, a perfectly
  // ordinary beat is reported as "never accepted" and the diagnosis names the
  // wrong clause. Two always blocks leave that order to chance.
  always @(posedge clk) if (rst_n && checking) begin
    for (int unsigned k = 0; k < N_IN; k++)
      if (in_valid[k] && in_ready[k]) begin
        automatic int ja = int'(in_sel[k*SW +: SW]);
        pair_q[k][ja].push_back(in_data[k*DW +: DW]);
        n_acc++;
      end

    for (int unsigned j = 0; j < N_OUT; j++) begin
      // ---- A3: an offered beat may not be withdrawn or re-aimed ----
      // A3's ANTECEDENT, counted HERE, where it can be seen. The floor block
      // cannot see it: whether an offer is ever held against a low ready is the
      // DESIGN's to decide, and a design that asserts out_valid_o only when
      // out_ready_i is already high keeps this false for the whole run. The old
      // floor counted cov_lockin_probe, which my own probe sets, so it reported
      // "A3 is untested" when I forgot to run the probe and never when the
      // design declined to enter the state.
      if (pv[j] && !pr[j]) cov_a3_held++;
      if (pv[j] && !pr[j]) begin
        if (!out_valid[j])
          fail("A3", $sformatf("cycle %0d: out_valid_o[%0d] was withdrawn without a transfer", cyc, j));
        else if (pd[j*DW +: DW] !== odata(j) || px[j*IW +: IW] !== oidx(j))
          fail("A3", $sformatf("cycle %0d: output %0d changed the beat it was offering (data %08x->%08x, idx %0d->%0d) before it moved",
                               cyc, j, pd[j*DW +: DW], odata(j), px[j*IW +: IW], oidx(j)));
      end

      if (out_valid[j] && out_ready[j]) begin
        automatic logic [DW-1:0] d = odata(j);
        automatic int s = src_of(d);
        n_del++;
        // ---- R4: never twice ----
        if (seen.exists(d))
          fail("R4", $sformatf("cycle %0d: output %0d delivered payload %08x a second time", cyc, j, d));
        else begin
          seen[d] = 1'b1;
          // ---- R3: idx must name the true source ----
          if (int'(oidx(j)) != s)
            fail("R3", $sformatf("cycle %0d: output %0d delivered a beat from input %0d but reported idx %0d",
                                 cyc, j, s, oidx(j)));
          // ---- R1, R2, R5: right output, unaltered, in order for the pair ----
          if (s >= N_IN)
            fail("R2", $sformatf("cycle %0d: output %0d delivered payload %08x, which names no input", cyc, j, d));
          else if (pair_q[s][j].size() == 0) begin
            // WAS fail("R1/R4", ...) -- ONE COMPOUND ID FOR TWO DIFFERENT FACTS.
            // "R1/R4" is not a clause, so the verdict named a token no clause
            // matches and a reader could not route it. The two causes ARE
            // distinguishable from state already in scope: pair_q is indexed by
            // (source, destination), so every queue for source s is visible here.
            //   found outstanding for another output -> accepted bound for j',
            //     delivered on j. That is R1 and nothing else.
            //   found nowhere -> a beat was delivered that nothing ever accepted.
            // The DUPLICATE case cannot reach this branch: seen.exists(d) catches
            // it eight lines above and already reports under R4's own id. So this
            // site was never R1/R4 -- it is R1 plus a third state.
            automatic int bound_for = bound_output_for(s, j, d);
            if (gov_delivery(s, j, d) == "R1")
              fail("R1", $sformatf("cycle %0d: output %0d delivered payload %08x from input %0d, which was accepted bound for output %0d -- R1 says a beat accepted while in_sel_i names j is delivered on j and on no other",
                                   cyc, j, d, s, bound_for));
            else
              // R6. The beat was never accepted on any input for any output, so
              // it is neither a routing fault (R1) nor a delivery-count fault
              // (R4) -- both presuppose acceptance and a fabricated beat
              // satisfies them vacuously. R6 was added for this state, on the
              // evidence that xb_m8_duplicate_on_stall_release reaches it: the
              // mutant emits a beat before anything accepted it, then again.
              // The second emission is a genuine R4; the first had no clause.
              fail("R6", $sformatf("cycle %0d: output %0d delivered payload %08x naming input %0d, which was never accepted on any input for any output (cycle %0d)",
                                   cyc, j, d, s, cyc));
          end
          else if (pair_q[s][j][0] !== d) begin
            // Is this beat further down the queue? If so the beats ahead of it
            // were never delivered -- that is loss, not reordering, and naming
            // the wrong one sends a reader looking for the wrong defect.
            automatic int at = -1;
            for (int q = 0; q < pair_q[s][j].size(); q++)
              if (pair_q[s][j][q] === d) begin at = q; break; end
            if (at > 0)
              fail("R4", $sformatf("cycle %0d: output %0d delivered %08x from input %0d, skipping %0d earlier beat(s) that were accepted and never delivered -- the first was %08x",
                                   cyc, j, d, s, at, pair_q[s][j][0]));
            else
              fail("R5", $sformatf("cycle %0d: output %0d delivered %08x from input %0d out of order; %08x was accepted first",
                                   cyc, j, d, s, pair_q[s][j][0]));
            // consume up to and including it, so one defect does not cascade
            if (at >= 0) for (int q = 0; q <= at; q++) void'(pair_q[s][j].pop_front());
          end
          else
            void'(pair_q[s][j].pop_front());
        end
        // ---- A2: the fairness window ----
        if (fair_on) begin
          for (int unsigned k = 0; k < N_IN; k++) if (contend[j][k]) begin
            if (int'(oidx(j)) == int'(k)) since[j][k] = 0;
            else begin
              since[j][k]++;
              if (since[j][k] >= n_contend[j])
                fail("A2", $sformatf("cycle %0d: output %0d has served %0d transfers since input %0d last got one, with %0d inputs contending. Every contender must be served at least once in every %0d transfers.",
                                     cyc, j, since[j][k], k, n_contend[j], n_contend[j]));
            end
          end
        end
      end
    end
    pv <= out_valid; pr <= out_ready; pd <= out_data; px <= out_idx;
  end

  // ---- X1: nothing offered while reset is low ----
  always @(posedge clk) if (!rst_n && out_valid !== '0)
    fail("X1", "an out_valid_o bit is asserted while rst_ni is low");

  // ---------------- stimulus ----------------
  // The driver is an ALWAYS BLOCK, not a loop the stimulus thread pumps. A
  // pumped loop only services the edges it happens to be waiting on, and every
  // bare edge wait the stimulus does between phases -- to change a ready line,
  // to bring another input in -- is an edge where a beat can be accepted and
  // go unnoticed. The driver then keeps presenting a beat the design has
  // already taken, the design takes it again, and the result looks exactly
  // like the design delivering a beat twice.
  //
  // The handshake is captured AT the rising edge for the same reason: in_ready
  // read at the negative edge is not necessarily the value the design used.
  logic [N_IN-1:0] hs;
  always @(posedge clk) hs <= (rst_n ? (in_valid & in_ready) : '0);

  int  nxt [N_IN];
  int  sel_of [N_IN];
  bit  offer [N_IN];
  int  cov_beats = 0, cov_contend_phases = 0, cov_stall_phases = 0;
  bit  cov_all_outputs [N_OUT];
  bit  cov_lockin_probe = 0, cov_reset_mid = 0;

  task automatic present(input int k);
    in_data[k*DW +: DW] = mk(k, nxt[k]);
    in_sel [k*SW +: SW] = SW'(sel_of[k]);
    in_valid[k] = 1'b1;
    cov_all_outputs[sel_of[k]] = 1'b1;
  endtask

  // Clause H2 is an obligation on the SOURCE: an offer is never withdrawn and
  // neither its payload nor its selector changes once asserted. A new selector
  // therefore takes effect on the next beat an input presents, never on the
  // one in flight -- which is why present() is called only on acceptance.
  always @(negedge clk) begin
    if (!rst_n) begin
      in_valid = '0;
    end else begin
      for (int k = 0; k < N_IN; k++) begin
        if (hs[k]) begin nxt[k]++; cov_beats++; in_valid[k] = 1'b0; end
        if (!in_valid[k] && offer[k]) present(k);
      end
    end
  end

  task automatic clear_contenders();
    fair_on = 1'b0;
    for (int j = 0; j < N_OUT; j++) begin
      n_contend[j] = 0;
      for (int k = 0; k < N_IN; k++) begin contend[j][k] = 1'b0; since[j][k] = 0; end
    end
  endtask

  // Derives the contending set from what is actually being offered.
  task automatic arm_fairness();
    clear_contenders();
    for (int k = 0; k < N_IN; k++)
      if (offer[k]) begin contend[sel_of[k]][k] = 1'b1; n_contend[sel_of[k]]++; end
    fair_on = 1'b1;
  endtask

  task automatic drain();
    clear_contenders();
    for (int k = 0; k < N_IN; k++) offer[k] = 1'b0;
    for (int t = 0; t < 400; t++) begin
      @(posedge clk);
      if (in_valid == '0) break;
    end
    repeat (16) @(posedge clk);
  endtask

  initial begin
    for (int k = 0; k < N_IN; k++) begin nxt[k] = 0; sel_of[k] = 0; offer[k] = 1'b0; end
    for (int j = 0; j < N_OUT; j++) cov_all_outputs[j] = 1'b0;
    in_data = '0; in_sel = '0; out_ready = '1;
    clear_contenders();
    repeat (5) @(posedge clk);
    @(negedge clk) rst_n = 1'b1;
    @(posedge clk);
    checking = 1'b1;

    // -- 1. all four inputs contend for ONE output. Fairness lives here. ------
    for (int k = 0; k < N_IN; k++) begin sel_of[k] = 0; offer[k] = 1'b1; end
    arm_fairness(); cov_contend_phases++;
    repeat (60) @(posedge clk);
    drain();

    // -- 2. each input to its own output: everything moves in parallel -------
    for (int k = 0; k < N_IN; k++) begin sel_of[k] = k; offer[k] = 1'b1; end
    arm_fairness();
    begin int base_del; base_del = n_del;
      repeat (30) @(posedge clk);
      if (n_del - base_del < 50)
        fail("I1", $sformatf("with four inputs bound for four distinct ready outputs, only %0d beats were delivered in 30 cycles; the outputs are not independent",
                             n_del - base_del));
    end

    // -- 3. one output stalled: the other three must keep moving (I1, I2) ----
    out_ready = 4'b1110; cov_stall_phases++;
    begin int base_del; base_del = n_del;
      repeat (30) @(posedge clk);
      if (n_del - base_del < 40)
        fail("I2", $sformatf("with output 0 stalled, only %0d beats moved on the other three outputs in 30 cycles. An input whose output is blocked must not block the others.",
                             n_del - base_del));
    end
    out_ready = '1;
    repeat (20) @(posedge clk);
    drain();

    // -- 3b. EVERY output stalled at once. Nothing may be accepted that cannot
    //        eventually be delivered, and nothing may be delivered at all.
    for (int k = 0; k < N_IN; k++) begin sel_of[k] = k; offer[k] = 1'b1; end
    arm_fairness();
    repeat (6) @(posedge clk);
    out_ready = 4'b0000;
    begin int base_del; base_del = n_del;
      repeat (24) @(posedge clk);
      if (n_del != base_del)
        fail("H1", $sformatf("cycle %0d: %0d beat(s) were delivered while every output was stalled",
                             cyc, n_del - base_del));
    end
    out_ready = '1;
    repeat (24) @(posedge clk);
    clear_contenders();
    drain();

    // -- 4. three inputs contending for output 3, a HIGH selector ------------
    for (int k = 0; k < 3; k++) begin sel_of[k] = 3; offer[k] = 1'b1; end
    sel_of[3] = 2; offer[3] = 1'b1;
    arm_fairness(); cov_contend_phases++;
    repeat (60) @(posedge clk);
    drain();

    // -- 5. A3: change the contender set while an output is stalled ----------
    // Whether a crossbar that does not hold its decision actually re-aims
    // depends on WHICH input is already being offered and which one arrives.
    // Bringing a higher-numbered input in behind a lower-numbered one never
    // unseats it under a rotation that favours low indices, so a probe built
    // that way watches the right signals and sees nothing. Contenders are
    // therefore brought in from the HIGHEST index DOWN, on every output in
    // turn, with the output stalled throughout so no offer is allowed to move.
    cov_lockin_probe = 1'b1;
    for (int j = 0; j < N_OUT; j++) begin
      out_ready = ~(4'b0001 << j);
      for (int k = N_IN - 1; k >= 0; k--) begin
        sel_of[k] = j; offer[k] = 1'b1;
        repeat (6) @(posedge clk);
      end
      out_ready = '1;
      repeat (20) @(posedge clk);
      drain();
    end

    // -- 6. X3: an offered beat with a ready target must be accepted ---------
    begin int t; bit took; int base_nxt;
      base_nxt = nxt[3];
      sel_of[3] = 1; offer[3] = 1'b1;
      took = 1'b0;
      for (t = 0; t < LIVE; t++) begin
        @(posedge clk);
        if (nxt[3] != base_nxt) begin took = 1'b1; break; end
      end
      if (!took)
        fail("X3", $sformatf("an input offering to a continuously ready output was not accepted within %0d cycles", LIVE));
    end
    drain();

    // -- 7. reset mid-stream -------------------------------------------------
    checking = 1'b0; cov_reset_mid = 1'b1;
    @(negedge clk) rst_n = 1'b0;
    repeat (4) @(posedge clk);
    @(negedge clk) rst_n = 1'b1;
    for (int k = 0; k < N_IN; k++)
      for (int j = 0; j < N_OUT; j++) pair_q[k][j].delete();
    seen.delete(); clear_contenders();
    for (int k = 0; k < N_IN; k++) nxt[k] += 1000;
    @(posedge clk);
    checking = 1'b1;
    for (int k = 0; k < N_IN; k++) begin sel_of[k] = 0; offer[k] = 1'b1; end
    arm_fairness();
    repeat (40) @(posedge clk);
    drain();

    // -- everything accepted must have been delivered -------------------------
    for (int k = 0; k < N_IN; k++)
      for (int j = 0; j < N_OUT; j++)
        if (pair_q[k][j].size() != 0)
          fail("R4", $sformatf("%0d beat(s) accepted from input %0d bound for output %0d were never delivered",
                               pair_q[k][j].size(), k, j));

    // -- rule 4 floors, on STIMULUS only --------------------------------------
    if (cov_beats < 250)        fail("COVERAGE", $sformatf("only %0d beats offered", cov_beats));
    if (cov_contend_phases < 2) fail("COVERAGE", "fewer than two phases with several inputs contending for one output");
    if (cov_stall_phases < 1)   fail("COVERAGE", "no output was ever stalled");
    // TWO floors, because they are two different facts and the first cannot
    // support the second. STIMULUS: did the harness try. CONDITION: was the
    // clause exercised. They diverge exactly where the design controls
    // whether the state is reached, and A3 is such a clause.
    if (!cov_lockin_probe)      fail("COVERAGE", "the contender set was never CHANGED while an output was stalled -- the A3 probe was not driven");
    if (cov_a3_held == 0)       fail("COVERAGE", "A3's antecedent never held: out_valid_o was never high while out_ready_i was low, so A3 was never judged. A design that offers only into a ready sink satisfies A3 by never entering it -- see negctl/a3_offers_only_when_ready_dut.sv");
    if (!cov_reset_mid)         fail("COVERAGE", "reset was never asserted mid-stream");
    for (int j = 0; j < N_OUT; j++)
      if (!cov_all_outputs[j])  fail("COVERAGE", $sformatf("output %0d was never selected", j));
    // ---- ATTRIBUTION CASES: does the SELECTOR return the id it should? ------
    // gov_delivery is a pure function of pair_q, so each branch is a direct call
    // with the state constructed. The mutant set cannot reach these: a mutant
    // changes what the DESIGN does, and which NAME a path reports under is a
    // property of this file.
    //
    // ONE CASE PER RETURN, not per id. gov_delivery has two returns and they are
    // two ids, so here the counts coincide -- v_ca03's gov_r has three returns
    // and two of them are A5, where they do not. The unit that has to be covered
    // is the one that can change independently.
    begin
      automatic int n_attrib = 0, n_bad = 0;
      automatic logic [DW-1:0] probe = 32'hA5A5_0001;
      for (int a = 0; a < N_IN; a++)
        for (int b = 0; b < N_OUT; b++) pair_q[a][b].delete();

      // R6 -- nothing anywhere accepted this beat.
      n_attrib++;
      if (gov_delivery(0, 1, probe) != "R6") begin
        n_bad++; $display("ATTRIB FAIL gov_delivery: unaccepted beat returned %s, expected R6", gov_delivery(0,1,probe));
      end else $display("ATTRIB ok gov_delivery R6 -- a beat nothing ever accepted");

      // R1 -- accepted from input 0 bound for output 2, delivered on output 1.
      pair_q[0][2].push_back(probe);
      n_attrib++;
      if (gov_delivery(0, 1, probe) != "R1") begin
        n_bad++; $display("ATTRIB FAIL gov_delivery: misrouted beat returned %s, expected R1", gov_delivery(0,1,probe));
      end else $display("ATTRIB ok gov_delivery R1 -- accepted for another output");

      // and the OUTPUT it names, because the message carries it and a wrong one
      // sends the reader to the wrong channel. Not an id, still an attribution.
      n_attrib++;
      if (bound_output_for(0, 1, probe) != 2) begin
        n_bad++; $display("ATTRIB FAIL bound_output_for: returned %0d, expected 2", bound_output_for(0,1,probe));
      end else $display("ATTRIB ok bound_output_for -- names the output it was bound for");

      // the SAME output must not count: a beat outstanding for j is not misrouted
      // to j. This is the boundary of the `jo != j` guard, and without a case the
      // guard could be dropped and every branch above would still pass.
      for (int a = 0; a < N_IN; a++)
        for (int b = 0; b < N_OUT; b++) pair_q[a][b].delete();
      pair_q[0][1].push_back(probe);
      n_attrib++;
      if (gov_delivery(0, 1, probe) != "R6") begin
        n_bad++; $display("ATTRIB FAIL gov_delivery: same-output beat returned %s, expected R6", gov_delivery(0,1,probe));
      end else $display("ATTRIB ok gov_delivery R6 -- outstanding for THIS output is not a misroute");

      for (int a = 0; a < N_IN; a++)
        for (int b = 0; b < N_OUT; b++) pair_q[a][b].delete();
      $display("FIRED v_ca04.attrib_cases %0d", n_attrib);
      if (n_bad != 0)
        fail("ATTRIB", $sformatf("%0d attribution case(s) returned the wrong clause id", n_bad));
    end

    // ---- FIRED: did the artefacts that must fire, fire? ---------------------
    // Every counter here GATES A FLOOR. The floor already refuses on zero, so
    // these lines add one thing the floor cannot: they distinguish a floor that
    // ran and read zero from a floor that IS NOT IN THIS RUN AT ALL -- deleted,
    // renamed, or skipped. Absent is not zero (rule 20), and v_ca03's read
    // coverage floor sat behind a dangling `else` and was skipped on exactly the
    // runs that were otherwise clean. check_fired.py refuses on both, separately.
    $display("FIRED v_ca04.cov_a3_held %0d", cov_a3_held);
    $display("FIRED v_ca04.cov_beats %0d", cov_beats);
    $display("FIRED v_ca04.cov_contend_phases %0d", cov_contend_phases);
    $display("FIRED v_ca04.cov_lockin_probe %0d", cov_lockin_probe);
    $display("FIRED v_ca04.cov_reset_mid %0d", cov_reset_mid);
    $display("FIRED v_ca04.cov_stall_phases %0d", cov_stall_phases);

    if (errors == 0) $display("RESULT: PASS");
    else $display("RESULT: FAIL (%0d violation%s)", errors, (errors == 1) ? "" : "s");
    $display("  [coverage] offered=%0d accepted=%0d delivered=%0d", cov_beats, n_acc, n_del);
    $finish;
  end

  initial begin
    #2_000_000;
    $display("RESULT: FAIL (watchdog: no forward progress; %0d violation(s) so far)", errors);
    $finish;
  end
endmodule
