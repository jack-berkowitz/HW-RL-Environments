// ============================================================================
// nc_i_band_unstable -- d_ai01 control for the BAND-FREEZE FLOOR. Never shipped.
// ============================================================================
// C3 makes z_o's VALUE unspecified inside the accumulate transition window. It
// does not suspend C1 or C4, which say when a value may move at all: a row with
// no enabled tick holds its output. This design moves z_o inside the band on
// EVERY clock edge, including edges that are not enabled ticks for the row.
//
// WHY THE BAND NEEDS A FLOOR AT ALL. It is 63 enabled ticks per accumulate
// transition at HEIGHT=8, 5.8% of samples, and it grows linearly with HEIGHT --
// which is this task's scored axis, so the unscored region is widest exactly
// where the task is hardest. "Unspecified value" is not "unconstrained output":
// without a floor a submission may free-run the bus there and no check would
// see it.
//
// THE PERTURBATION. The reference verbatim, with z_o XOR-ed by a free-running
// per-clock toggle while inside the band. Outside the band it is bit-for-bit
// the reference, so every scored sample is untouched and this control fails ONLY
// the freeze floor.
//
// WHAT IT DOES NOT TEST. Not "z_o is X" -- Verilator is 2-state and a test for
// X in this rig cannot fire. That is recorded at this task's vector guard,
// where a previous X test passed a run with no vectors loaded at all. The X half
// of the floor is unimplementable here and is stated as absent rather than
// written as a check that would always pass.
//
// PREDICTION: FAIL at both heights, naming the band-freeze floor, with zero z
// mismatches -- because everything it corrupts is unscored, which is the point.
// ============================================================================
`timescale 1ns/1ps

module fp16_gemm_array #(
  parameter int unsigned HEIGHT = 4,
  parameter int unsigned WIDTH  = 8
) (
  input  logic                                     clk_i,
  input  logic                                     rst_ni,
  input  logic [WIDTH-1:0][HEIGHT-1:0][15:0]       x_i,
  input  logic            [HEIGHT-1:0][15:0]       w_i,
  input  logic [WIDTH-1:0]            [15:0]       y_i,
  output logic [WIDTH-1:0]            [15:0]       z_o,
  input  logic [2:0]                               rnd_i,
  input  logic                                     accumulate_i,
  input  logic [WIDTH-1:0]                         row_clk_gate_en_i,
  input  logic                                     reg_enable_i,
  input  logic                                     flush_i,
  output logic [WIDTH-1:0][HEIGHT-1:0][4:0]        status_o
);
  localparam int unsigned D   = 4;
  localparam int unsigned D0  = D*(HEIGHT-1) + 3;
  localparam int unsigned DFB = D*(HEIGHT-1) + 4;

  logic [WIDTH-1:0][15:0] inner_z;
  int unsigned            acc_tick;
  logic                   prev_acc, armed, tog;

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      acc_tick <= 0; prev_acc <= 1'b0; armed <= 1'b0; tog <= 1'b0;
    end else begin
      prev_acc <= accumulate_i;
      tog      <= ~tog;               // free-running: NOT an enabled tick
      if (accumulate_i !== prev_acc) begin
        acc_tick <= 0;
        armed    <= 1'b1;
      end else if (reg_enable_i) acc_tick <= acc_tick + 1;
    end
  end

  // THE PERTURBATION: moves on every edge inside the band, enabled or not.
  for (genvar r = 0; r < WIDTH; r++) begin : g_unstable
    // TWO TICKS OF MARGIN at the band's far edge. The rig derives its window
    // from the recorded stimulus and this counter registers prev_acc, so the two
    // can differ by a cycle at the boundary; without the margin four corrupted
    // samples landed in SCORED territory and the control failed on z as well as
    // on the floor. A control that fails for two reasons is weaker evidence
    // about either.
    // TICK 0 IS EXCLUDED. The rig SCORES the transition cycle itself -- its
    // window arms on that cycle without suppressing it -- while this counter is
    // already reset when the checker samples #1 after the edge. Corrupting at
    // tick 0 therefore lands in a SCORED sample, and all four residual z
    // mismatches were exactly on accumulate transition cycles. The band this
    // control is built to occupy starts at tick 1.
    assign z_o[r] = (armed && acc_tick > 0 && acc_tick <= D0 + DFB - 2 && tog)
                    ? (inner_z[r] ^ 16'h0100)
                    : inner_z[r];
  end

  fp16_gemm_array_ref_inner #(.HEIGHT(HEIGHT), .WIDTH(WIDTH)) u_inner (
    .clk_i(clk_i), .rst_ni(rst_ni), .x_i(x_i), .w_i(w_i), .y_i(y_i), .z_o(inner_z),
    .rnd_i(rnd_i), .accumulate_i(accumulate_i),
    .row_clk_gate_en_i(row_clk_gate_en_i), .reg_enable_i(reg_enable_i),
    .flush_i(flush_i), .status_o(status_o)
  );
endmodule
