module dw_downsizer_tb;

  localparam int unsigned ADDR_W      = 32;
  localparam int unsigned ID_W        = 4;
  localparam int unsigned SLV_DATA_W  = 64;
  localparam int unsigned MST_DATA_W  = 16;
  localparam int unsigned MAX_READS   = 4;

  localparam int LOG_DEPTH  = 512;
  localparam int WAIT_LIMIT = 20000;

  localparam logic [1:0] BURST_FIXED = 2'b00;
  localparam logic [1:0] BURST_INCR  = 2'b01;
  localparam logic [1:0] BURST_WRAP  = 2'b10;

  localparam logic [1:0] RESP_OKAY   = 2'b00;
  localparam logic [1:0] RESP_SLVERR = 2'b10;
  localparam logic [1:0] RESP_DECERR = 2'b11;


  // ==========================================================================
  // Clock / reset
  // ==========================================================================

  logic clk;
  logic rst_n;

  initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
  end

  initial rst_n = 1'b0;


  task automatic bfm_reset(input int cycles = 4);
    @(negedge clk);
    rst_n = 1'b0;

    repeat (cycles)
      @(posedge clk);

    @(negedge clk);
    rst_n = 1'b1;
  endtask


  // ==========================================================================
  // DUT signals
  // ==========================================================================

  logic [ID_W-1:0]          s_awid;
  logic [ADDR_W-1:0]        s_awaddr;
  logic [7:0]               s_awlen;
  logic [2:0]               s_awsize;
  logic [1:0]               s_awburst;
  logic                     s_awvalid;
  logic                     s_awready;

  logic [SLV_DATA_W-1:0]    s_wdata;
  logic [SLV_DATA_W/8-1:0]  s_wstrb;
  logic                     s_wlast;
  logic                     s_wvalid;
  logic                     s_wready;

  logic [ID_W-1:0]          s_bid;
  logic [1:0]               s_bresp;
  logic                     s_bvalid;
  logic                     s_bready;

  logic [ID_W-1:0]          s_arid;
  logic [ADDR_W-1:0]        s_araddr;
  logic [7:0]               s_arlen;
  logic [2:0]               s_arsize;
  logic [1:0]               s_arburst;
  logic                     s_arvalid;
  logic                     s_arready;

  logic [ID_W-1:0]          s_rid;
  logic [SLV_DATA_W-1:0]    s_rdata;
  logic [1:0]               s_rresp;
  logic                     s_rlast;
  logic                     s_rvalid;
  logic                     s_rready;

  logic [ID_W-1:0]          m_awid;
  logic [ADDR_W-1:0]        m_awaddr;
  logic [7:0]               m_awlen;
  logic [2:0]               m_awsize;
  logic [1:0]               m_awburst;
  logic                     m_awvalid;
  logic                     m_awready;

  logic [MST_DATA_W-1:0]    m_wdata;
  logic [MST_DATA_W/8-1:0]  m_wstrb;
  logic                     m_wlast;
  logic                     m_wvalid;
  logic                     m_wready;

  logic [ID_W-1:0]          m_bid;
  logic [1:0]               m_bresp;
  logic                     m_bvalid;
  logic                     m_bready;

  logic [ID_W-1:0]          m_arid;
  logic [ADDR_W-1:0]        m_araddr;
  logic [7:0]               m_arlen;
  logic [2:0]               m_arsize;
  logic [1:0]               m_arburst;
  logic                     m_arvalid;
  logic                     m_arready;

  logic [ID_W-1:0]          m_rid;
  logic [MST_DATA_W-1:0]    m_rdata;
  logic [1:0]               m_rresp;
  logic                     m_rlast;
  logic                     m_rvalid;
  logic                     m_rready;


  dw_downsizer #(
      .ADDR_W      (ADDR_W),
      .ID_W        (ID_W),
      .SLV_DATA_W  (SLV_DATA_W),
      .MST_DATA_W  (MST_DATA_W),
      .MAX_READS   (MAX_READS)
  ) dut (
      .clk_i       (clk),
      .rst_ni      (rst_n),

      .s_awid      (s_awid),
      .s_awaddr    (s_awaddr),
      .s_awlen     (s_awlen),
      .s_awsize    (s_awsize),
      .s_awburst   (s_awburst),
      .s_awvalid   (s_awvalid),
      .s_awready   (s_awready),

      .s_wdata     (s_wdata),
      .s_wstrb     (s_wstrb),
      .s_wlast     (s_wlast),
      .s_wvalid    (s_wvalid),
      .s_wready    (s_wready),

      .s_bid       (s_bid),
      .s_bresp     (s_bresp),
      .s_bvalid    (s_bvalid),
      .s_bready    (s_bready),

      .s_arid      (s_arid),
      .s_araddr    (s_araddr),
      .s_arlen     (s_arlen),
      .s_arsize    (s_arsize),
      .s_arburst   (s_arburst),
      .s_arvalid   (s_arvalid),
      .s_arready   (s_arready),

      .s_rid       (s_rid),
      .s_rdata     (s_rdata),
      .s_rresp     (s_rresp),
      .s_rlast     (s_rlast),
      .s_rvalid    (s_rvalid),
      .s_rready    (s_rready),

      .m_awid      (m_awid),
      .m_awaddr    (m_awaddr),
      .m_awlen     (m_awlen),
      .m_awsize    (m_awsize),
      .m_awburst   (m_awburst),
      .m_awvalid   (m_awvalid),
      .m_awready   (m_awready),

      .m_wdata     (m_wdata),
      .m_wstrb     (m_wstrb),
      .m_wlast     (m_wlast),
      .m_wvalid    (m_wvalid),
      .m_wready    (m_wready),

      .m_bid       (m_bid),
      .m_bresp     (m_bresp),
      .m_bvalid    (m_bvalid),
      .m_bready    (m_bready),

      .m_arid      (m_arid),
      .m_araddr    (m_araddr),
      .m_arlen     (m_arlen),
      .m_arsize    (m_arsize),
      .m_arburst   (m_arburst),
      .m_arvalid   (m_arvalid),
      .m_arready   (m_arready),

      .m_rid       (m_rid),
      .m_rdata     (m_rdata),
      .m_rresp     (m_rresp),
      .m_rlast     (m_rlast),
      .m_rvalid    (m_rvalid),
      .m_rready    (m_rready)
  );


  // ==========================================================================
  // Transaction logs
  // ==========================================================================

  typedef struct packed {
    logic [ID_W-1:0]   id;
    logic [ADDR_W-1:0] addr;
    logic [7:0]        len;
    logic [2:0]        size;
    logic [1:0]        burst;
  } addr_rec_t;

  typedef struct packed {
    logic [MST_DATA_W-1:0]   data;
    logic [MST_DATA_W/8-1:0] strb;
    logic                    last;
  } mw_rec_t;

  typedef struct packed {
    logic [ID_W-1:0]       id;
    logic [SLV_DATA_W-1:0] data;
    logic [1:0]            resp;
    logic                  last;
  } sr_rec_t;

  typedef struct packed {
    logic [ID_W-1:0] id;
    logic [1:0]      resp;
  } sb_rec_t;


  addr_rec_t m_ar_log [0:LOG_DEPTH-1];
  addr_rec_t m_aw_log [0:LOG_DEPTH-1];
  mw_rec_t   m_w_log  [0:LOG_DEPTH-1];
  sr_rec_t   s_r_log  [0:LOG_DEPTH-1];
  sb_rec_t   s_b_log  [0:LOG_DEPTH-1];

  integer m_ar_count;
  integer m_aw_count;
  integer m_w_count;
  integer s_r_count;
  integer s_b_count;

  integer fail_count;


  always @(posedge clk) begin : handshake_monitor
    if (rst_n) begin

      if (m_arvalid && m_arready) begin
        if (m_ar_count < LOG_DEPTH) begin
          m_ar_log[m_ar_count].id    = m_arid;
          m_ar_log[m_ar_count].addr  = m_araddr;
          m_ar_log[m_ar_count].len   = m_arlen;
          m_ar_log[m_ar_count].size  = m_arsize;
          m_ar_log[m_ar_count].burst = m_arburst;
        end
        m_ar_count = m_ar_count + 1;
      end

      if (m_awvalid && m_awready) begin
        if (m_aw_count < LOG_DEPTH) begin
          m_aw_log[m_aw_count].id    = m_awid;
          m_aw_log[m_aw_count].addr  = m_awaddr;
          m_aw_log[m_aw_count].len   = m_awlen;
          m_aw_log[m_aw_count].size  = m_awsize;
          m_aw_log[m_aw_count].burst = m_awburst;
        end
        m_aw_count = m_aw_count + 1;
      end

      if (m_wvalid && m_wready) begin
        if (m_w_count < LOG_DEPTH) begin
          m_w_log[m_w_count].data = m_wdata;
          m_w_log[m_w_count].strb = m_wstrb;
          m_w_log[m_w_count].last = m_wlast;
        end
        m_w_count = m_w_count + 1;
      end

      if (s_rvalid && s_rready) begin
        if (s_r_count < LOG_DEPTH) begin
          s_r_log[s_r_count].id   = s_rid;
          s_r_log[s_r_count].data = s_rdata;
          s_r_log[s_r_count].resp = s_rresp;
          s_r_log[s_r_count].last = s_rlast;
        end
        s_r_count = s_r_count + 1;
      end

      if (s_bvalid && s_bready) begin
        if (s_b_count < LOG_DEPTH) begin
          s_b_log[s_b_count].id   = s_bid;
          s_b_log[s_b_count].resp = s_bresp;
        end
        s_b_count = s_b_count + 1;
      end

    end
  end


  // ==========================================================================
  // Utility
  // ==========================================================================

  task automatic fail_req(
      input string req_name,
      input string text
  );
    begin
      fail_count = fail_count + 1;
      $display("FAIL %s: %s", req_name, text);
    end
  endtask


  function automatic logic [2:0] calc_dsize(
      input logic [2:0] usize
  );
    begin
      if (usize > 3'd1)
        calc_dsize = 3'd1;
      else
        calc_dsize = usize;
    end
  endfunction


  function automatic logic [7:0] calc_dlen(
      input logic [ADDR_W-1:0] addr,
      input logic [7:0]        len,
      input logic [2:0]        usize
  );
    longint unsigned up_bytes;
    longint unsigned d_bytes;
    longint unsigned up_aligned;
    longint unsigned first_aligned;
    longint unsigned last_aligned;
    longint unsigned total_bytes;
    longint unsigned last_addr;
    longint unsigned beats;
    logic [2:0] dsize_v;

    begin
      dsize_v = calc_dsize(usize);

      up_bytes =
          64'd1 << usize;

      d_bytes =
          64'd1 << dsize_v;

      up_aligned =
          (addr >> usize) << usize;

      total_bytes =
          ((len + 1) * up_bytes) -
          (addr - up_aligned);

      last_addr =
          addr + total_bytes - 1;

      first_aligned =
          (addr >> dsize_v) << dsize_v;

      last_aligned =
          (last_addr >> dsize_v) << dsize_v;

      beats =
          ((last_aligned - first_aligned) / d_bytes) + 1;

      calc_dlen =
          beats - 1;
    end
  endfunction


  task automatic initialise_inputs;
    begin
      s_awid    = '0;
      s_awaddr  = '0;
      s_awlen   = '0;
      s_awsize  = '0;
      s_awburst = BURST_INCR;
      s_awvalid = 1'b0;

      s_wdata   = '0;
      s_wstrb   = '0;
      s_wlast   = 1'b0;
      s_wvalid  = 1'b0;

      s_bready  = 1'b1;

      s_arid    = '0;
      s_araddr  = '0;
      s_arlen   = '0;
      s_arsize  = '0;
      s_arburst = BURST_INCR;
      s_arvalid = 1'b0;

      s_rready  = 1'b1;

      m_awready = 1'b1;
      m_wready  = 1'b1;

      m_bid     = '0;
      m_bresp   = RESP_OKAY;
      m_bvalid  = 1'b0;

      m_arready = 1'b1;

      m_rid     = '0;
      m_rdata   = '0;
      m_rresp   = RESP_OKAY;
      m_rlast   = 1'b0;
      m_rvalid  = 1'b0;
    end
  endtask


  // ==========================================================================
  // Upstream BFMs
  // ==========================================================================

  task automatic drive_ar(
      input  logic [ID_W-1:0]   id_v,
      input  logic [ADDR_W-1:0] addr_v,
      input  logic [7:0]        len_v,
      input  logic [2:0]        size_v,
      input  logic [1:0]        burst_v,
      input  integer            budget,
      output bit                accepted,
      output integer            waited
  );
    begin
      accepted = 1'b0;
      waited   = 0;

      @(negedge clk);

      s_arid    = id_v;
      s_araddr  = addr_v;
      s_arlen   = len_v;
      s_arsize  = size_v;
      s_arburst = burst_v;
      s_arvalid = 1'b1;

      while (waited < budget) begin
        @(posedge clk);

        if (s_arready) begin
          accepted = 1'b1;
          break;
        end

        waited = waited + 1;
      end

      @(negedge clk);
      s_arvalid = 1'b0;
    end
  endtask


  task automatic drive_aw(
      input  logic [ID_W-1:0]   id_v,
      input  logic [ADDR_W-1:0] addr_v,
      input  logic [7:0]        len_v,
      input  logic [2:0]        size_v,
      input  logic [1:0]        burst_v,
      input  integer            budget,
      output bit                accepted,
      output integer            waited
  );
    begin
      accepted = 1'b0;
      waited   = 0;

      @(negedge clk);

      s_awid    = id_v;
      s_awaddr  = addr_v;
      s_awlen   = len_v;
      s_awsize  = size_v;
      s_awburst = burst_v;
      s_awvalid = 1'b1;

      while (waited < budget) begin
        @(posedge clk);

        if (s_awready) begin
          accepted = 1'b1;
          break;
        end

        waited = waited + 1;
      end

      @(negedge clk);
      s_awvalid = 1'b0;
    end
  endtask


  task automatic drive_wide_w(
      input logic [SLV_DATA_W-1:0]   data_v,
      input logic [SLV_DATA_W/8-1:0] strb_v,
      input logic                    last_v
  );
    integer n;
    bit accepted;

    begin
      accepted = 1'b0;

      @(negedge clk);

      s_wdata  = data_v;
      s_wstrb  = strb_v;
      s_wlast  = last_v;
      s_wvalid = 1'b1;

      for (n = 0; n < WAIT_LIMIT; n = n + 1) begin
        @(posedge clk);

        if (s_wready) begin
          accepted = 1'b1;
          break;
        end
      end

      if (!accepted)
        fail_req(
            "E1",
            "upstream W beat was never accepted"
        );

      @(negedge clk);
      s_wvalid = 1'b0;
    end
  endtask


  // ==========================================================================
  // Downstream response BFMs
  // ==========================================================================

  task automatic drive_narrow_r(
      input logic [ID_W-1:0]       id_v,
      input logic [MST_DATA_W-1:0] data_v,
      input logic [1:0]            resp_v,
      input logic                  last_v
  );
    integer n;
    bit accepted;

    begin
      accepted = 1'b0;

      @(negedge clk);

      m_rid    = id_v;
      m_rdata  = data_v;
      m_rresp  = resp_v;
      m_rlast  = last_v;
      m_rvalid = 1'b1;

      for (n = 0; n < WAIT_LIMIT; n = n + 1) begin
        @(posedge clk);

        if (m_rready) begin
          accepted = 1'b1;
          break;
        end
      end

      if (!accepted)
        fail_req(
            "D1",
            "downstream R beat was never accepted"
        );

      @(negedge clk);
      m_rvalid = 1'b0;
    end
  endtask


  task automatic drive_narrow_b(
      input logic [ID_W-1:0] id_v,
      input logic [1:0]      resp_v
  );
    integer n;
    bit accepted;

    begin
      accepted = 1'b0;

      @(negedge clk);

      m_bid    = id_v;
      m_bresp  = resp_v;
      m_bvalid = 1'b1;

      for (n = 0; n < WAIT_LIMIT; n = n + 1) begin
        @(posedge clk);

        if (m_bready) begin
          accepted = 1'b1;
          break;
        end
      end

      if (!accepted)
        fail_req(
            "E5",
            "downstream B response was never accepted"
        );

      @(negedge clk);
      m_bvalid = 1'b0;
    end
  endtask


  // ==========================================================================
  // Counter waits
  // ==========================================================================

  task automatic wait_m_ar(
      input integer target,
      input string req_name
  );
    integer n;
    bit done;

    begin
      done = 1'b0;

      for (n = 0; n < WAIT_LIMIT; n = n + 1) begin
        @(negedge clk);

        if (m_ar_count >= target) begin
          done = 1'b1;
          break;
        end
      end

      if (!done)
        fail_req(
            req_name,
            "expected downstream AR transaction never appeared"
        );
    end
  endtask


  task automatic wait_m_aw(
      input integer target,
      input string req_name
  );
    integer n;
    bit done;

    begin
      done = 1'b0;

      for (n = 0; n < WAIT_LIMIT; n = n + 1) begin
        @(negedge clk);

        if (m_aw_count >= target) begin
          done = 1'b1;
          break;
        end
      end

      if (!done)
        fail_req(
            req_name,
            "expected downstream AW transaction never appeared"
        );
    end
  endtask


  task automatic wait_m_w(
      input integer target,
      input string req_name
  );
    integer n;
    bit done;

    begin
      done = 1'b0;

      for (n = 0; n < WAIT_LIMIT; n = n + 1) begin
        @(negedge clk);

        if (m_w_count >= target) begin
          done = 1'b1;
          break;
        end
      end

      if (!done)
        fail_req(
            req_name,
            "expected downstream W beats never all appeared"
        );
    end
  endtask


  task automatic wait_s_r(
      input integer target,
      input string req_name
  );
    integer n;
    bit done;

    begin
      done = 1'b0;

      for (n = 0; n < WAIT_LIMIT; n = n + 1) begin
        @(negedge clk);

        if (s_r_count >= target) begin
          done = 1'b1;
          break;
        end
      end

      if (!done)
        fail_req(
            req_name,
            "expected upstream R response never completed"
        );
    end
  endtask


  task automatic wait_s_b(
      input integer target,
      input string req_name
  );
    integer n;
    bit done;

    begin
      done = 1'b0;

      for (n = 0; n < WAIT_LIMIT; n = n + 1) begin
        @(negedge clk);

        if (s_b_count >= target) begin
          done = 1'b1;
          break;
        end
      end

      if (!done)
        fail_req(
            req_name,
            "expected upstream B response never completed"
        );
    end
  endtask


  // ==========================================================================
  // Address checks
  // ==========================================================================

  task automatic check_ar_record(
      input integer            idx,
      input logic [ID_W-1:0]   exp_id,
      input logic [ADDR_W-1:0] exp_addr,
      input logic [7:0]        exp_len,
      input logic [2:0]        exp_size
  );
    begin
      if (idx >= m_ar_count) begin
        fail_req(
            "A2",
            "missing downstream AR record"
        );
      end
      else begin

        if (m_ar_log[idx].id != exp_id)
          fail_req(
              "A2",
              "downstream AR ID differs from upstream ID"
          );

        if (m_ar_log[idx].addr != exp_addr)
          fail_req(
              "B3",
              "downstream AR address was realigned or otherwise changed"
          );

        if (m_ar_log[idx].len != exp_len)
          fail_req(
              "B2",
              "downstream AR length is not the required block-span count"
          );

        if (m_ar_log[idx].size != exp_size)
          fail_req(
              "B1",
              "downstream AR size is not min(upstream size,1)"
          );

        if (
            (exp_len != 0) &&
            (m_ar_log[idx].burst != BURST_INCR)
        )
          fail_req(
              "B4",
              "multi-beat downstream AR burst was not INCR"
          );

      end
    end
  endtask


  task automatic check_aw_record(
      input integer            idx,
      input logic [ID_W-1:0]   exp_id,
      input logic [ADDR_W-1:0] exp_addr,
      input logic [7:0]        exp_len,
      input logic [2:0]        exp_size
  );
    begin
      if (idx >= m_aw_count) begin
        fail_req(
            "A2",
            "missing downstream AW record"
        );
      end
      else begin

        if (m_aw_log[idx].id != exp_id)
          fail_req(
              "A2",
              "downstream AW ID differs from upstream ID"
          );

        if (m_aw_log[idx].addr != exp_addr)
          fail_req(
              "B3",
              "downstream AW address was realigned or otherwise changed"
          );

        if (m_aw_log[idx].len != exp_len)
          fail_req(
              "B2",
              "downstream AW length is not the required block-span count"
          );

        if (m_aw_log[idx].size != exp_size)
          fail_req(
              "B1",
              "downstream AW size is not min(upstream size,1)"
          );

        if (
            (exp_len != 0) &&
            (m_aw_log[idx].burst != BURST_INCR)
        )
          fail_req(
              "B4",
              "multi-beat downstream AW burst was not INCR"
          );

      end
    end
  endtask


  task automatic check_sr(
      input integer                idx,
      input logic [ID_W-1:0]       exp_id,
      input logic [SLV_DATA_W-1:0] exp_data,
      input logic [SLV_DATA_W-1:0] data_mask,
      input logic [1:0]            exp_resp,
      input logic                  exp_last
  );
    begin
      if (idx >= s_r_count) begin
        fail_req(
            "A3",
            "missing upstream R beat"
        );
      end
      else begin

        if (s_r_log[idx].id != exp_id)
          fail_req(
              "D3",
              "upstream RID does not match transaction ID"
          );

        if (
            (s_r_log[idx].data & data_mask) !=
            (exp_data          & data_mask)
        )
          fail_req(
              "D1",
              "upstream R byte stream/data placement is incorrect"
          );

        if (s_r_log[idx].resp != exp_resp)
          fail_req(
              "D6",
              "upstream R response does not implement required error propagation"
          );

        if (s_r_log[idx].last != exp_last)
          fail_req(
              "D4",
              "s_rlast is asserted on the wrong upstream beat"
          );

      end
    end
  endtask


  task automatic check_sb(
      input integer          idx,
      input logic [ID_W-1:0] exp_id,
      input logic [1:0]      exp_resp
  );
    begin
      if (idx >= s_b_count) begin
        fail_req(
            "A3",
            "missing upstream B response"
        );
      end
      else begin

        if (s_b_log[idx].id != exp_id)
          fail_req(
              "E5",
              "upstream BID does not match transaction ID"
          );

        if (s_b_log[idx].resp != exp_resp)
          fail_req(
              "E6",
              "upstream B response did not preserve downstream response code"
          );

      end
    end
  endtask


  task automatic check_mw(
      input integer                  idx,
      input logic [MST_DATA_W-1:0]   exp_data,
      input logic [MST_DATA_W/8-1:0] exp_strb,
      input logic                    exp_last
  );
    begin
      if (idx >= m_w_count) begin
        fail_req(
            "E1",
            "missing downstream W beat"
        );
      end
      else begin

        if (m_w_log[idx].data != exp_data)
          fail_req(
              "E1",
              "downstream W byte stream is incorrect"
          );

        if (m_w_log[idx].strb != exp_strb)
          fail_req(
              "E2",
              "downstream W strobes were not split into the correct byte lanes"
          );

        if (m_w_log[idx].last != exp_last)
          fail_req(
              "E4",
              "m_wlast is asserted on the wrong narrow beat"
          );

      end
    end
  endtask


  // ==========================================================================
  // Reset / idle helper
  // ==========================================================================

  task automatic clean_reset;
    integer n;

    begin
      @(negedge clk);

      s_awvalid = 1'b0;
      s_wvalid  = 1'b0;
      s_arvalid = 1'b0;

      m_bvalid  = 1'b0;
      m_rvalid  = 1'b0;

      s_bready  = 1'b1;
      s_rready  = 1'b1;

      m_awready = 1'b1;
      m_wready  = 1'b1;
      m_arready = 1'b1;

      bfm_reset(4);

      /*
       * F2 is unambiguous: after reset release the converter is idle.
       */
      for (n = 0; n < 3; n = n + 1) begin
        @(posedge clk);

        if (
            m_awvalid ||
            m_wvalid  ||
            m_arvalid ||
            s_bvalid  ||
            s_rvalid
        )
          fail_req(
              "F2",
              "converter was not idle after reset release"
          );

      end
    end
  endtask


  // ==========================================================================
  // Basic read: aligned 64-bit beats -> eight 16-bit beats
  // ==========================================================================

  task automatic test_read_aligned;
    integer ar_base;
    integer sr_base;
    integer i;
    integer waited;
    bit accepted;
    logic [15:0] data_v;

    begin
      clean_reset();

      ar_base = m_ar_count;
      sr_base = s_r_count;

      drive_ar(
          4'h1,
          32'h0000_1000,
          8'd1,
          3'd3,
          BURST_INCR,
          WAIT_LIMIT,
          accepted,
          waited
      );

      if (!accepted)
        fail_req(
            "A1",
            "legal aligned read was never accepted"
        );

      wait_m_ar(
          ar_base + 1,
          "A2"
      );

      check_ar_record(
          ar_base,
          4'h1,
          32'h0000_1000,
          8'd7,
          3'd1
      );

      for (i = 0; i < 8; i = i + 1) begin

        data_v =
            (((2*i)+2) << 8) |
            ((2*i)+1);

        drive_narrow_r(
            4'h1,
            data_v,
            RESP_OKAY,
            (i == 7)
        );

      end

      wait_s_r(
          sr_base + 2,
          "A3"
      );

      check_sr(
          sr_base,
          4'h1,
          64'h0807_0605_0403_0201,
          64'hFFFF_FFFF_FFFF_FFFF,
          RESP_OKAY,
          1'b0
      );

      check_sr(
          sr_base + 1,
          4'h1,
          64'h100F_0E0D_0C0B_0A09,
          64'hFFFF_FFFF_FFFF_FFFF,
          RESP_OKAY,
          1'b1
      );

      if (m_ar_count != ar_base + 1)
        fail_req(
            "A2",
            "one upstream read produced more than one downstream AR"
        );

      if (s_r_count != sr_base + 2)
        fail_req(
            "A3",
            "upstream read produced the wrong number of R beats"
        );

    end
  endtask


  // ==========================================================================
  // Unaligned 64-bit read: first upstream beat occupies lanes 4..7
  // ==========================================================================

  task automatic test_read_unaligned;
    integer ar_base;
    integer sr_base;
    integer i;
    integer waited;
    bit accepted;
    logic [15:0] data_v;

    begin
      clean_reset();

      ar_base = m_ar_count;
      sr_base = s_r_count;

      drive_ar(
          4'h2,
          32'h0000_1104,
          8'd1,
          3'd3,
          BURST_INCR,
          WAIT_LIMIT,
          accepted,
          waited
      );

      if (!accepted)
        fail_req(
            "A1",
            "legal unaligned read was never accepted"
        );

      wait_m_ar(
          ar_base + 1,
          "A2"
      );

      /*
       * The important B2 case:
       * len=1,size=3,@+4 -> downstream len = 5.
       */
      check_ar_record(
          ar_base,
          4'h2,
          32'h0000_1104,
          8'd5,
          3'd1
      );

      for (i = 0; i < 6; i = i + 1) begin

        data_v =
            (((2*i)+2) << 8) |
            ((2*i)+1);

        drive_narrow_r(
            4'h2,
            data_v,
            RESP_OKAY,
            (i == 5)
        );

      end

      wait_s_r(
          sr_base + 2,
          "A3"
      );

      /*
       * Addresses 0x1104..0x1107 belong in upstream lanes 4..7.
       * Lanes 0..3 are not part of the transaction and are not checked.
       */
      check_sr(
          sr_base,
          4'h2,
          64'h0403_0201_0000_0000,
          64'hFFFF_FFFF_0000_0000,
          RESP_OKAY,
          1'b0
      );

      check_sr(
          sr_base + 1,
          4'h2,
          64'h0C0B_0A09_0807_0605,
          64'hFFFF_FFFF_FFFF_FFFF,
          RESP_OKAY,
          1'b1
      );

    end
  endtask


  // ==========================================================================
  // B1/B2 small transfer cases
  // ==========================================================================

  task automatic test_small_sizes;
    integer ar_base;
    integer sr_base;
    integer waited;
    bit accepted;

    begin
      clean_reset();

      /*
       * size=1 @ odd address:
       * one byte remains, but it still spans one downstream block -> len=0.
       */
      ar_base = m_ar_count;
      sr_base = s_r_count;

      drive_ar(
          4'h3,
          32'h0000_1201,
          8'd0,
          3'd1,
          BURST_INCR,
          WAIT_LIMIT,
          accepted,
          waited
      );

      if (!accepted)
        fail_req(
            "A1",
            "legal size-1 read was never accepted"
        );

      wait_m_ar(
          ar_base + 1,
          "A2"
      );

      check_ar_record(
          ar_base,
          4'h3,
          32'h0000_1201,
          8'd0,
          3'd1
      );

      drive_narrow_r(
          4'h3,
          16'hBBAA,
          RESP_OKAY,
          1'b1
      );

      wait_s_r(
          sr_base + 1,
          "A3"
      );

      /*
       * Payload is intentionally not checked in this edge case because the
       * contract does not explicitly spell out irrelevant downstream R lanes.
       */
      check_sr(
          sr_base,
          4'h3,
          64'h0,
          64'h0,
          RESP_OKAY,
          1'b1
      );


      /*
       * size=0 must remain size=0, not be forced to the narrow width.
       */
      ar_base = m_ar_count;
      sr_base = s_r_count;

      drive_ar(
          4'h4,
          32'h0000_1303,
          8'd0,
          3'd0,
          BURST_INCR,
          WAIT_LIMIT,
          accepted,
          waited
      );

      if (!accepted)
        fail_req(
            "A1",
            "legal size-0 read was never accepted"
        );

      wait_m_ar(
          ar_base + 1,
          "A2"
      );

      check_ar_record(
          ar_base,
          4'h4,
          32'h0000_1303,
          8'd0,
          3'd0
      );

      drive_narrow_r(
          4'h4,
          16'hCC55,
          RESP_OKAY,
          1'b1
      );

      wait_s_r(
          sr_base + 1,
          "A3"
      );

      check_sr(
          sr_base,
          4'h4,
          64'h0,
          64'h0,
          RESP_OKAY,
          1'b1
      );

    end
  endtask


  // ==========================================================================
  // FIXED len=0 is legal and becomes a multi-beat INCR narrow burst
  // ==========================================================================

  task automatic test_fixed_single_read;
    integer ar_base;
    integer sr_base;
    integer waited;
    integer i;
    bit accepted;
    logic [15:0] data_v;

    begin
      clean_reset();

      ar_base = m_ar_count;
      sr_base = s_r_count;

      drive_ar(
          4'h5,
          32'h0000_1400,
          8'd0,
          3'd3,
          BURST_FIXED,
          WAIT_LIMIT,
          accepted,
          waited
      );

      if (!accepted)
        fail_req(
            "C3",
            "FIXED len=0 read was refused"
        );

      wait_m_ar(
          ar_base + 1,
          "C3"
      );

      check_ar_record(
          ar_base,
          4'h5,
          32'h0000_1400,
          8'd3,
          3'd1
      );

      for (i = 0; i < 4; i = i + 1) begin

        data_v =
            (((2*i)+2) << 8) |
            ((2*i)+1);

        drive_narrow_r(
            4'h5,
            data_v,
            RESP_OKAY,
            (i == 3)
        );

      end

      wait_s_r(
          sr_base + 1,
          "A3"
      );

      check_sr(
          sr_base,
          4'h5,
          64'h0807_0605_0403_0201,
          64'hFFFF_FFFF_FFFF_FFFF,
          RESP_OKAY,
          1'b1
      );

    end
  endtask


  // ==========================================================================
  // Sticky read errors
  // ==========================================================================

  task automatic test_read_last_error;
    integer ar_base;
    integer sr_base;
    integer waited;
    integer i;
    bit accepted;
    logic [15:0] data_v;
    logic [1:0] resp_v;

    begin
      clean_reset();

      ar_base = m_ar_count;
      sr_base = s_r_count;

      drive_ar(
          4'h6,
          32'h0000_1500,
          8'd1,
          3'd3,
          BURST_INCR,
          WAIT_LIMIT,
          accepted,
          waited
      );

      if (!accepted)
        fail_req(
            "A1",
            "read error-precedence transaction was never accepted"
        );

      wait_m_ar(
          ar_base + 1,
          "A2"
      );

      check_ar_record(
          ar_base,
          4'h6,
          32'h0000_1500,
          8'd7,
          3'd1
      );

      for (i = 0; i < 8; i = i + 1) begin

        data_v =
            (((2*i)+2) << 8) |
            ((2*i)+1);

        if (i == 7)
          resp_v = RESP_DECERR;
        else
          resp_v = RESP_OKAY;

        drive_narrow_r(
            4'h6,
            data_v,
            resp_v,
            (i == 7)
        );

      end

      wait_s_r(
          sr_base + 2,
          "A3"
      );

      check_sr(
          sr_base,
          4'h6,
          64'h0807_0605_0403_0201,
          64'hFFFF_FFFF_FFFF_FFFF,
          RESP_OKAY,
          1'b0
      );

      check_sr(
          sr_base + 1,
          4'h6,
          64'h100F_0E0D_0C0B_0A09,
          64'hFFFF_FFFF_FFFF_FFFF,
          RESP_DECERR,
          1'b1
      );

      if (s_r_log[sr_base + 1].resp != RESP_DECERR)
        fail_req(
            "D7",
            "downstream DECERR was not preserved as DECERR upstream"
        );

    end
  endtask


  task automatic test_read_early_error;
    integer ar_base;
    integer sr_base;
    integer waited;
    integer i;
    bit accepted;
    logic [15:0] data_v;
    logic [1:0] resp_v;

    begin
      clean_reset();

      ar_base = m_ar_count;
      sr_base = s_r_count;

      drive_ar(
          4'h7,
          32'h0000_1600,
          8'd1,
          3'd3,
          BURST_INCR,
          WAIT_LIMIT,
          accepted,
          waited
      );

      if (!accepted)
        fail_req(
            "A1",
            "sticky-error read was never accepted"
        );

      wait_m_ar(
          ar_base + 1,
          "A2"
      );

      for (i = 0; i < 8; i = i + 1) begin

        data_v =
            (((2*i)+2) << 8) |
            ((2*i)+1);

        if (i == 3)
          resp_v = RESP_SLVERR;
        else
          resp_v = RESP_OKAY;

        drive_narrow_r(
            4'h7,
            data_v,
            resp_v,
            (i == 7)
        );

      end

      wait_s_r(
          sr_base + 2,
          "A3"
      );

      check_sr(
          sr_base,
          4'h7,
          64'h0807_0605_0403_0201,
          64'hFFFF_FFFF_FFFF_FFFF,
          RESP_SLVERR,
          1'b0
      );

      check_sr(
          sr_base + 1,
          4'h7,
          64'h100F_0E0D_0C0B_0A09,
          64'hFFFF_FFFF_FFFF_FFFF,
          RESP_SLVERR,
          1'b1
      );

    end
  endtask


  // ==========================================================================
  // Refused reads
  // ==========================================================================

  task automatic test_refused_read(
      input logic [1:0] burst_v,
      input logic [ID_W-1:0] id_v,
      input logic [ADDR_W-1:0] addr_v
  );
    integer ar_base;
    integer sr_base;
    integer waited;
    bit accepted;

    begin
      clean_reset();

      ar_base = m_ar_count;
      sr_base = s_r_count;

      drive_ar(
          id_v,
          addr_v,
          8'd1,
          3'd3,
          burst_v,
          WAIT_LIMIT,
          accepted,
          waited
      );

      if (!accepted)
        fail_req(
            "C4",
            "refused read was not accepted on the upstream AR channel"
        );

      wait_s_r(
          sr_base + 2,
          "C4"
      );

      if (m_ar_count != ar_base)
        fail_req(
            "C4",
            "refused read generated a downstream AR transaction"
        );

      check_sr(
          sr_base,
          id_v,
          64'h0,
          64'h0,
          RESP_SLVERR,
          1'b0
      );

      check_sr(
          sr_base + 1,
          id_v,
          64'h0,
          64'h0,
          RESP_SLVERR,
          1'b1
      );

      if (
          (s_r_log[sr_base].resp != RESP_SLVERR) ||
          (s_r_log[sr_base + 1].resp != RESP_SLVERR)
      )
        fail_req(
            "C4",
            "not every refused-read response beat carried SLVERR"
        );

    end
  endtask


  // ==========================================================================
  // Write: strobe splitting including zero-strobe narrow beats
  // ==========================================================================

  task automatic test_write_strb_split;
    integer aw_base;
    integer mw_base;
    integer sb_base;
    integer waited;
    bit accepted;

    begin
      clean_reset();

      aw_base = m_aw_count;
      mw_base = m_w_count;
      sb_base = s_b_count;

      drive_aw(
          4'h8,
          32'h0000_2000,
          8'd0,
          3'd3,
          BURST_INCR,
          WAIT_LIMIT,
          accepted,
          waited
      );

      if (!accepted)
        fail_req(
            "A1",
            "legal write was never accepted"
        );

      wait_m_aw(
          aw_base + 1,
          "A2"
      );

      check_aw_record(
          aw_base,
          4'h8,
          32'h0000_2000,
          8'd3,
          3'd1
      );

      drive_wide_w(
          64'h0807_0605_0403_0201,
          8'b1000_0001,
          1'b1
      );

      wait_m_w(
          mw_base + 4,
          "E1"
      );

      check_mw(
          mw_base,
          16'h0201,
          2'b01,
          1'b0
      );

      check_mw(
          mw_base + 1,
          16'h0403,
          2'b00,
          1'b0
      );

      check_mw(
          mw_base + 2,
          16'h0605,
          2'b00,
          1'b0
      );

      check_mw(
          mw_base + 3,
          16'h0807,
          2'b10,
          1'b1
      );

      /*
       * The two middle zero-strobe beats are REQUIRED by E3.
       */
      if (m_w_count != mw_base + 4)
        fail_req(
            "E3",
            "zero-strobe narrow beats were suppressed or extra W beats appeared"
        );

      drive_narrow_b(
          4'h8,
          RESP_DECERR
      );

      wait_s_b(
          sb_base + 1,
          "E5"
      );

      check_sb(
          sb_base,
          4'h8,
          RESP_DECERR
      );

      if (s_b_log[sb_base].resp != RESP_DECERR)
        fail_req(
            "E6",
            "downstream DECERR was not preserved on upstream B"
        );

    end
  endtask


  // ==========================================================================
  // Unaligned write
  // ==========================================================================

  task automatic test_write_unaligned;
    integer aw_base;
    integer mw_base;
    integer sb_base;
    integer waited;
    bit accepted;

    begin
      clean_reset();

      aw_base = m_aw_count;
      mw_base = m_w_count;
      sb_base = s_b_count;

      drive_aw(
          4'h9,
          32'h0000_2104,
          8'd0,
          3'd3,
          BURST_INCR,
          WAIT_LIMIT,
          accepted,
          waited
      );

      if (!accepted)
        fail_req(
            "A1",
            "legal unaligned write was never accepted"
        );

      wait_m_aw(
          aw_base + 1,
          "A2"
      );

      check_aw_record(
          aw_base,
          4'h9,
          32'h0000_2104,
          8'd1,
          3'd1
      );

      /*
       * Only upstream lanes 4..7 belong to this unaligned transfer.
       */
      drive_wide_w(
          64'h0807_0605_0403_0201,
          8'b1111_0000,
          1'b1
      );

      wait_m_w(
          mw_base + 2,
          "E1"
      );

      check_mw(
          mw_base,
          16'h0605,
          2'b11,
          1'b0
      );

      check_mw(
          mw_base + 1,
          16'h0807,
          2'b11,
          1'b1
      );

      drive_narrow_b(
          4'h9,
          RESP_OKAY
      );

      wait_s_b(
          sb_base + 1,
          "E5"
      );

      check_sb(
          sb_base,
          4'h9,
          RESP_OKAY
      );

    end
  endtask


  // ==========================================================================
  // Multi-upstream-beat write
  // ==========================================================================

  task automatic test_write_two_wide_beats;
    integer aw_base;
    integer mw_base;
    integer sb_base;
    integer waited;
    bit accepted;

    begin
      clean_reset();

      aw_base = m_aw_count;
      mw_base = m_w_count;
      sb_base = s_b_count;

      drive_aw(
          4'hA,
          32'h0000_2200,
          8'd1,
          3'd3,
          BURST_INCR,
          WAIT_LIMIT,
          accepted,
          waited
      );

      if (!accepted)
        fail_req(
            "A1",
            "two-beat write was never accepted"
        );

      wait_m_aw(
          aw_base + 1,
          "A2"
      );

      check_aw_record(
          aw_base,
          4'hA,
          32'h0000_2200,
          8'd7,
          3'd1
      );

      drive_wide_w(
          64'h1817_1615_1413_1211,
          8'hFF,
          1'b0
      );

      drive_wide_w(
          64'h2827_2625_2423_2221,
          8'hFF,
          1'b1
      );

      wait_m_w(
          mw_base + 8,
          "E1"
      );

      check_mw(mw_base + 0, 16'h1211, 2'b11, 1'b0);
      check_mw(mw_base + 1, 16'h1413, 2'b11, 1'b0);
      check_mw(mw_base + 2, 16'h1615, 2'b11, 1'b0);
      check_mw(mw_base + 3, 16'h1817, 2'b11, 1'b0);
      check_mw(mw_base + 4, 16'h2221, 2'b11, 1'b0);
      check_mw(mw_base + 5, 16'h2423, 2'b11, 1'b0);
      check_mw(mw_base + 6, 16'h2625, 2'b11, 1'b0);
      check_mw(mw_base + 7, 16'h2827, 2'b11, 1'b1);

      drive_narrow_b(
          4'hA,
          RESP_OKAY
      );

      wait_s_b(
          sb_base + 1,
          "E5"
      );

      check_sb(
          sb_base,
          4'hA,
          RESP_OKAY
      );

      if (m_aw_count != aw_base + 1)
        fail_req(
            "A2",
            "one upstream write generated multiple downstream AW transactions"
        );

      if (s_b_count != sb_base + 1)
        fail_req(
            "A3",
            "one upstream write generated multiple upstream B responses"
        );

    end
  endtask


  // ==========================================================================
  // Refused write
  // ==========================================================================

  task automatic test_refused_write(
      input logic [1:0] burst_v,
      input logic [ID_W-1:0] id_v,
      input logic [ADDR_W-1:0] addr_v
  );
    integer aw_base;
    integer mw_base;
    integer sb_base;
    integer waited;
    bit accepted;

    begin
      clean_reset();

      aw_base = m_aw_count;
      mw_base = m_w_count;
      sb_base = s_b_count;

      drive_aw(
          id_v,
          addr_v,
          8'd1,
          3'd3,
          burst_v,
          WAIT_LIMIT,
          accepted,
          waited
      );

      if (!accepted)
        fail_req(
            "C4",
            "refused write was not accepted on upstream AW"
        );

      /*
       * C4 requires the entire rejected W burst to be absorbed upstream.
       */
      drive_wide_w(
          64'h1122_3344_5566_7788,
          8'hFF,
          1'b0
      );

      drive_wide_w(
          64'h99AA_BBCC_DDEE_FF00,
          8'hFF,
          1'b1
      );

      wait_s_b(
          sb_base + 1,
          "C4"
      );

      if (m_aw_count != aw_base)
        fail_req(
            "C4",
            "refused write produced a downstream AW"
        );

      if (m_w_count != mw_base)
        fail_req(
            "C4",
            "refused write forwarded W data downstream"
        );

      if (s_b_log[sb_base].id != id_v)
        fail_req(
            "A3",
            "refused write B response used the wrong ID"
        );

      if (s_b_log[sb_base].resp != RESP_SLVERR)
        fail_req(
            "C4",
            "refused write did not return SLVERR"
        );

    end
  endtask


  // ==========================================================================
  // MAX_READS and reset discard
  // ==========================================================================

  task automatic test_read_capacity_and_reset;
    integer sr_base;
    integer waited;
    integer i;
    bit accepted;
    bit fifth_accepted;

    begin
      clean_reset();

      sr_base = s_r_count;

      /*
       * F2/A4 require capacity for four outstanding reads after reset.
       */
      for (i = 0; i < MAX_READS; i = i + 1) begin

        drive_ar(
            i[ID_W-1:0],
            32'h0000_7000 + (i * 16),
            8'd0,
            3'd0,
            BURST_INCR,
            WAIT_LIMIT,
            accepted,
            waited
        );

        if (!accepted)
          fail_req(
              "F2",
              "fewer than MAX_READS reads could be accepted after reset"
          );

      end


      /*
       * No downstream responses have been supplied, therefore none of the
       * four can have retired.  A fifth acceptance would exceed MAX_READS.
       */
      drive_ar(
          4'h4,
          32'h0000_7080,
          8'd0,
          3'd0,
          BURST_INCR,
          12,
          fifth_accepted,
          waited
      );

      if (fifth_accepted)
        fail_req(
            "A4",
            "more than MAX_READS reads were outstanding simultaneously"
        );

      if (s_r_count != sr_base)
        fail_req(
            "A3",
            "upstream read response appeared without a downstream R response"
        );


      /*
       * Reset discards all four reads.
       */
      @(negedge clk);

      s_arvalid = 1'b0;
      m_rvalid  = 1'b0;

      bfm_reset(4);

      repeat (2)
        @(posedge clk);


      /*
       * Present a stale pre-reset downstream response.  The DUT is free either
       * to accept or refuse it, but F3 forbids an upstream response.
       */
      sr_base = s_r_count;

      @(negedge clk);

      m_rid    = 4'h0;
      m_rdata  = 16'hCAFE;
      m_rresp  = RESP_OKAY;
      m_rlast  = 1'b1;
      m_rvalid = 1'b1;

      repeat (8)
        @(posedge clk);

      @(negedge clk);
      m_rvalid = 1'b0;

      repeat (3)
        @(posedge clk);

      if (s_r_count != sr_base)
        fail_req(
            "F3",
            "pre-reset read produced an upstream response after reset"
        );


      /*
       * Capacity must be available again.
       */
      for (i = 0; i < MAX_READS; i = i + 1) begin

        drive_ar(
            (i + 8),
            32'h0000_7100 + (i * 16),
            8'd0,
            3'd0,
            BURST_INCR,
            WAIT_LIMIT,
            accepted,
            waited
        );

        if (!accepted)
          fail_req(
              "F2",
              "read capacity was not restored after reset"
          );

      end

      clean_reset();
    end
  endtask


  // ==========================================================================
  // Write reset discard
  // ==========================================================================

  task automatic test_write_reset_discard;
    integer aw_base;
    integer sb_base;
    integer waited;
    bit accepted;

    begin
      clean_reset();

      aw_base = m_aw_count;
      sb_base = s_b_count;

      drive_aw(
          4'hE,
          32'h0000_7200,
          8'd0,
          3'd3,
          BURST_INCR,
          WAIT_LIMIT,
          accepted,
          waited
      );

      if (!accepted)
        fail_req(
            "A1",
            "pre-reset write was never accepted"
        );

      wait_m_aw(
          aw_base + 1,
          "A2"
      );

      drive_wide_w(
          64'h8877_6655_4433_2211,
          8'hFF,
          1'b1
      );

      /*
       * Do not provide B.  Reset while the transaction is outstanding.
       */
      @(negedge clk);
      bfm_reset(4);

      repeat (2)
        @(posedge clk);

      sb_base = s_b_count;

      /*
       * Stale pre-reset B response.
       */
      @(negedge clk);

      m_bid    = 4'hE;
      m_bresp  = RESP_OKAY;
      m_bvalid = 1'b1;

      repeat (8)
        @(posedge clk);

      @(negedge clk);
      m_bvalid = 1'b0;

      repeat (3)
        @(posedge clk);

      if (s_b_count != sb_base)
        fail_req(
            "F3",
            "pre-reset write produced an upstream B response after reset"
        );

      clean_reset();
    end
  endtask


  // ==========================================================================
  // Main
  // ==========================================================================

  initial begin : main_test
    fail_count = 0;

    m_ar_count = 0;
    m_aw_count = 0;
    m_w_count  = 0;
    s_r_count  = 0;
    s_b_count  = 0;

    initialise_inputs();


    // ------------------------------------------------------------------------
    // Address transformation and read data path
    // ------------------------------------------------------------------------

    test_read_aligned();

    test_read_unaligned();

    test_small_sizes();

    test_fixed_single_read();


    // ------------------------------------------------------------------------
    // Read response error precedence
    // ------------------------------------------------------------------------

    test_read_last_error();

    test_read_early_error();


    // ------------------------------------------------------------------------
    // Refusal rules
    // ------------------------------------------------------------------------

    test_refused_read(
        BURST_WRAP,
        4'hB,
        32'h0000_3000
    );

    test_refused_read(
        BURST_FIXED,
        4'hC,
        32'h0000_3100
    );


    // ------------------------------------------------------------------------
    // Write re-segmentation
    // ------------------------------------------------------------------------

    test_write_strb_split();

    test_write_unaligned();

    test_write_two_wide_beats();


    // ------------------------------------------------------------------------
    // Refused writes
    // ------------------------------------------------------------------------

    test_refused_write(
        BURST_WRAP,
        4'hD,
        32'h0000_4000
    );

    test_refused_write(
        BURST_FIXED,
        4'hF,
        32'h0000_4100
    );


    // ------------------------------------------------------------------------
    // Outstanding read bound and reset clearing
    // ------------------------------------------------------------------------

    test_read_capacity_and_reset();

    test_write_reset_discard();


    if (fail_count == 0)
      $display("RESULT: PASS");
    else
      $display("RESULT: FAIL");

    $finish;
  end


  // ==========================================================================
  // Unconditional watchdog
  // ==========================================================================

  initial begin
    #4_000_000;

    $display(
        "FAIL A3: watchdog expired before the testbench reached a verdict"
    );

    $display("RESULT: FAIL");

    $finish;
  end

endmodule