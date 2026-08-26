// ===========================================================================
// atop_filter_tb.sv
//
// Decides whether a design on this port map obeys the atop_filter contract.
//
// HOW IT DECIDES
//   * One posedge monitor holds every check.  It processes a cycle in the
//     order upstream-request -> downstream-request -> downstream-response ->
//     upstream-response, so a purely combinational design that forwards a beat
//     in the same cycle it accepts it is handled exactly like a registered one
//     (L3, L5).
//   * Pass-through is decided by FIFO expectation queues filled from what the
//     design was given and drained by what it produced -- never by matching on
//     payload values, which repeat.
//   * Manufactured responses are attributed by id, exactly as F4 instructs,
//     and never by arrival order or by position relative to the B.  Write ids
//     are partitioned so an id alone says which write owes a response:
//         ids  0-5   non-atomic writes   (pass-through B)
//         ids  6-11  atomic writes       (manufactured B, maybe R)
//         ids 12-15  reads               (pass-through R)
//   * Every wait is bounded, so a design that never makes progress fails
//     rather than hanging.
//
// WHAT IT DELIBERATELY DOES NOT CHECK (the latitude, L1-L5)
//   * L1: the order of a filtered write's B relative to its R beats.  The two
//     are counted independently and neither is required to come first.
//   * L2: s_rdata_o, s_ruser_o and s_buser_o on a manufactured response are
//     never read.
//   * L3/L5: no ready is required to be combinational or registered, and no
//     manufactured response is required at any particular cycle -- only the
//     64-cycle bound of X4.
//   * L4: a subsequent AW may be stalled for as long as the design likes while
//     a filtered write is in flight; the concurrency phase treats a refusal as
//     a legal answer, not a failure.
//   Nor anything the contract is silent about: s_awaddr_i is never privileged,
//   m_wstrb_o is only ever compared against what was presented, and read
//   traffic is never counted against the §W bound.
//
// TWO EXTENSIONS TO THE PROVIDED PLUMBING, both marked EXTENSION below:
//   * the subordinate's B and R response fields are driven from variables
//     instead of the constants 2'b00 / 1'b0, because P3 and P4 require those
//     fields to be returned *unmodified* and a subordinate that only ever
//     answers OKAY with user=0 cannot tell an unmodified field from a
//     hardwired one;
//   * request tasks that take every AW/AR field, because P1 and P3 require
//     every field to be forwarded unmodified and the provided tasks pin most
//     of them to zero.
// ===========================================================================

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
  logic rst_n = 1'b0;      // ACTIVE LOW

  task automatic bfm_reset(input int cycles = 5);
    @(negedge clk);
    rst_n = 1'b0;
    repeat (cycles) @(posedge clk);
    @(negedge clk);
    rst_n = 1'b1;
  endtask

  // ---- the signals, and the design under test ------------------------------
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
    .s_awid_i(s_awid), .s_awaddr_i(s_awaddr), .s_awlen_i(s_awlen),
    .s_awsize_i(s_awsize), .s_awburst_i(s_awburst), .s_awlock_i(s_awlock),
    .s_awcache_i(s_awcache), .s_awprot_i(s_awprot), .s_awqos_i(s_awqos),
    .s_awregion_i(s_awregion), .s_awatop_i(s_awatop), .s_awuser_i(s_awuser),
    .s_awvalid_i(s_awvalid), .s_awready_o(s_awready),
    .s_wdata_i(s_wdata), .s_wstrb_i(s_wstrb), .s_wlast_i(s_wlast),
    .s_wuser_i(s_wuser), .s_wvalid_i(s_wvalid), .s_wready_o(s_wready),
    .s_bid_o(s_bid), .s_bresp_o(s_bresp), .s_buser_o(s_buser),
    .s_bvalid_o(s_bvalid), .s_bready_i(s_bready),
    .s_arid_i(s_arid), .s_araddr_i(s_araddr), .s_arlen_i(s_arlen),
    .s_arsize_i(s_arsize), .s_arburst_i(s_arburst), .s_arlock_i(s_arlock),
    .s_arcache_i(s_arcache), .s_arprot_i(s_arprot), .s_arqos_i(s_arqos),
    .s_arregion_i(s_arregion), .s_aruser_i(s_aruser),
    .s_arvalid_i(s_arvalid), .s_arready_o(s_arready),
    .s_rid_o(s_rid), .s_rdata_o(s_rdata), .s_rresp_o(s_rresp),
    .s_rlast_o(s_rlast), .s_ruser_o(s_ruser), .s_rvalid_o(s_rvalid),
    .s_rready_i(s_rready),
    .m_awid_o(m_awid), .m_awaddr_o(m_awaddr), .m_awlen_o(m_awlen),
    .m_awsize_o(m_awsize), .m_awburst_o(m_awburst), .m_awlock_o(m_awlock),
    .m_awcache_o(m_awcache), .m_awprot_o(m_awprot), .m_awqos_o(m_awqos),
    .m_awregion_o(m_awregion), .m_awatop_o(m_awatop), .m_awuser_o(m_awuser),
    .m_awvalid_o(m_awvalid), .m_awready_i(m_awready),
    .m_wdata_o(m_wdata), .m_wstrb_o(m_wstrb), .m_wlast_o(m_wlast),
    .m_wuser_o(m_wuser), .m_wvalid_o(m_wvalid), .m_wready_i(m_wready),
    .m_bid_i(m_bid), .m_bresp_i(m_bresp), .m_buser_i(m_buser),
    .m_bvalid_i(m_bvalid), .m_bready_o(m_bready),
    .m_arid_o(m_arid), .m_araddr_o(m_araddr), .m_arlen_o(m_arlen),
    .m_arsize_o(m_arsize), .m_arburst_o(m_arburst), .m_arlock_o(m_arlock),
    .m_arcache_o(m_arcache), .m_arprot_o(m_arprot), .m_arqos_o(m_arqos),
    .m_arregion_o(m_arregion), .m_aruser_o(m_aruser),
    .m_arvalid_o(m_arvalid), .m_arready_i(m_arready),
    .m_rid_i(m_rid), .m_rdata_i(m_rdata), .m_rresp_i(m_rresp),
    .m_rlast_i(m_rlast), .m_ruser_i(m_ruser), .m_rvalid_i(m_rvalid),
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

  // EXTENSION: the response fields the subordinate returns are variables, so
  // that P3 and P4 ("returned unmodified") can actually be decided.  A
  // subordinate hardwired to OKAY/user=0 cannot distinguish a design that
  // forwards those fields from one that hardwires them.
  logic [1:0] sub_bresp = 2'b00;
  logic       sub_buser = 1'b0;
  logic [1:0] sub_rresp = 2'b00;
  logic       sub_ruser = 1'b0;

  // EXTENSION: the subordinate's responses are driven from REGISTERS rather
  // than combinationally from its queues.  As provided, m_bvalid/m_bid/m_rvalid
  // /m_rid/m_rdata/m_rlast are an always_comb reading queue variables that the
  // plumbing's own always @(posedge) block mutates with blocking assignments in
  // the same active region, so a posedge observer can sample a torn snapshot --
  // m_rvalid from before the update and m_rid/m_rdata from after it.  That is a
  // scheduling hazard in the harness, not behaviour of any design, and it would
  // misfire against a correct design as readily as a faulty one.  Registering
  // the outputs removes it and still models a perfectly legal AXI subordinate.
  int bfm_bq_id [$], bfm_bq_t [$], bfm_rq_id [$], bfm_rq_n [$];
  assign m_awready = 1'b1;
  assign m_wready  = 1'b1;
  assign m_arready = 1'b1;

  logic [3:0]  sub_b_id_q;
  logic        sub_b_val_q;
  logic [3:0]  sub_r_id_q;
  logic [31:0] sub_r_dat_q;
  logic        sub_r_val_q, sub_r_last_q;

  assign m_bvalid = sub_b_val_q;
  assign m_bid    = sub_b_id_q;
  assign m_bresp  = sub_bresp;
  assign m_buser  = sub_buser;
  assign m_rvalid = sub_r_val_q;
  assign m_rid    = sub_r_id_q;
  assign m_rdata  = sub_r_dat_q;
  assign m_rresp  = sub_rresp;
  assign m_ruser  = sub_ruser;
  assign m_rlast  = sub_r_last_q;

  always @(posedge clk) begin
    if (!rst_n) begin
      bfm_bq_id.delete(); bfm_bq_t.delete(); bfm_rq_id.delete(); bfm_rq_n.delete();
      sub_b_val_q <= 1'b0;
      sub_r_val_q <= 1'b0;
    end else begin
      if (m_awvalid && m_awready) begin
        bfm_bq_id.push_back(int'(m_awid)); bfm_bq_t.push_back(bfm_cycle + bfm_b_lag);
      end
      if (m_arvalid && m_arready) begin
        bfm_rq_id.push_back(int'(m_arid)); bfm_rq_n.push_back(int'(m_arlen) + 1);
      end
      // B output register
      if (!sub_b_val_q || m_bready) begin
        if (bfm_bq_id.size() > 0 && bfm_cycle >= bfm_bq_t[0]) begin
          sub_b_val_q <= 1'b1;
          sub_b_id_q  <= 4'(bfm_bq_id[0]);
          void'(bfm_bq_id.pop_front()); void'(bfm_bq_t.pop_front());
        end else begin
          sub_b_val_q <= 1'b0;
        end
      end
      // R output register
      if (!sub_r_val_q || m_rready) begin
        if (bfm_rq_id.size() > 0) begin
          sub_r_val_q  <= 1'b1;
          sub_r_id_q   <= 4'(bfm_rq_id[0]);
          sub_r_dat_q  <= 32'hFEED_0000 + 32'(bfm_rq_n[0]);
          sub_r_last_q <= (bfm_rq_n[0] <= 1);
          if (bfm_rq_n[0] <= 1) begin
            void'(bfm_rq_id.pop_front()); void'(bfm_rq_n.pop_front());
          end else begin
            bfm_rq_n[0] = bfm_rq_n[0] - 1;
          end
        end else begin
          sub_r_val_q <= 1'b0;
        end
      end
    end
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
  //                        FROM HERE ON: MY OWN CODE
  // ===========================================================================

  localparam int MAX_WRITE_TXNS = 4;
  localparam logic [1:0] SLVERR = 2'b10;

  // ---- verdict bookkeeping -------------------------------------------------
  int err_cnt = 0;
  int msg_cnt = 0;

  task automatic fail(input string cl, input string msg);
    err_cnt = err_cnt + 1;
    if (msg_cnt < 40) begin
      msg_cnt = msg_cnt + 1;
      $display("VIOLATION [%s] cycle=%0d : %s", cl, bfm_cycle, msg);
    end
    if (err_cnt == 60) begin
      $display("SUMMARY: stopping after %0d violations", err_cnt);
      $display("RESULT: FAIL");
      $finish;
    end
  endtask

  // ---- id partitioning, so an id alone attributes a response ---------------
  function automatic bit id_is_atomic(input int id); return (id >= 6)  && (id <= 11); endfunction
  function automatic bit id_is_read  (input int id); return (id >= 12) && (id <= 15); endfunction

  // ---- expectation records (packed, so they can live in queues) ------------
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
  } addr_t;

  typedef struct packed {
    logic [31:0] data;
    logic [3:0]  strb;
    logic        last;
    logic        user;
  } wbeat_t;

  typedef struct packed {
    logic [3:0] id;
    logic [1:0] resp;
    logic       user;
  } bresp_t;

  typedef struct packed {
    logic [3:0]  id;
    logic [31:0] data;
    logic [1:0]  resp;
    logic        last;
    logic        user;
  } rbeat_t;

  addr_t  fwd_aw_exp [$];   // non-atomic AWs, in acceptance order
  wbeat_t fwd_w_exp  [$];   // W beats of forwarded writes, in order
  addr_t  fwd_ar_exp [$];   // ARs, in acceptance order
  bresp_t b_pass_exp [$];   // B responses taken from the subordinate
  rbeat_t r_pass_exp [$];   // R beats taken from the subordinate

  // ---- upstream write ordering, for attributing W beats --------------------
  int wo_id  [$];
  int wo_rem [$];
  bit wo_flt [$];

  // ---- per-id state of filtered writes -------------------------------------
  bit f_act  [16];
  bit f_owes [16];
  bit f_bsee [16];
  bit f_done [16];
  bit f_x4   [16];
  int f_len  [16];
  int f_rcnt [16];
  int f_wlst [16];   // cycle of the s_wlast handshake, -1 if not yet
  int f_atop [16];

  // ---- the §W debt ---------------------------------------------------------
  int debt = 0;
  int dn_aw_cnt = 0;
  int dn_wlast_cnt = 0;
  int up_b_cnt = 0;
  int up_r_cnt = 0;

  bit x1_en = 1'b0;     // judge X1 while reset is low (master port quiet)
  bit x4_en = 1'b1;     // judge the X4 bound (off while we apply backpressure)
  int rst_edges = 0;

  // ---- X3: valid held stable until ready -----------------------------------
  bit     pv_have = 1'b0;
  logic   pv_bv, pv_br, pv_rv, pv_rr, pv_awv, pv_wv, pv_arv;
  bresp_t pv_b;
  rbeat_t pv_r;
  addr_t  pv_aw, pv_ar;
  wbeat_t pv_w;
  logic [5:0] pv_awatop;

  function automatic addr_t s_aw_rec();
    addr_t a;
    a.id = s_awid; a.addr = s_awaddr; a.len = s_awlen; a.size = s_awsize;
    a.burst = s_awburst; a.lock = s_awlock; a.cache = s_awcache;
    a.prot = s_awprot; a.qos = s_awqos; a.region = s_awregion; a.user = s_awuser;
    return a;
  endfunction
  function automatic addr_t m_aw_rec();
    addr_t a;
    a.id = m_awid; a.addr = m_awaddr; a.len = m_awlen; a.size = m_awsize;
    a.burst = m_awburst; a.lock = m_awlock; a.cache = m_awcache;
    a.prot = m_awprot; a.qos = m_awqos; a.region = m_awregion; a.user = m_awuser;
    return a;
  endfunction
  function automatic addr_t s_ar_rec();
    addr_t a;
    a.id = s_arid; a.addr = s_araddr; a.len = s_arlen; a.size = s_arsize;
    a.burst = s_arburst; a.lock = s_arlock; a.cache = s_arcache;
    a.prot = s_arprot; a.qos = s_arqos; a.region = s_arregion; a.user = s_aruser;
    return a;
  endfunction
  function automatic addr_t m_ar_rec();
    addr_t a;
    a.id = m_arid; a.addr = m_araddr; a.len = m_arlen; a.size = m_arsize;
    a.burst = m_arburst; a.lock = m_arlock; a.cache = m_arcache;
    a.prot = m_arprot; a.qos = m_arqos; a.region = m_arregion; a.user = m_aruser;
    return a;
  endfunction

  function automatic string aw_str(input addr_t a);
    return $sformatf("id=%0d addr=%08h len=%0d size=%0d burst=%0d lock=%0b cache=%01h prot=%0d qos=%01h region=%01h user=%0b",
                     a.id, a.addr, a.len, a.size, a.burst, a.lock, a.cache, a.prot, a.qos, a.region, a.user);
  endfunction

  task automatic filt_complete_check(input int id);
    automatic int d;
    if (!f_act[id] || f_done[id]) return;
    if (!f_bsee[id]) return;
    if (f_owes[id] && f_rcnt[id] < f_len[id] + 1) return;
    f_done[id] = 1'b1;
    if (f_x4[id] && f_wlst[id] >= 0) begin
      d = bfm_cycle - f_wlst[id];
      if (d > 64)
        fail("X4", $sformatf("filtered write id=%0d completed its responses %0d cycles after its s_wlast_i handshake, the bound is 64", id, d));
    end
  endtask

  // ===========================================================================
  // THE MONITOR
  // ===========================================================================
  always @(posedge clk) begin
    if (!rst_n) begin
      // X2: reset leaves nothing owed and nothing held.  Flush the model too.
      fwd_aw_exp.delete(); fwd_w_exp.delete(); fwd_ar_exp.delete();
      b_pass_exp.delete(); r_pass_exp.delete();
      wo_id.delete(); wo_rem.delete(); wo_flt.delete();
      for (int i = 0; i < 16; i++) begin
        f_act[i] = 1'b0; f_done[i] = 1'b0; f_bsee[i] = 1'b0;
        f_rcnt[i] = 0; f_wlst[i] = -1;
      end
      debt = 0;
      pv_have = 1'b0;
      rst_edges <= rst_edges + 1;
      // X1: while reset is low the unit originates nothing.  Judged from the
      // second rising edge on, because before an edge has passed the design's
      // registers hold nothing defined.  The master port is quiet here, so the
      // pass-through the clause exempts cannot be the cause.
      if (x1_en && rst_edges >= 1) begin
        if (m_awvalid === 1'b1 || m_wvalid === 1'b1)
          fail("X1", $sformatf("with rst_ni low the unit drives m_awvalid_o=%0b m_wvalid_o=%0b", m_awvalid, m_wvalid));
        if (s_bvalid === 1'b1 || s_rvalid === 1'b1)
          fail("X1", $sformatf("with rst_ni low and the master port quiet the unit drives s_bvalid_o=%0b s_rvalid_o=%0b", s_bvalid, s_rvalid));
      end
    end else begin
      automatic addr_t  ea, ga;
      automatic wbeat_t ew, gw;
      automatic bresp_t eb, gb;
      automatic rbeat_t er, gr;
      automatic int     id, fid;

      rst_edges <= 0;

      // ---- F1: atop is cleared on every forwarded AW ---------------------
      if (m_awvalid === 1'b1 && m_awatop !== 6'b000000)
        fail("F1", $sformatf("m_awatop_o=%06b while m_awvalid_o is asserted; it must be zero", m_awatop));

      // ---- X3: a valid may not be withdrawn or altered before its ready ---
      if (pv_have) begin
        if (pv_bv === 1'b1 && pv_br !== 1'b1) begin
          if (s_bvalid !== 1'b1)
            fail("X3", "s_bvalid_o was withdrawn before s_bready_i was seen");
          else if ({s_bid, s_bresp} !== {pv_b.id, pv_b.resp})
            fail("X3", "the B payload changed while s_bvalid_o was waiting for s_bready_i");
        end
        if (pv_rv === 1'b1 && pv_rr !== 1'b1) begin
          if (s_rvalid !== 1'b1)
            fail("X3", "s_rvalid_o was withdrawn before s_rready_i was seen");
          else if ({s_rid, s_rresp, s_rlast} !== {pv_r.id, pv_r.resp, pv_r.last})
            fail("X3", "the R payload changed while s_rvalid_o was waiting for s_rready_i");
        end
        if (pv_awv === 1'b1 && m_awready !== 1'b1) begin
          if (m_awvalid !== 1'b1)
            fail("X3", "m_awvalid_o was withdrawn before m_awready_i was seen");
          else if (m_aw_rec() !== pv_aw)
            fail("X3", "the AW payload changed while m_awvalid_o was waiting for m_awready_i");
        end
        if (pv_wv === 1'b1 && m_wready !== 1'b1) begin
          if (m_wvalid !== 1'b1)
            fail("X3", "m_wvalid_o was withdrawn before m_wready_i was seen");
        end
        if (pv_arv === 1'b1 && m_arready !== 1'b1) begin
          if (m_arvalid !== 1'b1)
            fail("X3", "m_arvalid_o was withdrawn before m_arready_i was seen");
        end
      end

      // ---- 1. upstream requests -------------------------------------------
      if (s_awvalid === 1'b1 && s_awready === 1'b1) begin
        id = int'(s_awid);
        wo_id.push_back(id);
        wo_rem.push_back(int'(s_awlen) + 1);
        // C1: atomic iff atop[5:4] != 00, whatever atop[3:0] holds
        wo_flt.push_back((s_awatop[5:4] != 2'b00) ? 1'b1 : 1'b0);
        if (s_awatop[5:4] == 2'b00) begin
          fwd_aw_exp.push_back(s_aw_rec());
        end else begin
          if (!id_is_atomic(id))
            $display("NOTE: testbench issued an atomic write on id %0d, outside the atomic id range", id);
          f_act[id]  = 1'b1;
          f_done[id] = 1'b0;
          f_bsee[id] = 1'b0;
          f_rcnt[id] = 0;
          f_wlst[id] = -1;
          f_len[id]  = int'(s_awlen);
          f_atop[id] = int'(s_awatop);
          f_owes[id] = s_awatop[5];      // C2
          f_x4[id]   = x4_en;
        end
      end

      if (s_wvalid === 1'b1 && s_wready === 1'b1) begin
        if (wo_id.size() == 0) begin
          fail("F2", "a W beat was accepted upstream with no write address outstanding");
        end else begin
          if (!wo_flt[0]) begin
            ew.data = s_wdata; ew.strb = s_wstrb; ew.last = s_wlast; ew.user = s_wuser;
            fwd_w_exp.push_back(ew);
          end
          if (s_wlast === 1'b1) begin
            if (wo_flt[0]) f_wlst[wo_id[0]] = bfm_cycle;
            void'(wo_id.pop_front()); void'(wo_rem.pop_front()); void'(wo_flt.pop_front());
          end else begin
            wo_rem[0] = wo_rem[0] - 1;
          end
        end
      end

      if (s_arvalid === 1'b1 && s_arready === 1'b1)
        fwd_ar_exp.push_back(s_ar_rec());

      // ---- 2. downstream requests -----------------------------------------
      if (m_awvalid === 1'b1 && m_awready === 1'b1) begin
        ga = m_aw_rec();
        if (fwd_aw_exp.size() == 0) begin
          fail("F1", $sformatf("an AW was forwarded (%s) that no non-atomic upstream write called for; an atomic write must never be forwarded", aw_str(ga)));
        end else begin
          ea = fwd_aw_exp.pop_front();
          if (ga !== ea)
            fail("P1", $sformatf("forwarded AW differs from the one presented:\n           got      %s\n           expected %s", aw_str(ga), aw_str(ea)));
        end
        dn_aw_cnt = dn_aw_cnt + 1;
        debt = debt + 1;
      end

      if (m_wvalid === 1'b1 && m_wready === 1'b1) begin
        gw.data = m_wdata; gw.strb = m_wstrb; gw.last = m_wlast; gw.user = m_wuser;
        if (fwd_w_exp.size() == 0) begin
          fail("F2", $sformatf("a W beat was forwarded (data=%08h last=%0b) that belongs to no forwarded write; the W beats of a filtered write must be consumed, not forwarded", gw.data, gw.last));
        end else begin
          ew = fwd_w_exp.pop_front();
          if (gw !== ew)
            fail("P2", $sformatf("forwarded W beat differs: got data=%08h strb=%04b last=%0b user=%0b, expected data=%08h strb=%04b last=%0b user=%0b",
                                 gw.data, gw.strb, gw.last, gw.user, ew.data, ew.strb, ew.last, ew.user));
        end
        if (m_wlast === 1'b1) begin
          dn_wlast_cnt = dn_wlast_cnt + 1;
          debt = debt - 1;
        end
      end

      if (m_arvalid === 1'b1 && m_arready === 1'b1) begin
        ga = m_ar_rec();
        if (fwd_ar_exp.size() == 0) begin
          fail("P3", $sformatf("an AR was forwarded (%s) that no upstream read called for", aw_str(ga)));
        end else begin
          ea = fwd_ar_exp.pop_front();
          if (ga !== ea)
            fail("P3", $sformatf("forwarded AR differs from the one presented:\n           got      %s\n           expected %s", aw_str(ga), aw_str(ea)));
        end
      end

      // ---- W2: the downstream write debt --------------------------------
      if (debt > MAX_WRITE_TXNS)
        fail("W2", $sformatf("the downstream write debt reached %0d, MAX_WRITE_TXNS is %0d", debt, MAX_WRITE_TXNS));

      // ---- 3. downstream responses arriving (pushed before any upstream
      //         pop, so a combinational pass-through in the same cycle works)
      if (m_bvalid === 1'b1 && m_bready === 1'b1) begin
        eb.id = m_bid; eb.resp = m_bresp; eb.user = m_buser;
        b_pass_exp.push_back(eb);
      end
      if (m_rvalid === 1'b1 && m_rready === 1'b1) begin
        er.id = m_rid; er.data = m_rdata; er.resp = m_rresp;
        er.last = m_rlast; er.user = m_ruser;
        r_pass_exp.push_back(er);
      end

      // ---- 4. upstream responses leaving ----------------------------------
      if (s_bvalid === 1'b1 && s_bready === 1'b1) begin
        up_b_cnt = up_b_cnt + 1;
        fid = int'(s_bid);
        if (id_is_atomic(fid)) begin
          // F3: manufactured, attributed by id
          if (!f_act[fid]) begin
            fail("F3", $sformatf("a B response arrived with id=%0d, which no filtered write owes", fid));
          end else if (f_bsee[fid]) begin
            fail("F3", $sformatf("a second B response arrived for filtered write id=%0d; exactly one is owed", fid));
          end else begin
            if (s_bresp !== SLVERR)
              fail("F3", $sformatf("the manufactured B for filtered write id=%0d carries resp=%02b, expected SLVERR (10)", fid, s_bresp));
            f_bsee[fid] = 1'b1;
            filt_complete_check(fid);
          end
        end else begin
          // P4: pass-through, in order
          gb.id = s_bid; gb.resp = s_bresp; gb.user = s_buser;
          if (b_pass_exp.size() == 0) begin
            fail("P4", $sformatf("a B response arrived upstream with id=%0d that the subordinate never sent", fid));
          end else begin
            eb = b_pass_exp.pop_front();
            if (gb !== eb)
              fail("P4", $sformatf("a B response was altered in transit: got id=%0d resp=%02b user=%0b, the subordinate sent id=%0d resp=%02b user=%0b",
                                   gb.id, gb.resp, gb.user, eb.id, eb.resp, eb.user));
          end
        end
      end

      if (s_rvalid === 1'b1 && s_rready === 1'b1) begin
        up_r_cnt = up_r_cnt + 1;
        fid = int'(s_rid);
        if (id_is_atomic(fid)) begin
          if (!f_act[fid]) begin
            fail("F4", $sformatf("an R beat arrived with id=%0d, which no filtered write owes", fid));
          end else if (!f_owes[fid]) begin
            fail("F5", $sformatf("an R beat arrived for filtered write id=%0d (atop=%06b), which owes no read response at all", fid, f_atop[fid][5:0]));
          end else if (f_rcnt[fid] >= f_len[fid] + 1) begin
            fail("F4", $sformatf("filtered write id=%0d owes %0d R beats but a further one arrived", fid, f_len[fid] + 1));
          end else begin
            f_rcnt[fid] = f_rcnt[fid] + 1;
            if (s_rresp !== SLVERR)
              fail("F4", $sformatf("manufactured R beat %0d of filtered write id=%0d carries resp=%02b, expected SLVERR (10)", f_rcnt[fid], fid, s_rresp));
            if (s_rlast !== ((f_rcnt[fid] == f_len[fid] + 1) ? 1'b1 : 1'b0))
              fail("F4", $sformatf("manufactured R beat %0d of %0d for filtered write id=%0d has s_rlast_o=%0b", f_rcnt[fid], f_len[fid] + 1, fid, s_rlast));
            filt_complete_check(fid);
          end
        end else if (id_is_read(fid)) begin
          gr.id = s_rid; gr.data = s_rdata; gr.resp = s_rresp;
          gr.last = s_rlast; gr.user = s_ruser;
          if (r_pass_exp.size() == 0) begin
            fail("P3", $sformatf("an R beat arrived upstream with id=%0d that the subordinate never sent", fid));
          end else begin
            er = r_pass_exp.pop_front();
            if (gr !== er)
              fail("P3", $sformatf("an R beat was altered in transit: got id=%0d data=%08h resp=%02b last=%0b user=%0b, the subordinate sent id=%0d data=%08h resp=%02b last=%0b user=%0b",
                                   gr.id, gr.data, gr.resp, gr.last, gr.user, er.id, er.data, er.resp, er.last, er.user));
          end
        end else begin
          fail("F4", $sformatf("an R beat arrived with id=%0d, which belongs to neither a read nor a filtered write", fid));
        end
      end

      // ---- remember this cycle for the X3 check --------------------------
      pv_bv = s_bvalid; pv_br = s_bready;
      pv_b.id = s_bid; pv_b.resp = s_bresp; pv_b.user = s_buser;
      pv_rv = s_rvalid; pv_rr = s_rready;
      pv_r.id = s_rid; pv_r.data = s_rdata; pv_r.resp = s_rresp;
      pv_r.last = s_rlast; pv_r.user = s_ruser;
      pv_awv = m_awvalid; pv_aw = m_aw_rec(); pv_awatop = m_awatop;
      pv_wv  = m_wvalid;
      pv_arv = m_arvalid; pv_ar = m_ar_rec();
      pv_have = 1'b1;
    end
  end

  // ===========================================================================
  // STIMULUS HELPERS -- EXTENSION: every AW/AR field is drivable, because P1
  // and P3 require every field to be forwarded unmodified.
  // ===========================================================================
  task automatic my_aw(input logic [3:0] id, input logic [31:0] addr,
                       input logic [7:0] len, input logic [5:0] atop,
                       input logic [2:0] size, input logic [1:0] burst,
                       input logic lock, input logic [3:0] cache,
                       input logic [2:0] prot, input logic [3:0] qos,
                       input logic [3:0] region, input logic user,
                       input int timeout, output bit accepted);
    automatic int t;
    @(negedge clk);
    s_awid = id; s_awaddr = addr; s_awlen = len; s_awatop = atop;
    s_awsize = size; s_awburst = burst; s_awlock = lock; s_awcache = cache;
    s_awprot = prot; s_awqos = qos; s_awregion = region; s_awuser = user;
    s_awvalid = 1'b1;
    accepted = 1'b0;
    for (t = 0; t < timeout; t++) begin
      @(posedge clk);
      if (s_awready === 1'b1) begin accepted = 1'b1; break; end
    end
    @(negedge clk) s_awvalid = 1'b0;
  endtask

  task automatic my_ar(input logic [3:0] id, input logic [31:0] addr,
                       input logic [7:0] len,
                       input logic [2:0] size, input logic [1:0] burst,
                       input logic lock, input logic [3:0] cache,
                       input logic [2:0] prot, input logic [3:0] qos,
                       input logic [3:0] region, input logic user,
                       input int timeout, output bit accepted);
    automatic int t;
    @(negedge clk);
    s_arid = id; s_araddr = addr; s_arlen = len;
    s_arsize = size; s_arburst = burst; s_arlock = lock; s_arcache = cache;
    s_arprot = prot; s_arqos = qos; s_arregion = region; s_aruser = user;
    s_arvalid = 1'b1;
    accepted = 1'b0;
    for (t = 0; t < timeout; t++) begin
      @(posedge clk);
      if (s_arready === 1'b1) begin accepted = 1'b1; break; end
    end
    @(negedge clk) s_arvalid = 1'b0;
  endtask

  task automatic my_w(input logic [31:0] data, input logic [3:0] strb,
                      input bit last, input logic user,
                      input int timeout, output bit accepted);
    automatic int t;
    @(negedge clk);
    s_wdata = data; s_wstrb = strb; s_wlast = last; s_wuser = user;
    s_wvalid = 1'b1;
    accepted = 1'b0;
    for (t = 0; t < timeout; t++) begin
      @(posedge clk);
      if (s_wready === 1'b1) begin accepted = 1'b1; break; end
    end
    @(negedge clk) s_wvalid = 1'b0;
  endtask

  // Drive an AW and require it to be taken.  X4 gives 64 cycles; the budget is
  // wider so only a design that never takes it is reported.
  task automatic aw_must(input logic [3:0] id, input logic [31:0] addr,
                         input logic [7:0] len, input logic [5:0] atop,
                         input logic [2:0] size, input logic [1:0] burst,
                         input logic lock, input logic [3:0] cache,
                         input logic [2:0] prot, input logic [3:0] qos,
                         input logic [3:0] region, input logic user,
                         input string ctx);
    automatic bit acc;
    my_aw(id, addr, len, atop, size, burst, lock, cache, prot, qos, region, user, 200, acc);
    if (!acc)
      fail("X4", $sformatf("%s: AW id=%0d atop=%06b was offered for 200 cycles and never accepted", ctx, id, atop));
  endtask

  task automatic w_must(input logic [31:0] data, input logic [3:0] strb,
                        input bit last, input logic user, input string ctx);
    automatic bit acc;
    my_w(data, strb, last, user, 200, acc);
    if (!acc)
      fail("X4", $sformatf("%s: a W beat (last=%0b) was offered for 200 cycles and never accepted", ctx, last));
  endtask

  task automatic wait_cycles(input int n); repeat (n) @(posedge clk); endtask

  // Wait, bounded, until every filtered write has been fully answered.
  task automatic settle(input int n);
    automatic int t;
    for (t = 0; t < n; t++) begin
      automatic bit busy = 1'b0;
      @(negedge clk);
      for (int i = 0; i < 16; i++) if (f_act[i] && !f_done[i]) busy = 1'b1;
      if (b_pass_exp.size() > 0 || r_pass_exp.size() > 0) busy = 1'b1;
      if (fwd_aw_exp.size() > 0 || fwd_w_exp.size() > 0 || fwd_ar_exp.size() > 0) busy = 1'b1;
      if (!busy) break;
    end
  endtask

  task automatic check_settled(input string ctx);
    for (int i = 0; i < 16; i++)
      if (f_act[i] && !f_done[i])
        fail("X4", $sformatf("%s: filtered write id=%0d never received everything it owes (B seen=%0b, %0d of %0d R beats)",
                             ctx, i, f_bsee[i], f_rcnt[i], f_owes[i] ? f_len[i] + 1 : 0));
    if (b_pass_exp.size() > 0)
      fail("P4", $sformatf("%s: %0d B response(s) taken from the subordinate were never returned upstream", ctx, b_pass_exp.size()));
    if (r_pass_exp.size() > 0)
      fail("P3", $sformatf("%s: %0d R beat(s) taken from the subordinate were never returned upstream", ctx, r_pass_exp.size()));
    if (fwd_aw_exp.size() > 0)
      fail("P1", $sformatf("%s: %0d non-atomic AW(s) were accepted upstream but never forwarded (C1 fixes which writes are non-atomic: atop[5:4]==00)", ctx, fwd_aw_exp.size()));
    if (fwd_ar_exp.size() > 0)
      fail("P3", $sformatf("%s: %0d AR(s) were accepted upstream but never forwarded; a read is never filtered", ctx, fwd_ar_exp.size()));
    if (fwd_w_exp.size() > 0)
      fail("P2", $sformatf("%s: %0d W beat(s) of a forwarded write were never forwarded", ctx, fwd_w_exp.size()));
  endtask

  // No R beat may ever arrive for a filtered write that owes none (F5).
  task automatic check_no_r(input int id, input string ctx);
    if (f_rcnt[id] != 0)
      fail("F5", $sformatf("%s: filtered write id=%0d owes no read response but %0d R beat(s) arrived for it", ctx, id, f_rcnt[id]));
  endtask

  // ===========================================================================
  // THE RUN
  // ===========================================================================
  initial begin
    automatic bit acc, acc2;
    automatic int i, t, t0;

    // ---- X1: reset originates nothing -------------------------------------
    x1_en = 1'b1;
    bfm_reset(8);
    x1_en = 1'b0;
    wait_cycles(4);

    // ---- P1/P2/P4: a non-atomic write, every field varied ------------------
    sub_bresp = 2'b11; sub_buser = 1'b1;      // so "unmodified" is decidable
    aw_must(4'd0, 32'hCAFE_0004, 8'd0, 6'b000000, 3'd2, 2'd1, 1'b1, 4'hA, 3'd5, 4'h7, 4'h3, 1'b1, "P1 single beat");
    w_must(32'h1234_5678, 4'b1011, 1'b1, 1'b1, "P1 single beat");
    settle(300);
    check_settled("P1 single beat");

    // ---- P2: a multi-beat burst -------------------------------------------
    sub_bresp = 2'b01; sub_buser = 1'b0;
    aw_must(4'd1, 32'h0BAD_C0DE, 8'd3, 6'b000000, 3'd0, 2'd2, 1'b0, 4'h5, 3'd2, 4'hF, 4'hC, 1'b0, "P2 burst");
    w_must(32'hAAAA_0001, 4'b0001, 1'b0, 1'b1, "P2 burst");
    w_must(32'hAAAA_0002, 4'b0110, 1'b0, 1'b0, "P2 burst");
    w_must(32'hAAAA_0003, 4'b1111, 1'b0, 1'b1, "P2 burst");
    w_must(32'hAAAA_0004, 4'b1000, 1'b1, 1'b0, "P2 burst");
    settle(300);
    check_settled("P2 burst");

    // ---- C1: atop[3:0] never affects classification ------------------------
    // atop = 001111 has [5:4] == 00, so this write is NOT atomic and must be
    // forwarded like any other.
    sub_bresp = 2'b00; sub_buser = 1'b1;
    aw_must(4'd2, 32'h1111_2222, 8'd1, 6'b001111, 3'd2, 2'd1, 1'b0, 4'h0, 3'd7, 4'h1, 4'h9, 1'b1, "C1 atop[3:0] only");
    w_must(32'hC1C1_0001, 4'b1100, 1'b0, 1'b0, "C1 atop[3:0] only");
    w_must(32'hC1C1_0002, 4'b0011, 1'b1, 1'b1, "C1 atop[3:0] only");
    settle(300);
    check_settled("C1 atop[3:0] only");

    // ---- P3: reads are never altered and never filtered --------------------
    sub_rresp = 2'b01; sub_ruser = 1'b1;
    my_ar(4'd12, 32'hDEAD_0000, 8'd2, 3'd1, 2'd2, 1'b1, 4'h3, 3'd4, 4'hB, 4'h6, 1'b1, 200, acc);
    if (!acc) fail("X4", "P3: an AR was offered for 200 cycles and never accepted");
    settle(300);
    check_settled("P3 burst read");
    sub_rresp = 2'b11; sub_ruser = 1'b0;
    my_ar(4'd13, 32'hBEEF_1000, 8'd0, 3'd2, 2'd1, 1'b0, 4'hF, 3'd0, 4'h0, 4'hE, 1'b0, 200, acc);
    if (!acc) fail("X4", "P3: an AR was offered for 200 cycles and never accepted");
    settle(300);
    check_settled("P3 single read");
    sub_rresp = 2'b00; sub_ruser = 1'b0;

    // ---- F1/F2/F3/F5: atomic without a read response -----------------------
    aw_must(4'd6, 32'hA100_0000, 8'd0, 6'b010000, 3'd2, 2'd1, 1'b0, 4'h0, 3'd0, 4'h0, 4'h0, 1'b0, "F3 single beat");
    w_must(32'hDDDD_0001, 4'hF, 1'b1, 1'b0, "F3 single beat");
    settle(300);
    check_settled("F3 single beat");
    check_no_r(6, "F5 single beat");

    // a filtered burst, so the whole W burst must be swallowed
    aw_must(4'd7, 32'hA100_0100, 8'd3, 6'b011111, 3'd2, 2'd1, 1'b0, 4'h0, 3'd0, 4'h0, 4'h0, 1'b0, "F2 burst");
    w_must(32'hDDDD_1001, 4'hF, 1'b0, 1'b0, "F2 burst");
    w_must(32'hDDDD_1002, 4'hF, 1'b0, 1'b0, "F2 burst");
    w_must(32'hDDDD_1003, 4'hF, 1'b0, 1'b0, "F2 burst");
    w_must(32'hDDDD_1004, 4'hF, 1'b1, 1'b0, "F2 burst");
    settle(300);
    check_settled("F2 burst");
    check_no_r(7, "F5 burst");

    // ---- F4: atomic that also owes a read response -------------------------
    aw_must(4'd8, 32'hA200_0000, 8'd0, 6'b100000, 3'd2, 2'd1, 1'b0, 4'h0, 3'd0, 4'h0, 4'h0, 1'b0, "F4 len=0");
    w_must(32'hEEEE_0001, 4'hF, 1'b1, 1'b0, "F4 len=0");
    settle(300);
    check_settled("F4 len=0");
    if (f_rcnt[8] != 1)
      fail("F4", $sformatf("filtered write id=8 (len=0) received %0d R beats, exactly 1 is owed", f_rcnt[8]));

    aw_must(4'd9, 32'hA200_0100, 8'd3, 6'b110000, 3'd2, 2'd1, 1'b0, 4'h0, 3'd0, 4'h0, 4'h0, 1'b0, "F4 len=3");
    w_must(32'hEEEE_1001, 4'hF, 1'b0, 1'b0, "F4 len=3");
    w_must(32'hEEEE_1002, 4'hF, 1'b0, 1'b0, "F4 len=3");
    w_must(32'hEEEE_1003, 4'hF, 1'b0, 1'b0, "F4 len=3");
    w_must(32'hEEEE_1004, 4'hF, 1'b1, 1'b0, "F4 len=3");
    settle(300);
    check_settled("F4 len=3");
    if (f_rcnt[9] != 4)
      fail("F4", $sformatf("filtered write id=9 (len=3) received %0d R beats, exactly 4 are owed", f_rcnt[9]));

    // atop[3:0] set, and [5:4] = 10: still atomic, still owes a read
    aw_must(4'd10, 32'hA200_0200, 8'd1, 6'b101010, 3'd2, 2'd1, 1'b0, 4'h0, 3'd0, 4'h0, 4'h0, 1'b0, "F4 len=1");
    w_must(32'hEEEE_2001, 4'hF, 1'b0, 1'b0, "F4 len=1");
    w_must(32'hEEEE_2002, 4'hF, 1'b1, 1'b0, "F4 len=1");
    settle(300);
    check_settled("F4 len=1");
    if (f_rcnt[10] != 2)
      fail("F4", $sformatf("filtered write id=10 (len=1) received %0d R beats, exactly 2 are owed", f_rcnt[10]));

    // ---- two filtered writes in flight at once, if the design allows it ----
    // L4 lets it stall the second for as long as it likes, so a refusal here
    // is a legal answer and is not reported.
    aw_must(4'd6, 32'hA300_0000, 8'd3, 6'b100000, 3'd2, 2'd1, 1'b0, 4'h0, 3'd0, 4'h0, 4'h0, 1'b0, "F4 overlap");
    w_must(32'hBBBB_0001, 4'hF, 1'b0, 1'b0, "F4 overlap");
    w_must(32'hBBBB_0002, 4'hF, 1'b0, 1'b0, "F4 overlap");
    my_aw(4'd7, 32'hA300_0100, 8'd1, 6'b110000, 3'd2, 2'd1, 1'b0, 4'h0, 3'd0, 4'h0, 4'h0, 1'b0, 60, acc2);
    w_must(32'hBBBB_0003, 4'hF, 1'b0, 1'b0, "F4 overlap");
    w_must(32'hBBBB_0004, 4'hF, 1'b1, 1'b0, "F4 overlap");
    if (!acc2) begin
      aw_must(4'd7, 32'hA300_0100, 8'd1, 6'b110000, 3'd2, 2'd1, 1'b0, 4'h0, 3'd0, 4'h0, 4'h0, 1'b0, "F4 overlap 2nd");
    end
    w_must(32'hBBBB_1001, 4'hF, 1'b0, 1'b0, "F4 overlap 2nd");
    w_must(32'hBBBB_1002, 4'hF, 1'b1, 1'b0, "F4 overlap 2nd");
    settle(400);
    check_settled("F4 overlap");
    if (f_rcnt[6] != 4)
      fail("F4", $sformatf("filtered write id=6 (len=3) received %0d R beats, exactly 4 are owed", f_rcnt[6]));
    if (f_rcnt[7] != 2)
      fail("F4", $sformatf("filtered write id=7 (len=1) received %0d R beats, exactly 2 are owed", f_rcnt[7]));

    // ---- X3: hold both response readies low and watch for a withdrawal ----
    // X4 is suspended here: with the readies low the unit is entitled to stall.
    x4_en = 1'b0;
    bfm_b_ready(1'b0);
    bfm_r_ready(1'b0);
    my_aw(4'd8, 32'hA400_0000, 8'd1, 6'b110000, 3'd2, 2'd1, 1'b0, 4'h0, 3'd0, 4'h0, 4'h0, 1'b0, 200, acc);
    if (acc) begin
      my_w(32'hCCCC_0001, 4'hF, 1'b0, 1'b0, 200, acc);
      if (acc) my_w(32'hCCCC_0002, 4'hF, 1'b1, 1'b0, 200, acc);
    end
    wait_cycles(40);                       // the monitor judges X3 throughout
    bfm_b_ready(1'b1);
    bfm_r_ready(1'b1);
    // finish the burst if the design would not take it under backpressure
    for (i = 0; i < 2; i++) begin
      automatic bit still = 1'b0;
      for (int k = 0; k < wo_id.size(); k++) if (wo_id[k] == 8) still = 1'b1;
      if (!still) break;
      my_w(32'hCCCC_0003, 4'hF, (i == 1) ? 1'b1 : 1'b0, 1'b0, 200, acc);
    end
    settle(400);
    x4_en = 1'b1;

    // ---- W2/W3/W4/W5: the outstanding-write bound --------------------------
    // W5 is decided by getting here at all: every filtered write above would
    // have leaked debt if the design counted them, and the four AWs below
    // would then never all be forwarded.
    bfm_dn_b_lag(400);                     // no B will arrive during the phase
    t0 = dn_aw_cnt;
    for (i = 0; i < MAX_WRITE_TXNS; i++)
      aw_must(4'(i), 32'h4000_0000 + 32'(i), 8'd0, 6'b000000, 3'd2, 2'd1, 1'b0, 4'h0, 3'd0, 4'h0, 4'h0, 1'b0, "W3 filling the bound");
    // W3: none of those four may have been stalled by the bound
    if (dn_aw_cnt - t0 != MAX_WRITE_TXNS)
      fail("W3", $sformatf("only %0d of %0d AWs were forwarded while the debt was below the bound", dn_aw_cnt - t0, MAX_WRITE_TXNS));
    if (debt != MAX_WRITE_TXNS)
      fail("W1", $sformatf("the downstream write debt is %0d after %0d AWs and no W burst, expected %0d", debt, MAX_WRITE_TXNS, MAX_WRITE_TXNS));
    // W2: a fifth AW may be offered; it must not be forwarded while the debt
    // is at the bound.  Whether it is accepted upstream is the design's choice.
    t0 = dn_aw_cnt;                        // captured before the offer: a design
    my_aw(4'd4, 32'h4000_0004, 8'd0, 6'b000000, 3'd2, 2'd1, 1'b0, 4'h0, 3'd0, 4'h0, 4'h0, 1'b0, 80, acc);
    if (dn_aw_cnt != t0)                   // may accept and forward in one cycle
      fail("W2", "a fifth AW was forwarded while the downstream write debt was already at MAX_WRITE_TXNS");
    // W4: completing W bursts, and not the arrival of a B, is what frees the
    // bound.  No B has arrived at all at this point.
    for (i = 0; i < MAX_WRITE_TXNS; i++)
      w_must(32'h5000_0000 + 32'(i), 4'hF, 1'b1, 1'b0, "W4 draining the bound");
    if (!acc) begin
      my_aw(4'd4, 32'h4000_0004, 8'd0, 6'b000000, 3'd2, 2'd1, 1'b0, 4'h0, 3'd0, 4'h0, 4'h0, 1'b0, 200, acc);
      if (!acc)
        fail("W4", "the fifth AW was still not accepted after four W bursts completed and with no B response yet delivered");
    end
    // it must now be forwarded, the bound having been freed by the W bursts.
    // t0 still holds the count from before the offer, so this is true whether
    // the forwarding happened during the offer or after the drain.
    for (t = 0; t < 200; t++) begin
      @(negedge clk);
      if (dn_aw_cnt > t0) break;
    end
    if (dn_aw_cnt == t0)
      fail("W4", "the fifth AW was never forwarded even though four W bursts had completed; only a B response was still missing");
    w_must(32'h5000_0004, 4'hF, 1'b1, 1'b0, "W4 fifth write");
    bfm_dn_b_lag(0);
    settle(900);
    check_settled("W bound phase");

    // ---- X1/X2: reset while responses are actually owed --------------------
    // The readies are held low first, so the unit finishes consuming a filtered
    // write and is left owing a B and two R beats it cannot deliver.  Resetting
    // then is what makes X1 and X2 observable: a unit that neither gates nor
    // discards those responses shows it here and nowhere else.  X4 is suspended
    // because the backpressure is ours.
    x4_en = 1'b0;
    bfm_b_ready(1'b0);
    bfm_r_ready(1'b0);
    aw_must(4'd11, 32'hA500_0000, 8'd1, 6'b110000, 3'd2, 2'd1, 1'b0, 4'h0, 3'd0, 4'h0, 4'h0, 1'b0, "X2 setup");
    w_must(32'hFFFF_0001, 4'hF, 1'b0, 1'b0, "X2 setup");
    w_must(32'hFFFF_0002, 4'hF, 1'b1, 1'b0, "X2 setup");
    wait_cycles(10);
    x1_en = 1'b1;
    bfm_reset(8);
    x1_en = 1'b0;
    bfm_b_ready(1'b1);
    bfm_r_ready(1'b1);
    x4_en = 1'b1;
    // X2: nothing may be owed or produced afterwards
    t0 = up_b_cnt + up_r_cnt;
    wait_cycles(60);
    if (up_b_cnt + up_r_cnt != t0)
      fail("X2", "a response appeared after reset for a transaction that was in flight before it");
    if (debt != 0)
      fail("X2", $sformatf("the downstream write debt is %0d after reset, expected 0", debt));

    // ---- and the unit still works afterwards -------------------------------
    sub_bresp = 2'b00; sub_buser = 1'b0;
    aw_must(4'd0, 32'h9000_0000, 8'd0, 6'b000000, 3'd2, 2'd1, 1'b0, 4'h0, 3'd0, 4'h0, 4'h0, 1'b0, "X2 after reset");
    w_must(32'h7777_0001, 4'hF, 1'b1, 1'b0, "X2 after reset");
    settle(300);
    check_settled("X2 after reset");
    aw_must(4'd6, 32'h9000_0100, 8'd1, 6'b100000, 3'd2, 2'd1, 1'b0, 4'h0, 3'd0, 4'h0, 4'h0, 1'b0, "X2 after reset filtered");
    w_must(32'h7777_1001, 4'hF, 1'b0, 1'b0, "X2 after reset filtered");
    w_must(32'h7777_1002, 4'hF, 1'b1, 1'b0, "X2 after reset filtered");
    settle(300);
    check_settled("X2 after reset filtered");
    if (f_rcnt[6] != 2)
      fail("F4", $sformatf("filtered write id=6 after reset received %0d R beats, exactly 2 are owed", f_rcnt[6]));

    // ---- verdict -----------------------------------------------------------
    $display("SUMMARY: %0d AWs forwarded, %0d W bursts completed downstream, %0d B and %0d R beats returned upstream, %0d violations",
             dn_aw_cnt, dn_wlast_cnt, up_b_cnt, up_r_cnt, err_cnt);
    if (dn_aw_cnt == 0)
      fail("P1", "not a single AW was ever forwarded");
    if (up_b_cnt == 0)
      fail("F3", "not a single B response was ever returned");
    if (err_cnt == 0) $display("RESULT: PASS");
    else              $display("RESULT: FAIL");
    $finish;
  end

endmodule