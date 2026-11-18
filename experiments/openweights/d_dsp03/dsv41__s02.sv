// =============================================================================
// fp_multifmt_fma.sv
// =============================================================================
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

  // ---------------------------------------------------------------------------
  // Handshake: fully combinational, conformant to L4
  // ---------------------------------------------------------------------------
  assign in_ready_o  = out_ready_i;
  assign out_valid_o = in_valid_i;

  // ---------------------------------------------------------------------------
  // Lane instantiation
  // ---------------------------------------------------------------------------
  localparam int MAX_LANES = WIDTH / 16;  // 2 or 4

  logic [31:0] lane_res   [0:MAX_LANES-1];
  logic [4:0]  lane_flags [0:MAX_LANES-1];
  logic        lane_active[0:MAX_LANES-1];

  genvar k;
  generate
    for (k = 0; k < MAX_LANES; k++) begin : gen_lanes
      logic [31:0] a_lane, b_lane, c_lane;
      logic [36:0] lane_out;

      always_comb begin
        a_lane = 32'b0;
        b_lane = 32'b0;
        c_lane = 32'b0;
        if (fmt_i == 2'd0) begin
          if (k*32 < WIDTH) begin
            a_lane = a_i[k*32 +: 32];
            b_lane = b_i[k*32 +: 32];
            c_lane = c_i[k*32 +: 32];
          end
        end else begin
          if (k*16 < WIDTH) begin
            a_lane = {16'b0, a_i[k*16 +: 16]};
            b_lane = {16'b0, b_i[k*16 +: 16]};
            c_lane = {16'b0, c_i[k*16 +: 16]};
          end
        end
      end

      always_comb begin
        if (fmt_i == 2'd0) begin
          lane_active[k] = vec_i ? (k < WIDTH/32) : (k == 0);
        end else begin
          lane_active[k] = vec_i ? (k < WIDTH/16) : (k == 0);
        end
      end

      assign lane_out = fma_lane(fmt_i, a_lane, b_lane, c_lane, rnd_i);
      assign lane_res[k]   = lane_out[31:0];
      assign lane_flags[k] = lane_out[36:32];
    end
  endgenerate

  // ---------------------------------------------------------------------------
  // Assemble result and flags
  // ---------------------------------------------------------------------------
  always_comb begin
    result_o = {WIDTH{1'b1}};
    flags_o  = 5'b0;
    for (int i = 0; i < MAX_LANES; i = i + 1) begin
      if (lane_active[i]) begin
        if (fmt_i == 2'd0) begin
          result_o[i*32 +: 32] = lane_res[i];
        end else begin
          result_o[i*16 +: 16] = lane_res[i][15:0];
        end
        flags_o = flags_o | lane_flags[i];
      end
    end
  end

  // ---------------------------------------------------------------------------
  // Per-lane fused multiply-add
  // ---------------------------------------------------------------------------
  function automatic logic [36:0] fma_lane(
    input logic [1:0]  fmt,
    input logic [31:0] a, b, c,
    input logic [2:0]  rnd
  );
    // All declarations at the top (T2)
    logic [31:0] av, bv, cv;
    logic [31:0] res;
    logic [4:0]  flags;
    int E, M, B, p, SHIFT_L;
    logic [31:0] exp_all_ones;
    logic sa, sb, sc, sp;
    logic [31:0] ea, eb, ec;
    logic [31:0] fa, fb, fc;
    logic a_nan, b_nan, c_nan, a_snan, b_snan, c_snan, a_qnan, b_qnan, c_qnan;
    logic a_inf, b_inf, c_inf;
    logic a_zero, b_zero, c_zero;
    logic [31:0] sig_a, sig_b, sig_c;
    int scale_a, scale_b, scale_c;
    logic [63:0] sig_p;
    int scale_p;
    logic sign_p, sign_c;
    logic invalid, qnan_present;
    logic [31:0] canonical_nan;
    logic [129:0] L_val, S_val, mag;
    logic signed [129:0] L_signed, S_signed, sum_s;
    logic [129:0] L_sig, S_sig;
    logic L_sign, S_sign;
    int E_max, E_min, d;
    logic [129:0] S_aligned;
    logic sticky;
    logic delta_sign;
    int msb_pos, i;
    int E_lsb, exp_exact, E_min_norm, E_sub_lsb, E_norm_lsb, target_lsb_exp;
    int shift_amt, shift_right;
    logic [129:0] q, r, half, q_rounded;
    logic r_gt_half, r_eq_half, r_lt_half;
    logic exact_gt_half, exact_lt_half, exact_eq_half, exact_nonzero;
    logic inc;
    int exp_unb, exp_field;
    logic [31:0] frac;
    logic overflow, underflow, inexact;
    logic sign_res;
    int max_exp;
    int msb_q;

    // Defaults
    res   = 32'b0;
    flags = 5'b0;

    // Format parameters
    case (fmt)
      2'd0: begin E = 8; M = 23; B = 127; end
      2'd1: begin E = 5; M = 10; B = 15;  end
      2'd2: begin E = 8; M = 7;  B = 127; end
      default: begin E = 8; M = 23; B = 127; end
    endcase
    p = M + 1;
    SHIFT_L = 128 - 2*p;
    exp_all_ones = (1 << E) - 1;
    max_exp = (1 << E) - 1;

    // Mask operands
    if (fmt == 2'd0) begin
      av = a; bv = b; cv = c;
    end else begin
      av = {16'b0, a[15:0]};
      bv = {16'b0, b[15:0]};
      cv = {16'b0, c[15:0]};
    end

    // Field extraction
    sa = av[E+M];
    ea = (av >> M) & exp_all_ones;
    fa = av & ((1 << M) - 1);
    sb = bv[E+M];
    eb = (bv >> M) & exp_all_ones;
    fb = bv & ((1 << M) - 1);
    sc = cv[E+M];
    ec = (cv >> M) & exp_all_ones;
    fc = cv & ((1 << M) - 1);

    // Special values
    a_nan = (ea == exp_all_ones) && (fa != 0);
    b_nan = (eb == exp_all_ones) && (fb != 0);
    c_nan = (ec == exp_all_ones) && (fc != 0);
    a_inf = (ea == exp_all_ones) && (fa == 0);
    b_inf = (eb == exp_all_ones) && (fb == 0);
    c_inf = (ec == exp_all_ones) && (fc == 0);
    a_zero = (ea == 0) && (fa == 0);
    b_zero = (eb == 0) && (fb == 0);
    c_zero = (ec == 0) && (fc == 0);
    a_snan = a_nan && (fa[M-1] == 0);
    b_snan = b_nan && (fb[M-1] == 0);
    c_snan = c_nan && (fc[M-1] == 0);
    a_qnan = a_nan && (fa[M-1] == 1);
    b_qnan = b_nan && (fb[M-1] == 1);
    c_qnan = c_nan && (fc[M-1] == 1);

    // Canonical NaN
    case (fmt)
      2'd0: canonical_nan = 32'h7FC00000;
      2'd1: canonical_nan = 32'h00007E00;
      2'd2: canonical_nan = 32'h00007FC0;
      default: canonical_nan = 32'h7FC00000;
    endcase

    // Invalid detection
    invalid = a_snan || b_snan || c_snan;
    sp = sa ^ sb;
    sign_p = sp;
    sign_c = sc;
    if ((a_zero && b_inf) || (a_inf && b_zero)) invalid = 1;
    if ((a_inf || b_inf) && !(a_zero || b_zero)) begin
      if (c_inf && (sp != sc)) invalid = 1;
    end

    if (invalid) begin
      res   = canonical_nan;
      flags = 5'b10000;
      return {flags, res};
    end

    qnan_present = a_qnan || b_qnan || c_qnan;
    if (qnan_present) begin
      res   = canonical_nan;
      flags = 5'b0;
      return {flags, res};
    end

    // Infinity cases
    if (a_inf || b_inf || c_inf) begin
      if ((a_inf || b_inf) && !(a_zero || b_zero)) begin
        sign_res = sp;
        res = {sign_res, exp_all_ones[E-1:0], {M{1'b0}}};
        flags = 5'b0;
        return {flags, res};
      end else if (c_inf) begin
        sign_res = sc;
        res = {sign_res, exp_all_ones[E-1:0], {M{1'b0}}};
        flags = 5'b0;
        return {flags, res};
      end
    end

    // Decode finite operands
    if (ea == 0) begin
      sig_a = fa;
      scale_a = 1 - B - M;
    end else begin
      sig_a = (1 << M) | fa;
      scale_a = ea - B - M;
    end
    if (eb == 0) begin
      sig_b = fb;
      scale_b = 1 - B - M;
    end else begin
      sig_b = (1 << M) | fb;
      scale_b = eb - B - M;
    end
    if (ec == 0) begin
      sig_c = fc;
      scale_c = 1 - B - M;
    end else begin
      sig_c = (1 << M) | fc;
      scale_c = ec - B - M;
    end

    sig_p = sig_a * sig_b;
    scale_p = scale_a + scale_b;
    sign_p = sa ^ sb;
    sign_c = sc;

    // Determine larger term
    if (scale_p >= scale_c) begin
      L_sig = sig_p;
      L_sign = sign_p;
      E_max = scale_p;
      S_sig = sig_c;
      S_sign = sign_c;
      E_min = scale_c;
    end else begin
      L_sig = sig_c;
      L_sign = sign_c;
      E_max = scale_c;
      S_sig = sig_p;
      S_sign = sign_p;
      E_min = scale_p;
    end
    d = E_max - E_min;

    L_val = L_sig << SHIFT_L;
    sticky = 0;
    if (d <= SHIFT_L) begin
      S_aligned = S_sig << (SHIFT_L - d);
    end else begin
      shift_right = d - SHIFT_L;
      if (shift_right >= 130) begin
        S_aligned = 0;
        sticky = (S_sig != 0);
      end else begin
        S_aligned = S_sig >> shift_right;
        sticky = (S_sig & ((1 << shift_right) - 1)) != 0;
      end
    end

    L_signed = L_sign ? -$signed({1'b0, L_val}) : $signed({1'b0, L_val});
    S_signed = S_sign ? -$signed({1'b0, S_aligned}) : $signed({1'b0, S_aligned});
    sum_s = L_signed + S_signed;

    if (sum_s[129]) begin
      mag = ~sum_s + 1;
      sign_res = 1'b1;
    end else begin
      mag = sum_s;
      sign_res = 1'b0;
    end

    if (mag == 0) begin
      if (sign_p == sign_c) sign_res = sign_p;
      else sign_res = (rnd == 3'd2) ? 1'b1 : 1'b0;
      res = {sign_res, {E+M{1'b0}}};
      flags = 5'b0;
      return {flags, res};
    end

    // Find MSB of mag
    msb_pos = 0;
    for (i = 0; i < 130; i = i + 1) begin
      if (mag[i]) msb_pos = i;
    end

    E_lsb = E_max - SHIFT_L;
    exp_exact = E_lsb + msb_pos;
    E_min_norm = 1 - B;
    E_sub_lsb = E_min_norm - M;
    E_norm_lsb = exp_exact - M;
    target_lsb_exp = (E_norm_lsb > E_sub_lsb) ? E_norm_lsb : E_sub_lsb;
    shift_amt = E_lsb - target_lsb_exp;

    delta_sign = (sign_res == S_sign) ? 1'b1 : 1'b0;

    if (shift_amt >= 0) begin
      q = mag << shift_amt;
      r = 0;
      sticky = 0;
      delta_sign = 0;
      shift_right = 0;
      half = 0;
      r_gt_half = 0;
      r_eq_half = 1;
      r_lt_half = 0;
    end else begin
      shift_right = -shift_amt;
      if (shift_right >= 130) begin
        q = 0;
        if (shift_right == 130) begin
          half = {1'b1, 129'b0};
          r = mag;
          r_gt_half = (r > half);
          r_eq_half = (r == half);
          r_lt_half = (r < half);
        end else begin
          r = mag;
          r_gt_half = 0;
          r_eq_half = 0;
          r_lt_half = 1;
        end
        if (r == 0 && sticky && (delta_sign == 0)) begin
          q = q - 1;
          r = 130'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
          sticky = 1;
          delta_sign = 1;
          r_gt_half = 1;
          r_eq_half = 0;
          r_lt_half = 0;
        end
      end else begin
        q = mag >> shift_right;
        r = mag & ((1 << shift_right) - 1);
        half = (shift_right > 0) ? (1 << (shift_right-1)) : 0;
        r_gt_half = (r > half);
        r_eq_half = (r == half);
        r_lt_half = (r < half);
        if (r == 0 && sticky && (delta_sign == 0)) begin
          q = q - 1;
          r = (1 << shift_right) - 1;
          sticky = 1;
          delta_sign = 1;
          r_gt_half = 1;
          r_eq_half = 0;
          r_lt_half = 0;
        end
      end
    end

    exact_gt_half = r_gt_half || (r_eq_half && sticky && delta_sign);
    exact_lt_half = r_lt_half || (r_eq_half && sticky && !delta_sign);
    exact_eq_half = r_eq_half && !sticky;
    exact_nonzero = (r != 0) || sticky;

    inc = 0;
    case (rnd)
      3'd0: begin // RNE
        if (exact_gt_half) inc = 1;
        else if (exact_lt_half) inc = 0;
        else inc = q[0];
      end
      3'd1: inc = 0; // RTZ
      3'd2: begin // RDN
        if (sign_res == 1) inc = exact_nonzero;
        else inc = 0;
      end
      3'd3: begin // RUP
        if (sign_res == 0) inc = exact_nonzero;
        else inc = 0;
      end
      3'd4: begin // RMM
        if (exact_gt_half) inc = 1;
        else if (exact_lt_half) inc = 0;
        else inc = 1;
      end
      default: inc = 0;
    endcase

    q_rounded = q + inc;

    if (q_rounded == 0) begin
      res = {sign_res, {E+M{1'b0}}};
      flags = {1'b0, 1'b0, 1'b0, 1'b1, 1'b1};
      return {flags, res};
    end

    // Find MSB of q_rounded
    msb_q = 0;
    for (i = 0; i < 130; i = i + 1) begin
      if (q_rounded[i]) msb_q = i;
    end

    exp_unb = target_lsb_exp + msb_q;
    exp_field = exp_unb + B;

    if (msb_q > M) begin
      q_rounded = q_rounded >> (msb_q - M);
      exp_unb = exp_unb + (msb_q - M);
      exp_field = exp_unb + B;
      msb_q = M;
    end

    if (exp_field >= max_exp) begin
      res = {sign_res, exp_all_ones[E-1:0], {M{1'b0}}};
      flags = {1'b0, 1'b0, 1'b1, 1'b0, 1'b1};
      return {flags, res};
    end

    if (exp_field <= 0) begin
      frac = q_rounded[M-1:0];
      exp_field = 0;
      res = {sign_res, exp_field[E-1:0], frac};
      inexact = exact_nonzero;
      underflow = inexact && (exp_field == 0);
      flags = {1'b0, 1'b0, 1'b0, underflow, inexact};
      return {flags, res};
    end

    if (msb_q < M) begin
      q_rounded = q_rounded << (M - msb_q);
    end
    frac = q_rounded[M-1:0];
    exp_field = exp_unb + B;
    res = {sign_res, exp_field[E-1:0], frac};
    inexact = exact_nonzero;
    underflow = 0;
    overflow = 0;
    flags = {1'b0, 1'b0, overflow, underflow, inexact};
    return {flags, res};
  endfunction

endmodule
