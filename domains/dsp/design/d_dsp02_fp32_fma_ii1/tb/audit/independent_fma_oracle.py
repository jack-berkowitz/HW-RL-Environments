#!/usr/bin/env python3
"""An INDEPENDENT fp32 fused-multiply-add oracle, in exact integer arithmetic.

WHY THIS EXISTS
---------------
d_dsp02's vector set is generated under rule 11's inversion: local code produces
the INPUTS, the vendored anchor (fpnew_fma) produces the EXPECTED VALUES. That
makes expected values unfalsifiable from inside the task -- if the anchor rounds
wrongly, every vector inherits the defect, the reference passes, every mutant
behaves as designed, and the task pins the defect as its contract.

The only check that reaches that is an independent computation of the same
quantity. Agent 2's rejection of fpnew_divsqrt_multi was exactly this: exact
rational arithmetic, compared against the module, found truncation where RNE
requires round-to-nearest.

METHOD
------
NO PYTHON FLOAT APPEARS ANYWHERE IN THIS FILE. Every fp32 value is a dyadic
rational, exactly representable as  (-1)^s * N * 2^E  with N and E integers.
Products and sums of dyadic rationals are dyadic, so a*b+c is computed EXACTLY
with Python's arbitrary-precision integers, and only then rounded once. That is
the definition of a fused multiply-add: one rounding, applied to the exact
product-sum.

Rounding is implemented from the IEEE-754 rules directly, not by calling any
library that might share an implementation (and therefore a bug) with the DUT.
"""
import struct   # ONLY for bit-pattern <-> int on the wire; never for arithmetic

# fp32 parameters
MANT = 23
EMAX = 127
EMIN = -126
BIAS = 127
SUBNORMAL_EXP = EMIN - MANT          # -149: exponent of the smallest ulp
MAX_BIASED = 254


def decode(bits):
    """bits -> ('num', sign, N, E) with value = (-1)^sign * N * 2^E, or a class."""
    s = (bits >> 31) & 1
    e = (bits >> 23) & 0xFF
    m = bits & 0x7FFFFF
    if e == 0xFF:
        return ("nan" if m else "inf", s, 0, 0)
    if e == 0:
        return ("num", s, m, SUBNORMAL_EXP)          # zero falls out as N=0
    return ("num", s, m + (1 << MANT), e - BIAS - MANT)


def encode(sign, biased_exp, mant):
    return ((sign & 1) << 31) | ((biased_exp & 0xFF) << 23) | (mant & 0x7FFFFF)


def round_to_fp32(sign, N, E, mode):
    """Round exact (-1)^sign * N * 2^E to fp32. Returns (bits, inexact, overflow,
    underflow). `mode` is one of RNE RTZ RDN RUP RMM."""
    if N == 0:
        # Exact zero. IEEE: the sign of an exact-zero sum is + in every mode
        # except roundTowardNegative, where it is -.
        return (encode(1 if mode == "RDN" else 0, 0, 0), False, False, False)

    msb = E + N.bit_length() - 1              # position of the leading 1
    # Target quantum: 24 significant bits, but never finer than 2^-149.
    Q = max(msb - MANT, SUBNORMAL_EXP)
    shift = Q - E

    if shift <= 0:
        M, round_bit, sticky = N << (-shift), 0, 0
    else:
        M = N >> shift
        rem = N & ((1 << shift) - 1)
        round_bit = (rem >> (shift - 1)) & 1 if shift >= 1 else 0
        sticky = 1 if (rem & ((1 << (shift - 1)) - 1)) else 0

    inexact = bool(round_bit or sticky)

    # --- the five modes, straight from the standard -------------------------
    if mode == "RNE":
        inc = round_bit and (sticky or (M & 1))
    elif mode == "RTZ":
        inc = False
    elif mode == "RDN":
        inc = (sign == 1) and inexact
    elif mode == "RUP":
        inc = (sign == 0) and inexact
    elif mode == "RMM":
        inc = bool(round_bit)
    else:
        raise ValueError(mode)

    if inc:
        M += 1
        if M >= (1 << (MANT + 1)):            # carried out of 24 bits
            M >>= 1
            Q += 1

    # --- classify ------------------------------------------------------------
    if M >= (1 << MANT):                      # normal
        biased = Q + MANT + BIAS
        if biased > MAX_BIASED:               # overflow
            if mode == "RTZ" or (mode == "RDN" and sign == 0) or \
               (mode == "RUP" and sign == 1):
                return (encode(sign, MAX_BIASED, 0x7FFFFF), True, True, False)
            return (encode(sign, 0xFF, 0), True, True, False)
        bits = encode(sign, biased, M - (1 << MANT))
        # TININESS AFTER ROUNDING: a value that was tiny before rounding but
        # became the smallest normal AFTER rounding is NOT underflow.
        return (bits, inexact, False, False)

    # subnormal (or zero after rounding)
    bits = encode(sign, 0, M)
    underflow = inexact                       # tiny AND inexact
    return (bits, inexact, False, underflow)


def fma_exact(a_bits, b_bits, c_bits, mode):
    """Exact (a*b)+c, rounded ONCE. Returns (bits, inexact, overflow, underflow,
    invalid) or ('special', bits) for NaN/Inf paths."""
    ka, sa, na, ea = decode(a_bits)
    kb, sb, nb, eb = decode(b_bits)
    kc, sc, nc, ec = decode(c_bits)

    # Special cases are NOT the subject of this audit -- the spec pins them and
    # they were checked directly. Flag them so the caller can skip.
    if "nan" in (ka, kb, kc) or "inf" in (ka, kb, kc):
        return None

    # exact product
    sp = sa ^ sb
    np_, ep = na * nb, ea + eb

    # exact sum, on a common exponent
    e_common = min(ep, ec)
    P = np_ << (ep - e_common)
    C = nc << (ec - e_common)
    sp_signed = P if sp == 0 else -P
    sc_signed = C if sc == 0 else -C
    total = sp_signed + sc_signed

    if total == 0:
        # exact cancellation: sign is + except under RDN
        return (encode(1 if mode == "RDN" else 0, 0, 0), False, False, False)
    sign = 0 if total > 0 else 1
    return round_to_fp32(sign, abs(total), e_common, mode)


# ---------------------------------------------------------------- helpers
def f32_bits_from_parts(sign, biased, mant):
    return encode(sign, biased, mant)


def exact_value_str(a, b, c):
    """The exact (a*b)+c as an integer-scaled string, for the report. Still no
    float: returns (numerator, power-of-two exponent)."""
    _, sa, na, ea = decode(a)
    _, sb, nb, eb = decode(b)
    _, sc, nc, ec = decode(c)
    sp, np_, ep = sa ^ sb, na * nb, ea + eb
    e = min(ep, ec)
    tot = (np_ << (ep - e)) * (1 if sp == 0 else -1) + \
          (nc << (ec - e)) * (1 if sc == 0 else -1)
    return tot, e
