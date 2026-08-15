// =============================================================================
// axi4_xbar_diffrate_tb.sv -- DIFF RATE measurement. NEVER SHIPPED.
// =============================================================================
// Reference and mutant, side by side, driven by ONE stimulus generator, outputs
// compared every cycle. Diff rate = cycles on which any observable output
// differs / cycles measured.
//
// The stimulus is generated INDEPENDENTLY OF EITHER DUT -- valid/data/ready
// patterns come from a free-running LFSR, not from a master model reacting to
// ready. If the generator reacted to one DUT the two would see different
// stimulus and the comparison would be meaningless.
//
// THIS IS A WITNESS, NOT A SCORE. It answers exactly one question: was
// non-equivalence demonstrated under this stimulus? A zero means THIS STIMULUS
// DID NOT DISTINGUISH THEM -- never that the designs are equivalent.
//
// Diff rate was previously used as a mutant-quality band. That was tested and
// retracted: it rated the most valuable mutant in the project (a real model
// submission that fooled the entire data checker) at 100%, and a comfortably
// killable one at 0%. See FINDINGS.md. Do not reintroduce a quality reading.
// =============================================================================

`timescale 1ns/1ps

module axi4_xbar_diffrate_tb
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
    mst_resp_t [NUM_SLV-1:0] slv_resp;
    xbar_rule_t [NUM_SLV-1:0] addr_map;

    slv_resp_t [NUM_MST-1:0] a_mst_resp, b_mst_resp;
    mst_req_t  [NUM_SLV-1:0] a_slv_req,  b_slv_req;

    axi4_xbar     #(.NUM_MST(NUM_MST), .NUM_SLV(NUM_SLV), .MAX_TRANS(MAX_TRANS)) u_ref (
        .clk(clk), .rst_n(rst_n), .mst_req(mst_req), .mst_resp(a_mst_resp),
        .slv_req(a_slv_req), .slv_resp(slv_resp), .addr_map(addr_map));

    axi4_xbar_mut #(.NUM_MST(NUM_MST), .NUM_SLV(NUM_SLV), .MAX_TRANS(MAX_TRANS)) u_mut (
        .clk(clk), .rst_n(rst_n), .mst_req(mst_req), .mst_resp(b_mst_resp),
        .slv_req(b_slv_req), .slv_resp(slv_resp), .addr_map(addr_map));

    initial for (int s = 0; s < NUM_SLV; s++) begin
        addr_map[s].mst_port   = s[$clog2(8)-1:0];
        addr_map[s].start_addr = addr_t'(s * 32'h0001_0000);
        addr_map[s].end_addr   = addr_t'((s + 1) * 32'h0001_0000);
    end

    // ---- LOCKSTEP stimulus, protocol-legal for BOTH DUTs --------------------
    // A free-running LFSR driving valid/payload directly is NOT legal AXI: it
    // deasserts and mutates valid before ready, and the vendored arbiter's own
    // assertion fires on it ("Req out implies req in"), aborting the run. So the
    // stimulus is held: once a channel asserts valid, valid and payload stay
    // stable until BOTH DUTs have accepted, then the next value is drawn.
    //
    // Holding until both accept keeps them on identical stimulus -- the faster
    // DUT simply waits for the slower, which is exactly what a diff-rate
    // comparison needs. It also means a capacity defect shows up as the
    // reference idling, which is the behaviour under test.
    logic [31:0] lfsr = 32'hACE1_2345;
    logic [NUM_MST-1:0] ar_hold, aw_hold, w_hold;
    logic [NUM_MST-1:0] ar_done_a, ar_done_b, aw_done_a, aw_done_b, w_done_a, w_done_b;

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            lfsr <= 32'hACE1_2345;
            ar_hold <= '0; aw_hold <= '0; w_hold <= '0;
            ar_done_a <= '0; ar_done_b <= '0;
            aw_done_a <= '0; aw_done_b <= '0;
            w_done_a  <= '0; w_done_b  <= '0;
        end else begin
            lfsr <= {lfsr[30:0], lfsr[31]^lfsr[21]^lfsr[1]^lfsr[0]};
            for (int m = 0; m < NUM_MST; m++) begin
                // AR
                if (!ar_hold[m]) begin
                    ar_hold[m] <= lfsr[m];
                    ar_done_a[m] <= 1'b0; ar_done_b[m] <= 1'b0;
                end else begin
                    if (a_mst_resp[m].ar_ready) ar_done_a[m] <= 1'b1;
                    if (b_mst_resp[m].ar_ready) ar_done_b[m] <= 1'b1;
                    if ((ar_done_a[m] || a_mst_resp[m].ar_ready) &&
                        (ar_done_b[m] || b_mst_resp[m].ar_ready)) begin
                        ar_hold[m] <= 1'b0;
                        ar_done_a[m] <= 1'b0; ar_done_b[m] <= 1'b0;
                    end
                end
                // AW
                if (!aw_hold[m]) begin
                    aw_hold[m] <= lfsr[m+4];
                    aw_done_a[m] <= 1'b0; aw_done_b[m] <= 1'b0;
                end else begin
                    if (a_mst_resp[m].aw_ready) aw_done_a[m] <= 1'b1;
                    if (b_mst_resp[m].aw_ready) aw_done_b[m] <= 1'b1;
                    if ((aw_done_a[m] || a_mst_resp[m].aw_ready) &&
                        (aw_done_b[m] || b_mst_resp[m].aw_ready)) begin
                        aw_hold[m] <= 1'b0;
                        aw_done_a[m] <= 1'b0; aw_done_b[m] <= 1'b0;
                    end
                end
                // W
                if (!w_hold[m]) begin
                    w_hold[m] <= lfsr[m+8];
                    w_done_a[m] <= 1'b0; w_done_b[m] <= 1'b0;
                end else begin
                    if (a_mst_resp[m].w_ready) w_done_a[m] <= 1'b1;
                    if (b_mst_resp[m].w_ready) w_done_b[m] <= 1'b1;
                    if ((w_done_a[m] || a_mst_resp[m].w_ready) &&
                        (w_done_b[m] || b_mst_resp[m].w_ready)) begin
                        w_hold[m] <= 1'b0;
                        w_done_a[m] <= 1'b0; w_done_b[m] <= 1'b0;
                    end
                end
            end
        end
    end

    // Payload is a function of a value that only changes when the channel is
    // idle, so it is stable across the whole valid-to-ready window.
    logic [31:0] pay [0:NUM_MST-1];
    always_ff @(posedge clk)
        for (int m = 0; m < NUM_MST; m++)
            if (!ar_hold[m] && !aw_hold[m]) pay[m] <= lfsr;

    for (genvar m = 0; m < NUM_MST; m++) begin : g_mst
        always_comb begin
            mst_req[m]          = '0;
            mst_req[m].ar_valid = ar_hold[m] && !(ar_done_a[m] && ar_done_b[m]);
            mst_req[m].ar.id    = slv_id_t'(pay[m][7:4]);
            mst_req[m].ar.addr  = addr_t'({pay[m][19:8], 4'h0} & 32'h0001_FFF0);
            mst_req[m].ar.len   = 8'(pay[m][9:8]);
            mst_req[m].ar.size  = 3'd3;
            mst_req[m].ar.burst = BURST_INCR;
            mst_req[m].aw_valid = aw_hold[m] && !(aw_done_a[m] && aw_done_b[m]);
            mst_req[m].aw       = mst_req[m].ar;
            mst_req[m].w_valid  = w_hold[m] && !(w_done_a[m] && w_done_b[m]);
            mst_req[m].w.data   = data_t'(pay[m]);
            mst_req[m].w.strb   = '1;
            mst_req[m].w.last   = pay[m][12];
            mst_req[m].r_ready  = lfsr[m+16];
            mst_req[m].b_ready  = lfsr[m+20];
        end
    end
    // Slaves respond to whichever DUT is driving them; each DUT has its own
    // slave-side view, so these are per-DUT and cannot be shared.
    for (genvar s = 0; s < NUM_SLV; s++) begin : g_slv
        always_comb begin
            slv_resp[s]          = '0;
            slv_resp[s].ar_ready = lfsr[s+24];
            slv_resp[s].aw_ready = lfsr[s+26];
            slv_resp[s].w_ready  = lfsr[s+28];
            slv_resp[s].r_valid  = 1'b0;
            slv_resp[s].b_valid  = 1'b0;
        end
    end

    int cyc = 0, diff = 0;
    int first_diff = -1;
    always_ff @(posedge clk) if (rst_n) begin
        automatic bit d = 1'b0;
        cyc <= cyc + 1;
        for (int m = 0; m < NUM_MST; m++)
            if (a_mst_resp[m] !== b_mst_resp[m]) d = 1'b1;
        for (int s = 0; s < NUM_SLV; s++)
            if (a_slv_req[s] !== b_slv_req[s]) d = 1'b1;
        if (d) begin
            diff <= diff + 1;
            if (first_diff < 0) first_diff <= cyc;   // witness cycle
        end
    end

    initial begin
        rst_n = 1'b0;
        repeat (12) @(posedge clk);
        rst_n = 1'b1;
        repeat (WINDOW) @(posedge clk);
        // The FIELD NAME carries the meaning: this is a witness, not a score.
        // Diff rate was demoted from a quality band after it ranked the most
        // valuable mutant in the project at 100% and a comfortably killable one
        // at 0% -- see FINDINGS.md.
        $display("METRIC: non_equivalence_demonstrated=%0d witness_cycle=%0d divergent_cycles=%0d of %0d",
                 (diff > 0), first_diff, diff, cyc);
        if (diff == 0)
            $display("TEST_RESULT: FAIL: mutant INDISTINGUISHABLE from reference on this stimulus -- no witness, non-equivalence NOT demonstrated");
        else
            $display("TEST_RESULT: PASS");
        $finish;
    end
endmodule
