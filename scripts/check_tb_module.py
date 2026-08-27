#!/usr/bin/env python3
"""Assert that task.yaml's `tb_module:` names a module that actually exists.

    check_tb_module.py            # every task; exit 1 if any task is broken

WHY (F42)
---------
v_ca05's reference testbench declared `tag_tracker_spec_tb` while its task.yaml
required `tb_module: tag_tracker_tb`. The harness builds with `--top-module`
taken from task.yaml, so that file could never be the top -- it had never run
through the scored path at all. Every v_ca05 ceiling figure before that was
found came from an ad-hoc invocation.

The asymmetry is what made it invisible: SUBMISSIONS were harness-measured, and
the ceiling they were scored against was not, and both were printed in the same
table in the same units with nothing marking the difference.

This is a name that has to agree in two places with nothing checking that it
does -- the same shape as the prompt document being dropped from the task-text
hash when the file was renamed. A rename is the reliable way to reintroduce it,
so the agreement is asserted here rather than remembered.

WHAT IT CHECKS, per verification task:

  1. task.yaml declares `tb_module:` at all.
  2. Some file under tb/ declares a module of exactly that name.
  3. `golden_top:` likewise resolves to a module under dut/.

WHAT IT DOES NOT CHECK. That the module does what its name suggests, or that
the reference testbench is correct. A name agreeing in two places is a
necessary condition and nothing more.
"""
import os
import re
import sys as _sys, os as _os
_sys.path.insert(0, _os.path.dirname(_os.path.abspath(__file__)))
from _terminal_state import terminal_state
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MODULE_RE = re.compile(r"^[ \t]*module[ \t]+([A-Za-z_][A-Za-z0-9_]*)", re.M)


def declared_modules(directory):
    """module name -> the file that declares it, for every .sv under `directory`."""
    found = {}
    if not os.path.isdir(directory):
        return found
    for root, _dirs, files in os.walk(directory):
        for fn in sorted(files):
            if not fn.endswith((".sv", ".svh")):
                continue
            path = os.path.join(root, fn)
            try:
                src = open(path, encoding="utf-8", errors="replace").read()
            except OSError:
                continue
            for name in MODULE_RE.findall(src):
                found.setdefault(name, os.path.relpath(path, REPO))
    return found


def yaml_scalar(path, key):
    try:
        src = open(path, encoding="utf-8", errors="replace").read()
    except OSError:
        return None
    m = re.search(r"^[ \t]*%s:[ \t]*(\S+)" % re.escape(key), src, re.M)
    return m.group(1).split("#")[0].strip() if m else None


def check_task(task_dir):
    """Returns (list of problems, list of confirmations, terminal-or-None)."""
    problems, ok = [], []
    task_yaml = os.path.join(task_dir, "task.yaml")
    rel = os.path.relpath(task_dir, REPO)
    if not os.path.isfile(task_yaml):
        why = terminal_state(task_dir)
        if why:
            # REPORTED, NOT SKIPPED. A task that quietly loses its task.yaml must
            # still land in BROKEN; only a task that says so lands here.
            return ([], ok, f"{rel}: no task.yaml -- {why}")
        return ([f"{rel}: no task.yaml"], ok, None)

    for key, subdir, what in (("tb_module", "tb", "reference testbench"),
                              ("golden_top", "dut", "golden DUT")):
        want = yaml_scalar(task_yaml, key)
        if want is None:
            continue                      # not every task declares both
        have = declared_modules(os.path.join(task_dir, subdir))
        if want in have:
            ok.append(f"  {rel}: {key}={want} -> {have[want]}")
        else:
            near = [n for n in have if want.split("_")[0] in n]
            hint = ("; %s/ declares %s" % (subdir, ", ".join(sorted(near)[:4]))
                    if near else "; %s/ declares nothing matching" % subdir)
            problems.append(
                f"{rel}: {key} = {want!r} but no module of that name exists "
                f"under {subdir}/{hint}.\n"
                f"      The harness builds with --top-module {want}, so the "
                f"{what} cannot be the top and never runs through the scored "
                f"path (F42).")
    return problems, ok, None


def main():
    roots = []
    for domain in sorted(os.listdir(os.path.join(REPO, "domains"))):
        for kind in ("verification", "design"):
            base = os.path.join(REPO, "domains", domain, kind)
            if os.path.isdir(base):
                roots += [os.path.join(base, t) for t in sorted(os.listdir(base))]

    all_problems, all_ok, all_terminal = [], [], []
    for task_dir in roots:
        if not os.path.isdir(task_dir):
            continue
        p, o, term = check_task(task_dir)
        all_problems += p
        all_ok += o
        if term:
            all_terminal.append(term)

    for line in all_ok:
        print(line)
    if all_problems:
        print("\n  BROKEN -- a declared module name does not exist:\n")
        for p in all_problems:
            print(f"    {p}")
        if all_terminal:
            print("\n  TERMINAL -- declared, not missing:\n")
            for t in all_terminal:
                print(f"    {t}")
        print(f"\n  {len(all_ok)} ok, {len(all_problems)} broken, "
              f"{len(all_terminal)} terminal")
        return 1
    if all_terminal:
        print("\n  TERMINAL -- declared, not missing:\n")
        for t in all_terminal:
            print(f"    {t}")
    print(f"\n  {len(all_ok)} name(s) checked, all resolve; "
          f"{len(all_terminal)} terminal task(s) declared.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
