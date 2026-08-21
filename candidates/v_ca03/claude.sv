// ===========================================================================
//  id_width_conv_tb
//
//  Specification-driven, self-checking testbench for id_width_conv.
//
//  Structure
//    * The testbench drives the slave port and *is* the downstream slave on
//      the master port, so it chooses response order itself.
//    * A single posedge monitor maintains a model of the conversion table:
//      what is outstanding per slave id, which master id currently owns which
//      slave id, and which transactions have been forwarded.  Every check is
//      grounded in a numbered clause; behaviour listed under section 8
//      (Named latitude) is deliberately not checked.
//    * Every wait is bounded.  The provided watchdog is kept.
//
//  Monitor ordering inside one posedge (matters for a combinational design):
//      master responses -> slave responses (retirement) -> slave addresses
//      -> master addresses -> write data
//  so that a zero-latency implementation is judged correctly and an entry
//  freed on edge E is seen as free by an acceptance on edge E (clause A4).
// ===========================================================================
`timescale 1ns/1ps

module id_width_conv_tb;

  // ------------------------------------------------------------------ config
  localparam int unsigned SLV_ID_W        = 4;
  localparam int unsigned MST_ID_W        = 2;
  localparam int unsigned ADDR_W          = 32;
  localparam int unsigned DATA_W          = 32;
  localparam int unsigned MAX_UNIQ_IDS    = 4;
  localparam int unsigned MAX_TXNS_PER_ID = 2;

  localparam int NSID   = 1 << SLV_ID_W;   // 16 slave ids
  localparam int NMID   = 1 << MST_ID_W;   // 4 master ids
  localparam int MAXTXN = 4096;            // capacity of the tag space

  localparam logic [ADDR_W-1:0] ADDR_BASE = 32'h1000_0000;
  localparam int                ADDR_STEP = 64;

  // Generous budget for a request the contract says must be accepted.  Long
  // enough that clause 8.3 ("ready may be low for internal arbitration")
  // cannot be the explanation; the design is otherwise idle at these points.
  localparam int BUDGET_ACCEPT = 400;
  // Budget over which a request the contract says must be refused is offered.
  localparam int BUDGET_REFUSE = 40;

  // ----------------------------------------------------------------- signals
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

  // ===========================================================================
  // PROVIDED PLUMBING -- moves transactions, checks nothing.
  // ===========================================================================
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
  // =================================================================== end plumbing

  // ------------------------------------------------------------------- DUT
  id_width_conv #(
    .SLV_ID_W        (SLV_ID_W),
    .MST_ID_W        (MST_ID_W),
    .ADDR_W          (ADDR_W),
    .DATA_W          (DATA_W),
    .MAX_UNIQ_IDS    (MAX_UNIQ_IDS),
    .MAX_TXNS_PER_ID (MAX_TXNS_PER_ID)
  ) dut (
    .clk_i (clk), .rst_ni (rst_n),
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
    .m_rvalid(m_rvalid), .m_rready(m_rready)
  );

  // --------------------------------------------------------------- bookkeeping
  // Per-transaction state.  Tags are globally unique across reads and writes,
  // and the address is a pure function of the tag, so a request seen on the
  // master port is identified by bookkeeping rather than by matching payload.
  int  txn_sid  [MAXTXN];
  int  txn_len  [MAXTXN];
  int  txn_mid  [MAXTXN];
  bit  txn_fwd  [MAXTXN];
  int  txn_bcnt [MAXTXN];   // response beats already seen on the slave port
  bit  txn_isrd [MAXTXN];
  bit  txn_drop [MAXTXN];   // discarded by a reset (F1)
  int  req_len  [MAXTXN];

  int  next_tag;

  int  rd_out   [$];   // accepted, not yet complete -- slave acceptance order
  int  wr_out   [$];
  int  rd_fwd_q [$];   // forwarded to master, awaiting my response -- AR order
  int  wr_fwd_q [$];

  int  rd_mid_owner [NMID];   // -1 = free
  int  wr_mid_owner [NMID];
  int  rd_credit    [NSID];   // master response beats seen, not yet consumed
  int  wr_credit    [NSID];

  logic [DATA_W-1:0]   exp_w_data [$];
  logic [DATA_W/8-1:0] exp_w_strb [$];
  bit                  exp_w_last [$];

  int  wdata_q [$];
  bit  wdata_busy;

  int  pend_ar_tag;
  int  pend_aw_tag;

  bit  auto_resp;
  bit  quiet_chk;      // F1 post-reset silence window
  int  rst_low_cnt;

  int  nerr;
  int  cyc;

  // A4 measurement
  bit  a4_rd_arm, a4_rd_ret, a4_rd_acc;
  int  a4_rd_sid, a4_rd_new, a4_rd_ret_cyc, a4_rd_acc_cyc;
  bit  a4_wr_arm, a4_wr_ret, a4_wr_acc;
  int  a4_wr_sid, a4_wr_new, a4_wr_ret_cyc, a4_wr_acc_cyc;

  // monitor scratch (only the monitor writes these)
  int mi, mtag, msid, mmid, mother;
  logic [DATA_W-1:0] mexp_d;
  bit                mexp_l;

  // -------------------------------------------------------------- diagnostics
  task automatic fail(input string req, input string msg);
    nerr = nerr + 1;
    if (nerr <= 60) $display("FAIL [%s] t=%0t cyc=%0d : %s", req, $time, cyc, msg);
    if (nerr == 61) $display("FAIL [--] further diagnostics suppressed");
  endtask

  // ---------------------------------------------------------------- encodings
  function automatic logic [ADDR_W-1:0] mk_addr(input int tag);
    return ADDR_BASE + (tag * ADDR_STEP);
  endfunction

  function automatic int tag_from_addr(input logic [ADDR_W-1:0] a);
    automatic int unsigned d;
    if (a < ADDR_BASE) return -1;
    d = a - ADDR_BASE;
    if ((d % ADDR_STEP) != 0) return -1;
    if ((d / ADDR_STEP) >= next_tag) return -1;
    return int'(d / ADDR_STEP);
  endfunction

  function automatic logic [DATA_W-1:0] mk_rdata(input int tag, input int k);
    return ((tag & 32'h0000_FFFF) << 16) | (k & 32'h0000_FFFF);
  endfunction

  function automatic logic [DATA_W-1:0] mk_wdata(input int tag, input int k);
    return 32'h8000_0000 ^ (((tag & 32'h0000_7FFF) << 16) | (k & 32'h0000_FFFF));
  endfunction

  function automatic logic [DATA_W/8-1:0] mk_wstrb(input int tag, input int k);
    return (DATA_W/8)'((tag + k) | 1);
  endfunction

  // ---------------------------------------------------------- model queries
  function automatic int rd_cnt_sid(input int sid);
    automatic int i; automatic int c;
    c = 0;
    for (i = 0; i < rd_out.size(); i++) if (txn_sid[rd_out[i]] == sid) c++;
    return c;
  endfunction

  function automatic int wr_cnt_sid(input int sid);
    automatic int i; automatic int c;
    c = 0;
    for (i = 0; i < wr_out.size(); i++) if (txn_sid[wr_out[i]] == sid) c++;
    return c;
  endfunction

  function automatic int rd_first_sid(input int sid);
    automatic int i;
    for (i = 0; i < rd_out.size(); i++) if (txn_sid[rd_out[i]] == sid) return rd_out[i];
    return -1;
  endfunction

  function automatic int wr_first_sid(input int sid);
    automatic int i;
    for (i = 0; i < wr_out.size(); i++) if (txn_sid[wr_out[i]] == sid) return wr_out[i];
    return -1;
  endfunction

  function automatic int rd_uniq();
    automatic int i; automatic int c; automatic bit seen [NSID];
    for (i = 0; i < NSID; i++) seen[i] = 1'b0;
    c = 0;
    for (i = 0; i < rd_out.size(); i++)
      if (!seen[txn_sid[rd_out[i]]]) begin seen[txn_sid[rd_out[i]]] = 1'b1; c++; end
    return c;
  endfunction

  function automatic int wr_uniq();
    automatic int i; automatic int c; automatic bit seen [NSID];
    for (i = 0; i < NSID; i++) seen[i] = 1'b0;
    c = 0;
    for (i = 0; i < wr_out.size(); i++)
      if (!seen[txn_sid[wr_out[i]]]) begin seen[txn_sid[wr_out[i]]] = 1'b1; c++; end
    return c;
  endfunction

  function automatic int rd_fwd_first_mid(input int m);
    automatic int i;
    for (i = 0; i < rd_fwd_q.size(); i++) if (txn_mid[rd_fwd_q[i]] == m) return rd_fwd_q[i];
    return -1;
  endfunction

  function automatic int wr_fwd_first_mid(input int m);
    automatic int i;
    for (i = 0; i < wr_fwd_q.size(); i++) if (txn_mid[wr_fwd_q[i]] == m) return wr_fwd_q[i];
    return -1;
  endfunction

  function automatic int find_rd_by_data(input logic [DATA_W-1:0] d);
    automatic int i; automatic int t;
    for (i = 0; i < rd_out.size(); i++) begin
      t = rd_out[i];
      if (mk_rdata(t, txn_bcnt[t]) === d) return t;
    end
    return -1;
  endfunction

  function automatic bit w_data_later(input logic [DATA_W-1:0] d);
    automatic int i;
    for (i = 1; i < exp_w_data.size(); i++) if (exp_w_data[i] === d) return 1'b1;
    return 1'b0;
  endfunction

  task automatic q_remove(inout int q [$], input int tg);
    automatic int i;
    for (i = 0; i < q.size(); i++) if (q[i] == tg) begin q.delete(i); return; end
  endtask

  // ==========================================================================
  //  Monitor -- one process, so the ordering above is deterministic.
  // ==========================================================================
  always @(posedge clk) cyc <= cyc + 1;

  always @(posedge clk) begin : mon

    if (!rst_n) begin
      rst_low_cnt = rst_low_cnt + 1;
      // F1: while reset is low nothing is accepted and nothing is presented.
      // One cycle of settling is allowed for a synchronous reset.
      if (rst_low_cnt >= 2) begin
        if (s_rvalid === 1'b1) fail("F1", "s_rvalid asserted while rst_ni is low");
        if (s_bvalid === 1'b1) fail("F1", "s_bvalid asserted while rst_ni is low");
        if (s_arvalid && s_arready) fail("F1", "read address accepted while rst_ni is low");
        if (s_awvalid && s_awready) fail("F1", "write address accepted while rst_ni is low");
      end
    end
    else begin
      rst_low_cnt = 0;

      // F1: after release, nothing outstanding before the reset may respond.
      if (quiet_chk) begin
        if (s_rvalid && s_rready)
          fail("F1", "read response after reset for a transaction issued before it");
        if (s_bvalid && s_bready)
          fail("F1", "write response after reset for a transaction issued before it");
      end

      // ---------------- 1. master response channels (credit) ----------------
      if (m_rvalid && m_rready) begin
        mmid = int'(m_rid);
        mtag = rd_fwd_first_mid(mmid);
        if (mtag >= 0) begin
          rd_credit[txn_sid[mtag]] = rd_credit[txn_sid[mtag]] + 1;
          if (m_rlast) q_remove(rd_fwd_q, mtag);
        end
      end
      if (m_bvalid && m_bready) begin
        mmid = int'(m_bid);
        mtag = wr_fwd_first_mid(mmid);
        if (mtag >= 0) begin
          wr_credit[txn_sid[mtag]] = wr_credit[txn_sid[mtag]] + 1;
          q_remove(wr_fwd_q, mtag);
        end
      end

      // ---------------- 2. slave read response beat -------------------------
      if (s_rvalid && s_rready) begin
        msid = int'(s_rid);
        mtag = rd_first_sid(msid);
        if (mtag < 0) begin
          fail("C2", $sformatf("read response beat with s_rid=%0d but no read transaction with that id is outstanding", msid));
        end else begin
          if (rd_credit[msid] <= 0)
            fail("D4", $sformatf("read response beat for s_rid=%0d with no corresponding master read beat", msid));
          else
            rd_credit[msid] = rd_credit[msid] - 1;

          mexp_d = mk_rdata(mtag, txn_bcnt[mtag]);
          mexp_l = (txn_bcnt[mtag] == txn_len[mtag]);

          if (s_rdata !== mexp_d) begin
            mother = find_rd_by_data(s_rdata);
            if (mother >= 0 && txn_sid[mother] != msid)
              fail("C1", $sformatf("read beat presented with s_rid=%0d but it belongs to slave id %0d", msid, txn_sid[mother]));
            else if (mother >= 0)
              fail("B1", $sformatf("read responses for slave id %0d are out of address-acceptance order", msid));
            else
              fail("E1", $sformatf("read data corrupted for slave id %0d: got %08h expected %08h", msid, s_rdata, mexp_d));
          end
          if (s_rlast !== mexp_l)
            fail("E1", $sformatf("s_rlast wrong for slave id %0d beat %0d: got %0b expected %0b", msid, txn_bcnt[mtag], s_rlast, mexp_l));
          if (s_rresp !== 2'b00)
            fail("E1", $sformatf("s_rresp corrupted for slave id %0d: got %02b expected 00", msid, s_rresp));

          txn_bcnt[mtag] = txn_bcnt[mtag] + 1;
          if (txn_bcnt[mtag] > txn_len[mtag]) begin
            q_remove(rd_out, mtag);
            if (rd_cnt_sid(msid) == 0) begin
              // A4/D2: the entry, and any master id it owns, is free from here.
              for (mi = 0; mi < NMID; mi++)
                if (rd_mid_owner[mi] == msid) rd_mid_owner[mi] = -1;
              if (a4_rd_arm && msid == a4_rd_sid && !a4_rd_ret) begin
                a4_rd_ret = 1'b1; a4_rd_ret_cyc = cyc;
              end
            end
          end
        end
      end

      // ---------------- 3. slave write response -----------------------------
      if (s_bvalid && s_bready) begin
        msid = int'(s_bid);
        mtag = wr_first_sid(msid);
        if (mtag < 0) begin
          fail("C2", $sformatf("write response with s_bid=%0d but no write transaction with that id is outstanding", msid));
        end else begin
          if (wr_credit[msid] <= 0)
            fail("D4", $sformatf("write response for s_bid=%0d with no corresponding master write response", msid));
          else
            wr_credit[msid] = wr_credit[msid] - 1;
          if (s_bresp !== 2'b00)
            fail("E1", $sformatf("s_bresp corrupted for slave id %0d: got %02b expected 00", msid, s_bresp));

          q_remove(wr_out, mtag);
          if (wr_cnt_sid(msid) == 0) begin
            for (mi = 0; mi < NMID; mi++)
              if (wr_mid_owner[mi] == msid) wr_mid_owner[mi] = -1;
            if (a4_wr_arm && msid == a4_wr_sid && !a4_wr_ret) begin
              a4_wr_ret = 1'b1; a4_wr_ret_cyc = cyc;
            end
          end
        end
      end

      // ---------------- 4. slave read address acceptance --------------------
      if (s_arvalid && s_arready) begin
        msid = int'(s_arid);
        mtag = pend_ar_tag;
        if (mtag < 0) begin
          fail("A1", "read address accepted while the testbench was offering none");
        end else begin
          if (rd_cnt_sid(msid) >= int'(MAX_TXNS_PER_ID))
            fail("A5", $sformatf("read accepted for slave id %0d which already has %0d outstanding (MAX_TXNS_PER_ID=%0d)",
                                 msid, rd_cnt_sid(msid), MAX_TXNS_PER_ID));
          else if (rd_cnt_sid(msid) == 0 && rd_uniq() >= int'(MAX_UNIQ_IDS))
            fail("A2/A3", $sformatf("read accepted for new slave id %0d while %0d distinct read ids are already outstanding (MAX_UNIQ_IDS=%0d)",
                                 msid, rd_uniq(), MAX_UNIQ_IDS));

          txn_sid[mtag]  = msid;
          txn_len[mtag]  = int'(s_arlen);
          txn_mid[mtag]  = -1;
          txn_fwd[mtag]  = 1'b0;
          txn_bcnt[mtag] = 0;
          txn_isrd[mtag] = 1'b1;
          txn_drop[mtag] = 1'b0;
          rd_out.push_back(mtag);
          pend_ar_tag = -1;

          if (a4_rd_arm && msid == a4_rd_new && !a4_rd_acc) begin
            a4_rd_acc = 1'b1; a4_rd_acc_cyc = cyc;
          end
        end
      end

      // ---------------- 5. slave write address acceptance -------------------
      if (s_awvalid && s_awready) begin
        msid = int'(s_awid);
        mtag = pend_aw_tag;
        if (mtag < 0) begin
          fail("A1", "write address accepted while the testbench was offering none");
        end else begin
          if (wr_cnt_sid(msid) >= int'(MAX_TXNS_PER_ID))
            fail("A5", $sformatf("write accepted for slave id %0d which already has %0d outstanding (MAX_TXNS_PER_ID=%0d)",
                                 msid, wr_cnt_sid(msid), MAX_TXNS_PER_ID));
          else if (wr_cnt_sid(msid) == 0 && wr_uniq() >= int'(MAX_UNIQ_IDS))
            fail("A2/A3", $sformatf("write accepted for new slave id %0d while %0d distinct write ids are already outstanding (MAX_UNIQ_IDS=%0d)",
                                 msid, wr_uniq(), MAX_UNIQ_IDS));

          txn_sid[mtag]  = msid;
          txn_len[mtag]  = int'(s_awlen);
          txn_mid[mtag]  = -1;
          txn_fwd[mtag]  = 1'b0;
          txn_bcnt[mtag] = 0;
          txn_isrd[mtag] = 1'b0;
          txn_drop[mtag] = 1'b0;
          wr_out.push_back(mtag);
          pend_aw_tag = -1;

          if (a4_wr_arm && msid == a4_wr_new && !a4_wr_acc) begin
            a4_wr_acc = 1'b1; a4_wr_acc_cyc = cyc;
          end
        end
      end

      // ---------------- 6. master read address ------------------------------
      if (m_arvalid && m_arready) begin
        mtag = tag_from_addr(m_araddr);
        if (mtag < 0)
          fail("E1", $sformatf("master read address %08h does not correspond to any request offered", m_araddr));
        else if (txn_drop[mtag]) begin
          // Discarded by a reset; F1 is judged by the silence window instead.
        end
        else if (!txn_isrd[mtag])
          fail("D4", $sformatf("master read address %08h belongs to a write transaction", m_araddr));
        else if (txn_fwd[mtag])
          fail("D4", $sformatf("master read request repeated for address %08h", m_araddr));
        else begin
          if (int'(m_arlen) != txn_len[mtag])
            fail("E1", $sformatf("m_arlen corrupted for address %08h: got %0d expected %0d", m_araddr, m_arlen, txn_len[mtag]));
          mmid = int'(m_arid);
          msid = txn_sid[mtag];
          if (rd_mid_owner[mmid] >= 0 && rd_mid_owner[mmid] != msid)
            fail("D1/D2", $sformatf("master read id %0d given to slave id %0d while slave id %0d still holds it (reused before retirement)",
                                 mmid, msid, rd_mid_owner[mmid]));
          rd_mid_owner[mmid] = msid;
          txn_mid[mtag] = mmid;
          txn_fwd[mtag] = 1'b1;
          rd_fwd_q.push_back(mtag);
        end
      end

      // ---------------- 7. master write address -----------------------------
      if (m_awvalid && m_awready) begin
        mtag = tag_from_addr(m_awaddr);
        if (mtag < 0)
          fail("E1", $sformatf("master write address %08h does not correspond to any request offered", m_awaddr));
        else if (txn_drop[mtag]) begin
          // discarded by reset
        end
        else if (txn_isrd[mtag])
          fail("D4", $sformatf("master write address %08h belongs to a read transaction", m_awaddr));
        else if (txn_fwd[mtag])
          fail("D4", $sformatf("master write request repeated for address %08h", m_awaddr));
        else begin
          if (int'(m_awlen) != txn_len[mtag])
            fail("E1", $sformatf("m_awlen corrupted for address %08h: got %0d expected %0d", m_awaddr, m_awlen, txn_len[mtag]));
          mmid = int'(m_awid);
          msid = txn_sid[mtag];
          if (wr_mid_owner[mmid] >= 0 && wr_mid_owner[mmid] != msid)
            fail("D1/D2", $sformatf("master write id %0d given to slave id %0d while slave id %0d still holds it (reused before retirement)",
                                 mmid, msid, wr_mid_owner[mmid]));
          wr_mid_owner[mmid] = msid;
          txn_mid[mtag] = mmid;
          txn_fwd[mtag] = 1'b1;
          wr_fwd_q.push_back(mtag);
        end
      end

      // ---------------- 8. write data ---------------------------------------
      if (s_wvalid && s_wready) begin
        exp_w_data.push_back(s_wdata);
        exp_w_strb.push_back(s_wstrb);
        exp_w_last.push_back(s_wlast);
      end
      if (m_wvalid && m_wready) begin
        if (exp_w_data.size() == 0) begin
          fail("D4", "master write data beat with no corresponding slave write data beat");
        end else begin
          if (m_wdata !== exp_w_data[0]) begin
            if (w_data_later(m_wdata))
              fail("B3", $sformatf("write data beat out of order: got %08h expected %08h", m_wdata, exp_w_data[0]));
            else
              fail("E1", $sformatf("write data corrupted: got %08h expected %08h", m_wdata, exp_w_data[0]));
          end
          if (m_wstrb !== exp_w_strb[0])
            fail("E1", $sformatf("m_wstrb corrupted: got %0h expected %0h", m_wstrb, exp_w_strb[0]));
          if (m_wlast !== exp_w_last[0])
            fail("E1", $sformatf("m_wlast corrupted: got %0b expected %0b", m_wlast, exp_w_last[0]));
          exp_w_data.pop_front(); exp_w_strb.pop_front(); exp_w_last.pop_front();
        end
      end
    end
  end

  // ==========================================================================
  //  Stimulus helpers
  // ==========================================================================
  // mode 0 = either outcome is legal (clause 8.3 latitude)
  // mode 1 = the contract requires acceptance
  // mode 2 = the contract requires refusal
  task automatic do_ar(input int sid, input int len, input int budget,
                       input int mode, input string req, output bit acc);
    automatic int tg;
    automatic int w;
    automatic logic [SLV_ID_W-1:0] sidv;
    automatic logic [7:0]          lenv;
    tg = next_tag; next_tag = next_tag + 1;
    req_len[tg] = len;
    txn_drop[tg] = 1'b0;
    txn_isrd[tg] = 1'b1;
    pend_ar_tag = tg;
    sidv = sid[SLV_ID_W-1:0];
    lenv = len[7:0];
    bfm_ar(sidv, mk_addr(tg), lenv, budget, acc, w);
    if (!acc) pend_ar_tag = -1;
    if (mode == 1 && !acc)
      fail(req, $sformatf("read request with slave id %0d was not accepted within %0d cycles although the contract requires it", sid, budget));
    if (mode == 2 && acc)
      fail(req, $sformatf("read request with slave id %0d was accepted although the contract forbids it", sid));
  endtask

  task automatic do_aw(input int sid, input int len, input int budget,
                       input int mode, input string req, output bit acc);
    automatic int tg;
    automatic int w;
    automatic logic [SLV_ID_W-1:0] sidv;
    automatic logic [7:0]          lenv;
    tg = next_tag; next_tag = next_tag + 1;
    req_len[tg] = len;
    txn_drop[tg] = 1'b0;
    txn_isrd[tg] = 1'b0;
    pend_aw_tag = tg;
    sidv = sid[SLV_ID_W-1:0];
    lenv = len[7:0];
    bfm_aw(sidv, mk_addr(tg), lenv, budget, acc, w);
    if (!acc) pend_aw_tag = -1;
    else wdata_q.push_back(tg);
    if (mode == 1 && !acc)
      fail(req, $sformatf("write request with slave id %0d was not accepted within %0d cycles although the contract requires it", sid, budget));
    if (mode == 2 && acc)
      fail(req, $sformatf("write request with slave id %0d was accepted although the contract forbids it", sid));
  endtask

  // Write data is offered in write-address acceptance order (B3's premise).
  initial begin : wdata_driver
    automatic int tg, k, l;
    wdata_busy = 1'b0;
    forever begin
      @(negedge clk);
      if (wdata_q.size() > 0) begin
        wdata_busy = 1'b1;
        tg = wdata_q.pop_front();
        l  = req_len[tg];
        for (k = 0; k <= l; k++)
          bfm_w(mk_wdata(tg, k), mk_wstrb(tg, k), (k == l));
        wdata_busy = 1'b0;
      end
    end
  end

  // A response is only ever offered for the transaction that is oldest for its
  // slave id, so the testbench never demands a reordering the contract does
  // not require of the design (B1), while still leaving response order between
  // different ids free (B2).
  function automatic int pick_rd_mid(input int start);
    automatic int i, m, tg;
    for (i = 0; i < NMID; i++) begin
      m  = (start + i) % NMID;
      tg = rd_fwd_first_mid(m);
      if (tg >= 0 && rd_first_sid(txn_sid[tg]) == tg) return m;
    end
    return -1;
  endfunction

  function automatic int pick_wr_mid(input int start);
    automatic int i, m, tg;
    for (i = 0; i < NMID; i++) begin
      m  = (start + i) % NMID;
      tg = wr_fwd_first_mid(m);
      if (tg >= 0 && wr_first_sid(txn_sid[tg]) == tg) return m;
    end
    return -1;
  endfunction

  task automatic send_rd_resp(input int m);
    automatic int tg, k, l;
    automatic logic [MST_ID_W-1:0] mv;
    tg = rd_fwd_first_mid(m);
    if (tg < 0) return;
    mv = m[MST_ID_W-1:0];
    l  = txn_len[tg];
    for (k = 0; k <= l; k++) bfm_rbeat(mv, mk_rdata(tg, k), (k == l));
  endtask

  task automatic send_wr_resp(input int m);
    automatic logic [MST_ID_W-1:0] mv;
    if (wr_fwd_first_mid(m) < 0) return;
    mv = m[MST_ID_W-1:0];
    bfm_bbeat(mv);
  endtask

  initial begin : auto_rd_resp
    automatic int m;
    forever begin
      @(negedge clk);
      if (auto_resp) begin
        m = pick_rd_mid($urandom_range(0, NMID-1));
        if (m >= 0) send_rd_resp(m);
      end
    end
  end

  initial begin : auto_wr_resp
    automatic int m;
    forever begin
      @(negedge clk);
      if (auto_resp) begin
        m = pick_wr_mid($urandom_range(0, NMID-1));
        if (m >= 0) send_wr_resp(m);
      end
    end
  end

  // ------------------------------------------------------------ bounded waits
  task automatic wait_fwd(input int tg, input int maxc);
    automatic int g;
    g = 0;
    while (!txn_fwd[tg] && g < maxc) begin @(posedge clk); g++; end
    if (!txn_fwd[tg])
      fail("D4", $sformatf("accepted transaction at address %08h never appeared on the master port", mk_addr(tg)));
  endtask

  task automatic wait_wdrain(input int maxc);
    automatic int g;
    g = 0;
    while (((wdata_q.size() > 0) || wdata_busy || (exp_w_data.size() > 0)) && (g < maxc)) begin
      @(posedge clk); g++;
    end
  endtask

  task automatic drain_active(input int maxc);
    automatic int g, m;
    g = 0;
    while (((rd_out.size() + wr_out.size()) > 0) && (g < maxc)) begin
      m = pick_rd_mid(0);
      if (m >= 0) send_rd_resp(m);
      else begin
        m = pick_wr_mid(0);
        if (m >= 0) send_wr_resp(m);
        else begin @(posedge clk); g++; end
      end
      g++;
    end
    if ((rd_out.size() + wr_out.size()) > 0)
      fail("D4", $sformatf("%0d reads and %0d writes never completed", rd_out.size(), wr_out.size()));
  endtask

  task automatic drain_passive(input int maxc);
    automatic int g;
    g = 0;
    while (((rd_out.size() + wr_out.size()) > 0) && (g < maxc)) begin @(posedge clk); g++; end
    if ((rd_out.size() + wr_out.size()) > 0)
      fail("D4", $sformatf("%0d reads and %0d writes never completed", rd_out.size(), wr_out.size()));
  endtask

  task automatic clear_model();
    automatic int i;
    while (rd_out.size()   > 0) begin txn_drop[rd_out[0]]   = 1'b1; rd_out.delete(0);   end
    while (wr_out.size()   > 0) begin txn_drop[wr_out[0]]   = 1'b1; wr_out.delete(0);   end
    while (rd_fwd_q.size() > 0) begin txn_drop[rd_fwd_q[0]] = 1'b1; rd_fwd_q.delete(0); end
    while (wr_fwd_q.size() > 0) begin txn_drop[wr_fwd_q[0]] = 1'b1; wr_fwd_q.delete(0); end
    while (wdata_q.size()  > 0) begin txn_drop[wdata_q[0]]  = 1'b1; wdata_q.delete(0);  end
    for (i = 0; i < NMID; i++) begin rd_mid_owner[i] = -1; wr_mid_owner[i] = -1; end
    for (i = 0; i < NSID; i++) begin rd_credit[i] = 0; wr_credit[i] = 0; end
    exp_w_data.delete(); exp_w_strb.delete(); exp_w_last.delete();
    pend_ar_tag = -1; pend_aw_tag = -1;
  endtask

  // ==========================================================================
  //  Test sequence
  // ==========================================================================
  initial begin : main
    automatic bit acc;
    automatic int i, n, tg, sid, len, m;

    s_awid = '0; s_awaddr = '0; s_awlen = '0; s_awvalid = 1'b0;
    s_wdata = '0; s_wstrb = '0; s_wlast = 1'b0; s_wvalid = 1'b0;
    s_arid = '0; s_araddr = '0; s_arlen = '0; s_arvalid = 1'b0;
    s_bready = 1'b1; s_rready = 1'b1;
    m_awready = 1'b1; m_wready = 1'b1; m_arready = 1'b1;
    m_rid = '0; m_rdata = '0; m_rresp = 2'b00; m_rlast = 1'b0; m_rvalid = 1'b0;
    m_bid = '0; m_bresp = 2'b00; m_bvalid = 1'b0;

    nerr = 0; cyc = 0; next_tag = 0; rst_low_cnt = 0;
    auto_resp = 1'b0; quiet_chk = 1'b0;
    pend_ar_tag = -1; pend_aw_tag = -1;
    a4_rd_arm = 0; a4_wr_arm = 0;
    for (i = 0; i < NMID; i++) begin rd_mid_owner[i] = -1; wr_mid_owner[i] = -1; end
    for (i = 0; i < NSID; i++) begin rd_credit[i] = 0; wr_credit[i] = 0; end
    for (i = 0; i < MAXTXN; i++) begin
      txn_sid[i]=0; txn_len[i]=0; txn_mid[i]=-1; txn_fwd[i]=0;
      txn_bcnt[i]=0; txn_isrd[i]=0; txn_drop[i]=0; req_len[i]=0;
    end

    bfm_reset(4);
    repeat (3) @(posedge clk);

    // ---------------------------------------------------------------------
    // Phase 1 -- the read-side boundary (A2, A3, A5)
    // ---------------------------------------------------------------------
    // MAX_UNIQ_IDS distinct ids must all be accepted; in particular the last
    // one, offered when MAX_UNIQ_IDS-1 are outstanding, must go.
    for (i = 0; i < int'(MAX_UNIQ_IDS); i++)
      do_ar(i+1, 0, BUDGET_ACCEPT, 1, "A3", acc);

    // One more distinct id must not be accepted while the table is full.
    do_ar(9, 0, BUDGET_REFUSE, 2, "A3", acc);

    // An id already outstanding is not blocked by A3.
    do_ar(1, 1, BUDGET_ACCEPT, 1, "A3", acc);

    // ... but A5 caps it at MAX_TXNS_PER_ID.
    do_ar(1, 0, BUDGET_REFUSE, 2, "A5", acc);

    // ---------------------------------------------------------------------
    // Phase 2 -- A4 on the read side: retirement frees an entry within 2 cycles
    // ---------------------------------------------------------------------
    tg = rd_first_sid(4);
    if (tg < 0) fail("A1", "read for slave id 4 is not outstanding as expected");
    else begin
      wait_fwd(tg, 200);
      if (txn_mid[tg] >= 0 && rd_fwd_first_mid(txn_mid[tg]) == tg) begin
        a4_rd_sid = 4; a4_rd_new = 10;
        a4_rd_ret = 0; a4_rd_acc = 0; a4_rd_arm = 1;
        fork
          do_ar(10, 0, BUDGET_ACCEPT, 1, "A4", acc);
          begin
            repeat (6) @(posedge clk);   // the new id is refused meanwhile
            send_rd_resp(txn_mid[tg]);
          end
        join
        a4_rd_arm = 0;
        if (!a4_rd_ret)
          fail("A4", "slave id 4 never retired on the read side");
        else if (!a4_rd_acc)
          fail("A4", "a new read id offered continuously across a retirement was never accepted");
        else if ((a4_rd_acc_cyc - a4_rd_ret_cyc) > 2)
          fail("A4", $sformatf("new read id accepted %0d cycles after the retiring edge (limit is 2)",
                               a4_rd_acc_cyc - a4_rd_ret_cyc));
      end
    end

    drain_active(3000);
    repeat (5) @(posedge clk);

    // ---------------------------------------------------------------------
    // Phase 3 -- the write-side boundary (A2, A3, A5) and A4
    // ---------------------------------------------------------------------
    for (i = 0; i < int'(MAX_UNIQ_IDS); i++)
      do_aw(i+1, 0, BUDGET_ACCEPT, 1, "A3", acc);

    do_aw(9, 0, BUDGET_REFUSE, 2, "A3", acc);
    do_aw(1, 1, BUDGET_ACCEPT, 1, "A3", acc);
    do_aw(1, 0, BUDGET_REFUSE, 2, "A5", acc);

    wait_wdrain(2000);

    tg = wr_first_sid(4);
    if (tg < 0) fail("A1", "write for slave id 4 is not outstanding as expected");
    else begin
      wait_fwd(tg, 200);
      if (txn_mid[tg] >= 0 && wr_fwd_first_mid(txn_mid[tg]) == tg) begin
        a4_wr_sid = 4; a4_wr_new = 10;
        a4_wr_ret = 0; a4_wr_acc = 0; a4_wr_arm = 1;
        fork
          do_aw(10, 0, BUDGET_ACCEPT, 1, "A4", acc);
          begin
            repeat (6) @(posedge clk);
            send_wr_resp(txn_mid[tg]);
          end
        join
        a4_wr_arm = 0;
        if (!a4_wr_ret)
          fail("A4", "slave id 4 never retired on the write side");
        else if (!a4_wr_acc)
          fail("A4", "a new write id offered continuously across a retirement was never accepted");
        else if ((a4_wr_acc_cyc - a4_wr_ret_cyc) > 2)
          fail("A4", $sformatf("new write id accepted %0d cycles after the retiring edge (limit is 2)",
                               a4_wr_acc_cyc - a4_wr_ret_cyc));
      end
    end

    wait_wdrain(2000);
    drain_active(3000);
    repeat (5) @(posedge clk);

    // ---------------------------------------------------------------------
    // Phase 4 -- reset (F1)
    // ---------------------------------------------------------------------
    do_ar(3, 0, BUDGET_ACCEPT, 1, "A3", acc);
    do_ar(5, 1, BUDGET_ACCEPT, 1, "A3", acc);
    do_aw(6, 0, BUDGET_ACCEPT, 1, "A3", acc);
    do_aw(7, 0, BUDGET_ACCEPT, 1, "A3", acc);
    wait_wdrain(2000);
    repeat (5) @(posedge clk);

    bfm_reset(4);
    clear_model();
    quiet_chk = 1'b1;
    repeat (40) @(posedge clk);
    quiet_chk = 1'b0;

    // The table is empty again, so MAX_UNIQ_IDS distinct ids are accepted...
    for (i = 0; i < int'(MAX_UNIQ_IDS); i++)
      do_ar(i+11, 0, BUDGET_ACCEPT, 1, "F1", acc);
    // ...and the boundary is back in force.
    do_ar(2, 0, BUDGET_REFUSE, 2, "A3", acc);
    drain_active(3000);
    repeat (5) @(posedge clk);

    // ---------------------------------------------------------------------
    // Phase 5 -- randomised traffic (B1, B3, C1, C2, D1, D2, D4, E1, and the
    //            acceptance-side checks of A3/A5 under contention)
    // ---------------------------------------------------------------------
    auto_resp = 1'b1;
    fork
      begin : rd_gen
        automatic int k, rsid, rlen;
        automatic bit a;
        for (k = 0; k < 140; k++) begin
          rsid = $urandom_range(1, 6);
          rlen = $urandom_range(0, 2);
          do_ar(rsid, rlen, 60, 0, "A3", a);
          repeat ($urandom_range(0, 3)) @(posedge clk);
        end
      end
      begin : wr_gen
        automatic int k, wsid, wlen;
        automatic bit a;
        for (k = 0; k < 140; k++) begin
          wsid = $urandom_range(1, 6);
          wlen = $urandom_range(0, 2);
          do_aw(wsid, wlen, 60, 0, "A3", a);
          repeat ($urandom_range(0, 3)) @(posedge clk);
        end
      end
    join

    drain_passive(20000);
    auto_resp = 1'b0;
    repeat (10) @(posedge clk);

    // ---------------------------------------------------------------------
    // Final consistency (D4)
    // ---------------------------------------------------------------------
    if (exp_w_data.size() != 0)
      fail("B3", $sformatf("%0d slave write data beats were never forwarded on the master port", exp_w_data.size()));
    if (rd_fwd_q.size() != 0 || wr_fwd_q.size() != 0)
      fail("D4", "master transactions remain unanswered at end of test");

    if (nerr == 0) $display("RESULT: PASS");
    else           $display("RESULT: FAIL");
    $finish;
  end

endmodule