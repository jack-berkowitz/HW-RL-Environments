`timescale 1ns/1ps

module id_width_conv_tb;

  localparam int unsigned ADDR_W      = 32;
  localparam int unsigned SLV_ID_W    = 4;
  localparam int unsigned MST_ID_W    = 4;
  localparam int unsigned DATA_W      = 64;
  localparam int unsigned SLV_DATA_W  = 64;
  localparam int unsigned MST_DATA_W  = 16;
  localparam int unsigned MAX_READS   = 4;

  logic clk;
  initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
  end

  logic rst_n;
  initial rst_n = 1'b0;

  logic [SLV_ID_W-1:0]         s_awid;
  logic [ADDR_W-1:0]           s_awaddr;
  logic [7:0]                  s_awlen;
  logic [2:0]                  s_awsize;
  logic [1:0]                  s_awburst;
  logic                        s_awvalid;
  logic                        s_awready;
  logic [SLV_DATA_W-1:0]       s_wdata;
  logic [SLV_DATA_W/8-1:0]     s_wstrb;
  logic                        s_wlast;
  logic                        s_wvalid;
  logic                        s_wready;
  logic [SLV_ID_W-1:0]         s_bid;
  logic [1:0]                  s_bresp;
  logic                        s_bvalid;
  logic                        s_bready;
  logic [SLV_ID_W-1:0]         s_arid;
  logic [ADDR_W-1:0]           s_araddr;
  logic [7:0]                  s_arlen;
  logic [2:0]                  s_arsize;
  logic [1:0]                  s_arburst;
  logic                        s_arvalid;
  logic                        s_arready;
  logic [SLV_ID_W-1:0]         s_rid;
  logic [SLV_DATA_W-1:0]       s_rdata;
  logic [1:0]                  s_rresp;
  logic                        s_rlast;
  logic                        s_rvalid;
  logic                        s_rready;

  logic [MST_ID_W-1:0]         m_awid;
  logic [ADDR_W-1:0]           m_awaddr;
  logic [7:0]                  m_awlen;
  logic [2:0]                  m_awsize;
  logic [1:0]                  m_awburst;
  logic                        m_awvalid;
  logic                        m_awready;
  logic [MST_DATA_W-1:0]       m_wdata;
  logic [MST_DATA_W/8-1:0]     m_wstrb;
  logic                        m_wlast;
  logic                        m_wvalid;
  logic                        m_wready;
  logic [MST_ID_W-1:0]         m_bid;
  logic [1:0]                  m_bresp;
  logic                        m_bvalid;
  logic                        m_bready;
  logic [MST_ID_W-1:0]         m_arid;
  logic [ADDR_W-1:0]           m_araddr;
  logic [7:0]                  m_arlen;
  logic [2:0]                  m_arsize;
  logic [1:0]                  m_arburst;
  logic                        m_arvalid;
  logic                        m_arready;
  logic [MST_ID_W-1:0]         m_rid;
  logic [MST_DATA_W-1:0]       m_rdata;
  logic [1:0]                  m_rresp;
  logic                        m_rlast;
  logic                        m_rvalid;
  logic                        m_rready;

  dw_downsizer #(
    .ADDR_W     (ADDR_W),
    .ID_W       (SLV_ID_W),
    .SLV_DATA_W (SLV_DATA_W),
    .MST_DATA_W (MST_DATA_W),
    .MAX_READS  (MAX_READS)
  ) dut (
    .clk_i      (clk),
    .rst_ni     (rst_n),
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

  typedef struct packed {
    logic [MST_ID_W-1:0] id;
    logic [ADDR_W-1:0]   addr;
    logic [7:0]          len;
    logic [2:0]          size;
    logic [1:0]          burst;
  } ax_rec_t;

  typedef struct packed {
    logic [MST_DATA_W-1:0]   data;
    logic [MST_DATA_W/8-1:0] strb;
    logic                    last;
  } w_down_rec_t;

  typedef struct packed {
    logic [SLV_ID_W-1:0] id;
    logic [1:0]          resp;
  } b_up_rec_t;

  typedef struct packed {
    logic [SLV_ID_W-1:0]   id;
    logic [SLV_DATA_W-1:0] data;
    logic [1:0]            resp;
    logic                  last;
  } r_up_rec_t;

  ax_rec_t    m_aw_q[$];
  ax_rec_t    m_ar_q[$];
  w_down_rec_t m_w_q[$];
  b_up_rec_t  s_b_q[$];
  r_up_rec_t  s_r_q[$];

  ax_rec_t     mon_ax;
  w_down_rec_t mon_w;
  b_up_rec_t   mon_b;
  r_up_rec_t   mon_r;

  int errors;

  task automatic fail(input string req, input string msg);
    begin
      errors = errors + 1;
      $display("FAIL %s: %s", req, msg);
    end
  endtask

  function automatic logic [31:0] align_addr(
    input logic [31:0] a,
    input logic [2:0]  sz
  );
    logic [31:0] mask;
    begin
      mask = (32'd1 << sz) - 32'd1;
      align_addr = a & ~mask;
    end
  endfunction

  function automatic int unsigned pick_dsize(input logic [2:0] sz);
    begin
      if (sz > 3'd1)
        pick_dsize = 1;
      else
        pick_dsize = sz;
    end
  endfunction

  function automatic int unsigned calc_dlen(
    input logic [31:0] addr,
    input logic [7:0]  len,
    input logic [2:0]  size
  );
    int unsigned ds;
    logic [31:0] total;
    logic [31:0] last_a;
    logic [31:0] first_aligned;
    logic [31:0] last_aligned;
    begin
      ds = pick_dsize(size);
      total = (32'd1 + len) * (32'd1 << size)
              - (addr - align_addr(addr, size));
      last_a = addr + total - 32'd1;
      first_aligned = align_addr(addr, ds[2:0]);
      last_aligned = align_addr(last_a, ds[2:0]);
      calc_dlen = (last_aligned - first_aligned) >> ds;
    end
  endfunction

  function automatic logic [7:0] pat_byte(input logic [31:0] a);
    begin
      pat_byte = (a[7:0] << 1) ^ a[15:8] ^ 8'ha6;
    end
  endfunction

  function automatic logic [15:0] make_mword(
    input logic [31:0] base,
    input int unsigned ds
  );
    logic [31:0] bus_base;
    logic [31:0] a;
    int k;
    begin
      make_mword = 16'h0000;
      bus_base = {base[31:1], 1'b0};
      for (k = 0; k < 2; k = k + 1) begin
        a = bus_base + k;
        if ((a >= base) && (a < (base + (32'd1 << ds))))
          make_mword[k*8 +: 8] = pat_byte(a);
      end
    end
  endfunction

  // -------------------------------------------------------------------------
  // BFMs. All design inputs change on the falling edge.
  // -------------------------------------------------------------------------

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
    input  logic [SLV_ID_W-1:0] id,
    input  logic [ADDR_W-1:0]   addr,
    input  logic [7:0]          len,
    input  logic [2:0]          size,
    input  logic [1:0]          burst,
    input  int                  budget,
    output bit                  accepted,
    output int                  waited
  );
    begin
      accepted = 1'b0;
      waited = 0;
      @(negedge clk);
      s_arid = id;
      s_araddr = addr;
      s_arlen = len;
      s_arsize = size;
      s_arburst = burst;
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

  task automatic bfm_aw(
    input  logic [SLV_ID_W-1:0] id,
    input  logic [ADDR_W-1:0]   addr,
    input  logic [7:0]          len,
    input  logic [2:0]          size,
    input  logic [1:0]          burst,
    input  int                  budget,
    output bit                  accepted,
    output int                  waited
  );
    begin
      accepted = 1'b0;
      waited = 0;
      @(negedge clk);
      s_awid = id;
      s_awaddr = addr;
      s_awlen = len;
      s_awsize = size;
      s_awburst = burst;
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

  task automatic bfm_w(
    input  logic [DATA_W-1:0]   data,
    input  logic [DATA_W/8-1:0] strb,
    input  logic                last,
    input  int                  budget,
    output bit                  accepted
  );
    int waited;
    begin
      accepted = 1'b0;
      waited = 0;
      @(negedge clk);
      s_wdata = data;
      s_wstrb = strb;
      s_wlast = last;
      s_wvalid = 1'b1;
      while (waited < budget) begin
        @(posedge clk);
        if (s_wready) begin
          accepted = 1'b1;
          break;
        end
        waited = waited + 1;
      end
      @(negedge clk);
      s_wvalid = 1'b0;
    end
  endtask

  task automatic bfm_rbeat(
    input  logic [MST_ID_W-1:0] mid,
    input  logic [MST_DATA_W-1:0] data,
    input  logic [1:0]          resp,
    input  logic                last,
    input  int                  budget,
    output bit                  accepted
  );
    int waited;
    begin
      accepted = 1'b0;
      waited = 0;
      @(negedge clk);
      m_rid = mid;
      m_rdata = data;
      m_rresp = resp;
      m_rlast = last;
      m_rvalid = 1'b1;
      while (waited < budget) begin
        @(posedge clk);
        if (m_rready) begin
          accepted = 1'b1;
          break;
        end
        waited = waited + 1;
      end
      @(negedge clk);
      m_rvalid = 1'b0;
    end
  endtask

  task automatic bfm_bbeat(
    input  logic [MST_ID_W-1:0] mid,
    input  logic [1:0]          resp,
    input  int                  budget,
    output bit                  accepted
  );
    int waited;
    begin
      accepted = 1'b0;
      waited = 0;
      @(negedge clk);
      m_bid = mid;
      m_bresp = resp;
      m_bvalid = 1'b1;
      while (waited < budget) begin
        @(posedge clk);
        if (m_bready) begin
          accepted = 1'b1;
          break;
        end
        waited = waited + 1;
      end
      @(negedge clk);
      m_bvalid = 1'b0;
    end
  endtask

  // -------------------------------------------------------------------------
  // Monitors. Handshakes, rather than payload values, identify records.
  // -------------------------------------------------------------------------

  always @(posedge clk) begin
    if (!rst_n) begin
      if ((s_bvalid === 1'b1) || (s_rvalid === 1'b1) ||
          (m_awvalid === 1'b1) || (m_wvalid === 1'b1) ||
          (m_arvalid === 1'b1))
        fail("F1", "a valid output was asserted while reset was active");

      m_aw_q.delete();
      m_ar_q.delete();
      m_w_q.delete();
      s_b_q.delete();
      s_r_q.delete();
    end else begin
      if (m_awvalid && m_awready) begin
        mon_ax.id = m_awid;
        mon_ax.addr = m_awaddr;
        mon_ax.len = m_awlen;
        mon_ax.size = m_awsize;
        mon_ax.burst = m_awburst;
        m_aw_q.push_back(mon_ax);
      end

      if (m_arvalid && m_arready) begin
        mon_ax.id = m_arid;
        mon_ax.addr = m_araddr;
        mon_ax.len = m_arlen;
        mon_ax.size = m_arsize;
        mon_ax.burst = m_arburst;
        m_ar_q.push_back(mon_ax);
      end

      if (m_wvalid && m_wready) begin
        mon_w.data = m_wdata;
        mon_w.strb = m_wstrb;
        mon_w.last = m_wlast;
        m_w_q.push_back(mon_w);
      end

      if (s_bvalid && s_bready) begin
        mon_b.id = s_bid;
        mon_b.resp = s_bresp;
        s_b_q.push_back(mon_b);
      end

      if (s_rvalid && s_rready) begin
        mon_r.id = s_rid;
        mon_r.data = s_rdata;
        mon_r.resp = s_rresp;
        mon_r.last = s_rlast;
        s_r_q.push_back(mon_r);
      end
    end
  end

  task automatic clear_queues;
    begin
      m_aw_q.delete();
      m_ar_q.delete();
      m_w_q.delete();
      s_b_q.delete();
      s_r_q.delete();
    end
  endtask

  task automatic clean_reset;
    begin
      bfm_reset(2);
      s_awvalid = 1'b0;
      s_wvalid = 1'b0;
      s_arvalid = 1'b0;
      s_bready = 1'b1;
      s_rready = 1'b1;
      m_awready = 1'b1;
      m_wready = 1'b1;
      m_arready = 1'b1;
      m_bvalid = 1'b0;
      m_rvalid = 1'b0;
      clear_queues();
    end
  endtask

  task automatic get_mar(output ax_rec_t rec, output bit ok);
    int n;
    begin
      rec = '0;
      ok = 1'b0;
      for (n = 0; n < 1000; n = n + 1) begin
        @(negedge clk);
        if (m_ar_q.size() != 0) begin
          rec = m_ar_q.pop_front();
          ok = 1'b1;
          break;
        end
      end
    end
  endtask

  task automatic get_maw(output ax_rec_t rec, output bit ok);
    int n;
    begin
      rec = '0;
      ok = 1'b0;
      for (n = 0; n < 1000; n = n + 1) begin
        @(negedge clk);
        if (m_aw_q.size() != 0) begin
          rec = m_aw_q.pop_front();
          ok = 1'b1;
          break;
        end
      end
    end
  endtask

  task automatic get_mw(output w_down_rec_t rec, output bit ok);
    int n;
    begin
      rec = '0;
      ok = 1'b0;
      for (n = 0; n < 1000; n = n + 1) begin
        @(negedge clk);
        if (m_w_q.size() != 0) begin
          rec = m_w_q.pop_front();
          ok = 1'b1;
          break;
        end
      end
    end
  endtask

  task automatic get_sb(output b_up_rec_t rec, output bit ok);
    int n;
    begin
      rec = '0;
      ok = 1'b0;
      for (n = 0; n < 1000; n = n + 1) begin
        @(negedge clk);
        if (s_b_q.size() != 0) begin
          rec = s_b_q.pop_front();
          ok = 1'b1;
          break;
        end
      end
    end
  endtask

  task automatic get_sr(output r_up_rec_t rec, output bit ok);
    int n;
    begin
      rec = '0;
      ok = 1'b0;
      for (n = 0; n < 1000; n = n + 1) begin
        @(negedge clk);
        if (s_r_q.size() != 0) begin
          rec = s_r_q.pop_front();
          ok = 1'b1;
          break;
        end
      end
    end
  endtask

  task automatic check_no_leftovers;
    begin
      repeat (12) @(negedge clk);
      if ((m_aw_q.size() != 0) || (m_ar_q.size() != 0) ||
          (m_w_q.size() != 0))
        fail("A2", "an accepted transaction produced extra downstream activity");
      if ((s_b_q.size() != 0) || (s_r_q.size() != 0))
        fail("A3", "an accepted transaction produced extra upstream responses");
    end
  endtask

  // -------------------------------------------------------------------------
  // Normal reads.
  // -------------------------------------------------------------------------

  task automatic run_read(
    input logic [SLV_ID_W-1:0] id,
    input logic [31:0]         addr,
    input logic [7:0]          len,
    input logic [2:0]          size,
    input logic [1:0]          burst,
    input int                  err_idx,
    input logic [1:0]          err_code
  );
    bit accepted;
    bit ok;
    int waited;
    int unsigned ds;
    int n_down;
    int i;
    int lane;
    int group_end;
    logic [7:0] expected_dlen;
    logic [2:0] expected_dsize;
    logic [31:0] total;
    logic [31:0] last_addr;
    logic [31:0] base;
    logic [31:0] bus_base;
    logic [31:0] lo;
    logic [31:0] hi;
    logic [31:0] a;
    logic [31:0] db;
    logic [63:0] expected_data;
    logic [63:0] compare_mask;
    logic [1:0] expected_resp;
    ax_rec_t da;
    r_up_rec_t ur;
    begin
      ds = pick_dsize(size);
      expected_dsize = ds;
      expected_dlen = calc_dlen(addr, len, size);
      n_down = expected_dlen + 1;
      total = (32'd1 + len) * (32'd1 << size)
              - (addr - align_addr(addr, size));
      last_addr = addr + total - 32'd1;

      bfm_ar(id, addr, len, size, burst, 300, accepted, waited);
      if (!accepted) begin
        if ((burst == 2'b00) && (len == 0))
          fail("C3", "a single-beat FIXED read was not accepted");
        else
          fail("A2", "a supported read address was not accepted");
        return;
      end

      get_mar(da, ok);
      if (!ok) begin
        fail("A2", "an accepted read produced no downstream address");
        return;
      end

      if ((da.id !== id) || (da.addr !== addr))
        fail("A2", "downstream read id or address differs from upstream");
      if (da.size !== expected_dsize)
        fail("B1", $sformatf("downstream size %0d, expected %0d",
                             da.size, expected_dsize));
      if (da.len !== expected_dlen)
        fail("B2", $sformatf("downstream len %0d, expected %0d",
                             da.len, expected_dlen));
      if ((expected_dlen != 0) && (da.burst !== 2'b01))
        fail("B4", "a multi-beat downstream read was not INCR");

      for (i = 0; i < n_down; i = i + 1) begin
        db = align_addr(addr, ds[2:0]) + (i << ds);
        bfm_rbeat(id, make_mword(db, ds),
                  (i == err_idx) ? err_code : 2'b00,
                  (i == expected_dlen), 300, ok);
        if (!ok) begin
          fail("A3", "downstream read response was not accepted");
          return;
        end
      end

      for (i = 0; i < (len + 1); i = i + 1) begin
        get_sr(ur, ok);
        if (!ok) begin
          fail("A3", $sformatf("missing upstream read beat %0d", i));
          return;
        end

        if (ur.id !== id)
          fail("D3", "upstream read beat carried the wrong id");
        if (ur.last !== (i == len))
          fail("D4", $sformatf("incorrect s_rlast on upstream beat %0d", i));

        base = align_addr(addr, size) + i * (32'd1 << size);
        bus_base = align_addr(base, 3);
        if (i == 0)
          lo = addr;
        else
          lo = base;
        hi = base + (32'd1 << size) - 32'd1;
        if (hi > last_addr)
          hi = last_addr;

        expected_data = 64'd0;
        compare_mask = 64'd0;
        for (lane = 0; lane < 8; lane = lane + 1) begin
          a = bus_base + lane;
          if ((a >= lo) && (a <= hi)) begin
            expected_data[lane*8 +: 8] = pat_byte(a);
            compare_mask[lane*8 +: 8] = 8'hff;
          end
        end

        if ((ur.data & compare_mask) !==
            (expected_data & compare_mask))
          fail("D1", $sformatf(
               "read byte stream/lane mismatch on upstream beat %0d: got %h expected %h mask %h",
               i, ur.data, expected_data, compare_mask));

        group_end = (align_addr(hi, ds[2:0])
                     - align_addr(addr, ds[2:0])) >> ds;
        if ((err_idx >= 0) && (err_idx <= group_end))
          expected_resp = err_code;
        else
          expected_resp = 2'b00;

        if (ur.resp !== expected_resp) begin
          if (err_idx < 0)
            fail("D5", $sformatf(
                 "non-OKAY response without an error on beat %0d", i));
          else if (err_code == 2'b11)
            fail("D7", $sformatf(
                 "DECERR was not preserved on upstream beat %0d", i));
          else
            fail("D6", $sformatf(
                 "sticky error mismatch on upstream beat %0d: got %b expected %b",
                 i, ur.resp, expected_resp));
        end
      end

      check_no_leftovers();
    end
  endtask

  // -------------------------------------------------------------------------
  // Normal writes.
  // -------------------------------------------------------------------------

  task automatic run_write(
    input logic [SLV_ID_W-1:0] id,
    input logic [31:0]         addr,
    input logic [7:0]          len,
    input logic [2:0]          size,
    input logic [1:0]          burst,
    input bit                  use_override,
    input logic [7:0]          first_strb,
    input logic [1:0]          downstream_bresp
  );
    bit accepted;
    bit ok;
    int waited;
    int unsigned ds;
    int n_down;
    int i;
    int j;
    int lane;
    int lane2;
    logic [7:0] expected_dlen;
    logic [2:0] expected_dsize;
    logic [31:0] total;
    logic [31:0] last_addr;
    logic [31:0] base;
    logic [31:0] bus_base;
    logic [31:0] lo;
    logic [31:0] hi;
    logic [31:0] a;
    logic [31:0] dfirst;
    logic [7:0] valid_mask;
    logic [63:0] uw_data [0:255];
    logic [7:0]  uw_strb [0:255];
    logic [15:0] expected_ddata [0:255];
    logic [1:0]  expected_dstrb [0:255];
    ax_rec_t da;
    w_down_rec_t dw;
    b_up_rec_t ub;
    begin
      ds = pick_dsize(size);
      expected_dsize = ds;
      expected_dlen = calc_dlen(addr, len, size);
      n_down = expected_dlen + 1;
      total = (32'd1 + len) * (32'd1 << size)
              - (addr - align_addr(addr, size));
      last_addr = addr + total - 32'd1;
      dfirst = align_addr(addr, ds[2:0]);

      for (i = 0; i < n_down; i = i + 1) begin
        expected_ddata[i] = 16'd0;
        expected_dstrb[i] = 2'd0;
      end

      for (i = 0; i < (len + 1); i = i + 1) begin
        if (burst == 2'b00)
          base = align_addr(addr, size);
        else
          base = align_addr(addr, size) + i * (32'd1 << size);
        bus_base = align_addr(base, 3);
        if (i == 0)
          lo = addr;
        else
          lo = base;
        hi = base + (32'd1 << size) - 32'd1;
        if (hi > last_addr)
          hi = last_addr;

        uw_data[i] = 64'd0;
        valid_mask = 8'd0;
        for (lane = 0; lane < 8; lane = lane + 1) begin
          a = bus_base + lane;
          uw_data[i][lane*8 +: 8] = pat_byte(a);
          if ((a >= lo) && (a <= hi))
            valid_mask[lane] = 1'b1;
        end

        uw_strb[i] = valid_mask;
        if ((i == 0) && use_override)
          uw_strb[i] = first_strb & valid_mask;

        for (lane = 0; lane < 8; lane = lane + 1) begin
          if (uw_strb[i][lane]) begin
            a = bus_base + lane;
            j = (align_addr(a, ds[2:0]) - dfirst) >> ds;
            lane2 = a & 32'd1;
            if ((j >= 0) && (j < n_down)) begin
              expected_dstrb[j][lane2] = 1'b1;
              expected_ddata[j][lane2*8 +: 8]
                = uw_data[i][lane*8 +: 8];
            end
          end
        end
      end

      bfm_aw(id, addr, len, size, burst, 300, accepted, waited);
      if (!accepted) begin
        if ((burst == 2'b00) && (len == 0))
          fail("C3", "a single-beat FIXED write was not accepted");
        else
          fail("A2", "a supported write address was not accepted");
        return;
      end

      for (i = 0; i < (len + 1); i = i + 1) begin
        bfm_w(uw_data[i], uw_strb[i], (i == len), 300, accepted);
        if (!accepted) begin
          fail("A3", $sformatf("upstream write beat %0d was not absorbed", i));
          return;
        end
      end

      get_maw(da, ok);
      if (!ok) begin
        fail("A2", "an accepted write produced no downstream address");
        return;
      end

      if ((da.id !== id) || (da.addr !== addr))
        fail("A2", "downstream write id or address differs from upstream");
      if (da.size !== expected_dsize)
        fail("B1", $sformatf("downstream write size %0d, expected %0d",
                             da.size, expected_dsize));
      if (da.len !== expected_dlen)
        fail("B2", $sformatf("downstream write len %0d, expected %0d",
                             da.len, expected_dlen));
      if ((expected_dlen != 0) && (da.burst !== 2'b01))
        fail("B4", "a multi-beat downstream write was not INCR");

      for (i = 0; i < n_down; i = i + 1) begin
        get_mw(dw, ok);
        if (!ok) begin
          fail("E3", $sformatf("missing downstream write beat %0d", i));
          return;
        end

        if (dw.strb !== expected_dstrb[i])
          fail("E2", $sformatf(
               "downstream write strobe on beat %0d was %b, expected %b",
               i, dw.strb, expected_dstrb[i]));

        for (lane = 0; lane < 2; lane = lane + 1) begin
          if (expected_dstrb[i][lane] &&
              (dw.data[lane*8 +: 8] !==
               expected_ddata[i][lane*8 +: 8]))
            fail("E1", $sformatf(
                 "write data mismatch on downstream beat %0d lane %0d",
                 i, lane));
        end

        if (dw.last !== (i == expected_dlen))
          fail("E4", $sformatf("incorrect m_wlast on beat %0d", i));
      end

      bfm_bbeat(id, downstream_bresp, 300, ok);
      if (!ok) begin
        fail("E5", "downstream B response was not accepted");
        return;
      end

      get_sb(ub, ok);
      if (!ok) begin
        fail("E5", "missing upstream B response");
        return;
      end
      if (ub.id !== id)
        fail("E5", "upstream B response carried the wrong id");
      if (ub.resp !== downstream_bresp)
        fail("E6", $sformatf("upstream B response %b, expected %b",
                             ub.resp, downstream_bresp));

      check_no_leftovers();
    end
  endtask

  // -------------------------------------------------------------------------
  // Refused transactions.
  // -------------------------------------------------------------------------

  task automatic run_refused_read(
    input logic [SLV_ID_W-1:0] id,
    input logic [31:0]         addr,
    input logic [7:0]          len,
    input logic [2:0]          size,
    input logic [1:0]          burst
  );
    bit accepted;
    bit ok;
    int waited;
    int i;
    r_up_rec_t ur;
    begin
      bfm_ar(id, addr, len, size, burst, 300, accepted, waited);
      if (!accepted) begin
        fail("C4", "a refused read was not accepted upstream");
        return;
      end

      for (i = 0; i < (len + 1); i = i + 1) begin
        get_sr(ur, ok);
        if (!ok) begin
          fail("C4", $sformatf("refused read lacked upstream R beat %0d", i));
          return;
        end
        if (ur.id !== id)
          fail("D3", "refused read response carried the wrong id");
        if (ur.resp !== 2'b10)
          fail("C4", $sformatf(
               "refused read beat %0d did not carry SLVERR", i));
        if (ur.last !== (i == len))
          fail("C4", $sformatf(
               "refused read had incorrect s_rlast on beat %0d", i));
      end

      repeat (12) @(negedge clk);
      if ((m_ar_q.size() != 0) || (m_aw_q.size() != 0) ||
          (m_w_q.size() != 0))
        fail("C4", "a refused read produced downstream activity");
      if (s_r_q.size() != 0)
        fail("C4", "a refused read produced too many upstream R beats");
    end
  endtask

  task automatic run_refused_write(
    input logic [SLV_ID_W-1:0] id,
    input logic [31:0]         addr,
    input logic [7:0]          len,
    input logic [2:0]          size,
    input logic [1:0]          burst
  );
    bit accepted;
    bit ok;
    int waited;
    int i;
    int lane;
    logic [31:0] base;
    logic [31:0] bus_base;
    logic [31:0] lo;
    logic [31:0] hi;
    logic [31:0] a;
    logic [63:0] data;
    logic [7:0] strb;
    b_up_rec_t ub;
    begin
      bfm_aw(id, addr, len, size, burst, 300, accepted, waited);
      if (!accepted) begin
        fail("C4", "a refused write was not accepted upstream");
        return;
      end

      for (i = 0; i < (len + 1); i = i + 1) begin
        if (burst == 2'b00)
          base = align_addr(addr, size);
        else
          base = align_addr(addr, size) + i * (32'd1 << size);
        bus_base = align_addr(base, 3);
        lo = base;
        hi = base + (32'd1 << size) - 32'd1;
        data = 64'd0;
        strb = 8'd0;
        for (lane = 0; lane < 8; lane = lane + 1) begin
          a = bus_base + lane;
          data[lane*8 +: 8] = pat_byte(a);
          if ((a >= lo) && (a <= hi))
            strb[lane] = 1'b1;
        end

        bfm_w(data, strb, (i == len), 300, accepted);
        if (!accepted) begin
          fail("C4", $sformatf(
               "refused write did not absorb upstream W beat %0d", i));
          return;
        end
      end

      get_sb(ub, ok);
      if (!ok) begin
        fail("C4", "refused write lacked its upstream B response");
        return;
      end
      if (ub.id !== id)
        fail("E5", "refused write B response carried the wrong id");
      if (ub.resp !== 2'b10)
        fail("C4", "refused write B response was not SLVERR");

      repeat (12) @(negedge clk);
      if ((m_ar_q.size() != 0) || (m_aw_q.size() != 0) ||
          (m_w_q.size() != 0))
        fail("C4", "a refused write produced downstream activity");
      if (s_b_q.size() != 0)
        fail("C4", "a refused write produced multiple B responses");
    end
  endtask

  // -------------------------------------------------------------------------
  // Outstanding-read bound and response bookkeeping.
  // -------------------------------------------------------------------------

  task automatic run_max_reads;
    bit accepted;
    bit ok;
    int waited;
    int i;
    int j;
    int n;
    int found;
    int lane;
    logic [3:0] ids [0:4];
    logic [31:0] addrs [0:4];
    bit seen_request [0:4];
    bit seen_response [0:4];
    logic [7:0] got_byte;
    ax_rec_t ds [0:4];
    r_up_rec_t ur;
    begin
      for (i = 0; i < 5; i = i + 1) begin
        ids[i] = i + 1;
        addrs[i] = 32'h0000_5000 + i * 32'h10;
        seen_request[i] = 1'b0;
        seen_response[i] = 1'b0;
      end

      for (i = 0; i < MAX_READS; i = i + 1) begin
        bfm_ar(ids[i], addrs[i], 8'd0, 3'd0, 2'b01,
               300, accepted, waited);
        if (!accepted) begin
          fail("A4", $sformatf(
               "read %0d could not be accepted with capacity available", i));
          return;
        end
      end

      // A fifth request is allowed to wait, but must not be accepted while all
      // four earlier reads remain unanswered.
      bfm_ar(ids[4], addrs[4], 8'd0, 3'd0, 2'b01,
             1, accepted, waited);
      if (accepted) begin
        fail("A4", "more than MAX_READS reads were outstanding");
        n = 5;
      end else begin
        n = 4;
      end

      for (i = 0; i < n; i = i + 1) begin
        get_mar(ds[i], ok);
        if (!ok) begin
          fail("A2", "missing downstream address in outstanding-read test");
          return;
        end

        found = -1;
        for (j = 0; j < n; j = j + 1) begin
          if (ds[i].id == ids[j])
            found = j;
        end
        if (found < 0) begin
          fail("A2", "downstream read carried an unknown id");
          return;
        end
        if (seen_request[found])
          fail("A2", "one upstream read produced duplicate downstream reads");
        seen_request[found] = 1'b1;

        if (ds[i].addr !== addrs[found])
          fail("A2", "downstream read address mismatch in outstanding test");
        if (ds[i].size !== 3'd0)
          fail("B1", "size zero was changed in outstanding-read test");
        if (ds[i].len !== 8'd0)
          fail("B2", "single-byte read length changed in outstanding test");
      end

      // Respond in downstream issue order. Upstream completion order is not
      // constrained, so responses below are matched strictly by ID.
      for (i = 0; i < n; i = i + 1) begin
        found = -1;
        for (j = 0; j < n; j = j + 1) begin
          if (ds[i].id == ids[j])
            found = j;
        end
        if (found < 0)
          return;
        bfm_rbeat(ds[i].id, make_mword(addrs[found], 0),
                  2'b00, 1'b1, 300, ok);
        if (!ok) begin
          fail("A3", "downstream response stalled in outstanding-read test");
          return;
        end
      end

      for (i = 0; i < n; i = i + 1) begin
        get_sr(ur, ok);
        if (!ok) begin
          fail("A3", "missing upstream response in outstanding-read test");
          return;
        end

        found = -1;
        for (j = 0; j < n; j = j + 1) begin
          if (ur.id == ids[j])
            found = j;
        end
        if (found < 0) begin
          fail("D3", "upstream response carried an unknown id");
          return;
        end
        if (seen_response[found])
          fail("A3", "duplicate upstream response for one read");
        seen_response[found] = 1'b1;

        if (!ur.last)
          fail("D4", "single-beat read did not assert s_rlast");
        if (ur.resp !== 2'b00)
          fail("D5", "error-free outstanding read returned an error");

        lane = addrs[found] & 32'd7;
        got_byte = ur.data[lane*8 +: 8];
        if (got_byte !== pat_byte(addrs[found]))
          fail("D1", "data mismatch in outstanding-read test");
      end

      check_no_leftovers();
    end
  endtask

  // -------------------------------------------------------------------------
  // Asynchronous reset with a response held outstanding.
  // -------------------------------------------------------------------------

  task automatic run_reset_outstanding;
    bit accepted;
    bit ok;
    int waited;
    int i;
    time assert_time;
    ax_rec_t da;
    begin
      @(negedge clk);
      s_rready = 1'b0;

      bfm_ar(4'h9, 32'h0000_6001, 8'd0, 3'd0, 2'b01,
             300, accepted, waited);
      if (!accepted) begin
        fail("A2", "could not establish read for reset test");
        s_rready = 1'b1;
        return;
      end

      get_mar(da, ok);
      if (!ok) begin
        fail("A2", "missing downstream address in reset test");
        s_rready = 1'b1;
        return;
      end

      bfm_rbeat(4'h9, make_mword(32'h0000_6001, 0),
                2'b00, 1'b1, 300, ok);
      if (!ok) begin
        fail("A3", "could not present response in reset test");
        s_rready = 1'b1;
        return;
      end

      ok = 1'b0;
      for (i = 0; i < 300; i = i + 1) begin
        @(negedge clk);
        if (s_rvalid === 1'b1) begin
          ok = 1'b1;
          break;
        end
      end
      if (!ok) begin
        fail("A3", "upstream response never became visible in reset test");
        s_rready = 1'b1;
        return;
      end

      // No clock edge is waited for here. A synchronous-only reset would
      // clear s_rvalid at a later simulation time and fail this check.
      assert_time = $time;
      rst_n = 1'b0;
      wait (s_rvalid === 1'b0);
      if ($time != assert_time)
        fail("F1", "s_rvalid did not clear asynchronously with reset");

      if ((s_bvalid === 1'b1) || (m_awvalid === 1'b1) ||
          (m_wvalid === 1'b1) || (m_arvalid === 1'b1))
        fail("F1", "another valid output remained asserted during reset");

      repeat (2) @(posedge clk);
      @(negedge clk);
      rst_n = 1'b1;
      s_rready = 1'b1;
      clear_queues();

      for (i = 0; i < 20; i = i + 1) begin
        @(negedge clk);
        if ((s_rvalid === 1'b1) || (s_bvalid === 1'b1))
          fail("F3", "a pre-reset transaction responded after reset");
      end
      if ((s_r_q.size() != 0) || (s_b_q.size() != 0))
        fail("F3", "a queued pre-reset response appeared after reset");
      if (m_ar_q.size() != 0)
        fail("F2", "the pre-reset request was reissued after reset");

      // The unit must be usable again after releasing reset.
      run_read(4'ha, 32'h0000_6008, 8'd0, 3'd0, 2'b01, -1, 2'b00);
    end
  endtask

  // -------------------------------------------------------------------------
  // Test sequence.
  // -------------------------------------------------------------------------

  initial begin : main_sequence
    errors = 0;

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
    m_bresp = '0;
    m_bvalid = 1'b0;
    m_arready = 1'b1;
    m_rid = '0;
    m_rdata = '0;
    m_rresp = '0;
    m_rlast = 1'b0;
    m_rvalid = 1'b0;

    bfm_reset(4);

    // Aligned transform, byte stream, and eight downstream beats.
    run_read(4'h1, 32'h0000_1000, 8'd1, 3'd3, 2'b01, -1, 2'b00);

    clean_reset();
    // Unaligned first upstream beat: downstream len must be five.
    run_read(4'h2, 32'h0000_1004, 8'd1, 3'd3, 2'b01, -1, 2'b00);

    clean_reset();
    // One byte spanning one downstream block: downstream len is zero.
    run_read(4'h3, 32'h0000_1001, 8'd0, 3'd1, 2'b01, -1, 2'b00);

    clean_reset();
    // Size zero must remain zero, including on a multi-beat burst.
    run_read(4'h4, 32'h0000_1021, 8'd3, 3'd0, 2'b01, -1, 2'b00);

    clean_reset();
    // A one-beat FIXED request is accepted and becomes four INCR beats.
    run_read(4'h5, 32'h0000_1010, 8'd0, 3'd3, 2'b00, -1, 2'b00);

    clean_reset();
    // Error in the last downstream beat of upstream group zero: sticky.
    run_read(4'h6, 32'h0000_2000, 8'd1, 3'd3, 2'b01, 3, 2'b10);

    clean_reset();
    // Error only in the final group: first upstream beat remains OKAY.
    run_read(4'h7, 32'h0000_2000, 8'd1, 3'd3, 2'b01, 7, 2'b10);

    clean_reset();
    // DECERR must not be normalised to SLVERR.
    run_read(4'h8, 32'h0000_2000, 8'd1, 3'd3, 2'b01, 4, 2'b11);

    clean_reset();
    run_write(4'h1, 32'h0000_3000, 8'd1, 3'd3, 2'b01,
              1'b0, 8'h00, 2'b00);

    clean_reset();
    run_write(4'h2, 32'h0000_3004, 8'd1, 3'd3, 2'b01,
              1'b0, 8'h00, 2'b00);

    clean_reset();
    // Expected downstream strobes: 01, 00, 00, 10.
    run_write(4'h3, 32'h0000_3100, 8'd0, 3'd3, 2'b01,
              1'b1, 8'h81, 2'b00);

    clean_reset();
    // The two all-zero downstream strobes must still be emitted.
    run_write(4'h4, 32'h0000_3200, 8'd0, 3'd3, 2'b01,
              1'b1, 8'h0f, 2'b00);

    clean_reset();
    // At size one and address ...02, live upstream lanes are two and three.
    run_write(4'h5, 32'h0000_1002, 8'd0, 3'd1, 2'b01,
              1'b0, 8'h00, 2'b00);

    clean_reset();
    run_write(4'h6, 32'h0000_3300, 8'd0, 3'd3, 2'b00,
              1'b0, 8'h00, 2'b00);

    clean_reset();
    run_write(4'h7, 32'h0000_3400, 8'd0, 3'd3, 2'b01,
              1'b0, 8'h00, 2'b10);

    clean_reset();
    run_write(4'h8, 32'h0000_3500, 8'd0, 3'd3, 2'b01,
              1'b0, 8'h00, 2'b11);

    clean_reset();
    run_refused_read(4'h1, 32'h0000_4000, 8'd1, 3'd3, 2'b10);

    clean_reset();
    run_refused_read(4'h2, 32'h0000_4102, 8'd1, 3'd1, 2'b00);

    clean_reset();
    run_refused_write(4'h3, 32'h0000_4200, 8'd1, 3'd3, 2'b10);

    clean_reset();
    run_refused_write(4'h4, 32'h0000_4302, 8'd1, 3'd1, 2'b00);

    clean_reset();
    run_max_reads();

    clean_reset();
    run_reset_outstanding();

    if (errors == 0)
      $display("RESULT: PASS");
    else
      $display("RESULT: FAIL");
    $finish;
  end

  initial begin
    #4_000_000;
    $display("RESULT: FAIL (watchdog: no forward progress)");
    $finish;
  end

endmodule
