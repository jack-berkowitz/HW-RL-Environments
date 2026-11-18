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
  // MY TESTBENCH
  // ---------------------------------------------------------------------------

  bit tb_fail = 0;

  task automatic tb_check(input bit cond, input string msg);
    if (!cond) begin
      $display("FAIL: %s", msg);
      tb_fail = 1;
    end
  endtask

  task automatic tb_clear_cache();
    @(negedge clk); clr_cache = 1'b1;
    @(negedge clk); clr_cache = 1'b0;
    repeat (5) @(posedge clk);
  endtask

  task automatic tb_await_resp(input int limit, output bit got, output bit err,
                               output logic [47:0] mac, output int at_cycle);
    got = 0; err = 0; mac = 0; at_cycle = 0;
    for (int t = 0; t < limit; t++) begin
      @(posedge clk);
      if (rs_v) begin
        got = 1;
        err = rs_e;
        mac = rs_mac;
        at_cycle = bfm_cycle;
        break;
      end
    end
  endtask

  task automatic tb_do_lookup(input logic [31:0] ip, output bit got, output bit err,
                              output logic [47:0] mac, output int at_cycle);
    bit ok;
    bfm_lookup(ip, ok);
    if (!ok) begin
      $display("FAIL: lookup not accepted within 32 cycles");
      tb_fail = 1;
      got = 0; err = 0; mac = 0; at_cycle = 0;
      return;
    end
    tb_await_resp(2000, got, err, mac, at_cycle);
    if (!got) begin
      $display("FAIL: no response within 2000 cycles");
      tb_fail = 1;
    end
  endtask

  task automatic tb_insert(input logic [31:0] ip, input logic [47:0] mac);
    bit ok;
    bfm_send(16'h0001, mac, ip, 48'h0, 32'hC0A80199, ok);
    if (!ok) begin
      $display("FAIL: failed to insert entry");
      tb_fail = 1;
    end
    bfm_wait(10);
  endtask

  // X1: no output valid during reset
  always @(negedge clk) begin
    if (rst) begin
      if (m_hv || m_pv || rs_v) begin
        $display("FAIL: X1: output valid asserted during reset");
        tb_fail = 1;
      end
    end
  end

  initial begin
    bfm_reset();
    bfm_wait(10);

    // -----------------------------------------------------------------------
    // Q4 / Q5: cache miss inside subnet, retries and timeout
    // -----------------------------------------------------------------------
    begin
      bit got, err;
      logic [47:0] mac;
      int resp_cycle;
      int nreq;
      int req_at[4];
      int gap;
      int timeout;
      tb_clear_cache();
      bfm_rx.delete();
      tb_do_lookup(32'hC0A80132, got, err, mac, resp_cycle);
      tb_check(got, "Q5: no response for cache miss");
      tb_check(err, "Q5: response should be error for unanswered lookup");
      nreq = 0;
      foreach (bfm_rx[i]) begin
        if (bfm_rx[i].eth_type == 16'h0806 && bfm_rx[i].oper == 1) begin
          if (nreq < 4) req_at[nreq] = bfm_rx[i].at;
          nreq++;
        end
      end
      tb_check(nreq == 4, $sformatf("Q4: expected 4 requests, got %0d", nreq));
      if (nreq == 4) begin
        for (int i = 0; i < 3; i++) begin
          gap = req_at[i+1] - req_at[i];
          tb_check(gap >= 64 && gap <= 80, $sformatf("Q4: request spacing %0d not in [64,80]", gap));
        end
        timeout = resp_cycle - req_at[3];
        tb_check(timeout >= 256 && timeout <= 300, $sformatf("Q5: timeout %0d not in [256,300]", timeout));
      end
      foreach (bfm_rx[i]) begin
        if (bfm_rx[i].eth_type == 16'h0806 && bfm_rx[i].oper == 1) begin
          tb_check(bfm_rx[i].dest_mac == 48'hFF_FF_FF_FF_FF_FF, "Q2: request dest_mac not broadcast");
          tb_check(bfm_rx[i].src_mac == cfg_local_mac, "Q2: request src_mac");
          tb_check(bfm_rx[i].sha == cfg_local_mac, "Q2: request SHA");
          tb_check(bfm_rx[i].spa == cfg_local_ip, "Q2: request SPA");
          tb_check(bfm_rx[i].tha == 48'h0, "Q2: request THA");
          tb_check(bfm_rx[i].tpa == 32'hC0A80132, "Q3: request TPA should be looked-up IP (inside subnet)");
        end
      end
    end

    // -----------------------------------------------------------------------
    // Q3: outside subnet -> gateway
    // -----------------------------------------------------------------------
    begin
      bit got, err;
      logic [47:0] mac;
      int resp_cycle;
      int nreq;
      tb_clear_cache();
      bfm_rx.delete();
      tb_do_lookup(32'h0A000001, got, err, mac, resp_cycle);
      tb_check(got, "Q3: no response for outside lookup");
      tb_check(err, "Q3: expected error for unanswered outside lookup");
      nreq = 0;
      foreach (bfm_rx[i]) begin
        if (bfm_rx[i].eth_type == 16'h0806 && bfm_rx[i].oper == 1) begin
          tb_check(bfm_rx[i].tpa == cfg_gateway_ip, $sformatf("Q3: expected TPA=gateway %h, got %h", cfg_gateway_ip, bfm_rx[i].tpa));
          nreq++;
        end
      end
      tb_check(nreq == 4, $sformatf("Q3: expected 4 requests, got %0d", nreq));
    end

    // -----------------------------------------------------------------------
    // A1: answer ARP request for local IP
    // -----------------------------------------------------------------------
    begin
      bit ok;
      logic [47:0] req_sha;
      logic [31:0] req_spa;
      req_sha = 48'hAA_BB_CC_DD_EE_FF;
      req_spa = 32'hC0A80164;
      tb_clear_cache();
      bfm_rx.delete();
      bfm_send(16'h0001, req_sha, req_spa, 48'h0, cfg_local_ip, ok);
      tb_check(ok, "A1: failed to send ARP request");
      bfm_wait(100);
      tb_check(bfm_rx.size() == 1, $sformatf("A1: expected 1 reply, got %0d", bfm_rx.size()));
      if (bfm_rx.size() == 1) begin
        automatic bfm_frame_t f;
        f = bfm_rx[0];
        tb_check(f.eth_type == 16'h0806, "A1: reply eth_type");
        tb_check(f.oper == 16'h0002, "A1: reply oper");
        tb_check(f.dest_mac == req_sha, "A1: reply dest_mac");
        tb_check(f.src_mac == cfg_local_mac, "A1: reply src_mac");
        tb_check(f.sha == cfg_local_mac, "A1: reply SHA");
        tb_check(f.spa == cfg_local_ip, "A1: reply SPA");
        tb_check(f.tha == req_sha, "A1: reply THA");
        tb_check(f.tpa == req_spa, "A1: reply TPA");
      end
    end

    // -----------------------------------------------------------------------
    // A2: don't answer ARP request for other IP
    // -----------------------------------------------------------------------
    begin
      bit ok;
      logic [47:0] req_sha;
      logic [31:0] req_spa;
      logic [31:0] other_ip;
      req_sha = 48'hAA_BB_CC_DD_EE_FF;
      req_spa = 32'hC0A80164;
      other_ip = 32'hC0A80199;
      tb_clear_cache();
      bfm_rx.delete();
      bfm_send(16'h0001, req_sha, req_spa, 48'h0, other_ip, ok);
      tb_check(ok, "A2: failed to send ARP request");
      bfm_wait(100);
      tb_check(bfm_rx.size() == 0, $sformatf("A2: expected 0 replies, got %0d", bfm_rx.size()));
    end

    // -----------------------------------------------------------------------
    // A3: ignore non-ARP frame
    // -----------------------------------------------------------------------
    begin
      bit ok;
      bit got, err;
      logic [47:0] mac;
      int resp_cycle;
      logic [47:0] req_sha;
      logic [31:0] nonarp_spa;
      req_sha = 48'hAA_BB_CC_DD_EE_FF;
      nonarp_spa = 32'hC0A80177;
      tb_clear_cache();
      bfm_rx.delete();
      bfm_send(16'h0001, req_sha, nonarp_spa, 48'h0, cfg_local_ip, ok, 16'h0800);
      tb_check(ok, "A3: failed to send non-ARP frame");
      bfm_wait(100);
      tb_check(bfm_rx.size() == 0, $sformatf("A3: expected 0 frames, got %0d", bfm_rx.size()));
      tb_do_lookup(nonarp_spa, got, err, mac, resp_cycle);
      tb_check(got, "A3: no response for lookup");
      tb_check(err, "A3: non-ARP frame should not be learned (expected error)");
    end

    // -----------------------------------------------------------------------
    // C1: learn from ARP frame
    // -----------------------------------------------------------------------
    begin
      bit ok;
      bit got, err;
      logic [47:0] mac;
      int resp_cycle;
      logic [31:0] learn_ip;
      logic [47:0] learn_mac;
      learn_ip = 32'hC0A80188;
      learn_mac = 48'h11_22_33_44_55_66;
      tb_clear_cache();
      bfm_rx.delete();
      bfm_send(16'h0001, learn_mac, learn_ip, 48'h0, 32'hC0A80199, ok);
      tb_check(ok, "C1: failed to send ARP request");
      bfm_wait(50);
      bfm_rx.delete();
      tb_do_lookup(learn_ip, got, err, mac, resp_cycle);
      tb_check(got, "C1: no response for lookup");
      tb_check(!err, "C1: expected cache hit (no error)");
      tb_check(mac == learn_mac, $sformatf("C1: expected MAC %h, got %h", learn_mac, mac));
      tb_check(bfm_rx.size() == 0, "C1: cache hit should not transmit a frame");
    end

    // -----------------------------------------------------------------------
    // C2: cache capacity
    // -----------------------------------------------------------------------
    begin
      bit got, err;
      logic [47:0] mac;
      int resp_cycle;
      logic [31:0] ips[5];
      logic [47:0] macs[5];
      int hits;
      ips[0] = 32'hC0A80110;
      ips[1] = 32'hC0A80111;
      ips[2] = 32'hC0A80112;
      ips[3] = 32'hC0A80113;
      ips[4] = 32'hC0A80114;
      macs[0] = 48'hA0;
      macs[1] = 48'hA1;
      macs[2] = 48'hA2;
      macs[3] = 48'hA3;
      macs[4] = 48'hA4;
      tb_clear_cache();
      for (int i = 0; i < 4; i++) tb_insert(ips[i], macs[i]);
      for (int i = 0; i < 4; i++) begin
        bfm_rx.delete();
        tb_do_lookup(ips[i], got, err, mac, resp_cycle);
        tb_check(got && !err && mac == macs[i], $sformatf("C2: entry %0d not in cache", i));
        tb_check(bfm_rx.size() == 0, "C2: cache hit should not transmit");
      end
      tb_insert(ips[4], macs[4]);
      bfm_rx.delete();
      tb_do_lookup(ips[4], got, err, mac, resp_cycle);
      tb_check(got && !err && mac == macs[4], "C2: 5th entry not in cache");
      tb_check(bfm_rx.size() == 0, "C2: cache hit should not transmit");
      hits = 0;
      for (int i = 0; i < 4; i++) begin
        bfm_rx.delete();
        tb_do_lookup(ips[i], got, err, mac, resp_cycle);
        if (got && !err && mac == macs[i]) hits++;
      end
      tb_check(hits == 3, $sformatf("C2: expected 3 original entries, got %0d", hits));
    end

    // -----------------------------------------------------------------------
    // C3: clear_cache
    // -----------------------------------------------------------------------
    begin
      bit got, err;
      logic [47:0] mac;
      int resp_cycle;
      tb_clear_cache();
      tb_insert(32'hC0A80120, 48'hB0);
      bfm_rx.delete();
      tb_do_lookup(32'hC0A80120, got, err, mac, resp_cycle);
      tb_check(got && !err && mac == 48'hB0, "C3: entry not in cache before clear");
      tb_clear_cache();
      bfm_rx.delete();
      tb_do_lookup(32'hC0A80120, got, err, mac, resp_cycle);
      tb_check(got, "C3: no response after clear");
      tb_check(err, "C3: expected cache miss after clear");
      tb_check(bfm_rx.size() > 0, "C3: cache miss should transmit ARP request");
    end

    // -----------------------------------------------------------------------
    // Q6: ARP reply resolves outstanding lookup
    // -----------------------------------------------------------------------
    begin
      bit ok;
      bit got, err;
      logic [47:0] mac;
      int resp_cycle;
      logic [31:0] q6_ip;
      logic [47:0] q6_mac;
      int wait_count;
      int nreq6;
      q6_ip = 32'hC0A80130;
      q6_mac = 48'hDE_AD_BE_EF_00_01;
      tb_clear_cache();
      bfm_rx.delete();
      bfm_lookup(q6_ip, ok);
      tb_check(ok, "Q6: lookup not accepted");
      wait_count = 0;
      while (bfm_rx.size() == 0 && wait_count < 200) begin
        bfm_wait(1);
        wait_count++;
      end
      tb_check(bfm_rx.size() > 0, "Q6: no request transmitted");
      bfm_send(16'h0002, q6_mac, q6_ip, 48'h0, cfg_local_ip, ok);
      tb_check(ok, "Q6: failed to send ARP reply");
      tb_await_resp(200, got, err, mac, resp_cycle);
      tb_check(got, "Q6: no response after ARP reply");
      tb_check(!err, "Q6: expected success after ARP reply");
      tb_check(mac == q6_mac, $sformatf("Q6: expected MAC %h, got %h", q6_mac, mac));
      nreq6 = 0;
      foreach (bfm_rx[i]) begin
        if (bfm_rx[i].eth_type == 16'h0806 && bfm_rx[i].oper == 1) nreq6++;
      end
      tb_check(nreq6 == 1, $sformatf("Q6: expected 1 request, got %0d", nreq6));
      bfm_rx.delete();
      tb_do_lookup(q6_ip, got, err, mac, resp_cycle);
      tb_check(got && !err && mac == q6_mac, "Q6: cache not updated after reply");
      tb_check(bfm_rx.size() == 0, "Q6: cache hit should not transmit");
    end

    // -----------------------------------------------------------------------
    // Final verdict
    // -----------------------------------------------------------------------
    if (tb_fail) begin
      $display("RESULT: FAIL");
    end else begin
      $display("RESULT: PASS");
    end
    $finish;
  end

endmodule
