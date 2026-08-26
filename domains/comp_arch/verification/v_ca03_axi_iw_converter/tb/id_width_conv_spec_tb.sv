// =============================================================================
// id_width_conv_spec_tb.sv -- REFERENCE TESTBENCH for v_ca03. NEVER SHIPPED.
// =============================================================================
// Establishes the kill ceiling. Written against spec/id_width_conv_spec.md.
//
// THE MODEL IS OF THE CONTRACT, NOT OF THE ANCHOR.
// It keeps exactly what the clauses name: a per-identifier outstanding COUNT
// (A5), the set of identifiers with a non-zero count (A2/A3), a per-identifier
// FIFO of accepted transactions (B1), and the live slave-to-master mapping
// (D1/D2). It does not mirror the anchor's table, free-list or search order --
// if it did, both would share the same blind spots and the boundary mutants
// would be unkillable in exactly the cases they exist for.
//
// RULE 5 APPLIES WHEN THIS DISAGREES WITH SOMETHING. The model is nontrivial,
// so unlike a scoreboard it can be wrong while passing the golden. On any
// failure, run the failing case through the golden before changing a check.
// =============================================================================

module id_width_conv_tb;


  // VCD on demand, for the rule-34 stimulus-variation check. Guarded by a
  // plusarg so a normal scoring run is byte-for-byte unaffected.
  initial if ($test$plusargs("vcd")) begin
    $dumpfile("dump.vcd");
    $dumpvars(0, id_width_conv_tb);
  end
  // ---- scored configuration (spec section 9) --------------------------------
  localparam int SLV_ID_W = 4, MST_ID_W = 2, ADDR_W = 32, DATA_W = 32;
  localparam int MAX_UNIQ = 4, MAX_TXN = 2;
  localparam int NID = 1 << SLV_ID_W;
  localparam int RETIRE_WINDOW = 2;   // A4

  logic clk = 0, rst_n = 0;
  always #5 clk = ~clk;

  logic [SLV_ID_W-1:0] s_awid=0, s_arid=0, s_bid, s_rid;
  logic [ADDR_W-1:0]   s_awaddr=0, s_araddr=0, s_rdata;
  logic [DATA_W-1:0]   s_wdata=0;
  logic [7:0]          s_awlen=0, s_arlen=0;
  logic [DATA_W/8-1:0] s_wstrb=0;
  logic [1:0]          s_bresp, s_rresp;
  logic s_awvalid=0, s_awready, s_wlast=0, s_wvalid=0, s_wready;
  logic s_bvalid, s_bready, s_arvalid=0, s_arready, s_rlast, s_rvalid, s_rready;

  logic [MST_ID_W-1:0] m_awid, m_arid, m_bid=0, m_rid=0;
  logic [ADDR_W-1:0]   m_awaddr, m_araddr;
  logic [DATA_W-1:0]   m_wdata, m_rdata=0;
  logic [7:0]          m_awlen, m_arlen;
  logic [DATA_W/8-1:0] m_wstrb;
  logic [1:0]          m_bresp=0, m_rresp=0;
  logic m_awvalid, m_awready, m_wlast, m_wvalid, m_wready;
  logic m_bvalid=0, m_bready, m_arvalid, m_arready, m_rlast=0, m_rvalid=0, m_rready;

  id_width_conv #(.SLV_ID_W(SLV_ID_W), .MST_ID_W(MST_ID_W), .ADDR_W(ADDR_W),
                  .DATA_W(DATA_W), .MAX_UNIQ_IDS(MAX_UNIQ), .MAX_TXNS_PER_ID(MAX_TXN)) dut (
    .clk_i(clk), .rst_ni(rst_n),
    .s_awid, .s_awaddr, .s_awlen, .s_awvalid, .s_awready,
    .s_wdata, .s_wstrb, .s_wlast, .s_wvalid, .s_wready,
    .s_bid, .s_bresp, .s_bvalid, .s_bready,
    .s_arid, .s_araddr, .s_arlen, .s_arvalid, .s_arready,
    .s_rid, .s_rdata, .s_rresp, .s_rlast, .s_rvalid, .s_rready,
    .m_awid, .m_awaddr, .m_awlen, .m_awvalid, .m_awready,
    .m_wdata, .m_wstrb, .m_wlast, .m_wvalid, .m_wready,
    .m_bid, .m_bresp, .m_bvalid, .m_bready,
    .m_arid, .m_araddr, .m_arlen, .m_arvalid, .m_arready,
    .m_rid, .m_rdata, .m_rresp, .m_rlast, .m_rvalid, .m_rready);

  int unsigned n_fail = 0;
  // E1 now covers `resp` on BOTH response channels. A responder that returns
  // only OKAY makes that half of the clause unfalsifiable: the checker compares
  // against the constant its own responder drives, so port and expectation are
  // the same symbol and nothing can disagree.
  function automatic logic [1:0] resp_of(input logic [ADDR_W-1:0] a);
    case (a[1:0])
      2'b10:   return 2'b10;   // SLVERR
      2'b11:   return 2'b11;   // DECERR
      default: return 2'b00;   // OKAY
    endcase
  endfunction

  task automatic fail(input string cl, input string msg);
    n_fail = n_fail + 1;
    if (n_fail <= 40) $display("FAIL [%s] %s (t=%0t)", cl, msg, $time);
  endtask

  // ---- THE CONTRACT MODEL --------------------------------------------------
  int unsigned live_r [NID];          // A5: outstanding reads per slave id
  int unsigned live_w [NID];
  int unsigned addr_q [NID][$];       // B1: accepted read addrs, per id, in order
  int unsigned waddr_q [NID][$];      // the same for WRITES -- E1's new half
  int cov_err_r = 0, cov_err_b = 0;   // NON-OKAY responses actually returned
  int unsigned len_q  [NID][$];       // each accepted read's burst length
  int unsigned rbeat  [NID];          // beats seen so far of the head burst
  int unsigned map_of [NID];          // D1: master id assigned to a live slave id
  bit          map_valid [NID];
  int unsigned owner_of [1<<MST_ID_W];// D1 reverse: which slave id holds a master id
  bit          owner_valid [1<<MST_ID_W];

  function automatic int unsigned distinct_r();
    distinct_r = 0;
    for (int i = 0; i < NID; i++) if (live_r[i] != 0) distinct_r++;
  endfunction
  // A3 + A5 together: may a read with this id be accepted right now?
  function automatic bit may_accept_r(input int unsigned id);
    if (live_r[id] >= MAX_TXN)                          return 1'b0;   // A5
    if (live_r[id] == 0 && distinct_r() >= MAX_UNIQ)    return 1'b0;   // A3
    return 1'b1;
  endfunction

  int unsigned n_ar=0, n_mar=0, n_r=0, n_rbeat=0, n_aw=0, n_b=0;
  int unsigned cov_longburst=0, cov_wfull=0, cov_mixed_w=0, cov_boundary_long=0;
  int unsigned n_rbeat_exp=0, n_aw_issued=0;
  int unsigned cov_full_new=0, cov_full_same=0, cov_depth=0, cov_retire=0, cov_mixed=0;

  // ---- master-side slave model ---------------------------------------------
  // MULTI-BEAT. It honours m_arlen and derives each beat's data from the
  // address it was given, so the slave-side checker can predict every beat from
  // the transaction's own address. A single-beat responder that returns a
  // constant cannot check E1 (payload forwarded unmodified), C1 (the response
  // carries its transaction's identifier) or D4 (one transaction in, one out) --
  // every beat looks like every other beat.
  int unsigned mq_id [$], mq_addr [$], mq_len [$];
  int unsigned m_beat = 0;
  // THE TESTBENCH IS A SOURCE, AND D5 BINDS THE DESIGN -- but a source that
  // withdraws its own offer makes the design LOOK like it withdrew. `reply_en`
  // going low at the end of a `drain()` took back an R beat the design was still
  // holding, and the design's s_rvalid followed:
  //     DIAG t=8335 ch=1 withdraw | reply_en=0 mq=2 | m_rvalid=0 s_rvalid=0
  // Two D5 failures on the GOLDEN, neither of them the golden's. `hold_m*` keeps
  // an offer up once made until its ready is seen; `reply_en` still decides when
  // a NEW response may start, which is all it was ever for.
  logic hold_mr = 0, hold_mb = 0;
  always @(posedge clk) if (!rst_n) begin
    hold_mr <= 1'b0; hold_mb <= 1'b0;
  end else begin
    hold_mr <= m_rvalid && !m_rready;
    hold_mb <= m_bvalid && !m_bready;
  end
  logic reply_en = 0;
  always @(posedge clk) if (rst_n && m_arvalid && m_arready) begin
    n_mar++;
    mq_id.push_back(m_arid); mq_addr.push_back(m_araddr); mq_len.push_back(m_arlen);
  end
  always_comb begin
    m_rvalid = (reply_en || hold_mr) && (mq_id.size() > 0);
    m_rid    = (mq_id.size() > 0) ? MST_ID_W'(mq_id[0]) : '0;
    m_rdata  = (mq_id.size() > 0) ? (mq_addr[0] + m_beat) : '0;
    m_rlast  = (mq_id.size() > 0) && (m_beat == mq_len[0]);
    m_rresp  = (mq_id.size() > 0) ? resp_of(mq_addr[0]) : 2'b00;
  end
  always @(posedge clk) if (rst_n && m_rvalid && m_rready) begin
    if (m_beat == mq_len[0]) begin
      void'(mq_id.pop_front()); void'(mq_addr.pop_front()); void'(mq_len.pop_front());
      m_beat <= 0;
    end else m_beat <= m_beat + 1;
  end

  // Write responses. B is returned only once the write's own W burst has
  // completed at the master port; clause B3 puts the beats in address order, so
  // pairing the head of the AW queue with each m_wlast is exact.
  int unsigned awq [$], bq [$];
  int unsigned awq_a [$], bq_a [$];      // the address each carries, for resp_of
  always @(posedge clk) if (rst_n && m_awvalid && m_awready) begin
    awq.push_back(m_awid); awq_a.push_back(m_awaddr);
  end
  always @(posedge clk) if (rst_n && m_wvalid && m_wready && m_wlast) begin
    if (awq.size() > 0) begin
      bq.push_back(awq[0]);   void'(awq.pop_front());
      bq_a.push_back(awq_a[0]); void'(awq_a.pop_front());
    end
  end
  always_comb begin
    m_bvalid = (reply_en || hold_mb) && (bq.size() > 0);
    m_bid    = (bq.size() > 0) ? MST_ID_W'(bq[0]) : '0;
    m_bresp  = (bq_a.size() > 0) ? resp_of(ADDR_W'(bq_a[0])) : 2'b00;
  end
  always @(posedge clk) if (rst_n && m_bvalid && m_bready) begin
    void'(bq.pop_front()); void'(bq_a.pop_front());
  end

  // ---- D5: BACKPRESSURE, and the antecedent it creates ---------------------
  // Held at 1, these five readies make D5's antecedent -- `valid && !ready` --
  // unreachable on every channel the design drives, so a design that withdraws
  // an offer before its ready is seen is undetectable and D5 is a clause with no
  // instrument. Two halves, one boundary: the clause and the stimulus that can
  // falsify it land together or neither lands.
  //
  // FREE-RUNNING, AND NOT ARMED BY `valid`. The first version of this stall
  // armed combinationally on each channel's own valid, so the stall would land
  // on the cycle the offer was made. That closes a loop -- ready -> design ->
  // valid -> arm -> ready -- and here it did not converge:
  //
  //     %Warning-UNOPTFLAT: Circular combinational logic: 'id_width_conv_tb.m_awready'
  //
  //     26 failures across A1, A3, COVERAGE, D4, E1 and FLOOR, none of them a
  //     design defect, and IDENTICAL for four different one-hot choices of which
  //     single ready was made reactive. A defect that does not change when you
  //     change which channel provokes it is a settle order, not a channel.
  //
  // On v_ca06 the same loop CONVERGED and gave the right answer. Nothing in
  // either run said which had happened; the harness builds -Wno-fatal, which is
  // right for a vendored anchor, and the anchor contributes its own UNOPTFLAT
  // warnings that dilute this one to invisibility.
  //
  // Decoupling costs nothing. The objection to a REGISTERED arm -- the stall
  // lands a cycle after valid rose, so a one-cycle valid is already accepted --
  // does not reach a stall that is simply low some of the time regardless. The
  // per-channel antecedent counts printed at the end are the evidence.
  //
  // Aperiodic on purpose: a fixed duty cycle can resonate with a design's own
  // period and stall only in phases where nothing is offered. Different bit
  // pairs per channel keep the five decorrelated.
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
  // The STIMULUS half, harness-determined by construction: how many cycles this
  // testbench held a ready low. It reads no design output, so it cannot reject
  // correct hardware -- which is why the ANTECEDENT counts are reported and this
  // one is gated.
  int cov_bp_driven = 0;
  always @(posedge clk) if (rst_n && (stall_sb|stall_sr|stall_maw|stall_mw|stall_mar))
    cov_bp_driven <= cov_bp_driven + 1;

  // ---- D5's CHECKER --------------------------------------------------------
  // The payload signature is EXACT here, not truncated: the widest channel is
  // 42 bits (m_ar: id 2 + addr 32 + len 8), so every bit the clause speaks about
  // is compared. A truncated signature cannot fail on the bits it drops, and a
  // check that cannot fail on part of its subject should say which part.
  int cov_d5 [5];
  logic pv [5];
  logic [63:0] pp [5];
  function automatic logic [63:0] pay(input int c);
    case (c)
      0: return {58'b0, s_bid,  s_bresp};                    // 6 bits
      1: return {25'b0, s_rid,  s_rdata, s_rresp, s_rlast};  // 39 bits
      2: return {22'b0, m_awid, m_awaddr, m_awlen};          // 42 bits
      3: return {27'b0, m_wdata, m_wstrb, m_wlast};          // 37 bits
      default: return {22'b0, m_arid, m_araddr, m_arlen};    // 42 bits
    endcase
  endfunction
  // pv MUST clear on reset. F1 says the design presents no response while
  // rst_ni is low, so an offer held across a reset is withdrawn LEGITIMATELY --
  // and a checker that only skips WHILE reset is low carries its stale
  // held-offer into the first cycle after release. That fired on v_ca06's
  // golden before it was fixed; it is not a hypothetical.
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
          fail("D5", $sformatf("channel %0d: valid was withdrawn without a handshake (t=%0t)", c, $time));
        else if (pay(c) !== pp[c])
          fail("D5", $sformatf("channel %0d: the payload changed while the offer was held (t=%0t)", c, $time));
      end
      if (v[c] && !r[c]) cov_d5[c]++;
      pv[c] <= v[c] && !r[c];
      pp[c] <= pay(c);
    end
  end

  // ---- model updates + checks ---------------------------------------------
  always @(posedge clk) begin
    if (!rst_n) begin
      for (int i = 0; i < NID; i++) begin
        live_r[i] <= 0; live_w[i] <= 0; addr_q[i].delete(); len_q[i].delete();
        waddr_q[i].delete();
        rbeat[i] <= 0; map_valid[i] <= 1'b0;
      end
      for (int i = 0; i < (1<<MST_ID_W); i++) owner_valid[i] <= 1'b0;
    end else begin
      if (s_arvalid && s_arready) begin
        live_r[s_arid] <= live_r[s_arid] + 1;
        addr_q[s_arid].push_back(s_araddr);
        len_q[s_arid].push_back(s_arlen);
        n_ar++;
        n_rbeat_exp <= n_rbeat_exp + s_arlen + 1;   // stimulus, not response
      end
      // D1: a master id may serve only one live slave id at a time
      if (m_arvalid && m_arready) begin
        if (owner_valid[m_arid] && owner_of[m_arid] != s_arid_at_mar)
          fail("D1", $sformatf("master id %0d serves slave id %0d and %0d at once",
                               m_arid, owner_of[m_arid], s_arid_at_mar));
      end
      // ---- every read data BEAT, not only the last -----------------------
      if (s_rvalid && s_rready) begin
        n_rbeat++;
        if (addr_q[s_rid].size() == 0) begin
          // C1/C2 together: either this beat carries an identifier that has
          // nothing outstanding, or an identifier that is not its own.
          fail("C2", $sformatf("read beat for slave id %0d with none outstanding", s_rid));
        end else begin
          automatic int unsigned exp_data = addr_q[s_rid][0] + rbeat[s_rid];
          automatic bit exp_last = (rbeat[s_rid] == len_q[s_rid][0]);
          if (s_rdata !== exp_data[DATA_W-1:0])
            fail("E1", $sformatf("read beat %0d of slave id %0d carries %08x, expected %08x -- the data a beat carries follows from the address its transaction was issued with, which E1 forwards unmodified",
                                 rbeat[s_rid], s_rid, s_rdata, exp_data[DATA_W-1:0]));
          if (s_rresp !== resp_of(ADDR_W'(addr_q[s_rid][0])))
            fail("E1", $sformatf("read beat of slave id %0d carries resp %b, expected %b -- the subordinate's code is forwarded unmodified",
                                 s_rid, s_rresp, resp_of(ADDR_W'(addr_q[s_rid][0]))));
          if (resp_of(ADDR_W'(addr_q[s_rid][0])) != 2'b00) cov_err_r++;
          if (s_rlast !== exp_last)
            fail("D4", $sformatf("slave id %0d: rlast is %0b on beat %0d of a %0d-beat burst -- one accepted transaction produces exactly one response, of exactly its own length",
                                 s_rid, s_rlast, rbeat[s_rid], len_q[s_rid][0] + 1));
          if (s_rlast) begin
            live_r[s_rid] <= live_r[s_rid] - 1;
            void'(addr_q[s_rid].pop_front());   // B1: consume in acceptance order
            void'(len_q[s_rid].pop_front());
            rbeat[s_rid] <= 0;
            n_r++;
          end else begin
            rbeat[s_rid] <= rbeat[s_rid] + 1;
          end
        end
      end

      // ---- the WRITE side ------------------------------------------------
      if (s_awvalid && s_awready) begin
        live_w[s_awid] <= live_w[s_awid] + 1;
        waddr_q[s_awid].push_back(s_awaddr);
        n_aw++;
      end
      if (s_bvalid && s_bready) begin
        n_b++;
        if (live_w[s_bid] == 0)
          fail("C2", $sformatf("write response for slave id %0d with none outstanding", s_bid));
        else
          live_w[s_bid] <= live_w[s_bid] - 1;
        if (waddr_q[s_bid].size() == 0)
          fail("C2", $sformatf("write response for slave id %0d with no write outstanding", s_bid));
        else begin
          if (s_bresp !== resp_of(ADDR_W'(waddr_q[s_bid][0])))
            fail("E1", $sformatf("write response for slave id %0d carries resp %b, expected %b -- a converter alters identifiers and nothing else",
                                 s_bid, s_bresp, resp_of(ADDR_W'(waddr_q[s_bid][0]))));
          if (resp_of(ADDR_W'(waddr_q[s_bid][0])) != 2'b00) cov_err_b++;
          void'(waddr_q[s_bid].pop_front());
        end
      end
    end
  end
  // the slave id whose master request is being issued -- tracked for D1
  int unsigned s_arid_at_mar = 0;
  always @(posedge clk) if (rst_n && s_arvalid && s_arready) s_arid_at_mar <= s_arid;

  // ---- driver --------------------------------------------------------------
  // Offers a read and reports whether it was accepted within `budget`.
  task automatic offer_ar(input int unsigned id, input int budget, output bit acc,
                          output int took, input int unsigned len = 0);
    acc = 0; took = 0;
    @(negedge clk); s_arvalid = 1; s_arid = id[SLV_ID_W-1:0];
    s_araddr = 32'h1000 + (id << 8) + n_ar; s_arlen = len[7:0];
    while (took < budget) begin
      @(posedge clk);
      if (s_arready) begin acc = 1; break; end
      took++;
    end
    @(negedge clk) s_arvalid = 0;
  endtask
  // Offers a write address; send_w then drives its data burst. Both hold valid
  // until ready, so no offer is ever withdrawn.
  task automatic offer_aw(input int unsigned id, input int budget, output bit acc,
                          output int took, input int unsigned len = 0);
    acc = 0; took = 0;
    @(negedge clk); s_awvalid = 1; s_awid = id[SLV_ID_W-1:0];
    s_awaddr = 32'h5000 + (id << 8) + n_aw; s_awlen = len[7:0];
    while (took < budget) begin
      @(posedge clk);
      if (s_awready) begin acc = 1; break; end
      took++;
    end
    @(negedge clk) s_awvalid = 0;
  endtask

  task automatic send_w(input int unsigned len);
    for (int b = 0; b <= int'(len); b++) begin
      @(negedge clk); s_wvalid = 1; s_wdata = 32'hD000_0000 + b;
      s_wstrb = '1; s_wlast = (b == int'(len));
      forever begin @(posedge clk); if (s_wready) break; end
    end
    @(negedge clk); s_wvalid = 0; s_wlast = 0;
  endtask

  task automatic drain(input int n);
    reply_en = 1; repeat (n) @(posedge clk); reply_en = 0;
  endtask

  string phase = "init";

  initial begin
    bit acc; int took;
    repeat (4) @(posedge clk);
    @(negedge clk) rst_n = 1;
    repeat (2) @(posedge clk);

    // ---- BOUNDARY 1: the table, from below and at the limit ---------------
    phase = "A3";
    for (int i = 0; i < MAX_UNIQ-1; i++) begin
      offer_ar(i, 40, acc, took);
      if (!acc) fail("A3", $sformatf("id %0d refused with only %0d distinct outstanding", i, i));
    end
    cov_full_new++;   // offered: a new id at MAX_UNIQ-1 distinct
    offer_ar(MAX_UNIQ-1, 40, acc, took);
    if (!acc) fail("A3", "a new id was refused at MAX_UNIQ-1 distinct outstanding");
    cov_full_new++;   // offered: a new id at a full table
    offer_ar(9, 25, acc, took);
    if (acc) fail("A3", "a NEW id was accepted with the table already full");

    // ---- BOUNDARY 4: same id at a full table must NOT be blocked ----------
    phase = "A3-same-id";
    cov_full_same++;  // offered: an already-outstanding id at a full table
    offer_ar(0, 40, acc, took);
    if (!acc) fail("A3", "an ALREADY-OUTSTANDING id was refused at a full table");

    // ---- BOUNDARY 2: depth per identifier --------------------------------
    phase = "A5";
    drain(60);
    offer_ar(5, 40, acc, took);
    if (!acc) fail("A5", "first txn on a fresh id refused");
    cov_depth++;      // offered: the 2nd txn on one id
    offer_ar(5, 40, acc, took);
    if (!acc) fail("A5", "second txn on the same id refused, MAX_TXNS_PER_ID=2");
    cov_depth++;      // offered: the 3rd
    offer_ar(5, 25, acc, took);
    if (acc) fail("A5", "third txn on the same id accepted, MAX_TXNS_PER_ID=2");
    drain(60);

    // ---- BOUNDARY 3: the entry is free within A4's window -----------------
    phase = "A4";
    for (int i = 0; i < MAX_UNIQ; i++) offer_ar(i, 40, acc, took);
    fork
      begin
        offer_ar(9, 40, acc, took);
        if (!acc) fail("A4", "new id never accepted after a retirement");
        else if (took > RETIRE_WINDOW)
          fail("A4", $sformatf("entry freed late: new id accepted %0d cycles after retirement, window is %0d",
                               took, RETIRE_WINDOW));
      end
      begin
        cov_retire++;   // offered: a new id across a retirement edge
        @(posedge clk); reply_en = 1;
        @(posedge clk);
        while (!(m_rvalid && m_rready)) @(posedge clk);
        @(posedge clk) reply_en = 0;
      end
    join
    drain(80);

    // ---- BOUNDARY 5: reads and writes are counted separately -------------
    phase = "A1";
    for (int i = 0; i < MAX_UNIQ; i++) offer_ar(i, 40, acc, took);
    begin
      int w = 0; bit wacc = 0;
      cov_mixed++;    // offered: a write while reads fill the table
      @(negedge clk); s_awvalid = 1; s_awid = 4'd9; s_awaddr = 32'h5000; s_awlen = 0;
      while (w < 30) begin @(posedge clk); if (s_awready) begin wacc = 1; break; end w++; end
      @(negedge clk) s_awvalid = 0;
      if (!wacc) fail("A1", "a WRITE was refused while only READS occupied the table");
      // Send this write's data and let it retire. Accepting an address and
      // never supplying its W burst leaves the transaction outstanding for the
      // rest of the run, holding a table entry -- every later write boundary is
      // then measured one entry short, and the failure is reported against the
      // design rather than against the stimulus that caused it.
      else begin n_aw_issued++; send_w(0); end
    end
    drain(160);

    // ---- random traffic against the model --------------------------------
    phase = "random";
    for (int k = 0; k < 120; k++) begin
      automatic int unsigned id = $urandom_range(0, 7);
      automatic bit expect_ok = may_accept_r(id);
      offer_ar(id, expect_ok ? 40 : 20, acc, took);
      if (expect_ok && !acc)
        fail("A3/A5", $sformatf("id %0d refused though the contract permits it", id));
      if (!expect_ok && acc)
        fail("A3/A5", $sformatf("id %0d accepted though the contract forbids it", id));
      if ($urandom_range(0,2) == 0) drain($urandom_range(4, 20));
    end
    drain(200);

    for (int i = 0; i < NID; i++)
      if (live_r[i] != 0) fail("D4", $sformatf("id %0d still outstanding after drain (%0d)", i, live_r[i]));
    // NOTE rule 4: every floor below counts what this testbench OFFERED, never
    // what the design accepted. A floor a faulty design can zero is measuring
    // the design, not the stimulus -- these all fired on every mutant before
    // this was fixed.

    // ---- BOUNDARY 6: the same boundary, probed with LONG BURSTS ----------
    // A3 bounds the number of distinct identifiers, not their burst lengths. A
    // design that applies the bound one entry early only for long bursts passes
    // every single-beat probe above and fails nothing until a burst arrives.
    phase = "boundary with long bursts";
    drain(80);
    for (int i = 0; i < MAX_UNIQ-1; i++) begin
      offer_ar(i, 8, acc, took, 6);
      if (!acc) fail("A3", $sformatf("id %0d refused with only %0d distinct outstanding, seven-beat burst", i, i));
    end
    offer_ar(MAX_UNIQ-1, 8, acc, took, 6);
    if (!acc) fail("A3", "a new id was refused at MAX_UNIQ-1 distinct outstanding, seven-beat burst");
    cov_boundary_long++; cov_longburst++;
    drain(300);

    // ---- WRITES, to a full write table -----------------------------------
    // Everything above is read-only. A1 counts reads and writes SEPARATELY, and
    // nothing on the write side -- the response identifier, its resp field, or
    // whether one write produces exactly one response -- has been observed yet.
    phase = "writes";
    for (int i = 0; i < MAX_UNIQ; i++) begin
      offer_aw(i, 400, acc, took, 1);
      if (!acc) fail("A3", $sformatf("write id %0d refused with only %0d distinct write ids outstanding", i, i));
      else begin n_aw_issued++; send_w(1); end
    end
    cov_wfull++;
    // A read offered while ONLY writes occupy the table must be accepted.
    offer_ar(5, 12, acc, took, 0);
    if (!acc) fail("A1", "a READ was refused while only WRITES occupied the table");
    cov_mixed_w++;
    drain(300);

    // ---- sustained traffic: enough beats and responses to pass a count ----
    // A defect that appears on the thirty-second beat, or after the sixteenth
    // write response, is invisible to a run that issues a handful of each.
    phase = "sustained";
    for (int k = 0; k < 16; k++) begin
      offer_ar(k % MAX_UNIQ, 60, acc, took, 3);
      offer_aw(k % MAX_UNIQ, 60, acc, took, 0);
      if (acc) begin n_aw_issued++; send_w(0); end
      drain(40);
    end
    drain(400);

    // ---- SUSTAINED TRAFFIC UNDER BACKPRESSURE ----------------------------
    // Backpressure is on for the WHOLE run -- it does not need a window, and an
    // earlier version of this comment claimed it did. That claim was wrong: the
    // 26 failures that seemed to show the stalls breaking the A3/A4 budget
    // probes were the combinational loop described above, not the stalls.
    // Confirmed by removing the loop and leaving the stalls global, which passes
    // every clause.
    //
    // This phase stays because the earlier phases reach D5's antecedent only
    // lightly on the two address channels. Budgets are generous (400 cycles, not
    // 8) because a design that is slow under backpressure is conforming --
    // latitude item 2 -- and a budget that expired here would report a design's
    // legal slowness as an A3 refusal.
    phase = "sustained under backpressure -- D5";
    for (int k = 0; k < 12; k++) begin
      offer_ar(k % MAX_UNIQ, 400, acc, took, 3);
      offer_aw(k % MAX_UNIQ, 400, acc, took, 1);
      if (acc) begin n_aw_issued++; send_w(1); end
      drain(60);
    end
    drain(600);

    if (cov_full_new < 2)  fail("FLOOR", "the table boundary was not exercised from both sides");
    if (cov_full_same < 1) fail("FLOOR", "a same-id request at a full table was never offered");
    if (cov_depth < 2)     fail("FLOOR", "the per-id depth boundary was not exercised from both sides");
    if (cov_retire < 1)    fail("FLOOR", "the retirement window was never measured");
    if (cov_mixed < 1)     fail("FLOOR", "reads and writes were never mixed at the boundary");
    if (cov_boundary_long < 1)
      fail("FLOOR", "the table boundary was never probed with a long burst");
    if (cov_longburst < 1)
      fail("FLOOR", "no burst longer than one beat was ever issued -- E1, C1 and D4 go unchecked on a single-beat run");
    if (cov_wfull < 1)     fail("FLOOR", "the WRITE table was never filled");
    if (cov_mixed_w < 1)   fail("FLOOR", "a read was never offered while only writes occupied the table");
    if (n_rbeat_exp < 40)
      fail("FLOOR", $sformatf("only %0d read data beats were ever ASKED FOR", n_rbeat_exp));
    if (n_aw_issued < 16)
      fail("FLOOR", $sformatf("only %0d writes were issued", n_aw_issued));

    // D5's antecedent REPORTS and does not gate. Whether a conforming design's
    // valid ever coincides with a stalled ready is that design's own timing, and
    // a gate on it REJECTS CORRECT HARDWARE -- measured on v_ca06, where a
    // condition floor of this shape rejected dut2 and a conformant perturbation.
    // The STIMULUS half is the harness's to provide and IS gated, below.
    $display("  [coverage] D5 antecedent held: s_b=%0d s_r=%0d m_aw=%0d m_w=%0d m_ar=%0d",
             cov_d5[0], cov_d5[1], cov_d5[2], cov_d5[3], cov_d5[4]);
    for (int c = 0; c < 5; c++)
      if (cov_d5[c] == 0)
        $display("  [flag] D5 was never judged on channel %0d -- valid was never high while its ready was low. Not a failure: entering that state is the design's timing.", c);
    if (cov_bp_driven < 200)
      fail("FLOOR", $sformatf("a ready was held low on only %0d cycle(s) -- D5 cannot be judged on any channel without backpressure, and that half is the harness's to provide", cov_bp_driven));

    $display("METRIC: reads accepted %0d, master reads %0d, responses %0d", n_ar, n_mar, n_r);
    // A DANGLING `else`, AND IT COST TWO THINGS. This read
    //     if (n_fail == 0) $display("RESULT: PASS");
    //     else  // comment
    //     // comment
    //     if (cov_err_r < 4) fail(...);
    //     ...
    //     $display("RESULT: FAIL (%0d failures)", n_fail);
    // The `else` bound to the cov_err_r check, not to a FAIL display. So:
    //   1. THE READ-COVERAGE FLOOR RAN ONLY ON A RUN THAT HAD ALREADY FAILED.
    //      A floor that is skipped exactly when the run is otherwise clean is a
    //      floor that cannot do the one job it has.
    //   2. `RESULT: FAIL` PRINTED UNCONDITIONALLY -- every passing run of this
    //      testbench ended with a FAIL line. The harness greps PASS first, so
    //      the verdicts were right; they were right because of the ORDER OF TWO
    //      GREPS in a file this testbench does not control.
    // Floors run before the verdict is computed, and exactly one RESULT line is
    // printed.
    //
    // E1's resp half is unfalsifiable if every response returned is OKAY: the
    // checker would be comparing against the constant the responder drives.
    if (cov_err_r < 4)
      fail("COVERAGE", $sformatf("only %0d non-OKAY READ responses were returned -- E1's resp half is untested at OKAY alone", cov_err_r));
    if (cov_err_b < 4)
      fail("COVERAGE", $sformatf("only %0d non-OKAY WRITE responses were returned -- E1's new B-channel half is untested at OKAY alone", cov_err_b));
    $display("  [coverage] non-OKAY responses returned: reads=%0d writes=%0d", cov_err_r, cov_err_b);
    // ---- FIRED: did the artefacts that must fire, fire? ---------------------
    // Every counter here GATES A FLOOR. The floor already refuses on zero, so
    // these lines add one thing the floor cannot: they distinguish a floor that
    // ran and read zero from a floor that IS NOT IN THIS RUN AT ALL -- deleted,
    // renamed, or skipped. Absent is not zero (rule 20), and v_ca03's read
    // coverage floor sat behind a dangling `else` and was skipped on exactly the
    // runs that were otherwise clean. check_fired.py refuses on both, separately.
    $display("FIRED v_ca03.cov_boundary_long %0d", cov_boundary_long);
    $display("FIRED v_ca03.cov_bp_driven %0d", cov_bp_driven);
    $display("FIRED v_ca03.cov_depth %0d", cov_depth);
    $display("FIRED v_ca03.cov_err_b %0d", cov_err_b);
    $display("FIRED v_ca03.cov_err_r %0d", cov_err_r);
    $display("FIRED v_ca03.cov_full_new %0d", cov_full_new);
    $display("FIRED v_ca03.cov_full_same %0d", cov_full_same);
    $display("FIRED v_ca03.cov_longburst %0d", cov_longburst);
    $display("FIRED v_ca03.cov_mixed %0d", cov_mixed);
    $display("FIRED v_ca03.cov_mixed_w %0d", cov_mixed_w);
    $display("FIRED v_ca03.cov_retire %0d", cov_retire);
    $display("FIRED v_ca03.cov_wfull %0d", cov_wfull);
    $display("FIRED v_ca03.n_aw_issued %0d", n_aw_issued);
    $display("FIRED v_ca03.n_rbeat_exp %0d", n_rbeat_exp);
    if (n_fail == 0) $display("RESULT: PASS");
    else             $display("RESULT: FAIL (%0d failures)", n_fail);
    $finish;
  end

  initial begin
    #4_000_000;
    $display("RESULT: FAIL (watchdog fired in phase %s)", phase);
    $finish;
  end

endmodule
