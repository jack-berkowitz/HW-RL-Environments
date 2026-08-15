#!/usr/bin/env python3
"""VECTOR GENERATOR for d_dsp02 -- INPUTS ONLY. THIS IS NOT AN ORACLE.

READ THIS BEFORE CHANGING ANYTHING HERE
---------------------------------------
This script produces (a, b, c, rounding_mode) tuples and NOTHING ELSE. It never
computes an expected result. Expected values come from the vendored anchor
(`fpnew_fma`), captured by `tb/audit/capture_vectors_tb.sv`.

That inversion is deliberate. If a Python model produced expected values and we
merely cross-checked it against the anchor, a shared misconception -- the same
misreading of a corner of IEEE-754 on both sides -- would survive the
cross-check, because both would agree for the same wrong reason. There is a
worked example in NOTES.md: a hand-computed FMA case in this project was wrong
and was caught only because the anchor disagreed.

Under this scheme:

    a Python bug can cost COVERAGE -- a corner we failed to generate --
    and can NEVER produce a wrong expected value.

So the risk moves entirely to input coverage, which is why the checker carries
stimulus-side coverage floors that FAIL THE RUN when a category is unreached.
Adding a category here without adding its floor there is how this gets
undermined.

Output: one hex word per line, `{a[31:0], b[31:0], c[31:0], rnd[2:0]}` = 99 bits,
padded to 25 hex chars, for `$readmemh`.
"""
import random
import struct
import sys

# rounding modes, matching the shipped spec's encoding (IEEE five only)
RNE, RTZ, RDN, RUP, RMM = 0, 1, 2, 3, 4
MODES = [RNE, RTZ, RDN, RUP, RMM]

def f2b(x):
    return struct.unpack("<I", struct.pack("<f", x))[0]

# ---- named constants -------------------------------------------------------
POS_ZERO   = 0x00000000
NEG_ZERO   = 0x80000000
POS_INF    = 0x7F800000
NEG_INF    = 0xFF800000
QNAN       = 0x7FC00000
QNAN_PAY   = 0x7FC0DEAD          # quiet NaN with a distinctive payload
SNAN       = 0x7F800001          # signalling NaN: exponent all ones, MSB of mantissa clear
MIN_SUBNORM= 0x00000001          # 2^-149
MAX_SUBNORM= 0x007FFFFF
MIN_NORMAL = 0x00800000          # 2^-126
MAX_NORMAL = 0x7F7FFFFF
ONE        = 0x3F800000

vectors = []
tags = {}          # category -> count, for the generator's own report

def emit(a, b, c, rnd, cat):
    vectors.append((a & 0xFFFFFFFF, b & 0xFFFFFFFF, c & 0xFFFFFFFF, rnd))
    tags[cat] = tags.get(cat, 0) + 1

def emit_all_modes(a, b, c, cat):
    for m in MODES:
        emit(a, b, c, m, cat)

# ---------------------------------------------------------------- categories
# Each block below corresponds to a coverage floor in the checker. If you add a
# block, add the floor; a category generated but not floored can silently vanish.

# 1. SUBNORMAL OPERANDS
for op in (MIN_SUBNORM, MAX_SUBNORM, 0x00000002, 0x00400000):
    emit_all_modes(ONE, op, POS_ZERO, "subnormal_operand")
    emit_all_modes(op, ONE, f2b(1e-30), "subnormal_operand")

# 2. SUBNORMAL RESULTS -- product lands below the normal range
emit_all_modes(MIN_NORMAL, f2b(0.5), NEG_ZERO, "subnormal_result")
emit_all_modes(f2b(2**-100), f2b(2**-40), POS_ZERO, "subnormal_result")
emit_all_modes(MIN_SUBNORM, ONE, POS_ZERO, "subnormal_result")

# 3. SIGNALLING NaN -- must raise invalid and quiet the NaN
for pos in range(3):
    ops = [ONE, ONE, ONE]
    ops[pos] = SNAN
    emit_all_modes(ops[0], ops[1], ops[2], "signalling_nan")

# 4. QUIET NaN PAYLOAD, BOTH OPERAND ORDERS
emit_all_modes(QNAN_PAY, ONE, ONE, "qnan_payload")
emit_all_modes(ONE, QNAN_PAY, ONE, "qnan_payload")
emit_all_modes(ONE, ONE, QNAN_PAY, "qnan_payload")

# 5. SIGNED ZERO RESULTS, every mode -- (-0)+(+0) is +0 except under RDN
emit_all_modes(NEG_ZERO, ONE, POS_ZERO, "signed_zero")
emit_all_modes(POS_ZERO, ONE, NEG_ZERO, "signed_zero")
emit_all_modes(NEG_ZERO, ONE, NEG_ZERO, "signed_zero")
emit_all_modes(ONE, f2b(-1.0), ONE, "signed_zero")          # exact cancellation to zero

# 6. OVERFLOW and UNDERFLOW BOUNDARIES
emit_all_modes(MAX_NORMAL, f2b(2.0), POS_ZERO, "overflow")
emit_all_modes(MAX_NORMAL, MAX_NORMAL, POS_ZERO, "overflow")
emit_all_modes(MIN_NORMAL, f2b(2**-30), POS_ZERO, "underflow")
emit_all_modes(MIN_SUBNORM, f2b(0.5), POS_ZERO, "underflow")

# 7. TININESS AFTER ROUNDING -- the case where before/after detection DISAGREE.
# A product just under the smallest normal that ROUNDS UP to exactly the
# smallest normal: tiny before rounding, not tiny after.
emit_all_modes(0x00FFFFFF, f2b(0.5), POS_ZERO, "tininess_boundary")
emit_all_modes(0x00800001, f2b(0.5), POS_ZERO, "tininess_boundary")
emit_all_modes(MIN_NORMAL, f2b(0.99999994), POS_ZERO, "tininess_boundary")

# 8. EXACT RESULTS, including the fused-cancellation discriminator.
# a=b=1+2^-12 -> a*b = 1 + 2^-11 + 2^-24; c cancels the representable part, so a
# FUSED unit returns 2^-24 and a multiply-then-add returns exactly zero.
emit_all_modes(0x3F800800, 0x3F800800, 0xBF801000, "exact_fused_cancel")
emit_all_modes(f2b(2.0), f2b(3.0), f2b(4.0), "exact")
emit_all_modes(f2b(1.5), f2b(2.0), f2b(-3.0), "exact")

# 9. ROUNDING MODES DISAGREE -- halfway and near-halfway ties.
# A design that hardcodes RNE passes everything else; this is what catches it.
def ties():
    out = []
    for k in range(1, 24):                       # halfway at various magnitudes
        base = 0x3F800000 | ((1 << k) - 1)
        out.append((base, ONE, 0x33800000))      # + 2^-24, an exact tie
    out += [
        (ONE, ONE, 0x33800000),                  # 1 + 2^-24, tie to even
        (0x3F800001, ONE, 0x33800000),           # 1+2^-23 + 2^-24, tie to odd
        (0x3F800002, ONE, 0x33800000),
        (0x3FFFFFFF, ONE, 0x33000000),           # near the binade boundary
    ]
    return out
for (a, b, c) in ties():
    emit_all_modes(a, b, c, "modes_disagree")

# 10. RANDOM, all modes -- background coverage, not a floor
rng = random.Random(0xD5F02)          # fixed seed: the vector set is reproducible
for _ in range(4000):
    def rnd_op():
        r = rng.random()
        if r < 0.10: return rng.randint(0, 0x007FFFFF)          # subnormal
        if r < 0.15: return rng.choice([POS_ZERO, NEG_ZERO, POS_INF, NEG_INF, QNAN])
        if r < 0.20: return rng.randint(0x7F000000, 0x7F7FFFFF) # large
        return rng.getrandbits(32)
    emit(rnd_op(), rnd_op(), rnd_op(), rng.choice(MODES), "random")

# ---------------------------------------------------------------- write out
out = sys.argv[1] if len(sys.argv) > 1 else "vectors/inputs.hex"
with open(out, "w") as fh:
    for (a, b, c, r) in vectors:
        word = (a << 67) | (b << 35) | (c << 3) | r
        fh.write(f"{word:025x}\n")

print(f"wrote {len(vectors)} input tuples to {out}")
print("categories generated (each needs a matching coverage floor in the checker):")
for k in sorted(tags):
    print(f"  {k:<22} {tags[k]}")
print("\nNOTE: this file contains NO expected values. The anchor produces those.")
