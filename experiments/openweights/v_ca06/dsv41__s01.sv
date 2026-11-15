// ---------------------------------------------------------------------------
// Testbench for dw_downsizer
// ---------------------------------------------------------------------------
module dw_downsizer_tb;

  // Parameters (pinned by spec)
  localparam int ADDR_W     = 32;
  localparam int ID_W       = 4;
  localparam int SLV_DATA_W = 64;
  localparam int MST_DATA_W = 16;
  localparam int MAX_READS  = 4;

  // -------------------------------------------------------------------------
  // DUT signals
  // -------------------------------------------------------------------------
  logic clk;
  logic rst_n;

  // Upstream (slave) port
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

  // Downstream (master) port
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

  // -------------------------------------------------------------------------
  // DUT instantiation
  // -------------------------------------------------------------------------
  dw_downsizer #(
    .ADDR_W     (ADDR_W),
    .ID_W       (ID_W),
    .SLV_DATA_W (SLV_DATA_W),
    .MST_DATA_W (MST_DATA_W),
    .MAX_READS  (MAX_READS)
  ) dut (
    .clk_i      (clk),
    .rst_ni     (rst_n),
    // upstream
    .s_awid     (s_awid),
    .s_awaddr   (s_awaddr),
    .s_awlen    (s_awlen),
    .s_awsize   (s_awsize),
    .s_awburst  (s_awburst),
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
    .s_arsize   (s_arsize),
    .s_arburst  (s_arburst),
    .s_arvalid  (s_arvalid),
    .s_arready  (s_arready),
    .s_rid      (s_rid),
    .s_rdata    (s_rdata),
    .s_rresp    (s_rresp),
    .s_rlast    (s_rlast),
    .s_rvalid   (s_rvalid),
    .s_rready   (s_rready),
    // downstream
    .m_awid     (m_awid),
    .m_awaddr   (m_awaddr),
    .m_awlen    (m_awlen),
    .m_awsize   (m_awsize),
    .m_awburst  (m_awburst),
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
    .m_arsize   (m_arsize),
    .m_arburst  (m_arburst),
    .m_arvalid  (m_arvalid),
    .m_arready  (m_arready),
    .m_rid      (m_rid),
    .m_rdata    (m_rdata),
    .m_rresp    (m_rresp),
    .m_rlast    (m_rlast),
    .m_rvalid   (m_rvalid),
    .m_rready   (m_rready)
  );

  // -------------------------------------------------------------------------
  // Clock generation
  // -------------------------------------------------------------------------
  initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
  end

  // -------------------------------------------------------------------------
  // Reset
  // -------------------------------------------------------------------------
  initial begin
    rst_n = 1'b0;
  end

  // -------------------------------------------------------------------------
  // Watchdog
  // -------------------------------------------------------------------------
  initial begin
    #4_000_000;
    $display("RESULT: FAIL (watchdog: no forward progress)");
    $finish;
  end

  // -------------------------------------------------------------------------
  // Provided plumbing (adapted)
  // -------------------------------------------------------------------------
  task automatic bfm_reset(input int cycles = 4);
    @(negedge clk);
    rst_n = 1'b0;
    repeat (cycles) @(posedge clk);
    @(negedge clk);
    rst_n = 1'b1;
  endtask

  task automatic bfm_ar(
    input  logic [ID_W-1:0]   id,
    input  logic [ADDR_W-1:0] addr,
    input  logic [7:0]        len,
    input  logic [2:0]        size,
    input  logic [1:0]        burst,
    input  int                budget,
    output bit                accepted,
    output int                waited
  );
    accepted = 1'b0; waited = 0;
    @(negedge clk);
    s_arid = id; s_araddr = addr; s_arlen = len; s_arsize = size; s_arburst = burst; s_arvalid = 1'b1;
    while (waited < budget) begin
      @(posedge clk);
      if (s_arready) begin accepted = 1'b1; break; end
      waited++;
    end
    @(negedge clk) s_arvalid = 1'b0;
  endtask

  task automatic bfm_aw(
    input  logic [ID_W-1:0]   id,
    input  logic [ADDR_W-1:0] addr,
    input  logic [7:0]        len,
    input  logic [2:0]        size,
    input  logic [1:0]        burst,
    input  int                budget,
    output bit                accepted,
    output int                waited
  );
    accepted = 1'b0; waited = 0;
    @(negedge clk);
    s_awid = id; s_awaddr = addr; s_awlen = len; s_awsize = size; s_awburst = burst; s_awvalid = 1'b1;
    while (waited < budget) begin
      @(posedge clk);
      if (s_awready) begin accepted = 1'b1; break; end
      waited++;
    end
    @(negedge clk) s_awvalid = 1'b0;
  endtask

  task automatic bfm_w(
    input logic [SLV_DATA_W-1:0]   data,
    input logic [SLV_DATA_W/8-1:0] strb,
    input logic                    last
  );
    @(negedge clk);
    s_wdata = data; s_wstrb = strb; s_wlast = last; s_wvalid = 1'b1;
    forever begin
      @(posedge clk);
      if (s_wready) break;
    end
    @(negedge clk) s_wvalid = 1'b0;
  endtask

  task automatic bfm_rbeat(
    input logic [ID_W-1:0]       mid,
    input logic [MST_DATA_W-1:0] data,
    input logic                  last,
    input logic [1:0]            resp
  );
    @(negedge clk);
    m_rid = mid; m_rdata = data; m_rlast = last; m_rresp = resp; m_rvalid = 1'b1;
    forever begin
      @(posedge clk);
      if (m_rready) break;
    end
    @(negedge clk) m_rvalid = 1'b0;
  endtask

  task automatic bfm_bbeat(
    input logic [ID_W-1:0] mid,
    input logic [1:0]      resp
  );
    @(negedge clk);
    m_bid = mid; m_bresp = resp; m_bvalid = 1'b1;
    forever begin
      @(posedge clk);
      if (m_bready) break;
    end
    @(negedge clk) m_bvalid = 1'b0;
  endtask

  // -------------------------------------------------------------------------
  // Helper functions
  // -------------------------------------------------------------------------
  function automatic int calc_dlen(
    input logic [ADDR_W-1:0] addr,
    input logic [7:0]        len,
    input logic [2:0]        size
  );
    int total_bytes;
    int first, last;
    int dsize;
    int dbeat_bytes;
    int aligned_first, aligned_last;
    dsize = (size > 1) ? 1 : size;
    dbeat_bytes = 1 << dsize;
    total_bytes = (len + 1) * (1 << size) - (addr - (addr & ~((1 << size) - 1)));
    first = addr;
    last = addr + total_bytes - 1;
    aligned_first = first & ~(dbeat_bytes - 1);
    aligned_last = last & ~(dbeat_bytes - 1);
    return (aligned_last - aligned_first) / dbeat_bytes;
  endfunction

  function automatic int get_upstream_beat(
    input logic [ADDR_W-1:0] addr,
    input logic [7:0]        len,
    input logic [2:0]        size,
    input int                A
  );
    int beat_bytes;
    int aligned_addr;
    int end0;
    beat_bytes = 1 << size;
    aligned_addr = addr & ~(beat_bytes - 1);
    end0 = aligned_addr + beat_bytes - 1;
    if (A <= end0) return 0;
    return 1 + (A - (end0 + 1)) / beat_bytes;
  endfunction

  // -------------------------------------------------------------------------
  // Transaction record types and queues
  // -------------------------------------------------------------------------
  typedef struct packed {
    logic [ID_W-1:0]   id;
    logic [ADDR_W-1:0] addr;
    logic [7:0]        len;
    logic [2:0]        size;
    logic [1:0]        burst;
  } addr_t;

  typedef struct packed {
    logic [MST_DATA_W-1:0]   data;
    logic [MST_DATA_W/8-1:0] strb;
    logic                    last;
  } wbeat_t;

  typedef struct packed {
    logic [ID_W-1:0]       id;
    logic [SLV_DATA_W-1:0] data;
    logic [1:0]            resp;
    logic                  last;
  } rbeat_t;

  typedef struct packed {
    logic [ID_W-1:0] id;
    logic [1:0]      resp;
  } bbeat_t;

  addr_t  m_ar_q[$];
  addr_t  m_aw_q[$];
  wbeat_t m_w_q[$];
  rbeat_t s_r_q[$];
  bbeat_t s_b_q[$];

  int fail_count = 0;

  // -------------------------------------------------------------------------
  // Monitors
  // -------------------------------------------------------------------------
  always @(posedge clk) begin
    if (rst_n && m_arvalid && m_arready) begin
      addr_t t;
      t.id = m_arid; t.addr = m_araddr; t.len = m_arlen; t.size = m_arsize; t.burst = m_arburst;
      m_ar_q.push_back(t);
    end
    if (rst_n && m_awvalid && m_awready) begin
      addr_t t;
      t.id = m_awid; t.addr = m_awaddr; t.len = m_awlen; t.size = m_awsize; t.burst = m_awburst;
      m_aw_q.push_back(t);
    end
    if (rst_n && m_wvalid && m_wready) begin
      wbeat_t t;
      t.data = m_wdata; t.strb = m_wstrb; t.last = m_wlast;
      m_w_q.push_back(t);
    end
    if (rst_n && s_rvalid && s_rready) begin
      rbeat_t t;
      t.id = s_rid; t.data = s_rdata; t.resp = s_rresp; t.last = s_rlast;
      s_r_q.push_back(t);
    end
    if (rst_n && s_bvalid && s_bready) begin
      bbeat_t t;
      t.id = s_bid; t.resp = s_bresp;
      s_b_q.push_back(t);
    end
  end

  always @(negedge rst_n) begin
    m_ar_q.delete();
    m_aw_q.delete();
    m_w_q.delete();
    s_r_q.delete();
    s_b_q.delete();
  end

  // -------------------------------------------------------------------------
  // Directed test tasks
  // -------------------------------------------------------------------------
  task automatic do_read_test(
    input logic [ID_W-1:0]   id,
    input logic [ADDR_W-1:0] addr,
    input logic [7:0]        len,
    input logic [2:0]        size,
    input logic [1:0]        burst,
    input bit                inject_error,
    input int                error_beat,
    input logic [1:0]        error_code
  );
    bit accepted;
    int waited;
    int dlen;
    int dsize;
    int dbeat_bytes;
    int total_bytes;
    int first, last;
    int aligned_first, aligned_last;
    int i, j, k;
    addr_t ar_t;
    rbeat_t r_t;
    logic [MST_DATA_W-1:0] m_data;
    logic [1:0] m_resp;
    logic [SLV_DATA_W-1:0] exp_data;
    logic [7:0] exp_byte;
    int beat_addr;
    int bytes_in_beat;
    int lane;
    int group_e;
    int e_block_start;
    int exp_resp;
    int start_addr, end_addr;
    int byte_addr;

    m_ar_q.delete();
    s_r_q.delete();

    bfm_ar(id, addr, len, size, burst, 100, accepted, waited);
    if (!accepted) begin
      $display("FAIL: A1 read address not accepted id=%0d addr=%h len=%0d size=%0d burst=%0d", id, addr, len, size, burst);
      fail_count++;
      return;
    end

    while (m_ar_q.size() == 0) @(posedge clk);
    ar_t = m_ar_q.pop_front();

    dsize = (size > 1) ? 1 : size;
    dbeat_bytes = 1 << dsize;
    total_bytes = (len + 1) * (1 << size) - (addr - (addr & ~((1 << size) - 1)));
    first = addr;
    last = addr + total_bytes - 1;
    aligned_first = first & ~(dbeat_bytes - 1);
    aligned_last = last & ~(dbeat_bytes - 1);
    dlen = (aligned_last - aligned_first) / dbeat_bytes;

    if (ar_t.id !== id) begin $display("FAIL: A2 read id mismatch exp=%0d got=%0d", id, ar_t.id); fail_count++; end
    if (ar_t.addr !== addr) begin $display("FAIL: B3 read addr mismatch exp=%h got=%h", addr, ar_t.addr); fail_count++; end
    if (ar_t.size !== dsize) begin $display("FAIL: B1 read size mismatch exp=%0d got=%0d", dsize, ar_t.size); fail_count++; end
    if (ar_t.len !== dlen) begin $display("FAIL: B2 read len mismatch exp=%0d got=%0d", dlen, ar_t.len); fail_count++; end
    if (dlen > 0 && ar_t.burst !== 2'b01) begin $display("FAIL: B4 read burst mismatch exp=INCR got=%0d", ar_t.burst); fail_count++; end

    for (i = 0; i <= dlen; i++) begin
      if (i == 0) beat_addr = addr;
      else        beat_addr = aligned_first + i * dbeat_bytes;
      m_data = '0;
      for (k = 0; k < dbeat_bytes; k++) begin
        byte_addr = (aligned_first + i * dbeat_bytes) + k;
        m_data[k*8 +: 8] = byte_addr[7:0];
      end
      m_resp = 2'b00;
      if (inject_error && i == error_beat) m_resp = error_code;
      bfm_rbeat(id, m_data, (i == dlen), m_resp);
    end

    for (j = 0; j <= len; j++) begin
      while (s_r_q.size() == 0) @(posedge clk);
      r_t = s_r_q.pop_front();

      if (burst == 2'b00) beat_addr = addr;
      else                beat_addr = addr + j * (1 << size);
      start_addr = addr + j * (1 << size);
      end_addr = start_addr + (1 << size) - 1;
      if (end_addr > addr + total_bytes - 1) end_addr = addr + total_bytes - 1;
      bytes_in_beat = end_addr - start_addr + 1;

      if (r_t.id !== id) begin $display("FAIL: D3 read id mismatch exp=%0d got=%0d", id, r_t.id); fail_count++; end
      if (r_t.last !== (j == len)) begin $display("FAIL: D4 read last mismatch beat=%0d exp=%0d got=%0d", j, (j==len), r_t.last); fail_count++; end

      if (inject_error) begin
        if (error_beat == 0) e_block_start = aligned_first;
        else                 e_block_start = aligned_first + error_beat * dbeat_bytes;
        group_e = get_upstream_beat(addr, len, size, e_block_start);
      end else begin
        group_e = 0;
      end

      exp_resp = 2'b00;
      if (inject_error && j >= group_e) exp_resp = error_code;
      if (r_t.resp !== exp_resp) begin
        $display("FAIL: D6/D7 read resp mismatch beat=%0d exp=%0d got=%0d", j, exp_resp, r_t.resp);
        fail_count++;
      end

      for (k = 0; k < bytes_in_beat; k++) begin
        byte_addr = start_addr + k;
        lane = byte_addr % 8;
        exp_byte = byte_addr[7:0];
        if (r_t.data[lane*8 +: 8] !== exp_byte) begin
          $display("FAIL: D1/D2 read data mismatch beat=%0d lane=%0d addr=%h exp=%02h got=%02h",
                   j, lane, byte_addr, exp_byte, r_t.data[lane*8 +: 8]);
          fail_count++;
        end
      end
    end

    if (s_r_q.size() != 0) begin
      $display("FAIL: A3 extra upstream R beats");
      fail_count++;
      s_r_q.delete();
    end
  endtask

  task automatic do_write_test(
    input logic [ID_W-1:0]   id,
    input logic [ADDR_W-1:0] addr,
    input logic [7:0]        len,
    input logic [2:0]        size,
    input logic [1:0]        burst,
    input int                strobe_mode, // 0: all valid, 1: 0x81, 2: 0x0F
    input bit                inject_error,
    input logic [1:0]        error_code
  );
    bit accepted;
    int waited;
    int dlen;
    int dsize;
    int dbeat_bytes;
    int total_bytes;
    int first, last;
    int aligned_first, aligned_last;
    int i, j, k, jj;
    addr_t aw_t;
    wbeat_t w_t;
    bbeat_t b_t;
    logic [MST_DATA_W-1:0] exp_m_data;
    logic [MST_DATA_W/8-1:0] exp_m_strb;
    logic [SLV_DATA_W-1:0] up_data[256];
    logic [SLV_DATA_W/8-1:0] up_strb[256];
    int up_start_addr[256];
    int up_end_addr[256];
    int beat_bytes;
    int offset;
    int start_addr, end_addr;
    int byte_addr;
    int lane;
    int found_j;
    logic [7:0] byte_val;
    bit byte_valid;
    int group;
    bit fail;

    m_aw_q.delete();
    m_w_q.delete();
    s_b_q.delete();

    dsize = (size > 1) ? 1 : size;
    dbeat_bytes = 1 << dsize;
    beat_bytes = 1 << size;
    total_bytes = (len + 1) * beat_bytes - (addr - (addr & ~(beat_bytes - 1)));
    first = addr;
    last = addr + total_bytes - 1;
    aligned_first = first & ~(dbeat_bytes - 1);
    aligned_last = last & ~(dbeat_bytes - 1);
    dlen = (aligned_last - aligned_first) / dbeat_bytes;

    for (j = 0; j <= len; j++) begin
      if (j == 0) up_start_addr[j] = addr;
      else        up_start_addr[j] = (addr & ~(beat_bytes - 1)) + j * beat_bytes;
      up_end_addr[j] = up_start_addr[j] + beat_bytes - 1;
      if (up_end_addr[j] > addr + total_bytes - 1) up_end_addr[j] = addr + total_bytes - 1;
      up_data[j] = '0;
      up_strb[j] = '0;
      for (k = 0; k < beat_bytes; k++) begin
        byte_addr = up_start_addr[j] + k;
        if (byte_addr >= addr && byte_addr <= addr + total_bytes - 1) begin
          lane = byte_addr % 8;
          up_data[j][lane*8 +: 8] = byte_addr[7:0];
          up_strb[j][lane] = 1'b1;
        end
      end
      if (strobe_mode == 1) begin
        for (k = 0; k < 8; k++) if (k != 0 && k != 7) up_strb[j][k] = 1'b0;
      end else if (strobe_mode == 2) begin
        for (k = 0; k < 8; k++) if (k > 3) up_strb[j][k] = 1'b0;
      end
    end

    bfm_aw(id, addr, len, size, burst, 100, accepted, waited);
    if (!accepted) begin
      $display("FAIL: A1 write address not accepted id=%0d addr=%h len=%0d size=%0d burst=%0d", id, addr, len, size, burst);
      fail_count++;
      return;
    end

    while (m_aw_q.size() == 0) @(posedge clk);
    aw_t = m_aw_q.pop_front();

    if (aw_t.id !== id) begin $display("FAIL: A2 write id mismatch exp=%0d got=%0d", id, aw_t.id); fail_count++; end
    if (aw_t.addr !== addr) begin $display("FAIL: B3 write addr mismatch exp=%h got=%h", addr, aw_t.addr); fail_count++; end
    if (aw_t.size !== dsize) begin $display("FAIL: B1 write size mismatch exp=%0d got=%0d", dsize, aw_t.size); fail_count++; end
    if (aw_t.len !== dlen) begin $display("FAIL: B2 write len mismatch exp=%0d got=%0d", dlen, aw_t.len); fail_count++; end
    if (dlen > 0 && aw_t.burst !== 2'b01) begin $display("FAIL: B4 write burst mismatch exp=INCR got=%0d", aw_t.burst); fail_count++; end

    for (j = 0; j <= len; j++) begin
      bfm_w(up_data[j], up_strb[j], (j == len));
    end

    for (i = 0; i <= dlen; i++) begin
      while (m_w_q.size() == 0) @(posedge clk);
      w_t = m_w_q.pop_front();

      exp_m_data = '0;
      exp_m_strb = '0;
      for (k = 0; k < dbeat_bytes; k++) begin
        byte_addr = aligned_first + i * dbeat_bytes + k;
        if (byte_addr >= addr && byte_addr <= addr + total_bytes - 1) begin
          found_j = -1;
          for (jj = 0; jj <= len; jj++) begin
            if (byte_addr >= up_start_addr[jj] && byte_addr <= up_end_addr[jj]) begin
              found_j = jj;
              break;
            end
          end
          if (found_j >= 0) begin
            lane = byte_addr % 8;
            if (up_strb[found_j][lane]) begin
              exp_m_data[k*8 +: 8] = up_data[found_j][lane*8 +: 8];
              exp_m_strb[k] = 1'b1;
            end
          end
        end
      end

      for (k = 0; k < dbeat_bytes; k++) begin
        if (w_t.strb[k] !== exp_m_strb[k]) begin
          $display("FAIL: E2 write strb mismatch beat=%0d lane=%0d exp=%0d got=%0d", i, k, exp_m_strb[k], w_t.strb[k]);
          fail_count++;
        end
        if (exp_m_strb[k] && w_t.data[k*8 +: 8] !== exp_m_data[k*8 +: 8]) begin
          $display("FAIL: E1 write data mismatch beat=%0d lane=%0d exp=%02h got=%02h",
                   i, k, exp_m_data[k*8 +: 8], w_t.data[k*8 +: 8]);
          fail_count++;
        end
      end
      if (w_t.last !== (i == dlen)) begin
        $display("FAIL: E4 write last mismatch beat=%0d exp=%0d got=%0d", i, (i==dlen), w_t.last);
        fail_count++;
      end
    end

    if (m_w_q.size() != 0) begin
      $display("FAIL: E3 extra downstream W beats");
      fail_count++;
      m_w_q.delete();
    end

    bfm_bbeat(id, inject_error ? error_code : 2'b00);

    while (s_b_q.size() == 0) @(posedge clk);
    b_t = s_b_q.pop_front();
    if (b_t.id !== id) begin $display("FAIL: E5 write B id mismatch exp=%0d got=%0d", id, b_t.id); fail_count++; end
    if (b_t.resp !== (inject_error ? error_code : 2'b00)) begin
      $display("FAIL: E6 write B resp mismatch exp=%0d got=%0d", (inject_error ? error_code : 2'b00), b_t.resp);
      fail_count++;
    end
    if (s_b_q.size() != 0) begin
      $display("FAIL: A3 extra upstream B beats");
      fail_count++;
      s_b_q.delete();
    end
  endtask

  task automatic do_refused_read_test(
    input logic [ID_W-1:0]   id,
    input logic [ADDR_W-1:0] addr,
    input logic [7:0]        len,
    input logic [2:0]        size,
    input logic [1:0]        burst
  );
    bit accepted;
    int waited;
    int i;
    rbeat_t r_t;

    m_ar_q.delete();
    s_r_q.delete();

    bfm_ar(id, addr, len, size, burst, 100, accepted, waited);
    if (!accepted) begin
      $display("FAIL: C4 refused read not accepted id=%0d addr=%h len=%0d size=%0d burst=%0d", id, addr, len, size, burst);
      fail_count++;
      return;
    end

    repeat (10) @(posedge clk);
    if (m_ar_q.size() != 0) begin
      $display("FAIL: C4 refused read produced downstream AR");
      fail_count++;
      m_ar_q.delete();
    end

    for (i = 0; i <= len; i++) begin
      while (s_r_q.size() == 0) @(posedge clk);
      r_t = s_r_q.pop_front();
      if (r_t.id !== id) begin $display("FAIL: C4 refused read id mismatch beat=%0d exp=%0d got=%0d", i, id, r_t.id); fail_count++; end
      if (r_t.resp !== 2'b10) begin $display("FAIL: C4 refused read resp mismatch beat=%0d exp=SLVERR got=%0d", i, r_t.resp); fail_count++; end
      if (r_t.last !== (i == len)) begin $display("FAIL: C4 refused read last mismatch beat=%0d exp=%0d got=%0d", i, (i==len), r_t.last); fail_count++; end
    end

    if (s_r_q.size() != 0) begin
      $display("FAIL: C4 refused read extra R beats");
      fail_count++;
      s_r_q.delete();
    end
  endtask

  task automatic do_refused_write_test(
    input logic [ID_W-1:0]   id,
    input logic [ADDR_W-1:0] addr,
    input logic [7:0]        len,
    input logic [2:0]        size,
    input logic [1:0]        burst
  );
    bit accepted;
    int waited;
    int i, b;
    bbeat_t b_t;
    logic [SLV_DATA_W-1:0] data;
    logic [SLV_DATA_W/8-1:0] strb;
    int start_addr, end_addr;
    int beat_bytes;
    int byte_addr;
    int lane;

    m_aw_q.delete();
    m_w_q.delete();
    s_b_q.delete();

    bfm_aw(id, addr, len, size, burst, 100, accepted, waited);
    if (!accepted) begin
      $display("FAIL: C4 refused write not accepted id=%0d addr=%h len=%0d size=%0d burst=%0d", id, addr, len, size, burst);
      fail_count++;
      return;
    end

    beat_bytes = 1 << size;
    for (i = 0; i <= len; i++) begin
      data = '0;
      strb = '0;
      if (i == 0) start_addr = addr;
      else        start_addr = (addr & ~(beat_bytes - 1)) + i * beat_bytes;
      end_addr = start_addr + beat_bytes - 1;
      for (b = 0; b < beat_bytes; b++) begin
        byte_addr = start_addr + b;
        lane = byte_addr % 8;
        strb[lane] = 1'b1;
        data[lane*8 +: 8] = byte_addr[7:0];
      end
      bfm_w(data, strb, (i == len));
    end

    repeat (10) @(posedge clk);
    if (m_aw_q.size() != 0) begin
      $display("FAIL: C4 refused write produced downstream AW");
      fail_count++;
      m_aw_q.delete();
    end
    if (m_w_q.size() != 0) begin
      $display("FAIL: C4 refused write produced downstream W");
      fail_count++;
      m_w_q.delete();
    end

    while (s_b_q.size() == 0) @(posedge clk);
    b_t = s_b_q.pop_front();
    if (b_t.id !== id) begin $display("FAIL: C4 refused write B id mismatch exp=%0d got=%0d", id, b_t.id); fail_count++; end
    if (b_t.resp !== 2'b10) begin $display("FAIL: C4 refused write B resp mismatch exp=SLVERR got=%0d", b_t.resp); fail_count++; end
    if (s_b_q.size() != 0) begin
      $display("FAIL: C4 refused write extra B beats");
      fail_count++;
      s_b_q.delete();
    end
  endtask

  // -------------------------------------------------------------------------
  // Main test sequence
  // -------------------------------------------------------------------------
  initial begin
    // Initialize all driven signals
    s_awid = 0; s_awaddr = 0; s_awlen = 0; s_awsize = 0; s_awburst = 0; s_awvalid = 0;
    s_wdata = 0; s_wstrb = 0; s_wlast = 0; s_wvalid = 0;
    s_bready = 1;
    s_arid = 0; s_araddr = 0; s_arlen = 0; s_arsize = 0; s_arburst = 0; s_arvalid = 0;
    s_rready = 1;
    m_awready = 1; m_arready = 1; m_wready = 1;
    m_bvalid = 0; m_bid = 0; m_bresp = 0;
    m_rvalid = 0; m_rid = 0; m_rdata = 0; m_rlast = 0; m_rresp = 0;

    // Initial reset
    bfm_reset(4);

    // F1: while reset low, no valid
    rst_n = 1'b0;
    repeat (2) @(posedge clk);
    if (s_awready !== 0 || s_wready !== 0 || s_bvalid !== 0 || s_arready !== 0 || s_rvalid !== 0 ||
        m_awvalid !== 0 || m_wvalid !== 0 || m_bready !== 0 || m_arvalid !== 0 || m_rready !== 0) begin
      $display("FAIL: F1 reset low outputs not zero");
      fail_count++;
    end
    bfm_reset(4);

    // F2: after reset idle, MAX_READS accepted
    for (int i = 0; i < 4; i++) begin
      bit acc; int w;
      bfm_ar(i[3:0], 32'h1000 + i*16, 8'd0, 3'd3, 2'b01, 100, acc, w);
      if (!acc) begin $display("FAIL: F2 read %0d not accepted after reset", i); fail_count++; end
    end
    bit acc5; int w5;
    bfm_ar(4'd4, 32'h2000, 8'd0, 3'd3, 2'b01, 20, acc5, w5);
    if (acc5) begin $display("FAIL: A4 5th read accepted while 4 outstanding"); fail_count++; end

    for (int i = 0; i < 4; i++) begin
      addr_t ar;
      while (m_ar_q.size() == 0) @(posedge clk);
      ar = m_ar_q.pop_front();
      int dlen = calc_dlen(ar.addr, ar.len, ar.size);
      for (int b = 0; b <= dlen; b++) begin
        bfm_rbeat(ar.id, 16'h0000, (b == dlen), 2'b00);
      end
    end

    bfm_ar(4'd4, 32'h2000, 8'd0, 3'd3, 2'b01, 100, acc5, w5);
    if (!acc5) begin $display("FAIL: A4 5th read not accepted after responses"); fail_count++; end
    addr_t ar5;
    while (m_ar_q.size() == 0) @(posedge clk);
    ar5 = m_ar_q.pop_front();
    int dlen5 = calc_dlen(ar5.addr, ar5.len, ar5.size);
    for (int b = 0; b <= dlen5; b++) begin
      bfm_rbeat(ar5.id, 16'h0000, (b == dlen5), 2'b00);
    end
    repeat (10) @(posedge clk);

    // Read tests
    do_read_test(4'd1, 32'h1000, 8'd1, 3'd3, 2'b01, 0, 0, 2'b00);
    do_read_test(4'd2, 32'h1004, 8'd1, 3'd3, 2'b01, 0, 0, 2'b00);
    do_read_test(4'd3, 32'h1001, 8'd0, 3'd1, 2'b01, 0, 0, 2'b00);
    do_read_test(4'd4, 32'h1000, 8'd0, 3'd0, 2'b01, 0, 0, 2'b00);
    do_read_test(4'd5, 32'h1000, 8'd0, 3'd3, 2'b00, 0, 0, 2'b00); // FIXED len0 (C3)
    do_read_test(4'd6, 32'h1000, 8'd1, 3'd3, 2'b01, 1, 0, 2'b10);
    do_read_test(4'd7, 32'h1000, 8'd1, 3'd3, 2'b01, 1, 3, 2'b10);
    do_read_test(4'd8, 32'h1000, 8'd1, 3'd3, 2'b01, 1, 7, 2'b10);
    do_read_test(4'd9, 32'h1000, 8'd1, 3'd3, 2'b01, 1, 0, 2'b11);

    // Refused reads
    do_refused_read_test(4'd10, 32'h1000, 8'd1, 3'd3, 2'b10); // WRAP
    do_refused_read_test(4'd11, 32'h1000, 8'd1, 3'd3, 2'b00); // FIXED len1

    // Write tests
    do_write_test(4'd12, 32'h1000, 8'd1, 3'd3, 2'b01, 0, 0, 2'b00);
    do_write_test(4'd13, 32'h1004, 8'd1, 3'd3, 2'b01, 0, 0, 2'b00);
    do_write_test(4'd14, 32'h1000, 8'd0, 3'd3, 2'b01, 1, 0, 2'b00); // strobe 0x81
    do_write_test(4'd15, 32'h1000, 8'd0, 3'd3, 2'b01, 2, 0, 2'b00); // strobe 0x0F
    do_write_test(4'd16, 32'h1000, 8'd0, 3'd3, 2'b00, 0, 0, 2'b00); // FIXED len0 (C3)
    do_write_test(4'd17, 32'h1000, 8'd0, 3'd3, 2'b01, 0, 1, 2'b10);
    do_write_test(4'd18, 32'h1000, 8'd0, 3'd3, 2'b01, 0, 1, 2'b11);

    // Refused writes
    do_refused_write_test(4'd19, 32'h1000, 8'd1, 3'd3, 2'b10); // WRAP
    do_refused_write_test(4'd20, 32'h1000, 8'd1, 3'd3, 2'b00); // FIXED len1

    // F3: reset during transaction, no response after
    m_ar_q.delete(); s_r_q.delete();
    bit acc_r; int w_r;
    bfm_ar(4'd21, 32'h3000, 8'd0, 3'd3, 2'b01, 100, acc_r, w_r);
    if (!acc_r) begin $display("FAIL: F3 read not accepted"); fail_count++; end
    while (m_ar_q.size() == 0) @(posedge clk);
    @(negedge clk);
    rst_n = 1'b0;
    repeat (2) @(posedge clk);
    @(negedge clk);
    rst_n = 1'b1;
    repeat (20) @(posedge clk);
    if (s_r_q.size() != 0) begin
      $display("FAIL: F3 response after reset");
      fail_count++;
      s_r_q.delete();
    end

    // Final result
    if (fail_count == 0) $display("RESULT: PASS");
    else                 $display("RESULT: FAIL");
    $finish;
  end

endmodule
