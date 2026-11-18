// ---------------------------------------------------------------------------
// dw_downsizer_tb -- self-checking testbench for the AXI4 data-width downsizer.
// Scored configuration: 64-bit upstream, 16-bit downstream, ratio 4,
// ADDR_W=32, ID_W=4, MAX_READS=4, async active-low reset.
//
// Clause coverage:
//   A1..A4  acceptance, 1:1 downstream txn (id/addr), 1 upstream response,
//           outstanding-read bound
//   B1..B4  downstream size = min(size,1), len = blocks-spanned, addr kept,
//           INCR when multi-beat (single-beat burst type NOT checked: L6)
//   C3/C4   FIXED len==0 served; WRAP / FIXED len!=0 refused: accepted
//           upstream, zero downstream activity, W absorbed, SLVERR on every
//           upstream response beat, correct beat count and rlast
//   D1..D7  byte stream, lane placement, rid, rlast, OKAY, sticky+grouped
//           error precedence, error code preserved (SLVERR and DECERR)
//   E1..E6  byte stream, per-lane strobe split, unstrobed beats still emitted,
//           m_wlast, one B with matching id, error code passed through
//   F1..F3  mid-flight reset: nothing completes/originates after release,
//           unit idle and MAX_READS available again
// Deliberately NOT checked (latitude): latencies, ready timing, ordering
// between transactions, buffering style, single-beat downstream burst type,
// output values while valid is low or while reset is low.
// ---------------------------------------------------------------------------
module dw_downsizer_tb;

  localparam int unsigned ADDR_W = 32;
  localparam int unsigned ID_W   = 4;
  localparam int unsigned SDW    = 64;   // upstream width
  localparam int unsigned MDW    = 16;   // downstream width

  logic clk;
  initial begin clk = 1'b0; forever #5 clk = ~clk; end

  logic rst_n;
  initial rst_n = 1'b0;

  // ---- upstream (slave-side, WIDE) port signals ----
  logic [ID_W-1:0]   s_awid, s_arid, s_bid, s_rid;
  logic [ADDR_W-1:0] s_awaddr, s_araddr;
  logic [7:0]        s_awlen, s_arlen;
  logic [2:0]        s_awsize, s_arsize;
  logic [1:0]        s_awburst, s_arburst, s_bresp, s_rresp;
  logic              s_awvalid, s_awready, s_wvalid, s_wready, s_wlast;
  logic              s_bvalid, s_bready, s_arvalid, s_arready;
  logic              s_rvalid, s_rready, s_rlast;
  logic [SDW-1:0]    s_wdata, s_rdata;
  logic [SDW/8-1:0]  s_wstrb;

  // ---- downstream (master-side, NARROW) port signals ----
  logic [ID_W-1:0]   m_awid, m_arid, m_bid, m_rid;
  logic [ADDR_W-1:0] m_awaddr, m_araddr;
  logic [7:0]        m_awlen, m_arlen;
  logic [2:0]        m_awsize, m_arsize;
  logic [1:0]        m_awburst, m_arburst, m_bresp, m_rresp;
  logic              m_awvalid, m_awready, m_wvalid, m_wready, m_wlast;
  logic              m_bvalid, m_bready, m_arvalid, m_arready;
  logic              m_rvalid, m_rready, m_rlast;
  logic [MDW-1:0]    m_wdata, m_rdata;
  logic [MDW/8-1:0]  m_wstrb;

  dw_downsizer #(
    .ADDR_W     (ADDR_W),
    .ID_W       (ID_W),
    .SLV_DATA_W (SDW),
    .MST_DATA_W (MDW),
    .MAX_READS  (4)
  ) dut (
    .clk_i     (clk),
    .rst_ni    (rst_n),
    .s_awid    (s_awid),   .s_awaddr (s_awaddr), .s_awlen  (s_awlen),
    .s_awsize  (s_awsize), .s_awburst(s_awburst),.s_awvalid(s_awvalid),
    .s_awready (s_awready),
    .s_wdata   (s_wdata),  .s_wstrb  (s_wstrb),  .s_wlast  (s_wlast),
    .s_wvalid  (s_wvalid), .s_wready (s_wready),
    .s_bid     (s_bid),    .s_bresp  (s_bresp),  .s_bvalid (s_bvalid),
    .s_bready  (s_bready),
    .s_arid    (s_arid),   .s_araddr (s_araddr), .s_arlen (s_arlen),
    .s_arsize  (s_arsize), .s_arburst(s_arburst),.s_arvalid(s_arvalid),
    .s_arready (s_arready),
    .s_rid     (s_rid),    .s_rdata  (s_rdata),  .s_rresp (s_rresp),
    .s_rlast   (s_rlast),  .s_rvalid (s_rvalid),  .s_rready(s_rready),
    .m_awid    (m_awid),   .m_awaddr (m_awaddr),  .m_awlen (m_awlen),
    .m_awsize  (m_awsize), .m_awburst(m_awburst), .m_awvalid(m_awvalid),
    .m_awready (m_awready),
    .m_wdata   (m_wdata),  .m_wstrb  (m_wstrb),   .m_wlast (m_wlast),
    .m_wvalid  (m_wvalid), .m_wready (m_wready),
    .m_bid     (m_bid),    .m_bresp  (m_bresp),   .m_bvalid(m_bvalid),
    .m_bready  (m_bready),
    .m_arid    (m_arid),   .m_araddr (m_araddr),  .m_arlen (m_arlen),
    .m_arsize  (m_arsize), .m_arburst(m_arburst), .m_arvalid(m_arvalid),
    .m_arready (m_arready),
    .m_rid     (m_rid),    .m_rdata  (m_rdata),   .m_rresp (m_rresp),
    .m_rlast   (m_rlast),  .m_rvalid (m_rvalid),   .m_rready(m_rready)
  );

  // ---- handshake counters (bookkeeping, not value matching) ----
  int c_maw = 0, c_mw = 0, c_mar = 0, c_mr = 0, c_sb = 0, c_sr = 0;
  always @(posedge clk) begin
    if (rst_n) begin
      if (m_awvalid && m_awready) c_maw = c_maw + 1;
      if (m_wvalid  && m_wready)  c_mw  = c_mw  + 1;
      if (m_arvalid && m_arready) c_mar = c_mar + 1;
      if (m_rvalid  && m_rready)  c_mr  = c_mr  + 1;
      if (s_bvalid  && s_bready)  c_sb  = c_sb  + 1;
      if (s_rvalid  && s_rready)  c_sr  = c_sr  + 1;
    end
  end

  int errors = 0;
  int rbeat4 [0:3];

  // ---- capture variables for handshake payloads ----
  logic [ID_W-1:0]   cap_id, cap_rid, cap_bid;
  logic [ADDR_W-1:0] cap_addr;
  logic [7:0]        cap_len;
  logic [2:0]        cap_size;
  logic [1:0]        cap_burst, cap_rresp, cap_bresp;
  logic [SDW-1:0]    cap_rdata;
  logic [MDW-1:0]    cap_wdata;
  logic [MDW/8-1:0]  cap_wstrb;
  logic              cap_rlast, cap_wlast;

  // ---- watchdog: fires regardless of what the design does ----
  initial begin
    #4_000_000;
    $display("RESULT: FAIL (watchdog: no forward progress)");
    $finish;
  end

  task automatic fail(input string req, input string msg);
    errors = errors + 1;
    $display("FAIL [%0s] %0s", req, msg);
  endtask

  // deterministic per-test, per-stream-index byte pattern
  function automatic logic [7:0] pat(input int t, input int k);
    return 8'((t * 61 + k * 13 + 5) & 8'hFF);
  endfunction

  // ---- reset (asserted/released away from the sampling edge) ----
  task automatic bfm_reset(input int cycles = 4);
    @(negedge clk);
    rst_n = 1'b0;
    repeat (cycles) @(posedge clk);
    @(negedge clk);
    rst_n = 1'b1;
  endtask

  task automatic settle(input int cycles);
    repeat (cycles) @(posedge clk);
  endtask

  task automatic recover();
    bfm_reset(3);
    settle(10);
  endtask

  // ---- upstream drivers ----
  task automatic bfm_ar(input logic [ID_W-1:0]  id,
                        input logic [ADDR_W-1:0] addr,
                        input logic [7:0]  len,
                        input logic [2:0]  size,
                        input logic [1:0]  burst,
                        input int          budget,
                        output bit         accepted);
    int waited = 0;
    accepted = 1'b0;
    @(negedge clk);
    s_arid = id; s_araddr = addr; s_arlen = len;
    s_arsize = size; s_arburst = burst; s_arvalid = 1'b1;
    while (waited < budget) begin
      @(posedge clk);
      if (s_arready) begin accepted = 1'b1; break; end
      waited = waited + 1;
    end
    @(negedge clk);
    s_arvalid = 1'b0;
  endtask

  task automatic bfm_aw(input logic [ID_W-1:0]  id,
                        input logic [ADDR_W-1:0] addr,
                        input logic [7:0]  len,
                        input logic [2:0]  size,
                        input logic [1:0]  burst,
                        input int          budget,
                        output bit         accepted);
    int waited = 0;
    accepted = 1'b0;
    @(negedge clk);
    s_awid = id; s_awaddr = addr; s_awlen = len;
    s_awsize = size; s_awburst = burst; s_awvalid = 1'b1;
    while (waited < budget) begin
      @(posedge clk);
      if (s_awready) begin accepted = 1'b1; break; end
      waited = waited + 1;
    end
    @(negedge clk);
    s_awvalid = 1'b0;
  endtask

  task automatic bfm_w(input logic [SDW-1:0]   data,
                       input logic [SDW/8-1:0] strb,
                       input logic              last,
                       input int                budget,
                       output bit               ok);
    int w = 0;
    ok = 1'b0;
    @(negedge clk);
    s_wdata = data; s_wstrb = strb; s_wlast = last; s_wvalid = 1'b1;
    while (w < budget) begin
      @(posedge clk);
      if (s_wready) begin ok = 1'b1; break; end
      w = w + 1;
    end
    @(negedge clk);
    s_wvalid = 1'b0;
  endtask

  // ---- downstream responders ----
  task automatic m_put_r(input logic [ID_W-1:0] mid,
                         input logic [MDW-1:0]  data,
                         input logic             last,
                         input logic [1:0]      resp,
                         input int              budget,
                         output bit             ok);
    int w = 0;
    ok = 1'b0;
    @(negedge clk);
    m_rid = mid; m_rdata = data; m_rlast = last; m_rresp = resp; m_rvalid = 1'b1;
    while (w < budget) begin
      @(posedge clk);
      if (m_rready) begin ok = 1'b1; break; end
      w = w + 1;
    end
    @(negedge clk);
    m_rvalid = 1'b0;
  endtask

  task automatic m_put_b(input logic [ID_W-1:0] mid,
                         input logic [1:0]      resp,
                         input int              budget,
                         output bit             ok);
    int w = 0;
    ok = 1'b0;
    @(negedge clk);
    m_bid = mid; m_bresp = resp; m_bvalid = 1'b1;
    while (w < budget) begin
      @(posedge clk);
      if (m_bready) begin ok = 1'b1; break; end
      w = w + 1;
    end
    @(negedge clk);
    m_bvalid = 1'b0;
  endtask

  // ---- handshake waiters (capture payload at the transfer edge) ----
  task automatic m_wait_aw(input int budget, output bit ok);
    int w = 0;
    ok = 1'b0;
    while (w < budget) begin
      @(posedge clk);
      if (m_awvalid && m_awready) begin
        cap_id = m_awid; cap_addr = m_awaddr; cap_len = m_awlen;
        cap_size = m_awsize; cap_burst = m_awburst;
        ok = 1'b1; break;
      end
      w = w + 1;
    end
  endtask

  task automatic m_wait_ar(input int budget, output bit ok);
    int w = 0;
    ok = 1'b0;
    while (w < budget) begin
      @(posedge clk);
      if (m_arvalid && m_arready) begin
        cap_id = m_arid; cap_addr = m_araddr; cap_len = m_arlen;
        cap_size = m_arsize; cap_burst = m_arburst;
        ok = 1'b1; break;
      end
      w = w + 1;
    end
  endtask

  task automatic m_wait_w(input int budget, output bit ok);
    int w = 0;
    ok = 1'b0;
    while (w < budget) begin
      @(posedge clk);
      if (m_wvalid && m_wready) begin
        cap_wdata = m_wdata; cap_wstrb = m_wstrb; cap_wlast = m_wlast;
        ok = 1'b1; break;
      end
      w = w + 1;
    end
  endtask

  task automatic s_wait_r(input int budget, output bit ok);
    int w = 0;
    ok = 1'b0;
    while (w < budget) begin
      @(posedge clk);
      if (s_rvalid && s_rready) begin
        cap_rid = s_rid; cap_rdata = s_rdata;
        cap_rresp = s_rresp; cap_rlast = s_rlast;
        ok = 1'b1; break;
      end
      w = w + 1;
    end
  endtask

  task automatic s_wait_b(input int budget, output bit ok);
    int w = 0;
    ok = 1'b0;
    while (w < budget) begin
      @(posedge clk);
      if (s_bvalid && s_bready) begin
        cap_bid = s_bid; cap_bresp = s_bresp;
        ok = 1'b1; break;
      end
      w = w + 1;
    end
  endtask

  // no further upstream responses may appear once a transaction retired (A3)
  task automatic quiet_check(input int cycles, input string req);
    int b0, r0;
    @(negedge clk);
    b0 = c_sb; r0 = c_sr;
    repeat (cycles) @(posedge clk);
    @(negedge clk);
    if (c_sb != b0) fail(req, "extra upstream B response after transaction completed");
    if (c_sr != r0) fail(req, "extra upstream R beat after transaction completed");
  endtask

  // ------------------------------------------------------------------------
  // do_read: one upstream read, fully checked. err_beat indexes the
  // downstream beats (-1 = inject no error); refuse expects a C4 refusal.
  // ------------------------------------------------------------------------
  task automatic do_read(input int              t,
                         input logic [ID_W-1:0]  id,
                         input logic [ADDR_W-1:0] addr,
                         input logic [7:0]      len,
                         input logic [2:0]      size,
                         input logic [1:0]      burst,
                         input int              err_beat,
                         input logic [1:0]      err_code,
                         input bit              refuse);
    int total, dsize, dlen, G, ub, db, off;
    int mar0, mr0;
    int b, l, A, k, lane;
    int rj, rl, rA, rk;
    bit acc, rok, cok;
    logic [MDW-1:0]   mdata;
    logic [SDW-1:0]    exp_d;
    logic [SDW/8-1:0] exp_m;
    logic [1:0]       eres;

    off   = addr - ((addr >> size) << size);
    total = (len + 1) * (1 << size) - off;
    dsize = (size > 1) ? 1 : size;                      // B1: min(size,1)
    dlen  = ((addr + total - 1) >> dsize) - (addr >> dsize); // B2: blocks spanned
    G     = (1 << size) / (1 << dsize);                 // downstream beats per upstream beat
    ub    = len + 1;
    db    = dlen + 1;

    if (refuse) begin
      @(negedge clk);
      mar0 = c_mar; mr0 = c_mr;
      bfm_ar(id, addr, len, size, burst, 500, acc);
      if (!acc) fail("C4", "refused read not accepted on the upstream AR channel (C4.1)");
      for (b = 0; b < ub; b++) begin
        s_wait_r(500, cok);
        if (!cok) begin fail("C4", "timeout waiting for R beat of refused read (C4.4/C4.5)"); break; end
        if (cap_rid != id)              fail("D3", "refused read R beat id mismatch");
        if (cap_rresp != 2'b10)         fail("C4", "refused read R beat not SLVERR (C4.4)");
        if (cap_rlast != (b == ub - 1)) fail("C4", "rlast placement wrong on refused read (C4.5)");
      end
      @(negedge clk);
      if (c_mar != mar0) fail("C4", "downstream AR issued for refused read (C4.2)");
      if (c_mr  != mr0) fail("C4", "downstream R activity for refused read (C4.2)");
      quiet_check(16, "A3");
    end else begin
      @(negedge clk);
      mar0 = c_mar;
      fork
        begin : drv
          bfm_ar(id, addr, len, size, burst, 500, acc);
          if (!acc) fail("A1", "upstream read address not accepted");
        end
        begin : rsp
          m_wait_ar(2000, rok);
          if (!rok) fail("A2", "no downstream AR for accepted read");
          else begin
            if (cap_id != id)        fail("A2", "downstream AR id mismatch");
            if (cap_addr != addr)    fail("B3", $sformatf("downstream AR addr %08x expected %08x", cap_addr, addr));
            if (int'(cap_len) != dlen)  fail("B2", $sformatf("downstream AR len %0d expected %0d", cap_len, dlen));
            if (int'(cap_size) != dsize) fail("B1", $sformatf("downstream AR size %0d expected %0d", cap_size, dsize));
            if (dlen > 0 && cap_burst != 2'b01) fail("B4", "multi-beat downstream burst not INCR");
            for (rj = 0; rj < db; rj++) begin
              mdata = {MDW{1'b1}};
              for (rl = 0; rl < (1 << dsize); rl++) begin
                rA = addr + rj * (1 << dsize) + rl;
                rk = rA - addr;
                if (rk < total) mdata[(rA % 2) * 8 +: 8] =  pat(t, rk);
                else            mdata[(rA % 2) * 8 +: 8] = ~pat(t, rk);
              end
              m_put_r(id, mdata, (rj == db - 1),
                      (rj == err_beat) ? err_code : 2'b00, 500, rok);
              if (!rok) begin fail("D1", "timeout driving downstream R beat"); break; end
            end
          end
        end
        begin : col
          for (b = 0; b < ub; b++) begin
            s_wait_r(2000, cok);
            if (!cok) begin fail("A3", "timeout waiting upstream R beat"); break; end
            if (cap_rid != id) fail("D3", "upstream R id mismatch");
            exp_d = '0; exp_m = '0;
            for (l = 0; l < (1 << size); l++) begin
              A = addr + b * (1 << size) + l;
              k = A - addr;
              if (k < total) begin
                exp_d[(A % 8) * 8 +: 8] = pat(t, k);   // D2: lane = addr mod 8
                exp_m[A % 8] = 1'b1;
              end
            end
            for (lane = 0; lane < 8; lane++) begin
              if (exp_m[lane] && cap_rdata[lane*8 +: 8] != exp_d[lane*8 +: 8])
                fail("D1", $sformatf("upstream R beat %0d lane %0d data mismatch (D1/D2)", b, lane));
            end
            if (err_beat >= 0 && err_beat < (b + 1) * G) eres = err_code; // D6 sticky
            else                                            eres = 2'b00;      // D5
            if (cap_rresp != eres)
              fail("D6", $sformatf("upstream R beat %0d resp %0d expected %0d (D6/D7)", b, cap_rresp, eres));
            if (cap_rlast != (b == ub - 1)) fail("D4", "s_rlast placement wrong");
          end
        end
      join
      @(negedge clk);
      if (c_mar != mar0 + 1) fail("A2", "downstream AR count wrong for accepted read");
      quiet_check(16, "A3");
    end
  endtask

  // ------------------------------------------------------------------------
  // do_write: one upstream write, fully checked. lmask is the lane strobe
  // mask (lane-correct per X3); bresp is the downstream B code to return.
  // ------------------------------------------------------------------------
  task automatic do_write(input int              t,
                          input logic [ID_W-1:0]  id,
                          input logic [ADDR_W-1:0] addr,
                          input logic [7:0]      len,
                          input logic [2:0]      size,
                          input logic [1:0]      burst,
                          input logic [7:0]      lmask,
                          input logic [1:0]      bresp,
                          input bit              refuse);
    int total, dsize, dlen, ub, db, off;
    int maw0, mw0;
    int b, l, A, k;
    int rj, rl, rA, rk, rl2;
    bit acc, ok, rok;
    logic [SDW-1:0]    wdata;
    logic [SDW/8-1:0]  wstrb;
    logic [MDW-1:0]    edata;
    logic [MDW/8-1:0]  estrb, edmask;

    off   = addr - ((addr >> size) << size);
    total = (len + 1) * (1 << size) - off;
    dsize = (size > 1) ? 1 : size;
    dlen  = ((addr + total - 1) >> dsize) - (addr >> dsize);
    ub    = len + 1;
    db    = dlen + 1;

    if (refuse) begin
      @(negedge clk);
      maw0 = c_maw; mw0 = c_mw;
      bfm_aw(id, addr, len, size, burst, 500, acc);
      if (!acc) fail("C4", "refused write not accepted on the upstream AW channel (C4.1)");
      for (b = 0; b < ub; b++) begin
        wdata = '0; wstrb = '0;
        for (l = 0; l < (1 << size); l++) begin
          A = addr + b * (1 << size) + l;
          k = A - addr;
          wdata[(A % 8) * 8 +: 8] = pat(t, k);
          wstrb[A % 8] = lmask[A % 8] && (k < total);
        end
        bfm_w(wdata, wstrb, (b == ub - 1), 500, ok);
        if (!ok) begin fail("C4", "refused write W beat not absorbed (C4.3)"); break; end
      end
      s_wait_b(500, ok);
      if (!ok) fail("C4", "no B response for refused write (C4.4)");
      else begin
        if (cap_bid != id)       fail("E5", "refused write B id mismatch");
        if (cap_bresp != 2'b10) fail("C4", "refused write B not SLVERR (C4.4)");
      end
      @(negedge clk);
      if (c_maw != maw0) fail("C4", "downstream AW issued for refused write (C4.2)");
      if (c_mw  != mw0)  fail("C4", "downstream W beat issued for refused write (C4.2)");
      quiet_check(16, "A3");
    end else begin
      @(negedge clk);
      maw0 = c_maw; mw0 = c_mw;
      fork
        begin : drv
          bfm_aw(id, addr, len, size, burst, 500, acc);
          if (!acc) fail("A1", "upstream write address not accepted");
          for (b = 0; b < ub; b++) begin
            wdata = '0; wstrb = '0;
            for (l = 0; l < (1 << size); l++) begin
              A = addr + b * (1 << size) + l;
              k = A - addr;
              wdata[(A % 8) * 8 +: 8] = pat(t, k);
              wstrb[A % 8] = lmask[A % 8] && (k < total);
            end
            bfm_w(wdata, wstrb, (b == ub - 1), 1000, ok);
            if (!ok) begin fail("E1", "upstream W beat not accepted"); break; end
          end
        end
        begin : rsp
          m_wait_aw(2000, rok);
          if (!rok) fail("A2", "no downstream AW for accepted write");
          else begin
            if (cap_id != id)           fail("A2", "downstream AW id mismatch");
            if (cap_addr != addr)       fail("B3", "downstream AW addr mismatch");
            if (int'(cap_len) != dlen)  fail("B2", $sformatf("downstream AW len %0d expected %0d", cap_len, dlen));
            if (int'(cap_size) != dsize) fail("B1", "downstream AW size mismatch");
            if (dlen > 0 && cap_burst != 2'b01) fail("B4", "multi-beat downstream write burst not INCR");
            for (rj = 0; rj < db; rj++) begin
              m_wait_w(2000, rok);
              if (!rok) begin fail("E1", "timeout waiting downstream W beat"); break; end
              edata = '0; estrb = '0; edmask = '0;
              for (rl = 0; rl < (1 << dsize); rl++) begin
                rA = addr + rj * (1 << dsize) + rl;
                rk = rA - addr;
                estrb[rA % 2] = lmask[rA % 8] && (rk < total);   // E2/E3
                if (rk < total && lmask[rA % 8]) begin
                  edata[(rA % 2) * 8 +: 8] = pat(t, rk);
                  edmask[rA % 2] = 1'b1;
                end
              end
              if (cap_wstrb != estrb)
                fail("E2", $sformatf("downstream W beat %0d strb %02x expected %02x (E2/E3)",
                      rj, cap_wstrb, estrb));
              for (rl2 = 0; rl2 < 2; rl2++) begin
                if (edmask[rl2] && cap_wdata[rl2*8 +: 8] != edata[rl2*8 +: 8])
                  fail("E1", $sformatf("downstream W beat %0d lane %0d data mismatch", rj, rl2));
              end
              if (cap_wlast != (rj == db - 1)) fail("E4", "m_wlast placement wrong");
            end
            m_put_b(id, bresp, 500, rok);
            if (!rok) fail("E5", "timeout driving downstream B");
          end
        end
      join
      s_wait_b(1000, ok);
      if (!ok) fail("E5", "timeout waiting upstream B (A3/E5)");
      else begin
        if (cap_bid != id) fail("E5", "upstream B id mismatch");
        if (cap_bresp != bresp)
          fail("E6", $sformatf("upstream B resp %0d expected %0d", cap_bresp, bresp));
      end
      @(negedge clk);
      if (c_maw != maw0 + 1)    fail("A2", "downstream AW count wrong for accepted write");
      if (c_mw  != mw0 + db)    fail("E3", $sformatf("downstream W beat count %0d expected %0d",
                                                    c_mw - mw0, db));
      quiet_check(16, "A3");
    end
  endtask

  // ------------------------------------------------------------------------
  // A4: four reads outstanding, a fifth must not be accepted; all four are
  // then served (in whatever order the design issues them) and checked.
  // ------------------------------------------------------------------------
  task automatic test_a4();
    int i, j, l, A, k, nb, bb, total, dsize, dlen, db, mar0;
    bit acc, ok, rok;
    logic [MDW-1:0]    mdata;
    logic [ID_W-1:0]   tid;
    logic [ADDR_W-1:0] a4addr;

    @(negedge clk);
    mar0 = c_mar;
    for (i = 0; i < 4; i++) begin
      tid = i[ID_W-1:0];
      bfm_ar(tid, 32'hA000 + i * 64, 8'd1, 3'd3, 2'b01, 500, acc);
      if (!acc) fail("A4", "read not accepted with fewer than MAX_READS outstanding");
    end
    // four reads outstanding (no downstream data returned yet)
    bfm_ar(4'd4, 32'hA000 + 4 * 64, 8'd1, 3'd3, 2'b01, 200, acc);
    if (acc) fail("A4", "5th read accepted while MAX_READS reads outstanding");

    for (i = 0; i < 4; i++) begin
      m_wait_ar(1000, rok);
      if (!rok) begin fail("A2", "missing downstream AR (A4 test)"); break; end
      total = (cap_len + 1) * (1 << cap_size)
              - (cap_addr - ((cap_addr >> cap_size) << cap_size));
      dsize = (cap_size > 1) ? 1 : cap_size;
      dlen  = ((cap_addr + total - 1) >> dsize) - (cap_addr >> dsize);
      db    = dlen + 1;
      for (j = 0; j < db; j++) begin
        mdata = {MDW{1'b1}};
        for (l = 0; l < (1 << dsize); l++) begin
          A = cap_addr + j * (1 << dsize) + l;
          k = A - cap_addr;
          if (k < total) mdata[(A % 2) * 8 +: 8] =  pat(100 + cap_id, k);
          else           mdata[(A % 2) * 8 +: 8] = ~pat(100 + cap_id, k);
        end
        m_put_r(cap_id, mdata, (j == db - 1), 2'b00, 500, rok);
        if (!rok) begin fail("D1", "timeout driving R beat (A4)"); break; end
      end
    end

    for (i = 0; i < 4; i++) rbeat4[i] = 0;
    for (nb = 0; nb < 8; nb++) begin
      s_wait_r(1000, ok);
      if (!ok) begin fail("A3", "timeout collecting upstream R beats (A4)"); break; end
      if (cap_rid > 3) fail("D3", "unexpected rid on R beat (A4)");
      else begin
        bb = rbeat4[cap_rid];
        rbeat4[cap_rid] = bb + 1;
        a4addr = 32'hA000 + cap_rid * 64;
        for (l = 0; l < 8; l++) begin
          A = a4addr + bb * 8 + l;
          k = bb * 8 + l;
          if (cap_rdata[(A % 8) * 8 +: 8] != pat(100 + cap_rid, k))
            fail("D1", $sformatf("A4 read id %0d beat %0d lane %0d data mismatch (D1/D2)",
                  cap_rid, bb, A % 8));
        end
        if (cap_rresp != 2'b00) fail("D5", "A4 read R resp not OKAY");
        if (cap_rlast != (bb == 1)) fail("D4", "A4 rlast placement wrong");
      end
    end
    for (i = 0; i < 4; i++)
      if (rbeat4[i] != 2)
        fail("A3", $sformatf("read id %0d produced %0d R beats, expected 2", i, rbeat4[i]));
    @(negedge clk);
    if (c_mar != mar0 + 4) fail("A2", "downstream AR count wrong (A4)");
    quiet_check(32, "A3");
  endtask

  // ------------------------------------------------------------------------
  // F1..F3: reset mid-transaction; nothing may complete or originate after
  // release, and the unit must be fully usable again.
  // ------------------------------------------------------------------------
  task automatic test_reset();
    bit acc, rok;
    int aw0, w0, ar0, b0, r0;
    fork
      begin : d1
        bfm_ar(4'd5, 32'h9000, 8'd1, 3'd3, 2'b01, 500, acc);
        if (!acc) fail("A1", "reset-test read not accepted");
      end
      begin : r1
        m_wait_ar(1000, rok);
        if (rok) m_put_r(4'd5, 16'hA55A, 1'b0, 2'b00, 500, rok);
      end
    join
    // transaction in flight (one of eight downstream beats given): reset
    bfm_reset(4);
    // F3: nothing from the pre-reset transaction after release
    @(negedge clk);
    aw0 = c_maw; w0 = c_mw; ar0 = c_mar; b0 = c_sb; r0 = c_sr;
    repeat (32) @(posedge clk);
    @(negedge clk);
    if (c_mar != ar0) fail("F3", "downstream AR after reset for pre-reset transaction");
    if (c_maw != aw0) fail("F3", "downstream AW after reset");
    if (c_mw  != w0)  fail("F3", "downstream W beat after reset");
    if (c_sb  != b0)  fail("F3", "upstream B after reset for pre-reset transaction");
    if (c_sr  != r0)  fail("F3", "upstream R beat after reset for pre-reset transaction");
    // F2: unit idle and working again
    do_read(90, 4'd6, 32'h9100, 8'd0, 3'd3, 2'b01, -1, 2'b00, 1'b0);
  endtask

  // ------------------------------------------------------------------------
  // Main sequence. Every case named "Measured" in the spec is exercised.
  // ------------------------------------------------------------------------
  initial begin
    s_awid = '0; s_awaddr = '0; s_awlen = '0; s_awsize = '0; s_awburst = '0; s_awvalid = 1'b0;
    s_wdata = '0; s_wstrb = '0; s_wlast = 1'b0; s_wvalid = 1'b0;
    s_arid = '0; s_araddr = '0; s_arlen = '0; s_arsize = '0; s_arburst = '0; s_arvalid = 1'b0;
    s_bready = 1'b1; s_rready = 1'b1;
    m_awready = 1'b1; m_wready = 1'b1; m_arready = 1'b1; m_bready = 1'b1; m_rready = 1'b1;
    m_rid = '0; m_rdata = '0; m_rlast = 1'b0; m_rresp = 2'b00; m_rvalid = 1'b0;
    m_bid = '0; m_bresp = 2'b00; m_bvalid = 1'b0;

    bfm_reset(4);
    settle(10);

    // ---- reads: address transform (B1..B4) and data path (D1..D7) ----
    do_read (1, 4'd1, 32'h1000, 8'd1, 3'd3, 2'b01, -1, 2'b00, 1'b0); // dlen 7
    recover();
    do_read (2, 4'd1, 32'h1004, 8'd1, 3'd3, 2'b01, -1, 2'b00, 1'b0); // unaligned -> dlen 5
    recover();
    do_read (3, 4'd2, 32'h1001, 8'd0, 3'd1, 2'b01, -1, 2'b00, 1'b0); // 1 byte -> dlen 0
    recover();
    do_read (4, 4'd2, 32'h2001, 8'd0, 3'd0, 2'b01, -1, 2'b00, 1'b0); // size 0 stays 0
    recover();
    do_read (5, 4'd3, 32'h3002, 8'd0, 3'd2, 2'b01, -1, 2'b00, 1'b0); // size 2 -> 1
    recover();
    do_read (6, 4'd3, 32'h4000, 8'd0, 3'd3, 2'b01, -1, 2'b00, 1'b0); // dlen 3
    recover();
    do_read (7, 4'd3, 32'h5000, 8'd0, 3'd3, 2'b00, -1, 2'b00, 1'b0); // FIXED len0 served (C3)
    recover();
    do_read (8, 4'd4, 32'h5100, 8'd1, 3'd3, 2'b10, -1, 2'b00, 1'b1); // WRAP refused (C1/C4)
    recover();
    do_read (9, 4'd4, 32'h5200, 8'd1, 3'd3, 2'b00, -1, 2'b00, 1'b1); // FIXED len1 refused (C2/C4)
    recover();
    // sticky error precedence, 2 upstream beats of 4 downstream beats each
    do_read (10, 4'd5, 32'h8000, 8'd1, 3'd3, 2'b01, 0, 2'b10, 1'b0); // err d0  -> SLVERR SLVERR
    recover();
    do_read (11, 4'd5, 32'h8000, 8'd1, 3'd3, 2'b01, 3, 2'b10, 1'b0); // err d3  -> SLVERR SLVERR
    recover();
    do_read (12, 4'd5, 32'h8000, 8'd1, 3'd3, 2'b01, 7, 2'b10, 1'b0); // err last -> OKAY SLVERR
    recover();
    do_read (13, 4'd5, 32'h8000, 8'd1, 3'd3, 2'b01, 0, 2'b11, 1'b0); // DECERR preserved (D7)
    recover();

    // ---- writes: data path (E1..E6) ----
    do_write(20, 4'd6, 32'h6000, 8'd0, 3'd3, 2'b01, 8'h81, 2'b00, 1'b0); // strb 0x81 -> 01 00 00 10
    recover();
    do_write(21, 4'd6, 32'h6100, 8'd0, 3'd3, 2'b01, 8'h0F, 2'b00, 1'b0); // unstrobed beats emitted
    recover();
    do_write(22, 4'd6, 32'h7004, 8'd1, 3'd3, 2'b01, 8'hFF, 2'b00, 1'b0); // unaligned, full strobes
    recover();
    do_write(23, 4'd7, 32'h7300, 8'd0, 3'd1, 2'b01, 8'h03, 2'b00, 1'b0); // size 1 single beat
    recover();
    do_write(24, 4'd7, 32'h7400, 8'd1, 3'd3, 2'b01, 8'hFF, 2'b10, 1'b0); // downstream SLVERR -> B SLVERR
    recover();
    do_write(25, 4'd7, 32'h7500, 8'd0, 3'd3, 2'b00, 8'hFF, 2'b00, 1'b0); // FIXED len0 write served
    recover();
    do_write(26, 4'd8, 32'h7600, 8'd1, 3'd3, 2'b10, 8'hFF, 2'b00, 1'b1); // WRAP write refused
    recover();
    do_write(27, 4'd8, 32'h7700, 8'd1, 3'd3, 2'b00, 8'hFF, 2'b00, 1'b1); // FIXED len1 write refused
    recover();
    do_write(28, 4'd9, 32'h7800, 8'd0, 3'd3, 2'b01, 8'hFF, 2'b11, 1'b0); // DECERR passthrough (E6)
    recover();

    // ---- outstanding reads bound (A4) ----
    test_a4();
    recover();

    // ---- reset behaviour (F1..F3), then A4 again to prove F2 ----
    test_reset();
    recover();
    test_a4();

    if (errors == 0) $display("RESULT: PASS");
    else             $display("RESULT: FAIL");
    $finish;
  end

endmodule
