module arp_engine_tb;

  // ---------------------------------------------------------------------------
  // PROVIDED PLUMBING -- moves frames and lookups, checks nothing.
  // ---------------------------------------------------------------------------
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
    .clear_cache_i(clr_cache)
  );

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
    if (m_hv && m_hr) begin
      bfm_pdm = m_dm; bfm_psm = m_sm; bfm_pet = m_et; bfm_pat = bfm_cycle;
    end
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

  task automatic bfm_await(input int limit, output bit got, output bit err,
                           output logic [47:0] mac, output int took);
    got = 1'b0; err = 1'b0; mac = '0; took = 0;
    for (int t=0;t<limit;t++) begin
      @(posedge clk); took = t;
      if (rs_v) begin got = 1'b1; err = rs_e; mac = rs_mac; break; end
    end
  endtask

  task automatic bfm_wait(input int n); repeat (n) @(posedge clk); endtask

  initial begin
    #8_000_000;
    $display("RESULT: FAIL (watchdog: no verdict reached)");
    $finish;
  end

  // ---------------------------------------------------------------------------
  // MY TESTBENCH
  // ---------------------------------------------------------------------------

  typedef struct packed {
    bit          err;
    logic [47:0] mac;
    int          at;
  } resp_t;

  resp_t resp_q [$];

  bit          ok;
  bit          got;
  bit          err;
  logic [47:0] mac;
  int          resp_at;
  int          nreq;
  int          i, t;
  bfm_frame_t  f;
  bfm_frame_t  reqs[4];

  logic [31:0] ip_timeout;
  logic [31:0] ip_q6;
  logic [47:0] mac_q6;
  logic [31:0] ip_out;
  logic [47:0] gw_mac;
  logic [31:0] req_ip;
  logic [47:0] req_mac;
  logic [31:0] other_ip;
  logic [47:0] other_mac;
  logic [31:0] not_local_ip;
  logic [31:0] nonarp_ip;
  logic [47:0] nonarp_mac;
  logic [31:0] cap_ip[5];
  logic [47:0] cap_mac[5];
  logic [31:0] clear_ip;
  logic [47:0] clear_mac;

  task automatic fail(input string msg);
    $display("FAIL: %s", msg);
    $display("RESULT: FAIL");
    $finish;
  endtask

  task automatic clear_rx;
    bfm_rx.delete();
  endtask

  task automatic clear_resp;
    resp_q.delete();
  endtask

  task automatic bfm_clear_cache;
    @(negedge clk); clr_cache = 1'b1;
    @(posedge clk);
    @(negedge clk); clr_cache = 1'b0;
    repeat (2) @(posedge clk);
  endtask

  task automatic wait_frame(input int limit, output bit got);
    got = 1'b0;
    for (int t=0; t<limit; t++) begin
      @(posedge clk);
      if (bfm_rx.size() > 0) begin
        got = 1'b1;
        return;
      end
    end
  endtask

  task automatic wait_resp(input int limit, output bit got, output bit err,
                           output logic [47:0] mac, output int at);
    got = 1'b0; err = 1'b0; mac = '0; at = 0;
    for (int t=0; t<limit; t++) begin
      if (resp_q.size() > 0) begin
        automatic resp_t r = resp_q.pop_front();
        got = 1'b1; err = r.err; mac = r.mac; at = r.at;
        return;
      end
      @(posedge clk);
    end
    if (resp_q.size() > 0) begin
      automatic resp_t r = resp_q.pop_front();
      got = 1'b1; err = r.err; mac = r.mac; at = r.at;
    end
  endtask

  task automatic wait_tx_header(input int limit, output bit got);
    got = 1'b0;
    for (int t=0; t<limit; t++) begin
      @(posedge clk);
      if (m_hv && m_hr) begin
        got = 1'b1;
        return;
      end
    end
  endtask

  always @(posedge clk) if (!rst && rs_v && rs_r) begin
    resp_t r;
    r.err = rs_e;
    r.mac = rs_mac;
    r.at  = bfm_cycle;
    resp_q.push_back(r);
  end

  always @(negedge clk) if (rst) begin
    if (m_hv === 1'b1) begin
      $display("FAIL: X1 m_hdr_valid_o high during reset");
      $display("RESULT: FAIL");
      $finish;
    end
    if (m_pv === 1'b1) begin
      $display("FAIL: X1 m_payload_valid_o high during reset");
      $display("RESULT: FAIL");
      $finish;
    end
    if (rs_v === 1'b1) begin
      $display("FAIL: X1 resp_valid_o high during reset");
      $display("RESULT: FAIL");
      $finish;
    end
  end

  initial begin
    bfm_reset();

    // -----------------------------------------------------------------------
    // Q2-Q5: timeout / retry behaviour
    // -----------------------------------------------------------------------
    bfm_clear_cache();
    clear_rx();
    clear_resp();
    ip_timeout = 32'hC0A8_0155; // inside subnet
    bfm_lookup(ip_timeout, ok, 32);
    if (!ok) fail("X3: lookup not accepted within 32 cycles");
    wait_resp(1000, got, err, mac, resp_at);
    if (!got) fail("Q5: no timeout response within 1000 cycles");
    if (!err) fail("Q5: timeout response error low");
    bfm_wait(100);

    nreq = 0;
    while (bfm_rx.size() > 0) begin
      f = bfm_rx.pop_front();
      if (f.eth_type != 16'h0806) fail("F: transmitted frame eth_type not 0x0806");
      if (f.oper != 16'h0001) fail("Q2: transmitted frame not ARP request");
      if (f.dest_mac != 48'hFF_FF_FF_FF_FF_FF) fail("Q2: request dest_mac not broadcast");
      if (f.src_mac != cfg_local_mac) fail("Q2: request src_mac not local_mac");
      if (f.sha != cfg_local_mac) fail("Q2: request SHA not local_mac");
      if (f.spa != cfg_local_ip) fail("Q2: request SPA not local_ip");
      if (f.tha != 48'h0) fail("Q2: request THA not zero");
      if (f.tpa != ip_timeout) fail("Q3: inside subnet request TPA not looked-up IP");
      if (f.htype != 16'h0001) fail("F: htype wrong");
      if (f.ptype != 16'h0800) fail("F: ptype wrong");
      if (f.hlen != 8'd6) fail("F: hlen wrong");
      if (f.plen != 8'd4) fail("F: plen wrong");
      if (f.nbytes != 28) fail("F: payload length not 28");
      if (nreq < 4) reqs[nreq] = f;
      nreq++;
    end
    if (nreq != 4) fail($sformatf("Q4: expected exactly 4 requests, got %0d", nreq));
    for (i=1; i<4; i++) begin
      automatic int gap = reqs[i].at - reqs[i-1].at;
      if (gap < 64 || gap > 80) fail($sformatf("Q4: request spacing %0d not in 64..80", gap));
    end
    begin
      automatic int delta = resp_at - reqs[3].at;
      if (delta < 256 || delta > 300)
        fail($sformatf("Q5: timeout delta %0d not in 256..300 after fourth request", delta));
    end

    // -----------------------------------------------------------------------
    // Q6 inside subnet: reply resolves outstanding lookup
    // -----------------------------------------------------------------------
    bfm_clear_cache();
    clear_rx();
    clear_resp();
    ip_q6 = 32'hC0A8_0166;
    mac_q6 = 48'hAA_BB_CC_DD_EE_01;
    bfm_lookup(ip_q6, ok, 32);
    if (!ok) fail("X3: lookup not accepted");
    wait_tx_header(200, got);
    if (!got) fail("Q2: no request header for miss");
    bfm_send(16'h0002, mac_q6, ip_q6, cfg_local_mac, cfg_local_ip, ok);
    if (!ok) fail("X3: design did not accept reply frame");
    wait_resp(200, got, err, mac, resp_at);
    if (!got) fail("Q6: no response after ARP reply");
    if (err) fail("Q6: response error high after reply");
    if (mac != mac_q6) fail("Q6: response MAC not reply SHA");
    wait_frame(200, got);
    if (!got) fail("Q2: request frame not completed");
    f = bfm_rx.pop_front();
    if (f.tpa != ip_q6) fail("Q3: inside subnet TPA wrong");
    if (f.dest_mac != 48'hFF_FF_FF_FF_FF_FF) fail("Q2: request dest not broadcast");
    if (f.sha != cfg_local_mac) fail("Q2: request SHA wrong");
    if (f.spa != cfg_local_ip) fail("Q2: request SPA wrong");
    if (f.tha != 48'h0) fail("Q2: request THA not zero");
    if (f.oper != 16'h0001) fail("Q2: request not request");
    bfm_wait(100);
    if (bfm_rx.size() != 0) fail("Q6: further request transmitted after reply");

    // -----------------------------------------------------------------------
    // Q1: cache hit, no frame transmitted
    // -----------------------------------------------------------------------
    clear_rx();
    clear_resp();
    bfm_lookup(ip_q6, ok, 32);
    if (!ok) fail("X3: lookup not accepted");
    wait_resp(32, got, err, mac, resp_at);
    if (!got) fail("Q1: cache hit not answered within 32 cycles");
    if (err) fail("Q1: cache hit response error high");
    if (mac != mac_q6) fail("Q1: cache hit MAC wrong");
    bfm_wait(100);
    if (bfm_rx.size() != 0) fail("Q1: frame transmitted on cache hit");

    // -----------------------------------------------------------------------
    // Q3 outside subnet: request goes to gateway
    // -----------------------------------------------------------------------
    bfm_clear_cache();
    clear_rx();
    clear_resp();
    ip_out = 32'h0808_0808;
    gw_mac = 48'h11_22_33_44_55_66;
    bfm_lookup(ip_out, ok, 32);
    if (!ok) fail("X3: lookup not accepted");
    wait_tx_header(200, got);
    if (!got) fail("Q2: no request for outside lookup");
    bfm_send(16'h0002, gw_mac, cfg_gateway_ip, cfg_local_mac, cfg_local_ip, ok);
    if (!ok) fail("X3: design did not accept gateway reply");
    wait_resp(200, got, err, mac, resp_at);
    if (!got) fail("Q6: no response after gateway reply");
    if (err) fail("Q6: response error high after gateway reply");
    if (mac != gw_mac) fail("Q6: response MAC not gateway reply SHA");
    wait_frame(200, got);
    if (!got) fail("Q2: outside request frame not completed");
    f = bfm_rx.pop_front();
    if (f.tpa != cfg_gateway_ip) fail("Q3: outside subnet request TPA not gateway_ip");
    if (f.dest_mac != 48'hFF_FF_FF_FF_FF_FF) fail("Q2: outside request dest not broadcast");
    if (f.sha != cfg_local_mac) fail("Q2: outside request SHA wrong");
    if (f.spa != cfg_local_ip) fail("Q2: outside request SPA wrong");
    if (f.tha != 48'h0) fail("Q2: outside request THA not zero");
    if (f.oper != 16'h0001) fail("Q2: outside request not request");
    bfm_wait(100);
    if (bfm_rx.size() != 0) fail("Q6: further request after gateway reply");

    // -----------------------------------------------------------------------
    // A1: answer ARP request for local IP, and learn
    // -----------------------------------------------------------------------
    bfm_clear_cache();
    clear_rx();
    clear_resp();
    req_ip = 32'hC0A8_01A1;
    req_mac = 48'hDE_AD_BE_EF_00_01;
    bfm_send(16'h0001, req_mac, req_ip, 48'h0, cfg_local_ip, ok);
    if (!ok) fail("X3: design did not accept ARP request for local IP");
    wait_frame(200, got);
    if (!got) fail("A1: no reply to ARP request for local IP");
    f = bfm_rx.pop_front();
    if (f.dest_mac != req_mac) fail("A1: reply dest_mac not requester SHA");
    if (f.src_mac != cfg_local_mac) fail("A1: reply src_mac not local_mac");
    if (f.eth_type != 16'h0806) fail("A1: reply eth_type not ARP");
    if (f.oper != 16'h0002) fail("A1: reply operation not 2");
    if (f.sha != cfg_local_mac) fail("A1: reply SHA not local_mac");
    if (f.spa != cfg_local_ip) fail("A1: reply SPA not local_ip");
    if (f.tha != req_mac) fail("A1: reply THA not requester SHA");
    if (f.tpa != req_ip) fail("A1: reply TPA not requester SPA");
    if (f.nbytes != 28) fail("F: reply payload length not 28");
    bfm_wait(100);
    if (bfm_rx.size() != 0) fail("A1: extra frame after reply");

    clear_rx();
    clear_resp();
    bfm_lookup(req_ip, ok, 32);
    if (!ok) fail("X3: lookup not accepted");
    wait_resp(32, got, err, mac, resp_at);
    if (!got) fail("C1: request not learned (no cache hit)");
    if (err) fail("C1: learned lookup error high");
    if (mac != req_mac) fail("C1: learned MAC wrong");
    bfm_wait(100);
    if (bfm_rx.size() != 0) fail("C1: frame transmitted on learned cache hit");

    // -----------------------------------------------------------------------
    // A2: request TPA not local, not answered, but learned
    // -----------------------------------------------------------------------
    bfm_clear_cache();
    clear_rx();
    clear_resp();
    other_ip = 32'hC0A8_01B2;
    other_mac = 48'hBA_D0_00_00_00_02;
    not_local_ip = 32'hC0A8_01B3;
    bfm_send(16'h0001, other_mac, other_ip, 48'h0, not_local_ip, ok);
    if (!ok) fail("X3: design did not accept ARP request not for local IP");
    bfm_wait(500);
    if (bfm_rx.size() != 0) fail("A2: answered ARP request not for local IP");

    clear_rx();
    clear_resp();
    bfm_lookup(other_ip, ok, 32);
    if (!ok) fail("X3: lookup not accepted");
    wait_resp(32, got, err, mac, resp_at);
    if (!got) fail("C1: request not learned (A2 test)");
    if (err) fail("C1: learned lookup error high (A2 test)");
    if (mac != other_mac) fail("C1: learned MAC wrong (A2 test)");
    bfm_wait(100);
    if (bfm_rx.size() != 0) fail("C1: frame transmitted on learned cache hit (A2 test)");

    // -----------------------------------------------------------------------
    // A3: non-ARP frame ignored entirely
    // -----------------------------------------------------------------------
    bfm_clear_cache();
    clear_rx();
    clear_resp();
    nonarp_ip = 32'hC0A8_01C3;
    nonarp_mac = 48'hBA_D0_00_00_00_03;
    bfm_send(16'h0001, nonarp_mac, nonarp_ip, 48'h0, cfg_local_ip, ok, 16'h0800);
    if (!ok) fail("X3: design did not accept non-ARP frame");
    bfm_wait(500);
    if (bfm_rx.size() != 0) fail("A3: answered non-ARP frame");

    clear_rx();
    clear_resp();
    bfm_lookup(nonarp_ip, ok, 32);
    if (!ok) fail("X3: lookup not accepted");
    wait_tx_header(200, got);
    if (!got) begin
      if (resp_q.size() > 0) fail("A3: non-ARP frame learned (cache hit)");
      else fail("Q2: no request for unknown IP after non-ARP");
    end
    bfm_send(16'h0002, 48'h00_00_00_00_00_99, nonarp_ip, cfg_local_mac, cfg_local_ip, ok);
    if (!ok) fail("X3: design did not accept cleanup reply");
    wait_resp(200, got, err, mac, resp_at);
    if (!got) fail("Q6: no response after cleanup reply");
    if (err) fail("Q6: cleanup reply error high");
    wait_frame(200, got);
    if (!got) fail("Q2: non-ARP test request frame not completed");
    f = bfm_rx.pop_front();
    if (f.tpa != nonarp_ip) fail("Q3: non-ARP test request TPA wrong");
    bfm_wait(100);
    if (bfm_rx.size() != 0) fail("Q6: further request after cleanup reply");

    // -----------------------------------------------------------------------
    // C2: cache capacity 4, L1 latitude respected
    // -----------------------------------------------------------------------
    bfm_clear_cache();
    clear_rx();
    clear_resp();
    cap_ip[0] = 32'hC0A8_01D0; cap_mac[0] = 48'hC0_00_00_00_00_00;
    cap_ip[1] = 32'hC0A8_01D1; cap_mac[1] = 48'hC0_00_00_00_00_01;
    cap_ip[2] = 32'hC0A8_01D2; cap_mac[2] = 48'hC0_00_00_00_00_02;
    cap_ip[3] = 32'hC0A8_01D3; cap_mac[3] = 48'hC0_00_00_00_00_03;
    cap_ip[4] = 32'hC0A8_01D4; cap_mac[4] = 48'hC0_00_00_00_00_04;
    for (i=0; i<5; i++) begin
      bfm_send(16'h0001, cap_mac[i], cap_ip[i], 48'h0, 32'hC0A8_01FF, ok);
      if (!ok) fail("X3: design did not accept cache insert frame");
      bfm_wait(10);
    end

    clear_rx();
    clear_resp();
    bfm_lookup(cap_ip[4], ok, 32);
    if (!ok) fail("X3: lookup not accepted");
    wait_resp(32, got, err, mac, resp_at);
    if (!got) fail("C1: most recent insert not in cache");
    if (err) fail("C1: most recent insert lookup error high");
    if (mac != cap_mac[4]) fail("C1: most recent insert MAC wrong");
    bfm_wait(100);
    if (bfm_rx.size() != 0) fail("C1: frame transmitted on most recent cache hit");

    begin
      automatic bit found_miss = 0;
      for (i=0; i<4 && !found_miss; i++) begin
        clear_rx();
        clear_resp();
        bfm_lookup(cap_ip[i], ok, 32);
        if (!ok) fail("X3: lookup not accepted");
        begin
          automatic bit got_resp = 0;
          automatic bit got_req = 0;
          for (t=0; t<100; t++) begin
            if (resp_q.size() > 0) begin
              automatic resp_t r = resp_q.pop_front();
              got_resp = 1;
              if (r.err) fail("Q1: cache hit error high");
              if (r.mac != cap_mac[i]) fail("Q1: cache hit MAC wrong");
              break;
            end
            if (m_hv) begin
              got_req = 1;
              break;
            end
            @(posedge clk);
          end
          if (got_resp) begin
            // hit, continue
          end else if (got_req) begin
            found_miss = 1;
            bfm_send(16'h0002, cap_mac[i], cap_ip[i], cfg_local_mac, cfg_local_ip, ok);
            if (!ok) fail("X3: design did not accept capacity cleanup reply");
            wait_resp(200, got, err, mac, resp_at);
            if (!got) fail("Q6: no response after capacity cleanup reply");
            if (err) fail("Q6: capacity cleanup reply error high");
            if (mac != cap_mac[i]) fail("Q6: capacity cleanup MAC wrong");
            wait_frame(200, got);
            if (!got) fail("Q2: capacity miss request frame not completed");
            f = bfm_rx.pop_front();
            if (f.tpa != cap_ip[i]) fail("Q3: capacity miss request TPA wrong");
            bfm_wait(100);
            if (bfm_rx.size() != 0) fail("Q6: further request after capacity cleanup reply");
          end else begin
            fail("X3: no response or request for capacity lookup");
          end
        end
      end
      if (!found_miss) fail("C2: cache held more than 4 entries (all first 4 still present)");
    end

    // -----------------------------------------------------------------------
    // C3: clear_cache empties the cache
    // -----------------------------------------------------------------------
    bfm_clear_cache();
    clear_rx();
    clear_resp();
    clear_ip = 32'hC0A8_01E0;
    clear_mac = 48'hC0_00_00_00_00_10;
    bfm_send(16'h0001, clear_mac, clear_ip, 48'h0, 32'hC0A8_01FF, ok);
    if (!ok) fail("X3: design did not accept clear insert frame");
    bfm_wait(10);

    clear_rx();
    clear_resp();
    bfm_lookup(clear_ip, ok, 32);
    if (!ok) fail("X3: lookup not accepted");
    wait_resp(32, got, err, mac, resp_at);
    if (!got) fail("C1: clear test insert not in cache");
    if (err) fail("C1: clear test insert error high");
    if (mac != clear_mac) fail("C1: clear test insert MAC wrong");
    bfm_wait(100);
    if (bfm_rx.size() != 0) fail("C1: frame transmitted on clear test hit");

    bfm_clear_cache();
    clear_rx();
    clear_resp();
    bfm_lookup(clear_ip, ok, 32);
    if (!ok) fail("X3: lookup not accepted");
    wait_tx_header(200, got);
    if (!got) fail("C3: clear_cache did not empty cache (no request for previously cached IP)");
    bfm_send(16'h0002, clear_mac, clear_ip, cfg_local_mac, cfg_local_ip, ok);
    if (!ok) fail("X3: design did not accept clear cleanup reply");
    wait_resp(200, got, err, mac, resp_at);
    if (!got) fail("Q6: no response after clear cleanup reply");
    if (err) fail("Q6: clear cleanup reply error high");
    wait_frame(200, got);
    if (!got) fail("Q2: clear test request frame not completed");
    f = bfm_rx.pop_front();
    if (f.tpa != clear_ip) fail("Q3: clear test miss request TPA wrong");
    bfm_wait(100);
    if (bfm_rx.size() != 0) fail("Q6: further request after clear cleanup reply");

    $display("RESULT: PASS");
    $finish;
  end

endmodule
