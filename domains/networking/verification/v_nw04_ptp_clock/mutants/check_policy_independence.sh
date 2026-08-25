#!/bin/bash
# TIER-B 5c: no mutant may be killed by the POLICY difference alone.
#
# The ten defects of mutants.sv are re-derived on top of the policy-divergent
# implementation (mutants/policy/), which acts on every control input in its own
# cycle and drives both time bases from the same increment -- the opposite
# choice on both named latitude clauses. Each is run against the reference
# testbench. A verdict that differs from the same defect on the golden base
# means that mutant is perturbing latitude rather than contract.
set -u
cd "$(dirname "$0")/../../../../.." || exit 1
T=domains/networking/verification/v_nw04_ptp_clock
W=$(mktemp -d); trap 'rm -rf "$W"' EXIT
fails=0

run_one() {   # $1 label, $2 expected, $3.. files
  local label="$1" expect="$2"; shift 2
  rm -rf "$W/obj"
  if ! verilator --binary --timing -j 4 -Wno-fatal --top-module ptp_time_base_tb \
       -o run --Mdir "$W/obj" "$@" "$T/tb/ptp_time_base_tb.sv" >"$W/b.log" 2>&1; then
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
echo "reference testbench vs the GOLDEN base and its ten defects"
_r24=$fails
run_one "golden (clean)" PASS "$T/dut/ptp_clock.sv" "$T/dut/ptp_time_base.sv"
if [ "$fails" -ne "$_r24" ]; then
  echo "  RULE24: a CLEAN implementation was reported as failing. That is the"
  echo "          control, not a result -- the instrument has not reproduced a"
  echo "          known answer, so no verdict below it is a measurement."
  exit 2
fi
for M in $(grep -oE "^module pt_m[A-Za-z0-9_]+" "$T/mutants/mutants.sv" | awk '{print $2}'); do
  python3 -c "
import re
src=open('$T/mutants/mutants.sv').read()
b=[x for x in re.split(r'(?=^module )', src, flags=re.M) if x.startswith('module $M')][0]
open('$W/$M.sv','w').write(b.replace('module $M','module ptp_time_base',1))"
  run_one "$M" FAIL "$T/dut/ptp_clock.sv" "$T/dut/ptp_clock_${M#pt_}.sv" "$W/$M.sv"
done

echo
echo "reference testbench vs the POLICY-DIVERGENT base and the same eight defects"
sed 's/module pt_c1_zero_latency/module ptp_time_base/' \
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
