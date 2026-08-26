// =============================================================================
// fp16_gemm_array.sv -- implementation of the d_ai01 contract.
//
//   * fp16_fma        : purely combinational binary16 fused multiply-add,
//                       exact product, single rounding, all five modes,
//                       full subnormal support, A5/A6 range tables, IEEE flags.
//   * fp16_gemm_array : WIDTH rows x HEIGHT stages, operand skew d(k)=4*(H-1-k)+2,
//                       status delay 2, accumulate feedback dfb = 4*(H-1)+3.
//
// Register budget (per row), chosen to hit the contract's timing exactly:
//   operand -> FMA_k                     : 0 registers  (combinational)
//   FMA_k   -> FMA_{k+1} accumulator     : D = 4 registers
//   FMA_{H-1} -> z_o                     : 2 registers
//   z_o     -> accumulate feedback mux   : 1 further register
// giving d(k) = 4*(H-1-k)+2, dfb = d(0)+1, and a 2-deep flag pipe per stage.
//
// No loop in this file has a data-dependent or wide bound: the leading-one
// search is an unrolled 6-level select, not a per-bit iteration, so the slang
// unroll budget (T5) is never approached. Total loop iterations at H=8,W=8 are
// 8*(7*4 + 2 + 8*2) = 368.
// =============================================================================

// -----------------------------------------------------------------------------
// Combinational binary16 fused multiply-add.
//
// Method: the exact product (22-bit significand) and the exact addend (11-bit
// significand) are both placed, without truncation, on a common fixed-point
// grid whose LSB has weight 2^-48 -- the lowest exponent any binary16 product
// can reach. The signed sum on that grid is therefore EXACT, which removes the
// sticky-bit borrow problem entirely: no information is discarded before the
// single rounding. 84 bits covers the whole range (2^32 down to 2^-48).
// -----------------------------------------------------------------------------
/* verilator lint_off DECLFILENAME */
module fp16_fma (
  input  logic [15:0] a_i,
  input  logic [15:0] b_i,
  input  logic [15:0] c_i,
  input  logic [2:0]  rnd_i,
  output logic [15:0] z_o,
  output logic [4:0]  flags_o   // {NV, DZ, OF, UF, NX}
);

  localparam int unsigned WA = 84;   // fixed-point grid width, LSB weight 2^-48

  localparam logic [2:0] RNE = 3'd0;
  localparam logic [2:0] RTZ = 3'd1;
  localparam logic [2:0] RDN = 3'd2;
  localparam logic [2:0] RUP = 3'd3;
  localparam logic [2:0] RMM = 3'd4;

  localparam logic [15:0] QNAN = 16'h7E00;   // F2

  // ---------------------------------------------------------------------------
  // Decode
  // ---------------------------------------------------------------------------
  logic       sa, sb, sc;
  logic [4:0] ea, eb, ec;
  logic [9:0] ma, mb, mc;

  assign {sa, ea, ma} = a_i;
  assign {sb, eb, mb} = b_i;
  assign {sc, ec, mc} = c_i;

  logic a_zero, b_zero;
  logic a_inf,  b_inf,  c_inf;
  logic a_nan,  b_nan,  c_nan;

  assign a_zero = (ea == 5'd0)  && (ma == 10'd0);
  assign b_zero = (eb == 5'd0)  && (mb == 10'd0);
  assign a_inf  = (ea == 5'd31) && (ma == 10'd0);
  assign b_inf  = (eb == 5'd31) && (mb == 10'd0);
  assign c_inf  = (ec == 5'd31) && (mc == 10'd0);
  assign a_nan  = (ea == 5'd31) && (ma != 10'd0);
  assign b_nan  = (eb == 5'd31) && (mb != 10'd0);
  assign c_nan  = (ec == 5'd31) && (mc != 10'd0);

  // Significands with the hidden bit made explicit; subnormals keep a 0 there.
  logic [10:0] sga, sgb, sgc;
  assign sga = {(ea != 5'd0), ma};
  assign sgb = {(eb != 5'd0), mb};
  assign sgc = {(ec != 5'd0), mc};

  // Exponent such that value = significand * 2^(x - 10). Subnormals share the
  // smallest normal exponent, which is what makes them fall out of the same
  // datapath with no special case (F1).
  logic signed [8:0] xea, xeb, xec;
  assign xea = (ea == 5'd0) ? -9'sd14 : ($signed({4'b0000, ea}) - 9'sd15);
  assign xeb = (eb == 5'd0) ? -9'sd14 : ($signed({4'b0000, eb}) - 9'sd15);
  assign xec = (ec == 5'd0) ? -9'sd14 : ($signed({4'b0000, ec}) - 9'sd15);

  // ---------------------------------------------------------------------------
  // Exact product and exact alignment
  // ---------------------------------------------------------------------------
  logic [21:0] sigp;
  logic        sgn_p;
  assign sigp  = sga * sgb;
  assign sgn_p = sa ^ sb;

  // Grid LSB exponents: product 2^ep, addend 2^ecl, with ep in [-48,10] and
  // ecl in [-24,5].
  logic signed [8:0] ep, ecl;
  assign ep  = xea + xeb - 9'sd20;
  assign ecl = xec - 9'sd10;

  logic [6:0] shp, shc;
  assign shp = 7'(unsigned'(ep  + 9'sd48));   // [0, 58]
  assign shc = 7'(unsigned'(ecl + 9'sd48));   // [24, 53]

  logic [WA-1:0] pext, cext;
  assign pext = {{(WA-22){1'b0}}, sigp} << shp;
  assign cext = {{(WA-11){1'b0}}, sgc}  << shc;

  logic signed [WA:0] pterm, cterm, ssum;
  assign pterm = sgn_p ? -$signed({1'b0, pext}) : $signed({1'b0, pext});
  assign cterm = sc    ? -$signed({1'b0, cext}) : $signed({1'b0, cext});
  assign ssum  = pterm + cterm;

  logic          neg;
  logic [WA-1:0] mag;
  assign neg = ssum[WA];
  assign mag = WA'(unsigned'(neg ? -ssum : ssum));   // |sum| < 2^33, nothing is lost here

  // ---------------------------------------------------------------------------
  // Leading-one search, as a 6-level unrolled select (never a per-bit loop).
  // nt is mag left-aligned so that its MSB sits at bit 95; lz is the shift used.
  // ---------------------------------------------------------------------------
  logic [95:0] nt;
  logic [6:0]  lz;

  always_comb begin
    nt = {12'b0, mag};
    lz = 7'd0;
    if (nt[95:48] == 48'd0) begin lz = lz + 7'd48; nt = nt << 48; end
    if (nt[95:72] == 24'd0) begin lz = lz + 7'd24; nt = nt << 24; end
    if (nt[95:84] == 12'd0) begin lz = lz + 7'd12; nt = nt << 12; end
    if (nt[95:90] ==  6'd0) begin lz = lz + 7'd6;  nt = nt << 6;  end
    if (nt[95:93] ==  3'd0) begin lz = lz + 7'd3;  nt = nt << 3;  end
    if (!nt[95]) begin
      if (nt[94]) begin lz = lz + 7'd1; nt = nt << 1; end
      else        begin lz = lz + 7'd2; nt = nt << 2; end
    end
  end

  // Index of the exact sum's leading one on the grid; value = 2^(msbi-48) scale.
  logic [6:0] msbi;
  logic       norm_path;
  assign msbi      = 7'd95 - lz;
  assign norm_path = (msbi >= 7'd34);   // result exponent >= -14, i.e. normal

  // ---------------------------------------------------------------------------
  // Round-to-11-bits. In the subnormal path the retained LSB is pinned to the
  // grid position of 2^-24, so the result is a correctly rounded subnormal
  // rather than a flush (F1, A6).
  // ---------------------------------------------------------------------------
  logic [10:0] keep;
  logic        rbit, sbit;

  always_comb begin
    if (norm_path) begin
      keep = nt[95:85];
      rbit = nt[84];
      sbit = |nt[83:0];
    end else begin
      keep = {1'b0, mag[33:24]};
      rbit = mag[23];
      sbit = |mag[22:0];
    end
  end

  logic inexact;
  assign inexact = rbit | sbit;

  logic inc;
  always_comb begin
    case (rnd_i)
      RNE:     inc = rbit & (sbit | keep[0]);
      RTZ:     inc = 1'b0;
      RDN:     inc =  neg & inexact;
      RUP:     inc = ~neg & inexact;
      RMM:     inc = rbit;
      default: inc = 1'b0;              // 5-7 unexercised (F3)
    endcase
  end

  logic [11:0] keep_r;
  assign keep_r = {1'b0, keep} + {11'b0, inc};

  logic [7:0] expf, expf_adj;
  assign expf     = {1'b0, msbi} - 8'd33;                    // biased exponent
  assign expf_adj = keep_r[11] ? (expf + 8'd1) : expf;       // rounding carry

  logic ovf_range;
  assign ovf_range = norm_path && (expf_adj >= 8'd31);

  // A5: the delivered value above the range is tabulated per mode and sign.
  logic [15:0] ovf_val;
  always_comb begin
    case (rnd_i)
      RTZ:     ovf_val = neg ? 16'hFBFF : 16'h7BFF;
      RDN:     ovf_val = neg ? 16'hFC00 : 16'h7BFF;
      RUP:     ovf_val = neg ? 16'hFBFF : 16'h7C00;
      default: ovf_val = neg ? 16'hFC00 : 16'h7C00;          // RNE, RMM
    endcase
  end

  // In the subnormal path keep_r[10] set means rounding carried up to 2^-14,
  // so the delivered value is the smallest normal and is no longer tiny.
  logic [15:0] norm_res, sub_res;
  assign norm_res = {neg, expf_adj[4:0], keep_r[11] ? 10'd0 : keep_r[9:0]};
  assign sub_res  = {neg, 4'd0, keep_r[10:0]};

  // A8: sign of an exact zero.
  logic sign_zero;
  assign sign_zero = ((sigp == 22'd0) && (sgc == 11'd0) && (sgn_p == sc))
                       ? sgn_p : (rnd_i == RDN);

  // ---------------------------------------------------------------------------
  // Non-finite handling (A9) and final select
  // ---------------------------------------------------------------------------
  logic inv_mul, any_nan, prod_inf, inv_add;
  assign inv_mul  = (a_inf & b_zero) | (b_inf & a_zero);
  assign any_nan  = a_nan | b_nan | c_nan;
  assign prod_inf = (a_inf | b_inf) & ~inv_mul & ~(a_nan | b_nan);
  assign inv_add  = prod_inf & c_inf & (sgn_p != sc);

  logic [15:0] res;
  logic        nv, ofl, ufl, nx;

  always_comb begin
    res = QNAN;
    nv  = 1'b0;
    ofl = 1'b0;
    ufl = 1'b0;
    nx  = 1'b0;

    if (inv_mul) begin                       // infinity * zero
      nv  = 1'b1;
    end else if (any_nan) begin              // NaN operand: no flag raised
      res = QNAN;
    end else if (inv_add) begin              // (+inf) + (-inf)
      nv  = 1'b1;
    end else if (prod_inf) begin
      res = {sgn_p, 5'd31, 10'd0};
    end else if (c_inf) begin
      res = {sc, 5'd31, 10'd0};
    end else if (ssum == '0) begin
      res = {sign_zero, 15'd0};
    end else if (ovf_range) begin
      res = ovf_val;
      ofl = 1'b1;
      nx  = 1'b1;
    end else if (norm_path) begin
      res = norm_res;
      nx  = inexact;
    end else begin
      res = sub_res;
      nx  = inexact;
      ufl = inexact & ~keep_r[10];           // A7: tiny AND inexact only
    end
  end

  assign z_o     = res;
  assign flags_o = {nv, 1'b0, ofl, ufl, nx};  // DZ never raised (V3)

endmodule
/* verilator lint_on DECLFILENAME */


// -----------------------------------------------------------------------------
// The array.
// -----------------------------------------------------------------------------
module fp16_gemm_array #(
  parameter int unsigned HEIGHT = 8,
  parameter int unsigned WIDTH  = 8
) (
  input  logic                                  clk_i,
  input  logic                                  rst_ni,
  input  logic [WIDTH-1:0][HEIGHT-1:0][15:0]    x_i,
  input  logic [HEIGHT-1:0][15:0]               w_i,
  input  logic [WIDTH-1:0][15:0]                y_i,
  output logic [WIDTH-1:0][15:0]                z_o,
  input  logic [2:0]                            rnd_i,
  input  logic                                  accumulate_i,
  input  logic [WIDTH-1:0]                      row_clk_gate_en_i,
  input  logic                                  reg_enable_i,
  input  logic                                  flush_i,
  output logic [WIDTH-1:0][HEIGHT-1:0][4:0]     status_o
);

  localparam int unsigned D = 4;   // L1: contractual, not an implementation choice

  for (genvar r = 0; r < int'(WIDTH); r++) begin : g_row

    // A1: an enabled tick for this row. C2/C4: flush outranks reg_enable_i but
    // not the row clock gate, so a gated row is untouched by either.
    logic row_en, row_clr;
    assign row_en  = reg_enable_i & row_clk_gate_en_i[r];
    assign row_clr = flush_i      & row_clk_gate_en_i[r];

    logic [15:0] stage_out [0:HEIGHT-1];        // combinational FMA results
    logic [4:0]  stage_flg [0:HEIGHT-1];
    logic [15:0] acc_pipe  [0:HEIGHT-2][0:D-1]; // D registers between stages
    logic [15:0] out_pipe  [0:1];               // 2 registers to z_o
    logic [15:0] fb_reg;                        // the extra tick of C3
    logic [4:0]  flg_pipe  [0:HEIGHT-1][0:1];   // A10: 2 enabled ticks, flat

    for (genvar k = 0; k < int'(HEIGHT); k++) begin : g_stage
      logic [15:0] c_in;

      if (k == 0) begin : g_seed
        // C3: accumulate replaces the bias with this row's own z_o, one
        // register further back than an operand presented at the same edge.
        assign c_in = accumulate_i ? fb_reg : y_i[r];
      end else begin : g_link
        assign c_in = acc_pipe[k-1][D-1];
      end

      fp16_fma u_fma (
        .a_i     (x_i[r][k]),
        .b_i     (w_i[k]),      // broadcast to every row
        .c_i     (c_in),
        .rnd_i   (rnd_i),
        .z_o     (stage_out[k]),
        .flags_o (stage_flg[k])
      );

      assign status_o[r][k] = flg_pipe[k][1];
    end

    always_ff @(posedge clk_i or negedge rst_ni) begin
      if (!rst_ni) begin                    // V2: asynchronous, reaches gated rows
        for (int unsigned kk = 0; kk < HEIGHT-1; kk++) begin
          for (int unsigned jj = 0; jj < D; jj++) acc_pipe[kk][jj] <= 16'h0000;
        end
        out_pipe[0] <= 16'h0000;
        out_pipe[1] <= 16'h0000;
        fb_reg      <= 16'h0000;
        for (int unsigned kk = 0; kk < HEIGHT; kk++) begin
          flg_pipe[kk][0] <= 5'h00;
          flg_pipe[kk][1] <= 5'h00;
        end
      end else if (row_clr) begin           // C2: flush, but only a clocked row
        for (int unsigned kk = 0; kk < HEIGHT-1; kk++) begin
          for (int unsigned jj = 0; jj < D; jj++) acc_pipe[kk][jj] <= 16'h0000;
        end
        out_pipe[0] <= 16'h0000;
        out_pipe[1] <= 16'h0000;
        fb_reg      <= 16'h0000;
        for (int unsigned kk = 0; kk < HEIGHT; kk++) begin
          flg_pipe[kk][0] <= 5'h00;
          flg_pipe[kk][1] <= 5'h00;
        end
      end else if (row_en) begin            // C1, C4
        for (int unsigned kk = 0; kk < HEIGHT-1; kk++) begin
          acc_pipe[kk][0] <= stage_out[kk];
          for (int unsigned jj = 1; jj < D; jj++) begin
            acc_pipe[kk][jj] <= acc_pipe[kk][jj-1];
          end
        end
        out_pipe[0] <= stage_out[HEIGHT-1];
        out_pipe[1] <= out_pipe[0];
        fb_reg      <= out_pipe[1];
        for (int unsigned kk = 0; kk < HEIGHT; kk++) begin
          flg_pipe[kk][0] <= stage_flg[kk];
          flg_pipe[kk][1] <= flg_pipe[kk][0];
        end
      end
    end

    assign z_o[r] = out_pipe[1];

  end

endmodule