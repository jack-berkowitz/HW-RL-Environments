 module arp_engine_tb;

// ---------------------------------------------------------------------------
// PROVIDED PLUMBING -- moves frames and lookups, checks nothing.
// ---------------------------------------------------------------------------
// This exists so you spend your effort on checking rather than on serialising
// ARP frames byte by byte. It has been compiled and run against a correct
// design.
//
// What it does: generates the clock, sequences reset, connects the design,
// packs an ARP frame into the 28 bytes clause F describes and drives it in,
// unpacks every frame the design sends out into its fields, and offers a
// lookup.
//
// What it does NOT do: it keeps no cache, models no retry or timeout, decides
// nothing about which address should have been asked for, and draws no
// conclusion from any frame it captured. Every check is yours to write.
//
// ONE THING WORTH KNOWING: a frame is only complete when its last payload byte
// has moved, twenty-eight cycles after its header at the earliest. Waiting
// twenty cycles for one and concluding the design sent nothing is a mistake
// about the plumbing, not a finding about the design.
// ---------------------------------------------------------------------------

  // ---- clock ---------------------------------------------------------------
  logic clk = 1'b0;
  always #5 clk = ~clk;

  int bfm_cycle = 0;
  always @(posedge clk) if (!rst) bfm_cycle <= bfm_cycle + 1;

  // ---- reset ---------------------------------------------------------------
  logic rst = 1'b1;            // SYNCHRONOUS, ACTIVE HIGH

  task automatic bfm_reset(input int cycles = 6);
    @(negedge clk);
    rst = 1'b1;
    repeat (cycles) @(posedge clk);
    @(negedge clk);
    rst = 1'b0;
    repeat (3) @(posedge clk);
  endtask

  // ---- signals and the design under test ------------------------------------
  logic        s_hv = 1'b0, s_hr;
  logic [47:0] s_dm = '0, s_sm = '0;
  logic [15:0] s_et = '0;
  logic [7:0]  s_pd = '0;
  logic        s_pv = 1'b0, s_pr, s_pl = 1'b0, s_pu = 1'b0;
  logic        m_hv, m_hr = 1'b1;
  logic [47:0] m_dm, m_sm;
  logic [15:0] m_et;
  logic [7:0]  m_pd;
  logic        m_pv, m_pr = 1'b1, m_pl, m_pu;
  logic        rq_v = 1'b0, rq_r;
  logic [31:0] rq_ip = '0;
  logic        rs_v, rs_r = 1'b1, rs_e;
  logic [47:0] rs_mac;
  logic        clr_cache = 1'b0;
  logic [47:0] cfg_local_mac  = 48'h02_00_00_00_00_01;
  logic [31:0] cfg_local_ip   = 32'hC0A8_0101;
  logic [31:0] cfg_gateway_ip = 32'hC0A8_01FE;
  logic [31:0] cfg_subnet     = 32'hFFFF_FF00;

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
    .local_mac_i(cfg_local_mac), .local_ip_i(cfg_local_ip),
    .gateway_ip_i(cfg_gateway_ip), .subnet_mask_i(cfg_subnet),
    .clear_cache_i(clr_cache));

  // ---- every frame the design sends, unpacked --------------------------------
  typedef struct packed {
    logic [47:0] dest_mac, src_mac;
    logic [15:0] eth_type, htype, ptype, oper;
    logic [7:0]  hlen, plen;
    logic [47:0] sha, tha;
    logic [31:0] spa, tpa;
    int          at;          // the cycle its header moved
    int          nbytes;      // payload length, so you can check it yourself
  } bfm_frame_t;

  bfm_frame_t bfm_rx [$];     // frames captured from the design
  logic [7:0] bfm_buf [$];
  logic [47:0] bfm_pdm, bfm_psm; logic [15:0] bfm_pet; int bfm_pat;

  always @(posedge clk) if (!rst) begin
    if (m_hv && m_hr) begin bfm_pdm = m_dm; bfm_psm = m_sm; bfm_pet = m_et; bfm_pat = bfm_cycle; end
    if (m_pv && m_pr) begin
      bfm_buf.push_back(m_pd);
      if (m_pl) begin
        bfm_frame_t f;
        f.dest_mac = bfm_pdm; f.src_mac = bfm_psm; f.eth_type = bfm_pet;
        f.at = bfm_pat; f.nbytes = bfm_buf.size();
        f.htype = (bfm_buf.size() > 1)  ? {bfm_buf[0], bfm_buf[1]} : '0;
        f.ptype = (bfm_buf.size() > 3)  ? {bfm_buf[2], bfm_buf[3]} : '0;
        f.hlen  = (bfm_buf.size() > 4)  ? bfm_buf[4] : '0;
        f.plen  = (bfm_buf.size() > 5)  ? bfm_buf[5] : '0;
        f.oper  = (bfm_buf.size() > 7)  ? {bfm_buf[6], bfm_buf[7]} : '0;
        f.sha   = (bfm_buf.size() > 13) ? {bfm_buf[8],bfm_buf[9],bfm_buf[10],
                                           bfm_buf[11],bfm_buf[12],bfm_buf[13]} : '0;
        f.spa   = (bfm_buf.size() > 17) ? {bfm_buf[14],bfm_buf[15],bfm_buf[16],bfm_buf[17]} : '0;
        f.tha   = (bfm_buf.size() > 23) ? {bfm_buf[18],bfm_buf[19],bfm_buf[20],
                                           bfm_buf[21],bfm_buf[22],bfm_buf[23]} : '0;
        f.tpa   = (bfm_buf.size() > 27) ? {bfm_buf[24],bfm_buf[25],bfm_buf[26],bfm_buf[27]} : '0;
        bfm_rx.push_back(f);
        bfm_buf.delete();
      end
    end
  end

  // ---- driving a frame in ----------------------------------------------------
  // Returns without waiting for any response. `ok` is low if the design did not
  // accept the header or a payload byte within `limit` cycles.
  task automatic bfm_send(input logic [15:0] oper, input logic [47:0] sha,
                          input logic [31:0] spa, input logic [47:0] tha,
                          input logic [31:0] tpa, output bit ok,
                          input logic [15:0] ethtype = 16'h0806, input int limit = 32);
    logic [7:0] p [28];
    ok = 1'b1;
    p[0]=8'h00; p[1]=8'h01; p[2]=8'h08; p[3]=8'h00; p[4]=8'd6; p[5]=8'd4;
    p[6]=oper[15:8]; p[7]=oper[7:0];
    for (int i=0;i<6;i++) p[8+i]  = sha[47-8*i -: 8];
    for (int i=0;i<4;i++) p[14+i] = spa[31-8*i -: 8];
    for (int i=0;i<6;i++) p[18+i] = tha[47-8*i -: 8];
    for (int i=0;i<4;i++) p[24+i] = tpa[31-8*i -: 8];
    @(negedge clk); s_dm = cfg_local_mac; s_sm = sha; s_et = ethtype; s_hv = 1'b1;
    begin bit took = 1'b0;
      for (int t=0;t<limit;t++) begin @(posedge clk); if (s_hr) begin took=1'b1; break; end end
      if (!took) ok = 1'b0;
    end
    @(negedge clk) s_hv = 1'b0;
    if (!ok) return;
    for (int i=0;i<28;i++) begin
      bit took = 1'b0;
      @(negedge clk); s_pd = p[i]; s_pl = (i==27); s_pv = 1'b1;
      for (int t=0;t<limit;t++) begin @(posedge clk); if (s_pr) begin took=1'b1; break; end end
      @(negedge clk) s_pv = 1'b0; s_pl = 1'b0;
      if (!took) begin ok = 1'b0; return; end
    end
  endtask

  // ---- offering a lookup ------------------------------------------------------
  task automatic bfm_lookup(input logic [31:0] ip, output bit ok, input int limit = 32);
    ok = 1'b0;
    @(negedge clk); rq_ip = ip; rq_v = 1'b1;
    for (int t=0;t<limit;t++) begin @(posedge clk); if (rq_r) begin ok = 1'b1; break; end end
    @(negedge clk) rq_v = 1'b0;
  endtask

  // Waits for a response. `got` is low if none arrived within `limit` cycles.
  task automatic bfm_await(input int limit, output bit got, output bit err,
                           output logic [47:0] mac, output int took);
    got = 1'b0; err = 1'b0; mac = '0; took = 0;
    for (int t=0;t<limit;t++) begin
      @(posedge clk); took = t;
      if (rs_v) begin got = 1'b1; err = rs_e; mac = rs_mac; break; end
    end
  endtask

  task automatic bfm_wait(input int n); repeat (n) @(posedge clk); endtask

  // ---- watchdog ---------------------------------------------------------------
  // Yours to keep. It fires regardless of what the design does: one of the
  // faulty designs never accepts a lookup at all, and without this your
  // testbench hangs instead of reporting. A hang is not a verdict.
  initial begin
    #8_000_000;
    $display("RESULT: FAIL (watchdog: no verdict reached)");
    $finish;
  end

// ---------------------------------------------------------------------------
// TESTBENCH LOGIC
// ---------------------------------------------------------------------------

  // X1: rst_i is active high synchronous. No output valid is asserted.
  int edges = 0;
  always @(posedge clk) edges <= edges + 1;
  always @(posedge clk) begin
    if (edges > 0 && rst) begin
      if (m_hv || m_pv || rs_v) begin
        $display("Clause X1: output valid asserted during reset");
        $display("RESULT: FAIL");
        $finish;
      end
    end
  end

  task automatic fail(string msg);
    $display("%s", msg);
    $display("RESULT: FAIL");
    $finish;
  endtask

  initial begin
    automatic bit ok;
    automatic bit got, err;
    automatic logic [47:0] mac;
    automatic int took;

    bfm_reset();

    // -----------------------------------------------------------------------
    // TEST 1: Subnet Lookup, Retries (Q2, Q3, Q4, Q5, X3)
    // -----------------------------------------------------------------------
    begin
      automatic int last_req_time = 0;
      automatic int resp_time = 0;
      
      bfm_rx.delete();
      bfm_lookup(32'hC0A8_0105, ok, 32);
      if (!ok) fail("Clause X3: lookup not accepted within 32 cycles");

      bfm_await(500, got, err, mac, took);
      if (!got) fail("Clause Q5: no response for timeout");
      resp_time = bfm_cycle;
      if (!err) fail("Clause Q5: resp_error_o must be high on timeout");

      bfm_wait(100); // ensure no extra requests follow
      if (bfm_rx.size() != 4) fail("Clause Q4: exactly 4 requests expected on timeout");

      for (int i=0; i<4; i++) begin
        automatic bfm_frame_t f = bfm_rx[i];
        if (f.dest_mac != 48'hFFFFFFFFFFFF) fail("Clause Q2: broadcast dest MAC expected");
        if (f.sha != cfg_local_mac) fail("Clause Q2: SHA must be local_mac");
        if (f.spa != cfg_local_ip) fail("Clause Q2: SPA must be local_ip");
        if (f.tha != 0) fail("Clause Q2: THA must be 0");
        if (f.tpa != 32'hC0A8_0105) fail("Clause Q3: asked address in subnet must be lookup IP");
        if (f.oper != 1) fail("Clause Q2: must be request (oper=1)");

        if (i > 0) begin
          automatic int diff = f.at - last_req_time;
          if (diff < 64 || diff > 80) fail("Clause Q4: interval must be 64-80 cycles");
        end
        last_req_time = f.at;
      end

      begin
        automatic int timeout_diff = resp_time - bfm_rx[3].at;
        if (timeout_diff < 256 || timeout_diff > 300) fail("Clause Q5: response must be 256-300 cycles after 4th request");
      end
    end

    // -----------------------------------------------------------------------
    // TEST 1.5: Reply with wrong SPA does not resolve lookup (Q6, C1)
    // -----------------------------------------------------------------------
    begin
      bfm_rx.delete();
      bfm_lookup(32'hC0A8_0120, ok, 32);
      if (!ok) fail("Clause X3: lookup not accepted");

      begin
        automatic bit req_seen = 0;
        for (int t=0; t<100; t++) begin
          if (bfm_rx.size() > 0) begin req_seen = 1; break; end
          bfm_wait(1);
        end
        if (!req_seen) fail("Clause Q2: no request sent");
      end

      // Send reply from wrong SPA (0121 instead of 0120)
      bfm_send(2, 48'h22_22_22_22_22_22, 32'hC0A8_0121, cfg_local_mac, cfg_local_ip, ok);
      if (!ok) fail("Clause X3: frame not accepted");

      // Verify the outstanding lookup continues retrying (sends a 2nd request)
      begin
        automatic bit req2_seen = 0;
        for (int t=0; t<100; t++) begin
          if (bfm_rx.size() > 1) begin req2_seen = 1; break; end
          bfm_wait(1);
        end
        if (!req2_seen) fail("Clause Q6: lookup resolved by reply with wrong SPA");
      end

      // Resolve it correctly
      bfm_send(2, 48'h20_20_20_20_20_20, 32'hC0A8_0120, cfg_local_mac, cfg_local_ip, ok);
      if (!ok) fail("Clause X3: frame not accepted");
      bfm_await(200, got, err, mac, took);
      if (!got || err || mac != 48'h20_20_20_20_20_20) fail("Clause Q6: valid reply did not resolve lookup correctly");

      // Verify the wrong-SPA reply was cached anyway (C1)
      bfm_rx.delete();
      bfm_lookup(32'hC0A8_0121, ok, 32);
      bfm_await(32, got, err, mac, took);
      if (!got || err || mac != 48'h22_22_22_22_22_22) fail("Clause C1: did not cache wrong-SPA reply");
      if (bfm_rx.size() > 0) fail("Clause Q1: cache hit transmitted a request");
    end

    // -----------------------------------------------------------------------
    // TEST 2: Gateway routing and Resolution (Q3, Q6, Q1)
    // -----------------------------------------------------------------------
    begin
      bfm_rx.delete();
      bfm_lookup(32'h0808_0808, ok, 32); // IP completely outside subnet
      if (!ok) fail("Clause X3: lookup not accepted");

      begin
        automatic bit req_seen = 0;
        for (int t=0; t<200; t++) begin
          if (bfm_rx.size() > 0) begin req_seen = 1; break; end
          bfm_wait(1);
        end
        if (!req_seen) fail("Clause Q2/Q3: no request sent for gateway lookup");
      end

      if (bfm_rx[0].tpa != cfg_gateway_ip) fail("Clause Q3: asked address outside subnet must be gateway IP");

      // Reply from the Gateway
      bfm_send(2, 48'hA1_A2_A3_A4_A5_A6, cfg_gateway_ip, cfg_local_mac, cfg_local_ip, ok);
      if (!ok) fail("Clause X3: frame not accepted");

      bfm_await(200, got, err, mac, took);
      if (!got || err || mac != 48'hA1_A2_A3_A4_A5_A6) fail("Clause Q6: error resolving gateway");

      // Looking up Gateway IP directly to firmly test Q1/C1 without routing ambiguity
      bfm_rx.delete();
      bfm_lookup(cfg_gateway_ip, ok, 32);
      if (!ok) fail("Clause X3: lookup not accepted");
      
      bfm_await(32, got, err, mac, took);
      if (!got || err || mac != 48'hA1_A2_A3_A4_A5_A6) fail("Clause Q1/C1: gateway IP not cached properly");
      if (bfm_rx.size() != 0) fail("Clause Q1: sent request on hit");
    end

    // -----------------------------------------------------------------------
    // TEST 2.5: Edge-case Subnet Mask
    // -----------------------------------------------------------------------
    begin
      @(negedge clk); clr_cache = 1;
      @(negedge clk); clr_cache = 0;

      bfm_rx.delete();
      bfm_lookup(32'hC0A8_0201, ok, 32); // 02 is outside FF00 mask against 0101
      if (!ok) fail("Clause X3: lookup not accepted");
      
      begin
        automatic bit req_seen = 0;
        for (int t=0; t<100; t++) begin
          if (bfm_rx.size() > 0) begin req_seen = 1; break; end
          bfm_wait(1);
        end
        if (!req_seen) fail("Clause Q2: request missing");
      end

      if (bfm_rx[0].tpa != cfg_gateway_ip) fail("Clause Q3: edge case subnet logic failed");

      bfm_send(2, 48'hB1_B2_B3_B4_B5_B6, cfg_gateway_ip, cfg_local_mac, cfg_local_ip, ok);
      bfm_await(200, got, err, mac, took);
    end

    // -----------------------------------------------------------------------
    // TEST 3: Cache Capacity (C2)
    // -----------------------------------------------------------------------
    begin
      @(negedge clk); clr_cache = 1;
      @(negedge clk); clr_cache = 0;

      // Insert exactly 4 entries
      bfm_send(1, 48'h11, 32'hC0A8_0111, 48'h0, cfg_local_ip, ok); if (!ok) fail("Clause X3: frame rejected"); bfm_wait(100);
      bfm_send(1, 48'h12, 32'hC0A8_0112, 48'h0, cfg_local_ip, ok); if (!ok) fail("Clause X3: frame rejected"); bfm_wait(100);
      bfm_send(1, 48'h13, 32'hC0A8_0113, 48'h0, cfg_local_ip, ok); if (!ok) fail("Clause X3: frame rejected"); bfm_wait(100);
      bfm_send(1, 48'h14, 32'hC0A8_0114, 48'h0, cfg_local_ip, ok); if (!ok) fail("Clause X3: frame rejected"); bfm_wait(100);

      bfm_rx.delete();

      // Look up all 4, they must hit (capacity >= 4)
      begin
        automatic logic [31:0] ips[4] = '{32'hC0A8_0111, 32'hC0A8_0112, 32'hC0A8_0113, 32'hC0A8_0114};
        for (int i=0; i<4; i++) begin
          bfm_rx.delete();
          bfm_lookup(ips[i], ok, 32);
          if (!ok) fail("Clause X3: lookup not accepted");
          bfm_await(40, got, err, mac, took);
          if (!got) fail("Clause C2: cache capacity must be at least 4");
          if (bfm_rx.size() > 0) fail("Clause Q1: transmitted frame on hit");
        end
      end

      // Insert a 5th entry
      bfm_send(1, 48'h15, 32'hC0A8_0115, 48'h0, cfg_local_ip, ok); if (!ok) fail("Clause X3: frame rejected"); bfm_wait(100);
      bfm_rx.delete();

      // Look up all 5. Since capacity is 4, at least one MUST miss.
      begin
        automatic logic [31:0] ips5[5] = '{32'hC0A8_0111, 32'hC0A8_0112, 32'hC0A8_0113, 32'hC0A8_0114, 32'hC0A8_0115};
        automatic logic [47:0] macs5[5] = '{48'h11, 48'h12, 48'h13, 48'h14, 48'h15};
        automatic int hits = 0;

        for (int i=0; i<5; i++) begin
          bfm_rx.delete();
          bfm_lookup(ips5[i], ok, 32);
          if (!ok) fail("Clause X3: lookup not accepted");

          begin
            automatic bit is_hit = 0;
            for (int t=0; t<100; t++) begin
              if (rs_v) begin is_hit = 1; break; end
              if (bfm_rx.size() > 0) begin is_hit = 0; break; end
              bfm_wait(1);
            end

            if (is_hit) begin
              hits++;
            end else begin
              // Resolve the miss to free up the engine
              bfm_send(2, macs5[i], ips5[i], cfg_local_mac, cfg_local_ip, ok);
              if (!ok) fail("Clause X3: frame rejected");
              bfm_await(200, got, err, mac, took);
            end
          end
        end
        if (hits == 5) fail("Clause C2: cache capacity must be exactly 4 (held 5 entries)");
      end
    end

    // -----------------------------------------------------------------------
    // TEST 4: Ignore wrong ETH_TYPE (A3)
    // -----------------------------------------------------------------------
    begin
      bfm_rx.delete();
      // Send an IPv4 frame containing what looks like an ARP reply
      bfm_send(2, 48'h16, 32'hC0A8_0116, cfg_local_mac, cfg_local_ip, ok, 16'h0800);
      if (!ok) fail("Clause X3: frame not accepted");
      bfm_wait(100);
      
      if (bfm_rx.size() > 0) fail("Clause A3: answered a non-ARP frame");

      bfm_rx.delete();
      bfm_lookup(32'hC0A8_0116, ok, 32);
      if (!ok) fail("Clause X3: lookup not accepted");

      begin
        automatic bit req_seen = 0;
        for (int t=0; t<100; t++) begin
          if (bfm_rx.size() > 0) begin req_seen = 1; break; end
          bfm_wait(1);
        end
        if (!req_seen) fail("Clause A3: learned from non-ARP frame");
      end

      bfm_send(2, 48'h16, 32'hC0A8_0116, cfg_local_mac, cfg_local_ip, ok);
      bfm_await(200, got, err, mac, took);
    end

    // -----------------------------------------------------------------------
    // TEST 5: Unanswered Requests (A2, C1)
    // -----------------------------------------------------------------------
    begin
      bfm_rx.delete();
      // Request for another IP
      bfm_send(1, 48'h17, 32'hC0A8_0117, 48'h0, 32'hC0A8_0117, ok);
      if (!ok) fail("Clause X3: frame not accepted");

      bfm_wait(100);
      if (bfm_rx.size() > 0) fail("Clause A2: answered request for another IP");

      // Verify it was still learned
      bfm_lookup(32'hC0A8_0117, ok, 32);
      bfm_await(32, got, err, mac, took);
      if (!got) fail("Clause C1: did not learn from request for another IP");
      if (bfm_rx.size() > 0) fail("Clause Q1: sent frame on cache hit");
    end

    // -----------------------------------------------------------------------
    // TEST 6: Verify A1 response fields exactly
    // -----------------------------------------------------------------------
    begin
      bfm_rx.delete();
      bfm_send(1, 48'h18, 32'hC0A8_0118, 48'h0, cfg_local_ip, ok);
      if (!ok) fail("Clause X3: frame not accepted");
      bfm_wait(100);

      if (bfm_rx.size() != 1) fail("Clause A1: expected exactly one reply");
      
      begin
        automatic bfm_frame_t f = bfm_rx[0];
        if (f.oper != 2) fail("Clause A1: must answer with reply (oper=2)");
        if (f.sha != cfg_local_mac) fail("Clause A1: SHA must be local_mac");
        if (f.spa != cfg_local_ip) fail("Clause A1: SPA must be local_ip");
        if (f.tha != 48'h18) fail("Clause A1: THA must be requester's SHA");
        if (f.tpa != 32'hC0A8_0118) fail("Clause A1: TPA must be requester's SPA");
        if (f.dest_mac != 48'h18) fail("Clause A1: dest_mac must be requester's SHA");
      end
    end

    // -----------------------------------------------------------------------
    // TEST 7: Unprompted reply must be cached (C1)
    // -----------------------------------------------------------------------
    begin
      bfm_rx.delete();
      bfm_send(2, 48'h19, 32'hC0A8_0119, cfg_local_mac, cfg_local_ip, ok);
      if (!ok) fail("Clause X3: frame not accepted");
      bfm_wait(100);
      if (bfm_rx.size() > 0) fail("Clause A1: should not transmit upon receiving a reply");

      bfm_lookup(32'hC0A8_0119, ok, 32);
      bfm_await(32, got, err, mac, took);
      if (!got || err || mac != 48'h19) fail("Clause C1: unprompted reply not cached");
    end

    // -----------------------------------------------------------------------
    // TEST 8: Cache Clear (C3)
    // -----------------------------------------------------------------------
    begin
      @(negedge clk); clr_cache = 1;
      @(negedge clk); clr_cache = 0;

      bfm_rx.delete();
      bfm_lookup(32'hC0A8_0119, ok, 32);
      if (!ok) fail("Clause X3: lookup not accepted");

      begin
        automatic bit req_seen = 0;
        for (int t=0; t<100; t++) begin
          if (bfm_rx.size() > 0) begin req_seen = 1; break; end
          bfm_wait(1);
        end
        if (!req_seen) fail("Clause C3: clear_cache_i did not empty the cache");
      end
      
      bfm_send(2, 48'h19, 32'hC0A8_0119, cfg_local_mac, cfg_local_ip, ok);
      bfm_await(200, got, err, mac, took);
    end

    // Verdict if all tests pass
    $display("RESULT: PASS");
    $finish;
  end

endmodule