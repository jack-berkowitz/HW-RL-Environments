// =============================================================================
// common_selftest.sv -- validates the shared Tier-2 verification models
// =============================================================================
// golden_mem and mem_stub are depended on by three separate harnesses, so they
// get their own self-test rather than being trusted implicitly.
//   iverilog -g2012 -I testbenches/common -o sim testbenches/common/common_selftest.sv
// =============================================================================
`timescale 1ns/1ps
`include "mem_stub.sv"

module common_selftest;
    localparam int AW = 10, DW = 32;

    int errors = 0, checks = 0;
    string fail_reason = "";

    task automatic chk(input bit cond, input string why);
        checks++;
        if (!cond) begin
            errors++;
            if (fail_reason == "") fail_reason = why;
            if (errors <= 15) $display("[FAIL] t=%0t : %s", $time, why);
        end
    endtask

    logic clk = 1'b0, rst_n;
    always #5 clk = ~clk;

    logic              req_valid, req_we;
    logic [AW-1:0]     req_addr;
    logic [DW-1:0]     req_wdata;
    logic [1:0]        req_size;
    logic              resp_valid, busy, err_overlap;
    logic [DW-1:0]     resp_rdata;
    int                err_overlap_count;

    golden_mem #(.ADDR_W(AW), .DATA_W(DW), .LINE_BYTES(16)) gm ();

    mem_stub #(.ADDR_W(AW), .DATA_W(DW), .MIN_LAT(2), .MAX_LAT(6)) ms (
        .clk(clk), .rst_n(rst_n),
        .req_valid(req_valid), .req_addr(req_addr), .req_we(req_we),
        .req_wdata(req_wdata), .req_size(req_size),
        .resp_valid(resp_valid), .resp_rdata(resp_rdata),
        .busy(busy), .err_overlap(err_overlap), .err_overlap_count(err_overlap_count)
    );

    logic [DW-1:0] got, exp;
    int lat, a, sz;

    // one memory transaction, returning observed latency
    task automatic mem_txn(input int addr, input bit we, input int size,
                           input logic [DW-1:0] wd);
        req_valid = 1'b1; req_addr = AW'(addr); req_we = we;
        req_wdata = wd;   req_size = 2'(size);
        @(posedge clk); #1;
        req_valid = 1'b0;
        lat = 0;
        while (!resp_valid) begin @(posedge clk); #1; lat++;
            if (lat > 40) begin chk(0, "mem_stub: no response within 40 cycles"); return; end
        end
        got = resp_rdata;
        chk(lat >= 2 && lat <= 6, $sformatf("mem_stub latency %0d outside [2,6]", lat));
    endtask

    initial begin
        // ---------------- golden_mem: sized little-endian access ----------------
        gm.init_zero();
        gm.wr_sized(16, 2, 32'hDEADBEEF);
        chk(gm.rd_sized(16,2) === 32'hDEADBEEF, "gm: word round-trip");
        chk(gm.rd_byte(16) === 8'hEF, "gm: little-endian byte 0");
        chk(gm.rd_byte(19) === 8'hDE, "gm: little-endian byte 3");
        chk(gm.rd_sized(16,1) === 32'h0000BEEF, "gm: halfword read of low half");
        chk(gm.rd_sized(18,1) === 32'h0000DEAD, "gm: halfword read of high half");
        chk(gm.rd_sized(17,0) === 32'h000000BE, "gm: byte read at offset 1");

        // sub-word write must not disturb neighbours
        gm.wr_sized(17, 0, 32'h11);
        chk(gm.rd_sized(16,2) === 32'hDEAD11EF, "gm: byte write left neighbours intact");

        // wrap: an out-of-range address must fold in, not crash
        gm.wr_sized((1<<AW) + 4, 2, 32'hCAFEF00D);
        chk(gm.rd_sized(4,2) === 32'hCAFEF00D, "gm: address wrap folds into space");

        // line access
        gm.init_zero();
        gm.wr_line(32, {4{32'h01234567}});
        chk(gm.rd_line(32) === {4{32'h01234567}}, "gm: line round-trip");
        chk(gm.rd_sized(32,2) === 32'h01234567, "gm: line/scalar views agree");

        // pattern fill must not be all-zero (an unfetched load must not look right)
        gm.init_pattern(3);
        begin
            int nz; nz = 0;
            for (int i = 0; i < 64; i++) if (gm.rd_byte(i) !== 8'h00) nz++;
            chk(nz > 40, "gm: init_pattern produced too many zero bytes");
        end

        // ---------------- mem_stub ----------------
        req_valid = 0; req_we = 0; req_addr = '0; req_wdata = '0; req_size = 2'd2;
        rst_n = 1'b0; repeat (3) @(posedge clk); #1; rst_n = 1'b1; @(posedge clk); #1;

        ms.init_pattern(3);            // stub storage mirrors gm's pattern
        gm.init_pattern(3);

        // reads must match the golden model, at several sizes
        for (int k = 0; k < 24; k++) begin
            a  = ($urandom_range(0, 63) * 4);
            sz = $urandom_range(0, 2);
            exp = gm.rd_sized(a, sz);
            mem_txn(a, 1'b0, sz, '0);
            chk(got === exp, $sformatf("mem_stub read @0x%0h sz%0d = 0x%0h expected 0x%0h",
                                       a, sz, got, exp));
        end

        // writes must land, and be visible to a later read
        for (int k = 0; k < 24; k++) begin
            logic [DW-1:0] wd;
            a  = ($urandom_range(0, 63) * 4);
            sz = $urandom_range(0, 2);
            wd = DW'($urandom());
            gm.wr_sized(a, sz, wd);
            mem_txn(a, 1'b1, sz, wd);
            exp = gm.rd_sized(a, sz);
            mem_txn(a, 1'b0, sz, '0);
            chk(got === exp, $sformatf("mem_stub write/read-back @0x%0h sz%0d = 0x%0h expected 0x%0h",
                                       a, sz, got, exp));
        end

        // whole-image agreement
        begin
            int bad; bad = 0;
            for (int i = 0; i < (1<<AW); i++)
                if (ms.peek_byte(i) !== gm.rd_byte(i)) bad++;
            chk(bad == 0, $sformatf("mem_stub image diverges from golden in %0d bytes", bad));
        end

        // single-outstanding violation must be DETECTED, not swallowed
        chk(err_overlap === 1'b0, "mem_stub flagged an overlap during legal traffic");
        req_valid = 1'b1; req_addr = '0; req_we = 1'b0; req_size = 2'd2;
        repeat (3) @(posedge clk);      // hold valid across the busy window
        #1;
        chk(err_overlap === 1'b1, "mem_stub failed to flag a request issued while busy");
        req_valid = 1'b0;
        repeat (10) @(posedge clk);

        if (errors == 0) begin
            $display("// info: %0d checks on golden_mem + mem_stub", checks);
            $display("TEST_RESULT: PASS");
        end else
            $display("TEST_RESULT: FAIL: %s (%0d failing of %0d)", fail_reason, errors, checks);
        $finish;
    end

    initial begin
        #500_000;
        $display("TEST_RESULT: FAIL: timeout -- common selftest did not complete");
        $finish;
    end
endmodule
