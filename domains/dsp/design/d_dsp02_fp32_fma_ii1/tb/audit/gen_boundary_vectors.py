#!/usr/bin/env python3
"""Generate FMA cases that sit at or near fp32 rounding boundaries.

The cases are chosen so the five rounding modes DISAGREE wherever possible --
a case all modes agree on cannot detect a mode being mis-implemented, which is
exactly the defect found in fpnew_divsqrt_multi.
"""
import sys
sys.path.insert(0, "/private/tmp/claude-501/-Users-jackberkowitz-Desktop-hw-rl-benchmark/2381f2fe-5b48-47a1-8d06-7bf301d0b593/scratchpad")
from fma_oracle import encode, decode, fma_exact

MODES = ["RNE", "RTZ", "RDN", "RUP", "RMM"]
cases = []          # (tag, a, b, c)


def add(tag, a, b, c):
    cases.append((tag, a, b, c))


# ---------------------------------------------------------------- A: exact ties
# 1.0 * (1 + k*ulp) + 2^-24  == exact halfway above (1 + k*ulp).
# k even and k odd exercise ties-to-even in BOTH directions.
for k in (0, 1, 2, 3, 6, 7, 0x7FFFFE, 0x7FFFFF):
    add(f"tie_mant{k:#x}", encode(0, 127, 0), encode(0, 127, k), encode(0, 103, 0))

# same at other binades, so a mode error cannot hide at one exponent
for be in (100, 110, 140, 200, 250):
    add(f"tie_exp{be}", encode(0, be, 0), encode(0, 127, 1), encode(0, be - 24, 0))

# negative results: RDN/RUP must swap roles
for k in (0, 1, 5):
    add(f"tie_neg_mant{k}", encode(1, 127, 0), encode(0, 127, k), encode(1, 103, 0))

# ------------------------------------------------------- B: just off the tie
# one ulp of the exact value below / above the halfway point: every mode must
# agree here, so a disagreement means something other than tie-breaking is wrong
add("just_below_tie", encode(0, 127, 0), encode(0, 127, 0), encode(0, 102, 0))
add("just_above_tie", encode(0, 127, 0), encode(0, 127, 0), encode(0, 103, 1))

# ---------------------------------------------------------- C: subnormal results
# product lands deep in subnormal territory; c nudges it onto a subnormal tie.
add("sub_tie_a", encode(0, 60, 0), encode(0, 40, 0), encode(0, 0, 1))
add("sub_tie_b", encode(0, 50, 0), encode(0, 50, 0), encode(0, 0, 3))
add("sub_small", encode(0, 1, 0), encode(0, 1, 0), encode(0, 0, 0))
add("sub_plus_min", encode(0, 0, 1), encode(0, 127, 0), encode(0, 0, 1))
# a subnormal tie: exact value halfway between two subnormals
add("sub_halfway", encode(0, 64, 0), encode(0, 40, 0), encode(0, 0, 5))

# --------------------------------------------- D: tininess AFTER rounding
# Exact value just below 2^-126 (smallest normal) that rounds UP to exactly
# 2^-126. Under tininess-after-rounding this is NOT underflow.
# largest subnormal = (2^23 - 1) * 2^-149 ; smallest normal = 2^-126
add("tiny_boundary_up", encode(0, 0, 0x7FFFFF), encode(0, 127, 0), encode(0, 0, 1))
add("tiny_boundary_near", encode(0, 1, 0), encode(0, 126, 0x7FFFFF), encode(0, 0, 0))
# just under the boundary, stays subnormal -> IS underflow
add("tiny_stays_sub", encode(0, 0, 0x7FFFFE), encode(0, 127, 0), encode(0, 0, 0))

# ------------------------------------------------------------- E: overflow edge
add("ovf_edge", encode(0, 254, 0x7FFFFF), encode(0, 127, 0), encode(0, 254, 0x7FFFFF))
add("ovf_tie", encode(0, 254, 0x7FFFFF), encode(0, 127, 1), encode(0, 0, 0))

# ------------------------------------------- F: cancellation leaving few bits
add("cancel_small", encode(0, 127, 1), encode(0, 127, 0), encode(1, 127, 0))
add("cancel_tie", encode(0, 128, 1), encode(0, 127, 0), encode(1, 128, 0))

# --------------------------------------------------------------------- emit
vec_path = sys.argv[1] if len(sys.argv) > 1 else "vectors.txt"
exp_path = sys.argv[2] if len(sys.argv) > 2 else "expected.txt"
with open(vec_path, "w") as vf, open(exp_path, "w") as ef:
    n = 0
    for tag, a, b, c in cases:
        for mi, m in enumerate(MODES):
            r = fma_exact(a, b, c, m)
            if r is None:
                continue                       # NaN/Inf path, not this audit
            bits, inexact, ovf, uf = r
            vf.write(f"{a:08x} {b:08x} {c:08x} {mi}\n")
            ef.write(f"{tag} {m} {a:08x} {b:08x} {c:08x} "
                     f"{bits:08x} {int(inexact)} {int(ovf)} {int(uf)}\n")
            n += 1
print(f"  {len(cases)} cases x {len(MODES)} modes = {n} vectors")

# How many cases actually DISCRIMINATE between modes? A case where every mode
# agrees is dead weight for this audit.
disc = 0
for tag, a, b, c in cases:
    outs = {fma_exact(a, b, c, m)[0] for m in MODES if fma_exact(a, b, c, m)}
    if len(outs) > 1:
        disc += 1
print(f"  cases where the modes DISAGREE (i.e. can detect a mode defect): {disc}/{len(cases)}")
