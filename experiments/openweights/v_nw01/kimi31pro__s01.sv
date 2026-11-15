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

  // ---- every frame the design sends, unpacked --------------------------------
  typedef struct packed {
    logic [47:0] dest_mac, src_mac;
    logic [15:0] eth_type, htype, ptype, oper;
    logic [7:0]  hlen, plen;
    logic [47:0] sha, tha;
    logic [31:0] spa, tpa;
    int          at;          // the cycle its header moved
    int          nbytes;      // payload length, so you can check it yourself
  } bfm_frame_t;

  bfm_frame_t bfm_rx [$];     // frames captured from the design
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

  // ---- driving a frame in ----------------------------------------------------
  // Returns without waiting for any response. `ok` is low if the design did not
  // accept the header or a payload byte within `limit` cycles.
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

  // ---- offering a lookup ------------------------------------------------------
  task automatic bfm_lookup(input logic [31:0] ip, output bit ok, input int limit = 32);
    ok = 1'b0;
    @(negedge clk); rq_ip = ip; rq_v = 1'b1;
    for (int t=0;t<limit;t++) begin @(posedge clk); if (rq_r) begin ok = 1'b1; break; end end
    @(negedge clk) rq_v = 1'b0;
  endtask

  // Waits for a response. `got` is low if none arrived within `limit` cycles.
  task automatic bfm_await(input int limit, output bit got, output bit err,
                           output logic [47:0] mac, output int took);
    got = 1'b0; err = 1'b0; mac = '0; took = 0;
    for (int t=0;t<limit;t++) begin
      @(posedge clk); took = t;
      if (rs_v) begin got = 1'b1; err = rs_e; mac = rs_mac; break; end
    end
  endtask

  task automatic bfm_wait(input int n); repeat (n) @(posedge clk); endtask

  // ---- watchdog ---------------------------------------------------------------
  // Yours to keep. It fires regardless of what the design does: one of the
  // faulty designs never accepts a lookup at all, and without this your
  // testbench hangs instead of reporting. A hang is not a verdict.
  initial begin
    #8_000_000;
    $display("RESULT: FAIL (watchdog: no verdict reached)");
    $finish;
  end

  // ---------------------------------------------------------------------------
  // Testbench bookkeeping and checking
  // ---------------------------------------------------------------------------

  typedef struct packed {
    logic        err;
    logic [47:0] mac;
    int          at;
  } resp_item_t;

  resp_item_t resp_stream_q [$];
  resp_item_t resp_tmp;
  int errors = 0;

  // Capture responses by handshake, so even a response coincident with a lookup
  // acceptance cannot be missed by the stimulus tasks.
  always @(posedge clk) begin
    if (!rst && rs_v && rs_r) begin
      resp_tmp.err = rs_e;
      resp_tmp.mac = rs_mac;
      resp_tmp.at  = bfm_cycle;
      resp_stream_q.push_back(resp_tmp);
    end
  end

  task automatic note_fail(input string clause, input string msg);
    begin
      errors++;
      $display("CHECK FAIL [%s] cycle %0d: %s", clause, bfm_cycle, msg);
    end
  endtask

  // Reset every phase so that tests never depend on replacement policy or on
  // behaviour of a second lookup while one is outstanding.  Checking is done
  // after each rising edge, as required for synchronous reset.
  task automatic fresh;
    begin
      @(negedge clk);
      rst = 1'b1;
      repeat (6) begin
        @(posedge clk);
        @(negedge clk);
        if ((m_hv !== 1'b0) || (m_pv !== 1'b0) || (rs_v !== 1'b0))
          note_fail("X1", "an output valid was asserted while reset was high");
      end
      rst = 1'b0;
      repeat (3) @(posedge clk);
      @(negedge clk);

      bfm_rx.delete();
      bfm_buf.delete();
      resp_stream_q.delete();

      s_hv = 1'b0;
      s_pv = 1'b0;
      s_pl = 1'b0;
      rq_v = 1'b0;
      clr_cache = 1'b0;
      m_hr = 1'b1;
      m_pr = 1'b1;
      rs_r = 1'b1;
    end
  endtask

  task automatic wait_frames(input int target, input int limit, output bit got);
    begin
      got = 1'b0;
      for (int t = 0; t < limit; t++) begin
        if (bfm_rx.size() >= target) begin
          got = 1'b1;
          return;
        end
        @(negedge clk);
      end
      got = (bfm_rx.size() >= target);
    end
  endtask

  task automatic wait_response(input int limit, output bit got);
    begin
      got = 1'b0;
      for (int t = 0; t < limit; t++) begin
        if (resp_stream_q.size() != 0) begin
          got = 1'b1;
          return;
        end
        @(negedge clk);
      end
      got = (resp_stream_q.size() != 0);
    end
  endtask

  task automatic pulse_clear;
    begin
      @(negedge clk);
      clr_cache = 1'b1;
      @(posedge clk);
      @(negedge clk);
      clr_cache = 1'b0;
    end
  endtask

  task automatic check_common_frame(input bfm_frame_t f, input string clause);
    begin
      if (f.eth_type !== 16'h0806)
        note_fail(clause, $sformatf("eth_type was %04x, not 0806", f.eth_type));
      if (f.nbytes != 28)
        note_fail("F", $sformatf("ARP payload length was %0d, not 28", f.nbytes));
      if (f.htype !== 16'h0001)
        note_fail("F", $sformatf("hardware type was %04x", f.htype));
      if (f.ptype !== 16'h0800)
        note_fail("F", $sformatf("protocol type was %04x", f.ptype));
      if (f.hlen !== 8'd6)
        note_fail("F", $sformatf("hardware length was %0d", f.hlen));
      if (f.plen !== 8'd4)
        note_fail("F", $sformatf("protocol length was %0d", f.plen));
    end
  endtask

  task automatic check_request_frame(input bfm_frame_t f,
                                     input logic [31:0] wanted_tpa,
                                     input string clause);
    begin
      check_common_frame(f, "F/Q2");
      if (f.dest_mac !== 48'hFF_FF_FF_FF_FF_FF)
        note_fail("Q2", $sformatf("request destination was %012x, not broadcast",
                                  f.dest_mac));
      if (f.oper !== 16'd1)
        note_fail("Q2", $sformatf("request operation was %0d, not 1", f.oper));
      if (f.sha !== cfg_local_mac)
        note_fail("Q2", $sformatf("request SHA was %012x, expected %012x",
                                  f.sha, cfg_local_mac));
      if (f.spa !== cfg_local_ip)
        note_fail("Q2", $sformatf("request SPA was %08x, expected %08x",
                                  f.spa, cfg_local_ip));
      if (f.tha !== 48'h0)
        note_fail("Q2", $sformatf("request THA was %012x, not zero", f.tha));
      if (f.tpa !== wanted_tpa)
        note_fail(clause, $sformatf("request TPA was %08x, expected %08x",
                                    f.tpa, wanted_tpa));
    end
  endtask

  // A guaranteed cache hit: successful response within 32 cycles and no frame.
  task automatic check_cache_hit(input logic [31:0] ip,
                                 input logic [47:0] wanted_mac,
                                 input string clause);
    bit ok;
    bit got;
    int base;
    resp_item_t r;
    begin
      base = bfm_rx.size();
      bfm_lookup(ip, ok);
      if (!ok) begin
        note_fail("X3", $sformatf("lookup of %08x was not accepted within 32 cycles", ip));
        return;
      end

      got = 1'b0;
      for (int t = 0; t <= 32; t++) begin
        if (resp_stream_q.size() != 0) begin
          got = 1'b1;
          break;
        end
        if (t != 32) @(negedge clk);
      end

      if (!got) begin
        note_fail(clause, $sformatf("cached lookup of %08x was not answered within 32 cycles", ip));
      end else begin
        r = resp_stream_q.pop_front();
        if (r.err !== 1'b0)
          note_fail("Q1", $sformatf("cached lookup of %08x returned an error", ip));
        else if (r.mac !== wanted_mac)
          note_fail(clause, $sformatf("lookup of %08x returned MAC %012x, expected %012x",
                                      ip, r.mac, wanted_mac));
      end

      // Long enough to include a complete erroneously emitted ARP request.
      bfm_wait(90);
      @(negedge clk);
      if (bfm_rx.size() != base)
        note_fail("Q1", $sformatf("cached lookup of %08x transmitted a frame", ip));
      if (resp_stream_q.size() != 0)
        note_fail("Q1", $sformatf("cached lookup of %08x produced extra responses", ip));
    end
  endtask

  // A lookup which must miss and go to the network.  This task deliberately
  // leaves the lookup outstanding; the caller starts a fresh phase afterwards
  // or explicitly resolves it.
  task automatic check_network_lookup(input logic [31:0] ip,
                                      input logic [31:0] wanted_tpa,
                                      input string clause);
    bit ok;
    bit got;
    int base;
    bfm_frame_t f;
    begin
      base = bfm_rx.size();
      bfm_lookup(ip, ok);
      if (!ok) begin
        note_fail("X3", $sformatf("lookup of %08x was not accepted within 32 cycles", ip));
        return;
      end

      wait_frames(base + 1, 180, got);
      if (!got) begin
        note_fail(clause, $sformatf("lookup of %08x did not produce an ARP request", ip));
      end else begin
        f = bfm_rx[base];
        check_request_frame(f, wanted_tpa, clause);
      end

      if (resp_stream_q.size() != 0)
        note_fail(clause, $sformatf("lookup of %08x was answered locally instead of going to the network",
                                    ip));
    end
  endtask

  // ---------------------------------------------------------------------------
  // Individual specification tests
  // ---------------------------------------------------------------------------

  task automatic check_initial_reset;
    begin
      // Do not inspect outputs at time zero.  The first inspection is after the
      // first rising edge, exactly as X1 requires.
      repeat (3) begin
        @(posedge clk);
        @(negedge clk);
        if ((m_hv !== 1'b0) || (m_pv !== 1'b0) || (rs_v !== 1'b0))
          note_fail("X1", "output valid was not low after a rising edge with reset high");
      end
    end
  endtask

  task automatic test_a1_and_request_learning;
    bit ok;
    bit got;
    bfm_frame_t f;
    begin
      fresh();
      bfm_send(16'd1, 48'h02_00_00_00_00_11, 32'hC0A8_0111,
               48'h0, cfg_local_ip, ok);
      if (!ok) begin
        note_fail("X3", "ARP request for the local IP was not accepted within the byte/header bounds");
        return;
      end

      wait_frames(1, 160, got);
      if (!got) begin
        note_fail("A1", "request for local_ip_i was not answered");
        return;
      end

      f = bfm_rx[0];
      check_common_frame(f, "F/A1");
      if (f.oper !== 16'd2)
        note_fail("A1", $sformatf("reply operation was %0d, not 2", f.oper));
      if (f.dest_mac !== 48'h02_00_00_00_00_11)
        note_fail("A1", $sformatf("reply destination was %012x", f.dest_mac));
      if (f.sha !== cfg_local_mac)
        note_fail("A1", $sformatf("reply SHA was %012x", f.sha));
      if (f.spa !== cfg_local_ip)
        note_fail("A1", $sformatf("reply SPA was %08x", f.spa));
      if (f.tha !== 48'h02_00_00_00_00_11)
        note_fail("A1", $sformatf("reply THA was %012x", f.tha));
      if (f.tpa !== 32'hC0A8_0111)
        note_fail("A1", $sformatf("reply TPA was %08x", f.tpa));

      bfm_wait(90);
      @(negedge clk);
      if (bfm_rx.size() != 1)
        note_fail("A1", $sformatf("one local request produced %0d frames", bfm_rx.size()));

      // C1 applies to requests as well as replies; Q1 forbids another frame.
      check_cache_hit(32'hC0A8_0111, 48'h02_00_00_00_00_11, "C1");
    end
  endtask

  task automatic test_a2_other_target;
    bit ok;
    begin
      fresh();
      bfm_send(16'd1, 48'h02_00_00_00_00_12, 32'hC0A8_0112,
               48'h0, 32'hC0A8_0199, ok);
      if (!ok) begin
        note_fail("X3", "ARP request aimed at another station was not accepted");
        return;
      end

      bfm_wait(100);
      @(negedge clk);
      if (bfm_rx.size() != 0)
        note_fail("A2", "request whose TPA was not local_ip_i was answered");

      // It is not answered, but it is still an ARP frame and must be learned.
      check_cache_hit(32'hC0A8_0112, 48'h02_00_00_00_00_12, "C1");
    end
  endtask

  task automatic test_reply_learning;
    bit ok;
    begin
      fresh();
      bfm_send(16'd2, 48'h02_00_00_00_00_13, 32'hC0A8_0113,
               cfg_local_mac, cfg_local_ip, ok);
      if (!ok) begin
        note_fail("X3", "ARP reply used for cache learning was not accepted");
        return;
      end
      check_cache_hit(32'hC0A8_0113, 48'h02_00_00_00_00_13, "C1");
    end
  endtask

  task automatic test_non_arp;
    bit ok;
    begin
      fresh();
      bfm_send(16'd1, 48'h02_00_00_00_00_14, 32'hC0A8_0114,
               48'h0, cfg_local_ip, ok, 16'h0800);
      if (!ok) begin
        note_fail("X3", "non-ARP input frame was not accepted within the liveness bounds");
        return;
      end

      bfm_wait(100);
      @(negedge clk);
      if (bfm_rx.size() != 0)
        note_fail("A3", "non-ARP frame was answered");
      if (resp_stream_q.size() != 0)
        note_fail("A3", "non-ARP frame caused a lookup response");

      // If the frame had been learned, this would be a cache hit and no request
      // would appear.  A request demonstrates that it was ignored entirely.
      check_network_lookup(32'hC0A8_0114, 32'hC0A8_0114, "A3");
    end
  endtask

  task automatic test_inside_subnet;
    begin
      fresh();
      check_network_lookup(32'hC0A8_0142, 32'hC0A8_0142, "Q3");
    end
  endtask

  task automatic test_outside_subnet;
    begin
      fresh();
      check_network_lookup(32'hC000_0237, cfg_gateway_ip, "Q3");
    end
  endtask

  task automatic test_retries_and_timeout;
    bit ok;
    bit got;
    int delta;
    int fourth_at;
    bfm_frame_t f;
    resp_item_t r;
    begin
      fresh();
      bfm_lookup(32'hC0A8_0177, ok);
      if (!ok) begin
        note_fail("X3", "unanswered lookup was not accepted within 32 cycles");
        return;
      end

      wait_frames(4, 500, got);
      if (!got) begin
        note_fail("Q4", $sformatf("only %0d request frames were captured; exactly 4 are required",
                                  bfm_rx.size()));
        return;
      end

      for (int i = 0; i < 4; i++) begin
        f = bfm_rx[i];
        check_request_frame(f, 32'hC0A8_0177, "Q2/Q3");
      end

      for (int i = 1; i < 4; i++) begin
        delta = bfm_rx[i].at - bfm_rx[i-1].at;
        if ((delta < 64) || (delta > 80))
          note_fail("Q4", $sformatf("requests %0d and %0d were %0d cycles apart, outside 64..80",
                                    i, i+1, delta));
      end

      fourth_at = bfm_rx[3].at;
      got = 1'b0;
      for (int t = 0; t < 340; t++) begin
        if (resp_stream_q.size() != 0) begin
          got = 1'b1;
          break;
        end
        @(negedge clk);
      end

      if (!got) begin
        note_fail("Q5", "unanswered lookup did not produce its error response");
      end else begin
        r = resp_stream_q.pop_front();
        delta = r.at - fourth_at;
        if (r.err !== 1'b1)
          note_fail("Q5", "unanswered lookup did not set resp_error_o");
        if ((delta < 256) || (delta > 300))
          note_fail("Q5", $sformatf("error response came %0d cycles after request 4, outside 256..300",
                                    delta));
        // L2: deliberately do not inspect r.mac when r.err is high.
      end

      bfm_wait(100);
      @(negedge clk);
      if (bfm_rx.size() != 4)
        note_fail("Q4", $sformatf("unanswered lookup ultimately transmitted %0d requests, not 4",
                                  bfm_rx.size()));
      if (resp_stream_q.size() != 0)
        note_fail("Q5", "unanswered lookup produced more than one response");
    end
  endtask

  task automatic test_reply_resolves;
    bit ok;
    bit send_ok;
    bit got;
    bit late_seen;
    bfm_frame_t f;
    resp_item_t r;
    begin
      fresh();
      bfm_lookup(32'hC0A8_0166, ok);
      if (!ok) begin
        note_fail("X3", "lookup used for resolution test was not accepted");
        return;
      end

      // Offer the resolving reply immediately.  Any requests which completed
      // before the reply was processed are permitted; requests after resolution
      // are not.
      bfm_send(16'd2, 48'h02_00_00_00_00_66, 32'hC0A8_0166,
               cfg_local_mac, cfg_local_ip, send_ok);
      if (!send_ok) begin
        note_fail("X3", "resolving ARP reply was not accepted within the liveness bounds");
        return;
      end

      wait_response(160, got);
      if (!got) begin
        note_fail("Q6", "matching ARP reply did not resolve the outstanding lookup");
      end else begin
        r = resp_stream_q.pop_front();
        if (r.err !== 1'b0)
          note_fail("Q6", "matching ARP reply produced an error response");
        else if (r.mac !== 48'h02_00_00_00_00_66)
          note_fail("Q6", $sformatf("resolved MAC was %012x", r.mac));
      end

      bfm_wait(320);
      @(negedge clk);

      if (bfm_rx.size() == 0) begin
        note_fail("Q2", "lookup resolved by a reply never transmitted its initial request");
      end else begin
        f = bfm_rx[0];
        check_request_frame(f, 32'hC0A8_0166, "Q3");
      end

      if (got) begin
        late_seen = 1'b0;
        for (int i = 0; i < bfm_rx.size(); i++) begin
          if (bfm_rx[i].at > r.at)
            late_seen = 1'b1;
        end
        if (late_seen)
          note_fail("Q6", "a request was transmitted after the matching reply resolved the lookup");
      end

      if (resp_stream_q.size() != 0)
        note_fail("Q6", "resolved lookup produced an additional response");
    end
  endtask

  task automatic test_cache_capacity;
    bit ok;
    logic [31:0] ip;
    logic [47:0] mac;
    begin
      fresh();

      // Check only the entry just inserted.  In particular, never require any
      // older entry to survive the fifth insertion: that is latitude L1.
      for (int i = 0; i < 5; i++) begin
        ip  = 32'hC0A8_0140 + i;
        mac = 48'h02_00_00_00_01_40 + i;
        bfm_send(16'd2, mac, ip, cfg_local_mac, cfg_local_ip, ok);
        if (!ok) begin
          note_fail("X3", $sformatf("ARP reply %0d used to fill the cache was not accepted", i));
          return;
        end

        if (i == 4)
          check_cache_hit(ip, mac, "C2");
        else
          check_cache_hit(ip, mac, "C1");
      end
    end
  endtask

  task automatic test_clear_cache;
    bit ok;
    bit all_sent;
    logic [31:0] ip;
    logic [47:0] mac;
    begin
      // Test every populated address in an independent phase.  Thus an
      // outstanding request from one clear test cannot affect the next.
      for (int k = 0; k < 4; k++) begin
        fresh();
        all_sent = 1'b1;

        for (int i = 0; i < 4; i++) begin
          ip  = 32'hC0A8_0140 + i;
          mac = 48'h02_00_00_00_01_40 + i;
          bfm_send(16'd2, mac, ip, cfg_local_mac, cfg_local_ip, ok);
          if (!ok) begin
            note_fail("X3", "frame used to populate the cache for C3 was not accepted");
            all_sent = 1'b0;
            break;
          end
        end

        if (all_sent) begin
          pulse_clear();
          ip = 32'hC0A8_0140 + k;
          check_network_lookup(ip, ip, "C3");
        end
      end
    end
  endtask

  task automatic test_reset_state;
    bit ok;
    begin
      // A cached entry must not survive reset.
      fresh();
      bfm_send(16'd2, 48'h02_00_00_00_00_55, 32'hC0A8_0155,
               cfg_local_mac, cfg_local_ip, ok);
      if (!ok)
        note_fail("X3", "frame used to populate the cache for X2 was not accepted");

      fresh();
      check_network_lookup(32'hC0A8_0155, 32'hC0A8_0155, "X2");

      // Nor may an outstanding lookup survive reset and later emit retries or
      // a timeout response.
      fresh();
      bfm_lookup(32'hC0A8_0188, ok);
      if (!ok)
        note_fail("X3", "lookup used for outstanding-reset test was not accepted");

      fresh();
      bfm_wait(400);
      @(negedge clk);
      if (bfm_rx.size() != 0)
        note_fail("X2", "frames were transmitted after reset from a pre-reset lookup");
      if (resp_stream_q.size() != 0)
        note_fail("X2", "a response arrived after reset from a pre-reset lookup");
    end
  endtask

  // ---------------------------------------------------------------------------
  // Main stimulus
  // ---------------------------------------------------------------------------

  initial begin : main_stimulus
    check_initial_reset();

    test_a1_and_request_learning();
    test_a2_other_target();
    test_reply_learning();
    test_non_arp();

    test_inside_subnet();
    test_outside_subnet();
    test_retries_and_timeout();
    test_reply_resolves();

    test_cache_capacity();
    test_clear_cache();
    test_reset_state();

    if (errors == 0)
      $display("RESULT: PASS");
    else
      $display("RESULT: FAIL");
    $finish;
  end

endmodule
