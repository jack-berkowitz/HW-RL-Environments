module id_width_conv_tb;

  localparam int unsigned SLV_ID_W        = 4;
  localparam int unsigned MST_ID_W        = 2;
  localparam int unsigned ADDR_W          = 32;
  localparam int unsigned DATA_W          = 32;
  localparam int unsigned MAX_UNIQ_IDS    = 4;
  localparam int unsigned MAX_TXNS_PER_ID = 2;
  localparam int unsigned MAX_TXNS        = 256;

  logic clk;
  logic rst_n;

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
    .SLV_ID_W        (SLV_ID_W),
    .MST_ID_W        (MST_ID_W),
    .ADDR_W          (ADDR_W),
    .DATA_W          (DATA_W),
    .MAX_UNIQ_IDS    (MAX_UNIQ_IDS),
    .MAX_TXNS_PER_ID (MAX_TXNS_PER_ID)
  ) dut (
    .clk_i     (clk),
    .rst_ni    (rst_n),
    .s_awid    (s_awid),
    .s_awaddr  (s_awaddr),
    .s_awlen   (s_awlen),
    .s_awvalid (s_awvalid),
    .s_awready (s_awready),
    .s_wdata   (s_wdata),
    .s_wstrb   (s_wstrb),
    .s_wlast   (s_wlast),
    .s_wvalid  (s_wvalid),
    .s_wready  (s_wready),
    .s_bid     (s_bid),
    .s_bresp   (s_bresp),
    .s_bvalid  (s_bvalid),
    .s_bready  (s_bready),
    .s_arid    (s_arid),
    .s_araddr  (s_araddr),
    .s_arlen   (s_arlen),
    .s_arvalid (s_arvalid),
    .s_arready (s_arready),
    .s_rid     (s_rid),
    .s_rdata   (s_rdata),
    .s_rresp   (s_rresp),
    .s_rlast   (s_rlast),
    .s_rvalid  (s_rvalid),
    .s_rready  (s_rready),
    .m_awid    (m_awid),
    .m_awaddr  (m_awaddr),
    .m_awlen   (m_awlen),
    .m_awvalid (m_awvalid),
    .m_awready (m_awready),
    .m_wdata   (m_wdata),
    .m_wstrb   (m_wstrb),
    .m_wlast   (m_wlast),
    .m_wvalid  (m_wvalid),
    .m_wready  (m_wready),
    .m_bid     (m_bid),
    .m_bresp   (m_bresp),
    .m_bvalid  (m_bvalid),
    .m_bready  (m_bready),
    .m_arid    (m_arid),
    .m_araddr  (m_araddr),
    .m_arlen   (m_arlen),
    .m_arvalid (m_arvalid),
    .m_arready (m_arready),
    .m_rid     (m_rid),
    .m_rdata   (m_rdata),
    .m_rresp   (m_rresp),
    .m_rlast   (m_rlast),
    .m_rvalid  (m_rvalid),
    .m_rready  (m_rready)
  );

  // -------------------------------------------------------------------------
  // PROVIDED PLUMBING
  // -------------------------------------------------------------------------
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

  // -------------------------------------------------------------------------
  // Transaction model
  // -------------------------------------------------------------------------
  typedef struct {
    logic [SLV_ID_W-1:0] sid;
    logic [MST_ID_W-1:0] mid;
    logic [ADDR_W-1:0]   addr;
    logic [7:0]          len;
    logic [DATA_W-1:0]   data_base;
    bit                  launched;
    bit                  active;
  } txn_t;

  typedef struct {
    int                  idx;
    int                  beat;
    logic [SLV_ID_W-1:0] sid;
    logic [DATA_W-1:0]   data;
    logic                last;
  } r_exp_t;

  typedef struct {
    int                  idx;
    logic [SLV_ID_W-1:0] sid;
  } b_exp_t;

  txn_t rt [0:MAX_TXNS-1];
  txn_t wt [0:MAX_TXNS-1];

  int rd_q [0:(1<<SLV_ID_W)-1][$];
  int wr_q [0:(1<<SLV_ID_W)-1][$];
  int w_order[$];
  r_exp_t exp_r[$];
  b_exp_t exp_b[$];

  int rd_accepted, wr_accepted;
  int rd_launched, wr_launched;
  int rd_outstanding, wr_outstanding;
  int w_pos, w_beat;
  int w_data_driven;
  int next_addr;
  int cycle;
  int errors;

  int drv_r_idx, drv_r_beat, drv_b_idx;
  bit stale_mode;

  int last_ar_accept_cycle, last_aw_accept_cycle;
  int last_rd_retire_cycle, last_wr_retire_cycle;

  bit acc;
  int waited;
  logic [MST_ID_W-1:0] old_rmid, old_bmid;

  task automatic fail(input string req, input string msg);
    errors++;
    $display("%s: %s (cycle %0d)", req, msg, cycle);
  endtask

  function automatic int rd_front(input int sid);
    if (rd_q[sid].size() != 0) rd_front = rd_q[sid][0];
    else                       rd_front = -1;
  endfunction

  function automatic int wr_front(input int sid);
    if (wr_q[sid].size() != 0) wr_front = wr_q[sid][0];
    else                       wr_front = -1;
  endfunction

  function automatic logic [DATA_W/8-1:0] strb_for(input int idx,
                                                    input int beat);
    case ((idx + beat) % 4)
      0: strb_for = 4'b1110;
      1: strb_for = 4'b1101;
      2: strb_for = 4'b1011;
      default: strb_for = 4'b0111;
    endcase
  endfunction

  task automatic offer_ar(input logic [SLV_ID_W-1:0] id,
                          input logic [7:0] len,
                          input int budget,
                          output bit accepted,
                          output int waited);
    automatic logic [ADDR_W-1:0] a;
    a = 32'h0010_0000 + next_addr * 32'h40;
    next_addr++;
    bfm_ar(id, a, len, budget, accepted, waited);
  endtask

  task automatic offer_aw(input logic [SLV_ID_W-1:0] id,
                          input logic [7:0] len,
                          input int budget,
                          output bit accepted,
                          output int waited);
    automatic logic [ADDR_W-1:0] a;
    a = 32'h0010_0000 + next_addr * 32'h40;
    next_addr++;
    bfm_aw(id, a, len, budget, accepted, waited);
  endtask

  task automatic send_pending_w;
    automatic int p;
    automatic int idx;
    automatic int b;
    for (p = w_data_driven; p < w_order.size(); p++) begin
      idx = w_order[p];
      for (b = 0; b <= wt[idx].len; b++) begin
        bfm_w(wt[idx].data_base + b, strb_for(idx, b),
              b == wt[idx].len);
      end
    end
    w_data_driven = w_order.size();
  endtask

  task automatic send_read_front(input int sid);
    automatic int idx;
    automatic int b;
    idx = rd_front(sid);
    if (idx < 0) begin
      fail("D4", "testbench could not find the read it intended to answer");
    end else begin
      for (b = 0; b <= rt[idx].len; b++) begin
        drv_r_idx = idx;
        drv_r_beat = b;
        bfm_rbeat(rt[idx].mid, rt[idx].data_base + b,
                  b == rt[idx].len);
      end
      drv_r_idx = -1;
    end
  endtask

  task automatic send_b_front(input int sid);
    automatic int idx;
    idx = wr_front(sid);
    if (idx < 0) begin
      fail("D4", "testbench could not find the write it intended to answer");
    end else begin
      drv_b_idx = idx;
      bfm_bbeat(wt[idx].mid);
      drv_b_idx = -1;
    end
  endtask

  task automatic wait_drained(input int budget);
    automatic int n;
    n = 0;
    while (((rd_outstanding != 0) || (wr_outstanding != 0) ||
            (exp_r.size() != 0) || (exp_b.size() != 0)) &&
           (n < budget)) begin
      @(negedge clk);
      n++;
    end
    if ((rd_outstanding != 0) || (wr_outstanding != 0) ||
        (exp_r.size() != 0) || (exp_b.size() != 0)) begin
      fail("D4", "accepted transactions or injected responses did not drain");
    end
  endtask

  // -------------------------------------------------------------------------
  // Scoreboard. Responses retire before new master identifiers are examined,
  // so reuse on the retiring edge itself is legal under A4/D2.
  // -------------------------------------------------------------------------
  always @(posedge clk) begin
    automatic int i;
    automatic int j;
    automatic int idx;
    automatic int found;
    automatic r_exp_t re;
    automatic b_exp_t be;

    cycle = cycle + 1;

    if (!rst_n) begin
      for (i = 0; i < (1<<SLV_ID_W); i++) begin
        rd_q[i].delete();
        wr_q[i].delete();
      end
      w_order.delete();
      exp_r.delete();
      exp_b.delete();
      rd_accepted = 0;
      wr_accepted = 0;
      rd_launched = 0;
      wr_launched = 0;
      rd_outstanding = 0;
      wr_outstanding = 0;
      w_pos = 0;
      w_beat = 0;
      w_data_driven = 0;
      drv_r_idx = -1;
      drv_b_idx = -1;

      if (s_bvalid)
        fail("F1", "s_bvalid was high while synchronous reset was asserted");
      if (s_rvalid)
        fail("F1", "s_rvalid was high while synchronous reset was asserted");
    end else begin
      // Record downstream responses injected by the testbench.
      if (m_rvalid && m_rready && !stale_mode) begin
        if ((drv_r_idx < 0) || !rt[drv_r_idx].active) begin
          fail("D4", "testbench response bookkeeping had no active read");
        end else begin
          re.idx  = drv_r_idx;
          re.beat = drv_r_beat;
          re.sid  = rt[drv_r_idx].sid;
          re.data = rt[drv_r_idx].data_base + drv_r_beat;
          re.last = (drv_r_beat == rt[drv_r_idx].len);
          exp_r.push_back(re);
        end
      end

      if (m_bvalid && m_bready && !stale_mode) begin
        if ((drv_b_idx < 0) || !wt[drv_b_idx].active) begin
          fail("D4", "testbench response bookkeeping had no active write");
        end else begin
          be.idx = drv_b_idx;
          be.sid = wt[drv_b_idx].sid;
          exp_b.push_back(be);
        end
      end

      // Slave read responses: C1/C2, E1, B1 and retirement.
      if (s_rvalid) begin
        if (stale_mode)
          fail("F1", "a pre-reset read produced a response after reset");

        if (exp_r.size() == 0) begin
          fail("C2", "read response had no corresponding outstanding response");
        end else begin
          re = exp_r[0];
          if (s_rid !== re.sid)
            fail("C1", "read response carried the wrong slave identifier");
          if (s_rdata !== re.data)
            fail("E1", "read data was modified");
          if (s_rresp !== 2'b00)
            fail("E1", "read response code was modified");
          if (s_rlast !== re.last)
            fail("E1", "read last indication was modified");

          if (s_rready) begin
            exp_r.pop_front();
            if (re.last) begin
              if ((s_rid == re.sid) && (rd_q[re.sid].size() != 0)) begin
                if (rd_q[re.sid][0] != re.idx) begin
                  fail("B1", "same-ID reads completed out of order");
                end else begin
                  rd_q[re.sid].pop_front();
                  rt[re.idx].active = 1'b0;
                  rd_outstanding--;
                  last_rd_retire_cycle = cycle;
                end
              end else begin
                fail("C2", "last read beat had no outstanding transaction");
              end
            end
          end
        end
      end

      // Slave write responses.
      if (s_bvalid) begin
        if (stale_mode)
          fail("F1", "a pre-reset write produced a response after reset");

        if (exp_b.size() == 0) begin
          fail("C2", "write response had no corresponding outstanding response");
        end else begin
          be = exp_b[0];
          if (s_bid !== be.sid)
            fail("C1", "write response carried the wrong slave identifier");

          if (s_bready) begin
            exp_b.pop_front();
            if ((s_bid == be.sid) && (wr_q[be.sid].size() != 0)) begin
              if (wr_q[be.sid][0] != be.idx) begin
                fail("B1", "same-ID writes completed out of order");
              end else begin
                wr_q[be.sid].pop_front();
                wt[be.idx].active = 1'b0;
                wr_outstanding--;
                last_wr_retire_cycle = cycle;
              end
            end else begin
              fail("C2", "write response had no outstanding transaction");
            end
          end
        end
      end

      // Slave address acceptance defines the start of outstanding lifetime.
      if (s_arvalid && s_arready) begin
        if (rd_accepted >= MAX_TXNS) begin
          fail("D4", "testbench transaction storage exhausted");
        end else begin
          idx = rd_accepted;
          rt[idx].sid = s_arid;
          rt[idx].addr = s_araddr;
          rt[idx].len = s_arlen;
          rt[idx].data_base = 32'h4000_0000 | s_araddr;
          rt[idx].launched = 1'b0;
          rt[idx].active = 1'b1;
          rd_q[s_arid].push_back(idx);
          rd_accepted++;
          rd_outstanding++;
          last_ar_accept_cycle = cycle;
        end
      end

      if (s_awvalid && s_awready) begin
        if (wr_accepted >= MAX_TXNS) begin
          fail("D4", "testbench transaction storage exhausted");
        end else begin
          idx = wr_accepted;
          wt[idx].sid = s_awid;
          wt[idx].addr = s_awaddr;
          wt[idx].len = s_awlen;
          wt[idx].data_base = 32'h8000_0000 ^ s_awaddr;
          wt[idx].launched = 1'b0;
          wt[idx].active = 1'b1;
          wr_q[s_awid].push_back(idx);
          w_order.push_back(idx);
          wr_accepted++;
          wr_outstanding++;
          last_aw_accept_cycle = cycle;
        end
      end

      // Master addresses: unique addresses let bookkeeping identify each one.
      if (m_arvalid && m_arready) begin
        found = -1;
        for (i = 0; i < rd_accepted; i++) begin
          if (!rt[i].launched && rt[i].active &&
              (rt[i].addr == m_araddr) && (rt[i].len == m_arlen)) begin
            found = i;
            break;
          end
        end
        if (found < 0) begin
          fail("D4", "unexpected, duplicate, or corrupted master read address");
        end else begin
          rt[found].launched = 1'b1;
          rt[found].mid = m_arid;
          rd_launched++;
          for (j = 0; j < rd_accepted; j++) begin
            if ((j != found) && rt[j].active && rt[j].launched &&
                (rt[j].sid != rt[found].sid) &&
                (rt[j].mid == m_arid)) begin
              fail("D1", "co-outstanding read IDs shared a master identifier");
              fail("D2", "master read identifier was reused before retirement");
            end
          end
        end
      end

      if (m_awvalid && m_awready) begin
        found = -1;
        for (i = 0; i < wr_accepted; i++) begin
          if (!wt[i].launched && wt[i].active &&
              (wt[i].addr == m_awaddr) && (wt[i].len == m_awlen)) begin
            found = i;
            break;
          end
        end
        if (found < 0) begin
          fail("D4", "unexpected, duplicate, or corrupted master write address");
        end else begin
          wt[found].launched = 1'b1;
          wt[found].mid = m_awid;
          wr_launched++;
          for (j = 0; j < wr_accepted; j++) begin
            if ((j != found) && wt[j].active && wt[j].launched &&
                (wt[j].sid != wt[found].sid) &&
                (wt[j].mid == m_awid)) begin
              fail("D1", "co-outstanding write IDs shared a master identifier");
              fail("D2", "master write identifier was reused before retirement");
            end
          end
        end
      end

      // Write data must follow global slave-address acceptance order.
      if (m_wvalid && m_wready) begin
        if (w_pos >= w_order.size()) begin
          fail("B3", "master write data had no corresponding accepted write");
        end else begin
          idx = w_order[w_pos];
          if (!wt[idx].launched)
            fail("B3", "write data preceded its master address transaction");
          if (m_wdata !== (wt[idx].data_base + w_beat))
            fail("E1", "write data was modified or attributed to another write");
          if (m_wstrb !== strb_for(idx, w_beat))
            fail("E1", "write strobes were modified");
          if (m_wlast !== (w_beat == wt[idx].len))
            fail("E1", "write last indication was modified");

          if (w_beat == wt[idx].len) begin
            w_beat = 0;
            w_pos++;
          end else begin
            w_beat++;
          end
        end
      end
    end
  end

  // -------------------------------------------------------------------------
  // Directed verification
  // -------------------------------------------------------------------------
  initial begin
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
    m_bresp = 2'b00;
    m_bvalid = 1'b0;
    m_arready = 1'b1;
    m_rid = '0;
    m_rdata = '0;
    m_rresp = 2'b00;
    m_rlast = 1'b0;
    m_rvalid = 1'b0;

    cycle = 0;
    errors = 0;
    next_addr = 1;
    stale_mode = 1'b0;
    drv_r_idx = -1;
    drv_b_idx = -1;
    last_ar_accept_cycle = -1000;
    last_aw_accept_cycle = -1000;
    last_rd_retire_cycle = -1000;
    last_wr_retire_cycle = -1000;

    bfm_reset(4);

    // ---------------- Writes: A2/A3/A5, D1/D2, B3 and E1 ----------------
    offer_aw(0, 1, 30, acc, waited);
    if (!acc) fail("A3", "first write identifier was refused");
    offer_aw(1, 0, 30, acc, waited);
    if (!acc) fail("A3", "second write identifier was refused");
    offer_aw(2, 2, 30, acc, waited);
    if (!acc) fail("A3", "third write identifier was refused");

    // At MAX_UNIQ_IDS-1, a fourth distinct identifier must be accepted.
    offer_aw(3, 0, 30, acc, waited);
    if (!acc) fail("A3", "new write ID was refused at MAX_UNIQ_IDS-1");

    // At the boundary, a fifth distinct identifier must wait.
    offer_aw(4, 0, 3, acc, waited);
    if (acc) fail("A3", "new write ID was accepted with a full table");

    // Full-table blocking does not apply to an already outstanding ID.
    offer_aw(0, 1, 30, acc, waited);
    if (!acc) fail("A3", "existing write ID was blocked by the full table");

    // But that ID is now at its per-ID depth.
    offer_aw(0, 0, 3, acc, waited);
    if (acc) fail("A5", "third same-ID write was accepted before completion");

    send_pending_w();

    // Offer a new ID continuously across retirement of ID 3.
    last_wr_retire_cycle = -1000;
    last_aw_accept_cycle = -1000;
    fork
      send_b_front(3);
      offer_aw(5, 1, 30, acc, waited);
    join
    if (!acc) begin
      fail("A4", "new write ID was not accepted after an entry retired");
    end else if ((last_wr_retire_cycle < 0) ||
                 ((last_aw_accept_cycle - last_wr_retire_cycle) > 2)) begin
      fail("A4", "new write ID acceptance exceeded the 2-cycle window");
    end

    // Completion of one same-ID transaction permits another, without assuming
    // any particular promptness beyond eventual acceptance.
    send_b_front(0);
    offer_aw(0, 0, 30, acc, waited);
    if (!acc) fail("A5", "same-ID write remained blocked after completion");

    send_pending_w();

    // Deliberately choose an order across identifiers; preserve order within
    // identifier 0.
    send_b_front(5);
    send_b_front(0);
    send_b_front(2);
    send_b_front(0);
    send_b_front(1);
    wait_drained(300);

    // ---------------- Reads: independent table and same boundaries ---------
    offer_ar(8,  1, 30, acc, waited);
    if (!acc) fail("A3", "first read identifier was refused");
    offer_ar(9,  0, 30, acc, waited);
    if (!acc) fail("A3", "second read identifier was refused");
    offer_ar(10, 1, 30, acc, waited);
    if (!acc) fail("A3", "third read identifier was refused");
    offer_ar(11, 2, 30, acc, waited);
    if (!acc) fail("A3", "new read ID was refused at MAX_UNIQ_IDS-1");

    offer_ar(12, 0, 3, acc, waited);
    if (acc) fail("A3", "new read ID was accepted with a full table");

    offer_ar(8, 0, 30, acc, waited);
    if (!acc) fail("A3", "existing read ID was blocked by the full table");

    offer_ar(8, 1, 3, acc, waited);
    if (acc) fail("A5", "third same-ID read was accepted before completion");

    // ID 11 has three beats; the request remains offered throughout them and
    // must be accepted no more than two cycles after its final beat retires.
    last_rd_retire_cycle = -1000;
    last_ar_accept_cycle = -1000;
    fork
      send_read_front(11);
      offer_ar(12, 1, 40, acc, waited);
    join
    if (!acc) begin
      fail("A4", "new read ID was not accepted after an entry retired");
    end else if ((last_rd_retire_cycle < 0) ||
                 ((last_ar_accept_cycle - last_rd_retire_cycle) > 2)) begin
      fail("A4", "new read ID acceptance exceeded the 2-cycle window");
    end

    send_read_front(8);
    offer_ar(8, 2, 30, acc, waited);
    if (!acc) fail("A5", "same-ID read remained blocked after completion");

    // Out-of-order completion between different slave IDs is legal and helps
    // ensure that restoration is based on bookkeeping rather than ID choice.
    send_read_front(9);
    send_read_front(10);
    send_read_front(8);
    send_read_front(12);
    send_read_front(8);
    wait_drained(300);

    // ---------------- Reset with live and reset-time transactions ----------
    offer_aw(2, 1, 30, acc, waited);
    if (!acc) fail("A3", "could not create pre-reset outstanding write");
    offer_ar(6, 1, 30, acc, waited);
    if (!acc) fail("A3", "could not create pre-reset outstanding read");
    send_pending_w();

    old_bmid = wt[wr_front(2)].mid;
    old_rmid = rt[rd_front(6)].mid;

    // Offer all three request types during reset. Handshakes are allowed, but
    // anything accepted must be discarded.
    @(negedge clk);
    rst_n = 1'b0;
    s_awid = 4'd13;
    s_awaddr = 32'h0020_0000;
    s_awlen = 0;
    s_awvalid = 1'b1;
    s_arid = 4'd14;
    s_araddr = 32'h0020_0040;
    s_arlen = 0;
    s_arvalid = 1'b1;
    s_wdata = 32'hdead_beef;
    s_wstrb = 4'hf;
    s_wlast = 1'b1;
    s_wvalid = 1'b1;
    repeat (4) @(posedge clk);
    @(negedge clk);
    s_awvalid = 1'b0;
    s_arvalid = 1'b0;
    s_wvalid = 1'b0;
    rst_n = 1'b1;

    // Present stale downstream responses for a fixed time. A correct design
    // need not accept them, and must never forward them to the slave port.
    stale_mode = 1'b1;
    @(negedge clk);
    m_rid = old_rmid;
    m_rdata = 32'h1234_5678;
    m_rresp = 2'b00;
    m_rlast = 1'b1;
    m_rvalid = 1'b1;
    m_bid = old_bmid;
    m_bresp = 2'b00;
    m_bvalid = 1'b1;
    repeat (3) @(posedge clk);
    @(negedge clk);
    m_rvalid = 1'b0;
    m_bvalid = 1'b0;
    stale_mode = 1'b0;
    repeat (4) @(posedge clk);

    // The table must be empty after reset: four distinct IDs in each direction
    // are again admissible.
    offer_aw(4, 0, 30, acc, waited);
    if (!acc) fail("A3", "write table was not empty after reset");
    offer_aw(5, 1, 30, acc, waited);
    if (!acc) fail("A3", "write table retained a pre-reset entry");
    offer_aw(6, 0, 30, acc, waited);
    if (!acc) fail("A3", "write table retained a pre-reset entry");
    offer_aw(7, 0, 30, acc, waited);
    if (!acc) fail("A3", "fourth post-reset write ID was refused");

    offer_ar(0, 0, 30, acc, waited);
    if (!acc) fail("A3", "read table was not empty after reset");
    offer_ar(1, 1, 30, acc, waited);
    if (!acc) fail("A3", "read table retained a pre-reset entry");
    offer_ar(2, 0, 30, acc, waited);
    if (!acc) fail("A3", "read table retained a pre-reset entry");
    offer_ar(3, 1, 30, acc, waited);
    if (!acc) fail("A3", "fourth post-reset read ID was refused");

    send_pending_w();

    send_read_front(3);
    send_read_front(1);
    send_read_front(2);
    send_read_front(0);
    send_b_front(7);
    send_b_front(5);
    send_b_front(4);
    send_b_front(6);
    wait_drained(300);

    if (rd_accepted != rd_launched)
      fail("D4", "not every accepted read produced one master read");
    if (wr_accepted != wr_launched)
      fail("D4", "not every accepted write produced one master write");
    if (w_pos != w_order.size())
      fail("D4", "not every accepted write produced its master write data");

    repeat (5) @(posedge clk);

    if (errors == 0)
      $display("RESULT: PASS");
    else
      $display("RESULT: FAIL");
    $finish;
  end

endmodule
