#!/usr/bin/env python3
"""Does each design spec's stated pin equal the rule applied to its own sweep?

THE PIN IS THE ONLY THING MAKING PPA NUMBERS COMPARABLE across submissions to a
task: every candidate is built at one period, stated in the spec BEFORE
solicitation, so nobody can buy area by relaxing the clock. The pin rule is

    pinned_period_ns = ceil(1.5 * converged_period_ns / 0.25) * 0.25

WHY THIS EXISTS. The pin lives in the spec as prose. The converged period lives
in fmax_results/<task>_fmax.json. Nothing connected the two, so a mistyped pin
-- a halved one, a transposed digit -- would have been invisible: the build
would run, close timing, and produce a number against the wrong question. The PC
agent checked d_ca01 and d_ca03 by hand before committing hours to them, which
is the right instinct and the wrong place for it to live.

find_fmax.py writes `pinned_period_ns` into new sweeps, but ONE of thirty-one
fmax files carries it -- the rest predate the field -- and nothing in scripts/
reads it. A field written by one tool and consulted by none is not provenance;
this check consults the spec, which is what actually binds.

IT DOES NOT INVENT A PIN. Where the spec states none, or no sweep exists, it
reports NO CONCLUSION and exits non-zero. "The pin is right" and "there is
nothing to check" must not print the same.

  usage:  check_pin.py [task ...]        default: every design task
"""
import glob, json, math, os, re, sys

RULE = "ceil(1.5 x converged / 0.25) * 0.25"
PIN_RE = re.compile(r"pinned period is\s+([0-9]+(?:\.[0-9]+)?)\s*ns", re.I)


def stated_pin(task_dir):
    for p in sorted(glob.glob(os.path.join(task_dir, "spec", "*.sv"))):
        m = PIN_RE.search(open(p, errors="replace").read())
        if m:
            return float(m.group(1)), os.path.basename(p)
    return None, None


def prompt_pin(task_dir):
    """The pin as the PROMPT states it, and whether the prompt says NOT YET SET.

    THE SPEC IS NOT THE PROMPT. probe/PASTE.md INLINES the spec rather than
    referencing it, so writing a pin into spec/ leaves the document the model is
    actually handed still saying whatever it said before. d_ai01's prompt read
    "THE PINNED PERIOD FOR THIS TASK IS NOT YET SET" for as long as its spec
    carried 16.75, and a re-solicitation in that window would have produced three
    candidates answering a prompt that CONTRADICTED the spec it was generated
    from -- worse than a stale prompt, because a stale one is at least
    self-consistent.

    Caught by AGENT-DESIGN-43a92055 while landing the pin I had asked them for:
    my own reasoning was that the pin must be in the prompt before solicitation,
    and I had checked only the spec.
    """
    for p in sorted(glob.glob(os.path.join(task_dir, "probe", "*.md"))):
        txt = open(p, errors="replace").read()
        m = PIN_RE.search(txt)
        if m:
            return float(m.group(1)), os.path.basename(p), False
        if "NOT YET SET" in txt.upper():
            return None, os.path.basename(p), True
    return None, None, False


def converged(task):
    f = os.path.join("fmax_results", f"{task}_fmax.json")
    if not os.path.exists(f):
        return None, None
    try:
        d = json.load(open(f))
    except Exception:
        return None, os.path.basename(f)
    return d.get("converged_period_ns"), os.path.basename(f)


def apply_rule(c):
    return round(math.ceil(c * 1.5 / 0.25) * 0.25, 4)


def main(argv):
    want = [a for a in argv[1:] if not a.startswith("-")]
    dirs = sorted(glob.glob("domains/*/design/d_*"))
    print(f"pin rule: {RULE}\n")
    print(f"{'task':<28} {'spec pin':>9} {'converged':>10} {'rule gives':>11}  verdict")
    bad = noconc = 0
    for d in dirs:
        t = os.path.basename(d)
        short = "_".join(t.split("_")[:2])
        if want and t not in want and short not in want:
            continue
        pin, specf = stated_pin(d)
        conv, fmaxf = converged(short)
        # SPEC-VS-PROMPT AGREEMENT DOES NOT DEPEND ON A SWEEP, so it is checked
        # BEFORE the sweep-availability branches below. My first version put it
        # after them, where a task with no fmax.json returned NO CONCLUSION and
        # never reached it -- and d_ai01, the task the check was written for, was
        # exactly that task. The branch could not fire on its own founding case.
        pnote = ""
        if pin is not None:
            ppin, pfile, notset = prompt_pin(d)
            if notset:
                pnote = f"   *** PROMPT ({pfile}) STILL SAYS 'NOT YET SET' ***"
            elif ppin is None:
                pnote = "   *** PROMPT STATES NO PIN -- the model is not told it ***"
            elif abs(ppin - pin) > 1e-9:
                pnote = f"   *** PROMPT SAYS {ppin:g}, SPEC SAYS {pin:g} ***"
            if pnote:
                bad += 1
        if pin is None and conv is None:
            print(f"  {t:<26} {'-':>9} {'-':>10} {'-':>11}  NO CONCLUSION -- no stated pin and no sweep")
            noconc += 1; continue
        if pin is None:
            print(f"  {t:<26} {'-':>9} {conv:>10} {'-':>11}  NO CONCLUSION -- spec states no pin")
            noconc += 1; continue
        if conv is None:
            print(f"  {t:<26} {pin:>9} {'-':>10} {'-':>11}  NO CONCLUSION -- no {short}_fmax.json to check it against{pnote}")
            noconc += 1; continue
        want_pin = apply_rule(conv)
        ok = abs(want_pin - pin) < 1e-9
        if not ok:
            bad += 1
        print(f"  {t:<26} {pin:>9} {conv:>10} {want_pin:>11}  "
              f"{'ok' if ok else '*** MISMATCH ***'}{pnote}")
    print(f"\n{bad} mismatch(es), {noconc} NO CONCLUSION.")
    if noconc:
        print("A task with no conclusion was NOT checked. That is not a pass.")
    return 1 if bad else (2 if noconc else 0)


if __name__ == "__main__":
    sys.exit(main(sys.argv))
