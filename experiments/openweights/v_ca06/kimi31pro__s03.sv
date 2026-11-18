module id_width_conv_tb;

  localparam int unsigned ADDR_W     = 32;
  localparam int unsigned ID_W       = 4;
  localparam int unsigned SLV_ID_W   = 4;
  localparam int unsigned MST_ID_W   = 4;
  localparam int unsigned DATA_W     = 64;
  localparam int unsigned SLV_DATA_W = 64;
  localparam int unsigned MST_DATA_W = 16;
  localparam int unsigned MAX_READS  = 4;
  localparam int unsigned IO_TIMEOUT = 200;

  logic clk;
  initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
  end

  logic rst_n;
  initial rst_n = 1'b0;

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
  } dn_w_rec_t;

  typedef struct packed {
    logic [ID_W-1:0]       id;
    logic [SLV_DATA_W-1:0] data;
    logic [1:0]            resp;
    logic                  last;
  } up_r_rec_t;

  typedef struct packed {
    logic [ID_W-1:0] id;
    logic [1:0]      resp;
  } up_b_rec_t;

  addr_rec_t ar_q[$];
  addr_rec_t aw_q[$];
  dn_w_rec_t dn_w_q[$];
  up_r_rec_t up_r_q[$];
  up_b_rec_t up_b_q[$];

  int errors;

  task automatic fail(input string requirement, input string message);
    begin
      errors = errors + 1;
      $display("FAIL [%s] %s", requirement, message);
    end
  endtask

  function automatic logic [31:0] align_addr(
    input logic [31:0] addr,
    input int unsigned size
  );
    align_addr = (addr >> size) << size;
  endfunction

  function automatic logic [7:0] byte_pat(
    input logic [31:0] addr,
    input int unsigned salt
  );
    byte_pat = addr[7:0] ^ salt[7:0] ^ 8'ha5;
  endfunction

  task automatic bfm_reset(input int cycles = 4);
    begin
      @(negedge clk);
      rst_n = 1'b0;
      repeat (cycles) @(posedge clk);
      @(negedge clk);
      rst_n = 1'b1;
    end
  endtask

  always @(posedge clk) begin
    automatic addr_rec_t tmp_ar;
    automatic addr_rec_t tmp_aw;
    automatic dn_w_rec_t tmp_w;
    automatic up_r_rec_t tmp_r;
    automatic up_b_rec_t tmp_b;

    if (!rst_n) begin
      if ((s_bvalid === 1'b1) || (s_rvalid === 1'b1) ||
          (m_awvalid === 1'b1) || (m_wvalid === 1'b1) ||
          (m_arvalid === 1'b1)) begin
        fail("F1", "a valid output was asserted while reset was active");
      end
      ar_q.delete();
      aw_q.delete();
      dn_w_q.delete();
      up_r_q.delete();
      up_b_q.delete();
    end else begin
      if (m_arvalid && m_arready) begin
        tmp_ar.id    = m_arid;
        tmp_ar.addr  = m_araddr;
        tmp_ar.len   = m_arlen;
        tmp_ar.size  = m_arsize;
        tmp_ar.burst = m_arburst;
        ar_q.push_back(tmp_ar);
      end
      if (m_awvalid && m_awready) begin
        tmp_aw.id    = m_awid;
        tmp_aw.addr  = m_awaddr;
        tmp_aw.len   = m_awlen;
        tmp_aw.size  = m_awsize;
        tmp_aw.burst = m_awburst;
        aw_q.push_back(tmp_aw);
      end
      if (m_wvalid && m_wready) begin
        tmp_w.data = m_wdata;
        tmp_w.strb = m_wstrb;
        tmp_w.last = m_wlast;
        dn_w_q.push_back(tmp_w);
      end
      if (s_rvalid && s_rready) begin
        tmp_r.id   = s_rid;
        tmp_r.data = s_rdata;
        tmp_r.resp = s_rresp;
        tmp_r.last = s_rlast;
        up_r_q.push_back(tmp_r);
      end
      if (s_bvalid && s_bready) begin
        tmp_b.id   = s_bid;
        tmp_b.resp = s_bresp;
        up_b_q.push_back(tmp_b);
      end
    end
  end

  task automatic send_ar(
    input  logic [ID_W-1:0]   id,
    input  logic [ADDR_W-1:0] addr,
    input  logic [7:0]        len,
    input  logic [2:0]        size,
    input  logic [1:0]        burst_in,
    input  int                budget,
    output bit                accepted,
    output int                waited
  );
    begin
      accepted = 1'b0;
      waited = 0;
      @(negedge clk);
      s_arid    = id;
      s_araddr  = addr;
      s_arlen   = len;
      s_arsize  = size;
      s_arburst = burst_in;
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

  task automatic send_aw(
    input  logic [ID_W-1:0]   id,
    input  logic [ADDR_W-1:0] addr,
    input  logic [7:0]        len,
    input  logic [2:0]        size,
    input  logic [1:0]        burst_in,
    input  int                budget,
    output bit                accepted,
    output int                waited
  );
    begin
      accepted = 1'b0;
      waited = 0;
      @(negedge clk);
      s_awid    = id;
      s_awaddr  = addr;
      s_awlen   = len;
      s_awsize  = size;
      s_awburst = burst_in;
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

  task automatic send_w(
    input  logic [SLV_DATA_W-1:0]   data,
    input  logic [SLV_DATA_W/8-1:0] strb,
    input  logic                    last,
    output bit                      accepted
  );
    int waited;
    begin
      accepted = 1'b0;
      waited = 0;
      @(negedge clk);
      s_wdata  = data;
      s_wstrb  = strb;
      s_wlast  = last;
      s_wvalid = 1'b1;
      while (waited < IO_TIMEOUT) begin
        @(posedge clk);
        if (s_wready) begin
          accepted = 1'b1;
          break;
        end
        waited = waited + 1;
      end
      @(negedge clk);
      s_wvalid = 1'b0;
      if (!accepted)
        fail("A3", "upstream W beat was not absorbed within the timeout");
    end
  endtask

  task automatic send_rbeat(
    input  logic [ID_W-1:0]       id,
    input  logic [MST_DATA_W-1:0] data,
    input  logic                  last,
    input  logic [1:0]            resp,
    output bit                    accepted
  );
    int waited;
    begin
      accepted = 1'b0;
      waited = 0;
      @(negedge clk);
      m_rid    = id;
      m_rdata  = data;
      m_rlast  = last;
      m_rresp  = resp;
      m_rvalid = 1'b1;
      while (waited < IO_TIMEOUT) begin
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

  task automatic send_bbeat(
    input logic [ID_W-1:0] id,
    input logic [1:0]      resp,
    output bit             accepted
  );
    int waited;
    begin
      accepted = 1'b0;
      waited = 0;
      @(negedge clk);
      m_bid    = id;
      m_bresp  = resp;
      m_bvalid = 1'b1;
      while (waited < IO_TIMEOUT) begin
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

  task automatic get_ar(output addr_rec_t rec, output bit ok);
    int waited;
    begin
      rec = '0;
      ok = 1'b0;
      waited = 0;
      while (waited < IO_TIMEOUT) begin
        @(negedge clk);
        if (ar_q.size() != 0) begin
          rec = ar_q.pop_front();
          ok = 1'b1;
          break;
        end
        waited = waited + 1;
      end
    end
  endtask

  task automatic get_aw(output addr_rec_t rec, output bit ok);
    int waited;
    begin
      rec = '0;
      ok = 1'b0;
      waited = 0;
      while (waited < IO_TIMEOUT) begin
        @(negedge clk);
        if (aw_q.size() != 0) begin
          rec = aw_q.pop_front();
          ok = 1'b1;
          break;
        end
        waited = waited + 1;
      end
    end
  endtask

  task automatic get_dn_w(output dn_w_rec_t rec, output bit ok);
    int waited;
    begin
      rec = '0;
      ok = 1'b0;
      waited = 0;
      while (waited < IO_TIMEOUT) begin
        @(negedge clk);
        if (dn_w_q.size() != 0) begin
          rec = dn_w_q.pop_front();
          ok = 1'b1;
          break;
        end
        waited = waited + 1;
      end
    end
  endtask

  task automatic get_up_r(output up_r_rec_t rec, output bit ok);
    int waited;
    begin
      rec = '0;
      ok = 1'b0;
      waited = 0;
      while (waited < IO_TIMEOUT) begin
        @(negedge clk);
        if (up_r_q.size() != 0) begin
          rec = up_r_q.pop_front();
          ok = 1'b1;
          break;
        end
        waited = waited + 1;
      end
    end
  endtask

  task automatic get_up_b(output up_b_rec_t rec, output bit ok);
    int waited;
    begin
      rec = '0;
      ok = 1'b0;
      waited = 0;
      while (waited < IO_TIMEOUT) begin
        @(negedge clk);
        if (up_b_q.size() != 0) begin
          rec = up_b_q.pop_front();
          ok = 1'b1;
          break;
        end
        waited = waited + 1;
      end
    end
  endtask

  task automatic run_read(
    input logic [ID_W-1:0]   id,
    input logic [ADDR_W-1:0] addr,
    input logic [7:0]        len,
    input logic [2:0]        size,
    input logic [1:0]        burst_in,
    input bit                refused,
    input int                error_beat,
    input logic [1:0]        error_code,
    input int                salt
  );
    bit accepted;
    bit ok;
    int waited;
    int upbeats;
    int up_bytes;
    int dsize;
    int dbytes;
    int dbeats;
    int dlen;
    int total_bytes;
    int i;
    int j;
    int k;
    int last_d;
    logic [31:0] last_addr;
    logic [31:0] block_addr;
    logic [31:0] beat_base;
    logic [31:0] byte_addr;
    logic [31:0] up_first;
    logic [31:0] up_last;
    logic [MST_DATA_W-1:0] ndata;
    logic [1:0] expected_resp;
    addr_rec_t da;
    up_r_rec_t ur;
    begin
      upbeats = len;
      upbeats = upbeats + 1;
      up_bytes = 1 << size;
      dsize = (size > 1) ? 1 : size;
      dbytes = 1 << dsize;
      total_bytes = upbeats * up_bytes - (addr - align_addr(addr, size));
      last_addr = addr + total_bytes - 1;
      dlen = (align_addr(last_addr, dsize) - align_addr(addr, dsize)) >> dsize;
      dbeats = dlen + 1;

      send_ar(id, addr, len, size, burst_in, IO_TIMEOUT, accepted, waited);
      if (!accepted) begin
        if (refused)
          fail("C4", "a refused read was not accepted on the upstream address channel");
        else
          fail("A2", "a legal read was not accepted within the timeout");
        bfm_reset();
      end else if (!refused) begin
        get_ar(da, ok);
        if (!ok) begin
          fail("A2", "accepted read produced no downstream address");
          bfm_reset();
        end else begin
          if ((da.id !== id) || (da.addr !== addr))
            fail("A2", "downstream read id or address differs from upstream");
          if (da.size !== dsize[2:0])
            fail("B1", "downstream read size is not min(upstream size,1)");
          if (da.len !== dlen[7:0])
            fail("B2", "downstream read length is not the number of spanned blocks minus one");
          if ((dbeats > 1) && (da.burst !== 2'b01))
            fail("B4", "multi-beat downstream read is not INCR");

          for (i = 0; i < dbeats; i = i + 1) begin
            ndata = '0;
            block_addr = align_addr(addr, dsize) + i * dbytes;
            for (j = 0; j < dbytes; j = j + 1)
              ndata[j*8 +: 8] = byte_pat(block_addr + j, salt);
            send_rbeat(id, ndata, (i == dbeats-1),
                       (i == error_beat) ? error_code : 2'b00, ok);
            if (!ok) begin
              fail("A3", "downstream R beat was not accepted within the timeout");
              bfm_reset();
              return;
            end
          end

          for (k = 0; k < upbeats; k = k + 1) begin
            get_up_r(ur, ok);
            if (!ok) begin
              fail("A3", "accepted read did not produce all upstream R beats");
              bfm_reset();
              return;
            end
            if (ur.id !== id)
              fail("D3", "upstream R beat has the wrong id");
            if (ur.last !== (k == upbeats-1))
              fail("D4", "upstream RLAST is not asserted only on the final beat");

            beat_base = align_addr(addr, size) + k * up_bytes;
            for (j = 0; j < 8; j = j + 1) begin
              byte_addr = beat_base + j;
              if ((byte_addr >= addr) && (byte_addr <= last_addr)) begin
                if (ur.data[j*8 +: 8] !== byte_pat(byte_addr, salt))
                  fail("D1", "upstream read byte stream or lane placement is incorrect");
              end
            end

            up_first = (beat_base > addr) ? beat_base : addr;
            up_last = ((beat_base + up_bytes - 1) < last_addr) ?
                      (beat_base + up_bytes - 1) : last_addr;
            last_d = (align_addr(up_last, dsize) - align_addr(addr, dsize)) >> dsize;
            expected_resp = ((error_beat >= 0) && (error_beat <= last_d)) ?
                            error_code : 2'b00;
            if (ur.resp !== expected_resp) begin
              if (error_beat >= 0)
                fail("D6", "read error is not sticky from its own group onward, or its code changed");
              else
                fail("D5", "error-free read returned a non-OKAY response");
            end
          end

          repeat (3) @(negedge clk);
          if (up_r_q.size() != 0)
            fail("A3", "read produced more than one upstream R burst");
          if (ar_q.size() != 0)
            fail("A2", "one accepted read produced multiple downstream transactions");
        end
      end else begin
        for (k = 0; k < upbeats; k = k + 1) begin
          get_up_r(ur, ok);
          if (!ok) begin
            fail("C4", "refused read did not return len+1 upstream R beats");
            bfm_reset();
            return;
          end
          if (ur.id !== id)
            fail("D3", "refused read returned the wrong id");
          if (ur.resp !== 2'b10)
            fail("C4", "every R beat of a refused read must be SLVERR");
          if (ur.last !== (k == upbeats-1))
            fail("C4", "refused read has incorrect RLAST placement");
        end
        repeat (4) @(negedge clk);
        if ((ar_q.size() != 0) || (aw_q.size() != 0) || (dn_w_q.size() != 0))
          fail("C4", "refused read produced downstream activity");
        if (up_r_q.size() != 0)
          fail("A3", "refused read produced extra upstream R beats");
      end
    end
  endtask

  task automatic run_write(
    input logic [ID_W-1:0]   id,
    input logic [ADDR_W-1:0] addr,
    input logic [7:0]        len,
    input logic [2:0]        size,
    input logic [1:0]        burst_in,
    input bit                refused,
    input int                strb_mode,
    input logic [1:0]        downstream_bresp,
    input int                salt
  );
    bit accepted;
    bit ok;
    int waited;
    int upbeats;
    int up_bytes;
    int dsize;
    int dbytes;
    int dbeats;
    int dlen;
    int total_bytes;
    int i;
    int j;
    int k;
    int source_beat;
    int source_lane;
    logic [31:0] last_addr;
    logic [31:0] beat_base;
    logic [31:0] byte_addr;
    logic [31:0] block_addr;
    logic [63:0] sent_data [0:255];
    logic [7:0]  sent_strb [0:255];
    logic [MST_DATA_W-1:0] expected_data;
    logic [MST_DATA_W/8-1:0] expected_strb;
    logic covered;
    addr_rec_t da;
    dn_w_rec_t dw;
    up_b_rec_t ub;
    begin
      upbeats = len;
      upbeats = upbeats + 1;
      up_bytes = 1 << size;
      dsize = (size > 1) ? 1 : size;
      dbytes = 1 << dsize;
      total_bytes = upbeats * up_bytes - (addr - align_addr(addr, size));
      last_addr = addr + total_bytes - 1;
      dlen = (align_addr(last_addr, dsize) - align_addr(addr, dsize)) >> dsize;
      dbeats = dlen + 1;

      send_aw(id, addr, len, size, burst_in, IO_TIMEOUT, accepted, waited);
      if (!accepted) begin
        if (refused)
          fail("C4", "a refused write was not accepted on the upstream address channel");
        else
          fail("A2", "a legal write was not accepted within the timeout");
        bfm_reset();
      end else begin
        for (k = 0; k < upbeats; k = k + 1) begin
          sent_data[k] = '0;
          sent_strb[k] = '0;
          beat_base = align_addr(addr, size) + k * up_bytes;
          for (j = 0; j < 8; j = j + 1) begin
            byte_addr = beat_base + j;
            sent_data[k][j*8 +: 8] = byte_pat(byte_addr, salt);
            if ((byte_addr >= addr) && (byte_addr <= last_addr))
              sent_strb[k][j] = 1'b1;
          end
          if ((strb_mode == 1) && (k == 0))
            sent_strb[k] = 8'h81;
          if ((strb_mode == 2) && (k == 0))
            sent_strb[k] = 8'h0f;
          send_w(sent_data[k], sent_strb[k], (k == upbeats-1), ok);
          if (!ok) begin
            bfm_reset();
            return;
          end
        end

        if (!refused) begin
          get_aw(da, ok);
          if (!ok) begin
            fail("A2", "accepted write produced no downstream address");
            bfm_reset();
            return;
          end
          if ((da.id !== id) || (da.addr !== addr))
            fail("A2", "downstream write id or address differs from upstream");
          if (da.size !== dsize[2:0])
            fail("B1", "downstream write size is not min(upstream size,1)");
          if (da.len !== dlen[7:0])
            fail("B2", "downstream write length is not the number of spanned blocks minus one");
          if ((dbeats > 1) && (da.burst !== 2'b01))
            fail("B4", "multi-beat downstream write is not INCR");

          for (i = 0; i < dbeats; i = i + 1) begin
            get_dn_w(dw, ok);
            if (!ok) begin
              fail("E3", "downstream write burst has fewer beats than required, including zero-strobe beats");
              bfm_reset();
              return;
            end

            expected_data = '0;
            expected_strb = '0;
            block_addr = align_addr(addr, dsize) + i * dbytes;
            for (j = 0; j < dbytes; j = j + 1) begin
              byte_addr = block_addr + j;
              covered = ((byte_addr >= addr) && (byte_addr <= last_addr));
              if (covered) begin
                source_beat = (byte_addr - align_addr(addr, size)) / up_bytes;
                source_lane = byte_addr & 32'h7;
                expected_data[j*8 +: 8] =
                  sent_data[source_beat][source_lane*8 +: 8];
                expected_strb[j] = sent_strb[source_beat][source_lane];
                if (dw.data[j*8 +: 8] !== expected_data[j*8 +: 8])
                  fail("E1", "downstream write byte stream is incorrect");
              end
            end
            if (dw.strb !== expected_strb)
              fail("E2", "downstream write strobes do not match the covered upstream byte lanes");
            if (dw.last !== (i == dbeats-1))
              fail("E4", "downstream WLAST is not asserted only on the final beat");
          end

          send_bbeat(id, downstream_bresp, ok);
          if (!ok) begin
            fail("E5", "downstream B response was not accepted within the timeout");
            bfm_reset();
            return;
          end
          get_up_b(ub, ok);
          if (!ok) begin
            fail("E5", "downstream B did not produce exactly one upstream B");
            bfm_reset();
            return;
          end
          if (ub.id !== id)
            fail("E5", "upstream B has the wrong id");
          if (ub.resp !== downstream_bresp)
            fail("E6", "upstream B did not preserve the downstream response code");

          repeat (3) @(negedge clk);
          if (up_b_q.size() != 0)
            fail("E5", "write produced more than one upstream B response");
          if ((aw_q.size() != 0) || (dn_w_q.size() != 0))
            fail("E3", "write produced extra downstream address or data beats");
        end else begin
          get_up_b(ub, ok);
          if (!ok) begin
            fail("C4", "refused write did not produce an upstream B response");
            bfm_reset();
            return;
          end
          if (ub.id !== id)
            fail("E5", "refused write returned the wrong id");
          if (ub.resp !== 2'b10)
            fail("C4", "refused write must return SLVERR");
          repeat (4) @(negedge clk);
          if ((aw_q.size() != 0) || (dn_w_q.size() != 0) || (ar_q.size() != 0))
            fail("C4", "refused write produced downstream activity");
          if (up_b_q.size() != 0)
            fail("A3", "refused write produced extra B responses");
        end
      end
    end
  endtask

  task automatic reset_with_outstanding;
    bit accepted;
    bit ok;
    int waited;
    addr_rec_t da;
    begin
      send_ar(4'hf, 32'h00003000, 8'd0, 3'd0, 2'b01,
              IO_TIMEOUT, accepted, waited);
      if (!accepted) begin
        fail("A2", "could not establish the outstanding read used for the reset test");
        bfm_reset();
      end else begin
        get_ar(da, ok);
        if (!ok)
          fail("A2", "outstanding reset-test read produced no downstream request");
        bfm_reset(5);
        repeat (10) @(negedge clk);
        if ((up_r_q.size() != 0) || (up_b_q.size() != 0))
          fail("F3", "a transaction outstanding before reset produced a response after reset");
        if ((ar_q.size() != 0) || (aw_q.size() != 0) || (dn_w_q.size() != 0))
          fail("F3", "a transaction outstanding before reset was reissued after reset");
      end
    end
  endtask

  task automatic four_outstanding_reads;
    bit accepted;
    bit fifth_accepted;
    bit ok;
    int waited;
    int i;
    int idx;
    int response_count;
    logic [4:0] seen_requests;
    logic [4:0] seen_responses;
    logic [31:0] expected_addr;
    logic [MST_DATA_W-1:0] ndata;
    addr_rec_t da;
    up_r_rec_t ur;
    begin
      seen_requests = '0;
      seen_responses = '0;

      for (i = 0; i < MAX_READS; i = i + 1) begin
        send_ar(i[3:0], 32'h00002000 + i*4, 8'd0, 3'd0, 2'b01,
                IO_TIMEOUT, accepted, waited);
        if (!accepted) begin
          fail("F2", "fewer than MAX_READS reads were accepted after reset");
          bfm_reset();
          return;
        end
      end

      send_ar(4'h4, 32'h00002010, 8'd0, 3'd0, 2'b01,
              12, fifth_accepted, waited);
      if (fifth_accepted)
        fail("A4", "a fifth read was accepted while MAX_READS reads were outstanding");

      for (response_count = 0; response_count < MAX_READS;
           response_count = response_count + 1) begin
        get_ar(da, ok);
        if (!ok) begin
          fail("A2", "outstanding reads did not each produce a downstream request");
          bfm_reset();
          return;
        end
        if (da.id >= MAX_READS) begin
          fail("A2", "downstream request has an id not among the outstanding reads");
          bfm_reset();
          return;
        end
        idx = da.id;
        expected_addr = 32'h00002000 + idx*4;
        if (seen_requests[idx])
          fail("A2", "an outstanding read produced duplicate downstream requests");
        seen_requests[idx] = 1'b1;
        if (da.addr !== expected_addr)
          fail("A2", "downstream address does not match the request identified by its id");
        if (da.size !== 3'd0)
          fail("B1", "size-zero read was not forwarded with size zero");
        if (da.len !== 8'd0)
          fail("B2", "single-byte read did not produce one downstream beat");

        ndata = '0;
        ndata[7:0] = byte_pat(da.addr, 8'h70 + idx);
        send_rbeat(da.id, ndata, 1'b1, 2'b00, ok);
        if (!ok) begin
          fail("A3", "downstream response for an outstanding read was not accepted");
          bfm_reset();
          return;
        end
      end

      for (i = 0; i < MAX_READS; i = i + 1) begin
        get_up_r(ur, ok);
        if (!ok) begin
          fail("A3", "outstanding reads did not each produce an upstream response");
          bfm_reset();
          return;
        end
        if (ur.id >= MAX_READS) begin
          fail("D3", "upstream response has an unexpected id");
          bfm_reset();
          return;
        end
        idx = ur.id;
        if (seen_responses[idx])
          fail("A3", "an outstanding read produced more than one response");
        seen_responses[idx] = 1'b1;
        expected_addr = 32'h00002000 + idx*4;
        if (!ur.last)
          fail("D4", "single-beat read response did not carry RLAST");
        if (ur.resp !== 2'b00)
          fail("D5", "error-free outstanding read returned an error");
        if (ur.data[(expected_addr[2:0])*8 +: 8] !==
            byte_pat(expected_addr, 8'h70 + idx))
          fail("D1", "outstanding read returned data in the wrong lane");
      end

      if ((seen_requests[3:0] != 4'hf) || (seen_responses[3:0] != 4'hf))
        fail("A3", "not every outstanding read completed exactly once");

      if (fifth_accepted)
        bfm_reset();
    end
  endtask

  initial begin
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

    bfm_reset();

    // Aligned two-beat read: eight downstream beats.
    run_read(4'h1, 32'h00001000, 8'd1, 3'd3, 2'b01,
             1'b0, -1, 2'b00, 8'h11);

    // Unaligned version: downstream len must be 5, not 7.
    run_read(4'h2, 32'h00001004, 8'd1, 3'd3, 2'b01,
             1'b0, -1, 2'b00, 8'h22);

    // A one-byte range filling only part of a downstream block.
    run_read(4'h3, 32'h00001001, 8'd0, 3'd1, 2'b01,
             1'b0, -1, 2'b00, 8'h33);

    // Size zero must remain size zero.
    run_read(4'h4, 32'h00001003, 8'd0, 3'd0, 2'b01,
             1'b0, -1, 2'b00, 8'h44);

    // Single-beat FIXED is legal and expands to four INCR beats.
    run_read(4'h5, 32'h00001100, 8'd0, 3'd3, 2'b00,
             1'b0, -1, 2'b00, 8'h55);

    // Refused reads.
    run_read(4'h6, 32'h00001200, 8'd0, 3'd3, 2'b10,
             1'b1, -1, 2'b00, 8'h66);
    run_read(4'h7, 32'h00001300, 8'd1, 3'd3, 2'b00,
             1'b1, -1, 2'b00, 8'h77);

    // Sticky errors: first group, last beat of first group, and final beat.
    run_read(4'h8, 32'h00001400, 8'd1, 3'd3, 2'b01,
             1'b0, 0, 2'b10, 8'h88);
    run_read(4'h9, 32'h00001500, 8'd1, 3'd3, 2'b01,
             1'b0, 3, 2'b10, 8'h99);
    run_read(4'ha, 32'h00001600, 8'd1, 3'd3, 2'b01,
             1'b0, 7, 2'b10, 8'haa);
    run_read(4'hb, 32'h00001700, 8'd1, 3'd3, 2'b01,
             1'b0, 7, 2'b11, 8'hbb);

    // Sparse strobes, including emitted all-zero-strobe beats.
    run_write(4'h1, 32'h00001800, 8'd0, 3'd3, 2'b01,
              1'b0, 1, 2'b00, 8'h18);
    run_write(4'h2, 32'h00001900, 8'd0, 3'd3, 2'b01,
              1'b0, 2, 2'b10, 8'h29);

    // Unaligned wide write and a narrow write using lanes 2 and 3.
    run_write(4'h3, 32'h00001a04, 8'd0, 3'd3, 2'b01,
              1'b0, 0, 2'b00, 8'h3a);
    run_write(4'h4, 32'h00001b02, 8'd0, 3'd1, 2'b01,
              1'b0, 0, 2'b11, 8'h4b);

    // Refused writes must absorb their complete upstream W bursts.
    run_write(4'h5, 32'h00001c00, 8'd0, 3'd3, 2'b10,
              1'b1, 0, 2'b00, 8'h5c);
    run_write(4'h6, 32'h00001d00, 8'd1, 3'd3, 2'b00,
              1'b1, 0, 2'b00, 8'h6d);

    reset_with_outstanding();
    four_outstanding_reads();

    repeat (5) @(negedge clk);
    if ((up_r_q.size() != 0) || (up_b_q.size() != 0))
      fail("A3", "unexpected upstream responses remained at end of test");

    if (errors == 0)
      $display("RESULT: PASS");
    else
      $display("RESULT: FAIL");
    $finish;
  end

  initial begin
    #4_000_000;
    $display("RESULT: FAIL");
    $finish;
  end

endmodule
