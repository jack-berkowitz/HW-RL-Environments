`timescale 1ns/1ps

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
  // Offers ONE write address and returns once it has transferred. Every field
  // is presented at the negative edge and held stable until the transfer, which
  // is what clause X3 requires of a source.
  //
  // `accepted` is returned low if `timeout` cycles pass without a transfer;
  // the offer is then withdrawn. Pass a large timeout when you simply want to
  // wait, and a small one when the point of the test is whether it is taken.
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
  // It accepts every request the design forwards and answers it. It is a model
  // of the thing on the other side, not of the design: it does not know or care
  // which requests the design chose to forward, and it checks nothing.
  //
  // bfm_dn_b_lag sets how many cycles the subordinate waits, after taking a
  // write address, before it answers that write. Zero means it answers as
  // early as it can. Set it to whatever your test needs.
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
  // Yours to keep. It fires regardless of what the design does, which is what
  // the termination requirement demands: some faulty designs never make
  // progress at all, and without this your testbench hangs instead of
  // reporting a verdict. A hang is not a verdict.
  initial begin
    #4_000_000;
    $display("RESULT: FAIL (watchdog: no forward progress)");
    $finish;
  end

// ---------------------------------------------------------------------------
// Testbench bookkeeping and checking
// ---------------------------------------------------------------------------

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
    logic        is_atomic;
    logic        need_r;
  } aw_rec_t;

  typedef struct packed {
    logic [31:0] data;
    logic [3:0]  strb;
    logic        last;
    logic        user;
  } w_rec_t;

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
  } ar_rec_t;

  typedef struct packed {
    logic [3:0] id;
    logic [1:0] resp;
    logic       user;
  } b_rec_t;

  typedef struct packed {
    logic [3:0]  id;
    logic [31:0] data;
    logic [1:0]  resp;
    logic        last;
    logic        user;
  } r_rec_t;

  aw_rec_t slave_writes [$];
  aw_rec_t exp_maw_q   [$];
  w_rec_t  exp_mw_q    [$];
  ar_rec_t exp_mar_q   [$];
  b_rec_t  exp_sb_q    [$];
  r_rec_t  exp_sr_q    [$];

  // At most one filtered write with a given ID is outstanding in the directed
  // stimulus. R beats are deliberately attributed by ID, never by arrival order.
  bit filt_active     [0:15];
  bit filt_wlast_seen [0:15];
  int filt_b_left     [0:15];
  int filt_r_left     [0:15];
  int filt_wlast_time [0:15];
  int filt_count;

  int debt;
  int tb_cycle = 0;
  bit seen_edge = 0;
  integer k;

  // Previous-cycle state for X3 stability checks.
  bit prev_m_awvalid, prev_m_awready;
  bit prev_m_wvalid,  prev_m_wready;
  bit prev_m_arvalid, prev_m_arready;
  bit prev_s_bvalid,  prev_s_bready;
  bit prev_s_rvalid,  prev_s_rready;

  logic [71:0] prev_m_aw_payload;
  logic [37:0] prev_m_w_payload;
  logic [65:0] prev_m_ar_payload;
  logic [6:0]  prev_s_b_payload;
  logic [39:0] prev_s_r_payload;

  bit ok;
  bit ok2;
  bit ok3;
  bit fifth_taken;
  integer j;
  aw_rec_t aw_cfg;
  ar_rec_t ar_cfg;

  task automatic fail(input string clause, input string detail);
    begin
      $display("CHECK FAILURE [%s] at cycle %0d: %s",
               clause, tb_cycle, detail);
      $display("RESULT: FAIL");
      $finish;
    end
  endtask

  task automatic clear_bookkeeping;
    integer n;
    begin
      slave_writes.delete();
      exp_maw_q.delete();
      exp_mw_q.delete();
      exp_mar_q.delete();
      exp_sb_q.delete();
      exp_sr_q.delete();
      debt = 0;
      filt_count = 0;
      for (n = 0; n < 16; n = n + 1) begin
        filt_active[n] = 1'b0;
        filt_wlast_seen[n] = 1'b0;
        filt_b_left[n] = 0;
        filt_r_left[n] = 0;
        filt_wlast_time[n] = 0;
      end
    end
  endtask

  // Full-field drivers used where the simplified plumbing's fixed fields would
  // not exercise P1/P2/P3 thoroughly enough.
  task automatic tb_aw_full(input aw_rec_t a, input int timeout,
                            output bit accepted);
    int t;
    @(negedge clk);
    s_awid     = a.id;
    s_awaddr   = a.addr;
    s_awlen    = a.len;
    s_awsize   = a.size;
    s_awburst  = a.burst;
    s_awlock   = a.lock;
    s_awcache  = a.cache;
    s_awprot   = a.prot;
    s_awqos    = a.qos;
    s_awregion = a.region;
    s_awatop   = a.atop;
    s_awuser   = a.user;
    s_awvalid  = 1'b1;
    accepted = 1'b0;
    for (t = 0; t < timeout; t = t + 1) begin
      @(posedge clk);
      if (s_awready) begin
        accepted = 1'b1;
        break;
      end
    end
    @(negedge clk);
    s_awvalid = 1'b0;
  endtask

  task automatic tb_w_full(input logic [31:0] data,
                           input logic [3:0] strb,
                           input bit last,
                           input bit user,
                           input int timeout,
                           output bit accepted);
    int t;
    @(negedge clk);
    s_wdata  = data;
    s_wstrb  = strb;
    s_wlast  = last;
    s_wuser  = user;
    s_wvalid = 1'b1;
    accepted = 1'b0;
    for (t = 0; t < timeout; t = t + 1) begin
      @(posedge clk);
      if (s_wready) begin
        accepted = 1'b1;
        break;
      end
    end
    @(negedge clk);
    s_wvalid = 1'b0;
  endtask

  task automatic tb_ar_full(input ar_rec_t a, input int timeout,
                            output bit accepted);
    int t;
    @(negedge clk);
    s_arid     = a.id;
    s_araddr   = a.addr;
    s_arlen    = a.len;
    s_arsize   = a.size;
    s_arburst  = a.burst;
    s_arlock   = a.lock;
    s_arcache  = a.cache;
    s_arprot   = a.prot;
    s_arqos    = a.qos;
    s_arregion = a.region;
    s_aruser   = a.user;
    s_arvalid  = 1'b1;
    accepted = 1'b0;
    for (t = 0; t < timeout; t = t + 1) begin
      @(posedge clk);
      if (s_arready) begin
        accepted = 1'b1;
        break;
      end
    end
    @(negedge clk);
    s_arvalid = 1'b0;
  endtask

  function automatic bit all_idle();
    all_idle = (slave_writes.size() == 0) &&
               (exp_maw_q.size() == 0) &&
               (exp_mw_q.size() == 0) &&
               (exp_mar_q.size() == 0) &&
               (exp_sb_q.size() == 0) &&
               (exp_sr_q.size() == 0) &&
               (filt_count == 0) &&
               (debt == 0) &&
               (bfm_bq_id.size() == 0) &&
               (bfm_rq_id.size() == 0);
  endfunction

  task automatic wait_idle(input int timeout, input string clause);
    int t;
    for (t = 0; t < timeout; t = t + 1) begin
      @(negedge clk);
      if (all_idle()) return;
    end
    fail(clause, "outstanding traffic or responses did not drain");
  endtask

  task automatic wait_bvalid(input int timeout);
    int t;
    for (t = 0; t < timeout; t = t + 1) begin
      @(negedge clk);
      if (s_bvalid) return;
    end
    fail("F3/X4", "manufactured B response was not presented");
  endtask

  task automatic wait_rvalid(input int timeout, input string clause);
    int t;
    for (t = 0; t < timeout; t = t + 1) begin
      @(negedge clk);
      if (s_rvalid) return;
    end
    fail(clause, "expected R response was not presented");
  endtask

  task automatic wait_debt_four(input int timeout);
    int t;
    for (t = 0; t < timeout; t = t + 1) begin
      @(negedge clk);
      if (debt == 4) return;
    end
    fail("W2/W3", "four forwarded AWs without WLAST did not produce debt four");
  endtask

  task automatic wait_normal_bs_drained(input int timeout);
    int t;
    for (t = 0; t < timeout; t = t + 1) begin
      @(negedge clk);
      if ((bfm_bq_id.size() == 0) && (exp_sb_q.size() == 0)) return;
    end
    fail("P4", "ordinary downstream B responses were not returned");
  endtask

  // One sampling process owns all scoreboard state. Same-cycle pass-through is
  // handled by creating upstream expectations before checking downstream
  // handshakes, and by capturing downstream responses before checking slave
  // response handshakes.
  always @(posedge clk) begin
    automatic aw_rec_t a;
    automatic w_rec_t w;
    automatic ar_rec_t ar;
    automatic b_rec_t b;
    automatic r_rec_t rr;

    tb_cycle = tb_cycle + 1;

    if (!seen_edge) begin
      // X1 explicitly makes no promise before the first rising edge.
      seen_edge = 1'b1;
      clear_bookkeeping();
      prev_m_awvalid = 1'b0;
      prev_m_wvalid = 1'b0;
      prev_m_arvalid = 1'b0;
      prev_s_bvalid = 1'b0;
      prev_s_rvalid = 1'b0;
    end else if (!rst_n) begin
      // The master-port responder is quiet in the reset tests. Thus any B/R
      // valid not coming from its inputs is an improperly manufactured reply.
      if (m_awvalid !== 1'b0)
        fail("X1", "m_awvalid_o asserted while reset was active");
      if (m_wvalid !== 1'b0)
        fail("X1", "m_wvalid_o asserted while reset was active");

      if (!m_bvalid && (s_bvalid !== 1'b0))
        fail("X1", "manufactured or stale B response during reset");
      if (!m_rvalid && (s_rvalid !== 1'b0))
        fail("X1", "manufactured or stale R response during reset");

      // If a downstream response is present, reset must not gate its
      // combinational pass-through.
      if (m_bvalid) begin
        if ((s_bvalid !== 1'b1) ||
            ({s_bid, s_bresp, s_buser} !== {m_bid, m_bresp, m_buser}))
          fail("X1/P4", "B pass-through was gated or altered during reset");
      end
      if (m_rvalid) begin
        if ((s_rvalid !== 1'b1) ||
            ({s_rid, s_rdata, s_rresp, s_rlast, s_ruser} !==
             {m_rid, m_rdata, m_rresp, m_rlast, m_ruser}))
          fail("X1/P3", "R pass-through was gated or altered during reset");
      end

      clear_bookkeeping();
      prev_m_awvalid = 1'b0;
      prev_m_wvalid = 1'b0;
      prev_m_arvalid = 1'b0;
      prev_s_bvalid = 1'b0;
      prev_s_rvalid = 1'b0;
    end else begin
      // ---- X3: valid and payload persist until ready ----------------------
      if (prev_m_awvalid && !prev_m_awready) begin
        if ((m_awvalid !== 1'b1) ||
            ({m_awid, m_awaddr, m_awlen, m_awsize, m_awburst,
              m_awlock, m_awcache, m_awprot, m_awqos, m_awregion,
              m_awatop, m_awuser} !== prev_m_aw_payload))
          fail("X3", "AW valid or payload changed before downstream ready");
      end
      if (prev_m_wvalid && !prev_m_wready) begin
        if ((m_wvalid !== 1'b1) ||
            ({m_wdata, m_wstrb, m_wlast, m_wuser} !== prev_m_w_payload))
          fail("X3", "W valid or payload changed before downstream ready");
      end
      if (prev_m_arvalid && !prev_m_arready) begin
        if ((m_arvalid !== 1'b1) ||
            ({m_arid, m_araddr, m_arlen, m_arsize, m_arburst,
              m_arlock, m_arcache, m_arprot, m_arqos, m_arregion,
              m_aruser} !== prev_m_ar_payload))
          fail("X3", "AR valid or payload changed before downstream ready");
      end
      if (prev_s_bvalid && !prev_s_bready) begin
        if ((s_bvalid !== 1'b1) ||
            ({s_bid, s_bresp, s_buser} !== prev_s_b_payload))
          fail("X3", "B valid or payload changed while backpressured");
      end
      if (prev_s_rvalid && !prev_s_rready) begin
        if ((s_rvalid !== 1'b1) ||
            ({s_rid, s_rdata, s_rresp, s_rlast, s_ruser} !==
             prev_s_r_payload))
          fail("X3", "R valid or payload changed while backpressured");
      end

      // F1 applies whenever valid is asserted, not only on a handshake.
      if (m_awvalid && (m_awatop !== 6'b000000))
        fail("F1", "m_awatop_o was nonzero while m_awvalid_o was asserted");

      // ---- Accept and classify upstream AW -------------------------------
      if (s_awvalid && s_awready) begin
        a.id = s_awid;
        a.addr = s_awaddr;
        a.len = s_awlen;
        a.size = s_awsize;
        a.burst = s_awburst;
        a.lock = s_awlock;
        a.cache = s_awcache;
        a.prot = s_awprot;
        a.qos = s_awqos;
        a.region = s_awregion;
        a.atop = s_awatop;
        a.user = s_awuser;
        a.is_atomic = (s_awatop[5:4] != 2'b00);
        a.need_r = (s_awatop[5] == 1'b1);

        slave_writes.push_back(a);

        if (!a.is_atomic) begin
          exp_maw_q.push_back(a);
        end else begin
          if (filt_active[s_awid])
            fail("TESTBOOKKEEPING", "filtered ID reused while outstanding");
          filt_active[s_awid] = 1'b1;
          filt_wlast_seen[s_awid] = 1'b0;
          filt_wlast_time[s_awid] = 0;
          filt_b_left[s_awid] = 1;
          if (a.need_r)
            filt_r_left[s_awid] = int'(a.len) + 1;
          else
            filt_r_left[s_awid] = 0;
          filt_count = filt_count + 1;
        end
      end

      // ---- Accept upstream AR --------------------------------------------
      if (s_arvalid && s_arready) begin
        ar.id = s_arid;
        ar.addr = s_araddr;
        ar.len = s_arlen;
        ar.size = s_arsize;
        ar.burst = s_arburst;
        ar.lock = s_arlock;
        ar.cache = s_arcache;
        ar.prot = s_arprot;
        ar.qos = s_arqos;
        ar.region = s_arregion;
        ar.user = s_aruser;
        exp_mar_q.push_back(ar);
      end

      // ---- Accept upstream W ---------------------------------------------
      if (s_wvalid && s_wready) begin
        if (slave_writes.size() == 0) begin
          fail("P2/F2", "W beat transferred without an accepted write address");
        end else begin
          a = slave_writes[0];
          if (!a.is_atomic) begin
            w.data = s_wdata;
            w.strb = s_wstrb;
            w.last = s_wlast;
            w.user = s_wuser;
            exp_mw_q.push_back(w);
          end
          if (s_wlast) begin
            if (a.is_atomic && filt_active[a.id]) begin
              filt_wlast_seen[a.id] = 1'b1;
              filt_wlast_time[a.id] = tb_cycle;
            end
            void'(slave_writes.pop_front());
          end
        end
      end

      // ---- Check downstream AW -------------------------------------------
      if (m_awvalid && m_awready) begin
        if (exp_maw_q.size() == 0) begin
          fail("F1/P1", "atomic or otherwise unexpected AW reached master port");
        end else begin
          a = exp_maw_q[0];
          if ({m_awid, m_awaddr, m_awlen, m_awsize, m_awburst,
               m_awlock, m_awcache, m_awprot, m_awqos, m_awregion,
               m_awuser} !==
              {a.id, a.addr, a.len, a.size, a.burst, a.lock,
               a.cache, a.prot, a.qos, a.region, a.user})
            fail("P1", "non-atomic AW field was modified");
          if (m_awatop !== 6'b000000)
            fail("F1", "forwarded AW did not clear AWATOP");
          void'(exp_maw_q.pop_front());
        end
      end

      // ---- Check downstream W --------------------------------------------
      if (m_wvalid && m_wready) begin
        if (exp_mw_q.size() == 0) begin
          fail("F2/P2", "filtered or otherwise unexpected W beat was forwarded");
        end else begin
          w = exp_mw_q[0];
          if ({m_wdata, m_wstrb, m_wlast, m_wuser} !==
              {w.data, w.strb, w.last, w.user})
            fail("P2", "forwarded W beat was modified or reordered");
          void'(exp_mw_q.pop_front());
        end
      end

      // ---- Check downstream AR -------------------------------------------
      if (m_arvalid && m_arready) begin
        if (exp_mar_q.size() == 0) begin
          fail("P3", "unexpected AR reached master port");
        end else begin
          ar = exp_mar_q[0];
          if ({m_arid, m_araddr, m_arlen, m_arsize, m_arburst,
               m_arlock, m_arcache, m_arprot, m_arqos, m_arregion,
               m_aruser} !==
              {ar.id, ar.addr, ar.len, ar.size, ar.burst, ar.lock,
               ar.cache, ar.prot, ar.qos, ar.region, ar.user})
            fail("P3", "AR field was modified");
          void'(exp_mar_q.pop_front());
        end
      end

      // ---- Capture ordinary downstream responses -------------------------
      if (m_bvalid && m_bready) begin
        b.id = m_bid;
        b.resp = m_bresp;
        b.user = m_buser;
        exp_sb_q.push_back(b);
      end

      if (m_rvalid && m_rready) begin
        rr.id = m_rid;
        rr.data = m_rdata;
        rr.resp = m_rresp;
        rr.last = m_rlast;
        rr.user = m_ruser;
        exp_sr_q.push_back(rr);
      end

      // ---- Check slave B, allowing manufactured/ordinary interleaving ----
      if (s_bvalid && s_bready) begin
        if (filt_active[s_bid] && (filt_b_left[s_bid] > 0)) begin
          if (s_bresp !== 2'b10)
            fail("F3", "manufactured B response was not SLVERR");
          // s_buser is intentionally unconstrained by L2.
          filt_b_left[s_bid] = filt_b_left[s_bid] - 1;
          if ((filt_b_left[s_bid] == 0) &&
              (filt_r_left[s_bid] == 0)) begin
            filt_active[s_bid] = 1'b0;
            filt_count = filt_count - 1;
          end
        end else if (exp_sb_q.size() > 0) begin
          b = exp_sb_q[0];
          if ({s_bid, s_bresp, s_buser} !== {b.id, b.resp, b.user})
            fail("P4", "ordinary B id, resp, or user was modified");
          void'(exp_sb_q.pop_front());
        end else begin
          fail("F3/P4", "unexpected or duplicate B response");
        end
      end

      // ---- Check slave R, attributing manufactured beats by ID -----------
      if (s_rvalid && s_rready) begin
        if (filt_active[s_rid] && (filt_r_left[s_rid] > 0)) begin
          if (s_rresp !== 2'b10)
            fail("F4", "manufactured R response was not SLVERR");

          if (filt_r_left[s_rid] == 1) begin
            if (s_rlast !== 1'b1)
              fail("F4", "final manufactured R beat did not assert RLAST");
          end else begin
            if (s_rlast !== 1'b0)
              fail("F4", "non-final manufactured R beat asserted RLAST");
          end

          // s_rdata and s_ruser are intentionally unconstrained by L2.
          filt_r_left[s_rid] = filt_r_left[s_rid] - 1;
          if ((filt_b_left[s_rid] == 0) &&
              (filt_r_left[s_rid] == 0)) begin
            filt_active[s_rid] = 1'b0;
            filt_count = filt_count - 1;
          end
        end else if (exp_sr_q.size() > 0) begin
          rr = exp_sr_q[0];
          if ({s_rid, s_rdata, s_rresp, s_rlast, s_ruser} !==
              {rr.id, rr.data, rr.resp, rr.last, rr.user})
            fail("P3", "ordinary R beat was modified or reordered");
          void'(exp_sr_q.pop_front());
        end else begin
          fail("F4/F5/P3",
               "unexpected, duplicate, or wrongly attributed R response");
        end
      end

      // ---- W1/W2: downstream write debt ----------------------------------
      debt = debt
             + ((m_awvalid && m_awready) ? 1 : 0)
             - ((m_wvalid && m_wready && m_wlast) ? 1 : 0);
      if (debt > 4)
        fail("W2", "downstream write debt exceeded MAX_WRITE_TXNS (4)");
      if (debt < 0)
        fail("W1/P2", "downstream WLAST made write debt negative");

      // ---- X4: manufactured responses after WLAST ------------------------
      for (k = 0; k < 16; k = k + 1) begin
        if (filt_active[k] && filt_wlast_seen[k]) begin
          if ((filt_b_left[k] > 0) && s_bready &&
              ((tb_cycle - filt_wlast_time[k]) > 64))
            fail("X4/F3", "owed B response exceeded 64-cycle bound");
          if ((filt_r_left[k] > 0) && s_rready &&
              ((tb_cycle - filt_wlast_time[k]) > 64))
            fail("X4/F4", "owed R response exceeded 64-cycle bound");
        end
      end

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

      prev_m_aw_payload = {m_awid, m_awaddr, m_awlen, m_awsize,
                           m_awburst, m_awlock, m_awcache, m_awprot,
                           m_awqos, m_awregion, m_awatop, m_awuser};
      prev_m_w_payload = {m_wdata, m_wstrb, m_wlast, m_wuser};
      prev_m_ar_payload = {m_arid, m_araddr, m_arlen, m_arsize,
                           m_arburst, m_arlock, m_arcache, m_arprot,
                           m_arqos, m_arregion, m_aruser};
      prev_s_b_payload = {s_bid, s_bresp, s_buser};
      prev_s_r_payload = {s_rid, s_rdata, s_rresp, s_rlast, s_ruser};
    end
  end

// ---------------------------------------------------------------------------
// Directed stimulus
// ---------------------------------------------------------------------------

  initial begin : main_test
    bfm_reset(5);
    repeat (2) @(negedge clk);

    // P1/P2/F1/C1: non-atomic because bits [5:4] are 00, despite nonzero
    // low ATOP bits. Exercise every AW field and both values of WUSER.
    aw_cfg = '0;
    aw_cfg.id = 4'h1;
    aw_cfg.addr = 32'h1234_5000;
    aw_cfg.len = 8'd1;
    aw_cfg.size = 3'd2;
    aw_cfg.burst = 2'b01;
    aw_cfg.lock = 1'b1;
    aw_cfg.cache = 4'ha;
    aw_cfg.prot = 3'b101;
    aw_cfg.qos = 4'hc;
    aw_cfg.region = 4'h9;
    aw_cfg.atop = 6'b00_1011;
    aw_cfg.user = 1'b1;
    tb_aw_full(aw_cfg, 64, ok);
    if (!ok) fail("W3/X4", "ordinary AW was not accepted below the debt bound");

    tb_w_full(32'h0123_4567, 4'h5, 1'b0, 1'b1, 64, ok);
    if (!ok) fail("P2/X4", "first ordinary W beat was not accepted");
    tb_w_full(32'h89ab_cdef, 4'ha, 1'b1, 1'b0, 64, ok);
    if (!ok) fail("P2/X4", "last ordinary W beat was not accepted");
    wait_idle(200, "P1/P2/P4");

    // P3/X3: full-field AR and a three-beat read, initially backpressured.
    bfm_r_ready(1'b0);
    ar_cfg = '0;
    ar_cfg.id = 4'h6;
    ar_cfg.addr = 32'h1234_5000; // same address as a write: still just a read
    ar_cfg.len = 8'd2;
    ar_cfg.size = 3'd2;
    ar_cfg.burst = 2'b01;
    ar_cfg.lock = 1'b0;
    ar_cfg.cache = 4'hf;
    ar_cfg.prot = 3'b011;
    ar_cfg.qos = 4'h5;
    ar_cfg.region = 4'h2;
    ar_cfg.user = 1'b1;
    tb_ar_full(ar_cfg, 64, ok);
    if (!ok) fail("P3", "read address was not accepted");
    wait_rvalid(40, "P3");
    repeat (4) @(negedge clk);
    bfm_r_ready(1'b1);
    wait_idle(200, "P3");

    // C1/C2/F2/F3/F5: atomic without a read response, three W beats.
    // Also hold B back to check manufactured-response stability.
    bfm_b_ready(1'b0);
    bfm_aw(4'h8, 32'h2000_0000, 8'd2, 6'b01_0101, 64, ok);
    if (!ok) fail("X4/L4", "atomic-without-read AW was not accepted");
    bfm_w(32'ha000_0000, 4'hf, 1'b0, 64, ok);
    if (!ok) fail("F2/X4", "first filtered W beat was not consumed");
    bfm_w(32'ha000_0001, 4'h3, 1'b0, 64, ok);
    if (!ok) fail("F2/X4", "middle filtered W beat was not consumed");
    bfm_w(32'ha000_0002, 4'hc, 1'b1, 64, ok);
    if (!ok) fail("F2/X4", "last filtered W beat was not consumed");
    wait_bvalid(80);
    repeat (4) @(negedge clk);
    bfm_b_ready(1'b1);
    wait_idle(120, "F3/F5/X4");

    // F4/L1/L5: three manufactured R beats and one B. Delays between W beats
    // permit R responses before WLAST, but do not require that implementation
    // choice. The scoreboard accepts either B/R ordering.
    bfm_aw(4'h9, 32'h3000_0000, 8'd2, 6'b10_0011, 64, ok);
    if (!ok) fail("X4/L4", "atomic-with-read AW was not accepted");
    bfm_w(32'hb000_0000, 4'hf, 1'b0, 64, ok);
    if (!ok) fail("F2/X4", "atomic read-producing W beat 0 stalled");
    repeat (3) @(negedge clk);
    bfm_w(32'hb000_0001, 4'hf, 1'b0, 64, ok);
    if (!ok) fail("F2/X4", "atomic read-producing W beat 1 stalled");
    repeat (2) @(negedge clk);
    bfm_w(32'hb000_0002, 4'hf, 1'b1, 64, ok);
    if (!ok) fail("F2/X4", "atomic read-producing WLAST stalled");
    wait_idle(140, "F3/F4/X4");

    // C2: [5:4]==11 also owes a read response. LEN=0 requires exactly one R,
    // with RLAST. Backpressure checks stability of manufactured R payloads.
    bfm_r_ready(1'b0);
    bfm_aw(4'ha, 32'h3000_1000, 8'd0, 6'b11_1111, 64, ok);
    if (!ok) fail("C2/X4", "ATOP 11 write was not accepted");
    bfm_w(32'hc001_0000, 4'hf, 1'b1, 64, ok);
    if (!ok) fail("F2/X4", "ATOP 11 W beat was not consumed");
    wait_rvalid(80, "F4/X4");
    repeat (4) @(negedge clk);
    bfm_r_ready(1'b1);
    wait_idle(120, "F3/F4/X4");

    // A second filtered transaction is offered while the first one's W burst
    // is still being supplied. The fork avoids requiring an implementation to
    // accept AW2 before it is possible for write 1 to finish.
    bfm_aw(4'hb, 32'h4000_0000, 8'd1, 6'b10_0000, 64, ok);
    if (!ok) fail("X4", "first overlapping filtered AW stalled");
    fork
      begin
        bfm_w(32'hd0b0_0000, 4'hf, 1'b0, 64, ok2);
        if (!ok2) fail("F2/X4", "overlapping write 1 beat 0 stalled");
        repeat (2) @(negedge clk);
        bfm_w(32'hd0b0_0001, 4'hf, 1'b1, 64, ok2);
        if (!ok2) fail("F2/X4", "overlapping write 1 WLAST stalled");
      end
      begin
        bfm_aw(4'hc, 32'h4000_1000, 8'd0, 6'b01_0000, 64, ok3);
        if (!ok3) fail("L4/X4", "second filtered AW exceeded allowed stall");
      end
    join
    bfm_w(32'hd0c0_0000, 4'hf, 1'b1, 64, ok);
    if (!ok) fail("F2/X4", "second filtered write's W beat stalled");
    wait_idle(180, "F3/F4/F5/X4");

    // W5: a run of filtered writes must not consume downstream write debt.
    // Multiple outstanding filtered IDs also check per-write response counts.
    for (j = 0; j < 5; j = j + 1) begin
      bfm_aw(j + 1, 32'h5000_0000, 8'd0, 6'b01_0000, 64, ok);
      if (!ok) fail("W5/X4", "filtered writes incorrectly exhausted write debt");
      bfm_w(32'hd500_0000 + j, 4'hf, 1'b1, 64, ok);
      if (!ok) fail("F2/X4", "filtered stress W beat stalled");
    end
    wait_idle(300, "F3/F5/W5/X4");

    // W4: complete six downstream bursts while their B responses are withheld.
    // Completion of W bursts, not B availability, must keep the bound open.
    bfm_dn_b_lag(200);
    for (j = 0; j < 6; j = j + 1) begin
      bfm_aw(j + 1, 32'h6000_0000 + j*32, 8'd0, 6'b00_0000, 64, ok);
      if (!ok) fail("W3/W4", "unanswered B responses exhausted write capacity");
      bfm_w(32'he000_0000 + j, 4'hf, 1'b1, 64, ok);
      if (!ok) fail("P2/X4", "ordinary W beat stalled in delayed-B test");
    end
    bfm_dn_b_lag(0);
    wait_idle(450, "P4/W4");

    // Build debt deliberately: four AWs and only non-final W beats. Drain all
    // their early B replies before offering a fifth write. Neither a non-final
    // W beat nor a B reply is permitted to reduce the debt.
    for (j = 0; j < 4; j = j + 1) begin
      bfm_aw(j + 1, 32'h7000_0000 + j*32, 8'd1, 6'b00_0000, 64, ok);
      if (!ok) fail("W3/X4", "AW stalled while debt was below four");
    end
    wait_debt_four(80);

    for (j = 0; j < 4; j = j + 1) begin
      bfm_w(32'he100_0000 + j, 4'hf, 1'b0, 64, ok);
      if (!ok) fail("P2/X4", "non-final W beat stalled at full debt");
    end

    wait_normal_bs_drained(100);

    // Reads are not subject to the write bound, even at debt four.
    bfm_ar(4'h7, 32'h7000_8000, 8'd0, 64, ok);
    if (!ok) fail("P3/W", "read traffic was incorrectly limited by write debt");

    // At debt four, either upstream buffering or backpressure is legal. What is
    // not legal is a fifth downstream AW; the W2 monitor checks that directly.
    bfm_aw(4'h5, 32'h7000_0100, 8'd0, 6'b00_0000, 8, ok);
    fifth_taken = ok;
    repeat (4) @(negedge clk);

    // Finish write 1. This is the first event that opens a downstream slot.
    bfm_w(32'he100_1000, 4'hf, 1'b1, 64, ok);
    if (!ok) fail("P2/X4", "WLAST needed to reduce debt was not accepted");

    if (!fifth_taken) begin
      bfm_aw(4'h5, 32'h7000_0100, 8'd0, 6'b00_0000, 64, ok);
      if (!ok) fail("W3/X4", "fifth AW remained stalled after WLAST reduced debt");
      fifth_taken = 1'b1;
    end

    for (j = 1; j < 4; j = j + 1) begin
      bfm_w(32'he100_1000 + j, 4'hf, 1'b1, 64, ok);
      if (!ok) fail("P2/X4", "remaining debt-test WLAST stalled");
    end
    bfm_w(32'he100_5000, 4'hf, 1'b1, 64, ok);
    if (!ok) fail("P2/X4", "fifth write's W beat stalled");
    wait_idle(300, "W2/W3/W4/P4");

    // X1/X2: present traffic while reset is low, withdraw it before release,
    // and verify that no request or response survives reset.
    @(negedge clk);
    rst_n = 1'b0;
    @(negedge clk);
    s_awid = 4'he;
    s_awaddr = 32'hdead_0000;
    s_awlen = 8'd0;
    s_awatop = 6'b10_0000;
    s_awvalid = 1'b1;
    s_wdata = 32'hdead_beef;
    s_wstrb = 4'hf;
    s_wlast = 1'b1;
    s_wvalid = 1'b1;
    s_arid = 4'hf;
    s_araddr = 32'hdead_1000;
    s_arlen = 8'd0;
    s_arvalid = 1'b1;
    repeat (2) @(negedge clk);
    s_awvalid = 1'b0;
    s_wvalid = 1'b0;
    s_arvalid = 1'b0;
    repeat (2) @(negedge clk);
    rst_n = 1'b1;
    repeat (16) @(negedge clk);

    if (!all_idle())
      fail("X2", "traffic presented during reset survived reset release");

    // Catch late duplicate manufactured responses before returning a verdict.
    repeat (20) @(negedge clk);
    if (!all_idle())
      fail("F3/F4/F5", "extra traffic remained at end of test");

    $display("RESULT: PASS");
    $finish;
  end

endmodule
