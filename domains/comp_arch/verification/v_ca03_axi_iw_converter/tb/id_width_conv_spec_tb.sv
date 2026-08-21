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
  logic s_bvalid, s_bready=1, s_arvalid=0, s_arready, s_rlast, s_rvalid, s_rready=1;

  logic [MST_ID_W-1:0] m_awid, m_arid, m_bid=0, m_rid=0;
  logic [ADDR_W-1:0]   m_awaddr, m_araddr;
  logic [DATA_W-1:0]   m_wdata, m_rdata=0;
  logic [7:0]          m_awlen, m_arlen;
  logic [DATA_W/8-1:0] m_wstrb;
  logic [1:0]          m_bresp=0, m_rresp=0;
  logic m_awvalid, m_awready=1, m_wlast, m_wvalid, m_wready=1;
  logic m_bvalid=0, m_bready, m_arvalid, m_arready=1, m_rlast=0, m_rvalid=0, m_rready;

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
  task automatic fail(input string cl, input string msg);
    n_fail = n_fail + 1;
    if (n_fail <= 40) $display("FAIL [%s] %s (t=%0t)", cl, msg, $time);
  endtask

  // ---- THE CONTRACT MODEL --------------------------------------------------
  int unsigned live_r [NID];          // A5: outstanding reads per slave id
  int unsigned live_w [NID];
  int unsigned addr_q [NID][$];       // B1: accepted read addrs, per id, in order
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

  int unsigned n_ar=0, n_mar=0, n_r=0;
  int unsigned cov_full_new=0, cov_full_same=0, cov_depth=0, cov_retire=0, cov_mixed=0;

  // master-side slave model, responds in the order it received per master id
  int unsigned mq [$];
  logic reply_en = 0;
  always @(posedge clk) if (rst_n && m_arvalid && m_arready) begin
    // D1: this master id must not already belong to a DIFFERENT live slave id
    n_mar++;
    mq.push_back(m_arid);
  end
  always_comb begin
    m_rvalid = reply_en && (mq.size() > 0);
    m_rid    = (mq.size() > 0) ? MST_ID_W'(mq[0]) : '0;
    m_rdata  = 32'hC0DE_0000 + ((mq.size() > 0) ? mq[0] : 0);
    m_rlast  = 1'b1;
    m_rresp  = 2'b00;
  end
  always @(posedge clk) if (rst_n && m_rvalid && m_rready) void'(mq.pop_front());

  assign m_awready = 1'b1;
  assign m_wready  = 1'b1;

  // ---- model updates + checks ---------------------------------------------
  always @(posedge clk) begin
    if (!rst_n) begin
      for (int i = 0; i < NID; i++) begin
        live_r[i] <= 0; live_w[i] <= 0; addr_q[i].delete(); map_valid[i] <= 1'b0;
      end
      for (int i = 0; i < (1<<MST_ID_W); i++) owner_valid[i] <= 1'b0;
    end else begin
      if (s_arvalid && s_arready) begin
        live_r[s_arid] <= live_r[s_arid] + 1;
        addr_q[s_arid].push_back(s_araddr);
        n_ar++;
      end
      // D1: a master id may serve only one live slave id at a time
      if (m_arvalid && m_arready) begin
        if (owner_valid[m_arid] && owner_of[m_arid] != s_arid_at_mar)
          fail("D1", $sformatf("master id %0d serves slave id %0d and %0d at once",
                               m_arid, owner_of[m_arid], s_arid_at_mar));
      end
      if (s_rvalid && s_rready && s_rlast) begin
        // C2: a response must belong to an outstanding transaction
        if (live_r[s_rid] == 0)
          fail("C2", $sformatf("read response for slave id %0d with none outstanding", s_rid));
        else begin
          live_r[s_rid] <= live_r[s_rid] - 1;
          void'(addr_q[s_rid].pop_front());     // B1: consume in acceptance order
        end
        n_r++;
      end
    end
  end
  // the slave id whose master request is being issued -- tracked for D1
  int unsigned s_arid_at_mar = 0;
  always @(posedge clk) if (rst_n && s_arvalid && s_arready) s_arid_at_mar <= s_arid;

  // ---- driver --------------------------------------------------------------
  // Offers a read and reports whether it was accepted within `budget`.
  task automatic offer_ar(input int unsigned id, input int budget, output bit acc, output int took);
    acc = 0; took = 0;
    @(negedge clk); s_arvalid = 1; s_arid = id[SLV_ID_W-1:0];
    s_araddr = 32'h1000 + (id << 8) + n_ar; s_arlen = 0;
    while (took < budget) begin
      @(posedge clk);
      if (s_arready) begin acc = 1; break; end
      took++;
    end
    @(negedge clk) s_arvalid = 0;
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
    end
    drain(80);

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

    if (cov_full_new < 2)  fail("FLOOR", "the table boundary was not exercised from both sides");
    if (cov_full_same < 1) fail("FLOOR", "a same-id request at a full table was never offered");
    if (cov_depth < 2)     fail("FLOOR", "the per-id depth boundary was not exercised from both sides");
    if (cov_retire < 1)    fail("FLOOR", "the retirement window was never measured");
    if (cov_mixed < 1)     fail("FLOOR", "reads and writes were never mixed at the boundary");

    $display("METRIC: reads accepted %0d, master reads %0d, responses %0d", n_ar, n_mar, n_r);
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
