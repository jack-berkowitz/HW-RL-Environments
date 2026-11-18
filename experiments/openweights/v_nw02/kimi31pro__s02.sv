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

  // ---- watchdog ------------------------------------------------------------
  initial begin
    #4_000_000;
    $display("RESULT: FAIL (watchdog: no forward progress)");
    $finish;
  end

// ---------------------------------------------------------------------------
// CHECKING AND DIRECTED STIMULUS
// ---------------------------------------------------------------------------

  task automatic die(input string msg);
    begin
      $display("FAIL at cycle %0d: %s", bfm_cycle, msg);
      $display("RESULT: FAIL");
      $finish;
    end
  endtask

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
  } aw_exp_t;

  typedef struct packed {
    logic [31:0] data;
    logic [3:0]  strb;
    logic        last;
    logic        user;
  } w_exp_t;

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
  } ar_exp_t;

  typedef struct packed {
    logic [3:0] id;
    logic [1:0] resp;
    logic       check_user;
    logic       user;
  } b_exp_t;

  aw_exp_t aw_q[$];
  w_exp_t  w_q[$];
  ar_exp_t ar_q[$];
  b_exp_t  b_q[$];

  bit exp_r_active[16];
  bit exp_r_manu[16];
  int exp_r_total[16];
  int seen_r[16];

  bit score_en = 1'b0;
  int debt = 0;
  int aw_hs_count = 0;
  int w_hs_count = 0;
  int ar_hs_count = 0;

  bit main_ok;
  bit fifth_accepted;
  int main_i;

  // Saved payloads for X3 stability checks.
  bit prev_rst;
  bit prev_m_awvalid, prev_m_awready;
  bit prev_m_wvalid, prev_m_wready;
  bit prev_m_arvalid, prev_m_arready;
  bit prev_s_bvalid, prev_s_bready;
  bit prev_s_rvalid, prev_s_rready;
  logic [71:0] prev_aw_payload;
  logic [37:0] prev_w_payload;
  logic [65:0] prev_ar_payload;
  logic [6:0]  prev_b_payload;
  logic [39:0] prev_r_payload;

  task automatic clear_expectations();
    int k;
    begin
      aw_q.delete();
      w_q.delete();
      ar_q.delete();
      b_q.delete();
      for (k = 0; k < 16; k++) begin
        exp_r_active[k] = 1'b0;
        exp_r_manu[k] = 1'b0;
        exp_r_total[k] = 0;
        seen_r[k] = 0;
      end
    end
  endtask

  function automatic bit expectations_done();
    int k;
    bit done;
    begin
      done = (aw_q.size() == 0) && (w_q.size() == 0) &&
             (ar_q.size() == 0) && (b_q.size() == 0);
      for (k = 0; k < 16; k++) begin
        if (exp_r_active[k] && (seen_r[k] != exp_r_total[k]))
          done = 1'b0;
      end
      expectations_done = done;
    end
  endfunction

  task automatic wait_all(input int timeout, input string clause_name);
    int t;
    bit done;
    begin
      done = expectations_done();
      for (t = 0; (t < timeout) && !done; t++) begin
        @(negedge clk);
        done = expectations_done();
      end
      if (!done)
        die({"X4/incomplete transaction: ", clause_name});
      // With both response ready signals high, duplicates are promptly seen.
      repeat (4) @(negedge clk);
    end
  endtask

  task automatic expect_aw(input logic [3:0] id, input logic [31:0] addr,
                           input logic [7:0] len, input logic [2:0] size,
                           input logic [1:0] burst, input logic lock,
                           input logic [3:0] cache, input logic [2:0] prot,
                           input logic [3:0] qos, input logic [3:0] region,
                           input logic user);
    aw_exp_t e;
    begin
      e.id = id; e.addr = addr; e.len = len; e.size = size;
      e.burst = burst; e.lock = lock; e.cache = cache; e.prot = prot;
      e.qos = qos; e.region = region; e.user = user;
      aw_q.push_back(e);
    end
  endtask

  task automatic expect_w(input logic [31:0] data, input logic [3:0] strb,
                          input logic last, input logic user);
    w_exp_t e;
    begin
      e.data = data; e.strb = strb; e.last = last; e.user = user;
      w_q.push_back(e);
    end
  endtask

  task automatic expect_ar(input logic [3:0] id, input logic [31:0] addr,
                           input logic [7:0] len, input logic [2:0] size,
                           input logic [1:0] burst, input logic lock,
                           input logic [3:0] cache, input logic [2:0] prot,
                           input logic [3:0] qos, input logic [3:0] region,
                           input logic user);
    ar_exp_t e;
    begin
      e.id = id; e.addr = addr; e.len = len; e.size = size;
      e.burst = burst; e.lock = lock; e.cache = cache; e.prot = prot;
      e.qos = qos; e.region = region; e.user = user;
      ar_q.push_back(e);
    end
  endtask

  task automatic expect_b(input logic [3:0] id, input logic [1:0] resp,
                          input logic check_user, input logic user);
    b_exp_t e;
    begin
      e.id = id; e.resp = resp; e.check_user = check_user; e.user = user;
      b_q.push_back(e);
    end
  endtask

  task automatic expect_normal_r(input logic [3:0] id, input logic [7:0] len);
    begin
      if (exp_r_active[int'(id)])
        die("Testbench error: reused an active R ID");
      exp_r_active[int'(id)] = 1'b1;
      exp_r_manu[int'(id)] = 1'b0;
      exp_r_total[int'(id)] = int'(len) + 1;
      seen_r[int'(id)] = 0;
    end
  endtask

  task automatic expect_manu_r(input logic [3:0] id, input logic [7:0] len);
    begin
      if (exp_r_active[int'(id)])
        die("Testbench error: reused an active R ID");
      exp_r_active[int'(id)] = 1'b1;
      exp_r_manu[int'(id)] = 1'b1;
      exp_r_total[int'(id)] = int'(len) + 1;
      seen_r[int'(id)] = 0;
    end
  endtask

  // Full-field drivers, used to check fields which the basic BFM holds fixed.
  task automatic offer_aw_full(
      input logic [3:0] id, input logic [31:0] addr, input logic [7:0] len,
      input logic [5:0] atop, input logic [2:0] size,
      input logic [1:0] burst, input logic lock, input logic [3:0] cache,
      input logic [2:0] prot, input logic [3:0] qos,
      input logic [3:0] region, input logic user,
      input int timeout, output bit accepted);
    int t;
    begin
      @(negedge clk);
      s_awid = id; s_awaddr = addr; s_awlen = len; s_awatop = atop;
      s_awsize = size; s_awburst = burst; s_awlock = lock;
      s_awcache = cache; s_awprot = prot; s_awqos = qos;
      s_awregion = region; s_awuser = user; s_awvalid = 1'b1;
      accepted = 1'b0;
      for (t = 0; t < timeout; t++) begin
        @(posedge clk);
        if (s_awready) begin accepted = 1'b1; break; end
      end
      @(negedge clk);
      s_awvalid = 1'b0;
    end
  endtask

  task automatic offer_w_full(input logic [31:0] data, input logic [3:0] strb,
                              input logic last, input logic user,
                              input int timeout, output bit accepted);
    int t;
    begin
      @(negedge clk);
      s_wdata = data; s_wstrb = strb; s_wlast = last; s_wuser = user;
      s_wvalid = 1'b1;
      accepted = 1'b0;
      for (t = 0; t < timeout; t++) begin
        @(posedge clk);
        if (s_wready) begin accepted = 1'b1; break; end
      end
      @(negedge clk);
      s_wvalid = 1'b0;
    end
  endtask

  task automatic offer_ar_full(
      input logic [3:0] id, input logic [31:0] addr, input logic [7:0] len,
      input logic [2:0] size, input logic [1:0] burst, input logic lock,
      input logic [3:0] cache, input logic [2:0] prot,
      input logic [3:0] qos, input logic [3:0] region, input logic user,
      input int timeout, output bit accepted);
    int t;
    begin
      @(negedge clk);
      s_arid = id; s_araddr = addr; s_arlen = len; s_arsize = size;
      s_arburst = burst; s_arlock = lock; s_arcache = cache;
      s_arprot = prot; s_arqos = qos; s_arregion = region;
      s_aruser = user; s_arvalid = 1'b1;
      accepted = 1'b0;
      for (t = 0; t < timeout; t++) begin
        @(posedge clk);
        if (s_arready) begin accepted = 1'b1; break; end
      end
      @(negedge clk);
      s_arvalid = 1'b0;
    end
  endtask

  // Non-atomic writes use deliberately non-default values in every field.
  task automatic normal_aw(input logic [3:0] id, input logic [31:0] addr,
                           input logic [7:0] len, input logic [5:0] atop,
                           input int timeout, output bit accepted);
    begin
      expect_aw(id, addr, len, 3'd3, 2'd2, 1'b1, 4'hA, 3'd5,
                4'hC, 4'h9, 1'b1);
      expect_b(id, 2'b00, 1'b1, 1'b0);
      offer_aw_full(id, addr, len, atop, 3'd3, 2'd2, 1'b1, 4'hA,
                    3'd5, 4'hC, 4'h9, 1'b1, timeout, accepted);
    end
  endtask

  task automatic normal_w(input logic [31:0] data, input logic [3:0] strb,
                          input logic last, input logic user,
                          input int timeout, output bit accepted);
    begin
      expect_w(data, strb, last, user);
      offer_w_full(data, strb, last, user, timeout, accepted);
    end
  endtask

  task automatic normal_ar(input logic [3:0] id, input logic [31:0] addr,
                           input logic [7:0] len, input int timeout,
                           output bit accepted);
    begin
      expect_ar(id, addr, len, 3'd1, 2'd2, 1'b1, 4'h5, 3'd6,
                4'hB, 4'h7, 1'b1);
      expect_normal_r(id, len);
      offer_ar_full(id, addr, len, 3'd1, 2'd2, 1'b1, 4'h5, 3'd6,
                    4'hB, 4'h7, 1'b1, timeout, accepted);
    end
  endtask

  task automatic do_atomic(input logic [3:0] id, input logic [7:0] len,
                           input logic [5:0] atop);
    bit ok;
    int i;
    begin
      expect_b(id, 2'b10, 1'b0, 1'b0);
      if (atop[5])
        expect_manu_r(id, len);
      bfm_aw(id, 32'h4000_0000 + 32'(id) * 32'h100, len, atop, 64, ok);
      if (!ok)
        die("X4: atomic AW was not accepted within 64 cycles");
      for (i = 0; i <= int'(len); i++) begin
        bfm_w(32'hA000_0000 + 32'(i), 4'(i + 1), i == int'(len), 64, ok);
        if (!ok)
          die("X4/F2: filtered W beat was not consumed within 64 cycles");
      end
      wait_all(64, "filtered write responses");
    end
  endtask

  task automatic new_phase();
    begin
      @(negedge clk);
      score_en = 1'b0;
      s_awvalid = 1'b0;
      s_wvalid = 1'b0;
      s_arvalid = 1'b0;
      s_bready = 1'b1;
      s_rready = 1'b1;
      bfm_b_lag = 0;
      bfm_reset();
      clear_expectations();
      debt = 0;
      aw_hs_count = 0;
      w_hs_count = 0;
      ar_hs_count = 0;
      score_en = 1'b1;
    end
  endtask

  // Protocol stability, exact payload checking, response accounting, and debt.
  always @(posedge clk) begin
    automatic int rid;

    if (!rst_n) begin
      debt = 0;
      aw_hs_count = 0;
      w_hs_count = 0;
      ar_hs_count = 0;
      prev_rst = 1'b0;
      prev_m_awvalid = 1'b0;
      prev_m_wvalid = 1'b0;
      prev_m_arvalid = 1'b0;
      prev_s_bvalid = 1'b0;
      prev_s_rvalid = 1'b0;

      // X1 applies from the first rising edge onward.
      if (m_awvalid !== 1'b0)
        die("X1: m_awvalid_o asserted while reset was active");
      if (m_wvalid !== 1'b0)
        die("X1: m_wvalid_o asserted while reset was active");
    end else begin
      if (prev_rst) begin
        if (prev_m_awvalid && !prev_m_awready) begin
          if ((m_awvalid !== 1'b1) ||
              ({m_awid, m_awaddr, m_awlen, m_awsize, m_awburst, m_awlock,
                m_awcache, m_awprot, m_awqos, m_awregion, m_awatop,
                m_awuser} !== prev_aw_payload))
            die("X3: AW valid/payload changed before ready");
        end
        if (prev_m_wvalid && !prev_m_wready) begin
          if ((m_wvalid !== 1'b1) ||
              ({m_wdata, m_wstrb, m_wlast, m_wuser} !== prev_w_payload))
            die("X3: W valid/payload changed before ready");
        end
        if (prev_m_arvalid && !prev_m_arready) begin
          if ((m_arvalid !== 1'b1) ||
              ({m_arid, m_araddr, m_arlen, m_arsize, m_arburst, m_arlock,
                m_arcache, m_arprot, m_arqos, m_arregion,
                m_aruser} !== prev_ar_payload))
            die("X3: AR valid/payload changed before ready");
        end
        if (prev_s_bvalid && !prev_s_bready) begin
          if ((s_bvalid !== 1'b1) ||
              ({s_bid, s_bresp, s_buser} !== prev_b_payload))
            die("X3: B valid/payload changed before ready");
        end
        if (prev_s_rvalid && !prev_s_rready) begin
          if ((s_rvalid !== 1'b1) ||
              ({s_rid, s_rdata, s_rresp, s_rlast, s_ruser} !== prev_r_payload))
            die("X3: R valid/payload changed before ready");
        end
      end

      if ((m_awvalid === 1'b1) && (m_awatop !== 6'b000000))
        die("F1: nonzero m_awatop_o while m_awvalid_o was asserted");

      if (score_en) begin
        if (m_awvalid && m_awready) begin
          if ((debt >= 4) && !(m_wvalid && m_wready && m_wlast))
            die("W2: fifth downstream AW exceeded MAX_WRITE_TXNS");
          aw_hs_count = aw_hs_count + 1;
          if (aw_q.size() == 0)
            die("F1/P1: unexpected downstream AW (atomic filtering or extra AW)");
          if ((m_awid !== aw_q[0].id) || (m_awaddr !== aw_q[0].addr) ||
              (m_awlen !== aw_q[0].len) || (m_awsize !== aw_q[0].size) ||
              (m_awburst !== aw_q[0].burst) || (m_awlock !== aw_q[0].lock) ||
              (m_awcache !== aw_q[0].cache) || (m_awprot !== aw_q[0].prot) ||
              (m_awqos !== aw_q[0].qos) || (m_awregion !== aw_q[0].region) ||
              (m_awuser !== aw_q[0].user))
            die("P1: forwarded AW field was modified");
          void'(aw_q.pop_front());
        end

        if (m_wvalid && m_wready) begin
          w_hs_count = w_hs_count + 1;
          if (w_q.size() == 0)
            die("F2/P2: unexpected downstream W beat");
          if ((m_wdata !== w_q[0].data) || (m_wstrb !== w_q[0].strb) ||
              (m_wlast !== w_q[0].last) || (m_wuser !== w_q[0].user))
            die("P2: forwarded W beat was modified or reordered");
          void'(w_q.pop_front());
        end

        if (m_arvalid && m_arready) begin
          ar_hs_count = ar_hs_count + 1;
          if (ar_q.size() == 0)
            die("P3: unexpected or duplicate downstream AR");
          if ((m_arid !== ar_q[0].id) || (m_araddr !== ar_q[0].addr) ||
              (m_arlen !== ar_q[0].len) || (m_arsize !== ar_q[0].size) ||
              (m_arburst !== ar_q[0].burst) || (m_arlock !== ar_q[0].lock) ||
              (m_arcache !== ar_q[0].cache) || (m_arprot !== ar_q[0].prot) ||
              (m_arqos !== ar_q[0].qos) || (m_arregion !== ar_q[0].region) ||
              (m_aruser !== ar_q[0].user))
            die("P3: forwarded AR field was modified");
          void'(ar_q.pop_front());
        end

        if (s_bvalid && s_bready) begin
          if (b_q.size() == 0)
            die("F3/P4: unexpected or duplicate B response");
          if (s_bid !== b_q[0].id)
            die("F3/P4: B response carried the wrong ID");
          if (s_bresp !== b_q[0].resp)
            die("F3/P4: B response carried the wrong response code");
          if (b_q[0].check_user && (s_buser !== b_q[0].user))
            die("P4: passed-through BUSER was modified");
          void'(b_q.pop_front());
        end

        if (s_rvalid && s_rready) begin
          if ($isunknown(s_rid))
            die("F4/P3: R ID was unknown on a handshake");
          rid = int'(s_rid);
          if (!exp_r_active[rid])
            die("F5/P3: unexpected R response or R response for wrong ID");
          if (seen_r[rid] >= exp_r_total[rid])
            die("F4: too many manufactured R beats");
          if (exp_r_manu[rid]) begin
            if (s_rresp !== 2'b10)
              die("F4: manufactured R beat was not SLVERR");
          end else begin
            if (s_rresp !== 2'b00)
              die("P3: passed-through RRESP was modified");
            if (s_ruser !== 1'b0)
              die("P3: passed-through RUSER was modified");
            if (s_rdata !== (32'hFEED_0000 +
                             32'(exp_r_total[rid] - seen_r[rid])))
              die("P3: passed-through RDATA was modified or reordered");
          end
          if (seen_r[rid] == exp_r_total[rid] - 1) begin
            if (s_rlast !== 1'b1)
              die("F4/P3: final R beat did not assert RLAST");
          end else begin
            if (s_rlast !== 1'b0)
              die("F4/P3: non-final R beat asserted RLAST");
          end
          seen_r[rid] = seen_r[rid] + 1;
        end

        if ((m_awvalid && m_awready) &&
            !(m_wvalid && m_wready && m_wlast))
          debt = debt + 1;
        else if (!(m_awvalid && m_awready) &&
                 (m_wvalid && m_wready && m_wlast))
          debt = debt - 1;

        if (debt < 0)
          die("W1/W4: downstream write debt became negative");
        if (debt > 4)
          die("W2: downstream write debt exceeded four");
      end

      prev_rst = 1'b1;
      prev_m_awvalid = m_awvalid;
      prev_m_awready = m_awready;
      prev_m_wvalid = m_wvalid;
      prev_m_wready = m_wready;
      prev_m_arvalid = m_arvalid;
      prev_m_arready = m_arready;
      prev_s_bvalid = s_bvalid;
      prev_s_bready = s_bready;
      prev_s_rvalid = s_rvalid;
      prev_s_rready = s_rready;
      prev_aw_payload = {m_awid, m_awaddr, m_awlen, m_awsize, m_awburst,
                         m_awlock, m_awcache, m_awprot, m_awqos, m_awregion,
                         m_awatop, m_awuser};
      prev_w_payload = {m_wdata, m_wstrb, m_wlast, m_wuser};
      prev_ar_payload = {m_arid, m_araddr, m_arlen, m_arsize, m_arburst,
                         m_arlock, m_arcache, m_arprot, m_arqos, m_arregion,
                         m_aruser};
      prev_b_payload = {s_bid, s_bresp, s_buser};
      prev_r_payload = {s_rid, s_rdata, s_rresp, s_rlast, s_ruser};
    end
  end

  initial begin
    // -----------------------------------------------------------------------
    // P1/P2/P3/P4 and X3: full-field pass-through, multi-beat traffic, and
    // response backpressure. Low ATOP bits must not cause classification.
    // -----------------------------------------------------------------------
    new_phase();
    bfm_b_ready(1'b0);
    bfm_r_ready(1'b0);

    normal_aw(4'h1, 32'h1234_5678, 8'd2, 6'b001010, 64, main_ok);
    if (!main_ok) die("X4/W3: ordinary AW was stalled below the debt bound");
    normal_w(32'h0123_4567, 4'h3, 1'b0, 1'b1, 64, main_ok);
    if (!main_ok) die("P2: first ordinary W beat was not accepted");
    normal_w(32'h89AB_CDEF, 4'hC, 1'b0, 1'b0, 64, main_ok);
    if (!main_ok) die("P2: middle ordinary W beat was not accepted");
    normal_w(32'h55AA_A55A, 4'h5, 1'b1, 1'b1, 64, main_ok);
    if (!main_ok) die("P2: final ordinary W beat was not accepted");

    normal_ar(4'h2, 32'hDEAD_BEEF, 8'd2, 64, main_ok);
    if (!main_ok) die("P3: ordinary AR was not accepted");

    repeat (12) @(negedge clk);
    bfm_b_ready(1'b1);
    bfm_r_ready(1'b1);
    wait_all(64, "ordinary pass-through traffic");

    // -----------------------------------------------------------------------
    // P3: reads are not subject to the write bound. Several outstanding reads
    // and several addresses must all pass unchanged.
    // -----------------------------------------------------------------------
    new_phase();
    for (main_i = 0; main_i < 6; main_i++) begin
      normal_ar(4'(8 + main_i), 32'h1000_0000 + 32'(main_i) * 32'h40,
                8'd0, 64, main_ok);
      if (!main_ok) die("P3: read traffic was improperly stalled or filtered");
    end
    wait_all(64, "multiple outstanding reads");

    // -----------------------------------------------------------------------
    // C1/C2/F1-F5: all three classes, low ATOP-bit variations, single and
    // multi-beat manufactured R bursts. Responses are accepted as soon as they
    // appear, including before B and before the final W beat.
    // -----------------------------------------------------------------------
    new_phase();
    do_atomic(4'h3, 8'd2, 6'b010101); // atomic, no read response
    if (debt != 0) die("W5: filtered write changed downstream debt");
    do_atomic(4'h4, 8'd0, 6'b011111); // atomic, no read response
    if (debt != 0) die("W5: filtered write changed downstream debt");
    do_atomic(4'h5, 8'd0, 6'b100011); // one manufactured R beat
    if (debt != 0) die("W5: filtered write changed downstream debt");
    do_atomic(4'h6, 8'd2, 6'b111100); // three manufactured R beats
    if (debt != 0) die("W5: filtered write changed downstream debt");

    // Manufactured responses under backpressure; no B/R ordering is assumed.
    new_phase();
    bfm_b_ready(1'b0);
    bfm_r_ready(1'b0);
    expect_b(4'h7, 2'b10, 1'b0, 1'b0);
    expect_manu_r(4'h7, 8'd1);
    bfm_aw(4'h7, 32'h1234_5678, 8'd1, 6'b100000, 64, main_ok);
    if (!main_ok) die("X4: backpressured atomic AW was not accepted");
    bfm_w(32'h1111_2222, 4'hF, 1'b0, 64, main_ok);
    if (!main_ok) die("X4/F2: first filtered W beat stalled");
    bfm_w(32'h3333_4444, 4'hF, 1'b1, 64, main_ok);
    if (!main_ok) die("X4/F2: final filtered W beat stalled");
    repeat (12) @(negedge clk);
    bfm_b_ready(1'b1);
    bfm_r_ready(1'b1);
    wait_all(64, "backpressured manufactured responses");

    // -----------------------------------------------------------------------
    // W2/W3/W4/W5: build debt to exactly four by withholding every W beat.
    // Let all four B responses return, proving that B does not reduce debt.
    // A filtered write must still work at the bound. The fifth ordinary AW may
    // be buffered upstream, but must not reach the master port until a WLAST.
    // -----------------------------------------------------------------------
    new_phase();
    for (main_i = 0; main_i < 4; main_i++) begin
      normal_aw(4'(main_i), 32'h8000_0000 + 32'(main_i) * 32'h100,
                8'd0, 6'b000000, 64, main_ok);
      if (!main_ok) die("W3: AW stalled while downstream debt was below four");
    end
    wait_all(64, "B responses with W bursts withheld");
    if (debt != 4) die("W1/W4: B responses incorrectly reduced write debt");

    do_atomic(4'h8, 8'd0, 6'b010000);
    if (debt != 4) die("W5: filtered write changed debt at the bound");

    normal_aw(4'h4, 32'h8000_1000, 8'd0, 6'b000000, 8, fifth_accepted);
    repeat (6) @(negedge clk);
    if (aw_hs_count != 4)
      die("W2/W4: fifth AW was forwarded before a downstream WLAST");

    normal_w(32'hD000_0000, 4'hF, 1'b1, 1'b0, 64, main_ok);
    if (!main_ok) die("P2: could not complete first withheld W burst");

    if (!fifth_accepted) begin
      offer_aw_full(4'h4, 32'h8000_1000, 8'd0, 6'b000000,
                    3'd3, 2'd2, 1'b1, 4'hA, 3'd5, 4'hC, 4'h9, 1'b1,
                    64, main_ok);
      if (!main_ok) die("W3/X4: fifth AW stalled after debt fell below four");
    end
    wait_all(64, "fifth AW after WLAST reduced debt");

    for (main_i = 0; main_i < 4; main_i++) begin
      normal_w(32'hD100_0000 + 32'(main_i), 4'hF, 1'b1, 1'b0,
               64, main_ok);
      if (!main_ok) die("P2: remaining ordinary W burst stalled");
    end
    wait_all(64, "drain downstream write debt");
    if (debt != 0) die("W4: completed W bursts did not reduce debt");

    // -----------------------------------------------------------------------
    // X1/X2: reset discards a filtered transaction, suppresses originated AW/W
    // even when upstream valids are presented, and does not gate downstream B/R.
    // -----------------------------------------------------------------------
    new_phase();
    expect_b(4'h9, 2'b10, 1'b0, 1'b0);
    expect_manu_r(4'h9, 8'd1);
    bfm_aw(4'h9, 32'hFFFF_0000, 8'd1, 6'b100000, 64, main_ok);
    if (!main_ok) die("X4: atomic AW before reset was not accepted");

    @(negedge clk);
    score_en = 1'b0;
    rst_n = 1'b0;
    s_awid = 4'hA;
    s_awaddr = 32'hAAAA_0000;
    s_awlen = 8'd0;
    s_awatop = 6'b010000;
    s_awvalid = 1'b1;
    s_wdata = 32'hBAD0_BAD0;
    s_wlast = 1'b1;
    s_wvalid = 1'b1;
    repeat (3) @(posedge clk);
    @(negedge clk);
    if ((m_awvalid !== 1'b0) || (m_wvalid !== 1'b0))
      die("X1: design originated AW/W during reset");
    if ((s_bvalid !== 1'b0) || (s_rvalid !== 1'b0))
      die("X1/X2: manufactured response survived reset with master port quiet");

    force m_bvalid = 1'b1;
    force m_bid = 4'hC;
    force m_bresp = 2'b11;
    force m_buser = 1'b1;
    force m_rvalid = 1'b1;
    force m_rid = 4'hD;
    force m_rdata = 32'hCAFE_BABE;
    force m_rresp = 2'b01;
    force m_rlast = 1'b1;
    force m_ruser = 1'b1;

    @(negedge clk);
    if ((s_bvalid !== 1'b1) || (s_bid !== 4'hC) ||
        (s_bresp !== 2'b11) || (s_buser !== 1'b1))
      die("X1/P4: B pass-through was gated or altered during reset");
    if ((s_rvalid !== 1'b1) || (s_rid !== 4'hD) ||
        (s_rdata !== 32'hCAFE_BABE) || (s_rresp !== 2'b01) ||
        (s_rlast !== 1'b1) || (s_ruser !== 1'b1))
      die("X1/P3: R pass-through was gated or altered during reset");

    release m_bvalid;
    release m_bid;
    release m_bresp;
    release m_buser;
    release m_rvalid;
    release m_rid;
    release m_rdata;
    release m_rresp;
    release m_rlast;
    release m_ruser;
    s_awvalid = 1'b0;
    s_wvalid = 1'b0;

    @(negedge clk);
    if ((s_bvalid !== 1'b0) || (s_rvalid !== 1'b0))
      die("X1: quiet master port produced a response during reset");

    repeat (2) @(posedge clk);
    @(negedge clk);
    rst_n = 1'b1;
    clear_expectations();
    debt = 0;
    aw_hs_count = 0;
    w_hs_count = 0;
    ar_hs_count = 0;
    score_en = 1'b1;

    repeat (10) @(negedge clk);
    normal_aw(4'h0, 32'h1234_5678, 8'd0, 6'b000000, 64, main_ok);
    if (!main_ok) die("X2: design did not accept new traffic after reset");
    normal_w(32'h600D_600D, 4'hF, 1'b1, 1'b0, 64, main_ok);
    if (!main_ok) die("X2: W path did not recover after reset");
    wait_all(64, "post-reset ordinary transaction");

    $display("RESULT: PASS");
    $finish;
  end

endmodule
