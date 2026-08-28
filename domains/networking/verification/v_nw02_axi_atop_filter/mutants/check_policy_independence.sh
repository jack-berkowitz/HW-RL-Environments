#!/bin/bash
# TIER-B 5c: no mutant may be killed by the POLICY difference alone.
#
# The ten defects of mutants.sv are re-derived on top of the policy-divergent
# implementation (mutants/policy/), which makes the opposite legal choice on
# both named latitude clauses. Each is then run against the reference
# testbench. A verdict that differs from the same defect on the golden base
# means that mutant is perturbing latitude rather than contract.
#
# Also runs the clean policy implementation itself, which must PASS.
set -u
cd "$(dirname "$0")/../../../../.." || exit 1
T=domains/networking/verification/v_nw02_axi_atop_filter
W=$(mktemp -d)
trap 'rm -rf "$W"' EXIT
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
anchor_ids=$(grep -oE "^module af_m[0-9]+_[a-z0-9_]+" "$T/mutants/mutants.sv" \
             | sed 's/^module af_m/af_/' | sort)
policy_ids=$(ls "$T"/mutants/policy/*.sv 2>/dev/null | xargs -n1 basename \
             | sed 's/\.sv$//; s/^af_p/af_/' | sort)
if [ "$anchor_ids" != "$policy_ids" ]; then
  echo "  RULE24: the anchor and policy halves are not the same SET."
  comm -23 <(printf '%s\n' "$anchor_ids") <(printf '%s\n' "$policy_ids") \
    | sed 's/^/    anchor only (no policy re-derivation): /'
  comm -13 <(printf '%s\n' "$anchor_ids") <(printf '%s\n' "$policy_ids") \
    | sed 's/^/    policy only (no anchor mutant): /'
  echo "  Add the missing re-derivation. Do NOT make the counts agree by"
  echo "  deleting the other side -- the anchor half is what scoring uses."
  echo ""
  echo "  AND DO NOT 'just re-run gen_mutants.py' TO RESOLVE THIS. That advice"
  echo "  used to print here and it was destructive: the generator rewrites"
  echo "  mutants.sv from its own list, so on a mismatch caused by a mutant"
  echo "  ADDED BY HAND it would delete the mutant and 'fix' the count by"
  echo "  removing the anchor side. af_m11 and af_m12 were both in that"
  echo "  position. The generator now REFUSES to drop mutants it does not"
  echo "  define; add the missing entries to MUT and POLICY instead."
  exit 2
fi

run_one() {  # $1 = label, $2 = dut file, $3 = expected (PASS|FAIL)
  rm -rf "$W/obj"
  if ! verilator --binary --timing -j 4 -Wno-fatal --top-module atop_filter_tb \
       -o run --Mdir "$W/obj" "$2" "$T/tb/atop_filter_tb.sv" >"$W/build.log" 2>&1; then
    printf '  %-28s BUILD FAIL\n' "$1"; grep '%Error' "$W/build.log" | head -2; fails=$((fails+1)); return
  fi
  out=$(timeout 120 "$W/obj/run" 2>&1)
  if echo "$out" | grep -qE '^RESULT: *PASS'; then got=PASS; else got=FAIL; fi
  if [ "$got" = "$3" ]; then
    printf '  %-28s %-4s as expected\n' "$1" "$got"
  else
    printf '  %-28s %-4s BUT EXPECTED %s\n' "$1" "$got" "$3"; fails=$((fails+1))
  fi
}

echo "RULE 24: each \"(clean)\" line below is a CONTROL -- a conforming"
echo "         implementation must PASS. Each defect line is the positive half."
echo
echo "reference testbench vs the POLICY-DIVERGENT base and the same $(printf '%s\n' "$anchor_ids" | wc -l | tr -d ' ') defects"
sed 's/module af_c1_b_before_r/module atop_filter/' \
    "$T/conformant/conformant_perturbations.sv" > "$W/clean.sv"
_r24=$fails
run_one "policy base (clean)" "$W/clean.sv" PASS
if [ "$fails" -ne "$_r24" ]; then
  echo "  RULE24: a CLEAN implementation was reported as failing. That is the"
  echo "          control, not a result -- the instrument has not reproduced a"
  echo "          known answer, so no verdict below it is a measurement."
  exit 2
fi
for f in "$T"/mutants/policy/*.sv; do
  run_one "$(basename "$f" .sv)" "$f" FAIL
done
echo
if [ "$fails" -eq 0 ]; then
  echo "OK: all 13 checks here pass -- the clean policy implementation, and each"
  echo "    of the TWELVE defects re-derived on it. THIS SCRIPT COVERS THE POLICY"
  echo "    BASE ONLY. The golden-base half (golden PASS, twelve mutants killed)"
  echo "    is established by scripts/sim_verification.sh, not here. Saying"
  echo "    both-bases here would claim a check this script never ran."
  echo ""
  echo "    THE af_m11/af_m12 GAP IS CLOSED. From the moment af_m11 landed this"
  echo "    script exited on its count guard without running anything: af_m11"
  echo "    and af_m12 were hand-written and had no policy counterparts, so 5c"
  echo "    produced NO verification at all for as long as that lasted. Both are"
  echo "    now generated by gen_mutants.py, p11 and p12 with them, counts agree."
  echo ""
  echo "    THE TEXT THAT USED TO PRINT HERE WAS WRONG THE MOMENT IT BECAME"
  echo "    REACHABLE. It described the gap and called itself what should print"
  echo "    once p11 and p12 exist -- so when they did, it announced a gap that"
  echo "    had just been closed. Documentation parked in an unreachable branch"
  echo "    is not preserved, it is unmaintained: nothing could contradict it"
  echo "    while nothing could reach it."
else
  echo "MISMATCH in $fails case(s) -- a mutant is sensitive to the policy choice."
fi
exit "$fails"
