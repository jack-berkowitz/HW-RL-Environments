// ---------------------------------------------------------------------------
// id_width_conv_tb -- self-checking testbench for the ID-width converter.
// Maintains a model of the outstanding-transaction table per direction and
// checks A1..A5, B1..B3, C1/C2, D1..D4, E1, F1 as described in the spec.
// ---------------------------------------------------------------------------
module id_width_conv_tb;

  localparam int unsigned SLV_ID_W        = 4;
  localparam int unsigned MST_ID_W        = 2;
  localparam int unsigned ADDR_W          = 32;
  localparam int unsigned DATA_W          = 32;
  localparam int unsigned MAX_UNIQ_IDS    = 4;
  localparam int unsigned MAX_TXNS_PER_ID = 2;
  localparam int          MAXTAG          = 512;

  // ---------------- DUT wiring ----------------
  logic clk;
  logic rst_n;

  logic [SLV_ID_W-1:0]  s_awid, s_arid, s_bid, s_rid;
  logic [ADDR_W-1:0]    s_awaddr, s_araddr;
  logic [7:0]           s_awlen, s_arlen;
  logic                 s_awvalid, s_awready;
  logic [DATA_W-1:0]    s_wdata, s_rdata;
  logic [DATA_W/8-1:0]  s_wstrb;
  logic                 s_wlast, s_wvalid, s_wready;
  logic [1:0]           s_bresp, s_rresp;
  logic                 s_bvalid, s_bready, s_rvalid, s_rready, s_rlast;
  logic [MST_ID_W-1:0]  m_awid, m_arid, m_bid, m_rid;
  logic [ADDR_W-1:0]    m_awaddr, m_araddr;
  logic [7:0]           m_awlen, m_arlen;
  logic                 m_awvalid, m_awready;
  logic [DATA_W-1:0]    m_wdata, m_rdata;
  logic [DATA_W/8-1:0]  m_wstrb;
  logic                 m_wlast, m_wvalid, m_wready;
  logic [1:0]           m_bresp, m_rresp;
  logic                 m_bvalid, m_bready;
  logic                 m_arvalid, m_arready;
  logic                 m_rvalid, m_rready, m_rlast;

  id_width_conv #(
    .SLV_ID_W        (SLV_ID_W),
    .MST_ID_W        (MST_ID_W),
    .ADDR_W          (ADDR_W),
    .DATA_W          (DATA_W),
    .MAX_UNIQ_IDS    (MAX_UNIQ_IDS),
    .MAX_TXNS_PER_ID (MAX_TXNS_PER_ID)
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
  // TB state / model of the table
  // ---------------------------------------------------------------------------
  int errors = 0;
  int tag_ctr = 0;
  int addr_ctr = 1;
  int wdata_ctr = 1;
  int rdata_ctr = 1;
  bit r_gate = 1'b1;     // read-response gate (TB-internal pacing only)
  bit w_gate = 1'b1;
  bit r_busy = 1'b0;
  bit w_busy = 1'b0;
  bit stray_ok = 1'b0;   // after mid-run reset: ignore stray master handshakes
  int last_r_tag = -1;
  int last_w_tag = -1;
  int cur_w_tag  = -1;
  int w_bcur_tag = -1;

  // per-transaction bookkeeping (identified by tag, never by value)
  int                 t_slv    [0:MAXTAG-1];
  int                 t_dir    [0:MAXTAG-1];   // 0 = read, 1 = write
  logic [ADDR_W-1:0]  t_addr   [0:MAXTAG-1];
  logic [7:0]         t_len    [0:MAXTAG-1];
  int                 t_mid    [0:MAXTAG-1];
  bit                 t_issued [0:MAXTAG-1];
  bit                 t_act    [0:MAXTAG-1];
  bit                 t_wmdone [0:MAXTAG-1];
  logic [1:0]         t_bresp  [0:MAXTAG-1];

  // outstanding counts per slave id (A1/A2/A5)
  int r_cnt [0:15];
  int w_cnt [0:15];

  // tags awaiting master address issue, per slave id (B1 ordering)
  int r_slvq     [0:15][0:63];
  int r_slvq_h   [0:15];
  int r_slvq_t   [0:15];
  int w_slvq     [0:15][0:63];
  int w_slvq_h   [0:15];
  int w_slvq_t   [0:15];

  // read: master-AR issue order + per-mid active txn queues
  int r_mst   [0:MAXTAG-1];
  int r_mst_h = 0;
  int r_mst_t = 0;
  int r_midq   [0:3][0:63];
  int r_midq_h [0:3];
  int r_midq_t [0:3];

  // expected slave read beats, per slave id (C1/C2/E1/B1)
  logic [DATA_W-1:0]   rbe_data [0:15][0:255];
  logic [1:0]         rbe_resp [0:15][0:255];
  logic               rbe_last [0:15][0:255];
  int                 rbe_tag  [0:15][0:255];
  int rbe_h [0:15];
  int rbe_t [0:15];

  // expected master W beats, global FIFO (B3/E1)
  logic [DATA_W-1:0]     we_data [0:4095];
  logic [DATA_W/8-1:0]   we_strb [0:4095];
  logic                 we_last [0:4095];
  int we_h = 0;
  int we_t = 0;
  int w_dorder   [0:MAXTAG-1];   // tags in slave-W-last order
  int w_dorder_h = 0;
  int w_dorder_t = 0;

  // write: accept order for B responses + expected B per slave id
  int w_resp   [0:MAXTAG-1];
  int w_resp_h = 0;
  int w_resp_t = 0;
  int wbe_tag [0:15][0:63];
  int wbe_h   [0:15];
  int wbe_t   [0:15];

  // master-id ownership (D1/D2)
  int r_own    [0:3];
  int r_owncnt [0:3];
  int w_own    [0:3];
  int w_owncnt [0:3];

  task automatic fail(input string req, input string msg);
    begin
      errors = errors + 1;
      $display("FAIL: %s: %s (time %0t)", req, msg, $time);
    end
  endtask

  task automatic model_clear();
    int i;
    begin
      for (i = 0; i < MAXTAG; i = i + 1) begin
        t_act[i]    = 1'b0;
        t_issued[i] = 1'b1;
      end
      for (i = 0; i < 16; i = i + 1) begin
        r_cnt[i] = 0;    w_cnt[i] = 0;
        r_slvq_h[i] = 0; r_slvq_t[i] = 0;
        w_slvq_h[i] = 0; w_slvq_t[i] = 0;
        rbe_h[i] = 0;    rbe_t[i] = 0;
        wbe_h[i] = 0;    wbe_t[i] = 0;
      end
      for (i = 0; i < 4; i = i + 1) begin
        r_own[i] = -1; r_owncnt[i] = 0;
        w_own[i] = -1; w_owncnt[i] = 0;
        r_midq_h[i] = 0; r_midq_t[i] = 0;
      end
      r_mst_h = 0; r_mst_t = 0;
      we_h = 0;    we_t = 0;
      w_dorder_h = 0; w_dorder_t = 0;
      w_resp_h = 0;   w_resp_t = 0;
      cur_w_tag = -1;
      w_bcur_tag = -1;
    end
  endtask

  // response beat / response tasks (TB is the downstream slave)
  task automatic tb_rbeat(input logic [MST_ID_W-1:0] mid,
                          input logic [DATA_W-1:0]   d,
                          input bit                 lst,
                          input logic [1:0]         rp);
    begin
      @(negedge clk);
      m_rid = mid; m_rdata = d; m_rlast = lst; m_rresp = rp; m_rvalid = 1'b1;
      forever begin @(posedge clk); if (m_rready) break; end
      @(negedge clk) m_rvalid = 1'b0;
    end
  endtask

  task automatic tb_bbeat(input logic [MST_ID_W-1:0] mid,
                          input logic [1:0]         rp);
    begin
      @(negedge clk);
      m_bid = mid; m_bresp = rp; m_bvalid = 1'b1;
      forever begin @(posedge clk); if (m_bready) break; end
      @(negedge clk) m_bvalid = 1'b0;
    end
  endtask

  // convenience wrappers (unique addr per txn -> bookkeeping, not value match)
  task automatic do_ar(input int sid, input int len, input int budget,
                       output bit acc, output int waited);
    begin
      bfm_ar(sid, addr_ctr, len, budget, acc, waited);
      addr_ctr = addr_ctr + 1;
    end
  endtask

  task automatic do_aw(input int sid, input int len, input int budget,
                       output bit acc, output int waited);
    begin
      bfm_aw(sid, addr_ctr, len, budget, acc, waited);
      addr_ctr = addr_ctr + 1;
    end
  endtask

  task automatic do_wbeats(input int len);
    int i;
    logic [DATA_W-1:0]   d;
    logic [DATA_W/8-1:0] st;
    begin
      for (i = 0; i <= len; i = i + 1) begin
        d  = wdata_ctr;
        st = wdata_ctr + 1;
        wdata_ctr = wdata_ctr + 1;
        bfm_w(d, st, (i == len));
      end
    end
  endtask

  task automatic wait_r_idle(input int sid);
    int j;
    begin
      j = 0;
      while ((r_cnt[sid] != 0) && (j < 20000)) begin
        @(negedge clk);
        j = j + 1;
      end
      if (r_cnt[sid] != 0) fail("D4", "read transaction never completed");
    end
  endtask

  task automatic wait_w_idle(input int sid);
    int j;
    begin
      j = 0;
      while ((w_cnt[sid] != 0) && (j < 20000)) begin
        @(negedge clk);
        j = j + 1;
      end
      if (w_cnt[sid] != 0) fail("D4", "write transaction never completed");
    end
  endtask

  task automatic wait_all_r_idle();
    int j; int k; int sum;
    begin
      j = 0;
      forever begin
        sum = 0;
        for (k = 0; k < 16; k = k + 1) sum = sum + r_cnt[k];
        if (sum == 0) break;
        if (j >= 20000) begin fail("D4", "read side did not drain"); break; end
        @(negedge clk);
        j = j + 1;
      end
    end
  endtask

  task automatic wait_all_w_idle();
    int j; int k; int sum;
    begin
      j = 0;
      forever begin
        sum = 0;
        for (k = 0; k < 16; k = k + 1) sum = sum + w_cnt[k];
        if (sum == 0) break;
        if (j >= 20000) begin fail("D4", "write side did not drain"); break; end
        @(negedge clk);
        j = j + 1;
      end
    end
  endtask

  // ---------------------------------------------------------------------------
  // Monitors (sample pre-edge values at posedge, as the plumbing does)
  // ---------------------------------------------------------------------------
  // F1: no response while rst_ni low (checked on negedge: stable sample)
  always @(negedge clk) begin
    if (!rst_n) begin
      if (s_bvalid || s_rvalid) fail("F1", "response presented while rst_ni low");
    end
  end

  // slave AR accept -> create tag, count outstanding (A1/A2)
  always @(posedge clk) begin
    if (rst_n && s_arvalid && s_arready) begin
      t_slv[tag_ctr]    = int'(s_arid);
      t_dir[tag_ctr]    = 0;
      t_addr[tag_ctr]   = s_araddr;
      t_len[tag_ctr]    = s_arlen;
      t_mid[tag_ctr]    = -1;
      t_issued[tag_ctr] = 1'b0;
      t_act[tag_ctr]    = 1'b1;
      t_wmdone[tag_ctr] = 1'b0;
      last_r_tag = tag_ctr;
      r_cnt[int'(s_arid)] = r_cnt[int'(s_arid)] + 1;
      r_slvq[int'(s_arid)][r_slvq_t[int'(s_arid)]] = tag_ctr;
      r_slvq_t[int'(s_arid)] = r_slvq_t[int'(s_arid)] + 1;
      tag_ctr = tag_ctr + 1;
    end
  end

  // slave AW accept
  always @(posedge clk) begin
    if (rst_n && s_awvalid && s_awready) begin
      t_slv[tag_ctr]    = int'(s_awid);
      t_dir[tag_ctr]    = 1;
      t_addr[tag_ctr]   = s_awaddr;
      t_len[tag_ctr]    = s_awlen;
      t_mid[tag_ctr]    = -1;
      t_issued[tag_ctr] = 1'b0;
      t_act[tag_ctr]    = 1'b1;
      t_wmdone[tag_ctr] = 1'b0;
      last_w_tag = tag_ctr;
      w_cnt[int'(s_awid)] = w_cnt[int'(s_awid)] + 1;
      w_slvq[int'(s_awid)][w_slvq_t[int'(s_awid)]] = tag_ctr;
      w_slvq_t[int'(s_awid)] = w_slvq_t[int'(s_awid)] + 1;
      w_resp[w_resp_t] = tag_ctr;
      w_resp_t = w_resp_t + 1;
      tag_ctr = tag_ctr + 1;
    end
  end

  // master AR issue: D4 (match), E1 (len), B1 (per-id order), D1/D2 (mid owner)
  always @(posedge clk) begin
    int tg; int k; int mid;
    tg = -1;
    if (rst_n && m_arvalid && m_arready) begin
      for (k = 0; k < tag_ctr; k = k + 1) begin
        if (t_act[k] && (t_dir[k] == 0) && !t_issued[k] && (t_addr[k] == m_araddr))
          tg = k;
      end
      if (tg < 0) begin
        if (!stray_ok) fail("D4", "master AR without matching slave AR");
      end else begin
        t_issued[tg] = 1'b1;
        if (m_arlen !== t_len[tg]) fail("E1", "m_arlen not forwarded unmodified");
        if (r_slvq[t_slv[tg]][r_slvq_h[t_slv[tg]]] != tg)
          fail("B1", "master AR issued out of per-id accept order");
        r_slvq_h[t_slv[tg]] = r_slvq_h[t_slv[tg]] + 1;
        mid = int'(m_arid);
        t_mid[tg] = mid;
        if ((r_owncnt[mid] > 0) && (r_own[mid] != t_slv[tg]))
          fail("D1", "master id shared/reused while its owner is outstanding (D1/D2)");
        r_own[mid] = t_slv[tg];
        r_owncnt[mid] = r_owncnt[mid] + 1;
        r_mst[r_mst_t] = tg;
        r_mst_t = r_mst_t + 1;
        r_midq[mid][r_midq_t[mid]] = tg;
        r_midq_t[mid] = r_midq_t[mid] + 1;
      end
    end
  end

  // master AW issue
  always @(posedge clk) begin
    int tg; int k; int mid;
    tg = -1;
    if (rst_n && m_awvalid && m_awready) begin
      for (k = 0; k < tag_ctr; k = k + 1) begin
        if (t_act[k] && (t_dir[k] == 1) && !t_issued[k] && (t_addr[k] == m_awaddr))
          tg = k;
      end
      if (tg < 0) begin
        if (!stray_ok) fail("D4", "master AW without matching slave AW");
      end else begin
        t_issued[tg] = 1'b1;
        if (m_awlen !== t_len[tg]) fail("E1", "m_awlen not forwarded unmodified");
        if (w_slvq[t_slv[tg]][w_slvq_h[t_slv[tg]]] != tg)
          fail("B1", "master AW issued out of per-id accept order");
        w_slvq_h[t_slv[tg]] = w_slvq_h[t_slv[tg]] + 1;
        mid = int'(m_awid);
        t_mid[tg] = mid;
        if ((w_owncnt[mid] > 0) && (w_own[mid] != t_slv[tg]))
          fail("D1", "master id shared/reused while its owner is outstanding (D1/D2)");
        w_own[mid] = t_slv[tg];
        w_owncnt[mid] = w_owncnt[mid] + 1;
      end
    end
  end

  // master read beat -> expected slave read beat
  always @(posedge clk) begin
    int mid; int tg; int sv;
    mid = -1; tg = -1;
    if (rst_n && m_rvalid && m_rready) begin
      mid = int'(m_rid);
      if ((mid >= 0) && (r_midq_h[mid] < r_midq_t[mid])) tg = r_midq[mid][r_midq_h[mid]];
      if (tg < 0) begin
        fail("C2", "master read beat with no outstanding master read txn");
      end else begin
        sv = t_slv[tg];
        rbe_data[sv][rbe_t[sv]] = m_rdata;
        rbe_resp[sv][rbe_t[sv]] = m_rresp;
        rbe_last[sv][rbe_t[sv]] = m_rlast;
        rbe_tag [sv][rbe_t[sv]] = tg;
        rbe_t[sv] = rbe_t[sv] + 1;
        if (m_rlast) r_midq_h[mid] = r_midq_h[mid] + 1;
      end
    end
  end

  // slave read response: C1/C2/E1/B1, retirement (A4)
  always @(posedge clk) begin
    int sv; int tg; bit xl;
    if (rst_n && s_rvalid && s_rready) begin
      sv = int'(s_rid);
      if (rbe_h[sv] >= rbe_t[sv]) begin
        fail("C2", "slave read beat for an id with no outstanding read (C1/C2)");
      end else begin
        tg = rbe_tag[sv][rbe_h[sv]];
        if (s_rdata !== rbe_data[sv][rbe_h[sv]]) fail("E1", "read data mismatch (E1/B1/C1)");
        if (s_rresp !== rbe_resp[sv][rbe_h[sv]]) fail("E1", "rresp mismatch");
        if (s_rlast !== rbe_last[sv][rbe_h[sv]]) fail("E1", "rlast mismatch");
        xl = rbe_last[sv][rbe_h[sv]];
        rbe_h[sv] = rbe_h[sv] + 1;
        if (xl) begin
          r_cnt[sv] = r_cnt[sv] - 1;
          if (r_cnt[sv] < 0) fail("C2", "more read completions than outstanding");
          if (t_mid[tg] >= 0) r_owncnt[t_mid[tg]] = r_owncnt[t_mid[tg]] - 1;
          t_act[tg] = 1'b0;
        end
      end
    end
  end

  // slave W beat -> expected master W beat (B3/E1)
  always @(posedge clk) begin
    if (rst_n && s_wvalid && s_wready) begin
      we_data[we_t] = s_wdata;
      we_strb[we_t] = s_wstrb;
      we_last[we_t] = s_wlast;
      we_t = we_t + 1;
      if (s_wlast) begin
        w_dorder[w_dorder_t] = cur_w_tag;
        w_dorder_t = w_dorder_t + 1;
      end
    end
  end

  // master W beat: order + payload (B3/E1)
  always @(posedge clk) begin
    int tg; bit xl;
    tg = -1; xl = 1'b0;
    if (rst_n && m_wvalid && m_wready) begin
      if (we_h >= we_t) begin
        if (!stray_ok) fail("D4", "master W beat with no slave W beat outstanding");
      end else begin
        if (m_wdata !== we_data[we_h]) fail("E1", "write data reordered/modified (B3/E1)");
        if (m_wstrb !== we_strb[we_h]) fail("E1", "wstrb mismatch");
        if (m_wlast !== we_last[we_h]) fail("E1", "wlast mismatch");
        xl = we_last[we_h];
        we_h = we_h + 1;
        if (xl) begin
          tg = w_dorder[w_dorder_h];
          w_dorder_h = w_dorder_h + 1;
          if (tg >= 0) t_wmdone[tg] = 1'b1;
        end
      end
    end
  end

  // master B response -> expected slave B
  always @(posedge clk) begin
    int tg; int sv;
    if (rst_n && m_bvalid && m_bready) begin
      tg = w_bcur_tag;
      if (tg >= 0) begin
        sv = t_slv[tg];
        wbe_tag[sv][wbe_t[sv]] = tg;
        wbe_t[sv] = wbe_t[sv] + 1;
      end
    end
  end

  // slave B response: C1/C2/E1/B1, retirement (A4)
  always @(posedge clk) begin
    int sv; int tg;
    if (rst_n && s_bvalid && s_bready) begin
      sv = int'(s_bid);
      if (wbe_h[sv] >= wbe_t[sv]) begin
        fail("C2", "slave write response for an id with no outstanding write (C1/C2)");
      end else begin
        tg = wbe_tag[sv][wbe_h[sv]];
        wbe_h[sv] = wbe_h[sv] + 1;
        if (s_bresp !== t_bresp[tg]) fail("E1", "bresp mismatch / B response out of per-id order (B1/E1)");
        w_cnt[sv] = w_cnt[sv] - 1;
        if (w_cnt[sv] < 0) fail("C2", "more write completions than outstanding");
        if (t_mid[tg] >= 0) w_owncnt[t_mid[tg]] = w_owncnt[t_mid[tg]] - 1;
        t_act[tg] = 1'b0;
      end
    end
  end

  // ---------------------------------------------------------------------------
  // Responders (downstream slave). Read beats in master-AR order, write
  // responses in AW-accept order -> per-id response order is always legal.
  // ---------------------------------------------------------------------------
  initial begin
    int tg; int mid; int len; int i;
    logic [DATA_W-1:0] d;
    logic [1:0]       rp;
    bit               lst;
    forever begin
      @(posedge clk);
      if ((r_mst_h < r_mst_t) && r_gate) begin
        tg = r_mst[r_mst_h];
        r_mst_h = r_mst_h + 1;
        mid = t_mid[tg];
        len = int'(t_len[tg]);
        r_busy = 1'b1;
        for (i = 0; i <= len; i = i + 1) begin
          while (!r_gate) @(posedge clk);
          d  = rdata_ctr;
          rp = 2'((tg * 3 + i + 1) % 4);
          rdata_ctr = rdata_ctr + 1;
          lst = (i == len);
          tb_rbeat(mid, d, lst, rp);
        end
        r_busy = 1'b0;
      end
    end
  end

  initial begin
    int tg;
    logic [1:0] rp;
    forever begin
      @(posedge clk);
      if ((w_resp_h < w_resp_t) && w_gate && t_wmdone[w_resp[w_resp_h]]) begin
        tg = w_resp[w_resp_h];
        w_resp_h = w_resp_h + 1;
        w_busy = 1'b1;
        while (!w_gate) @(posedge clk);
        rp = 2'((tg * 3 + 1) % 4);
        t_bresp[tg] = rp;
        w_bcur_tag = tg;
        tb_bbeat(t_mid[tg], rp);
        w_busy = 1'b0;
      end
    end
  end

  // ---------------------------------------------------------------------------
  // Main sequence
  // ---------------------------------------------------------------------------
  initial begin
    int i; int j; int waited; int w4;
    bit acc; bit a4;

    s_awid = 0; s_awaddr = 0; s_awlen = 0; s_awvalid = 0;
    s_wdata = 0; s_wstrb = 0; s_wlast = 0; s_wvalid = 0;
    s_arid = 0; s_araddr = 0; s_arlen = 0; s_arvalid = 0;
    m_rid = 0; m_rdata = 0; m_rresp = 0; m_rlast = 0; m_rvalid = 0;
    m_bid = 0; m_bresp = 0; m_bvalid = 0;
    m_awready = 1'b1; m_wready = 1'b1; m_arready = 1'b1;
    s_bready = 1'b1;  s_rready = 1'b1;
    r_gate = 1'b1;    w_gate = 1'b1;
    model_clear();
    bfm_reset(4);

    // ---- phase 1: basic read (D4/E1/C1) ----
    do_ar(1, 2, 200, acc, waited);
    if (!acc) fail("A3", "basic read request refused");
    wait_r_idle(1);

    // ---- phase 2: basic write ----
    do_aw(1, 1, 200, acc, waited);
    if (!acc) fail("A3", "basic write request refused");
    cur_w_tag = last_w_tag;
    do_wbeats(1);
    wait_w_idle(1);

    // ---- phase 3: read table boundary (A3 / A5 / A4 / D1) ----
    r_gate = 1'b0;                       // freeze completions
    @(negedge clk);
    for (i = 1; i <= 4; i = i + 1) begin
      do_ar(i, 0, 200, acc, waited);
      if (!acc) fail("A3", "read refused with fewer than MAX_UNIQ_IDS distinct ids outstanding");
    end
    do_ar(5, 0, 10, acc, waited);        // 4 distinct outstanding: new id
    if (acc) fail("A3", "read accepted with MAX_UNIQ_IDS distinct ids outstanding");
    do_ar(3, 0, 200, acc, waited);       // 2nd txn for existing id: permitted, not required
    if (acc) begin
      do_ar(3, 0, 10, acc, waited);
      if (acc) fail("A5", "third read per id accepted with two outstanding");
    end
    r_gate = 1'b1;                      // A4: free id 1, then new id within 2 cycles
    j = 0;
    while ((r_cnt[1] != 0) && (j < 20000)) begin
      @(negedge clk);
      j = j + 1;
    end
    if (r_cnt[1] != 0) fail("D4", "read never completed");
    s_arid = 5; s_araddr = addr_ctr; s_arlen = 0;
    addr_ctr = addr_ctr + 1;
    s_arvalid = 1'b1;
    w4 = 0; a4 = 1'b0;
    while (w4 < 6) begin
      @(posedge clk);
      if (s_arready) begin a4 = 1'b1; break; end
      w4 = w4 + 1;
    end
    @(negedge clk) s_arvalid = 1'b0;
    if (!a4) fail("A4", "new id not accepted after an entry was freed")
    else if (w4 > 1) fail("A4", "new id accepted later than 2 cycles after retirement");
    wait_all_r_idle();

    // ---- phase 4: write table boundary (A3 / A5 / A4 / D1) ----
    w_gate = 1'b0;
    @(negedge clk);
    for (i = 1; i <= 4; i = i + 1) begin
      do_aw(i, 0, 200, acc, waited);
      if (!acc) fail("A3", "write refused with fewer than MAX_UNIQ_IDS distinct ids outstanding");
      cur_w_tag = last_w_tag;
      do_wbeats(0);
    end
    do_aw(5, 0, 10, acc, waited);
    if (acc) fail("A3", "write accepted with MAX_UNIQ_IDS distinct ids outstanding");
    do_aw(3, 0, 200, acc, waited);
    if (acc) begin
      cur_w_tag = last_w_tag;
      do_wbeats(0);
      do_aw(3, 0, 10, acc, waited);
      if (acc) fail("A5", "third write per id accepted with two outstanding");
    end
    w_gate = 1'b1;
    j = 0;
    while ((w_cnt[1] != 0) && (j < 20000)) begin
      @(negedge clk);
      j = j + 1;
    end
    if (w_cnt[1] != 0) fail("D4", "write never completed");
    s_awid = 5; s_awaddr = addr_ctr; s_awlen = 0;
    addr_ctr = addr_ctr + 1;
    s_awvalid = 1'b1;
    w4 = 0; a4 = 1'b0;
    while (w4 < 6) begin
      @(posedge clk);
      if (s_awready) begin a4 = 1'b1; break; end
      w4 = w4 + 1;
    end
    @(negedge clk) s_awvalid = 1'b0;
    if (!a4) fail("A4", "new write id not accepted after an entry was freed")
    else if (w4 > 1) fail("A4", "new write id accepted later than 2 cycles after retirement");
    if (a4) begin
      cur_w_tag = last_w_tag;
      do_wbeats(0);
    end
    wait_all_w_idle();

    // ---- phase 5: B1, two reads same id co-outstanding ----
    r_gate = 1'b0;
    @(negedge clk);
    do_ar(2, 1, 200, acc, waited);
    if (!acc) fail("A3", "read refused (B1 setup)");
    do_ar(2, 3, 200, acc, waited);       // second per id: permitted, not required
    r_gate = 1'b1;
    wait_all_r_idle();

    // ---- phase 6: B3, two writes, beats in address-accept order ----
    do_aw(7, 2, 200, acc, waited);
    if (!acc) fail("A3", "write refused (B3 setup)");
    cur_w_tag = last_w_tag;
    do_wbeats(2);
    do_aw(8, 1, 200, acc, waited);
    if (!acc) fail("A3", "write refused (B3 setup 2)");
    cur_w_tag = last_w_tag;
    do_wbeats(1);
    wait_all_w_idle();

    // ---- phase 7: F1 reset with transactions outstanding ----
    r_gate = 1'b0; w_gate = 1'b0;
    @(negedge clk);
    do_ar(9, 1, 200, acc, waited);
    if (!acc) fail("A3", "read refused (F1 setup)");
    do_ar(10, 0, 200, acc, waited);
    if (!acc) fail("A3", "read refused (F1 setup 2)");
    do_aw(9, 0, 200, acc, waited);
    if (!acc) fail("A3", "write refused (F1 setup)");
    cur_w_tag = last_w_tag;
    do_wbeats(0);
    do_aw(10, 0, 200, acc, waited);
    if (!acc) fail("A3", "write refused (F1 setup 2)");
    cur_w_tag = last_w_tag;
    do_wbeats(0);
    j = 0;
    while ((r_busy || w_busy) && (j < 100)) begin
      @(negedge clk);
      j = j + 1;
    end
    bfm_reset(5);
    model_clear();
    stray_ok = 1'b1;
    // F1: discarded transactions must produce no response after release
    for (i = 0; i < 40; i = i + 1) begin
      @(negedge clk);
      if (s_rvalid) fail("F1", "read response after reset for a discarded txn");
      if (s_bvalid) fail("F1", "write response after reset for a discarded txn");
    end
    // A3 (table empty after release): 4 distinct read ids must be accepted
    for (i = 1; i <= 4; i = i + 1) begin
      do_ar(i, 0, 200, acc, waited);
      if (!acc) fail("A3", "post-reset read refused: table not empty after reset");
    end
    r_gate = 1'b1;
    wait_all_r_idle();
    for (i = 1; i <= 4; i = i + 1) begin
      do_aw(i, 0, 200, acc, waited);
      if (!acc) fail("A3", "post-reset write refused: table not empty after reset");
      cur_w_tag = last_w_tag;
      do_wbeats(0);
    end
    w_gate = 1'b1;
    wait_all_w_idle();

    if (errors == 0) $display("RESULT: PASS");
    else             $display("RESULT: FAIL");
    $finish;
  end

endmodule
