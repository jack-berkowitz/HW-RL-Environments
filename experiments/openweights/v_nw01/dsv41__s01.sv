module arp_engine_tb;

  // =========================================================================
  // PROVIDED PLUMBING
  // =========================================================================
  logic clk = 1'b0;
  always #5 clk = ~clk;

  int bfm_cycle = 0;
  always @(posedge clk) if (!rst) bfm_cycle <= bfm_cycle + 1;

  logic rst = 1'b1;

  task automatic bfm_reset(input int cycles = 6);
    @(negedge clk);
    rst = 1'b1;
    repeat (cycles) @(posedge clk);
    @(negedge clk);
    rst = 1'b0;
    repeat (3) @(posedge clk);
  endtask

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
    .s_src_mac_i(s_sm), .s_eth_type_i(s_et),
    .s_payload_data_i(s_pd), .s_payload_valid_i(s_pv), .s_payload_ready_o(s_pr),
    .s_payload_last_i(s_pl), .s_payload_user_i(s_pu),
    .m_hdr_valid_o(m_hv), .m_hdr_ready_i(m_hr), .m_dest_mac_o(m_dm),
    .m_src_mac_o(m_sm), .m_eth_type_o(m_et),
    .m_payload_data_o(m_pd), .m_payload_valid_o(m_pv), .m_payload_ready_i(m_pr),
    .m_payload_last_o(m_pl), .m_payload_user_o(m_pu),
    .req_valid_i(rq_v), .req_ready_o(rq_r), .req_ip_i(rq_ip),
    .resp_valid_o(rs_v), .resp_ready_i(rs_r), .resp_error_o(rs_e), .resp_mac_o(rs_mac),
    .local_mac_i(cfg_local_mac), .local_ip_i(cfg_local_ip),
    .gateway_ip_i(cfg_gateway_ip), .subnet_mask_i(cfg_subnet),
    .clear_cache_i(clr_cache));

  typedef struct packed {
    logic [47:0] dest_mac, src_mac;
    logic [15:0] eth_type, htype, ptype, oper;
    logic [7:0]  hlen, plen;
    logic [47:0] sha, tha;
    logic [31:0] spa, tpa;
    int          at;
    int          nbytes;
  } bfm_frame_t;

  bfm_frame_t bfm_rx [$];
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

  task automatic bfm_lookup(input logic [31:0] ip, output bit ok, input int limit = 32);
    ok = 1'b0;
    @(negedge clk); rq_ip = ip; rq_v = 1'b1;
    for (int t=0;t<limit;t++) begin @(posedge clk); if (rq_r) begin ok = 1'b1; break; end end
    @(negedge clk) rq_v = 1'b0;
  endtask

  task automatic bfm_wait(input int n); repeat (n) @(posedge clk); endtask

  initial begin
    #8_000_000;
    $display("RESULT: FAIL (watchdog: no verdict reached)");
    $finish;
  end

  // =========================================================================
  // TEST INFRASTRUCTURE
  // =========================================================================
  int errors = 0;

  task automatic fail(input string msg);
    $display("FAIL: %s", msg);
    errors++;
  endtask

  task automatic check(input bit cond, input string msg);
    if (!cond) fail(msg);
  endtask

  typedef struct packed {
    bit err;
    logic [47:0] mac;
    int at;
  } resp_t;

  resp_t resp_q [$];

  always @(posedge clk) if (!rst) begin
    if (rs_v && rs_r) begin
      resp_t r;
      r.err = rs_e;
      r.mac = rs_mac;
      r.at = bfm_cycle;
      resp_q.push_back(r);
    end
  end

  task automatic clear_resp();
    resp_q.delete();
  endtask

  task automatic wait_resp(input int limit, output bit got, output bit err,
                           output logic [47:0] mac, output int at_cycle);
    got = 1'b0; err = 1'b0; mac = '0; at_cycle = 0;
    for (int t = 0; t < limit; t++) begin
      if (resp_q.size() > 0) begin
        resp_t r;
        r = resp_q.pop_front();
        got = 1'b1; err = r.err; mac = r.mac; at_cycle = r.at;
        return;
      end
      @(posedge clk);
    end
  endtask

  // Reset check: only after first posedge with rst high
  int rst_negedge_count = 0;
  always @(negedge clk) begin
    if (rst) begin
      rst_negedge_count = rst_negedge_count + 1;
      if (rst_negedge_count > 1) begin
        if (rs_v) fail("X1: rs_v high during reset");
        if (m_hv) fail("X1: m_hv high during reset");
        if (m_pv) fail("X1: m_pv high during reset");
      end
    end else begin
      rst_negedge_count = 0;
    end
  end

  // =========================================================================
  // TEST TASKS
  // =========================================================================

  // Test 1: miss -> 4 requests -> timeout
  task automatic test_miss_timeout();
    logic [31:0] ip;
    bit ok, got, err;
    logic [47:0] mac;
    int resp_cycle;
    int n_req, i;
    int t_req [4];
    int gap, dt;

    $display("--- Test 1: miss -> 4 requests -> timeout ---");
    ip = 32'hC0A8_0105;  // 192.168.1.5, inside subnet

    bfm_reset();
    bfm_rx.delete();
    clear_resp();

    bfm_lookup(ip, ok, 32);
    if (!ok) begin
      fail("X3: lookup not accepted within 32 cycles");
      return;
    end

    wait_resp(600, got, err, mac, resp_cycle);
    if (!got) begin
      fail("Q5: no timeout response");
      return;
    end
    if (!err) fail("Q5: timeout response should have error high");

    n_req = 0;
    for (i = 0; i < bfm_rx.size(); i++) begin
      bfm_frame_t f;
      f = bfm_rx[i];
      if (f.eth_type == 16'h0806 && f.oper == 16'h0001) begin
        n_req++;
        if (n_req <= 4) t_req[n_req-1] = f.at;
        if (f.dest_mac != 48'hFFFFFFFFFFFF) fail("Q2: request not broadcast");
        if (f.sha != cfg_local_mac) fail("Q2: SHA wrong");
        if (f.spa != cfg_local_ip) fail("Q2: SPA wrong");
        if (f.tha != 48'h0) fail("Q2: THA not zero");
        if (f.tpa != ip) fail("Q3: TPA should be looked-up IP (inside subnet)");
        if (f.nbytes != 28) fail("F: request payload not 28 bytes");
        if (f.htype != 16'h0001) fail("F: htype wrong");
        if (f.ptype != 16'h0800) fail("F: ptype wrong");
        if (f.hlen != 8'd6) fail("F: hlen wrong");
        if (f.plen != 8'd4) fail("F: plen wrong");
      end
    end

    if (n_req != 4) begin
      fail($sformatf("Q4: expected exactly 4 requests, got %0d", n_req));
      return;
    end

    for (i = 1; i < 4; i++) begin
      gap = t_req[i] - t_req[i-1];
      if (gap < 64 || gap > 80) fail($sformatf("Q4: request gap %0d not in [64,80]", gap));
    end

    dt = resp_cycle - t_req[3];
    if (dt < 256 || dt > 300) fail($sformatf("Q5: timeout %0d cycles after 4th request, not in [256,300]", dt));
  endtask

  // Test 2: reply resolves outstanding lookup
  task automatic test_reply_resolves();
    logic [31:0] ip;
    logic [47:0] remote_mac;
    bit ok, got, err;
    logic [47:0] mac;
    int resp_cycle;
    int n_req, i;
    int reply_done_cycle;

    $display("--- Test 2: reply resolves ---");
    ip = 32'hC0A8_0106;  // 192.168.1.6
    remote_mac = 48'hAA_BB_CC_DD_EE_FF;

    bfm_reset();
    bfm_rx.delete();
    clear_resp();

    bfm_lookup(ip, ok, 32);
    if (!ok) begin
      fail("X3: lookup not accepted");
      return;
    end

    // Wait a bit for first request
    bfm_wait(40);

    // Send reply
    bfm_send(16'h0002, remote_mac, ip, cfg_local_mac, cfg_local_ip, ok);
    reply_done_cycle = bfm_cycle;
    if (!ok) begin
      fail("X3: reply frame not accepted");
      return;
    end

    wait_resp(200, got, err, mac, resp_cycle);
    if (!got) begin
      fail("Q6: no response after reply");
      return;
    end
    if (err) fail("Q6: response should have error low");
    if (mac != remote_mac) fail("Q6: response MAC should be reply SHA");

    // Wait and check no requests after reply
    bfm_wait(200);
    n_req = 0;
    for (i = 0; i < bfm_rx.size(); i++) begin
      bfm_frame_t f;
      f = bfm_rx[i];
      if (f.eth_type == 16'h0806 && f.oper == 16'h0001 && f.at > reply_done_cycle) begin
        n_req++;
      end
    end
    if (n_req > 0) fail($sformatf("Q6: %0d requests transmitted after reply", n_req));
  endtask

  // Test 3: cache hit (uses entry learned in test 2)
  task automatic test_cache_hit();
    logic [31:0] ip;
    logic [47:0] expected_mac;
    bit ok, got, err;
    logic [47:0] mac;
    int resp_cycle;
    int rx_before;

    $display("--- Test 3: cache hit ---");
    ip = 32'hC0A8_0106;
    expected_mac = 48'hAA_BB_CC_DD_EE_FF;

    // Don't reset - keep cache from test 2
    clear_resp();
    rx_before = bfm_rx.size();

    bfm_lookup(ip, ok, 32);
    if (!ok) begin
      fail("X3: lookup not accepted");
      return;
    end

    wait_resp(100, got, err, mac, resp_cycle);
    if (!got) begin
      fail("Q1: no response for cache hit");
      return;
    end
    if (err) fail("Q1: cache hit should have error low");
    if (mac != expected_mac) fail("Q1: wrong MAC for cache hit");
    if (bfm_rx.size() != rx_before) fail("Q1: frame transmitted on cache hit");
  endtask

  // Test 4: answer ARP request for local IP
  task automatic test_answer_request();
    logic [47:0] requester_mac;
    logic [31:0] requester_ip;
    bit ok;
    int i;
    bit found;

    $display("--- Test 4: answer request ---");
    requester_mac = 48'h11_22_33_44_55_66;
    requester_ip = 32'hC0A8_0164;  // 192.168.1.100

    bfm_reset();
    bfm_rx.delete();
    clear_resp();

    bfm_send(16'h0001, requester_mac, requester_ip, 48'h0, cfg_local_ip, ok);
    if (!ok) begin
      fail("X3: request frame not accepted");
      return;
    end

    bfm_wait(100);

    found = 0;
    for (i = 0; i < bfm_rx.size(); i++) begin
      bfm_frame_t f;
      f = bfm_rx[i];
      if (f.eth_type == 16'h0806 && f.oper == 16'h0002) begin
        found = 1;
        if (f.dest_mac != requester_mac) fail("A1: reply dest_mac wrong");
        if (f.sha != cfg_local_mac) fail("A1: reply SHA wrong");
        if (f.spa != cfg_local_ip) fail("A1: reply SPA wrong");
        if (f.tha != requester_mac) fail("A1: reply THA wrong");
        if (f.tpa != requester_ip) fail("A1: reply TPA wrong");
        if (f.nbytes != 28) fail("F: reply payload not 28 bytes");
      end
    end
    if (!found) fail("A1: no reply to ARP request for local IP");
  endtask

  // Test 5: don't answer other requests, but do learn
  task automatic test_no_answer_other();
    logic [47:0] requester_mac;
    logic [31:0] requester_ip;
    logic [31:0] other_ip;
    bit ok, got, err;
    logic [47:0] mac;
    int resp_cycle;
    int i;
    bit found;

    $display("--- Test 5: don't answer other requests ---");
    requester_mac = 48'h11_22_33_44_55_77;
    requester_ip = 32'hC0A8_0165;  // 192.168.1.101
    other_ip = 32'hC0A8_0166;      // 192.168.1.102 (not local)

    bfm_reset();
    bfm_rx.delete();
    clear_resp();

    bfm_send(16'h0001, requester_mac, requester_ip, 48'h0, other_ip, ok);
    if (!ok) begin
      fail("X3: request frame not accepted");
      return;
    end

    bfm_wait(100);

    found = 0;
    for (i = 0; i < bfm_rx.size(); i++) begin
      bfm_frame_t f;
      f = bfm_rx[i];
      if (f.eth_type == 16'h0806 && f.oper == 16'h0002) found = 1;
    end
    if (found) fail("A2: replied to request for non-local IP");

    // Should be learned (C1)
    clear_resp();
    bfm_lookup(requester_ip, ok, 32);
    if (!ok) begin
      fail("X3: lookup not accepted");
      return;
    end
    wait_resp(100, got, err, mac, resp_cycle);
    if (!got) fail("C1: request not learned");
    else if (err) fail("C1: learned entry should hit");
    else if (mac != requester_mac) fail("C1: learned MAC wrong");
  endtask

  // Test 6: ignore non-ARP frames
  task automatic test_ignore_non_arp();
    logic [47:0] sender_mac;
    logic [31:0] sender_ip;
    bit ok, got, err;
    logic [47:0] mac;
    int resp_cycle;
    int i;
    bit found;

    $display("--- Test 6: ignore non-ARP ---");
    sender_mac = 48'h11_22_33_44_55_88;
    sender_ip = 32'hC0A8_0167;  // 192.168.1.103

    bfm_reset();
    bfm_rx.delete();
    clear_resp();

    // Send IPv4 frame (not ARP)
    bfm_send(16'h0001, sender_mac, sender_ip, 48'h0, cfg_local_ip, ok, 16'h0800);
    if (!ok) begin
      fail("X3: non-ARP frame not accepted");
      return;
    end

    bfm_wait(100);

    found = 0;
    for (i = 0; i < bfm_rx.size(); i++) begin
      bfm_frame_t f;
      f = bfm_rx[i];
      if (f.eth_type == 16'h0806) found = 1;
    end
    if (found) fail("A3: replied to non-ARP frame");

    // Should NOT be learned
    clear_resp();
    bfm_lookup(sender_ip, ok, 32);
    if (!ok) begin
      fail("X3: lookup not accepted");
      return;
    end
    wait_resp(600, got, err, mac, resp_cycle);
    if (!got) fail("Q5: no response for lookup");
    else if (!err) fail("A3: non-ARP frame was learned (should miss)");
  endtask

  // Test 7: outside subnet -> gateway
  task automatic test_outside_subnet();
    logic [31:0] ip;
    bit ok, got, err;
    logic [47:0] mac;
    int resp_cycle;
    int i, n_req;

    $display("--- Test 7: outside subnet -> gateway ---");
    ip = 32'h0A00_0005;  // 10.0.0.5, outside subnet

    bfm_reset();
    bfm_rx.delete();
    clear_resp();

    bfm_lookup(ip, ok, 32);
    if (!ok) begin
      fail("X3: lookup not accepted");
      return;
    end

    wait_resp(600, got, err, mac, resp_cycle);
    if (!got) begin
      fail("Q5: no timeout response");
      return;
    end

    n_req = 0;
    for (i = 0; i < bfm_rx.size(); i++) begin
      bfm_frame_t f;
      f = bfm_rx[i];
      if (f.eth_type == 16'h0806 && f.oper == 16'h0001) begin
        n_req++;
        if (f.tpa != cfg_gateway_ip) fail("Q3: TPA should be gateway for outside-subnet lookup");
      end
    end
    if (n_req != 4) fail($sformatf("Q4: expected 4 requests, got %0d", n_req));
  endtask

  // Test 8: clear_cache
  task automatic test_clear_cache();
    logic [47:0] remote_mac;
    logic [31:0] remote_ip;
    bit ok, got, err;
    logic [47:0] mac;
    int resp_cycle;

    $display("--- Test 8: clear_cache ---");
    remote_mac = 48'h11_22_33_44_55_99;
    remote_ip = 32'hC0A8_0168;  // 192.168.1.104

    bfm_reset();
    bfm_rx.delete();
    clear_resp();

    // Learn entry via ARP request (not for local IP)
    bfm_send(16'h0001, remote_mac, remote_ip, 48'h0, 32'hC0A8_0169, ok);
    if (!ok) begin
      fail("X3: request frame not accepted");
      return;
    end

    bfm_wait(50);

    // Verify cached
    clear_resp();
    bfm_lookup(remote_ip, ok, 32);
    if (!ok) begin
      fail("X3: lookup not accepted");
      return;
    end
    wait_resp(100, got, err, mac, resp_cycle);
    if (!got || err) begin
      fail("C1: entry not learned");
      return;
    end

    // Clear cache
    @(negedge clk); clr_cache = 1'b1;
    @(negedge clk); clr_cache = 1'b0;
    bfm_wait(5);

    // Should miss now
    clear_resp();
    bfm_lookup(remote_ip, ok, 32);
    if (!ok) begin
      fail("X3: lookup not accepted");
      return;
    end
    wait_resp(600, got, err, mac, resp_cycle);
    if (!got) fail("C3: no response after clear_cache lookup");
    else if (!err) fail("C3: cache not cleared (lookup hit after clear)");
  endtask

  // Test 9: cache capacity
  task automatic test_capacity();
    logic [47:0] macs [5];
    logic [31:0] ips [5];
    bit ok, got, err;
    logic [47:0] mac;
    int resp_cycle;
    int i;
    int hits, misses;
    bit fifth_hit;
    int first4_hits;

    $display("--- Test 9: cache capacity ---");

    bfm_reset();
    bfm_rx.delete();
    clear_resp();

    for (i = 0; i < 5; i++) begin
      macs[i] = 48'hA0_00_00_00_00_00 + i;
      ips[i] = 32'hC0A8_0200 + i;  // 192.168.2.0 + i
    end

    // Insert 5 entries via ARP requests (not for local IP)
    for (i = 0; i < 5; i++) begin
      bfm_send(16'h0001, macs[i], ips[i], 48'h0, 32'hC0A8_0300, ok);
      if (!ok) begin
        fail("X3: request frame not accepted");
        return;
      end
      bfm_wait(10);
    end

    hits = 0;
    misses = 0;
    fifth_hit = 0;
    first4_hits = 0;
    for (i = 0; i < 5; i++) begin
      clear_resp();
      bfm_lookup(ips[i], ok, 32);
      if (!ok) begin
        fail("X3: lookup not accepted");
        return;
      end
      wait_resp(600, got, err, mac, resp_cycle);
      if (!got) begin
        fail("Q5: no response for lookup");
        return;
      end
      if (err) begin
        misses++;
      end else begin
        hits++;
        if (mac != macs[i]) fail("C1: wrong MAC for cached entry");
        if (i == 4) fifth_hit = 1;
        if (i < 4) first4_hits++;
      end
    end

    if (!fifth_hit) fail("C1: 5th inserted entry not cached");
    if (first4_hits == 4) fail("C2: all 4 first entries still cached, cache holds 5");
  endtask

  // =========================================================================
  // MAIN
  // =========================================================================
  initial begin
    bfm_reset();
    test_miss_timeout();
    test_reply_resolves();
    test_cache_hit();
    test_answer_request();
    test_no_answer_other();
    test_ignore_non_arp();
    test_outside_subnet();
    test_clear_cache();
    test_capacity();

    if (errors == 0) $display("RESULT: PASS");
    else $display("RESULT: FAIL");
    $finish;
  end

endmodule
