// =============================================================================
// fp_multifmt_fma.sv
// -----------------------------------------------------------------------------
// Multi-format (FP32 / FP16 / BF16) SIMD fused multiply-add.
//
// Structure:
//   * ONE shared arithmetic core, sized for the widest format (24-bit
//     significands).  FP16 and BF16 significands are MSB-aligned into the same
//     24-bit field (1+10+13 and 1+7+16 zeros), and the unbiased exponent is
//     carried as a signed number, so a single 24x24 multiplier, one alignment
//     shifter, one adder, one leading-one detector and one rounder serve all
//     three formats.  Only the round position, the exponent bias and the
//     packing differ, and those are runtime muxes, not extra datapaths.
//   * Lanes are processed sequentially through that single core, one lane per
//     cycle, so the lane count scales with WIDTH without replicating the
//     datapath.  Latency and throughput are free (L2/L3); area is not.  The
//     last lane is forwarded combinationally to `result_o`, so an operation
//     costs exactly N cycles and back-to-back scalar operations run at one per
//     cycle.
//   * Exactly one rounding of the exact product-plus-addend: the 48-bit
//     product is never rounded, the addend is aligned against it inside a
//     76-bit window (3*24+4) whose position is max(product, addend) + 1, and
//     everything below the window is collapsed into a sticky bit.  The window
//     is provably wide enough: bits are only dropped when the two terms differ
//     by more than six binary places, and cancellation then cannot reach them.
//     76 <= 4*p = 96 for FP32 (A8).
//   * Subnormals are values like any other -- an operand with a zero exponent
//     field simply gets exponent 1-bias and no hidden bit, and a result below
//     the format's minimum normal is rounded at the fixed subnormal position.
//     Nothing is flushed.
// =============================================================================

module fp_multifmt_fma #(
  parameter int unsigned WIDTH = 64        // {32, 64}
) (
  input  logic             clk_i,
  input  logic             rst_ni,         // active low

  // ---- operation in ---------------------------------------------------------
  input  logic             in_valid_i,
  output logic             in_ready_o,
  input  logic [1:0]       fmt_i,          // 0 = FP32, 1 = FP16, 2 = BF16
  input  logic             vec_i,          // 1 = packed SIMD lanes
  input  logic [WIDTH-1:0] a_i,
  input  logic [WIDTH-1:0] b_i,
  input  logic [WIDTH-1:0] c_i,
  input  logic [2:0]       rnd_i,          // 0 RNE, 1 RTZ, 2 RDN, 3 RUP, 4 RMM

  // ---- result out -----------------------------------------------------------
  output logic             out_valid_o,
  input  logic             out_ready_i,
  output logic [WIDTH-1:0] result_o,
  output logic [4:0]       flags_o         // {NV, DZ, OF, UF, NX}
);

  // ---------------------------------------------------------------------------
  // constants
  // ---------------------------------------------------------------------------
  localparam int unsigned NS16 = WIDTH/16;      // 16-bit slices : 2 or 4
  localparam int unsigned NS32 = WIDTH/32;      // 32-bit slices : 1 or 2

  localparam logic [1:0] ST_IDLE = 2'd0;
  localparam logic [1:0] ST_CALC = 2'd1;

  // ---------------------------------------------------------------------------
  // unpacked operand description
  // ---------------------------------------------------------------------------
  typedef struct packed {
    logic               sgn;
    logic signed [15:0] ex;      // unbiased exponent of the value
    logic [23:0]        sig;     // significand, MSB-aligned into 24 bits
    logic               is_z;
    logic               is_inf;
    logic               is_nan;
    logic               is_snan;
  } fp_t;

  function automatic fp_t unpack_fp (input logic [31:0] x, input logic [1:0] f);
    fp_t                r;
    logic               sgn;
    logic [7:0]         ef;
    logic [22:0]        mn;
    logic [23:0]        m24;
    logic               mmsb;
    logic [7:0]         emx;
    logic signed [15:0] bias;
    logic               zer;
    logic               subn;
    logic               ismx;
    begin
      case (f)
        2'd0: begin  // FP32 : 1/8/23, bias 127
          sgn  = x[31];
          ef   = x[30:23];
          mn   = x[22:0];
          m24  = {1'b0, x[22:0]};
          mmsb = x[22];
          emx  = 8'd255;
          bias = 16'sd127;
        end
        2'd1: begin  // FP16 : 1/5/10, bias 15
          sgn  = x[15];
          ef   = {3'b000, x[14:10]};
          mn   = {13'b0, x[9:0]};
          m24  = {1'b0, x[9:0], 13'b0};
          mmsb = x[9];
          emx  = 8'd31;
          bias = 16'sd15;
        end
        default: begin  // BF16 : 1/8/7, bias 127
          sgn  = x[15];
          ef   = x[14:7];
          mn   = {16'b0, x[6:0]};
          m24  = {1'b0, x[6:0], 16'b0};
          mmsb = x[6];
          emx  = 8'd255;
          bias = 16'sd127;
        end
      endcase
      zer  = (ef == 8'd0) && (mn == 23'd0);
      subn = (ef == 8'd0) && (mn != 23'd0);
      ismx = (ef == emx);

      r.sgn     = sgn;
      r.is_z    = zer;
      r.is_inf  = ismx && (mn == 23'd0);
      r.is_nan  = ismx && (mn != 23'd0);
      r.is_snan = ismx && (mn != 23'd0) && !mmsb;
      r.sig     = (zer || subn || ismx) ? m24 : (m24 | 24'h800000);
      r.ex      = (zer || subn) ? (16'sd1 - bias)
                                : ($signed({8'b0, ef}) - bias);
      unpack_fp = r;
    end
  endfunction

  function automatic logic [31:0] pack_fp (input logic [1:0] f,
                                           input logic       s,
                                           input logic [7:0] e,
                                           input logic [22:0] m);
    begin
      case (f)
        2'd0:    pack_fp = {s, e, m};
        2'd1:    pack_fp = {16'hFFFF, s, e[4:0], m[9:0]};
        default: pack_fp = {16'hFFFF, s, e, m[6:0]};
      endcase
    end
  endfunction

  // ---------------------------------------------------------------------------
  // sequencer state
  // ---------------------------------------------------------------------------
  logic [1:0]        st_q;
  logic [WIDTH-1:0]  a_q, b_q, c_q;
  logic [1:0]        fmt_q;
  logic              vec_q;
  logic [2:0]        rnd_q;
  logic [2:0]        lane_q;
  logic [WIDTH-1:0]  res_q;
  logic [4:0]        flg_q;
  logic [2:0]        nlanes;
  logic              accept;
  logic              last_lane;
  logic [WIDTH-1:0]  res_nxt;

  // ---------------------------------------------------------------------------
  // lane operand slice
  // ---------------------------------------------------------------------------
  logic [31:0] la, lb, lc;

  always_comb begin
    la = 32'b0;
    lb = 32'b0;
    lc = 32'b0;
    if (fmt_q == 2'd0) begin
      for (int k = 0; k < int'(NS32); k++) begin
        if (k == int'(lane_q)) begin
          la = a_q[k*32 +: 32];
          lb = b_q[k*32 +: 32];
          lc = c_q[k*32 +: 32];
        end
      end
    end else begin
      for (int k = 0; k < int'(NS16); k++) begin
        if (k == int'(lane_q)) begin
          la = {16'b0, a_q[k*16 +: 16]};
          lb = {16'b0, b_q[k*16 +: 16]};
          lc = {16'b0, c_q[k*16 +: 16]};
        end
      end
    end
  end

  // ---------------------------------------------------------------------------
  // shared arithmetic core (one lane per cycle)
  // ---------------------------------------------------------------------------
  fp_t ua, ub, uc;

  logic [7:0]         expmax;
  logic signed [15:0] biasv, e_min;
  logic [22:0]        qnan_man;

  logic               pr_sign, pr_zero, pr_inf;
  logic [47:0]        prod;
  logic signed [15:0] ep_sum, ec_eff, dexp, anch, e_res, pe, dsh_s;
  logic [15:0]        shraw;
  logic [6:0]         sham;
  logic [47:0]        vsh;
  logic [75:0]        fixw, shfw;
  logic [123:0]       fun_in, fun_out;
  logic               stk, sgn_f, sgn_g, eff_sub, res_sgn;
  logic [76:0]        sum_add, sub_a, sub_b;
  logic               ge_sw;
  logic [77:0]        mag, magn;
  logic [7:0]         lzc;
  logic [127:0]       lz_v0;
  logic [63:0]        lz_v1;
  logic [31:0]        lz_v2;
  logic [15:0]        lz_v3;
  logic [7:0]         lz_v4;
  logic [3:0]         lz_v5;
  logic [1:0]         lz_v6;
  logic [6:0]         lz_n;
  logic [23:0]        sig_r, sig_r2;
  logic               gbit, sbit_r, sbit, gbit2, sbit2;
  logic [25:0]        wvec, wsh, wlost;
  logic [7:0]         dsh;
  logic               inc_r;
  logic [24:0]        sum_r;
  logic               cry, nrm;
  logic [22:0]        man_o, man_f;
  logic signed [15:0] expf;
  logic               ovf, nx_f, uf_f, zsign, inf_on_ovf;
  logic [31:0]        res_lane;
  logic [4:0]         flg_lane;

  assign ua = unpack_fp(la, fmt_q);
  assign ub = unpack_fp(lb, fmt_q);
  assign uc = unpack_fp(lc, fmt_q);

  always_comb begin
    // ---- per-format constants ----------------------------------------------
    expmax   = (fmt_q == 2'd1) ? 8'd31 : 8'd255;
    biasv    = (fmt_q == 2'd1) ? 16'sd15 : 16'sd127;
    e_min    = 16'sd1 - biasv;
    case (fmt_q)
      2'd0:    qnan_man = 23'h400000;
      2'd1:    qnan_man = 23'h000200;
      default: qnan_man = 23'h000040;
    endcase

    // ---- product ------------------------------------------------------------
    pr_sign = ua.sgn ^ ub.sgn;
    pr_zero = ua.is_z | ub.is_z;
    pr_inf  = ua.is_inf | ub.is_inf;
    prod    = ua.sig * ub.sig;                    // exact 48-bit product

    // A zero term is pushed far below the other one so that the non-zero term
    // always owns the anchor and can never be shifted out into the sticky bit.
    ep_sum = pr_zero   ? -16'sd2000 : (ua.ex + ub.ex);
    ec_eff = uc.is_z   ? -16'sd2000 : uc.ex;

    // anchor = max(exponent just above product MSB, just above addend MSB)
    dexp   = ep_sum - ec_eff + 16'sd1;
    anch   = (dexp >= 16'sd0) ? (ep_sum + 16'sd2) : (ec_eff + 16'sd1);
    shraw  = (dexp >= 16'sd0) ? dexp : -dexp;
    sham   = (shraw > 16'd76) ? 7'd76 : shraw[6:0];

    // window bit i has weight 2**(anch-76+i)
    if (dexp >= 16'sd0) begin
      fixw  = {prod, 28'b0};
      vsh   = {uc.sig, 24'b0};
      sgn_f = pr_sign;
      sgn_g = uc.sgn;
    end else begin
      fixw  = {uc.sig, 52'b0};
      vsh   = prod;
      sgn_f = uc.sgn;
      sgn_g = pr_sign;
    end

    fun_in  = {vsh, 76'b0};
    fun_out = fun_in >> sham;
    shfw    = fun_out[123:48];
    stk     = |fun_out[47:0];

    // ---- add / subtract -----------------------------------------------------
    // The three possible outcomes are formed by three adders in parallel so
    // that no carry chain feeds another:
    //   sum_add = fixw + shfw
    //   sub_a   = fixw - shfw - stk   (fixw is the larger term; the tail below
    //                                  the window turns the exact difference
    //                                  into (sub_a) + (1 - tail))
    //   sub_b   = shfw - fixw         (shfw is the larger term; the exact
    //                                  difference is (sub_b) + tail)
    // and sub_b's carry-out tells which term is larger.
    eff_sub = sgn_f ^ sgn_g;
    sum_add = {1'b0, fixw} + {1'b0, shfw};
    sub_a   = {1'b0, fixw} + {1'b0, ~shfw} + {76'b0, ~stk};
    sub_b   = {1'b0, shfw} + {1'b0, ~fixw} + 77'd1;
    ge_sw   = sub_b[76];
    if (!eff_sub) begin
      mag     = {1'b0, sum_add};
      res_sgn = sgn_f;
    end else if (ge_sw) begin
      mag     = {2'b0, sub_b[75:0]};
      res_sgn = sgn_g;
    end else begin
      mag     = {2'b0, sub_a[75:0]};
      res_sgn = sgn_f;
    end

    // ---- normalise ----------------------------------------------------------
    // leading-zero count, binary search (mag[77] sits at lz_v0[127])
    lz_v0   = {mag, 50'b0};
    lz_n[6] = ~(|lz_v0[127:64]);
    lz_v1   = lz_n[6] ? lz_v0[63:0]  : lz_v0[127:64];
    lz_n[5] = ~(|lz_v1[63:32]);
    lz_v2   = lz_n[5] ? lz_v1[31:0]  : lz_v1[63:32];
    lz_n[4] = ~(|lz_v2[31:16]);
    lz_v3   = lz_n[4] ? lz_v2[15:0]  : lz_v2[31:16];
    lz_n[3] = ~(|lz_v3[15:8]);
    lz_v4   = lz_n[3] ? lz_v3[7:0]   : lz_v3[15:8];
    lz_n[2] = ~(|lz_v4[7:4]);
    lz_v5   = lz_n[2] ? lz_v4[3:0]   : lz_v4[7:4];
    lz_n[1] = ~(|lz_v5[3:2]);
    lz_v6   = lz_n[1] ? lz_v5[1:0]   : lz_v5[3:2];
    lz_n[0] = ~lz_v6[1];
    lzc     = (mag == 78'b0) ? 8'd78 : {1'b0, lz_n};
    magn    = mag << lzc;
    e_res = anch + 16'sd1 - $signed({8'b0, lzc});

    // ---- round position (format dependent) ----------------------------------
    case (fmt_q)
      2'd0: begin                      // p = 24
        sig_r  = magn[77:54];
        gbit   = magn[53];
        sbit_r = |magn[52:0];
      end
      2'd1: begin                      // p = 11
        sig_r  = {13'b0, magn[77:67]};
        gbit   = magn[66];
        sbit_r = |magn[65:0];
      end
      default: begin                   // p = 8
        sig_r  = {16'b0, magn[77:70]};
        gbit   = magn[69];
        sbit_r = |magn[68:0];
      end
    endcase
    sbit = sbit_r | stk;

    // ---- subnormal alignment ------------------------------------------------
    dsh_s = e_min - e_res;
    if (e_res < e_min) begin
      dsh    = (dsh_s > 16'sd26) ? 8'd26 : dsh_s[7:0];
      wvec   = {sig_r, gbit, sbit};
      wsh    = wvec >> dsh;
      wlost  = wvec & ~({26{1'b1}} << dsh);
      sig_r2 = wsh[25:2];
      gbit2  = wsh[1];
      sbit2  = wsh[0] | (|wlost);
      pe     = 16'sd1;
    end else begin
      dsh    = 8'd0;
      wvec   = 26'b0;
      wsh    = 26'b0;
      wlost  = 26'b0;
      sig_r2 = sig_r;
      gbit2  = gbit;
      sbit2  = sbit;
      pe     = e_res + biasv;
    end

    // ---- round --------------------------------------------------------------
    case (rnd_q)
      3'd0:    inc_r = gbit2 & (sbit2 | sig_r2[0]);   // RNE
      3'd1:    inc_r = 1'b0;                          // RTZ
      3'd2:    inc_r = res_sgn & (gbit2 | sbit2);     // RDN
      3'd3:    inc_r = (~res_sgn) & (gbit2 | sbit2);  // RUP
      default: inc_r = gbit2;                         // RMM
    endcase
    sum_r = {1'b0, sig_r2} + {24'b0, inc_r};

    case (fmt_q)
      2'd0: begin
        cry   = sum_r[24];
        nrm   = sum_r[23];
        man_o = sum_r[22:0];
      end
      2'd1: begin
        cry   = sum_r[11];
        nrm   = sum_r[10];
        man_o = {13'b0, sum_r[9:0]};
      end
      default: begin
        cry   = sum_r[8];
        nrm   = sum_r[7];
        man_o = {16'b0, sum_r[6:0]};
      end
    endcase

    if (cry) begin
      expf  = pe + 16'sd1;
      man_f = 23'b0;
    end else if (nrm) begin
      expf  = pe;
      man_f = man_o;
    end else begin
      expf  = 16'sd0;
      man_f = man_o;
    end

    nx_f  = gbit2 | sbit2;
    ovf   = (expf >= $signed({8'b0, expmax}));
    uf_f  = nx_f & (expf == 16'sd0) & ~ovf;

    inf_on_ovf = (rnd_q == 3'd0) | (rnd_q == 3'd4)
               | ((rnd_q == 3'd2) &  res_sgn)
               | ((rnd_q == 3'd3) & ~res_sgn);

    // sign of an exact zero result
    zsign = (pr_zero && uc.is_z && (pr_sign == uc.sgn)) ? pr_sign
                                                       : (rnd_q == 3'd2);

    // ---- result selection ---------------------------------------------------
    if (ua.is_snan | ub.is_snan | uc.is_snan |
        (ua.is_inf & ub.is_z) | (ua.is_z & ub.is_inf)) begin
      res_lane = pack_fp(fmt_q, 1'b0, expmax, qnan_man);
      flg_lane = 5'b10000;
    end else if (ua.is_nan | ub.is_nan | uc.is_nan) begin
      res_lane = pack_fp(fmt_q, 1'b0, expmax, qnan_man);
      flg_lane = 5'b00000;
    end else if (pr_inf) begin
      if (uc.is_inf && (uc.sgn != pr_sign)) begin
        res_lane = pack_fp(fmt_q, 1'b0, expmax, qnan_man);
        flg_lane = 5'b10000;
      end else begin
        res_lane = pack_fp(fmt_q, pr_sign, expmax, 23'b0);
        flg_lane = 5'b00000;
      end
    end else if (uc.is_inf) begin
      res_lane = pack_fp(fmt_q, uc.sgn, expmax, 23'b0);
      flg_lane = 5'b00000;
    end else if ((mag == 78'b0) && !stk) begin
      res_lane = pack_fp(fmt_q, zsign, 8'b0, 23'b0);
      flg_lane = 5'b00000;
    end else if (ovf) begin
      if (inf_on_ovf) res_lane = pack_fp(fmt_q, res_sgn, expmax, 23'b0);
      else            res_lane = pack_fp(fmt_q, res_sgn, expmax - 8'd1,
                                         23'h7FFFFF);
      flg_lane = 5'b00101;                       // OF | NX
    end else begin
      res_lane = pack_fp(fmt_q, res_sgn, expf[7:0], man_f);
      flg_lane = {3'b000, uf_f, nx_f};
    end
  end

  // ---------------------------------------------------------------------------
  // lane result placement
  // ---------------------------------------------------------------------------
  always_comb begin
    res_nxt = res_q;
    if (fmt_q == 2'd0) begin
      for (int k = 0; k < int'(NS32); k++) begin
        if (k == int'(lane_q)) res_nxt[k*32 +: 32] = res_lane;
      end
    end else begin
      for (int k = 0; k < int'(NS16); k++) begin
        if (k == int'(lane_q)) res_nxt[k*16 +: 16] = res_lane[15:0];
      end
    end
  end

  always_comb begin
    if (!vec_q)                 nlanes = 3'd1;
    else if (fmt_q == 2'd0)     nlanes = 3'(NS32);
    else                        nlanes = 3'(NS16);
  end

  // ---------------------------------------------------------------------------
  // handshake / sequencer
  // ---------------------------------------------------------------------------
  // The final lane of an operation is forwarded straight to the result port,
  // so an operation costs exactly one cycle per lane.  Neither `in_ready_o`
  // nor `out_valid_o` depends on `in_valid_i`, and `out_valid_o` does not
  // depend on `out_ready_i` (L4).
  assign last_lane   = (st_q == ST_CALC) && (lane_q == (nlanes - 3'd1));
  assign in_ready_o  = (st_q == ST_IDLE) || (last_lane && out_ready_i);
  assign out_valid_o = last_lane;
  assign result_o    = res_nxt;
  assign flags_o     = flg_q | flg_lane;
  assign accept      = in_valid_i && in_ready_o;

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      st_q   <= ST_IDLE;
      a_q    <= {WIDTH{1'b0}};
      b_q    <= {WIDTH{1'b0}};
      c_q    <= {WIDTH{1'b0}};
      fmt_q  <= 2'd0;
      vec_q  <= 1'b0;
      rnd_q  <= 3'd0;
      lane_q <= 3'd0;
      res_q  <= {WIDTH{1'b1}};
      flg_q  <= 5'd0;
    end else begin
      if (st_q == ST_CALC) begin
        if (!last_lane) begin
          res_q  <= res_nxt;
          flg_q  <= flg_q | flg_lane;
          lane_q <= lane_q + 3'd1;
        end else if (out_ready_i) begin
          st_q <= ST_IDLE;                 // result taken this cycle
        end
      end
      if (accept) begin
        a_q    <= a_i;
        b_q    <= b_i;
        c_q    <= c_i;
        fmt_q  <= fmt_i;
        vec_q  <= vec_i;
        rnd_q  <= rnd_i;
        lane_q <= 3'd0;
        res_q  <= {WIDTH{1'b1}};
        flg_q  <= 5'd0;
        st_q   <= ST_CALC;
      end
    end
  end

endmodule
