#!/usr/bin/env python3
"""Exact binary32 rounding model, and the audit that withdrew d_dsp01.

WHAT THIS IS FOR. Rule 11 puts expected values beyond the reach of locally
written code: the capture rig generates INPUTS ONLY and every expected value
comes from externally-authored RTL. That makes a FABRICATED answer impossible.
It does nothing about a WRONG anchor -- and when the contract is pinned to an
external standard rather than to the anchor's behaviour, those are different
risks. This model checks the anchor against the standard the contract cites,
before anything downstream is built on it. See F54.

It is deliberately not RTL and is never part of a scored path.

METHOD. Operands are converted to exact `Fraction`s, the quotient/root is
rounded once at the target precision under the requested mode, and flags follow
IEEE 754-2019 clause 7 with tininess detected AFTER rounding.

SELF-VALIDATION. `validate()` checks the model against binary64 division rounded
to binary32, which is exact for this purpose (53 >= 2*24 + 2, so there is no
double-rounding hazard). It reported 0 disagreements in 180 cases. A model that
has not been validated is an opinion.

Usage:  python3 ieee754_model.py ../../vectors/vectors.hex
"""
import struct, sys
from fractions import Fraction
from collections import Counter

P, EMIN = 24, -126          # binary32 precision and minimum normal exponent

def cls(u):
    e, m = (u >> 23) & 0xFF, u & 0x7FFFFF
    if e == 0:   return 'zero' if m == 0 else 'subn'
    if e == 255: return 'inf' if m == 0 else ('qnan' if m >> 22 else 'snan')
    return 'norm'

def to_frac(u):
    """(sign, exact magnitude as a Fraction). Subnormals included."""
    s, e, m = (u >> 31) & 1, (u >> 23) & 0xFF, u & 0x7FFFFF
    if e == 0:
        return s, Fraction(m, 1 << 23) * Fraction(2) ** EMIN
    return s, Fraction((1 << 23) | m, 1 << 23) * Fraction(2) ** (e - 127)

RNE, RTZ, RDN, RUP, RMM = range(5)
MODE_NAMES = {RNE: 'RNE', RTZ: 'RTZ', RDN: 'RDN', RUP: 'RUP', RMM: 'RMM'}

def round_exact(fr, sign, mode):
    """Correctly round an exact non-negative Fraction. Returns (bits, flags)
    with flags = {NV,DZ,OF,UF,NX} in bits 4..0."""
    if fr == 0:
        return (sign << 31), 0
    e = fr.numerator.bit_length() - fr.denominator.bit_length()
    while Fraction(2) ** e > fr:        e -= 1
    while Fraction(2) ** (e + 1) <= fr: e += 1
    exp = max(e - (P - 1), EMIN - (P - 1))          # gradual underflow
    scaled = fr / Fraction(2) ** exp
    q, rem = scaled.numerator // scaled.denominator, None
    rem = scaled - q
    inexact = rem != 0
    if   mode == RNE: up = rem > Fraction(1, 2) or (rem == Fraction(1, 2) and q & 1)
    elif mode == RTZ: up = False
    elif mode == RDN: up = inexact and sign == 1
    elif mode == RUP: up = inexact and sign == 0
    elif mode == RMM: up = rem >= Fraction(1, 2)
    else:             up = False
    if up: q += 1
    val = Fraction(q) * Fraction(2) ** exp
    if val >= Fraction(2) ** 128:                    # overflow, clause 7.4
        away = not (mode == RTZ or (mode == RDN and sign == 0)
                                or (mode == RUP and sign == 1))
        bits = (sign << 31) | (0x7F800000 if away else 0x7F7FFFFF)
        return bits, 0b00101                         # OF | NX
    if q >= (1 << P): q >>= 1; exp += 1
    if q < (1 << (P - 1)) and exp <= EMIN - (P - 1):
        bits = (sign << 31) | q                      # subnormal
    else:
        bits = (sign << 31) | ((exp + (P - 1) + 127) << 23) | (q & 0x7FFFFF)
    tiny_after = val != 0 and val < Fraction(2) ** EMIN
    return bits, (0b00001 if inexact else 0) | (0b00010 if inexact and tiny_after else 0)

def read_vectors(path):
    """112-bit words: [104] op [103:101] rnd [100:69] a [68:37] b [36:5] result [4:0] flags"""
    out = []
    for ln in open(path):
        ln = ln.strip()
        if not ln: continue
        v = int(ln, 16)
        out.append(dict(op=(v >> 104) & 1, rnd=(v >> 101) & 7,
                        a=(v >> 69) & 0xFFFFFFFF, b=(v >> 37) & 0xFFFFFFFF,
                        r=(v >> 5) & 0xFFFFFFFF, f=v & 0x1F))
    return out

def finite_div(x):
    return (x['op'] == 0
            and cls(x['a']) in ('norm', 'subn') and cls(x['b']) in ('norm', 'subn')
            and to_frac(x['b'])[1] != 0)

def validate(rows):
    """Model vs binary64-then-round. Must be 0 before any verdict below is used."""
    u2f = lambda u: struct.unpack('<f', struct.pack('<I', u))[0]
    def f2u(x):
        try: return struct.unpack('<I', struct.pack('<f', x))[0]
        except OverflowError: return None
    n = bad = 0
    for x in rows:
        if not finite_div(x) or x['rnd'] != RNE: continue
        ref = f2u(u2f(x['a']) / u2f(x['b']))
        sa, fa = to_frac(x['a']); sb, fb = to_frac(x['b'])
        mine, _ = round_exact(fa / fb, sa ^ sb, RNE)
        if ref is None: continue
        n += 1; bad += (ref != mine)
    return n, bad

def in_range(x):
    """True when the exact quotient cannot overflow under any mode. Subnormal
    results ARE included -- gradual underflow is the capability the contract
    exists to measure, and validate() covers it, since binary64-then-round
    handles subnormals correctly. Only OVERFLOW is excluded: which of infinity
    and the largest finite a mode delivers is a separate convention that must
    not be allowed to blur the diagonal."""
    if not finite_div(x): return False
    sa, fa = to_frac(x['a']); sb, fb = to_frac(x['b'])
    q = fa / fb
    return q < Fraction(2) ** 128

def crosstab(rows):
    """Rows: the mode DRIVEN. Columns: the mode the anchor actually delivered."""
    print(f"{'driven':>8} | " + " ".join(f"{MODE_NAMES[m]:>7}" for m in range(5)) + "       n")
    for d in range(5):
        sel = [x for x in rows if in_range(x) and x['rnd'] == d]
        cells, tot = [], 0
        for m in range(5):
            ok = tot = 0
            for x in sel:
                sa, fa = to_frac(x['a']); sb, fb = to_frac(x['b'])
                mb, _ = round_exact(fa / fb, sa ^ sb, m)
                tot += 1; ok += (mb == x['r'])
            cells.append(f"{ok/tot:7.3f}" if tot else "      -")
        print(f"{MODE_NAMES[d]:>8} | " + " ".join(cells) + f"   {tot:5d}")

if __name__ == '__main__':
    rows = read_vectors(sys.argv[1] if len(sys.argv) > 1 else 'vectors/vectors.hex')
    print(f"vectors: {len(rows)}")
    n, bad = validate(rows)
    print(f"model self-validation vs binary64 (RNE): n={n} disagreements={bad}")
    if bad:
        sys.exit("model is not validated; nothing below is evidence")
    print("\nfraction of anchor results matching the model under each mode")
    print("(in-range quotients only -- the population validate() covers):")
    crosstab(rows)

    # Subnormal results, separately: this is the capability the contract exists
    # to measure, so it must not be averaged into the table above.
    sub = [x for x in rows if in_range(x) and cls(x['r']) == 'subn']
    ok = sum(1 for x in sub
             if round_exact(to_frac(x['a'])[1] / to_frac(x['b'])[1],
                            to_frac(x['a'])[0] ^ to_frac(x['b'])[0], x['rnd'])[0] == x['r'])
    print(f"\nsubnormal DIV results: {ok}/{len(sub)} bit-exact")
    fl = sum(1 for x in rows if in_range(x)
             and round_exact(to_frac(x['a'])[1] / to_frac(x['b'])[1],
                             to_frac(x['a'])[0] ^ to_frac(x['b'])[0], x['rnd'])[1] != x['f'])
    print(f"flag disagreements over in-range DIV: {fl}/{sum(1 for x in rows if in_range(x))}")
