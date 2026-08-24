// ===========================================================================
// atop_filter_tb.sv -- specification-driven testbench for atop_filter
//
// Everything is decided by a model driven from OBSERVED handshakes, never from
// what the stimulus intended: the slave side is observed to build expectations,
// the master side is checked against them, and manufactured responses are
// attributed by id (F4) rather than by arrival order.
//
// Checks:  C1/C2 classification (bits [5:4] only; read response on bit [5])
//          P1  non-atomic AW forwarded with every field unmodified
//          P2  W beats forwarded unmodified and in order, wlast on same beat
//          P3  AR forwarded unmodified, master R beats returned unmodified
//          P4  master B returned unmodified (id, resp, user)
//          F1  atomic AW never forwarded; m_awatop_o zero while m_awvalid_o
//          F2  W beats of a filtered write consumed, never forwarded
//          F3  exactly one B per filtered write, SLVERR, correct id
//          F4  exactly awlen+1 R beats, SLVERR, correct id, rlast on the last
//          F5  no R beats for a filtered write with awatop[5] == 0
//          W2  downstream write debt never exceeds 4
//          W3  debt below the bound does not stall a non-atomic AW
//          W4  debt falls on a completed W burst, not on a B response
//          W5  a filtered write does not consume bound capacity
//          X1  no output valid asserted while rst_ni is low
//          X2  nothing owed after reset
//          X3  valid held with a stable payload until ready
//          X4  the 64-cycle liveness bounds
//
// Deliberately NOT checked (latitude):
//          L1  B before R, R before B, or interleaved -- attribution is by id
//          L2  s_rdata_o / s_ruser_o / s_buser_o on a manufactured response
//          L3  whether any ready is combinational or registered
//          L4  whether a later AW is stalled behind a filtered write
//          L5  the latency of a manufactured response
// ===========================================================================
module atop_filter_tb;

  // -------------------------------------------------------------------------
  // PROVIDED PLUMBING -- moves transactions, checks nothing.
  // -------------------------------------------------------------------------

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
  logic [3:0]          m_arregion;
  logic [3:0]          m_arqos;
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
  /* verilator lint_off WIDTHTRUNC */
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
  /* verilator lint_on WIDTHTRUNC */

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

  // =========================================================================
  // VERDICT
  // =========================================================================
  bit    verdict_done = 1'b0;
  string phase_name   = "startup";
  int    phase_cnt    = 0;

  task automatic tb_fail(input string clause_id, input string detail);
    if (!verdict_done) begin
      verdict_done = 1'b1;
      $display("------------------------------------------------------------");
      $display("  time    : %0t  (cycle %0d)", $time, bfm_cycle);
      $display("  phase   : %s", phase_name);
      $display("  clause  : %s", clause_id);
      $display("  detail  : %s", detail);
      $display("------------------------------------------------------------");
      $display("RESULT: FAIL");
    end
    $finish;
  endtask

  task automatic set_phase(input string nm);
    phase_name = nm;
    phase_cnt  = phase_cnt + 1;
  endtask

  // =========================================================================
  // MODEL
  // =========================================================================

  // a write whose AW has been accepted upstream but whose W burst is unfinished
  typedef struct packed { logic filt; logic [3:0] id; } wpend_t;

  // the AW that must appear, unmodified, on the master port (P1)
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
  } awrec_t;

  typedef struct packed {
    logic [31:0] data;
    logic [3:0]  strb;
    logic        last;
    logic        user;
  } wrec_t;

  typedef struct packed { logic [3:0] id; logic manuf; }                 brec_t;
  typedef struct packed { logic [3:0] id; logic [8:0] remain; }          rrec_t;
  typedef struct packed {
    logic [3:0]  id;
    logic [1:0]  resp;
    logic        user;
    logic [31:0] earliest;   // cycle before which the subordinate cannot answer
  } mbrec_t;
  typedef struct packed {
    logic [3:0]  id;
    logic [31:0] data;
    logic [1:0]  resp;
    logic        last;
  } mrrec_t;

  wpend_t wpend_q  [$];   // writes in AW order, for W-beat routing
  awrec_t exp_maw_q[$];   // AWs that must be forwarded, in order
  wrec_t  exp_mw_q [$];   // W beats that must be forwarded, in order
  awrec_t exp_mar_q[$];   // ARs that must be forwarded, in order
  brec_t  exp_b_q  [$];   // B responses owed upstream
  rrec_t  exp_r_q  [$];   // manufactured R bursts owed upstream, by id
  mbrec_t mb_q     [$];   // B responses taken from the subordinate
  mrrec_t mr_q     [$];   // R beats taken from the subordinate

  int debt = 0;           // W1, computed from master-port handshakes only

  function automatic bit queues_idle();
    return (wpend_q.size()  == 0) && (exp_maw_q.size() == 0) &&
           (exp_mw_q.size() == 0) && (exp_mar_q.size() == 0) &&
           (exp_b_q.size()  == 0) && (exp_r_q.size()   == 0) &&
           (mb_q.size()     == 0) && (mr_q.size()      == 0);
  endfunction

  task automatic model_clear();
    wpend_q.delete(); exp_maw_q.delete(); exp_mw_q.delete(); exp_mar_q.delete();
    exp_b_q.delete(); exp_r_q.delete(); mb_q.delete(); mr_q.delete();
    debt = 0;
  endtask

  // =========================================================================
  // MONITOR
  //   order within the edge: slave requests observed, master requests checked,
  //   master responses captured, slave responses checked -- so that a design
  //   which is combinational in either direction is handled correctly.
  // =========================================================================
  always @(posedge clk) begin
    automatic wpend_t wp;
    automatic awrec_t aw, aw2;
    automatic wrec_t  wr, wr2;
    automatic brec_t  br;
    automatic rrec_t  rr;
    automatic mbrec_t mb;
    automatic mrrec_t mr;
    automatic int     idx;
    automatic int     d_up, d_dn;

    if (!rst_n) begin
      model_clear();
    end else begin

      // ---- 1. slave-side requests: build the expectations ----------------
      if (s_awvalid === 1'b1 && s_awready === 1'b1) begin
        wp.filt = (s_awatop[5:4] != 2'b00);          // C1
        wp.id   = s_awid;
        wpend_q.push_back(wp);
        br.id = s_awid; br.manuf = wp.filt;
        exp_b_q.push_back(br);                        // F3 / P4
        if (wp.filt && s_awatop[5] === 1'b1) begin    // C2 / F4
          rr.id = s_awid; rr.remain = 9'(s_awlen) + 9'd1;
          exp_r_q.push_back(rr);
        end
        if (!wp.filt) begin
          aw.id = s_awid; aw.addr = s_awaddr; aw.len = s_awlen; aw.size = s_awsize;
          aw.burst = s_awburst; aw.lock = s_awlock; aw.cache = s_awcache;
          aw.prot = s_awprot; aw.qos = s_awqos; aw.region = s_awregion;
          aw.user = s_awuser;
          exp_maw_q.push_back(aw);
        end
      end

      if (s_wvalid === 1'b1 && s_wready === 1'b1) begin
        if (wpend_q.size() == 0) begin
          tb_fail("P2/F2", "a W beat was accepted while no write address was outstanding");
        end else begin
          if (wpend_q[0].filt !== 1'b1) begin
            wr.data = s_wdata; wr.strb = s_wstrb; wr.last = s_wlast; wr.user = s_wuser;
            exp_mw_q.push_back(wr);
          end
          if (s_wlast === 1'b1) void'(wpend_q.pop_front());
        end
      end

      if (s_arvalid === 1'b1 && s_arready === 1'b1) begin
        aw.id = s_arid; aw.addr = s_araddr; aw.len = s_arlen; aw.size = s_arsize;
        aw.burst = s_arburst; aw.lock = s_arlock; aw.cache = s_arcache;
        aw.prot = s_arprot; aw.qos = s_arqos; aw.region = s_arregion;
        aw.user = s_aruser;
        exp_mar_q.push_back(aw);
      end

      // ---- 2. master-side requests: check them ---------------------------
      if (m_awvalid === 1'b1 && m_awatop !== 6'b000000)
        tb_fail("F1", $sformatf("m_awatop_o = %06b while m_awvalid_o is asserted; it must be zero",
                                m_awatop));

      d_up = 0; d_dn = 0;
      if (m_awvalid === 1'b1 && m_awready === 1'b1) begin
        if (exp_maw_q.size() == 0) begin
          tb_fail("F1", $sformatf(
            "an AW (id %0h) was forwarded that the design was not given to forward -- an atomic AW must never reach the master port",
            m_awid));
        end else begin
          aw  = exp_maw_q.pop_front();
          aw2.id = m_awid; aw2.addr = m_awaddr; aw2.len = m_awlen; aw2.size = m_awsize;
          aw2.burst = m_awburst; aw2.lock = m_awlock; aw2.cache = m_awcache;
          aw2.prot = m_awprot; aw2.qos = m_awqos; aw2.region = m_awregion;
          aw2.user = m_awuser;
          if (aw2 !== aw)
            tb_fail("P1/F1", $sformatf(
              "forwarded AW altered: got id=%0h addr=%08h len=%0d size=%0d burst=%0d lock=%b cache=%0h prot=%0h qos=%0h region=%0h user=%b ; expected id=%0h addr=%08h len=%0d size=%0d burst=%0d lock=%b cache=%0h prot=%0h qos=%0h region=%0h user=%b",
              aw2.id, aw2.addr, aw2.len, aw2.size, aw2.burst, aw2.lock, aw2.cache,
              aw2.prot, aw2.qos, aw2.region, aw2.user,
              aw.id, aw.addr, aw.len, aw.size, aw.burst, aw.lock, aw.cache,
              aw.prot, aw.qos, aw.region, aw.user));
        end
        // The subordinate on the master port is fully determined: it accepts
        // every request and answers it.  Predicting its answers here, instead
        // of sampling m_bvalid/m_rvalid, keeps the checker clear of the
        // plumbing's same-timestep queue updates.
        mb.id = m_awid; mb.resp = 2'b00; mb.user = 1'b0;
        mb.earliest = 32'(bfm_cycle) + 32'(bfm_b_lag);
        mb_q.push_back(mb);
        d_up = 1;
      end

      if (m_wvalid === 1'b1 && m_wready === 1'b1) begin
        if (exp_mw_q.size() == 0) begin
          tb_fail("F2", $sformatf(
            "a W beat (data %08h) was forwarded that belongs to a filtered write -- it must be consumed instead",
            m_wdata));
        end else begin
          wr = exp_mw_q.pop_front();
          wr2.data = m_wdata; wr2.strb = m_wstrb; wr2.last = m_wlast; wr2.user = m_wuser;
          if (wr2 !== wr)
            tb_fail("P2", $sformatf(
              "forwarded W beat altered: got data=%08h strb=%04b last=%b user=%b ; expected data=%08h strb=%04b last=%b user=%b",
              wr2.data, wr2.strb, wr2.last, wr2.user, wr.data, wr.strb, wr.last, wr.user));
        end
        if (m_wlast === 1'b1) d_dn = 1;
      end

      debt = debt + d_up - d_dn;                       // W1
      if (debt > 4)
        tb_fail("W2", $sformatf("downstream write debt reached %0d; MAX_WRITE_TXNS is 4", debt));

      if (m_arvalid === 1'b1 && m_arready === 1'b1) begin
        if (exp_mar_q.size() == 0) begin
          tb_fail("P3", $sformatf("an AR (id %0h) appeared on the master port that was never offered upstream", m_arid));
        end else begin
          aw  = exp_mar_q.pop_front();
          aw2.id = m_arid; aw2.addr = m_araddr; aw2.len = m_arlen; aw2.size = m_arsize;
          aw2.burst = m_arburst; aw2.lock = m_arlock; aw2.cache = m_arcache;
          aw2.prot = m_arprot; aw2.qos = m_arqos; aw2.region = m_arregion;
          aw2.user = m_aruser;
          if (aw2 !== aw)
            tb_fail("P3", $sformatf(
              "forwarded AR altered: got id=%0h addr=%08h len=%0d size=%0d burst=%0d lock=%b cache=%0h prot=%0h qos=%0h region=%0h user=%b ; expected id=%0h addr=%08h len=%0d size=%0d burst=%0d lock=%b cache=%0h prot=%0h qos=%0h region=%0h user=%b",
              aw2.id, aw2.addr, aw2.len, aw2.size, aw2.burst, aw2.lock, aw2.cache,
              aw2.prot, aw2.qos, aw2.region, aw2.user,
              aw.id, aw.addr, aw.len, aw.size, aw.burst, aw.lock, aw.cache,
              aw.prot, aw.qos, aw.region, aw.user));
        end
        for (int k = 0; k <= int'(m_arlen); k++) begin
          mr.id   = m_arid;
          mr.data = 32'hFEED_0000 + 32'(int'(m_arlen) + 1 - k);
          mr.resp = 2'b00;
          mr.last = (k == int'(m_arlen));
          mr_q.push_back(mr);
        end
      end

      // ---- 3. slave-side responses: check them ---------------------------
      if (s_bvalid === 1'b1 && s_bready === 1'b1) begin
        idx = -1;
        for (int i = 0; i < exp_b_q.size(); i++)
          if (exp_b_q[i].id === s_bid) begin idx = i; break; end
        if (idx < 0) begin
          tb_fail("F3/P4", $sformatf(
            "B response with id %0h that no outstanding write owes -- a filtered write gets exactly one B, and a forwarded write exactly the subordinate's",
            s_bid));
        end else if (exp_b_q[idx].manuf === 1'b1) begin
          if (s_bresp !== 2'b10)
            tb_fail("F3", $sformatf("manufactured B for id %0h carries resp %02b; SLVERR (10) is required",
                                    s_bid, s_bresp));
          exp_b_q.delete(idx);
        end else begin
          idx = -1;
          for (int i = 0; i < mb_q.size(); i++)
            if (mb_q[i].id === s_bid) begin idx = i; break; end
          if (idx < 0) begin
            tb_fail("P4/F3", $sformatf(
              "B with id %0h returned upstream although the subordinate has not answered that write -- a forwarded write's B may not be manufactured",
              s_bid));
          end else if (32'(bfm_cycle) < mb_q[idx].earliest) begin
            tb_fail("P4", $sformatf(
              "B with id %0h returned upstream at cycle %0d, before the subordinate answers that write (cycle %0d) -- a forwarded write's B may not be manufactured",
              s_bid, bfm_cycle, mb_q[idx].earliest));
          end else begin
            if (s_bresp !== mb_q[idx].resp || s_buser !== mb_q[idx].user)
              tb_fail("P4", $sformatf(
                "B for id %0h altered: got resp=%02b user=%b ; the subordinate sent resp=%02b user=%b",
                s_bid, s_bresp, s_buser, mb_q[idx].resp, mb_q[idx].user));
            mb_q.delete(idx);
            for (int i = 0; i < exp_b_q.size(); i++)
              if (exp_b_q[i].id === s_bid) begin exp_b_q.delete(i); break; end
          end
        end
      end

      if (s_rvalid === 1'b1 && s_rready === 1'b1) begin
        idx = -1;
        for (int i = 0; i < exp_r_q.size(); i++)
          if (exp_r_q[i].id === s_rid) begin idx = i; break; end
        if (idx >= 0) begin
          // a manufactured beat, attributed by id as F4 requires
          if (s_rresp !== 2'b10)
            tb_fail("F4", $sformatf("manufactured R beat for id %0h carries resp %02b; SLVERR (10) is required",
                                    s_rid, s_rresp));
          else if (s_rlast !== ((exp_r_q[idx].remain == 9'd1) ? 1'b1 : 1'b0))
            tb_fail("F4", $sformatf(
              "manufactured R beat for id %0h has rlast=%b with %0d beat(s) of the burst still owed; rlast belongs on the final beat and no other",
              s_rid, s_rlast, exp_r_q[idx].remain));
          else if (exp_r_q[idx].remain <= 9'd1) exp_r_q.delete(idx);
          else exp_r_q[idx].remain = exp_r_q[idx].remain - 9'd1;
        end else begin
          idx = -1;
          for (int i = 0; i < mr_q.size(); i++)
            if (mr_q[i].id === s_rid) begin idx = i; break; end
          if (idx < 0) begin
            tb_fail("F4/F5/P3", $sformatf(
              "R beat with id %0h that nothing owes -- either too many manufactured beats, beats for a write that owes none, or a read that was never made",
              s_rid));
          end else begin
            if (s_rdata !== mr_q[idx].data || s_rresp !== mr_q[idx].resp ||
                s_rlast !== mr_q[idx].last)
              tb_fail("P3", $sformatf(
                "R beat for id %0h altered: got data=%08h resp=%02b last=%b ; the subordinate sent data=%08h resp=%02b last=%b",
                s_rid, s_rdata, s_rresp, s_rlast,
                mr_q[idx].data, mr_q[idx].resp, mr_q[idx].last));
            mr_q.delete(idx);
          end
        end
      end
    end
  end

  // ---- X1: no output valid while reset is low -------------------------------
  // The subordinate in the plumbing only clears its own queues synchronously,
  // so for the first edge of a reset it can still be offering a response that a
  // pass-through design is merely relaying.  The check is taken once it is
  // quiet, which is the state X1 is actually about.
  // Sampled at the rising edge only: rst_ni changes on the falling edge, so by
  // the rising edge an asynchronous reset has certainly propagated.
  // X1 constrains what the unit ORIGINATES.  The pass-through B and R paths are
  // combinational in their master-port inputs whatever rst_ni is doing, so those
  // two are only judged while the subordinate is quiet -- which is the gate
  // below on the plumbing's own response queues.  Nothing is judged before the
  // first rising edge: until one has happened the design's registers hold no
  // defined value and its outputs mean nothing.
  int x1_edges = 0;
  always @(posedge clk) begin
    x1_edges <= x1_edges + 1;
    if (rst_n === 1'b0 && x1_edges > 0) begin
      if (m_awvalid === 1'b1 || m_wvalid === 1'b1)
        tb_fail("X1", "the unit originates a request while rst_ni is low");
      if (bfm_bq_id.size() == 0 && bfm_rq_id.size() == 0 &&
          s_awvalid !== 1'b1 && s_wvalid !== 1'b1 && s_arvalid !== 1'b1) begin
        if (m_arvalid === 1'b1 || s_bvalid === 1'b1 || s_rvalid === 1'b1)
          tb_fail("X1", "a manufactured response is offered while rst_ni is low");
      end
    end
  end

  // ---- X3: valid held with a stable payload until ready ---------------------
  // Only the fields the contract fixes are compared: L2 leaves s_rdata_o,
  // s_ruser_o and s_buser_o free on a manufactured response.
  logic        hb, hr, haw, hw, har;
  logic [3:0]  hb_id,  hr_id,  haw_id,  har_id;
  logic [1:0]  hb_resp, hr_resp;
  logic        hr_last;
  logic [31:0] haw_addr, har_addr, hw_data;
  logic [3:0]  hw_strb;
  logic        hw_last;

  always @(posedge clk) begin
    if (!rst_n) begin
      hb <= 1'b0; hr <= 1'b0; haw <= 1'b0; hw <= 1'b0; har <= 1'b0;
    end else begin
      if (hb === 1'b1) begin
        if (s_bvalid !== 1'b1)
          tb_fail("X3", "s_bvalid_o was deasserted before s_bready_i was seen");
        else if (s_bid !== hb_id || s_bresp !== hb_resp)
          tb_fail("X3", "the s_b payload changed while the response was waiting for s_bready_i");
      end
      if (hr === 1'b1) begin
        if (s_rvalid !== 1'b1)
          tb_fail("X3", "s_rvalid_o was deasserted before s_rready_i was seen");
        else if (s_rid !== hr_id || s_rresp !== hr_resp || s_rlast !== hr_last)
          tb_fail("X3", "the s_r payload changed while the beat was waiting for s_rready_i");
      end
      if (haw === 1'b1) begin
        if (m_awvalid !== 1'b1)
          tb_fail("X3", "m_awvalid_o was deasserted before m_awready_i was seen");
        else if (m_awid !== haw_id || m_awaddr !== haw_addr)
          tb_fail("X3", "the m_aw payload changed while the request was waiting for m_awready_i");
      end
      if (hw === 1'b1) begin
        if (m_wvalid !== 1'b1)
          tb_fail("X3", "m_wvalid_o was deasserted before m_wready_i was seen");
        else if (m_wdata !== hw_data || m_wstrb !== hw_strb || m_wlast !== hw_last)
          tb_fail("X3", "the m_w payload changed while the beat was waiting for m_wready_i");
      end
      if (har === 1'b1) begin
        if (m_arvalid !== 1'b1)
          tb_fail("X3", "m_arvalid_o was deasserted before m_arready_i was seen");
        else if (m_arid !== har_id || m_araddr !== har_addr)
          tb_fail("X3", "the m_ar payload changed while the request was waiting for m_arready_i");
      end
      hb  <= s_bvalid  && !s_bready;   hb_id <= s_bid; hb_resp <= s_bresp;
      hr  <= s_rvalid  && !s_rready;   hr_id <= s_rid; hr_resp <= s_rresp; hr_last <= s_rlast;
      haw <= m_awvalid && !m_awready;  haw_id <= m_awid; haw_addr <= m_awaddr;
      hw  <= m_wvalid  && !m_wready;   hw_data <= m_wdata; hw_strb <= m_wstrb; hw_last <= m_wlast;
      har <= m_arvalid && !m_arready;  har_id <= m_arid; har_addr <= m_araddr;
    end
  end

  // =========================================================================
  // STIMULUS HELPERS
  // =========================================================================

  // A full-field AW, so that P1's "every field unmodified" is actually tested.
  task automatic tb_aw(input logic [3:0] id, input logic [31:0] addr,
                       input logic [7:0] len, input logic [5:0] atop,
                       input logic [2:0] size, input logic [1:0] burst,
                       input logic lock, input logic [3:0] cache,
                       input logic [2:0] prot, input logic [3:0] qos,
                       input logic [3:0] region, input logic user,
                       input int timeout, output bit accepted);
    int t;
    @(negedge clk);
    s_awid = id; s_awaddr = addr; s_awlen = len; s_awatop = atop; s_awsize = size;
    s_awburst = burst; s_awlock = lock; s_awcache = cache; s_awprot = prot;
    s_awqos = qos; s_awregion = region; s_awuser = user;
    s_awvalid = 1'b1;
    accepted = 1'b0;
    for (t = 0; t < timeout; t++) begin
      @(posedge clk);
      if (s_awready === 1'b1) begin accepted = 1'b1; break; end
    end
    @(negedge clk) s_awvalid = 1'b0;
  endtask

  task automatic tb_ar(input logic [3:0] id, input logic [31:0] addr,
                       input logic [7:0] len, input logic [2:0] size,
                       input logic [1:0] burst, input logic lock,
                       input logic [3:0] cache, input logic [2:0] prot,
                       input logic [3:0] qos, input logic [3:0] region,
                       input logic user, input int timeout, output bit accepted);
    int t;
    @(negedge clk);
    s_arid = id; s_araddr = addr; s_arlen = len; s_arsize = size; s_arburst = burst;
    s_arlock = lock; s_arcache = cache; s_arprot = prot; s_arqos = qos;
    s_arregion = region; s_aruser = user;
    s_arvalid = 1'b1;
    accepted = 1'b0;
    for (t = 0; t < timeout; t++) begin
      @(posedge clk);
      if (s_arready === 1'b1) begin accepted = 1'b1; break; end
    end
    @(negedge clk) s_arvalid = 1'b0;
  endtask

  task automatic tb_w(input logic [31:0] data, input logic [3:0] strb,
                      input bit last, input logic user,
                      input int timeout, output bit accepted);
    int t;
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

  // Address phase only, with every field derived from the id so that a dropped
  // or swapped field shows up.
  task automatic send_aw(input logic [3:0] id, input logic [7:0] len,
                         input logic [5:0] atop, input int timeout,
                         input bit must, output bit accepted);
    tb_aw(id, 32'h1000_0000 + (32'(id) << 8), len, atop, 3'd2, 2'd1, id[1],
          4'(id ^ 4'h5), 3'(id), 4'(id ^ 4'hA), 4'(id ^ 4'h3), id[0],
          timeout, accepted);
    if (must && !accepted)
      tb_fail("X4/W3", $sformatf(
        "AW id %0h was not accepted within %0d cycles although the write bound permits it",
        id, timeout));
  endtask

  task automatic send_wburst(input logic [3:0] id, input logic [7:0] len,
                             input int timeout);
    bit acc;
    for (int i = 0; i <= int'(len); i++) begin
      tb_w(32'hD000_0000 + (32'(id) << 16) + 32'(i), 4'(i + 1),
           (i == int'(len)), id[0], timeout, acc);
      if (!acc)
        tb_fail("X4/F2", $sformatf(
          "W beat %0d of write id %0h was not accepted within %0d cycles", i, id, timeout));
    end
  endtask

  // X4's bound is conditional on the sink holding ready.  While responses are
  // being left unconsumed the unit is entitled to refuse W beats, so this
  // variant reports nothing when a beat is not taken.
  task automatic send_wburst_soft(input logic [3:0] id, input logic [7:0] len,
                                  input int timeout);
    bit acc;
    for (int i = 0; i <= int'(len); i++) begin
      tb_w(32'hD000_0000 + (32'(id) << 16) + 32'(i), 4'(i + 1),
           (i == int'(len)), id[0], timeout, acc);
      if (!acc) return;
    end
  endtask

  task automatic do_write(input logic [3:0] id, input logic [7:0] len,
                          input logic [5:0] atop);
    bit acc;
    send_aw(id, len, atop, 80, 1'b1, acc);
    send_wburst(id, len, 80);
  endtask

  // Everything owed must have been delivered within `budget` cycles.
  task automatic settle(input int budget);
    int t;
    for (t = 0; t < budget; t++) begin
      @(posedge clk);
      if (queues_idle()) break;
    end
    @(negedge clk);
    if (exp_r_q.size() != 0)
      tb_fail("F4/X4", $sformatf(
        "%0d manufactured R beat(s) still owed after %0d cycles (first: id %0h, %0d beat(s) missing)",
        exp_r_q.size(), budget, exp_r_q[0].id, exp_r_q[0].remain));
    if (exp_b_q.size() != 0)
      tb_fail("F3/X4", $sformatf(
        "%0d B response(s) still owed after %0d cycles (first: id %0h, %0s)",
        exp_b_q.size(), budget, exp_b_q[0].id,
        exp_b_q[0].manuf ? "manufactured" : "forwarded write"));
    if (exp_mw_q.size() != 0)
      tb_fail("P2/X4", $sformatf("%0d W beat(s) of a forwarded write never reached the master port",
                                 exp_mw_q.size()));
    if (exp_maw_q.size() != 0)
      tb_fail("P1/X4", $sformatf("%0d accepted non-atomic AW(s) never reached the master port",
                                 exp_maw_q.size()));
    if (exp_mar_q.size() != 0)
      tb_fail("P3/X4", $sformatf("%0d accepted AR(s) never reached the master port",
                                 exp_mar_q.size()));
    if (mb_q.size() != 0)
      tb_fail("P4/X4", $sformatf("%0d B response(s) taken from the subordinate were never returned upstream",
                                 mb_q.size()));
    if (mr_q.size() != 0)
      tb_fail("P3/X4", $sformatf("%0d R beat(s) taken from the subordinate were never returned upstream",
                                 mr_q.size()));
    if (wpend_q.size() != 0)
      tb_fail("F2/X4", $sformatf("%0d write(s) have an unfinished W burst", wpend_q.size()));
  endtask

  // =========================================================================
  // STIMULUS
  // =========================================================================
  //   write ids live in 1..7, read ids in 8..15, so that a manufactured R beat
  //   and a pass-through R beat can never be confused for one another.
  initial begin
    bit acc;

    bfm_reset(5);
    repeat (5) @(posedge clk);

    // ---------- pass-through ----------------------------------------------
    set_phase("P1/P2/P4 single-beat non-atomic write");
    do_write(4'h1, 8'd0, 6'b000000);
    settle(80);

    set_phase("P2 four-beat non-atomic write");
    do_write(4'h2, 8'd3, 6'b000000);
    settle(80);

    set_phase("C1 awatop[3:0] alone does not make a write atomic");
    do_write(4'h3, 8'd1, 6'b001111);       // [5:4] == 00 -> must be forwarded
    settle(80);
    do_write(4'h3, 8'd0, 6'b000110);
    settle(80);

    set_phase("P3 read pass-through, three-beat burst");
    tb_ar(4'h8, 32'h2000_0100, 8'd2, 3'd2, 2'd1, 1'b1, 4'hB, 3'd6, 4'h9, 4'h4, 1'b1, 80, acc);
    if (!acc) tb_fail("X4/P3", "AR was not accepted within 80 cycles");
    settle(80);

    // ---------- filtering --------------------------------------------------
    set_phase("F1/F2/F3/F5 atomic write without a read response, one beat");
    do_write(4'h4, 8'd0, 6'b010000);       // [5:4]=01 -> atomic, no R owed
    settle(70);                            // X4: within 64 cycles of wlast

    set_phase("F2/F5 atomic write without a read response, four beats");
    do_write(4'h5, 8'd3, 6'b011010);
    settle(70);

    set_phase("F3/F4 atomic write owing a read response, one beat");
    do_write(4'h6, 8'd0, 6'b100000);       // [5:4]=10 -> R owed
    settle(70);

    set_phase("F4 atomic write owing a four-beat read response");
    do_write(4'h7, 8'd3, 6'b110001);       // [5:4]=11 -> R owed, len+1 = 4
    settle(70);

    set_phase("F4 atomic write owing an eight-beat read response");
    do_write(4'h2, 8'd7, 6'b100011);
    settle(70);

    // ---------- one transaction after another ------------------------------
    set_phase("F3/F4 three filtered writes back to back");
    do_write(4'h1, 8'd1, 6'b100000);
    do_write(4'h2, 8'd0, 6'b010000);
    do_write(4'h3, 8'd2, 6'b110000);
    settle(120);

    set_phase("mixed traffic: forwarded, filtered, forwarded");
    do_write(4'h4, 8'd1, 6'b000000);
    do_write(4'h5, 8'd1, 6'b100100);
    do_write(4'h6, 8'd2, 6'b000000);
    tb_ar(4'h9, 32'h3000_0000, 8'd1, 3'd2, 2'd1, 1'b0, 4'h6, 3'd1, 4'hC, 4'h2, 1'b0, 80, acc);
    if (!acc) tb_fail("X4/P3", "AR was not accepted within 80 cycles");
    do_write(4'h7, 8'd0, 6'b010001);
    settle(160);

    // ---------- back-pressure and X3 ---------------------------------------
    set_phase("X3 pass-through B held while s_bready_i is low");
    bfm_dn_b_lag(12);
    do_write(4'h1, 8'd0, 6'b000000);
    bfm_b_ready(1'b0);
    repeat (25) @(posedge clk);            // the B waits here; X3 watches it
    bfm_b_ready(1'b1);
    settle(80);
    bfm_dn_b_lag(0);

    set_phase("X3 pass-through R held while s_rready_i is low");
    bfm_r_ready(1'b0);
    tb_ar(4'hA, 32'h4000_0000, 8'd3, 3'd2, 2'd1, 1'b0, 4'h1, 3'd2, 4'h3, 4'h4, 1'b1, 80, acc);
    if (!acc) tb_fail("X4/P3", "AR was not accepted within 80 cycles");
    repeat (20) @(posedge clk);
    bfm_r_ready(1'b1);
    settle(80);

    set_phase("X3/L1/L5 manufactured responses held while both readies are low");
    bfm_b_ready(1'b0);
    bfm_r_ready(1'b0);
    send_aw(4'h6, 8'd3, 6'b100000, 80, 1'b0, acc);
    if (acc) begin
      // R beats may already be waiting here, before the burst is finished, so
      // release the readies from a second process rather than deadlocking.
      fork
        begin
          repeat (18) @(posedge clk);
          bfm_r_ready(1'b1);
          repeat (4) @(posedge clk);
          bfm_b_ready(1'b1);
        end
        send_wburst(4'h6, 8'd3, 400);
      join
    end else begin
      bfm_r_ready(1'b1);
      bfm_b_ready(1'b1);
    end
    settle(120);

    // ---------- the write bound --------------------------------------------
    set_phase("W2/W3 four AWs with no write data, then a fifth");
    send_aw(4'h1, 8'd0, 6'b000000, 80, 1'b1, acc);   // debt 0 -> 1
    send_aw(4'h2, 8'd0, 6'b000000, 80, 1'b1, acc);   // debt 1 -> 2
    send_aw(4'h3, 8'd0, 6'b000000, 80, 1'b1, acc);   // debt 2 -> 3
    send_aw(4'h4, 8'd0, 6'b000000, 80, 1'b1, acc);   // debt 3 -> 4  (W3)
    send_aw(4'h5, 8'd0, 6'b000000, 40, 1'b0, acc);   // may be refused (W2)
    send_aw(4'h6, 8'd0, 6'b000000, 40, 1'b0, acc);
    // now let the four bursts finish; the monitor has been watching the debt
    send_wburst(4'h1, 8'd0, 80);
    send_wburst(4'h2, 8'd0, 80);
    send_wburst(4'h3, 8'd0, 80);
    send_wburst(4'h4, 8'd0, 80);
    settle(200);
    set_phase("W3 the bound releases once the bursts have finished");
    do_write(4'h5, 8'd0, 6'b000000);
    settle(120);

    set_phase("W4 the debt falls on a completed W burst, not on a B response");
    bfm_dn_b_lag(200);                     // the subordinate answers nothing yet
    for (int i = 0; i < 7; i++) begin
      send_aw(4'(i + 1), 8'd0, 6'b000000, 80, 1'b1, acc);
      send_wburst(4'(i + 1), 8'd0, 80);
    end
    settle(400);
    bfm_dn_b_lag(0);

    set_phase("W5 filtered writes do not consume bound capacity");
    do_write(4'h1, 8'd0, 6'b010000);
    settle(70);
    do_write(4'h2, 8'd0, 6'b100000);
    settle(70);
    do_write(4'h3, 8'd1, 6'b010000);
    settle(70);
    do_write(4'h4, 8'd0, 6'b110000);
    settle(70);
    do_write(4'h5, 8'd0, 6'b010000);
    settle(70);
    do_write(4'h6, 8'd1, 6'b000000);       // must still be forwarded
    settle(120);

    // ---------- X1: nothing originated while reset is low --------------------
    // X2 says the unit's behaviour must not depend on anything presented while
    // reset was low, so presenting something is fair game; X1 says that while
    // it is low no request is originated on the master port.
    set_phase("X1 requests offered while rst_ni is low originate nothing");
    @(negedge clk) rst_n = 1'b0;
    @(negedge clk);
    s_awid = 4'h5; s_awaddr = 32'h1000_0000; s_awlen = 8'd1; s_awatop = 6'b000000;
    s_awsize = 3'd2; s_awburst = 2'd1; s_awvalid = 1'b1;
    s_wdata = 32'hAAAA_5555; s_wstrb = 4'hF; s_wlast = 1'b0; s_wvalid = 1'b1;
    repeat (8) @(posedge clk);           // the X1 monitor is watching here
    @(negedge clk);
    s_awvalid = 1'b0; s_wvalid = 1'b0;
    repeat (3) @(posedge clk);
    @(negedge clk) rst_n = 1'b1;
    repeat (4) @(posedge clk);
    set_phase("X2 service is clean after that reset");
    do_write(4'h3, 8'd0, 6'b000000);
    settle(80);

    // ---------- reset in flight ---------------------------------------------
    set_phase("X2 reset with a filtered write in flight");
    bfm_b_ready(1'b0);
    bfm_r_ready(1'b0);
    send_aw(4'h7, 8'd2, 6'b100000, 60, 1'b0, acc);
    if (acc) send_wburst_soft(4'h7, 8'd2, 60);
    bfm_reset(4);
    bfm_b_ready(1'b1);
    bfm_r_ready(1'b1);
    repeat (60) @(posedge clk);            // any response now is unowed
    @(negedge clk);
    if (!queues_idle())
      tb_fail("X2", "the unit still owed something after reset");

    set_phase("normal service after reset");
    do_write(4'h1, 8'd1, 6'b000000);
    settle(80);
    do_write(4'h2, 8'd1, 6'b100000);
    settle(70);
    tb_ar(4'hB, 32'h5000_0000, 8'd0, 3'd2, 2'd1, 1'b0, 4'h0, 3'd0, 4'h0, 4'h0, 1'b0, 80, acc);
    if (!acc) tb_fail("X4/P3", "AR was not accepted within 80 cycles");
    settle(80);

    if (!verdict_done) begin
      $display("all %0d phases clean", phase_cnt);
      $display("RESULT: PASS");
    end
    $finish;
  end

endmodule