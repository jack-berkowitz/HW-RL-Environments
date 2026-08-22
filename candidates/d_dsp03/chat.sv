module fp_multifmt_fma #(
  parameter int unsigned WIDTH = 64
) (
  input  logic             clk_i,
  input  logic             rst_ni,

  input  logic             in_valid_i,
  output logic             in_ready_o,
  input  logic [1:0]       fmt_i,
  input  logic             vec_i,
  input  logic [WIDTH-1:0] a_i,
  input  logic [WIDTH-1:0] b_i,
  input  logic [WIDTH-1:0] c_i,
  input  logic [2:0]       rnd_i,

  output logic             out_valid_o,
  input  logic             out_ready_i,
  output logic [WIDTH-1:0] result_o,
  output logic [4:0]       flags_o
);

  localparam int EXACT_W = 448;

  function automatic logic round_increment(
    input logic       sign_v,
    input logic [2:0] rnd_v,
    input logic       rem_nz,
    input logic       rem_gt_half,
    input logic       rem_eq_half,
    input logic       lsb_v
  );
    logic inc;
    begin
      inc = 1'b0;
      case (rnd_v)
        3'd0: inc = rem_gt_half | (rem_eq_half & lsb_v); // RNE
        3'd1: inc = 1'b0;                               // RTZ
        3'd2: inc = sign_v & rem_nz;                    // RDN
        3'd3: inc = (~sign_v) & rem_nz;                 // RUP
        3'd4: inc = rem_gt_half | rem_eq_half;          // RMM
        default: inc = 1'b0;
      endcase
      round_increment = inc;
    end
  endfunction

  // Return value: {flags[4:0], result[31:0]}.
  // For 16-bit formats only result[15:0] is used by the caller.
  function automatic logic [36:0] fma_lane(
    input logic [31:0] aa,
    input logic [31:0] bb,
    input logic [31:0] cc,
    input logic [1:0]  fmt,
    input logic [2:0]  rnd
  );
    integer fw;
    integer ew;
    integer fb;
    integer bias;
    integer exp_max_field;
    integer min_norm_exp;
    integer max_norm_exp;
    integer e_sub;
    integer expa;
    integer expb;
    integer expc;
    integer ea_scale;
    integer eb_scale;
    integer ec_scale;
    integer ep_scale;
    integer common_scale;
    integer p_shift;
    integer c_shift;
    integer lead;
    integer real_exp;
    integer rshift;
    integer rounded_exp;
    integer exp_field_out;
    integer j;

    logic [63:0] ua;
    logic [63:0] ub;
    logic [63:0] uc;
    logic [63:0] frac_mask;
    logic [63:0] exp_mask;
    logic [63:0] fraca;
    logic [63:0] fracb;
    logic [63:0] fracc;
    logic [63:0] ma;
    logic [63:0] mb;
    logic [63:0] mc;
    logic [63:0] mp;
    logic [63:0] sig64;
    logic [63:0] enc64;
    logic [63:0] max_sig;

    logic sa;
    logic sb;
    logic sc;
    logic sp;
    logic sr;
    logic a_zero;
    logic b_zero;
    logic c_zero;
    logic a_inf;
    logic b_inf;
    logic c_inf;
    logic a_nan;
    logic b_nan;
    logic c_nan;
    logic a_snan;
    logic b_snan;
    logic c_snan;
    logic any_nan;
    logic invalid;
    logic zero_inf;
    logic prod_inf;
    logic opp_inf;
    logic inexact;
    logic rem_nz;
    logic rem_gt_half;
    logic rem_eq_half;
    logic inc;
    logic to_inf;

    logic [4:0] flags;
    logic [31:0] result;
    logic [EXACT_W-1:0] pwide;
    logic [EXACT_W-1:0] cwide;
    logic [EXACT_W-1:0] sumwide;
    logic [EXACT_W-1:0] truncwide;
    logic [EXACT_W-1:0] remwide;
    logic [EXACT_W-1:0] halfwide;

    begin
      fw = 32;
      ew = 8;
      fb = 23;
      bias = 127;

      if (fmt == 2'd1) begin
        fw = 16;
        ew = 5;
        fb = 10;
        bias = 15;
      end else if (fmt == 2'd2) begin
        fw = 16;
        ew = 8;
        fb = 7;
        bias = 127;
      end

      exp_max_field = (1 << ew) - 1;
      min_norm_exp = 1 - bias;
      max_norm_exp = (exp_max_field - 1) - bias;
      e_sub = 1 - bias - fb;

      frac_mask = (64'h1 << fb) - 1;
      exp_mask = (64'h1 << ew) - 1;

      ua = {32'b0, aa};
      ub = {32'b0, bb};
      uc = {32'b0, cc};

      sa = ua[fw-1];
      sb = ub[fw-1];
      sc = uc[fw-1];
      sp = sa ^ sb;

      expa = (ua >> fb) & exp_mask;
      expb = (ub >> fb) & exp_mask;
      expc = (uc >> fb) & exp_mask;

      fraca = ua & frac_mask;
      fracb = ub & frac_mask;
      fracc = uc & frac_mask;

      a_zero = (expa == 0) && (fraca == 0);
      b_zero = (expb == 0) && (fracb == 0);
      c_zero = (expc == 0) && (fracc == 0);

      a_inf = (expa == exp_max_field) && (fraca == 0);
      b_inf = (expb == exp_max_field) && (fracb == 0);
      c_inf = (expc == exp_max_field) && (fracc == 0);

      a_nan = (expa == exp_max_field) && (fraca != 0);
      b_nan = (expb == exp_max_field) && (fracb != 0);
      c_nan = (expc == exp_max_field) && (fracc != 0);

      a_snan = a_nan && ((fraca & (64'h1 << (fb-1))) == 0);
      b_snan = b_nan && ((fracb & (64'h1 << (fb-1))) == 0);
      c_snan = c_nan && ((fracc & (64'h1 << (fb-1))) == 0);

      any_nan = a_nan | b_nan | c_nan;

      zero_inf =
          (a_zero & b_inf) |
          (a_inf  & b_zero);

      prod_inf =
          (a_inf | b_inf) &
          (~a_nan) &
          (~b_nan) &
          (~zero_inf);

      opp_inf =
          prod_inf &
          c_inf &
          (sp != sc);

      invalid =
          a_snan |
          b_snan |
          c_snan |
          zero_inf |
          opp_inf;

      flags = 5'b0;
      result = 32'b0;
      enc64 = 64'b0;

      if (invalid) begin
        // Canonical quiet NaN.
        enc64 = (64'h1 * exp_max_field) << fb;
        enc64 = enc64 | (64'h1 << (fb-1));
        result = enc64[31:0];
        flags[4] = 1'b1;
      end else if (any_nan) begin
        // Canonical quiet NaN, but no NV for quiet-NaN propagation alone.
        enc64 = (64'h1 * exp_max_field) << fb;
        enc64 = enc64 | (64'h1 << (fb-1));
        result = enc64[31:0];
      end else if (prod_inf) begin
        enc64 = (64'h1 * exp_max_field) << fb;
        if (sp)
          enc64 = enc64 | (64'h1 << (fw-1));
        result = enc64[31:0];
      end else if (c_inf) begin
        enc64 = (64'h1 * exp_max_field) << fb;
        if (sc)
          enc64 = enc64 | (64'h1 << (fw-1));
        result = enc64[31:0];
      end else begin

        // Represent every finite operand exactly as
        //
        //      sign * integer_significand * 2^scale
        //
        // including subnormals.

        if (expa == 0) begin
          ma = fraca;
          ea_scale = e_sub;
        end else begin
          ma = (64'h1 << fb) | fraca;
          ea_scale = expa - bias - fb;
        end

        if (expb == 0) begin
          mb = fracb;
          eb_scale = e_sub;
        end else begin
          mb = (64'h1 << fb) | fracb;
          eb_scale = expb - bias - fb;
        end

        if (expc == 0) begin
          mc = fracc;
          ec_scale = e_sub;
        end else begin
          mc = (64'h1 << fb) | fracc;
          ec_scale = expc - bias - fb;
        end

        // Exact product. 24 x 24 significant bits is the widest case,
        // so 64 bits is sufficient without any product rounding.
        mp = ma * mb;
        ep_scale = ea_scale + eb_scale;

        // Align product and addend to a common exact binary scale.
        if (ep_scale < ec_scale)
          common_scale = ep_scale;
        else
          common_scale = ec_scale;

        p_shift = ep_scale - common_scale;
        c_shift = ec_scale - common_scale;

        pwide = {{(EXACT_W-64){1'b0}}, mp};
        cwide = {{(EXACT_W-64){1'b0}}, mc};

        pwide = pwide << p_shift;
        cwide = cwide << c_shift;

        // Exact signed addition without a two's-complement precision loss.
        sumwide = {EXACT_W{1'b0}};
        sr = 1'b0;

        if (sp == sc) begin
          sumwide = pwide + cwide;
          sr = sp;
        end else if (pwide > cwide) begin
          sumwide = pwide - cwide;
          sr = sp;
        end else if (cwide > pwide) begin
          sumwide = cwide - pwide;
          sr = sc;
        end else begin
          sumwide = {EXACT_W{1'b0}};
          sr = (rnd == 3'd2);
        end

        // Exact zero sign.
        if (sumwide == {EXACT_W{1'b0}}) begin
          if (sp == sc)
            sr = sp;
          else
            sr = (rnd == 3'd2);

          enc64 = 64'b0;
          if (sr)
            enc64 = 64'h1 << (fw-1);

          result = enc64[31:0];
        end else begin

          // Constant-bound leading-one search.
          lead = -1;
          for (j = 0; j < EXACT_W; j = j + 1) begin
            if (sumwide[j])
              lead = j;
          end

          real_exp = common_scale + lead;
          inexact = 1'b0;
          sig64 = 64'b0;

          if (real_exp >= min_norm_exp) begin

            // Normal result candidate.
            // Keep fb+1 significand bits and round exactly once.
            rshift = lead - fb;

            truncwide = {EXACT_W{1'b0}};
            remwide = {EXACT_W{1'b0}};
            halfwide = {EXACT_W{1'b0}};
            rem_nz = 1'b0;
            rem_gt_half = 1'b0;
            rem_eq_half = 1'b0;
            inc = 1'b0;

            if (rshift > 0) begin
              truncwide = sumwide >> rshift;
              remwide = sumwide - (truncwide << rshift);

              halfwide[0] = 1'b1;
              halfwide = halfwide << (rshift - 1);

              rem_nz = |remwide;
              rem_gt_half = (remwide > halfwide);
              rem_eq_half = (remwide == halfwide);

              inc = round_increment(
                  sr,
                  rnd,
                  rem_nz,
                  rem_gt_half,
                  rem_eq_half,
                  truncwide[0]
              );

              sig64 = truncwide[63:0];

              if (inc)
                sig64 = sig64 + 1'b1;

              inexact = rem_nz;
            end else begin
              truncwide = sumwide << (-rshift);
              sig64 = truncwide[63:0];
              inexact = 1'b0;
            end

            rounded_exp = real_exp;

            // Rounding can carry out of the significand.
            if (sig64 >= (64'h1 << (fb+1))) begin
              sig64 = sig64 >> 1;
              rounded_exp = rounded_exp + 1;
            end

            if (rounded_exp > max_norm_exp) begin

              // IEEE overflow: OF and NX are both asserted.
              flags[2] = 1'b1;
              flags[0] = 1'b1;

              to_inf = 1'b0;

              case (rnd)
                3'd0: to_inf = 1'b1; // RNE
                3'd1: to_inf = 1'b0; // RTZ
                3'd2: to_inf = sr;   // RDN
                3'd3: to_inf = ~sr;  // RUP
                3'd4: to_inf = 1'b1; // RMM
                default: to_inf = 1'b0;
              endcase

              enc64 = 64'b0;

              if (to_inf) begin
                enc64 = (64'h1 * exp_max_field) << fb;
              end else begin
                // Largest finite number.
                exp_field_out = exp_max_field - 1;
                max_sig = frac_mask;
                enc64 = exp_field_out;
                enc64 = (enc64 << fb) | max_sig;
              end

              if (sr)
                enc64 = enc64 | (64'h1 << (fw-1));

              result = enc64[31:0];
            end else begin

              flags[0] = inexact;

              exp_field_out = rounded_exp + bias;
              enc64 = exp_field_out;
              enc64 =
                  (enc64 << fb) |
                  (sig64 & frac_mask);

              if (sr)
                enc64 = enc64 | (64'h1 << (fw-1));

              result = enc64[31:0];
            end

          end else begin

            // Subnormal result candidate.
            //
            // Quantize directly in units of the smallest subnormal.
            // This is also what makes tininess-after-rounding easy to
            // implement correctly.
            rshift = e_sub - common_scale;

            truncwide = {EXACT_W{1'b0}};
            remwide = {EXACT_W{1'b0}};
            halfwide = {EXACT_W{1'b0}};
            rem_nz = 1'b0;
            rem_gt_half = 1'b0;
            rem_eq_half = 1'b0;
            inc = 1'b0;

            if (rshift > 0) begin
              truncwide = sumwide >> rshift;
              remwide = sumwide - (truncwide << rshift);

              halfwide[0] = 1'b1;
              halfwide = halfwide << (rshift - 1);

              rem_nz = |remwide;
              rem_gt_half = (remwide > halfwide);
              rem_eq_half = (remwide == halfwide);

              inc = round_increment(
                  sr,
                  rnd,
                  rem_nz,
                  rem_gt_half,
                  rem_eq_half,
                  truncwide[0]
              );

              sig64 = truncwide[63:0];

              if (inc)
                sig64 = sig64 + 1'b1;

              inexact = rem_nz;
            end else begin
              truncwide = sumwide << (-rshift);
              sig64 = truncwide[63:0];
              inexact = 1'b0;
            end

            enc64 = 64'b0;

            if (sig64 >= (64'h1 << fb)) begin
              // Rounding carried the tiny exact value up to the
              // smallest normal. It is therefore NOT tiny after
              // rounding, so UF remains clear.
              enc64 = 64'h1 << fb;
              flags[0] = inexact;
            end else begin
              enc64 = sig64 & frac_mask;

              flags[0] = inexact;

              // Tininess is detected after rounding and underflow is
              // only raised when the result is also inexact.
              flags[1] = inexact;
            end

            if (sr)
              enc64 = enc64 | (64'h1 << (fw-1));

            result = enc64[31:0];
          end
        end
      end

      fma_lane = {flags, result};
    end
  endfunction

  integer k;
  logic [36:0] lane_tmp;
  logic [31:0] lane_a;
  logic [31:0] lane_b;
  logic [31:0] lane_c;

  // Fully combinational ready/valid implementation.
  //
  // If the downstream stalls, in_ready_o is low, so the upstream is
  // required to hold its valid payload stable. Consequently result_o,
  // flags_o and out_valid_o also remain stable until the result transfers.
  always_comb begin
    in_ready_o = rst_ni & out_ready_i;
    out_valid_o = rst_ni & in_valid_i;

    // Required NaN-boxing / all-ones fill above used scalar lanes.
    result_o = {WIDTH{1'b1}};
    flags_o = 5'b0;

    lane_tmp = 37'b0;
    lane_a = 32'b0;
    lane_b = 32'b0;
    lane_c = 32'b0;

    if (fmt_i == 2'd0) begin

      // FP32: WIDTH/32 possible lanes.
      for (k = 0; k < WIDTH/32; k = k + 1) begin
        if (vec_i || (k == 0)) begin
          lane_a = a_i[k*32 +: 32];
          lane_b = b_i[k*32 +: 32];
          lane_c = c_i[k*32 +: 32];

          lane_tmp =
              fma_lane(
                  lane_a,
                  lane_b,
                  lane_c,
                  2'd0,
                  rnd_i
              );

          result_o[k*32 +: 32] = lane_tmp[31:0];
          flags_o = flags_o | lane_tmp[36:32];
        end
      end

    end else begin

      // FP16/BF16: WIDTH/16 possible lanes.
      for (k = 0; k < WIDTH/16; k = k + 1) begin
        if (vec_i || (k == 0)) begin
          lane_a = 32'b0;
          lane_b = 32'b0;
          lane_c = 32'b0;

          lane_a[15:0] = a_i[k*16 +: 16];
          lane_b[15:0] = b_i[k*16 +: 16];
          lane_c[15:0] = c_i[k*16 +: 16];

          lane_tmp =
              fma_lane(
                  lane_a,
                  lane_b,
                  lane_c,
                  fmt_i,
                  rnd_i
              );

          result_o[k*16 +: 16] = lane_tmp[15:0];
          flags_o = flags_o | lane_tmp[36:32];
        end
      end
    end
  end

endmodule