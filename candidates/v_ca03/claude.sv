// ===========================================================================
// id_width_conv_tb.sv -- self-checking testbench for id_width_conv.
//
// The contract is mostly about a bounded table of identifier conversions, so
// the testbench maintains a model of that table: which slave identifiers are
// outstanding in each direction, how many transactions each holds, which master
// identifier each is using, and the exact response beats each is owed.
//
// WHAT IS DELIBERATELY NOT CHECKED, because the contract leaves it free and a
// check would reject correct hardware:
//   B2  the relative order of responses carrying DIFFERENT slave identifiers;
//   D3  which master identifier is chosen, and the allocation order -- only
//       distinctness and reuse-after-retirement are checked, never a value;
//   latency anywhere, and the promptness of s_arready/s_awready except inside
//       A4's 2-cycle window, which is the one place the contract bounds it.  A
//       refusal is therefore only ever a failure where A3/A4/A5 give an exact
//       boundary;
//   s_bresp -- E1 lists addr/len, W data/strb/last and R data/resp/last, and
//       bresp is not among them;
//   the value of any output while its valid is low.
//
// Transactions are identified by bookkeeping: every request is given a unique
// address, so a master request is matched to its slave request by address, and
// every data beat is derived from the transaction's tag so that no expected
// value ever repeats.
// ===========================================================================

`timescale 1ns/1ps

module id_width_conv_tb;

  // ---------------- scored configuration ----------------
  localparam int unsigned SLV_ID_W        = 4;
  localparam int unsigned MST_ID_W        = 2;
  localparam int unsigned ADDR_W          = 32;
  localparam int unsigned DATA_W          = 32;
  localparam int unsigned MAX_UNIQ_IDS    = 4;
  localparam int unsigned MAX_TXNS_PER_ID = 2;

  localparam int NSID = 1 << SLV_ID_W;   // 16 slave identifiers
  localparam int NMID = 1 << MST_ID_W;   // 4 master identifiers

  // ---------------- DUT connections ----------------
  logic [SLV_ID_W-1:0]   s_awid;
  logic [ADDR_W-1:0]     s_awaddr;
  logic [7:0]            s_awlen;
  logic                  s_awvalid, s_awready;

  logic [DATA_W-1:0]     s_wdata;
  logic [DATA_W/8-1:0]   s_wstrb;
  logic                  s_wlast, s_wvalid, s_wready;

  logic [SLV_ID_W-1:0]   s_bid;
  logic [1:0]            s_bresp;
  logic                  s_bvalid, s_bready;

  logic [SLV_ID_W-1:0]   s_arid;
  logic [ADDR_W-1:0]     s_araddr;
  logic [7:0]            s_arlen;
  logic                  s_arvalid, s_arready;

  logic [SLV_ID_W-1:0]   s_rid;
  logic [DATA_W-1:0]     s_rdata;
  logic [1:0]            s_rresp;
  logic                  s_rlast, s_rvalid, s_rready;

  logic [MST_ID_W-1:0]   m_awid;
  logic [ADDR_W-1:0]     m_awaddr;
  logic [7:0]            m_awlen;
  logic                  m_awvalid, m_awready;

  logic [DATA_W-1:0]     m_wdata;
  logic [DATA_W/8-1:0]   m_wstrb;
  logic                  m_wlast, m_wvalid, m_wready;

  logic [MST_ID_W-1:0]   m_bid;
  logic [1:0]            m_bresp;
  logic                  m_bvalid, m_bready;

  logic [MST_ID_W-1:0]   m_arid;
  logic [ADDR_W-1:0]     m_araddr;
  logic [7:0]            m_arlen;
  logic                  m_arvalid, m_arready;

  logic [MST_ID_W-1:0]   m_rid;
  logic [DATA_W-1:0]     m_rdata;
  logic [1:0]            m_rresp;
  logic                  m_rlast, m_rvalid, m_rready;

  // =========================================================================
  // PROVIDED PLUMBING -- moves transactions, checks nothing.
  // =========================================================================
  logic clk;
  initial begin clk = 1'b0; forever #5 clk = ~clk; end

  logic rst_n;
  initial rst_n = 1'b0;

  // Asserted and released away from the sampling edge.
  task automatic bfm_reset(input int cycles = 4);
    @(negedge clk);
    rst_n = 1'b0;
    repeat (cycles) @(posedge clk);
    @(negedge clk);
    rst_n = 1'b1;
  endtask

  // Offer a read address and hold it stable until accepted or the budget runs
  // out. Reports BOTH facts: whether it went, and how many cycles it waited.
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

  // The same for a write address.
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

  // Watchdog. Fires regardless of what the design does.
  initial begin
    #4_000_000;
    $display("RESULT: FAIL (watchdog: no forward progress)");
    $finish;
  end

  // =========================================================================
  // DUT
  // =========================================================================
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

  // =========================================================================
  // Model state
  // =========================================================================
  int errors;
  int cyc;
  int next_tag;
  logic [ADDR_W-1:0] next_addr;
  int post_reset_watch;      // >0 while checking F1's discard requirement
  int quiet_master;          // >0 while stale master activity must be ignored

  // per-transaction facts, keyed by tag
  int          tag_sid  [int];
  int          tag_len  [int];
  int          tag_mid  [int];   // -1 until the master request is seen
  bit          tag_wdone[int];   // master write data complete
  logic [ADDR_W-1:0] tag_addr[int];
  int                tag_by_addr[logic [ADDR_W-1:0]];

  // read side
  int rd_live [$];               // accepted, not yet completed, in accept order
  int rd_await[$];               // accepted, master AR not yet seen
  int rd_mreq [$];               // master AR seen, not yet responded
  int rd_cnt  [NSID];            // outstanding per slave id
  int rd_beat [NSID];            // beats delivered for the head txn of this id
  int rd_mid_owner[NMID];        // slave id owning this master id, -1 free
  int rd_mid_ref  [NMID];

  // write side
  int wr_live [$];
  int wr_await[$];
  int wr_mreq [$];
  int wr_cnt  [NSID];
  int wr_mid_owner[NMID];
  int wr_mid_ref  [NMID];

  // expected master write beat stream (B3 / E1)
  logic [DATA_W-1:0]   wexp_data[$];
  logic [DATA_W/8-1:0] wexp_strb[$];
  bit                  wexp_last[$];
  int                  wexp_tag [$];
  int                  w_tag_order[$];   // AW accept order, for beat ownership

  // timing witnesses for A4
  int ar_acc_cyc [NSID];
  int aw_acc_cyc [NSID];
  int rd_ret_cyc [NSID];
  int wr_ret_cyc [NSID];

  // D4 counters
  int n_s_ar, n_m_ar, n_s_aw, n_m_aw;
  int n_s_rlast, n_m_rlast, n_s_b, n_m_b;

  // stress control
  bit ar_done, aw_done;
  int rr_r, rr_b;

  // =========================================================================
  // helpers
  // =========================================================================
  task automatic fail(input string code, input string msg);
    errors = errors + 1;
    if (errors <= 40)
      $display("FAIL [%0s] time=%0t cyc=%0d : %0s", code, $time, cyc, msg);
  endtask

  // Expected payloads are derived from the tag, so no expected value repeats.
  function automatic logic [DATA_W-1:0] exp_rdata(input int tg, input int idx);
    return {tg[15:0], idx[15:0]};
  endfunction

  function automatic logic [1:0] exp_rresp(input int tg, input int idx);
    return (((tg + idx) % 4) == 3) ? 2'b10 : 2'b00;
  endfunction

  function automatic logic [DATA_W-1:0] exp_wdata(input int tg, input int idx);
    return {~tg[15:0], idx[15:0]};
  endfunction

  function automatic logic [DATA_W/8-1:0] exp_wstrb(input int tg, input int idx);
    return (((tg + idx) % 3) == 0) ? 4'hF : 4'h5;
  endfunction

  function automatic int head_tag_sid_rd(input int sid);
    automatic int i;
    for (i = 0; i < rd_live.size(); i++)
      if (tag_sid[rd_live[i]] == sid) return rd_live[i];
    return -1;
  endfunction

  function automatic int head_tag_sid_wr(input int sid);
    automatic int i;
    for (i = 0; i < wr_live.size(); i++)
      if (tag_sid[wr_live[i]] == sid) return wr_live[i];
    return -1;
  endfunction

  function automatic int head_tag_mid_rd(input int mid);
    automatic int i;
    for (i = 0; i < rd_mreq.size(); i++)
      if (tag_mid[rd_mreq[i]] == mid) return rd_mreq[i];
    return -1;
  endfunction

  function automatic int head_tag_mid_wr(input int mid);
    automatic int i;
    for (i = 0; i < wr_mreq.size(); i++)
      if (tag_mid[wr_mreq[i]] == mid) return wr_mreq[i];
    return -1;
  endfunction

  function automatic int rd_distinct();
    automatic int i, n;
    n = 0;
    for (i = 0; i < NSID; i++) if (rd_cnt[i] > 0) n = n + 1;
    return n;
  endfunction

  function automatic int wr_distinct();
    automatic int i, n;
    n = 0;
    for (i = 0; i < NSID; i++) if (wr_cnt[i] > 0) n = n + 1;
    return n;
  endfunction

  function automatic int rd_busy();
    return rd_await.size() + rd_mreq.size() + rd_live.size();
  endfunction

  function automatic int wr_busy();
    return wr_await.size() + wr_mreq.size() + wr_live.size();
  endfunction

  task automatic model_clear();
    automatic int i;
    // Counters are per-era: a reset discards work in flight, so counts taken
    // across a reset boundary would not balance even for correct hardware.
    n_s_ar = 0; n_m_ar = 0; n_s_aw = 0; n_m_aw = 0;
    n_s_rlast = 0; n_m_rlast = 0; n_s_b = 0; n_m_b = 0;
    tag_by_addr.delete();
    rd_live.delete(); rd_await.delete(); rd_mreq.delete();
    wr_live.delete(); wr_await.delete(); wr_mreq.delete();
    wexp_data.delete(); wexp_strb.delete(); wexp_last.delete(); wexp_tag.delete();
    w_tag_order.delete();
    for (i = 0; i < NSID; i++) begin
      rd_cnt[i] = 0; wr_cnt[i] = 0; rd_beat[i] = 0;
      ar_acc_cyc[i] = -1; aw_acc_cyc[i] = -1;
      rd_ret_cyc[i] = -1; wr_ret_cyc[i] = -1;
    end
    for (i = 0; i < NMID; i++) begin
      rd_mid_owner[i] = -1; rd_mid_ref[i] = 0;
      wr_mid_owner[i] = -1; wr_mid_ref[i] = 0;
    end
  endtask

  // =========================================================================
  // MONITOR -- one block, so the order of events inside a cycle is defined.
  // Retirements are processed BEFORE acceptances and before master requests, so
  // a design that frees an entry and reuses it on the same edge is accepted.
  // =========================================================================
  always @(posedge clk) begin
    int i, tg, sid, mid, idx, ln, hit;

    cyc = cyc + 1;

    if (!rst_n) begin
      // F1: idle while reset is low.
      if (s_arvalid && s_arready) fail("F1", "AR handshake occurred while rst_ni was low");
      if (s_awvalid && s_awready) fail("F1", "AW handshake occurred while rst_ni was low");
      if (s_wvalid  && s_wready ) fail("F1", "W handshake occurred while rst_ni was low");
      if (s_rvalid)               fail("F1", "read response presented while rst_ni was low");
      if (s_bvalid)               fail("F1", "write response presented while rst_ni was low");
    end
    else begin
      if (post_reset_watch > 0) begin
        post_reset_watch = post_reset_watch - 1;
        // F1: nothing outstanding before the reset may answer after it.
        if (s_rvalid) fail("F1", "read response after reset for a discarded transaction");
        if (s_bvalid) fail("F1", "write response after reset for a discarded transaction");
      end
      if (quiet_master > 0) quiet_master = quiet_master - 1;

      // ------------------------------------------------ retirements first
      if (s_rvalid && s_rready) begin
        sid = int'(s_rid);
        tg  = head_tag_sid_rd(sid);
        if (tg < 0) begin
          // C1 is reported here per the spec: a wrongly restored identifier
          // shows up as a beat for an id with nothing outstanding.
          fail("C2", $sformatf("read beat for slave id %0d with no outstanding transaction", sid));
        end
        else begin
          idx = rd_beat[sid];
          ln  = tag_len[tg];
          if (s_rdata !== exp_rdata(tg, idx))
            fail("E1", $sformatf("read data for id %0d beat %0d: got %08h expected %08h",
                                 sid, idx, s_rdata, exp_rdata(tg, idx)));
          if (s_rresp !== exp_rresp(tg, idx))
            fail("E1", $sformatf("read resp for id %0d beat %0d: got %02b expected %02b",
                                 sid, idx, s_rresp, exp_rresp(tg, idx)));
          if (s_rlast !== ((idx == ln) ? 1'b1 : 1'b0))
            fail("E1", $sformatf("read last for id %0d beat %0d of %0d: got %0b",
                                 sid, idx, ln, s_rlast));
          if (s_rlast) begin
            // A1: the transaction is outstanding until this edge.
            rd_beat[sid] = 0;
            for (i = 0; i < rd_live.size(); i++)
              if (rd_live[i] == tg) begin rd_live.delete(i); break; end
            rd_cnt[sid] = rd_cnt[sid] - 1;
            n_s_rlast = n_s_rlast + 1;
            if (tag_mid[tg] >= 0) begin
              mid = tag_mid[tg];
              rd_mid_ref[mid] = rd_mid_ref[mid] - 1;
              if (rd_mid_ref[mid] <= 0) begin
                rd_mid_ref[mid] = 0;
                rd_mid_owner[mid] = -1;   // D2: free only now
              end
            end
            if (rd_cnt[sid] == 0) rd_ret_cyc[sid] = cyc;   // A4 witness
          end
          else begin
            rd_beat[sid] = idx + 1;
          end
        end
      end

      if (s_bvalid && s_bready) begin
        sid = int'(s_bid);
        tg  = head_tag_sid_wr(sid);
        if (tg < 0) begin
          fail("C2", $sformatf("write response for slave id %0d with no outstanding transaction", sid));
        end
        else begin
          for (i = 0; i < wr_live.size(); i++)
            if (wr_live[i] == tg) begin wr_live.delete(i); break; end
          wr_cnt[sid] = wr_cnt[sid] - 1;
          n_s_b = n_s_b + 1;
          if (tag_mid[tg] >= 0) begin
            mid = tag_mid[tg];
            wr_mid_ref[mid] = wr_mid_ref[mid] - 1;
            if (wr_mid_ref[mid] <= 0) begin
              wr_mid_ref[mid] = 0;
              wr_mid_owner[mid] = -1;
            end
          end
          if (wr_cnt[sid] == 0) wr_ret_cyc[sid] = cyc;
        end
      end

      // ------------------------------------------------ slave acceptances
      if (s_arvalid && s_arready) begin
        sid = int'(s_arid);
        tg  = next_tag; next_tag = next_tag + 1;
        tag_sid[tg]   = sid;
        tag_addr[tg]  = s_araddr;
        tag_by_addr[s_araddr] = tg;
        tag_len[tg]   = int'(s_arlen);
        tag_mid[tg]   = -1;
        tag_wdone[tg] = 1'b0;
        // A5: depth per identifier.
        if (rd_cnt[sid] >= MAX_TXNS_PER_ID)
          fail("A5", $sformatf("read id %0d accepted with %0d already outstanding (max %0d)",
                               sid, rd_cnt[sid], MAX_TXNS_PER_ID));
        // A3: a new identifier accepted while the table is full.
        if ((rd_cnt[sid] == 0) && (rd_distinct() >= MAX_UNIQ_IDS))
          fail("A3", $sformatf("new read id %0d accepted while %0d distinct ids already outstanding",
                               sid, rd_distinct()));
        rd_cnt[sid] = rd_cnt[sid] + 1;
        rd_live.push_back(tg);
        rd_await.push_back(tg);
        ar_acc_cyc[sid] = cyc;
        n_s_ar = n_s_ar + 1;
      end

      if (s_awvalid && s_awready) begin
        sid = int'(s_awid);
        tg  = next_tag; next_tag = next_tag + 1;
        tag_sid[tg]   = sid;
        tag_addr[tg]  = s_awaddr;
        tag_by_addr[s_awaddr] = tg;
        tag_len[tg]   = int'(s_awlen);
        tag_mid[tg]   = -1;
        tag_wdone[tg] = 1'b0;
        if (wr_cnt[sid] >= MAX_TXNS_PER_ID)
          fail("A5", $sformatf("write id %0d accepted with %0d already outstanding (max %0d)",
                               sid, wr_cnt[sid], MAX_TXNS_PER_ID));
        if ((wr_cnt[sid] == 0) && (wr_distinct() >= MAX_UNIQ_IDS))
          fail("A3", $sformatf("new write id %0d accepted while %0d distinct ids already outstanding",
                               sid, wr_distinct()));
        wr_cnt[sid] = wr_cnt[sid] + 1;
        wr_live.push_back(tg);
        wr_await.push_back(tg);
        w_tag_order.push_back(tg);
        aw_acc_cyc[sid] = cyc;
        n_s_aw = n_s_aw + 1;
      end

      // Slave write beat accepted: record what the master port owes (B3/E1).
      if (s_wvalid && s_wready) begin
        if (w_tag_order.size() == 0) begin
          fail("D4", "write data beat accepted with no accepted write address outstanding");
        end
        else begin
          tg = w_tag_order[0];
          wexp_data.push_back(s_wdata);
          wexp_strb.push_back(s_wstrb);
          wexp_last.push_back(s_wlast);
          wexp_tag .push_back(tg);
          if (s_wlast) w_tag_order.delete(0);
        end
      end

      // ------------------------------------------------ master port
      if (m_arvalid && m_arready) begin
        n_m_ar = n_m_ar + 1;
        hit = -1;
        for (i = 0; i < rd_await.size(); i++)
          if (tag_addr[rd_await[i]] == m_araddr) begin hit = i; break; end
        if (hit < 0) begin
          if (quiet_master == 0)
            fail("E1", $sformatf("master AR addr %08h matches no accepted slave read request", m_araddr));
        end
        else begin
          tg  = rd_await[hit];
          mid = int'(m_arid);
          rd_await.delete(hit);
          if (int'(m_arlen) != tag_len[tg])
            fail("E1", $sformatf("master AR len for addr %08h: got %0d expected %0d",
                                 m_araddr, m_arlen, tag_len[tg]));
          // D1/D2: a master id may not serve two different slave ids at once,
          // and is free for a different one only once its owner has retired.
          if ((rd_mid_owner[mid] >= 0) && (rd_mid_owner[mid] != tag_sid[tg]))
            fail("D1", $sformatf("master read id %0d used for slave id %0d while still held by slave id %0d",
                                 mid, tag_sid[tg], rd_mid_owner[mid]));
          rd_mid_owner[mid] = tag_sid[tg];
          rd_mid_ref[mid]   = rd_mid_ref[mid] + 1;
          tag_mid[tg]       = mid;
          rd_mreq.push_back(tg);
        end
      end

      if (m_awvalid && m_awready) begin
        n_m_aw = n_m_aw + 1;
        hit = -1;
        for (i = 0; i < wr_await.size(); i++)
          if (tag_addr[wr_await[i]] == m_awaddr) begin hit = i; break; end
        if (hit < 0) begin
          if (quiet_master == 0)
            fail("E1", $sformatf("master AW addr %08h matches no accepted slave write request", m_awaddr));
        end
        else begin
          tg  = wr_await[hit];
          mid = int'(m_awid);
          wr_await.delete(hit);
          if (int'(m_awlen) != tag_len[tg])
            fail("E1", $sformatf("master AW len for addr %08h: got %0d expected %0d",
                                 m_awaddr, m_awlen, tag_len[tg]));
          if ((wr_mid_owner[mid] >= 0) && (wr_mid_owner[mid] != tag_sid[tg]))
            fail("D1", $sformatf("master write id %0d used for slave id %0d while still held by slave id %0d",
                                 mid, tag_sid[tg], wr_mid_owner[mid]));
          wr_mid_owner[mid] = tag_sid[tg];
          wr_mid_ref[mid]   = wr_mid_ref[mid] + 1;
          tag_mid[tg]       = mid;
          wr_mreq.push_back(tg);
        end
      end

      // B3/E1: master write beats must be the slave stream, in order, unbroken.
      if (m_wvalid && m_wready) begin
        if (wexp_data.size() == 0) begin
          if (quiet_master == 0)
            fail("E1", "master write beat with no corresponding slave write beat");
        end
        else begin
          if (m_wdata !== wexp_data[0])
            fail("E1", $sformatf("master write data: got %08h expected %08h", m_wdata, wexp_data[0]));
          if (m_wstrb !== wexp_strb[0])
            fail("E1", $sformatf("master write strb: got %0h expected %0h", m_wstrb, wexp_strb[0]));
          if (m_wlast !== wexp_last[0])
            fail("E1", $sformatf("master write last: got %0b expected %0b", m_wlast, wexp_last[0]));
          if (wexp_last[0]) tag_wdone[wexp_tag[0]] = 1'b1;
          wexp_data.delete(0); wexp_strb.delete(0);
          wexp_last.delete(0); wexp_tag.delete(0);
        end
      end
    end
  end

  // =========================================================================
  // Downstream response drivers (bounded, so nothing can hang).
  // =========================================================================
  task automatic drv_rbeat(input logic [MST_ID_W-1:0] mid,
                           input logic [DATA_W-1:0]   data,
                           input logic [1:0]          rsp,
                           input logic                is_last);
    automatic int guard;
    guard = 0;
    @(negedge clk);
    m_rid = mid; m_rdata = data; m_rresp = rsp; m_rlast = is_last; m_rvalid = 1'b1;
    while (guard < 3000) begin
      @(posedge clk);
      if (m_rready) break;
      guard = guard + 1;
    end
    if (guard >= 3000) fail("D4", "design never accepted a downstream read response beat");
    @(negedge clk) m_rvalid = 1'b0;
  endtask

  task automatic drv_bbeat(input logic [MST_ID_W-1:0] mid);
    automatic int guard;
    guard = 0;
    @(negedge clk);
    m_bid = mid; m_bresp = 2'b00; m_bvalid = 1'b1;
    while (guard < 3000) begin
      @(posedge clk);
      if (m_bready) break;
      guard = guard + 1;
    end
    if (guard >= 3000) fail("D4", "design never accepted a downstream write response");
    @(negedge clk) m_bvalid = 1'b0;
  endtask

  task automatic drv_wbeat(input logic [DATA_W-1:0]   data,
                           input logic [DATA_W/8-1:0] strb,
                           input logic                is_last);
    automatic int guard;
    guard = 0;
    @(negedge clk);
    s_wdata = data; s_wstrb = strb; s_wlast = is_last; s_wvalid = 1'b1;
    while (guard < 3000) begin
      @(posedge clk);
      if (s_wready) break;
      guard = guard + 1;
    end
    if (guard >= 3000) fail("D4", "design never accepted a slave write data beat");
    @(negedge clk) s_wvalid = 1'b0;
  endtask

  // Respond to the oldest outstanding master read transaction on `mid`.
  task automatic resp_read_mid(input int mid);
    automatic int tg, ln, i;
    tg = head_tag_mid_rd(mid);
    if (tg < 0) return;
    for (i = 0; i < rd_mreq.size(); i++)
      if (rd_mreq[i] == tg) begin rd_mreq.delete(i); break; end
    ln = tag_len[tg];
    for (i = 0; i <= ln; i++)
      drv_rbeat(mid[MST_ID_W-1:0], exp_rdata(tg, i), exp_rresp(tg, i), (i == ln));
    n_m_rlast = n_m_rlast + 1;
  endtask

  task automatic resp_write_mid(input int mid);
    automatic int tg, i;
    tg = head_tag_mid_wr(mid);
    if (tg < 0) return;
    for (i = 0; i < wr_mreq.size(); i++)
      if (wr_mreq[i] == tg) begin wr_mreq.delete(i); break; end
    drv_bbeat(mid[MST_ID_W-1:0]);
    n_m_b = n_m_b + 1;
  endtask

  // Complete the oldest outstanding read of one slave id, waiting (bounded)
  // for its master request to appear first.  Latency is free, so this waits.
  task automatic complete_read_sid(input int sid);
    automatic int tg, guard;
    tg = head_tag_sid_rd(sid);
    if (tg < 0) return;
    guard = 0;
    while ((tag_mid[tg] < 0) && (guard < 500)) begin @(posedge clk); guard = guard + 1; end
    if (tag_mid[tg] < 0) begin
      fail("D4", $sformatf("no master read request appeared for accepted slave id %0d", sid));
      return;
    end
    resp_read_mid(tag_mid[tg]);
  endtask

  task automatic complete_write_sid(input int sid);
    automatic int tg, guard;
    tg = head_tag_sid_wr(sid);
    if (tg < 0) return;
    guard = 0;
    while (((tag_mid[tg] < 0) || !tag_wdone[tg]) && (guard < 500)) begin
      @(posedge clk); guard = guard + 1;
    end
    if (tag_mid[tg] < 0) begin
      fail("D4", $sformatf("no master write request appeared for accepted slave id %0d", sid));
      return;
    end
    resp_write_mid(tag_mid[tg]);
  endtask

  // =========================================================================
  // Stimulus helpers
  // =========================================================================
  task automatic do_ar(input int id, input int ln, input int budget,
                       output bit acc, output int wt);
    automatic logic [ADDR_W-1:0] a;
    a = next_addr; next_addr = next_addr + 32'h40;
    bfm_ar(id[SLV_ID_W-1:0], a, ln[7:0], budget, acc, wt);
  endtask

  // Offer a write address and, if accepted, its data beats.  Beats are driven
  // in address-acceptance order, which is what B3 requires of the master port.
  task automatic do_aw(input int id, input int ln, input int budget,
                       output bit acc, output int wt);
    automatic logic [ADDR_W-1:0] a;
    automatic int tg, i;
    a = next_addr; next_addr = next_addr + 32'h40;
    bfm_aw(id[SLV_ID_W-1:0], a, ln[7:0], budget, acc, wt);
    if (acc) begin
      tg = -1;
      if (tag_by_addr.exists(a)) tg = tag_by_addr[a];
      if (tg >= 0)
        for (i = 0; i <= ln; i++)
          drv_wbeat(exp_wdata(tg, i), exp_wstrb(tg, i), (i == ln));
    end
  endtask

  // =========================================================================
  // Directed tests
  // =========================================================================

  // A3 boundary and A4 window, read side.
  task automatic test_read_boundary();
    automatic bit acc; automatic int wt; automatic int i;
    automatic bit acc2; automatic int wt2;

    // Fill to MAX_UNIQ_IDS-1 distinct identifiers.
    for (i = 0; i < MAX_UNIQ_IDS - 1; i++) begin
      do_ar(i, 0, 100, acc, wt);
      if (!acc) fail("A3", $sformatf("read id %0d refused with only %0d distinct ids outstanding", i, i));
    end
    // A3: at MAX_UNIQ_IDS-1 a further NEW identifier must be accepted.
    do_ar(MAX_UNIQ_IDS - 1, 0, 100, acc, wt);
    if (!acc)
      fail("A3", $sformatf("new read id refused with only %0d distinct ids outstanding",
                           MAX_UNIQ_IDS - 1));

    // A3: at MAX_UNIQ_IDS a further NEW identifier must NOT be accepted while
    // nothing retires.  Nothing is completed during this window.
    do_ar(9, 0, 20, acc, wt);
    if (acc) fail("A3", "new read id accepted while the table was full");

    // A3: an identifier ALREADY outstanding is not blocked by this clause.
    do_ar(0, 0, 100, acc, wt);
    if (!acc) fail("A3", "already-outstanding read id refused although A3 does not block it");

    // A4: hold a new identifier and retire one; acceptance must come within
    // 2 cycles of the retiring edge.
    fork
      begin
        do_ar(9, 0, 200, acc2, wt2);
      end
      begin
        repeat (6) @(posedge clk);
        if (ar_acc_cyc[9] >= 0)
          fail("A3", "new read id accepted before any identifier retired");
        complete_read_sid(1);      // id 1 holds exactly one transaction
      end
    join
    if (!acc2) begin
      fail("A4", "new read id never accepted after an identifier retired");
    end
    else if ((rd_ret_cyc[1] >= 0) && (ar_acc_cyc[9] >= 0)) begin
      if ((ar_acc_cyc[9] - rd_ret_cyc[1]) > 2)
        fail("A4", $sformatf("new read id accepted %0d cycles after retirement (limit 2)",
                             ar_acc_cyc[9] - rd_ret_cyc[1]));
    end

    // Drain everything that is still outstanding.
    drain_reads(2000);
  endtask

  // A5 depth, read side.
  task automatic test_read_depth();
    automatic bit acc; automatic int wt; automatic int i;
    for (i = 0; i < MAX_TXNS_PER_ID; i++) begin
      do_ar(5, 1, 100, acc, wt);
      if (!acc) fail("A5", $sformatf("read id 5 refused at depth %0d (max %0d)", i, MAX_TXNS_PER_ID));
    end
    // A5: one more with the same identifier must not be accepted.
    do_ar(5, 1, 20, acc, wt);
    if (acc) fail("A5", "read id accepted beyond MAX_TXNS_PER_ID");
    // After one completes it must be accepted again.
    complete_read_sid(5);
    do_ar(5, 1, 200, acc, wt);
    if (!acc) fail("A5", "read id refused after one of its transactions completed");
    drain_reads(2000);
  endtask

  // A3 boundary and A4 window, write side.
  task automatic test_write_boundary();
    automatic bit acc; automatic int wt; automatic int i;
    automatic bit acc2; automatic int wt2;

    for (i = 0; i < MAX_UNIQ_IDS - 1; i++) begin
      do_aw(i, 0, 100, acc, wt);
      if (!acc) fail("A3", $sformatf("write id %0d refused with only %0d distinct ids outstanding", i, i));
    end
    do_aw(MAX_UNIQ_IDS - 1, 0, 100, acc, wt);
    if (!acc)
      fail("A3", $sformatf("new write id refused with only %0d distinct ids outstanding",
                           MAX_UNIQ_IDS - 1));

    do_aw(9, 0, 20, acc, wt);
    if (acc) fail("A3", "new write id accepted while the table was full");

    do_aw(0, 0, 100, acc, wt);
    if (!acc) fail("A3", "already-outstanding write id refused although A3 does not block it");

    fork
      begin
        do_aw(9, 0, 200, acc2, wt2);
      end
      begin
        repeat (6) @(posedge clk);
        if (aw_acc_cyc[9] >= 0)
          fail("A3", "new write id accepted before any identifier retired");
        complete_write_sid(1);
      end
    join
    if (!acc2) begin
      fail("A4", "new write id never accepted after an identifier retired");
    end
    else if ((wr_ret_cyc[1] >= 0) && (aw_acc_cyc[9] >= 0)) begin
      if ((aw_acc_cyc[9] - wr_ret_cyc[1]) > 2)
        fail("A4", $sformatf("new write id accepted %0d cycles after retirement (limit 2)",
                             aw_acc_cyc[9] - wr_ret_cyc[1]));
    end

    drain_writes(2000);
  endtask

  // A5 depth, write side.
  task automatic test_write_depth();
    automatic bit acc; automatic int wt; automatic int i;
    for (i = 0; i < MAX_TXNS_PER_ID; i++) begin
      do_aw(5, 1, 100, acc, wt);
      if (!acc) fail("A5", $sformatf("write id 5 refused at depth %0d (max %0d)", i, MAX_TXNS_PER_ID));
    end
    do_aw(5, 1, 20, acc, wt);
    if (acc) fail("A5", "write id accepted beyond MAX_TXNS_PER_ID");
    complete_write_sid(5);
    do_aw(5, 1, 200, acc, wt);
    if (!acc) fail("A5", "write id refused after one of its transactions completed");
    drain_writes(2000);
  endtask

  // =========================================================================
  // Drains
  // =========================================================================
  task automatic drain_reads(input int limit);
    automatic int guard, i, m;
    guard = 0;
    while ((rd_busy() > 0) && (guard < limit)) begin
      m = -1;
      for (i = 0; i < NMID; i++)
        if ((m < 0) && (head_tag_mid_rd(i) >= 0)) m = i;
      if (m < 0) begin @(posedge clk); guard = guard + 1; end
      else resp_read_mid(m);
    end
    if (rd_busy() > 0)
      fail("D4", "read transactions never completed");
  endtask

  task automatic drain_writes(input int limit);
    automatic int guard, i, m, tg;
    guard = 0;
    while ((wr_busy() > 0) && (guard < limit)) begin
      m = -1;
      for (i = 0; i < NMID; i++) begin
        tg = head_tag_mid_wr(i);
        if ((m < 0) && (tg >= 0) && tag_wdone[tg]) m = i;
      end
      if (m < 0) begin @(posedge clk); guard = guard + 1; end
      else resp_write_mid(m);
    end
    if (wr_busy() > 0)
      fail("D4", "write transactions never completed");
  endtask

  // =========================================================================
  // Stress -- concurrent reads and writes, responses returned out of order
  // across master identifiers (B2 permits that, and it exercises B1/C1/C2).
  // =========================================================================
  task automatic ar_gen(input int n);
    automatic int k; automatic bit acc; automatic int wt;
    for (k = 0; k < n; k++) begin
      // Six identifiers over four table entries, so the boundary is exercised.
      do_ar(k % 6, k % 4, 400, acc, wt);
      // A refusal inside the budget is NOT a failure: outside A3/A4/A5 the
      // contract does not bound readiness (named latitude 3).
    end
  endtask

  task automatic aw_gen(input int n);
    automatic int k; automatic bit acc; automatic int wt;
    for (k = 0; k < n; k++) begin
      do_aw(k % 6, k % 3, 400, acc, wt);
    end
  endtask

  task automatic resp_r_proc();
    automatic int guard, i, m, c;
    guard = 0;
    while (guard < 40000) begin
      if (ar_done && (rd_busy() == 0)) break;
      m = -1;
      for (i = 0; i < NMID; i++) begin
        c = (rr_r + i) % NMID;
        if ((m < 0) && (head_tag_mid_rd(c) >= 0)) m = c;
      end
      if (m < 0) begin @(posedge clk); guard = guard + 1; end
      else begin
        rr_r = (m + 1) % NMID;
        resp_read_mid(m);
      end
    end
  endtask

  task automatic resp_b_proc();
    automatic int guard, i, m, c, tg;
    guard = 0;
    while (guard < 40000) begin
      if (aw_done && (wr_busy() == 0)) break;
      m = -1;
      for (i = 0; i < NMID; i++) begin
        c  = (rr_b + i) % NMID;
        tg = head_tag_mid_wr(c);
        if ((m < 0) && (tg >= 0) && tag_wdone[tg]) m = c;
      end
      if (m < 0) begin @(posedge clk); guard = guard + 1; end
      else begin
        rr_b = (m + 1) % NMID;
        resp_write_mid(m);
      end
    end
  endtask

  task automatic test_stress();
    ar_done = 1'b0; aw_done = 1'b0;
    fork
      begin ar_gen(36); ar_done = 1'b1; end
      begin aw_gen(30); aw_done = 1'b1; end
      resp_r_proc();
      resp_b_proc();
    join
    drain_reads(3000);
    drain_writes(3000);
  endtask

  // =========================================================================
  // F1 -- reset discards work in flight and empties the table.
  // =========================================================================
  task automatic test_reset_discard();
    automatic bit acc; automatic int wt; automatic int i;

    // Put work in flight and answer none of it.
    do_ar(2, 1, 100, acc, wt);
    do_ar(3, 0, 100, acc, wt);
    do_aw(2, 0, 100, acc, wt);

    bfm_reset(4);
    model_clear();
    post_reset_watch = 24;   // F1: nothing from before the reset may answer
    quiet_master     = 24;   // stale master activity is not an E1 matter
    repeat (26) @(posedge clk);

    // F1: the table is empty again, so MAX_UNIQ_IDS distinct ids are accepted.
    // (The spec credits this half of F1 to the A3 check.)
    for (i = 0; i < MAX_UNIQ_IDS; i++) begin
      do_ar(i, 0, 100, acc, wt);
      if (!acc) fail("A3", $sformatf("read id %0d refused after reset: table not empty", i));
    end
    drain_reads(2000);
  endtask

  // D4: one transaction in, one transaction out, in both directions.
  task automatic check_counts();
    if (n_m_ar != n_s_ar)
      fail("D4", $sformatf("%0d slave read requests produced %0d master read requests",
                           n_s_ar, n_m_ar));
    if (n_m_aw != n_s_aw)
      fail("D4", $sformatf("%0d slave write requests produced %0d master write requests",
                           n_s_aw, n_m_aw));
    if (n_s_rlast != n_m_rlast)
      fail("D4", $sformatf("%0d master read responses produced %0d slave read responses",
                           n_m_rlast, n_s_rlast));
    if (n_s_b != n_m_b)
      fail("D4", $sformatf("%0d master write responses produced %0d slave write responses",
                           n_m_b, n_s_b));
    if (rd_busy() > 0) fail("D4", "read transactions still outstanding");
    if (wr_busy() > 0) fail("D4", "write transactions still outstanding");
  endtask

  // =========================================================================
  // Main
  // =========================================================================
  initial begin
    errors = 0; cyc = 0; next_tag = 1; next_addr = 32'h1000_0000;
    post_reset_watch = 0; quiet_master = 0;
    n_s_ar = 0; n_m_ar = 0; n_s_aw = 0; n_m_aw = 0;
    n_s_rlast = 0; n_m_rlast = 0; n_s_b = 0; n_m_b = 0;
    rr_r = 0; rr_b = 0; ar_done = 0; aw_done = 0;

    s_awid = '0; s_awaddr = '0; s_awlen = '0; s_awvalid = 1'b0;
    s_wdata = '0; s_wstrb = '0; s_wlast = 1'b0; s_wvalid = 1'b0;
    s_bready = 1'b1;
    s_arid = '0; s_araddr = '0; s_arlen = '0; s_arvalid = 1'b0;
    s_rready = 1'b1;
    m_awready = 1'b1; m_wready = 1'b1; m_arready = 1'b1;
    m_bid = '0; m_bresp = 2'b00; m_bvalid = 1'b0;
    m_rid = '0; m_rdata = '0; m_rresp = 2'b00; m_rlast = 1'b0; m_rvalid = 1'b0;

    model_clear();

    // F1: offer requests while rst_ni is low.  Nothing may be accepted and no
    // response may be presented; the monitor checks both every cycle.
    @(negedge clk);
    s_arid = 4'd1; s_araddr = 32'h0F00_0000; s_arlen = 8'd0; s_arvalid = 1'b1;
    s_awid = 4'd1; s_awaddr = 32'h0F00_0040; s_awlen = 8'd0; s_awvalid = 1'b1;
    repeat (3) @(posedge clk);
    @(negedge clk);
    s_arvalid = 1'b0; s_awvalid = 1'b0;

    bfm_reset(4);
    model_clear();
    // Anything the design was holding when reset landed is discarded, so a
    // stale master request just after release is not a payload matter.
    quiet_master = 6;
    repeat (8) @(posedge clk);

    test_read_boundary();
    test_read_depth();
    test_write_boundary();
    test_write_depth();
    test_stress();
    repeat (5) @(posedge clk);
    check_counts();          // covers everything since the opening reset
    test_reset_discard();

    repeat (10) @(posedge clk);
    check_counts();

    if (errors != 0)
      $display("%0d failure(s) reported", errors);
    if (errors == 0) $display("RESULT: PASS");
    else             $display("RESULT: FAIL");
    $finish;
  end

endmodule