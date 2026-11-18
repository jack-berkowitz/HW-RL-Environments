module atop_filter_tb;

  // ---------------------------------------------------------------------------
  // PROVIDED PLUMBING -- moves transactions, checks nothing.
  // ---------------------------------------------------------------------------
  logic clk = 1'b0;
  always #5 clk = ~clk;

  int bfm_cycle = 0;
  always @(posedge clk) if (rst_n) bfm_cycle <= bfm_cycle + 1;

  logic rst_n = 1'b0;      // ACTIVE LOW

  task automatic bfm_reset(input int cycles = 5);
    @(negedge clk);
    rst_n = 1'b0;
    repeat (cycles) @(posedge clk);
    @(negedge clk);
    rst_n = 1'b1;
  endtask

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
    s_bready  = 1'b1; s_rready  = 1'b1;
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

  // ===========================================================================
  // CHECKER STATE
  // ===========================================================================
  bit fail;

  // expected forwarded AW / AR payloads (atop excluded: F1 forces m_awatop=0)
  logic [65:0] exp_aw [$];
  logic [65:0] exp_ar [$];
  // expected forwarded W beats: {data,strb,last,user}
  logic [37:0] exp_w  [$];
  // expected pass-through B ids (in order)
  logic [3:0]  exp_pb [$];
  // expected pass-through R beats: {id,data,last,user}
  logic [37:0] exp_pr [$];
  // W beats offered by stimulus: {data,strb,last,filtered}
  logic [37:0] w_offered [$];
  // manufactured responses owed, per ID (F3/F4/F5)
  int exp_b_cnt [0:15];
  int exp_r_cnt [0:15];

  int debt_aw, debt_wl;      // W1 bookkeeping
  int n_r;
  logic [65:0] q_e;
  logic [37:0] q_w;
  logic [37:0] w_e;

  // X3 stability shadow registers
  logic st_maw, st_mw, st_mb, st_mr, st_mar;
  logic [71:0] pv_maw;
  logic [37:0] pv_mw;
  logic [6:0]  pv_mb;
  logic [37:0] pv_mr;
  logic [65:0] pv_mar;

  task automatic chk_fail(input string clause, input string msg);
    fail = 1'b1;
    $display("Violation [%s]: %s (cycle %0d)", clause, msg, bfm_cycle);
  endtask

  // Offer one W beat; tell the model whether it belongs to a filtered write.
  task automatic offer_w(input logic [31:0] data, input bit last, input bit filtered);
    bit acc;
    w_offered.push_back({data, 4'hF, last, filtered});
    bfm_w(data, 4'hF, last, 128, acc);
    if (!acc) begin
      if (w_offered.size() > 0) void'(w_offered.pop_front());
      chk_fail("X4/F2", "W beat not consumed within bound");
    end
  endtask

  task automatic do_write(input logic [3:0] id, input logic [7:0] len,
                          input logic [5:0] atop);
    bit acc;
    bit filt;
    int k;
    filt = (atop[5:4] != 2'b00);
    bfm_aw(id, 32'h0000_1000 + id, len, atop, 128, acc);
    if (!acc) begin
      chk_fail("X4", "AW not accepted within bound");
    end else begin
      for (k = 0; k <= int'(len); k++)
        offer_w(32'hA500_0000 + (32'(id) << 8) + 32'(k), (k == int'(len)), filt);
    end
  endtask

  // Wait until the DUT owes nothing and the subordinate has answered everything.
  task automatic drain(input int max_cycles);
    int t, i;
    bit done;
    done = 1'b0;
    for (t = 0; (t < max_cycles) && !done; t++) begin
      @(posedge clk);
      done = (exp_aw.size() == 0) && (exp_ar.size() == 0) && (exp_w.size() == 0)
          && (exp_pb.size() == 0) && (exp_pr.size() == 0) && (w_offered.size() == 0)
          && (!m_bvalid) && (!m_rvalid)
          && (bfm_bq_id.size() == 0) && (bfm_rq_id.size() == 0);
      for (i = 0; i < 16; i++)
        if ((exp_b_cnt[i] != 0) || (exp_r_cnt[i] != 0)) done = 1'b0;
    end
    if (!done) chk_fail("F3/F4/X4", "outstanding responses did not complete (drain)");
  endtask

  // Cancel subordinate Bs that will never be answered (used after the W-bound
  // test, where the subordinate deliberately withholds all B responses).
  task automatic b_purge();
    @(negedge clk);
    bfm_bq_id.delete();
    bfm_bq_t.delete();
  endtask

  // ===========================================================================
  // MAIN CHECKER
  // ===========================================================================
  always @(posedge clk) begin
    if (!rst_n) begin
      // X1: while reset is low the unit originates nothing (master port quiet
      // here, so s_bvalid/s_rvalid must be low too).
      if (m_awvalid) chk_fail("X1", "m_awvalid asserted during reset");
      if (m_wvalid)  chk_fail("X1", "m_wvalid asserted during reset");
      if (s_bvalid)  chk_fail("X1", "response originated during reset (B)");
      if (s_rvalid)  chk_fail("X1", "response originated during reset (R)");
      debt_aw = 0; debt_wl = 0;
    end else begin
      // F1: m_awatop must be zero whenever m_awvalid is high
      if (m_awvalid && (m_awatop != 6'b0))
        chk_fail("F1", "m_awatop nonzero while m_awvalid");

      // ---- slave-side handshakes: build the expected model ----
      if (s_awvalid && s_awready) begin
        if (s_awatop[5:4] == 2'b00) begin
          // C1: non-atomic -> must be forwarded unmodified (P1)
          exp_aw.push_back({s_awid,s_awaddr,s_awlen,s_awsize,s_awburst,s_awlock,
                            s_awcache,s_awprot,s_awqos,s_awregion,s_awuser});
        end else begin
          // filtered write: owes one B (F3) ...
          exp_b_cnt[s_awid] = exp_b_cnt[s_awid] + 1;
          // ... and awlen+1 R beats iff C2 (F4/F5)
          if (s_awatop[5]) exp_r_cnt[s_awid] = exp_r_cnt[s_awid] + int'(s_awlen) + 1;
        end
      end
      if (s_arvalid && s_arready)
        exp_ar.push_back({s_arid,s_araddr,s_arlen,s_arsize,s_arburst,s_arlock,
                          s_arcache,s_arprot,s_arqos,s_arregion,s_aruser});
      if (s_wvalid && s_wready) begin
        if (w_offered.size() == 0) begin
          chk_fail("P2", "unexpected slave W handshake");
        end else begin
          w_e = w_offered.pop_front();
          if (w_e[0] == 1'b0)   // belongs to a forwarded write -> expect it on m
            exp_w.push_back({w_e[37:6], w_e[5:2], w_e[1], 1'b0});
          // filtered: consumed, never forwarded (F2)
        end
      end

      // ---- master-side handshakes: verify against the model ----
      if (m_awvalid && m_awready) begin
        if (exp_aw.size() == 0) begin
          chk_fail("F1", "AW forwarded with none expected (atomic leaked?)");
        end else begin
          q_e = exp_aw.pop_front();
          if (q_e !== {m_awid,m_awaddr,m_awlen,m_awsize,m_awburst,m_awlock,
                       m_awcache,m_awprot,m_awqos,m_awregion,m_awuser})
            chk_fail("P1", "forwarded AW fields modified");
        end
        debt_aw = debt_aw + 1;
      end
      if (m_arvalid && m_arready) begin
        if (exp_ar.size() == 0) begin
          chk_fail("P3", "AR forwarded with none expected");
        end else begin
          q_e = exp_ar.pop_front();
          if (q_e !== {m_arid,m_araddr,m_arlen,m_arsize,m_arburst,m_arlock,
                       m_arcache,m_arprot,m_arqos,m_arregion,m_aruser})
            chk_fail("P3", "AR forwarded modified");
        end
      end
      if (m_wvalid && m_wready) begin
        if (exp_w.size() == 0) begin
          chk_fail("F2", "W beat forwarded with none expected");
        end else begin
          q_w = exp_w.pop_front();
          if (q_w !== {m_wdata,m_wstrb,m_wlast,m_wuser})
            chk_fail("P2", "W beat forwarded modified");
        end
        if (m_wlast) debt_wl = debt_wl + 1;
      end
      // W2: downstream write debt never exceeds 4
      if (debt_aw - debt_wl > 4)
        chk_fail("W2", "downstream write debt exceeded MAX_WRITE_TXNS");

      // ---- B channel ----
      if (m_bvalid && m_bready) exp_pb.push_back(m_bid);
      if (s_bvalid && s_bready) begin
        if (s_bresp == 2'b10) begin
          if (exp_b_cnt[s_bid] == 0) begin
            chk_fail("F3", "unexpected manufactured B response");
          end else begin
            exp_b_cnt[s_bid] = exp_b_cnt[s_bid] - 1;
          end
        end else if (s_bresp == 2'b00) begin
          if (exp_pb.size() == 0) begin
            chk_fail("P4/F3", "unexpected OKAY B response");
          end else begin
            if (exp_pb.pop_front() != s_bid) chk_fail("P4", "pass-through B id mismatch");
            if (s_buser != 1'b0) chk_fail("P4", "pass-through B user modified");
          end
        end else begin
          chk_fail("P4/F3", "unexpected s_bresp value");
        end
      end

      // ---- R channel ----
      if (m_rvalid && m_rready) exp_pr.push_back({m_rid,m_rdata,m_rlast,m_ruser});
      if (s_rvalid && s_rready) begin
        if (s_rresp == 2'b10) begin
          // attribute by rid (F4): never by arrival order
          n_r = exp_r_cnt[s_rid];
          if (n_r == 0) begin
            chk_fail("F4/F5", "unexpected manufactured R beat");
          end else begin
            if (s_rlast != (n_r == 1))
              chk_fail("F4", "s_rlast placement wrong on manufactured R");
            exp_r_cnt[s_rid] = n_r - 1;
          end
        end else if (s_rresp == 2'b00) begin
          if (exp_pr.size() == 0) begin
            chk_fail("P3", "unexpected pass-through R beat");
          end else begin
            q_w = exp_pr.pop_front();
            if (q_w !== {s_rid,s_rdata,s_rlast,s_ruser})
              chk_fail("P3", "pass-through R beat modified");
          end
        end else begin
          chk_fail("P3/F4", "unexpected s_rresp value");
        end
      end
    end
  end

  // ===========================================================================
  // X3: valid held means valid and payload held, until ready
  // ===========================================================================
  always @(posedge clk) begin
    if (rst_n) begin
      if (st_maw) begin
        if (!m_awvalid) chk_fail("X3", "m_awvalid deasserted before ready");
        else if (pv_maw !== {m_awid,m_awaddr,m_awlen,m_awsize,m_awburst,m_awlock,
                             m_awcache,m_awprot,m_awqos,m_awregion,m_awatop,m_awuser})
          chk_fail("X3", "m_aw payload unstable while stalled");
      end
      if (st_mw) begin
        if (!m_wvalid) chk_fail("X3", "m_wvalid deasserted before ready");
        else if (pv_mw !== {m_wdata,m_wstrb,m_wlast,m_wuser})
          chk_fail("X3", "m_w payload unstable while stalled");
      end
      if (st_mb) begin
        if (!s_bvalid) chk_fail("X3", "s_bvalid deasserted before ready");
        else if (pv_mb !== {s_bid,s_bresp,s_buser})
          chk_fail("X3", "s_b payload unstable while stalled");
      end
      if (st_mr) begin
        if (!s_rvalid) chk_fail("X3", "s_rvalid deasserted before ready");
        else if (pv_mr !== {s_rid,s_rdata,s_rresp,s_rlast,s_ruser})
          chk_fail("X3", "s_r payload unstable while stalled");
      end
      if (st_mar) begin
        if (!m_arvalid) chk_fail("X3", "m_arvalid deasserted before ready");
        else if (pv_mar !== {m_arid,m_araddr,m_arlen,m_arsize,m_arburst,m_arlock,
                             m_arcache,m_arprot,m_arqos,m_arregion,m_aruser})
          chk_fail("X3", "m_ar payload unstable while stalled");
      end
    end
    st_maw <= rst_n & m_awvalid & ~m_awready;
    pv_maw <= {m_awid,m_awaddr,m_awlen,m_awsize,m_awburst,m_awlock,
               m_awcache,m_awprot,m_awqos,m_awregion,m_awatop,m_awuser};
    st_mw  <= rst_n & m_wvalid  & ~m_wready;
    pv_mw  <= {m_wdata,m_wstrb,m_wlast,m_wuser};
    st_mb  <= rst_n & s_bvalid & ~s_bready;
    pv_mb  <= {s_bid,s_bresp,s_buser};
    st_mr  <= rst_n & s_rvalid & ~s_rready;
    pv_mr  <= {s_rid,s_rdata,s_rresp,s_rlast,s_ruser};
    st_mar <= rst_n & m_arvalid & ~m_arready;
    pv_mar <= {m_arid,m_araddr,m_arlen,m_arsize,m_arburst,m_arlock,
               m_arcache,m_arprot,m_arqos,m_arregion,m_aruser};
  end

  // ===========================================================================
  // STIMULUS
  // ===========================================================================
  initial begin
    int i;
    fail    = 1'b0;
    debt_aw = 0; debt_wl = 0;
    for (i = 0; i < 16; i++) begin
      exp_b_cnt[i] = 0;
      exp_r_cnt[i] = 0;
    end
    st_maw = 1'b0; st_mw = 1'b0; st_mb = 1'b0; st_mr = 1'b0; st_mar = 1'b0;
  end

  initial begin
    bit acc;
    bit got13;

    bfm_reset(5);
    repeat (3) @(posedge clk);

    // T1: plain non-atomic write, burst of 4 (P1/P2/P4)
    do_write(4'd0, 8'd3, 6'h00);
    drain(1000);

    // T2: C1 -- atop[3:0] nonzero but atop[5:4]==0: NOT atomic, pass through
    do_write(4'd1, 8'd1, 6'h0F);
    drain(1000);

    // T3: C1/C2 -- atomic without read response ([5:4]=01, [3:0]=F): F2/F3/F5
    do_write(4'd2, 8'd2, 6'h2F);
    drain(1000);

    // T4: atomic with read response ([5:4]=10), 2 R beats (F4)
    do_write(4'd3, 8'd1, 6'h42);
    drain(1000);

    // T5: atomic with read response ([5:4]=11), 5 R beats (F4)
    do_write(4'd4, 8'd4, 6'h33);
    drain(1000);

    // T6: read pass-through (P3)
    bfm_ar(4'd5, 32'h0000_2000, 8'd2, 128, acc);
    if (!acc) chk_fail("P3/X4", "AR not accepted");
    drain(1000);

    // T7: concurrency + backpressure (X3, F4 attribution by rid)
    bfm_aw(4'd6, 32'h0000_3000, 8'd3, 6'h45, 128, acc);
    if (!acc) chk_fail("X4", "atomic AW6 not accepted");
    bfm_b_ready(0); bfm_r_ready(0);          // stall owed responses
    repeat (10) @(posedge clk);
    bfm_b_ready(1); bfm_r_ready(1);
    repeat (2) @(posedge clk);
    bfm_aw(4'd7, 32'h0000_3004, 8'd0, 6'h00, 128, acc);
    if (!acc) chk_fail("X4", "AW7 not accepted");
    bfm_ar(4'd8, 32'h0000_3008, 8'd1, 128, acc);
    if (!acc) chk_fail("P3/X4", "AR8 not accepted");
    bfm_b_ready(0); bfm_r_ready(0);          // stall pass-through and owed beats
    repeat (10) @(posedge clk);
    bfm_b_ready(1); bfm_r_ready(1);
    repeat (2) @(posedge clk);
    offer_w(32'hC000_0600, 1'b0, 1'b1);     // filtered write 6: 4 beats
    offer_w(32'hC000_0601, 1'b0, 1'b1);
    offer_w(32'hC000_0602, 1'b0, 1'b1);
    offer_w(32'hC000_0603, 1'b1, 1'b1);
    offer_w(32'hC000_0700, 1'b1, 1'b0);     // forwarded write 7: 1 beat
    bfm_b_ready(0);                          // stall the pass-through B too
    repeat (10) @(posedge clk);
    bfm_b_ready(1);
    drain(1000);

    // T8: the outstanding-write bound (W2/W3/W4). Subordinate never answers B,
    // so only W-burst completion may release the bound.
    bfm_dn_b_lag(1_000_000);
    bfm_aw(4'd9,  32'h0000_4000, 8'd0, 6'h00, 128, acc);
    if (!acc) chk_fail("W3/X4", "AW9 not accepted while debt below bound");
    bfm_aw(4'd10, 32'h0000_4004, 8'd0, 6'h00, 128, acc);
    if (!acc) chk_fail("W3/X4", "AW10 not accepted while debt below bound");
    bfm_aw(4'd11, 32'h0000_4008, 8'd0, 6'h00, 128, acc);
    if (!acc) chk_fail("W3/X4", "AW11 not accepted while debt below bound");
    bfm_aw(4'd12, 32'h0000_400C, 8'd0, 6'h00, 128, acc);
    if (!acc) chk_fail("W3/X4", "AW12 not accepted while debt below bound");
    // debt is now 4: a further AW may legally stall; try briefly either way
    bfm_aw(4'd13, 32'h0000_4010, 8'd0, 6'h00, 40, got13);
    // complete bursts; only a wlast releases debt (W4), never a B
    offer_w(32'hD000_0900, 1'b1, 1'b0);
    offer_w(32'hD000_0A00, 1'b1, 1'b0);
    offer_w(32'hD000_0B00, 1'b1, 1'b0);
    offer_w(32'hD000_0C00, 1'b1, 1'b0);
    // debt is strictly below 4 now: W3 requires acceptance
    bfm_aw(4'd14, 32'h0000_4014, 8'd0, 6'h00, 128, acc);
    if (!acc) chk_fail("W3/X4", "AW not accepted while debt below bound");
    if (got13) offer_w(32'hD000_0D00, 1'b1, 1'b0);
    offer_w(32'hD000_0E00, 1'b1, 1'b0);
    b_purge();                               // cancel the withheld Bs
    bfm_dn_b_lag(0);
    drain(2000);

    // T9: X1/X2 -- reset mid-run, then behaviour must not depend on the past
    bfm_reset(5);
    repeat (3) @(posedge clk);
    do_write(4'd15, 8'd0, 6'h00);
    do_write(4'd0, 8'd1, 6'h21);             // filtered, no read owed (F5)
    drain(1000);

    if (fail) $display("RESULT: FAIL");
    else     $display("RESULT: PASS");
    $finish;
  end

endmodule
