// =============================================================================
// async_fifo_cdc_ref.sv -- THIN PORT SHIM for d_ca04.
// =============================================================================
// Wraps vendored upstream RTL:
//   refs/common_cells/src/cdc_fifo_gray.sv
//   pulp-platform/common_cells @ 9ca8a7655f741e7dd5736669a20a301325194c28
//   (tag v1.39.0, SHL-0.51)
//
// CLASS A. The behaviour under test is PULP's, not ours. This file contains NO
// logic: no state, no decisions, nothing that could change what the FIFO does.
// It is port renaming and parameter mapping only -- and unlike nw_d01's shim
// there is not even a polarity inversion here, because upstream already uses
// active-low resets in both domains.
//
// Parameter mapping:
//   DATA_W      -> WIDTH (and T defaults to logic [WIDTH-1:0])
//   LOG_DEPTH   -> LOG_DEPTH   (upstream depth is 2**LOG_DEPTH, same convention)
//   SYNC_STAGES -> SYNC_STAGES
// =============================================================================

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
        .dst_data_o  (rd_data),
        .dst_valid_o (rd_valid),
        .dst_ready_i (rd_ready)
    );

endmodule
