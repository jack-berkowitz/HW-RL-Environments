#!/bin/bash
# TIER-B 5c: no mutant may be killed by the POLICY difference alone.
#
# The defects of mutants.sv -- however many it defines; this script counts them
# rather than naming a number -- are re-derived on the policy-divergent
# implementation (mutants/policy/), which makes every beat wait for the sink and
# drives a fixed pattern while pop_valid_o is low -- the opposite choice on both
# named latitude clauses. A verdict that differs from the same defect on the
# golden base means that mutant is perturbing latitude rather than contract.
set -u
cd "$(dirname "$0")/../../../../.." || exit 1
T=domains/ai_accel/verification/v_ai02_stream_realign
D=$T/dut
W=$(mktemp -d); trap 'rm -rf "$W"' EXIT
fails=0
BASE=("$D/hwpe_stream_package.sv" "$D/hwpe_stream_interfaces.sv" "$D/tc_clk.sv"
      "$D/hwpe_stream_source_realign.sv")
for f in "$D"/hwpe_stream_source_realign_m*.sv; do BASE+=("$f"); done

run_one() {   # $1 label, $2 expected, $3.. files
  local label="$1" expect="$2"; shift 2
  rm -rf "$W/obj"
  if ! verilator --binary --timing -j 4 -Wno-fatal --top-module stream_realign_tb \
       -o run --Mdir "$W/obj" "$@" "$T/tb/stream_realign_tb.sv" >"$W/b.log" 2>&1; then
    printf '  %-34s BUILD FAIL\n' "$label"; grep '%Error' "$W/b.log" | head -2
    fails=$((fails+1)); return
  fi
  out=$(timeout 200 "$W/obj/run" 2>&1)
  if echo "$out" | grep -qE '^RESULT: *PASS'; then got=PASS; else got=FAIL; fi
  if [ "$got" = "$expect" ]; then printf '  %-34s %-4s as expected\n' "$label" "$got"
  else printf '  %-34s %-4s BUT EXPECTED %s\n' "$label" "$got" "$expect"; fails=$((fails+1)); fi
}

# SET EQUALITY IS CHECKED BEFORE ANYTHING IS COMPILED. This runner globs
# policy/*.sv, so a generation that failed part way leaves fewer files and every
# row still reads "as expected" -- a short set is indistinguishable from a
# complete one in the output, which is how a banner claiming ten sits above nine.
#
# It runs FIRST because it is free and the run is not. Placed after the golden
# loop, as it was, a miscount costs eleven Verilator builds before it fires; the
# control that proves this check works timed out at two minutes waiting for it.
n_anchor=$(grep -cE "^module sr_m" "$T/mutants/mutants.sv")
n_policy=$(ls "$T"/mutants/policy/*.sv 2>/dev/null | wc -l | tr -d ' ')
if [ "$n_anchor" -ne "$n_policy" ]; then
  echo "  RULE24: $n_anchor defects on the anchor but $n_policy re-derivations."
  echo "          The two halves are not the same set. Re-run the generator."
  exit 2
fi

echo "RULE 24: each \"(clean)\" line below is a CONTROL -- a conforming"
echo "         implementation must PASS. Each defect line is the positive half."
echo
echo "reference testbench vs the GOLDEN base and its $(grep -cE '^module sr_m' "$T/mutants/mutants.sv") defects"
_r24=$fails
run_one "golden (clean)" PASS "${BASE[@]}" "$D/stream_realign.sv"
if [ "$fails" -ne "$_r24" ]; then
  echo "  RULE24: a CLEAN implementation was reported as failing. That is the"
  echo "          control, not a result -- the instrument has not reproduced a"
  echo "          known answer, so no verdict below it is a measurement."
  exit 2
fi
for M in $(grep -oE "^module sr_m[A-Za-z0-9_]+" "$T/mutants/mutants.sv" | awk '{print $2}'); do
  python3 -c "
import re
src=open('$T/mutants/mutants.sv').read()
b=[x for x in re.split(r'(?=^module )', src, flags=re.M) if x.startswith('module $M')][0]
open('$W/$M.sv','w').write(b.replace('module $M','module stream_realign',1))"
  run_one "$M" FAIL "${BASE[@]}" "$W/$M.sv"
done

echo
echo "reference testbench vs the POLICY-DIVERGENT base and the same $n_anchor defects"
sed 's/module sr_c1_first_beat_waits/module stream_realign/' \
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
  echo "OK: $(( 2 * (n_anchor + 1) )) of $(( 2 * (n_anchor + 1) )) checks passed -- $n_anchor defects and one"
  echo "    clean control on each of the GOLDEN and POLICY-DIVERGENT bases."
  echo "    Every defect is caught on both, and both clean implementations"
  echo "    pass. No mutant is killed by the latitude choice."
else
  echo "MISMATCH in $fails case(s) -- a mutant is sensitive to the policy choice."
fi
exit "$fails"
