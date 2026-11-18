`timescale 1ns/1ps

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
    .s_payload_last_i(s_pl), .s_payload_user_i(s_pu),
    .m_hdr_valid_o(m_hv), .m_hdr_ready_i(m_hr), .m_dest_mac_o(m_dm),
    .m_src_mac_o(m_sm), .m_eth_type_o(m_et), .m_payload_data_o(m_pd),
    .m_payload_valid_o(m_pv), .m_payload_ready_i(m_pr),
    .m_payload_last_o(m_pl), .m_payload_user_o(m_pu),
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
        if (s_hr) begin
          took=1'b1;
          break;
        end
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
        if (s_pr) begin
          took=1'b1;
          break;
        end
      end
      @(negedge clk);
      s_pv = 1'b0;
      s_pl = 1'b0;
      if (!took) begin
        ok = 1'b0;
        return;
      end
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
      if (rq_r) begin
        ok = 1'b1;
        break;
      end
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
  // Testbench bookkeeping and checks
  // ---------------------------------------------------------------------------

  localparam logic [31:0] IP_RETRY    = 32'hC0A8_0137;
  localparam logic [31:0] IP_RESOLVE  = 32'hC0A8_013C;
  localparam logic [47:0] MAC_RESOLVE = 48'h02_00_00_00_00_AA;
  localparam logic [31:0] IP_OUTSIDE  = 32'h0808_0808;
  localparam logic [47:0] MAC_GATEWAY = 48'h02_00_00_00_00_FE;

  localparam logic [31:0] IP_A1_PEER  = 32'hC0A8_0146;
  localparam logic [47:0] MAC_A1_PEER = 48'h02_00_00_00_00_70;
  localparam logic [31:0] IP_A2_PEER  = 32'hC0A8_014D;
  localparam logic [47:0] MAC_A2_PEER = 48'h02_00_00_00_00_77;
  localparam logic [31:0] IP_A2_TPA   = 32'hC0A8_0163;

  localparam logic [31:0] IP_NONARP   = 32'hC0A8_0158;
  localparam logic [47:0] MAC_NONARP  = 48'h02_00_00_00_00_88;

  localparam logic [31:0] IP_CAP_BASE  = 32'hC0A8_0140;
  localparam logic [47:0] MAC_CAP_BASE = 48'h02_00_00_00_00_40;
  localparam logic [31:0] IP_X2_MISS   = 32'hC0A8_015A;

  typedef struct packed {
    logic        err;
    logic [47:0] mac;
    int          at;
  } resp_item_t;

  resp_item_t resp_log [$];
  resp_item_t resp_item;

  // Record response handshakes so that even a same-cycle cache response cannot
  // be missed by stimulus running after the request task returns.
  always @(posedge clk) begin
    if (!rst && rs_v && rs_r) begin
      resp_item.err = rs_e;
      resp_item.mac = rs_mac;
      resp_item.at  = bfm_cycle;
      resp_log.push_back(resp_item);
    end
  end

  // reset_sample changes only on a rising edge.  Checking on the following
  // falling edge observes the registered effects of reset without sampling
  // unknown time-zero state or racing the reset driver's falling-edge writes.
  logic reset_sample = 1'b0;
  always @(posedge clk) reset_sample <= rst;

  task automatic fail_clause(input string clause, input string detail);
    $display("FAIL [%s] %s", clause, detail);
    $display("RESULT: FAIL");
    $finish;
  endtask

  always @(negedge clk) begin
    if (reset_sample) begin
      if ((m_hv !== 1'b0) || (m_pv !== 1'b0) || (rs_v !== 1'b0))
        fail_clause("X1", "an output valid was asserted while reset was active");
    end
  end

  task automatic wait_frame(input int base, input int limit, output bit got);
    got = 1'b0;
    for (int t = 0; t < limit; t++) begin
      @(negedge clk);
      if (bfm_rx.size() > base) begin
        got = 1'b1;
        break;
      end
    end
  endtask

  task automatic wait_response(input int base, input int limit, output bit got);
    got = 1'b0;
    for (int t = 0; t < limit; t++) begin
      @(negedge clk);
      if (resp_log.size() > base) begin
        got = 1'b1;
        break;
      end
    end
  endtask

  task automatic offer_lookup(input logic [31:0] ip, output bit ok,
                              output int accepted_at);
    ok = 1'b0;
    accepted_at = -1;
    @(negedge clk);
    rq_ip = ip;
    rq_v = 1'b1;
    for (int t = 0; t < 32; t++) begin
      @(posedge clk);
      if (rq_r) begin
        ok = 1'b1;
        accepted_at = bfm_cycle;
        break;
      end
    end
    @(negedge clk);
    rq_v = 1'b0;
  endtask

  task automatic check_common_arp(input bfm_frame_t f, input string clause);
    if (f.eth_type !== 16'h0806)
      fail_clause("F", "transmitted ARP frame did not have eth_type 0x0806");
    if (f.nbytes != 28)
      fail_clause("F", "transmitted ARP payload was not exactly 28 bytes");
    if (f.htype !== 16'h0001)
      fail_clause("F", "wrong ARP hardware type");
    if (f.ptype !== 16'h0800)
      fail_clause("F", "wrong ARP protocol type");
    if (f.hlen !== 8'd6)
      fail_clause("F", "wrong ARP hardware length");
    if (f.plen !== 8'd4)
      fail_clause("F", "wrong ARP protocol length");
  endtask

  task automatic check_request(input bfm_frame_t f,
                               input logic [31:0] expected_tpa,
                               input string clause);
    check_common_arp(f, clause);
    if (f.dest_mac !== 48'hFF_FF_FF_FF_FF_FF)
      fail_clause("Q2", "lookup request was not Ethernet broadcast");
    if (f.oper !== 16'd1)
      fail_clause("Q2", "lookup did not transmit an ARP request");
    if (f.sha !== cfg_local_mac)
      fail_clause("Q2", "lookup request SHA was not local_mac_i");
    if (f.spa !== cfg_local_ip)
      fail_clause("Q2", "lookup request SPA was not local_ip_i");
    if (f.tha !== 48'd0)
      fail_clause("Q2", "lookup request THA was not zero");
    if (f.tpa !== expected_tpa)
      fail_clause(clause, "lookup request used the wrong target IP address");
  endtask

  task automatic check_cache_hit(input logic [31:0] ip,
                                 input logic [47:0] expected_mac,
                                 input string clause);
    automatic int fbase;
    automatic int rbase;
    automatic int accepted_at;
    automatic int delta;
    automatic bit ok;
    automatic bit got;

    @(negedge clk);
    fbase = bfm_rx.size();
    rbase = resp_log.size();

    offer_lookup(ip, ok, accepted_at);
    if (!ok)
      fail_clause("X3", "a cache-hit lookup was not accepted within 32 cycles");

    wait_response(rbase, 40, got);
    if (!got)
      fail_clause(clause, "cached address was not answered as a cache hit");

    delta = resp_log[rbase].at - accepted_at;
    if ((delta < 0) || (delta > 32))
      fail_clause("X3", "cache-hit response exceeded 32 cycles from acceptance");
    if (resp_log[rbase].err !== 1'b0)
      fail_clause("Q1", "cache-hit response incorrectly asserted resp_error_o");
    if (resp_log[rbase].mac !== expected_mac)
      fail_clause(clause, "cache-hit response returned the wrong MAC address");

    // Allow enough time for an erroneously generated request, including its
    // complete payload, to become visible in the frame log.
    bfm_wait(90);
    @(negedge clk);
    if ((bfm_rx.size() != fbase) || (m_hv !== 1'b0) || (m_pv !== 1'b0))
      fail_clause("Q1", "a cache hit caused a frame to be transmitted");
  endtask

  task automatic start_miss(input logic [31:0] ip,
                            input logic [31:0] expected_tpa,
                            input string clause,
                            output int fbase,
                            output int rbase,
                            output int accepted_at);
    automatic bit ok;
    automatic bit got;

    @(negedge clk);
    fbase = bfm_rx.size();
    rbase = resp_log.size();

    offer_lookup(ip, ok, accepted_at);
    if (!ok)
      fail_clause("X3", "lookup was not accepted within 32 cycles");

    wait_frame(fbase, 400, got);
    if (!got)
      fail_clause(clause, "an unknown address did not produce an ARP request");

    check_request(bfm_rx[fbase], expected_tpa, clause);
  endtask

  task automatic resolve_with_reply(input logic [31:0] spa,
                                    input logic [47:0] sha,
                                    input int rbase,
                                    input string clause,
                                    output int resolved_at);
    automatic bit ok;
    automatic bit got;

    bfm_send(16'd2, sha, spa, cfg_local_mac, cfg_local_ip, ok);
    if (!ok)
      fail_clause("X3", "received ARP reply was not accepted within 32 cycles");

    wait_response(rbase, 400, got);
    if (!got)
      fail_clause(clause, "matching ARP reply did not resolve the lookup");
    if (resp_log[rbase].err !== 1'b0)
      fail_clause("Q6", "matching ARP reply produced an error response");
    if (resp_log[rbase].mac !== sha)
      fail_clause("Q6", "resolved lookup did not return the reply's SHA");

    resolved_at = resp_log[rbase].at;

    // Drain any request whose header was already in flight when the reply
    // arrived.  Q6 checks use header timestamps, so such a request is not
    // mistaken for one issued after resolution.
    bfm_wait(100);
  endtask

  // ---------------------------------------------------------------------------
  // Main stimulus
  // ---------------------------------------------------------------------------
  initial begin : main_stimulus
    automatic bit ok;
    automatic bit got;
    automatic int fbase;
    automatic int rbase;
    automatic int accepted_at;
    automatic int resolved_at;
    automatic int delta;
    automatic int i;
    automatic bfm_frame_t f;

    bfm_reset();

    // -----------------------------------------------------------------------
    // Q2/Q3/Q4/Q5: leave an inside-subnet lookup unanswered and measure the
    // complete retry and timeout sequence.
    // -----------------------------------------------------------------------
    @(negedge clk);
    fbase = bfm_rx.size();
    rbase = resp_log.size();

    offer_lookup(IP_RETRY, ok, accepted_at);
    if (!ok)
      fail_clause("X3", "initial lookup was not accepted within 32 cycles");

    for (i = 0; i < 4; i++) begin
      if (i == 0)
        wait_frame(fbase + i, 400, got);
      else
        wait_frame(fbase + i, 180, got);

      if (!got)
        fail_clause("Q4", "fewer than four request frames were transmitted");

      check_request(bfm_rx[fbase + i], IP_RETRY, "Q2/Q3/Q4");

      if (resp_log.size() != rbase)
        fail_clause("Q5", "lookup was answered before the fourth request");
    end

    for (i = 0; i < 3; i++) begin
      delta = bfm_rx[fbase + i + 1].at - bfm_rx[fbase + i].at;
      if ((delta < 64) || (delta > 80))
        fail_clause("Q4", "consecutive request headers were not 64..80 cycles apart");
    end

    if (bfm_rx.size() != fbase + 4)
      fail_clause("Q4", "extra frame appeared during the four-request sequence");

    wait_response(rbase, 340, got);
    if (!got)
      fail_clause("Q5", "unanswered lookup did not produce a bounded timeout response");
    if (resp_log[rbase].err !== 1'b1)
      fail_clause("Q5", "unanswered lookup did not assert resp_error_o");

    // resp_mac_o is deliberately not examined here (L2).
    delta = resp_log[rbase].at - bfm_rx[fbase + 3].at;
    if ((delta < 256) || (delta > 300))
      fail_clause("Q5", "error response was not 256..300 cycles after request four");

    bfm_wait(100);
    @(negedge clk);
    if (bfm_rx.size() != fbase + 4)
      fail_clause("Q4", "more than four requests were transmitted in total");
    if (resp_log.size() != rbase + 1)
      fail_clause("Q5", "unanswered lookup produced an unexpected response count");

    // -----------------------------------------------------------------------
    // Q6/C1/Q1: resolve an outstanding lookup, then prove both that retries
    // stop and that the learned reply can subsequently hit in the cache.
    // -----------------------------------------------------------------------
    start_miss(IP_RESOLVE, IP_RESOLVE, "Q2/Q3/Q6",
               fbase, rbase, accepted_at);
    resolve_with_reply(IP_RESOLVE, MAC_RESOLVE, rbase, "Q6", resolved_at);

    bfm_wait(200);
    @(negedge clk);
    for (i = fbase; i < bfm_rx.size(); i++) begin
      if (bfm_rx[i].at > resolved_at)
        fail_clause("Q6", "a request was transmitted after the lookup resolved");
    end

    check_cache_hit(IP_RESOLVE, MAC_RESOLVE, "C1/Q1");

    // -----------------------------------------------------------------------
    // Q3: an outside-subnet lookup must ask for the gateway, not for the
    // outside address itself.  The gateway reply resolves that lookup.
    // -----------------------------------------------------------------------
    start_miss(IP_OUTSIDE, cfg_gateway_ip, "Q3",
               fbase, rbase, accepted_at);
    resolve_with_reply(cfg_gateway_ip, MAC_GATEWAY, rbase, "Q3/Q6", resolved_at);

    // -----------------------------------------------------------------------
    // A1: request aimed at local_ip_i must elicit a fully formed reply.
    // -----------------------------------------------------------------------
    @(negedge clk);
    fbase = bfm_rx.size();
    bfm_send(16'd1, MAC_A1_PEER, IP_A1_PEER, 48'd0, cfg_local_ip, ok);
    if (!ok)
      fail_clause("X3", "A1 request header or payload was not accepted in time");

    wait_frame(fbase, 400, got);
    if (!got)
      fail_clause("A1", "request for local_ip_i was not answered");

    f = bfm_rx[fbase];
    check_common_arp(f, "A1");
    if (f.dest_mac !== MAC_A1_PEER)
      fail_clause("A1", "reply destination was not the requester's SHA");
    if (f.oper !== 16'd2)
      fail_clause("A1", "answer was not an ARP reply");
    if (f.sha !== cfg_local_mac)
      fail_clause("A1", "reply SHA was not local_mac_i");
    if (f.spa !== cfg_local_ip)
      fail_clause("A1", "reply SPA was not local_ip_i");
    if (f.tha !== MAC_A1_PEER)
      fail_clause("A1", "reply THA was not the requester's SHA");
    if (f.tpa !== IP_A1_PEER)
      fail_clause("A1", "reply TPA was not the requester's SPA");

    bfm_wait(60);
    @(negedge clk);
    if (bfm_rx.size() != fbase + 1)
      fail_clause("A1", "request for local_ip_i produced extra frames");

    // -----------------------------------------------------------------------
    // A2/C1: a request aimed elsewhere gets no answer, but its SPA/SHA pair
    // must still be learned.
    // -----------------------------------------------------------------------
    @(negedge clk);
    fbase = bfm_rx.size();
    bfm_send(16'd1, MAC_A2_PEER, IP_A2_PEER, 48'd0, IP_A2_TPA, ok);
    if (!ok)
      fail_clause("X3", "A2 request header or payload was not accepted in time");

    bfm_wait(80);
    @(negedge clk);
    if (bfm_rx.size() != fbase)
      fail_clause("A2", "request whose TPA was not local_ip_i was answered");

    check_cache_hit(IP_A2_PEER, MAC_A2_PEER, "C1");

    // -----------------------------------------------------------------------
    // A3: an ARP-shaped payload with a non-ARP Ethernet type must be neither
    // answered nor learned.  Its subsequent lookup therefore goes to the wire.
    // -----------------------------------------------------------------------
    @(negedge clk);
    fbase = bfm_rx.size();
    bfm_send(16'd1, MAC_NONARP, IP_NONARP, 48'd0, cfg_local_ip,
             ok, 16'h0800);
    if (!ok)
      fail_clause("X3", "non-ARP frame header or payload was not accepted in time");

    bfm_wait(80);
    @(negedge clk);
    if (bfm_rx.size() != fbase)
      fail_clause("A3", "non-ARP frame was answered");

    start_miss(IP_NONARP, IP_NONARP, "A3/Q2",
               fbase, rbase, accepted_at);
    resolve_with_reply(IP_NONARP, MAC_NONARP, rbase, "Q6", resolved_at);

    // -----------------------------------------------------------------------
    // C2: starting empty, four entries must coexist.  After a fifth insert,
    // only the newly inserted entry is required to survive (L1).
    // -----------------------------------------------------------------------
    bfm_reset();

    for (i = 0; i < 4; i++) begin
      bfm_send(16'd2, MAC_CAP_BASE + i, IP_CAP_BASE + i,
               cfg_local_mac, cfg_local_ip, ok);
      if (!ok)
        fail_clause("X3", "cache-fill ARP reply was not accepted in time");
    end

    for (i = 0; i < 4; i++)
      check_cache_hit(IP_CAP_BASE + i, MAC_CAP_BASE + i, "C1/C2");

    bfm_send(16'd2, MAC_CAP_BASE + 4, IP_CAP_BASE + 4,
             cfg_local_mac, cfg_local_ip, ok);
    if (!ok)
      fail_clause("X3", "fifth cache-fill ARP reply was not accepted in time");

    check_cache_hit(IP_CAP_BASE + 4, MAC_CAP_BASE + 4, "C2");

    // -----------------------------------------------------------------------
    // C3: clearing the cache makes even the most recently inserted address
    // unknown again.
    // -----------------------------------------------------------------------
    @(negedge clk);
    clr_cache = 1'b1;
    @(posedge clk);
    @(negedge clk);
    clr_cache = 1'b0;

    start_miss(IP_CAP_BASE + 32'd4, IP_CAP_BASE + 32'd4, "C3/Q2",
               fbase, rbase, accepted_at);
    resolve_with_reply(IP_CAP_BASE + 32'd4, MAC_CAP_BASE + 4,
                       rbase, "Q6", resolved_at);

    // -----------------------------------------------------------------------
    // X2: reset while a lookup is outstanding.  No old retry or response may
    // survive, and an address cached before reset must miss afterwards.
    // -----------------------------------------------------------------------
    start_miss(IP_X2_MISS, IP_X2_MISS, "Q2/Q3",
               fbase, rbase, accepted_at);
    bfm_reset();

    @(negedge clk);
    fbase = bfm_rx.size();
    rbase = resp_log.size();
    bfm_wait(600);
    @(negedge clk);
    if (bfm_rx.size() != fbase)
      fail_clause("X2", "a request from the pre-reset lookup survived reset");
    if (resp_log.size() != rbase)
      fail_clause("X2", "a response from the pre-reset lookup survived reset");

    start_miss(IP_CAP_BASE + 32'd4, IP_CAP_BASE + 32'd4, "X2/Q2",
               fbase, rbase, accepted_at);
    resolve_with_reply(IP_CAP_BASE + 32'd4, MAC_CAP_BASE + 4,
                       rbase, "Q6", resolved_at);

    $display("All ARP engine checks completed.");
    $display("RESULT: PASS");
    $finish;
  end

endmodule
