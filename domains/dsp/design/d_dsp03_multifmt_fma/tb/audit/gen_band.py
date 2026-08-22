#!/usr/bin/env python3
"""Directed UNDERFLOW-BAND vectors. Inputs only -- rule 11.

The band is the case A7a exists to settle: an exact result strictly below the
smallest normal that rounds UP to exactly the smallest normal. The pinned rule
(delivered exponent field zero) says that is not underflow; IEEE 754-2019
clause 7.5's unbounded-exponent rule says it is. They disagree under RNE, RUP
and RMM and agree under RTZ and RDN, so driving all five modes crosses the
boundary in BOTH directions from one operand pair.

Five case shapes per format, per sign, per mode:
  BAND     (2 - 2^-M)*2^(1-bias) * 0.5  = (1 - 2^-(M+1))*2^(1-bias). The band.
  LOW      the same times 0.25: half the smallest normal, subnormal in EVERY
           mode, inexact. Brackets the band from below; both rules agree.
  HIGH     the same times (1 + 1ulp): normal in every mode, inexact. Brackets
           from above; both rules agree.
  FTZ      smallest subnormal squared: tiny, inexact, rounds to zero. This is
           why the predicate says "exponent field is zero" and not "subnormal".
  EXACT    smallest subnormal * 1.0: tiny and EXACT. No flags at all. Brackets
           the INEXACT half of the predicate rather than the tininess half.
"""
import sys, json

GEOM = {0: ("FP32", 8, 23), 1: ("FP16", 5, 10), 2: ("BF16", 8, 7)}

def consts(f):
    _, E, M = GEOM[f]
    bias = (1 << (E - 1)) - 1
    return dict(E=E, M=M, bias=bias, W=1 + E + M,
                lowmax=(1 << M) | ((1 << M) - 1),   # exp field 1, mantissa all ones
                half=(bias - 1) << M,
                quarter=(bias - 2) << M,
                one=bias << M,
                one_ulp=(bias << M) | 1,
                tiny=1)

def shapes(f, sign):
    k = consts(f); s = sign << (k["W"] - 1)
    return [
        ("BAND",  s | k["lowmax"], k["half"],    0),
        ("LOW",   s | k["lowmax"], k["quarter"], 0),
        ("HIGH",  s | k["lowmax"], k["one_ulp"], 0),
        ("FTZ",   s | k["tiny"],   k["tiny"],    0),
        ("EXACT", s | k["tiny"],   k["one"],     0),
    ]

def build(width):
    cases = []
    for f in (0, 1, 2):
        for sign in (0, 1):
            for name, a, b, c in shapes(f, sign):
                for r in range(5):
                    cases.append((f"{GEOM[f][0]}/{name}/{'neg' if sign else 'pos'}",
                                  f, 0, r, a, b, c))
    # vectorial: the band in EVERY lane position, benign elsewhere, so a design
    # that computes the band correctly in lane 0 only is caught.
    for f in (0, 1, 2):
        k = consts(f); FW = k["W"]
        n = width // FW
        if n < 2:
            continue
        band = (k["lowmax"], k["half"], 0)
        benign = (k["one"], k["one"], k["one"])          # 1*1+1 = 2, no flags
        for lane in range(n):
            for r in range(5):
                a = b = c = 0
                for i in range(n):
                    src = band if i == lane else benign
                    a |= src[0] << (i * FW)
                    b |= src[1] << (i * FW)
                    c |= src[2] << (i * FW)
                cases.append((f"{GEOM[f][0]}/BAND-vec-lane{lane}", f, 1, r, a, b, c))
    return cases

if __name__ == "__main__":
    width = int(sys.argv[1]); out = sys.argv[2]
    cases = build(width)
    with open(out, "w") as fh:
        for _, f, vec, r, a, b, c in cases:
            fh.write(f"{(f << 196) | (vec << 195) | (r << 192) | (a << 128) | (b << 64) | c:050x}\n")
    json.dump([n for n, *_ in cases], open(out.replace(".hex", "_meta.json"), "w"))
    print(f"WIDTH={width}: {len(cases)} band cases -> {out}")
