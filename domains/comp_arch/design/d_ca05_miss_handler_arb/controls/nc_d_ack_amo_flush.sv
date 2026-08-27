// nc_d_ack_amo_flush -- NEGATIVE CONTROL for d_ca05. NOT a submission.
//
// THE ONE CHANGE: flush_ack_o pulses whenever the flush walk completes, including the walk an atomic forces (F7, F8).
//
// EXPECTED: fails T5 on BOTH the AMO-induced flush and the flush+amo corner, and passes the genuine flush. This is the obvious implementation.
//
// The vendored anchor is NOT edited -- it cannot be. This control instantiates
// the same miss_handler the reference does and perturbs ONE output on the way
// out, so the defect is isolated by construction.
// =============================================================================
// d_ca05 -- miss_handler_arb REFERENCE.
//
// THIS SHIM CONTAINS NO BEHAVIOUR. It binds parameters and casts two structs.
// Every decision the contract grades -- the arbitration order, the AMO/flush
// interaction, the flush walk, the MSHR matching -- is made by the VENDORED
// CVA6 miss_handler, unmodified, at
//
//     refs/cva6/core/cache_subsystem/miss_handler.sv
//
// That is the point: d_ca05's oracle is real RTL nobody here wrote, and it stays
// that way only if the shim stays empty. An earlier boundary would have exposed
// a simple request/grant memory port instead of AXI, which reads better for a
// submitter -- but it needs an AXI-to-simple adapter of about eighty lines, and
// those eighty lines would be MY behaviour sitting inside the scored reference.
// AXI stays at the boundary so the shim can stay empty.
//
// The types come from spec/miss_handler_arb_pkg.sv. They bind DIRECTLY: CVA6's
// axi_adapter takes axi_req_t/axi_rsp_t as PARAMETER types and reaches into them
// by field name, and the package's fields carry those names, so no AXI
// conversion happens anywhere in this file.
// =============================================================================

module miss_handler_arb
  import miss_handler_arb_pkg::*;
#(
    parameter int unsigned NR_PORTS = 4
) (
    input  logic clk,
    input  logic rst_n,

    // ---- flush ---------------------------------------------------------------
    input  logic flush_i,
    output logic flush_ack_o,
    output logic miss_o,
    input  logic busy_i,

    // ---- requesters ----------------------------------------------------------
    input  logic [NR_PORTS-1:0][$bits(miss_req_t)-1:0] miss_req_i,
    output logic [NR_PORTS-1:0]       bypass_gnt_o,
    output logic [NR_PORTS-1:0]       bypass_valid_o,
    output logic [NR_PORTS-1:0][63:0] bypass_data_o,
    output logic [NR_PORTS-1:0]       miss_gnt_o,
    output logic [NR_PORTS-1:0]       active_serving_o,
    output logic [63:0]               critical_word_o,
    output logic                      critical_word_valid_o,
    input  logic [NR_PORTS-1:0][55:0] mshr_addr_i,
    output logic [NR_PORTS-1:0]       mshr_addr_matches_o,
    output logic [NR_PORTS-1:0]       mshr_index_matches_o,

    // ---- atomics -------------------------------------------------------------
    input  amo_req_t  amo_req_i,
    output amo_resp_t amo_resp_o,

    // ---- AXI: bypass (single accesses and atomics) ---------------------------
    output axi_req_t axi_bypass_req_o,
    input  axi_rsp_t axi_bypass_rsp_i,

    // ---- AXI: refill (cacheline reads and evictions) -------------------------
    output axi_req_t axi_data_req_o,
    input  axi_rsp_t axi_data_rsp_i,

    // ---- the cache array -----------------------------------------------------
    output logic [SET_ASSOC-1:0]    req_o,
    output logic [INDEX_WIDTH-1:0]  addr_o,
    output cache_line_t             data_o,
    output cl_be_t                  be_o,
    input  cache_line_t [SET_ASSOC-1:0] data_i,
    output logic                    we_o
);

  // The configuration the anchor was measured under. cv64a6_imafdc_sv39, not
  // cva6_cfg_empty: the empty config's zero DCACHE fields make every width
  // degenerate. The package's concrete numbers were read out of this.
  localparam config_pkg::cva6_cfg_t CVA6Cfg =
      build_config_pkg::build_config(cva6_config_pkg::cva6_cfg);

  // The only conversion in this file. ariane_pkg's amo structs are bit-identical
  // to the package's -- 135 and 65 bits -- so this is a reinterpretation and not
  // a translation. It exists because miss_handler takes those two by TYPE rather
  // than as packed bits, unlike miss_req_i.
  ariane_pkg::amo_req_t  amo_req_cva6;
  ariane_pkg::amo_resp_t amo_resp_cva6;
  always_comb amo_req_cva6 = ariane_pkg::amo_req_t'(amo_req_i);
  always_comb amo_resp_o   = amo_resp_t'(amo_resp_cva6);

  logic ack_raw;
  // "acknowledge when the walk finishes" -- which is right for a requested flush
  // and wrong for the two cases where nobody requested one.
  logic amo_seen_q;
  always_ff @(posedge clk or negedge rst_n)
    if (!rst_n) amo_seen_q <= 1'b0;
    else if (amo_req_i.req) amo_seen_q <= 1'b1;
    else if (ack_raw)       amo_seen_q <= 1'b0;
  assign flush_ack_o = ack_raw | (amo_seen_q & amo_resp_o.ack);

  miss_handler #(
      .CVA6Cfg     (CVA6Cfg),
      .NR_PORTS    (NR_PORTS),
      .axi_req_t   (axi_req_t),
      .axi_rsp_t   (axi_rsp_t),
      .cache_line_t(cache_line_t),
      .cl_be_t     (cl_be_t)
  ) i_miss_handler (
      .clk_i                (clk),
      .rst_ni               (rst_n),
      .flush_i              (flush_i),
      .flush_ack_o(ack_raw),
      .miss_o               (miss_o),
      .busy_i               (busy_i),
      .miss_req_i           (miss_req_i),
      .bypass_gnt_o         (bypass_gnt_o),
      .bypass_valid_o       (bypass_valid_o),
      .bypass_data_o        (bypass_data_o),
      .axi_bypass_o         (axi_bypass_req_o),
      .axi_bypass_i         (axi_bypass_rsp_i),
      .miss_gnt_o           (miss_gnt_o),
      .active_serving_o     (active_serving_o),
      .critical_word_o      (critical_word_o),
      .critical_word_valid_o(critical_word_valid_o),
      .axi_data_o           (axi_data_req_o),
      .axi_data_i           (axi_data_rsp_i),
      .mshr_addr_i          (mshr_addr_i),
      .mshr_addr_matches_o  (mshr_addr_matches_o),
      .mshr_index_matches_o (mshr_index_matches_o),
      .amo_req_i            (amo_req_cva6),
      .amo_resp_o           (amo_resp_cva6),
      .req_o                (req_o),
      .addr_o               (addr_o),
      .data_o               (data_o),
      .be_o                 (be_o),
      .data_i               (data_i),
      .we_o                 (we_o)
  );

endmodule
