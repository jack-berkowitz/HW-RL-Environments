#!/usr/bin/env python3
"""
tiny_core -- RV32I subset ISS, program generator, and retire-trace emitter.
ca_d08.  ORACLE OF RECORD.

CLASS B TASK. No external RTL oracle. This model and the traces it emits ARE
the oracle, so this file is what a sceptical reader should audit first.

PROVENANCE OF THE SEMANTICS
---------------------------
Written from the published RISC-V unprivileged ISA specification: the RV32I
base integer instruction set, its instruction formats (R/I/S/B/U/J), and the
defined behaviour of each opcode. It was NOT transcribed from SERV, darkriscv,
picorv32, Spike, or any other implementation.

SERV (olofk/serv) and darkriscv (darklife/darkriscv) are CROSS-CHECK ONLY --
consulted in a scratch directory outside the repo, never vendored, and never
used to define an expected value. Their role is confirming this ISS agrees with
an independent implementation on the traces; see cross_check_notes() below.

SCOPE -- deliberately hard-limited, per DESIGN_CATALOG.md:
  supported : lui auipc addi add sub and or xor slt sltu sll srl sra
              lw sw beq bne blt bge jal jalr
  excluded  : CSRs, interrupts, exceptions, misaligned access, fence,
              multiply/divide, byte/halfword memory operations

Everything here is plain Python integer arithmetic with explicit 32-bit
masking, so every wrap and every sign extension is visible rather than implied.

Usage:
    python3 rv32i_iss.py --emit <outdir> [--seed N]
    python3 rv32i_iss.py --selftest
"""

import argparse
import os
import random
import sys

MASK32 = 0xFFFFFFFF
XLEN = 32


def u32(x: int) -> int:
    """Truncate to unsigned 32-bit. Every arithmetic result passes through here."""
    return x & MASK32


def s32(x: int) -> int:
    """Interpret a 32-bit pattern as signed."""
    x &= MASK32
    return x - (1 << 32) if x & 0x8000_0000 else x


def sext(val: int, bits: int) -> int:
    """Sign-extend a `bits`-wide field to a Python int."""
    sign = 1 << (bits - 1)
    return (val & (sign - 1)) - (val & sign)


# ---------------------------------------------------------------------------
# Encoders. Kept next to the decoder on purpose: if the two disagree the
# self-test fails, which is a cheap guard against an encoding typo silently
# producing a program that tests something other than what it names.
# ---------------------------------------------------------------------------

def r_type(f7, rs2, rs1, f3, rd, op):
    return u32((f7 << 25) | (rs2 << 20) | (rs1 << 15) | (f3 << 12) | (rd << 7) | op)


def i_type(imm, rs1, f3, rd, op):
    return u32(((imm & 0xFFF) << 20) | (rs1 << 15) | (f3 << 12) | (rd << 7) | op)


def s_type(imm, rs2, rs1, f3, op):
    imm &= 0xFFF
    return u32(((imm >> 5) << 25) | (rs2 << 20) | (rs1 << 15) | (f3 << 12) |
               ((imm & 0x1F) << 7) | op)


def b_type(imm, rs2, rs1, f3, op):
    # B-format scrambles the immediate; bit 0 is always zero.
    imm &= 0x1FFF
    b12, b11 = (imm >> 12) & 1, (imm >> 11) & 1
    b10_5, b4_1 = (imm >> 5) & 0x3F, (imm >> 1) & 0xF
    return u32((b12 << 31) | (b10_5 << 25) | (rs2 << 20) | (rs1 << 15) |
               (f3 << 12) | (b4_1 << 8) | (b11 << 7) | op)


def u_type(imm, rd, op):
    return u32(((imm & 0xFFFFF) << 12) | (rd << 7) | op)


def j_type(imm, rd, op):
    imm &= 0x1FFFFF
    b20, b10_1 = (imm >> 20) & 1, (imm >> 1) & 0x3FF
    b11, b19_12 = (imm >> 11) & 1, (imm >> 12) & 0xFF
    return u32((b20 << 31) | (b10_1 << 21) | (b11 << 20) | (b19_12 << 12) |
               (rd << 7) | op)


# Convenience wrappers, named as the assembler names them.
LUI   = lambda rd, imm:            u_type(imm, rd, 0x37)
AUIPC = lambda rd, imm:            u_type(imm, rd, 0x17)
JAL   = lambda rd, off:            j_type(off, rd, 0x6F)
JALR  = lambda rd, rs1, off:       i_type(off, rs1, 0, rd, 0x67)
BEQ   = lambda rs1, rs2, off:      b_type(off, rs2, rs1, 0, 0x63)
BNE   = lambda rs1, rs2, off:      b_type(off, rs2, rs1, 1, 0x63)
BLT   = lambda rs1, rs2, off:      b_type(off, rs2, rs1, 4, 0x63)
BGE   = lambda rs1, rs2, off:      b_type(off, rs2, rs1, 5, 0x63)
LW    = lambda rd, rs1, off:       i_type(off, rs1, 2, rd, 0x03)
SW    = lambda rs1, rs2, off:      s_type(off, rs2, rs1, 2, 0x23)
ADDI  = lambda rd, rs1, imm:       i_type(imm, rs1, 0, rd, 0x13)
SLTI  = lambda rd, rs1, imm:       i_type(imm, rs1, 2, rd, 0x13)   # not in scope
ADD   = lambda rd, rs1, rs2:       r_type(0x00, rs2, rs1, 0, rd, 0x33)
SUB   = lambda rd, rs1, rs2:       r_type(0x20, rs2, rs1, 0, rd, 0x33)
SLL   = lambda rd, rs1, rs2:       r_type(0x00, rs2, rs1, 1, rd, 0x33)
SLT   = lambda rd, rs1, rs2:       r_type(0x00, rs2, rs1, 2, rd, 0x33)
SLTU  = lambda rd, rs1, rs2:       r_type(0x00, rs2, rs1, 3, rd, 0x33)
XOR   = lambda rd, rs1, rs2:       r_type(0x00, rs2, rs1, 4, rd, 0x33)
SRL   = lambda rd, rs1, rs2:       r_type(0x00, rs2, rs1, 5, rd, 0x33)
SRA   = lambda rd, rs1, rs2:       r_type(0x20, rs2, rs1, 5, rd, 0x33)
OR    = lambda rd, rs1, rs2:       r_type(0x00, rs2, rs1, 6, rd, 0x33)
AND   = lambda rd, rs1, rs2:       r_type(0x00, rs2, rs1, 7, rd, 0x33)


class Retire:
    """One committed instruction, exactly as the DUT must report it."""
    __slots__ = ("pc", "rd", "rd_val", "is_store", "st_addr", "st_data")

    def __init__(self, pc, rd, rd_val, is_store=0, st_addr=0, st_data=0):
        self.pc, self.rd, self.rd_val = pc, rd, rd_val
        self.is_store, self.st_addr, self.st_data = is_store, st_addr, st_data


class ISS:
    """RV32I subset interpreter. One step() == one architectural instruction."""

    def __init__(self, imem_words: int, dmem_words: int):
        self.x = [0] * 32
        self.pc = 0
        self.imem = [0] * imem_words
        self.dmem = [0] * dmem_words
        self.imem_words, self.dmem_words = imem_words, dmem_words

    def load_program(self, words):
        for i, w in enumerate(words):
            self.imem[i] = u32(w)

    def _wr(self, rd, val):
        # x0 is hardwired to zero: writes are discarded, reads are always 0.
        if rd != 0:
            self.x[rd] = u32(val)

    def step(self) -> Retire:
        pc = self.pc
        instr = self.imem[(pc >> 2) % self.imem_words]
        op = instr & 0x7F
        rd = (instr >> 7) & 0x1F
        f3 = (instr >> 12) & 0x7
        rs1 = (instr >> 15) & 0x1F
        rs2 = (instr >> 20) & 0x1F
        f7 = (instr >> 25) & 0x7F
        a, b = self.x[rs1], self.x[rs2]
        npc = u32(pc + 4)
        r = None

        if op == 0x37:                                   # LUI
            v = u32(instr & 0xFFFFF000)
            self._wr(rd, v); r = Retire(pc, rd, v)
        elif op == 0x17:                                 # AUIPC
            v = u32(pc + (instr & 0xFFFFF000))
            self._wr(rd, v); r = Retire(pc, rd, v)
        elif op == 0x6F:                                 # JAL
            imm = sext(((instr >> 31) & 1) << 20 | ((instr >> 21) & 0x3FF) << 1 |
                       ((instr >> 20) & 1) << 11 | ((instr >> 12) & 0xFF) << 12, 21)
            v = npc
            self._wr(rd, v); r = Retire(pc, rd, v)
            npc = u32(pc + imm)
        elif op == 0x67:                                 # JALR
            imm = sext((instr >> 20) & 0xFFF, 12)
            v = npc
            # target LSB is cleared, per spec; rd is written with pc+4 even when
            # rd == rs1, so the link value must be computed before the jump.
            npc = u32((a + imm) & ~1)
            self._wr(rd, v); r = Retire(pc, rd, v)
        elif op == 0x63:                                 # branches
            imm = sext(((instr >> 31) & 1) << 12 | ((instr >> 7) & 1) << 11 |
                       ((instr >> 25) & 0x3F) << 5 | ((instr >> 8) & 0xF) << 1, 13)
            taken = {0: s32(a) == s32(b), 1: s32(a) != s32(b),
                     4: s32(a) < s32(b), 5: s32(a) >= s32(b)}[f3]
            if taken:
                npc = u32(pc + imm)
            r = Retire(pc, 0, 0)                         # branches write no rd
        elif op == 0x03:                                 # LW
            imm = sext((instr >> 20) & 0xFFF, 12)
            addr = u32(a + imm)
            v = self.dmem[(addr >> 2) % self.dmem_words]
            self._wr(rd, v); r = Retire(pc, rd, v)
        elif op == 0x23:                                 # SW
            imm = sext(((instr >> 25) & 0x7F) << 5 | ((instr >> 7) & 0x1F), 12)
            addr = u32(a + imm)
            self.dmem[(addr >> 2) % self.dmem_words] = u32(b)
            r = Retire(pc, 0, 0, 1, addr, u32(b))
        elif op == 0x13:                                 # ADDI (only I-ALU in scope)
            imm = sext((instr >> 20) & 0xFFF, 12)
            v = u32(a + imm)
            self._wr(rd, v); r = Retire(pc, rd, v)
        elif op == 0x33:                                 # R-type ALU
            sh = b & 0x1F
            if   f3 == 0: v = u32(a - b) if f7 == 0x20 else u32(a + b)
            elif f3 == 1: v = u32(a << sh)
            elif f3 == 2: v = 1 if s32(a) < s32(b) else 0
            elif f3 == 3: v = 1 if u32(a) < u32(b) else 0
            elif f3 == 4: v = u32(a ^ b)
            elif f3 == 5: v = u32(s32(a) >> sh) if f7 == 0x20 else u32(u32(a) >> sh)
            elif f3 == 6: v = u32(a | b)
            else:         v = u32(a & b)
            self._wr(rd, v); r = Retire(pc, rd, v)
        else:
            raise ValueError(f"instruction out of scope at pc=0x{pc:08x}: 0x{instr:08x}")

        # Report what the architecture actually did: a write to x0 is discarded,
        # so the reported value must be 0, not the computed one. Getting this
        # wrong is the classic x0 bug and mutant m02 does exactly that.
        if r.rd == 0:
            r.rd_val = 0
        self.pc = npc
        return r

    def run(self, n: int):
        return [self.step() for _ in range(n)]


# ---------------------------------------------------------------------------
# Programs. Each returns (name, [words], n_retires) and ends in a self-loop so
# the core keeps fetching something legal after the checked region.
# ---------------------------------------------------------------------------

SELF_LOOP = JAL(0, 0)      # jal x0, 0 -- architecturally defined infinite loop


# Every program is prefixed with this. The spec says reset need NOT clear
# x1..x31 -- requiring a 32-entry register reset is real hardware for no
# architectural benefit -- so a program must never read a register it has not
# written. The ISS starts registers at zero and a real core starts them at
# whatever the flops held, so without this preamble the two disagree on any
# program that reads an unwritten register. The randomised programs did exactly
# that, and it surfaced as a branch going the wrong way.
REG_INIT = [ADDI(i, 0, (i * 7) - 16) for i in range(1, 16)]


def _prog(name, body):
    full = REG_INIT + body + [SELF_LOOP]
    return (name, full, len(REG_INIT) + len(body))


def directed_programs():
    progs = []

    # P1: every ALU op with ordinary operands
    b = [ADDI(1, 0, 100), ADDI(2, 0, 37),
         ADD(3, 1, 2), SUB(4, 1, 2), AND(5, 1, 2), OR(6, 1, 2), XOR(7, 1, 2),
         SLT(8, 1, 2), SLTU(9, 1, 2), SLL(10, 1, 2), SRL(11, 1, 2), SRA(12, 1, 2)]
    progs.append(_prog("alu_basic", b))

    # P2: sign boundaries -- negative operands, arithmetic vs logical shift,
    # signed vs unsigned compare. srl/sra of a negative value differ here and
    # nowhere else.
    b = [LUI(1, 0x80000), ADDI(2, 0, -1), ADDI(3, 0, 1),
         SRL(4, 1, 3), SRA(5, 1, 3),
         SLT(6, 2, 3), SLTU(7, 2, 3),
         SLT(8, 1, 3), SLTU(9, 1, 3),
         ADD(10, 1, 2), SUB(11, 1, 2)]
    progs.append(_prog("sign_boundaries", b))

    # P3: shift amounts use only the low 5 bits of rs2
    b = [ADDI(1, 0, 1), ADDI(2, 0, 33), ADDI(3, 0, 31), ADDI(4, 0, 32),
         SLL(5, 1, 2), SLL(6, 1, 3), SLL(7, 1, 4),
         LUI(8, 0x80000), SRA(9, 8, 3), SRL(10, 8, 3)]
    progs.append(_prog("shift_mask", b))

    # P4: x0 -- writes discarded, reads zero
    b = [ADDI(0, 0, 999), ADD(0, 0, 0), LUI(0, 0x12345),
         ADDI(1, 0, 5), ADD(0, 1, 1), ADD(2, 0, 1)]
    progs.append(_prog("x0_hardwired", b))

    # P5: lui / auipc, including the sign-extension boundary at bit 31
    b = [LUI(1, 0x00001), LUI(2, 0xFFFFF), LUI(3, 0x80000),
         AUIPC(4, 0), AUIPC(5, 1), AUIPC(6, 0xFFFFF)]
    progs.append(_prog("upper_imm", b))

    # P6: every branch, taken and not taken
    b = [ADDI(1, 0, 5), ADDI(2, 0, 5), ADDI(3, 0, -5),
         BEQ(1, 2, 8), ADDI(10, 0, 1),      # skipped
         BNE(1, 2, 8), ADDI(11, 0, 1),      # taken through
         BLT(3, 1, 8), ADDI(12, 0, 1),      # skipped
         BGE(1, 3, 8), ADDI(13, 0, 1),      # skipped
         BLT(1, 3, 8), ADDI(14, 0, 1),      # taken through
         ADDI(15, 0, 7)]
    progs.append(_prog("branches", b))

    # P7: signed branch comparison across zero -- blt/bge must be SIGNED.
    # An implementation using an unsigned compare passes P6 and fails here.
    b = [LUI(1, 0x80000), ADDI(2, 0, 1),
         BLT(1, 2, 8), ADDI(10, 0, 1),      # 0x80000000 < 1 signed -> taken
         BGE(2, 1, 8), ADDI(11, 0, 1),      # 1 >= 0x80000000 signed -> taken
         ADDI(12, 0, 3)]
    progs.append(_prog("branch_signed", b))

    # P8: jal / jalr, including jalr with rd == rs1 (link value must be pc+4,
    # computed before the target is taken) and the cleared target LSB
    b = [JAL(1, 8), ADDI(10, 0, 1),         # skipped
         ADDI(2, 0, 28), JALR(2, 2, 0),     # rd == rs1
         ADDI(11, 0, 1),
         ADDI(12, 0, 2), JAL(0, 8), ADDI(13, 0, 1), ADDI(14, 0, 9)]
    progs.append(_prog("jumps", b))

    # P8b: jalr specifically -- it was the thinnest-covered instruction in the
    # first full run (1 retire across 19 programs), and the spec calls out two
    # of its corners by name. Covers: a plain indirect jump, rd == rs1, an ODD
    # target whose LSB must be cleared, rd == x0 (links nothing), and a negative
    # offset.
    #
    # Targets are computed from P, the byte address of the first body
    # instruction, because REG_INIT shifts every program. Body word offsets:
    #   P+0  addi x5      P+4  JALR x6,x5     P+8/P+12 skipped
    #   P+16 addi x7      P+20 JALR x7,x7     P+24 skipped
    #   P+28 addi x8      P+32 JALR x9,x8     (odd target -> P+36)
    #   P+36 addi x10     P+40 JALR x0,x10    P+44 skipped
    #   P+48 addi x11     P+52 JALR x12,x11,-4 (x11 = P+60 so target is P+56)
    #   P+56 addi x13
    P = len(REG_INIT) * 4
    b = [ADDI(5, 0, P + 16),  JALR(6, 5, 0),        # plain: jump over 2
         ADDI(20, 0, 1), ADDI(21, 0, 1),            # skipped
         ADDI(7, 0, P + 28),  JALR(7, 7, 0),        # rd == rs1
         ADDI(22, 0, 1),                            # skipped
         ADDI(8, 0, P + 37),  JALR(9, 8, 0),        # ODD target -> LSB cleared
         ADDI(10, 0, P + 48), JALR(0, 10, 0),       # rd == x0
         ADDI(23, 0, 1),                            # skipped
         ADDI(11, 0, P + 60), JALR(12, 11, -4),     # negative offset
         ADDI(24, 0, 1),                            # skipped
         ADDI(13, 0, 99)]
    progs.append(_prog("jalr_corners", b))

    # P9: load/store round trip, including a negative offset and store of x0
    b = [ADDI(1, 0, 64), ADDI(2, 0, 0x123),
         SW(1, 2, 0), LW(3, 1, 0),
         SW(1, 2, 8), LW(4, 1, 8),
         ADDI(5, 0, 72), SW(5, 0, -8), LW(6, 5, -8),
         LUI(7, 0xABCDE), SW(1, 7, 4), LW(8, 1, 4)]
    progs.append(_prog("mem_roundtrip", b))

    # P10: load-use hazard -- the consumer is the very next instruction, then
    # one apart, then two. A pipeline that forgets to interlock fails the first.
    b = [ADDI(1, 0, 128), ADDI(2, 0, 55), SW(1, 2, 0),
         LW(3, 1, 0), ADD(4, 3, 3),                  # back-to-back
         LW(5, 1, 0), ADDI(9, 0, 0), ADD(6, 5, 5),   # one apart
         LW(7, 1, 0), ADDI(9, 0, 0), ADDI(9, 0, 0), ADD(8, 7, 7)]
    progs.append(_prog("load_use", b))

    # P11: back-to-back dependent ALU ops -- a forwarding chain
    b = [ADDI(1, 0, 1), ADD(2, 1, 1), ADD(3, 2, 2), ADD(4, 3, 3),
         ADD(5, 4, 4), SUB(6, 5, 4), AND(7, 6, 5), OR(8, 7, 6), XOR(9, 8, 7)]
    progs.append(_prog("fwd_chain", b))

    # P12: store depending on a just-computed address and a just-loaded value
    b = [ADDI(1, 0, 200), ADDI(2, 0, 0x77), SW(1, 2, 0),
         LW(3, 1, 0), SW(1, 3, 4),
         ADD(4, 1, 1), SW(4, 3, 0), LW(5, 4, 0)]
    progs.append(_prog("store_fwd", b))

    # P13: branch whose condition depends on the immediately preceding op
    b = [ADDI(1, 0, 3), ADDI(2, 0, 3),
         SUB(3, 1, 2), BEQ(3, 0, 8), ADDI(10, 0, 1),
         ADD(4, 1, 2), BNE(4, 0, 8), ADDI(11, 0, 1),
         ADDI(12, 0, 5)]
    progs.append(_prog("branch_dep", b))

    return progs


def random_program(rnd, n_instr, dmem_words):
    """Constrained-random straight-line-ish program.

    Branches only ever jump FORWARD over a small span, and jumps are omitted, so
    the program cannot loop and the retire count stays deterministic. Memory
    addresses are masked into a safe window.
    """
    body = []
    # seed a few registers with known values and a valid base address
    body += [ADDI(1, 0, 256), ADDI(2, 0, 7), ADDI(3, 0, -9), LUI(4, 0x80000)]
    while len(body) < n_instr:
        k = rnd.randint(0, 9)
        rd = rnd.randint(0, 15)
        s1, s2 = rnd.randint(0, 15), rnd.randint(0, 15)
        if k == 0:
            body.append(rnd.choice([ADD, SUB, AND, OR, XOR, SLT, SLTU])(rd, s1, s2))
        elif k == 1:
            body.append(rnd.choice([SLL, SRL, SRA])(rd, s1, s2))
        elif k == 2:
            body.append(ADDI(rd, s1, rnd.randint(-2048, 2047)))
        elif k == 3:
            body.append(rnd.choice([LUI, AUIPC])(rd, rnd.randint(0, 0xFFFFF)))
        elif k == 4 and len(body) + 2 < n_instr:
            # keep stores inside the data window: base reg 1 holds 256
            body.append(SW(1, s2, 4 * rnd.randint(0, 8)))
        elif k == 5:
            body.append(LW(rd, 1, 4 * rnd.randint(0, 8)))
        elif k == 6 and len(body) + 3 < n_instr:
            body.append(rnd.choice([BEQ, BNE, BLT, BGE])(s1, s2, 8))
            body.append(ADDI(rd, 0, rnd.randint(-100, 100)))
        else:
            body.append(ADDI(rd, s1, rnd.randint(-16, 16)))
    return body[:n_instr]


# ---------------------------------------------------------------------------
# Emission
# ---------------------------------------------------------------------------

IMEM_WORDS = 1024
DMEM_WORDS = 1024


def emit(outdir: str, seed: int):
    os.makedirs(outdir, exist_ok=True)
    rnd = random.Random(seed)

    progs = list(directed_programs())
    for i in range(6):
        progs.append(_prog(f"rand{i}", random_program(rnd, 40 + 10 * i, DMEM_WORDS)))

    index = []
    total_retires = 0
    for pi, (name, words, n_ret) in enumerate(progs):
        iss = ISS(IMEM_WORDS, DMEM_WORDS)
        iss.load_program(words)
        trace = iss.run(n_ret)

        with open(os.path.join(outdir, f"prog{pi:02d}.hex"), "w") as f:
            for w in words:
                f.write(f"{u32(w):08x}\n")
        with open(os.path.join(outdir, f"trace{pi:02d}.hex"), "w") as f:
            # one retire per line: pc rd rd_val is_store st_addr st_data
            for r in trace:
                f.write(f"{r.pc:08x} {r.rd:02x} {u32(r.rd_val):08x} "
                        f"{r.is_store:01x} {u32(r.st_addr):08x} {u32(r.st_data):08x}\n")
        index.append((pi, name, len(words), n_ret))
        total_retires += n_ret

    with open(os.path.join(outdir, "index.txt"), "w") as f:
        for pi, name, nw, nr in index:
            f.write(f"{pi} {name} {nw} {nr}\n")
    # Machine-readable retire count per program, one hex word per line, so the
    # checker can $readmemh it instead of carrying a hardcoded table that would
    # drift the moment a program is added.
    with open(os.path.join(outdir, "retires.hex"), "w") as f:
        for _, _, _, nr in index:
            f.write(f"{nr:08x}\n")
    with open(os.path.join(outdir, "MANIFEST.txt"), "w") as f:
        f.write(f"programs: {len(progs)}\nseed: {seed}\n")
        f.write(f"total retires: {total_retires}\n")
        f.write(f"imem_words: {IMEM_WORDS}\ndmem_words: {DMEM_WORDS}\n")
        f.write("generated by ref/model/rv32i_iss.py -- do not hand-edit\n")

    print(f"wrote {len(progs)} programs, {total_retires} retires, to {outdir}")
    for pi, name, nw, nr in index:
        print(f"  prog{pi:02d} {name:18s} {nw:4d} words {nr:4d} retires")
    return len(progs), total_retires


# ---------------------------------------------------------------------------
# Self-test: architectural properties that hold regardless of implementation.
# ---------------------------------------------------------------------------

def selftest() -> int:
    fails = 0

    def chk(cond, msg):
        nonlocal fails
        if not cond:
            print(f"SELFTEST FAIL: {msg}")
            fails += 1

    def run_prog(words, n):
        m = ISS(IMEM_WORDS, DMEM_WORDS)
        m.load_program(words)
        return m, m.run(n)

    # encoder/decoder agreement on a round trip
    m, t = run_prog([ADDI(1, 0, 5), ADDI(2, 0, -5), ADD(3, 1, 2)], 3)
    chk(m.x[1] == 5, "addi positive")
    chk(m.x[2] == u32(-5), "addi negative sign-extends")
    chk(m.x[3] == 0, "5 + (-5) == 0")

    # x0 is hardwired: written value discarded AND reported as zero
    m, t = run_prog([ADDI(0, 0, 999), ADD(1, 0, 0)], 2)
    chk(m.x[0] == 0, "x0 not writable")
    chk(t[0].rd == 0 and t[0].rd_val == 0, "retire of a write to x0 reports value 0")
    chk(m.x[1] == 0, "x0 reads as zero")

    # shifts use only rs2[4:0]
    m, _ = run_prog([ADDI(1, 0, 1), ADDI(2, 0, 33), SLL(3, 1, 2)], 3)
    chk(m.x[3] == 2, "shift amount masked to 5 bits (1 << 33 == 1 << 1)")

    # sra vs srl on a negative value
    m, _ = run_prog([LUI(1, 0x80000), ADDI(2, 0, 4), SRA(3, 1, 2), SRL(4, 1, 2)], 4)
    chk(m.x[3] == u32(s32(0x80000000) >> 4), "sra sign-extends")
    chk(m.x[4] == (0x80000000 >> 4), "srl zero-fills")
    chk(m.x[3] != m.x[4], "sra and srl differ on a negative operand")

    # slt signed vs sltu unsigned
    m, _ = run_prog([ADDI(1, 0, -1), ADDI(2, 0, 1), SLT(3, 1, 2), SLTU(4, 1, 2)], 4)
    chk(m.x[3] == 1, "slt: -1 < 1 signed")
    chk(m.x[4] == 0, "sltu: 0xFFFFFFFF > 1 unsigned")

    # branch comparisons are signed
    m, t = run_prog([LUI(1, 0x80000), ADDI(2, 0, 1), BLT(1, 2, 8),
                     ADDI(10, 0, 1), ADDI(11, 0, 2)], 4)
    chk(m.x[10] == 0, "blt taken with a negative operand skips the next instruction")

    # jal writes pc+4 and branches; jalr clears the target LSB
    m, t = run_prog([JAL(1, 8), ADDI(10, 0, 1), ADDI(11, 0, 2)], 2)
    chk(m.x[1] == 4, "jal link == pc+4")
    chk(t[1].pc == 8, "jal redirected fetch to pc+8")
    m, t = run_prog([ADDI(1, 0, 9), JALR(2, 1, 0), ADDI(10, 0, 1)], 2)
    chk(t[1].pc == 4, "jalr executed from pc=4")
    chk(m.pc == 8, "jalr target LSB cleared (9 -> 8)")

    # jalr with rd == rs1 must link pc+4, not the pre-jump register value
    m, t = run_prog([ADDI(1, 0, 12), JALR(1, 1, 0)], 2)
    chk(m.x[1] == 8, "jalr rd==rs1 links pc+4")
    chk(m.pc == 12, "jalr rd==rs1 still jumps to the old rs1")

    # store/load round trip, negative offset
    m, t = run_prog([ADDI(1, 0, 64), ADDI(2, 0, 0x123), SW(1, 2, 0), LW(3, 1, 0)], 4)
    chk(m.x[3] == 0x123, "load returns the stored word")
    chk(t[2].is_store == 1 and t[2].st_addr == 64 and t[2].st_data == 0x123,
        "store retire reports address and data")
    chk(t[2].rd == 0 and t[2].rd_val == 0, "store writes no rd")

    # branches report no rd
    m, t = run_prog([ADDI(1, 0, 1), BEQ(1, 1, 8), ADDI(10, 0, 1), ADDI(11, 0, 1)], 3)
    chk(t[1].rd == 0 and t[1].rd_val == 0, "branch writes no rd")
    chk(t[1].is_store == 0, "branch is not a store")

    # auipc uses the instruction's own pc
    m, t = run_prog([ADDI(0, 0, 0), AUIPC(1, 0)], 2)
    chk(m.x[1] == 4, "auipc adds its own pc")

    # every directed program runs to completion without an out-of-scope opcode
    for name, words, n in directed_programs():
        try:
            mm = ISS(IMEM_WORDS, DMEM_WORDS); mm.load_program(words); mm.run(n)
        except Exception as e:                      # noqa: BLE001
            chk(False, f"directed program '{name}' raised: {e}")

    # random programs too
    rnd = random.Random(1234)
    for i in range(20):
        w = random_program(rnd, 60, DMEM_WORDS) + [SELF_LOOP]
        try:
            mm = ISS(IMEM_WORDS, DMEM_WORDS); mm.load_program(w); mm.run(60)
        except Exception as e:                      # noqa: BLE001
            chk(False, f"random program {i} raised: {e}")

    print("SELFTEST PASS" if fails == 0 else f"SELFTEST FAILED ({fails})")
    return fails


def cross_check_notes():
    """Cross-check record. SERV / darkriscv are CONSULTED, never authoritative.

    Both are permissively licensed RV32I implementations pinned in refs.lock and
    cloned to the external scratch directory; neither is vendored and neither
    defines an expected value here. Their role is confirming that an independent
    implementation agrees with this ISS on the same programs.

    DESIGN_CATALOG.md is explicit that neither is a usable structural template
    (SERV is bit-serial), so they are trace cross-checks only.

    Status is recorded in NOTES.md rather than asserted here, because a failed
    cross-check is a finding to report, not a reason to change the ISS silently.
    """
    return None


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--emit", metavar="OUTDIR")
    ap.add_argument("--selftest", action="store_true")
    ap.add_argument("--seed", type=int, default=20260814)
    a = ap.parse_args()
    rc = 0
    if a.selftest:
        rc = selftest()
    if a.emit:
        emit(a.emit, a.seed)
    if not a.selftest and not a.emit:
        ap.print_help()
    sys.exit(1 if rc else 0)
