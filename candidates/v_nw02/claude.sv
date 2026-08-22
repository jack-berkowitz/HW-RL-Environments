// ===========================================================================
//  atop_filter_tb -- specification-driven testbench for atop_filter
//
//  Checks C1, C2, P1-P4, F1-F5, W1-W5, X1-X4.  Deliberately blind to every
//  item of section L: the order of a manufactured B against its R beats, the
//  values on rdata/ruser/buser of a manufactured response, whether any ready
//  is registered, whether a later AW is stalled behind a filtered write, and
//  the latency of anything.
// ===========================================================================
module atop_filter_tb;

  // -------------------------------------------------------------------------
  // PROVIDED PLUMBING -- moves transactions, checks nothing.
  // -------------------------------------------------------------------------

  // ---- clock ---------------------------------------------------------------
  logic clk = 1'b0;
  always #5 clk = ~clk;

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

  // =========================================================================
  //  MY CODE
  // =========================================================================
  //
  //  Nothing here is identified by matching a payload against a payload.
  //  Every transaction gets a unique address and, more importantly, the two
  //  sources that can appear on the slave B and R channels are kept apart by
  //  construction: ordinary writes and reads use IDs 0..7, filtered atomic
  //  writes use IDs 8..15.  So a response is attributed by which bookkeeping
  //  record is outstanding for its ID, never by inspecting whether its RESP
  //  happens to look like SLVERR.
  //
  //  W beats are tied to their AW by AXI's own rule -- W bursts follow AW
  //  order -- and the driver below never offers a W beat before the AW it
  //  belongs to has been accepted, so that association is never ambiguous.
  // -------------------------------------------------------------------------

  localparam int MAX_WRITE_TXNS = 4;
  localparam int MAX_ERR        = 30;

  typedef struct packed {
    logic [3:0]  id;
    logic [31:0] addr;
    logic [7:0]  len;
    logic [2:0]  size;
    logic [1:0]  burst;
    logic        lock;
    logic [3:0]  cache;
    logic [2:0]  prot;
    logic [3:0]  qos;
    logic [3:0]  region;
    logic [5:0]  atop;
    logic        user;
  } awr_t;

  typedef struct packed {
    logic [3:0]  id;
    logic [31:0] addr;
    logic [7:0]  len;
    logic [2:0]  size;
    logic [1:0]  burst;
    logic        lock;
    logic [3:0]  cache;
    logic [2:0]  prot;
    logic [3:0]  qos;
    logic [3:0]  region;
    logic        user;
  } arr_t;

  typedef struct packed {
    logic [31:0] data;
    logic [3:0]  strb;
    logic        last;
    logic        user;
    logic [15:0] seq_no;
  } wbt_t;

  // ---- what the stimulus asks the drivers to present ----------------------
  awr_t awq [$];
  wbt_t wq  [$];
  arr_t arq [$];

  // ---- what the design is expected to produce -----------------------------
  awr_t exp_maw [$];                 // forwarded AWs, in order
  wbt_t exp_mw  [$];                 // forwarded W beats, in order
  arr_t exp_mar [$];                 // forwarded ARs, in order
  logic [6:0]  fb_q [$];             // {id,resp,user} seen on m_b, owed upstream
  logic [39:0] fr_q [$];             // {id,data,resp,last,user} seen on m_r

  // ---- writes accepted upstream, in AW order, W burst not yet finished ----
  //      {atom, owes_r, id[3:0], len[7:0]}
  logic [13:0] wo_q [$];

  // ---- filtered writes awaiting their manufactured responses --------------
  int pend_id    [$];
  int pend_rleft [$];
  int pend_bpend [$];
  int pend_t0    [$];
  int pend_clean [$];

  // ---- counters -----------------------------------------------------------
  int err_cnt    = 0;
  int debt       = 0;      // W1: master-port AW handshakes - master-port WLAST
  int aw_acc_cnt = 0;
  int n_filtered = 0;
  int n_forward  = 0;
  int n_reads    = 0;
  bit sb_en      = 1'b1;
  bit x1_en      = 1'b0;
  bit x2_en      = 1'b0;
  int rst_hot    = 0;

  // ---- registered handshake flags, for the drivers ------------------------
  logic aw_acc, w_acc, ar_acc;

  // ---- previous-cycle samples, for X3 -------------------------------------
  bit          p_ok = 1'b0;
  logic        p_sbv, p_sbr, p_srv, p_srr, p_mawv, p_mawr, p_mwv, p_mwr, p_marv, p_marr;
  logic [6:0]  p_sb;
  logic [39:0] p_sr;
  awr_t        p_maw;
  arr_t        p_mar;
  logic [37:0] p_mw;


  // -------------------------------------------------------------------------
  //  Pre-edge snapshot.
  //
  //  A latch that is transparent while the clock is low and closed while it is
  //  high, so every q_ below holds the value its signal had immediately before
  //  the rising edge -- which is the value the design itself used.  The monitor
  //  reads only these copies.
  //
  //  Reading the live signals at the rising edge instead is not safe here: a
  //  clocked block that updates state with blocking assignments -- the
  //  subordinate model above does exactly that with its queues -- feeds
  //  combinational outputs that then change part-way through the same
  //  timestep, and a monitor scheduled after it sees handshakes that never
  //  happened.  A nonblocking capture at the falling edge does not fix it
  //  either: a nonblocking assignment evaluates its right-hand side when the
  //  statement runs, so it would race the drivers on that same edge.
  // -------------------------------------------------------------------------
  bit   q_rst;
  logic q_sawv, q_sawr, q_swv, q_swr, q_sarv, q_sarr, q_sbv, q_sbr, q_srv, q_srr;
  logic q_mawv, q_mawr, q_mwv, q_mwr, q_marv, q_marr, q_mbv, q_mbr, q_mrv, q_mrr;
  awr_t q_saw, q_maw;
  arr_t q_sar, q_mar;
  logic [37:0] q_sw, q_mw;
  logic [6:0]  q_sb, q_mb;
  logic [39:0] q_sr, q_mr;

  always_latch if (!clk) begin
    q_rst   = rst_n;
    q_sawv  = s_awvalid; q_sawr  = s_awready;
    q_saw   = {s_awid, s_awaddr, s_awlen, s_awsize, s_awburst, s_awlock,
               s_awcache, s_awprot, s_awqos, s_awregion, s_awatop, s_awuser};
    q_swv   = s_wvalid;  q_swr  = s_wready;
    q_sw    = {s_wdata, s_wstrb, s_wlast, s_wuser};
    q_sarv  = s_arvalid; q_sarr  = s_arready;
    q_sar   = {s_arid, s_araddr, s_arlen, s_arsize, s_arburst, s_arlock,
               s_arcache, s_arprot, s_arqos, s_arregion, s_aruser};
    q_sbv   = s_bvalid;  q_sbr  = s_bready;
    q_sb    = {s_bid, s_bresp, s_buser};
    q_srv   = s_rvalid;  q_srr  = s_rready;
    q_sr    = {s_rid, s_rdata, s_rresp, s_rlast, s_ruser};
    q_mawv  = m_awvalid; q_mawr  = m_awready;
    q_maw   = {m_awid, m_awaddr, m_awlen, m_awsize, m_awburst, m_awlock,
               m_awcache, m_awprot, m_awqos, m_awregion, m_awatop, m_awuser};
    q_mwv   = m_wvalid;  q_mwr  = m_wready;
    q_mw    = {m_wdata, m_wstrb, m_wlast, m_wuser};
    q_marv  = m_arvalid; q_marr  = m_arready;
    q_mar   = {m_arid, m_araddr, m_arlen, m_arsize, m_arburst, m_arlock,
               m_arcache, m_arprot, m_arqos, m_arregion, m_aruser};
    q_mbv   = m_bvalid;  q_mbr  = m_bready;
    q_mb    = {m_bid, m_bresp, m_buser};
    q_mrv   = m_rvalid;  q_mrr  = m_rready;
    q_mr    = {m_rid, m_rdata, m_rresp, m_rlast, m_ruser};
  end

  // -------------------------------------------------------------------------
  task automatic flag(input string cl, input string msg);
    err_cnt = err_cnt + 1;
    if (err_cnt <= MAX_ERR)
      $display("[cycle %0d] VIOLATION of clause %s: %s", bfm_cycle, cl, msg);
    if (err_cnt == MAX_ERR) begin
      $display("(too many violations to be worth listing; stopping here)");
      $display("RESULT: FAIL");
      $finish;
    end
  endtask

  // -------------------------------------------------------------------------
  //  Upstream drivers.  Everything is presented at the falling edge and held
  //  unchanged until the handshake is seen at a rising edge -- the source
  //  obligation X3 places on me.
  // -------------------------------------------------------------------------
  always @(posedge clk) begin
    aw_acc <= q_rst && q_sawv && q_sawr;
    w_acc  <= q_rst && q_swv  && q_swr;
    ar_acc <= q_rst && q_sarv && q_sarr;
  end

  always @(negedge clk) begin
    if (!rst_n) begin
      s_awvalid = 1'b0;
      s_wvalid  = 1'b0;
      s_arvalid = 1'b0;
    end else begin
      if (aw_acc) begin void'(awq.pop_front()); s_awvalid = 1'b0; end
      if (!s_awvalid && (awq.size() > 0)) begin
        s_awid     = awq[0].id;     s_awaddr = awq[0].addr;
        s_awlen    = awq[0].len;    s_awsize = awq[0].size;
        s_awburst  = awq[0].burst;  s_awlock = awq[0].lock;
        s_awcache  = awq[0].cache;  s_awprot = awq[0].prot;
        s_awqos    = awq[0].qos;    s_awregion = awq[0].region;
        s_awatop   = awq[0].atop;   s_awuser = awq[0].user;
        s_awvalid  = 1'b1;
      end

      if (w_acc) begin void'(wq.pop_front()); s_wvalid = 1'b0; end
      // A W beat is never offered before the AW it belongs to has been taken,
      // so the beat's owner is always the head of wo_q.
      if (!s_wvalid && (wq.size() > 0) && (int'(wq[0].seq_no) < aw_acc_cnt)) begin
        s_wdata = wq[0].data; s_wstrb = wq[0].strb;
        s_wlast = wq[0].last; s_wuser = wq[0].user;
        s_wvalid = 1'b1;
      end

      if (ar_acc) begin void'(arq.pop_front()); s_arvalid = 1'b0; end
      if (!s_arvalid && (arq.size() > 0)) begin
        s_arid    = arq[0].id;    s_araddr = arq[0].addr;
        s_arlen   = arq[0].len;   s_arsize = arq[0].size;
        s_arburst = arq[0].burst; s_arlock = arq[0].lock;
        s_arcache = arq[0].cache; s_arprot = arq[0].prot;
        s_arqos   = arq[0].qos;   s_arregion = arq[0].region;
        s_aruser  = arq[0].user;
        s_arvalid = 1'b1;
      end
    end
  end

  // ---- response readiness, driven from one process, at the falling edge ---
  int rdy_mode = 0;
  always @(negedge clk) begin
    case (rdy_mode)
      1: begin
        s_bready = ($urandom_range(0, 2) != 0);
        s_rready = ($urandom_range(0, 2) != 0);
      end
      2: begin
        s_bready = ((bfm_cycle % 7) < 2);
        s_rready = ((bfm_cycle % 5) < 2);
      end
      3: begin s_bready = 1'b0; s_rready = 1'b0; end
      default: begin s_bready = 1'b1; s_rready = 1'b1; end
    endcase
  end

  // -------------------------------------------------------------------------
  //  Field comparisons
  // -------------------------------------------------------------------------
  task automatic cmp_maw(input awr_t e);
    if      (m_awid     !== e.id)     flag("P1", $sformatf("forwarded AW addr %08h: awid %0d became %0d",     e.addr, e.id, m_awid));
    else if (m_awaddr   !== e.addr)   flag("P1", $sformatf("forwarded AW addr %08h: awaddr became %08h",      e.addr, m_awaddr));
    else if (m_awlen    !== e.len)    flag("P1", $sformatf("forwarded AW addr %08h: awlen %0d became %0d",    e.addr, e.len, m_awlen));
    else if (m_awsize   !== e.size)   flag("P1", $sformatf("forwarded AW addr %08h: awsize changed",          e.addr));
    else if (m_awburst  !== e.burst)  flag("P1", $sformatf("forwarded AW addr %08h: awburst changed",         e.addr));
    else if (m_awlock   !== e.lock)   flag("P1", $sformatf("forwarded AW addr %08h: awlock changed",          e.addr));
    else if (m_awcache  !== e.cache)  flag("P1", $sformatf("forwarded AW addr %08h: awcache changed",         e.addr));
    else if (m_awprot   !== e.prot)   flag("P1", $sformatf("forwarded AW addr %08h: awprot changed",          e.addr));
    else if (m_awqos    !== e.qos)    flag("P1", $sformatf("forwarded AW addr %08h: awqos changed",           e.addr));
    else if (m_awregion !== e.region) flag("P1", $sformatf("forwarded AW addr %08h: awregion changed",        e.addr));
    else if (m_awuser   !== e.user)   flag("P1", $sformatf("forwarded AW addr %08h: awuser changed",          e.addr));
  endtask

  task automatic cmp_mar(input arr_t e);
    if      (m_arid     !== e.id)     flag("P3", $sformatf("forwarded AR addr %08h: arid %0d became %0d",  e.addr, e.id, m_arid));
    else if (m_araddr   !== e.addr)   flag("P3", $sformatf("forwarded AR addr %08h: araddr became %08h",   e.addr, m_araddr));
    else if (m_arlen    !== e.len)    flag("P3", $sformatf("forwarded AR addr %08h: arlen %0d became %0d", e.addr, e.len, m_arlen));
    else if (m_arsize   !== e.size)   flag("P3", $sformatf("forwarded AR addr %08h: arsize changed",       e.addr));
    else if (m_arburst  !== e.burst)  flag("P3", $sformatf("forwarded AR addr %08h: arburst changed",      e.addr));
    else if (m_arlock   !== e.lock)   flag("P3", $sformatf("forwarded AR addr %08h: arlock changed",       e.addr));
    else if (m_arcache  !== e.cache)  flag("P3", $sformatf("forwarded AR addr %08h: arcache changed",      e.addr));
    else if (m_arprot   !== e.prot)   flag("P3", $sformatf("forwarded AR addr %08h: arprot changed",       e.addr));
    else if (m_arqos    !== e.qos)    flag("P3", $sformatf("forwarded AR addr %08h: arqos changed",        e.addr));
    else if (m_arregion !== e.region) flag("P3", $sformatf("forwarded AR addr %08h: arregion changed",     e.addr));
    else if (m_aruser   !== e.user)   flag("P3", $sformatf("forwarded AR addr %08h: aruser changed",       e.addr));
  endtask

  // -------------------------------------------------------------------------
  //  The monitor.  It reads only the pre-edge snapshot above, so what it sees
  //  is exactly what the design saw on that rising edge.
  // -------------------------------------------------------------------------
  always @(posedge clk) begin
    automatic awr_t eaw;
    automatic arr_t ear;
    automatic wbt_t ew;
    automatic logic [13:0] wo;
    automatic int nd, i, k, hit;
    automatic logic [6:0]  fb;
    automatic logic [39:0] fr;

    if (!q_rst) begin
      // ---- X1 -----------------------------------------------------------
      // Counted rather than edge-triggered, so a single settling cycle at the
      // instant reset is pulled is not mistaken for a design that ignores it.
      if (q_mawv || q_mwv || q_marv || q_sbv || q_srv) rst_hot = rst_hot + 1;
      else                                             rst_hot = 0;
      if (x1_en && (rst_hot == 2))
        flag("X1", "an output valid stays asserted while rst_ni is low");
      p_ok = 1'b0;
    end else begin
      rst_hot = 0;

      // ---- X3: no output valid may be withdrawn or altered before ready ---
      if (p_ok) begin
        if (p_sbv && !p_sbr) begin
          if (!q_sbv)             flag("X3", "s_bvalid_o was withdrawn before s_bready_i was seen");
          else if (q_sb !== p_sb) flag("X3", "the B payload changed while the response was still being offered");
        end
        if (p_srv && !p_srr) begin
          if (!q_srv)             flag("X3", "s_rvalid_o was withdrawn before s_rready_i was seen");
          else if (q_sr !== p_sr) flag("X3", "the R payload changed while the beat was still being offered");
        end
        if (p_mawv && !p_mawr) begin
          if (!q_mawv)              flag("X3", "m_awvalid_o was withdrawn before m_awready_i was seen");
          else if (q_maw !== p_maw) flag("X3", "the AW payload changed while the request was still being offered");
        end
        if (p_mwv && !p_mwr) begin
          if (!q_mwv)             flag("X3", "m_wvalid_o was withdrawn before m_wready_i was seen");
          else if (q_mw !== p_mw) flag("X3", "the W payload changed while the beat was still being offered");
        end
        if (p_marv && !p_marr) begin
          if (!q_marv)              flag("X3", "m_arvalid_o was withdrawn before m_arready_i was seen");
          else if (q_mar !== p_mar) flag("X3", "the AR payload changed while the request was still being offered");
        end
      end

      // ---- X2: nothing owed after reset ----------------------------------
      if (x2_en && (q_mawv || q_mwv || q_marv || q_sbv || q_srv))
        flag("X2", "the unit drives a valid after reset although it was given nothing to do since");

      // ---- F1: atop is cleared on everything that is forwarded -----------
      if (q_mawv && (q_maw[6:1] !== 6'b000000))
        flag("F1", $sformatf("m_awatop_o is %06b while m_awvalid_o is asserted; it must be zero", q_maw[6:1]));

      // ---- W1/W2: the downstream write debt ------------------------------
      nd = debt + ((q_mawv && q_mawr) ? 1 : 0) - ((q_mwv && q_mwr && q_mw[1]) ? 1 : 0);
      if (nd > MAX_WRITE_TXNS)
        flag("W2", $sformatf(
          "downstream write debt reached %0d; MAX_WRITE_TXNS is %0d", nd, MAX_WRITE_TXNS));
      debt = nd;

      if (q_sawv && q_sawr) aw_acc_cnt = aw_acc_cnt + 1;

      if (sb_en) begin
        // ---- slave AW accepted -------------------------------------------
        if (q_sawv && q_sawr) begin
          wo = {(q_saw[6:5] != 2'b00), q_saw[6], q_saw[71:68], q_saw[35:28]};   // C1, C2
          wo_q.push_back(wo);
          if (q_saw[6:5] == 2'b00) begin
            exp_maw.push_back(q_saw);
            n_forward = n_forward + 1;
          end else begin
            n_filtered = n_filtered + 1;
          end
        end

        // ---- slave W accepted --------------------------------------------
        if (q_swv && q_swr) begin
          if (wo_q.size() == 0) begin
            flag("TB", "a W beat was accepted before its AW -- testbench bug, not a design fault");
          end else begin
            if (!wo_q[0][13]) begin           // forwarded write: expect it downstream
              ew = {q_sw[37:6], q_sw[5:2], q_sw[1], q_sw[0], 16'd0};
              exp_mw.push_back(ew);
            end
            if (q_sw[1]) begin                // WLAST
              if (wo_q[0][13]) begin          // F3/F4: this write now owes responses
                pend_id.push_back(int'(wo_q[0][11:8]));
                pend_rleft.push_back(wo_q[0][12] ? (int'(wo_q[0][7:0]) + 1) : 0);
                pend_bpend.push_back(1);
                pend_t0.push_back(bfm_cycle);
                pend_clean.push_back((q_sbr && q_srr) ? 1 : 0);
              end
              void'(wo_q.pop_front());
            end
          end
        end

        // ---- slave AR accepted -------------------------------------------
        if (q_sarv && q_sarr) begin
          exp_mar.push_back(q_sar);
          n_reads = n_reads + 1;
        end

        // ---- master AW forwarded ------------------------------------------
        if (q_mawv && q_mawr) begin
          // Every AW carries a unique address, so an AW that arrives out of
          // turn can be told from a corrupted one: if this AW is further down
          // the expected queue, the ones ahead of it were dropped, and a write
          // whose awatop[5:4] is 00 must never be dropped (C1).
          hit = -1;
          for (i = 0; i < exp_maw.size(); i++)
            if ((hit < 0) && (exp_maw[i].addr === q_maw[67:36])) hit = i;
          if (hit < 0) begin
            flag("F1", $sformatf(
              "an AW (addr %08h, id %0d) reached the subordinate that was not owed to it: an atomic write was forwarded",
              q_maw[67:36], q_maw[71:68]));
          end else if (hit > 0) begin
            flag("C1", $sformatf(
              "the AW at addr %08h with awatop %06b was never forwarded, though its awatop[5:4] is 00: only bits [5:4] may make a write atomic",
              exp_maw[0].addr, exp_maw[0].atop));
            for (i = 0; i < hit; i++) void'(exp_maw.pop_front());
            eaw = exp_maw.pop_front();
            cmp_maw(eaw);
          end else begin
            eaw = exp_maw.pop_front();
            cmp_maw(eaw);
          end
        end

        // ---- master W forwarded -------------------------------------------
        if (q_mwv && q_mwr) begin
          if (exp_mw.size() == 0)
            flag("F2", "a W beat reached the subordinate with no forwarded write outstanding: the write data of a filtered write was not absorbed");
          else begin
            ew = exp_mw.pop_front();
            if      (q_mw[37:6] !== ew.data) flag("P2", $sformatf("forwarded W beat: wdata %08h became %08h", ew.data, q_mw[37:6]));
            else if (q_mw[5:2]  !== ew.strb) flag("P2", $sformatf("forwarded W beat: wstrb %04b became %04b", ew.strb, q_mw[5:2]));
            else if (q_mw[1]    !== ew.last) flag("P2", $sformatf("forwarded W beat: wlast %0b became %0b, so the burst boundary moved", ew.last, q_mw[1]));
            else if (q_mw[0]    !== ew.user) flag("P2", "forwarded W beat: wuser changed");
          end
        end

        // ---- master AR forwarded ------------------------------------------
        if (q_marv && q_marr) begin
          if (exp_mar.size() == 0)
            flag("P3", $sformatf("an AR (addr %08h) reached the subordinate with no read outstanding", q_mar[61:30]));
          else begin
            ear = exp_mar.pop_front();
            cmp_mar(ear);
          end
        end

        // ---- responses arriving from the subordinate ----------------------
        if (q_mbv && q_mbr) fb_q.push_back(q_mb);
        if (q_mrv && q_mrr) fr_q.push_back(q_mr);

        // ---- B returned upstream ------------------------------------------
        if (q_sbv && q_sbr) begin
          hit = -1;
          for (i = 0; i < pend_id.size(); i++)
            if ((hit < 0) && (pend_bpend[i] == 1) && (pend_id[i] == int'(q_sb[6:3]))) hit = i;
          if (hit >= 0) begin
            if (q_sb[2:1] !== 2'b10)
              flag("F3", $sformatf(
                "the B for filtered write id %0d has bresp %02b; it must be SLVERR (2'b10)", q_sb[6:3], q_sb[2:1]));
            pend_bpend[hit] = 0;
          end else begin
            hit = -1;
            for (i = 0; i < fb_q.size(); i++)
              if ((hit < 0) && (fb_q[i][6:3] === q_sb[6:3])) hit = i;
            if (hit >= 0) begin
              fb = fb_q[hit];
              if (q_sb[2:1] !== fb[2:1])
                flag("P4", $sformatf("B for id %0d: bresp %02b from the subordinate became %02b", q_sb[6:3], fb[2:1], q_sb[2:1]));
              else if (q_sb[0] !== fb[0])
                flag("P4", $sformatf("B for id %0d: buser changed", q_sb[6:3]));
              fb_q.delete(hit);
            end else begin
              flag("F3", $sformatf(
                "a B response with id %0d was returned that nothing was owed: either a filtered write answered more than once, or a response was invented",
                q_sb[6:3]));
            end
          end
        end

        // ---- R returned upstream ------------------------------------------
        if (q_srv && q_srr) begin
          hit = -1;
          for (i = 0; i < pend_id.size(); i++)
            if ((hit < 0) && (pend_rleft[i] > 0) && (pend_id[i] == int'(q_sr[39:36]))) hit = i;
          if (hit >= 0) begin
            if (q_sr[3:2] !== 2'b10)
              flag("F4", $sformatf(
                "a manufactured R beat for filtered write id %0d has rresp %02b; it must be SLVERR (2'b10)", q_sr[39:36], q_sr[3:2]));
            else if (q_sr[1] !== ((pend_rleft[hit] == 1) ? 1'b1 : 1'b0))
              flag("F4", $sformatf(
                "filtered write id %0d: rlast is %0b on the beat with %0d of the burst still to come",
                q_sr[39:36], q_sr[1], pend_rleft[hit] - 1));
            pend_rleft[hit] = pend_rleft[hit] - 1;
          end else begin
            hit = -1;
            for (i = 0; i < fr_q.size(); i++)
              if ((hit < 0) && (fr_q[i][39:36] === q_sr[39:36])) hit = i;
            if (hit >= 0) begin
              fr = fr_q[hit];
              if      (q_sr[35:4] !== fr[35:4]) flag("P3", $sformatf("R beat for id %0d: rdata %08h became %08h", q_sr[39:36], fr[35:4], q_sr[35:4]));
              else if (q_sr[3:2]  !== fr[3:2])  flag("P3", $sformatf("R beat for id %0d: rresp changed", q_sr[39:36]));
              else if (q_sr[1]    !== fr[1])    flag("P3", $sformatf("R beat for id %0d: rlast changed, so the read burst boundary moved", q_sr[39:36]));
              else if (q_sr[0]    !== fr[0])    flag("P3", $sformatf("R beat for id %0d: ruser changed", q_sr[39:36]));
              fr_q.delete(hit);
            end else begin
              flag("F5", $sformatf(
                "an R beat with id %0d was returned that nothing was owed: a filtered write that owes no read response produced one, or too many beats were produced",
                q_sr[39:36]));
            end
          end
        end

        // ---- retire finished filtered writes, and time them (X4) ----------
        for (i = 0; i < pend_id.size(); i++)
          if (!(q_sbr && q_srr)) pend_clean[i] = 0;
        k = 0;
        while (k < pend_id.size()) begin
          if ((pend_bpend[k] == 0) && (pend_rleft[k] == 0)) begin
            if ((pend_clean[k] == 1) && ((bfm_cycle - pend_t0[k]) > 64))
              flag("X4", $sformatf(
                "the responses for the filtered write with id %0d took %0d cycles after its WLAST, with both readies held high; the bound is 64",
                pend_id[k], bfm_cycle - pend_t0[k]));
            pend_id.delete(k); pend_rleft.delete(k); pend_bpend.delete(k);
            pend_t0.delete(k); pend_clean.delete(k);
          end else begin
            k = k + 1;
          end
        end
      end

      // ---- keep this cycle for the next X3 comparison --------------------
      p_sbv = q_sbv;   p_sbr = q_sbr;   p_sb  = q_sb;
      p_srv = q_srv;   p_srr = q_srr;   p_sr  = q_sr;
      p_mawv = q_mawv; p_mawr = q_mawr; p_maw = q_maw;
      p_mwv = q_mwv;   p_mwr = q_mwr;   p_mw  = q_mw;
      p_marv = q_marv; p_marr = q_marr; p_mar = q_mar;
      p_ok = 1'b1;
    end
  end

  // =========================================================================
  //  Stimulus
  // =========================================================================
  int next_seq = 0;
  int next_ar  = 0;

  task automatic gen_aw(input logic [3:0] id, input logic [7:0] len,
                        input logic [5:0] atop, output int seq_no);
    awr_t r;
    r.id     = id;
    r.addr   = 32'h1000_0000 + (32'(next_seq) << 6);
    r.len    = len;
    r.size   = 3'($urandom_range(0, 2));
    r.burst  = 2'($urandom_range(0, 1));
    r.lock   = 1'($urandom_range(0, 1));
    r.cache  = 4'($urandom_range(0, 15));
    r.prot   = 3'($urandom_range(0, 7));
    r.qos    = 4'($urandom_range(0, 15));
    r.region = 4'($urandom_range(0, 15));
    r.atop   = atop;
    r.user   = 1'($urandom_range(0, 1));
    seq_no   = next_seq;
    next_seq = next_seq + 1;
    awq.push_back(r);
  endtask

  task automatic gen_w(input int seq_no, input logic [7:0] len);
    wbt_t b;
    int i;
    for (i = 0; i <= int'(len); i++) begin
      b.data   = $urandom();
      b.strb   = 4'($urandom_range(0, 15));
      b.last   = (i == int'(len));
      b.user   = 1'($urandom_range(0, 1));
      b.seq_no = 16'(seq_no);
      wq.push_back(b);
    end
  endtask

  task automatic gen_write(input logic [3:0] id, input logic [7:0] len, input logic [5:0] atop);
    int seq_no;
    gen_aw(id, len, atop, seq_no);
    gen_w(seq_no, len);
  endtask

  task automatic gen_read(input logic [3:0] id, input logic [7:0] len);
    arr_t r;
    r.id     = id;
    r.addr   = 32'h2000_0000 + (32'(next_ar) << 6);
    r.len    = len;
    r.size   = 3'($urandom_range(0, 2));
    r.burst  = 2'($urandom_range(0, 1));
    r.lock   = 1'($urandom_range(0, 1));
    r.cache  = 4'($urandom_range(0, 15));
    r.prot   = 3'($urandom_range(0, 7));
    r.qos    = 4'($urandom_range(0, 15));
    r.region = 4'($urandom_range(0, 15));
    r.user   = 1'($urandom_range(0, 1));
    next_ar  = next_ar + 1;
    arq.push_back(r);
  endtask

  function automatic bit all_quiet();
    return (awq.size() == 0) && (wq.size() == 0) && (arq.size() == 0) &&
           (exp_maw.size() == 0) && (exp_mw.size() == 0) && (exp_mar.size() == 0) &&
           (fb_q.size() == 0) && (fr_q.size() == 0) &&
           (wo_q.size() == 0) && (pend_id.size() == 0) &&
           (bfm_bq_id.size() == 0) && (bfm_rq_id.size() == 0) &&
           !s_awvalid && !s_wvalid && !s_arvalid;
  endfunction

  task automatic settle(input int max_cycles, input string ctx_id);
    int t;
    t = 0;
    while (t < max_cycles) begin
      @(posedge clk);
      t = t + 1;
      if (all_quiet()) begin
        repeat (3) @(posedge clk);
        return;
      end
    end
    if ((n_forward + n_filtered + n_reads) == 0)
      flag("X4", $sformatf(
        "%s: the unit accepted nothing at all in %0d cycles; it makes no forward progress in either direction",
        ctx_id, max_cycles));
    else if (s_awvalid && (wo_q.size() == 0) && (debt < MAX_WRITE_TXNS) && (pend_id.size() == 0))
      flag((n_filtered > 0) ? "W5" : "W3", $sformatf(
        "%s: an AW has been offered with nothing in flight and a downstream write debt of only %0d, and it is still not accepted. %0d atomic writes have been filtered; a filtered write forwards neither an AW nor a W beat and so must not consume any of the outstanding-write bound",
        ctx_id, debt, n_filtered));
    else
      flag("X4", $sformatf(
        "%s: traffic had not drained after %0d cycles (aw=%0d w=%0d exp_aw=%0d exp_w=%0d pend=%0d b=%0d r=%0d debt=%0d)",
        ctx_id, max_cycles, awq.size(), wq.size(), exp_maw.size(), exp_mw.size(),
        pend_id.size(), fb_q.size(), fr_q.size(), debt));
  endtask

  task automatic wait_debt(input int want, input int max_cycles,
                           input string cl, input string msg);
    int t;
    t = 0;
    while (t < max_cycles) begin
      @(posedge clk);
      t = t + 1;
      if (debt == want) return;
    end
    flag(cl, msg);
  endtask

  // -------------------------------------------------------------------------
  //  The run
  // -------------------------------------------------------------------------
  initial begin
    int i, j, seq_no;
    logic [5:0] atv [6];

    // atomic opcodes worth exercising: the low four bits must never matter (C1)
    atv[0] = 6'b01_0000; atv[1] = 6'b01_1010; atv[2] = 6'b10_0000;
    atv[3] = 6'b10_1111; atv[4] = 6'b11_0000; atv[5] = 6'b11_0101;

    rdy_mode = 0;
    bfm_dn_b_lag(0);
    bfm_reset(6);
    repeat (5) @(posedge clk);

    // ---- ordinary writes must be left completely alone (P1, P2, P4) ------
    // atop[3:0] is deliberately non-zero on some of these: C1 says the low
    // bits never make a write atomic.
    for (i = 0; i < 8; i++)
      gen_write(4'(i % 8), 8'(i % 4), (i % 2) ? 6'b00_0000 : 6'b00_1101);
    settle(3000, "ordinary writes");

    // ---- reads are never touched (P3) ------------------------------------
    for (i = 0; i < 6; i++) gen_read(4'(i % 8), 8'(i % 4));
    settle(3000, "reads");

    // ---- filtered writes, one at a time (C1, C2, F1..F5) -----------------
    for (i = 0; i < 6; i++) begin
      for (j = 0; j < 3; j++) begin
        gen_write(4'(8 + (i % 8)), (j == 2) ? 8'd3 : 8'(j), atv[i]);
        settle(3000, "single filtered write");
      end
    end

    // ---- several filtered writes back to back (F3: exactly one B each) ---
    for (i = 0; i < 6; i++) gen_write(4'(8 + i), 8'(i % 4), atv[i]);
    settle(4000, "back-to-back filtered writes");

    // ---- filtered and ordinary writes interleaved, reads alongside -------
    for (i = 0; i < 12; i++) begin
      if (i % 3 == 0) gen_write(4'(8 + (i % 8)), 8'(i % 4), atv[i % 6]);
      else            gen_write(4'(i % 8), 8'(i % 3), (i % 2) ? 6'b00_0000 : 6'b00_0111);
      if (i % 4 == 0) gen_read(4'(i % 8), 8'(i % 3));
    end
    settle(6000, "mixed traffic");

    // ---- W2/W3: the bound is exactly four --------------------------------
    // Four AWs with their write data held back.  Nothing downstream can
    // retire, so the debt climbs to and must stop at MAX_WRITE_TXNS.
    bfm_dn_b_lag(400);            // no B may arrive during this experiment
    for (i = 0; i < 4; i++) gen_aw(4'(i), 8'd1, 6'b00_0000, seq_no);
    wait_debt(4, 400, "W3",
      "only reached a downstream write debt below 4 with four AWs offered and no write data supplied; the bound alone must not stall an AW while the debt is under MAX_WRITE_TXNS");
    // A fifth. It may or may not be taken upstream (L4), but it must not
    // reach the subordinate: the W2 monitor is watching the debt.
    gen_aw(4'd5, 8'd1, 6'b00_0000, seq_no);
    repeat (120) @(posedge clk);
    // Now supply all five bursts.  As each completes downstream the debt
    // falls, and the fifth AW must then go -- with no B having arrived yet,
    // which is what separates W4 from a design that counts B responses.
    for (i = 0; i < 5; i++) gen_w(next_seq - 5 + i, 8'd1);
    wait_debt(0, 600, "W4",
      "the downstream write debt never returned to zero even though every write burst completed on the master port and no B response had yet arrived; the debt must be retired by WLAST, not by B");
    bfm_dn_b_lag(0);
    settle(4000, "write-bound experiment");

    // ---- W5: a filtered write must not consume any of the bound ----------
    bfm_dn_b_lag(400);
    gen_write(4'd9, 8'd1, 6'b10_0000);       // filtered, absorbed entirely
    settle(2000, "filtered write before the bound test");
    for (i = 0; i < 4; i++) gen_aw(4'(i), 8'd0, 6'b00_0000, seq_no);
    wait_debt(4, 400, "W5",
      "after a filtered write, four ordinary AWs could not all reach the subordinate: the filtered write was counted against the outstanding-write bound, but it forwards neither an AW nor any W beat");
    for (i = 0; i < 4; i++) gen_w(next_seq - 4 + i, 8'd0);
    bfm_dn_b_lag(0);
    settle(4000, "W5 experiment");

    // ---- backpressure on both response channels (X3, and F3/F4 again) ----
    rdy_mode = 2;
    for (i = 0; i < 14; i++) begin
      if (i % 2 == 0) gen_write(4'(8 + (i % 8)), 8'(i % 4), atv[i % 6]);
      else            gen_write(4'(i % 8), 8'(i % 3), 6'b00_0000);
      if (i % 5 == 0) gen_read(4'(i % 8), 8'(i % 4));
    end
    settle(8000, "backpressured traffic");

    rdy_mode = 1;
    for (i = 0; i < 14; i++) begin
      if (i % 3 == 1) gen_write(4'(8 + (i % 8)), 8'(i % 4), atv[i % 6]);
      else            gen_write(4'(i % 8), 8'(i % 4), 6'b00_1001);
      if (i % 4 == 2) gen_read(4'(i % 8), 8'(i % 3));
    end
    settle(8000, "randomly backpressured traffic");
    rdy_mode = 0;

    // ---- X1 / X2: reset with work in flight ------------------------------
    // A filtered write is left half-fed and ordinary writes are left owing
    // responses, then reset lands on top of all of it.
    sb_en = 1'b0;
    bfm_dn_b_lag(400);
    rdy_mode = 3;                       // both response channels shut
    gen_write(4'd12, 8'd3, 6'b11_0000); // filtered: owes a B and four R beats
    gen_write(4'd1,  8'd3, 6'b00_0000);
    repeat (40) @(posedge clk);
    // the manufactured responses are now up and stalled, which is the state a
    // reset has to clear
    if (!s_bvalid && !s_rvalid)
      $display("[cycle %0d] note: no response was outstanding when reset was applied", bfm_cycle);
    @(negedge clk);
    x1_en = 1'b1;
    awq.delete(); wq.delete(); arq.delete();
    bfm_reset(6);
    @(negedge clk);
    x1_en = 1'b0;
    rdy_mode = 0;
    x2_en = 1'b1;
    repeat (40) @(posedge clk);
    @(negedge clk);
    x2_en = 1'b0;

    // scrub every model of the world; X2 says the unit holds nothing either
    exp_maw.delete(); exp_mw.delete(); exp_mar.delete();
    fb_q.delete(); fr_q.delete(); wo_q.delete();
    pend_id.delete(); pend_rleft.delete(); pend_bpend.delete();
    pend_t0.delete(); pend_clean.delete();
    debt = 0; aw_acc_cnt = 0; next_seq = 0;
    bfm_dn_b_lag(0);
    sb_en = 1'b1;

    // ---- and it must still work afterwards -------------------------------
    for (i = 0; i < 10; i++) begin
      if (i % 2 == 0) gen_write(4'(8 + (i % 8)), 8'(i % 4), atv[i % 6]);
      else            gen_write(4'(i % 8), 8'(i % 3), 6'b00_0000);
      if (i % 3 == 0) gen_read(4'(i % 8), 8'(i % 3));
    end
    settle(6000, "traffic after reset");

    // ---- verdict ----------------------------------------------------------
    if (n_filtered < 20)
      flag("F3", $sformatf("only %0d atomic writes were ever accepted", n_filtered));
    if (n_forward < 20)
      flag("P1", $sformatf("only %0d ordinary writes were ever accepted", n_forward));
    if (n_reads < 5)
      flag("P3", $sformatf("only %0d reads were ever accepted", n_reads));

    $display("--- %0d ordinary writes, %0d atomic writes, %0d reads, %0d violations ---",
             n_forward, n_filtered, n_reads, err_cnt);
    if (err_cnt == 0) $display("RESULT: PASS");
    else              $display("RESULT: FAIL");
    $finish;
  end

endmodule