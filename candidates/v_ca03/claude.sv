// ---------------------------------------------------------------------------
// id_width_conv_tb.sv -- self-checking testbench for id_width_conv
//
// Every check is grounded in a numbered requirement and reports it by name.
// Behaviour left free by the contract (section 8) is never checked: the master
// identifier values, the allocation order, latency, ready promptness outside
// A4's window, and the relative order of responses carrying different slave
// identifiers.
//
// Identification is by bookkeeping, not by content matching: every transaction
// is given a unique address (E1 requires it forwarded unmodified, so the master
// port address names the transaction) and every read/write data beat a unique
// payload. No check ever assumes a particular master identifier.
// ---------------------------------------------------------------------------
/* verilator lint_off WIDTH */
`timescale 1ns/1ps

module id_width_conv_tb;

  localparam int unsigned SLV_ID_W        = 4;
  localparam int unsigned MST_ID_W        = 2;
  localparam int unsigned ADDR_W          = 32;
  localparam int unsigned DATA_W          = 32;
  localparam int unsigned MAX_UNIQ_IDS    = 4;
  localparam int unsigned MAX_TXNS_PER_ID = 2;

  localparam int MAXT = 512;          // transaction records
  localparam int MAXB = 8;            // beats per transaction (len <= 7)
  localparam int NSID = 1 << SLV_ID_W;
  localparam int NMID = 1 << MST_ID_W;

  // -------------------------------------------------------------------------
  // Signals
  // -------------------------------------------------------------------------
  logic [SLV_ID_W-1:0] s_awid;
  logic [ADDR_W-1:0]   s_awaddr;
  logic [7:0]          s_awlen;
  logic                s_awvalid, s_awready;
  logic [DATA_W-1:0]   s_wdata;
  logic [DATA_W/8-1:0] s_wstrb;
  logic                s_wlast, s_wvalid, s_wready;
  logic [SLV_ID_W-1:0] s_bid;
  logic [1:0]          s_bresp;
  logic                s_bvalid, s_bready;
  logic [SLV_ID_W-1:0] s_arid;
  logic [ADDR_W-1:0]   s_araddr;
  logic [7:0]          s_arlen;
  logic                s_arvalid, s_arready;
  logic [SLV_ID_W-1:0] s_rid;
  logic [DATA_W-1:0]   s_rdata;
  logic [1:0]          s_rresp;
  logic                s_rlast, s_rvalid, s_rready;

  logic [MST_ID_W-1:0] m_awid;
  logic [ADDR_W-1:0]   m_awaddr;
  logic [7:0]          m_awlen;
  logic                m_awvalid, m_awready;
  logic [DATA_W-1:0]   m_wdata;
  logic [DATA_W/8-1:0] m_wstrb;
  logic                m_wlast, m_wvalid, m_wready;
  logic [MST_ID_W-1:0] m_bid;
  logic [1:0]          m_bresp;
  logic                m_bvalid, m_bready;
  logic [MST_ID_W-1:0] m_arid;
  logic [ADDR_W-1:0]   m_araddr;
  logic [7:0]          m_arlen;
  logic                m_arvalid, m_arready;
  logic [MST_ID_W-1:0] m_rid;
  logic [DATA_W-1:0]   m_rdata;
  logic [1:0]          m_rresp;
  logic                m_rlast, m_rvalid, m_rready;

  // -------------------------------------------------------------------------
  // DUT
  // -------------------------------------------------------------------------
  id_width_conv #(
    .SLV_ID_W        (SLV_ID_W),
    .MST_ID_W        (MST_ID_W),
    .ADDR_W          (ADDR_W),
    .DATA_W          (DATA_W),
    .MAX_UNIQ_IDS    (MAX_UNIQ_IDS),
    .MAX_TXNS_PER_ID (MAX_TXNS_PER_ID)
  ) dut (
    .clk_i (clk), .rst_ni (rst_n),
    .s_awid(s_awid), .s_awaddr(s_awaddr), .s_awlen(s_awlen),
    .s_awvalid(s_awvalid), .s_awready(s_awready),
    .s_wdata(s_wdata), .s_wstrb(s_wstrb), .s_wlast(s_wlast),
    .s_wvalid(s_wvalid), .s_wready(s_wready),
    .s_bid(s_bid), .s_bresp(s_bresp), .s_bvalid(s_bvalid), .s_bready(s_bready),
    .s_arid(s_arid), .s_araddr(s_araddr), .s_arlen(s_arlen),
    .s_arvalid(s_arvalid), .s_arready(s_arready),
    .s_rid(s_rid), .s_rdata(s_rdata), .s_rresp(s_rresp), .s_rlast(s_rlast),
    .s_rvalid(s_rvalid), .s_rready(s_rready),
    .m_awid(m_awid), .m_awaddr(m_awaddr), .m_awlen(m_awlen),
    .m_awvalid(m_awvalid), .m_awready(m_awready),
    .m_wdata(m_wdata), .m_wstrb(m_wstrb), .m_wlast(m_wlast),
    .m_wvalid(m_wvalid), .m_wready(m_wready),
    .m_bid(m_bid), .m_bresp(m_bresp), .m_bvalid(m_bvalid), .m_bready(m_bready),
    .m_arid(m_arid), .m_araddr(m_araddr), .m_arlen(m_arlen),
    .m_arvalid(m_arvalid), .m_arready(m_arready),
    .m_rid(m_rid), .m_rdata(m_rdata), .m_rresp(m_rresp), .m_rlast(m_rlast),
    .m_rvalid(m_rvalid), .m_rready(m_rready)
  );

// ---------------------------------------------------------------------------
// PROVIDED PLUMBING -- moves transactions, checks nothing.
// ---------------------------------------------------------------------------

  logic clk;
  initial begin clk = 1'b0; forever #5 clk = ~clk; end

  logic rst_n;
  initial rst_n = 1'b0;

  // Asserted and released away from the sampling edge.
  task automatic bfm_reset(input int cycles = 4);
    @(negedge clk);
    rst_n = 1'b0;
    repeat (cycles) @(posedge clk);
    @(negedge clk);
    rst_n = 1'b1;
  endtask

  // Offer a read address and hold it stable until accepted or the budget runs
  // out. Reports BOTH facts: whether it went, and how many cycles it waited.
  // Interpreting a refusal is yours.
  task automatic bfm_ar(input  logic [SLV_ID_W-1:0] id,
                        input  logic [ADDR_W-1:0]   addr,
                        input  logic [7:0]          len,
                        input  int                  budget,
                        output bit                  accepted,
                        output int                  waited);
    accepted = 1'b0; waited = 0;
    @(negedge clk);
    s_arid = id; s_araddr = addr; s_arlen = len; s_arvalid = 1'b1;
    while (waited < budget) begin
      @(posedge clk);
      if (s_arready) begin accepted = 1'b1; break; end
      waited++;
    end
    @(negedge clk) s_arvalid = 1'b0;
  endtask

  // The same for a write address.
  task automatic bfm_aw(input  logic [SLV_ID_W-1:0] id,
                        input  logic [ADDR_W-1:0]   addr,
                        input  logic [7:0]          len,
                        input  int                  budget,
                        output bit                  accepted,
                        output int                  waited);
    accepted = 1'b0; waited = 0;
    @(negedge clk);
    s_awid = id; s_awaddr = addr; s_awlen = len; s_awvalid = 1'b1;
    while (waited < budget) begin
      @(posedge clk);
      if (s_awready) begin accepted = 1'b1; break; end
      waited++;
    end
    @(negedge clk) s_awvalid = 1'b0;
  endtask

  // Watchdog. Fires regardless of what the design does -- one of the faulty
  // implementations refuses a request it should accept.
  initial begin
    #4_000_000;
    $display("RESULT: FAIL (watchdog: no forward progress)");
    $finish;
  end

// ---------------------------------------------------------------------------
// END OF PROVIDED PLUMBING
//
// The three data-movement tasks below replace bfm_w / bfm_rbeat / bfm_bbeat.
// They are the provided bodies with the unbounded `forever` wait given a
// budget, so that a design which never raises a ready reports the failure that
// caused it rather than relying on the watchdog (G1).
// ---------------------------------------------------------------------------

  // -------------------------------------------------------------------------
  // Failure reporting
  // -------------------------------------------------------------------------
  int  errors;
  int  cyc;

  task automatic finish_run();
    if (errors == 0) $display("RESULT: PASS");
    else             $display("RESULT: FAIL");
    $finish;
  endtask

  task automatic tb_fail(input string req, input string msg);
    errors++;
    $display("[%s] t=%0t: %s", req, $time, msg);
    if (errors >= 40) begin
      $display("too many failures, stopping");
      finish_run();
    end
  endtask

  // -------------------------------------------------------------------------
  // Model of what the contract says must be true
  // -------------------------------------------------------------------------
  int          t_sid   [MAXT];   // slave identifier
  int          t_len   [MAXT];   // awlen/arlen
  int          t_mid    [MAXT];  // master identifier, observed
  bit          t_hasm  [MAXT];   // master identifier known yet
  bit          t_iswr  [MAXT];   // write (1) or read (0)
  bit          t_acc   [MAXT];   // accepted on the slave port
  bit          t_out   [MAXT];   // outstanding per A1
  bit          t_kill  [MAXT];   // discarded by a reset (F1)
  bit          t_mseen [MAXT];   // master address request observed
  bit          t_wdone [MAXT];   // all write beats forwarded
  logic [1:0]  t_resp  [MAXT];   // response code this TB will drive back
  int          t_accc  [MAXT];   // cycle of slave-side acceptance
  int          seq_ctr;

  bit r_sent [MAXT*MAXB];        // read beat presented on the master port
  bit r_seen [MAXT*MAXB];        // read beat observed on the slave port

  int cnt_rd [NSID];             // outstanding per slave id, reads
  int cnt_wr [NSID];             // outstanding per slave id, writes
  int ndist_rd, ndist_wr;        // distinct identifiers outstanding
  int ret_cyc_rd [NSID];         // cycle an identifier last retired (A4)
  int ret_cyc_wr [NSID];

  int mpend_r [$];               // master reads awaiting a downstream response
  int mpend_w [$];
  int exp_r_q [$];               // read beats sent downstream, in send order
  int exp_b_q [$];               // write responses sent downstream
  int w_exp_q [$];               // write beats expected on the master port (B3)

  bit rst_chk;                   // enforce "idle while reset is low" (F1)
  bit quiet_chk;                 // enforce "nothing survives a reset" (F1)
  bit f1_rep_r, f1_rep_b;        // one-shot flags, so a stuck valid is one line

  int scratch [16];

  // ---- encodings -----------------------------------------------------------
  function automatic int enc_f(input int s, input int b);
    return s*MAXB + b;
  endfunction

  function automatic logic [ADDR_W-1:0] addr_f(input int s, input bit wr);
    return (wr ? 32'h2000_0000 : 32'h1000_0000) + (s * 64);
  endfunction

  function automatic int seq_from_addr(input logic [ADDR_W-1:0] a, input bit wr);
    automatic logic [ADDR_W-1:0] base;
    automatic logic [ADDR_W-1:0] d;
    base = wr ? 32'h2000_0000 : 32'h1000_0000;
    if (a < base) return -1;
    d = a - base;
    if (d[5:0] != 6'd0) return -1;
    if ((d >> 6) >= MAXT) return -1;
    return int'(d >> 6);
  endfunction

  function automatic logic [DATA_W-1:0] rdata_f(input int s, input int b);
    return 32'h8000_0000 | enc_f(s,b);
  endfunction

  function automatic logic [DATA_W-1:0] wdata_f(input int s, input int b);
    return 32'h4000_0000 | enc_f(s,b);
  endfunction

  function automatic logic [DATA_W/8-1:0] strb_f(input int s, input int b);
    automatic int v;
    v = ((s + b) % 15) + 1;
    return v[DATA_W/8-1:0];
  endfunction

  // A response may be presented for a transaction only when no older
  // transaction with the same slave identifier is still outstanding: B1 fixes
  // the slave-side order, so this testbench never asks a design to reorder.
  function automatic bit is_head(input int sq);
    automatic int j;
    for (j = 0; j < sq; j++)
      if (t_out[j] && (t_iswr[j] == t_iswr[sq]) && (t_sid[j] == t_sid[sq]))
        return 1'b0;
    return 1'b1;
  endfunction

  function automatic int find_pending(input bit wr, input int mid);
    automatic int i, best;
    best = -1;
    if (wr) begin
      for (i = 0; i < mpend_w.size(); i++)
        if ((t_mid[mpend_w[i]] == mid) && (best < 0 || mpend_w[i] < best))
          best = mpend_w[i];
    end else begin
      for (i = 0; i < mpend_r.size(); i++)
        if ((t_mid[mpend_r[i]] == mid) && (best < 0 || mpend_r[i] < best))
          best = mpend_r[i];
    end
    if (best >= 0 && !is_head(best)) best = -1;
    return best;
  endfunction

  function automatic int take_pending(input bit wr, input int mid);
    automatic int i, best;
    best = find_pending(wr, mid);
    if (best < 0) return -1;
    if (wr) begin
      for (i = 0; i < mpend_w.size(); i++)
        if (mpend_w[i] == best) begin mpend_w.delete(i); break; end
    end else begin
      for (i = 0; i < mpend_r.size(); i++)
        if (mpend_r[i] == best) begin mpend_r.delete(i); break; end
    end
    return best;
  endfunction

  function automatic bit any_outstanding();
    automatic int i;
    for (i = 0; i < seq_ctr; i++)
      if (t_acc[i] && !t_kill[i] && t_out[i]) return 1'b1;
    return 1'b0;
  endfunction

  always @(posedge clk) cyc <= cyc + 1;

  // -------------------------------------------------------------------------
  // Monitoring. One process, so that everything sampled at a rising edge is
  // evaluated in a defined order. Completions are processed first: A4 makes a
  // table entry free on the very edge at which its last transaction completes,
  // so a request accepted on that same edge must be judged against the table
  // as it is AFTER the retirement.
  // -------------------------------------------------------------------------

  task automatic mon_slave_r();
    automatic int e, sq, bt, i, k, idx;
    if (rst_chk && s_rvalid && !f1_rep_r) begin
      f1_rep_r = 1'b1;
      tb_fail("F1", "a read response was presented while rst_ni was low");
    end
    if (!(s_rvalid && s_rready)) return;
    if (!rst_n) begin
      tb_fail("F1", "a read response transferred while rst_ni was low");
      return;
    end
    if (s_rdata[31:12] !== 20'h80000) begin
      tb_fail("E1", $sformatf("read data %h is not a value presented on the master port", s_rdata));
      return;
    end
    e  = int'(s_rdata[11:0]);
    sq = e / MAXB;
    bt = e % MAXB;
    if (sq >= seq_ctr) begin
      tb_fail("E1", $sformatf("read data %h is not a value presented on the master port", s_rdata));
      return;
    end
    if (t_kill[sq]) begin
      tb_fail("F1", "a read response was presented for a transaction discarded by reset");
      return;
    end
    if (quiet_chk && !f1_rep_r) begin
      f1_rep_r = 1'b1;
      tb_fail("F1", "a read response appeared after reset with nothing outstanding");
      return;
    end
    if (!r_sent[e]) begin
      tb_fail("C2", "a read beat reached the slave port that was never presented on the master port");
      return;
    end
    if (r_seen[e]) begin
      tb_fail("D4", "one master read beat produced more than one slave read beat");
      return;
    end
    r_seen[e] = 1'b1;
    if (!t_out[sq])
      tb_fail("C2", "a read response was presented for a transaction that is not outstanding");
    if (int'(s_rid) != t_sid[sq])
      tb_fail("C1", $sformatf("read response carries RID %0d, transaction was issued with ID %0d",
                              s_rid, t_sid[sq]));
    if (s_rlast !== ((bt == t_len[sq]) ? 1'b1 : 1'b0))
      tb_fail("E1", "rlast was not forwarded unmodified");
    if (s_rresp !== t_resp[sq])
      tb_fail("E1", "rresp was not forwarded unmodified");
    // B1: within one slave identifier, in the order the requests were accepted
    idx = -1;
    for (i = 0; i < exp_r_q.size(); i++) begin
      k = exp_r_q[i] / MAXB;
      if (t_sid[k] == int'(s_rid)) begin idx = i; break; end
    end
    if (idx < 0)
      tb_fail("C2", "a read beat was presented for an identifier with no response outstanding");
    else if (exp_r_q[idx] != e)
      tb_fail("B1", "read responses for one slave identifier are out of request order");
    else
      exp_r_q.delete(idx);
    if (bt == t_len[sq]) begin
      t_out[sq] = 1'b0;
      cnt_rd[t_sid[sq]]--;
      if (cnt_rd[t_sid[sq]] == 0) begin
        ndist_rd--;
        ret_cyc_rd[t_sid[sq]] = cyc;
      end
    end
  endtask

  task automatic mon_slave_b();
    automatic int i, idx, sq;
    if (rst_chk && s_bvalid && !f1_rep_b) begin
      f1_rep_b = 1'b1;
      tb_fail("F1", "a write response was presented while rst_ni was low");
    end
    if (!(s_bvalid && s_bready)) return;
    if (!rst_n) begin
      tb_fail("F1", "a write response transferred while rst_ni was low");
      return;
    end
    if (quiet_chk && !f1_rep_b) begin
      f1_rep_b = 1'b1;
      tb_fail("F1", "a write response appeared after reset with nothing outstanding");
      return;
    end
    idx = -1;
    for (i = 0; i < exp_b_q.size(); i++)
      if (t_sid[exp_b_q[i]] == int'(s_bid)) begin idx = i; break; end
    if (idx < 0) begin
      tb_fail("C1", $sformatf("write response carries BID %0d, for which no response is outstanding", s_bid));
      return;
    end
    sq = exp_b_q[idx];
    exp_b_q.delete(idx);
    if (t_kill[sq])
      tb_fail("F1", "a write response was presented for a transaction discarded by reset");
    if (!t_out[sq])
      tb_fail("C2", "a write response was presented for a transaction that is not outstanding");
    if (s_bresp !== t_resp[sq])
      tb_fail("E1", "bresp was not forwarded unmodified");
    t_out[sq] = 1'b0;
    cnt_wr[t_sid[sq]]--;
    if (cnt_wr[t_sid[sq]] == 0) begin
      ndist_wr--;
      ret_cyc_wr[t_sid[sq]] = cyc;
    end
  endtask

  task automatic mon_master_w();
    automatic int e, sq, bt;
    if (!(m_wvalid && m_wready)) return;
    if (!rst_n) return;
    if (w_exp_q.size() == 0) begin
      tb_fail("D4", "a write data beat appeared on the master port with none pending");
      return;
    end
    e  = w_exp_q[0];
    sq = e / MAXB;
    bt = e % MAXB;
    void'(w_exp_q.pop_front());
    if (t_kill[sq]) return;
    if (m_wdata !== wdata_f(sq, bt)) begin
      tb_fail("B3", "write data beats are not in the order their addresses were accepted, or wdata was modified");
      return;
    end
    if (m_wstrb !== strb_f(sq, bt))
      tb_fail("E1", "wstrb was not forwarded unmodified");
    if (m_wlast !== ((bt == t_len[sq]) ? 1'b1 : 1'b0))
      tb_fail("E1", "wlast was not forwarded unmodified");
    if (bt == t_len[sq]) t_wdone[sq] = 1'b1;
  endtask

  // Master address requests: this is where the identifier mapping becomes
  // observable, so D1/D2 are checked here. Which value is chosen is never
  // checked (D3).
  task automatic mon_master_ar();
    automatic int sq, j;
    if (!(m_arvalid && m_arready)) return;
    if (!rst_n) return;
    sq = seq_from_addr(m_araddr, 1'b0);
    if (sq < 0 || sq >= seq_ctr || t_iswr[sq]) begin
      tb_fail("E1", $sformatf("master read address %h matches no slave read request", m_araddr));
      return;
    end
    if (t_kill[sq]) return;         // pre-reset leftovers: F1 covers those
    if (t_mseen[sq]) begin
      tb_fail("D4", "one slave read request produced more than one master read request");
      return;
    end
    t_mseen[sq] = 1'b1;
    if (m_arlen !== t_len[sq][7:0])
      tb_fail("E1", "arlen was not forwarded unmodified");
    for (j = 0; j < seq_ctr; j++)
      if (!t_iswr[j] && t_out[j] && t_hasm[j] && (j != sq)
          && (t_mid[j] == int'(m_arid)) && (t_sid[j] != t_sid[sq])) begin
        tb_fail("D1", $sformatf("master ID %0d carries slave IDs %0d and %0d at the same time (reads)",
                                m_arid, t_sid[j], t_sid[sq]));
        break;
      end
    t_mid[sq]  = int'(m_arid);
    t_hasm[sq] = 1'b1;
    mpend_r.push_back(sq);
  endtask

  task automatic mon_master_aw();
    automatic int sq, j;
    if (!(m_awvalid && m_awready)) return;
    if (!rst_n) return;
    sq = seq_from_addr(m_awaddr, 1'b1);
    if (sq < 0 || sq >= seq_ctr || !t_iswr[sq]) begin
      tb_fail("E1", $sformatf("master write address %h matches no slave write request", m_awaddr));
      return;
    end
    if (t_kill[sq]) return;
    if (t_mseen[sq]) begin
      tb_fail("D4", "one slave write request produced more than one master write request");
      return;
    end
    t_mseen[sq] = 1'b1;
    if (m_awlen !== t_len[sq][7:0])
      tb_fail("E1", "awlen was not forwarded unmodified");
    for (j = 0; j < seq_ctr; j++)
      if (t_iswr[j] && t_out[j] && t_hasm[j] && (j != sq)
          && (t_mid[j] == int'(m_awid)) && (t_sid[j] != t_sid[sq])) begin
        tb_fail("D1", $sformatf("master ID %0d carries slave IDs %0d and %0d at the same time (writes)",
                                m_awid, t_sid[j], t_sid[sq]));
        break;
      end
    t_mid[sq]  = int'(m_awid);
    t_hasm[sq] = 1'b1;
    mpend_w.push_back(sq);
  endtask

  // Slave address acceptance: A2/A3/A5 are checked on every acceptance, for
  // the whole run, not only where a directed test looks.
  task automatic mon_slave_ar();
    automatic int sq, sid;
    if (!(s_arvalid && s_arready)) return;
    if (!rst_n) begin
      tb_fail("F1", "a read request was accepted while rst_ni was low");
      return;
    end
    sq = seq_from_addr(s_araddr, 1'b0);
    if (sq < 0 || sq >= seq_ctr || t_iswr[sq]) return;
    sid = t_sid[sq];
    if ((cnt_rd[sid] == 0) && (ndist_rd >= int'(MAX_UNIQ_IDS)))
      tb_fail("A3", $sformatf("read ID %0d accepted while %0d other distinct read IDs were outstanding",
                              sid, ndist_rd));
    if (cnt_rd[sid] >= int'(MAX_TXNS_PER_ID))
      tb_fail("A5", $sformatf("read ID %0d accepted while %0d transactions with that ID were outstanding",
                              sid, cnt_rd[sid]));
    if (cnt_rd[sid] == 0) ndist_rd++;
    cnt_rd[sid]++;
    t_acc[sq]  = 1'b1;
    t_out[sq]  = 1'b1;
    t_accc[sq] = cyc;
  endtask

  task automatic mon_slave_aw();
    automatic int sq, sid, b;
    if (!(s_awvalid && s_awready)) return;
    if (!rst_n) begin
      tb_fail("F1", "a write request was accepted while rst_ni was low");
      return;
    end
    sq = seq_from_addr(s_awaddr, 1'b1);
    if (sq < 0 || sq >= seq_ctr || !t_iswr[sq]) return;
    sid = t_sid[sq];
    if ((cnt_wr[sid] == 0) && (ndist_wr >= int'(MAX_UNIQ_IDS)))
      tb_fail("A3", $sformatf("write ID %0d accepted while %0d other distinct write IDs were outstanding",
                              sid, ndist_wr));
    if (cnt_wr[sid] >= int'(MAX_TXNS_PER_ID))
      tb_fail("A5", $sformatf("write ID %0d accepted while %0d transactions with that ID were outstanding",
                              sid, cnt_wr[sid]));
    if (cnt_wr[sid] == 0) ndist_wr++;
    cnt_wr[sid]++;
    t_acc[sq]  = 1'b1;
    t_out[sq]  = 1'b1;
    t_accc[sq] = cyc;
    for (b = 0; b <= t_len[sq]; b++) w_exp_q.push_back(enc_f(sq, b));  // B3
  endtask

  always @(posedge clk) begin
    mon_slave_r();
    mon_slave_b();
    mon_master_w();
    mon_master_ar();
    mon_master_aw();
    mon_slave_ar();
    mon_slave_aw();
  end

  // -------------------------------------------------------------------------
  // Stimulus
  // -------------------------------------------------------------------------
  task automatic drv_w(input logic [DATA_W-1:0]   data,
                       input logic [DATA_W/8-1:0] strb,
                       input logic                last,
                       input int                  budget);
    automatic int w;
    w = 0;
    @(negedge clk);
    s_wdata = data; s_wstrb = strb; s_wlast = last; s_wvalid = 1'b1;
    while (w < budget) begin
      @(posedge clk);
      if (s_wready) break;
      w++;
    end
    @(negedge clk) s_wvalid = 1'b0;
    if (w >= budget) begin
      tb_fail("D4", "a write data beat was never accepted on the slave port");
      finish_run();
    end
  endtask

  task automatic drv_rbeat(input int                  mid,
                           input logic [DATA_W-1:0]   data,
                           input logic [1:0]          rsp,
                           input logic                last,
                           input int                  budget);
    automatic int w;
    w = 0;
    @(negedge clk);
    m_rid = mid[MST_ID_W-1:0]; m_rdata = data; m_rlast = last;
    m_rresp = rsp; m_rvalid = 1'b1;
    while (w < budget) begin
      @(posedge clk);
      if (m_rready) break;
      w++;
    end
    @(negedge clk) m_rvalid = 1'b0;
    if (w >= budget) begin
      tb_fail("D4", "a read response beat was never accepted on the master port");
      finish_run();
    end
  endtask

  task automatic drv_bbeat(input int         mid,
                           input logic [1:0] rsp,
                           input int         budget);
    automatic int w;
    w = 0;
    @(negedge clk);
    m_bid = mid[MST_ID_W-1:0]; m_bresp = rsp; m_bvalid = 1'b1;
    while (w < budget) begin
      @(posedge clk);
      if (m_bready) break;
      w++;
    end
    @(negedge clk) m_bvalid = 1'b0;
    if (w >= budget) begin
      tb_fail("D4", "a write response was never accepted on the master port");
      finish_run();
    end
  endtask

  task automatic init_txn(input int sq, input int sid, input int len,
                          input bit wr, input logic [1:0] rsp);
    t_sid[sq]   = sid;
    t_len[sq]   = len;
    t_iswr[sq]  = wr;
    t_resp[sq]  = rsp;
    t_mid[sq]   = -1;
    t_hasm[sq]  = 1'b0;
    t_acc[sq]   = 1'b0;
    t_out[sq]   = 1'b0;
    t_kill[sq]  = 1'b0;
    t_mseen[sq] = 1'b0;
    t_wdone[sq] = 1'b0;
    t_accc[sq]  = -1;
  endtask

  task automatic issue_read(input  int sid, input int len, input logic [1:0] rsp,
                            input  int budget,
                            output bit acc, output int sq);
    automatic bit a;
    automatic int w;
    sq = seq_ctr;
    init_txn(sq, sid, len, 1'b0, rsp);
    seq_ctr++;
    bfm_ar(sid[SLV_ID_W-1:0], addr_f(sq, 1'b0), len[7:0], budget, a, w);
    acc = a;
  endtask

  task automatic send_write_data(input int sq);
    automatic int b;
    for (b = 0; b <= t_len[sq]; b++)
      drv_w(wdata_f(sq, b), strb_f(sq, b), (b == t_len[sq]), 3000);
  endtask

  task automatic issue_write(input  int sid, input int len, input logic [1:0] rsp,
                             input  int budget,
                             output bit acc, output int sq);
    automatic bit a;
    automatic int w;
    sq = seq_ctr;
    init_txn(sq, sid, len, 1'b1, rsp);
    seq_ctr++;
    bfm_aw(sid[SLV_ID_W-1:0], addr_f(sq, 1'b1), len[7:0], budget, a, w);
    acc = a;
    if (a) send_write_data(sq);
  endtask

  task automatic respond_read(input int mid);
    automatic int sq, b;
    sq = take_pending(1'b0, mid);
    if (sq < 0) return;
    for (b = 0; b <= t_len[sq]; b++) begin
      r_sent[enc_f(sq, b)] = 1'b1;
      exp_r_q.push_back(enc_f(sq, b));
      drv_rbeat(t_mid[sq], rdata_f(sq, b), t_resp[sq], (b == t_len[sq]), 3000);
    end
  endtask

  task automatic respond_write(input int mid);
    automatic int sq, g;
    sq = take_pending(1'b1, mid);
    if (sq < 0) return;
    g = 0;
    while ((g < 3000) && !t_wdone[sq]) begin @(posedge clk); g++; end
    if (!t_wdone[sq]) begin
      tb_fail("B3", "write data beats were never forwarded to the master port");
      finish_run();
    end
    exp_b_q.push_back(sq);
    drv_bbeat(t_mid[sq], t_resp[sq], 3000);
  endtask

  task automatic wait_mid(input int sq, input int budget);
    automatic int i;
    i = 0;
    while ((i < budget) && !t_hasm[sq]) begin @(posedge clk); i++; end
    if (!t_hasm[sq]) begin
      tb_fail("D4", "an accepted slave request never produced a master request");
      finish_run();
    end
  endtask

  task automatic wait_done(input int sq, input int budget);
    automatic int i;
    i = 0;
    while ((i < budget) && t_out[sq]) begin @(posedge clk); i++; end
    if (t_out[sq]) begin
      tb_fail("D4", "a transaction never received its response on the slave port");
      finish_run();
    end
  endtask

  // Tool note (Verilator 5.x): a call to a user function must never appear in the
  // condition of a loop whose body contains a timing control -- the function's
  // locals are corrupted and it spins forever. Every such condition below is
  // evaluated into a variable first.
  task automatic drain_all(input int budget);
    automatic int guard, i, cand;
    automatic bit did, more, busy;
    guard = 0;
    more  = ((mpend_r.size() > 0) || (mpend_w.size() > 0));
    while ((guard < budget) && more) begin
      did = 1'b0;
      for (i = 0; i < NMID; i++) begin
        cand = find_pending(1'b0, i);
        if (cand >= 0) begin respond_read(i);  did = 1'b1; end
        cand = find_pending(1'b1, i);
        if (cand >= 0) begin respond_write(i); did = 1'b1; end
      end
      if (!did) @(posedge clk);
      guard++;
      more = ((mpend_r.size() > 0) || (mpend_w.size() > 0));
    end
    guard = 0;
    busy  = any_outstanding();
    while ((guard < 3000) && busy) begin
      @(posedge clk);
      guard++;
      busy = any_outstanding();
    end
  endtask

  task automatic do_reset(input int cycles);
    automatic int i;
    @(negedge clk);
    rst_n = 1'b0;
    for (i = 0; i < seq_ctr; i++) begin
      t_kill[i] = 1'b1;
      t_out[i]  = 1'b0;
    end
    mpend_r = {}; mpend_w = {}; exp_r_q = {}; exp_b_q = {}; w_exp_q = {};
    for (i = 0; i < NSID; i++) begin cnt_rd[i] = 0; cnt_wr[i] = 0; end
    ndist_rd = 0; ndist_wr = 0;
    repeat (cycles) @(posedge clk);
    @(negedge clk);
    rst_n = 1'b1;
  endtask

  // -------------------------------------------------------------------------
  // Tests
  // -------------------------------------------------------------------------

  // One read and one write end to end: D4, E1, C1, C2, B3.
  task automatic t_basic();
    automatic bit acc;
    automatic int sq;
    issue_read(3, 2, 2'b00, 200, acc, sq);
    if (!acc) begin
      tb_fail("A3", "a read request was refused with an empty identifier table");
      return;
    end
    wait_mid(sq, 600);
    respond_read(t_mid[sq]);
    wait_done(sq, 600);

    issue_write(5, 1, 2'b00, 200, acc, sq);
    if (!acc) begin
      tb_fail("A3", "a write request was refused with an empty identifier table");
      return;
    end
    wait_mid(sq, 600);
    respond_write(t_mid[sq]);
    wait_done(sq, 600);

    // resp is payload too (E1)
    issue_read(1, 1, 2'b10, 200, acc, sq);
    if (acc) begin
      wait_mid(sq, 600);
      respond_read(t_mid[sq]);
      wait_done(sq, 600);
    end
  endtask

  // The boundary itself, on the read side: A2, A3, A5, A4, D1.
  task automatic t_read_table();
    automatic bit acc, acc5;
    automatic int sq, sq5, i, delta;
    for (i = 0; i < int'(MAX_UNIQ_IDS); i++) begin
      issue_read(i+1, 0, 2'b00, 300, acc, sq);
      if (!acc)
        tb_fail("A3", $sformatf("a read with a new ID was refused while only %0d distinct IDs were outstanding", i));
      scratch[i] = sq;
      if (acc) wait_mid(sq, 600);
    end
    // At MAX_UNIQ_IDS, an unseen identifier must not be accepted.
    issue_read(9, 0, 2'b00, 40, acc, sq);
    if (acc)
      tb_fail("A3", "a new read ID was accepted while MAX_UNIQ_IDS distinct IDs were outstanding");
    // An identifier already outstanding is not blocked by A3.
    issue_read(2, 0, 2'b00, 300, acc, sq);
    if (!acc)
      tb_fail("A3", "a read with an ID already outstanding was refused while the table was full");
    else begin
      scratch[4] = sq;
      wait_mid(sq, 600);
    end
    // ... but only up to MAX_TXNS_PER_ID.
    issue_read(2, 0, 2'b00, 40, acc, sq);
    if (acc)
      tb_fail("A5", "a third transaction with one read ID was accepted (MAX_TXNS_PER_ID is 2)");

    // A4: offer a new identifier continuously across a retirement.
    ret_cyc_rd[1] = -1;
    fork
      begin
        issue_read(9, 0, 2'b00, 600, acc5, sq5);
      end
      begin
        repeat (4) @(posedge clk);
        respond_read(t_mid[scratch[0]]);   // retires read ID 1
      end
    join
    if (ret_cyc_rd[1] < 0)
      tb_fail("A1", "the read transaction for ID 1 never completed");
    else if (!acc5)
      tb_fail("A4", "a new read ID was never accepted after an identifier retired");
    else if (t_accc[sq5] < ret_cyc_rd[1])
      tb_fail("A3", "a new read ID was accepted before any identifier had retired");
    else begin
      delta = t_accc[sq5] - ret_cyc_rd[1];
      if (delta > 2)
        tb_fail("A4", $sformatf("a new read ID was accepted %0d cycles after retirement (limit is 2)", delta));
    end
    drain_all(600);
  endtask

  // The same boundary on the write side.
  task automatic t_write_table();
    automatic bit acc, acc5;
    automatic int sq, sq5, i, delta;
    for (i = 0; i < int'(MAX_UNIQ_IDS); i++) begin
      issue_write(i+5, 0, 2'b00, 300, acc, sq);
      if (!acc)
        tb_fail("A3", $sformatf("a write with a new ID was refused while only %0d distinct IDs were outstanding", i));
      scratch[i] = sq;
      if (acc) wait_mid(sq, 600);
    end
    issue_write(12, 0, 2'b00, 40, acc, sq);
    if (acc)
      tb_fail("A3", "a new write ID was accepted while MAX_UNIQ_IDS distinct IDs were outstanding");
    issue_write(6, 0, 2'b00, 300, acc, sq);
    if (!acc)
      tb_fail("A3", "a write with an ID already outstanding was refused while the table was full");
    else begin
      scratch[4] = sq;
      wait_mid(sq, 600);
    end
    issue_write(6, 0, 2'b00, 40, acc, sq);
    if (acc)
      tb_fail("A5", "a third transaction with one write ID was accepted (MAX_TXNS_PER_ID is 2)");

    ret_cyc_wr[5] = -1;
    fork
      begin
        issue_write(12, 0, 2'b00, 600, acc5, sq5);
      end
      begin
        repeat (4) @(posedge clk);
        respond_write(t_mid[scratch[0]]);  // retires write ID 5
      end
    join
    if (ret_cyc_wr[5] < 0)
      tb_fail("A1", "the write transaction for ID 5 never completed");
    else if (!acc5)
      tb_fail("A4", "a new write ID was never accepted after an identifier retired");
    else if (t_accc[sq5] < ret_cyc_wr[5])
      tb_fail("A3", "a new write ID was accepted before any identifier had retired");
    else begin
      delta = t_accc[sq5] - ret_cyc_wr[5];
      if (delta > 2)
        tb_fail("A4", $sformatf("a new write ID was accepted %0d cycles after retirement (limit is 2)", delta));
    end
    drain_all(600);
  endtask

  // A5 in both directions, including that the slot comes back.
  task automatic t_depth();
    automatic bit acc;
    automatic int sq, a, b;
    issue_read(6, 1, 2'b00, 300, acc, a);
    if (!acc) tb_fail("A3", "the first read with an ID was refused with an empty table");
    else wait_mid(a, 600);
    issue_read(6, 1, 2'b00, 300, acc, b);
    if (!acc) tb_fail("A5", "a second transaction with one read ID was refused (MAX_TXNS_PER_ID is 2)");
    else wait_mid(b, 600);
    issue_read(6, 1, 2'b00, 40, acc, sq);
    if (acc) tb_fail("A5", "a third transaction with one read ID was accepted");
    respond_read(t_mid[a]);
    wait_done(a, 600);
    issue_read(6, 1, 2'b00, 300, acc, sq);
    if (!acc) tb_fail("A5", "a read was still refused after a transaction with that ID had completed");
    drain_all(600);
  endtask

  // Mixed traffic: keeps the continuous A2/A3/A5/D1/B1/B3/C1/C2/E1 checks busy
  // with several identifiers in flight and responses taken in varying order
  // across different master identifiers (which B2 leaves free).
  task automatic t_random();
    automatic bit acc;
    automatic int sq, n, pick, sid, len, k, cand;
    automatic logic [1:0] rsp;
    for (n = 0; n < 90; n++) begin
      pick = $urandom_range(0, 9);
      sid  = $urandom_range(0, 6);
      len  = $urandom_range(0, 3);
      rsp  = $urandom_range(0, 3);
      if (pick < 3) begin
        issue_read(sid, len, rsp, 40, acc, sq);
      end else if (pick < 6) begin
        issue_write(sid, len, rsp, 40, acc, sq);
      end else if (pick < 8) begin
        k    = $urandom_range(0, NMID-1);
        cand = find_pending(1'b0, k);
        if (cand >= 0) respond_read(k);
        else @(posedge clk);
      end else begin
        k    = $urandom_range(0, NMID-1);
        cand = find_pending(1'b1, k);
        if (cand >= 0) respond_write(k);
        else @(posedge clk);
      end
    end
    drain_all(2000);
  endtask


  // A3/A4 turn on "retires completely": an identifier holding MAX_TXNS_PER_ID
  // transactions still occupies its entry when only one of them has finished.
  task automatic t_partial_retire();
    automatic bit acc, accn;
    automatic int sq, sqn, i, delta, a1, a2;
    issue_read(1, 0, 2'b00, 300, acc, a1);
    if (!acc) tb_fail("A3", "a read was refused with an empty identifier table");
    else wait_mid(a1, 600);
    issue_read(1, 0, 2'b00, 300, acc, a2);
    if (!acc) tb_fail("A5", "a second transaction with one read ID was refused (MAX_TXNS_PER_ID is 2)");
    else wait_mid(a2, 600);
    for (i = 2; i <= int'(MAX_UNIQ_IDS); i++) begin
      issue_read(i, 0, 2'b00, 300, acc, sq);
      if (!acc) tb_fail("A3", "a read with a new ID was refused while a table entry was still free");
      else wait_mid(sq, 600);
    end
    // One of ID 1's two transactions completes: ID 1 has NOT retired.
    respond_read(t_mid[a1]);
    wait_done(a1, 600);
    issue_read(9, 0, 2'b00, 40, acc, sq);
    if (acc)
      tb_fail("A3", "a new read ID was accepted although an outstanding identifier had not retired completely");
    // Now retire ID 1 completely; the new identifier must be taken within 2 cycles.
    ret_cyc_rd[1] = -1;
    fork
      begin
        issue_read(9, 0, 2'b00, 600, accn, sqn);
      end
      begin
        repeat (4) @(posedge clk);
        respond_read(t_mid[a2]);
      end
    join
    if (ret_cyc_rd[1] < 0)
      tb_fail("A1", "the last read transaction for ID 1 never completed");
    else if (!accn)
      tb_fail("A4", "a new read ID was never accepted after an identifier retired completely");
    else if (t_accc[sqn] < ret_cyc_rd[1])
      tb_fail("A3", "a new read ID was accepted before its identifier had retired completely");
    else begin
      delta = t_accc[sqn] - ret_cyc_rd[1];
      if (delta > 2)
        tb_fail("A4", $sformatf("a new read ID was accepted %0d cycles after complete retirement (limit is 2)", delta));
    end
    drain_all(600);
  endtask

  // F1.
  task automatic t_reset();
    automatic bit acc;
    automatic int sq, i;
    // Fill both tables so that a design which fails to clear them on reset has
    // no free entry left for the fresh identifiers used after the release.
    for (i = 0; i < int'(MAX_UNIQ_IDS); i++) issue_read (i+1, 1, 2'b00, 300, acc, sq);
    for (i = 0; i < int'(MAX_UNIQ_IDS); i++) issue_write(i+5, 1, 2'b00, 300, acc, sq);
    repeat (6) @(posedge clk);

    @(negedge clk);
    rst_n = 1'b0;
    for (i = 0; i < seq_ctr; i++) begin t_kill[i] = 1'b1; t_out[i] = 1'b0; end
    mpend_r = {}; mpend_w = {}; exp_r_q = {}; exp_b_q = {}; w_exp_q = {};
    for (i = 0; i < NSID; i++) begin cnt_rd[i] = 0; cnt_wr[i] = 0; end
    ndist_rd = 0; ndist_wr = 0;
    repeat (3) @(posedge clk);

    f1_rep_r = 1'b0; f1_rep_b = 1'b0;
    rst_chk  = 1'b1;
    issue_read(1, 0, 2'b00, 6, acc, sq);
    if (acc) tb_fail("F1", "a read request was accepted while rst_ni was low");
    repeat (3) @(posedge clk);
    rst_chk = 1'b0;

    @(negedge clk);
    rst_n = 1'b1;

    // Nothing outstanding before the reset may produce a response after it.
    f1_rep_r = 1'b0; f1_rep_b = 1'b0;
    quiet_chk = 1'b1;
    repeat (25) @(posedge clk);
    quiet_chk = 1'b0;

    // The tables are empty again. The identifiers used here were NOT used
    // before the reset, so a stale entry cannot be mistaken for a free one.
    for (i = 0; i < int'(MAX_UNIQ_IDS); i++) begin
      issue_read(i+9, 0, 2'b00, 300, acc, sq);
      if (!acc) tb_fail("F1", "the read identifier table was not empty after reset");
      else wait_mid(sq, 600);
    end
    // Drained before the write half: whether reads and writes share table
    // entries is left free (section 8, item 6), so this testbench never
    // requires MAX_UNIQ_IDS read AND MAX_UNIQ_IDS write IDs at the same time.
    drain_all(600);
    for (i = 0; i < int'(MAX_UNIQ_IDS); i++) begin
      issue_write((i+13) % 16, 0, 2'b00, 300, acc, sq);
      if (!acc) tb_fail("F1", "the write identifier table was not empty after reset");
      else wait_mid(sq, 600);
    end
    drain_all(600);
  endtask

  task automatic check_final();
    automatic int i;
    for (i = 0; i < seq_ctr; i++) begin
      if (t_acc[i] && !t_kill[i] && !t_mseen[i])
        tb_fail("D4", "an accepted slave transaction never produced a master transaction");
      if (t_mseen[i] && !t_acc[i] && !t_kill[i])
        tb_fail("D4", "a master transaction appeared for a request that was never accepted");
      if (t_acc[i] && !t_kill[i] && t_out[i])
        tb_fail("D4", "a transaction never received its response");
    end
    if (exp_r_q.size() != 0)
      tb_fail("D4", "read beats presented on the master port never reached the slave port");
    if (exp_b_q.size() != 0)
      tb_fail("D4", "write responses presented on the master port never reached the slave port");
    if (w_exp_q.size() != 0)
      tb_fail("B3", "write data beats were never forwarded to the master port");
  endtask

  // -------------------------------------------------------------------------
  // Main
  // -------------------------------------------------------------------------
  initial begin
    automatic int i;
    errors = 0; seq_ctr = 0; cyc = 0;
    ndist_rd = 0; ndist_wr = 0;
    rst_chk = 1'b0; quiet_chk = 1'b0; f1_rep_r = 1'b0; f1_rep_b = 1'b0;
    for (i = 0; i < NSID; i++) begin
      cnt_rd[i] = 0; cnt_wr[i] = 0;
      ret_cyc_rd[i] = -1; ret_cyc_wr[i] = -1;
    end
    for (i = 0; i < MAXT*MAXB; i++) begin r_sent[i] = 1'b0; r_seen[i] = 1'b0; end
    for (i = 0; i < MAXT; i++) begin
      t_acc[i] = 1'b0; t_out[i] = 1'b0; t_kill[i] = 1'b0;
      t_mseen[i] = 1'b0; t_hasm[i] = 1'b0; t_iswr[i] = 1'b0;
      t_sid[i] = -1; t_len[i] = 0; t_mid[i] = -1; t_wdone[i] = 1'b0;
    end

    s_awid = '0; s_awaddr = '0; s_awlen = '0; s_awvalid = 1'b0;
    s_wdata = '0; s_wstrb = '0; s_wlast = 1'b0; s_wvalid = 1'b0;
    s_arid = '0; s_araddr = '0; s_arlen = '0; s_arvalid = 1'b0;
    s_bready = 1'b1; s_rready = 1'b1;
    m_awready = 1'b1; m_wready = 1'b1; m_arready = 1'b1;
    m_bid = '0; m_bresp = 2'b00; m_bvalid = 1'b0;
    m_rid = '0; m_rdata = '0; m_rresp = 2'b00; m_rlast = 1'b0; m_rvalid = 1'b0;

    do_reset(5);
    repeat (2) @(posedge clk);

    t_basic();
    t_read_table();
    t_write_table();
    t_depth();
    t_partial_retire();
    t_random();
    t_reset();

    drain_all(600);
    check_final();
    repeat (5) @(posedge clk);
    finish_run();
  end

endmodule