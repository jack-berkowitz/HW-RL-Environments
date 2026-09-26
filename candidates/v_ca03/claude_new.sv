// =============================================================================
// id_width_conv_tb -- self-checking testbench for the ID width converter.
//
// Structure
//   * ONE posedge monitor owns all bookkeeping and every check. It processes
//     each edge in a fixed order: master responses -> slave responses
//     (retirements) -> slave address handshakes (A3/A5) -> master address
//     handshakes (D1/D4/E1) -> write data (B3/E1). Retiring before accepting
//     within one edge is what A4's measured zero-cycle reuse requires.
//   * Drivers and the downstream responders run in separate processes and act
//     only on flags the monitor sets; they never read DUT outputs themselves.
//   * Every transaction is identified by a unique address chosen when it is
//     offered (bookkeeping, not value matching).
//   * Downstream responses are returned oldest-first per slave id and in
//     master-AR order per master id, with a random choice ACROSS ids (B2 is
//     free). Any correct design can meet that order whatever mapping it uses.
// =============================================================================
module id_width_conv_tb;

  localparam int unsigned SLV_ID_W        = 4;
  localparam int unsigned MST_ID_W        = 2;
  localparam int unsigned ADDR_W          = 32;
  localparam int unsigned DATA_W          = 32;
  localparam int unsigned MAX_UNIQ_IDS    = 4;
  localparam int unsigned MAX_TXNS_PER_ID = 2;

  localparam int NSID = 1 << SLV_ID_W;
  localparam int NMID = 1 << MST_ID_W;

  // ---------------------------------------------------------------------------
  // DUT signals
  // ---------------------------------------------------------------------------
  logic [SLV_ID_W-1:0]   s_awid = '0;
  logic [ADDR_W-1:0]     s_awaddr = '0;
  logic [7:0]            s_awlen = '0;
  logic                  s_awvalid = 1'b0;
  logic                  s_awready;
  logic [DATA_W-1:0]     s_wdata = '0;
  logic [DATA_W/8-1:0]   s_wstrb = '0;
  logic                  s_wlast = 1'b0;
  logic                  s_wvalid = 1'b0;
  logic                  s_wready;
  logic [SLV_ID_W-1:0]   s_bid;
  logic [1:0]            s_bresp;
  logic                  s_bvalid;
  logic                  s_bready = 1'b0;
  logic [SLV_ID_W-1:0]   s_arid = '0;
  logic [ADDR_W-1:0]     s_araddr = '0;
  logic [7:0]            s_arlen = '0;
  logic                  s_arvalid = 1'b0;
  logic                  s_arready;
  logic [SLV_ID_W-1:0]   s_rid;
  logic [DATA_W-1:0]     s_rdata;
  logic [1:0]            s_rresp;
  logic                  s_rlast;
  logic                  s_rvalid;
  logic                  s_rready = 1'b0;

  logic [MST_ID_W-1:0]   m_awid;
  logic [ADDR_W-1:0]     m_awaddr;
  logic [7:0]            m_awlen;
  logic                  m_awvalid;
  logic                  m_awready = 1'b0;
  logic [DATA_W-1:0]     m_wdata;
  logic [DATA_W/8-1:0]   m_wstrb;
  logic                  m_wlast;
  logic                  m_wvalid;
  logic                  m_wready = 1'b0;
  logic [MST_ID_W-1:0]   m_bid = '0;
  logic [1:0]            m_bresp = '0;
  logic                  m_bvalid = 1'b0;
  logic                  m_bready;
  logic [MST_ID_W-1:0]   m_arid;
  logic [ADDR_W-1:0]     m_araddr;
  logic [7:0]            m_arlen;
  logic                  m_arvalid;
  logic                  m_arready = 1'b0;
  logic [MST_ID_W-1:0]   m_rid = '0;
  logic [DATA_W-1:0]     m_rdata = '0;
  logic [1:0]            m_rresp = '0;
  logic                  m_rlast = 1'b0;
  logic                  m_rvalid = 1'b0;
  logic                  m_rready;

// ---------------------------------------------------------------------------
// PROVIDED PLUMBING -- moves transactions, checks nothing.
// ---------------------------------------------------------------------------
// This exists so you spend your effort on checking rather than on handshake
// mechanics. It has been compiled and run against a correct implementation.
//
// What it does: generates the clock, sequences reset, offers one address
// request at a time and REPORTS whether it was accepted and after how many
// cycles, and lets you present responses on the downstream port.
//
// What it does NOT do: it never decides whether a request SHOULD have been
// accepted, never tracks what is outstanding, and never chooses a response
// order. Those are the task.
// ---------------------------------------------------------------------------

  logic clk;
  initial begin clk = 1'b0; forever #5 clk = ~clk; end

  logic rst_n;
  initial rst_n = 1'b0;

  // Asserted and released away from the sampling edge.
  task automatic bfm_reset(input int cycles = 4);
    @(negedge clk);
    rst_n = 1'b0;
    repeat (cycles) @(posedge clk);
    @(negedge clk);
    rst_n = 1'b1;
  endtask

  // Offer a read address and hold it stable until accepted or the budget runs
  // out. Reports BOTH facts: whether it went, and how many cycles it waited.
  // Interpreting a refusal is yours.
  task automatic bfm_ar(input  logic [SLV_ID_W-1:0] id,
                        input  logic [ADDR_W-1:0]   addr,
                        input  logic [7:0]          len,
                        input  int                  budget,
                        output bit                  accepted,
                        output int                  waited);
    accepted = 1'b0; waited = 0;
    @(negedge clk);
    s_arid = id; s_araddr = addr; s_arlen = len; s_arvalid = 1'b1;
    while (waited < budget) begin
      @(posedge clk);
      if (s_arready) begin accepted = 1'b1; break; end
      waited++;
    end
    @(negedge clk) s_arvalid = 1'b0;
  endtask

  // The same for a write address.
  task automatic bfm_aw(input  logic [SLV_ID_W-1:0] id,
                        input  logic [ADDR_W-1:0]   addr,
                        input  logic [7:0]          len,
                        input  int                  budget,
                        output bit                  accepted,
                        output int                  waited);
    accepted = 1'b0; waited = 0;
    @(negedge clk);
    s_awid = id; s_awaddr = addr; s_awlen = len; s_awvalid = 1'b1;
    while (waited < budget) begin
      @(posedge clk);
      if (s_awready) begin accepted = 1'b1; break; end
      waited++;
    end
    @(negedge clk) s_awvalid = 1'b0;
  endtask

  // One write data beat.
  task automatic bfm_w(input logic [DATA_W-1:0]   data,
                       input logic [DATA_W/8-1:0] strb,
                       input logic                last);
    @(negedge clk);
    s_wdata = data; s_wstrb = strb; s_wlast = last; s_wvalid = 1'b1;
    forever begin @(posedge clk); if (s_wready) break; end
    @(negedge clk) s_wvalid = 1'b0;
  endtask

  // Present one downstream read response beat with the given master identifier.
  // WHICH identifier, and in what order, is yours to decide.
  task automatic bfm_rbeat(input logic [MST_ID_W-1:0] mid,
                           input logic [DATA_W-1:0]   data,
                           input logic                last);
    @(negedge clk);
    m_rid = mid; m_rdata = data; m_rlast = last; m_rresp = 2'b00; m_rvalid = 1'b1;
    forever begin @(posedge clk); if (m_rready) break; end
    @(negedge clk) m_rvalid = 1'b0;
  endtask

  // Present one downstream write response.
  task automatic bfm_bbeat(input logic [MST_ID_W-1:0] mid);
    @(negedge clk);
    m_bid = mid; m_bresp = 2'b00; m_bvalid = 1'b1;
    forever begin @(posedge clk); if (m_bready) break; end
    @(negedge clk) m_bvalid = 1'b0;
  endtask

  // Watchdog. Fires regardless of what the design does -- one of the faulty
  // implementations refuses a request it should accept.
  initial begin
    #4_000_000;
    $display("RESULT: FAIL (watchdog: no forward progress)");
    $finish;
  end

  // ---------------------------------------------------------------------------
  // DUT
  // ---------------------------------------------------------------------------
  id_width_conv #(
      .SLV_ID_W(SLV_ID_W), .MST_ID_W(MST_ID_W), .ADDR_W(ADDR_W), .DATA_W(DATA_W),
      .MAX_UNIQ_IDS(MAX_UNIQ_IDS), .MAX_TXNS_PER_ID(MAX_TXNS_PER_ID)
  ) dut (
      .clk_i(clk), .rst_ni(rst_n),
      .s_awid, .s_awaddr, .s_awlen, .s_awvalid, .s_awready,
      .s_wdata, .s_wstrb, .s_wlast, .s_wvalid, .s_wready,
      .s_bid, .s_bresp, .s_bvalid, .s_bready,
      .s_arid, .s_araddr, .s_arlen, .s_arvalid, .s_arready,
      .s_rid, .s_rdata, .s_rresp, .s_rlast, .s_rvalid, .s_rready,
      .m_awid, .m_awaddr, .m_awlen, .m_awvalid, .m_awready,
      .m_wdata, .m_wstrb, .m_wlast, .m_wvalid, .m_wready,
      .m_bid, .m_bresp, .m_bvalid, .m_bready,
      .m_arid, .m_araddr, .m_arlen, .m_arvalid, .m_arready,
      .m_rid, .m_rdata, .m_rresp, .m_rlast, .m_rvalid, .m_rready
  );

  // ---------------------------------------------------------------------------
  // Failure reporting
  // ---------------------------------------------------------------------------
  // Simulator hazard (measured on Verilator 5.x): a process that WRITES a variable and later
  // POLLS it can keep reading a stale copy while another process updates it.
  // Rule used throughout: every variable a process polls has exactly one
  // writer, and that writer is some other process. Hence one error counter per
  // reporting process, handshake COUNTERS owned by the monitor, append-only
  // work lists with consumer-private read indices, per-process address counters.
  int errs_m = 0, errs_s = 0;           // monitor-owned / sequencer-owned
  int eby_m [string];
  int eby_s [string];

  task automatic fail_m(input string req, input string msg);   // monitor only
    errs_m++;
    if (!eby_m.exists(req)) eby_m[req] = 0;
    eby_m[req]++;
    if (eby_m[req] <= 8) $display("FAIL %s: t=%0t %s", req, $time, msg);
  endtask

  task automatic fail_s(input string req, input string msg);   // sequencer only
    errs_s++;
    if (!eby_s.exists(req)) eby_s[req] = 0;
    eby_s[req]++;
    if (eby_s[req] <= 8) $display("FAIL %s: t=%0t %s", req, $time, msg);
  endtask

  // ---------------------------------------------------------------------------
  // Model state (owned by the monitor)
  // ---------------------------------------------------------------------------
  typedef struct packed {
    int          tag;
    logic [31:0] data;
    logic [1:0]  resp;
    logic        last;
  } rexp_t;

  typedef struct packed {
    int          tag;
    logic [31:0] data;
    logic [3:0]  strb;
    logic        last;
  } wbeat_t;

  typedef struct packed {
    int         mid;
    logic [7:0] len;
  } mreq_t;

  int      cyc = 0;
  int      epoch = 0;
  bit      in_rst = 1'b1;          // rst_n as sampled at the last posedge
  int      ntag = 0;

  // read side
  int      rd_out   [NSID][$];     // outstanding tags per slave id, accept order (A1)
  int      r_sid    [int];
  int      r_len    [int];
  int      r_mid    [int];         // -1 until the master AR is seen
  bit      r_taken  [int];         // responder has started this one
  int      r_addr2tag [int];       // live accepted, keyed by address
  bit      r_stale_addr [int];     // accepted before/while reset
  mreq_t   r_pend   [int];         // master AR seen before its slave handshake
  int      r_midq   [NMID][$];     // master-AR order per master id (responder)
  rexp_t   exp_r    [NSID][$];     // delivered downstream beats awaiting the slave port
  mreq_t   r_stale_work [$];       // post-release master ARs of stale txns
  bit      stale_rsid [NSID];

  // write side
  int      wr_out   [NSID][$];
  int      w_sid    [int];
  int      w_len    [int];
  int      w_mid    [int];
  bit      w_taken  [int];
  bit      w_mwdone [int];         // all beats forwarded on the master W channel
  int      w_addr2tag [int];
  bit      w_stale_addr [int];
  mreq_t   w_pend   [int];
  int      w_midq   [NMID][$];
  int      exp_b    [NSID][$];     // tags whose downstream B was delivered
  mreq_t   w_stale_work [$];
  bit      stale_wsid [NSID];
  int      w_todo   [$];           // accepted AWs awaiting W data, accept order
  wbeat_t  sw_stream [$];          // slave W beats not yet seen on the master (B3)

  // handshake flags for the drivers
  int      ar_hs_n = 0, aw_hs_n = 0, w_hs_n = 0, mr_hs_n = 0, mb_hs_n = 0;   // monitor-owned
  int      ar_acc_cyc = -1, aw_acc_cyc = -1, rd_free_cyc = -1, wr_free_cyc = -1;
  int      r_cur_tag = -1, b_cur_tag = -1, w_cur_tag = -1;
  int      n_rd_acc = 0, n_rd_done = 0, n_wr_acc = 0, n_wr_done = 0;

  // stimulus controls
  int      s_rready_mode = 2, s_bready_mode = 2, m_ready_mode = 2;   // 0 low, 1 high, 2 random
  bit      r_en = 1'b0, b_en = 1'b0;
  bit      r_allow [NSID];
  bit      b_allow [NSID];
  int      resp_idle = 30, beat_gap = 20, w_gap = 20;

  initial begin
    for (int s = 0; s < NSID; s++) begin r_allow[s] = 1'b1; b_allow[s] = 1'b1; end
  end

  // ---------------------------------------------------------------------------
  // Model helpers
  // ---------------------------------------------------------------------------
  function automatic int n_distinct(input bit is_wr);
    int n;
    n = 0;
    for (int s = 0; s < NSID; s++) n += is_wr ? int'(wr_out[s].size() > 0) : int'(rd_out[s].size() > 0);
    return n;
  endfunction

  function automatic int first_untaken_rd(input int s);
    for (int k = 0; k < rd_out[s].size(); k++)
      if (!r_taken.exists(rd_out[s][k])) return rd_out[s][k];
    return -1;
  endfunction

  function automatic int first_untaken_wr(input int s);
    for (int k = 0; k < wr_out[s].size(); k++)
      if (!w_taken.exists(wr_out[s][k])) return wr_out[s][k];
    return -1;
  endfunction

  // D1/D2: a master id may not be shared by two co-outstanding different slave ids
  task automatic link_rd(input int t, input int mid, input logic [7:0] len);
    if (len !== r_len[t][7:0]) fail_m("E1", $sformatf("m_arlen %0d, slave arlen %0d", len, r_len[t]));
    r_mid[t] = mid;
    for (int s = 0; s < NSID; s++) begin
      if (s == r_sid[t]) continue;
      for (int k = 0; k < rd_out[s].size(); k++)
        if (r_mid[rd_out[s][k]] == mid)
          fail_m("D1", $sformatf("read master id %0d given to slave id %0d while slave id %0d still outstanding on it (D2 reuse before retirement)",
                               mid, r_sid[t], s));
    end
    r_midq[mid].push_back(t);
  endtask

  task automatic link_wr(input int t, input int mid, input logic [7:0] len);
    if (len !== w_len[t][7:0]) fail_m("E1", $sformatf("m_awlen %0d, slave awlen %0d", len, w_len[t]));
    w_mid[t] = mid;
    for (int s = 0; s < NSID; s++) begin
      if (s == w_sid[t]) continue;
      for (int k = 0; k < wr_out[s].size(); k++)
        if (w_mid[wr_out[s][k]] == mid)
          fail_m("D1", $sformatf("write master id %0d given to slave id %0d while slave id %0d still outstanding on it (D2 reuse before retirement)",
                               mid, w_sid[t], s));
    end
    w_midq[mid].push_back(t);
  endtask

  task automatic clear_for_reset();
    for (int s = 0; s < NSID; s++) begin
      if (rd_out[s].size() > 0) stale_rsid[s] = 1'b1;
      if (wr_out[s].size() > 0) stale_wsid[s] = 1'b1;
      rd_out[s].delete(); wr_out[s].delete(); exp_r[s].delete(); exp_b[s].delete();
    end
    for (int m = 0; m < NMID; m++) begin r_midq[m].delete(); w_midq[m].delete(); end
    foreach (r_addr2tag[a]) r_stale_addr[a] = 1'b1;
    foreach (w_addr2tag[a]) w_stale_addr[a] = 1'b1;
    foreach (r_pend[a]) r_stale_addr[a] = 1'b1;
    foreach (w_pend[a]) w_stale_addr[a] = 1'b1;
    r_addr2tag.delete(); w_addr2tag.delete(); r_pend.delete(); w_pend.delete();
    r_stale_work.delete(); w_stale_work.delete(); w_todo.delete(); sw_stream.delete();
  endtask

  // ---------------------------------------------------------------------------
  // THE MONITOR
  // ---------------------------------------------------------------------------
  always @(posedge clk) begin : monitor
    automatic int     t, s, m;
    automatic rexp_t  e;
    automatic wbeat_t wb;
    automatic int     a;
    automatic mreq_t  mq;
    cyc++;
    if (!rst_n) begin
      // ---------------------------------------------------------- F1: in reset
      if (!in_rst) begin
        epoch++;
        clear_for_reset();
      end else if (cyc > 1) begin
        // from the second reset edge on the design has been reset: no response
        if (s_rvalid) fail_m("F1", "s_rvalid high while rst_ni low");
        if (s_bvalid) fail_m("F1", "s_bvalid high while rst_ni low");
      end
      in_rst = 1'b1;
      // a handshake during reset is legal (latitude 7) and is discarded
      if (s_arvalid && s_arready) begin
        ar_hs_n++; r_stale_addr[int'(s_araddr)] = 1'b1; stale_rsid[s_arid] = 1'b1;
      end
      if (s_awvalid && s_awready) begin
        aw_hs_n++; w_stale_addr[int'(s_awaddr)] = 1'b1; stale_wsid[s_awid] = 1'b1;
      end
      if (s_wvalid && s_wready) w_hs_n++;
    end else begin
      in_rst = 1'b0;

      // ---------------------------------------------------------- 1. master responses
      if (m_rvalid && m_rready) begin
        mr_hs_n++;
        t = r_cur_tag;
        if (t >= 0 && r_sid.exists(t)) begin
          e.tag = t; e.data = m_rdata; e.resp = m_rresp; e.last = m_rlast;
          exp_r[r_sid[t]].push_back(e);
        end
      end
      if (m_bvalid && m_bready) begin
        mb_hs_n++;
        t = b_cur_tag;
        if (t >= 0 && w_sid.exists(t)) exp_b[w_sid[t]].push_back(t);
      end

      // ---------------------------------------------------------- 2. slave responses
      if (s_rvalid && s_rready) begin
        s = int'(s_rid);
        if (rd_out[s].size() == 0) begin
          if (stale_rsid[s]) fail_m("F1", $sformatf("read response for slave id %0d after reset; nothing of it outstanding", s));
          else               fail_m("C2", $sformatf("read response for slave id %0d with no read outstanding", s));
        end else if (exp_r[s].size() == 0) begin
          fail_m("C2", $sformatf("read response for slave id %0d before any downstream beat was returned for it", s));
        end else begin
          e = exp_r[s].pop_front();
          if (s_rdata !== e.data || s_rresp !== e.resp || s_rlast !== e.last)
            fail_m("E1", $sformatf("read beat id %0d: got data %h resp %0d last %0d, expected %h %0d %0d (B1/E1)",
                                 s, s_rdata, s_rresp, s_rlast, e.data, e.resp, e.last));
          if (s_rlast) begin                               // A1: retires here
            void'(rd_out[s].pop_front());
            n_rd_done++;
            if (rd_out[s].size() == 0) rd_free_cyc = cyc;
          end
        end
      end
      if (s_bvalid && s_bready) begin
        s = int'(s_bid);
        if (wr_out[s].size() == 0) begin
          if (stale_wsid[s]) fail_m("F1", $sformatf("write response for slave id %0d after reset; nothing of it outstanding", s));
          else               fail_m("C2", $sformatf("write response for slave id %0d with no write outstanding", s));
        end else if (exp_b[s].size() == 0) begin
          fail_m("C2", $sformatf("write response for slave id %0d before any downstream B was returned for it", s));
        end else begin
          t = exp_b[s].pop_front();
          if (t != wr_out[s][0]) fail_m("B1", $sformatf("write responses for slave id %0d out of order", s));
          void'(wr_out[s].pop_front());
          n_wr_done++;
          if (wr_out[s].size() == 0) wr_free_cyc = cyc;
        end
      end

      // ---------------------------------------------------------- 3. slave address handshakes
      if (s_arvalid && s_arready) begin
        ar_hs_n++;
        s = int'(s_arid);
        if (rd_out[s].size() == 0 && n_distinct(1'b0) >= MAX_UNIQ_IDS)
          fail_m("A3", $sformatf("read with new slave id %0d accepted while %0d distinct ids outstanding (A2)", s, n_distinct(1'b0)));
        if (rd_out[s].size() >= MAX_TXNS_PER_ID)
          fail_m("A5", $sformatf("read #%0d outstanding for slave id %0d accepted", rd_out[s].size() + 1, s));
        t = ntag++;
        a = int'(s_araddr);
        r_sid[t] = s; r_len[t] = int'(s_arlen); r_mid[t] = -1;
        rd_out[s].push_back(t);
        r_addr2tag[a] = t;
        stale_rsid[s] = 1'b0;
        ar_acc_cyc = cyc;
        n_rd_acc++;
        if (r_pend.exists(a)) begin link_rd(t, r_pend[a].mid, r_pend[a].len); r_pend.delete(a); end
      end
      if (s_awvalid && s_awready) begin
        aw_hs_n++;
        s = int'(s_awid);
        if (wr_out[s].size() == 0 && n_distinct(1'b1) >= MAX_UNIQ_IDS)
          fail_m("A3", $sformatf("write with new slave id %0d accepted while %0d distinct ids outstanding (A2)", s, n_distinct(1'b1)));
        if (wr_out[s].size() >= MAX_TXNS_PER_ID)
          fail_m("A5", $sformatf("write #%0d outstanding for slave id %0d accepted", wr_out[s].size() + 1, s));
        t = ntag++;
        a = int'(s_awaddr);
        w_sid[t] = s; w_len[t] = int'(s_awlen); w_mid[t] = -1;
        wr_out[s].push_back(t);
        w_addr2tag[a] = t;
        w_todo.push_back(t);
        stale_wsid[s] = 1'b0;
        aw_acc_cyc = cyc;
        n_wr_acc++;
        if (w_pend.exists(a)) begin link_wr(t, w_pend[a].mid, w_pend[a].len); w_pend.delete(a); end
      end

      // ---------------------------------------------------------- 4. master address handshakes
      if (m_arvalid && m_arready) begin
        a = int'(m_araddr);
        if (r_addr2tag.exists(a)) begin
          t = r_addr2tag[a];
          if (r_mid[t] != -1) fail_m("D4", $sformatf("second master read for one slave read (addr %h)", m_araddr));
          else link_rd(t, int'(m_arid), m_arlen);
        end else if (r_stale_addr.exists(a)) begin
          mq.mid = int'(m_arid); mq.len = m_arlen; r_stale_work.push_back(mq);
        end else if (s_arvalid && s_araddr == m_araddr) begin
          mq.mid = int'(m_arid); mq.len = m_arlen; r_pend[a] = mq;   // forwarded ahead of its own acceptance
        end else begin
          fail_m("D4", $sformatf("master read addr %h matches no accepted slave read (E1 address)", m_araddr));
        end
      end
      if (m_awvalid && m_awready) begin
        a = int'(m_awaddr);
        if (w_addr2tag.exists(a)) begin
          t = w_addr2tag[a];
          if (w_mid[t] != -1) fail_m("D4", $sformatf("second master write for one slave write (addr %h)", m_awaddr));
          else link_wr(t, int'(m_awid), m_awlen);
        end else if (w_stale_addr.exists(a)) begin
          mq.mid = int'(m_awid); mq.len = m_awlen; w_stale_work.push_back(mq);
        end else if (s_awvalid && s_awaddr == m_awaddr) begin
          mq.mid = int'(m_awid); mq.len = m_awlen; w_pend[a] = mq;
        end else begin
          fail_m("D4", $sformatf("master write addr %h matches no accepted slave write (E1 address)", m_awaddr));
        end
      end

      // ---------------------------------------------------------- 5. write data (B3, E1)
      if (s_wvalid && s_wready) begin
        w_hs_n++;
        wb.tag = w_cur_tag; wb.data = s_wdata; wb.strb = s_wstrb; wb.last = s_wlast;
        sw_stream.push_back(wb);
      end
      if (m_wvalid && m_wready) begin
        if (sw_stream.size() == 0) begin
          fail_m("E1", "master W beat with no slave W beat to account for it (B3)");
        end else begin
          wb = sw_stream.pop_front();
          if (m_wdata !== wb.data || m_wstrb !== wb.strb || m_wlast !== wb.last)
            fail_m("E1", $sformatf("master W beat %h/%h/%0d, expected %h/%h/%0d in slave order (B3)",
                                 m_wdata, m_wstrb, m_wlast, wb.data, wb.strb, wb.last));
          if (wb.last && wb.tag >= 0) w_mwdone[wb.tag] = 1'b1;
        end
      end
    end
  end

  // ---------------------------------------------------------------------------
  // Ready generators (driven at negedge; nothing samples there but the design
  // at the following posedge)
  // ---------------------------------------------------------------------------
  function automatic logic pick_ready(input int mode);
    if (mode == 0) return 1'b0;
    if (mode == 1) return 1'b1;
    return $urandom_range(0, 99) < 75;
  endfunction

  always @(negedge clk) begin
    s_rready  = pick_ready(s_rready_mode);
    s_bready  = pick_ready(s_bready_mode);
    m_arready = pick_ready(m_ready_mode);
    m_awready = pick_ready(m_ready_mode);
    m_wready  = pick_ready(m_ready_mode);
  end

  // ---------------------------------------------------------------------------
  // Drivers (hold valid until the monitor reports the handshake)
  // ---------------------------------------------------------------------------
  task automatic drv_ar(input logic [SLV_ID_W-1:0] id, input logic [ADDR_W-1:0] addr,
                        input logic [7:0] len, input int budget, output bit acc, output int waited);
    int c0;
    acc = 1'b0; waited = 0;
    @(negedge clk);
    c0 = ar_hs_n;
    s_arid = id; s_araddr = addr; s_arlen = len; s_arvalid = 1'b1;
    forever begin
      @(negedge clk);
      if (ar_hs_n != c0) begin acc = 1'b1; break; end
      if (waited >= budget) break;
      if (rel_kind == 1 && waited == rel_at) s_rready_mode = 1;     // A4: release while held
      waited++;
    end
    s_arvalid = 1'b0;
  endtask

  task automatic drv_aw(input logic [SLV_ID_W-1:0] id, input logic [ADDR_W-1:0] addr,
                        input logic [7:0] len, input int budget, output bit acc, output int waited);
    int c0;
    acc = 1'b0; waited = 0;
    @(negedge clk);
    c0 = aw_hs_n;
    s_awid = id; s_awaddr = addr; s_awlen = len; s_awvalid = 1'b1;
    forever begin
      @(negedge clk);
      if (aw_hs_n != c0) begin acc = 1'b1; break; end
      if (waited >= budget) break;
      if (rel_kind == 2 && waited == rel_at) s_bready_mode = 1;
      waited++;
    end
    s_awvalid = 1'b0;
  endtask

  // downstream beats; abandoned if reset intervenes
  task automatic rbeat_x(input int mid, input logic [31:0] data, input logic [1:0] resp,
                         input logic last, output bit ok);
    int c0;
    ok = 1'b0;
    @(negedge clk);
    if (in_rst) return;
    c0 = mr_hs_n;
    m_rid = MST_ID_W'(mid); m_rdata = data; m_rresp = resp; m_rlast = last; m_rvalid = 1'b1;
    forever begin
      @(negedge clk);
      if (mr_hs_n != c0) begin ok = 1'b1; break; end
      if (in_rst) break;
    end
    m_rvalid = 1'b0;
  endtask

  task automatic bbeat_x(input int mid, output bit ok);
    int c0;
    ok = 1'b0;
    @(negedge clk);
    if (in_rst) return;
    c0 = mb_hs_n;
    m_bid = MST_ID_W'(mid); m_bresp = 2'b00; m_bvalid = 1'b1;
    forever begin
      @(negedge clk);
      if (mb_hs_n != c0) begin ok = 1'b1; break; end
      if (in_rst) break;
    end
    m_bvalid = 1'b0;
  endtask

  // ---------------------------------------------------------------------------
  // Write data driver: beats for accepted AWs, in accept order (B3)
  // ---------------------------------------------------------------------------
  initial begin : w_driver
    automatic int t, k, ep, c0, idx, my_ep;
    automatic bit ok;
    idx = 0; my_ep = -1;
    forever begin
      @(negedge clk);
      if (my_ep != epoch) begin my_ep = epoch; idx = 0; end
      if (in_rst || idx >= w_todo.size()) continue;
      t = w_todo[idx];
      idx++;
      ep = epoch;
      for (k = 0; k <= w_len[t]; k++) begin
        while ($urandom_range(0, 99) < w_gap) @(negedge clk);
        if (in_rst || ep != epoch) break;
        w_cur_tag = t;
        c0 = w_hs_n;
        s_wdata = $urandom; s_wstrb = 4'($urandom); s_wlast = (k == w_len[t]);
        s_wvalid = 1'b1;
        ok = 1'b0;
        forever begin
          @(negedge clk);
          if (w_hs_n != c0) begin ok = 1'b1; break; end
          if (in_rst) break;
        end
        s_wvalid = 1'b0;
        if (!ok || ep != epoch) break;
      end
    end
  end

  // ---------------------------------------------------------------------------
  // Downstream read responder
  // ---------------------------------------------------------------------------
  initial begin : r_responder
    automatic int    cand [$];
    automatic int    t, m, s, pick, k, ep, my_ep, shead;
    automatic int    head [NMID];
    automatic bit    ok;
    automatic mreq_t sw;
    my_ep = -1; shead = 0;
    forever begin
      @(negedge clk);
      if (my_ep != epoch) begin my_ep = epoch; shead = 0; for (m = 0; m < NMID; m++) head[m] = 0; end
      if (in_rst || !r_en) continue;
      if ($urandom_range(0, 99) < resp_idle) continue;
      if (shead < r_stale_work.size()) begin                // stale downstream work: answer it
        sw = r_stale_work[shead];
        shead++;
        for (k = 0; k <= int'(sw.len); k++) begin
          r_cur_tag = -1;
          rbeat_x(sw.mid, $urandom, 2'b00, k == int'(sw.len), ok);
          if (!ok) break;
        end
        continue;
      end
      cand.delete();
      for (m = 0; m < NMID; m++) begin
        if (head[m] >= r_midq[m].size()) continue;
        t = r_midq[m][head[m]];
        s = r_sid[t];
        if (r_allow[s] && first_untaken_rd(s) == t) cand.push_back(t);
      end
      if (cand.size() == 0) continue;
      pick = cand[$urandom_range(0, cand.size() - 1)];
      m = r_mid[pick];
      head[m]++;
      r_taken[pick] = 1'b1;
      ep = epoch;
      for (k = 0; k <= r_len[pick]; k++) begin
        while ($urandom_range(0, 99) < beat_gap) @(negedge clk);
        if (in_rst || ep != epoch) break;
        r_cur_tag = pick;
        rbeat_x(m, $urandom, 2'($urandom_range(0, 3)), k == r_len[pick], ok);
        if (!ok || ep != epoch) break;
      end
    end
  end

  // ---------------------------------------------------------------------------
  // Downstream write responder (only after all of a write's beats went out)
  // ---------------------------------------------------------------------------
  initial begin : b_responder
    automatic int    cand [$];
    automatic int    t, m, s, pick, my_ep, shead;
    automatic int    head [NMID];
    automatic bit    ok;
    automatic mreq_t sw;
    my_ep = -1; shead = 0;
    forever begin
      @(negedge clk);
      if (my_ep != epoch) begin my_ep = epoch; shead = 0; for (m = 0; m < NMID; m++) head[m] = 0; end
      if (in_rst || !b_en) continue;
      if ($urandom_range(0, 99) < resp_idle) continue;
      if (shead < w_stale_work.size()) begin
        sw = w_stale_work[shead];
        shead++;
        b_cur_tag = -1;
        bbeat_x(sw.mid, ok);
        continue;
      end
      cand.delete();
      for (m = 0; m < NMID; m++) begin
        if (head[m] >= w_midq[m].size()) continue;
        t = w_midq[m][head[m]];
        s = w_sid[t];
        if (b_allow[s] && w_mwdone.exists(t) && first_untaken_wr(s) == t) cand.push_back(t);
      end
      if (cand.size() == 0) continue;
      pick = cand[$urandom_range(0, cand.size() - 1)];
      m = w_mid[pick];
      head[m]++;
      w_taken[pick] = 1'b1;
      b_cur_tag = pick;
      bbeat_x(m, ok);
    end
  end

  // ---------------------------------------------------------------------------
  // Random traffic generators. Started by a sequencer-owned run counter; each
  // reports completion on a counter only it writes.
  // ---------------------------------------------------------------------------
  int rnd_run = 0, rnd_n = 0, rnd_pool = 8;        // sequencer-owned
  int rnd_ar_fin = 0;                              // rnd_ar-owned
  int rnd_aw_fin = 0;                              // rnd_aw-owned
  int actr0 = 0, actr1 = 0, actr2 = 0;            // address counter per offering process
  int rel_kind = 0, rel_at = 0;                    // sequencer-owned (A4 release point)

  function automatic logic [31:0] next_addr(input int src);
    int v;
    case (src)
      0:       begin actr0++; v = actr0; end
      1:       begin actr1++; v = actr1; end
      default: begin actr2++; v = actr2; end
    endcase
    return {src[1:0], v[25:0], 4'h0};
  endfunction

  initial begin : rnd_ar
    automatic bit acc;
    automatic int w, my_run;
    my_run = 0;
    forever begin
      while (rnd_run == my_run) @(negedge clk);
      my_run = rnd_run;
      for (int i = 0; i < rnd_n; i++) begin
        repeat ($urandom_range(0, 3)) @(negedge clk);
        drv_ar(SLV_ID_W'($urandom_range(0, rnd_pool - 1)), next_addr(1), 8'($urandom_range(0, 3)),
               $urandom_range(0, 15), acc, w);
      end
      rnd_ar_fin++;
    end
  end

  initial begin : rnd_aw
    automatic bit acc;
    automatic int w, my_run;
    my_run = 0;
    forever begin
      while (rnd_run == my_run) @(negedge clk);
      my_run = rnd_run;
      for (int i = 0; i < rnd_n; i++) begin
        repeat ($urandom_range(0, 3)) @(negedge clk);
        drv_aw(SLV_ID_W'($urandom_range(0, rnd_pool - 1)), next_addr(2), 8'($urandom_range(0, 3)),
               $urandom_range(0, 15), acc, w);
      end
      rnd_aw_fin++;
    end
  end

  // ---------------------------------------------------------------------------
  // Sequencer helpers
  // ---------------------------------------------------------------------------
  function automatic bit all_idle();
    for (int s = 0; s < NSID; s++) if (rd_out[s].size() || wr_out[s].size()) return 1'b0;
    return (r_pend.size() == 0) && (w_pend.size() == 0);
  endfunction

  // Let everything complete; anything that cannot is a lost transaction (D4).
  task automatic drain(input string phase, input int limit);
    int k;
    s_rready_mode = 1; s_bready_mode = 1; m_ready_mode = 1;
    r_en = 1'b1; b_en = 1'b1;
    for (int s = 0; s < NSID; s++) begin r_allow[s] = 1'b1; b_allow[s] = 1'b1; end
    for (k = 0; k < limit && !all_idle(); k++) @(negedge clk);
    if (!all_idle()) begin
      for (int s = 0; s < NSID; s++) begin
        for (int j = 0; j < rd_out[s].size(); j++)
          fail_s("D4", $sformatf("[%s] read (slave id %0d) never completed: %s", phase, s,
                               r_mid[rd_out[s][j]] < 0 ? "never forwarded to the master port" : "response never returned"));
        for (int j = 0; j < wr_out[s].size(); j++)
          fail_s("D4", $sformatf("[%s] write (slave id %0d) never completed: %s", phase, s,
                               w_mid[wr_out[s][j]] < 0 ? "never forwarded to the master port" : "response never returned"));
      end
      if (r_pend.size() || w_pend.size())
        fail_s("D4", $sformatf("[%s] master request issued for a slave request never accepted", phase));
    end
  endtask

  // Fill ids lo..lo+n-1 in one direction; each must be accepted (A3 boundary).
  task automatic must_accept(input bit is_wr, input int id, input string why);
    bit acc;
    int w;
    if (is_wr) drv_aw(SLV_ID_W'(id), next_addr(0), 8'd1, 300, acc, w);
    else       drv_ar(SLV_ID_W'(id), next_addr(0), 8'd1, 300, acc, w);
    if (!acc) fail_s("A3", $sformatf("%s with new slave id %0d refused (%0d distinct outstanding): %s",
                                   is_wr ? "write" : "read", id, n_distinct(is_wr), why));
  endtask

  task automatic offer(input bit is_wr, input int id, input int budget, output bit acc);
    int w;
    if (is_wr) drv_aw(SLV_ID_W'(id), next_addr(0), 8'd0, budget, acc, w);
    else       drv_ar(SLV_ID_W'(id), next_addr(0), 8'd0, budget, acc, w);
  endtask

  // A4: with the table full, stall the SLAVE side of id 1's response (it has
  // been answered downstream but has not retired -- the D2 exposure), hold a
  // request with a new id, release the stall part-way through the hold, and
  // time the acceptance against the retiring edge.
  task automatic a4_case(input bit is_wr);
    bit    acc;
    int    w, freed, freed0, accd;
    string dir;
    dir = is_wr ? "write" : "read";
    freed0 = is_wr ? wr_free_cyc : rd_free_cyc;
    if (is_wr) begin s_bready_mode = 0; for (int s = 0; s < NSID; s++) b_allow[s] = (s == 1); b_en = 1'b1; end
    else       begin s_rready_mode = 0; for (int s = 0; s < NSID; s++) r_allow[s] = (s == 1); r_en = 1'b1; end
    repeat (40) @(negedge clk);
    rel_kind = is_wr ? 2 : 1;
    rel_at   = 25;                       // refused for 25 cycles first (A3, checked by the monitor)
    if (is_wr) drv_aw(SLV_ID_W'(5), next_addr(0), 8'd0, 400, acc, w);
    else       drv_ar(SLV_ID_W'(5), next_addr(0), 8'd0, 400, acc, w);
    rel_kind = 0;
    repeat (2) @(negedge clk);
    if (!acc) begin
      fail_s("A4", $sformatf("%s with new slave id 5 never accepted after slave id 1 retired", dir));
    end else begin
      freed = is_wr ? wr_free_cyc : rd_free_cyc;
      accd  = is_wr ? aw_acc_cyc  : ar_acc_cyc;
      // accepted before id 1 retired is an A3 violation, already reported by the monitor
      if (freed != freed0 && accd >= freed && accd - freed > 2)
        fail_s("A4", $sformatf("%s entry freed at cycle %0d, waiting request accepted at %0d (> 2 cycles)", dir, freed, accd));
    end
    if (is_wr) begin b_en = 1'b0; for (int s = 0; s < NSID; s++) b_allow[s] = 1'b1; end
    else       begin r_en = 1'b0; for (int s = 0; s < NSID; s++) r_allow[s] = 1'b1; end
  endtask

  // ---------------------------------------------------------------------------
  // Sequencer
  // ---------------------------------------------------------------------------
  initial begin : sequencer
    automatic bit acc;
    automatic int k, f_ar, f_aw;

    bfm_reset(4);
    repeat (5) @(negedge clk);

    $display("t=%0t phase 1: A3 boundary / A1 / A5", $time);
    // ===== Phase 1: A3 boundary, A1 separate counting, A5 depth ==============
    m_ready_mode = 1; s_rready_mode = 1; s_bready_mode = 1;
    r_en = 1'b0; b_en = 1'b0; resp_idle = 0; beat_gap = 0; w_gap = 0;
    // after reset the table is empty: MAX_UNIQ_IDS distinct ids must go in,
    // each at (n < MAX) distinct outstanding. Same ids both directions, so a
    // design sharing entries between directions (latitude 6) is not penalised.
    for (int s = 0; s < MAX_UNIQ_IDS; s++) must_accept(1'b0, s, "read side below the bound (A2/A3)");
    for (int s = 0; s < MAX_UNIQ_IDS; s++) must_accept(1'b1, s, "write side counted separately (A1)");
    repeat (10) @(negedge clk);
    // at the bound a new id must not be accepted (the monitor flags it if it is)
    offer(1'b0, 4, 30, acc);
    offer(1'b1, 4, 30, acc);
    // depth per id: third concurrent txn for one id must not be accepted
    for (k = 0; k < 3; k++) offer(1'b0, 0, 20, acc);
    for (k = 0; k < 3; k++) offer(1'b1, 0, 20, acc);
    repeat (10) @(negedge clk);

    $display("t=%0t phase 2: A4 / D2", $time);
    // ===== Phase 2: A4 window and D2 reuse-before-retirement ================
    a4_case(1'b0);
    a4_case(1'b1);
    resp_idle = 10; beat_gap = 10;
    drain("phase 2", 3000);

    $display("t=%0t phase 3: F1 reset", $time);
    // ===== Phase 3: F1 reset ================================================
    // leave responses pending inside the design (slave side stalled)
    s_rready_mode = 0; s_bready_mode = 0; m_ready_mode = 1;
    r_en = 1'b1; b_en = 1'b1; resp_idle = 0; beat_gap = 0;
    for (int s = 0; s < 3; s++) must_accept(1'b0, s, "after drain");
    for (int s = 0; s < 3; s++) must_accept(1'b1, s, "after drain");
    repeat (60) @(negedge clk);
    // reset, offering requests while it is low (accepting them is legal)
    @(negedge clk) rst_n = 1'b0;
    offer(1'b0, 7, 2, acc);
    offer(1'b1, 7, 2, acc);
    repeat (2) @(negedge clk);
    rst_n = 1'b1;
    // quiet window: nothing may come back for anything from before or during reset
    s_rready_mode = 1; s_bready_mode = 1;
    repeat (150) @(negedge clk);
    // the table is empty after release: MAX_UNIQ_IDS NEW ids must be accepted.
    // Responders paused so the ids stay outstanding and the table really fills.
    r_en = 1'b0; b_en = 1'b0;
    for (int s = 8; s < 8 + MAX_UNIQ_IDS; s++) must_accept(1'b0, s, "after reset release (F1: table empty)");
    for (int s = 8; s < 8 + MAX_UNIQ_IDS; s++) must_accept(1'b1, s, "after reset release (F1: table empty)");
    resp_idle = 10; beat_gap = 10;
    drain("phase 3", 3000);

    $display("t=%0t phase 4: random traffic", $time);
    // ===== Phase 4: random traffic ==========================================
    s_rready_mode = 2; s_bready_mode = 2; m_ready_mode = 2;
    r_en = 1'b1; b_en = 1'b1; resp_idle = 40; beat_gap = 25; w_gap = 20;
    rnd_n = 1500; rnd_pool = 8;
    f_ar = rnd_ar_fin; f_aw = rnd_aw_fin;
    rnd_run++;
    for (k = 0; k < 150000 && !(rnd_ar_fin != f_ar && rnd_aw_fin != f_aw); k++) @(negedge clk);
    if (!(rnd_ar_fin != f_ar && rnd_aw_fin != f_aw)) fail_s("D4", "random traffic did not finish");
    drain("random", 5000);

    $display("t=%0t verdict", $time);
    // ===== Verdict ==========================================================
    $display("summary: reads %0d accepted / %0d completed, writes %0d accepted / %0d completed",
             n_rd_acc, n_rd_done, n_wr_acc, n_wr_done);
    if (n_rd_acc < 100 || n_wr_acc < 100) fail_s("D4", "too little traffic completed to judge the design");
    if (errs_m + errs_s == 0) $display("RESULT: PASS");
    else           $display("RESULT: FAIL");
    $finish;
  end

endmodule