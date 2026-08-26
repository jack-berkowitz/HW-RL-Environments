// ---------------------------------------------------------------------------
// AXI4 Data-Width Downsizer Testbench
// ---------------------------------------------------------------------------

module dw_downsizer_tb;

    localparam int unsigned ADDR_W     = 32;
    localparam int unsigned ID_W       = 4;
    localparam int unsigned SLV_DATA_W = 64;
    localparam int unsigned MST_DATA_W = 16;
    localparam int unsigned MAX_READS  = 4;

    logic clk_i;
    initial begin clk_i = 1'b0; forever #5 clk_i = ~clk_i; end

    logic rst_ni;

    // Upstream (Slave) Port
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

    // Downstream (Master) Port
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
        .ADDR_W(ADDR_W),
        .ID_W(ID_W),
        .SLV_DATA_W(SLV_DATA_W),
        .MST_DATA_W(MST_DATA_W),
        .MAX_READS(MAX_READS)
    ) dut (
        .*
    );

    task automatic fail(string msg);
        $display("RESULT: FAIL (%s)", msg);
        $finish;
    endtask

    // -------------------------------------------------------------------------
    // BFM Functions and Tasks
    // -------------------------------------------------------------------------
    
    function int calc_expected_dlen(logic [31:0] addr, logic [7:0] len, logic [2:0] size);
        automatic int beat_bytes = 1 << size;
        automatic logic [31:0] mask = ~(32'(beat_bytes) - 1);
        automatic int total_bytes = (len + 1) * beat_bytes - (addr - (addr & mask));
        automatic logic [2:0] dsize = (size < 1) ? size : 1;
        automatic int d_beat_bytes = 1 << dsize;
        automatic logic [31:0] dmask = ~(32'(d_beat_bytes) - 1);
        automatic logic [31:0] first = addr;
        automatic logic [31:0] last = addr + total_bytes - 1;
        automatic logic [31:0] aligned_first = first & dmask;
        automatic logic [31:0] aligned_last  = last & dmask;
        return (aligned_last - aligned_first) / d_beat_bytes;
    endfunction

    task automatic drive_reset();
        @(negedge clk_i);
        rst_ni = 1'b0;
        @(posedge clk_i);
        for (int i=0; i<5; i++) begin
            if (s_bvalid || s_rvalid || m_awvalid || m_wvalid || m_arvalid)
                fail("F1: Valid high during reset");
            @(posedge clk_i);
        end
        @(negedge clk_i);
        rst_ni = 1'b1;
    endtask

    task automatic bfm_ar(input  logic [ID_W-1:0]   id,
                          input  logic [ADDR_W-1:0] addr,
                          input  logic [7:0]        len,
                          input  logic [2:0]        size,
                          input  logic [1:0]        burst,
                          input  int                budget,
                          output bit                accepted,
                          output int                waited);
        accepted = 1'b0; waited = 0;
        @(negedge clk_i);
        s_arid = id; s_araddr = addr; s_arlen = len; s_arsize = size; s_arburst = burst; s_arvalid = 1'b1;
        while (waited < budget) begin
            @(posedge clk_i);
            if (s_arready) begin accepted = 1'b1; break; end
            waited++;
        end
        @(negedge clk_i) s_arvalid = 1'b0;
    endtask

    task automatic bfm_aw(input  logic [ID_W-1:0]   id,
                          input  logic [ADDR_W-1:0] addr,
                          input  logic [7:0]        len,
                          input  logic [2:0]        size,
                          input  logic [1:0]        burst,
                          input  int                budget,
                          output bit                accepted,
                          output int                waited);
        accepted = 1'b0; waited = 0;
        @(negedge clk_i);
        s_awid = id; s_awaddr = addr; s_awlen = len; s_awsize = size; s_awburst = burst; s_awvalid = 1'b1;
        while (waited < budget) begin
            @(posedge clk_i);
            if (s_awready) begin accepted = 1'b1; break; end
            waited++;
        end
        @(negedge clk_i) s_awvalid = 1'b0;
    endtask

    task automatic wait_and_accept_m_ar(output logic [3:0] id, output logic [31:0] addr, output logic [7:0] len, output logic [2:0] size, output logic [1:0] burst);
        @(negedge clk_i);
        m_arready = 1'b1;
        forever begin
            @(posedge clk_i);
            if (m_arvalid) begin
                id = m_arid; addr = m_araddr; len = m_arlen; size = m_arsize; burst = m_arburst;
                break;
            end
        end
        @(negedge clk_i);
        m_arready = 1'b0;
    endtask

    task automatic wait_and_accept_m_aw(output logic [3:0] id, output logic [31:0] addr, output logic [7:0] len, output logic [2:0] size, output logic [1:0] burst);
        @(negedge clk_i);
        m_awready = 1'b1;
        forever begin
            @(posedge clk_i);
            if (m_awvalid) begin
                id = m_awid; addr = m_awaddr; len = m_awlen; size = m_awsize; burst = m_awburst;
                break;
            end
        end
        @(negedge clk_i);
        m_awready = 1'b0;
    endtask

    task automatic bfm_rbeat(input logic [ID_W-1:0] mid, input logic [15:0] data, input logic [1:0] resp, input logic last);
        @(negedge clk_i);
        m_rid = mid; m_rdata = data; m_rlast = last; m_rresp = resp; m_rvalid = 1'b1;
        forever begin @(posedge clk_i); if (m_rready) break; end
        @(negedge clk_i) m_rvalid = 1'b0;
    endtask

    task automatic serve_downstream_r(logic [3:0] id, logic [31:0] start_addr, logic [7:0] dlen, logic [2:0] dsize, logic [1:0] inject_err = 0);
        automatic int d_beat_bytes = 1 << dsize;
        automatic logic [31:0] d_addr = start_addr;
        for (int i = 0; i <= dlen; i++) begin
            automatic logic [15:0] rdata = 0;
            automatic int start_lane = d_addr % d_beat_bytes;
            for (int b = start_lane; b < d_beat_bytes; b++) begin
                automatic logic [31:0] abs_addr = (d_addr & ~(32'(d_beat_bytes)-1)) + b;
                if (b == 0) rdata[7:0] = abs_addr[7:0] ^ 8'hAA;
                if (b == 1) rdata[15:8] = abs_addr[7:0] ^ 8'hAA;
            end
            bfm_rbeat(id, rdata, (inject_err != 0 && i == dlen) ? inject_err : 2'b00, (i == dlen));
            d_addr = (d_addr & ~(32'(d_beat_bytes)-1)) + d_beat_bytes;
        end
    endtask

    task automatic wait_for_r(output logic [3:0] id, output logic [63:0] data, output logic [1:0] resp, output logic last);
        @(negedge clk_i);
        s_rready = 1'b1;
        forever begin
            @(posedge clk_i);
            if (s_rvalid) begin
                id = s_rid; data = s_rdata; resp = s_rresp; last = s_rlast;
                break;
            end
        end
        @(negedge clk_i);
        s_rready = 1'b0;
    endtask

    task automatic check_upstream_r(logic [3:0] exp_id, logic [31:0] start_addr, logic [7:0] len, logic [2:0] size, logic [1:0] expect_err_on_last = 0);
        automatic int beat_bytes = 1 << size;
        automatic logic [31:0] mask = ~(32'(beat_bytes) - 1);
        automatic logic [31:0] cur_addr = start_addr;
        for (int i = 0; i <= len; i++) begin
            automatic logic [3:0] obs_id;
            automatic logic [63:0] obs_data;
            automatic logic [1:0] obs_resp;
            automatic logic obs_last;
            wait_for_r(obs_id, obs_data, obs_resp, obs_last);

            if (obs_id != exp_id) fail("D3: wrong ID");
            if (i == len && obs_last !== 1'b1) fail("D4: missing rlast");
            if (i < len && obs_last === 1'b1) fail("D4: early rlast");

            if (expect_err_on_last != 0) begin
                if (i == len && obs_resp != expect_err_on_last) fail("D6: missing err on last");
                if (i < len && obs_resp != 2'b00) fail("D6: early err");
            end else begin
                if (obs_resp != 2'b00) fail("D5: resp not OKAY");
            end

            // Check Data content
            begin
                automatic int start_lane = cur_addr % beat_bytes;
                for (int b = start_lane; b < beat_bytes; b++) begin
                    automatic logic [31:0] abs_addr = (cur_addr & mask) + b;
                    automatic int lane = abs_addr % 8;
                    automatic logic [7:0] exp_byte = abs_addr[7:0] ^ 8'hAA;
                    automatic logic [7:0] obs_byte = obs_data[lane*8 +: 8];
                    if (obs_byte != exp_byte) fail($sformatf("D1/D2: Data mismatch. Exp %0x got %0x", exp_byte, obs_byte));
                end
            end
            cur_addr = (cur_addr & mask) + beat_bytes;
        end
    endtask

    task automatic bfm_w(input logic [63:0] data, input logic [7:0] strb, input logic last);
        @(negedge clk_i);
        s_wdata = data; s_wstrb = strb; s_wlast = last; s_wvalid = 1'b1;
        forever begin @(posedge clk_i); if (s_wready) break; end
        @(negedge clk_i) s_wvalid = 1'b0;
    endtask

    task automatic send_upstream_w(logic [31:0] start_addr, logic [7:0] len, logic [2:0] size);
        automatic int beat_bytes = 1 << size;
        automatic logic [31:0] mask = ~(32'(beat_bytes) - 1);
        automatic logic [31:0] cur_addr = start_addr;
        for (int i = 0; i <= len; i++) begin
            automatic logic [63:0] wdata = 0;
            automatic logic [7:0] wstrb = 0;
            automatic bit unstrobed_beat = (len >= 1 && i == 1);

            automatic int start_lane = cur_addr % beat_bytes;
            for (int b = start_lane; b < beat_bytes; b++) begin
                automatic logic [31:0] abs_addr = (cur_addr & mask) + b;
                automatic int lane = abs_addr % 8;
                wdata[lane*8 +: 8] = abs_addr[7:0] ^ 8'h55;
                if (!unstrobed_beat) wstrb[lane] = 1'b1;
            end
            bfm_w(wdata, wstrb, (i == len));
            cur_addr = (cur_addr & mask) + beat_bytes;
        end
    endtask

    task automatic check_downstream_w(logic [31:0] start_addr, logic [7:0] up_len, logic [2:0] up_size, logic [7:0] exp_dlen);
        automatic int up_beat_bytes = 1 << up_size;
        automatic logic [2:0] dsize = (up_size < 1) ? up_size : 1;
        automatic int d_beat_bytes = 1 << dsize;
        automatic logic [31:0] d_addr = start_addr;
        automatic logic [31:0] up_aligned_start = start_addr & ~(32'(up_beat_bytes)-1);
        automatic int total_bytes = (up_len + 1) * up_beat_bytes - (start_addr - up_aligned_start);
        automatic logic [31:0] end_addr = start_addr + total_bytes - 1;

        @(negedge clk_i);
        m_wready = 1'b1;

        for (int i = 0; i <= exp_dlen; i++) begin
            automatic logic [15:0] obs_data;
            automatic logic [1:0] obs_strb;
            automatic logic obs_last;
            forever begin
                @(posedge clk_i);
                if (m_wvalid) begin
                    obs_data = m_wdata; obs_strb = m_wstrb; obs_last = m_wlast;
                    break;
                end
            end

            if (i == exp_dlen && obs_last !== 1'b1) fail("E4: missing wlast");
            if (i < exp_dlen && obs_last === 1'b1) fail("E4: early wlast");

            begin
                automatic logic [31:0] d_aligned = d_addr & ~(32'(d_beat_bytes)-1);
                automatic int up_beat_idx = 0;
                automatic bit exp_unstrobed = 0;
                automatic logic [1:0] exp_strb = 0;
                automatic logic [15:0] exp_data = 0;
                automatic int start_lane = d_addr % d_beat_bytes;

                if (d_aligned >= start_addr) up_beat_idx = (d_aligned - up_aligned_start) / up_beat_bytes;
                exp_unstrobed = (up_len >= 1 && up_beat_idx == 1);

                for (int b = start_lane; b < d_beat_bytes; b++) begin
                    automatic logic [31:0] abs_addr = d_aligned + b;
                    automatic logic [7:0] expected_byte = abs_addr[7:0] ^ 8'h55;
                    exp_data[b*8 +: 8] = expected_byte;
                    if (abs_addr >= start_addr && abs_addr <= end_addr && !exp_unstrobed) begin
                        exp_strb[b] = 1'b1;
                    end
                end

                if (obs_strb !== exp_strb) fail("E2/E3: Strobe mismatch");
                for (int lane=0; lane<2; lane++) begin
                    if (exp_strb[lane]) begin
                        if (obs_data[lane*8 +: 8] !== exp_data[lane*8 +: 8]) fail("E1: Data mismatch");
                    end
                end
            end
            d_addr = (d_addr & ~(32'(d_beat_bytes)-1)) + d_beat_bytes;
        end
        @(negedge clk_i);
        m_wready = 1'b0;
    endtask

    task automatic bfm_bbeat(input logic [3:0] mid, input logic [1:0] resp);
        @(negedge clk_i);
        m_bid = mid; m_bresp = resp; m_bvalid = 1'b1;
        forever begin @(posedge clk_i); if (m_bready) break; end
        @(negedge clk_i) m_bvalid = 1'b0;
    endtask

    task automatic wait_for_b(output logic [3:0] id, output logic [1:0] resp);
        @(negedge clk_i);
        s_bready = 1'b1;
        forever begin
            @(posedge clk_i);
            if (s_bvalid) begin
                id = s_bid; resp = s_bresp;
                break;
            end
        end
        @(negedge clk_i);
        s_bready = 1'b0;
    endtask


    // -------------------------------------------------------------------------
    // Top-Level Test Routines
    // -------------------------------------------------------------------------

    task automatic test_read(logic [3:0] id, logic [31:0] addr, logic [7:0] len, logic [2:0] size, logic [1:0] burst, logic [1:0] inject_err = 0);
        automatic bit is_refused = (burst == 2'b10) || (burst == 2'b00 && len > 0);
        automatic int expected_dlen = calc_expected_dlen(addr, len, size);
        automatic logic [2:0] expected_dsize = (size < 1) ? size : 1;
        automatic bit ar_accepted;
        automatic int ar_waited;

        bfm_ar(id, addr, len, size, burst, 100, ar_accepted, ar_waited);
        if (!ar_accepted) fail("A1: AR not accepted");

        if (is_refused) begin
            fork
                begin
                    for (int i=0; i<20; i++) begin
                        @(posedge clk_i);
                        if (m_arvalid) fail("C4: Downstream AR seen for refused transaction");
                    end
                end
                begin
                    for (int i = 0; i <= len; i++) begin
                        automatic logic [3:0] obs_rid;
                        automatic logic [63:0] obs_rdata;
                        automatic logic [1:0] obs_rresp;
                        automatic logic obs_rlast;
                        wait_for_r(obs_rid, obs_rdata, obs_rresp, obs_rlast);
                        if (obs_rid != id) fail("D3: Wrong ID on refused R beat");
                        if (obs_rresp != 2'b10) fail("C4: Refused R beat not SLVERR");
                        if (i == len && obs_rlast !== 1'b1) fail("C4: Last not set on final refused R beat");
                        if (i < len && obs_rlast === 1'b1) fail("C4: Last set early on refused R beat");
                    end
                end
            join
        end else begin
            automatic logic [3:0] obs_arid;
            automatic logic [31:0] obs_araddr;
            automatic logic [7:0] obs_arlen;
            automatic logic [2:0] obs_arsize;
            automatic logic [1:0] obs_arburst;

            wait_and_accept_m_ar(obs_arid, obs_araddr, obs_arlen, obs_arsize, obs_arburst);
            if (obs_araddr != addr) fail("B3: Downstream addr mismatch");
            if (obs_arlen != expected_dlen) fail("B2: Downstream len mismatch");
            if (obs_arsize != expected_dsize) fail("B1: Downstream size mismatch");
            if (expected_dlen > 0 && obs_arburst != 2'b01) fail("B4: Downstream burst must be INCR");

            fork
                begin serve_downstream_r(id, addr, expected_dlen, expected_dsize, inject_err); end
                begin check_upstream_r(id, addr, len, size, inject_err); end
            join
        end
    endtask

    task automatic test_write(logic [3:0] id, logic [31:0] addr, logic [7:0] len, logic [2:0] size, logic [1:0] burst, logic [1:0] inject_err = 0);
        automatic bit is_refused = (burst == 2'b10) || (burst == 2'b00 && len > 0);
        automatic int expected_dlen = calc_expected_dlen(addr, len, size);
        automatic logic [2:0] expected_dsize = (size < 1) ? size : 1;
        automatic bit aw_accepted;
        automatic int aw_waited;

        bfm_aw(id, addr, len, size, burst, 100, aw_accepted, aw_waited);
        if (!aw_accepted) fail("A1: AW not accepted");

        if (is_refused) begin
            fork
                begin send_upstream_w(addr, len, size); end
                begin
                    for (int i=0; i<20; i++) begin
                        @(posedge clk_i);
                        if (m_awvalid || m_wvalid) fail("C4: Downstream req seen for refused transaction");
                    end
                end
                begin
                    automatic logic [3:0] obs_bid;
                    automatic logic [1:0] obs_bresp;
                    wait_for_b(obs_bid, obs_bresp);
                    if (obs_bid != id) fail("C4: wrong ID on refused B");
                    if (obs_bresp != 2'b10) fail("C4: missing SLVERR on refused B");
                end
            join
        end else begin
            automatic logic [3:0] obs_awid;
            automatic logic [31:0] obs_awaddr;
            automatic logic [7:0] obs_awlen;
            automatic logic [2:0] obs_awsize;
            automatic logic [1:0] obs_awburst;

            wait_and_accept_m_aw(obs_awid, obs_awaddr, obs_awlen, obs_awsize, obs_awburst);
            if (obs_awaddr != addr) fail("B3: Downstream AW addr mismatch");
            if (obs_awlen != expected_dlen) fail("B2: Downstream AW len mismatch");
            if (obs_awsize != expected_dsize) fail("B1: Downstream AW size mismatch");
            if (expected_dlen > 0 && obs_awburst != 2'b01) fail("B4: Downstream AW burst not INCR");

            fork
                begin send_upstream_w(addr, len, size); end
                begin
                    check_downstream_w(addr, len, size, expected_dlen);
                    bfm_bbeat(id, inject_err);
                end
                begin
                    automatic logic [3:0] obs_bid;
                    automatic logic [1:0] obs_bresp;
                    wait_for_b(obs_bid, obs_bresp);
                    if (obs_bid != id) fail("E5: Upstream B ID mismatch");
                    if (inject_err != 0) begin
                        if (obs_bresp != inject_err) fail("E6: Upstream B err precedence failed");
                    end else begin
                        if (obs_bresp != 2'b00) fail("E6: Upstream B should be OKAY");
                    end
                end
            join
        end
    endtask

    task automatic test_max_reads();
        automatic bit acc;
        automatic int wait_cycles;

        for(int i=0; i<4; i++) begin
            bfm_ar(i, 32'h2000 + i*16, 0, 3, 1, 100, acc, wait_cycles);
            if (!acc) fail("A4: Could not accept 4 reads");
        end

        fork
            begin
                bfm_ar(4, 32'h2040, 0, 3, 1, 200, acc, wait_cycles);
                if (!acc) fail("A4: 5th read not accepted after retiring 1");
            end
            begin
                automatic logic [3:0] m_id;
                automatic logic [31:0] m_addr;
                automatic logic [7:0] m_len;
                automatic logic [2:0] m_sz;
                automatic logic [1:0] m_brst;
                
                repeat(20) @(posedge clk_i);
                wait_and_accept_m_ar(m_id, m_addr, m_len, m_sz, m_brst);
                fork
                    serve_downstream_r(m_id, m_addr, m_len, m_sz, 0);
                    check_upstream_r(m_id, m_addr, 0, 3, 0);
                join
            end
        join

        for(int i=0; i<4; i++) begin
            automatic logic [3:0] m_id;
            automatic logic [31:0] m_addr;
            automatic logic [7:0] m_len;
            automatic logic [2:0] m_sz;
            automatic logic [1:0] m_brst;
            wait_and_accept_m_ar(m_id, m_addr, m_len, m_sz, m_brst);
            fork
                serve_downstream_r(m_id, m_addr, m_len, m_sz, 0);
                check_upstream_r(m_id, m_addr, 0, 3, 0);
            join
        end
    endtask

    task automatic test_reset_aborts();
        automatic bit acc;
        automatic int wait_cycles;
        automatic logic [3:0] m_id;
        automatic logic [31:0] m_addr;
        automatic logic [7:0] m_len;
        automatic logic [2:0] m_sz;
        automatic logic [1:0] m_brst;
        
        bfm_ar(5, 32'h3000, 0, 3, 1, 100, acc, wait_cycles);
        if (!acc) fail("Reset setup: AR not accepted");

        wait_and_accept_m_ar(m_id, m_addr, m_len, m_sz, m_brst);
        
        drive_reset();

        repeat(10) @(posedge clk_i);
        if (s_rvalid || s_bvalid || m_arvalid || m_awvalid || m_wvalid)
            fail("F3: Transaction produced response/request after reset");

        test_max_reads();
    endtask

    // Watchdog
    initial begin
        #4_000_000;
        $display("RESULT: FAIL (watchdog: no forward progress)");
        $finish;
    end

    // Main Test Sequence
    initial begin
        s_arvalid = 0; s_awvalid = 0; s_wvalid = 0; s_rready = 0; s_bready = 0;
        m_arready = 0; m_awready = 0; m_wready = 0; m_rvalid = 0; m_bvalid = 0;

        drive_reset();

        // Test normal reads
        test_read(0, 32'h1000, 0, 3, 2'b01);
        test_read(1, 32'h1000, 1, 3, 2'b01);
        test_read(2, 32'h1004, 1, 3, 2'b01);
        test_read(3, 32'h1001, 0, 1, 2'b01);
        test_read(4, 32'h1005, 3, 0, 2'b01);
        test_read(5, 32'h1020, 1, 3, 2'b01, 2'b11); // DECERR on last read beat

        // Test normal writes (with unstrobed beat handling tests)
        test_write(6, 32'h2000, 0, 3, 2'b01);
        test_write(7, 32'h2000, 1, 3, 2'b01);
        test_write(8, 32'h2004, 1, 3, 2'b01);
        test_write(9, 32'h2001, 0, 1, 2'b01);
        test_write(10, 32'h2005, 3, 0, 2'b01);
        test_write(11, 32'h2020, 1, 3, 2'b01, 2'b10); // SLVERR on write response

        // Test Refusals
        test_read(12, 32'h3000, 3, 3, 2'b10);  // WRAP
        test_write(13, 32'h3000, 3, 3, 2'b10);
        test_read(14, 32'h4000, 1, 3, 2'b00);  // FIXED len>0
        test_write(15, 32'h4000, 1, 3, 2'b00);

        // FIXED len=0 works normally
        test_read(0, 32'h5000, 0, 3, 2'b00);
        test_write(1, 32'h5000, 0, 3, 2'b00);

        // MAX_READS Limit & Reset Cleanup Testing
        test_reset_aborts();

        $display("RESULT: PASS");
        $finish;
    end
endmodule