module arp_engine_tb;

// ---------------------------------------------------------------------------
// PROVIDED PLUMBING (verbatim)
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
// TESTBENCH PROPER
// ---------------------------------------------------------------------------

  bit failed = 0;
  bit x1_bad = 0;

  // X1: while reset is high, no output valid may be asserted (from 1st edge on)
  always @(posedge clk) if (rst) begin
    if (m_hv || m_pv || rs_v) begin
      if (!x1_bad) begin
        x1_bad = 1; failed = 1;
        $display("FAIL: X1 - output valid asserted while rst_i high");
      end
    end
  end

  task automatic chk(input bit c, input string m);
    if (!c) begin failed = 1; $display("FAIL: %s", m); end
  endtask

  // wait until a new (complete) frame has been captured, or timeout
  task automatic wait_new(input int base_n, input int limit, output bit got);
    got = 1'b0;
    for (int t = 0; t < limit; t++) begin
      @(posedge clk);
      if (bfm_rx.size() > base_n) begin got = 1'b1; break; end
    end
  endtask

  // idle for n cycles; quiet==0 if any frame appeared
  task automatic idle(input int n, input int base_n, output bit quiet);
    quiet = 1'b1;
    repeat (n) @(posedge clk);
    if (bfm_rx.size() != base_n) quiet = 1'b0;
  endtask

  bit ok, got, err, quiet, rdone, rerr;
  bit got2, err2;
  logic [47:0] mac, mac2;
  int took, took2;
  int base, nreq, rtime, nmiss;
  int rc [8];
  bfm_frame_t fr;

  logic [47:0] SHA_X, SHA_Y, SHA_Z, SHA_W, GW_MAC;
  logic [31:0] IP_X, IP_Y, IP_Z, IP_M, IP_W, IP_OUT;
  logic [47:0] P_SHA [0:4];
  logic [31:0] P_IP  [0:4];

  initial begin
    SHA_X = 48'h02_00_00_00_00_11; IP_X = 32'hC0A8_0111;
    SHA_Y = 48'h02_00_00_00_00_12; IP_Y = 32'hC0A8_0112;
    SHA_Z = 48'h02_00_00_00_00_13; IP_Z = 32'hC0A8_0113;
    SHA_W = 48'h02_00_00_00_00_14; IP_W = 32'hC0A8_0114;
    GW_MAC = 48'h02_00_00_00_00_FE;
    IP_M   = 32'hC0A8_01AA;                 // inside local /24
    IP_OUT = 32'h0808_0808;                  // outside local /24
    for (int k = 0; k < 5; k++) begin
      P_SHA[k] = 48'h02_00_00_00_02_00 + k;
      P_IP[k]  = 32'hC0A8_0121 + k;
    end

    bfm_reset(6);

    // ---------------- A1: answer a request for our IP ----------------
    base = bfm_rx.size();
    bfm_send(16'h0001, SHA_X, IP_X, 48'h0, cfg_local_ip, ok);
    chk(ok, "X3 - request frame not accepted");
    wait_new(base, 200, got);
    chk(got, "A1 - no reply to request whose TPA == local_ip");
    if (got) begin
      fr = bfm_rx[$];
      chk(fr.eth_type == 16'h0806, "A1/F - reply eth_type != 0x0806");
      chk(fr.oper    == 16'h0002, "A1 - reply oper != 2");
      chk(fr.sha     == cfg_local_mac, "A1 - reply SHA != local_mac");
      chk(fr.spa     == cfg_local_ip,  "A1 - reply SPA != local_ip");
      chk(fr.tha     == SHA_X, "A1 - reply THA != requester SHA");
      chk(fr.tpa     == IP_X,  "A1 - reply TPA != requester SPA");
      chk(fr.dest_mac== SHA_X, "A1 - reply dest_mac != requester SHA");
      chk(fr.nbytes  == 28,    "F - reply payload not 28 bytes");
    end

    // ---------------- Q1/C1: learned from the request, hit, no frame ----
    base = bfm_rx.size();
    bfm_lookup(IP_X, ok);
    chk(ok, "X3 - lookup not accepted");
    bfm_await(32, got, err, mac, took);
    chk(got && !err && (mac == SHA_X), "Q1/C1 - cache hit for address learned from request");
    idle(60, base, quiet);
    chk(quiet, "Q1 - frame transmitted on a cache hit");

    // ---------------- A2: request not for us is not answered ------------
    base = bfm_rx.size();
    bfm_send(16'h0001, SHA_Y, IP_Y, 48'h0, 32'hC0A8_0199, ok);
    chk(ok, "X3 - frame not accepted (A2)");
    idle(150, base, quiet);
    chk(quiet, "A2 - answered a request whose TPA != local_ip");

    // ---------------- A3: non-ARP frame ignored entirely ----------------
    base = bfm_rx.size();
    bfm_send(16'h0001, SHA_Z, IP_Z, 48'h0, cfg_local_ip, ok, 16'h0800);
    chk(ok, "X3 - non-ARP frame not accepted");
    idle(100, base, quiet);
    chk(quiet, "A3 - non-ARP frame was answered");
    bfm_lookup(IP_Z, ok);
    chk(ok, "X3 - lookup not accepted (A3)");
    bfm_await(32, got, err, mac, took);
    chk(!got, "A3 - learned from a non-ARP frame");

    // ---------------- Q6: a reply resolves the outstanding lookup --------
    bfm_send(16'h0002, SHA_Z, IP_Z, cfg_local_mac, cfg_local_ip, ok);
    chk(ok, "X3 - resolving reply not accepted");
    bfm_await(200, got, err, mac, took);
    chk(got && !err && (mac == SHA_Z), "Q6 - reply with matching SPA did not resolve lookup");
    base = bfm_rx.size();
    idle(150, base, quiet);
    chk(quiet, "Q6 - further request transmitted after reply resolved lookup");

    // ---------------- Q2/Q3/Q4/Q5: unanswered lookup, in subnet --------
    base = bfm_rx.size();
    bfm_lookup(IP_M, ok);
    chk(ok, "X3 - lookup not accepted (Q2)");
    nreq = 0; rdone = 0; rerr = 0;
    for (int t = 0; t < 900; t++) begin
      @(posedge clk);
      if (bfm_rx.size() > base + nreq) begin
        fr = bfm_rx[base + nreq];
        if (nreq < 8) rc[nreq] = fr.at;
        nreq++;
      end
      if (!rdone && rs_v) begin rdone = 1; rerr = rs_e; rtime = bfm_cycle; end
    end
    chk(nreq == 4, "Q4 - number of request frames != 4");
    if (nreq >= 1) begin
      fr = bfm_rx[base];
      chk(fr.dest_mac == 48'hFFFF_FFFF_FFFF, "Q2 - request not broadcast");
      chk(fr.eth_type == 16'h0806, "Q2 - request eth_type != 0x0806");
      chk(fr.oper    == 16'h0001, "Q2 - request oper != 1");
      chk(fr.sha     == cfg_local_mac, "Q2 - request SHA != local_mac");
      chk(fr.spa     == cfg_local_ip,  "Q2 - request SPA != local_ip");
      chk(fr.tha     == 48'h0, "Q2 - request THA != 0");
      chk(fr.tpa     == IP_M,  "Q3 - in-subnet lookup did not ask for the address itself");
    end
    for (int k = 1; k < nreq && k < 8; k++)
      chk((rc[k] - rc[k-1] >= 64) && (rc[k] - rc[k-1] <= 80), "Q4 - retry spacing outside 64..80");
    chk(rdone, "Q5 - no response after timeout");
    if (rdone) chk(rerr, "Q5 - timeout response did not raise resp_error_o");
    if (rdone && nreq >= 4)
      chk((rtime - rc[3] >= 256) && (rtime - rc[3] <= 300), "Q5 - error response timing outside 256..300 after 4th request");
    bfm_wait(50);

    // ---------------- Q3/Q6: out-of-subnet asks the gateway -------------
    base = bfm_rx.size();
    bfm_lookup(IP_OUT, ok);
    chk(ok, "X3 - lookup not accepted (Q3 gateway)");
    wait_new(base, 100, got);
    chk(got, "Q2 - no request for out-of-subnet lookup");
    if (got) begin
      fr = bfm_rx[$];
      chk(fr.tpa == cfg_gateway_ip, "Q3 - out-of-subnet lookup did not ask for gateway");
    end
    bfm_send(16'h0002, GW_MAC, cfg_gateway_ip, cfg_local_mac, cfg_local_ip, ok);
    chk(ok, "X3 - gateway reply not accepted");
    bfm_await(200, got, err, mac, took);
    chk(got && !err && (mac == GW_MAC), "Q6 - gateway reply did not resolve lookup");
    base = bfm_rx.size();
    idle(150, base, quiet);
    chk(quiet, "Q6 - further request after gateway reply resolved lookup");

    // ---------------- C3: clear_cache empties the cache ------------------
    bfm_send(16'h0001, SHA_W, IP_W, 48'h0, cfg_local_ip, ok);
    chk(ok, "X3 - W request not accepted");
    base = bfm_rx.size();
    wait_new(base, 200, got);            // the A1 reply; frame fully processed
    bfm_lookup(IP_W, ok);
    chk(ok, "X3 - W lookup not accepted");
    bfm_await(32, got, err, mac, took);
    chk(got && !err && (mac == SHA_W), "C1 - W not learned from request");
    @(negedge clk); clr_cache = 1'b1;
    @(negedge clk); clr_cache = 1'b0;
    bfm_wait(2);
    base = bfm_rx.size();
    bfm_lookup(IP_W, ok);
    chk(ok, "X3 - lookup after clear not accepted");
    bfm_await(32, got, err, mac, took);
    chk(!got, "C3 - cache not cleared (address still answered)");
    wait_new(base, 100, got);
    chk(got, "C3/Q2 - no request transmitted after clear_cache");
    if (got) begin
      fr = bfm_rx[$];
      chk(fr.tpa == IP_W, "C3/Q2 - request after clear asked for wrong address");
    end
    bfm_send(16'h0002, SHA_W, IP_W, cfg_local_mac, cfg_local_ip, ok);
    bfm_await(200, got, err, mac, took);
    chk(got && !err && (mac == SHA_W), "Q6 - lookup after clear did not resolve");

    // ---------------- C2: capacity is exactly 4 ---------------------------
    for (int k = 0; k < 5; k++) begin
      bfm_send(16'h0001, P_SHA[k], P_IP[k], 48'h0, cfg_local_ip, ok);
      chk(ok, "X3 - capacity insert frame not accepted");
      base = bfm_rx.size();
      wait_new(base, 200, got);          // wait for the design's reply: frame processed
    end
    bfm_lookup(P_IP[4], ok);
    chk(ok, "X3 - lookup of last inserted not accepted");
    bfm_await(32, got, err, mac, took);
    chk(got && !err && (mac == P_SHA[4]), "C1/C2 - last inserted entry missing");
    nmiss = 0;
    for (int k = 0; k < 4; k++) begin
      bfm_lookup(P_IP[k], ok);
      chk(ok, "X3 - capacity probe lookup not accepted");
      bfm_await(32, got, err, mac, took);
      if (got && !err) begin
        chk(mac == P_SHA[k], "C1 - wrong MAC for surviving cache entry");
      end else begin
        nmiss++;
        bfm_send(16'h0002, P_SHA[k], P_IP[k], cfg_local_mac, cfg_local_ip, ok);
        bfm_await(200, got2, err2, mac2, took2);
        chk(got2 && !err2 && (mac2 == P_SHA[k]), "Q6 - capacity probe lookup did not resolve");
      end
    end
    chk(nmiss >= 1, "C2 - all 5 inserted addresses still cached (capacity > 4)");

    if (failed) $display("RESULT: FAIL");
    else        $display("RESULT: PASS");
    $finish;
  end

endmodule
