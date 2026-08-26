module dw_downsizer_tb;

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

  logic [ID_W-1:0]          s_awid;
  logic [ADDR_W-1:0]        s_awaddr;
  logic [7:0]               s_awlen;
  logic [2:0]               s_awsize;
  logic [1:0]               s_awburst;
  logic                     s_awvalid;
  logic                     s_awready;

  logic [SLV_DATA_W-1:0]    s_wdata;
  logic [SLV_DATA_W/8-1:0]  s_wstrb;
  logic                     s_wlast;
  logic                     s_wvalid;
  logic                     s_wready;

  logic [ID_W-1:0]          s_bid;
  logic [1:0]               s_bresp;
  logic                     s_bvalid;
  logic                     s_bready;

  logic [ID_W-1:0]          s_arid;
  logic [ADDR_W-1:0]        s_araddr;
  logic [7:0]               s_arlen;
  logic [2:0]               s_arsize;
  logic [1:0]               s_arburst;
  logic                     s_arvalid;
  logic                     s_arready;

  logic [ID_W-1:0]          s_rid;
  logic [SLV_DATA_W-1:0]    s_rdata;
  logic [1:0]               s_rresp;
  logic                     s_rlast;
  logic                     s_rvalid;
  logic                     s_rready;

  logic [ID_W-1:0]          m_awid;
  logic [ADDR_W-1:0]        m_awaddr;
  logic [7:0]               m_awlen;
  logic [2:0]               m_awsize;
  logic [1:0]               m_awburst;
  logic                     m_awvalid;
  logic                     m_awready;

  logic [MST_DATA_W-1:0]    m_wdata;
  logic [MST_DATA_W/8-1:0]  m_wstrb;
  logic                     m_wlast;
  logic                     m_wvalid;
  logic                     m_wready;

  logic [ID_W-1:0]          m_bid;
  logic [1:0]               m_bresp;
  logic                     m_bvalid;
  logic                     m_bready;

  logic [ID_W-1:0]          m_arid;
  logic [ADDR_W-1:0]        m_araddr;
  logic [7:0]               m_arlen;
  logic [2:0]               m_arsize;
  logic [1:0]               m_arburst;
  logic                     m_arvalid;
  logic                     m_arready;

  logic [ID_W-1:0]          m_rid;
  logic [MST_DATA_W-1:0]    m_rdata;
  logic [1:0]               m_rresp;
  logic                     m_rlast;
  logic                     m_rvalid;
  logic                     m_rready;

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

  typedef struct packed {
    logic [ID_W-1:0]   id;
    logic [ADDR_W-1:0] addr;
    logic [7:0]        len;
    logic [2:0]        size;
    logic [1:0]        burst;
  } addr_rec_t;

  typedef struct packed {
    logic [MST_DATA_W-1:0]   data;
    logic [MST_DATA_W/8-1:0] strb;
    logic                    last;
  } mw_rec_t;

  typedef struct packed {
    logic [ID_W-1:0]       id;
    logic [SLV_DATA_W-1:0] data;
    logic [1:0]            resp;
    logic                  last;
  } sr_rec_t;

  typedef struct packed {
    logic [ID_W-1:0] id;
    logic [1:0]      resp;
  } sb_rec_t;

  addr_rec_t m_ar_q[$];
  addr_rec_t m_aw_q[$];
  mw_rec_t   m_w_q[$];
  sr_rec_t   s_r_q[$];
  sb_rec_t   s_b_q[$];

  int m_ar_hs_count;
  int m_aw_hs_count;
  int m_w_hs_count;
  int fail_count;
  bit done;

  initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
  end

  always @(posedge clk) begin
    if (rst_n) begin
      if (m_arvalid && m_arready) begin
        m_ar_q.push_back({m_arid, m_araddr, m_arlen, m_arsize, m_arburst});
        m_ar_hs_count = m_ar_hs_count + 1;
      end
      if (m_awvalid && m_awready) begin
        m_aw_q.push_back({m_awid, m_awaddr, m_awlen, m_awsize, m_awburst});
        m_aw_hs_count = m_aw_hs_count + 1;
      end
      if (m_wvalid && m_wready) begin
        m_w_q.push_back({m_wdata, m_wstrb, m_wlast});
        m_w_hs_count = m_w_hs_count + 1;
      end
      if (s_rvalid && s_rready) begin
        s_r_q.push_back({s_rid, s_rdata, s_rresp, s_rlast});
      end
      if (s_bvalid && s_bready) begin
        s_b_q.push_back({s_bid, s_bresp});
      end
    end
  end

  task automatic fail_req(input string req_name, input string msg);
    begin
      fail_count = fail_count + 1;
      $display("FAIL %s: %s", req_name, msg);
    end
  endtask

  task automatic wait_posedges(input int n);
    automatic int i;
    begin
      for (i = 0; i < n; i = i + 1) begin
        @(posedge clk);
      end
    end
  endtask

  task automatic clear_queues;
    begin
      m_ar_q.delete();
      m_aw_q.delete();
      m_w_q.delete();
      s_r_q.delete();
      s_b_q.delete();
    end
  endtask

  task automatic reset_dut(input int cycles);
    begin
      @(negedge clk);
      rst_n = 1'b0;
      repeat (cycles) @(posedge clk);
      @(negedge clk);
      rst_n = 1'b1;
    end
  endtask

  function automatic logic [ADDR_W-1:0] align_addr(
    input logic [ADDR_W-1:0] addr,
    input int unsigned size
  );
    begin
      align_addr = (addr >> size) << size;
    end
  endfunction

  function automatic int unsigned dsize_of(input int unsigned usize);
    begin
      if (usize > 1) dsize_of = 1;
      else           dsize_of = usize;
    end
  endfunction

  function automatic int unsigned dlen_of(
    input logic [ADDR_W-1:0] addr,
    input int unsigned       usize,
    input int unsigned       ulen
  );
    automatic longint unsigned beat_bytes;
    automatic longint unsigned total_bytes;
    automatic longint unsigned first_addr;
    automatic longint unsigned last_addr;
    automatic longint unsigned first_block;
    automatic longint unsigned last_block;
    automatic longint unsigned dbeat_bytes;
    automatic int unsigned dsize;
    begin
      beat_bytes  = 64'd1 << usize;
      dsize       = dsize_of(usize);
      dbeat_bytes = 64'd1 << dsize;
      first_addr  = addr;
      total_bytes = (ulen + 1) * beat_bytes - (addr - align_addr(addr, usize));
      last_addr   = first_addr + total_bytes - 1;
      first_block = align_addr(addr, dsize);
      last_block  = (last_addr >> dsize) << dsize;
      dlen_of     = int'((last_block - first_block) / dbeat_bytes);
    end
  endfunction

  function automatic logic [7:0] mem_byte(input logic [ADDR_W-1:0] addr);
    begin
      mem_byte = addr[7:0] ^ 8'hA5;
    end
  endfunction

  function automatic logic [MST_DATA_W-1:0] make_m_rdata(
    input logic [ADDR_W-1:0] transfer_addr
  );
    automatic logic [ADDR_W-1:0] bus_base;
    begin
      bus_base = {transfer_addr[ADDR_W-1:1], 1'b0};
      make_m_rdata[7:0]  = mem_byte(bus_base);
      make_m_rdata[15:8] = mem_byte(bus_base + 1);
    end
  endfunction

  function automatic logic [SLV_DATA_W-1:0] expand_slv_byte_mask(
    input logic [SLV_DATA_W/8-1:0] byte_mask
  );
    automatic int i;
    begin
      expand_slv_byte_mask = '0;
      for (i = 0; i < SLV_DATA_W/8; i = i + 1) begin
        expand_slv_byte_mask[i*8 +: 8] = {8{byte_mask[i]}};
      end
    end
  endfunction

  function automatic logic [MST_DATA_W-1:0] expand_mst_byte_mask(
    input logic [MST_DATA_W/8-1:0] byte_mask
  );
    automatic int i;
    begin
      expand_mst_byte_mask = '0;
      for (i = 0; i < MST_DATA_W/8; i = i + 1) begin
        expand_mst_byte_mask[i*8 +: 8] = {8{byte_mask[i]}};
      end
    end
  endfunction

  task automatic build_up_read_expected(
    input  logic [ADDR_W-1:0]       addr,
    input  int unsigned             usize,
    input  int unsigned             beat_idx,
    output logic [SLV_DATA_W-1:0]   exp_data,
    output logic [SLV_DATA_W/8-1:0] exp_mask
  );
    automatic int unsigned beat_bytes;
    automatic logic [ADDR_W-1:0] beat_base;
    automatic logic [ADDR_W-1:0] first_valid;
    automatic logic [ADDR_W-1:0] last_valid;
    automatic logic [ADDR_W-1:0] a;
    automatic int lane;
    begin
      beat_bytes = 1 << usize;
      beat_base  = align_addr(addr, usize) + beat_idx * beat_bytes;
      if (beat_idx == 0) first_valid = addr;
      else               first_valid = beat_base;
      last_valid = beat_base + beat_bytes - 1;
      exp_data = '0;
      exp_mask = '0;
      a = first_valid;
      while (a <= last_valid) begin
        lane = int'(a[2:0]);
        exp_data[lane*8 +: 8] = mem_byte(a);
        exp_mask[lane] = 1'b1;
        a = a + 1;
      end
    end
  endtask

  task automatic send_ar(
    input  logic [ID_W-1:0]   id,
    input  logic [ADDR_W-1:0] addr,
    input  logic [7:0]        len,
    input  logic [2:0]        size,
    input  logic [1:0]        burst,
    input  int                budget,
    output bit                accepted
  );
    automatic int waited;
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
        if (s_arready) begin
          accepted = 1'b1;
          break;
        end
        waited = waited + 1;
      end
      @(negedge clk);
      s_arvalid = 1'b0;
    end
  endtask

  task automatic send_aw(
    input  logic [ID_W-1:0]   id,
    input  logic [ADDR_W-1:0] addr,
    input  logic [7:0]        len,
    input  logic [2:0]        size,
    input  logic [1:0]        burst,
    input  int                budget,
    output bit                accepted
  );
    automatic int waited;
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
        if (s_awready) begin
          accepted = 1'b1;
          break;
        end
        waited = waited + 1;
      end
      @(negedge clk);
      s_awvalid = 1'b0;
    end
  endtask

  task automatic send_w(
    input  logic [SLV_DATA_W-1:0]   data,
    input  logic [SLV_DATA_W/8-1:0] strb,
    input  logic                    last,
    input  int                      budget,
    output bit                      accepted
  );
    automatic int waited;
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
        if (s_wready) begin
          accepted = 1'b1;
          break;
        end
        waited = waited + 1;
      end
      @(negedge clk);
      s_wvalid = 1'b0;
    end
  endtask

  task automatic drive_m_r(
    input logic [ID_W-1:0]       id,
    input logic [MST_DATA_W-1:0] data,
    input logic [1:0]            resp,
    input logic                  last,
    input int                    budget,
    output bit                   accepted
  );
    automatic int waited;
    begin
      accepted = 1'b0;
      waited = 0;
      @(negedge clk);
      m_rid = id;
      m_rdata = data;
      m_rresp = resp;
      m_rlast = last;
      m_rvalid = 1'b1;
      while (waited < budget) begin
        @(posedge clk);
        if (m_rready) begin
          accepted = 1'b1;
          break;
        end
        waited = waited + 1;
      end
      @(negedge clk);
      m_rvalid = 1'b0;
    end
  endtask

  task automatic drive_m_b(
    input logic [ID_W-1:0] id,
    input logic [1:0]      resp,
    input int              budget,
    output bit             accepted
  );
    automatic int waited;
    begin
      accepted = 1'b0;
      waited = 0;
      @(negedge clk);
      m_bid = id;
      m_bresp = resp;
      m_bvalid = 1'b1;
      while (waited < budget) begin
        @(posedge clk);
        if (m_bready) begin
          accepted = 1'b1;
          break;
        end
        waited = waited + 1;
      end
      @(negedge clk);
      m_bvalid = 1'b0;
    end
  endtask

  task automatic wait_m_ar_count(input int need, input int budget, output bit got);
    automatic int waited;
    begin
      got = 1'b0;
      waited = 0;
      while (waited < budget) begin
        if (m_ar_q.size() >= need) begin
          got = 1'b1;
          break;
        end
        @(posedge clk);
        waited = waited + 1;
      end
    end
  endtask

  task automatic wait_m_aw_count(input int need, input int budget, output bit got);
    automatic int waited;
    begin
      got = 1'b0;
      waited = 0;
      while (waited < budget) begin
        if (m_aw_q.size() >= need) begin
          got = 1'b1;
          break;
        end
        @(posedge clk);
        waited = waited + 1;
      end
    end
  endtask

  task automatic wait_m_w_count(input int need, input int budget, output bit got);
    automatic int waited;
    begin
      got = 1'b0;
      waited = 0;
      while (waited < budget) begin
        if (m_w_q.size() >= need) begin
          got = 1'b1;
          break;
        end
        @(posedge clk);
        waited = waited + 1;
      end
    end
  endtask

  task automatic wait_s_r_count(input int need, input int budget, output bit got);
    automatic int waited;
    begin
      got = 1'b0;
      waited = 0;
      while (waited < budget) begin
        if (s_r_q.size() >= need) begin
          got = 1'b1;
          break;
        end
        @(posedge clk);
        waited = waited + 1;
      end
    end
  endtask

  task automatic wait_s_b_count(input int need, input int budget, output bit got);
    automatic int waited;
    begin
      got = 1'b0;
      waited = 0;
      while (waited < budget) begin
        if (s_b_q.size() >= need) begin
          got = 1'b1;
          break;
        end
        @(posedge clk);
        waited = waited + 1;
      end
    end
  endtask

  task automatic check_downstream_addr(
    input addr_rec_t          rec,
    input logic [ID_W-1:0]    id,
    input logic [ADDR_W-1:0]  addr,
    input logic [7:0]         len,
    input logic [2:0]         size,
    input bit                 is_read
  );
    automatic int unsigned exp_dsize;
    automatic int unsigned exp_dlen;
    automatic string ch;
    begin
      exp_dsize = dsize_of(size);
      exp_dlen  = dlen_of(addr, size, len);
      if (is_read) ch = "read";
      else         ch = "write";

      if (rec.id !== id) begin
        fail_req("A2", $sformatf("%s downstream id %0h != upstream id %0h", ch, rec.id, id));
      end
      if (rec.addr !== addr) begin
        fail_req("B3", $sformatf("%s downstream addr %08h != upstream addr %08h", ch, rec.addr, addr));
      end
      if (rec.size !== exp_dsize[2:0]) begin
        fail_req("B1", $sformatf("%s downstream size %0d != expected %0d", ch, rec.size, exp_dsize));
      end
      if (rec.len !== exp_dlen[7:0]) begin
        fail_req("B2", $sformatf("%s downstream len %0d != expected %0d", ch, rec.len, exp_dlen));
      end
      if ((exp_dlen != 0) && (rec.burst !== BURST_INCR)) begin
        fail_req("B4", $sformatf("%s multi-beat downstream burst %0b is not INCR", ch, rec.burst));
      end
    end
  endtask

  task automatic run_read(
    input logic [ID_W-1:0]   id,
    input logic [ADDR_W-1:0] addr,
    input logic [7:0]        len,
    input logic [2:0]        size,
    input logic [1:0]        burst,
    input int                err_beat,
    input logic [1:0]        err_code
  );
    automatic bit accepted;
    automatic bit got;
    automatic addr_rec_t ar_rec;
    automatic sr_rec_t rr;
    automatic int unsigned dsize;
    automatic int unsigned dlen;
    automatic int unsigned db;
    automatic int unsigned ub;
    automatic int err_group;
    automatic int i;
    automatic logic [ADDR_W-1:0] block_addr;
    automatic logic [ADDR_W-1:0] err_addr;
    automatic logic [MST_DATA_W-1:0] dn_data;
    automatic logic [1:0] dn_resp;
    automatic logic [1:0] exp_resp;
    automatic logic [SLV_DATA_W-1:0] exp_data;
    automatic logic [SLV_DATA_W/8-1:0] exp_mask;
    begin
      clear_queues();
      send_ar(id, addr, len, size, burst, 500, accepted);
      if (!accepted) begin
        fail_req("A1", $sformatf("legal read id=%0h addr=%08h was not accepted", id, addr));
        return;
      end

      wait_m_ar_count(1, 500, got);
      if (!got) begin
        fail_req("A2", "accepted legal read produced no downstream AR");
        return;
      end
      ar_rec = m_ar_q.pop_front();
      check_downstream_addr(ar_rec, id, addr, len, size, 1'b1);

      dsize = dsize_of(size);
      dlen = dlen_of(addr, size, len);
      db = 1 << dsize;
      ub = 1 << size;
      err_group = -1;
      if (err_beat >= 0) begin
        block_addr = align_addr(addr, dsize) + err_beat * db;
        if (err_beat == 0) err_addr = addr;
        else               err_addr = block_addr;
        err_group = int'((err_addr - align_addr(addr, size)) / ub);
      end

      for (i = 0; i <= int'(dlen); i = i + 1) begin
        block_addr = align_addr(addr, dsize) + i * db;
        if (i == 0) dn_data = make_m_rdata(addr);
        else        dn_data = make_m_rdata(block_addr);
        if (i == err_beat) dn_resp = err_code;
        else               dn_resp = RESP_OKAY;
        drive_m_r(id, dn_data, dn_resp, (i == int'(dlen)), 500, accepted);
        if (!accepted) begin
          fail_req("A3", $sformatf("DUT would not accept downstream R beat %0d", i));
          return;
        end
      end

      wait_s_r_count(int'(len) + 1, 500, got);
      if (!got) begin
        fail_req("A3", $sformatf("read produced fewer than %0d upstream R beats", int'(len) + 1));
        return;
      end

      for (i = 0; i <= int'(len); i = i + 1) begin
        rr = s_r_q.pop_front();
        build_up_read_expected(addr, size, i, exp_data, exp_mask);
        if (rr.id !== id) begin
          fail_req("D3", $sformatf("R beat %0d id %0h != %0h", i, rr.id, id));
        end
        if (rr.last !== (i == int'(len))) begin
          fail_req("D4", $sformatf("R beat %0d last=%0b expected=%0b", i, rr.last, (i == int'(len))));
        end
        if ((rr.data & expand_slv_byte_mask(exp_mask)) !==
            (exp_data & expand_slv_byte_mask(exp_mask))) begin
          fail_req("D1/D2", $sformatf("R beat %0d data/lane placement mismatch", i));
        end

        if (err_group < 0) begin
          exp_resp = RESP_OKAY;
          if (rr.resp !== exp_resp) begin
            fail_req("D5", $sformatf("R beat %0d resp %0b != OKAY", i, rr.resp));
          end
        end else begin
          if (i >= err_group) exp_resp = err_code;
          else                exp_resp = RESP_OKAY;
          if (rr.resp !== exp_resp) begin
            fail_req("D6/D7", $sformatf("R beat %0d resp %0b expected %0b", i, rr.resp, exp_resp));
          end
        end
      end

      wait_posedges(5);
      if (s_r_q.size() != 0) begin
        fail_req("A3", "legal read produced extra upstream R beat(s)");
        s_r_q.delete();
      end
      if (m_ar_q.size() != 0) begin
        fail_req("A2", "one accepted read produced more than one downstream AR");
        m_ar_q.delete();
      end
    end
  endtask

  task automatic run_refused_read(
    input logic [ID_W-1:0]   id,
    input logic [ADDR_W-1:0] addr,
    input logic [7:0]        len,
    input logic [2:0]        size,
    input logic [1:0]        burst,
    input string             req_name
  );
    automatic bit accepted;
    automatic bit got;
    automatic int ar_before;
    automatic int aw_before;
    automatic int w_before;
    automatic int i;
    automatic sr_rec_t rr;
    begin
      clear_queues();
      ar_before = m_ar_hs_count;
      aw_before = m_aw_hs_count;
      w_before = m_w_hs_count;
      send_ar(id, addr, len, size, burst, 500, accepted);
      if (!accepted) begin
        fail_req(req_name, "refused read was not accepted on upstream AR");
        return;
      end

      wait_s_r_count(int'(len) + 1, 500, got);
      if (!got) begin
        fail_req("C4", "refused read did not synthesize len+1 upstream R beats");
        return;
      end
      for (i = 0; i <= int'(len); i = i + 1) begin
        rr = s_r_q.pop_front();
        if (rr.id !== id) begin
          fail_req("A3", $sformatf("refused read R id %0h != %0h", rr.id, id));
        end
        if (rr.resp !== RESP_SLVERR) begin
          fail_req("C4", $sformatf("refused read R beat %0d resp %0b != SLVERR", i, rr.resp));
        end
        if (rr.last !== (i == int'(len))) begin
          fail_req("C4", $sformatf("refused read R beat %0d last incorrect", i));
        end
      end

      wait_posedges(8);
      if ((m_ar_hs_count != ar_before) || (m_aw_hs_count != aw_before) || (m_w_hs_count != w_before)) begin
        fail_req("C4", "refused read leaked a downstream transaction/data beat");
      end
      if (s_r_q.size() != 0) begin
        fail_req("A3", "refused read produced extra upstream R beat(s)");
        s_r_q.delete();
      end
    end
  endtask

  task automatic build_expected_mw(
    input  logic [ADDR_W-1:0]       addr,
    input  logic [2:0]              size,
    input  logic [SLV_DATA_W-1:0]   udata,
    input  logic [SLV_DATA_W/8-1:0] ustrb,
    input  int                      dn_idx,
    output logic [MST_DATA_W-1:0]   exp_data,
    output logic [MST_DATA_W/8-1:0] exp_strb,
    output logic [MST_DATA_W/8-1:0] data_mask
  );
    automatic int unsigned dsize;
    automatic int unsigned db;
    automatic int unsigned ub;
    automatic logic [ADDR_W-1:0] block_base;
    automatic logic [ADDR_W-1:0] first_valid;
    automatic logic [ADDR_W-1:0] last_valid;
    automatic logic [ADDR_W-1:0] a;
    automatic int ulane;
    automatic int mlane;
    begin
      dsize = dsize_of(size);
      db = 1 << dsize;
      ub = 1 << size;
      block_base = align_addr(addr, dsize) + dn_idx * db;
      first_valid = addr;
      last_valid = align_addr(addr, size) + ub - 1;
      exp_data = '0;
      exp_strb = '0;
      data_mask = '0;
      a = block_base;
      while (a < block_base + db) begin
        if ((a >= first_valid) && (a <= last_valid)) begin
          ulane = int'(a[2:0]);
          mlane = int'(a[0]);
          exp_data[mlane*8 +: 8] = udata[ulane*8 +: 8];
          exp_strb[mlane] = ustrb[ulane];
          data_mask[mlane] = 1'b1;
        end
        a = a + 1;
      end
    end
  endtask

  task automatic run_write_one(
    input logic [ID_W-1:0]          id,
    input logic [ADDR_W-1:0]        addr,
    input logic [2:0]               size,
    input logic [1:0]               burst,
    input logic [SLV_DATA_W-1:0]    udata,
    input logic [SLV_DATA_W/8-1:0]  ustrb,
    input logic [1:0]               dn_bresp
  );
    automatic bit accepted;
    automatic bit got;
    automatic addr_rec_t aw_rec;
    automatic mw_rec_t wr;
    automatic sb_rec_t br;
    automatic int unsigned dlen;
    automatic int i;
    automatic logic [MST_DATA_W-1:0] exp_data;
    automatic logic [MST_DATA_W/8-1:0] exp_strb;
    automatic logic [MST_DATA_W/8-1:0] data_mask;
    automatic logic [MST_DATA_W-1:0] wide_mask;
    begin
      clear_queues();
      send_aw(id, addr, 8'd0, size, burst, 500, accepted);
      if (!accepted) begin
        fail_req("A1", $sformatf("legal write id=%0h addr=%08h was not accepted", id, addr));
        return;
      end

      send_w(udata, ustrb, 1'b1, 500, accepted);
      if (!accepted) begin
        fail_req("A3", "legal write data beat was not accepted upstream");
        return;
      end

      wait_m_aw_count(1, 500, got);
      if (!got) begin
        fail_req("A2", "accepted legal write produced no downstream AW");
        return;
      end
      aw_rec = m_aw_q.pop_front();
      check_downstream_addr(aw_rec, id, addr, 8'd0, size, 1'b0);

      dlen = dlen_of(addr, size, 0);
      wait_m_w_count(int'(dlen) + 1, 500, got);
      if (!got) begin
        fail_req("E3", $sformatf("write produced fewer than %0d downstream W beats", int'(dlen) + 1));
        return;
      end
      for (i = 0; i <= int'(dlen); i = i + 1) begin
        wr = m_w_q.pop_front();
        build_expected_mw(addr, size, udata, ustrb, i, exp_data, exp_strb, data_mask);
        wide_mask = expand_mst_byte_mask(data_mask);
        if ((wr.data & wide_mask) !== (exp_data & wide_mask)) begin
          fail_req("E1", $sformatf("downstream W beat %0d data byte stream mismatch", i));
        end
        if (wr.strb !== exp_strb) begin
          fail_req("E2", $sformatf("downstream W beat %0d strb %0b expected %0b", i, wr.strb, exp_strb));
        end
        if (wr.last !== (i == int'(dlen))) begin
          fail_req("E4", $sformatf("downstream W beat %0d last incorrect", i));
        end
      end

      drive_m_b(id, dn_bresp, 500, accepted);
      if (!accepted) begin
        fail_req("E5", "DUT did not accept downstream B response");
        return;
      end
      wait_s_b_count(1, 500, got);
      if (!got) begin
        fail_req("E5", "downstream B did not produce upstream B");
        return;
      end
      br = s_b_q.pop_front();
      if (br.id !== id) begin
        fail_req("E5", $sformatf("upstream B id %0h != %0h", br.id, id));
      end
      if (br.resp !== dn_bresp) begin
        fail_req("E6", $sformatf("upstream B resp %0b != downstream code %0b", br.resp, dn_bresp));
      end

      wait_posedges(5);
      if (s_b_q.size() != 0) begin
        fail_req("A3", "write produced extra upstream B response(s)");
        s_b_q.delete();
      end
      if (m_aw_q.size() != 0) begin
        fail_req("A2", "one accepted write produced more than one downstream AW");
        m_aw_q.delete();
      end
      if (m_w_q.size() != 0) begin
        fail_req("E3", "write produced more downstream W beats than transformed length");
        m_w_q.delete();
      end
    end
  endtask

  task automatic run_refused_write(
    input logic [ID_W-1:0]   id,
    input logic [ADDR_W-1:0] addr,
    input logic [7:0]        len,
    input logic [2:0]        size,
    input logic [1:0]        burst,
    input string             req_name
  );
    automatic bit accepted;
    automatic bit got;
    automatic int ar_before;
    automatic int aw_before;
    automatic int w_before;
    automatic int i;
    automatic logic [SLV_DATA_W-1:0] data;
    automatic sb_rec_t br;
    begin
      clear_queues();
      ar_before = m_ar_hs_count;
      aw_before = m_aw_hs_count;
      w_before = m_w_hs_count;
      send_aw(id, addr, len, size, burst, 500, accepted);
      if (!accepted) begin
        fail_req(req_name, "refused write was not accepted on upstream AW");
        return;
      end

      for (i = 0; i <= int'(len); i = i + 1) begin
        data = 64'h8877665544332211 ^ i;
        send_w(data, 8'hFF, (i == int'(len)), 500, accepted);
        if (!accepted) begin
          fail_req("C4", $sformatf("refused write did not absorb upstream W beat %0d", i));
          return;
        end
      end

      wait_s_b_count(1, 500, got);
      if (!got) begin
        fail_req("C4", "refused write did not synthesize upstream B");
        return;
      end
      br = s_b_q.pop_front();
      if (br.id !== id) begin
        fail_req("A3", $sformatf("refused write B id %0h != %0h", br.id, id));
      end
      if (br.resp !== RESP_SLVERR) begin
        fail_req("C4", $sformatf("refused write B resp %0b != SLVERR", br.resp));
      end

      wait_posedges(8);
      if ((m_ar_hs_count != ar_before) || (m_aw_hs_count != aw_before) || (m_w_hs_count != w_before)) begin
        fail_req("C4", "refused write leaked downstream address/data traffic");
      end
      if (s_b_q.size() != 0) begin
        fail_req("A3", "refused write produced extra upstream B response(s)");
        s_b_q.delete();
      end
    end
  endtask

  task automatic test_reset_cancellation;
    automatic bit accepted;
    automatic bit got;
    automatic addr_rec_t ar_rec;
    automatic int ar_after_old;
    automatic int aw_after_old;
    automatic int w_after_old;
    automatic int i;
    begin
      clear_queues();
      send_ar(4'hE, 32'h0000_7000, 8'd0, 3'd3, BURST_INCR, 500, accepted);
      if (!accepted) begin
        fail_req("A1", "pre-reset legal read was not accepted");
        return;
      end
      wait_m_ar_count(1, 500, got);
      if (!got) begin
        fail_req("A2", "pre-reset accepted read produced no downstream AR");
        return;
      end
      ar_rec = m_ar_q.pop_front();
      check_downstream_addr(ar_rec, 4'hE, 32'h0000_7000, 8'd0, 3'd3, 1'b1);
      ar_after_old = m_ar_hs_count;
      aw_after_old = m_aw_hs_count;
      w_after_old = m_w_hs_count;

      @(negedge clk);
      rst_n = 1'b0;
      repeat (4) @(posedge clk);
      @(negedge clk);
      rst_n = 1'b1;

      for (i = 0; i < 8; i = i + 1) begin
        @(posedge clk);
        if (s_rvalid || s_bvalid) begin
          fail_req("F3", "pre-reset transaction produced an upstream response after reset");
        end
        if (m_arvalid || m_awvalid || m_wvalid) begin
          fail_req("F2", "unit was not idle after reset release");
        end
      end
      if ((m_ar_hs_count != ar_after_old) || (m_aw_hs_count != aw_after_old) || (m_w_hs_count != w_after_old)) begin
        fail_req("F2", "stale downstream traffic appeared after reset release");
      end
      if ((s_r_q.size() != 0) || (s_b_q.size() != 0)) begin
        fail_req("F3", "pre-reset response transferred after reset");
        s_r_q.delete();
        s_b_q.delete();
      end
    end
  endtask

  task automatic test_max_reads;
    automatic bit accepted;
    automatic bit got;
    automatic int i;
    automatic addr_rec_t recs[0:4];
    automatic addr_rec_t ar_rec;
    automatic sr_rec_t rr;
    automatic logic [15:0] seen;
    automatic logic [MST_DATA_W-1:0] dn_data;
    begin
      clear_queues();
      seen = '0;

      for (i = 0; i < 4; i = i + 1) begin
        send_ar(4'h8 + i, 32'h0000_8000 + i*16, 8'd0, 3'd1, BURST_INCR, 500, accepted);
        if (!accepted) begin
          fail_req("F2", $sformatf("after reset, read slot %0d of MAX_READS was not accepted", i));
          return;
        end
      end

      wait_m_ar_count(4, 1000, got);
      if (!got) begin
        fail_req("A2", "four accepted reads did not each produce a downstream AR");
        return;
      end
      for (i = 0; i < 4; i = i + 1) begin
        recs[i] = m_ar_q.pop_front();
        if ((recs[i].id < 4'h8) || (recs[i].id > 4'hB)) begin
          fail_req("A2", $sformatf("concurrent downstream read used unexpected id %0h", recs[i].id));
        end else begin
          check_downstream_addr(recs[i], recs[i].id,
                                32'h0000_8000 + (recs[i].id - 4'h8)*16,
                                8'd0, 3'd1, 1'b1);
        end
      end

      send_ar(4'hC, 32'h0000_8040, 8'd0, 3'd1, BURST_INCR, 20, accepted);
      if (accepted) begin
        fail_req("A4", "fifth read was accepted while four upstream reads were still outstanding");
      end

      dn_data = make_m_rdata(recs[0].addr);
      drive_m_r(recs[0].id, dn_data, RESP_OKAY, 1'b1, 500, accepted);
      if (!accepted) begin
        fail_req("A4", "could not retire one of four outstanding reads");
        return;
      end
      wait_s_r_count(1, 500, got);
      if (!got) begin
        fail_req("A4", "retiring downstream response did not retire upstream read");
        return;
      end
      rr = s_r_q.pop_front();
      if (rr.id !== recs[0].id) begin
        fail_req("D3", "retired read returned wrong id");
      end

      send_ar(4'hC, 32'h0000_8040, 8'd0, 3'd1, BURST_INCR, 500, accepted);
      if (!accepted) begin
        fail_req("A4", "read was not accepted after one of four outstanding reads retired");
        return;
      end
      wait_m_ar_count(1, 500, got);
      if (!got) begin
        fail_req("A2", "newly accepted fifth read produced no downstream AR");
        return;
      end
      recs[4] = m_ar_q.pop_front();
      check_downstream_addr(recs[4], 4'hC, 32'h0000_8040, 8'd0, 3'd1, 1'b1);

      for (i = 1; i < 5; i = i + 1) begin
        dn_data = make_m_rdata(recs[i].addr);
        drive_m_r(recs[i].id, dn_data, RESP_OKAY, 1'b1, 500, accepted);
        if (!accepted) begin
          fail_req("A3", $sformatf("could not provide response for outstanding read %0d", i));
          return;
        end
      end
      wait_s_r_count(4, 1000, got);
      if (!got) begin
        fail_req("A3", "not all outstanding reads completed during cleanup");
        return;
      end
      for (i = 0; i < 4; i = i + 1) begin
        rr = s_r_q.pop_front();
        if (seen[rr.id]) begin
          fail_req("A3", $sformatf("duplicate completion for id %0h", rr.id));
        end
        seen[rr.id] = 1'b1;
        if (!rr.last) begin
          fail_req("D4", $sformatf("single-beat read id %0h lacked rlast", rr.id));
        end
      end
      if (!(seen[4'h9] && seen[4'hA] && seen[4'hB] && seen[4'hC])) begin
        fail_req("A3", "cleanup responses did not complete exactly the remaining four reads");
      end
    end
  endtask

  initial begin
    rst_n = 1'b0;

    s_awid = '0;
    s_awaddr = '0;
    s_awlen = '0;
    s_awsize = '0;
    s_awburst = BURST_INCR;
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
    s_arburst = BURST_INCR;
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

    m_ar_hs_count = 0;
    m_aw_hs_count = 0;
    m_w_hs_count = 0;
    fail_count = 0;
    done = 1'b0;

    reset_dut(4);

    // B1/B2/B3/B4 and D1..D5: normal reads, including the measured boundaries.
    run_read(4'h1, 32'h0000_1000, 8'd1, 3'd3, BURST_INCR, -1, RESP_OKAY);
    run_read(4'h2, 32'h0000_1004, 8'd1, 3'd3, BURST_INCR, -1, RESP_OKAY);
    run_read(4'h3, 32'h0000_1005, 8'd0, 3'd0, BURST_INCR, -1, RESP_OKAY);
    run_read(4'h4, 32'h0000_1001, 8'd0, 3'd1, BURST_INCR, -1, RESP_OKAY);

    // C3 plus B4: single-beat FIXED upstream is legal and expands to INCR.
    run_read(4'h5, 32'h0000_2000, 8'd0, 3'd3, BURST_FIXED, -1, RESP_OKAY);

    // D6/D7: late error affects only its group and later; early error is sticky.
    run_read(4'h6, 32'h0000_3000, 8'd1, 3'd3, BURST_INCR, 7, RESP_SLVERR);
    run_read(4'h7, 32'h0000_3100, 8'd1, 3'd3, BURST_INCR, 0, RESP_DECERR);

    // C1/C4 and C2/C4: refused reads are accepted, never forwarded, and synthesize SLVERR.
    run_refused_read(4'h8, 32'h0000_4000, 8'd1, 3'd3, BURST_WRAP,  "C1");
    run_refused_read(4'h9, 32'h0000_4100, 8'd1, 3'd3, BURST_FIXED, "C2");

    // E1..E6: sparse strobe creates zero-strobe narrow beats; response code is preserved.
    run_write_one(4'hA, 32'h0000_5000, 3'd3, BURST_INCR,
                  64'h1716151413121110, 8'h81, RESP_OKAY);
    run_write_one(4'hB, 32'h0000_5002, 3'd1, BURST_INCR,
                  64'h2726252423222120, 8'h0C, RESP_DECERR);

    // C1/C4 write side: absorb the entire refused W burst and emit no downstream traffic.
    run_refused_write(4'hC, 32'h0000_6000, 8'd1, 3'd3, BURST_WRAP, "C1");

    // F2/F3, then A4 capacity/retirement after reset.
    test_reset_cancellation();
    test_max_reads();

    done = 1'b1;
    if (fail_count == 0) $display("RESULT: PASS");
    else                 $display("RESULT: FAIL");
    $finish;
  end

  initial begin
    #4_000_000;
    if (!done) begin
      $display("FAIL A3: watchdog: no forward progress");
      $display("RESULT: FAIL");
      $finish;
    end
  end

endmodule