module atop_filter_tb;

  // ---------------------------------------------------------------------------
  // PROVIDED PLUMBING -- moves transactions, checks nothing.
  // ---------------------------------------------------------------------------
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
    .m_rready_o(m_rready));

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
  // OUR CHECKING AND STIMULUS
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
    logic        user;
  } aw_rec_t;

  typedef struct packed {
    logic [31:0] data;
    logic [3:0]  strb;
    logic        wlast;
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

  bit checks_enabled = 0;

  int id_type [16];
  int id_len [16];
  int id_b_expected [16];
  int id_b_seen [16];
  int id_r_expected [16];
  int id_r_seen [16];
  int id_wlast_time [16];

  aw_rec_t exp_aw_q [$];
  w_rec_t  exp_w_q [$];
  ar_rec_t exp_ar_q [$];

  task automatic fail(input string msg);
    $display("RESULT: FAIL (%s)", msg);
    $finish;
  endtask

  task automatic setup_write(input int id, input int typ, input int len);
    id_type[id] = typ;
    id_len[id] = len;
    id_b_expected[id] = 1;
    id_b_seen[id] = 0;
    id_r_expected[id] = (typ == 3) ? (len + 1) : 0;
    id_r_seen[id] = 0;
    id_wlast_time[id] = -1;
  endtask

  task automatic setup_read(input int id, input int len);
    id_type[id] = 4;
    id_len[id] = len;
    id_b_expected[id] = 0;
    id_b_seen[id] = 0;
    id_r_expected[id] = len + 1;
    id_r_seen[id] = 0;
    id_wlast_time[id] = -1;
  endtask

  task automatic do_aw(input logic [3:0] id, input logic [31:0] addr,
                       input logic [7:0] len, input logic [5:0] atop,
                       input bit is_atomic, input int timeout,
                       output bit accepted);
    if (!is_atomic) begin
      automatic aw_rec_t e;
      e.id = id; e.addr = addr; e.len = len; e.size = 3'd2; e.burst = 2'd1;
      e.lock = 0; e.cache = 0; e.prot = 0; e.qos = 0; e.region = 0; e.user = 0;
      exp_aw_q.push_back(e);
    end
    bfm_aw(id, addr, len, atop, timeout, accepted);
    if (!accepted) fail("AW not accepted");
  endtask

  task automatic do_w_id(input int id, input logic [31:0] data,
                         input logic [3:0] strb, input bit is_last,
                         input bit is_atomic, input int timeout);
    bit accepted;
    if (!is_atomic) begin
      automatic w_rec_t e;
      e.data = data; e.strb = strb; e.wlast = is_last; e.user = 0;
      exp_w_q.push_back(e);
    end
    bfm_w(data, strb, is_last, timeout, accepted);
    if (!accepted) fail("W not accepted");
    if (is_atomic && is_last) id_wlast_time[id] = bfm_cycle;
  endtask

  task automatic do_ar(input logic [3:0] id, input logic [31:0] addr,
                       input logic [7:0] len, input int timeout);
    bit accepted;
    automatic ar_rec_t e;
    e.id = id; e.addr = addr; e.len = len; e.size = 3'd2; e.burst = 2'd1;
    e.lock = 0; e.cache = 0; e.prot = 0; e.qos = 0; e.region = 0; e.user = 0;
    exp_ar_q.push_back(e);
    bfm_ar(id, addr, len, timeout, accepted);
    if (!accepted) fail("AR not accepted");
  endtask

  task automatic wait_b_id(input int id, input int timeout);
    for (int t = 0; t < timeout; t++) begin
      @(posedge clk);
      if (id_b_seen[id] >= id_b_expected[id]) return;
    end
    fail($sformatf("timeout waiting B id %0d", id));
  endtask

  task automatic wait_write_done(input int id, input int timeout);
    for (int t = 0; t < timeout; t++) begin
      @(posedge clk);
      if (id_b_seen[id] >= id_b_expected[id] &&
          id_r_seen[id] >= id_r_expected[id]) return;
    end
    fail($sformatf("X4: timeout waiting responses for id %0d", id));
  endtask

  task automatic wait_all_done(input int timeout);
    bit all;
    for (int t = 0; t < timeout; t++) begin
      all = 1;
      for (int i = 0; i < 15; i++) begin
        if (id_b_seen[i] < id_b_expected[i]) all = 0;
        if (id_r_seen[i] < id_r_expected[i]) all = 0;
      end
      if (all) return;
      @(posedge clk);
    end
    fail("X4: timeout waiting all responses");
  endtask

  always @(posedge clk) begin
    if (rst_n && checks_enabled) begin
      if (m_awvalid && m_awatop != 6'b000000)
        fail("F1: m_awatop_o not zero while m_awvalid_o");

      if (m_awvalid && m_awready) begin
        if (exp_aw_q.size() == 0)
          fail("P1/F1: unexpected forwarded AW");
        else begin
          automatic aw_rec_t e = exp_aw_q.pop_front();
          if (m_awid != e.id || m_awaddr != e.addr || m_awlen != e.len ||
              m_awsize != e.size || m_awburst != e.burst || m_awlock != e.lock ||
              m_awcache != e.cache || m_awprot != e.prot || m_awqos != e.qos ||
              m_awregion != e.region || m_awuser != e.user)
            fail("P1: non-atomic AW not forwarded unmodified");
        end
      end

      if (m_wvalid && m_wready) begin
        if (exp_w_q.size() == 0)
          fail("P2/F2: unexpected forwarded W beat");
        else begin
          automatic w_rec_t e = exp_w_q.pop_front();
          if (m_wdata != e.data || m_wstrb != e.strb ||
              m_wlast != e.wlast || m_wuser != e.user)
            fail("P2: forwarded W beat not unmodified/in order");
        end
      end

      if (m_arvalid && m_arready) begin
        if (exp_ar_q.size() == 0)
          fail("P3: unexpected forwarded AR");
        else begin
          automatic ar_rec_t e = exp_ar_q.pop_front();
          if (m_arid != e.id || m_araddr != e.addr || m_arlen != e.len ||
              m_arsize != e.size || m_arburst != e.burst || m_arlock != e.lock ||
              m_arcache != e.cache || m_arprot != e.prot || m_arqos != e.qos ||
              m_arregion != e.region || m_aruser != e.user)
            fail("P3: AR not forwarded unmodified");
        end
      end

      if (m_bvalid) begin
        if (!s_bvalid)
          fail("P4/X1: s_bvalid_o does not follow m_bvalid_i");
        else if (s_bid != m_bid || s_bresp != m_bresp || s_buser != m_buser)
          fail("P4: forwarded B not unmodified");
      end

      if (s_bvalid && s_bready) begin
        automatic int id = int'(s_bid);
        if (id_type[id] == 1) begin
          if (!m_bvalid || m_bid != s_bid || m_bresp != s_bresp || m_buser != s_buser)
            fail("P4: non-atomic B not forwarded from master");
          id_b_seen[id]++;
          if (id_b_seen[id] > 1)
            fail("P4: extra B for non-atomic write");
        end else if (id_type[id] == 2 || id_type[id] == 3) begin
          if (s_bresp != 2'b10)
            fail("F3: manufactured B resp not SLVERR");
          id_b_seen[id]++;
          if (id_b_seen[id] > 1)
            fail("F3: more than one B for filtered write");
          if (id_wlast_time[id] >= 0 && (bfm_cycle - id_wlast_time[id]) > 64)
            fail("X4: manufactured B late");
        end else if (id_type[id] == 4) begin
          fail("P4: unexpected B for read id");
        end else if (id == 15) begin
          fail("X2: spurious B after reset");
        end else begin
          fail("unknown B id");
        end
      end

      if (m_rvalid) begin
        if (!s_rvalid)
          fail("P3/X1: s_rvalid_o does not follow m_rvalid_i");
        else if (s_rid != m_rid || s_rdata != m_rdata || s_rresp != m_rresp ||
                 s_rlast != m_rlast || s_ruser != m_ruser)
          fail("P3: forwarded R not unmodified");
      end

      if (s_rvalid && s_rready) begin
        automatic int id = int'(s_rid);
        if (id_type[id] == 4) begin
          if (!m_rvalid || m_rid != s_rid || m_rdata != s_rdata ||
              m_rresp != s_rresp || m_rlast != s_rlast || m_ruser != s_ruser)
            fail("P3: read R not forwarded unmodified");
          id_r_seen[id]++;
          if (id_r_seen[id] > id_r_expected[id])
            fail("P3: extra read R beat");
        end else if (id_type[id] == 3) begin
          if (s_rresp != 2'b10)
            fail("F4: manufactured R resp not SLVERR");
          id_r_seen[id]++;
          if (id_r_seen[id] < id_r_expected[id]) begin
            if (s_rlast)
              fail("F4: rlast asserted early");
          end else if (id_r_seen[id] == id_r_expected[id]) begin
            if (!s_rlast)
              fail("F4: rlast missing on final manufactured R");
            if (id_wlast_time[id] >= 0 && (bfm_cycle - id_wlast_time[id]) > 64)
              fail("X4: manufactured R late");
          end else begin
            fail("F4: extra manufactured R beat");
          end
        end else if (id_type[id] == 2) begin
          fail("F5: unexpected R for atomic write without read response");
        end else if (id_type[id] == 1) begin
          fail("unexpected R for non-atomic write");
        end else if (id == 15) begin
          fail("X2: spurious R after reset");
        end else begin
          fail("unknown R id");
        end
      end
    end
  end

  initial begin
    int i;
    bit accepted;
    bit aw5_ok;
    bit got_r;
    bit got_b;
    logic [3:0] rid0;
    logic rlast0;
    logic [3:0] bid0;
    logic [1:0] bresp0;
    int t;
    aw_rec_t e4;

    for (i = 0; i < 16; i++) begin
      id_type[i] = 0;
      id_len[i] = 0;
      id_b_expected[i] = 0;
      id_b_seen[i] = 0;
      id_r_expected[i] = 0;
      id_r_seen[i] = 0;
      id_wlast_time[i] = -1;
    end
    checks_enabled = 0;

    // X1/X2 reset test: present an atomic write while reset is low.
    @(negedge clk);
    s_awid = 4'hF; s_awaddr = 32'hDEADBEEF; s_awlen = 0;
    s_awsize = 3'd2; s_awburst = 2'd1; s_awlock = 0; s_awcache = 0;
    s_awprot = 0; s_awqos = 0; s_awregion = 0; s_awatop = 6'b100000;
    s_awuser = 0; s_awvalid = 1;
    s_wdata = 32'h12345678; s_wstrb = 4'hF; s_wlast = 1;
    s_wuser = 0; s_wvalid = 1;
    repeat (3) begin
      @(posedge clk);
      if (m_awvalid || m_wvalid)
        fail("X1: originated during reset");
    end
    @(negedge clk);
    s_awvalid = 0; s_wvalid = 0;
    rst_n = 1;
    repeat (10) begin
      @(posedge clk);
      if (s_bvalid) fail("X2: spurious B after reset");
      if (s_rvalid) fail("X2: spurious R after reset");
    end
    checks_enabled = 1;

    // -----------------------------------------------------------------------
    // W5 / W2 / W3 / W4 debt tests
    // -----------------------------------------------------------------------
    bfm_dn_b_lag(0);

    // Three non-atomic AWs outstanding: debt = 3.
    for (i = 0; i < 3; i++) begin
      setup_write(i, 1, 0);
      do_aw(4'(i), 32'h1000 + i, 0, 6'b000001, 0, 64, accepted);
    end

    // A filtered write must not change the debt.
    setup_write(14, 2, 0);
    do_aw(14, 32'hB000, 0, 6'b010000, 1, 64, accepted);
    do_w_id(14, 32'hBEEF0000, 4'hF, 1, 1, 64);
    wait_write_done(14, 100);

    // Debt is still 3, so this fourth non-atomic AW must be accepted.
    setup_write(3, 1, 0);
    do_aw(3, 32'h1003, 0, 6'b000001, 0, 64, accepted);

    // Wait for B responses.  W4: these must not reduce the debt.
    for (i = 0; i < 4; i++) wait_b_id(i, 100);

    // Debt is 4.  A fifth non-atomic AW must be stalled.
    setup_write(4, 1, 0);
    e4.id = 4; e4.addr = 32'h2000; e4.len = 0; e4.size = 3'd2;
    e4.burst = 2'd1; e4.lock = 0; e4.cache = 0; e4.prot = 0;
    e4.qos = 0; e4.region = 0; e4.user = 0;
    exp_aw_q.push_back(e4);
    @(negedge clk);
    s_awid = 4; s_awaddr = 32'h2000; s_awlen = 0;
    s_awsize = 3'd2; s_awburst = 2'd1; s_awlock = 0; s_awcache = 0;
    s_awprot = 0; s_awqos = 0; s_awregion = 0; s_awatop = 6'b000001;
    s_awuser = 0; s_awvalid = 1;
    for (t = 0; t < 10; t++) begin
      @(posedge clk);
      if (s_awready)
        fail("W2/W4: accepted 5th AW while debt=4 after B responses");
    end

    // Complete one write burst: debt falls to 3, fifth AW must be taken.
    do_w_id(0, 32'hA0000000, 4'hF, 1, 0, 64);
    aw5_ok = 0;
    for (t = 0; t < 64; t++) begin
      @(posedge clk);
      if (s_awready) begin aw5_ok = 1; break; end
    end
    if (!aw5_ok)
      fail("W3/X4: 5th AW not accepted after debt reduced");
    @(negedge clk) s_awvalid = 0;

    // Complete the remaining outstanding write bursts.
    do_w_id(1, 32'hA1000000, 4'hF, 1, 0, 64);
    do_w_id(2, 32'hA2000000, 4'hF, 1, 0, 64);
    do_w_id(3, 32'hA3000000, 4'hF, 1, 0, 64);
    do_w_id(4, 32'hA4000000, 4'hF, 1, 0, 64);
    wait_b_id(4, 100);

    // -----------------------------------------------------------------------
    // P2 multi-beat non-atomic write
    // -----------------------------------------------------------------------
    setup_write(11, 1, 2);
    do_aw(11, 32'hB000, 2, 6'b000000, 0, 64, accepted);
    do_w_id(11, 32'h11000000, 4'hF, 0, 0, 64);
    do_w_id(11, 32'h11000001, 4'hF, 0, 0, 64);
    do_w_id(11, 32'h11000002, 4'hF, 1, 0, 64);
    wait_b_id(11, 100);

    // -----------------------------------------------------------------------
    // Filtered writes
    // -----------------------------------------------------------------------
    // id5: atomic without read response, len=2
    setup_write(5, 2, 2);
    do_aw(5, 32'h3000, 2, 6'b010000, 1, 64, accepted);
    do_w_id(5, 32'hB0000000, 4'hF, 0, 1, 64);
    do_w_id(5, 32'hB0000001, 4'hF, 0, 1, 64);
    do_w_id(5, 32'hB0000002, 4'hF, 1, 1, 64);
    wait_write_done(5, 100);

    // id6: atomic with read response, len=3
    setup_write(6, 3, 3);
    do_aw(6, 32'h4000, 3, 6'b100000, 1, 64, accepted);
    do_w_id(6, 32'hC0000000, 4'hF, 0, 1, 64);
    do_w_id(6, 32'hC0000001, 4'hF, 0, 1, 64);
    do_w_id(6, 32'hC0000002, 4'hF, 0, 1, 64);
    do_w_id(6, 32'hC0000003, 4'hF, 1, 1, 64);
    wait_write_done(6, 100);

    // id7: atomic with read response, len=0, bits [5:4] = 11
    setup_write(7, 3, 0);
    do_aw(7, 32'h5000, 0, 6'b110000, 1, 64, accepted);
    do_w_id(7, 32'hD0000000, 4'hF, 1, 1, 64);
    wait_write_done(7, 100);

    // id8: atomic with read response, len=1, lower opcode bits non-zero
    setup_write(8, 3, 1);
    do_aw(8, 32'h6000, 1, 6'b101010, 1, 64, accepted);
    do_w_id(8, 32'hE0000000, 4'hF, 0, 1, 64);
    do_w_id(8, 32'hE0000001, 4'hF, 1, 1, 64);
    wait_write_done(8, 100);

    // -----------------------------------------------------------------------
    // P3 read pass-through
    // -----------------------------------------------------------------------
    setup_read(9, 2);
    do_ar(9, 32'h7000, 2, 64);
    wait_write_done(9, 100);

    setup_read(10, 0);
    do_ar(10, 32'h8000, 0, 64);
    wait_write_done(10, 100);

    // -----------------------------------------------------------------------
    // X3 backpressure on manufactured R
    // -----------------------------------------------------------------------
    setup_write(12, 3, 1);
    do_aw(12, 32'h9000, 1, 6'b100000, 1, 64, accepted);
    bfm_r_ready(0);
    do_w_id(12, 32'hF0000000, 4'hF, 0, 1, 64);
    do_w_id(12, 32'hF0000001, 4'hF, 1, 1, 64);

    got_r = 0;
    for (t = 0; t < 64; t++) begin
      @(posedge clk);
      if (s_rvalid && s_rid == 12) begin got_r = 1; break; end
    end
    if (!got_r) fail("X4: no R for id12");
    rid0 = s_rid;
    rlast0 = s_rlast;
    repeat (3) begin
      @(posedge clk);
      if (!s_rvalid || s_rid != rid0 || s_rlast != rlast0)
        fail("X3: R valid/payload not stable under backpressure");
    end
    bfm_r_ready(1);
    wait_write_done(12, 100);

    // -----------------------------------------------------------------------
    // X3 backpressure on manufactured B
    // -----------------------------------------------------------------------
    setup_write(13, 2, 0);
    do_aw(13, 32'hA000, 0, 6'b010000, 1, 64, accepted);
    bfm_b_ready(0);
    do_w_id(13, 32'hA5000000, 4'hF, 1, 1, 64);

    got_b = 0;
    for (t = 0; t < 64; t++) begin
      @(posedge clk);
      if (s_bvalid && s_bid == 13) begin got_b = 1; break; end
    end
    if (!got_b) fail("X4: no B for id13");
    bid0 = s_bid;
    bresp0 = s_bresp;
    repeat (3) begin
      @(posedge clk);
      if (!s_bvalid || s_bid != bid0 || s_bresp != bresp0)
        fail("X3: B valid/payload not stable under backpressure");
    end
    bfm_b_ready(1);
    wait_write_done(13, 100);

    // -----------------------------------------------------------------------
    // Final checks
    // -----------------------------------------------------------------------
    wait_all_done(200);

    if (exp_aw_q.size() != 0) fail("P1: missing forwarded AW");
    if (exp_w_q.size() != 0)  fail("P2: missing forwarded W");
    if (exp_ar_q.size() != 0) fail("P3: missing forwarded AR");

    for (i = 0; i < 15; i++) begin
      if (id_b_seen[i] != id_b_expected[i])
        fail($sformatf("B count mismatch for id %0d", i));
      if (id_r_seen[i] != id_r_expected[i])
        fail($sformatf("R count mismatch for id %0d", i));
    end

    $display("RESULT: PASS");
    $finish;
  end

endmodule
