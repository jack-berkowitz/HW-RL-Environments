module atop_filter_tb;

// ---------------------------------------------------------------------------
// PROVIDED PLUMBING -- with a small injection hook added for reset testing.
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

  // Injection hooks (used only by the reset test).
  logic inj_bvalid = 1'b0;
  logic [3:0] inj_bid = '0;
  logic [1:0] inj_bresp = '0;
  logic inj_buser = '0;
  logic inj_rvalid = 1'b0;
  logic [3:0] inj_rid = '0;
  logic [31:0] inj_rdata = '0;
  logic [1:0] inj_rresp = '0;
  logic inj_rlast = 1'b0;
  logic inj_ruser = '0;

  atop_filter #(.ID_W(4), .ADDR_W(32), .DATA_W(32), .USER_W(1)) dut (
    .clk_i(clk), .rst_ni(rst_n),
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
    .s_rlast_o(s_rlast), .s_ruser_o(s_ruser),
    .s_rvalid_o(s_rvalid), .s_rready_i(s_rready),
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
    .m_rlast_i(m_rlast), .m_ruser_i(m_ruser),
    .m_rvalid_i(m_rvalid), .m_rready_o(m_rready));

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
      if (m_bvalid && m_bready && bfm_bq_id.size() > 0) begin
        void'(bfm_bq_id.pop_front()); void'(bfm_bq_t.pop_front());
      end
      if (m_rvalid && m_rready && bfm_rq_id.size() > 0) begin
        if (bfm_rq_n[0] <= 1) begin void'(bfm_rq_id.pop_front()); void'(bfm_rq_n.pop_front()); end
        else bfm_rq_n[0] = bfm_rq_n[0] - 1;
      end
    end
  end
  always_comb begin
    if (inj_bvalid) begin
      m_bvalid = 1'b1; m_bid = inj_bid; m_bresp = inj_bresp; m_buser = inj_buser;
    end else begin
      m_bvalid = (bfm_bq_id.size() > 0) && (bfm_cycle >= bfm_bq_t[0]);
      m_bid    = 4'(bfm_bq_id.size() ? bfm_bq_id[0] : 0);
      m_bresp  = 2'b00;
      m_buser  = 1'b0;
    end
    if (inj_rvalid) begin
      m_rvalid = 1'b1; m_rid = inj_rid; m_rdata = inj_rdata;
      m_rresp = inj_rresp; m_rlast = inj_rlast; m_ruser = inj_ruser;
    end else begin
      m_rvalid = (bfm_rq_id.size() > 0);
      m_rid    = 4'(bfm_rq_id.size() ? bfm_rq_id[0] : 0);
      m_rdata  = 32'hFEED_0000 + 32'(bfm_rq_n.size() ? bfm_rq_n[0] : 0);
      m_rresp  = 2'b00;
      m_ruser  = 1'b0;
      m_rlast  = (bfm_rq_id.size() > 0) && (bfm_rq_n[0] <= 1);
    end
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
    $display("RESULT: FAIL (watchdog)");
    $finish;
  end

// ===========================================================================
// MY TESTBENCH
// ===========================================================================
  bit fail_flag = 0;

  task automatic fail_msg(input string msg);
    $display("FAIL: %s", msg);
    fail_flag = 1;
  endtask

  // -------- master-port AW monitor --------
  int m_aw_seen_id[$];
  logic [31:0] m_aw_seen_addr[$];
  logic [7:0]  m_aw_seen_len[$];
  logic [5:0]  m_aw_seen_atop[$];
  logic [2:0]  m_aw_seen_size[$];
  logic [1:0]  m_aw_seen_burst[$];
  always @(posedge clk) if (rst_n && m_awvalid && m_awready) begin
    m_aw_seen_id.push_back(int'(m_awid));
    m_aw_seen_addr.push_back(m_awaddr);
    m_aw_seen_len.push_back(m_awlen);
    m_aw_seen_atop.push_back(m_awatop);
    m_aw_seen_size.push_back(m_awsize);
    m_aw_seen_burst.push_back(m_awburst);
  end

  // -------- master-port W monitor --------
  logic [31:0] m_w_seen_data[$];
  logic [3:0]  m_w_seen_strb[$];
  logic        m_w_seen_last[$];
  always @(posedge clk) if (rst_n && m_wvalid && m_wready) begin
    m_w_seen_data.push_back(m_wdata);
    m_w_seen_strb.push_back(m_wstrb);
    m_w_seen_last.push_back(m_wlast);
  end

  // -------- master-port AR monitor --------
  int m_ar_seen_id[$];
  logic [31:0] m_ar_seen_addr[$];
  logic [7:0]  m_ar_seen_len[$];
  always @(posedge clk) if (rst_n && m_arvalid && m_arready) begin
    m_ar_seen_id.push_back(int'(m_arid));
    m_ar_seen_addr.push_back(m_araddr);
    m_ar_seen_len.push_back(m_arlen);
  end

  // -------- slave-port B monitor --------
  int s_b_seen_id[$];
  logic [1:0] s_b_seen_resp[$];
  always @(posedge clk) if (rst_n && s_bvalid && s_bready) begin
    s_b_seen_id.push_back(int'(s_bid));
    s_b_seen_resp.push_back(s_bresp);
  end

  // -------- slave-port R monitor --------
  int s_r_seen_id[$];
  logic [1:0] s_r_seen_resp[$];
  logic s_r_seen_last[$];
  always @(posedge clk) if (rst_n && s_rvalid && s_rready) begin
    s_r_seen_id.push_back(int'(s_rid));
    s_r_seen_resp.push_back(s_rresp);
    s_r_seen_last.push_back(s_rlast);
  end

  // -------- downstream write debt (W1) --------
  int debt = 0;
  always @(posedge clk) begin
    if (!rst_n) begin
      debt <= 0;
    end else begin
      automatic logic inc = m_awvalid && m_awready;
      automatic logic dec = m_wvalid && m_wready && m_wlast;
      if (debt + inc - dec > 4)
        fail_msg($sformatf("W2: debt would be %0d (>4)", debt + inc - dec));
      debt <= debt + inc - dec;
    end
  end

  // -------- helper tasks --------
  task automatic clear_m_aw_queue();
    m_aw_seen_id.delete(); m_aw_seen_addr.delete(); m_aw_seen_len.delete();
    m_aw_seen_atop.delete(); m_aw_seen_size.delete(); m_aw_seen_burst.delete();
  endtask

  task automatic clear_m_w_queue();
    m_w_seen_data.delete(); m_w_seen_strb.delete(); m_w_seen_last.delete();
  endtask

  task automatic clear_all();
    clear_m_aw_queue(); clear_m_w_queue();
    m_ar_seen_id.delete(); m_ar_seen_addr.delete(); m_ar_seen_len.delete();
    s_b_seen_id.delete(); s_b_seen_resp.delete();
    s_r_seen_id.delete(); s_r_seen_resp.delete(); s_r_seen_last.delete();
  endtask

  task automatic wait_quiet(input int max_cycles);
    int t;
    for (t = 0; t < max_cycles; t++) begin
      @(negedge clk);
      if (!s_awvalid && !s_wvalid && !s_arvalid &&
          !m_awvalid && !m_wvalid && !m_arvalid &&
          !s_bvalid && !s_rvalid) break;
    end
  endtask

  task automatic wait_b_resp(input int id, input logic [1:0] exp_resp,
                             input int timeout, output bit found);
    int t, i;
    found = 0;
    for (t = 0; t < timeout; t++) begin
      @(negedge clk);
      for (i = 0; i < s_b_seen_id.size(); i++) begin
        if (s_b_seen_id[i] == id) begin
          if (s_b_seen_resp[i] !== exp_resp)
            fail_msg($sformatf("B resp id=%0d got %b exp %b",
                               id, s_b_seen_resp[i], exp_resp));
          s_b_seen_id.delete(i);
          s_b_seen_resp.delete(i);
          found = 1;
          break;
        end
      end
      if (found) break;
    end
    if (!found) fail_msg($sformatf("B timeout id=%0d", id));
  endtask

  task automatic wait_r_beats(input int id, input int n_beats,
                              input logic [1:0] exp_resp, input int timeout,
                              output bit ok);
    int t, i, seen;
    bit last_seen, got_one;
    ok = 0; seen = 0; last_seen = 0;
    for (t = 0; t < timeout; t++) begin
      @(negedge clk);
      got_one = 1;
      while (got_one) begin
        got_one = 0;
        for (i = 0; i < s_r_seen_id.size(); i++) begin
          if (s_r_seen_id[i] == id) begin
            seen = seen + 1;
            if (s_r_seen_resp[i] !== exp_resp)
              fail_msg($sformatf("R resp id=%0d beat %0d got %b exp %b",
                                 id, seen, s_r_seen_resp[i], exp_resp));
            if (s_r_seen_last[i]) begin
              if (seen == n_beats) last_seen = 1;
              else fail_msg($sformatf("R rlast early id=%0d beat %0d", id, seen));
            end
            s_r_seen_id.delete(i);
            s_r_seen_resp.delete(i);
            s_r_seen_last.delete(i);
            got_one = 1;
            break;
          end
        end
      end
      if (seen == n_beats && last_seen) begin ok = 1; break; end
      if (seen > n_beats) begin
        fail_msg($sformatf("R too many beats id=%0d", id));
        break;
      end
    end
    if (!ok) begin
      if (seen != n_beats) fail_msg($sformatf("R count id=%0d got %0d exp %0d", id, seen, n_beats));
      else fail_msg($sformatf("R rlast missing id=%0d", id));
    end
  endtask

  task automatic check_no_r_for_id(input int id, input int cycles);
    int t, i;
    for (t = 0; t < cycles; t++) begin
      @(negedge clk);
      i = 0;
      while (i < s_r_seen_id.size()) begin
        if (s_r_seen_id[i] == id) begin
          fail_msg($sformatf("F5: unexpected R beat for id=%0d", id));
          s_r_seen_id.delete(i);
          s_r_seen_resp.delete(i);
          s_r_seen_last.delete(i);
        end else i = i + 1;
      end
    end
  endtask

  // -------------------------------------------------------------------------
  // Test 1: non-atomic pass-through (P1, P2, P4, F1 awatop-zero)
  // -------------------------------------------------------------------------
  task automatic test_nonatomic_passthrough();
    int id = 1;
    bit acc, found;
    int t;

    wait_quiet(300);
    clear_all();

    bfm_aw(id, 32'hDEAD_BEEF, 8'd2, 6'b000101, 200, acc);
    if (!acc) begin fail_msg("P1: non-atomic AW not accepted"); return; end

    for (t = 0; t < 200; t++) begin
      @(negedge clk);
      if (m_aw_seen_id.size() > 0) break;
    end
    if (m_aw_seen_id.size() == 0) fail_msg("P1: non-atomic AW not forwarded");
    else begin
      if (m_aw_seen_id[0] !== id)             fail_msg("P1: id altered");
      if (m_aw_seen_addr[0] !== 32'hDEAD_BEEF) fail_msg("P1: addr altered");
      if (m_aw_seen_len[0] !== 8'd2)           fail_msg("P1: len altered");
      if (m_aw_seen_atop[0] !== 6'b000000)     fail_msg("F1: awatop not zeroed");
      if (m_aw_seen_size[0] !== 3'd2)          fail_msg("P1: size altered");
      if (m_aw_seen_burst[0] !== 2'd1)         fail_msg("P1: burst altered");
      clear_m_aw_queue();
    end

    bfm_w(32'hAAAA_1111, 4'h5, 1'b0, 200, acc); if (!acc) fail_msg("P2: W1");
    bfm_w(32'hBBBB_2222, 4'hA, 1'b0, 200, acc); if (!acc) fail_msg("P2: W2");
    bfm_w(32'hCCCC_3333, 4'hF, 1'b1, 200, acc); if (!acc) fail_msg("P2: W3");

    for (t = 0; t < 200; t++) begin
      @(negedge clk);
      if (m_w_seen_data.size() >= 3) break;
    end
    if (m_w_seen_data.size() < 3) fail_msg("P2: W beats not forwarded");
    else begin
      if (m_w_seen_data[0] !== 32'hAAAA_1111) fail_msg("P2: W1 data");
      if (m_w_seen_strb[0] !== 4'h5)          fail_msg("P2: W1 strb");
      if (m_w_seen_last[0])                   fail_msg("P2: W1 last");
      if (m_w_seen_data[1] !== 32'hBBBB_2222) fail_msg("P2: W2 data");
      if (m_w_seen_last[1])                   fail_msg("P2: W2 last");
      if (m_w_seen_data[2] !== 32'hCCCC_3333) fail_msg("P2: W3 data");
      if (!m_w_seen_last[2])                  fail_msg("P2: W3 last");
      clear_m_w_queue();
    end

    wait_b_resp(id, 2'b00, 300, found);
    if (!found) fail_msg("P4: pass-through B missing");

    wait_quiet(300);
    clear_all();
  endtask

  // -------------------------------------------------------------------------
  // Test 2: atomic without R (C1, C2, F1, F2, F3, F5)
  // -------------------------------------------------------------------------
  task automatic test_atomic_no_r();
    int id = 2;
    bit acc, found;
    int t, i;

    wait_quiet(300);
    clear_all();

    bfm_aw(id, 32'h2000, 8'd0, 6'b010000, 200, acc);
    if (!acc) begin fail_msg("C1: atomic AW not accepted"); return; end

    bfm_w(32'hA5A5_0001, 4'hF, 1'b1, 200, acc);
    if (!acc) fail_msg("F2: filtered W not consumed");

    // no W should be forwarded
    for (t = 0; t < 50; t++) @(negedge clk);
    if (m_w_seen_data.size() > 0) fail_msg("F2: filtered W forwarded to master");

    wait_b_resp(id, 2'b10, 300, found);
    if (!found) fail_msg("F3: no SLVERR B for filtered write");

    check_no_r_for_id(id, 100);

    for (i = 0; i < m_aw_seen_id.size(); i++)
      if (m_aw_seen_id[i] == id) fail_msg("F1: atomic AW forwarded");

    wait_quiet(300);
    clear_all();
  endtask

  // -------------------------------------------------------------------------
  // Test 3: atomic with R, awlen=3 (C2, F4)
  // -------------------------------------------------------------------------
  task automatic test_atomic_with_r();
    int id = 3;
    bit acc, found;
    int t, i;

    wait_quiet(300);
    clear_all();

    bfm_aw(id, 32'h3000, 8'd3, 6'b100000, 200, acc);
    if (!acc) begin fail_msg("C1: atomic-with-R AW not accepted"); return; end

    bfm_w(32'h1111_0001, 4'hF, 1'b0, 200, acc); if (!acc) fail_msg("F2: W0");
    bfm_w(32'h1111_0002, 4'hF, 1'b0, 200, acc); if (!acc) fail_msg("F2: W1");
    bfm_w(32'h1111_0003, 4'hF, 1'b0, 200, acc); if (!acc) fail_msg("F2: W2");
    bfm_w(32'h1111_0004, 4'hF, 1'b1, 200, acc); if (!acc) fail_msg("F2: W3");

    wait_b_resp(id, 2'b10, 300, found);
    if (!found) fail_msg("F3: B missing for atomic-with-R");

    wait_r_beats(id, 4, 2'b10, 300, found);
    if (!found) fail_msg("F4: R beats wrong for awlen=3");

    for (t = 0; t < 50; t++) @(negedge clk);
    if (m_w_seen_data.size() > 0) fail_msg("F2: filtered W forwarded");
    for (i = 0; i < m_aw_seen_id.size(); i++)
      if (m_aw_seen_id[i] == id) fail_msg("F1: atomic AW forwarded");

    wait_quiet(300);
    clear_all();
  endtask

  // -------------------------------------------------------------------------
  // Test 4: C1 -- awatop[3:0] does not affect classification
  // -------------------------------------------------------------------------
  task automatic test_atop_low_bits();
    int id;
    bit acc, found;
    int t, i;

    // awatop[5:4]=01 with nonzero [3:0] -> atomic without R
    wait_quiet(300); clear_all();
    id = 4;
    bfm_aw(id, 32'h4000, 8'd0, 6'b011111, 200, acc);
    if (!acc) begin fail_msg("C1: AW 011111 not accepted"); return; end
    bfm_w(32'h4444_4444, 4'hF, 1'b1, 200, acc);
    if (!acc) fail_msg("C1: W not accepted");
    wait_b_resp(id, 2'b10, 300, found);
    if (!found) fail_msg("C1: awatop=011111 not treated atomic (no B)");
    check_no_r_for_id(id, 100);
    for (i = 0; i < m_aw_seen_id.size(); i++)
      if (m_aw_seen_id[i] == id) fail_msg("C1: awatop=011111 forwarded");
    wait_quiet(300); clear_all();

    // awatop[5:4]=10 with nonzero [3:0] -> atomic with R
    id = 5;
    bfm_aw(id, 32'h4100, 8'd1, 6'b101111, 200, acc);
    if (!acc) begin fail_msg("C1: AW 101111 not accepted"); return; end
    bfm_w(32'h5555_0001, 4'hF, 1'b0, 200, acc);
    bfm_w(32'h5555_0002, 4'hF, 1'b1, 200, acc);
    wait_b_resp(id, 2'b10, 300, found);
    if (!found) fail_msg("C1: awatop=101111 not treated atomic");
    wait_r_beats(id, 2, 2'b10, 300, found);
    if (!found) fail_msg("C1: awatop=101111 missing R beats");
    wait_quiet(300); clear_all();
  endtask

  // -------------------------------------------------------------------------
  // Test 5: mixed in-flight -- attribute R beats by ID (F4, F5)
  // -------------------------------------------------------------------------
  task automatic test_mixed();
    int id_a = 6, id_b = 7, id_c = 8;
    bit acc, found;
    int t, i;

    wait_quiet(300);
    clear_all();

    // id_a: atomic with R, awlen=1 (2 R beats)
    bfm_aw(id_a, 32'h6000, 8'd1, 6'b100000, 200, acc);
    if (!acc) begin fail_msg("mixed: AW A not accepted"); return; end
    // id_b: atomic without R
    bfm_aw(id_b, 32'h6100, 8'd0, 6'b010000, 200, acc);
    if (!acc) begin fail_msg("mixed: AW B not accepted"); return; end
    // id_c: non-atomic (must pass through)
    bfm_aw(id_c, 32'h6200, 8'd0, 6'b000000, 200, acc);
    if (!acc) begin fail_msg("mixed: AW C not accepted"); return; end

    // W for all three
    bfm_w(32'hA0A0_0001, 4'hF, 1'b0, 200, acc);
    bfm_w(32'hA0A0_0002, 4'hF, 1'b1, 200, acc);
    bfm_w(32'hB0B0_0001, 4'hF, 1'b1, 200, acc);
    bfm_w(32'hC0C0_0001, 4'hF, 1'b1, 200, acc);

    wait_b_resp(id_a, 2'b10, 400, found); if (!found) fail_msg("mixed: B A");
    wait_b_resp(id_b, 2'b10, 400, found); if (!found) fail_msg("mixed: B B");
    wait_b_resp(id_c, 2'b00, 400, found); if (!found) fail_msg("mixed: B C");

    wait_r_beats(id_a, 2, 2'b10, 400, found);
    if (!found) fail_msg("mixed: R A");
    check_no_r_for_id(id_b, 50);

    // id_c should have been forwarded
    found = 0;
    for (i = 0; i < m_aw_seen_id.size(); i++)
      if (m_aw_seen_id[i] == id_c) found = 1;
    if (!found) fail_msg("mixed: non-atomic id_c not forwarded");
    for (i = 0; i < m_aw_seen_id.size(); i++) begin
      if (m_aw_seen_id[i] == id_a) fail_msg("mixed: atomic id_a forwarded");
      if (m_aw_seen_id[i] == id_b) fail_msg("mixed: atomic id_b forwarded");
    end

    wait_quiet(400);
    clear_all();
  endtask

  // -------------------------------------------------------------------------
  // Test 6: read pass-through (P3)
  // -------------------------------------------------------------------------
  task automatic test_read_passthrough();
    int id = 9;
    bit acc, found;
    int t;

    wait_quiet(300);
    clear_all();

    bfm_ar(id, 32'h9000, 8'd2, 200, acc);
    if (!acc) begin fail_msg("P3: AR not accepted"); return; end

    for (t = 0; t < 200; t++) begin
      @(negedge clk);
      if (m_ar_seen_id.size() > 0) break;
    end
    if (m_ar_seen_id.size() == 0) fail_msg("P3: AR not forwarded");
    else begin
      if (m_ar_seen_id[0] !== id)          fail_msg("P3: AR id altered");
      if (m_ar_seen_addr[0] !== 32'h9000)  fail_msg("P3: AR addr altered");
      if (m_ar_seen_len[0] !== 8'd2)       fail_msg("P3: AR len altered");
      m_ar_seen_id.delete(); m_ar_seen_addr.delete(); m_ar_seen_len.delete();
    end

    wait_r_beats(id, 3, 2'b00, 400, found);
    if (!found) fail_msg("P3: read R beats not returned");

    wait_quiet(300);
    clear_all();
  endtask

  // -------------------------------------------------------------------------
  // Test 7: outstanding-write bound (W1-W5)
  // -------------------------------------------------------------------------
  task automatic test_debt_bound();
    int id;
    bit acc;
    int t;

    wait_quiet(300);
    clear_all();

    bfm_dn_b_lag(100);          // delay B responses so W alone must free debt

    // 4 non-atomic AWs, no W -> debt rises to 4 (W3)
    for (int k = 0; k < 4; k++) begin
      id = 10 + k;
      bfm_aw(id, 32'hA000 + k*4, 8'd0, 6'b000000, 300, acc);
      if (!acc) begin
        fail_msg($sformatf("W3: AW%0d not accepted with debt<4", k));
        bfm_dn_b_lag(0);
        return;
      end
    end

    for (t = 0; t < 300; t++) begin
      @(negedge clk);
      if (m_aw_seen_id.size() >= 4) break;
    end
    if (m_aw_seen_id.size() < 4) fail_msg("W3: not all 4 AWs forwarded");
    clear_m_aw_queue();

    // Now complete 4 W bursts, no B yet.  Debt must drop on W, not B.
    for (int k = 0; k < 4; k++) begin
      bfm_w(32'hB000_0000 + k, 4'hF, 1'b1, 300, acc);
      if (!acc) begin
        fail_msg($sformatf("W: W burst %0d not accepted", k));
        bfm_dn_b_lag(0);
        return;
      end
    end

    // Debt is now 0 even though no B has returned.  AW5 must be accepted
    // within 64 cycles (X4).
    bfm_aw(14, 32'hB000, 8'd0, 6'b000000, 64, acc);
    if (!acc) fail_msg("W4/X4: AW5 not accepted within 64 cyc after W freed debt");

    // Clean up AW5's W so debt returns to zero.
    bfm_w(32'hC000_0000, 4'hF, 1'b1, 300, acc);

    bfm_dn_b_lag(0);
    wait_quiet(600);
    clear_all();
  endtask

  // -------------------------------------------------------------------------
  // Test 8: reset behaviour (X1)
  // -------------------------------------------------------------------------
  task automatic test_reset();
    int t;
    bit seen;

    wait_quiet(300);
    clear_all();

    @(negedge clk);
    rst_n = 1'b0;
    s_bready = 1'b0;
    s_rready = 1'b0;

    repeat (10) begin
      @(posedge clk);
      if (m_awvalid) fail_msg("X1: m_awvalid high during reset");
      if (m_wvalid)  fail_msg("X1: m_wvalid high during reset");
    end

    // Combinational pass-through of B while reset is asserted.
    @(negedge clk);
    inj_bvalid = 1'b1; inj_bid = 4'd7; inj_bresp = 2'b00; inj_buser = 1'b0;
    seen = 0;
    for (t = 0; t < 6; t++) begin
      @(posedge clk);
      if (s_bvalid && s_bid === 4'd7) begin seen = 1; break; end
    end
    if (!seen) fail_msg("X1: s_bvalid did not follow m_bvalid during reset");
    inj_bvalid = 1'b0;
    repeat (2) @(posedge clk);
    if (s_bvalid) fail_msg("X1: s_bvalid stuck after injection removed");

    // Combinational pass-through of R while reset is asserted.
    @(negedge clk);
    inj_rvalid = 1'b1; inj_rid = 4'd8; inj_rdata = 32'hDEAD_BEEF;
    inj_rresp = 2'b00; inj_rlast = 1'b1; inj_ruser = 1'b0;
    seen = 0;
    for (t = 0; t < 6; t++) begin
      @(posedge clk);
      if (s_rvalid && s_rid === 4'd8) begin seen = 1; break; end
    end
    if (!seen) fail_msg("X1: s_rvalid did not follow m_rvalid during reset");
    inj_rvalid = 1'b0;
    repeat (2) @(posedge clk);
    if (s_rvalid) fail_msg("X1: s_rvalid stuck after injection removed");

    // Release reset; no manufactured response should appear.
    @(negedge clk);
    rst_n = 1'b1;
    s_bready = 1'b1;
    s_rready = 1'b1;
    repeat (5) @(posedge clk);
    for (t = 0; t < 100; t++) begin
      @(posedge clk);
      if (s_bvalid) fail_msg("X1: manufactured B after reset with no traffic");
      if (s_rvalid) fail_msg("X1: manufactured R after reset with no traffic");
    end

    wait_quiet(300);
    clear_all();
  endtask

  // -------------------------------------------------------------------------
  // Main sequence
  // -------------------------------------------------------------------------
  initial begin
    bfm_reset(5);
    repeat (5) @(posedge clk);

    test_nonatomic_passthrough();
    if (fail_flag) begin $display("RESULT: FAIL"); $finish; end

    test_atomic_no_r();
    if (fail_flag) begin $display("RESULT: FAIL"); $finish; end

    test_atomic_with_r();
    if (fail_flag) begin $display("RESULT: FAIL"); $finish; end

    test_atop_low_bits();
    if (fail_flag) begin $display("RESULT: FAIL"); $finish; end

    test_mixed();
    if (fail_flag) begin $display("RESULT: FAIL"); $finish; end

    test_read_passthrough();
    if (fail_flag) begin $display("RESULT: FAIL"); $finish; end

    test_debt_bound();
    if (fail_flag) begin $display("RESULT: FAIL"); $finish; end

    test_reset();
    if (fail_flag) begin $display("RESULT: FAIL"); $finish; end

    $display("RESULT: PASS");
    $finish;
  end

endmodule
