module fp16_gemm_array #(
  parameter int unsigned HEIGHT = 8,
  parameter int unsigned WIDTH  = 8
) (
  input  logic                               clk_i,
  input  logic                               rst_ni,
  input  logic [WIDTH-1:0][HEIGHT-1:0][15:0] x_i,
  input  logic            [HEIGHT-1:0][15:0] w_i,
  input  logic [WIDTH-1:0]            [15:0] y_i,
  output logic [WIDTH-1:0]            [15:0] z_o,
  input  logic [2:0]                         rnd_i,
  input  logic                               accumulate_i,
  input  logic [WIDTH-1:0]                   row_clk_gate_en_i,
  input  logic                               reg_enable_i,
  input  logic                               flush_i,
  output logic [WIDTH-1:0][HEIGHT-1:0][4:0]  status_o
);

  // Return value is {NV, DZ, OF, UF, NX, result[15:0]}.
  function automatic logic [20:0] fma16 (
    input logic [15:0] a,
    input logic [15:0] b,
    input logic [15:0] c,
    input logic [2:0]  rnd
  );
    logic [15:0] result;
    logic [4:0]  flags;

    logic a_nan, b_nan, c_nan;
    logic a_inf, b_inf, c_inf;
    logic a_zero, b_zero;

    logic [10:0] sig_a, sig_b, sig_c;
    logic [21:0] prod_sig;
    logic        sign_prod, sign_res;

    integer ea, eb, ec;
    integer prod_exp, add_exp, base_exp;
    integer shift_prod, shift_add;
    integer h, round_sh, out_exp;

    logic [65:0] mag_prod, mag_add, mag;
    logic [65:0] scan;
    logic [65:0] shifted;
    logic [65:0] remainder;
    logic [65:0] halfway;
    logic [11:0] sig_work;
    logic [4:0]  exp_work;
    logic        inexact, increment, overflow, to_inf;
  begin
    result    = 16'h0000;
    flags     = 5'b00000;
    sign_res  = 1'b0;
    mag       = 66'd0;
    shifted   = 66'd0;
    remainder = 66'd0;
    halfway   = 66'd0;
    sig_work  = 12'd0;
    exp_work  = 5'd0;
    inexact   = 1'b0;
    increment = 1'b0;
    overflow  = 1'b0;
    to_inf    = 1'b0;
    h         = 0;
    round_sh  = 0;
    out_exp   = 0;

    a_nan  = (&a[14:10]) && (|a[9:0]);
    b_nan  = (&b[14:10]) && (|b[9:0]);
    c_nan  = (&c[14:10]) && (|c[9:0]);
    a_inf  = (&a[14:10]) && !(|a[9:0]);
    b_inf  = (&b[14:10]) && !(|b[9:0]);
    c_inf  = (&c[14:10]) && !(|c[9:0]);
    a_zero = (a[14:0] == 15'd0);
    b_zero = (b[14:0] == 15'd0);

    sign_prod = a[15] ^ b[15];

    if (a_nan || b_nan || c_nan) begin
      result = 16'h7e00;
    end else if ((a_inf && b_zero) || (b_inf && a_zero)) begin
      result   = 16'h7e00;
      flags[4] = 1'b1;
    end else if (a_inf || b_inf) begin
      if (c_inf && (c[15] != sign_prod)) begin
        result   = 16'h7e00;
        flags[4] = 1'b1;
      end else begin
        result = {sign_prod, 5'h1f, 10'd0};
      end
    end else if (c_inf) begin
      result = {c[15], 5'h1f, 10'd0};
    end else begin
      sig_a = {(a[14:10] != 5'd0), a[9:0]};
      sig_b = {(b[14:10] != 5'd0), b[9:0]};
      sig_c = {(c[14:10] != 5'd0), c[9:0]};

      ea = (a[14:10] == 5'd0) ? 1 : a[14:10];
      eb = (b[14:10] == 5'd0) ? 1 : b[14:10];
      ec = (c[14:10] == 5'd0) ? 1 : c[14:10];

      prod_sig = sig_a * sig_b;

      // prod_sig * 2^prod_exp and sig_c * 2^add_exp are exact.
      prod_exp = ea + eb - 50;
      add_exp  = ec - 25;
      base_exp = (prod_exp < add_exp) ? prod_exp : add_exp;

      shift_prod = prod_exp - base_exp;
      shift_add  = add_exp  - base_exp;

      mag_prod = {{44{1'b0}}, prod_sig} << shift_prod;
      mag_add  = {{55{1'b0}}, sig_c}    << shift_add;

      if (sign_prod == c[15]) begin
        mag      = mag_prod + mag_add;
        sign_res = sign_prod;
      end else if (mag_prod > mag_add) begin
        mag      = mag_prod - mag_add;
        sign_res = sign_prod;
      end else begin
        mag      = mag_add - mag_prod;
        sign_res = c[15];
      end

      if (mag == 66'd0) begin
        // Like-signed zeros retain their sign. All other exact zero sums
        // are +0 except under RDN.
        if ((prod_sig == 22'd0) && (sig_c == 11'd0) &&
            (sign_prod == c[15])) begin
          sign_res = sign_prod;
        end else begin
          sign_res = (rnd == 3'd2);
        end
        result = {sign_res, 15'd0};
      end else begin
        // Leading-one search by fixed binary reduction, avoiding a per-bit
        // normalisation loop at each array element.
        scan = mag;
        h = 0;
        if (|scan[65:32]) begin
          h = h + 32;
          scan = scan >> 32;
        end
        if (|scan[31:16]) begin
          h = h + 16;
          scan = scan >> 16;
        end
        if (|scan[15:8]) begin
          h = h + 8;
          scan = scan >> 8;
        end
        if (|scan[7:4]) begin
          h = h + 4;
          scan = scan >> 4;
        end
        if (|scan[3:2]) begin
          h = h + 2;
          scan = scan >> 2;
        end
        if (scan[1]) begin
          h = h + 1;
        end

        out_exp = h + base_exp;

        if (out_exp >= -14) begin
          // Normal-result rounding: retain an 11-bit significand.
          if (h > 10) begin
            round_sh  = h - 10;
            shifted   = mag >> round_sh;
            remainder = mag & ((66'd1 << round_sh) - 66'd1);
            halfway   = 66'd1 << (round_sh - 1);
            inexact   = |remainder;
            sig_work  = {1'b0, shifted[10:0]};
          end else begin
            round_sh = 0;
            shifted  = mag << (10 - h);
            sig_work = {1'b0, shifted[10:0]};
          end

          if (inexact) begin
            case (rnd)
              3'd0: increment = (remainder > halfway) ||
                                ((remainder == halfway) && sig_work[0]);
              3'd2: increment = sign_res;
              3'd3: increment = !sign_res;
              3'd4: increment = (remainder >= halfway);
              default: increment = 1'b0;
            endcase
          end

          if (increment) begin
            sig_work = sig_work + 12'd1;
          end

          if (sig_work[11]) begin
            sig_work = 12'd1024;
            out_exp  = out_exp + 1;
          end

          if (out_exp > 15) begin
            overflow = 1'b1;
          end

          // RTZ and the non-routing directed modes do not carry at the
          // overflow threshold, but the threshold still raises OF and NX.
          if ((out_exp == 15) && (h > 10) &&
              (shifted[10:0] == 11'h7ff) &&
              (remainder >= halfway)) begin
            overflow = 1'b1;
          end

          if (overflow) begin
            to_inf = (rnd == 3'd0) || (rnd == 3'd4) ||
                     (!sign_res && (rnd == 3'd3)) ||
                     ( sign_res && (rnd == 3'd2));
            result = to_inf ? {sign_res, 5'h1f, 10'd0}
                            : {sign_res, 5'h1e, 10'h3ff};
            flags  = 5'b00101;
          end else begin
            exp_work = out_exp + 15;
            result   = {sign_res, exp_work, sig_work[9:0]};
            flags[0] = inexact;
          end
        end else begin
          // Subnormal rounding uses the fixed quantum 2^-24.
          if ((base_exp + 24) >= 0) begin
            shifted  = mag << (base_exp + 24);
            sig_work = {1'b0, shifted[10:0]};
          end else begin
            round_sh  = -(base_exp + 24);
            shifted   = mag >> round_sh;
            remainder = mag & ((66'd1 << round_sh) - 66'd1);
            halfway   = 66'd1 << (round_sh - 1);
            inexact   = |remainder;
            sig_work  = {1'b0, shifted[10:0]};
          end

          if (inexact) begin
            case (rnd)
              3'd0: increment = (remainder > halfway) ||
                                ((remainder == halfway) && sig_work[0]);
              3'd2: increment = sign_res;
              3'd3: increment = !sign_res;
              3'd4: increment = (remainder >= halfway);
              default: increment = 1'b0;
            endcase
          end

          if (increment) begin
            sig_work = sig_work + 12'd1;
          end

          if (sig_work == 12'd1024) begin
            result = {sign_res, 5'h01, 10'd0};
          end else begin
            result = {sign_res, 5'd0, sig_work[9:0]};
          end

          flags[0] = inexact;
          flags[1] = inexact && (sig_work < 12'd1024);
        end
      end
    end

    fma16 = {flags, result};
  end
  endfunction

  // Four registers per stage give both the four-tick inter-stage spacing
  // and the three further ticks from the last operation to z_o.
  logic [WIDTH-1:0][HEIGHT-1:0][3:0][15:0] data_pipe;
  logic [WIDTH-1:0][HEIGHT-1:0][2:0][4:0]  flag_pipe;
  logic [WIDTH-1:0]                        flush_active;

  logic [WIDTH-1:0][HEIGHT-1:0][15:0]      stage_addend;
  logic [WIDTH-1:0][HEIGHT-1:0][20:0]      fma_packed;

  for (genvar r = 0; r < WIDTH; r++) begin : g_rows
    for (genvar k = 0; k < HEIGHT; k++) begin : g_stages
      if (k == 0) begin : g_first
        assign stage_addend[r][k] = accumulate_i ? z_o[r] : y_i[r];
      end else begin : g_later
        assign stage_addend[r][k] = data_pipe[r][k-1][3];
      end

      assign fma_packed[r][k] =
        fma16(x_i[r][k], w_i[k], stage_addend[r][k], rnd_i);

      assign status_o[r][k] = flag_pipe[r][k][2];
    end

    assign z_o[r] = data_pipe[r][HEIGHT-1][3];
  end

  integer r;
  integer k;
  integer j;

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      data_pipe    <= '0;
      flag_pipe    <= '0;
      flush_active <= '0;
    end else begin
      for (r = 0; r < WIDTH; r = r + 1) begin
        if (row_clk_gate_en_i[r]) begin
          if (flush_i) begin
            // Flush is simultaneous throughout the row and outranks
            // reg_enable_i, but not the row clock gate.
            data_pipe[r] <= '0;

            // The first flushed tick reports the normal A10 value. Later
            // flushed ticks hold both the visible flags and their delay line.
            if (!flush_active[r]) begin
              for (k = 0; k < HEIGHT; k = k + 1) begin
                flag_pipe[r][k][0] <= fma_packed[r][k][20:16];
                for (j = 1; j < 3; j = j + 1) begin
                  flag_pipe[r][k][j] <= flag_pipe[r][k][j-1];
                end
              end
            end
            flush_active[r] <= 1'b1;
          end else begin
            flush_active[r] <= 1'b0;

            if (reg_enable_i) begin
              for (k = 0; k < HEIGHT; k = k + 1) begin
                data_pipe[r][k][0] <= fma_packed[r][k][15:0];
                flag_pipe[r][k][0] <= fma_packed[r][k][20:16];

                for (j = 1; j < 4; j = j + 1) begin
                  data_pipe[r][k][j] <= data_pipe[r][k][j-1];
                end
                for (j = 1; j < 3; j = j + 1) begin
                  flag_pipe[r][k][j] <= flag_pipe[r][k][j-1];
                end
              end
            end
          end
        end
      end
    end
  end

endmodule
