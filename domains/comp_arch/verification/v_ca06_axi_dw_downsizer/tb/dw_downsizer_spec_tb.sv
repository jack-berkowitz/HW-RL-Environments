// =============================================================================
// v_ca06 REFERENCE TESTBENCH -- scoring support, never shipped.
//
// Developed against SIX legal implementations, not one: the anchor, the
// independent dut2, and five conformant perturbations. That ordering is
// deliberate -- the re-grade showed the strongest submissions lost their score
// to REJECTING A LEGAL VARIANT, not to missing a defect.
//
// Consequences of that, all load-bearing:
//   * no ready is ever required to be high. Every wait has a generous budget
//     and fails only on timeout, naming the channel.
//   * every payload is sampled ONLY when its own valid is high (clause X2).
//   * downstream beats are not assumed contiguous (L5) and no latency is
//     assumed anywhere (L1).
//   * transactions are driven ONE AT A TIME for the exact checks, because A4
//     makes MAX_READS an upper bound and two of the six accept only one. A
//     separate phase OFFERS concurrency and checks it only if it is taken.
// =============================================================================
// A WAIT COMMITS ON THE HANDSHAKE, NOT ON ONE SIDE OF IT.
// These loops broke on the READY/GRANT alone. That is equivalent today -- the
// valid is asserted before the wait and held throughout it -- so the defect was
// unreachable and no run could distinguish the two forms.
//
// It becomes reachable the moment anything gates the valid: the design sees no
// offer, the testbench sees a ready, and a beat that never moved is recorded as
// moved. Measured on v_ca05, where the reference model then reported "full=0
// with 8 entries" and the failure was attributed to the design.
//
// 24 sites across six tasks had this shape. Corrected everywhere rather than
// where a perturbation happened to reach, because "correct only while nothing
// gates the valid" is a property of the corpus and not of the code.
module dw_downsizer_tb;

  // VCD on demand, for the rule-34 stimulus-variation check. Guarded by a
  // plusarg so a normal scoring run is byte-for-byte unaffected.
  initial if ($test$plusargs("vcd")) begin
    $dumpfile("dump.vcd");
    $dumpvars(0, dw_downsizer_tb);
  end
  localparam int ADDR_W=32, ID_W=4, SW=64, MW=16, MAXR=4;
  localparam int SBY = SW/8, MBY = MW/8, MSIZE = 1;

  logic clk=0, rst_n=0; always #5 clk=~clk;

  logic [ID_W-1:0]  s_awid=0, s_arid=0, s_bid, s_rid;
  logic [ADDR_W-1:0] s_awaddr=0, s_araddr=0;
  logic [7:0]       s_awlen=0, s_arlen=0;
  logic [2:0]       s_awsize=0, s_arsize=0;
  logic [1:0]       s_awburst=1, s_arburst=1, s_bresp, s_rresp;
  logic             s_awvalid=0, s_awready, s_wvalid=0, s_wready, s_wlast=0;
  logic             s_bvalid, s_bready, s_arvalid=0, s_arready, s_rlast, s_rvalid, s_rready;
  logic [SW-1:0]    s_wdata=0, s_rdata;
  logic [SBY-1:0]   s_wstrb=0;

  logic [ID_W-1:0]  m_awid, m_arid, m_bid=0, m_rid=0;
  logic [ADDR_W-1:0] m_awaddr, m_araddr;
  logic [7:0]       m_awlen, m_arlen;
  logic [2:0]       m_awsize, m_arsize;
  logic [1:0]       m_awburst, m_arburst, m_bresp=0, m_rresp=0;
  logic             m_awvalid, m_awready, m_wvalid, m_wready, m_wlast;
  logic             m_bvalid=0, m_bready, m_arvalid, m_arready, m_rlast=0, m_rvalid=0, m_rready;
  logic [MW-1:0]    m_wdata, m_rdata=0;
  logic [MBY-1:0]   m_wstrb;

  dw_downsizer dut (.clk_i(clk), .rst_ni(rst_n), .*);

  int unsigned n_fail = 0;
  task automatic fail(input string cl, input string msg);
    n_fail++;
    if (n_fail <= 40) $display("FAIL [%s] %s (t=%0t)", cl, msg, $time);
  endtask

  // ---- the contract, as functions -----------------------------------------
  function automatic int unsigned bby(input int unsigned sz); return 1 << sz; endfunction
  function automatic logic [ADDR_W-1:0] algn(input logic [ADDR_W-1:0] a, input int unsigned sz);
    return a & ~((32'd1 << sz) - 32'd1);
  endfunction
  function automatic bit refused(input logic [1:0] b, input int unsigned l);
    return (b == 2'b10) || ((b == 2'b00) && (l != 0));          // C1, C2, C3
  endfunction
  function automatic int unsigned dsz(input int unsigned sz);    // B1
    return (sz < MSIZE) ? sz : MSIZE;
  endfunction
  function automatic int unsigned totb(input logic [ADDR_W-1:0] a, input int unsigned l,
                                       input int unsigned sz);
    return (l + 1) * bby(sz) - int'(a - algn(a, sz));
  endfunction
  // B2: a count of aligned downstream BLOCKS SPANNED. Dividing the byte count
  // gives -1 when the range does not fill one block (len=0 size=1 at an odd
  // address covers a single byte, and the answer is one beat, not minus one).
  function automatic int unsigned dslen(input logic [ADDR_W-1:0] a, input int unsigned l,
                                        input int unsigned sz);
    automatic logic [ADDR_W-1:0] lastb = a + ADDR_W'(totb(a, l, sz)) - 1;
    return (algn(lastb, dsz(sz)) - algn(a, dsz(sz))) / bby(dsz(sz));
  endfunction
  // first byte address of beat j of a burst, and one past its last byte
  function automatic logic [ADDR_W-1:0] beat_lo(input logic [ADDR_W-1:0] a,
                                                input int unsigned sz, input int unsigned j);
    return (j == 0) ? a : (algn(a, sz) + ADDR_W'(j * bby(sz)));
  endfunction
  function automatic logic [ADDR_W-1:0] beat_hi(input logic [ADDR_W-1:0] a,
                                                input int unsigned sz, input int unsigned j);
    return algn(a, sz) + ADDR_W'((j + 1) * bby(sz));
  endfunction
  // the byte the memory holds at an address -- address-derived, so the expected
  // upstream data follows from the contract rather than from the design
  function automatic logic [7:0] memb(input logic [ADDR_W-1:0] a);
    return a[7:0] ^ 8'hA5;
  endfunction

  // ---- downstream slave: reads --------------------------------------------
  logic [ADDR_W-1:0] rq_addr [$]; int rq_len [$], rq_size [$]; logic [ID_W-1:0] rq_id [$];
  int  rbeat = 0;
  int  n_ds_ar = 0, n_ds_aw = 0;
  always @(posedge clk) if (rst_n && m_arvalid && m_arready) begin
    rq_addr.push_back(m_araddr); rq_len.push_back(int'(m_arlen));
    rq_size.push_back(int'(m_arsize)); rq_id.push_back(m_arid); n_ds_ar++;
  end
  // REGISTERED, not combinational. An always_comb that reads a queue another
  // process pushes is not guaranteed to re-evaluate on the push: the first
  // response went out and every later one waited for some unrelated signal to
  // move, so each transaction timed out at exactly the wait budget and its
  // beats surfaced during the NEXT one. Driving the response from registers
  // removes the question.
  // Downstream errors are STEERED BY ADDRESS so the checker can predict them
  // without sharing state with the responder: bit 12 of a transaction's address
  // asks for an error, and bits 11:8 select which downstream beat carries it.
  // Bit 13 selects DECERR over SLVERR.
  function automatic bit want_err(input logic [ADDR_W-1:0] a); return a[20]; endfunction
  function automatic int  err_beat_of(input logic [ADDR_W-1:0] a); return int'(a[19:16]); endfunction
  function automatic logic [1:0] err_code_of(input logic [ADDR_W-1:0] a);
    return a[21] ? 2'b11 : 2'b10;
  endfunction

  logic            m_rvalid_q = 0, m_rlast_q = 0;
  logic [MW-1:0]   m_rdata_q = '0;
  logic [ID_W-1:0] m_rid_q = '0;
  assign m_rvalid = m_rvalid_q;
  assign m_rlast  = m_rlast_q;
  assign m_rid    = m_rid_q;
  assign m_rdata  = m_rdata_q;
  logic [1:0] m_rresp_q = 2'b00;
  assign m_rresp  = m_rresp_q;

  function automatic logic [MW-1:0] ds_beat_data(input logic [ADDR_W-1:0] a,
                                                 input int unsigned sz, input int unsigned j);
    ds_beat_data = '0;
    for (int b = 0; b < MBY; b++) begin
      automatic logic [ADDR_W-1:0] x = algn(a, sz) + ADDR_W'(j*bby(sz) + b);
      if (x >= beat_lo(a, sz, j) && x < beat_hi(a, sz, j))
        ds_beat_data[8*(x % MBY) +: 8] = memb(x);
    end
  endfunction

  always @(posedge clk) begin
    if (!rst_n) begin
      m_rvalid_q <= 1'b0; m_rlast_q <= 1'b0; rbeat <= 0;
    end else begin
      if (m_rvalid_q && m_rready) begin
        if (rbeat == rq_len[0]) begin
          void'(rq_addr.pop_front()); void'(rq_len.pop_front());
          void'(rq_size.pop_front()); void'(rq_id.pop_front());
          rbeat <= 0; m_rvalid_q <= 1'b0;
        end else begin
          rbeat <= rbeat + 1;
          m_rvalid_q <= 1'b1;
          m_rdata_q  <= ds_beat_data(rq_addr[0], rq_size[0], rbeat + 1);
          m_rlast_q  <= ((rbeat + 1) == rq_len[0]);
          m_rid_q    <= rq_id[0];
          m_rresp_q  <= (want_err(rq_addr[0]) && ((rbeat + 1) == err_beat_of(rq_addr[0])))
                        ? err_code_of(rq_addr[0]) : 2'b00;
        end
      end else if (!m_rvalid_q && rq_addr.size() > 0) begin
        m_rvalid_q <= 1'b1;
        m_rdata_q  <= ds_beat_data(rq_addr[0], rq_size[0], rbeat);
        m_rlast_q  <= (rbeat == rq_len[0]);
        m_rid_q    <= rq_id[0];
        m_rresp_q  <= (want_err(rq_addr[0]) && (rbeat == err_beat_of(rq_addr[0])))
                      ? err_code_of(rq_addr[0]) : 2'b00;
      end
    end
  end

  // ---- downstream slave: writes, and the W-beat log -----------------------
  logic [ID_W-1:0] wq_id [$]; logic [ADDR_W-1:0] wq_addr [$]; int n_pend_b = 0;
  logic [MW-1:0]   wl_data [$]; logic [MBY-1:0] wl_strb [$]; logic wl_last [$];
  // ONE ordered block: a counter written here and read by a separate block is a
  // race, and for a len=0 burst the AW and the final W beat land in one cycle.
  always @(posedge clk) if (rst_n) begin
    if (m_awvalid && m_awready) begin wq_id.push_back(m_awid);
                                      wq_addr.push_back(m_awaddr); n_ds_aw++; end
    if (m_wvalid && m_wready) begin
      wl_data.push_back(m_wdata); wl_strb.push_back(m_wstrb); wl_last.push_back(m_wlast);
      if (m_wlast) n_pend_b++;
    end
    if (m_bvalid && m_bready) begin
      m_bvalid <= 1'b0;
      if (wq_id.size() > 0) begin void'(wq_id.pop_front()); void'(wq_addr.pop_front()); end
    end else if (!m_bvalid && n_pend_b > 0) begin
      m_bvalid <= 1'b1;
      m_bresp  <= (wq_addr.size() > 0 && want_err(wq_addr[0])) ? err_code_of(wq_addr[0]) : 2'b00;
      m_bid <= (wq_id.size() > 0) ? wq_id[0] : '0;
      n_pend_b--;
    end
  end

  // ---- coverage, counted on STIMULUS only (rule 4) ------------------------
  int cov_reads=0, cov_writes=0, cov_refused=0, cov_unaligned=0, cov_narrow=0;
  int cov_rd_err=0, cov_wr_err=0, cov_decerr=0, cov_err_last=0, cov_a4_offered=0;
  int cov_size0=0, cov_partial_strb=0, cov_zero_strb_beat=0, cov_fixed1=0;
  int cov_long=0, cov_conc_offered=0, cov_conc_taken=0, cov_rbeats=0, cov_wbeats=0;
  string phase = "init";

  // ---- upstream master: one read, fully checked ---------------------------
  task automatic do_read(input logic [ID_W-1:0] id, input logic [ADDR_W-1:0] a,
                         input int unsigned len, input int unsigned sz,
                         input logic [1:0] burst);
    int t, got, exp_beats; bit is_ref; int ar0;
    is_ref = refused(burst, len); exp_beats = len + 1;
    // COUNTER READS ARE ORDERED WITH A NEGEDGE, and this is a defect that
    // BACKPRESSURE EXPOSED rather than one it created. `n_ds_ar` / `n_ds_aw` are
    // incremented in a separate `always @(posedge clk)`; a task that resumes at
    // the same posedge and reads them races that block. With every ready held at
    // 1 the downstream address and the upstream response never landed in the
    // same cycle, so the race was unreachable. Under backpressure they align:
    //     TRACE t=3755 AWdown addr=00003000 len=0
    //     TRACE t=3755 Bup    id=0 resp=0
    //     DIAG  t=3755 aw0=0 n_ds_aw=0   -> "issued 0 downstream addresses"
    //     DIAG  t=3805 aw0=0 n_ds_aw=2   -> "issued 2", the same write off by one
    // Reading at the NEGEDGE puts the read unambiguously after every posedge
    // update. The testbench's own note at the W-beat log says the same thing
    // about a different counter; this is the second instance.
    @(negedge clk);
    ar0 = n_ds_ar;
    cov_reads++; if (is_ref) cov_refused++;
    if (a != algn(a, sz)) cov_unaligned++;
    if (sz < MSIZE) cov_narrow++;
    if (sz == 0) cov_size0++;
    if (burst == 2'b00 && len == 0) cov_fixed1++;
    if (len >= 7) cov_long++;
    if (want_err(a)) begin
      cov_rd_err++;
      if (err_code_of(a) == 2'b11) cov_decerr++;
      if (err_beat_of(a) >= dslen(a, len, sz)) cov_err_last++;
    end
    cov_rbeats += exp_beats;

    @(negedge clk); s_arid=id; s_araddr=a; s_arlen=8'(len); s_arsize=3'(sz);
                    s_arburst=burst; s_arvalid=1;
    for (t=0; t<4000; t++) begin @(posedge clk); if (s_arvalid && s_arready) break; end
    @(negedge clk) s_arvalid=0;
    if (t >= 4000) begin
      fail("A1", $sformatf("%s: read address never accepted in 4000 cycles", phase));
      return;
    end
    got = 0;
    for (t=0; t<20000; t++) begin
      @(posedge clk);
      if (s_rvalid && s_rready) begin
        automatic int j = got;
        automatic logic [SW-1:0] want = '0;
        got++;
        if (s_rid !== id)
          fail("D3", $sformatf("%s: R beat %0d carries id %0d, expected %0d", phase, j, s_rid, id));
        if (is_ref) begin
          if (s_rresp !== 2'b10)                                        // C4.4
            fail("C4", $sformatf("%s: refused read, R beat %0d carries resp %0b, expected SLVERR on EVERY beat",
                                 phase, j, s_rresp));
        end else begin
          for (int b = 0; b < SBY; b++) begin
            automatic logic [ADDR_W-1:0] ba = algn(a, sz) + ADDR_W'(j*bby(sz) + b);
            if (ba >= beat_lo(a, sz, j) && ba < beat_hi(a, sz, j))
              want[8*(ba % SBY) +: 8] = memb(ba);
          end
          begin
            // D6 is STICKY: this upstream beat carries the error if the erroring
            // downstream beat lies in its own group or any earlier one. D7: the
            // code is preserved, not normalised.
            // D6 is OWNERSHIP, not persistence. This upstream beat must carry
            // the error if the erroring downstream beat lies in ITS OWN group.
            // Whether the error PERSISTS onto later beats is L7 -- declared-open
            // latitude -- and beats after the erroring one are NOT CHECKED here,
            // in either direction.
            //
            // This clause used to require persistence, and the reference passed
            // it for as long as it existed. The reference is sticky only while
            // its pipeline stays full: the accumulated response register is not
            // cleared while beats keep arriving and IS cleared when it bubbles.
            // Three idle cycles between downstream R beats and it stops. The
            // task never stalled that path, so a property of pipeline occupancy
            // was recorded as a property of the contract, and a submission
            // asserting it would have scored well while being wrong.
            //   0/1/2 idle cycles: persists.  3/4/8: does not.  dut2: always.
            // Narrowing costs no detection: 12/12 mutants still die, dw_m6,
            // dw_m11 and dw_m12 included.
            automatic logic [1:0] want_r = 2'b00;
            automatic bit err_own = want_err(a)
                && (beat_lo(a, dsz(sz), err_beat_of(a)) >= beat_lo(a, sz, j))
                && (beat_lo(a, dsz(sz), err_beat_of(a)) <  beat_hi(a, sz, j));
            automatic bit err_past = want_err(a)
                && (beat_lo(a, dsz(sz), err_beat_of(a)) <  beat_lo(a, sz, j));
            if (err_own)  want_r = err_code_of(a);
            if (err_past) want_r = s_rresp;   // L7: unchecked, either way
            // A ternary between two string LITERALS pads the shorter with NULs to
            // the longer's width. The empty arm here printed FIFTY NULs into the
            // middle of this message, and this message is a rule-16 WITNESS --
            // the string the mutant record is checked against. Plain if/else.
            // THREE outcomes, not two, because D6 and D7 are different clauses.
            // D6 is precedence -- an error is due and must appear. D7 is code
            // preservation -- the error that appears must be the one the slave
            // returned. Collapsing them reported a code swap as a precedence
            // failure, which names the wrong clause for the defect and would
            // have credited a submission with checking something it did not.
            if (s_rresp !== want_r) begin
              if (want_r == 2'b00)
                fail("D5", $sformatf("%s: R beat %0d carries resp %0b, expected %0b",
                                     phase, j, s_rresp, want_r));
              else if (s_rresp == 2'b00)
                fail("D6", $sformatf("%s: R beat %0d carries resp %0b, expected %0b -- an error is STICKY from the beat it occurs on",
                                     phase, j, s_rresp, want_r));
              else
                fail("D7", $sformatf("%s: R beat %0d carries resp %0b where the slave returned %0b -- an error, of the WRONG KIND; the code is preserved, not normalised",
                                     phase, j, s_rresp, want_r));
            end
          end
          if ((s_rdata & lane_mask(a, sz, j)) !== (want & lane_mask(a, sz, j)))
            fail("D1", $sformatf("%s: R beat %0d data %016x, expected %016x on the lanes it covers",
                                 phase, j, s_rdata & lane_mask(a,sz,j), want & lane_mask(a,sz,j)));
        end
        if (s_rlast !== (got == exp_beats))                             // D4
          fail("D4", $sformatf("%s: rlast is %0b on beat %0d of a %0d-beat response",
                               phase, s_rlast, j, exp_beats));
        if (s_rlast) break;
      end
    end
    if (got != exp_beats)
      fail("A3", $sformatf("%s: read produced %0d upstream beats, expected exactly %0d",
                           phase, got, exp_beats));
    @(negedge clk);                 // order this read after the posedge updates
    if (is_ref && (n_ds_ar != ar0))                                     // C4.2
      fail("C4", $sformatf("%s: a refused read issued %0d downstream address(es); it must issue none",
                           phase, n_ds_ar - ar0));
    if (!is_ref && (n_ds_ar != ar0 + 1))                                // A2
      fail("A2", $sformatf("%s: read issued %0d downstream addresses, expected exactly 1",
                           phase, n_ds_ar - ar0));
  endtask

  function automatic logic [SW-1:0] lane_mask(input logic [ADDR_W-1:0] a,
                                              input int unsigned sz, input int unsigned j);
    lane_mask = '0;
    for (int b = 0; b < SBY; b++) begin
      automatic logic [ADDR_W-1:0] ba = algn(a, sz) + ADDR_W'(j*bby(sz) + b);
      if (ba >= beat_lo(a, sz, j) && ba < beat_hi(a, sz, j))
        lane_mask[8*(ba % SBY) +: 8] = 8'hFF;
    end
  endfunction

  // ---- upstream master: one write, fully checked --------------------------
  task automatic do_write(input logic [ID_W-1:0] id, input logic [ADDR_W-1:0] a,
                          input int unsigned len, input int unsigned sz,
                          input logic [1:0] burst, input bit sparse);
    int t, aw0, exp_dsbeats, k, j; bit is_ref;
    logic [SBY-1:0] strb; logic [ID_W-1:0] b_id; logic [1:0] b_resp;
    is_ref = refused(burst, len);
    @(negedge clk);                 // see the note in do_read
    aw0 = n_ds_aw; wl_data.delete(); wl_strb.delete(); wl_last.delete();
    cov_writes++; if (is_ref) cov_refused++;
    if (a != algn(a, sz)) cov_unaligned++;
    if (sz < MSIZE) cov_narrow++;
    if (burst == 2'b00 && len == 0) cov_fixed1++;
    if (sparse) cov_partial_strb++;
    if (want_err(a)) cov_wr_err++;
    cov_wbeats += len + 1;

    @(negedge clk); s_awid=id; s_awaddr=a; s_awlen=8'(len); s_awsize=3'(sz);
                    s_awburst=burst; s_awvalid=1;
    for (t=0; t<4000; t++) begin @(posedge clk); if (s_awvalid && s_awready) break; end
    @(negedge clk) s_awvalid=0;
    if (t >= 4000) begin
      fail("A1", $sformatf("%s: write address never accepted in 4000 cycles", phase));
      return;
    end
    // drive len+1 upstream beats with LANE-CORRECT strobes (clause X3)
    for (k = 0; k <= int'(len); k++) begin
      @(negedge clk);
      s_wdata = '0; strb = '0;
      for (int b = 0; b < SBY; b++) begin
        automatic logic [ADDR_W-1:0] ba = algn(a, sz) + ADDR_W'(k*bby(sz) + b);
        if (ba >= beat_lo(a, sz, k) && ba < beat_hi(a, sz, k)) begin
          s_wdata[8*(ba % SBY) +: 8] = memb(ba);
          strb[ba % SBY] = sparse ? ((ba % 4) == 0) : 1'b1;
        end
      end
      s_wstrb = strb; s_wlast = (k == int'(len)); s_wvalid = 1;
      for (t=0; t<8000; t++) begin @(posedge clk); if (s_wvalid && s_wready) break; end
      if (t >= 8000) begin
        fail("A1", $sformatf("%s: write beat %0d never accepted in 8000 cycles", phase, k));
        @(negedge clk) s_wvalid=0; s_wlast=0; return;
      end
    end
    @(negedge clk) s_wvalid=0; s_wlast=0;
    // the B
    for (t=0; t<20000; t++) begin @(posedge clk); if (s_bvalid && s_bready) break; end
    if (t >= 20000) begin
      fail("A3", $sformatf("%s: write never produced a B response", phase)); return;
    end
    // `s_bid` and `s_bresp` are only valid during the handshake cycle, so they
    // are latched HERE and the counter reads move to the negedge below.
    b_id = s_bid; b_resp = s_bresp;
    if (b_id !== id)
      fail("E5", $sformatf("%s: B carries id %0d, expected %0d", phase, b_id, id));
    @(negedge clk);
    if (is_ref) begin
      if (b_resp !== 2'b10)
        fail("C4", $sformatf("%s: refused write answered %0b, expected SLVERR", phase, b_resp));
      if (n_ds_aw != aw0)
        fail("C4", $sformatf("%s: a refused write issued %0d downstream address(es); it must issue none",
                             phase, n_ds_aw - aw0));
      if (wl_data.size() != 0)
        fail("C4", $sformatf("%s: a refused write forwarded %0d downstream W beat(s); it must forward none",
                             phase, wl_data.size()));
      return;
    end
    begin
      automatic logic [1:0] want_b = want_err(a) ? err_code_of(a) : 2'b00;
      if (b_resp !== want_b)
        fail("E6", $sformatf("%s: write answered %0b, expected %0b -- the downstream code passes through",
                             phase, b_resp, want_b));
    end
    if (n_ds_aw != aw0 + 1)
      fail("A2", $sformatf("%s: write issued %0d downstream addresses, expected exactly 1",
                           phase, n_ds_aw - aw0));
    // E2/E3/E4: exactly the beats B2 computes, each carrying its own lanes
    exp_dsbeats = dslen(a, len, sz) + 1;
    if (wl_data.size() != exp_dsbeats) begin
      fail("E3", $sformatf("%s: downstream burst has %0d beats, expected exactly %0d -- an unstrobed beat is still a beat",
                           phase, wl_data.size(), exp_dsbeats));
    end else begin
      for (j = 0; j < exp_dsbeats; j++) begin
        automatic logic [MW-1:0]  wd = '0; automatic logic [MBY-1:0] ws = '0;
        automatic logic [MBY-1:0] mask = '0;
        automatic int unsigned dz = dsz(sz);
        for (int b = 0; b < MBY; b++) begin
          automatic logic [ADDR_W-1:0] ba = algn(a, dz) + ADDR_W'(j*bby(dz) + b);
          if (ba >= beat_lo(a, dz, j) && ba < beat_hi(a, dz, j)
              && ba >= a && ba < a + ADDR_W'(totb(a, len, sz))) begin
            // lane = address mod bus bytes, as above
            wd[8*(ba % MBY) +: 8] = memb(ba); mask[ba % MBY] = 1'b1;
            ws[ba % MBY] = sparse ? ((ba % 4) == 0) : 1'b1;
          end
        end
        if (wl_strb[j] !== ws)
          fail("E2", $sformatf("%s: downstream beat %0d strb %0b, expected %0b", phase, j, wl_strb[j], ws));
        for (int b = 0; b < MBY; b++)
          if (ws[b] && (wl_data[j][8*b +: 8] !== wd[8*b +: 8]))
            fail("E1", $sformatf("%s: downstream beat %0d lane %0d is %02x, expected %02x",
                                 phase, j, b, wl_data[j][8*b +: 8], wd[8*b +: 8]));
        if (wl_last[j] !== (j == exp_dsbeats-1))
          fail("E4", $sformatf("%s: downstream wlast is %0b on beat %0d of %0d",
                               phase, wl_last[j], j, exp_dsbeats));
        if (ws == '0) cov_zero_strb_beat++;
      end
    end
  endtask

  // ---- the downstream address transform, checked as issued ---------------
  // Latched at the handshake and compared against B1..B4 -- not against the
  // golden's choices, against the formulas.
  logic [ADDR_W-1:0] chk_a; int chk_len, chk_sz; bit chk_arm=0;
  always @(posedge clk) if (rst_n && chk_arm && m_arvalid && m_arready) begin
    if (m_arsize !== 3'(dsz(chk_sz)))
      fail("B1", $sformatf("%s: downstream arsize %0d, expected min(size,%0d)=%0d",
                           phase, m_arsize, MSIZE, dsz(chk_sz)));
    if (m_arlen !== 8'(dslen(chk_a, chk_len, chk_sz)))
      fail("B2", $sformatf("%s: downstream arlen %0d, expected %0d (bytes covered, not beat count)",
                           phase, m_arlen, dslen(chk_a, chk_len, chk_sz)));
    if (m_araddr !== chk_a)
      fail("B3", $sformatf("%s: downstream araddr %08x, expected %08x unchanged", phase, m_araddr, chk_a));
    if ((dslen(chk_a, chk_len, chk_sz) > 0) && (m_arburst !== 2'b01))
      fail("B4", $sformatf("%s: downstream arburst %0b on a %0d-beat burst, expected INCR",
                           phase, m_arburst, dslen(chk_a, chk_len, chk_sz)+1));
  end
  always @(posedge clk) if (rst_n && chk_arm && m_awvalid && m_awready) begin
    if (m_awsize !== 3'(dsz(chk_sz)))
      fail("B1", $sformatf("%s: downstream awsize %0d, expected %0d", phase, m_awsize, dsz(chk_sz)));
    if (m_awlen !== 8'(dslen(chk_a, chk_len, chk_sz)))
      fail("B2", $sformatf("%s: downstream awlen %0d, expected %0d", phase, m_awlen,
                           dslen(chk_a, chk_len, chk_sz)));
    if (m_awaddr !== chk_a)
      fail("B3", $sformatf("%s: downstream awaddr %08x, expected %08x", phase, m_awaddr, chk_a));
    if ((dslen(chk_a, chk_len, chk_sz) > 0) && (m_awburst !== 2'b01))
      fail("B4", $sformatf("%s: downstream awburst %0b on a %0d-beat burst, expected INCR",
                           phase, m_awburst, dslen(chk_a, chk_len, chk_sz)+1));
  end
  task automatic arm(input logic [ADDR_W-1:0] a, input int unsigned l, input int unsigned sz);
    chk_a = a; chk_len = l; chk_sz = sz; chk_arm = 1'b1;
  endtask

  // ---- A5: BACKPRESSURE, and the antecedent it creates --------------------
  // Held at 1, these five readies make A5's antecedent -- `valid && !ready` --
  // unreachable on every channel, so a design that withdraws an offer before its
  // ready is seen is undetectable and A5 is a clause with no instrument.
  //
  // FREE-RUNNING, AND NOT ARMED BY `valid`. An arm that reads a channel's valid
  // and drives its ready in the same cycle CLOSES A COMBINATIONAL LOOP through
  // the design -- ready -> design -> valid -> arm -> ready. Verilator names it:
  //
  //     %Warning-UNOPTFLAT: Circular combinational logic:
  //       'dw_downsizer_tb.m_arready'  (also m_awready, m_wready, s_bready)
  //
  // and the harness builds with -Wno-fatal, which is right for vendored RTL and
  // is what carried this past unread. It is not a cosmetic warning. The same
  // armed stall on v_ca03 produced 26 FAILURES ACROSS SIX CLAUSE IDS -- A1, A3,
  // COVERAGE, D4, E1, FLOOR -- none of them a design defect, and it produced
  // them identically no matter which single ready was made reactive, which is
  // the signature of a settle order rather than a channel. Here it converged and
  // gave the right answer. Same instrument, two tasks, one right answer and one
  // wrong one, and NOTHING IN EITHER RUN SAID WHICH.
  //
  // Decoupling costs nothing that matters. The v_nw02 objection was to a
  // REGISTERED arm -- the stall lands a cycle after valid rose, so a valid that
  // is high for one cycle has already been accepted. That objection does not
  // reach a stall that is simply low some of the time regardless of valid: a
  // one-cycle offer meets a stalled ready at the stall's duty rate. The
  // per-channel antecedent counts printed at the end are the evidence, and they
  // are reported for exactly that reason.
  //
  // Aperiodic on purpose. A fixed duty cycle can resonate with a design's own
  // period and stall only in the phases where nothing is ever offered; an LFSR
  // cannot. Different bit pairs per channel keep the five decorrelated, so the
  // design is never fully blocked and never fully free.
  logic [15:0] bp_lfsr = 16'hACE1;
  always @(posedge clk) bp_lfsr <= !rst_n ? 16'hACE1
      : {bp_lfsr[14:0], bp_lfsr[15]^bp_lfsr[13]^bp_lfsr[12]^bp_lfsr[10]};
  wire stall_sb  = bp_lfsr[0] & bp_lfsr[5];
  wire stall_sr  = bp_lfsr[1] & bp_lfsr[6];
  wire stall_maw = bp_lfsr[2] & bp_lfsr[7];
  wire stall_mw  = bp_lfsr[3] & bp_lfsr[8];
  wire stall_mar = bp_lfsr[4] & bp_lfsr[9];
  assign s_bready  = !stall_sb;
  assign s_rready  = !stall_sr;
  assign m_awready = !stall_maw;
  assign m_wready  = !stall_mw;
  assign m_arready = !stall_mar;
  // The STIMULUS half, and it is harness-determined by construction: how many
  // cycles this testbench held a ready low. It does not read a design output, so
  // it cannot reject correct hardware -- which is the whole reason the ANTECEDENT
  // counts below are reported and this one is gated.
  int cov_bp_driven = 0;
  always @(posedge clk) if (rst_n && (stall_sb|stall_sr|stall_maw|stall_mw|stall_mar))
    cov_bp_driven <= cov_bp_driven + 1;

  // ---- A5's CHECKER -------------------------------------------------------
  int cov_a5 [5];
  logic pv [5];
  logic [63:0] pp [5];
  function automatic logic [63:0] pay(input int c);
    case (c)
      0: return {60'b0, s_bid};
      1: return {s_rdata[31:0], 27'b0, s_rid, s_rlast};
      2: return {m_awaddr[31:0], m_awlen, m_awsize, m_awburst, 19'b0};
      3: return {m_wdata[15:0], m_wstrb[1:0], m_wlast, 45'b0};
      default: return {m_araddr[31:0], m_arlen, m_arsize, m_arburst, 19'b0};
    endcase
  endfunction
  // pv MUST clear on reset. F1 says the unit presents no valid while rst_ni is
  // low, so an offer held across a reset is withdrawn LEGITIMATELY -- and a
  // checker that only skips WHILE reset is low carries its stale held-offer into
  // the first cycle after release. That fired on the GOLDEN before it was fixed.
  always @(posedge clk) if (!rst_n) begin
    for (int c = 0; c < 5; c++) pv[c] <= 1'b0;
  end else begin
    automatic logic v [5]; automatic logic r [5];
    v[0]=s_bvalid;  r[0]=s_bready;   v[1]=s_rvalid;  r[1]=s_rready;
    v[2]=m_awvalid; r[2]=m_awready;  v[3]=m_wvalid;  r[3]=m_wready;
    v[4]=m_arvalid; r[4]=m_arready;
    for (int c = 0; c < 5; c++) begin
      if (pv[c]) begin
        if (!v[c])
          fail("A5", $sformatf("channel %0d: valid was withdrawn without a handshake (t=%0t)", c, $time));
        else if (pay(c) !== pp[c])
          fail("A5", $sformatf("channel %0d: the payload changed while the offer was held (t=%0t)", c, $time));
      end
      if (v[c] && !r[c]) cov_a5[c]++;
      pv[c] <= v[c] && !r[c];
      pp[c] <= pay(c);
    end
  end

  // ---- A4: at most MAX_READS reads outstanding ---------------------------
  // A4 is an UPPER bound whose permissive half says a further address "need not
  // be accepted until one retires", so accepting FEWER conforms -- dut2 accepts
  // one and passes. The only violation is accepting MORE, so this counts and
  // bounds rather than requiring.
  //
  // RETIREMENT IS COUNTED FROM WHAT THE TESTBENCH ASKED FOR, not from the
  // design's s_rlast. Retiring on s_rlast gave this counter the SAME INPUT as
  // dw_m10's defect, which withholds exactly that signal: the counter could
  // never decrement, so A4 fired once per cycle for the rest of the run --
  // 1,024,737 failures where the honest count is zero. A counter whose exit
  // condition is the thing under test has no exit, and its "coverage" of that
  // defect is D4's detection wearing A4's label.
  //
  // The expected beat count is pushed at AR acceptance, when the testbench is
  // the one driving s_arlen. Beats are attributed by s_rid, which the design
  // drives -- a residual coupling, stated rather than hidden. It is far weaker
  // than the one it replaces: no mutant in this set perturbs rid, and D3
  // independently checks that every beat carries an id of an outstanding read,
  // so a design corrupting rid fails D3 whatever A4 does.
  int a4_live = 0, a4_peak = 0;
  int a4_exp [16][$];                    // expected beats per id, in AR order
  int a4_got [16];
  bit a4_over = 0;                       // edge-triggered: see below
  always @(posedge clk) if (rst_n) begin
    automatic int ret = 0;
    automatic int nxt;
    if (s_rvalid && s_rready) begin
      a4_got[s_rid] = a4_got[s_rid] + 1;
      if (a4_exp[s_rid].size() > 0 && a4_got[s_rid] >= a4_exp[s_rid][0]) begin
        a4_got[s_rid] = 0;
        void'(a4_exp[s_rid].pop_front());
        ret = 1;
      end
    end
    if (s_arvalid && s_arready) a4_exp[s_arid].push_back(int'(s_arlen) + 1);
    nxt = a4_live + ((s_arvalid && s_arready) ? 1 : 0) - ret;
    a4_live <= nxt;
    if (nxt > a4_peak) a4_peak <= nxt;
    // EDGE-TRIGGERED. The condition is a LEVEL on a counter, and a level check
    // on a counter that stops moving reports once per cycle forever whatever
    // the cause. One line per episode, re-armed when the count returns inside
    // the bound. This is the structural half of the fix and it holds even if
    // some future defect finds another way to stall the count.
    if (nxt > MAXR) begin
      if (!a4_over)
        fail("A4", $sformatf("%s: %0d reads outstanding at once, the bound is %0d",
                             phase, nxt, MAXR));
      a4_over <= 1'b1;
    end else a4_over <= 1'b0;
  end

  // ---- X1: nothing originated while reset is low -------------------------
  bit seen_edge = 0;
  always @(posedge clk) if (!seen_edge) seen_edge <= 1'b1;
  always @(posedge clk) if (seen_edge && !rst_n) begin
    if (m_arvalid || m_awvalid || m_wvalid || s_rvalid || s_bvalid)
      fail("X1", "a valid is asserted while rst_ni is low");
  end

  // ---- stimulus ----------------------------------------------------------
  initial begin
    repeat (4) @(posedge clk); @(negedge clk) rst_n = 1; repeat (2) @(posedge clk);

    phase = "A:reads, aligned";
    for (int sz = 0; sz <= 3; sz++)
      for (int l = 0; l <= 3; l++) begin
        arm(32'h1000, l, sz); do_read(4'(l), 32'h1000, l, sz, 2'b01);
      end

    phase = "B:reads, UNALIGNED -- B2 follows bytes covered";
    arm(32'h1004, 1, 3); do_read(4'h7, 32'h1004, 1, 3, 2'b01);
    arm(32'h1002, 1, 3); do_read(4'h8, 32'h1002, 1, 3, 2'b01);
    arm(32'h1006, 3, 3); do_read(4'h9, 32'h1006, 3, 3, 2'b01);
    arm(32'h1001, 0, 1); do_read(4'hA, 32'h1001, 0, 1, 2'b01);

    phase = "C:refused reads";
    arm(32'h1000, 3, 3); do_read(4'h1, 32'h1000, 3, 3, 2'b10);   // WRAP
    arm(32'h1000, 1, 3); do_read(4'h2, 32'h1000, 1, 3, 2'b00);   // FIXED multi
    arm(32'h1000, 7, 2); do_read(4'h3, 32'h1000, 7, 2, 2'b10);
    phase = "C2:FIXED of ONE beat is SERVED";
    arm(32'h1000, 0, 3); do_read(4'h4, 32'h1000, 0, 3, 2'b00);
    arm(32'h1008, 0, 1); do_read(4'h5, 32'h1008, 0, 1, 2'b00);

    phase = "D:long reads";
    arm(32'h2000, 7, 3);  do_read(4'h6, 32'h2000, 7,  3, 2'b01);
    arm(32'h2000, 15, 3); do_read(4'h7, 32'h2000, 15, 3, 2'b01);

    phase = "E:writes, aligned";
    for (int sz = 0; sz <= 3; sz++)
      for (int l = 0; l <= 2; l++) begin
        arm(32'h3000, l, sz); do_write(4'(l), 32'h3000, l, sz, 2'b01, 1'b0);
      end

    phase = "F:writes, SPARSE strobes -- E2 and E3";
    arm(32'h3000, 0, 3); do_write(4'h1, 32'h3000, 0, 3, 2'b01, 1'b1);
    arm(32'h3000, 3, 3); do_write(4'h2, 32'h3000, 3, 3, 2'b01, 1'b1);
    arm(32'h3008, 1, 2); do_write(4'h3, 32'h3008, 1, 2, 2'b01, 1'b1);

    phase = "G:writes, unaligned";
    arm(32'h3004, 1, 3); do_write(4'h4, 32'h3004, 1, 3, 2'b01, 1'b0);
    arm(32'h3002, 2, 3); do_write(4'h5, 32'h3002, 2, 3, 2'b01, 1'b1);

    phase = "H:refused writes";
    arm(32'h3000, 3, 3); do_write(4'h6, 32'h3000, 3, 3, 2'b10, 1'b0);
    arm(32'h3000, 2, 3); do_write(4'h7, 32'h3000, 2, 3, 2'b00, 1'b0);
    phase = "H2:FIXED of ONE beat is SERVED";
    arm(32'h3000, 0, 3); do_write(4'h8, 32'h3000, 0, 3, 2'b00, 1'b0);

    phase = "I:repetition -- every clause holds on the Nth transaction";
    for (int n = 0; n < 24; n++) begin
      arm(32'h4000 + ADDR_W'(n*64), 1, 3);
      do_read(4'(n % 16), 32'h4000 + ADDR_W'(n*64), 1, 3, 2'b01);
      arm(32'h5000 + ADDR_W'(n*64), 1, 3);
      do_write(4'(n % 16), 32'h5000 + ADDR_W'(n*64), 1, 3, 2'b01, (n % 3) == 0);
    end

    phase = "J:refused and served ALTERNATING";
    for (int n = 0; n < 6; n++) begin
      arm(32'h6000, 3, 3); do_read(4'h1, 32'h6000, 3, 3, 2'b10);
      arm(32'h6000 + ADDR_W'(n*32), 1, 3);
      do_read(4'h2, 32'h6000 + ADDR_W'(n*32), 1, 3, 2'b01);
      arm(32'h7000, 2, 3); do_write(4'h3, 32'h7000, 2, 3, 2'b00, 1'b0);
      arm(32'h7000 + ADDR_W'(n*32), 0, 3);
      do_write(4'h4, 32'h7000 + ADDR_W'(n*32), 0, 3, 2'b01, 1'b0);
    end

    phase = "K:concurrency OFFERED, not required";
    // A4 makes MAX_READS an UPPER bound. Two of the six legal implementations
    // accept only one transaction at a time, so acceptance is offered and
    // checked only if taken -- requiring it would reject a conforming design.
    chk_arm = 1'b0;
    begin
      int t; bit took;
      @(negedge clk); s_arid=4'hE; s_araddr=32'h8000; s_arlen=8'd1; s_arsize=3'd3;
                      s_arburst=2'b01; s_arvalid=1;
      for (t=0; t<200; t++) begin @(posedge clk); if (s_arvalid && s_arready) break; end
      took = (t < 200);
      @(negedge clk) s_arvalid=0;
      cov_conc_offered++;
      if (took) begin
        int t2; bit took2;
        // offer SIX concurrent reads. A4 permits the design to accept as few as
        // it likes, so none of this is required -- it is offered so that a
        // design which accepts MORE than the bound has somewhere to reveal it.
        for (int e = 0; e < 6; e++) begin
          @(negedge clk); s_arid = 4'(e); s_araddr = 32'hC000 + ADDR_W'(e*64);
                          s_arlen = 8'd1; s_arsize = 3'd3; s_arburst = 2'b01;
                          s_arvalid = 1;
          for (int t3 = 0; t3 < 24; t3++) begin @(posedge clk); if (s_arvalid && s_arready) break; end
          @(negedge clk) s_arvalid = 0;
        end
        cov_a4_offered++;
        for (int t3 = 0; t3 < 4000; t3++) begin
          @(posedge clk);
          if (rq_addr.size() == 0 && !s_rvalid && a4_live == 0) break;
        end
        @(negedge clk); s_arid=4'hF; s_araddr=32'h9000; s_arlen=8'd1; s_arsize=3'd3;
                        s_arburst=2'b01; s_arvalid=1;
        for (t2=0; t2<64; t2++) begin @(posedge clk); if (s_arvalid && s_arready) break; end
        took2 = (t2 < 64);
        @(negedge clk) s_arvalid=0;
        if (took2) cov_conc_taken++;
        // whether or not the second was taken, every beat must be attributable
        for (t2=0; t2<40000; t2++) begin
          @(posedge clk);
          if (s_rvalid && s_rready) begin
            if (s_rid !== 4'hE && s_rid !== 4'hF)
              fail("D3", $sformatf("%s: R beat carries id %0d, which no outstanding read used",
                                   phase, s_rid));
          end
          if (rq_addr.size() == 0 && !s_rvalid) break;
        end
      end
    end
    repeat (40) @(posedge clk);

    phase = "M:DOWNSTREAM ERRORS -- D6 is sticky, D7 preserves the code";
    // bit 20 asks the downstream slave for an error, bits 19:16 pick which
    // downstream beat carries it, bit 21 selects DECERR over SLVERR.
    arm(32'h10_0000, 1, 3); do_read(4'h1, 32'h10_0000, 1, 3, 2'b01);   // beat 0
    arm(32'h13_0000, 1, 3); do_read(4'h2, 32'h13_0000, 1, 3, 2'b01);   // beat 3
    arm(32'h17_0000, 1, 3); do_read(4'h3, 32'h17_0000, 1, 3, 2'b01);   // LAST beat
    arm(32'h33_0000, 1, 3); do_read(4'h4, 32'h33_0000, 1, 3, 2'b01);   // DECERR
    arm(32'h11_0000, 3, 3); do_read(4'h5, 32'h11_0000, 3, 3, 2'b01);   // long, beat 1
    arm(32'h1F_0000, 3, 3); do_read(4'h6, 32'h1F_0000, 3, 3, 2'b01);   // beat 15 of 16
    // More DECERR, because D7 is about telling the two codes apart and one
    // DECERR read gives a guard exactly one chance to fire. dw_m12 keys on the
    // SECOND DECERR since reset; with a single one it would be unreachable and
    // this would be a dw_m8 repeat -- a mutant in the set that cannot be scored.
    arm(32'h37_0000, 1, 3); do_read(4'hA, 32'h37_0000, 1, 3, 2'b01);   // DECERR, LAST beat
    arm(32'h31_0000, 3, 3); do_read(4'hB, 32'h31_0000, 3, 3, 2'b01);   // DECERR, long, beat 1
    arm(32'h10_0000, 0, 3); do_write(4'h7, 32'h10_0000, 0, 3, 2'b01, 1'b0);
    arm(32'h30_0000, 1, 3); do_write(4'h8, 32'h30_0000, 1, 3, 2'b01, 1'b0);
    arm(32'h10_0000, 2, 3); do_write(4'h9, 32'h10_0000, 2, 3, 2'b01, 1'b1);

    phase = "L:reset mid-stream";
    arm(32'hA000, 7, 3);
    @(negedge clk); s_arid=4'h1; s_araddr=32'hA000; s_arlen=8'd7; s_arsize=3'd3;
                    s_arburst=2'b01; s_arvalid=1;
    repeat (4) @(posedge clk);
    @(negedge clk) s_arvalid=0; rst_n=0;
    repeat (6) @(posedge clk);
    rq_addr.delete(); rq_len.delete(); rq_size.delete(); rq_id.delete();
    wq_id.delete(); n_pend_b=0; rbeat=0;
    @(negedge clk) rst_n=1; repeat (4) @(posedge clk);
    arm(32'hB000, 1, 3); do_read(4'h2, 32'hB000, 1, 3, 2'b01);   // F2, F3

    // A5's antecedent REPORTS and does not gate: whether a conforming design's
    // valid coincides with a stalled ready is its own timing, and a gate on it
    // rejected dut2 and a perturbation on v_nw02. The STIMULUS half gates.
    $display("  [coverage] A5 antecedent held: s_b=%0d s_r=%0d m_aw=%0d m_w=%0d m_ar=%0d",
             cov_a5[0], cov_a5[1], cov_a5[2], cov_a5[3], cov_a5[4]);
    for (int c = 0; c < 5; c++)
      if (cov_a5[c] == 0)
        $display("  [flag] A5 was never judged on channel %0d -- valid was never high while its ready was low. Not a failure: entering that state is the design's timing.", c);
    if (cov_bp_driven < 200)
      fail("FLOOR", $sformatf("a ready was held low on only %0d cycle(s) -- A5 cannot be judged on any channel without backpressure, and that half is the harness's to provide", cov_bp_driven));
    // ---- coverage floors, all counted on STIMULUS (rule 4) ---------------
    if (cov_reads  < 40) fail("FLOOR", $sformatf("only %0d reads driven", cov_reads));
    if (cov_writes < 30) fail("FLOOR", $sformatf("only %0d writes driven", cov_writes));
    if (cov_refused < 8) fail("FLOOR", $sformatf("only %0d refused bursts driven -- C1..C4 undertested", cov_refused));
    if (cov_fixed1 < 3)  fail("FLOOR", "the FIXED single-beat case, which is SERVED, was driven fewer than 3 times");
    if (cov_unaligned < 6) fail("FLOOR", $sformatf("only %0d unaligned requests -- B2's own case", cov_unaligned));
    if (cov_narrow < 6)  fail("FLOOR", $sformatf("only %0d requests narrower than the downstream width", cov_narrow));
    if (cov_size0 < 2)   fail("FLOOR", "size=0, where B1's min is not the downstream width, was barely driven");
    if (cov_partial_strb < 4) fail("FLOOR", "sparse strobes were barely driven -- E2 and E3 undertested");
    if (cov_zero_strb_beat < 2) fail("FLOOR", "no downstream beat with an ALL-ZERO strobe was ever produced -- E3 untested");
    if (cov_long < 2)    fail("FLOOR", "no long burst was driven");
    if (cov_conc_offered < 1) fail("FLOOR", "concurrency was never even offered");
    if (cov_a4_offered < 1)
      fail("FLOOR", "more reads than the MAX_READS bound were never OFFERED, so A4 has no stimulus that could reveal a design accepting too many");
    if (cov_rd_err < 4) fail("FLOOR", $sformatf("only %0d reads asked for a downstream error -- D6 undertested", cov_rd_err));
    if (cov_wr_err < 2) fail("FLOOR", $sformatf("only %0d writes asked for a downstream error -- E6 undertested", cov_wr_err));
    if (cov_decerr < 1)  fail("FLOOR", "DECERR was never driven -- D7 untested");
    if (cov_err_last < 1) fail("FLOOR", "no error was placed on the LAST downstream beat, which is the case that shows D6 is sticky rather than whole-transaction");
    if (cov_rbeats < 120) fail("FLOOR", $sformatf("only %0d upstream R beats were asked for", cov_rbeats));
    if (cov_wbeats < 70)  fail("FLOOR", $sformatf("only %0d upstream W beats were driven", cov_wbeats));
    // ---- FIRED: did the artefacts that must fire, fire? ---------------------
    // Every counter here GATES A FLOOR. The floor already refuses on zero, so
    // these lines add one thing the floor cannot: they distinguish a floor that
    // ran and read zero from a floor that IS NOT IN THIS RUN AT ALL -- deleted,
    // renamed, or skipped. Absent is not zero (rule 20), and v_ca03's read
    // coverage floor sat behind a dangling `else` and was skipped on exactly the
    // runs that were otherwise clean. check_fired.py refuses on both, separately.
    $display("FIRED v_ca06.cov_a4_offered %0d", cov_a4_offered);
    $display("FIRED v_ca06.cov_bp_driven %0d", cov_bp_driven);
    $display("FIRED v_ca06.cov_conc_offered %0d", cov_conc_offered);
    $display("FIRED v_ca06.cov_decerr %0d", cov_decerr);
    $display("FIRED v_ca06.cov_err_last %0d", cov_err_last);
    $display("FIRED v_ca06.cov_fixed1 %0d", cov_fixed1);
    $display("FIRED v_ca06.cov_long %0d", cov_long);
    $display("FIRED v_ca06.cov_narrow %0d", cov_narrow);
    $display("FIRED v_ca06.cov_partial_strb %0d", cov_partial_strb);
    $display("FIRED v_ca06.cov_rbeats %0d", cov_rbeats);
    $display("FIRED v_ca06.cov_rd_err %0d", cov_rd_err);
    $display("FIRED v_ca06.cov_reads %0d", cov_reads);
    $display("FIRED v_ca06.cov_refused %0d", cov_refused);
    $display("FIRED v_ca06.cov_size0 %0d", cov_size0);
    $display("FIRED v_ca06.cov_unaligned %0d", cov_unaligned);
    $display("FIRED v_ca06.cov_wbeats %0d", cov_wbeats);
    $display("FIRED v_ca06.cov_wr_err %0d", cov_wr_err);
    $display("FIRED v_ca06.cov_writes %0d", cov_writes);
    $display("FIRED v_ca06.cov_zero_strb_beat %0d", cov_zero_strb_beat);

    if (n_fail == 0) $display("RESULT: PASS");
    // Same hazard, and this one is worse: the RESULT line is the COUNTING BASIS
    // every downstream number is read from. It printed "(1 failure )" with an
    // invisible NUL, and a parser pinned to the plural read that as no failures.
    else if (n_fail == 1) $display("RESULT: FAIL (1 failure)");
    else                  $display("RESULT: FAIL (%0d failures)", n_fail);
    $display("  [coverage] reads=%0d writes=%0d refused=%0d unaligned=%0d narrow=%0d size0=%0d",
             cov_reads, cov_writes, cov_refused, cov_unaligned, cov_narrow, cov_size0);
    $display("  [coverage] sparse=%0d zero-strb-beats=%0d fixed1=%0d long=%0d conc offered/taken=%0d/%0d",
             cov_partial_strb, cov_zero_strb_beat, cov_fixed1, cov_long,
             cov_conc_offered, cov_conc_taken);
    $display("  [coverage] R beats asked=%0d  W beats driven=%0d  ds AR=%0d ds AW=%0d",
             cov_rbeats, cov_wbeats, n_ds_ar, n_ds_aw);
    $display("  [coverage] downstream errors: reads=%0d writes=%0d decerr=%0d on-last-beat=%0d",
             cov_rd_err, cov_wr_err, cov_decerr, cov_err_last);
    $display("  [coverage] A4: peak reads outstanding = %0d against a bound of %0d", a4_peak, MAXR);
    $finish;
  end

  initial begin
    #40000000;
    $display("FAIL [WATCHDOG] the testbench did not finish; %0d failure(s) so far", n_fail);
    $display("RESULT: FAIL (watchdog)");
    $finish;
  end
endmodule
