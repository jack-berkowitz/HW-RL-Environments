// PORT MAP ONLY -- no implementation is shipped.
module fp_noncomp (
    input  logic        clk_i,
    input  logic        rst_ni,

    input  logic [31:0] operand_a_i,
    input  logic [31:0] operand_b_i,
    input  logic [1:0]  op_i,
    input  logic [2:0]  op_mode_i,

    input  logic        in_valid_i,
    output logic        in_ready_o,

    output logic [31:0] result_o,
    output logic [9:0]  class_mask_o,
    output logic [4:0]  status_o,

    output logic        out_valid_o,
    input  logic        out_ready_i
);
endmodule
