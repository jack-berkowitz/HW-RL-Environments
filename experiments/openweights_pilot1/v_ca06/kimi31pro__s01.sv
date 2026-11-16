`timescale 1ns/1ps

module id_width_conv_tb;

  localparam int unsigned ADDR_W     = 32;
  localparam int unsigned ID_W       = 4;
  localparam int unsigned SLV_DATA_W = 64;
  localparam int unsigned MST_DATA_W = 16;
  localparam int unsigned MAX_READS  = 4;

  localparam logic [1:0] AXI_OKAY   = 2'b00;
  localparam logic [1:0] AXI_SLVERR = 2'b10;
  localparam logic [1:0] AXI_DECERR = 2'b11;

  localparam logic [1:0] AXI_FIXED = 2'b00;
  localparam logic [1:0] AXI_INCR  = 2'b01;
  localparam logic [1:0] AXI_WRAP  = 2'b10;

  logic clk;
  logic rst_n;

  logic [ID_W-1:0]         s_awid;
  logic [ADDR_W-1:0]       s_awaddr;
  logic [7:0]              s_awlen;
  logic [2:0]              s_awsize;
  logic [1:0]              s_awburst;
  logic                    s_awvalid;
  logic                    s_awready;
  logic [SLV_DATA_W-1:0]   s_wdata;
  logic [SLV_DATA_W/8-1:0] s_wstrb;
  logic                    s_wlast;
  logic                    s_wvalid;
  logic                    s_wready;
  logic [ID_W-1:0]         s_bid;
  logic [1:0]              s_bresp;
  logic                    s_bvalid;
  logic                    s_bready;
  logic [ID_W-1:0]         s_arid;
  logic [ADDR_W-1:0]       s_araddr;
  logic [7:0]              s_arlen;
  logic [2:0]              s_arsize;
  logic [1:0]              s_arburst;
  logic                    s_arvalid;
  logic                    s_arready;
  logic [ID_W-1:0]         s_rid;
  logic [SLV_DATA_W-1:0]   s_rdata;
  logic [1:0]              s_rresp;
  logic                    s_rlast;
  logic                    s_rvalid;
  logic                    s_rready;

  logic [ID_W-1:0]         m_awid;
  logic [ADDR_W-1:0]       m_awaddr;
  logic [7:0]              m_awlen;
  logic [2:0]              m_awsize;
  logic [1:0]              m_awburst;
  logic                    m_awvalid;
  logic                    m_awready;
  logic [MST_DATA_W-1:0]   m_wdata;
  logic [MST_DATA_W/8-1:0] m_wstrb;
  logic                    m_wlast;
  logic                    m_wvalid;
  logic                    m_wready;
  logic [ID_W-1:0]         m_bid;
  logic [1:0]              m_bresp;
  logic                    m_bvalid;
  logic                    m_bready;
  logic [ID_W-1:0]         m_arid;
  logic [ADDR_W-1:0]       m_araddr;
  logic [7:0]              m_arlen;
  logic [2:0]              m_arsize;
  logic [1:0]              m_arburst;
  logic                    m_arvalid;
  logic                    m_arready;
  logic [ID_W-1:0]         m_rid;
  logic [MST_DATA_W-1:0]   m_rdata;
  logic [1:0]              m_rresp;
  logic                    m_rlast;
  logic                    m_rvalid;
  logic                    m_rready;

  dw_downsizer #(
    .ADDR_W     (ADDR_W),
    .ID_W       (ID_W),
    .SLV_DATA_W (SLV_DATA_W),
    .MST_DATA_W (MST_DATA_W),
    .MAX_READS  (MAX_READS)
  ) dut (
    .clk_i     (clk),
    .rst_ni    (rst_n),

    .s_awid    (s_awid),
    .s_awaddr  (s_awaddr),
    .s_awlen   (s_awlen),
    .s_awsize  (s_awsize),
    .s_awburst (s_awburst),
    .s_awvalid (s_awvalid),
    .s_awready (s_awready),
    .s_wdata   (s_wdata),
    .s_wstrb   (s_wstrb),
    .s_wlast   (s_wlast),
    .s_wvalid  (s_wvalid),
    .s_wready  (s_wready),
    .s_bid     (s_bid),
    .s_bresp   (s_bresp),
    .s_bvalid  (s_bvalid),
    .s_bready  (s_bready),
    .s_arid    (s_arid),
    .s_araddr  (s_araddr),
    .s_arlen   (s_arlen),
    .s_arsize  (s_arsize),
    .s_arburst (s_arburst),
    .s_arvalid (s_arvalid),
    .s_arready (s_arready),
    .s_rid     (s_rid),
    .s_rdata   (s_rdata),
    .s_rresp   (s_rresp),
    .s_rlast   (s_rlast),
    .s_rvalid  (s_rvalid),
    .s_rready  (s_rready),

    .m_awid    (m_awid),
    .m_awaddr  (m_awaddr),
    .m_awlen   (m_awlen),
    .m_awsize  (m_awsize),
    .m_awburst (m_awburst),
    .m_awvalid (m_awvalid),
    .m_awready (m_awready),
    .m_wdata   (m_wdata),
    .m_wstrb   (m_wstrb),
    .m_wlast   (m_wlast),
    .m_wvalid  (m_wvalid),
    .m_wready  (m_wready),
    .m_bid     (m_bid),
    .m_bresp   (m_bresp),
    .m_bvalid  (m_bvalid),
    .m_bready  (m_bready),
    .m_arid    (m_arid),
    .m_araddr  (m_araddr),
    .m_arlen   (m_arlen),
    .m_arsize  (m_arsize),
    .m_arburst (m_arburst),
    .m_arvalid (m_arvalid),
    .m_arready (m_arready),
    .m_rid     (m_rid),
    .m_rdata   (m_rdata),
    .m_rresp   (m_rresp),
    .m_rlast   (m_rlast),
    .m_rvalid  (m_rvalid),
    .m_rready  (m_rready)
  );

  typedef struct packed {
    logic [ID_W-1:0]   id;
    logic [ADDR_W-1:0] addr;
    logic [7:0]        len;
    logic [2:0]        size;
    logic [1:0]        burst;
  } ax_rec_t;

  typedef struct packed {
    logic [MST_DATA_W-1:0]   data;
    logic [MST_DATA_W/8-1:0] strb;
    logic                    last;
  } w_rec_t;

  typedef struct packed {
    logic [ID_W-1:0]       id;
    logic [SLV_DATA_W-1:0] data;
    logic [1:0]            resp;
    logic                  last;
  } r_rec_t;

  typedef struct packed {
    logic [ID_W-1:0] id;
    logic [1:0]      resp;
  } b_rec_t;

  ax_rec_t m_aw_q[$];
  ax_rec_t m_ar_q[$];
  w_rec_t  m_w_q[$];
  r_rec_t  s_r_q[$];
  b_rec_t  s_b_q[$];

  int errors;
  bit finished;

  initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
  end

  initial rst_n = 1'b0;

  function automatic logic [31:0] align_to(
    input logic [31:0] addr,
    input int unsigned size
  );
    logic [31:0] mask;
    begin
      if (size == 0) begin
        align_to = addr;
      end else begin
        mask = (32'h1 << size) - 1;
        align_to = addr & ~mask;
      end
    end
  endfunction

  function automatic logic [7:0] pat(
    input logic [31:0] addr,
    input int unsigned seed
  );
    logic [7:0] seed_byte;
    begin
      seed_byte = seed[7:0];
      pat = addr[7:0] ^ (addr[15:8] << 1) ^ seed_byte ^ 8'ha5;
    end
  endfunction

  task automatic fail(input string requirement, input string detail);
    begin
      errors = errors + 1;
      $display("TB_FAIL %s: %s", requirement, detail);
    end
  endtask

  task automatic bfm_reset(input int cycles = 4);
    begin
      @(negedge clk);
      rst_n = 1'b0;
      repeat (cycles) @(posedge clk);
      @(negedge clk);
      rst_n = 1'b1;
    end
  endtask

  task automatic bfm_ar(
    input  logic [ID_W-1:0] id,
    input  logic [ADDR_W-1:0] addr,
    input  logic [7:0] len,
    input  int budget,
    output bit accepted,
    output int waited
  );
    begin
      accepted = 1'b0;
      waited = 0;
      @(negedge clk);
      s_arid = id;
      s_araddr = addr;
      s_arlen = len;
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
    end
  endtask

  task automatic bfm_aw(
    input  logic [ID_W-1:0] id,
    input  logic [ADDR_W-1:0] addr,
    input  logic [7:0] len,
    input  int budget,
    output bit accepted,
    output int waited
  );
    begin
      accepted = 1'b0;
      waited = 0;
      @(negedge clk);
      s_awid = id;
      s_awaddr = addr;
      s_awlen = len;
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
    end
  endtask

  task automatic bfm_w(
    input logic [SLV_DATA_W-1:0]   data,
    input logic [SLV_DATA_W/8-1:0] strb,
    input logic                    last
  );
    begin
      @(negedge clk);
      s_wdata = data;
      s_wstrb = strb;
      s_wlast = last;
      s_wvalid = 1'b1;
      forever begin
        @(posedge clk);
        if (s_wready) break;
      end
      @(negedge clk);
      s_wvalid = 1'b0;
    end
  endtask

  task automatic bfm_rbeat_resp(
    input logic [ID_W-1:0]       mid,
    input logic [MST_DATA_W-1:0] data,
    input logic [1:0]            resp,
    input logic                  last
  );
    begin
      @(negedge clk);
      m_rid = mid;
      m_rdata = data;
      m_rresp = resp;
      m_rlast = last;
      m_rvalid = 1'b1;
      forever begin
        @(posedge clk);
        if (m_rready) break;
      end
      @(negedge clk);
      m_rvalid = 1'b0;
    end
  endtask

  task automatic bfm_bbeat_resp(
    input logic [ID_W-1:0] mid,
    input logic [1:0]      resp
  );
    begin
      @(negedge clk);
      m_bid = mid;
      m_bresp = resp;
      m_bvalid = 1'b1;
      forever begin
        @(posedge clk);
        if (m_bready) break;
      end
      @(negedge clk);
      m_bvalid = 1'b0;
    end
  endtask

  task automatic clear_queues;
    begin
      m_aw_q.delete();
      m_ar_q.delete();
      m_w_q.delete();
      s_r_q.delete();
      s_b_q.delete();
    end
  endtask

  task automatic fresh_reset;
    begin
      @(negedge clk);
      s_awvalid = 1'b0;
      s_wvalid = 1'b0;
      s_arvalid = 1'b0;
      m_rvalid = 1'b0;
      m_bvalid = 1'b0;
      s_bready = 1'b1;
      s_rready = 1'b1;
      m_awready = 1'b1;
      m_wready = 1'b1;
      m_arready = 1'b1;
      bfm_reset(3);
      clear_queues();
    end
  endtask

  task automatic get_m_ar(output ax_rec_t item, output bit ok);
    int n;
    begin
      item = '0;
      ok = 1'b0;
      for (n = 0; n < 500; n++) begin
        if (m_ar_q.size() != 0) begin
          item = m_ar_q.pop_front();
          ok = 1'b1;
          break;
        end
        @(negedge clk);
      end
    end
  endtask

  task automatic get_m_aw(output ax_rec_t item, output bit ok);
    int n;
    begin
      item = '0;
      ok = 1'b0;
      for (n = 0; n < 500; n++) begin
        if (m_aw_q.size() != 0) begin
          item = m_aw_q.pop_front();
          ok = 1'b1;
          break;
        end
        @(negedge clk);
      end
    end
  endtask

  task automatic wait_r_count(input int count, output bit ok);
    int n;
    begin
      ok = 1'b0;
      for (n = 0; n < 1000; n++) begin
        if (s_r_q.size() >= count) begin
          ok = 1'b1;
          break;
        end
        @(negedge clk);
      end
    end
  endtask

  task automatic wait_b_count(input int count, output bit ok);
    int n;
    begin
      ok = 1'b0;
      for (n = 0; n < 1000; n++) begin
        if (s_b_q.size() >= count) begin
          ok = 1'b1;
          break;
        end
        @(negedge clk);
      end
    end
  endtask

  task automatic wait_w_count(input int count, output bit ok);
    int n;
    begin
      ok = 1'b0;
      for (n = 0; n < 1000; n++) begin
        if (m_w_q.size() >= count) begin
          ok = 1'b1;
          break;
        end
        @(negedge clk);
      end
    end
  endtask

  task automatic wait_refused_r(
    input int count,
    output bit ok,
    output bit leaked
  );
    int n;
    begin
      ok = 1'b0;
      leaked = 1'b0;
      for (n = 0; n < 1000; n++) begin
        if (m_ar_q.size() != 0) begin
          leaked = 1'b1;
          break;
        end
        if (s_r_q.size() >= count) begin
          ok = 1'b1;
          break;
        end
        @(negedge clk);
      end
    end
  endtask

  always @(posedge clk) begin : monitor_proc
    automatic ax_rec_t ax_item;
    automatic w_rec_t  w_item;
    automatic r_rec_t  r_item;
    automatic b_rec_t  b_item;

    if (!rst_n) begin
      if (s_bvalid !== 1'b0)
        fail("F1", "s_bvalid was asserted while reset was active");
      if (s_rvalid !== 1'b0)
        fail("F1", "s_rvalid was asserted while reset was active");
      if (m_awvalid !== 1'b0)
        fail("F1", "m_awvalid was asserted while reset was active");
      if (m_wvalid !== 1'b0)
        fail("F1", "m_wvalid was asserted while reset was active");
      if (m_arvalid !== 1'b0)
        fail("F1", "m_arvalid was asserted while reset was active");
    end else begin
      if (m_awvalid && m_awready) begin
        ax_item.id = m_awid;
        ax_item.addr = m_awaddr;
        ax_item.len = m_awlen;
        ax_item.size = m_awsize;
        ax_item.burst = m_awburst;
        m_aw_q.push_back(ax_item);
      end

      if (m_arvalid && m_arready) begin
        ax_item.id = m_arid;
        ax_item.addr = m_araddr;
        ax_item.len = m_arlen;
        ax_item.size = m_arsize;
        ax_item.burst = m_arburst;
        m_ar_q.push_back(ax_item);
      end

      if (m_wvalid && m_wready) begin
        w_item.data = m_wdata;
        w_item.strb = m_wstrb;
        w_item.last = m_wlast;
        m_w_q.push_back(w_item);
      end

      if (s_rvalid && s_rready) begin
        r_item.id = s_rid;
        r_item.data = s_rdata;
        r_item.resp = s_rresp;
        r_item.last = s_rlast;
        s_r_q.push_back(r_item);
      end

      if (s_bvalid && s_bready) begin
        b_item.id = s_bid;
        b_item.resp = s_bresp;
        s_b_q.push_back(b_item);
      end
    end
  end

  task automatic run_read(
    input logic [ID_W-1:0] id,
    input logic [31:0] addr,
    input logic [7:0] len,
    input logic [2:0] size,
    input logic [1:0] burst,
    input int unsigned seed,
    input int err_idx,
    input logic [1:0] err_code,
    input string tag
  );
    bit accepted;
    bit ok;
    bit header_ok;
    int waited;
    int up_bytes;
    int dsize_int;
    int dbytes;
    int offset;
    int total_bytes;
    int dlen;
    int dbeats;
    int i;
    int u;
    int l;
    int lane;
    int group_end;
    logic [31:0] last_addr;
    logic [31:0] base;
    logic [31:0] byte_addr;
    logic [31:0] beat_addr;
    logic [2:0] expected_size;
    logic [7:0] expected_len;
    logic [15:0] rdata_tmp;
    logic [1:0] beat_resp;
    logic [1:0] expected_resp;
    logic [7:0] expected_byte;
    ax_rec_t ar_item;
    r_rec_t r_item;
    begin
      fresh_reset();

      up_bytes = 1 << size;
      dsize_int = (size > 1) ? 1 : size;
      dbytes = 1 << dsize_int;
      offset = addr - align_to(addr, size);
      total_bytes = (len + 1) * up_bytes - offset;
      last_addr = addr + total_bytes - 1;
      dlen = (align_to(last_addr, dsize_int) -
              align_to(addr, dsize_int)) / dbytes;
      dbeats = dlen + 1;
      expected_size = dsize_int;
      expected_len = dlen;

      @(negedge clk);
      s_arsize = size;
      s_arburst = burst;
      bfm_ar(id, addr, len, 300, accepted, waited);

      if (!accepted) begin
        fail("A2", {tag, ": accepted read address was not accepted"});
        return;
      end

      get_m_ar(ar_item, ok);
      if (!ok) begin
        fail("A2", {tag, ": no downstream read address was produced"});
        return;
      end

      header_ok = 1'b1;
      if (ar_item.id !== id) begin
        fail("A2", {tag, ": downstream read ID differs from upstream ID"});
        header_ok = 1'b0;
      end
      if (ar_item.addr !== addr) begin
        fail("B3", {tag, ": downstream read address was realigned or changed"});
        header_ok = 1'b0;
      end
      if (ar_item.size !== expected_size) begin
        fail("B1", $sformatf("%s: downstream size %0d, expected %0d",
                             tag, ar_item.size, expected_size));
        header_ok = 1'b0;
      end
      if (ar_item.len !== expected_len) begin
        fail("B2", $sformatf("%s: downstream len %0d, expected %0d",
                             tag, ar_item.len, expected_len));
        header_ok = 1'b0;
      end
      if ((dlen > 0) && (ar_item.burst !== AXI_INCR)) begin
        fail("B4", {tag, ": multi-beat downstream read was not INCR"});
        header_ok = 1'b0;
      end
      if (!header_ok) return;

      for (i = 0; i < dbeats; i++) begin
        rdata_tmp = '0;
        if (dsize_int == 1) begin
          base = align_to(addr, 1) + i * 2;
          rdata_tmp[7:0] = pat(base, seed);
          rdata_tmp[15:8] = pat(base + 1, seed);
        end else begin
          beat_addr = addr + i;
          lane = beat_addr % 2;
          rdata_tmp[8*lane +: 8] = pat(beat_addr, seed);
        end

        if (i == err_idx)
          beat_resp = err_code;
        else
          beat_resp = AXI_OKAY;

        bfm_rbeat_resp(id, rdata_tmp, beat_resp, i == dlen);
      end

      wait_r_count(len + 1, ok);
      if (!ok) begin
        fail("A3", {tag, ": timed out waiting for the upstream R burst"});
        return;
      end

      for (u = 0; u <= len; u++) begin
        r_item = s_r_q.pop_front();

        if (r_item.id !== id)
          fail("D3", {tag, ": upstream R beat carried the wrong ID"});

        if (r_item.last !== (u == len))
          fail("D4", $sformatf("%s: bad s_rlast on upstream beat %0d",
                               tag, u));

        byte_addr = align_to(addr, size) + (u + 1) * up_bytes - 1;
        if (byte_addr > last_addr) byte_addr = last_addr;
        group_end = (align_to(byte_addr, dsize_int) -
                     align_to(addr, dsize_int)) / dbytes;

        if ((err_idx >= 0) && (err_idx <= group_end))
          expected_resp = err_code;
        else
          expected_resp = AXI_OKAY;

        if (r_item.resp !== expected_resp) begin
          if (err_idx < 0)
            fail("D5", $sformatf(
              "%s: upstream beat %0d response %b, expected OKAY",
              tag, u, r_item.resp));
          else
            fail("D6/D7", $sformatf(
              "%s: upstream beat %0d response %b, expected %b",
              tag, u, r_item.resp, expected_resp));
        end

        base = align_to(addr, size) + u * up_bytes;
        for (l = 0; l < 8; l++) begin
          byte_addr = base + l;
          if ((byte_addr >= addr) && (byte_addr <= last_addr)) begin
            expected_byte = pat(byte_addr, seed);
            if (r_item.data[8*l +: 8] !== expected_byte) begin
              fail("D1/D2", $sformatf(
                "%s: beat %0d lane %0d data %02x, expected %02x",
                tag, u, l, r_item.data[8*l +: 8], expected_byte));
            end
          end
        end
      end

      repeat (8) @(negedge clk);
      if (m_ar_q.size() != 0)
        fail("A2", {tag, ": more than one downstream read was produced"});
      if (s_r_q.size() != 0)
        fail("A3", {tag, ": extra upstream R beats were produced"});
    end
  endtask

  task automatic run_write(
    input logic [ID_W-1:0] id,
    input logic [31:0] addr,
    input logic [7:0] len,
    input logic [2:0] size,
    input logic [1:0] burst,
    input logic [7:0] strobe_pattern,
    input int unsigned seed,
    input logic [1:0] downstream_bresp,
    input string tag
  );
    bit accepted;
    bit ok;
    bit header_ok;
    int waited;
    int up_bytes;
    int dsize_int;
    int dbytes;
    int offset;
    int total_bytes;
    int dlen;
    int dbeats;
    int i;
    int u;
    int l;
    int lane;
    logic [31:0] last_addr;
    logic [31:0] base;
    logic [31:0] byte_addr;
    logic [31:0] beat_addr;
    logic [2:0] expected_size;
    logic [7:0] expected_len;
    logic [63:0] wdata_tmp;
    logic [7:0] wstrb_tmp;
    logic [15:0] expected_data;
    logic [1:0] expected_strb;
    ax_rec_t aw_item;
    w_rec_t w_item;
    b_rec_t b_item;
    begin
      fresh_reset();

      up_bytes = 1 << size;
      dsize_int = (size > 1) ? 1 : size;
      dbytes = 1 << dsize_int;
      offset = addr - align_to(addr, size);
      total_bytes = (len + 1) * up_bytes - offset;
      last_addr = addr + total_bytes - 1;
      dlen = (align_to(last_addr, dsize_int) -
              align_to(addr, dsize_int)) / dbytes;
      dbeats = dlen + 1;
      expected_size = dsize_int;
      expected_len = dlen;

      @(negedge clk);
      s_awsize = size;
      s_awburst = burst;
      bfm_aw(id, addr, len, 300, accepted, waited);

      if (!accepted) begin
        fail("A2", {tag, ": accepted write address was not accepted"});
        return;
      end

      for (u = 0; u <= len; u++) begin
        base = align_to(addr, size) + u * up_bytes;
        wdata_tmp = '0;
        wstrb_tmp = '0;

        for (l = 0; l < 8; l++) begin
          byte_addr = base + l;
          wdata_tmp[8*l +: 8] = pat(byte_addr, seed);
          if ((byte_addr >= addr) && (byte_addr <= last_addr))
            wstrb_tmp[l] = strobe_pattern[l];
        end

        bfm_w(wdata_tmp, wstrb_tmp, u == len);
      end

      get_m_aw(aw_item, ok);
      if (!ok) begin
        fail("A2", {tag, ": no downstream write address was produced"});
        return;
      end

      header_ok = 1'b1;
      if (aw_item.id !== id) begin
        fail("A2", {tag, ": downstream write ID differs from upstream ID"});
        header_ok = 1'b0;
      end
      if (aw_item.addr !== addr) begin
        fail("B3", {tag, ": downstream write address was realigned or changed"});
        header_ok = 1'b0;
      end
      if (aw_item.size !== expected_size) begin
        fail("B1", $sformatf("%s: downstream size %0d, expected %0d",
                             tag, aw_item.size, expected_size));
        header_ok = 1'b0;
      end
      if (aw_item.len !== expected_len) begin
        fail("B2", $sformatf("%s: downstream len %0d, expected %0d",
                             tag, aw_item.len, expected_len));
        header_ok = 1'b0;
      end
      if ((dlen > 0) && (aw_item.burst !== AXI_INCR)) begin
        fail("B4", {tag, ": multi-beat downstream write was not INCR"});
        header_ok = 1'b0;
      end
      if (!header_ok) return;

      wait_w_count(dbeats, ok);
      if (!ok) begin
        fail("E3", $sformatf(
          "%s: timed out waiting for %0d downstream W beats",
          tag, dbeats));
        return;
      end

      for (i = 0; i < dbeats; i++) begin
        w_item = m_w_q.pop_front();
        expected_data = '0;
        expected_strb = '0;

        if (dsize_int == 1) begin
          base = align_to(addr, 1) + i * 2;
          for (l = 0; l < 2; l++) begin
            byte_addr = base + l;
            expected_data[8*l +: 8] = pat(byte_addr, seed);
            if ((byte_addr >= addr) && (byte_addr <= last_addr))
              expected_strb[l] = strobe_pattern[byte_addr % 8];
          end
        end else begin
          beat_addr = addr + i;
          lane = beat_addr % 2;
          expected_data[8*lane +: 8] = pat(beat_addr, seed);
          if ((beat_addr >= addr) && (beat_addr <= last_addr))
            expected_strb[lane] = strobe_pattern[beat_addr % 8];
        end

        if (w_item.strb !== expected_strb) begin
          fail("E2/E3", $sformatf(
            "%s: downstream beat %0d strb %b, expected %b",
            tag, i, w_item.strb, expected_strb));
        end

        for (l = 0; l < 2; l++) begin
          if (expected_strb[l] &&
              (w_item.data[8*l +: 8] !== expected_data[8*l +: 8])) begin
            fail("E1", $sformatf(
              "%s: downstream beat %0d lane %0d data %02x, expected %02x",
              tag, i, l, w_item.data[8*l +: 8],
              expected_data[8*l +: 8]));
          end
        end

        if (w_item.last !== (i == dlen))
          fail("E4", $sformatf("%s: bad m_wlast on downstream beat %0d",
                               tag, i));
      end

      bfm_bbeat_resp(id, downstream_bresp);
      wait_b_count(1, ok);
      if (!ok) begin
        fail("A3/E5", {tag, ": no upstream B response was produced"});
        return;
      end

      b_item = s_b_q.pop_front();
      if (b_item.id !== id)
        fail("E5", {tag, ": upstream B response carried the wrong ID"});
      if (b_item.resp !== downstream_bresp)
        fail("E6", $sformatf(
          "%s: upstream B response %b, expected %b",
          tag, b_item.resp, downstream_bresp));

      repeat (8) @(negedge clk);
      if (m_aw_q.size() != 0)
        fail("A2", {tag, ": more than one downstream write was produced"});
      if (m_w_q.size() != 0)
        fail("E3", {tag, ": extra downstream W beats were produced"});
      if (s_b_q.size() != 0)
        fail("A3/E5", {tag, ": more than one upstream B response was produced"});
    end
  endtask

  task automatic run_refused_read(
    input logic [ID_W-1:0] id,
    input logic [31:0] addr,
    input logic [7:0] len,
    input logic [2:0] size,
    input logic [1:0] burst,
    input string tag
  );
    bit accepted;
    bit ok;
    bit leaked;
    int waited;
    int u;
    r_rec_t r_item;
    begin
      fresh_reset();

      @(negedge clk);
      s_arsize = size;
      s_arburst = burst;
      bfm_ar(id, addr, len, 300, accepted, waited);

      if (!accepted) begin
        fail("C4", {tag, ": refused read was not accepted upstream"});
        return;
      end

      wait_refused_r(len + 1, ok, leaked);
      if (leaked) begin
        fail("C4", {tag, ": refused read produced a downstream transaction"});
        return;
      end
      if (!ok) begin
        fail("C4", {tag, ": refused read did not return len+1 upstream R beats"});
        return;
      end

      for (u = 0; u <= len; u++) begin
        r_item = s_r_q.pop_front();
        if (r_item.id !== id)
          fail("C4/D3", {tag, ": refused read R beat carried the wrong ID"});
        if (r_item.resp !== AXI_SLVERR)
          fail("C4", $sformatf(
            "%s: refused read beat %0d response %b, expected SLVERR",
            tag, u, r_item.resp));
        if (r_item.last !== (u == len))
          fail("C4", $sformatf(
            "%s: refused read beat %0d had incorrect s_rlast", tag, u));
      end

      repeat (8) @(negedge clk);
      if (m_ar_q.size() != 0)
        fail("C4", {tag, ": refused read leaked a downstream address"});
      if (s_r_q.size() != 0)
        fail("C4/A3", {tag, ": refused read produced extra R beats"});
    end
  endtask

  task automatic run_refused_write(
    input logic [ID_W-1:0] id,
    input logic [31:0] addr,
    input logic [7:0] len,
    input logic [2:0] size,
    input logic [1:0] burst,
    input string tag
  );
    bit accepted;
    bit ok;
    int waited;
    int up_bytes;
    int offset;
    int total_bytes;
    int u;
    int l;
    logic [31:0] last_addr;
    logic [31:0] base;
    logic [31:0] byte_addr;
    logic [63:0] wdata_tmp;
    logic [7:0] wstrb_tmp;
    b_rec_t b_item;
    begin
      fresh_reset();

      up_bytes = 1 << size;
      offset = addr - align_to(addr, size);
      total_bytes = (len + 1) * up_bytes - offset;
      last_addr = addr + total_bytes - 1;

      @(negedge clk);
      s_awsize = size;
      s_awburst = burst;
      bfm_aw(id, addr, len, 300, accepted, waited);

      if (!accepted) begin
        fail("C4", {tag, ": refused write was not accepted upstream"});
        return;
      end

      for (u = 0; u <= len; u++) begin
        base = align_to(addr, size) + u * up_bytes;
        wdata_tmp = '0;
        wstrb_tmp = '0;
        for (l = 0; l < 8; l++) begin
          byte_addr = base + l;
          wdata_tmp[8*l +: 8] = pat(byte_addr, 8'h5a);
          if ((byte_addr >= addr) && (byte_addr <= last_addr))
            wstrb_tmp[l] = 1'b1;
        end
        bfm_w(wdata_tmp, wstrb_tmp, u == len);
      end

      if ((m_aw_q.size() != 0) || (m_w_q.size() != 0)) begin
        fail("C4", {tag, ": refused write produced downstream traffic"});
        return;
      end

      wait_b_count(1, ok);
      if (!ok) begin
        fail("C4", {tag, ": refused write did not produce an upstream B"});
        return;
      end

      b_item = s_b_q.pop_front();
      if (b_item.id !== id)
        fail("C4/E5", {tag, ": refused write B carried the wrong ID"});
      if (b_item.resp !== AXI_SLVERR)
        fail("C4", $sformatf(
          "%s: refused write B response %b, expected SLVERR",
          tag, b_item.resp));

      repeat (8) @(negedge clk);
      if ((m_aw_q.size() != 0) || (m_w_q.size() != 0))
        fail("C4", {tag, ": refused write leaked downstream traffic"});
      if (s_b_q.size() != 0)
        fail("C4/A3", {tag, ": refused write produced extra B responses"});
    end
  endtask

  task automatic test_outstanding_and_reset;
    bit accepted;
    int waited;
    int i;
    begin
      fresh_reset();

      for (i = 0; i < MAX_READS; i++) begin
        @(negedge clk);
        s_arsize = 3'd3;
        s_arburst = AXI_INCR;
        bfm_ar(i[3:0], 32'h0000_7000 + i * 32'h40,
               8'd0, 300, accepted, waited);
        if (!accepted) begin
          fail("A4", $sformatf(
            "read %0d of MAX_READS could not be accepted", i));
          return;
        end
      end

      @(negedge clk);
      s_arsize = 3'd3;
      s_arburst = AXI_INCR;
      bfm_ar(4'hf, 32'h0000_7f00, 8'd0, 40, accepted, waited);
      if (accepted)
        fail("A4", "a fifth read was accepted with four reads outstanding");

      bfm_reset(3);
      clear_queues();
      repeat (12) @(negedge clk);

      if (s_r_q.size() != 0)
        fail("F3", "a pre-reset read produced a response after reset");
      if (s_b_q.size() != 0)
        fail("F3", "a pre-reset transaction produced a B response after reset");
      if ((m_ar_q.size() != 0) || (m_aw_q.size() != 0))
        fail("F2", "old downstream traffic reappeared after reset");

      for (i = 0; i < MAX_READS; i++) begin
        @(negedge clk);
        s_arsize = 3'd3;
        s_arburst = AXI_INCR;
        bfm_ar(i[3:0], 32'h0000_8000 + i * 32'h40,
               8'd0, 300, accepted, waited);
        if (!accepted) begin
          fail("F2", $sformatf(
            "after reset, read %0d of MAX_READS could not be accepted", i));
          return;
        end
      end

      bfm_reset(3);
      clear_queues();
    end
  endtask

  initial begin : watchdog_proc
    #4_000_000;
    if (!finished) begin
      $display("TB_FAIL WATCHDOG: no forward progress");
      $display("RESULT: FAIL");
      $finish;
    end
  end

  initial begin : main_proc
    errors = 0;
    finished = 1'b0;

    s_awid = '0;
    s_awaddr = '0;
    s_awlen = '0;
    s_awsize = '0;
    s_awburst = '0;
    s_awvalid = 1'b0;
    s_wdata = '0;
    s_wstrb = '0;
    s_wlast = 1'b0;
    s_wvalid = 1'b0;
    s_bready = 1'b1;
    s_arid = '0;
    s_araddr = '0;
    s_arlen = '0;
    s_arsize = '0;
    s_arburst = '0;
    s_arvalid = 1'b0;
    s_rready = 1'b1;

    m_awready = 1'b1;
    m_wready = 1'b1;
    m_bid = '0;
    m_bresp = AXI_OKAY;
    m_bvalid = 1'b0;
    m_arready = 1'b1;
    m_rid = '0;
    m_rdata = '0;
    m_rresp = AXI_OKAY;
    m_rlast = 1'b0;
    m_rvalid = 1'b0;

    repeat (2) @(posedge clk);

    // Address transform, byte stream, lane placement, and normal responses.
    run_read(4'h1, 32'h0000_1000, 8'd1, 3'd3, AXI_INCR,
             8'h11, -1, AXI_OKAY, "R aligned size3 len1");
    run_read(4'h2, 32'h0000_1004, 8'd1, 3'd3, AXI_INCR,
             8'h22, -1, AXI_OKAY, "R unaligned size3 len1");
    run_read(4'h3, 32'h0000_1001, 8'd0, 3'd1, AXI_INCR,
             8'h33, -1, AXI_OKAY, "R single byte at odd address");
    run_read(4'h4, 32'h0000_1003, 8'd2, 3'd0, AXI_INCR,
             8'h44, -1, AXI_OKAY, "R size0 three bytes");
    run_read(4'h5, 32'h0000_2000, 8'd0, 3'd3, AXI_FIXED,
             8'h55, -1, AXI_OKAY, "R FIXED len0 must be served");

    // Sticky error precedence and preservation of the error code.
    run_read(4'h6, 32'h0000_2100, 8'd1, 3'd3, AXI_INCR,
             8'h66, 0, AXI_SLVERR, "R error on downstream beat0");
    run_read(4'h7, 32'h0000_2200, 8'd1, 3'd3, AXI_INCR,
             8'h77, 3, AXI_SLVERR, "R error on downstream beat3");
    run_read(4'h8, 32'h0000_2300, 8'd1, 3'd3, AXI_INCR,
             8'h88, 7, AXI_SLVERR, "R error on final downstream beat");
    run_read(4'h9, 32'h0000_2400, 8'd1, 3'd3, AXI_INCR,
             8'h99, 4, AXI_DECERR, "R DECERR preservation");

    // Full and partial strobes, unaligned writes, size 0, and B responses.
    run_write(4'h1, 32'h0000_4000, 8'd1, 3'd3, AXI_INCR,
              8'hff, 8'h12, AXI_OKAY, "W aligned full strobes");
    run_write(4'h2, 32'h0000_4004, 8'd1, 3'd3, AXI_INCR,
              8'hff, 8'h23, AXI_OKAY, "W unaligned full strobes");
    run_write(4'h3, 32'h0000_5001, 8'd0, 3'd1, AXI_INCR,
              8'hff, 8'h34, AXI_OKAY, "W single byte odd address");
    run_write(4'h4, 32'h0000_5003, 8'd2, 3'd0, AXI_INCR,
              8'hff, 8'h45, AXI_OKAY, "W size0 three bytes");
    run_write(4'h5, 32'h0000_6000, 8'd0, 3'd3, AXI_FIXED,
              8'h81, 8'h56, AXI_OKAY, "W FIXED len0 strb81");
    run_write(4'h6, 32'h0000_6100, 8'd0, 3'd3, AXI_INCR,
              8'h0f, 8'h67, AXI_OKAY, "W unstrobed beats emitted");
    run_write(4'h7, 32'h0000_6200, 8'd0, 3'd3, AXI_INCR,
              8'hff, 8'h78, AXI_SLVERR, "W SLVERR preservation");
    run_write(4'h8, 32'h0000_6300, 8'd0, 3'd3, AXI_INCR,
              8'hff, 8'h89, AXI_DECERR, "W DECERR preservation");

    // Refused burst types: acceptance, absorption, no downstream traffic,
    // exact response count, SLVERR, and final-beat marking.
    run_refused_read(4'ha, 32'h0000_3000, 8'd1, 3'd3,
                     AXI_WRAP, "R WRAP refusal");
    run_refused_read(4'hb, 32'h0000_3100, 8'd1, 3'd3,
                     AXI_FIXED, "R FIXED len1 refusal");
    run_refused_write(4'hc, 32'h0000_3200, 8'd0, 3'd3,
                      AXI_WRAP, "W WRAP refusal");
    run_refused_write(4'hd, 32'h0000_3300, 8'd1, 3'd3,
                      AXI_FIXED, "W FIXED len1 refusal");

    test_outstanding_and_reset();

    finished = 1'b1;
    if (errors == 0)
      $display("RESULT: PASS");
    else
      $display("RESULT: FAIL");
    $finish;
  end

endmodule
