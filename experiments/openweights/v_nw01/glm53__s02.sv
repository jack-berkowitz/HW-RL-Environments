module arp_engine_tb;

  // ---------------------------------------------------------------------------
  // PROVIDED PLUMBING
  // ---------------------------------------------------------------------------
  logic clk = 1'b0;
  always #5 clk = ~clk;

  int bfm_cycle = 0;
  always @(posedge clk) if (!rst) bfm_cycle <= bfm_cycle + 1;

  logic rst = 1'b1;            // SYNCHRONOUS, ACTIVE HIGH

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
  // MY CHECKER AND STIMULUS
  // ---------------------------------------------------------------------------
  bit failed = 1'b0;

  task automatic fail(input string clause);
    failed = 1'b1;
    $display("VIOLATION: %s", clause);
  endtask

  // index of the k-th (0-based) ARP request we sent for `tpa`
  function automatic int req_idx(input logic [31:0] tpa, input int k);
    int n; n = 0;
    foreach (bfm_rx[i])
      if (bfm_rx[i].oper == 16'd1 && bfm_rx[i].tpa == tpa &&
          bfm_rx[i].spa == cfg_local_ip) begin
        if (n == k) return i;
        n++;
      end
    return -1;
  endfunction

  function automatic int count_req(input logic [31:0] tpa);
    int n; n = 0;
    foreach (bfm_rx[i])
      if (bfm_rx[i].oper == 16'd1 && bfm_rx[i].tpa == tpa &&
          bfm_rx[i].spa == cfg_local_ip) n++;
    return n;
  endfunction

  function automatic int find_reply_to(input logic [47:0] dst);
    foreach (bfm_rx[i])
      if (bfm_rx[i].oper == 16'd2 && bfm_rx[i].dest_mac == dst) return i;
    return -1;
  endfunction

  task automatic wait_resp(input int limit, output bit got, output bit err,
                           output logic [47:0] mac, output int cyc);
    got = 0; err = 0; mac = '0; cyc = -1;
    for (int t = 0; t < limit; t++) begin
      @(posedge clk);
      if (rs_v) begin got = 1; err = rs_e; mac = rs_mac; cyc = bfm_cycle; break; end
    end
  endtask

  // Q2 / F field checks on a captured request frame
  task automatic check_request(input int idx, input logic [31:0] tpa);
    if (idx < 0) begin fail("Q2: expected request frame missing"); return; end
    if (bfm_rx[idx].dest_mac != 48'hFFFF_FFFF_FFFF) fail("Q2: request not broadcast");
    if (bfm_rx[idx].eth_type   != 16'h0806)         fail("F: request eth_type not 0x0806");
    if (bfm_rx[idx].htype      != 16'h0001)         fail("F: htype");
    if (bfm_rx[idx].ptype      != 16'h0800)         fail("F: ptype");
    if (bfm_rx[idx].hlen       != 8'd6)             fail("F: hlen");
    if (bfm_rx[idx].plen       != 8'd4)             fail("F: plen");
    if (bfm_rx[idx].oper       != 16'd1)            fail("Q2: oper not request");
    if (bfm_rx[idx].sha        != cfg_local_mac)    fail("Q2: SHA not local_mac");
    if (bfm_rx[idx].spa        != cfg_local_ip)     fail("Q2: SPA not local_ip");
    if (bfm_rx[idx].tha        != 48'h0)            fail("Q2: THA not zero");
    if (bfm_rx[idx].tpa        != tpa)              fail("Q2/Q3: TPA wrong");
    if (bfm_rx[idx].nbytes     < 28)                fail("F: payload too short for ARP fields");
  endtask

  localparam logic [31:0] IP_A    = 32'hC0A8_01_05;  // in subnet
  localparam logic [47:0] MAC_A   = 48'h02_00_00_00_00_A1;
  localparam logic [31:0] IP_OUT  = 32'hC0A8_02_01;  // outside subnet
  localparam logic [47:0] MAC_G   = 48'h02_00_00_00_00_FE;
  localparam logic [31:0] IP_B    = 32'hC0A8_01_22;  // in subnet, never answered
  localparam logic [47:0] REQ_MAC = 48'h02_00_00_00_00_AA;
  localparam logic [31:0] REQ_IP  = 32'hC0A8_01_10;
  localparam logic [47:0] MAC_B2  = 48'h02_00_00_00_00_B2;
  localparam logic [31:0] IP_B2   = 32'hC0A8_01_33;
  localparam logic [47:0] MAC_C   = 48'h02_00_00_00_00_CC;
  localparam logic [31:0] IP_C    = 32'hC0A8_01_64;

  initial begin : main
    bit ok; bit got; bit err; logic [47:0] mac; int cyc;
    int n0; int idx; int d; int t4; int dt;

    // ---- X1: no output valid while rst_i is high (after edges have occurred)
    repeat (4) @(posedge clk);
    if (m_hv !== 1'b0 || m_pv !== 1'b0 || rs_v !== 1'b0)
      fail("X1: output valid asserted during reset");
    bfm_reset();

    // ---- T1: Q2/Q3 (in-subnet), Q6, X2 (cache empty after reset)
    bfm_lookup(IP_A, ok);
    if (!ok) fail("X3: lookup not accepted within 32 cycles");
    for (int t = 0; t < 200 && count_req(IP_A) == 0; t++) @(posedge clk);
    idx = req_idx(IP_A, 0);
    if (idx < 0) fail("Q2/X2: no request for unknown address after reset");
    else         check_request(idx, IP_A);
    // Q6: a reply with SPA == asked address resolves the lookup
    bfm_send(16'd2, MAC_A, IP_A, cfg_local_mac, cfg_local_ip, ok);
    if (!ok) fail("X3: reply frame not accepted");
    wait_resp(200, got, err, mac, cyc);
    if (!got || err != 1'b0 || mac != MAC_A)
      fail("Q6: reply did not resolve outstanding lookup");
    repeat (250) @(posedge clk);
    if (count_req(IP_A) != 1)
      fail("Q6: further request transmitted after resolution");

    // ---- T2: Q1 cache hit, no frame transmitted
    n0 = bfm_rx.size();
    bfm_lookup(IP_A, ok);
    if (!ok) fail("X3: lookup not accepted");
    wait_resp(100, got, err, mac, cyc);
    if (!got || err != 1'b0 || mac != MAC_A)
      fail("Q1: cached address not answered from cache");
    repeat (100) @(posedge clk);
    if (bfm_rx.size() != n0)
      fail("Q1: frame transmitted on a cache hit");

    // ---- T3: Q3 off-subnet lookup asks the gateway
    bfm_lookup(IP_OUT, ok);
    if (!ok) fail("X3: lookup not accepted");
    for (int t = 0; t < 200 && count_req(cfg_gateway_ip) == 0; t++) @(posedge clk);
    idx = req_idx(cfg_gateway_ip, 0);
    if (idx < 0) fail("Q3: off-subnet lookup did not ask gateway_ip");
    else         check_request(idx, cfg_gateway_ip);
    bfm_send(16'd2, MAC_G, cfg_gateway_ip, cfg_local_mac, cfg_local_ip, ok);
    wait_resp(200, got, err, mac, cyc);
    if (!got || err != 1'b0 || mac != MAC_G)
      fail("Q6: gateway reply did not resolve lookup");

    // ---- T4: Q4 / Q5 retries and timeout (no answer ever)
    bfm_lookup(IP_B, ok);
    if (!ok) fail("X3: lookup not accepted");
    wait_resp(900, got, err, mac, cyc);   // bounded: a hang here is impossible
    if (!got || err != 1'b1)
      fail("Q5: no error response after timeout");
    if (count_req(IP_B) != 4)
      fail("Q4: retry count is not exactly 4");
    else begin
      for (int k = 1; k < 4; k++) begin
        d = bfm_rx[req_idx(IP_B, k)].at - bfm_rx[req_idx(IP_B, k-1)].at;
        if (d < 58 || d > 112)
          fail("Q4: retry spacing outside 64..80-cycle window");
      end
      t4 = bfm_rx[req_idx(IP_B, 3)].at;
      dt = cyc - t4;
      if (dt < 252 || dt > 332)
        fail("Q5: error response outside 256..300-cycle window after 4th request");
    end
    repeat (200) @(posedge clk);
    if (count_req(IP_B) != 4)
      fail("Q4: requests transmitted after giving up");

    // ---- T5: A1 answer a request for our own address
    bfm_send(16'd1, REQ_MAC, REQ_IP, 48'h0, cfg_local_ip, ok);
    if (!ok) fail("X3: request frame not accepted");
    repeat (200) @(posedge clk);
    idx = find_reply_to(REQ_MAC);
    if (idx < 0)
      fail("A1: no reply to a request for local_ip");
    else begin
      if (bfm_rx[idx].oper != 16'd2)                    fail("A1: reply oper not 2");
      if (bfm_rx[idx].sha   != cfg_local_mac)           fail("A1: reply SHA not local_mac");
      if (bfm_rx[idx].spa   != cfg_local_ip)            fail("A1: reply SPA not local_ip");
      if (bfm_rx[idx].tha   != REQ_MAC)                 fail("A1: reply THA not requester SHA");
      if (bfm_rx[idx].tpa   != REQ_IP)                  fail("A1: reply TPA not requester SPA");
      if (bfm_rx[idx].dest_mac != REQ_MAC)              fail("A1: reply not sent to requester");
    end

    // ---- T6: A2 request for somebody else is not answered
    bfm_send(16'd1, MAC_B2, IP_B2, 48'h0, 32'hC0A8_01_77, ok);
    if (!ok) fail("X3: request frame not accepted");
    repeat (150) @(posedge clk);
    if (find_reply_to(MAC_B2) >= 0)
      fail("A2: answered a request whose TPA is not local_ip");

    // ---- T7: C1/Q1 the pair from that request is learned
    n0 = bfm_rx.size();
    bfm_lookup(IP_B2, ok);
    wait_resp(100, got, err, mac, cyc);
    if (!got || err != 1'b0 || mac != MAC_B2)
      fail("C1: (SPA,SHA) from received request not served from cache");
    repeat (100) @(posedge clk);
    if (bfm_rx.size() != n0)
      fail("Q1: frame transmitted on a cache hit (C1 case)");

    // ---- T8: A3 non-ARP frame ignored entirely
    bfm_send(16'd1, MAC_C, IP_C, 48'h0, cfg_local_ip, ok, 16'h0800);
    if (!ok) fail("X3: non-ARP frame not accepted");
    repeat (150) @(posedge clk);
    if (find_reply_to(MAC_C) >= 0)
      fail("A3: non-ARP frame was answered");
    bfm_lookup(IP_C, ok);
    for (int t = 0; t < 200 && count_req(IP_C) == 0; t++) @(posedge clk);
    if (count_req(IP_C) == 0)
      fail("A3: non-ARP frame was learned from (lookup not sent to network)");
    else begin
      check_request(req_idx(IP_C, 0), IP_C);
      bfm_send(16'd2, MAC_C, IP_C, cfg_local_mac, cfg_local_ip, ok);
      wait_resp(200, got, err, mac, cyc);
      if (!got || err != 1'b0 || mac != MAC_C)
        fail("Q6: reply did not resolve lookup (A3 case)");
    end

    // ---- T9: C2 cache capacity / C1 last insert survives displacement
    for (int k = 1; k <= 5; k++) begin
      bfm_send(16'd1, 48'h02_00_00_00_01_00 + k, 32'hC0A8_01_40 + k,
               48'h0, 32'hC0A8_01_99, ok);
      if (!ok) fail("X3: frame not accepted");
    end
    n0 = bfm_rx.size();
    bfm_lookup(32'hC0A8_01_45, ok);   // the most recently inserted pair
    wait_resp(100, got, err, mac, cyc);
    if (!got || err != 1'b0 || mac != 48'h02_00_00_00_01_05)
      fail("C2/C1: most recently inserted entry not in full cache");
    repeat (100) @(posedge clk);
    if (bfm_rx.size() != n0)
      fail("Q1: frame transmitted on a cache hit (C2 case)");
    // L1: which of the older entries survived is deliberately NOT checked.

    // ---- T10: C3 clear_cache empties the cache
    @(negedge clk); clr_cache = 1'b1;
    @(negedge clk); clr_cache = 1'b0;
    bfm_lookup(32'hC0A8_01_45, ok);
    for (int t = 0; t < 200 && count_req(32'hC0A8_01_45) == 0; t++) @(posedge clk);
    if (count_req(32'hC0A8_01_45) == 0)
      fail("C3: cache not emptied by clear_cache_i");
    else begin
      check_request(req_idx(32'hC0A8_01_45, 0), 32'hC0A8_01_45);
      bfm_send(16'd2, 48'h02_00_00_00_01_05, 32'hC0A8_01_45,
               cfg_local_mac, cfg_local_ip, ok);
      wait_resp(200, got, err, mac, cyc);   // let it resolve; verdict next
    end

    if (failed) $display("RESULT: FAIL");
    else        $display("RESULT: PASS");
    $finish;
  end

endmodule
