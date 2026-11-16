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

  // ---------------------------------------------------------------------------
  // Exact binary16 FMA
  //
  // Every finite operand and product is represented exactly as a signed integer
  // scaled by 2^-48.  The smallest product, 2^-24 * 2^-24, is therefore one
  // integer LSB.  No product or intermediate sum is rounded.
  // ---------------------------------------------------------------------------

  function automatic logic [6:0] msb96(input logic [95:0] v);
    logic [95:0] t;
    logic [6:0]  p;
    begin
      t = v;
      p = 7'd0;

      if (|t[95:32]) begin
        p = p + 7'd32;
        t = t >> 32;
      end
      if (|t[63:32]) begin
        p = p + 7'd32;
        t = t >> 32;
      end
      if (|t[31:16]) begin
        p = p + 7'd16;
        t = t >> 16;
      end
      if (|t[15:8]) begin
        p = p + 7'd8;
        t = t >> 8;
      end
      if (|t[7:4]) begin
        p = p + 7'd4;
        t = t >> 4;
      end
      if (|t[3:2]) begin
        p = p + 7'd2;
        t = t >> 2;
      end
      if (t[1]) begin
        p = p + 7'd1;
        t = t >> 1;
      end

      msb96 = p;
    end
  endfunction

  function automatic logic round_increment(
    input logic [95:0] remainder,
    input logic [95:0] halfway,
    input logic        result_sign,
    input logic [2:0]  rnd,
    input logic        retained_lsb
  );
    begin
      case (rnd)
        3'd0: round_increment =                    // RNE
          (remainder > halfway) ||
          ((remainder == halfway) && retained_lsb);

        3'd1: round_increment = 1'b0;              // RTZ

        3'd2: round_increment =                    // RDN
          result_sign && (|remainder);

        3'd3: round_increment =                    // RUP
          !result_sign && (|remainder);

        3'd4: round_increment =                    // RMM
          (remainder >= halfway);

        default: round_increment =
          (remainder > halfway) ||
          ((remainder == halfway) && retained_lsb);
      endcase
    end
  endfunction

  // Return {NV, DZ, OF, UF, NX, result[15:0]}.
  function automatic logic [20:0] fma16(
    input logic [15:0] a,
    input logic [15:0] b,
    input logic [15:0] c,
    input logic [2:0]  rnd
  );
    logic sa, sb, sc, sp;
    logic result_sign;

    logic [4:0] ea, eb, ec;
    logic [9:0] fa, fb, fc;
    logic [10:0] siga, sigb, sigc;
    logic [4:0] efa, efb, efc;

    logic a_nan, b_nan, c_nan;
    logic a_inf, b_inf, c_inf;
    logic a_zero, b_zero;

    logic [21:0] product;
    logic [5:0]  product_shift;
    logic [5:0]  addend_shift;

    logic [95:0] product_magnitude;
    logic [95:0] addend_magnitude;
    logic signed [95:0] product_term;
    logic signed [95:0] addend_term;
    logic signed [95:0] exact_sum;
    logic [95:0] magnitude;

    logic [6:0]  leading_bit;
    logic [6:0]  right_shift;
    logic [95:0] shifted;
    logic [95:0] remainder;
    logic [95:0] halfway;
    logic [11:0] retained;
    logic [11:0] rounded;
    logic        increment;
    logic        remainder_nonzero;
    logic [7:0]  exponent;

    logic        nv, of, uf, nx;
    logic [15:0] result;

    begin
      sa = a[15];
      sb = b[15];
      sc = c[15];
      sp = sa ^ sb;

      ea = a[14:10];
      eb = b[14:10];
      ec = c[14:10];

      fa = a[9:0];
      fb = b[9:0];
      fc = c[9:0];

      a_nan  = (ea == 5'h1f) && (fa != 10'd0);
      b_nan  = (eb == 5'h1f) && (fb != 10'd0);
      c_nan  = (ec == 5'h1f) && (fc != 10'd0);

      a_inf  = (ea == 5'h1f) && (fa == 10'd0);
      b_inf  = (eb == 5'h1f) && (fb == 10'd0);
      c_inf  = (ec == 5'h1f) && (fc == 10'd0);

      a_zero = (ea == 5'd0) && (fa == 10'd0);
      b_zero = (eb == 5'd0) && (fb == 10'd0);

      siga = {(ea != 5'd0), fa};
      sigb = {(eb != 5'd0), fb};
      sigc = {(ec != 5'd0), fc};

      efa = (ea == 5'd0) ? 5'd1 : ea;
      efb = (eb == 5'd0) ? 5'd1 : eb;
      efc = (ec == 5'd0) ? 5'd1 : ec;

      nv = 1'b0;
      of = 1'b0;
      uf = 1'b0;
      nx = 1'b0;
      result = 16'h0000;
      result_sign = 1'b0;

      if (a_nan || b_nan || c_nan) begin
        result = 16'h7e00;
      end else if ((a_inf && b_zero) || (b_inf && a_zero)) begin
        result = 16'h7e00;
        nv = 1'b1;
      end else if (a_inf || b_inf) begin
        if (c_inf && (sc != sp)) begin
          result = 16'h7e00;
          nv = 1'b1;
        end else begin
          result = {sp, 5'h1f, 10'h000};
        end
      end else if (c_inf) begin
        result = {sc, 5'h1f, 10'h000};
      end else begin
        // Product: siga*sigb * 2^(efa+efb-50).
        // Scaled by 2^48, its shift is efa+efb-2.
        product = siga * sigb;
        product_shift = {1'b0, efa} + {1'b0, efb} - 6'd2;
        product_magnitude =
          {{74{1'b0}}, product} << product_shift;

        // Addend: sigc * 2^(efc-25).
        // Scaled by 2^48, its shift is efc+23.
        addend_shift = {1'b0, efc} + 6'd23;
        addend_magnitude =
          {{85{1'b0}}, sigc} << addend_shift;

        product_term = sp ? -$signed(product_magnitude)
                          :  $signed(product_magnitude);
        addend_term  = sc ? -$signed(addend_magnitude)
                          :  $signed(addend_magnitude);
        exact_sum = product_term + addend_term;

        if (exact_sum == 0) begin
          // Equal-signed zeros retain their sign.  Opposite-signed zeros and
          // exact nonzero cancellation produce -0 only under RDN.
          if (sp == sc)
            result_sign = sp;
          else
            result_sign = (rnd == 3'd2);

          result = {result_sign, 15'd0};
        end else begin
          result_sign = exact_sum[95];
          magnitude = result_sign ? -exact_sum : exact_sum;
          leading_bit = msb96(magnitude);

          if (leading_bit >= 7'd34) begin
            // Normal-range exact result.  Retain eleven significand bits.
            right_shift = leading_bit - 7'd10;
            shifted = magnitude >> right_shift;
            retained = {1'b0, shifted[10:0]};

            remainder =
              magnitude & ((96'd1 << right_shift) - 96'd1);
            halfway = 96'd1 << (right_shift - 7'd1);
            remainder_nonzero = |remainder;

            increment = round_increment(
              remainder, halfway, result_sign, rnd, retained[0]
            );
            rounded = retained + {{11{1'b0}}, increment};

            exponent = {1'b0, leading_bit} - 8'd33;
            if (rounded[11])
              exponent = exponent + 8'd1;

            // 65520 * 2^48 is the binary16 overflow threshold.  The explicit
            // magnitude comparison is needed for modes whose delivered value
            // remains 65504 even though OF must be raised at the threshold.
            if ((magnitude >= (96'd65520 << 48)) ||
                (exponent >= 8'd31)) begin
              of = 1'b1;
              nx = 1'b1;

              case (rnd)
                3'd1: result =                       // RTZ
                  {result_sign, 5'h1e, 10'h3ff};

                3'd2: result =                       // RDN
                  result_sign ? {1'b1, 5'h1f, 10'h000}
                              : {1'b0, 5'h1e, 10'h3ff};

                3'd3: result =                       // RUP
                  result_sign ? {1'b1, 5'h1e, 10'h3ff}
                              : {1'b0, 5'h1f, 10'h000};

                default: result =                    // RNE and RMM
                  {result_sign, 5'h1f, 10'h000};
              endcase
            end else begin
              result = {
                result_sign,
                exponent[4:0],
                rounded[11] ? 10'h000 : rounded[9:0]
              };
              nx = remainder_nonzero;
            end
          end else begin
            // Subnormal quantum is 2^-24, or 2^24 in the fixed-point format.
            shifted = magnitude >> 24;
            retained = {1'b0, shifted[10:0]};
            remainder = magnitude & 96'hffffff;
            halfway = 96'h800000;
            remainder_nonzero = |remainder;

            increment = round_increment(
              remainder, halfway, result_sign, rnd, retained[0]
            );
            rounded = retained + {{11{1'b0}}, increment};

            nx = remainder_nonzero;
            uf = remainder_nonzero;

            if (rounded[10])
              result = {result_sign, 5'd1, 10'd0};
            else
              result = {result_sign, 5'd0, rounded[9:0]};
          end
        end
      end

      fma16 = {nv, 1'b0, of, uf, nx, result};
    end
  endfunction

  // ---------------------------------------------------------------------------
  // Temporal array
  //
  // A stage samples its operands when result pipe entry 0 is loaded.  Entry 3
  // therefore delivers that operation three enabled ticks later.  The following
  // stage samples it one tick after that, giving the required four-tick stage
  // spacing.  Status entry 2 similarly delivers flags two ticks after sampling.
  // ---------------------------------------------------------------------------

  logic [15:0] result_pipe [0:WIDTH-1][0:HEIGHT-1][0:3];
  logic [4:0]  status_pipe [0:WIDTH-1][0:HEIGHT-1][0:2];
  logic [15:0] stage_addend [0:WIDTH-1][0:HEIGHT-1];
  logic [20:0] stage_fma [0:WIDTH-1][0:HEIGHT-1];
  logic [WIDTH-1:0] flush_seen;

  generate
    for (genvar r = 0; r < WIDTH; r = r + 1) begin : g_row
      assign z_o[r] = result_pipe[r][HEIGHT-1][3];

      // This is control bookkeeping only.  It is cleared whenever flush is low
      // so that every new assertion has one normally updating status tick.
      always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni)
          flush_seen[r] <= 1'b0;
        else if (!flush_i)
          flush_seen[r] <= 1'b0;
        else if (row_clk_gate_en_i[r])
          flush_seen[r] <= 1'b1;
      end

      for (genvar k = 0; k < HEIGHT; k = k + 1) begin : g_stage
        integer j;

        if (k == 0) begin : g_stage_zero
          // z_o is read before this edge's nonblocking updates, hence this is
          // the previous enabled tick's registered row result.
          assign stage_addend[r][k] = accumulate_i
            ? result_pipe[r][HEIGHT-1][3]
            : y_i[r];
        end else begin : g_stage_later
          assign stage_addend[r][k] = result_pipe[r][k-1][3];
        end

        assign stage_fma[r][k] =
          fma16(x_i[r][k], w_i[k], stage_addend[r][k], rnd_i);

        assign status_o[r][k] = status_pipe[r][k][2];

        always_ff @(posedge clk_i or negedge rst_ni) begin
          if (!rst_ni) begin
            for (j = 0; j < 4; j = j + 1)
              result_pipe[r][k][j] <= 16'h0000;
            for (j = 0; j < 3; j = j + 1)
              status_pipe[r][k][j] <= 5'b00000;
          end else if (row_clk_gate_en_i[r]) begin
            if (flush_i) begin
              // Simultaneous flush of the whole chain, independent of
              // reg_enable_i.
              for (j = 0; j < 4; j = j + 1)
                result_pipe[r][k][j] <= 16'h0000;

              // Status advances on only the first tick of an assertion.
              if (!flush_seen[r]) begin
                status_pipe[r][k][0] <= stage_fma[r][k][20:16];
                for (j = 1; j < 3; j = j + 1)
                  status_pipe[r][k][j] <= status_pipe[r][k][j-1];
              end
            end else if (reg_enable_i) begin
              result_pipe[r][k][0] <= stage_fma[r][k][15:0];
              for (j = 1; j < 4; j = j + 1)
                result_pipe[r][k][j] <= result_pipe[r][k][j-1];

              status_pipe[r][k][0] <= stage_fma[r][k][20:16];
              for (j = 1; j < 3; j = j + 1)
                status_pipe[r][k][j] <= status_pipe[r][k][j-1];
            end
          end
        end
      end
    end
  endgenerate

endmodule
