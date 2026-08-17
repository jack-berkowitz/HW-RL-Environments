#!/bin/bash
set -uo pipefail
cd /Users/jackberkowitz/Desktop/hw_rl_benchmark
LOG="fmax_results/build_queue.log"
say() { printf '%s  %s\n' "$(date '+%H:%M:%S')" "$*" | tee -a "$LOG"; }
while pgrep -f "ppa_candidate|find_fmax" >/dev/null; do sleep 30; done
say "=== QUEUE 2 -- new candidates ==="
say "  NOT queued: d_ca04/kimi (build fail), d_dsp02/deepseek (build fail),"
say "    d_dsp02/gemini (fails correctness at vector 4)."
say "[A] d_ca04/deepseek PPA at 4.5 ns"
CLK_PERIOD_NS=4.5000 stdbuf -oL -eL ./scripts/ppa_candidate.sh \
  d_ca04 candidates/d_ca04/deepseek.sv deepseek_scored >> "$LOG" 2>&1
RCA=$?; say "[A] exit=$RCA"
if [ "$RCA" -eq 0 ]; then
  say "[B] d_ca04/deepseek Fmax sweep (seed 4.5 ns)"
  PYTHONUNBUFFERED=1 stdbuf -oL -eL python3 -u scripts/find_fmax.py \
    --design d_ca04_cand_deepseek_scored --seed-period-ns 4.5 \
    --max-bracket-iterations 4 --resolution-ns 0.5 --max-iterations 9 \
    --skip-sim-check >> "$LOG" 2>&1
  say "[B] exit=$?"
else
  say "[B] SKIPPED -- single PPA did not complete (F31)."
fi
say "=== QUEUE 2 COMPLETE ==="

# --- rule 17: the reference PPA record predates the build-config hash, so the
# --- 6.4x area comparison is UNCOMPARABLE until it is rebuilt with one.
say "[C] d_dsp02 reference PPA at 12.8125 ns -- regenerate with a build-config hash"
CLK_PERIOD_NS=12.8125 WIPE_DESIGN=d_dsp02_fp32_fma_ii1 PLATFORM=sky130hd \
  stdbuf -oL -eL ./scripts/run_orfs_build.sh \
  /work/domains/dsp/design/d_dsp02_fp32_fma_ii1/orfs/config.mk >> "$LOG" 2>&1
RCC=$?
if [ "$RCC" -eq 0 ]; then
  FLOW="${ORFS_FLOW_DIR:-$HOME/tools/OpenROAD-flow-scripts/flow}"
  L="$FLOW/logs/sky130hd/d_dsp02_fp32_fma_ii1/base"
  R="$FLOW/reports/sky130hd/d_dsp02_fp32_fma_ii1/base"
  BCH_OUT="$(python3 scripts/build_config_hash.py \
    domains/dsp/design/d_dsp02_fp32_fma_ii1/orfs/config.mk \
    domains/dsp/design/d_dsp02_fp32_fma_ii1/orfs/constraint.sdc CLK_PERIOD_NS=12.8125)"
  python3 scripts/write_run_record.py d_dsp02_fp32_fma_ii1 \
    domains/dsp/design/d_dsp02_fp32_fma_ii1/ref/fp32_fma_ii1_ref.sv ppa reference_hashed \
    "status=completed" \
    "design_area_um2=$(grep -iE '^Design area' "$L/6_report.log" | tail -1 | grep -oE '[0-9]+' | head -1)" \
    "wns_ns=$(python3 -c "import json;print(json.load(open('$L/6_report.json'))['finish__timing__setup__ws'])" 2>/dev/null)" \
    "power_w=$(grep -A11 'finish report_power' "$R/6_finish.rpt" | grep -E '^Total' | awk '{print $5}')" \
    "clk_period_ns=12.8125" "drc=0" "orfs_nickname=d_dsp02_fp32_fma_ii1" "pdk=sky130hd" \
    "correctness_gate=passed:reference" \
    "build_config_hash=$(echo "$BCH_OUT" | head -1)" \
    "build_config_fields=$(echo "$BCH_OUT" | tail -n +2 | tr -s ' ' | tr '\n' ';' | sed 's/^;//')" \
    >> "$LOG" 2>&1
fi
say "[C] exit=$RCC"
say "=== QUEUE 2 COMPLETE (with reference rehash) ==="
