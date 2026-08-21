// =============================================================================
// mutants.sv -- these MUST BE CAUGHT.
// =============================================================================
// Built in the FIRST pass, not retrofitted after a blind run. Every one sits
// exactly on a boundary between two states a clause names, which is the shape
// that produced the only mutants nothing has caught on earlier tasks.
//
// Each wraps the unmodified golden and gates the slave-side handshake. The
// valid into the golden and the ready out are gated TOGETHER, so no cycle
// exists in which one side believes a transaction was accepted and the other
// does not -- the injected defect is a stall that should not happen, or the
// absence of one that should.
//
// The occupancy tracker in each wrapper watches the SLAVE PORT HANDSHAKES ONLY.
// It never reads anything inside the golden, so a mutant cannot inherit the
// golden's own blind spots.
// =============================================================================

// ----------------------------------------------------------------------------
// iw_m1_table_one_too_small -- violates A3.
// BOUNDARY: the table stalls ONE ENTRY EARLY.
// A new identifier is refused once MAX_UNIQ_IDS-1 distinct ids are outstanding,
// where A3 requires it to be accepted. Correct at every other occupancy, so a
// testbench that fills the table and checks only that the NEXT one blocks sees
// nothing wrong -- it has to check the entry BELOW the boundary too.
// ----------------------------------------------------------------------------
module iw_m1_table_one_too_small #(
    parameter int unsigned SLV_ID_W        = 4,
    parameter int unsigned MST_ID_W        = 2,
    parameter int unsigned ADDR_W          = 32,
    parameter int unsigned DATA_W          = 32,
    parameter int unsigned MAX_UNIQ_IDS    = 4,
    parameter int unsigned MAX_TXNS_PER_ID = 2
) (
    input  logic clk_i,
    input  logic rst_ni,
    input  logic [SLV_ID_W-1:0]   s_awid,
    input  logic [ADDR_W-1:0]   s_awaddr,
    input  logic [7:0]          s_awlen,
    input  logic                s_awvalid,
    output logic                s_awready,
    input  logic [DATA_W-1:0]   s_wdata,
    input  logic [DATA_W/8-1:0] s_wstrb,
    input  logic                s_wlast,
    input  logic                s_wvalid,
    output logic                s_wready,
    output logic [SLV_ID_W-1:0]   s_bid,
    output logic [1:0]          s_bresp,
    output logic                s_bvalid,
    input  logic                s_bready,
    input  logic [SLV_ID_W-1:0]   s_arid,
    input  logic [ADDR_W-1:0]   s_araddr,
    input  logic [7:0]          s_arlen,
    input  logic                s_arvalid,
    output logic                s_arready,
    output logic [SLV_ID_W-1:0]   s_rid,
    output logic [DATA_W-1:0]   s_rdata,
    output logic [1:0]          s_rresp,
    output logic                s_rlast,
    output logic                s_rvalid,
    input  logic                s_rready,
    output logic [MST_ID_W-1:0]   m_awid,
    output logic [ADDR_W-1:0]   m_awaddr,
    output logic [7:0]          m_awlen,
    output logic                m_awvalid,
    input  logic                m_awready,
    output logic [DATA_W-1:0]   m_wdata,
    output logic [DATA_W/8-1:0] m_wstrb,
    output logic                m_wlast,
    output logic                m_wvalid,
    input  logic                m_wready,
    input  logic [MST_ID_W-1:0]   m_bid,
    input  logic [1:0]          m_bresp,
    input  logic                m_bvalid,
    output logic                m_bready,
    output logic [MST_ID_W-1:0]   m_arid,
    output logic [ADDR_W-1:0]   m_araddr,
    output logic [7:0]          m_arlen,
    output logic                m_arvalid,
    input  logic                m_arready,
    input  logic [MST_ID_W-1:0]   m_rid,
    input  logic [DATA_W-1:0]   m_rdata,
    input  logic [1:0]          m_rresp,
    input  logic                m_rlast,
    input  logic                m_rvalid,
    output logic                m_rready
);

  // Outstanding count per slave id, from the slave-port handshakes only.
  localparam int unsigned NID = 1 << SLV_ID_W;
  int unsigned rcnt [NID];
  int unsigned wcnt [NID];
  always_ff @(posedge clk_i) begin
    if (!rst_ni) begin
      for (int i = 0; i < NID; i++) begin rcnt[i] <= 0; wcnt[i] <= 0; end
    end else begin
      if (s_arvalid && s_arready)                 rcnt[s_arid] <= rcnt[s_arid] + 1;
      if (s_rvalid  && s_rready && s_rlast)       rcnt[s_rid]  <= rcnt[s_rid]  - 1;
      if (s_awvalid && s_awready)                 wcnt[s_awid] <= wcnt[s_awid] + 1;
      if (s_bvalid  && s_bready)                  wcnt[s_bid]  <= wcnt[s_bid]  - 1;
    end
  end
  function automatic int unsigned n_distinct_r();
    n_distinct_r = 0;
    for (int i = 0; i < NID; i++) if (rcnt[i] != 0) n_distinct_r++;
  endfunction
  function automatic int unsigned n_distinct_w();
    n_distinct_w = 0;
    for (int i = 0; i < NID; i++) if (wcnt[i] != 0) n_distinct_w++;
  endfunction

  wire g_arvalid = s_arvalid & ~((n_distinct_r() >= (MAX_UNIQ_IDS-1)) && (rcnt[s_arid] == 0));
  wire g_awvalid = s_awvalid & ~((n_distinct_w() >= (MAX_UNIQ_IDS-1)) && (wcnt[s_awid] == 0));
  wire g_arready, g_awready;
  assign s_arready = g_arready & ~((n_distinct_r() >= (MAX_UNIQ_IDS-1)) && (rcnt[s_arid] == 0));
  assign s_awready = g_awready & ~((n_distinct_w() >= (MAX_UNIQ_IDS-1)) && (wcnt[s_awid] == 0));

  id_width_conv #(
      .SLV_ID_W(SLV_ID_W), .MST_ID_W(MST_ID_W), .ADDR_W(ADDR_W), .DATA_W(DATA_W),
      .MAX_UNIQ_IDS(MAX_UNIQ_IDS), .MAX_TXNS_PER_ID(MAX_TXNS_PER_ID)
  ) i_g (
      .clk_i, .rst_ni,
      .s_awid, .s_awaddr, .s_awlen, .s_awvalid(g_awvalid), .s_awready(g_awready),
      .s_wdata, .s_wstrb, .s_wlast, .s_wvalid, .s_wready,
      .s_bid, .s_bresp, .s_bvalid, .s_bready,
      .s_arid, .s_araddr, .s_arlen, .s_arvalid(g_arvalid), .s_arready(g_arready),
      .s_rid, .s_rdata, .s_rresp, .s_rlast, .s_rvalid, .s_rready,
      .m_awid, .m_awaddr, .m_awlen, .m_awvalid, .m_awready,
      .m_wdata, .m_wstrb, .m_wlast, .m_wvalid, .m_wready,
      .m_bid, .m_bresp, .m_bvalid, .m_bready,
      .m_arid, .m_araddr, .m_arlen, .m_arvalid, .m_arready,
      .m_rid, .m_rdata, .m_rresp, .m_rlast, .m_rvalid, .m_rready
  );
endmodule

// ----------------------------------------------------------------------------
// iw_m2_depth_one_too_small -- violates A5.
// BOUNDARY: the per-identifier depth is ONE TOO SMALL.
// A second transaction with an identifier already outstanding is refused, where
// A5 permits MAX_TXNS_PER_ID of them. Every distinct identifier still works, so
// only a testbench that stacks transactions on ONE id reaches it.
// ----------------------------------------------------------------------------
module iw_m2_depth_one_too_small #(
    parameter int unsigned SLV_ID_W        = 4,
    parameter int unsigned MST_ID_W        = 2,
    parameter int unsigned ADDR_W          = 32,
    parameter int unsigned DATA_W          = 32,
    parameter int unsigned MAX_UNIQ_IDS    = 4,
    parameter int unsigned MAX_TXNS_PER_ID = 2
) (
    input  logic clk_i,
    input  logic rst_ni,
    input  logic [SLV_ID_W-1:0]   s_awid,
    input  logic [ADDR_W-1:0]   s_awaddr,
    input  logic [7:0]          s_awlen,
    input  logic                s_awvalid,
    output logic                s_awready,
    input  logic [DATA_W-1:0]   s_wdata,
    input  logic [DATA_W/8-1:0] s_wstrb,
    input  logic                s_wlast,
    input  logic                s_wvalid,
    output logic                s_wready,
    output logic [SLV_ID_W-1:0]   s_bid,
    output logic [1:0]          s_bresp,
    output logic                s_bvalid,
    input  logic                s_bready,
    input  logic [SLV_ID_W-1:0]   s_arid,
    input  logic [ADDR_W-1:0]   s_araddr,
    input  logic [7:0]          s_arlen,
    input  logic                s_arvalid,
    output logic                s_arready,
    output logic [SLV_ID_W-1:0]   s_rid,
    output logic [DATA_W-1:0]   s_rdata,
    output logic [1:0]          s_rresp,
    output logic                s_rlast,
    output logic                s_rvalid,
    input  logic                s_rready,
    output logic [MST_ID_W-1:0]   m_awid,
    output logic [ADDR_W-1:0]   m_awaddr,
    output logic [7:0]          m_awlen,
    output logic                m_awvalid,
    input  logic                m_awready,
    output logic [DATA_W-1:0]   m_wdata,
    output logic [DATA_W/8-1:0] m_wstrb,
    output logic                m_wlast,
    output logic                m_wvalid,
    input  logic                m_wready,
    input  logic [MST_ID_W-1:0]   m_bid,
    input  logic [1:0]          m_bresp,
    input  logic                m_bvalid,
    output logic                m_bready,
    output logic [MST_ID_W-1:0]   m_arid,
    output logic [ADDR_W-1:0]   m_araddr,
    output logic [7:0]          m_arlen,
    output logic                m_arvalid,
    input  logic                m_arready,
    input  logic [MST_ID_W-1:0]   m_rid,
    input  logic [DATA_W-1:0]   m_rdata,
    input  logic [1:0]          m_rresp,
    input  logic                m_rlast,
    input  logic                m_rvalid,
    output logic                m_rready
);

  // Outstanding count per slave id, from the slave-port handshakes only.
  localparam int unsigned NID = 1 << SLV_ID_W;
  int unsigned rcnt [NID];
  int unsigned wcnt [NID];
  always_ff @(posedge clk_i) begin
    if (!rst_ni) begin
      for (int i = 0; i < NID; i++) begin rcnt[i] <= 0; wcnt[i] <= 0; end
    end else begin
      if (s_arvalid && s_arready)                 rcnt[s_arid] <= rcnt[s_arid] + 1;
      if (s_rvalid  && s_rready && s_rlast)       rcnt[s_rid]  <= rcnt[s_rid]  - 1;
      if (s_awvalid && s_awready)                 wcnt[s_awid] <= wcnt[s_awid] + 1;
      if (s_bvalid  && s_bready)                  wcnt[s_bid]  <= wcnt[s_bid]  - 1;
    end
  end
  function automatic int unsigned n_distinct_r();
    n_distinct_r = 0;
    for (int i = 0; i < NID; i++) if (rcnt[i] != 0) n_distinct_r++;
  endfunction
  function automatic int unsigned n_distinct_w();
    n_distinct_w = 0;
    for (int i = 0; i < NID; i++) if (wcnt[i] != 0) n_distinct_w++;
  endfunction

  wire g_arvalid = s_arvalid & ~((rcnt[s_arid] >= (MAX_TXNS_PER_ID-1)) && (rcnt[s_arid] != 0));
  wire g_awvalid = s_awvalid & ~((wcnt[s_awid] >= (MAX_TXNS_PER_ID-1)) && (wcnt[s_awid] != 0));
  wire g_arready, g_awready;
  assign s_arready = g_arready & ~((rcnt[s_arid] >= (MAX_TXNS_PER_ID-1)) && (rcnt[s_arid] != 0));
  assign s_awready = g_awready & ~((wcnt[s_awid] >= (MAX_TXNS_PER_ID-1)) && (wcnt[s_awid] != 0));

  id_width_conv #(
      .SLV_ID_W(SLV_ID_W), .MST_ID_W(MST_ID_W), .ADDR_W(ADDR_W), .DATA_W(DATA_W),
      .MAX_UNIQ_IDS(MAX_UNIQ_IDS), .MAX_TXNS_PER_ID(MAX_TXNS_PER_ID)
  ) i_g (
      .clk_i, .rst_ni,
      .s_awid, .s_awaddr, .s_awlen, .s_awvalid(g_awvalid), .s_awready(g_awready),
      .s_wdata, .s_wstrb, .s_wlast, .s_wvalid, .s_wready,
      .s_bid, .s_bresp, .s_bvalid, .s_bready,
      .s_arid, .s_araddr, .s_arlen, .s_arvalid(g_arvalid), .s_arready(g_arready),
      .s_rid, .s_rdata, .s_rresp, .s_rlast, .s_rvalid, .s_rready,
      .m_awid, .m_awaddr, .m_awlen, .m_awvalid, .m_awready,
      .m_wdata, .m_wstrb, .m_wlast, .m_wvalid, .m_wready,
      .m_bid, .m_bresp, .m_bvalid, .m_bready,
      .m_arid, .m_araddr, .m_arlen, .m_arvalid, .m_arready,
      .m_rid, .m_rdata, .m_rresp, .m_rlast, .m_rvalid, .m_rready
  );
endmodule

// ----------------------------------------------------------------------------
// iw_m3_entry_freed_late -- violates A4.
// BOUNDARY: an entry is freed LATE.
// After the last transaction of an identifier completes, the table entry is held
// for three further cycles, so a new identifier offered in that window is
// refused. A4 says the entry is free on the completing edge. Invisible to any
// testbench that waits before issuing the next request.
// ----------------------------------------------------------------------------
module iw_m3_entry_freed_late #(
    parameter int unsigned SLV_ID_W        = 4,
    parameter int unsigned MST_ID_W        = 2,
    parameter int unsigned ADDR_W          = 32,
    parameter int unsigned DATA_W          = 32,
    parameter int unsigned MAX_UNIQ_IDS    = 4,
    parameter int unsigned MAX_TXNS_PER_ID = 2
) (
    input  logic clk_i,
    input  logic rst_ni,
    input  logic [SLV_ID_W-1:0]   s_awid,
    input  logic [ADDR_W-1:0]   s_awaddr,
    input  logic [7:0]          s_awlen,
    input  logic                s_awvalid,
    output logic                s_awready,
    input  logic [DATA_W-1:0]   s_wdata,
    input  logic [DATA_W/8-1:0] s_wstrb,
    input  logic                s_wlast,
    input  logic                s_wvalid,
    output logic                s_wready,
    output logic [SLV_ID_W-1:0]   s_bid,
    output logic [1:0]          s_bresp,
    output logic                s_bvalid,
    input  logic                s_bready,
    input  logic [SLV_ID_W-1:0]   s_arid,
    input  logic [ADDR_W-1:0]   s_araddr,
    input  logic [7:0]          s_arlen,
    input  logic                s_arvalid,
    output logic                s_arready,
    output logic [SLV_ID_W-1:0]   s_rid,
    output logic [DATA_W-1:0]   s_rdata,
    output logic [1:0]          s_rresp,
    output logic                s_rlast,
    output logic                s_rvalid,
    input  logic                s_rready,
    output logic [MST_ID_W-1:0]   m_awid,
    output logic [ADDR_W-1:0]   m_awaddr,
    output logic [7:0]          m_awlen,
    output logic                m_awvalid,
    input  logic                m_awready,
    output logic [DATA_W-1:0]   m_wdata,
    output logic [DATA_W/8-1:0] m_wstrb,
    output logic                m_wlast,
    output logic                m_wvalid,
    input  logic                m_wready,
    input  logic [MST_ID_W-1:0]   m_bid,
    input  logic [1:0]          m_bresp,
    input  logic                m_bvalid,
    output logic                m_bready,
    output logic [MST_ID_W-1:0]   m_arid,
    output logic [ADDR_W-1:0]   m_araddr,
    output logic [7:0]          m_arlen,
    output logic                m_arvalid,
    input  logic                m_arready,
    input  logic [MST_ID_W-1:0]   m_rid,
    input  logic [DATA_W-1:0]   m_rdata,
    input  logic [1:0]          m_rresp,
    input  logic                m_rlast,
    input  logic                m_rvalid,
    output logic                m_rready
);

  // Outstanding count per slave id, from the slave-port handshakes only.
  localparam int unsigned NID = 1 << SLV_ID_W;
  int unsigned rcnt [NID];
  int unsigned wcnt [NID];
  always_ff @(posedge clk_i) begin
    if (!rst_ni) begin
      for (int i = 0; i < NID; i++) begin rcnt[i] <= 0; wcnt[i] <= 0; end
    end else begin
      if (s_arvalid && s_arready)                 rcnt[s_arid] <= rcnt[s_arid] + 1;
      if (s_rvalid  && s_rready && s_rlast)       rcnt[s_rid]  <= rcnt[s_rid]  - 1;
      if (s_awvalid && s_awready)                 wcnt[s_awid] <= wcnt[s_awid] + 1;
      if (s_bvalid  && s_bready)                  wcnt[s_bid]  <= wcnt[s_bid]  - 1;
    end
  end
  function automatic int unsigned n_distinct_r();
    n_distinct_r = 0;
    for (int i = 0; i < NID; i++) if (rcnt[i] != 0) n_distinct_r++;
  endfunction
  function automatic int unsigned n_distinct_w();
    n_distinct_w = 0;
    for (int i = 0; i < NID; i++) if (wcnt[i] != 0) n_distinct_w++;
  endfunction

  // hold the entry for three cycles past completion
  logic [1:0] hold_r, hold_w;
  always_ff @(posedge clk_i) begin
    if (!rst_ni) begin hold_r <= 0; hold_w <= 0; end
    else begin
      if (s_rvalid && s_rready && s_rlast) hold_r <= 2'd3; else if (hold_r != 0) hold_r <= hold_r - 1;
      if (s_bvalid && s_bready)            hold_w <= 2'd3; else if (hold_w != 0) hold_w <= hold_w - 1;
    end
  end

  wire g_arvalid = s_arvalid & ~(hold_r != 0);
  wire g_awvalid = s_awvalid & ~(hold_w != 0);
  wire g_arready, g_awready;
  assign s_arready = g_arready & ~(hold_r != 0);
  assign s_awready = g_awready & ~(hold_w != 0);

  id_width_conv #(
      .SLV_ID_W(SLV_ID_W), .MST_ID_W(MST_ID_W), .ADDR_W(ADDR_W), .DATA_W(DATA_W),
      .MAX_UNIQ_IDS(MAX_UNIQ_IDS), .MAX_TXNS_PER_ID(MAX_TXNS_PER_ID)
  ) i_g (
      .clk_i, .rst_ni,
      .s_awid, .s_awaddr, .s_awlen, .s_awvalid(g_awvalid), .s_awready(g_awready),
      .s_wdata, .s_wstrb, .s_wlast, .s_wvalid, .s_wready,
      .s_bid, .s_bresp, .s_bvalid, .s_bready,
      .s_arid, .s_araddr, .s_arlen, .s_arvalid(g_arvalid), .s_arready(g_arready),
      .s_rid, .s_rdata, .s_rresp, .s_rlast, .s_rvalid, .s_rready,
      .m_awid, .m_awaddr, .m_awlen, .m_awvalid, .m_awready,
      .m_wdata, .m_wstrb, .m_wlast, .m_wvalid, .m_wready,
      .m_bid, .m_bresp, .m_bvalid, .m_bready,
      .m_arid, .m_araddr, .m_arlen, .m_arvalid, .m_arready,
      .m_rid, .m_rdata, .m_rresp, .m_rlast, .m_rvalid, .m_rready
  );
endmodule

// ----------------------------------------------------------------------------
// iw_m4_same_id_blocked_when_full -- violates A3.
// BOUNDARY: a full table also blocks an identifier it ALREADY holds.
// A3's second sentence says a request carrying an id already outstanding is not
// blocked by fullness. This one blocks it. The table size itself is correct and
// the stall for NEW ids is correct -- only the same-id case at exactly the full
// boundary is wrong.
// ----------------------------------------------------------------------------
module iw_m4_same_id_blocked_when_full #(
    parameter int unsigned SLV_ID_W        = 4,
    parameter int unsigned MST_ID_W        = 2,
    parameter int unsigned ADDR_W          = 32,
    parameter int unsigned DATA_W          = 32,
    parameter int unsigned MAX_UNIQ_IDS    = 4,
    parameter int unsigned MAX_TXNS_PER_ID = 2
) (
    input  logic clk_i,
    input  logic rst_ni,
    input  logic [SLV_ID_W-1:0]   s_awid,
    input  logic [ADDR_W-1:0]   s_awaddr,
    input  logic [7:0]          s_awlen,
    input  logic                s_awvalid,
    output logic                s_awready,
    input  logic [DATA_W-1:0]   s_wdata,
    input  logic [DATA_W/8-1:0] s_wstrb,
    input  logic                s_wlast,
    input  logic                s_wvalid,
    output logic                s_wready,
    output logic [SLV_ID_W-1:0]   s_bid,
    output logic [1:0]          s_bresp,
    output logic                s_bvalid,
    input  logic                s_bready,
    input  logic [SLV_ID_W-1:0]   s_arid,
    input  logic [ADDR_W-1:0]   s_araddr,
    input  logic [7:0]          s_arlen,
    input  logic                s_arvalid,
    output logic                s_arready,
    output logic [SLV_ID_W-1:0]   s_rid,
    output logic [DATA_W-1:0]   s_rdata,
    output logic [1:0]          s_rresp,
    output logic                s_rlast,
    output logic                s_rvalid,
    input  logic                s_rready,
    output logic [MST_ID_W-1:0]   m_awid,
    output logic [ADDR_W-1:0]   m_awaddr,
    output logic [7:0]          m_awlen,
    output logic                m_awvalid,
    input  logic                m_awready,
    output logic [DATA_W-1:0]   m_wdata,
    output logic [DATA_W/8-1:0] m_wstrb,
    output logic                m_wlast,
    output logic                m_wvalid,
    input  logic                m_wready,
    input  logic [MST_ID_W-1:0]   m_bid,
    input  logic [1:0]          m_bresp,
    input  logic                m_bvalid,
    output logic                m_bready,
    output logic [MST_ID_W-1:0]   m_arid,
    output logic [ADDR_W-1:0]   m_araddr,
    output logic [7:0]          m_arlen,
    output logic                m_arvalid,
    input  logic                m_arready,
    input  logic [MST_ID_W-1:0]   m_rid,
    input  logic [DATA_W-1:0]   m_rdata,
    input  logic [1:0]          m_rresp,
    input  logic                m_rlast,
    input  logic                m_rvalid,
    output logic                m_rready
);

  // Outstanding count per slave id, from the slave-port handshakes only.
  localparam int unsigned NID = 1 << SLV_ID_W;
  int unsigned rcnt [NID];
  int unsigned wcnt [NID];
  always_ff @(posedge clk_i) begin
    if (!rst_ni) begin
      for (int i = 0; i < NID; i++) begin rcnt[i] <= 0; wcnt[i] <= 0; end
    end else begin
      if (s_arvalid && s_arready)                 rcnt[s_arid] <= rcnt[s_arid] + 1;
      if (s_rvalid  && s_rready && s_rlast)       rcnt[s_rid]  <= rcnt[s_rid]  - 1;
      if (s_awvalid && s_awready)                 wcnt[s_awid] <= wcnt[s_awid] + 1;
      if (s_bvalid  && s_bready)                  wcnt[s_bid]  <= wcnt[s_bid]  - 1;
    end
  end
  function automatic int unsigned n_distinct_r();
    n_distinct_r = 0;
    for (int i = 0; i < NID; i++) if (rcnt[i] != 0) n_distinct_r++;
  endfunction
  function automatic int unsigned n_distinct_w();
    n_distinct_w = 0;
    for (int i = 0; i < NID; i++) if (wcnt[i] != 0) n_distinct_w++;
  endfunction

  wire g_arvalid = s_arvalid & ~((n_distinct_r() >= MAX_UNIQ_IDS) && (rcnt[s_arid] != 0));
  wire g_awvalid = s_awvalid & ~((n_distinct_w() >= MAX_UNIQ_IDS) && (wcnt[s_awid] != 0));
  wire g_arready, g_awready;
  assign s_arready = g_arready & ~((n_distinct_r() >= MAX_UNIQ_IDS) && (rcnt[s_arid] != 0));
  assign s_awready = g_awready & ~((n_distinct_w() >= MAX_UNIQ_IDS) && (wcnt[s_awid] != 0));

  id_width_conv #(
      .SLV_ID_W(SLV_ID_W), .MST_ID_W(MST_ID_W), .ADDR_W(ADDR_W), .DATA_W(DATA_W),
      .MAX_UNIQ_IDS(MAX_UNIQ_IDS), .MAX_TXNS_PER_ID(MAX_TXNS_PER_ID)
  ) i_g (
      .clk_i, .rst_ni,
      .s_awid, .s_awaddr, .s_awlen, .s_awvalid(g_awvalid), .s_awready(g_awready),
      .s_wdata, .s_wstrb, .s_wlast, .s_wvalid, .s_wready,
      .s_bid, .s_bresp, .s_bvalid, .s_bready,
      .s_arid, .s_araddr, .s_arlen, .s_arvalid(g_arvalid), .s_arready(g_arready),
      .s_rid, .s_rdata, .s_rresp, .s_rlast, .s_rvalid, .s_rready,
      .m_awid, .m_awaddr, .m_awlen, .m_awvalid, .m_awready,
      .m_wdata, .m_wstrb, .m_wlast, .m_wvalid, .m_wready,
      .m_bid, .m_bresp, .m_bvalid, .m_bready,
      .m_arid, .m_araddr, .m_arlen, .m_arvalid, .m_arready,
      .m_rid, .m_rdata, .m_rresp, .m_rlast, .m_rvalid, .m_rready
  );
endmodule

// ----------------------------------------------------------------------------
// iw_m5_reads_and_writes_share -- violates A1.
// BOUNDARY: reads and writes share one table.
// A1 counts them separately. Here a write is refused once reads plus writes
// occupy MAX_UNIQ_IDS entries between them. Pure-read and pure-write traffic
// behave perfectly; only mixed traffic at the boundary is wrong.
// ----------------------------------------------------------------------------
module iw_m5_reads_and_writes_share #(
    parameter int unsigned SLV_ID_W        = 4,
    parameter int unsigned MST_ID_W        = 2,
    parameter int unsigned ADDR_W          = 32,
    parameter int unsigned DATA_W          = 32,
    parameter int unsigned MAX_UNIQ_IDS    = 4,
    parameter int unsigned MAX_TXNS_PER_ID = 2
) (
    input  logic clk_i,
    input  logic rst_ni,
    input  logic [SLV_ID_W-1:0]   s_awid,
    input  logic [ADDR_W-1:0]   s_awaddr,
    input  logic [7:0]          s_awlen,
    input  logic                s_awvalid,
    output logic                s_awready,
    input  logic [DATA_W-1:0]   s_wdata,
    input  logic [DATA_W/8-1:0] s_wstrb,
    input  logic                s_wlast,
    input  logic                s_wvalid,
    output logic                s_wready,
    output logic [SLV_ID_W-1:0]   s_bid,
    output logic [1:0]          s_bresp,
    output logic                s_bvalid,
    input  logic                s_bready,
    input  logic [SLV_ID_W-1:0]   s_arid,
    input  logic [ADDR_W-1:0]   s_araddr,
    input  logic [7:0]          s_arlen,
    input  logic                s_arvalid,
    output logic                s_arready,
    output logic [SLV_ID_W-1:0]   s_rid,
    output logic [DATA_W-1:0]   s_rdata,
    output logic [1:0]          s_rresp,
    output logic                s_rlast,
    output logic                s_rvalid,
    input  logic                s_rready,
    output logic [MST_ID_W-1:0]   m_awid,
    output logic [ADDR_W-1:0]   m_awaddr,
    output logic [7:0]          m_awlen,
    output logic                m_awvalid,
    input  logic                m_awready,
    output logic [DATA_W-1:0]   m_wdata,
    output logic [DATA_W/8-1:0] m_wstrb,
    output logic                m_wlast,
    output logic                m_wvalid,
    input  logic                m_wready,
    input  logic [MST_ID_W-1:0]   m_bid,
    input  logic [1:0]          m_bresp,
    input  logic                m_bvalid,
    output logic                m_bready,
    output logic [MST_ID_W-1:0]   m_arid,
    output logic [ADDR_W-1:0]   m_araddr,
    output logic [7:0]          m_arlen,
    output logic                m_arvalid,
    input  logic                m_arready,
    input  logic [MST_ID_W-1:0]   m_rid,
    input  logic [DATA_W-1:0]   m_rdata,
    input  logic [1:0]          m_rresp,
    input  logic                m_rlast,
    input  logic                m_rvalid,
    output logic                m_rready
);

  // Outstanding count per slave id, from the slave-port handshakes only.
  localparam int unsigned NID = 1 << SLV_ID_W;
  int unsigned rcnt [NID];
  int unsigned wcnt [NID];
  always_ff @(posedge clk_i) begin
    if (!rst_ni) begin
      for (int i = 0; i < NID; i++) begin rcnt[i] <= 0; wcnt[i] <= 0; end
    end else begin
      if (s_arvalid && s_arready)                 rcnt[s_arid] <= rcnt[s_arid] + 1;
      if (s_rvalid  && s_rready && s_rlast)       rcnt[s_rid]  <= rcnt[s_rid]  - 1;
      if (s_awvalid && s_awready)                 wcnt[s_awid] <= wcnt[s_awid] + 1;
      if (s_bvalid  && s_bready)                  wcnt[s_bid]  <= wcnt[s_bid]  - 1;
    end
  end
  function automatic int unsigned n_distinct_r();
    n_distinct_r = 0;
    for (int i = 0; i < NID; i++) if (rcnt[i] != 0) n_distinct_r++;
  endfunction
  function automatic int unsigned n_distinct_w();
    n_distinct_w = 0;
    for (int i = 0; i < NID; i++) if (wcnt[i] != 0) n_distinct_w++;
  endfunction

  wire g_arvalid = s_arvalid & ~(((n_distinct_r() + n_distinct_w()) >= MAX_UNIQ_IDS) && (rcnt[s_arid] == 0));
  wire g_awvalid = s_awvalid & ~(((n_distinct_r() + n_distinct_w()) >= MAX_UNIQ_IDS) && (wcnt[s_awid] == 0));
  wire g_arready, g_awready;
  assign s_arready = g_arready & ~(((n_distinct_r() + n_distinct_w()) >= MAX_UNIQ_IDS) && (rcnt[s_arid] == 0));
  assign s_awready = g_awready & ~(((n_distinct_r() + n_distinct_w()) >= MAX_UNIQ_IDS) && (wcnt[s_awid] == 0));

  id_width_conv #(
      .SLV_ID_W(SLV_ID_W), .MST_ID_W(MST_ID_W), .ADDR_W(ADDR_W), .DATA_W(DATA_W),
      .MAX_UNIQ_IDS(MAX_UNIQ_IDS), .MAX_TXNS_PER_ID(MAX_TXNS_PER_ID)
  ) i_g (
      .clk_i, .rst_ni,
      .s_awid, .s_awaddr, .s_awlen, .s_awvalid(g_awvalid), .s_awready(g_awready),
      .s_wdata, .s_wstrb, .s_wlast, .s_wvalid, .s_wready,
      .s_bid, .s_bresp, .s_bvalid, .s_bready,
      .s_arid, .s_araddr, .s_arlen, .s_arvalid(g_arvalid), .s_arready(g_arready),
      .s_rid, .s_rdata, .s_rresp, .s_rlast, .s_rvalid, .s_rready,
      .m_awid, .m_awaddr, .m_awlen, .m_awvalid, .m_awready,
      .m_wdata, .m_wstrb, .m_wlast, .m_wvalid, .m_wready,
      .m_bid, .m_bresp, .m_bvalid, .m_bready,
      .m_arid, .m_araddr, .m_arlen, .m_arvalid, .m_arready,
      .m_rid, .m_rdata, .m_rresp, .m_rlast, .m_rvalid, .m_rready
  );
endmodule
