#!/usr/bin/env python3
"""Format-generic exact FMA model, and the anchor audit for d_dsp03.

WHY THIS RUNS BEFORE ANYTHING ELSE IS BUILT. Rule 11 keeps locally written code
away from expected values: the capture rig generates inputs only. That makes a
fabricated answer impossible and says nothing about whether the vendored anchor
knows the right one. d_dsp01 satisfied rule 11 exactly and its anchor was wrong
in four rounding modes of five -- see F54. An anchor is a CANDIDATE for the
reference until its output has been checked against the standard the contract
cites.

METHOD. Operands decode to exact `Fraction`s, a*b + c is formed exactly (no
rounding -- that is what makes it a *fused* multiply-add), and the exact result
is rounded ONCE at the target precision.

VALIDATION -- `validate_rounder`. The rounder is checked against a property it
does not itself compute: for an exact value v, find the bracketing representable
pair by BINARY SEARCH OVER BIT PATTERNS (legal because IEEE magnitude is
monotonic in the encoding), then assert the rounder picked the member the mode
requires. That is independent of the rounding arithmetic, and it runs at every
format rather than only the one a library happens to support. A model that has
not been validated is an opinion.

Usage:  python3 ieee754_fma_model.py ../../vectors/vectors.hex
"""
import sys, random
from fractions import Fraction
from collections import Counter

RNE, RTZ, RDN, RUP, RMM = range(5)
MODE_NAMES = {RNE: 'RNE', RTZ: 'RTZ', RDN: 'RDN', RUP: 'RUP', RMM: 'RMM'}
FMTS = {0: ('FP32', 8, 23), 1: ('FP16', 5, 10), 2: ('BF16', 8, 7)}

NV, DZ, OF, UF, NX = 0b10000, 0b01000, 0b00100, 0b00010, 0b00001

def geom(E, M):
    return (1 << (E - 1)) - 1, -((1 << (E - 1)) - 2)      # bias, emin

def classify(bits, E, M):
    e, m = (bits >> M) & ((1 << E) - 1), bits & ((1 << M) - 1)
    if e == 0:            return 'zero' if m == 0 else 'subn'
    if e == (1 << E) - 1: return 'inf' if m == 0 else ('qnan' if m >> (M - 1) else 'snan')
    return 'norm'

def decode(bits, E, M):
    """(sign, exact magnitude as Fraction). Only for finite inputs."""
    bias, emin = geom(E, M)
    s = (bits >> (E + M)) & 1
    e, m = (bits >> M) & ((1 << E) - 1), bits & ((1 << M) - 1)
    if e == 0:
        return s, Fraction(m, 1 << M) * Fraction(2) ** emin
    return s, Fraction((1 << M) | m, 1 << M) * Fraction(2) ** (e - bias)

def qnan(E, M):
    return (((1 << E) - 1) << M) | (1 << (M - 1))

def _round_at(v, exp, sign, mode):
    """Round v to an integer multiple of 2**exp. Returns (q, inexact)."""
    scaled = v / Fraction(2) ** exp
    q = scaled.numerator // scaled.denominator
    rem = scaled - q
    inexact = rem != 0
    if   mode == RNE: up = rem > Fraction(1, 2) or (rem == Fraction(1, 2) and q & 1)
    elif mode == RTZ: up = False
    elif mode == RDN: up = inexact and sign == 1
    elif mode == RUP: up = inexact and sign == 0
    elif mode == RMM: up = rem >= Fraction(1, 2)
    else:             up = False
    if up: q += 1
    return q, inexact

def round_frac(v, sign, E, M, mode):
    """Round an exact non-negative Fraction. Returns (bits, flags)."""
    bias, emin = geom(E, M)
    P = M + 1
    if v == 0:
        return (sign << (E + M)), 0
    e = v.numerator.bit_length() - v.denominator.bit_length()
    while Fraction(2) ** e > v:       e -= 1
    while Fraction(2) ** (e + 1) <= v: e += 1
    exp = max(e - (P - 1), emin - (P - 1))            # gradual underflow
    q, inexact = _round_at(v, exp, sign, mode)
    val = Fraction(q) * Fraction(2) ** exp
    emax_val = Fraction(2) ** (bias + 1)
    if val >= emax_val:                                # overflow, clause 7.4
        away = not (mode == RTZ or (mode == RDN and sign == 0)
                                or (mode == RUP and sign == 1))
        top = (((1 << E) - 1) << M) if away else ((((1 << E) - 2) << M) | ((1 << M) - 1))
        return (sign << (E + M)) | top, OF | NX
    if q >= (1 << P): q >>= 1; exp += 1
    if q < (1 << (P - 1)) and exp <= emin - (P - 1):
        bits = (sign << (E + M)) | q                   # subnormal
    else:
        bits = (sign << (E + M)) | ((exp + (P - 1) + bias) << M) | (q & ((1 << M) - 1))
    # UNDERFLOW predicate -- TRACKS A PINNED TASK DECISION, 2026-08-21.
    #
    # NOT a bug fix, and this model was not wrong before. It implemented IEEE
    # 754-2019 clause 7.5's tininess-after-rounding rule -- round at the target
    # precision with an UNBOUNDED EXPONENT, then test against the smallest
    # normal -- which is a correct reading of the standard.
    #
    # The CONTRACT changed under it. A7a (d_dsp03) and A6 (d_dsp02) now pin the
    # delivered-result rule longhand and cite no standard: UF iff inexact AND
    # the delivered result's biased exponent field is zero, which covers
    # subnormals and zeros alike. The two rules agree everywhere except one
    # band -- an exact result below the smallest normal that rounds UP to it --
    # where they disagree under RNE, RUP and RMM.
    expfield = (bits >> M) & ((1 << E) - 1)
    return bits, (NX if inexact else 0) | (UF if (inexact and expfield == 0) else 0)

def fma(ab, bb, cb, E, M, mode):
    """Bit-exact fused multiply-add. Returns (bits, flags)."""
    ca, cbc, cc = classify(ab, E, M), classify(bb, E, M), classify(cb, E, M)
    if 'snan' in (ca, cbc, cc):
        return qnan(E, M), NV
    sa = (ab >> (E + M)) & 1; sb = (bb >> (E + M)) & 1; sc = (cb >> (E + M)) & 1
    sp = sa ^ sb
    # 0 * inf is invalid whatever c is, and takes priority over a quiet NaN c
    if (ca == 'inf' and cbc == 'zero') or (ca == 'zero' and cbc == 'inf'):
        return qnan(E, M), NV
    if 'qnan' in (ca, cbc, cc):
        return qnan(E, M), 0
    if ca == 'inf' or cbc == 'inf':                    # product is infinite
        if cc == 'inf' and sc != sp:                   # inf - inf
            return qnan(E, M), NV
        return (sp << (E + M)) | (((1 << E) - 1) << M), 0
    if cc == 'inf':
        return cb, 0
    _, fa = decode(ab, E, M); _, fb = decode(bb, E, M); _, fc = decode(cb, E, M)
    prod = fa * fb
    exact = (Fraction(-1) ** sp) * prod + (Fraction(-1) ** sc) * fc
    if exact == 0:
        # IEEE 754-2019 clause 6.3: an exact zero from operands of opposite sign
        # is +0 in every mode but roundTowardNegative.
        if prod == 0 and fc == 0 and sp == sc:
            return (sp << (E + M)), 0
        return ((1 if mode == RDN else 0) << (E + M)), 0
    sign = 0 if exact > 0 else 1
    return round_frac(abs(exact), sign, E, M, mode)

# ---------------------------------------------------------------------------
# validation: the bracketing-pair property, independent of the rounder
# ---------------------------------------------------------------------------
def validate_rounder(E, M, trials=3000, seed=7):
    bias, emin = geom(E, M)
    maxfinite = (((1 << E) - 2) << M) | ((1 << M) - 1)
    rng = random.Random(seed)
    def mag(bits): return decode(bits, E, M)[1]
    bad = 0
    for _ in range(trials):
        # an exact value somewhere in range, usually between two representables
        lo_pat = rng.randrange(1, maxfinite)
        frac = Fraction(rng.randrange(1, 1000), 1000)
        v = mag(lo_pat) + frac * (mag(lo_pat + 1) - mag(lo_pat))
        if v >= Fraction(2) ** (bias + 1): continue
        # bracket by binary search over patterns -- magnitude is monotonic here
        lo, hi = 0, maxfinite
        while lo < hi:
            mid = (lo + hi + 1) // 2
            if mag(mid) <= v: lo = mid
            else:             hi = mid - 1
        below, above = lo, min(lo + 1, maxfinite)
        for sign in (0, 1):
            for mode in range(5):
                got, _ = round_frac(v, sign, E, M, mode)
                got &= (1 << (E + M)) - 1
                if   mode == RTZ: want = below
                elif mode == RDN: want = above if sign else below
                elif mode == RUP: want = below if sign else above
                else:
                    db, da = v - mag(below), mag(above) - v
                    if   db < da: want = below
                    elif da < db: want = above
                    else: want = above if mode == RMM else (below if not (below & 1) else above)
                if got != want: bad += 1
    return trials, bad

# ---------------------------------------------------------------------------
M64 = (1 << 64) - 1

def read_vectors(path):
    """288-bit records. The WIDTH is read from the record, not from the path."""
    out = []
    for ln in open(path):
        ln = ln.strip()
        if not ln: continue
        v = int(ln, 16)
        out.append(dict(fmt=(v >> 266) & 3, w=64 if (v >> 265) & 1 else 32,
                        vec=(v >> 264) & 1, rnd=(v >> 261) & 7,
                        a=(v >> 197) & M64, b=(v >> 133) & M64, c=(v >> 69) & M64,
                        r=(v >> 5) & M64, f=v & 0x1F))
    return out

def expect(x):
    """Model result for one captured vector: N lanes of the selected format,
    N = WIDTH/fmt_width when vectorial and 1 otherwise. Bits above the lanes in
    use are NaN-boxed to all ones; flags are the OR across lanes."""
    _, E, M = FMTS[x['fmt']]
    FW, W = E + M + 1, x['w']
    n = (W // FW) if x['vec'] else 1
    mask = (1 << FW) - 1
    res, flags = 0, 0
    for i in range(n):
        bits, fl = fma((x['a'] >> (i * FW)) & mask,
                       (x['b'] >> (i * FW)) & mask,
                       (x['c'] >> (i * FW)) & mask, E, M, x['rnd'])
        res |= bits << (i * FW)
        flags |= fl
    if n * FW < W:                       # NaN-boxing above the lanes in use
        res |= ((1 << (W - n * FW)) - 1) << (n * FW)
    return res, flags

if __name__ == '__main__':
    print("rounder validation (bracketing-pair property, independent of the rounder):")
    okall = True
    for k, (nm, E, M) in FMTS.items():
        n, bad = validate_rounder(E, M)
        print(f"  {nm:5s} (E={E},M={M}): {n} trials x 2 signs x 5 modes, mismatches={bad}")
        okall &= (bad == 0)
    if not okall:
        sys.exit("rounder is not validated; nothing below is evidence")

    rows = []
    for path in (sys.argv[1:] or ['vectors/vectors_w32.hex', 'vectors/vectors_w64.hex']):
        rows += read_vectors(path)
    print(f"\nvectors: {len(rows)}")
    print(f"{'W':>4} {'fmt':>6} {'mode':>5} {'lanes':>6} {'n':>6} {'result bad':>11} {'flags bad':>10}")
    tot_r = tot_f = 0
    for W in (32, 64):
        for k, (nm, E, M) in FMTS.items():
            for v in (0, 1):
                sel = [x for x in rows if x['w'] == W and x['fmt'] == k and x['vec'] == v]
                if not sel: continue
                rb = fb = 0
                for x in sel:
                    eb, ef = expect(x)
                    if eb != x['r']: rb += 1
                    if ef != x['f']: fb += 1
                tot_r += rb; tot_f += fb
                nl = (W // (E + M + 1)) if v else 1
                print(f"{W:>4} {nm:>6} {'vec' if v else 'scal':>5} {nl:6d} "
                      f"{len(sel):6d} {rb:11d} {fb:10d}")
    print(f"\nTOTAL result mismatches: {tot_r}    flag mismatches: {tot_f}")
    if tot_r == 0 and tot_f == 0:
        print("ANCHOR CONFORMS on this vector set -- usable as a golden reference.")
