#!/bin/bash
# TIER-B 5c: no mutant may be killed by the POLICY difference alone.
#
# The ten guarded defects of mutants.sv are re-derived on the policy-divergent
# implementation in dut2/ -- an independent design written from the spec, not a
# wrapper around the anchor. A verdict that differs from the same defect on the
# golden base means that mutant is perturbing latitude rather than contract.
#
# HOW THE RE-DERIVATION IS DONE. Every mutant here wraps an implementation and
# reads its guards from the PORTS only, so the re-derived defect is the same
# wrapper pointed at the other implementation. The wrapper cannot depend on
# either design's internals because it never sees them -- which is the whole
# reason guards were restricted to contract-level state.
#
# RULE 24: each "(clean)" line below is a CONTROL -- a conforming implementation
# must PASS. Each defect line is the positive half. A failing control aborts.
set -u
cd "$(dirname "$0")/../../../../.." || exit 1
REPO="$(pwd)"
T=domains/comp_arch/verification/v_ca05_id_queue
D=$T/dut
W=$(mktemp -d); trap 'rm -rf "$W"' EXIT
fails=0
OTHER=$(ls $D/*.sv | grep -v "/tag_tracker.sv$")

run_one() {   # $1 label, $2 expected, $3.. files
  local label="$1" expect="$2"; shift 2
  rm -rf "$W/obj"
  if ! verilator --binary --timing -j 4 -Wno-fatal --top-module tag_tracker_tb \
       -o run --Mdir "$W/obj" +incdir+"$REPO/refs/common_cells/include" "$@" "$T/tb/tag_tracker_spec_tb.sv" >"$W/b.log" 2>&1; then
    printf '  %-46s BUILD FAIL\n' "$label"; grep '%Error' "$W/b.log" | head -2
    fails=$((fails+1)); return
  fi
  out=$(timeout 400 "$W/obj/run" 2>&1)
  if echo "$out" | grep -qE '^RESULT: *PASS'; then got=PASS; else got=FAIL; fi
  if [ "$got" = "$expect" ]; then printf '  %-46s %-4s as expected\n' "$label" "$got"
  else printf '  %-46s %-4s BUT EXPECTED %s\n' "$label" "$got" "$expect"; fails=$((fails+1)); fi
}

ctl() {  # abort if a CONTROL failed -- it is not a result
  if [ "$fails" -ne "$1" ]; then
    echo "  RULE24: a CLEAN implementation was reported as failing. That is the"
    echo "          control, not a result -- the instrument has not reproduced a"
    echo "          known answer, so no verdict below it is a measurement."
    exit 2
  fi
}

echo "reference testbench vs the GOLDEN base and its ten defects"
r=$fails; run_one "golden (clean)" PASS $OTHER "$D/tag_tracker.sv"; ctl "$r"
# The mutant takes the top name and DELEGATES to the golden, so the golden has
# to be renamed out of the way. Passing both under one name is a duplicate
# definition: verilator picks one, and every mutant silently runs the golden.
python3 -c "
import re,sys
src=open('$D/tag_tracker.sv').read()
open(sys.argv[1],'w').write(re.sub(r'\bmodule tag_tracker\b','module tag_tracker_golden',src))
" "$W/golden_renamed.sv"
for M in $(grep -oE "^module tt_m[A-Za-z0-9_]+" "$T/mutants/mutants.sv" | awk '{print $2}'); do
  python3 -c "
import re,sys
src=open('$T/mutants/mutants.sv').read()
head=src[:src.index('\nmodule tt_')] if '\nmodule tt_' in src else ''
b=[x for x in re.split(r'(?=^module )', src, flags=re.M) if x.startswith('module $M ')][0]
b=b.replace('module $M ','module tag_tracker ',1)
b=re.sub(r'\btag_tracker(\s*)#\(', r'tag_tracker_golden\1#(', b)
b=re.sub(r'\btag_tracker(\s+)i_g\b', r'tag_tracker_golden\1i_g', b)
b=b.replace('module tag_tracker_golden ','module tag_tracker ',1)
open('$W/$M.sv','w').write(head+'\n'+b)"
  run_one "$M" FAIL $OTHER "$W/golden_renamed.sv" "$W/$M.sv"
done

echo
echo "reference testbench vs the POLICY-DIVERGENT base and the same ten defects"
sed 's/module tag_tracker_alt/module tag_tracker/' "$T/dut2/tag_tracker_alt.sv" > "$W/clean_policy.sv"
r=$fails; run_one "policy base (clean)" PASS $OTHER "$W/clean_policy.sv"; ctl "$r"
for f in "$T"/mutants/policy/*.sv; do
  run_one "$(basename "$f" .sv)" FAIL $OTHER "$T/dut2/tag_tracker_alt.sv" "$f"
done

echo
if [ "$fails" -eq 0 ]; then
  echo "OK: every defect is caught on BOTH bases, and both clean implementations"
  echo "    pass. No mutant is killed by the latitude choice."
else
  echo "MISMATCH in $fails case(s) -- a mutant is sensitive to the policy choice."
fi
exit "$fails"
