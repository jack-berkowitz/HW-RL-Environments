// ============================================================================
// nc_f6_amo_skips_flush -- d_ca05 NEGATIVE CONTROL for F6. Never shipped.
// ============================================================================
// F6 says an atomic FORCES A FULL FLUSH BEFORE IT IS SERVED: amo_req_i.req with
// busy_i low sends the unit into the flush walk of F4 first, and only when the
// cache is clean is the atomic issued.
//
// This performs the atomic without paying for the walk ON THE ARRAY PORT. The
// inner unit still runs its flush, so its own idea of the cache state and every
// downstream behaviour are unchanged -- but `req_o` is held low for the
// duration, so nothing is observable where F4 says a flush's cost is paid.
//
// IT IS THE DESIGN F4's RATIONALE NAMES: "a task that scored only the end state
// would let a submission invent a broadcast invalidate the hardware does not
// have." This is that submission, written out.
//
// WHY IT PASSED BEFORE. The only check on the AMO-induced flush was
// expect_eq("T5 amo-induced flush acks", acks - a0, 0), and ZERO IS THE
// CONFORMING ANSWER -- F7 requires no acknowledgement. It is also the answer a
// design that never flushed gives. An in-range failure value, which needs a
// second channel rather than more care; the array port is that channel.
//
// The array interface has NO GRANT -- it is a fire-and-forget SRAM port with
// combinational read data -- so suppressing req_o costs the inner unit nothing.
// That is exactly what makes the violation free to a submission and invisible
// without a count.
//
// PREDICTION: SHOULD FAIL naming F6, with 0 array requests against a floor of
// one full walk (512 requests, 256 writes). If it passes, the check does not
// observe the array port during the AMO sequence and F6 is still unenforced.
//
// POLARITY: NO CROSSOVER. The suppression is unconditional within the window.
// ============================================================================
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

module miss_handler_arb_f6_inner
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
      .flush_ack_o          (flush_ack_o),
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


// ---------------------------------------------------------------------------
// The wrapper: reference behaviour, F6's cost never paid on the array port.
// ---------------------------------------------------------------------------
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
    logic [SET_ASSOC-1:0] inner_req;
    logic                 amo_window;

    // The window is F6'S OWN ANTECEDENT, verbatim: "amo_req_i.req asserted with
    // busy_i low". Gating on anything broader is not this violation -- a first
    // attempt opened on amo_req_i.req alone, which also suppressed the REFILL
    // traffic of T6's deferred-atomic case and made the control fail F6 and T6
    // together. A control that fails for two reasons is weaker evidence about
    // either, so the window matches the clause it violates and nothing more.
    // A genuine flush (flush_i high) is untouched, so T4's walk stays fully
    // observable.
    //
    // SUPPRESSING BY WINDOW ALONE DOES NOT WORK, and the reason is worth
    // recording. F6's antecedent is also satisfied in F9's case -- a miss raised
    // in the same cycle as the atomic -- where the miss DEFERS the atomic and no
    // AMO-induced flush happens. Gating all of req_o on the window blocked the
    // array traffic the miss needs to BECOME a refill, so the control failed F6
    // and T6 together; and yielding on the refill could not work either, because
    // the refill can never be issued once its own array access is suppressed.
    // Discriminating by the WRITE SIGNATURE instead of by the window is what
    // separates them. A control that fails for two reasons is weaker evidence
    // about either.
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)                          amo_window <= 1'b0;
        else if (amo_req_i.req && !flush_i) amo_window <= 1'b1;
        else if (amo_resp_o.ack)            amo_window <= 1'b0;
    end

    // THE PERTURBATION. Suppress only the FLUSH WRITES -- the ones F4 identifies
    // by their signature, "asserting be_o.vldrty for ALL SET_ASSOC = 8 ways".
    // A refill's array write does not look like that, so miss handling is
    // untouched and only the walk's cost disappears from the port.
    assign req_o = (amo_window && we_o && (&be_o.vldrty)) ? '0 : inner_req;

    miss_handler_arb_f6_inner #(.NR_PORTS(NR_PORTS)) u_inner (
        .clk(clk),
        .rst_n(rst_n),
        .flush_i(flush_i),
        .flush_ack_o(flush_ack_o),
        .miss_o(miss_o),
        .busy_i(busy_i),
        .miss_req_i(miss_req_i),
        .bypass_gnt_o(bypass_gnt_o),
        .bypass_valid_o(bypass_valid_o),
        .bypass_data_o(bypass_data_o),
        .miss_gnt_o(miss_gnt_o),
        .active_serving_o(active_serving_o),
        .critical_word_o(critical_word_o),
        .critical_word_valid_o(critical_word_valid_o),
        .mshr_addr_i(mshr_addr_i),
        .mshr_addr_matches_o(mshr_addr_matches_o),
        .mshr_index_matches_o(mshr_index_matches_o),
        .amo_req_i(amo_req_i),
        .amo_resp_o(amo_resp_o),
        .axi_bypass_req_o(axi_bypass_req_o),
        .axi_bypass_rsp_i(axi_bypass_rsp_i),
        .axi_data_req_o(axi_data_req_o),
        .axi_data_rsp_i(axi_data_rsp_i),
        .req_o(inner_req),
        .addr_o(addr_o),
        .data_o(data_o),
        .be_o(be_o),
        .data_i(data_i),
        .we_o(we_o)
    );
endmodule
