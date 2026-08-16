// =============================================================================
// Conformant perturbations of tag_tracker -- see README.md in this directory.
//
// THESE MUST SURVIVE. Each changes only behaviour the specification leaves
// open, so a testbench that fails one is relying on an unpromised property.
//
// Every module here wraps the UNMODIFIED golden. The wrapper is the entire
// difference, which is what makes the result attributable.
// =============================================================================
`timescale 1ns/1ps

// -----------------------------------------------------------------------------
// c1 -- match_gnt_o free-runs.
// R11: a search completes on match_req_i && match_gnt_o. The value of
// match_gnt_o while no request is pending is not a contract term.
// -----------------------------------------------------------------------------
module tt_c1_match_gnt_freerun #(
    parameter int TAG_W = 0, parameter int SLOTS = 0,
    parameter bit FULL_RATE = 0, parameter bit CUT_POP_PATH = 0,
    parameter int N_MATCH = 1, parameter type payload_t = logic[31:0],
    localparam type tag_t = logic[TAG_W-1:0]
) (
    input logic clk_i, rst_ni,
    input tag_t push_tag_i, input payload_t push_data_i,
    input logic push_req_i, output logic push_gnt_o,
    input payload_t [N_MATCH-1:0] match_data_i, match_mask_i,
    input logic [N_MATCH-1:0] match_req_i,
    output logic [N_MATCH-1:0] match_hit_o, match_gnt_o,
    input tag_t pop_tag_i, input logic pop_en_i, pop_req_i,
    output payload_t pop_data_o, output logic pop_data_valid_o, pop_gnt_o,
    output logic full_o, empty_o
);
    logic [N_MATCH-1:0] inner_match_gnt;
    tag_tracker #(.TAG_W(TAG_W), .SLOTS(SLOTS), .FULL_RATE(FULL_RATE),
                  .CUT_POP_PATH(CUT_POP_PATH), .N_MATCH(N_MATCH),
                  .payload_t(payload_t)) u_golden (
        .clk_i, .rst_ni, .push_tag_i, .push_data_i, .push_req_i, .push_gnt_o,
        .match_data_i, .match_mask_i, .match_req_i, .match_hit_o,
        .match_gnt_o(inner_match_gnt),
        .pop_tag_i, .pop_en_i, .pop_req_i, .pop_data_o, .pop_data_valid_o,
        .pop_gnt_o, .full_o, .empty_o);

    // Grant is presented as always-available. A real completion still requires
    // match_req_i, which the golden continues to police internally.
    assign match_gnt_o = {N_MATCH{1'b1}};
endmodule


// -----------------------------------------------------------------------------
// c2 -- pop_data_o is garbage whenever pop_data_valid_o is low.
// R10: pop_data_o is explicitly unconstrained when no entry is present.
// -----------------------------------------------------------------------------
module tt_c2_pop_data_garbage #(
    parameter int TAG_W = 0, parameter int SLOTS = 0,
    parameter bit FULL_RATE = 0, parameter bit CUT_POP_PATH = 0,
    parameter int N_MATCH = 1, parameter type payload_t = logic[31:0],
    localparam type tag_t = logic[TAG_W-1:0]
) (
    input logic clk_i, rst_ni,
    input tag_t push_tag_i, input payload_t push_data_i,
    input logic push_req_i, output logic push_gnt_o,
    input payload_t [N_MATCH-1:0] match_data_i, match_mask_i,
    input logic [N_MATCH-1:0] match_req_i,
    output logic [N_MATCH-1:0] match_hit_o, match_gnt_o,
    input tag_t pop_tag_i, input logic pop_en_i, pop_req_i,
    output payload_t pop_data_o, output logic pop_data_valid_o, pop_gnt_o,
    output logic full_o, empty_o
);
    payload_t inner_pop_data;
    logic     inner_valid;
    logic [31:0] lfsr;

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) lfsr <= 32'hACE1_2345;
        else         lfsr <= {lfsr[30:0], lfsr[31] ^ lfsr[21] ^ lfsr[1] ^ lfsr[0]};
    end

    tag_tracker #(.TAG_W(TAG_W), .SLOTS(SLOTS), .FULL_RATE(FULL_RATE),
                  .CUT_POP_PATH(CUT_POP_PATH), .N_MATCH(N_MATCH),
                  .payload_t(payload_t)) u_golden (
        .clk_i, .rst_ni, .push_tag_i, .push_data_i, .push_req_i, .push_gnt_o,
        .match_data_i, .match_mask_i, .match_req_i, .match_hit_o, .match_gnt_o,
        .pop_tag_i, .pop_en_i, .pop_req_i,
        .pop_data_o(inner_pop_data), .pop_data_valid_o(inner_valid),
        .pop_gnt_o, .full_o, .empty_o);

    assign pop_data_valid_o = inner_valid;
    assign pop_data_o       = inner_valid ? inner_pop_data : payload_t'(lfsr);
endmodule


// -----------------------------------------------------------------------------
// c3 -- push_gnt_o withheld on alternate cycles even when space exists.
// R6: grant may be low for reasons other than fullness.
// The request is gated into the golden as well, so no entry is committed while
// the grant is hidden -- withholding the grant WITHOUT gating the request would
// be a genuine violation rather than a conformant perturbation.
// -----------------------------------------------------------------------------
module tt_c3_push_gnt_throttled #(
    parameter int TAG_W = 0, parameter int SLOTS = 0,
    parameter bit FULL_RATE = 0, parameter bit CUT_POP_PATH = 0,
    parameter int N_MATCH = 1, parameter type payload_t = logic[31:0],
    localparam type tag_t = logic[TAG_W-1:0]
) (
    input logic clk_i, rst_ni,
    input tag_t push_tag_i, input payload_t push_data_i,
    input logic push_req_i, output logic push_gnt_o,
    input payload_t [N_MATCH-1:0] match_data_i, match_mask_i,
    input logic [N_MATCH-1:0] match_req_i,
    output logic [N_MATCH-1:0] match_hit_o, match_gnt_o,
    input tag_t pop_tag_i, input logic pop_en_i, pop_req_i,
    output payload_t pop_data_o, output logic pop_data_valid_o, pop_gnt_o,
    output logic full_o, empty_o
);
    logic allow;
    logic inner_push_gnt;

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) allow <= 1'b0;
        else         allow <= ~allow;
    end

    tag_tracker #(.TAG_W(TAG_W), .SLOTS(SLOTS), .FULL_RATE(FULL_RATE),
                  .CUT_POP_PATH(CUT_POP_PATH), .N_MATCH(N_MATCH),
                  .payload_t(payload_t)) u_golden (
        .clk_i, .rst_ni, .push_tag_i, .push_data_i,
        .push_req_i(push_req_i & allow), .push_gnt_o(inner_push_gnt),
        .match_data_i, .match_mask_i, .match_req_i, .match_hit_o, .match_gnt_o,
        .pop_tag_i, .pop_en_i, .pop_req_i, .pop_data_o, .pop_data_valid_o,
        .pop_gnt_o, .full_o, .empty_o);

    assign push_gnt_o = inner_push_gnt & allow;
endmodule


// -----------------------------------------------------------------------------
// c4 -- pop_gnt_o delayed by one cycle.
// Latitude 6: the number of cycles between request and grant is unconstrained.
// The request is likewise delayed into the golden so that the completion the
// testbench observes is the one the golden actually performed.
// -----------------------------------------------------------------------------
module tt_c4_pop_gnt_delayed #(
    parameter int TAG_W = 0, parameter int SLOTS = 0,
    parameter bit FULL_RATE = 0, parameter bit CUT_POP_PATH = 0,
    parameter int N_MATCH = 1, parameter type payload_t = logic[31:0],
    localparam type tag_t = logic[TAG_W-1:0]
) (
    input logic clk_i, rst_ni,
    input tag_t push_tag_i, input payload_t push_data_i,
    input logic push_req_i, output logic push_gnt_o,
    input payload_t [N_MATCH-1:0] match_data_i, match_mask_i,
    input logic [N_MATCH-1:0] match_req_i,
    output logic [N_MATCH-1:0] match_hit_o, match_gnt_o,
    input tag_t pop_tag_i, input logic pop_en_i, pop_req_i,
    output payload_t pop_data_o, output logic pop_data_valid_o, pop_gnt_o,
    output logic full_o, empty_o
);
    logic pop_req_d;
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) pop_req_d <= 1'b0;
        else         pop_req_d <= pop_req_i;
    end

    tag_tracker #(.TAG_W(TAG_W), .SLOTS(SLOTS), .FULL_RATE(FULL_RATE),
                  .CUT_POP_PATH(CUT_POP_PATH), .N_MATCH(N_MATCH),
                  .payload_t(payload_t)) u_golden (
        .clk_i, .rst_ni, .push_tag_i, .push_data_i, .push_req_i, .push_gnt_o,
        .match_data_i, .match_mask_i, .match_req_i, .match_hit_o, .match_gnt_o,
        .pop_tag_i, .pop_en_i, .pop_req_i(pop_req_d),
        .pop_data_o, .pop_data_valid_o, .pop_gnt_o, .full_o, .empty_o);
endmodule
