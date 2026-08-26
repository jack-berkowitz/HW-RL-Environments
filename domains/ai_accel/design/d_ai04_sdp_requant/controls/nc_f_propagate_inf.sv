// nc_f_propagate_inf -- NEGATIVE CONTROL for d_ai04. NOT a submission.
//
// THE ONE CHANGE: infinity is propagated as infinity rather than clamped to FLT_MAX (F8).
//
// EXPECTED: fails ONLY the two infinity vectors. This is the IEEE-754-correct behaviour and the contract forbids it.
// A control that fails NOTHING means the clause is not checked. A control
// that fails EVERYTHING means the testbench cannot localise the defect and
// the clause is not isolated. Both are findings about the testbench.
// =============================================================================
// =============================================================================
// d_ai04 -- sdp_requant REFERENCE IMPLEMENTATION
//
// Built from spec/sdp_requant_iface.sv, which was itself built only from probe
// measurements against NV_NVDLA_SDP_CORE_Y_cvt. Every constant below traces to a
// row of MEASUREMENTS.md.
//
// THE REFERENCE IS AN ANCHOR, NOT A TARGET (G5). It is deliberately the SIMPLE
// conforming shape: combinational arithmetic feeding a two-slot output buffer.
// That is the minimum A2 and A3 permit -- the anchor itself holds three words --
// so a submission is free to be deeper, or to pipeline the multiply, and neither
// is penalised. Those are P3 choices.
// =============================================================================

module sdp_requant (
    input  logic         clk,
    input  logic         rst_n,

    input  logic [63:0]  in_data,
    input  logic         in_valid,
    output logic         in_ready,

    input  logic [ 1:0]  cfg_precision,
    input  logic [31:0]  cfg_offset,
    input  logic [15:0]  cfg_scale,
    input  logic [ 5:0]  cfg_truncate,
    input  logic         cfg_bypass,
    input  logic         cfg_nan_to_zero,

    output logic [127:0] out_data,
    output logic         out_valid,
    input  logic         out_ready
);

  // ---------------------------------------------------------------------------
  // INTEGER LANE (F3-F6)
  // ---------------------------------------------------------------------------
  // The widths here are DERIVED, per F5, and the derivation is the clause:
  //   x - cfg_offset  spans [-(2^31 + 32767), 2^31 + 32767], so 34 bits signed.
  //   times cfg_scale (|.| <= 32768) reaches 2^46 + 2^30, so 50 bits signed.
  // A 32-bit intermediate passes every small vector and fails the wide ones.
  //
  // ROUNDING IS DONE ON THE MAGNITUDE (F4). Round-half-up on |v| IS ties-away on
  // v, and the whole rule reduces to one bit: the remainder mag[t-1:0] is >= half
  // exactly when mag[t-1] is set. Doing it in the signed domain instead --
  // (v + (1 << (t-1))) >>> t -- is round-half-UP and wrong on every negative tie.
  function automatic logic [31:0] int_lane(
      input logic [15:0] x,
      input logic [31:0] offset,
      input logic [15:0] scale,
      input logic [ 5:0] trunc,
      input logic        bypass
  );
    logic signed [33:0] diff;
    logic signed [49:0] prod;
    logic signed [63:0] prod64;
    logic        [63:0] mag, q;
    logic               neg;
    logic signed [63:0] res;
    begin
      if (bypass) return {{16{x[15]}}, x};          // F6

      diff = $signed({{18{x[15]}}, x}) - $signed({{2{offset[31]}}, offset});
      prod = diff * $signed(scale);

      // WIDEN BY SIGN EXTENSION, NOT BY CONCATENATION. The first version wrote
      // {14'b0, prod}, which ZERO-extends a signed 50-bit product into 64 bits:
      // every negative product became a large positive one and the magnitude was
      // taken from the corrupted value. The testbench caught it on the first
      // negative tie and on 60 sweep words; it passed every non-negative vector.
      prod64 = $signed(prod);
      neg    = (prod64 < 64'sd0);
      mag    = neg ? 64'(-prod64) : 64'(prod64);

      q = mag >> trunc;
      if (trunc != 6'd0 && mag[trunc - 6'd1]) q = q + 64'd1;   // ties away

      res = neg ? -$signed(q) : $signed(q);

      // F5: saturation is LAST, after the shift and the rounding.
      if (res >  64'sh000000007FFFFFFF) return 32'h7FFFFFFF;
      if (res < -64'sh0000000080000000) return 32'h80000000;
      return res[31:0];
    end
  endfunction

  // ---------------------------------------------------------------------------
  // FLOAT LANE (F7-F9): exact binary16 -> binary32
  // ---------------------------------------------------------------------------
  // The subnormal branch is the second derived quantity. Every binary16
  // subnormal is a NORMAL binary32, so the field-copy that works for normals is
  // wrong here: the mantissa must be normalised and the exponent adjusted by the
  // leading-zero count. Checked against 0x0001 -> 0x33800000 (2^-24 exactly).
  function automatic logic [31:0] flt_lane(
      input logic [15:0] x,
      input logic        nan_to_zero
  );
    logic        sgn;
    logic [ 4:0] ex;
    logic [ 9:0] mn;
    logic [ 3:0] lz;
    logic [ 9:0] shifted;
    begin
      sgn = x[15];
      ex  = x[14:10];
      mn  = x[9:0];

      if (ex == 5'h1F) begin
        if (mn == 10'd0)
          return {sgn, 8'hFF, 23'h0};                      // propagate infinity
        else if (nan_to_zero)
          return 32'h0000_0000;                            // F9, NaN only
        else
          return {sgn, 8'hFF, 13'b0, mn};                  // F9: payload low
      end

      if (ex == 5'd0) begin
        if (mn == 10'd0) return {sgn, 31'b0};              // signed zero

        // leading zeros of the 10-bit mantissa
        lz = 4'd0;
        for (int i = 9; i >= 0; i--) begin
          if (mn[i]) break;
          lz = lz + 4'd1;
        end
        // the set MSB sits at bit (9-lz); dropping it leaves lz+1 of left shift
        shifted = mn << (lz + 4'd1);
        // value = mn * 2^-24 = 1.f * 2^(-15-lz)  ->  fp32 exponent 112 - lz
        return {sgn, 8'd112 - {4'b0, lz}, shifted, 13'b0};
      end

      // normal: bias 15 -> 127, so the exponent field gains 112
      return {sgn, {3'b0, ex} + 8'd112, mn, 13'b0};
    end
  endfunction

  // ---------------------------------------------------------------------------
  // The word: four independent lanes (F1), mode chosen per F2
  // ---------------------------------------------------------------------------
  logic [127:0] word_result;
  always_comb begin
    for (int k = 0; k < 4; k++) begin
      logic [15:0] x;
      x = in_data[16*k +: 16];
      word_result[32*k +: 32] = (cfg_precision == 2'd2)
                              ? flt_lane(x, cfg_nan_to_zero)
                              : int_lane(x, cfg_offset, cfg_scale, cfg_truncate, cfg_bypass);
    end
  end

  // ---------------------------------------------------------------------------
  // FLOW CONTROL (A1-A6): two result slots, and in_ready off a REGISTER
  // ---------------------------------------------------------------------------
  // in_ready is a function of occ_q alone. The path from out_ready to in_ready
  // therefore passes through a flop, which is what A2 requires. Reading
  // out_ready combinationally here would be smaller and would fail T5.
  logic [1:0]   occ_q;
  logic [127:0] slot_q [0:1];
  logic         wptr_q, rptr_q;

  wire accept = in_valid  && in_ready;
  wire emit   = out_valid && out_ready;

  assign in_ready  = (occ_q != 2'd2);
  assign out_valid = (occ_q != 2'd0);
  assign out_data  = slot_q[rptr_q];

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      occ_q  <= 2'd0;
      wptr_q <= 1'b0;
      rptr_q <= 1'b0;
      slot_q[0] <= 128'd0;
      slot_q[1] <= 128'd0;
    end else begin
      if (accept) begin
        slot_q[wptr_q] <= word_result;      // A5: config is sampled with the word
        wptr_q         <= ~wptr_q;
      end
      if (emit) rptr_q <= ~rptr_q;
      case ({accept, emit})
        2'b10:   occ_q <= occ_q + 2'd1;
        2'b01:   occ_q <= occ_q - 2'd1;
        default: occ_q <= occ_q;
      endcase
    end
  end

endmodule
