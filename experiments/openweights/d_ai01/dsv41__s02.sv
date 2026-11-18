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
  // Internal storage
  // ---------------------------------------------------------------------------
  logic [15:0] pipe [0:WIDTH-1][0:HEIGHT-1][0:3];
  logic [4:0]  flag_pipe [0:WIDTH-1][0:HEIGHT-1][0:2];
  logic [WIDTH-1:0] flush_hold;

  // ---------------------------------------------------------------------------
  // Leading-zero count for 72-bit value (combinational, no loops)
  // ---------------------------------------------------------------------------
  function automatic int clz72(input logic [71:0] val);
    int z;
    if (val[71:64] != 0) begin
      if (val[71:68] != 0) begin
        if (val[71:70] != 0) begin
          if (val[71]) z = 0;
          else z = 1;
        end else begin
          if (val[69]) z = 2;
          else z = 3;
        end
      end else begin
        if (val[67:66] != 0) begin
          if (val[67]) z = 4;
          else z = 5;
        end else begin
          if (val[65]) z = 6;
          else z = 7;
        end
      end
    end else if (val[63:56] != 0) begin
      if (val[63:60] != 0) begin
        if (val[63:62] != 0) begin
          if (val[63]) z = 8;
          else z = 9;
        end else begin
          if (val[61]) z = 10;
          else z = 11;
        end
      end else begin
        if (val[59:58] != 0) begin
          if (val[59]) z = 12;
          else z = 13;
        end else begin
          if (val[57]) z = 14;
          else z = 15;
        end
      end
    end else if (val[55:48] != 0) begin
      if (val[55:52] != 0) begin
        if (val[55:54] != 0) begin
          if (val[55]) z = 16;
          else z = 17;
        end else begin
          if (val[53]) z = 18;
          else z = 19;
        end
      end else begin
        if (val[51:50] != 0) begin
          if (val[51]) z = 20;
          else z = 21;
        end else begin
          if (val[49]) z = 22;
          else z = 23;
        end
      end
    end else if (val[47:40] != 0) begin
      if (val[47:44] != 0) begin
        if (val[47:46] != 0) begin
          if (val[47]) z = 24;
          else z = 25;
        end else begin
          if (val[45]) z = 26;
          else z = 27;
        end
      end else begin
        if (val[43:42] != 0) begin
          if (val[43]) z = 28;
          else z = 29;
        end else begin
          if (val[41]) z = 30;
          else z = 31;
        end
      end
    end else if (val[39:32] != 0) begin
      if (val[39:36] != 0) begin
        if (val[39:38] != 0) begin
          if (val[39]) z = 32;
          else z = 33;
        end else begin
          if (val[37]) z = 34;
          else z = 35;
        end
      end else begin
        if (val[35:34] != 0) begin
          if (val[35]) z = 36;
          else z = 37;
        end else begin
          if (val[33]) z = 38;
          else z = 39;
        end
      end
    end else if (val[31:24] != 0) begin
      if (val[31:28] != 0) begin
        if (val[31:30] != 0) begin
          if (val[31]) z = 40;
          else z = 41;
        end else begin
          if (val[29]) z = 42;
          else z = 43;
        end
      end else begin
        if (val[27:26] != 0) begin
          if (val[27]) z = 44;
          else z = 45;
        end else begin
          if (val[25]) z = 46;
          else z = 47;
        end
      end
    end else if (val[23:16] != 0) begin
      if (val[23:20] != 0) begin
        if (val[23:22] != 0) begin
          if (val[23]) z = 48;
          else z = 49;
        end else begin
          if (val[21]) z = 50;
          else z = 51;
        end
      end else begin
        if (val[19:18] != 0) begin
          if (val[19]) z = 52;
          else z = 53;
        end else begin
          if (val[17]) z = 54;
          else z = 55;
        end
      end
    end else if (val[15:8] != 0) begin
      if (val[15:12] != 0) begin
        if (val[15:14] != 0) begin
          if (val[15]) z = 56;
          else z = 57;
        end else begin
          if (val[13]) z = 58;
          else z = 59;
        end
      end else begin
        if (val[11:10] != 0) begin
          if (val[11]) z = 60;
          else z = 61;
        end else begin
          if (val[9]) z = 62;
          else z = 63;
        end
      end
    end else if (val[7:0] != 0) begin
      if (val[7:4] != 0) begin
        if (val[7:6] != 0) begin
          if (val[7]) z = 64;
          else z = 65;
        end else begin
          if (val[5]) z = 66;
          else z = 67;
        end
      end else begin
        if (val[3:2] != 0) begin
          if (val[3]) z = 68;
          else z = 69;
        end else begin
          if (val[1]) z = 70;
          else z = 71;
        end
      end
    end else z = 72;
    return z;
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
    // Declarations (must precede all statements)
    logic sa, sb, sc;
    logic [4:0] exp_a, exp_b, exp_c;
    logic [9:0] frac_a, frac_b, frac_c;
    logic [10:0] sig_a, sig_b, sig_c;
    int e_a, e_b, e_c;
    logic [21:0] P;
    int E_p, E_c, E;
    int diff_p, diff_c;
    logic [71:0] prod_scaled, add_scaled;
    logic signed [71:0] prod_val, add_val, exact;
    logic sign;
    logic [71:0] abs_exact;
    int msb, exp_val;
    logic [71:0] Q;
    int shift;
    logic guard, sticky, lsb, round_up;
    logic [71:0] rounded;
    logic inexact;
    int exp_field;
    logic [9:0] frac_out;
    logic [15:0] res;
    logic [4:0] fl;
    logic overflow_thresh;
    int clz;
    logic prod_sign;

    // Defaults
    result = 16'h0000;
    flags  = 5'b00000;

    // -----------------------------------------------------------------------
    // Special cases
    // -----------------------------------------------------------------------
    // NaN
    if ((a[14:10] == 5'h1F && a[9:0] != 0) ||
        (b[14:10] == 5'h1F && b[9:0] != 0) ||
        (c[14:10] == 5'h1F && c[9:0] != 0)) begin
      result = 16'h7E00;
      flags  = 5'b00000;
      return;
    end

    // Infinity in a or b
    if (a[14:10] == 5'h1F || b[14:10] == 5'h1F) begin
      if ((a[14:10] == 5'h1F && b[14:0] == 0) ||
          (b[14:10] == 5'h1F && a[14:0] == 0)) begin
        result = 16'h7E00;
        flags  = 5'b10000; // NV
        return;
      end
      prod_sign = a[15] ^ b[15];
      if (c[14:10] == 5'h1F) begin
        if (c[15] == prod_sign) begin
          result = {prod_sign, 5'h1F, 10'b0};
          flags  = 5'b00000;
        end else begin
          result = 16'h7E00;
          flags  = 5'b10000;
        end
      end else begin
        result = {prod_sign, 5'h1F, 10'b0};
        flags  = 5'b00000;
      end
      return;
    end

    // Infinity in c
    if (c[14:10] == 5'h1F) begin
      result = c;
      flags  = 5'b00000;
      return;
    end

    // Zero in a or b
    if (a[14:0] == 0 || b[14:0] == 0) begin
      prod_sign = a[15] ^ b[15];
      if (c[14:0] == 0) begin
        if (prod_sign == c[15]) begin
          result = {prod_sign, 15'b0};
        end else begin
          result = (rnd == 3) ? 16'h8000 : 16'h0000;
        end
        flags = 5'b00000;
      end else begin
        result = c;
        flags  = 5'b00000;
      end
      return;
    end

    // -----------------------------------------------------------------------
    // Unpack operands
    // -----------------------------------------------------------------------
    sa = a[15];
    exp_a = a[14:10];
    frac_a = a[9:0];
    if (exp_a == 0) begin
      sig_a = {1'b0, frac_a};
      e_a   = -24;
    end else begin
      sig_a = {1'b1, frac_a};
      e_a   = exp_a - 25;
    end

    sb = b[15];
    exp_b = b[14:10];
    frac_b = b[9:0];
    if (exp_b == 0) begin
      sig_b = {1'b0, frac_b};
      e_b   = -24;
    end else begin
      sig_b = {1'b1, frac_b};
      e_b   = exp_b - 25;
    end

    sc = c[15];
    exp_c = c[14:10];
    frac_c = c[9:0];
    if (c[14:0] == 0) begin
      sig_c = 11'b0;
      e_c   = 0;
    end else if (exp_c == 0) begin
      sig_c = {1'b0, frac_c};
      e_c   = -24;
    end else begin
      sig_c = {1'b1, frac_c};
      e_c   = exp_c - 25;
    end

    // -----------------------------------------------------------------------
    // Exact integer computation in units of 2^(E-48)
    // -----------------------------------------------------------------------
    P = sig_a * sig_b;
    E_p = e_a + e_b;
    E_c = e_c;
    E = (E_p > E_c) ? E_p : E_c;
    diff_p = E - E_p;
    diff_c = E - E_c;

    prod_scaled = {50'b0, P} << (48 - diff_p);
    add_scaled  = {61'b0, sig_c} << (48 - diff_c);

    prod_val = (sa ^ sb) ? -$signed({1'b0, prod_scaled}) : $signed({1'b0, prod_scaled});
    add_val  = sc ? -$signed({1'b0, add_scaled}) : $signed({1'b0, add_scaled});
    exact    = prod_val + add_val;

    // Exact zero from cancellation
    if (exact == 0) begin
      result = (rnd == 3) ? 16'h8000 : 16'h0000;
      flags  = 5'b00000;
      return;
    end

    sign = exact[71];
    abs_exact = sign ? -exact : exact;

    clz = clz72(abs_exact);
    msb = 71 - clz;
    exp_val = E - 48 + msb;

    // -----------------------------------------------------------------------
    // Subnormal range
    // -----------------------------------------------------------------------
    if (exp_val < -14) begin
      shift = 24 - E;
      Q = abs_exact >> shift;
      guard = abs_exact[shift-1];
      sticky = |(abs_exact & ((72'd1 << (shift-1)) - 1));
      lsb = abs_exact[shift];
      inexact = guard | sticky;

      case (rnd)
        0: round_up = guard & (sticky | lsb); // RNE
        1: round_up = 0;                       // RTZ
        2: round_up = sign & (guard | sticky); // RDN
        3: round_up = ~sign & (guard | sticky);// RUP
        4: round_up = guard;                   // RMM
        default: round_up = 0;
      endcase

      rounded = Q + round_up;

      if (rounded >= 1024) begin
        result = {sign, 5'h01, 10'b0};
        flags  = {1'b0, 1'b0, 1'b0, inexact, inexact};
      end else begin
        result = {sign, 5'h00, rounded[9:0]};
        flags  = {1'b0, 1'b0, 1'b0, inexact, inexact};
      end
      return;
    end

    // -----------------------------------------------------------------------
    // Normal range
    // -----------------------------------------------------------------------
    shift = msb - 10;
    Q = abs_exact >> shift;
    guard = abs_exact[shift-1];
    sticky = |(abs_exact & ((72'd1 << (shift-1)) - 1));
    lsb = abs_exact[shift];
    inexact = guard | sticky;

    // Overflow threshold check: exact >= 65520 (0xFFF0)
    overflow_thresh = (exp_val == 15 && Q == 2047 && guard == 1);

    case (rnd)
      0: round_up = guard & (sticky | lsb); // RNE
      1: round_up = 0;                       // RTZ
      2: round_up = sign & (guard | sticky); // RDN
      3: round_up = ~sign & (guard | sticky);// RUP
      4: round_up = guard;                   // RMM
      default: round_up = 0;
    endcase

    rounded = Q + round_up;
    if (rounded == 2048) begin
      rounded = 1024;
      exp_val = exp_val + 1;
    end

    if (exp_val > 15 || overflow_thresh) begin
      // Overflow
      flags = {1'b0, 1'b0, 1'b1, 1'b0, 1'b1}; // OF=1, NX=1
      case (rnd)
        0: result = sign ? 16'hFC00 : 16'h7C00; // RNE
        1: result = sign ? 16'hFBFF : 16'h7BFF; // RTZ
        2: result = sign ? 16'hFC00 : 16'h7BFF; // RDN
        3: result = sign ? 16'hFBFF : 16'h7C00; // RUP
        4: result = sign ? 16'hFC00 : 16'h7C00; // RMM
        default: result = sign ? 16'hFC00 : 16'h7C00;
      endcase
      return;
    end

    exp_field = exp_val + 15;
    frac_out = rounded[9:0];
    result = {sign, exp_field[4:0], frac_out};
    flags  = {1'b0, 1'b0, 1'b0, 1'b0, inexact};
    return;
  endfunction

  // ---------------------------------------------------------------------------
  // Generate rows and stages
  // ---------------------------------------------------------------------------
  genvar r, k;
  generate
    for (r = 0; r < WIDTH; r++) begin : gen_row
      for (k = 0; k < HEIGHT; k++) begin : gen_stage
        logic [15:0] fma_a, fma_b, fma_c;
        logic [15:0] fma_result;
        logic [4:0]  fma_flags;

        assign fma_a = x_i[r][k];
        assign fma_b = w_i[k];

        if (k == 0) begin : gen_stage0
          assign fma_c = accumulate_i ? z_o[r] : y_i[r];
        end else begin : gen_stageN
          assign fma_c = pipe[r][k-1][3];
        end

        always_comb begin
          fp16_fma(fma_a, fma_b, fma_c, rnd_i, fma_result, fma_flags);
        end

        // Result pipeline (4 deep)
        always_ff @(posedge clk_i or negedge rst_ni) begin
          if (!rst_ni) begin
            pipe[r][k][0] <= 16'h0000;
            pipe[r][k][1] <= 16'h0000;
            pipe[r][k][2] <= 16'h0000;
            pipe[r][k][3] <= 16'h0000;
          end else if (row_clk_gate_en_i[r] && flush_i) begin
            pipe[r][k][0] <= 16'h0000;
            pipe[r][k][1] <= 16'h0000;
            pipe[r][k][2] <= 16'h0000;
            pipe[r][k][3] <= 16'h0000;
          end else if (row_clk_gate_en_i[r] && reg_enable_i) begin
            pipe[r][k][0] <= fma_result;
            pipe[r][k][1] <= pipe[r][k][0];
            pipe[r][k][2] <= pipe[r][k][1];
            pipe[r][k][3] <= pipe[r][k][2];
          end
        end

        // Flag pipeline (3 deep)
        always_ff @(posedge clk_i or negedge rst_ni) begin
          if (!rst_ni) begin
            flag_pipe[r][k][0] <= 5'b00000;
            flag_pipe[r][k][1] <= 5'b00000;
            flag_pipe[r][k][2] <= 5'b00000;
          end else if (row_clk_gate_en_i[r] && reg_enable_i && (!flush_i || !flush_hold[r])) begin
            flag_pipe[r][k][0] <= fma_flags;
            flag_pipe[r][k][1] <= flag_pipe[r][k][0];
            flag_pipe[r][k][2] <= flag_pipe[r][k][1];
          end
        end

        assign status_o[r][k] = flag_pipe[r][k][2];
      end
    end
  endgenerate

  // ---------------------------------------------------------------------------
  // Output assignment and flush_hold tracking
  // ---------------------------------------------------------------------------
  generate
    for (r = 0; r < WIDTH; r++) begin : gen_z
      assign z_o[r] = pipe[r][HEIGHT-1][3];
    end
  endgenerate

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      flush_hold <= '0;
    end else begin
      for (int i = 0; i < WIDTH; i++) begin
        if (row_clk_gate_en_i[i] && reg_enable_i) begin
          flush_hold[i] <= flush_i;
        end
      end
    end
  end

endmodule
