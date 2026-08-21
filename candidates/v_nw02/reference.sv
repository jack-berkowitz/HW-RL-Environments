// Reference testbench for v_nw02 atop_filter. Scoring reference, not shipped.
//
// It carries a MODEL, not a scoreboard of recorded waveforms: which writes are
// filtered, what each one owes on B and on R, which W beats may reach the
// master port, and the downstream write debt of clause W1. The model is built
// from the stimulus alone and never reads a DUT internal, so it is capable of
// being wrong in a way a recorded trace could not be.
//
// It deliberately does NOT require an order between a manufactured B and the
// manufactured R beats (clause L1), nor any value on their data/user fields
// (clause L2).
module atop_filter_tb;
  localparam int MAXW = 4;          // clause W2, spec section 0
  localparam int RESP_DEADLINE = 64; // clause X4
  localparam int BLAG = 20;         // downstream B lag: > any legal debt-free delay

  int errors = 0;
  task automatic fail(input string clause, input string detail);
    if (errors < 24) $display("FAIL %s: %s", clause, detail);
    errors++;
  endtask

  logic clk = 1'b0, rst_n = 1'b0;
  always #5 clk = ~clk;
  int cyc = 0;
  always @(posedge clk) if (rst_n) cyc <= cyc + 1;

  // ---- DUT signals -----------------------------------------------------------
  logic [3:0] s_awid; logic [31:0] s_awaddr; logic [7:0] s_awlen; logic [2:0] s_awsize;
  logic [1:0] s_awburst; logic s_awlock; logic [3:0] s_awcache; logic [2:0] s_awprot;
  logic [3:0] s_awqos, s_awregion; logic [5:0] s_awatop; logic s_awuser, s_awvalid, s_awready;
  logic [31:0] s_wdata; logic [3:0] s_wstrb; logic s_wlast, s_wuser, s_wvalid, s_wready;
  logic [3:0] s_bid; logic [1:0] s_bresp; logic s_buser, s_bvalid, s_bready;
  logic [3:0] s_arid; logic [31:0] s_araddr; logic [7:0] s_arlen; logic [2:0] s_arsize;
  logic [1:0] s_arburst; logic s_arlock; logic [3:0] s_arcache; logic [2:0] s_arprot;
  logic [3:0] s_arqos, s_arregion; logic s_aruser, s_arvalid, s_arready;
  logic [3:0] s_rid; logic [31:0] s_rdata; logic [1:0] s_rresp; logic s_rlast, s_ruser;
  logic s_rvalid, s_rready;
  logic [3:0] m_awid; logic [31:0] m_awaddr; logic [7:0] m_awlen; logic [2:0] m_awsize;
  logic [1:0] m_awburst; logic m_awlock; logic [3:0] m_awcache; logic [2:0] m_awprot;
  logic [3:0] m_awqos, m_awregion; logic [5:0] m_awatop; logic m_awuser, m_awvalid, m_awready;
  logic [31:0] m_wdata; logic [3:0] m_wstrb; logic m_wlast, m_wuser, m_wvalid, m_wready;
  logic [3:0] m_bid; logic [1:0] m_bresp; logic m_buser, m_bvalid, m_bready;
  logic [3:0] m_arid; logic [31:0] m_araddr; logic [7:0] m_arlen; logic [2:0] m_arsize;
  logic [1:0] m_arburst; logic m_arlock; logic [3:0] m_arcache; logic [2:0] m_arprot;
  logic [3:0] m_arqos, m_arregion; logic m_aruser, m_arvalid, m_arready;
  logic [3:0] m_rid; logic [31:0] m_rdata; logic [1:0] m_rresp; logic m_rlast, m_ruser;
  logic m_rvalid, m_rready;

  atop_filter #(.ID_W(4), .ADDR_W(32), .DATA_W(32), .USER_W(1)) dut (
    .clk_i(clk), .rst_ni(rst_n),
    .s_awid_i(s_awid), .s_awaddr_i(s_awaddr), .s_awlen_i(s_awlen), .s_awsize_i(s_awsize),
    .s_awburst_i(s_awburst), .s_awlock_i(s_awlock), .s_awcache_i(s_awcache),
    .s_awprot_i(s_awprot), .s_awqos_i(s_awqos), .s_awregion_i(s_awregion),
    .s_awatop_i(s_awatop), .s_awuser_i(s_awuser), .s_awvalid_i(s_awvalid), .s_awready_o(s_awready),
    .s_wdata_i(s_wdata), .s_wstrb_i(s_wstrb), .s_wlast_i(s_wlast), .s_wuser_i(s_wuser),
    .s_wvalid_i(s_wvalid), .s_wready_o(s_wready),
    .s_bid_o(s_bid), .s_bresp_o(s_bresp), .s_buser_o(s_buser), .s_bvalid_o(s_bvalid),
    .s_bready_i(s_bready),
    .s_arid_i(s_arid), .s_araddr_i(s_araddr), .s_arlen_i(s_arlen), .s_arsize_i(s_arsize),
    .s_arburst_i(s_arburst), .s_arlock_i(s_arlock), .s_arcache_i(s_arcache),
    .s_arprot_i(s_arprot), .s_arqos_i(s_arqos), .s_arregion_i(s_arregion),
    .s_aruser_i(s_aruser), .s_arvalid_i(s_arvalid), .s_arready_o(s_arready),
    .s_rid_o(s_rid), .s_rdata_o(s_rdata), .s_rresp_o(s_rresp), .s_rlast_o(s_rlast),
    .s_ruser_o(s_ruser), .s_rvalid_o(s_rvalid), .s_rready_i(s_rready),
    .m_awid_o(m_awid), .m_awaddr_o(m_awaddr), .m_awlen_o(m_awlen), .m_awsize_o(m_awsize),
    .m_awburst_o(m_awburst), .m_awlock_o(m_awlock), .m_awcache_o(m_awcache),
    .m_awprot_o(m_awprot), .m_awqos_o(m_awqos), .m_awregion_o(m_awregion),
    .m_awatop_o(m_awatop), .m_awuser_o(m_awuser), .m_awvalid_o(m_awvalid), .m_awready_i(m_awready),
    .m_wdata_o(m_wdata), .m_wstrb_o(m_wstrb), .m_wlast_o(m_wlast), .m_wuser_o(m_wuser),
    .m_wvalid_o(m_wvalid), .m_wready_i(m_wready),
    .m_bid_i(m_bid), .m_bresp_i(m_bresp), .m_buser_i(m_buser), .m_bvalid_i(m_bvalid),
    .m_bready_o(m_bready),
    .m_arid_o(m_arid), .m_araddr_o(m_araddr), .m_arlen_o(m_arlen), .m_arsize_o(m_arsize),
    .m_arburst_o(m_arburst), .m_arlock_o(m_arlock), .m_arcache_o(m_arcache),
    .m_arprot_o(m_arprot), .m_arqos_o(m_arqos), .m_arregion_o(m_arregion),
    .m_aruser_o(m_aruser), .m_arvalid_o(m_arvalid), .m_arready_i(m_arready),
    .m_rid_i(m_rid), .m_rdata_i(m_rdata), .m_rresp_i(m_rresp), .m_rlast_i(m_rlast),
    .m_ruser_i(m_ruser), .m_rvalid_i(m_rvalid), .m_rready_o(m_rready));

  // =========================== THE MODEL ======================================
  // Expected forwarded AW (non-atomic writes only), in issue order.
  int fa_id [$], fa_addr [$], fa_len [$];
  // Expected forwarded W beats, in issue order.
  int fw_data [$], fw_strb [$]; bit fw_last [$];
  // Expected upstream B: manufactured (SLVERR) and forwarded, matched by id+resp.
  int eb_id [$]; int eb_resp [$]; int eb_due [$]; bit eb_made [$];
  // Expected upstream R beats, per id, in order.
  int er_id [$]; int er_resp [$]; bit er_last [$]; int er_due [$]; bit er_made [$];
  int debt = 0, peak_debt = 0;
  int n_maw = 0, n_mwlast = 0;
  // COVERAGE COUNTERS -- these count STIMULUS, never DUT responses. A counter
  // the DUT can suppress lets a faulty design fail the floor instead of the
  // clause it actually violates, and the defect is then misattributed.
  int cov_nonatomic = 0, cov_store = 0, cov_load = 0, cov_multibeat = 0, cov_wbeats = 0;
  bit cov_backpressure = 0, cov_reset = 0, cov_filled_bound = 0;
  bit checking = 1'b1;

  // ---- master-port checker: P1, P2, F1, F2, W1, W2 ---------------------------
  always @(posedge clk) if (rst_n && checking) begin
    if (m_awvalid && m_awready) begin
      n_maw++; debt++;
      if (debt > peak_debt) peak_debt = debt;
      if (debt > MAXW)
        fail("W2", $sformatf("downstream write debt reached %0d, bound is %0d (cycle %0d)",
                             debt, MAXW, cyc));
      if (m_awatop != 6'b000000)
        fail("F1", $sformatf("forwarded AW carries atop=%b, must be zero (cycle %0d)", m_awatop, cyc));
      if (fa_id.size() == 0)
        fail("F1/F2", $sformatf("an AW reached the master port that no non-atomic write asked for -- id=%0d (cycle %0d)", m_awid, cyc));
      else begin
        if (int'(m_awid) != fa_id[0] || int'(m_awaddr) != fa_addr[0] || int'(m_awlen) != fa_len[0])
          fail("P1", $sformatf("forwarded AW altered: got id=%0d addr=%08x len=%0d, expected id=%0d addr=%08x len=%0d",
                               m_awid, m_awaddr, m_awlen, fa_id[0], fa_addr[0], fa_len[0]));
        void'(fa_id.pop_front()); void'(fa_addr.pop_front()); void'(fa_len.pop_front());
      end
    end
    if (m_wvalid && m_wready) begin
      if (m_wlast) begin
        n_mwlast++;
        debt--;
      end
      if (fw_data.size() == 0)
        fail("F2", $sformatf("a W beat reached the master port that belongs to no forwarded write -- data=%08x (cycle %0d). The W beats of a filtered write must be absorbed.", m_wdata, cyc));
      else begin
        if (int'(m_wdata) != fw_data[0] || int'(m_wstrb) != fw_strb[0] || m_wlast !== fw_last[0])
          fail("P2", $sformatf("forwarded W beat altered: got data=%08x strb=%h last=%b, expected data=%08x strb=%h last=%b",
                               m_wdata, m_wstrb, m_wlast, fw_data[0], fw_strb[0], fw_last[0]));
        void'(fw_data.pop_front()); void'(fw_strb.pop_front()); void'(fw_last.pop_front());
      end
    end
  end

  // ---- upstream B checker: F3, P4, X4 ---------------------------------------
  always @(posedge clk) if (rst_n && checking && s_bvalid && s_bready) begin
    int k; bit found;
    found = 1'b0;
    for (k = 0; k < eb_id.size(); k++)
      if (eb_id[k] == int'(s_bid) && eb_resp[k] == int'(s_bresp)) begin found = 1'b1; break; end
    if (!found) begin
      if (eb_id.size() == 0)
        fail("F3", $sformatf("a B arrived that nothing is owed -- id=%0d resp=%b (cycle %0d)", s_bid, s_bresp, cyc));
      else
        fail("F3", $sformatf("B mismatch: got id=%0d resp=%b; oldest outstanding expects id=%0d resp=%b (cycle %0d)",
                             s_bid, s_bresp, eb_id[0], eb_resp[0][1:0], cyc));
      // consume the oldest so one defect does not cascade into every later beat
      void'(eb_id.pop_front()); void'(eb_resp.pop_front()); void'(eb_due.pop_front()); void'(eb_made.pop_front());
    end else begin
      if (eb_made[k] && cyc > eb_due[k])
        fail("X4", $sformatf("manufactured B for id=%0d arrived at cycle %0d, deadline was %0d", s_bid, cyc, eb_due[k]));
      eb_id.delete(k); eb_resp.delete(k); eb_due.delete(k); eb_made.delete(k);
    end
  end

  // ---- upstream R checker: F4, F5, P3, X4 -----------------------------------
  always @(posedge clk) if (rst_n && checking && s_rvalid && s_rready) begin
    int k; bit found;
    found = 1'b0;
    for (k = 0; k < er_id.size(); k++) if (er_id[k] == int'(s_rid)) begin found = 1'b1; break; end
    if (!found) begin
      fail("F4/F5", $sformatf("an R beat arrived for id=%0d that nothing is owed -- resp=%b last=%b (cycle %0d). A write that owes no read response must produce no R beats, and a burst must not run past awlen+1 beats.",
                              s_rid, s_rresp, s_rlast, cyc));
    end else begin
      if (int'(s_rresp) != er_resp[k])
        fail("F4", $sformatf("R beat for id=%0d carries resp=%b, expected %b (cycle %0d)",
                             s_rid, s_rresp, er_resp[k][1:0], cyc));
      if (s_rlast !== er_last[k])
        fail("F4", $sformatf("R beat for id=%0d has last=%b, expected %b -- rlast belongs on the final beat and on no other (cycle %0d)",
                             s_rid, s_rlast, er_last[k], cyc));
      if (er_made[k] && cyc > er_due[k])
        fail("X4", $sformatf("manufactured R beat for id=%0d arrived at cycle %0d, deadline was %0d", s_rid, cyc, er_due[k]));
      er_id.delete(k); er_resp.delete(k); er_last.delete(k); er_due.delete(k); er_made.delete(k);
    end
  end

  // ---- X3: valid must not drop before ready ---------------------------------
  logic pv_b = 0, pv_r = 0, pv_maw = 0, pv_mw = 0;
  logic [6:0]  pb; logic [39:0] pr;
  always @(posedge clk) if (rst_n && checking) begin
    if (pv_b && !s_bvalid) fail("X3", $sformatf("s_bvalid dropped without a handshake (cycle %0d)", cyc));
    if (pv_r && !s_rvalid) fail("X3", $sformatf("s_rvalid dropped without a handshake (cycle %0d)", cyc));
    if (pv_maw && !m_awvalid) fail("X3", $sformatf("m_awvalid dropped without a handshake (cycle %0d)", cyc));
    if (pv_mw && !m_wvalid) fail("X3", $sformatf("m_wvalid dropped without a handshake (cycle %0d)", cyc));
    pv_b   <= s_bvalid  && !s_bready;
    pv_r   <= s_rvalid  && !s_rready;
    pv_maw <= m_awvalid && !m_awready;
    pv_mw  <= m_wvalid  && !m_wready;
  end

  // ---- X1: nothing asserted while reset is low ------------------------------
  always @(posedge clk) if (!rst_n) begin
    if (s_bvalid || s_rvalid || m_awvalid || m_wvalid || m_arvalid)
      fail("X1", "an output valid is asserted while rst_ni is low");
  end

  // =============== downstream responder (the TB is the subordinate) ===========
  // B is returned a long lag AFTER the AW, so that a debt freed by a completed
  // W burst is distinguishable from a debt freed by a B arriving (clause W4).
  int dq_id [$], dq_t [$];
  int rq_id [$], rq_n [$];
  assign m_awready = 1'b1;
  assign m_wready  = 1'b1;
  assign m_arready = 1'b1;
  always @(posedge clk) if (rst_n) begin
    if (m_awvalid && m_awready) begin dq_id.push_back(int'(m_awid)); dq_t.push_back(cyc + BLAG); end
    if (m_arvalid && m_arready) begin rq_id.push_back(int'(m_arid)); rq_n.push_back(int'(m_arlen) + 1); end
    if (m_bvalid && m_bready) begin void'(dq_id.pop_front()); void'(dq_t.pop_front()); end
    if (m_rvalid && m_rready) begin
      if (rq_n[0] <= 1) begin void'(rq_id.pop_front()); void'(rq_n.pop_front()); end
      else rq_n[0] = rq_n[0] - 1;
    end
  end
  always_comb begin
    m_bvalid = (dq_id.size() > 0) && (cyc >= dq_t[0]);
    m_bid = 4'(dq_id.size() ? dq_id[0] : 0); m_bresp = 2'b00; m_buser = 1'b0;
    m_rvalid = (rq_id.size() > 0);
    m_rid = 4'(rq_id.size() ? rq_id[0] : 0);
    m_rdata = 32'hFEED_0000 + 32'(rq_id.size()); m_rresp = 2'b00; m_ruser = 1'b0;
    m_rlast = (rq_id.size() > 0) && (rq_n[0] <= 1);
  end
  // The forwarded B and R expectations are raised by the STIMULUS, at issue
  // time, not by this responder's handshakes. A forwarded B is combinational in
  // the master-port B, so the two handshakes land in the same cycle and pushing
  // an expectation there races the checker that consumes it.

  // =============== stimulus ===================================================
  int wdata_ctr = 0;

  task automatic try_aw(input int id, input int addr, input int len, input logic [5:0] atop,
                        input int timeout, output bit accepted);
    int t, n_fa, n_eb, n_er;
    // Raise every expectation FIRST. The design may forward this AW in the same
    // cycle it accepts it, and a model updated afterwards is a cycle behind the
    // thing it is checking.
    n_fa = 0; n_eb = 0; n_er = 0;
    if (atop[5:4] == 2'b00) begin
      fa_id.push_back(id); fa_addr.push_back(addr); fa_len.push_back(len); n_fa = 1;
      // this responder answers every forwarded write with OKAY, after BLAG
      eb_id.push_back(id); eb_resp.push_back(2'b00);
      eb_due.push_back(0); eb_made.push_back(1'b0); n_eb = 1;
    end else begin
      eb_id.push_back(id); eb_resp.push_back(2'b10);
      eb_due.push_back(cyc + RESP_DEADLINE + 8*(len+1)); eb_made.push_back(1'b1); n_eb = 1;
      if (atop[5]) for (int b = 0; b <= len; b++) begin
        er_id.push_back(id); er_resp.push_back(2'b10); er_last.push_back(b == len);
        er_due.push_back(cyc + RESP_DEADLINE + 8*(len+1)); er_made.push_back(1'b1); n_er++;
      end
    end
    if (atop[5:4] == 2'b00) cov_nonatomic++;
    else begin
      if (atop[5]) cov_load++; else cov_store++;
      if (len > 0) cov_multibeat++;
    end
    @(negedge clk);
    s_awid = 4'(id); s_awaddr = 32'(addr); s_awlen = 8'(len); s_awatop = atop; s_awvalid = 1'b1;
    accepted = 1'b0;
    for (t = 0; t < timeout; t++) begin
      @(posedge clk);
      if (s_awready) begin accepted = 1'b1; break; end
    end
    @(negedge clk) s_awvalid = 1'b0;
    if (!accepted) begin
      // nothing was accepted, so nothing this call queued can have been
      // consumed; the entries are still the newest in each queue.
      repeat (n_fa) begin void'(fa_id.pop_back()); void'(fa_addr.pop_back()); void'(fa_len.pop_back()); end
      repeat (n_eb) begin void'(eb_id.pop_back()); void'(eb_resp.pop_back()); void'(eb_due.pop_back()); void'(eb_made.pop_back()); end
      repeat (n_er) begin void'(er_id.pop_back()); void'(er_resp.pop_back()); void'(er_last.pop_back()); void'(er_due.pop_back()); void'(er_made.pop_back()); end
    end
  endtask

  task automatic issue_aw(input int id, input int addr, input int len, input logic [5:0] atop);
    bit ok;
    try_aw(id, addr, len, atop, 4000, ok);
    if (!ok) fail("W3/X4", $sformatf("AW id=%0d was never accepted (cycle %0d)", id, cyc));
  endtask

  // Sends a W burst. `filtered` says whether these beats belong to a filtered
  // write, in which case they must NOT appear on the master port.
  task automatic send_w(input int n, input bit filtered);
    for (int i = 0; i < n; i++) begin
      wdata_ctr++; cov_wbeats++;
      @(negedge clk);
      s_wdata = 32'hC0DE_0000 + 32'(wdata_ctr); s_wstrb = 4'hF;
      s_wlast = (i == n - 1); s_wvalid = 1'b1;
      if (!filtered) begin
        fw_data.push_back(int'(32'hC0DE_0000 + 32'(wdata_ctr)));
        fw_strb.push_back(4'hF); fw_last.push_back(i == n - 1);
      end
      begin
        bit took; int t;
        took = 1'b0;
        // BOUNDED. An unbounded wait here turns a design that never accepts a W
        // beat into a hang, and a hang diagnoses nothing: the verdict names the
        // watchdog rather than the clause that was actually broken.
        for (t = 0; t < RESP_DEADLINE; t++) begin
          @(posedge clk);
          if (s_wready) begin took = 1'b1; break; end
        end
        if (!took) begin
          fail("X4", $sformatf("a W beat was offered for %0d cycles and never accepted (cycle %0d). Every W beat of a write already admitted must be consumed -- forwarded or absorbed.", RESP_DEADLINE, cyc));
          @(negedge clk) s_wvalid = 1'b0;
          return;
        end
      end
      @(negedge clk) s_wvalid = 1'b0;
    end
  endtask

  task automatic issue_ar(input int id, input int addr, input int len);
    for (int b = 0; b <= len; b++) begin
      er_id.push_back(id); er_resp.push_back(2'b00); er_last.push_back(b == len);
      er_due.push_back(0); er_made.push_back(1'b0);
    end
    @(negedge clk);
    s_arid = 4'(id); s_araddr = 32'(addr); s_arlen = 8'(len); s_arvalid = 1'b1;
    begin
      bit took; int t;
      took = 1'b0;
      for (t = 0; t < RESP_DEADLINE; t++) begin
        @(posedge clk);
        if (s_arready) begin took = 1'b1; break; end
      end
      if (!took) fail("P3/X4", $sformatf("an AR was offered for %0d cycles and never accepted (cycle %0d); the read path is never filtered and must not be blocked", RESP_DEADLINE, cyc));
    end
    @(negedge clk) s_arvalid = 1'b0;
  endtask

  task automatic settle(input int n);
    repeat (n) @(posedge clk);
  endtask

  task automatic expect_quiet(input string clause, input string what);
    if (eb_id.size() != 0)
      fail(clause, $sformatf("%s: %0d B response(s) still owed, oldest id=%0d", what, eb_id.size(), eb_id[0]));
    if (er_id.size() != 0)
      fail(clause, $sformatf("%s: %0d R beat(s) still owed, oldest id=%0d", what, er_id.size(), er_id[0]));
    if (fa_id.size() != 0)
      fail(clause, $sformatf("%s: %0d AW(s) never reached the master port", what, fa_id.size()));
    if (fw_data.size() != 0)
      fail(clause, $sformatf("%s: %0d W beat(s) never reached the master port", what, fw_data.size()));
  endtask

  initial begin
    s_awid=0; s_awaddr=0; s_awlen=0; s_awsize=3'd2; s_awburst=2'd1; s_awlock=0;
    s_awcache=0; s_awprot=0; s_awqos=0; s_awregion=0; s_awatop=0; s_awuser=0; s_awvalid=0;
    s_wdata=0; s_wstrb=4'hF; s_wlast=0; s_wuser=0; s_wvalid=0; s_bready=1;
    s_arid=0; s_araddr=0; s_arlen=0; s_arsize=3'd2; s_arburst=2'd1; s_arlock=0;
    s_arcache=0; s_arprot=0; s_arqos=0; s_arregion=0; s_aruser=0; s_arvalid=0; s_rready=1;

    repeat (5) @(posedge clk);
    @(negedge clk) rst_n = 1'b1;
    settle(2);

    // -- 1. an ordinary write passes through, and its B comes back ------------
    issue_aw(1, 32'h1000, 0, 6'b000000); send_w(1, 1'b0); settle(40);
    expect_quiet("P1/P2/P4", "after one ordinary write");

    // -- 2. an atomic store: filtered, one SLVERR B, and NO R beats -----------
    issue_aw(2, 32'h1100, 0, 6'b010000); send_w(1, 1'b1); settle(40);
    expect_quiet("F2/F3/F5", "after one atomic store");

    // -- 3. an atomic load, single beat, then a four-beat one -----------------
    issue_aw(3, 32'h1200, 0, 6'b100000); send_w(1, 1'b1); settle(40);
    issue_aw(4, 32'h1300, 3, 6'b100000); send_w(4, 1'b1); settle(60);
    expect_quiet("F3/F4", "after two atomic loads");

    // -- 4. two atomic loads with DIFFERENT ids, back to back -----------------
    issue_aw(9, 32'h1400, 1, 6'b100000); send_w(2, 1'b1); settle(40);
    issue_aw(5, 32'h1500, 1, 6'b100000); send_w(2, 1'b1); settle(40);
    expect_quiet("F3/F4", "after two atomic loads with different ids");

    // -- 5. the bound. Fill it with W beats withheld, and prove a slot is
    //       freed by a COMPLETED W BURST and not by a B arriving. ------------
    begin
      bit ok; int admitted;
      admitted = 0; cov_filled_bound = 1'b1;
      for (int i = 0; i < MAXW + 2; i++) begin
        try_aw(i, 32'h2000 + i*16, 0, 6'b000000, 40, ok);
        if (ok) admitted++;
      end
      if (admitted != MAXW)
        fail("W2/W3", $sformatf("with no W burst completed downstream, %0d AWs were admitted; the bound is %0d",
                                admitted, MAXW));
      // No B has been returned yet (BLAG=20 from each AW, and none has been
      // acknowledged upstream). Complete ONE W burst and require a slot to free.
      send_w(1, 1'b0);
      try_aw(12, 32'h2900, 0, 6'b000000, RESP_DEADLINE, ok);
      if (!ok)
        fail("W4", "after one W burst completed on the master port, no further AW was admitted -- the debt is freed by a completed W burst, not by a B response");
      else admitted++;
      // drain
      for (int i = 0; i < admitted - 1; i++) send_w(1, 1'b0);
      settle(120);
      expect_quiet("W1/W4", "after draining the bound test");
    end

    // -- 6. reads pass through untouched, alongside a filtered atomic ---------
    issue_ar(7, 32'h3000, 1); settle(20);
    issue_aw(8, 32'h3100, 2, 6'b110000); send_w(3, 1'b1); settle(60);
    expect_quiet("P3/F4", "after a read alongside an atomic load");

    // -- 7. backpressure: hold both response channels off, then release ------
    cov_backpressure = 1'b1;
    @(negedge clk) s_bready = 1'b0; s_rready = 1'b0;
    issue_aw(6, 32'h4000, 2, 6'b100000); send_w(3, 1'b1);
    settle(30);
    @(negedge clk) s_bready = 1'b1; s_rready = 1'b1;
    settle(80);
    expect_quiet("F3/F4/X3", "after backpressure on both response channels");

    // -- 8. an atomic store and an atomic load distinguished by bit 5 only ----
    issue_aw(10, 32'h5000, 2, 6'b010000); send_w(3, 1'b1); settle(60);
    expect_quiet("F5", "after a multi-beat atomic STORE, which owes no R beats");
    issue_aw(11, 32'h5100, 2, 6'b100000); send_w(3, 1'b1); settle(60);
    expect_quiet("F4", "after a multi-beat atomic LOAD");

    // -- 9. mid-stream reset ---------------------------------------------------
    cov_reset = 1'b1;
    checking = 1'b0;
    @(negedge clk) rst_n = 1'b0;
    repeat (6) @(posedge clk);
    @(negedge clk) rst_n = 1'b1;
    settle(4);
    fa_id.delete(); fa_addr.delete(); fa_len.delete();
    fw_data.delete(); fw_strb.delete(); fw_last.delete();
    eb_id.delete(); eb_resp.delete(); eb_due.delete(); eb_made.delete();
    er_id.delete(); er_resp.delete(); er_last.delete(); er_due.delete(); er_made.delete();
    dq_id.delete(); dq_t.delete(); rq_id.delete(); rq_n.delete();
    checking = 1'b1;
    issue_aw(13, 32'h6000, 1, 6'b100000); send_w(2, 1'b1); settle(60);
    expect_quiet("X2", "after a mid-stream reset the unit must owe nothing and work normally");

    // Rule 4 floors, on stimulus only.
    if (cov_nonatomic < 6) fail("COVERAGE", $sformatf("only %0d non-atomic writes issued", cov_nonatomic));
    if (cov_store < 2)     fail("COVERAGE", $sformatf("only %0d atomic STOREs issued -- F5 needs writes that owe no R", cov_store));
    if (cov_load < 6)      fail("COVERAGE", $sformatf("only %0d atomic LOADs issued", cov_load));
    if (cov_multibeat < 4) fail("COVERAGE", $sformatf("only %0d multi-beat atomic writes issued -- awlen+1 is untested at awlen=0", cov_multibeat));
    if (cov_wbeats < 20)   fail("COVERAGE", $sformatf("only %0d W beats sent", cov_wbeats));
    if (!cov_backpressure) fail("COVERAGE", "the response channels were never backpressured");
    if (!cov_reset)        fail("COVERAGE", "reset was never asserted mid-stream");
    if (!cov_filled_bound) fail("COVERAGE", "the write bound was never driven to its limit");

    if (errors == 0) $display("RESULT: PASS");
    else $display("RESULT: FAIL (%0d violation%s)", errors, (errors == 1) ? "" : "s");
    $finish;
  end

  initial begin
    #4_000_000;
    $display("RESULT: FAIL (watchdog: no forward progress; %0d violation(s) so far)", errors);
    $finish;
  end
endmodule
