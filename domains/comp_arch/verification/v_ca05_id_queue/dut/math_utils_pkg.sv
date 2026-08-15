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

package math_utils_pkg;

    
    
    function automatic integer ceil_div (input longint dividend, input longint divisor);
        automatic longint remainder;

        `ifndef SYNTHESIS
        
        `endif

        remainder = dividend;
        for (ceil_div = 0; remainder > 0; ceil_div++) begin
            remainder = remainder - divisor;
        end
    endfunction

    

    

    
    
    function automatic integer unsigned idx_width (input integer unsigned num_idx);
        return (num_idx > 32'd1) ? unsigned'($clog2(num_idx)) : 32'd1;
    endfunction

    
    function automatic bit is_power_of_2 (input integer unsigned value);
        return (value != 0) && (value & (value - 1)) == 0;
    endfunction

endpackage
