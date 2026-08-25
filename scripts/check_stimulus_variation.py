#!/usr/bin/env python3
"""Count DISTINCT VALUES each DUT input takes over a run, from a VCD.

RULE 34 BUILD STEP. Every input a contract gives meaning to must take more than
one value over the scored sequence. An input that never changes has not been
tested however continuously it was assigned, so "was it driven" is the wrong
question -- d_ca03's asid_i was assigned every cycle at zero while the whole
ASID and global-page clause went unexercised.

  usage:  check_stimulus_variation.py <spec_iface.sv> <dump.vcd> <dut_instance>

  to produce the dump, add to the testbench (guarded, so normal runs are
  unaffected) and build with --trace:

      initial if ($test$plusargs("vcd")) begin
        $dumpfile("dump.vcd");
        $dumpvars(0, <tb_module>);
      end

A FROZEN INPUT IS NOT AUTOMATICALLY A DEFECT. It is a defect when no other
varying input can reach the clause it governs. d_nw01 holds addr_map constant
and that is correct -- the addresses vary and reach outside the map, so the
decode-error clause is exercised anyway. d_ca03 held pmpcfg_i constant and
nothing else could reach A8. Read the clause before calling it.

A constant that IS legitimate must be declared with the clause permitting it,
because nothing in the source distinguishes a deliberate constant from an
overlooked one.

VALIDATED against d_ca03, where an independent in-testbench monitor reports the
same three frozen inputs out of 24. That agreement is the reason this is
trusted: an earlier static scanner over source text was wrong four times, every
time under-reporting, and this tool was wrong once -- a VCD aliases signals
sharing a value to ONE identifier code, and keeping one name per code hid 7 of
8 ports behind the testbench-side names they were bound to.

WHAT IT DOES NOT DO. A signal absent from the dump yields NO CONCLUSION and is
reported as such rather than counted as frozen. Verilator can optimise a signal
away entirely, so absence means unknown.


Generic across tasks: it reads the module's input port names out of the spec and
looks them up in the DUT scope of the dump, so nothing per-task has to be written.
It observes ACTUAL VALUE CHANGES rather than source text, which is the half a
static scan cannot do -- that scanner was wrong four times, every time by reading
source and reporting on behaviour.

Usage: vcdvary.py <spec_iface.sv> <dump.vcd> <dut_scope_name>
"""
import os, re, sys, collections

spec, vcd, dut = sys.argv[1], sys.argv[2], sys.argv[3]

# ---- WHERE THE PORT LIST LIVES IS A PROPERTY OF THE TASK, NOT OF THIS TOOL ----
#
# This read spec/*_iface.sv and nothing else. v_ca05_id_queue has no iface file:
# its port map lives in probe/PASTE.md, which is CORRECT for a verification task
# -- the hash covers PASTE.md and it is the document a submitter is actually
# shown -- and was invisible here. The sweep reported v_ca05 SKIPPED every time
# it ran, and a reader scanning the results cannot tell SKIPPED from "measured,
# nothing frozen". Those are opposite conclusions: one says the inputs vary, the
# other says nobody looked.
#
# A task whose port map lives where the submitter sees it is not doing anything
# wrong, so the instrument learns to read it rather than the task growing a file
# to satisfy the instrument -- which would also move its task_text_hash and
# invalidate a solicitation to fix a tooling gap.
#
# It NAMES the file it took the ports from, on every run. A fallback that
# substitutes silently has answered a different question than the one asked.
def _module_header(path):
    try:
        t = open(path, errors="replace").read()
    except OSError:
        return None
    return re.search(r"^module\s+\w+.*?\((.*?)^\);", t, re.S | re.M)


m = _module_header(spec)
src = spec
if not m:
    # spec/<x>_iface.sv -> <task>/probe/PASTE.md
    task_dir = os.path.dirname(os.path.dirname(os.path.abspath(spec)))
    for cand in (os.path.join(task_dir, "probe", "PASTE.md"),
                 os.path.join(task_dir, "probe", "BLIND_TB_TASK.md")):
        m = _module_header(cand)
        if m:
            src = cand
            break
if not m:
    print(f"NOT MEASURABLE: no module header in {spec}", file=sys.stderr)
    print("  and none in the task's probe/PASTE.md or probe/BLIND_TB_TASK.md.",
          file=sys.stderr)
    print("  NOTHING WAS READ. This is not the same answer as 'no input is",
          file=sys.stderr)
    print("  frozen' -- report it as NOT MEASURABLE, never as a clean result.",
          file=sys.stderr)
    sys.exit(3)
if src != spec:
    print(f"note: port list read from {os.path.relpath(src)} "
          f"-- {os.path.relpath(spec)} declares no module header.")
ports, cur = [], None
for line in m.group(1).splitlines():
    line = re.sub(r"//.*", "", line)
    d = re.match(r"\s*(input|output|inout)\b", line)
    if d:
        cur = d.group(1)
    if cur == "input":
        for nm in re.findall(r"(\w+)\s*(?:,|$)", line):
            if nm not in ("input", "output", "inout", "logic", "wire", "reg",
                          "signed", "unsigned"):
                ports.append(nm)
ports = [p for p in dict.fromkeys(ports)]

# ---- VCD: id -> (scope, name); then distinct values per id ------------------
# ids maps an identifier code to EVERY (scope, name) bound to it. A VCD aliases
# signals that carry the same value to ONE code, so a port and the testbench
# signal wired to it share a code -- and a dict keeping one name per code silently
# dropped all but the last, reporting 1 of 8 ports "not found in the dump".
ids, scope, seen = collections.defaultdict(list), [], collections.defaultdict(set)
with open(vcd, errors="replace") as f:
    in_defs = True
    for line in f:
        line = line.strip()
        if in_defs:
            if line.startswith("$scope"):
                scope.append(line.split()[2])
            elif line.startswith("$upscope"):
                scope and scope.pop()
            elif line.startswith("$var"):
                p = line.split()
                ids[p[3]].append((".".join(scope), p[4]))
            elif line.startswith("$enddefinitions"):
                in_defs = False
            continue
        if not line or line[0] in "#$":
            continue
        if line[0] in "01xzXZ":
            vid, val = line[1:], line[0]
        elif line[0] in "bBrR":
            parts = line.split()
            if len(parts) < 2:
                continue
            val, vid = parts[0], parts[1]
        else:
            continue
        if vid in ids:
            seen[vid].add(val)

# ---- report -----------------------------------------------------------------
# Prefer a scope named by the caller; fall back to ANY scope if that name is not
# present. Instantiation names vary and a multi-line instantiation defeats a
# regex, so requiring the caller to know the instance name loses tasks silently.
def collect(scope_filter):
    out = {}
    for vid, binds in ids.items():
        for sc, nm in binds:
            if nm in ports and scope_filter(sc):
                out.setdefault(nm, set()).update(seen.get(vid, set()))
    return out

byname = collect(lambda sc: sc.endswith(dut) or dut in sc.split("."))
if not byname or len(byname) < len(ports) // 2:
    byname = collect(lambda sc: True)
    print(f"  (no scope named '{dut}' carried the ports; matched across all scopes)")

missing = [p for p in ports if p not in byname]
frozen  = sorted(n for n, v in byname.items() if len(v) <= 1)
varied  = sorted(n for n, v in byname.items() if len(v) > 1)

print(f"  inputs in spec: {len(ports)}   found in dump: {len(byname)}")
if missing:
    print(f"  NOT FOUND in the dump (cannot conclude): {', '.join(missing)}")
print(f"  varied ({len(varied)}): {', '.join(varied) if varied else '-'}")
if frozen:
    print(f"  FROZEN ({len(frozen)}):")
    for n in frozen:
        print(f"      {n}   = {next(iter(byname[n])) if byname[n] else '<never written>'}")
else:
    print("  FROZEN: none")
