module id_width_conv_tb;

  localparam int unsigned SLV_ID_W         = 4;
  localparam int unsigned MST_ID_W         = 2;
  localparam int unsigned ADDR_W           = 32;
  localparam int unsigned DATA_W           = 32;
  localparam int unsigned MAX_UNIQ_IDS     = 4;
  localparam int unsigned MAX_TXNS_PER_ID  = 2;
  localparam int unsigned MID_COUNT        = (1 << MST_ID_W);
  localparam int unsigned SID_COUNT        = (1 << SLV_ID_W);

  // ---------------------------------------------------------------------------
  // Clock / reset
  // ---------------------------------------------------------------------------
  logic clk;
  initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
  end

  logic rst_n;
  initial rst_n = 1'b0;

  task automatic bfm_reset(input int cycles = 4);
    @(negedge clk);
    rst_n = 1'b0;
    repeat (cycles) @(posedge clk);
    @(negedge clk);
    rst_n = 1'b1;
  endtask

  // ---------------------------------------------------------------------------
  // DUT signals
  // ---------------------------------------------------------------------------
  logic [SLV_ID_W-1:0] s_awid;
  logic [ADDR_W-1:0]   s_awaddr;
  logic [7:0]          s_awlen;
  logic                s_awvalid;
  logic                s_awready;

  logic [DATA_W-1:0]   s_wdata;
  logic [DATA_W/8-1:0] s_wstrb;
  logic                s_wlast;
  logic                s_wvalid;
  logic                s_wready;

  logic [SLV_ID_W-1:0] s_bid;
  logic [1:0]          s_bresp;
  logic                s_bvalid;
  logic                s_bready;

  logic [SLV_ID_W-1:0] s_arid;
  logic [ADDR_W-1:0]   s_araddr;
  logic [7:0]          s_arlen;
  logic                s_arvalid;
  logic                s_arready;

  logic [SLV_ID_W-1:0] s_rid;
  logic [DATA_W-1:0]   s_rdata;
  logic [1:0]          s_rresp;
  logic                s_rlast;
  logic                s_rvalid;
  logic                s_rready;

  logic [MST_ID_W-1:0] m_awid;
  logic [ADDR_W-1:0]   m_awaddr;
  logic [7:0]          m_awlen;
  logic                m_awvalid;
  logic                m_awready;

  logic [DATA_W-1:0]   m_wdata;
  logic [DATA_W/8-1:0] m_wstrb;
  logic                m_wlast;
  logic                m_wvalid;
  logic                m_wready;

  logic [MST_ID_W-1:0] m_bid;
  logic [1:0]          m_bresp;
  logic                m_bvalid;
  logic                m_bready;

  logic [MST_ID_W-1:0] m_arid;
  logic [ADDR_W-1:0]   m_araddr;
  logic [7:0]          m_arlen;
  logic                m_arvalid;
  logic                m_arready;

  logic [MST_ID_W-1:0] m_rid;
  logic [DATA_W-1:0]   m_rdata;
  logic [1:0]          m_rresp;
  logic                m_rlast;
  logic                m_rvalid;
  logic                m_rready;

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
  // Provided transaction helpers
  // ---------------------------------------------------------------------------
  task automatic bfm_ar(
      input  logic [SLV_ID_W-1:0] id,
      input  logic [ADDR_W-1:0]   addr,
      input  logic [7:0]          len,
      input  int                  budget,
      output bit                  accepted,
      output int                  waited
  );
    accepted = 1'b0;
    waited = 0;
    @(negedge clk);
    s_arid = id;
    s_araddr = addr;
    s_arlen = len;
    s_arvalid = 1'b1;
    while (waited < budget) begin
      @(posedge clk);
      if (s_arready) begin
        accepted = 1'b1;
        break;
      end
      waited++;
    end
    @(negedge clk);
    s_arvalid = 1'b0;
  endtask

  task automatic bfm_aw(
      input  logic [SLV_ID_W-1:0] id,
      input  logic [ADDR_W-1:0]   addr,
      input  logic [7:0]          len,
      input  int                  budget,
      output bit                  accepted,
      output int                  waited
  );
    accepted = 1'b0;
    waited = 0;
    @(negedge clk);
    s_awid = id;
    s_awaddr = addr;
    s_awlen = len;
    s_awvalid = 1'b1;
    while (waited < budget) begin
      @(posedge clk);
      if (s_awready) begin
        accepted = 1'b1;
        break;
      end
      waited++;
    end
    @(negedge clk);
    s_awvalid = 1'b0;
  endtask

  task automatic bfm_w(
      input logic [DATA_W-1:0]   data,
      input logic [DATA_W/8-1:0] strb,
      input logic                last
  );
    @(negedge clk);
    s_wdata = data;
    s_wstrb = strb;
    s_wlast = last;
    s_wvalid = 1'b1;
    forever begin
      @(posedge clk);
      if (s_wready)
        break;
    end
    @(negedge clk);
    s_wvalid = 1'b0;
  endtask

  task automatic bfm_rbeat(
      input logic [MST_ID_W-1:0] mid,
      input logic [DATA_W-1:0]   data,
      input logic                last
  );
    @(negedge clk);
    m_rid = mid;
    m_rdata = data;
    m_rlast = last;
    m_rresp = 2'b00;
    m_rvalid = 1'b1;
    forever begin
      @(posedge clk);
      if (m_rready)
        break;
    end
    @(negedge clk);
    m_rvalid = 1'b0;
  endtask

  task automatic bfm_bbeat(input logic [MST_ID_W-1:0] mid);
    @(negedge clk);
    m_bid = mid;
    m_bresp = 2'b00;
    m_bvalid = 1'b1;
    forever begin
      @(posedge clk);
      if (m_bready)
        break;
    end
    @(negedge clk);
    m_bvalid = 1'b0;
  endtask

  // ---------------------------------------------------------------------------
  // Checker state
  // ---------------------------------------------------------------------------
  bit verdict_done;
  int tb_cycle;
  int reset_low_edges;

  int rd_out [0:SID_COUNT-1];
  int wr_out [0:SID_COUNT-1];

  bit rd_mid_valid [0:MID_COUNT-1];
  bit wr_mid_valid [0:MID_COUNT-1];
  logic [SLV_ID_W-1:0] rd_mid_sid [0:MID_COUNT-1];
  logic [SLV_ID_W-1:0] wr_mid_sid [0:MID_COUNT-1];

  bit rd_addr_exp_valid;
  bit rd_addr_exp_accepted;
  logic [SLV_ID_W-1:0] rd_addr_exp_sid;
  logic [ADDR_W-1:0] rd_addr_exp_addr;
  logic [7:0] rd_addr_exp_len;
  logic [MST_ID_W-1:0] rd_last_mid;
  int rd_master_seq;

  bit wr_addr_exp_valid;
  bit wr_addr_exp_accepted;
  logic [SLV_ID_W-1:0] wr_addr_exp_sid;
  logic [ADDR_W-1:0] wr_addr_exp_addr;
  logic [7:0] wr_addr_exp_len;
  logic [MST_ID_W-1:0] wr_last_mid;
  int wr_master_seq;

  bit rd_resp_exp_valid;
  logic [SLV_ID_W-1:0] rd_resp_exp_sid;
  logic [DATA_W-1:0] rd_resp_exp_data;
  logic [1:0] rd_resp_exp_resp;
  logic rd_resp_exp_last;
  int rd_resp_seq;
  int rd_resp_owed;

  bit wr_resp_exp_valid;
  logic [SLV_ID_W-1:0] wr_resp_exp_sid;
  int wr_resp_seq;
  int wr_resp_owed;

  bit allow_unexpected_master_resp;

  localparam int WQ_MAX = 256;
  logic [DATA_W-1:0] wq_data [0:WQ_MAX-1];
  logic [DATA_W/8-1:0] wq_strb [0:WQ_MAX-1];
  logic wq_last [0:WQ_MAX-1];
  int wq_head;
  int wq_tail;
  int w_forward_seq;

  integer mi;
  integer si;
  integer sid_v;
  integer mid_v;
  integer slot_v;
  integer distinct_v;

  task automatic fail_clause(
      input string clause_name,
      input string detail
  );
    begin
      if (!verdict_done) begin
        verdict_done = 1'b1;
        $display("FAIL [%s] cycle=%0d: %s", clause_name, tb_cycle, detail);
        $display("RESULT: FAIL");
        $finish;
      end
    end
  endtask

  function automatic int count_rd_distinct;
    int i;
    int n;
    begin
      n = 0;
      for (i = 0; i < SID_COUNT; i = i + 1) begin
        if (rd_out[i] > 0)
          n = n + 1;
      end
      count_rd_distinct = n;
    end
  endfunction

  function automatic int count_wr_distinct;
    int i;
    int n;
    begin
      n = 0;
      for (i = 0; i < SID_COUNT; i = i + 1) begin
        if (wr_out[i] > 0)
          n = n + 1;
      end
      count_wr_distinct = n;
    end
  endfunction

  // ---------------------------------------------------------------------------
  // Always-on scoreboard.
  //
  // Completion is processed before new master-address allocation so a master
  // ID may legally become reusable on the same edge on which the last upstream
  // response for its former slave ID completes (A4/D2).
  // ---------------------------------------------------------------------------
  always @(posedge clk) begin
    if (!rst_n) begin
      tb_cycle = 0;

      // A synchronous-reset DUT commonly updates registered outputs in the NBA
      // region of the first asserted edge.  Judge reset-idle behaviour from the
      // following asserted edge onward, avoiding an active/NBA sampling race.
      if (reset_low_edges > 0) begin
        if (s_arvalid && s_arready)
          fail_clause("F1", "read address request was accepted while reset was low");

        if (s_awvalid && s_awready)
          fail_clause("F1", "write address request was accepted while reset was low");

        if (s_rvalid)
          fail_clause("F1", "read response was presented while reset was low");

        if (s_bvalid)
          fail_clause("F1", "write response was presented while reset was low");
      end

      reset_low_edges = reset_low_edges + 1;

      for (si = 0; si < SID_COUNT; si = si + 1) begin
        rd_out[si] = 0;
        wr_out[si] = 0;
      end

      for (mi = 0; mi < MID_COUNT; mi = mi + 1) begin
        rd_mid_valid[mi] = 1'b0;
        wr_mid_valid[mi] = 1'b0;
        rd_mid_sid[mi] = '0;
        wr_mid_sid[mi] = '0;
      end

      rd_addr_exp_valid = 1'b0;
      rd_addr_exp_accepted = 1'b0;
      wr_addr_exp_valid = 1'b0;
      wr_addr_exp_accepted = 1'b0;

      rd_resp_exp_valid = 1'b0;
      wr_resp_exp_valid = 1'b0;
      rd_resp_owed = 0;
      wr_resp_owed = 0;

      wq_head = 0;
      wq_tail = 0;

    end else begin
      reset_low_edges = 0;
      tb_cycle = tb_cycle + 1;

      // ---- downstream response handshakes create one owed upstream response
      if (m_rvalid && m_rready && !allow_unexpected_master_resp)
        rd_resp_owed = rd_resp_owed + 1;

      if (m_bvalid && m_bready && !allow_unexpected_master_resp)
        wr_resp_owed = wr_resp_owed + 1;

      // ---- read response: C1/C2/E1, plus A1 retirement
      if (s_rvalid && s_rready) begin
        sid_v = s_rid;

        if (rd_out[sid_v] <= 0)
          fail_clause("C2", "slave read response named an ID with no outstanding read transaction");

        if (!rd_resp_exp_valid && !allow_unexpected_master_resp)
          fail_clause("C2/D4", "slave read response appeared with no expected master response");

        if (rd_resp_exp_valid) begin
          if (s_rid !== rd_resp_exp_sid)
            fail_clause("C1", "slave read response restored the wrong slave identifier");

          if (s_rdata !== rd_resp_exp_data)
            fail_clause("E1", "read response data was modified");

          if (s_rresp !== rd_resp_exp_resp)
            fail_clause("E1", "read response code was modified");

          if (s_rlast !== rd_resp_exp_last)
            fail_clause("E1", "read response last flag was modified");

          rd_resp_exp_valid = 1'b0;
          rd_resp_seq = rd_resp_seq + 1;
        end

        if (!allow_unexpected_master_resp) begin
          if (rd_resp_owed <= 0)
            fail_clause("D4", "more slave read responses were produced than master read responses accepted");
          rd_resp_owed = rd_resp_owed - 1;
        end

        if (s_rlast) begin
          rd_out[sid_v] = rd_out[sid_v] - 1;

          if (rd_out[sid_v] == 0) begin
            for (mi = 0; mi < MID_COUNT; mi = mi + 1) begin
              if (rd_mid_valid[mi] && (rd_mid_sid[mi] == sid_v)) begin
                rd_mid_valid[mi] = 1'b0;
                rd_mid_sid[mi] = '0;
              end
            end
          end
        end
      end

      // ---- write response: C1/C2, plus A1 retirement
      if (s_bvalid && s_bready) begin
        sid_v = s_bid;

        if (wr_out[sid_v] <= 0)
          fail_clause("C2", "slave write response named an ID with no outstanding write transaction");

        if (!wr_resp_exp_valid && !allow_unexpected_master_resp)
          fail_clause("C2/D4", "slave write response appeared with no expected master response");

        if (wr_resp_exp_valid) begin
          if (s_bid !== wr_resp_exp_sid)
            fail_clause("C1", "slave write response restored the wrong slave identifier");

          wr_resp_exp_valid = 1'b0;
          wr_resp_seq = wr_resp_seq + 1;
        end

        if (!allow_unexpected_master_resp) begin
          if (wr_resp_owed <= 0)
            fail_clause("D4", "more slave write responses were produced than master write responses accepted");
          wr_resp_owed = wr_resp_owed - 1;
        end

        wr_out[sid_v] = wr_out[sid_v] - 1;

        if (wr_out[sid_v] == 0) begin
          for (mi = 0; mi < MID_COUNT; mi = mi + 1) begin
            if (wr_mid_valid[mi] && (wr_mid_sid[mi] == sid_v)) begin
              wr_mid_valid[mi] = 1'b0;
              wr_mid_sid[mi] = '0;
            end
          end
        end
      end

      // ---- accepted slave read addresses: A1/A2/A5
      if (s_arvalid && s_arready) begin
        sid_v = s_arid;
        rd_out[sid_v] = rd_out[sid_v] + 1;

        if (rd_out[sid_v] > MAX_TXNS_PER_ID)
          fail_clause("A5", "more than MAX_TXNS_PER_ID reads were accepted for one slave ID");

        distinct_v = count_rd_distinct();
        if (distinct_v > MAX_UNIQ_IDS)
          fail_clause("A2/A3", "more than MAX_UNIQ_IDS distinct read IDs became outstanding");

        if (rd_addr_exp_valid) begin
          if ((s_arid !== rd_addr_exp_sid) ||
              (s_araddr !== rd_addr_exp_addr) ||
              (s_arlen !== rd_addr_exp_len))
            fail_clause("D4/E1", "accepted read address did not match the transaction armed by the testbench");

          rd_addr_exp_accepted = 1'b1;
        end
      end

      // ---- accepted slave write addresses: A1/A2/A5
      if (s_awvalid && s_awready) begin
        sid_v = s_awid;
        wr_out[sid_v] = wr_out[sid_v] + 1;

        if (wr_out[sid_v] > MAX_TXNS_PER_ID)
          fail_clause("A5", "more than MAX_TXNS_PER_ID writes were accepted for one slave ID");

        distinct_v = count_wr_distinct();
        if (distinct_v > MAX_UNIQ_IDS)
          fail_clause("A2/A3", "more than MAX_UNIQ_IDS distinct write IDs became outstanding");

        if (wr_addr_exp_valid) begin
          if ((s_awid !== wr_addr_exp_sid) ||
              (s_awaddr !== wr_addr_exp_addr) ||
              (s_awlen !== wr_addr_exp_len))
            fail_clause("D4/E1", "accepted write address did not match the transaction armed by the testbench");

          wr_addr_exp_accepted = 1'b1;
        end
      end

      // ---- master read address: D1/D2/D4/E1
      if (m_arvalid && m_arready) begin
        mid_v = m_arid;

        if (!rd_addr_exp_valid || !rd_addr_exp_accepted)
          fail_clause("D4", "master read address appeared without the corresponding accepted slave request");

        if (m_araddr !== rd_addr_exp_addr)
          fail_clause("E1/D4", "master read address was modified");

        if (m_arlen !== rd_addr_exp_len)
          fail_clause("E1/D4", "master read length was modified");

        if (rd_mid_valid[mid_v] && (rd_mid_sid[mid_v] != rd_addr_exp_sid))
          fail_clause("D1/D2", "master read ID was reused for a different co-outstanding slave ID");

        rd_mid_valid[mid_v] = 1'b1;
        rd_mid_sid[mid_v] = rd_addr_exp_sid;
        rd_last_mid = m_arid;
        rd_master_seq = rd_master_seq + 1;
        rd_addr_exp_valid = 1'b0;
        rd_addr_exp_accepted = 1'b0;
      end

      // ---- master write address: D1/D2/D4/E1
      if (m_awvalid && m_awready) begin
        mid_v = m_awid;

        if (!wr_addr_exp_valid || !wr_addr_exp_accepted)
          fail_clause("D4", "master write address appeared without the corresponding accepted slave request");

        if (m_awaddr !== wr_addr_exp_addr)
          fail_clause("E1/D4", "master write address was modified");

        if (m_awlen !== wr_addr_exp_len)
          fail_clause("E1/D4", "master write length was modified");

        if (wr_mid_valid[mid_v] && (wr_mid_sid[mid_v] != wr_addr_exp_sid))
          fail_clause("D1/D2", "master write ID was reused for a different co-outstanding slave ID");

        wr_mid_valid[mid_v] = 1'b1;
        wr_mid_sid[mid_v] = wr_addr_exp_sid;
        wr_last_mid = m_awid;
        wr_master_seq = wr_master_seq + 1;
        wr_addr_exp_valid = 1'b0;
        wr_addr_exp_accepted = 1'b0;
      end

      // ---- write data FIFO: B3/E1
      if (s_wvalid && s_wready) begin
        if ((wq_tail - wq_head) >= WQ_MAX)
          fail_clause("B3", "write-data checker queue overflowed");

        slot_v = wq_tail % WQ_MAX;
        wq_data[slot_v] = s_wdata;
        wq_strb[slot_v] = s_wstrb;
        wq_last[slot_v] = s_wlast;
        wq_tail = wq_tail + 1;
      end

      if (m_wvalid && m_wready) begin
        if (wq_head >= wq_tail)
          fail_clause("B3/D4", "master write-data beat appeared without an accepted slave write-data beat");

        slot_v = wq_head % WQ_MAX;

        if (m_wdata !== wq_data[slot_v])
          fail_clause("E1/B3", "write-data payload was modified or reordered");

        if (m_wstrb !== wq_strb[slot_v])
          fail_clause("E1/B3", "write strobe was modified or reordered");

        if (m_wlast !== wq_last[slot_v])
          fail_clause("E1/B3", "write last flag was modified or reordered");

        wq_head = wq_head + 1;
        w_forward_seq = w_forward_seq + 1;
      end
    end
  end

  // ---------------------------------------------------------------------------
  // High-level helpers
  // ---------------------------------------------------------------------------
  task automatic wait_rd_master(
      input int start_seq,
      input int budget,
      output logic [MST_ID_W-1:0] mid
  );
    int n;
    begin
      n = 0;
      while ((rd_master_seq == start_seq) && (n < budget)) begin
        @(negedge clk);
        n = n + 1;
      end

      if (rd_master_seq == start_seq)
        fail_clause("D4", "accepted slave read request did not produce a master read request within the watchdog-sized test window");

      mid = rd_last_mid;
    end
  endtask

  task automatic wait_wr_master(
      input int start_seq,
      input int budget,
      output logic [MST_ID_W-1:0] mid
  );
    int n;
    begin
      n = 0;
      while ((wr_master_seq == start_seq) && (n < budget)) begin
        @(negedge clk);
        n = n + 1;
      end

      if (wr_master_seq == start_seq)
        fail_clause("D4", "accepted slave write request did not produce a master write request within the watchdog-sized test window");

      mid = wr_last_mid;
    end
  endtask

  task automatic issue_read(
      input logic [SLV_ID_W-1:0] sid,
      input logic [ADDR_W-1:0] addr,
      input logic [7:0] len,
      input int accept_budget,
      input string accept_clause,
      output logic [MST_ID_W-1:0] mid
  );
    bit accepted;
    int waited;
    int start_seq;
    begin
      start_seq = rd_master_seq;
      rd_addr_exp_valid = 1'b1;
      rd_addr_exp_accepted = 1'b0;
      rd_addr_exp_sid = sid;
      rd_addr_exp_addr = addr;
      rd_addr_exp_len = len;

      bfm_ar(sid, addr, len, accept_budget, accepted, waited);

      if (!accepted)
        fail_clause(accept_clause, "read request that was required for this test was not accepted");

      wait_rd_master(start_seq, 2048, mid);
    end
  endtask

  task automatic issue_write(
      input logic [SLV_ID_W-1:0] sid,
      input logic [ADDR_W-1:0] addr,
      input logic [7:0] len,
      input int accept_budget,
      input string accept_clause,
      output logic [MST_ID_W-1:0] mid
  );
    bit accepted;
    int waited;
    int start_seq;
    begin
      start_seq = wr_master_seq;
      wr_addr_exp_valid = 1'b1;
      wr_addr_exp_accepted = 1'b0;
      wr_addr_exp_sid = sid;
      wr_addr_exp_addr = addr;
      wr_addr_exp_len = len;

      bfm_aw(sid, addr, len, accept_budget, accepted, waited);

      if (!accepted)
        fail_clause(accept_clause, "write request that was required for this test was not accepted");

      wait_wr_master(start_seq, 2048, mid);
    end
  endtask

  task automatic expect_read_blocked(
      input logic [SLV_ID_W-1:0] sid,
      input logic [ADDR_W-1:0] addr,
      input logic [7:0] len,
      input int budget,
      input string clause_name
  );
    bit accepted;
    int waited;
    begin
      bfm_ar(sid, addr, len, budget, accepted, waited);
      if (accepted)
        fail_clause(clause_name, "read request was accepted at a boundary where it was required to remain blocked");
    end
  endtask

  task automatic expect_write_blocked(
      input logic [SLV_ID_W-1:0] sid,
      input logic [ADDR_W-1:0] addr,
      input logic [7:0] len,
      input int budget,
      input string clause_name
  );
    bit accepted;
    int waited;
    begin
      bfm_aw(sid, addr, len, budget, accepted, waited);
      if (accepted)
        fail_clause(clause_name, "write request was accepted at a boundary where it was required to remain blocked");
    end
  endtask

  task automatic send_w_checked(
      input logic [DATA_W-1:0] data,
      input logic [DATA_W/8-1:0] strb,
      input logic last
  );
    int start_seq;
    int n;
    begin
      start_seq = w_forward_seq;
      bfm_w(data, strb, last);

      n = 0;
      while ((w_forward_seq == start_seq) && (n < 2048)) begin
        @(negedge clk);
        n = n + 1;
      end

      if (w_forward_seq == start_seq)
        fail_clause("B3/E1", "accepted slave write-data beat was not forwarded on the master port");
    end
  endtask

  task automatic send_r_expect(
      input logic [MST_ID_W-1:0] mid,
      input logic [SLV_ID_W-1:0] sid,
      input logic [DATA_W-1:0] data,
      input logic [1:0] resp,
      input logic last
  );
    int start_seq;
    int n;
    bit m_done;
    begin
      if (rd_resp_exp_valid)
        fail_clause("D4", "testbench attempted to overlap two read response expectations");

      start_seq = rd_resp_seq;
      rd_resp_exp_valid = 1'b1;
      rd_resp_exp_sid = sid;
      rd_resp_exp_data = data;
      rd_resp_exp_resp = resp;
      rd_resp_exp_last = last;

      @(negedge clk);
      m_rid = mid;
      m_rdata = data;
      m_rresp = resp;
      m_rlast = last;
      m_rvalid = 1'b1;

      m_done = 1'b0;
      n = 0;
      while (!m_done && (n < 2048)) begin
        @(posedge clk);
        if (m_rready)
          m_done = 1'b1;
        n = n + 1;
      end

      if (!m_done)
        fail_clause("D4", "master read response was never accepted by the converter");

      @(negedge clk);
      m_rvalid = 1'b0;

      n = 0;
      while ((rd_resp_seq == start_seq) && (n < 2048)) begin
        @(negedge clk);
        n = n + 1;
      end

      if (rd_resp_seq == start_seq)
        fail_clause("D4", "accepted master read response did not produce one slave read response");
    end
  endtask

  task automatic send_two_r_in_order_no_wait(
      input logic [MST_ID_W-1:0] mid_a,
      input logic [MST_ID_W-1:0] mid_b,
      input logic [SLV_ID_W-1:0] sid,
      input logic [DATA_W-1:0] data_a,
      input logic [DATA_W-1:0] data_b
  );
    int got;
    int n;
    bit a_taken;
    bit b_taken;
    begin
      // This helper deliberately does NOT wait for A to emerge upstream before
      // presenting B downstream.  That creates a real same-ID ordering test
      // while still presenting the downstream responses in legal transaction
      // order for every master-ID allocation policy.
      if (rd_resp_exp_valid)
        fail_clause("B1", "testbench ordering probe started with another read expectation active");

      allow_unexpected_master_resp = 1'b1;
      rd_resp_exp_valid = 1'b0;
      rd_resp_owed = 0;

      got = 0;
      a_taken = 1'b0;
      b_taken = 1'b0;
      n = 0;

      @(negedge clk);
      m_rid = mid_a;
      m_rdata = data_a;
      m_rresp = 2'b00;
      m_rlast = 1'b1;
      m_rvalid = 1'b1;

      while (!a_taken && (n < 2048)) begin
        @(posedge clk);

        if (s_rvalid && s_rready) begin
          if (s_rid !== sid)
            fail_clause("C1/B1", "same-ID ordering probe restored the wrong slave ID");
          if (got != 0)
            fail_clause("B1", "unexpected extra read response appeared before the first ordered response");
          if (s_rdata !== data_a)
            fail_clause("B1", "second same-ID read response overtook the first");
          if (!s_rlast)
            fail_clause("E1/B1", "single-beat first response lost its last flag");
          got = 1;
        end

        if (m_rready)
          a_taken = 1'b1;

        n = n + 1;
      end

      if (!a_taken)
        fail_clause("D4", "first master response in same-ID ordering probe was not accepted");

      // Change to the second legal response only on the opposite edge after A
      // was accepted.  Keeping valid asserted is a legal back-to-back transfer.
      @(negedge clk);
      m_rid = mid_b;
      m_rdata = data_b;
      m_rresp = 2'b00;
      m_rlast = 1'b1;
      m_rvalid = 1'b1;

      n = 0;
      while (!b_taken && (n < 2048)) begin
        @(posedge clk);

        if (s_rvalid && s_rready) begin
          if (s_rid !== sid)
            fail_clause("C1/B1", "same-ID ordering probe restored the wrong slave ID");

          if (got == 0) begin
            if (s_rdata !== data_a)
              fail_clause("B1", "second same-ID read response overtook the first");
            if (!s_rlast)
              fail_clause("E1/B1", "single-beat first response lost its last flag");
            got = 1;
          end else if (got == 1) begin
            if (s_rdata !== data_b)
              fail_clause("B1", "same-ID read responses were not returned in address-acceptance order");
            if (!s_rlast)
              fail_clause("E1/B1", "single-beat second response lost its last flag");
            got = 2;
          end else begin
            fail_clause("C2/D4", "duplicate slave read response appeared in same-ID ordering probe");
          end
        end

        if (m_rready)
          b_taken = 1'b1;

        n = n + 1;
      end

      if (!b_taken)
        fail_clause("D4", "second master response in same-ID ordering probe was not accepted");

      @(negedge clk);
      m_rvalid = 1'b0;

      n = 0;
      while ((got < 2) && (n < 2048)) begin
        @(posedge clk);

        if (s_rvalid && s_rready) begin
          if (s_rid !== sid)
            fail_clause("C1/B1", "same-ID ordering probe restored the wrong slave ID");

          if (got == 0) begin
            if (s_rdata !== data_a)
              fail_clause("B1", "second same-ID read response overtook the first");
            if (!s_rlast)
              fail_clause("E1/B1", "single-beat first response lost its last flag");
            got = 1;
          end else if (got == 1) begin
            if (s_rdata !== data_b)
              fail_clause("B1", "same-ID read responses were not returned in address-acceptance order");
            if (!s_rlast)
              fail_clause("E1/B1", "single-beat second response lost its last flag");
            got = 2;
          end
        end

        n = n + 1;
      end

      if (got != 2)
        fail_clause("B1/D4", "two master responses did not produce two ordered slave responses");

      // With both transactions complete, any additional slave response is a
      // duplicate and C2/D4 violation.
      repeat (3) begin
        @(posedge clk);
        if (s_rvalid && s_rready)
          fail_clause("C2/D4", "duplicate slave read response appeared after same-ID ordering probe");
      end

      @(negedge clk);
      allow_unexpected_master_resp = 1'b0;
      rd_resp_owed = 0;
    end
  endtask

  task automatic send_b_expect(
      input logic [MST_ID_W-1:0] mid,
      input logic [SLV_ID_W-1:0] sid
  );
    int start_seq;
    int n;
    bit m_done;
    begin
      if (wr_resp_exp_valid)
        fail_clause("D4", "testbench attempted to overlap two write response expectations");

      start_seq = wr_resp_seq;
      wr_resp_exp_valid = 1'b1;
      wr_resp_exp_sid = sid;

      @(negedge clk);
      m_bid = mid;
      m_bresp = 2'b00;
      m_bvalid = 1'b1;

      m_done = 1'b0;
      n = 0;
      while (!m_done && (n < 2048)) begin
        @(posedge clk);
        if (m_bready)
          m_done = 1'b1;
        n = n + 1;
      end

      if (!m_done)
        fail_clause("D4", "master write response was never accepted by the converter");

      @(negedge clk);
      m_bvalid = 1'b0;

      n = 0;
      while ((wr_resp_seq == start_seq) && (n < 2048)) begin
        @(negedge clk);
        n = n + 1;
      end

      if (wr_resp_seq == start_seq)
        fail_clause("D4", "accepted master write response did not produce one slave write response");
    end
  endtask

  // A4 read-side boundary.  The fifth identifier is already continuously
  // offered when the selected old identifier retires.  Acceptance on that same
  // edge is legal and counts as delay zero.
  task automatic read_retire_and_accept_new(
      input logic [MST_ID_W-1:0] retiring_mid,
      input logic [SLV_ID_W-1:0] retiring_sid,
      input logic [SLV_ID_W-1:0] new_sid,
      input logic [ADDR_W-1:0] new_addr,
      output logic [MST_ID_W-1:0] new_mid
  );
    int start_master_seq;
    int start_resp_seq;
    int n;
    int post_retire_cycles;
    bit retired;
    bit accepted;
    bit master_resp_taken;
    begin
      start_master_seq = rd_master_seq;
      start_resp_seq = rd_resp_seq;
      rd_addr_exp_valid = 1'b1;
      rd_addr_exp_accepted = 1'b0;
      rd_addr_exp_sid = new_sid;
      rd_addr_exp_addr = new_addr;
      rd_addr_exp_len = 8'd0;

      rd_resp_exp_valid = 1'b1;
      rd_resp_exp_sid = retiring_sid;
      rd_resp_exp_data = 32'hA4A4_1001;
      rd_resp_exp_resp = 2'b00;
      rd_resp_exp_last = 1'b1;

      @(negedge clk);
      s_arid = new_sid;
      s_araddr = new_addr;
      s_arlen = 8'd0;
      s_arvalid = 1'b1;

      // Prove it is blocked while the table is still full.
      repeat (3) begin
        @(posedge clk);
        if (s_arready)
          fail_clause("A3", "new read ID was accepted while MAX_UNIQ_IDS old IDs were still outstanding");
      end

      @(negedge clk);
      m_rid = retiring_mid;
      m_rdata = 32'hA4A4_1001;
      m_rresp = 2'b00;
      m_rlast = 1'b1;
      m_rvalid = 1'b1;

      retired = 1'b0;
      accepted = 1'b0;
      master_resp_taken = 1'b0;
      post_retire_cycles = 0;
      n = 0;

      while (!accepted && (n < 4096)) begin
        @(posedge clk);

        if (!master_resp_taken && m_rready)
          master_resp_taken = 1'b1;

        // Same-edge retirement and acceptance is legal: evaluate both raw
        // handshakes from this edge before deciding whether A3 was violated.
        if (s_rvalid && s_rready && s_rlast && (s_rid == retiring_sid))
          retired = 1'b1;

        if (s_arvalid && s_arready) begin
          if (!retired)
            fail_clause("A3", "new read ID was accepted before an old ID retired completely");
          accepted = 1'b1;
        end

        if (retired && !accepted) begin
          post_retire_cycles = post_retire_cycles + 1;
          if (post_retire_cycles > 2)
            fail_clause("A4", "new read ID was not accepted within 2 cycles of final retirement");
        end

        n = n + 1;

        // A valid response must not be presented repeatedly after its first
        // handshake.  Drop it on the opposite edge as soon as it is taken.
        @(negedge clk);
        if (master_resp_taken)
          m_rvalid = 1'b0;
        if (accepted)
          s_arvalid = 1'b0;
      end

      if (!master_resp_taken)
        fail_clause("D4", "retiring master read response was not accepted");

      if (!accepted)
        fail_clause("A4", "new read ID was never accepted after retirement");

      s_arvalid = 1'b0;
      m_rvalid = 1'b0;

      if (rd_resp_seq == start_resp_seq)
        fail_clause("D4", "retiring master read response did not reach the slave side");

      wait_rd_master(start_master_seq, 2048, new_mid);
    end
  endtask

  task automatic write_retire_and_accept_new(
      input logic [MST_ID_W-1:0] retiring_mid,
      input logic [SLV_ID_W-1:0] retiring_sid,
      input logic [SLV_ID_W-1:0] new_sid,
      input logic [ADDR_W-1:0] new_addr,
      output logic [MST_ID_W-1:0] new_mid
  );
    int start_master_seq;
    int start_resp_seq;
    int n;
    int post_retire_cycles;
    bit retired;
    bit accepted;
    bit master_resp_taken;
    begin
      start_master_seq = wr_master_seq;
      start_resp_seq = wr_resp_seq;
      wr_addr_exp_valid = 1'b1;
      wr_addr_exp_accepted = 1'b0;
      wr_addr_exp_sid = new_sid;
      wr_addr_exp_addr = new_addr;
      wr_addr_exp_len = 8'd0;

      wr_resp_exp_valid = 1'b1;
      wr_resp_exp_sid = retiring_sid;

      @(negedge clk);
      s_awid = new_sid;
      s_awaddr = new_addr;
      s_awlen = 8'd0;
      s_awvalid = 1'b1;

      repeat (3) begin
        @(posedge clk);
        if (s_awready)
          fail_clause("A3", "new write ID was accepted while MAX_UNIQ_IDS old IDs were still outstanding");
      end

      @(negedge clk);
      m_bid = retiring_mid;
      m_bresp = 2'b00;
      m_bvalid = 1'b1;

      retired = 1'b0;
      accepted = 1'b0;
      master_resp_taken = 1'b0;
      post_retire_cycles = 0;
      n = 0;

      while (!accepted && (n < 4096)) begin
        @(posedge clk);

        if (!master_resp_taken && m_bready)
          master_resp_taken = 1'b1;

        if (s_bvalid && s_bready && (s_bid == retiring_sid))
          retired = 1'b1;

        if (s_awvalid && s_awready) begin
          if (!retired)
            fail_clause("A3", "new write ID was accepted before an old ID retired completely");
          accepted = 1'b1;
        end

        if (retired && !accepted) begin
          post_retire_cycles = post_retire_cycles + 1;
          if (post_retire_cycles > 2)
            fail_clause("A4", "new write ID was not accepted within 2 cycles of final retirement");
        end

        n = n + 1;

        @(negedge clk);
        if (master_resp_taken)
          m_bvalid = 1'b0;
        if (accepted)
          s_awvalid = 1'b0;
      end

      if (!master_resp_taken)
        fail_clause("D4", "retiring master write response was not accepted");

      if (!accepted)
        fail_clause("A4", "new write ID was never accepted after retirement");

      s_awvalid = 1'b0;
      m_bvalid = 1'b0;

      if (wr_resp_seq == start_resp_seq)
        fail_clause("D4", "retiring master write response did not reach the slave side");

      wait_wr_master(start_master_seq, 2048, new_mid);
    end
  endtask

  task automatic verify_four_distinct_read_mids(
      input logic [MST_ID_W-1:0] m0,
      input logic [MST_ID_W-1:0] m1,
      input logic [MST_ID_W-1:0] m2,
      input logic [MST_ID_W-1:0] m3
  );
    begin
      if ((m0 == m1) || (m0 == m2) || (m0 == m3) ||
          (m1 == m2) || (m1 == m3) || (m2 == m3))
        fail_clause("D1", "four co-outstanding read IDs did not receive four distinct master IDs");
    end
  endtask

  task automatic verify_four_distinct_write_mids(
      input logic [MST_ID_W-1:0] m0,
      input logic [MST_ID_W-1:0] m1,
      input logic [MST_ID_W-1:0] m2,
      input logic [MST_ID_W-1:0] m3
  );
    begin
      if ((m0 == m1) || (m0 == m2) || (m0 == m3) ||
          (m1 == m2) || (m1 == m3) || (m2 == m3))
        fail_clause("D1", "four co-outstanding write IDs did not receive four distinct master IDs");
    end
  endtask

  // ---------------------------------------------------------------------------
  // Test phases
  // ---------------------------------------------------------------------------
  task automatic test_read_capacity;
    logic [MST_ID_W-1:0] m1;
    logic [MST_ID_W-1:0] m2;
    logic [MST_ID_W-1:0] m3;
    logic [MST_ID_W-1:0] m4;
    logic [MST_ID_W-1:0] m1b;
    logic [MST_ID_W-1:0] m1c;
    logic [MST_ID_W-1:0] m5;
    begin
      bfm_reset(4);
      repeat (2) @(posedge clk);

      issue_read(4'h1, 32'h1000_0100, 8'd0, 256, "A3", m1);
      issue_read(4'h2, 32'h1000_0200, 8'd0, 256, "A3", m2);
      issue_read(4'h3, 32'h1000_0300, 8'd0, 256, "A3", m3);

      // Exact A3 lower boundary: with only MAX_UNIQ_IDS-1 distinct IDs in use,
      // the fourth distinct ID is not a request that may be rejected forever.
      issue_read(4'h4, 32'h1000_0400, 8'd0, 256, "A3", m4);
      verify_four_distinct_read_mids(m1, m2, m3, m4);

      // Fifth distinct ID must be blocked while all four entries are occupied.
      expect_read_blocked(4'h5, 32'h1000_0500, 8'd0, 12, "A3");

      // An already-present ID is not blocked by A3 and may reach depth two.
      issue_read(4'h1, 32'h1000_0110, 8'd0, 256, "A3/A5", m1b);

      // With four master IDs already owned by four distinct slave IDs, D1
      // forces this second transaction of ID 1 to use an ID not owned by a
      // different slave ID.  The always-on owner checker enforces that rule.
      expect_read_blocked(4'h1, 32'h1000_0120, 8'd0, 12, "A5");

      // Retire one of ID 1's two transactions.  A third transaction with ID 1
      // can then be admitted without increasing the distinct-ID count.
      send_r_expect(m1, 4'h1, 32'h1111_0001, 2'b00, 1'b1);
      issue_read(4'h1, 32'h1000_0120, 8'd0, 256, "A5", m1c);

      // Retire the sole transaction for ID 2 while ID 5 is already being held
      // valid.  A4 gives an exact two-cycle acceptance bound from retirement.
      read_retire_and_accept_new(m2, 4'h2, 4'h5, 32'h1000_0500, m5);

      // Because IDs 1,3,4 remain outstanding, the newly allocated ID 5 must not
      // collide with any of their master IDs.  D3 leaves the particular value
      // free, so compare only against still-live owners.
      if ((m5 == m1) || (m5 == m3) || (m5 == m4))
        fail_clause("D1/D2", "new read ID reused a master ID still owned by a different outstanding slave ID");
    end
  endtask

  task automatic test_write_capacity_and_data;
    logic [MST_ID_W-1:0] m1;
    logic [MST_ID_W-1:0] m2;
    logic [MST_ID_W-1:0] m3;
    logic [MST_ID_W-1:0] m4;
    logic [MST_ID_W-1:0] m1b;
    logic [MST_ID_W-1:0] m1c;
    logic [MST_ID_W-1:0] m5;
    begin
      bfm_reset(4);
      repeat (2) @(posedge clk);

      issue_write(4'h1, 32'h2000_0100, 8'd0, 256, "A3", m1);
      send_w_checked(32'hA001_0001, 4'b1111, 1'b1);

      issue_write(4'h2, 32'h2000_0200, 8'd0, 256, "A3", m2);
      send_w_checked(32'hA002_0002, 4'b1101, 1'b1);

      issue_write(4'h3, 32'h2000_0300, 8'd0, 256, "A3", m3);
      send_w_checked(32'hA003_0003, 4'b1011, 1'b1);

      issue_write(4'h4, 32'h2000_0400, 8'd0, 256, "A3", m4);
      send_w_checked(32'hA004_0004, 4'b0111, 1'b1);

      verify_four_distinct_write_mids(m1, m2, m3, m4);

      expect_write_blocked(4'h5, 32'h2000_0500, 8'd0, 12, "A3");

      issue_write(4'h1, 32'h2000_0110, 8'd0, 256, "A3/A5", m1b);
      send_w_checked(32'hB001_0011, 4'b1110, 1'b1);

      expect_write_blocked(4'h1, 32'h2000_0120, 8'd0, 12, "A5");

      send_b_expect(m1, 4'h1);
      issue_write(4'h1, 32'h2000_0120, 8'd0, 256, "A5", m1c);
      send_w_checked(32'hC001_0021, 4'b0011, 1'b1);

      write_retire_and_accept_new(m2, 4'h2, 4'h5, 32'h2000_0500, m5);
      send_w_checked(32'hD005_0050, 4'b0101, 1'b1);

      if ((m5 == m1) || (m5 == m3) || (m5 == m4))
        fail_clause("D1/D2", "new write ID reused a master ID still owned by a different outstanding slave ID");
    end
  endtask

  task automatic test_payload_and_ordering;
    logic [MST_ID_W-1:0] r7a;
    logic [MST_ID_W-1:0] r7b;
    logic [MST_ID_W-1:0] r8;
    logic [MST_ID_W-1:0] r9;
    logic [MST_ID_W-1:0] w6a;
    logic [MST_ID_W-1:0] w6b;
    begin
      bfm_reset(4);
      repeat (2) @(posedge clk);

      // Multi-beat read response: exact data/resp/last preservation and ID
      // restoration on every beat.
      issue_read(4'h7, 32'h3000_7000, 8'd1, 256, "A3", r7a);
      send_r_expect(r7a, 4'h7, 32'h7011_AAAA, 2'b10, 1'b0);
      send_r_expect(r7a, 4'h7, 32'h7012_5555, 2'b01, 1'b1);

      // Two co-outstanding transactions with the same slave ID.  Their master
      // responses are driven back-to-back in transaction order without waiting
      // for the first slave response, so B1 is observable if the converter
      // swaps buffered same-ID responses.
      issue_read(4'h7, 32'h3000_7010, 8'd0, 256, "A3", r7a);
      issue_read(4'h7, 32'h3000_7020, 8'd0, 256, "A5", r7b);
      send_two_r_in_order_no_wait(
          r7a, r7b, 4'h7, 32'h7020_1111, 32'h7020_2222
      );

      // Different IDs may return in either order.  Deliberately return ID 9
      // first; the checker validates each transaction independently and does not
      // impose a cross-ID ordering rule (B2 latitude).
      issue_read(4'h8, 32'h3000_8000, 8'd0, 256, "A3", r8);
      issue_read(4'h9, 32'h3000_9000, 8'd0, 256, "A3", r9);
      send_r_expect(r9, 4'h9, 32'h9000_0009, 2'b00, 1'b1);
      send_r_expect(r8, 4'h8, 32'h8000_0008, 2'b00, 1'b1);

      // Write-data ordering and non-interleaving.  Two write addresses are
      // accepted in sequence; their beats are then sent in that same address
      // order.  The FIFO checker compares every downstream W beat against this
      // exact accepted upstream beat stream.
      issue_write(4'h6, 32'h4000_6000, 8'd2, 256, "A3", w6a);
      issue_write(4'h6, 32'h4000_6010, 8'd1, 256, "A5", w6b);

      send_w_checked(32'h6000_0001, 4'b1111, 1'b0);
      send_w_checked(32'h6000_0002, 4'b1010, 1'b0);
      send_w_checked(32'h6000_0003, 4'b0101, 1'b1);
      send_w_checked(32'h6010_0001, 4'b1100, 1'b0);
      send_w_checked(32'h6010_0002, 4'b0011, 1'b1);

      send_b_expect(w6a, 4'h6);
      send_b_expect(w6b, 4'h6);
    end
  endtask

  task automatic test_reset_discard;
    logic [MST_ID_W-1:0] old_rmid;
    logic [MST_ID_W-1:0] old_wmid;
    logic [MST_ID_W-1:0] tmp_mid;
    int n;
    begin
      bfm_reset(4);
      repeat (2) @(posedge clk);

      // Leave one read and one write genuinely outstanding across the reset
      // assertion.  No downstream response is supplied for either transaction.
      issue_read(4'hA, 32'h5000_A000, 8'd0, 256, "A3", old_rmid);
      issue_write(4'hB, 32'h5000_B000, 8'd0, 256, "A3", old_wmid);
      send_w_checked(32'hBEEF_00B0, 4'b1111, 1'b1);

      // Assert synchronous active-low reset.  Slave address valids are held high
      // during reset specifically to check the F1 no-acceptance rule.
      @(negedge clk);
      rst_n = 1'b0;
      s_arid = 4'hC;
      s_araddr = 32'h5000_C000;
      s_arlen = 8'd0;
      s_arvalid = 1'b1;
      s_awid = 4'hD;
      s_awaddr = 32'h5000_D000;
      s_awlen = 8'd0;
      s_awvalid = 1'b1;

      repeat (4) @(posedge clk);

      @(negedge clk);
      s_arvalid = 1'b0;
      s_awvalid = 1'b0;
      rst_n = 1'b1;

      // No pre-reset transaction may spontaneously reappear after release.
      for (n = 0; n < 6; n = n + 1) begin
        @(posedge clk);
        if (s_rvalid || s_bvalid)
          fail_clause("F1", "a transaction outstanding before reset produced a response after reset");
      end

      // More importantly, the old table occupancy must be gone.  Four new
      // distinct IDs in EACH direction can again be admitted.  If the old A/B
      // entries survived reset, the fourth new distinct ID reaches the A3
      // boundary one entry too early and this phase fails.
      issue_read(4'h1, 32'h5100_0100, 8'd0, 256, "F1/A3", tmp_mid);
      issue_read(4'h2, 32'h5100_0200, 8'd0, 256, "F1/A3", tmp_mid);
      issue_read(4'h3, 32'h5100_0300, 8'd0, 256, "F1/A3", tmp_mid);
      issue_read(4'h4, 32'h5100_0400, 8'd0, 256, "F1/A3", tmp_mid);

      issue_write(4'h5, 32'h5200_0500, 8'd0, 256, "F1/A3", tmp_mid);
      send_w_checked(32'h5200_0005, 4'b1111, 1'b1);
      issue_write(4'h6, 32'h5200_0600, 8'd0, 256, "F1/A3", tmp_mid);
      send_w_checked(32'h5200_0006, 4'b1111, 1'b1);
      issue_write(4'h7, 32'h5200_0700, 8'd0, 256, "F1/A3", tmp_mid);
      send_w_checked(32'h5200_0007, 4'b1111, 1'b1);
      issue_write(4'h8, 32'h5200_0800, 8'd0, 256, "F1/A3", tmp_mid);
      send_w_checked(32'h5200_0008, 4'b1111, 1'b1);
    end
  endtask

  // ---------------------------------------------------------------------------
  // Initialisation, watchdog, and top-level sequence
  // ---------------------------------------------------------------------------
  initial begin
    verdict_done = 1'b0;
    tb_cycle = 0;
    reset_low_edges = 0;

    s_awid = '0;
    s_awaddr = '0;
    s_awlen = '0;
    s_awvalid = 1'b0;
    s_wdata = '0;
    s_wstrb = '0;
    s_wlast = 1'b0;
    s_wvalid = 1'b0;
    s_bready = 1'b1;
    s_arid = '0;
    s_araddr = '0;
    s_arlen = '0;
    s_arvalid = 1'b0;
    s_rready = 1'b1;

    m_awready = 1'b1;
    m_wready = 1'b1;
    m_bid = '0;
    m_bresp = '0;
    m_bvalid = 1'b0;
    m_arready = 1'b1;
    m_rid = '0;
    m_rdata = '0;
    m_rresp = '0;
    m_rlast = 1'b0;
    m_rvalid = 1'b0;

    rd_addr_exp_valid = 1'b0;
    rd_addr_exp_accepted = 1'b0;
    wr_addr_exp_valid = 1'b0;
    wr_addr_exp_accepted = 1'b0;
    rd_resp_exp_valid = 1'b0;
    wr_resp_exp_valid = 1'b0;
    allow_unexpected_master_resp = 1'b0;
    rd_master_seq = 0;
    wr_master_seq = 0;
    rd_resp_seq = 0;
    wr_resp_seq = 0;
    rd_resp_owed = 0;
    wr_resp_owed = 0;
    wq_head = 0;
    wq_tail = 0;
    w_forward_seq = 0;
  end

  initial begin
    #4_000_000;
    if (!verdict_done) begin
      verdict_done = 1'b1;
      $display("FAIL [G1]: watchdog expired before a verdict");
      $display("RESULT: FAIL");
      $finish;
    end
  end

  initial begin
    // Begin after time-zero initialisation has settled.
    repeat (2) @(negedge clk);

    test_read_capacity();
    test_write_capacity_and_data();
    test_payload_and_ordering();
    test_reset_discard();

    if (wq_head != wq_tail)
      fail_clause("B3/D4", "write-data beats remained unforwarded at the end of the test");

    if (rd_resp_owed != 0)
      fail_clause("D4", "master read responses remained unmatched at the end of the test");

    if (wr_resp_owed != 0)
      fail_clause("D4", "master write responses remained unmatched at the end of the test");

    if (!verdict_done) begin
      verdict_done = 1'b1;
      $display("RESULT: PASS");
      $finish;
    end
  end

endmodule