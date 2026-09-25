// =============================================================================
// sdp_requant -- 4-lane requantise / convert unit (d_ai04)
//
// Structure
//   * 2-slot skid buffer, latency 1, II 1. The skid slot holds the RAW input
//     word plus its config (A5); the output slot holds the computed result.
//     in_ready = ~skid_vld_q (flop output, no path from out_ready -- A2).
//   * One shared datapath sits between the skid mux and the output register.
//   * Integer product decomposed on the 16-bit scale (G4):
//         (x - off) * sc  =  x*sc  -  off*sc
//     off*sc (32x16) is computed ONCE per word and shared by all four lanes;
//     each lane then needs only a 16x16 multiply and a 48-bit subtract.
//     Exact in 48 bits signed: |p| <= (2^31 + 2^15 - 1) * 2^15 < 2^47.
//   * Ties-away rounding as a sign-corrected increment on the floor result:
//         s   = (2p) >>> t          // floor(p / 2^(t-1)), t=0 -> 2p
//         q   = s >> 1, half = s[0]
//         inc = half & (p >= 0 | sticky)
//     t = 0 falls out naturally (half = 0). Shift amounts >= 48 are exact
//     because >>> sign-fills. The sticky mask depends only on t, so it is
//     built once and shared.
// =============================================================================
module sdp_requant (
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

  // ---------------------------------------------------------------------------
  // Per-word context. bypass is only live in integer mode and nan_to_zero only
  // in float mode (F6, F9), so a single bit carries whichever one applies.
  // ---------------------------------------------------------------------------
  typedef struct packed {
    logic [63:0] data;
    logic        is_float;
    logic        flag;     // float: nan_to_zero   integer: bypass
    logic [31:0] offset;
    logic [15:0] scale;
    logic [ 5:0] trunc;
  } ctx_t;

  ctx_t          in_ctx;
  ctx_t          src;
  ctx_t          skid_q;
  logic          skid_vld_q;
  logic [127:0]  out_q;
  logic          out_vld_q;
  logic [127:0]  result;

  logic          accept;
  logic          out_free;

  // ---------------------------------------------------------------------------
  // Flow control
  // ---------------------------------------------------------------------------
  assign in_ready  = ~skid_vld_q;
  assign out_valid = out_vld_q;
  assign out_data  = out_q;

  assign accept    = in_valid & ~skid_vld_q;
  assign out_free  = ~out_vld_q | out_ready;

  assign in_ctx.data     = in_data;
  assign in_ctx.is_float = (cfg_precision == 2'd2);
  assign in_ctx.flag     = (cfg_precision == 2'd2) ? cfg_nan_to_zero : cfg_bypass;
  assign in_ctx.offset   = cfg_offset;
  assign in_ctx.scale    = cfg_scale;
  assign in_ctx.trunc    = cfg_truncate;

  // skid slot is older than anything on the input when occupied
  assign src = skid_vld_q ? skid_q : in_ctx;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      skid_vld_q <= 1'b0;
      out_vld_q  <= 1'b0;
    end else if (out_free) begin
      out_vld_q  <= skid_vld_q | accept;
      skid_vld_q <= 1'b0;
    end else if (accept) begin
      skid_vld_q <= 1'b1;
    end
  end

  // data registers carry no reset: validity alone gates them (A6)
  always_ff @(posedge clk) begin
    if (out_free & (skid_vld_q | accept)) out_q  <= result;
    if (~out_free & accept)               skid_q <= in_ctx;
  end

  // ---------------------------------------------------------------------------
  // Shared per-word terms
  // ---------------------------------------------------------------------------
  logic signed [31:0] off_s;
  logic signed [15:0] sc_s;
  logic signed [47:0] k_prod;   // off * sc, exact
  logic        [47:0] smask;    // smask[i] = (i < trunc-1): bits below the half bit

  assign off_s  = $signed(src.offset);
  assign sc_s   = $signed(src.scale);
  assign k_prod = 48'(off_s) * 48'(sc_s);          // sign-extended, exact

  always_comb begin
    for (int i = 0; i < 48; i++) smask[i] = ((i + 1) < int'(src.trunc));
  end

  // ---------------------------------------------------------------------------
  // Lanes
  // ---------------------------------------------------------------------------
  for (genvar k = 0; k < 4; k++) begin : g_lane
    logic        [15:0] h;
    // integer path
    logic signed [15:0] x;
    logic signed [31:0] xs;
    logic        [47:0] p;
    logic signed [48:0] p2;
    logic signed [48:0] s;
    logic               half;
    logic               sticky;
    logic               inc;
    logic        [48:0] r;
    logic        [31:0] int_sat;
    logic        [31:0] int_res;
    // float path
    logic               fs;
    logic        [ 4:0] fe;
    logic        [ 9:0] fm;
    logic        [ 3:0] lz;
    logic        [ 9:0] nm;
    logic        [ 7:0] sub_exp;
    logic        [ 7:0] nrm_exp;
    logic        [31:0] flt_res;

    assign h = src.data[16*k +: 16];

    // ---- integer: exact product, ties-away round, saturate last ----------
    assign x      = $signed(h);
    assign xs     = x * sc_s;                         // 16x16 -> 32, exact
    assign p      = $unsigned(48'(xs) - k_prod);    // exact in 48b
    assign p2     = $signed({p, 1'b0});
    assign s      = p2 >>> src.trunc;
    assign half   = s[0];
    assign sticky = |(p & smask);
    assign inc    = half & (~p[47] | sticky);
    assign r      = {s[48], s[48:1]} + {48'd0, inc};

    assign int_sat = (r[48:31] == {18{r[48]}}) ? r[31:0]
                   : (r[48] ? 32'h8000_0000 : 32'h7FFF_FFFF);
    assign int_res = src.flag ? {{16{h[15]}}, h} : int_sat;

    // ---- float: exact binary16 -> binary32 --------------------------------
    assign fs = h[15];
    assign fe = h[14:10];
    assign fm = h[9:0];

    always_comb begin
      lz = 4'd9;
      for (int i = 0; i < 10; i++) if (fm[i]) lz = 4'($unsigned(9 - i));
    end

    assign nm      = fm << (lz + 4'd1);               // drop the leading one
    assign sub_exp = 8'd112 - {4'd0, lz};             // 2^(msb-24) -> 103..112
    assign nrm_exp = {3'd0, fe} + 8'd112;

    always_comb begin
      if (fe == 5'h1F) begin
        if (fm == 10'd0)   flt_res = {fs, 8'hFE, 23'h7F_FFFF};      // inf -> +-FLT_MAX
        else if (src.flag) flt_res = 32'h0000_0000;                 // NaN, nan_to_zero
        else               flt_res = {fs, 8'hFF, 13'd0, fm};        // NaN, payload low
      end else if (fe == 5'd0) begin
        if (fm == 10'd0)   flt_res = {fs, 31'd0};                   // signed zero
        else               flt_res = {fs, sub_exp, nm, 13'd0};      // subnormal
      end else begin
        flt_res = {fs, nrm_exp, fm, 13'd0};
      end
    end

    assign result[32*k +: 32] = src.is_float ? flt_res : int_res;
  end

endmodule