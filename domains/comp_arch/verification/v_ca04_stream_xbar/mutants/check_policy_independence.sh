#!/bin/bash
# TIER-B 5c: no mutant may be killed by the POLICY difference alone.
#
# The eight defects of mutants.sv are re-derived on the policy-divergent
# implementation (mutants/policy/), which rotates DOWNWARD and REGISTERS its
# outputs -- the opposite choice on both named latitude clauses. A verdict that
# differs from the same defect on the golden base means that mutant is
# perturbing latitude rather than contract.
set -u
cd "$(dirname "$0")/../../../../.." || exit 1
T=domains/comp_arch/verification/v_ca04_stream_xbar
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
anchor_ids=$(grep -oE "^module xb_m[0-9]+_[a-z0-9_]+" "$T/mutants/mutants.sv" \
             | sed 's/^module xb_m/xb_/' | sort)
policy_ids=$(ls "$T"/mutants/policy/*.sv 2>/dev/null | xargs -n1 basename \
             | sed 's/\.sv$//; s/^xb_p/xb_/' | sort)
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
BASE=("$D/aa_asserts_off.sv" "$D/cf_math_pkg.sv" "$D/lzc.sv" "$D/rr_arb_tree.sv"
      "$D/spill_register.sv" "$D/spill_register_flushable.sv" "$D/stream_demux.sv"
      "$D/stream_xbar.sv")
# four of the ten defects live INSIDE the arbiter, so their renamed copies have
# to be in the compile too
for f in "$D"/rr_arb_tree_m*.sv "$D"/stream_xbar_m*.sv; do
  [ -e "$f" ] && BASE+=("$f")
done

run_one() {   # $1 label, $2 expected, $3.. files
  local label="$1" expect="$2"; shift 2
  rm -rf "$W/obj"
  if ! verilator --binary --timing -j 4 -Wno-fatal --top-module route_xbar_tb \
       -I"$D/include" -o run --Mdir "$W/obj" "$@" "$T/tb/route_xbar_tb.sv" >"$W/b.log" 2>&1; then
    printf '  %-34s BUILD FAIL\n' "$label"; grep '%Error' "$W/b.log" | head -2
    fails=$((fails+1)); return
  fi
  out=$(timeout 200 "$W/obj/run" 2>&1)
  if echo "$out" | grep -qE '^RESULT: *PASS'; then got=PASS; else got=FAIL; fi
  if [ "$got" = "$expect" ]; then printf '  %-34s %-4s as expected\n' "$label" "$got"
  else printf '  %-34s %-4s BUT EXPECTED %s\n' "$label" "$got" "$expect"; fails=$((fails+1)); fi
}

echo "RULE 24: each \"(clean)\" line below is a CONTROL -- a conforming"
echo "         implementation must PASS. Each defect line is the positive half."
echo
echo "reference testbench vs the GOLDEN base and its $(printf '%s\n' "$anchor_ids" | wc -l | tr -d ' ') defects"
_r24=$fails
run_one "golden (clean)" PASS "${BASE[@]}" "$D/route_xbar.sv"
if [ "$fails" -ne "$_r24" ]; then
  echo "  RULE24: a CLEAN implementation was reported as failing. That is the"
  echo "          control, not a result -- the instrument has not reproduced a"
  echo "          known answer, so no verdict below it is a measurement."
  exit 2
fi
for M in $(grep -oE "^module xb_m[A-Za-z0-9_]+" "$T/mutants/mutants.sv" | awk '{print $2}'); do
  python3 -c "
import re
src=open('$T/mutants/mutants.sv').read()
b=[x for x in re.split(r'(?=^module )', src, flags=re.M) if x.startswith('module $M')][0]
open('$W/$M.sv','w').write(b.replace('module $M','module route_xbar',1))"
  run_one "$M" FAIL "${BASE[@]}" "$W/$M.sv"
done

echo
echo "reference testbench vs the POLICY-DIVERGENT base and the same $(printf '%s\n' "$anchor_ids" | wc -l | tr -d ' ') defects"
sed 's/module xb_c1_registered_down_rotation/module route_xbar/' \
    "$T/conformant/conformant_perturbations.sv" > "$W/clean_policy.sv"
_r24=$fails
run_one "policy base (clean)" PASS "$W/clean_policy.sv"
if [ "$fails" -ne "$_r24" ]; then
  echo "  RULE24: a CLEAN implementation was reported as failing. That is the"
  echo "          control, not a result -- the instrument has not reproduced a"
  echo "          known answer, so no verdict below it is a measurement."
  exit 2
fi
for f in "$T"/mutants/policy/*.sv; do
  run_one "$(basename "$f" .sv)" FAIL "$f"
done

echo
if [ "$fails" -eq 0 ]; then
  echo "OK: every defect is caught on BOTH bases, and both clean implementations"
  echo "    pass. No mutant is killed by the latitude choice."
else
  echo "MISMATCH in $fails case(s) -- a mutant is sensitive to the policy choice."
fi
exit "$fails"
