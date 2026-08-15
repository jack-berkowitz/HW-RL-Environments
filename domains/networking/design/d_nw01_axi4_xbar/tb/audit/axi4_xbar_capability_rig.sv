// =============================================================================
// axi4_xbar_capability_tb.sv -- CAPABILITY AUDIT for d_nw01. NEVER SHIPPED.
// =============================================================================
// Not a checker: emits no TEST_RESULT and decides nothing. It measures what a
// design is CAPABLE of, which is different from whether it is correct.
//
// Motivation: a candidate came in 67 % smaller than the vendored reference and
// passed every correctness config. At that magnitude the two are probably not
// doing the same thing, and the checker would not see it, because the contract
// never required them to.
//
// Three measurements, each isolating one capability the spec failed to pin:
//
//   PHASE 1  OUTSTANDING CAPACITY -- responses are never accepted, so the
//            design fills up and stalls. The count at stall is how many
//            transactions it can have in flight per master.
//
//   PHASE 2  CONCURRENCY -- master0 talks only to slave0 and master1 only to
//            slave1. Disjoint pairs share nothing, so a real crossbar serves
//            them in parallel and aggregate throughput is ~2x one pair alone.
//            A design that funnels everything through one shared arbiter is
//            correct on every transaction and scores ~1x.
//
//   PHASE 3  AGGREGATE THROUGHPUT -- all-to-all saturation. Exposes 1 and 2
//            together as a single number.
//
// Prints CAPABILITY: lines. Compare two designs by running it against each.
// =============================================================================

`timescale 1ns/1ps

module axi4_xbar_capability_tb
  import axi4_xbar_pkg::*;
#(
    parameter int NUM_MST   = 4,
    parameter int NUM_SLV   = 2,
    parameter int MAX_TRANS = 8,
    parameter int WINDOW    = 20000
);

    logic clk = 1'b0, rst_n;
    always #5 clk = ~clk;

    slv_req_t  [NUM_MST-1:0] mst_req;
    slv_resp_t [NUM_MST-1:0] mst_resp;
    mst_req_t  [NUM_SLV-1:0] slv_req;
    mst_resp_t [NUM_SLV-1:0] slv_resp;
    xbar_rule_t [NUM_SLV-1:0] addr_map;

    axi4_xbar #(.NUM_MST(NUM_MST), .NUM_SLV(NUM_SLV), .MAX_TRANS(MAX_TRANS)) dut (
        .clk(clk), .rst_n(rst_n), .mst_req(mst_req), .mst_resp(mst_resp),
        .slv_req(slv_req), .slv_resp(slv_resp), .addr_map(addr_map));

    initial for (int s = 0; s < NUM_SLV; s++) begin
        addr_map[s].mst_port   = s[$clog2(8)-1:0];
        addr_map[s].start_addr = addr_t'(s * 32'h0001_0000);
        addr_map[s].end_addr   = addr_t'((s + 1) * 32'h0001_0000);
    end

    // ---- master drivers: target and enable are set by the sequencer --------
    logic [NUM_MST-1:0] m_en;
    int                 m_target [0:NUM_MST-1];
    bit                 accept_r;          // phase 1 holds this low
    int                 ar_accepted [0:NUM_MST-1];
    int                 bursts_done [0:NUM_MST-1];

    for (genvar m = 0; m < NUM_MST; m++) begin : g_mst
        always_comb begin
            mst_req[m]          = '0;
            mst_req[m].r_ready  = accept_r;
            mst_req[m].b_ready  = 1'b1;
            mst_req[m].ar_valid = m_en[m];
            mst_req[m].ar.id    = slv_id_t'(m);
            mst_req[m].ar.addr  = addr_t'(m_target[m] * 32'h0001_0000 + 32'h40);
            mst_req[m].ar.len   = 8'd0;         // single-beat: capacity, not burst length
            mst_req[m].ar.size  = 3'd3;
            mst_req[m].ar.burst = BURST_INCR;
        end
        always_ff @(posedge clk) begin
            if (!rst_n) begin ar_accepted[m] <= 0; bursts_done[m] <= 0; end
            else begin
                if (mst_req[m].ar_valid && mst_resp[m].ar_ready)
                    ar_accepted[m] <= ar_accepted[m] + 1;
                if (mst_resp[m].r_valid && mst_req[m].r_ready && mst_resp[m].r.last)
                    bursts_done[m] <= bursts_done[m] + 1;
            end
        end
    end

    // ---- slave models: accept one AR, return it, zero added latency --------
    // sink_ar (phase 1 only) makes the slave accept EVERY AR and return nothing.
    // Without it the slave itself is the thing that backs up, and phase 1
    // measures the depth of my model's pipeline rather than the DUT's capacity.
    bit      sink_ar;
    int      s_beats [0:NUM_SLV-1];
    mst_id_t s_id    [0:NUM_SLV-1];
    for (genvar s = 0; s < NUM_SLV; s++) begin : g_slv
        always_comb begin
            slv_resp[s]          = '0;
            slv_resp[s].ar_ready = sink_ar ? 1'b1 : (s_beats[s] == 0);
            slv_resp[s].aw_ready = 1'b1;
            slv_resp[s].w_ready  = 1'b1;
            slv_resp[s].r_valid  = (s_beats[s] != 0);
            slv_resp[s].r.id     = s_id[s];
            slv_resp[s].r.data   = data_t'(s);
            slv_resp[s].r.resp   = RESP_OKAY;
            slv_resp[s].r.last   = 1'b1;
        end
        always_ff @(posedge clk) begin
            if (!rst_n) s_beats[s] <= 0;
            else if (sink_ar) s_beats[s] <= 0;
            else if (slv_req[s].ar_valid && slv_resp[s].ar_ready) begin
                s_beats[s] <= 1; s_id[s] <= slv_req[s].ar.id;
            end else if (slv_resp[s].r_valid && slv_req[s].r_ready)
                s_beats[s] <= 0;
        end
    end

    task automatic reset_all();
        m_en = '0; accept_r = 1'b1; sink_ar = 1'b0;
        for (int m = 0; m < NUM_MST; m++) m_target[m] = 0;
        rst_n = 1'b0;
        repeat (12) @(posedge clk);
        rst_n = 1'b1;
        repeat (4) @(posedge clk);
    endtask

    int t0, agg_pair, agg_single, agg_all;

    initial begin
        // =====================================================================
        // PHASE 1 -- outstanding capacity, per master
        // Responses are NEVER accepted, so the design fills and stalls. The
        // accepted count at stall is its in-flight capacity.
        // =====================================================================
        reset_all();
        accept_r = 1'b0;                      // never drain
        sink_ar  = 1'b1;                      // slave never backs up: DUT is the only limit
        for (int m = 0; m < NUM_MST; m++) m_target[m] = m % NUM_SLV;
        m_en = '1;
        repeat (2000) @(posedge clk);
        m_en = '0;
        $write("CAPABILITY: outstanding_per_master =");
        for (int m = 0; m < NUM_MST; m++) $write(" %0d", ar_accepted[m]);
        $write("   (MAX_TRANS parameter = %0d)\n", MAX_TRANS);

        // =====================================================================
        // PHASE 2 -- concurrency across DISJOINT master/slave pairs
        // First one pair alone, then two disjoint pairs. A real crossbar serves
        // disjoint pairs in parallel, so the second number is ~2x the first.
        // Anything near 1x means everything is funnelling through one arbiter.
        // =====================================================================
        reset_all();
        m_target[0] = 0;
        m_en = '0; m_en[0] = 1'b1;            // master0 -> slave0 alone
        repeat (WINDOW) @(posedge clk);
        agg_single = bursts_done[0];
        m_en = '0;

        reset_all();
        m_target[0] = 0; m_target[1] = 1;     // disjoint pairs, no shared slave
        m_en = '0; m_en[0] = 1'b1; m_en[1] = 1'b1;
        repeat (WINDOW) @(posedge clk);
        agg_pair = bursts_done[0] + bursts_done[1];
        m_en = '0;

        $display("CAPABILITY: one_pair_bursts=%0d two_disjoint_pairs_bursts=%0d speedup_x100=%0d",
                 agg_single, agg_pair,
                 (agg_single == 0) ? 0 : (agg_pair * 100) / agg_single);
        $display("CAPABILITY: per_master_in_disjoint_test m0=%0d m1=%0d",
                 bursts_done[0], bursts_done[1]);

        // =====================================================================
        // PHASE 3 -- all-to-all saturation
        // =====================================================================
        reset_all();
        for (int m = 0; m < NUM_MST; m++) m_target[m] = m % NUM_SLV;
        m_en = '1;
        repeat (WINDOW) @(posedge clk);
        agg_all = 0;
        for (int m = 0; m < NUM_MST; m++) agg_all += bursts_done[m];
        m_en = '0;
        $display("CAPABILITY: all_to_all_bursts=%0d over %0d cycles, bursts_per_1000cyc=%0d",
                 agg_all, WINDOW, (agg_all * 1000) / WINDOW);
        $finish;
    end

    initial begin
        #50_000_000;
        $display("CAPABILITY: TIMEOUT");
        $finish;
    end

endmodule
