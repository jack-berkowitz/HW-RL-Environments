// =============================================================================
// conformant_perturbations.sv -- these MUST SURVIVE.
// =============================================================================
// Each module wraps the UNMODIFIED golden and changes something the
// specification deliberately leaves open. A submitted testbench must ACCEPT
// every one; a failure here means the testbench checked something the spec
// never promised -- a defect in the SPEC or in the submission, never in these.
//
// Opposite sign to mutants/. See conformant/README.md for the clause-by-clause
// enumeration and the non-equivalence witnesses.
//
// Every wrapper instantiates `frame_arb_mux #(` -- the parameter list is
// required, because the harness rewrites the inner instantiation by matching
// the module name followed by `#(`.
// =============================================================================

// -----------------------------------------------------------------------------
// fm_c1 -- ready withheld on a rolling schedule.   Licence: S6, latitude 3.
// An input's ready may be low for reasons other than fullness. Both the valid
// into the golden and the ready out are gated together, so no cycle exists in
// which the golden accepts a beat the source does not know about.
// -----------------------------------------------------------------------------
module fm_c1_ready_withheld #(
    parameter int S_COUNT = 4, parameter int DATA_WIDTH = 32, parameter int USER_WIDTH = 1
) (
    input  logic clk_i, input logic rst_i,
    input  logic [S_COUNT-1:0][DATA_WIDTH-1:0]     s_tdata_i,
    input  logic [S_COUNT-1:0][(DATA_WIDTH/8)-1:0] s_tkeep_i,
    input  logic [S_COUNT-1:0]                     s_tvalid_i,
    output logic [S_COUNT-1:0]                     s_tready_o,
    input  logic [S_COUNT-1:0]                     s_tlast_i,
    input  logic [S_COUNT-1:0][USER_WIDTH-1:0]     s_tuser_i,
    output logic [DATA_WIDTH-1:0]                  m_tdata_o,
    output logic [(DATA_WIDTH/8)-1:0]              m_tkeep_o,
    output logic                                   m_tvalid_o,
    input  logic                                   m_tready_i,
    output logic                                   m_tlast_o,
    output logic [USER_WIDTH-1:0]                  m_tuser_o
);
  logic [2:0] cnt;
  always_ff @(posedge clk_i) if (rst_i) cnt <= '0; else cnt <= cnt + 1;

  logic [S_COUNT-1:0] mask, g_valid, g_ready;
  always_comb for (int k = 0; k < S_COUNT; k++) mask[k] = (cnt[1:0] == k[1:0]);

  assign g_valid    = s_tvalid_i & ~mask;
  assign s_tready_o = g_ready    & ~mask;

  frame_arb_mux #(.S_COUNT(S_COUNT), .DATA_WIDTH(DATA_WIDTH), .USER_WIDTH(USER_WIDTH)) i_g (
    .clk_i(clk_i), .rst_i(rst_i),
    .s_tdata_i(s_tdata_i), .s_tkeep_i(s_tkeep_i), .s_tvalid_i(g_valid),
    .s_tready_o(g_ready), .s_tlast_i(s_tlast_i), .s_tuser_i(s_tuser_i),
    .m_tdata_o(m_tdata_o), .m_tkeep_o(m_tkeep_o), .m_tvalid_o(m_tvalid_o),
    .m_tready_i(m_tready_i), .m_tlast_o(m_tlast_o), .m_tuser_o(m_tuser_o));
endmodule

// -----------------------------------------------------------------------------
// fm_c2 -- input order reversed.                   Licence: S9, latitude 1.
// Selection order is unconstrained, so serving the inputs in the opposite
// rotation is a legal design. Implemented as a pure permutation of the ports.
// -----------------------------------------------------------------------------
module fm_c2_reversed_order #(
    parameter int S_COUNT = 4, parameter int DATA_WIDTH = 32, parameter int USER_WIDTH = 1
) (
    input  logic clk_i, input logic rst_i,
    input  logic [S_COUNT-1:0][DATA_WIDTH-1:0]     s_tdata_i,
    input  logic [S_COUNT-1:0][(DATA_WIDTH/8)-1:0] s_tkeep_i,
    input  logic [S_COUNT-1:0]                     s_tvalid_i,
    output logic [S_COUNT-1:0]                     s_tready_o,
    input  logic [S_COUNT-1:0]                     s_tlast_i,
    input  logic [S_COUNT-1:0][USER_WIDTH-1:0]     s_tuser_i,
    output logic [DATA_WIDTH-1:0]                  m_tdata_o,
    output logic [(DATA_WIDTH/8)-1:0]              m_tkeep_o,
    output logic                                   m_tvalid_o,
    input  logic                                   m_tready_i,
    output logic                                   m_tlast_o,
    output logic [USER_WIDTH-1:0]                  m_tuser_o
);
  logic [S_COUNT-1:0][DATA_WIDTH-1:0]     r_data;
  logic [S_COUNT-1:0][(DATA_WIDTH/8)-1:0] r_keep;
  logic [S_COUNT-1:0]                     r_valid, r_ready, r_last;
  logic [S_COUNT-1:0][USER_WIDTH-1:0]     r_user;

  always_comb begin
    for (int k = 0; k < S_COUNT; k++) begin
      r_data [k] = s_tdata_i [S_COUNT-1-k];
      r_keep [k] = s_tkeep_i [S_COUNT-1-k];
      r_valid[k] = s_tvalid_i[S_COUNT-1-k];
      r_last [k] = s_tlast_i [S_COUNT-1-k];
      r_user [k] = s_tuser_i [S_COUNT-1-k];
      s_tready_o[S_COUNT-1-k] = r_ready[k];
    end
  end

  frame_arb_mux #(.S_COUNT(S_COUNT), .DATA_WIDTH(DATA_WIDTH), .USER_WIDTH(USER_WIDTH)) i_g (
    .clk_i(clk_i), .rst_i(rst_i),
    .s_tdata_i(r_data), .s_tkeep_i(r_keep), .s_tvalid_i(r_valid),
    .s_tready_o(r_ready), .s_tlast_i(r_last), .s_tuser_i(r_user),
    .m_tdata_o(m_tdata_o), .m_tkeep_o(m_tkeep_o), .m_tvalid_o(m_tvalid_o),
    .m_tready_i(m_tready_i), .m_tlast_o(m_tlast_o), .m_tuser_o(m_tuser_o));
endmodule

// -----------------------------------------------------------------------------
// fm_c3 -- one extra register stage on the output. Licence: S11, latitude 2.
// Latency is unconstrained. This is a register slice with a combinational
// upstream ready: exactly one cycle of added latency and no loss of throughput.
// -----------------------------------------------------------------------------
module fm_c3_extra_latency #(
    parameter int S_COUNT = 4, parameter int DATA_WIDTH = 32, parameter int USER_WIDTH = 1
) (
    input  logic clk_i, input logic rst_i,
    input  logic [S_COUNT-1:0][DATA_WIDTH-1:0]     s_tdata_i,
    input  logic [S_COUNT-1:0][(DATA_WIDTH/8)-1:0] s_tkeep_i,
    input  logic [S_COUNT-1:0]                     s_tvalid_i,
    output logic [S_COUNT-1:0]                     s_tready_o,
    input  logic [S_COUNT-1:0]                     s_tlast_i,
    input  logic [S_COUNT-1:0][USER_WIDTH-1:0]     s_tuser_i,
    output logic [DATA_WIDTH-1:0]                  m_tdata_o,
    output logic [(DATA_WIDTH/8)-1:0]              m_tkeep_o,
    output logic                                   m_tvalid_o,
    input  logic                                   m_tready_i,
    output logic                                   m_tlast_o,
    output logic [USER_WIDTH-1:0]                  m_tuser_o
);
  logic [DATA_WIDTH-1:0]     g_data, r_data;
  logic [(DATA_WIDTH/8)-1:0] g_keep, r_keep;
  logic [USER_WIDTH-1:0]     g_user, r_user;
  logic                      g_valid, g_last, g_ready, r_valid, r_last;

  wire fire = r_valid & m_tready_i;
  wire free = ~r_valid | fire;
  assign g_ready = free;

  always_ff @(posedge clk_i) begin
    if (rst_i) r_valid <= 1'b0;
    else begin
      if (fire) r_valid <= 1'b0;
      if (free && g_valid) begin
        r_valid <= 1'b1;
        r_data  <= g_data; r_keep <= g_keep; r_user <= g_user; r_last <= g_last;
      end
    end
  end

  assign m_tdata_o = r_data; assign m_tkeep_o = r_keep;
  assign m_tuser_o = r_user; assign m_tlast_o = r_last;
  assign m_tvalid_o = r_valid;

  frame_arb_mux #(.S_COUNT(S_COUNT), .DATA_WIDTH(DATA_WIDTH), .USER_WIDTH(USER_WIDTH)) i_g (
    .clk_i(clk_i), .rst_i(rst_i),
    .s_tdata_i(s_tdata_i), .s_tkeep_i(s_tkeep_i), .s_tvalid_i(s_tvalid_i),
    .s_tready_o(s_tready_o), .s_tlast_i(s_tlast_i), .s_tuser_i(s_tuser_i),
    .m_tdata_o(g_data), .m_tkeep_o(g_keep), .m_tvalid_o(g_valid),
    .m_tready_i(g_ready), .m_tlast_o(g_last), .m_tuser_o(g_user));
endmodule

// -----------------------------------------------------------------------------
// fm_c4 -- output signals carry garbage while invalid. Licence: latitude 4.
// tdata/tkeep/tuser are unconstrained whenever m_tvalid_o is low, so a design
// is free to drive anything there. A testbench that samples them without
// qualifying on valid fails here and only here.
// -----------------------------------------------------------------------------
module fm_c4_garbage_when_invalid #(
    parameter int S_COUNT = 4, parameter int DATA_WIDTH = 32, parameter int USER_WIDTH = 1
) (
    input  logic clk_i, input logic rst_i,
    input  logic [S_COUNT-1:0][DATA_WIDTH-1:0]     s_tdata_i,
    input  logic [S_COUNT-1:0][(DATA_WIDTH/8)-1:0] s_tkeep_i,
    input  logic [S_COUNT-1:0]                     s_tvalid_i,
    output logic [S_COUNT-1:0]                     s_tready_o,
    input  logic [S_COUNT-1:0]                     s_tlast_i,
    input  logic [S_COUNT-1:0][USER_WIDTH-1:0]     s_tuser_i,
    output logic [DATA_WIDTH-1:0]                  m_tdata_o,
    output logic [(DATA_WIDTH/8)-1:0]              m_tkeep_o,
    output logic                                   m_tvalid_o,
    input  logic                                   m_tready_i,
    output logic                                   m_tlast_o,
    output logic [USER_WIDTH-1:0]                  m_tuser_o
);
  logic [DATA_WIDTH-1:0]     g_data;
  logic [(DATA_WIDTH/8)-1:0] g_keep;
  logic [USER_WIDTH-1:0]     g_user;
  logic                      g_valid, g_last;
  logic [31:0]               lfsr;

  always_ff @(posedge clk_i)
    if (rst_i) lfsr <= 32'h1234_5678;
    else       lfsr <= {lfsr[30:0], lfsr[31]^lfsr[21]^lfsr[1]^lfsr[0]};

  assign m_tvalid_o = g_valid;
  assign m_tlast_o  = g_last;
  assign m_tdata_o  = g_valid ? g_data : lfsr[DATA_WIDTH-1:0];
  assign m_tkeep_o  = g_valid ? g_keep : lfsr[(DATA_WIDTH/8)-1:0];
  assign m_tuser_o  = g_valid ? g_user : lfsr[USER_WIDTH-1:0];

  frame_arb_mux #(.S_COUNT(S_COUNT), .DATA_WIDTH(DATA_WIDTH), .USER_WIDTH(USER_WIDTH)) i_g (
    .clk_i(clk_i), .rst_i(rst_i),
    .s_tdata_i(s_tdata_i), .s_tkeep_i(s_tkeep_i), .s_tvalid_i(s_tvalid_i),
    .s_tready_o(s_tready_o), .s_tlast_i(s_tlast_i), .s_tuser_i(s_tuser_i),
    .m_tdata_o(g_data), .m_tkeep_o(g_keep), .m_tvalid_o(g_valid),
    .m_tready_i(m_tready_i), .m_tlast_o(g_last), .m_tuser_o(g_user));
endmodule

// -----------------------------------------------------------------------------
// fm_c5 -- a forced idle cycle after every frame.  Licence: latitude 5.
// Whether frames may run back to back is unspecified. Valid out and ready in
// are gated together, so the stall is invisible to the data path.
// -----------------------------------------------------------------------------
module fm_c5_idle_between_frames #(
    parameter int S_COUNT = 4, parameter int DATA_WIDTH = 32, parameter int USER_WIDTH = 1
) (
    input  logic clk_i, input logic rst_i,
    input  logic [S_COUNT-1:0][DATA_WIDTH-1:0]     s_tdata_i,
    input  logic [S_COUNT-1:0][(DATA_WIDTH/8)-1:0] s_tkeep_i,
    input  logic [S_COUNT-1:0]                     s_tvalid_i,
    output logic [S_COUNT-1:0]                     s_tready_o,
    input  logic [S_COUNT-1:0]                     s_tlast_i,
    input  logic [S_COUNT-1:0][USER_WIDTH-1:0]     s_tuser_i,
    output logic [DATA_WIDTH-1:0]                  m_tdata_o,
    output logic [(DATA_WIDTH/8)-1:0]              m_tkeep_o,
    output logic                                   m_tvalid_o,
    input  logic                                   m_tready_i,
    output logic                                   m_tlast_o,
    output logic [USER_WIDTH-1:0]                  m_tuser_o
);
  logic g_valid, g_last, g_ready, stall;

  always_ff @(posedge clk_i)
    if (rst_i) stall <= 1'b0;
    else       stall <= (m_tvalid_o & m_tready_i & m_tlast_o);

  assign m_tvalid_o = g_valid & ~stall;
  assign g_ready    = m_tready_i & ~stall;

  frame_arb_mux #(.S_COUNT(S_COUNT), .DATA_WIDTH(DATA_WIDTH), .USER_WIDTH(USER_WIDTH)) i_g (
    .clk_i(clk_i), .rst_i(rst_i),
    .s_tdata_i(s_tdata_i), .s_tkeep_i(s_tkeep_i), .s_tvalid_i(s_tvalid_i),
    .s_tready_o(s_tready_o), .s_tlast_i(s_tlast_i), .s_tuser_i(s_tuser_i),
    .m_tdata_o(m_tdata_o), .m_tkeep_o(m_tkeep_o), .m_tvalid_o(g_valid),
    .m_tready_i(g_ready), .m_tlast_o(m_tlast_o), .m_tuser_o(m_tuser_o));
endmodule
