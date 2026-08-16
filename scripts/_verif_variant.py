#!/usr/bin/env python3
"""Build the DUT variant a verification submission is compiled against.

Helper for sim_verification.sh. Separate file rather than an inline heredoc
because the shell script already uses one, and nesting them silently truncates
the outer block at the inner terminator.

    _verif_variant.py <workdir> <golden|tt_cN_...> <conformant.sv> <top>

Writes <workdir>/variant.sv and <workdir>/extra.sv.

WHY THE RENAMING IS HERE AND NOT IN sed
---------------------------------------
BSD sed (macOS) does not support \\b. `sed "s/\\btag_tracker\\b/x/"` substitutes
NOTHING and exits 0, so the file passes through unchanged. That failure is
invisible in this harness: the build succeeds, the run passes, and every
perturbation row silently runs the GOLDEN DUT instead of the perturbation.

It was caught by a negative control that relies on unpromised behaviour and was
not rejected. A cruder control -- a testbench that fails everything -- had
already "passed" and made the harness look validated. Two controls, and only the
specific one had any power.
"""
import os
import re
import sys


def main():
    if len(sys.argv) != 5:
        sys.exit(__doc__.strip().splitlines()[0])
    work, which, conf, top = sys.argv[1:5]

    golden = open(os.path.join(work, "golden_renamed.sv"), encoding="utf-8").read()
    variant = os.path.join(work, "variant.sv")
    extra = os.path.join(work, "extra.sv")

    if which == "golden":
        # Present the golden under its own name; no wrapper needed.
        out = re.sub(r"\bmodule %s_golden\b" % re.escape(top),
                     "module %s" % top, golden)
        open(variant, "w", encoding="utf-8").write(out)
        open(extra, "w", encoding="utf-8").write("")
        return

    # The golden keeps its renamed identity; the perturbation takes `top`.
    open(variant, "w", encoding="utf-8").write(golden)

    txt = open(conf, encoding="utf-8").read()
    blocks = re.split(r"(?=^module )", txt, flags=re.M)
    head = "".join(b for b in blocks if not b.startswith("module "))
    body = next((b for b in blocks
                 if re.match(r"module %s\b" % re.escape(which), b)), None)
    if body is None:
        sys.exit("no module %s in %s" % (which, conf))

    # ORDER MATTERS. Rewrite the inner instantiation FIRST, then the module
    # declaration. Doing it the other way renames the declaration to `top` and
    # the instantiation rewrite then catches the declaration too, producing a
    # module named <top>_golden that collides with the real golden -- which is
    # a second silent way for every perturbation row to run the wrong DUT.
    body = re.sub(r"\b%s(\s*)#\(" % re.escape(top),
                  r"%s_golden\1#(" % top, body)
    body = re.sub(r"\bmodule %s\b" % re.escape(which), "module %s" % top, body)

    open(extra, "w", encoding="utf-8").write(head + body)


if __name__ == "__main__":
    main()
