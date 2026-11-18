// ============================================================================
// id_width_conv_tb -- self-checking testbench for the AXI id-width converter.
//
// Strategy: the TB is the upstream master on the slave port and the
// downstream slave on the master port.  A reference model of both
// outstanding-transaction tables (read side and write side) is maintained by a
// single posedge monitor; every response beat is attributed by bookkeeping
// (oldest outstanding transaction with that slave id), never by matching
// values (all addresses/data are generated uniquely anyway).
//
// Checks (clause -> where):
//   A1  directions counted separately ......... Phase H cross-direction test
//   A2  per-side distinct-id bound ............ monitor (acceptance) + D1
//   A3  exact boundary / table empty after rst  Phases B/C/D/G + monitor
//   A4  entry freed within 2 cycles ........... a3a4_read / a3a4_write
//   A5  per-id depth .......................... Phases C/D + monitor
//   B1  per-id response order ................. monitor attribution (E1 label)
//   B3  write-data order, no interleaving ..... monitor m_w stream check
//   C1/C2 response ids correspond to outstanding txns ... monitor (B)
//   D1/D2 master id distinct/reuse rules ...... monitor (D)
//   D4  1:1 transaction correspondence ........ monitor (B)/(D) + drains
//   E1  payload forwarded unmodified .......... monitor comparisons
//   F1  reset behaviour ....................... Phases A and G + monitor
// ============================================================================
module id_width_conv_tb;

  localparam int unsigned SLV_ID_W        = 4;
  localparam int unsigned MST_ID_W        = 2;
  localparam int unsigned ADDR_W          = 32;
  localparam int unsigned DATA_W          = 32;
  localparam int unsigned MAX_UNIQ_IDS    = 4;
  localparam int unsigned MAX_TXNS_PER_ID = 2;
  localparam int           MAXT           = 128;

  // ------------------------------- DUT wires -------------------------------
  logic [SLV_ID_W-1:0]  s_awid;
  logic [ADDR_W-1:0]    s_awaddr;
  logic [7:0]           s_awlen;
  logic                 s_awvalid;
  logic                 s_awready;
  logic [DATA_W-1:0]    s_wdata;
  logic [DATA_W/8-1:0]  s_wstrb;
  logic                 s_wlast;
  logic                 s_wvalid;
  logic                 s_wready;
  logic [SLV_ID_W-1:0]  s_bid;
  logic [1:0]           s_bresp;
  logic                 s_bvalid;
  logic                 s_bready;
  logic [SLV_ID_W-1:0]  s_arid;
  logic [ADDR_W-1:0]    s_araddr;
  logic [7:0]           s_arlen;
  logic                 s_arvalid;
  logic                 s_arready;
  logic [SLV_ID_W-1:0]  s_rid;
  logic [DATA_W-1:0]    s_rdata;
  logic [1:0]           s_rresp;
  logic                 s_rlast;
  logic                 s_rvalid;
  logic                 s_rready;
  logic [MST_ID_W-1:0]  m_awid;
  logic [ADDR_W-1:0]    m_awaddr;
  logic [7:0]           m_awlen;
  logic                 m_awvalid;
  logic                 m_awready;
  logic [DATA_W-1:0]    m_wdata;
  logic [DATA_W/8-1:0]  m_wstrb;
  logic                 m_wlast;
  logic                 m_wvalid;
  logic                 m_wready;
  logic [MST_ID_W-1:0]  m_bid;
  logic [1:0]           m_bresp;
  logic                 m_bvalid;
  logic                 m_bready;
  logic [MST_ID_W-1:0]  m_arid;
  logic [ADDR_W-1:0]    m_araddr;
  logic [7:0]           m_arlen;
  logic                 m_arvalid;
  logic                 m_arready;
  logic [MST_ID_W-1:0]  m_rid;
  logic [DATA_W-1:0]    m_rdata;
  logic [1:0]           m_rresp;
  logic                 m_rlast;
  logic                 m_rvalid;
  logic                 m_rready;

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
// END PROVIDED PLUMBING
// ---------------------------------------------------------------------------

  id_width_conv #(
    .SLV_ID_W        (SLV_ID_W),
    .MST_ID_W        (MST_ID_W),
    .ADDR_W          (ADDR_W),
    .DATA_W          (DATA_W),
    .MAX_UNIQ_IDS    (MAX_UNIQ_IDS),
    .MAX_TXNS_PER_ID (MAX_TXNS_PER_ID)
  ) dut (
    .clk_i    (clk),
    .rst_ni   (rst_n),
    .s_awid   (s_awid),   .s_awaddr (s_awaddr), .s_awlen  (s_awlen),
    .s_awvalid(s_awvalid), .s_awready(s_awready),
    .s_wdata  (s_wdata),  .s_wstrb  (s_wstrb),  .s_wlast  (s_wlast),
    .s_wvalid (s_wvalid),  .s_wready (s_wready),
    .s_bid    (s_bid),    .s_bresp  (s_bresp),  .s_bvalid(s_bvalid),
    .s_bready (s_bready),
    .s_arid   (s_arid),   .s_araddr (s_araddr), .s_arlen (s_arlen),
    .s_arvalid(s_arvalid), .s_arready(s_arready),
    .s_rid    (s_rid),    .s_rdata  (s_rdata),  .s_rresp (s_rresp),
    .s_rlast  (s_rlast),  .s_rvalid (s_rvalid),  .s_rready(s_rready),
    .m_awid   (m_awid),   .m_awaddr (m_awaddr),  .m_awlen (m_awlen),
    .m_awvalid(m_awvalid), .m_awready(m_awready),
    .m_wdata  (m_wdata),  .m_wstrb  (m_wstrb),   .m_wlast (m_wlast),
    .m_wvalid (m_wvalid), .m_wready (m_wready),
    .m_bid    (m_bid),    .m_bresp  (m_bresp),   .m_bvalid(m_bvalid),
    .m_bready (m_bready),
    .m_arid   (m_arid),   .m_araddr (m_araddr),  .m_arlen (m_arlen),
    .m_arvalid(m_arvalid), .m_arready(m_arready),
    .m_rid    (m_rid),    .m_rdata  (m_rdata),   .m_rresp (m_rresp),
    .m_rlast  (m_rlast),  .m_rvalid (m_rvalid),  .m_rready(m_rready)
  );

  // ------------------------------ model state ------------------------------
  // Read-transaction table (indexed by acceptance order).
  int rt_sid[MAXT];
  int rt_addr[MAXT];
  int rt_len[MAXT];
  int rt_nbeats[MAXT];
  int rt_mid[MAXT];      // master id, -1 until the master request appears
  int rt_mgiven[MAXT];   // beats accepted at the master port
  int rt_deliv[MAXT];    // beats delivered on the slave port
  int rt_done[MAXT];
  int rt_cnt;
  // Write-transaction table.
  int wt_sid[MAXT];
  int wt_addr[MAXT];
  int wt_len[MAXT];
  int wt_nbeats[MAXT];
  int wt_mid[MAXT];
  int wt_sent[MAXT];     // beats accepted on the slave port
  int wt_fwd[MAXT];      // beats forwarded on the master port
  int wt_bgiven[MAXT];
  int wt_done[MAXT];
  int wt_cnt;

  int rd_outst[16];      // outstanding read txns per slave id
  int wr_outst[16];      // outstanding write txns per slave id
  int rd_distinct;       // distinct slave ids outstanding on the read side
  int wr_distinct;

  int wfwd_ptr;          // write whose data the master port must forward next
  int cur_wtxn;          // write txn the s_w driver is currently filling
  int pres_r_txn;        // read txn whose beat is currently offered on m_r
  int pres_b_txn;        // write txn whose B response is currently offered

  int fail_count;
  bit rst_seen;
  int quiet_left;        // posedges of silence right after a reset release
  int addr_seq;

  // monitor scratch (single writer: the monitor process)
  int m_t;
  int m_i;
  int m_b;
  int m_exp_last;

  // main-flow scratch
  bit acc, acc2, ok;
  int w2;
  int jj;
  int t0, t1, t2, t3, t4, t5, t6, t7;
  int tA, tB, tC, tD, tE;
  int tP, tQ, tR, tS, tT, tU, tV;
  int wc_before;

  // ------------------------------ helpers ------------------------------
  task automatic fail(input string req, input string msg);
    fail_count = fail_count + 1;
    $display("FAIL %s: %s", req, msg);
  endtask

  function automatic logic [DATA_W-1:0] gen_r_data(input int t, input int b);
    return {8'hA5, t[11:0], b[11:0]};
  endfunction

  function automatic logic [1:0] gen_r_resp(input int t, input int b);
    return (((t + b) % 4) == 0) ? 2'b01 : 2'b00;
  endfunction

  function automatic logic [DATA_W-1:0] gen_w_data(input int t, input int b);
    return {8'h3C, t[11:0], b[11:0]};
  endfunction

  function automatic logic [DATA_W/8-1:0] gen_w_strb(input int t, input int b);
    return (((t + b) % 3) == 0) ? 4'h3 : 4'hF;
  endfunction

  function automatic logic [1:0] gen_b_resp(input int t);
    return ((t % 5) == 0) ? 2'b01 : 2'b00;
  endfunction

  function automatic logic [ADDR_W-1:0] next_addr();
    addr_seq = addr_seq + 1;
    return 32'h0000_1000 + addr_seq * 4;
  endfunction

  task automatic clear_model();
    begin
      for (int i = 0; i < MAXT; i = i + 1) begin
        rt_sid[i] = 0; rt_addr[i] = 0; rt_len[i] = 0; rt_nbeats[i] = 0;
        rt_mid[i] = -1; rt_mgiven[i] = 0; rt_deliv[i] = 0; rt_done[i] = 1;
        wt_sid[i] = 0; wt_addr[i] = 0; wt_len[i] = 0; wt_nbeats[i] = 0;
        wt_mid[i] = -1; wt_sent[i] = 0; wt_fwd[i] = 0; wt_bgiven[i] = 0;
        wt_done[i] = 1;
      end
      rt_cnt = 0; wt_cnt = 0;
      rd_distinct = 0; wr_distinct = 0;
      for (int i = 0; i < 16; i = i + 1) begin
        rd_outst[i] = 0; wr_outst[i] = 0;
      end
      wfwd_ptr = 0;
    end
  endtask

  // ------------------------------ drivers ------------------------------
  // Offer a read for a fixed number of cycles; report whether it was taken.
  task automatic probe_ar(input int sid, input int cycles, output bit acc);
    int k;
    begin
      acc = 1'b0;
      @(negedge clk);
      s_arid = sid; s_araddr = next_addr(); s_arlen = 8'd0; s_arvalid = 1'b1;
      for (k = 0; k < cycles; k = k + 1) begin
        @(posedge clk);
        if (s_arready) begin acc = 1'b1; break; end
      end
      @(negedge clk) s_arvalid = 1'b0;
    end
  endtask

  task automatic probe_aw(input int sid, input int cycles, output bit acc);
    int k;
    begin
      acc = 1'b0;
      @(negedge clk);
      s_awid = sid; s_awaddr = next_addr(); s_awlen = 8'd0; s_awvalid = 1'b1;
      for (k = 0; k < cycles; k = k + 1) begin
        @(posedge clk);
        if (s_awready) begin acc = 1'b1; break; end
      end
      @(negedge clk) s_awvalid = 1'b0;
    end
  endtask

  // One write-data beat on the slave port (with a budget; drives at negedge).
  task automatic do_wbeat(input int t, input int b, input int budget,
                          output bit ok);
    int k;
    begin
      ok = 1'b0;
      @(negedge clk);
      cur_wtxn = t;
      s_wdata = gen_w_data(t, b);
      s_wstrb = gen_w_strb(t, b);
      s_wlast = (b == wt_len[t]);
      s_wvalid = 1'b1;
      for (k = 0; k < budget; k = k + 1) begin
        @(posedge clk);
        if (s_wready) begin ok = 1'b1; break; end
      end
      @(negedge clk) begin s_wvalid = 1'b0; cur_wtxn = -1; end
      if (!ok) fail("D4", "slave port refused write data");
    end
  endtask

  task automatic do_write_data(input int t);
    bit ok;
    begin
      for (int b = 0; b <= wt_len[t]; b = b + 1) begin
        do_wbeat(t, b, 500, ok);
        if (!ok) begin abandon_write(t); break; end
      end
    end
  endtask

  // One read-response beat on the master port (we are the downstream slave).
  task automatic do_rbeat(input int t, input int b, input int budget,
                          output bit ok);
    int k;
    begin
      ok = 1'b0;
      @(negedge clk);
      pres_r_txn = t;
      m_rid = rt_mid[t];
      m_rdata = gen_r_data(t, b);
      m_rresp = gen_r_resp(t, b);
      m_rlast = (b == rt_len[t]);
      m_rvalid = 1'b1;
      for (k = 0; k < budget; k = k + 1) begin
        @(posedge clk);
        if (m_rready) begin ok = 1'b1; break; end
      end
      @(negedge clk) begin m_rvalid = 1'b0; pres_r_txn = -1; end
      if (!ok) fail("D4", "master port refused a read response beat");
    end
  endtask

  task automatic do_bresp(input int t, input int budget, output bit ok);
    int k;
    begin
      ok = 1'b0;
      @(negedge clk);
      pres_b_txn = t;
      m_bid = wt_mid[t];
      m_bresp = gen_b_resp(t);
      m_bvalid = 1'b1;
      for (k = 0; k < budget; k = k + 1) begin
        @(posedge clk);
        if (m_bready) begin ok = 1'b1; break; end
      end
      @(negedge clk) begin m_bvalid = 1'b0; pres_b_txn = -1; end
      if (!ok) fail("D4", "master port refused the write response");
    end
  endtask

  // ------------------------------ waits ------------------------------
  task automatic wait_r_mid(input int t, input int budget, output bit ok);
    int k;
    begin
      ok = 1'b0;
      for (k = 0; k < budget; k = k + 1) begin
        @(posedge clk);
        if (rt_mid[t] >= 0) begin ok = 1'b1; break; end
      end
      if (!ok) fail("D4", "master read request never issued for an accepted slave read");
    end
  endtask

  task automatic wait_w_mid(input int t, input int budget, output bit ok);
    int k;
    begin
      ok = 1'b0;
      for (k = 0; k < budget; k = k + 1) begin
        @(posedge clk);
        if (wt_mid[t] >= 0) begin ok = 1'b1; break; end
      end
      if (!ok) fail("D4", "master write request never issued for an accepted slave write");
    end
  endtask

  task automatic wait_w_fwd(input int t, input int budget, output bit ok);
    int k;
    begin
      ok = 1'b0;
      for (k = 0; k < budget; k = k + 1) begin
        @(posedge clk);
        if (wt_fwd[t] >= wt_nbeats[t]) begin ok = 1'b1; break; end
      end
      if (!ok) fail("D4", "accepted write data never forwarded to the master port");
    end
  endtask

  task automatic wait_r_done(input int t, input int budget, output bit ok);
    int k;
    begin
      ok = 1'b0;
      for (k = 0; k < budget; k = k + 1) begin
        @(posedge clk);
        if (rt_done[t]) begin ok = 1'b1; break; end
      end
      if (!ok) fail("D4", "read response never forwarded to the slave port");
    end
  endtask

  task automatic wait_w_done(input int t, input int budget, output bit ok);
    int k;
    begin
      ok = 1'b0;
      for (k = 0; k < budget; k = k + 1) begin
        @(posedge clk);
        if (wt_done[t]) begin ok = 1'b1; break; end
      end
      if (!ok) fail("D4", "write response never forwarded to the slave port");
    end
  endtask

  // Remove a txn from the model (only after a recorded failure).
  task automatic abandon_read(input int t);
    begin
      @(negedge clk);
      if (!rt_done[t]) begin
        rt_done[t] = 1;
        if (rd_outst[rt_sid[t]] > 0) begin
          rd_outst[rt_sid[t]] = rd_outst[rt_sid[t]] - 1;
          if (rd_outst[rt_sid[t]] == 0) rd_distinct = rd_distinct - 1;
        end
      end
    end
  endtask

  task automatic abandon_write(input int t);
    begin
      @(negedge clk);
      if (!wt_done[t]) begin
        wt_done[t] = 1;
        if (wr_outst[wt_sid[t]] > 0) begin
          wr_outst[wt_sid[t]] = wr_outst[wt_sid[t]] - 1;
          if (wr_outst[wt_sid[t]] == 0) wr_distinct = wr_distinct - 1;
        end
      end
    end
  endtask

  // ------------------------------ responders ------------------------------
  // Per-mid (hence per-sid) response order is preserved by the caller.
  task automatic respond_read(input int t);
    bit ok;
    begin
      wait_r_mid(t, 500, ok);
      if (ok) begin
        for (int b = rt_mgiven[t]; b <= rt_len[t]; b = b + 1) begin
          do_rbeat(t, b, 500, ok);
          if (!ok) begin abandon_read(t); break; end
        end
      end else abandon_read(t);
    end
  endtask

  task automatic respond_write(input int t);
    bit ok;
    begin
      wait_w_mid(t, 500, ok);
      if (ok) wait_w_fwd(t, 500, ok);
      if (ok) do_bresp(t, 500, ok);
      if (!ok) abandon_write(t);
    end
  endtask

  task automatic drain_reads();
    int t, k;
    bit ok, alldone;
    begin
      forever begin
        t = -1;
        for (int i = 0; i < rt_cnt; i = i + 1) begin
          if (!rt_done[i] && rt_mgiven[i] < rt_nbeats[i]) begin t = i; break; end
        end
        if (t < 0) break;
        wait_r_mid(t, 500, ok);
        if (ok) begin
          for (int b = rt_mgiven[t]; b <= rt_len[t]; b = b + 1) begin
            do_rbeat(t, b, 500, ok);
            if (!ok) break;
          end
          if (ok) wait_r_done(t, 2000, ok);
        end
        if (!ok) abandon_read(t);
      end
      alldone = 1'b0;
      for (k = 0; k < 3000; k = k + 1) begin
        @(posedge clk);
        t = -1;
        for (int i = 0; i < rt_cnt; i = i + 1) begin
          if (!rt_done[i]) begin t = i; break; end
        end
        if (t < 0) begin alldone = 1'b1; break; end
      end
      if (!alldone) begin
        fail("D4", "read responses missing at drain (timeout)");
        for (int i = 0; i < rt_cnt; i = i + 1)
          if (!rt_done[i]) abandon_read(i);
      end
    end
  endtask

  task automatic drain_writes();
    int t, k;
    bit ok, alldone;
    begin
      forever begin
        t = -1;
        for (int i = 0; i < wt_cnt; i = i + 1) begin
          if (!wt_done[i] && !wt_bgiven[i]) begin t = i; break; end
        end
        if (t < 0) break;
        wait_w_mid(t, 500, ok);
        if (ok) wait_w_fwd(t, 500, ok);
        if (ok) begin
          do_bresp(t, 500, ok);
          if (ok) wait_w_done(t, 2000, ok);
        end
        if (!ok) abandon_write(t);
      end
      alldone = 1'b0;
      for (k = 0; k < 3000; k = k + 1) begin
        @(posedge clk);
        t = -1;
        for (int i = 0; i < wt_cnt; i = i + 1) begin
          if (!wt_done[i]) begin t = i; break; end
        end
        if (t < 0) begin alldone = 1'b1; break; end
      end
      if (!alldone) begin
        fail("D4", "write responses missing at drain (timeout)");
        for (int i = 0; i < wt_cnt; i = i + 1)
          if (!wt_done[i]) abandon_write(i);
      end
    end
  endtask

  // ------------------------------ A4 measurement ------------------------------
  // Must be entered in the same timestep as the retiring posedge T.
  // Acceptance of the continuously offered new-id request must occur at
  // T, T+1 or T+2 (A4).
  task automatic measure_a4_ar();
    int a4cnt;
    bit acceptedf;
    begin
      acceptedf = 1'b0; a4cnt = 0;
      if (s_arready) acceptedf = 1'b1;
      if (!acceptedf) begin
        @(negedge clk) begin m_rvalid = 1'b0; pres_r_txn = -1; end
        @(posedge clk);
        a4cnt = 1;
        if (s_arready) acceptedf = 1'b1;
        if (!acceptedf) begin
          @(posedge clk);
          a4cnt = 2;
          if (s_arready) acceptedf = 1'b1;
          if (!acceptedf) begin
            @(posedge clk);
            a4cnt = 3;
            if (s_arready) acceptedf = 1'b1;
          end
        end
      end
      if (!acceptedf)
        fail("A4", "new-id read request not accepted within 2 cycles of entry retirement");
      else if (a4cnt > 2)
        fail("A4", "new-id read request accepted more than 2 cycles after entry retirement");
    end
  endtask

  task automatic measure_a4_aw();
    int a4cnt;
    bit acceptedf;
    begin
      acceptedf = 1'b0; a4cnt = 0;
      if (s_awready) acceptedf = 1'b1;
      if (!acceptedf) begin
        @(negedge clk) begin m_bvalid = 1'b0; pres_b_txn = -1; end
        @(posedge clk);
        a4cnt = 1;
        if (s_awready) acceptedf = 1'b1;
        if (!acceptedf) begin
          @(posedge clk);
          a4cnt = 2;
          if (s_awready) acceptedf = 1'b1;
          if (!acceptedf) begin
            @(posedge clk);
            a4cnt = 3;
            if (s_awready) acceptedf = 1'b1;
          end
        end
      end
      if (!acceptedf)
        fail("A4", "new-id write request not accepted within 2 cycles of entry retirement");
      else if (a4cnt > 2)
        fail("A4", "new-id write request accepted more than 2 cycles after entry retirement");
    end
  endtask

  // Fill the read table to MAX_UNIQ_IDS distinct ids, verify a new id is
  // blocked (A3), then retire one entry and verify acceptance within 2
  // cycles (A4).  The new-id request stays offered continuously throughout.
  task automatic a3a4_read(input int new_sid, input int retire_t);
    int waited, k;
    bit accx, done_T;
    begin
      if (rt_mid[retire_t] < 0) begin
        fail("D4", "master read request never issued for an accepted slave read (A4 setup)");
      end else begin
        @(negedge clk);
        s_arid = new_sid; s_araddr = next_addr(); s_arlen = 8'd0; s_arvalid = 1'b1;
        waited = 0; accx = 1'b0;
        while (waited < 15) begin
          @(posedge clk);
          if (s_arready) begin accx = 1'b1; break; end
          waited = waited + 1;
        end
        if (accx) begin
          fail("A3", "new read id accepted while MAX_UNIQ_IDS distinct read ids were outstanding");
          @(negedge clk) s_arvalid = 1'b0;
        end else begin
          @(negedge clk);
          pres_r_txn = retire_t;
          m_rid = rt_mid[retire_t];
          m_rdata = gen_r_data(retire_t, 0);
          m_rresp = gen_r_resp(retire_t, 0);
          m_rlast = 1'b1;
          m_rvalid = 1'b1;
          accx = 1'b0;
          for (k = 0; k < 500; k = k + 1) begin
            @(posedge clk);
            if (m_rready) begin accx = 1'b1; break; end
          end
          if (!accx) begin
            fail("D4", "master port refused the read response beat (A4 setup)");
            @(negedge clk) begin m_rvalid = 1'b0; pres_r_txn = -1; s_arvalid = 1'b0; end
          end else begin
            done_T = s_rvalid; // same-edge forwarding by the design?
            if (done_T) begin
              measure_a4_ar();
            end else begin
              @(negedge clk) begin m_rvalid = 1'b0; pres_r_txn = -1; end
              done_T = 1'b0;
              for (k = 0; k < 500; k = k + 1) begin
                @(posedge clk);
                if (s_rvalid) begin done_T = 1'b1; break; end
              end
              if (!done_T) begin
                fail("D4", "slave read response never appeared (A4 setup)");
                @(negedge clk) s_arvalid = 1'b0;
              end else begin
                measure_a4_ar();
              end
            end
            @(negedge clk) begin s_arvalid = 1'b0; m_rvalid = 1'b0; pres_r_txn = -1; end
          end
        end
      end
    end
  endtask

  task automatic a3a4_write(input int new_sid, input int retire_t);
    int waited, k;
    bit accx, done_T;
    begin
      if (wt_mid[retire_t] < 0) begin
        fail("D4", "master write request never issued for an accepted slave write (A4 setup)");
      end else begin
        @(negedge clk);
        s_awid = new_sid; s_awaddr = next_addr(); s_awlen = 8'd0; s_awvalid = 1'b1;
        waited = 0; accx = 1'b0;
        while (waited < 15) begin
          @(posedge clk);
          if (s_awready) begin accx = 1'b1; break; end
          waited = waited + 1;
        end
        if (accx) begin
          fail("A3", "new write id accepted while MAX_UNIQ_IDS distinct write ids were outstanding");
          @(negedge clk) s_awvalid = 1'b0;
        end else begin
          wait_w_fwd(retire_t, 500, accx);
          if (!accx) begin
            @(negedge clk) s_awvalid = 1'b0;
          end else begin
            @(negedge clk);
            pres_b_txn = retire_t;
            m_bid = wt_mid[retire_t];
            m_bresp = gen_b_resp(retire_t);
            m_bvalid = 1'b1;
            accx = 1'b0;
            for (k = 0; k < 500; k = k + 1) begin
              @(posedge clk);
              if (m_bready) begin accx = 1'b1; break; end
            end
            if (!accx) begin
              fail("D4", "master port refused the write response (A4 setup)");
              @(negedge clk) begin m_bvalid = 1'b0; pres_b_txn = -1; s_awvalid = 1'b0; end
            end else begin
              done_T = s_bvalid; // same-edge forwarding by the design?
              if (done_T) begin
                measure_a4_aw();
              end else begin
                @(negedge clk) begin m_bvalid = 1'b0; pres_b_txn = -1; end
                done_T = 1'b0;
                for (k = 0; k < 500; k = k + 1) begin
                  @(posedge clk);
                  if (s_bvalid) begin done_T = 1'b1; break; end
                end
                if (!done_T) begin
                  fail("D4", "slave write response never appeared (A4 setup)");
                  @(negedge clk) s_awvalid = 1'b0;
                end else begin
                  measure_a4_aw();
                end
              end
              @(negedge clk) begin s_awvalid = 1'b0; m_bvalid = 1'b0; pres_b_txn = -1; end
            end
          end
        end
      end
    end
  endtask

  // ------------------------------------------------------------------
  // Monitor / checker.  All model bookkeeping happens here, in a fixed
  // intra-edge order that makes same-edge (combinational) forwarding and
  // the zero-cycle A4 acceptance race-free:
  //   (A) downstream response acceptances  m_b, m_r
  //   (B) slave-port response deliveries  s_b, s_r   (C1/C2/E1/B1)
  //   (C) slave-port acceptances          s_aw, s_ar, s_w  (A2/A5)
  //   (D) master-port requests            m_aw, m_ar, m_w  (D1/D2/D4/E1/B3)
  // (B) before (C) is essential: an entry retired at edge T must not make
  // the A2 check fire on a new id accepted at that same edge T.
  // ------------------------------------------------------------------
  always @(posedge clk) begin
    if (!rst_n) begin
      // F1: no response may be presented while reset is low (skip the very
      // first reset edge: a synchronous design has not sampled reset yet).
      if (rst_seen && (s_bvalid || s_rvalid))
        fail("F1", "response valid asserted on the slave port while rst_ni is low");
      rst_seen = 1'b1;
    end else begin
      rst_seen = 1'b0;
      if (quiet_left > 0) quiet_left = quiet_left - 1;

      // ---------------- (A) downstream response acceptances ----------------
      if (m_bvalid && m_bready && pres_b_txn >= 0)
        wt_bgiven[pres_b_txn] = 1;
      if (m_rvalid && m_rready && pres_r_txn >= 0)
        rt_mgiven[pres_r_txn] = rt_mgiven[pres_r_txn] + 1;

      // ---------------- (B) slave-port response deliveries ----------------
      if (s_bvalid && s_bready) begin
        m_t = -1;
        for (m_i = 0; m_i < wt_cnt; m_i = m_i + 1) begin
          if (!wt_done[m_i] && wt_sid[m_i] == s_bid) begin m_t = m_i; break; end
        end
        if (m_t < 0) begin
          fail("C2", $sformatf("write response for slave id %0d with no outstanding write txn", s_bid));
          if (quiet_left > 0)
            fail("F1", "write response appeared after reset with an empty table");
        end else begin
          if (!wt_bgiven[m_t])
            fail("D4", "slave write response without a corresponding master write response");
          if (s_bresp != gen_b_resp(m_t))
            fail("E1", "write response resp not forwarded unmodified");
          wt_done[m_t] = 1;
          if (wr_outst[s_bid] > 0) begin
            wr_outst[s_bid] = wr_outst[s_bid] - 1;
            if (wr_outst[s_bid] == 0) wr_distinct = wr_distinct - 1;
          end
        end
      end
      if (s_rvalid && s_rready) begin
        m_t = -1;
        for (m_i = 0; m_i < rt_cnt; m_i = m_i + 1) begin
          if (!rt_done[m_i] && rt_sid[m_i] == s_rid) begin m_t = m_i; break; end
        end
        if (m_t < 0) begin
          fail("C2", $sformatf("read response for slave id %0d with no outstanding read txn", s_rid));
          if (quiet_left > 0)
            fail("F1", "read response appeared after reset with an empty table");
        end else begin
          if (rt_deliv[m_t] >= rt_mgiven[m_t]) begin
            fail("E1", "read beat delivered on the slave port was never supplied downstream");
          end else begin
            if (s_rdata != gen_r_data(m_t, rt_deliv[m_t]))
              fail("E1", "read data mismatch (payload corruption or per-id reordering, B1)");
            if (s_rresp != gen_r_resp(m_t, rt_deliv[m_t]))
              fail("E1", "read resp not forwarded unmodified");
            m_exp_last = (rt_deliv[m_t] == rt_len[m_t]);
            if (s_rlast != m_exp_last)
              fail("E1", "rlast mismatch on read response");
          end
          rt_deliv[m_t] = rt_deliv[m_t] + 1;
          if (rt_deliv[m_t] >= rt_nbeats[m_t]) begin
            rt_done[m_t] = 1;
            if (rd_outst[s_rid] > 0) begin
              rd_outst[s_rid] = rd_outst[s_rid] - 1;
              if (rd_outst[s_rid] == 0) rd_distinct = rd_distinct - 1;
            end
          end
        end
      end

      // ---------------- (C) slave-port acceptances ----------------
      if (s_awvalid && s_awready) begin
        if (wr_outst[s_awid] >= MAX_TXNS_PER_ID)
          fail("A5", $sformatf("write accepted for id %0d with %0d already outstanding", s_awid, wr_outst[s_awid]));
        if (wr_outst[s_awid] == 0 && wr_distinct >= MAX_UNIQ_IDS)
          fail("A2", $sformatf("write accepted for new id %0d with %0d distinct write ids outstanding", s_awid, wr_distinct));
        if (wt_cnt < MAXT) begin
          wt_sid[wt_cnt] = s_awid;
          wt_addr[wt_cnt] = s_awaddr;
          wt_len[wt_cnt] = s_awlen;
          wt_nbeats[wt_cnt] = s_awlen + 1;
          wt_mid[wt_cnt] = -1;
          wt_sent[wt_cnt] = 0;
          wt_fwd[wt_cnt] = 0;
          wt_bgiven[wt_cnt] = 0;
          wt_done[wt_cnt] = 0;
          if (wr_outst[s_awid] == 0) wr_distinct = wr_distinct + 1;
          wr_outst[s_awid] = wr_outst[s_awid] + 1;
          wt_cnt = wt_cnt + 1;
        end
      end
      if (s_arvalid && s_arready) begin
        if (rd_outst[s_arid] >= MAX_TXNS_PER_ID)
          fail("A5", $sformatf("read accepted for id %0d with %0d already outstanding", s_arid, rd_outst[s_arid]));
        if (rd_outst[s_arid] == 0 && rd_distinct >= MAX_UNIQ_IDS)
          fail("A2", $sformatf("read accepted for new id %0d with %0d distinct read ids outstanding", s_arid, rd_distinct));
        if (rt_cnt < MAXT) begin
          rt_sid[rt_cnt] = s_arid;
          rt_addr[rt_cnt] = s_araddr;
          rt_len[rt_cnt] = s_arlen;
          rt_nbeats[rt_cnt] = s_arlen + 1;
          rt_mid[rt_cnt] = -1;
          rt_mgiven[rt_cnt] = 0;
          rt_deliv[rt_cnt] = 0;
          rt_done[rt_cnt] = 0;
          if (rd_outst[s_arid] == 0) rd_distinct = rd_distinct + 1;
          rd_outst[s_arid] = rd_outst[s_arid] + 1;
          rt_cnt = rt_cnt + 1;
        end
      end
      if (s_wvalid && s_wready) begin
        if (cur_wtxn >= 0 && cur_wtxn < wt_cnt)
          wt_sent[cur_wtxn] = wt_sent[cur_wtxn] + 1;
      end

      // ---------------- (D) master-port requests ----------------
      if (m_awvalid && m_awready) begin
        m_t = -1;
        for (m_i = 0; m_i < wt_cnt; m_i = m_i + 1) begin
          if (wt_mid[m_i] < 0 && wt_addr[m_i] == m_awaddr) begin m_t = m_i; break; end
        end
        if (m_t < 0) begin
          fail("D4", "master write address with no matching accepted slave write");
        end else begin
          if (wt_len[m_t] != m_awlen)
            fail("E1", "write address len not forwarded unmodified");
          for (m_i = 0; m_i < wt_cnt; m_i = m_i + 1) begin
            if (m_i != m_t && !wt_done[m_i] && wt_mid[m_i] == m_awid
                && wt_sid[m_i] != wt_sid[m_t]) begin
              fail("D1", $sformatf("master write id %0d shared by co-outstanding slave ids %0d and %0d",
                                   m_awid, wt_sid[m_i], wt_sid[m_t]));
              fail("D2", "master write id reused for a different slave id before retirement");
              break;
            end
          end
          wt_mid[m_t] = m_awid;
        end
      end
      if (m_arvalid && m_arready) begin
        m_t = -1;
        for (m_i = 0; m_i < rt_cnt; m_i = m_i + 1) begin
          if (rt_mid[m_i] < 0 && rt_addr[m_i] == m_araddr) begin m_t = m_i; break; end
        end
        if (m_t < 0) begin
          fail("D4", "master read address with no matching accepted slave read");
        end else begin
          if (rt_len[m_t] != m_arlen)
            fail("E1", "read address len not forwarded unmodified");
          for (m_i = 0; m_i < rt_cnt; m_i = m_i + 1) begin
            if (m_i != m_t && !rt_done[m_i] && rt_mid[m_i] == m_arid
                && rt_sid[m_i] != rt_sid[m_t]) begin
              fail("D1", $sformatf("master read id %0d shared by co-outstanding slave ids %0d and %0d",
                                   m_arid, rt_sid[m_i], rt_sid[m_t]));
              fail("D2", "master read id reused for a different slave id before retirement");
              break;
            end
          end
          rt_mid[m_t] = m_arid;
        end
      end
      // B3/E1: write data must be forwarded in slave-AW acceptance order,
      // unmodified and without interleaving.
      if (m_wvalid && m_wready) begin
        if (wfwd_ptr < wt_cnt && wt_fwd[wfwd_ptr] < wt_sent[wfwd_ptr]) begin
          m_t = wfwd_ptr;
          m_b = wt_fwd[m_t];
          if (m_wdata != gen_w_data(m_t, m_b))
            fail("E1", "write data mismatch (payload corruption, misordering or interleaving, B3)");
          if (m_wstrb != gen_w_strb(m_t, m_b))
            fail("E1", "write strobe not forwarded unmodified");
          m_exp_last = (m_b == wt_len[m_t]);
          if (m_wlast != m_exp_last)
            fail("E1", "wlast mismatch on forwarded write data");
          wt_fwd[m_t] = wt_fwd[m_t] + 1;
          if (wt_fwd[m_t] >= wt_nbeats[m_t]) begin
            wfwd_ptr = wfwd_ptr + 1;
            while (wfwd_ptr < wt_cnt && wt_fwd[wfwd_ptr] >= wt_nbeats[wfwd_ptr])
              wfwd_ptr = wfwd_ptr + 1;
          end
        end else begin
          fail("E1", "master write data forwarded with no matching slave write data");
        end
      end
    end
  end

  // ------------------------------------------------------------------
  // Main stimulus flow
  // ------------------------------------------------------------------
  initial begin : main_stim
    s_awid = 0; s_awaddr = 0; s_awlen = 0; s_awvalid = 0;
    s_arid = 0; s_araddr = 0; s_arlen = 0; s_arvalid = 0;
    s_wdata = 0; s_wstrb = 0; s_wlast = 0; s_wvalid = 0;
    m_rid = 0; m_rdata = 0; m_rresp = 0; m_rlast = 0; m_rvalid = 0;
    m_bid = 0; m_bresp = 0; m_bvalid = 0;
    s_bready = 1; s_rready = 1;
    m_awready = 1; m_wready = 1; m_arready = 1;
    cur_wtxn = -1; pres_r_txn = -1; pres_b_txn = -1;
    fail_count = 0; rst_seen = 0; quiet_left = 0; addr_seq = 0;
    clear_model();

    repeat (2) @(posedge clk);

    // ---- Phase A: reset behaviour (F1) ----
    // Offers while rst_ni is low: acceptance is optional (ready is
    // unconstrained during reset), so no acceptance is required here.
    bfm_ar(4'd4,  next_addr(), 8'd0, 3, acc, w2);
    bfm_aw(4'd9,  next_addr(), 8'd0, 3, acc, w2);
    do_wbeat(0, 0, 3, ok);                 // content irrelevant: discarded
    bfm_ar(4'd11, next_addr(), 8'd0, 3, acc, w2);
    bfm_aw(4'd2,  next_addr(), 8'd0, 3, acc, w2);
    // idle reset cycles: anything accepted above must be cleared by a
    // later reset edge before release.
    repeat (3) @(posedge clk);
    @(negedge clk) rst_n = 1'b1;
    clear_model();
    quiet_left = 24;
    // quiet window: any response now would be for a discarded txn (F1/C2)
    repeat (24) @(posedge clk);

    // ---- Phase B: read-side table boundary (A2/A3/A4) ----
    t0 = rt_cnt;
    bfm_ar(4'd1, next_addr(), 8'd0, 500, acc, w2);
    if (!acc) fail("A3", "read with an empty table not accepted");
    t1 = rt_cnt;
    bfm_ar(4'd2, next_addr(), 8'd0, 500, acc, w2);
    if (!acc) fail("A3", "read id 2 not accepted below the distinct-id bound");
    t2 = rt_cnt;
    bfm_ar(4'd3, next_addr(), 8'd0, 500, acc, w2);
    if (!acc) fail("A3", "read id 3 not accepted below the distinct-id bound");
    t3 = rt_cnt;
    bfm_ar(4'd4, next_addr(), 8'd0, 500, acc, w2);
    if (!acc) fail("A3", "new read id not accepted at MAX_UNIQ_IDS-1 distinct ids");
    if (acc) a3a4_read(4'd5, t0);
    drain_reads();

    // ---- Phase C: read-side per-id depth (A5) and entry semantics ----
    t0 = rt_cnt;
    bfm_ar(4'd6, next_addr(), 8'd0, 500, acc, w2);
    if (!acc) fail("A3", "read id 6 not accepted with a free entry");
    t1 = rt_cnt;
    bfm_ar(4'd6, next_addr(), 8'd0, 500, acc, w2);
    if (!acc) fail("A5", "second same-id read not accepted below MAX_TXNS_PER_ID");
    if (acc) begin
      probe_ar(4'd6, 15, acc2);
      if (acc2) fail("A5", "third same-id read accepted beyond MAX_TXNS_PER_ID");
      respond_read(t0);
      wait_r_done(t0, 500, ok);
      bfm_ar(4'd6, next_addr(), 8'd0, 500, acc, w2);
      if (!acc) fail("A5", "same-id read not accepted after one txn retired");
    end
    drain_reads();
    // two ids at full depth; the bounds still hold exactly
    t0 = rt_cnt; bfm_ar(4'd7,  next_addr(), 8'd0, 500, acc, w2);
    t1 = rt_cnt; bfm_ar(4'd7,  next_addr(), 8'd0, 500, acc, w2);
    t2 = rt_cnt; bfm_ar(4'd8,  next_addr(), 8'd0, 500, acc, w2);
    t3 = rt_cnt; bfm_ar(4'd8,  next_addr(), 8'd0, 500, acc, w2);
    probe_ar(4'd7, 15, acc2);
    if (acc2) fail("A5", "third read for id 7 accepted beyond MAX_TXNS_PER_ID");
    t4 = rt_cnt;
    bfm_ar(4'd9, next_addr(), 8'd0, 500, acc, w2);
    if (!acc) fail("A3", "new read id 9 not accepted with only 2 distinct ids outstanding");
    t5 = rt_cnt;
    bfm_ar(4'd10, next_addr(), 8'd0, 500, acc, w2);
    if (!acc) fail("A3", "new read id 10 not accepted with only 3 distinct ids outstanding");
    probe_ar(4'd11, 15, acc2);
    if (acc2) fail("A3", "new read id 11 accepted at MAX_UNIQ_IDS distinct ids");
    drain_reads();
    // an entry is freed only when the LAST txn of its id completes (A4/A3)
    t0 = rt_cnt; bfm_ar(4'd1, next_addr(), 8'd0, 500, acc, w2);
    t1 = rt_cnt; bfm_ar(4'd1, next_addr(), 8'd0, 500, acc, w2);
    t2 = rt_cnt; bfm_ar(4'd2, next_addr(), 8'd0, 500, acc, w2);
    t3 = rt_cnt; bfm_ar(4'd2, next_addr(), 8'd0, 500, acc, w2);
    t4 = rt_cnt; bfm_ar(4'd3, next_addr(), 8'd0, 500, acc, w2);
    t5 = rt_cnt; bfm_ar(4'd3, next_addr(), 8'd0, 500, acc, w2);
    t6 = rt_cnt; bfm_ar(4'd4, next_addr(), 8'd0, 500, acc, w2);
    t7 = rt_cnt; bfm_ar(4'd4, next_addr(), 8'd0, 500, acc, w2);
    respond_read(t0);
    wait_r_done(t0, 500, ok);
    probe_ar(4'd5, 15, acc2);
    if (acc2) fail("A3", "new read id accepted while an id with a still-outstanding txn holds its entry");
    bfm_ar(4'd1, next_addr(), 8'd0, 500, acc, w2);
    if (!acc) fail("A5", "same-id read not accepted after a per-id slot freed");
    drain_reads();

    // ---- Phase D: write-side boundary (A2/A3/A4) and depth (A5) ----
    t0 = wt_cnt;
    bfm_aw(4'd1, next_addr(), 8'd0, 500, acc, w2);
    if (!acc) fail("A3", "write with an empty table not accepted");
    if (acc) do_write_data(t0);
    t1 = wt_cnt;
    bfm_aw(4'd2, next_addr(), 8'd0, 500, acc, w2);
    if (!acc) fail("A3", "write id 2 not accepted below the distinct-id bound");
    if (acc) do_write_data(t1);
    t2 = wt_cnt;
    bfm_aw(4'd3, next_addr(), 8'd0, 500, acc, w2);
    if (!acc) fail("A3", "write id 3 not accepted below the distinct-id bound");
    if (acc) do_write_data(t2);
    t3 = wt_cnt;
    bfm_aw(4'd4, next_addr(), 8'd0, 500, acc, w2);
    if (!acc) fail("A3", "new write id not accepted at MAX_UNIQ_IDS-1 distinct ids");
    if (acc) begin
      do_write_data(t3);
      wc_before = wt_cnt;
      a3a4_write(4'd5, t0);
      if (wt_cnt > wc_before) do_write_data(wt_cnt - 1);
    end
    drain_writes();
    // per-id write depth
    t0 = wt_cnt;
    bfm_aw(4'd6, next_addr(), 8'd0, 500, acc, w2);
    if (acc) do_write_data(t0);
    t1 = wt_cnt;
    bfm_aw(4'd6, next_addr(), 8'd0, 500, acc, w2);
    if (!acc) fail("A5", "second same-id write not accepted below MAX_TXNS_PER_ID");
    if (acc) begin
      do_write_data(t1);
      probe_aw(4'd6, 15, acc2);
      if (acc2) fail("A5", "third same-id write accepted beyond MAX_TXNS_PER_ID");
      respond_write(t0);
      wait_w_done(t0, 500, ok);
      bfm_aw(4'd6, next_addr(), 8'd0, 500, acc, w2);
      if (!acc) fail("A5", "same-id write not accepted after one txn retired");
      if (acc) do_write_data(wt_cnt - 1);
    end
    drain_writes();
    // write entry freed only at last txn completion
    t0 = wt_cnt; bfm_aw(4'd1, next_addr(), 8'd0, 500, acc, w2); if (acc) do_write_data(t0);
    t1 = wt_cnt; bfm_aw(4'd1, next_addr(), 8'd0, 500, acc, w2); if (acc) do_write_data(t1);
    t2 = wt_cnt; bfm_aw(4'd2, next_addr(), 8'd0, 500, acc, w2); if (acc) do_write_data(t2);
    t3 = wt_cnt; bfm_aw(4'd2, next_addr(), 8'd0, 500, acc, w2); if (acc) do_write_data(t3);
    t4 = wt_cnt; bfm_aw(4'd3, next_addr(), 8'd0, 500, acc, w2); if (acc) do_write_data(t4);
    t5 = wt_cnt; bfm_aw(4'd3, next_addr(), 8'd0, 500, acc, w2); if (acc) do_write_data(t5);
    t6 = wt_cnt; bfm_aw(4'd4, next_addr(), 8'd0, 500, acc, w2); if (acc) do_write_data(t6);
    t7 = wt_cnt; bfm_aw(4'd4, next_addr(), 8'd0, 500, acc, w2); if (acc) do_write_data(t7);
    respond_write(t0);
    wait_w_done(t0, 500, ok);
    probe_aw(4'd5, 15, acc2);
    if (acc2) fail("A3", "new write id accepted while an id with a still-outstanding txn holds its entry");
    bfm_aw(4'd1, next_addr(), 8'd0, 500, acc, w2);
    if (!acc) fail("A5", "same-id write not accepted after a per-id slot freed");
    if (acc) do_write_data(wt_cnt - 1);
    drain_writes();

    // ---- Phase E: read payload, per-id ordering, mid reuse (B1/B2/D1/D2/E1) ----
    tA = rt_cnt;
    bfm_ar(4'd3, next_addr(), 8'd3, 500, acc, w2);
    if (!acc) fail("A3", "read id 3 not accepted with a free entry");
    tB = rt_cnt;
    bfm_ar(4'd5, next_addr(), 8'd1, 500, acc, w2);
    if (!acc) fail("A3", "read id 5 not accepted with a free entry");
    tC = rt_cnt;
    bfm_ar(4'd3, next_addr(), 8'd0, 500, acc, w2);
    if (!acc) fail("A5", "second same-id read not accepted below MAX_TXNS_PER_ID");
    tD = rt_cnt;
    bfm_ar(4'd8, next_addr(), 8'd2, 500, acc, w2);
    if (!acc) fail("A3", "read id 8 not accepted below the distinct-id bound");
    tE = rt_cnt;
    bfm_ar(4'd5, next_addr(), 8'd0, 500, acc, w2);
    if (!acc) fail("A5", "second read for id 5 not accepted below MAX_TXNS_PER_ID");
    // responses returned out of order across ids (B2 is free), in order
    // within an id (B1); per-mid order kept by us as the downstream slave.
    respond_read(tD);
    respond_read(tA);
    respond_read(tB);
    respond_read(tC);
    respond_read(tE);
    drain_reads();
    // two batches of 4 distinct ids: master ids must be reused only after
    // retirement (D2), and be distinct while co-outstanding (D1).
    for (jj = 0; jj < 4; jj = jj + 1) begin
      bfm_ar(9 + jj, next_addr(), 8'd0, 500, acc, w2);
      if (!acc) fail("A3", "read for a new id refused below the distinct-id bound");
    end
    drain_reads();
    for (jj = 0; jj < 4; jj = jj + 1) begin
      bfm_ar(1 + jj, next_addr(), 8'd0, 500, acc, w2);
      if (!acc) fail("A3", "read for a new id refused below the distinct-id bound");
    end
    drain_reads();

    // ---- Phase F: write payload, ordering, mid reuse (B1/B3/D1/D2/E1) ----
    tA = wt_cnt;
    bfm_aw(4'd2, next_addr(), 8'd2, 500, acc, w2);
    if (!acc) fail("A3", "write id 2 not accepted with a free entry");
    if (acc) do_write_data(tA);
    tB = wt_cnt;
    bfm_aw(4'd2, next_addr(), 8'd0, 500, acc, w2);
    if (!acc) fail("A5", "second same-id write not accepted below MAX_TXNS_PER_ID");
    if (acc) do_write_data(tB);
    tC = wt_cnt;
    bfm_aw(4'd7, next_addr(), 8'd1, 500, acc, w2);
    if (!acc) fail("A3", "write id 7 not accepted with a free entry");
    if (acc) do_write_data(tC);
    tD = wt_cnt;
    bfm_aw(4'd7, next_addr(), 8'd0, 500, acc, w2);
    if (!acc) fail("A5", "second write for id 7 not accepted below MAX_TXNS_PER_ID");
    if (acc) do_write_data(tD);
    tE = wt_cnt;
    bfm_aw(4'd9, next_addr(), 8'd3, 500, acc, w2);
    if (!acc) fail("A3", "write id 9 not accepted below the distinct-id bound");
    if (acc) do_write_data(tE);
    // write responses out of order across ids, in order within an id
    respond_write(tE);
    respond_write(tA);
    respond_write(tC);
    respond_write(tB);
    respond_write(tD);
    drain_writes();
    for (jj = 0; jj < 4; jj = jj + 1) begin
      bfm_aw(9 + jj, next_addr(), 8'd0, 500, acc, w2);
      if (!acc) fail("A3", "write for a new id refused below the distinct-id bound");
      if (acc) do_write_data(wt_cnt - 1);
    end
    drain_writes();
    for (jj = 0; jj < 4; jj = jj + 1) begin
      bfm_aw(1 + jj, next_addr(), 8'd0, 500, acc, w2);
      if (!acc) fail("A3", "write for a new id refused below the distinct-id bound");
      if (acc) do_write_data(wt_cnt - 1);
    end
    drain_writes();

    // ---- Phase G: reset in mid-operation (F1) ----
    // leave transactions outstanding, one read partially beat-given
    tP = rt_cnt;
    bfm_ar(4'd4, next_addr(), 8'd3, 500, acc, w2);
    tQ = rt_cnt;
    bfm_ar(4'd5, next_addr(), 8'd0, 500, acc, w2);
    tR = rt_cnt;
    bfm_ar(4'd6, next_addr(), 8'd2, 500, acc, w2);
    if (acc) begin
      wait_r_mid(tR, 500, ok);
      if (ok) begin
        do_rbeat(tR, 0, 500, ok);
        if (ok) do_rbeat(tR, 1, 500, ok);
      end
    end
    tS = wt_cnt;
    bfm_aw(4'd7, next_addr(), 8'd1, 50, acc, w2);
    if (acc) do_write_data(tS);
    tT = wt_cnt;
    bfm_aw(4'd8, next_addr(), 8'd0, 50, acc, w2);
    if (acc) do_write_data(tT);
    // reset: everything outstanding must be discarded
    @(negedge clk) rst_n = 1'b0;
    bfm_ar(4'd3, next_addr(), 8'd0, 3, acc, w2);
    bfm_aw(4'd2, next_addr(), 8'd0, 3, acc, w2);
    do_wbeat(0, 0, 3, ok);
    repeat (3) @(posedge clk);
    @(negedge clk) rst_n = 1'b1;
    clear_model();
    quiet_left = 30;
    repeat (30) @(posedge clk);
    // table must be empty: four distinct new read ids must be accepted (A3)
    bfm_ar(4'd12, next_addr(), 8'd0, 500, acc, w2);
    if (!acc) fail("A3", "table not empty after reset: read id 12 refused");
    bfm_ar(4'd13, next_addr(), 8'd0, 500, acc, w2);
    if (!acc) fail("A3", "table not empty after reset: read id 13 refused");
    bfm_ar(4'd14, next_addr(), 8'd0, 500, acc, w2);
    if (!acc) fail("A3", "table not empty after reset: read id 14 refused");
    bfm_ar(4'd15, next_addr(), 8'd0, 500, acc, w2);
    if (!acc) fail("A3", "table not empty after reset: read id 15 refused");
    drain_reads();
    // normal operation must resume end-to-end
    tU = wt_cnt;
    bfm_aw(4'd1, next_addr(), 8'd1, 500, acc, w2);
    if (acc) begin
      do_write_data(tU);
      respond_write(tU);
      drain_writes();
    end
    tV = rt_cnt;
    bfm_ar(4'd2, next_addr(), 8'd1, 500, acc, w2);
    if (acc) begin
      respond_read(tV);
      drain_reads();
    end

    // ---- Phase H: mixed traffic and cross-direction counting (A1) ----
    tA = rt_cnt;
    bfm_ar(4'd1, next_addr(), 8'd1, 500, acc, w2);
    if (!acc) fail("A3", "read id 1 not accepted with empty tables");
    tB = wt_cnt;
    bfm_aw(4'd3, next_addr(), 8'd1, 500, acc, w2);
    if (!acc) begin
      fail("A1", "write refused while the write side is below its bound (reads and writes counted separately)");
      fail("A3", "write id 3 not accepted below the write-side distinct-id bound");
    end
    if (acc) do_write_data(tB);
    tC = rt_cnt;
    bfm_ar(4'd2, next_addr(), 8'd0, 500, acc, w2);
    if (!acc) begin
      fail("A1", "read refused while the read side is below its bound (reads and writes counted separately)");
      fail("A3", "read id 2 not accepted below the read-side distinct-id bound");
    end
    tD = wt_cnt;
    bfm_aw(4'd4, next_addr(), 8'd0, 500, acc, w2);
    if (!acc) begin
      fail("A1", "write refused while the write side is below its bound (reads and writes counted separately)");
      fail("A3", "write id 4 not accepted below the write-side distinct-id bound");
    end
    if (acc) do_write_data(tD);
    respond_read(tA);
    respond_write(tD);
    respond_read(tC);
    respond_write(tB);
    drain_reads();
    drain_writes();
    // same slave id active in both directions at once (A1)
    tP = rt_cnt;
    bfm_ar(4'd5, next_addr(), 8'd0, 500, acc, w2);
    if (!acc) fail("A3", "read id 5 not accepted with a free entry");
    tQ = rt_cnt;
    bfm_ar(4'd5, next_addr(), 8'd0, 500, acc, w2);
    if (!acc) fail("A5", "second same-id read not accepted below MAX_TXNS_PER_ID");
    tR = wt_cnt;
    bfm_aw(4'd5, next_addr(), 8'd0, 500, acc, w2);
    if (!acc) fail("A1", "write for id 5 refused while only reads for id 5 are outstanding (directions counted separately)");
    if (acc) do_write_data(tR);
    respond_read(tP);
    respond_read(tQ);
    respond_write(tR);
    drain_reads();
    drain_writes();

    // ---- end of test ----
    if (rd_distinct != 0 || wr_distinct != 0)
      fail("D4", "outstanding transactions remain at the end of the test");
    if (fail_count == 0) $display("RESULT: PASS");
    else                 $display("RESULT: FAIL");
    $finish;
  end

endmodule
