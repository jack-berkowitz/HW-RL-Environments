module id_width_conv_tb;

  localparam int unsigned SLV_ID_W        = 4;
  localparam int unsigned MST_ID_W        = 2;
  localparam int unsigned ADDR_W          = 32;
  localparam int unsigned DATA_W          = 32;
  localparam int unsigned MAX_UNIQ_IDS    = 4;
  localparam int unsigned MAX_TXNS_PER_ID = 2;

  localparam int SID_COUNT = (1 << SLV_ID_W);
  localparam int MID_COUNT = (1 << MST_ID_W);
  localparam int MAX_TX     = 128;
  localparam int MAX_BEATS  = 256;

  // ---------------------------------------------------------------------------
  // DUT signals
  // ---------------------------------------------------------------------------
  logic                    clk;
  logic                    rst_n;

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
    .clk_i      (clk),
    .rst_ni     (rst_n),

    .s_awid     (s_awid),
    .s_awaddr   (s_awaddr),
    .s_awlen    (s_awlen),
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
    .m_arvalid  (m_arvalid),
    .m_arready  (m_arready),

    .m_rid      (m_rid),
    .m_rdata    (m_rdata),
    .m_rresp    (m_rresp),
    .m_rlast    (m_rlast),
    .m_rvalid   (m_rvalid),
    .m_rready   (m_rready)
  );

  // ---------------------------------------------------------------------------
  // PROVIDED PLUMBING -- moves transactions, checks nothing.
  // ---------------------------------------------------------------------------
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

  // ---------------------------------------------------------------------------
  // Scoreboard state
  // ---------------------------------------------------------------------------
  typedef struct {
    bit                      allocated;
    bit                      accepted;
    logic [SLV_ID_W-1:0]     sid;
    logic [ADDR_W-1:0]       addr;
    logic [7:0]              len;
    bit                      master_seen;
    logic [MST_ID_W-1:0]     mid;
    longint unsigned         accept_cycle;
    longint unsigned         retire_cycle;
    int                      slave_beats;
    bit                      done;
  } rd_rec_t;

  typedef struct {
    bit                      allocated;
    bit                      accepted;
    logic [SLV_ID_W-1:0]     sid;
    logic [ADDR_W-1:0]       addr;
    logic [7:0]              len;
    bit                      master_seen;
    logic [MST_ID_W-1:0]     mid;
    longint unsigned         accept_cycle;
    longint unsigned         retire_cycle;
    bit                      done;
  } wr_rec_t;

  rd_rec_t rd_rec [0:MAX_TX-1];
  wr_rec_t wr_rec [0:MAX_TX-1];

  int rd_next_seq;
  int wr_next_seq;

  int rd_out_cnt [0:SID_COUNT-1];
  int wr_out_cnt [0:SID_COUNT-1];
  int rd_distinct;
  int wr_distinct;

  int rd_sid_fifo [0:SID_COUNT-1][0:MAX_TX-1];
  int rd_sid_head [0:SID_COUNT-1];
  int rd_sid_tail [0:SID_COUNT-1];

  int wr_sid_fifo [0:SID_COUNT-1][0:MAX_TX-1];
  int wr_sid_head [0:SID_COUNT-1];
  int wr_sid_tail [0:SID_COUNT-1];

  int rd_fwd_fifo [0:MAX_TX-1];
  int rd_fwd_head;
  int rd_fwd_tail;

  int wr_fwd_fifo [0:MAX_TX-1];
  int wr_fwd_head;
  int wr_fwd_tail;

  int wr_data_fifo [0:MAX_TX-1];
  int wr_data_head;
  int wr_data_tail;

  bit rd_mid_owner_valid [0:MID_COUNT-1];
  logic [SLV_ID_W-1:0] rd_mid_owner_sid [0:MID_COUNT-1];
  bit wr_mid_owner_valid [0:MID_COUNT-1];
  logic [SLV_ID_W-1:0] wr_mid_owner_sid [0:MID_COUNT-1];

  int                  rbeat_seq [0:MAX_BEATS-1];
  logic [DATA_W-1:0]   rbeat_data [0:MAX_BEATS-1];
  logic [1:0]          rbeat_resp [0:MAX_BEATS-1];
  bit                  rbeat_last [0:MAX_BEATS-1];
  bit                  rbeat_used [0:MAX_BEATS-1];
  int                  rbeat_count;

  int                  bitem_seq [0:MAX_TX-1];
  bit                  bitem_used [0:MAX_TX-1];
  int                  bitem_count;

  int                  wbeat_seq [0:MAX_BEATS-1];
  logic [DATA_W-1:0]   wbeat_data [0:MAX_BEATS-1];
  logic [DATA_W/8-1:0] wbeat_strb [0:MAX_BEATS-1];
  bit                  wbeat_last [0:MAX_BEATS-1];
  bit                  wbeat_used [0:MAX_BEATS-1];
  int                  wbeat_count;
  int                  wbeat_head;

  bit ar_tag_valid;
  int ar_tag_seq;
  bit aw_tag_valid;
  int aw_tag_seq;

  bit r_drive_tag_valid;
  bit r_drive_stale;
  int r_drive_seq;
  bit b_drive_tag_valid;
  bit b_drive_stale;
  int b_drive_seq;

  int errors;
  longint unsigned cycle_no;
  string watchdog_req;

  bit reset_has_occurred;
  logic [SLV_ID_W-1:0] stale_read_sid;
  logic [SLV_ID_W-1:0] stale_write_sid;

  // Test transaction handles.
  int rfill [0:4];
  int rdepth [0:3];
  int rord [0:1];
  int wfill [0:4];
  int wdepth [0:3];
  int worder [0:1];
  int wmulti [0:1];
  int rpre;
  int wpre;
  int rpost [0:3];
  int wpost [0:3];

  bit a4_r_acc;
  int a4_r_wait;
  bit a4_w_acc;
  int a4_w_wait;

  // ---------------------------------------------------------------------------
  // Utility functions/tasks
  // ---------------------------------------------------------------------------
  task automatic fail_req(input string req_name, input string msg);
    begin
      $display("%s: FAIL - %s", req_name, msg);
      errors = errors + 1;
    end
  endtask

  task automatic stop_if_failed;
    begin
      if (errors != 0) begin
        @(negedge clk);
        $display("RESULT: FAIL");
        $finish;
      end
    end
  endtask

  function automatic int first_rbeat_for_seq(input int seq_no);
    integer k;
    begin
      first_rbeat_for_seq = -1;
      for (k = 0; k < rbeat_count; k = k + 1) begin
        if ((first_rbeat_for_seq < 0) && !rbeat_used[k] && (rbeat_seq[k] == seq_no))
          first_rbeat_for_seq = k;
      end
    end
  endfunction

  function automatic int first_bitem_for_seq(input int seq_no);
    integer k;
    begin
      first_bitem_for_seq = -1;
      for (k = 0; k < bitem_count; k = k + 1) begin
        if ((first_bitem_for_seq < 0) && !bitem_used[k] && (bitem_seq[k] == seq_no))
          first_bitem_for_seq = k;
      end
    end
  endfunction

  function automatic bit any_unconsumed_rbeat;
    integer k;
    begin
      any_unconsumed_rbeat = 1'b0;
      for (k = 0; k < rbeat_count; k = k + 1) begin
        if (!rbeat_used[k]) any_unconsumed_rbeat = 1'b1;
      end
    end
  endfunction

  function automatic bit any_unconsumed_bitem;
    integer k;
    begin
      any_unconsumed_bitem = 1'b0;
      for (k = 0; k < bitem_count; k = k + 1) begin
        if (!bitem_used[k]) any_unconsumed_bitem = 1'b1;
      end
    end
  endfunction

  function automatic bit later_rbeat_for_sid(input logic [SLV_ID_W-1:0] sid,
                                               input int head_seq);
    integer k;
    begin
      later_rbeat_for_sid = 1'b0;
      for (k = 0; k < rbeat_count; k = k + 1) begin
        if (!rbeat_used[k] && (rbeat_seq[k] != head_seq) &&
            rd_rec[rbeat_seq[k]].allocated &&
            (rd_rec[rbeat_seq[k]].sid == sid))
          later_rbeat_for_sid = 1'b1;
      end
    end
  endfunction

  function automatic bit later_bitem_for_sid(input logic [SLV_ID_W-1:0] sid,
                                               input int head_seq);
    integer k;
    begin
      later_bitem_for_sid = 1'b0;
      for (k = 0; k < bitem_count; k = k + 1) begin
        if (!bitem_used[k] && (bitem_seq[k] != head_seq) &&
            wr_rec[bitem_seq[k]].allocated &&
            (wr_rec[bitem_seq[k]].sid == sid))
          later_bitem_for_sid = 1'b1;
      end
    end
  endfunction

  task automatic prep_read(input  logic [SLV_ID_W-1:0] sid,
                           input  logic [ADDR_W-1:0] addr,
                           input  logic [7:0] len,
                           output int seq_no);
    begin
      seq_no = rd_next_seq;
      rd_next_seq = rd_next_seq + 1;
      rd_rec[seq_no].allocated = 1'b1;
      rd_rec[seq_no].accepted = 1'b0;
      rd_rec[seq_no].sid = sid;
      rd_rec[seq_no].addr = addr;
      rd_rec[seq_no].len = len;
      rd_rec[seq_no].master_seen = 1'b0;
      rd_rec[seq_no].mid = '0;
      rd_rec[seq_no].accept_cycle = 0;
      rd_rec[seq_no].retire_cycle = 0;
      rd_rec[seq_no].slave_beats = 0;
      rd_rec[seq_no].done = 1'b0;
    end
  endtask

  task automatic prep_write(input  logic [SLV_ID_W-1:0] sid,
                            input  logic [ADDR_W-1:0] addr,
                            input  logic [7:0] len,
                            output int seq_no);
    begin
      seq_no = wr_next_seq;
      wr_next_seq = wr_next_seq + 1;
      wr_rec[seq_no].allocated = 1'b1;
      wr_rec[seq_no].accepted = 1'b0;
      wr_rec[seq_no].sid = sid;
      wr_rec[seq_no].addr = addr;
      wr_rec[seq_no].len = len;
      wr_rec[seq_no].master_seen = 1'b0;
      wr_rec[seq_no].mid = '0;
      wr_rec[seq_no].accept_cycle = 0;
      wr_rec[seq_no].retire_cycle = 0;
      wr_rec[seq_no].done = 1'b0;
    end
  endtask

  task automatic wait_master_read(input int seq_no);
    begin
      watchdog_req = "D4";
      while (!rd_rec[seq_no].master_seen) @(negedge clk);
    end
  endtask

  task automatic wait_master_write(input int seq_no);
    begin
      watchdog_req = "D4";
      while (!wr_rec[seq_no].master_seen) @(negedge clk);
    end
  endtask

  task automatic wait_read_done(input int seq_no);
    begin
      watchdog_req = "D4";
      while (!rd_rec[seq_no].done) @(negedge clk);
    end
  endtask

  task automatic wait_write_done(input int seq_no);
    begin
      watchdog_req = "D4";
      while (!wr_rec[seq_no].done) @(negedge clk);
    end
  endtask

  task automatic issue_read(input  logic [SLV_ID_W-1:0] sid,
                            input  logic [ADDR_W-1:0] addr,
                            input  logic [7:0] len,
                            input  string req_name,
                            output int seq_no);
    automatic bit accepted;
    automatic int waited;
    begin
      prep_read(sid, addr, len, seq_no);
      ar_tag_valid = 1'b1;
      ar_tag_seq = seq_no;
      watchdog_req = req_name;
      bfm_ar(sid, addr, len, 1000000, accepted, waited);
      ar_tag_valid = 1'b0;
      if (!accepted) begin
        fail_req(req_name, "request that should make progress was not accepted within the generous budget");
      end
      if (accepted) wait_master_read(seq_no);
    end
  endtask

  task automatic issue_write(input  logic [SLV_ID_W-1:0] sid,
                             input  logic [ADDR_W-1:0] addr,
                             input  logic [7:0] len,
                             input  string req_name,
                             output int seq_no);
    automatic bit accepted;
    automatic int waited;
    begin
      prep_write(sid, addr, len, seq_no);
      aw_tag_valid = 1'b1;
      aw_tag_seq = seq_no;
      watchdog_req = req_name;
      bfm_aw(sid, addr, len, 1000000, accepted, waited);
      aw_tag_valid = 1'b0;
      if (!accepted) begin
        fail_req(req_name, "request that should make progress was not accepted within the generous budget");
      end
      if (accepted) wait_master_write(seq_no);
    end
  endtask

  task automatic attempt_read_blocked(input logic [SLV_ID_W-1:0] sid,
                                      input logic [ADDR_W-1:0] addr,
                                      input logic [7:0] len,
                                      input string req_name);
    automatic int seq_no;
    automatic bit accepted;
    automatic int waited;
    begin
      prep_read(sid, addr, len, seq_no);
      ar_tag_valid = 1'b1;
      ar_tag_seq = seq_no;
      watchdog_req = req_name;
      bfm_ar(sid, addr, len, 4, accepted, waited);
      ar_tag_valid = 1'b0;
      if (accepted) fail_req(req_name, "request was accepted while the specification requires it to remain blocked");
    end
  endtask

  task automatic attempt_write_blocked(input logic [SLV_ID_W-1:0] sid,
                                       input logic [ADDR_W-1:0] addr,
                                       input logic [7:0] len,
                                       input string req_name);
    automatic int seq_no;
    automatic bit accepted;
    automatic int waited;
    begin
      prep_write(sid, addr, len, seq_no);
      aw_tag_valid = 1'b1;
      aw_tag_seq = seq_no;
      watchdog_req = req_name;
      bfm_aw(sid, addr, len, 4, accepted, waited);
      aw_tag_valid = 1'b0;
      if (accepted) fail_req(req_name, "request was accepted while the specification requires it to remain blocked");
    end
  endtask

  task automatic send_rbeat_only(input int seq_no,
                                 input logic [DATA_W-1:0] data,
                                 input logic [1:0] resp,
                                 input bit is_last,
                                 input bit wait_for_slave);
    automatic int old_beats;
    begin
      old_beats = rd_rec[seq_no].slave_beats;
      watchdog_req = "D4";
      @(negedge clk);
      r_drive_tag_valid = 1'b1;
      r_drive_stale = 1'b0;
      r_drive_seq = seq_no;
      m_rid = rd_rec[seq_no].mid;
      m_rdata = data;
      m_rresp = resp;
      m_rlast = is_last;
      m_rvalid = 1'b1;
      forever begin
        @(posedge clk);
        if (m_rready) break;
      end
      @(negedge clk);
      m_rvalid = 1'b0;
      r_drive_tag_valid = 1'b0;
      if (wait_for_slave) begin
        while (rd_rec[seq_no].slave_beats == old_beats) @(negedge clk);
      end
    end
  endtask

  task automatic send_bitem_only(input int seq_no,
                                 input logic [1:0] resp,
                                 input bit wait_for_slave);
    begin
      watchdog_req = "D4";
      @(negedge clk);
      b_drive_tag_valid = 1'b1;
      b_drive_stale = 1'b0;
      b_drive_seq = seq_no;
      m_bid = wr_rec[seq_no].mid;
      m_bresp = resp;
      m_bvalid = 1'b1;
      forever begin
        @(posedge clk);
        if (m_bready) break;
      end
      @(negedge clk);
      m_bvalid = 1'b0;
      b_drive_tag_valid = 1'b0;
      if (wait_for_slave) wait_write_done(seq_no);
    end
  endtask

  task automatic send_write_beat(input logic [DATA_W-1:0] data,
                                 input logic [DATA_W/8-1:0] strb,
                                 input bit is_last);
    begin
      watchdog_req = "B3";
      bfm_w(data, strb, is_last);
    end
  endtask

  task automatic wait_all_w_forwarded;
    begin
      watchdog_req = "B3";
      while (wbeat_head < wbeat_count) @(negedge clk);
    end
  endtask

  task automatic pulse_stale_r(input logic [MST_ID_W-1:0] mid);
    automatic int n;
    begin
      @(negedge clk);
      r_drive_tag_valid = 1'b0;
      r_drive_stale = 1'b1;
      m_rid = mid;
      m_rdata = 32'hDEAD_A55A;
      m_rresp = 2'b10;
      m_rlast = 1'b1;
      m_rvalid = 1'b1;
      n = 0;
      while (n < 4) begin
        @(posedge clk);
        if (m_rready) break;
        n = n + 1;
      end
      @(negedge clk);
      m_rvalid = 1'b0;
      r_drive_stale = 1'b0;
    end
  endtask

  task automatic pulse_stale_b(input logic [MST_ID_W-1:0] mid);
    automatic int n;
    begin
      @(negedge clk);
      b_drive_tag_valid = 1'b0;
      b_drive_stale = 1'b1;
      m_bid = mid;
      m_bresp = 2'b10;
      m_bvalid = 1'b1;
      n = 0;
      while (n < 4) begin
        @(posedge clk);
        if (m_bready) break;
        n = n + 1;
      end
      @(negedge clk);
      m_bvalid = 1'b0;
      b_drive_stale = 1'b0;
    end
  endtask

  // ---------------------------------------------------------------------------
  // Central checker.  Important ordering inside this block:
  //   1) master responses are recorded,
  //   2) slave responses retire transactions,
  //   3) new slave addresses are judged/accepted,
  //   4) master addresses are paired.
  // This deliberately permits A4's zero-cycle retire-and-reuse case.
  // ---------------------------------------------------------------------------
  always @(posedge clk) begin : mon_blk
    automatic integer i;
    automatic int seq_no;
    automatic int sid_i;
    automatic int mid_i;
    automatic int bidx;
    automatic int cand_count;
    automatic int cand_bidx;
    automatic int cand_seq;
    automatic int head_seq;
    automatic bit saw_later;

    cycle_no = cycle_no + 1;

    if (!rst_n) begin
      if (s_arvalid && s_arready)
        fail_req("F1", "read address accepted while reset is asserted");
      if (s_awvalid && s_awready)
        fail_req("F1", "write address accepted while reset is asserted");
      if (s_rvalid || s_bvalid)
        fail_req("F1", "slave response presented while reset is asserted");
      if (m_arvalid || m_awvalid || m_wvalid)
        fail_req("F1", "master request/data presented while reset is asserted");

      rd_distinct = 0;
      wr_distinct = 0;
      rd_fwd_head = 0;
      rd_fwd_tail = 0;
      wr_fwd_head = 0;
      wr_fwd_tail = 0;
      wr_data_head = 0;
      wr_data_tail = 0;
      rbeat_count = 0;
      bitem_count = 0;
      wbeat_count = 0;
      wbeat_head = 0;

      for (i = 0; i < SID_COUNT; i = i + 1) begin
        rd_out_cnt[i] = 0;
        wr_out_cnt[i] = 0;
        rd_sid_head[i] = 0;
        rd_sid_tail[i] = 0;
        wr_sid_head[i] = 0;
        wr_sid_tail[i] = 0;
      end
      for (i = 0; i < MID_COUNT; i = i + 1) begin
        rd_mid_owner_valid[i] = 1'b0;
        wr_mid_owner_valid[i] = 1'b0;
      end
    end else begin
      // ---- Record downstream read response beats by explicit driver bookkeeping.
      if (m_rvalid && m_rready) begin
        if (r_drive_stale) begin
          // A stale post-reset response is intentionally offered.  It must not
          // create any slave response; no expected item is enqueued here.
        end else if (!r_drive_tag_valid) begin
          fail_req("D4", "downstream read response handshake was not tied to a driven transaction");
        end else begin
          seq_no = r_drive_seq;
          if (!rd_rec[seq_no].master_seen || (m_rid != rd_rec[seq_no].mid))
            fail_req("D4", "downstream read response used a master ID not belonging to the tagged transaction");
          if (rbeat_count >= MAX_BEATS) begin
            fail_req("D4", "read-response bookkeeping overflow");
          end else begin
            rbeat_seq[rbeat_count] = seq_no;
            rbeat_data[rbeat_count] = m_rdata;
            rbeat_resp[rbeat_count] = m_rresp;
            rbeat_last[rbeat_count] = m_rlast;
            rbeat_used[rbeat_count] = 1'b0;
            rbeat_count = rbeat_count + 1;
          end
        end
      end

      // ---- Record downstream write responses by explicit driver bookkeeping.
      if (m_bvalid && m_bready) begin
        if (b_drive_stale) begin
          // Intentionally stale after reset; do not enqueue an expected response.
        end else if (!b_drive_tag_valid) begin
          fail_req("D4", "downstream write response handshake was not tied to a driven transaction");
        end else begin
          seq_no = b_drive_seq;
          if (!wr_rec[seq_no].master_seen || (m_bid != wr_rec[seq_no].mid))
            fail_req("D4", "downstream write response used a master ID not belonging to the tagged transaction");
          if (bitem_count >= MAX_TX) begin
            fail_req("D4", "write-response bookkeeping overflow");
          end else begin
            bitem_seq[bitem_count] = seq_no;
            bitem_used[bitem_count] = 1'b0;
            bitem_count = bitem_count + 1;
          end
        end
      end

      // ---- Slave read response: C1/C2, B1, D4 and E1.
      if (s_rvalid && s_rready) begin
        cand_count = 0;
        cand_bidx = -1;
        cand_seq = -1;
        saw_later = 1'b0;

        for (i = 0; i < SID_COUNT; i = i + 1) begin
          if (rd_sid_head[i] < rd_sid_tail[i]) begin
            head_seq = rd_sid_fifo[i][rd_sid_head[i]];
            bidx = first_rbeat_for_seq(head_seq);
            if (bidx >= 0) begin
              cand_count = cand_count + 1;
              cand_bidx = bidx;
              cand_seq = head_seq;
            end else if (later_rbeat_for_sid(i[SLV_ID_W-1:0], head_seq)) begin
              saw_later = 1'b1;
            end
          end
        end

        if (rd_out_cnt[s_rid] == 0)
          fail_req("C2", "slave read response carried an ID with no outstanding read transaction");

        if (reset_has_occurred && (s_rid == stale_read_sid) && (rd_out_cnt[s_rid] == 0))
          fail_req("F1", "a pre-reset read transaction produced a response after reset");

        if (cand_count == 0) begin
          if (saw_later) fail_req("B1", "later same-ID read response was released before the older transaction");
          if (any_unconsumed_rbeat())
            fail_req("D4", "slave read response did not correspond to an order-eligible master response");
          else
            fail_req("D4", "slave read response appeared without any master response to forward");
        end else if (cand_count > 1) begin
          fail_req("D4", "testbench created multiple eligible read responses; response identity became ambiguous");
        end else begin
          if (s_rid != rd_rec[cand_seq].sid)
            fail_req("C1", "slave read response restored the wrong slave ID");

          if (s_rdata != rbeat_data[cand_bidx])
            fail_req("E1", "read data changed across the converter");
          if (s_rresp != rbeat_resp[cand_bidx])
            fail_req("E1", "read response code changed across the converter");
          if (s_rlast != rbeat_last[cand_bidx])
            fail_req("E1", "read last changed across the converter");

          if (later_rbeat_for_sid(rd_rec[cand_seq].sid, cand_seq) &&
              ((s_rdata != rbeat_data[cand_bidx]) ||
               (s_rresp != rbeat_resp[cand_bidx]) ||
               (s_rlast != rbeat_last[cand_bidx])))
            fail_req("B1", "same-ID read responses were returned out of acceptance order");

          rbeat_used[cand_bidx] = 1'b1;
          rd_rec[cand_seq].slave_beats = rd_rec[cand_seq].slave_beats + 1;

          if (rbeat_last[cand_bidx]) begin
            sid_i = rd_rec[cand_seq].sid;
            rd_rec[cand_seq].done = 1'b1;
            rd_rec[cand_seq].retire_cycle = cycle_no;
            if ((rd_sid_head[sid_i] >= rd_sid_tail[sid_i]) ||
                (rd_sid_fifo[sid_i][rd_sid_head[sid_i]] != cand_seq)) begin
              fail_req("B1", "read completion was not for the oldest transaction of its slave ID");
            end else begin
              rd_sid_head[sid_i] = rd_sid_head[sid_i] + 1;
            end
            if (rd_out_cnt[sid_i] <= 0) begin
              fail_req("A1", "read outstanding count underflowed at completion");
            end else begin
              rd_out_cnt[sid_i] = rd_out_cnt[sid_i] - 1;
              if (rd_out_cnt[sid_i] == 0) begin
                rd_distinct = rd_distinct - 1;
                for (i = 0; i < MID_COUNT; i = i + 1) begin
                  if (rd_mid_owner_valid[i] && (rd_mid_owner_sid[i] == sid_i[SLV_ID_W-1:0]))
                    rd_mid_owner_valid[i] = 1'b0;
                end
              end
            end
          end
        end
      end

      // ---- Slave write response: C1/C2, B1 and D4.
      if (s_bvalid && s_bready) begin
        cand_count = 0;
        cand_bidx = -1;
        cand_seq = -1;
        saw_later = 1'b0;

        for (i = 0; i < SID_COUNT; i = i + 1) begin
          if (wr_sid_head[i] < wr_sid_tail[i]) begin
            head_seq = wr_sid_fifo[i][wr_sid_head[i]];
            bidx = first_bitem_for_seq(head_seq);
            if (bidx >= 0) begin
              cand_count = cand_count + 1;
              cand_bidx = bidx;
              cand_seq = head_seq;
            end else if (later_bitem_for_sid(i[SLV_ID_W-1:0], head_seq)) begin
              saw_later = 1'b1;
            end
          end
        end

        if (wr_out_cnt[s_bid] == 0)
          fail_req("C2", "slave write response carried an ID with no outstanding write transaction");

        if (reset_has_occurred && (s_bid == stale_write_sid) && (wr_out_cnt[s_bid] == 0))
          fail_req("F1", "a pre-reset write transaction produced a response after reset");

        if (cand_count == 0) begin
          if (saw_later) fail_req("B1", "later same-ID write response was released before the older transaction");
          if (any_unconsumed_bitem())
            fail_req("D4", "slave write response did not correspond to an order-eligible master response");
          else
            fail_req("D4", "slave write response appeared without any master response to forward");
        end else if (cand_count > 1) begin
          fail_req("D4", "testbench created multiple eligible write responses; response identity became ambiguous");
        end else begin
          if (s_bid != wr_rec[cand_seq].sid)
            fail_req("C1", "slave write response restored the wrong slave ID");

          bitem_used[cand_bidx] = 1'b1;
          sid_i = wr_rec[cand_seq].sid;
          wr_rec[cand_seq].done = 1'b1;
          wr_rec[cand_seq].retire_cycle = cycle_no;
          if ((wr_sid_head[sid_i] >= wr_sid_tail[sid_i]) ||
              (wr_sid_fifo[sid_i][wr_sid_head[sid_i]] != cand_seq)) begin
            fail_req("B1", "write completion was not for the oldest transaction of its slave ID");
          end else begin
            wr_sid_head[sid_i] = wr_sid_head[sid_i] + 1;
          end
          if (wr_out_cnt[sid_i] <= 0) begin
            fail_req("A1", "write outstanding count underflowed at completion");
          end else begin
            wr_out_cnt[sid_i] = wr_out_cnt[sid_i] - 1;
            if (wr_out_cnt[sid_i] == 0) begin
              wr_distinct = wr_distinct - 1;
              for (i = 0; i < MID_COUNT; i = i + 1) begin
                if (wr_mid_owner_valid[i] && (wr_mid_owner_sid[i] == sid_i[SLV_ID_W-1:0]))
                  wr_mid_owner_valid[i] = 1'b0;
              end
            end
          end
        end
      end

      // ---- Slave read address acceptance: A1/A2/A3/A5.
      if (s_arvalid && s_arready) begin
        if (!ar_tag_valid) begin
          fail_req("D4", "slave read address handshake was not generated by the testbench request driver");
        end else begin
          seq_no = ar_tag_seq;
          sid_i = s_arid;
          if (rd_out_cnt[sid_i] == 0) begin
            if (rd_distinct >= MAX_UNIQ_IDS) begin
              fail_req("A2", "more than MAX_UNIQ_IDS distinct read IDs became outstanding");
              fail_req("A3", "new read ID was accepted while the read table was full");
            end
            rd_distinct = rd_distinct + 1;
          end
          if (rd_out_cnt[sid_i] >= MAX_TXNS_PER_ID)
            fail_req("A5", "more than MAX_TXNS_PER_ID reads became outstanding for one slave ID");
          rd_out_cnt[sid_i] = rd_out_cnt[sid_i] + 1;
          rd_sid_fifo[sid_i][rd_sid_tail[sid_i]] = seq_no;
          rd_sid_tail[sid_i] = rd_sid_tail[sid_i] + 1;
          rd_fwd_fifo[rd_fwd_tail] = seq_no;
          rd_fwd_tail = rd_fwd_tail + 1;
          rd_rec[seq_no].accepted = 1'b1;
          rd_rec[seq_no].accept_cycle = cycle_no;
        end
      end

      // ---- Slave write address acceptance: A1/A2/A3/A5.
      if (s_awvalid && s_awready) begin
        if (!aw_tag_valid) begin
          fail_req("D4", "slave write address handshake was not generated by the testbench request driver");
        end else begin
          seq_no = aw_tag_seq;
          sid_i = s_awid;
          if (wr_out_cnt[sid_i] == 0) begin
            if (wr_distinct >= MAX_UNIQ_IDS) begin
              fail_req("A2", "more than MAX_UNIQ_IDS distinct write IDs became outstanding");
              fail_req("A3", "new write ID was accepted while the write table was full");
            end
            wr_distinct = wr_distinct + 1;
          end
          if (wr_out_cnt[sid_i] >= MAX_TXNS_PER_ID)
            fail_req("A5", "more than MAX_TXNS_PER_ID writes became outstanding for one slave ID");
          wr_out_cnt[sid_i] = wr_out_cnt[sid_i] + 1;
          wr_sid_fifo[sid_i][wr_sid_tail[sid_i]] = seq_no;
          wr_sid_tail[sid_i] = wr_sid_tail[sid_i] + 1;
          wr_fwd_fifo[wr_fwd_tail] = seq_no;
          wr_fwd_tail = wr_fwd_tail + 1;
          wr_data_fifo[wr_data_tail] = seq_no;
          wr_data_tail = wr_data_tail + 1;
          wr_rec[seq_no].accepted = 1'b1;
          wr_rec[seq_no].accept_cycle = cycle_no;
        end
      end

      // ---- Master read address: D1/D2/D4 and E1.
      if (m_arvalid && m_arready) begin
        if (rd_fwd_head >= rd_fwd_tail) begin
          fail_req("D4", "master read transaction appeared without an accepted slave read transaction");
        end else begin
          seq_no = rd_fwd_fifo[rd_fwd_head];
          rd_fwd_head = rd_fwd_head + 1;
          if (m_araddr != rd_rec[seq_no].addr)
            fail_req("E1", "read address changed across the converter");
          if (m_arlen != rd_rec[seq_no].len)
            fail_req("E1", "read length changed across the converter");
          if (rd_rec[seq_no].master_seen)
            fail_req("D4", "one slave read transaction produced more than one master read transaction");

          mid_i = m_arid;
          if (rd_mid_owner_valid[mid_i] && (rd_mid_owner_sid[mid_i] != rd_rec[seq_no].sid)) begin
            fail_req("D1", "different co-outstanding read slave IDs used the same master ID");
            fail_req("D2", "a read master ID was reused for a different slave ID before retirement");
          end
          rd_mid_owner_valid[mid_i] = 1'b1;
          rd_mid_owner_sid[mid_i] = rd_rec[seq_no].sid;
          rd_rec[seq_no].mid = m_arid;
          rd_rec[seq_no].master_seen = 1'b1;
        end
      end

      // ---- Master write address: D1/D2/D4 and E1.
      if (m_awvalid && m_awready) begin
        if (wr_fwd_head >= wr_fwd_tail) begin
          fail_req("D4", "master write transaction appeared without an accepted slave write transaction");
        end else begin
          seq_no = wr_fwd_fifo[wr_fwd_head];
          wr_fwd_head = wr_fwd_head + 1;
          if (m_awaddr != wr_rec[seq_no].addr)
            fail_req("E1", "write address changed across the converter");
          if (m_awlen != wr_rec[seq_no].len)
            fail_req("E1", "write length changed across the converter");
          if (wr_rec[seq_no].master_seen)
            fail_req("D4", "one slave write transaction produced more than one master write transaction");

          mid_i = m_awid;
          if (wr_mid_owner_valid[mid_i] && (wr_mid_owner_sid[mid_i] != wr_rec[seq_no].sid)) begin
            fail_req("D1", "different co-outstanding write slave IDs used the same master ID");
            fail_req("D2", "a write master ID was reused for a different slave ID before retirement");
          end
          wr_mid_owner_valid[mid_i] = 1'b1;
          wr_mid_owner_sid[mid_i] = wr_rec[seq_no].sid;
          wr_rec[seq_no].mid = m_awid;
          wr_rec[seq_no].master_seen = 1'b1;
        end
      end

      // ---- Slave write data bookkeeping.  AXI4 has no WID; address-order
      // bookkeeping assigns each beat to the oldest write still receiving data.
      if (s_wvalid && s_wready) begin
        if (wr_data_head >= wr_data_tail) begin
          fail_req("B3", "write data was accepted without a preceding write address");
        end else begin
          seq_no = wr_data_fifo[wr_data_head];
          if (wbeat_count >= MAX_BEATS) begin
            fail_req("B3", "write-data bookkeeping overflow");
          end else begin
            wbeat_seq[wbeat_count] = seq_no;
            wbeat_data[wbeat_count] = s_wdata;
            wbeat_strb[wbeat_count] = s_wstrb;
            wbeat_last[wbeat_count] = s_wlast;
            wbeat_used[wbeat_count] = 1'b0;
            wbeat_count = wbeat_count + 1;
          end
          if (s_wlast) wr_data_head = wr_data_head + 1;
        end
      end

      // ---- Master write data: B3 and E1.
      if (m_wvalid && m_wready) begin
        if (wbeat_head >= wbeat_count) begin
          fail_req("B3", "master write-data beat appeared before the corresponding slave beat");
        end else begin
          if (m_wdata != wbeat_data[wbeat_head])
            fail_req("E1", "write data changed across the converter");
          if (m_wstrb != wbeat_strb[wbeat_head])
            fail_req("E1", "write strobe changed across the converter");
          if (m_wlast != wbeat_last[wbeat_head]) begin
            fail_req("E1", "write last changed across the converter");
            fail_req("B3", "write transaction beat boundary changed on the master port");
          end
          wbeat_used[wbeat_head] = 1'b1;
          wbeat_head = wbeat_head + 1;
        end
      end
    end
  end

  // ---------------------------------------------------------------------------
  // Initialization and directed tests
  // ---------------------------------------------------------------------------
  initial begin : stimulus
    automatic integer i;
    automatic longint signed delta_cycles;

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

    rd_next_seq = 0;
    wr_next_seq = 0;
    errors = 0;
    cycle_no = 0;
    watchdog_req = "F1";
    ar_tag_valid = 1'b0;
    aw_tag_valid = 1'b0;
    r_drive_tag_valid = 1'b0;
    r_drive_stale = 1'b0;
    b_drive_tag_valid = 1'b0;
    b_drive_stale = 1'b0;
    reset_has_occurred = 1'b0;
    stale_read_sid = 4'hE;
    stale_write_sid = 4'hD;

    for (i = 0; i < MAX_TX; i = i + 1) begin
      rd_rec[i].allocated = 1'b0;
      wr_rec[i].allocated = 1'b0;
      bitem_used[i] = 1'b0;
    end
    for (i = 0; i < MAX_BEATS; i = i + 1) begin
      rbeat_used[i] = 1'b0;
      wbeat_used[i] = 1'b0;
    end

    // F1: while reset is asserted, actively offer address requests.  They must
    // not be accepted, and no response/request may be presented by the DUT.
    @(negedge clk);
    s_arid = 4'hF;
    s_araddr = 32'h0000_F000;
    s_arlen = 8'd0;
    s_arvalid = 1'b1;
    s_awid = 4'hF;
    s_awaddr = 32'h0000_F100;
    s_awlen = 8'd0;
    s_awvalid = 1'b1;
    repeat (3) @(posedge clk);
    @(negedge clk);
    s_arvalid = 1'b0;
    s_awvalid = 1'b0;
    stop_if_failed();

    bfm_reset(4);

    // -----------------------------------------------------------------------
    // READ SIDE: A1/A2/A3/A4, C1/C2, D1/D2/D4, E1.
    // Fill four distinct IDs.  The first read is two beats long so a non-final
    // beat can prove that A1 does not retire the identifier early.
    // -----------------------------------------------------------------------
    issue_read(4'h1, 32'h1000_0100, 8'd1, "A3", rfill[0]);
    issue_read(4'h2, 32'h1000_0200, 8'd0, "A3", rfill[1]);
    issue_read(4'h3, 32'h1000_0300, 8'd0, "A3", rfill[2]);
    issue_read(4'h4, 32'h1000_0400, 8'd0, "A3", rfill[3]);
    stop_if_failed();

    // Full table: a fifth distinct ID must be blocked (A2/A3).
    attempt_read_blocked(4'h5, 32'h1000_0500, 8'd0, "A3");
    stop_if_failed();

    // A1: a non-final read beat does not complete the transaction, therefore it
    // must not free the table entry.
    send_rbeat_only(rfill[0], 32'h1111_0001, 2'b01, 1'b0, 1'b1);
    attempt_read_blocked(4'h5, 32'h1000_0510, 8'd0, "A1");
    stop_if_failed();

    // A4: hold the new ID continuously while the old ID's final response retires.
    // Acceptance on the retirement edge is legal (delta 0); >2 cycles is not.
    prep_read(4'h5, 32'h1000_0520, 8'd0, rfill[4]);
    a4_r_acc = 1'b0;
    a4_r_wait = 0;
    watchdog_req = "A4";
    fork
      begin
        ar_tag_valid = 1'b1;
        ar_tag_seq = rfill[4];
        bfm_ar(4'h5, 32'h1000_0520, 8'd0, 1000000, a4_r_acc, a4_r_wait);
        ar_tag_valid = 1'b0;
      end
      begin
        wait (s_arvalid == 1'b1);
        send_rbeat_only(rfill[0], 32'h1111_0002, 2'b10, 1'b1, 1'b1);
      end
    join
    if (!a4_r_acc) begin
      fail_req("A4", "new read ID was not accepted after an identifier retired");
    end else begin
      delta_cycles = $signed(rd_rec[rfill[4]].accept_cycle) - $signed(rd_rec[rfill[0]].retire_cycle);
      if (delta_cycles < 0)
        fail_req("A3", "new read ID was accepted before the old identifier retired");
      if (delta_cycles > 2)
        fail_req("A4", "new read ID was accepted more than two cycles after retirement");
      wait_master_read(rfill[4]);
    end
    stop_if_failed();

    // Retire the remaining read IDs in a deliberately non-ID order.  B2 says
    // cross-ID order is free, so the checker accepts whichever ID we choose.
    send_rbeat_only(rfill[2], 32'h3333_0003, 2'b00, 1'b1, 1'b1);
    send_rbeat_only(rfill[4], 32'h5555_0005, 2'b01, 1'b1, 1'b1);
    send_rbeat_only(rfill[1], 32'h2222_0002, 2'b10, 1'b1, 1'b1);
    send_rbeat_only(rfill[3], 32'h4444_0004, 2'b00, 1'b1, 1'b1);
    stop_if_failed();

    // -----------------------------------------------------------------------
    // READ A5 and D2: two same-ID transactions are allowed, a third is blocked.
    // After one completes, another same-ID transaction may enter.  A different
    // slave ID is then admitted while the original slave ID is still outstanding;
    // any master ID ever reserved by the original ID must not be reused early.
    // -----------------------------------------------------------------------
    issue_read(4'h6, 32'h2000_0100, 8'd0, "A5", rdepth[0]);
    issue_read(4'h6, 32'h2000_0200, 8'd0, "A5", rdepth[1]);
    attempt_read_blocked(4'h6, 32'h2000_0300, 8'd0, "A5");
    stop_if_failed();

    send_rbeat_only(rdepth[0], 32'h6000_0001, 2'b00, 1'b1, 1'b1);
    issue_read(4'h6, 32'h2000_0400, 8'd0, "A5", rdepth[2]);
    issue_read(4'h8, 32'h2000_0800, 8'd0, "D2", rdepth[3]);
    stop_if_failed();

    send_rbeat_only(rdepth[1], 32'h6000_0002, 2'b01, 1'b1, 1'b1);
    send_rbeat_only(rdepth[2], 32'h6000_0003, 2'b10, 1'b1, 1'b1);
    send_rbeat_only(rdepth[3], 32'h8000_0001, 2'b00, 1'b1, 1'b1);
    stop_if_failed();

    // -----------------------------------------------------------------------
    // READ B1: if the implementation gives two same-slave-ID transactions
    // different master IDs, return the second master transaction first.  The
    // converter must hold it until the older slave transaction can complete.
    // If it chose one master ID for both, downstream AXI already imposes order.
    // -----------------------------------------------------------------------
    issue_read(4'h7, 32'h3000_0100, 8'd0, "B1", rord[0]);
    issue_read(4'h7, 32'h3000_0200, 8'd0, "B1", rord[1]);
    stop_if_failed();

    if (rd_rec[rord[0]].mid != rd_rec[rord[1]].mid) begin
      send_rbeat_only(rord[1], 32'h7777_0002, 2'b10, 1'b1, 1'b0);
      repeat (2) @(posedge clk);
      @(negedge clk);
      stop_if_failed();
      send_rbeat_only(rord[0], 32'h7777_0001, 2'b01, 1'b1, 1'b1);
      wait_read_done(rord[1]);
    end else begin
      send_rbeat_only(rord[0], 32'h7777_0001, 2'b01, 1'b1, 1'b1);
      send_rbeat_only(rord[1], 32'h7777_0002, 2'b10, 1'b1, 1'b1);
    end
    stop_if_failed();

    // -----------------------------------------------------------------------
    // WRITE SIDE: A1/A2/A3/A4, C1/C2, D1/D2/D4, E1 and B3.
    // -----------------------------------------------------------------------
    issue_write(4'h1, 32'h4000_0100, 8'd0, "A3", wfill[0]);
    send_write_beat(32'hA100_0001, 4'b1111, 1'b1);
    issue_write(4'h2, 32'h4000_0200, 8'd0, "A3", wfill[1]);
    send_write_beat(32'hA200_0002, 4'b0111, 1'b1);
    issue_write(4'h3, 32'h4000_0300, 8'd0, "A3", wfill[2]);
    send_write_beat(32'hA300_0003, 4'b0011, 1'b1);
    issue_write(4'h4, 32'h4000_0400, 8'd0, "A3", wfill[3]);
    send_write_beat(32'hA400_0004, 4'b0001, 1'b1);
    wait_all_w_forwarded();
    stop_if_failed();

    // W completion does not retire a write; only B does (A1).
    attempt_write_blocked(4'h5, 32'h4000_0500, 8'd0, "A1");
    stop_if_failed();

    // A4 write retirement/reuse window.
    prep_write(4'h5, 32'h4000_0520, 8'd0, wfill[4]);
    a4_w_acc = 1'b0;
    a4_w_wait = 0;
    watchdog_req = "A4";
    fork
      begin
        aw_tag_valid = 1'b1;
        aw_tag_seq = wfill[4];
        bfm_aw(4'h5, 32'h4000_0520, 8'd0, 1000000, a4_w_acc, a4_w_wait);
        aw_tag_valid = 1'b0;
      end
      begin
        wait (s_awvalid == 1'b1);
        send_bitem_only(wfill[0], 2'b01, 1'b1);
      end
    join
    if (!a4_w_acc) begin
      fail_req("A4", "new write ID was not accepted after an identifier retired");
    end else begin
      delta_cycles = $signed(wr_rec[wfill[4]].accept_cycle) - $signed(wr_rec[wfill[0]].retire_cycle);
      if (delta_cycles < 0)
        fail_req("A3", "new write ID was accepted before the old identifier retired");
      if (delta_cycles > 2)
        fail_req("A4", "new write ID was accepted more than two cycles after retirement");
      wait_master_write(wfill[4]);
      send_write_beat(32'hA500_0005, 4'b1011, 1'b1);
      wait_all_w_forwarded();
    end
    stop_if_failed();

    send_bitem_only(wfill[2], 2'b00, 1'b1);
    send_bitem_only(wfill[4], 2'b10, 1'b1);
    send_bitem_only(wfill[1], 2'b01, 1'b1);
    send_bitem_only(wfill[3], 2'b00, 1'b1);
    stop_if_failed();

    // WRITE A5 and D2.
    issue_write(4'h6, 32'h5000_0100, 8'd0, "A5", wdepth[0]);
    send_write_beat(32'hB600_0001, 4'b1111, 1'b1);
    issue_write(4'h6, 32'h5000_0200, 8'd0, "A5", wdepth[1]);
    send_write_beat(32'hB600_0002, 4'b1101, 1'b1);
    wait_all_w_forwarded();
    attempt_write_blocked(4'h6, 32'h5000_0300, 8'd0, "A5");
    stop_if_failed();

    send_bitem_only(wdepth[0], 2'b00, 1'b1);
    issue_write(4'h6, 32'h5000_0400, 8'd0, "A5", wdepth[2]);
    send_write_beat(32'hB600_0003, 4'b1011, 1'b1);
    issue_write(4'h8, 32'h5000_0800, 8'd0, "D2", wdepth[3]);
    send_write_beat(32'hB800_0001, 4'b0111, 1'b1);
    wait_all_w_forwarded();
    stop_if_failed();

    send_bitem_only(wdepth[1], 2'b01, 1'b1);
    send_bitem_only(wdepth[2], 2'b10, 1'b1);
    send_bitem_only(wdepth[3], 2'b00, 1'b1);
    stop_if_failed();

    // WRITE B1: the second response must not be exposed before the first master
    // response exists.  (BRESP payload itself is not constrained by E1.)
    issue_write(4'h7, 32'h6000_0100, 8'd0, "B1", worder[0]);
    send_write_beat(32'hC700_0001, 4'b1111, 1'b1);
    issue_write(4'h7, 32'h6000_0200, 8'd0, "B1", worder[1]);
    send_write_beat(32'hC700_0002, 4'b1111, 1'b1);
    wait_all_w_forwarded();
    stop_if_failed();

    if (wr_rec[worder[0]].mid != wr_rec[worder[1]].mid) begin
      send_bitem_only(worder[1], 2'b10, 1'b0);
      repeat (2) @(posedge clk);
      @(negedge clk);
      stop_if_failed();
      send_bitem_only(worder[0], 2'b01, 1'b1);
      wait_write_done(worder[1]);
    end else begin
      send_bitem_only(worder[0], 2'b01, 1'b1);
      send_bitem_only(worder[1], 2'b10, 1'b1);
    end
    stop_if_failed();

    // B3 + E1: two writes, with a two-beat first transaction, verify master W
    // stream is exactly the slave W stream and transaction beats are not mixed.
    issue_write(4'h9, 32'h7000_0100, 8'd1, "B3", wmulti[0]);
    issue_write(4'hA, 32'h7000_0200, 8'd0, "B3", wmulti[1]);
    send_write_beat(32'hD900_0001, 4'b1111, 1'b0);
    send_write_beat(32'hD900_0002, 4'b1010, 1'b1);
    send_write_beat(32'hDA00_0001, 4'b0101, 1'b1);
    wait_all_w_forwarded();
    stop_if_failed();
    send_bitem_only(wmulti[0], 2'b00, 1'b1);
    send_bitem_only(wmulti[1], 2'b00, 1'b1);
    stop_if_failed();

    // -----------------------------------------------------------------------
    // F1 mid-stream reset: create one outstanding read and one outstanding
    // write, then reset before either response returns.  After release, stale
    // downstream responses are offered.  They must never create slave responses.
    // -----------------------------------------------------------------------
    issue_read(stale_read_sid, 32'h8000_0E00, 8'd0, "F1", rpre);
    issue_write(stale_write_sid, 32'h8000_0D00, 8'd0, "F1", wpre);
    send_write_beat(32'hE0D0_0001, 4'b1111, 1'b1);
    wait_all_w_forwarded();
    stop_if_failed();

    bfm_reset(4);
    reset_has_occurred = 1'b1;

    pulse_stale_r(rd_rec[rpre].mid);
    pulse_stale_b(wr_rec[wpre].mid);
    repeat (4) @(posedge clk);
    @(negedge clk);
    stop_if_failed();

    // After reset the table is empty again.  Demonstrate four fresh distinct
    // read IDs can occupy it, retire them, then do the same on the write side.
    issue_read(4'h1, 32'h9000_0100, 8'd0, "F1", rpost[0]);
    issue_read(4'h2, 32'h9000_0200, 8'd0, "F1", rpost[1]);
    issue_read(4'h3, 32'h9000_0300, 8'd0, "F1", rpost[2]);
    issue_read(4'h4, 32'h9000_0400, 8'd0, "F1", rpost[3]);
    stop_if_failed();
    send_rbeat_only(rpost[0], 32'h9100_0001, 2'b00, 1'b1, 1'b1);
    send_rbeat_only(rpost[1], 32'h9200_0002, 2'b00, 1'b1, 1'b1);
    send_rbeat_only(rpost[2], 32'h9300_0003, 2'b00, 1'b1, 1'b1);
    send_rbeat_only(rpost[3], 32'h9400_0004, 2'b00, 1'b1, 1'b1);
    stop_if_failed();

    issue_write(4'h1, 32'hA000_0100, 8'd0, "F1", wpost[0]);
    send_write_beat(32'hA100_1001, 4'b1111, 1'b1);
    issue_write(4'h2, 32'hA000_0200, 8'd0, "F1", wpost[1]);
    send_write_beat(32'hA200_1002, 4'b1111, 1'b1);
    issue_write(4'h3, 32'hA000_0300, 8'd0, "F1", wpost[2]);
    send_write_beat(32'hA300_1003, 4'b1111, 1'b1);
    issue_write(4'h4, 32'hA000_0400, 8'd0, "F1", wpost[3]);
    send_write_beat(32'hA400_1004, 4'b1111, 1'b1);
    wait_all_w_forwarded();
    stop_if_failed();
    send_bitem_only(wpost[0], 2'b00, 1'b1);
    send_bitem_only(wpost[1], 2'b00, 1'b1);
    send_bitem_only(wpost[2], 2'b00, 1'b1);
    send_bitem_only(wpost[3], 2'b00, 1'b1);
    stop_if_failed();

    // Brief quiescent drain catches duplicated/stray late outputs without
    // imposing any latency requirement on a transaction that is still pending.
    repeat (10) @(posedge clk);
    @(negedge clk);
    stop_if_failed();

    @(negedge clk);
    if (errors == 0)
      $display("RESULT: PASS");
    else
      $display("RESULT: FAIL");
    $finish;
  end

  // G1 watchdog.  It always terminates the simulation, even if a faulty DUT
  // permanently withholds a handshake.  The final line remains exactly one of
  // the required RESULT strings.
  initial begin
    #4_000_000;
    $display("%s: FAIL - watchdog: no forward progress", watchdog_req);
    $display("RESULT: FAIL");
    $finish;
  end

endmodule