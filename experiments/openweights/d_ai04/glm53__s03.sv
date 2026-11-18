// =============================================================================
// d_ai04 -- sdp_requant : 4-lane requantise / convert unit
// =============================================================================
// Architecture: two-slot skid buffer (A2 forces a registered in_ready, A3
// forces a second slot so a word accepted into a stalled stream is not lost).
// Latency 1, II 1. Configuration is captured with each word (A5) and pipelined
// through the buffer. The two modes are separate datapaths inside one lane
// function (F2); they share only the pipeline and the output register.
//
// Integer path (F3-F6): 33-bit difference, exact 49-bit product (F5), magnitude-
// domain round-to-nearest-ties-away (F4), saturation last (F5), t==0 a no-op.
// Float path (F7-F9): exact binary16 -> binary32 with subnormal normalisation
// via leading-zero count, infinity clamped to FLT_MAX, NaN payload in the low
// mantissa bits, cfg_nan_to_zero forcing NaN (only) to zero.
// =============================================================================

module sdp_requant (
    input  logic         clk,
    input  logic         rst_n,           // active-low, asynchronous assert

    input  logic [63:0]  in_data,
    input  logic         in_valid,
    output logic         in_ready,

    input  logic [ 1:0]  cfg_precision,
    input  logic [31:0]  cfg_offset,      // SIGNED, SUBTRACTED (F3)
    input  logic [15:0]  cfg_scale,       // SIGNED
    input  logic [ 5:0]  cfg_truncate,    // 0..63
    input  logic         cfg_bypass,
    input  logic         cfg_nan_to_zero,

    output logic [127:0] out_data,
    output logic         out_valid,
    input  logic         out_ready
);

  // 2 + 32 + 16 + 6 + 1 + 1 = 58 bits of configuration, captured per word (A5)
  typedef logic [57:0] cfg_t;

  // ---------------------------------------------------------------------------
  // Per-lane processing. cfg layout:
  //   [57:56] precision  [55:24] offset  [23:8] scale  [7:2] truncate
  //   [1] bypass          [0] nan_to_zero
  // ---------------------------------------------------------------------------
  function automatic logic [31:0] lane_proc (
      input cfg_t        c,
      input logic [15:0] x
  );
    logic [1:0]          prec;
    logic [31:0]         off;
    logic [15:0]         scl;
    logic [5:0]          tr;
    logic                byp;
    logic                ntz;
    logic signed [15:0]  xs;
    logic signed [32:0]  diff;
    logic signed [48:0]  prod;
    logic                pneg;
    logic [63:0]         mag;
    logic [63:0]         half;
    logic [63:0]         qmag;
    logic signed [63:0]  res;
    logic                s;
    logic [4:0]          e;
    logic [9:0]          m;
    logic [3:0]          lz;
    logic [9:0]          n;
    logic [7:0]          e32;
    logic [31:0]         r;

    prec = c[57:56];
    off  = c[55:24];
    scl  = c[23:8];
    tr   = c[7:2];
    byp  = c[1];
    ntz  = c[0];

    if (prec == 2'd2) begin
      // ---- FLOAT MODE (F7-F9): exact binary16 -> binary32 ---------------
      s = x[15];
      e = x[14:10];
      m = x[9:0];
      if (e == 5'h1F) begin
        if (m == 10'd0) begin
          r = {s, 8'h7F, 23'h7FFFFF};                 // F8: inf -> FLT_MAX
        end else begin
          r = ntz ? 32'h00000000 : {s, 8'hFF, 13'b0, m}; // F9: NaN payload low
        end
      end else if (e == 5'd0) begin
        if (m == 10'd0) begin
          r = {s, 31'b0};                             // signed zero preserved
        end else begin
          // F7: subnormal -> normal binary32, normalise by leading-zero count
          casez (m)
            10'b1????????? : lz = 4'd0;
            10'b01???????? : lz = 4'd1;
            10'b001??????? : lz = 4'd2;
            10'b0001?????? : lz = 4'd3;
            10'b00001????? : lz = 4'd4;
            10'b000001???? : lz = 4'd5;
            10'b0000001??? : lz = 4'd6;
            10'b00000001?? : lz = 4'd7;
            10'b000000001? : lz = 4'd8;
            default        : lz = 4'd9;
          endcase
          n   = m << lz;                              // MSB (bit 9) set
          e32 = 8'd112 - {4'b0000, lz};               // 127 - 15 - lz
          r   = {s, e32, n[8:0], 14'b0};
        end
      end else begin
        e32 = {3'b000, e} + 8'd112;                   // e - 15 + 127
        r   = {s, e32, m, 13'b0};
      end
    end else begin
      // ---- INTEGER MODE (F3-F6) -----------------------------------------
      xs = $signed(x);
      if (byp) begin
        r = {{16{xs[15]}}, x};                         // F6: sign-extend only
      end else begin
        // F3: offset SUBTRACTS. 33-bit difference (does not fit in 32).
        diff = $signed({xs[15], xs}) - $signed(off);
        // F5: exact product, 33 + 16 = 49 bits (does not fit in 47).
        prod = diff * $signed(scl);
        // F4: round to nearest, ties AWAY from zero, in the magnitude domain.
        pneg = prod[48];
        mag  = pneg ? -$signed(prod) : $signed(prod);
        if (tr == 6'd0) begin
          qmag = mag;                                 // t == 0 is a no-op
        end else begin
          half = 64'd1 << (tr - 6'd1);
          qmag = (mag + half) >> tr;
        end
        res = pneg ? -$signed(qmag) : $signed(qmag);
        // F5: saturation LAST, to signed 32 bits.
        if (res > 64'sd2147483647) begin
          r = 32'h7FFFFFFF;
        end else if (res < -64'sd2147483648) begin
          r = 32'h80000000;
        end else begin
          r = res[31:0];
        end
      end
    end

    lane_proc = r;
  endfunction

  // ---------------------------------------------------------------------------
  // Two-slot buffer. Slot 0 drives the output; slot 1 is the extra storage
  // A2+A3 require so a word accepted while the consumer stalls is retained.
  // ---------------------------------------------------------------------------
  cfg_t        cfg_in;
  logic        v0, v1;
  logic [63:0] d0, d1;
  cfg_t        c0, c1;
  logic        in_ready_r;
  logic        do_out;
  logic        s0v_n, s1v_n;
  logic [63:0] s0d_n, s1d_n;
  cfg_t        s0c_n, s1c_n;

  assign cfg_in = {cfg_precision, cfg_offset, cfg_scale,
                   cfg_truncate, cfg_bypass, cfg_nan_to_zero};

  assign in_ready = in_ready_r;      // registered: no comb path from out_ready
  assign out_valid = v0;
  assign do_out    = v0 & out_ready;

  always_comb begin
    out_data[31:0]   = lane_proc(c0, d0[15:0]);
    out_data[63:32]  = lane_proc(c0, d0[31:16]);
    out_data[95:64]  = lane_proc(c0, d0[47:32]);
    out_data[127:96] = lane_proc(c0, d0[63:48]);
  end

  // next state: advance on output transfer, then accept into the lowest slot
  always_comb begin
    s0v_n = v0;  s0d_n = d0;  s0c_n = c0;
    s1v_n = v1;  s1d_n = d1;  s1c_n = c1;
    if (do_out) begin
      s0v_n = v1;  s0d_n = d1;  s0c_n = c1;
      s1v_n = 1'b0;
    end
    if (in_valid && in_ready_r) begin
      if (!s0v_n) begin
        s0v_n = 1'b1;  s0d_n = in_data;  s0c_n = cfg_in;
      end else begin
        s1v_n = 1'b1;  s1d_n = in_data;  s1c_n = cfg_in;
      end
    end
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      v0          <= 1'b0;
      v1          <= 1'b0;
      d0          <= 64'd0;
      d1          <= 64'd0;
      c0          <= '0;
      c1          <= '0;
      in_ready_r  <= 1'b1;          // A6: ready high, valid low after reset
    end else begin
      v0         <= s0v_n;
      v1         <= s1v_n;
      d0         <= s0d_n;
      d1         <= s1d_n;
      c0         <= s0c_n;
      c1         <= s1c_n;
      in_ready_r <= !(s0v_n && s1v_n);
    end
  end

endmodule
