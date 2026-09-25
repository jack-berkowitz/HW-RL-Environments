// Exact binary16 fused multiply-accumulate array.
// Four registers per stage: align/product, exact sum, round, delivery.
// A sample at enabled edge n produces flags at n+2 and data at n+3.
// All finite arithmetic is integer arithmetic in units of 2^-48.
module fp16_gemm_array #(
  parameter int unsigned HEIGHT = 8,
  parameter int unsigned WIDTH = 8
) (
  input logic clk_i, rst_ni,
  input logic [WIDTH-1:0][HEIGHT-1:0][15:0] x_i,
  input logic [HEIGHT-1:0][15:0] w_i,
  input logic [WIDTH-1:0][15:0] y_i,
  output logic [WIDTH-1:0][15:0] z_o,
  input logic [2:0] rnd_i,
  input logic accumulate_i,
  input logic [WIDTH-1:0] row_clk_gate_en_i,
  input logic reg_enable_i, flush_i,
  output logic [WIDTH-1:0][HEIGHT-1:0][4:0] status_o
);
  for (genvar r=0; r<WIDTH; r++) begin : rows
    logic [HEIGHT:0][15:0] chain;
    logic flush_seen;
    // Remember a flush only on a row clock edge. A stalled first flush
    // still clears data, but does not consume the first enabled flag update.
    always_ff @(posedge clk_i or negedge rst_ni) begin
      if (!rst_ni) flush_seen <= 1'b0;
      else if (row_clk_gate_en_i[r]) begin
        if (!flush_i) flush_seen <= 1'b0;
        else if (reg_enable_i) flush_seen <= 1'b1;
      end
    end
    assign chain[0] = accumulate_i ? z_o[r] : y_i[r];
    assign z_o[r] = chain[HEIGHT];
    for (genvar k=0; k<HEIGHT; k++) begin : stages
      fp16_gemm_fma_stage u_fma (
        .clk_i, .rst_ni, .row_en_i(row_clk_gate_en_i[r]),
        .reg_en_i(reg_enable_i), .flush_i,
        .freeze_flags_i(flush_i && flush_seen),
        .a_i(x_i[r][k]), .b_i(w_i[k]), .c_i(chain[k]),
        .rnd_i, .result_o(chain[k+1]), .status_o(status_o[r][k])
      );
    end
  end
endmodule

module fp16_gemm_fma_stage (
  input logic clk_i, rst_ni, row_en_i, reg_en_i,
  input logic flush_i, freeze_flags_i,
  input logic [15:0] a_i, b_i, c_i,
  input logic [2:0] rnd_i,
  output logic [15:0] result_o,
  output logic [4:0] status_o
);
  typedef struct packed {
    logic [79:0] product, addend;
    logic ps, cs;
    logic [2:0] rnd;
    logic special, invalid;
    logic [15:0] special_value;
  } aligned_t;
  typedef struct packed {
    logic [79:0] magnitude;
    logic sign;
    logic [2:0] rnd;
    logic special, invalid;
    logic [15:0] special_value;
  } sum_t;
  aligned_t align_d, align_q;
  sum_t sum_d, sum_q;
  logic [15:0] rounded_d, rounded_q;
  logic [4:0] flags_d;

  // Fixed-depth priority tree, not a per-bit scan nested in array loops.
  function automatic logic [6:0] leading_index(input logic [79:0] v);
    logic [127:0] t;
    logic [6:0] n;
    begin
      t = {48'b0,v}; n = 0;
      if (|t[127:64]) begin t=t>>64; n=n+7'd64; end
      if (|t[63:32]) begin t=t>>32; n=n+7'd32; end
      if (|t[31:16]) begin t=t>>16; n=n+7'd16; end
      if (|t[15:8]) begin t=t>>8; n=n+7'd8; end
      if (|t[7:4]) begin t=t>>4; n=n+7'd4; end
      if (|t[3:2]) begin t=t>>2; n=n+7'd2; end
      if (t[1]) n=n+7'd1;
      return n;
    end
  endfunction

  always_comb begin : align_operands
    logic [10:0] ma, mb, mc;
    logic [21:0] product;
    logic [5:0] ea, eb, ec;
    logic an, bn, cn, ai, bi, ci, az, bz;
    logic snan, bad_product, bad_sum;
    logic [6:0] pshift, cshift;
    ma = {(|a_i[14:10]),a_i[9:0]};
    mb = {(|b_i[14:10]),b_i[9:0]};
    mc = {(|c_i[14:10]),c_i[9:0]};
    ea = a_i[14:10]==0 ? 6'd1 : {1'b0,a_i[14:10]};
    eb = b_i[14:10]==0 ? 6'd1 : {1'b0,b_i[14:10]};
    ec = c_i[14:10]==0 ? 6'd1 : {1'b0,c_i[14:10]};
    an = (&a_i[14:10]) && (|a_i[9:0]);
    bn = (&b_i[14:10]) && (|b_i[9:0]);
    cn = (&c_i[14:10]) && (|c_i[9:0]);
    ai = (&a_i[14:10]) && !(|a_i[9:0]);
    bi = (&b_i[14:10]) && !(|b_i[9:0]);
    ci = (&c_i[14:10]) && !(|c_i[9:0]);
    az = !(|a_i[14:0]); bz = !(|b_i[14:0]);
    snan = (an && !a_i[9]) || (bn && !b_i[9]) || (cn && !c_i[9]);
    bad_product = (ai && bz) || (bi && az);
    bad_sum = (ai || bi) && !an && !bn && ci &&
              ((a_i[15]^b_i[15]) != c_i[15]);
    product = ma * mb;
    pshift = {1'b0,ea}+{1'b0,eb}-7'd2;
    cshift = {1'b0,ec}+7'd23;
    align_d = '0;
    align_d.product = {58'b0,product} << pshift;
    align_d.addend = {69'b0,mc} << cshift;
    align_d.ps = a_i[15]^b_i[15];
    align_d.cs = c_i[15];
    align_d.rnd = rnd_i;
    align_d.special = an || bn || cn || ai || bi || ci;
    align_d.invalid = snan || bad_product || bad_sum;
    if (an || bn || cn || bad_product || bad_sum)
      align_d.special_value = 16'h7e00;
    else if (ai || bi)
      align_d.special_value = {align_d.ps,15'h7c00};
    else align_d.special_value = {c_i[15],15'h7c00};
  end

  always_comb begin : exact_add
    sum_d = '0;
    sum_d.rnd = align_q.rnd;
    sum_d.special = align_q.special;
    sum_d.invalid = align_q.invalid;
    sum_d.special_value = align_q.special_value;
    if (align_q.ps == align_q.cs) begin
      sum_d.magnitude = align_q.product + align_q.addend;
      sum_d.sign = align_q.ps;
    end else if (align_q.product > align_q.addend) begin
      sum_d.magnitude = align_q.product - align_q.addend;
      sum_d.sign = align_q.ps;
    end else if (align_q.product < align_q.addend) begin
      sum_d.magnitude = align_q.addend - align_q.product;
      sum_d.sign = align_q.cs;
    end else begin
      sum_d.magnitude = '0;
      sum_d.sign = (align_q.rnd == 3'd2);
    end
  end

  always_comb begin : round_once
    logic [6:0] top, shift;
    logic [79:0] shifted, tail;
    logic [11:0] significand;
    logic [5:0] exponent;
    logic guard_bit, sticky, inexact, increment, to_inf;
    top = leading_index(sum_q.magnitude);
    // Normal significands retain eleven bits. Subnormals use a fixed
    // quantum of 2^-24, i.e. discard exactly 24 accumulator bits.
    shift = top >= 7'd34 ? top-7'd10 : 7'd24;
    shifted = sum_q.magnitude >> shift;
    tail = sum_q.magnitude << (7'd80-shift);
    guard_bit = tail[79];
    sticky = |tail[78:0];
    inexact = guard_bit || sticky;
    increment = 1'b0;
    case (sum_q.rnd)
      3'd0: increment = guard_bit && (sticky || shifted[0]);
      3'd1: increment = 1'b0;
      3'd2: increment = sum_q.sign && inexact;
      3'd3: increment = !sum_q.sign && inexact;
      3'd4: increment = guard_bit;
      default: increment = 1'b0;
    endcase
    significand = {1'b0,shifted[10:0]} + {11'b0,increment};
    exponent = top >= 7'd34 ? 6'(top-7'd33) : 6'd0;
    if (top >= 7'd34 && significand[11]) begin
      significand = significand >> 1;
      exponent = exponent+6'd1;
    end else if (top < 7'd34 && significand[10]) exponent = 6'd1;
    to_inf = (sum_q.rnd==3'd0) || (sum_q.rnd==3'd4) ||
             (sum_q.rnd==3'd2 && sum_q.sign) ||
             (sum_q.rnd==3'd3 && !sum_q.sign);
    flags_d = '0;
    rounded_d = {sum_q.sign,exponent[4:0],significand[9:0]};
    if (sum_q.special) begin
      rounded_d = sum_q.special_value;
      flags_d[4] = sum_q.invalid;
    end else if (sum_q.magnitude == 0) begin
      rounded_d = {sum_q.sign,15'b0};
    end else if (exponent >= 6'd31) begin
      rounded_d = to_inf ? {sum_q.sign,15'h7c00} : {sum_q.sign,15'h7bff};
      flags_d = 5'b00101;
    end else begin
      flags_d[0] = inexact;
      // Detect tininess after rounding: a rounded minimum normal is not tiny.
      flags_d[1] = inexact && (exponent == 0);
    end
  end

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      align_q <= '0; sum_q <= '0; rounded_q <= '0;
      result_o <= '0; status_o <= '0;
    end else if (row_en_i) begin
      if (flush_i) begin
        align_q <= '0; sum_q <= '0; rounded_q <= '0; result_o <= '0;
        if (reg_en_i && !freeze_flags_i) status_o <= flags_d;
      end else if (reg_en_i) begin
        align_q <= align_d;
        sum_q <= sum_d;
        rounded_q <= rounded_d;
        result_o <= rounded_q;
        status_o <= flags_d;
      end
    end
  end
endmodule
