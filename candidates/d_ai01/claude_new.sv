// =============================================================================
// fp16_gemm_array.sv -- implementation of the d_ai01 contract.
//
// ARCHITECTURE
//   One compute element (CE) per (row, stage). Each CE is a four-register
//   pipeline, so D = 4 falls out of the structure:
//
//     edge s   : A  <- {x*w significand product, exponent sum, classes,
//                       addend, rnd}         (multiplier runs BEFORE A, off
//                                             the primary inputs)
//     edge s+1 : M  <- align + add          (38-bit exact magnitude)
//     edge s+2 : R  <- normalise + round    (16-bit value, 4 flags)
//                      status_o = R.flags   -> A10: flags 2 ticks after sample
//     edge s+3 : P  <- R.value              (inter-stage register)
//                      stage k+1 samples P_k at s+4, z_o = P_{H-1}
//
//   => d(H-1) = 3, stages D = 4 apart, d(k) = 4(H-1-k)+3 (A3/L2/L3), and the
//      accumulate feedback reads the z_o REGISTER at stage 0's sampling edge,
//      i.e. dfb = d(0)+1 (C3).
//
//   The FMA is split so every register boundary sits where the datapath is
//   narrow enough to be cheap and every combinational segment is short:
//     seg0 (inputs -> A): decode + 11x11 multiply
//     seg1 (A -> M)     : addend decode, specials, align, add/sub, abs
//     seg2 (M -> R)     : limited normalisation, rounding, range, flags
//
// CONTROL
//   en  = reg_enable_i & row_clk_gate_en_i[r]           (A1, C1, C4)
//   clr = flush_i      & row_clk_gate_en_i[r]           (C2: beats reg_enable,
//                                                        loses to the gate)
//   Two per-row valid bits (vA, vM) are cleared by an enabled flush tick and
//   refill afterwards. M loads only when vA, R only when vM. On flush tick 1
//   both are still set, so R (status_o) updates normally; from tick 2 onward
//   R holds -- the C2 status suspension. z_o = P is forced to 0 on every
//   clocked flush edge. A third per-row bit (vR) records that R has held real
//   data since reset, so A/M/R data flops need no reset of their own.
//
// ARITHMETIC
//   Single rounding (A2/A4); subnormals in and out (F1); the A5/A6 range
//   tables; tininess detected AFTER rounding (unbounded exponent), UF only
//   when tiny AND inexact (A7); exact-zero sign rule (A8); canonical qNaN
//   0x7E00, NV for sNaN / inf*0 / inf-inf, none for qNaN (A9); DZ always 0.
//
// SYNTHESIS FRONTEND NOTES (T5)
//   No loops at all: rows and stages are generate constructs, and every
//   priority search is written as fixed straight-line logic. Every variable
//   is declared at module scope or at the top of its function.
// =============================================================================

module fp16_gemm_array #(
  parameter int unsigned HEIGHT = 8,
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

  for (genvar r = 0; r < WIDTH; r++) begin : g_row

    logic                    row_en;
    logic                    row_clr;
    logic                    v_a_q;   // A holds data sampled on a non-flush tick
    logic                    v_m_q;   // M holds data derived from such an A
    logic                    v_r_q;   // R has been loaded since reset
    logic [HEIGHT-1:0][15:0] p;       // stage outputs (P registers)
    logic [15:0]             bias;

    assign row_en  = reg_enable_i & row_clk_gate_en_i[r];
    assign row_clr = flush_i      & row_clk_gate_en_i[r];

    always_ff @(posedge clk_i or negedge rst_ni) begin
      if (!rst_ni) begin
        v_a_q <= 1'b0;
        v_m_q <= 1'b0;
        v_r_q <= 1'b0;
      end else if (row_en) begin
        v_a_q <= ~flush_i;
        v_m_q <= v_a_q & ~flush_i;
        v_r_q <= v_r_q | v_m_q;
      end
    end

    // C3: the row's own z_o replaces the bias while accumulate_i is high.
    assign bias   = accumulate_i ? p[HEIGHT-1] : y_i[r];
    assign z_o[r] = p[HEIGHT-1];

    for (genvar k = 0; k < HEIGHT; k++) begin : g_stage

      logic [15:0] addend;
      logic [3:0]  flags;   // {NV, OF, UF, NX}

      if (k == 0) begin : g_first
        assign addend = bias;
      end else begin : g_next
        assign addend = p[k-1];
      end

      fp16_gemm_array_ce u_ce (
        .clk_i   ( clk_i     ),
        .rst_ni  ( rst_ni    ),
        .en_i    ( row_en    ),
        .clr_i   ( row_clr   ),
        .ld_m_i  ( v_a_q     ),
        .ld_r_i  ( v_m_q     ),
        .ld_p_i  ( v_r_q     ),
        .x_i     ( x_i[r][k] ),
        .w_i     ( w_i[k]    ),
        .c_i     ( addend    ),
        .rnd_i   ( rnd_i     ),
        .p_o     ( p[k]      ),
        .flags_o ( flags     )
      );

      // V3: {NV, DZ, OF, UF, NX}; DZ is never raised.
      assign status_o[r][k] = {flags[3], 1'b0, flags[2:0]};
    end
  end

endmodule


// =============================================================================
// One compute element: fma(x, w, c) under rnd, four registers deep.
// =============================================================================
module fp16_gemm_array_ce (
  input  logic        clk_i,
  input  logic        rst_ni,
  input  logic        en_i,     // enabled tick for this row
  input  logic        clr_i,    // flush on a clocked edge: zero P
  input  logic        ld_m_i,   // row valid: M may load
  input  logic        ld_r_i,   // row valid: R may load
  input  logic        ld_p_i,   // row valid: P may load
  input  logic [15:0] x_i,
  input  logic [15:0] w_i,
  input  logic [15:0] c_i,
  input  logic [2:0]  rnd_i,
  output logic [15:0] p_o,
  output logic [3:0]  flags_o   // {NV, OF, UF, NX}
);

  // rnd_i encoding (F3)
  localparam logic [2:0] RNE = 3'd0;
  localparam logic [2:0] RTZ = 3'd1;
  localparam logic [2:0] RDN = 3'd2;
  localparam logic [2:0] RUP = 3'd3;
  localparam logic [2:0] RMM = 3'd4;

  // Rounding class carried past seg1, where the result sign is known:
  //   NEVER : RTZ, RDN on +, RUP on -   (magnitude never rounds up)
  //   UP    : RDN on -, RUP on +        (magnitude rounds up if inexact)
  //   NEAR  : RNE
  //   AWAY  : RMM
  localparam logic [1:0] CL_NEVER = 2'b00;
  localparam logic [1:0] CL_UP    = 2'b01;
  localparam logic [1:0] CL_NEAR  = 2'b10;
  localparam logic [1:0] CL_AWAY  = 2'b11;

  // ---------------------------------------------------------------------------
  // seg0: decode x, w; significand product. Inputs -> A.
  // ---------------------------------------------------------------------------
  logic        x_ez, x_em, x_fz, w_ez, w_em, w_fz;
  logic        x_zero, x_inf, x_nan, x_snan;
  logic        w_zero, w_inf, w_nan, w_snan;
  logic [10:0] x_m, w_m;
  logic [4:0]  x_e, w_e;
  logic [21:0] s0_mp;
  logic [5:0]  s0_se;

  assign x_ez   = ~|x_i[14:10];
  assign x_em   =  &x_i[14:10];
  assign x_fz   = ~|x_i[9:0];
  assign w_ez   = ~|w_i[14:10];
  assign w_em   =  &w_i[14:10];
  assign w_fz   = ~|w_i[9:0];

  assign x_zero = x_ez &  x_fz;
  assign x_inf  = x_em &  x_fz;
  assign x_nan  = x_em & ~x_fz;
  assign x_snan = x_nan & ~x_i[9];
  assign w_zero = w_ez &  w_fz;
  assign w_inf  = w_em &  w_fz;
  assign w_nan  = w_em & ~w_fz;
  assign w_snan = w_nan & ~w_i[9];

  assign x_m    = {~x_ez, x_i[9:0]};
  assign w_m    = {~w_ez, w_i[9:0]};
  assign x_e    = {x_i[14:11], x_i[10] | x_ez};   // subnormal: exponent 1
  assign w_e    = {w_i[14:11], w_i[10] | w_ez};

  assign s0_mp  = x_m * w_m;
  // A zero product is given the smallest exponent, so the addend always
  // anchors the alignment and passes through exactly.
  assign s0_se  = (x_zero | w_zero) ? 6'd2 : ({1'b0, x_e} + {1'b0, w_e});

  // ---------------------------------------------------------------------------
  // A register (no reset: nothing downstream loads it before v_a is set)
  // ---------------------------------------------------------------------------
  logic        a_sp;
  logic [21:0] a_mp;
  logic [5:0]  a_se;
  logic        a_inv;     // inf * 0
  logic        a_nan;     // x or w is NaN
  logic        a_snan;    // x or w is sNaN
  logic        a_inf;     // product is infinite
  logic [2:0]  a_rnd;
  logic [15:0] a_c;

  always_ff @(posedge clk_i) begin
    if (en_i) begin
      a_sp   <= x_i[15] ^ w_i[15];
      a_mp   <= s0_mp;
      a_se   <= s0_se;
      a_inv  <= (x_inf & w_zero) | (x_zero & w_inf);
      a_nan  <= x_nan | w_nan;
      a_snan <= x_snan | w_snan;
      a_inf  <= x_inf | w_inf;
      a_rnd  <= rnd_i;
      a_c    <= c_i;
    end
  end

  // ---------------------------------------------------------------------------
  // seg1: addend decode, special cases, alignment, add, magnitude. A -> M.
  //
  // Exact-sum field, 38 bits ("ext" coordinates): bit j weighs
  // 2^(F - 38 + j) for a reference exponent F. Bit 0 is a sticky column: it
  // only ever holds the OR of addend bits shifted below the field, and that
  // happens only when the product exceeds the addend by >= 2 bits, so the
  // column sits strictly below every guard bit the rounder reads.
  //   product : mp << 3             (fixed)
  //   addend  : mc << 27 >> shamt,  shamt = se - Ec - 1, clamped to [0, 38]
  // shamt < 0 means the addend dominates by more than the field allows; it is
  // then pinned at the top ("anchored") and the product, which lies wholly
  // below the addend's guard and round bits, contributes only its sticky and
  // borrow -- which is all it can contribute there.
  // lim = F + 13 is the largest left shift that keeps the biased exponent >= 1.
  // ---------------------------------------------------------------------------
  logic        c_ez, c_em, c_fz;
  logic        c_inf, c_nan, c_snan;
  logic [10:0] c_m;
  logic [4:0]  c_e;
  logic        eff_sub;

  logic        s1_spec, s1_isnan, s1_nv, s1_spec_sign;

  logic [6:0]  s1_t;
  logic        s1_anch;
  logic [5:0]  s1_shamt;
  logic [5:0]  s1_lim;
  logic [48:0] s1_wide;
  logic [37:0] s1_aext, s1_pext;
  logic [38:0] s1_sum;
  logic        s1_neg;
  logic [37:0] s1_mag;
  logic        s1_zero;
  logic        s1_sign;
  logic [1:0]  s1_cls;

  assign c_ez   = ~|a_c[14:10];
  assign c_em   =  &a_c[14:10];
  assign c_fz   = ~|a_c[9:0];
  assign c_inf  = c_em &  c_fz;
  assign c_nan  = c_em & ~c_fz;
  assign c_snan = c_nan & ~a_c[9];
  assign c_m    = {~c_ez, a_c[9:0]};
  assign c_e    = {a_c[14:11], a_c[10] | c_ez};

  assign eff_sub = a_sp ^ a_c[15];

  // Special results, in priority order (A9).
  always_comb begin
    s1_spec      = 1'b0;
    s1_isnan     = 1'b0;
    s1_nv        = 1'b0;
    s1_spec_sign = 1'b0;
    if (a_inv) begin
      s1_spec  = 1'b1;
      s1_isnan = 1'b1;
      s1_nv    = 1'b1;
    end else if (a_nan | c_nan) begin
      s1_spec  = 1'b1;
      s1_isnan = 1'b1;
      s1_nv    = a_snan | c_snan;
    end else if (a_inf & c_inf & eff_sub) begin
      s1_spec  = 1'b1;
      s1_isnan = 1'b1;
      s1_nv    = 1'b1;
    end else if (a_inf) begin
      s1_spec      = 1'b1;
      s1_spec_sign = a_sp;
    end else if (c_inf) begin
      s1_spec      = 1'b1;
      s1_spec_sign = a_c[15];
    end
  end

  // Alignment.
  assign s1_t     = {1'b0, a_se} - {2'b00, c_e} - 7'd1;       // se - Ec - 1
  assign s1_anch  = s1_t[6];                                   // negative
  assign s1_shamt = s1_anch                 ? 6'd0  :
                    (s1_t[5:0] > 6'd38)     ? 6'd38 : s1_t[5:0];
  assign s1_lim   = s1_anch ? ({1'b0, c_e} - 6'd1) : (a_se - 6'd2);
  assign s1_wide  = {c_m, 38'd0} >> s1_shamt;
  assign s1_aext  = {s1_wide[48:12], s1_wide[11] | (|s1_wide[10:0])};
  assign s1_pext  = {13'd0, a_mp, 3'd0};

  // Add / subtract; the field never carries out of bit 37 (bounded above).
  assign s1_sum   = eff_sub ? ({1'b0, s1_pext} - {1'b0, s1_aext})
                            : ({1'b0, s1_pext} + {1'b0, s1_aext});
  assign s1_neg   = s1_sum[38];
  assign s1_mag   = s1_neg ? (~s1_sum[37:0] + 38'd1) : s1_sum[37:0];
  assign s1_zero  = ~|s1_sum[37:0];

  always_comb begin
    if (s1_spec)      s1_sign = s1_spec_sign;
    else if (s1_zero) s1_sign = eff_sub ? (a_rnd == RDN) : a_sp;   // A8
    else              s1_sign = s1_neg ? a_c[15] : a_sp;
  end

  always_comb begin
    case (a_rnd)
      RNE:     s1_cls = CL_NEAR;
      RTZ:     s1_cls = CL_NEVER;
      RDN:     s1_cls = s1_sign ? CL_UP : CL_NEVER;
      RUP:     s1_cls = s1_sign ? CL_NEVER : CL_UP;
      RMM:     s1_cls = CL_AWAY;
      default: s1_cls = CL_NEAR;                 // RNE (5-7: unspecified)
    endcase
  end

  // ---------------------------------------------------------------------------
  // M register (no reset: loads only after A holds real data)
  // ---------------------------------------------------------------------------
  logic [37:0] m_mag;
  logic        m_sign;
  logic [5:0]  m_lim;
  logic        m_spec, m_isnan, m_nv;
  logic [1:0]  m_cls;

  always_ff @(posedge clk_i) begin
    if (en_i & ld_m_i) begin
      m_mag   <= s1_mag;
      m_sign  <= s1_sign;
      m_lim   <= s1_lim;
      m_spec  <= s1_spec;
      m_isnan <= s1_isnan;
      m_nv    <= s1_nv;
      m_cls   <= s1_cls;
    end
  end

  // ---------------------------------------------------------------------------
  // seg2: normalise by min(lzc, lim), round, range, flags. M -> R.
  // The left shift is built greedily from 32 down to 1, each step taken only
  // if the bits it would discard are zero AND the remaining exponent budget
  // allows it; that computes min(lzc, lim) and the shifted value together,
  // and the leftover budget is the biased exponent minus one.
  // After the shift: n[37] implicit bit, n[36:27] fraction, n[26] guard,
  // n[25] round-below-guard (for after-rounding tininess), n[24:0] sticky.
  // ---------------------------------------------------------------------------
  logic [37:0] n0, n1, n2, n3, n4, n5, n6;
  logic [5:0]  b0, b1, b2, b3, b4, b5, b6;
  logic [6:0]  s2_epre;
  logic        s2_g, s2_r, s2_st, s2_inexact, s2_rup;
  logic [4:0]  s2_efld;
  logic [14:0] s2_packed;
  logic        s2_pre_of, s2_of, s2_tiny, s2_uf, s2_nx;
  logic        s2_keep_normal;
  logic [15:0] s2_val;
  logic [3:0]  s2_flags;

  assign n0 = m_mag;
  assign b0 = m_lim;

  assign {n1, b1} = ((~|n0[37:6])  && (b0 >= 6'd32)) ? {n0[5:0],   32'd0, b0 - 6'd32} : {n0, b0};
  assign {n2, b2} = ((~|n1[37:22]) && (b1 >= 6'd16)) ? {n1[21:0],  16'd0, b1 - 6'd16} : {n1, b1};
  assign {n3, b3} = ((~|n2[37:30]) && (b2 >= 6'd8))  ? {n2[29:0],   8'd0, b2 - 6'd8}  : {n2, b2};
  assign {n4, b4} = ((~|n3[37:34]) && (b3 >= 6'd4))  ? {n3[33:0],   4'd0, b3 - 6'd4}  : {n3, b3};
  assign {n5, b5} = ((~|n4[37:36]) && (b4 >= 6'd2))  ? {n4[35:0],   2'd0, b4 - 6'd2}  : {n4, b4};
  assign {n6, b6} = ((~n5[37])     && (b5 >= 6'd1))  ? {n5[36:0],   1'd0, b5 - 6'd1}  : {n5, b5};

  assign s2_epre    = {1'b0, b6} + 7'd1;          // valid when n6[37]
  assign s2_g       = n6[26];
  assign s2_r       = n6[25];
  assign s2_st      = |n6[25:0];
  assign s2_inexact = s2_g | s2_st;

  always_comb begin
    case (m_cls)
      CL_NEVER: s2_rup = 1'b0;
      CL_UP:    s2_rup = s2_inexact;
      CL_NEAR:  s2_rup = s2_g & (s2_st | n6[27]);
      default:  s2_rup = s2_g;                    // CL_AWAY
    endcase
  end

  assign s2_pre_of = n6[37] & (s2_epre >= 7'd31);
  assign s2_efld   = n6[37] ? s2_epre[4:0] : 5'd0;
  assign s2_packed = {s2_efld, n6[36:27]} + {14'd0, s2_rup};
  assign s2_of     = s2_pre_of | (&s2_packed[14:10]);

  // Tininess after rounding with unbounded exponent: a subnormal pre-round
  // value is tiny unless it reached 2^-14 and would have reached it with one
  // more bit of precision too.
  assign s2_keep_normal = (s2_packed[14:10] == 5'd1) &
                          (m_cls[1] ? (s2_g & s2_r) : (s2_g & s2_st));
  assign s2_tiny   = ~n6[37] & ~s2_keep_normal;
  assign s2_uf     = s2_tiny & s2_inexact;
  assign s2_nx     = s2_inexact | s2_of;

  always_comb begin
    if (m_spec) begin
      s2_val   = m_isnan ? 16'h7E00 : {m_sign, 15'h7C00};
      s2_flags = {m_nv, 3'b000};
    end else if (s2_of) begin
      s2_val   = {m_sign, (m_cls == CL_NEVER) ? 15'h7BFF : 15'h7C00};
      s2_flags = 4'b0101;                          // OF, NX
    end else begin
      s2_val   = {m_sign, s2_packed};
      s2_flags = {1'b0, 1'b0, s2_uf, s2_nx};
    end
  end

  // ---------------------------------------------------------------------------
  // R register: value (no reset) and flags (reset; drive status_o).
  // ---------------------------------------------------------------------------
  logic [15:0] r_val;
  logic [3:0]  r_flags;

  always_ff @(posedge clk_i) begin
    if (en_i & ld_r_i) r_val <= s2_val;
  end

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni)              r_flags <= 4'd0;
    else if (en_i & ld_r_i)   r_flags <= s2_flags;
  end

  // ---------------------------------------------------------------------------
  // P register: the inter-stage register. Flush zeroes it (C2).
  // ---------------------------------------------------------------------------
  logic [15:0] p_q;

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni)              p_q <= 16'd0;
    else if (clr_i)           p_q <= 16'd0;
    else if (en_i & ld_p_i)   p_q <= r_val;
  end

  assign p_o     = p_q;
  assign flags_o = r_flags;

endmodule