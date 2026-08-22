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

  atop_filter #(
    .ID_W(4),
    .ADDR_W(32),
    .DATA_W(32),
    .USER_W(1)
  ) dut (
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

  // ---- upstream: offering requests to the design ---------------------------

  task automatic bfm_aw(
      input logic [3:0] id,
      input logic [31:0] addr,
      input logic [7:0] len,
      input logic [5:0] atop,
      input int timeout,
      output bit accepted);
    int t;
    @(negedge clk);
    s_awid = id;
    s_awaddr = addr;
    s_awlen = len;
    s_awatop = atop;
    s_awsize = 3'd2;
    s_awburst = 2'd1;
    s_awlock = 1'b0;
    s_awcache = 4'd0;
    s_awprot = 3'd0;
    s_awqos = 4'd0;
    s_awregion = 4'd0;
    s_awuser = 1'b0;
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

  task automatic bfm_w(
      input logic [31:0] data,
      input logic [3:0] strb,
      input bit last,
      input int timeout,
      output bit accepted);
    int t;
    @(negedge clk);
    s_wdata = data;
    s_wstrb = strb;
    s_wlast = last;
    s_wuser = 1'b0;
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

  task automatic bfm_ar(
      input logic [3:0] id,
      input logic [31:0] addr,
      input logic [7:0] len,
      input int timeout,
      output bit accepted);
    int t;
    @(negedge clk);
    s_arid = id;
    s_araddr = addr;
    s_arlen = len;
    s_arsize = 3'd2;
    s_arburst = 2'd1;
    s_arlock = 1'b0;
    s_arcache = 4'd0;
    s_arprot = 3'd0;
    s_arqos = 4'd0;
    s_arregion = 4'd0;
    s_aruser = 1'b0;
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

  task automatic bfm_b_ready(input bit v);
    @(negedge clk);
    s_bready = v;
  endtask

  task automatic bfm_r_ready(input bit v);
    @(negedge clk);
    s_rready = v;
  endtask

  // ---- downstream: this plumbing is the SUBORDINATE ------------------------

  int bfm_b_lag = 0;

  task automatic bfm_dn_b_lag(input int cycles);
    bfm_b_lag = cycles;
  endtask

  int bfm_bq_id [$];
  int bfm_bq_t [$];
  int bfm_rq_id [$];
  int bfm_rq_n [$];

  logic tb_m_awready_ctl = 1'b1;
  logic tb_m_wready_ctl  = 1'b1;
  logic tb_m_arready_ctl = 1'b1;

  assign m_awready = tb_m_awready_ctl;
  assign m_wready  = tb_m_wready_ctl;
  assign m_arready = tb_m_arready_ctl;

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

  always_comb begin
    m_bvalid = (bfm_bq_id.size() > 0) &&
               (bfm_cycle >= bfm_bq_t[0]);
    m_bid = 4'(bfm_bq_id.size() ? bfm_bq_id[0] : 0);
    m_bresp = 2'b00;
    m_buser = 1'b0;

    m_rvalid = (bfm_rq_id.size() > 0);
    m_rid = 4'(bfm_rq_id.size() ? bfm_rq_id[0] : 0);
    m_rdata = 32'hFEED_0000 +
              32'(bfm_rq_n.size() ? bfm_rq_n[0] : 0);
    m_rresp = 2'b00;
    m_ruser = 1'b0;
    m_rlast = (bfm_rq_id.size() > 0) &&
              (bfm_rq_n[0] <= 1);
  end

  initial begin
    s_awvalid = 1'b0;
    s_wvalid = 1'b0;
    s_arvalid = 1'b0;
    s_bready = 1'b1;
    s_rready = 1'b1;

    s_awid = '0;
    s_awaddr = '0;
    s_awlen = '0;
    s_awsize = 3'd2;
    s_awburst = 2'd1;
    s_awlock = 1'b0;
    s_awcache = '0;
    s_awprot = '0;
    s_awqos = '0;
    s_awregion = '0;
    s_awatop = '0;
    s_awuser = 1'b0;

    s_wdata = '0;
    s_wstrb = 4'hF;
    s_wlast = 1'b0;
    s_wuser = 1'b0;

    s_arid = '0;
    s_araddr = '0;
    s_arlen = '0;
    s_arsize = 3'd2;
    s_arburst = 2'd1;
    s_arlock = 1'b0;
    s_arcache = '0;
    s_arprot = '0;
    s_arqos = '0;
    s_arregion = '0;
    s_aruser = 1'b0;
  end

  // ---- watchdog ------------------------------------------------------------
  initial begin
    #4_000_000;
    $display("FAIL termination/X4: watchdog: no forward progress");
    $display("RESULT: FAIL");
    $finish;
  end


  // ---------------------------------------------------------------------------
  // SELF-CHECKING SCOREBOARD / MONITORS
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

  aw_rec_t m_aw_log[$];
  w_rec_t  m_w_log[$];
  ar_rec_t m_ar_log[$];

  b_rec_t dn_b_fifo[$];
  r_rec_t dn_r_fifo[$];

  int sb_ok_count[0:15];
  int sb_err_count[0:15];
  int sr_ok_count[0:15];
  int sr_err_count[0:15];
  int sr_err_last_count[0:15];
  int sr_err_last_ordinal[0:15];

  int sb_ok_total;
  int sb_err_total;
  int sr_ok_total;
  int sr_err_total;

  int dn_write_debt;

  bit held_aw_valid;
  bit held_w_valid;
  bit held_ar_valid;
  bit held_b_valid;
  bit held_r_valid;

  aw_rec_t held_aw;
  w_rec_t held_w;
  ar_rec_t held_ar;
  b_rec_t held_b;
  r_rec_t held_r;

  task automatic tb_fail(
      input string clause_name,
      input string msg);
    $display("FAIL %s: %s", clause_name, msg);
    $display("RESULT: FAIL");
    $finish;
  endtask

  task automatic need(
      input bit ok,
      input string clause_name,
      input string msg);
    if (!ok)
      tb_fail(clause_name, msg);
  endtask

  task automatic quiet_cycles(input int n);
    int t;
    for (t = 0; t < n; t++)
      @(negedge clk);
  endtask

  task automatic wait_m_aw_size(
      input int target,
      input int max_cycles,
      input string clause_name);
    int t;
    bit done_flag;

    done_flag = (m_aw_log.size() >= target);

    for (t = 0; (t < max_cycles) && !done_flag; t++) begin
      @(negedge clk);
      done_flag = (m_aw_log.size() >= target);
    end

    if (!done_flag)
      tb_fail(
        clause_name,
        $sformatf("downstream AW count did not reach %0d", target)
      );
  endtask

  task automatic wait_m_w_size(
      input int target,
      input int max_cycles,
      input string clause_name);
    int t;
    bit done_flag;

    done_flag = (m_w_log.size() >= target);

    for (t = 0; (t < max_cycles) && !done_flag; t++) begin
      @(negedge clk);
      done_flag = (m_w_log.size() >= target);
    end

    if (!done_flag)
      tb_fail(
        clause_name,
        $sformatf("downstream W count did not reach %0d", target)
      );
  endtask

  task automatic wait_m_ar_size(
      input int target,
      input int max_cycles,
      input string clause_name);
    int t;
    bit done_flag;

    done_flag = (m_ar_log.size() >= target);

    for (t = 0; (t < max_cycles) && !done_flag; t++) begin
      @(negedge clk);
      done_flag = (m_ar_log.size() >= target);
    end

    if (!done_flag)
      tb_fail(
        clause_name,
        $sformatf("downstream AR count did not reach %0d", target)
      );
  endtask

  task automatic wait_sb_ok(
      input logic [3:0] id,
      input int target,
      input int max_cycles,
      input string clause_name);
    int t;
    bit done_flag;

    done_flag = (sb_ok_count[int'(id)] >= target);

    for (t = 0; (t < max_cycles) && !done_flag; t++) begin
      @(negedge clk);
      done_flag = (sb_ok_count[int'(id)] >= target);
    end

    if (!done_flag)
      tb_fail(
        clause_name,
        $sformatf(
          "upstream OKAY B count for id %0d did not reach %0d",
          id,
          target
        )
      );
  endtask

  task automatic wait_sr_ok(
      input logic [3:0] id,
      input int target,
      input int max_cycles,
      input string clause_name);
    int t;
    bit done_flag;

    done_flag = (sr_ok_count[int'(id)] >= target);

    for (t = 0; (t < max_cycles) && !done_flag; t++) begin
      @(negedge clk);
      done_flag = (sr_ok_count[int'(id)] >= target);
    end

    if (!done_flag)
      tb_fail(
        clause_name,
        $sformatf(
          "upstream OKAY R count for id %0d did not reach %0d",
          id,
          target
        )
      );
  endtask

  task automatic wait_filtered_counts(
      input logic [3:0] id,
      input int b_target,
      input int r_target,
      input int start_cycle,
      input string clause_name);
    bit done_flag;

    done_flag =
      (sb_err_count[int'(id)] >= b_target) &&
      (sr_err_count[int'(id)] >= r_target);

    while (!done_flag &&
           ((bfm_cycle - start_cycle) < 64)) begin
      @(negedge clk);
      done_flag =
        (sb_err_count[int'(id)] >= b_target) &&
        (sr_err_count[int'(id)] >= r_target);
    end

    if (!done_flag)
      tb_fail(
        clause_name,
        $sformatf(
          "manufactured responses for id %0d missed 64-cycle bound",
          id
        )
      );
  endtask

  task automatic check_aw_log(
      input int idx,
      input logic [3:0]  id,
      input logic [31:0] addr,
      input logic [7:0]  len,
      input logic [2:0]  size,
      input logic [1:0]  burst,
      input logic        lock,
      input logic [3:0]  cache,
      input logic [2:0]  prot,
      input logic [3:0]  qos,
      input logic [3:0]  region,
      input logic [5:0]  atop,
      input logic        user,
      input string       clause_name);
    aw_rec_t got;

    if ((idx < 0) || (idx >= m_aw_log.size()))
      tb_fail(
        clause_name,
        $sformatf("missing downstream AW log entry %0d", idx)
      );

    got = m_aw_log[idx];

    if ((got.id     !== id)     ||
        (got.addr   !== addr)   ||
        (got.len    !== len)    ||
        (got.size   !== size)   ||
        (got.burst  !== burst)  ||
        (got.lock   !== lock)   ||
        (got.cache  !== cache)  ||
        (got.prot   !== prot)   ||
        (got.qos    !== qos)    ||
        (got.region !== region) ||
        (got.atop   !== atop)   ||
        (got.user   !== user))
      tb_fail(
        clause_name,
        $sformatf(
          "downstream AW payload mismatch at log entry %0d",
          idx
        )
      );
  endtask

  task automatic check_w_log(
      input int idx,
      input logic [31:0] data,
      input logic [3:0]  strb,
      input logic        last,
      input logic        user,
      input string       clause_name);
    w_rec_t got;

    if ((idx < 0) || (idx >= m_w_log.size()))
      tb_fail(
        clause_name,
        $sformatf("missing downstream W log entry %0d", idx)
      );

    got = m_w_log[idx];

    if ((got.data !== data) ||
        (got.strb !== strb) ||
        (got.last !== last) ||
        (got.user !== user))
      tb_fail(
        clause_name,
        $sformatf(
          "downstream W payload mismatch at log entry %0d",
          idx
        )
      );
  endtask

  task automatic check_ar_log(
      input int idx,
      input logic [3:0]  id,
      input logic [31:0] addr,
      input logic [7:0]  len,
      input logic [2:0]  size,
      input logic [1:0]  burst,
      input logic        lock,
      input logic [3:0]  cache,
      input logic [2:0]  prot,
      input logic [3:0]  qos,
      input logic [3:0]  region,
      input logic        user,
      input string       clause_name);
    ar_rec_t got;

    if ((idx < 0) || (idx >= m_ar_log.size()))
      tb_fail(
        clause_name,
        $sformatf("missing downstream AR log entry %0d", idx)
      );

    got = m_ar_log[idx];

    if ((got.id     !== id)     ||
        (got.addr   !== addr)   ||
        (got.len    !== len)    ||
        (got.size   !== size)   ||
        (got.burst  !== burst)  ||
        (got.lock   !== lock)   ||
        (got.cache  !== cache)  ||
        (got.prot   !== prot)   ||
        (got.qos    !== qos)    ||
        (got.region !== region) ||
        (got.user   !== user))
      tb_fail(
        clause_name,
        $sformatf(
          "downstream AR payload mismatch at log entry %0d",
          idx
        )
      );
  endtask

  // Full-field source helpers used where the provided BFMs intentionally drive
  // mostly-zero sideband fields.

  task automatic tb_aw_full(
      input logic [3:0]  id,
      input logic [31:0] addr,
      input logic [7:0]  len,
      input logic [2:0]  size,
      input logic [1:0]  burst,
      input logic        lock,
      input logic [3:0]  cache,
      input logic [2:0]  prot,
      input logic [3:0]  qos,
      input logic [3:0]  region,
      input logic [5:0]  atop,
      input logic        user,
      input int          timeout,
      output bit         accepted);
    int t;

    @(negedge clk);
    s_awid = id;
    s_awaddr = addr;
    s_awlen = len;
    s_awsize = size;
    s_awburst = burst;
    s_awlock = lock;
    s_awcache = cache;
    s_awprot = prot;
    s_awqos = qos;
    s_awregion = region;
    s_awatop = atop;
    s_awuser = user;
    s_awvalid = 1'b1;
    accepted = 1'b0;

    for (t = 0; t < timeout; t++) begin
      @(posedge clk);
      if (s_awready === 1'b1) begin
        accepted = 1'b1;
        break;
      end
    end

    @(negedge clk);
    s_awvalid = 1'b0;
  endtask

  task automatic tb_w_full(
      input logic [31:0] data,
      input logic [3:0]  strb,
      input logic        last,
      input logic        user,
      input int          timeout,
      output bit         accepted);
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
      if (s_wready === 1'b1) begin
        accepted = 1'b1;
        break;
      end
    end

    @(negedge clk);
    s_wvalid = 1'b0;
  endtask

  task automatic tb_ar_full(
      input logic [3:0]  id,
      input logic [31:0] addr,
      input logic [7:0]  len,
      input logic [2:0]  size,
      input logic [1:0]  burst,
      input logic        lock,
      input logic [3:0]  cache,
      input logic [2:0]  prot,
      input logic [3:0]  qos,
      input logic [3:0]  region,
      input logic        user,
      input int          timeout,
      output bit         accepted);
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
      if (s_arready === 1'b1) begin
        accepted = 1'b1;
        break;
      end
    end

    @(negedge clk);
    s_arvalid = 1'b0;
  endtask

  task automatic tb_dn_ready(
      input bit aw_v,
      input bit w_v,
      input bit ar_v);
    @(negedge clk);
    tb_m_awready_ctl = aw_v;
    tb_m_wready_ctl = w_v;
    tb_m_arready_ctl = ar_v;
  endtask

  // One monitor owns all checker state, avoiding checker/checker races.
  always @(posedge clk) begin : monitor_all
    automatic int k;
    automatic int next_debt;
    automatic int find_idx;
    automatic int q_idx;
    automatic aw_rec_t a_tmp;
    automatic w_rec_t  w_tmp;
    automatic ar_rec_t ar_tmp;
    automatic b_rec_t  b_tmp;
    automatic r_rec_t  r_tmp;

    if (!rst_n) begin
      if ((m_awvalid === 1'b1) ||
          (m_wvalid  === 1'b1) ||
          (m_arvalid === 1'b1) ||
          (s_bvalid  === 1'b1) ||
          (s_rvalid  === 1'b1))
        tb_fail(
          "X1",
          "an output valid was asserted while rst_ni was low"
        );

      m_aw_log.delete();
      m_w_log.delete();
      m_ar_log.delete();
      dn_b_fifo.delete();
      dn_r_fifo.delete();

      for (k = 0; k < 16; k++) begin
        sb_ok_count[k] = 0;
        sb_err_count[k] = 0;
        sr_ok_count[k] = 0;
        sr_err_count[k] = 0;
        sr_err_last_count[k] = 0;
        sr_err_last_ordinal[k] = 0;
      end

      sb_ok_total = 0;
      sb_err_total = 0;
      sr_ok_total = 0;
      sr_err_total = 0;
      dn_write_debt = 0;

      held_aw_valid = 1'b0;
      held_w_valid = 1'b0;
      held_ar_valid = 1'b0;
      held_b_valid = 1'b0;
      held_r_valid = 1'b0;

      held_aw = '0;
      held_w = '0;
      held_ar = '0;
      held_b = '0;
      held_r = '0;

    end else begin

      // X3 on downstream request channels.
      if (held_aw_valid) begin
        if (m_awvalid !== 1'b1)
          tb_fail(
            "X3",
            "downstream AWVALID dropped before AWREADY"
          );

        if ((m_awid     !== held_aw.id)     ||
            (m_awaddr   !== held_aw.addr)   ||
            (m_awlen    !== held_aw.len)    ||
            (m_awsize   !== held_aw.size)   ||
            (m_awburst  !== held_aw.burst)  ||
            (m_awlock   !== held_aw.lock)   ||
            (m_awcache  !== held_aw.cache)  ||
            (m_awprot   !== held_aw.prot)   ||
            (m_awqos    !== held_aw.qos)    ||
            (m_awregion !== held_aw.region) ||
            (m_awatop   !== held_aw.atop)   ||
            (m_awuser   !== held_aw.user))
          tb_fail(
            "X3",
            "downstream AW payload changed while AWVALID was stalled"
          );
      end

      if (held_w_valid) begin
        if (m_wvalid !== 1'b1)
          tb_fail(
            "X3",
            "downstream WVALID dropped before WREADY"
          );

        if ((m_wdata !== held_w.data) ||
            (m_wstrb !== held_w.strb) ||
            (m_wlast !== held_w.last) ||
            (m_wuser !== held_w.user))
          tb_fail(
            "X3",
            "downstream W payload changed while WVALID was stalled"
          );
      end

      if (held_ar_valid) begin
        if (m_arvalid !== 1'b1)
          tb_fail(
            "X3",
            "downstream ARVALID dropped before ARREADY"
          );

        if ((m_arid     !== held_ar.id)     ||
            (m_araddr   !== held_ar.addr)   ||
            (m_arlen    !== held_ar.len)    ||
            (m_arsize   !== held_ar.size)   ||
            (m_arburst  !== held_ar.burst)  ||
            (m_arlock   !== held_ar.lock)   ||
            (m_arcache  !== held_ar.cache)  ||
            (m_arprot   !== held_ar.prot)   ||
            (m_arqos    !== held_ar.qos)    ||
            (m_arregion !== held_ar.region) ||
            (m_aruser   !== held_ar.user))
          tb_fail(
            "X3",
            "downstream AR payload changed while ARVALID was stalled"
          );
      end

      held_aw_valid =
        ((m_awvalid === 1'b1) &&
         (m_awready === 1'b0));

      if (held_aw_valid) begin
        held_aw.id = m_awid;
        held_aw.addr = m_awaddr;
        held_aw.len = m_awlen;
        held_aw.size = m_awsize;
        held_aw.burst = m_awburst;
        held_aw.lock = m_awlock;
        held_aw.cache = m_awcache;
        held_aw.prot = m_awprot;
        held_aw.qos = m_awqos;
        held_aw.region = m_awregion;
        held_aw.atop = m_awatop;
        held_aw.user = m_awuser;
      end

      held_w_valid =
        ((m_wvalid === 1'b1) &&
         (m_wready === 1'b0));

      if (held_w_valid) begin
        held_w.data = m_wdata;
        held_w.strb = m_wstrb;
        held_w.last = m_wlast;
        held_w.user = m_wuser;
      end

      held_ar_valid =
        ((m_arvalid === 1'b1) &&
         (m_arready === 1'b0));

      if (held_ar_valid) begin
        held_ar.id = m_arid;
        held_ar.addr = m_araddr;
        held_ar.len = m_arlen;
        held_ar.size = m_arsize;
        held_ar.burst = m_arburst;
        held_ar.lock = m_arlock;
        held_ar.cache = m_arcache;
        held_ar.prot = m_arprot;
        held_ar.qos = m_arqos;
        held_ar.region = m_arregion;
        held_ar.user = m_aruser;
      end

      // X3: once an upstream response VALID is stalled, VALID and payload must
      // remain unchanged through the cycle in which READY is finally observed.
      if (held_b_valid) begin
        if (s_bvalid !== 1'b1)
          tb_fail(
            "X3",
            "BVALID dropped before BREADY"
          );

        if ((s_bid   !== held_b.id) ||
            (s_bresp !== held_b.resp) ||
            (s_buser !== held_b.user))
          tb_fail(
            "X3",
            "B payload changed while BVALID was stalled"
          );
      end

      if (held_r_valid) begin
        if (s_rvalid !== 1'b1)
          tb_fail(
            "X3",
            "RVALID dropped before RREADY"
          );

        if ((s_rid   !== held_r.id)   ||
            (s_rdata !== held_r.data) ||
            (s_rresp !== held_r.resp) ||
            (s_rlast !== held_r.last) ||
            (s_ruser !== held_r.user))
          tb_fail(
            "X3",
            "R payload changed while RVALID was stalled"
          );
      end

      held_b_valid =
        ((s_bvalid === 1'b1) &&
         (s_bready === 1'b0));

      if (held_b_valid) begin
        held_b.id = s_bid;
        held_b.resp = s_bresp;
        held_b.user = s_buser;
      end

      held_r_valid =
        ((s_rvalid === 1'b1) &&
         (s_rready === 1'b0));

      if (held_r_valid) begin
        held_r.id = s_rid;
        held_r.data = s_rdata;
        held_r.resp = s_rresp;
        held_r.last = s_rlast;
        held_r.user = s_ruser;
      end

      // F1 applies whenever downstream AWVALID is asserted, not merely on a
      // handshake.
      if ((m_awvalid === 1'b1) &&
          (m_awatop !== 6'b000000))
        tb_fail(
          "F1",
          "m_awatop_o was nonzero while m_awvalid_o was asserted"
        );

      // Log downstream requests.
      if ((m_awvalid === 1'b1) &&
          (m_awready === 1'b1)) begin
        a_tmp.id = m_awid;
        a_tmp.addr = m_awaddr;
        a_tmp.len = m_awlen;
        a_tmp.size = m_awsize;
        a_tmp.burst = m_awburst;
        a_tmp.lock = m_awlock;
        a_tmp.cache = m_awcache;
        a_tmp.prot = m_awprot;
        a_tmp.qos = m_awqos;
        a_tmp.region = m_awregion;
        a_tmp.atop = m_awatop;
        a_tmp.user = m_awuser;
        m_aw_log.push_back(a_tmp);
      end

      if ((m_wvalid === 1'b1) &&
          (m_wready === 1'b1)) begin
        w_tmp.data = m_wdata;
        w_tmp.strb = m_wstrb;
        w_tmp.last = m_wlast;
        w_tmp.user = m_wuser;
        m_w_log.push_back(w_tmp);
      end

      if ((m_arvalid === 1'b1) &&
          (m_arready === 1'b1)) begin
        ar_tmp.id = m_arid;
        ar_tmp.addr = m_araddr;
        ar_tmp.len = m_arlen;
        ar_tmp.size = m_arsize;
        ar_tmp.burst = m_arburst;
        ar_tmp.lock = m_arlock;
        ar_tmp.cache = m_arcache;
        ar_tmp.prot = m_arprot;
        ar_tmp.qos = m_arqos;
        ar_tmp.region = m_arregion;
        ar_tmp.user = m_aruser;
        m_ar_log.push_back(ar_tmp);
      end

      // W1/W2: independent reference count of downstream write debt.
      next_debt = dn_write_debt;

      if ((m_awvalid === 1'b1) &&
          (m_awready === 1'b1))
        next_debt = next_debt + 1;

      if ((m_wvalid === 1'b1) &&
          (m_wready === 1'b1) &&
          (m_wlast === 1'b1))
        next_debt = next_debt - 1;

      if (next_debt > 4)
        tb_fail(
          "W2",
          $sformatf(
            "downstream write debt reached %0d (>4)",
            next_debt
          )
        );

      if (next_debt < 0)
        tb_fail(
          "P2/F2",
          "a downstream WLAST completed without downstream AW debt"
        );

      dn_write_debt = next_debt;

      // Capture each downstream response actually accepted by the DUT.
      if ((m_bvalid === 1'b1) &&
          (m_bready === 1'b1)) begin
        b_tmp.id = m_bid;
        b_tmp.resp = m_bresp;
        b_tmp.user = m_buser;
        dn_b_fifo.push_back(b_tmp);
      end

      if ((m_rvalid === 1'b1) &&
          (m_rready === 1'b1)) begin
        r_tmp.id = m_rid;
        r_tmp.data = m_rdata;
        r_tmp.resp = m_rresp;
        r_tmp.last = m_rlast;
        r_tmp.user = m_ruser;
        dn_r_fifo.push_back(r_tmp);
      end

      // Upstream B: OKAY must be an exact pass-through response from the
      // subordinate. Any locally manufactured response must be SLVERR.
      if ((s_bvalid === 1'b1) &&
          (s_bready === 1'b1)) begin

        if (s_bresp === 2'b00) begin
          find_idx = -1;

          for (q_idx = 0;
               q_idx < dn_b_fifo.size();
               q_idx++) begin
            if ((find_idx < 0) &&
                (dn_b_fifo[q_idx].id === s_bid))
              find_idx = q_idx;
          end

          if (find_idx < 0)
            tb_fail(
              "P4/F3",
              "unexpected upstream OKAY B with no matching downstream B ID"
            );

          b_tmp = dn_b_fifo[find_idx];
          dn_b_fifo.delete(find_idx);

          if ((s_bid   !== b_tmp.id) ||
              (s_bresp !== b_tmp.resp) ||
              (s_buser !== b_tmp.user))
            tb_fail(
              "P4",
              "downstream B response was not returned unmodified"
            );

          sb_ok_count[int'(s_bid)] =
            sb_ok_count[int'(s_bid)] + 1;
          sb_ok_total = sb_ok_total + 1;

        end else if (s_bresp === 2'b10) begin
          sb_err_count[int'(s_bid)] =
            sb_err_count[int'(s_bid)] + 1;
          sb_err_total = sb_err_total + 1;

        end else begin
          tb_fail(
            "F3/P4",
            "upstream B response was neither pass-through OKAY nor manufactured SLVERR"
          );
        end
      end

      // Upstream R: OKAY must exactly match a downstream R beat. SLVERR is a
      // manufactured atomic-write read response; its data/user are deliberately
      // not checked (L2).
      if ((s_rvalid === 1'b1) &&
          (s_rready === 1'b1)) begin

        if (s_rresp === 2'b00) begin
          find_idx = -1;

          for (q_idx = 0;
               q_idx < dn_r_fifo.size();
               q_idx++) begin
            if ((find_idx < 0) &&
                (dn_r_fifo[q_idx].id === s_rid))
              find_idx = q_idx;
          end

          if (find_idx < 0)
            tb_fail(
              "P3/F4/F5",
              "unexpected upstream OKAY R with no matching downstream R ID"
            );

          r_tmp = dn_r_fifo[find_idx];
          dn_r_fifo.delete(find_idx);

          if ((s_rid   !== r_tmp.id)   ||
              (s_rdata !== r_tmp.data) ||
              (s_rresp !== r_tmp.resp) ||
              (s_rlast !== r_tmp.last) ||
              (s_ruser !== r_tmp.user))
            tb_fail(
              "P3",
              "downstream R beat was not returned unmodified"
            );

          sr_ok_count[int'(s_rid)] =
            sr_ok_count[int'(s_rid)] + 1;
          sr_ok_total = sr_ok_total + 1;

        end else if (s_rresp === 2'b10) begin
          sr_err_count[int'(s_rid)] =
            sr_err_count[int'(s_rid)] + 1;
          sr_err_total = sr_err_total + 1;

          if (s_rlast === 1'b1) begin
            sr_err_last_count[int'(s_rid)] =
              sr_err_last_count[int'(s_rid)] + 1;

            sr_err_last_ordinal[int'(s_rid)] =
              sr_err_count[int'(s_rid)];
          end

        end else begin
          tb_fail(
            "F4/P3",
            "upstream R response was neither pass-through OKAY nor manufactured SLVERR"
          );
        end
      end
    end
  end


  // ---------------------------------------------------------------------------
  // STIMULUS
  // ---------------------------------------------------------------------------

  initial begin : main_test
    automatic bit ok;
    automatic bit ok2;
    automatic int base_aw;
    automatic int base_w;
    automatic int base_ar;
    automatic int base_b_ok;
    automatic int base_b_err;
    automatic int base_r_ok;
    automatic int base_r_err;
    automatic int start_cycle;
    automatic int i;

    // -----------------------------------------------------------------------
    // Reset sanity / clean start.
    // -----------------------------------------------------------------------
    bfm_reset(5);
    quiet_cycles(2);

    // -----------------------------------------------------------------------
    // P1/P2/P4 + C1 + F1:
    // Non-atomic means bits [5:4] == 00 even when [3:0] is nonzero.
    // Exercise every AW sideband with distinctive values and a 4-beat W burst.
    // -----------------------------------------------------------------------
    $display("TEST P1/P2/P4, C1, F1");
    bfm_dn_b_lag(8);

    base_aw = m_aw_log.size();
    base_w = m_w_log.size();
    base_b_ok = sb_ok_count[1];
    base_b_err = sb_err_count[1];
    base_r_err = sr_err_count[1];

    tb_aw_full(
      4'h1,
      32'hA5C0_1000,
      8'd3,
      3'd1,
      2'b10,
      1'b1,
      4'hA,
      3'h5,
      4'h9,
      4'h6,
      6'b00_1011,
      1'b1,
      64,
      ok
    );

    need(
      ok,
      "P1/X4",
      "non-atomic full-field AW was not accepted within 64 cycles"
    );

    wait_m_aw_size(base_aw + 1, 64, "P1");

    check_aw_log(
      base_aw,
      4'h1,
      32'hA5C0_1000,
      8'd3,
      3'd1,
      2'b10,
      1'b1,
      4'hA,
      3'h5,
      4'h9,
      4'h6,
      6'b000000,
      1'b1,
      "P1/F1"
    );

    tb_w_full(
      32'h1111_0001,
      4'b0011,
      1'b0,
      1'b1,
      64,
      ok
    );
    need(
      ok,
      "P2/X4",
      "first non-atomic W beat was not accepted"
    );
    wait_m_w_size(base_w + 1, 64, "P2");
    check_w_log(
      base_w + 0,
      32'h1111_0001,
      4'b0011,
      1'b0,
      1'b1,
      "P2"
    );

    tb_w_full(
      32'h2222_0002,
      4'b1100,
      1'b0,
      1'b0,
      64,
      ok
    );
    need(
      ok,
      "P2/X4",
      "second non-atomic W beat was not accepted"
    );
    wait_m_w_size(base_w + 2, 64, "P2");
    check_w_log(
      base_w + 1,
      32'h2222_0002,
      4'b1100,
      1'b0,
      1'b0,
      "P2"
    );

    tb_w_full(
      32'h3333_0003,
      4'b0011,
      1'b0,
      1'b1,
      64,
      ok
    );
    need(
      ok,
      "P2/X4",
      "third non-atomic W beat was not accepted"
    );
    wait_m_w_size(base_w + 3, 64, "P2");
    check_w_log(
      base_w + 2,
      32'h3333_0003,
      4'b0011,
      1'b0,
      1'b1,
      "P2"
    );

    tb_w_full(
      32'h4444_0004,
      4'b1100,
      1'b1,
      1'b0,
      64,
      ok
    );
    need(
      ok,
      "P2/X4",
      "final non-atomic W beat was not accepted"
    );
    wait_m_w_size(base_w + 4, 64, "P2");
    check_w_log(
      base_w + 3,
      32'h4444_0004,
      4'b1100,
      1'b1,
      1'b0,
      "P2"
    );

    wait_sb_ok(
      4'h1,
      base_b_ok + 1,
      128,
      "P4"
    );

    quiet_cycles(4);

    need(
      sb_ok_count[1] == base_b_ok + 1,
      "P4",
      "wrong number of pass-through B responses"
    );

    need(
      sb_err_count[1] == base_b_err,
      "C1/F3",
      "non-atomic write was treated as filtered"
    );

    need(
      sr_err_count[1] == base_r_err,
      "C1/F5",
      "non-atomic write created a manufactured R"
    );

    need(
      dn_b_fifo.size() == 0,
      "P4",
      "a downstream B response was not returned upstream"
    );

    // Address must not participate in filtering; low ATOP bits must not either.
    base_aw = m_aw_log.size();
    base_w = m_w_log.size();
    base_b_ok = sb_ok_count[2];
    base_b_err = sb_err_count[2];

    bfm_aw(
      4'h2,
      32'h0000_0000,
      8'd0,
      6'b00_1111,
      64,
      ok
    );

    need(
      ok,
      "C1/P1/X4",
      "non-atomic AW at address zero was not accepted"
    );

    wait_m_aw_size(base_aw + 1, 64, "C1/P1");

    check_aw_log(
      base_aw,
      4'h2,
      32'h0000_0000,
      8'd0,
      3'd2,
      2'd1,
      1'b0,
      4'd0,
      3'd0,
      4'd0,
      4'd0,
      6'b000000,
      1'b0,
      "C1/P1/F1"
    );

    bfm_w(
      32'hCAFE_0002,
      4'hF,
      1'b1,
      64,
      ok
    );

    need(
      ok,
      "P2/X4",
      "single-beat non-atomic W was not accepted"
    );

    wait_m_w_size(base_w + 1, 64, "P2");

    check_w_log(
      base_w,
      32'hCAFE_0002,
      4'hF,
      1'b1,
      1'b0,
      "P2"
    );

    wait_sb_ok(
      4'h2,
      base_b_ok + 1,
      128,
      "P4"
    );

    quiet_cycles(4);

    need(
      sb_err_count[2] == base_b_err,
      "C1/F3",
      "ATOP[3:0] or address incorrectly caused filtering"
    );


    // -----------------------------------------------------------------------
    // X3 on downstream AW/W/AR under actual downstream backpressure.
    // -----------------------------------------------------------------------
    $display("TEST X3 downstream request stability");

    bfm_reset(5);
    bfm_dn_b_lag(0);
    quiet_cycles(1);

    base_aw = m_aw_log.size();
    base_w = m_w_log.size();
    base_b_ok = sb_ok_count[9];

    tb_dn_ready(
      1'b0,
      1'b1,
      1'b1
    );

    ok = 1'b0;

    fork
      begin
        tb_aw_full(
          4'h9,
          32'h9090_0000,
          8'd0,
          3'd2,
          2'b01,
          1'b0,
          4'h7,
          3'h2,
          4'h3,
          4'h4,
          6'b00_0010,
          1'b1,
          80,
          ok
        );
      end
      begin
        repeat (8) @(posedge clk);
        tb_dn_ready(
          1'b1,
          1'b1,
          1'b1
        );
      end
    join

    need(
      ok,
      "X3/P1",
      "AW did not complete after downstream AWREADY was restored"
    );

    wait_m_aw_size(
      base_aw + 1,
      64,
      "X3/P1"
    );

    check_aw_log(
      base_aw,
      4'h9,
      32'h9090_0000,
      8'd0,
      3'd2,
      2'b01,
      1'b0,
      4'h7,
      3'h2,
      4'h3,
      4'h4,
      6'b000000,
      1'b1,
      "X3/P1/F1"
    );

    tb_dn_ready(
      1'b1,
      1'b0,
      1'b1
    );

    ok = 1'b0;

    fork
      begin
        tb_w_full(
          32'h9090_A5A5,
          4'hB,
          1'b1,
          1'b1,
          80,
          ok
        );
      end
      begin
        repeat (8) @(posedge clk);
        tb_dn_ready(
          1'b1,
          1'b1,
          1'b1
        );
      end
    join

    need(
      ok,
      "X3/P2",
      "W did not complete after downstream WREADY was restored"
    );

    wait_m_w_size(
      base_w + 1,
      64,
      "X3/P2"
    );

    check_w_log(
      base_w,
      32'h9090_A5A5,
      4'hB,
      1'b1,
      1'b1,
      "X3/P2"
    );

    wait_sb_ok(
      4'h9,
      base_b_ok + 1,
      96,
      "P4"
    );

    bfm_reset(5);
    quiet_cycles(1);

    base_ar = m_ar_log.size();
    base_r_ok = sr_ok_count[10];

    tb_dn_ready(
      1'b1,
      1'b1,
      1'b0
    );

    ok = 1'b0;

    fork
      begin
        tb_ar_full(
          4'hA,
          32'hA0A0_0040,
          8'd0,
          3'd2,
          2'b01,
          1'b0,
          4'h6,
          3'h4,
          4'h5,
          4'h7,
          1'b1,
          80,
          ok
        );
      end
      begin
        repeat (8) @(posedge clk);
        tb_dn_ready(
          1'b1,
          1'b1,
          1'b1
        );
      end
    join

    need(
      ok,
      "X3/P3",
      "AR did not complete after downstream ARREADY was restored"
    );

    wait_m_ar_size(
      base_ar + 1,
      64,
      "X3/P3"
    );

    check_ar_log(
      base_ar,
      4'hA,
      32'hA0A0_0040,
      8'd0,
      3'd2,
      2'b01,
      1'b0,
      4'h6,
      3'h4,
      4'h5,
      4'h7,
      1'b1,
      "X3/P3"
    );

    wait_sr_ok(
      4'hA,
      base_r_ok + 1,
      96,
      "P3"
    );

    quiet_cycles(4);


    // -----------------------------------------------------------------------
    // F2/F3/F5 + C1:
    // [5:4] == 01 is atomic but owes no R response.
    // -----------------------------------------------------------------------
    $display("TEST F2/F3/F5, C1 (01 atomic)");

    bfm_reset(5);
    bfm_dn_b_lag(0);
    quiet_cycles(1);

    base_aw = m_aw_log.size();
    base_w = m_w_log.size();
    base_b_err = sb_err_count[3];
    base_r_err = sr_err_count[3];

    tb_aw_full(
      4'h3,
      32'h1357_2000,
      8'd2,
      3'd2,
      2'b01,
      1'b0,
      4'h3,
      3'h6,
      4'hC,
      4'h2,
      6'b01_1111,
      1'b1,
      64,
      ok
    );

    need(
      ok,
      "C1/X4",
      "01 atomic AW was not accepted within 64 cycles"
    );

    tb_w_full(
      32'hA300_0001,
      4'hF,
      1'b0,
      1'b1,
      64,
      ok
    );
    need(
      ok,
      "F2/X4",
      "first filtered W beat was not consumed"
    );

    tb_w_full(
      32'hA300_0002,
      4'h7,
      1'b0,
      1'b0,
      64,
      ok
    );
    need(
      ok,
      "F2/X4",
      "second filtered W beat was not consumed"
    );

    tb_w_full(
      32'hA300_0003,
      4'h8,
      1'b1,
      1'b1,
      64,
      ok
    );
    need(
      ok,
      "F2/X4",
      "final filtered W beat was not consumed"
    );

    start_cycle = bfm_cycle;

    wait_filtered_counts(
      4'h3,
      base_b_err + 1,
      base_r_err,
      start_cycle,
      "F3/X4"
    );

    quiet_cycles(12);

    need(
      m_aw_log.size() == base_aw,
      "F1",
      "01 atomic AW reached the downstream port"
    );

    need(
      m_w_log.size() == base_w,
      "F2",
      "W beat of a filtered write reached the downstream port"
    );

    need(
      sb_err_count[3] == base_b_err + 1,
      "F3",
      "filtered write did not produce exactly one B"
    );

    need(
      sr_err_count[3] == base_r_err,
      "F5",
      "01 atomic write incorrectly produced R beats"
    );

    need(
      sb_err_total == 1,
      "F3",
      "01 atomic test produced an extra manufactured B"
    );

    need(
      sr_err_total == 0,
      "F5",
      "01 atomic test produced a manufactured R"
    );


    // -----------------------------------------------------------------------
    // F3/F4 + C2 + L1/L2 tolerance:
    // [5:4] == 10 owes B plus AWLEN+1 R beats. We do not constrain B/R order
    // and do not inspect manufactured RDATA/RUSER/BUSER.
    // -----------------------------------------------------------------------
    $display("TEST F3/F4, C2 (10 atomic, multi-beat R)");

    bfm_reset(5);
    quiet_cycles(1);

    base_aw = m_aw_log.size();
    base_w = m_w_log.size();

    tb_aw_full(
      4'h4,
      32'h2468_3000,
      8'd3,
      3'd2,
      2'b01,
      1'b0,
      4'h5,
      3'h1,
      4'h4,
      4'hB,
      6'b10_0011,
      1'b1,
      64,
      ok
    );

    need(
      ok,
      "C2/X4",
      "10 atomic AW was not accepted within 64 cycles"
    );

    for (i = 0; i < 4; i++) begin
      bfm_w(
        32'hB400_0000 + i,
        4'hF,
        (i == 3),
        64,
        ok
      );

      need(
        ok,
        "F2/X4",
        $sformatf(
          "filtered W beat %0d was not consumed",
          i
        )
      );
    end

    start_cycle = bfm_cycle;

    wait_filtered_counts(
      4'h4,
      1,
      4,
      start_cycle,
      "F3/F4/X4"
    );

    quiet_cycles(12);

    need(
      m_aw_log.size() == base_aw,
      "F1",
      "10 atomic AW reached the downstream port"
    );

    need(
      m_w_log.size() == base_w,
      "F2",
      "10 atomic W beat reached the downstream port"
    );

    need(
      sb_err_count[4] == 1,
      "F3",
      "10 atomic write did not produce exactly one B"
    );

    need(
      sr_err_count[4] == 4,
      "F4",
      "R beat count was not AWLEN+1"
    );

    need(
      sr_err_last_count[4] == 1,
      "F4",
      "R channel did not assert RLAST exactly once"
    );

    need(
      sr_err_last_ordinal[4] == 4,
      "F4",
      "RLAST was not on the final manufactured R beat"
    );

    need(
      sb_err_total == 1,
      "F3",
      "10 atomic test produced extra manufactured B responses"
    );

    need(
      sr_err_total == 4,
      "F4",
      "10 atomic test produced the wrong total manufactured R count"
    );


    // [5:4] == 11 must also classify as atomic-with-read-response.
    $display("TEST C1/C2 (11 atomic)");

    bfm_reset(5);
    quiet_cycles(1);

    base_aw = m_aw_log.size();
    base_w = m_w_log.size();

    bfm_aw(
      4'h5,
      32'hFFFF_FFFC,
      8'd0,
      6'b11_1010,
      64,
      ok
    );

    need(
      ok,
      "C1/C2/X4",
      "11 atomic AW was not accepted"
    );

    bfm_w(
      32'hB500_0001,
      4'hF,
      1'b1,
      64,
      ok
    );

    need(
      ok,
      "F2/X4",
      "11 atomic W beat was not consumed"
    );

    start_cycle = bfm_cycle;

    wait_filtered_counts(
      4'h5,
      1,
      1,
      start_cycle,
      "F3/F4/X4"
    );

    quiet_cycles(10);

    need(
      m_aw_log.size() == base_aw,
      "F1",
      "11 atomic AW reached downstream"
    );

    need(
      m_w_log.size() == base_w,
      "F2",
      "11 atomic W reached downstream"
    );

    need(
      sb_err_count[5] == 1,
      "F3",
      "11 atomic write did not produce one B"
    );

    need(
      sr_err_count[5] == 1,
      "F4",
      "11 atomic write did not produce one R"
    );

    need(
      sr_err_last_count[5] == 1,
      "F4",
      "single manufactured R did not carry RLAST"
    );

    need(
      sr_err_last_ordinal[5] == 1,
      "F4",
      "single manufactured R had wrong RLAST position"
    );


    // -----------------------------------------------------------------------
    // X3 under response backpressure. No assertion is made about whether a
    // response must become visible while READY is low; if VALID does appear,
    // the monitor above requires it and its payload to remain stable.
    // -----------------------------------------------------------------------
    $display("TEST X3 response stability under backpressure");

    bfm_reset(5);
    quiet_cycles(1);

    bfm_b_ready(1'b0);
    bfm_r_ready(1'b0);

    bfm_aw(
      4'h6,
      32'h6060_0000,
      8'd2,
      6'b10_0000,
      64,
      ok
    );

    need(
      ok,
      "C2/X4",
      "backpressure-test atomic AW was not accepted"
    );

    for (i = 0; i < 3; i++) begin
      bfm_w(
        32'h6600_0000 + i,
        4'hF,
        (i == 2),
        64,
        ok
      );

      need(
        ok,
        "F2/X4",
        "backpressure-test filtered W beat was not consumed"
      );
    end

    quiet_cycles(8);

    // Do not require a particular manufactured-response latency while READY is
    // low (L5/X4). The monitor has already checked stability for any VALID that
    // became visible during these stalled cycles. Reset cleanly rather than
    // imposing an extra latency rule that the contract does not state.
    bfm_reset(5);
    bfm_b_ready(1'b1);
    bfm_r_ready(1'b1);
    quiet_cycles(1);


    // -----------------------------------------------------------------------
    // W1/W2/W3/W5:
    // Build debt deliberately by withholding W. Four downstream AWs are legal,
    // a fifth downstream AW is not until a WLAST reduces debt. An atomic AW at
    // debt==4 must still be accept-able because it never changes that debt.
    // -----------------------------------------------------------------------
    $display("TEST W1/W2/W3/W5 outstanding-write bound");

    bfm_reset(5);
    bfm_dn_b_lag(0);
    quiet_cycles(1);

    base_aw = m_aw_log.size();
    base_w = m_w_log.size();

    for (i = 0; i < 4; i++) begin
      bfm_aw(
        4'(i),
        32'h7000_0000 + 32'(i * 16),
        8'd0,
        6'b00_0000,
        64,
        ok
      );

      need(
        ok,
        "W3/X4",
        $sformatf(
          "non-atomic AW %0d stalled below debt bound",
          i
        )
      );

      wait_m_aw_size(
        base_aw + i + 1,
        64,
        "W3"
      );
    end

    quiet_cycles(2);

    need(
      dn_write_debt == 4,
      "W1/W2",
      $sformatf(
        "expected debt 4, observed %0d",
        dn_write_debt
      )
    );

    // Atomic AW after the four ordinary AWs: it is fifth in AW order, but must
    // not itself consume a downstream-debt slot.
    bfm_aw(
      4'hE,
      32'h7E00_0000,
      8'd0,
      6'b01_0000,
      64,
      ok
    );

    need(
      ok,
      "W5/X4",
      "filtered AW was blocked merely because downstream debt was 4"
    );

    quiet_cycles(4);

    need(
      m_aw_log.size() == base_aw + 4,
      "W5/F1",
      "filtered AW changed downstream debt / was forwarded at debt 4"
    );

    need(
      dn_write_debt == 4,
      "W5",
      "filtered AW changed the downstream write debt"
    );

    // Offer the next ordinary AW while debt is full. Free exactly one slot
    // later with the WLAST belonging to the first ordinary AW.
    ok = 1'b0;
    ok2 = 1'b0;

    fork
      begin
        bfm_aw(
          4'hF,
          32'h7F00_0000,
          8'd0,
          6'b00_0000,
          80,
          ok
        );
      end
      begin
        repeat (8) @(posedge clk);

        bfm_w(
          32'h7000_0000,
          4'hF,
          1'b1,
          64,
          ok2
        );
      end
    join

    need(
      ok2,
      "P2/X4",
      "first debt-releasing WLAST was not accepted"
    );

    need(
      ok,
      "W2/W3/X4",
      "ordinary AW did not progress after WLAST freed a debt slot"
    );

    wait_m_aw_size(
      base_aw + 5,
      64,
      "W2/W3"
    );

    need(
      dn_write_debt <= 4,
      "W2",
      "debt exceeded four after freeing one slot"
    );

    // Complete the remaining three original normal writes, then the filtered
    // write, then the final normal write, preserving AXI W ordering.
    for (i = 1; i < 4; i++) begin
      bfm_w(
        32'h7000_0000 + 32'(i),
        4'hF,
        1'b1,
        64,
        ok
      );

      need(
        ok,
        "P2/X4",
        $sformatf(
          "normal W %0d was not accepted",
          i
        )
      );
    end

    bfm_w(
      32'h7E00_0000,
      4'hF,
      1'b1,
      64,
      ok
    );

    need(
      ok,
      "F2/W5/X4",
      "filtered W at end of debt queue was not consumed"
    );

    bfm_w(
      32'h7F00_0000,
      4'hF,
      1'b1,
      64,
      ok
    );

    need(
      ok,
      "P2/X4",
      "final normal W was not accepted"
    );

    wait_m_w_size(
      base_w + 5,
      96,
      "P2/W5"
    );

    quiet_cycles(8);

    need(
      m_aw_log.size() == base_aw + 5,
      "W2/W5/F1",
      "wrong number of downstream AWs in debt-bound test"
    );

    need(
      m_w_log.size() == base_w + 5,
      "F2/W5/P2",
      "filtered W affected downstream W traffic"
    );

    need(
      dn_write_debt == 0,
      "W1/W5",
      $sformatf(
        "write debt did not return to zero; got %0d",
        dn_write_debt
      )
    );


    // -----------------------------------------------------------------------
    // W4:
    // Completion of W, not arrival of B, frees capacity. Hold all subordinate
    // B responses for 200 cycles; five sequential completed write bursts must
    // still be accepted because each WLAST reduces debt immediately.
    // -----------------------------------------------------------------------
    $display("TEST W4 debt is reduced by WLAST, not B");

    bfm_reset(5);
    bfm_dn_b_lag(200);
    quiet_cycles(1);

    base_aw = m_aw_log.size();

    for (i = 0; i < 4; i++) begin
      bfm_aw(
        4'(8 + i),
        32'h8000_0000 + 32'(i * 16),
        8'd0,
        6'b00_0000,
        64,
        ok
      );

      need(
        ok,
        "W4/X4",
        $sformatf(
          "AW %0d stalled before four delayed B responses existed",
          i
        )
      );

      bfm_w(
        32'h8800_0000 + 32'(i),
        4'hF,
        1'b1,
        64,
        ok
      );

      need(
        ok,
        "W4/P2",
        $sformatf(
          "W %0d was not accepted",
          i
        )
      );
    end

    need(
      dn_write_debt == 0,
      "W4",
      "completed W bursts did not reduce reference downstream debt to zero"
    );

    bfm_aw(
      4'hC,
      32'h8C00_0000,
      8'd0,
      6'b00_0000,
      64,
      ok
    );

    need(
      ok,
      "W4/X4",
      "fifth AW stalled waiting for B even though all prior W bursts completed"
    );

    wait_m_aw_size(
      base_aw + 5,
      64,
      "W4"
    );

    bfm_w(
      32'h8C00_0000,
      4'hF,
      1'b1,
      64,
      ok
    );

    need(
      ok,
      "W4/P2",
      "fifth W was not accepted"
    );

    quiet_cycles(2);

    need(
      dn_write_debt == 0,
      "W4",
      "fifth completed W did not release debt"
    );

    // Reset discards the deliberately delayed subordinate B traffic.
    bfm_reset(5);
    bfm_dn_b_lag(0);
    quiet_cycles(1);


    // -----------------------------------------------------------------------
    // P3: full-field AR pass-through and exact R pass-through.
    // -----------------------------------------------------------------------
    $display("TEST P3 read pass-through");

    base_ar = m_ar_log.size();
    base_r_ok = sr_ok_count[8];
    base_r_err = sr_err_count[8];

    tb_ar_full(
      4'h8,
      32'h9000_0040,
      8'd3,
      3'd1,
      2'b10,
      1'b1,
      4'hD,
      3'h3,
      4'hA,
      4'h5,
      1'b1,
      64,
      ok
    );

    need(
      ok,
      "P3/X4",
      "full-field AR was not accepted"
    );

    wait_m_ar_size(
      base_ar + 1,
      64,
      "P3"
    );

    check_ar_log(
      base_ar,
      4'h8,
      32'h9000_0040,
      8'd3,
      3'd1,
      2'b10,
      1'b1,
      4'hD,
      3'h3,
      4'hA,
      4'h5,
      1'b1,
      "P3"
    );

    wait_sr_ok(
      4'h8,
      base_r_ok + 4,
      128,
      "P3"
    );

    quiet_cycles(4);

    need(
      sr_ok_count[8] == base_r_ok + 4,
      "P3",
      "read returned wrong number of R beats"
    );

    need(
      sr_err_count[8] == base_r_err,
      "P3",
      "ordinary read was converted to an error response"
    );

    need(
      dn_r_fifo.size() == 0,
      "P3",
      "downstream R beat was not returned upstream"
    );


    // -----------------------------------------------------------------------
    // Read traffic is not subject to the four-write debt bound. Stall R
    // consumption so six ARs are simultaneously outstanding downstream.
    // -----------------------------------------------------------------------
    $display("TEST read traffic is not limited by write debt bound");

    bfm_reset(5);
    quiet_cycles(1);
    bfm_r_ready(1'b0);

    base_ar = m_ar_log.size();

    for (i = 0; i < 6; i++) begin
      bfm_ar(
        4'(i),
        32'hA000_0000 + 32'(i * 32),
        8'd0,
        64,
        ok
      );

      need(
        ok,
        "P3",
        $sformatf(
          "AR %0d was stalled as though subject to write bound",
          i
        )
      );

      wait_m_ar_size(
        base_ar + i + 1,
        64,
        "P3"
      );
    end

    need(
      dn_write_debt == 0,
      "W1",
      "read traffic changed write debt"
    );

    quiet_cycles(8);

    bfm_r_ready(1'b1);

    for (i = 0; i < 6; i++) begin
      wait_sr_ok(
        4'(i),
        1,
        160,
        "P3"
      );
    end

    quiet_cycles(4);

    need(
      sr_ok_total == 6,
      "P3",
      "six outstanding reads did not return exactly six beats"
    );

    need(
      sr_err_total == 0,
      "P3",
      "ordinary outstanding reads produced error responses"
    );

    need(
      dn_r_fifo.size() == 0,
      "P3",
      "read response pass-through FIFO did not drain"
    );


    // -----------------------------------------------------------------------
    // X1/X2: asynchronous reset with a pending locally-generated response, and
    // transactions presented only while reset is low.
    // -----------------------------------------------------------------------
    $display("TEST X1/X2 asynchronous reset and reset-time traffic");

    bfm_reset(5);
    quiet_cycles(1);

    bfm_b_ready(1'b0);

    bfm_aw(
      4'h7,
      32'hB700_0000,
      8'd0,
      6'b01_0000,
      64,
      ok
    );

    need(
      ok,
      "X1/X2",
      "pre-reset atomic AW was not accepted"
    );

    bfm_w(
      32'hB700_0001,
      4'hF,
      1'b1,
      64,
      ok
    );

    need(
      ok,
      "X1/X2",
      "pre-reset atomic W was not accepted"
    );

    quiet_cycles(4);

    // Assert reset away from the sampling edge. monitor_all checks X1 at every
    // rising edge while reset remains low.
    @(negedge clk);
    rst_n = 1'b0;

    repeat (3)
      @(posedge clk);

    // Present complete-looking requests while reset is low. They must neither
    // leak downstream nor create responses after reset release.
    @(negedge clk);

    s_awid = 4'hD;
    s_awaddr = 32'hDEAD_0000;
    s_awlen = 8'd0;
    s_awsize = 3'd2;
    s_awburst = 2'b01;
    s_awlock = 1'b0;
    s_awcache = 4'hF;
    s_awprot = 3'h7;
    s_awqos = 4'hF;
    s_awregion = 4'hF;
    s_awatop = 6'b11_1111;
    s_awuser = 1'b1;
    s_awvalid = 1'b1;

    s_wdata = 32'hDEAD_BEEF;
    s_wstrb = 4'hF;
    s_wlast = 1'b1;
    s_wuser = 1'b1;
    s_wvalid = 1'b1;

    s_arid = 4'hD;
    s_araddr = 32'hDEAD_1000;
    s_arlen = 8'd1;
    s_arsize = 3'd2;
    s_arburst = 2'b01;
    s_arlock = 1'b0;
    s_arcache = 4'hF;
    s_arprot = 3'h7;
    s_arqos = 4'hF;
    s_arregion = 4'hF;
    s_aruser = 1'b1;
    s_arvalid = 1'b1;

    repeat (4)
      @(posedge clk);

    @(negedge clk);

    s_awvalid = 1'b0;
    s_wvalid = 1'b0;
    s_arvalid = 1'b0;
    s_bready = 1'b1;
    s_rready = 1'b1;

    repeat (2)
      @(posedge clk);

    @(negedge clk);
    rst_n = 1'b1;

    quiet_cycles(24);

    need(
      m_aw_log.size() == 0,
      "X2",
      "AW presented during reset leaked downstream after reset"
    );

    need(
      m_w_log.size() == 0,
      "X2",
      "W presented during reset leaked downstream after reset"
    );

    need(
      m_ar_log.size() == 0,
      "X2",
      "AR presented during reset leaked downstream after reset"
    );

    need(
      sb_ok_total == 0,
      "X2",
      "reset-time traffic created a pass-through B response"
    );

    need(
      sb_err_total == 0,
      "X2",
      "reset-time/pre-reset traffic survived reset as manufactured B"
    );

    need(
      sr_ok_total == 0,
      "X2",
      "reset-time traffic created a pass-through R response"
    );

    need(
      sr_err_total == 0,
      "X2",
      "reset-time/pre-reset traffic survived reset as manufactured R"
    );

    need(
      dn_b_fifo.size() == 0,
      "X2",
      "downstream B state survived reset"
    );

    need(
      dn_r_fifo.size() == 0,
      "X2",
      "downstream R state survived reset"
    );

    need(
      dn_write_debt == 0,
      "X2",
      "write-debt state survived reset"
    );

    $display("RESULT: PASS");
    $finish;
  end

endmodule