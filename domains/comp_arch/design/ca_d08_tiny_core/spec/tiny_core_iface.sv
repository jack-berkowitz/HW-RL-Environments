// =============================================================================
// tiny_core_iface.sv  --  PORT DEFINITION ONLY (no implementation)
// =============================================================================
// Task: implement a single-issue, in-order RV32I subset processor core.
//
// Deliberately the smallest real processor in this benchmark. The instruction
// set is hard-limited; everything outside it is out of scope and will never be
// fetched.
//
// -----------------------------------------------------------------------------
// INSTRUCTION SET -- exactly these 21, nothing else
// -----------------------------------------------------------------------------
//   lui  auipc  addi  add  sub  and  or  xor  slt  sltu  sll  srl  sra
//   lw  sw  beq  bne  blt  bge  jal  jalr
//
//   NOT IN SCOPE, never fetched, need not be decoded:
//   CSRs, interrupts, exceptions, misaligned access, fence, multiply/divide,
//   byte/halfword memory ops, and every I-type ALU op other than addi
//   (no slti/sltiu/andi/ori/xori/slli/srli/srai).
//
//   Semantics are exactly those of the RISC-V unprivileged ISA, RV32I base.
//   In particular, and because these are the usual places to go wrong:
//     * x0 is HARDWIRED to zero. Writes to it are discarded; reads return 0.
//     * Shift amounts use only rs2[4:0]. `sll x3, x1, x2` with x2 == 33
//       shifts by 1.
//     * `sra` is arithmetic (sign-extending), `srl` is logical (zero-filling).
//     * `slt`/`blt`/`bge` compare SIGNED; `sltu` compares UNSIGNED.
//     * `jal`/`jalr` write pc+4 to rd. For `jalr` the link value is pc+4 even
//       when rd == rs1, so it must be formed before the jump is taken.
//     * `jalr` clears bit 0 of the computed target.
//     * `auipc` adds the immediate to the PC OF THE AUIPC ITSELF.
//
// -----------------------------------------------------------------------------
// PARAMETERS
// -----------------------------------------------------------------------------
//   IMEM_AW : instruction memory address width in WORDS. Legal: 8, 10, 12.
//   DMEM_AW : data memory address width in WORDS.        Legal: 8, 10, 12.
//   Reset PC is 0. Execution begins at instruction word 0.
//
// -----------------------------------------------------------------------------
// MEMORY INTERFACES -- both ideal and single-cycle. No caches, no stalls,
//                     no wait states, no protocol.
// -----------------------------------------------------------------------------
//   INSTRUCTION FETCH (read only):
//     Drive `imem_addr` with a BYTE address. `imem_rdata` returns the word at
//     that address COMBINATIONALLY, in the same cycle. It is always valid and
//     never stalls. Only bits [IMEM_AW+1:2] of the address are decoded.
//
//   DATA MEMORY (read and write, one access per cycle at most):
//     `dmem_addr` is a BYTE address and is always word-aligned (misaligned
//     access is out of scope and never generated).
//       read : drive dmem_req=1, dmem_we=0. `dmem_rdata` returns the word
//              COMBINATIONALLY in the same cycle.
//       write: drive dmem_req=1, dmem_we=1, `dmem_wdata`. The write commits on
//              that rising clock edge.
//     Drive dmem_req=0 when not accessing memory. Only bits [DMEM_AW+1:2] of
//     the address are decoded.
//
//   Both memories are provided by the environment. Do not instantiate storage
//   for them inside the core.
//
// -----------------------------------------------------------------------------
// RETIRE INTERFACE -- the one place this spec constrains observability
// -----------------------------------------------------------------------------
// A trace-based checker can only work if the core says what it committed, so
// the commit interface is part of the contract and is pinned exactly. This is
// the ONLY exception to "the microarchitecture is yours".
//
//   R1. `retire_valid` is high for EXACTLY ONE CYCLE per committed instruction.
//       AT MOST ONE retire per cycle -- the core is single-issue.
//   R2. Instructions retire in PROGRAM ORDER.
//   R3. When `retire_valid` is high, the other retire_* outputs describe THAT
//       instruction and must be stable in that cycle. When it is low they are
//       don't-care.
//   R4. `retire_pc`     : the byte PC of the retired instruction.
//   R5. `retire_rd`     : the architectural destination register number, or 0
//       when the instruction writes no register (sw, beq, bne, blt, bge).
//   R6. `retire_rd_val` : the value written to `retire_rd`.
//       *** When retire_rd == 0, retire_rd_val MUST be 0. *** An instruction
//       whose encoded rd is x0 (for example `addi x0, x0, 999`) still retires,
//       still reports retire_rd == 0, and must report retire_rd_val == 0 --
//       NOT the value the ALU computed. x0 is hardwired; nothing was written.
//   R7. `retire_is_store` : 1 for `sw`, 0 for everything else.
//   R8. `retire_store_addr` / `retire_store_data` : the byte address written
//       and the word written, valid only when retire_is_store is 1.
//
//   THE COMPARISON IS ORDER-BASED, NEVER CYCLE-STAMPED. The checker matches the
//   Nth retire against the Nth expected entry, at whatever cycle it arrives. It
//   never asserts when a retire happens, only that the sequence is right.
//
// -----------------------------------------------------------------------------
// WHAT IS NOT CONSTRAINED
// -----------------------------------------------------------------------------
//   PIPELINE DEPTH IS YOURS. Single-cycle, two-stage, five-stage, anything.
//   So are: forwarding vs interlocking, whether branches are predicted, how
//   load-use hazards are resolved, and the cycle count of any instruction.
//   None of it is checked. Only the retire SEQUENCE is.
//
//   The only timing requirement is LIVENESS: the core must retire its Nth
//   instruction within 64*N + 256 cycles of reset being released. That bound is
//   loose enough for any sane design and exists so a hung core fails rather
//   than hanging the checker.
//
// -----------------------------------------------------------------------------
// RESET
// -----------------------------------------------------------------------------
//   rst_n is ACTIVE-LOW and SYNCHRONOUS.
//   R9.  While rst_n is low, retire_valid == 0.
//        AFTER release, when the first retire happens is NOT constrained. A
//        single-cycle core may retire in its very first active cycle; a deeply
//        pipelined one may take many. That delay is a pipeline-depth artifact,
//        and pipeline depth is explicitly yours.
//   R10. After reset the core begins fetching at PC 0.
//   R11. Architectural registers x1..x31 need NOT be cleared by reset. Do not
//        spend hardware zeroing them. Every program begins by writing every
//        register it later reads, so their reset values are never observable.
//        x0 always reads 0.
//
// -----------------------------------------------------------------------------
// PROGRAM TERMINATION
// -----------------------------------------------------------------------------
//   Every program ends with `jal x0, 0`, an architecturally-defined infinite
//   self-loop. The core is expected to spin there forever. The checker simply
//   stops looking after the expected number of retires; you need no halt
//   instruction and no special encoding.
//
// =============================================================================

module tiny_core #(
    parameter int IMEM_AW = 10,     // 8 / 10 / 12  (words)
    parameter int DMEM_AW = 10      // 8 / 10 / 12  (words)
) (
    input  logic        clk,
    input  logic        rst_n,

    // instruction fetch -- combinational read, always valid
    output logic [31:0] imem_addr,
    input  logic [31:0] imem_rdata,

    // data memory -- combinational read, synchronous write
    output logic        dmem_req,
    output logic        dmem_we,
    output logic [31:0] dmem_addr,
    output logic [31:0] dmem_wdata,
    input  logic [31:0] dmem_rdata,

    // retire interface -- see RETIRE INTERFACE above
    output logic        retire_valid,
    output logic [31:0] retire_pc,
    output logic [4:0]  retire_rd,
    output logic [31:0] retire_rd_val,
    output logic        retire_is_store,
    output logic [31:0] retire_store_addr,
    output logic [31:0] retire_store_data
);

    // IMPLEMENTATION INTENTIONALLY OMITTED.

endmodule
