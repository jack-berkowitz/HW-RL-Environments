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

module lead_zero_ctr #(
  
  parameter int unsigned WIDTH = 2,
  
  parameter bit          MODE  = 1'b0,

  
  parameter int unsigned CNT_WIDTH = math_utils_pkg::idx_width(WIDTH)
) (
  
  input  logic [WIDTH-1:0]     in_i,
  
  output logic [CNT_WIDTH-1:0] cnt_o,
  
  output logic                 empty_o
);

  if (WIDTH <= 1) begin : gen_degenerate_lzc

    assign cnt_o[0] = !in_i[0];
    assign empty_o = !in_i[0];

  end else begin : gen_lzc

    localparam int unsigned NumLevels = $clog2(WIDTH);

    logic [WIDTH-1:0][NumLevels-1:0] index_lut;
    logic [2**NumLevels-1:0] sel_nodes                  ;
    logic [2**NumLevels-1:0][NumLevels-1:0] index_nodes ;

    logic [WIDTH-1:0] in_tmp;

    if (MODE) begin : g_flip
      
      always_comb begin : flip_vector
        for (int unsigned i = 0; i < WIDTH; i++) begin
          in_tmp[i] = in_i[WIDTH-1-i];
        end
      end
    end else begin : g_no_flip
      
      assign in_tmp = in_i;
    end

    for (genvar j = 0; unsigned'(j) < WIDTH; j++) begin : g_index_lut
      assign index_lut[j] = (NumLevels)'(unsigned'(j));
    end

    for (genvar level = 0; unsigned'(level) < NumLevels; level++) begin : g_levels
      if (unsigned'(level) == NumLevels - 1) begin : g_last_level
        for (genvar k = 0; k < 2 ** level; k++) begin : g_level
          
          if (unsigned'(k) * 2 < WIDTH - 1) begin : g_reduce
            assign sel_nodes[2 ** level - 1 + k] = in_tmp[k * 2] | in_tmp[k * 2 + 1];
            assign index_nodes[2 ** level - 1 + k] = (in_tmp[k * 2] == 1'b1)
              ? index_lut[k * 2] :
                index_lut[k * 2 + 1];
          end
          
          if (unsigned'(k) * 2 == WIDTH - 1) begin : g_base
            assign sel_nodes[2 ** level - 1 + k] = in_tmp[k * 2];
            assign index_nodes[2 ** level - 1 + k] = index_lut[k * 2];
          end
          
          if (unsigned'(k) * 2 > WIDTH - 1) begin : g_out_of_range
            assign sel_nodes[2 ** level - 1 + k] = 1'b0;
            assign index_nodes[2 ** level - 1 + k] = '0;
          end
        end
      end else begin : g_not_last_level
        for (genvar l = 0; l < 2 ** level; l++) begin : g_level
          assign sel_nodes[2 ** level - 1 + l] =
              sel_nodes[2 ** (level + 1) - 1 + l * 2] | sel_nodes[2 ** (level + 1) - 1 + l * 2 + 1];
          assign index_nodes[2 ** level - 1 + l] = (sel_nodes[2 ** (level + 1) - 1 + l * 2] == 1'b1)
            ? index_nodes[2 ** (level + 1) - 1 + l * 2] :
              index_nodes[2 ** (level + 1) - 1 + l * 2 + 1];
        end
      end
    end

    assign cnt_o = NumLevels > unsigned'(0) ? index_nodes[0] : {($clog2(WIDTH)) {1'b0}};
    assign empty_o = NumLevels > unsigned'(0) ? ~sel_nodes[0] : ~(|in_i);

  end : gen_lzc

endmodule : lead_zero_ctr
