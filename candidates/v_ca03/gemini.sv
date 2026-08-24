module id_width_conv_tb;

  localparam int SLV_ID_W        = 4;
  localparam int MST_ID_W        = 2;
  localparam int ADDR_W          = 32;
  localparam int DATA_W          = 32;
  localparam int MAX_UNIQ_IDS    = 4;
  localparam int MAX_TXNS_PER_ID = 2;

// ---------------------------------------------------------------------------
// PROVIDED PLUMBING -- moves transactions, checks nothing.
// ---------------------------------------------------------------------------

  logic clk;
  initial begin clk = 1'b0; forever #5 clk = ~clk; end

  logic rst_n;
  initial rst_n = 1'b0;

  // Asserted and released away from the sampling edge.
  task automatic bfm_reset(input int cycles = 4);
    @(negedge clk);
    rst_n = 1'b0;
    repeat (cycles) @(posedge clk);
    @(negedge clk);
    rst_n = 1'b1;
  endtask

  // The interface signals
  logic [SLV_ID_W-1:0]        s_awid;
  logic [ADDR_W-1:0]          s_awaddr;
  logic [7:0]                 s_awlen;
  logic                       s_awvalid;
  logic                       s_awready;

  logic [DATA_W-1:0]          s_wdata;
  logic [DATA_W/8-1:0]        s_wstrb;
  logic                       s_wlast;
  logic                       s_wvalid;
  logic                       s_wready;

  logic [SLV_ID_W-1:0]        s_bid;
  logic [1:0]                 s_bresp;
  logic                       s_bvalid;
  logic                       s_bready;

  logic [SLV_ID_W-1:0]        s_arid;
  logic [ADDR_W-1:0]          s_araddr;
  logic [7:0]                 s_arlen;
  logic                       s_arvalid;
  logic                       s_arready;

  logic [SLV_ID_W-1:0]        s_rid;
  logic [DATA_W-1:0]          s_rdata;
  logic [1:0]                 s_rresp;
  logic                       s_rlast;
  logic                       s_rvalid;
  logic                       s_rready;

  logic [MST_ID_W-1:0]        m_awid;
  logic [ADDR_W-1:0]          m_awaddr;
  logic [7:0]                 m_awlen;
  logic                       m_awvalid;
  logic                       m_awready;

  logic [DATA_W-1:0]          m_wdata;
  logic [DATA_W/8-1:0]        m_wstrb;
  logic                       m_wlast;
  logic                       m_wvalid;
  logic                       m_wready;

  logic [MST_ID_W-1:0]        m_bid;
  logic [1:0]                 m_bresp;
  logic                       m_bvalid;
  logic                       m_bready;

  logic [MST_ID_W-1:0]        m_arid;
  logic [ADDR_W-1:0]          m_araddr;
  logic [7:0]                 m_arlen;
  logic                       m_arvalid;
  logic                       m_arready;

  logic [MST_ID_W-1:0]        m_rid;
  logic [DATA_W-1:0]          m_rdata;
  logic [1:0]                 m_rresp;
  logic                       m_rlast;
  logic                       m_rvalid;
  logic                       m_rready;

  id_width_conv #(
    .SLV_ID_W(SLV_ID_W),
    .MST_ID_W(MST_ID_W),
    .ADDR_W(ADDR_W),
    .DATA_W(DATA_W),
    .MAX_UNIQ_IDS(MAX_UNIQ_IDS),
    .MAX_TXNS_PER_ID(MAX_TXNS_PER_ID)
  ) dut (
    .clk_i(clk), .rst_ni(rst_n),
    .s_awid(s_awid), .s_awaddr(s_awaddr), .s_awlen(s_awlen), .s_awvalid(s_awvalid), .s_awready(s_awready),
    .s_wdata(s_wdata), .s_wstrb(s_wstrb), .s_wlast(s_wlast), .s_wvalid(s_wvalid), .s_wready(s_wready),
    .s_bid(s_bid), .s_bresp(s_bresp), .s_bvalid(s_bvalid), .s_bready(s_bready),
    .s_arid(s_arid), .s_araddr(s_araddr), .s_arlen(s_arlen), .s_arvalid(s_arvalid), .s_arready(s_arready),
    .s_rid(s_rid), .s_rdata(s_rdata), .s_rresp(s_rresp), .s_rlast(s_rlast), .s_rvalid(s_rvalid), .s_rready(s_rready),
    .m_awid(m_awid), .m_awaddr(m_awaddr), .m_awlen(m_awlen), .m_awvalid(m_awvalid), .m_awready(m_awready),
    .m_wdata(m_wdata), .m_wstrb(m_wstrb), .m_wlast(m_wlast), .m_wvalid(m_wvalid), .m_wready(m_wready),
    .m_bid(m_bid), .m_bresp(m_bresp), .m_bvalid(m_bvalid), .m_bready(m_bready),
    .m_arid(m_arid), .m_araddr(m_araddr), .m_arlen(m_arlen), .m_arvalid(m_arvalid), .m_arready(m_arready),
    .m_rid(m_rid), .m_rdata(m_rdata), .m_rresp(m_rresp), .m_rlast(m_rlast), .m_rvalid(m_rvalid), .m_rready(m_rready)
  );

  task automatic bfm_ar(input  logic [SLV_ID_W-1:0] id,
                        input  logic [ADDR_W-1:0]   addr,
                        input  logic [7:0]          len,
                        input  int                  budget,
                        output bit                  accepted,
                        output int                  waited);
    accepted = 1'b0; waited = 0;
    @(negedge clk);
    s_arid = id; s_araddr = addr; s_arlen = len; s_arvalid = 1'b1;
    while (waited < budget) begin
      @(posedge clk);
      if (s_arready) begin accepted = 1'b1; break; end
      waited++;
    end
    @(negedge clk) s_arvalid = 1'b0;
  endtask

  task automatic bfm_aw(input  logic [SLV_ID_W-1:0] id,
                        input  logic [ADDR_W-1:0]   addr,
                        input  logic [7:0]          len,
                        input  int                  budget,
                        output bit                  accepted,
                        output int                  waited);
    accepted = 1'b0; waited = 0;
    @(negedge clk);
    s_awid = id; s_awaddr = addr; s_awlen = len; s_awvalid = 1'b1;
    while (waited < budget) begin
      @(posedge clk);
      if (s_awready) begin accepted = 1'b1; break; end
      waited++;
    end
    @(negedge clk) s_awvalid = 1'b0;
  endtask

  task automatic bfm_w(input logic [DATA_W-1:0]   data,
                       input logic [DATA_W/8-1:0] strb,
                       input logic                last);
    @(negedge clk);
    s_wdata = data; s_wstrb = strb; s_wlast = last; s_wvalid = 1'b1;
    forever begin @(posedge clk); if (s_wready) break; end
    @(negedge clk) s_wvalid = 1'b0;
  endtask

  task automatic bfm_rbeat(input logic [MST_ID_W-1:0] mid,
                           input logic [DATA_W-1:0]   data,
                           input logic                last);
    @(negedge clk);
    m_rid = mid; m_rdata = data; m_rlast = last; m_rresp = 2'b00; m_rvalid = 1'b1;
    forever begin @(posedge clk); if (m_rready) break; end
    @(negedge clk) m_rvalid = 1'b0;
  endtask

  task automatic bfm_bbeat(input logic [MST_ID_W-1:0] mid);
    @(negedge clk);
    m_bid = mid; m_bresp = 2'b00; m_bvalid = 1'b1;
    forever begin @(posedge clk); if (m_bready) break; end
    @(negedge clk) m_bvalid = 1'b0;
  endtask

  initial begin
    #4_000_000;
    $display("RESULT: FAIL (watchdog: no forward progress)");
    $finish;
  end

// ---------------------------------------------------------------------------
// TESTBENCH LOGIC
// ---------------------------------------------------------------------------

  int cycle_cnt = 0;
  always @(posedge clk) begin
    if (rst_n) cycle_cnt++;
  end

  // Monitor state structures
  int s_ar_count[16];
  bit ar_mst_in_use[4];
  logic [3:0] active_ar_slv_for_mst[4];
  int slv_ar_expected_m_ar[int];
  logic [7:0] slv_ar_len_by_addr[int];
  logic [3:0] slv_ar_req_by_addr[int];
  logic [3:0] expected_s_rid_for_mid[4];

  int s_aw_count[16];
  bit aw_mst_in_use[4];
  logic [3:0] active_aw_slv_for_mst[4];
  int slv_aw_expected_m_aw[int];
  logic [7:0] slv_aw_len_by_addr[int];
  logic [3:0] slv_aw_req_by_addr[int];
  logic [3:0] expected_s_bid_for_mid[4];

  typedef struct {
    logic [DATA_W-1:0] data;
    logic [DATA_W/8-1:0] strb;
    logic last;
  } wbeat_t;
  
  wbeat_t expected_m_w[$];

  typedef struct {
    logic [DATA_W-1:0] data;
    logic last;
    logic [3:0] expected_rid;
  } exp_r_t;
  
  exp_r_t expected_s_r_per_id[16][$];
  int expected_s_b_per_id[16][$];

  logic [1:0] mid_seq_for_slv_ar_3[$];
  logic [1:0] mid_seq_for_slv_aw_3[$];

  int id0_retire_time = -1;
  int id4_accept_time = -1;
  int id1_aw_retire_time = -1;
  int id4_aw_accept_time = -1;

  function automatic logic[1:0] get_mid_for_slv_ar(logic [3:0] sid);
    for (int i=0; i<4; i++) begin
      if (ar_mst_in_use[i] && active_ar_slv_for_mst[i] == sid) return i[1:0];
    end
    return 2'b00;
  endfunction

  function automatic logic[1:0] get_mid_for_slv_aw(logic [3:0] sid);
    for (int i=0; i<4; i++) begin
      if (aw_mst_in_use[i] && active_aw_slv_for_mst[i] == sid) return i[1:0];
    end
    return 2'b00;
  endfunction

  task automatic send_rbeat(logic [1:0] mid, logic [DATA_W-1:0] data, logic last);
    automatic exp_r_t r;
    automatic logic [3:0] sid;
    sid = expected_s_rid_for_mid[mid];
    r.data = data; r.last = last; r.expected_rid = sid;
    expected_s_r_per_id[sid].push_back(r);
    bfm_rbeat(mid, data, last);
  endtask

  task automatic send_bbeat(logic [1:0] mid);
    automatic logic [3:0] sid;
    sid = expected_s_bid_for_mid[mid];
    expected_s_b_per_id[sid].push_back(1);
    bfm_bbeat(mid);
  endtask

  // Passive Monitor logic
  always @(posedge clk) begin
    if (!rst_n) begin
      for (int i=0; i<16; i++) s_ar_count[i] = 0;
      for (int i=0; i<4; i++) begin
        ar_mst_in_use[i] = 0;
        active_ar_slv_for_mst[i] = 0;
      end
      slv_ar_expected_m_ar.delete();
      slv_ar_len_by_addr.delete();
      slv_ar_req_by_addr.delete();
      for (int i=0; i<16; i++) expected_s_r_per_id[i].delete();
      
      for (int i=0; i<16; i++) s_aw_count[i] = 0;
      for (int i=0; i<4; i++) begin
        aw_mst_in_use[i] = 0;
        active_aw_slv_for_mst[i] = 0;
      end
      slv_aw_expected_m_aw.delete();
      slv_aw_len_by_addr.delete();
      slv_aw_req_by_addr.delete();
      expected_m_w.delete();
      for (int i=0; i<16; i++) expected_s_b_per_id[i].delete();
      
      mid_seq_for_slv_ar_3.delete();
      mid_seq_for_slv_aw_3.delete();
      
      id0_retire_time = -1;
      id4_accept_time = -1;
      id1_aw_retire_time = -1;
      id4_aw_accept_time = -1;
    end else begin
      // AR channel
      if (s_arvalid && s_arready) begin
        slv_ar_req_by_addr[s_araddr] = s_arid;
        slv_ar_len_by_addr[s_araddr] = s_arlen;
        if (!slv_ar_expected_m_ar.exists(s_araddr)) slv_ar_expected_m_ar[s_araddr] = 0;
        slv_ar_expected_m_ar[s_araddr]++;
        s_ar_count[s_arid]++;
        
        if (s_arid == 4) id4_accept_time = cycle_cnt;
      end
      
      if (m_arvalid && m_arready) begin
        if (!slv_ar_expected_m_ar.exists(m_araddr) || slv_ar_expected_m_ar[m_araddr] == 0) begin
          $display("RESULT: FAIL (D4)"); $finish;
        end
        slv_ar_expected_m_ar[m_araddr]--;
        if (m_arlen !== slv_ar_len_by_addr[m_araddr]) begin
          $display("RESULT: FAIL (E1)"); $finish;
        end
        
        begin
          automatic logic [3:0] slv_id = slv_ar_req_by_addr[m_araddr];
          expected_s_rid_for_mid[m_arid] = slv_id;
          
          if (slv_id == 3) mid_seq_for_slv_ar_3.push_back(m_arid);
          
          if (ar_mst_in_use[m_arid]) begin
            if (active_ar_slv_for_mst[m_arid] != slv_id) begin
              $display("RESULT: FAIL (D1)"); $finish; 
            end
          end else begin
            ar_mst_in_use[m_arid] = 1;
            active_ar_slv_for_mst[m_arid] = slv_id;
          end
        end
      end
      
      // R channel
      if (s_rvalid && s_rready) begin
        if (expected_s_r_per_id[s_rid].size() == 0) begin
          $display("RESULT: FAIL (C2)"); $finish; 
        end
        begin
          automatic exp_r_t r;
          r = expected_s_r_per_id[s_rid].pop_front();
          if (r.data !== s_rdata || r.last !== s_rlast) begin
            $display("RESULT: FAIL (E1)"); $finish;
          end
        end
        
        if (s_rlast) begin
          s_ar_count[s_rid]--;
          if (s_ar_count[s_rid] == 0) begin
            for (int i=0; i<4; i++) begin
              if (ar_mst_in_use[i] && active_ar_slv_for_mst[i] == s_rid) begin
                ar_mst_in_use[i] = 0;
              end
            end
          end
          if (s_rid == 0) id0_retire_time = cycle_cnt;
        end
      end
      
      // AW channel
      if (s_awvalid && s_awready) begin
        slv_aw_req_by_addr[s_awaddr] = s_awid;
        slv_aw_len_by_addr[s_awaddr] = s_awlen;
        if (!slv_aw_expected_m_aw.exists(s_awaddr)) slv_aw_expected_m_aw[s_awaddr] = 0;
        slv_aw_expected_m_aw[s_awaddr]++;
        s_aw_count[s_awid]++;
        
        if (s_awid == 4) id4_aw_accept_time = cycle_cnt;
      end
      
      if (m_awvalid && m_awready) begin
        if (!slv_aw_expected_m_aw.exists(m_awaddr) || slv_aw_expected_m_aw[m_awaddr] == 0) begin
          $display("RESULT: FAIL (D4)"); $finish;
        end
        slv_aw_expected_m_aw[m_awaddr]--;
        if (m_awlen !== slv_aw_len_by_addr[m_awaddr]) begin
          $display("RESULT: FAIL (E1)"); $finish;
        end
        
        begin
          automatic logic [3:0] slv_id = slv_aw_req_by_addr[m_awaddr];
          expected_s_bid_for_mid[m_awid] = slv_id;
          
          if (slv_id == 3) mid_seq_for_slv_aw_3.push_back(m_awid);
          
          if (aw_mst_in_use[m_awid]) begin
            if (active_aw_slv_for_mst[m_awid] != slv_id) begin
              $display("RESULT: FAIL (D1)"); $finish; 
            end
          end else begin
            aw_mst_in_use[m_awid] = 1;
            active_aw_slv_for_mst[m_awid] = slv_id;
          end
        end
      end
      
      // W channel
      if (s_wvalid && s_wready) begin
        automatic wbeat_t w;
        w.data = s_wdata; w.strb = s_wstrb; w.last = s_wlast;
        expected_m_w.push_back(w);
      end
      if (m_wvalid && m_wready) begin
        if (expected_m_w.size() == 0) begin
          $display("RESULT: FAIL (D4)"); $finish; 
        end
        begin
          automatic wbeat_t w;
          w = expected_m_w.pop_front();
          if (w.data !== m_wdata || w.strb !== m_wstrb || w.last !== m_wlast) begin
            $display("RESULT: FAIL (B3)"); $finish; 
          end
        end
      end
      
      // B channel
      if (s_bvalid && s_bready) begin
        if (expected_s_b_per_id[s_bid].size() == 0) begin
          $display("RESULT: FAIL (C2)"); $finish; 
        end
        void'(expected_s_b_per_id[s_bid].pop_front());
        if (s_bresp !== 2'b00) begin
          $display("RESULT: FAIL (E1)"); $finish;
        end
        
        s_aw_count[s_bid]--;
        if (s_aw_count[s_bid] == 0) begin
          for (int i=0; i<4; i++) begin
            if (aw_mst_in_use[i] && active_aw_slv_for_mst[i] == s_bid) begin
              aw_mst_in_use[i] = 0;
            end
          end
        end
        if (s_bid == 1) id1_aw_retire_time = cycle_cnt;
      end
    end
  end

  logic [1:0] mid0, mid1_w;
  logic [1:0] mid_3_1, mid_3_2, mid_3_w_1, mid_3_w_2;
  
  initial begin
    automatic bit accepted;
    automatic int waited;

    s_arvalid = 0; s_awvalid = 0; s_wvalid = 0; m_rvalid = 0; m_bvalid = 0;
    s_bready = 1; s_rready = 1; m_awready = 1; m_arready = 1; m_wready = 1;

    bfm_reset(4);

    // F1 Test
    bfm_ar(10, 32'hA000, 0, 10, accepted, waited);
    bfm_aw(10, 32'hB000, 0, 10, accepted, waited);
    repeat(10) @(posedge clk);
    bfm_reset(4);

    // A2 Test on AR
    bfm_ar(0, 32'h1000, 0, 10, accepted, waited);
    if (!accepted) begin $display("RESULT: FAIL (A2)"); $finish; end
    bfm_ar(1, 32'h1010, 0, 10, accepted, waited);
    if (!accepted) begin $display("RESULT: FAIL (A2)"); $finish; end
    bfm_ar(2, 32'h1020, 0, 10, accepted, waited);
    if (!accepted) begin $display("RESULT: FAIL (A2)"); $finish; end
    bfm_ar(3, 32'h1030, 0, 10, accepted, waited);
    if (!accepted) begin $display("RESULT: FAIL (A2)"); $finish; end

    // A3 block Test on AR
    bfm_ar(4, 32'h1040, 0, 10, accepted, waited);
    if (accepted) begin $display("RESULT: FAIL (A3)"); $finish; end

    // A3 pass (existing ID)
    bfm_ar(3, 32'h1050, 0, 10, accepted, waited);
    if (!accepted) begin $display("RESULT: FAIL (A3)"); $finish; end

    // A5 block (max 2 per ID)
    bfm_ar(3, 32'h1060, 0, 10, accepted, waited);
    if (accepted) begin $display("RESULT: FAIL (A5)"); $finish; end

    repeat(20) @(posedge clk);
    mid0 = get_mid_for_slv_ar(0);

    // A4 Test on AR
    fork
      begin
        bfm_ar(4, 32'h1040, 0, 100, accepted, waited);
      end
      begin
        repeat(5) @(posedge clk);
        send_rbeat(mid0, 32'hD0D0D0D0, 1'b1);
      end
    join
    
    if (!accepted) begin $display("RESULT: FAIL (A4)"); $finish; end
    if (id4_accept_time < id0_retire_time) begin $display("RESULT: FAIL (A3)"); $finish; end
    if (id4_accept_time - id0_retire_time > 2) begin $display("RESULT: FAIL (A4)"); $finish; end

    // AW Tests
    bfm_aw(0, 32'h2000, 0, 10, accepted, waited); 
    bfm_aw(1, 32'h2010, 0, 10, accepted, waited); 
    bfm_aw(2, 32'h2020, 0, 10, accepted, waited); 
    bfm_aw(3, 32'h2030, 0, 10, accepted, waited); 

    bfm_aw(4, 32'h2040, 0, 10, accepted, waited);
    if (accepted) begin $display("RESULT: FAIL (A3)"); $finish; end

    bfm_aw(3, 32'h2050, 0, 10, accepted, waited);
    if (!accepted) begin $display("RESULT: FAIL (A3)"); $finish; end

    bfm_aw(3, 32'h2060, 0, 10, accepted, waited);
    if (accepted) begin $display("RESULT: FAIL (A5)"); $finish; end
    
    bfm_w(32'hA0, 4'hF, 1'b1);
    bfm_w(32'hA1, 4'hF, 1'b1);
    bfm_w(32'hA2, 4'hF, 1'b1);
    bfm_w(32'hA3, 4'hF, 1'b1);
    bfm_w(32'hA4, 4'hF, 1'b1);

    repeat(20) @(posedge clk);
    mid1_w = get_mid_for_slv_aw(1);

    fork
      begin
        bfm_aw(4, 32'h2040, 0, 100, accepted, waited);
      end
      begin
        repeat(5) @(posedge clk);
        send_bbeat(mid1_w);
      end
    join
    
    if (!accepted) begin $display("RESULT: FAIL (A4)"); $finish; end
    if (id4_aw_accept_time < id1_aw_retire_time) begin $display("RESULT: FAIL (A3)"); $finish; end
    if (id4_aw_accept_time - id1_aw_retire_time > 2) begin $display("RESULT: FAIL (A4)"); $finish; end
    
    bfm_w(32'hA5, 4'hF, 1'b1);

    // Finish everything
    repeat(20) @(posedge clk);
    mid_3_1 = mid_seq_for_slv_ar_3.pop_front();
    mid_3_2 = mid_seq_for_slv_ar_3.pop_front();
    send_rbeat(mid_3_1, 32'h3333_1111, 1'b1);
    send_rbeat(mid_3_2, 32'h3333_2222, 1'b1);
    send_rbeat(get_mid_for_slv_ar(1), 32'h1111_1111, 1'b1);
    send_rbeat(get_mid_for_slv_ar(2), 32'h2222_2222, 1'b1);
    send_rbeat(get_mid_for_slv_ar(4), 32'h4444_4444, 1'b1);

    mid_3_w_1 = mid_seq_for_slv_aw_3.pop_front();
    mid_3_w_2 = mid_seq_for_slv_aw_3.pop_front();
    send_bbeat(mid_3_w_1);
    send_bbeat(mid_3_w_2);
    send_bbeat(get_mid_for_slv_aw(0));
    send_bbeat(get_mid_for_slv_aw(2));
    send_bbeat(get_mid_for_slv_aw(4));

    begin
      automatic int timeout = 1000;
      while(timeout > 0) begin
        automatic bit all_done = 1;
        for (int i=0; i<16; i++) begin
          if (s_ar_count[i] > 0 || s_aw_count[i] > 0) all_done = 0;
        end
        if (all_done) break;
        @(posedge clk);
        timeout--;
      end
      if (timeout == 0) begin
        $display("RESULT: FAIL (G1)"); $finish; 
      end
    end
    
    $display("RESULT: PASS");
    $finish;
  end

endmodule