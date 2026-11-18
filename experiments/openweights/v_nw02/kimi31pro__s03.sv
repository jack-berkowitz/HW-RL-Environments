`timescale 1ns/1ps

module atop_filter_tb;

// ---------------------------------------------------------------------------
// PROVIDED PLUMBING -- moves transactions, checks nothing.
// ---------------------------------------------------------------------------

  // ---- clock ---------------------------------------------------------------
  logic clk = 1'b0;
  always #5 clk = ~clk;

  int bfm_cycle = 0;
  always @(posedge clk) if (rst_n) bfm_cycle <= bfm_cycle + 1;

  // ---- reset ---------------------------------------------------------------
  logic rst_n = 1'b0;

  task automatic bfm_reset(input int cycles = 5);
    @(negedge clk);
    rst_n = 1'b0;
    repeat (cycles) @(posedge clk);
    @(negedge clk);
    rst_n = 1'b1;
  endtask

  // ---- the signals, and the design under test ------------------------------
  logic [3:0]     s_awid;
  logic [31:0]    s_awaddr;
  logic [7:0]     s_awlen;
  logic [2:0]     s_awsize;
  logic [1:0]     s_awburst;
  logic           s_awlock;
  logic [3:0]     s_awcache;
  logic [2:0]     s_awprot;
  logic [3:0]     s_awqos;
  logic [3:0]     s_awregion;
  logic [5:0]     s_awatop;
  logic           s_awuser;
  logic           s_awvalid;
  logic           s_awready;
  logic [31:0]    s_wdata;
  logic [3:0]     s_wstrb;
  logic           s_wlast;
  logic           s_wuser;
  logic           s_wvalid;
  logic           s_wready;
  logic [3:0]     s_bid;
  logic [1:0]     s_bresp;
  logic           s_buser;
  logic           s_bvalid;
  logic           s_bready;
  logic [3:0]     s_arid;
  logic [31:0]    s_araddr;
  logic [7:0]     s_arlen;
  logic [2:0]     s_arsize;
  logic [1:0]     s_arburst;
  logic           s_arlock;
  logic [3:0]     s_arcache;
  logic [2:0]     s_arprot;
  logic [3:0]     s_arqos;
  logic [3:0]     s_arregion;
  logic           s_aruser;
  logic           s_arvalid;
  logic           s_arready;
  logic [3:0]     s_rid;
  logic [31:0]    s_rdata;
  logic [1:0]     s_rresp;
  logic           s_rlast;
  logic           s_ruser;
  logic           s_rvalid;
  logic           s_rready;
  logic [3:0]     m_awid;
  logic [31:0]    m_awaddr;
  logic [7:0]     m_awlen;
  logic [2:0]     m_awsize;
  logic [1:0]     m_awburst;
  logic           m_awlock;
  logic [3:0]     m_awcache;
  logic [2:0]     m_awprot;
  logic [3:0]     m_awqos;
  logic [3:0]     m_awregion;
  logic [5:0]     m_awatop;
  logic           m_awuser;
  logic           m_awvalid;
  logic           m_awready;
  logic [31:0]    m_wdata;
  logic [3:0]     m_wstrb;
  logic           m_wlast;
  logic           m_wuser;
  logic           m_wvalid;
  logic           m_wready;
  logic [3:0]     m_bid;
  logic [1:0]     m_bresp;
  logic           m_buser;
  logic           m_bvalid;
  logic           m_bready;
  logic [3:0]     m_arid;
  logic [31:0]    m_araddr;
  logic [7:0]     m_arlen;
  logic [2:0]     m_arsize;
  logic [1:0]     m_arburst;
  logic           m_arlock;
  logic [3:0]     m_arcache;
  logic [2:0]     m_arprot;
  logic [3:0]     m_arqos;
  logic [3:0]     m_arregion;
  logic           m_aruser;
  logic           m_arvalid;
  logic           m_arready;
  logic [3:0]     m_rid;
  logic [31:0]    m_rdata;
  logic [1:0]     m_rresp;
  logic           m_rlast;
  logic           m_ruser;
  logic           m_rvalid;
  logic           m_rready;

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

  // ---- upstream tasks ------------------------------------------------------
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
                        input logic [7:0] len, input int timeout,
                        output bit accepted);
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

  // ---- downstream subordinate ---------------------------------------------
  int bfm_b_lag = 0;
  task automatic bfm_dn_b_lag(input int cycles); bfm_b_lag = cycles; endtask

  int bfm_bq_id [$], bfm_bq_t [$], bfm_rq_id [$], bfm_rq_n [$];

  // These controls leave the default plumbing behaviour unchanged, while
  // allowing directed backpressure, non-default response payloads, and reset
  // pass-through tests.
  bit bfm_m_awready = 1'b1;
  bit bfm_m_wready  = 1'b1;
  bit bfm_m_arready = 1'b1;

  logic [1:0] bfm_bresp;
  logic       bfm_buser;
  logic [1:0] bfm_rresp;
  logic       bfm_ruser;

  bit         bfm_inj_bvalid;
  logic [3:0] bfm_inj_bid;
  logic [1:0] bfm_inj_bresp;
  logic       bfm_inj_buser;
  bit         bfm_inj_rvalid;
  logic [3:0] bfm_inj_rid;
  logic [31:0] bfm_inj_rdata;
  logic [1:0] bfm_inj_rresp;
  logic       bfm_inj_rlast;
  logic       bfm_inj_ruser;

  assign m_awready = bfm_m_awready;
  assign m_wready  = bfm_m_wready;
  assign m_arready = bfm_m_arready;

  always @(posedge clk) begin
    if (!rst_n) begin
      bfm_bq_id.delete(); bfm_bq_t.delete();
      bfm_rq_id.delete(); bfm_rq_n.delete();
    end else begin
      if (m_awvalid && m_awready) begin
        bfm_bq_id.push_back(int'(m_awid));
        bfm_bq_t.push_back(bfm_cycle + bfm_b_lag);
      end
      if (m_arvalid && m_arready) begin
        bfm_rq_id.push_back(int'(m_arid));
        bfm_rq_n.push_back(int'(m_arlen) + 1);
      end
      if (m_bvalid && m_bready && bfm_bq_id.size() > 0) begin
        void'(bfm_bq_id.pop_front());
        void'(bfm_bq_t.pop_front());
      end
      if (m_rvalid && m_rready && bfm_rq_id.size() > 0) begin
        if (bfm_rq_n[0] <= 1) begin
          void'(bfm_rq_id.pop_front());
          void'(bfm_rq_n.pop_front());
        end else begin
          bfm_rq_n[0] = bfm_rq_n[0] - 1;
        end
      end
    end
  end

  always_comb begin
    m_bvalid = bfm_inj_bvalid ||
               ((bfm_bq_id.size() > 0) && (bfm_cycle >= bfm_bq_t[0]));
    m_bid    = bfm_inj_bvalid ? bfm_inj_bid :
               4'(bfm_bq_id.size() ? bfm_bq_id[0] : 0);
    m_bresp  = bfm_inj_bvalid ? bfm_inj_bresp : bfm_bresp;
    m_buser  = bfm_inj_bvalid ? bfm_inj_buser : bfm_buser;

    m_rvalid = bfm_inj_rvalid || (bfm_rq_id.size() > 0);
    m_rid    = bfm_inj_rvalid ? bfm_inj_rid :
               4'(bfm_rq_id.size() ? bfm_rq_id[0] : 0);
    m_rdata  = bfm_inj_rvalid ? bfm_inj_rdata :
               32'hFEED_0000 + 32'(bfm_rq_n.size() ? bfm_rq_n[0] : 0);
    m_rresp  = bfm_inj_rvalid ? bfm_inj_rresp : bfm_rresp;
    m_ruser  = bfm_inj_rvalid ? bfm_inj_ruser : bfm_ruser;
    m_rlast  = bfm_inj_rvalid ? bfm_inj_rlast :
               ((bfm_rq_id.size() > 0) && (bfm_rq_n[0] <= 1));
  end

  // ---- idle the upstream request signals at time zero ----------------------
  initial begin
    s_awvalid = 1'b0; s_wvalid = 1'b0; s_arvalid = 1'b0;
    s_bready  = 1'b1; s_rready = 1'b1;
    s_awid = '0; s_awaddr = '0; s_awlen = '0; s_awsize = 3'd2;
    s_awburst = 2'd1; s_awlock = 1'b0; s_awcache = '0; s_awprot = '0;
    s_awqos = '0; s_awregion = '0; s_awatop = '0; s_awuser = 1'b0;
    s_wdata = '0; s_wstrb = 4'hF; s_wlast = 1'b0; s_wuser = 1'b0;
    s_arid = '0; s_araddr = '0; s_arlen = '0; s_arsize = 3'd2;
    s_arburst = 2'd1; s_arlock = 1'b0; s_arcache = '0; s_arprot = '0;
    s_arqos = '0; s_arregion = '0; s_aruser = 1'b0;
  end

  // ---- watchdog ------------------------------------------------------------
  initial begin
    #4_000_000;
    $display("RESULT: FAIL (watchdog: no forward progress)");
    $finish;
  end

// ---------------------------------------------------------------------------
// Testbench records, scoreboard, and protocol checks.
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
  } aw_rec_t;

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
    logic [31:0] data;
    logic [3:0]  strb;
    logic        last;
    logic        user;
  } w_rec_t;

  aw_rec_t exp_maw[$];
  ar_rec_t exp_mar[$];
  w_rec_t  exp_mw[$];

  bit        up_atomic_q[$];
  bit        up_read_q[$];
  logic [3:0] up_id_q[$];

  int man_b_due[16];
  int man_r_due[16];
  int man_deadline[16];
  bit man_deadline_en[16];

  int downstream_debt;
  bit liveness_check_en;
  bit finished = 1'b0;

  aw_rec_t aw_tmp;
  ar_rec_t ar_tmp;
  integer mi;

  logic [127:0] maw_pay, mar_pay, mw_pay, sb_pay, sr_pay;
  logic [127:0] prev_maw_pay, prev_mar_pay, prev_mw_pay;
  logic [127:0] prev_sb_pay, prev_sr_pay;
  bit prev_maw_valid, prev_maw_ready;
  bit prev_mw_valid, prev_mw_ready;
  bit prev_mar_valid, prev_mar_ready;
  bit prev_sb_valid, prev_sb_ready;
  bit prev_sr_valid, prev_sr_ready;
  bit prev_rst_n;

  always_comb begin
    maw_pay = {m_awid, m_awaddr, m_awlen, m_awsize, m_awburst, m_awlock,
               m_awcache, m_awprot, m_awqos, m_awregion, m_awatop, m_awuser};
    mar_pay = {m_arid, m_araddr, m_arlen, m_arsize, m_arburst, m_arlock,
               m_arcache, m_arprot, m_arqos, m_arregion, m_aruser};
    mw_pay  = {m_wdata, m_wstrb, m_wlast, m_wuser};
    sb_pay  = {s_bid, s_bresp, s_buser};
    sr_pay  = {s_rid, s_rdata, s_rresp, s_rlast, s_ruser};
  end

  task automatic tb_fail(input string clause, input string detail);
    begin
      if (!finished) begin
        finished = 1'b1;
        $display("Violation %s at cycle %0d: %s", clause, bfm_cycle, detail);
        $display("RESULT: FAIL");
        $finish;
      end
    end
  endtask

  function automatic aw_rec_t get_saw();
    aw_rec_t a;
    begin
      a.id = s_awid; a.addr = s_awaddr; a.len = s_awlen; a.size = s_awsize;
      a.burst = s_awburst; a.lock = s_awlock; a.cache = s_awcache;
      a.prot = s_awprot; a.qos = s_awqos; a.region = s_awregion;
      a.atop = s_awatop; a.user = s_awuser;
      get_saw = a;
    end
  endfunction

  function automatic aw_rec_t get_maw();
    aw_rec_t a;
    begin
      a.id = m_awid; a.addr = m_awaddr; a.len = m_awlen; a.size = m_awsize;
      a.burst = m_awburst; a.lock = m_awlock; a.cache = m_awcache;
      a.prot = m_awprot; a.qos = m_awqos; a.region = m_awregion;
      a.atop = m_awatop; a.user = m_awuser;
      get_maw = a;
    end
  endfunction

  function automatic ar_rec_t get_sar();
    ar_rec_t a;
    begin
      a.id = s_arid; a.addr = s_araddr; a.len = s_arlen; a.size = s_arsize;
      a.burst = s_arburst; a.lock = s_arlock; a.cache = s_arcache;
      a.prot = s_arprot; a.qos = s_arqos; a.region = s_arregion;
      a.user = s_aruser;
      get_sar = a;
    end
  endfunction

  function automatic ar_rec_t get_mar();
    ar_rec_t a;
    begin
      a.id = m_arid; a.addr = m_araddr; a.len = m_arlen; a.size = m_arsize;
      a.burst = m_arburst; a.lock = m_arlock; a.cache = m_arcache;
      a.prot = m_arprot; a.qos = m_arqos; a.region = m_arregion;
      a.user = m_aruser;
      get_mar = a;
    end
  endfunction

  function automatic w_rec_t get_sw();
    w_rec_t w;
    begin
      w.data = s_wdata; w.strb = s_wstrb; w.last = s_wlast; w.user = s_wuser;
      get_sw = w;
    end
  endfunction

  function automatic w_rec_t get_mw();
    w_rec_t w;
    begin
      w.data = m_wdata; w.strb = m_wstrb; w.last = m_wlast; w.user = m_wuser;
      get_mw = w;
    end
  endfunction

  function automatic aw_rec_t mk_aw(input logic [3:0] id,
                                    input logic [31:0] addr,
                                    input logic [7:0] len,
                                    input logic [5:0] atop);
    aw_rec_t a;
    begin
      a.id = id; a.addr = addr; a.len = len; a.size = 3'd3;
      a.burst = 2'b01; a.lock = (atop[5:4] == 2'b00);
      a.cache = 4'hA; a.prot = 3'h5; a.qos = 4'hC; a.region = 4'h9;
      a.atop = atop; a.user = 1'b1;
      mk_aw = a;
    end
  endfunction

  function automatic ar_rec_t mk_ar(input logic [3:0] id,
                                    input logic [31:0] addr,
                                    input logic [7:0] len);
    ar_rec_t a;
    begin
      a.id = id; a.addr = addr; a.len = len; a.size = 3'd3;
      a.burst = 2'b01; a.lock = 1'b1; a.cache = 4'h6; a.prot = 3'h3;
      a.qos = 4'hB; a.region = 4'h7; a.user = 1'b1;
      mk_ar = a;
    end
  endfunction

  function automatic w_rec_t mk_w(input logic [31:0] data,
                                  input logic [3:0] strb,
                                  input bit last,
                                  input bit user);
    w_rec_t w;
    begin
      w.data = data; w.strb = strb; w.last = last; w.user = user;
      mk_w = w;
    end
  endfunction

  task automatic tb_aw(input aw_rec_t a, input int timeout,
                       output bit accepted);
    int t;
    begin
      @(negedge clk);
      s_awid = a.id; s_awaddr = a.addr; s_awlen = a.len; s_awsize = a.size;
      s_awburst = a.burst; s_awlock = a.lock; s_awcache = a.cache;
      s_awprot = a.prot; s_awqos = a.qos; s_awregion = a.region;
      s_awatop = a.atop; s_awuser = a.user;
      s_awvalid = 1'b1;
      accepted = 1'b0;
      for (t = 0; t < timeout; t++) begin
        @(posedge clk);
        if (s_awready) begin accepted = 1'b1; break; end
      end
      @(negedge clk);
      s_awvalid = 1'b0;
    end
  endtask

  task automatic tb_w(input w_rec_t w, input int timeout,
                      output bit accepted);
    int t;
    begin
      @(negedge clk);
      s_wdata = w.data; s_wstrb = w.strb; s_wlast = w.last; s_wuser = w.user;
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

  task automatic tb_ar(input ar_rec_t a, input int timeout,
                       output bit accepted);
    int t;
    begin
      @(negedge clk);
      s_arid = a.id; s_araddr = a.addr; s_arlen = a.len; s_arsize = a.size;
      s_arburst = a.burst; s_arlock = a.lock; s_arcache = a.cache;
      s_arprot = a.prot; s_arqos = a.qos; s_arregion = a.region;
      s_aruser = a.user;
      s_arvalid = 1'b1;
      accepted = 1'b0;
      for (t = 0; t < timeout; t++) begin
        @(posedge clk);
        if (s_arready) begin accepted = 1'b1; break; end
      end
      @(negedge clk);
      s_arvalid = 1'b0;
    end
  endtask

  function automatic bit manufactured_clear();
    integer i;
    begin
      manufactured_clear = 1'b1;
      for (i = 0; i < 16; i = i + 1) begin
        if (man_b_due[i] != 0 || man_r_due[i] != 0)
          manufactured_clear = 1'b0;
      end
    end
  endfunction

  function automatic bit all_quiet();
    begin
      all_quiet = (exp_maw.size() == 0) && (exp_mw.size() == 0) &&
                  (exp_mar.size() == 0) && (up_atomic_q.size() == 0) &&
                  (bfm_bq_id.size() == 0) && (bfm_rq_id.size() == 0) &&
                  manufactured_clear();
    end
  endfunction

  task automatic drain_all(input int timeout);
    int t;
    bit seen;
    begin
      seen = 1'b0;
      for (t = 0; t < timeout; t++) begin
        @(posedge clk);
        if (all_quiet()) begin seen = 1'b1; break; end
      end
      if (!seen) begin
        if (exp_maw.size() != 0)
          tb_fail("P1/W3", "a forwarded AW is missing or was not accepted");
        else if (exp_mw.size() != 0)
          tb_fail("P2", "a forwarded W beat is missing");
        else if (exp_mar.size() != 0)
          tb_fail("P3", "a forwarded AR is missing");
        else if (!manufactured_clear())
          tb_fail("F3/F4/X4", "manufactured responses are missing");
        else if (bfm_bq_id.size() != 0)
          tb_fail("P4", "a downstream B response was not returned");
        else if (bfm_rq_id.size() != 0)
          tb_fail("P3", "downstream R beats were not returned");
        else
          tb_fail("P2/X4", "write traffic did not drain");
      end
      // A response in excess of the exact manufactured count is visible here.
      repeat (4) @(posedge clk);
    end
  endtask

  task automatic wait_manufactured_clear(input int timeout);
    int t;
    bit seen;
    begin
      seen = 1'b0;
      for (t = 0; t < timeout; t++) begin
        @(posedge clk);
        if (manufactured_clear()) begin seen = 1'b1; break; end
      end
      if (!seen)
        tb_fail("F3/F4/X4", "filtered-write responses did not complete");
    end
  endtask

  task automatic wait_downstream_quiet(input int timeout);
    int t;
    bit seen;
    begin
      seen = 1'b0;
      for (t = 0; t < timeout; t++) begin
        @(posedge clk);
        if (bfm_bq_id.size() == 0 && bfm_rq_id.size() == 0) begin
          seen = 1'b1;
          break;
        end
      end
      if (!seen)
        tb_fail("P3/P4", "downstream responses did not drain");
    end
  endtask

  // Main monitor. Upstream handshakes are processed before downstream ones so
  // that a combinational pass-through transfer can be checked in the same cycle.
  always @(posedge clk) begin
    if (m_awvalid && m_awatop !== 6'b000000)
      tb_fail("F1", "m_awatop_o is nonzero while m_awvalid_o is asserted");

    // These tests never deliberately mix a downstream response with a
    // manufactured response, so the required pass-through can be checked
    // directly and without imposing an ordering on manufactured channels.
    if (m_bvalid) begin
      if (s_bvalid !== 1'b1)
        tb_fail("P4/X1", "a master-port B response is not forwarded");
      else if ({s_bid, s_bresp, s_buser} !== {m_bid, m_bresp, m_buser})
        tb_fail("P4", "B id, resp, or user was altered");
    end
    if (m_rvalid) begin
      if (s_rvalid !== 1'b1)
        tb_fail("P3/X1", "a master-port R beat is not forwarded");
      else if ({s_rid, s_rdata, s_rresp, s_rlast, s_ruser} !==
               {m_rid, m_rdata, m_rresp, m_rlast, m_ruser})
        tb_fail("P3", "an R beat was altered");
    end

    if (!rst_n) begin
      if (m_awvalid !== 1'b0 || m_wvalid !== 1'b0)
        tb_fail("X1", "AW or W valid is asserted while reset is low");
      if (!m_bvalid && s_bvalid !== 1'b0)
        tb_fail("X1", "a manufactured B response is present during reset");
      if (!m_rvalid && s_rvalid !== 1'b0)
        tb_fail("X1", "a manufactured R response is present during reset");

      exp_maw.delete(); exp_mw.delete(); exp_mar.delete();
      up_atomic_q.delete(); up_read_q.delete(); up_id_q.delete();
      downstream_debt = 0;
      for (mi = 0; mi < 16; mi = mi + 1) begin
        man_b_due[mi] = 0;
        man_r_due[mi] = 0;
        man_deadline[mi] = 0;
        man_deadline_en[mi] = 1'b0;
      end
      prev_maw_valid = 1'b0;
      prev_mw_valid = 1'b0;
      prev_mar_valid = 1'b0;
      prev_sb_valid = 1'b0;
      prev_sr_valid = 1'b0;
      prev_rst_n = 1'b0;
    end else begin
      // X3: valid and payload persist throughout backpressure.
      if (prev_rst_n) begin
        if (prev_maw_valid && !prev_maw_ready) begin
          if (m_awvalid !== 1'b1 || maw_pay !== prev_maw_pay)
            tb_fail("X3", "m_awvalid or its payload changed before ready");
        end
        if (prev_mw_valid && !prev_mw_ready) begin
          if (m_wvalid !== 1'b1 || mw_pay !== prev_mw_pay)
            tb_fail("X3", "m_wvalid or its payload changed before ready");
        end
        if (prev_mar_valid && !prev_mar_ready) begin
          if (m_arvalid !== 1'b1 || mar_pay !== prev_mar_pay)
            tb_fail("X3", "m_arvalid or its payload changed before ready");
        end
        if (prev_sb_valid && !prev_sb_ready) begin
          if (s_bvalid !== 1'b1 || sb_pay !== prev_sb_pay)
            tb_fail("X3", "s_bvalid or its payload changed before ready");
        end
        if (prev_sr_valid && !prev_sr_ready) begin
          if (s_rvalid !== 1'b1 || sr_pay !== prev_sr_pay)
            tb_fail("X3", "s_rvalid or its payload changed before ready");
        end
      end

      if (s_awvalid && s_awready) begin
        aw_tmp = get_saw();
        up_atomic_q.push_back(aw_tmp.atop[5:4] != 2'b00);
        up_read_q.push_back(aw_tmp.atop[5]);
        up_id_q.push_back(aw_tmp.id);

        if (aw_tmp.atop[5:4] == 2'b00) begin
          aw_tmp.atop = 6'b000000;
          exp_maw.push_back(aw_tmp);
        end else begin
          man_b_due[aw_tmp.id] = 1;
          man_r_due[aw_tmp.id] = aw_tmp.atop[5] ? (int'(aw_tmp.len) + 1) : 0;
          man_deadline_en[aw_tmp.id] = 1'b0;
        end
      end

      if (s_wvalid && s_wready) begin
        if (up_atomic_q.size() == 0) begin
          tb_fail("P2/F2", "a W beat transferred without an accepted AW");
        end else begin
          if (!up_atomic_q[0])
            exp_mw.push_back(get_sw());
          if (s_wlast) begin
            if (up_atomic_q[0]) begin
              man_deadline[up_id_q[0]] = bfm_cycle + 64;
              man_deadline_en[up_id_q[0]] = 1'b1;
            end
            void'(up_atomic_q.pop_front());
            void'(up_read_q.pop_front());
            void'(up_id_q.pop_front());
          end
        end
      end

      if (s_arvalid && s_arready)
        exp_mar.push_back(get_sar());

      if (m_awvalid && m_awready) begin
        downstream_debt = downstream_debt + 1;
        if (exp_maw.size() == 0) begin
          tb_fail("F1/P1", "an atomic or otherwise unexpected AW was forwarded");
        end else begin
          if (get_maw() !== exp_maw[0])
            tb_fail("P1/F1", "forwarded AW fields differ from the non-atomic AW");
          void'(exp_maw.pop_front());
        end
      end

      if (m_wvalid && m_wready) begin
        if (exp_mw.size() == 0) begin
          tb_fail("F2/P2", "a filtered or otherwise unexpected W beat was forwarded");
        end else begin
          if (get_mw() !== exp_mw[0])
            tb_fail("P2", "W data, strb, user, order, or last was altered");
          void'(exp_mw.pop_front());
        end
        if (m_wlast)
          downstream_debt = downstream_debt - 1;
      end

      if (downstream_debt > 4)
        tb_fail("W2/W4", "downstream write debt exceeded four");
      if (downstream_debt < 0)
        tb_fail("W1/P2", "downstream write debt became negative");

      if (m_arvalid && m_arready) begin
        if (exp_mar.size() == 0) begin
          tb_fail("P3", "an unexpected AR was forwarded");
        end else begin
          if (get_mar() !== exp_mar[0])
            tb_fail("P3", "one or more AR fields were altered");
          void'(exp_mar.pop_front());
        end
      end

      if (s_bvalid && s_bready && !m_bvalid) begin
        if (man_b_due[s_bid] != 1) begin
          tb_fail("F3", "unexpected, duplicate, or wrongly identified manufactured B");
        end else begin
          if (s_bresp !== 2'b10)
            tb_fail("F3", "manufactured B response is not SLVERR");
          man_b_due[s_bid] = 0;
        end
      end

      if (s_rvalid && s_rready && !m_rvalid) begin
        if (man_r_due[s_rid] <= 0) begin
          tb_fail("F4/F5", "unexpected or excess manufactured R beat");
        end else begin
          if (s_rresp !== 2'b10)
            tb_fail("F4", "manufactured R response is not SLVERR");
          if (s_rlast !== (man_r_due[s_rid] == 1))
            tb_fail("F4", "s_rlast_o is not asserted only on the final owed beat");
          man_r_due[s_rid] = man_r_due[s_rid] - 1;
        end
      end

      for (mi = 0; mi < 16; mi = mi + 1) begin
        if (man_b_due[mi] == 0 && man_r_due[mi] == 0)
          man_deadline_en[mi] = 1'b0;
        else if (liveness_check_en && man_deadline_en[mi] &&
                 bfm_cycle > man_deadline[mi])
          tb_fail("X4", $sformatf(
                  "filtered write id %0d still owes B=%0d R=%0d after 64 cycles",
                  mi, man_b_due[mi], man_r_due[mi]));
      end

      prev_maw_valid = m_awvalid;
      prev_maw_ready = m_awready;
      prev_maw_pay = maw_pay;
      prev_mw_valid = m_wvalid;
      prev_mw_ready = m_wready;
      prev_mw_pay = mw_pay;
      prev_mar_valid = m_arvalid;
      prev_mar_ready = m_arready;
      prev_mar_pay = mar_pay;
      prev_sb_valid = s_bvalid;
      prev_sb_ready = s_bready;
      prev_sb_pay = sb_pay;
      prev_sr_valid = s_rvalid;
      prev_sr_ready = s_rready;
      prev_sr_pay = sr_pay;
      prev_rst_n = 1'b1;
    end
  end

// ---------------------------------------------------------------------------
// Directed tests.
// ---------------------------------------------------------------------------

  task automatic test_pass_through();
    bit ok;
    int i;
    begin
      bfm_dn_b_lag(0);

      // Low ATOP bits are nonzero, but [5:4]==00: this is not atomic.
      tb_aw(mk_aw(4'h1, 32'h1000_0040, 8'd2, 6'b00_1010), 70, ok);
      if (!ok) tb_fail("W3/X4", "non-atomic AW was not accepted below the bound");
      tb_w(mk_w(32'hA0A0_0001, 4'h1, 1'b0, 1'b1), 70, ok);
      if (!ok) tb_fail("P2/X4", "first ordinary W beat was not accepted");
      tb_w(mk_w(32'hB1B1_0002, 4'h6, 1'b0, 1'b0), 70, ok);
      if (!ok) tb_fail("P2/X4", "second ordinary W beat was not accepted");
      tb_w(mk_w(32'hC2C2_0003, 4'hF, 1'b1, 1'b1), 70, ok);
      if (!ok) tb_fail("P2/X4", "last ordinary W beat was not accepted");

      tb_aw(mk_aw(4'h2, 32'h2000_0080, 8'd0, 6'b00_1111), 70, ok);
      if (!ok) tb_fail("C1/W3", "AW with only low ATOP bits set was stalled");
      tb_w(mk_w(32'h1234_5678, 4'h9, 1'b1, 1'b0), 70, ok);
      if (!ok) tb_fail("P2/X4", "ordinary single-beat write stalled");

      // Same address space as later filtered writes: reads are never filtered.
      tb_ar(mk_ar(4'h9, 32'hDEAD_0000, 8'd2), 70, ok);
      if (!ok) tb_fail("P3", "ordinary AR was not accepted");
      drain_all(300);

      // Hold R back so that more than four reads are outstanding. The write
      // bound must not be reused as a read bound.
      bfm_r_ready(1'b0);
      for (i = 0; i < 6; i = i + 1) begin
        tb_ar(mk_ar(4'(i), 32'h5000_0000 + i * 32'h20, 8'd0), 70, ok);
        if (!ok) tb_fail("P3/W", "read traffic was stalled by a write-style bound");
      end
      bfm_r_ready(1'b1);
      drain_all(300);
    end
  endtask

  task automatic test_filtering();
    bit ok;
    begin
      // 01: atomic, but no read response. Three W beats test consumption
      // through and including WLAST.
      tb_aw(mk_aw(4'h4, 32'hDEAD_0000, 8'd2, 6'b01_0101), 70, ok);
      if (!ok) tb_fail("C1/X4", "01 atomic AW was not accepted");
      tb_w(mk_w(32'h1111_0001, 4'hF, 1'b0, 1'b1), 70, ok);
      if (!ok) tb_fail("F2/X4", "first filtered W beat was not consumed");
      tb_w(mk_w(32'h2222_0002, 4'h3, 1'b0, 1'b0), 70, ok);
      if (!ok) tb_fail("F2/X4", "middle filtered W beat was not consumed");
      tb_w(mk_w(32'h3333_0003, 4'hC, 1'b1, 1'b1), 70, ok);
      if (!ok) tb_fail("F2/X4", "last filtered W beat was not consumed");

      // 10: one B and exactly one R. The pause permits a compliant design to
      // manufacture either response before the W burst.
      tb_aw(mk_aw(4'h5, 32'hDEAD_1000, 8'd0, 6'b10_0011), 70, ok);
      if (!ok) tb_fail("C1/X4", "10 atomic AW was not accepted");
      repeat (2) @(posedge clk);
      tb_w(mk_w(32'h4444_0004, 4'hF, 1'b1, 1'b0), 70, ok);
      if (!ok) tb_fail("F2/X4", "10 atomic W beat was not consumed");

      // 11 also owes a read response. LEN=3 requires four R beats.
      tb_aw(mk_aw(4'h6, 32'hDEAD_2000, 8'd3, 6'b11_1100), 70, ok);
      if (!ok) tb_fail("C1/X4", "11 atomic AW was not accepted");
      repeat (3) @(posedge clk);
      tb_w(mk_w(32'h5555_0005, 4'h1, 1'b0, 1'b0), 70, ok);
      if (!ok) tb_fail("F2/X4", "11 atomic W beat zero was not consumed");
      tb_w(mk_w(32'h6666_0006, 4'h2, 1'b0, 1'b1), 70, ok);
      if (!ok) tb_fail("F2/X4", "11 atomic W beat one was not consumed");
      tb_w(mk_w(32'h7777_0007, 4'h4, 1'b0, 1'b0), 70, ok);
      if (!ok) tb_fail("F2/X4", "11 atomic W beat two was not consumed");
      tb_w(mk_w(32'h8888_0008, 4'h8, 1'b1, 1'b1), 70, ok);
      if (!ok) tb_fail("F2/X4", "11 atomic WLAST was not consumed");

      // Responses from IDs 4, 5, and 6 may be interleaved. The scoreboard
      // attributes every R solely by RID and imposes no B/R ordering.
      drain_all(400);
    end
  endtask

  task automatic test_backpressure();
    bit ok;
    begin
      // Manufactured responses are held back briefly. No latency other than
      // the X4 bound is assumed, and no particular B/R order is required.
      @(negedge clk);
      liveness_check_en = 1'b0;
      bfm_b_ready(1'b0);
      bfm_r_ready(1'b0);
      tb_aw(mk_aw(4'h8, 32'h8000_0000, 8'd1, 6'b10_0000), 70, ok);
      if (!ok) tb_fail("X4", "atomic AW stalled under response backpressure");
      tb_w(mk_w(32'hAAAA_0001, 4'hF, 1'b0, 1'b1), 70, ok);
      if (!ok) tb_fail("F2/X4", "filtered W beat stalled under backpressure");
      tb_w(mk_w(32'hBBBB_0002, 4'hF, 1'b1, 1'b0), 70, ok);
      if (!ok) tb_fail("F2/X4", "filtered WLAST stalled under backpressure");
      repeat (4) @(posedge clk);
      bfm_b_ready(1'b1);
      bfm_r_ready(1'b1);
      drain_all(300);
      @(negedge clk);
      liveness_check_en = 1'b1;

      // Pass-through B stability.
      bfm_b_ready(1'b0);
      tb_aw(mk_aw(4'h9, 32'h9000_0000, 8'd0, 6'b00_0000), 70, ok);
      if (!ok) tb_fail("P1/W3", "ordinary AW stalled");
      tb_w(mk_w(32'h9999_0001, 4'hF, 1'b1, 1'b1), 70, ok);
      if (!ok) tb_fail("P2", "ordinary W stalled");
      repeat (4) @(posedge clk);
      bfm_b_ready(1'b1);
      drain_all(300);

      // Pass-through R stability.
      bfm_r_ready(1'b0);
      tb_ar(mk_ar(4'hA, 32'hA000_0000, 8'd1), 70, ok);
      if (!ok) tb_fail("P3", "ordinary AR stalled");
      repeat (4) @(posedge clk);
      bfm_r_ready(1'b1);
      drain_all(300);

      // Exercise output-valid stability on all three downstream request
      // channels. Either combinational or registered ready is acceptable.
      @(negedge clk);
      bfm_m_awready = 1'b0;
      fork
        tb_aw(mk_aw(4'hB, 32'hB000_0000, 8'd0, 6'b00_0000), 30, ok);
        begin
          repeat (4) @(posedge clk);
          @(negedge clk);
          bfm_m_awready = 1'b1;
        end
      join
      if (!ok) tb_fail("P1/X3", "AW did not transfer after downstream ready");

      @(negedge clk);
      bfm_m_wready = 1'b0;
      fork
        tb_w(mk_w(32'hBBBB_0001, 4'h5, 1'b1, 1'b1), 30, ok);
        begin
          repeat (4) @(posedge clk);
          @(negedge clk);
          bfm_m_wready = 1'b1;
        end
      join
      if (!ok) tb_fail("P2/X3", "W did not transfer after downstream ready");

      @(negedge clk);
      bfm_m_arready = 1'b0;
      fork
        tb_ar(mk_ar(4'hC, 32'hC000_0000, 8'd0), 30, ok);
        begin
          repeat (4) @(posedge clk);
          @(negedge clk);
          bfm_m_arready = 1'b1;
        end
      join
      if (!ok) tb_fail("P3/X3", "AR did not transfer after downstream ready");
      drain_all(300);
    end
  endtask

  task automatic test_filtered_debt_neutral();
    bit ok;
    begin
      bfm_reset(3);
      bfm_dn_b_lag(0);

      // Establish actual downstream debt three without any WLAST.
      tb_aw(mk_aw(4'h1, 32'h1100_0000, 8'd0, 6'b00_0000), 70, ok);
      if (!ok) tb_fail("W3", "first AW stalled below the bound");
      tb_aw(mk_aw(4'h2, 32'h2200_0000, 8'd0, 6'b00_0000), 70, ok);
      if (!ok) tb_fail("W3", "second AW stalled below the bound");
      tb_aw(mk_aw(4'h3, 32'h3300_0000, 8'd0, 6'b00_0000), 70, ok);
      if (!ok) tb_fail("W3", "third AW stalled below the bound");
      wait_downstream_quiet(200);

      // A filtered write must not consume the fourth debt slot.
      tb_aw(mk_aw(4'h4, 32'h4400_0000, 8'd0, 6'b01_0000), 70, ok);
      if (!ok) tb_fail("X4", "filtered AW stalled at debt three");
      tb_w(mk_w(32'h4444_4444, 4'hF, 1'b1, 1'b0), 70, ok);
      if (!ok) tb_fail("F2/X4", "filtered W was not consumed at debt three");
      wait_manufactured_clear(150);

      tb_aw(mk_aw(4'h5, 32'h5500_0000, 8'd0, 6'b00_0000), 70, ok);
      if (!ok)
        tb_fail("W3/W5", "filtered write incorrectly consumed a debt slot");

      tb_w(mk_w(32'h1111_1111, 4'hF, 1'b1, 1'b0), 70, ok);
      if (!ok) tb_fail("P2", "cleanup W1 stalled");
      tb_w(mk_w(32'h2222_2222, 4'hF, 1'b1, 1'b0), 70, ok);
      if (!ok) tb_fail("P2", "cleanup W2 stalled");
      tb_w(mk_w(32'h3333_3333, 4'hF, 1'b1, 1'b0), 70, ok);
      if (!ok) tb_fail("P2", "cleanup W3 stalled");
      tb_w(mk_w(32'h5555_5555, 4'hF, 1'b1, 1'b0), 70, ok);
      if (!ok) tb_fail("P2", "cleanup W4 stalled");
      drain_all(400);
    end
  endtask

  task automatic test_write_bound();
    bit ok5;
    bit okw;
    begin
      bfm_reset(3);
      bfm_dn_b_lag(20);

      // Four AWs with no WLAST build the exact bound of four.
      tb_aw(mk_aw(4'h0, 32'h0100_0000, 8'd1, 6'b00_0000), 70, okw);
      if (!okw) tb_fail("W3", "AW zero stalled below the bound");
      tb_aw(mk_aw(4'h1, 32'h0100_1000, 8'd1, 6'b00_0000), 70, okw);
      if (!okw) tb_fail("W3", "AW one stalled below the bound");
      tb_aw(mk_aw(4'h2, 32'h0100_2000, 8'd1, 6'b00_0000), 70, okw);
      if (!okw) tb_fail("W3", "AW two stalled below the bound");
      tb_aw(mk_aw(4'h3, 32'h0100_3000, 8'd1, 6'b00_0000), 70, okw);
      if (!okw) tb_fail("W3", "fourth AW stalled while debt was three");

      // Keep a fifth AW offered while (a) a non-last W beat completes and
      // (b) all four B responses arrive. Neither event reduces the debt.
      // A compliant implementation may buffer and accept the fifth upstream
      // AW, but it must not forward it until a downstream WLAST completes.
      ok5 = 1'b0;
      okw = 1'b0;
      fork
        tb_aw(mk_aw(4'h4, 32'h0100_4000, 8'd1, 6'b00_0000), 60, ok5);
        begin
          repeat (3) @(posedge clk);
          tb_w(mk_w(32'hD000_0000, 4'hF, 1'b0, 1'b0), 70, okw);
        end
      join
      if (!okw) tb_fail("P2", "non-last W beat at full debt was not accepted");

      repeat (50) @(posedge clk);

      // Only this WLAST frees a downstream slot.
      tb_w(mk_w(32'hD000_0001, 4'hF, 1'b1, 1'b1), 70, okw);
      if (!okw) tb_fail("P2/W4", "burst-completing WLAST was not accepted");

      if (!ok5) begin
        tb_aw(mk_aw(4'h4, 32'h0100_4000, 8'd1, 6'b00_0000), 70, ok5);
        if (!ok5) tb_fail("W3/W4/X4", "fifth AW stalled after WLAST freed debt");
      end
      bfm_dn_b_lag(0);

      // Complete writes one through four.
      tb_w(mk_w(32'hD100_0000, 4'h1, 1'b0, 1'b0), 70, okw);
      if (!okw) tb_fail("P2", "write one beat zero stalled");
      tb_w(mk_w(32'hD100_0001, 4'h2, 1'b1, 1'b0), 70, okw);
      if (!okw) tb_fail("P2", "write one WLAST stalled");
      tb_w(mk_w(32'hD200_0000, 4'h3, 1'b0, 1'b0), 70, okw);
      if (!okw) tb_fail("P2", "write two beat zero stalled");
      tb_w(mk_w(32'hD200_0001, 4'h4, 1'b1, 1'b0), 70, okw);
      if (!okw) tb_fail("P2", "write two WLAST stalled");
      tb_w(mk_w(32'hD300_0000, 4'h5, 1'b0, 1'b0), 70, okw);
      if (!okw) tb_fail("P2", "write three beat zero stalled");
      tb_w(mk_w(32'hD300_0001, 4'h6, 1'b1, 1'b0), 70, okw);
      if (!okw) tb_fail("P2", "write three WLAST stalled");
      tb_w(mk_w(32'hD400_0000, 4'h7, 1'b0, 1'b0), 70, okw);
      if (!okw) tb_fail("P2", "write four beat zero stalled");
      tb_w(mk_w(32'hD400_0001, 4'h8, 1'b1, 1'b0), 70, okw);
      if (!okw) tb_fail("P2", "write four WLAST stalled");

      drain_all(500);
    end
  endtask

  task automatic test_reset_behaviour();
    bit ok;
    begin
      // Leave a filtered write owed responses, then asynchronously reset it.
      bfm_b_ready(1'b0);
      bfm_r_ready(1'b0);
      tb_aw(mk_aw(4'hE, 32'hE000_0000, 8'd0, 6'b10_0000), 70, ok);
      if (!ok) tb_fail("X4", "pre-reset atomic AW stalled");
      tb_w(mk_w(32'hEEEE_0000, 4'hF, 1'b1, 1'b0), 70, ok);
      if (!ok) tb_fail("F2/X4", "pre-reset atomic W stalled");
      repeat (2) @(posedge clk);

      @(negedge clk);
      rst_n = 1'b0;
      s_awid = 4'hF;
      s_awaddr = 32'hF000_0000;
      s_awlen = 8'd0;
      s_awatop = 6'b10_0000;
      s_awvalid = 1'b1;
      s_wdata = 32'hFFFF_FFFF;
      s_wstrb = 4'hF;
      s_wlast = 1'b1;
      s_wvalid = 1'b1;
      bfm_inj_bvalid = 1'b0;
      bfm_inj_rvalid = 1'b0;
      repeat (4) @(posedge clk);

      // B and R pass-through remains combinational even during reset.
      @(negedge clk);
      bfm_inj_bid = 4'hA;
      bfm_inj_bresp = 2'b11;
      bfm_inj_buser = 1'b1;
      bfm_inj_bvalid = 1'b1;
      bfm_inj_rid = 4'hD;
      bfm_inj_rdata = 32'hCAFE_BABE;
      bfm_inj_rresp = 2'b11;
      bfm_inj_rlast = 1'b1;
      bfm_inj_ruser = 1'b1;
      bfm_inj_rvalid = 1'b1;

      @(negedge clk);
      if (s_bvalid !== 1'b1 ||
          {s_bid, s_bresp, s_buser} !== {4'hA, 2'b11, 1'b1})
        tb_fail("X1/P4", "B pass-through was gated or altered during reset");
      if (s_rvalid !== 1'b1 ||
          {s_rid, s_rdata, s_rresp, s_rlast, s_ruser} !==
          {4'hD, 32'hCAFE_BABE, 2'b11, 1'b1, 1'b1})
        tb_fail("X1/P3", "R pass-through was gated or altered during reset");
      if (m_awvalid !== 1'b0 || m_wvalid !== 1'b0)
        tb_fail("X1", "request valid originated during asynchronous reset");

      @(negedge clk);
      bfm_inj_bvalid = 1'b0;
      bfm_inj_rvalid = 1'b0;
      s_awvalid = 1'b0;
      s_wvalid = 1'b0;
      s_bready = 1'b1;
      s_rready = 1'b1;

      @(negedge clk);
      if (s_bvalid !== 1'b0 || s_rvalid !== 1'b0)
        tb_fail("X1", "manufactured response survived reset");
      rst_n = 1'b1;

      // Neither the interrupted filtered write nor requests presented during
      // reset may create traffic after release.
      repeat (8) begin
        @(posedge clk);
        if (m_awvalid || m_wvalid || s_bvalid || s_rvalid)
          tb_fail("X2", "transaction or owed response survived reset");
      end

      tb_aw(mk_aw(4'h1, 32'h1234_0000, 8'd0, 6'b00_0000), 70, ok);
      if (!ok) tb_fail("X2", "ordinary AW did not work after reset");
      tb_w(mk_w(32'h1234_ABCD, 4'hF, 1'b1, 1'b1), 70, ok);
      if (!ok) tb_fail("X2", "ordinary W did not work after reset");
      tb_ar(mk_ar(4'h2, 32'h5678_0000, 8'd0), 70, ok);
      if (!ok) tb_fail("X2", "ordinary AR did not work after reset");
      drain_all(300);
    end
  endtask

  initial begin
    bfm_m_awready = 1'b1;
    bfm_m_wready = 1'b1;
    bfm_m_arready = 1'b1;

    bfm_bresp = 2'b01;
    bfm_buser = 1'b1;
    bfm_rresp = 2'b01;
    bfm_ruser = 1'b1;

    bfm_inj_bvalid = 1'b0;
    bfm_inj_bid = 4'h0;
    bfm_inj_bresp = 2'b00;
    bfm_inj_buser = 1'b0;
    bfm_inj_rvalid = 1'b0;
    bfm_inj_rid = 4'h0;
    bfm_inj_rdata = 32'h0;
    bfm_inj_rresp = 2'b00;
    bfm_inj_rlast = 1'b0;
    bfm_inj_ruser = 1'b0;

    liveness_check_en = 1'b1;

    bfm_reset(5);
    test_pass_through();
    test_filtering();
    test_backpressure();
    test_filtered_debt_neutral();
    test_write_bound();
    test_reset_behaviour();

    if (!finished) begin
      finished = 1'b1;
      $display("RESULT: PASS");
      $finish;
    end
  end

endmodule
