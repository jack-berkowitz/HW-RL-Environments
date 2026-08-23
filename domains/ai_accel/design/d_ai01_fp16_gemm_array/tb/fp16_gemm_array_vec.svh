// fp16_gemm_array_vec.svh -- d_ai01 vector record layout.
//
// INCLUDED BY BOTH the capture rig (tb/audit/capture_vectors_tb.sv) and the
// scoring TB (tb/fp16_gemm_array_tb.sv). One definition, two readers: if the
// layout lived separately in each, a silent disagreement between them would
// present as a DUT mismatch on every vector, which is the most expensive kind
// of false signal to chase.
//
// One record is ONE CYCLE: the whole operand field and control state presented
// at that cycle, followed by what the reference delivered at that same cycle.
// The array's contract is temporal (see spec A3), so a record that held only an
// operand triple could not express it.

`ifndef FP16_GEMM_ARRAY_VEC_SVH
`define FP16_GEMM_ARRAY_VEC_SVH

typedef struct packed {
  // --- stimulus ---
  logic [`VW-1:0][`VH-1:0][15:0] x;
  logic          [`VH-1:0][15:0] w;
  logic [`VW-1:0]         [15:0] y;
  logic                    [2:0] rnd;
  logic                          accumulate;
  logic                          flush;
  logic                          reg_enable;
  logic [`VW-1:0]                row_gate;
  // --- what the reference delivered at this same cycle ---
  logic [`VW-1:0]         [15:0] z;
  logic [`VW-1:0][`VH-1:0] [4:0] status;
} rec_t;

localparam int unsigned REC_W = $bits(rec_t);

// Deterministic 32-bit xorshift. The scoring run must reproduce the capture run
// exactly, so nothing here may depend on simulator randomisation.
function automatic int unsigned xs32(input int unsigned s);
  int unsigned v = s;
  v ^= (v << 13);
  v ^= (v >> 17);
  v ^= (v << 5);
  return v;
endfunction

// A binary16 value drawn to be ARITHMETICALLY INTERESTING rather than uniform.
// Uniform 16-bit patterns are ~3% infinity/NaN and mostly enormous exponents, so
// a chain of them saturates to infinity within a stage or two and the vectors
// stop testing the adder at all.
//
//   band 0  exponent 0x0C..0x12, i.e. magnitudes around 1 -- the bulk of the
//           set, chosen so an 8-deep chain accumulates without saturating
//   band 1  exponent 0x01..0x08, small normals, drives toward underflow
//   band 2  exponent 0x17..0x1E, large normals, drives toward overflow
//   band 3  subnormals, exponent field zero, nonzero significand
function automatic logic [15:0] fp16_draw(input int unsigned r, input int unsigned band);
  logic        sgn  = r[31];
  logic [9:0]  mant = r[9:0];
  logic [4:0]  expo;
  begin
    case (band)
      1:       expo = 5'h01 + (r[18:16] % 8);
      2:       expo = 5'h17 + (r[18:16] % 8);
      3:       return {sgn, 5'h00, (mant == 0) ? 10'h1 : mant};
      default: expo = 5'h0C + (r[18:16] % 7);
    endcase
    return {sgn, expo, mant};
  end
endfunction

`endif
