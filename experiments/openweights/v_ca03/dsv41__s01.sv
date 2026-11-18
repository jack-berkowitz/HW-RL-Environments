module id_width_conv_tb;

  // ---------------------------------------------------------------------------
  // Parameters
  // ---------------------------------------------------------------------------
  localparam int SLV_ID_W        = 4;
  localparam int MST_ID_W        = 2;
  localparam int ADDR_W          = 32;
  localparam int DATA_W          = 32;
  localparam int MAX_UNIQ_IDS    = 4;
  localparam int MAX_TXNS_PER_ID = 2;
  localparam int N_IDS           = 1 << SLV_ID_W;
  localparam int MST_IDS         = 1 << MST_ID_W;

  // ---------------------------------------------------------------------------
  // Signals
  // ---------------------------------------------------------------------------
  logic [SLV_ID_W-1:0]   s_awid;
  logic [ADDR_W-1:0]     s_awaddr;
  logic [7:0]            s_awlen;
  logic                  s_awvalid;
  logic                  s_awready;

  logic [DATA_W-1:0]     s_wdata;
  logic [DATA_W/8-1:0]   s_wstrb;
  logic                  s_wlast;
  logic                  s_wvalid;
  logic                  s_wready;

  logic [SLV_ID_W-1:0]   s_bid;
  logic [1:0]            s_bresp;
  logic                  s_bvalid;
  logic                  s_bready;

  logic [SLV_ID_W-1:0]   s_arid;
  logic [ADDR_W-1:0]     s_araddr;
  logic [7:0]            s_arlen;
  logic                  s_arvalid;
  logic                  s_arready;

  logic [SLV_ID_W-1:0]   s_rid;
  logic [DATA_W-1:0]     s_rdata;
  logic [1:0]            s_rresp;
  logic                  s_rlast;
  logic                  s_rvalid;
  logic                  s_rready;

  logic [MST_ID_W-1:0]   m_awid;
  logic [ADDR_W-1:0]     m_awaddr;
  logic [7:0]            m_awlen;
  logic                  m_awvalid;
  logic                  m_awready;

  logic [DATA_W-1:0]     m_wdata;
  logic [DATA_W/8-1:0]   m_wstrb;
  logic                  m_wlast;
  logic                  m_wvalid;
  logic                  m_wready;

  logic [MST_ID_W-1:0]   m_bid;
  logic [1:0]            m_bresp;
  logic                  m_bvalid;
  logic                  m_bready;

  logic [MST_ID_W-1:0]   m_arid;
  logic [ADDR_W-1:0]     m_araddr;
  logic [7:0]            m_arlen;
  logic                  m_arvalid;
  logic                  m_arready;

  logic [MST_ID_W-1:0]   m_rid;
  logic [DATA_W-1:0]     m_rdata;
  logic [1:0]            m_rresp;
  logic                  m_rlast;
  logic                  m_rvalid;
  logic                  m_rready;

  // ---------------------------------------------------------------------------
  // PROVIDED PLUMBING -- moves transactions, checks nothing.
  // ---------------------------------------------------------------------------
  logic clk;
  initial begin clk = 1'b0; forever #5 clk = ~clk; end

  logic rst_n;
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
  // DUT
  // ---------------------------------------------------------------------------
  id_width_conv #(
    .SLV_ID_W(SLV_ID_W),
    .MST_ID_W(MST_ID_W),
    .ADDR_W(ADDR_W),
    .DATA_W(DATA_W),
    .MAX_UNIQ_IDS(MAX_UNIQ_IDS),
    .MAX_TXNS_PER_ID(MAX_TXNS_PER_ID)
  ) dut (
    .clk_i(clk),
    .rst_ni(rst_n),
    .s_awid(s_awid),
    .s_awaddr(s_awaddr),
    .s_awlen(s_awlen),
    .s_awvalid(s_awvalid),
    .s_awready(s_awready),
    .s_wdata(s_wdata),
    .s_wstrb(s_wstrb),
    .s_wlast(s_wlast),
    .s_wvalid(s_wvalid),
    .s_wready(s_wready),
    .s_bid(s_bid),
    .s_bresp(s_bresp),
    .s_bvalid(s_bvalid),
    .s_bready(s_bready),
    .s_arid(s_arid),
    .s_araddr(s_araddr),
    .s_arlen(s_arlen),
    .s_arvalid(s_arvalid),
    .s_arready(s_arready),
    .s_rid(s_rid),
    .s_rdata(s_rdata),
    .s_rresp(s_rresp),
    .s_rlast(s_rlast),
    .s_rvalid(s_rvalid),
    .s_rready(s_rready),
    .m_awid(m_awid),
    .m_awaddr(m_awaddr),
    .m_awlen(m_awlen),
    .m_awvalid(m_awvalid),
    .m_awready(m_awready),
    .m_wdata(m_wdata),
    .m_wstrb(m_wstrb),
    .m_wlast(m_wlast),
    .m_wvalid(m_wvalid),
    .m_wready(m_wready),
    .m_bid(m_bid),
    .m_bresp(m_bresp),
    .m_bvalid(m_bvalid),
    .m_bready(m_bready),
    .m_arid(m_arid),
    .m_araddr(m_araddr),
    .m_arlen(m_arlen),
    .m_arvalid(m_arvalid),
    .m_arready(m_arready),
    .m_rid(m_rid),
    .m_rdata(m_rdata),
    .m_rresp(m_rresp),
    .m_rlast(m_rlast),
    .m_rvalid(m_rvalid),
    .m_rready(m_rready)
  );

  // ---------------------------------------------------------------------------
  // Constant ready signals
  // ---------------------------------------------------------------------------
  assign s_bready  = 1'b1;
  assign s_rready  = 1'b1;
  assign m_awready = 1'b1;
  assign m_wready  = 1'b1;
  assign m_arready = 1'b1;

  // ---------------------------------------------------------------------------
  // Model types
  // ---------------------------------------------------------------------------
  typedef struct {
    logic [SLV_ID_W-1:0] sid;
    logic [ADDR_W-1:0]   addr;
    logic [7:0]          len;
    logic [MST_ID_W-1:0] mid;
    bit                  mid_valid;
    bit                  forwarded;
  } txn_t;

  typedef struct {
    logic [DATA_W-1:0]   data;
    logic [DATA_W/8-1:0] strb;
    logic                last;
  } wbeat_t;

  typedef struct {
    logic [DATA_W-1:0] data;
    logic [1:0]        resp;
    logic              last;
  } rbeat_t;

  typedef struct {
    logic [1:0] resp;
  } bbeat_t;

  // ---------------------------------------------------------------------------
  // Model state
  // ---------------------------------------------------------------------------
  txn_t   rd_q  [N_IDS][$];
  txn_t   wr_q  [N_IDS][$];
  rbeat_t exp_r [N_IDS][$];
  bbeat_t exp_b [N_IDS][$];
  wbeat_t exp_w [$];

  int                  mid_cnt [MST_IDS];
  logic [SLV_ID_W-1:0] mid_sid [MST_IDS];

  int fail_count = 0;

  // ---------------------------------------------------------------------------
  // Helper functions
  // ---------------------------------------------------------------------------
  function automatic int rd_distinct();
    int c;
    int i;
    c = 0;
    for (i = 0; i < N_IDS; i++) begin
      if (rd_q[i].size() > 0) c++;
    end
    return c;
  endfunction

  function automatic int wr_distinct();
    int c;
    int i;
    c = 0;
    for (i = 0; i < N_IDS; i++) begin
      if (wr_q[i].size() > 0) c++;
    end
    return c;
  endfunction

  // ---------------------------------------------------------------------------
  // Reporting
  // ---------------------------------------------------------------------------
  task automatic report_fail(input string req, input string msg);
    fail_count++;
    $display("FAIL: %s: %s", req, msg);
  endtask

  // ---------------------------------------------------------------------------
  // Wait helpers
  // ---------------------------------------------------------------------------
  task automatic wait_rd_forwarded(input  logic [SLV_ID_W-1:0] sid,
                                   input  logic [ADDR_W-1:0]   addr,
                                   output logic [MST_ID_W-1:0] mid);
    int idx;
    int i;
    bit found;
    idx = sid;
    found = 0;
    while (!found) begin
      @(negedge clk);
      for (i = 0; i < rd_q[idx].size(); i++) begin
        if (rd_q[idx][i].addr == addr && rd_q[idx][i].forwarded) begin
          mid = rd_q[idx][i].mid;
          found = 1;
          break;
        end
      end
    end
  endtask

  task automatic wait_wr_forwarded(input  logic [SLV_ID_W-1:0] sid,
                                   input  logic [ADDR_W-1:0]   addr,
                                   output logic [MST_ID_W-1:0] mid);
    int idx;
    int i;
    bit found;
    idx = sid;
    found = 0;
    while (!found) begin
      @(negedge clk);
      for (i = 0; i < wr_q[idx].size(); i++) begin
        if (wr_q[idx][i].addr == addr && wr_q[idx][i].forwarded) begin
          mid = wr_q[idx][i].mid;
          found = 1;
          break;
        end
      end
    end
  endtask

  task automatic wait_rd_complete(input logic [SLV_ID_W-1:0] sid,
                                  input logic [ADDR_W-1:0]   addr);
    int idx;
    int i;
    bit found;
    idx = sid;
    found = 1;
    while (found) begin
      @(negedge clk);
      found = 0;
      for (i = 0; i < rd_q[idx].size(); i++) begin
        if (rd_q[idx][i].addr == addr) begin
          found = 1;
          break;
        end
      end
    end
  endtask

  task automatic wait_wr_complete(input logic [SLV_ID_W-1:0] sid,
                                  input logic [ADDR_W-1:0]   addr);
    int idx;
    int i;
    bit found;
    idx = sid;
    found = 1;
    while (found) begin
      @(negedge clk);
      found = 0;
      for (i = 0; i < wr_q[idx].size(); i++) begin
        if (wr_q[idx][i].addr == addr) begin
          found = 1;
          break;
        end
      end
    end
  endtask

  // ---------------------------------------------------------------------------
  // Transaction completion helpers
  // ---------------------------------------------------------------------------
  task automatic complete_read(input logic [SLV_ID_W-1:0] sid,
                               input logic [ADDR_W-1:0]   addr,
                               input logic [DATA_W-1:0]   data);
    logic [MST_ID_W-1:0] mid;
    rbeat_t e;
    int idx;
    idx = sid;
    wait_rd_forwarded(sid, addr, mid);
    e.data = data;
    e.resp = 2'b00;
    e.last = 1'b1;
    exp_r[idx].push_back(e);
    bfm_rbeat(mid, data, 1'b1);
    wait_rd_complete(sid, addr);
  endtask

  task automatic complete_write(input logic [SLV_ID_W-1:0] sid,
                                input logic [ADDR_W-1:0]   addr);
    logic [MST_ID_W-1:0] mid;
    bbeat_t e;
    int idx;
    idx = sid;
    wait_wr_forwarded(sid, addr, mid);
    e.resp = 2'b00;
    exp_b[idx].push_back(e);
    bfm_bbeat(mid);
    wait_wr_complete(sid, addr);
  endtask

  task automatic send_w(input logic [DATA_W-1:0]   data,
                        input logic [DATA_W/8-1:0] strb,
                        input logic                last);
    wbeat_t e;
    e.data = data;
    e.strb = strb;
    e.last = last;
    exp_w.push_back(e);
    bfm_w(data, strb, last);
  endtask

  // ---------------------------------------------------------------------------
  // Address handshake helpers
  // ---------------------------------------------------------------------------
  task automatic do_ar_accept(input logic [SLV_ID_W-1:0] id,
                              input logic [ADDR_W-1:0]   addr,
                              input int                  budget);
    bit acc;
    int wait;
    bfm_ar(id, addr, 8'd0, budget, acc, wait);
    if (!acc) report_fail("A3", "expected AR accepted but refused");
  endtask

  task automatic do_ar_refuse(input logic [SLV_ID_W-1:0] id,
                              input logic [ADDR_W-1:0]   addr,
                              input int                  budget,
                              input string               req);
    bit acc;
    int wait;
    bfm_ar(id, addr, 8'd0, budget, acc, wait);
    if (acc) report_fail(req, "expected AR refused but accepted");
  endtask

  task automatic do_ar_accept_a4(input logic [SLV_ID_W-1:0] id,
                                 input logic [ADDR_W-1:0]   addr);
    bit acc;
    int wait;
    bfm_ar(id, addr, 8'd0, 4, acc, wait);
    if (!acc) report_fail("A4", "expected AR accepted after retirement but refused");
    else if (wait > 1) report_fail("A4", "AR accepted too late after retirement");
  endtask

  task automatic do_aw_accept(input logic [SLV_ID_W-1:0] id,
                              input logic [ADDR_W-1:0]   addr,
                              input int                  budget);
    bit acc;
    int wait;
    bfm_aw(id, addr, 8'd0, budget, acc, wait);
    if (!acc) report_fail("A3", "expected AW accepted but refused");
  endtask

  task automatic do_aw_refuse(input logic [SLV_ID_W-1:0] id,
                              input logic [ADDR_W-1:0]   addr,
                              input int                  budget,
                              input string               req);
    bit acc;
    int wait;
    bfm_aw(id, addr, 8'd0, budget, acc, wait);
    if (acc) report_fail(req, "expected AW refused but accepted");
  endtask

  task automatic do_aw_accept_a4(input logic [SLV_ID_W-1:0] id,
                                 input logic [ADDR_W-1:0]   addr);
    bit acc;
    int wait;
    bfm_aw(id, addr, 8'd0, 4, acc, wait);
    if (!acc) report_fail("A4", "expected AW accepted after retirement but refused");
    else if (wait > 1) report_fail("A4", "AW accepted too late after retirement");
  endtask

  // ---------------------------------------------------------------------------
  // Checker
  // ---------------------------------------------------------------------------
  always @(posedge clk) begin
    int i, j;
    int sid_idx;
    int mid_idx;
    bit found;
    txn_t t;
    wbeat_t we;
    rbeat_t re;
    bbeat_t be;

    if (!rst_n) begin
      // F1: no response presented while reset is low
      if (s_bvalid) report_fail("F1", "s_bvalid high during reset");
      if (s_rvalid) report_fail("F1", "s_rvalid high during reset");

      // Reset model
      for (i = 0; i < N_IDS; i++) begin
        rd_q[i].delete();
        wr_q[i].delete();
        exp_r[i].delete();
        exp_b[i].delete();
      end
      exp_w.delete();
      for (i = 0; i < MST_IDS; i++) begin
        mid_cnt[i] = 0;
        mid_sid[i] = '0;
      end
    end else begin
      // -----------------------------------------------------------------------
      // Slave AR handshake
      // -----------------------------------------------------------------------
      if (s_arvalid && s_arready) begin
        sid_idx = s_arid;
        if (rd_q[sid_idx].size() >= MAX_TXNS_PER_ID) begin
          report_fail("A5", "accepted AR when per-ID depth full");
        end
        if (rd_q[sid_idx].size() == 0 && rd_distinct() >= MAX_UNIQ_IDS) begin
          report_fail("A3", "accepted new AR when table full");
        end
        t.sid = s_arid;
        t.addr = s_araddr;
        t.len = s_arlen;
        t.mid = '0;
        t.mid_valid = 0;
        t.forwarded = 0;
        rd_q[sid_idx].push_back(t);
      end

      // -----------------------------------------------------------------------
      // Slave AW handshake
      // -----------------------------------------------------------------------
      if (s_awvalid && s_awready) begin
        sid_idx = s_awid;
        if (wr_q[sid_idx].size() >= MAX_TXNS_PER_ID) begin
          report_fail("A5", "accepted AW when per-ID depth full");
        end
        if (wr_q[sid_idx].size() == 0 && wr_distinct() >= MAX_UNIQ_IDS) begin
          report_fail("A3", "accepted new AW when table full");
        end
        t.sid = s_awid;
        t.addr = s_awaddr;
        t.len = s_awlen;
        t.mid = '0;
        t.mid_valid = 0;
        t.forwarded = 0;
        wr_q[sid_idx].push_back(t);
      end

      // -----------------------------------------------------------------------
      // Master AR handshake
      // -----------------------------------------------------------------------
      if (m_arvalid && m_arready) begin
        found = 0;
        for (i = 0; i < N_IDS; i++) begin
          for (j = 0; j < rd_q[i].size(); j++) begin
            if (!rd_q[i][j].forwarded &&
                rd_q[i][j].addr == m_araddr &&
                rd_q[i][j].len  == m_arlen) begin
              mid_idx = m_arid;
              if (mid_cnt[mid_idx] > 0 && mid_sid[mid_idx] != rd_q[i][j].sid) begin
                report_fail("D1/D2", "master ID reused for different slave ID while outstanding");
              end
              rd_q[i][j].mid       = m_arid;
              rd_q[i][j].mid_valid = 1;
              rd_q[i][j].forwarded = 1;
              mid_cnt[mid_idx]++;
              mid_sid[mid_idx] = rd_q[i][j].sid;
              found = 1;
              break;
            end
          end
          if (found) break;
        end
        if (!found) report_fail("D4/E1", "master AR has no matching slave AR");
      end

      // -----------------------------------------------------------------------
      // Master AW handshake
      // -----------------------------------------------------------------------
      if (m_awvalid && m_awready) begin
        found = 0;
        for (i = 0; i < N_IDS; i++) begin
          for (j = 0; j < wr_q[i].size(); j++) begin
            if (!wr_q[i][j].forwarded &&
                wr_q[i][j].addr == m_awaddr &&
                wr_q[i][j].len  == m_awlen) begin
              mid_idx = m_awid;
              if (mid_cnt[mid_idx] > 0 && mid_sid[mid_idx] != wr_q[i][j].sid) begin
                report_fail("D1/D2", "master ID reused for different slave ID while outstanding");
              end
              wr_q[i][j].mid       = m_awid;
              wr_q[i][j].mid_valid = 1;
              wr_q[i][j].forwarded = 1;
              mid_cnt[mid_idx]++;
              mid_sid[mid_idx] = wr_q[i][j].sid;
              found = 1;
              break;
            end
          end
          if (found) break;
        end
        if (!found) report_fail("D4/E1", "master AW has no matching slave AW");
      end

      // -----------------------------------------------------------------------
      // Master W handshake
      // -----------------------------------------------------------------------
      if (m_wvalid && m_wready) begin
        if (exp_w.size() == 0) begin
          report_fail("B3/E1", "unexpected W beat");
        end else begin
          we = exp_w.pop_front();
          if (m_wdata !== we.data || m_wstrb !== we.strb || m_wlast !== we.last) begin
            report_fail("E1", "W beat payload mismatch");
          end
        end
      end

      // -----------------------------------------------------------------------
      // Slave R response
      // -----------------------------------------------------------------------
      if (s_rvalid && s_rready) begin
        sid_idx = s_rid;
        if (exp_r[sid_idx].size() == 0) begin
          report_fail("C2", "unexpected R response");
        end else begin
          re = exp_r[sid_idx].pop_front();
          if (s_rdata !== re.data || s_rresp !== re.resp || s_rlast !== re.last) begin
            report_fail("E1", "R beat payload mismatch");
          end
          if (s_rlast) begin
            if (rd_q[sid_idx].size() == 0) begin
              report_fail("C2", "R completion with no outstanding txn");
            end else begin
              t = rd_q[sid_idx].pop_front();
              if (t.mid_valid) begin
                mid_cnt[t.mid]--;
                if (mid_cnt[t.mid] == 0) mid_sid[t.mid] = '0;
              end
            end
          end
        end
      end

      // -----------------------------------------------------------------------
      // Slave B response
      // -----------------------------------------------------------------------
      if (s_bvalid && s_bready) begin
        sid_idx = s_bid;
        if (exp_b[sid_idx].size() == 0) begin
          report_fail("C2", "unexpected B response");
        end else begin
          be = exp_b[sid_idx].pop_front();
          if (s_bresp !== be.resp) begin
            report_fail("E1", "B response mismatch");
          end
          if (wr_q[sid_idx].size() == 0) begin
            report_fail("C2", "B completion with no outstanding txn");
          end else begin
            t = wr_q[sid_idx].pop_front();
            if (t.mid_valid) begin
              mid_cnt[t.mid]--;
              if (mid_cnt[t.mid] == 0) mid_sid[t.mid] = '0;
            end
          end
        end
      end
    end
  end

  // ---------------------------------------------------------------------------
  // Stimulus
  // ---------------------------------------------------------------------------
  initial begin
    int i;

    // Initial signal values
    s_awvalid = 0; s_wvalid = 0; s_arvalid = 0; m_bvalid = 0; m_rvalid = 0;
    s_awid = 0; s_awaddr = 0; s_awlen = 0; s_wdata = 0; s_wstrb = 0; s_wlast = 0;
    s_arid = 0; s_araddr = 0; s_arlen = 0;
    m_bid = 0; m_bresp = 0; m_rid = 0; m_rdata = 0; m_rresp = 0; m_rlast = 0;

    // Initialise model
    for (i = 0; i < N_IDS; i++) begin
      rd_q[i].delete();
      wr_q[i].delete();
      exp_r[i].delete();
      exp_b[i].delete();
    end
    exp_w.delete();
    for (i = 0; i < MST_IDS; i++) begin
      mid_cnt[i] = 0;
      mid_sid[i] = '0;
    end
    fail_count = 0;

    bfm_reset(4);

    // -----------------------------------------------------------------------
    // Phase 1: basic read and write
    // -----------------------------------------------------------------------
    do_ar_accept(1, 32'h100, 20);
    complete_read(1, 32'h100, 32'hA1);

    do_aw_accept(2, 32'h200, 20);
    send_w(32'hB2, 4'hF, 1'b1);
    complete_write(2, 32'h200);

    // -----------------------------------------------------------------------
    // Phase 2: read table boundary and A4
    // -----------------------------------------------------------------------
    do_ar_accept(0, 32'h1000, 20);
    do_ar_accept(1, 32'h1001, 20);
    do_ar_accept(2, 32'h1002, 20);
    do_ar_accept(3, 32'h1003, 20);

    do_ar_refuse(8, 32'h1008, 10, "A3");

    complete_read(0, 32'h1000, 32'hA0);
    do_ar_accept_a4(8, 32'h1008);

    // -----------------------------------------------------------------------
    // Phase 3: read depth per ID
    // -----------------------------------------------------------------------
    do_ar_accept(1, 32'h1001b, 20);
    do_ar_refuse(1, 32'h1001c, 10, "A5");

    complete_read(1, 32'h1001, 32'hA11);
    do_ar_accept(1, 32'h1001c, 20);
    complete_read(1, 32'h1001b, 32'hA12);
    complete_read(1, 32'h1001c, 32'hA13);

    // -----------------------------------------------------------------------
    // Phase 4: write table boundary and A4
    // -----------------------------------------------------------------------
    do_aw_accept(4, 32'h2000, 20);
    send_w(32'hB4, 4'hF, 1'b1);
    do_aw_accept(5, 32'h2001, 20);
    send_w(32'hB5, 4'hF, 1'b1);
    do_aw_accept(6, 32'h2002, 20);
    send_w(32'hB6, 4'hF, 1'b1);
    do_aw_accept(7, 32'h2003, 20);
    send_w(32'hB7, 4'hF, 1'b1);

    do_aw_refuse(12, 32'h2008, 10, "A3");

    complete_write(4, 32'h2000);
    do_aw_accept_a4(12, 32'h2008);
    send_w(32'hB12, 4'hF, 1'b1);

    // -----------------------------------------------------------------------
    // Phase 5: write depth per ID
    // -----------------------------------------------------------------------
    do_aw_accept(5, 32'h2001b, 20);
    send_w(32'hB5b, 4'hF, 1'b1);
    do_aw_refuse(5, 32'h2001c, 10, "A5");

    complete_write(5, 32'h2001);
    do_aw_accept(5, 32'h2001c, 20);
    send_w(32'hB5c, 4'hF, 1'b1);
    complete_write(5, 32'h2001b);
    complete_write(5, 32'h2001c);

    // -----------------------------------------------------------------------
    // Phase 6: clean up remaining transactions
    // -----------------------------------------------------------------------
    complete_read(2, 32'h1002, 32'hA2);
    complete_read(3, 32'h1003, 32'hA3);
    complete_read(8, 32'h1008, 32'hA8);

    complete_write(6, 32'h2002);
    complete_write(7, 32'h2003);
    complete_write(12, 32'h2008);

    // -----------------------------------------------------------------------
    // Phase 7: reset behaviour (F1)
    // -----------------------------------------------------------------------
    do_ar_accept(9, 32'h3000, 20);
    do_aw_accept(10, 32'h3001, 20);
    send_w(32'hB10, 4'hF, 1'b1);

    @(negedge clk);
    rst_n = 1'b0;
    // Drive some requests during reset (may or may not be accepted)
    s_arvalid = 1; s_arid = 15; s_araddr = 32'hFFFF; s_arlen = 0;
    s_awvalid = 1; s_awid = 15; s_awaddr = 32'hFFFE; s_awlen = 0;
    s_wvalid  = 1; s_wdata = 32'hDEAD; s_wstrb = 4'hF; s_wlast = 1;
    repeat (4) @(posedge clk);
    @(negedge clk);
    rst_n = 1'b1;
    s_arvalid = 0; s_awvalid = 0; s_wvalid = 0;

    // No response should appear for discarded transactions
    for (i = 0; i < 10; i++) begin
      @(posedge clk);
      if (s_bvalid) report_fail("F1", "response after reset for discarded txn");
      if (s_rvalid) report_fail("F1", "response after reset for discarded txn");
    end

    // Verify table is empty after reset by accepting 4 distinct reads
    do_ar_accept(0, 32'h4000, 20);
    do_ar_accept(1, 32'h4001, 20);
    do_ar_accept(2, 32'h4002, 20);
    do_ar_accept(3, 32'h4003, 20);

    // -----------------------------------------------------------------------
    // Final result
    // -----------------------------------------------------------------------
    if (fail_count == 0) $display("RESULT: PASS");
    else                 $display("RESULT: FAIL");
    $finish;
  end

endmodule
