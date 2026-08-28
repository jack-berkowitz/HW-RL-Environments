#!/usr/bin/env python3
"""Capture the RESOLVED vendored-file closure per task, from Verilator itself.

WHY NOT GENERATE FROM sim_flags_verilator.txt. Those files are mostly `-y`
search PATHS, not file lists. d_nw03's entire vendored input is one directory;
"which anchors does this task consume" has no static answer there, and
common_cells/src alone holds 86 files. A lock generated from the flags would
either record whole directories -- 800+ files, mostly unconsumed, every edit to
an unused file going red -- or guess.

Verilator answers it exactly. `--MMD` writes a makefile dependency file naming
every source it actually read, so the closure is a BUILD PRODUCT rather than a
maintained claim. That is what the 6-of-36 drift was: a hand-maintained
declaration nobody could verify.

PER-TOP ATTRIBUTION, not a flat union. When an anchor moves the first question
is which closure it affects, and a union cannot answer it. A file read only by
the alt-reference is still an oracle input, so tops are unioned for the lock --
but the attribution is kept.

Emits JSON on stdout: {task: {top: [refs/... paths]}}.
"""
import glob
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def verilator():
    for c in (os.environ.get("SIM_VERILATOR_EXE"),
              os.path.expanduser("~/tools/oss-cad-suite/bin/verilator"),
              shutil.which("verilator")):
        if c and os.path.isx_ok(c) if False else (c and os.access(str(c), os.X_OK)):
            return c
    return None


def flags_for(task_dir):
    """The task's own verilator tokens, %REPO% expanded."""
    p = os.path.join(task_dir, "ref", "sim_flags_verilator.txt")
    if not os.path.isfile(p):
        return []
    out = []
    for line in open(p, encoding="utf-8", errors="replace"):
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        out.append(line.replace("%REPO%", REPO))
    return out


def _module_name(path):
    """The LAST module declared in the file, which is the top by convention here.

    Taken from the source, not the filename. Deriving it from the filename is
    the identify-by-filename defect this whole exercise is about, and it bit
    immediately: axis_switch_oq_alt_ref.sv declares module `axis_switch_oq`, so
    a filename-derived top produced "--top-module not found in design" and the
    alt-reference's closure came back as an error rather than a file list.
    """
    names = re.findall(r"^\s*module\s+(\w+)", open(path, errors="replace").read(), re.M)
    return names[-1] if names else os.path.basename(path)[:-3]


def tops_for(task_dir):
    """[(name, [files])] -- every top whose closure is an oracle input."""
    refs = sorted(glob.glob(os.path.join(task_dir, "ref", "*.sv")))
    tbs = sorted(glob.glob(os.path.join(task_dir, "tb", "*.sv")))
    out = []
    for tb in tbs:
        base = os.path.basename(tb)[:-3]
        # an alt-reference is a DUT, not a bench: give it its own closure
        # A REPLACEMENT vs A WRAPPER, and they need opposite treatment. An
        # alt-reference DECLARES the same module the reference does, so passing
        # both is a duplicate-module error. A control wrapper like
        # async_fifo_cdc_thru INSTANTIATES it and fails to elaborate without
        # it. Filename suffixes do not separate the two -- `_alt_ref` and
        # `_thru` look alike -- so the discriminator is whether this file
        # declares any module the reference also declares.
        mine = set(re.findall(r"^\s*module\s+(\w+)",
                              open(tb, errors="replace").read(), re.M))
        theirs = set()
        for r in refs:
            theirs |= set(re.findall(r"^\s*module\s+(\w+)",
                                     open(r, errors="replace").read(), re.M))
        replaces = bool(mine & theirs)
        out.append((_module_name(tb), [tb] if replaces else [tb] + refs))
    if not tbs:
        for r in refs:
            out.append((_module_name(r), [r]))
    return out


def capture(vexe, task_dir, top, files):
    d = tempfile.mkdtemp(prefix="dep_")
    try:
        cmd = [vexe, "--lint-only", "--MMD", "--Mdir", d,
               "-Wno-fatal", "-Wno-lint", "-Wno-style",
               "--top-module", top,
               f"+incdir+{os.path.join(REPO,'testbenches','common')}",
               f"+incdir+{os.path.dirname(files[0])}"]
        cmd += flags_for(task_dir) + files
        r = subprocess.run(cmd, capture_output=True, text=True, timeout=300)
        got = set()
        for f in glob.glob(os.path.join(d, "*.d")):
            for tok in re.split(r"[\s\\]+", open(f, errors="replace").read()):
                if "/refs/" in tok:
                    got.add("refs/" + tok.split("/refs/", 1)[1])
        if not got and r.returncode != 0:
            return None, (r.stderr or "")[-400:]
        return sorted(got), None
    except subprocess.TimeoutExpired:
        return None, "timeout"
    finally:
        shutil.rmtree(d, ignore_errors=True)


def main():
    vexe = verilator()
    if not vexe:
        print("no verilator on PATH", file=sys.stderr)
        return 2
    only = sys.argv[1:] or None
    out, errs = {}, {}
    for td in sorted(glob.glob(os.path.join(REPO, "domains", "*", "design", "d_*"))):
        task = os.path.basename(td)
        if only and not any(o in task for o in only):
            continue
        if not flags_for(td):
            continue
        for top, files in tops_for(td):
            got, err = capture(vexe, td, top, files)
            if got is None:
                errs.setdefault(task, {})[top] = err
            else:
                out.setdefault(task, {})[top] = got
    json.dump({"closures": out, "errors": errs}, sys.stdout, indent=1, sort_keys=True)
    return 0


if __name__ == "__main__":
    sys.exit(main())
