#!/usr/bin/env bash
# Rule 21 witness runner. Substitute each mutant for the golden -- the same
# rename the harness performs -- run the reference against it, and report the
# FIRST clause failure. That message is the witness.
set -u
cd "$(dirname "$0")/.."
OUT="${TMPDIR:-/tmp}/v_dsp02_witness"; mkdir -p "$OUT"
TOP=fp_noncomp
python3 -c "
import re,sys
src=open('dut/${TOP}.sv').read()
open(sys.argv[1],'w').write(re.sub(r'\bmodule ${TOP}\b', 'module ${TOP}_golden', src))
" "$OUT/golden_renamed.sv"
OTHER=$(ls dut/*.sv | grep -v "dut/${TOP}.sv$")

# ---- RULE 24 CONTROL, run before any number below is read -------------------
# NEGATIVE: the unmodified golden must produce NO clause failure through this
#   exact build-and-grep pipeline. This is the half that catches a runner which
#   reports a failure unconditionally.
# POSITIVE: every mutant below must produce one. This is the half that catches
#   the two bugs this runner actually had -- a rename that silently matched
#   nothing, and a grep that did not match the testbench's failure format.
#   Both made a real failure look like silence.
r24_neg="unknown"
rm -rf "$OUT/_control"
if verilator --binary --timing -j 4 -Wno-fatal --top-module ${TOP}_tb -o run \
     --Mdir "$OUT/_control"  $OTHER "dut/${TOP}.sv" tb/fp_noncomp_spec_tb.sv > "$OUT/_control.build" 2>&1; then
  cw=$(timeout 400 "$OUT/_control/run" 2>&1 | grep -m1 -E "^\[?FAIL")
  if [ -z "$cw" ]; then r24_neg="PASS (golden produced no clause failure)"
  else r24_neg="FAIL -- golden produced: $cw"; fi
else
  r24_neg="FAIL -- control build failed (see $OUT/_control.build)"
fi
rm -rf "$OUT/_control"
echo "  RULE24 negative control : $r24_neg"
echo "  NOTE: each line below is the FIRST clause failure of that mutant, not the"
echo "        set. COUNTING the lines gives a kill count and that is exact. The id"
echo "        ON a line is the first id to fire, not the only one -- reading the id"
echo "        column as coverage is a wrong claim with a right number."
if [ "${r24_neg:0:4}" != "PASS" ]; then
  echo "  RULE24: refusing to report witnesses -- the instrument did not reproduce"
  echo "          a known answer, so anything it prints is a number, not a measurement."
  exit 2
fi

MUTS=$(grep -oE "^module fn_m[a-z0-9_]+" mutants/mutants.sv | awk '{print $2}')
n_tot=0; n_fail=0
for m in $MUTS; do
  n_tot=$((n_tot+1))
  python3 - "$m" "$OUT" "$TOP" <<'PY'
import re, sys
mut, out, top = sys.argv[1], sys.argv[2], sys.argv[3]
src = open("mutants/mutants.sv").read()
head = src[:src.index("\nmodule fn_")]          # file-scope helper functions
b = [x for x in re.split(r"(?=^module )", src, flags=re.M) if x.startswith("module %s " % mut)][0]
b = b.replace("module %s " % mut, "module %s " % top, 1)
b = re.sub(r"\b%s(\s*)#\(" % top, r"%s_golden\1#(" % top, b)
b = re.sub(r"\b%s(\s+)i_g\b" % top, r"%s_golden\1i_g" % top, b)
b = b.replace("module %s_golden " % top, "module %s " % top, 1)
open("%s/%s.sv" % (out, mut), "w").write(head + "\n" + b)
PY
  verilator --binary --timing -j 4 -Wno-fatal --top-module ${TOP}_tb -o run --Mdir "$OUT/$m" \
    $OTHER "$OUT/golden_renamed.sv" "$OUT/$m.sv" tb/fp_noncomp_spec_tb.sv > "$OUT/$m.build" 2>&1
  if [ $? -ne 0 ]; then echo "  $m : BUILD FAILED -- $(df -m "$OUT" | awk 'NR==2{print $4}')M free on the build volume (a mutant build needs ~600M); see $OUT/$m.build"; continue; fi
  w=$(timeout 300 "$OUT/$m/run" 2>&1 | grep -m1 -E "^\[?FAIL")
  if [ -z "$w" ]; then echo "  $m : NO FAILURE OBSERVED -- the build exited 0 and $(df -m "$OUT" | awk 'NR==2{print $4}')M remains free on the build volume, so this is not a space failure; treat the REFERENCE as suspect"
  else echo "  $m : $w"; n_fail=$((n_fail+1)); fi
  # A Verilator object directory per mutant is hundreds of megabytes on the
  # larger designs. Keeping ten of them filled this machine's disk mid-run.
  rm -rf "$OUT/$m"
done
echo "  RULE24 positive control : $n_fail of $n_tot mutants produced a clause failure"
if [ "$n_fail" -ne "$n_tot" ]; then
  echo "  RULE24: NOT a clean reproduction -- treat every line above as unlicensed."
  exit 2
fi
