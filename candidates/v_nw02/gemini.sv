module atop_filter_tb;
// ---------------------------------------------------------------------------
// PROVIDED PLUMBING -- moves transactions, checks nothing.
// ---------------------------------------------------------------------------
// This exists so you spend your effort on checking rather than on AXI
// handshake mechanics. It has been compiled and run against a correct design.
//
// What it does: generates the clock, sequences reset, connects the design,
// offers one beat at a time on a chosen channel and returns once that beat has
// transferred, and plays the part of the subordinate on the master port --
// accepting requests and answering them.
//
// What it does NOT do: it has no notion of which writes are special, keeps no
// model of what the design owes anyone, counts nothing, and draws no conclusion
// from any signal. Every check is yours to write.
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
    m_bresp  = 2'b00;
    m_buser  = 1'b0;
    m_rvalid = (bfm_rq_id.size() > 0);
    m_rid    = 4'(bfm_rq_id.size() ? bfm_rq_id[0] : 0);
    m_rdata  = 32'hFEED_0000 + 32'(bfm_rq_n.size() ? bfm_rq_n[0] : 0);
    m_rresp  = 2'b00;
    m_ruser  = 1'b0;
    m_rlast  = (bfm_rq_id.size() > 0) && (bfm_rq_n[0] <= 1);
  end

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

  initial begin
    #4_000_000;
    $display("RESULT: FAIL (watchdog: no forward progress)");
    $finish;
  end

  // ---------------------------------------------------------------------------
  // VERIFICATION CODE
  // ---------------------------------------------------------------------------

  typedef struct {
    logic [3:0] id; logic [31:0] addr; logic [7:0] len; logic [2:0] size;
    logic [1:0] burst; logic lock; logic [3:0] cache; logic [2:0] prot;
    logic [3:0] qos; logic [3:0] region; logic [5:0] atop; logic user;
  } aw_tx_t;

  typedef struct {
    logic [31:0] data; logic [3:0] strb; logic last; logic user;
  } w_tx_t;

  typedef struct {
    logic [3:0] id; logic [31:0] addr; logic [7:0] len; logic [2:0] size;
    logic [1:0] burst; logic lock; logic [3:0] cache; logic [2:0] prot;
    logic [3:0] qos; logic [3:0] region; logic user;
  } ar_tx_t;

  typedef struct {
    logic [3:0] id; logic [1:0] resp; logic user;
  } b_tx_t;

  typedef struct {
    logic [3:0] id; logic [31:0] data; logic [1:0] resp; logic last; logic user;
  } r_tx_t;

  aw_tx_t expected_m_aw[$];
  bit     m_aw_is_atomic[$];
  w_tx_t  expected_m_w[$];
  ar_tx_t expected_m_ar[$];
  b_tx_t  expected_s_b[$];
  r_tx_t  expected_s_r[$];

  int owed_b_err[16];
  int owed_r_err[16];
  int downstream_debt = 0;

  bit x3_m_awvalid, x3_m_wvalid, x3_m_arvalid, x3_s_bvalid, x3_s_rvalid;

  task automatic report_fail(string msg);
    $display("RESULT: FAIL (%s)", msg);
    $finish;
  endtask

  function automatic bit owed_b_err_all_zero();
    for(int i=0; i<16; i++) if(owed_b_err[i] > 0) return 0;
    return 1;
  endfunction

  function automatic bit owed_r_err_all_zero();
    for(int i=0; i<16; i++) if(owed_r_err[i] > 0) return 0;
    return 1;
  endfunction

  task automatic wait_for_idle();
    int timeout = 1000;
    while (timeout > 0) begin
      if (expected_m_aw.size() == 0 && expected_m_w.size() == 0 &&
          expected_m_ar.size() == 0 && expected_s_b.size() == 0 &&
          expected_s_r.size() == 0 &&
          owed_b_err_all_zero() && owed_r_err_all_zero())
        return;
      @(posedge clk);
      timeout--;
    end
    report_fail("wait_for_idle timeout");
  endtask

  task automatic wait_for_responses(input int id, input int timeout);
    int t = 0;
    while (owed_b_err[id] > 0 || owed_r_err[id] > 0) begin
      @(posedge clk);
      t++;
      if (t > timeout) report_fail("X4: response not completed within timeout");
    end
  endtask

  always @(posedge clk) begin
    if (!rst_n) begin
      expected_m_aw.delete();
      m_aw_is_atomic.delete();
      expected_m_w.delete();
      expected_m_ar.delete();
      expected_s_b.delete();
      expected_s_r.delete();
      for (int i=0; i<16; i++) owed_b_err[i] = 0;
      for (int i=0; i<16; i++) owed_r_err[i] = 0;
      downstream_debt = 0;
      x3_m_awvalid = 0; x3_m_wvalid = 0; x3_m_arvalid = 0;
      x3_s_bvalid = 0; x3_s_rvalid = 0;

      if (m_awvalid || m_wvalid) report_fail("X1: originates valid during reset");
      if (s_bvalid) report_fail("X1: originates B valid during reset");
      if (s_rvalid) report_fail("X1: originates R valid during reset");
    end else begin
      // X3 checks
      if (x3_m_awvalid && !m_awvalid) report_fail("X3: m_awvalid dropped without ready");
      if (x3_m_wvalid && !m_wvalid) report_fail("X3: m_wvalid dropped without ready");
      if (x3_m_arvalid && !m_arvalid) report_fail("X3: m_arvalid dropped without ready");
      if (x3_s_bvalid && !s_bvalid) report_fail("X3: s_bvalid dropped without ready");
      if (x3_s_rvalid && !s_rvalid) report_fail("X3: s_rvalid dropped without ready");

      x3_m_awvalid = m_awvalid && !m_awready;
      x3_m_wvalid  = m_wvalid && !m_wready;
      x3_m_arvalid = m_arvalid && !m_arready;
      x3_s_bvalid  = s_bvalid && !s_bready;
      x3_s_rvalid  = s_rvalid && !s_rready;

      // W Bound Checking
      begin
        automatic int next_debt = downstream_debt;
        if (m_awvalid && m_awready) next_debt++;
        if (m_wvalid && m_wready && m_wlast) next_debt--;
        downstream_debt = next_debt;
        
        if (downstream_debt > 4) report_fail("W2: downstream write debt exceeded 4");
        if (downstream_debt == 4 && !(m_wvalid && m_wready && m_wlast)) begin
          if (m_awvalid) report_fail("W2: m_awvalid asserted while debt is 4 and not completing W");
        end
      end

      // AW Scoreboard Tracking
      if (s_awvalid && s_awready) begin
        automatic bit is_atomic = (s_awatop[5:4] != 2'b00);
        m_aw_is_atomic.push_back(is_atomic);
        if (!is_atomic) begin
          automatic aw_tx_t tx;
          tx.id = s_awid; tx.addr = s_awaddr; tx.len = s_awlen; tx.size = s_awsize;
          tx.burst = s_awburst; tx.lock = s_awlock; tx.cache = s_awcache; tx.prot = s_awprot;
          tx.qos = s_awqos; tx.region = s_awregion; tx.atop = s_awatop; tx.user = s_awuser;
          expected_m_aw.push_back(tx);
        end else begin
          owed_b_err[s_awid]++;
          if (s_awatop[5] == 1'b1) owed_r_err[s_awid] += (int'(s_awlen) + 1);
        end
      end

      if (m_awvalid && m_awready) begin
        if (expected_m_aw.size() == 0) report_fail("P1: m_awvalid high but no non-atomic AW expected");
        else begin
          automatic aw_tx_t exp = expected_m_aw.pop_front();
          if (m_awid !== exp.id || m_awaddr !== exp.addr || m_awlen !== exp.len ||
              m_awsize !== exp.size || m_awburst !== exp.burst || m_awlock !== exp.lock ||
              m_awcache !== exp.cache || m_awprot !== exp.prot || m_awqos !== exp.qos ||
              m_awregion !== exp.region || m_awuser !== exp.user) begin
            report_fail("P1: forwarded AW fields do not match");
          end
          if (m_awatop !== 6'b000000) report_fail("F1: m_awatop_o != 0");
        end
      end

      // W Scoreboard Tracking
      if (s_wvalid && s_wready) begin
        if (m_aw_is_atomic.size() == 0) report_fail("W beat arrived but no AW was sent");
        if (!m_aw_is_atomic[0]) begin
          automatic w_tx_t tx;
          tx.data = s_wdata; tx.strb = s_wstrb; tx.last = s_wlast; tx.user = s_wuser;
          expected_m_w.push_back(tx);
        end
        if (s_wlast) void'(m_aw_is_atomic.pop_front());
      end

      if (m_wvalid && m_wready) begin
        if (expected_m_w.size() == 0) report_fail("F2: m_w valid but no forwarded W beat expected");
        else begin
          automatic w_tx_t exp = expected_m_w.pop_front();
          if (m_wdata !== exp.data || m_wstrb !== exp.strb || m_wlast !== exp.last || m_wuser !== exp.user)
            report_fail("P2: forwarded W fields do not match");
        end
      end

      // AR Scoreboard Tracking
      if (s_arvalid && s_arready) begin
        automatic ar_tx_t tx;
        tx.id = s_arid; tx.addr = s_araddr; tx.len = s_arlen; tx.size = s_arsize;
        tx.burst = s_arburst; tx.lock = s_arlock; tx.cache = s_arcache; tx.prot = s_arprot;
        tx.qos = s_arqos; tx.region = s_arregion; tx.user = s_aruser;
        expected_m_ar.push_back(tx);
      end

      if (m_arvalid && m_arready) begin
        if (expected_m_ar.size() == 0) report_fail("P3: Spurious m_arvalid");
        else begin
          automatic ar_tx_t exp = expected_m_ar.pop_front();
          if (m_arid !== exp.id || m_araddr !== exp.addr || m_arlen !== exp.len ||
              m_arsize !== exp.size || m_arburst !== exp.burst || m_arlock !== exp.lock ||
              m_arcache !== exp.cache || m_arprot !== exp.prot || m_arqos !== exp.qos ||
              m_arregion !== exp.region || m_aruser !== exp.user)
            report_fail("P3: forwarded AR fields do not match");
        end
      end

      // Response Tracking (Downstream -> Upstream)
      if (m_bvalid && m_bready) begin
        automatic b_tx_t tx;
        tx.id = m_bid; tx.resp = m_bresp; tx.user = m_buser;
        expected_s_b.push_back(tx);
      end

      if (m_rvalid && m_rready) begin
        automatic r_tx_t tx;
        tx.id = m_rid; tx.data = m_rdata; tx.resp = m_rresp; tx.last = m_rlast; tx.user = m_ruser;
        expected_s_r.push_back(tx);
      end

      if (s_bvalid && s_bready) begin
        if (s_bresp == 2'b10) begin
          if (owed_b_err[s_bid] > 0) owed_b_err[s_bid]--;
          else report_fail("F3: Spurious manufactured B response");
        end else begin
          if (expected_s_b.size() == 0) report_fail("P4: Spurious pass-through B response");
          else begin
            automatic b_tx_t exp = expected_s_b.pop_front();
            if (s_bid !== exp.id || s_bresp !== exp.resp || s_buser !== exp.user)
              report_fail("P4: forwarded B fields do not match");
          end
        end
      end

      if (s_rvalid && s_rready) begin
        if (s_rresp == 2'b10) begin
          if (owed_r_err[s_rid] > 0) begin
            owed_r_err[s_rid]--;
            if (owed_r_err[s_rid] == 0 && !s_rlast) report_fail("F4: s_rlast_o not asserted on final manufactured R beat");
            if (owed_r_err[s_rid] > 0 && s_rlast) report_fail("F4: s_rlast_o asserted early on manufactured R beat");
          end else begin
            report_fail("F4/F5: Spurious manufactured R response");
          end
        end else begin
          if (expected_s_r.size() == 0) report_fail("P3: Spurious pass-through R response");
          else begin
            automatic r_tx_t exp = expected_s_r.pop_front();
            if (s_rid !== exp.id || s_rdata !== exp.data || s_rresp !== exp.resp ||
                s_rlast !== exp.last || s_ruser !== exp.user)
              report_fail("P3: forwarded R fields do not match");
          end
        end
      end
    end
  end

  // ---- Test Sequence -------------------------------------------------------
  initial begin
    automatic bit acc;
    
    bfm_reset(5);
    
    // Set a moderate lag for B responses so they appear naturally after W beats finish
    bfm_dn_b_lag(100);

    // 1. Pass-through test
    bfm_aw(1, 32'h1000, 0, 6'b000000, 64, acc);
    if (!acc) report_fail("X4: Non-atomic AW not accepted");
    bfm_w(32'hAABB, 4'hF, 1, 64, acc);
    if (!acc) report_fail("X4: Non-atomic W not accepted");
    wait_for_idle();

    // 2. Filtered test C2=0
    bfm_aw(2, 32'h2000, 0, 6'b010000, 64, acc);
    if (!acc) report_fail("X4: Atomic AW not accepted");
    bfm_w(32'h1122, 4'hF, 1, 64, acc);
    if (!acc) report_fail("X4: Atomic W not consumed");
    wait_for_responses(2, 64);

    // 3. Filtered test C2=1
    bfm_aw(3, 32'h3000, 0, 6'b100000, 64, acc);
    bfm_w(32'h3344, 4'hF, 1, 64, acc);
    wait_for_responses(3, 64);

    // 4. Test AR pass-through
    bfm_ar(4, 32'h4000, 0, 64, acc);
    wait_for_idle();

    // 5. Debt Bound W2, W3, W4 (requires built-up traffic)
    // Send 4 non-atomic AWs but hold W back
    for (int i=0; i<4; i++) begin
      bfm_aw(4'(5+i), 32'h5000 + 32'(i*4), 0, 6'b000000, 64, acc);
      if (!acc) report_fail("W3: AW stalled when debt < 4");
    end
    
    // Attempt 5th AW -> expected to stall
    bfm_aw(9, 32'h6000, 0, 6'b000000, 10, acc);
    if (acc) report_fail("W2: 5th AW accepted while debt is 4 and no W last");

    // Complete 1 W burst -> debt goes from 4 to 3
    bfm_w(32'hDEAD, 4'hF, 1, 64, acc);
    if (!acc) report_fail("X4: W beat not accepted when debt=4");

    // 5th AW should now be accepted
    bfm_aw(9, 32'h6000, 0, 6'b000000, 64, acc);
    if (!acc) report_fail("W4: 5th AW not accepted after W burst completion");

    // Clear the remaining 4 W bursts
    for (int i=0; i<4; i++) begin
      bfm_w(32'hBEEF, 4'hF, 1, 64, acc);
    end
    wait_for_idle();

    // 6. Test Burst length > 0 (Atomic)
    bfm_aw(10, 32'h7000, 3, 6'b110000, 64, acc);
    if (!acc) report_fail("X4: Atomic AW not accepted");
    bfm_w(32'h1, 4'hF, 0, 64, acc);
    bfm_w(32'h2, 4'hF, 0, 64, acc);
    bfm_w(32'h3, 4'hF, 0, 64, acc);
    bfm_w(32'h4, 4'hF, 1, 64, acc);
    wait_for_responses(10, 64);

    // 7. Test Burst length > 0 (Non-atomic)
    bfm_aw(11, 32'h8000, 2, 6'b000000, 64, acc);
    bfm_w(32'hA, 4'hF, 0, 64, acc);
    bfm_w(32'hB, 4'hF, 0, 64, acc);
    bfm_w(32'hC, 4'hF, 1, 64, acc);
    wait_for_idle();

    // 8. Test C1: ensure [3:0] payload doesn't affect classification
    bfm_aw(12, 32'h9000, 0, 6'b011111, 64, acc);
    bfm_w(32'hD, 4'hF, 1, 64, acc);
    wait_for_responses(12, 64);

    bfm_aw(13, 32'hA000, 0, 6'b001111, 64, acc);
    bfm_w(32'hE, 4'hF, 1, 64, acc);
    wait_for_idle();

    // 9. Back-to-back atomic sequences
    bfm_aw(14, 32'hB000, 0, 6'b100000, 64, acc);
    bfm_w(32'hF, 4'hF, 1, 64, acc);
    bfm_aw(15, 32'hC000, 0, 6'b100000, 64, acc);
    bfm_w(32'h10, 4'hF, 1, 64, acc);
    wait_for_responses(14, 64);
    wait_for_responses(15, 64);

    wait_for_idle();

    $display("RESULT: PASS");
    $finish;
  end
endmodule