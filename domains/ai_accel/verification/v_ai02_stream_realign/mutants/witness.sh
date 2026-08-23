#!/usr/bin/env bash
# Rule 16 witness harness runner: first observable difference, golden vs mutant.
set -u
cd "$(dirname "$0")/.."
OUT="${TMPDIR:-/tmp}/v_ai02_witness"; mkdir -p "$OUT"
CTRL_SRCS='dut/*.sv mutants/mutants.sv mutants/nonequiv_tb.sv'

# ---- RULE 24 CONTROL, run before any number below is read -------------------
# NEGATIVE: driving the GOLDEN against itself must report NO DIFFERENCE. This
#   is the half that catches a harness reporting a difference unconditionally,
#   or one whose observable projection is comparing something it should not.
# POSITIVE: every mutant below must report a first difference. This is the half
#   that catches a harness which cannot see one -- the failure mode where a
#   stimulus never reaches the guarded configuration and silence is mistaken
#   for equivalence.
rm -rf "$OUT/_control"
verilator --binary --timing -j 4 -Wno-fatal --top-module nonequiv_tb \
  -DMUT_MOD=stream_realign  -o run --Mdir "$OUT/_control" \
  $CTRL_SRCS > "$OUT/_control.build" 2>&1
if [ $? -ne 0 ]; then
  echo "  RULE24 negative control : FAIL -- control build failed (see $OUT/_control.build)"
  exit 2
fi
cw=$(timeout 300 "$OUT/_control/run" 2>&1 | grep "^WITNESS")
rm -rf "$OUT/_control"
case "$cw" in
  *"NO DIFFERENCE OBSERVED"*)
    echo "  RULE24 negative control : PASS (golden vs golden: no difference)" ;;
  *)
    echo "  RULE24 negative control : FAIL -- golden vs golden reported: $cw"
    echo "  RULE24: refusing to report witnesses -- the instrument did not"
    echo "          reproduce a known answer."
    exit 2 ;;
esac

MUTS=$(grep -oE "^module [a-z0-9_]+" mutants/mutants.sv | awk '{print $2}')
n_tot=0; n_fail=0
for m in $MUTS; do
  n_tot=$((n_tot+1))
  verilator --binary --timing -j 4 -Wno-fatal --top-module nonequiv_tb \
    -DMUT_MOD="$m" -o run --Mdir "$OUT/$m" \
    dut/*.sv mutants/mutants.sv mutants/nonequiv_tb.sv > "$OUT/$m.build" 2>&1
  if [ $? -ne 0 ]; then echo "  $m : BUILD FAILED (see $OUT/$m.build)"; continue; fi
  wl=$(timeout 300 "$OUT/$m/run" 2>&1 | grep "^WITNESS")
  echo "$wl" | sed 's/^WITNESS /  /'
  case "$wl" in *"NO DIFFERENCE OBSERVED"*) ;; *) n_fail=$((n_fail+1)) ;; esac
  # A Verilator object directory per mutant is hundreds of megabytes on the
  # larger designs. Keeping ten of them filled this machine's disk mid-run.
  rm -rf "$OUT/$m"
done
echo "  RULE24 positive control : $n_fail of $n_tot mutants reported a difference"
if [ "$n_fail" -ne "$n_tot" ]; then
  echo "  RULE24: NOT a clean reproduction -- treat every line above as unlicensed."
  exit 2
fi
