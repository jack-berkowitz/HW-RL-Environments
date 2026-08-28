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
T=domains/networking/verification/v_nw03_axis_arb_mux
D=$T/dut
W=$(mktemp -d); trap 'rm -rf "$W"' EXIT
fails=0

# ---------------------------------------------------------------------------
# THE TWO HALVES MUST BE THE SAME SET, not merely the same size.
#
# This runner globs policy/*.sv and grades whatever it finds, so a missing
# re-derivation leaves every row reading "as expected" and the summary still
# claiming every defect is covered. A short set is indistinguishable from a
# complete one in the output. On v_ca03 that produced a universal that was false
# for exactly one mutant, and on v_ca07 it once turned a reported 22/22 into a
# real 21/22.
#
# COMPARING IDS, NOT COUNTS. A count agrees whenever both sides are N with
# different membership -- it sees a shortfall, never a substitution, and names
# neither the missing id nor the direction. Demonstrated: renaming one policy
# file to a bogus id leaves the counts equal and the sets unequal.
#
# BEFORE ANY BUILD, so a mismatch costs a second rather than a full compile pass.
anchor_ids=$(grep -oE "^module fm_m[0-9]+_[a-z0-9_]+" "$T/mutants/mutants.sv" \
             | sed 's/^module fm_m/fm_/' | sort)
policy_ids=$(ls "$T"/mutants/policy/*.sv 2>/dev/null | xargs -n1 basename \
             | sed 's/\.sv$//; s/^fm_p/fm_/' | sort)
if [ "$anchor_ids" != "$policy_ids" ]; then
  echo "  RULE24: the anchor and policy halves are not the same SET."
  comm -23 <(printf '%s\n' "$anchor_ids") <(printf '%s\n' "$policy_ids") \
    | sed 's/^/    anchor only (no policy re-derivation): /'
  comm -13 <(printf '%s\n' "$anchor_ids") <(printf '%s\n' "$policy_ids") \
    | sed 's/^/    policy only (no anchor mutant): /'
  echo "  Add the missing re-derivation. Do NOT make the counts agree by"
  echo "  deleting the other side -- the anchor half is what scoring uses."
  exit 2
fi
OTHER=$(ls $D/*.sv | grep -v "/frame_arb_mux.sv$")

run_one() {   # $1 label, $2 expected, $3.. files
  local label="$1" expect="$2"; shift 2
  rm -rf "$W/obj"
  if ! verilator --binary --timing -j 4 -Wno-fatal --top-module frame_arb_mux_tb \
       -o run --Mdir "$W/obj"  "$@" "$T/tb/frame_arb_mux_spec_tb.sv" >"$W/b.log" 2>&1; then
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

echo "reference testbench vs the GOLDEN base and its $(printf '%s\n' "$anchor_ids" | wc -l | tr -d ' ') defects"
r=$fails; run_one "golden (clean)" PASS $OTHER "$D/frame_arb_mux.sv"; ctl "$r"
# The mutant takes the top name and DELEGATES to the golden, so the golden has
# to be renamed out of the way. Passing both under one name is a duplicate
# definition: verilator picks one, and every mutant silently runs the golden.
python3 -c "
import re,sys
src=open('$D/frame_arb_mux.sv').read()
open(sys.argv[1],'w').write(re.sub(r'\bmodule frame_arb_mux\b','module frame_arb_mux_golden',src))
" "$W/golden_renamed.sv"
for M in $(grep -oE "^module fm_m[A-Za-z0-9_]+" "$T/mutants/mutants.sv" | awk '{print $2}'); do
  python3 -c "
import re,sys
src=open('$T/mutants/mutants.sv').read()
head=src[:src.index('\nmodule fm_')] if '\nmodule fm_' in src else ''
b=[x for x in re.split(r'(?=^module )', src, flags=re.M) if x.startswith('module $M ')][0]
b=b.replace('module $M ','module frame_arb_mux ',1)
b=re.sub(r'\bframe_arb_mux(\s*)#\(', r'frame_arb_mux_golden\1#(', b)
b=re.sub(r'\bframe_arb_mux(\s+)i_g\b', r'frame_arb_mux_golden\1i_g', b)
b=b.replace('module frame_arb_mux_golden ','module frame_arb_mux ',1)
open('$W/$M.sv','w').write(head+'\n'+b)"
  run_one "$M" FAIL $OTHER "$W/golden_renamed.sv" "$W/$M.sv"
done

echo
echo "reference testbench vs the POLICY-DIVERGENT base and the same $(printf '%s\n' "$anchor_ids" | wc -l | tr -d ' ') defects"
sed 's/module frame_arb_mux_alt/module frame_arb_mux/' "$T/dut2/frame_arb_mux_alt.sv" > "$W/clean_policy.sv"
r=$fails; run_one "policy base (clean)" PASS $OTHER "$W/clean_policy.sv"; ctl "$r"
for f in "$T"/mutants/policy/*.sv; do
  run_one "$(basename "$f" .sv)" FAIL $OTHER "$T/dut2/frame_arb_mux_alt.sv" "$f"
done

echo
if [ "$fails" -eq 0 ]; then
  echo "OK: every defect is caught on BOTH bases, and both clean implementations"
  echo "    pass. No mutant is killed by the latitude choice."
else
  echo "MISMATCH in $fails case(s) -- a mutant is sensitive to the policy choice."
fi
exit "$fails"
