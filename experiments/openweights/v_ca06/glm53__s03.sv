// ---------------------------------------------------------------------------
// dw_downsizer_tb -- self-checking testbench for the AXI4 data-width downsizer
// (64-bit upstream / 16-bit downstream, ratio 4, MAX_READS 4).
//
// The TB drives the upstream (slave) port as a master and answers the
// downstream (master) port as a slave.  All checks are grounded in the
// numbered clauses of the specification.  Latitudes L1-L6 are respected:
// no latency, readiness-promptness, inter-transaction ordering, single-beat
// burst-type or in-flight-beat assumptions are made.
// ---------------------------------------------------------------------------
module dw_downsizer_tb;

  // ---- pinned configuration (spec section 0) ----
  localparam int unsigned ADDR_W     = 32;
  localparam int unsigned ID_W       = 4;
  localparam int unsigned SLV_DATA_W = 64;
  localparam int unsigned MST_DATA_W = 16;
  localparam int unsigned MAX_READS  = 4;

  // ---- clock / reset ----
  logic clk;
  initial begin clk = 1'b0; forever #5 clk = ~clk; end
  logic rst_n;
  initial rst_n = 1'b0;

  // ---- DUT nets ----
  logic [ID_W-1:0]         s_awid, s_bid, s_arid, s_rid;
  logic [ADDR_W-1:0]       s_awaddr, s_araddr;
  logic [7:0]              s_awlen, s_arlen;
  logic [2:0]              s_awsize, s_arsize;
  logic [1:0]              s_awburst, s_arburst, s_bresp, s_rresp;
  logic                    s_awvalid, s_awready, s_wvalid, s_wready, s_wlast;
  logic                    s_bvalid, s_bready, s_rvalid, s_rready, s_rlast;
  logic                    s_arvalid, s_arready;
  logic [SLV_DATA_W-1:0]   s_wdata, s_rdata;
  logic [SLV_DATA_W/8-1:0] s_wstrb;

  logic [ID_W-1:0]         m_awid, m_bid, m_arid, m_rid;
  logic [ADDR_W-1:0]       m_awaddr, m_araddr;
  logic [7:0]              m_awlen, m_arlen;
  logic [2:0]              m_awsize, m_arsize;
  logic [1:0]              m_awburst, m_arburst, m_bresp, m_rresp;
  logic                    m_awvalid, m_awready, m_wvalid, m_wready, m_wlast;
  logic                    m_bvalid, m_bready, m_arvalid, m_arready;
  logic                    m_rvalid, m_rready, m_rlast;
  logic [MST_DATA_W-1:0]   m_wdata, m_rdata;
  logic [MST_DATA_W/8-1:0] m_wstrb;

  dw_downsizer #(
    .ADDR_W     (ADDR_W),
    .ID_W       (ID_W),
    .SLV_DATA_W (SLV_DATA_W),
    .MST_DATA_W (MST_DATA_W),
    .MAX_READS  (MAX_READS)
  ) dut (
    .clk_i(clk), .rst_ni(rst_n),
    .s_awid(s_awid), .s_awaddr(s_awaddr), .s_awlen(s_awlen), .s_awsize(s_awsize),
    .s_awburst(s_awburst), .s_awvalid(s_awvalid), .s_awready(s_awready),
    .s_wdata(s_wdata), .s_wstrb(s_wstrb), .s_wlast(s_wlast),
    .s_wvalid(s_wvalid), .s_wready(s_wready),
    .s_bid(s_bid), .s_bresp(s_bresp), .s_bvalid(s_bvalid), .s_bready(s_bready),
    .s_arid(s_arid), .s_araddr(s_araddr), .s_arlen(s_arlen), .s_arsize(s_arsize),
    .s_arburst(s_arburst), .s_arvalid(s_arvalid), .s_arready(s_arready),
    .s_rid(s_rid), .s_rdata(s_rdata), .s_rresp(s_rresp), .s_rlast(s_rlast),
    .s_rvalid(s_rvalid), .s_rready(s_rready),
    .m_awid(m_awid), .m_awaddr(m_awaddr), .m_awlen(m_awlen), .m_awsize(m_awsize),
    .m_awburst(m_awburst), .m_awvalid(m_awvalid), .m_awready(m_awready),
    .m_wdata(m_wdata), .m_wstrb(m_wstrb), .m_wlast(m_wlast),
    .m_wvalid(m_wvalid), .m_wready(m_wready),
    .m_bid(m_bid), .m_bresp(m_bresp), .m_bvalid(m_bvalid), .m_bready(m_bready),
    .m_arid(m_arid), .m_araddr(m_araddr), .m_arlen(m_arlen), .m_arsize(m_arsize),
    .m_arburst(m_arburst), .m_arvalid(m_arvalid), .m_arready(m_arready),
    .m_rid(m_rid), .m_rdata(m_rdata), .m_rresp(m_rresp), .m_rlast(m_rlast),
    .m_rvalid(m_rvalid), .m_rready(m_rready)
  );

  // ---- bookkeeping types ----
  typedef struct {
    logic [ID_W-1:0]   id;
    logic [ADDR_W-1:0] addr;
    int                usize;
    int                ulen;
    int                dsize;
    int                dlen;
    int                sbb;    // upstream beat bytes
    int                dbb;    // downstream beat bytes
    longint unsigned   nbytes; // total bytes covered
    longint unsigned   sal;    // aligned(addr,size)
    longint unsigned   dal;    // aligned(addr,dsize)
  } txn_t;

  typedef struct {
    logic [ID_W-1:0]     id;
    logic [SLV_DATA_W-1:0] data;
    logic [1:0]          resp;
    bit                  last;
  } rbeat_t;

  typedef struct {
    logic [MST_DATA_W-1:0]   data;
    logic [MST_DATA_W/8-1:0] strb;
    bit                     last;
  } wbeat_t;

  typedef struct {
    logic [ID_W-1:0] id;
    logic [1:0]      resp;
  } bresp_t;

  // ---- state ----
  int      n_fail = 0;
  string   cur_test = "init";

  txn_t    exp_ar_a [16];
  bit      exp_ar_v [16];
  txn_t    exp_aw_a [16];
  bit      exp_aw_v [16];
  bit      ar_open  [16];
  bit      aw_open  [16];
  int      rd_cnt   [16];
  bit      rd_done  [16];
  int      b_cnt    [16];

  txn_t    ds_rd_q [$];
  txn_t    ds_wr_q [$];
  rbeat_t  rb_all  [$];
  wbeat_t  w_all   [$];
  bresp_t  b_all   [$];

  logic [SLV_DATA_W-1:0] drv_data [256];
  logic [7:0]            drv_strb [256];

  int hs_ar_cnt = 0;  // upstream AR handshakes seen by monitor
  int hs_aw_cnt = 0;
  int hs_w_cnt  = 0;  // upstream W handshakes
  int hs_mr_cnt = 0;  // downstream R handshakes
  int hs_mb_cnt = 0;  // downstream B handshakes

  // ---- helpers ----
  function automatic logic [7:0] byte_val(input longint unsigned a);
    return (a * 7 + 13) & 8'hFF;
  endfunction

  function automatic txn_t mk_txn(input logic [ID_W-1:0]   id,
                                  input logic [ADDR_W-1:0] addr,
                                  input logic [7:0]       ulen,
                                  input int               usize);
    txn_t t;
    longint unsigned bb, dsz, first, last, alo, ahi;
    bb   = 64'd1 << usize;
    t.id    = id;
    t.addr  = addr;
    t.usize = usize;
    t.ulen  = int'(ulen);
    t.sbb   = int'(bb);
    t.sal   = addr & ~(bb - 1);
    t.nbytes = (int'(ulen) + 1) * bb - (addr - t.sal);
    t.dsize  = (usize < 1) ? usize : 1;
    dsz      = 64'd1 << t.dsize;
    t.dbb    = int'(dsz);
    t.dal    = addr & ~(dsz - 1);
    first    = addr;
    last     = addr + t.nbytes - 1;
    alo      = first & ~(dsz - 1);
    ahi      = last  & ~(dsz - 1);
    t.dlen   = int'((ahi - alo) / dsz);
    return t;
  endfunction

  function automatic logic [MST_DATA_W-1:0] mk_ds_rdata(input txn_t t, input int k);
    logic [MST_DATA_W-1:0] d;
    longint unsigned A;
    d = '0;
    for (int l = 0; l < t.dbb; l++) begin
      A = t.dal + k * t.dbb + l;
      if (A >= t.addr && A < t.addr + t.nbytes) d[l*8 +: 8] = byte_val(A);
    end
    return d;
  endfunction

  task automatic fail(input string tag);
    $display("FAIL [%s] %s (t=%0t)", cur_test, tag, $time);
    n_fail++;
  endtask

  task automatic wait_neg(input int cycles);
    repeat (cycles) @(negedge clk);
  endtask

  // ---- drivers (acceptance decided by monitor-side handshake counters) ----
  task automatic up_ar(input logic [ID_W-1:0] id, input logic [ADDR_W-1:0] addr,
                       input logic [7:0] len, input logic [2:0] size,
                       input logic [1:0] burst, input int budget, output bit acc);
    int c0;
    acc = 1'b0;
    @(negedge clk);
    s_arid = id; s_araddr = addr; s_arlen = len; s_arsize = size; s_arburst = burst;
    s_arvalid = 1'b1;
    c0 = hs_ar_cnt;
    for (int i = 0; i < budget; i++) begin
      @(posedge clk);
      @(negedge clk);
      if (hs_ar_cnt > c0) begin acc = 1'b1; break; end
    end
    s_arvalid = 1'b0;
  endtask

  task automatic up_aw(input logic [ID_W-1:0] id, input logic [ADDR_W-1:0] addr,
                       input logic [7:0] len, input logic [2:0] size,
                       input logic [1:0] burst, input int budget, output bit acc);
    int c0;
    acc = 1'b0;
    @(negedge clk);
    s_awid = id; s_awaddr = addr; s_awlen = len; s_awsize = size; s_awburst = burst;
    s_awvalid = 1'b1;
    c0 = hs_aw_cnt;
    for (int i = 0; i < budget; i++) begin
      @(posedge clk);
      @(negedge clk);
      if (hs_aw_cnt > c0) begin acc = 1'b1; break; end
    end
    s_awvalid = 1'b0;
  endtask

  task automatic up_wbeat(input logic [SLV_DATA_W-1:0] data,
                          input logic [SLV_DATA_W/8-1:0] strb,
                          input bit last, input int budget, output bit acc);
    int c0;
    acc = 1'b0;
    @(negedge clk);
    s_wdata = data; s_wstrb = strb; s_wlast = last; s_wvalid = 1'b1;
    c0 = hs_w_cnt;
    for (int i = 0; i < budget; i++) begin
      @(posedge clk);
      @(negedge clk);
      if (hs_w_cnt > c0) begin acc = 1'b1; break; end
    end
    s_wvalid = 1'b0;
  endtask

  task automatic ds_rbeat(input logic [ID_W-1:0] mid, input logic [MST_DATA_W-1:0] data,
                          input logic [1:0] resp, input bit last,
                          input int budget, output bit acc);
    int c0;
    acc = 1'b0;
    @(negedge clk);
    m_rid = mid; m_rdata = data; m_rresp = resp; m_rlast = last; m_rvalid = 1'b1;
    c0 = hs_mr_cnt;
    for (int i = 0; i < budget; i++) begin
      @(posedge clk);
      @(negedge clk);
      if (hs_mr_cnt > c0) begin acc = 1'b1; break; end
    end
    m_rvalid = 1'b0;
  endtask

  task automatic ds_bbeat(input logic [ID_W-1:0] mid, input logic [1:0] resp,
                          input int budget, output bit acc);
    int c0;
    acc = 1'b0;
    @(negedge clk);
    m_bid = mid; m_bresp = resp; m_bvalid = 1'b1;
    c0 = hs_mb_cnt;
    for (int i = 0; i < budget; i++) begin
      @(posedge clk);
      @(negedge clk);
      if (hs_mb_cnt > c0) begin acc = 1'b1; break; end
    end
    m_bvalid = 1'b0;
  endtask

  // ---- wait / pop helpers ----
  task automatic wait_ds_rd(input logic [ID_W-1:0] id, input int budget, output bit found);
    found = 1'b0;
    for (int i = 0; i < budget; i++) begin
      for (int q = 0; q < ds_rd_q.size(); q++)
        if (ds_rd_q[q].id == id) begin found = 1'b1; break; end
      if (found) break;
      @(negedge clk);
    end
  endtask

  task automatic wait_ds_rd_any(input int budget, output bit found);
    found = 1'b0;
    for (int i = 0; i < budget; i++) begin
      if (ds_rd_q.size() > 0) begin found = 1'b1; return; end
      @(negedge clk);
    end
  endtask

  task automatic pop_ds_rd(input logic [ID_W-1:0] id, output txn_t t);
    for (int i = 0; i < ds_rd_q.size(); i++)
      if (ds_rd_q[i].id == id) begin
        t = ds_rd_q[i];
        ds_rd_q.delete(i);
        return;
      end
  endtask

  task automatic wait_ds_aw(input logic [ID_W-1:0] id, input int budget, output bit found);
    found = 1'b0;
    for (int i = 0; i < budget; i++) begin
      for (int q = 0; q < ds_wr_q.size(); q++)
        if (ds_wr_q[q].id == id) begin found = 1'b1; break; end
      if (found) break;
      @(negedge clk);
    end
  endtask

  task automatic pop_ds_aw(input logic [ID_W-1:0] id, output txn_t t);
    for (int i = 0; i < ds_wr_q.size(); i++)
      if (ds_wr_q[i].id == id) begin
        t = ds_wr_q[i];
        ds_wr_q.delete(i);
        return;
      end
  endtask

  task automatic wait_rd_done(input logic [ID_W-1:0] id, input int budget, output bit done);
    done = 1'b0;
    for (int i = 0; i < budget; i++) begin
      if (rd_done[id]) begin done = 1'b1; return; end
      @(negedge clk);
    end
  endtask

  task automatic wait_w_cnt(input int n, input int budget, output bit ok);
    ok = 1'b0;
    for (int i = 0; i < budget; i++) begin
      if (w_all.size() >= n) begin ok = 1'b1; return; end
      @(negedge clk);
    end
  endtask

  task automatic wait_b(input logic [ID_W-1:0] id, input int budget, output bit found);
    found = 1'b0;
    for (int i = 0; i < budget; i++) begin
      for (int q = 0; q < b_all.size(); q++)
        if (b_all[q].id == id) begin found = 1'b1; break; end
      if (found) break;
      @(negedge clk);
    end
  endtask

  // ---- downstream read responder (data model + optional sticky errors) ----
  task automatic respond_read(input txn_t t, input logic [255:0] err_mask,
                              input logic [1:0] ecode);
    bit acc;
    for (int k = 0; k <= t.dlen; k++) begin
      ds_rbeat(t.id, mk_ds_rdata(t, k), err_mask[k] ? ecode : 2'b00,
               (k == t.dlen), 800, acc);
      if (!acc) begin fail("A3: downstream R beat never accepted"); return; end
    end
  endtask

  // ---- upstream read-burst checker (D1..D7, A3, C4.4, C4.5) ----
  task automatic check_r_beats(input logic [ID_W-1:0] id, input int mark, input int ulen,
                               input bit refused, input txn_t t,
                               input logic [255:0] err_mask, input logic [1:0] ecode);
    int n;
    n = 0;
    for (int i = mark; i < rb_all.size(); i++) begin
      logic [SLV_DATA_W-1:0]   edata;
      logic [SLV_DATA_W/8-1:0] emask;
      logic [1:0]              eresp;
      longint unsigned         s0;
      longint unsigned         A;
      if (rb_all[i].id != id) continue;
      edata = '0; emask = '0;
      s0 = t.sal + n * t.sbb;
      for (int l = 0; l < t.sbb; l++) begin
        A = s0 + l;
        if (A >= t.addr && A < t.addr + t.nbytes) begin
          edata[(A % 8)*8 +: 8] = byte_val(A);
          emask[A % 8] = 1'b1;
        end
      end
      if (refused) begin
        eresp = 2'b10;
      end else begin
        eresp = 2'b00;
        for (int k = 0; k <= t.dlen; k++)
          if (err_mask[k] && (((t.dal + k * t.dbb - t.sal) / t.sbb) <= n))
            eresp = ecode;
      end
      for (int b = 0; b < 8; b++)
        if (emask[b] && rb_all[i].data[b*8 +: 8] != edata[b*8 +: 8])
          fail("D1/D2: upstream read data or lane placement mismatch");
      if (rb_all[i].resp != eresp)
        fail(refused ? "C4.4: refused read beat not SLVERR"
                     : "D5/D6/D7: upstream read resp mismatch");
      if (rb_all[i].last != (n == ulen))
        fail("D4: s_rlast mismatch");
      n++;
    end
    if (n != ulen + 1)
      fail(refused ? "C4.5/A3: wrong number of R beats for refused read"
                   : "A3: wrong number of upstream R beats");
  endtask

  // ---- one read transaction, end to end ----
  task automatic do_read(input logic [ID_W-1:0] id, input logic [ADDR_W-1:0] addr,
                         input logic [7:0] len, input logic [2:0] size,
                         input logic [1:0] burst, input logic [255:0] err_mask,
                         input logic [1:0] ecode, input bit expect_refuse);
    bit acc, found, done;
    txn_t t, td;
    int mark, nbeats;
    t = mk_txn(id, addr, len, int'(size));
    mark = rb_all.size();
    rd_done[id] = 1'b0;
    up_ar(id, addr, len, size, burst, 800, acc);
    if (!acc) begin fail("A1/C4.1: upstream read address never accepted"); return; end
    if (expect_refuse) begin
      wait_neg(80);
      if (exp_ar_v[id])      fail("C4.2: downstream AR issued for refused read");
      if (ds_rd_q.size() != 0) fail("C4.2: downstream read activity for refused burst");
      wait_rd_done(id, 800, done);
      if (!done) begin fail("C4.5/A3: refused read never responded"); return; end
      check_r_beats(id, mark, int'(len), 1'b1, t, err_mask, ecode);
    end else begin
      wait_ds_rd(id, 800, found);
      if (!found) begin fail("A2: no downstream read transaction issued"); return; end
      pop_ds_rd(id, td);
      respond_read(td, err_mask, ecode);
      wait_rd_done(id, 800, done);
      if (!done) begin fail("A3/D4: upstream read never completed"); return; end
      check_r_beats(id, mark, int'(len), 1'b0, t, err_mask, ecode);
      wait_neg(10);
      nbeats = 0;
      for (int i = mark; i < rb_all.size(); i++) if (rb_all[i].id == id) nbeats++;
      if (nbeats != int'(len) + 1) fail("A3: wrong number of upstream R beats");
      for (int i = mark; i < rb_all.size(); i++)
        if (rb_all[i].id != id) fail("A3/D3: unexpected R beat for another id");
    end
  endtask

  // ---- one write transaction, end to end ----
  task automatic do_write(input logic [ID_W-1:0] id, input logic [ADDR_W-1:0] addr,
                          input logic [7:0] len, input logic [2:0] size,
                          input logic [1:0] burst, input logic [7:0] ovr,
                          input bit use_ovr, input logic [1:0] ds_bresp,
                          input bit expect_refuse);
    bit acc, found, wok;
    txn_t t, td;
    int mark_w, mark_b;
    t = mk_txn(id, addr, len, int'(size));
    mark_w = w_all.size();
    mark_b = b_all.size();
    b_cnt[id] = 0;
    up_aw(id, addr, len, size, burst, 800, acc);
    if (!acc) begin fail("A1/C4.1: upstream write address never accepted"); return; end
    // drive the upstream W burst with lane-correct strobes (X3)
    for (int j = 0; j <= int'(len); j++) begin
      logic [SLV_DATA_W-1:0]   wd;
      logic [SLV_DATA_W/8-1:0] ws;
      longint unsigned A;
      wd = '0; ws = '0;
      for (int l = 0; l < t.sbb; l++) begin
        A = t.sal + j * t.sbb + l;
        if (A >= t.addr && A < t.addr + t.nbytes) begin
          wd[(A % 8)*8 +: 8] = byte_val(A);
          ws[A % 8] = 1'b1;
        end
      end
      if (use_ovr) ws = ovr;
      drv_data[j] = wd;
      drv_strb[j] = ws;
      up_wbeat(wd, ws, (j == int'(len)), 800, acc);
      if (!acc) begin fail("C4.3/A1: upstream W beat never accepted"); return; end
    end
    if (expect_refuse) begin
      wait_neg(80);
      if (w_all.size() != mark_w) fail("C4.3: downstream W beats for refused write");
      if (ds_wr_q.size() != 0)    fail("C4.2: downstream write transaction for refused write");
      wait_b(id, 800, found);
      if (!found) begin fail("C4.4/A3: refused write never responded"); return; end
      if (b_cnt[id] != 1) fail("A3/E5: wrong number of upstream B beats");
      for (int i = mark_b; i < b_all.size(); i++)
        if (b_all[i].id == id && b_all[i].resp != 2'b10)
          fail("C4.4: refused write not SLVERR");
      wait_neg(10);
      if (w_all.size() != mark_w) fail("C4.3: downstream W beats for refused write (late)");
    end else begin
      wait_ds_aw(id, 800, found);
      if (!found) begin fail("A2: no downstream write transaction issued"); return; end
      pop_ds_aw(id, td);
      wait_w_cnt(mark_w + t.dlen + 1, 800, wok);
      if (!wok) begin fail("E3/E4: downstream W burst did not complete"); return; end
      for (int k = 0; k <= t.dlen; k++) begin
        logic [MST_DATA_W-1:0]   edata;
        logic [MST_DATA_W/8-1:0] estrb;
        longint unsigned A;
        int j;
        estrb = '0; edata = '0;
        for (int l = 0; l < t.dbb; l++) begin
          A = t.dal + k * t.dbb + l;
          if (A >= t.sal && A < t.sal + (t.ulen + 1) * t.sbb) begin
            j = int'((A - t.sal) / t.sbb);
            estrb[A % t.dbb] = drv_strb[j][A % 8];
            if (drv_strb[j][A % 8])
              edata[(A % t.dbb)*8 +: 8] = drv_data[j][(A % 8)*8 +: 8];
          end
        end
        if (w_all[mark_w + k].strb != estrb)
          fail("E2/E3: downstream wstrb mismatch");
        for (int b = 0; b < t.dbb; b++)
          if (estrb[b] && w_all[mark_w + k].data[b*8 +: 8] != edata[b*8 +: 8])
            fail("E1: downstream write data mismatch");
        if (w_all[mark_w + k].last != (k == t.dlen))
          fail("E4: m_wlast mismatch");
      end
      wait_neg(10);
      if (w_all.size() != mark_w + t.dlen + 1) fail("E3: extra downstream W beats");
      ds_bbeat(id, ds_bresp, 800, acc);
      if (!acc) begin fail("E5: downstream B never accepted"); return; end
      wait_b(id, 800, found);
      if (!found) begin fail("E5/A3: no upstream B response"); return; end
      if (b_cnt[id] != 1) fail("A3/E5: wrong number of upstream B responses");
      for (int i = mark_b; i < b_all.size(); i++)
        if (b_all[i].id == id && b_all[i].resp != ds_bresp)
          fail("E6: upstream B response code mismatch");
      for (int i = mark_b; i < b_all.size(); i++)
        if (b_all[i].id != id) fail("A3/E5: unexpected upstream B");
    end
  endtask

  // ---- A4: outstanding-read bound ----
  task automatic test_a4;
    bit acc, found, done;
    txn_t t;
    int nacc, mark;
    logic [ID_W-1:0] ids [4];
    logic [ADDR_W-1:0] addrs [4];
    logic [7:0] lens [4];
    mark = rb_all.size();
    ids[0] = 4'h1; addrs[0] = 32'h00008000; lens[0] = 8'd3;
    ids[1] = 4'h2; addrs[1] = 32'h00008100; lens[1] = 8'd1;
    ids[2] = 4'h3; addrs[2] = 32'h00008200; lens[2] = 8'd0;
    ids[3] = 4'h4; addrs[3] = 32'h00008300; lens[3] = 8'd7;
    for (int i = 0; i < 4; i++) rd_done[ids[i]] = 1'b0;
    // try to get MAX_READS reads outstanding without answering any
    nacc = 0;
    for (int i = 0; i < 4; i++) begin
      up_ar(ids[i], addrs[i], lens[i], 3'd3, 2'b01, 1500, acc);
      if (acc) nacc++;
      else break;
    end
    if (nacc == 4) begin
      // a further read must not be accepted while MAX_READS are outstanding
      up_ar(4'h5, 32'h00008400, 8'd0, 3'd3, 2'b01, 60, acc);
      if (acc) fail("A4: read accepted beyond MAX_READS outstanding");
    end
    // answer every arrived downstream read, in arrival order
    for (int i = 0; i < nacc; i++) begin
      wait_ds_rd_any(1500, found);
      if (!found) begin fail("A2: downstream read missing under load"); break; end
      t = ds_rd_q[0];
      ds_rd_q.delete(0);
      respond_read(t, 256'd0, 2'b00);
    end
    for (int i = 0; i < nacc; i++) begin
      wait_rd_done(ids[i], 1500, done);
      if (!done) fail("A3: read under load did not complete");
    end
    for (int i = 0; i < nacc; i++) begin
      t = mk_txn(ids[i], addrs[i], lens[i], 3);
      check_r_beats(ids[i], mark, int'(lens[i]), 1'b0, t, 256'd0, 2'b00);
    end
  endtask

  // ---- L3: two outstanding reads, answered out of order when possible ----
  task automatic test_conc;
    bit acc, found, done, found2;
    txn_t t6, t7, tA, tB;
    int mark;
    mark = rb_all.size();
    rd_done[4'h6] = 1'b0;
    rd_done[4'h7] = 1'b0;
    up_ar(4'h6, 32'h00009000, 8'd1, 3'd3, 2'b01, 800, acc);
    if (!acc) begin fail("A1: concurrent read 6 not accepted"); return; end
    wait_ds_rd(4'h6, 800, found);
    if (!found) begin fail("A2: concurrent read 6 no downstream txn"); return; end
    up_ar(4'h7, 32'h00009100, 8'd3, 3'd3, 2'b01, 800, acc);
    if (!acc) begin
      // implementation serialises: complete 6 first, then 7
      pop_ds_rd(4'h6, t6);
      respond_read(t6, 256'd0, 2'b00);
      wait_rd_done(4'h6, 800, done);
      up_ar(4'h7, 32'h00009100, 8'd3, 3'd3, 2'b01, 800, acc);
      if (!acc) begin fail("A1: concurrent read 7 not accepted"); return; end
      wait_ds_rd(4'h7, 800, found);
      if (!found) begin fail("A2: concurrent read 7 no downstream txn"); return; end
      pop_ds_rd(4'h7, t7);
      respond_read(t7, 256'd0, 2'b00);
      wait_rd_done(4'h7, 800, done);
    end else begin
      wait_ds_rd(4'h7, 800, found);
      if (!found) begin fail("A2: concurrent read 7 no downstream txn"); return; end
      // both pending: answer in reverse arrival order (L3)
      found2 = 1'b0;
      for (int i = 0; i < 100; i++) begin
        if (ds_rd_q.size() >= 2) begin found2 = 1'b1; break; end
        @(negedge clk);
      end
      if (found2) begin
        tA = ds_rd_q[0]; tB = ds_rd_q[1];
        ds_rd_q.delete(1); ds_rd_q.delete(0);
      end else begin
        tA = ds_rd_q[0]; ds_rd_q.delete(0);
        tB = tA; // only one arrived: answer it, then wait for the other
      end
      if (found2) begin
        respond_read(tB, 256'd0, 2'b00);
        respond_read(tA, 256'd0, 2'b00);
      end else begin
        respond_read(tA, 256'd0, 2'b00);
        wait_ds_rd_any(800, found);
        if (!found) begin fail("A2: second concurrent read missing"); return; end
        tB = ds_rd_q[0]; ds_rd_q.delete(0);
        respond_read(tB, 256'd0, 2'b00);
      end
      wait_rd_done(4'h6, 800, done);
      wait_rd_done(4'h7, 800, done);
    end
    t6 = mk_txn(4'h6, 32'h00009000, 8'd1, 3);
    check_r_beats(4'h6, mark, 1, 1'b0, t6, 256'd0, 2'b00);
    t7 = mk_txn(4'h7, 32'h00009100, 8'd3, 3);
    check_r_beats(4'h7, mark, 3, 1'b0, t7, 256'd0, 2'b00);
  endtask

  // ---- F1/F2/F3: asynchronous reset mid-transaction ----
  task automatic test_reset;
    bit acc, found, done;
    txn_t t;
    int cnt_before;
    rd_done[4'h8] = 1'b0;
    up_ar(4'h8, 32'h00006000, 8'd3, 3'd3, 2'b01, 800, acc);
    if (!acc) begin fail("F: setup read not accepted"); return; end
    wait_ds_rd(4'h8, 800, found);
    if (!found) begin fail("F: setup read no downstream txn"); return; end
    pop_ds_rd(4'h8, t);
    // answer only part of the downstream burst, leave the read in flight
    ds_rbeat(t.id, mk_ds_rdata(t, 0), 2'b00, 1'b0, 800, acc);
    ds_rbeat(t.id, mk_ds_rdata(t, 1), 2'b00, 1'b0, 800, acc);
    // asynchronous, active-low reset (F1 is checked by a monitor)
    @(negedge clk);
    rst_n = 1'b0;
    repeat (3) @(negedge clk);
    cnt_before = rd_cnt[4'h8];
    repeat (6) @(posedge clk);   // F1 window
    @(negedge clk);
    rst_n = 1'b1;
    exp_ar_v[4'h8] = 1'b0;
    ar_open[4'h8]   = 1'b0;
    // F3: the pre-reset transaction must not resume
    repeat (50) @(negedge clk);
    if (rd_cnt[4'h8] != cnt_before)
      fail("F3: pre-reset read produced R beats after reset");
    // F2: unit is idle and functional again
    do_read(4'h9, 32'h00007000, 8'd1, 3'd1, 2'b01, 256'd0, 2'b00, 1'b0);
  endtask

  // ---- monitors ----
  always @(posedge clk) if (rst_n && s_arvalid && s_arready) begin
    txn_t t;
    hs_ar_cnt++;
    ar_open[s_arid] = 1'b1;
    if (!(s_arburst == 2'b10 || (s_arburst == 2'b01 && s_arlen != 0))) begin
      t = mk_txn(s_arid, s_araddr, s_arlen, int'(s_arsize));
      exp_ar_v[s_arid] = 1'b1;
      exp_ar_a[s_arid] = t;
    end
  end

  always @(posedge clk) if (rst_n && m_arvalid && m_arready) begin
    txn_t t;
    if (!exp_ar_v[m_arid]) begin
      fail("A2/C4.2: downstream AR without accepted upstream read");
    end else begin
      t = exp_ar_a[m_arid];
      exp_ar_v[m_arid] = 1'b0;
      if (m_araddr != t.addr)          fail("B3: downstream araddr mismatch");
      if (int'(m_arlen) != t.dlen)     fail("B2: downstream arlen mismatch");
      if (int'(m_arsize) != t.dsize)   fail("B1: downstream arsize mismatch");
      if (t.dlen > 0 && m_arburst != 2'b01)
        fail("B4: multi-beat downstream read burst not INCR");
      ds_rd_q.push_back(t);
    end
  end

  always @(posedge clk) if (rst_n && s_rvalid && s_rready) begin
    rbeat_t b;
    if (!ar_open[s_rid]) fail("D3/A3: upstream R beat without outstanding read");
    b.id = s_rid; b.data = s_rdata; b.resp = s_rresp; b.last = s_rlast;
    rb_all.push_back(b);
    rd_cnt[s_rid]++;
    if (s_rlast) begin
      ar_open[s_rid]  = 1'b0;
      rd_done[s_rid]  = 1'b1;
    end
  end

  always @(posedge clk) if (rst_n && s_awvalid && s_awready) begin
    txn_t t;
    hs_aw_cnt++;
    aw_open[s_awid] = 1'b1;
    if (!(s_awburst == 2'b10 || (s_awburst == 2'b01 && s_awlen != 0))) begin
      t = mk_txn(s_awid, s_awaddr, s_awlen, int'(s_awsize));
      exp_aw_v[s_awid] = 1'b1;
      exp_aw_a[s_awid] = t;
    end
  end

  always @(posedge clk) if (rst_n && m_awvalid && m_awready) begin
    txn_t t;
    if (!exp_aw_v[m_awid]) begin
      fail("A2/C4.2: downstream AW without accepted upstream write");
    end else begin
      t = exp_aw_a[m_awid];
      exp_aw_v[m_awid] = 1'b0;
      if (m_awaddr != t.addr)          fail("B3: downstream awaddr mismatch");
      if (int'(m_awlen) != t.dlen)     fail("B2: downstream awlen mismatch");
      if (int'(m_awsize) != t.dsize)   fail("B1: downstream awsize mismatch");
      if (t.dlen > 0 && m_awburst != 2'b01)
        fail("B4: multi-beat downstream write burst not INCR");
      ds_wr_q.push_back(t);
    end
  end

  always @(posedge clk) if (rst_n && m_wvalid && m_wready) begin
    wbeat_t b;
    b.data = m_wdata; b.strb = m_wstrb; b.last = m_wlast;
    w_all.push_back(b);
  end

  always @(posedge clk) if (rst_n && s_wvalid && s_wready) hs_w_cnt++;

  always @(posedge clk) if (rst_n && m_rvalid && m_rready) hs_mr_cnt++;

  always @(posedge clk) if (rst_n && m_bvalid && m_bready) hs_mb_cnt++;

  always @(posedge clk) if (rst_n && s_bvalid && s_bready) begin
    bresp_t b;
    if (!aw_open[s_bid]) fail("E5/A3: upstream B without outstanding write");
    aw_open[s_bid] = 1'b0;
    b.id = s_bid; b.resp = s_bresp;
    b_all.push_back(b);
    b_cnt[s_bid]++;
  end

  // F1: while rst_ni is low the unit presents no valid (from the first edge on)
  always @(posedge clk) if (!rst_n) begin
    if (s_bvalid || s_rvalid || m_awvalid || m_wvalid || m_arvalid)
      fail("F1: valid asserted while rst_ni is low");
  end

  // ---- downstream-slave readiness pattern (gaps allowed by L5) ----
  initial begin : readys
    m_arready = 1'b0; m_awready = 1'b0; m_wready = 1'b0;
    s_rready  = 1'b0; s_bready  = 1'b0;
    forever begin
      @(negedge clk);
      m_arready = 1'b1; m_awready = 1'b1; m_wready = 1'b1; s_rready = 1'b1; s_bready = 1'b1;
      @(negedge clk);
      m_arready = 1'b1; m_awready = 1'b1; m_wready = 1'b0; s_rready = 1'b1; s_bready = 1'b1;
      @(negedge clk);
      m_arready = 1'b0; m_awready = 1'b1; m_wready = 1'b1; s_rready = 1'b0; s_bready = 1'b1;
      @(negedge clk);
      m_arready = 1'b1; m_awready = 1'b0; m_wready = 1'b1; s_rready = 1'b1; s_bready = 1'b0;
    end
  end

  // ---- main sequence ----
  initial begin : main
    repeat (4) @(negedge clk);
    rst_n = 1'b1;
    repeat (4) @(negedge clk);

    // reads: address transform + data path
    cur_test = "T01"; do_read(4'h1, 32'h00001000, 8'd3, 3'd3, 2'b01, 256'd0, 2'b00, 1'b0);
    cur_test = "T02"; do_read(4'h1, 32'h00001004, 8'd1, 3'd3, 2'b01, 256'd0, 2'b00, 1'b0); // dlen 5
    cur_test = "T03"; do_read(4'h1, 32'h00001000, 8'd1, 3'd3, 2'b01, 256'd0, 2'b00, 1'b0); // dlen 7
    cur_test = "T04"; do_read(4'h1, 32'h00001001, 8'd0, 3'd1, 2'b01, 256'd0, 2'b00, 1'b0); // dlen 0
    cur_test = "T05"; do_read(4'h1, 32'h00002000, 8'd3, 3'd0, 2'b01, 256'd0, 2'b00, 1'b0); // size 0 stays 0
    cur_test = "T06"; do_read(4'h1, 32'h00002002, 8'd1, 3'd1, 2'b01, 256'd0, 2'b00, 1'b0);
    cur_test = "T07"; do_read(4'h1, 32'h00002010, 8'd1, 3'd2, 2'b01, 256'd0, 2'b00, 1'b0); // size 2 -> 1
    cur_test = "T08"; do_read(4'h1, 32'h00002020, 8'd0, 3'd3, 2'b00, 256'd0, 2'b00, 1'b0); // FIXED len 0 (C3)

    // reads: sticky downstream errors (D6/D7)
    cur_test = "T09"; do_read(4'h1, 32'h00002100, 8'd1, 3'd3, 2'b01, 256'h001, 2'b10, 1'b0); // err beat 0
    cur_test = "T10"; do_read(4'h1, 32'h00002140, 8'd1, 3'd3, 2'b01, 256'h008, 2'b10, 1'b0); // err beat 3
    cur_test = "T11"; do_read(4'h1, 32'h00002180, 8'd1, 3'd3, 2'b01, 256'h080, 2'b10, 1'b0); // err last beat
    cur_test = "T12"; do_read(4'h1, 32'h000021C0, 8'd1, 3'd3, 2'b01, 256'h001, 2'b11, 1'b0); // DECERR kept

    // refused reads (C1/C2/C4)
    cur_test = "T13"; do_read(4'h1, 32'h00001000, 8'd3, 3'd3, 2'b10, 256'd0, 2'b00, 1'b1); // WRAP
    cur_test = "T14"; do_read(4'h1, 32'h00001000, 8'd1, 3'd3, 2'b01, 256'd0, 2'b00, 1'b1); // FIXED len 1

    // writes: data path + strobe splitting (E1..E6)
    cur_test = "T15"; do_write(4'h2, 32'h00003000, 8'd3, 3'd3, 2'b01, 8'h00, 1'b0, 2'b00, 1'b0);
    cur_test = "T16"; do_write(4'h2, 32'h00003010, 8'd0, 3'd3, 2'b01, 8'h81, 1'b1, 2'b00, 1'b0); // 01 00 00 10
    cur_test = "T17"; do_write(4'h2, 32'h00003020, 8'd0, 3'd3, 2'b01, 8'h0F, 1'b1, 2'b00, 1'b0); // last two 00
    cur_test = "T18"; do_write(4'h2, 32'h00003004, 8'd1, 3'd3, 2'b01, 8'h00, 1'b0, 2'b00, 1'b0); // unaligned
    cur_test = "T19"; do_write(4'h2, 32'h00003040, 8'd1, 3'd0, 2'b01, 8'h00, 1'b0, 2'b00, 1'b0); // size 0
    cur_test = "T20"; do_write(4'h2, 32'h00003052, 8'd1, 3'd1, 2'b01, 8'h00, 1'b0, 2'b00, 1'b0); // size 1
    cur_test = "T21"; do_write(4'h2, 32'h00003060, 8'd3, 3'd3, 2'b01, 8'h00, 1'b0, 2'b10, 1'b0); // ds SLVERR
    cur_test = "T22"; do_write(4'h2, 32'h00003064, 8'd0, 3'd3, 2'b01, 8'h00, 1'b0, 2'b11, 1'b0); // ds DECERR
    cur_test = "T23"; do_write(4'h2, 32'h00003080, 8'd0, 3'd3, 2'b00, 8'h00, 1'b0, 2'b00, 1'b0); // FIXED len 0 (C3)

    // refused writes (C1/C2/C4)
    cur_test = "T24"; do_write(4'h2, 32'h00003090, 8'd3, 3'd3, 2'b10, 8'h00, 1'b0, 2'b00, 1'b1); // WRAP
    cur_test = "T25"; do_write(4'h2, 32'h000030A0, 8'd1, 3'd3, 2'b01, 8'h00, 1'b0, 2'b00, 1'b1); // FIXED len 1

    // outstanding reads and interleaving
    cur_test = "T26"; test_a4;
    cur_test = "T27"; test_conc;

    // reset behaviour
    cur_test = "T28"; test_reset;

    if (n_fail == 0) $display("RESULT: PASS");
    else             $display("RESULT: FAIL (%0d violations)", n_fail);
    $finish;
  end

  // ---- watchdog: terminates unconditionally ----
  initial begin : watchdog
    #4_000_000;
    $display("RESULT: FAIL (watchdog: no forward progress)");
    $finish;
  end

endmodule
