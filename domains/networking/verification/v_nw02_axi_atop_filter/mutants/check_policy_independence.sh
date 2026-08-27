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
# The two halves must be the SAME SET. This runner globs policy/*.sv, so a
# generation that failed part way leaves fewer files and every row still reads
# "as expected" -- a short set is indistinguishable from a complete one in the
# output. Paired with the generator wiping the directory first, a miscount is
# now the loud failure and a stale file is impossible.
n_anchor=$(grep -cE "^module af_m[0-9]+_" "$T/mutants/mutants.sv")
n_policy=$(ls "$T"/mutants/policy/*.sv 2>/dev/null | wc -l | tr -d ' ')
if [ "$n_anchor" -ne "$n_policy" ]; then
  echo "  RULE24: $n_anchor defects on the anchor but $n_policy re-derivations."
  echo "          The two halves are not the same set. Re-run gen_mutants.py."
  exit 2
fi
echo "reference testbench vs the POLICY-DIVERGENT base and the same $(grep -cE '^module af_m[0-9]+_' "$T/mutants/mutants.sv") defects"
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
  echo "OK: all 11 checks here pass -- the clean policy implementation, and each"
  echo "    of the ten defects re-derived on it. THIS SCRIPT COVERS THE POLICY"
  echo "    BASE ONLY. The golden-base half (golden PASS, ELEVEN mutants"
  echo "    killed) is established by scripts/sim_verification.sh, not here."
  echo "    Saying \"both bases\" here would claim a check this script never ran."
  echo
  echo "    AND THE TWO SETS ARE NO LONGER THE SAME SIZE. af_m11, added to give"
  echo "    W3 a witness, has NO policy-base counterpart: ten of the eleven"
  echo "    golden-base mutants are covered here, not eleven. That is a real"
  echo "    gap and it is stated rather than absorbed into \"all checks pass\"."
else
  echo "MISMATCH in $fails case(s) -- a mutant is sensitive to the policy choice."
fi
exit "$fails"
