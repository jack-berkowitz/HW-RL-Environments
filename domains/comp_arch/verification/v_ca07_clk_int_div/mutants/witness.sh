#!/usr/bin/env bash
# Rule 16 witness harness: the first clause failure the reference reports against
# each mutant, plus the negative controls. Scoring support, never shipped.
#
# RULE 24 -- both halves, and it REFUSES rather than warns:
#   NEGATIVE control: the unmodified anchor must produce NO clause failure
#     through this exact build-and-grep pipeline. Catches a runner that reports
#     a failure unconditionally.
#   POSITIVE control: every mutant must produce one. Catches the faults these
#     runners have actually had -- a rename that silently matched nothing, and a
#     grep that did not match the testbench's failure format. Both turn a real
#     failure into silence, and neither control alone would catch both.
#
# COUNTING BASIS. Every number below is counted from RESULT: and FAIL [ lines
# the testbench emits, never from a text match anywhere in the log. This runner
# once reported one violation for every implementation INCLUDING THE ANCHOR,
# because its grep matched the word VIOLATION inside the harness's own
# explanatory prose.
#
# THE ANCHOR IS RENAMED OUT OF THE WAY. A mutant takes the top module's name and
# delegates to the anchor; passing both under one name is a duplicate definition
# and verilator quietly runs the anchor for every mutant, reporting ten clean
# sweeps of nothing. FINDINGS F66.
set -u
cd "$(dirname "$0")/.." || exit 1
D=dut
TB=tb/clk_ratio_div_spec_tb.sv
OUT="${TMPDIR:-/tmp}/v_ca07_witness"; mkdir -p "$OUT"
OTHER=$(ls $D/*.sv | grep -v "/clk_ratio_div.sv$")

build_run() {   # $1 Mdir tag, $2.. sources; echoes the first FAIL [ line
  local tag="$1"; shift
  rm -rf "$OUT/$tag"
  if ! verilator --binary --timing -j 4 -Wno-fatal --top-module clk_ratio_div_tb \
       -o run --Mdir "$OUT/$tag" "$@" "$TB" > "$OUT/$tag.build" 2>&1; then
    echo "__BUILD_FAIL__"; return
  fi
  timeout 1200 "$OUT/$tag/run" 2>&1 | grep -m1 -E "^FAIL \["
  rm -rf "$OUT/$tag"
}

# ---- RULE 24 negative control ------------------------------------------------
neg=$(build_run _control $OTHER "$D/clk_ratio_div.sv")
if [ "$neg" = "__BUILD_FAIL__" ]; then
  echo "  RULE24 negative control : FAIL -- control build failed"; exit 2
elif [ -n "$neg" ]; then
  echo "  RULE24 negative control : FAIL -- the anchor produced: $neg"
  echo "  RULE24: refusing to report witnesses. The instrument has not"
  echo "          reproduced a known answer, so anything it prints is a number."
  exit 2
else
  echo "  RULE24 negative control : PASS (anchor produced no clause failure)"
fi

python3 -c "
import re,sys
src=open('$D/clk_ratio_div.sv').read()
open(sys.argv[1],'w').write(re.sub(r'\bmodule clk_ratio_div\b','module clk_ratio_div_golden',src))
" "$OUT/golden_renamed.sv"

n_tot=0; n_fail=0
for MM in $(grep -oE "^module cd_m[0-9]+_[A-Za-z0-9_]+" mutants/mutants.sv | awk '{print $2}'); do
  n_tot=$((n_tot+1))
  python3 -c "
import re
src=open('mutants/mutants.sv').read()
b=[x for x in re.split(r'(?=^module )', src, flags=re.M) if x.startswith('module $MM ')][0]
b=re.sub(r'\bclk_ratio_div(\s+i_g)', r'clk_ratio_div_golden\1', b)   # inner FIRST
b=b.replace('module $MM (', 'module clk_ratio_div (', 1)
open('$OUT/$MM.sv','w').write(b)"
  w=$(build_run "$MM" $OTHER "$OUT/golden_renamed.sv" "$OUT/$MM.sv")
  if [ "$w" = "__BUILD_FAIL__" ]; then echo "  $MM : BUILD FAILED"
  elif [ -z "$w" ]; then echo "  $MM : NO FAILURE OBSERVED -- treat the REFERENCE as suspect"
  else echo "  $MM : $w"; n_fail=$((n_fail+1)); fi
done

echo "  RULE24 positive control : $n_fail of $n_tot mutants produced a clause failure"

# ---- negative controls -------------------------------------------------------
# Each must be caught, and the line says WHICH CLAUSE caught it. A control that
# is only noticed by a watchdog has not been measured, it has timed out.
#
# The PROFILE, not just the first line. stuck_high and reset_polarity fail
# FIRST on the same clause for different reasons -- an output stuck high has no
# rising edges and a design held in reset has no output either -- and two
# controls printing the same line are not two demonstrations. The clause set
# and the failure count separate them; a first-failure line alone would not.
profile() {   # $1 tag, $2.. sources
  local tag="$1"; shift
  rm -rf "$OUT/$tag"
  if ! verilator --binary --timing -j 4 -Wno-fatal --top-module clk_ratio_div_tb \
       -o run --Mdir "$OUT/$tag" "$@" "$TB" > "$OUT/$tag.build" 2>&1; then
    echo "BUILD FAIL"; return
  fi
  local log="$OUT/$tag.run"
  timeout 1200 "$OUT/$tag/run" > "$log" 2>&1
  # COUNTING BASIS. The total comes from the testbench's own RESULT line, which
  # counts every failure. It is NOT a count of printed FAIL lines: printing stops
  # at 40 while counting does not, so counting the lines reports 40 for anything
  # worse than 40 and makes two different controls look identical.
  local n cl printed note
  # Tolerant of the RESULT line's wording -- it prints "(1 failure )" for one
  # and "(181 failures)" for many, and a pattern pinned to the plural silently
  # returned zero for the singular case, which read as NOT CAUGHT for a control
  # that WAS caught. The number is the only part worth matching.
  n=$(sed -n 's/^RESULT: FAIL (\([0-9][0-9]*\).*/\1/p' "$log" | head -1)
  [ -z "$n" ] && n=0
  printed=$(grep -c -E "^FAIL \[" "$log")
  cl=$(grep -oE "^FAIL \[[A-Z][0-9]+\]" "$log" | sed 's/^FAIL \[//; s/\]$//' | sort -u | tr '\n' ',' | sed 's/,$//')
  note=""
  [ "$printed" -lt "$n" ] && note=" (clauses among the first $printed printed of $n)"
  if [ "$n" -eq 0 ]; then echo "NOT CAUGHT -- 0 clause failures"
  else echo "$n failures on {$cl}$note"; fi
  rm -rf "$OUT/$tag"
}
echo
echo "negative controls -- caught, on which clause, and how the profiles differ"
for NC in negctl/stuck_high_dut.sv negctl/reset_polarity_dut.sv; do
  b=$(basename "$NC" .sv)
  w=$(build_run "nc_$b" $OTHER "$OUT/golden_renamed.sv" "$NC")
  [ -z "$w" ] && w="NOT CAUGHT -- the reference has no floor here"
  printf '  %-36s %s\n' "$b" "$w"
  pf=$(profile "pr_$b" $OTHER "$OUT/golden_renamed.sv" "$NC")
  printf '  %-36s   profile: %s\n' "" "$pf"
  case "$w$pf" in *"FAIL ["*"NOT CAUGHT"*) echo "  RULE24: the two readings of the same run disagree."; exit 2;; esac
done
for NC in h3_nc1_throttle_hits_same_value h3_nc2_extra_gating_hits_same_value; do
  python3 -c "
import re
src=open('negctl/h3_violating_perturbations.sv').read()
b=[x for x in re.split(r'(?=^module )', src, flags=re.M) if x.startswith('module $NC ')][0]
b=b.replace('module $NC (', 'module clk_ratio_div (', 1)
open('$OUT/$NC.sv','w').write(b)"
  w=$(build_run "nc_$NC" $OTHER "$OUT/golden_renamed.sv" "$OUT/$NC.sv")
  [ -z "$w" ] && w="NOT CAUGHT -- an H3 violation passed as a legal variant"
  printf '  %-36s %s\n' "$NC" "$w"
  pf=$(profile "pr_$NC" $OTHER "$OUT/golden_renamed.sv" "$OUT/$NC.sv")
  printf '  %-36s   profile: %s\n' "" "$pf"
  case "$w$pf" in *"FAIL ["*"NOT CAUGHT"*) echo "  RULE24: the two readings of the same run disagree."; exit 2;; esac
done

if [ "$n_fail" -ne "$n_tot" ]; then
  echo
  echo "  RULE24: NOT a clean reproduction -- treat every line above as unlicensed."
  exit 2
fi
