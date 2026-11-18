// ---------------------------------------------------------------------------
// id_width_conv_tb -- self-checking testbench for the AXI ID-width converter
//
// Model maintained by the TB:
//   pend_ar/pend_aw : slave requests accepted but not yet seen at master port
//   rd_outst/wr_outst : master transactions awaiting a downstream response
//   exp_wq          : expected master write-data beats (acceptance order, B3)
//   exp_r_sid[sid]  : expected slave read beats per slave id (B1/C1/E1)
//   exp_b_cnt[sid]  : expected slave write responses per slave id
// ---------------------------------------------------------------------------
module id_width_conv_tb;

  localparam int unsigned SLV_ID_W = 4;
  localparam int unsigned MST_ID_W = 2;
  localparam int unsigned ADDR_W   = 32;
  localparam int unsigned DATA_W   = 32;
  localparam int unsigned MAX_UNIQ_IDS    = 4;
  localparam int unsigned MAX_TXNS_PER_ID = 2;
  localparam int unsigned STRB_W = DATA_W/8;

  // ---------------- DUT wiring ----------------
  logic clk, rst_n;
  logic [SLV_ID_W-1:0] s_awid, s_bid, s_arid, s_rid;
  logic [ADDR_W-1:0]   s_awaddr, s_araddr;
  logic [7:0]          s_awlen, s_arlen;
  logic                s_awvalid, s_awready;
  logic [DATA_W-1:0]   s_wdata;
  logic [STRB_W-1:0]   s_wstrb;
  logic                s_wlast, s_wvalid, s_wready;
  logic [1:0]          s_bresp;
  logic                s_bvalid, s_bready;
  logic                s_arvalid, s_arready;
  logic [DATA_W-1:0]   s_rdata;
  logic [1:0]          s_rresp;
  logic                s_rlast, s_rvalid, s_rready;

  logic [MST_ID_W-1:0] m_awid, m_bid, m_arid, m_rid;
  logic [ADDR_W-1:0]   m_awaddr, m_araddr;
  logic [7:0]          m_awlen, m_arlen;
  logic                m_awvalid, m_awready;
  logic [DATA_W-1:0]   m_wdata, m_rdata;
  logic [STRB_W-1:0]   m_wstrb;
  logic                m_wlast, m_wvalid, m_wready;
  logic [1:0]          m_bresp, m_rresp;
  logic                m_bvalid, m_bready;
  logic                m_arvalid, m_arready;
  logic                m_rlast, m_rvalid, m_rready;

  id_width_conv #(
    .SLV_ID_W(SLV_ID_W), .MST_ID_W(MST_ID_W), .ADDR_W(ADDR_W),
    .DATA_W(DATA_W), .MAX_UNIQ_IDS(MAX_UNIQ_IDS),
    .MAX_TXNS_PER_ID(MAX_TXNS_PER_ID)
  ) dut (
    .clk_i(clk), .rst_ni(rst_n),
    .s_awid(s_awid), .s_awaddr(s_awaddr), .s_awlen(s_awlen),
    .s_awvalid(s_awvalid), .s_awready(s_awready),
    .s_wdata(s_wdata), .s_wstrb(s_wstrb), .s_wlast(s_wlast),
    .s_wvalid(s_wvalid), .s_wready(s_wready),
    .s_bid(s_bid), .s_bresp(s_bresp), .s_bvalid(s_bvalid), .s_bready(s_bready),
    .s_arid(s_arid), .s_araddr(s_araddr), .s_arlen(s_arlen),
    .s_arvalid(s_arvalid), .s_arready(s_arready),
    .s_rid(s_rid), .s_rdata(s_rdata), .s_rresp(s_rresp),
    .s_rlast(s_rlast), .s_rvalid(s_rvalid), .s_rready(s_rready),
    .m_awid(m_awid), .m_awaddr(m_awaddr), .m_awlen(m_awlen),
    .m_awvalid(m_awvalid), .m_awready(m_awready),
    .m_wdata(m_wdata), .m_wstrb(m_wstrb), .m_wlast(m_wlast),
    .m_wvalid(m_wvalid), .m_wready(m_wready),
    .m_bid(m_bid), .m_bresp(m_bresp), .m_bvalid(m_bvalid), .m_bready(m_bready),
    .m_arid(m_arid), .m_araddr(m_araddr), .m_arlen(m_arlen),
    .m_arvalid(m_arvalid), .m_arready(m_arready),
    .m_rid(m_rid), .m_rdata(m_rdata), .m_rresp(m_rresp),
    .m_rlast(m_rlast), .m_rvalid(m_rvalid), .m_rready(m_rready)
  );

  // ---------------- model state ----------------
  typedef struct packed {
    logic [SLV_ID_W-1:0] sid;
    logic [ADDR_W-1:0]   addr;
    logic [7:0]          len;
    logic [MST_ID_W-1:0] mid;
  } txn_t;

  typedef struct packed {
    logic [SLV_ID_W-1:0] sid;
    logic [DATA_W-1:0]   data;
    logic               last;
  } rbeat_t;

  typedef struct packed {
    logic [DATA_W-1:0]    data;
    logic [STRB_W-1:0]    strb;
    logic                last;
  } wbeat_t;

  txn_t   pend_ar[$], pend_aw[$];   // accepted at slave, not yet at master
  txn_t   rd_outst[$], wr_outst[$]; // forwarded, awaiting downstream response
  wbeat_t exp_wq[$];                 // expected master W beats (acceptance order)
  rbeat_t exp_r_sid [16][$];        // expected slave R beats, per slave id (B1)
  int     exp_b_cnt [16];            // expected slave B responses, per slave id

  int  errors        = 0;
  int  post_rst_cnt  = 0;
  bit  rst_prev      = 1'b0;
  bit  acc;
  int  wt, cyc, addr_n = 0;
  logic [ADDR_W-1:0] a;

  // ---------------------------------------------------------------------------
  // PROVIDED PLUMBING
  // ---------------------------------------------------------------------------
  initial begin clk = 1'b0; forever #5 clk = ~clk; end

  initial rst_n = 1'b0;

  task automatic bfm_reset(input int cycles = 4);
    @(negedge clk);
    rst_n = 1'b0;
    repeat (cycles) @(posedge clk);
    @(negedge clk);
    rst_n = 1'b1;
  endtask

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

  task automatic bfm_w(input logic [DATA_W-1:0]   data,
                       input logic [DATA_W/8-1:0] strb,
                       input logic                last);
    @(negedge clk);
    s_wdata = data; s_wstrb = strb; s_wlast = last; s_wvalid = 1'b1;
    forever begin @(posedge clk); if (s_wready) break; end
    @(negedge clk) s_wvalid = 1'b0;
  endtask

  task automatic bfm_rbeat(input logic [MST_ID_W-1:0] mid,
                           input logic [DATA_W-1:0]   data,
                           input logic                last);
    @(negedge clk);
    m_rid = mid; m_rdata = data; m_rlast = last; m_rresp = 2'b00; m_rvalid = 1'b1;
    forever begin @(posedge clk); if (m_rready) break; end
    @(negedge clk) m_rvalid = 1'b0;
  endtask

  task automatic bfm_bbeat(input logic [MST_ID_W-1:0] mid);
    @(negedge clk);
    m_bid = mid; m_bresp = 2'b00; m_bvalid = 1'b1;
    forever begin @(posedge clk); if (m_bready) break; end
    @(negedge clk) m_bvalid = 1'b0;
  endtask

  initial begin
    #4_000_000;
    $display("RESULT: FAIL (watchdog: no forward progress)");
    $finish;
  end

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------
  task automatic fail(input string tag, input string msg);
    errors++;
    $display("FAIL [%s] %s (time %0t)", tag, msg, $time);
  endtask

  task automatic chk_acc(input bit ok, input string tag, input string msg);
    if (!ok) fail(tag, msg);
  endtask

  function automatic logic [ADDR_W-1:0] gen_addr();
    addr_n = addr_n + 1;
    gen_addr = 32'h0000_1000 + addr_n * 64;
  endfunction

  function automatic int find_rd(input logic [SLV_ID_W-1:0] sid);
    find_rd = -1;
    for (int i = 0; i < rd_outst.size(); i++)
      if (rd_outst[i].sid == sid) begin find_rd = i; break; end
  endfunction

  function automatic int find_wr(input logic [SLV_ID_W-1:0] sid);
    find_wr = -1;
    for (int i = 0; i < wr_outst.size(); i++)
      if (wr_outst[i].sid == sid) begin find_wr = i; break; end
  endfunction

  function automatic int tot_exp();
    tot_exp = exp_wq.size();
    for (int i = 0; i < 16; i++) begin
      tot_exp += exp_r_sid[i].size();
      tot_exp += exp_b_cnt[i];
    end
  endfunction

  task automatic clear_model();
    pend_ar.delete();  pend_aw.delete();
    rd_outst.delete(); wr_outst.delete();
    exp_wq.delete();
    for (int i = 0; i < 16; i++) begin
      exp_r_sid[i].delete();
      exp_b_cnt[i] = 0;
    end
  endtask

  task automatic settle(input int n);
    repeat (n) @(negedge clk);
  endtask

  task automatic wait_rd(input int n);
    automatic int guard;
    guard = 0;
    while (rd_outst.size() < n && guard < 400) begin guard++; @(negedge clk); end
    if (rd_outst.size() < n) fail("D4", "master read transaction never forwarded");
  endtask

  task automatic wait_wr(input int n);
    automatic int guard;
    guard = 0;
    while (wr_outst.size() < n && guard < 400) begin guard++; @(negedge clk); end
    if (wr_outst.size() < n) fail("D4", "master write transaction never forwarded");
  endtask

  task automatic wait_sid_r_empty(input int sid);
    automatic int guard;
    guard = 0;
    while (exp_r_sid[sid].size() > 0 && guard < 300) begin guard++; @(negedge clk); end
  endtask

  task automatic wait_sid_b_empty(input int sid);
    automatic int guard;
    guard = 0;
    while (exp_b_cnt[sid] > 0 && guard < 300) begin guard++; @(negedge clk); end
  endtask

  task automatic quiesce();
    automatic int guard;
    guard = 0;
    while ((pend_ar.size() + pend_aw.size() + rd_outst.size() +
            wr_outst.size() + tot_exp()) > 0 && guard < 800) begin
      guard++; @(negedge clk);
    end
    if (guard >= 800) fail("D4", "design did not quiesce (transactions stuck)");
  endtask

  // Send the write beats matching what the checker recorded for this AW.
  task automatic do_w(input logic [ADDR_W-1:0] addr, input logic [7:0] len);
    for (int unsigned b = 0; b <= len; b++)
      bfm_w(addr + b * (DATA_W/8), {STRB_W{1'b1}}, (b == len));
  endtask

  // Respond to the read txn at rd_outst[idx] (per-sid order preserved).
  task automatic respond_read(input int idx);
    automatic txn_t t;
    if (idx < 0 || idx >= rd_outst.size()) begin
      fail("D4", "respond_read: no such outstanding read txn");
      return;
    end
    t = rd_outst[idx];
    for (int b = 0; b <= t.len; b++) begin
      exp_r_sid[t.sid].push_back(
        rbeat_t'{t.sid, t.addr + b * (DATA_W/8), (b == t.len)});
      bfm_rbeat(t.mid, t.addr + b * (DATA_W/8), (b == t.len));
    end
    rd_outst.delete(idx);
  endtask

  task automatic respond_write(input int idx);
    automatic txn_t t;
    if (idx < 0 || idx >= wr_outst.size()) begin
      fail("D4", "respond_write: no such outstanding write txn");
      return;
    end
    t = wr_outst[idx];
    exp_b_cnt[t.sid]++;
    bfm_bbeat(t.mid);
    wr_outst.delete(idx);
  endtask

  task automatic drain_reads();
    while (rd_outst.size() > 0) respond_read(0);
  endtask

  task automatic drain_writes();
    while (wr_outst.size() > 0) respond_write(0);
  endtask

  // ---------------------------------------------------------------------------
  // Checker -- samples at posedge (TB drives at negedge, so no race)
  // ---------------------------------------------------------------------------
  always @(posedge clk) begin
    automatic int    k;
    automatic txn_t  t;
    automatic wbeat_t we;
    automatic rbeat_t re;

    // reset release: table must be empty, everything outstanding is discarded
    if (rst_n && !rst_prev) begin
      clear_model();
      post_rst_cnt = 30;
    end
    rst_prev = rst_n;
    if (post_rst_cnt > 0) post_rst_cnt = post_rst_cnt - 1;

    if (!rst_n) begin
      // F1: no response may be presented during reset
      if (s_rvalid) fail("F1", "s_rvalid asserted during reset");
      if (s_bvalid) fail("F1", "s_bvalid asserted during reset");
      // handshakes during reset are legal and are simply discarded
    end else begin
      // record slave-side acceptances first (a combinational forward could
      // complete on the same edge)
      if (s_arvalid && s_arready) begin
        t.sid = s_arid; t.addr = s_araddr; t.len = s_arlen; t.mid = '0;
        pend_ar.push_back(t);
      end
      if (s_awvalid && s_awready) begin
        t.sid = s_awid; t.addr = s_awaddr; t.len = s_awlen; t.mid = '0;
        pend_aw.push_back(t);
        for (int b = 0; b <= s_awlen; b++)
          exp_wq.push_back(wbeat_t'{s_awaddr + b * (DATA_W/8),
                                    {STRB_W{1'b1}}, (b == s_awlen)});
      end

      // master read address: D4 one-in-one-out, E1 payload, D1 mid uniqueness
      if (m_arvalid && m_arready) begin
        k = -1;
        for (int i = 0; i < pend_ar.size(); i++)
          if (pend_ar[i].addr == m_araddr) k = i;
        if (k < 0) begin
          fail("D4", "master AR with no matching accepted slave AR");
        end else begin
          t = pend_ar[k];
          pend_ar.delete(k);
          if (t.len !== m_arlen) fail("E1", "master AR len mismatch");
          for (int i = 0; i < rd_outst.size(); i++)
            if (rd_outst[i].mid === m_arid && rd_outst[i].sid !== t.sid)
              fail("D1", "master read id collision between co-outstanding slave ids");
          t.mid = m_arid;
          rd_outst.push_back(t);
        end
      end

      // master write address
      if (m_awvalid && m_awready) begin
        k = -1;
        for (int i = 0; i < pend_aw.size(); i++)
          if (pend_aw[i].addr == m_awaddr) k = i;
        if (k < 0) begin
          fail("D4", "master AW with no matching accepted slave AW");
        end else begin
          t = pend_aw[k];
          pend_aw.delete(k);
          if (t.len !== m_awlen) fail("E1", "master AW len mismatch");
          for (int i = 0; i < wr_outst.size(); i++)
            if (wr_outst[i].mid === m_awid && wr_outst[i].sid !== t.sid)
              fail("D1", "master write id collision between co-outstanding slave ids");
          t.mid = m_awid;
          wr_outst.push_back(t);
        end
      end

      // master write data: B3 order / no interleaving, E1 payload
      if (m_wvalid && m_wready) begin
        if (exp_wq.size() == 0) begin
          fail("E1", "unexpected master write beat");
        end else begin
          we = exp_wq.pop_front();
          if (we.data !== m_wdata) fail("E1", "write data mismatch");
          if (we.strb !== m_wstrb) fail("E1", "write strb mismatch");
          if (we.last !== m_wlast) fail("B3", "write last mismatch / interleaving");
        end
      end

      // slave read response: per-sid FIFO (B1), C1/C2, E1
      if (s_rvalid && s_rready) begin
        if (exp_r_sid[s_rid].size() == 0) begin
          if (post_rst_cnt > 0)
            fail("F1", "read response for transaction discarded by reset");
          else
            fail("C2", "slave read beat with no outstanding transaction");
        end else begin
          re = exp_r_sid[s_rid].pop_front();
          if (re.data !== s_rdata) fail("E1", "read data mismatch (payload/order)");
          if (re.last !== s_rlast) fail("E1", "read last mismatch");
          if (s_rresp !== 2'b00) fail("E1", "read resp not forwarded");
        end
      end

      // slave write response
      if (s_bvalid && s_bready) begin
        if (exp_b_cnt[s_bid] == 0) begin
          if (post_rst_cnt > 0)
            fail("F1", "write response for transaction discarded by reset");
          else
            fail("C2", "slave write response with no outstanding transaction");
        end else begin
          exp_b_cnt[s_bid] = exp_b_cnt[s_bid] - 1;
          if (s_bresp !== 2'b00) fail("E1", "write resp not forwarded");
        end
      end
    end
  end

  // ---------------------------------------------------------------------------
  // Main stimulus sequence
  // ---------------------------------------------------------------------------
  initial begin
    s_awid = 0; s_awaddr = 0; s_awlen = 0; s_awvalid = 0;
    s_wdata = 0; s_wstrb = 0; s_wlast = 0; s_wvalid = 0;
    s_arid = 0; s_araddr = 0; s_arlen = 0; s_arvalid = 0;
    s_bready = 1'b1; s_rready = 1'b1;
    m_arready = 1'b1; m_awready = 1'b1; m_wready = 1'b1;
    m_rready = 1'b1; m_bready = 1'b1;
    m_rid = 0; m_rdata = 0; m_rresp = 0; m_rlast = 0; m_rvalid = 0;
    m_bid = 0; m_bresp = 0; m_bvalid = 0;

    bfm_reset(4);
    settle(2);

    // -------- Phase 1: basic one-in-one-out forwarding --------
    a = gen_addr(); bfm_ar(4'd1, a, 8'd1, 20, acc, wt);
    chk_acc(acc, "A3", "fresh read id not accepted on empty table");
    a = gen_addr(); bfm_aw(4'd2, a, 8'd0, 20, acc, wt);
    chk_acc(acc, "A3", "fresh write id not accepted on empty table");
    do_w(a, 8'd0);
    wait_rd(1); respond_read(0);
    wait_wr(1); respond_write(0);
    quiesce();

    // -------- Phase 2: read-side A3 / A5 / A4 --------
    a = gen_addr(); bfm_ar(4'd1, a, 8'd0, 20, acc, wt);
    chk_acc(acc, "A3", "read id1 not accepted");
    a = gen_addr(); bfm_ar(4'd2, a, 8'd0, 20, acc, wt);
    chk_acc(acc, "A3", "read id2 not accepted");
    a = gen_addr(); bfm_ar(4'd3, a, 8'd2, 20, acc, wt);   // multi-beat
    chk_acc(acc, "A3", "read id3 not accepted");
    a = gen_addr(); bfm_ar(4'd4, a, 8'd0, 20, acc, wt);   // MAX-1 -> must accept
    chk_acc(acc, "A3", "4th distinct read id not accepted at boundary");
    a = gen_addr(); bfm_ar(4'd5, a, 8'd0, 6, acc, wt);     // MAX -> must refuse
    if (acc) fail("A3", "5th distinct read id accepted");
    a = gen_addr(); bfm_ar(4'd1, a, 8'd0, 20, acc, wt);    // same id, table full
    chk_acc(acc, "A3", "already-outstanding read id1 refused while table full");
    a = gen_addr(); bfm_ar(4'd1, a, 8'd0, 6, acc, wt);     // 3rd for id1 -> refuse
    if (acc) fail("A5", "3rd read txn for id1 accepted");
    a = gen_addr(); bfm_ar(4'd2, a, 8'd0, 20, acc, wt);    // 2nd for id2 -> accept
    chk_acc(acc, "A5", "2nd read txn for id2 refused");
    a = gen_addr(); bfm_ar(4'd2, a, 8'd0, 6, acc, wt);     // 3rd -> refuse
    if (acc) fail("A5", "3rd read txn for id2 accepted");

    // retire id4 completely; its table entry must free (A4)
    wait_rd(1);
    respond_read(find_rd(4'd4));
    wait_sid_r_empty(4);
    a = gen_addr();
    s_arid = 4'd5; s_araddr = a; s_arlen = 8'd0; s_arvalid = 1'b1;
    cyc = 0;
    while (cyc <= 10) begin
      @(posedge clk);
      if (s_arready) break;
      cyc++;
    end
    @(negedge clk) s_arvalid = 1'b0;
    if (cyc > 10) fail("A4", "freed read entry not reused (new id never accepted)");
    else if (cyc > 2) fail("A4", $sformatf("new read id accepted after %0d cycles (window 2)", cyc));

    drain_reads();
    quiesce();

    // -------- Phase 3: write-side A3 / A5 / A4 --------
    a = gen_addr(); bfm_aw(4'd1, a, 8'd0, 20, acc, wt);
    chk_acc(acc, "A3", "write id1 not accepted"); do_w(a, 8'd0);
    a = gen_addr(); bfm_aw(4'd2, a, 8'd0, 20, acc, wt);
    chk_acc(acc, "A3", "write id2 not accepted"); do_w(a, 8'd0);
    a = gen_addr(); bfm_aw(4'd3, a, 8'd1, 20, acc, wt);   // 2-beat write
    chk_acc(acc, "A3", "write id3 not accepted"); do_w(a, 8'd1);
    a = gen_addr(); bfm_aw(4'd4, a, 8'd0, 20, acc, wt);   // MAX-1 -> must accept
    chk_acc(acc, "A3", "4th distinct write id not accepted at boundary"); do_w(a, 8'd0);
    a = gen_addr(); bfm_aw(4'd5, a, 8'd0, 6, acc, wt);    // MAX -> must refuse
    if (acc) fail("A3", "5th distinct write id accepted");
    a = gen_addr(); bfm_aw(4'd1, a, 8'd0, 20, acc, wt);   // 2nd for id1 -> accept
    chk_acc(acc, "A5", "2nd write txn for id1 refused"); do_w(a, 8'd0);
    a = gen_addr(); bfm_aw(4'd1, a, 8'd0, 6, acc, wt);    // 3rd -> refuse
    if (acc) fail("A5", "3rd write txn for id1 accepted");

    // retire id4's write completely; entry must free (A4)
    wait_wr(1);
    respond_write(find_wr(4'd4));
    wait_sid_b_empty(4);
    a = gen_addr();
    s_awid = 4'd5; s_awaddr = a; s_awlen = 8'd0; s_awvalid = 1'b1;
    cyc = 0;
    while (cyc <= 10) begin
      @(posedge clk);
      if (s_awready) break;
      cyc++;
    end
    @(negedge clk) s_awvalid = 1'b0;
    if (cyc > 10) fail("A4", "freed write entry not reused (new id never accepted)");
    else if (cyc > 2) fail("A4", $sformatf("new write id accepted after %0d cycles (window 2)", cyc));
    if (cyc <= 10) do_w(a, 8'd0);

    drain_writes();
    quiesce();

    // -------- Phase 4: reset behaviour (F1) --------
    a = gen_addr(); bfm_ar(4'd3, a, 8'd0, 20, acc, wt);
    chk_acc(acc, "A3", "pre-reset read not accepted");
    a = gen_addr(); bfm_aw(4'd3, a, 8'd0, 20, acc, wt);
    chk_acc(acc, "A3", "pre-reset write not accepted"); do_w(a, 8'd0);
    settle(2);

    // drop reset; deliberately offer requests during reset (ready may be high,
    // handshakes are legal -- they must simply be discarded)
    @(negedge clk);
    rst_n = 1'b0;
    s_arid = 4'd7; s_araddr = gen_addr(); s_arlen = 8'd0; s_arvalid = 1'b1;
    s_awid = 4'd7; s_awaddr = gen_addr(); s_awlen = 8'd0; s_awvalid = 1'b1;
    s_wdata = 32'hDEAD_BEEF; s_wstrb = {STRB_W{1'b1}}; s_wlast = 1'b1; s_wvalid = 1'b1;
    repeat (4) @(negedge clk);
    s_arvalid = 1'b0; s_awvalid = 1'b0; s_wvalid = 1'b0;
    repeat (2) @(negedge clk);
    rst_n = 1'b1;
    settle(8);   // any response for a discarded txn is flagged F1 by the checker

    // table must be empty after release: 4 distinct ids accepted, 5th refused
    a = gen_addr(); bfm_ar(4'd8,  a, 8'd0, 20, acc, wt);
    chk_acc(acc, "A3", "post-reset read id8 not accepted (table must be empty)");
    a = gen_addr(); bfm_ar(4'd9,  a, 8'd0, 20, acc, wt);
    chk_acc(acc, "A3", "post-reset read id9 not accepted");
    a = gen_addr(); bfm_ar(4'd10, a, 8'd0, 20, acc, wt);
    chk_acc(acc, "A3", "post-reset read id10 not accepted");
    a = gen_addr(); bfm_ar(4'd11, a, 8'd0, 20, acc, wt);
    chk_acc(acc, "A3", "post-reset read id11 not accepted");
    a = gen_addr(); bfm_ar(4'd12, a, 8'd0, 6, acc, wt);
    if (acc) fail("A3", "5th distinct post-reset read id accepted");

    wait_rd(1); drain_reads();
    a = gen_addr(); bfm_aw(4'd8, a, 8'd0, 20, acc, wt);
    chk_acc(acc, "A3", "post-reset write id8 not accepted"); do_w(a, 8'd0);
    wait_wr(1); drain_writes();
    quiesce();
    settle(4);

    // -------- verdict --------
    if (errors == 0) $display("RESULT: PASS");
    else             $display("RESULT: FAIL");
    $finish;
  end

endmodule
