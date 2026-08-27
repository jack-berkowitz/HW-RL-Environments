module id_width_conv_tb;

  localparam int unsigned SLV_ID_W         = 4;
  localparam int unsigned MST_ID_W         = 2;
  localparam int unsigned ADDR_W           = 32;
  localparam int unsigned DATA_W           = 32;
  localparam int unsigned MAX_UNIQ_IDS     = 4;
  localparam int unsigned MAX_TXNS_PER_ID  = 2;

  localparam int MAX_RECS   = 96;
  localparam int LONG_WAIT  = 2000;

  // --------------------------------------------------------------------------
  // DUT port signals
  // --------------------------------------------------------------------------

  logic                    clk;
  logic                    rst_n;

  logic [SLV_ID_W-1:0]     s_awid;
  logic [ADDR_W-1:0]       s_awaddr;
  logic [7:0]              s_awlen;
  logic                    s_awvalid;
  logic                    s_awready;

  logic [DATA_W-1:0]       s_wdata;
  logic [DATA_W/8-1:0]     s_wstrb;
  logic                    s_wlast;
  logic                    s_wvalid;
  logic                    s_wready;

  logic [SLV_ID_W-1:0]     s_bid;
  logic [1:0]              s_bresp;
  logic                    s_bvalid;
  logic                    s_bready;

  logic [SLV_ID_W-1:0]     s_arid;
  logic [ADDR_W-1:0]       s_araddr;
  logic [7:0]              s_arlen;
  logic                    s_arvalid;
  logic                    s_arready;

  logic [SLV_ID_W-1:0]     s_rid;
  logic [DATA_W-1:0]       s_rdata;
  logic [1:0]              s_rresp;
  logic                    s_rlast;
  logic                    s_rvalid;
  logic                    s_rready;

  logic [MST_ID_W-1:0]     m_awid;
  logic [ADDR_W-1:0]       m_awaddr;
  logic [7:0]              m_awlen;
  logic                    m_awvalid;
  logic                    m_awready;

  logic [DATA_W-1:0]       m_wdata;
  logic [DATA_W/8-1:0]     m_wstrb;
  logic                    m_wlast;
  logic                    m_wvalid;
  logic                    m_wready;

  logic [MST_ID_W-1:0]     m_bid;
  logic [1:0]              m_bresp;
  logic                    m_bvalid;
  logic                    m_bready;

  logic [MST_ID_W-1:0]     m_arid;
  logic [ADDR_W-1:0]       m_araddr;
  logic [7:0]              m_arlen;
  logic                    m_arvalid;
  logic                    m_arready;

  logic [MST_ID_W-1:0]     m_rid;
  logic [DATA_W-1:0]       m_rdata;
  logic [1:0]              m_rresp;
  logic                    m_rlast;
  logic                    m_rvalid;
  logic                    m_rready;


  id_width_conv #(
      .SLV_ID_W         (SLV_ID_W),
      .MST_ID_W         (MST_ID_W),
      .ADDR_W           (ADDR_W),
      .DATA_W           (DATA_W),
      .MAX_UNIQ_IDS     (MAX_UNIQ_IDS),
      .MAX_TXNS_PER_ID  (MAX_TXNS_PER_ID)
  ) dut (
      .clk_i      (clk),
      .rst_ni     (rst_n),

      .s_awid     (s_awid),
      .s_awaddr   (s_awaddr),
      .s_awlen    (s_awlen),
      .s_awvalid  (s_awvalid),
      .s_awready  (s_awready),

      .s_wdata    (s_wdata),
      .s_wstrb    (s_wstrb),
      .s_wlast    (s_wlast),
      .s_wvalid   (s_wvalid),
      .s_wready   (s_wready),

      .s_bid      (s_bid),
      .s_bresp    (s_bresp),
      .s_bvalid   (s_bvalid),
      .s_bready   (s_bready),

      .s_arid     (s_arid),
      .s_araddr   (s_araddr),
      .s_arlen    (s_arlen),
      .s_arvalid  (s_arvalid),
      .s_arready  (s_arready),

      .s_rid      (s_rid),
      .s_rdata    (s_rdata),
      .s_rresp    (s_rresp),
      .s_rlast    (s_rlast),
      .s_rvalid   (s_rvalid),
      .s_rready   (s_rready),

      .m_awid     (m_awid),
      .m_awaddr   (m_awaddr),
      .m_awlen    (m_awlen),
      .m_awvalid  (m_awvalid),
      .m_awready  (m_awready),

      .m_wdata    (m_wdata),
      .m_wstrb    (m_wstrb),
      .m_wlast    (m_wlast),
      .m_wvalid   (m_wvalid),
      .m_wready   (m_wready),

      .m_bid      (m_bid),
      .m_bresp    (m_bresp),
      .m_bvalid   (m_bvalid),
      .m_bready   (m_bready),

      .m_arid     (m_arid),
      .m_araddr   (m_araddr),
      .m_arlen    (m_arlen),
      .m_arvalid  (m_arvalid),
      .m_arready  (m_arready),

      .m_rid      (m_rid),
      .m_rdata    (m_rdata),
      .m_rresp    (m_rresp),
      .m_rlast    (m_rlast),
      .m_rvalid   (m_rvalid),
      .m_rready   (m_rready)
  );


  // --------------------------------------------------------------------------
  // PROVIDED PLUMBING
  // --------------------------------------------------------------------------

  initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
  end

  initial rst_n = 1'b0;

  task automatic bfm_reset(input int cycles = 4);
    @(negedge clk);
    rst_n = 1'b0;
    repeat (cycles) @(posedge clk);
    @(negedge clk);
    rst_n = 1'b1;
  endtask

  task automatic bfm_ar(
      input  logic [SLV_ID_W-1:0] id,
      input  logic [ADDR_W-1:0]   addr,
      input  logic [7:0]          len,
      input  int                  budget,
      output bit                  accepted,
      output int                  waited
  );
    accepted = 1'b0;
    waited   = 0;
    @(negedge clk);
    s_arid    = id;
    s_araddr  = addr;
    s_arlen   = len;
    s_arvalid = 1'b1;
    while (waited < budget) begin
      @(posedge clk);
      if (s_arready) begin
        accepted = 1'b1;
        break;
      end
      waited++;
    end
    @(negedge clk);
    s_arvalid = 1'b0;
  endtask

  task automatic bfm_aw(
      input  logic [SLV_ID_W-1:0] id,
      input  logic [ADDR_W-1:0]   addr,
      input  logic [7:0]          len,
      input  int                  budget,
      output bit                  accepted,
      output int                  waited
  );
    accepted = 1'b0;
    waited   = 0;
    @(negedge clk);
    s_awid    = id;
    s_awaddr  = addr;
    s_awlen   = len;
    s_awvalid = 1'b1;
    while (waited < budget) begin
      @(posedge clk);
      if (s_awready) begin
        accepted = 1'b1;
        break;
      end
      waited++;
    end
    @(negedge clk);
    s_awvalid = 1'b0;
  endtask

  task automatic bfm_w(
      input logic [DATA_W-1:0]   data,
      input logic [DATA_W/8-1:0] strb,
      input logic                last
  );
    @(negedge clk);
    s_wdata  = data;
    s_wstrb  = strb;
    s_wlast  = last;
    s_wvalid = 1'b1;
    forever begin
      @(posedge clk);
      if (s_wready)
        break;
    end
    @(negedge clk);
    s_wvalid = 1'b0;
  endtask

  task automatic bfm_rbeat(
      input logic [MST_ID_W-1:0] mid,
      input logic [DATA_W-1:0]   data,
      input logic                last
  );
    @(negedge clk);
    m_rid    = mid;
    m_rdata  = data;
    m_rlast  = last;
    m_rresp  = 2'b00;
    m_rvalid = 1'b1;
    forever begin
      @(posedge clk);
      if (m_rready)
        break;
    end
    @(negedge clk);
    m_rvalid = 1'b0;
  endtask

  task automatic bfm_bbeat(
      input logic [MST_ID_W-1:0] mid
  );
    @(negedge clk);
    m_bid    = mid;
    m_bresp  = 2'b00;
    m_bvalid = 1'b1;
    forever begin
      @(posedge clk);
      if (m_bready)
        break;
    end
    @(negedge clk);
    m_bvalid = 1'b0;
  endtask

  // Watchdog required by G1.
  initial begin
    #4_000_000;
    $display("RESULT: FAIL");
    $finish;
  end


  // --------------------------------------------------------------------------
  // Testbench bookkeeping
  // --------------------------------------------------------------------------

  typedef struct packed {
    logic                    valid;
    logic                    forwarded;
    logic [SLV_ID_W-1:0]     sid;
    logic [MST_ID_W-1:0]     mid;
    logic [ADDR_W-1:0]       addr;
    logic [7:0]              len;
    logic [8:0]              down_beats;
    logic [8:0]              up_beats;
    logic [31:0]             accept_cycle;
    logic [31:0]             retire_cycle;
  } rd_rec_t;

  typedef struct packed {
    logic                    valid;
    logic                    forwarded;
    logic                    down_resp_seen;
    logic [SLV_ID_W-1:0]     sid;
    logic [MST_ID_W-1:0]     mid;
    logic [ADDR_W-1:0]       addr;
    logic [7:0]              len;
    logic [31:0]             accept_cycle;
    logic [31:0]             retire_cycle;
  } wr_rec_t;

  typedef struct packed {
    logic [DATA_W-1:0]       data;
    logic [DATA_W/8-1:0]     strb;
    logic                    last;
  } wbeat_t;

  rd_rec_t rd_rec [0:MAX_RECS-1];
  wr_rec_t wr_rec [0:MAX_RECS-1];
  wbeat_t  w_exp_q[$];

  integer rd_rec_count;
  integer wr_rec_count;
  integer cycle_no;
  integer fail_count;

  integer rd_retire_cycle [0:(1<<SLV_ID_W)-1];
  integer wr_retire_cycle [0:(1<<SLV_ID_W)-1];

  logic stale_probe_active;


  function automatic logic [DATA_W-1:0] read_data_pattern(
      input logic [ADDR_W-1:0] addr,
      input integer            beat
  );
    logic [31:0] mix;
    begin
      mix = 32'hA500_0000 ^ addr ^ (32'h0101_0101 * beat);
      read_data_pattern = mix[DATA_W-1:0];
    end
  endfunction


  function automatic logic [1:0] response_pattern(
      input logic [ADDR_W-1:0] addr
  );
    begin
      response_pattern = addr[5:4];
    end
  endfunction


  task automatic fail_req(
      input string req_name,
      input string detail
  );
    begin
      fail_count = fail_count + 1;
      $display("FAIL %s: %s", req_name, detail);
    end
  endtask


  task automatic drive_rbeat_resp(
      input logic [MST_ID_W-1:0] mid,
      input logic [DATA_W-1:0]   data,
      input logic [1:0]          resp,
      input logic                last
  );
    @(negedge clk);
    m_rid    = mid;
    m_rdata  = data;
    m_rresp  = resp;
    m_rlast  = last;
    m_rvalid = 1'b1;
    forever begin
      @(posedge clk);
      if (m_rready)
        break;
    end
    @(negedge clk);
    m_rvalid = 1'b0;
  endtask


  task automatic drive_bbeat_resp(
      input logic [MST_ID_W-1:0] mid,
      input logic [1:0]          resp
  );
    @(negedge clk);
    m_bid    = mid;
    m_bresp  = resp;
    m_bvalid = 1'b1;
    forever begin
      @(posedge clk);
      if (m_bready)
        break;
    end
    @(negedge clk);
    m_bvalid = 1'b0;
  endtask


  task automatic probe_stale_r(
      input  logic [MST_ID_W-1:0] mid,
      output bit                  was_accepted
  );
    automatic integer n;

    was_accepted = 1'b0;

    @(negedge clk);
    m_rid    = mid;
    m_rdata  = 32'hDEAD_BEEF;
    m_rresp  = 2'b10;
    m_rlast  = 1'b1;
    m_rvalid = 1'b1;

    for (n = 0; n < 8; n = n + 1) begin
      @(posedge clk);
      if (!was_accepted && m_rready) begin
        was_accepted = 1'b1;
        @(negedge clk);
        m_rvalid = 1'b0;
      end
    end
  endtask


  task automatic probe_stale_b(
      input  logic [MST_ID_W-1:0] mid,
      output bit                  was_accepted
  );
    automatic integer n;

    was_accepted = 1'b0;

    @(negedge clk);
    m_bid    = mid;
    m_bresp  = 2'b11;
    m_bvalid = 1'b1;

    for (n = 0; n < 8; n = n + 1) begin
      @(posedge clk);
      if (!was_accepted && m_bready) begin
        was_accepted = 1'b1;
        @(negedge clk);
        m_bvalid = 1'b0;
      end
    end
  endtask


  // --------------------------------------------------------------------------
  // Passive checker / model
  // --------------------------------------------------------------------------

  always @(posedge clk) begin : monitor
    automatic integer i;
    automatic integer j;
    automatic integer found;
    automatic integer same_count;
    automatic integer distinct_count;
    automatic logic [(1<<SLV_ID_W)-1:0] seen_ids;
    automatic integer total_beats;
    automatic wbeat_t wb;

    cycle_no = cycle_no + 1;

    if (!rst_n) begin
      if (s_awvalid && s_awready)
        fail_req("F1", "write address accepted while reset was low");
      if (s_arvalid && s_arready)
        fail_req("F1", "read address accepted while reset was low");
      if (s_wvalid && s_wready)
        fail_req("F1", "write data accepted while reset was low");
      if (s_bvalid)
        fail_req("F1", "write response presented while reset was low");
      if (s_rvalid)
        fail_req("F1", "read response presented while reset was low");

      rd_rec_count = 0;
      wr_rec_count = 0;
      w_exp_q.delete();

      for (i = 0; i < MAX_RECS; i = i + 1) begin
        rd_rec[i] = '0;
        wr_rec[i] = '0;
      end

      for (i = 0; i < (1<<SLV_ID_W); i = i + 1) begin
        rd_retire_cycle[i] = -1;
        wr_retire_cycle[i] = -1;
      end

    end
    else begin

      if (m_rvalid && m_rready && !stale_probe_active) begin
        found = -1;

        for (i = 0; i < rd_rec_count; i = i + 1) begin
          total_beats = rd_rec[i].len + 1;
          if (
              (found < 0) &&
              rd_rec[i].valid &&
              rd_rec[i].forwarded &&
              (rd_rec[i].mid == m_rid) &&
              (rd_rec[i].down_beats < total_beats)
          )
            found = i;
        end

        if (found < 0) begin
          fail_req("C2", "downstream read response used a master ID with no tracked transaction");
        end
        else begin
          total_beats = rd_rec[found].len + 1;

          if (m_rdata != read_data_pattern(rd_rec[found].addr, rd_rec[found].down_beats))
            fail_req("E1", "test response bookkeeping observed unexpected downstream R data");

          if (m_rresp != response_pattern(rd_rec[found].addr))
            fail_req("E1", "test response bookkeeping observed unexpected downstream R resp");

          if (m_rlast != (rd_rec[found].down_beats == (total_beats - 1)))
            fail_req("E1", "test response bookkeeping observed unexpected downstream R last");

          rd_rec[found].down_beats = rd_rec[found].down_beats + 1'b1;
        end
      end


      if (m_bvalid && m_bready && !stale_probe_active) begin
        found = -1;

        for (i = 0; i < wr_rec_count; i = i + 1) begin
          if (
              (found < 0) &&
              wr_rec[i].valid &&
              wr_rec[i].forwarded &&
              !wr_rec[i].down_resp_seen &&
              (wr_rec[i].mid == m_bid)
          )
            found = i;
        end

        if (found < 0) begin
          fail_req("C2", "downstream write response used a master ID with no tracked transaction");
        end
        else begin
          if (m_bresp != response_pattern(wr_rec[found].addr))
            fail_req("E1", "test response bookkeeping observed unexpected downstream B resp");
          wr_rec[found].down_resp_seen = 1'b1;
        end
      end


      if (s_rvalid && s_rready) begin
        found = -1;

        for (i = 0; i < rd_rec_count; i = i + 1) begin
          if (
              (found < 0) &&
              rd_rec[i].valid &&
              (rd_rec[i].sid == s_rid)
          )
            found = i;
        end

        if (found < 0) begin
          if (!stale_probe_active) begin
            fail_req("C1", "slave RID did not restore an outstanding slave identifier");
            fail_req("C2", "slave R beat had no outstanding transaction");
          end
        end
        else begin
          total_beats = rd_rec[found].len + 1;

          if (rd_rec[found].up_beats >= rd_rec[found].down_beats)
            fail_req("C2", "slave R beat appeared before its downstream response was accepted");

          if (s_rdata != read_data_pattern(rd_rec[found].addr, rd_rec[found].up_beats)) begin
            fail_req("B1", "read responses for one slave ID were not returned in request order");
            fail_req("E1", "read response data was modified");
          end

          if (s_rresp != response_pattern(rd_rec[found].addr))
            fail_req("E1", "read response code was modified");

          if (s_rlast != (rd_rec[found].up_beats == (total_beats - 1)))
            fail_req("E1", "read response last was modified");

          rd_rec[found].up_beats = rd_rec[found].up_beats + 1'b1;

          if (s_rlast) begin
            if (rd_rec[found].up_beats != total_beats)
              fail_req("E1", "read burst terminated at the wrong beat count");

            rd_rec[found].valid         = 1'b0;
            rd_rec[found].retire_cycle = cycle_no;
            rd_retire_cycle[s_rid]      = cycle_no;
          end
        end
      end


      if (s_bvalid && s_bready) begin
        found = -1;

        for (i = 0; i < wr_rec_count; i = i + 1) begin
          if (
              (found < 0) &&
              wr_rec[i].valid &&
              (wr_rec[i].sid == s_bid)
          )
            found = i;
        end

        if (found < 0) begin
          if (!stale_probe_active) begin
            fail_req("C1", "slave BID did not restore an outstanding slave identifier");
            fail_req("C2", "slave B response had no outstanding transaction");
          end
        end
        else begin
          if (!wr_rec[found].down_resp_seen)
            fail_req("C2", "slave B response appeared before its downstream response was accepted");

          if (s_bresp != response_pattern(wr_rec[found].addr)) begin
            fail_req("B1", "write responses for one slave ID were not returned in request order");
            fail_req("E1", "write response code was modified");
          end

          wr_rec[found].valid         = 1'b0;
          wr_rec[found].retire_cycle = cycle_no;
          wr_retire_cycle[s_bid]      = cycle_no;
        end
      end


      if (s_arvalid && s_arready) begin
        same_count     = 0;
        distinct_count = 0;
        seen_ids       = '0;

        for (i = 0; i < rd_rec_count; i = i + 1) begin
          if (rd_rec[i].valid) begin
            seen_ids[rd_rec[i].sid] = 1'b1;
            if (rd_rec[i].sid == s_arid)
              same_count = same_count + 1;
          end
        end

        for (i = 0; i < (1<<SLV_ID_W); i = i + 1)
          if (seen_ids[i])
            distinct_count = distinct_count + 1;

        if (same_count >= MAX_TXNS_PER_ID)
          fail_req("A5", "accepted a read beyond MAX_TXNS_PER_ID");

        if (!seen_ids[s_arid] && (distinct_count >= MAX_UNIQ_IDS)) begin
          fail_req("A2", "accepted more than MAX_UNIQ_IDS distinct read IDs");
          fail_req("A3", "accepted a new read ID while the read table was full");
        end

        if (rd_rec_count < MAX_RECS) begin
          rd_rec[rd_rec_count].valid         = 1'b1;
          rd_rec[rd_rec_count].forwarded     = 1'b0;
          rd_rec[rd_rec_count].sid           = s_arid;
          rd_rec[rd_rec_count].mid           = '0;
          rd_rec[rd_rec_count].addr          = s_araddr;
          rd_rec[rd_rec_count].len           = s_arlen;
          rd_rec[rd_rec_count].down_beats    = '0;
          rd_rec[rd_rec_count].up_beats      = '0;
          rd_rec[rd_rec_count].accept_cycle  = cycle_no;
          rd_rec[rd_rec_count].retire_cycle  = '0;
          rd_rec_count = rd_rec_count + 1;
        end
      end


      if (s_awvalid && s_awready) begin
        same_count     = 0;
        distinct_count = 0;
        seen_ids       = '0;

        for (i = 0; i < wr_rec_count; i = i + 1) begin
          if (wr_rec[i].valid) begin
            seen_ids[wr_rec[i].sid] = 1'b1;
            if (wr_rec[i].sid == s_awid)
              same_count = same_count + 1;
          end
        end

        for (i = 0; i < (1<<SLV_ID_W); i = i + 1)
          if (seen_ids[i])
            distinct_count = distinct_count + 1;

        if (same_count >= MAX_TXNS_PER_ID)
          fail_req("A5", "accepted a write beyond MAX_TXNS_PER_ID");

        if (!seen_ids[s_awid] && (distinct_count >= MAX_UNIQ_IDS)) begin
          fail_req("A2", "accepted more than MAX_UNIQ_IDS distinct write IDs");
          fail_req("A3", "accepted a new write ID while the write table was full");
        end

        if (wr_rec_count < MAX_RECS) begin
          wr_rec[wr_rec_count].valid          = 1'b1;
          wr_rec[wr_rec_count].forwarded      = 1'b0;
          wr_rec[wr_rec_count].down_resp_seen = 1'b0;
          wr_rec[wr_rec_count].sid            = s_awid;
          wr_rec[wr_rec_count].mid            = '0;
          wr_rec[wr_rec_count].addr           = s_awaddr;
          wr_rec[wr_rec_count].len            = s_awlen;
          wr_rec[wr_rec_count].accept_cycle   = cycle_no;
          wr_rec[wr_rec_count].retire_cycle   = '0;
          wr_rec_count = wr_rec_count + 1;
        end
      end


      if (m_arvalid && m_arready) begin
        found = -1;

        for (i = 0; i < rd_rec_count; i = i + 1) begin
          if (
              (found < 0) &&
              rd_rec[i].valid &&
              !rd_rec[i].forwarded &&
              (rd_rec[i].addr == m_araddr) &&
              (rd_rec[i].len  == m_arlen)
          )
            found = i;
        end

        if (found < 0) begin
          fail_req("D4", "master AR did not correspond to exactly one accepted slave AR");
          fail_req("E1", "master AR address/length was modified or duplicated");
        end
        else begin
          for (j = 0; j < rd_rec_count; j = j + 1) begin
            if (
                rd_rec[j].valid &&
                rd_rec[j].forwarded &&
                (rd_rec[j].sid != rd_rec[found].sid) &&
                (rd_rec[j].mid == m_arid)
            ) begin
              fail_req("D1", "co-outstanding read IDs collided on one master ID");
              fail_req("D2", "read master ID was reused before the prior slave ID retired");
            end
          end

          rd_rec[found].forwarded = 1'b1;
          rd_rec[found].mid       = m_arid;
        end
      end


      if (m_awvalid && m_awready) begin
        found = -1;

        for (i = 0; i < wr_rec_count; i = i + 1) begin
          if (
              (found < 0) &&
              wr_rec[i].valid &&
              !wr_rec[i].forwarded &&
              (wr_rec[i].addr == m_awaddr) &&
              (wr_rec[i].len  == m_awlen)
          )
            found = i;
        end

        if (found < 0) begin
          fail_req("D4", "master AW did not correspond to exactly one accepted slave AW");
          fail_req("E1", "master AW address/length was modified or duplicated");
        end
        else begin
          for (j = 0; j < wr_rec_count; j = j + 1) begin
            if (
                wr_rec[j].valid &&
                wr_rec[j].forwarded &&
                (wr_rec[j].sid != wr_rec[found].sid) &&
                (wr_rec[j].mid == m_awid)
            ) begin
              fail_req("D1", "co-outstanding write IDs collided on one master ID");
              fail_req("D2", "write master ID was reused before the prior slave ID retired");
            end
          end

          wr_rec[found].forwarded = 1'b1;
          wr_rec[found].mid       = m_awid;
        end
      end


      if (s_wvalid && s_wready) begin
        wb.data = s_wdata;
        wb.strb = s_wstrb;
        wb.last = s_wlast;
        w_exp_q.push_back(wb);
      end

      if (m_wvalid && m_wready) begin
        if (w_exp_q.size() == 0) begin
          fail_req("B3", "master W beat appeared without a preceding accepted slave W beat");
          fail_req("E1", "unexpected master W payload");
        end
        else begin
          wb = w_exp_q.pop_front();
          if (
              (m_wdata != wb.data) ||
              (m_wstrb != wb.strb) ||
              (m_wlast != wb.last)
          ) begin
            fail_req("B3", "write beats were reordered or interleaved");
            fail_req("E1", "write data/strb/last was modified");
          end
        end
      end


      if (stale_probe_active) begin
        if (s_rvalid)
          fail_req("F1", "pre-reset read work produced an upstream response after reset");
        if (s_bvalid)
          fail_req("F1", "pre-reset write work produced an upstream response after reset");
      end

    end
  end


  task automatic wait_rd_forward(
      input  logic [ADDR_W-1:0] addr,
      output bit                  ok,
      output logic [MST_ID_W-1:0] mid
  );
    automatic integer n;
    automatic integer i;
    ok  = 1'b0;
    mid = '0;

    for (n = 0; n < LONG_WAIT; n = n + 1) begin
      @(negedge clk);
      for (i = 0; i < rd_rec_count; i = i + 1) begin
        if (rd_rec[i].valid && rd_rec[i].forwarded && (rd_rec[i].addr == addr)) begin
          ok  = 1'b1;
          mid = rd_rec[i].mid;
        end
      end
      if (ok)
        break;
    end

    if (!ok)
      fail_req("D4", "accepted read did not produce a master AR within the test watchdog budget");
  endtask


  task automatic wait_wr_forward(
      input  logic [ADDR_W-1:0] addr,
      output bit                  ok,
      output logic [MST_ID_W-1:0] mid
  );
    automatic integer n;
    automatic integer i;
    ok  = 1'b0;
    mid = '0;

    for (n = 0; n < LONG_WAIT; n = n + 1) begin
      @(negedge clk);
      for (i = 0; i < wr_rec_count; i = i + 1) begin
        if (wr_rec[i].valid && wr_rec[i].forwarded && (wr_rec[i].addr == addr)) begin
          ok  = 1'b1;
          mid = wr_rec[i].mid;
        end
      end
      if (ok)
        break;
    end

    if (!ok)
      fail_req("D4", "accepted write did not produce a master AW within the test watchdog budget");
  endtask


  task automatic get_rd_accept_cycle(
      input  logic [ADDR_W-1:0] addr,
      output bit                  found_ok,
      output integer              when_cycle
  );
    automatic integer i;
    found_ok   = 1'b0;
    when_cycle = -1;

    for (i = 0; i < rd_rec_count; i = i + 1) begin
      if (rd_rec[i].addr == addr) begin
        found_ok   = 1'b1;
        when_cycle = rd_rec[i].accept_cycle;
      end
    end
  endtask


  task automatic get_wr_accept_cycle(
      input  logic [ADDR_W-1:0] addr,
      output bit                  found_ok,
      output integer              when_cycle
  );
    automatic integer i;
    found_ok   = 1'b0;
    when_cycle = -1;

    for (i = 0; i < wr_rec_count; i = i + 1) begin
      if (wr_rec[i].addr == addr) begin
        found_ok   = 1'b1;
        when_cycle = wr_rec[i].accept_cycle;
      end
    end
  endtask


  task automatic wait_rd_retired(
      input logic [ADDR_W-1:0] addr
  );
    automatic integer n;
    automatic integer i;
    automatic bit done;
    done = 1'b0;

    for (n = 0; n < LONG_WAIT; n = n + 1) begin
      @(negedge clk);
      done = 1'b0;
      for (i = 0; i < rd_rec_count; i = i + 1) begin
        if ((rd_rec[i].addr == addr) && !rd_rec[i].valid)
          done = 1'b1;
      end
      if (done)
        break;
    end

    if (!done)
      fail_req("A1", "read transaction did not retire after its final response");
  endtask


  task automatic wait_wr_retired(
      input logic [ADDR_W-1:0] addr
  );
    automatic integer n;
    automatic integer i;
    automatic bit done;
    done = 1'b0;

    for (n = 0; n < LONG_WAIT; n = n + 1) begin
      @(negedge clk);
      done = 1'b0;
      for (i = 0; i < wr_rec_count; i = i + 1) begin
        if ((wr_rec[i].addr == addr) && !wr_rec[i].valid)
          done = 1'b1;
      end
      if (done)
        break;
    end

    if (!done)
      fail_req("A1", "write transaction did not retire after its B response");
  endtask


  task automatic respond_read(
      input logic [ADDR_W-1:0] addr
  );
    automatic bit ok;
    automatic logic [MST_ID_W-1:0] mid;
    automatic integer i;
    automatic integer beat;
    automatic integer start_beat;
    automatic integer len_i;

    wait_rd_forward(addr, ok, mid);
    if (!ok)
      return;

    len_i      = 0;
    start_beat = 0;

    for (i = 0; i < rd_rec_count; i = i + 1) begin
      if (rd_rec[i].addr == addr) begin
        len_i      = rd_rec[i].len;
        start_beat = rd_rec[i].down_beats;
      end
    end

    for (beat = start_beat; beat <= len_i; beat = beat + 1) begin
      drive_rbeat_resp(
          mid,
          read_data_pattern(addr, beat),
          response_pattern(addr),
          (beat == len_i)
      );
    end

    wait_rd_retired(addr);
  endtask


  task automatic respond_write(
      input logic [ADDR_W-1:0] addr
  );
    automatic bit ok;
    automatic logic [MST_ID_W-1:0] mid;

    wait_wr_forward(addr, ok, mid);
    if (!ok)
      return;

    drive_bbeat_resp(mid, response_pattern(addr));
    wait_wr_retired(addr);
  endtask


  task automatic drain_all_reads;
    automatic integer i;
    automatic integer chosen;
    automatic integer idle_cycles;
    automatic bit any_active;
    automatic logic [ADDR_W-1:0] chosen_addr;

    idle_cycles = 0;

    forever begin
      any_active  = 1'b0;
      chosen      = -1;
      chosen_addr = '0;

      for (i = 0; i < rd_rec_count; i = i + 1) begin
        if (rd_rec[i].valid) begin
          any_active = 1'b1;
          if ((chosen < 0) && rd_rec[i].forwarded) begin
            chosen      = i;
            chosen_addr = rd_rec[i].addr;
          end
        end
      end

      if (!any_active)
        break;

      if (chosen >= 0) begin
        respond_read(chosen_addr);
        idle_cycles = 0;
      end
      else begin
        @(negedge clk);
        idle_cycles = idle_cycles + 1;
        if (idle_cycles >= LONG_WAIT) begin
          fail_req("D4", "accepted reads remained outstanding but none was forwarded");
          break;
        end
      end
    end
  endtask


  task automatic drain_all_writes;
    automatic integer i;
    automatic integer chosen;
    automatic integer idle_cycles;
    automatic bit any_active;
    automatic logic [ADDR_W-1:0] chosen_addr;

    idle_cycles = 0;

    forever begin
      any_active  = 1'b0;
      chosen      = -1;
      chosen_addr = '0;

      for (i = 0; i < wr_rec_count; i = i + 1) begin
        if (wr_rec[i].valid) begin
          any_active = 1'b1;
          if ((chosen < 0) && wr_rec[i].forwarded) begin
            chosen      = i;
            chosen_addr = wr_rec[i].addr;
          end
        end
      end

      if (!any_active)
        break;

      if (chosen >= 0) begin
        respond_write(chosen_addr);
        idle_cycles = 0;
      end
      else begin
        @(negedge clk);
        idle_cycles = idle_cycles + 1;
        if (idle_cycles >= LONG_WAIT) begin
          fail_req("D4", "accepted writes remained outstanding but none was forwarded");
          break;
        end
      end
    end
  endtask


  task automatic require_ar_accept(
      input logic [SLV_ID_W-1:0] id,
      input logic [ADDR_W-1:0]   addr,
      input logic [7:0]          len,
      input string               req_name
  );
    automatic bit accepted;
    automatic integer waited;

    bfm_ar(id, addr, len, LONG_WAIT, accepted, waited);
    if (!accepted)
      fail_req(req_name, "read request that must be serviceable was not accepted");
  endtask


  task automatic require_aw_accept(
      input logic [SLV_ID_W-1:0] id,
      input logic [ADDR_W-1:0]   addr,
      input logic [7:0]          len,
      input string               req_name
  );
    automatic bit accepted;
    automatic integer waited;

    bfm_aw(id, addr, len, LONG_WAIT, accepted, waited);
    if (!accepted)
      fail_req(req_name, "write request that must be serviceable was not accepted");
  endtask


  initial begin : main_test
    automatic bit accepted;
    automatic bit ok;
    automatic bit stale_r_taken;
    automatic bit stale_b_taken;
    automatic integer waited;
    automatic integer accept_cycle;
    automatic integer retire_cycle;
    automatic logic [MST_ID_W-1:0] mid0;
    automatic logic [MST_ID_W-1:0] mid1;
    automatic logic [MST_ID_W-1:0] mid2;
    automatic logic [MST_ID_W-1:0] mid3;

    automatic logic [31:0] r0;
    automatic logic [31:0] r1;
    automatic logic [31:0] r2;
    automatic logic [31:0] r3;
    automatic logic [31:0] r4;
    automatic logic [31:0] r5;
    automatic logic [31:0] r6;

    automatic logic [31:0] w0;
    automatic logic [31:0] w1;
    automatic logic [31:0] w2;
    automatic logic [31:0] w3;
    automatic logic [31:0] w4;
    automatic logic [31:0] w5;

    fail_count         = 0;
    cycle_no           = 0;
    stale_probe_active = 1'b0;

    s_awid    = '0;
    s_awaddr  = '0;
    s_awlen   = '0;
    s_awvalid = 1'b0;

    s_wdata   = '0;
    s_wstrb   = '0;
    s_wlast   = 1'b0;
    s_wvalid  = 1'b0;

    s_bready  = 1'b1;

    s_arid    = '0;
    s_araddr  = '0;
    s_arlen   = '0;
    s_arvalid = 1'b0;

    s_rready  = 1'b1;

    m_awready = 1'b1;
    m_wready  = 1'b1;
    m_bvalid  = 1'b0;
    m_bid     = '0;
    m_bresp   = '0;

    m_arready = 1'b1;
    m_rvalid  = 1'b0;
    m_rid     = '0;
    m_rdata   = '0;
    m_rresp   = '0;
    m_rlast   = 1'b0;


    // F1: reset while active.
    @(negedge clk);
    rst_n     = 1'b0;
    s_awvalid = 1'b1;
    s_arvalid = 1'b1;
    s_wvalid  = 1'b1;
    m_bvalid  = 1'b1;
    m_rvalid  = 1'b1;

    repeat (3) @(posedge clk);

    @(negedge clk);
    s_awvalid = 1'b0;
    s_arvalid = 1'b0;
    s_wvalid  = 1'b0;
    m_bvalid  = 1'b0;
    m_rvalid  = 1'b0;
    rst_n     = 1'b1;


    // ------------------------------------------------------------------------
    // Read-table A3/A4 boundary.
    // ------------------------------------------------------------------------

    r0 = 32'h1000_0000;
    r1 = 32'h1000_0100;
    r2 = 32'h1000_0200;
    r3 = 32'h1000_0300;
    r4 = 32'h1000_0400;

    require_ar_accept(4'h0, r0, 8'd0, "A3");
    require_ar_accept(4'h1, r1, 8'd0, "A3");
    require_ar_accept(4'h2, r2, 8'd0, "A3");
    require_ar_accept(4'h3, r3, 8'd0, "A3");

    wait_rd_forward(r0, ok, mid0);

    bfm_ar(4'h4, r4, 8'd0, 5, accepted, waited);

    if (accepted)
      fail_req("A3", "fifth distinct read ID was accepted before any ID retired");

    fork
      begin
        automatic bit acc_a4;
        automatic integer wait_a4;

        bfm_ar(
            4'h4,
            r4,
            8'd0,
            LONG_WAIT,
            acc_a4,
            wait_a4
        );

        if (!acc_a4)
          fail_req("A4", "new read ID was not accepted after an entry retired");
      end

      begin
        drive_rbeat_resp(
            mid0,
            read_data_pattern(r0, 0),
            response_pattern(r0),
            1'b1
        );
      end
    join

    repeat (3) @(negedge clk);

    retire_cycle = rd_retire_cycle[4'h0];

    get_rd_accept_cycle(
        r4,
        ok,
        accept_cycle
    );

    if (!ok)
      fail_req("A4", "new read ID never entered the table after retirement");
    else if (retire_cycle < 0)
      fail_req("A1", "retiring read did not complete on its final response transfer");
    else begin

      if (accept_cycle < retire_cycle)
        fail_req("A3", "new read ID was accepted before the full-table entry retired");

      if ((accept_cycle - retire_cycle) > 2)
        fail_req("A4", "read entry was not reusable within two cycles of retirement");

    end

    wait_rd_forward(r4, ok, mid0);

    drain_all_reads();


    // ------------------------------------------------------------------------
    // Per-ID read depth and ordering.
    // ------------------------------------------------------------------------

    bfm_reset(3);

    r5 = 32'h2000_0010;
    r6 = 32'h2000_0120;

    require_ar_accept(4'h5, r5, 8'd2, "A5");
    require_ar_accept(4'h5, r6, 8'd0, "A5");

    bfm_ar(
        4'h5,
        32'h2000_0220,
        8'd0,
        5,
        accepted,
        waited
    );

    if (accepted)
      fail_req("A5", "third read transaction for one slave ID was accepted");

    respond_read(r5);
    respond_read(r6);


    // ------------------------------------------------------------------------
    // Write table A3/A4 boundary and B3/E1.
    // ------------------------------------------------------------------------

    bfm_reset(3);

    w0 = 32'h3000_0000;
    w1 = 32'h3000_0100;
    w2 = 32'h3000_0200;
    w3 = 32'h3000_0300;
    w4 = 32'h3000_0400;

    require_aw_accept(4'h8, w0, 8'd0, "A3");
    require_aw_accept(4'h9, w1, 8'd0, "A3");
    require_aw_accept(4'hA, w2, 8'd0, "A3");
    require_aw_accept(4'hB, w3, 8'd0, "A3");

    wait_wr_forward(w0, ok, mid0);
    bfm_w(32'h1111_0000, 4'b1111, 1'b1);

    wait_wr_forward(w1, ok, mid1);
    bfm_w(32'h2222_0001, 4'b0111, 1'b1);

    wait_wr_forward(w2, ok, mid2);
    bfm_w(32'h3333_0002, 4'b1011, 1'b1);

    wait_wr_forward(w3, ok, mid3);
    bfm_w(32'h4444_0003, 4'b1101, 1'b1);

    bfm_aw(4'hC, w4, 8'd0, 5, accepted, waited);

    if (accepted)
      fail_req("A3", "fifth distinct write ID was accepted before any ID retired");

    fork
      begin
        automatic bit acc_w_a4;
        automatic integer wait_w_a4;

        bfm_aw(
            4'hC,
            w4,
            8'd0,
            LONG_WAIT,
            acc_w_a4,
            wait_w_a4
        );

        if (!acc_w_a4)
          fail_req("A4", "new write ID was not accepted after an entry retired");
      end

      begin
        drive_bbeat_resp(
            mid0,
            response_pattern(w0)
        );
      end
    join

    repeat (3) @(negedge clk);

    retire_cycle = wr_retire_cycle[4'h8];

    get_wr_accept_cycle(
        w4,
        ok,
        accept_cycle
    );

    if (!ok)
      fail_req("A4", "new write ID never entered the table after retirement");
    else if (retire_cycle < 0)
      fail_req("A1", "retiring write did not complete on its B response transfer");
    else begin

      if (accept_cycle < retire_cycle)
        fail_req("A3", "new write ID was accepted before the full-table entry retired");

      if ((accept_cycle - retire_cycle) > 2)
        fail_req("A4", "write entry was not reusable within two cycles of retirement");

    end

    wait_wr_forward(w4, ok, mid0);
    bfm_w(32'h5555_0004, 4'b1110, 1'b1);

    drain_all_writes();


    // ------------------------------------------------------------------------
    // Per-ID write depth and multi-beat ordering.
    // ------------------------------------------------------------------------

    bfm_reset(3);

    w5 = 32'h4000_0010;

    require_aw_accept(4'h6, w5, 8'd2, "A5");

    require_aw_accept(
        4'h6,
        32'h4000_1010,
        8'd0,
        "A5"
    );

    bfm_aw(
        4'h6,
        32'h4000_2010,
        8'd0,
        5,
        accepted,
        waited
    );

    if (accepted)
      fail_req("A5", "third write transaction for one slave ID was accepted");

    wait_wr_forward(w5, ok, mid0);

    bfm_w(32'hCAFE_0000, 4'b1111, 1'b0);
    bfm_w(32'hCAFE_0001, 4'b0011, 1'b0);
    bfm_w(32'hCAFE_0002, 4'b0001, 1'b1);

    respond_write(w5);

    wait_wr_forward(
        32'h4000_1010,
        ok,
        mid1
    );

    bfm_w(
        32'hD00D_0003,
        4'b1111,
        1'b1
    );

    respond_write(
        32'h4000_1010
    );


    // ------------------------------------------------------------------------
    // F1 mid-operation reset/discard.
    // ------------------------------------------------------------------------

    bfm_reset(3);

    require_ar_accept(
        4'h1,
        32'h5000_0010,
        8'd0,
        "A3"
    );

    require_aw_accept(
        4'h2,
        32'h5000_1010,
        8'd0,
        "A3"
    );

    wait_rd_forward(
        32'h5000_0010,
        ok,
        mid0
    );

    wait_wr_forward(
        32'h5000_1010,
        ok,
        mid1
    );

    bfm_w(
        32'hFACE_1234,
        4'b1111,
        1'b1
    );

    bfm_reset(3);

    stale_probe_active = 1'b1;

    fork
      probe_stale_r(
          mid0,
          stale_r_taken
      );

      probe_stale_b(
          mid1,
          stale_b_taken
      );
    join

    @(negedge clk);

    rst_n = 1'b0;

    repeat (2)
      @(posedge clk);

    @(negedge clk);

    m_rvalid = 1'b0;
    m_bvalid = 1'b0;

    stale_probe_active = 1'b0;

    rst_n = 1'b1;


    // Table must be empty after reset.
    require_ar_accept(
        4'h0,
        32'h6000_0000,
        8'd0,
        "A3"
    );

    require_ar_accept(
        4'h1,
        32'h6000_0100,
        8'd0,
        "A3"
    );

    require_ar_accept(
        4'h2,
        32'h6000_0200,
        8'd0,
        "A3"
    );

    require_ar_accept(
        4'h3,
        32'h6000_0300,
        8'd0,
        "F1"
    );

    drain_all_reads();


    repeat (5)
      @(negedge clk);

    if (w_exp_q.size() != 0)
      fail_req("B3", "accepted slave W beats remained unforwarded at end of test");

    if (fail_count == 0)
      $display("RESULT: PASS");
    else
      $display("RESULT: FAIL");

    $finish;
  end

endmodule