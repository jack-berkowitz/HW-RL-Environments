// Reference testbench for v_nw01 arp_engine. Scoring reference, not shipped.
//
// It carries a MODEL: what the engine has been taught, which address a lookup
// should actually ask for, how many requests it owes and how far apart, and
// what a reply to somebody else's request should contain. Every expected value
// comes from the stimulus and the specification, never from a DUT internal.
//
// Clause L1 leaves the cache's replacement choice free, so the model asserts
// only what C1 and C3 fix: the entry just taught is retrievable, and after a
// clear nothing is.
module arp_engine_tb;

  // VCD on demand, for the rule-34 stimulus-variation check. Guarded by a
  // plusarg so a normal scoring run is byte-for-byte unaffected.
  initial if ($test$plusargs("vcd")) begin
    $dumpfile("dump.vcd");
    $dumpvars(0, arp_engine_tb);
  end
  // VARIABLES, not localparams, and the distinction is the whole point. The spec
  // says these four "are inputs, not constants; hold them steady while the engine
  // is running" -- so a design that hardcodes them is non-conforming, and only
  // these ports can reach that clause.
  //
  // Held constant, the boundary Q3 branches on can be crossed from both sides and
  // STILL not be tested: a design hardcoding /24 and 192.168.1.1 reaches both
  // branches correctly at this configuration. Reaching both branches is not
  // testing that the boundary sits where the configuration says it is.
  //
  // The checker half is why a variation sweep cannot find this on its own. These
  // symbols feed the instantiation AND the expectations, so port and expectation
  // are one symbol: it varies in neither place, and a sweep counting values per
  // port sees a constant with nothing behind it to disagree with.
  logic [47:0] LMAC = 48'h02_00_00_00_00_01;
  logic [31:0] LIP  = 32'hC0A8_0101;      // 192.168.1.1
  logic [31:0] GWIP = 32'hC0A8_01FE;      // 192.168.1.254
  logic [31:0] MASK = 32'hFFFF_FF00;      // /24

  // The second identity, taken up across the mid-stream reset in step 8. The
  // mask WIDTH differs, which is what separates a design reading subnet_mask_i
  // from one that hardcodes /24: 10.0.9.9 is inside 10.0.5.7/16 and outside
  // 10.0.5.7/24, so the two answer Q3 differently for the same lookup.
  localparam logic [47:0] LMAC2 = 48'h02_00_00_00_00_02;
  localparam logic [31:0] LIP2  = 32'h0A00_0507;     // 10.0.5.7
  localparam logic [31:0] GWIP2 = 32'h0A00_0001;     // 10.0.0.1
  localparam logic [31:0] MASK2 = 32'hFFFF_0000;     // /16
  int cov_identities = 1;
  localparam logic [47:0] BCAST = 48'hFF_FF_FF_FF_FF_FF;
  localparam int RETRIES = 4, GAP_LO = 64, GAP_HI = 80;
  localparam int TMO_LO = 256, TMO_HI = 300, HIT_MAX = 32;

  int errors = 0;
  task automatic fail(input string clause, input string detail);
    if (errors < 24) $display("FAIL %s: %s", clause, detail);
    errors++;
  endtask

  logic clk = 1'b0; always #5 clk = ~clk;
  logic rst = 1'b1;
  logic s_hv = 1'b0, s_hr; logic [47:0] s_dm = '0, s_sm = '0; logic [15:0] s_et = '0;
  logic [7:0] s_pd = '0; logic s_pv = 1'b0, s_pr, s_pl = 1'b0, s_pu = 1'b0;
  logic m_hv, m_hr = 1'b1; logic [47:0] m_dm, m_sm; logic [15:0] m_et;
  logic [7:0] m_pd; logic m_pv, m_pr = 1'b1, m_pl, m_pu;
  logic rq_v = 1'b0, rq_r; logic [31:0] rq_ip = '0;
  logic rs_v, rs_r = 1'b1, rs_e; logic [47:0] rs_mac;
  logic clr_cache = 1'b0;

  arp_engine dut (
    .clk_i(clk), .rst_i(rst),
    .s_hdr_valid_i(s_hv), .s_hdr_ready_o(s_hr), .s_dest_mac_i(s_dm),
    .s_src_mac_i(s_sm), .s_eth_type_i(s_et), .s_payload_data_i(s_pd),
    .s_payload_valid_i(s_pv), .s_payload_ready_o(s_pr), .s_payload_last_i(s_pl),
    .s_payload_user_i(s_pu),
    .m_hdr_valid_o(m_hv), .m_hdr_ready_i(m_hr), .m_dest_mac_o(m_dm),
    .m_src_mac_o(m_sm), .m_eth_type_o(m_et), .m_payload_data_o(m_pd),
    .m_payload_valid_o(m_pv), .m_payload_ready_i(m_pr), .m_payload_last_o(m_pl),
    .m_payload_user_o(m_pu),
    .req_valid_i(rq_v), .req_ready_o(rq_r), .req_ip_i(rq_ip),
    .resp_valid_o(rs_v), .resp_ready_i(rs_r), .resp_error_o(rs_e), .resp_mac_o(rs_mac),
    .local_mac_i(LMAC), .local_ip_i(LIP), .gateway_ip_i(GWIP), .subnet_mask_i(MASK),
    .clear_cache_i(clr_cache));

  int cyc = 0; always @(posedge clk) if (!rst) cyc <= cyc + 1;

  // ---------------- transmit monitor: decode every frame the engine sends --
  typedef struct packed {
    logic [47:0] dest_mac, src_mac; logic [15:0] eth_type;
    logic [15:0] htype, ptype, oper; logic [7:0] hlen, plen;
    logic [47:0] sha, tha; logic [31:0] spa, tpa; int at;
  } frame_t;

  frame_t txq [$];
  logic [7:0] txbuf [$];
  logic [47:0] pend_dm, pend_sm; logic [15:0] pend_et; int pend_at;
  bit have_hdr = 1'b0;

  always @(posedge clk) if (!rst) begin
    if (m_hv && m_hr) begin
      pend_dm = m_dm; pend_sm = m_sm; pend_et = m_et; pend_at = cyc; have_hdr = 1'b1;
    end
    if (m_pv && m_pr) begin
      txbuf.push_back(m_pd);
      if (m_pl) begin
        automatic frame_t f;
        if (txbuf.size() != 28)
          fail("F", $sformatf("cycle %0d: a transmitted ARP payload was %0d bytes, not 28",
                              cyc, txbuf.size()));
        else begin
          f.dest_mac = pend_dm; f.src_mac = pend_sm; f.eth_type = pend_et; f.at = pend_at;
          f.htype = {txbuf[0], txbuf[1]};  f.ptype = {txbuf[2], txbuf[3]};
          f.hlen  = txbuf[4];              f.plen  = txbuf[5];
          f.oper  = {txbuf[6], txbuf[7]};
          f.sha   = {txbuf[8],  txbuf[9],  txbuf[10], txbuf[11], txbuf[12], txbuf[13]};
          f.spa   = {txbuf[14], txbuf[15], txbuf[16], txbuf[17]};
          f.tha   = {txbuf[18], txbuf[19], txbuf[20], txbuf[21], txbuf[22], txbuf[23]};
          f.tpa   = {txbuf[24], txbuf[25], txbuf[26], txbuf[27]};
          txq.push_back(f);
        end
        txbuf.delete(); have_hdr = 1'b0;
      end
    end
  end

  always @(posedge clk) if (rst && (m_hv || m_pv || rs_v))
    fail("X1", "an output valid is asserted while rst_i is high");

  // ---------------- the model ----------------
  logic [47:0] known [logic [31:0]];   // what the engine has been taught
  int cov_lookups = 0, cov_hits = 0, cov_misses = 0, cov_replies_in = 0;
  int cov_requests_in = 0, cov_timeouts = 0;
  bit cov_offsubnet = 0, cov_clear = 0, cov_reset = 0, cov_nonarp = 0, cov_notforus = 0;
  bit cov_second_timeout = 0, cov_busy_request = 0;

  function automatic logic [31:0] asked_for(input logic [31:0] ip);
    return ((ip & MASK) == (LIP & MASK)) ? ip : GWIP;   // clause Q3
  endfunction

  // ---------------- stimulus helpers ----------------
  task automatic send_frame(input logic [15:0] oper, input logic [47:0] sha,
                            input logic [31:0] spa, input logic [47:0] tha,
                            input logic [31:0] tpa, input logic [15:0] ethtype = 16'h0806);
    logic [7:0] p [28];
    p[0]=8'h00; p[1]=8'h01; p[2]=8'h08; p[3]=8'h00; p[4]=8'd6; p[5]=8'd4;
    p[6]=oper[15:8]; p[7]=oper[7:0];
    for (int i=0;i<6;i++) p[8+i]  = sha[47-8*i -: 8];
    for (int i=0;i<4;i++) p[14+i] = spa[31-8*i -: 8];
    for (int i=0;i<6;i++) p[18+i] = tha[47-8*i -: 8];
    for (int i=0;i<4;i++) p[24+i] = tpa[31-8*i -: 8];
    // BOUNDED. An unbounded wait here turns a design that never accepts a
    // frame into a hang, and a hang diagnoses nothing -- the verdict then names
    // the watchdog rather than the clause that was broken.
    @(negedge clk); s_dm = LMAC; s_sm = sha; s_et = ethtype; s_hv = 1'b1;
    begin
      bit took = 1'b0;
      for (int t = 0; t < HIT_MAX; t++) begin @(posedge clk); if (s_hr) begin took = 1'b1; break; end end
      if (!took) begin
        fail("X3", $sformatf("a frame header was offered for %0d cycles and never accepted", HIT_MAX));
        @(negedge clk) s_hv = 1'b0;
        return;
      end
    end
    @(negedge clk) s_hv = 1'b0;
    for (int i=0;i<28;i++) begin
      bit took = 1'b0;
      @(negedge clk); s_pd = p[i]; s_pl = (i==27); s_pv = 1'b1;
      for (int t = 0; t < HIT_MAX; t++) begin @(posedge clk); if (s_pr) begin took = 1'b1; break; end end
      if (!took) begin
        fail("X3", $sformatf("payload byte %0d was offered for %0d cycles and never accepted", i, HIT_MAX));
        @(negedge clk) s_pv = 1'b0; s_pl = 1'b0;
        return;
      end
      @(negedge clk) s_pv = 1'b0; s_pl = 1'b0;
    end
    if (ethtype == 16'h0806) known[spa] = sha;          // clause C1
  endtask

  task automatic start_lookup(input logic [31:0] ip);
    @(negedge clk); rq_ip = ip; rq_v = 1'b1;
    begin
      bit took = 1'b0;
      for (int t = 0; t < HIT_MAX; t++) begin @(posedge clk); if (rq_r) begin took = 1'b1; break; end end
      if (!took)
        fail("X3", $sformatf("a lookup was offered for %0d cycles and never accepted", HIT_MAX));
    end
    @(negedge clk) rq_v = 1'b0;
    cov_lookups++;
  endtask

  task automatic await_response(input int limit, output bit got, output bit err,
                                output logic [47:0] mac, output int took);
    got = 1'b0; err = 1'b0; mac = '0; took = 0;
    for (int t = 0; t < limit; t++) begin
      @(posedge clk);
      took = t;
      if (rs_v) begin got = 1'b1; err = rs_e; mac = rs_mac; break; end
    end
  endtask

  // A cache hit: answered quickly, correctly, and WITHOUT a frame (Q1).
  task automatic expect_hit(input logic [31:0] ip, input string what);
    bit got, err; logic [47:0] mac; int took;
    txq.delete();
    start_lookup(ip);
    await_response(HIT_MAX + 8, got, err, mac, took);
    cov_hits++;
    if (!got) fail("Q1/X3", $sformatf("%s: no response within %0d cycles", what, HIT_MAX + 8));
    else begin
      if (err) fail("Q1", $sformatf("%s: answered with an error, but the address is cached", what));
      else if (mac !== known[ip])
        fail("Q1", $sformatf("%s: answered %012x, expected the cached %012x", what, mac, known[ip]));
      if (took > HIT_MAX)
        fail("X3", $sformatf("%s: a cached answer took %0d cycles, the bound is %0d", what, took, HIT_MAX));
    end
    repeat (4) @(posedge clk);
    if (txq.size() != 0)
      fail("Q1", $sformatf("%s: %0d frame(s) were transmitted for an address already cached",
                           what, txq.size()));
  endtask

  // Checks one transmitted ARP request against Q2 and Q3.
  task automatic check_request(input frame_t f, input logic [31:0] want_tpa, input string what);
    if (f.eth_type !== 16'h0806) fail("F", $sformatf("%s: eth_type %04x, expected 0806", what, f.eth_type));
    if (f.oper !== 16'd1)   fail("Q2", $sformatf("%s: operation %0d, expected 1 (request)", what, f.oper));
    if (f.dest_mac !== BCAST) fail("Q2", $sformatf("%s: sent to %012x, expected the broadcast address", what, f.dest_mac));
    if (f.sha !== LMAC)     fail("Q2", $sformatf("%s: SHA %012x, expected local_mac_i", what, f.sha));
    if (f.spa !== LIP)      fail("Q2", $sformatf("%s: SPA %08x, expected local_ip_i", what, f.spa));
    if (f.tha !== 48'd0)    fail("Q2", $sformatf("%s: THA %012x, expected zero", what, f.tha));
    if (f.tpa !== want_tpa)
      fail("Q3", $sformatf("%s: asked for %08x, expected %08x -- an address inside the subnet is asked for directly, one outside it via the gateway",
                           what, f.tpa, want_tpa));
    if (f.htype !== 16'h0001 || f.ptype !== 16'h0800 || f.hlen !== 8'd6 || f.plen !== 8'd4)
      fail("F", $sformatf("%s: fixed header fields are htype=%04x ptype=%04x hlen=%0d plen=%0d",
                          what, f.htype, f.ptype, f.hlen, f.plen));
  endtask

  initial begin
    repeat (6) @(posedge clk);
    @(negedge clk) rst = 1'b0;
    repeat (3) @(posedge clk);

    // -- 1. a miss goes to the network, and a reply resolves it -------------
    begin
      bit got, err; logic [47:0] mac; int took;
      txq.delete();
      start_lookup(32'hC0A8_0105);
      cov_misses++;
      repeat (80) @(posedge clk);
      if (txq.size() < 1) fail("Q2", "an uncached lookup transmitted no request frame");
      else check_request(txq[0], 32'hC0A8_0105, "first request");
      send_frame(16'd2, 48'hAA_BB_CC_DD_EE_05, 32'hC0A8_0105, LMAC, LIP);
      cov_replies_in++;
      await_response(200, got, err, mac, took);
      if (!got) fail("Q6", "a matching reply did not resolve the lookup");
      else if (err) fail("Q6", "a matching reply resolved the lookup as an error");
      else if (mac !== 48'hAA_BB_CC_DD_EE_05)
        fail("Q6", $sformatf("resolved to %012x, expected the reply's SHA aabbccddee05", mac));
    end
    repeat (6) @(posedge clk);

    // -- 2. the same address is now cached ---------------------------------
    expect_hit(32'hC0A8_0105, "a second lookup of a learned address");

    // -- 3. an unanswered lookup: count, spacing, and when it gives up ------
    begin
      bit got, err; logic [47:0] mac; int took; int t0;
      txq.delete();
      start_lookup(32'hC0A8_0109);
      cov_misses++; cov_timeouts++;
      t0 = cyc;
      await_response(2000, got, err, mac, took);
      if (!got) fail("Q5", "an unanswered lookup never gave up");
      else if (!err) fail("Q5", "an unanswered lookup was resolved without an error");
      if (txq.size() != RETRIES)
        fail("Q4", $sformatf("an unanswered lookup transmitted %0d request(s); exactly %0d are required",
                             txq.size(), RETRIES));
      for (int i = 0; i < txq.size(); i++)
        check_request(txq[i], 32'hC0A8_0109, $sformatf("retry %0d", i));
      for (int i = 1; i < txq.size(); i++) begin
        automatic int gap = txq[i].at - txq[i-1].at;
        if (gap < GAP_LO || gap > GAP_HI)
          fail("Q4", $sformatf("requests %0d and %0d are %0d cycles apart; the window is %0d..%0d",
                               i-1, i, gap, GAP_LO, GAP_HI));
      end
      if (txq.size() == RETRIES) begin
        automatic int since = (t0 + took) - txq[RETRIES-1].at;
        if (since < TMO_LO || since > TMO_HI)
          fail("Q5", $sformatf("gave up %0d cycles after the last request; the window is %0d..%0d",
                               since, TMO_LO, TMO_HI));
      end
    end
    repeat (6) @(posedge clk);

    // -- 4. a request for us is answered; one for somebody else is not ------
    begin
      txq.delete();
      send_frame(16'd1, 48'h11_22_33_44_55_66, 32'hC0A8_0107, 48'd0, LIP);
      cov_requests_in++;
      repeat (40) @(posedge clk);
      if (txq.size() != 1)
        fail("A1", $sformatf("a request for our own address produced %0d frame(s), expected 1", txq.size()));
      else begin
        automatic frame_t f = txq[0];
        if (f.oper !== 16'd2) fail("A1", $sformatf("reply operation %0d, expected 2", f.oper));
        if (f.sha !== LMAC)   fail("A1", $sformatf("reply SHA %012x, expected local_mac_i", f.sha));
        if (f.spa !== LIP)    fail("A1", $sformatf("reply SPA %08x, expected local_ip_i", f.spa));
        if (f.tha !== 48'h11_22_33_44_55_66)
          fail("A1", $sformatf("reply THA %012x, expected the requester's SHA", f.tha));
        if (f.tpa !== 32'hC0A8_0107)
          fail("A1", $sformatf("reply TPA %08x, expected the requester's SPA c0a80107", f.tpa));
        if (f.dest_mac !== 48'h11_22_33_44_55_66)
          fail("A1", $sformatf("reply sent to %012x, expected the requester's SHA", f.dest_mac));
      end
      // and the requester is now known (C1)
      expect_hit(32'hC0A8_0107, "the address of a station that asked us");

      txq.delete();
      cov_notforus = 1'b1;
      send_frame(16'd1, 48'h77_88_99_AA_BB_CC, 32'hC0A8_0111, 48'd0, 32'hC0A8_01AB);
      repeat (40) @(posedge clk);
      if (txq.size() != 0)
        fail("A2", $sformatf("a request for somebody else's address produced %0d frame(s)", txq.size()));
    end

    // -- 5. a non-ARP frame is ignored entirely ----------------------------
    begin
      logic [47:0] before_mac;
      txq.delete();
      cov_nonarp = 1'b1;
      send_frame(16'd1, 48'hDE_AD_BE_EF_00_01, 32'hC0A8_0122, 48'd0, LIP, 16'h0800);
      repeat (40) @(posedge clk);
      if (txq.size() != 0)
        fail("A3", $sformatf("a frame with eth_type 0800 produced %0d frame(s); it must be ignored",
                             txq.size()));
      // and it must not have been learned from: a lookup must go to the network
      txq.delete();
      start_lookup(32'hC0A8_0122);
      repeat (80) @(posedge clk);
      if (txq.size() == 0)
        fail("A3", "the sender of a non-ARP frame was learned; that frame must be ignored entirely");
      repeat (700) @(posedge clk);        // let it time out
    end

    // -- 6. an address outside the subnet is asked for via the gateway -----
    begin
      cov_offsubnet = 1'b1;
      txq.delete();
      start_lookup(32'h0808_0808);
      cov_misses++;
      repeat (80) @(posedge clk);
      if (txq.size() < 1) fail("Q2", "an off-subnet lookup transmitted no request");
      else check_request(txq[0], GWIP, "off-subnet lookup");
      repeat (700) @(posedge clk);
    end

    // -- 7. clear_cache makes every address unknown again ------------------
    begin
      cov_clear = 1'b1;
      send_frame(16'd2, 48'h01_02_03_04_05_06, 32'hC0A8_0130, LMAC, LIP);
      cov_replies_in++;
      repeat (10) @(posedge clk);
      expect_hit(32'hC0A8_0130, "an address taught just before the clear");
      @(negedge clk) clr_cache = 1'b1;
      repeat (4) @(posedge clk);
      @(negedge clk) clr_cache = 1'b0;
      repeat (4) @(posedge clk);
      txq.delete();
      start_lookup(32'hC0A8_0130);
      repeat (80) @(posedge clk);
      if (txq.size() == 0)
        fail("C3", "after clear_cache a previously cached address was still answered from the cache");
      repeat (700) @(posedge clk);
    end

    // -- 7a. a SECOND unanswered lookup -------------------------------------
    // Q4 fixes the count at exactly four for EVERY unanswered lookup, not only
    // the first. A design that gives up one retry early from the second one
    // onward passes phase 3 and fails nothing until a second lookup times out.
    begin
      bit got, err; logic [47:0] mac; int took;
      txq.delete();
      start_lookup(32'hC0A8_0131);
      cov_misses++; cov_timeouts++; cov_second_timeout = 1'b1;
      await_response(2000, got, err, mac, took);
      if (!got)      fail("Q5", "the SECOND unanswered lookup never gave up");
      else if (!err) fail("Q5", "the SECOND unanswered lookup was resolved without an error");
      if (txq.size() != RETRIES)
        fail("Q4", $sformatf("the SECOND unanswered lookup transmitted %0d request(s); exactly %0d are required, on every lookup alike",
                             txq.size(), RETRIES));
      for (int i = 0; i < txq.size(); i++)
        check_request(txq[i], 32'hC0A8_0131, $sformatf("second unanswered lookup, retry %0d", i));
    end
    repeat (6) @(posedge clk);

    // -- 7b. a request arrives WHILE one of our own lookups is outstanding ----
    // A1 and A2 hold whatever else the engine is doing. Every request above is
    // fed to an idle engine, so a design that answers correctly only when idle,
    // or that answers requests meant for other stations while it is busy,
    // passes phase 4 and fails nothing until the two overlap.
    begin
      int n_reply = 0, n_foreign = 0;
      bit got, err; logic [47:0] mac; int took;
      txq.delete();
      start_lookup(32'hC0A8_0141);            // unknown, so it stays outstanding
      cov_misses++;
      repeat (12) @(posedge clk);
      send_frame(16'd1, 48'hAA_BB_CC_DD_EE_01, 32'hC0A8_0142, 48'd0, LIP);
      cov_requests_in++; cov_busy_request = 1'b1;
      repeat (80) @(posedge clk);
      for (int i = 0; i < txq.size(); i++) begin
        if (txq[i].oper === 16'd2) begin
          automatic frame_t f = txq[i];
          n_reply++;
          if (f.sha !== LMAC)
            fail("A1", $sformatf("reply SHA %012x while a lookup was outstanding, expected local_mac_i", f.sha));
          if (f.spa !== LIP)
            fail("A1", $sformatf("reply SPA %08x while a lookup was outstanding, expected local_ip_i", f.spa));
          if (f.tha !== 48'hAA_BB_CC_DD_EE_01)
            fail("A1", $sformatf("reply THA %012x while a lookup was outstanding, expected the requester's SHA", f.tha));
          if (f.tpa !== 32'hC0A8_0142)
            fail("A1", $sformatf("reply TPA %08x while a lookup was outstanding, expected c0a80142", f.tpa));
        end
      end
      if (n_reply != 1)
        fail("A1", $sformatf("a request for our own address produced %0d reply frame(s) while a lookup was outstanding; exactly 1 is required",
                             n_reply));

      // ...and one meant for SOMEBODY ELSE, still while we are busy
      txq.delete();
      send_frame(16'd1, 48'hAA_BB_CC_DD_EE_02, 32'hC0A8_0143, 48'd0, 32'hC0A8_01CD);
      repeat (80) @(posedge clk);
      for (int i = 0; i < txq.size(); i++) if (txq[i].oper === 16'd2) n_foreign++;
      if (n_foreign != 0)
        fail("A2", $sformatf("a request for another station's address produced %0d reply frame(s) while a lookup was outstanding",
                             n_foreign));

      await_response(3000, got, err, mac, took);   // let it retire
    end
    repeat (6) @(posedge clk);

    // -- 8. reset mid-stream ------------------------------------------------
    begin
      cov_reset = 1'b1;
      @(negedge clk) rst = 1'b1;
      repeat (5) @(posedge clk);
      // The identity is REPROGRAMMED here, while the engine is held in reset.
      // The spec permits exactly this -- "hold them steady while the engine is
      // running" -- and it is the only stimulus that can distinguish a design
      // reading these ports from one that hardcoded their first values.
      @(negedge clk) begin
        LMAC = LMAC2; LIP = LIP2; GWIP = GWIP2; MASK = MASK2;
        cov_identities = cov_identities + 1;
      end
      repeat (2) @(posedge clk);
      @(negedge clk) rst = 1'b0;
      known.delete(); txq.delete(); txbuf.delete();
      repeat (4) @(posedge clk);
      send_frame(16'd2, 48'h0A_0B_0C_0D_0E_0F, 32'h0A00_0540, LMAC, LIP);
      repeat (10) @(posedge clk);
      expect_hit(32'h0A00_0540, "after a mid-stream reset the engine still learns");
    end

    // -- 8b. the SECOND identity is exercised, or reprogramming proves nothing
    begin
      // Q3, and this is the discriminating pair. Under /16 the first address is
      // INSIDE the local subnet and is asked for directly; under a hardcoded /24
      // it would be outside and the gateway would be asked for instead. The
      // second is outside under both, so it separates the GATEWAY value too --
      // a design holding the old gateway asks for 192.168.1.254.
      txq.delete();
      start_lookup(32'h0A00_0909);
      cov_misses++;
      repeat (80) @(posedge clk);
      if (txq.size() < 1) fail("Q2", "a lookup after reprogramming transmitted no request");
      else check_request(txq[0], 32'h0A00_0909,
                         "in-subnet under the reprogrammed /16 -- a hardcoded /24 asks the gateway here");
      repeat (700) @(posedge clk);

      txq.delete();
      start_lookup(32'hAC10_0101);
      cov_misses++;
      repeat (80) @(posedge clk);
      if (txq.size() < 1) fail("Q2", "an off-subnet lookup after reprogramming transmitted no request");
      else check_request(txq[0], GWIP2,
                         "off-subnet after reprogramming -- the NEW gateway_ip_i");
      repeat (700) @(posedge clk);

      // A1 from both sides under the new identity. A design holding the old
      // local IP answers the wrong one of these two and stays silent on the
      // other, and each half alone would let one of those pass.
      txq.delete();
      send_frame(16'd1, 48'h11_22_33_44_55_67, 32'h0A00_0522, 48'd0, LIP2);
      repeat (40) @(posedge clk);
      if (txq.size() == 0)
        fail("A1", "a request for the REPROGRAMMED local_ip_i was not answered -- local_ip_i is an input, not a constant");
      else begin : chk_new_identity
        frame_t f;
        f = txq[0];
        if (f.spa !== LIP2)
          fail("A1", $sformatf("reply SPA %08x after reprogramming, expected the NEW local_ip_i %08x", f.spa, LIP2));
        if (f.sha !== LMAC2)
          fail("A1", $sformatf("reply SHA %012x after reprogramming, expected the NEW local_mac_i %012x", f.sha, LMAC2));
      end : chk_new_identity

      txq.delete();
      send_frame(16'd1, 48'h11_22_33_44_55_68, 32'h0A00_0523, 48'd0, 32'hC0A8_0101);
      repeat (40) @(posedge clk);
      if (txq.size() != 0)
        fail("A2", $sformatf("a request for the OLD local_ip_i produced %0d frame(s) after reprogramming -- the old value is not this engine's address any more", txq.size()));
    end

    // -- rule 4 floors, on STIMULUS only ------------------------------------
    if (cov_lookups < 8)     fail("COVERAGE", $sformatf("only %0d lookups driven", cov_lookups));
    if (cov_misses < 3)      fail("COVERAGE", $sformatf("only %0d uncached lookups driven", cov_misses));
    if (cov_hits < 4)        fail("COVERAGE", $sformatf("only %0d cached lookups driven", cov_hits));
    if (cov_replies_in < 2)  fail("COVERAGE", "fewer than two ARP replies were fed in");
    if (cov_requests_in < 1) fail("COVERAGE", "no ARP request was ever fed in -- A1 is untested");
    if (cov_timeouts < 1)    fail("COVERAGE", "no lookup was ever left unanswered -- Q4 and Q5 are untested");
    if (!cov_offsubnet)      fail("COVERAGE", "no off-subnet lookup was driven -- Q3 is untested");
    if (!cov_notforus)       fail("COVERAGE", "no request for another station was driven -- A2 is untested");
    // These four are inputs, not constants, and only they can reach that clause.
    // One configuration cannot distinguish a design that reads them from one
    // that hardcoded their first values, however many addresses are looked up.
    if (cov_identities < 2)  fail("COVERAGE", $sformatf("only %0d identity configuration(s) driven -- local_ip_i, local_mac_i, subnet_mask_i and gateway_ip_i are INPUTS, and a design that hardcodes them is indistinguishable at one configuration", cov_identities));
    if (!cov_nonarp)         fail("COVERAGE", "no non-ARP frame was driven -- A3 is untested");
    if (!cov_second_timeout) fail("COVERAGE", "only ONE lookup was ever left unanswered -- Q4's count is unchecked on any later one");
    if (!cov_busy_request)   fail("COVERAGE", "no ARP request arrived while one of our own lookups was outstanding");
    if (!cov_clear)          fail("COVERAGE", "clear_cache_i was never asserted");
    if (!cov_reset)          fail("COVERAGE", "reset was never asserted mid-stream");

    if (errors == 0) $display("RESULT: PASS");
    else $display("RESULT: FAIL (%0d violation%s)", errors, (errors == 1) ? "" : "s");
    $display("  [coverage] lookups=%0d hits=%0d misses=%0d frames_in=%0d",
             cov_lookups, cov_hits, cov_misses, cov_replies_in + cov_requests_in);
    $finish;
  end

  initial begin
    #8_000_000;
    $display("RESULT: FAIL (watchdog: no forward progress; %0d violation(s) so far)", errors);
    $finish;
  end
endmodule
