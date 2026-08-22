module atop_filter_tb;

// ---------------------------------------------------------------------------
// PROVIDED PLUMBING -- moves transactions, checks nothing.
// ---------------------------------------------------------------------------
  // ---- clock ---------------------------------------------------------------
  logic clk = 1'b0;
  always #5 clk = ~clk;

  // A free-running cycle count, for your own bookkeeping and messages.
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
// TESTBENCH IMPLEMENTATION
// ---------------------------------------------------------------------------

  task automatic fail(string msg);
    $display("RESULT: FAIL (%s)", msg);
    $finish;
  endtask

  typedef struct { logic [3:0] id; logic [31:0] addr; logic [7:0] len; logic [5:0] atop; logic is_atomic; logic owes_r; int w_beats_expected; } aw_tx_t;
  typedef struct { logic last; } w_beat_t;
  typedef struct { logic [1:0] resp; logic is_mfg; logic user; } expected_b_t;
  typedef struct { logic [1:0] resp; logic last; logic is_mfg; logic [31:0] data; logic user; } expected_r_t;
  typedef struct { logic [3:0] id; logic [31:0] addr; logic [7:0] len; } ar_tx_t;

  typedef expected_b_t queue_of_b_t[$];
  typedef expected_r_t queue_of_r_t[$];

  aw_tx_t w_match_q[$];
  aw_tx_t expected_m_aw_q[$];
  w_beat_t expected_m_w_q[$];
  queue_of_b_t exp_slv_b_q[16];
  queue_of_r_t exp_slv_r_q[16];
  ar_tx_t exp_m_ar_q[$];

  aw_tx_t current_w_tx;
  bit in_w_burst = 0;
  int w_beats_done = 0;
  int w_debt = 0;

  // Liveness tracking
  int aw_wait_cycles = 0;
  int w_wait_cycles = 0;
  int b_wait_cycles[16];
  int r_wait_cycles[16];

  always @(posedge clk) begin
    if (!rst_n) begin
      w_debt <= 0;
      in_w_burst <= 0;
      w_beats_done <= 0;
      w_match_q.delete();
      expected_m_aw_q.delete();
      expected_m_w_q.delete();
      exp_m_ar_q.delete();
      for(int i=0; i<16; i++) begin
        exp_slv_b_q[i].delete();
        exp_slv_r_q[i].delete();
        b_wait_cycles[i] = 0;
        r_wait_cycles[i] = 0;
      end
      aw_wait_cycles = 0;
      w_wait_cycles = 0;

      // X1: outputs valid during reset
      if (s_bvalid || s_rvalid || m_awvalid || m_wvalid || m_arvalid) 
        fail("X1: output valid asserted while reset is low");

    end else begin
      automatic int inc;
      automatic int dec;
      inc = (m_awvalid && m_awready) ? 1 : 0;
      dec = (m_wvalid && m_wready && m_wlast) ? 1 : 0;
      w_debt <= w_debt + inc - dec;
      
      if (w_debt + inc - dec > 4) fail("W2: downstream write debt exceeds 4");

      if (m_awvalid && m_awatop != 0) fail("F1: m_awatop must be 0 when m_awvalid is high");

      // X4 trackers
      if (s_awvalid && !s_awready) aw_wait_cycles++; else aw_wait_cycles = 0;
      if (s_wvalid && !s_wready) w_wait_cycles++; else w_wait_cycles = 0;

      if (aw_wait_cycles > 64 && w_debt < 4) fail("X4/W3: AW stalled > 64 cycles when debt < 4");
      if (w_wait_cycles > 64) fail("X4: W stalled > 64 cycles");

      for (int i=0; i<16; i++) begin
        if (exp_slv_b_q[i].size() > 0) b_wait_cycles[i]++;
        else b_wait_cycles[i] = 0;
        if (b_wait_cycles[i] > 64 && s_bready) fail("X4: B response > 64 cycles");

        if (exp_slv_r_q[i].size() > 0) r_wait_cycles[i]++;
        else r_wait_cycles[i] = 0;
        if (r_wait_cycles[i] > 64 && s_rready) fail("X4: R response > 64 cycles");
      end

      // s_aw handshake
      if (s_awvalid && s_awready) begin
        automatic logic [1:0] atop_top = s_awatop[5:4];
        automatic bit is_atomic = (atop_top != 2'b00); // C1
        automatic bit owes_r = s_awatop[5];            // C2
        automatic aw_tx_t tx;
        tx.id = s_awid; tx.addr = s_awaddr; tx.len = s_awlen; tx.atop = s_awatop;
        tx.is_atomic = is_atomic; tx.owes_r = owes_r; tx.w_beats_expected = s_awlen + 1;
        w_match_q.push_back(tx);
        if (!is_atomic) expected_m_aw_q.push_back(tx);
      end

      // m_aw handshake
      if (m_awvalid && m_awready) begin
        if (expected_m_aw_q.size() == 0) fail("F1: unexpected m_aw handshake (atomic forwarded?)");
        else begin
          automatic aw_tx_t exp = expected_m_aw_q.pop_front();
          if (m_awid != exp.id || m_awaddr != exp.addr || m_awlen != exp.len) fail("P1: m_aw payload mismatch");
        end
      end

      // s_w handshake
      if (s_wvalid && s_wready) begin
        if (!in_w_burst) begin
          if (w_match_q.size() == 0) fail("Testbench error: W burst without AW");
          current_w_tx = w_match_q.pop_front();
          in_w_burst = 1;
          w_beats_done = 0;
        end
        w_beats_done++;

        if (!current_w_tx.is_atomic) begin
          automatic w_beat_t wb; wb.last = s_wlast;
          expected_m_w_q.push_back(wb);
        end

        if (s_wlast) begin
          if (w_beats_done != current_w_tx.w_beats_expected) fail("W burst length mismatch with AW len");
          in_w_burst = 0;
          if (current_w_tx.is_atomic) begin
            automatic expected_b_t eb; eb.resp = 2'b10; eb.is_mfg = 1; eb.user = 0;
            exp_slv_b_q[current_w_tx.id].push_back(eb); // F3
            if (current_w_tx.owes_r) begin
              for (int i=0; i<current_w_tx.w_beats_expected; i++) begin
                automatic expected_r_t er; 
                er.resp = 2'b10; er.last = (i == current_w_tx.w_beats_expected - 1);
                er.is_mfg = 1; er.data = 0; er.user = 0;
                exp_slv_r_q[current_w_tx.id].push_back(er); // F4
              end
            end
          end
        end
      end

      // m_w handshake
      if (m_wvalid && m_wready) begin
        if (expected_m_w_q.size() == 0) fail("F2: W beat forwarded but none expected");
        else begin
          automatic w_beat_t exp = expected_m_w_q.pop_front();
          if (m_wlast != exp.last) fail("P2: m_wlast mismatch");
        end
      end

      // m_b handshake
      if (m_bvalid && m_bready) begin
        automatic expected_b_t eb; eb.resp = m_bresp; eb.is_mfg = 0; eb.user = m_buser;
        exp_slv_b_q[m_bid].push_back(eb); // P4
      end

      // s_b handshake
      if (s_bvalid && s_bready) begin
        if (exp_slv_b_q[s_bid].size() == 0) fail("Unexpected B response on slave");
        else begin
          automatic expected_b_t eb = exp_slv_b_q[s_bid].pop_front();
          if (s_bresp != eb.resp) fail("F3/P4: B resp mismatch");
          if (!eb.is_mfg && s_buser != eb.user) fail("P4: B user mismatch");
        end
      end

      // s_ar handshake
      if (s_arvalid && s_arready) begin
        automatic ar_tx_t tx; tx.id = s_arid; tx.addr = s_araddr; tx.len = s_arlen;
        exp_m_ar_q.push_back(tx);
      end

      // m_ar handshake
      if (m_arvalid && m_arready) begin
        if (exp_m_ar_q.size() == 0) fail("Unexpected master AR");
        else begin
          automatic ar_tx_t tx = exp_m_ar_q.pop_front();
          if (m_arid != tx.id || m_araddr != tx.addr || m_arlen != tx.len) fail("P3: AR mismatch");
        end
      end

      // m_r handshake
      if (m_rvalid && m_rready) begin
        automatic expected_r_t er; er.resp = m_rresp; er.last = m_rlast; er.is_mfg = 0; er.data = m_rdata; er.user = m_ruser;
        exp_slv_r_q[m_rid].push_back(er); // P3
      end

      // s_r handshake
      if (s_rvalid && s_rready) begin
        if (exp_slv_r_q[s_rid].size() == 0) fail("Unexpected R response on slave");
        else begin
          automatic expected_r_t er = exp_slv_r_q[s_rid].pop_front();
          if (s_rresp != er.resp) fail("F4/P3: R resp mismatch");
          if (s_rlast != er.last) fail("F4/P3: R last mismatch");
          if (!er.is_mfg && s_rdata != er.data) fail("P3: R data mismatch");
          if (!er.is_mfg && s_ruser != er.user) fail("P3: R user mismatch");
        end
      end
    end
  end

  // X3 Payload Stability
  logic m_awvalid_stalled; logic [3:0] m_awid_s; logic [31:0] m_awaddr_s; logic [7:0] m_awlen_s; logic [5:0] m_awatop_s;
  logic m_wvalid_stalled; logic [31:0] m_wdata_s; logic [3:0] m_wstrb_s; logic m_wlast_s;
  logic s_bvalid_stalled; logic [3:0] s_bid_s; logic [1:0] s_bresp_s;
  logic s_rvalid_stalled; logic [3:0] s_rid_s; logic [1:0] s_rresp_s; logic s_rlast_s;
  logic m_arvalid_stalled; logic [3:0] m_arid_s; logic [31:0] m_araddr_s; logic [7:0] m_arlen_s;

  always @(posedge clk) begin
    if (!rst_n) begin
      m_awvalid_stalled <= 0; m_wvalid_stalled <= 0; s_bvalid_stalled <= 0; s_rvalid_stalled <= 0; m_arvalid_stalled <= 0;
    end else begin
      if (m_awvalid_stalled) begin
        if (!m_awvalid) fail("X3: m_awvalid dropped");
        if (m_awid != m_awid_s || m_awaddr != m_awaddr_s || m_awlen != m_awlen_s || m_awatop != m_awatop_s) fail("X3: m_aw payload changed");
      end
      m_awvalid_stalled <= m_awvalid && !m_awready;
      if (m_awvalid && (!m_awvalid_stalled || m_awready)) begin
        m_awid_s <= m_awid; m_awaddr_s <= m_awaddr; m_awlen_s <= m_awlen; m_awatop_s <= m_awatop;
      end

      if (m_wvalid_stalled) begin
        if (!m_wvalid) fail("X3: m_wvalid dropped");
        if (m_wdata != m_wdata_s || m_wstrb != m_wstrb_s || m_wlast != m_wlast_s) fail("X3: m_w payload changed");
      end
      m_wvalid_stalled <= m_wvalid && !m_wready;
      if (m_wvalid && (!m_wvalid_stalled || m_wready)) begin
        m_wdata_s <= m_wdata; m_wstrb_s <= m_wstrb; m_wlast_s <= m_wlast;
      end

      if (s_bvalid_stalled) begin
        if (!s_bvalid) fail("X3: s_bvalid dropped");
        if (s_bid != s_bid_s || s_bresp != s_bresp_s) fail("X3: s_b payload changed");
      end
      s_bvalid_stalled <= s_bvalid && !s_bready;
      if (s_bvalid && (!s_bvalid_stalled || s_bready)) begin
        s_bid_s <= s_bid; s_bresp_s <= s_bresp;
      end

      if (s_rvalid_stalled) begin
        if (!s_rvalid) fail("X3: s_rvalid dropped");
        if (s_rid != s_rid_s || s_rresp != s_rresp_s || s_rlast != s_rlast_s) fail("X3: s_r payload changed");
      end
      s_rvalid_stalled <= s_rvalid && !s_rready;
      if (s_rvalid && (!s_rvalid_stalled || s_rready)) begin
        s_rid_s <= s_rid; s_rresp_s <= s_rresp; s_rlast_s <= s_rlast;
      end

      if (m_arvalid_stalled) begin
        if (!m_arvalid) fail("X3: m_arvalid dropped");
        if (m_arid != m_arid_s || m_araddr != m_araddr_s || m_arlen != m_arlen_s) fail("X3: m_ar payload changed");
      end
      m_arvalid_stalled <= m_arvalid && !m_arready;
      if (m_arvalid && (!m_arvalid_stalled || m_arready)) begin
        m_arid_s <= m_arid; m_araddr_s <= m_araddr; m_arlen_s <= m_arlen;
      end
    end
  end

  // STIMULUS
  initial begin
    bit accepted;
    bfm_dn_b_lag(0);
    #10;
    bfm_reset(5);

    // --- TEST 1: Normal pass-through ---
    bfm_aw(1, 32'h100, 0, 6'b00_0000, 100, accepted);
    if (!accepted) fail("T1 AW not accepted");
    bfm_w(32'hAAAA, 4'hF, 1, 100, accepted);
    if (!accepted) fail("T1 W not accepted");
    while (exp_slv_b_q[1].size() > 0) @(posedge clk);

    // --- TEST 2: Atomic no R ---
    bfm_aw(2, 32'h200, 1, 6'b01_0000, 100, accepted);
    bfm_w(32'hB1, 4'hF, 0, 100, accepted);
    bfm_w(32'hB2, 4'hF, 1, 100, accepted);
    while (exp_slv_b_q[2].size() > 0) @(posedge clk);

    // --- TEST 3: Atomic with R ---
    bfm_aw(3, 32'h300, 2, 6'b10_0000, 100, accepted);
    bfm_w(32'hC1, 4'hF, 0, 100, accepted);
    bfm_w(32'hC2, 4'hF, 0, 100, accepted);
    bfm_w(32'hC3, 4'hF, 1, 100, accepted);
    while (exp_slv_b_q[3].size() > 0 || exp_slv_r_q[3].size() > 0) @(posedge clk);

    // --- TEST 4: Max Debt (W2, W3, W4) ---
    bfm_aw(4, 32'h400, 0, 6'b00_0000, 100, accepted);
    bfm_aw(5, 32'h500, 0, 6'b00_0000, 100, accepted);
    bfm_aw(6, 32'h600, 0, 6'b00_0000, 100, accepted);
    bfm_aw(7, 32'h700, 0, 6'b00_0000, 100, accepted);
    
    @(posedge clk);
    fork
      begin
        bfm_aw(8, 32'h800, 0, 6'b00_0000, 50, accepted);
        if (!accepted) fail("W3: Non-atomic AW stalled despite master W completion");
      end
      begin
        repeat(15) @(posedge clk);
        bfm_w(32'hD4, 4'hF, 1, 100, accepted);
      end
    join
    
    // Test W5 (Filtered write doesn't change debt)
    bfm_aw(11, 32'hB00, 0, 6'b01_0000, 100, accepted);
    bfm_w(32'hF1, 4'hF, 1, 100, accepted);
    
    bfm_w(32'hD5, 4'hF, 1, 100, accepted);
    bfm_w(32'hD6, 4'hF, 1, 100, accepted);
    bfm_w(32'hD7, 4'hF, 1, 100, accepted);
    bfm_w(32'hD8, 4'hF, 1, 100, accepted);

    while (exp_slv_b_q[4].size() > 0 || exp_slv_b_q[8].size() > 0 || exp_slv_b_q[11].size() > 0) @(posedge clk);

    // --- TEST 5: AR / R Pass-through ---
    bfm_ar(9, 32'h900, 1, 100, accepted);
    while (exp_slv_r_q[9].size() > 0) @(posedge clk);

    // --- TEST 6: X4 Liveness (Holding Ready Low) ---
    bfm_b_ready(0);
    bfm_r_ready(0);
    bfm_aw(10, 32'hA00, 0, 6'b11_0000, 100, accepted);
    bfm_w(32'hE1, 4'hF, 1, 100, accepted);

    repeat(30) @(posedge clk);
    bfm_b_ready(1);
    bfm_r_ready(1);
    while (exp_slv_b_q[10].size() > 0 || exp_slv_r_q[10].size() > 0) @(posedge clk);

    // Finish conditions
    repeat(50) @(posedge clk);

    if (w_match_q.size() > 0) fail("Orphan AW (no W burst seen)");
    if (expected_m_aw_q.size() > 0) fail("Orphan AW (not forwarded)");
    if (expected_m_w_q.size() > 0) fail("Orphan W (not forwarded)");
    for (int i=0; i<16; i++) begin
      if (exp_slv_b_q[i].size() > 0) fail("Missing expected B response");
      if (exp_slv_r_q[i].size() > 0) fail("Missing expected R response");
    end
    if (exp_m_ar_q.size() > 0) fail("Orphan AR (not forwarded)");

    $display("RESULT: PASS");
    $finish;
  end

endmodule