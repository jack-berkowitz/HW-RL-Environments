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

# --- new candidates and the rule-17 rehashes -------------------------------
say "[D] d_ca04/qwen PPA at 4.5 ns"
CLK_PERIOD_NS=4.5000 stdbuf -oL -eL ./scripts/ppa_candidate.sh \
  d_ca04 candidates/d_ca04/qwen.sv qwen_scored >> "$LOG" 2>&1
RCD=$?; say "[D] exit=$RCD"
if [ "$RCD" -eq 0 ]; then
  say "[E] d_ca04/qwen Fmax sweep (seed 4.5 ns)"
  PYTHONUNBUFFERED=1 stdbuf -oL -eL python3 -u scripts/find_fmax.py \
    --design d_ca04_cand_qwen_scored --seed-period-ns 4.5 \
    --max-bracket-iterations 4 --resolution-ns 0.5 --max-iterations 9 \
    --skip-sim-check >> "$LOG" 2>&1
  say "[E] exit=$?"
else
  say "[E] SKIPPED (F31)."
fi

# RULE 17: d_ca04's reference PPA has no build-config hash while both candidates
# do, so the 1.369 headline is UNCOMPARABLE exactly as d_dsp02's 6.4x was.
say "[F] d_ca04 reference PPA at 2.625 ns -- regenerate WITH a build-config hash"
CLK_PERIOD_NS=2.6250 WIPE_DESIGN=d_ca04_async_fifo_cdc PLATFORM=sky130hd \
  stdbuf -oL -eL ./scripts/run_orfs_build.sh \
  /work/domains/comp_arch/design/d_ca04_async_fifo_cdc/orfs/config.mk >> "$LOG" 2>&1
RCF=$?
if [ "$RCF" -eq 0 ]; then
  FLOW="${ORFS_FLOW_DIR:-$HOME/tools/OpenROAD-flow-scripts/flow}"
  L="$FLOW/logs/sky130hd/d_ca04_async_fifo_cdc/base"
  R="$FLOW/reports/sky130hd/d_ca04_async_fifo_cdc/base"
  BCH="$(python3 scripts/build_config_hash.py \
    domains/comp_arch/design/d_ca04_async_fifo_cdc/orfs/config.mk \
    domains/comp_arch/design/d_ca04_async_fifo_cdc/orfs/constraint.sdc CLK_PERIOD_NS=2.6250)"
  python3 scripts/write_run_record.py d_ca04_async_fifo_cdc \
    domains/comp_arch/design/d_ca04_async_fifo_cdc/ref/async_fifo_cdc_ref.sv ppa reference_hashed \
    "status=completed" \
    "design_area_um2=$(grep -iE '^Design area' "$L/6_report.log" | tail -1 | grep -oE '[0-9]+' | head -1)" \
    "wns_ns=$(python3 -c "import json;print(json.load(open('$L/6_report.json'))['finish__timing__setup__ws'])" 2>/dev/null)" \
    "power_w=$(grep -A11 'finish report_power' "$R/6_finish.rpt" | grep -E '^Total' | awk '{print $5}')" \
    "clk_period_ns=2.625" "drc=0" "orfs_nickname=d_ca04_async_fifo_cdc" "pdk=sky130hd" \
    "correctness_gate=passed:reference-18/18" \
    "build_config_hash=$(echo "$BCH" | head -1)" \
    "build_config_fields=$(echo "$BCH" | tail -n +2 | tr -s ' ' | tr '\n' ';' | sed 's/^;//')" \
    >> "$LOG" 2>&1
fi
say "[F] exit=$RCF"
say "=== QUEUE 2 COMPLETE (new candidates + rule-17 rehashes) ==="
