// ---------------------------------------------------------------------------
// dw_downsizer testbench -- decides the contract in spec/dw_downsizer_spec.md
// Upstream (wide) port driven as master, downstream (narrow) port answered as
// slave.  All waits are bounded; the watchdog guarantees termination.
// ---------------------------------------------------------------------------
module dw_downsizer_tb;

  localparam int unsigned ADDR_W     = 32;
  localparam int unsigned ID_W       = 4;
  localparam int unsigned SLV_DATA_W = 64;
  localparam int unsigned MST_DATA_W = 16;

  // ---- clock / reset ------------------------------------------------------
  logic clk;
  initial begin clk = 1'b0; forever #5 clk = ~clk; end
  logic rst_n;
  initial rst_n = 1'b0;

  // ---- upstream (slave-side, WIDE) signals --------------------------------
  logic [ID_W-1:0]         s_awid, s_arid, s_bid;
  logic [ADDR_W-1:0]       s_awaddr, s_araddr;
  logic [7:0]              s_awlen, s_arlen;
  logic [2:0]              s_awsize, s_arsize;
  logic [1:0]              s_awburst, s_arburst, s_bresp, s_rresp;
  logic                    s_awvalid, s_awready, s_wvalid, s_wready, s_wlast;
  logic [SLV_DATA_W-1:0]   s_wdata, s_rdata;
  logic [SLV_DATA_W/8-1:0] s_wstrb;
  logic                    s_bvalid, s_bready, s_rvalid, s_rready, s_rlast;

  // ---- downstream (master-side, NARROW) signals ----------------------------
  logic [ID_W-1:0]         m_awid, m_arid, m_bid, m_rid;
  logic [ADDR_W-1:0]       m_awaddr, m_araddr;
  logic [7:0]              m_awlen, m_arlen;
  logic [2:0]              m_awsize, m_arsize;
  logic [1:0]              m_awburst, m_arburst, m_bresp, m_rresp;
  logic                    m_awvalid, m_awready, m_wvalid, m_wready, m_wlast;
  logic [MST_DATA_W-1:0]   m_wdata, m_rdata;
  logic [MST_DATA_W/8-1:0] m_wstrb;
  logic                    m_bvalid, m_bready, m_rvalid, m_rready, m_rlast;

  // ---- DUT -----------------------------------------------------------------
  dw_downsizer #(
    .ADDR_W     (ADDR_W),
    .ID_W       (ID_W),
    .SLV_DATA_W (SLV_DATA_W),
    .MST_DATA_W (MST_DATA_W),
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
    .s_arid    (s_arid),   .s_araddr (s_araddr), .s_arlen  (s_arlen),
    .s_arsize  (s_arsize), .s_arburst(s_arburst),.s_arvalid(s_arvalid),
    .s_arready (s_arready),
    .s_rid     (s_rid),    .s_rdata  (s_rdata),  .s_rresp  (s_rresp),
    .s_rlast   (s_rlast),  .s_rvalid (s_rvalid), .s_rready (s_rready),
    .m_awid    (m_awid),   .m_awaddr (m_awaddr), .m_awlen  (m_awlen),
    .m_awsize  (m_awsize), .m_awburst(m_awburst),.m_awvalid(m_awvalid),
    .m_awready (m_awready),
    .m_wdata   (m_wdata),  .m_wstrb  (m_wstrb),  .m_wlast  (m_wlast),
    .m_wvalid  (m_wvalid), .m_wready (m_wready),
    .m_bid     (m_bid),    .m_bresp  (m_bresp),  .m_bvalid (m_bvalid),
    .m_bready  (m_bready),
    .m_arid    (m_arid),   .m_araddr (m_araddr), .m_arlen  (m_arlen),
    .m_arsize  (m_arsize), .m_arburst(m_arburst),.m_arvalid(m_arvalid),
    .m_arready (m_arready),
    .m_rid     (m_rid),    .m_rdata  (m_rdata),  .m_rresp  (m_rresp),
    .m_rlast   (m_rlast),  .m_rvalid (m_rvalid), .m_rready (m_rready)
  );

  // TB is a permanent-taker on the channels it may take (L2: DUT may not
  // rely on readiness, but nothing forbids the TB slave being always ready).
  assign s_bready  = rst_n;
  assign s_rready  = rst_n;
  assign m_awready = rst_n;
  assign m_wready  = rst_n;
  assign m_bready  = rst_n;
  assign m_arready = rst_n;
  assign m_rready  = rst_n;

  // ---- bookkeeping types ---------------------------------------------------
  typedef struct {
    logic [ADDR_W-1:0] addr;
    int                len;
    int                size;
    bit                refused;
    int                dsize;
    int                dlen;
    int                total_bytes;
    int                err_ds_beat;   // -1 = no injected downstream error
    logic [1:0]        err_code;
  } txn_t;

  typedef struct packed {
    logic [ID_W-1:0]       rid;
    logic [SLV_DATA_W-1:0] rdata;
    logic [1:0]            rresp;
    logic                  rlast;
  } rrec_t;

  typedef struct packed {
    logic [ID_W-1:0] bid;
    logic [1:0]      bresp;
  } brec_t;

  txn_t  exp_rd [logic [ID_W-1:0]];
  txn_t  exp_wr [logic [ID_W-1:0]];
  bit    aw_seen [logic [ID_W-1:0]];
  int    awc     [logic [ID_W-1:0]];
  int    wbc     [logic [ID_W-1:0]];

  rrec_t          up_r_q [$];
  brec_t          up_b_q [$];
  logic [ID_W-1:0] ds_ar_q [$];
  logic [SLV_DATA_W/8-1:0] w_strb_q [$];   // upstream strobe per upstream W beat
  logic [ID_W-1:0] cur_ds_w_id;

  int              errors;
  logic [ID_W-1:0] nid;

  // ---- helpers --------------------------------------------------------------
  function automatic int bbs(input int s);
    return 1 << s;
  endfunction

  function automatic logic [ADDR_W-1:0] align_a(input logic [ADDR_W-1:0] a,
                                                input int s);
    return a & ~((ADDR_W'(1) << s) - ADDR_W'(1));
  endfunction

  function automatic logic [7:0] bval(input logic [ADDR_W-1:0] a);
    return a[7:0] ^ 8'h5A;      // per-address data pattern
  endfunction

  task automatic err(input string msg);
    errors++;
    $display("FAIL [%0t] %s", $time, msg);
  endtask

  task automatic wait_cycles(input int n);
    repeat (n) @(posedge clk);
  endtask

  // ---- BFM tasks (drive on negedge, sample on posedge) ----------------------
  task automatic bfm_reset(input int cycles = 4);
    @(negedge clk); rst_n = 1'b0;
    repeat (cycles) @(posedge clk);
    @(negedge clk); rst_n = 1'b1;
  endtask

  task automatic bfm_ar(input logic [ID_W-1:0] id, input logic [ADDR_W-1:0] addr,
                        input logic [7:0] len, input logic [2:0] asize,
                        input logic [1:0] aburst,
                        input int budget, output bit accepted, output int waited);
    accepted = 1'b0; waited = 0;
    @(negedge clk);
    s_arid = id; s_araddr = addr; s_arlen = len;
    s_arsize = asize; s_arburst = aburst; s_arvalid = 1'b1;
    while (waited < budget) begin
      @(posedge clk);
      if (s_arready) begin accepted = 1'b1; break; end
      waited++;
    end
    @(negedge clk) s_arvalid = 1'b0;
  endtask

  task automatic bfm_aw(input logic [ID_W-1:0] id, input logic [ADDR_W-1:0] addr,
                        input logic [7:0] len, input logic [2:0] asize,
                        input logic [1:0] aburst,
                        input int budget, output bit accepted, output int waited);
    accepted = 1'b0; waited = 0;
    @(negedge clk);
    s_awid = id; s_awaddr = addr; s_awlen = len;
    s_awsize = asize; s_awburst = aburst; s_awvalid = 1'b1;
    while (waited < budget) begin
      @(posedge clk);
      if (s_awready) begin accepted = 1'b1; break; end
      waited++;
    end
    @(negedge clk) s_awvalid = 1'b0;
  endtask

  task automatic bfm_w(input logic [SLV_DATA_W-1:0] data,
                       input logic [SLV_DATA_W/8-1:0] strb,
                       input logic last,
                       input int budget, output bit accepted);
    accepted = 1'b0;
    @(negedge clk);
    s_wdata = data; s_wstrb = strb; s_wlast = last; s_wvalid = 1'b1;
    for (int i = 0; i < budget; i++) begin
      @(posedge clk);
      if (s_wready) begin accepted = 1'b1; break; end
    end
    @(negedge clk) s_wvalid = 1'b0;
  endtask

  task automatic bfm_rbeat(input logic [ID_W-1:0] mid,
                           input logic [MST_DATA_W-1:0] data,
                           input logic last, input logic [1:0] resp,
                           input int budget);
    bit done;
    @(negedge clk);
    m_rid = mid; m_rdata = data; m_rlast = last; m_rresp = resp; m_rvalid = 1'b1;
    done = 1'b0;
    for (int i = 0; (i < budget) && !done; i++) begin
      @(posedge clk);
      if (m_rready) done = 1'b1;
    end
    @(negedge clk) m_rvalid = 1'b0;
  endtask

  task automatic bfm_bbeat(input logic [ID_W-1:0] mid, input logic [1:0] resp,
                           input int budget);
    bit done;
    @(negedge clk);
    m_bid = mid; m_bresp = resp; m_bvalid = 1'b1;
    done = 1'b0;
    for (int i = 0; (i < budget) && !done; i++) begin
      @(posedge clk);
      if (m_bready) done = 1'b1;
    end
    @(negedge clk) m_bvalid = 1'b0;
  endtask

  // ---- bounded waits --------------------------------------------------------
  task automatic wait_up_r(input int budget, output bit got);
    got = 1'b0;
    for (int i = 0; i < budget; i++) begin
      if (up_r_q.size() > 0) begin got = 1'b1; return; end
      @(posedge clk);
    end
  endtask

  task automatic wait_up_b(input int budget, output bit got);
    got = 1'b0;
    for (int i = 0; i < budget; i++) begin
      if (up_b_q.size() > 0) begin got = 1'b1; return; end
      @(posedge clk);
    end
  endtask

  task automatic wait_ds_ar(input int budget, output bit got);
    got = 1'b0;
    for (int i = 0; i < budget; i++) begin
      if (ds_ar_q.size() > 0) begin got = 1'b1; return; end
      @(posedge clk);
    end
  endtask

  task automatic wait_ds_aw(input logic [ID_W-1:0] id, input int budget,
                            output bit got);
    got = 1'b0;
    for (int i = 0; i < budget; i++) begin
      if (aw_seen[id]) begin got = 1'b1; return; end
      @(posedge clk);
    end
  endtask

  task automatic wait_wcnt(input logic [ID_W-1:0] id, input int cnt,
                           input int budget, output bit got);
    got = 1'b0;
    for (int i = 0; i < budget; i++) begin
      if (wbc.exists(id) && (wbc[id] >= cnt)) begin got = 1'b1; return; end
      @(posedge clk);
    end
  endtask

  // ---- expected-transaction model -------------------------------------------
  task automatic make_exp(input logic [ADDR_W-1:0] addr, input int len,
                          input int size, input bit refuse, input int err_beat,
                          input logic [1:0] ecode, output txn_t t);
    logic [ADDR_W-1:0] first_a, last_a;
    t.addr = addr; t.len = len; t.size = size; t.refused = refuse;
    t.err_ds_beat = err_beat; t.err_code = ecode;
    t.dsize = 0; t.dlen = 0; t.total_bytes = 0;
    if (!refuse) begin
      t.dsize = (size < 1) ? size : 1;                       // B1
      t.total_bytes = (len + 1) * bbs(size)
                      - (addr - align_a(addr, size));
      first_a = addr;
      last_a  = addr + t.total_bytes - 1;
      t.dlen  = (align_a(last_a, t.dsize) - align_a(first_a, t.dsize))
                >> t.dsize;                                  // B2
    end
  endtask

  // ---- downstream request checkers (called from monitors) --------------------
  task automatic check_ds_ar(input logic [ID_W-1:0] aid,
                             input logic [ADDR_W-1:0] aaddr,
                             input logic [7:0] alen,
                             input logic [2:0] asize,
                             input logic [1:0] aburst);
    txn_t t;
    if (!exp_rd.exists(aid)) begin
      err("C4.2/A2: downstream AR with no matching accepted read");
      return;
    end
    t = exp_rd[aid];
    if (t.refused) begin err("C4.2: downstream AR for refused read"); return; end
    if (aaddr  != t.addr)  err("B3: downstream AR address mismatch");
    if (alen   != t.dlen)  err("B2: downstream AR length mismatch");
    if (asize  != t.dsize) err("B1: downstream AR size mismatch");
    if ((t.dlen > 0) && (aburst != 2'b01))
      err("B4: multi-beat downstream burst must be INCR");
  endtask

  task automatic check_ds_aw(input logic [ID_W-1:0] aid,
                             input logic [ADDR_W-1:0] aaddr,
                             input logic [7:0] alen,
                             input logic [2:0] asize,
                             input logic [1:0] aburst);
    txn_t t;
    if (!exp_wr.exists(aid)) begin
      err("C4.2/A2: downstream AW with no matching accepted write");
      return;
    end
    t = exp_wr[aid];
    if (t.refused) begin err("C4.2: downstream AW for refused write"); return; end
    if (aaddr  != t.addr)  err("B3: downstream AW address mismatch");
    if (alen   != t.dlen)  err("B2: downstream AW length mismatch");
    if (asize  != t.dsize) err("B1: downstream AW size mismatch");
    if ((t.dlen > 0) && (aburst != 2'b01))
      err("B4: multi-beat downstream burst must be INCR");
  endtask

  task automatic check_ds_w(input logic [ID_W-1:0] wid,
                            input logic [MST_DATA_W-1:0] data,
                            input logic [MST_DATA_W/8-1:0] strb,
                            input logic last);
    txn_t t;
    logic [ADDR_W-1:0] a0, last_a;
    int j, ub;
    bit sb;
    if (!exp_wr.exists(wid)) begin
      err("E1/C4.2: downstream W beat with no matching write");
      return;
    end
    t = exp_wr[wid];
    if (t.refused) begin err("C4.2: downstream W beat for refused write"); return; end
    if (!wbc.exists(wid)) wbc[wid] = 0;
    j = wbc[wid];
    if (j > t.dlen) begin err("E3/B2: too many downstream W beats"); return; end
    last_a = t.addr + t.total_bytes - 1;
    for (int k = 0; k < bbs(t.dsize); k++) begin
      a0 = align_a(t.addr, t.dsize) + j * bbs(t.dsize) + k;
      ub = (align_a(a0, t.size) - align_a(t.addr, t.size)) >> t.size;
      sb = 1'b0;
      if ((ub >= 0) && (ub < w_strb_q.size()))
        sb = w_strb_q[ub][a0 % 8];
      if (strb[k] !== sb)
        err("E2: downstream W strobe mismatch");
      if (sb && (data[8*k +: 8] !== bval(a0)))
        err("E1: downstream W data byte mismatch");
    end
    if (last !== (j == t.dlen)) err("E4: m_wlast mismatch");
    wbc[wid] = j + 1;
  endtask

  // ---- monitors --------------------------------------------------------------
  always @(posedge clk) begin
    if (rst_n && s_rvalid && s_rready) begin
      automatic rrec_t r = '0;
      r.rid = s_rid; r.rdata = s_rdata; r.rresp = s_rresp; r.rlast = s_rlast;
      up_r_q.push_back(r);
    end
  end

  always @(posedge clk) begin
    if (rst_n && s_bvalid && s_bready) begin
      automatic brec_t b = '0;
      b.bid = s_bid; b.bresp = s_bresp;
      up_b_q.push_back(b);
    end
  end

  always @(posedge clk) begin
    if (rst_n && m_arvalid && m_arready) begin
      check_ds_ar(m_arid, m_araddr, m_arlen, m_arsize, m_arburst);
      ds_ar_q.push_back(m_arid);
    end
  end

  always @(posedge clk) begin
    if (rst_n && m_awvalid && m_awready) begin
      check_ds_aw(m_awid, m_awaddr, m_awlen, m_awsize, m_awburst);
      cur_ds_w_id = m_awid;
      aw_seen[m_awid] = 1'b1;
      if (awc.exists(m_awid)) awc[m_awid] = awc[m_awid] + 1;
      else                   awc[m_awid] = 1;
    end
  end

  always @(posedge clk) begin
    if (rst_n && m_wvalid && m_wready)
      check_ds_w(cur_ds_w_id, m_wdata, m_wstrb, m_wlast);
  end

  // ---- downstream slave responses --------------------------------------------
  task automatic respond_read(input logic [ID_W-1:0] id);
    txn_t t;
    logic [MST_DATA_W-1:0] d;
    logic [1:0] resp;
    t = exp_rd[id];
    for (int j = 0; j <= t.dlen; j++) begin
      d = '0;
      for (int k = 0; k < bbs(t.dsize); k++)
        d[8*k +: 8] = bval(align_a(t.addr, t.dsize) + j * bbs(t.dsize) + k);
      resp = (j == t.err_ds_beat) ? t.err_code : 2'b00;
      bfm_rbeat(id, d, (j == t.dlen), resp, 5000);
    end
  endtask

  // ---- upstream response checker ----------------------------------------------
  task automatic check_read_up(input logic [ID_W-1:0] id);
    txn_t t;
    rrec_t r;
    logic [ADDR_W-1:0] base, last_a, a0;
    logic [1:0] exp_resp;
    int g;
    bit got;
    t = exp_rd[id];
    last_a = t.addr + t.total_bytes - 1;
    for (int i = 0; i <= t.len; i++) begin
      wait_up_r(2000, got);
      if (!got) begin err("A3/C4.5: missing upstream R beat"); return; end
      r = up_r_q.pop_front();
      if (r.rid !== id) err("D3: upstream R id mismatch");
      if (t.refused) begin
        exp_resp = 2'b10;                                    // C4.4
      end else begin
        g = bbs(t.size) / bbs(t.dsize);
        if ((t.err_ds_beat >= 0) && (t.err_ds_beat <= (i + 1) * g - 1))
          exp_resp = t.err_code;                             // D6/D7
        else
          exp_resp = 2'b00;                                  // D5
        base = align_a(t.addr, t.size) + i * bbs(t.size);
        for (int l = 0; l < bbs(t.size); l++) begin
          a0 = base + l;
          if ((a0 >= t.addr) && (a0 <= last_a)) begin
            if (r.rdata[8*(a0 % 8) +: 8] !== bval(a0))
              err("D1/D2: upstream R data/lane mismatch");
          end
        end
      end
      if (r.rresp !== exp_resp)
        err("D5/D6/D7/C4.4: upstream R response mismatch");
      if (r.rlast !== (i == t.len)) err("D4: s_rlast mismatch");
    end
  endtask

  // ---- one write transaction ---------------------------------------------------
  task automatic do_write(input logic [ID_W-1:0] id, input logic [ADDR_W-1:0] addr,
                          input int len, input int size, input int burst,
                          input bit refuse, input logic [1:0] ds_bresp,
                          input bit use_ov,
                          input logic [SLV_DATA_W/8-1:0] strb_ov);
    txn_t t;
    bit acc, got, wacc;
    int waited;
    logic [SLV_DATA_W-1:0] d;
    logic [SLV_DATA_W/8-1:0] sb;
    logic [ADDR_W-1:0] base, last_a, a0;
    brec_t b;
    // clean slate (previous transaction was fully consumed)
    up_r_q.delete(); up_b_q.delete(); ds_ar_q.delete(); w_strb_q.delete();
    make_exp(addr, len, size, refuse, -1, 2'b00, t);
    exp_wr[id] = t;
    aw_seen[id] = 1'b0;
    wbc[id] = 0;
    if (awc.exists(id)) awc[id] = 0; else awc[id] = 0;
    bfm_aw(id, addr, len[7:0], size[2:0], burst[1:0], 2000, acc, waited);
    if (!acc) begin
      err("A2/C4.1: write address never accepted");
      exp_wr.delete(id); aw_seen.delete(id); wbc.delete(id); awc.delete(id);
      return;
    end
    last_a = addr + t.total_bytes - 1;
    for (int i = 0; i <= len; i++) begin
      d = '0; sb = '0;
      base = align_a(addr, size) + i * bbs(size);
      for (int l = 0; l < bbs(size); l++) begin
        a0 = base + l;
        if ((a0 >= addr) && (a0 <= last_a)) begin
          d[8*(a0 % 8) +: 8] = bval(a0);
          sb[a0 % 8] = 1'b1;                 // lane-correct strobes (X3)
        end
      end
      if (use_ov) sb = strb_ov;
      w_strb_q.push_back(sb);
      bfm_w(d, sb, (i == len), 2000, wacc);
      if (!wacc) begin
        err("A3/C4.3: upstream W beat never accepted");
        exp_wr.delete(id); aw_seen.delete(id); wbc.delete(id); awc.delete(id);
        return;
      end
    end
    if (refuse) begin
      wait_up_b(2000, got);
      if (!got) begin
        err("A3/C4.4: no upstream B for refused write");
      end else begin
        b = up_b_q.pop_front();
        if (b.bid !== id) err("E5: upstream B id mismatch");
        if (b.bresp !== 2'b10) err("C4.4: refused write must answer SLVERR");
      end
      if (aw_seen[id]) err("C4.2: downstream AW for refused write");
    end else begin
      wait_ds_aw(id, 2000, got);
      if (!got) begin
        err("A2: no downstream AW for accepted write");
        exp_wr.delete(id); aw_seen.delete(id); wbc.delete(id); awc.delete(id);
        return;
      end
      wait_wcnt(id, t.dlen + 1, 2000, got);
      if (!got) begin
        err("B2/E3: downstream W beat count mismatch");
        exp_wr.delete(id); aw_seen.delete(id); wbc.delete(id); awc.delete(id);
        return;
      end
      bfm_bbeat(id, ds_bresp, 5000);
      wait_up_b(2000, got);
      if (!got) begin
        err("E5: no upstream B for write");
      end else begin
        b = up_b_q.pop_front();
        if (b.bid !== id) err("E5: upstream B id mismatch");
        if (b.bresp !== ds_bresp) err("E6: upstream B response mismatch");
      end
    end
    wait_cycles(20);
    if (up_b_q.size() != 0) err("A3: extra upstream B beats");
    if (!refuse && (awc[id] != 1)) err("A2: not exactly one downstream AW");
    if (refuse  && (awc[id] != 0)) err("A2/C4.2: downstream AW for refused write");
    up_b_q.delete();
    exp_wr.delete(id); aw_seen.delete(id); wbc.delete(id); awc.delete(id);
  endtask

  // ---- one read transaction ------------------------------------------------------
  task automatic do_read(input logic [ID_W-1:0] id, input logic [ADDR_W-1:0] addr,
                         input int len, input int size, input int burst,
                         input bit refuse, input int err_beat,
                         input logic [1:0] ecode);
    txn_t t;
    bit acc, got;
    int waited;
    logic [ID_W-1:0] rid;
    up_r_q.delete(); up_b_q.delete(); ds_ar_q.delete();
    make_exp(addr, len, size, refuse, err_beat, ecode, t);
    exp_rd[id] = t;
    bfm_ar(id, addr, len[7:0], size[2:0], burst[1:0], 2000, acc, waited);
    if (!acc) begin
      err("A2/C4.1: read address never accepted");
      exp_rd.delete(id);
      return;
    end
    if (refuse) begin
      // C4.2: any downstream AR is flagged by the monitor.
      check_read_up(id);
    end else begin
      wait_ds_ar(2000, got);
      if (!got) begin
        err("A2: no downstream AR for accepted read");
        exp_rd.delete(id);
        return;
      end
      rid = ds_ar_q.pop_front();
      respond_read(rid);
      check_read_up(rid);
    end
    wait_cycles(20);
    if (up_r_q.size() != 0) err("A3: extra upstream R beats");
    if (ds_ar_q.size() != 0) err("A2: extra downstream AR");
    up_r_q.delete(); ds_ar_q.delete();
    exp_rd.delete(id);
  endtask

  // ---- MAX_READS outstanding, interleaved completion (A4, D3, L3) ----------------
  task automatic do_four_reads();
    txn_t t;
    bit acc, got;
    int waited;
    logic [ID_W-1:0] rid;
    logic [ID_W-1:0] ids [0:3];
    up_r_q.delete(); up_b_q.delete(); ds_ar_q.delete();
    for (int k = 0; k < 4; k++) begin
      ids[k] = nid; nid = nid + 1;
      make_exp(32'h8000 + k * 64, 1, 3, 1'b0, -1, 2'b00, t);
      exp_rd[ids[k]] = t;
      bfm_ar(ids[k], t.addr, 8'd1, 3'd3, 2'b01, 2000, acc, waited);
      if (!acc) err("A2/A4: read address not accepted");
    end
    for (int k = 0; k < 4; k++) begin
      wait_ds_ar(2000, got);
      if (!got) begin err("A2: missing downstream AR"); break; end
      rid = ds_ar_q.pop_front();      // completion order is free (L3)
      respond_read(rid);
      check_read_up(rid);
      exp_rd.delete(rid);
    end
    wait_cycles(20);
    if (up_r_q.size() != 0) err("A3: extra upstream R beats");
    up_r_q.delete(); ds_ar_q.delete();
  endtask

  // ---- reset behaviour (F1..F3) ---------------------------------------------------
  task automatic do_reset_test();
    bit acc, got;
    int waited;
    txn_t t;
    logic [ID_W-1:0] id;
    up_r_q.delete(); up_b_q.delete(); ds_ar_q.delete();
    id = nid; nid = nid + 1;
    make_exp(32'h9000, 0, 1, 1'b0, -1, 2'b00, t);
    exp_rd[id] = t;
    bfm_ar(id, 32'h9000, 8'd0, 3'd1, 2'b01, 2000, acc, waited);
    if (!acc) begin
      err("A2: reset-test read not accepted");
      exp_rd.delete(id);
      return;
    end
    wait_ds_ar(2000, got);
    if (!got) begin
      err("A2: no downstream AR before reset");
      exp_rd.delete(id);
      return;
    end
    ds_ar_q.pop_front();               // read left deliberately unfinished
    // F1: asynchronous, active-low reset; no valid while low
    @(negedge clk); rst_n = 1'b0;
    repeat (3) begin
      @(posedge clk);
      if (s_rvalid || s_bvalid || m_awvalid || m_wvalid ||
          m_bvalid || m_arvalid)
        err("F1: valid asserted while rst_ni low");
    end
    @(negedge clk); rst_n = 1'b1;
    // F3: the pre-reset read must not be answered after the reset
    for (int i = 0; i < 100; i++) begin
      @(posedge clk);
      if (s_rvalid) begin
        err("F3: response after reset for pre-reset transaction");
        break;
      end
    end
    up_r_q.delete(); up_b_q.delete(); ds_ar_q.delete();
    exp_rd.delete(id);
    // F2: unit is idle afterwards; a fresh read is served
    do_read(nid, 32'h9100, 0, 1, 1, 1'b0, -1, 2'b00);
    nid = nid + 1;
  endtask

  // ---- watchdog --------------------------------------------------------------------
  initial begin
    #4_000_000;
    $display("RESULT: FAIL (watchdog: no forward progress)");
    $finish;
  end

  // ---- main sequence -----------------------------------------------------------------
  initial begin
    s_awid = '0; s_awaddr = '0; s_awlen = '0; s_awsize = '0;
    s_awburst = '0; s_awvalid = 1'b0;
    s_wdata = '0; s_wstrb = '0; s_wlast = 1'b0; s_wvalid = 1'b0;
    s_arid = '0; s_araddr = '0; s_arlen = '0; s_arsize = '0;
    s_arburst = '0; s_arvalid = 1'b0;
    m_rid = '0; m_rdata = '0; m_rlast = 1'b0; m_rresp = '0; m_rvalid = 1'b0;
    m_bid = '0; m_bresp = '0; m_bvalid = 1'b0;
    errors = 0; nid = 0; cur_ds_w_id = '0;

    bfm_reset(4);
    wait_cycles(10);

    // ---------------- writes ----------------
    do_write(nid, 32'h1000, 3, 3, 1, 1'b0, 2'b00, 1'b0, '0); nid = nid + 1;
    // E2 measured case: strb 0x81 -> downstream 01 00 00 10
    do_write(nid, 32'h2000, 0, 3, 1, 1'b0, 2'b00, 1'b1, 8'h81); nid = nid + 1;
    // E3 measured case: strb 0x0F -> four beats, last two strb 00
    do_write(nid, 32'h2100, 0, 3, 1, 1'b0, 2'b00, 1'b1, 8'h0F); nid = nid + 1;
    // B2 unaligned write: len=1 size=1 @0x1004 -> downstream len 1
    do_write(nid, 32'h1004, 1, 1, 1, 1'b0, 2'b00, 1'b0, '0); nid = nid + 1;
    // size 0 stays 0 (B1)
    do_write(nid, 32'h3001, 3, 0, 1, 1'b0, 2'b00, 1'b0, '0); nid = nid + 1;
    // C3 + B4: FIXED len=0 accepted, 4-beat downstream burst must be INCR
    do_write(nid, 32'h1000, 0, 3, 0, 1'b0, 2'b00, 1'b0, '0); nid = nid + 1;
    // C2/C4: WRAP write refused
    do_write(nid, 32'h4000, 3, 1, 2, 1'b1, 2'b00, 1'b0, '0); nid = nid + 1;
    // C2/C4: FIXED len!=0 write refused
    do_write(nid, 32'h4000, 1, 1, 0, 1'b1, 2'b00, 1'b0, '0); nid = nid + 1;
    // E6: downstream B SLVERR -> upstream SLVERR
    do_write(nid, 32'h6000, 1, 3, 1, 1'b0, 2'b10, 1'b0, '0); nid = nid + 1;
    // E6: downstream B DECERR -> upstream DECERR
    do_write(nid, 32'h6100, 0, 1, 1, 1'b0, 2'b11, 1'b0, '0); nid = nid + 1;

    // ---------------- reads -----------------
    do_read(nid, 32'h1000, 1, 3, 1, 1'b0, -1, 2'b00); nid = nid + 1;
    // B2 measured: len=1 size=3 @0x1004 -> downstream len 5
    do_read(nid, 32'h1004, 1, 3, 1, 1'b0, -1, 2'b00); nid = nid + 1;
    // B2 measured: len=0 size=1 @0x1001 -> downstream len 0 (one beat)
    do_read(nid, 32'h1001, 0, 1, 1, 1'b0, -1, 2'b00); nid = nid + 1;
    // B1 measured: size 0 stays 0; lane 7 placement (D2)
    do_read(nid, 32'h000F, 0, 0, 1, 1'b0, -1, 2'b00); nid = nid + 1;
    // size 2 reduces to 1 (B1)
    do_read(nid, 32'h5000, 1, 2, 1, 1'b0, -1, 2'b00); nid = nid + 1;
    // D6 measured: error on ds beat 0 -> SLVERR SLVERR
    do_read(nid, 32'h4000, 1, 3, 1, 1'b0, 0, 2'b10); nid = nid + 1;
    // D6 measured: error on ds beat 3 -> SLVERR SLVERR
    do_read(nid, 32'h4100, 1, 3, 1, 1'b0, 3, 2'b10); nid = nid + 1;
    // D6 measured: error on LAST ds beat -> OKAY SLVERR
    do_read(nid, 32'h4200, 1, 3, 1, 1'b0, 7, 2'b10); nid = nid + 1;
    // D7 measured: DECERR preserved
    do_read(nid, 32'h4300, 1, 3, 1, 1'b0, 2, 2'b11); nid = nid + 1;
    // C1/C4: WRAP read refused -> len+1 SLVERR beats, rlast on last
    do_read(nid, 32'h7000, 3, 3, 2, 1'b1, -1, 2'b00); nid = nid + 1;
    // C2/C4: FIXED len!=0 read refused
    do_read(nid, 32'h7000, 2, 1, 0, 1'b1, -1, 2'b00); nid = nid + 1;
    // C3: FIXED len=0 read accepted and converted
    do_read(nid, 32'h7100, 0, 3, 0, 1'b0, -1, 2'b00); nid = nid + 1;

    // A4 / D3 / L3: four reads outstanding, completions in arrival order
    do_four_reads();

    // F1 / F2 / F3
    do_reset_test();

    wait_cycles(50);
    if (errors == 0) $display("RESULT: PASS");
    else             $display("RESULT: FAIL (%0d errors)", errors);
    $finish;
  end

endmodule
