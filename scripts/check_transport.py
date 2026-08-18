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
import os
import sys
import unicodedata

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# ---------------------------------------------------------------------------
# INVISIBLE CODEPOINTS, in three groups. The distinction that matters is not
# "is it invisible" but "does anything downstream handle it".
#
#   HANDLED -- the runners strip it into a build copy before compiling, so a
#              file carrying it still scores correctly. Reported, never fatal.
#              U+00A0 only, and ONLY while the strip is actually present.
#   COVERED -- zero-width and bidi controls; already fatal here.
#   GAP     -- non-ASCII SPACE characters, BOM, soft hyphen, and the line and
#              paragraph separators. NOTHING strips these, they reach the
#              lexer, and they were not detected at all before this.
#
# The asymmetry is deliberate. Making U+00A0 fatal refuses files the pipeline
# runs correctly -- that was tried once and reverted as an over-correction.
# Leaving the rest undetected lets a paste artifact be scored as a model error.
HANDLED = {0x00A0}
COVERED = {0x200B, 0x200C, 0x200D, 0x2060} | set(range(0x202A, 0x202F))
GAP = ({0xFEFF, 0x00AD, 0x1680, 0x2028, 0x2029, 0x202F, 0x205F, 0x3000}
       | set(range(0x2000, 0x200B)))

RUNNER_STRIPPERS = ("scripts/sim_candidate.sh", "scripts/ppa_candidate.sh")


def runner_strip_set():
    r"""Codepoints the runners actually strip, read out of their sed commands.

    WHY THIS IS COMPUTED AND NOT ASSERTED. U+00A0 is non-fatal here purely
    BECAUSE sim_candidate.sh and ppa_candidate.sh normalise it onto a copy.
    That is a claim about OTHER FILES, and a comment making it would keep
    reading true after someone deleted the sed -- the exact shape of defect
    this project keeps finding. So the claim is re-derived on every run:
    delete the strip and U+00A0 becomes fatal here automatically, rather than
    being left silently unhandled behind a comment that says otherwise.

    Matches the \xNN\xNN escapes inside a sed s/// command and decodes them as
    UTF-8, which is how both runners spell it:

        LC_ALL=C sed $'s/\xc2\xa0/ /g' "$cand" > "$runfile"
    """
    stripped = set()
    pat = re.compile(r"""sed\s+\$'s/((?:\\x[0-9a-fA-F]{2})+)/""")
    for rel in RUNNER_STRIPPERS:
        try:
            src = open(os.path.join(REPO, rel), encoding="utf-8",
                       errors="replace").read()
        except OSError:
            continue
        for m in pat.finditer(src):
            hexes = re.findall(r"\\x([0-9a-fA-F]{2})", m.group(1))
            raw = bytes(int(h, 16) for h in hexes)
            try:
                for ch in raw.decode("utf-8"):
                    stripped.add(ord(ch))
            except UnicodeDecodeError:
                pass
    return stripped


def _name(cp):
    try:
        return unicodedata.name(chr(cp))
    except ValueError:
        return "<unnamed control>"


def codepoint_checks():
    """Per-codepoint checks, with anything in HANDLED demoted to FATAL wherever
    the runners turn out not to strip it after all."""
    unhandled = HANDLED - runner_strip_set()
    out = []
    for cp in sorted(HANDLED):
        if cp in unhandled:
            out.append((
                "U+%04X -- MARKED HANDLED BUT NO RUNNER STRIPS IT" % cp,
                re.compile(re.escape(chr(cp))),
                "the normalisation in %s is gone, so this now reaches the "
                "lexer; restore the strip or stop calling it handled"
                % " / ".join(RUNNER_STRIPPERS),
                True))
        else:
            out.append((
                "U+%04X %s (handled -- normalised on a copy)" % (cp, _name(cp)),
                re.compile(re.escape(chr(cp))),
                "chat interfaces substitute it; the runners normalise it",
                False))
    for cp in sorted(GAP):
        out.append((
            "U+%04X %s" % (cp, _name(cp)),
            re.compile(re.escape(chr(cp))),
            "a non-ASCII space or invisible that NOTHING normalises; it "
            "reaches the lexer and breaks tokenisation",
            True))
    return out


# (name, compiled pattern, why it cannot be authored)
CHECKS = codepoint_checks() + [
    ("injected fragment before a sized literal",
     # No trailing \b: the second real instance was `1 me1'b0`, where "me1"
     # has no word boundary after "me" and the original pattern missed it.
     # A digit followed by whitespace and a bare word is not valid in any
     # expression context here, so this does not need to be narrower.
     re.compile(r"[0-9]\s+me"),
     "a bare word where a literal belongs; no model emits `1 me`", True),
    ("doubled sized literal",
     re.compile(r"[0-9]+\s*'[bdh][0-9a-fA-FxzXZ_]+\s*'[bdh]"),
     "two literals fused with no operator between them", True),
    ("zero-width or bidi control character",
     re.compile("[" + "".join(chr(c) for c in sorted(COVERED)) + "]"),
     "invisible characters survive a paste and break tokenisation", True),
]


def scan(path):
    raw = open(path, encoding="utf-8", errors="replace").read()
    lines = raw.splitlines()
    hits = []
    for name, pat, why, fatal in CHECKS:
        for i, line in enumerate(lines, 1):
            for m in pat.finditer(line):
                hits.append((i, name, why, line.strip()[:90], m.group(0), fatal))
    return hits


def main():
    if len(sys.argv) != 2:
        print("usage: check_transport.py <file.sv>")
        return 2
    path = sys.argv[1]
    hits = scan(path)
    fatal_hits = [h for h in hits if h[5]]
    if not hits:
        print(f"  {path}: no known transport damage")
        return 0
    # Summarise per CLASS, not per occurrence: 13017 identical lines is not a
    # report, it is a wall. Count and first line number are what a reader needs.
    def summarise(rows):
        agg = {}
        for line_no, name, why, text, _frag, _f in rows:
            e = agg.setdefault(name, {"n": 0, "first": line_no, "why": why, "text": text})
            e["n"] += 1
            e["first"] = min(e["first"], line_no)
        return agg

    if not fatal_hits:
        print(f"  {path}: handled transport artefact(s), not fatal:")
        for name, e in sorted(summarise(hits).items()):
            print(f"    {name}: {e['n']} occurrence(s), first at line {e['first']}")
        return 0

    print(f"  TRANSPORT DAMAGE in {path} -- {len(fatal_hits)} site(s).")
    print("  This is a SETUP problem. Do not score this file; re-paste it.\n")
    for name, e in sorted(summarise(fatal_hits).items()):
        print(f"    {name}: {e['n']} occurrence(s), first at line {e['first']}")
        print(f"      {e['why']}")
        if e["text"]:
            print(f"      {e['text']}")
    return 1


if __name__ == "__main__":
    sys.exit(main())
