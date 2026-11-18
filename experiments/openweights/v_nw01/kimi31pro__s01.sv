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
    .s_payload_valid_i(s_pv), .s_payload_ready_o(s_pr),
    .s_payload_last_i(s_pl),
    .s_payload_user_i(s_pu),
    .m_hdr_valid_o(m_hv), .m_hdr_ready_i(m_hr), .m_dest_mac_o(m_dm),
    .m_src_mac_o(m_sm), .m_eth_type_o(m_et), .m_payload_data_o(m_pd),
    .m_payload_valid_o(m_pv), .m_payload_ready_i(m_pr),
    .m_payload_last_o(m_pl),
    .m_payload_user_o(m_pu),
    .req_valid_i(rq_v), .req_ready_o(rq_r), .req_ip_i(rq_ip),
    .resp_valid_o(rs_v), .resp_ready_i(rs_r), .resp_error_o(rs_e),
    .resp_mac_o(rs_mac),
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
        bfm_frame_t f;
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
        f.spa   = (bfm_buf.size() > 17) ? {bfm_buf[14],bfm_buf[15],bfm_buf[16],
                                           bfm_buf[17]} : '0;
        f.tha   = (bfm_buf.size() > 23) ? {bfm_buf[18],bfm_buf[19],bfm_buf[20],
                                           bfm_buf[21],bfm_buf[22],bfm_buf[23]} : '0;
        f.tpa   = (bfm_buf.size() > 27) ? {bfm_buf[24],bfm_buf[25],bfm_buf[26],
                                           bfm_buf[27]} : '0;
        bfm_rx.push_back(f);
        bfm_buf.delete();
      end
    end
  end

  // ---- driving a frame in ----------------------------------------------------
  task automatic bfm_send(input logic [15:0] oper, input logic [47:0] sha,
                          input logic [31:0] spa, input logic [47:0] tha,
                          input logic [31:0] tpa, output bit ok,
                          input logic [15:0] ethtype = 16'h0806,
                          input int limit = 32);
    logic [7:0] p [28];
    ok = 1'b1;
    p[0]=8'h00; p[1]=8'h01; p[2]=8'h08; p[3]=8'h00; p[4]=8'd6; p[5]=8'd4;
    p[6]=oper[15:8]; p[7]=oper[7:0];
    for (int i=0;i<6;i++) p[8+i]  = sha[47-8*i -: 8];
    for (int i=0;i<4;i++) p[14+i] = spa[31-8*i -: 8];
    for (int i=0;i<6;i++) p[18+i] = tha[47-8*i -: 8];
    for (int i=0;i<4;i++) p[24+i] = tpa[31-8*i -: 8];
    @(negedge clk);
    s_dm = cfg_local_mac;
    s_sm = sha;
    s_et = ethtype;
    s_hv = 1'b1;
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
      @(negedge clk);
      s_pd = p[i];
      s_pl = (i==27);
      s_pv = 1'b1;
      for (int t=0;t<limit;t++) begin
        @(posedge clk);
        if (s_pr) begin took=1'b1; break; end
      end
      @(negedge clk) s_pv = 1'b0; s_pl = 1'b0;
      if (!took) begin ok = 1'b0; return; end
    end
  endtask

  // ---- offering a lookup ------------------------------------------------------
  task automatic bfm_lookup(input logic [31:0] ip, output bit ok,
                            input int limit = 32);
    ok = 1'b0;
    @(negedge clk);
    rq_ip = ip;
    rq_v = 1'b1;
    for (int t=0;t<limit;t++) begin
      @(posedge clk);
      if (rq_r) begin ok = 1'b1; break; end
    end
    @(negedge clk) rq_v = 1'b0;
  endtask

  task automatic bfm_await(input int limit, output bit got, output bit err,
                           output logic [47:0] mac, output int took);
    got = 1'b0;
    err = 1'b0;
    mac = '0;
    took = 0;
    for (int t=0;t<limit;t++) begin
      @(posedge clk);
      took = t;
      if (rs_v) begin
        got = 1'b1;
        err = rs_e;
        mac = rs_mac;
        break;
      end
    end
  endtask

  task automatic bfm_wait(input int n);
    repeat (n) @(posedge clk);
  endtask

  // ---- watchdog ---------------------------------------------------------------
  initial begin
    #8_000_000;
    $display("RESULT: FAIL (watchdog: no verdict reached)");
    $finish;
  end

// ---------------------------------------------------------------------------
// Testbench bookkeeping and checking.
// ---------------------------------------------------------------------------

  typedef struct packed {
    logic        err;
    logic [47:0] mac;
    int          at;
  } resp_item_t;

  resp_item_t resp_q [$];

  int failures = 0;
  int tx_hdr_total = 0;
  int last_req_at = -1;
  logic reset_sampled = 1'b0;
  bit x1_reported = 1'b0;

  task automatic report_fail(input string clause, input string detail);
    failures = failures + 1;
    $display("FAIL %s at cycle %0d: %s", clause, bfm_cycle, detail);
  endtask

  // Record responses independently of the stimulus task currently running, so
  // a short response pulse cannot be missed while a frame is being driven.
  always @(posedge clk) begin
    automatic resp_item_t item;
    reset_sampled = rst;
    if (!rst) begin
      if (rs_v && rs_r) begin
        item.err = rs_e;
        item.mac = rs_mac;
        item.at = bfm_cycle;
        resp_q.push_back(item);
      end
      if (m_hv && m_hr)
        tx_hdr_total = tx_hdr_total + 1;
      if (rq_v && rq_r)
        last_req_at = bfm_cycle;
    end
  end

  // Check on the falling edge after a rising edge at which reset was sampled
  // high. Thus nothing is sampled at time zero, and reset remains synchronous.
  always @(negedge clk) begin
    if (reset_sampled && rst && !x1_reported) begin
      if ((m_hv !== 1'b0) || (m_pv !== 1'b0) || (rs_v !== 1'b0)) begin
        x1_reported = 1'b1;
        report_fail("X1", "an output valid was asserted while rst was high");
      end
    end
  end

  task automatic clean_reset;
    bfm_reset();
    @(negedge clk);
    clr_cache = 1'b0;
    bfm_rx.delete();
    resp_q.delete();
    bfm_buf.delete();
  endtask

  task automatic get_frame(input int limit, output bit got,
                           output bfm_frame_t f);
    got = 1'b0;
    f = '0;
    for (int t = 0; t < limit; t++) begin
      if (bfm_rx.size() != 0) begin
        f = bfm_rx.pop_front();
        got = 1'b1;
        return;
      end
      @(posedge clk);
    end
    if (bfm_rx.size() != 0) begin
      f = bfm_rx.pop_front();
      got = 1'b1;
    end
  endtask

  task automatic get_resp(input int limit, output bit got,
                          output resp_item_t r);
    got = 1'b0;
    r = '0;
    for (int t = 0; t < limit; t++) begin
      if (resp_q.size() != 0) begin
        r = resp_q.pop_front();
        got = 1'b1;
        return;
      end
      @(posedge clk);
    end
    if (resp_q.size() != 0) begin
      r = resp_q.pop_front();
      got = 1'b1;
    end
  endtask

  // No transmitted header is allowed during the interval, and no previously
  // started frame is allowed to be left in the capture queue.
  task automatic no_transmit(input int cycles, input string clause);
    bfm_frame_t junk;
    int h0;
    h0 = tx_hdr_total;
    repeat (cycles) @(posedge clk);
    @(negedge clk);
    if ((tx_hdr_total != h0) || (bfm_rx.size() != 0)) begin
      report_fail(clause,
                  $sformatf("unexpected transmission (%0d new headers, %0d queued frames)",
                            tx_hdr_total-h0, bfm_rx.size()));
      while (bfm_rx.size() != 0)
        junk = bfm_rx.pop_front();
    end
  endtask

  task automatic check_arp_common(input bfm_frame_t f, input string clause);
    if (f.eth_type !== 16'h0806)
      report_fail(clause, $sformatf("eth_type was %04x, not 0806", f.eth_type));
    if (f.nbytes != 28)
      report_fail(clause, $sformatf("payload length was %0d, not 28", f.nbytes));
    if (f.htype !== 16'h0001)
      report_fail(clause, $sformatf("hardware type was %04x", f.htype));
    if (f.ptype !== 16'h0800)
      report_fail(clause, $sformatf("protocol type was %04x", f.ptype));
    if (f.hlen !== 8'd6)
      report_fail(clause, $sformatf("hardware length was %0d", f.hlen));
    if (f.plen !== 8'd4)
      report_fail(clause, $sformatf("protocol length was %0d", f.plen));
  endtask

  task automatic check_request(input bfm_frame_t f, input logic [31:0] target,
                               input string clause);
    check_arp_common(f, clause);
    if (f.oper !== 16'd1)
      report_fail(clause, $sformatf("operation was %0d, not request", f.oper));
    if (f.dest_mac !== 48'hff_ff_ff_ff_ff_ff)
      report_fail("Q2", $sformatf("request destination was %012x, not broadcast",
                                  f.dest_mac));
    if (f.sha !== cfg_local_mac)
      report_fail("Q2", $sformatf("request SHA was %012x, not local MAC", f.sha));
    if (f.spa !== cfg_local_ip)
      report_fail("Q2", $sformatf("request SPA was %08x, not local IP", f.spa));
    if (f.tha !== 48'd0)
      report_fail("Q2", $sformatf("request THA was %012x, not zero", f.tha));
    if (f.tpa !== target)
      report_fail("Q3", $sformatf("request TPA was %08x, expected %08x",
                                  f.tpa, target));
  endtask

  task automatic check_answer_reply(input bfm_frame_t f,
                                    input logic [47:0] requester_mac,
                                    input logic [31:0] requester_ip);
    check_arp_common(f, "F/A1");
    if (f.oper !== 16'd2)
      report_fail("A1", $sformatf("reply operation was %0d, not 2", f.oper));
    if (f.dest_mac !== requester_mac)
      report_fail("A1", $sformatf("reply destination was %012x, expected %012x",
                                  f.dest_mac, requester_mac));
    if (f.sha !== cfg_local_mac)
      report_fail("A1", $sformatf("reply SHA was %012x, not local MAC", f.sha));
    if (f.spa !== cfg_local_ip)
      report_fail("A1", $sformatf("reply SPA was %08x, not local IP", f.spa));
    if (f.tha !== requester_mac)
      report_fail("A1", $sformatf("reply THA was %012x, expected %012x",
                                  f.tha, requester_mac));
    if (f.tpa !== requester_ip)
      report_fail("A1", $sformatf("reply TPA was %08x, expected %08x",
                                  f.tpa, requester_ip));
  endtask

  task automatic lookup_hit(input logic [31:0] ip,
                            input logic [47:0] expected_mac,
                            input string clause);
    bit ok;
    bit got;
    resp_item_t r;
    bfm_lookup(ip, ok);
    if (!ok) begin
      report_fail("X3", $sformatf("lookup of %08x was not accepted within 32 cycles", ip));
      return;
    end
    get_resp(40, got, r);
    if (!got) begin
      report_fail(clause, $sformatf("cached lookup of %08x was not answered", ip));
    end else begin
      if ((r.at < last_req_at) || ((r.at - last_req_at) > 32))
        report_fail("X3", $sformatf("cache-hit response took %0d cycles",
                                    r.at-last_req_at));
      if (r.err)
        report_fail(clause, $sformatf("cached lookup of %08x returned an error", ip));
      else if (r.mac !== expected_mac)
        report_fail(clause, $sformatf("cached lookup returned MAC %012x, expected %012x",
                                      r.mac, expected_mac));
    end
    no_transmit(60, clause);
  endtask

  task automatic lookup_miss(input logic [31:0] ip,
                             input logic [31:0] requested_target,
                             input string clause,
                             output bfm_frame_t f);
    bit ok;
    bit got;
    f = '0;
    bfm_lookup(ip, ok);
    if (!ok) begin
      report_fail("X3", $sformatf("lookup of %08x was not accepted within 32 cycles", ip));
      return;
    end
    get_frame(180, got, f);
    if (resp_q.size() != 0) begin
      report_fail(clause,
                  $sformatf("lookup of %08x was answered without a network request", ip));
      resp_q.delete();
    end
    if (!got) begin
      report_fail(clause, $sformatf("miss for %08x produced no ARP request", ip));
      return;
    end
    check_request(f, requested_target, clause);
  endtask

// ---------------------------------------------------------------------------
// A1, C1 and Q1: answer a request for us, learn its sender, then hit the cache.
// ---------------------------------------------------------------------------
  task automatic test_a1_q1;
    bit ok;
    bit got;
    bfm_frame_t f;
    logic [47:0] remote_mac;
    logic [31:0] remote_ip;
    remote_mac = 48'h02_00_00_00_00_0a;
    remote_ip = 32'hC0A8_010a;
    clean_reset();
    bfm_send(16'd1, remote_mac, remote_ip, 48'd0, cfg_local_ip, ok);
    if (!ok) begin
      report_fail("X3", "ARP request for local IP was not accepted");
      return;
    end
    get_frame(160, got, f);
    if (!got) begin
      report_fail("A1", "request for local IP was not answered");
      return;
    end
    check_answer_reply(f, remote_mac, remote_ip);
    lookup_hit(remote_ip, remote_mac, "Q1/C1");
  endtask

// ---------------------------------------------------------------------------
// A2 and C1: a request for somebody else is learned from but not answered.
// ---------------------------------------------------------------------------
  task automatic test_a2;
    bit ok;
    logic [47:0] remote_mac;
    logic [31:0] remote_ip;
    remote_mac = 48'h02_00_00_00_00_0b;
    remote_ip = 32'hC0A8_010b;
    clean_reset();
    bfm_send(16'd1, remote_mac, remote_ip, 48'd0, 32'hC0A8_0199, ok);
    if (!ok) begin
      report_fail("X3", "ARP request for another station was not accepted");
      return;
    end
    no_transmit(80, "A2");
    lookup_hit(remote_ip, remote_mac, "C1/Q1");
  endtask

// ---------------------------------------------------------------------------
// A3: an ARP-shaped payload with a non-ARP Ethernet type is entirely ignored.
// ---------------------------------------------------------------------------
  task automatic test_a3;
    bit ok;
    bfm_frame_t f;
    logic [47:0] remote_mac;
    logic [31:0] remote_ip;
    remote_mac = 48'h02_00_00_00_00_0c;
    remote_ip = 32'hC0A8_010c;
    clean_reset();
    bfm_send(16'd1, remote_mac, remote_ip, 48'd0, cfg_local_ip, ok, 16'h0800);
    if (!ok) begin
      report_fail("X3", "non-ARP frame was not accepted");
      return;
    end
    no_transmit(80, "A3");
    // If the non-ARP frame was learned from, this lookup hits instead of
    // producing the required request and lookup_miss reports it.
    lookup_miss(remote_ip, remote_ip, "A3/Q2", f);
  endtask

// ---------------------------------------------------------------------------
// Q2, Q6 and C1: resolve a miss with a reply, stop retrying, and retain SHA.
// Requests completed before the reply resolves the lookup are allowed.
// ---------------------------------------------------------------------------
  task automatic test_q6;
    bit ok;
    bit got;
    resp_item_t r;
    bfm_frame_t f;
    logic [31:0] target_ip;
    logic [47:0] target_mac;
    int hstart;
    int nframes;
    target_ip = 32'hC0A8_0120;
    target_mac = 48'h02_00_00_00_00_20;
    clean_reset();
    hstart = tx_hdr_total;
    bfm_lookup(target_ip, ok);
    if (!ok) begin
      report_fail("X3", "lookup for Q6 was not accepted");
      return;
    end

    // Start the reply immediately. Even so, an implementation is allowed to
    // send a retry before it has received the complete reply; those frames are
    // distinguished by their header timestamps below.
    bfm_send(16'd2, target_mac, target_ip, cfg_local_mac, cfg_local_ip, ok);
    if (!ok) begin
      report_fail("X3", "resolving ARP reply was not accepted");
      return;
    end
    get_resp(180, got, r);
    if (!got) begin
      report_fail("Q6", "matching ARP reply did not resolve the lookup");
      return;
    end
    if (r.err)
      report_fail("Q6", "matching ARP reply produced an error response");
    else if (r.mac !== target_mac)
      report_fail("Q6", $sformatf("resolved MAC was %012x, expected %012x",
                                  r.mac, target_mac));

    // Drain frames whose headers preceded resolution. A retry after resolution
    // is a Q6 violation.
    bfm_wait(80);
    @(negedge clk);
    nframes = bfm_rx.size();
    if ((nframes == 0) && (tx_hdr_total == hstart))
      report_fail("Q2", "cache miss produced no request before the reply");
    while (bfm_rx.size() != 0) begin
      f = bfm_rx.pop_front();
      check_request(f, target_ip, "Q2/Q3");
      if (f.at > (r.at + 2))
        report_fail("Q6", "a request was transmitted after the lookup resolved");
    end
    no_transmit(110, "Q6");
    lookup_hit(target_ip, target_mac, "C1/Q1");
  endtask

// ---------------------------------------------------------------------------
// Q3: an off-subnet lookup asks for the gateway, not for the off-subnet IP.
// ---------------------------------------------------------------------------
  task automatic test_gateway;
    bfm_frame_t f;
    clean_reset();
    lookup_miss(32'h0A00_0001, cfg_gateway_ip, "Q3/Q2", f);
  endtask

// ---------------------------------------------------------------------------
// Q4 and Q5: exactly four requests, bounded retry spacing, and a late error.
// resp_mac_o is deliberately not examined on the error response (L2).
// ---------------------------------------------------------------------------
  task automatic test_retries_timeout;
    bit ok;
    bit got;
    bfm_frame_t fr [4];
    resp_item_t r;
    logic [31:0] target_ip;
    int hstart;
    int spacing;
    int delay_after_fourth;
    target_ip = 32'hC0A8_0130;
    clean_reset();
    hstart = tx_hdr_total;
    bfm_lookup(target_ip, ok);
    if (!ok) begin
      report_fail("X3", "lookup for retry test was not accepted");
      return;
    end

    for (int i = 0; i < 4; i++) begin
      get_frame((i == 0) ? 220 : 120, got, fr[i]);
      if (!got) begin
        report_fail("Q4", $sformatf("request %0d was not transmitted", i+1));
        return;
      end
      check_request(fr[i], target_ip, "Q2/Q3/Q4");
      if (resp_q.size() != 0) begin
        report_fail("Q5", "lookup was answered before four requests and the timeout");
        return;
      end
      if (i != 0) begin
        spacing = fr[i].at - fr[i-1].at;
        if ((spacing < 64) || (spacing > 80))
          report_fail("Q4", $sformatf("requests %0d and %0d were %0d cycles apart",
                                      i, i+1, spacing));
      end
    end

    get_resp(360, got, r);
    if (!got) begin
      report_fail("Q5", "no error response arrived after the fourth request");
      return;
    end
    delay_after_fourth = r.at - fr[3].at;
    if ((delay_after_fourth < 256) || (delay_after_fourth > 300))
      report_fail("Q5", $sformatf("error came %0d cycles after request four",
                                  delay_after_fourth));
    if (!r.err)
      report_fail("Q5", "timeout response did not have resp_error_o high");

    // This catches both complete extra frames and a fifth header whose payload
    // is still in progress. No value check is made on the error response's MAC.
    no_transmit(110, "Q4");
    if (tx_hdr_total != (hstart + 4))
      report_fail("Q4", $sformatf("observed %0d transmitted headers, expected exactly 4",
                                  tx_hdr_total-hstart));
  endtask

// ---------------------------------------------------------------------------
// C1, C2 and C3: every new insert, including one into a full cache, must be
// usable. No older entry is required to survive the fifth insert (L1).
// ---------------------------------------------------------------------------
  task automatic test_cache_and_clear;
    bit ok;
    bfm_frame_t f;
    logic [31:0] ip;
    logic [31:0] latest_ip;
    logic [47:0] mac;
    clean_reset();
    latest_ip = '0;

    for (int i = 0; i < 5; i++) begin
      ip = 32'hC0A8_0140 + i;
      mac = 48'h02_00_00_00_00_40 + i;
      latest_ip = ip;
      bfm_send(16'd1, mac, ip, 48'd0, 32'hC0A8_01ee, ok);
      if (!ok) begin
        report_fail("X3", $sformatf("cache-insert frame %0d was not accepted", i));
        return;
      end
      no_transmit(50, "A2");
      // Only the entry just inserted is checked. In particular, after the
      // fifth insertion no claim is made about any older entry.
      lookup_hit(ip, mac, (i == 4) ? "C2/C1" : "C1/Q1");
    end

    @(negedge clk);
    clr_cache = 1'b1;
    @(posedge clk);
    @(negedge clk);
    clr_cache = 1'b0;
    @(posedge clk);

    lookup_miss(latest_ip, latest_ip, "C3/Q2", f);
  endtask

// ---------------------------------------------------------------------------
// X2: reset empties a populated cache and cancels an outstanding lookup.
// The second part also gives a fresh lookup a chance to prove forward progress.
// ---------------------------------------------------------------------------
  task automatic test_reset_state;
    bit ok;
    bfm_frame_t f;
    logic [47:0] remote_mac;
    logic [31:0] remote_ip;
    int hbase;
    remote_mac = 48'h02_00_00_00_00_50;
    remote_ip = 32'hC0A8_0150;
    clean_reset();

    bfm_send(16'd1, remote_mac, remote_ip, 48'd0, 32'hC0A8_01ee, ok);
    if (!ok) begin
      report_fail("X3", "frame used to populate cache for reset test was not accepted");
      return;
    end
    no_transmit(60, "A2");

    bfm_reset();
    @(negedge clk);
    bfm_rx.delete();
    resp_q.delete();
    bfm_buf.delete();

    // The address was cached before reset, so a hit here demonstrates that
    // reset failed to empty the cache.
    lookup_miss(remote_ip, remote_ip, "X2/Q2", f);

    // That miss leaves a lookup outstanding. Reset must cancel it: no old
    // retries and no old timeout response may appear afterwards.
    bfm_reset();
    hbase = tx_hdr_total;
    bfm_wait(380);
    @(negedge clk);
    if ((tx_hdr_total != hbase) || (bfm_rx.size() != 0) || (resp_q.size() != 0))
      report_fail("X2", "activity from the pre-reset lookup survived reset");
    bfm_rx.delete();
    resp_q.delete();
    bfm_buf.delete();

    lookup_miss(32'hC0A8_0151, 32'hC0A8_0151, "X2/Q2", f);
  endtask

  initial begin
    test_a1_q1();
    test_a2();
    test_a3();
    test_q6();
    test_gateway();
    test_retries_timeout();
    test_cache_and_clear();
    test_reset_state();

    clean_reset();
    @(negedge clk);
    if (failures == 0)
      $display("RESULT: PASS");
    else
      $display("RESULT: FAIL");
    $finish;
  end

endmodule
