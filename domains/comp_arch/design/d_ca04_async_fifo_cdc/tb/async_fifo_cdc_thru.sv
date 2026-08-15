// =============================================================================
// async_fifo_cdc_thru.sv -- sustained-throughput measurement. NEVER SHIPPED.
// =============================================================================
// Not a checker: it emits no TEST_RESULT and decides nothing. It answers one
// question the correctness checker deliberately does not ask, because the spec
// deliberately does not constrain it -- what sustained throughput does a design
// actually achieve under continuous offered load?
//
// The reason this matters: upstream cdc_fifo_gray carries a spill_register on
// its output that a leaner implementation may omit. That is an area saving, but
// a spill register also decouples the output handshake, so dropping it can cost
// throughput. An area win bought with throughput is not the same as an area win
// -- and if only area is reported, the trade is invisible.
//
// wr_valid and rd_ready are held HIGH for the whole run, so the number measured
// is the design's own ceiling and not an artifact of the stimulus.
// =============================================================================

`timescale 1ps/1ps

module async_fifo_cdc_thru #(
    parameter int DATA_W      = 32,
    parameter int LOG_DEPTH   = 3,
    parameter int SYNC_STAGES = 2,
    parameter int WR_HALF     = 5000,
    parameter int RD_HALF     = 5000,
    parameter int RUN_CYCLES  = 20000
);

    logic wr_clk = 1'b0, rd_clk = 1'b0;
    always #(WR_HALF) wr_clk = ~wr_clk;
    always #(RD_HALF) rd_clk = ~rd_clk;

    logic              wr_rst_n, rd_rst_n;
    logic              wr_valid, wr_ready;
    logic [DATA_W-1:0] wr_data;
    logic              rd_valid, rd_ready;
    logic [DATA_W-1:0] rd_data;

    async_fifo_cdc #(.DATA_W(DATA_W), .LOG_DEPTH(LOG_DEPTH), .SYNC_STAGES(SYNC_STAGES)) dut (
        .wr_clk(wr_clk), .wr_rst_n(wr_rst_n), .wr_valid(wr_valid),
        .wr_ready(wr_ready), .wr_data(wr_data),
        .rd_clk(rd_clk), .rd_rst_n(rd_rst_n), .rd_valid(rd_valid),
        .rd_ready(rd_ready), .rd_data(rd_data));

    longint wr_beats = 0, rd_beats = 0, wr_cycles = 0, rd_cycles = 0;

    always_ff @(posedge wr_clk) if (wr_rst_n) begin
        wr_cycles++;
        if (wr_valid && wr_ready) wr_beats++;
        wr_data <= wr_data + 1;
    end
    always_ff @(posedge rd_clk) if (rd_rst_n) begin
        rd_cycles++;
        if (rd_valid && rd_ready) rd_beats++;
    end

    initial begin
        wr_valid = 1'b1; rd_ready = 1'b1; wr_data = '0;
        wr_rst_n = 1'b0; rd_rst_n = 1'b0;
        repeat (8) @(posedge wr_clk);
        wr_rst_n = 1'b1; rd_rst_n = 1'b1;
        repeat (RUN_CYCLES) @(posedge rd_clk);
        $display("METRIC: thru wr_beats=%0d/%0d rd_beats=%0d/%0d wr_pct=%0d rd_pct=%0d",
                 wr_beats, wr_cycles, rd_beats, rd_cycles,
                 (wr_cycles == 0) ? 0 : (wr_beats * 100) / wr_cycles,
                 (rd_cycles == 0) ? 0 : (rd_beats * 100) / rd_cycles);
        $finish;
    end

    initial begin
        #500_000_000;
        $display("METRIC: thru TIMEOUT");
        $finish;
    end

endmodule
