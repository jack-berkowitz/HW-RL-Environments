#!/usr/bin/env python3
"""Detect transport damage in a pasted submission, before it is scored.

    check_transport.py <file.sv>        # exit 1 if damage is found

WHY
---
A submission that arrives damaged is a SETUP problem, not a result. Scoring it
attributes a paste artifact to the model, which is the same misattribution this
project keeps finding elsewhere: a harness limitation reported as a property of
the candidate.

Two classes seen so far, both real:

  1. U+00A0 (non-breaking space) substituted for ordinary spaces. Verilator
     reports `unexpected $end` and slang reports a UTF-8 complaint, so the
     answer looks broken when only the transport was. Already normalised on a
     copy by the runners; detected here so it is NAMED rather than silently
     repaired.

  2. Injected literal text. Two `gemini` submissions each carried exactly one
     instance:

         sum_is_zero = 1 me;                 (should be 1'b0)
         if (full_o !== 1 me1'b0) ...        (should be 1'b0)

     One per file, in otherwise clean 200+ line submissions, and in the second
     the correct literal survives immediately after the injected fragment --
     so it is an INSERTION into the character stream, not a model error. No
     model writes `1 me`.

WHAT THIS DOES NOT DO
---------------------
It cannot prove a file is undamaged. It recognises the damage classes already
observed, and a new class will be invisible until it is added here -- the same
stated limitation as the rule set. A clean run means "none of the known damage",
never "this is what the model produced".
"""
import re
import sys

# (name, compiled pattern, why it cannot be authored)
CHECKS = [
    ("U+00A0 non-breaking space",
     re.compile(" "),
     "chat interfaces substitute it for an ordinary space"),
    ("injected fragment before a sized literal",
     # No trailing \b: the second real instance was `1 me1'b0`, where "me1"
     # has no word boundary after "me" and the original pattern missed it.
     # A digit followed by whitespace and a bare word is not valid in any
     # expression context here, so this does not need to be narrower.
     re.compile(r"[0-9]\s+me"),
     "a bare word where a literal belongs; no model emits `1 me`"),
    ("doubled sized literal",
     re.compile(r"[0-9]+\s*'[bdh][0-9a-fA-FxzXZ_]+\s*'[bdh]"),
     "two literals fused with no operator between them"),
    ("zero-width or bidi control character",
     re.compile("[​‌‍⁠‪-‮]"),
     "invisible characters survive a paste and break tokenisation"),
]


def scan(path):
    raw = open(path, encoding="utf-8", errors="replace").read()
    lines = raw.splitlines()
    hits = []
    for name, pat, why in CHECKS:
        for i, line in enumerate(lines, 1):
            for m in pat.finditer(line):
                hits.append((i, name, why, line.strip()[:90], m.group(0)))
    return hits


def main():
    if len(sys.argv) != 2:
        print("usage: check_transport.py <file.sv>")
        return 2
    path = sys.argv[1]
    hits = scan(path)
    if not hits:
        print(f"  {path}: no known transport damage")
        return 0

    print(f"  TRANSPORT DAMAGE in {path} -- {len(hits)} site(s).")
    print("  This is a SETUP problem. Do not score this file; re-paste it.\n")
    seen = set()
    for line_no, name, why, text, frag in hits:
        key = (line_no, name)
        if key in seen:
            continue
        seen.add(key)
        print(f"    line {line_no}: {name}")
        print(f"      matched {frag!r} -- {why}")
        print(f"      {text}")
    return 1


if __name__ == "__main__":
    sys.exit(main())
