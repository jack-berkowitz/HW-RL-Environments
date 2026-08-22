#!/usr/bin/env python3
"""Append the A6 underflow-band inputs to vectors/inputs.hex. INPUTS ONLY.

Rule 11: this generates operand tuples and nothing else. Expected values come
from the vendored anchor via tb/audit/capture_vectors_tb.sv, as for every other
vector in this task.

WHY THESE VECTORS EXIST. A6 pins underflow as "inexact AND the delivered
result's biased exponent field is zero" and departs from IEEE 754-2019 clause
7.5 in one band -- an exact result strictly below the smallest normal that
rounds UP onto it. The original 4290 reached that band 6 times, positive sign
only, so the negative half of the clause was unexercised and the mutant that
sits on the alternative reading (mA8) had only half its target. These 50 add
both signs across all five modes, plus the brackets either side and the
flush-to-zero case that motivated the exponent-field wording.

IDEMPOTENT-BY-INSPECTION, NOT BY MAGIC: it APPENDS. Run it once against the
4290-line file. Re-running doubles the band block.

Usage:  python3 gen/append_band_inputs.py [vectors/inputs.hex]
"""
import sys

# name, a, b, c -- see A6's worked table in spec/fp32_fma_ii1_iface.sv
SHAPES = [
    ("BAND",  0x00FFFFFF, 0x3F000000, 0),  # (1 - 2^-24)*2^-126: rounds up onto min normal
    ("LOW",   0x00FFFFFF, 0x3E800000, 0),  # half that: subnormal in every mode
    ("HIGH",  0x00FFFFFF, 0x3F800001, 0),  # normal in every mode
    ("FTZ",   0x00000001, 0x00000001, 0),  # 2^-298: tiny, inexact, rounds to zero
    ("EXACT", 0x00000001, 0x3F800000, 0),  # tiny and EXACT: no flags at all
]

def rows():
    for _, a, b, c in SHAPES:
        for sign in (0, 1):
            aa = a | (sign << 31)
            for r in range(5):                      # RNE RTZ RDN RUP RMM
                yield f"{((aa << 67) | (b << 35) | (c << 3) | r):025x}"

if __name__ == "__main__":
    out = sys.argv[1] if len(sys.argv) > 1 else "vectors/inputs.hex"
    n = 0
    with open(out, "a") as fh:
        for line in rows():
            fh.write(line + "\n")
            n += 1
    print(f"appended {n} band input tuples to {out}")
    print("NOTE: this file contains NO expected values. The anchor produces those.")
