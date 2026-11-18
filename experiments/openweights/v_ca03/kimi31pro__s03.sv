module id_width_conv_tb;

  localparam int unsigned SLV_ID_W        = 4;
  localparam int unsigned MST_ID_W        = 2;
  localparam int unsigned ADDR_W          = 32;
  localparam int unsigned DATA_W          = 32;
  localparam int unsigned MAX_UNIQ_IDS    = 4;
  localparam int unsigned MAX_TXNS_PER_ID = 2;
  localparam int unsigned WAIT_LIMIT      = 1000;

  logic clk;
  logic rst_n;

  logic [SLV_ID_W-1:0] s_awid;
  logic [ADDR_W-1:0]   s_awaddr;
  logic [7:0]          s_awlen;
  logic                s_awvalid;
  logic                s_awready;

  logic [DATA_W-1:0]   s_wdata;
  logic [DATA_W/8-1:0] s_wstrb;
  logic                s_wlast;
  logic                s_wvalid;
  logic                s_wready;

  logic [SLV_ID_W-1:0] s_bid;
  logic [1:0]          s_bresp;
  logic                s_bvalid;
  logic                s_bready;

  logic [SLV_ID_W-1:0] s_arid;
  logic [ADDR_W-1:0]   s_araddr;
  logic [7:0]          s_arlen;
  logic                s_arvalid;
  logic                s_arready;

  logic [SLV_ID_W-1:0] s_rid;
  logic [DATA_W-1:0]   s_rdata;
  logic [1:0]          s_rresp;
  logic                s_rlast;
  logic                s_rvalid;
  logic                s_rready;

  logic [MST_ID_W-1:0] m_awid;
  logic [ADDR_W-1:0]   m_awaddr;
  logic [7:0]          m_awlen;
  logic                m_awvalid;
  logic                m_awready;

  logic [DATA_W-1:0]   m_wdata;
  logic [DATA_W/8-1:0] m_wstrb;
  logic                m_wlast;
  logic                m_wvalid;
  logic                m_wready;

  logic [MST_ID_W-1:0] m_bid;
  logic [1:0]          m_bresp;
  logic                m_bvalid;
  logic                m_bready;

  logic [MST_ID_W-1:0] m_arid;
  logic [ADDR_W-1:0]   m_araddr;
  logic [7:0]          m_arlen;
  logic                m_arvalid;
  logic                m_arready;

  logic [MST_ID_W-1:0] m_rid;
  logic [DATA_W-1:0]   m_rdata;
  logic [1:0]          m_rresp;
  logic                m_rlast;
  logic                m_rvalid;
  logic                m_rready;

  id_width_conv #(
      .SLV_ID_W        (SLV_ID_W),
      .MST_ID_W        (MST_ID_W),
      .ADDR_W          (ADDR_W),
      .DATA_W          (DATA_W),
      .MAX_UNIQ_IDS    (MAX_UNIQ_IDS),
      .MAX_TXNS_PER_ID (MAX_TXNS_PER_ID)
  ) dut (
      .clk_i     (clk),
      .rst_ni    (rst_n),

      .s_awid    (s_awid),
      .s_awaddr  (s_awaddr),
      .s_awlen   (s_awlen),
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
      .m_arvalid (m_arvalid),
      .m_arready (m_arready),

      .m_rid     (m_rid),
      .m_rdata   (m_rdata),
      .m_rresp   (m_rresp),
      .m_rlast   (m_rlast),
      .m_rvalid  (m_rvalid),
      .m_rready  (m_rready)
  );

  // -------------------------------------------------------------------------
  // Provided plumbing
  // -------------------------------------------------------------------------

  initial begin clk = 1'b0; forever #5 clk = ~clk; end

  initial rst_n = 1'b0;

  task automatic bfm_reset(input int cycles = 4);
    @(negedge clk);
    rst_n = 1'b0;
    repeat (cycles) @(posedge clk);
    @(negedge clk);
    rst_n = 1'b1;
  endtask

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

  task automatic bfm_w(input logic [DATA_W-1:0]   data,
                       input logic [DATA_W/8-1:0] strb,
                       input logic                last);
    @(negedge clk);
    s_wdata = data; s_wstrb = strb; s_wlast = last; s_wvalid = 1'b1;
    forever begin @(posedge clk); if (s_wready) break; end
    @(negedge clk) s_wvalid = 1'b0;
  endtask

  task automatic bfm_rbeat(input logic [MST_ID_W-1:0] mid,
                           input logic [DATA_W-1:0]   data,
                           input logic                last);
    @(negedge clk);
    m_rid = mid; m_rdata = data; m_rlast = last; m_rresp = 2'b00; m_rvalid = 1'b1;
    forever begin @(posedge clk); if (m_rready) break; end
    @(negedge clk) m_rvalid = 1'b0;
  endtask

  task automatic bfm_bbeat(input logic [MST_ID_W-1:0] mid);
    @(negedge clk);
    m_bid = mid; m_bresp = 2'b00; m_bvalid = 1'b1;
    forever begin @(posedge clk); if (m_bready) break; end
    @(negedge clk) m_bvalid = 1'b0;
  endtask

  initial begin
    #4_000_000;
    $display("G1: watchdog expired; no forward progress");
    $display("RESULT: FAIL");
    $finish;
  end

  // Variant of the read-response BFM which also exercises RRESP forwarding.
  task automatic bfm_rbeat_full(input logic [MST_ID_W-1:0] mid,
                                input logic [DATA_W-1:0]   data,
                                input logic [1:0]          resp,
                                input logic                last);
    @(negedge clk);
    m_rid = mid;
    m_rdata = data;
    m_rresp = resp;
    m_rlast = last;
    m_rvalid = 1'b1;
    forever begin @(posedge clk); if (m_rready) break; end
    @(negedge clk) m_rvalid = 1'b0;
  endtask

  // -------------------------------------------------------------------------
  // Transaction model
  // -------------------------------------------------------------------------

  typedef struct {
    logic [SLV_ID_W-1:0] sid;
    logic [ADDR_W-1:0]   addr;
    logic [7:0]          len;
    logic [MST_ID_W-1:0] mid;
    bit                  m_seen;
    bit                  done;
    bit                  b_sent;
    int                  accept_cycle;
    int                  retire_cycle;
    int                  tag;
    int                  r_sent;
    int                  r_seen;
    int                  w_sbeats;
    int                  w_mbeats;
  } txn_t;

  typedef struct {
    int                  txn;
    logic [SLV_ID_W-1:0] sid;
    logic [DATA_W-1:0]   data;
    logic [1:0]          resp;
    logic                last;
  } r_exp_t;

  typedef struct {
    int                  txn;
    logic [DATA_W-1:0]   data;
    logic [DATA_W/8-1:0] strb;
    logic                last;
  } w_exp_t;

  txn_t   rd_txns[$];
  txn_t   wr_txns[$];
  r_exp_t r_exp_q[$];
  w_exp_t w_exp_q[$];

  int  cycle;
  int  errors;
  bit  discard_window;

  task automatic note_fail(input string code, input string msg);
    errors = errors + 1;
    $display("%s: %s", code, msg);
  endtask

  task automatic die(input string code, input string msg);
    note_fail(code, msg);
    $display("RESULT: FAIL");
    $finish;
  endtask

  function automatic int rd_sid_count(input logic [SLV_ID_W-1:0] sid);
    int n;
    int i;
    n = 0;
    for (i = 0; i < rd_txns.size(); i++) begin
      if (!rd_txns[i].done && rd_txns[i].sid == sid)
        n = n + 1;
    end
    rd_sid_count = n;
  endfunction

  function automatic int wr_sid_count(input logic [SLV_ID_W-1:0] sid);
    int n;
    int i;
    n = 0;
    for (i = 0; i < wr_txns.size(); i++) begin
      if (!wr_txns[i].done && wr_txns[i].sid == sid)
        n = n + 1;
    end
    wr_sid_count = n;
  endfunction

  function automatic int rd_distinct_count();
    int n;
    int i;
    int j;
    bit seen;
    n = 0;
    for (i = 0; i < rd_txns.size(); i++) begin
      if (!rd_txns[i].done) begin
        seen = 1'b0;
        for (j = 0; j < i; j++) begin
          if (!rd_txns[j].done && rd_txns[j].sid == rd_txns[i].sid)
            seen = 1'b1;
        end
        if (!seen)
          n = n + 1;
      end
    end
    rd_distinct_count = n;
  endfunction

  function automatic int wr_distinct_count();
    int n;
    int i;
    int j;
    bit seen;
    n = 0;
    for (i = 0; i < wr_txns.size(); i++) begin
      if (!wr_txns[i].done) begin
        seen = 1'b0;
        for (j = 0; j < i; j++) begin
          if (!wr_txns[j].done && wr_txns[j].sid == wr_txns[i].sid)
            seen = 1'b1;
        end
        if (!seen)
          n = n + 1;
      end
    end
    wr_distinct_count = n;
  endfunction

  function automatic int rd_oldest_sid(input logic [SLV_ID_W-1:0] sid);
    int i;
    int found;
    found = -1;
    for (i = 0; i < rd_txns.size(); i++) begin
      if (found < 0 && !rd_txns[i].done && rd_txns[i].sid == sid)
        found = i;
    end
    rd_oldest_sid = found;
  endfunction

  function automatic int wr_oldest_sid(input logic [SLV_ID_W-1:0] sid);
    int i;
    int found;
    found = -1;
    for (i = 0; i < wr_txns.size(); i++) begin
      if (found < 0 && !wr_txns[i].done && wr_txns[i].sid == sid)
        found = i;
    end
    wr_oldest_sid = found;
  endfunction

  function automatic logic [ADDR_W-1:0] addr_for(input int n);
    addr_for = 32'h0000_1000 + n * 32'h0000_0040;
  endfunction

  function automatic logic [DATA_W-1:0] make_rd_data(input int tag,
                                                      input int beat);
    make_rd_data = 32'ha000_0000 + tag * 32'h0000_0100 + beat;
  endfunction

  function automatic logic [DATA_W-1:0] make_wr_data(input int tag,
                                                      input int beat);
    make_wr_data = 32'h5000_0000 + tag * 32'h0000_0100 + beat;
  endfunction

  function automatic logic [DATA_W/8-1:0] make_wstrb(input int tag,
                                                      input int beat);
    logic [DATA_W/8-1:0] v;
    v = {DATA_W/8{1'b1}};
    v = v ^ ((tag + beat) & 3);
    make_wstrb = v;
  endfunction

  // -------------------------------------------------------------------------
  // Monitor operations. Completions are processed before new acceptances so
  // that retirement and reuse on the same rising edge are treated as legal.
  // -------------------------------------------------------------------------

  task automatic mon_s_ar;
    automatic txn_t nt;
    automatic int sc;
    automatic int dc;
    sc = rd_sid_count(s_arid);
    dc = rd_distinct_count();

    if (sc >= MAX_TXNS_PER_ID)
      note_fail("A5", $sformatf("accepted a third outstanding read for slave id %0d", s_arid));
    else if (sc == 0 && dc >= MAX_UNIQ_IDS)
      note_fail("A3", $sformatf("accepted new read id %0d while %0d ids were outstanding", s_arid, dc));

    nt.sid          = s_arid;
    nt.addr         = s_araddr;
    nt.len          = s_arlen;
    nt.mid          = '0;
    nt.m_seen       = 1'b0;
    nt.done         = 1'b0;
    nt.b_sent       = 1'b0;
    nt.accept_cycle = cycle;
    nt.retire_cycle = -1;
    nt.tag          = rd_txns.size() + 1;
    nt.r_sent       = 0;
    nt.r_seen       = 0;
    nt.w_sbeats     = 0;
    nt.w_mbeats     = 0;
    rd_txns.push_back(nt);
  endtask

  task automatic mon_s_aw;
    automatic txn_t nt;
    automatic int sc;
    automatic int dc;
    sc = wr_sid_count(s_awid);
    dc = wr_distinct_count();

    if (sc >= MAX_TXNS_PER_ID)
      note_fail("A5", $sformatf("accepted a third outstanding write for slave id %0d", s_awid));
    else if (sc == 0 && dc >= MAX_UNIQ_IDS)
      note_fail("A3", $sformatf("accepted new write id %0d while %0d ids were outstanding", s_awid, dc));

    nt.sid          = s_awid;
    nt.addr         = s_awaddr;
    nt.len          = s_awlen;
    nt.mid          = '0;
    nt.m_seen       = 1'b0;
    nt.done         = 1'b0;
    nt.b_sent       = 1'b0;
    nt.accept_cycle = cycle;
    nt.retire_cycle = -1;
    nt.tag          = wr_txns.size() + 1;
    nt.r_sent       = 0;
    nt.r_seen       = 0;
    nt.w_sbeats     = 0;
    nt.w_mbeats     = 0;
    wr_txns.push_back(nt);
  endtask

  task automatic mon_m_ar;
    automatic int i;
    automatic int idx;
    idx = -1;

    // Addresses in the stimulus are unique, so association remains
    // unambiguous without imposing an order on master address requests.
    for (i = 0; i < rd_txns.size(); i++) begin
      if (idx < 0 && !rd_txns[i].done && !rd_txns[i].m_seen &&
          rd_txns[i].addr == m_araddr)
        idx = i;
    end

    if (idx < 0) begin
      for (i = 0; i < rd_txns.size(); i++) begin
        if (idx < 0 && !rd_txns[i].done && !rd_txns[i].m_seen)
          idx = i;
      end
      if (idx >= 0)
        note_fail("E1", $sformatf("master AR addr %08x does not match an accepted slave AR", m_araddr));
      else
        note_fail("D4", $sformatf("unexpected or duplicate master AR addr %08x", m_araddr));
    end

    if (idx >= 0) begin
      if (rd_txns[idx].len != m_arlen)
        note_fail("E1", $sformatf("AR len changed from %0d to %0d",
                                  rd_txns[idx].len, m_arlen));

      for (i = 0; i < rd_txns.size(); i++) begin
        if (i != idx && !rd_txns[i].done && rd_txns[i].m_seen &&
            rd_txns[i].sid != rd_txns[idx].sid &&
            rd_txns[i].mid == m_arid)
          note_fail("D1/D2", $sformatf(
              "master read id %0d shared by co-outstanding slave ids %0d and %0d",
              m_arid, rd_txns[i].sid, rd_txns[idx].sid));
      end

      rd_txns[idx].mid    = m_arid;
      rd_txns[idx].m_seen = 1'b1;
    end
  endtask

  task automatic mon_m_aw;
    automatic int i;
    automatic int idx;
    idx = -1;

    for (i = 0; i < wr_txns.size(); i++) begin
      if (idx < 0 && !wr_txns[i].done && !wr_txns[i].m_seen &&
          wr_txns[i].addr == m_awaddr)
        idx = i;
    end

    if (idx < 0) begin
      for (i = 0; i < wr_txns.size(); i++) begin
        if (idx < 0 && !wr_txns[i].done && !wr_txns[i].m_seen)
          idx = i;
      end
      if (idx >= 0)
        note_fail("E1", $sformatf("master AW addr %08x does not match an accepted slave AW", m_awaddr));
      else
        note_fail("D4", $sformatf("unexpected or duplicate master AW addr %08x", m_awaddr));
    end

    if (idx >= 0) begin
      if (wr_txns[idx].len != m_awlen)
        note_fail("E1", $sformatf("AW len changed from %0d to %0d",
                                  wr_txns[idx].len, m_awlen));

      for (i = 0; i < wr_txns.size(); i++) begin
        if (i != idx && !wr_txns[i].done && wr_txns[i].m_seen &&
            wr_txns[i].sid != wr_txns[idx].sid &&
            wr_txns[i].mid == m_awid)
          note_fail("D1/D2", $sformatf(
              "master write id %0d shared by co-outstanding slave ids %0d and %0d",
              m_awid, wr_txns[i].sid, wr_txns[idx].sid));
      end

      wr_txns[idx].mid    = m_awid;
      wr_txns[idx].m_seen = 1'b1;
    end
  endtask

  task automatic mon_s_w;
    automatic w_exp_t we;
    automatic int i;
    automatic int idx;
    idx = -1;

    // AXI4 write data follows slave address acceptance order.
    for (i = 0; i < wr_txns.size(); i++) begin
      if (idx < 0 && wr_txns[i].w_sbeats < wr_txns[i].len + 1)
        idx = i;
    end

    if (idx < 0) begin
      note_fail("E1", "slave W beat has no corresponding write transaction");
    end else begin
      we.txn  = idx;
      we.data = s_wdata;
      we.strb = s_wstrb;
      we.last = s_wlast;
      w_exp_q.push_back(we);
      wr_txns[idx].w_sbeats = wr_txns[idx].w_sbeats + 1;
    end
  endtask

  task automatic mon_m_w;
    automatic w_exp_t we;
    if (w_exp_q.size() == 0) begin
      note_fail("D4", "master W beat has no corresponding slave W beat");
    end else begin
      we = w_exp_q.pop_front();
      if (m_wdata !== we.data)
        note_fail("E1/B3", $sformatf("W data changed or reordered: expected %08x, got %08x",
                                     we.data, m_wdata));
      if (m_wstrb !== we.strb)
        note_fail("E1", $sformatf("W strb changed: expected %x, got %x",
                                  we.strb, m_wstrb));
      if (m_wlast !== we.last)
        note_fail("E1/B3", $sformatf("W last changed or beats were interleaved: expected %0b, got %0b",
                                     we.last, m_wlast));
      wr_txns[we.txn].w_mbeats = wr_txns[we.txn].w_mbeats + 1;
    end
  endtask

  task automatic mon_s_r;
    automatic int oldest;
    automatic int i;
    automatic int idx;
    automatic int other;
    automatic r_exp_t re;

    oldest = rd_oldest_sid(s_rid);
    if (oldest < 0) begin
      note_fail("C2", $sformatf("read response for slave id %0d has no outstanding transaction", s_rid));
      if (discard_window)
        note_fail("F1", "a transaction outstanding across reset produced a read response");
    end else begin
      idx = -1;
      for (i = 0; i < r_exp_q.size(); i++) begin
        if (idx < 0 && r_exp_q[i].txn == oldest)
          idx = i;
      end

      if (idx < 0) begin
        other = -1;
        for (i = 0; i < r_exp_q.size(); i++) begin
          if (other < 0 && r_exp_q[i].sid == s_rid)
            other = i;
        end
        if (other >= 0)
          note_fail("E1/B1", "same-id read responses returned out of address order");
        else
          note_fail("D4", $sformatf("read response for id %0d has no downstream response", s_rid));
      end else begin
        re = r_exp_q[idx];
        r_exp_q.delete(idx);

        if (s_rdata !== re.data)
          note_fail("E1", $sformatf("R data changed: expected %08x, got %08x",
                                    re.data, s_rdata));
        if (s_rresp !== re.resp)
          note_fail("E1", $sformatf("R resp changed: expected %0b, got %0b",
                                    re.resp, s_rresp));
        if (s_rlast !== re.last)
          note_fail("E1", $sformatf("R last changed: expected %0b, got %0b",
                                    re.last, s_rlast));

        rd_txns[oldest].r_seen = rd_txns[oldest].r_seen + 1;
        if (s_rlast) begin
          if (rd_txns[oldest].r_seen != rd_txns[oldest].len + 1)
            note_fail("E1", "read retired with the wrong number of data beats");
          rd_txns[oldest].done = 1'b1;
          rd_txns[oldest].retire_cycle = cycle;
        end else if (rd_txns[oldest].r_seen >= rd_txns[oldest].len + 1) begin
          note_fail("E1", "too many non-last read data beats");
        end
      end
    end
  endtask

  task automatic mon_s_b;
    automatic int oldest;
    automatic int i;
    automatic bit younger_sent;

    oldest = wr_oldest_sid(s_bid);
    if (oldest < 0) begin
      note_fail("C2", $sformatf("write response for slave id %0d has no outstanding transaction", s_bid));
      if (discard_window)
        note_fail("F1", "a transaction outstanding across reset produced a write response");
    end else if (!wr_txns[oldest].b_sent) begin
      younger_sent = 1'b0;
      for (i = 0; i < wr_txns.size(); i++) begin
        if (!wr_txns[i].done && wr_txns[i].sid == s_bid && wr_txns[i].b_sent)
          younger_sent = 1'b1;
      end
      if (younger_sent)
        note_fail("E1/B1", "same-id write responses returned out of address order");
      else
        note_fail("D4", "slave B response arrived without a downstream B response");
    end else begin
      wr_txns[oldest].done = 1'b1;
      wr_txns[oldest].retire_cycle = cycle;
    end
  endtask

  always @(posedge clk) begin
    cycle = cycle + 1;
    if (!rst_n) begin
      if (s_bvalid)
        note_fail("F1", "s_bvalid was high while reset was asserted");
      if (s_rvalid)
        note_fail("F1", "s_rvalid was high while reset was asserted");

      // Handshakes during reset are legal, but everything associated with
      // them is discarded from the model.
      rd_txns.delete();
      wr_txns.delete();
      r_exp_q.delete();
      w_exp_q.delete();
    end else begin
      if (s_rvalid && s_rready) mon_s_r();
      if (s_bvalid && s_bready) mon_s_b();

      if (s_arvalid && s_arready) mon_s_ar();
      if (s_awvalid && s_awready) mon_s_aw();
      if (s_wvalid && s_wready)   mon_s_w();

      if (m_arvalid && m_arready) mon_m_ar();
      if (m_awvalid && m_awready) mon_m_aw();
      if (m_wvalid && m_wready)   mon_m_w();
    end
  end

  // -------------------------------------------------------------------------
  // Stimulus helpers
  // -------------------------------------------------------------------------

  task automatic req_ar(input logic [SLV_ID_W-1:0] id,
                        input logic [ADDR_W-1:0]   addr,
                        input logic [7:0]          len,
                        input int                  budget,
                        input bit                  expect_accept,
                        input string               code,
                        output int                 idx);
    automatic bit accepted;
    automatic int waited;
    automatic int before;
    before = rd_txns.size();
    idx = -1;
    bfm_ar(id, addr, len, budget, accepted, waited);

    if (accepted) begin
      if (rd_txns.size() <= before)
        die("A1", "accepted read handshake was not recorded");
      idx = before;
      if (!expect_accept)
        die(code, $sformatf("read id %0d was accepted although it had to remain blocked", id));
    end else if (expect_accept) begin
      die(code, $sformatf("read id %0d was not accepted within %0d cycles", id, budget));
    end
  endtask

  task automatic req_aw(input logic [SLV_ID_W-1:0] id,
                        input logic [ADDR_W-1:0]   addr,
                        input logic [7:0]          len,
                        input int                  budget,
                        input bit                  expect_accept,
                        input string               code,
                        output int                 idx);
    automatic bit accepted;
    automatic int waited;
    automatic int before;
    before = wr_txns.size();
    idx = -1;
    bfm_aw(id, addr, len, budget, accepted, waited);

    if (accepted) begin
      if (wr_txns.size() <= before)
        die("A1", "accepted write handshake was not recorded");
      idx = before;
      if (!expect_accept)
        die(code, $sformatf("write id %0d was accepted although it had to remain blocked", id));
    end else if (expect_accept) begin
      die(code, $sformatf("write id %0d was not accepted within %0d cycles", id, budget));
    end
  endtask

  task automatic need_rd_mid(input int idx);
    automatic int k;
    automatic bit ok;
    k = 0;
    ok = 1'b0;
    while (k < WAIT_LIMIT && !ok) begin
      if (rd_txns[idx].m_seen)
        ok = 1'b1;
      else begin
        @(negedge clk);
        k = k + 1;
      end
    end
    if (!ok)
      die("D4", $sformatf("accepted read %0d never produced a master AR", idx));
  endtask

  task automatic need_wr_mid(input int idx);
    automatic int k;
    automatic bit ok;
    k = 0;
    ok = 1'b0;
    while (k < WAIT_LIMIT && !ok) begin
      if (wr_txns[idx].m_seen)
        ok = 1'b1;
      else begin
        @(negedge clk);
        k = k + 1;
      end
    end
    if (!ok)
      die("D4", $sformatf("accepted write %0d never produced a master AW", idx));
  endtask

  task automatic need_rd_done(input int idx);
    automatic int k;
    automatic bit ok;
    k = 0;
    ok = 1'b0;
    while (k < WAIT_LIMIT && !ok) begin
      if (rd_txns[idx].done)
        ok = 1'b1;
      else begin
        @(negedge clk);
        k = k + 1;
      end
    end
    if (!ok)
      die("D4", $sformatf("master read response %0d produced no complete slave response", idx));
  endtask

  task automatic need_wr_done(input int idx);
    automatic int k;
    automatic bit ok;
    k = 0;
    ok = 1'b0;
    while (k < WAIT_LIMIT && !ok) begin
      if (wr_txns[idx].done)
        ok = 1'b1;
      else begin
        @(negedge clk);
        k = k + 1;
      end
    end
    if (!ok)
      die("D4", $sformatf("master write response %0d produced no slave B response", idx));
  endtask

  task automatic need_wr_data(input int idx);
    automatic int k;
    automatic bit ok;
    k = 0;
    ok = 1'b0;
    while (k < WAIT_LIMIT && !ok) begin
      if (wr_txns[idx].w_mbeats == wr_txns[idx].len + 1)
        ok = 1'b1;
      else begin
        @(negedge clk);
        k = k + 1;
      end
    end
    if (!ok)
      die("D4", $sformatf("write %0d did not forward all of its W beats", idx));
  endtask

  task automatic send_read_txn(input int idx);
    automatic int b;
    automatic r_exp_t re;
    automatic logic [DATA_W-1:0] d;
    automatic logic [1:0] resp;
    automatic logic [MST_ID_W-1:0] mid;

    mid = rd_txns[idx].mid;
    for (b = 0; b < rd_txns[idx].len + 1; b++) begin
      d = make_rd_data(rd_txns[idx].tag, b);
      resp = (rd_txns[idx].tag + b) & 3;

      re.txn  = idx;
      re.sid  = rd_txns[idx].sid;
      re.data = d;
      re.resp = resp;
      re.last = (b == rd_txns[idx].len);
      r_exp_q.push_back(re);
      rd_txns[idx].r_sent = rd_txns[idx].r_sent + 1;

      bfm_rbeat_full(mid, d, resp, b == rd_txns[idx].len);
    end
  endtask

  task automatic send_w_txn(input int idx);
    automatic int b;
    for (b = 0; b < wr_txns[idx].len + 1; b++) begin
      bfm_w(make_wr_data(wr_txns[idx].tag, b),
            make_wstrb(wr_txns[idx].tag, b),
            b == wr_txns[idx].len);
    end
  endtask

  task automatic send_b_txn(input int idx);
    wr_txns[idx].b_sent = 1'b1;
    bfm_bbeat(wr_txns[idx].mid);
  endtask

  // -------------------------------------------------------------------------
  // Directed test
  // -------------------------------------------------------------------------

  initial begin : main_test
    automatic int r_old;
    automatic int w_old;
    automatic int r1;
    automatic int r2;
    automatic int r3;
    automatic int r4;
    automatic int r1b;
    automatic int r5;
    automatic int w7;
    automatic int w6;
    automatic int w8;
    automatic int w9;
    automatic int w6b;
    automatic int w10;
    automatic int dummy_idx;
    automatic bit reset_ar_accepted;
    automatic bit reset_aw_accepted;
    automatic int reset_ar_waited;
    automatic int reset_aw_waited;
    automatic logic [MST_ID_W-1:0] old_rmid;
    automatic logic [MST_ID_W-1:0] old_wmid;
    automatic logic [DATA_W-1:0] old_rdata;

    errors = 0;
    cycle = 0;
    discard_window = 1'b0;

    s_awid = '0;
    s_awaddr = '0;
    s_awlen = '0;
    s_awvalid = 1'b0;
    s_wdata = '0;
    s_wstrb = '0;
    s_wlast = 1'b0;
    s_wvalid = 1'b0;
    s_bready = 1'b1;

    s_arid = '0;
    s_araddr = '0;
    s_arlen = '0;
    s_arvalid = 1'b0;
    s_rready = 1'b1;

    m_awready = 1'b1;
    m_wready = 1'b1;
    m_arready = 1'b1;

    m_bid = '0;
    m_bresp = '0;
    m_bvalid = 1'b0;
    m_rid = '0;
    m_rdata = '0;
    m_rresp = '0;
    m_rlast = 1'b0;
    m_rvalid = 1'b0;

    bfm_reset(4);

    // Establish one outstanding transaction in each direction, then reset.
    req_ar(4'd12, addr_for(1), 8'd0, WAIT_LIMIT, 1'b1, "A3", r_old);
    req_aw(4'd13, addr_for(2), 8'd0, WAIT_LIMIT, 1'b1, "A3", w_old);
    send_w_txn(w_old);
    need_rd_mid(r_old);
    need_wr_mid(w_old);
    need_wr_data(w_old);

    old_rmid = rd_txns[r_old].mid;
    old_wmid = wr_txns[w_old].mid;
    old_rdata = make_rd_data(rd_txns[r_old].tag, 0);

    // Offer traffic during reset without requiring ready to take either value.
    @(negedge clk);
    rst_n = 1'b0;
    fork
      bfm_ar(4'd14, addr_for(3), 8'd0, 4,
             reset_ar_accepted, reset_ar_waited);
      bfm_aw(4'd15, addr_for(4), 8'd0, 4,
             reset_aw_accepted, reset_aw_waited);
      begin
        @(negedge clk);
        s_wdata = 32'hdead_beef;
        s_wstrb = 4'hf;
        s_wlast = 1'b1;
        s_wvalid = 1'b1;
        repeat (3) @(posedge clk);
        @(negedge clk);
        s_wvalid = 1'b0;
      end
      begin
        repeat (6) @(posedge clk);
        @(negedge clk);
        rst_n = 1'b1;
      end
    join

    // Return the pre-reset downstream responses after reset. A correct DUT
    // either ignores them or accepts and discards them; neither may produce a
    // slave response. Valid is time-bounded so an empty DUT cannot hang the TB.
    discard_window = 1'b1;
    repeat (2) @(negedge clk);
    fork
      begin
        @(negedge clk);
        m_rid = old_rmid;
        m_rdata = old_rdata;
        m_rresp = 2'b00;
        m_rlast = 1'b1;
        m_rvalid = 1'b1;
        repeat (3) @(posedge clk);
        @(negedge clk);
        m_rvalid = 1'b0;
      end
      begin
        @(negedge clk);
        m_bid = old_wmid;
        m_bresp = 2'b00;
        m_bvalid = 1'b1;
        repeat (3) @(posedge clk);
        @(negedge clk);
        m_bvalid = 1'b0;
      end
    join
    repeat (4) @(negedge clk);
    discard_window = 1'b0;

    if (errors != 0) begin
      $display("RESULT: FAIL");
      $finish;
    end

    // ------------------------- read-side A3/A5 -----------------------------
    req_ar(4'd1, addr_for(10), 8'd0, WAIT_LIMIT, 1'b1, "A3", r1);
    req_ar(4'd2, addr_for(11), 8'd0, WAIT_LIMIT, 1'b1, "A3", r2);
    req_ar(4'd3, addr_for(12), 8'd0, WAIT_LIMIT, 1'b1, "A3", r3);

    // Three distinct ids are outstanding: the fourth new id must be accepted.
    req_ar(4'd4, addr_for(13), 8'd0, WAIT_LIMIT, 1'b1, "A3", r4);

    // A full table does not block an already-outstanding id. This second read
    // is two beats long to exercise RDATA/RRESP/RLAST on every beat.
    req_ar(4'd1, addr_for(14), 8'd1, WAIT_LIMIT, 1'b1, "A3", r1b);

    need_rd_mid(r1);
    need_rd_mid(r2);
    need_rd_mid(r3);
    need_rd_mid(r4);
    need_rd_mid(r1b);

    // Neither a third transaction for id 1 nor a fifth distinct id may go.
    req_ar(4'd1, addr_for(15), 8'd0, 6, 1'b0, "A5", dummy_idx);
    req_ar(4'd5, addr_for(16), 8'd0, 6, 1'b0, "A3", dummy_idx);

    // Keep id 5 offered across retirement of id 2. Acceptance on the retiring
    // edge or either of the following two edges satisfies A4.
    fork
      req_ar(4'd5, addr_for(17), 8'd0, WAIT_LIMIT, 1'b1, "A4", r5);
      begin
        repeat (2) @(negedge clk);
        send_read_txn(r2);
      end
    join
    need_rd_done(r2);

    if (rd_txns[r5].accept_cycle < rd_txns[r2].retire_cycle)
      die("A3", "new read id was accepted before an entry retired");
    if (rd_txns[r5].accept_cycle - rd_txns[r2].retire_cycle > 2)
      die("A4", $sformatf("new read id accepted %0d cycles after retirement",
                          rd_txns[r5].accept_cycle - rd_txns[r2].retire_cycle));

    need_rd_mid(r5);

    // Different-id responses are deliberately returned in an order unrelated
    // to address order. Same-id responses remain in address order.
    send_read_txn(r5);
    need_rd_done(r5);
    send_read_txn(r4);
    need_rd_done(r4);
    send_read_txn(r3);
    need_rd_done(r3);
    send_read_txn(r1);
    need_rd_done(r1);
    send_read_txn(r1b);
    need_rd_done(r1b);

    // ------------------------- write-side A3/A5 ----------------------------
    req_aw(4'd7, addr_for(30), 8'd0, WAIT_LIMIT, 1'b1, "A3", w7);
    req_aw(4'd6, addr_for(31), 8'd0, WAIT_LIMIT, 1'b1, "A3", w6);
    req_aw(4'd8, addr_for(32), 8'd0, WAIT_LIMIT, 1'b1, "A3", w8);

    // Boundary: three distinct ids already outstanding.
    req_aw(4'd9, addr_for(33), 8'd0, WAIT_LIMIT, 1'b1, "A3", w9);

    // Existing id is not blocked by A3. Two beats exercise non-interleaving.
    req_aw(4'd6, addr_for(34), 8'd1, WAIT_LIMIT, 1'b1, "A3", w6b);

    req_aw(4'd6, addr_for(35), 8'd0, 6, 1'b0, "A5", dummy_idx);
    req_aw(4'd10, addr_for(36), 8'd0, 6, 1'b0, "A3", dummy_idx);

    // Retire id 7 while id 10 is continuously offered.
    fork
      req_aw(4'd10, addr_for(37), 8'd0, WAIT_LIMIT, 1'b1, "A4", w10);
      begin
        repeat (2) @(negedge clk);
        send_w_txn(w7);
        need_wr_mid(w7);
        need_wr_data(w7);
        send_b_txn(w7);
      end
    join
    need_wr_done(w7);

    if (wr_txns[w10].accept_cycle < wr_txns[w7].retire_cycle)
      die("A3", "new write id was accepted before an entry retired");
    if (wr_txns[w10].accept_cycle - wr_txns[w7].retire_cycle > 2)
      die("A4", $sformatf("new write id accepted %0d cycles after retirement",
                          wr_txns[w10].accept_cycle - wr_txns[w7].retire_cycle));

    // Supply all remaining W data in slave AW acceptance order.
    send_w_txn(w6);
    send_w_txn(w8);
    send_w_txn(w9);
    send_w_txn(w6b);
    send_w_txn(w10);

    need_wr_mid(w6);
    need_wr_mid(w8);
    need_wr_mid(w9);
    need_wr_mid(w6b);
    need_wr_mid(w10);

    need_wr_data(w6);
    need_wr_data(w8);
    need_wr_data(w9);
    need_wr_data(w6b);
    need_wr_data(w10);

    // Different ids complete out of order; id 6 retains its per-id order.
    send_b_txn(w10);
    need_wr_done(w10);
    send_b_txn(w9);
    need_wr_done(w9);
    send_b_txn(w8);
    need_wr_done(w8);
    send_b_txn(w6);
    need_wr_done(w6);
    send_b_txn(w6b);
    need_wr_done(w6b);

    repeat (4) @(negedge clk);

    if (rd_distinct_count() != 0 || wr_distinct_count() != 0)
      note_fail("D4", "not all accepted transactions produced complete responses");
    if (r_exp_q.size() != 0 || w_exp_q.size() != 0)
      note_fail("D4", "expected response or write-data beats were not forwarded");

    if (errors == 0)
      $display("RESULT: PASS");
    else
      $display("RESULT: FAIL");
    $finish;
  end

endmodule
