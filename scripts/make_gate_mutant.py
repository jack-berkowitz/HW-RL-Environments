#!/usr/bin/env python3
"""Generate the VALIDITY-GATE MUTANT for a task, mechanically, from its golden DUT.

    make_gate_mutant.py <golden.sv> <top_module> <out.sv>

WHAT THIS IS FOR
----------------
A verification submission must do more than pass the golden DUT. `null_tb.sv`
declares the required module, drives nothing, observes nothing, prints
`RESULT: PASS`, and the harness reported it as having "passed the validity
gate". So did an instantiate-and-ignore testbench. The gate was satisfiable
without discriminating, which means it was not a gate.

THE GATE IS BEHAVIOURAL, NOT STRUCTURAL. Every submission runs against two
DUTs and must produce DIFFERENT verdicts: PASS on the golden, FAIL on this
mutant. A submission that cannot tell them apart is INVALID.

**A DUT-instantiation check would not have worked.** Instantiation is a
source-level property, and any source-level or lint-style gate is satisfiable
by instantiating the DUT and ignoring it. Requiring a difference in OUTCOME
has no source-level counterfeit: to produce two verdicts you must observe
something that differs.

THE TRANSFORM: every output port is tied to `'1`.
------------------------------------------------
One rule, and it does both jobs the gate needs:

  * DATA outputs become all-ones, which is wrong on essentially any stimulus,
    so any submission that checks a single data output catches it.
  * HANDSHAKE outputs (valid / ready / last / grant) become ASSERTED, which
    keeps transactions FLOWING. This is deliberate. Tying handshakes low, or
    tying outputs to a value that stalls, makes submissions hang instead of
    reporting a mismatch, and a hang diagnoses nothing -- Agent 2 hit exactly
    that at v_nw02, where two known-bad DUTs were caught only by watchdog
    because send_w/issue_ar waited unbounded.

IT MUST ELABORATE AND SIMULATE CLEANLY. A syntactically broken DUT is useless
as a gate: it fails at elaboration, so EVERY submission fails it identically,
including the null testbench -- which would then show PASS-golden/FAIL-mutant
and satisfy the gate it was meant to fail. The mutant must be functionally
wrong, not structurally broken. The port list is copied VERBATIM from the
golden so the interface cannot drift.

IT IS DELIBERATELY MAXIMALLY OBVIOUS. The gate is a floor, not a scoring axis.
A subtle gate-mutant produces false INVALIDs on legitimate-but-narrow
testbenches, which is the expensive failure direction. It is also kept
separate from the per-task authoring control (Tier-B step 5b), which may
legitimately be subtle and is not this.

IT IS NOT A SCORED MUTANT. It never enters a kill-rate numerator or
denominator, and it is identified by explicit identifier, never by position,
name, or path.
"""
import os
import re
import sys

GATE_ID = "__gate_mutant__"      # the explicit identifier; never positional


def _split_top_level(s, sep=","):
    """Split on `sep` at bracket depth zero."""
    out, depth, cur = [], 0, []
    for ch in s:
        if ch in "([{":
            depth += 1
        elif ch in ")]}":
            depth -= 1
        if ch == sep and depth == 0:
            out.append("".join(cur)); cur = []
        else:
            cur.append(ch)
    out.append("".join(cur))
    return out


def _strip_comments(s):
    s = re.sub(r"/\*.*?\*/", " ", s, flags=re.S)
    return re.sub(r"//[^\n]*", " ", s)


def module_header(src, top):
    """The verbatim text from `module <top>` through the `;` closing its port
    list, plus the port-list body. Copied rather than reconstructed: a
    regenerated interface can drift from the golden's, and then the mutant
    fails to bind and every submission 'fails' it for the wrong reason."""
    m = re.search(r"\bmodule\s+%s\b" % re.escape(top), src)
    if not m:
        raise SystemExit(f"make_gate_mutant: no `module {top}` in the golden source")
    i, depth, seen_ports, start = m.start(), 0, False, m.start()
    while i < len(src):
        c = src[i]
        if c == "(":
            depth += 1; seen_ports = True
        elif c == ")":
            depth -= 1
        elif c == ";" and depth == 0 and seen_ports:
            return src[start:i + 1], _port_body(src[start:i + 1])
        i += 1
    raise SystemExit("make_gate_mutant: could not find the end of the port list")


def _port_body(header):
    """The last parenthesised group in the header is the port list; anything
    before it is the parameter list."""
    depth, groups, cur, start = 0, [], None, None
    for idx, ch in enumerate(header):
        if ch == "(":
            depth += 1
            if depth == 1:
                start = idx + 1
        elif ch == ")":
            if depth == 1:
                groups.append(header[start:idx])
            depth -= 1
    return groups[-1] if groups else ""


def output_ports(port_body):
    """Names of every output port.

    Direction PERSISTS across a comma in SystemVerilog: `output logic a, b`
    makes both outputs. Tracking the last-seen direction is required; matching
    the word `output` per item would silently miss `b` and leave it undriven,
    which elaborates fine and produces a mutant that is only half wrong."""
    names, direction = [], None
    for item in _split_top_level(_strip_comments(port_body)):
        item = item.strip()
        if not item:
            continue
        dm = re.match(r"\b(input|output|inout)\b", item)
        if dm:
            direction = dm.group(1)
        if direction != "output":
            continue
        # the port name is the last identifier not followed by a range
        ids = re.findall(r"\b([A-Za-z_][A-Za-z0-9_$]*)\b(?!\s*\[[^\]]*\]\s*[A-Za-z_])", item)
        ids = [x for x in ids
               if x not in ("input", "output", "inout", "logic", "wire", "reg",
                            "signed", "unsigned", "var", "bit", "byte", "int",
                            "integer", "shortint", "longint", "time", "real")]
        if ids:
            names.append(ids[-1])
    return names


def build(golden_path, top, out_path):
    src = _strip_comments(open(golden_path, encoding="utf-8", errors="replace").read())
    raw = open(golden_path, encoding="utf-8", errors="replace").read()
    header, body = module_header(raw, top)
    outs = output_ports(body)
    if not outs:
        raise SystemExit(f"make_gate_mutant: `{top}` declares no output ports; "
                         "a gate mutant cannot be built from it, and a task "
                         "whose DUT has no outputs cannot be gated this way")
    lines = [
        "// GENERATED by scripts/make_gate_mutant.py -- DO NOT EDIT, DO NOT SHIP.",
        "//",
        "// The VALIDITY-GATE MUTANT. Every output of the golden is tied to '1.",
        "// Data outputs become all-ones (wrong on any stimulus); handshake",
        "// outputs become asserted, which keeps transactions FLOWING so a",
        "// submission reports a mismatch instead of hanging. A hang diagnoses",
        "// nothing.",
        "//",
        "// A submission must FAIL this and PASS the golden. Producing the same",
        "// verdict on both means it did not discriminate, and it is INVALID.",
        "// This mutant is NOT part of the scored mutant set and never enters a",
        "// kill rate.",
        "//",
        f"// Interface copied verbatim from {os.path.relpath(golden_path)}.",
        header,
    ]
    for o in outs:
        lines.append(f"  assign {o} = '1;")
    lines.append("endmodule")
    open(out_path, "w", encoding="utf-8").write("\n".join(lines) + "\n")
    return outs


def main():
    if len(sys.argv) != 4:
        print(__doc__.strip().splitlines()[0])
        print("usage: make_gate_mutant.py <golden.sv> <top_module> <out.sv>")
        return 2
    golden, top, out = sys.argv[1:4]
    outs = build(golden, top, out)
    print(f"  gate mutant for `{top}`: {len(outs)} output(s) tied to '1 -> {out}")
    for o in outs:
        print(f"      {o}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
