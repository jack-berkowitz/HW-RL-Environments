module dw_downsizer_tb;

  localparam int ADDR_W = 32;
  localparam int ID_W = 4;
  localparam int SLV_DATA_W = 64;
  localparam int MST_DATA_W = 16;
  localparam int MAX_READS = 4;
  localparam int MAX_CYCLES = 3000;

  logic clk;
  initial begin clk = 1'b0; forever #5 clk = ~clk; end

  logic rst_n;
  initial rst_n = 1'b0;

  // Upstream (DUT slave port)
  logic [ID_W-1:0]      s_awid;
  logic [ADDR_W-1:0]    s_awaddr;
  logic [7:0]           s_awlen;
  logic [2:0]           s_awsize;
  logic [1:0]           s_awburst;
  logic                 s_awvalid;
  logic                 s_awready;
  logic [SLV_DATA_W-1:0]   s_wdata;
  logic [SLV_DATA_W/8-1:0] s_wstrb;
  logic                 s_wlast;
  logic                 s_wvalid;
  logic                 s_wready;
  logic [ID_W-1:0]      s_bid;
  logic [1:0]           s_bresp;
  logic                 s_bvalid;
  logic                 s_bready;
  logic [ID_W-1:0]      s_arid;
  logic [ADDR_W-1:0]    s_araddr;
  logic [7:0]           s_arlen;
  logic [2:0]           s_arsize;
  logic [1:0]           s_arburst;
  logic                 s_arvalid;
  logic                 s_arready;
  logic [ID_W-1:0]      s_rid;
  logic [SLV_DATA_W-1:0]   s_rdata;
  logic [1:0]           s_rresp;
  logic                 s_rlast;
  logic                 s_rvalid;
  logic                 s_rready;

  // Downstream (DUT master port)
  logic [ID_W-1:0]      m_awid;
  logic [ADDR_W-1:0]    m_awaddr;
  logic [7:0]           m_awlen;
  logic [2:0]           m_awsize;
  logic [1:0]           m_awburst;
  logic                 m_awvalid;
  logic                 m_awready;
  logic [MST_DATA_W-1:0]   m_wdata;
  logic [MST_DATA_W/8-1:0] m_wstrb;
  logic                 m_wlast;
  logic                 m_wvalid;
  logic                 m_wready;
  logic [ID_W-1:0]      m_bid;
  logic [1:0]           m_bresp;
  logic                 m_bvalid;
  logic                 m_bready;
  logic [ID_W-1:0]      m_arid;
  logic [ADDR_W-1:0]    m_araddr;
  logic [7:0]           m_arlen;
  logic [2:0]           m_arsize;
  logic [1:0]           m_arburst;
  logic                 m_arvalid;
  logic                 m_arready;
  logic [ID_W-1:0]      m_rid;
  logic [MST_DATA_W-1:0]   m_rdata;
  logic [1:0]           m_rresp;
  logic                 m_rlast;
  logic                 m_rvalid;
  logic                 m_rready;

  dw_downsizer #(
    .ADDR_W(ADDR_W), .ID_W(ID_W), .SLV_DATA_W(SLV_DATA_W),
    .MST_DATA_W(MST_DATA_W), .MAX_READS(MAX_READS)
  ) dut (
    .clk_i(clk), .rst_ni(rst_n),
    .s_awid(s_awid), .s_awaddr(s_awaddr), .s_awlen(s_awlen),
    .s_awsize(s_awsize), .s_awburst(s_awburst), .s_awvalid(s_awvalid),
    .s_awready(s_awready),
    .s_wdata(s_wdata), .s_wstrb(s_wstrb), .s_wlast(s_wlast),
    .s_wvalid(s_wvalid), .s_wready(s_wready),
    .s_bid(s_bid), .s_bresp(s_bresp), .s_bvalid(s_bvalid), .s_bready(s_bready),
    .s_arid(s_arid), .s_araddr(s_araddr), .s_arlen(s_arlen),
    .s_arsize(s_arsize), .s_arburst(s_arburst), .s_arvalid(s_arvalid),
    .s_arready(s_arready),
    .s_rid(s_rid), .s_rdata(s_rdata), .s_rresp(s_rresp),
    .s_rlast(s_rlast), .s_rvalid(s_rvalid), .s_rready(s_rready),
    .m_awid(m_awid), .m_awaddr(m_awaddr), .m_awlen(m_awlen),
    .m_awsize(m_awsize), .m_awburst(m_awburst), .m_awvalid(m_awvalid),
    .m_awready(m_awready),
    .m_wdata(m_wdata), .m_wstrb(m_wstrb), .m_wlast(m_wlast),
    .m_wvalid(m_wvalid), .m_wready(m_wready),
    .m_bid(m_bid), .m_bresp(m_bresp), .m_bvalid(m_bvalid), .m_bready(m_bready),
    .m_arid(m_arid), .m_araddr(m_araddr), .m_arlen(m_arlen),
    .m_arsize(m_arsize), .m_arburst(m_arburst), .m_arvalid(m_arvalid),
    .m_arready(m_arready),
    .m_rid(m_rid), .m_rdata(m_rdata), .m_rresp(m_rresp),
    .m_rlast(m_rlast), .m_rvalid(m_rvalid), .m_rready(m_rready)
  );

  // We drive upstream ready + downstream address/data ready always high
  assign s_bready  = 1'b1;
  assign s_rready  = 1'b1;
  assign m_awready = 1'b1;
  assign m_wready  = 1'b1;
  assign m_arready = 1'b1;

  typedef struct packed {
    logic [ID_W-1:0]   id;
    logic [ADDR_W-1:0] addr;
    logic [7:0]        len;
    logic [2:0]        size;
    logic [1:0]        burst;
  } addr_txn_t;

  typedef struct packed {
    logic [MST_DATA_W-1:0]   data;
    logic [MST_DATA_W/8-1:0] strb;
    logic                    last;
  } w_beat_t;

  typedef struct packed {
    logic [ID_W-1:0]     id;
    logic [SLV_DATA_W-1:0] data;
    logic [1:0]          resp;
    logic                last;
  } r_beat_t;

  typedef struct packed {
    logic [ID_W-1:0] id;
    logic [1:0]      resp;
  } b_beat_t;

  addr_txn_t d_aw_q[$];
  addr_txn_t d_ar_q[$];
  w_beat_t   d_w_q[$];
  r_beat_t   u_r_q[$];
  b_beat_t   u_b_q[$];

  addr_txn_t aw_result, ar_result;
  w_beat_t   w_result;
  r_beat_t   r_result;
  b_beat_t   b_result;

  always @(posedge clk) begin
    if (rst_n) begin
      if (m_awvalid && m_awready) begin
        automatic addr_txn_t t;
        t.id = m_awid; t.addr = m_awaddr; t.len = m_awlen;
        t.size = m_awsize; t.burst = m_awburst;
        d_aw_q.push_back(t);
      end
      if (m_arvalid && m_arready) begin
        automatic addr_txn_t t;
        t.id = m_arid; t.addr = m_araddr; t.len = m_arlen;
        t.size = m_arsize; t.burst = m_arburst;
        d_ar_q.push_back(t);
      end
      if (m_wvalid && m_wready) begin
        automatic w_beat_t w;
        w.data = m_wdata; w.strb = m_wstrb; w.last = m_wlast;
        d_w_q.push_back(w);
      end
      if (s_rvalid && s_rready) begin
        automatic r_beat_t r;
        r.id = s_rid; r.data = s_rdata; r.resp = s_rresp; r.last = s_rlast;
        u_r_q.push_back(r);
      end
      if (s_bvalid && s_bready) begin
        automatic b_beat_t b;
        b.id = s_bid; b.resp = s_bresp;
        u_b_q.push_back(b);
      end
    end
  end

  int fail_count = 0;

  task automatic bfm_reset(input int cycles = 4);
    @(negedge clk);
    rst_n = 1'b0;
    repeat (cycles) @(posedge clk);
    @(negedge clk);
    rst_n = 1'b1;
  endtask

  task automatic bfm_aw(
    input logic [ID_W-1:0] id, input logic [ADDR_W-1:0] addr,
    input logic [7:0] len, input logic [2:0] size, input logic [1:0] burst,
    input int budget, output bit accepted);
    accepted = 1'b0;
    @(negedge clk);
    s_awid = id; s_awaddr = addr; s_awlen = len;
    s_awsize = size; s_awburst = burst; s_awvalid = 1'b1;
    for (int i = 0; i < budget && !accepted; i++) begin
      @(posedge clk);
      if (s_awready) accepted = 1'b1;
    end
    @(negedge clk) s_awvalid = 1'b0;
  endtask

  task automatic bfm_ar(
    input logic [ID_W-1:0] id, input logic [ADDR_W-1:0] addr,
    input logic [7:0] len, input logic [2:0] size, input logic [1:0] burst,
    input int budget, output bit accepted);
    accepted = 1'b0;
    @(negedge clk);
    s_arid = id; s_araddr = addr; s_arlen = len;
    s_arsize = size; s_arburst = burst; s_arvalid = 1'b1;
    for (int i = 0; i < budget && !accepted; i++) begin
      @(posedge clk);
      if (s_arready) accepted = 1'b1;
    end
    @(negedge clk) s_arvalid = 1'b0;
  endtask

  task automatic bfm_w(
    input logic [SLV_DATA_W-1:0] data, input logic [SLV_DATA_W/8-1:0] strb,
    input logic last, input int budget, output bit accepted);
    accepted = 1'b0;
    @(negedge clk);
    s_wdata = data; s_wstrb = strb; s_wlast = last; s_wvalid = 1'b1;
    for (int i = 0; i < budget && !accepted; i++) begin
      @(posedge clk);
      if (s_wready) accepted = 1'b1;
    end
    @(negedge clk) s_wvalid = 1'b0;
  endtask

  task automatic m_send_b(input logic [ID_W-1:0] id, input logic [1:0] resp);
    @(negedge clk);
    m_bid = id; m_bresp = resp; m_bvalid = 1'b1;
    forever begin
      @(negedge clk);
      if (m_bready) begin
        @(posedge clk);
        @(negedge clk) m_bvalid = 1'b0;
        break;
      end
    end
  endtask

  task automatic m_send_r(
    input logic [ID_W-1:0] id, input logic [MST_DATA_W-1:0] data,
    input logic [1:0] resp, input logic last);
    @(negedge clk);
    m_rid = id; m_rdata = data; m_rresp = resp; m_rlast = last; m_rvalid = 1'b1;
    forever begin
      @(negedge clk);
      if (m_rready) begin
        @(posedge clk);
        @(negedge clk) m_rvalid = 1'b0;
        break;
      end
    end
  endtask

  function automatic int beat_bytes(input int sz);
    return 1 << sz;
  endfunction

  function automatic logic [ADDR_W-1:0] aligned_addr(
    input logic [ADDR_W-1:0] a, input int sz);
    return a & ~((1 << sz) - 1);
  endfunction

  function automatic int expected_dlen(
    input logic [ADDR_W-1:0] addr, input int sz, input int len);
    int total_bytes, dsize;
    logic [ADDR_W-1:0] first, last, af, al;
    total_bytes = (len + 1) * beat_bytes(sz) - (addr - aligned_addr(addr, sz));
    first = addr;
    last = addr + total_bytes - 1;
    dsize = (sz < 1) ? sz : 1;
    af = aligned_addr(first, dsize);
    al = aligned_addr(last, dsize);
    return (al - af) / beat_bytes(dsize);
  endfunction

  task automatic drain_queues();
    d_aw_q.delete();
    d_ar_q.delete();
    d_w_q.delete();
    u_r_q.delete();
    u_b_q.delete();
  endtask

  task automatic wait_d_aw(output bit ok);
    ok = 1'b0;
    for (int i = 0; i < MAX_CYCLES; i++) begin
      if (d_aw_q.size() > 0) begin
        aw_result = d_aw_q.pop_front();
        ok = 1'b1;
        return;
      end
      @(posedge clk);
    end
  endtask

  task automatic wait_d_ar(output bit ok);
    ok = 1'b0;
    for (int i = 0; i < MAX_CYCLES; i++) begin
      if (d_ar_q.size() > 0) begin
        ar_result = d_ar_q.pop_front();
        ok = 1'b1;
        return;
      end
      @(posedge clk);
    end
  endtask

  task automatic wait_d_w(output bit ok);
    ok = 1'b0;
    for (int i = 0; i < MAX_CYCLES; i++) begin
      if (d_w_q.size() > 0) begin
        w_result = d_w_q.pop_front();
        ok = 1'b1;
        return;
      end
      @(posedge clk);
    end
  endtask

  task automatic wait_u_b(output bit ok);
    ok = 1'b0;
    for (int i = 0; i < MAX_CYCLES; i++) begin
      if (u_b_q.size() > 0) begin
        b_result = u_b_q.pop_front();
        ok = 1'b1;
        return;
      end
      @(posedge clk);
    end
  endtask

  task automatic wait_u_r(output bit ok);
    ok = 1'b0;
    for (int i = 0; i < MAX_CYCLES; i++) begin
      if (u_r_q.size() > 0) begin
        r_result = u_r_q.pop_front();
        ok = 1'b1;
        return;
      end
      @(posedge clk);
    end
  endtask

  // ===== Main test sequence =====
  initial begin
    automatic bit acc;
    automatic bit ok;
    automatic int j;

    bfm_reset(4);

    // ---- Test 1: basic aligned write size 3 len 0 ----
    bfm_aw(4'h1, 32'h1000, 8'd0, 3'd3, 2'b01, MAX_CYCLES, acc);
    if (!acc) begin $display("FAIL: A1 write AW not accepted"); fail_count++; end
    else begin
      bfm_w(64'hAABBCCDDEEFF0011, 8'hFF, 1'b1, MAX_CYCLES, acc);
      if (!acc) begin $display("FAIL: A1 write W not accepted"); fail_count++; end
      else begin
        wait_d_aw(ok);
        if (!ok) begin $display("FAIL: A2 no downstream AW"); fail_count++; end
        else begin
          if (aw_result.id !== 4'h1) begin $display("FAIL: A2 wrong AW id"); fail_count++; end
          if (aw_result.addr !== 32'h1000) begin $display("FAIL: B3 AW addr %h", aw_result.addr); fail_count++; end
          if (aw_result.size !== 3'd1) begin $display("FAIL: B1 AW size %0d", aw_result.size); fail_count++; end
          if (aw_result.len !== 8'd3) begin $display("FAIL: B2 AW len %0d", aw_result.len); fail_count++; end
          if (aw_result.burst !== 2'b01) begin $display("FAIL: B4 AW burst %b", aw_result.burst); fail_count++; end
          for (j = 0; j < 4; j++) begin
            wait_d_w(ok);
            if (!ok) begin $display("FAIL: A2 missing W beat %0d", j); fail_count++; end
            else begin
              case (j)
                0: begin
                  if (w_result.data !== 16'h0011) begin $display("FAIL: E1 W0 data %h", w_result.data); fail_count++; end
                  if (w_result.strb !== 2'b11) begin $display("FAIL: E2 W0 strb %b", w_result.strb); fail_count++; end
                  if (w_result.last !== 1'b0) begin $display("FAIL: E4 W0 last"); fail_count++; end
                end
                1: begin
                  if (w_result.data !== 16'hEEFF) begin $display("FAIL: E1 W1 data %h", w_result.data); fail_count++; end
                  if (w_result.strb !== 2'b11) begin $display("FAIL: E2 W1 strb %b", w_result.strb); fail_count++; end
                  if (w_result.last !== 1'b0) begin $display("FAIL: E4 W1 last"); fail_count++; end
                end
                2: begin
                  if (w_result.data !== 16'hCCDD) begin $display("FAIL: E1 W2 data %h", w_result.data); fail_count++; end
                  if (w_result.strb !== 2'b11) begin $display("FAIL: E2 W2 strb %b", w_result.strb); fail_count++; end
                  if (w_result.last !== 1'b0) begin $display("FAIL: E4 W2 last"); fail_count++; end
                end
                3: begin
                  if (w_result.data !== 16'hAABB) begin $display("FAIL: E1 W3 data %h", w_result.data); fail_count++; end
                  if (w_result.strb !== 2'b11) begin $display("FAIL: E2 W3 strb %b", w_result.strb); fail_count++; end
                  if (w_result.last !== 1'b1) begin $display("FAIL: E4 W3 last"); fail_count++; end
                end
              endcase
            end
          end
          m_send_b(4'h1, 2'b00);
          wait_u_b(ok);
          if (!ok) begin $display("FAIL: A3 no upstream B"); fail_count++; end
          else begin
            if (b_result.id !== 4'h1) begin $display("FAIL: E5 wrong B id"); fail_count++; end
            if (b_result.resp !== 2'b00) begin $display("FAIL: E6 B resp %b", b_result.resp); fail_count++; end
          end
        end
      end
    end
    drain_queues();

    // ---- Test 2: basic aligned read size 3 len 0 ----
    bfm_ar(4'h2, 32'h2000, 8'd0, 3'd3, 2'b01, MAX_CYCLES, acc);
    if (!acc) begin $display("FAIL: A1 read AR not accepted"); fail_count++; end
    else begin
      wait_d_ar(ok);
      if (!ok) begin $display("FAIL: A2 no downstream AR"); fail_count++; end
      else begin
        if (ar_result.id !== 4'h2) begin $display("FAIL: A2 AR id"); fail_count++; end
        if (ar_result.addr !== 32'h2000) begin $display("FAIL: B3 AR addr"); fail_count++; end
        if (ar_result.size !== 3'd1) begin $display("FAIL: B1 AR size %0d", ar_result.size); fail_count++; end
        if (ar_result.len !== 8'd3) begin $display("FAIL: B2 AR len %0d", ar_result.len); fail_count++; end
        if (ar_result.burst !== 2'b01) begin $display("FAIL: B4 AR burst"); fail_count++; end
        m_send_r(4'h2, 16'h1111, 2'b00, 1'b0);
        m_send_r(4'h2, 16'h2222, 2'b00, 1'b0);
        m_send_r(4'h2, 16'h3333, 2'b00, 1'b0);
        m_send_r(4'h2, 16'h4444, 2'b00, 1'b1);
        wait_u_r(ok);
        if (!ok) begin $display("FAIL: A3 no upstream R"); fail_count++; end
        else begin
          if (r_result.id !== 4'h2) begin $display("FAIL: D3 R id"); fail_count++; end
          if (r_result.data !== 64'h4444333322221111) begin $display("FAIL: D1 R data %h", r_result.data); fail_count++; end
          if (r_result.last !== 1'b1) begin $display("FAIL: D4 R last"); fail_count++; end
          if (r_result.resp !== 2'b00) begin $display("FAIL: D5 R resp"); fail_count++; end
        end
      end
    end
    drain_queues();

    // ---- Test 3: multi-beat aligned read size 3 len 1 ----
    bfm_ar(4'h3, 32'h3000, 8'd1, 3'd3, 2'b01, MAX_CYCLES, acc);
    if (!acc) begin $display("FAIL: A1 multi AR not accepted"); fail_count++; end
    else begin
      wait_d_ar(ok);
      if (!ok) begin $display("FAIL: A2 no AR (multi)"); fail_count++; end
      else begin
        if (ar_result.addr !== 32'h3000) begin $display("FAIL: B3 AR addr (multi)"); fail_count++; end
        if (ar_result.size !== 3'd1) begin $display("FAIL: B1 AR size (multi)"); fail_count++; end
        if (ar_result.len !== 8'd7) begin $display("FAIL: B2 AR len (multi) %0d", ar_result.len); fail_count++; end
        if (ar_result.burst !== 2'b01) begin $display("FAIL: B4 AR burst (multi)"); fail_count++; end
        for (j = 0; j < 8; j++) begin
          m_send_r(4'h3, 16'h1000 + j, 2'b00, (j == 7) ? 1'b1 : 1'b0);
        end
        wait_u_r(ok);
        if (!ok) begin $display("FAIL: A3 missing R0 (multi)"); fail_count++; end
        else begin
          if (r_result.data !== {16'h1003, 16'h1002, 16'h1001, 16'h1000}) begin
            $display("FAIL: D1 R0 (multi) %h", r_result.data); fail_count++;
          end
          if (r_result.last !== 1'b0) begin $display("FAIL: D4 R0 last"); fail_count++; end
        end
        wait_u_r(ok);
        if (!ok) begin $display("FAIL: A3 missing R1 (multi)"); fail_count++; end
        else begin
          if (r_result.data !== {16'h1007, 16'h1006, 16'h1005, 16'h1004}) begin
            $display("FAIL: D1 R1 (multi) %h", r_result.data); fail_count++;
          end
          if (r_result.last !== 1'b1) begin $display("FAIL: D4 R1 last"); fail_count++; end
        end
      end
    end
    drain_queues();

    // ---- Test 4: unaligned read size 3 len 1 addr 0x1004 ----
    bfm_ar(4'h4, 32'h1004, 8'd1, 3'd3, 2'b01, MAX_CYCLES, acc);
    if (!acc) begin $display("FAIL: A1 unaligned AR not accepted"); fail_count++; end
    else begin
      wait_d_ar(ok);
      if (!ok) begin $display("FAIL: A2 no AR (unaligned)"); fail_count++; end
      else begin
        if (ar_result.addr !== 32'h1004) begin $display("FAIL: B3 unaligned addr %h", ar_result.addr); fail_count++; end
        if (ar_result.len !== 8'd5) begin $display("FAIL: B2 unaligned len %0d", ar_result.len); fail_count++; end
        m_send_r(4'h4, 16'h1100, 2'b00, 1'b0);
        m_send_r(4'h4, 16'h3322, 2'b00, 1'b0);
        m_send_r(4'h4, 16'h5544, 2'b00, 1'b0);
        m_send_r(4'h4, 16'h7766, 2'b00, 1'b0);
        m_send_r(4'h4, 16'h9988, 2'b00, 1'b0);
        m_send_r(4'h4, 16'hBBAA, 2'b00, 1'b1);
        wait_u_r(ok);
        if (!ok) begin $display("FAIL: A3 missing R0 (unaligned)"); fail_count++; end
        else begin
          if (r_result.data !== 64'h3322110077665544) begin
            $display("FAIL: D2 unaligned R0 %h", r_result.data); fail_count++;
          end
          if (r_result.last !== 1'b0) begin $display("FAIL: D4 unaligned R0 last"); fail_count++; end
        end
        wait_u_r(ok);
        if (!ok) begin $display("FAIL: A3 missing R1 (unaligned)"); fail_count++; end
        else begin
          if (r_result.data[63:32] !== 32'hBBAA9988) begin
            $display("FAIL: D2 unaligned R1 upper %h", r_result.data[63:32]); fail_count++;
          end
          if (r_result.last !== 1'b1) begin $display("FAIL: D4 unaligned R1 last"); fail_count++; end
        end
      end
    end
    drain_queues();

    // ---- Test 5: size 1 read addr 0x5001 ----
    bfm_ar(4'h5, 32'h5001, 8'd0, 3'd1, 2'b01, MAX_CYCLES, acc);
    if (!acc) begin $display("FAIL: A1 size1 AR not accepted"); fail_count++; end
    else begin
      wait_d_ar(ok);
      if (!ok) begin $display("FAIL: A2 no AR (size1)"); fail_count++; end
      else begin
        if (ar_result.addr !== 32'h5001) begin $display("FAIL: B3 size1 addr %h", ar_result.addr); fail_count++; end
        if (ar_result.size !== 3'd1) begin $display("FAIL: B1 size1 size %0d", ar_result.size); fail_count++; end
        if (ar_result.len !== 8'd0) begin $display("FAIL: B2 size1 len %0d", ar_result.len); fail_count++; end
        m_send_r(4'h5, 16'hAB00, 2'b00, 1'b1);
        wait_u_r(ok);
        if (!ok) begin $display("FAIL: A3 missing R (size1)"); fail_count++; end
        else begin
          if (r_result.data[15:8] !== 8'hAB) begin
            $display("FAIL: D2 size1 byte %h", r_result.data[15:8]); fail_count++;
          end
          if (r_result.last !== 1'b1) begin $display("FAIL: D4 size1 last"); fail_count++; end
        end
      end
    end
    drain_queues();

    // ---- Test 6: size 0 read addr 0x6000 ----
    bfm_ar(4'h6, 32'h6000, 8'd0, 3'd0, 2'b01, MAX_CYCLES, acc);
    if (!acc) begin $display("FAIL: A1 size0 AR not accepted"); fail_count++; end
    else begin
      wait_d_ar(ok);
      if (!ok) begin $display("FAIL: A2 no AR (size0)"); fail_count++; end
      else begin
        if (ar_result.size !== 3'd0) begin $display("FAIL: B1 size0 not 0: %0d", ar_result.size); fail_count++; end
        if (ar_result.len !== 8'd0) begin $display("FAIL: B2 size0 len %0d", ar_result.len); fail_count++; end
        m_send_r(4'h6, 16'h1200, 2'b00, 1'b1);
        wait_u_r(ok);
        if (!ok) begin $display("FAIL: A3 missing R (size0)"); fail_count++; end
        else begin
          if (r_result.data[7:0] !== 8'h12) begin
            $display("FAIL: D2 size0 byte %h", r_result.data[7:0]); fail_count++;
          end
        end
      end
    end
    drain_queues();

    // ---- Test 7: FIXED len 0 write accepted (C3) ----
    bfm_aw(4'h7, 32'h7000, 8'd0, 3'd3, 2'b00, MAX_CYCLES, acc);
    if (!acc) begin $display("FAIL: C3 FIXED len0 AW not accepted"); fail_count++; end
    else begin
      bfm_w(64'h0, 8'hFF, 1'b1, MAX_CYCLES, acc);
      if (!acc) begin $display("FAIL: C3 FIXED len0 W not accepted"); fail_count++; end
      else begin
        wait_d_aw(ok);
        if (!ok) begin $display("FAIL: C3 no AW for FIXED len0"); fail_count++; end
        else begin
          if (aw_result.len !== 8'd3) begin $display("FAIL: B2 FIXED dlen %0d", aw_result.len); fail_count++; end
          if (aw_result.burst !== 2'b01) begin $display("FAIL: B4 FIXED burst %b", aw_result.burst); fail_count++; end
          for (j = 0; j < 4; j++) wait_d_w(ok);
          m_send_b(4'h7, 2'b00);
          wait_u_b(ok);
          if (!ok) begin $display("FAIL: C3 no B"); fail_count++; end
          else if (b_result.resp !== 2'b00) begin $display("FAIL: C3 B resp %b", b_result.resp); fail_count++; end
        end
      end
    end
    drain_queues();

    // ---- Test 8: FIXED len 1 write refused (C2/C4) ----
    bfm_aw(4'h8, 32'h8000, 8'd1, 3'd3, 2'b00, MAX_CYCLES, acc);
    if (!acc) begin $display("FAIL: C4 FIXED len1 AW not accepted"); fail_count++; end
    else begin
      bfm_w(64'h1, 8'hFF, 1'b0, MAX_CYCLES, acc);
      if (!acc) begin $display("FAIL: C4 FIXED len1 W0 not accepted"); fail_count++; end
      bfm_w(64'h2, 8'hFF, 1'b1, MAX_CYCLES, acc);
      if (!acc) begin $display("FAIL: C4 FIXED len1 W1 not accepted"); fail_count++; end
      wait_u_b(ok);
      if (!ok) begin $display("FAIL: C4 no B for refused FIXED"); fail_count++; end
      else begin
        if (b_result.id !== 4'h8) begin $display("FAIL: C4 B id"); fail_count++; end
        if (b_result.resp !== 2'b10) begin $display("FAIL: C4 B not SLVERR %b", b_result.resp); fail_count++; end
      end
      repeat (10) @(posedge clk);
      if (d_aw_q.size() > 0) begin $display("FAIL: C4 downstream AW after refusal"); fail_count++; end
      if (d_w_q.size() > 0) begin $display("FAIL: C4 downstream W after refusal"); fail_count++; end
    end
    drain_queues();

    // ---- Test 9: WRAP write refused (C1/C4) ----
    bfm_aw(4'h9, 32'h9000, 8'd3, 3'd3, 2'b10, MAX_CYCLES, acc);
    if (!acc) begin $display("FAIL: C4 WRAP AW not accepted"); fail_count++; end
    else begin
      for (j = 0; j < 4; j++) begin
        bfm_w(64'h0, 8'hFF, (j == 3) ? 1'b1 : 1'b0, MAX_CYCLES, acc);
        if (!acc) begin $display("FAIL: C4 WRAP W%0d not accepted", j); fail_count++; end
      end
      wait_u_b(ok);
      if (!ok) begin $display("FAIL: C4 no B for WRAP"); fail_count++; end
      else if (b_result.resp !== 2'b10) begin
        $display("FAIL: C1 WRAP resp not SLVERR %b", b_result.resp); fail_count++;
      end
      repeat (10) @(posedge clk);
      if (d_aw_q.size() > 0) begin $display("FAIL: C1 downstream AW for WRAP"); fail_count++; end
      if (d_w_q.size() > 0) begin $display("FAIL: C1 downstream W for WRAP"); fail_count++; end
    end
    drain_queues();

    // ---- Test 10: SLVERR on first beat - sticky (D6) ----
    bfm_ar(4'hA, 32'hA000, 8'd0, 3'd3, 2'b01, MAX_CYCLES, acc);
    if (!acc) begin $display("FAIL: A1 err AR not accepted"); fail_count++; end
    else begin
      wait_d_ar(ok);
      if (!ok) begin $display("FAIL: A2 no AR for err"); fail_count++; end
      else begin
        m_send_r(4'hA, 16'h1111, 2'b10, 1'b0);
        m_send_r(4'hA, 16'h2222, 2'b00, 1'b0);
        m_send_r(4'hA, 16'h3333, 2'b00, 1'b0);
        m_send_r(4'hA, 16'h4444, 2'b00, 1'b1);
        wait_u_r(ok);
        if (!ok) begin $display("FAIL: A3 no R for err"); fail_count++; end
        else if (r_result.resp !== 2'b10) begin
          $display("FAIL: D6 not sticky from beat 0: %b", r_result.resp); fail_count++;
        end
      end
    end
    drain_queues();

    // ---- Test 11: SLVERR on last beat only (D6) ----
    bfm_ar(4'hB, 32'hB000, 8'd1, 3'd3, 2'b01, MAX_CYCLES, acc);
    if (!acc) begin $display("FAIL: A1 err2 AR not accepted"); fail_count++; end
    else begin
      wait_d_ar(ok);
      if (!ok) begin $display("FAIL: A2 no AR for err2"); fail_count++; end
      else begin
        for (j = 0; j < 7; j++) m_send_r(4'hB, 16'h1, 2'b00, 1'b0);
        m_send_r(4'hB, 16'h8, 2'b10, 1'b1);
        wait_u_r(ok);
        if (!ok) begin $display("FAIL: A3 no R0 (err2)"); fail_count++; end
        else begin
          if (r_result.resp !== 2'b00) begin
            $display("FAIL: D6 first beat should be OKAY: %b", r_result.resp); fail_count++;
          end
        end
        wait_u_r(ok);
        if (!ok) begin $display("FAIL: A3 no R1 (err2)"); fail_count++; end
        else begin
          if (r_result.resp !== 2'b10) begin
            $display("FAIL: D6 last beat should be SLVERR: %b", r_result.resp); fail_count++;
          end
        end
      end
    end
    drain_queues();

    // ---- Test 12: DECERR preserved (D7) ----
    bfm_ar(4'hC, 32'hC000, 8'd0, 3'd3, 2'b01, MAX_CYCLES, acc);
    if (!acc) begin $display("FAIL: A1 decerr AR not accepted"); fail_count++; end
    else begin
      wait_d_ar(ok);
      if (!ok) begin $display("FAIL: A2 no AR for decerr"); fail_count++; end
      else begin
        m_send_r(4'hC, 16'h1, 2'b11, 1'b0);
        m_send_r(4'hC, 16'h2, 2'b00, 1'b0);
        m_send_r(4'hC, 16'h3, 2'b00, 1'b0);
        m_send_r(4'hC, 16'h4, 2'b00, 1'b1);
        wait_u_r(ok);
        if (!ok) begin $display("FAIL: A3 no R for decerr"); fail_count++; end
        else if (r_result.resp !== 2'b11) begin
          $display("FAIL: D7 DECERR not preserved: %b", r_result.resp); fail_count++;
        end
      end
    end
    drain_queues();

    // ---- Test 13: write with downstream SLVERR (E6) ----
    bfm_aw(4'hD, 32'hD000, 8'd0, 3'd3, 2'b01, MAX_CYCLES, acc);
    if (!acc) begin $display("FAIL: A1 wslverr AW not accepted"); fail_count++; end
    else begin
      bfm_w(64'h0, 8'hFF, 1'b1, MAX_CYCLES, acc);
      wait_d_aw(ok);
      if (!ok) begin $display("FAIL: A2 no AW for wslverr"); fail_count++; end
      else begin
        for (j = 0; j < 4; j++) wait_d_w(ok);
        m_send_b(4'hD, 2'b10);
        wait_u_b(ok);
        if (!ok) begin $display("FAIL: A3 no B for wslverr"); fail_count++; end
        else if (b_result.resp !== 2'b10) begin
          $display("FAIL: E6 B SLVERR not preserved: %b", b_result.resp); fail_count++;
        end
      end
    end
    drain_queues();

    // ---- Test 14: write strb pattern 0x0F (E2/E3) ----
    bfm_aw(4'hE, 32'hE000, 8'd0, 3'd3, 2'b01, MAX_CYCLES, acc);
    if (!acc) begin $display("FAIL: A1 strb AW not accepted"); fail_count++; end
    else begin
      bfm_w(64'h8877665544332211, 8'h0F, 1'b1, MAX_CYCLES, acc);
      wait_d_aw(ok);
      if (!ok) begin $display("FAIL: A2 no AW for strb"); fail_count++; end
      else begin
        wait_d_w(ok);
        if (ok) begin
          if (w_result.strb !== 2'b11) begin $display("FAIL: E2 W0 strb %b", w_result.strb); fail_count++; end
          if (w_result.data !== 16'h2211) begin $display("FAIL: E1 W0 data %h", w_result.data); fail_count++; end
        end else begin $display("FAIL: E2 no W0"); fail_count++; end
        wait_d_w(ok);
        if (ok) begin
          if (w_result.strb !== 2'b11) begin $display("FAIL: E2 W1 strb %b", w_result.strb); fail_count++; end
          if (w_result.data !== 16'h4433) begin $display("FAIL: E1 W1 data %h", w_result.data); fail_count++; end
        end else begin $display("FAIL: E2 no W1"); fail_count++; end
        wait_d_w(ok);
        if (ok) begin
          if (w_result.strb !== 2'b00) begin $display("FAIL: E3 W2 strb %b", w_result.strb); fail_count++; end
        end else begin $display("FAIL: E3 no W2"); fail_count++; end
        wait_d_w(ok);
        if (ok) begin
          if (w_result.strb !== 2'b00) begin $display("FAIL: E3 W3 strb %b", w_result.strb); fail_count++; end
          if (w_result.last !== 1'b1) begin $display("FAIL: E4 W3 last"); fail_count++; end
        end else begin $display("FAIL: E3 no W3"); fail_count++; end
        m_send_b(4'hE, 2'b00);
        wait_u_b(ok);
      end
    end
    drain_queues();

    if (fail_count == 0)
      $display("RESULT: PASS");
    else
      $display("RESULT: FAIL");
    $finish;
  end

  // Watchdog
  initial begin
    #4_000_000;
    $display("RESULT: FAIL (watchdog)");
    $finish;
  end

endmodule
