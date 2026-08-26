// ca05_elab_probe.sv -- d_ca05 STEP 0, PROBE 1: ELABORATION WITH TYPES BOUND.
//
// This is the step DESIGN_TASK_LANDSCAPE.md names as outstanding:
//
//   "The remaining errors are in axi_adapter.sv and are the unbound parameter
//    type class ... I have NOT YET BUILT THE PROBE that proves it with types
//    bound, which is the one step outstanding; on the evidence it is very
//    likely clean, and THAT IS A PREDICTION RATHER THAN A RESULT."
//
// Nothing here is invented. The parameter binding is copied from the real
// parent, refs/cva6/core/cache_subsystem/std_nbdcache.sv:156, and the two
// localparam types are copied from std_nbdcache.sv:51 and :57, where they are
// declared -- they are NOT in std_cache_pkg, which is why binding them is the
// question. CVA6Cfg comes from build_config_pkg::build_config() fed the real
// cv64a6_imafdc_sv39 user config, not from cva6_cfg_empty, whose zero-valued
// DCACHE fields would make the widths degenerate and prove nothing.

`include "axi/typedef.svh"

module ca05_elab_probe
  import ariane_pkg::*;
  import std_cache_pkg::*;
#(
    parameter int unsigned NR_PORTS = 4
) (
    input  logic clk_i,
    input  logic rst_ni,
    input  logic flush_i,
    output logic flush_ack_o,
    output logic miss_o,
    input  logic busy_i
);

  // The configuration, built the way the design is actually built.
  localparam config_pkg::cva6_cfg_t CVA6Cfg =
      build_config_pkg::build_config(cva6_config_pkg::cva6_cfg);

  // AXI types, from the vendored PULP typedef macros.
  typedef logic [63:0] axi_addr_t;
  typedef logic [ 3:0] axi_id_t;
  typedef logic [63:0] axi_data_t;
  typedef logic [ 7:0] axi_strb_t;
  typedef logic [ 0:0] axi_user_t;
  `AXI_TYPEDEF_ALL(cva6_axi, axi_addr_t, axi_id_t, axi_data_t, axi_strb_t, axi_user_t)

  // Copied verbatim from std_nbdcache.sv:51 and :57.
  localparam type cache_line_t = struct packed {
    logic [CVA6Cfg.DCACHE_TAG_WIDTH-1:0]  tag;
    logic [CVA6Cfg.DCACHE_LINE_WIDTH-1:0] data;
    logic                                 valid;
    logic                                 dirty;
  };
  localparam type cl_be_t = struct packed {
    logic [(CVA6Cfg.DCACHE_TAG_WIDTH+7)/8-1:0]  tag;
    logic [(CVA6Cfg.DCACHE_LINE_WIDTH+7)/8-1:0] data;
    logic [CVA6Cfg.DCACHE_SET_ASSOC-1:0]        vldrty;
  };

  logic [NR_PORTS-1:0][$bits(miss_req_t)-1:0] miss_req_i;
  logic [NR_PORTS-1:0]       bypass_gnt_o, bypass_valid_o;
  logic [NR_PORTS-1:0][63:0] bypass_data_o;
  cva6_axi_req_t             axi_bypass_o, axi_data_o;
  cva6_axi_resp_t            axi_bypass_i, axi_data_i;
  logic [NR_PORTS-1:0]       miss_gnt_o, active_serving_o;
  logic [63:0]               critical_word_o;
  logic                      critical_word_valid_o;
  logic [NR_PORTS-1:0][55:0] mshr_addr_i;
  logic [NR_PORTS-1:0]       mshr_addr_matches_o, mshr_index_matches_o;
  amo_req_t                  amo_req_i;
  amo_resp_t                 amo_resp_o;
  logic [CVA6Cfg.DCACHE_SET_ASSOC-1:0]   req_o;
  logic [CVA6Cfg.DCACHE_INDEX_WIDTH-1:0] addr_o;
  cache_line_t                           data_o;
  cl_be_t                                be_o;
  cache_line_t [CVA6Cfg.DCACHE_SET_ASSOC-1:0] data_i;
  logic                                  we_o;

  miss_handler #(
      .CVA6Cfg     (CVA6Cfg),
      .NR_PORTS    (NR_PORTS),
      .axi_req_t   (cva6_axi_req_t),
      .axi_rsp_t   (cva6_axi_resp_t),
      .cache_line_t(cache_line_t),
      .cl_be_t     (cl_be_t)
  ) dut (
      .clk_i, .rst_ni, .flush_i, .flush_ack_o, .miss_o, .busy_i,
      .miss_req_i, .bypass_gnt_o, .bypass_valid_o, .bypass_data_o,
      .axi_bypass_o, .axi_bypass_i,
      .miss_gnt_o, .active_serving_o,
      .critical_word_o, .critical_word_valid_o,
      .axi_data_o, .axi_data_i,
      .mshr_addr_i, .mshr_addr_matches_o, .mshr_index_matches_o,
      .amo_req_i, .amo_resp_o,
      .req_o, .addr_o, .data_o, .be_o, .data_i, .we_o
  );

endmodule
