module dw_downsizer_tb;

    // ---------------------------------------------------------------------------
    // PARAMETERS & SIGNALS
    // ---------------------------------------------------------------------------
    localparam int unsigned ADDR_W     = 32;
    localparam int unsigned ID_W       = 4;
    localparam int unsigned SLV_DATA_W = 64;
    localparam int unsigned MST_DATA_W = 16;
    localparam int unsigned MAX_READS  = 4;

    logic clk_i;
    logic rst_ni;

    // Upstream (slave) port
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

    // Downstream (master) port
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
        .ADDR_W(ADDR_W),
        .ID_W(ID_W),
        .SLV_DATA_W(SLV_DATA_W),
        .MST_DATA_W(MST_DATA_W),
        .MAX_READS(MAX_READS)
    ) dut (.*);

    // ---------------------------------------------------------------------------
    // PLUMBING & UTILITIES
    // ---------------------------------------------------------------------------
    initial begin clk_i = 1'b0; forever #5 clk_i = ~clk_i; end

    task automatic bfm_reset(input int cycles = 4);
        @(negedge clk_i);
        rst_ni = 1'b0;
        repeat (cycles) @(posedge clk_i);
        @(negedge clk_i);
        rst_ni = 1'b1;
    endtask

    initial begin
        #4_000_000;
        $display("RESULT: FAIL (watchdog: no forward progress)");
        $finish;
    end

    task automatic fail(string msg);
        $display("RESULT: FAIL (%s)", msg);
        $finish;
    endtask

    function automatic logic [31:0] aligned(logic [31:0] addr, logic [2:0] size);
        automatic logic [31:0] mask = (1 << size) - 1;
        return addr & ~mask;
    endfunction

    function automatic int total_bytes(logic [31:0] addr, logic [7:0] len, logic [2:0] size);
        return (len + 1) * (1 << size) - (addr - aligned(addr, size));
    endfunction

    function automatic logic [7:0] exp_dlen(logic [31:0] addr, logic [7:0] len, logic [2:0] size);
        automatic logic [31:0] first = addr;
        automatic int tb = total_bytes(addr, len, size);
        automatic logic [31:0] last = addr + tb - 1;
        automatic logic [2:0] dsize = (size > 1) ? 1 : size;
        return (aligned(last, dsize) - aligned(first, dsize)) / (1 << dsize);
    endfunction

    function automatic logic [31:0] next_addr(logic [31:0] addr, logic [2:0] size);
        return aligned(addr, size) + (1 << size);
    endfunction

    // ---------------------------------------------------------------------------
    // EXPECTATION TRACKING MODELS
    // ---------------------------------------------------------------------------
    typedef struct {
        logic [ID_W-1:0] id;
        logic [ADDR_W-1:0] addr;
        logic [7:0] len;
        logic [2:0] size;
        logic [1:0] burst;
        logic [1:0] expected_strobes[256];
    } req_t;

    typedef struct {
        logic [ID_W-1:0] id;
        logic [ADDR_W-1:0] addr;
        logic [7:0] len;
        logic [2:0] size;
        logic [1:0] burst;
        logic is_refused;
        int beat_count;
        logic [1:0] expected_resp;
    } s_ar_t;

    typedef struct {
        logic [ID_W-1:0] id;
        logic [ADDR_W-1:0] addr;
        logic [7:0] len;
        logic [2:0] size;
        logic [1:0] burst;
        logic is_refused;
    } s_aw_t;

    typedef struct {
        logic [ID_W-1:0] id;
        logic [ADDR_W-1:0] addr;
        logic [7:0] len;
        logic [2:0] size;
        int beat_count;
        logic [1:0] expected_strobes[256];
    } m_aw_t;

    typedef struct {
        logic [ID_W-1:0] id;
        logic [ADDR_W-1:0] addr;
        logic [7:0] len;
        logic [2:0] size;
    } m_ar_t;

    typedef struct {
        logic [ID_W-1:0] id;
        logic [1:0] resp;
    } b_resp_t;

    req_t exp_m_ar[$];
    req_t exp_m_aw[$];

    s_ar_t pending_s_ar[$];
    s_aw_t pending_s_aw[$];
    m_aw_t pending_m_aw[$];
    m_ar_t pending_m_ar[$];
    b_resp_t b_resp_q[$];

    // ---------------------------------------------------------------------------
    // BFM TRANSACTORS
    // ---------------------------------------------------------------------------
    task automatic expect_downstream(logic [ID_W-1:0] id, logic [ADDR_W-1:0] addr, logic [7:0] len, logic [2:0] size, logic [1:0] burst, logic is_write);
        automatic logic is_refused = (burst == 2'b10) || (burst == 2'b00 && len != 0);
        if (!is_refused) begin
            automatic req_t exp;
            exp.id = id;
            exp.addr = addr;
            exp.size = (size > 1) ? 1 : size;
            exp.len = exp_dlen(addr, len, size);
            exp.burst = (exp.len == 0) ? 2'bxx : 2'b01; 

            if (is_write) begin
                automatic logic [31:0] d_addr = addr;
                for (int db = 0; db <= exp.len; db++) begin
                    automatic logic [31:0] d_al = aligned(d_addr, exp.size);
                    automatic logic [1:0] d_strb = 0;
                    for (int i = 0; i < 2; i++) begin
                        automatic logic [31:0] A = d_al + i;
                        automatic logic is_valid = 0;
                        automatic logic [31:0] u_cur = addr;
                        for (int ub = 0; ub <= len; ub++) begin
                            automatic logic [31:0] u_al = aligned(u_cur, size);
                            automatic int tb = total_bytes(addr, len, size);
                            automatic logic [31:0] u_start = (ub == 0) ? addr : u_al;
                            automatic logic [31:0] u_end = (ub == len) ? (addr + tb - 1) : (u_al + (1 << size) - 1);
                            if (A >= u_start && A <= u_end) begin
                                if (!(ub == 1 && len > 1)) is_valid = 1; // Align wstrb clearing for E3 test
                            end
                            u_cur = next_addr(u_cur, size);
                        end
                        if (is_valid) d_strb[i] = 1'b1;
                    end
                    exp.expected_strobes[db] = d_strb;
                    d_addr = d_al + 2;
                end
                exp_m_aw.push_back(exp);
            end else begin
                exp_m_ar.push_back(exp);
            end
        end
    endtask

    task automatic do_upstream_read_start(logic [ID_W-1:0] id, logic [ADDR_W-1:0] addr, logic [7:0] len, logic [2:0] size, logic [1:0] burst);
        expect_downstream(id, addr, len, size, burst, 0);
        @(negedge clk_i);
        s_arid = id; s_araddr = addr; s_arlen = len; s_arsize = size; s_arburst = burst;
        s_arvalid = 1;
    endtask

    task automatic wait_ar_accept();
        forever begin @(posedge clk_i); if (s_arready) break; end
        @(negedge clk_i); s_arvalid = 0;
    endtask

    task automatic do_upstream_read(logic [ID_W-1:0] id, logic [ADDR_W-1:0] addr, logic [7:0] len, logic [2:0] size, logic [1:0] burst);
        do_upstream_read_start(id, addr, len, size, burst);
        wait_ar_accept();
    endtask

    task automatic do_upstream_write(logic [ID_W-1:0] id, logic [ADDR_W-1:0] addr, logic [7:0] len, logic [2:0] size, logic [1:0] burst);
        expect_downstream(id, addr, len, size, burst, 1);
        
        @(negedge clk_i);
        s_awid = id; s_awaddr = addr; s_awlen = len; s_awsize = size; s_awburst = burst;
        s_awvalid = 1;
        forever begin @(posedge clk_i); if (s_awready) break; end
        @(negedge clk_i); s_awvalid = 0;
        
        begin
            automatic logic [31:0] cur_addr = addr;
            for (int b = 0; b <= len; b++) begin
                automatic logic [SLV_DATA_W-1:0] wdata = 0;
                automatic logic [SLV_DATA_W/8-1:0] wstrb = 0;
                
                automatic logic [31:0] al_addr = aligned(cur_addr, size);
                automatic int tb = total_bytes(addr, len, size);
                automatic logic [31:0] start_A = (b == 0) ? addr : al_addr;
                automatic logic [31:0] end_A = (b == len) ? (addr + tb - 1) : (al_addr + (1 << size) - 1);
                
                for (logic [31:0] A = start_A; A <= end_A; A++) begin
                    automatic int lane = A % 8;
                    wdata[lane*8 +: 8] = A[7:0];
                    wstrb[lane] = 1'b1;
                end
                
                if (b == 1 && len > 1) wstrb = 0; // E3 test case
                
                @(negedge clk_i);
                s_wdata = wdata; s_wstrb = wstrb; s_wlast = (b == len); s_wvalid = 1;
                forever begin @(posedge clk_i); if (s_wready) break; end
                
                cur_addr = next_addr(cur_addr, size);
            end
        end
        @(negedge clk_i); s_wvalid = 0;
    endtask

    task automatic send_b_resp(logic [ID_W-1:0] id, logic [1:0] resp);
        automatic b_resp_t r;
        r.id = id; r.resp = resp;
        b_resp_q.push_back(r);
    endtask

    // ---------------------------------------------------------------------------
    // DOWNSTREAM RESPONDERS
    // ---------------------------------------------------------------------------
    initial begin
        m_bvalid = 0;
        forever begin
            @(posedge clk_i);
            if (rst_ni && b_resp_q.size() > 0) begin
                automatic b_resp_t r = b_resp_q.pop_front();
                @(negedge clk_i);
                m_bvalid = 1; m_bid = r.id; m_bresp = r.resp;
                forever begin @(posedge clk_i); if (m_bready) break; end
                @(negedge clk_i); m_bvalid = 0;
            end
        end
    end

    initial begin
        m_rvalid = 0;
        forever begin
            @(posedge clk_i);
            if (rst_ni && pending_m_ar.size() > 0) begin
                automatic m_ar_t req = pending_m_ar.pop_front();
                automatic logic [31:0] cur_addr = req.addr;
                for (int i = 0; i <= req.len; i++) begin
                    automatic logic [15:0] rdata;
                    automatic logic [31:0] al_addr = aligned(cur_addr, req.size);
                    automatic logic [1:0] rresp = 2'b00;

                    rdata[7:0]   = ~(al_addr[7:0]);
                    rdata[15:8]  = ~((al_addr + 1) & 32'hFF);
                    
                    if ((al_addr & ~1) == 32'h3000) rresp = 2'b10;
                    else if ((al_addr & ~1) == 32'h4000) rresp = 2'b11;
                    
                    @(negedge clk_i);
                    m_rvalid = 1; m_rid = req.id; m_rdata = rdata; m_rresp = rresp; m_rlast = (i == req.len);
                    forever begin @(posedge clk_i); if (m_rready) break; end
                    cur_addr = next_addr(cur_addr, req.size);
                end
                @(negedge clk_i); m_rvalid = 0;
            end
        end
    end

    // ---------------------------------------------------------------------------
    // MONITORS & CHECKERS
    // ---------------------------------------------------------------------------
    always @(posedge clk_i) begin
        if (rst_ni && s_arvalid && s_arready) begin
            automatic s_ar_t req;
            req.id = s_arid; req.addr = s_araddr; req.len = s_arlen; req.size = s_arsize; req.burst = s_arburst;
            req.is_refused = (req.burst == 2'b10) || (req.burst == 2'b00 && req.len != 0);
            req.beat_count = 0;
            req.expected_resp = 2'b00;
            pending_s_ar.push_back(req);
        end
    end

    always @(posedge clk_i) begin
        if (rst_ni && s_rvalid && s_rready) begin
            automatic int idx = -1;
            for (int i=0; i<pending_s_ar.size(); i++) begin
                if (pending_s_ar[i].id == s_rid) begin
                    idx = i; break;
                end
            end
            if (idx == -1) fail("D3: Upstream R carries unknown ID");
            
            begin
                automatic s_ar_t req = pending_s_ar[idx];
                automatic logic [31:0] cur_addr = req.addr;
                for (int b=0; b<req.beat_count; b++) cur_addr = next_addr(cur_addr, req.size);
                
                automatic int tb = total_bytes(req.addr, req.len, req.size);
                automatic logic [31:0] al_addr = aligned(cur_addr, req.size);
                automatic logic [31:0] start_A = (req.beat_count == 0) ? req.addr : al_addr;
                automatic logic [31:0] end_A = (req.beat_count == req.len) ? (req.addr + tb - 1) : (al_addr + (1 << req.size) - 1);
                
                if (req.is_refused) begin
                    if (s_rresp !== 2'b10) fail("C4: Refused read must return SLVERR");
                end else begin
                    for (logic [31:0] A = start_A; A <= end_A; A++) begin
                        automatic int lane = A % 8;
                        automatic logic [7:0] expected_byte = ~(A[7:0]);
                        if (s_rdata[lane*8 +: 8] !== expected_byte) fail("D1/D2: Upstream R data mismatch in valid byte lane");
                        if ((A & ~1) == 32'h3000) req.expected_resp = 2'b10;
                        else if ((A & ~1) == 32'h4000) req.expected_resp = 2'b11;
                    end
                    if (s_rresp !== req.expected_resp) fail("D6/D7/D5: Upstream R error response mismatch");
                end
                
                if (s_rlast !== (req.beat_count == req.len)) fail("D4: s_rlast incorrect");
                
                req.beat_count++;
                if (s_rlast) pending_s_ar.delete(idx);
                else pending_s_ar[idx] = req;
            end
        end
    end

    always @(posedge clk_i) begin
        if (rst_ni && m_arvalid && m_arready) begin
            automatic int found = -1;
            if (exp_m_ar.size() == 0) fail("A2/C4: Unexpected downstream AR");
            for (int i=0; i<exp_m_ar.size(); i++) begin
                if (exp_m_ar[i].id == m_arid) begin found = i; break; end
            end
            if (found == -1) fail("A2: Downstream AR ID unexpected");
            
            begin
                automatic req_t exp = exp_m_ar[found];
                exp_m_ar.delete(found);
                
                if (m_araddr !== exp.addr || m_arlen !== exp.len || m_arsize !== exp.size) fail("A2/B1/B2/B3: Downstream AR attributes mismatch");
                if (exp.len != 0 && m_arburst !== 2'b01) fail("B4: Downstream AR burst must be INCR");
                
                begin
                    automatic m_ar_t req;
                    req.id = m_arid; req.addr = m_araddr; req.len = m_arlen; req.size = m_arsize;
                    pending_m_ar.push_back(req);
                end
            end
        end
    end

    always @(posedge clk_i) begin
        if (rst_ni && s_awvalid && s_awready) begin
            automatic s_aw_t req;
            req.id = s_awid; req.addr = s_awaddr; req.len = s_awlen; req.size = s_awsize; req.burst = s_awburst;
            req.is_refused = (req.burst == 2'b10) || (req.burst == 2'b00 && req.len != 0);
            pending_s_aw.push_back(req);
        end
    end

    always @(posedge clk_i) begin
        if (rst_ni && m_awvalid && m_awready) begin
            automatic int found = -1;
            if (exp_m_aw.size() == 0) fail("A2/C4: Unexpected downstream AW");
            for (int i=0; i<exp_m_aw.size(); i++) begin
                if (exp_m_aw[i].id == m_awid) begin found = i; break; end
            end
            if (found == -1) fail("A2: Downstream AW ID unexpected");
            
            begin
                automatic req_t exp = exp_m_aw[found];
                exp_m_aw.delete(found);
                
                if (m_awaddr !== exp.addr || m_awlen !== exp.len || m_awsize !== exp.size) fail("A2/B1/B2/B3: Downstream AW attributes mismatch");
                if (exp.len != 0 && m_awburst !== 2'b01) fail("B4: Downstream AW burst must be INCR");
                
                begin
                    automatic m_aw_t req;
                    req.id = m_awid; req.addr = m_awaddr; req.len = m_awlen; req.size = m_awsize;
                    req.beat_count = 0;
                    for (int db=0; db<=req.len; db++) req.expected_strobes[db] = exp.expected_strobes[db];
                    pending_m_aw.push_back(req);
                end
            end
        end
    end

    always @(posedge clk_i) begin
        if (rst_ni && m_wvalid && m_wready) begin
            if (pending_m_aw.size() == 0) fail("Unexpected downstream W");
            begin
                automatic m_aw_t req = pending_m_aw[0];
                automatic logic [31:0] cur_addr = req.addr;
                for (int b=0; b<req.beat_count; b++) cur_addr = next_addr(cur_addr, req.size);
                
                begin
                    automatic logic [31:0] al_addr = aligned(cur_addr, req.size);
                    automatic logic [7:0] exp_byte0 = al_addr[7:0];
                    automatic logic [7:0] exp_byte1 = (al_addr + 1) & 8'hFF;
                    automatic logic [1:0] exp_strb = req.expected_strobes[req.beat_count];
                    
                    if (m_wlast !== (req.beat_count == req.len)) fail("E4: m_wlast incorrect");
                    if (m_wstrb !== exp_strb) fail("E2/E3: Downstream strb mismatch");
                    if (m_wstrb[0] && m_wdata[7:0] !== exp_byte0) fail("E1: Write data mismatch");
                    if (m_wstrb[1] && m_wdata[15:8] !== exp_byte1) fail("E1: Write data mismatch");
                    
                    req.beat_count++;
                    if (m_wlast) begin
                        automatic logic [1:0] bresp = 2'b00;
                        if ((al_addr & ~1) == 32'h5000) bresp = 2'b10;
                        if ((al_addr & ~1) == 32'h6000) bresp = 2'b11;
                        send_b_resp(req.id, bresp);
                        pending_m_aw.pop_front();
                    end else begin
                        pending_m_aw[0] = req;
                    end
                end
            end
        end
    end

    always @(posedge clk_i) begin
        if (rst_ni && s_bvalid && s_bready) begin
            automatic int idx = -1;
            if (pending_s_aw.size() == 0) fail("E5: Unexpected upstream B");
            for (int i=0; i<pending_s_aw.size(); i++) begin
                if (pending_s_aw[i].id == s_bid) begin idx = i; break; end
            end
            if (idx == -1) fail("E5: Upstream B carries unknown ID");
            
            begin
                automatic s_aw_t req = pending_s_aw[idx];
                if (req.is_refused) begin
                    if (s_bresp !== 2'b10) fail("C4: Refused write must return SLVERR");
                end else begin
                    automatic logic [1:0] exp_bresp = 2'b00;
                    automatic int tb = total_bytes(req.addr, req.len, req.size);
                    automatic logic [31:0] last_A = req.addr + tb - 1;
                    for (logic [31:0] A = req.addr; A <= last_A; A++) begin
                        if ((A & ~1) == 32'h5000) exp_bresp = 2'b10;
                        else if ((A & ~1) == 32'h6000) exp_bresp = 2'b11;
                    end
                    if (s_bresp !== exp_bresp) fail("E6: Upstream B error response mismatch");
                end
                pending_s_aw.delete(idx);
            end
        end
    end

    // ---------------------------------------------------------------------------
    // TEST SEQUENCE
    // ---------------------------------------------------------------------------
    initial begin
        m_arready = 1; m_awready = 1; m_wready = 1; s_rready = 1; s_bready = 1;
        s_awid = 0; s_awaddr = 0; s_awlen = 0; s_awsize = 0; s_awburst = 0; s_awvalid = 0;
        s_wdata = 0; s_wstrb = 0; s_wlast = 0; s_wvalid = 0;
        s_arid = 0; s_araddr = 0; s_arlen = 0; s_arsize = 0; s_arburst = 0; s_arvalid = 0;

        bfm_reset();
        if (m_awvalid || m_wvalid || m_arvalid || s_rvalid || s_bvalid) fail("F2: Valid active immediately after reset");

        do_upstream_read(4'd1, 32'h1000, 0, 3, 2'b01);
        do_upstream_read(4'd2, 32'h1004, 1, 3, 2'b01);
        do_upstream_read(4'd3, 32'h1001, 0, 1, 2'b01);

        do_upstream_read(4'd4, 32'h2000, 3, 3, 2'b10); 
        do_upstream_read(4'd5, 32'h2000, 1, 3, 2'b00); 
        do_upstream_read(4'd6, 32'h2000, 0, 3, 2'b00); 

        do_upstream_write(4'd7, 32'h3000, 0, 3, 2'b01);
        do_upstream_write(4'd8, 32'h3004, 1, 3, 2'b01);
        do_upstream_write(4'd9, 32'h4000, 3, 3, 2'b10); 

        do_upstream_read(4'd10, 32'h3000, 1, 3, 2'b01);
        do_upstream_read(4'd11, 32'h4000, 1, 3, 2'b01);

        do_upstream_write(4'd12, 32'h5000, 1, 3, 2'b01);
        do_upstream_write(4'd13, 32'h6000, 1, 3, 2'b01);
        
        repeat(100) @(posedge clk_i);
        
        @(negedge clk_i); m_arready = 0;
        
        do_upstream_read_start(4'd1, 32'h7000, 0, 3, 2'b01); wait_ar_accept();
        do_upstream_read_start(4'd2, 32'h7008, 0, 3, 2'b01); wait_ar_accept();
        do_upstream_read_start(4'd3, 32'h7010, 0, 3, 2'b01); wait_ar_accept();
        do_upstream_read_start(4'd4, 32'h7018, 0, 3, 2'b01); wait_ar_accept();
        
        do_upstream_read_start(4'd5, 32'h7020, 0, 3, 2'b01);
        
        repeat(10) @(posedge clk_i);
        if (s_arready) fail("A4: 5th read accepted while 4 outstanding");
        
        @(negedge clk_i); m_arready = 1;
        wait_ar_accept();
        repeat(100) @(posedge clk_i);
        
        do_upstream_read_start(4'd6, 32'h8000, 0, 3, 2'b01);
        wait_ar_accept();
        bfm_reset();
        
        repeat(20) @(posedge clk_i);
        if (m_arvalid || m_awvalid || m_wvalid || s_rvalid || s_bvalid) fail("F3: Transaction survived reset");
        
        $display("RESULT: PASS");
        $finish;
    end

endmodule