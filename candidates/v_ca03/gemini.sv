module id_width_conv_tb;

  parameter int unsigned SLV_ID_W        = 4;
  parameter int unsigned MST_ID_W        = 2;
  parameter int unsigned ADDR_W          = 32;
  parameter int unsigned DATA_W          = 32;
  parameter int unsigned MAX_UNIQ_IDS    = 4;
  parameter int unsigned MAX_TXNS_PER_ID = 2;

  // Ports
  logic                    clk;
  logic                    rst_n;

  logic [SLV_ID_W-1:0]     s_awid;
  logic [ADDR_W-1:0]       s_awaddr;
  logic [7:0]              s_awlen;
  logic                    s_awvalid;
  logic                    s_awready;
  logic [DATA_W-1:0]       s_wdata;
  logic [DATA_W/8-1:0]     s_wstrb;
  logic                    s_wlast;
  logic                    s_wvalid;
  logic                    s_wready;
  logic [SLV_ID_W-1:0]     s_bid;
  logic [1:0]              s_bresp;
  logic                    s_bvalid;
  logic                    s_bready;
  logic [SLV_ID_W-1:0]     s_arid;
  logic [ADDR_W-1:0]       s_araddr;
  logic [7:0]              s_arlen;
  logic                    s_arvalid;
  logic                    s_arready;
  logic [SLV_ID_W-1:0]     s_rid;
  logic [DATA_W-1:0]       s_rdata;
  logic [1:0]              s_rresp;
  logic                    s_rlast;
  logic                    s_rvalid;
  logic                    s_rready;

  logic [MST_ID_W-1:0]     m_awid;
  logic [ADDR_W-1:0]       m_awaddr;
  logic [7:0]              m_awlen;
  logic                    m_awvalid;
  logic                    m_awready;
  logic [DATA_W-1:0]       m_wdata;
  logic [DATA_W/8-1:0]     m_wstrb;
  logic                    m_wlast;
  logic                    m_wvalid;
  logic                    m_wready;
  logic [MST_ID_W-1:0]     m_bid;
  logic [1:0]              m_bresp;
  logic                    m_bvalid;
  logic                    m_bready;
  logic [MST_ID_W-1:0]     m_arid;
  logic [ADDR_W-1:0]       m_araddr;
  logic [7:0]              m_arlen;
  logic                    m_arvalid;
  logic                    m_arready;
  logic [MST_ID_W-1:0]     m_rid;
  logic [DATA_W-1:0]       m_rdata;
  logic [1:0]              m_rresp;
  logic                    m_rlast;
  logic                    m_rvalid;
  logic                    m_rready;

  id_width_conv #(
      .SLV_ID_W(SLV_ID_W),
      .MST_ID_W(MST_ID_W),
      .ADDR_W(ADDR_W),
      .DATA_W(DATA_W),
      .MAX_UNIQ_IDS(MAX_UNIQ_IDS),
      .MAX_TXNS_PER_ID(MAX_TXNS_PER_ID)
  ) dut (
      .clk_i(clk), .rst_ni(rst_n),
      .s_awid(s_awid), .s_awaddr(s_awaddr), .s_awlen(s_awlen), .s_awvalid(s_awvalid), .s_awready(s_awready),
      .s_wdata(s_wdata), .s_wstrb(s_wstrb), .s_wlast(s_wlast), .s_wvalid(s_wvalid), .s_wready(s_wready),
      .s_bid(s_bid), .s_bresp(s_bresp), .s_bvalid(s_bvalid), .s_bready(s_bready),
      .s_arid(s_arid), .s_araddr(s_araddr), .s_arlen(s_arlen), .s_arvalid(s_arvalid), .s_arready(s_arready),
      .s_rid(s_rid), .s_rdata(s_rdata), .s_rresp(s_rresp), .s_rlast(s_rlast), .s_rvalid(s_rvalid), .s_rready(s_rready),
      .m_awid(m_awid), .m_awaddr(m_awaddr), .m_awlen(m_awlen), .m_awvalid(m_awvalid), .m_awready(m_awready),
      .m_wdata(m_wdata), .m_wstrb(m_wstrb), .m_wlast(m_wlast), .m_wvalid(m_wvalid), .m_wready(m_wready),
      .m_bid(m_bid), .m_bresp(m_bresp), .m_bvalid(m_bvalid), .m_bready(m_bready),
      .m_arid(m_arid), .m_araddr(m_araddr), .m_arlen(m_arlen), .m_arvalid(m_arvalid), .m_arready(m_arready),
      .m_rid(m_rid), .m_rdata(m_rdata), .m_rresp(m_rresp), .m_rlast(m_rlast), .m_rvalid(m_rvalid), .m_rready(m_rready)
  );

  // ---------------------------------------------------------------------------
  // PROVIDED PLUMBING -- moves transactions, checks nothing.
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

  task automatic bfm_ar(input logic [SLV_ID_W-1:0] id, input logic [ADDR_W-1:0] addr, input logic [7:0] len, input int budget, output bit accepted, output int waited);
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

  task automatic bfm_aw(input logic [SLV_ID_W-1:0] id, input logic [ADDR_W-1:0] addr, input logic [7:0] len, input int budget, output bit accepted, output int waited);
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

  task automatic bfm_w(input logic [DATA_W-1:0] data, input logic [DATA_W/8-1:0] strb, input logic last);
    @(negedge clk);
    s_wdata = data; s_wstrb = strb; s_wlast = last; s_wvalid = 1'b1;
    forever begin @(posedge clk); if (s_wready) break; end
    @(negedge clk) s_wvalid = 1'b0;
  endtask

  task automatic bfm_rbeat(input logic [MST_ID_W-1:0] mid, input logic [DATA_W-1:0] data, input logic last);
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

  // ---------------------------------------------------------------------------
  // TESTBENCH STRUCTURES AND MONITORS
  // ---------------------------------------------------------------------------
  int errors = 0;
  task automatic error(string msg);
    $display("FAIL: %s", msg);
    errors++;
  endtask

  int cycle_count = 0;
  always @(posedge clk) cycle_count++;

  typedef struct { logic [31:0] data; logic last; } rbeat_t;
  typedef struct { logic [31:0] data; logic [3:0] strb; logic last; } wbeat_t;

  rbeat_t expected_rbeats[16][$];
  int     expected_bbeats[16];
  wbeat_t expected_m_wbeats[$];

  int ar_outstanding_cnt[16];
  int aw_outstanding_cnt[16];
  int last_ar_accept_cycle[16];
  int last_aw_accept_cycle[16];
  int retire_cycle_ar[16];
  int retire_cycle_aw[16];

  int active_m_ids_for_sid_ar[16][4];
  int active_m_ids_for_sid_aw[16][4];

  int ar_sid_by_mid[4][$];
  int aw_sid_by_mid[4][$];

  int expected_m_arlen_by_addr[logic [31:0]];
  int expected_m_awlen_by_addr[logic [31:0]];
  int s_ar_id_by_addr[logic [31:0]];
  int s_aw_id_by_addr[logic [31:0]];

  task automatic tb_reset();
    bfm_reset();
    for(int i=0; i<16; i++) begin
      ar_outstanding_cnt[i] = 0;
      aw_outstanding_cnt[i] = 0;
      expected_bbeats[i] = 0;
      expected_rbeats[i].delete();
      for(int j=0; j<4; j++) begin
        active_m_ids_for_sid_ar[i][j] = 0;
        active_m_ids_for_sid_aw[i][j] = 0;
      end
    end
    for(int j=0; j<4; j++) begin
      ar_sid_by_mid[j].delete();
      aw_sid_by_mid[j].delete();
    end
    expected_m_arlen_by_addr.delete();
    expected_m_awlen_by_addr.delete();
    s_ar_id_by_addr.delete();
    s_aw_id_by_addr.delete();
    expected_m_wbeats.delete();
  endtask

  // Track Outstanding and Retirement Cycles (A1, A4)
  always @(posedge clk) begin
    if (!rst_n) begin
      // checked in reset tasks
    end else begin
      if (s_arvalid === 1'b1 && s_arready === 1'b1) begin
        ar_outstanding_cnt[s_arid]++;
        last_ar_accept_cycle[s_arid] = cycle_count;
      end
      if (s_rvalid === 1'b1 && s_rready === 1'b1) begin
        if (s_rlast === 1'b1) begin
          if (ar_outstanding_cnt[s_rid] > 0) begin
            if (ar_outstanding_cnt[s_rid] == 1) retire_cycle_ar[s_rid] = cycle_count;
            ar_outstanding_cnt[s_rid]--;
          end else begin
            error("C2: R response for non-outstanding ID");
          end
        end
      end

      if (s_awvalid === 1'b1 && s_awready === 1'b1) begin
        aw_outstanding_cnt[s_awid]++;
        last_aw_accept_cycle[s_awid] = cycle_count;
      end
      if (s_bvalid === 1'b1 && s_bready === 1'b1) begin
        if (aw_outstanding_cnt[s_bid] > 0) begin
          if (aw_outstanding_cnt[s_bid] == 1) retire_cycle_aw[s_bid] = cycle_count;
          aw_outstanding_cnt[s_bid]--;
        end else begin
          error("C2: B response for non-outstanding ID");
        end
      end
    end
  end

  // AR Master Channel Monitor (D1, D2, D4, E1, F1)
  always @(posedge clk) begin
    if (rst_n && m_arvalid === 1'b1 && m_arready === 1'b1) begin
      automatic logic [31:0] addr = m_araddr;
      automatic logic [1:0]  mid  = m_arid;
      if (!s_ar_id_by_addr.exists(addr)) begin
        error("E1/F1: Master AR for unknown address (likely pre-reset)");
      end else begin
        automatic int sid = s_ar_id_by_addr[addr];
        ar_sid_by_mid[mid].push_back(sid);
        active_m_ids_for_sid_ar[sid][mid]++;
        for (int i=0; i<16; i++) begin
          if (i != sid && active_m_ids_for_sid_ar[i][mid] > 0) begin
            error("D1: Same Master AR ID used for different co-outstanding Slave IDs");
          end
        end
        if (m_arlen !== expected_m_arlen_by_addr[addr]) error("E1: M_ARLEN mismatch");
      end
    end
  end

  // AW Master Channel Monitor (D1, D2, D4, E1, F1)
  always @(posedge clk) begin
    if (rst_n && m_awvalid === 1'b1 && m_awready === 1'b1) begin
      automatic logic [31:0] addr = m_awaddr;
      automatic logic [1:0]  mid  = m_awid;
      if (!s_aw_id_by_addr.exists(addr)) begin
        error("E1/F1: Master AW for unknown address");
      end else begin
        automatic int sid = s_aw_id_by_addr[addr];
        aw_sid_by_mid[mid].push_back(sid);
        active_m_ids_for_sid_aw[sid][mid]++;
        for (int i=0; i<16; i++) begin
          if (i != sid && active_m_ids_for_sid_aw[i][mid] > 0) begin
            error("D1: Same Master AW ID used for different co-outstanding Slave IDs");
          end
        end
        if (m_awlen !== expected_m_awlen_by_addr[addr]) error("E1: M_AWLEN mismatch");
      end
    end
  end

  // Write Data Master Monitor (B3, E1)
  always @(posedge clk) begin
    if (rst_n && m_wvalid === 1'b1 && m_wready === 1'b1) begin
      if (expected_m_wbeats.size() == 0) begin
        error("B3/E1: Unexpected Master W beat");
      end else begin
        automatic wbeat_t exp = expected_m_wbeats.pop_front();
        if (m_wdata !== exp.data) error("E1: M_WDATA mismatch");
        if (m_wstrb !== exp.strb) error("E1: M_WSTRB mismatch");
        if (m_wlast !== exp.last) error("E1: M_WLAST mismatch");
      end
    end
  end

  // Read Data Slave Monitor (C1, C2, B1, E1)
  always @(posedge clk) begin
    if (rst_n && s_rvalid === 1'b1 && s_rready === 1'b1) begin
      automatic int sid = s_rid;
      if (expected_rbeats[sid].size() == 0) begin
        error("C1/C2: Unexpected R beat or wrong ID");
      end else begin
        automatic rbeat_t exp = expected_rbeats[sid].pop_front();
        if (s_rdata !== exp.data) error("E1: S_RDATA mismatch");
        if (s_rlast !== exp.last) error("E1: S_RLAST mismatch");
      end
    end
  end

  // Write Resp Slave Monitor (C1, C2, B1)
  always @(posedge clk) begin
    if (rst_n && s_bvalid === 1'b1 && s_bready === 1'b1) begin
      automatic int sid = s_bid;
      if (expected_bbeats[sid] == 0) begin
        error("C1/C2: Unexpected B beat or wrong ID");
      end else begin
        expected_bbeats[sid]--;
      end
    end
  end

  // F1 Reset State Checking
  always @(posedge clk) begin
    if (!rst_n) begin
      if (s_arready === 1'b1 || s_awready === 1'b1 || s_wready === 1'b1 ||
          s_rvalid === 1'b1 || s_bvalid === 1'b1 ||
          m_arvalid === 1'b1 || m_awvalid === 1'b1 || m_wvalid === 1'b1) begin
        error("F1: Active signals during reset");
      end
    end
  end

  // ---------------------------------------------------------------------------
  // HELPER TASKS
  // ---------------------------------------------------------------------------
  task automatic send_ar(input int id, input logic[31:0] addr, input logic[7:0] len, input int expected_accept);
    automatic bit acc; automatic int w;
    s_ar_id_by_addr[addr] = id;
    expected_m_arlen_by_addr[addr] = len;
    bfm_ar(id, addr, len, 50, acc, w);
    if (expected_accept && !acc) error($sformatf("A3: Failed to accept AR ID %0d", id));
    if (!expected_accept && acc) error($sformatf("A3/A5: Should not accept AR ID %0d", id));
  endtask

  task automatic send_aw(input int id, input logic[31:0] addr, input logic[7:0] len, input int expected_accept);
    automatic bit acc; automatic int w;
    s_aw_id_by_addr[addr] = id;
    expected_m_awlen_by_addr[addr] = len;
    bfm_aw(id, addr, len, 50, acc, w);
    if (expected_accept && !acc) error($sformatf("A3: Failed to accept AW ID %0d", id));
    if (!expected_accept && acc) error($sformatf("A3/A5: Should not accept AW ID %0d", id));
  endtask

  task automatic send_wbeat(input logic [31:0] data, input logic [3:0] strb, input logic last);
    expected_m_wbeats.push_back('{data, strb, last});
    bfm_w(data, strb, last);
  endtask

  task automatic wait_for_m_ar(input int sid);
    automatic int count = 0;
    while (count < 150) begin
      @(posedge clk);
      for (int i=0; i<4; i++) begin
        if (active_m_ids_for_sid_ar[sid][i] > 0) return;
      end
      count++;
    end
    error($sformatf("TB: M_AR for sid %0d never appeared", sid));
  endtask

  task automatic wait_for_m_aw(input int sid);
    automatic int count = 0;
    while (count < 150) begin
      @(posedge clk);
      for (int i=0; i<4; i++) begin
        if (active_m_ids_for_sid_aw[sid][i] > 0) return;
      end
      count++;
    end
    error($sformatf("TB: M_AW for sid %0d never appeared", sid));
  endtask

  task automatic retire_sid_ar(input int sid);
    automatic int mid = -1;
    for (int i=0; i<4; i++) begin
      if (active_m_ids_for_sid_ar[sid][i] > 0) begin mid = i; break; end
    end
    if (mid == -1) begin error("TB: No active mid for AR sid"); return; end
    
    // send_rbeat inline
    begin
      automatic int mapped_sid = ar_sid_by_mid[mid][0];
      expected_rbeats[mapped_sid].push_back('{32'hCAFEBABE, 1'b1});
      bfm_rbeat(mid, 32'hCAFEBABE, 1'b1);
      ar_sid_by_mid[mid].pop_front();
      active_m_ids_for_sid_ar[mapped_sid][mid]--;
    end
  endtask

  task automatic retire_sid_aw(input int sid);
    automatic int mid = -1;
    for (int i=0; i<4; i++) begin
      if (active_m_ids_for_sid_aw[sid][i] > 0) begin mid = i; break; end
    end
    if (mid == -1) begin error("TB: No active mid for AW sid"); return; end
    
    // send_bbeat inline
    begin
      automatic int mapped_sid = aw_sid_by_mid[mid].pop_front();
      expected_bbeats[mapped_sid]++;
      bfm_bbeat(mid);
      active_m_ids_for_sid_aw[mapped_sid][mid]--;
    end
  endtask


  // ---------------------------------------------------------------------------
  // MAIN TEST SEQUENCE
  // ---------------------------------------------------------------------------
  initial begin
    // Setup inputs (act as ready slave downstream)
    s_bready = 1; s_rready = 1;
    m_awready = 1; m_arready = 1; m_wready = 1;

    // Reset Phase
    tb_reset();

    // PHASE 1: AR boundary & depth (A2, A3, A5)
    send_ar(0, 32'h1000, 8'h0, 1);
    send_ar(1, 32'h1100, 8'h0, 1);
    send_ar(2, 32'h1200, 8'h0, 1);
    send_ar(3, 32'h1300, 8'h0, 1);

    // 5th distinct ID -> reject (A3)
    send_ar(4, 32'h1400, 8'h0, 0);

    // Already outstanding ID -> accept (A3 part 2)
    send_ar(0, 32'h1010, 8'h0, 1);

    // 3rd txn on same ID -> reject (A5)
    send_ar(0, 32'h1020, 8'h0, 0);


    // PHASE 2: AR Retirement and Turnaround (A4)
    wait_for_m_ar(1);
    fork
      begin
        send_ar(4, 32'h1400, 8'h0, 1); // should succeed after retirement
      end
      begin
        repeat (3) @(posedge clk);
        retire_sid_ar(1);
      end
    join
    if ((last_ar_accept_cycle[4] - retire_cycle_ar[1]) > 2) begin
      error("A4: Acceptance of new ID took more than 2 cycles after retirement");
    end


    // PHASE 3: AW boundary & write ordering (A2, A3, A5, B3)
    send_aw(5, 32'h2000, 8'h0, 1);
    send_aw(6, 32'h2100, 8'h0, 1);
    send_aw(7, 32'h2200, 8'h0, 1);
    send_aw(8, 32'h2300, 8'h0, 1);

    // 5th AW ID -> reject
    send_aw(9, 32'h2400, 8'h0, 0);

    // Duplicate -> accept
    send_aw(5, 32'h2010, 8'h0, 1);

    // W Data driving in strict AW acceptance order (B3 checks via M monitor)
    send_wbeat(32'hD05, 4'hF, 1'b1);
    send_wbeat(32'hD06, 4'hF, 1'b1);
    send_wbeat(32'hD07, 4'hF, 1'b1);
    send_wbeat(32'hD08, 4'hF, 1'b1);
    send_wbeat(32'hD05_2, 4'hF, 1'b1);

    // Retire AW ID 6 to free up slot
    wait_for_m_aw(6);
    fork
      begin
        send_aw(9, 32'h2400, 8'h0, 1);
      end
      begin
        repeat (3) @(posedge clk);
        retire_sid_aw(6);
      end
    join
    if ((last_aw_accept_cycle[9] - retire_cycle_aw[6]) > 2) begin
      error("A4: Acceptance of AW took more than 2 cycles");
    end
    send_wbeat(32'hD09, 4'hF, 1'b1);


    // PHASE 4: Reset behavior (F1)
    // IDs 0, 2, 3, 4 active for AR. IDs 5, 7, 8, 9 active for AW.
    tb_reset();

    // After reset, table must be completely empty. (F1)
    // Max 4 unique IDs should be accepted successfully.
    send_ar(10, 32'h3000, 8'h0, 1);
    send_ar(11, 32'h3100, 8'h0, 1);
    send_ar(12, 32'h3200, 8'h0, 1);
    send_ar(13, 32'h3300, 8'h0, 1);
    send_ar(14, 32'h3400, 8'h0, 0); // Fails since full

    // Give it time to flush any accidental spurious traffic
    repeat (50) @(posedge clk);

    if (errors == 0) $display("RESULT: PASS");
    else $display("RESULT: FAIL (%0d errors)", errors);
    $finish;
  end

endmodule