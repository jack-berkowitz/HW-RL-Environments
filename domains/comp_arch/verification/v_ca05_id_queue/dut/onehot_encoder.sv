// =============================================================================
// THIRD-PARTY NOTICES
// =============================================================================
// This file is a derivative work of one of the open-source hardware projects
// listed below, and is distributed under the terms of that project's licence.
// It has been modified: identifiers, formatting and commentary differ from the
// original.
//
// These notices are retained as those licences require. They are listed for the
// whole vendored corpus rather than per file.
//
//   bespoke-silicon-group/basejump_stl   SHL-0.51
//   pulp-platform/common_cells           SHL-0.51
//   pulp-platform/axi                    SHL-0.51
//   pulp-platform/cvfpu                  SHL-0.51
//   pulp-platform/fpu_div_sqrt_mvp       SHL-0.51
//   pulp-platform/hwpe-stream            SHL-0.51
//   pulp-platform/ne16                   SHL-0.51
//   pulp-platform/redmule                SHL-0.51
//   pulp-platform/idma                   SHL-0.51
//   pulp-platform/hwpe-ctrl              SHL-0.51
//   pulp-platform/hci                    SHL-0.51
//   pulp-platform/tech_cells_generic     SHL-0.51
//   nvdla/hw                             NVIDIA
//   alexforencich/verilog-axis           MIT
//   alexforencich/verilog-ethernet       MIT
//   openhwgroup/cva6                     SHL-0.51
//
// Copyright is held by the respective projects and their contributors,
// including ETH Zurich, the University of Bologna, the University of
// Washington / Bespoke Silicon Group, Alex Forencich, NVIDIA Corporation and
// the OpenHW Group, among others named in those repositories.
//
// Licence texts: http://solderpad.org/licenses/SHL-0.51 ,
// https://www.apache.org/licenses/LICENSE-2.0 , and the MIT, BSD and ISC texts
// as published by their stewards.
// =============================================================================
`timescale 1ns/1ps

module onehot_encoder #(
    parameter int unsigned ONEHOT_WIDTH = 16,
    
    parameter int unsigned BIN_WIDTH    = ONEHOT_WIDTH == 1 ? 1 : $clog2(ONEHOT_WIDTH)
)   (
    input  logic [ONEHOT_WIDTH-1:0] onehot,
    output logic [BIN_WIDTH-1:0]    bin
);

    for (genvar j = 0; j < BIN_WIDTH; j++) begin : gen_jl
        logic [ONEHOT_WIDTH-1:0] tmp_mask;
            for (genvar i = 0; i < ONEHOT_WIDTH; i++) begin : gen_il
                logic [BIN_WIDTH-1:0] tmp_i;
                assign tmp_i = BIN_WIDTH'(i);
                assign tmp_mask[i] = tmp_i[j];
            end
        assign bin[j] = |(tmp_mask & onehot);
    end

endmodule
