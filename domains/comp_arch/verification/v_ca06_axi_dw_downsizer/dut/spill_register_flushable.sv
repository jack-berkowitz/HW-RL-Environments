// Copyright 2021 ETH Zurich and University of Bologna.
//
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License. You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.
//
// Fabian Schuiki <fschuiki@iis.ee.ethz.ch>

// ---- INLINED common_cells/assertions.svh (harness passes no -I; see task.yaml) ----
// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

// Macros and helper code for using assertions.
//  - Provides default clk and rst options to simplify code
//  - Provides boiler plate template for common assertions

`ifndef COMMON_CELLS_ASSERTIONS_SVH
`define COMMON_CELLS_ASSERTIONS_SVH

`ifdef UVM
  // report assertion error with UVM if compiled
  package assert_rpt_pkg;
    import uvm_pkg::*;
    `include "uvm_macros.svh"
    function void assert_rpt(string msg);
      `uvm_error("ASSERT FAILED", msg)
    endfunction
  endpackage
`endif

///////////////////
// Helper macros //
///////////////////

// helper macro to reduce code clutter, can be used to hide signal defs only used for assertions
`ifndef ASSERTS_OFF
`ifndef SYNTHESIS
`ifndef XSIM
`define INC_ASSERT
`endif
`endif   
`endif
// forcefully enable assertions with ASSERTS_OVERRIDE_ON, overriding any define that turns them off
`ifdef ASSERTS_OVERRIDE_ON
`ifndef INC_ASSERT
`define INC_ASSERT
`endif
`endif

// Converts an arbitrary block of code into a Verilog string
`define ASSERT_STRINGIFY(__x) `"__x`"

// ASSERT_RPT is available to change the reporting mechanism when an assert fails
`ifndef ASSERT_RPT
`define ASSERT_RPT(__name, __desc = "")                                                 \
`ifdef UVM                                                                              \
  assert_rpt_pkg::assert_rpt($sformatf("[%m] %s: %s (%s:%0d)",                          \
                             __name, __desc, `__FILE__, `__LINE__));                    \
`else                                                                                   \
  $error("[ASSERT FAILED] [%m] %s: %s (%s:%0d)", __name, __desc, `__FILE__, `__LINE__); \
`endif
`endif

///////////////////////////////////////
// Simple assertion and cover macros //
///////////////////////////////////////

// Default clk and reset signals used by assertion macros below.
`define ASSERT_DEFAULT_CLK clk_i
`define ASSERT_DEFAULT_RST !rst_ni

// Immediate assertion
// Note that immediate assertions are sensitive to simulation glitches.
`define ASSERT_I(__name, __prop, __desc = "")        \
`ifdef INC_ASSERT                                    \
  __name: assert (__prop)                            \
    else begin                                       \
      `ASSERT_RPT(`ASSERT_STRINGIFY(__name), __desc) \
    end                                              \
`endif

// Assertion in initial block. Can be used for things like parameter checking.
`define ASSERT_INIT(__name, __prop, __desc = "")       \
`ifdef INC_ASSERT                                      \
  initial begin                                        \
    __name: assert (__prop)                            \
      else begin                                       \
        `ASSERT_RPT(`ASSERT_STRINGIFY(__name), __desc) \
      end                                              \
  end                                                  \
`endif

// Assertion in final block. Can be used for things like queues being empty
// at end of sim, all credits returned at end of sim, state machines in idle
// at end of sim.
`define ASSERT_FINAL(__name, __prop, __desc = "")                            \
`ifdef INC_ASSERT                                                            \
  final begin                                                                \
    __name: assert (__prop || $test$plusargs("disable_assert_final_checks")) \
      else begin                                                             \
        `ASSERT_RPT(`ASSERT_STRINGIFY(__name), __desc)                       \
      end                                                                    \
  end                                                                        \
`endif

// Assert a concurrent property directly.
// It can be called as a module (or interface) body item.
`define ASSERT(__name, __prop, __clk = `ASSERT_DEFAULT_CLK, __rst = `ASSERT_DEFAULT_RST, __desc = "") \
`ifdef INC_ASSERT                                                                                     \
  __name: assert property (@(posedge __clk) disable iff ((__rst) !== '0) (__prop))                    \
    else begin                                                                                        \
      `ASSERT_RPT(`ASSERT_STRINGIFY(__name), __desc)                                                  \
    end                                                                                               \
`endif
// Note: Above we use (__rst !== '0) in the disable iff statements instead of
// (__rst == '1).  This properly disables the assertion in cases when reset is X at
// the beginning of a simulation. For that case, (reset == '1) does not disable the
// assertion.

// Assert a concurrent property NEVER happens
`define ASSERT_NEVER(__name, __prop, __clk = `ASSERT_DEFAULT_CLK, __rst = `ASSERT_DEFAULT_RST, __desc = "") \
`ifdef INC_ASSERT                                                                                           \
  __name: assert property (@(posedge __clk) disable iff ((__rst) !== '0) not (__prop))                      \
    else begin                                                                                              \
      `ASSERT_RPT(`ASSERT_STRINGIFY(__name), __desc)                                                        \
    end                                                                                                     \
`endif

// Assert that signal has a known value (each bit is either '0' or '1') after reset.
// It can be called as a module (or interface) body item.
`define ASSERT_KNOWN(__name, __sig, __clk = `ASSERT_DEFAULT_CLK, __rst = `ASSERT_DEFAULT_RST, __desc = "") \
`ifdef INC_ASSERT                                                                                          \
  `ASSERT(__name, !$isunknown(__sig), __clk, __rst, __desc)                                                \
`endif

//  Cover a concurrent property
`define COVER(__name, __prop, __clk = `ASSERT_DEFAULT_CLK, __rst = `ASSERT_DEFAULT_RST) \
`ifdef INC_ASSERT                                                                       \
  __name: cover property (@(posedge __clk) disable iff ((__rst) !== '0) (__prop));      \
`endif

//////////////////////////////
// Complex assertion macros //
//////////////////////////////

// Assert that signal is an active-high pulse with pulse length of 1 clock cycle
`define ASSERT_PULSE(__name, __sig, __clk = `ASSERT_DEFAULT_CLK, __rst = `ASSERT_DEFAULT_RST, __desc = "") \
`ifdef INC_ASSERT                                                                                          \
  `ASSERT(__name, $rose(__sig) |=> !(__sig), __clk, __rst, __desc)                                         \
`endif

// Assert that a property is true only when an enable signal is set.  It can be called as a module
// (or interface) body item.
`define ASSERT_IF(__name, __prop, __enable, __clk = `ASSERT_DEFAULT_CLK, __rst = `ASSERT_DEFAULT_RST, __desc = "") \
`ifdef INC_ASSERT                                                                                                  \
  `ASSERT(__name, (__enable) |-> (__prop), __clk, __rst, __desc)                                                   \
`endif

// Assert that signal has a known value (each bit is either '0' or '1') after reset if enable is
// set.  It can be called as a module (or interface) body item.
`define ASSERT_KNOWN_IF(__name, __sig, __enable, __clk = `ASSERT_DEFAULT_CLK, __rst = `ASSERT_DEFAULT_RST, __desc = "") \
`ifdef INC_ASSERT                                                                                                       \
  `ASSERT_KNOWN(__name``KnownEnable, __enable, __clk, __rst, __desc)                                                    \
  `ASSERT_IF(__name, !$isunknown(__sig), __enable, __clk, __rst, __desc)                                                \
`endif

// Assert that (unmasked parts of) data are stable when valid is high and ready is low.
`define ASSERT_STABLE(__name, __valid, __ready, __data, __mask = '0, __clk = `ASSERT_DEFAULT_CLK, __rst = `ASSERT_DEFAULT_RST, __desc = "") \
`ifdef INC_ASSERT                                                                                                                           \
  `ASSERT(__name, (__valid) && !(__ready) |=> $stable((__data) & ~(__mask)), __clk, __rst, __desc)                                          \
`endif

///////////////////////
// Assumption macros //
///////////////////////

// Assume a concurrent property
`define ASSUME(__name, __prop, __clk = `ASSERT_DEFAULT_CLK, __rst = `ASSERT_DEFAULT_RST, __desc = "") \
`ifdef INC_ASSERT                                                                                     \
  __name: assume property (@(posedge __clk) disable iff ((__rst) !== '0) (__prop))                    \
    else begin                                                                                        \
      `ASSERT_RPT(`ASSERT_STRINGIFY(__name), __desc)                                                  \
    end                                                                                               \
`endif

// Assume an immediate property
`define ASSUME_I(__name, __prop, __desc = "")        \
`ifdef INC_ASSERT                                    \
  __name: assume (__prop)                            \
    else begin                                       \
      `ASSERT_RPT(`ASSERT_STRINGIFY(__name), __desc) \
    end                                              \
`endif

//////////////////////////////////
// For formal verification only //
//////////////////////////////////

// Note that the existing set of ASSERT macros specified above shall be used for FPV,
// thereby ensuring that the assertions are evaluated during DV simulations as well.

// ASSUME_FPV
// Assume a concurrent property during formal verification only.
`define ASSUME_FPV(__name, __prop, __clk = `ASSERT_DEFAULT_CLK, __rst = `ASSERT_DEFAULT_RST, __desc = "") \
`ifdef FPV_ON                                                                                             \
   `ASSUME(__name, __prop, __clk, __rst, __desc)                                                          \
`endif

// ASSUME_I_FPV
// Assume a concurrent property during formal verification only.
`define ASSUME_I_FPV(__name, __prop, __desc = "") \
`ifdef FPV_ON                                     \
   `ASSUME_I(__name, __prop, __desc)              \
`endif

// COVER_FPV
// Cover a concurrent property during formal verification
`define COVER_FPV(__name, __prop, __clk = `ASSERT_DEFAULT_CLK, __rst = `ASSERT_DEFAULT_RST) \
`ifdef FPV_ON                                                                               \
   `COVER(__name, __prop, __clk, __rst)                                                     \
`endif


`endif // COMMON_CELLS_ASSERTIONS_SVH
// ---- end inlined common_cells/assertions.svh ----

/// A register with handshakes that completely cuts any combinational paths
/// between the input and output. This spill register can be flushed.
module spill_register_flushable #(
  parameter type T           = logic,
  parameter bit  Bypass      = 1'b0   // make this spill register transparent
) (
  input  logic clk_i   ,
  input  logic rst_ni  ,
  input  logic valid_i ,
  input  logic flush_i ,
  output logic ready_o ,
  input  T     data_i  ,
  output logic valid_o ,
  input  logic ready_i ,
  output T     data_o
);

  if (Bypass) begin : gen_bypass
    assign valid_o = valid_i;
    assign ready_o = ready_i;
    assign data_o  = data_i;
  end else begin : gen_spill_reg
    // The A register.
    T a_data_q;
    logic a_full_q;
    logic a_fill, a_drain;

    always_ff @(posedge clk_i or negedge rst_ni) begin : ps_a_data
      if (!rst_ni)
        a_data_q <= T'('0);
      else if (a_fill)
        a_data_q <= data_i;
    end

    always_ff @(posedge clk_i or negedge rst_ni) begin : ps_a_full
      if (!rst_ni)
        a_full_q <= 0;
      else if (a_fill || a_drain)
        a_full_q <= a_fill;
    end

    // The B register.
    T b_data_q;
    logic b_full_q;
    logic b_fill, b_drain;

    always_ff @(posedge clk_i or negedge rst_ni) begin : ps_b_data
      if (!rst_ni)
        b_data_q <= T'('0);
      else if (b_fill)
        b_data_q <= a_data_q;
    end

    always_ff @(posedge clk_i or negedge rst_ni) begin : ps_b_full
      if (!rst_ni)
        b_full_q <= 0;
      else if (b_fill || b_drain)
        b_full_q <= b_fill;
    end

    // Fill the A register when the A or B register is empty. Drain the A register
    // whenever it is full and being filled, or if a flush is requested.
    assign a_fill = valid_i && ready_o && (!flush_i);
    assign a_drain = (a_full_q && !b_full_q) || flush_i;

    // Fill the B register whenever the A register is drained, but the downstream
    // circuit is not ready. Drain the B register whenever it is full and the
    // downstream circuit is ready, or if a flush is requested.
    assign b_fill = a_drain && (!ready_i) && (!flush_i);
    assign b_drain = (b_full_q && ready_i) || flush_i;

    // We can accept input as long as register B is not full.
    // Note: flush_i and valid_i must not be high at the same time,
    // otherwise an invalid handshake may occur
    assign ready_o = !a_full_q || !b_full_q;

    // The unit provides output as long as one of the registers is filled.
    assign valid_o = a_full_q | b_full_q;

    // We empty the spill register before the slice register.
    assign data_o = b_full_q ? b_data_q : a_data_q;

    `ifndef COMMON_CELLS_ASSERTS_OFF
    `ASSERT(flush_valid, flush_i |-> ~valid_i, clk_i, !rst_ni,
           "Trying to flush and feed the spill register simultaneously. You will lose data!")
   `endif
  end
endmodule
