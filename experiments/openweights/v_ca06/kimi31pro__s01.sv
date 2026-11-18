`timescale 1ns/1ps

module id_width_conv_tb;

  localparam int unsigned ADDR_W     = 32;
  localparam int unsigned ID_W       = 4;
  localparam int unsigned SLV_DATA_W = 64;
  localparam int unsigned MST_DATA_W = 16;
  localparam int unsigned MAX_READS  = 4;

  localparam logic [1:0] RESP_OKAY   = 2'b00;
  localparam logic [1:0] RESP_SLVERR = 2'b10;
  localparam logic [1:0] RESP_DECERR = 2'b11;
  localparam logic [1:0] BURST_FIXED = 2'b00;
  localparam logic [1:0] BURST_INCR  = 2'b01;
  localparam logic [1:0] BURST_WRAP  = 2'b10;

  logic clk;
  logic rst_n;

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

  initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
  end

  int errors       = 0;
  bit finished     = 0;
  int reset_pedges = 0;

  int m_aw_count = 0;
  int m_w_count  = 0;
  int m_ar_count = 0;
  int s_b_count  = 0;
  int s_r_count  = 0;

  task automatic note_fail(input string requirement, input string message);
    begin
      errors = errors + 1;
      if (errors <= 100)
        $display("%s: %s", requirement, message);
    end
  endtask

  function automatic logic [31:0] align_addr(
    input logic [31:0] addr,
    input int          size
  );
    logic [31:0] mask;
    begin
      mask = (32'h1 << size) - 1;
      align_addr = addr & ~mask;
    end
  endfunction

  function automatic logic [7:0] rd_byte(input logic [31:0] addr);
    begin
      rd_byte = addr[7:0] ^ 8'ha5;
    end
  endfunction

  function automatic logic [7:0] wr_byte(input logic [31:0] addr);
    begin
      wr_byte = addr[7:0] + 8'h3c;
    end
  endfunction

  task automatic bfm_reset(input int cycles);
    begin
      @(negedge clk);
      rst_n = 1'b0;
      repeat (cycles) @(posedge clk);
      @(negedge clk);
      rst_n = 1'b1;
    end
  endtask

  task automatic bfm_ar(
    input  logic [ID_W-1:0]   id,
    input  logic [ADDR_W-1:0] addr,
    input  logic [7:0]        len,
    input  logic [2:0]        size,
    input  logic [1:0]        burst,
    input  int                budget,
    output bit                accepted,
    output int                waited
  );
    begin
      accepted = 1'b0;
      waited = 0;
      @(negedge clk);
      s_arid = id;
      s_araddr = addr;
      s_arlen = len;
      s_arsize = size;
      s_arburst = burst;
      s_arvalid = 1'b1;
      while (waited < budget) begin
        @(posedge clk);
        if (s_arready === 1'b1) begin
          accepted = 1'b1;
          break;
        end
        waited = waited + 1;
      end
      @(negedge clk);
      s_arvalid = 1'b0;
    end
  endtask

  task automatic bfm_aw(
    input  logic [ID_W-1:0]   id,
    input  logic [ADDR_W-1:0] addr,
    input  logic [7:0]        len,
    input  logic [2:0]        size,
    input  logic [1:0]        burst,
    input  int                budget,
    output bit                accepted,
    output int                waited
  );
    begin
      accepted = 1'b0;
      waited = 0;
      @(negedge clk);
      s_awid = id;
      s_awaddr = addr;
      s_awlen = len;
      s_awsize = size;
      s_awburst = burst;
      s_awvalid = 1'b1;
      while (waited < budget) begin
        @(posedge clk);
        if (s_awready === 1'b1) begin
          accepted = 1'b1;
          break;
        end
        waited = waited + 1;
      end
      @(negedge clk);
      s_awvalid = 1'b0;
    end
  endtask

  task automatic bfm_w(
    input  logic [SLV_DATA_W-1:0]   data,
    input  logic [SLV_DATA_W/8-1:0] strb,
    input  logic                    last,
    input  int                      budget,
    output bit                      accepted
  );
    int waited;
    begin
      accepted = 1'b0;
      waited = 0;
      @(negedge clk);
      s_wdata = data;
      s_wstrb = strb;
      s_wlast = last;
      s_wvalid = 1'b1;
      while (waited < budget) begin
        @(posedge clk);
        if (s_wready === 1'b1) begin
          accepted = 1'b1;
          break;
        end
        waited = waited + 1;
      end
      @(negedge clk);
      s_wvalid = 1'b0;
    end
  endtask

  task automatic bfm_rbeat(
    input  logic [ID_W-1:0]       id,
    input  logic [MST_DATA_W-1:0] data,
    input  logic                  last,
    input  logic [1:0]            resp,
    input  int                    budget,
    output bit                    accepted
  );
    int waited;
    begin
      accepted = 1'b0;
      waited = 0;
      @(negedge clk);
      m_rid = id;
      m_rdata = data;
      m_rlast = last;
      m_rresp = resp;
      m_rvalid = 1'b1;
      while (waited < budget) begin
        @(posedge clk);
        if (m_rready === 1'b1) begin
          accepted = 1'b1;
          break;
        end
        waited = waited + 1;
      end
      @(negedge clk);
      m_rvalid = 1'b0;
    end
  endtask

  task automatic bfm_bbeat(
    input  logic [ID_W-1:0] id,
    input  logic [1:0]      resp,
    input  int              budget,
    output bit              accepted
  );
    int waited;
    begin
      accepted = 1'b0;
      waited = 0;
      @(negedge clk);
      m_bid = id;
      m_bresp = resp;
      m_bvalid = 1'b1;
      while (waited < budget) begin
        @(posedge clk);
        if (m_bready === 1'b1) begin
          accepted = 1'b1;
          break;
        end
        waited = waited + 1;
      end
      @(negedge clk);
      m_bvalid = 1'b0;
    end
  endtask

  task automatic take_m_ar(
    input  int                budget,
    output logic [ID_W-1:0]   id,
    output logic [ADDR_W-1:0] addr,
    output logic [7:0]        len,
    output logic [2:0]        size,
    output logic [1:0]        burst,
    output bit                found
  );
    int k;
    begin
      found = 1'b0;
      id = '0;
      addr = '0;
      len = '0;
      size = '0;
      burst = '0;
      for (k = 0; k < budget; k = k + 1) begin
        @(posedge clk);
        if ((m_arvalid === 1'b1) && (m_arready === 1'b1)) begin
          id = m_arid;
          addr = m_araddr;
          len = m_arlen;
          size = m_arsize;
          burst = m_arburst;
          found = 1'b1;
          break;
        end
      end
    end
  endtask

  task automatic take_m_aw(
    input  int                budget,
    output logic [ID_W-1:0]   id,
    output logic [ADDR_W-1:0] addr,
    output logic [7:0]        len,
    output logic [2:0]        size,
    output logic [1:0]        burst,
    output bit                found
  );
    int k;
    begin
      found = 1'b0;
      id = '0;
      addr = '0;
      len = '0;
      size = '0;
      burst = '0;
      for (k = 0; k < budget; k = k + 1) begin
        @(posedge clk);
        if ((m_awvalid === 1'b1) && (m_awready === 1'b1)) begin
          id = m_awid;
          addr = m_awaddr;
          len = m_awlen;
          size = m_awsize;
          burst = m_awburst;
          found = 1'b1;
          break;
        end
      end
    end
  endtask

  task automatic take_m_w(
    input  int                      budget,
    output logic [MST_DATA_W-1:0]   data,
    output logic [MST_DATA_W/8-1:0] strb,
    output logic                    last,
    output bit                      found
  );
    int k;
    begin
      found = 1'b0;
      data = '0;
      strb = '0;
      last = 1'b0;
      for (k = 0; k < budget; k = k + 1) begin
        @(posedge clk);
        if ((m_wvalid === 1'b1) && (m_wready === 1'b1)) begin
          data = m_wdata;
          strb = m_wstrb;
          last = m_wlast;
          found = 1'b1;
          break;
        end
      end
    end
  endtask

  task automatic take_s_r(
    input  int                      budget,
    output logic [ID_W-1:0]         id,
    output logic [SLV_DATA_W-1:0]   data,
    output logic [1:0]              resp,
    output logic                    last,
    output bit                      found
  );
    int k;
    begin
      found = 1'b0;
      id = '0;
      data = '0;
      resp = '0;
      last = 1'b0;
      for (k = 0; k < budget; k = k + 1) begin
        @(posedge clk);
        if ((s_rvalid === 1'b1) && (s_rready === 1'b1)) begin
          id = s_rid;
          data = s_rdata;
          resp = s_rresp;
          last = s_rlast;
          found = 1'b1;
          break;
        end
      end
    end
  endtask

  task automatic take_s_b(
    input  int              budget,
    output logic [ID_W-1:0] id,
    output logic [1:0]      resp,
    output bit              found
  );
    int k;
    begin
      found = 1'b0;
      id = '0;
      resp = '0;
      for (k = 0; k < budget; k = k + 1) begin
        @(posedge clk);
        if ((s_bvalid === 1'b1) && (s_bready === 1'b1)) begin
          id = s_bid;
          resp = s_bresp;
          found = 1'b1;
          break;
        end
      end
    end
  endtask

  always @(posedge clk) begin
    if (!rst_n) begin
      reset_pedges <= reset_pedges + 1;
    end else begin
      reset_pedges <= 0;
      if ((m_awvalid === 1'b1) && (m_awready === 1'b1))
        m_aw_count <= m_aw_count + 1;
      if ((m_wvalid === 1'b1) && (m_wready === 1'b1))
        m_w_count <= m_w_count + 1;
      if ((m_arvalid === 1'b1) && (m_arready === 1'b1))
        m_ar_count <= m_ar_count + 1;
      if ((s_bvalid === 1'b1) && (s_bready === 1'b1))
        s_b_count <= s_b_count + 1;
      if ((s_rvalid === 1'b1) && (s_rready === 1'b1))
        s_r_count <= s_r_count + 1;
    end
  end

  // Sample away from the rising edge, and only after reset has had a rising
  // edge at which asynchronous-reset state is certain to have been established.
  always @(negedge clk) begin
    if (!rst_n && (reset_pedges > 0)) begin
      if (s_bvalid !== 1'b0)
        note_fail("F1", "s_bvalid was not low during reset");
      if (s_rvalid !== 1'b0)
        note_fail("F1", "s_rvalid was not low during reset");
      if (m_awvalid !== 1'b0)
        note_fail("F1", "m_awvalid was not low during reset");
      if (m_wvalid !== 1'b0)
        note_fail("F1", "m_wvalid was not low during reset");
      if (m_arvalid !== 1'b0)
        note_fail("F1", "m_arvalid was not low during reset");
    end
  end

  task automatic do_read(
    input string          tag,
    input logic [3:0]     id,
    input logic [31:0]    addr,
    input logic [7:0]     len,
    input logic [2:0]     size,
    input logic [1:0]     burst,
    input bit             refused,
    input int             error_beat,
    input logic [1:0]     error_code
  );
    int up_n;
    int up_bytes;
    int total_bytes;
    int dsize;
    int dbytes;
    int dlen;
    int d_n;
    logic [31:0] al_up;
    logic [31:0] al_first;
    logic [31:0] al_last;
    logic [31:0] last_addr;

    bit accepted;
    int waited;
    bit cap_ok;
    bit resp_ok;
    bit send_ok;

    logic [3:0]  cap_id;
    logic [31:0] cap_addr;
    logic [7:0]  cap_len;
    logic [2:0]  cap_size;
    logic [1:0]  cap_burst;

    logic [3:0]  got_rid;
    logic [63:0] got_rdata;
    logic [1:0]  got_rresp;
    logic        got_rlast;

    int before_ar;
    int before_aw;
    int before_w;
    int before_r;

    int db_send;
    int lane_send;
    logic [31:0] base_send;
    logic [15:0] send_data;
    logic [1:0] send_resp;

    int ub;
    int db_chk;
    int a_chk;
    logic [31:0] ubase;
    logic [31:0] uend;
    logic [31:0] dbase;
    bit err_seen;
    logic [1:0] exp_resp;
    logic [7:0] got_byte;
    logic exp_last;

    begin
      up_n = len;
      up_n = up_n + 1;
      up_bytes = 1 << size;
      al_up = align_addr(addr, size);
      total_bytes = up_n * up_bytes - (addr - al_up);
      last_addr = addr + total_bytes - 1;

      dsize = (size > 1) ? 1 : size;
      dbytes = 1 << dsize;
      al_first = align_addr(addr, dsize);
      al_last = align_addr(last_addr, dsize);
      dlen = (al_last - al_first) / dbytes;
      d_n = dlen + 1;

      @(negedge clk);
      before_ar = m_ar_count;
      before_aw = m_aw_count;
      before_w = m_w_count;
      before_r = s_r_count;

      fork
        begin
          bfm_ar(id, addr, len, size, burst, 1000, accepted, waited);
          if (!accepted) begin
            if (refused)
              note_fail("C4", $sformatf("%s: refused read address was not accepted", tag));
            else
              note_fail("A1", $sformatf("%s: read address was not accepted", tag));
          end
        end

        begin
          if (!refused) begin
            take_m_ar(1000, cap_id, cap_addr, cap_len, cap_size,
                      cap_burst, cap_ok);
            if (!cap_ok) begin
              note_fail("A2", $sformatf("%s: no downstream read address", tag));
            end else begin
              if (cap_id !== id)
                note_fail("A2", $sformatf("%s: downstream id %h expected %h",
                                          tag, cap_id, id));
              if (cap_addr !== addr)
                note_fail("B3", $sformatf("%s: downstream addr %h expected %h",
                                          tag, cap_addr, addr));
              if (cap_size !== dsize[2:0])
                note_fail("B1", $sformatf("%s: downstream size %0d expected %0d",
                                          tag, cap_size, dsize));
              if (cap_len !== dlen[7:0])
                note_fail("B2", $sformatf("%s: downstream len %0d expected %0d",
                                          tag, cap_len, dlen));
              // L6: deliberately do not inspect burst for a one-beat burst.
              if ((dlen > 0) && (cap_burst !== BURST_INCR))
                note_fail("B4", $sformatf("%s: multi-beat downstream burst was %b",
                                          tag, cap_burst));

              for (db_send = 0; db_send < d_n; db_send = db_send + 1) begin
                base_send = al_first + db_send * dbytes;
                send_data = 16'h0000;
                for (lane_send = 0; lane_send < 2;
                     lane_send = lane_send + 1) begin
                  send_data[lane_send*8 +: 8] =
                    rd_byte((base_send & 32'hffff_fffe) + lane_send);
                end
                if (db_send == error_beat)
                  send_resp = error_code;
                else
                  send_resp = RESP_OKAY;
                bfm_rbeat(id, send_data, (db_send == d_n-1), send_resp,
                          1000, send_ok);
                if (!send_ok)
                  note_fail("D1", $sformatf("%s: downstream R beat %0d was not accepted",
                                            tag, db_send));
              end
            end
          end
        end

        begin
          err_seen = 1'b0;
          for (ub = 0; ub < up_n; ub = ub + 1) begin
            take_s_r(1500, got_rid, got_rdata, got_rresp, got_rlast, resp_ok);
            if (!resp_ok) begin
              if (refused)
                note_fail("C4", $sformatf("%s: missing refused upstream R beat %0d",
                                          tag, ub));
              else
                note_fail("A3", $sformatf("%s: missing upstream R beat %0d",
                                          tag, ub));
              break;
            end else begin
              if (got_rid !== id)
                note_fail("D3", $sformatf("%s: R id %h expected %h",
                                          tag, got_rid, id));

              exp_last = (ub == up_n-1);
              if (got_rlast !== exp_last)
                note_fail("D4", $sformatf("%s: R beat %0d last=%b expected %b",
                                          tag, ub, got_rlast, exp_last));

              if (ub == 0) begin
                ubase = addr;
                uend = al_up + up_bytes - 1;
              end else begin
                ubase = al_up + ub * up_bytes;
                uend = ubase + up_bytes - 1;
              end
              if (uend > last_addr)
                uend = last_addr;

              if (refused) begin
                exp_resp = RESP_SLVERR;
              end else begin
                for (db_chk = 0; db_chk < d_n; db_chk = db_chk + 1) begin
                  dbase = al_first + db_chk * dbytes;
                  if ((db_chk == error_beat) &&
                      (dbase <= uend) &&
                      ((dbase + dbytes - 1) >= ubase))
                    err_seen = 1'b1;
                end
                exp_resp = err_seen ? error_code : RESP_OKAY;
              end

              if (got_rresp !== exp_resp) begin
                if (refused)
                  note_fail("C4", $sformatf("%s: refused R beat %0d resp=%b expected SLVERR",
                                            tag, ub, got_rresp));
                else if (error_beat < 0)
                  note_fail("D5", $sformatf("%s: R beat %0d resp=%b expected OKAY",
                                            tag, ub, got_rresp));
                else
                  note_fail("D6/D7", $sformatf("%s: R beat %0d resp=%b expected %b",
                                               tag, ub, got_rresp, exp_resp));
              end

              if (!refused) begin
                for (a_chk = ubase; a_chk <= uend; a_chk = a_chk + 1) begin
                  got_byte = got_rdata >> ((a_chk & 7) * 8);
                  if (got_byte !== rd_byte(a_chk))
                    note_fail("D1/D2",
                      $sformatf("%s: address %h lane %0d data %h expected %h",
                                tag, a_chk, (a_chk & 7), got_byte,
                                rd_byte(a_chk)));
                end
              end
            end
          end
        end
      join

      repeat (4) @(negedge clk);

      if ((s_r_count - before_r) != up_n) begin
        if (refused)
          note_fail("C4", $sformatf("%s: refused read produced %0d R beats, expected %0d",
                                    tag, s_r_count-before_r, up_n));
        else
          note_fail("A3", $sformatf("%s: produced %0d R beats, expected %0d",
                                    tag, s_r_count-before_r, up_n));
      end

      if (refused) begin
        if ((m_ar_count != before_ar) ||
            (m_aw_count != before_aw) ||
            (m_w_count != before_w))
          note_fail("C4", $sformatf("%s: refused read caused downstream activity", tag));
      end else begin
        if ((m_ar_count - before_ar) != 1)
          note_fail("A2", $sformatf("%s: downstream AR count delta %0d expected 1",
                                    tag, m_ar_count-before_ar));
        if ((m_aw_count != before_aw) || (m_w_count != before_w))
          note_fail("A2", $sformatf("%s: read caused downstream write activity", tag));
      end
    end
  endtask

  task automatic do_write(
    input string       tag,
    input logic [3:0]  id,
    input logic [31:0] addr,
    input logic [7:0]  len,
    input logic [2:0]  size,
    input logic [1:0]  burst,
    input bit          refused,
    input int          strb_mode,
    input logic [1:0]  downstream_bresp
  );
    int up_n;
    int up_bytes;
    int total_bytes;
    int dsize;
    int dbytes;
    int dlen;
    int d_n;
    logic [31:0] al_up;
    logic [31:0] al_first;
    logic [31:0] al_last;
    logic [31:0] last_addr;

    bit accepted;
    int waited;
    bit w_ok;
    bit cap_ok;
    bit wall_ok;
    bit wcap_ok;
    bit b_ok;
    bit bsend_ok;

    logic [3:0]  cap_id;
    logic [31:0] cap_addr;
    logic [7:0]  cap_len;
    logic [2:0]  cap_size;
    logic [1:0]  cap_burst;

    logic [15:0] got_wdata;
    logic [1:0]  got_wstrb;
    logic        got_wlast;
    logic [3:0]  got_bid;
    logic [1:0]  got_bresp;

    int before_ar;
    int before_aw;
    int before_w;
    int before_b;

    int ub_snd;
    int a_snd;
    int lane_snd;
    logic [31:0] base_snd;
    logic [31:0] end_snd;
    logic [63:0] up_wdata;
    logic [7:0]  up_wstrb;
    bit live_snd;

    int db_cap;
    int lane_cap;
    int lane_up;
    int a_cap;
    logic [31:0] base_cap;
    logic [1:0] exp_wstrb;
    bit live_cap;
    logic [7:0] got_byte;
    logic [1:0] exp_bresp;

    begin
      up_n = len;
      up_n = up_n + 1;
      up_bytes = 1 << size;
      al_up = align_addr(addr, size);
      total_bytes = up_n * up_bytes - (addr - al_up);
      last_addr = addr + total_bytes - 1;

      dsize = (size > 1) ? 1 : size;
      dbytes = 1 << dsize;
      al_first = align_addr(addr, dsize);
      al_last = align_addr(last_addr, dsize);
      dlen = (al_last - al_first) / dbytes;
      d_n = dlen + 1;

      @(negedge clk);
      before_ar = m_ar_count;
      before_aw = m_aw_count;
      before_w = m_w_count;
      before_b = s_b_count;

      fork
        begin
          bfm_aw(id, addr, len, size, burst, 1000, accepted, waited);
          if (!accepted) begin
            if (refused)
              note_fail("C4", $sformatf("%s: refused write address was not accepted", tag));
            else
              note_fail("A1", $sformatf("%s: write address was not accepted", tag));
          end

          for (ub_snd = 0; ub_snd < up_n; ub_snd = ub_snd + 1) begin
            if (ub_snd == 0) begin
              base_snd = addr;
              end_snd = al_up + up_bytes - 1;
            end else begin
              base_snd = al_up + ub_snd * up_bytes;
              end_snd = base_snd + up_bytes - 1;
            end
            if (end_snd > last_addr)
              end_snd = last_addr;

            up_wdata = 64'h0;
            up_wstrb = 8'h00;
            for (a_snd = base_snd; a_snd <= end_snd; a_snd = a_snd + 1) begin
              lane_snd = a_snd & 7;
              up_wdata[lane_snd*8 +: 8] = wr_byte(a_snd);
              live_snd = 1'b1;
              if ((strb_mode == 1) && (up_bytes == 8))
                live_snd = ((lane_snd == 0) || (lane_snd == 7));
              else if ((strb_mode == 2) && (up_bytes == 8))
                live_snd = (lane_snd < 4);
              if (live_snd)
                up_wstrb[lane_snd] = 1'b1;
            end

            bfm_w(up_wdata, up_wstrb, (ub_snd == up_n-1), 1000, w_ok);
            if (!w_ok) begin
              if (refused)
                note_fail("C4", $sformatf("%s: refused W beat %0d was not absorbed",
                                          tag, ub_snd));
              else
                note_fail("E1", $sformatf("%s: upstream W beat %0d was not accepted",
                                          tag, ub_snd));
            end
          end
        end

        begin
          if (!refused) begin
            wall_ok = 1'b1;
            fork
              begin
                take_m_aw(1000, cap_id, cap_addr, cap_len, cap_size,
                          cap_burst, cap_ok);
                if (!cap_ok) begin
                  note_fail("A2", $sformatf("%s: no downstream write address", tag));
                end else begin
                  if (cap_id !== id)
                    note_fail("A2", $sformatf("%s: downstream AW id %h expected %h",
                                              tag, cap_id, id));
                  if (cap_addr !== addr)
                    note_fail("B3", $sformatf("%s: downstream AW addr %h expected %h",
                                              tag, cap_addr, addr));
                  if (cap_size !== dsize[2:0])
                    note_fail("B1", $sformatf("%s: downstream AW size %0d expected %0d",
                                              tag, cap_size, dsize));
                  if (cap_len !== dlen[7:0])
                    note_fail("B2", $sformatf("%s: downstream AW len %0d expected %0d",
                                              tag, cap_len, dlen));
                  if ((dlen > 0) && (cap_burst !== BURST_INCR))
                    note_fail("B4", $sformatf("%s: multi-beat downstream AW burst was %b",
                                              tag, cap_burst));
                end
              end

              begin
                for (db_cap = 0; db_cap < d_n; db_cap = db_cap + 1) begin
                  take_m_w(1200, got_wdata, got_wstrb, got_wlast, wcap_ok);
                  if (!wcap_ok) begin
                    note_fail("E3", $sformatf("%s: missing downstream W beat %0d",
                                              tag, db_cap));
                    wall_ok = 1'b0;
                    break;
                  end else begin
                    base_cap = al_first + db_cap * dbytes;
                    exp_wstrb = 2'b00;

                    for (lane_cap = 0; lane_cap < 2;
                         lane_cap = lane_cap + 1) begin
                      a_cap = (base_cap & 32'hffff_fffe) + lane_cap;
                      live_cap = 1'b0;
                      if ((a_cap >= base_cap) &&
                          (a_cap < (base_cap + dbytes)) &&
                          (a_cap >= addr) &&
                          (a_cap <= last_addr)) begin
                        lane_up = a_cap & 7;
                        live_cap = 1'b1;
                        if ((strb_mode == 1) && (up_bytes == 8))
                          live_cap = ((lane_up == 0) || (lane_up == 7));
                        else if ((strb_mode == 2) && (up_bytes == 8))
                          live_cap = (lane_up < 4);
                      end
                      if (live_cap)
                        exp_wstrb[lane_cap] = 1'b1;
                    end

                    if (got_wstrb !== exp_wstrb)
                      note_fail("E2/E3",
                        $sformatf("%s: W beat %0d strb=%b expected %b",
                                  tag, db_cap, got_wstrb, exp_wstrb));

                    for (lane_cap = 0; lane_cap < 2;
                         lane_cap = lane_cap + 1) begin
                      if (exp_wstrb[lane_cap]) begin
                        a_cap = (base_cap & 32'hffff_fffe) + lane_cap;
                        got_byte = got_wdata >> (lane_cap * 8);
                        if (got_byte !== wr_byte(a_cap))
                          note_fail("E1",
                            $sformatf("%s: W beat %0d lane %0d data %h expected %h",
                                      tag, db_cap, lane_cap, got_byte,
                                      wr_byte(a_cap)));
                      end
                    end

                    if (got_wlast !== (db_cap == d_n-1))
                      note_fail("E4",
                        $sformatf("%s: W beat %0d last=%b expected %b",
                                  tag, db_cap, got_wlast, (db_cap == d_n-1)));
                  end
                end
              end
            join

            if (cap_ok && wall_ok) begin
              bfm_bbeat(id, downstream_bresp, 1000, bsend_ok);
              if (!bsend_ok)
                note_fail("E5", $sformatf("%s: downstream B was not accepted", tag));
            end
          end
        end

        begin
          take_s_b(1800, got_bid, got_bresp, b_ok);
          if (!b_ok) begin
            if (refused)
              note_fail("C4", $sformatf("%s: refused write produced no B", tag));
            else
              note_fail("A3/E5", $sformatf("%s: write produced no upstream B", tag));
          end else begin
            if (got_bid !== id)
              note_fail("E5", $sformatf("%s: B id %h expected %h",
                                        tag, got_bid, id));
            exp_bresp = refused ? RESP_SLVERR : downstream_bresp;
            if (got_bresp !== exp_bresp) begin
              if (refused)
                note_fail("C4", $sformatf("%s: refused B resp=%b expected SLVERR",
                                          tag, got_bresp));
              else
                note_fail("E6", $sformatf("%s: B resp=%b expected %b",
                                          tag, got_bresp, exp_bresp));
            end
          end
        end
      join

      repeat (4) @(negedge clk);

      if ((s_b_count - before_b) != 1) begin
        if (refused)
          note_fail("C4", $sformatf("%s: refused write produced %0d B beats",
                                    tag, s_b_count-before_b));
        else
          note_fail("A3/E5", $sformatf("%s: write produced %0d B beats",
                                       tag, s_b_count-before_b));
      end

      if (refused) begin
        if ((m_ar_count != before_ar) ||
            (m_aw_count != before_aw) ||
            (m_w_count != before_w))
          note_fail("C4", $sformatf("%s: refused write caused downstream activity", tag));
      end else begin
        if ((m_aw_count - before_aw) != 1)
          note_fail("A2", $sformatf("%s: downstream AW count delta %0d expected 1",
                                    tag, m_aw_count-before_aw));
        if ((m_w_count - before_w) != d_n)
          note_fail("E3", $sformatf("%s: downstream W count delta %0d expected %0d",
                                    tag, m_w_count-before_w, d_n));
        if (m_ar_count != before_ar)
          note_fail("A2", $sformatf("%s: write caused downstream read activity", tag));
      end
    end
  endtask

  task automatic test_read_limit;
    logic [3:0]  ids [0:3];
    logic [31:0] addrs [0:3];
    bit seen [0:3];

    bit accepted;
    bit fifth_accepted;
    bit cap_ok;
    bit send_ok;
    bit resp_ok;
    bit all_ok;
    int waited;

    logic [3:0]  cap_id;
    logic [31:0] cap_addr;
    logic [7:0]  cap_len;
    logic [2:0]  cap_size;
    logic [1:0]  cap_burst;

    logic [3:0]  got_rid;
    logic [63:0] got_rdata;
    logic [1:0]  got_rresp;
    logic        got_rlast;
    logic [15:0] send_data;
    logic [7:0]  got_byte;

    int i;
    int j;
    int idx;
    logic [31:0] bus_base;

    begin
      all_ok = 1'b1;
      fifth_accepted = 1'b0;
      for (i = 0; i < 4; i = i + 1) begin
        ids[i] = 4'd8 + i;
        addrs[i] = 32'h0000_3000 + i;
        seen[i] = 1'b0;
      end

      // No responses are returned until all four reads are outstanding.
      for (i = 0; i < 4; i = i + 1) begin
        fork
          begin
            bfm_ar(ids[i], addrs[i], 8'd0, 3'd0, BURST_INCR,
                   1000, accepted, waited);
            if (!accepted) begin
              note_fail("A4", $sformatf("read %0d below MAX_READS was not accepted", i));
              all_ok = 1'b0;
            end
          end
          begin
            take_m_ar(1000, cap_id, cap_addr, cap_len, cap_size,
                      cap_burst, cap_ok);
            if (!cap_ok) begin
              note_fail("A2", $sformatf("outstanding read %0d had no downstream AR", i));
              all_ok = 1'b0;
            end else begin
              if ((cap_id !== ids[i]) || (cap_addr !== addrs[i]))
                note_fail("A2", "outstanding read downstream id/address mismatch");
              if ((cap_len !== 8'd0) || (cap_size !== 3'd0))
                note_fail("B1/B2", "single-byte outstanding read transform mismatch");
            end
          end
        join
        if (!all_ok)
          break;
      end

      if (all_ok) begin
        // A fifth acceptance without any retirement would make five reads
        // outstanding. Non-acceptance is explicitly permitted.
        bfm_ar(4'd12, 32'h0000_3004, 8'd0, 3'd0, BURST_INCR,
               16, fifth_accepted, waited);
        if (fifth_accepted) begin
          note_fail("A4", "a fifth read was accepted with four reads outstanding");
          all_ok = 1'b0;
        end
      end

      if (all_ok) begin
        fork
          begin
            for (i = 0; i < 4; i = i + 1) begin
              bus_base = addrs[i] & 32'hffff_fffe;
              send_data = {rd_byte(bus_base+1), rd_byte(bus_base)};
              bfm_rbeat(ids[i], send_data, 1'b1, RESP_OKAY, 1000, send_ok);
              if (!send_ok)
                note_fail("A4", $sformatf("response for outstanding read %0d stalled", i));
            end
          end

          begin
            // Upstream completion order between transactions is unconstrained.
            for (j = 0; j < 4; j = j + 1) begin
              take_s_r(1500, got_rid, got_rdata, got_rresp, got_rlast, resp_ok);
              if (!resp_ok) begin
                note_fail("A3", "missing response in MAX_READS test");
                break;
              end else begin
                idx = got_rid;
                idx = idx - 8;
                if ((idx < 0) || (idx > 3)) begin
                  note_fail("D3", $sformatf("unexpected id %h in MAX_READS test", got_rid));
                end else begin
                  if (seen[idx])
                    note_fail("A3", $sformatf("duplicate response for id %h", got_rid));
                  seen[idx] = 1'b1;
                  if (got_rlast !== 1'b1)
                    note_fail("D4", "single-beat MAX_READS response lacked RLAST");
                  if (got_rresp !== RESP_OKAY)
                    note_fail("D5", "MAX_READS response was not OKAY");
                  got_byte = got_rdata >> ((addrs[idx] & 7) * 8);
                  if (got_byte !== rd_byte(addrs[idx]))
                    note_fail("D1/D2", "MAX_READS response data/lane mismatch");
                end
              end
            end
            for (j = 0; j < 4; j = j + 1) begin
              if (!seen[j])
                note_fail("A3", $sformatf("no response retired read %0d", j));
            end
          end
        join
      end

      // Also cleans up the deliberately over-accepted case without waiting
      // for a response that the testbench will never supply.
      bfm_reset(3);
    end
  endtask

  task automatic test_reset;
    bit accepted;
    bit cap_ok;
    int waited;
    int i;

    logic [3:0]  cap_id;
    logic [31:0] cap_addr;
    logic [7:0]  cap_len;
    logic [2:0]  cap_size;
    logic [1:0]  cap_burst;

    begin
      // Leave a real transaction outstanding across reset.
      fork
        begin
          bfm_ar(4'd13, 32'h0000_4800, 8'd1, 3'd3, BURST_INCR,
                 1000, accepted, waited);
          if (!accepted)
            note_fail("A1", "reset-test read address was not accepted");
        end
        begin
          take_m_ar(1000, cap_id, cap_addr, cap_len, cap_size,
                    cap_burst, cap_ok);
          if (!cap_ok)
            note_fail("A2", "reset-test read had no downstream request");
        end
      join

      bfm_reset(4);

      // Nothing from the pre-reset transaction may leak out after release.
      for (i = 0; i < 24; i = i + 1) begin
        @(negedge clk);
        if (s_rvalid !== 1'b0)
          note_fail("F3", "pre-reset read produced a response after reset");
        if (s_bvalid !== 1'b0)
          note_fail("F3", "pre-reset transaction produced a B after reset");
        if ((m_arvalid !== 1'b0) ||
            (m_awvalid !== 1'b0) ||
            (m_wvalid !== 1'b0))
          note_fail("F2", "unit did not return to idle after reset");
      end

      // A fresh transaction must work after reset.
      do_read("post-reset fresh read", 4'd14, 32'h0000_5000,
              8'd0, 3'd3, BURST_INCR, 1'b0, -1, RESP_OKAY);
    end
  endtask

  initial begin
    rst_n = 1'b0;

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
    m_bresp = RESP_OKAY;
    m_bvalid = 1'b0;
    m_arready = 1'b1;
    m_rid = '0;
    m_rdata = '0;
    m_rresp = RESP_OKAY;
    m_rlast = 1'b0;
    m_rvalid = 1'b0;

    bfm_reset(4);

    // Address transform, including both unaligned and sub-block cases.
    do_read("aligned size3 len1", 4'd1, 32'h0000_1000,
            8'd1, 3'd3, BURST_INCR, 1'b0, -1, RESP_OKAY);
    do_read("unaligned size3 len1", 4'd2, 32'h0000_1004,
            8'd1, 3'd3, BURST_INCR, 1'b0, -1, RESP_OKAY);
    do_read("single byte at 1001", 4'd3, 32'h0000_1001,
            8'd0, 3'd1, BURST_INCR, 1'b0, -1, RESP_OKAY);
    do_read("size remains zero", 4'd4, 32'h0000_1021,
            8'd3, 3'd0, BURST_INCR, 1'b0, -1, RESP_OKAY);

    // A legal one-beat FIXED burst is converted, not refused.
    do_read("legal FIXED len0 read", 4'd5, 32'h0000_1100,
            8'd0, 3'd3, BURST_FIXED, 1'b0, -1, RESP_OKAY);

    // Sticky read errors and preservation of both error codes.
    do_read("last downstream beat SLVERR", 4'd6, 32'h0000_1200,
            8'd1, 3'd3, BURST_INCR, 1'b0, 7, RESP_SLVERR);
    do_read("early downstream beat DECERR", 4'd7, 32'h0000_1300,
            8'd1, 3'd3, BURST_INCR, 1'b0, 3, RESP_DECERR);
    do_read("first downstream beat SLVERR", 4'd8, 32'h0000_1400,
            8'd1, 3'd3, BURST_INCR, 1'b0, 0, RESP_SLVERR);

    // Write byte stream, unaligned lanes, and exact downstream segmentation.
    do_write("aligned size3 write", 4'd1, 32'h0000_2000,
             8'd1, 3'd3, BURST_INCR, 1'b0, 0, RESP_OKAY);
    do_write("unaligned size3 write", 4'd2, 32'h0000_2004,
             8'd1, 3'd3, BURST_INCR, 1'b0, 0, RESP_OKAY);

    // strb_mode 1 generates 8'h81: expected downstream strobes 01 00 00 10.
    do_write("sparse strobe 81", 4'd3, 32'h0000_2100,
             8'd0, 3'd3, BURST_INCR, 1'b0, 1, RESP_OKAY);

    // strb_mode 2 generates 8'h0f and requires emission of two strb=0 beats.
    do_write("low-half strobe 0f", 4'd4, 32'h0000_2200,
             8'd0, 3'd3, BURST_INCR, 1'b0, 2, RESP_OKAY);

    do_write("size zero write", 4'd5, 32'h0000_2021,
             8'd3, 3'd0, BURST_INCR, 1'b0, 0, RESP_OKAY);
    do_write("legal FIXED len0 write", 4'd6, 32'h0000_2300,
             8'd0, 3'd3, BURST_FIXED, 1'b0, 0, RESP_OKAY);

    do_write("write SLVERR preserved", 4'd7, 32'h0000_2400,
             8'd0, 3'd3, BURST_INCR, 1'b0, 0, RESP_SLVERR);
    do_write("write DECERR preserved", 4'd8, 32'h0000_2501,
             8'd0, 3'd1, BURST_INCR, 1'b0, 0, RESP_DECERR);

    // Refusals: accepted upstream, absorbed, SLVERR, and no downstream activity.
    do_read("refused WRAP read", 4'd9, 32'h0000_4000,
            8'd1, 3'd3, BURST_WRAP, 1'b1, -1, RESP_OKAY);
    do_read("refused FIXED len1 read", 4'd10, 32'h0000_4100,
            8'd1, 3'd3, BURST_FIXED, 1'b1, -1, RESP_OKAY);
    do_write("refused WRAP write", 4'd11, 32'h0000_4200,
             8'd1, 3'd3, BURST_WRAP, 1'b1, 0, RESP_OKAY);
    do_write("refused FIXED len1 write", 4'd12, 32'h0000_4300,
             8'd1, 3'd3, BURST_FIXED, 1'b1, 0, RESP_OKAY);

    test_read_limit();
    test_reset();

    repeat (5) @(negedge clk);
    finished = 1'b1;
    if (errors == 0)
      $display("RESULT: PASS");
    else
      $display("RESULT: FAIL");
    $finish;
  end

  initial begin
    #4_000_000;
    if (!finished) begin
      finished = 1'b1;
      $display("A1/A3: watchdog expired without forward progress");
      $display("RESULT: FAIL");
      $finish;
    end
  end

endmodule
