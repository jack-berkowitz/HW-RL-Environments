module id_width_conv_tb;

// ---- parameters -----------------------------------------------------------
localparam int unsigned SLV_ID_W        = 4;
localparam int unsigned MST_ID_W        = 2;
localparam int unsigned ADDR_W          = 32;
localparam int unsigned DATA_W          = 32;
localparam int unsigned MAX_UNIQ_IDS    = 4;
localparam int unsigned MAX_TXNS_PER_ID = 2;

// ---- signals --------------------------------------------------------------
logic                    clk_i;
logic                    rst_ni;

// ---- slave (upstream) port ----
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

// ---- master (downstream) port ----
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

// ---- DUT instantiation ----------------------------------------------------
id_width_conv #(
    .SLV_ID_W(SLV_ID_W),
    .MST_ID_W(MST_ID_W),
    .ADDR_W(ADDR_W),
    .DATA_W(DATA_W),
    .MAX_UNIQ_IDS(MAX_UNIQ_IDS),
    .MAX_TXNS_PER_ID(MAX_TXNS_PER_ID)
) dut (
    .clk_i(clk_i),
    .rst_ni(rst_ni),
    .s_awid(s_awid), .s_awaddr(s_awaddr), .s_awlen(s_awlen), .s_awvalid(s_awvalid), .s_awready(s_awready),
    .s_wdata(s_wdata), .s_wstrb(s_wstrb), .s_wlast(s_wlast), .s_wvalid(s_wvalid), .s_wready(s_wready),
    .s_bid(s_bid), .s_bresp(s_bresp), .s_bvalid(s_bvalid), .s_bready(s_bready),
    .s_arid(s_arid), .s_araddr(s_araddr), .s_arlen(s_arlen), .s_arvalid(s_arvalid), .s_arready(s_arready),
    .s_rid(s_rid), .s_rdata(s_rdata), .s_rresp(s_rresp), .s_rlast(s_rlast), .s_rvalid(s_rvalid), .s_rready(s_rready),
    .m_awid(m_awid), .m_awaddr(m_awaddr), .m_awlen(m_awlen), .m_awvalid(m_awvalid), .m_awready(m_awready),
    .m_wdata(m_wdata), .m_wstrb(m_wstrb), .m_wlast(m_wlast), .m_wvalid(m_wvalid), .m_wready(m_wready),
    .m_bid(m_bid), .m_bresp(m_bresp), .m_bvalid(m_bvalid), .m_bready(m_bready),
    .m_arid(m_arid), .m_araddr(m_araddr), .m_arlen(m_arlen), .m_arvalid(m_arvalid), .m_arready(m_arready),
    .m_rid(m_rid), .m_rdata(m_rdata), .m_rresp(m_rresp), .m_rlast(m_rlast), .m_rvalid(m_rvalid), .m_rready(m_rready)
);

// ---------------------------------------------------------------------------
// PROVIDED PLUMBING -- moves transactions, checks nothing.
// ---------------------------------------------------------------------------
logic clk;
initial begin clk = 1'b0; forever #5 clk = ~clk; end
assign clk_i = clk;

logic rst_n;
initial rst_n = 1'b0;
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
// TESTBENCH TYPES AND STATE
// ---------------------------------------------------------------------------
typedef struct {
    logic [3:0] slv_id;
    logic [31:0] addr;
    logic [7:0] len;
} txn_t;

typedef struct {
    logic [3:0] slv_id;
    logic [7:0] len;
} aw_txn_t;

typedef struct {
    logic [31:0] data;
    logic [3:0] strb;
    logic last;
} w_beat_t;

typedef struct {
    logic [31:0] data;
    logic [1:0] resp;
    logic last;
    logic [3:0] id;
} r_beat_t;

typedef struct {
    logic [1:0] mst_id;
    logic [3:0] slv_id;
    logic [31:0] addr;
    logic [7:0] len;
} m_ar_txn_t;

typedef struct {
    logic [1:0] mst_id;
    logic [3:0] slv_id;
    logic [31:0] addr;
    logic [7:0] len;
} m_aw_txn_t;

txn_t pending_ar[$];
txn_t pending_aw[$];

int rd_txns_per_slv_id[16];
int wr_txns_per_slv_id[16];

logic [3:0] mst2slv_rd[4];
logic mst2slv_rd_valid[4];
logic [1:0] slv2mst_rd[16];

logic [3:0] mst2slv_wr[4];
logic mst2slv_wr_valid[4];
logic [1:0] slv2mst_wr[16];

aw_txn_t expected_w_txns[$];
int current_w_beats_left;
logic [3:0] current_w_slv_id;

w_beat_t global_s_w_queue[$];
r_beat_t expected_s_r_queues[16][$];
logic [1:0] expected_s_b_queues[16][$];

m_ar_txn_t m_ar_queue[$];
m_aw_txn_t m_aw_queue[$];

int last_retire_time_rd;
int last_retire_time_wr;

always @(negedge rst_ni) begin
    pending_ar.delete();
    pending_aw.delete();
    m_ar_queue.delete();
    m_aw_queue.delete();
    expected_w_txns.delete();
    global_s_w_queue.delete();
    for (int i = 0; i < 16; i++) begin
        rd_txns_per_slv_id[i] = 0;
        wr_txns_per_slv_id[i] = 0;
        expected_s_r_queues[i].delete();
        expected_s_b_queues[i].delete();
    end
    for (int i = 0; i < 4; i++) begin
        mst2slv_rd_valid[i] = 1'b0;
        mst2slv_wr_valid[i] = 1'b0;
    end
    current_w_beats_left = 0;
    last_retire_time_rd = 0;
    last_retire_time_wr = 0;
end

// ---------------------------------------------------------------------------
// MONITORS AND CHECKERS
// ---------------------------------------------------------------------------
always @(posedge clk) begin
    // ---- READ CHANNEL (AR) CHECKERS ----
    if (s_arvalid && s_arready && rst_n) begin
        automatic txn_t t;
        t.slv_id = s_arid; 
        t.addr = s_araddr; 
        t.len = s_arlen;
        pending_ar.push_back(t);
        rd_txns_per_slv_id[s_arid]++;
    end

    if (m_arvalid && m_arready && rst_n) begin
        automatic int found_idx = -1;
        automatic txn_t t;
        automatic m_ar_txn_t m_ar;
        for (int i = 0; i < pending_ar.size(); i++) begin
            if (pending_ar[i].addr == m_araddr && pending_ar[i].len == m_arlen) begin
                found_idx = i;
                break;
            end
        end
        if (found_idx == -1) begin
            $display("RESULT: FAIL (D4/E1: m_ar unknown or corrupted payload)");
            $finish;
        end
        t = pending_ar[found_idx];
        pending_ar.delete(found_idx);

        if (mst2slv_rd_valid[m_arid]) begin
            if (mst2slv_rd[m_arid] != t.slv_id) begin
                $display("RESULT: FAIL (D1/D2: Master ARID %0d reused for SLV_ID %0d while active for SLV_ID %0d)", m_arid, t.slv_id, mst2slv_rd[m_arid]);
                $finish;
            end
        end else begin
            mst2slv_rd_valid[m_arid] = 1'b1;
            mst2slv_rd[m_arid] = t.slv_id;
            slv2mst_rd[t.slv_id] = m_arid;
        end

        m_ar.mst_id = m_arid;
        m_ar.slv_id = t.slv_id;
        m_ar.addr   = m_araddr;
        m_ar.len    = m_arlen;
        m_ar_queue.push_back(m_ar);
    end

    // ---- READ RESPONSE (R) CHECKERS ----
    if (s_rvalid && s_rready && rst_n) begin
        automatic r_beat_t b;
        if (rd_txns_per_slv_id[s_rid] == 0) begin
            $display("RESULT: FAIL (C2: s_r for non-outstanding ID %0d)", s_rid);
            $finish;
        end
        if (expected_s_r_queues[s_rid].size() == 0) begin
            $display("RESULT: FAIL (C1: unexpected s_r or wrong ID restoration)");
            $finish;
        end
        b = expected_s_r_queues[s_rid].pop_front();
        if (s_rdata !== b.data || s_rresp !== b.resp || s_rlast !== b.last) begin
            $display("RESULT: FAIL (E1: s_r payload mismatch)");
            $finish;
        end
        if (s_rlast) begin
            rd_txns_per_slv_id[s_rid]--;
            if (rd_txns_per_slv_id[s_rid] == 0) begin
                mst2slv_rd_valid[ slv2mst_rd[s_rid] ] = 1'b0;
                last_retire_time_rd = $time;
            end
        end
    end

    // ---- WRITE CHANNEL (AW) CHECKERS ----
    if (s_awvalid && s_awready && rst_n) begin
        automatic txn_t t;
        automatic aw_txn_t tw;
        t.slv_id = s_awid; 
        t.addr = s_awaddr; 
        t.len = s_awlen;
        pending_aw.push_back(t);
        wr_txns_per_slv_id[s_awid]++;

        tw.slv_id = s_awid; 
        tw.len = s_awlen;
        expected_w_txns.push_back(tw);
    end

    if (m_awvalid && m_awready && rst_n) begin
        automatic int found_idx = -1;
        automatic txn_t t;
        automatic m_aw_txn_t m_aw;
        for (int i = 0; i < pending_aw.size(); i++) begin
            if (pending_aw[i].addr == m_awaddr && pending_aw[i].len == m_awlen) begin
                found_idx = i;
                break;
            end
        end
        if (found_idx == -1) begin
            $display("RESULT: FAIL (D4/E1: m_aw unknown or corrupted payload)");
            $finish;
        end
        t = pending_aw[found_idx];
        pending_aw.delete(found_idx);

        if (mst2slv_wr_valid[m_awid]) begin
            if (mst2slv_wr[m_awid] != t.slv_id) begin
                $display("RESULT: FAIL (D1/D2: Master AWID %0d reused improperly)", m_awid);
                $finish;
            end
        end else begin
            mst2slv_wr_valid[m_awid] = 1'b1;
            mst2slv_wr[m_awid] = t.slv_id;
            slv2mst_wr[t.slv_id] = m_awid;
        end

        m_aw.mst_id = m_awid;
        m_aw.slv_id = t.slv_id;
        m_aw.addr   = m_awaddr;
        m_aw.len    = m_awlen;
        m_aw_queue.push_back(m_aw);
    end

    // ---- WRITE DATA (W) CHECKERS ----
    if (s_wvalid && s_wready && rst_n) begin
        automatic w_beat_t b;
        b.data = s_wdata; 
        b.strb = s_wstrb; 
        b.last = s_wlast;
        global_s_w_queue.push_back(b);
    end

    if (m_wvalid && m_wready && rst_n) begin
        automatic w_beat_t b;
        if (current_w_beats_left == 0) begin
            automatic aw_txn_t tw;
            if (expected_w_txns.size() == 0) begin
                $display("RESULT: FAIL (B3/D4: m_w without valid preceding s_aw)");
                $finish;
            end
            tw = expected_w_txns.pop_front();
            current_w_beats_left = tw.len + 1;
            current_w_slv_id = tw.slv_id;
        end

        if (global_s_w_queue.size() == 0) begin
            $display("RESULT: FAIL (B3/E1: m_w but no upstream s_w data registered)");
            $finish;
        end
        b = global_s_w_queue.pop_front();
        if (m_wdata !== b.data || m_wstrb !== b.strb || m_wlast !== b.last) begin
            $display("RESULT: FAIL (E1: m_w payload mismatch)");
            $finish;
        end

        current_w_beats_left--;
        if (m_wlast && current_w_beats_left != 0) begin
            $display("RESULT: FAIL (E1: m_wlast asserted prematurely)");
            $finish;
        end
        if (!m_wlast && current_w_beats_left == 0) begin
            $display("RESULT: FAIL (E1: m_wlast missing at burst end)");
            $finish;
        end
    end

    // ---- WRITE RESPONSE (B) CHECKERS ----
    if (s_bvalid && s_bready && rst_n) begin
        automatic logic [1:0] resp;
        if (wr_txns_per_slv_id[s_bid] == 0) begin
            $display("RESULT: FAIL (C2: s_b for non-outstanding ID %0d)", s_bid);
            $finish;
        end
        if (expected_s_b_queues[s_bid].size() == 0) begin
            $display("RESULT: FAIL (C1: unexpected s_b or wrong ID restoration)");
            $finish;
        end
        resp = expected_s_b_queues[s_bid].pop_front();
        if (s_bresp !== resp) begin
            $display("RESULT: FAIL (E1: s_b payload mismatch)");
            $finish;
        end
        wr_txns_per_slv_id[s_bid]--;
        if (wr_txns_per_slv_id[s_bid] == 0) begin
            mst2slv_wr_valid[ slv2mst_wr[s_bid] ] = 1'b0;
            last_retire_time_wr = $time;
        end
    end
end

// ---------------------------------------------------------------------------
// WRAPPERS FOR BFM RESPONSE TASKS
// ---------------------------------------------------------------------------
task automatic send_rbeat(input logic [MST_ID_W-1:0] mid,
                          input logic [DATA_W-1:0]   data,
                          input logic                last);
    automatic r_beat_t b;
    // Push verification state BEFORE applying the bfm pulse since bfm 
    // runs combinationally leading up to the posedge clock match.
    b.data = data; 
    b.resp = 2'b00; 
    b.last = last; 
    b.id = mst2slv_rd[mid];
    expected_s_r_queues[b.id].push_back(b);
    
    bfm_rbeat(mid, data, last);
endtask

task automatic send_bbeat(input logic [MST_ID_W-1:0] mid);
    expected_s_b_queues[ mst2slv_wr[mid] ].push_back(2'b00);
    bfm_bbeat(mid);
endtask

// ---------------------------------------------------------------------------
// MAIN STIMULUS
// ---------------------------------------------------------------------------
initial begin
    automatic bit acc;
    automatic int waited;

    s_awid = 0; s_awaddr = 0; s_awlen = 0; s_awvalid = 0;
    s_wdata = 0; s_wstrb = 0; s_wlast = 0; s_wvalid = 0;
    s_arid = 0; s_araddr = 0; s_arlen = 0; s_arvalid = 0;
    m_arready = 0; m_awready = 0; m_wready = 0;
    m_rid = 0; m_rdata = 0; m_rresp = 0; m_rlast = 0; m_rvalid = 0;
    m_bid = 0; m_bresp = 0; m_bvalid = 0;
    s_rready = 1; s_bready = 1;

    // Trigger reset sequence
    bfm_reset();

    // =========================================================================
    // READ PATH VERIFICATION (A2, A3, A4, A5, B1)
    // =========================================================================
    
    // A2: Test the bounded limits. Can we handle exactly MAX_UNIQ_IDS?
    for (int i = 1; i <= MAX_UNIQ_IDS; i++) begin
        bfm_ar(i, i * 4096, 0, 10, acc, waited);
        if (!acc) begin 
            $display("RESULT: FAIL (A2: Rejected transaction below MAX_UNIQ_IDS limit)"); 
            $finish; 
        end
    end

    // A3: Exceed the boundary limitation. New ID must be rejected.
    bfm_ar(5, 5 * 4096, 0, 10, acc, waited);
    if (acc) begin 
        $display("RESULT: FAIL (A3: Accepted a new ID request over MAX_UNIQ_IDS bound)"); 
        $finish; 
    end

    // A5: Request limits depth per identifier. Verify it allows MAX_TXNS_PER_ID limits
    bfm_ar(1, 10 * 4096, 0, 10, acc, waited);
    if (!acc) begin 
        $display("RESULT: FAIL (A5: Failed to accept secondary transaction for an active ID)"); 
        $finish; 
    end

    // A5: Verify strict bounding depth enforcement at MAX_TXNS_PER_ID + 1.
    bfm_ar(1, 11 * 4096, 0, 10, acc, waited);
    if (acc) begin 
        $display("RESULT: FAIL (A5: Permitted transaction beyond MAX_TXNS_PER_ID)"); 
        $finish; 
    end

    // Cycle through accepted ARs to transfer them across the downstream bridge.
    for (int i = 0; i < 5; i++) begin
        while (!m_arvalid) @(posedge clk);
        @(negedge clk); m_arready = 1;
        @(posedge clk); @(negedge clk); m_arready = 0;
    end

    // A4: Timely Retirement Clearance
    begin
        automatic bit acc_id5 = 0;
        automatic int waited_id5 = 0;
        automatic int idx = -1;
        automatic m_ar_txn_t t2;
        
        fork
            // Hold a background test to detect the release margin
            begin
                bfm_ar(5, 5 * 4096, 0, 100, acc_id5, waited_id5);
            end
        join_none

        // Guarantee background task initialization
        repeat (5) @(posedge clk);

        // Fetch ID 2's request representation on the master 
        for (int i = 0; i < m_ar_queue.size(); i++) begin
            if (m_ar_queue[i].slv_id == 2) begin idx = i; break; end
        end
        if (idx == -1) begin 
            $display("RESULT: FAIL (D4: Tracked ID 2 missing from upstream queue map)"); 
            $finish; 
        end
        
        t2 = m_ar_queue[idx];
        m_ar_queue.delete(idx);
        
        // Complete the ID 2 transaction, releasing its slot
        send_rbeat(t2.mst_id, 32'h22222222, 1'b1);
        
        // Evaluate the wait gap constraint directly.
        wait(acc_id5);
        begin
            automatic int cycles_after = ($time - last_retire_time_rd) / 10;
            if (cycles_after > 2 || cycles_after < 0) begin
                $display("RESULT: FAIL (A4: Blocked request not accepted within 2 cycles, took %0d)", cycles_after);
                $finish;
            end
        end
    end

    // Absorb the newly accepted AR
    while (!m_arvalid) @(posedge clk);
    @(negedge clk); m_arready = 1;
    @(posedge clk); @(negedge clk); m_arready = 0;

    // Purge the remaining read transactions cleanly
    while (m_ar_queue.size() > 0) begin
        automatic m_ar_txn_t t = m_ar_queue.pop_front();
        for (int i = 0; i <= t.len; i++) begin
            send_rbeat(t.mst_id, 32'h12345678 + i, (i == t.len));
        end
    end
    
    repeat (10) @(posedge clk);

    // =========================================================================
    // WRITE PATH VERIFICATION (A2, A3, A4, B3)
    // =========================================================================

    // Fill table capacity mapping to limits
    for (int i = 1; i <= MAX_UNIQ_IDS; i++) begin
        bfm_aw(i, i * 4096, 1, 10, acc, waited);
        if (!acc) begin 
            $display("RESULT: FAIL (A2: Rejecting valid AW transactions below MAX_UNIQ_IDS limit)"); 
            $finish; 
        end
    end

    // Bound test constraint limit
    bfm_aw(5, 5 * 4096, 1, 10, acc, waited);
    if (acc) begin 
        $display("RESULT: FAIL (A3: Accepting unauthorized AW transaction over MAX_UNIQ_IDS boundary)"); 
        $finish; 
    end

    // Execute the globally synced stream of Write (W) data blocks to evaluate B3
    for (int i = 1; i <= 4; i++) begin
        bfm_w(32'hA0A0A0A0 + i, 4'hF, 0);
        bfm_w(32'hB0B0B0B0 + i, 4'hF, 1);
    end

    // Bridge upstream accepted transactions out downstream
    for (int i = 0; i < 4; i++) begin
        while (!m_awvalid) @(posedge clk);
        @(negedge clk); m_awready = 1;
        @(posedge clk); @(negedge clk); m_awready = 0;
    end

    for (int i = 0; i < 8; i++) begin
        while (!m_wvalid) @(posedge clk);
        @(negedge clk); m_wready = 1;
        @(posedge clk); @(negedge clk); m_wready = 0;
    end

    // A4: Timely Retirement Clearance For Write Phase
    begin
        automatic bit acc_id5 = 0;
        automatic int waited_id5 = 0;
        automatic int idx = -1;
        automatic m_aw_txn_t t1;
        
        fork
            begin
                bfm_aw(5, 5 * 4096, 0, 100, acc_id5, waited_id5);
            end
        join_none

        repeat (5) @(posedge clk);

        for (int i = 0; i < m_aw_queue.size(); i++) begin
            if (m_aw_queue[i].slv_id == 1) begin idx = i; break; end
        end
        if (idx == -1) begin 
            $display("RESULT: FAIL (D4: Missing tracking footprint for AW ID 1)"); 
            $finish; 
        end
        
        t1 = m_aw_queue[idx];
        m_aw_queue.delete(idx);
        
        // Finalize the tracked sequence logic, asserting its retirement scope
        send_bbeat(t1.mst_id);
        
        wait(acc_id5);
        begin
            automatic int cycles_after = ($time - last_retire_time_wr) / 10;
            if (cycles_after > 2 || cycles_after < 0) begin
                $display("RESULT: FAIL (A4: Blocked AW request failed acceptance compliance window)");
                $finish;
            end
        end
    end

    // Flush ID 5 output mapping 
    while (!m_awvalid) @(posedge clk);
    @(negedge clk); m_awready = 1;
    @(posedge clk); @(negedge clk); m_awready = 0;

    bfm_w(32'hC0C0C0C0, 4'hF, 1);
    while (!m_wvalid) @(posedge clk);
    @(negedge clk); m_wready = 1;
    @(posedge clk); @(negedge clk); m_wready = 0;

    // Empty sequence records
    while (m_aw_queue.size() > 0) begin
        automatic m_aw_txn_t t = m_aw_queue.pop_front();
        send_bbeat(t.mst_id);
    end

    repeat (10) @(posedge clk);

    // =========================================================================
    // RESET DISCARD VERIFICATION (F1)
    // =========================================================================
    
    // Inject a pending tracking action
    bfm_ar(6, 6000, 0, 10, acc, waited);
    while (!m_arvalid) @(posedge clk);
    
    @(negedge clk);
    rst_n = 0;
    @(posedge clk);
    
    // Assess active-low synchronous bounds checking
    if (m_arvalid || m_awvalid || m_wvalid || s_rvalid || s_bvalid) begin
        $display("RESULT: FAIL (F1: Output states failed to maintain valid-low silence bounds during reset phase)");
        $finish;
    end
    
    @(negedge clk);
    rst_n = 1;
    
    $display("RESULT: PASS");
    $finish;
end

endmodule