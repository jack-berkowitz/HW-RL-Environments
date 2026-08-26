// ===========================================================================
// arp_engine_tb.sv
//
// Decides whether a design on this port map obeys the ARP engine contract.
//
// HOW IT DECIDES
//   * Two posedge monitors do the observing: one counts transmitted frame
//     headers and captured responses (with timestamps taken from the same
//     cycle counter the plumbing stamps frames with, so intervals are
//     comparable), and one enforces X1 while reset is high.
//   * The stimulus is a sequence of phases, each of which sets up a situation
//     the contract names and then decides it.  Every wait is bounded, so a
//     design that accepts nothing fails rather than hanging (Termination).
//   * Results are identified by bookkeeping -- position in the captured frame
//     queue, and counter deltas taken either side of a phase -- never by
//     matching on payload.
//
// WHAT IT DELIBERATELY DOES NOT CHECK (the latitude, L1-L3)
//   * L1: which entry a full cache displaces.  Only the just-inserted address
//     is ever required to be present, and only the effect of C3.
//   * L2: resp_mac_o when resp_error_o is high is never read.
//   * L3: the exact cycle of any response or frame.  Only the counts and the
//     windows Q4, Q5 and X3 fix are checked.
//   Nor anything the contract is silent about: m_src_mac_o, s_payload_user_i,
//   payloads of other lengths, or a second lookup offered while one is
//   outstanding.
// ===========================================================================

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
  initial begin
    #8_000_000;
    $display("RESULT: FAIL (watchdog: no verdict reached)");
    $finish;
  end

  // ===========================================================================
  //                        FROM HERE ON: MY OWN CODE
  // ===========================================================================

  // ---- addresses used by the stimulus --------------------------------------
  localparam logic [47:0] BCAST  = 48'hFFFF_FFFF_FFFF;
  localparam logic [47:0] MAC_A  = 48'h02_00_00_00_0A_01;
  localparam logic [47:0] MAC_B  = 48'h02_00_00_00_0B_02;
  localparam logic [47:0] MAC_C  = 48'h02_00_00_00_0C_03;
  localparam logic [47:0] MAC_D  = 48'h02_00_00_00_0D_04;
  localparam logic [47:0] MAC_E  = 48'h02_00_00_00_0E_05;
  localparam logic [47:0] MAC_G  = 48'h02_00_00_00_66_FE;   // the gateway
  // in-subnet addresses (192.168.1.x, local is .1, gateway is .254)
  localparam logic [31:0] IP_A     = 32'hC0A8_0110;
  localparam logic [31:0] IP_B     = 32'hC0A8_0120;
  localparam logic [31:0] IP_C     = 32'hC0A8_0130;
  localparam logic [31:0] IP_D     = 32'hC0A8_0140;
  localparam logic [31:0] IP_E     = 32'hC0A8_0150;
  localparam logic [31:0] IP_OTHER = 32'hC0A8_01AA;         // somebody else, not us
  localparam logic [31:0] IP_FAR   = 32'h0A00_0005;         // 10.0.0.5, off-subnet

  // ---- verdict bookkeeping -------------------------------------------------
  int err_cnt = 0;
  int msg_cnt = 0;

  task automatic fail(input string cl, input string msg);
    err_cnt = err_cnt + 1;
    if (msg_cnt < 40) begin
      msg_cnt = msg_cnt + 1;
      $display("VIOLATION [%s] cycle=%0d : %s", cl, bfm_cycle, msg);
    end
    if (err_cnt == 60) begin
      $display("SUMMARY: stopping after %0d violations", err_cnt);
      $display("RESULT: FAIL");
      $finish;
    end
  endtask

  // ---- observation ---------------------------------------------------------
  // Counters advance with nonblocking assignment and timestamp with the same
  // pre-edge bfm_cycle the plumbing stamps frames with, so a response time and
  // a frame time are on the same scale.
  int          tx_hdr_cnt = 0;      // frame headers the design has sent
  int          resp_cnt   = 0;      // responses the design has delivered
  int          last_resp_at = 0;
  bit          last_resp_err = 1'b0;
  logic [47:0] last_resp_mac = '0;
  int          rst_edges = 0;

  always @(posedge clk) begin
    if (rst) begin
      rst_edges <= rst_edges + 1;
      // X1: while reset is high no output valid is asserted.  Judged from the
      // second rising edge on, because before an edge has passed the design's
      // registers hold nothing defined.
      if (rst_edges >= 1) begin
        if (m_hv === 1'b1 || m_pv === 1'b1 || rs_v === 1'b1)
          fail("X1", $sformatf("with rst_i high the design drives m_hdr_valid_o=%0b m_payload_valid_o=%0b resp_valid_o=%0b",
                               m_hv, m_pv, rs_v));
      end
    end else begin
      rst_edges <= 0;
      if (m_hv && m_hr) tx_hdr_cnt <= tx_hdr_cnt + 1;
      if (rs_v && rs_r) begin
        resp_cnt      <= resp_cnt + 1;
        last_resp_at  <= bfm_cycle;
        last_resp_err <= rs_e;
        last_resp_mac <= rs_mac;
      end
    end
  end

  // ---- frame field checks ---------------------------------------------------
  task automatic chk_common(input bfm_frame_t f, input string ctx);
    if (f.eth_type !== 16'h0806)
      fail("F", $sformatf("%s: transmitted eth_type=%04h, an ARP frame carries 0806", ctx, f.eth_type));
    if (f.nbytes != 28)
      fail("F", $sformatf("%s: transmitted payload is %0d bytes, an ARP frame is 28", ctx, f.nbytes));
    if (f.htype !== 16'h0001)
      fail("F", $sformatf("%s: hardware type=%04h, expected 0001", ctx, f.htype));
    if (f.ptype !== 16'h0800)
      fail("F", $sformatf("%s: protocol type=%04h, expected 0800", ctx, f.ptype));
    if (f.hlen !== 8'd6)
      fail("F", $sformatf("%s: hardware length=%0d, expected 6", ctx, f.hlen));
    if (f.plen !== 8'd4)
      fail("F", $sformatf("%s: protocol length=%0d, expected 4", ctx, f.plen));
  endtask

  task automatic chk_request(input bfm_frame_t f, input logic [31:0] tpa_exp, input string ctx);
    chk_common(f, ctx);
    if (f.oper !== 16'd1)
      fail("Q2", $sformatf("%s: transmitted operation=%0d, a request carries 1", ctx, f.oper));
    if (f.dest_mac !== BCAST)
      fail("Q2", $sformatf("%s: request sent to %012h, it must be broadcast to ffffffffffff", ctx, f.dest_mac));
    if (f.sha !== cfg_local_mac)
      fail("Q2", $sformatf("%s: request SHA=%012h, expected local_mac_i %012h", ctx, f.sha, cfg_local_mac));
    if (f.spa !== cfg_local_ip)
      fail("Q2", $sformatf("%s: request SPA=%08h, expected local_ip_i %08h", ctx, f.spa, cfg_local_ip));
    if (f.tha !== 48'd0)
      fail("Q2", $sformatf("%s: request THA=%012h, expected zero", ctx, f.tha));
    if (f.tpa !== tpa_exp)
      fail("Q3", $sformatf("%s: request asks for TPA=%08h, expected %08h", ctx, f.tpa, tpa_exp));
  endtask

  // ---- helpers ---------------------------------------------------------------
  task automatic do_clear();
    @(negedge clk); clr_cache = 1'b1;
    repeat (2) @(posedge clk);
    @(negedge clk); clr_cache = 1'b0;
    repeat (2) @(posedge clk);
  endtask

  // Nothing may be transmitted for n cycles.
  task automatic quiet_tx(input int n, input string cl, input string msg);
    automatic int t0;
    @(negedge clk); t0 = tx_hdr_cnt;
    repeat (n) @(posedge clk);
    @(negedge clk);
    if (tx_hdr_cnt != t0)
      fail(cl, $sformatf("%s (%0d frame header(s) transmitted)", msg, tx_hdr_cnt - t0));
  endtask

  // A lookup that must be answered from the cache (Q1) with no frame sent.
  task automatic expect_hit(input logic [31:0] ip, input logic [47:0] mac,
                            input string cl, input string ctx);
    automatic bit ok, got, err;
    automatic logic [47:0] m;
    automatic int took, t0, r0, t;
    // let any frame already in flight finish, so it cannot be mistaken for a
    // request transmitted on account of this lookup
    for (t = 0; t < 120; t++) begin
      @(negedge clk);
      if (m_pv !== 1'b1 && m_hv !== 1'b1) break;
    end
    @(negedge clk); t0 = tx_hdr_cnt; r0 = resp_cnt;
    bfm_lookup(ip, ok, 32);
    if (!ok) begin
      fail("X3", $sformatf("%s: lookup of %08h was not accepted within 32 cycles", ctx, ip));
      return;
    end
    bfm_await(32, got, err, m, took);
    if (!got) begin
      fail(cl, $sformatf("%s: lookup of %08h should be in the cache but was not answered within 32 cycles of acceptance; either it was never learned (C1) or it was not answered from the cache (Q1)", ctx, ip));
      // let whatever it is doing finish, so the next phase starts clean
      for (int t = 0; t < 900; t++) begin
        @(negedge clk);
        if (resp_cnt > r0) break;
      end
      return;
    end
    if (err)
      fail(cl, $sformatf("%s: lookup of %08h answered with resp_error_o high; that address is in the cache", ctx, ip));
    else if (m !== mac)
      fail(cl, $sformatf("%s: lookup of %08h answered with resp_mac_o=%012h, the cached MAC is %012h", ctx, ip, m, mac));
    // Q1: and no frame is transmitted
    bfm_wait(60);
    @(negedge clk);
    if (tx_hdr_cnt != t0)
      fail("Q1", $sformatf("%s: a frame was transmitted for a lookup of %08h that the cache can answer", ctx, ip));
  endtask

  // A lookup that must MISS: a request must go out, and a reply then resolves
  // it.  The reply is sent as soon as the request's header has moved, so it
  // lands well before the first retry falls due and cannot race it.
  task automatic miss_and_resolve(input logic [31:0] ip, input logic [31:0] tpa_exp,
                                  input logic [47:0] sha, input logic [31:0] spa,
                                  input string cl, input string ctx);
    automatic bit ok, got, err, saw;
    automatic logic [47:0] m;
    automatic int took, i0, r0, t0, t;
    @(negedge clk);
    i0 = bfm_rx.size(); r0 = resp_cnt; t0 = tx_hdr_cnt;
    bfm_lookup(ip, ok, 32);
    if (!ok) begin
      fail("X3", $sformatf("%s: lookup of %08h was not accepted within 32 cycles", ctx, ip));
      return;
    end
    saw = 1'b0;
    for (t = 0; t < 200; t++) begin
      @(negedge clk);
      if (tx_hdr_cnt > t0) begin saw = 1'b1; break; end
      if (resp_cnt > r0) break;
    end
    if (!saw) begin
      if (resp_cnt > r0 && !last_resp_err)
        fail(cl, $sformatf("%s: lookup of %08h was answered from the cache, but that address must be unknown", ctx, ip));
      else if (resp_cnt > r0)
        fail(cl, $sformatf("%s: lookup of %08h was answered with an error without transmitting any request", ctx, ip));
      else
        fail("Q2", $sformatf("%s: lookup of %08h transmitted no ARP request", ctx, ip));
      return;
    end
    // resolve it
    bfm_send(16'd2, sha, spa, cfg_local_mac, cfg_local_ip, ok);
    if (!ok) begin
      fail("X3", $sformatf("%s: the reply frame was not accepted within 32 cycles", ctx));
      return;
    end
    bfm_await(200, got, err, m, took);
    if (!got)
      fail("Q6", $sformatf("%s: a reply with SPA=%08h did not resolve the outstanding lookup", ctx, spa));
    else if (err)
      fail("Q6", $sformatf("%s: the lookup resolved by a reply was answered with resp_error_o high", ctx));
    else if (m !== sha)
      fail("Q6", $sformatf("%s: resolved with resp_mac_o=%012h, the reply's SHA was %012h", ctx, m, sha));
    // the request it transmitted must be well formed and correctly aimed
    if (bfm_rx.size() > i0) chk_request(bfm_rx[i0], tpa_exp, ctx);
    else fail("F", $sformatf("%s: the transmitted frame never completed its payload", ctx));
    // Q6: no further request once it is resolved
    quiet_tx(220, "Q6", $sformatf("%s: a further request was transmitted after the lookup was resolved", ctx));
  endtask

  // ---- the retry-and-timeout sequence, Q4 and Q5 -----------------------------
  task automatic run_timeout(input logic [31:0] ip, input logic [31:0] tpa_exp, input string ctx);
    automatic bit ok, resp_seen, resp_err;
    automatic int i0, r0, t, nreq, k, d, resp_at, obs;
    do_clear();
    @(negedge clk);
    i0 = bfm_rx.size(); r0 = resp_cnt;
    resp_seen = 1'b0; resp_err = 1'b0; resp_at = 0; obs = 0;
    bfm_lookup(ip, ok, 32);
    if (!ok) begin
      fail("X3", $sformatf("%s: lookup of %08h was not accepted within 32 cycles", ctx, ip));
      return;
    end
    // Watch long enough for four requests, the timeout, and a further stretch
    // in which nothing more may be transmitted.
    for (t = 0; t < 1600; t++) begin
      @(negedge clk);
      if (!resp_seen && resp_cnt > r0) begin
        resp_seen = 1'b1;
        resp_err  = last_resp_err;
        resp_at   = last_resp_at;
      end
      if (resp_seen) begin
        obs = obs + 1;
        if (obs > 260) break;
      end
    end
    nreq = bfm_rx.size() - i0;
    // Q4: exactly four requests
    if (nreq != 4)
      fail("Q4", $sformatf("%s: %0d request frames were transmitted for an unanswered lookup, exactly 4 are required", ctx, nreq));
    for (k = 0; k < nreq; k++)
      chk_request(bfm_rx[i0+k], tpa_exp, $sformatf("%s request %0d", ctx, k+1));
    // Q4: spacing between consecutive requests, measured header to header.
    // The window is widened by the "cycle or two" the contract itself concedes
    // for the handshake, because a design may start its interval when it
    // decides to send rather than when the header moves.  A wrong interval is
    // wrong by far more than two cycles.
    for (k = 1; k < nreq; k++) begin
      d = bfm_rx[i0+k].at - bfm_rx[i0+k-1].at;
      if (d < 62 || d > 82)
        fail("Q4", $sformatf("%s: requests %0d and %0d are %0d cycles apart, the interval must be 64 to 80", ctx, k, k+1, d));
    end
    // Q5: the error response
    if (!resp_seen) begin
      fail("Q5", $sformatf("%s: an unanswered lookup was never answered at all", ctx));
    end else begin
      if (!resp_err)
        fail("Q5", $sformatf("%s: an unanswered lookup was answered with resp_error_o low", ctx));
      // Measured from the cycle the fourth request's header moved, with the
      // same two cycles of handshake tolerance: a conforming design may anchor
      // its timeout on deciding to send, on the header, or on the last payload
      // byte, and all three land inside this.
      if (nreq >= 4) begin
        d = resp_at - bfm_rx[i0+3].at;
        if (d < 254)
          fail("Q5", $sformatf("%s: answered %0d cycles after the fourth request, which is before the 256 cycle timeout", ctx, d));
        else if (d > 302)
          fail("Q5", $sformatf("%s: answered %0d cycles after the fourth request, the timeout window ends at 300", ctx, d));
      end
    end
  endtask

  // ===========================================================================
  // THE RUN
  // ===========================================================================
  initial begin
    automatic bit ok, got, err, saw;
    automatic logic [47:0] m;
    automatic int took, i0, r0, t0, t;

    bfm_reset(8);

    // ---- A1: a request aimed at us is answered -----------------------------
    @(negedge clk); i0 = bfm_rx.size();
    bfm_send(16'd1, MAC_A, IP_A, 48'd0, cfg_local_ip, ok);
    if (!ok) fail("X3", "A1: the received frame was not accepted within 32 cycles");
    for (t = 0; t < 200; t++) begin
      @(negedge clk);
      if (bfm_rx.size() > i0) break;
    end
    if (bfm_rx.size() <= i0) begin
      fail("A1", "a request whose TPA is local_ip_i was not answered");
    end else begin
      automatic bfm_frame_t f = bfm_rx[i0];
      chk_common(f, "A1 reply");
      if (f.oper !== 16'd2)
        fail("A1", $sformatf("the answer carries operation=%0d, a reply carries 2", f.oper));
      if (f.dest_mac !== MAC_A)
        fail("A1", $sformatf("the reply was sent to %012h, expected the requester's SHA %012h", f.dest_mac, MAC_A));
      if (f.sha !== cfg_local_mac)
        fail("A1", $sformatf("reply SHA=%012h, expected local_mac_i %012h", f.sha, cfg_local_mac));
      if (f.spa !== cfg_local_ip)
        fail("A1", $sformatf("reply SPA=%08h, expected local_ip_i %08h", f.spa, cfg_local_ip));
      if (f.tha !== MAC_A)
        fail("A1", $sformatf("reply THA=%012h, expected the requester's SHA %012h", f.tha, MAC_A));
      if (f.tpa !== IP_A)
        fail("A1", $sformatf("reply TPA=%08h, expected the requester's SPA %08h", f.tpa, IP_A));
    end
    // C1 + Q1: that frame was learned from
    expect_hit(IP_A, MAC_A, "C1", "C1 after a received request");

    // ---- A2: a request aimed at somebody else is not answered --------------
    do_clear();
    bfm_send(16'd1, MAC_B, IP_B, 48'd0, IP_OTHER, ok);
    if (!ok) fail("X3", "A2: the received frame was not accepted within 32 cycles");
    quiet_tx(160, "A2", "a request whose TPA is not local_ip_i was answered");
    // C1: but it is still learned from
    expect_hit(IP_B, MAC_B, "C1", "C1 after a request aimed elsewhere");

    // ---- A3: a non-ARP frame is ignored entirely ---------------------------
    do_clear();
    bfm_send(16'd1, MAC_C, IP_C, 48'd0, cfg_local_ip, ok, 16'h0800);
    if (!ok) fail("X3", "A3: the received frame was not accepted within 32 cycles");
    quiet_tx(160, "A3", "a frame whose eth_type is not 0806 was answered");
    // ...and not learned from: the address must still be unknown
    miss_and_resolve(IP_C, IP_C, MAC_C, IP_C, "A3",
                     "A3 learn check (a non-ARP frame must not be learned from)");

    // ---- Q2/Q3/Q6: an in-subnet miss ---------------------------------------
    do_clear();
    miss_and_resolve(IP_D, IP_D, MAC_D, IP_D, "C3", "Q2 in-subnet lookup");
    expect_hit(IP_D, MAC_D, "C1", "C1 after a reply resolved the lookup");

    // ---- Q3: an address outside the local subnet asks for the gateway ------
    do_clear();
    miss_and_resolve(IP_FAR, cfg_gateway_ip, MAC_G, cfg_gateway_ip, "C3",
                     "Q3 off-subnet lookup");

    // ---- Q4/Q5: nobody answers ---------------------------------------------
    run_timeout(IP_E, IP_E, "Q4/Q5 in-subnet");

    // ---- C3: clear_cache_i empties the cache -------------------------------
    do_clear();
    bfm_send(16'd2, MAC_E, IP_E, cfg_local_mac, cfg_local_ip, ok);
    if (!ok) fail("X3", "C3: the received reply was not accepted within 32 cycles");
    expect_hit(IP_E, MAC_E, "C1", "C1 after a received reply");
    do_clear();
    miss_and_resolve(IP_E, IP_E, MAC_E, IP_E, "C3",
                     "C3 (every address must be unknown after clear_cache_i)");

    // ---- C2: an insert never fails, even with the cache full ---------------
    // L1 forbids requiring any particular older entry to survive, so only the
    // address just inserted is checked.
    do_clear();
    bfm_send(16'd1, 48'h02_00_00_00_F0_01, 32'hC0A8_0181, 48'd0, IP_OTHER, ok);
    bfm_send(16'd1, 48'h02_00_00_00_F0_02, 32'hC0A8_0182, 48'd0, IP_OTHER, ok);
    bfm_send(16'd1, 48'h02_00_00_00_F0_03, 32'hC0A8_0183, 48'd0, IP_OTHER, ok);
    bfm_send(16'd1, 48'h02_00_00_00_F0_04, 32'hC0A8_0184, 48'd0, IP_OTHER, ok);
    bfm_send(16'd1, 48'h02_00_00_00_F0_05, 32'hC0A8_0185, 48'd0, IP_OTHER, ok);
    if (!ok) fail("X3", "C2: a received frame was not accepted within 32 cycles");
    expect_hit(32'hC0A8_0185, 48'h02_00_00_00_F0_05, "C2", "C2 insert into a full cache");

    // ---- X2: reset empties the cache and drops the outstanding lookup ------
    do_clear();
    bfm_send(16'd2, MAC_B, IP_B, cfg_local_mac, cfg_local_ip, ok);
    if (!ok) fail("X3", "X2 setup: the received reply was not accepted within 32 cycles");
    @(negedge clk); r0 = resp_cnt;
    bfm_lookup(IP_D, ok, 32);            // a miss, so a request goes out
    if (!ok) fail("X3", "X2 setup: the lookup was not accepted within 32 cycles");
    // Reset while that request is still being transmitted: X1 requires every
    // output valid to be low while rst_i is high, mid-frame included.
    for (t = 0; t < 60; t++) begin
      @(negedge clk);
      if (m_pv === 1'b1) break;
    end
    bfm_wait(3);
    bfm_reset(8);
    @(negedge clk);
    bfm_buf.delete();                    // drop the abandoned partial frame
    // no lookup is outstanding: nothing may be answered or transmitted
    @(negedge clk); r0 = resp_cnt; t0 = tx_hdr_cnt;
    bfm_wait(320);
    @(negedge clk);
    if (resp_cnt != r0)
      fail("X2", "a lookup outstanding across reset was answered after the reset");
    if (tx_hdr_cnt != t0)
      fail("X2", "a request for a lookup outstanding across reset was transmitted after the reset");
    // the cache is empty: an address learned before the reset is unknown
    miss_and_resolve(IP_B, IP_B, MAC_B, IP_B, "X2",
                     "X2 (the cache must be empty after reset)");

    // ---- verdict -----------------------------------------------------------
    $display("SUMMARY: %0d frames captured, %0d responses, %0d violations",
             bfm_rx.size(), resp_cnt, err_cnt);
    if (resp_cnt == 0)
      fail("X3", "the design never answered a single lookup");
    if (err_cnt == 0) $display("RESULT: PASS");
    else              $display("RESULT: FAIL");
    $finish;
  end

endmodule