// =============================================================================
// fp_multifmt_fma -- fused multiply-add, FP32 / FP16 / BF16, SIMD lanes
// One rounding of the exact a*b + c. Subnormals exact everywhere.
// UF rule (A7a): UF = NX && delivered exponent field == 0.
// =============================================================================
module fp_multifmt_fma #(
  parameter int unsigned WIDTH = 64        // {32, 64}
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

  logic [1:0]       fmt_q;
  logic             vec_q;
  logic [WIDTH-1:0] a_q, b_q, c_q;
  logic [2:0]       rnd_q;
  logic             busy_q;
  logic [WIDTH-1:0] res_c;
  logic [4:0]       flg_c;
  logic [36:0]      lane_r;
  int               k;

  // ---------------------------------------------------------------------------
  // Single-lane fused FMA core. Operands in 32-bit containers (16-bit formats
  // use the low half). Returns {flags[4:0], result[31:0]}.
  // Internal significand field: 3p+4 bits (<= 4p per A8), plus sticky.
  // ---------------------------------------------------------------------------
  function automatic logic [36:0] fma_lane(
    input logic [31:0] opa,
    input logic [31:0] opb,
    input logic [31:0] opc,
    input logic [1:0]  fmt,
    input logic [2:0]  rnd
  );
    int          p;
    int          manw;
    int          bias;
    int          emin;
    int          emax;
    int          wl;
    logic [31:0] qnan;
    logic [31:0] res;
    logic [4:0]  flg;
    logic        sa, sb, sc;
    logic [7:0]  ea, eb, ec;
    logic [22:0] ma, mb, mc;
    logic        a_all1, b_all1, c_all1;
    logic        a_nan, b_nan, c_nan;
    logic        a_snan, b_snan, c_snan;
    logic        a_inf, b_inf, c_inf;
    logic        a_zero, b_zero, c_zero;
    logic [23:0] siga, sigb, sigc;
    int          ea_u, eb_u, ec_u;
    logic [47:0] pa;
    int          pe;
    logic        ps;
    logic        prod_inf;
    logic        invalid;
    int          sdiff;
    logic        case_b;
    logic [77:0] prod_f, add_f;
    logic        st_p, st_a;
    int          elsb;
    int          sh_a;
    int          rsh;
    logic [77:0] mmag;
    logic        sstick;
    logic        rsign;
    logic        exact_zero;
    int          msb;
    int          e0;
    int          e0r;
    logic        is_sub;
    int          sh;
    logic [77:0] sig78;
    logic        guard;
    logic        stk;
    logic        residue;
    logic        nx;
    logic        inc;
    logic [24:0] rounded;
    logic        carry;
    logic        of;
    logic        uf;
    int          ef;
    logic [7:0]  ef8;
    logic        ovf_inf;
    logic [22:0] man_r;
    logic        zsign;
    int          i;

    // ---- format geometry ---------------------------------------------------
    case (fmt)
      2'd1:    begin manw = 10; bias = 15;  end
      2'd2:    begin manw = 7;  bias = 127; end
      default: begin manw = 23; bias = 127; end
    endcase
    p    = manw + 1;
    emin = 1 - bias;
    emax = bias;
    wl   = 3*p + 4;
    case (fmt)
      2'd1:    qnan = 32'h00007E00;
      2'd2:    qnan = 32'h00007FC0;
      default: qnan = 32'h7FC00000;
    endcase

    // ---- decode -------------------------------------------------------------
    sa = (fmt == 2'd0) ? opa[31] : opa[15];
    ea = (fmt == 2'd0) ? opa[30:23] :
         ((fmt == 2'd1) ? {3'b000, opa[14:10]} : opa[14:7]);
    ma = (fmt == 2'd0) ? opa[22:0] :
         ((fmt == 2'd1) ? {13'b0, opa[9:0]} : {16'b0, opa[6:0]});

    sb = (fmt == 2'd0) ? opb[31] : opb[15];
    eb = (fmt == 2'd0) ? opb[30:23] :
         ((fmt == 2'd1) ? {3'b000, opb[14:10]} : opb[14:7]);
    mb = (fmt == 2'd0) ? opb[22:0] :
         ((fmt == 2'd1) ? {13'b0, opb[9:0]} : {16'b0, opb[6:0]});

    sc = (fmt == 2'd0) ? opc[31] : opc[15];
    ec = (fmt == 2'd0) ? opc[30:23] :
         ((fmt == 2'd1) ? {3'b000, opc[14:10]} : opc[14:7]);
    mc = (fmt == 2'd0) ? opc[22:0] :
         ((fmt == 2'd1) ? {13'b0, opc[9:0]} : {16'b0, opc[6:0]});

    a_all1 = (ea == ((fmt == 2'd1) ? 8'h1F : 8'hFF));
    b_all1 = (eb == ((fmt == 2'd1) ? 8'h1F : 8'hFF));
    c_all1 = (ec == ((fmt == 2'd1) ? 8'h1F : 8'hFF));

    a_nan  = a_all1 && (ma != 23'd0);
    b_nan  = b_all1 && (mb != 23'd0);
    c_nan  = c_all1 && (mc != 23'd0);
    a_snan = a_nan && !ma[manw-1];
    b_snan = b_nan && !mb[manw-1];
    c_snan = c_nan && !mc[manw-1];
    a_inf  = a_all1 && (ma == 23'd0);
    b_inf  = b_all1 && (mb == 23'd0);
    c_inf  = c_all1 && (mc == 23'd0);
    a_zero = (ea == 8'd0) && (ma == 23'd0);
    b_zero = (eb == 8'd0) && (mb == 23'd0);
    c_zero = (ec == 8'd0) && (mc == 23'd0);

    siga = a_zero ? 24'd0 : {(ea == 8'd0), ma};
    sigb = b_zero ? 24'd0 : {(eb == 8'd0), mb};
    sigc = c_zero ? 24'd0 : {(ec == 8'd0), mc};
    ea_u = (ea == 8'd0) ? emin : (int'(ea) - bias);
    eb_u = (eb == 8'd0) ? emin : (int'(eb) - bias);
    ec_u = (ec == 8'd0) ? emin : (int'(ec) - bias);

    // ---- exact product (never rounded) --------------------------------------
    pa = siga * sigb;
    pe = ea_u + eb_u;
    ps = sa ^ sb;

    // ---- specials ------------------------------------------------------------
    prod_inf = a_inf | b_inf;
    invalid  = a_snan | b_snan | c_snan
             | (a_inf & b_zero) | (a_zero & b_inf)
             | (prod_inf & c_inf & (ps != sc));

    res = 32'd0;
    flg = 5'd0;
    if (invalid) begin
      res = qnan;
      flg = 5'b10000;                                   // NV
    end else if (a_nan | b_nan | c_nan) begin
      res = qnan;
    end else if (prod_inf) begin
      case (fmt)
        2'd1:    res = {16'd0, ps, 5'h1F, 10'd0};
        2'd2:    res = {16'd0, ps, 8'hFF, 7'd0};
        default: res = {ps, 8'hFF, 23'd0};
      endcase
    end else if (c_inf) begin
      case (fmt)
        2'd1:    res = {16'd0, sc, 5'h1F, 10'd0};
        2'd2:    res = {16'd0, sc, 8'hFF, 7'd0};
        default: res = {sc, 8'hFF, 23'd0};
      endcase
    end else if (a_zero | b_zero) begin
      if (c_zero) begin
        zsign = (ps == sc) ? ps : (rnd == 3'd2);        // A6
        case (fmt)
          2'd1, 2'd2: res = {16'd0, zsign, 15'd0};
          default:    res = {zsign, 31'd0};
        endcase
      end else begin
        res = opc;                                      // exact: 0 + c
      end
    end else begin
      // ---- alignment into the 3p+4-bit field --------------------------------
      sdiff = pe - ec_u;
      st_p  = 1'b0;
      st_a  = 1'b0;
      if (sdiff >= 0) begin
        case_b = 1'b0;
        prod_f = {30'd0, pa} << (wl - 2*p);             // product at field top
        elsb   = pe - wl + 2;
        sh_a   = wl - p - 1 - sdiff;
        if (sh_a >= 0) begin
          add_f = {54'd0, sigc} << sh_a;                // addend fully in field
        end else begin
          rsh = sdiff - (wl - p - 1);
          if (rsh >= p) begin
            add_f = 78'd0;
            st_a  = (sigc != 24'd0);
          end else begin
            add_f = {54'd0, sigc} >> rsh;
            st_a  = ((sigc << (24 - rsh)) != 24'd0);    // lost low bits
          end
        end
      end else begin
        case_b = 1'b1;
        add_f  = {54'd0, sigc} << (wl - p);             // addend at field top
        elsb   = ec_u - wl + 1;
        rsh     = (-sdiff) - (wl - 2*p + 1);
        if (rsh <= 0) begin
          prod_f = {30'd0, pa} << (-rsh);               // product fully in field
        end else if (rsh >= 2*p) begin
          prod_f = 78'd0;
          st_p   = (pa != 48'd0);
        end else begin
          prod_f = {30'd0, pa} >> rsh;
          st_p   = ((pa << (48 - rsh)) != 48'd0);       // lost low bits
        end
      end

      // ---- magnitude sum with borrow-corrected sticky ----------------------
      exact_zero = 1'b0;
      if (ps == sc) begin
        rsign  = ps;
        mmag   = prod_f + add_f;
        sstick = st_p | st_a;
      end else begin
        if (prod_f > add_f) begin
          rsign = ps;
          if (case_b) begin
            mmag   = prod_f - add_f;
            sstick = st_p;
          end else begin
            mmag   = prod_f - add_f - {77'd0, st_a};    // subtrahend residue
            sstick = st_a;
          end
        end else if (prod_f < add_f) begin
          rsign = sc;
          if (case_b) begin
            mmag   = add_f - prod_f - {77'd0, st_p};    // subtrahend residue
            sstick = st_p;
          end else begin
            mmag   = add_f - prod_f;
            sstick = st_a;
          end
        end else begin
          if (st_p) begin
            rsign = ps;  mmag = 78'd0;  sstick = 1'b1;
          end else if (st_a) begin
            rsign = sc;  mmag = 78'd0;  sstick = 1'b1;
          end else begin
            rsign = (rnd == 3'd2);                       // A6: +0, -0 under RDN
            mmag = 78'd0;  sstick = 1'b0;  exact_zero = 1'b1;
          end
        end
      end

      if (exact_zero) begin
        case (fmt)
          2'd1, 2'd2: res = {16'd0, rsign, 15'd0};
          default:    res = {rsign, 31'd0};
        endcase
        flg = 5'd0;
      end else begin
        // ---- normalize ------------------------------------------------------
        msb = 0;
        for (i = 0; i < 78; i++) if (mmag[i]) msb = i;
        e0     = elsb + msb;
        is_sub = (e0 < emin);
        if (is_sub) sh = emin - elsb - (p - 1);
        else        sh = msb - (p - 1);
        if (sh >= 0) begin
          sig78 = mmag >> sh;
          if (sh == 0) begin
            guard = 1'b0;
            stk   = sstick;
          end else begin
            guard = mmag[sh-1];
            stk   = ((mmag & ((78'd1 << (sh-1)) - 78'd1)) != 78'd0) | sstick;
          end
        end else begin
          sig78 = mmag << (-sh);                        // exact, no residue
          guard = 1'b0;
          stk   = sstick;
        end

        // ---- single rounding ------------------------------------------------
        residue = guard | stk;
        nx      = residue;
        case (rnd)
          3'd0:    inc = guard & (stk | sig78[0]);       // RNE
          3'd1:    inc = 1'b0;                           // RTZ
          3'd2:    inc = rsign & residue;                // RDN
          3'd3:    inc = (~rsign) & residue;             // RUP
          3'd4:    inc = guard;                          // RMM
          default: inc = 1'b0;
        endcase
        rounded = {1'b0, sig78[23:0]} + {24'd0, inc};
        carry   = rounded[p];
        of      = 1'b0;
        if (is_sub) begin
          ef = rounded[p-1] ? 1 : 0;                      // promoted to normal
        end else begin
          e0r = e0 + (carry ? 1 : 0);
          if (e0r > emax) begin
            of = 1'b1;
            nx = 1'b1;
            ef = 0;
          end else begin
            ef = e0r + bias;
          end
        end
        for (i = 0; i < 23; i++) man_r[i] = (i < manw) ? rounded[i] : 1'b0;
        uf = nx & (ef == 0) & ~of;                       // A7a: delivered ef==0

        if (of) begin
          case (rnd)
            3'd1:    ovf_inf = 1'b0;
            3'd2:    ovf_inf = rsign;
            3'd3:    ovf_inf = ~rsign;
            default: ovf_inf = 1'b1;
          endcase
          if (ovf_inf) begin
            case (fmt)
              2'd1:    res = {16'd0, rsign, 5'h1F, 10'd0};
              2'd2:    res = {16'd0, rsign, 8'hFF, 7'd0};
              default: res = {rsign, 8'hFF, 23'd0};
            endcase
          end else begin
            case (fmt)
              2'd1:    res = {16'd0, rsign, 5'h1E, 10'h3FF};
              2'd2:    res = {16'd0, rsign, 8'hFE, 7'h7F};
              default: res = {rsign, 8'hFE, 23'h7FFFFF};
            endcase
          end
          flg = 5'b00101;                                // OF | NX
        end else begin
          ef8 = 8'(ef);
          case (fmt)
            2'd1:    res = {16'd0, rsign, ef8[4:0], man_r[9:0]};
            2'd2:    res = {16'd0, rsign, ef8[7:0], man_r[6:0]};
            default: res = {rsign, ef8[7:0], man_r[22:0]};
          endcase
          flg = {1'b0, 1'b0, of, uf, nx};
        end
      end
    end
    fma_lane = {flg, res};
  endfunction

  // ---------------------------------------------------------------------------
  // SIMD lanes: N = vec ? WIDTH/format_width : 1, independent; unused bits = 1
  // ---------------------------------------------------------------------------
  always_comb begin
    res_c = {WIDTH{1'b1}};
    flg_c = 5'd0;
    if (fmt_q == 2'd0) begin
      for (k = 0; k < WIDTH/32; k++) begin
        if (vec_q || (k == 0)) begin
          lane_r = fma_lane(a_q[32*k +: 32], b_q[32*k +: 32], c_q[32*k +: 32],
                            2'd0, rnd_q);
          res_c[32*k +: 32] = lane_r[31:0];
          flg_c = flg_c | lane_r[36:32];
        end
      end
    end else begin
      for (k = 0; k < WIDTH/16; k++) begin
        if (vec_q || (k == 0)) begin
          lane_r = fma_lane({16'd0, a_q[16*k +: 16]}, {16'd0, b_q[16*k +: 16]},
                            {16'd0, c_q[16*k +: 16]}, fmt_q, rnd_q);
          res_c[16*k +: 16] = lane_r[15:0];
          flg_c = flg_c | lane_r[36:32];
        end
      end
    end
  end

  // ---------------------------------------------------------------------------
  // Handshake: one registered stage. in_ready depends on out_ready (permitted),
  // never on in_valid; out_valid is a register, stable until taken.
  // ---------------------------------------------------------------------------
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      busy_q <= 1'b0;
      fmt_q  <= 2'd0;
      vec_q  <= 1'b0;
      a_q    <= '0;
      b_q    <= '0;
      c_q    <= '0;
      rnd_q  <= 3'd0;
    end else begin
      if (in_valid_i && in_ready_o) begin
        fmt_q  <= fmt_i;
        vec_q  <= vec_i;
        a_q    <= a_i;
        b_q    <= b_i;
        c_q    <= c_i;
        rnd_q  <= rnd_i;
        busy_q <= 1'b1;
      end else if (busy_q && out_ready_i) begin
        busy_q <= 1'b0;
      end
    end
  end

  assign in_ready_o  = (!busy_q) || out_ready_i;
  assign out_valid_o = busy_q;
  assign result_o    = res_c;
  assign flags_o     = flg_c;

endmodule
