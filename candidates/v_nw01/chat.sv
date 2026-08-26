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
  logic [47:0] bfm_pdm, bfm_psm;
  logic [15:0] bfm_pet;
  int bfm_pat;

  always @(posedge clk) if (!rst) begin
    if (m_hv && m_hr) begin
      bfm_pdm = m_dm;
      bfm_psm = m_sm;
      bfm_pet = m_et;
      bfm_pat = bfm_cycle;
    end
    if (m_pv && m_pr) begin
      bfm_buf.push_back(m_pd);
      if (m_pl) begin
        automatic bfm_frame_t f;
        f.dest_mac = bfm_pdm;
        f.src_mac = bfm_psm;
        f.eth_type = bfm_pet;
        f.at = bfm_pat;
        f.nbytes = bfm_buf.size();
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
    begin
      bit took = 1'b0;
      for (int t=0;t<limit;t++) begin
        @(posedge clk);
        if (s_hr) begin took=1'b1; break; end
      end
      if (!took) ok = 1'b0;
    end
    @(negedge clk) s_hv = 1'b0;
    if (!ok) return;
    for (int i=0;i<28;i++) begin
      bit took = 1'b0;
      @(negedge clk); s_pd = p[i]; s_pl = (i==27); s_pv = 1'b1;
      for (int t=0;t<limit;t++) begin
        @(posedge clk);
        if (s_pr) begin took=1'b1; break; end
      end
      @(negedge clk) s_pv = 1'b0;
      s_pl = 1'b0;
      if (!took) begin ok = 1'b0; return; end
    end
  endtask

  task automatic bfm_lookup(input logic [31:0] ip, output bit ok, input int limit = 32);
    ok = 1'b0;
    @(negedge clk); rq_ip = ip; rq_v = 1'b1;
    for (int t=0;t<limit;t++) begin
      @(posedge clk);
      if (rq_r) begin ok = 1'b1; break; end
    end
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

  // ---------------------------------------------------------------------------
  // Testbench bookkeeping and monitors.
  // ---------------------------------------------------------------------------
  typedef struct packed {
    logic        err;
    logic [47:0] mac;
    int          at;
  } tb_resp_t;

  tb_resp_t tb_resp_q [$];
  tb_resp_t tb_resp_sample;
  int tb_tx_hdr_at [$];
  int tb_req_at [$];
  int tb_last_rx_done = -1;
  int tb_errors = 0;

  always @(posedge clk) if (!rst && rs_v && rs_r) begin
    tb_resp_sample.err = rs_e;
    tb_resp_sample.mac = rs_mac;
    tb_resp_sample.at  = bfm_cycle;
    tb_resp_q.push_back(tb_resp_sample);
  end

  always @(posedge clk) if (!rst && m_hv && m_hr)
    tb_tx_hdr_at.push_back(bfm_cycle);

  always @(posedge clk) if (!rst && rq_v && rq_r)
    tb_req_at.push_back(bfm_cycle);

  always @(posedge clk) if (!rst && s_pv && s_pr && s_pl)
    tb_last_rx_done = bfm_cycle;

  task automatic tb_fail(input string clause_name, input string why);
    tb_errors = tb_errors + 1;
    $display("FAIL[%s]: %s", clause_name, why);
  endtask

  task automatic tb_clear_observed;
    bfm_rx.delete();
    bfm_buf.delete();
    tb_resp_q.delete();
    tb_tx_hdr_at.delete();
    tb_req_at.delete();
    tb_last_rx_done = -1;
  endtask

  task automatic tb_fresh_reset;
    bfm_reset(6);
    @(negedge clk);
    tb_clear_observed();
  endtask

  task automatic tb_checked_reset(input int cycles);
    int i;
    @(negedge clk);
    rst = 1'b1;
    for (i = 0; i < cycles; i = i + 1) begin
      @(posedge clk);
      @(negedge clk);
      if (m_hv !== 1'b0)
        tb_fail("X1", "m_hdr_valid_o asserted while reset was high");
      if (m_pv !== 1'b0)
        tb_fail("X1", "m_payload_valid_o asserted while reset was high");
      if (rs_v !== 1'b0)
        tb_fail("X1", "resp_valid_o asserted while reset was high");
    end
    rst = 1'b0;
    repeat (3) @(posedge clk);
    @(negedge clk);
  endtask

  task automatic tb_wait_cycles(input int n);
    int i;
    for (i = 0; i < n; i = i + 1) begin
      @(posedge clk);
      @(negedge clk);
    end
  endtask

  task automatic tb_wait_frame_count(input int want, input int limit, output bit got);
    int i;
    got = 1'b0;
    if (bfm_rx.size() >= want) begin
      got = 1'b1;
      return;
    end
    for (i = 0; i < limit; i = i + 1) begin
      @(posedge clk);
      @(negedge clk);
      if (bfm_rx.size() >= want) begin
        got = 1'b1;
        return;
      end
    end
  endtask

  task automatic tb_wait_resp_count(input int want, input int limit, output bit got);
    int i;
    got = 1'b0;
    if (tb_resp_q.size() >= want) begin
      got = 1'b1;
      return;
    end
    for (i = 0; i < limit; i = i + 1) begin
      @(posedge clk);
      @(negedge clk);
      if (tb_resp_q.size() >= want) begin
        got = 1'b1;
        return;
      end
    end
  endtask

  task automatic tb_check_arp_frame(input bfm_frame_t f,
                                    input string clause_name,
                                    input logic [47:0] exp_dest,
                                    input logic [15:0] exp_oper,
                                    input logic [47:0] exp_sha,
                                    input logic [31:0] exp_spa,
                                    input logic [47:0] exp_tha,
                                    input logic [31:0] exp_tpa);
    if (f.nbytes != 28)
      tb_fail("F", $sformatf("%s: payload length %0d, expected 28", clause_name, f.nbytes));
    if (f.eth_type !== 16'h0806)
      tb_fail("F", $sformatf("%s: eth_type %04h, expected 0806", clause_name, f.eth_type));
    if (f.htype !== 16'h0001)
      tb_fail("F", $sformatf("%s: htype %04h, expected 0001", clause_name, f.htype));
    if (f.ptype !== 16'h0800)
      tb_fail("F", $sformatf("%s: ptype %04h, expected 0800", clause_name, f.ptype));
    if (f.hlen !== 8'd6)
      tb_fail("F", $sformatf("%s: hlen %0d, expected 6", clause_name, f.hlen));
    if (f.plen !== 8'd4)
      tb_fail("F", $sformatf("%s: plen %0d, expected 4", clause_name, f.plen));
    if (f.dest_mac !== exp_dest)
      tb_fail(clause_name, $sformatf("dest MAC %012h, expected %012h", f.dest_mac, exp_dest));
    if (f.oper !== exp_oper)
      tb_fail(clause_name, $sformatf("operation %0d, expected %0d", f.oper, exp_oper));
    if (f.sha !== exp_sha)
      tb_fail(clause_name, $sformatf("SHA %012h, expected %012h", f.sha, exp_sha));
    if (f.spa !== exp_spa)
      tb_fail(clause_name, $sformatf("SPA %08h, expected %08h", f.spa, exp_spa));
    if (f.tha !== exp_tha)
      tb_fail(clause_name, $sformatf("THA %012h, expected %012h", f.tha, exp_tha));
    if (f.tpa !== exp_tpa)
      tb_fail(clause_name, $sformatf("TPA %08h, expected %08h", f.tpa, exp_tpa));
  endtask

  task automatic tb_expect_hit(input logic [31:0] ip,
                               input logic [47:0] exp_mac,
                               input string source_clause);
    bit ok;
    bit got;
    int accept_at;
    int delta;
    tb_resp_t r;

    tb_clear_observed();
    bfm_lookup(ip, ok, 32);
    if (!ok) begin
      tb_fail("X3", $sformatf("cached lookup %08h was not accepted within 32 cycles", ip));
      return;
    end
    if (tb_req_at.size() == 0) begin
      tb_fail("X3", "lookup acceptance was not observed by bookkeeping monitor");
      return;
    end
    accept_at = tb_req_at[0];
    tb_wait_resp_count(1, 40, got);
    if (!got) begin
      tb_fail($sformatf("%s/X3", source_clause),
              $sformatf("cached lookup %08h did not produce its required hit response within 32 cycles", ip));
      return;
    end
    r = tb_resp_q[0];
    delta = r.at - accept_at;
    if ((delta < 0) || (delta > 32))
      tb_fail("X3", $sformatf("cached lookup response latency was %0d cycles", delta));
    if (r.err !== 1'b0)
      tb_fail(source_clause, $sformatf("cached lookup %08h returned error", ip));
    if (r.mac !== exp_mac)
      tb_fail(source_clause, $sformatf("cached lookup %08h returned MAC %012h, expected %012h",
                                      ip, r.mac, exp_mac));
    tb_wait_cycles(100);
    if (tb_tx_hdr_at.size() != 0)
      tb_fail("Q1", $sformatf("cached lookup %08h transmitted %0d frame header(s)",
                              ip, tb_tx_hdr_at.size()));
  endtask

  task automatic tb_expect_first_request(input logic [31:0] lookup_ip,
                                         input logic [31:0] arp_target,
                                         input string clause_name,
                                         output int first_at);
    bit ok;
    bit got;
    bfm_frame_t f;

    first_at = -1;
    tb_clear_observed();
    bfm_lookup(lookup_ip, ok, 32);
    if (!ok) begin
      tb_fail("X3", $sformatf("lookup %08h was not accepted within 32 cycles", lookup_ip));
      return;
    end
    tb_wait_frame_count(1, 500, got);
    if (!got) begin
      tb_fail(clause_name, $sformatf("lookup %08h did not transmit an ARP request", lookup_ip));
      return;
    end
    f = bfm_rx[0];
    first_at = f.at;
    tb_check_arp_frame(f, clause_name, 48'hFF_FF_FF_FF_FF_FF, 16'd1,
                       cfg_local_mac, cfg_local_ip, 48'h00_00_00_00_00_00, arp_target);
  endtask

  // ---------------------------------------------------------------------------
  // Individual specification tests.
  // ---------------------------------------------------------------------------
  task automatic test_x1_reset_outputs;
    int i;
    for (i = 0; i < 4; i = i + 1) begin
      @(posedge clk);
      @(negedge clk);
      if (m_hv !== 1'b0)
        tb_fail("X1", "m_hdr_valid_o asserted while reset was high");
      if (m_pv !== 1'b0)
        tb_fail("X1", "m_payload_valid_o asserted while reset was high");
      if (rs_v !== 1'b0)
        tb_fail("X1", "resp_valid_o asserted while reset was high");
    end
    rst = 1'b0;
    tb_wait_cycles(3);
    tb_clear_observed();
  endtask

  task automatic test_a1_and_request_learning;
    bit ok;
    bit got;
    logic [47:0] peer_mac;
    logic [31:0] peer_ip;
    bfm_frame_t f;

    peer_mac = 48'h10_20_30_40_50_60;
    peer_ip  = 32'hC0A8_0122;
    tb_fresh_reset();
    bfm_send(16'd1, peer_mac, peer_ip, 48'h00_00_00_00_00_00, cfg_local_ip, ok);
    if (!ok) begin
      tb_fail("X3", "ARP request for local IP was not accepted within the receive liveness bound");
      return;
    end
    tb_wait_frame_count(1, 500, got);
    if (!got) begin
      tb_fail("A1", "request for local IP was not answered");
      return;
    end
    f = bfm_rx[0];
    tb_check_arp_frame(f, "A1", peer_mac, 16'd2,
                       cfg_local_mac, cfg_local_ip, peer_mac, peer_ip);
    tb_wait_cycles(60);
    if (tb_tx_hdr_at.size() != 1)
      tb_fail("A1", $sformatf("request for local IP caused %0d transmitted headers, expected one reply",
                              tb_tx_hdr_at.size()));
    tb_expect_hit(peer_ip, peer_mac, "C1");
  endtask

  task automatic test_a2_nonlocal_request_learns_but_no_reply;
    bit ok;
    logic [47:0] peer_mac;
    logic [31:0] peer_ip;
    logic [31:0] other_tpa;

    peer_mac  = 48'h20_21_22_23_24_25;
    peer_ip   = 32'hC0A8_0133;
    other_tpa = 32'hC0A8_01A5;
    tb_fresh_reset();
    bfm_send(16'd1, peer_mac, peer_ip, 48'h00_00_00_00_00_00, other_tpa, ok);
    if (!ok) begin
      tb_fail("X3", "ARP request for another IP was not accepted within the receive liveness bound");
      return;
    end
    tb_wait_cycles(300);
    if (tb_tx_hdr_at.size() != 0)
      tb_fail("A2", "ARP request whose TPA was not local_ip_i was answered");
    tb_expect_hit(peer_ip, peer_mac, "C1");
  endtask

  task automatic test_a3_nonarp_is_ignored;
    bit ok;
    int first_at;
    logic [47:0] peer_mac;
    logic [31:0] peer_ip;

    peer_mac = 48'h30_31_32_33_34_35;
    peer_ip  = 32'hC0A8_0144;
    tb_fresh_reset();
    bfm_send(16'd1, peer_mac, peer_ip, 48'h00_00_00_00_00_00, cfg_local_ip,
             ok, 16'h0800, 32);
    if (!ok) begin
      tb_fail("X3", "non-ARP frame was not accepted within the receive liveness bound");
      return;
    end
    tb_wait_cycles(300);
    if (tb_tx_hdr_at.size() != 0)
      tb_fail("A3", "non-ARP frame caused a transmitted frame");
    tb_expect_first_request(peer_ip, peer_ip, "A3", first_at);
    tb_fresh_reset();
  endtask

  task automatic test_c1_reply_learning_and_q1;
    bit ok;
    logic [47:0] peer_mac;
    logic [31:0] peer_ip;

    peer_mac = 48'h40_41_42_43_44_45;
    peer_ip  = 32'hC0A8_0155;
    tb_fresh_reset();
    bfm_send(16'd2, peer_mac, peer_ip, cfg_local_mac, cfg_local_ip, ok);
    if (!ok) begin
      tb_fail("X3", "ARP reply was not accepted within the receive liveness bound");
      return;
    end
    tb_expect_hit(peer_ip, peer_mac, "C1");
  endtask

  task automatic test_c2_cache_capacity;
    logic [31:0] ips [5];
    logic [47:0] macs [5];
    bit ok;
    bit got;
    bit saw_missing;
    int i;
    int err_before;
    tb_resp_t r;

    ips[0] = 32'hC0A8_0161; macs[0] = 48'h50_00_00_00_00_61;
    ips[1] = 32'hC0A8_0162; macs[1] = 48'h50_00_00_00_00_62;
    ips[2] = 32'hC0A8_0163; macs[2] = 48'h50_00_00_00_00_63;
    ips[3] = 32'hC0A8_0164; macs[3] = 48'h50_00_00_00_00_64;
    ips[4] = 32'hC0A8_0165; macs[4] = 48'h50_00_00_00_00_65;

    // Four inserts must all fit; no replacement choice is involved yet.
    tb_fresh_reset();
    for (i = 0; i < 4; i = i + 1) begin
      bfm_send(16'd2, macs[i], ips[i], cfg_local_mac, cfg_local_ip, ok);
      if (!ok) begin
        tb_fail("X3", "ARP reply was not accepted while filling four-entry cache");
        return;
      end
    end
    for (i = 0; i < 4; i = i + 1) begin
      err_before = tb_errors;
      tb_expect_hit(ips[i], macs[i], "C2");
      if (tb_errors != err_before) begin
        tb_fresh_reset();
        return;
      end
    end

    // After a fifth insert, the just-inserted entry must exist, while at least
    // one of the previous four must no longer hit.  We deliberately do not
    // require WHICH old entry was displaced (L1).
    tb_fresh_reset();
    for (i = 0; i < 5; i = i + 1) begin
      bfm_send(16'd2, macs[i], ips[i], cfg_local_mac, cfg_local_ip, ok);
      if (!ok) begin
        tb_fail("X3", "ARP reply was not accepted while testing full cache");
        return;
      end
    end
    err_before = tb_errors;
    tb_expect_hit(ips[4], macs[4], "C1/C2");
    if (tb_errors != err_before) begin
      tb_fresh_reset();
      return;
    end

    saw_missing = 1'b0;
    for (i = 0; i < 4; i = i + 1) begin
      tb_clear_observed();
      bfm_lookup(ips[i], ok, 32);
      if (!ok) begin
        tb_fail("X3", "lookup was not accepted while checking cache capacity");
        return;
      end
      tb_wait_resp_count(1, 40, got);
      if (got) begin
        r = tb_resp_q[0];
        if ((r.err === 1'b0) && (r.mac === macs[i])) begin
          if (tb_tx_hdr_at.size() != 0)
            tb_fail("Q1", "cache hit transmitted a frame during capacity test");
        end else begin
          saw_missing = 1'b1;
          break;
        end
      end else begin
        saw_missing = 1'b1;
        break;
      end
    end
    if (!saw_missing)
      tb_fail("C2", "all five learned entries still hit; cache capacity must be exactly four");
    tb_fresh_reset();
  endtask

  task automatic test_c3_clear_cache;
    bit ok;
    int first_at;
    logic [47:0] peer_mac;
    logic [31:0] peer_ip;

    peer_mac = 48'h60_61_62_63_64_65;
    peer_ip  = 32'hC0A8_0171;
    tb_fresh_reset();
    bfm_send(16'd2, peer_mac, peer_ip, cfg_local_mac, cfg_local_ip, ok);
    if (!ok) begin
      tb_fail("X3", "ARP reply was not accepted before clear-cache test");
      return;
    end
    tb_expect_hit(peer_ip, peer_mac, "C1");

    @(negedge clk);
    clr_cache = 1'b1;
    @(posedge clk);
    @(negedge clk);
    clr_cache = 1'b0;
    tb_wait_cycles(2);

    tb_expect_first_request(peer_ip, peer_ip, "C3", first_at);
    tb_fresh_reset();
  endtask

  task automatic test_q2_q3_local_miss;
    int first_at;
    logic [31:0] ip;

    ip = 32'hC0A8_017A;
    tb_fresh_reset();
    tb_expect_first_request(ip, ip, "Q2/Q3", first_at);
    tb_fresh_reset();
  endtask

  task automatic test_q3_gateway_miss;
    int first_at;
    logic [31:0] ip;

    ip = 32'h0A01_0203;
    tb_fresh_reset();
    tb_expect_first_request(ip, cfg_gateway_ip, "Q3", first_at);
    tb_fresh_reset();
  endtask

  task automatic test_q6_resolution_and_no_more_requests;
    bit ok;
    bit got;
    int first_at;
    int correct_reply_done;
    int i;
    logic [31:0] target_ip;
    logic [47:0] target_mac;
    tb_resp_t r;

    target_ip  = 32'hC0A8_0188;
    target_mac = 48'h70_71_72_73_74_75;
    tb_fresh_reset();
    tb_expect_first_request(target_ip, target_ip, "Q2/Q6", first_at);
    if (first_at < 0) begin
      tb_fresh_reset();
      return;
    end

    // A matching reply must resolve it with SHA as the response MAC.
    bfm_send(16'd2, target_mac, target_ip, cfg_local_mac, cfg_local_ip, ok);
    if (!ok) begin
      tb_fail("X3", "matching ARP reply was not accepted");
      tb_fresh_reset();
      return;
    end
    correct_reply_done = tb_last_rx_done;
    tb_wait_resp_count(1, 400, got);
    if (!got) begin
      tb_fail("Q6", "matching ARP reply did not resolve outstanding lookup");
    end else begin
      r = tb_resp_q[0];
      if (r.err !== 1'b0)
        tb_fail("Q6", "matching ARP reply produced an error response");
      if (r.mac !== target_mac)
        tb_fail("Q6", $sformatf("matching ARP reply returned MAC %012h, expected %012h",
                                r.mac, target_mac));
    end

    // Any request whose header handshakes after the matching reply was fully
    // received violates "No further request is transmitted".  Waiting more
    // than the maximum retry spacing is enough to expose another retry.
    tb_wait_cycles(100);
    for (i = 0; i < tb_tx_hdr_at.size(); i = i + 1) begin
      if (tb_tx_hdr_at[i] > correct_reply_done)
        tb_fail("Q6", $sformatf("ARP request transmitted at cycle %0d after matching reply completed at %0d",
                                tb_tx_hdr_at[i], correct_reply_done));
    end
    tb_fresh_reset();
  endtask

  task automatic test_q4_q5_retries_and_timeout;
    bit ok;
    int i;
    int gap;
    int dt;
    logic [31:0] ip;
    bfm_frame_t f;
    tb_resp_t r;

    ip = 32'hC0A8_01B0;
    tb_fresh_reset();
    tb_clear_observed();
    bfm_lookup(ip, ok, 32);
    if (!ok) begin
      tb_fail("X3", "unanswered lookup was not accepted within 32 cycles");
      return;
    end

    // Long enough for 4 retries plus the specified post-fourth timeout, with
    // substantial margin, while still being fully bounded.
    tb_wait_cycles(1200);

    if (tb_tx_hdr_at.size() != 4)
      tb_fail("Q4", $sformatf("unanswered lookup transmitted %0d request headers, expected exactly 4",
                              tb_tx_hdr_at.size()));
    if (bfm_rx.size() != 4)
      tb_fail("Q4/F", $sformatf("unanswered lookup completed %0d transmitted frame(s), expected 4",
                                bfm_rx.size()));

    for (i = 0; (i < bfm_rx.size()) && (i < 4); i = i + 1) begin
      f = bfm_rx[i];
      tb_check_arp_frame(f, "Q2/Q4", 48'hFF_FF_FF_FF_FF_FF, 16'd1,
                         cfg_local_mac, cfg_local_ip, 48'h00_00_00_00_00_00, ip);
    end

    if (tb_tx_hdr_at.size() >= 4) begin
      for (i = 1; i < 4; i = i + 1) begin
        gap = tb_tx_hdr_at[i] - tb_tx_hdr_at[i-1];
        if ((gap < 64) || (gap > 80))
          tb_fail("Q4", $sformatf("request %0d to %0d spacing was %0d cycles; required 64..80",
                                  i, i+1, gap));
      end
    end

    if (tb_resp_q.size() == 0) begin
      tb_fail("Q5", "unanswered lookup produced no timeout response");
    end else begin
      r = tb_resp_q[0];
      if (r.err !== 1'b1)
        tb_fail("Q5", "unanswered lookup timeout response did not assert resp_error_o");
      if (tb_tx_hdr_at.size() >= 4) begin
        dt = r.at - tb_tx_hdr_at[3];
        if ((dt < 256) || (dt > 300))
          tb_fail("Q5", $sformatf("timeout response arrived %0d cycles after fourth request; required 256..300",
                                  dt));
      end
      if (tb_resp_q.size() != 1)
        tb_fail("Q5", $sformatf("unanswered lookup produced %0d response handshakes, expected one",
                                tb_resp_q.size()));
    end
  endtask

  task automatic test_x2_reset_clears_cache_and_outstanding;
    bit ok;
    int first_at;
    logic [47:0] peer_mac;
    logic [31:0] peer_ip;

    peer_mac = 48'h80_81_82_83_84_85;
    peer_ip  = 32'hC0A8_01C1;

    // First prove the entry exists.
    tb_fresh_reset();
    bfm_send(16'd2, peer_mac, peer_ip, cfg_local_mac, cfg_local_ip, ok);
    if (!ok) begin
      tb_fail("X3", "ARP reply was not accepted before reset-state test");
      return;
    end
    tb_expect_hit(peer_ip, peer_mac, "C1");

    // Reset must empty the cache, so the same address now misses.
    tb_fresh_reset();
    tb_expect_first_request(peer_ip, peer_ip, "X2", first_at);
    if (first_at < 0) begin
      tb_fresh_reset();
      return;
    end

    // Reset while that lookup is outstanding.  After reset, no retry or old
    // timeout response is allowed to reappear.
    tb_checked_reset(6);
    tb_clear_observed();
    tb_wait_cycles(350);
    if (tb_tx_hdr_at.size() != 0)
      tb_fail("X2", "pre-reset outstanding lookup resumed transmitting after reset");
    if (tb_resp_q.size() != 0)
      tb_fail("X2", "pre-reset outstanding lookup produced a response after reset");
  endtask

  // ---------------------------------------------------------------------------
  // Main sequence and bounded verdict.
  // ---------------------------------------------------------------------------
  initial begin
    test_x1_reset_outputs();
    test_a1_and_request_learning();
    test_a2_nonlocal_request_learns_but_no_reply();
    test_a3_nonarp_is_ignored();
    test_c1_reply_learning_and_q1();
    test_c2_cache_capacity();
    test_c3_clear_cache();
    test_q2_q3_local_miss();
    test_q3_gateway_miss();
    test_q6_resolution_and_no_more_requests();
    test_q4_q5_retries_and_timeout();
    test_x2_reset_clears_cache_and_outstanding();

    if (tb_errors == 0)
      $display("RESULT: PASS");
    else
      $display("RESULT: FAIL");
    $finish;
  end

  initial begin
    #8_000_000;
    $display("FAIL[TB]: watchdog fired before normal verdict");
    $display("RESULT: FAIL");
    $finish;
  end

endmodule