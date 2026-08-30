// ===========================================================================
// dw_downsizer_tb.sv -- decides whether a dw_downsizer obeys the contract.
//
// NOTE ON THE TASK TEXT: the trailing "What to produce" section, and the
// provided plumbing, are leftovers from a different task (id_width_conv). The
// plumbing names SLV_ID_W / MST_ID_W / DATA_W, none of which exist on this port
// map, and its bfm_ar omits the size and burst fields this contract explicitly
// turns on. The timing discipline from that plumbing is kept exactly -- drive
// after @(negedge clk), sample handshakes at @(posedge clk) -- and the drivers
// are rebuilt against the real signal names.
//
// WHAT IS DELIBERATELY NOT CHECKED, because the contract frees it and a check
// would reject a correct implementation:
//   L1  latency, anywhere -- every wait is a bounded retry, never a required
//       cycle count;
//   L2  when any ready rises. A refusal is only ever reported after a long
//       budget, and never merely because the unit looked idle;
//   L3  ordering between transactions. The bulk of the run is ONE transaction
//       at a time so no inter-transaction order is ever assumed; the one
//       multi-outstanding phase uses distinct ids and single-beat bursts, so
//       matching is by id and interleaving cannot matter;
//   L4  when the downstream W burst starts relative to the upstream one;
//   L5  gaps between downstream beats, and how many are in flight;
//   L6  the burst type of a SINGLE-BEAT downstream burst -- B4 is checked ONLY
//       where the downstream burst has more than one beat;
//   X2  any output while its valid is low;
//   X1  any output while rst_ni is low, before the first rising edge.
// Read data on lanes the transaction does not cover is also never examined,
// nor write data on unstrobed lanes, nor the read payload of a refused
// transaction -- the contract says nothing about any of them.
//
// Per the contract's own grouping, the C4 check carries C1 and C2.
// ===========================================================================

`timescale 1ns/1ps

module dw_downsizer_tb;

  // ---- pinned scored configuration ----------------------------------------
  localparam int unsigned ADDR_W     = 32;
  localparam int unsigned ID_W       = 4;
  localparam int unsigned SLV_DATA_W = 64;
  localparam int unsigned MST_DATA_W = 16;
  localparam int unsigned MAX_READS  = 4;
  localparam int SBYTES = SLV_DATA_W/8;   // 8
  localparam int MBYTES = MST_DATA_W/8;   // 2

  localparam logic [1:0] FIXED = 2'b00;
  localparam logic [1:0] INCR  = 2'b01;
  localparam logic [1:0] WRAP  = 2'b10;
  localparam logic [1:0] OKAY   = 2'b00;
  localparam logic [1:0] SLVERR = 2'b10;
  localparam logic [1:0] DECERR = 2'b11;

  // =========================================================================
  // clock, reset, watchdog  (timing discipline from the provided plumbing)
  // =========================================================================
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

  initial begin
    #4_000_000;
    $display("RESULT: FAIL (watchdog: no forward progress)");
    $finish;
  end

  // =========================================================================
  // DUT
  // =========================================================================
  logic [ID_W-1:0]         s_awid;
  logic [ADDR_W-1:0]       s_awaddr;
  logic [7:0]              s_awlen;
  logic [2:0]              s_awsize;
  logic [1:0]              s_awburst;
  logic                    s_awvalid, s_awready;
  logic [SLV_DATA_W-1:0]   s_wdata;
  logic [SBYTES-1:0]       s_wstrb;
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
  logic [MBYTES-1:0]       m_wstrb;
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

  // =========================================================================
  // failure reporting
  // =========================================================================
  int nerr;
  int nprint;

  task automatic fail(input string cl, input string msg);
    nerr = nerr + 1;
    if (nprint < 40) begin
      nprint = nprint + 1;
      $display("FAIL [%0s] t=%0t : %0s", cl, $time, msg);
    end
  endtask

  // =========================================================================
  // the address transform, exactly as sections 2 and 3 state it
  // =========================================================================
  function automatic int unsigned bbytes(input int sz);
    return (1 << sz);
  endfunction

  function automatic logic [ADDR_W-1:0] algn(input logic [ADDR_W-1:0] a, input int sz);
    return a & ~((32'(1) << sz) - 32'(1));
  endfunction

  function automatic int dn_size(input int sz);
    return (sz < 1) ? sz : 1;
  endfunction

  function automatic int unsigned total_bytes(input logic [ADDR_W-1:0] a,
                                              input int ln, input int sz);
    return (ln + 1) * bbytes(sz) - (a - algn(a, sz));
  endfunction

  // B2: a count of BLOCKS SPANNED, not a division of the byte count.
  function automatic int exp_dlen(input logic [ADDR_W-1:0] a, input int ln, input int sz);
    int d;
    logic [ADDR_W-1:0] lastb;
    d     = dn_size(sz);
    lastb = a + total_bytes(a, ln, sz) - 1;
    return int'((algn(lastb, d) - algn(a, d)) >> d);
  endfunction

  // C1 and C2, decided together; observed through C4.
  function automatic bit is_refused(input logic [1:0] brst, input int ln);
    return (brst == WRAP) || ((brst == FIXED) && (ln != 0));
  endfunction

  // Deterministic byte content: adjacent addresses always differ, so a
  // one-lane or one-beat shift cannot alias into a pass.
  function automatic logic [7:0] rd_byte(input int a);
    return 8'((a * 131) + 17);
  endfunction

  function automatic logic [7:0] wr_byte(input int a);
    return 8'((a * 197) + 83);
  endfunction

  function automatic logic [7:0] pat_mask(input int kind);
    case (kind)
      0:       return 8'hFF;
      1:       return 8'h81;
      2:       return 8'h0F;
      3:       return 8'hAA;
      default: return 8'h00;
    endcase
  endfunction

  // First and last byte address of upstream beat i (only beat 0 can be partial).
  function automatic int ubeat_lo(input logic [ADDR_W-1:0] a, input int sz, input int i);
    return (i == 0) ? int'(a) : int'(algn(a, sz)) + i * int'(bbytes(sz));
  endfunction

  function automatic int ubeat_hi(input logic [ADDR_W-1:0] a, input int sz, input int i);
    return int'(algn(a, sz)) + (i + 1) * int'(bbytes(sz)) - 1;
  endfunction

  // =========================================================================
  // Monitors.  Only this block writes the model queues and counters; the test
  // tasks read them by index, so no queue is ever written from two processes.
  // =========================================================================
  logic [ID_W-1:0]       dar_id   [$];
  logic [ADDR_W-1:0]     dar_addr [$];
  logic [7:0]            dar_len  [$];
  logic [2:0]            dar_size [$];
  logic [1:0]            dar_bst  [$];
  int                    n_dar;

  logic [ID_W-1:0]       daw_id   [$];
  logic [ADDR_W-1:0]     daw_addr [$];
  logic [7:0]            daw_len  [$];
  logic [2:0]            daw_size [$];
  logic [1:0]            daw_bst  [$];
  int                    n_daw;

  logic [MST_DATA_W-1:0] dw_data [$];
  logic [MBYTES-1:0]     dw_strb [$];
  bit                    dw_last [$];
  int                    n_dw;

  logic [ID_W-1:0]       ur_id   [$];
  logic [SLV_DATA_W-1:0] ur_data [$];
  logic [1:0]            ur_resp [$];
  bit                    ur_last [$];
  int                    n_ur;

  logic [ID_W-1:0]       ub_id   [$];
  logic [1:0]            ub_resp [$];
  int                    n_ub;

  int edge_cnt;

  // upstream W burst record, read back when checking the downstream burst
  logic [SLV_DATA_W-1:0] uw_data [16];
  logic [SBYTES-1:0]     uw_strb [16];

  always @(posedge clk) begin
    edge_cnt <= edge_cnt + 1;
    if (!rst_n) begin
      // F1: while reset is low the unit presents no valid on any channel it
      // drives.  X1: not before the first rising edge.
      if (edge_cnt > 0) begin
        if (m_awvalid) fail("F1", "m_awvalid high while rst_ni low");
        if (m_wvalid ) fail("F1", "m_wvalid high while rst_ni low");
        if (m_arvalid) fail("F1", "m_arvalid high while rst_ni low");
        if (s_bvalid ) fail("F1", "s_bvalid high while rst_ni low");
        if (s_rvalid ) fail("F1", "s_rvalid high while rst_ni low");
      end
    end
    else begin
      if (m_arvalid && m_arready) begin
        dar_id.push_back(m_arid);     dar_addr.push_back(m_araddr);
        dar_len.push_back(m_arlen);   dar_size.push_back(m_arsize);
        dar_bst.push_back(m_arburst); n_dar = n_dar + 1;
      end
      if (m_awvalid && m_awready) begin
        daw_id.push_back(m_awid);     daw_addr.push_back(m_awaddr);
        daw_len.push_back(m_awlen);   daw_size.push_back(m_awsize);
        daw_bst.push_back(m_awburst); n_daw = n_daw + 1;
      end
      if (m_wvalid && m_wready) begin
        dw_data.push_back(m_wdata); dw_strb.push_back(m_wstrb);
        dw_last.push_back(m_wlast); n_dw = n_dw + 1;
      end
      if (s_rvalid && s_rready) begin
        ur_id.push_back(s_rid);     ur_data.push_back(s_rdata);
        ur_resp.push_back(s_rresp); ur_last.push_back(s_rlast);
        n_ur = n_ur + 1;
      end
      if (s_bvalid && s_bready) begin
        ub_id.push_back(s_bid); ub_resp.push_back(s_bresp); n_ub = n_ub + 1;
      end
    end
  end

  // =========================================================================
  // Drivers.  Every wait is bounded: nothing here can hang.
  // =========================================================================
  task automatic drv_ar(input int id, input logic [ADDR_W-1:0] addr, input int ln,
                        input int sz, input logic [1:0] brst, input int budget,
                        output bit accepted);
    int waited;
    accepted = 1'b0;
    waited   = 0;
    @(negedge clk);
    s_arid = id[ID_W-1:0]; s_araddr = addr; s_arlen = ln[7:0];
    s_arsize = sz[2:0]; s_arburst = brst; s_arvalid = 1'b1;
    while (waited < budget) begin
      @(posedge clk);
      if (s_arready) begin accepted = 1'b1; break; end
      waited = waited + 1;
    end
    @(negedge clk) s_arvalid = 1'b0;
  endtask

  task automatic drv_aw(input int id, input logic [ADDR_W-1:0] addr, input int ln,
                        input int sz, input logic [1:0] brst, input int budget,
                        output bit accepted);
    int waited;
    accepted = 1'b0;
    waited   = 0;
    @(negedge clk);
    s_awid = id[ID_W-1:0]; s_awaddr = addr; s_awlen = ln[7:0];
    s_awsize = sz[2:0]; s_awburst = brst; s_awvalid = 1'b1;
    while (waited < budget) begin
      @(posedge clk);
      if (s_awready) begin accepted = 1'b1; break; end
      waited = waited + 1;
    end
    @(negedge clk) s_awvalid = 1'b0;
  endtask

  task automatic drv_w(input logic [SLV_DATA_W-1:0] data, input logic [SBYTES-1:0] strb,
                       input bit is_last, input int budget, output bit accepted);
    int waited;
    accepted = 1'b0;
    waited   = 0;
    @(negedge clk);
    s_wdata = data; s_wstrb = strb; s_wlast = is_last; s_wvalid = 1'b1;
    while (waited < budget) begin
      @(posedge clk);
      if (s_wready) begin accepted = 1'b1; break; end
      waited = waited + 1;
    end
    @(negedge clk) s_wvalid = 1'b0;
  endtask

  task automatic drv_rbeat(input int id, input logic [MST_DATA_W-1:0] data,
                           input logic [1:0] resp, input bit is_last);
    int waited;
    waited = 0;
    @(negedge clk);
    m_rid = id[ID_W-1:0]; m_rdata = data; m_rresp = resp;
    m_rlast = is_last; m_rvalid = 1'b1;
    while (waited < 300) begin
      @(posedge clk);
      if (m_rready) break;
      waited = waited + 1;
    end
    if (waited >= 300)
      fail("A3", "design never accepted a downstream read data beat");
    @(negedge clk) m_rvalid = 1'b0;
  endtask

  task automatic drv_bbeat(input int id, input logic [1:0] resp);
    int waited;
    waited = 0;
    @(negedge clk);
    m_bid = id[ID_W-1:0]; m_bresp = resp; m_bvalid = 1'b1;
    while (waited < 300) begin
      @(posedge clk);
      if (m_bready) break;
      waited = waited + 1;
    end
    if (waited >= 300)
      fail("E5", "design never accepted the downstream write response");
    @(negedge clk) m_bvalid = 1'b0;
  endtask

  task automatic idle_cycles(input int n);
    repeat (n) @(posedge clk);
  endtask

  // =========================================================================
  // READ transaction
  // =========================================================================
  task automatic do_read(input int id, input logic [ADDR_W-1:0] addr, input int ln,
                         input int sz, input logic [1:0] brst,
                         input int err_beat, input logic [1:0] err_code,
                         input string nm);
    bit  accepted;
    bit  refused;
    int  d, dlen, j, k, i, waited, nb, lastd, lo, hi, aa;
    int  s_dar, s_daw, s_dw, s_ur;
    logic [MST_DATA_W-1:0] bd;
    logic [1:0] want_resp;
    bit  seen_last;

    refused   = is_refused(brst, ln);
    d         = dn_size(sz);
    dlen      = exp_dlen(addr, ln, sz);
    s_dar     = n_dar; s_daw = n_daw; s_dw = n_dw; s_ur = n_ur;
    seen_last = 1'b0;

    drv_ar(id, addr, ln, sz, brst, 300, accepted);
    // C4.1: a refused transaction is STILL accepted on its address channel.
    if (!accepted) begin
      fail(refused ? "C4" : "A1",
           $sformatf("%0s: s_arready never rose in 300 cycles", nm));
      return;
    end

    if (!refused) begin
      waited = 0;
      while (((n_dar - s_dar) < 1) && (waited < 300)) begin
        @(posedge clk);
        waited = waited + 1;
      end
      if ((n_dar - s_dar) < 1) begin
        fail("A2", $sformatf("%0s: no downstream read request appeared", nm));
      end
      else begin
        if (dar_id[s_dar] !== id[ID_W-1:0])
          fail("A2", $sformatf("%0s: downstream arid=%0d, upstream id=%0d",
                               nm, dar_id[s_dar], id));
        if (dar_addr[s_dar] !== addr)
          fail("B3", $sformatf("%0s: downstream araddr=%08h, upstream addr=%08h",
                               nm, dar_addr[s_dar], addr));
        if (int'(dar_size[s_dar]) != d)
          fail("B1", $sformatf("%0s: downstream arsize=%0d, expected min(size,1)=%0d",
                               nm, dar_size[s_dar], d));
        if (int'(dar_len[s_dar]) != dlen)
          fail("B2", $sformatf("%0s: downstream arlen=%0d, expected %0d blocks spanned",
                               nm, dar_len[s_dar], dlen));
        // B4 binds ONLY where the downstream burst has more than one beat (L6).
        if ((dlen > 0) && (dar_bst[s_dar] !== INCR))
          fail("B4", $sformatf("%0s: downstream arburst=%02b on a %0d-beat burst, expected INCR",
                               nm, dar_bst[s_dar], dlen+1));

        for (j = 0; j <= dlen; j++) begin
          bd = '0;
          for (k = 0; k < int'(bbytes(d)); k++) begin
            aa = int'(algn(addr, d)) + j * int'(bbytes(d)) + k;
            bd[8*(aa % MBYTES) +: 8] = rd_byte(aa);
          end
          drv_rbeat(id, bd, (j == err_beat) ? err_code : OKAY, (j == dlen));
        end
      end
    end

    // ---- upstream R burst ------------------------------------------------
    nb     = 0;
    waited = 0;
    while ((waited < 1000) && (nb < (ln + 3)) && !seen_last) begin
      if ((n_ur - s_ur) > nb) begin
        i = s_ur + nb;
        if (ur_id[i] !== id[ID_W-1:0])
          fail("D3", $sformatf("%0s: upstream R beat %0d carries id %0d, expected %0d",
                               nm, nb, ur_id[i], id));
        if (ur_last[i] !== ((nb == ln) ? 1'b1 : 1'b0))
          fail(refused ? "C4" : "D4",
               $sformatf("%0s: upstream R beat %0d of %0d has rlast=%0b",
                         nm, nb, ln+1, ur_last[i]));
        if (refused) begin
          // C4.4: SLVERR on EVERY beat, not only the last.
          if (ur_resp[i] !== SLVERR)
            fail("C4", $sformatf("%0s: refused read beat %0d carries resp %02b, expected SLVERR",
                                 nm, nb, ur_resp[i]));
        end
        else begin
          // D6: sticky -- error in this beat's own downstream group or any
          // earlier one.  D7: the code is preserved, not normalised.
          hi        = ubeat_hi(addr, sz, nb);
          lastd     = int'((algn(hi, d) - algn(addr, d)) >> d);
          want_resp = ((err_beat >= 0) && (err_beat <= lastd)) ? err_code : OKAY;
          if (ur_resp[i] !== want_resp)
            fail((err_beat < 0) ? "D5" : "D6",
                 $sformatf("%0s: upstream R beat %0d resp=%02b, expected %02b (downstream error on beat %0d, group ends at %0d)",
                           nm, nb, ur_resp[i], want_resp, err_beat, lastd));
          // D1/D2: only the bytes the transaction covers, in the lanes the
          // address selects.  Lanes outside the transfer are not examined.
          lo = ubeat_lo(addr, sz, nb);
          hi = ubeat_hi(addr, sz, nb);
          for (aa = lo; aa <= hi; aa++) begin
            if (ur_data[i][8*(aa % SBYTES) +: 8] !== rd_byte(aa))
              fail("D1", $sformatf("%0s: beat %0d lane %0d (byte addr %08h) = %02h, expected %02h",
                                   nm, nb, aa % SBYTES, aa,
                                   ur_data[i][8*(aa % SBYTES) +: 8], rd_byte(aa)));
          end
        end
        if (ur_last[i]) seen_last = 1'b1;
        nb = nb + 1;
      end
      else begin
        @(posedge clk);
        waited = waited + 1;
      end
    end

    // A3 / C4.5: exactly len+1 beats, rlast on the last, and no more.
    if (nb != (ln + 1))
      fail("A3", $sformatf("%0s: upstream read produced %0d R beats, expected %0d",
                           nm, nb, ln + 1));
    idle_cycles(15);
    if ((n_ur - s_ur) != (ln + 1))
      fail("A3", $sformatf("%0s: upstream read produced %0d R beats after settling, expected %0d",
                           nm, n_ur - s_ur, ln + 1));

    if (refused) begin
      // C4.2: a monitor watching only the downstream port sees NOTHING.
      if ((n_dar - s_dar) != 0)
        fail("C4", $sformatf("%0s: refused read produced %0d downstream read request(s)",
                             nm, n_dar - s_dar));
      if (((n_daw - s_daw) != 0) || ((n_dw - s_dw) != 0))
        fail("C4", $sformatf("%0s: refused read produced downstream write activity", nm));
    end
    else begin
      // A2: exactly one downstream transaction.
      if ((n_dar - s_dar) != 1)
        fail("A2", $sformatf("%0s: produced %0d downstream read requests, expected exactly 1",
                             nm, n_dar - s_dar));
    end
  endtask

  // =========================================================================
  // WRITE transaction
  // =========================================================================
  task automatic do_write(input int id, input logic [ADDR_W-1:0] addr, input int ln,
                          input int sz, input logic [1:0] brst, input int strb_kind,
                          input logic [1:0] bresp_code, input string nm);
    bit  accepted;
    bit  refused;
    int  d, dlen, i, j, k, aa, lo, hi, waited, ub, lane_d;
    int  s_dar, s_daw, s_dw, s_ub;
    int  lastbyte;
    logic [SBYTES-1:0] allow, use_strb;
    logic [SLV_DATA_W-1:0] wd;
    logic [MBYTES-1:0] want_strb;
    logic [7:0] got_byte, want_byte;
    logic [1:0] want_resp;

    refused  = is_refused(brst, ln);
    d        = dn_size(sz);
    dlen     = exp_dlen(addr, ln, sz);
    lastbyte = int'(addr) + int'(total_bytes(addr, ln, sz)) - 1;
    s_dar    = n_dar; s_daw = n_daw; s_dw = n_dw; s_ub = n_ub;

    drv_aw(id, addr, ln, sz, brst, 300, accepted);
    if (!accepted) begin
      fail(refused ? "C4" : "A1",
           $sformatf("%0s: s_awready never rose in 300 cycles", nm));
      return;
    end

    // Build and drive the upstream W burst.  X3: strobes are masked to the byte
    // lanes the address actually selects, so the burst is conforming AXI.
    for (i = 0; i <= ln; i++) begin
      lo    = ubeat_lo(addr, sz, i);
      hi    = ubeat_hi(addr, sz, i);
      allow = '0;
      wd    = '0;
      for (aa = lo; aa <= hi; aa++) begin
        allow[aa % SBYTES]        = 1'b1;
        wd[8*(aa % SBYTES) +: 8]  = wr_byte(aa);
      end
      use_strb     = allow & pat_mask(strb_kind);
      uw_strb[i]   = use_strb;
      uw_data[i]   = wd;
      drv_w(wd, use_strb, (i == ln), 300, accepted);
      // C4.3: for a refused write every upstream beat is still absorbed.
      if (!accepted)
        fail(refused ? "C4" : "A1",
             $sformatf("%0s: upstream W beat %0d never accepted", nm, i));
    end

    if (!refused) begin
      waited = 0;
      while (((n_daw - s_daw) < 1) && (waited < 300)) begin
        @(posedge clk);
        waited = waited + 1;
      end
      if ((n_daw - s_daw) < 1) begin
        fail("A2", $sformatf("%0s: no downstream write request appeared", nm));
      end
      else begin
        if (daw_id[s_daw] !== id[ID_W-1:0])
          fail("A2", $sformatf("%0s: downstream awid=%0d, upstream id=%0d",
                               nm, daw_id[s_daw], id));
        if (daw_addr[s_daw] !== addr)
          fail("B3", $sformatf("%0s: downstream awaddr=%08h, upstream addr=%08h",
                               nm, daw_addr[s_daw], addr));
        if (int'(daw_size[s_daw]) != d)
          fail("B1", $sformatf("%0s: downstream awsize=%0d, expected min(size,1)=%0d",
                               nm, daw_size[s_daw], d));
        if (int'(daw_len[s_daw]) != dlen)
          fail("B2", $sformatf("%0s: downstream awlen=%0d, expected %0d blocks spanned",
                               nm, daw_len[s_daw], dlen));
        if ((dlen > 0) && (daw_bst[s_daw] !== INCR))
          fail("B4", $sformatf("%0s: downstream awburst=%02b on a %0d-beat burst, expected INCR",
                               nm, daw_bst[s_daw], dlen+1));

        // E3: the downstream burst always has exactly dlen+1 beats, including
        // beats whose lanes are all unstrobed.
        waited = 0;
        while (((n_dw - s_dw) < (dlen + 1)) && (waited < 1000)) begin
          @(posedge clk);
          waited = waited + 1;
        end
        if ((n_dw - s_dw) < (dlen + 1)) begin
          fail("E3", $sformatf("%0s: downstream W burst had %0d beats, expected %0d",
                               nm, n_dw - s_dw, dlen + 1));
        end
        else begin
          for (j = 0; j <= dlen; j++) begin
            want_strb = '0;
            if (dw_last[s_dw + j] !== ((j == dlen) ? 1'b1 : 1'b0))
              fail("E4", $sformatf("%0s: downstream W beat %0d of %0d has wlast=%0b",
                                   nm, j, dlen+1, dw_last[s_dw + j]));
            for (k = 0; k < int'(bbytes(d)); k++) begin
              aa     = int'(algn(addr, d)) + j * int'(bbytes(d)) + k;
              lane_d = aa % MBYTES;
              if ((aa >= int'(addr)) && (aa <= lastbyte)) begin
                ub = (aa - int'(algn(addr, sz))) / int'(bbytes(sz));
                if (uw_strb[ub][aa % SBYTES]) begin
                  want_strb[lane_d] = 1'b1;
                  // E1: data checked only where strobed; unstrobed lanes carry
                  // no byte the upstream burst presented.
                  got_byte  = dw_data[s_dw + j][8*lane_d +: 8];
                  want_byte = uw_data[ub][8*(aa % SBYTES) +: 8];
                  if (got_byte !== want_byte)
                    fail("E1", $sformatf("%0s: downstream beat %0d lane %0d (byte addr %08h) = %02h, expected %02h",
                                         nm, j, lane_d, aa, got_byte, want_byte));
                end
              end
            end
            // E2: exactly the bits for the lanes this beat covers, nothing else.
            if (dw_strb[s_dw + j] !== want_strb)
              fail("E2", $sformatf("%0s: downstream beat %0d strb=%02b, expected %02b",
                                   nm, j, dw_strb[s_dw + j], want_strb));
          end
          idle_cycles(10);
          if ((n_dw - s_dw) != (dlen + 1))
            fail("E3", $sformatf("%0s: downstream W burst had %0d beats after settling, expected %0d",
                                 nm, n_dw - s_dw, dlen + 1));
        end
        drv_bbeat(id, bresp_code);
      end
    end
    else begin
      idle_cycles(25);
      // C4.2 / C4.3: no downstream transaction at all, not even a data beat.
      if ((n_daw - s_daw) != 0)
        fail("C4", $sformatf("%0s: refused write produced %0d downstream write request(s)",
                             nm, n_daw - s_daw));
      if ((n_dw - s_dw) != 0)
        fail("C4", $sformatf("%0s: refused write forwarded %0d downstream W beat(s)",
                             nm, n_dw - s_dw));
      if ((n_dar - s_dar) != 0)
        fail("C4", $sformatf("%0s: refused write produced downstream read activity", nm));
    end

    // ---- upstream B ------------------------------------------------------
    waited = 0;
    while (((n_ub - s_ub) < 1) && (waited < 1000)) begin
      @(posedge clk);
      waited = waited + 1;
    end
    if ((n_ub - s_ub) < 1) begin
      fail(refused ? "C4" : "A3", $sformatf("%0s: no upstream B response", nm));
    end
    else begin
      want_resp = refused ? SLVERR : bresp_code;
      if (ub_id[s_ub] !== id[ID_W-1:0])
        fail("E5", $sformatf("%0s: upstream bid=%0d, expected %0d", nm, ub_id[s_ub], id));
      if (ub_resp[s_ub] !== want_resp)
        fail(refused ? "C4" : "E6",
             $sformatf("%0s: upstream bresp=%02b, expected %02b", nm, ub_resp[s_ub], want_resp));
      idle_cycles(15);
      // A3 / E5: exactly one response, neither more nor fewer.
      if ((n_ub - s_ub) != 1)
        fail("E5", $sformatf("%0s: produced %0d upstream B responses, expected exactly 1",
                             nm, n_ub - s_ub));
    end
  endtask

  // =========================================================================
  // Stimulus
  // =========================================================================
  int  ph_i, ph_k, ph_w, ph_which;
  bit  ph_ok;
  int  s_dar_p, s_ur_p, s_ub_p;
  logic [ADDR_W-1:0] cc_addr [4];

  initial begin
    nerr = 0; nprint = 0;
    n_dar = 0; n_daw = 0; n_dw = 0; n_ur = 0; n_ub = 0;
    edge_cnt = 0;

    s_awid = '0; s_awaddr = '0; s_awlen = '0; s_awsize = '0; s_awburst = INCR;
    s_awvalid = 1'b0;
    s_wdata = '0; s_wstrb = '0; s_wlast = 1'b0; s_wvalid = 1'b0;
    s_bready = 1'b1;
    s_arid = '0; s_araddr = '0; s_arlen = '0; s_arsize = '0; s_arburst = INCR;
    s_arvalid = 1'b0;
    s_rready = 1'b1;
    m_awready = 1'b1; m_wready = 1'b1; m_arready = 1'b1;
    m_bid = '0; m_bresp = OKAY; m_bvalid = 1'b0;
    m_rid = '0; m_rdata = '0; m_rresp = OKAY; m_rlast = 1'b0; m_rvalid = 1'b0;

    bfm_reset(6);
    idle_cycles(4);

    // ---- reads: the address transform, every measured case ---------------
    do_read(1, 32'h0000_1000, 1, 3, INCR, -1, OKAY, "rd aligned len1 size3 (dlen 7)");
    do_read(2, 32'h0000_1004, 1, 3, INCR, -1, OKAY, "rd unaligned len1 size3 (dlen 5)");
    do_read(3, 32'h0000_1001, 0, 1, INCR, -1, OKAY, "rd single byte size1 (dlen 0)");
    do_read(4, 32'h0000_2003, 0, 0, INCR, -1, OKAY, "rd size0 stays size0");
    do_read(5, 32'h0000_2005, 3, 0, INCR, -1, OKAY, "rd size0 len3");
    do_read(6, 32'h0000_3000, 3, 3, INCR, -1, OKAY, "rd len3 size3 (dlen 15)");
    do_read(7, 32'h0000_4000, 0, 3, INCR, -1, OKAY, "rd len0 size3 (dlen 3)");
    do_read(8, 32'h0000_9002, 2, 1, INCR, -1, OKAY, "rd len2 size1");
    do_read(9, 32'h0000_A001, 1, 2, INCR, -1, OKAY, "rd unaligned size2");

    // C3: FIXED len=0 is served, and B4 binds on its multi-beat downstream burst.
    do_read(10, 32'h0000_5000, 0, 3, FIXED, -1, OKAY, "rd FIXED len0 (accepted, C3/B4)");

    // C1/C2, reported under C4.
    do_read(11, 32'h0000_6000, 1, 3, FIXED, -1, OKAY, "rd FIXED len1 (refused)");
    do_read(12, 32'h0000_7000, 3, 3, WRAP,  -1, OKAY, "rd WRAP (refused)");
    do_read(13, 32'h0000_7100, 0, 3, WRAP,  -1, OKAY, "rd WRAP len0 (refused)");

    // D5/D6/D7: sticky error precedence and code preservation.
    do_read(14, 32'h0000_8000, 1, 3, INCR,  0, SLVERR, "rd err on dbeat 0 (SLVERR SLVERR)");
    do_read(15, 32'h0000_8100, 1, 3, INCR,  3, SLVERR, "rd err on dbeat 3 (SLVERR SLVERR)");
    do_read(16, 32'h0000_8200, 1, 3, INCR,  7, SLVERR, "rd err on last dbeat (OKAY SLVERR)");
    do_read(17, 32'h0000_8300, 1, 3, INCR,  2, DECERR, "rd DECERR preserved (D7)");
    do_read(18, 32'h0000_8400, 1, 3, INCR,  4, DECERR, "rd DECERR on second group");

    // ---- writes ----------------------------------------------------------
    do_write(1, 32'h0001_0000, 1, 3, INCR, 0, OKAY,   "wr aligned len1 size3 full strb");
    do_write(2, 32'h0001_1000, 0, 3, INCR, 1, OKAY,   "wr strb 0x81 (E2: 01 00 00 10)");
    do_write(3, 32'h0001_2000, 0, 3, INCR, 2, OKAY,   "wr strb 0x0F (E3: 4 beats, 2 empty)");
    do_write(4, 32'h0001_3000, 0, 3, INCR, 4, OKAY,   "wr strb 0x00 (E3: all beats emitted)");
    do_write(5, 32'h0001_4004, 1, 3, INCR, 0, OKAY,   "wr unaligned len1 size3 (dlen 5)");
    do_write(6, 32'h0001_5002, 0, 1, INCR, 0, OKAY,   "wr size1 lanes 2,3 (X3)");
    do_write(7, 32'h0001_6003, 2, 0, INCR, 0, OKAY,   "wr size0 stays size0");
    do_write(8, 32'h0001_7000, 0, 3, FIXED, 0, OKAY,  "wr FIXED len0 (accepted, C3/B4)");
    do_write(9, 32'h0001_8000, 3, 3, INCR, 3, OKAY,   "wr len3 strb 0xAA");
    do_write(10, 32'h0001_9000, 1, 3, INCR, 0, SLVERR, "wr B SLVERR preserved (E6)");
    do_write(11, 32'h0001_A000, 1, 3, INCR, 0, DECERR, "wr B DECERR preserved (E6)");
    do_write(12, 32'h0001_B000, 1, 3, FIXED, 0, OKAY,  "wr FIXED len1 (refused)");
    do_write(13, 32'h0001_C000, 2, 3, WRAP,  0, OKAY,  "wr WRAP (refused)");

    // ---- A4/A3: MAX_READS outstanding, distinct ids ----------------------
    // Single-beat bursts, so inter-transaction interleaving (L3) cannot matter.
    s_dar_p = n_dar;
    s_ur_p  = n_ur;
    for (ph_k = 0; ph_k < MAX_READS; ph_k++) begin
      cc_addr[ph_k] = 32'h0002_0000 + ph_k * 32'h40;
      drv_ar(ph_k + 1, cc_addr[ph_k], 0, 1, INCR, 300, ph_ok);
      if (!ph_ok)
        fail("A4", $sformatf("read %0d of MAX_READS=%0d not accepted with fewer than the bound outstanding",
                             ph_k, MAX_READS));
    end
    ph_w = 0;
    while (((n_dar - s_dar_p) < MAX_READS) && (ph_w < 1000)) begin
      @(posedge clk);
      ph_w = ph_w + 1;
    end
    if ((n_dar - s_dar_p) < MAX_READS) begin
      fail("A2", $sformatf("only %0d of %0d downstream read requests appeared",
                           n_dar - s_dar_p, MAX_READS));
    end
    else begin
      // Answer in the order the design asked, which is its choice (L3).
      for (ph_k = 0; ph_k < MAX_READS; ph_k++) begin
        ph_which = int'(dar_id[s_dar_p + ph_k]) - 1;
        if ((ph_which < 0) || (ph_which >= MAX_READS)) begin
          fail("A2", $sformatf("downstream read request carries unknown id %0d",
                               dar_id[s_dar_p + ph_k]));
          ph_which = 0;
        end
        else begin
          if (dar_addr[s_dar_p + ph_k] !== cc_addr[ph_which])
            fail("B3", $sformatf("outstanding read id %0d: downstream addr %08h, expected %08h",
                                 ph_which + 1, dar_addr[s_dar_p + ph_k], cc_addr[ph_which]));
        end
        drv_rbeat(int'(dar_id[s_dar_p + ph_k]),
                  {rd_byte(int'(cc_addr[ph_which]) + 1), rd_byte(int'(cc_addr[ph_which]))},
                  OKAY, 1'b1);
      end
      ph_w = 0;
      while (((n_ur - s_ur_p) < MAX_READS) && (ph_w < 1000)) begin
        @(posedge clk);
        ph_w = ph_w + 1;
      end
      if ((n_ur - s_ur_p) < MAX_READS) begin
        fail("A3", $sformatf("only %0d of %0d outstanding reads produced an upstream response",
                             n_ur - s_ur_p, MAX_READS));
      end
      else begin
        for (ph_k = 0; ph_k < MAX_READS; ph_k++) begin
          ph_which = int'(ur_id[s_ur_p + ph_k]) - 1;
          if ((ph_which < 0) || (ph_which >= MAX_READS)) begin
            fail("D3", $sformatf("upstream R beat carries unknown id %0d", ur_id[s_ur_p + ph_k]));
          end
          else begin
            if (!ur_last[s_ur_p + ph_k])
              fail("D4", $sformatf("outstanding read id %0d: single-beat burst without rlast",
                                   ph_which + 1));
            if (ur_resp[s_ur_p + ph_k] !== OKAY)
              fail("D5", $sformatf("outstanding read id %0d: resp %02b, expected OKAY",
                                   ph_which + 1, ur_resp[s_ur_p + ph_k]));
            for (ph_i = 0; ph_i < 2; ph_i++) begin
              if (ur_data[s_ur_p + ph_k][8*((int'(cc_addr[ph_which]) + ph_i) % SBYTES) +: 8]
                    !== rd_byte(int'(cc_addr[ph_which]) + ph_i))
                fail("D1", $sformatf("outstanding read id %0d: byte %0d mismatched",
                                     ph_which + 1, ph_i));
            end
          end
        end
      end
      idle_cycles(15);
      if ((n_ur - s_ur_p) != MAX_READS)
        fail("A3", $sformatf("%0d outstanding reads produced %0d upstream R beats, expected %0d",
                             MAX_READS, n_ur - s_ur_p, MAX_READS));
    end

    // ---- F3: a read outstanding across a reset produces no response ------
    s_dar_p = n_dar;
    s_ur_p  = n_ur;
    drv_ar(6, 32'h0003_0000, 1, 3, INCR, 300, ph_ok);
    if (!ph_ok) fail("A1", "reset phase: read address never accepted");
    ph_w = 0;
    while (((n_dar - s_dar_p) < 1) && (ph_w < 500)) begin
      @(posedge clk);
      ph_w = ph_w + 1;
    end
    // Deliberately answer nothing downstream, then reset.
    bfm_reset(6);
    idle_cycles(30);
    if ((n_ur - s_ur_p) != 0)
      fail("F3", $sformatf("%0d upstream R beat(s) after reset for a transaction outstanding before it",
                           n_ur - s_ur_p));

    // F3 for a write: address and data in, downstream B deliberately withheld,
    // then reset.  No upstream B may appear afterwards.
    s_ub_p = n_ub;
    drv_aw(7, 32'h0003_1000, 0, 3, INCR, 300, ph_ok);
    if (!ph_ok) fail("A1", "reset phase: write address never accepted");
    drv_w(64'hCAFE_F00D_1234_5678, 8'hFF, 1'b1, 300, ph_ok);
    if (!ph_ok) fail("A1", "reset phase: write data beat never accepted");
    idle_cycles(10);
    bfm_reset(6);
    idle_cycles(30);
    if ((n_ub - s_ub_p) != 0)
      fail("F3", $sformatf("%0d upstream B response(s) after reset for a write outstanding before it",
                           n_ub - s_ub_p));

    // ---- F2: after release the unit is idle and serves again -------------
    do_read(1, 32'h0004_0000, 1, 3, INCR, -1, OKAY, "rd after reset (F2)");
    do_write(1, 32'h0004_1000, 1, 3, INCR, 0, OKAY, "wr after reset (F2)");
    s_dar_p = n_dar;
    for (ph_k = 0; ph_k < MAX_READS; ph_k++) begin
      drv_ar(ph_k + 1, 32'h0005_0000 + ph_k * 32'h40, 0, 1, INCR, 300, ph_ok);
      if (!ph_ok)
        fail("F2", $sformatf("after reset, read %0d of MAX_READS not accepted", ph_k));
    end
    ph_w = 0;
    while (((n_dar - s_dar_p) < MAX_READS) && (ph_w < 1000)) begin
      @(posedge clk);
      ph_w = ph_w + 1;
    end
    if ((n_dar - s_dar_p) < MAX_READS)
      fail("F2", $sformatf("after reset only %0d of %0d reads reached the downstream port",
                           n_dar - s_dar_p, MAX_READS));
    else
      for (ph_k = 0; ph_k < MAX_READS; ph_k++)
        drv_rbeat(int'(dar_id[s_dar_p + ph_k]), 16'h0000, OKAY, 1'b1);
    idle_cycles(40);

    // ---- verdict ---------------------------------------------------------
    $display("summary: %0d failure(s); downstream ar=%0d aw=%0d w=%0d, upstream r=%0d b=%0d",
             nerr, n_dar, n_daw, n_dw, n_ur, n_ub);
    if (nerr == 0) $display("RESULT: PASS");
    else           $display("RESULT: FAIL");
    $finish;
  end

endmodule