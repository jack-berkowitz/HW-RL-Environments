// sdp_requant_alt_ref.sv -- d_ai04 SECOND SOURCE. Not the reference, not a
// submission, not in the scored path.
//
// WHY. The reference was written by the author of the spec, from the
// MEASUREMENTS the spec was derived from. That tests the reference against the
// measurements. It does not test whether the SPEC IS SUFFICIENT -- whether the
// text alone determines the design. d_ca03's second source found four contract
// defects doing exactly this.
//
// THIS FILE WAS WRITTEN FROM spec/sdp_requant_iface.sv ALONE. Where the spec
// left something undetermined, the gap is recorded in a NOTE below rather than
// resolved by looking at the reference or the measurements.
//
// IT IS DELIBERATELY A DIFFERENT DESIGN in the three places the spec leaves
// free (P3), so that "both conform" is demonstrated rather than asserted:
//
//   1. STRUCTURE. Two stages -- a raw input register, then a computing stage
//      feeding a two-entry output queue -- so LATENCY IS 2, not the reference's
//      1, and CAPACITY IS 3, not the reference's 2. A4 says latency is free and
//      the anchor's numbers are "for reference and not as a requirement". If the
//      scoring testbench has quietly assumed latency 1, this file fails and that
//      is a TESTBENCH defect, not a design one.
//   2. ROUNDING. Floor-then-correct in the SIGNED domain rather than
//      round-half-up on the magnitude. F4 is ties-away, which in signed floor
//      terms is: round up when 2*r >= 2^t for a non-negative value and when
//      2*r > 2^t for a negative one. The asymmetry in that comparison IS the
//      tie rule, and getting it from the other side is the point of the exercise.
//   3. NORMALISATION. A priority case over the ten subnormal mantissa positions
//      instead of a counting loop.

`timescale 1ns/1ps

module sdp_requant_alt (
    input  logic         clk,
    input  logic         rst_n,
    input  logic [63:0]  in_data,
    input  logic         in_valid,
    output logic         in_ready,
    input  logic [ 1:0]  cfg_precision,
    input  logic [31:0]  cfg_offset,
    input  logic [15:0]  cfg_scale,
    input  logic [ 5:0]  cfg_truncate,
    input  logic         cfg_bypass,
    input  logic         cfg_nan_to_zero,
    output logic [127:0] out_data,
    output logic         out_valid,
    input  logic         out_ready
);

  // ---- integer lane: floor-then-correct, signed domain -----------------------
  function automatic logic [31:0] ilane(
      input logic [15:0] x, input logic [31:0] off, input logic [15:0] sc,
      input logic [5:0] tr, input logic byp);
    logic signed [63:0] v, q, r, twop, res;
    begin
      if (byp) return {{16{x[15]}}, x};                        // F6

      // F5: exact, no intermediate rounding or saturation.
      v = $signed({{48{x[15]}}, x}) - $signed({{32{off[31]}}, off});
      v = v * $signed({{48{sc[15]}}, sc});

      if (tr == 6'd0) begin
        res = v;
      end else begin
        twop = 64'sd1 <<< tr;
        q    = v >>> tr;              // arithmetic shift == floor
        r    = v - (q <<< tr);        // 0 <= r < 2^tr, because q is the floor
        // F4 ties-away, expressed against the floor:
        //   non-negative -- round up on r*2 >= 2^tr (the tie goes up)
        //   negative     -- round up on r*2 >  2^tr (the tie stays at the floor,
        //                   which is further from zero)
        if (v >= 64'sd0) begin
          if ((r <<< 1) >= twop) q = q + 64'sd1;
        end else begin
          if ((r <<< 1) >  twop) q = q + 64'sd1;
        end
        res = q;
      end

      if (res >  64'sd2147483647)  return 32'h7FFFFFFF;        // F5, last
      if (res < -64'sd2147483648)  return 32'h80000000;
      return res[31:0];
    end
  endfunction

  // ---- float lane: priority case, no counting loop ---------------------------
  function automatic logic [31:0] flane(input logic [15:0] x, input logic n2z);
    logic       s; logic [4:0] e; logic [9:0] m;
    logic [7:0] e32; logic [9:0] m32;
    begin
      s = x[15]; e = x[14:10]; m = x[9:0];

      if (e == 5'h1F) begin
        if (m == 10'd0)  return {s, 8'hFE, 23'h7FFFFF};        // F8
        if (n2z)         return 32'h0000_0000;                 // F9
        return {s, 8'hFF, 13'b0, m};                           // F9
      end
      if (e != 5'd0) return {s, {3'b0, e} + 8'd112, m, 13'b0};  // F7 normal
      if (m == 10'd0) return {s, 31'b0};                        // signed zero

      // F7 subnormal: the leading one sits at bit p, the value is
      // 1.f * 2^(p-24), so the fp32 exponent field is 127 + p - 24 = 103 + p.
      // PRIORITY, not UNIQUE. Several mantissa bits are set at once in any
      // subnormal with more than one significant digit, so `unique` is violated
      // on the first such value -- 0x03FF trips it immediately. The intent is
      // "the highest set bit", which is priority.
      priority case (1'b1)
        m[9]: begin e32 = 8'd112; m32 = m <<  1; end
        m[8]: begin e32 = 8'd111; m32 = m <<  2; end
        m[7]: begin e32 = 8'd110; m32 = m <<  3; end
        m[6]: begin e32 = 8'd109; m32 = m <<  4; end
        m[5]: begin e32 = 8'd108; m32 = m <<  5; end
        m[4]: begin e32 = 8'd107; m32 = m <<  6; end
        m[3]: begin e32 = 8'd106; m32 = m <<  7; end
        m[2]: begin e32 = 8'd105; m32 = m <<  8; end
        m[1]: begin e32 = 8'd104; m32 = m <<  9; end
        default: begin e32 = 8'd103; m32 = m << 10; end
      endcase
      return {s, e32, m32, 13'b0};
    end
  endfunction

  // ---- stage 1: raw capture. A5 -- the configuration travels WITH the word ----
  logic        s1_v;
  logic [63:0] s1_d;
  logic [ 1:0] s1_pr;
  logic [31:0] s1_off;
  logic [15:0] s1_sc;
  logic [ 5:0] s1_tr;
  logic        s1_byp, s1_n2z;

  // ---- stage 2: a two-entry result queue -------------------------------------
  logic [127:0] q_mem [0:1];
  logic         q_wp, q_rp;
  logic [1:0]   q_cnt;

  // A2: in_ready is a function of REGISTERS ONLY. There is no path from
  // out_ready to it. Three slots is what A2+A3+A4 cost with a registered
  // compute stage -- one more than the reference needs, because the reference
  // computes combinationally and so has nothing in flight to hold.
  wire [1:0] occ = {1'b0, s1_v} + q_cnt;
  assign in_ready  = (occ != 2'd3);
  assign out_valid = (q_cnt != 2'd0);
  assign out_data  = q_mem[q_rp];

  wire accept  = in_valid  && in_ready;
  wire emit    = out_valid && out_ready;
  wire q_room  = (q_cnt != 2'd2) || emit;
  wire advance = s1_v && q_room;

  logic [127:0] computed;
  always_comb begin
    for (int k = 0; k < 4; k++) begin
      logic [15:0] xk;
      xk = s1_d[16*k +: 16];
      computed[32*k +: 32] = (s1_pr == 2'd2) ? flane(xk, s1_n2z)
                                             : ilane(xk, s1_off, s1_sc, s1_tr, s1_byp);
    end
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      s1_v <= 1'b0; s1_d <= 64'd0; s1_pr <= 2'd0; s1_off <= 32'd0;
      s1_sc <= 16'd0; s1_tr <= 6'd0; s1_byp <= 1'b0; s1_n2z <= 1'b0;
      q_wp <= 1'b0; q_rp <= 1'b0; q_cnt <= 2'd0;
      q_mem[0] <= 128'd0; q_mem[1] <= 128'd0;
    end else begin
      if (accept) begin
        s1_d   <= in_data;   s1_pr  <= cfg_precision; s1_off <= cfg_offset;
        s1_sc  <= cfg_scale; s1_tr  <= cfg_truncate;  s1_byp <= cfg_bypass;
        s1_n2z <= cfg_nan_to_zero;
        s1_v   <= 1'b1;
      end else if (advance) begin
        s1_v <= 1'b0;
      end

      if (advance) begin
        q_mem[q_wp] <= computed;
        q_wp        <= ~q_wp;
      end
      if (emit) q_rp <= ~q_rp;

      case ({advance, emit})
        2'b10:   q_cnt <= q_cnt + 2'd1;
        2'b01:   q_cnt <= q_cnt - 2'd1;
        default: q_cnt <= q_cnt;
      endcase
    end
  end

endmodule

// The scoring testbench instantiates `sdp_requant`. This wrapper lets the second
// source be dropped in unchanged, the way d_ca03's alt_ref is.
module sdp_requant (
    input  logic clk, input logic rst_n,
    input  logic [63:0] in_data, input logic in_valid, output logic in_ready,
    input  logic [1:0] cfg_precision, input logic [31:0] cfg_offset,
    input  logic [15:0] cfg_scale, input logic [5:0] cfg_truncate,
    input  logic cfg_bypass, input logic cfg_nan_to_zero,
    output logic [127:0] out_data, output logic out_valid, input logic out_ready
);
  sdp_requant_alt u (.*);
endmodule
