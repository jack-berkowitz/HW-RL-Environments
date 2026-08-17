// =============================================================================
// frame_arb_mux_alt.sv -- SECOND DUT for v_nw03. Locally written.
// =============================================================================
// An independent implementation of spec/frame_arb_mux_spec.md, written against
// the specification rather than derived from the anchor, and deliberately making
// DIFFERENT choices everywhere the spec leaves one open.
//
// *** NOTHING IN THE HARNESS RUNS THIS YET. ***
// scripts/sim_verification.sh gates on the DECLARATION -- it refuses when
// task.yaml claims a second DUT and dut2/ is absent -- but it never compiles
// this file and never adds a row for it. It has been exercised only by running
// the reference testbench against it by hand; see NOTES.md. No claim about any
// submission rests on it.
//
// THE THREE DIFFERENCES (rule 5), named before writing:
//
//   1. SELECTION MECHANISM. A single rotating pointer, scanned combinationally
//      from `next_ptr`, advanced by one past the input just served. The anchor
//      uses a masked-priority tree carrying its own mask register. Same
//      obligation under S10, different machine.
//
//   2. NO INPUT REGISTERS -- and this is the one that matters. `s_tready_o[k]`
//      is high ONLY for the input currently selected. The anchor registers
//      every input, so its ready is high for any input whose register is empty,
//      including inputs that are not selected and will not be next. §7.3
//      licenses both. A testbench that learned "ready means not selected yet,
//      but accepted anyway" from the anchor's behaviour breaks here; a
//      testbench that reads S6 as written does not.
//
//   3. OUTPUT DEPTH. One output register, with `s_tready_o` combinationally
//      dependent on `m_tready_i`. The anchor carries a two-deep output datapath
//      (output register plus a temp register) and a registered ready. Different
//      latency and a different backpressure signature, both legal under S11.
// =============================================================================

module frame_arb_mux_alt #(
    parameter int S_COUNT    = 4,
    parameter int DATA_WIDTH = 32,
    parameter int USER_WIDTH = 1
) (
    input  logic                                     clk_i,
    input  logic                                     rst_i,

    input  logic [S_COUNT-1:0][DATA_WIDTH-1:0]       s_tdata_i,
    input  logic [S_COUNT-1:0][(DATA_WIDTH/8)-1:0]   s_tkeep_i,
    input  logic [S_COUNT-1:0]                       s_tvalid_i,
    output logic [S_COUNT-1:0]                       s_tready_o,
    input  logic [S_COUNT-1:0]                       s_tlast_i,
    input  logic [S_COUNT-1:0][USER_WIDTH-1:0]       s_tuser_i,

    output logic [DATA_WIDTH-1:0]                    m_tdata_o,
    output logic [(DATA_WIDTH/8)-1:0]                m_tkeep_o,
    output logic                                     m_tvalid_o,
    input  logic                                     m_tready_i,
    output logic                                     m_tlast_o,
    output logic [USER_WIDTH-1:0]                    m_tuser_o
);

  localparam int KEEP_WIDTH = DATA_WIDTH/8;
  localparam int IW         = (S_COUNT > 1) ? $clog2(S_COUNT) : 1;

  logic [IW-1:0] next_ptr, sel;
  logic          busy;

  logic [DATA_WIDTH-1:0] o_data;
  logic [KEEP_WIDTH-1:0] o_keep;
  logic [USER_WIDTH-1:0] o_user;
  logic                  o_last, o_valid;

  wire o_fire = o_valid & m_tready_i;
  wire o_free = ~o_valid | o_fire;      // a beat can be loaded this cycle

  // ---- selection: hold while mid-frame, otherwise rotate ---------------------
  logic          pick_valid;
  logic [IW-1:0] pick;

  always_comb begin
    pick_valid = 1'b0;
    pick       = '0;
    if (busy) begin
      pick_valid = 1'b1;
      pick       = sel;
    end else begin
      // Scan downwards so the LAST match written wins, which is the input
      // closest to next_ptr going upwards.
      for (int i = S_COUNT - 1; i >= 0; i--) begin
        automatic int idx = (int'(next_ptr) + i) % S_COUNT;
        if (s_tvalid_i[idx]) begin
          pick_valid = 1'b1;
          pick       = IW'(idx);
        end
      end
    end
  end

  // Difference 2: ready ONLY for the selected input.
  always_comb begin
    s_tready_o = '0;
    if (pick_valid && o_free) s_tready_o[pick] = 1'b1;
  end

  always_ff @(posedge clk_i) begin
    if (rst_i) begin
      next_ptr <= '0;
      sel      <= '0;
      busy     <= 1'b0;
      o_valid  <= 1'b0;
    end else begin
      if (o_fire) o_valid <= 1'b0;

      if (pick_valid && o_free && s_tvalid_i[pick]) begin
        o_valid <= 1'b1;
        o_data  <= s_tdata_i[pick];
        o_keep  <= s_tkeep_i[pick];
        o_user  <= s_tuser_i[pick];
        o_last  <= s_tlast_i[pick];
        sel     <= pick;
        busy    <= ~s_tlast_i[pick];
        if (s_tlast_i[pick])
          next_ptr <= (int'(pick) == S_COUNT - 1) ? '0 : IW'(int'(pick) + 1);
      end
    end
  end

  assign m_tdata_o  = o_data;
  assign m_tkeep_o  = o_keep;
  assign m_tuser_o  = o_user;
  assign m_tlast_o  = o_last;
  assign m_tvalid_o = o_valid;

endmodule
