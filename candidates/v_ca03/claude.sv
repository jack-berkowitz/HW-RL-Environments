// ===========================================================================
//  id_width_conv_tb.sv
//
//  Self-checking testbench for id_width_conv.
//
//  Method
//  ------
//  The testbench keeps a model of the conversion table: which slave
//  identifiers are outstanding, how many transactions each holds, and which
//  master identifier each transaction was given.  Every clause that is about
//  the table (A2, A3, A4, A5, D1, D2) is checked against that model rather
//  than against any output value.
//
//  Every transaction is given a unique address and every read beat a unique
//  payload, so a master request or a slave response is attributed to the
//  transaction that produced it by BOOKKEEPING, never by matching on a value
//  that could repeat.
//
//  What is deliberately NOT checked
//  --------------------------------
//    D3   which master identifier is chosen, and in what order they are
//         allocated: the model only ever asks whether two co-outstanding
//         slave identifiers were given the SAME one.
//    lat  the number of cycles between a slave request and its master
//         request, or between a master response and its slave response.
//    rdy  the promptness of s_awready / s_arready anywhere except A4's
//         2-cycle window and A3's boundary.  Every "must be accepted" check
//         uses a generous budget, never an immediate one.
//    B2   the relative order of responses carrying different identifiers.
//    out  the value of any output while its valid is low.
//
//  As the downstream slave the testbench honours the one obligation AXI puts
//  on it: responses for a given master identifier are returned in the order
//  the requests arrived.  Across different master identifiers it reorders
//  freely, which is what puts B1 under real pressure.
// ===========================================================================
`timescale 1ns/1ps

module id_width_conv_tb;

  localparam int unsigned SLV_ID_W        = 4;
  localparam int unsigned MST_ID_W        = 2;
  localparam int unsigned ADDR_W          = 32;
  localparam int unsigned DATA_W          = 32;
  localparam int unsigned MAX_UNIQ_IDS    = 4;
  localparam int unsigned MAX_TXNS_PER_ID = 2;

  localparam int NMID = 1 << MST_ID_W;    // 4 master identifiers
  localparam int NSID = 1 << SLV_ID_W;    // 16 slave identifiers

  // ---- slave port ----------------------------------------------------------
  logic [SLV_ID_W-1:0]  s_awid;
  logic [ADDR_W-1:0]    s_awaddr;
  logic [7:0]           s_awlen;
  logic                 s_awvalid, s_awready;
  logic [DATA_W-1:0]    s_wdata;
  logic [DATA_W/8-1:0]  s_wstrb;
  logic                 s_wlast, s_wvalid, s_wready;
  logic [SLV_ID_W-1:0]  s_bid;
  logic [1:0]           s_bresp;
  logic                 s_bvalid, s_bready;
  logic [SLV_ID_W-1:0]  s_arid;
  logic [ADDR_W-1:0]    s_araddr;
  logic [7:0]           s_arlen;
  logic                 s_arvalid, s_arready;
  logic [SLV_ID_W-1:0]  s_rid;
  logic [DATA_W-1:0]    s_rdata;
  logic [1:0]           s_rresp;
  logic                 s_rlast, s_rvalid, s_rready;
  // ---- master port ---------------------------------------------------------
  logic [MST_ID_W-1:0]  m_awid;
  logic [ADDR_W-1:0]    m_awaddr;
  logic [7:0]           m_awlen;
  logic                 m_awvalid, m_awready;
  logic [DATA_W-1:0]    m_wdata;
  logic [DATA_W/8-1:0]  m_wstrb;
  logic                 m_wlast, m_wvalid, m_wready;
  logic [MST_ID_W-1:0]  m_bid;
  logic [1:0]           m_bresp;
  logic                 m_bvalid, m_bready;
  logic [MST_ID_W-1:0]  m_arid;
  logic [ADDR_W-1:0]    m_araddr;
  logic [7:0]           m_arlen;
  logic                 m_arvalid, m_arready;
  logic [MST_ID_W-1:0]  m_rid;
  logic [DATA_W-1:0]    m_rdata;
  logic [1:0]           m_rresp;
  logic                 m_rlast, m_rvalid, m_rready;

  id_width_conv #(
    .SLV_ID_W(SLV_ID_W), .MST_ID_W(MST_ID_W), .ADDR_W(ADDR_W), .DATA_W(DATA_W),
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
    .s_rid(s_rid), .s_rdata(s_rdata), .s_rresp(s_rresp), .s_rlast(s_rlast),
    .s_rvalid(s_rvalid), .s_rready(s_rready),
    .m_awid(m_awid), .m_awaddr(m_awaddr), .m_awlen(m_awlen),
    .m_awvalid(m_awvalid), .m_awready(m_awready),
    .m_wdata(m_wdata), .m_wstrb(m_wstrb), .m_wlast(m_wlast),
    .m_wvalid(m_wvalid), .m_wready(m_wready),
    .m_bid(m_bid), .m_bresp(m_bresp), .m_bvalid(m_bvalid), .m_bready(m_bready),
    .m_arid(m_arid), .m_araddr(m_araddr), .m_arlen(m_arlen),
    .m_arvalid(m_arvalid), .m_arready(m_arready),
    .m_rid(m_rid), .m_rdata(m_rdata), .m_rresp(m_rresp), .m_rlast(m_rlast),
    .m_rvalid(m_rvalid), .m_rready(m_rready));

  // -------------------------------------------------------------------------
  // PROVIDED PLUMBING -- moves transactions, checks nothing.
  // -------------------------------------------------------------------------

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

  // -------------------------------------------------------------------------
  // END OF PROVIDED PLUMBING -- everything below is the testbench proper.
  // -------------------------------------------------------------------------

  // Response beats with a resp code, so E1 covers `resp` as well.
  task automatic tb_rbeat(input logic [MST_ID_W-1:0] mid,
                          input logic [DATA_W-1:0]   data,
                          input logic                last,
                          input logic [1:0]          rsp);
    @(negedge clk);
    m_rid = mid; m_rdata = data; m_rlast = last; m_rresp = rsp; m_rvalid = 1'b1;
    forever begin @(posedge clk); if (m_rready) break; end
    @(negedge clk) m_rvalid = 1'b0;
  endtask

  task automatic tb_bbeat(input logic [MST_ID_W-1:0] mid, input logic [1:0] rsp);
    @(negedge clk);
    m_bid = mid; m_bresp = rsp; m_bvalid = 1'b1;
    forever begin @(posedge clk); if (m_bready) break; end
    @(negedge clk) m_bvalid = 1'b0;
  endtask

  // ---- verdict -------------------------------------------------------------
  int err_count = 0;
  int msg_count = 0;

  task automatic fail(input string clause, input string msg);
    err_count = err_count + 1;
    if (msg_count < 40) begin
      msg_count = msg_count + 1;
      $display("VIOLATION [%s] %s (cycle %0d)", clause, msg, cyc);
    end
  endtask

  // ---- the model -----------------------------------------------------------
  int cyc = 0;

  int  rd_q [NSID][$];              // outstanding read seqs, per slave id
  int  wr_q [NSID][$];              // outstanding write seqs, per slave id
  int  mid_rd_q [NMID][$];          // forwarded reads awaiting a response
  int  mid_wr_q [NMID][$];

  int  t_sid [int];                 // per transaction, keyed by its unique seq
  int  t_len [int];
  int  t_mid [int];
  int  t_fwd [int];
  int  t_wr  [int];
  int  rcv   [int];                 // read beats delivered so far
  int  b_sent[int];                 // master write response issued

  int  seq_of_addr [int];           // unique address -> seq
  int  seq_of_rdat [int];           // unique read payload -> seq
  int  beat_of_rdat[int];           // unique read payload -> beat index
  int  last_of_rdat[int];

  logic [DATA_W-1:0]   exp_wd [$];  // write beats seen on the slave port,
  logic [DATA_W/8-1:0] exp_ws [$];  // awaiting their appearance on the master
  logic                exp_wl [$];  // port, in the same order (B3, E1)

  int  aw_order_q [$];              // accepted writes awaiting their data

  int  ar_acc_cyc [NSID];           // when this id's last AR was accepted
  int  aw_acc_cyc [NSID];
  int  rd_ret_cyc [NSID];           // when this id last went fully outstanding-free
  int  wr_ret_cyc [NSID];

  int  seq_ctr   = 0;
  int  rdat_ctr  = 32'h5000_0000;
  int  wdat_ctr  = 32'h9000_0000;
  int  n_rd_done = 0, n_wr_done = 0;
  int  n_rd_acc  = 0, n_wr_acc  = 0;

  int  auto_resp = 1;               // background responder enabled
  int  rd_busy = 0, wr_busy = 0, w_busy = 0;
  int  f1_watch = 0;                // check that nothing leaks across a reset
  int  bp_on    = 0;                // response backpressure on the slave port

  // Driven off the sampling edge; the monitor reads these at the rising edge.
  always @(negedge clk) begin
    if (bp_on != 0) begin
      s_rready = ($urandom_range(0, 3) != 0);
      s_bready = ($urandom_range(0, 3) != 0);
    end
  end

  function automatic int rd_distinct();
    int i, n;
    n = 0;
    for (i = 0; i < NSID; i++) if (rd_q[i].size() != 0) n = n + 1;
    return n;
  endfunction

  function automatic int wr_distinct();
    int i, n;
    n = 0;
    for (i = 0; i < NSID; i++) if (wr_q[i].size() != 0) n = n + 1;
    return n;
  endfunction

  function automatic int rd_total();
    int i, n;
    n = 0;
    for (i = 0; i < NSID; i++) n = n + rd_q[i].size();
    return n;
  endfunction

  function automatic int wr_total();
    int i, n;
    n = 0;
    for (i = 0; i < NSID; i++) n = n + wr_q[i].size();
    return n;
  endfunction

  // ---- the monitor ---------------------------------------------------------
  // Order inside this block matters and is deliberate:
  //   completions first, so an identifier that retires on this edge has freed
  //   its entry before an acceptance on the same edge is judged (A4 measured
  //   zero cycles on a correct design);
  //   then slave-side acceptances and write beats, so a zero-latency design
  //   whose master request appears in the same cycle still finds its record;
  //   then the master side.
  always @(posedge clk) begin : mon_blk
    int i, sq, mm, bt, idx, other;
    logic [DATA_W-1:0]   wd;
    logic [DATA_W/8-1:0] ws;
    logic                wl;

    cyc = cyc + 1;

    if (!rst_n) begin
      if (cyc >= 3) begin
        if (s_rvalid === 1'b1) fail("F1", "s_rvalid is asserted while rst_ni is low");
        if (s_bvalid === 1'b1) fail("F1", "s_bvalid is asserted while rst_ni is low");
        if (s_arvalid === 1'b1 && s_arready === 1'b1)
          fail("F1", "a read address was accepted while rst_ni is low");
        if (s_awvalid === 1'b1 && s_awready === 1'b1)
          fail("F1", "a write address was accepted while rst_ni is low");
      end
    end else begin
      // =================== completions ====================================
      if (s_rvalid === 1'b1 && s_rready === 1'b1) begin
        if (f1_watch)
          fail("F1", "a read response was presented after reset for a transaction issued before it");
        if (!seq_of_rdat.exists(int'(s_rdata))) begin
          fail("E1/C2", $sformatf("read beat with payload %0h was never presented on the master port (payload altered, or a beat invented)",
                                  s_rdata));
        end else begin
          sq = seq_of_rdat[int'(s_rdata)];
          if (t_sid[sq] != int'(s_rid))
            fail("C1", $sformatf("read beat of the transaction issued with slave id %0d came back as id %0d",
                                 t_sid[sq], s_rid));
          if (rd_q[int'(s_rid)].size() == 0)
            fail("C2", $sformatf("read response on id %0d with no transaction outstanding on that id", s_rid));
          else if (rd_q[int'(s_rid)][0] != sq)
            fail("B1", $sformatf("id %0d returned the response of the transaction accepted at slot %0d before that of slot %0d, which was accepted first",
                                 s_rid, sq, rd_q[int'(s_rid)][0]));
          if (rcv[sq] != beat_of_rdat[int'(s_rdata)])
            fail("B1/D4", $sformatf("transaction %0d delivered beat %0d where beat %0d was due",
                                    sq, beat_of_rdat[int'(s_rdata)], rcv[sq]));
          if (s_rlast !== (last_of_rdat[int'(s_rdata)] ? 1'b1 : 1'b0))
            fail("E1", $sformatf("transaction %0d: rlast is %0b on beat %0d, it was presented as %0b on the master port",
                                 sq, s_rlast, beat_of_rdat[int'(s_rdata)], last_of_rdat[int'(s_rdata)]));
          if (s_rresp !== 2'b00 && s_rresp !== 2'b10)
            fail("E1", $sformatf("transaction %0d: rresp is %0b, which was never presented on the master port", sq, s_rresp));
          rcv[sq] = rcv[sq] + 1;
          if (s_rlast === 1'b1) begin
            if (rd_q[int'(s_rid)].size() != 0 && rd_q[int'(s_rid)][0] == sq) begin
              void'(rd_q[int'(s_rid)].pop_front());
              if (rd_q[int'(s_rid)].size() == 0) rd_ret_cyc[int'(s_rid)] = cyc;
            end
            n_rd_done = n_rd_done + 1;
          end
        end
      end

      if (s_bvalid === 1'b1 && s_bready === 1'b1) begin
        if (f1_watch)
          fail("F1", "a write response was presented after reset for a transaction issued before it");
        if (wr_q[int'(s_bid)].size() == 0) begin
          fail("C2", $sformatf("write response on id %0d with no transaction outstanding on that id", s_bid));
        end else begin
          sq = wr_q[int'(s_bid)][0];
          if (b_sent[sq] != 1)
            fail("B1/C2", $sformatf("write response on id %0d, but the oldest transaction outstanding on that id has had no master response yet",
                                    s_bid));
          void'(wr_q[int'(s_bid)].pop_front());
          if (wr_q[int'(s_bid)].size() == 0) wr_ret_cyc[int'(s_bid)] = cyc;
          n_wr_done = n_wr_done + 1;
        end
      end

      // =================== slave-side acceptances =========================
      if (s_arvalid === 1'b1 && s_arready === 1'b1) begin
        if (!seq_of_addr.exists(int'(s_araddr))) begin
          fail("D4", "an address was accepted that belongs to no offered transaction");
        end else begin
          sq = seq_of_addr[int'(s_araddr)];
          // A3: a NEW identifier may not be taken when the table is full
          if (rd_q[int'(s_arid)].size() == 0 && rd_distinct() >= int'(MAX_UNIQ_IDS))
            fail("A3", $sformatf("read id %0d accepted while %0d distinct read ids were already outstanding; the table holds %0d",
                                 s_arid, rd_distinct(), MAX_UNIQ_IDS));
          // A5: depth per identifier
          if (rd_q[int'(s_arid)].size() >= int'(MAX_TXNS_PER_ID))
            fail("A5", $sformatf("read id %0d accepted with %0d already outstanding on that id; the limit is %0d",
                                 s_arid, rd_q[int'(s_arid)].size(), MAX_TXNS_PER_ID));
          rd_q[int'(s_arid)].push_back(sq);
          ar_acc_cyc[int'(s_arid)] = cyc;
          n_rd_acc = n_rd_acc + 1;
          // A2
          if (rd_distinct() > int'(MAX_UNIQ_IDS))
            fail("A2", $sformatf("%0d distinct read ids outstanding, the table holds %0d", rd_distinct(), MAX_UNIQ_IDS));
        end
      end

      if (s_awvalid === 1'b1 && s_awready === 1'b1) begin
        if (!seq_of_addr.exists(int'(s_awaddr))) begin
          fail("D4", "an address was accepted that belongs to no offered transaction");
        end else begin
          sq = seq_of_addr[int'(s_awaddr)];
          if (wr_q[int'(s_awid)].size() == 0 && wr_distinct() >= int'(MAX_UNIQ_IDS))
            fail("A3", $sformatf("write id %0d accepted while %0d distinct write ids were already outstanding; the table holds %0d",
                                 s_awid, wr_distinct(), MAX_UNIQ_IDS));
          if (wr_q[int'(s_awid)].size() >= int'(MAX_TXNS_PER_ID))
            fail("A5", $sformatf("write id %0d accepted with %0d already outstanding on that id; the limit is %0d",
                                 s_awid, wr_q[int'(s_awid)].size(), MAX_TXNS_PER_ID));
          wr_q[int'(s_awid)].push_back(sq);
          aw_acc_cyc[int'(s_awid)] = cyc;
          aw_order_q.push_back(sq);
          n_wr_acc = n_wr_acc + 1;
          if (wr_distinct() > int'(MAX_UNIQ_IDS))
            fail("A2", $sformatf("%0d distinct write ids outstanding, the table holds %0d", wr_distinct(), MAX_UNIQ_IDS));
        end
      end

      // slave write beats: what the master port must reproduce, in this order
      if (s_wvalid === 1'b1 && s_wready === 1'b1) begin
        exp_wd.push_back(s_wdata);
        exp_ws.push_back(s_wstrb);
        exp_wl.push_back(s_wlast);
      end

      // =================== master side ====================================
      if (m_arvalid === 1'b1 && m_arready === 1'b1) begin
        if (!seq_of_addr.exists(int'(m_araddr))) begin
          fail("D4/E1", $sformatf("master read request for address %0h, which no slave transaction carried", m_araddr));
        end else begin
          sq = seq_of_addr[int'(m_araddr)];
          if (t_wr[sq] != 0)
            fail("D4", $sformatf("a write transaction was forwarded on the read address channel (address %0h)", m_araddr));
          if (t_fwd[sq] != 0)
            fail("D4", $sformatf("slave read transaction at address %0h was forwarded to the master port more than once", m_araddr));
          if (int'(m_arlen) != t_len[sq])
            fail("E1", $sformatf("master read len is %0d, the slave request carried %0d", m_arlen, t_len[sq]));
          t_fwd[sq] = 1;
          t_mid[sq] = int'(m_arid);
          // D1 / D2: no other read outstanding on a DIFFERENT slave id may
          // already hold this master id
          for (i = 0; i < NSID; i++) begin
            if (i != t_sid[sq]) begin
              for (idx = 0; idx < rd_q[i].size(); idx++) begin
                other = rd_q[i][idx];
                if (t_fwd[other] == 1 && t_mid[other] == int'(m_arid))
                  fail("D1/D2", $sformatf("master read id %0d given to slave id %0d while it is still held by slave id %0d, which is outstanding",
                                          m_arid, t_sid[sq], i));
              end
            end
          end
          mid_rd_q[int'(m_arid)].push_back(sq);
        end
      end

      if (m_awvalid === 1'b1 && m_awready === 1'b1) begin
        if (!seq_of_addr.exists(int'(m_awaddr))) begin
          fail("D4/E1", $sformatf("master write request for address %0h, which no slave transaction carried", m_awaddr));
        end else begin
          sq = seq_of_addr[int'(m_awaddr)];
          if (t_wr[sq] != 1)
            fail("D4", $sformatf("a read transaction was forwarded on the write address channel (address %0h)", m_awaddr));
          if (t_fwd[sq] != 0)
            fail("D4", $sformatf("slave write transaction at address %0h was forwarded to the master port more than once", m_awaddr));
          if (int'(m_awlen) != t_len[sq])
            fail("E1", $sformatf("master write len is %0d, the slave request carried %0d", m_awlen, t_len[sq]));
          t_fwd[sq] = 1;
          t_mid[sq] = int'(m_awid);
          for (i = 0; i < NSID; i++) begin
            if (i != t_sid[sq]) begin
              for (idx = 0; idx < wr_q[i].size(); idx++) begin
                other = wr_q[i][idx];
                if (t_fwd[other] == 1 && t_mid[other] == int'(m_awid))
                  fail("D1/D2", $sformatf("master write id %0d given to slave id %0d while it is still held by slave id %0d, which is outstanding",
                                          m_awid, t_sid[sq], i));
              end
            end
          end
          mid_wr_q[int'(m_awid)].push_back(sq);
        end
      end

      if (m_wvalid === 1'b1 && m_wready === 1'b1) begin
        if (exp_wd.size() == 0) begin
          fail("B3/D4", "a write data beat appeared on the master port that was never accepted on the slave port");
        end else begin
          wd = exp_wd.pop_front();
          ws = exp_ws.pop_front();
          wl = exp_wl.pop_front();
          if (m_wdata !== wd)
            fail("B3/E1", $sformatf("master write beat carries %0h where %0h was due; write data must follow address order and be unmodified",
                                    m_wdata, wd));
          if (m_wstrb !== ws)
            fail("E1", $sformatf("master write strobe is %0h, the slave beat carried %0h", m_wstrb, ws));
          if (m_wlast !== wl)
            fail("B3/E1", $sformatf("master write beat has wlast %0b where %0b was due", m_wlast, wl));
        end
      end
    end
  end

  // ---- stimulus helpers ----------------------------------------------------
  function automatic logic [ADDR_W-1:0] new_txn(input int sid, input int len, input int is_wr);
    logic [ADDR_W-1:0] a;
    seq_ctr = seq_ctr + 1;
    a = ADDR_W'(32'h1000_0000 + seq_ctr * 64);
    seq_of_addr[int'(a)] = seq_ctr;
    t_sid[seq_ctr] = sid;
    t_len[seq_ctr] = len;
    t_mid[seq_ctr] = -1;
    t_fwd[seq_ctr] = 0;
    t_wr [seq_ctr] = is_wr;
    rcv  [seq_ctr] = 0;
    b_sent[seq_ctr] = 0;
    return a;
  endfunction

  // Send the response for the transaction at the head of a master id's queue.
  // Per-master-id order is the one obligation AXI puts on a downstream slave.
  task automatic send_read_burst(input int mid);
    int sq, nb, b;
    logic [DATA_W-1:0] d;
    if (mid_rd_q[mid].size() == 0) return;
    sq = mid_rd_q[mid].pop_front();
    nb = t_len[sq] + 1;
    rd_busy = 1;
    for (b = 0; b < nb; b++) begin
      rdat_ctr = rdat_ctr + 1;
      d = DATA_W'(rdat_ctr);
      seq_of_rdat [int'(d)] = sq;
      beat_of_rdat[int'(d)] = b;
      last_of_rdat[int'(d)] = (b == nb-1) ? 1 : 0;
      tb_rbeat(MST_ID_W'(mid), d, (b == nb-1), 2'b00);
    end
    rd_busy = 0;
  endtask

  task automatic send_write_resp(input int mid);
    int sq;
    if (mid_wr_q[mid].size() == 0) return;
    sq = mid_wr_q[mid].pop_front();
    wr_busy = 1;
    b_sent[sq] = 1;
    tb_bbeat(MST_ID_W'(mid), 2'b00);
    wr_busy = 0;
  endtask

  // ---- background downstream slave ----------------------------------------
  initial begin : rd_responder
    int m, pick, cand [$];
    forever begin
      @(negedge clk);
      if (rst_n === 1'b1 && auto_resp != 0) begin
        cand.delete();
        for (m = 0; m < NMID; m++) if (mid_rd_q[m].size() != 0) cand.push_back(m);
        if (cand.size() != 0 && ($urandom_range(0, 3) != 0)) begin
          pick = cand[$urandom_range(0, cand.size()-1)];   // reorder across ids
          send_read_burst(pick);
        end
      end
    end
  end

  initial begin : wr_responder
    int m, pick, cand [$];
    forever begin
      @(negedge clk);
      if (rst_n === 1'b1 && auto_resp != 0) begin
        cand.delete();
        for (m = 0; m < NMID; m++) if (mid_wr_q[m].size() != 0) cand.push_back(m);
        if (cand.size() != 0 && ($urandom_range(0, 3) != 0)) begin
          pick = cand[$urandom_range(0, cand.size()-1)];
          send_write_resp(pick);
        end
      end
    end
  end

  // Write data for every accepted write, in address-acceptance order (B3 is
  // a requirement on the design; sending in order is the obligation on us).
  initial begin : w_sender
    int sq, nb, b;
    logic [DATA_W-1:0] d;
    forever begin
      @(negedge clk);
      if (rst_n === 1'b1 && aw_order_q.size() != 0) begin
        sq = aw_order_q.pop_front();
        nb = t_len[sq] + 1;
        w_busy = 1;
        for (b = 0; b < nb; b++) begin
          wdat_ctr = wdat_ctr + 1;
          d = DATA_W'(wdat_ctr);
          bfm_w(d, {(DATA_W/8){1'b1}}, (b == nb-1));
        end
        w_busy = 0;
      end
    end
  end

  // ---- flow helpers --------------------------------------------------------
  task automatic quiesce(input int limit, input string tag);
    int i;
    for (i = 0; i < limit; i++) begin
      @(posedge clk);
      if (rd_total() == 0 && wr_total() == 0 && aw_order_q.size() == 0 &&
          exp_wd.size() == 0 && rd_busy == 0 && wr_busy == 0 && w_busy == 0) return;
    end
    fail("A1/D4", $sformatf("%s: %0d reads and %0d writes were accepted and never completed",
                            tag, rd_total(), wr_total()));
  endtask

  task automatic model_flush();
    int i;
    for (i = 0; i < NSID; i++) begin rd_q[i].delete(); wr_q[i].delete(); end
    for (i = 0; i < NMID; i++) begin mid_rd_q[i].delete(); mid_wr_q[i].delete(); end
    aw_order_q.delete();
    exp_wd.delete(); exp_ws.delete(); exp_wl.delete();
  endtask

  // ---- stimulus ------------------------------------------------------------
  initial begin : main
    int i, k, sid, len, sq1, m1, d0, d1, d2, d3;
    bit acc;
    int wt;
    logic [ADDR_W-1:0] a;

    s_awid = '0; s_awaddr = '0; s_awlen = '0; s_awvalid = 1'b0;
    s_wdata = '0; s_wstrb = '0; s_wlast = 1'b0; s_wvalid = 1'b0;
    s_arid = '0; s_araddr = '0; s_arlen = '0; s_arvalid = 1'b0;
    s_bready = 1'b1; s_rready = 1'b1;
    m_awready = 1'b1; m_arready = 1'b1; m_wready = 1'b1;
    m_rid = '0; m_rdata = '0; m_rresp = 2'b00; m_rlast = 1'b0; m_rvalid = 1'b0;
    m_bid = '0; m_bresp = 2'b00; m_bvalid = 1'b0;

    bfm_reset(6);

    // =================== random traffic ==================================
    // Six identifiers against a four-entry table, so refusals happen and are
    // legitimate; nothing here requires an acceptance.
    fork
      begin
        for (i = 0; i < 120; i++) begin
          sid = $urandom_range(0, 5);
          len = $urandom_range(0, 3);
          a   = new_txn(sid, len, 0);
          bfm_ar(SLV_ID_W'(sid), a, 8'(len), 60, acc, wt);
          if (!acc) seq_of_addr.delete(int'(a));   // never offered again
        end
      end
      begin
        for (i = 0; i < 120; i++) begin
          sid = $urandom_range(0, 5);
          len = $urandom_range(0, 3);
          a   = new_txn(sid, len, 1);
          bfm_aw(SLV_ID_W'(sid), a, 8'(len), 60, acc, wt);
          if (!acc) seq_of_addr.delete(int'(a));
        end
      end
    join
    quiesce(4000, "random traffic");
    if (n_rd_done < 40)
      fail("A3/A4", $sformatf("only %0d reads completed in the random phase; the design is refusing requests it must accept", n_rd_done));
    if (n_wr_done < 40)
      fail("A3/A4", $sformatf("only %0d writes completed in the random phase", n_wr_done));

    // =================== A3 / A5, read side ==============================
    // The write side is left idle throughout, because a design is free to
    // share one table between the directions (latitude 6).
    auto_resp = 0;
    d0 = 1; d1 = 2; d2 = 3; d3 = 4;
    for (k = 0; k < 3; k++) begin
      a = new_txn(d0 + k, 0, 0);
      bfm_ar(SLV_ID_W'(d0 + k), a, 8'd0, 60, acc, wt);
      if (!acc) fail("A3", $sformatf("read id %0d refused with only %0d distinct ids outstanding", d0 + k, k));
    end
    // MAX_UNIQ_IDS-1 distinct outstanding: a further new one must be taken
    a = new_txn(d3, 0, 0);
    bfm_ar(SLV_ID_W'(d3), a, 8'd0, 60, acc, wt);
    if (!acc)
      fail("A3", $sformatf("read id %0d refused with %0d distinct ids outstanding; the table holds %0d",
                           d3, MAX_UNIQ_IDS-1, MAX_UNIQ_IDS));
    // the table is full: a NEW identifier must not be taken
    a = new_txn(9, 0, 0);
    bfm_ar(SLV_ID_W'(9), a, 8'd0, 30, acc, wt);
    if (acc) fail("A3", "a new read id was accepted with the table already full");
    else seq_of_addr.delete(int'(a));
    // an identifier already outstanding is NOT blocked by A3
    a = new_txn(d0, 0, 0);
    bfm_ar(SLV_ID_W'(d0), a, 8'd0, 60, acc, wt);
    if (!acc)
      fail("A3", $sformatf("read id %0d refused although it is already outstanding and holds only 1 of %0d transactions",
                           d0, MAX_TXNS_PER_ID));
    else begin
      // A5: that identifier is now at its depth limit
      a = new_txn(d0, 0, 0);
      bfm_ar(SLV_ID_W'(d0), a, 8'd0, 30, acc, wt);
      if (acc) fail("A5", $sformatf("a third transaction was accepted on read id %0d; the limit is %0d", d0, MAX_TXNS_PER_ID));
      else seq_of_addr.delete(int'(a));
    end

    // =================== A4, read side ===================================
    // Retire id d1 completely while a new identifier is offered continuously.
    sq1 = rd_q[d1][0];
    m1  = t_mid[sq1];
    if (m1 < 0 || mid_rd_q[m1].size() == 0 || mid_rd_q[m1][0] != sq1) begin
      fail("D1", "the transaction to be retired is not at the head of its master id, so A4 cannot be measured");
    end else begin
      a = new_txn(9, 0, 0);
      fork
        begin
          bfm_ar(SLV_ID_W'(9), a, 8'd0, 400, acc, wt);
        end
        begin
          repeat (8) @(posedge clk);
          send_read_burst(m1);
        end
      join
      if (!acc) begin
        fail("A4", "a new read id was never accepted after an identifier retired");
      end else if (ar_acc_cyc[9] < rd_ret_cyc[d1]) begin
        fail("A3", "the new read id was accepted before the retirement that freed its entry");
      end else if ((ar_acc_cyc[9] - rd_ret_cyc[d1]) > 2) begin
        fail("A4", $sformatf("a new read id was accepted %0d cycles after the entry was freed; the bound is 2",
                             ar_acc_cyc[9] - rd_ret_cyc[d1]));
      end
    end
    auto_resp = 1;
    quiesce(4000, "A3/A4 read");

    // =================== A3 / A5 / A4, write side ========================
    auto_resp = 0;
    for (k = 0; k < 3; k++) begin
      a = new_txn(d0 + k, 0, 1);
      bfm_aw(SLV_ID_W'(d0 + k), a, 8'd0, 60, acc, wt);
      if (!acc) fail("A3", $sformatf("write id %0d refused with only %0d distinct ids outstanding", d0 + k, k));
    end
    a = new_txn(d3, 0, 1);
    bfm_aw(SLV_ID_W'(d3), a, 8'd0, 60, acc, wt);
    if (!acc)
      fail("A3", $sformatf("write id %0d refused with %0d distinct ids outstanding; the table holds %0d",
                           d3, MAX_UNIQ_IDS-1, MAX_UNIQ_IDS));
    a = new_txn(9, 0, 1);
    bfm_aw(SLV_ID_W'(9), a, 8'd0, 30, acc, wt);
    if (acc) fail("A3", "a new write id was accepted with the table already full");
    else seq_of_addr.delete(int'(a));
    a = new_txn(d0, 0, 1);
    bfm_aw(SLV_ID_W'(d0), a, 8'd0, 60, acc, wt);
    if (!acc)
      fail("A3", $sformatf("write id %0d refused although it is already outstanding and holds only 1 of %0d transactions",
                           d0, MAX_TXNS_PER_ID));
    else begin
      a = new_txn(d0, 0, 1);
      bfm_aw(SLV_ID_W'(d0), a, 8'd0, 30, acc, wt);
      if (acc) fail("A5", $sformatf("a third transaction was accepted on write id %0d; the limit is %0d", d0, MAX_TXNS_PER_ID));
      else seq_of_addr.delete(int'(a));
    end
    // let the write data drain so nothing but the response is missing
    repeat (40) @(posedge clk);
    sq1 = wr_q[d1][0];
    m1  = t_mid[sq1];
    if (m1 < 0 || mid_wr_q[m1].size() == 0 || mid_wr_q[m1][0] != sq1) begin
      fail("D1", "the write transaction to be retired is not at the head of its master id, so A4 cannot be measured");
    end else begin
      a = new_txn(9, 0, 1);
      fork
        begin
          bfm_aw(SLV_ID_W'(9), a, 8'd0, 400, acc, wt);
        end
        begin
          repeat (8) @(posedge clk);
          send_write_resp(m1);
        end
      join
      if (!acc) begin
        fail("A4", "a new write id was never accepted after an identifier retired");
      end else if (aw_acc_cyc[9] < wr_ret_cyc[d1]) begin
        fail("A3", "the new write id was accepted before the retirement that freed its entry");
      end else if ((aw_acc_cyc[9] - wr_ret_cyc[d1]) > 2) begin
        fail("A4", $sformatf("a new write id was accepted %0d cycles after the entry was freed; the bound is 2",
                             aw_acc_cyc[9] - wr_ret_cyc[d1]));
      end
    end
    auto_resp = 1;
    quiesce(4000, "A3/A4 write");

    // =================== F1: reset discards ==============================
    auto_resp = 0;
    for (k = 0; k < 3; k++) begin
      a = new_txn(d0 + k, 1, 0);
      bfm_ar(SLV_ID_W'(d0 + k), a, 8'd1, 60, acc, wt);
    end
    a = new_txn(d0, 0, 1);
    bfm_aw(SLV_ID_W'(d0), a, 8'd0, 60, acc, wt);
    repeat (30) @(posedge clk);          // let the write data go out
    // Reset, and offer a request entirely INSIDE the reset window: an offer
    // that straddles the release may legitimately be taken after it.
    @(negedge clk);
    rst_n = 1'b0;
    a = new_txn(7, 0, 0);
    bfm_ar(SLV_ID_W'(7), a, 8'd0, 8, acc, wt);      // 8 < the reset length
    if (acc) fail("F1", "a read address was accepted while rst_ni was low");
    else seq_of_addr.delete(int'(a));
    repeat (3) @(posedge clk);
    @(negedge clk);
    rst_n = 1'b1;
    model_flush();
    f1_watch = 1;
    repeat (60) @(posedge clk);          // nothing from before the reset may appear
    f1_watch = 0;
    // and the table must be empty again
    for (k = 0; k < 4; k++) begin
      a = new_txn(10 + k, 0, 0);
      bfm_ar(SLV_ID_W'(10 + k), a, 8'd0, 60, acc, wt);
      if (!acc) fail("F1", $sformatf("only %0d distinct read ids could be accepted after reset; the table must be empty", k));
    end
    auto_resp = 1;
    quiesce(4000, "post-reset");

    // =================== a second random run =============================
    bp_on = 1;
    fork
      begin : rd_stream
        automatic int ri, rsid, rlen, rwt;
        automatic bit racc;
        automatic logic [ADDR_W-1:0] ra;
        for (ri = 0; ri < 80; ri++) begin
          rsid = $urandom_range(0, 5);
          rlen = $urandom_range(0, 3);
          ra   = new_txn(rsid, rlen, 0);
          bfm_ar(SLV_ID_W'(rsid), ra, 8'(rlen), 60, racc, rwt);
          if (!racc) seq_of_addr.delete(int'(ra));
        end
      end
      begin : wr_stream
        automatic int wi, wsid, wlen, wwt;
        automatic bit wacc;
        automatic logic [ADDR_W-1:0] wa;
        for (wi = 0; wi < 80; wi++) begin
          wsid = $urandom_range(0, 5);
          wlen = $urandom_range(0, 3);
          wa   = new_txn(wsid, wlen, 1);
          bfm_aw(SLV_ID_W'(wsid), wa, 8'(wlen), 60, wacc, wwt);
          if (!wacc) seq_of_addr.delete(int'(wa));
        end
      end
    join
    bp_on = 0;
    @(negedge clk); s_rready = 1'b1; s_bready = 1'b1;
    quiesce(4000, "second random run");

    $display("INFO: %0d reads and %0d writes accepted; %0d and %0d completed",
             n_rd_acc, n_wr_acc, n_rd_done, n_wr_done);
    if (err_count == 0) $display("RESULT: PASS");
    else                $display("RESULT: FAIL (%0d violation%s)", err_count, (err_count == 1) ? "" : "s");
    $finish;
  end

endmodule