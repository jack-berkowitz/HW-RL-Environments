// id_width_conv_tb.sv
// Self-checking testbench for id_width_conv
// Verilator 5.x compatible

module id_width_conv_tb;

    // Parameters
    localparam int unsigned SLV_ID_W = 4;
    localparam int unsigned MST_ID_W = 2;
    localparam int unsigned ADDR_W = 32;
    localparam int unsigned DATA_W = 32;
    localparam int unsigned MAX_UNIQ_IDS = 4;
    localparam int unsigned MAX_TXNS_PER_ID = 2;

    // Signals
    logic clk;
    logic rst_n;

    // Slave port
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

    // Master port
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

    // DUT instance
    id_width_conv #(
        .SLV_ID_W(SLV_ID_W),
        .MST_ID_W(MST_ID_W),
        .ADDR_W(ADDR_W),
        .DATA_W(DATA_W),
        .MAX_UNIQ_IDS(MAX_UNIQ_IDS),
        .MAX_TXNS_PER_ID(MAX_TXNS_PER_ID)
    ) dut (
        .clk_i(clk),
        .rst_ni(rst_n),
        .s_awid(s_awid),
        .s_awaddr(s_awaddr),
        .s_awlen(s_awlen),
        .s_awvalid(s_awvalid),
        .s_awready(s_awready),
        .s_wdata(s_wdata),
        .s_wstrb(s_wstrb),
        .s_wlast(s_wlast),
        .s_wvalid(s_wvalid),
        .s_wready(s_wready),
        .s_bid(s_bid),
        .s_bresp(s_bresp),
        .s_bvalid(s_bvalid),
        .s_bready(s_bready),
        .s_arid(s_arid),
        .s_araddr(s_araddr),
        .s_arlen(s_arlen),
        .s_arvalid(s_arvalid),
        .s_arready(s_arready),
        .s_rid(s_rid),
        .s_rdata(s_rdata),
        .s_rresp(s_rresp),
        .s_rlast(s_rlast),
        .s_rvalid(s_rvalid),
        .s_rready(s_rready),
        .m_awid(m_awid),
        .m_awaddr(m_awaddr),
        .m_awlen(m_awlen),
        .m_awvalid(m_awvalid),
        .m_awready(m_awready),
        .m_wdata(m_wdata),
        .m_wstrb(m_wstrb),
        .m_wlast(m_wlast),
        .m_wvalid(m_wvalid),
        .m_wready(m_wready),
        .m_bid(m_bid),
        .m_bresp(m_bresp),
        .m_bvalid(m_bvalid),
        .m_bready(m_bready),
        .m_arid(m_arid),
        .m_araddr(m_araddr),
        .m_arlen(m_arlen),
        .m_arvalid(m_arvalid),
        .m_arready(m_arready),
        .m_rid(m_rid),
        .m_rdata(m_rdata),
        .m_rresp(m_rresp),
        .m_rlast(m_rlast),
        .m_rvalid(m_rvalid),
        .m_rready(m_rready)
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

    initial begin
        #4_000_000;
        $display("RESULT: FAIL (watchdog: no forward progress)");
        $finish;
    end

    // ---------------------------------------------------------------------------
    // TESTBENCH MODEL AND CHECKERS
    // ---------------------------------------------------------------------------

    typedef struct {
        int unsigned txn_id;
        logic [SLV_ID_W-1:0] slave_id;
        logic [ADDR_W-1:0] addr;
        logic [7:0] len;
        logic is_write;
        logic [DATA_W-1:0] wdata[256];
        logic [DATA_W/8-1:0] wstrb[256];
        logic wlast[256];
        logic [DATA_W-1:0] rdata[256];
        logic [1:0] rresp[256];
        logic rlast[256];
        int num_beats;
        int unsigned master_id;
        bit address_sent;
        int beats_sent;
        int beats_received;
        bit completed;
    } txn_t;

    txn_t txns[int unsigned];
    int unsigned next_txn_id = 0;
    int fail_count = 0;

    // Read side
    int unsigned rd_outstanding_count[logic [SLV_ID_W-1:0]];
    int unsigned rd_distinct_count = 0;
    int unsigned rd_queue[logic [SLV_ID_W-1:0]][$];
    logic [SLV_ID_W-1:0] rd_mid_to_sid[logic [MST_ID_W-1:0]];
    logic [MST_ID_W-1:0] rd_sid_to_mid[logic [SLV_ID_W-1:0]];
    bit rd_mid_valid[logic [MST_ID_W-1:0]];

    // Write side
    int unsigned wr_outstanding_count[logic [SLV_ID_W-1:0]];
    int unsigned wr_distinct_count = 0;
    int unsigned wr_queue[logic [SLV_ID_W-1:0]][$];
    logic [SLV_ID_W-1:0] wr_mid_to_sid[logic [MST_ID_W-1:0]];
    logic [MST_ID_W-1:0] wr_sid_to_mid[logic [SLV_ID_W-1:0]];
    bit wr_mid_valid[logic [MST_ID_W-1:0]];

    // Master queues
    int unsigned master_wr_txn_queue[$];
    int unsigned master_read_queue[$];

    // Cycle counter
    int unsigned cycle_count = 0;
    always @(negedge clk) cycle_count <= cycle_count + 1;

    // Retirement tracking
    int unsigned last_retire_cycle = 0;
    logic [SLV_ID_W-1:0] last_retired_id;

    task automatic report_fail(input string req, input string msg);
        $display("FAIL: %s - %s", req, msg);
        fail_count++;
    endtask

    task automatic wait_address_sent(input int unsigned tid);
        int timeout = 0;
        while (!txns[tid].address_sent && timeout < 1000) begin
            @(posedge clk);
            timeout++;
        end
        if (timeout >= 1000) report_fail("D4", "Timeout waiting for master address");
    endtask

    task automatic send_read_response(input int unsigned tid);
        int timeout;
        wait_address_sent(tid);
        if (!txns[tid].address_sent) return;
        for (int i = 0; i < txns[tid].num_beats; i++) begin
            bfm_rbeat(txns[tid].master_id, txns[tid].rdata[i], txns[tid].rlast[i]);
        end
        timeout = 0;
        while (!txns[tid].completed && timeout < 1000) begin
            @(posedge clk);
            timeout++;
        end
        if (timeout >= 1000) report_fail("C2", "Timeout waiting for read response completion");
    endtask

    task automatic send_write_response(input int unsigned tid);
        int timeout;
        timeout = 0;
        while (txns[tid].beats_sent != txns[tid].num_beats && timeout < 1000) begin
            @(posedge clk);
            timeout++;
        end
        if (timeout >= 1000) begin
            report_fail("B3", "Timeout waiting for master write data");
            return;
        end
        bfm_bbeat(txns[tid].master_id);
        timeout = 0;
        while (!txns[tid].completed && timeout < 1000) begin
            @(posedge clk);
            timeout++;
        end
        if (timeout >= 1000) report_fail("C2", "Timeout waiting for write response completion");
    endtask

    task automatic send_write_data(input int unsigned tid);
        for (int i = 0; i < txns[tid].num_beats; i++) begin
            bfm_w(txns[tid].wdata[i], txns[tid].wstrb[i], txns[tid].wlast[i]);
        end
    endtask

    // ---------------------------------------------------------------------------
    // MONITORS
    // ---------------------------------------------------------------------------

    // Slave address handshakes
    always @(posedge clk) begin
        if (rst_n) begin
            if (s_arvalid && s_arready) begin
                if (rd_outstanding_count[s_arid] == 0 && rd_distinct_count == MAX_UNIQ_IDS) begin
                    report_fail("A3", $sformatf("Accepted new read ID %0d when table full", s_arid));
                end
                if (rd_outstanding_count[s_arid] == MAX_TXNS_PER_ID) begin
                    report_fail("A5", $sformatf("Accepted read ID %0d exceeding max txns per ID", s_arid));
                end
                int unsigned tid = s_araddr;
                if (txns.exists(tid)) report_fail("D4", "Duplicate transaction ID");
                txn_t t;
                t.txn_id = tid;
                t.slave_id = s_arid;
                t.addr = s_araddr;
                t.len = s_arlen;
                t.is_write = 0;
                t.num_beats = s_arlen + 1;
                for (int i = 0; i < t.num_beats; i++) begin
                    t.rdata[i] = {tid[15:0], i[15:0]};
                    t.rresp[i] = 2'b00;
                    t.rlast[i] = (i == t.num_beats - 1);
                end
                t.master_id = -1;
                t.address_sent = 0;
                t.beats_sent = 0;
                t.beats_received = 0;
                t.completed = 0;
                txns[tid] = t;
                if (rd_outstanding_count[s_arid] == 0) rd_distinct_count++;
                rd_outstanding_count[s_arid]++;
                rd_queue[s_arid].push_back(tid);
            end
            if (s_awvalid && s_awready) begin
                if (wr_outstanding_count[s_awid] == 0 && wr_distinct_count == MAX_UNIQ_IDS) begin
                    report_fail("A3", $sformatf("Accepted new write ID %0d when table full", s_awid));
                end
                if (wr_outstanding_count[s_awid] == MAX_TXNS_PER_ID) begin
                    report_fail("A5", $sformatf("Accepted write ID %0d exceeding max txns per ID", s_awid));
                end
                int unsigned tid = s_awaddr;
                if (txns.exists(tid)) report_fail("D4", "Duplicate transaction ID");
                txn_t t;
                t.txn_id = tid;
                t.slave_id = s_awid;
                t.addr = s_awaddr;
                t.len = s_awlen;
                t.is_write = 1;
                t.num_beats = s_awlen + 1;
                for (int i = 0; i < t.num_beats; i++) begin
                    t.wdata[i] = {tid[15:0], i[15:0]};
                    t.wstrb[i] = {DATA_W/8{1'b1}};
                    t.wlast[i] = (i == t.num_beats - 1);
                end
                t.master_id = -1;
                t.address_sent = 0;
                t.beats_sent = 0;
                t.beats_received = 0;
                t.completed = 0;
                txns[tid] = t;
                if (wr_outstanding_count[s_awid] == 0) wr_distinct_count++;
                wr_outstanding_count[s_awid]++;
                wr_queue[s_awid].push_back(tid);
                master_wr_txn_queue.push_back(tid);
            end
        end
    end

    // Master address handshakes
    always @(posedge clk) begin
        if (rst_n) begin
            if (m_arvalid && m_arready) begin
                int unsigned tid = m_araddr;
                if (!txns.exists(tid)) begin
                    report_fail("D4", "Master read address for unknown transaction");
                end else begin
                    txn_t t = txns[tid];
                    if (t.addr !== m_araddr) report_fail("E1", "Read addr mismatch");
                    if (t.len !== m_arlen) report_fail("E1", "Read len mismatch");
                    if (t.address_sent) report_fail("D4", "Duplicate master read address");
                    t.address_sent = 1;
                    if (rd_sid_to_mid.exists(t.slave_id)) begin
                        if (rd_sid_to_mid[t.slave_id] !== m_arid) report_fail("D1", "Master ID changed for same slave ID");
                    end else begin
                        if (rd_mid_valid[m_arid]) begin
                            logic [SLV_ID_W-1:0] other_sid = rd_mid_to_sid[m_arid];
                            if (rd_outstanding_count[other_sid] > 0) begin
                                report_fail("D1", "Master ID reused while other slave ID outstanding");
                            end
                        end
                        rd_sid_to_mid[t.slave_id] = m_arid;
                        rd_mid_to_sid[m_arid] = t.slave_id;
                        rd_mid_valid[m_arid] = 1;
                    end
                    t.master_id = m_arid;
                    txns[tid] = t;
                    master_read_queue.push_back(tid);
                end
            end
            if (m_awvalid && m_awready) begin
                int unsigned tid = m_awaddr;
                if (!txns.exists(tid)) begin
                    report_fail("D4", "Master write address for unknown transaction");
                end else begin
                    txn_t t = txns[tid];
                    if (t.addr !== m_awaddr) report_fail("E1", "Write addr mismatch");
                    if (t.len !== m_awlen) report_fail("E1", "Write len mismatch");
                    if (t.address_sent) report_fail("D4", "Duplicate master write address");
                    t.address_sent = 1;
                    if (wr_sid_to_mid.exists(t.slave_id)) begin
                        if (wr_sid_to_mid[t.slave_id] !== m_awid) report_fail("D1", "Master ID changed for same slave ID");
                    end else begin
                        if (wr_mid_valid[m_awid]) begin
                            logic [SLV_ID_W-1:0] other_sid = wr_mid_to_sid[m_awid];
                            if (wr_outstanding_count[other_sid] > 0) begin
                                report_fail("D1", "Master ID reused while other slave ID outstanding");
                            end
                        end
                        wr_sid_to_mid[t.slave_id] = m_awid;
                        wr_mid_to_sid[m_awid] = t.slave_id;
                        wr_mid_valid[m_awid] = 1;
                    end
                    t.master_id = m_awid;
                    txns[tid] = t;
                end
            end
        end
    end

    // Master write data handshakes
    always @(posedge clk) begin
        if (rst_n) begin
            if (m_wvalid && m_wready) begin
                if (master_wr_txn_queue.size() == 0) begin
                    report_fail("B3", "Master write data with no pending write transaction");
                end else begin
                    int unsigned tid = master_wr_txn_queue[0];
                    txn_t t = txns[tid];
                    int beat_idx = t.beats_sent;
                    if (m_wdata !== t.wdata[beat_idx]) report_fail("E1", "Write data mismatch");
                    if (m_wstrb !== t.wstrb[beat_idx]) report_fail("E1", "Write strb mismatch");
                    if (m_wlast !== t.wlast[beat_idx]) report_fail("E1", "Write last mismatch");
                    t.beats_sent++;
                    if (m_wlast) void'(master_wr_txn_queue.pop_front());
                    txns[tid] = t;
                end
            end
        end
    end

    // Slave response handshakes
    always @(posedge clk) begin
        if (rst_n) begin
            if (s_rvalid && s_rready) begin
                if (rd_queue[s_rid].size() == 0) begin
                    report_fail("C2", $sformatf("Read response for ID %0d with no outstanding transaction", s_rid));
                end else begin
                    int unsigned tid = rd_queue[s_rid][0];
                    txn_t t = txns[tid];
                    int beat_idx = t.beats_received;
                    if (s_rdata !== t.rdata[beat_idx]) report_fail("E1", "Read data mismatch");
                    if (s_rresp !== t.rresp[beat_idx]) report_fail("E1", "Read resp mismatch");
                    if (s_rlast !== t.rlast[beat_idx]) report_fail("E1", "Read last mismatch");
                    t.beats_received++;
                    if (s_rlast) begin
                        t.completed = 1;
                        void'(rd_queue[s_rid].pop_front());
                        rd_outstanding_count[s_rid]--;
                        if (rd_outstanding_count[s_rid] == 0) begin
                            rd_distinct_count--;
                            last_retire_cycle = cycle_count;
                            last_retired_id = s_rid;
                            if (rd_sid_to_mid.exists(s_rid)) begin
                                logic [MST_ID_W-1:0] mid = rd_sid_to_mid[s_rid];
                                rd_mid_valid[mid] = 0;
                                rd_sid_to_mid.delete(s_rid);
                                rd_mid_to_sid.delete(mid);
                            end
                        end
                    end
                    txns[tid] = t;
                end
            end
            if (s_bvalid && s_bready) begin
                if (wr_queue[s_bid].size() == 0) begin
                    report_fail("C2", $sformatf("Write response for ID %0d with no outstanding transaction", s_bid));
                end else begin
                    int unsigned tid = wr_queue[s_bid][0];
                    txn_t t = txns[tid];
                    t.completed = 1;
                    void'(wr_queue[s_bid].pop_front());
                    wr_outstanding_count[s_bid]--;
                    if (wr_outstanding_count[s_bid] == 0) begin
                        wr_distinct_count--;
                        last_retire_cycle = cycle_count;
                        last_retired_id = s_bid;
                        if (wr_sid_to_mid.exists(s_bid)) begin
                            logic [MST_ID_W-1:0] mid = wr_sid_to_mid[s_bid];
                            wr_mid_valid[mid] = 0;
                            wr_sid_to_mid.delete(s_bid);
                            wr_mid_to_sid.delete(mid);
                        end
                    end
                    txns[tid] = t;
                end
            end
        end
    end

    // Reset checks
    always @(posedge clk) begin
        if (!rst_n) begin
            if (s_bvalid || s_rvalid) report_fail("F1", "Response presented during reset");
        end
    end

    always @(negedge rst_n) begin
        rd_outstanding_count.delete();
        rd_distinct_count = 0;
        rd_queue.delete();
        rd_sid_to_mid.delete();
        rd_mid_to_sid.delete();
        rd_mid_valid.delete();
        wr_outstanding_count.delete();
        wr_distinct_count = 0;
        wr_queue.delete();
        wr_sid_to_mid.delete();
        wr_mid_to_sid.delete();
        wr_mid_valid.delete();
        master_wr_txn_queue.delete();
        master_read_queue.delete();
    end

    // ---------------------------------------------------------------------------
    // MAIN TEST SEQUENCE
    // ---------------------------------------------------------------------------
    initial begin
        // Initialize signals
        s_awid = 0; s_awaddr = 0; s_awlen = 0; s_awvalid = 0;
        s_wdata = 0; s_wstrb = 0; s_wlast = 0; s_wvalid = 0;
        s_bready = 1;
        s_arid = 0; s_araddr = 0; s_arlen = 0; s_arvalid = 0;
        s_rready = 1;
        m_awready = 1;
        m_wready = 1;
        m_arready = 1;
        m_bvalid = 0; m_bid = 0; m_bresp = 0;
        m_rvalid = 0; m_rid = 0; m_rdata = 0; m_rlast = 0; m_rresp = 0;

        bfm_reset(4);
        repeat(2) @(posedge clk);

        // Test 1: Basic read and write
        int unsigned tid_rd0 = next_txn_id++;
        bit acc; int wait;
        bfm_ar(0, tid_rd0, 0, 20, acc, wait);
        if (!acc) report_fail("A3", "Basic read not accepted");
        send_read_response(tid_rd0);

        int unsigned tid_wr1 = next_txn_id++;
        bfm_aw(1, tid_wr1, 0, 20, acc, wait);
        if (!acc) report_fail("A3", "Basic write not accepted");
        send_write_data(tid_wr1);
        send_write_response(tid_wr1);

        // Test 2: Multiple beats
        int unsigned tid_rd2 = next_txn_id++;
        bfm_ar(2, tid_rd2, 1, 20, acc, wait);
        if (!acc) report_fail("A3", "Multi-beat read not accepted");
        send_read_response(tid_rd2);

        int unsigned tid_wr3 = next_txn_id++;
        bfm_aw(3, tid_wr3, 1, 20, acc, wait);
        if (!acc) report_fail("A3", "Multi-beat write not accepted");
        send_write_data(tid_wr3);
        send_write_response(tid_wr3);

        // Test 3: A5 - max txns per ID (reads)
        int unsigned tid_rd4a = next_txn_id++;
        bfm_ar(4, tid_rd4a, 0, 20, acc, wait);
        if (!acc) report_fail("A5", "First read with ID 4 not accepted");
        int unsigned tid_rd4b = next_txn_id++;
        bfm_ar(4, tid_rd4b, 0, 20, acc, wait);
        if (!acc) report_fail("A5", "Second read with ID 4 not accepted");
        int unsigned tid_rd4c = next_txn_id++;
        bfm_ar(4, tid_rd4c, 0, 10, acc, wait);
        if (acc) report_fail("A5", "Third read with ID 4 accepted when max txns reached");
        send_read_response(tid_rd4a);
        bfm_ar(4, tid_rd4c, 0, 20, acc, wait);
        if (!acc) report_fail("A5", "Read with ID 4 not accepted after one completed");
        send_read_response(tid_rd4b);
        send_read_response(tid_rd4c);

        // Test 3b: A5 - max txns per ID (writes)
        int unsigned tid_wr10a = next_txn_id++;
        bfm_aw(10, tid_wr10a, 0, 20, acc, wait);
        if (!acc) report_fail("A5", "First write with ID 10 not accepted");
        int unsigned tid_wr10b = next_txn_id++;
        bfm_aw(10, tid_wr10b, 0, 20, acc, wait);
        if (!acc) report_fail("A5", "Second write with ID 10 not accepted");
        int unsigned tid_wr10c = next_txn_id++;
        bfm_aw(10, tid_wr10c, 0, 10, acc, wait);
        if (acc) report_fail("A5", "Third write with ID 10 accepted when max txns reached");
        send_write_data(tid_wr10a);
        send_write_data(tid_wr10b);
        send_write_response(tid_wr10a);
        bfm_aw(10, tid_wr10c, 0, 20, acc, wait);
        if (!acc) report_fail("A5", "Write with ID 10 not accepted after one completed");
        send_write_data(tid_wr10c);
        send_write_response(tid_wr10b);
        send_write_response(tid_wr10c);

        // Test 4: A3/A4 - table full (reads)
        int unsigned tid_rd5 = next_txn_id++;
        bfm_ar(5, tid_rd5, 0, 20, acc, wait);
        if (!acc) report_fail("A3", "Read ID 5 not accepted");
        int unsigned tid_rd6 = next_txn_id++;
        bfm_ar(6, tid_rd6, 0, 20, acc, wait);
        if (!acc) report_fail("A3", "Read ID 6 not accepted");
        int unsigned tid_rd7 = next_txn_id++;
        bfm_ar(7, tid_rd7, 0, 20, acc, wait);
        if (!acc) report_fail("A3", "Read ID 7 not accepted");
        int unsigned tid_rd8 = next_txn_id++;
        bfm_ar(8, tid_rd8, 0, 20, acc, wait);
        if (!acc) report_fail("A3", "Read ID 8 not accepted");
        int unsigned tid_rd9 = next_txn_id++;
        bfm_ar(9, tid_rd9, 0, 10, acc, wait);
        if (acc) report_fail("A3", "New read ID 9 accepted when table full");
        // A4 test
        bit acc9; int wait9;
        fork
            bfm_ar(9, tid_rd9, 0, 100, acc9, wait9);
        join_none
        repeat(2) @(posedge clk);
        send_read_response(tid_rd5);
        int timeout = 0;
        while (!acc9 && timeout < 1000) begin @(posedge clk); timeout++; end
        if (timeout >= 1000) report_fail("A4", "Timeout waiting for new ID acceptance");
        timeout = 0;
        while (last_retired_id != 5 && timeout < 1000) begin @(posedge clk); timeout++; end
        if (timeout >= 1000) report_fail("A4", "Timeout waiting for retirement of ID 5");
        if (cycle_count - last_retire_cycle > 2) begin
            report_fail("A4", $sformatf("New ID accepted %0d cycles after retirement, expected <=2", cycle_count - last_retire_cycle));
        end
        send_read_response(tid_rd6);
        send_read_response(tid_rd7);
        send_read_response(tid_rd8);
        send_read_response(tid_rd9);

        // Test 5: D1/D2 - master ID assignment
        int unsigned tid_rd11 = next_txn_id++;
        bfm_ar(11, tid_rd11, 0, 20, acc, wait);
        if (!acc) report_fail("D1", "Read ID 11 not accepted");
        int unsigned tid_rd12 = next_txn_id++;
        bfm_ar(12, tid_rd12, 0, 20, acc, wait);
        if (!acc) report_fail("D1", "Read ID 12 not accepted");
        wait_address_sent(tid_rd11);
        wait_address_sent(tid_rd12);
        if (txns[tid_rd11].master_id == txns[tid_rd12].master_id) begin
            report_fail("D1", "Two different slave IDs got same master ID");
        end
        send_read_response(tid_rd11);
        send_read_response(tid_rd12);

        // Test 6: B1 - per-ID ordering
        int unsigned tid_rd13a = next_txn_id++;
        bfm_ar(13, tid_rd13a, 0, 20, acc, wait);
        if (!acc) report_fail("B1", "Read ID 13a not accepted");
        int unsigned tid_rd13b = next_txn_id++;
        bfm_ar(13, tid_rd13b, 0, 20, acc, wait);
        if (!acc) report_fail("B1", "Read ID 13b not accepted");
        wait_address_sent(tid_rd13a);
        wait_address_sent(tid_rd13b);
        send_read_response(tid_rd13a);
        send_read_response(tid_rd13b);

        // Test 7: B3 - write data ordering
        int unsigned tid_wr14 = next_txn_id++;
        bfm_aw(14, tid_wr14, 0, 20, acc, wait);
        if (!acc) report_fail("B3", "Write ID 14 not accepted");
        int unsigned tid_wr15 = next_txn_id++;
        bfm_aw(15, tid_wr15, 0, 20, acc, wait);
        if (!acc) report_fail("B3", "Write ID 15 not accepted");
        send_write_data(tid_wr14);
        send_write_data(tid_wr15);
        send_write_response(tid_wr14);
        send_write_response(tid_wr15);

        // Test 8: Reset behavior (F1)
        int unsigned tid_rd_reset = next_txn_id++;
        bfm_ar(0, tid_rd_reset, 0, 20, acc, wait);
        if (!acc) report_fail("F1", "Read before reset not accepted");
        int unsigned tid_wr_reset = next_txn_id++;
        bfm_aw(1, tid_wr_reset, 0, 20, acc, wait);
        if (!acc) report_fail("F1", "Write before reset not accepted");
        send_write_data(tid_wr_reset);
        @(negedge clk);
        rst_n = 1'b0;
        repeat(4) @(posedge clk);
        @(negedge clk);
        rst_n = 1'b1;
        repeat(10) @(posedge clk);
        if (txns[tid_rd_reset].completed) report_fail("F1", "Read outstanding before reset completed after reset");
        if (txns[tid_wr_reset].completed) report_fail("F1", "Write outstanding before reset completed after reset");
        for (int i = 0; i < 4; i++) begin
            int unsigned tid = next_txn_id++;
            bfm_ar(i, tid, 0, 20, acc, wait);
            if (!acc) report_fail("A3", $sformatf("Read ID %0d not accepted after reset", i));
            send_read_response(tid);
        end

        repeat(10) @(posedge clk);
        if (fail_count == 0) $display("RESULT: PASS");
        else $display("RESULT: FAIL");
        $finish;
    end

endmodule
