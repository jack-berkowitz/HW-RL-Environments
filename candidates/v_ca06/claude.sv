// ===========================================================================
// dw_downsizer_tb.sv
//
// Self-checking testbench for the AXI4 data-width downsizer described in
// spec/dw_downsizer_spec.md.  Every check names the clause it decides.
//
// NOTE ON THE PROVIDED PLUMBING.  The clock, reset and watchdog are kept
// verbatim, as is its timing discipline (drive at the falling edge, sample at
// the rising edge).  The request/response helpers had to be adapted, because
// as shipped they name signals this port map does not have (SLV_ID_W, a single
// DATA_W -- upstream W data is 64 bits and downstream R data is 16, so one
// width cannot type both) and they hardcode resp = OKAY, which would make D6,
// D7 and E6 undecidable.  The adaptations are: correct widths, size/burst
// arguments on the address tasks, a resp argument on the response tasks, and a
// cycle budget on every wait so nothing can spin forever.
//
// STRUCTURE
//   * One posedge monitor holds all the checking.  It samples every channel at
//     the edge the design uses, in the order upstream-accept -> downstream ->
//     upstream-response, so a zero-latency implementation that issues its
//     downstream request in the same cycle it accepts the upstream one is
//     handled exactly like a deeply pipelined one (L1).
//   * Transactions are identified by bookkeeping -- a serial number recorded
//     when the address handshake is seen -- never by matching on payload.
//   * The reference model computes the address transform from the clauses
//     themselves (B1/B2/B3), and the read/write byte streams from the byte
//     addresses the transaction covers (D1/D2/E1/E2), so nothing depends on
//     how the implementation segments internally (L4/L5).
//   * Nothing the contract leaves open is checked: latency, readiness timing,
//     inter-transaction ordering, W-burst start, downstream beat pacing, and
//     the burst type of a single-beat downstream burst (L1-L6) are all free.
//   * Every wait is bounded and the run always reaches a verdict.
// ===========================================================================

module dw_downsizer_tb;

  // ---- scored configuration, pinned ---------------------------------------
  localparam int unsigned ADDR_W     = 32;
  localparam int unsigned ID_W       = 4;
  localparam int unsigned SLV_DATA_W = 64;
  localparam int unsigned MST_DATA_W = 16;
  localparam int unsigned MAX_READS  = 4;

  localparam int SBYTES = SLV_DATA_W/8;   // 8 upstream byte lanes
  localparam int MBYTES = MST_DATA_W/8;   // 2 downstream byte lanes
  localparam int NTXN   = 256;            // serial-number table
  localparam int MAXB   = 128;            // max bytes in one transaction here

  localparam logic [1:0] FIXED = 2'b00, INCR = 2'b01, WRAP = 2'b10;
  localparam logic [1:0] OKAY  = 2'b00, SLVERR = 2'b10, DECERR = 2'b11;

  // ---------------------------------------------------------------------------
  // PROVIDED PLUMBING -- clock, reset, watchdog.
  // ---------------------------------------------------------------------------
  logic clk;
  initial begin clk = 1'b0; forever #5 clk = ~clk; end

  logic rst_n;
  initial rst_n = 1'b0;

  task automatic bfm_reset(input int cycles = 4);
    @(negedge clk);
    rst_n = 1'b0;
    repeat (cycles) @(posedge clk);
    @(negedge clk);
    rst_n = 1'b1;
  endtask

  // Watchdog. Fires regardless of what the design does -- one of the faulty
  // implementations refuses a request it should accept.
  initial begin
    #4_000_000;
    $display("RESULT: FAIL (watchdog: no forward progress)");
    $finish;
  end

  // ---- device under test ---------------------------------------------------
  logic [ID_W-1:0]         s_awid;
  logic [ADDR_W-1:0]       s_awaddr;
  logic [7:0]              s_awlen;
  logic [2:0]              s_awsize;
  logic [1:0]              s_awburst;
  logic                    s_awvalid, s_awready;
  logic [SLV_DATA_W-1:0]   s_wdata;
  logic [SLV_DATA_W/8-1:0] s_wstrb;
  logic                    s_wlast, s_wvalid, s_wready;
  logic [ID_W-1:0]         s_bid;
  logic [1:0]              s_bresp;
  logic                    s_bvalid, s_bready;
  logic [ID_W-1:0]         s_arid;
  logic [ADDR_W-1:0]       s_araddr;
  logic [7:0]              s_arlen;
  logic [2:0]              s_arsize;
  logic [1:0]              s_arburst;
  logic                    s_arvalid, s_arready;
  logic [ID_W-1:0]         s_rid;
  logic [SLV_DATA_W-1:0]   s_rdata;
  logic [1:0]              s_rresp;
  logic                    s_rlast, s_rvalid, s_rready;

  logic [ID_W-1:0]         m_awid;
  logic [ADDR_W-1:0]       m_awaddr;
  logic [7:0]              m_awlen;
  logic [2:0]              m_awsize;
  logic [1:0]              m_awburst;
  logic                    m_awvalid, m_awready;
  logic [MST_DATA_W-1:0]   m_wdata;
  logic [MST_DATA_W/8-1:0] m_wstrb;
  logic                    m_wlast, m_wvalid, m_wready;
  logic [ID_W-1:0]         m_bid;
  logic [1:0]              m_bresp;
  logic                    m_bvalid, m_bready;
  logic [ID_W-1:0]         m_arid;
  logic [ADDR_W-1:0]       m_araddr;
  logic [7:0]              m_arlen;
  logic [2:0]              m_arsize;
  logic [1:0]              m_arburst;
  logic                    m_arvalid, m_arready;
  logic [ID_W-1:0]         m_rid;
  logic [MST_DATA_W-1:0]   m_rdata;
  logic [1:0]              m_rresp;
  logic                    m_rlast, m_rvalid, m_rready;

  dw_downsizer #(
    .ADDR_W(ADDR_W), .ID_W(ID_W), .SLV_DATA_W(SLV_DATA_W),
    .MST_DATA_W(MST_DATA_W), .MAX_READS(MAX_READS)
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

  // ---- verdict bookkeeping -------------------------------------------------
  int err_cnt = 0;
  int msg_cnt = 0;

  task automatic fail(input string req_id, input string msg);
    err_cnt = err_cnt + 1;
    if (msg_cnt < 50) begin
      msg_cnt = msg_cnt + 1;
      $display("FAIL [%s] t=%0t : %s", req_id, $time, msg);
    end
    if (err_cnt == 60) begin
      $display("STATS: stopping after %0d violations", err_cnt);
      $display("RESULT: FAIL");
      $finish;
    end
  endtask

  // ---- the address transform, straight from the clauses --------------------
  function automatic logic [31:0] algn(input logic [31:0] a, input int sz);
    automatic logic [31:0] m = (32'h1 << sz) - 32'h1;
    return a & ~m;
  endfunction

  function automatic int bb(input int sz);
    return 1 << sz;
  endfunction

  function automatic int calc_total(input logic [31:0] a, input int len, input int sz);
    return (len + 1) * bb(sz) - int'(a - algn(a, sz));            // total_bytes
  endfunction

  function automatic int calc_dsize(input int sz);                 // B1: min(size,1)
    return (sz < 1) ? sz : 1;
  endfunction

  function automatic int calc_dlen(input logic [31:0] a, input int len, input int sz);
    automatic int dsz = calc_dsize(sz);                            // B2: blocks spanned
    automatic logic [31:0] lst = a + calc_total(a, len, sz) - 1;
    return int'(algn(lst, dsz) - algn(a, dsz)) / bb(dsz);
  endfunction

  // ---- transaction table ---------------------------------------------------
  typedef struct {
    bit              used;
    bit              is_wr;
    logic [ID_W-1:0] id;
    logic [31:0]     addr;
    int              len;
    int              sz;
    logic [1:0]      burst;
    bit              refused;
    int              total;
    int              dsize;
    int              dbb;
    int              dlen;
    logic [31:0]     dbase;
    bit              ds_seen;    // downstream address handshake seen
    int              up_beat;    // upstream response beats consumed
    int              ds_beat;    // downstream W beats seen
    int              err_beat;   // downstream beat carrying an error, -1 = none
    logic [1:0]      err_code;
    bit              done;
  } txn_t;

  txn_t T [NTXN];
  int   n_txn = 0;

  int   rd_live [$];      // serials of reads outstanding (A4 counts these)
  int   ds_r_q  [$];      // downstream reads awaiting data from us
  int   cur_wr  = -1;     // the one write in flight
  int   ar_offer = -1;    // serial being offered on the upstream AR channel
  int   aw_offer = -1;

  // write byte map for the transaction in flight (one write at a time)
  logic [7:0] wr_byte [MAXB];
  bit         wr_strb [MAXB];

  bit b_pend   = 1'b0;
  int b_pend_s = -1;

  // ---- control flags -------------------------------------------------------
  bit hold_ds_r  = 1'b0;   // withhold downstream read data (A4 phase)
  bit stall_en   = 1'b0;   // random backpressure from our side
  bit f1_quiet   = 1'b0;   // upstream stimulus is quiet: F1 may be judged
  bit quiet_win  = 1'b0;   // nothing should be originated at all (F2/F3)
  int rst_cyc    = 0;

  // ---- deterministic payload, keyed by serial so beats of different
  //      transactions can never be confused for one another -----------------
  function automatic logic [7:0] rbyte(input int s, input logic [31:0] a);
    return 8'(a[7:0]) + 8'(s * 13) + 8'h5A;
  endfunction

  function automatic logic [7:0] wbyte(input int s, input logic [31:0] a);
    return 8'(a[7:0]) ^ 8'(s * 7) ^ 8'h3C;
  endfunction

  // first / last byte address of upstream beat i
  function automatic logic [31:0] up_lo(input int s, input int i);
    return (i == 0) ? T[s].addr : (algn(T[s].addr, T[s].sz) + i * bb(T[s].sz));
  endfunction

  function automatic logic [31:0] up_hi(input int s, input int i);
    return algn(T[s].addr, T[s].sz) + (i + 1) * bb(T[s].sz) - 1;
  endfunction

  // ===========================================================================
  // OUR READINESS.  We are the upstream master and the downstream slave; when
  // we accept is entirely our choice, so random backpressure here is legal and
  // exercises L4/L5 without requiring anything of the design.
  // ===========================================================================
  int unsigned lfsr = 32'hACE1_2345;

  function automatic int unsigned rnd();
    lfsr = lfsr ^ (lfsr << 13);
    lfsr = lfsr ^ (lfsr >> 17);
    lfsr = lfsr ^ (lfsr << 5);
    return lfsr;
  endfunction

  always @(negedge clk) begin
    automatic int unsigned r = rnd();
    m_arready = stall_en ? (r[0] | r[1]) : 1'b1;
    m_awready = stall_en ? (r[2] | r[3]) : 1'b1;
    m_wready  = stall_en ? (r[4] | r[5]) : 1'b1;
    s_rready  = stall_en ? (r[6] | r[7]) : 1'b1;
    s_bready  = stall_en ? (r[8] | r[9]) : 1'b1;
  end

  // ===========================================================================
  // THE MONITOR -- every check lives here.  Sampling at the rising edge gives
  // the values the design used during the cycle that is ending.
  // ===========================================================================
  always @(posedge clk) begin
    if (!rst_n) begin
      // Model flush: reset leaves nothing outstanding (F2/F3).
      rd_live.delete();
      ds_r_q.delete();
      cur_wr   = -1;
      b_pend   = 1'b0;
      rst_cyc  = rst_cyc + 1;
      // F1, judged only with our stimulus quiet and only after a clock edge
      // has occurred (X1): the unit originates no valid while reset is low.
      if (f1_quiet && rst_cyc >= 2) begin
        if (s_rvalid === 1'b1 || s_bvalid === 1'b1 || m_arvalid === 1'b1 ||
            m_awvalid === 1'b1 || m_wvalid === 1'b1)
          fail("F1", $sformatf("with reset low and no stimulus offered the unit drives s_rvalid=%0b s_bvalid=%0b m_arvalid=%0b m_awvalid=%0b m_wvalid=%0b",
                               s_rvalid, s_bvalid, m_arvalid, m_awvalid, m_wvalid));
      end
    end else begin
      automatic int s;
      automatic int j;
      automatic int i;
      automatic logic [31:0] blk;
      automatic logic [31:0] a;
      automatic int last_ds;
      automatic logic [1:0] exp_resp;
      automatic bit covered;
      automatic bit exp_strb;

      rst_cyc = 0;

      // ---- F2/F3: nothing may be originated in a declared quiet window ----
      if (quiet_win) begin
        if (s_rvalid === 1'b1 || s_bvalid === 1'b1)
          fail("F3", "a response appeared after reset for a transaction that was outstanding before it");
        if (m_arvalid === 1'b1 || m_awvalid === 1'b1 || m_wvalid === 1'b1)
          fail("F2", "the unit is not idle after reset release: it drives a downstream request");
      end

      // ---- A1: upstream address handshakes accept transactions ------------
      if (s_arvalid === 1'b1 && s_arready === 1'b1) begin
        if (ar_offer >= 0) begin
          rd_live.push_back(ar_offer);
          ar_offer = -1;
        end
      end
      if (s_awvalid === 1'b1 && s_awready === 1'b1) begin
        if (aw_offer >= 0) begin
          cur_wr   = aw_offer;
          aw_offer = -1;
        end
      end

      // ---- A4: the outstanding-read bound ---------------------------------
      if (rd_live.size() > MAX_READS)
        fail("A4", $sformatf("%0d reads are outstanding at once, MAX_READS is %0d", rd_live.size(), MAX_READS));

      // ---- downstream AR: A2, B1, B2, B3, B4, C4 --------------------------
      if (m_arvalid === 1'b1 && m_arready === 1'b1) begin
        s = -1;
        for (int k = 0; k < rd_live.size(); k++)
          if (T[rd_live[k]].id == m_arid && !T[rd_live[k]].ds_seen) begin
            s = rd_live[k];
            break;
          end
        if (s < 0) begin
          fail("A2", $sformatf("downstream read request (id %0d addr %08h) matches no accepted upstream read that is still awaiting one", m_arid, m_araddr));
        end else if (T[s].refused) begin
          T[s].ds_seen = 1'b1;
          fail("C4", $sformatf("a refused %s read (addr %08h len %0d) produced a downstream read request; a refusal produces no downstream transaction at all",
                               (T[s].burst == WRAP) ? "WRAP" : "FIXED", T[s].addr, T[s].len));
        end else begin
          T[s].ds_seen = 1'b1;
          if (m_araddr !== T[s].addr)
            fail("B3", $sformatf("downstream araddr %08h, upstream addr %08h; the address is not realigned", m_araddr, T[s].addr));
          if (int'(m_arsize) !== T[s].dsize)
            fail("B1", $sformatf("downstream arsize %0d, expected min(size,1) = %0d for upstream size %0d", m_arsize, T[s].dsize, T[s].sz));
          if (int'(m_arlen) !== T[s].dlen)
            fail("B2", $sformatf("downstream arlen %0d, expected %0d (blocks spanned by addr %08h len %0d size %0d, total_bytes %0d)",
                                 m_arlen, T[s].dlen, T[s].addr, T[s].len, T[s].sz, T[s].total));
          if (T[s].dlen > 0 && m_arburst !== INCR)
            fail("B4", $sformatf("downstream arburst %0b on a %0d-beat downstream burst; it must be INCR", m_arburst, T[s].dlen + 1));
          ds_r_q.push_back(s);
        end
      end

      // ---- downstream AW: A2, B1, B2, B3, B4, C4 --------------------------
      if (m_awvalid === 1'b1 && m_awready === 1'b1) begin
        if (cur_wr < 0) begin
          fail("A2", $sformatf("downstream write request (id %0d addr %08h) with no accepted upstream write in flight", m_awid, m_awaddr));
        end else if (T[cur_wr].refused) begin
          fail("C4", $sformatf("a refused %s write (addr %08h len %0d) produced a downstream write request",
                               (T[cur_wr].burst == WRAP) ? "WRAP" : "FIXED", T[cur_wr].addr, T[cur_wr].len));
          T[cur_wr].ds_seen = 1'b1;
        end else if (T[cur_wr].ds_seen) begin
          fail("A2", "a second downstream write request for one upstream write");
        end else begin
          T[cur_wr].ds_seen = 1'b1;
          if (m_awid !== T[cur_wr].id)
            fail("A2", $sformatf("downstream awid %0d, upstream awid %0d", m_awid, T[cur_wr].id));
          if (m_awaddr !== T[cur_wr].addr)
            fail("B3", $sformatf("downstream awaddr %08h, upstream addr %08h", m_awaddr, T[cur_wr].addr));
          if (int'(m_awsize) !== T[cur_wr].dsize)
            fail("B1", $sformatf("downstream awsize %0d, expected %0d for upstream size %0d", m_awsize, T[cur_wr].dsize, T[cur_wr].sz));
          if (int'(m_awlen) !== T[cur_wr].dlen)
            fail("B2", $sformatf("downstream awlen %0d, expected %0d (addr %08h len %0d size %0d)", m_awlen, T[cur_wr].dlen, T[cur_wr].addr, T[cur_wr].len, T[cur_wr].sz));
          if (T[cur_wr].dlen > 0 && m_awburst !== INCR)
            fail("B4", $sformatf("downstream awburst %0b on a %0d-beat downstream burst; it must be INCR", m_awburst, T[cur_wr].dlen + 1));
        end
      end

      // ---- downstream W: E1, E2, E3, E4, C4 -------------------------------
      if (m_wvalid === 1'b1 && m_wready === 1'b1) begin
        if (cur_wr < 0) begin
          fail("A2", "a downstream W beat with no accepted upstream write in flight");
        end else if (T[cur_wr].refused) begin
          fail("C4", "a refused write produced downstream W beats; its whole W burst must be absorbed upstream");
        end else begin
          j = T[cur_wr].ds_beat;
          if (j > T[cur_wr].dlen) begin
            fail("E3", $sformatf("downstream W burst has more than the %0d beats the transform computes", T[cur_wr].dlen + 1));
          end else begin
            if (m_wlast !== ((j == T[cur_wr].dlen) ? 1'b1 : 1'b0))
              fail("E4", $sformatf("m_wlast=%0b on downstream W beat %0d of %0d", m_wlast, j, T[cur_wr].dlen + 1));
            blk = T[cur_wr].dbase + j * T[cur_wr].dbb;
            for (int l = 0; l < MBYTES; l++) begin
              covered  = 1'b0;
              a        = '0;
              if (T[cur_wr].dbb == MBYTES) begin
                covered = 1'b1;
                a       = blk + l;
              end else if (int'(blk % MBYTES) == l) begin
                covered = 1'b1;
                a       = blk;
              end
              exp_strb = 1'b0;
              if (covered && a >= T[cur_wr].addr && a < T[cur_wr].addr + T[cur_wr].total)
                exp_strb = wr_strb[int'(a - T[cur_wr].addr)];
              if (m_wstrb[l] !== exp_strb)
                fail("E2", $sformatf("downstream W beat %0d lane %0d: strb=%0b, expected %0b (that lane %s byte %08h)",
                                     j, l, m_wstrb[l], exp_strb,
                                     covered ? "carries" : "carries no byte of the transaction,", a));
              else if (exp_strb && m_wdata[l*8 +: 8] !== wr_byte[int'(a - T[cur_wr].addr)])
                fail("E1", $sformatf("downstream W beat %0d lane %0d: data %02h, expected %02h (byte at address %08h)",
                                     j, l, m_wdata[l*8 +: 8], wr_byte[int'(a - T[cur_wr].addr)], a));
            end
          end
          T[cur_wr].ds_beat = T[cur_wr].ds_beat + 1;
          if (T[cur_wr].ds_beat == T[cur_wr].dlen + 1 && T[cur_wr].ds_seen && !b_pend) begin
            b_pend   = 1'b1;
            b_pend_s = cur_wr;
          end
        end
      end

      // ---- upstream R: A3, C4, D1..D7 -------------------------------------
      if (s_rvalid === 1'b1 && s_rready === 1'b1) begin
        s = -1;
        if (rd_live.size() == 1) begin
          s = rd_live[0];
          if (s_rid !== T[s].id)
            fail("D3", $sformatf("upstream R beat carries id %0d; the only outstanding read has id %0d", s_rid, T[s].id));
        end else begin
          for (int k = 0; k < rd_live.size(); k++)
            if (T[rd_live[k]].id == s_rid) begin s = rd_live[k]; break; end
        end
        if (s < 0) begin
          fail("A3", $sformatf("upstream R beat (id %0d) belongs to no outstanding read", s_rid));
        end else begin
          i = T[s].up_beat;
          if (i > T[s].len) begin
            fail("A3", $sformatf("read id %0d produced more than the %0d upstream R beats requested", T[s].id, T[s].len + 1));
          end else begin
            // D4
            if (s_rlast !== ((i == T[s].len) ? 1'b1 : 1'b0))
              fail("D4", $sformatf("s_rlast=%0b on upstream R beat %0d of %0d", s_rlast, i, T[s].len + 1));
            if (T[s].refused) begin
              // C4.4: SLVERR on every beat, not only the last
              if (s_rresp !== SLVERR)
                fail("C4", $sformatf("refused read: upstream R beat %0d carries resp %0b, expected SLVERR on every one of the %0d beats", i, s_rresp, T[s].len + 1));
            end else begin
              // D6/D7: sticky from the first erroring downstream beat, by group
              last_ds  = int'(up_hi(s, i) - T[s].dbase) / T[s].dbb;
              exp_resp = (T[s].err_beat >= 0 && T[s].err_beat <= last_ds) ? T[s].err_code : OKAY;
              if (s_rresp !== exp_resp)
                fail((T[s].err_beat < 0) ? "D5" : ((exp_resp == OKAY) ? "D6" : ((s_rresp == OKAY) ? "D6" : "D7")),
                     $sformatf("upstream R beat %0d carries resp %0b, expected %0b (downstream beat %0d carried %0b; this beat's group ends at downstream beat %0d)",
                               i, s_rresp, exp_resp, T[s].err_beat, T[s].err_code, last_ds));
              // D1/D2: the byte stream, in the lanes the addresses select.
              // Data is only judged where the response is OKAY.
              if (exp_resp == OKAY) begin
                for (a = up_lo(s, i); a <= up_hi(s, i); a = a + 1) begin
                  if (a >= T[s].addr && a < T[s].addr + T[s].total) begin
                    automatic int lane = int'(a % SBYTES);
                    if (s_rdata[lane*8 +: 8] !== rbyte(s, a))
                      fail("D1", $sformatf("upstream R beat %0d lane %0d: data %02h, expected %02h (byte at address %08h)",
                                           i, lane, s_rdata[lane*8 +: 8], rbyte(s, a), a));
                  end
                end
              end
            end
            T[s].up_beat = i + 1;
            if (s_rlast === 1'b1) begin
              if (T[s].up_beat != T[s].len + 1)
                fail("A3", $sformatf("read id %0d ended after %0d upstream R beats, %0d were requested", T[s].id, T[s].up_beat, T[s].len + 1));
              T[s].done = 1'b1;
              for (int k = 0; k < rd_live.size(); k++)
                if (rd_live[k] == s) begin rd_live.delete(k); break; end
            end
          end
        end
      end

      // ---- upstream B: A3, C4, E5, E6 -------------------------------------
      if (s_bvalid === 1'b1 && s_bready === 1'b1) begin
        if (cur_wr < 0) begin
          fail("A3", "an upstream B response with no accepted upstream write in flight");
        end else if (T[cur_wr].done) begin
          fail("A3", "a second upstream B response for one upstream write");
        end else begin
          if (s_bid !== T[cur_wr].id)
            fail("E5", $sformatf("upstream B carries id %0d, the write had id %0d", s_bid, T[cur_wr].id));
          if (T[cur_wr].refused) begin
            if (s_bresp !== SLVERR)
              fail("C4", $sformatf("refused write answered with resp %0b, expected SLVERR", s_bresp));
          end else begin
            if (s_bresp !== T[cur_wr].err_code)
              fail("E6", $sformatf("upstream B carries resp %0b, the downstream B carried %0b", s_bresp, T[cur_wr].err_code));
          end
          T[cur_wr].done = 1'b1;
        end
      end
    end
  end

  // ===========================================================================
  // DOWNSTREAM SLAVE -- read data.  Adapted from bfm_rbeat: correct width, a
  // resp argument, and a bounded wait.
  // ===========================================================================
  task automatic drv_rbeat(input logic [ID_W-1:0]     mid,
                           input logic [MST_DATA_W-1:0] data,
                           input logic [1:0]          resp,
                           input logic                last,
                           output bit                 ok);
    ok = 1'b0;
    @(negedge clk);
    if (!rst_n) return;
    m_rid = mid; m_rdata = data; m_rlast = last; m_rresp = resp; m_rvalid = 1'b1;
    for (int i = 0; i < 3000; i++) begin
      @(posedge clk);
      if (m_rready === 1'b1) begin ok = 1'b1; break; end
      if (!rst_n) break;
    end
    @(negedge clk) m_rvalid = 1'b0;
  endtask

  initial begin
    m_rvalid = 1'b0; m_rid = '0; m_rdata = '0; m_rresp = OKAY; m_rlast = 1'b0;
    forever begin
      @(posedge clk);
      if (!rst_n || hold_ds_r || ds_r_q.size() == 0) continue;
      begin
        automatic int s = ds_r_q.pop_front();
        for (int j = 0; j <= T[s].dlen; j++) begin
          automatic logic [MST_DATA_W-1:0] d = '0;
          automatic logic [31:0] blk = T[s].dbase + j * T[s].dbb;
          automatic bit ok;
          for (int l = 0; l < MBYTES; l++) begin
            automatic logic [31:0] a = blk + l;
            if (T[s].dbb == MBYTES)            d[l*8 +: 8] = rbyte(s, a);
            else if (int'(blk % MBYTES) == l)  d[l*8 +: 8] = rbyte(s, blk);
            else                               d[l*8 +: 8] = 8'hE7;   // no byte here
          end
          drv_rbeat(T[s].id, d,
                    (j == T[s].err_beat) ? T[s].err_code : OKAY,
                    (j == T[s].dlen) ? 1'b1 : 1'b0, ok);
          if (!ok) break;
        end
      end
    end
  end

  // ===========================================================================
  // DOWNSTREAM SLAVE -- write response.  Adapted from bfm_bbeat.
  // ===========================================================================
  task automatic drv_bbeat(input logic [ID_W-1:0] mid, input logic [1:0] resp);
    @(negedge clk);
    if (!rst_n) return;
    m_bid = mid; m_bresp = resp; m_bvalid = 1'b1;
    for (int i = 0; i < 3000; i++) begin
      @(posedge clk);
      if (m_bready === 1'b1) break;
      if (!rst_n) break;
    end
    @(negedge clk) m_bvalid = 1'b0;
  endtask

  initial begin
    m_bvalid = 1'b0; m_bid = '0; m_bresp = OKAY;
    forever begin
      @(posedge clk);
      if (!rst_n) continue;
      if (b_pend) begin
        automatic int s = b_pend_s;
        b_pend = 1'b0;
        drv_bbeat(T[s].id, T[s].err_code);
      end
    end
  end

  // ===========================================================================
  // UPSTREAM MASTER.  Adapted from bfm_ar / bfm_aw / bfm_w: size and burst
  // arguments, and every wait bounded.
  // ===========================================================================
  int budget_ar = 600;
  int budget_rs = 2500;
  int timeouts  = 0;

  function automatic int budget(input int nominal);
    return (timeouts >= 2) ? 60 : nominal;   // the fault is established; keep moving
  endfunction

  task automatic bfm_ar(input  logic [ID_W-1:0] id, input logic [31:0] addr,
                        input  logic [7:0] len, input logic [2:0] sz,
                        input  logic [1:0] burst, input int budg,
                        output bit accepted, output int waited);
    accepted = 1'b0; waited = 0;
    @(negedge clk);
    s_arid = id; s_araddr = addr; s_arlen = len; s_arsize = sz;
    s_arburst = burst; s_arvalid = 1'b1;
    while (waited < budg) begin
      @(posedge clk);
      if (s_arready === 1'b1) begin accepted = 1'b1; break; end
      waited++;
    end
    @(negedge clk) s_arvalid = 1'b0;
  endtask

  task automatic bfm_aw(input  logic [ID_W-1:0] id, input logic [31:0] addr,
                        input  logic [7:0] len, input logic [2:0] sz,
                        input  logic [1:0] burst, input int budg,
                        output bit accepted, output int waited);
    accepted = 1'b0; waited = 0;
    @(negedge clk);
    s_awid = id; s_awaddr = addr; s_awlen = len; s_awsize = sz;
    s_awburst = burst; s_awvalid = 1'b1;
    while (waited < budg) begin
      @(posedge clk);
      if (s_awready === 1'b1) begin accepted = 1'b1; break; end
      waited++;
    end
    @(negedge clk) s_awvalid = 1'b0;
  endtask

  task automatic bfm_w(input logic [SLV_DATA_W-1:0] data,
                       input logic [SBYTES-1:0]     strb,
                       input logic                  last,
                       output bit                   ok);
    ok = 1'b0;
    @(negedge clk);
    s_wdata = data; s_wstrb = strb; s_wlast = last; s_wvalid = 1'b1;
    for (int i = 0; i < budget(budget_rs); i++) begin
      @(posedge clk);
      if (s_wready === 1'b1) begin ok = 1'b1; break; end
    end
    @(negedge clk) s_wvalid = 1'b0;
  endtask

  // ---- build a transaction record -----------------------------------------
  function automatic int mk_txn(input bit is_wr, input logic [ID_W-1:0] id,
                                input logic [31:0] addr, input int len, input int sz,
                                input logic [1:0] burst, input int err_beat,
                                input logic [1:0] err_code);
    automatic int s = n_txn;
    n_txn = n_txn + 1;
    T[s].used     = 1'b1;
    T[s].is_wr    = is_wr;
    T[s].id       = id;
    T[s].addr     = addr;
    T[s].len      = len;
    T[s].sz       = sz;
    T[s].burst    = burst;
    // C1/C2/C3: WRAP always refused; FIXED refused unless it is a single beat
    T[s].refused  = (burst == WRAP) || ((burst == FIXED) && (len != 0));
    T[s].total    = calc_total(addr, len, sz);
    T[s].dsize    = calc_dsize(sz);
    T[s].dbb      = bb(calc_dsize(sz));
    T[s].dlen     = calc_dlen(addr, len, sz);
    T[s].dbase    = algn(addr, calc_dsize(sz));
    T[s].ds_seen  = 1'b0;
    T[s].up_beat  = 0;
    T[s].ds_beat  = 0;
    T[s].err_beat = err_beat;
    T[s].err_code = err_code;
    T[s].done     = 1'b0;
    return s;
  endfunction

  // ---- wait for a transaction to retire -----------------------------------
  task automatic wait_done(input int s, input string what);
    automatic int i;
    for (i = 0; i < budget(budget_rs); i++) begin
      @(posedge clk);
      if (T[s].done) break;
    end
    if (!T[s].done) begin
      timeouts = timeouts + 1;
      if (!T[s].refused && !T[s].ds_seen)
        fail("A2", $sformatf("%s id %0d addr %08h len %0d size %0d: no downstream transaction was ever issued", what, T[s].id, T[s].addr, T[s].len, T[s].sz));
      else
        fail("A3", $sformatf("%s id %0d addr %08h len %0d size %0d: no complete upstream response (%0d of %0d beats seen)",
                             what, T[s].id, T[s].addr, T[s].len, T[s].sz, T[s].up_beat, T[s].len + 1));
      T[s].done = 1'b1;
      for (int k = 0; k < rd_live.size(); k++)
        if (rd_live[k] == s) begin rd_live.delete(k); break; end
    end
  endtask

  // ---- one read ------------------------------------------------------------
  task automatic do_read(input logic [ID_W-1:0] id, input logic [31:0] addr,
                         input int len, input int sz, input logic [1:0] burst,
                         input int err_beat, input logic [1:0] err_code);
    automatic int s;
    automatic bit acc;
    automatic int wt;
    s = mk_txn(1'b0, id, addr, len, sz, burst, err_beat, err_code);
    ar_offer = s;
    bfm_ar(id, addr, 8'(len), 3'(sz), burst, budget(budget_ar), acc, wt);
    if (!acc) begin
      timeouts = timeouts + 1;
      ar_offer = -1;
      fail("A1", $sformatf("read id %0d addr %08h len %0d size %0d burst %0b was never accepted upstream, with nothing else outstanding",
                           id, addr, len, sz, burst));
      T[s].done = 1'b1;
      return;
    end
    wait_done(s, "read");
    if (T[s].refused && T[s].ds_seen == 1'b0 && T[s].done)
      ; // correct: a refusal produces no downstream transaction (C4.2)
  endtask

  // ---- one write -----------------------------------------------------------
  // strb_mode: 0 = every lane the address selects, otherwise an explicit mask
  // applied to the single beat (used for the E2 and E3 cases).
  task automatic do_write(input logic [ID_W-1:0] id, input logic [31:0] addr,
                          input int len, input int sz, input logic [1:0] burst,
                          input logic [1:0] bresp, input bit use_mask,
                          input logic [SBYTES-1:0] mask);
    automatic int s;
    automatic bit acc, ok;
    automatic int wt;
    s = mk_txn(1'b1, id, addr, len, sz, burst, -1, bresp);
    // byte map for the whole transaction
    for (int k = 0; k < MAXB; k++) begin
      wr_byte[k] = 8'h00;
      wr_strb[k] = 1'b0;
    end
    for (int b = 0; b < T[s].total; b++) begin
      automatic logic [31:0] a = addr + b;
      wr_byte[b] = wbyte(s, a);
      wr_strb[b] = use_mask ? mask[int'(a % SBYTES)] : 1'b1;
    end
    aw_offer = s;
    bfm_aw(id, addr, 8'(len), 3'(sz), burst, budget(budget_ar), acc, wt);
    if (!acc) begin
      timeouts = timeouts + 1;
      aw_offer = -1;
      fail("A1", $sformatf("write id %0d addr %08h len %0d size %0d burst %0b was never accepted upstream",
                           id, addr, len, sz, burst));
      T[s].done = 1'b1;
      return;
    end
    // ---- the W burst.  Strobes are always confined to the lanes the beat's
    //      address selects (X3), so the burst is conforming AXI.
    for (int i = 0; i <= len; i++) begin
      automatic logic [SLV_DATA_W-1:0] d = '0;
      automatic logic [SBYTES-1:0]     st = '0;
      automatic logic [31:0] lo = up_lo(s, i);
      automatic logic [31:0] hi = up_hi(s, i);
      automatic int aa;
      automatic logic [31:0] a;
      for (aa = int'(lo); aa <= int'(hi); aa++) begin
        automatic int lane;
        a    = 32'(aa);
        lane = int'(a % SBYTES);
        if (a >= addr && a < addr + T[s].total) begin
          d[lane*8 +: 8] = wr_byte[int'(a - addr)];
          st[lane]       = wr_strb[int'(a - addr)];
        end
      end
      bfm_w(d, st, (i == len) ? 1'b1 : 1'b0, ok);
      if (!ok) begin
        timeouts = timeouts + 1;
        fail(T[s].refused ? "C4" : "E1",
             $sformatf("write id %0d: upstream W beat %0d was never accepted%s", id, i,
                       T[s].refused ? "; a refused write must still absorb its whole W burst" : ""));
        break;
      end
    end
    wait_done(s, "write");
    if (!T[s].refused && T[s].ds_beat != T[s].dlen + 1)
      fail("E3", $sformatf("write id %0d: downstream W burst had %0d beats, the transform computes %0d (an unstrobed beat is still a beat)",
                           id, T[s].ds_beat, T[s].dlen + 1));
    if (!T[s].refused && !T[s].ds_seen)
      fail("A2", $sformatf("write id %0d produced no downstream write request", id));
    cur_wr = -1;
  endtask

  // ===========================================================================
  // THE RUN
  // ===========================================================================
  int q_i;

  initial begin
    s_awid='0; s_awaddr='0; s_awlen='0; s_awsize='0; s_awburst=INCR; s_awvalid=1'b0;
    s_wdata='0; s_wstrb='0; s_wlast=1'b0; s_wvalid=1'b0;
    s_arid='0; s_araddr='0; s_arlen='0; s_arsize='0; s_arburst=INCR; s_arvalid=1'b0;
    for (int k = 0; k < MAXB; k++) begin wr_byte[k]='0; wr_strb[k]=1'b0; end

    // ---- F1: reset with everything quiet ---------------------------------
    f1_quiet = 1'b1;
    bfm_reset(6);
    f1_quiet = 1'b0;
    // ---- F2: idle after release ------------------------------------------
    quiet_win = 1'b1;
    repeat (20) @(posedge clk);
    @(negedge clk);
    quiet_win = 1'b0;

    // ---- reads: the address transform and the byte stream ----------------
    do_read(4'h1, 32'h0000_1000, 0, 3, INCR, -1, OKAY);   // dlen 3
    do_read(4'h2, 32'h0000_1000, 1, 3, INCR, -1, OKAY);   // dlen 7
    do_read(4'h3, 32'h0000_1004, 1, 3, INCR, -1, OKAY);   // dlen 5, unaligned
    do_read(4'h4, 32'h0000_1001, 0, 1, INCR, -1, OKAY);   // dlen 0, one byte
    do_read(4'h5, 32'h0000_1002, 3, 1, INCR, -1, OKAY);   // crosses a wide lane group
    do_read(4'h6, 32'h0000_1003, 3, 0, INCR, -1, OKAY);   // size 0 stays 0 (B1)
    do_read(4'h7, 32'h0000_1000, 1, 2, INCR, -1, OKAY);
    do_read(4'h8, 32'h0000_1007, 0, 3, INCR, -1, OKAY);   // one byte, top lane
    do_read(4'h9, 32'h0000_1006, 1, 1, INCR, -1, OKAY);
    do_read(4'hA, 32'h0000_2000, 7, 3, INCR, -1, OKAY);   // 8 upstream beats

    stall_en = 1'b1;                                       // random backpressure
    do_read(4'h1, 32'h0000_3001, 2, 3, INCR, -1, OKAY);
    do_read(4'h2, 32'h0000_3005, 3, 1, INCR, -1, OKAY);
    do_read(4'h3, 32'h0000_300F, 0, 0, INCR, -1, OKAY);
    stall_en = 1'b0;

    // ---- C1/C2/C3: what is refused, and what is not ----------------------
    do_read(4'hB, 32'h0000_1000, 0, 3, FIXED, -1, OKAY);   // C3: served, B4 says INCR
    do_read(4'hC, 32'h0000_1000, 1, 3, FIXED, -1, OKAY);   // C2: refused
    do_read(4'hD, 32'h0000_1000, 3, 3, WRAP,  -1, OKAY);   // C1: refused
    do_read(4'hE, 32'h0000_1008, 0, 1, FIXED, -1, OKAY);   // C3 again, dlen 0

    // ---- D5/D6/D7: error precedence, stickiness, and the code ------------
    do_read(4'h1, 32'h0000_1000, 1, 3, INCR, 0, SLVERR);   // SLVERR SLVERR
    do_read(4'h2, 32'h0000_1000, 1, 3, INCR, 3, SLVERR);   // SLVERR SLVERR
    do_read(4'h3, 32'h0000_1000, 1, 3, INCR, 7, SLVERR);   // OKAY   SLVERR
    do_read(4'h4, 32'h0000_1000, 1, 3, INCR, 5, DECERR);   // OKAY   DECERR
    do_read(4'h5, 32'h0000_1000, 3, 3, INCR, 9, SLVERR);   // OKAY OKAY SLVERR SLVERR
    do_read(4'h6, 32'h0000_1004, 1, 3, INCR, 2, DECERR);

    // ---- writes -----------------------------------------------------------
    do_write(4'h1, 32'h0000_1000, 0, 3, INCR, OKAY, 1'b0, '0);
    do_write(4'h2, 32'h0000_1000, 1, 3, INCR, OKAY, 1'b0, '0);
    do_write(4'h3, 32'h0000_1004, 1, 3, INCR, OKAY, 1'b0, '0);
    do_write(4'h4, 32'h0000_1001, 0, 1, INCR, OKAY, 1'b0, '0);
    do_write(4'h5, 32'h0000_1002, 3, 1, INCR, OKAY, 1'b0, '0);
    do_write(4'h6, 32'h0000_1003, 3, 0, INCR, OKAY, 1'b0, '0);
    do_write(4'h7, 32'h0000_1007, 0, 3, INCR, OKAY, 1'b0, '0);
    do_write(4'h8, 32'h0000_2000, 7, 3, INCR, OKAY, 1'b0, '0);
    stall_en = 1'b1;
    do_write(4'h9, 32'h0000_3001, 2, 3, INCR, OKAY, 1'b0, '0);
    stall_en = 1'b0;

    // ---- E2/E3: strobes split per byte lane, unstrobed beats still emitted
    do_write(4'hA, 32'h0000_1000, 0, 3, INCR, OKAY, 1'b1, 8'h81);  // -> 01 00 00 10
    do_write(4'hB, 32'h0000_1000, 0, 3, INCR, OKAY, 1'b1, 8'h0F);  // -> 11 11 00 00
    do_write(4'hC, 32'h0000_1000, 0, 3, INCR, OKAY, 1'b1, 8'h00);  // every beat strb 0
    do_write(4'hD, 32'h0000_1000, 1, 3, INCR, OKAY, 1'b1, 8'h42);

    // ---- E6: the write response code is preserved ------------------------
    do_write(4'h1, 32'h0000_1000, 0, 3, INCR, SLVERR, 1'b0, '0);
    do_write(4'h2, 32'h0000_1000, 1, 3, INCR, DECERR, 1'b0, '0);

    // ---- C1/C2/C3 on the write side --------------------------------------
    do_write(4'hE, 32'h0000_1000, 0, 3, FIXED, OKAY, 1'b0, '0);   // served
    do_write(4'hF, 32'h0000_1000, 1, 3, FIXED, OKAY, 1'b0, '0);   // refused
    do_write(4'h0, 32'h0000_1000, 3, 3, WRAP,  OKAY, 1'b0, '0);   // refused

    // ---- A4: the outstanding-read bound ----------------------------------
    hold_ds_r = 1'b1;
    begin
      automatic bit acc;
      automatic int wt;
      automatic int accepted_n = 0;
      automatic int sv [$];
      for (int k = 0; k < MAX_READS + 2; k++) begin
        automatic int s = mk_txn(1'b0, 4'(k + 1), 32'h0000_4000 + k*32'h40, 1, 3, INCR, -1, OKAY);
        ar_offer = s;
        bfm_ar(4'(k + 1), 32'h0000_4000 + k*32'h40, 8'd1, 3'd3, INCR, 40, acc, wt);
        if (acc) begin accepted_n++; sv.push_back(s); end
        else begin ar_offer = -1; T[s].done = 1'b1; end
      end
      // Not accepting beyond the bound is correct (A4, L2); exceeding it is not,
      // and the monitor reports that.  Now let them all retire.
      hold_ds_r = 1'b0;
      for (q_i = 0; q_i < sv.size(); q_i++) wait_done(sv[q_i], "read");
      // F2/A4: the bound is a bound on blocking, so reads flow again after they retire
      begin
        automatic int s2 = mk_txn(1'b0, 4'h7, 32'h0000_5000, 0, 3, INCR, -1, OKAY);
        ar_offer = s2;
        bfm_ar(4'h7, 32'h0000_5000, 8'd0, 3'd3, INCR, budget(budget_ar), acc, wt);
        if (!acc) begin
          timeouts = timeouts + 1;
          ar_offer = -1;
          fail("A4", "a read was not accepted even after every outstanding read had retired");
          T[s2].done = 1'b1;
        end else wait_done(s2, "read");
      end
    end

    // ---- F3: a transaction outstanding across reset produces no response --
    begin
      automatic bit acc;
      automatic int wt;
      automatic int s3;
      hold_ds_r = 1'b1;
      s3 = mk_txn(1'b0, 4'h9, 32'h0000_6000, 3, 3, INCR, -1, OKAY);
      ar_offer = s3;
      bfm_ar(4'h9, 32'h0000_6000, 8'd3, 3'd3, INCR, budget(budget_ar), acc, wt);
      ar_offer = -1;
      repeat (10) @(posedge clk);
      @(negedge clk);
      f1_quiet = 1'b1;
      bfm_reset(6);                 // asynchronous, mid-transaction
      f1_quiet = 1'b0;
      ds_r_q.delete();              // that downstream request no longer exists
      hold_ds_r = 1'b0;
      quiet_win = 1'b1;
      repeat (40) @(posedge clk);   // nothing may appear for the abandoned read
      @(negedge clk);
      quiet_win = 1'b0;
      T[s3].done = 1'b1;
    end

    // ---- F2: the unit works again afterwards ------------------------------
    do_read(4'h1, 32'h0000_7000, 1, 3, INCR, -1, OKAY);
    do_write(4'h2, 32'h0000_7000, 1, 3, INCR, OKAY, 1'b0, '0);
    do_read(4'h3, 32'h0000_7010, 0, 1, INCR, 0, SLVERR);

    // ---- verdict ----------------------------------------------------------
    $display("STATS: %0d transactions driven, %0d violations", n_txn, err_cnt);
    if (n_txn == 0) fail("A1", "no transaction was ever driven");
    if (err_cnt == 0) $display("RESULT: PASS");
    else              $display("RESULT: FAIL");
    $finish;
  end

endmodule