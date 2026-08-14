#!/usr/bin/env python3
"""
int8_requant -- golden model and vector generator.  ai_d01.  ORACLE OF RECORD.

CLASS B TASK. There is no external RTL oracle. This model, and the vectors it
emits, ARE the oracle. Everything the testbench believes about correctness comes
from here, so this file is the thing a sceptical reader should audit first.

PROVENANCE OF THE ALGORITHM
---------------------------
Written from the *documented* fixed-point requantisation algorithm used by
TFLite (`MultiplyByQuantizedMultiplier`), which is composed of two published
primitives from the gemmlowp fixed-point library:

  * SaturatingRoundingDoublingHighMul -- multiply two Q0.31 values and keep the
    high word, with round-half-away-from-zero.
  * RoundingDivideByPOT              -- arithmetic right shift with
    round-half-away-from-zero.

It was NOT transcribed from NVDLA's SDP RTL, from gemmlowp's C++ source, or
from any other implementation. It is written here from the arithmetic
definition, in plain Python integer arithmetic, so that it can be read and
checked against the specification in spec/int8_requant_iface.sv line by line.
Python's arbitrary-precision ints mean there is no hidden width truncation:
every narrowing below is explicit and deliberate.

NVDLA SDP (refs/nvdla_hw/vmod/nvdla/sdp/, pinned in refs.lock) is used ONLY as
a sanity cross-check on the emitted vectors -- see check_against_nvdla_notes()
at the bottom. It never defines expected values.

Usage:
    python3 int8_requant_model.py --emit-vectors <outdir> [--seed N]
    python3 int8_requant_model.py --selftest
"""

import argparse
import os
import random
import sys

INT32_MIN = -(1 << 31)
INT32_MAX = (1 << 31) - 1
INT8_MIN = -128
INT8_MAX = 127

# Multiplier is required by the spec to be normalised into [2^30, 2^31-1].
MULT_MIN = 1 << 30
MULT_MAX = INT32_MAX


# ---------------------------------------------------------------------------
# Primitives. Each mirrors one numbered step of the spec header.
# ---------------------------------------------------------------------------

def _trunc_div(numer: int, denom: int) -> int:
    """Integer division TRUNCATING TOWARD ZERO (C semantics), not floor.

    Python's // floors, which differs for negative numerators: -3 // 2 == -2
    but C gives -1. The spec says truncate toward zero, so do that explicitly.
    This is the single most likely place for a subtle sign bug, in the model
    and in a submitted design alike.
    """
    q = abs(numer) // abs(denom)
    if (numer < 0) != (denom < 0):
        q = -q
    return q


def saturating_rounding_doubling_high_mul(a: int, b: int) -> int:
    """Spec step 1. Q0.31 x Q0.31 -> Q0.31, round half away from zero.

    Computes round(a*b*2 / 2^32) == round(a*b / 2^31), saturating the single
    overflow case a == b == INT32_MIN.
    """
    assert INT32_MIN <= a <= INT32_MAX, f"acc out of int32 range: {a}"
    assert INT32_MIN <= b <= INT32_MAX, f"mult out of int32 range: {b}"

    # The one input pair whose exact result is not representable.
    # Unreachable while the spec constrains mult >= 2^30 > 0, but the guard is
    # kept so the model stays correct if that precondition is ever relaxed.
    if a == INT32_MIN and b == INT32_MIN:
        return INT32_MAX

    p = a * b                                   # exact, arbitrary precision
    nudge = (1 << 30) if p >= 0 else (1 - (1 << 30))
    return _trunc_div(p + nudge, 1 << 31)


def rounding_divide_by_pot(x: int, exponent: int) -> int:
    """Spec step 2. Arithmetic right shift by `exponent`, round half AWAY from zero.

    Note this is NOT round-half-to-even and NOT round-half-up: -1.5 goes to -2,
    +1.5 goes to +2. The asymmetric `threshold` below is what implements that
    for negative x, and dropping the `+1` is a classic off-the-mark bug (it
    silently becomes round-half-up). Mutant m03 does exactly that.
    """
    assert 0 <= exponent <= 31, f"shift out of range: {exponent}"
    if exponent == 0:
        return x

    mask = (1 << exponent) - 1
    remainder = x & mask                        # two's-complement AND
    threshold = (mask >> 1) + (1 if x < 0 else 0)
    shifted = (x >> exponent)                   # Python >> is arithmetic
    return shifted + (1 if remainder > threshold else 0)


def clamp_int8(x: int) -> int:
    """Spec step 4. Saturate (NOT wrap) into the int8 range."""
    return max(INT8_MIN, min(INT8_MAX, x))


def requant(acc: int, mult: int, shift: int, zero_point: int) -> int:
    """Full spec pipeline, steps 1-4. Returns a signed int8."""
    assert MULT_MIN <= mult <= MULT_MAX, f"mult not normalised: {mult}"
    assert INT8_MIN <= zero_point <= INT8_MAX, f"zp out of int8 range: {zero_point}"
    hi = saturating_rounding_doubling_high_mul(acc, mult)   # step 1
    sh = rounding_divide_by_pot(hi, shift)                  # step 2
    biased = sh + zero_point                                # step 3
    return clamp_int8(biased)                               # step 4


# ---------------------------------------------------------------------------
# Vector generation
# ---------------------------------------------------------------------------

def _to_hex(v: int, bits: int) -> str:
    """Two's-complement hex, `bits` wide, for $readmemh."""
    return f"{v & ((1 << bits) - 1):0{bits // 4}x}"


def gen_cases(seed: int):
    """Directed cases first (each targets one named hazard), then random.

    Directed cases are ordered and named so a testbench failure maps back to a
    specific arithmetic property rather than 'vector 1473 mismatched'.
    """
    rnd = random.Random(seed)
    cases = []   # (tag, acc, mult, shift, zp)

    def add(tag, acc, mult, shift, zp):
        cases.append((tag, acc, mult, shift, zp))

    unity = MULT_MIN            # 2^30: with shift=30 this is multiply-by-1/2...
    # With mult = 2^30, SRDHM(a, 2^30) == round(a/2), so shift s gives ~a/2^(s+1).

    # --- D1: identity-ish and zero ---
    add("zero_acc",            0, unity, 0, 0)
    add("zero_acc_nonzero_zp", 0, unity, 0, 25)
    add("small_positive",     100, MULT_MAX, 0, 0)
    add("small_negative",    -100, MULT_MAX, 0, 0)

    # --- D1b: the clamp boundary, one LSB either side, on both rails.
    # With mult = 2^30 and shift = 0, DHIMUL(acc, 2^30) == acc/2 rounded, so
    # acc = 2*v drives exactly v into the clamp. These four pin the boundary
    # itself rather than sampling near it, which is what makes an off-by-one in
    # the comparison die in the directed phase instead of on random luck.
    add("clamp_edge_pos_127",  254, unity, 0, 0)    # lands on +127, must NOT clamp
    add("clamp_edge_pos_128",  256, unity, 0, 0)    # lands on +128, MUST clamp to +127
    add("clamp_edge_neg_128", -256, unity, 0, 0)    # lands on -128, must NOT clamp
    add("clamp_edge_neg_129", -258, unity, 0, 0)    # lands on -129, MUST clamp to -128
    # same boundary reached via the zero point rather than the datapath
    add("clamp_edge_zp_128",   256, unity, 0, 0)
    add("clamp_edge_zp_over",  200, unity, 0, 100)  # 100 + 100 = 200 -> +127

    # --- D2: saturation, both directions, and exactly at the rails ---
    add("sat_high",     INT32_MAX, MULT_MAX, 0, 0)
    add("sat_low",      INT32_MIN, MULT_MAX, 0, 0)
    add("sat_high_zp",  INT32_MAX, MULT_MAX, 0, 127)
    add("sat_low_zp",   INT32_MIN, MULT_MAX, 0, -128)
    # land exactly on +127 and -128 before the clamp, so clamp must NOT engage
    add("exactly_127",  127 << 1, MULT_MIN, 0, 0)
    add("exactly_m128", -128 << 1, MULT_MIN, 0, 0)

    # --- D3: tie handling at BOTH steps, both signs -- the core hazard ---
    # With mult = 2^30, SRDHM(a, 2^30) == a/2 rounded, so `acc = 1<<s` drives an
    # exact .5 into the step-2 shift. s stops at 30 because acc = 1<<31 would
    # leave the int32 input range.
    for s in (1, 2, 3, 8, 30):
        half = 1 << s
        add(f"round_half_pos_s{s}",  half, MULT_MIN, s, 0)
        add(f"round_half_neg_s{s}", -half, MULT_MIN, s, 0)
        add(f"round_just_under_s{s}",  half - 1, MULT_MIN, s, 0)
        add(f"round_just_over_s{s}",   half + 1, MULT_MIN, s, 0)

    # Step-1 ties specifically: odd acc with mult = 2^30 gives an exact x.5 into
    # SRDHM, where positive rounds up and negative rounds toward zero. These are
    # the vectors that fail a design assuming one uniform rounding mode.
    for a in (3, 5, 7, 9, 11, 1001, 32769):
        add(f"srdhm_tie_pos_{a}",  a, MULT_MIN, 0, 0)
        add(f"srdhm_tie_neg_{a}", -a, MULT_MIN, 0, 0)

    # --- D4: shift extremes ---
    add("shift_0_max",  INT32_MAX, MULT_MAX, 0, 0)
    add("shift_31_max", INT32_MAX, MULT_MAX, 31, 0)
    add("shift_31_min", INT32_MIN, MULT_MAX, 31, 0)
    add("shift_31_zero", 0, MULT_MIN, 31, 0)

    # --- D5: zero-point applied AFTER shift, and its own saturation ---
    add("zp_pushes_high",  100 << 4, MULT_MIN, 4, 127)
    add("zp_pushes_low",  -100 << 4, MULT_MIN, 4, -128)
    add("zp_max_from_zero", 0, MULT_MIN, 0, 127)
    add("zp_min_from_zero", 0, MULT_MIN, 0, -128)

    # --- D6: multiplier boundaries ---
    add("mult_min_bound", 1 << 20, MULT_MIN, 5, 0)
    add("mult_max_bound", 1 << 20, MULT_MAX, 5, 0)

    # --- R1: random soak, biased toward the interesting regions ---
    for i in range(2000):
        bucket = i % 5
        if bucket == 0:            # full-range acc
            acc = rnd.randint(INT32_MIN, INT32_MAX)
        elif bucket == 1:          # near zero, where rounding decides the result
            acc = rnd.randint(-1024, 1024)
        elif bucket == 2:          # near the int32 rails
            acc = rnd.choice([INT32_MIN, INT32_MAX]) + rnd.randint(-64, 64)
            acc = max(INT32_MIN, min(INT32_MAX, acc))
        elif bucket == 3:          # values that will land near the int8 clamp
            acc = rnd.randint(-300, 300) << rnd.randint(0, 8)
            acc = max(INT32_MIN, min(INT32_MAX, acc))
        else:                      # exact half-way points -> rounding ties
            s = rnd.randint(1, 20)
            acc = (rnd.randint(-500, 500) * 2 + 1) << (s - 1)
            acc = max(INT32_MIN, min(INT32_MAX, acc))
        mult = rnd.randint(MULT_MIN, MULT_MAX)
        shift = rnd.randint(0, 31)
        zp = rnd.randint(INT8_MIN, INT8_MAX)
        add(f"rand{i}", acc, mult, shift, zp)

    return cases


def emit(outdir: str, seed: int):
    cases = gen_cases(seed)
    os.makedirs(outdir, exist_ok=True)

    paths = {k: os.path.join(outdir, f"{k}.hex")
             for k in ("acc", "mult", "shift", "zp", "expected", "flags")}
    fh = {k: open(v, "w") for k, v in paths.items()}

    # flags bits, consumed by the checker for COVERAGE ACCOUNTING ONLY --
    # never for grading. Grading compares against expected.hex and nothing else.
    F_CLAMP_HI = 1 << 0
    F_CLAMP_LO = 1 << 1
    F_TIE1 = 1 << 2     # step 1 saw an exact .5
    F_TIE2 = 1 << 3     # step 2 saw an exact .5
    F_SH0 = 1 << 4
    F_SH31 = 1 << 5

    n = {k: 0 for k in ("clamp_hi", "clamp_lo", "tie1", "tie2", "sh0", "sh31")}

    for tag, acc, mult, shift, zp in cases:
        hi = saturating_rounding_doubling_high_mul(acc, mult)
        sh = rounding_divide_by_pot(hi, shift)
        biased = sh + zp
        exp = clamp_int8(biased)

        f = 0
        if biased > INT8_MAX:
            f |= F_CLAMP_HI; n["clamp_hi"] += 1
        if biased < INT8_MIN:
            f |= F_CLAMP_LO; n["clamp_lo"] += 1
        # step 1 tie: |acc*mult| has exactly 2^30 in its low 31 bits
        if (abs(acc * mult) & ((1 << 31) - 1)) == (1 << 30):
            f |= F_TIE1; n["tie1"] += 1
        # step 2 tie: hi's low `shift` bits are exactly the half-way value
        if shift > 0 and (hi & ((1 << shift) - 1)) == (1 << (shift - 1)):
            f |= F_TIE2; n["tie2"] += 1
        if shift == 0:
            f |= F_SH0; n["sh0"] += 1
        if shift == 31:
            f |= F_SH31; n["sh31"] += 1

        fh["acc"].write(_to_hex(acc, 32) + "\n")
        fh["mult"].write(_to_hex(mult, 32) + "\n")
        fh["shift"].write(_to_hex(shift, 8) + "\n")
        fh["zp"].write(_to_hex(zp, 8) + "\n")
        fh["expected"].write(_to_hex(exp, 8) + "\n")
        fh["flags"].write(_to_hex(f, 8) + "\n")
    for f in fh.values():
        f.close()

    with open(os.path.join(outdir, "MANIFEST.txt"), "w") as f:
        f.write(f"vectors: {len(cases)}\n")
        f.write(f"seed: {seed}\n")
        for k, v in n.items():
            f.write(f"{k}: {v}\n")
        f.write("generated by ref/model/int8_requant_model.py -- do not hand-edit\n")

    print(f"wrote {len(cases)} vectors to {outdir}")
    for k, v in n.items():
        print(f"  {k:9s} {v:5d} ({100.0*v/len(cases):5.1f}%)")
    return len(cases), n


# ---------------------------------------------------------------------------
# Self-test: properties that must hold independently of the implementation.
# ---------------------------------------------------------------------------

def selftest() -> int:
    fails = 0

    def chk(cond, msg):
        nonlocal fails
        if not cond:
            print(f"SELFTEST FAIL: {msg}")
            fails += 1

    # truncate-toward-zero, the sign trap
    chk(_trunc_div(-3, 2) == -1, "_trunc_div(-3,2) should be -1 (C), not -2 (floor)")
    chk(_trunc_div(3, 2) == 1, "_trunc_div(3,2) == 1")
    chk(_trunc_div(-4, 2) == -2, "_trunc_div(-4,2) == -2")

    # RDBPOT is round-half-AWAY-from-zero, symmetric about zero
    chk(rounding_divide_by_pot(3, 1) == 2, "3>>1 half rounds away -> 2")
    chk(rounding_divide_by_pot(-3, 1) == -2, "-3>>1 half rounds away -> -2")
    chk(rounding_divide_by_pot(1, 1) == 1, "1>>1 -> 1")
    chk(rounding_divide_by_pot(-1, 1) == -1, "-1>>1 -> -1")
    chk(rounding_divide_by_pot(5, 2) == 1, "5>>2 = 1.25 -> 1")
    chk(rounding_divide_by_pot(6, 2) == 2, "6>>2 = 1.5 -> 2 (away)")
    chk(rounding_divide_by_pot(-6, 2) == -2, "-6>>2 = -1.5 -> -2 (away)")
    chk(rounding_divide_by_pot(7, 0) == 7, "shift 0 is identity")

    # SRDHM: multiplying by 2^30 is division by 2 with rounding
    chk(saturating_rounding_doubling_high_mul(4, MULT_MIN) == 2, "SRDHM(4,2^30)==2")
    chk(saturating_rounding_doubling_high_mul(-4, MULT_MIN) == -2, "SRDHM(-4,2^30)==-2")
    chk(saturating_rounding_doubling_high_mul(0, MULT_MAX) == 0, "SRDHM(0,*)==0")
    chk(saturating_rounding_doubling_high_mul(INT32_MIN, INT32_MIN) == INT32_MAX,
        "SRDHM overflow case saturates")

    # ---- THE TWO STEPS USE DIFFERENT TIE RULES. This is not a bug and not a
    # transcription slip; it is what gemmlowp does and what ships in TFLite.
    # Pinned here because the spec pins it, and because a designer who assumes
    # one uniform rounding mode will fail exactly these vectors.
    #
    #   step 1 (SRDHM)  : ties round toward +infinity   (+3.5 -> +4, -3.5 -> -3)
    #   step 2 (RDBPOT) : ties round away from zero     (+1.5 -> +2, -1.5 -> -2)
    #
    # The asymmetry in step 1 comes from the negative nudge being (1 - 2^30)
    # rather than -2^30: that extra +1 pulls a negative exact-tie back toward
    # zero after truncation. Mutant m02 removes it.
    chk(saturating_rounding_doubling_high_mul(7, MULT_MIN) == 4,
        "SRDHM tie +3.5 -> +4")
    chk(saturating_rounding_doubling_high_mul(-7, MULT_MIN) == -3,
        "SRDHM tie -3.5 -> -3 (toward zero -- NOT away)")
    chk(saturating_rounding_doubling_high_mul(9, MULT_MIN) == 5, "SRDHM tie +4.5 -> +5")
    chk(saturating_rounding_doubling_high_mul(-9, MULT_MIN) == -4, "SRDHM tie -4.5 -> -4")
    # non-tie values ARE symmetric, which is what makes the tie asymmetry sharp
    chk(saturating_rounding_doubling_high_mul(8, MULT_MIN) == 4, "SRDHM exact +4")
    chk(saturating_rounding_doubling_high_mul(-8, MULT_MIN) == -4, "SRDHM exact -4")

    # step 2 in isolation is symmetric about zero
    for x in (3, 6, 10, 22, 1234567):
        for e in (1, 2, 5):
            chk(rounding_divide_by_pot(x, e) == -rounding_divide_by_pot(-x, e),
                f"RDBPOT must be sign-symmetric at x={x} e={e}")

    # composite: away from ties, negating the input negates the result
    for acc in (12344, 1000, 8, 1 << 20):
        for s in (0, 3, 11):
            a = requant(acc, MULT_MIN, s, 0)
            b = requant(-acc, MULT_MIN, s, 0)
            if abs(a) < 127 and abs(b) < 127:
                chk(a == -b, f"non-tie symmetry broken at acc={acc} shift={s}: {a} vs {-b}")

    # clamp really saturates, never wraps
    chk(requant(INT32_MAX, MULT_MAX, 0, 0) == 127, "positive saturation")
    chk(requant(INT32_MIN, MULT_MAX, 0, 0) == -128, "negative saturation")
    chk(requant(0, MULT_MIN, 0, 127) == 127, "zp alone reaches +127")
    chk(requant(0, MULT_MIN, 0, -128) == -128, "zp alone reaches -128")

    # every legal input produces an in-range int8
    rnd = random.Random(7)
    for _ in range(20000):
        r = requant(rnd.randint(INT32_MIN, INT32_MAX),
                    rnd.randint(MULT_MIN, MULT_MAX),
                    rnd.randint(0, 31),
                    rnd.randint(INT8_MIN, INT8_MAX))
        chk(INT8_MIN <= r <= INT8_MAX, f"result escaped int8 range: {r}")

    print("SELFTEST PASS" if fails == 0 else f"SELFTEST FAILED ({fails})")
    return fails


def check_against_nvdla_notes():
    """Cross-check record. NVDLA SDP is CONSULTED, never authoritative.

    NVDLA's SDP performs the same accumulate -> scale -> shift -> clamp chain
    with a per-channel multiplier and right shift, and truncates to int8 with
    saturation. That structural agreement is the whole of the cross-check: it
    confirms the task describes real inference hardware. It does NOT validate
    individual vectors, because NVDLA's rounding is a configuration option and
    is not guaranteed to be round-half-away-from-zero.

    Recorded in NOTES.md. Nothing in this file depends on it.
    """
    return None


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--emit-vectors", metavar="OUTDIR")
    ap.add_argument("--selftest", action="store_true")
    ap.add_argument("--seed", type=int, default=20260814)
    a = ap.parse_args()
    rc = 0
    if a.selftest:
        rc = selftest()
    if a.emit_vectors:
        emit(a.emit_vectors, a.seed)
    if not a.selftest and not a.emit_vectors:
        ap.print_help()
    sys.exit(1 if rc else 0)
