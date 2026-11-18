module id_width_conv_tb;

  localparam int unsigned SLV_ID_W        = 4;
  localparam int unsigned MST_ID_W        = 2;
  localparam int unsigned ADDR_W          = 32;
  localparam int unsigned DATA_W          = 32;
  localparam int unsigned MAX_UNIQ_IDS    = 4;
  localparam int unsigned MAX_TXNS_PER_ID = 2;
  localparam int unsigned NIDS            = 1 << SLV_ID_W;
  localparam int unsigned NMIDS           = 1 << MST_ID_W;

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
    $display("FAIL G1: watchdog expired");
    $display("RESULT: FAIL");
    $finish;
  end

  // ---------------------------------------------------------------------------
  // Transaction model.
  // ---------------------------------------------------------------------------

  typedef struct {
    int              sid;
    logic [31:0]     addr;
    logic [7:0]      len;
    int              mid;
    int              beat;
  } rd_txn_t;

  typedef struct {
    int              sid;
    logic [31:0]     addr;
    logic [7:0]      len;
    int              mid;
  } wr_txn_t;

  typedef struct {
    int              sid;
    logic [31:0]     addr;
    logic [7:0]      len;
    int              mid;
    bit              served;
  } mrd_txn_t;

  typedef struct {
    int              sid;
    logic [31:0]     addr;
    logic [7:0]      len;
    int              mid;
    bit              served;
  } mwr_txn_t;

  typedef struct {
    logic [31:0]     data;
    logic [3:0]      strb;
    logic            last;
  } wbeat_t;

  rd_txn_t  rd_q[NIDS][$];
  wr_txn_t  wr_q[NIDS][$];
  rd_txn_t  rd_pend[$];
  wr_txn_t  wr_pend[$];
  mrd_txn_t mrd_q[$];
  mwr_txn_t mwr_q[$];
  wbeat_t   wexp[$];

  int mid_sid_r[NMIDS];
  int mid_sid_w[NMIDS];
  int mid_ref_r[NMIDS];
  int mid_ref_w[NMIDS];

  bit normal_enable = 1'b0;
  bit f1_guard      = 1'b0;
  bit auto_respond  = 1'b0;

  int cyc = 0;
  int addr_seq = 0;

  int last_ar_acc_cyc = -1;
  int last_aw_acc_cyc = -1;
  int last_r_retire_cyc = -1;
  int last_b_retire_cyc = -1;
  logic [31:0] last_ar_acc_addr = 0;
  logic [31:0] last_aw_acc_addr = 0;

  task automatic die(input string requirement, input string message);
    begin
      $display("FAIL %s: %s", requirement, message);
      $display("RESULT: FAIL");
      $finish;
    end
  endtask

  function automatic logic [31:0] make_addr(input int n);
    make_addr = 32'h0001_0000 + n * 32'h20;
  endfunction

  function automatic logic [31:0] expected_rdata(
    input logic [31:0] addr,
    input int          beat
  );
    expected_rdata = addr ^ 32'h5a00_0000 ^ beat;
  endfunction

  function automatic int distinct_reads();
    automatic int i;
    automatic int n;
    begin
      n = 0;
      for (i = 0; i < NIDS; i++) begin
        if (rd_q[i].size() != 0) n++;
      end
      distinct_reads = n;
    end
  endfunction

  function automatic int distinct_writes();
    automatic int i;
    automatic int n;
    begin
      n = 0;
      for (i = 0; i < NIDS; i++) begin
        if (wr_q[i].size() != 0) n++;
      end
      distinct_writes = n;
    end
  endfunction

  function automatic bit model_drained();
    automatic int i;
    automatic bit empty;
    begin
      empty = 1'b1;
      for (i = 0; i < NIDS; i++) begin
        if (rd_q[i].size() != 0) empty = 1'b0;
        if (wr_q[i].size() != 0) empty = 1'b0;
      end
      if (rd_pend.size() != 0) empty = 1'b0;
      if (wr_pend.size() != 0) empty = 1'b0;
      if (wexp.size() != 0) empty = 1'b0;
      model_drained = empty;
    end
  endfunction

  task automatic model_init;
    automatic int i;
    begin
      for (i = 0; i < NIDS; i++) begin
        rd_q[i].delete();
        wr_q[i].delete();
      end
      rd_pend.delete();
      wr_pend.delete();
      mrd_q.delete();
      mwr_q.delete();
      wexp.delete();
      for (i = 0; i < NMIDS; i++) begin
        mid_sid_r[i] = -1;
        mid_sid_w[i] = -1;
        mid_ref_r[i] = 0;
        mid_ref_w[i] = 0;
      end
    end
  endtask

  // ---------------------------------------------------------------------------
  // Scoreboard and protocol checks.
  // ---------------------------------------------------------------------------

  always @(posedge clk) begin : scoreboard
    automatic int i;
    automatic int j;
    automatic int idx;
    automatic int old_mid;
    automatic rd_txn_t rt;
    automatic wr_txn_t wt;
    automatic mrd_txn_t mrt;
    automatic mwr_txn_t mwt;
    automatic wbeat_t wb;

    cyc = cyc + 1;

    if (!rst_n) begin
      if (s_bvalid) die("F1", "s_bvalid asserted during reset");
      if (s_rvalid) die("F1", "s_rvalid asserted during reset");
    end else if (f1_guard) begin
      if (s_bvalid || s_rvalid)
        die("F1", "a discarded transaction produced a slave response");
      if (m_awvalid || m_arvalid || m_wvalid)
        die("F1", "a discarded transaction was forwarded after reset");
    end else if (normal_enable) begin

      // Retire responses first: reuse on the retiring edge is legal.
      if (s_rvalid) begin
        if (rd_q[s_rid].size() == 0)
          die("C2", "read response has no outstanding transaction for its slave ID");

        rt = rd_q[s_rid][0];
        if (s_rdata !== expected_rdata(rt.addr, rt.beat))
          die("E1/B1", "read data was altered or returned out of per-ID order");
        if (s_rresp !== 2'b00)
          die("E1", "read response code was altered");
        if (s_rlast !== (rt.beat == rt.len))
          die("E1", "read last indication was altered");

        if (s_rready && s_rlast) begin
          old_mid = rt.mid;
          rd_q[s_rid].pop_front();
          if (old_mid >= 0) begin
            mid_ref_r[old_mid]--;
            if (mid_ref_r[old_mid] == 0)
              mid_sid_r[old_mid] = -1;
          end
          last_r_retire_cyc = cyc;
        end else if (s_rready) begin
          rd_q[s_rid][0].beat = rt.beat + 1;
        end
      end

      if (s_bvalid) begin
        if (wr_q[s_bid].size() == 0)
          die("C2", "write response has no outstanding transaction for its slave ID");
        if (s_bresp !== 2'b00)
          die("E1", "write response code was altered");

        if (s_bready) begin
          wt = wr_q[s_bid][0];
          old_mid = wt.mid;
          wr_q[s_bid].pop_front();
          if (old_mid >= 0) begin
            mid_ref_w[old_mid]--;
            if (mid_ref_w[old_mid] == 0)
              mid_sid_w[old_mid] = -1;
          end
          last_b_retire_cyc = cyc;
        end
      end

      // Slave address acceptance defines the outstanding-set boundaries.
      if (s_arvalid && s_arready) begin
        if (rd_q[s_arid].size() >= MAX_TXNS_PER_ID)
          die("A5", "too many outstanding reads for one slave ID");
        if ((rd_q[s_arid].size() == 0) &&
            (distinct_reads() >= MAX_UNIQ_IDS))
          die("A3/D1", "a new slave ID was accepted while the read table was full");

        rt.sid  = s_arid;
        rt.addr = s_araddr;
        rt.len  = s_arlen;
        rt.mid  = -1;
        rt.beat = 0;
        rd_q[s_arid].push_back(rt);
        rd_pend.push_back(rt);
        last_ar_acc_cyc = cyc;
        last_ar_acc_addr = s_araddr;
      end

      if (s_awvalid && s_awready) begin
        if (wr_q[s_awid].size() >= MAX_TXNS_PER_ID)
          die("A5", "too many outstanding writes for one slave ID");
        if ((wr_q[s_awid].size() == 0) &&
            (distinct_writes() >= MAX_UNIQ_IDS))
          die("A3/D1", "a new slave ID was accepted while the write table was full");

        wt.sid  = s_awid;
        wt.addr = s_awaddr;
        wt.len  = s_awlen;
        wt.mid  = -1;
        wr_q[s_awid].push_back(wt);
        wr_pend.push_back(wt);
        last_aw_acc_cyc = cyc;
        last_aw_acc_addr = s_awaddr;
      end

      // Write data is expected in slave address-acceptance order.
      if (s_wvalid && s_wready) begin
        wb.data = s_wdata;
        wb.strb = s_wstrb;
        wb.last = s_wlast;
        wexp.push_back(wb);
      end

      // Match master addresses by the unique address assigned to each request.
      if (m_arvalid && m_arready) begin
        idx = -1;
        for (i = 0; i < rd_pend.size(); i++) begin
          if (rd_pend[i].addr == m_araddr) begin
            idx = i;
            break;
          end
        end
        if (idx < 0)
          die("D4", "master read address does not correspond one-to-one to a slave request");
        if (m_arlen !== rd_pend[idx].len)
          die("E1", "master read length differs from the slave request");

        rt = rd_pend[idx];
        if ((mid_sid_r[m_arid] != -1) && (mid_sid_r[m_arid] != rt.sid))
          die("D1/D2", "master read ID is shared by different co-outstanding slave IDs");

        mid_sid_r[m_arid] = rt.sid;
        mid_ref_r[m_arid]++;
        rt.mid = m_arid;

        for (j = 0; j < rd_q[rt.sid].size(); j++) begin
          if (rd_q[rt.sid][j].addr == rt.addr)
            rd_q[rt.sid][j].mid = m_arid;
        end

        mrt.sid = rt.sid;
        mrt.addr = rt.addr;
        mrt.len = rt.len;
        mrt.mid = m_arid;
        mrt.served = 1'b0;
        mrd_q.push_back(mrt);
        rd_pend.delete(idx);
      end

      if (m_awvalid && m_awready) begin
        idx = -1;
        for (i = 0; i < wr_pend.size(); i++) begin
          if (wr_pend[i].addr == m_awaddr) begin
            idx = i;
            break;
          end
        end
        if (idx < 0)
          die("D4", "master write address does not correspond one-to-one to a slave request");
        if (m_awlen !== wr_pend[idx].len)
          die("E1", "master write length differs from the slave request");

        wt = wr_pend[idx];
        if ((mid_sid_w[m_awid] != -1) && (mid_sid_w[m_awid] != wt.sid))
          die("D1/D2", "master write ID is shared by different co-outstanding slave IDs");

        mid_sid_w[m_awid] = wt.sid;
        mid_ref_w[m_awid]++;
        wt.mid = m_awid;

        for (j = 0; j < wr_q[wt.sid].size(); j++) begin
          if (wr_q[wt.sid][j].addr == wt.addr)
            wr_q[wt.sid][j].mid = m_awid;
        end

        mwt.sid = wt.sid;
        mwt.addr = wt.addr;
        mwt.len = wt.len;
        mwt.mid = m_awid;
        mwt.served = 1'b0;
        mwr_q.push_back(mwt);
        wr_pend.delete(idx);
      end

      if (m_wvalid && m_wready) begin
        if (wexp.size() == 0)
          die("D4/B3", "unexpected or duplicated master write-data beat");
        wb = wexp.pop_front();
        if ((m_wdata !== wb.data) ||
            (m_wstrb !== wb.strb) ||
            (m_wlast !== wb.last))
          die("E1/B3", "write data was altered, interleaved, or forwarded out of order");
      end
    end
  end

  // ---------------------------------------------------------------------------
  // Downstream response selection.
  // ---------------------------------------------------------------------------

  task automatic wait_read_master(input int sid);
    automatic int n;
    automatic int i;
    automatic bit found;
    begin
      found = 1'b0;
      n = 0;
      while (!found && (n < 200)) begin
        for (i = 0; i < mrd_q.size(); i++) begin
          if (mrd_q[i].sid == sid) found = 1'b1;
        end
        if (!found) begin
          @(negedge clk);
          n++;
        end
      end
      if (!found) die("D4", "accepted read was not forwarded to the master port");
    end
  endtask

  task automatic wait_write_master(input int sid);
    automatic int n;
    automatic int i;
    automatic bit found;
    begin
      found = 1'b0;
      n = 0;
      while (!found && (n < 200)) begin
        for (i = 0; i < mwr_q.size(); i++) begin
          if (mwr_q[i].sid == sid) found = 1'b1;
        end
        if (!found) begin
          @(negedge clk);
          n++;
        end
      end
      if (!found) die("D4", "accepted write was not forwarded to the master port");
    end
  endtask

  task automatic respond_read_sid(input int sid);
    automatic int i;
    automatic int b;
    automatic int idx;
    automatic mrd_txn_t t;
    begin
      idx = -1;
      for (i = 0; i < mrd_q.size(); i++) begin
        if (!mrd_q[i].served && (mrd_q[i].sid == sid)) begin
          idx = i;
          break;
        end
      end
      if (idx < 0) die("D4", "no forwarded read available for a planned response");
      t = mrd_q[idx];
      mrd_q[idx].served = 1'b1;
      for (b = 0; b <= t.len; b++) begin
        bfm_rbeat(t.mid[MST_ID_W-1:0],
                  expected_rdata(t.addr, b),
                  (b == t.len));
      end
    end
  endtask

  task automatic respond_write_sid(input int sid);
    automatic int i;
    automatic int idx;
    automatic mwr_txn_t t;
    begin
      idx = -1;
      for (i = 0; i < mwr_q.size(); i++) begin
        if (!mwr_q[i].served && (mwr_q[i].sid == sid)) begin
          idx = i;
          break;
        end
      end
      if (idx < 0) die("D4", "no forwarded write available for a planned response");
      t = mwr_q[idx];
      mwr_q[idx].served = 1'b1;
      bfm_bbeat(t.mid[MST_ID_W-1:0]);
    end
  endtask

  initial begin : automatic_response_process
    automatic int i;
    automatic int selected_sid;
    automatic bit found;
    forever begin
      @(negedge clk);
      if (auto_respond && normal_enable && rst_n) begin
        found = 1'b0;
        selected_sid = 0;
        for (i = 0; i < mwr_q.size(); i++) begin
          if (!found && !mwr_q[i].served) begin
            found = 1'b1;
            selected_sid = mwr_q[i].sid;
          end
        end
        if (found) begin
          respond_write_sid(selected_sid);
        end else begin
          for (i = 0; i < mrd_q.size(); i++) begin
            if (!found && !mrd_q[i].served) begin
              found = 1'b1;
              selected_sid = mrd_q[i].sid;
            end
          end
          if (found) respond_read_sid(selected_sid);
        end
      end
    end
  end

  task automatic drain_all;
    automatic int n;
    begin
      @(negedge clk);
      auto_respond = 1'b1;
      n = 0;
      while (!model_drained() && (n < 2000)) begin
        @(negedge clk);
        n++;
      end
      if (!model_drained())
        die("D4", "transactions did not drain one-for-one");
      @(negedge clk);
      auto_respond = 1'b0;
    end
  endtask

  task automatic offer_ar_ok(input int sid, input int len);
    automatic bit accepted;
    automatic int waited;
    automatic logic [31:0] a;
    begin
      a = make_addr(addr_seq);
      addr_seq++;
      bfm_ar(sid[SLV_ID_W-1:0], a, len[7:0], 40, accepted, waited);
      if (!accepted) die("A3", "a read that should be accepted was refused");
    end
  endtask

  task automatic offer_aw_ok(input int sid, input int len);
    automatic bit accepted;
    automatic int waited;
    automatic logic [31:0] a;
    automatic int b;
    begin
      a = make_addr(addr_seq);
      addr_seq++;
      bfm_aw(sid[SLV_ID_W-1:0], a, len[7:0], 40, accepted, waited);
      if (!accepted) die("A3", "a write that should be accepted was refused");
      for (b = 0; b <= len; b++)
        bfm_w(a ^ 32'hc000_0000 ^ b, 4'hf, (b == len));
    end
  endtask

  // ---------------------------------------------------------------------------
  // Directed verification.
  // ---------------------------------------------------------------------------

  task automatic run_tests;
    automatic bit accepted;
    automatic int waited;
    automatic int old_mid_r;
    automatic int old_mid_w;
    automatic logic [31:0] a;
    automatic logic [31:0] blocked_a;
    automatic int i;
    begin
      // Requests offered throughout reset may handshake, but must be discarded.
      repeat (2) @(posedge clk);
      @(negedge clk);
      s_awid = 4'd2;
      s_awaddr = 32'h0000_2000;
      s_awlen = 0;
      s_awvalid = 1'b1;
      s_arid = 4'd3;
      s_araddr = 32'h0000_3000;
      s_arlen = 0;
      s_arvalid = 1'b1;
      s_wdata = 32'h1234_5678;
      s_wstrb = 4'hf;
      s_wlast = 1'b1;
      s_wvalid = 1'b1;
      repeat (5) @(posedge clk);
      @(negedge clk);
      s_awvalid = 1'b0;
      s_arvalid = 1'b0;
      s_wvalid = 1'b0;
      f1_guard = 1'b1;
      rst_n = 1'b1;
      repeat (10) @(posedge clk);
      @(negedge clk);
      f1_guard = 1'b0;

      // Create genuine pre-reset outstanding transactions.
      model_init();
      normal_enable = 1'b1;
      offer_ar_ok(7, 0);
      offer_aw_ok(7, 0);
      wait_read_master(7);
      wait_write_master(7);
      old_mid_r = mrd_q[0].mid;
      old_mid_w = mwr_q[0].mid;

      @(negedge clk);
      normal_enable = 1'b0;
      rst_n = 1'b0;
      repeat (4) @(posedge clk);
      @(negedge clk);
      f1_guard = 1'b1;
      rst_n = 1'b1;
      m_rid = old_mid_r[MST_ID_W-1:0];
      m_rdata = expected_rdata(make_addr(0), 0);
      m_rresp = 2'b00;
      m_rlast = 1'b1;
      m_rvalid = 1'b1;
      m_bid = old_mid_w[MST_ID_W-1:0];
      m_bresp = 2'b00;
      m_bvalid = 1'b1;
      repeat (3) @(posedge clk);
      @(negedge clk);
      m_rvalid = 1'b0;
      m_bvalid = 1'b0;
      repeat (10) @(posedge clk);
      @(negedge clk);
      f1_guard = 1'b0;

      // A3 read boundary: three, then the fourth distinct ID must be accepted.
      model_init();
      normal_enable = 1'b1;
      offer_ar_ok(0, 0);
      offer_ar_ok(1, 0);
      offer_ar_ok(2, 0);
      offer_ar_ok(3, 0);

      // A3 does not block an already-present ID below its per-ID depth.
      offer_ar_ok(1, 0);

      blocked_a = make_addr(addr_seq);
      addr_seq++;
      bfm_ar(4, blocked_a, 0, 6, accepted, waited);
      if (accepted)
        die("A3", "fifth distinct read ID was accepted without a retirement");

      // A4: the fifth ID is offered continuously across retirement of ID zero.
      wait_read_master(0);
      a = make_addr(addr_seq);
      addr_seq++;
      fork
        begin
          bfm_ar(4, a, 0, 150, accepted, waited);
        end
        begin
          repeat (3) @(negedge clk);
          respond_read_sid(0);
        end
      join
      if (!accepted)
        die("A4", "new read ID was not accepted after an entry retired");
      if (last_ar_acc_addr !== a)
        die("A3", "unexpected read address acceptance during A4 test");
      if (last_ar_acc_cyc < last_r_retire_cyc)
        die("A3", "new read ID was accepted before an entry retired");
      if ((last_ar_acc_cyc - last_r_retire_cyc) > 2)
        die("A4", "new read ID acceptance exceeded the two-cycle window");
      drain_all();

      // A3/A4 write boundary, independently of the read side.
      offer_aw_ok(8, 0);
      offer_aw_ok(9, 0);
      offer_aw_ok(10, 0);
      offer_aw_ok(11, 0);
      offer_aw_ok(9, 0);

      blocked_a = make_addr(addr_seq);
      addr_seq++;
      bfm_aw(12, blocked_a, 0, 6, accepted, waited);
      if (accepted)
        die("A3", "fifth distinct write ID was accepted without a retirement");

      wait_write_master(8);
      a = make_addr(addr_seq);
      addr_seq++;
      fork
        begin
          bfm_aw(12, a, 0, 150, accepted, waited);
        end
        begin
          repeat (3) @(negedge clk);
          respond_write_sid(8);
        end
      join
      if (!accepted)
        die("A4", "new write ID was not accepted after an entry retired");
      if (!accepted) die("A4", "missing write acceptance");
      bfm_w(a ^ 32'hc000_0000, 4'hf, 1'b1);
      if (last_aw_acc_addr !== a)
        die("A3", "unexpected write address acceptance during A4 test");
      if (last_aw_acc_cyc < last_b_retire_cyc)
        die("A3", "new write ID was accepted before an entry retired");
      if ((last_aw_acc_cyc - last_b_retire_cyc) > 2)
        die("A4", "new write ID acceptance exceeded the two-cycle window");
      drain_all();

      // A5 read depth and B1/E1 with multiple beats per transaction.
      offer_ar_ok(5, 1);
      offer_ar_ok(5, 0);
      blocked_a = make_addr(addr_seq);
      addr_seq++;
      bfm_ar(5, blocked_a, 0, 6, accepted, waited);
      if (accepted)
        die("A5", "third co-outstanding read for one slave ID was accepted");

      // A different ID remains legal while one ID is at its depth limit.
      offer_ar_ok(6, 0);

      wait_read_master(5);
      a = make_addr(addr_seq);
      addr_seq++;
      fork
        begin
          bfm_ar(5, a, 0, 150, accepted, waited);
        end
        begin
          repeat (3) @(negedge clk);
          respond_read_sid(5);
        end
      join
      if (!accepted)
        die("A5", "read ID remained blocked after one of its transactions completed");
      drain_all();

      // A5 write depth, including a two-beat write for B3/E1.
      offer_aw_ok(13, 1);
      offer_aw_ok(13, 0);
      blocked_a = make_addr(addr_seq);
      addr_seq++;
      bfm_aw(13, blocked_a, 0, 6, accepted, waited);
      if (accepted)
        die("A5", "third co-outstanding write for one slave ID was accepted");

      offer_aw_ok(14, 0);
      wait_write_master(13);
      a = make_addr(addr_seq);
      addr_seq++;
      fork
        begin
          bfm_aw(13, a, 0, 150, accepted, waited);
        end
        begin
          repeat (3) @(negedge clk);
          respond_write_sid(13);
        end
      join
      if (!accepted)
        die("A5", "write ID remained blocked after one of its transactions completed");
      bfm_w(a ^ 32'hc000_0000, 4'hf, 1'b1);
      drain_all();

      // Allow duplicated or late responses to become visible.
      repeat (5) @(posedge clk);
      for (i = 0; i < NMIDS; i++) begin
        if ((mid_ref_r[i] != 0) || (mid_ref_w[i] != 0))
          die("D2", "master ID lifetime model did not return to empty");
      end

      $display("RESULT: PASS");
      $finish;
    end
  endtask

  initial begin
    s_awid = 0;
    s_awaddr = 0;
    s_awlen = 0;
    s_awvalid = 0;
    s_wdata = 0;
    s_wstrb = 0;
    s_wlast = 0;
    s_wvalid = 0;
    s_bready = 1'b1;
    s_arid = 0;
    s_araddr = 0;
    s_arlen = 0;
    s_arvalid = 0;
    s_rready = 1'b1;

    m_awready = 1'b1;
    m_wready = 1'b1;
    m_bid = 0;
    m_bresp = 0;
    m_bvalid = 0;
    m_arready = 1'b1;
    m_rid = 0;
    m_rdata = 0;
    m_rresp = 0;
    m_rlast = 0;
    m_rvalid = 0;

    model_init();
    run_tests();
  end

endmodule
