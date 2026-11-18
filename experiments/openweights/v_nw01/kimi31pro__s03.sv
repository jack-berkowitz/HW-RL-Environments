`timescale 1ns/1ps

module arp_engine_tb;

  // ---------------------------------------------------------------------------
  // PROVIDED PLUMBING -- moves frames and lookups, checks nothing.
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
    p[0]=8'h00; p[1]=8'h01; p[2]=8'h08; p[3]=8'h00;
    p[4]=8'd6; p[5]=8'd4;
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

  typedef struct packed {
    logic        err;
    logic [47:0] mac;
    int          at;
  } resp_item_t;

  resp_item_t resp_q [$];
  bit reset_bad = 1'b0;
  int tx_hdr_total = 0;

  // Record responses so that a response coincident with another BFM operation
  // cannot be missed. Header timestamps use the same cycle domain as bfm_rx.at.
  always @(posedge clk) begin
    if (rst) begin
      if (m_hv || m_pv || rs_v)
        reset_bad = 1'b1;
    end else begin
      if (m_hv && m_hr)
        tx_hdr_total = tx_hdr_total + 1;
      if (rs_v && rs_r) begin
        automatic resp_item_t item;
        item.err = rs_e;
        item.mac = rs_mac;
        item.at = bfm_cycle;
        resp_q.push_back(item);
      end
    end
  end

  task automatic die(input string clause, input string detail);
    begin
      $display("FAIL [%s] %s", clause, detail);
      $display("RESULT: FAIL");
      $finish;
    end
  endtask

  task automatic phase_reset;
    begin
      bfm_reset();
      @(negedge clk);
      bfm_rx.delete();
      resp_q.delete();
      if (reset_bad)
        die("X1", "an output valid was asserted while synchronous reset was high");
    end
  endtask

  task automatic offer_lookup(input logic [31:0] ip, output bit ok,
                              output int accepted_at);
    int t;
    begin
      ok = 1'b0;
      accepted_at = -1;
      @(negedge clk);
      rq_ip = ip;
      rq_v = 1'b1;
      for (t = 0; t < 32; t = t + 1) begin
        @(posedge clk);
        if (rq_r) begin
          ok = 1'b1;
          accepted_at = bfm_cycle;
          break;
        end
      end
      @(negedge clk);
      rq_v = 1'b0;
    end
  endtask

  task automatic wait_response_count(input int wanted, input int limit,
                                     output bit ok);
    int t;
    begin
      ok = (resp_q.size() >= wanted);
      for (t = 0; t < limit && !ok; t = t + 1) begin
        @(posedge clk);
        if (resp_q.size() >= wanted)
          ok = 1'b1;
      end
    end
  endtask

  task automatic wait_frame_count(input int wanted, input int limit,
                                  output bit ok);
    int t;
    begin
      ok = (bfm_rx.size() >= wanted);
      for (t = 0; t < limit && !ok; t = t + 1) begin
        @(posedge clk);
        if (bfm_rx.size() >= wanted)
          ok = 1'b1;
      end
    end
  endtask

  task automatic wait_header_count(input int wanted, input int limit,
                                   output bit ok);
    int t;
    begin
      ok = (tx_hdr_total >= wanted);
      for (t = 0; t < limit && !ok; t = t + 1) begin
        @(posedge clk);
        if (tx_hdr_total >= wanted)
          ok = 1'b1;
      end
    end
  endtask

  task automatic check_f(input bfm_frame_t f, input string tag);
    begin
      if (f.eth_type !== 16'h0806)
        die("F", $sformatf("%s: Ethernet type was %04x, not 0806",
                           tag, f.eth_type));
      if (f.nbytes != 28)
        die("F", $sformatf("%s: payload length was %0d, not 28",
                           tag, f.nbytes));
      if (f.htype !== 16'h0001)
        die("F", $sformatf("%s: bad hardware type %04x", tag, f.htype));
      if (f.ptype !== 16'h0800)
        die("F", $sformatf("%s: bad protocol type %04x", tag, f.ptype));
      if (f.hlen !== 8'd6)
        die("F", $sformatf("%s: bad hardware length %0d", tag, f.hlen));
      if (f.plen !== 8'd4)
        die("F", $sformatf("%s: bad protocol length %0d", tag, f.plen));
    end
  endtask

  task automatic check_request(input bfm_frame_t f,
                               input logic [31:0] asked_ip,
                               input string tag);
    begin
      check_f(f, tag);
      if (f.oper !== 16'd1)
        die("Q2", $sformatf("%s: operation was %0d, not request", tag, f.oper));
      if (f.dest_mac !== 48'hff_ff_ff_ff_ff_ff)
        die("Q2", $sformatf("%s: request was not broadcast", tag));
      if (f.sha !== cfg_local_mac)
        die("Q2", $sformatf("%s: SHA was not local_mac_i", tag));
      if (f.spa !== cfg_local_ip)
        die("Q2", $sformatf("%s: SPA was not local_ip_i", tag));
      if (f.tha !== 48'd0)
        die("Q2", $sformatf("%s: THA was nonzero", tag));
      if (f.tpa !== asked_ip)
        die("Q3", $sformatf("%s: TPA was %08x, expected %08x",
                            tag, f.tpa, asked_ip));
    end
  endtask

  task automatic check_a1_reply(input bfm_frame_t f,
                                input logic [47:0] requester_mac,
                                input logic [31:0] requester_ip,
                                input string tag);
    begin
      check_f(f, tag);
      if (f.oper !== 16'd2)
        die("A1", $sformatf("%s: operation was not reply", tag));
      if (f.dest_mac !== requester_mac)
        die("A1", $sformatf("%s: reply destination was not requester SHA", tag));
      if (f.sha !== cfg_local_mac)
        die("A1", $sformatf("%s: reply SHA was not local_mac_i", tag));
      if (f.spa !== cfg_local_ip)
        die("A1", $sformatf("%s: reply SPA was not local_ip_i", tag));
      if (f.tha !== requester_mac)
        die("A1", $sformatf("%s: reply THA was not requester SHA", tag));
      if (f.tpa !== requester_ip)
        die("A1", $sformatf("%s: reply TPA was not requester SPA", tag));
    end
  endtask

  // A lookup following a learning frame must be a cache hit. This routine does
  // not assume whether the response coincides with acceptance or follows it.
  task automatic check_cached_lookup(input logic [31:0] ip,
                                     input logic [47:0] expected_mac,
                                     input string tag);
    bit ok;
    int accepted_at;
    int old_frames;
    int old_responses;
    resp_item_t r;
    begin
      old_frames = bfm_rx.size();
      old_responses = resp_q.size();

      offer_lookup(ip, ok, accepted_at);
      if (!ok)
        die("X3", $sformatf("%s: lookup was not accepted within 32 cycles", tag));

      wait_response_count(old_responses + 1, 40, ok);
      if (!ok)
        die("Q1/C1", $sformatf("%s: learned address was not answered from cache",
                               tag));

      r = resp_q[old_responses];
      if ((r.at < accepted_at) || ((r.at - accepted_at) > 32))
        die("X3", $sformatf("%s: cache-hit response took %0d cycles",
                            tag, r.at - accepted_at));
      if (r.err !== 1'b0)
        die("Q1", $sformatf("%s: cache hit incorrectly reported an error", tag));
      if (r.mac !== expected_mac)
        die("Q1/C1", $sformatf("%s: returned MAC %012x, expected %012x",
                               tag, r.mac, expected_mac));

      bfm_wait(45);
      @(negedge clk);
      if (bfm_rx.size() != old_frames)
        die("Q1", $sformatf("%s: cache hit caused a frame to be transmitted",
                            tag));
    end
  endtask

  // ---------------------------------------------------------------------------
  // A1, C1 and Q1: answer a request for us, learn its sender, then hit cache.
  // ---------------------------------------------------------------------------
  task automatic test_answer_and_learn;
    logic [47:0] peer_mac;
    logic [31:0] peer_ip;
    bit ok;
    bfm_frame_t f;
    begin
      phase_reset();
      peer_mac = 48'h02_00_00_00_00_11;
      peer_ip  = 32'hC0A8_0111;

      bfm_send(16'd1, peer_mac, peer_ip, 48'd0, cfg_local_ip, ok);
      if (!ok)
        die("X3", "A1 frame header or payload was not accepted within 32 cycles");

      wait_frame_count(1, 160, ok);
      if (!ok)
        die("A1", "request for local_ip_i was not answered");

      @(negedge clk);
      f = bfm_rx[0];
      check_a1_reply(f, peer_mac, peer_ip, "local request");

      bfm_wait(40);
      @(negedge clk);
      if (bfm_rx.size() != 1)
        die("A1", "more than one reply was generated for one request");

      check_cached_lookup(peer_ip, peer_mac, "sender learned from ARP request");
    end
  endtask

  // ---------------------------------------------------------------------------
  // A2 and C1: a request for somebody else is unanswered but still learned.
  // ---------------------------------------------------------------------------
  task automatic test_other_target;
    logic [47:0] peer_mac;
    logic [31:0] peer_ip;
    logic [31:0] other_ip;
    bit ok;
    begin
      phase_reset();
      peer_mac = 48'h02_00_00_00_00_12;
      peer_ip  = 32'hC0A8_0112;
      other_ip = 32'hC0A8_0199;

      bfm_send(16'd1, peer_mac, peer_ip, 48'd0, other_ip, ok);
      if (!ok)
        die("X3", "A2 frame was not accepted within the liveness bound");

      bfm_wait(80);
      @(negedge clk);
      if (bfm_rx.size() != 0)
        die("A2", "request whose TPA was not local_ip_i was answered");

      check_cached_lookup(peer_ip, peer_mac,
                          "sender of request for another target");
    end
  endtask

  // ---------------------------------------------------------------------------
  // A3 and Q2/Q3: non-ARP traffic is neither answered nor learned. The ensuing
  // miss also checks an inside-subnet request.
  // ---------------------------------------------------------------------------
  task automatic test_non_arp;
    logic [47:0] peer_mac;
    logic [31:0] peer_ip;
    bit ok;
    int accepted_at;
    bfm_frame_t f;
    begin
      phase_reset();
      peer_mac = 48'h02_00_00_00_00_13;
      peer_ip  = 32'hC0A8_0113;

      bfm_send(16'd1, peer_mac, peer_ip, 48'd0, cfg_local_ip, ok,
               16'h0800);
      if (!ok)
        die("X3", "non-ARP frame was not accepted within the liveness bound");

      bfm_wait(80);
      @(negedge clk);
      if (bfm_rx.size() != 0)
        die("A3", "non-ARP frame was answered");

      offer_lookup(peer_ip, ok, accepted_at);
      if (!ok)
        die("X3", "lookup after non-ARP frame was not accepted");

      wait_frame_count(1, 160, ok);
      if (!ok)
        die("A3/Q2", "non-ARP sender appears to have been learned, or no request was sent");

      @(negedge clk);
      if (resp_q.size() != 0)
        die("A3", "non-ARP frame inserted its sender into the cache");
      f = bfm_rx[0];
      check_request(f, peer_ip, "inside-subnet miss");
    end
  endtask

  // ---------------------------------------------------------------------------
  // C3: learn and prove an entry, clear the cache, and prove it is now a miss.
  // ---------------------------------------------------------------------------
  task automatic test_clear_cache;
    logic [47:0] peer_mac;
    logic [31:0] peer_ip;
    bit ok;
    int accepted_at;
    bfm_frame_t f;
    begin
      phase_reset();
      peer_mac = 48'h02_00_00_00_00_14;
      peer_ip  = 32'hC0A8_0114;

      bfm_send(16'd2, peer_mac, peer_ip, cfg_local_mac, cfg_local_ip, ok);
      if (!ok)
        die("X3", "ARP reply used for C3 was not accepted");

      bfm_wait(50);
      @(negedge clk);
      if (bfm_rx.size() != 0)
        die("A1", "an ARP reply unexpectedly generated a transmitted frame");

      check_cached_lookup(peer_ip, peer_mac, "entry before clear_cache_i");

      @(negedge clk);
      clr_cache = 1'b1;
      @(posedge clk);
      @(negedge clk);
      clr_cache = 1'b0;

      offer_lookup(peer_ip, ok, accepted_at);
      if (!ok)
        die("X3", "lookup after clear_cache_i was not accepted");

      wait_frame_count(1, 160, ok);
      if (!ok)
        die("C3", "cleared entry was still answered from the cache");

      @(negedge clk);
      if (resp_q.size() != 0)
        die("C3", "cleared entry produced a cache-hit response");
      f = bfm_rx[0];
      check_request(f, peer_ip, "lookup after cache clear");
    end
  endtask

  // ---------------------------------------------------------------------------
  // C1/C2: five distinct inserts into a four-entry cache. The newest entry must
  // work. At least one older entry must be absent, but no particular older entry
  // is selected, preserving replacement-policy latitude L1.
  // ---------------------------------------------------------------------------
  task automatic test_capacity;
    logic [31:0] base_ip;
    logic [47:0] base_mac;
    logic [31:0] other_ip;
    bit ok;
    bit saw_miss;
    int i;
    int w;
    int old_frames;
    int old_responses;
    int accepted_at;
    bfm_frame_t f;
    resp_item_t r;
    begin
      phase_reset();
      base_ip  = 32'hC0A8_0120;
      base_mac = 48'h02_00_00_00_00_20;
      other_ip = 32'hC0A8_01AA;

      for (i = 0; i < 5; i = i + 1) begin
        bfm_send(16'd1, base_mac + i, base_ip + i, 48'd0, other_ip, ok);
        if (!ok)
          die("X3", $sformatf("capacity insert %0d was not accepted", i));
      end

      bfm_wait(60);
      @(negedge clk);
      if (bfm_rx.size() != 0)
        die("A2", "a capacity-test request for another target was answered");

      check_cached_lookup(base_ip + 4, base_mac + 4,
                          "newest insert into a full cache");

      saw_miss = 1'b0;
      for (i = 0; i < 4; i = i + 1) begin
        if (!saw_miss) begin
          old_frames = bfm_rx.size();
          old_responses = resp_q.size();

          offer_lookup(base_ip + i, ok, accepted_at);
          if (!ok)
            die("X3", "capacity probe was not accepted within 32 cycles");

          ok = (resp_q.size() > old_responses) ||
               (bfm_rx.size() > old_frames);
          for (w = 0; w < 80 && !ok; w = w + 1) begin
            @(posedge clk);
            if ((resp_q.size() > old_responses) ||
                (bfm_rx.size() > old_frames))
              ok = 1'b1;
          end
          if (!ok)
            die("Q1/Q2", "capacity probe produced neither a response nor a request");

          @(negedge clk);
          if (resp_q.size() > old_responses) begin
            r = resp_q[old_responses];
            if ((r.at < accepted_at) || ((r.at - accepted_at) > 32))
              die("X3", "surviving capacity entry missed the cache-hit bound");
            if (r.err !== 1'b0)
              die("Q1", "surviving capacity entry returned an error");
            if (r.mac !== (base_mac + i))
              die("C1", "surviving capacity entry returned the wrong MAC");

            bfm_wait(45);
            @(negedge clk);
            if (bfm_rx.size() != old_frames)
              die("Q1", "surviving capacity entry also caused a network request");
          end else begin
            // Stop at the first miss: no network resolution is allowed to alter
            // the cache before the capacity conclusion has been established.
            saw_miss = 1'b1;
            f = bfm_rx[old_frames];
            check_request(f, base_ip + i, "displaced capacity entry");
          end
        end
      end

      if (!saw_miss)
        die("C2", "newest entry plus all four older entries survived: capacity exceeded four");
    end
  endtask

  // ---------------------------------------------------------------------------
  // Q4/Q5: leave a lookup unanswered and observe all retries and the timeout.
  // ---------------------------------------------------------------------------
  task automatic test_retries_and_timeout;
    logic [31:0] target_ip;
    bit ok;
    int accepted_at;
    int i;
    int gap;
    int response_delay;
    resp_item_t r;
    begin
      phase_reset();
      target_ip = 32'hC0A8_0164;

      offer_lookup(target_ip, ok, accepted_at);
      if (!ok)
        die("X3", "retry-test lookup was not accepted within 32 cycles");

      wait_response_count(1, 900, ok);
      if (!ok)
        die("Q4/Q5", "unanswered lookup did not reach its error response");

      @(negedge clk);
      r = resp_q[0];

      if (bfm_rx.size() != 4)
        die("Q4", $sformatf("unanswered lookup generated %0d requests, not exactly 4",
                            bfm_rx.size()));
      if (r.err !== 1'b1)
        die("Q5", "unanswered lookup did not report resp_error_o high");

      for (i = 0; i < 4; i = i + 1)
        check_request(bfm_rx[i], target_ip,
                      $sformatf("retry request %0d", i + 1));

      for (i = 1; i < 4; i = i + 1) begin
        gap = bfm_rx[i].at - bfm_rx[i-1].at;
        if ((gap < 64) || (gap > 80))
          die("Q4", $sformatf("requests %0d and %0d were %0d cycles apart",
                              i, i + 1, gap));
      end

      response_delay = r.at - bfm_rx[3].at;
      if ((response_delay < 256) || (response_delay > 300))
        die("Q5", $sformatf("error response came %0d cycles after fourth request",
                            response_delay));

      bfm_wait(100);
      @(negedge clk);
      if (bfm_rx.size() != 4)
        die("Q4", "a fifth request appeared after the timeout response");
    end
  endtask

  // ---------------------------------------------------------------------------
  // Q3/Q6: an outside-subnet lookup asks for the gateway, and a matching reply
  // resolves it. Requests already emitted before resolution are not counted as
  // "further" requests; any request after resolution is.
  // ---------------------------------------------------------------------------
  task automatic test_gateway_resolution;
    logic [31:0] outside_ip;
    logic [47:0] gateway_mac;
    bit ok;
    int accepted_at;
    int header_base;
    int i;
    resp_item_t r;
    begin
      phase_reset();
      outside_ip = 32'h0A00_0001;
      gateway_mac = 48'h02_00_00_00_00_66;

      header_base = tx_hdr_total;
      offer_lookup(outside_ip, ok, accepted_at);
      if (!ok)
        die("X3", "outside-subnet lookup was not accepted within 32 cycles");

      // Start supplying the answer at the first request header rather than
      // waiting for its entire payload, giving resolution a chance before retry.
      wait_header_count(header_base + 1, 100, ok);
      if (!ok)
        die("Q2", "outside-subnet lookup did not emit a request header");

      bfm_send(16'd2, gateway_mac, cfg_gateway_ip,
               cfg_local_mac, cfg_local_ip, ok);
      if (!ok)
        die("X3", "resolving ARP reply was not accepted within the liveness bound");

      wait_response_count(1, 700, ok);
      if (!ok)
        die("Q6", "matching ARP reply did not resolve the outstanding lookup");

      wait_frame_count(1, 160, ok);
      if (!ok)
        die("Q2", "outside-subnet request payload was not completed");

      @(negedge clk);
      r = resp_q[0];
      if (r.err !== 1'b0)
        die("Q6", "matching ARP reply produced an error response");
      if (r.mac !== gateway_mac)
        die("Q6", $sformatf("resolved MAC was %012x, expected reply SHA %012x",
                            r.mac, gateway_mac));

      check_request(bfm_rx[0], cfg_gateway_ip, "outside-subnet request");

      bfm_wait(140);
      @(negedge clk);
      for (i = 0; i < bfm_rx.size(); i = i + 1) begin
        check_request(bfm_rx[i], cfg_gateway_ip, "gateway-resolution request");
        if (bfm_rx[i].at > r.at)
          die("Q6", "a request was transmitted after the lookup had resolved");
      end
    end
  endtask

  // ---------------------------------------------------------------------------
  // X2: reset empties a populated cache and cancels an outstanding lookup.
  // ---------------------------------------------------------------------------
  task automatic test_reset_state;
    logic [47:0] peer_mac;
    logic [31:0] peer_ip;
    logic [31:0] other_ip;
    bit ok;
    int accepted_at;
    bfm_frame_t f;
    begin
      phase_reset();
      peer_mac = 48'h02_00_00_00_00_15;
      peer_ip  = 32'hC0A8_0115;
      other_ip = 32'hC0A8_01AB;

      bfm_send(16'd1, peer_mac, peer_ip, 48'd0, other_ip, ok);
      if (!ok)
        die("X3", "reset-state learning frame was not accepted");

      bfm_wait(50);
      check_cached_lookup(peer_ip, peer_mac, "entry before reset");

      phase_reset();
      offer_lookup(peer_ip, ok, accepted_at);
      if (!ok)
        die("X3", "post-reset lookup was not accepted");

      wait_frame_count(1, 160, ok);
      if (!ok)
        die("X2", "an address learned before reset remained cached");

      @(negedge clk);
      if (resp_q.size() != 0)
        die("X2", "post-reset lookup was answered from the old cache");
      f = bfm_rx[0];
      check_request(f, peer_ip, "post-reset cache-empty lookup");

      // This lookup is outstanding. Reset must cancel its future retries and
      // timeout response as well as clearing the cache.
      phase_reset();
      bfm_wait(380);
      @(negedge clk);
      if (bfm_rx.size() != 0)
        die("X2", "a request from the pre-reset outstanding lookup survived reset");
      if (resp_q.size() != 0)
        die("X2", "a response from the pre-reset outstanding lookup survived reset");
    end
  endtask

  initial begin
    test_answer_and_learn();
    test_other_target();
    test_non_arp();
    test_clear_cache();
    test_capacity();
    test_retries_and_timeout();
    test_gateway_resolution();
    test_reset_state();

    $display("RESULT: PASS");
    $finish;
  end

endmodule
