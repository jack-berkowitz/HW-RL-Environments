module atop_filter_tb;

  // -------------------------------------------------------------------------
  // PROVIDED PLUMBING
  // -------------------------------------------------------------------------

  logic clk = 1'b0;
  always #5 clk = ~clk;

  int bfm_cycle = 0;
  always @(posedge clk) if (rst_n) bfm_cycle <= bfm_cycle + 1;

  logic rst_n = 1'b0;

  task automatic bfm_reset(input int cycles = 5);
    @(negedge clk);
    rst_n = 1'b0;
    repeat (cycles) @(posedge clk);
    @(negedge clk);
    rst_n = 1'b1;
  endtask

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
    .m_rready_o(m_rready)
  );

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

  int bfm_b_lag = 0;
  task automatic bfm_dn_b_lag(input int cycles); bfm_b_lag = cycles; endtask

  int bfm_bq_id [$], bfm_bq_t [$], bfm_rq_id [$], bfm_rq_n [$];

  // These knobs retain the plumbing's default behaviour, while allowing the
  // pass-through checks to use nonzero resp/user values as well.
  logic [1:0] bfm_dn_bresp = 2'b00;
  logic       bfm_dn_buser = 1'b0;
  logic [1:0] bfm_dn_rresp = 2'b00;
  logic       bfm_dn_ruser = 1'b0;

  assign m_awready = 1'b1;
  assign m_wready  = 1'b1;
  assign m_arready = 1'b1;

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
      if (m_bvalid && m_bready) begin
        void'(bfm_bq_id.pop_front());
        void'(bfm_bq_t.pop_front());
      end
      if (m_rvalid && m_rready) begin
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
    m_bvalid = (bfm_bq_id.size() > 0) && (bfm_cycle >= bfm_bq_t[0]);
    m_bid    = 4'(bfm_bq_id.size() ? bfm_bq_id[0] : 0);
    m_bresp  = bfm_dn_bresp;
    m_buser  = bfm_dn_buser;
    m_rvalid = (bfm_rq_id.size() > 0);
    m_rid    = 4'(bfm_rq_id.size() ? bfm_rq_id[0] : 0);
    m_rdata  = 32'hFEED_0000 + 32'(bfm_rq_n.size() ? bfm_rq_n[0] : 0);
    m_rresp  = bfm_dn_rresp;
    m_ruser  = bfm_dn_ruser;
    m_rlast  = (bfm_rq_id.size() > 0) && (bfm_rq_n[0] <= 1);
  end

  initial begin
    s_awvalid = 1'b0; s_wvalid = 1'b0; s_arvalid = 1'b0;
    s_bready  = 1'b1; s_rready = 1'b1;
    s_awid = '0; s_awaddr = '0; s_awlen = '0;
    s_awsize = 3'd2; s_awburst = 2'd1;
    s_awlock = 1'b0; s_awcache = '0; s_awprot = '0;
    s_awqos = '0; s_awregion = '0; s_awatop = '0; s_awuser = 1'b0;
    s_wdata = '0; s_wstrb = 4'hF; s_wlast = 1'b0; s_wuser = 1'b0;
    s_arid = '0; s_araddr = '0; s_arlen = '0;
    s_arsize = 3'd2; s_arburst = 2'd1;
    s_arlock = 1'b0; s_arcache = '0; s_arprot = '0;
    s_arqos = '0; s_arregion = '0; s_aruser = 1'b0;
  end

  initial begin
    #4_000_000;
    $display("RESULT: FAIL (watchdog: no forward progress)");
    $finish;
  end

  // -------------------------------------------------------------------------
  // Scoreboard and protocol checking
  // -------------------------------------------------------------------------

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

  typedef struct {
    logic [3:0] id;
    int         r_total;
    int         r_seen;
    bit         b_seen;
    bit         wlast_seen;
    int         wlast_cycle;
    bit         live_armed;
  } filt_rec_t;

  aw_rec_t s_aw_rec, m_aw_rec;
  w_rec_t  s_w_rec, m_w_rec;
  ar_rec_t s_ar_rec, m_ar_rec;
  b_rec_t  s_b_rec, m_b_rec;
  r_rec_t  s_r_rec, m_r_rec;

  always_comb begin
    s_aw_rec = '0;
    s_aw_rec.id = s_awid;
    s_aw_rec.addr = s_awaddr;
    s_aw_rec.len = s_awlen;
    s_aw_rec.size = s_awsize;
    s_aw_rec.burst = s_awburst;
    s_aw_rec.lock = s_awlock;
    s_aw_rec.cache = s_awcache;
    s_aw_rec.prot = s_awprot;
    s_aw_rec.qos = s_awqos;
    s_aw_rec.region = s_awregion;
    s_aw_rec.atop = s_awatop;
    s_aw_rec.user = s_awuser;

    m_aw_rec = '0;
    m_aw_rec.id = m_awid;
    m_aw_rec.addr = m_awaddr;
    m_aw_rec.len = m_awlen;
    m_aw_rec.size = m_awsize;
    m_aw_rec.burst = m_awburst;
    m_aw_rec.lock = m_awlock;
    m_aw_rec.cache = m_awcache;
    m_aw_rec.prot = m_awprot;
    m_aw_rec.qos = m_awqos;
    m_aw_rec.region = m_awregion;
    m_aw_rec.atop = m_awatop;
    m_aw_rec.user = m_awuser;

    s_w_rec = '{data:s_wdata, strb:s_wstrb, last:s_wlast, user:s_wuser};
    m_w_rec = '{data:m_wdata, strb:m_wstrb, last:m_wlast, user:m_wuser};

    s_ar_rec = '0;
    s_ar_rec.id = s_arid;
    s_ar_rec.addr = s_araddr;
    s_ar_rec.len = s_arlen;
    s_ar_rec.size = s_arsize;
    s_ar_rec.burst = s_arburst;
    s_ar_rec.lock = s_arlock;
    s_ar_rec.cache = s_arcache;
    s_ar_rec.prot = s_arprot;
    s_ar_rec.qos = s_arqos;
    s_ar_rec.region = s_arregion;
    s_ar_rec.user = s_aruser;

    m_ar_rec = '0;
    m_ar_rec.id = m_arid;
    m_ar_rec.addr = m_araddr;
    m_ar_rec.len = m_arlen;
    m_ar_rec.size = m_arsize;
    m_ar_rec.burst = m_arburst;
    m_ar_rec.lock = m_arlock;
    m_ar_rec.cache = m_arcache;
    m_ar_rec.prot = m_arprot;
    m_ar_rec.qos = m_arqos;
    m_ar_rec.region = m_arregion;
    m_ar_rec.user = m_aruser;

    s_b_rec = '{id:s_bid, resp:s_bresp, user:s_buser};
    m_b_rec = '{id:m_bid, resp:m_bresp, user:m_buser};
    s_r_rec = '{id:s_rid, data:s_rdata, resp:s_rresp,
                last:s_rlast, user:s_ruser};
    m_r_rec = '{id:m_rid, data:m_rdata, resp:m_rresp,
                last:m_rlast, user:m_ruser};
  end

  aw_rec_t aw_exp[$];
  w_rec_t  w_exp[$];
  ar_rec_t ar_exp[$];
  b_rec_t  dn_b_q[$];
  r_rec_t  dn_r_q[$];

  bit kind_atomic_q[$];
  int kind_fidx_q[$];
  filt_rec_t filt_q[$];
  filt_rec_t fr;
  aw_rec_t exp_aw;

  int downstream_debt;
  int mon_i;
  int mon_idx;

  bit failed;
  bit monitor_started;
  bit live_enable;

  bit p_awv, p_awr;
  bit p_wv, p_wr;
  bit p_arv, p_arr;
  bit p_bv, p_br;
  bit p_rv, p_rr;
  aw_rec_t p_aw;
  w_rec_t  p_w;
  ar_rec_t p_ar;
  b_rec_t  p_b;
  r_rec_t  p_r;

  task automatic tb_fail(input string clause, input string detail);
    if (!failed) begin
      failed = 1'b1;
      $display("TB FAIL [%s] at cycle %0d: %s",
               clause, bfm_cycle, detail);
      $display("RESULT: FAIL");
      $finish;
    end
  endtask

  always @(posedge clk) begin
    if (!rst_n) begin
      aw_exp.delete();
      w_exp.delete();
      ar_exp.delete();
      dn_b_q.delete();
      dn_r_q.delete();
      kind_atomic_q.delete();
      kind_fidx_q.delete();
      filt_q.delete();
      downstream_debt = 0;
      p_awv = 1'b0;
      p_wv = 1'b0;
      p_arv = 1'b0;
      p_bv = 1'b0;
      p_rv = 1'b0;

      if (monitor_started) begin
        if ((m_awvalid !== 1'b0) || (m_wvalid !== 1'b0))
          tb_fail("X1", "m_awvalid or m_wvalid was not low during reset");
      end
    end else begin
      // X3: valid and payload must remain stable through backpressure.
      if (p_awv && !p_awr) begin
        if ((m_awvalid !== 1'b1) || (m_aw_rec !== p_aw))
          tb_fail("X3", "master AW valid/payload changed before ready");
      end
      if (p_wv && !p_wr) begin
        if ((m_wvalid !== 1'b1) || (m_w_rec !== p_w))
          tb_fail("X3", "master W valid/payload changed before ready");
      end
      if (p_arv && !p_arr) begin
        if ((m_arvalid !== 1'b1) || (m_ar_rec !== p_ar))
          tb_fail("X3", "master AR valid/payload changed before ready");
      end
      if (p_bv && !p_br) begin
        if ((s_bvalid !== 1'b1) || (s_b_rec !== p_b))
          tb_fail("X3", "slave B valid/payload changed before ready");
      end
      if (p_rv && !p_rr) begin
        if ((s_rvalid !== 1'b1) || (s_r_rec !== p_r))
          tb_fail("X3", "slave R valid/payload changed before ready");
      end

      if ((m_awvalid === 1'b1) && (m_awatop !== 6'b000000))
        tb_fail("F1", "m_awatop was nonzero while m_awvalid was asserted");

      // Process slave and master handshakes in the same cycle. The order here
      // deliberately supports a combinational, zero-latency implementation.
      if ((s_awvalid === 1'b1) && (s_awready === 1'b1)) begin
        if (s_awatop[5:4] == 2'b00) begin
          aw_exp.push_back(s_aw_rec);
          kind_atomic_q.push_back(1'b0);
          kind_fidx_q.push_back(-1);
        end else begin
          fr.id = s_awid;
          fr.r_total = 0;
          if (s_awatop[5])
            fr.r_total = int'(s_awlen) + 1;
          fr.r_seen = 0;
          fr.b_seen = 1'b0;
          fr.wlast_seen = 1'b0;
          fr.wlast_cycle = 0;
          fr.live_armed = 1'b0;
          filt_q.push_back(fr);
          kind_atomic_q.push_back(1'b1);
          kind_fidx_q.push_back(filt_q.size() - 1);
        end
      end

      if ((m_awvalid === 1'b1) && (m_awready === 1'b1)) begin
        if (aw_exp.size() == 0) begin
          tb_fail("F1/P1",
                  "unexpected master AW: atomic AW forwarded or AW duplicated");
        end else begin
          exp_aw = aw_exp[0];
          exp_aw.atop = 6'b000000;
          if (m_aw_rec !== exp_aw)
            tb_fail("P1/F1", "forwarded AW field was modified");
          void'(aw_exp.pop_front());
        end
        downstream_debt = downstream_debt + 1;
      end

      if ((s_wvalid === 1'b1) && (s_wready === 1'b1)) begin
        if (kind_atomic_q.size() == 0) begin
          tb_fail("P2/F2", "a W beat was accepted with no corresponding AW");
        end else begin
          if (!kind_atomic_q[0])
            w_exp.push_back(s_w_rec);

          if (s_wlast === 1'b1) begin
            if (kind_atomic_q[0]) begin
              mon_idx = kind_fidx_q[0];
              filt_q[mon_idx].wlast_seen = 1'b1;
              filt_q[mon_idx].wlast_cycle = bfm_cycle;
              filt_q[mon_idx].live_armed =
                live_enable && (s_bready === 1'b1) && (s_rready === 1'b1);
            end
            void'(kind_atomic_q.pop_front());
            void'(kind_fidx_q.pop_front());
          end
        end
      end

      if ((m_wvalid === 1'b1) && (m_wready === 1'b1)) begin
        if (w_exp.size() == 0) begin
          tb_fail("F2/P2",
                  "unexpected master W beat: filtered W forwarded or W duplicated");
        end else begin
          if (m_w_rec !== w_exp[0])
            tb_fail("P2", "forwarded W data, strb, last, or user was modified");
          void'(w_exp.pop_front());
        end
        if (m_wlast === 1'b1)
          downstream_debt = downstream_debt - 1;
      end

      if ((s_arvalid === 1'b1) && (s_arready === 1'b1))
        ar_exp.push_back(s_ar_rec);

      if ((m_arvalid === 1'b1) && (m_arready === 1'b1)) begin
        if (ar_exp.size() == 0) begin
          tb_fail("P3", "unexpected or duplicated master AR");
        end else begin
          if (m_ar_rec !== ar_exp[0])
            tb_fail("P3", "forwarded AR field was modified");
          void'(ar_exp.pop_front());
        end
      end

      if ((m_bvalid === 1'b1) && (m_bready === 1'b1))
        dn_b_q.push_back(m_b_rec);

      if ((s_bvalid === 1'b1) && (s_bready === 1'b1)) begin
        if ((dn_b_q.size() > 0) && (s_b_rec === dn_b_q[0])) begin
          void'(dn_b_q.pop_front());
        end else if (s_bresp === 2'b10) begin
          mon_idx = -1;
          for (mon_i = 0; mon_i < filt_q.size(); mon_i = mon_i + 1) begin
            if ((mon_idx < 0) &&
                (filt_q[mon_i].id == s_bid) &&
                !filt_q[mon_i].b_seen)
              mon_idx = mon_i;
          end
          if (mon_idx < 0) begin
            tb_fail("F3", "manufactured B had a wrong ID or was duplicated");
          end else begin
            filt_q[mon_idx].b_seen = 1'b1;
          end
        end else if (dn_b_q.size() > 0) begin
          tb_fail("P4", "downstream B id, resp, or user was modified");
        end else begin
          tb_fail("F3", "unexpected B, or filtered B was not SLVERR");
        end
      end

      if ((m_rvalid === 1'b1) && (m_rready === 1'b1))
        dn_r_q.push_back(m_r_rec);

      if ((s_rvalid === 1'b1) && (s_rready === 1'b1)) begin
        if ((dn_r_q.size() > 0) && (s_r_rec === dn_r_q[0])) begin
          void'(dn_r_q.pop_front());
        end else if (s_rresp === 2'b10) begin
          mon_idx = -1;
          for (mon_i = 0; mon_i < filt_q.size(); mon_i = mon_i + 1) begin
            if ((mon_idx < 0) &&
                (filt_q[mon_i].id == s_rid) &&
                (filt_q[mon_i].r_seen < filt_q[mon_i].r_total))
              mon_idx = mon_i;
          end
          if (mon_idx < 0) begin
            tb_fail("F4/F5",
                    "manufactured R had a wrong ID, wrong count, or was not owed");
          end else begin
            filt_q[mon_idx].r_seen = filt_q[mon_idx].r_seen + 1;
            if (filt_q[mon_idx].r_seen == filt_q[mon_idx].r_total) begin
              if (s_rlast !== 1'b1)
                tb_fail("F4", "rlast was not asserted on the final manufactured beat");
            end else begin
              if (s_rlast !== 1'b0)
                tb_fail("F4", "rlast was asserted before the final manufactured beat");
            end
          end
        end else if (dn_r_q.size() > 0) begin
          tb_fail("P3", "downstream R id, data, resp, last, or user was modified");
        end else begin
          tb_fail("F4/F5", "unexpected R, or manufactured R was not SLVERR");
        end
      end

      if (downstream_debt > 4)
        tb_fail("W2/W4", "downstream write debt exceeded MAX_WRITE_TXNS");
      if (downstream_debt < 0)
        tb_fail("W1/P2", "downstream write debt became negative");

      // Once backpressure is applied, do not impose the no-backpressure
      // response deadline on older filtered writes.
      if (!live_enable || (s_bready !== 1'b1) || (s_rready !== 1'b1)) begin
        for (mon_i = 0; mon_i < filt_q.size(); mon_i = mon_i + 1)
          filt_q[mon_i].live_armed = 1'b0;
      end

      for (mon_i = 0; mon_i < filt_q.size(); mon_i = mon_i + 1) begin
        if (filt_q[mon_i].live_armed &&
            ((!filt_q[mon_i].b_seen) ||
             (filt_q[mon_i].r_seen != filt_q[mon_i].r_total)) &&
            ((bfm_cycle - filt_q[mon_i].wlast_cycle) > 64))
          tb_fail("X4", "a manufactured response exceeded the 64-cycle bound");
      end

      p_awv = (m_awvalid === 1'b1);
      p_awr = (m_awready === 1'b1);
      p_aw = m_aw_rec;
      p_wv = (m_wvalid === 1'b1);
      p_wr = (m_wready === 1'b1);
      p_w = m_w_rec;
      p_arv = (m_arvalid === 1'b1);
      p_arr = (m_arready === 1'b1);
      p_ar = m_ar_rec;
      p_bv = (s_bvalid === 1'b1);
      p_br = (s_bready === 1'b1);
      p_b = s_b_rec;
      p_rv = (s_rvalid === 1'b1);
      p_rr = (s_rready === 1'b1);
      p_r = s_r_rec;
    end
  end

  // -------------------------------------------------------------------------
  // Stimulus helpers
  // -------------------------------------------------------------------------

  task automatic tb_aw_req(
      input logic [3:0] id, input logic [31:0] addr,
      input logic [7:0] len, input logic [5:0] atop,
      input bit fancy, input int timeout, output bit accepted);
    int t;
    @(negedge clk);
    s_awid = id;
    s_awaddr = addr;
    s_awlen = len;
    s_awatop = atop;
    if (fancy) begin
      s_awsize = 3'd5;
      s_awburst = 2'b10;
      s_awlock = 1'b1;
      s_awcache = 4'hA;
      s_awprot = 3'h5;
      s_awqos = 4'hC;
      s_awregion = 4'h9;
      s_awuser = 1'b1;
    end else begin
      s_awsize = 3'd2;
      s_awburst = 2'd1;
      s_awlock = 1'b0;
      s_awcache = 4'd0;
      s_awprot = 3'd0;
      s_awqos = 4'd0;
      s_awregion = 4'd0;
      s_awuser = 1'b0;
    end
    s_awvalid = 1'b1;
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

  task automatic tb_aw_must(
      input logic [3:0] id, input logic [31:0] addr,
      input logic [7:0] len, input logic [5:0] atop,
      input bit fancy, input int timeout, input string clause);
    bit accepted;
    tb_aw_req(id, addr, len, atop, fancy, timeout, accepted);
    if (!accepted)
      tb_fail(clause, "AW was not accepted within the permitted interval");
  endtask

  task automatic tb_w_req(
      input logic [31:0] data, input logic [3:0] strb,
      input bit last, input bit user, input int timeout,
      output bit accepted);
    int t;
    @(negedge clk);
    s_wdata = data;
    s_wstrb = strb;
    s_wlast = last;
    s_wuser = user;
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

  task automatic tb_w_must(
      input logic [31:0] data, input logic [3:0] strb,
      input bit last, input bit user, input int timeout,
      input string clause);
    bit accepted;
    tb_w_req(data, strb, last, user, timeout, accepted);
    if (!accepted)
      tb_fail(clause, "W beat was not accepted within 64 cycles");
  endtask

  task automatic tb_ar_req(
      input logic [3:0] id, input logic [31:0] addr,
      input logic [7:0] len, input bit fancy, input int timeout,
      output bit accepted);
    int t;
    @(negedge clk);
    s_arid = id;
    s_araddr = addr;
    s_arlen = len;
    if (fancy) begin
      s_arsize = 3'd4;
      s_arburst = 2'b10;
      s_arlock = 1'b1;
      s_arcache = 4'h6;
      s_arprot = 3'h3;
      s_arqos = 4'hB;
      s_arregion = 4'h7;
      s_aruser = 1'b1;
    end else begin
      s_arsize = 3'd2;
      s_arburst = 2'd1;
      s_arlock = 1'b0;
      s_arcache = 4'd0;
      s_arprot = 3'd0;
      s_arqos = 4'd0;
      s_arregion = 4'd0;
      s_aruser = 1'b0;
    end
    s_arvalid = 1'b1;
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

  task automatic tb_ar_must(
      input logic [3:0] id, input logic [31:0] addr,
      input logic [7:0] len, input bit fancy, input int timeout,
      input string clause);
    bit accepted;
    tb_ar_req(id, addr, len, fancy, timeout, accepted);
    if (!accepted)
      tb_fail(clause, "AR was not accepted/forwarded");
  endtask

  task automatic tb_dn_style(
      input logic [1:0] bresp, input bit buser,
      input logic [1:0] rresp, input bit ruser);
    @(negedge clk);
    bfm_dn_bresp = bresp;
    bfm_dn_buser = buser;
    bfm_dn_rresp = rresp;
    bfm_dn_ruser = ruser;
  endtask

  function automatic bit tb_filters_done();
    int j;
    bit ok;
    ok = 1'b1;
    for (j = 0; j < filt_q.size(); j = j + 1) begin
      if (!filt_q[j].b_seen ||
          (filt_q[j].r_seen != filt_q[j].r_total))
        ok = 1'b0;
    end
    tb_filters_done = ok;
  endfunction

  function automatic bit tb_all_done();
    bit ok;
    ok = tb_filters_done();
    if (aw_exp.size() != 0) ok = 1'b0;
    if (w_exp.size() != 0) ok = 1'b0;
    if (ar_exp.size() != 0) ok = 1'b0;
    if (dn_b_q.size() != 0) ok = 1'b0;
    if (dn_r_q.size() != 0) ok = 1'b0;
    if (kind_atomic_q.size() != 0) ok = 1'b0;
    if (bfm_bq_id.size() != 0) ok = 1'b0;
    if (bfm_rq_id.size() != 0) ok = 1'b0;
    if (downstream_debt != 0) ok = 1'b0;
    tb_all_done = ok;
  endfunction

  task automatic tb_drain(input int max_cycles, input string clause);
    int t;
    bit done;
    done = tb_all_done();
    for (t = 0; (t < max_cycles) && !done; t = t + 1) begin
      @(posedge clk);
      done = tb_all_done();
    end
    if (!done)
      tb_fail(clause, "traffic or manufactured responses failed to drain");
  endtask

  task automatic tb_quiet(input int cycles);
    repeat (cycles) @(posedge clk);
  endtask

  task automatic tb_wait_debt(input int target, input int timeout,
                              input string clause);
    int t;
    bit seen;
    seen = (downstream_debt == target);
    for (t = 0; (t < timeout) && !seen; t = t + 1) begin
      @(posedge clk);
      seen = (downstream_debt == target);
    end
    if (!seen)
      tb_fail(clause, "downstream debt did not reach its expected value");
  endtask

  task automatic tb_wait_b_empty(input int timeout);
    int t;
    bit done;
    done = (bfm_bq_id.size() == 0) && (dn_b_q.size() == 0);
    for (t = 0; (t < timeout) && !done; t = t + 1) begin
      @(posedge clk);
      done = (bfm_bq_id.size() == 0) && (dn_b_q.size() == 0);
    end
    if (!done)
      tb_fail("P4", "downstream B responses were not returned");
  endtask

  task automatic tb_wait_filters_done(input int timeout);
    int t;
    bit done;
    done = tb_filters_done();
    for (t = 0; (t < timeout) && !done; t = t + 1) begin
      @(posedge clk);
      done = tb_filters_done();
    end
    if (!done)
      tb_fail("F3/F4/X4", "filtered-write responses did not complete");
  endtask

  task automatic tb_wait_forward_empty(input int timeout);
    int t;
    bit done;
    done = (aw_exp.size() == 0) && (w_exp.size() == 0) &&
           (kind_atomic_q.size() == 0) && (downstream_debt == 0);
    for (t = 0; (t < timeout) && !done; t = t + 1) begin
      @(posedge clk);
      done = (aw_exp.size() == 0) && (w_exp.size() == 0) &&
             (kind_atomic_q.size() == 0) && (downstream_debt == 0);
    end
    if (!done)
      tb_fail("W4/P1/P2", "completed W bursts did not free the write bound");
  endtask

  // While reset is active, inject one downstream B and R directly into the
  // plumbing's queues. They must still appear combinationally upstream.
  task automatic tb_reset_passthrough();
    @(negedge clk);
    bfm_bq_id.push_back(13);
    bfm_bq_t.push_back(bfm_cycle);
    bfm_rq_id.push_back(14);
    bfm_rq_n.push_back(1);
    @(posedge clk);
    if (s_bvalid !== 1'b1)
      tb_fail("X1/P4", "downstream B was not forwarded during reset");
    if ((s_bid !== 4'd13) || (s_bresp !== 2'b00) || (s_buser !== 1'b0))
      tb_fail("X1/P4", "B payload changed during reset pass-through");
    if (s_rvalid !== 1'b1)
      tb_fail("X1/P3", "downstream R was not forwarded during reset");
    if ((s_rid !== 4'd14) || (s_rdata !== 32'hFEED_0001) ||
        (s_rresp !== 2'b00) || (s_rlast !== 1'b1) || (s_ruser !== 1'b0))
      tb_fail("X1/P3", "R payload changed during reset pass-through");
    @(negedge clk);
  endtask

  // -------------------------------------------------------------------------
  // Directed test sequence
  // -------------------------------------------------------------------------

  initial begin : main_test
    bit fifth_taken;
    int i;

    failed = 1'b0;
    monitor_started = 1'b0;
    live_enable = 1'b1;

    // Ignore unknown register outputs before the first clock edge, then check
    // reset with a quiet master port.
    @(posedge clk);
    @(negedge clk);
    monitor_started = 1'b1;
    if ((m_awvalid !== 1'b0) || (m_wvalid !== 1'b0))
      tb_fail("X1", "design originated AW/W after the first reset edge");
    if ((s_bvalid !== 1'b0) || (s_rvalid !== 1'b0))
      tb_fail("X1", "manufactured response appeared with master port quiet");

    tb_reset_passthrough();

    // Present stale atomic traffic during reset. It must have no effect after
    // release. Response ready is held low here so an illegal response cannot
    // appear and disappear between observations.
    @(negedge clk);
    s_bready = 1'b0;
    s_rready = 1'b0;
    s_awid = 4'hF;
    s_awaddr = 32'hDEAD_BEEF;
    s_awlen = 8'd0;
    s_awatop = 6'b10_0000;
    s_awvalid = 1'b1;
    s_wdata = 32'hBAD0_BAD0;
    s_wstrb = 4'hF;
    s_wlast = 1'b1;
    s_wvalid = 1'b1;
    repeat (2) @(posedge clk);
    @(negedge clk);
    if ((m_awvalid !== 1'b0) || (m_wvalid !== 1'b0) ||
        (s_bvalid !== 1'b0) || (s_rvalid !== 1'b0))
      tb_fail("X1", "traffic presented during reset caused output activity");
    s_awvalid = 1'b0;
    s_wvalid = 1'b0;
    s_bready = 1'b1;
    s_rready = 1'b1;

    bfm_reset(3);
    tb_quiet(4);

    // P1/P2: every AW field, a multi-beat W burst, all strobes, W user, and
    // nonzero low ATOP bits on a non-atomic write. Use a distinctive B too.
    tb_dn_style(2'b11, 1'b1, 2'b00, 1'b0);
    tb_aw_must(4'd1, 32'h0000_1000, 8'd3, 6'b00_1111,
               1'b1, 64, "P1/C1/W3");
    tb_w_must(32'hA0A0_0000, 4'h0, 1'b0, 1'b1, 64, "P2");
    tb_w_must(32'hA0A0_0001, 4'h5, 1'b0, 1'b0, 64, "P2");
    tb_w_must(32'hA0A0_0002, 4'hA, 1'b0, 1'b1, 64, "P2");
    tb_w_must(32'hA0A0_0003, 4'hF, 1'b1, 1'b0, 64, "P2");
    tb_drain(160, "P1/P2/P4");
    tb_quiet(6);

    // P3/P4: AR fields and downstream R fields, including resp/user, must be
    // untouched. Two reads also exercise a second transaction.
    tb_dn_style(2'b00, 1'b0, 2'b11, 1'b1);
    tb_ar_must(4'd2, 32'h0000_1000, 8'd2, 1'b1, 100, "P3");
    tb_ar_must(4'd3, 32'hFFFF_FFFC, 8'd0, 1'b0, 100, "P3");
    tb_drain(160, "P3");
    tb_quiet(6);
    tb_dn_style(2'b00, 1'b0, 2'b00, 1'b0);

    bfm_reset(3);
    tb_quiet(3);

    // Atomic without a read response. Low ATOP bits must not affect C1/C2.
    // The burst is deliberately longer than one beat and offered slowly.
    tb_aw_must(4'd4, 32'h0000_1000, 8'd3, 6'b01_1010,
               1'b0, 64, "C1/F3/X4");
    tb_w_must(32'hB000_0000, 4'hF, 1'b0, 1'b0, 64, "F2/X4");
    tb_quiet(2);
    tb_w_must(32'hB000_0001, 4'h1, 1'b0, 1'b1, 64, "F2/X4");
    tb_quiet(2);
    tb_w_must(32'hB000_0002, 4'h2, 1'b0, 1'b0, 64, "F2/X4");
    tb_w_must(32'hB000_0003, 4'h4, 1'b1, 1'b1, 64, "F2/X4");
    tb_drain(180, "F2/F3/F5/X4");
    tb_quiet(10);

    // Atomic with a three-beat manufactured read burst. Idle intervals allow
    // a legal implementation to emit R before B and before W last.
    tb_aw_must(4'd5, 32'h0000_1000, 8'd2, 6'b10_0101,
               1'b0, 64, "C2/F4/X4");
    tb_quiet(3);
    tb_w_must(32'hC000_0000, 4'hF, 1'b0, 1'b0, 64, "F2/X4");
    tb_quiet(2);
    tb_w_must(32'hC000_0001, 4'h3, 1'b0, 1'b0, 64, "F2/X4");
    tb_quiet(2);
    tb_w_must(32'hC000_0002, 4'hC, 1'b1, 1'b0, 64, "F2/X4");

    // ATOP=11 also owes a read response; len=0 means exactly one R beat.
    tb_aw_must(4'd6, 32'h0000_2000, 8'd0, 6'b11_0011,
               1'b0, 64, "C2/F4/X4");
    tb_w_must(32'hC100_0000, 4'hF, 1'b1, 1'b0, 64, "F2/X4");
    tb_drain(200, "F3/F4/X4");
    tb_quiet(8);

    // Several writes following one another, with ordinary traffic interleaved.
    // Response order is intentionally not constrained by the scoreboard.
    tb_aw_must(4'd7, 32'h0000_3000, 8'd1, 6'b10_0000,
               1'b0, 64, "F4/X4");
    tb_w_must(32'hD700_0000, 4'hF, 1'b0, 1'b0, 64, "F2/X4");
    tb_w_must(32'hD700_0001, 4'hF, 1'b1, 1'b0, 64, "F2/X4");

    tb_aw_must(4'd9, 32'h0000_3000, 8'd0, 6'b00_0000,
               1'b0, 64, "P1/L4");
    tb_w_must(32'hD900_0000, 4'h9, 1'b1, 1'b1, 64, "P2");

    tb_aw_must(4'd8, 32'h0000_4000, 8'd2, 6'b11_0000,
               1'b0, 64, "F4/X4");
    tb_w_must(32'hD800_0000, 4'hF, 1'b0, 1'b0, 64, "F2/X4");
    tb_w_must(32'hD800_0001, 4'hF, 1'b0, 1'b0, 64, "F2/X4");
    tb_w_must(32'hD800_0002, 4'hF, 1'b1, 1'b0, 64, "F2/X4");
    tb_ar_must(4'd11, 32'h0000_4000, 8'd1, 1'b0, 100, "P3");
    tb_drain(240, "P1-P4/F3-F5/X4");
    tb_quiet(10);

    // Backpressure manufactured responses. No particular B/R order or valid
    // latency is required, but anything asserted must remain stable (X3).
    bfm_reset(3);
    tb_quiet(3);
    live_enable = 1'b0;
    bfm_b_ready(1'b0);
    bfm_r_ready(1'b0);
    tb_aw_must(4'd10, 32'h0000_5000, 8'd1, 6'b10_0000,
               1'b0, 64, "F4");
    tb_w_must(32'hEA00_0000, 4'hF, 1'b0, 1'b0, 64, "F2");
    tb_w_must(32'hEA00_0001, 4'hF, 1'b1, 1'b0, 64, "F2");
    tb_quiet(8);
    bfm_b_ready(1'b1);
    bfm_r_ready(1'b1);
    live_enable = 1'b1;
    tb_drain(200, "F3/F4");
    tb_quiet(8);

    // W4: complete five write bursts without any B responses. Completion of W,
    // not arrival of B, must make each subsequent AW possible.
    bfm_reset(3);
    bfm_dn_b_lag(1000);
    for (i = 0; i < 5; i = i + 1) begin
      tb_aw_must(4'(i), 32'h0000_6000, 8'd0, 6'b00_0000,
                 1'b0, 64, "W3/W4/X4");
      tb_w_must(32'hF000_0000 + 32'(i), 4'hF, 1'b1,
                1'b0, 64, "P2/W4");
    end
    tb_wait_forward_empty(100);

    // Flush the deliberately unanswered subordinate transactions.
    bfm_reset(3);
    bfm_dn_b_lag(2);
    tb_quiet(3);

    // Build the maximum debt by holding back every W beat. Let all four B
    // responses return; B must not reduce the debt.
    for (i = 0; i < 4; i = i + 1)
      tb_aw_must(4'(i), 32'h0000_7000, 8'd0, 6'b00_0000,
                 1'b0, 64, "W3/X4");
    tb_wait_debt(4, 100, "P1/W2");
    tb_wait_b_empty(100);

    // A filtered write and a read at full debt must not consume downstream
    // write debt or be filtered/stalled by the write bound.
    tb_aw_must(4'd12, 32'h0000_7000, 8'd0, 6'b01_0000,
               1'b0, 64, "W5/F3/X4");
    tb_w_must(32'hFC00_0000, 4'hF, 1'b1, 1'b0, 64, "F2/W5");
    tb_wait_filters_done(100);
    tb_ar_must(4'd13, 32'h0000_7000, 8'd0, 1'b0, 100, "P3/W");

    // Offer a fifth ordinary AW while debt is still four. Accepting it into an
    // internal buffer is legal; forwarding it now is not. The global debt
    // monitor rejects the latter.
    tb_aw_req(4'd4, 32'h0000_8000, 8'd0, 6'b00_0000,
              1'b0, 8, fifth_taken);

    // Completing one downstream W burst frees exactly one entry.
    tb_w_must(32'hD000_0000, 4'hF, 1'b1, 1'b0, 64, "P2/W4");
    if (!fifth_taken)
      tb_aw_must(4'd4, 32'h0000_8000, 8'd0, 6'b00_0000,
                 1'b0, 64, "W3/W4/X4");

    for (i = 1; i < 4; i = i + 1)
      tb_w_must(32'hD000_0000 + 32'(i), 4'hF, 1'b1,
                1'b0, 64, "P2");
    tb_w_must(32'hE000_0000, 4'hF, 1'b1, 1'b0, 64, "P2");

    tb_drain(300, "W2/W3/W4/W5/P1-P4/F3");
    tb_quiet(12);

    if (!failed) begin
      $display("RESULT: PASS");
      $finish;
    end
  end

endmodule
