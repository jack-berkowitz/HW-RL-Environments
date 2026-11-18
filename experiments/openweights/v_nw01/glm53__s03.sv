module arp_engine_tb;
  // ---------------------------------------------------------------------------
  // PROVIDED PLUMBING
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
  // TESTBENCH CHECKING CODE
  // ---------------------------------------------------------------------------
  int hdr_events;                       // count of header handshakes on m_hdr
  always @(posedge clk) if (!rst && m_hv && m_hr) hdr_events <= hdr_events + 1;

  bit  t_ok, t_got, t_err;
  logic [47:0] t_mac;
  int  t_idx, t_sz0, t_prev, t_d, t_cyc, t_base, t_baseh;
  logic [31:0] t_tgt;
  bfm_frame_t t_fr;

  task automatic fail_now(input string why);
    $display("FAIL: %s", why);
    $display("RESULT: FAIL");
    $finish;
  endtask

  // wait for a new complete frame to appear at index `base` in bfm_rx
  task automatic wait_frame(input int base, input int limit, output bit got, output int idx);
    got = 1'b0; idx = base;
    for (int t = 0; t < limit; t++) begin
      @(posedge clk);
      if (bfm_rx.size() > base) begin got = 1'b1; break; end
    end
    if (!got && bfm_rx.size() > base) got = 1'b1;  // settle same-edge race
  endtask

  // wait for a response; reports the bfm_cycle at which it was seen
  task automatic wait_resp(input int limit, output bit got, output bit err,
                          output logic [47:0] mac, output int cyc);
    got = 1'b0; err = 1'b0; mac = '0; cyc = 0;
    for (int t = 0; t < limit; t++) begin
      @(posedge clk);
      if (rs_v) begin got = 1'b1; err = rs_e; mac = rs_mac; cyc = bfm_cycle; break; end
    end
  endtask

  // check a captured frame is a well-formed ARP request for `tpa` (Q2/Q3/F)
  task automatic chk_req_fields(input int idx, input logic [31:0] tpa);
    bfm_frame_t f;
    f = bfm_rx[idx];
    if (f.dest_mac !== 48'hFFFF_FFFF_FFFF) fail_now("Q2: request not broadcast");
    if (f.eth_type  !== 16'h0806)         fail_now("F/Q2: request eth_type not 0x0806");
    if (f.htype     !== 16'h0001)         fail_now("F: hardware type");
    if (f.ptype     !== 16'h0800)         fail_now("F: protocol type");
    if (f.hlen      !== 8'd6)             fail_now("F: hardware length");
    if (f.plen      !== 8'd4)             fail_now("F: protocol length");
    if (f.oper      !== 16'd1)            fail_now("Q2: operation not request");
    if (f.sha       !== cfg_local_mac)    fail_now("Q2: SHA not local_mac");
    if (f.spa       !== cfg_local_ip)     fail_now("Q2: SPA not local_ip");
    if (f.tha       !== 48'h0)            fail_now("Q2: THA not zero");
    if (f.tpa       !== tpa)              fail_now("Q3: TPA is not the address asked for");
    if (f.nbytes    != 28)                fail_now("F: request payload not 28 bytes");
  endtask

  initial begin
    bfm_reset();
    $display("TB: reset done");

    // ---- X1: no output valid while rst_i high (after the first edge) --------
    @(negedge clk); rst = 1'b1;
    @(posedge clk);                       // first edge with rst high
    repeat (3) begin
      @(posedge clk);
      if (rs_v !== 1'b0 || m_hv !== 1'b0 || m_pv !== 1'b0)
        fail_now("X1: output valid asserted during reset");
    end
    @(negedge clk); rst = 1'b0;
    repeat (3) @(posedge clk);

    // ---- X2 + Q2 + Q4 + Q5: fresh on-subnet lookup, no answer --------------
    t_tgt  = 32'hC0A8_0133;               // on local /24, unknown
    t_base = bfm_rx.size();
    t_baseh = hdr_events;
    bfm_lookup(t_tgt, t_ok);
    if (!t_ok) fail_now("X3: lookup not accepted within 32 cycles");
    wait_frame(t_base, 200, t_got, t_idx);
    if (!t_got) fail_now("X2/Q2: no ARP request after lookup of unknown address");
    chk_req_fields(t_idx, t_tgt);
    for (int k = 1; k < 4; k++) begin
      t_prev = bfm_rx[bfm_rx.size()-1].at;
      t_sz0  = bfm_rx.size();
      wait_frame(t_sz0, 200, t_got, t_idx);
      if (!t_got) fail_now("Q4: fewer than 4 requests transmitted");
      t_d = bfm_rx[t_sz0].at - t_prev;
      if (t_d < 58 || t_d > 86) fail_now("Q4: retry spacing outside 64-80 cycle window");
      chk_req_fields(t_sz0, t_tgt);
    end
    t_prev = bfm_rx[bfm_rx.size()-1].at;  // cycle of 4th request header
    wait_resp(420, t_got, t_err, t_mac, t_cyc);
    if (!t_got)      fail_now("Q5: no error response after 4 unanswered requests");
    if (!t_err)      fail_now("Q5: response after timeout has error flag low");
    t_d = t_cyc - t_prev;
    if (t_d < 250 || t_d > 310) fail_now("Q5: error response not 256-300 cycles after 4th request");
    bfm_wait(200);
    if (bfm_rx.size() != 4 || hdr_events != t_baseh + 4)
      fail_now("Q4: request count is not exactly 4");
    $display("TB: Q2/Q4/Q5/X2 done");

    // ---- Q6: reply resolves outstanding lookup, no further request ---------
    t_tgt  = 32'hC0A8_0144;
    t_base = bfm_rx.size();
    bfm_lookup(t_tgt, t_ok);
    if (!t_ok) fail_now("X3: lookup not accepted");
    wait_frame(t_base, 200, t_got, t_idx);
    if (!t_got) fail_now("Q2: no request for outstanding lookup");
    chk_req_fields(t_idx, t_tgt);
    bfm_send(16'd2, 48'hAA_BB_CC_DD_EE_01, t_tgt, 48'h0, 32'h0, t_ok);
    if (!t_ok) fail_now("X3: reply frame not accepted");
    wait_resp(200, t_got, t_err, t_mac, t_cyc);
    if (!t_got || t_err) fail_now("Q6: reply did not resolve outstanding lookup");
    if (t_mac !== 48'hAA_BB_CC_DD_EE_01) fail_now("Q6: resolved MAC is not reply SHA");
    bfm_wait(200);
    if (bfm_rx.size() != t_base + 1) fail_now("Q6: further request after resolving reply");
    $display("TB: Q6 done");

    // ---- C1 + Q1: learned pair answered from cache, no frame ---------------
    t_base  = bfm_rx.size();
    t_baseh = hdr_events;
    bfm_lookup(t_tgt, t_ok);
    if (!t_ok) fail_now("X3: lookup not accepted");
    wait_resp(40, t_got, t_err, t_mac, t_cyc);
    if (!t_got || t_err) fail_now("Q1: cache hit not answered (C1: was the pair learned?)");
    if (t_mac !== 48'hAA_BB_CC_DD_EE_01) fail_now("Q1: cached MAC mismatch");
    bfm_wait(120);
    if (hdr_events != t_baseh) fail_now("Q1: frame transmitted on a cache-hit lookup");
    $display("TB: C1/Q1 done");

    // ---- Q3: off-subnet lookup asks for the gateway -------------------------
    t_tgt  = 32'hC0A8_0205;               // outside local /24
    t_base = bfm_rx.size();
    bfm_lookup(t_tgt, t_ok);
    if (!t_ok) fail_now("X3: lookup not accepted");
    wait_frame(t_base, 200, t_got, t_idx);
    if (!t_got) fail_now("Q2: no request for off-subnet lookup");
    chk_req_fields(t_idx, cfg_gateway_ip);   // fails with "Q3" if TPA wrong
    // resolve it via a reply naming the gateway, so no retry wait is needed
    bfm_send(16'd2, 48'h02_00_00_00_00_99, cfg_gateway_ip, 48'h0, 32'h0, t_ok);
    if (!t_ok) fail_now("X3: frame not accepted");
    wait_resp(200, t_got, t_err, t_mac, t_cyc);
    if (!t_got || t_err) fail_now("Q6: gateway reply did not resolve lookup");
    bfm_wait(150);
    if (bfm_rx.size() != t_base + 1) fail_now("Q6: extra request after resolution");
    $display("TB: Q3 done");

    // ---- A1: request for local IP is answered with a correct reply ----------
    t_base = bfm_rx.size();
    bfm_send(16'd1, 48'h03_00_00_00_00_10, 32'hC0A8_0177, 48'h0, cfg_local_ip, t_ok);
    if (!t_ok) fail_now("X3: request frame not accepted");
    wait_frame(t_base, 200, t_got, t_idx);
    if (!t_got) fail_now("A1: no reply to request whose TPA is local_ip");
    t_fr = bfm_rx[t_idx];
    if (t_fr.dest_mac !== 48'h03_00_00_00_00_10) fail_now("A1: reply dest_mac not requester SHA");
    if (t_fr.eth_type  !== 16'h0806)            fail_now("A1: reply eth_type");
    if (t_fr.oper      !== 16'd2)               fail_now("A1: reply operation not 2");
    if (t_fr.sha       !== cfg_local_mac)       fail_now("A1: reply SHA not local_mac");
    if (t_fr.spa       !== cfg_local_ip)        fail_now("A1: reply SPA not local_ip");
    if (t_fr.tha       !== 48'h03_00_00_00_00_10) fail_now("A1: reply THA not requester SHA");
    if (t_fr.tpa       !== 32'hC0A8_0177)       fail_now("A1: reply TPA not requester SPA");
    $display("TB: A1 done");

    // ---- A2: request for somebody else is not answered ----------------------
    t_baseh = hdr_events;
    bfm_send(16'd1, 48'h03_00_00_00_00_20, 32'hC0A8_0188, 48'h0, 32'hC0A8_0199, t_ok);
    if (!t_ok) fail_now("X3: frame not accepted");
    bfm_wait(250);
    if (hdr_events != t_baseh) fail_now("A2: replied to a request whose TPA is not local_ip");
    $display("TB: A2 done");

    // ---- A3: non-ARP frame ignored (not answered, not learned) -------------
    t_baseh = hdr_events;
    bfm_send(16'd1, 48'h03_00_00_00_00_30, 32'hC0A8_0166, 48'h0, cfg_local_ip,
             t_ok, 16'h0800);
    if (!t_ok) fail_now("X3: frame not accepted");
    bfm_wait(200);
    if (hdr_events != t_baseh) fail_now("A3: answered a frame whose eth_type is not 0x0806");
    // not learned either: a lookup of its SPA must go to the network (Q2)
    t_base = bfm_rx.size();
    bfm_lookup(32'hC0A8_0166, t_ok);
    if (!t_ok) fail_now("X3: lookup not accepted");
    wait_frame(t_base, 200, t_got, t_idx);
    if (!t_got) fail_now("A3/C1: learned from a non-ARP frame (answered from cache)");
    else        chk_req_fields(t_idx, 32'hC0A8_0166);
    wait_resp(800, t_got, t_err, t_mac, t_cyc);   // drain the doomed lookup
    if (!t_got || !t_err) fail_now("Q5: drained lookup did not time out with error");
    $display("TB: A3 done");

    // ---- C2: 5 inserts into a 4-entry cache; newest entry must survive -----
    for (int k = 1; k <= 5; k++) begin
      bfm_send(16'd2, 48'h0200_0011_0000 + k, 32'hC0A8_0150 + k, 48'h0, 32'h0, t_ok);
      if (!t_ok) fail_now("X3: frame not accepted");
      bfm_wait(4);
    end
    t_baseh = hdr_events;
    bfm_lookup(32'hC0A8_0155, t_ok);
    if (!t_ok) fail_now("X3: lookup not accepted");
    wait_resp(40, t_got, t_err, t_mac, t_cyc);
    if (!t_got || t_err) fail_now("C2: newest entry missing after insert into full cache");
    if (t_mac !== 48'h0200_0011_0005) fail_now("C2: newest entry has wrong MAC");
    bfm_wait(120);
    if (hdr_events != t_baseh) fail_now("Q1: frame transmitted on cache hit (C2)");
    $display("TB: C2 done");

    // ---- C3: clear_cache empties the cache ----------------------------------
    @(negedge clk); clr_cache = 1'b1;
    @(posedge clk);
    @(negedge clk); clr_cache = 1'b0;
    repeat (3) @(posedge clk);
    t_base = bfm_rx.size();
    bfm_lookup(32'hC0A8_0155, t_ok);
    if (!t_ok) fail_now("X3: lookup not accepted");
    wait_frame(t_base, 200, t_got, t_idx);
    if (!t_got) fail_now("C3: lookup still hits after clear_cache");
    else        chk_req_fields(t_idx, 32'hC0A8_0155);
    wait_resp(800, t_got, t_err, t_mac, t_cyc);   // drain
    if (!t_got || !t_err) fail_now("Q5: drained lookup did not time out with error");
    $display("TB: C3 done");

    $display("RESULT: PASS");
    $finish;
  end
endmodule
