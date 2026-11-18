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

  // Asserts reset, holds it, and releases it OFF the sampling edge, so nothing
  // you or the design samples changes in the same timestep as the change.
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

  // Offers ONE write data beat and returns once it has transferred.
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

  // Offers ONE read address and returns once it has transferred.
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

  // Your readiness to take responses. Changed at the negative edge, never at
  // the edge the design samples them on.
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
  // CHECKERS AND STIMULUS
  // ===========================================================================
  // ID space: writes use ids 0..7, reads use ids 8..15.  R beats on the slave
  // port are attributed by rid (F4): rid < 8 can only be a manufactured beat,
  // rid >= 8 can only be a pass-through read beat.

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
  } axf_t;

  typedef struct packed {
    logic [31:0] data;
    logic [3:0]  strb;
    logic        last;
    logic        user;
  } wf_t;

  typedef struct packed {
    logic [3:0]  id;
    logic [1:0]  resp;
    logic        user;
  } bf_t;

  typedef struct packed {
    logic [3:0]  id;
    logic [31:0] data;
    logic [1:0]  resp;
    logic        last;
    logic        user;
  } rf_t;

  typedef struct packed {
    bit          filt;
    logic [3:0]  id;
  } swq_t;

  int  errors   = 0;
  bit  f1_done = 0;
  bit  w2_done = 0;

  task automatic fail(input string clause);
    errors = errors + 1;
    $display("[%0t] VIOLATION of %0s", $time, clause);
  endtask

  // ---- model state ---------------------------------------------------------
  axf_t aw_exp[$];          // AWs that must appear on the master port (P1)
  axf_t ar_exp[$];          // ARs that must appear on the master port (P3)
  wf_t  w_exp[$];           // W beats that must appear on the master port (P2)
  bf_t  mb_q[$];            // Bs taken on the master port, not yet seen below (P4)
  rf_t  mr_q[$];            // R beats taken on the master port (P3)
  swq_t sw_q[$];            // outstanding slave writes, in AW order

  // manufactured-response bookkeeping, indexed by write id (0..7)
  int mfg_b_left[16];       // B beats still owed  (F3)
  int mfg_r_left[16];       // R beats still owed  (F4)
  int mfg_r_len[16];        // awlen of the owing write
  int mfg_r_cnt[16];        // R beats seen so far for the current write
  bit mfg_r_lastok[16];     // rlast seen on the final beat
  bit mfg_active[16];       // a filtered write with responses outstanding
  bit mfg_wlast[16];        // its s_wlast handshake has completed
  int mfg_deadline[16];     // bfm_cycle of wlast + 65   (X4)

  int aw_m_cnt    = 0;      // master-port AW handshakes     (W1)
  int wlast_m_cnt = 0;      // master-port W handshakes with m_wlast (W1)

  function automatic int mfg_pending();
    int s;
    s = 0;
    for (int k = 0; k < 16; k++) s = s + mfg_b_left[k] + mfg_r_left[k];
    return s;
  endfunction

  function automatic bit all_quiet();
    return (aw_exp.size() == 0) && (w_exp.size() == 0) && (ar_exp.size() == 0) &&
           (mb_q.size()  == 0) && (mr_q.size() == 0) && (sw_q.size()   == 0) &&
           (mfg_pending() == 0);
  endfunction

  initial begin
    for (int k = 0; k < 16; k++) begin
      mfg_b_left[k] = 0; mfg_r_left[k] = 0; mfg_r_len[k] = 0; mfg_r_cnt[k] = 0;
      mfg_r_lastok[k] = 0; mfg_active[k] = 0; mfg_wlast[k] = 0; mfg_deadline[k] = 0;
    end
  end

  // ---- X1 / F1: continuous -------------------------------------------------
  always @(posedge clk) begin
    if (!rst_n) begin
      if (m_awvalid) fail("X1 (m_awvalid_o high while rst_ni is low)");
      if (m_wvalid)  fail("X1 (m_wvalid_o high while rst_ni is low)");
      if (s_bvalid)  fail("X1 (response originated while rst_ni is low)");
      if (s_rvalid)  fail("X1 (response originated while rst_ni is low)");
    end
    if (m_awvalid && (m_awatop != 6'd0) && !f1_done) begin
      f1_done = 1;
      fail("F1 (m_awatop_o nonzero while m_awvalid_o is asserted)");
    end
  end

  // ---- X3: valid/payload stability until ready ----------------------------
  logic        x3v_aw, x3r_aw, x3v_w, x3r_w, x3v_ar, x3r_ar;
  logic        x3v_b,  x3r_b,  x3v_r, x3r_r;
  logic [71:0] x3p_aw;
  logic [37:0] x3p_w;
  logic [65:0] x3p_ar;
  logic [6:0]  x3p_b;
  logic [39:0] x3p_r;

  always @(posedge clk) begin
    if (rst_n) begin
      if (x3v_aw && !x3r_aw) begin
        if (!m_awvalid)
          fail("X3 (m_awvalid_o withdrawn before ready)");
        else if ({m_awid,m_awaddr,m_awlen,m_awsize,m_awburst,m_awlock,m_awcache,
                  m_awprot,m_awqos,m_awregion,m_awatop,m_awuser} != x3p_aw)
          fail("X3 (m_aw payload changed before ready)");
      end
      if (x3v_w && !x3r_w) begin
        if (!m_wvalid)
          fail("X3 (m_wvalid_o withdrawn before ready)");
        else if ({m_wdata,m_wstrb,m_wlast,m_wuser} != x3p_w)
          fail("X3 (m_w payload changed before ready)");
      end
      if (x3v_ar && !x3r_ar) begin
        if (!m_arvalid)
          fail("X3 (m_arvalid_o withdrawn before ready)");
        else if ({m_arid,m_araddr,m_arlen,m_arsize,m_arburst,m_arlock,m_arcache,
                  m_arprot,m_arqos,m_arregion,m_aruser} != x3p_ar)
          fail("X3 (m_ar payload changed before ready)");
      end
      if (x3v_b && !x3r_b) begin
        if (!s_bvalid)
          fail("X3 (s_bvalid_o withdrawn before s_bready_i)");
        else if ({s_bid,s_bresp,s_buser} != x3p_b)
          fail("X3 (s_b payload changed before s_bready_i)");
      end
      if (x3v_r && !x3r_r) begin
        if (!s_rvalid)
          fail("X3 (s_rvalid_o withdrawn before s_rready_i)");
        else if ({s_rid,s_rdata,s_rresp,s_rlast,s_ruser} != x3p_r)
          fail("X3 (s_r payload changed before s_rready_i)");
      end
    end
    x3v_aw <= m_awvalid; x3r_aw <= m_awready;
    x3p_aw <= {m_awid,m_awaddr,m_awlen,m_awsize,m_awburst,m_awlock,m_awcache,
               m_awprot,m_awqos,m_awregion,m_awatop,m_awuser};
    x3v_w <= m_wvalid; x3r_w <= m_wready;
    x3p_w <= {m_wdata,m_wstrb,m_wlast,m_wuser};
    x3v_ar <= m_arvalid; x3r_ar <= m_arready;
    x3p_ar <= {m_arid,m_araddr,m_arlen,m_arsize,m_arburst,m_arlock,m_arcache,
               m_arprot,m_arqos,m_arregion,m_aruser};
    x3v_b <= s_bvalid; x3r_b <= s_bready;
    x3p_b <= {s_bid,s_bresp,s_buser};
    x3v_r <= s_rvalid; x3r_r <= s_rready;
    x3p_r <= {s_rid,s_rdata,s_rresp,s_rlast,s_ruser};
  end

  // ---- main monitor --------------------------------------------------------
  axf_t ax_tmp;
  wf_t  w_tmp;
  bf_t  b_tmp;
  rf_t  r_tmp;

  always @(posedge clk) begin : mon
    if (rst_n) begin
      // ---- 1: slave-side requests (build the model) ----
      if (s_awvalid && s_awready) begin
        sw_q.push_back('{(s_awatop[5:4] != 2'b00), s_awid});
        if (s_awatop[5:4] == 2'b00) begin
          aw_exp.push_back('{s_awid, s_awaddr, s_awlen, s_awsize, s_awburst,
                            s_awlock, s_awcache, s_awprot, s_awqos, s_awregion,
                            s_awuser});
        end else begin
          mfg_b_left[s_awid] = 1;
          mfg_active[s_awid] = 1'b1;
          mfg_wlast[s_awid]  = 1'b0;
          if (s_awatop[5]) begin
            mfg_r_left[s_awid]   = int'(s_awlen) + 1;
            mfg_r_len[s_awid]    = int'(s_awlen);
            mfg_r_cnt[s_awid]    = 0;
            mfg_r_lastok[s_awid] = 1'b0;
          end else begin
            mfg_r_left[s_awid] = 0;
          end
        end
      end
      if (s_wvalid && s_wready) begin
        if (sw_q.size() == 0) begin
          fail("P2 (W beat transferred with no outstanding write)");
        end else begin
          if (!sw_q[0].filt)
            w_exp.push_back('{s_wdata, s_wstrb, s_wlast, s_wuser});
          if (s_wlast) begin
            if (sw_q[0].filt) begin
              mfg_wlast[sw_q[0].id]    = 1'b1;
              mfg_deadline[sw_q[0].id] = bfm_cycle + 65;
            end
            void'(sw_q.pop_front());
          end
        end
      end
      if (s_arvalid && s_arready)
        ar_exp.push_back('{s_arid, s_araddr, s_arlen, s_arsize, s_arburst,
                          s_arlock, s_arcache, s_arprot, s_arqos, s_arregion,
                          s_aruser});

      // ---- 2: master-side requests (check the model) ----
      if (m_awvalid && m_awready) begin
        aw_m_cnt = aw_m_cnt + 1;
        if (aw_exp.size() == 0) begin
          fail("F1 (an atomic AW reached the master port)");
        end else begin
          ax_tmp = aw_exp.pop_front();
          if (ax_tmp.id != m_awid || ax_tmp.addr != m_awaddr ||
              ax_tmp.len != m_awlen || ax_tmp.size != m_awsize ||
              ax_tmp.burst != m_awburst || ax_tmp.lock != m_awlock ||
              ax_tmp.cache != m_awcache || ax_tmp.prot != m_awprot ||
              ax_tmp.qos != m_awqos || ax_tmp.region != m_awregion ||
              ax_tmp.user != m_awuser)
            fail("P1 (forwarded AW field modified)");
        end
      end
      if (m_wvalid && m_wready) begin
        if (m_wlast) wlast_m_cnt = wlast_m_cnt + 1;
        if (w_exp.size() == 0) begin
          fail("F2 (W beat of a filtered write reached the master port)");
        end else begin
          w_tmp = w_exp.pop_front();
          if (w_tmp.data != m_wdata || w_tmp.strb != m_wstrb ||
              w_tmp.last != m_wlast || w_tmp.user != m_wuser)
            fail("P2 (forwarded W beat modified)");
        end
      end
      if (m_arvalid && m_arready) begin
        if (ar_exp.size() == 0) begin
          fail("P3 (unexpected AR on the master port)");
        end else begin
          ax_tmp = ar_exp.pop_front();
          if (ax_tmp.id != m_arid || ax_tmp.addr != m_araddr ||
              ax_tmp.len != m_arlen || ax_tmp.size != m_arsize ||
              ax_tmp.burst != m_arburst || ax_tmp.lock != m_arlock ||
              ax_tmp.cache != m_arcache || ax_tmp.prot != m_arprot ||
              ax_tmp.qos != m_arqos || ax_tmp.region != m_arregion ||
              ax_tmp.user != m_aruser)
            fail("P3 (forwarded AR field modified)");
        end
      end
      if ((aw_m_cnt - wlast_m_cnt) > 4 && !w2_done) begin
        w2_done = 1;
        fail("W2 (downstream write debt exceeded MAX_WRITE_TXNS of 4)");
      end

      // ---- 3: master-side responses (record) ----
      if (m_bvalid && m_bready) mb_q.push_back('{m_bid, m_bresp, m_buser});
      if (m_rvalid && m_rready) mr_q.push_back('{m_rid, m_rdata, m_rresp, m_rlast, m_ruser});

      // ---- 4: slave-side responses (check) ----
      if (s_bvalid && s_bready) begin
        if (s_bresp == 2'b10) begin
          if (mfg_b_left[s_bid] > 0) begin
            mfg_b_left[s_bid] = mfg_b_left[s_bid] - 1;
            if (mfg_active[s_bid] && mfg_b_left[s_bid] == 0 &&
                mfg_r_left[s_bid] == 0) begin
              if (mfg_wlast[s_bid] && (bfm_cycle > mfg_deadline[s_bid]))
                fail("X4 (manufactured B response later than 64 cycles)");
              mfg_active[s_bid] = 1'b0;
            end
          end else begin
            fail("F3 (unexpected manufactured B response)");
          end
        end else begin
          if (mb_q.size() == 0) begin
            fail("P4 (unexpected B response on the slave port)");
          end else begin
            b_tmp = mb_q.pop_front();
            if (b_tmp.id != s_bid || b_tmp.resp != s_bresp || b_tmp.user != s_buser)
              fail("P4 (B response modified in pass-through)");
          end
        end
      end
      if (s_rvalid && s_rready) begin
        if (!s_rid[3]) begin
          // write-id space: must be a manufactured beat, attributed by rid (F4)
          if (mfg_r_left[s_rid] > 0) begin
            if (s_rresp != 2'b10)
              fail("F4 (manufactured R beat is not SLVERR)");
            mfg_r_left[s_rid] = mfg_r_left[s_rid] - 1;
            mfg_r_cnt[s_rid]  = mfg_r_cnt[s_rid] + 1;
            if (s_rlast) begin
              if (mfg_r_cnt[s_rid] != (mfg_r_len[s_rid] + 1))
                fail("F4 (s_rlast_o not on the final R beat)");
              mfg_r_lastok[s_rid] = 1'b1;
            end
            if ((mfg_r_cnt[s_rid] == (mfg_r_len[s_rid] + 1)) && !mfg_r_lastok[s_rid])
              fail("F4 (s_rlast_o missing on the final R beat)");
            if (mfg_active[s_rid] && mfg_b_left[s_rid] == 0 &&
                mfg_r_left[s_rid] == 0) begin
              if (mfg_wlast[s_rid] && (bfm_cycle > mfg_deadline[s_rid]))
                fail("X4 (manufactured R response later than 64 cycles)");
              mfg_active[s_rid] = 1'b0;
            end
          end else begin
            fail("F4/F5 (unexpected R beat on the slave port)");
          end
        end else begin
          // read-id space: pass-through read beat
          if (mr_q.size() == 0) begin
            fail("P3 (unexpected R beat on the slave port)");
          end else begin
            r_tmp = mr_q.pop_front();
            if (r_tmp.id != s_rid || r_tmp.data != s_rdata ||
                r_tmp.resp != s_rresp || r_tmp.last != s_rlast ||
                r_tmp.user != s_ruser)
              fail("P3 (R beat modified in pass-through)");
          end
        end
      end
    end
  end

  // ---- drain helper --------------------------------------------------------
  task automatic wait_quiet(input int max_cycles);
    int t;
    for (t = 0; t < max_cycles; t++) begin
      @(negedge clk);
      if (all_quiet()) begin
        repeat (6) @(negedge clk);
        if (all_quiet()) return;
      end
    end
    fail("X4 (liveness: owed traffic did not drain)");
  endtask

  // ---- stimulus ------------------------------------------------------------
  bit acc;
  int i;
  int n_aw;

  initial begin : main_stim
    // =================================================================
    // Reset with traffic offered underneath it (X1, X2)
    // =================================================================
    @(negedge clk);
    rst_n = 1'b0;
    @(negedge clk);
    s_awid = 4'd2; s_awaddr = 32'hDEAD_0000; s_awlen = 8'd1; s_awatop = 6'h20;
    s_awsize = 3'd2; s_awburst = 2'd1; s_awlock = 1'b0; s_awcache = 4'd0;
    s_awprot = 3'd0; s_awqos = 4'd0; s_awregion = 4'd0; s_awuser = 1'b0;
    s_awvalid = 1'b1;
    s_wdata = 32'h1234_5678; s_wstrb = 4'hF; s_wlast = 1'b1; s_wuser = 1'b0;
    s_wvalid = 1'b1;
    s_arid = 4'd9; s_araddr = 32'hDEAD_1000; s_arlen = 8'd0;
    s_arsize = 3'd2; s_arburst = 2'd1; s_arlock = 1'b0; s_arcache = 4'd0;
    s_arprot = 3'd0; s_arqos = 4'd0; s_arregion = 4'd0; s_aruser = 1'b0;
    s_arvalid = 1'b1;
    repeat (6) @(posedge clk);
    @(negedge clk);
    s_awvalid = 1'b0; s_wvalid = 1'b0; s_arvalid = 1'b0;
    repeat (3) @(posedge clk);
    @(negedge clk);
    rst_n = 1'b1;

    repeat (20) @(posedge clk);
    if (s_bvalid || s_rvalid || m_awvalid || m_wvalid || m_arvalid)
      fail("X2 (unit owes a response or holds a transaction after reset)");

    // =================================================================
    // C: basic non-atomic write, 4-beat burst
    // =================================================================
    bfm_aw(4'd0, 32'h0000_1000, 8'd3, 6'h00, 70, acc);
    if (!acc) fail("W3/X4 (non-atomic AW not accepted with debt 0)");
    for (i = 0; i < 4; i++) begin
      bfm_w(32'hA000_0000 + 32'(i), 4'hF, i == 3, 70, acc);
      if (!acc) fail("X4 (W beat not accepted)");
    end
    wait_quiet(400);

    // =================================================================
    // D: atomic without read response (atop[5:4] == 01) -- F2/F3/F5
    // =================================================================
    bfm_aw(4'd1, 32'h0000_2000, 8'd2, 6'h10, 70, acc);
    if (!acc) fail("X4 (filtered AW not accepted)");
    for (i = 0; i < 3; i++) begin
      bfm_w(32'hD000_0000 + 32'(i), 4'hF, i == 2, 70, acc);
      if (!acc) fail("X4 (filtered W beat not consumed, F2)");
    end
    wait_quiet(400);
    repeat (30) @(posedge clk);   // F5: no R beat may ever appear for this id

    // =================================================================
    // E: atomic with read response (atop[5:4] == 10), len 7 -- F4
    // =================================================================
    bfm_aw(4'd2, 32'h0000_3000, 8'd7, 6'h20, 70, acc);
    if (!acc) fail("X4 (filtered AW not accepted)");
    for (i = 0; i < 8; i++) begin
      bfm_w(32'hE000_0000 + 32'(i), 4'hF, i == 7, 70, acc);
      if (!acc) fail("X4 (filtered W beat not consumed, F2)");
    end
    wait_quiet(500);
    if (mfg_r_cnt[2] != 8) fail("F4 (wrong number of manufactured R beats)");

    // =================================================================
    // F: atomic with read response, len 0, atop[5:4] == 11
    // =================================================================
    bfm_aw(4'd3, 32'h0000_3800, 8'd0, 6'h30, 70, acc);
    if (!acc) fail("X4 (filtered AW not accepted)");
    bfm_w(32'hE100_0000, 4'hF, 1'b1, 70, acc);
    if (!acc) fail("X4 (filtered W beat not consumed, F2)");
    wait_quiet(400);
    if (mfg_r_cnt[3] != 1) fail("F4 (wrong number of manufactured R beats)");

    // =================================================================
    // G: classification -- atop[3:0] never affects atomicity (C1)
    // =================================================================
    bfm_aw(4'd4, 32'h0000_4000, 8'd1, 6'h0F, 70, acc);
    if (!acc) fail("W3/X4 (AW with atop[5:4]==00 not accepted)");
    bfm_w(32'hA100_0000, 4'hF, 1'b0, 70, acc);
    if (!acc) fail("X4 (W beat not accepted)");
    bfm_w(32'hA100_0001, 4'hF, 1'b1, 70, acc);
    if (!acc) fail("X4 (W beat not accepted)");
    wait_quiet(400);
    bfm_aw(4'd5, 32'h0000_4800, 8'd1, 6'h3F, 70, acc);
    if (!acc) fail("X4 (filtered AW not accepted)");
    bfm_w(32'hD100_0000, 4'hF, 1'b0, 70, acc);
    if (!acc) fail("X4 (filtered W beat not consumed, F2)");
    bfm_w(32'hD100_0001, 4'hF, 1'b1, 70, acc);
    if (!acc) fail("X4 (filtered W beat not consumed, F2)");
    wait_quiet(500);
    if (mfg_r_cnt[5] != 2) fail("F4 (wrong number of manufactured R beats)");

    // =================================================================
    // H: long non-atomic burst, 8 beats (P2)
    // =================================================================
    bfm_aw(4'd6, 32'h0000_5000, 8'd7, 6'h00, 70, acc);
    if (!acc) fail("W3/X4 (non-atomic AW not accepted)");
    for (i = 0; i < 8; i++) begin
      bfm_w(32'hA200_0000 + 32'(i), 4'hF, i == 7, 70, acc);
      if (!acc) fail("X4 (W beat not accepted)");
    end
    wait_quiet(400);

    // =================================================================
    // I: read pass-through (P3)
    // =================================================================
    bfm_ar(4'd8, 32'hF000_0000, 8'd2, 500, acc);
    if (!acc) fail("P3 (AR never accepted)");
    wait_quiet(400);

    // =================================================================
    // J: the outstanding-write bound (W2/W3/W4)
    // =================================================================
    for (i = 0; i < 4; i++) begin
      bfm_aw(4'(i), 32'h2000_0000 + 32'(i) * 4, 8'd0, 6'h00, 70, acc);
      if (!acc) fail("W3/X4 (non-atomic AW stalled while debt below 4)");
    end
    // wait until all four are downstream: debt == 4
    for (i = 0; i < 200; i++) begin
      @(negedge clk);
      if ((aw_m_cnt - wlast_m_cnt) == 4) break;
    end
    // let the subordinate answer: B responses must NOT reduce the debt (W4)
    repeat (10) @(negedge clk);
    // offer a fifth write; a correct unit must not let the debt pass 4 (W2)
    bfm_aw(4'd4, 32'h2000_0010, 8'd0, 6'h00, 40, acc);
    n_aw = 4 + (acc ? 1 : 0);
    for (i = 0; i < n_aw; i++) begin
      bfm_w(32'hB000_0000 + 32'(i), 4'hF, 1'b1, 70, acc);
      if (!acc) fail("X4 (W beat not accepted)");
    end
    wait_quiet(800);

    // =================================================================
    // K: back-to-back filtered writes owing R beats (F3/F4, L1)
    // =================================================================
    bfm_aw(4'd5, 32'h0000_6000, 8'd1, 6'h20, 70, acc);
    if (!acc) fail("X4 (filtered AW not accepted)");
    bfm_aw(4'd6, 32'h0000_6400, 8'd2, 6'h20, 70, acc);
    if (!acc) fail("X4 (filtered AW not accepted)");
    for (i = 0; i < 2; i++) begin
      bfm_w(32'hD200_0000 + 32'(i), 4'hF, i == 1, 70, acc);
      if (!acc) fail("X4 (filtered W beat not consumed, F2)");
    end
    for (i = 0; i < 3; i++) begin
      bfm_w(32'hD300_0000 + 32'(i), 4'hF, i == 2, 70, acc);
      if (!acc) fail("X4 (filtered W beat not consumed, F2)");
    end
    wait_quiet(600);
    if (mfg_r_cnt[5] != 2 || mfg_r_cnt[6] != 3)
      fail("F4 (wrong R beat counts for back-to-back filtered writes)");

    // =================================================================
    // L: X3 stability of manufactured responses under backpressure
    // =================================================================
    bfm_aw(4'd7, 32'h0000_7000, 8'd3, 6'h20, 70, acc);
    if (!acc) fail("X4 (filtered AW not accepted)");
    for (i = 0; i < 4; i++) begin
      bfm_w(32'hD400_0000 + 32'(i), 4'hF, i == 3, 70, acc);
      if (!acc) fail("X4 (filtered W beat not consumed, F2)");
    end
    bfm_b_ready(0);
    bfm_r_ready(0);
    repeat (15) @(posedge clk);   // responses stall here; X3 is checked above
    bfm_b_ready(1);
    bfm_r_ready(1);
    wait_quiet(600);
    if (mfg_r_cnt[7] != 4) fail("F4 (wrong number of manufactured R beats)");

    // pass-through B under backpressure
    bfm_b_ready(0);
    bfm_aw(4'd0, 32'h0000_7400, 8'd0, 6'h00, 70, acc);
    if (!acc) fail("W3/X4 (non-atomic AW not accepted)");
    bfm_w(32'hA400_0000, 4'hF, 1'b1, 150, acc);
    if (!acc) fail("X4 (W beat not accepted)");
    repeat (12) @(posedge clk);
    bfm_b_ready(1);
    wait_quiet(600);

    // =================================================================
    // M: read interleaved with a filtered write (P3 vs F4)
    // =================================================================
    bfm_ar(4'd9, 32'hF000_1000, 8'd1, 500, acc);
    if (!acc) fail("P3 (AR never accepted)");
    bfm_aw(4'd2, 32'h0000_7800, 8'd0, 6'h21, 70, acc);
    if (!acc) fail("X4 (filtered AW not accepted)");
    bfm_w(32'hD500_0000, 4'hF, 1'b1, 70, acc);
    if (!acc) fail("X4 (filtered W beat not consumed, F2)");
    wait_quiet(600);
    if (mfg_r_cnt[2] != 1) fail("F4 (wrong number of manufactured R beats)");

    // =================================================================
    // final drain and verdict
    // =================================================================
    wait_quiet(800);
    repeat (50) @(posedge clk);
    if (!all_quiet()) fail("X4 (traffic did not drain at end of test)");
    if (aw_m_cnt != wlast_m_cnt)
      fail("W1/W2 (downstream write debt nonzero after all traffic)");

    if (errors == 0) begin
      $display("All checks passed.");
      $display("RESULT: PASS");
    end else begin
      $display("%0d violation(s) detected.", errors);
      $display("RESULT: FAIL");
    end
    $finish;
  end

endmodule
