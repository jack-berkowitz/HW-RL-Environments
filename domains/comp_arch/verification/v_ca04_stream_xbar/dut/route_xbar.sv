// ---------------------------------------------------------------------------
// GOLDEN -- scoring only. NEVER shipped to a submission.
//
// Class A port shim: flattens the anchor's packed-array ports into plain wide
// vectors and pins the configuration. Slicing and renaming only -- no logic,
// no reordering, no arbitration of its own.
//
// Pinned inside the shim, deliberately NOT exposed as parameters: the port
// counts and the arbitration mode. Fairness is a property of round-robin
// arbitration at a specific port count; exposing either would let a submission
// build the golden off-spec and fail the validity gate for a configuration
// error rather than a verification error.
// ---------------------------------------------------------------------------
module route_xbar #(
  parameter int unsigned N_IN    = 4,
  parameter int unsigned N_OUT   = 4,
  parameter int unsigned DATA_W  = 32,
  parameter int unsigned SEL_W   = 2,
  parameter int unsigned IDX_W   = 2
) (
  input  logic                       clk_i,
  input  logic                       rst_ni,
  // ---- input side ----
  input  logic [N_IN*DATA_W-1:0]     in_data_i,
  input  logic [N_IN*SEL_W-1:0]      in_sel_i,
  input  logic [N_IN-1:0]            in_valid_i,
  output logic [N_IN-1:0]            in_ready_o,
  // ---- output side ----
  output logic [N_OUT*DATA_W-1:0]    out_data_o,
  output logic [N_OUT*IDX_W-1:0]     out_idx_o,
  output logic [N_OUT-1:0]           out_valid_o,
  input  logic [N_OUT-1:0]           out_ready_i
);
  typedef logic [DATA_W-1:0] payload_t;
  typedef logic [SEL_W-1:0]  sel_t;
  typedef logic [IDX_W-1:0]  idx_t;

  payload_t [N_IN-1:0]  d_i;
  sel_t     [N_IN-1:0]  s_i;
  payload_t [N_OUT-1:0] d_o;
  idx_t     [N_OUT-1:0] x_o;

  always_comb begin
    for (int unsigned k = 0; k < N_IN; k++) begin
      d_i[k] = in_data_i[k*DATA_W +: DATA_W];
      s_i[k] = in_sel_i[k*SEL_W  +: SEL_W];
    end
  end
  always_comb begin
    for (int unsigned j = 0; j < N_OUT; j++) begin
      out_data_o[j*DATA_W +: DATA_W] = d_o[j];
      out_idx_o [j*IDX_W  +: IDX_W]  = x_o[j];
    end
  end

  stream_xbar #(
    .NumInp      (N_IN),
    .NumOut      (N_OUT),
    .DataWidth   (DATA_W),
    .OutSpillReg (1'b0),
    .ExtPrio     (1'b0),      // internal round robin
    .AxiVldRdy   (1'b1),      // strict valid/ready handshaking
    .LockIn      (1'b1)       // an arbitration decision is held until it completes
  ) i_xbar (
    .clk_i, .rst_ni,
    .flush_i (1'b0),
    .rr_i    ('0),
    .data_i  (d_i),
    .sel_i   (s_i),
    .valid_i (in_valid_i),
    .ready_o (in_ready_o),
    .data_o  (d_o),
    .idx_o   (x_o),
    .valid_o (out_valid_o),
    .ready_i (out_ready_i)
  );
endmodule
