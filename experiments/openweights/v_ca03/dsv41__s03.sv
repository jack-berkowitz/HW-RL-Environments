`timescale 1ns/1ps

module id_width_conv_tb;

  localparam int SLV_ID_W = 4;
  localparam int MST_ID_W = 2;
  localparam int ADDR_W = 32;
  localparam int DATA_W = 32;
  localparam int MAX_UNIQ_IDS = 4;
  localparam int MAX_TXNS_PER_ID = 2;

  logic clk;
  logic rst_n;

  logic [SLV_ID_W-1:0] s_awid, s_arid, s_bid, s_rid;
  logic [ADDR_W-1:0]   s_awaddr, s_araddr;
  logic [7:0]          s_awlen, s_arlen;
  logic                s_awvalid, s_awready;
  logic [DATA_W-1:0]   s_wdata;
  logic [DATA_W/8-1:0] s_wstrb;
  logic                s_wlast, s_wvalid, s_wready;
  logic                s_bvalid, s_bready;
  logic [1:0]          s_bresp;
  logic                s_arvalid, s_arready;
  logic                s_rvalid, s_rready;
  logic [DATA_W-1:0]   s_rdata;
  logic [1:0]          s_rresp;
  logic                s_rlast;

  logic [MST_ID_W-1:0] m_awid, m_arid, m_bid, m_rid;
  logic [ADDR_W-1:0]   m_awaddr, m_araddr;
  logic [7:0]          m_awlen, m_arlen;
  logic                m_awvalid, m_awready;
  logic [DATA_W-1:0]   m_wdata;
  logic [DATA_W/8-1:0] m_wstrb;
  logic                m_wlast, m_wvalid, m_wready;
  logic                m_bvalid, m_bready;
  logic [1:0]          m_bresp;
  logic                m_arvalid, m_arready;
  logic                m_rvalid, m_rready;
  logic [DATA_W-1:0]   m_rdata;
  logic [1:0]          m_rresp;
  logic                m_rlast;

  id_width_conv #(
    .SLV_ID_W(SLV_ID_W), .MST_ID_W(MST_ID_W),
    .ADDR_W(ADDR_W), .DATA_W(DATA_W),
    .MAX_UNIQ_IDS(MAX_UNIQ_IDS), .MAX_TXNS_PER_ID(MAX_TXNS_PER_ID)
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

  // ---------------- Provided plumbing ----------------
  initial begin clk = 1'b0; forever #5 clk = ~clk; end
  initial rst_n = 1'b0;

  task automatic bfm_reset(input int cycles = 4);
    @(negedge clk);
    rst_n = 1'b0;
    repeat (cycles) @(posedge clk);
    @(negedge clk);
    rst_n = 1'b1;
  endtask

  task automatic bfm_ar(input logic [SLV_ID_W-1:0] id, input logic [ADDR_W-1:0] addr,
                        input logic [7:0] len, input int budget,
                        output bit accepted, output int waited);
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

  task automatic bfm_aw(input logic [SLV_ID_W-1:0] id, input logic [ADDR_W-1:0] addr,
                        input logic [7:0] len, input int budget,
                        output bit accepted, output int waited);
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

  task automatic bfm_w(input logic [DATA_W-1:0] data, input logic [DATA_W/8-1:0] strb,
                       input logic last);
    @(negedge clk);
    s_wdata = data; s_wstrb = strb; s_wlast = last; s_wvalid = 1'b1;
    forever begin @(posedge clk); if (s_wready) break; end
    @(negedge clk) s_wvalid = 1'b0;
  endtask

  task automatic bfm_rbeat(input logic [MST_ID_W-1:0] mid, input logic [DATA_W-1:0] data,
                           input logic last);
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

  // ---------------- Ready signals ----------------
  assign m_arready = rst_n;
  assign m_awready = rst_n;
  assign m_wready  = rst_n;
  assign s_rready  = rst_n;
  assign s_bready  = rst_n;

  // ---------------- State ----------------
  int errors = 0;
  task automatic fail(input string req, input string msg);
    errors++;
    $display("FAIL [%s]: %s", req, msg);
  endtask

  typedef struct {
    logic [SLV_ID_W-1:0] sid;
    logic [ADDR_W-1:0]   addr;
    logic [7:0]          len;
    logic [DATA_W-1:0]   rdata;
    logic [MST_ID_W-1:0] mid;
    bit has_mid;
    bit completed;
  } rtxn_t;
  rtxn_t rtxns[$];

  typedef struct {
    logic [SLV_ID_W-1:0] sid;
    logic [ADDR_W-1:0]   addr;
    logic [7:0]          len;
    logic [DATA_W-1:0]   wdata;
    logic [DATA_W/8-1:0] wstrb;
    logic [MST_ID_W-1:0] mid;
    bit has_mid;
    bit completed;
  } wtxn_t;
  wtxn_t wtxns[$];

  typedef struct {
    logic [MST_ID_W-1:0] mid;
    logic [ADDR_W-1:0]   addr;
    logic [7:0]          len;
  } mar_t;
  mar_t mar_q[$];

  typedef struct {
    logic [MST_ID_W-1:0] mid;
    logic [ADDR_W-1:0]   addr;
    logic [7:0]          len;
  } maw_t;
  maw_t maw_q[$];

  typedef struct {
    logic [DATA_W-1:0]   data;
    logic [DATA_W/8-1:0] strb;
    logic                last;
  } mw_t;
  mw_t mw_q[$];

  logic [DATA_W-1:0] exp_wdata[$];

  // ---------------- Checks ----------------

  // Master AR: E1, D1, D2
  always @(posedge clk) begin
    int found;
    if (rst_n && m_arvalid && m_arready) begin
      found = -1;
      for (int i = 0; i < rtxns.size(); i++) begin
        if (rtxns[i].addr == m_araddr && !rtxns[i].has_mid) begin
          found = i;
          break;
        end
      end
      if (found < 0) begin
        fail("E1", "m_ar has no matching slave AR");
      end else begin
        if (rtxns[found].len != m_arlen) fail("E1", "m_arlen mismatch");
        for (int j = 0; j < rtxns.size(); j++) begin
          if (j != found && rtxns[j].has_mid && !rtxns[j].completed &&
              rtxns[j].mid == m_arid && rtxns[j].sid != rtxns[found].sid) begin
            fail("D1", "same mid for different sids (read)");
          end
        end
        rtxns[found].mid = m_arid;
        rtxns[found].has_mid = 1;
      end
      mar_q.push_back('{mid: m_arid, addr: m_araddr, len: m_arlen});
    end
  end

  // Master AW: E1, D1, D2
  always @(posedge clk) begin
    int found;
    if (rst_n && m_awvalid && m_awready) begin
      found = -1;
      for (int i = 0; i < wtxns.size(); i++) begin
        if (wtxns[i].addr == m_awaddr && !wtxns[i].has_mid) begin
          found = i;
          break;
        end
      end
      if (found < 0) begin
        fail("E1", "m_aw has no matching slave AW");
      end else begin
        if (wtxns[found].len != m_awlen) fail("E1", "m_awlen mismatch");
        for (int j = 0; j < wtxns.size(); j++) begin
          if (j != found && wtxns[j].has_mid && !wtxns[j].completed &&
              wtxns[j].mid == m_awid && wtxns[j].sid != wtxns[found].sid) begin
            fail("D1", "same mid for different sids (write)");
          end
        end
        wtxns[found].mid = m_awid;
        wtxns[found].has_mid = 1;
      end
      maw_q.push_back('{mid: m_awid, addr: m_awaddr, len: m_awlen});
    end
  end

  // Master W: E1, B3
  always @(posedge clk) begin
    if (rst_n && m_wvalid && m_wready) begin
      if (exp_wdata.size() > 0) begin
        if (m_wdata != exp_wdata[0]) fail("B3", "m_w out of order or wrong data");
        exp_wdata.pop_front();
      end
      mw_q.push_back('{data: m_wdata, strb: m_wstrb, last: m_wlast});
    end
  end

  // Slave R: C1, C2, B1, E1
  always @(posedge clk) begin
    int found;
    if (rst_n && s_rvalid && s_rready) begin
      found = -1;
      for (int i = 0; i < rtxns.size(); i++) begin
        if (rtxns[i].rdata == s_rdata && !rtxns[i].completed) begin
          found = i;
          break;
        end
      end
      if (found < 0) begin
        fail("C2", "s_r has no matching outstanding txn");
      end else begin
        if (rtxns[found].sid != s_rid) fail("C1", "s_rid mismatch");
        for (int i = 0; i < found; i++) begin
          if (rtxns[i].sid == rtxns[found].sid && !rtxns[i].completed) begin
            fail("B1", "out of order read response for same sid");
            break;
          end
        end
        if (rtxns[found].len == 0 && !s_rlast) fail("E1", "s_rlast should be 1");
        rtxns[found].completed = 1;
      end
    end
  end

  // Slave B: C1, C2, B1
  always @(posedge clk) begin
    int found;
    if (rst_n && s_bvalid && s_bready) begin
      found = -1;
      for (int i = 0; i < wtxns.size(); i++) begin
        if (wtxns[i].sid == s_bid && !wtxns[i].completed) begin
          found = i;
          break;
        end
      end
      if (found < 0) begin
        fail("C2", "s_b has no matching outstanding txn");
      end else begin
        for (int i = 0; i < found; i++) begin
          if (wtxns[i].sid == wtxns[found].sid && !wtxns[i].completed) begin
            fail("B1", "out of order b response for same sid");
            break;
          end
        end
        wtxns[found].completed = 1;
      end
    end
  end

  // Reset: F1
  always @(posedge clk) begin
    if (!rst_n) begin
      if (s_bvalid) fail("F1", "s_bvalid high during reset");
      if (s_rvalid) fail("F1", "s_rvalid high during reset");
    end
  end

  // ---------------- Helpers ----------------
  task automatic wait_mar(input int budget);
    int t;
    t = 0;
    while (mar_q.size() == 0 && t < budget) begin
      @(posedge clk);
      t++;
    end
  endtask

  task automatic wait_maw(input int budget);
    int t;
    t = 0;
    while (maw_q.size() == 0 && t < budget) begin
      @(posedge clk);
      t++;
    end
  endtask

  task automatic wait_mw(input int budget);
    int t;
    t = 0;
    while (mw_q.size() == 0 && t < budget) begin
      @(posedge clk);
      t++;
    end
  endtask

  // ---------------- Test tasks ----------------

  task automatic test_basic_read();
    bit acc;
    int w;
    int t;
    rtxn_t tr;
    mar_t mar;

    bfm_reset();
    rtxns.delete(); mar_q.delete();

    tr.sid = 0; tr.addr = 32'h100; tr.len = 0; tr.rdata = 32'hDEAD;
    tr.has_mid = 0; tr.completed = 0;
    rtxns.push_back(tr);

    bfm_ar(0, 32'h100, 0, 100, acc, w);
    if (!acc) begin
      fail("A3", "basic read not accepted");
      rtxns.delete();
      return;
    end

    wait_mar(100);
    if (mar_q.size() == 0) begin
      fail("D4", "m_ar not seen");
      rtxns.delete();
      return;
    end
    mar = mar_q.pop_front();
    if (mar.addr != 32'h100) fail("E1", "m_araddr mismatch");

    bfm_rbeat(mar.mid, 32'hDEAD, 1);

    t = 0;
    while (!rtxns[0].completed && t < 100) begin
      @(posedge clk);
      t++;
    end
    if (!rtxns[0].completed) fail("A1", "read did not complete");
  endtask

  task automatic test_basic_write();
    bit acc;
    int w;
    int t;
    wtxn_t tw;
    maw_t maw;
    mw_t mw;

    bfm_reset();
    wtxns.delete(); maw_q.delete(); mw_q.delete(); exp_wdata.delete();

    tw.sid = 0; tw.addr = 32'h200; tw.len = 0; tw.wdata = 32'hBEEF;
    tw.wstrb = 4'hF; tw.has_mid = 0; tw.completed = 0;
    wtxns.push_back(tw);
    exp_wdata.push_back(32'hBEEF);

    bfm_aw(0, 32'h200, 0, 100, acc, w);
    if (!acc) begin
      fail("A3", "basic write not accepted");
      wtxns.delete();
      return;
    end

    bfm_w(32'hBEEF, 4'hF, 1);

    wait_maw(100);
    if (maw_q.size() == 0) begin
      fail("D4", "m_aw not seen");
      return;
    end
    maw = maw_q.pop_front();
    if (maw.addr != 32'h200) fail("E1", "m_awaddr mismatch");

    wait_mw(100);
    if (mw_q.size() == 0) begin
      fail("D4", "m_w not seen");
      return;
    end
    mw = mw_q.pop_front();
    if (mw.data != 32'hBEEF) fail("E1", "m_wdata mismatch");
    if (mw.strb != 4'hF) fail("E1", "m_wstrb mismatch");
    if (!mw.last) fail("E1", "m_wlast mismatch");

    bfm_bbeat(maw.mid);

    t = 0;
    while (!wtxns[0].completed && t < 100) begin
      @(posedge clk);
      t++;
    end
    if (!wtxns[0].completed) fail("A1", "write did not complete");
  endtask

  // A3: at MAX_UNIQ_IDS distinct IDs, a new one is blocked
  task automatic test_a3_boundary();
    bit acc;
    int w;
    int t;
    int found;
    rtxn_t tr;
    mar_t mar;

    bfm_reset();
    rtxns.delete(); mar_q.delete();

    for (int i = 0; i < 4; i++) begin
      tr.sid = i[3:0]; tr.addr = 32'h1000 + i*32'h100; tr.len = 0;
      tr.rdata = 32'hA000 + i; tr.has_mid = 0; tr.completed = 0;
      rtxns.push_back(tr);
      bfm_ar(i[3:0], 32'h1000 + i*32'h100, 0, 100, acc, w);
      if (!acc) fail("A3", $sformatf("ID %0d not accepted", i));
    end

    bfm_ar(4, 32'h5000, 0, 10, acc, w);
    if (acc) fail("A3", "5th ID accepted while 4 outstanding");

    for (int k = 0; k < 4; k++) begin
      wait_mar(100);
      if (mar_q.size() == 0) begin
        fail("D4", "missing m_ar");
        break;
      end
      mar = mar_q.pop_front();
      found = -1;
      for (int i = 0; i < rtxns.size(); i++) begin
        if (rtxns[i].addr == mar.addr && !rtxns[i].completed) begin
          found = i;
          break;
        end
      end
      if (found >= 0) bfm_rbeat(mar.mid, rtxns[found].rdata, 1);
    end

    t = 0;
    while (t < 100) begin
      bit all_done;
      all_done = 1;
      for (int i = 0; i < rtxns.size(); i++) if (!rtxns[i].completed) all_done = 0;
      if (all_done) break;
      @(posedge clk);
      t++;
    end
  endtask

  // A4: retirement frees an entry within 2 cycles
  task automatic test_a4_retirement();
    bit acc;
    int w;
    int t;
    int cycles_after;
    bit txn_done;
    rtxn_t tr;
    mar_t mar;

    bfm_reset();
    rtxns.delete(); mar_q.delete();

    for (int i = 0; i < 4; i++) begin
      tr.sid = i[3:0]; tr.addr = 32'h1000 + i*32'h100; tr.len = 0;
      tr.rdata = 32'hA000 + i; tr.has_mid = 0; tr.completed = 0;
      rtxns.push_back(tr);
      bfm_ar(i[3:0], 32'h1000 + i*32'h100, 0, 100, acc, w);
      if (!acc) fail("A3", $sformatf("ID %0d not accepted", i));
    end

    // Drive 5th ID manually, hold valid
    @(negedge clk);
    s_arid = 4; s_araddr = 32'h5000; s_arlen = 0; s_arvalid = 1;

    repeat (5) @(posedge clk);
    if (s_arready) fail("A3", "5th ID accepted while 4 outstanding");

    wait_mar(100);
    if (mar_q.size() == 0) begin
      fail("D4", "missing m_ar");
      @(negedge clk) s_arvalid = 0;
      return;
    end
    mar = mar_q.pop_front();
    bfm_rbeat(mar.mid, rtxns[0].rdata, 1);

    cycles_after = 0;
    txn_done = 0;
    t = 0;
    while (t < 20) begin
      @(negedge clk);
      if (rtxns[0].completed) txn_done = 1;
      if (txn_done) cycles_after++;
      if (s_arready) break;
      t++;
    end
    if (!s_arready) fail("A4", "5th ID not accepted after retirement");
    else if (cycles_after > 3) fail("A4", $sformatf("accepted %0d cycles after retirement", cycles_after));

    @(negedge clk) s_arvalid = 0;
  endtask

  // A5: MAX_TXNS_PER_ID depth per ID
  task automatic test_a5_depth();
    bit acc;
    int w;
    int t;
    rtxn_t tr;
    mar_t mar;

    bfm_reset();
    rtxns.delete(); mar_q.delete();

    tr.sid = 0; tr.addr = 32'h100; tr.len = 0; tr.rdata = 32'hA000;
    tr.has_mid = 0; tr.completed = 0;
    rtxns.push_back(tr);
    bfm_ar(0, 32'h100, 0, 100, acc, w);
    if (!acc) fail("A5", "first same-ID read not accepted");

    tr.sid = 0; tr.addr = 32'h200; tr.len = 0; tr.rdata = 32'hB000;
    tr.has_mid = 0; tr.completed = 0;
    rtxns.push_back(tr);
    bfm_ar(0, 32'h200, 0, 100, acc, w);
    if (!acc) fail("A5", "second same-ID read not accepted");

    bfm_ar(0, 32'h300, 0, 10, acc, w);
    if (acc) fail("A5", "third same-ID read accepted while 2 outstanding");

    wait_mar(100);
    if (mar_q.size() == 0) begin
      fail("D4", "missing m_ar");
      return;
    end
    mar = mar_q.pop_front();
    bfm_rbeat(mar.mid, rtxns[0].rdata, 1);

    t = 0;
    while (!rtxns[0].completed && t < 100) begin
      @(posedge clk);
      t++;
    end

    bfm_ar(0, 32'h300, 0, 10, acc, w);
    if (!acc) fail("A5", "third same-ID read not accepted after retirement");
  endtask

  // B1: per-ID ordering
  task automatic test_b1_ordering();
    bit acc;
    int w;
    int t;
    rtxn_t tr;
    mar_t mar1, mar2;

    bfm_reset();
    rtxns.delete(); mar_q.delete();

    tr.sid = 0; tr.addr = 32'h100; tr.len = 0; tr.rdata = 32'hA000;
    tr.has_mid = 0; tr.completed = 0;
    rtxns.push_back(tr);
    bfm_ar(0, 32'h100, 0, 100, acc, w);
    if (!acc) fail("A5", "first read not accepted");

    tr.sid = 0; tr.addr = 32'h200; tr.len = 0; tr.rdata = 32'hB000;
    tr.has_mid = 0; tr.completed = 0;
    rtxns.push_back(tr);
    bfm_ar(0, 32'h200, 0, 100, acc, w);
    if (!acc) fail("A5", "second read not accepted");

    t = 0;
    while (mar_q.size() < 2 && t < 100) begin
      @(posedge clk);
      t++;
    end
    if (mar_q.size() < 2) begin
      fail("D4", "not all m_ar seen");
      return;
    end
    mar1 = mar_q.pop_front();
    mar2 = mar_q.pop_front();

    if (mar1.mid == mar2.mid) begin
      bfm_rbeat(mar1.mid, 32'hA000, 1);
      bfm_rbeat(mar2.mid, 32'hB000, 1);
    end else begin
      bfm_rbeat(mar2.mid, 32'hB000, 1);
      bfm_rbeat(mar1.mid, 32'hA000, 1);
    end

    t = 0;
    while (t < 100) begin
      bit done;
      done = rtxns[0].completed && rtxns[1].completed;
      if (done) break;
      @(posedge clk);
      t++;
    end
    if (!rtxns[0].completed) fail("A1", "read 0 did not complete");
    if (!rtxns[1].completed) fail("A1", "read 1 did not complete");
  endtask

  // B3: write data ordering
  task automatic test_b3_ordering();
    bit acc;
    int w;
    int t;
    wtxn_t tw;
    maw_t maw;
    mw_t mw;

    bfm_reset();
    wtxns.delete(); maw_q.delete(); mw_q.delete(); exp_wdata.delete();

    tw.sid = 0; tw.addr = 32'h100; tw.len = 0; tw.wdata = 32'hA000;
    tw.wstrb = 4'hF; tw.has_mid = 0; tw.completed = 0;
    wtxns.push_back(tw);
    exp_wdata.push_back(32'hA000);
    bfm_aw(0, 32'h100, 0, 100, acc, w);
    if (!acc) fail("A3", "AW1 not accepted");

    tw.sid = 1; tw.addr = 32'h200; tw.len = 0; tw.wdata = 32'hB000;
    tw.wstrb = 4'hF; tw.has_mid = 0; tw.completed = 0;
    wtxns.push_back(tw);
    exp_wdata.push_back(32'hB000);
    bfm_aw(1, 32'h200, 0, 100, acc, w);
    if (!acc) fail("A3", "AW2 not accepted");

    bfm_w(32'hA000, 4'hF, 1);
    bfm_w(32'hB000, 4'hF, 1);

    t = 0;
    while (mw_q.size() < 2 && t < 100) begin
      @(posedge clk);
      t++;
    end
    if (mw_q.size() < 2) begin
      fail("D4", "not all m_w seen");
      return;
    end
    mw = mw_q.pop_front();
    if (mw.data != 32'hA000) fail("B3", "first m_w data mismatch");
    mw = mw_q.pop_front();
    if (mw.data != 32'hB000) fail("B3", "second m_w data mismatch");

    for (int k = 0; k < 2; k++) begin
      wait_maw(100);
      if (maw_q.size() > 0) begin
        maw = maw_q.pop_front();
        bfm_bbeat(maw.mid);
      end
    end

    t = 0;
    while (t < 100) begin
      bit done;
      done = wtxns[0].completed && wtxns[1].completed;
      if (done) break;
      @(posedge clk);
      t++;
    end
  endtask

  // F1: reset behavior
  task automatic test_reset();
    bit acc;
    int w;
    int t;
    int found;
    rtxn_t tr;
    mar_t mar;

    bfm_reset();
    rtxns.delete(); mar_q.delete();

    tr.sid = 0; tr.addr = 32'h100; tr.len = 0; tr.rdata = 32'hA000;
    tr.has_mid = 0; tr.completed = 0;
    rtxns.push_back(tr);
    bfm_ar(0, 32'h100, 0, 100, acc, w);
    if (!acc) fail("A3", "read 0 not accepted");

    tr.sid = 1; tr.addr = 32'h200; tr.len = 0; tr.rdata = 32'hB000;
    tr.has_mid = 0; tr.completed = 0;
    rtxns.push_back(tr);
    bfm_ar(1, 32'h200, 0, 100, acc, w);
    if (!acc) fail("A3", "read 1 not accepted");

    bfm_reset();
    rtxns.delete(); mar_q.delete();

    repeat (3) @(posedge clk);
    if (m_arvalid) fail("F1", "m_arvalid high after reset");

    for (int i = 0; i < 4; i++) begin
      tr.sid = i[3:0]; tr.addr = 32'h1000 + i*32'h100; tr.len = 0;
      tr.rdata = 32'hC000 + i; tr.has_mid = 0; tr.completed = 0;
      rtxns.push_back(tr);
      bfm_ar(i[3:0], 32'h1000 + i*32'h100, 0, 100, acc, w);
      if (!acc) fail("A3", $sformatf("post-reset ID %0d not accepted", i));
    end

    for (int k = 0; k < 4; k++) begin
      wait_mar(100);
      if (mar_q.size() > 0) begin
        mar = mar_q.pop_front();
        found = -1;
        for (int i = 0; i < rtxns.size(); i++) begin
          if (rtxns[i].addr == mar.addr && !rtxns[i].completed) begin
            found = i;
            break;
          end
        end
        if (found >= 0) bfm_rbeat(mar.mid, rtxns[found].rdata, 1);
      end
    end
  endtask

  // ---------------- Main ----------------
  initial begin
    bfm_reset();

    test_basic_read();
    test_basic_write();
    test_a3_boundary();
    test_a4_retirement();
    test_a5_depth();
    test_b1_ordering();
    test_b3_ordering();
    test_reset();

    if (errors == 0) $display("RESULT: PASS");
    else $display("RESULT: FAIL");
    $finish;
  end

endmodule
