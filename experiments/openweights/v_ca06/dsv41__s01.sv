`timescale 1ns/1ps

module dw_downsizer_tb;

  localparam int ADDR_W = 32;
  localparam int ID_W = 4;
  localparam int SLV_DATA_W = 64;
  localparam int MST_DATA_W = 16;
  localparam int MAX_READS = 4;

  logic clk;
  logic rst_n;

  // Upstream
  logic [ID_W-1:0] s_awid;
  logic [ADDR_W-1:0] s_awaddr;
  logic [7:0] s_awlen;
  logic [2:0] s_awsize;
  logic [1:0] s_awburst;
  logic s_awvalid;
  logic s_awready;
  logic [SLV_DATA_W-1:0] s_wdata;
  logic [SLV_DATA_W/8-1:0] s_wstrb;
  logic s_wlast;
  logic s_wvalid;
  logic s_wready;
  logic [ID_W-1:0] s_bid;
  logic [1:0] s_bresp;
  logic s_bvalid;
  logic s_bready;
  logic [ID_W-1:0] s_arid;
  logic [ADDR_W-1:0] s_araddr;
  logic [7:0] s_arlen;
  logic [2:0] s_arsize;
  logic [1:0] s_arburst;
  logic s_arvalid;
  logic s_arready;
  logic [ID_W-1:0] s_rid;
  logic [SLV_DATA_W-1:0] s_rdata;
  logic [1:0] s_rresp;
  logic s_rlast;
  logic s_rvalid;
  logic s_rready;

  // Downstream
  logic [ID_W-1:0] m_awid;
  logic [ADDR_W-1:0] m_awaddr;
  logic [7:0] m_awlen;
  logic [2:0] m_awsize;
  logic [1:0] m_awburst;
  logic m_awvalid;
  logic m_awready;
  logic [MST_DATA_W-1:0] m_wdata;
  logic [MST_DATA_W/8-1:0] m_wstrb;
  logic m_wlast;
  logic m_wvalid;
  logic m_wready;
  logic [ID_W-1:0] m_bid;
  logic [1:0] m_bresp;
  logic m_bvalid;
  logic m_bready;
  logic [ID_W-1:0] m_arid;
  logic [ADDR_W-1:0] m_araddr;
  logic [7:0] m_arlen;
  logic [2:0] m_arsize;
  logic [1:0] m_arburst;
  logic m_arvalid;
  logic m_arready;
  logic [ID_W-1:0] m_rid;
  logic [MST_DATA_W-1:0] m_rdata;
  logic [1:0] m_rresp;
  logic m_rlast;
  logic m_rvalid;
  logic m_rready;

  dw_downsizer #(
    .ADDR_W(ADDR_W),
    .ID_W(ID_W),
    .SLV_DATA_W(SLV_DATA_W),
    .MST_DATA_W(MST_DATA_W),
    .MAX_READS(MAX_READS)
  ) dut (.*);

  initial begin clk = 1'b0; forever #5 clk = ~clk; end

  initial begin
    rst_n = 1'b0;
    repeat (4) @(posedge clk);
    @(negedge clk);
    rst_n = 1'b1;
  end

  int errors = 0;

  function automatic logic [7:0] byte_at(input logic [31:0] a);
    return a[7:0] ^ 8'h5A;
  endfunction

  function automatic int calc_total_bytes(
      input logic [ADDR_W-1:0] addr,
      input logic [7:0] len,
      input logic [2:0] size
  );
    automatic int beat_bytes = 1 << size;
    automatic int aligned_addr = addr & ~((1 << size) - 1);
    return (len + 1) * beat_bytes - (addr - aligned_addr);
  endfunction

  function automatic int calc_down_len(
      input logic [ADDR_W-1:0] addr,
      input logic [7:0] len,
      input logic [2:0] size
  );
    automatic int total_bytes = calc_total_bytes(addr, len, size);
    automatic int dsize = (size > 1) ? 1 : size;
    automatic int dbeat_bytes = 1 << dsize;
    automatic int first = addr;
    automatic int last = addr + total_bytes - 1;
    automatic int aligned_first = first & ~(dbeat_bytes - 1);
    automatic int aligned_last = last & ~(dbeat_bytes - 1);
    return (aligned_last - aligned_first) / dbeat_bytes;
  endfunction

  function automatic logic [SLV_DATA_W-1:0] expected_upstream_data(
      input logic [ADDR_W-1:0] addr,
      input int total_bytes,
      input int beat_idx
  );
    logic [SLV_DATA_W-1:0] d;
    d = '0;
    for (int i = 0; i < 8; i++) begin
      automatic int a = addr + beat_idx * 8 + i;
      if (a < addr + total_bytes) begin
        automatic int lane = a % 8;
        d[lane * 8 +: 8] = byte_at(a);
      end
    end
    return d;
  endfunction

  function automatic logic [SLV_DATA_W-1:0] upstream_mask(
      input logic [ADDR_W-1:0] addr,
      input int total_bytes,
      input int beat_idx
  );
    logic [SLV_DATA_W-1:0] m;
    m = '0;
    for (int i = 0; i < 8; i++) begin
      automatic int a = addr + beat_idx * 8 + i;
      if (a < addr + total_bytes) begin
        automatic int lane = a % 8;
        m[lane * 8 +: 8] = 8'hFF;
      end
    end
    return m;
  endfunction

  function automatic logic [SLV_DATA_W-1:0] make_wdata(
      input logic [ADDR_W-1:0] addr,
      input int beat_idx
  );
    logic [SLV_DATA_W-1:0] d;
    d = '0;
    for (int i = 0; i < 8; i++) begin
      automatic int a = addr + beat_idx * 8 + i;
      automatic int lane = a % 8;
      d[lane * 8 +: 8] = byte_at(a);
    end
    return d;
  endfunction

  function automatic logic [SLV_DATA_W/8-1:0] make_wstrb(
      input logic [ADDR_W-1:0] addr,
      input int beat_idx,
      input logic [SLV_DATA_W/8-1:0] pattern
  );
    logic [SLV_DATA_W/8-1:0] s;
    s = '0;
    for (int i = 0; i < 8; i++) begin
      automatic int a = addr + beat_idx * 8 + i;
      automatic int lane = a % 8;
      s[lane] = pattern[lane];
    end
    return s;
  endfunction

  // Downstream slave: always ready
  assign m_awready = rst_n;
  assign m_wready = rst_n;
  assign m_arready = rst_n;
  assign m_bready = 1'b1;
  assign m_rready = 1'b1;

  // Upstream response ready
  assign s_bready = 1'b1;
  assign s_rready = 1'b1;

  // Capture queues
  logic [ID_W-1:0] cap_aw_id[$];
  logic [ADDR_W-1:0] cap_aw_addr[$];
  logic [7:0] cap_aw_len[$];
  logic [2:0] cap_aw_size[$];
  logic [1:0] cap_aw_burst[$];

  logic [MST_DATA_W-1:0] cap_w_data[$];
  logic [MST_DATA_W/8-1:0] cap_w_strb[$];
  logic cap_w_last[$];

  logic [ID_W-1:0] cap_ar_id[$];
  logic [ADDR_W-1:0] cap_ar_addr[$];
  logic [7:0] cap_ar_len[$];
  logic [2:0] cap_ar_size[$];
  logic [1:0] cap_ar_burst[$];

  always @(posedge clk) begin
    if (rst_n) begin
      if (m_awvalid && m_awready) begin
        cap_aw_id.push_back(m_awid);
        cap_aw_addr.push_back(m_awaddr);
        cap_aw_len.push_back(m_awlen);
        cap_aw_size.push_back(m_awsize);
        cap_aw_burst.push_back(m_awburst);
      end
      if (m_wvalid && m_wready) begin
        cap_w_data.push_back(m_wdata);
        cap_w_strb.push_back(m_wstrb);
        cap_w_last.push_back(m_wlast);
      end
      if (m_arvalid && m_arready) begin
        cap_ar_id.push_back(m_arid);
        cap_ar_addr.push_back(m_araddr);
        cap_ar_len.push_back(m_arlen);
        cap_ar_size.push_back(m_arsize);
        cap_ar_burst.push_back(m_arburst);
      end
    end
  end

  // Downstream response drivers
  logic m_rvalid_r = 1'b0;
  logic [ID_W-1:0] m_rid_r;
  logic [MST_DATA_W-1:0] m_rdata_r;
  logic [1:0] m_rresp_r;
  logic m_rlast_r;

  assign m_rvalid = m_rvalid_r;
  assign m_rid = m_rid_r;
  assign m_rdata = m_rdata_r;
  assign m_rresp = m_rresp_r;
  assign m_rlast = m_rlast_r;

  logic m_bvalid_r = 1'b0;
  logic [ID_W-1:0] m_bid_r;
  logic [1:0] m_bresp_r;

  assign m_bvalid = m_bvalid_r;
  assign m_bid = m_bid_r;
  assign m_bresp = m_bresp_r;

  // Tasks
  task automatic drive_aw(
      input logic [ID_W-1:0] id,
      input logic [ADDR_W-1:0] addr,
      input logic [7:0] len,
      input logic [2:0] size,
      input logic [1:0] burst,
      output bit accepted
  );
    @(negedge clk);
    s_awid = id; s_awaddr = addr; s_awlen = len; s_awsize = size; s_awburst = burst;
    s_awvalid = 1'b1;
    accepted = 0;
    for (int i = 0; i < 200; i++) begin
      @(posedge clk);
      if (s_awready) begin accepted = 1; break; end
    end
    @(negedge clk);
    s_awvalid = 1'b0;
  endtask

  task automatic drive_ar(
      input logic [ID_W-1:0] id,
      input logic [ADDR_W-1:0] addr,
      input logic [7:0] len,
      input logic [2:0] size,
      input logic [1:0] burst,
      output bit accepted
  );
    @(negedge clk);
    s_arid = id; s_araddr = addr; s_arlen = len; s_arsize = size; s_arburst = burst;
    s_arvalid = 1'b1;
    accepted = 0;
    for (int i = 0; i < 200; i++) begin
      @(posedge clk);
      if (s_arready) begin accepted = 1; break; end
    end
    @(negedge clk);
    s_arvalid = 1'b0;
  endtask

  task automatic drive_w(
      input logic [SLV_DATA_W-1:0] data,
      input logic [SLV_DATA_W/8-1:0] strb,
      input logic last
  );
    @(negedge clk);
    s_wdata = data; s_wstrb = strb; s_wlast = last;
    s_wvalid = 1'b1;
    for (int i = 0; i < 200; i++) begin
      @(posedge clk);
      if (s_wready) break;
    end
    @(negedge clk);
    s_wvalid = 1'b0;
  endtask

  task automatic wait_b(
      input logic [ID_W-1:0] exp_id,
      input logic [1:0] exp_resp,
      input int timeout,
      output bit ok
  );
    ok = 0;
    for (int i = 0; i < timeout; i++) begin
      @(posedge clk);
      if (s_bvalid) begin
        if (s_bid !== exp_id) begin
          $display("FAIL: E5 - B id mismatch: got %0d exp %0d", s_bid, exp_id);
          errors++;
        end
        if (s_bresp !== exp_resp) begin
          $display("FAIL: E6 - B resp mismatch: got %0d exp %0d", s_bresp, exp_resp);
          errors++;
        end
        ok = 1;
        break;
      end
    end
  endtask

  task automatic wait_r_beats(
      input logic [ID_W-1:0] exp_id,
      input logic [ADDR_W-1:0] addr,
      input logic [7:0] len,
      input logic [2:0] size,
      input logic [1:0] exp_resp,
      input bit refused,
      input int timeout
  );
    automatic int total_bytes = calc_total_bytes(addr, len, size);
    automatic int num_beats = len + 1;
    for (int b = 0; b < num_beats; b++) begin
      automatic bit got;
      got = 0;
      for (int i = 0; i < timeout; i++) begin
        @(posedge clk);
        if (s_rvalid) begin
          got = 1;
          if (s_rid !== exp_id) begin
            $display("FAIL: D3 - R id mismatch at beat %0d", b);
            errors++;
          end
          if (s_rlast !== (b == num_beats - 1)) begin
            $display("FAIL: D4 - R last mismatch at beat %0d", b);
            errors++;
          end
          if (s_rresp !== exp_resp) begin
            $display("FAIL: D5/D7 - R resp mismatch at beat %0d: got %0d exp %0d", b, s_rresp, exp_resp);
            errors++;
          end
          if (!refused) begin
            automatic logic [SLV_DATA_W-1:0] exp_data;
            automatic logic [SLV_DATA_W-1:0] mask;
            exp_data = expected_upstream_data(addr, total_bytes, b);
            mask = upstream_mask(addr, total_bytes, b);
            if ((s_rdata & mask) !== (exp_data & mask)) begin
              $display("FAIL: D1 - R data mismatch at beat %0d: got %h exp %h mask %h", b, s_rdata, exp_data, mask);
              errors++;
            end
          end
          break;
        end
      end
      if (!got) begin
        $display("FAIL: A3 - timeout waiting for R beat %0d", b);
        errors++;
        break;
      end
    end
  endtask

  task automatic wait_cap_aw(input int timeout, output bit ok);
    ok = 0;
    for (int i = 0; i < timeout; i++) begin
      @(posedge clk);
      if (cap_aw_id.size() > 0) begin ok = 1; break; end
    end
  endtask

  task automatic wait_cap_w(input int n, input int timeout, output bit ok);
    ok = 0;
    for (int i = 0; i < timeout; i++) begin
      @(posedge clk);
      if (cap_w_data.size() >= n) begin ok = 1; break; end
    end
  endtask

  task automatic wait_cap_ar(input int timeout, output bit ok);
    ok = 0;
    for (int i = 0; i < timeout; i++) begin
      @(posedge clk);
      if (cap_ar_id.size() > 0) begin ok = 1; break; end
    end
  endtask

  task automatic respond_write(input logic [ID_W-1:0] id, input logic [1:0] resp);
    @(negedge clk);
    m_bvalid_r = 1'b1; m_bid_r = id; m_bresp_r = resp;
    @(posedge clk);
    @(negedge clk);
    m_bvalid_r = 1'b0;
  endtask

  task automatic test_write(
      input logic [ID_W-1:0] id,
      input logic [ADDR_W-1:0] addr,
      input logic [7:0] len,
      input logic [2:0] size,
      input logic [1:0] burst,
      input logic [SLV_DATA_W/8-1:0] strb_pattern,
      input bit refused,
      input logic [1:0] down_resp
  );
    automatic bit aw_acc;
    automatic bit aw_ok;
    automatic bit w_ok;
    automatic bit b_ok;
    automatic int exp_down_len = calc_down_len(addr, len, size);
    automatic int exp_down_beats = exp_down_len + 1;
    automatic logic [2:0] exp_down_size = (size > 1) ? 1 : size;
    automatic logic [1:0] exp_down_burst = (exp_down_len > 0) ? 2'b01 : 2'b00;

    drive_aw(id, addr, len, size, burst, aw_acc);
    if (!aw_acc) begin
      $display("FAIL: A1 - s_aw not accepted");
      errors++;
      return;
    end

    fork
      begin
        for (int i = 0; i <= len; i++) begin
          automatic logic [SLV_DATA_W-1:0] wd;
          automatic logic [SLV_DATA_W/8-1:0] ws;
          wd = make_wdata(addr, i);
          ws = make_wstrb(addr, i, strb_pattern);
          drive_w(wd, ws, i == len);
        end
      end
      begin
        if (refused) begin
          wait_b(id, 2'b10, 1000, b_ok);
          if (!b_ok) begin
            $display("FAIL: C4 - no B for refused write");
            errors++;
          end
          if (cap_aw_id.size() > 0 || cap_w_data.size() > 0) begin
            $display("FAIL: C4 - refused write produced downstream transaction");
            errors++;
          end
        end else begin
          wait_cap_aw(1000, aw_ok);
          if (!aw_ok) begin
            $display("FAIL: A2 - no downstream AW");
            errors++;
          end else begin
            if (cap_aw_id[0] !== id) begin
              $display("FAIL: A2 - AW id mismatch");
              errors++;
            end
            if (cap_aw_addr[0] !== addr) begin
              $display("FAIL: B3 - AW addr mismatch");
              errors++;
            end
            if (cap_aw_len[0] !== exp_down_len[7:0]) begin
              $display("FAIL: B2 - AW len mismatch: got %0d exp %0d", cap_aw_len[0], exp_down_len);
              errors++;
            end
            if (cap_aw_size[0] !== exp_down_size) begin
              $display("FAIL: B1 - AW size mismatch: got %0d exp %0d", cap_aw_size[0], exp_down_size);
              errors++;
            end
            if (exp_down_len > 0 && cap_aw_burst[0] !== exp_down_burst) begin
              $display("FAIL: B4 - AW burst mismatch");
              errors++;
            end
          end
          wait_cap_w(exp_down_beats, 1000, w_ok);
          if (!w_ok) begin
            $display("FAIL: A2 - not enough downstream W beats: got %0d exp %0d", cap_w_data.size(), exp_down_beats);
            errors++;
          end else begin
            for (int i = 0; i < exp_down_beats; i++) begin
              automatic logic [MST_DATA_W-1:0] exp_data;
              automatic logic [MST_DATA_W/8-1:0] exp_strb;
              automatic logic [MST_DATA_W-1:0] dmask;
              automatic int dbeat_bytes = 1 << exp_down_size;
              exp_data = '0;
              exp_strb = '0;
              dmask = '0;
              for (int j = 0; j < dbeat_bytes; j++) begin
                automatic int byte_addr = addr + i * dbeat_bytes + j;
                automatic int up_beat = (byte_addr - addr) / 8;
                automatic int up_lane = byte_addr % 8;
                if (byte_addr < addr + calc_total_bytes(addr, len, size)) begin
                  exp_data[j * 8 +: 8] = byte_at(byte_addr);
                  dmask[j * 8 +: 8] = 8'hFF;
                  if (up_beat <= len) begin
                    exp_strb[j] = make_wstrb(addr, up_beat, strb_pattern)[up_lane];
                  end
                end
              end
              if ((cap_w_data[i] & dmask) !== (exp_data & dmask)) begin
                $display("FAIL: E1 - W data mismatch at beat %0d: got %h exp %h mask %h", i, cap_w_data[i], exp_data, dmask);
                errors++;
              end
              if (cap_w_strb[i] !== exp_strb) begin
                $display("FAIL: E2 - W strb mismatch at beat %0d: got %h exp %h", i, cap_w_strb[i], exp_strb);
                errors++;
              end
              if (cap_w_last[i] !== (i == exp_down_beats - 1)) begin
                $display("FAIL: E4 - W last mismatch at beat %0d", i);
                errors++;
              end
            end
          end
          respond_write(id, down_resp);
          wait_b(id, down_resp, 1000, b_ok);
          if (!b_ok) begin
            $display("FAIL: A3 - no B");
            errors++;
          end
        end
      end
    join
  endtask

  task automatic test_read(
      input logic [ID_W-1:0] id,
      input logic [ADDR_W-1:0] addr,
      input logic [7:0] len,
      input logic [2:0] size,
      input logic [1:0] burst,
      input bit refused,
      input logic [1:0] down_resp,
      input int err_beat
  );
    automatic bit ar_acc;
    automatic bit ar_ok;
    automatic int exp_down_len = calc_down_len(addr, len, size);
    automatic int exp_down_beats = exp_down_len + 1;
    automatic logic [2:0] exp_down_size = (size > 1) ? 1 : size;
    automatic logic [1:0] exp_down_burst = (exp_down_len > 0) ? 2'b01 : 2'b00;
    automatic logic [1:0] exp_up_resp;

    drive_ar(id, addr, len, size, burst, ar_acc);
    if (!ar_acc) begin
      $display("FAIL: A1 - s_ar not accepted");
      errors++;
      return;
    end

    if (refused) begin
      wait_r_beats(id, addr, len, size, 2'b10, 1, 1000);
      if (cap_ar_id.size() > 0) begin
        $display("FAIL: C4 - refused read produced downstream transaction");
        errors++;
      end
    end else begin
      wait_cap_ar(1000, ar_ok);
      if (!ar_ok) begin
        $display("FAIL: A2 - no downstream AR");
        errors++;
      end else begin
        if (cap_ar_id[0] !== id) begin
          $display("FAIL: A2 - AR id mismatch");
          errors++;
        end
        if (cap_ar_addr[0] !== addr) begin
          $display("FAIL: B3 - AR addr mismatch");
          errors++;
        end
        if (cap_ar_len[0] !== exp_down_len[7:0]) begin
          $display("FAIL: B2 - AR len mismatch: got %0d exp %0d", cap_ar_len[0], exp_down_len);
          errors++;
        end
        if (cap_ar_size[0] !== exp_down_size) begin
          $display("FAIL: B1 - AR size mismatch: got %0d exp %0d", cap_ar_size[0], exp_down_size);
          errors++;
        end
        if (exp_down_len > 0 && cap_ar_burst[0] !== exp_down_burst) begin
          $display("FAIL: B4 - AR burst mismatch");
          errors++;
        end
      end
      for (int b = 0; b < exp_down_beats; b++) begin
        automatic logic [1:0] r;
        automatic int dbeat_bytes = 1 << exp_down_size;
        r = 2'b00;
        if (err_beat >= 0 && b >= err_beat) r = down_resp;
        @(negedge clk);
        m_rvalid_r = 1'b1;
        m_rid_r = id;
        m_rdata_r = '0;
        for (int j = 0; j < dbeat_bytes; j++) begin
          m_rdata_r[j * 8 +: 8] = byte_at(addr + b * dbeat_bytes + j);
        end
        m_rresp_r = r;
        m_rlast_r = (b == exp_down_beats - 1);
        @(posedge clk);
      end
      @(negedge clk);
      m_rvalid_r = 1'b0;
      exp_up_resp = (err_beat >= 0) ? down_resp : 2'b00;
      wait_r_beats(id, addr, len, size, exp_up_resp, 0, 1000);
    end
  endtask

  // F1: no valid during reset
  always @(posedge clk) begin
    if (!rst_n) begin
      if (s_bvalid !== 1'b0 || s_rvalid !== 1'b0 ||
          m_awvalid !== 1'b0 || m_wvalid !== 1'b0 || m_arvalid !== 1'b0) begin
        $display("FAIL: F1 - valid asserted during reset");
        errors++;
      end
    end
  end

  // Test sequence
  initial begin
    wait (rst_n == 1'b1);
    repeat (2) @(posedge clk);

    // Writes
    test_write(4'h1, 32'h1000, 8'd0, 3'd3, 2'b01, 8'hFF, 0, 2'b00);
    test_write(4'h2, 32'h1000, 8'd1, 3'd3, 2'b01, 8'hFF, 0, 2'b00);
    test_write(4'h3, 32'h1004, 8'd1, 3'd3, 2'b01, 8'hFF, 0, 2'b00);
    test_write(4'h4, 32'h1002, 8'd0, 3'd1, 2'b01, 8'hFF, 0, 2'b00);
    test_write(4'h5, 32'h1001, 8'd0, 3'd0, 2'b01, 8'hFF, 0, 2'b00);
    test_write(4'h6, 32'h1000, 8'd0, 3'd3, 2'b01, 8'h81, 0, 2'b00);
    test_write(4'h7, 32'h1000, 8'd0, 3'd3, 2'b01, 8'h0F, 0, 2'b00);
    test_write(4'h8, 32'h1000, 8'd0, 3'd3, 2'b01, 8'hFF, 0, 2'b10);
    test_write(4'h9, 32'h1000, 8'd0, 3'd3, 2'b01, 8'hFF, 0, 2'b11);
    test_write(4'hA, 32'h1000, 8'd0, 3'd3, 2'b00, 8'hFF, 0, 2'b00);
    test_write(4'hB, 32'h1000, 8'd1, 3'd3, 2'b00, 8'hFF, 1, 2'b00);
    test_write(4'hC, 32'h1000, 8'd0, 3'd3, 2'b10, 8'hFF, 1, 2'b00);

    // Reads
    test_read(4'h1, 32'h1000, 8'd0, 3'd3, 2'b01, 0, 2'b00, -1);
    test_read(4'h2, 32'h1000, 8'd1, 3'd3, 2'b01, 0, 2'b00, -1);
    test_read(4'h3, 32'h1004, 8'd1, 3'd3, 2'b01, 0, 2'b00, -1);
    test_read(4'h4, 32'h1002, 8'd0, 3'd1, 2'b01, 0, 2'b00, -1);
    test_read(4'h5, 32'h1001, 8'd0, 3'd0, 2'b01, 0, 2'b00, -1);
    test_read(4'h6, 32'h1000, 8'd1, 3'd3, 2'b01, 0, 2'b10, 0);
    test_read(4'h7, 32'h1000, 8'd1, 3'd3, 2'b01, 0, 2'b10, 3);
    test_read(4'h8, 32'h1000, 8'd1, 3'd3, 2'b01, 0, 2'b10, 7);
    test_read(4'h9, 32'h1000, 8'd1, 3'd3, 2'b01, 0, 2'b11, 0);
    test_read(4'hA, 32'h1000, 8'd0, 3'd3, 2'b00, 0, 2'b00, -1);
    test_read(4'hB, 32'h1000, 8'd1, 3'd3, 2'b00, 1, 2'b00, -1);
    test_read(4'hC, 32'h1000, 8'd0, 3'd3, 2'b10, 1, 2'b00, -1);

    if (errors == 0) $display("RESULT: PASS");
    else $display("RESULT: FAIL (%0d errors)", errors);
    $finish;
  end

  // Watchdog
  initial begin
    #4_000_000;
    $display("RESULT: FAIL (watchdog: no forward progress)");
    $finish;
  end

endmodule
