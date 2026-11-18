// =============================================================================
// fp16_gemm_array -- d_ai01 implementation
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

  // ---------------------------------------------------------------------------
  // Local parameters
  // ---------------------------------------------------------------------------
  localparam int D = 4;                       // per-stage delay
  localparam int DFB = D*(HEIGHT-1) + 4;      // feedback loop delay

  // ---------------------------------------------------------------------------
  // Internal registers
  // ---------------------------------------------------------------------------
  logic [15:0] x_d1 [WIDTH][HEIGHT];
  logic [15:0] x_d2 [WIDTH][HEIGHT];
  logic [15:0] w_d1 [WIDTH][HEIGHT];
  logic [15:0] w_d2 [WIDTH][HEIGHT];
  logic [15:0] y_d1 [WIDTH];
  logic [15:0] y_d2 [WIDTH];

  logic [15:0] p [WIDTH][HEIGHT];
  logic [15:0] p_delay [WIDTH][HEIGHT][4];   // only k < HEIGHT-1 used

  logic [15:0] z_o_reg [WIDTH];
  logic [15:0] z_d1 [WIDTH];
  logic [15:0] z_d2 [WIDTH];
  logic [15:0] z_d3 [WIDTH];

  logic [4:0] status_reg [WIDTH][HEIGHT];
  logic       flush_active [WIDTH];

  // Combinational FMA results
  logic [15:0] p_new [WIDTH][HEIGHT];
  logic [4:0]  flags_new [WIDTH][HEIGHT];

  // ---------------------------------------------------------------------------
  // Leading-one finder for 96-bit magnitude
  // ---------------------------------------------------------------------------
  function automatic logic [6:0] find_msb96(input logic [95:0] val);
    logic [6:0] msb;
    logic found;
    integer i;
    logic [7:0] byte_val;
    begin
      msb = 0;
      found = 0;
      for (i = 11; i >= 0; i = i - 1) begin
        byte_val = val[i*8 +: 8];
        if (!found && byte_val != 0) begin
          casez (byte_val)
            8'b1???????: msb = i*8 + 7;
            8'b01??????: msb = i*8 + 6;
            8'b001?????: msb = i*8 + 5;
            8'b0001????: msb = i*8 + 4;
            8'b00001???: msb = i*8 + 3;
            8'b000001??: msb = i*8 + 2;
            8'b0000001?: msb = i*8 + 1;
            8'b00000001: msb = i*8 + 0;
            default: msb = i*8 + 0;
          endcase
          found = 1;
        end
      end
      return msb;
    end
  endfunction

  // ---------------------------------------------------------------------------
  // Binary16 fused multiply-add
  // ---------------------------------------------------------------------------
  function automatic void fp16_fma(
    input  logic [15:0] a,
    input  logic [15:0] b,
    input  logic [15:0] c,
    input  logic [2:0]  rnd,
    output logic [15:0] result,
    output logic [4:0]  flags
  );
    // Declarations (all at top to satisfy slang)
    logic sa, sb, sc;
    logic [4:0] ea, eb, ec;
    logic [9:0] fa, fb, fc;
    logic na, nb, nc;
    logic ia, ib, ic;
    logic za, zb, zc;
    logic sp;
    logic [10:0] Ma, Mb, Mc;
    logic signed [6:0] Ea, Eb, Ec;
    logic is_zero_a, is_zero_b, is_zero_c;
    logic [21:0] Mp;
    logic signed [7:0] Ep;
    logic signed [6:0] E_min;
    logic signed [6:0] Ep_eff, Ec_eff;
    logic signed [95:0] acc;
    logic sign_res;
    logic [95:0] mag;
    logic [6:0] msb;
    logic signed [8:0] E_lead;
    logic signed [8:0] e_field;
    logic [10:0] M_pre;
    logic [11:0] M_rounded;
    logic [95:0] rem, half, mask;
    logic rem_gt_half, rem_eq_half, rem_nonzero;
    logic round_up;
    logic [11:0] k, k_pre;
    logic signed [8:0] shift_sub;
    logic signed [8:0] shift;
    logic [10:0] lsb;
    logic both_zero;
    logic [95:0] term_u;
    logic signed [95:0] term_s;
    logic [7:0] shift_amt;
    logic [3:0] pos;
    logic found;
    integer i;

    // -----------------------------------------------------------------------
    // Unpack fields
    // -----------------------------------------------------------------------
    sa = a[15]; ea = a[14:10]; fa = a[9:0];
    sb = b[15]; eb = b[14:10]; fb = b[9:0];
    sc = c[15]; ec = c[14:10]; fc = c[9:0];

    // NaN detection
    na = (ea == 5'h1F) && (fa != 0);
    nb = (eb == 5'h1F) && (fb != 0);
    nc = (ec == 5'h1F) && (fc != 0);
    if (na || nb || nc) begin
      result = 16'h7E00;
      flags  = 5'b00000;
      return;
    end

    // Inf detection
    ia = (ea == 5'h1F) && (fa == 0);
    ib = (eb == 5'h1F) && (fb == 0);
    ic = (ec == 5'h1F) && (fc == 0);

    // Zero detection
    za = (ea == 0) && (fa == 0);
    zb = (eb == 0) && (fb == 0);
    zc = (ec == 0) && (fc == 0);

    // infinity * zero
    if ((ia && zb) || (ib && za)) begin
      result = 16'h7E00;
      flags  = 5'b10000; // NV
      return;
    end

    // infinity in product
    if (ia || ib) begin
      sp = sa ^ sb;
      if (ic) begin
        if (sp == sc) begin
          result = sp ? 16'hFC00 : 16'h7C00;
          flags  = 5'b00000;
        end else begin
          result = 16'h7E00;
          flags  = 5'b10000; // NV
        end
      end else begin
        result = sp ? 16'hFC00 : 16'h7C00;
        flags  = 5'b00000;
      end
      return;
    end

    // c is infinity
    if (ic) begin
      result = sc ? 16'hFC00 : 16'h7C00;
      flags  = 5'b00000;
      return;
    end

    // -----------------------------------------------------------------------
    // Unpack a (finite)
    // -----------------------------------------------------------------------
    if (ea == 0) begin
      if (fa == 0) begin
        is_zero_a = 1; Ma = 0; Ea = 0;
      end else begin
        is_zero_a = 0;
        found = 0; pos = 0;
        for (i = 9; i >= 0; i = i - 1) begin
          if (!found && fa[i]) begin
            pos = i; found = 1;
          end
        end
        Ma = fa << (10 - pos);
        Ea = -34 + pos;
      end
    end else begin
      is_zero_a = 0;
      Ma = {1'b1, fa};
      Ea = $signed({1'b0, ea}) - 25;
    end

    // Unpack b
    if (eb == 0) begin
      if (fb == 0) begin
        is_zero_b = 1; Mb = 0; Eb = 0;
      end else begin
        is_zero_b = 0;
        found = 0; pos = 0;
        for (i = 9; i >= 0; i = i - 1) begin
          if (!found && fb[i]) begin
            pos = i; found = 1;
          end
        end
        Mb = fb << (10 - pos);
        Eb = -34 + pos;
      end
    end else begin
      is_zero_b = 0;
      Mb = {1'b1, fb};
      Eb = $signed({1'b0, eb}) - 25;
    end

    // Unpack c
    if (ec == 0) begin
      if (fc == 0) begin
        is_zero_c = 1; Mc = 0; Ec = 0;
      end else begin
        is_zero_c = 0;
        found = 0; pos = 0;
        for (i = 9; i >= 0; i = i - 1) begin
          if (!found && fc[i]) begin
            pos = i; found = 1;
          end
        end
        Mc = fc << (10 - pos);
        Ec = -34 + pos;
      end
    end else begin
      is_zero_c = 0;
      Mc = {1'b1, fc};
      Ec = $signed({1'b0, ec}) - 25;
    end

    // -----------------------------------------------------------------------
    // Product
    // -----------------------------------------------------------------------
    if (is_zero_a || is_zero_b) begin
      Mp = 0;
      Ep = 0;
      sp = sa ^ sb;
    end else begin
      Mp = Ma * Mb;
      Ep = Ea + Eb;
      sp = sa ^ sb;
    end

    // -----------------------------------------------------------------------
    // Exact sum in 96-bit fixed-point
    // -----------------------------------------------------------------------
    Ep_eff = (Mp == 0) ? 7'sd100 : Ep;
    Ec_eff = (is_zero_c) ? 7'sd100 : Ec;
    E_min = (Ep_eff < Ec_eff) ? Ep_eff : Ec_eff;

    acc = 96'sd0;
    if (Mp != 0) begin
      shift_amt = Ep - E_min;
      term_u = {74'b0, Mp};
      term_s = $signed(term_u);
      term_s = term_s << shift_amt;
      if (sp) acc = acc - term_s;
      else    acc = acc + term_s;
    end
    if (!is_zero_c) begin
      shift_amt = Ec - E_min;
      term_u = {85'b0, Mc};
      term_s = $signed(term_u);
      term_s = term_s << shift_amt;
      if (sc) acc = acc - term_s;
      else    acc = acc + term_s;
    end

    // -----------------------------------------------------------------------
    // Zero result
    // -----------------------------------------------------------------------
    if (acc == 0) begin
      both_zero = (Mp == 0) && (Mc == 0);
      if (both_zero) begin
        if (sp == sc) sign_res = sp;
        else sign_res = (rnd == 2) ? 1 : 0;
      end else begin
        sign_res = (rnd == 2) ? 1 : 0;
      end
      result = {sign_res, 15'b0};
      flags  = 5'b00000;
      return;
    end

    // -----------------------------------------------------------------------
    // Normalize and round
    // -----------------------------------------------------------------------
    sign_res = acc[95];
    mag = sign_res ? (96'sd0 - acc) : acc;
    msb = find_msb96(mag);
    E_lead = E_min + msb;

    if (E_lead >= -14) begin
      // Normal or overflow
      e_field = E_lead + 15;
      shift = $signed({1'b0, msb}) - 10;
      if (shift > 0) begin
        M_pre = mag >> shift;
        mask = (96'd1 << shift) - 1;
        rem = mag & mask;
        half = 96'd1 << (shift - 1);
        rem_gt_half = (rem > half);
        rem_eq_half = (rem == half);
        rem_nonzero = (rem != 0);
        lsb = M_pre[0];
        case (rnd)
          0: begin
            if (rem_gt_half) round_up = 1;
            else if (rem_eq_half) round_up = lsb;
            else round_up = 0;
          end
          1: round_up = 0;
          2: round_up = sign_res && rem_nonzero;
          3: round_up = (!sign_res) && rem_nonzero;
          4: begin
            if (rem_gt_half) round_up = 1;
            else if (rem_eq_half) round_up = 1;
            else round_up = 0;
          end
          default: round_up = 0;
        endcase
        M_rounded = M_pre + round_up;
      end else begin
        M_rounded = mag << (-shift);
        rem_nonzero = 0;
        round_up = 0;
      end

      if (M_rounded == 12'd2048) begin
        M_rounded = 12'd1024;
        e_field = e_field + 1;
      end

      if (e_field >= 31) begin
        case (rnd)
          0: result = sign_res ? 16'hFC00 : 16'h7C00;
          1: result = sign_res ? 16'hFBFF : 16'h7BFF;
          2: result = sign_res ? 16'hFC00 : 16'h7BFF;
          3: result = sign_res ? 16'hFBFF : 16'h7C00;
          4: result = sign_res ? 16'hFC00 : 16'h7C00;
          default: result = 16'h7C00;
        endcase
        flags = 5'b00101; // OF=1, NX=1
        return;
      end

      result = {sign_res, e_field[4:0], M_rounded[9:0]};
      flags  = {4'b0, rem_nonzero};
      return;
    end else begin
      // Subnormal or underflow to zero
      shift_sub = E_min + 24;
      if (shift_sub >= 0) begin
        k = mag << shift_sub;
        rem_nonzero = 0;
        round_up = 0;
      end else begin
        shift = -shift_sub;
        k_pre = mag >> shift;
        mask = (96'd1 << shift) - 1;
        rem = mag & mask;
        half = 96'd1 << (shift - 1);
        rem_gt_half = (rem > half);
        rem_eq_half = (rem == half);
        rem_nonzero = (rem != 0);
        lsb = k_pre[0];
        case (rnd)
          0: begin
            if (rem_gt_half) round_up = 1;
            else if (rem_eq_half) round_up = lsb;
            else round_up = 0;
          end
          1: round_up = 0;
          2: round_up = sign_res && rem_nonzero;
          3: round_up = (!sign_res) && rem_nonzero;
          4: begin
            if (rem_gt_half) round_up = 1;
            else if (rem_eq_half) round_up = 1;
            else round_up = 0;
          end
          default: round_up = 0;
        endcase
        k = k_pre + round_up;
      end

      if (k == 0) begin
        result = {sign_res, 15'b0};
        flags  = 5'b00011; // UF=1, NX=1
        return;
      end else if (k >= 1024) begin
        result = {sign_res, 5'b00001, 10'b0};
        flags  = {4'b0, rem_nonzero};
        return;
      end else begin
        result = {sign_res, 5'b0, k[9:0]};
        flags  = {3'b0, rem_nonzero, rem_nonzero};
        return;
      end
    end
  endfunction

  // ---------------------------------------------------------------------------
  // Combinational FMA evaluation for all rows and stages
  // ---------------------------------------------------------------------------
  always_comb begin
    for (int r = 0; r < WIDTH; r++) begin
      for (int k = 0; k < HEIGHT; k++) begin
        logic [15:0] addend;
        if (k == 0) begin
          addend = accumulate_i ? z_d3[r] : y_d2[r];
        end else begin
          addend = p_delay[r][k-1][3];
        end
        fp16_fma(x_d2[r][k], w_d2[r][k], addend, rnd_i,
                 p_new[r][k], flags_new[r][k]);
      end
    end
  end

  // ---------------------------------------------------------------------------
  // Sequential logic
  // ---------------------------------------------------------------------------
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      for (int r = 0; r < WIDTH; r++) begin
        flush_active[r] <= 1'b0;
        z_o_reg[r] <= 16'b0;
        z_d1[r] <= 16'b0;
        z_d2[r] <= 16'b0;
        z_d3[r] <= 16'b0;
        y_d1[r] <= 16'b0;
        y_d2[r] <= 16'b0;
        for (int k = 0; k < HEIGHT; k++) begin
          x_d1[r][k] <= 16'b0;
          x_d2[r][k] <= 16'b0;
          w_d1[r][k] <= 16'b0;
          w_d2[r][k] <= 16'b0;
          p[r][k] <= 16'b0;
          status_reg[r][k] <= 5'b0;
          for (int d = 0; d < 4; d++) begin
            p_delay[r][k][d] <= 16'b0;
          end
        end
      end
    end else begin
      for (int r = 0; r < WIDTH; r++) begin
        if (row_clk_gate_en_i[r]) begin
          if (flush_i) begin
            // Flush asserted
            if (!flush_active[r]) begin
              // First flush edge: update status normally, then clear pipeline
              for (int k = 0; k < HEIGHT; k++) begin
                status_reg[r][k] <= flags_new[r][k];
                p[r][k] <= 16'b0;
                x_d1[r][k] <= 16'b0;
                x_d2[r][k] <= 16'b0;
                w_d1[r][k] <= 16'b0;
                w_d2[r][k] <= 16'b0;
                for (int d = 0; d < 4; d++) begin
                  p_delay[r][k][d] <= 16'b0;
                end
              end
              y_d1[r] <= 16'b0;
              y_d2[r] <= 16'b0;
              z_o_reg[r] <= 16'b0;
              z_d1[r] <= 16'b0;
              z_d2[r] <= 16'b0;
              z_d3[r] <= 16'b0;
              flush_active[r] <= 1'b1;
            end else begin
              // Subsequent flush edges: hold status, keep zeros
              // (registers already zero, do nothing)
            end
          end else begin
            // flush low
            flush_active[r] <= 1'b0;
            if (reg_enable_i) begin
              // Normal enabled tick
              for (int k = 0; k < HEIGHT; k++) begin
                x_d1[r][k] <= x_i[r][k];
                x_d2[r][k] <= x_d1[r][k];
                w_d1[r][k] <= w_i[k];
                w_d2[r][k] <= w_d1[r][k];
                p[r][k] <= p_new[r][k];
                status_reg[r][k] <= flags_new[r][k];
                if (k < HEIGHT-1) begin
                  p_delay[r][k][0] <= p_new[r][k];
                  p_delay[r][k][1] <= p_delay[r][k][0];
                  p_delay[r][k][2] <= p_delay[r][k][1];
                  p_delay[r][k][3] <= p_delay[r][k][2];
                end
              end
              y_d1[r] <= y_i[r];
              y_d2[r] <= y_d1[r];
              z_o_reg[r] <= p[r][HEIGHT-1];
              z_d1[r] <= p[r][HEIGHT-1];
              z_d2[r] <= z_d1[r];
              z_d3[r] <= z_d2[r];
            end
          end
        end
      end
    end
  end

  // ---------------------------------------------------------------------------
  // Outputs
  // ---------------------------------------------------------------------------
  always_comb begin
    for (int r = 0; r < WIDTH; r++) begin
      z_o[r] = z_o_reg[r];
      for (int k = 0; k < HEIGHT; k++) begin
        status_o[r][k] = status_reg[r][k];
      end
    end
  end

endmodule
