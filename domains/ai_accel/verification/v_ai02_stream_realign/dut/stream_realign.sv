// ---------------------------------------------------------------------------
// GOLDEN -- scoring only. NEVER shipped to a submission.
//
// Class A port shim: flattens the anchor's SystemVerilog interfaces and its
// packed control struct into plain signals, and pins the configuration.
// Wiring and renaming only -- no rotation, no buffering, no logic of its own.
// ---------------------------------------------------------------------------
module stream_realign (
  input  logic        clk_i,
  input  logic        rst_ni,
  input  logic        clear_i,
  // ---- control ----
  input  logic        realign_i,
  input  logic        first_i,
  input  logic        last_i,
  input  logic [3:0]  strb_i,
  // ---- input stream ----
  input  logic [31:0] push_data_i,
  input  logic [3:0]  push_strb_i,
  input  logic        push_valid_i,
  output logic        push_ready_o,
  // ---- output stream ----
  output logic [31:0] pop_data_o,
  output logic [3:0]  pop_strb_o,
  output logic        pop_valid_o,
  input  logic        pop_ready_i
);
  hwpe_stream_package::ctrl_realign_t  ctrl;
  hwpe_stream_package::flags_realign_t flags;

  // enable and last_packet are PINNED, and strb_valid and line_length are dead
  // at this configuration -- they are read only on the DECOUPLED path, which is
  // not the one pinned here. Exposing a port the design never reads would be a
  // port map that lies.
  always_comb begin
    ctrl.enable      = 1'b1;
    ctrl.strb_valid  = 1'b0;
    ctrl.realign     = realign_i;
    ctrl.first       = first_i;
    ctrl.last        = last_i;
    ctrl.last_packet = 1'b0;
    ctrl.line_length = 16'd0;
  end

  hwpe_stream_intf_stream #(.DATA_WIDTH(32)) push (.clk(clk_i));
  hwpe_stream_intf_stream #(.DATA_WIDTH(32)) pop  (.clk(clk_i));

  assign push.data  = push_data_i;
  assign push.strb  = push_strb_i;
  assign push.valid = push_valid_i;
  assign push_ready_o = push.ready;

  assign pop_data_o  = pop.data;
  assign pop_strb_o  = pop.strb;
  assign pop_valid_o = pop.valid;
  assign pop.ready   = pop_ready_i;

  hwpe_stream_source_realign #(
    .DECOUPLED       (0),
    .DATA_WIDTH      (32),
    .STRB_FIFO_DEPTH (4)
  ) i_realign (
    .clk_i, .rst_ni, .test_mode_i (1'b0), .clear_i,
    .ctrl_i  (ctrl),
    .flags_o (flags),
    .strb_i  (strb_i),
    .push_i  (push),
    .pop_o   (pop)
  );
endmodule
