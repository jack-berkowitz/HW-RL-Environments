module id_width_conv_tb;

  localparam int unsigned SLV_ID_W        = 4;
  localparam int unsigned MST_ID_W        = 2;
  localparam int unsigned ADDR_W          = 32;
  localparam int unsigned DATA_W          = 32;
  localparam int unsigned MAX_UNIQ_IDS    = 4;
  localparam int unsigned MAX_TXNS_PER_ID = 2;

  logic                    clk_i;
  logic                    rst_ni;

  logic [SLV_ID_W-1:0]     s_awid;
  logic [ADDR_W-1:0]       s_awaddr;
  logic [7:0]              s_awlen;
  logic                    s_awvalid;
  logic                    s_awready;

  logic [DATA_W-1:0]       s_wdata;
  logic [DATA_W/8-1:0]     s_wstrb;
  logic                    s_wlast;
  logic                    s_wvalid;
  logic                    s_wready;

  logic [SLV_ID_W-1:0]     s_bid;
  logic [1:0]              s_bresp;
  logic                    s_bvalid;
  logic                    s_bready;

  logic [SLV_ID_W-1:0]     s_arid;
  logic [ADDR_W-1:0]       s_araddr;
  logic [7:0]              s_arlen;
  logic                    s_arvalid;
  logic                    s_arready;

  logic [SLV_ID_W-1:0]     s_rid;
  logic [DATA_W-1:0]       s_rdata;
  logic [1:0]              s_rresp;
  logic                    s_rlast;
  logic                    s_rvalid;
  logic                    s_rready;

  logic [MST_ID_W-1:0]     m_awid;
  logic [ADDR_W-1:0]       m_awaddr;
  logic [7:0]              m_awlen;
  logic                    m_awvalid;
  logic                    m_awready;

  logic [DATA_W-1:0]       m_wdata;
  logic [DATA_W/8-1:0]     m_wstrb;
  logic                    m_wlast;
  logic                    m_wvalid;
  logic                    m_wready;

  logic [MST_ID_W-1:0]     m_bid;
  logic [1:0]              m_bresp;
  logic                    m_bvalid;
  logic                    m_bready;

  logic [MST_ID_W-1:0]     m_arid;
  logic [ADDR_W-1:0]       m_araddr;
  logic [7:0]              m_arlen;
  logic                    m_arvalid;
  logic                    m_arready;

  logic [MST_ID_W-1:0]     m_rid;
  logic [DATA_W-1:0]       m_rdata;
  logic [1:0]              m_rresp;
  logic                    m_rlast;
  logic                    m_rvalid;
  logic                    m_rready;

  id_width_conv #(
      .SLV_ID_W        (SLV_ID_W),
      .MST_ID_W        (MST_ID_W),
      .ADDR_W          (ADDR_W),
      .DATA_W          (DATA_W),
      .MAX_UNIQ_IDS    (MAX_UNIQ_IDS),
      .MAX_TXNS_PER_ID (MAX_TXNS_PER_ID)
  ) dut (
      .clk_i     (clk_i),
      .rst_ni    (rst_ni),
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

  // ---------------------------------------------------------------------------
  // PROVIDED PLUMBING -- moves transactions, checks nothing.
  // ---------------------------------------------------------------------------

  logic clk;
  initial begin clk = 1'b0; forever #5 clk = ~clk; end

  logic rst_n;
  initial rst_n = 1'b0;

  assign clk_i = clk;
  assign rst_ni = rst_n;

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
    $display("RESULT: FAIL (watchdog: no forward progress)");
    $finish;
  end

  // ---------------------------------------------------------------------------
  // Transaction model.
  // ---------------------------------------------------------------------------

  typedef struct packed {
    logic [SLV_ID_W-1:0] sid;
    logic [ADDR_W-1:0]   addr;
    logic [7:0]          len;
    logic [MST_ID_W-1:0] mid;
    bit                  forwarded;
    bit                  master_done;
    int unsigned         s_beats;
    int unsigned         m_beats;
  } rd_rec_t;

  typedef struct packed {
    logic [SLV_ID_W-1:0] sid;
    logic [ADDR_W-1:0]   addr;
    logic [7:0]          len;
    logic [MST_ID_W-1:0] mid;
    bit                  forwarded;
    bit                  master_done;
    bit                  s_data_done;
    bit                  m_data_done;
    int unsigned         s_beats;
    int unsigned         m_beats;
  } wr_rec_t;

  rd_rec_t reads[$];
  wr_rec_t writes[$];

  int errors;
  int cyc;
  bit f1_guard;

  bit a4r_armed;
  logic [SLV_ID_W-1:0] a4r_old_sid;
  logic [SLV_ID_W-1:0] a4r_new_sid;
  int a4r_retire_cyc;
  int a4r_accept_cyc;

  bit a4w_armed;
  logic [SLV_ID_W-1:0] a4w_old_sid;
  logic [SLV_ID_W-1:0] a4w_new_sid;
  int a4w_retire_cyc;
  int a4w_accept_cyc;

  bit acc;
  int waited;
  bit ok;

  function automatic logic [DATA_W-1:0] read_payload(
      input logic [ADDR_W-1:0] addr, input int beat);
    read_payload = addr ^ 32'hA5A5_0000 ^ beat;
  endfunction

  function automatic logic [DATA_W-1:0] write_payload(
      input logic [ADDR_W-1:0] addr, input int beat);
    write_payload = addr + 32'h0101_0000 + (beat * 32'h0000_0101);
  endfunction

  function automatic logic [DATA_W/8-1:0] write_strb(
      input logic [ADDR_W-1:0] addr, input int beat);
    logic unused_addr_bit;
    unused_addr_bit = addr[0];
    write_strb = ((beat + unused_addr_bit) % 2 == 0) ? 4'hF : 4'h3;
  endfunction

  function automatic int rd_distinct_count();
    int i;
    int j;
    int n;
    bit seen;
    n = 0;
    for (i = 0; i < reads.size(); i = i + 1) begin
      seen = 1'b0;
      for (j = 0; j < i; j = j + 1)
        if (reads[j].sid == reads[i].sid) seen = 1'b1;
      if (!seen) n = n + 1;
    end
    rd_distinct_count = n;
  endfunction

  function automatic int wr_distinct_count();
    int i;
    int j;
    int n;
    bit seen;
    n = 0;
    for (i = 0; i < writes.size(); i = i + 1) begin
      seen = 1'b0;
      for (j = 0; j < i; j = j + 1)
        if (writes[j].sid == writes[i].sid) seen = 1'b1;
      if (!seen) n = n + 1;
    end
    wr_distinct_count = n;
  endfunction

  function automatic int rd_sid_count(input logic [SLV_ID_W-1:0] sid);
    int i;
    int n;
    n = 0;
    for (i = 0; i < reads.size(); i = i + 1)
      if (reads[i].sid == sid) n = n + 1;
    rd_sid_count = n;
  endfunction

  function automatic int wr_sid_count(input logic [SLV_ID_W-1:0] sid);
    int i;
    int n;
    n = 0;
    for (i = 0; i < writes.size(); i = i + 1)
      if (writes[i].sid == sid) n = n + 1;
    wr_sid_count = n;
  endfunction

  function automatic int rd_fwd_count();
    int i;
    int n;
    n = 0;
    for (i = 0; i < reads.size(); i = i + 1)
      if (reads[i].forwarded) n = n + 1;
    rd_fwd_count = n;
  endfunction

  function automatic int wr_fwd_count();
    int i;
    int n;
    n = 0;
    for (i = 0; i < writes.size(); i = i + 1)
      if (writes[i].forwarded) n = n + 1;
    wr_fwd_count = n;
  endfunction

  function automatic int wr_data_done_count();
    int i;
    int n;
    n = 0;
    for (i = 0; i < writes.size(); i = i + 1)
      if (writes[i].m_data_done) n = n + 1;
    wr_data_done_count = n;
  endfunction

  task automatic note_fail(input string req, input string msg);
    errors = errors + 1;
    if (errors < 80)
      $display("%s violation: %s (time %0t)", req, msg, $time);
  endtask

  task automatic finish_sim;
    if (errors == 0)
      $display("RESULT: PASS");
    else
      $display("RESULT: FAIL");
    $finish;
  endtask

  // ---------------------------------------------------------------------------
  // Monitors and scoreboard. Retirements are processed before new address
  // acceptances so that reuse on the retiring edge itself is legal.
  // ---------------------------------------------------------------------------

  always @(posedge clk) begin : monitor_block
    automatic int i;
    automatic int j;
    automatic int idx;
    automatic rd_rec_t new_rd;
    automatic wr_rec_t new_wr;

    cyc = cyc + 1;

    if (!rst_n) begin
      if (s_bvalid)
        note_fail("F1", "s_bvalid was high while synchronous reset was low");
      if (s_rvalid)
        note_fail("F1", "s_rvalid was high while synchronous reset was low");
      reads.delete();
      writes.delete();
    end else begin

      // Downstream read response: associate by master ID and outstanding order.
      if (!f1_guard && m_rvalid && m_rready) begin
        idx = -1;
        for (i = 0; i < reads.size(); i = i + 1) begin
          if (reads[i].forwarded && !reads[i].master_done &&
              reads[i].mid == m_rid) begin
            idx = i;
            break;
          end
        end
        if (idx < 0) begin
          note_fail("D4", "master read response had no master transaction");
        end else begin
          if (m_rlast)
            reads[idx].master_done = 1'b1;
          else
            reads[idx].m_beats = reads[idx].m_beats + 1;
        end
      end

      // Downstream write response.
      if (!f1_guard && m_bvalid && m_bready) begin
        idx = -1;
        for (i = 0; i < writes.size(); i = i + 1) begin
          if (writes[i].forwarded && !writes[i].master_done &&
              writes[i].mid == m_bid) begin
            idx = i;
            break;
          end
        end
        if (idx < 0)
          note_fail("D4", "master write response had no master transaction");
        else
          writes[idx].master_done = 1'b1;
      end

      // Slave read response. The first matching ID is the oldest transaction,
      // which checks B1 as well as payload integrity and retirement.
      if (s_rvalid && s_rready) begin
        idx = -1;
        for (i = 0; i < reads.size(); i = i + 1) begin
          if (reads[i].sid == s_rid) begin
            idx = i;
            break;
          end
        end
        if (idx < 0) begin
          note_fail("C2", $sformatf("read response for ID %0h had no outstanding transaction", s_rid));
          if (f1_guard)
            note_fail("F1", "a discarded or pre-reset read produced a response");
        end else begin
          if (s_rdata !== read_payload(reads[idx].addr, reads[idx].s_beats))
            note_fail("E1", $sformatf(
                "read data mismatch for ID %0h addr %0h beat %0d: got %0h expected %0h",
                s_rid, reads[idx].addr, reads[idx].s_beats, s_rdata,
                read_payload(reads[idx].addr, reads[idx].s_beats)));
          if (s_rresp !== 2'b00)
            note_fail("E1", "read response code was not forwarded unmodified");
          if (s_rlast !== (reads[idx].s_beats == reads[idx].len))
            note_fail("E1", $sformatf(
                "read last mismatch for addr %0h beat %0d len %0d",
                reads[idx].addr, reads[idx].s_beats, reads[idx].len));

          if (s_rlast) begin
            if (!reads[idx].master_done)
              note_fail("D4", "slave read completed without a master response");
            if (a4r_armed && reads[idx].sid == a4r_old_sid)
              a4r_retire_cyc = cyc;
            reads.delete(idx);
          end else begin
            reads[idx].s_beats = reads[idx].s_beats + 1;
          end
        end
      end

      // Slave write response.
      if (s_bvalid && s_bready) begin
        idx = -1;
        for (i = 0; i < writes.size(); i = i + 1) begin
          if (writes[i].sid == s_bid) begin
            idx = i;
            break;
          end
        end
        if (idx < 0) begin
          note_fail("C2", $sformatf("write response for ID %0h had no outstanding transaction", s_bid));
          if (f1_guard)
            note_fail("F1", "a discarded or pre-reset write produced a response");
        end else begin
          if (s_bresp !== 2'b00)
            note_fail("E1", "write response code was not forwarded unmodified");
          if (!writes[idx].master_done)
            note_fail("D4", "slave write completed without a master response");
          if (a4w_armed && writes[idx].sid == a4w_old_sid)
            a4w_retire_cyc = cyc;
          writes.delete(idx);
        end
      end

      // Slave read address acceptance: enforce the exact table and depth bounds.
      if (s_arvalid && s_arready) begin
        if (rd_sid_count(s_arid) == 0) begin
          if (rd_distinct_count() >= MAX_UNIQ_IDS)
            note_fail("A3", $sformatf(
                "accepted new read ID %0h while %0d IDs were outstanding",
                s_arid, rd_distinct_count()));
        end else if (rd_sid_count(s_arid) >= MAX_TXNS_PER_ID) begin
          note_fail("A5", $sformatf(
              "accepted more than %0d reads for ID %0h",
              MAX_TXNS_PER_ID, s_arid));
        end

        if (a4r_armed && s_arid == a4r_new_sid)
          a4r_accept_cyc = cyc;

        new_rd.sid = s_arid;
        new_rd.addr = s_araddr;
        new_rd.len = s_arlen;
        new_rd.mid = '0;
        new_rd.forwarded = 1'b0;
        new_rd.master_done = 1'b0;
        new_rd.s_beats = 0;
        new_rd.m_beats = 0;
        reads.push_back(new_rd);
      end

      // Slave write address acceptance.
      if (s_awvalid && s_awready) begin
        if (wr_sid_count(s_awid) == 0) begin
          if (wr_distinct_count() >= MAX_UNIQ_IDS)
            note_fail("A3", $sformatf(
                "accepted new write ID %0h while %0d IDs were outstanding",
                s_awid, wr_distinct_count()));
        end else if (wr_sid_count(s_awid) >= MAX_TXNS_PER_ID) begin
          note_fail("A5", $sformatf(
              "accepted more than %0d writes for ID %0h",
              MAX_TXNS_PER_ID, s_awid));
        end

        if (a4w_armed && s_awid == a4w_new_sid)
          a4w_accept_cyc = cyc;

        new_wr.sid = s_awid;
        new_wr.addr = s_awaddr;
        new_wr.len = s_awlen;
        new_wr.mid = '0;
        new_wr.forwarded = 1'b0;
        new_wr.master_done = 1'b0;
        new_wr.s_data_done = 1'b0;
        new_wr.m_data_done = 1'b0;
        new_wr.s_beats = 0;
        new_wr.m_beats = 0;
        writes.push_back(new_wr);
      end

      // Slave write data is booked in slave address acceptance order.
      if (s_wvalid && s_wready) begin
        idx = -1;
        for (i = 0; i < writes.size(); i = i + 1) begin
          if (!writes[i].s_data_done) begin
            idx = i;
            break;
          end
        end
        if (idx < 0) begin
          note_fail("D4", "accepted write data without an outstanding write address");
        end else begin
          writes[idx].s_beats = writes[idx].s_beats + 1;
          if (s_wlast) writes[idx].s_data_done = 1'b1;
        end
      end

      // Master read address. Matching by unique address permits arbitrary
      // forwarding order between different IDs.
      if (m_arvalid && m_arready) begin
        idx = -1;
        for (i = 0; i < reads.size(); i = i + 1) begin
          if (!reads[i].forwarded && reads[i].addr == m_araddr &&
              reads[i].len == m_arlen) begin
            idx = i;
            break;
          end
        end
        if (idx < 0) begin
          if (f1_guard)
            note_fail("F1", "a read accepted before or during reset reappeared afterwards");
          note_fail("E1", $sformatf(
              "master AR addr/len %0h/%0d matched no accepted slave request",
              m_araddr, m_arlen));
          note_fail("D4", "unexpected or duplicate master read transaction");
        end else begin
          reads[idx].forwarded = 1'b1;
          reads[idx].mid = m_arid;
          for (j = 0; j < reads.size(); j = j + 1) begin
            if (j != idx && reads[j].forwarded &&
                reads[j].sid != reads[idx].sid &&
                reads[j].mid == m_arid) begin
              note_fail("D1", $sformatf(
                  "master read ID %0h shared by co-outstanding slave IDs %0h and %0h",
                  m_arid, reads[j].sid, reads[idx].sid));
              note_fail("D2", "master read identifier was reused before retirement");
            end
          end
        end
      end

      // Master write address.
      if (m_awvalid && m_awready) begin
        idx = -1;
        for (i = 0; i < writes.size(); i = i + 1) begin
          if (!writes[i].forwarded && writes[i].addr == m_awaddr &&
              writes[i].len == m_awlen) begin
            idx = i;
            break;
          end
        end
        if (idx < 0) begin
          if (f1_guard)
            note_fail("F1", "a write accepted before or during reset reappeared afterwards");
          note_fail("E1", $sformatf(
              "master AW addr/len %0h/%0d matched no accepted slave request",
              m_awaddr, m_awlen));
          note_fail("D4", "unexpected or duplicate master write transaction");
        end else begin
          writes[idx].forwarded = 1'b1;
          writes[idx].mid = m_awid;
          for (j = 0; j < writes.size(); j = j + 1) begin
            if (j != idx && writes[j].forwarded &&
                writes[j].sid != writes[idx].sid &&
                writes[j].mid == m_awid) begin
              note_fail("D1", $sformatf(
                  "master write ID %0h shared by co-outstanding slave IDs %0h and %0h",
                  m_awid, writes[j].sid, writes[idx].sid));
              note_fail("D2", "master write identifier was reused before retirement");
            end
          end
        end
      end

      // Master write data must follow global slave AW order, without interleave.
      if (m_wvalid && m_wready) begin
        idx = -1;
        for (i = 0; i < writes.size(); i = i + 1) begin
          if (!writes[i].m_data_done) begin
            idx = i;
            break;
          end
        end
        if (idx < 0) begin
          if (f1_guard)
            note_fail("F1", "write data survived reset");
          note_fail("D4", "unexpected or extra master write data beat");
        end else begin
          if (writes[idx].m_beats >= writes[idx].s_beats) begin
            note_fail("D4", "master forwarded a write beat never accepted on the slave port");
          end else begin
            if (m_wdata !== write_payload(writes[idx].addr, writes[idx].m_beats))
              note_fail("E1", $sformatf(
                  "write data/order mismatch for addr %0h beat %0d: got %0h expected %0h",
                  writes[idx].addr, writes[idx].m_beats, m_wdata,
                  write_payload(writes[idx].addr, writes[idx].m_beats)));
            if (m_wstrb !== write_strb(writes[idx].addr, writes[idx].m_beats))
              note_fail("E1", "write strobe was modified or misordered");
            if (m_wlast !== (writes[idx].m_beats == writes[idx].len))
              note_fail("E1", "write last was modified or misordered");
          end
          writes[idx].m_beats = writes[idx].m_beats + 1;
          if (m_wlast) writes[idx].m_data_done = 1'b1;
        end
      end
    end
  end

  // ---------------------------------------------------------------------------
  // Stimulus helpers.
  // ---------------------------------------------------------------------------

  task automatic wait_rd_forwarded(input int target, input int budget,
                                   output bit success);
    int k;
    success = 1'b0;
    for (k = 0; k < budget; k = k + 1) begin
      @(negedge clk);
      if (rd_fwd_count() >= target) begin
        success = 1'b1;
        return;
      end
    end
  endtask

  task automatic wait_wr_forwarded(input int target, input int budget,
                                   output bit success);
    int k;
    success = 1'b0;
    for (k = 0; k < budget; k = k + 1) begin
      @(negedge clk);
      if (wr_fwd_count() >= target) begin
        success = 1'b1;
        return;
      end
    end
  endtask

  task automatic wait_wr_data_done(input int target, input int budget,
                                   output bit success);
    int k;
    success = 1'b0;
    for (k = 0; k < budget; k = k + 1) begin
      @(negedge clk);
      if (wr_data_done_count() >= target) begin
        success = 1'b1;
        return;
      end
    end
  endtask

  task automatic wait_rd_empty(input int budget, output bit success);
    int k;
    success = 1'b0;
    for (k = 0; k < budget; k = k + 1) begin
      @(negedge clk);
      if (reads.size() == 0) begin
        success = 1'b1;
        return;
      end
    end
  endtask

  task automatic wait_wr_empty(input int budget, output bit success);
    int k;
    success = 1'b0;
    for (k = 0; k < budget; k = k + 1) begin
      @(negedge clk);
      if (writes.size() == 0) begin
        success = 1'b1;
        return;
      end
    end
  endtask

  task automatic wait_a4r_retired(input int budget, output bit success);
    int k;
    success = 1'b0;
    for (k = 0; k < budget; k = k + 1) begin
      @(negedge clk);
      if (a4r_retire_cyc >= 0) begin
        success = 1'b1;
        return;
      end
    end
  endtask

  task automatic wait_a4w_retired(input int budget, output bit success);
    int k;
    success = 1'b0;
    for (k = 0; k < budget; k = k + 1) begin
      @(negedge clk);
      if (a4w_retire_cyc >= 0) begin
        success = 1'b1;
        return;
      end
    end
  endtask

  task automatic require_ar(input logic [SLV_ID_W-1:0] id,
                            input logic [ADDR_W-1:0] addr,
                            input logic [7:0] len,
                            input string req);
    bit accepted;
    int waited_local;
    bfm_ar(id, addr, len, 100, accepted, waited_local);
    if (!accepted) begin
      note_fail(req, $sformatf("read ID %0h addr %0h was refused", id, addr));
      finish_sim();
    end
  endtask

  task automatic require_aw(input logic [SLV_ID_W-1:0] id,
                            input logic [ADDR_W-1:0] addr,
                            input logic [7:0] len,
                            input string req);
    bit accepted;
    int waited_local;
    bfm_aw(id, addr, len, 100, accepted, waited_local);
    if (!accepted) begin
      note_fail(req, $sformatf("write ID %0h addr %0h was refused", id, addr));
      finish_sim();
    end
  endtask

  task automatic require_ar_blocked(input logic [SLV_ID_W-1:0] id,
                                    input logic [ADDR_W-1:0] addr,
                                    input logic [7:0] len,
                                    input string req);
    bit accepted;
    int waited_local;
    bfm_ar(id, addr, len, 5, accepted, waited_local);
    if (accepted) begin
      note_fail(req, $sformatf("read ID %0h addr %0h was accepted while blocked", id, addr));
      finish_sim();
    end
  endtask

  task automatic require_aw_blocked(input logic [SLV_ID_W-1:0] id,
                                    input logic [ADDR_W-1:0] addr,
                                    input logic [7:0] len,
                                    input string req);
    bit accepted;
    int waited_local;
    bfm_aw(id, addr, len, 5, accepted, waited_local);
    if (accepted) begin
      note_fail(req, $sformatf("write ID %0h addr %0h was accepted while blocked", id, addr));
      finish_sim();
    end
  endtask

  task automatic send_read_response(input logic [ADDR_W-1:0] addr);
    automatic int i;
    automatic int idx;
    automatic int b;
    automatic logic [MST_ID_W-1:0] mid;
    automatic logic [7:0] len;
    idx = -1;
    mid = '0;
    len = 0;
    for (i = 0; i < reads.size(); i = i + 1) begin
      if (reads[i].forwarded && !reads[i].master_done &&
          reads[i].addr == addr) begin
        idx = i;
        mid = reads[i].mid;
        len = reads[i].len;
        break;
      end
    end
    if (idx < 0) begin
      note_fail("D4", $sformatf("could not find forwarded read addr %0h", addr));
      finish_sim();
    end
    for (b = 0; b <= len; b = b + 1)
      bfm_rbeat(mid, read_payload(addr, b), b == len);
  endtask

  task automatic send_write_response(input logic [ADDR_W-1:0] addr);
    automatic int i;
    automatic int idx;
    automatic logic [MST_ID_W-1:0] mid;
    idx = -1;
    mid = '0;
    for (i = 0; i < writes.size(); i = i + 1) begin
      if (writes[i].forwarded && !writes[i].master_done &&
          writes[i].addr == addr) begin
        idx = i;
        mid = writes[i].mid;
        break;
      end
    end
    if (idx < 0) begin
      note_fail("D4", $sformatf("could not find forwarded write addr %0h", addr));
      finish_sim();
    end
    bfm_bbeat(mid);
  endtask

  task automatic send_write_data(input logic [ADDR_W-1:0] addr,
                                 input logic [7:0] len);
    automatic int b;
    for (b = 0; b <= len; b = b + 1)
      bfm_w(write_payload(addr, b), write_strb(addr, b), b == len);
  endtask

  // Hold AW, AR and W valid throughout reset. Ready is deliberately not checked.
  task automatic reset_with_traffic;
    @(negedge clk);
    rst_n = 1'b0;
    s_awid = 4'hE;
    s_awaddr = 32'h0000_5100;
    s_awlen = 0;
    s_awvalid = 1'b1;
    s_arid = 4'hF;
    s_araddr = 32'h0000_5000;
    s_arlen = 0;
    s_arvalid = 1'b1;
    s_wdata = 32'hBAD0_5000;
    s_wstrb = 4'hF;
    s_wlast = 1'b1;
    s_wvalid = 1'b1;
    repeat (5) @(posedge clk);
    @(negedge clk);
    s_awvalid = 1'b0;
    s_arvalid = 1'b0;
    s_wvalid = 1'b0;
    rst_n = 1'b1;
  endtask

  // Offer stale responses without requiring a downstream handshake. A correct
  // empty design may either accept and ignore them or leave ready low.
  task automatic offer_stale_responses;
    automatic int k;
    for (k = 0; k < 4; k = k + 1) begin
      @(negedge clk);
      m_rid = k;
      m_rdata = 32'hDEAD_BEEF ^ k;
      m_rresp = 2'b00;
      m_rlast = 1'b1;
      m_rvalid = 1'b1;
      m_bid = k;
      m_bresp = 2'b00;
      m_bvalid = 1'b1;
      repeat (2) @(posedge clk);
      @(negedge clk);
      m_rvalid = 1'b0;
      m_bvalid = 1'b0;
    end
  endtask

  localparam logic [ADDR_W-1:0] R0  = 32'h0000_1000;
  localparam logic [ADDR_W-1:0] R1  = 32'h0000_1100;
  localparam logic [ADDR_W-1:0] R2  = 32'h0000_1200;
  localparam logic [ADDR_W-1:0] R3  = 32'h0000_1300;
  localparam logic [ADDR_W-1:0] R4  = 32'h0000_1400;
  localparam logic [ADDR_W-1:0] R1B = 32'h0000_1500;
  localparam logic [ADDR_W-1:0] R1C = 32'h0000_1600;

  localparam logic [ADDR_W-1:0] W0  = 32'h0000_2000;
  localparam logic [ADDR_W-1:0] W1  = 32'h0000_2100;
  localparam logic [ADDR_W-1:0] W2  = 32'h0000_2200;
  localparam logic [ADDR_W-1:0] W3  = 32'h0000_2300;
  localparam logic [ADDR_W-1:0] W4  = 32'h0000_2400;
  localparam logic [ADDR_W-1:0] W1B = 32'h0000_2500;
  localparam logic [ADDR_W-1:0] W1C = 32'h0000_2600;

  localparam logic [ADDR_W-1:0] RR  = 32'h0000_3000;
  localparam logic [ADDR_W-1:0] WR  = 32'h0000_3100;

  initial begin : main_test
    errors = 0;
    cyc = 0;
    f1_guard = 1'b0;

    a4r_armed = 1'b0;
    a4r_old_sid = '0;
    a4r_new_sid = '0;
    a4r_retire_cyc = -1;
    a4r_accept_cyc = -1;
    a4w_armed = 1'b0;
    a4w_old_sid = '0;
    a4w_new_sid = '0;
    a4w_retire_cyc = -1;
    a4w_accept_cyc = -1;

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
    m_bid = '0;
    m_bresp = '0;
    m_bvalid = 1'b0;
    m_arready = 1'b1;
    m_rid = '0;
    m_rdata = '0;
    m_rresp = '0;
    m_rlast = 1'b0;
    m_rvalid = 1'b0;

    bfm_reset(5);

    // ------------------------------------------------------------------
    // Read side: A3 lower boundary, full-table refusal, A4 retirement,
    // A5 depth, D1/D2, multi-beat E1 and per-ID response ordering.
    // ------------------------------------------------------------------
    require_ar(4'h0, R0, 8'd0, "A3");
    require_ar(4'h1, R1, 8'd0, "A3");
    require_ar(4'h2, R2, 8'd1, "A3");
    require_ar(4'h3, R3, 8'd0, "A3");

    wait_rd_forwarded(4, 200, ok);
    if (!ok) begin
      note_fail("D4", "four accepted reads did not produce four master reads");
      finish_sim();
    end

    require_ar_blocked(4'h4, R4, 8'd0, "A3");

    a4r_armed = 1'b1;
    a4r_old_sid = 4'h0;
    a4r_new_sid = 4'h4;
    a4r_retire_cyc = -1;
    a4r_accept_cyc = -1;
    fork
      bfm_ar(4'h4, R4, 8'd0, 200, acc, waited);
      send_read_response(R0);
    join

    if (!acc)
      note_fail("A4", "new read ID was not accepted after an entry retired");
    wait_a4r_retired(200, ok);
    a4r_armed = 1'b0;
    if (!ok) begin
      note_fail("D4", "retiring read never produced its slave response");
      finish_sim();
    end
    if (acc && a4r_accept_cyc >= a4r_retire_cyc &&
        (a4r_accept_cyc - a4r_retire_cyc) > 2)
      note_fail("A4", $sformatf(
          "new ID accepted %0d cycles after retirement",
          a4r_accept_cyc - a4r_retire_cyc));
    if (errors != 0) finish_sim();

    wait_rd_forwarded(4, 200, ok);
    if (!ok) begin
      note_fail("D4", "read accepted at retirement was not forwarded");
      finish_sim();
    end

    // A second transaction on an existing ID is not blocked by A3.
    require_ar(4'h1, R1B, 8'd0, "A3");
    wait_rd_forwarded(5, 200, ok);
    if (!ok) begin
      note_fail("D4", "second same-ID read was not forwarded");
      finish_sim();
    end

    // Two are already outstanding for ID 1, so a third must wait.
    require_ar_blocked(4'h1, R1C, 8'd0, "A5");

    // Deliberately complete different IDs out of order. Same-ID responses
    // remain in address order, as required on the downstream interface too.
    send_read_response(R3);
    send_read_response(R4);
    send_read_response(R1);
    send_read_response(R2);
    send_read_response(R1B);

    wait_rd_empty(300, ok);
    if (!ok) begin
      note_fail("D4", "one or more master read responses had no slave response");
      finish_sim();
    end

    // ------------------------------------------------------------------
    // Write side: independent table, ordered/non-interleaved W data,
    // A3/A4/A5, response restoration and payload checks.
    // ------------------------------------------------------------------
    require_aw(4'h0, W0, 8'd1, "A3");
    require_aw(4'h1, W1, 8'd0, "A3");
    require_aw(4'h2, W2, 8'd0, "A3");
    require_aw(4'h3, W3, 8'd1, "A3");

    wait_wr_forwarded(4, 200, ok);
    if (!ok) begin
      note_fail("D4", "four accepted writes did not produce four master writes");
      finish_sim();
    end

    send_write_data(W0, 8'd1);
    send_write_data(W1, 8'd0);
    send_write_data(W2, 8'd0);
    send_write_data(W3, 8'd1);

    wait_wr_data_done(4, 200, ok);
    if (!ok) begin
      note_fail("D4", "accepted write data was not forwarded");
      finish_sim();
    end

    require_aw_blocked(4'h4, W4, 8'd0, "A3");

    a4w_armed = 1'b1;
    a4w_old_sid = 4'h0;
    a4w_new_sid = 4'h4;
    a4w_retire_cyc = -1;
    a4w_accept_cyc = -1;
    fork
      bfm_aw(4'h4, W4, 8'd0, 200, acc, waited);
      send_write_response(W0);
    join

    if (!acc)
      note_fail("A4", "new write ID was not accepted after an entry retired");
    wait_a4w_retired(200, ok);
    a4w_armed = 1'b0;
    if (!ok) begin
      note_fail("D4", "retiring write never produced its slave response");
      finish_sim();
    end
    if (acc && a4w_accept_cyc >= a4w_retire_cyc &&
        (a4w_accept_cyc - a4w_retire_cyc) > 2)
      note_fail("A4", $sformatf(
          "new write ID accepted %0d cycles after retirement",
          a4w_accept_cyc - a4w_retire_cyc));
    if (errors != 0) finish_sim();

    wait_wr_forwarded(4, 200, ok);
    if (!ok) begin
      note_fail("D4", "write accepted at retirement was not forwarded");
      finish_sim();
    end

    require_aw(4'h1, W1B, 8'd0, "A3");
    wait_wr_forwarded(5, 200, ok);
    if (!ok) begin
      note_fail("D4", "second same-ID write was not forwarded");
      finish_sim();
    end
    require_aw_blocked(4'h1, W1C, 8'd0, "A5");

    // These beats must follow W4 and then W1B: slave AW acceptance order.
    send_write_data(W4, 8'd0);
    send_write_data(W1B, 8'd0);

    wait_wr_data_done(5, 200, ok);
    if (!ok) begin
      note_fail("D4", "later write data was not forwarded");
      finish_sim();
    end

    send_write_response(W3);
    send_write_response(W1);
    send_write_response(W4);
    send_write_response(W2);
    send_write_response(W1B);

    wait_wr_empty(300, ok);
    if (!ok) begin
      note_fail("D4", "one or more master write responses had no slave response");
      finish_sim();
    end

    // ------------------------------------------------------------------
    // F1: transactions outstanding across reset and requests offered during
    // reset are discarded. Stale responses are then offered on every master
    // ID. Finally, four fresh IDs check that the table is empty after reset.
    // ------------------------------------------------------------------
    require_ar(4'h6, RR, 8'd0, "A3");
    require_aw(4'h7, WR, 8'd0, "A3");

    wait_rd_forwarded(1, 200, ok);
    if (!ok) begin
      note_fail("D4", "reset-test read was not forwarded");
      finish_sim();
    end
    wait_wr_forwarded(1, 200, ok);
    if (!ok) begin
      note_fail("D4", "reset-test write was not forwarded");
      finish_sim();
    end
    send_write_data(WR, 8'd0);
    wait_wr_data_done(1, 200, ok);
    if (!ok) begin
      note_fail("D4", "reset-test write data was not forwarded");
      finish_sim();
    end

    f1_guard = 1'b1;
    reset_with_traffic();
    offer_stale_responses();
    repeat (4) @(negedge clk);
    f1_guard = 1'b0;

    require_ar(4'h0, 32'h0000_4000, 8'd0, "A3");
    require_ar(4'h1, 32'h0000_4100, 8'd0, "A3");
    require_ar(4'h2, 32'h0000_4200, 8'd0, "A3");
    require_ar(4'h3, 32'h0000_4300, 8'd0, "A3");
    require_ar_blocked(4'h4, 32'h0000_4400, 8'd0, "A3");

    wait_rd_forwarded(4, 200, ok);
    if (!ok) begin
      note_fail("D4", "post-reset reads were not forwarded one-for-one");
      finish_sim();
    end

    // Discard these final requests as well, and check once more that no old
    // response can emerge after release.
    f1_guard = 1'b1;
    bfm_reset(3);
    offer_stale_responses();
    repeat (4) @(negedge clk);

    finish_sim();
  end

endmodule
