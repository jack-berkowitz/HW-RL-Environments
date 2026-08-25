module atop_filter_tb;

  // ---------------------------------------------------------------------------
  // PROVIDED PLUMBING -- moves transactions; checker/stimulus are below.
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

  // ---- slave/upstream signals --------------------------------------------
  logic [3:0]  s_awid;
  logic [31:0] s_awaddr;
  logic [7:0]  s_awlen;
  logic [2:0]  s_awsize;
  logic [1:0]  s_awburst;
  logic        s_awlock;
  logic [3:0]  s_awcache;
  logic [2:0]  s_awprot;
  logic [3:0]  s_awqos;
  logic [3:0]  s_awregion;
  logic [5:0]  s_awatop;
  logic        s_awuser;
  logic        s_awvalid;
  logic        s_awready;

  logic [31:0] s_wdata;
  logic [3:0]  s_wstrb;
  logic        s_wlast;
  logic        s_wuser;
  logic        s_wvalid;
  logic        s_wready;

  logic [3:0]  s_bid;
  logic [1:0]  s_bresp;
  logic        s_buser;
  logic        s_bvalid;
  logic        s_bready;

  logic [3:0]  s_arid;
  logic [31:0] s_araddr;
  logic [7:0]  s_arlen;
  logic [2:0]  s_arsize;
  logic [1:0]  s_arburst;
  logic        s_arlock;
  logic [3:0]  s_arcache;
  logic [2:0]  s_arprot;
  logic [3:0]  s_arqos;
  logic [3:0]  s_arregion;
  logic        s_aruser;
  logic        s_arvalid;
  logic        s_arready;

  logic [3:0]  s_rid;
  logic [31:0] s_rdata;
  logic [1:0]  s_rresp;
  logic        s_rlast;
  logic        s_ruser;
  logic        s_rvalid;
  logic        s_rready;

  // ---- master/downstream signals -----------------------------------------
  logic [3:0]  m_awid;
  logic [31:0] m_awaddr;
  logic [7:0]  m_awlen;
  logic [2:0]  m_awsize;
  logic [1:0]  m_awburst;
  logic        m_awlock;
  logic [3:0]  m_awcache;
  logic [2:0]  m_awprot;
  logic [3:0]  m_awqos;
  logic [3:0]  m_awregion;
  logic [5:0]  m_awatop;
  logic        m_awuser;
  logic        m_awvalid;
  logic        m_awready;

  logic [31:0] m_wdata;
  logic [3:0]  m_wstrb;
  logic        m_wlast;
  logic        m_wuser;
  logic        m_wvalid;
  logic        m_wready;

  logic [3:0]  m_bid;
  logic [1:0]  m_bresp;
  logic        m_buser;
  logic        m_bvalid;
  logic        m_bready;

  logic [3:0]  m_arid;
  logic [31:0] m_araddr;
  logic [7:0]  m_arlen;
  logic [2:0]  m_arsize;
  logic [1:0]  m_arburst;
  logic        m_arlock;
  logic [3:0]  m_arcache;
  logic [2:0]  m_arprot;
  logic [3:0]  m_arqos;
  logic [3:0]  m_arregion;
  logic        m_aruser;
  logic        m_arvalid;
  logic        m_arready;

  logic [3:0]  m_rid;
  logic [31:0] m_rdata;
  logic [1:0]  m_rresp;
  logic        m_rlast;
  logic        m_ruser;
  logic        m_rvalid;
  logic        m_rready;

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

  // ---- upstream request BFM -----------------------------------------------
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
    @(negedge clk);
    s_awvalid = 1'b0;
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
    @(negedge clk);
    s_wvalid = 1'b0;
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
    @(negedge clk);
    s_arvalid = 1'b0;
  endtask

  task automatic bfm_b_ready(input bit v);
    @(negedge clk);
    s_bready = v;
  endtask

  task automatic bfm_r_ready(input bit v);
    @(negedge clk);
    s_rready = v;
  endtask

  // ---- downstream subordinate BFM ----------------------------------------
  int bfm_b_lag = 0;

  task automatic bfm_dn_b_lag(input int cycles);
    bfm_b_lag = cycles;
  endtask

  int bfm_bq_id [$], bfm_bq_t [$], bfm_rq_id [$], bfm_rq_n [$];

  assign m_awready = 1'b1;
  assign m_wready  = 1'b1;
  assign m_arready = 1'b1;

  always @(posedge clk) begin
    if (!rst_n) begin
      bfm_bq_id.delete();
      bfm_bq_t.delete();
      bfm_rq_id.delete();
      bfm_rq_n.delete();
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

  // Use non-SLVERR response values so manufactured traffic is unambiguous.
  // P3/P4 still require these arbitrary legal response/user values to pass.
  always_comb begin
    m_bvalid = (bfm_bq_id.size() > 0) && (bfm_cycle >= bfm_bq_t[0]);
    m_bid    = 4'(bfm_bq_id.size() ? bfm_bq_id[0] : 0);
    m_bresp  = 2'b11;
    m_buser  = 1'b1;

    m_rvalid = (bfm_rq_id.size() > 0);
    m_rid    = 4'(bfm_rq_id.size() ? bfm_rq_id[0] : 0);
    m_rdata  = 32'hFEED_0000 + 32'(bfm_rq_n.size() ? bfm_rq_n[0] : 0);
    m_rresp  = 2'b11;
    m_ruser  = 1'b1;
    m_rlast  = (bfm_rq_id.size() > 0) && (bfm_rq_n[0] <= 1);
  end

  // ---- initial upstream idle values --------------------------------------
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

  // ---------------------------------------------------------------------------
  // CHECKER MODEL
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

  aw_rec_t exp_aw_q[$];
  aw_rec_t w_owner_q[$];
  w_rec_t  exp_w_q[$];
  ar_rec_t exp_ar_q[$];
  b_rec_t  exp_b_q[$];
  r_rec_t  exp_r_q[$];

  aw_rec_t aw_push, aw_chk, owner_chk;
  w_rec_t  w_push, w_chk;
  ar_rec_t ar_push, ar_chk;
  b_rec_t  b_push, b_chk;
  r_rec_t  r_push, r_chk;

  bit atomic_known [0:15];
  bit atomic_need_r [0:15];
  bit atomic_wlast_seen [0:15];
  bit atomic_b_done [0:15];
  bit atomic_deadline_en [0:15];
  int atomic_r_expect [0:15];
  int atomic_r_got [0:15];
  int atomic_deadline [0:15];

  int dn_debt;
  int debt_next;
  int dn_aw_count;
  int dn_wlast_count;
  int pass_b_count;
  int pass_r_count;

  bit hold_b;
  logic [3:0] hold_bid;
  logic [1:0] hold_bresp;
  logic       hold_buser;

  bit hold_r;
  logic [3:0]  hold_rid;
  logic [31:0] hold_rdata;
  logic [1:0]  hold_rresp;
  logic        hold_rlast;
  logic        hold_ruser;

  bit verdict_printed = 1'b0;
  bit seen_posedge = 1'b0;
  integer mon_i;

  task automatic fail_now(input string clause_name, input string msg);
    if (!verdict_printed) begin
      verdict_printed = 1'b1;
      $display("FAIL %s: %s", clause_name, msg);
      $display("RESULT: FAIL");
      $finish;
    end
  endtask

  task automatic pass_now;
    if (!verdict_printed) begin
      verdict_printed = 1'b1;
      $display("RESULT: PASS");
      $finish;
    end
  endtask

  // Reset observability is checked on the falling edge after at least one
  // rising edge, so we never sample pre-first-edge unknown register state.
  always @(posedge clk) begin
    seen_posedge = 1'b1;
  end

  always @(negedge clk) begin
    if (seen_posedge && !rst_n) begin
      if (m_awvalid !== 1'b0)
        fail_now("X1", "m_awvalid_o is not low during reset");

      if (m_wvalid !== 1'b0)
        fail_now("X1", "m_wvalid_o is not low during reset");

      if ((m_bvalid === 1'b0) && (s_bvalid !== 1'b0))
        fail_now("X1",
                 "B appeared during reset while the downstream B input was quiet");

      if ((m_rvalid === 1'b0) && (s_rvalid !== 1'b0))
        fail_now("X1",
                 "R appeared during reset while the downstream R input was quiet");
    end
  end

  // Main scoreboard. Ordering within this block is intentional: upstream
  // acceptance is recorded before a same-cycle downstream transfer is checked.
  always @(posedge clk) begin
    if (!rst_n) begin
      exp_aw_q.delete();
      w_owner_q.delete();
      exp_w_q.delete();
      exp_ar_q.delete();
      exp_b_q.delete();
      exp_r_q.delete();

      dn_debt = 0;
      dn_aw_count = 0;
      dn_wlast_count = 0;
      pass_b_count = 0;
      pass_r_count = 0;
      hold_b = 1'b0;
      hold_r = 1'b0;

      for (mon_i = 0; mon_i < 16; mon_i = mon_i + 1) begin
        atomic_known[mon_i] = 1'b0;
        atomic_need_r[mon_i] = 1'b0;
        atomic_wlast_seen[mon_i] = 1'b0;
        atomic_b_done[mon_i] = 1'b0;
        atomic_deadline_en[mon_i] = 1'b0;
        atomic_r_expect[mon_i] = 0;
        atomic_r_got[mon_i] = 0;
        atomic_deadline[mon_i] = 0;
      end

    end else begin

      // X3: slave-side B output must remain asserted and stable while stalled.
      if (hold_b) begin
        if (s_bvalid !== 1'b1)
          fail_now("X3", "B valid dropped before ready handshake");

        if ((s_bid !== hold_bid) ||
            (s_bresp !== hold_bresp) ||
            (s_buser !== hold_buser))
          fail_now("X3", "B payload changed while valid was stalled");
      end

      hold_b = s_bvalid && !s_bready;

      if (hold_b) begin
        hold_bid = s_bid;
        hold_bresp = s_bresp;
        hold_buser = s_buser;
      end

      // X3: slave-side R output must remain asserted and stable while stalled.
      if (hold_r) begin
        if (s_rvalid !== 1'b1)
          fail_now("X3", "R valid dropped before ready handshake");

        if ((s_rid !== hold_rid) ||
            (s_rdata !== hold_rdata) ||
            (s_rresp !== hold_rresp) ||
            (s_rlast !== hold_rlast) ||
            (s_ruser !== hold_ruser))
          fail_now("X3", "R payload changed while valid was stalled");
      end

      hold_r = s_rvalid && !s_rready;

      if (hold_r) begin
        hold_rid = s_rid;
        hold_rdata = s_rdata;
        hold_rresp = s_rresp;
        hold_rlast = s_rlast;
        hold_ruser = s_ruser;
      end

      // Upstream AW handshake: classify only on ATOP[5:4].
      if (s_awvalid && s_awready) begin
        aw_push.id = s_awid;
        aw_push.addr = s_awaddr;
        aw_push.len = s_awlen;
        aw_push.size = s_awsize;
        aw_push.burst = s_awburst;
        aw_push.lock = s_awlock;
        aw_push.cache = s_awcache;
        aw_push.prot = s_awprot;
        aw_push.qos = s_awqos;
        aw_push.region = s_awregion;
        aw_push.atop = s_awatop;
        aw_push.user = s_awuser;

        w_owner_q.push_back(aw_push);

        if (s_awatop[5:4] == 2'b00) begin
          exp_aw_q.push_back(aw_push);
        end else begin
          if (atomic_known[s_awid])
            fail_now("test bookkeeping",
                     $sformatf("atomic ID %0d reused before reset", s_awid));

          atomic_known[s_awid] = 1'b1;
          atomic_need_r[s_awid] = s_awatop[5];

          atomic_r_expect[s_awid] =
              s_awatop[5] ? (int'(s_awlen) + 1) : 0;

          atomic_r_got[s_awid] = 0;
          atomic_b_done[s_awid] = 1'b0;
          atomic_wlast_seen[s_awid] = 1'b0;
          atomic_deadline_en[s_awid] = 1'b0;
        end
      end

      // Downstream AW must correspond exactly to a non-atomic AW and ATOP=0.
      if (m_awvalid && m_awready) begin
        if (exp_aw_q.size() == 0)
          fail_now("F1/C1",
                   $sformatf(
                     "unexpected downstream AW id=%0d; atomic AW was forwarded",
                     m_awid));

        aw_chk = exp_aw_q.pop_front();

        if ((m_awid !== aw_chk.id) ||
            (m_awaddr !== aw_chk.addr) ||
            (m_awlen !== aw_chk.len) ||
            (m_awsize !== aw_chk.size) ||
            (m_awburst !== aw_chk.burst) ||
            (m_awlock !== aw_chk.lock) ||
            (m_awcache !== aw_chk.cache) ||
            (m_awprot !== aw_chk.prot) ||
            (m_awqos !== aw_chk.qos) ||
            (m_awregion !== aw_chk.region) ||
            (m_awuser !== aw_chk.user))
          fail_now("P1",
                   $sformatf(
                     "non-atomic AW payload changed for id=%0d",
                     aw_chk.id));

        if (m_awatop !== 6'b000000)
          fail_now("F1",
                   $sformatf(
                     "m_awatop_o=%02h while m_awvalid_o for id=%0d",
                     m_awatop,
                     m_awid));

        dn_aw_count = dn_aw_count + 1;
      end

      // Upstream W handshake: ownership is by accepted AW order, never by data.
      if (s_wvalid && s_wready) begin
        if (w_owner_q.size() == 0)
          fail_now("AXI/X3",
                   "W beat accepted without a previously accepted AW");

        owner_chk = w_owner_q[0];

        if (owner_chk.atop[5:4] == 2'b00) begin
          w_push.data = s_wdata;
          w_push.strb = s_wstrb;
          w_push.last = s_wlast;
          w_push.user = s_wuser;
          exp_w_q.push_back(w_push);
        end

        if (s_wlast) begin
          void'(w_owner_q.pop_front());

          if (owner_chk.atop[5:4] != 2'b00) begin
            atomic_wlast_seen[owner_chk.id] = 1'b1;
            atomic_deadline[owner_chk.id] = bfm_cycle + 64;
            atomic_deadline_en[owner_chk.id] = 1'b1;
          end
        end
      end

      // Any downstream W must be the next W beat of a forwarded write.
      if (m_wvalid && m_wready) begin
        if (exp_w_q.size() == 0)
          fail_now(
            "F2/P2",
            "unexpected downstream W beat; filtered W was forwarded or order was corrupted"
          );

        w_chk = exp_w_q.pop_front();

        if ((m_wdata !== w_chk.data) ||
            (m_wstrb !== w_chk.strb) ||
            (m_wlast !== w_chk.last) ||
            (m_wuser !== w_chk.user))
          fail_now("P2",
                   "forwarded W beat payload/order/WLAST changed");

        if (m_wlast)
          dn_wlast_count = dn_wlast_count + 1;
      end

      // AR is always pass-through and every field is observable here.
      if (s_arvalid && s_arready) begin
        ar_push.id = s_arid;
        ar_push.addr = s_araddr;
        ar_push.len = s_arlen;
        ar_push.size = s_arsize;
        ar_push.burst = s_arburst;
        ar_push.lock = s_arlock;
        ar_push.cache = s_arcache;
        ar_push.prot = s_arprot;
        ar_push.qos = s_arqos;
        ar_push.region = s_arregion;
        ar_push.user = s_aruser;
        exp_ar_q.push_back(ar_push);
      end

      if (m_arvalid && m_arready) begin
        if (exp_ar_q.size() == 0)
          fail_now("P3", "unexpected downstream AR");

        ar_chk = exp_ar_q.pop_front();

        if ((m_arid !== ar_chk.id) ||
            (m_araddr !== ar_chk.addr) ||
            (m_arlen !== ar_chk.len) ||
            (m_arsize !== ar_chk.size) ||
            (m_arburst !== ar_chk.burst) ||
            (m_arlock !== ar_chk.lock) ||
            (m_arcache !== ar_chk.cache) ||
            (m_arprot !== ar_chk.prot) ||
            (m_arqos !== ar_chk.qos) ||
            (m_arregion !== ar_chk.region) ||
            (m_aruser !== ar_chk.user))
          fail_now("P3",
                   $sformatf("AR payload changed for id=%0d", ar_chk.id));
      end

      // Capture downstream responses when the DUT accepts them. This permits
      // either a combinational pass-through or internal buffering.
      if (m_bvalid && m_bready) begin
        b_push.id = m_bid;
        b_push.resp = m_bresp;
        b_push.user = m_buser;
        exp_b_q.push_back(b_push);
      end

      if (m_rvalid && m_rready) begin
        r_push.id = m_rid;
        r_push.data = m_rdata;
        r_push.resp = m_rresp;
        r_push.last = m_rlast;
        r_push.user = m_ruser;
        exp_r_q.push_back(r_push);
      end

      // Slave-side B: manufactured responses are fixed SLVERR; pass-through
      // responses use the subordinate's non-SLVERR value and compare exactly.
      if (s_bvalid && s_bready) begin
        if (s_bresp == 2'b10) begin
          if (!atomic_known[s_bid])
            fail_now("F3/P4",
                     $sformatf("unexpected manufactured B id=%0d", s_bid));

          if (atomic_b_done[s_bid])
            fail_now("F3",
                     $sformatf(
                       "more than one manufactured B for atomic id=%0d",
                       s_bid));

          atomic_b_done[s_bid] = 1'b1;

        end else begin
          if (exp_b_q.size() == 0)
            fail_now("P4/F3",
                     $sformatf(
                       "unexpected non-SLVERR B id=%0d resp=%0b",
                       s_bid,
                       s_bresp));

          b_chk = exp_b_q.pop_front();

          if ((s_bid !== b_chk.id) ||
              (s_bresp !== b_chk.resp) ||
              (s_buser !== b_chk.user))
            fail_now(
              "P4",
              $sformatf(
                "B pass-through altered: expected id=%0d resp=%0b user=%0b",
                b_chk.id,
                b_chk.resp,
                b_chk.user
              )
            );

          pass_b_count = pass_b_count + 1;
        end
      end

      // Slave-side R: attribute manufactured responses by RID, exactly as F4
      // requires. Never infer ownership from stream position or B ordering.
      if (s_rvalid && s_rready) begin
        if (s_rresp == 2'b10) begin
          if (!atomic_known[s_rid])
            fail_now("F4/P3",
                     $sformatf(
                       "unexpected manufactured R id=%0d",
                       s_rid));

          if (!atomic_need_r[s_rid])
            fail_now("F5",
                     $sformatf(
                       "atomic id=%0d does not owe any R beats",
                       s_rid));

          if (atomic_r_got[s_rid] >= atomic_r_expect[s_rid])
            fail_now("F4",
                     $sformatf(
                       "too many manufactured R beats for id=%0d",
                       s_rid));

          atomic_r_got[s_rid] = atomic_r_got[s_rid] + 1;

          if (atomic_r_got[s_rid] == atomic_r_expect[s_rid]) begin
            if (s_rlast !== 1'b1)
              fail_now(
                "F4",
                $sformatf(
                  "final manufactured R missing RLAST for id=%0d",
                  s_rid
                )
              );
          end else begin
            if (s_rlast !== 1'b0)
              fail_now(
                "F4",
                $sformatf(
                  "early RLAST on manufactured R beat %0d/%0d for id=%0d",
                  atomic_r_got[s_rid],
                  atomic_r_expect[s_rid],
                  s_rid
                )
              );
          end

        end else begin
          if (exp_r_q.size() == 0)
            fail_now(
              "P3/F4",
              $sformatf(
                "unexpected non-SLVERR R id=%0d resp=%0b",
                s_rid,
                s_rresp
              )
            );

          r_chk = exp_r_q.pop_front();

          if ((s_rid !== r_chk.id) ||
              (s_rdata !== r_chk.data) ||
              (s_rresp !== r_chk.resp) ||
              (s_rlast !== r_chk.last) ||
              (s_ruser !== r_chk.user))
            fail_now(
              "P3",
              $sformatf(
                "R pass-through altered for id=%0d",
                r_chk.id
              )
            );

          pass_r_count = pass_r_count + 1;
        end
      end

      // W1/W2/W4/W5: debt is defined only by downstream handshakes.
      debt_next = dn_debt;

      if (m_awvalid && m_awready)
        debt_next = debt_next + 1;

      if (m_wvalid && m_wready && m_wlast)
        debt_next = debt_next - 1;

      if (debt_next > 4)
        fail_now(
          "W2",
          $sformatf(
            "downstream write debt reached %0d (>4)",
            debt_next
          )
        );

      if (debt_next < 0)
        fail_now(
          "W1/P2",
          $sformatf(
            "downstream write debt became negative (%0d)",
            debt_next
          )
        );

      dn_debt = debt_next;

      // If response-ready was ever withheld after WLAST, X4's 64-cycle
      // response bound is not applicable to that transaction.
      for (mon_i = 0; mon_i < 16; mon_i = mon_i + 1) begin
        if (atomic_known[mon_i] &&
            atomic_wlast_seen[mon_i] &&
            atomic_deadline_en[mon_i]) begin

          if (!s_bready ||
              (atomic_need_r[mon_i] && !s_rready))
            atomic_deadline_en[mon_i] = 1'b0;

          if (atomic_deadline_en[mon_i] &&
              (bfm_cycle >= atomic_deadline[mon_i])) begin

            if (!atomic_b_done[mon_i] ||
                (atomic_r_got[mon_i] != atomic_r_expect[mon_i]))
              fail_now(
                "X4/F3/F4",
                $sformatf(
                  "atomic id=%0d responses not complete within 64 cycles of WLAST",
                  mon_i
                )
              );
          end
        end
      end
    end
  end

  // ---------------------------------------------------------------------------
  // EXTENDED BFM HELPERS -- same edge discipline as the supplied plumbing.
  // ---------------------------------------------------------------------------

  task automatic bfm_aw_full(
    input logic [3:0] id,
    input logic [31:0] addr,
    input logic [7:0] len,
    input logic [5:0] atop,
    input logic [2:0] size,
    input logic [1:0] burst,
    input logic lock,
    input logic [3:0] cache,
    input logic [2:0] prot,
    input logic [3:0] qos,
    input logic [3:0] region,
    input logic user,
    input int timeout,
    output bit accepted
  );
    int t;

    @(negedge clk);

    s_awid = id;
    s_awaddr = addr;
    s_awlen = len;
    s_awatop = atop;
    s_awsize = size;
    s_awburst = burst;
    s_awlock = lock;
    s_awcache = cache;
    s_awprot = prot;
    s_awqos = qos;
    s_awregion = region;
    s_awuser = user;
    s_awvalid = 1'b1;

    accepted = 1'b0;

    for (t = 0; t < timeout; t++) begin
      @(posedge clk);
      if (s_awready) begin
        accepted = 1'b1;
        break;
      end
    end

    @(negedge clk);
    s_awvalid = 1'b0;
  endtask

  task automatic bfm_w_full(
    input logic [31:0] data,
    input logic [3:0] strb,
    input logic last,
    input logic user,
    input int timeout,
    output bit accepted
  );
    int t;

    @(negedge clk);

    s_wdata = data;
    s_wstrb = strb;
    s_wlast = last;
    s_wuser = user;
    s_wvalid = 1'b1;

    accepted = 1'b0;

    for (t = 0; t < timeout; t++) begin
      @(posedge clk);
      if (s_wready) begin
        accepted = 1'b1;
        break;
      end
    end

    @(negedge clk);
    s_wvalid = 1'b0;
  endtask

  task automatic bfm_ar_full(
    input logic [3:0] id,
    input logic [31:0] addr,
    input logic [7:0] len,
    input logic [2:0] size,
    input logic [1:0] burst,
    input logic lock,
    input logic [3:0] cache,
    input logic [2:0] prot,
    input logic [3:0] qos,
    input logic [3:0] region,
    input logic user,
    input int timeout,
    output bit accepted
  );
    int t;

    @(negedge clk);

    s_arid = id;
    s_araddr = addr;
    s_arlen = len;
    s_arsize = size;
    s_arburst = burst;
    s_arlock = lock;
    s_arcache = cache;
    s_arprot = prot;
    s_arqos = qos;
    s_arregion = region;
    s_aruser = user;
    s_arvalid = 1'b1;

    accepted = 1'b0;

    for (t = 0; t < timeout; t++) begin
      @(posedge clk);
      if (s_arready) begin
        accepted = 1'b1;
        break;
      end
    end

    @(negedge clk);
    s_arvalid = 1'b0;
  endtask

  task automatic must_aw_full(
    input logic [3:0] id,
    input logic [31:0] addr,
    input logic [7:0] len,
    input logic [5:0] atop,
    input logic [2:0] size,
    input logic [1:0] burst,
    input logic lock,
    input logic [3:0] cache,
    input logic [2:0] prot,
    input logic [3:0] qos,
    input logic [3:0] region,
    input logic user,
    input string clause_name
  );
    bit accepted;

    bfm_aw_full(
      id,
      addr,
      len,
      atop,
      size,
      burst,
      lock,
      cache,
      prot,
      qos,
      region,
      user,
      64,
      accepted
    );

    if (!accepted)
      fail_now(
        clause_name,
        $sformatf(
          "AW id=%0d was not accepted within 64 cycles",
          id
        )
      );
  endtask

  task automatic must_w_full(
    input logic [31:0] data,
    input logic [3:0] strb,
    input logic last,
    input logic user,
    input string clause_name
  );
    bit accepted;

    bfm_w_full(
      data,
      strb,
      last,
      user,
      64,
      accepted
    );

    if (!accepted)
      fail_now(
        clause_name,
        "W beat was not accepted within 64 cycles"
      );
  endtask

  task automatic must_ar_full(
    input logic [3:0] id,
    input logic [31:0] addr,
    input logic [7:0] len,
    input logic [2:0] size,
    input logic [1:0] burst,
    input logic lock,
    input logic [3:0] cache,
    input logic [2:0] prot,
    input logic [3:0] qos,
    input logic [3:0] region,
    input logic user,
    input string clause_name
  );
    bit accepted;

    bfm_ar_full(
      id,
      addr,
      len,
      size,
      burst,
      lock,
      cache,
      prot,
      qos,
      region,
      user,
      64,
      accepted
    );

    if (!accepted)
      fail_now(
        clause_name,
        $sformatf(
          "AR id=%0d was not accepted within 64 cycles",
          id
        )
      );
  endtask

  task automatic wait_atomic_complete(
    input logic [3:0] id,
    input int max_cycles
  );
    int t;
    bit done;

    done = 1'b0;

    for (t = 0; t < max_cycles; t++) begin
      if (atomic_known[id] &&
          atomic_b_done[id] &&
          (atomic_r_got[id] == atomic_r_expect[id])) begin
        done = 1'b1;
        break;
      end

      @(posedge clk);
    end

    if (atomic_known[id] &&
        atomic_b_done[id] &&
        (atomic_r_got[id] == atomic_r_expect[id]))
      done = 1'b1;

    if (!done)
      fail_now(
        "X4/F3/F4",
        $sformatf(
          "atomic id=%0d did not complete",
          id
        )
      );
  endtask

  task automatic wait_dn_aw_count(
    input int target,
    input int max_cycles,
    input string clause_name
  );
    int t;
    bit done;

    done = 1'b0;

    for (t = 0; t < max_cycles; t++) begin
      if (dn_aw_count >= target) begin
        done = 1'b1;
        break;
      end

      @(posedge clk);
    end

    if (dn_aw_count >= target)
      done = 1'b1;

    if (!done)
      fail_now(
        clause_name,
        $sformatf(
          "downstream AW count did not reach %0d",
          target
        )
      );
  endtask

  task automatic wait_pass_b_count(
    input int target,
    input int max_cycles
  );
    int t;
    bit done;

    done = 1'b0;

    for (t = 0; t < max_cycles; t++) begin
      if (pass_b_count >= target) begin
        done = 1'b1;
        break;
      end

      @(posedge clk);
    end

    if (pass_b_count >= target)
      done = 1'b1;

    if (!done)
      fail_now(
        "P4/X4",
        $sformatf(
          "pass-through B count did not reach %0d",
          target
        )
      );
  endtask

  task automatic wait_pass_r_count(
    input int target,
    input int max_cycles
  );
    int t;
    bit done;

    done = 1'b0;

    for (t = 0; t < max_cycles; t++) begin
      if (pass_r_count >= target) begin
        done = 1'b1;
        break;
      end

      @(posedge clk);
    end

    if (pass_r_count >= target)
      done = 1'b1;

    if (!done)
      fail_now(
        "P3/X4",
        $sformatf(
          "pass-through R count did not reach %0d",
          target
        )
      );
  endtask

  // ---------------------------------------------------------------------------
  // DIRECTED STIMULUS
  // ---------------------------------------------------------------------------
  initial begin
    bit early_accepted;
    bit saw_b_stall;
    bit saw_r_stall;
    int base_b;
    int base_r;
    int base_aw;
    int t;

    // Establish defined reset state first.
    bfm_reset(5);
    repeat (2) @(posedge clk);

    // X1/X2: present an atomic AW/W while reset is asserted. It must neither
    // originate downstream traffic nor leave a transaction/response behind.
    @(negedge clk);

    rst_n = 1'b0;

    s_awid = 4'hF;
    s_awaddr = 32'hDEAD_0000;
    s_awlen = 8'd0;
    s_awatop = 6'b10_1111;
    s_awsize = 3'd2;
    s_awburst = 2'b01;
    s_awlock = 1'b0;
    s_awcache = 4'hF;
    s_awprot = 3'h7;
    s_awqos = 4'hF;
    s_awregion = 4'hF;
    s_awuser = 1'b1;
    s_awvalid = 1'b1;

    s_wdata = 32'hDEAD_BEEF;
    s_wstrb = 4'hF;
    s_wlast = 1'b1;
    s_wuser = 1'b1;
    s_wvalid = 1'b1;

    repeat (3) @(posedge clk);

    @(negedge clk);

    s_awvalid = 1'b0;
    s_wvalid = 1'b0;
    rst_n = 1'b1;

    repeat (5) @(posedge clk);

    // P1/P2/C1/F1: lower ATOP bits are nonzero, but [5:4]==00, so this is
    // non-atomic. Exercise every AW field plus a 3-beat W burst.
    bfm_dn_b_lag(6);

    base_b = pass_b_count;

    must_aw_full(
      4'h1,
      32'hA123_4564,
      8'd2,
      6'b00_1011,
      3'd2,
      2'b01,
      1'b1,
      4'hA,
      3'h5,
      4'h9,
      4'h3,
      1'b1,
      "C1/P1/X4"
    );

    must_w_full(
      32'h1111_AAAA,
      4'b0001,
      1'b0,
      1'b1,
      "P2/X4"
    );

    must_w_full(
      32'h2222_BBBB,
      4'b1010,
      1'b0,
      1'b0,
      "P2/X4"
    );

    must_w_full(
      32'h3333_CCCC,
      4'b1110,
      1'b1,
      1'b1,
      "P2/X4"
    );

    wait_pass_b_count(base_b + 1, 80);

    // P3: full-field AR plus a multi-beat downstream R stream. A read is never
    // filtered, and DECERR/user=1/data/RLAST must all return unmodified.
    base_r = pass_r_count;

    must_ar_full(
      4'h2,
      32'h0BAD_C0D0,
      8'd2,
      3'd2,
      2'b01,
      1'b1,
      4'h5,
      3'h3,
      4'hC,
      4'h7,
      1'b1,
      "P3/X4"
    );

    // Intercept the first R before its handshake when possible, then hold it
    // stalled for several cycles to exercise X3 without assuming a latency.
    saw_r_stall = 1'b0;

    if (s_rvalid) begin
      s_rready = 1'b0;
      saw_r_stall = 1'b1;
    end else begin
      for (t = 0; t < 12; t++) begin
        @(negedge clk);

        if (s_rvalid) begin
          s_rready = 1'b0;
          saw_r_stall = 1'b1;
          break;
        end
      end
    end

    if (saw_r_stall) begin
      repeat (4) @(posedge clk);
      @(negedge clk);
      s_rready = 1'b1;
    end

    wait_pass_r_count(base_r + 3, 80);

    // F2/F3/F5/C2: 01 is atomic but does not owe R. Use a multi-beat W burst.
    must_aw_full(
      4'h8,
      32'hA123_4564,
      8'd2,
      6'b01_1111,
      3'd2,
      2'b01,
      1'b0,
      4'h2,
      3'h1,
      4'h4,
      4'h8,
      1'b1,
      "C1/F1/X4"
    );

    must_w_full(
      32'h8100_0001,
      4'hF,
      1'b0,
      1'b1,
      "F2/X4"
    );

    must_w_full(
      32'h8100_0002,
      4'h3,
      1'b0,
      1'b0,
      "F2/X4"
    );

    must_w_full(
      32'h8100_0003,
      4'hC,
      1'b1,
      1'b1,
      "F2/X4"
    );

    wait_atomic_complete(4'h8, 70);
    repeat (8) @(posedge clk);

    // F4/L1/L5: 10 owes LEN+1 R beats. Leave several cycles between AW and W
    // so a correct design is free to emit R before B and before W completion.
    must_aw_full(
      4'h9,
      32'h9000_0040,
      8'd3,
      6'b10_0011,
      3'd2,
      2'b01,
      1'b0,
      4'h6,
      3'h2,
      4'h5,
      4'h9,
      1'b0,
      "C1/C2/F1/X4"
    );

    repeat (3) @(posedge clk);

    must_w_full(
      32'h9200_0001,
      4'h1,
      1'b0,
      1'b0,
      "F2/X4"
    );

    must_w_full(
      32'h9200_0002,
      4'h2,
      1'b0,
      1'b1,
      "F2/X4"
    );

    must_w_full(
      32'h9200_0003,
      4'h4,
      1'b0,
      1'b0,
      "F2/X4"
    );

    must_w_full(
      32'h9200_0004,
      4'h8,
      1'b1,
      1'b1,
      "F2/X4"
    );

    wait_atomic_complete(4'h9, 70);

    // C2's other read-producing class: 11 also owes R, here exactly one beat.
    must_aw_full(
      4'hA,
      32'h9000_0080,
      8'd0,
      6'b11_0000,
      3'd2,
      2'b01,
      1'b0,
      4'h1,
      3'h4,
      4'h6,
      4'hA,
      1'b1,
      "C1/C2/F1/X4"
    );

    must_w_full(
      32'hA300_0001,
      4'hF,
      1'b1,
      1'b0,
      "F2/X4"
    );

    wait_atomic_complete(4'hA, 70);

    // P4/X3: arrange a delayed normal B, catch valid at a falling edge before
    // its transfer, then backpressure it. The checker verifies stable payload.
    bfm_dn_b_lag(5);

    base_b = pass_b_count;

    must_aw_full(
      4'h5,
      32'h5000_0000,
      8'd0,
      6'b00_0000,
      3'd2,
      2'b01,
      1'b0,
      4'h3,
      3'h6,
      4'h2,
      4'h5,
      1'b1,
      "P1/X4"
    );

    must_w_full(
      32'h5500_0001,
      4'h5,
      1'b1,
      1'b1,
      "P2/X4"
    );

    saw_b_stall = 1'b0;

    for (t = 0; t < 12; t++) begin
      if (s_bvalid) begin
        s_bready = 1'b0;
        saw_b_stall = 1'b1;
        break;
      end

      @(negedge clk);
    end

    if (saw_b_stall) begin
      repeat (4) @(posedge clk);
      @(negedge clk);
      s_bready = 1'b1;
    end

    wait_pass_b_count(base_b + 1, 80);

    // Reset between functional and debt stress; no pre-reset transaction may
    // influence the next phase (X2).
    bfm_reset(5);
    repeat (2) @(posedge clk);

    bfm_dn_b_lag(500);

    // W2/W3: build downstream debt deliberately to exactly four by withholding
    // every W burst. A too-small bound fails to reach four; a too-large bound
    // is caught if a fifth AW reaches the master port.
    base_aw = dn_aw_count;

    must_aw_full(
      4'h0,
      32'h1000_0000,
      8'd0,
      6'b00_0000,
      3'd2,
      2'b01,
      1'b0,
      4'h0,
      3'h0,
      4'h0,
      4'h0,
      1'b0,
      "W3/X4"
    );

    must_aw_full(
      4'h1,
      32'h1000_0100,
      8'd0,
      6'b00_0000,
      3'd2,
      2'b01,
      1'b0,
      4'h1,
      3'h1,
      4'h1,
      4'h1,
      1'b1,
      "W3/X4"
    );

    must_aw_full(
      4'h2,
      32'h1000_0200,
      8'd0,
      6'b00_0000,
      3'd2,
      2'b01,
      1'b0,
      4'h2,
      3'h2,
      4'h2,
      4'h2,
      1'b0,
      "W3/X4"
    );

    must_aw_full(
      4'h3,
      32'h1000_0300,
      8'd0,
      6'b00_0000,
      3'd2,
      2'b01,
      1'b0,
      4'h3,
      3'h3,
      4'h3,
      4'h3,
      1'b1,
      "W3/X4"
    );

    wait_dn_aw_count(base_aw + 4, 70, "W3");

    if (dn_debt != 4)
      fail_now(
        "W1/W2",
        $sformatf(
          "expected debt 4 after four AWs and no WLAST, got %0d",
          dn_debt
        )
      );

    // The write bound must not throttle reads.
    base_r = pass_r_count;

    must_ar_full(
      4'h7,
      32'h7000_0000,
      8'd1,
      3'd2,
      2'b01,
      1'b0,
      4'h7,
      3'h7,
      4'h7,
      4'h7,
      1'b1,
      "P3/X4"
    );

    wait_pass_r_count(base_r + 2, 80);

    // At debt==4, upstream acceptance of a fifth AW is implementation latitude
    // (it may buffer it), but downstream debt must not become five.
    bfm_aw_full(
      4'h4,
      32'h1000_0400,
      8'd0,
      6'b00_1111,
      3'd2,
      2'b01,
      1'b0,
      4'h4,
      3'h4,
      4'h4,
      4'h4,
      1'b0,
      8,
      early_accepted
    );

    repeat (8) @(posedge clk);

    if (dn_aw_count != base_aw + 4)
      fail_now(
        "W2",
        "fifth downstream AW was forwarded while debt was already four"
      );

    // W4: completing the first W burst reduces debt even though B is delayed
    // hundreds of cycles. The fifth AW must then be able to proceed.
    must_w_full(
      32'hD000_0000,
      4'hF,
      1'b1,
      1'b0,
      "P2/W4/X4"
    );

    if (!early_accepted) begin
      must_aw_full(
        4'h4,
        32'h1000_0400,
        8'd0,
        6'b00_1111,
        3'd2,
        2'b01,
        1'b0,
        4'h4,
        3'h4,
        4'h4,
        4'h4,
        1'b0,
        "W4/X4"
      );
    end

    wait_dn_aw_count(base_aw + 5, 64, "W4/W3");

    // Drain the four remaining W bursts in accepted-AW order.
    must_w_full(
      32'hD100_0001,
      4'h1,
      1'b1,
      1'b1,
      "P2/X4"
    );

    must_w_full(
      32'hD200_0002,
      4'h2,
      1'b1,
      1'b0,
      "P2/X4"
    );

    must_w_full(
      32'hD300_0003,
      4'h4,
      1'b1,
      1'b1,
      "P2/X4"
    );

    must_w_full(
      32'hD400_0004,
      4'h8,
      1'b1,
      1'b0,
      "P2/X4"
    );

    repeat (4) @(posedge clk);

    if (dn_debt != 0)
      fail_now(
        "W1/W4",
        $sformatf(
          "debt did not return to zero after five WLASTs; got %0d",
          dn_debt
        )
      );

    // One final reset clears the deliberately delayed B responses and also
    // rechecks X2 (reset forgets all held transactions).
    bfm_reset(5);
    repeat (5) @(posedge clk);

    if ((exp_aw_q.size() != 0) ||
        (w_owner_q.size() != 0) ||
        (exp_w_q.size() != 0) ||
        (exp_ar_q.size() != 0) ||
        (exp_b_q.size() != 0) ||
        (exp_r_q.size() != 0))
      fail_now(
        "X2",
        "checker observed a pre-reset transaction after reset"
      );

    pass_now();
  end

  // ---- watchdog ------------------------------------------------------------
  initial begin
    #4_000_000;
    fail_now(
      "Termination/X4",
      "watchdog: no forward progress"
    );
  end

endmodule