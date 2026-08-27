// ============================================================================
// nc_k_overbuffered_read -- d_ca04 CAPABILITY-EXCEEDED CONTROL. Never shipped.
// ============================================================================
// B1 says the FIFO holds 2**LOG_DEPTH entries and a design may add AT MOST 4
// further beats of storage IN TOTAL across both clock domains, and that
// "storage beyond that is NON-CONFORMING." This adds EIGHT, all on the read
// side, on top of the reference's own two.
//
// WHY B1 EXISTS, in its own words: capacity_beats_accepted is REPORTED, and
// more of it looks better -- "a design that adds prefetch stages accepts more
// beats before backpressure and is credited for it, while the area those
// stages cost is charged to nothing. Without a ceiling the metric rewards
// spending rather than design." This control is that design, written out.
//
// THE PERTURBATION. The same cdc_fifo_gray core the reference instantiates,
// with an 8-deep synchronous FIFO in the READ clock domain between the core's
// read port and the module's read port. Every beat crosses correctly, in
// order, with the same gray-coded pointers; H3 holds because a FIFO output
// holds rd_valid and rd_data until the beat is accepted. THE ONLY THING WRONG
// WITH IT IS THAT IT HOLDS 8 MORE BEATS THAN B1 PERMITS.
//
// PREDICTION, stated before running. B1 documented its own non-enforcement --
// "NOT CHECKED BY THE TESTBENCH, and it cannot be from where the checker
// stands" -- so this control would have PASSED for as long as that was true.
// A ceiling check now exists, so:
//
//   ALL configurations SHOULD FAIL, in phase capacity, naming B1, with
//   cap_accepted at DEPTH+10 against a ceiling of DEPTH+4.
//
//   IF IT PASSES, the ceiling does not observe read-side storage and B1 is
//   still unenforced for exactly the shape of design that motivated it.
//
// WHY IT IS OBSERVABLE AFTER ALL, since B1's own text says it is not. The
// objection was that occupancy sampled on wr_clk sees a stale rd_idx and
// OVERSTATES, so a bound on it would fail conforming designs. That is true of
// the running occupancy estimate and NOT true of the at-rest measurement: with
// the reader stopped and the writer refused for 64 consecutive cycles, the
// synchroniser has converged and the read pointer has not moved. The objection
// was right about one of the two occupancy numbers and was applied to both.
//
// POLARITY: NO CROSSOVER. B1's allowance of 4 is a CONSTANT and does not scale
// with LOG_DEPTH, so 8 extra beats exceeds it at every legal depth.
// ============================================================================
`timescale 1ns/1ps

module async_fifo_cdc #(
    parameter int DATA_W      = 32,
    parameter int LOG_DEPTH   = 3,
    parameter int SYNC_STAGES = 2
) (
    input  logic              wr_clk,
    input  logic              wr_rst_n,
    input  logic              wr_valid,
    output logic              wr_ready,
    input  logic [DATA_W-1:0] wr_data,

    input  logic              rd_clk,
    input  logic              rd_rst_n,
    output logic              rd_valid,
    input  logic              rd_ready,
    output logic [DATA_W-1:0] rd_data
);
    localparam int EXTRA = 8;          // B1 permits 4 in total; the core uses 2

    logic              core_valid;
    logic              core_ready;
    logic [DATA_W-1:0] core_data;

    cdc_fifo_gray #(
        .WIDTH       (DATA_W),
        .T           (logic [DATA_W-1:0]),
        .LOG_DEPTH   (LOG_DEPTH),
        .SYNC_STAGES (SYNC_STAGES)
    ) u_cdc (
        .src_rst_ni  (wr_rst_n),
        .src_clk_i   (wr_clk),
        .src_data_i  (wr_data),
        .src_valid_i (wr_valid),
        .src_ready_o (wr_ready),

        .dst_rst_ni  (rd_rst_n),
        .dst_clk_i   (rd_clk),
        .dst_data_o  (core_data),
        .dst_valid_o (core_valid),
        .dst_ready_i (core_ready)
    );

    // ---- the extra storage, entirely inside the read clock domain ----------
    logic [DATA_W-1:0] q_mem [EXTRA];
    int                q_wr, q_rd, q_cnt;

    assign core_ready = (q_cnt < EXTRA);
    assign rd_valid   = (q_cnt != 0);
    assign rd_data    = q_mem[q_rd];

    always_ff @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n) begin
            q_wr <= 0; q_rd <= 0; q_cnt <= 0;
        end else begin
            automatic logic push = core_valid && (q_cnt < EXTRA);
            automatic logic pop  = (q_cnt != 0) && rd_ready;
            if (push) begin
                q_mem[q_wr] <= core_data;
                q_wr <= (q_wr + 1) % EXTRA;
            end
            if (pop) q_rd <= (q_rd + 1) % EXTRA;
            case ({push, pop})
                2'b10: q_cnt <= q_cnt + 1;
                2'b01: q_cnt <= q_cnt - 1;
                default: ;
            endcase
        end
    end

    // ---------------------------------------------------------------------
    // LIVENESS INSTRUMENT. A control's verdict tells you it did not break the
    // harness; it does not tell you it exercised the capability its name
    // claims. If this queue never actually filled, a FAIL would be coming from
    // somewhere else and the conclusion drawn from it would rest on nothing.
    // (AGENT-VERIF-A2's warning, from two v_ca06 perturbations whose R channel
    // had never been slow because a double drive left the gate connected to
    // nothing. Both passed every run for as long as they existed.)
    // ---------------------------------------------------------------------
    int q_peak;
    always_ff @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n) q_peak <= 0;
        else if (q_cnt > q_peak) q_peak <= q_cnt;
    end
    final begin
        $display("METRIC: nc_k peak_extra_occupancy=%0d (EXTRA=%0d, B1 allows 4 in total)",
                 q_peak, EXTRA);
        if (q_peak <= 4)
            $display("  NC_K IS INERT: it never held more than B1 permits, so its verdict is not evidence about B1.");
        else
            $display("  NC_K IS LIVE: it held %0d beats of read-side storage against B1's allowance of 4.", q_peak);
    end
endmodule
