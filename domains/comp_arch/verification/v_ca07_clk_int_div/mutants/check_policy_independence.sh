#!/bin/bash
# TIER-B 5c: no mutant may be killed by the POLICY difference alone.
#
# IN-SOURCE RE-DERIVATION. Each of the ten defects is written into dut2's OWN
# SOURCE, in its own terms -- a counter and a half-cycle-delayed phase, where the
# anchor is a state machine with its own clock gate. This is the method that CAN
# FAIL: a guard depending on something only the anchor has cannot be expressed
# here and surfaces as a defect the divergent base does not catch.
#
# RULE 24: each "(clean)" line is a CONTROL -- a conforming implementation must
# PASS. A failing control ABORTS rather than being counted with the defects,
# because a run whose control failed licenses nothing.
set -u
cd "$(dirname "$0")/../../../../.." || exit 1
T=domains/comp_arch/verification/v_ca07_clk_int_div
TB=$T/tb/clk_ratio_div_spec_tb.sv
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
anchor_ids=$(grep -oE "^module cd_m[0-9]+_[a-z0-9_]+" "$T/mutants/mutants.sv" \
             | sed 's/^module cd_m/cd_/' | sort)
policy_ids=$(ls "$T"/mutants/policy/*.sv 2>/dev/null | xargs -n1 basename \
             | sed 's/\.sv$//; s/^cd_p/cd_/' | sort)
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

run_one() {   # $1 label, $2 expected, $3.. sources
  local label="$1" expect="$2"; shift 2
  rm -rf "$W/obj"
  if ! verilator --binary --timing -j 4 -Wno-fatal --top-module clk_ratio_div_tb \
       -o run --Mdir "$W/obj" "$@" "$TB" >"$W/b.log" 2>&1; then
    printf '  %-46s BUILD FAIL\n' "$label"; grep '%Error' "$W/b.log" | head -2
    fails=$((fails+1)); return
  fi
  out=$(timeout 1200 "$W/obj/run" 2>&1)
  if echo "$out" | grep -qE '^RESULT: *PASS'; then got=PASS; else got=FAIL; fi
  if [ "$got" = "$expect" ]; then printf '  %-46s %-4s as expected\n' "$label" "$got"
  else printf '  %-46s %-4s BUT EXPECTED %s\n' "$label" "$got" "$expect"; fails=$((fails+1)); fi
}
ctl() {
  if [ "$fails" -ne "$1" ]; then
    echo "  RULE24: a CLEAN implementation was reported as failing. That is the"
    echo "          control, not a result -- no verdict below it is a measurement."
    exit 2
  fi
}

echo "RULE 24: each \"(clean)\" line is a CONTROL and must PASS."
echo
echo "reference testbench vs the ANCHOR and its $(printf '%s\n' "$anchor_ids" | wc -l | tr -d ' ') defects"
r=$fails; run_one "anchor (clean)" PASS $T/dut/*.sv; ctl "$r"
for MM in $(grep -oE "^module cd_m[0-9]+_[A-Za-z0-9_]+" "$T/mutants/mutants.sv" | awk '{print $2}'); do
  python3 -c "
import re
src=open('$T/mutants/mutants.sv').read()
b=[x for x in re.split(r'(?=^module )', src, flags=re.M) if x.startswith('module $MM ')][0]
b=re.sub(r'\bclk_ratio_div(\s+i_g)', r'clk_ratio_div_golden\1', b)   # inner FIRST
b=b.replace('module $MM (', 'module clk_ratio_div (', 1)
open('$W/$MM.sv','w').write(b)"
  python3 -c "
import re,sys
src=open('$T/dut/clk_ratio_div.sv').read()
open(sys.argv[1],'w').write(re.sub(r'\bmodule clk_ratio_div\b','module clk_ratio_div_golden',src))
" "$W/golden_renamed.sv"
  run_one "$MM" FAIL $T/dut/clk_int_div.sv $T/dut/tc_clk.sv "$W/golden_renamed.sv" "$W/$MM.sv"
done

echo
echo "reference testbench vs the POLICY-DIVERGENT base and the same $(printf '%s\n' "$anchor_ids" | wc -l | tr -d ' ') defects"
sed 's/module clk_ratio_div_alt/module clk_ratio_div/' "$T/dut2/clk_ratio_div_alt.sv" > "$W/clean_policy.sv"
r=$fails; run_one "policy base (clean)" PASS "$W/clean_policy.sv"; ctl "$r"
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
