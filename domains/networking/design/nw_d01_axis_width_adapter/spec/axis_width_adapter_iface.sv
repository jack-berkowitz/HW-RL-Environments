// =============================================================================
// axis_width_adapter_iface.sv  --  PORT DEFINITION ONLY (no implementation)
// =============================================================================
// Task: implement an AXI4-Stream data-width adapter. The input stream is
// S_BYTES wide, the output stream is M_BYTES wide, and the adapter converts
// between them in either direction without altering the byte stream.
//
// The contract is a BYTE-STREAM contract, not a beat contract. Beats are an
// artifact of the bus width; packets and their bytes are what must survive.
//
// -----------------------------------------------------------------------------
// PARAMETERS
// -----------------------------------------------------------------------------
//   S_BYTES : input  datapath width in BYTES. Legal: 1, 2, 4, 8.
//   M_BYTES : output datapath width in BYTES. Legal: 1, 2, 4, 8.
//   USER_W  : width of the tuser sideband. Legal: 1..8.
//
//   LEGALITY CONSTRAINT: one width must divide the other, i.e.
//       (S_BYTES % M_BYTES == 0) || (M_BYTES % S_BYTES == 0)
//   With the legal set {1,2,4,8} every combination satisfies this, so all 16
//   pairs are legal, including S_BYTES == M_BYTES (pass-through).
//   Any S_BYTES or M_BYTES outside {1,2,4,8} is ILLEGAL and need not be handled.
//
// -----------------------------------------------------------------------------
// PRECONDITIONS ON THE INPUT STREAM  (guaranteed by the producer -- do NOT add
//                    logic to police these; behaviour when violated is
//                    unconstrained and is never checked)
// -----------------------------------------------------------------------------
//   P1. s_keep is CONTIGUOUS FROM BIT 0. Legal values are 0...01, 0...011,
//       0...0111, ... , 1...1. Holes (e.g. 4'b1011) are illegal.
//   P2. Only the LAST beat of a packet (the beat with s_last == 1) may be
//       partial. Every non-last beat has all keep bits set.
//   P3. s_keep is never all-zero on a valid beat: every accepted beat carries
//       at least one live byte.
//   P4. A packet is a maximal run of accepted input beats ending with
//       s_last == 1. The stream begins on a packet boundary.
//
// -----------------------------------------------------------------------------
// WHAT THE ADAPTER MUST DO
// -----------------------------------------------------------------------------
//   Define the BYTE STREAM of a packet as the concatenation, in order, of every
//   keep-enabled byte of every beat of that packet, lane 0 first within a beat.
//
//   C1. BYTE PRESERVATION. The byte stream of output packet N must equal the
//       byte stream of input packet N, exactly, byte for byte. No insertion, no
//       deletion, no reordering, no alteration.
//   C2. PACKET COUNT AND ORDER. N input packets produce exactly N output
//       packets, in the same order. Packets are never merged or split.
//   C3. OUTPUT FRAMING. m_last is 1 on exactly the final beat of each output
//       packet and 0 on every other beat.
//   C4. OUTPUT KEEP. Output beats obey the same rules required of the input:
//       m_keep is contiguous from bit 0, only the m_last beat of a packet may
//       be partial, and m_keep is never all-zero on a valid beat.
//   C5. TUSER. m_user on the m_last beat of output packet N must equal s_user
//       as presented on the s_last beat of input packet N. tuser is a
//       PER-PACKET sideband here: its value on non-last beats is UNCONSTRAINED
//       and is never checked. Drive it however is convenient.
//
//   Byte lane numbering: within a beat, byte i occupies data[i*8 +: 8] and is
//   enabled by keep[i]. Byte 0 is the least significant and is FIRST in the
//   byte stream.
//
// -----------------------------------------------------------------------------
// HANDSHAKE CONTRACT
// -----------------------------------------------------------------------------
//   Standard AXI-Stream valid/ready on both sides. A beat transfers on a rising
//   clk edge at which valid && ready are both high.
//
//   H1. s_ready MUST NOT depend combinationally on s_valid. (m_ready may
//       influence s_ready; that is legal backpressure, not a loop.)
//   H2. Once s_valid is asserted the producer holds it, and holds
//       s_data/s_keep/s_last/s_user stable, until the beat is accepted. The
//       checker honours this; you may rely on it.
//   H3. When m_valid is high and m_ready is low, m_valid must REMAIN high and
//       m_data/m_keep/m_last/m_user must remain STABLE until the beat is
//       accepted. Nothing may be dropped or reordered under backpressure.
//   H4. No input beat may be dropped or duplicated.
//
// -----------------------------------------------------------------------------
// LATENCY AND THROUGHPUT
// -----------------------------------------------------------------------------
//   Latency is IMPLEMENTATION-DEFINED and is NOT checked. Pipeline it freely.
//
//   THROUGHPUT IS NOT CONSTRAINED AND IS NOT GATED. It is measured and printed
//   as a METRIC only. A design that inserts idle cycles is still CORRECT; it
//   will simply look worse on the reported number. This is deliberate: a
//   throughput floor would encode one implementation's pipelining choices into
//   the contract, and a differently-structured correct adapter would fail.
//
//   The only timing requirement is LIVENESS: if the producer keeps s_valid high
//   and the consumer keeps m_ready high, the adapter must not stall forever.
//   Concretely, with m_ready held high, every accepted input packet must be
//   fully emitted within 64 * (beats in that packet) + 64 cycles.
//
// -----------------------------------------------------------------------------
// RESET
// -----------------------------------------------------------------------------
//   rst_n is ACTIVE-LOW and SYNCHRONOUS.
//
//   R1. While rst_n is low, and in the first cycle after it is released:
//         m_valid == 0.
//   R2. s_ready may be 0 or 1 after reset; both are legal. If 0, it must become
//       1 within 64 cycles with no input offered.
//   R3. Reset asserted mid-packet DISCARDS all in-flight data. After release,
//       the next accepted beat begins a fresh packet and a fresh byte stream.
//       No partially-assembled beat may be emitted. Output signal values while
//       m_valid == 0 are don't-care.
//
// =============================================================================

module axis_width_adapter #(
    parameter int S_BYTES = 1,      // 1 / 2 / 4 / 8
    parameter int M_BYTES = 4,      // 1 / 2 / 4 / 8
    parameter int USER_W  = 1       // 1..8
) (
    input  logic                    clk,
    input  logic                    rst_n,

    // input stream
    input  logic                    s_valid,
    output logic                    s_ready,
    input  logic [S_BYTES*8-1:0]    s_data,
    input  logic [S_BYTES-1:0]      s_keep,
    input  logic                    s_last,
    input  logic [USER_W-1:0]       s_user,

    // output stream
    output logic                    m_valid,
    input  logic                    m_ready,
    output logic [M_BYTES*8-1:0]    m_data,
    output logic [M_BYTES-1:0]      m_keep,
    output logic                    m_last,
    output logic [USER_W-1:0]       m_user
);

    // IMPLEMENTATION INTENTIONALLY OMITTED.

endmodule
