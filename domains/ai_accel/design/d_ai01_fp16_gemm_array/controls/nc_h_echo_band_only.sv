// ============================================================================
// nc_h_echo_band_only -- d_ai01 COST CONTROL for C3's widened window.
// Never shipped. EXPECTED TO PASS after the widening, and that is its purpose.
// ============================================================================
// READ THIS BEFORE READING ITS VERDICT. Every other control in this directory
// fails and is inert if it passes. This one is the opposite: it exists to be
// DETECTED BEFORE the C3 widening and NOT DETECTED AFTER, and its PASS is the
// measurement. A reader who applies the usual rule to it will draw the
// backwards conclusion.
//
// WHY IT EXISTS. C3's exclusion window went from d(0) = D*(HEIGHT-1)+3 to
// d(0) + dfb = 2*D*(HEIGHT-1)+7 -- it doubled, 15->31 at HEIGHT=4 and 31->63 at
// HEIGHT=8. Every existing control (nc_a..nc_g) fails by 80 to 3033 z
// mismatches spread across the whole run, so ALL of them would be caught by a
// window of any width. Their firing says nothing whatever about what the NEW
// band covers, and Rule 24 is therefore not satisfied for the widening by the
// existing set.
//
// THE PERTURBATION. The reference verbatim, with z_o corrupted ONLY inside the
// newly excluded band: enabled ticks d(0)+1 through d(0)+dfb after a change of
// accumulate_i, counted the way the rig counts them. Outside that band it is
// bit-for-bit the reference.
//
// SO ITS VERDICT MEASURES THE BAND, AND NOTHING ELSE:
//   DETECTED   (FAIL) against the pre-widening window  -> the band was scored
//   NOT DETECTED (PASS) against the widened window     -> the band is now blind
//
// That pair is what the widening cost, stated as an experiment rather than as
// an assurance. It is the only artifact in this task that measures the size of
// the hole rather than the presence of a check.
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
  localparam int unsigned D    = 4;
  localparam int unsigned D0   = D*(HEIGHT-1) + 3;   // old window
  localparam int unsigned DFB  = D*(HEIGHT-1) + 4;   // feedback depth

  logic [WIDTH-1:0][15:0] inner_z;
  int unsigned            acc_tick;
  logic                   prev_acc;
  // ARMED ONLY AFTER A REAL TRANSITION. Without this the counter free-runs from
  // reset and enters the band during initial startup, where C3's window was
  // never armed -- so the control was detected after the widening for a reason
  // that had nothing to do with the band. Measured: 16 residual mismatches at
  // HEIGHT=4 and 32 at HEIGHT=8, all before the first change of accumulate_i.
  logic                   armed;

  // Enabled ticks since the last change of accumulate_i, in the SAME basis the
  // rig uses for the whole-array window: reg_enable_i alone.
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      acc_tick <= 0;
      prev_acc <= 1'b0;
      armed    <= 1'b0;
    end else begin
      prev_acc <= accumulate_i;
      if (accumulate_i !== prev_acc) begin
        acc_tick <= 0;
        armed    <= 1'b1;
      end else if (reg_enable_i) acc_tick <= acc_tick + 1;
    end
  end

  // THE PERTURBATION, confined to the newly excluded band.
  for (genvar r = 0; r < WIDTH; r++) begin : g_band
    assign z_o[r] = (armed && acc_tick > D0 && acc_tick <= D0 + DFB)
                    ? (inner_z[r] ^ 16'h0040)
                    : inner_z[r];
  end

  fp16_gemm_array_ref_inner #(.HEIGHT(HEIGHT), .WIDTH(WIDTH)) u_inner (
    .clk_i(clk_i), .rst_ni(rst_ni), .x_i(x_i), .w_i(w_i), .y_i(y_i), .z_o(inner_z),
    .rnd_i(rnd_i), .accumulate_i(accumulate_i),
    .row_clk_gate_en_i(row_clk_gate_en_i), .reg_enable_i(reg_enable_i),
    .flush_i(flush_i), .status_o(status_o)
  );
endmodule
