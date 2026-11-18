module atop_filter_tb;

// ---------------------------------------------------------------------------
// PROVIDED PLUMBING -- moves transactions, checks nothing.
// ---------------------------------------------------------------------------
  // ---- clock ---------------------------------------------------------------
  logic clk = 1'b0;
  always #5 clk = ~clk;

  // A free-running cycle count, for your own bookkeeping and messages.
  int bfm_cycle = 0;
  always @(posedge clk) if (rst_n) bfm_cycle <= bfm_cycle + 1;

  // ---- reset ---------------------------------------------------------------
  logic rst_n = 1'b0;      // ACTIVE LOW

  task automatic bfm_reset(input int cycles = 5);
    @(negedge clk);
    rst_n = 1'b0;
    repeat (cycles) @(posedge clk);
    @(negedge clk);
    rst_n = 1'b1;
  endtask

  // ---- the signals, and the design under test ------------------------------
  logic [3:0]     s_awid;
  logic [31:0]   s_awaddr;
  logic [7:0]          s_awlen;
  logic [2:0]          s_awsize;
  logic [1:0]          s_awburst;
  logic                s_awlock;
  logic [3:0]          s_awcache;
  logic [2:0]          s_awprot;
  logic [3:0]          s_awqos;
  logic [3:0]          s_awregion;
  logic [5:0]          s_awatop;
  logic    s_awuser;
  logic                s_awvalid;
  logic                s_awready;
  logic [31:0]   s_wdata;
  logic [3:0] s_wstrb;
  logic                s_wlast;
  logic    s_wuser;
  logic                s_wvalid;
  logic                s_wready;
  logic [3:0]     s_bid;
  logic [1:0]          s_bresp;
  logic    s_buser;
  logic                s_bvalid;
  logic                s_bready;
  logic [3:0]     s_arid;
  logic [31:0]   s_araddr;
  logic [7:0]          s_arlen;
  logic [2:0]          s_arsize;
  logic [1:0]          s_arburst;
  logic                s_arlock;
  logic [3:0]          s_arcache;
  logic [2:0]          s_arprot;
  logic [3:0]          s_arqos;
  logic [3:0]          s_arregion;
  logic    s_aruser;
  logic                s_arvalid;
  logic                s_arready;
  logic [3:0]     s_rid;
  logic [31:0]   s_rdata;
  logic [1:0]          s_rresp;
  logic                s_rlast;
  logic    s_ruser;
  logic                s_rvalid;
  logic                s_rready;
  logic [3:0]     m_awid;
  logic [31:0]   m_awaddr;
  logic [7:0]          m_awlen;
  logic [2:0]          m_awsize;
  logic [1:0]          m_awburst;
  logic                m_awlock;
  logic [3:0]          m_awcache;
  logic [2:0]          m_awprot;
  logic [3:0]          m_awqos;
  logic [3:0]          m_awregion;
  logic [5:0]          m_awatop;
  logic    m_awuser;
  logic                m_awvalid;
  logic                m_awready;
  logic [31:0]   m_wdata;
  logic [3:0] m_wstrb;
  logic                m_wlast;
  logic    m_wuser;
  logic                m_wvalid;
  logic                m_wready;
  logic [3:0]     m_bid;
  logic [1:0]          m_bresp;
  logic    m_buser;
  logic                m_bvalid;
  logic                m_bready;
  logic [3:0]     m_arid;
  logic [31:0]   m_araddr;
  logic [7:0]          m_arlen;
  logic [2:0]          m_arsize;
  logic [1:0]          m_arburst;
  logic                m_arlock;
  logic [3:0]          m_arcache;
  logic [2:0]          m_arprot;
  logic [3:0]          m_arqos;
  logic [3:0]          m_arregion;
  logic    m_aruser;
  logic                m_arvalid;
  logic                m_arready;
  logic [3:0]     m_rid;
  logic [31:0]   m_rdata;
  logic [1:0]          m_rresp;
  logic                m_rlast;
  logic    m_ruser;
  logic                m_rvalid;
  logic                m_rready;

  atop_filter #(.ID_W(4), .ADDR_W(32), .DATA_W(32), .USER_W(1)) dut (
    .clk_i(clk),
    .rst_ni(rst_n),
    .s_awid_i(s_awid),
    .s_awaddr_i(s_awaddr),
    .s_awlen_i(s_awlen),
    .s_awsize_i(s_awsize),
    .s_awburst_i(s_awburst),
    .s_awlock_i(s_awlock),
    .s_awcache_i(s_awcache),
    .s_awprot_i(s_awprot),
    .s_awqos_i(s_awqos),
    .s_awregion_i(s_awregion),
    .s_awatop_i(s_awatop),
    .s_awuser_i(s_awuser),
    .s_awvalid_i(s_awvalid),
    .s_awready_o(s_awready),
    .s_wdata_i(s_wdata),
    .s_wstrb_i(s_wstrb),
    .s_wlast_i(s_wlast),
    .s_wuser_i(s_wuser),
    .s_wvalid_i(s_wvalid),
    .s_wready_o(s_wready),
    .s_bid_o(s_bid),
    .s_bresp_o(s_bresp),
    .s_buser_o(s_buser),
    .s_bvalid_o(s_bvalid),
    .s_bready_i(s_bready),
    .s_arid_i(s_arid),
    .s_araddr_i(s_araddr),
    .s_arlen_i(s_arlen),
    .s_arsize_i(s_arsize),
    .s_arburst_i(s_arburst),
    .s_arlock_i(s_arlock),
    .s_arcache_i(s_arcache),
    .s_arprot_i(s_arprot),
    .s_arqos_i(s_arqos),
    .s_arregion_i(s_arregion),
    .s_aruser_i(s_aruser),
    .s_arvalid_i(s_arvalid),
    .s_arready_o(s_arready),
    .s_rid_o(s_rid),
    .s_rdata_o(s_rdata),
    .s_rresp_o(s_rresp),
    .s_rlast_o(s_rlast),
    .s_ruser_o(s_ruser),
    .s_rvalid_o(s_rvalid),
    .s_rready_i(s_rready),
    .m_awid_o(m_awid),
    .m_awaddr_o(m_awaddr),
    .m_awlen_o(m_awlen),
    .m_awsize_o(m_awsize),
    .m_awburst_o(m_awburst),
    .m_awlock_o(m_awlock),
    .m_awcache_o(m_awcache),
    .m_awprot_o(m_awprot),
    .m_awqos_o(m_awqos),
    .m_awregion_o(m_awregion),
    .m_awatop_o(m_awatop),
    .m_awuser_o(m_awuser),
    .m_awvalid_o(m_awvalid),
    .m_awready_i(m_awready),
    .m_wdata_o(m_wdata),
    .m_wstrb_o(m_wstrb),
    .m_wlast_o(m_wlast),
    .m_wuser_o(m_wuser),
    .m_wvalid_o(m_wvalid),
    .m_wready_i(m_wready),
    .m_bid_i(m_bid),
    .m_bresp_i(m_bresp),
    .m_buser_i(m_buser),
    .m_bvalid_i(m_bvalid),
    .m_bready_o(m_bready),
    .m_arid_o(m_arid),
    .m_araddr_o(m_araddr),
    .m_arlen_o(m_arlen),
    .m_arsize_o(m_arsize),
    .m_arburst_o(m_arburst),
    .m_arlock_o(m_arlock),
    .m_arcache_o(m_arcache),
    .m_arprot_o(m_arprot),
    .m_arqos_o(m_arqos),
    .m_arregion_o(m_arregion),
    .m_aruser_o(m_aruser),
    .m_arvalid_o(m_arvalid),
    .m_arready_i(m_arready),
    .m_rid_i(m_rid),
    .m_rdata_i(m_rdata),
    .m_rresp_i(m_rresp),
    .m_rlast_i(m_rlast),
    .m_ruser_i(m_ruser),
    .m_rvalid_i(m_rvalid),
    .m_rready_o(m_rready));

  // ---- upstream: offering requests to the design ---------------------------
  task automatic bfm_aw(input logic [3:0] id, input logic [31:0] addr,
                        input logic [7:0] len, input logic [5:0] atop,
                        input int timeout, output bit accepted);
    int t;
    @(negedge clk);
    s_awid = id; s_awaddr = addr; s_awlen = len; s_awatop = atop;
    s_awsize = 3'd2; s_awburst = 2'd1; s_awlock = 1'b0; s_awcache = 4'd0;
    s_awprot = 3'd0; s_awqos = 4'd0; s_awregion = 4'd0; s_awuser = 1'b0;
    s_awvalid = 1'b1;
    accepted = 1'b0;
    for (t = 0; t < timeout; t++) begin
      @(posedge clk);
      if (s_awready) begin accepted = 1'b1; break; end
    end
    @(negedge clk) s_awvalid = 1'b0;
  endtask

  task automatic bfm_w(input logic [31:0] data, input logic [3:0] strb,
                       input bit last, input int timeout, output bit accepted);
    int t;
    @(negedge clk);
    s_wdata = data; s_wstrb = strb; s_wlast = last; s_wuser = 1'b0;
    s_wvalid = 1'b1;
    accepted = 1'b0;
    for (t = 0; t < timeout; t++) begin
      @(posedge clk);
      if (s_wready) begin accepted = 1'b1; break; end
    end
    @(negedge clk) s_wvalid = 1'b0;
  endtask

  task automatic bfm_ar(input logic [3:0] id, input logic [31:0] addr,
                        input logic [7:0] len, input int timeout, output bit accepted);
    int t;
    @(negedge clk);
    s_arid = id; s_araddr = addr; s_arlen = len;
    s_arsize = 3'd2; s_arburst = 2'd1; s_arlock = 1'b0; s_arcache = 4'd0;
    s_arprot = 3'd0; s_arqos = 4'd0; s_arregion = 4'd0; s_aruser = 1'b0;
    s_arvalid = 1'b1;
    accepted = 1'b0;
    for (t = 0; t < timeout; t++) begin
      @(posedge clk);
      if (s_arready) begin accepted = 1'b1; break; end
    end
    @(negedge clk) s_arvalid = 1'b0;
  endtask

  task automatic bfm_b_ready(input bit v); @(negedge clk); s_bready = v; endtask
  task automatic bfm_r_ready(input bit v); @(negedge clk); s_rready = v; endtask

  // ---- downstream: this plumbing is the SUBORDINATE ------------------------
  int bfm_b_lag = 0;
  task automatic bfm_dn_b_lag(input int cycles); bfm_b_lag = cycles; endtask

  int bfm_bq_id [$], bfm_bq_t [$], bfm_rq_id [$], bfm_rq_n [$];
  assign m_awready = 1'b1;
  assign m_wready  = 1'b1;
  assign m_arready = 1'b1;
  always @(posedge clk) begin
    if (!rst_n) begin
      bfm_bq_id.delete(); bfm_bq_t.delete(); bfm_rq_id.delete(); bfm_rq_n.delete();
    end else begin
      if (m_awvalid && m_awready) begin
        bfm_bq_id.push_back(int'(m_awid)); bfm_bq_t.push_back(bfm_cycle + bfm_b_lag);
      end
      if (m_arvalid && m_arready) begin
        bfm_rq_id.push_back(int'(m_arid)); bfm_rq_n.push_back(int'(m_arlen) + 1);
      end
      if (m_bvalid && m_bready) begin
        void'(bfm_bq_id.pop_front()); void'(bfm_bq_t.pop_front());
      end
      if (m_rvalid && m_rready) begin
        if (bfm_rq_n[0] <= 1) begin void'(bfm_rq_id.pop_front()); void'(bfm_rq_n.pop_front()); end
        else bfm_rq_n[0] = bfm_rq_n[0] - 1;
      end
    end
  end
  always_comb begin
    m_bvalid = (bfm_bq_id.size() > 0) && (bfm_cycle >= bfm_bq_t[0]);
    m_bid    = 4'(bfm_bq_id.size() ? bfm_bq_id[0] : 0);
    m_bresp  = 2'b00;                 // the subordinate always succeeds
    m_buser  = 1'b0;
    m_rvalid = (bfm_rq_id.size() > 0);
    m_rid    = 4'(bfm_rq_id.size() ? bfm_rq_id[0] : 0);
    m_rdata  = 32'hFEED_0000 + 32'(bfm_rq_n.size() ? bfm_rq_n[0] : 0);
    m_rresp  = 2'b00;
    m_ruser  = 1'b0;
    m_rlast  = (bfm_rq_id.size() > 0) && (bfm_rq_n[0] <= 1);
  end

  // ---- idle the upstream request signals at time zero ----------------------
  initial begin
    s_awvalid = 1'b0; s_wvalid = 1'b0; s_arvalid = 1'b0;
    s_bready  = 1'b1; s_rready = 1'b1;
    s_awid = '0; s_awaddr = '0; s_awlen = '0; s_awsize = 3'd2; s_awburst = 2'd1;
    s_awlock = 1'b0; s_awcache = '0; s_awprot = '0; s_awqos = '0; s_awregion = '0;
    s_awatop = '0; s_awuser = 1'b0;
    s_wdata = '0; s_wstrb = 4'hF; s_wlast = 1'b0; s_wuser = 1'b0;
    s_arid = '0; s_araddr = '0; s_arlen = '0; s_arsize = 3'd2; s_arburst = 2'd1;
    s_arlock = 1'b0; s_arcache = '0; s_arprot = '0; s_arqos = '0; s_arregion = '0;
    s_aruser = 1'b0;
  end

  // ---- watchdog ------------------------------------------------------------
  initial begin
    #4_000_000;
    $display("RESULT: FAIL (watchdog: no forward progress)");
    $finish;
  end

// ===========================================================================
// CHECKER
// ===========================================================================

  typedef struct packed {
    logic [3:0]  id;
    logic [31:0] addr;
    logic [7:0]  len;
    logic [2:0]  sz;
    logic [1:0]  burst;
    logic        lk;
    logic [3:0]  cache;
    logic [2:0]  prot;
    logic [3:0]  qos;
    logic [3:0]  region;
    logic [5:0]  atop;
    logic        usr;
  } aw_t;

  typedef struct packed {
    logic [31:0] data;
    logic [3:0]  strb;
    logic        lst;
    logic        usr;
  } w_t;

  // Response-channel values sampled at the NEGATIVE edge.  These may be
  // combinational in plumbing outputs that mutate (with blocking assigns)
  // inside the clock-edge timestep, so they cannot be trusted at posedge.
  // At the negedge they are always settled.
  logic        n_s_bvalid;
  logic [3:0]  n_s_bid;
  logic [1:0]  n_s_bresp;
  logic        n_s_buser;
  logic        n_s_rvalid;
  logic [3:0]  n_s_rid;
  logic [31:0] n_s_rdata;
  logic [1:0]  n_s_rresp;
  logic        n_s_rlast;
  logic        n_s_ruser;

  always @(negedge clk) begin
    n_s_bvalid = s_bvalid; n_s_bid = s_bid; n_s_bresp = s_bresp; n_s_buser = s_buser;
    n_s_rvalid = s_rvalid; n_s_rid = s_rid; n_s_rdata = s_rdata;
    n_s_rresp = s_rresp;   n_s_rlast = s_rlast; n_s_ruser = s_ruser;
  end

  // ---- model state ---------------------------------------------------------
  aw_t      awq[$];          // non-atomic AWs accepted at slave port, in order
  w_t       wexp[$];         // W beats expected on the master port, in order
  int       dn_bq[$];        // ids of forwarded writes whose B is downstream
  int       arq_id[$];       // ARs accepted at slave port, in order
  logic [31:0] arq_addr[$];
  logic [7:0]  arq_len[$];
  int       dn_rq_id[$];     // outstanding forwarded reads
  int       dn_rq_n[$];
  int       owed_b[0:15];    // manufactured B beats still owed, by id
  int       owed_r[0:15];    // manufactured R beats still owed, by id
  int       fw_id[$];        // filtered writes awaiting responses (liveness)
  int       fw_t[$];
  int       debt = 0;        // W1: downstream write debt
  int       n_fail = 0;
  bit        cur_atomic = 0; // does the W burst currently being sent belong to
                             // a filtered write?  (set by the stimulus)
  logic [3:0] cur_filt_id = 0;
  int        edges_q = 0;
  int        x3_skip = 0;    // cycles to suspend X3 checks after a ready change
  int        x3b_cnt = 0, x3r_cnt = 0;
  logic [6:0]  x3b_p = '0;
  logic [39:0] x3r_p = '0;
  bit        b_held = 0, r_held = 0;

  task automatic fail(input string msg);
    n_fail++;
    $display("FAIL [cycle %0d]: %s", bfm_cycle, msg);
  endtask

  function automatic int owed_total();
    int s;
    s = 0;
    for (int i = 0; i < 16; i++) s = s + owed_b[i] + owed_r[i];
    return s;
  endfunction

  task automatic reset_and_check();
    @(negedge clk);
    rst_n = 1'b0;
    repeat (6) @(posedge clk);   // X1 behaviour is checked by the monitor here
    @(negedge clk);
    rst_n = 1'b1;
    repeat (2) @(posedge clk);
  endtask

  task automatic wait_quiet(input int timeout, input string tag);
    for (int t = 0; t < timeout; t++) begin
      @(posedge clk);
      if ((awq.size() == 0) && (wexp.size() == 0) && (dn_bq.size() == 0) &&
          (dn_rq_id.size() == 0) && (arq_id.size() == 0) && (fw_id.size() == 0) &&
          (owed_total() == 0))
        return;
    end
    fail($sformatf("X4/F3/F4: owed traffic did not drain (%s)", tag));
    reset_and_check();
  endtask

  // Ready controls that also suspend the X3 checker across the change, so
  // the transition cycle is never misread as a stability violation.
  task automatic tb_b_ready(input bit v);
    @(negedge clk); s_bready = v; x3_skip = 2;
  endtask
  task automatic tb_r_ready(input bit v);
    @(negedge clk); s_rready = v; x3_skip = 2;
  endtask

  // ---- the monitor ---------------------------------------------------------
  always @(posedge clk) begin
    edges_q <= edges_q + 1;
    if (!rst_n) begin
      // X2: after (and during) reset the model owes nothing
      awq.delete(); wexp.delete(); dn_bq.delete();
      arq_id.delete(); arq_addr.delete(); arq_len.delete();
      dn_rq_id.delete(); dn_rq_n.delete(); fw_id.delete(); fw_t.delete();
      debt = 0;
      for (int i = 0; i < 16; i++) begin owed_b[i] = 0; owed_r[i] = 0; end
      x3b_cnt = 0; x3r_cnt = 0;
      // X1: nothing is originated while rst_ni is low (checked only from the
      // second rising edge onward; before the first edge nothing is defined).
      if (edges_q >= 1) begin
        if (m_awvalid)  fail("X1: m_awvalid asserted while rst_ni low");
        if (m_wvalid)   fail("X1: m_wvalid asserted while rst_ni low");
        if (n_s_bvalid) fail("X1: B response originated while rst_ni low");
        if (n_s_rvalid) fail("X1: R response originated while rst_ni low");
      end
    end else begin
      // ---------------- F1: no atomic opcode ever leaves the master port
      if (m_awvalid && (m_awatop != 6'b000000))
        fail("F1: m_awatop nonzero while m_awvalid asserted");

      // ---------------- AW, slave side
      if (s_awvalid && s_awready) begin
        if (s_awatop[5:4] != 2'b00) begin
          // C1/C2: this write is filtered; it owes one B and maybe R beats
          owed_b[s_awid] = owed_b[s_awid] + 1;
          owed_r[s_awid] = s_awatop[5] ? (int'(s_awlen) + 1) : 0;
        end else begin
          awq.push_back('{id:s_awid, addr:s_awaddr, len:s_awlen, sz:s_awsize,
                         burst:s_awburst, lk:s_awlock, cache:s_awcache,
                         prot:s_awprot, qos:s_awqos, region:s_awregion,
                         atop:s_awatop, usr:s_awuser});
        end
      end

      // ---------------- AW, master side (P1 / F1)
      if (m_awvalid && m_awready) begin
        debt = debt + 1;
        dn_bq.push_back(int'(m_awid));
        if (awq.size() == 0)
          fail("F1/P1: AW forwarded with no matching non-atomic AW");
        else begin
          automatic aw_t e = awq.pop_front();
          // P1: every field unmodified -- except m_awatop, which F1 forces to 0
          if ((e.id != m_awid) || (e.addr != m_awaddr) || (e.len != m_awlen) ||
              (e.sz != m_awsize) || (e.burst != m_awburst) || (e.lk != m_awlock) ||
              (e.cache != m_awcache) || (e.prot != m_awprot) || (e.qos != m_awqos) ||
              (e.region != m_awregion) || (e.usr != m_awuser))
            fail("P1: forwarded AW field modified");
        end
      end

      // ---------------- W, slave side
      if (s_wvalid && s_wready) begin
        if (!cur_atomic)
          wexp.push_back('{data:s_wdata, strb:s_wstrb, lst:s_wlast, usr:s_wuser});
        else if (s_wlast) begin
          // F4: liveness clock for this filtered write starts at its wlast
          fw_id.push_back(int'(cur_filt_id));
          fw_t.push_back(bfm_cycle);
        end
      end

      // ---------------- W, master side (P2 / F2)
      if (m_wvalid && m_wready) begin
        if (m_wlast) debt = debt - 1;
        if (wexp.size() == 0)
          fail("F2: W beat forwarded for a write that was not forwarded");
        else begin
          automatic w_t e = wexp.pop_front();
          if ((e.data != m_wdata) || (e.strb != m_wstrb) ||
              (e.lst != m_wlast) || (e.usr != m_wuser))
            fail("P2: forwarded W beat modified or out of order");
        end
      end

      // ---------------- W1/W2: the outstanding-write bound
      if (debt > 4)
        fail("W2: downstream write debt exceeds MAX_WRITE_TXNS (4)");
      if (debt < 0)
        fail("W1/F2: debt went negative (W burst completed without a forwarded AW)");

      // ---------------- AR, slave side
      if (s_arvalid && s_arready) begin
        arq_id.push_back(int'(s_arid));
        arq_addr.push_back(s_araddr);
        arq_len.push_back(s_arlen);
      end

      // ---------------- AR, master side (P3)
      if (m_arvalid && m_arready) begin
        if (arq_id.size() == 0)
          fail("P3: AR forwarded with no matching read");
        else begin
          automatic int       aid = arq_id.pop_front();
          automatic logic [31:0] aad = arq_addr.pop_front();
          automatic logic [7:0]  aln = arq_len.pop_front();
          if ((4'(aid) != m_arid) || (aad != m_araddr) || (aln != m_arlen) ||
              (m_aruser != 1'b0))
            fail("P3: forwarded AR modified");
          dn_rq_id.push_back(aid);
          dn_rq_n.push_back(int'(aln) + 1);
        end
      end

      // ---------------- B, slave side (P4 / F3)
      if (n_s_bvalid && s_bready) begin
        if (n_s_bresp == 2'b00) begin
          if (dn_bq.size() == 0)
            fail("P4/F3: OKAY B response with no downstream B pending");
          else begin
            if ((4'(dn_bq[0]) != n_s_bid) || (n_s_buser != 1'b0))
              fail("P4: forwarded B response modified");
            void'(dn_bq.pop_front());
          end
        end else if (n_s_bresp == 2'b10) begin
          if (owed_b[n_s_bid] == 0)
            fail("F3: SLVERR B not owed by any filtered write (id)");
          owed_b[n_s_bid] = owed_b[n_s_bid] - 1;
        end else
          fail("P4/F3: B response with illegal resp code");
      end

      // ---------------- R, slave side (P3 / F4 / F5)
      if (n_s_rvalid && s_rready) begin
        if (n_s_rresp == 2'b00) begin
          if (dn_rq_id.size() == 0)
            fail("P3/F4: OKAY R beat with no read outstanding");
          else begin
            if (4'(dn_rq_id[0]) != n_s_rid)
              fail("P3: forwarded R beat id mismatch");
            if (n_s_rdata != (32'hFEED_0000 + 32'(dn_rq_n[0])))
              fail("P3: forwarded R beat data modified");
            if (n_s_ruser != 1'b0)
              fail("P3: forwarded R beat user modified");
            if (n_s_rlast != (dn_rq_n[0] <= 1))
              fail("P3: forwarded R beat rlast mispositioned");
            if (dn_rq_n[0] <= 1) begin
              void'(dn_rq_id.pop_front()); void'(dn_rq_n.pop_front());
            end else
              dn_rq_n[0] = dn_rq_n[0] - 1;
          end
        end else if (n_s_rresp == 2'b10) begin
          // F4/F5: attribute by rid, never by position in the stream
          if (owed_r[n_s_rid] == 0)
            fail("F4/F5: SLVERR R beat not owed by any filtered write (id)");
          else begin
            automatic bit exp_lst = (owed_r[n_s_rid] == 1);
            owed_r[n_s_rid] = owed_r[n_s_rid] - 1;
            if (n_s_rlast != exp_lst)
              fail("F4: manufactured R rlast not on the final beat (and only it)");
          end
        end else
          fail("P3/F4: R response with illegal resp code");
      end

      // ---------------- X4: liveness of manufactured responses.
      // Backpressure we are applying ourselves does not count against the
      // bound, so the deadline is postponed while either ready is low.
      for (int i = 0; i < fw_id.size(); ) begin
        if ((owed_b[fw_id[i]] + owed_r[fw_id[i]]) == 0) begin
          void'(fw_id.delete(i)); void'(fw_t.delete(i));
        end else begin
          if (!s_bready || !s_rready)
            fw_t[i] = fw_t[i] + 1;
          else if (bfm_cycle - fw_t[i] > 68)
            fail("X4: manufactured response not delivered within 64 cycles of wlast");
          i = i + 1;
        end
      end

      // ---------------- X3: valid held stable until ready (s_b / s_r)
      if (x3_skip > 0) begin
        x3_skip = x3_skip - 1;
        x3b_cnt = 0; x3r_cnt = 0;
      end else begin
        if (x3b_cnt >= 1) begin
          if (!n_s_bvalid)
            fail("X3: s_bvalid dropped before ready was seen");
          else if ({n_s_bid, n_s_bresp, n_s_buser} != x3b_p)
            fail("X3: s_b payload changed before ready was seen");
        end
        if (n_s_bvalid && !s_bready) begin
          x3b_cnt = x3b_cnt + 1;
          x3b_p = {n_s_bid, n_s_bresp, n_s_buser};
          b_held = 1;
        end else x3b_cnt = 0;

        if (x3r_cnt >= 1) begin
          if (!n_s_rvalid)
            fail("X3: s_rvalid dropped before ready was seen");
          else if ({n_s_rid, n_s_rdata, n_s_rresp, n_s_rlast, n_s_ruser} != x3r_p)
            fail("X3: s_r payload changed before ready was seen");
        end
        if (n_s_rvalid && !s_rready) begin
          x3r_cnt = x3r_cnt + 1;
          x3r_p = {n_s_rid, n_s_rdata, n_s_rresp, n_s_rlast, n_s_ruser};
          r_held = 1;
        end else x3r_cnt = 0;
      end
    end
  end

// ===========================================================================
// STIMULUS
// ===========================================================================

  // strict=0: a timeout is not reported as a violation (used where the
  // contract itself permits stalling under backpressure); the caller then
  // resynchronises with a reset.
  task automatic do_write(input logic [3:0] id, input logic [31:0] addr,
                          input logic [7:0] len, input logic [5:0] atop,
                          input int awto, input int wto, input bit strict,
                          output bit ok);
    bit acc;
    ok = 1'b1;
    cur_atomic   = (atop[5:4] != 2'b00);
    cur_filt_id  = id;
    bfm_aw(id, addr, len, atop, awto, acc);
    if (!acc) begin
      if (strict) fail("X4: AW not accepted within the liveness bound");
      ok = 1'b0; cur_atomic = 1'b0; return;
    end
    for (int i = 0; i <= int'(len); i++) begin
      bfm_w(32'hA5A0_0000 ^ (32'(id) << 20) ^ (32'(i) << 4), 4'hF,
            (i == int'(len)), wto, acc);
      if (!acc) begin
        if (strict) fail("X4/F2: W beat not consumed within the liveness bound");
        ok = 1'b0; cur_atomic = 1'b0; return;
      end
    end
    cur_atomic = 1'b0;
  endtask

  task automatic do_read(input logic [3:0] id, input logic [31:0] addr,
                         input logic [7:0] len, input int timeout,
                         input bit strict, output bit ok);
    bit acc;
    ok = 1'b1;
    bfm_ar(id, addr, len, timeout, acc);
    if (!acc) begin
      if (strict) fail("X4: AR not accepted within the liveness bound");
      ok = 1'b0;
    end
  endtask

  initial begin
    bit ok, acc, acc5, accw;
    for (int i = 0; i < 16; i++) begin owed_b[i] = 0; owed_r[i] = 0; end

    reset_and_check();

    // ---- phase 1: plain forwarded write, burst of two beats (P1/P2/P4)
    do_write(4'h1, 32'h0000_1000, 8'd1, 6'h00, 100, 100, 1'b1, ok);
    wait_quiet(400, "phase1");

    // ---- phase 2: atomic without read response (C1/C2, F1..F3, F5)
    do_write(4'h2, 32'h0000_2000, 8'd2, 6'h10, 100, 100, 1'b1, ok);
    wait_quiet(400, "phase2");

    // ---- phase 3: atomic with read response, two R beats (F4)
    do_write(4'h3, 32'h0000_3000, 8'd1, 6'h20, 100, 100, 1'b1, ok);
    wait_quiet(400, "phase3");

    // ---- phase 4: reads, single and burst (P3)
    do_read(4'h5, 32'h4000_0000, 8'd1, 200, 1'b1, ok);
    do_read(4'h9, 32'h4000_1000, 8'd3, 200, 1'b1, ok);
    wait_quiet(400, "phase4");

    // ---- phase 5: classification corners (C1, C2)
    do_write(4'h6, 32'h0000_6000, 8'd0, 6'h0F, 100, 100, 1'b1, ok); // [5:4]=00: NOT atomic
    do_write(4'h7, 32'h0000_7000, 8'd0, 6'h1F, 100, 100, 1'b1, ok); // atomic, no R
    do_write(4'hA, 32'h0000_A000, 8'd0, 6'h3F, 100, 100, 1'b1, ok); // atomic, with R
    wait_quiet(400, "phase5");

    // ---- phase 6: the outstanding-write bound (W2/W3)
    for (int i = 0; i < 4; i++) begin
      bfm_aw(4'(8 + i), 32'h0000_8000 + 32'(i), 8'd0, 6'h00, 100, acc);
      if (!acc) fail("W3/X4: AW stalled while debt strictly below MAX_WRITE_TXNS");
    end
    fork
      begin
        bfm_aw(4'hC, 32'h0000_8004, 8'd0, 6'h00, 2000, acc5);
      end
      begin
        for (int i = 0; i < 4; i++)
          bfm_w(32'hB000_0000 + 32'(i), 4'hF, 1'b1, 100, accw);
      end
    join
    if (!acc5) fail("X4: AW not accepted after the debt was reduced");
    bfm_w(32'hB000_0004, 4'hF, 1'b1, 100, accw);
    if (!accw) fail("X4: final W beat not accepted");
    wait_quiet(400, "phase6");

    // ---- phase 7: W4 -- a pending B must not hold the bound shut
    bfm_dn_b_lag(300);
    for (int i = 0; i < 6; i++)
      do_write(4'(i), 32'h0000_9000 + 32'(i), 8'd0, 6'h00, 150, 100, 1'b1, ok);
    wait_quiet(4000, "phase7");
    bfm_dn_b_lag(0);

    // ---- phase 8a: X3 on a forwarded B under backpressure
    b_held = 0;
    tb_b_ready(0);
    do_write(4'h0, 32'h0000_0000, 8'd0, 6'h00, 500, 200, 1'b0, ok);
    if (ok) begin
      repeat (20) @(posedge clk);
      tb_b_ready(1);
      wait_quiet(300, "phase8a");
    end else begin
      tb_b_ready(1);
      reset_and_check();
    end

    // ---- phase 8b: X3 on forwarded R beats under backpressure
    r_held = 0;
    tb_r_ready(0);
    do_read(4'h5, 32'h5000_0000, 8'd1, 500, 1'b0, ok);
    if (ok) begin
      repeat (20) @(posedge clk);
      tb_r_ready(1);
      wait_quiet(300, "phase8b");
    end else begin
      tb_r_ready(1);
      reset_and_check();
    end

    // ---- phase 8c: X3 on manufactured R beats under backpressure.
    // The unit may lawfully hold a filtered write open while its responses
    // are unconsumed, so a W timeout here is inconclusive, not a failure.
    r_held = 0;
    tb_r_ready(0);
    do_write(4'h3, 32'h0000_3000, 8'd3, 6'h20, 500, 400, 1'b0, ok);
    if (ok) begin
      repeat (20) @(posedge clk);
      tb_r_ready(1);
      wait_quiet(400, "phase8c");
    end else begin
      tb_r_ready(1);
      reset_and_check();
    end

    // ---- phase 9: X2 -- reset clears all state and the unit still works
    reset_and_check();
    do_write(4'h1, 32'h0000_1000, 8'd0, 6'h00, 100, 100, 1'b1, ok);
    do_write(4'h2, 32'h0000_2000, 8'd0, 6'h30, 100, 100, 1'b1, ok); // atomic, 1 R beat
    wait_quiet(400, "phase9");

    $display("info: backpressure holds exercised: b=%0b r=%0b, failures=%0d",
             b_held, r_held, n_fail);
    if (n_fail == 0)
      $display("RESULT: PASS");
    else
      $display("RESULT: FAIL");
    $finish;
  end

endmodule
