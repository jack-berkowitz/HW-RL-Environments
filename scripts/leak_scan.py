#!/usr/bin/env python3
"""Does a submission REFERENCE the harness, or merely mention it?

THE DEFECT THIS REPLACES. sim_candidate.sh grepped the RAW file for six leak
tokens, so `d_nw01/controls/nc_i_overbuffered_r.sv` was rejected outright for a
COMMENT reading "Grepping tb/axi4_xbar_tb.sv for an occupancy counter finds
nothing" -- prose explaining why the control matters, matched as though it were a
hierarchical reference into the testbench.

A scanner that cannot tell code from commentary refuses a file for what it SAYS
rather than what it DOES. Same class as the slang exemption enumerating
directories instead of stating the property.

WHAT IS AND IS NOT A LEAK. A submission reaching into the testbench hierarchy --
`<dut>_tb.signal` -- can see what it is not allowed to see. A submission naming
the testbench in a comment can see nothing. Only the first is a leak, and the
scanner has to be able to tell them apart before its verdict means anything.

THIS DOES NOT SILENTLY FORGIVE. A token found only in commentary is REPORTED, as
COMMENT rather than CODE. The caller does not reject on it, but nothing is
hidden: a submission that talks about the testbench is worth a human glance even
though it is not a rule violation, and a scanner that says nothing teaches the
reader there was nothing to say.

STRINGS ARE BLANKED BEFORE COMMENTS, reusing check_transport.code_only, because
the reverse order is a bypass: `string s = "x//"; wire y = t_tb.z;` has a `//`
inside a literal, and a stripper that honours it as a comment start would erase
the real hierarchical reference that follows on the same line.

  usage:  leak_scan.py <file>
  prints: CODE <token> | COMMENT <token> | CLEAN     exit 1 on CODE
"""
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from check_transport import code_only          # noqa: E402

# TWO TOKEN CLASSES, BECAUSE A STRING LITERAL IS SAFE FOR ONE AND IS THE ATTACK
# FOR THE OTHER. Blanking strings for both is a REGRESSION, and this file shipped
# it for about a minute:
#
#   $display("TEST_RESULT: PASS");
#
# is exactly how a verdict is forged, and it lives INSIDE a string. A scanner
# that blanks strings before looking for TEST_RESULT cannot see the one form the
# token actually appears in. The raw grep this replaces caught that; a
# comment-aware rewrite that forgot the distinction would have opened it.
#
# By contrast `axi4_xbar_tb.r_count` inside a string is inert -- a string cannot
# be dereferenced -- so for hierarchical and identifier tokens the string really
# is commentary.
FORGEABLE = ["TEST_RESULT"]                      # dangerous in code AND strings
REFERENCE = ["_tb.", "_tb ", "golden_mem", "mem_stub", "reference_solutions"]
LEAKS = FORGEABLE + REFERENCE                    # ported from runner/extract.py


def _no_block(text):
    return re.sub(r"/\*.*?\*/", " ", text, flags=re.S)


def strip(src):
    """Code with string literals, // comments and /* */ blocks removed."""
    lines = [code_only(l) for l in src.splitlines()]
    return _no_block("\n".join(lines))


def strip_comments_only(src):
    """Comments removed, STRING LITERALS KEPT -- for the forgeable tokens."""
    out = []
    for line in src.splitlines():
        i, n, in_str = 0, len(line), False
        buf = []
        while i < n:
            c = line[i]
            if not in_str and c == "/" and i + 1 < n and line[i + 1] == "/":
                break
            if c == '"' and (i == 0 or line[i - 1] != "\\"):
                in_str = not in_str
            buf.append(c)
            i += 1
        out.append("".join(buf))
    return _no_block("\n".join(out))


def main(argv):
    if len(argv) < 2:
        print(__doc__.strip().splitlines()[0])
        return 2
    try:
        src = open(argv[1], errors="replace").read()
    except OSError as e:
        print(f"NO CONCLUSION: cannot read {argv[1]}: {e}")
        return 2
    code = strip(src)                       # strings gone: reference tokens
    live = strip_comments_only(src)         # strings kept: forgeable tokens
    for t in FORGEABLE:
        if t in live:
            print(f"CODE\t{t}")
            return 1
    for t in REFERENCE:
        if t in code:
            print(f"CODE\t{t}")
            return 1
    for t in LEAKS:
        if t in src:
            print(f"COMMENT\t{t}")
            return 0
    print("CLEAN")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
