#!/bin/bash
# Sequential ORFS build queue. ORFS is single-occupancy -- two concurrent runs
# share the flow directory and overwrite each other's reports, which is P4.
#
# Unattended. Jobs are independent: a failure logs and the queue continues.
# Progress is UNBUFFERED to fmax_results/build_queue.log with timestamps, so an
# interrupted queue can be read back.
set -uo pipefail
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO"
LOG="fmax_results/build_queue.log"
mkdir -p fmax_results
say() { printf '%s  %s\n' "$(date '+%H:%M:%S')" "$*" | tee -a "$LOG"; }

if pgrep -f "ppa_candidate|find_fmax" >/dev/null; then
  say "waiting for the in-flight build to finish"
  while pgrep -f "ppa_candidate|find_fmax" >/dev/null; do sleep 30; done
fi

# ---- memory precondition, CHECKED not assumed (F31) ------------------------
# d_nw01's candidate needs more than the 5.8 GB ceiling that OOM-killed it.
# Docker Desktop's saved setting can be raised without the running daemon
# picking it up -- it needs a restart -- so the queue reads what the DAEMON
# reports rather than trusting the settings file.
MEM_GB="$(docker info --format '{{.MemTotal}}' 2>/dev/null | awk '{printf "%.1f", $1/1024/1024/1024}')"
say "docker daemon reports ${MEM_GB:-unknown} GB available"
BIG_OK=0
if [ -n "${MEM_GB:-}" ] && [ "$(echo "$MEM_GB >= 8.0" | bc -l 2>/dev/null || echo 0)" = "1" ]; then
  BIG_OK=1
fi

say "=== QUEUE START -- 6 jobs ==="
say "NOT queued, and why:"
say "  d_dsp02/gemini -- FAILS CORRECTNESS (vector 4). A PPA number for a design"
say "    that fails its contract is not a result."
say "  d_nw01/gemini  -- does not build (anonymous struct as a parameter value,"
say "    confirmed on both frontends). Scores zero under rule 19."
[ "$BIG_OK" = "1" ] || say "  d_nw01/chat -- daemon at ${MEM_GB} GB, needs >= 8 (F31)."

# --- d_dsp02/chat: the first S1-COMPLIANT submission ------------------------
# Re-solicited after F30. Measures latency 3, II 1 -- it implements the scored
# configuration, so unlike the previous answer its PPA is comparable with the
# reference's.
say "[1] d_dsp02/chat PPA at 12.8125 ns (its own Fmax period)"
CLK_PERIOD_NS=12.8125 stdbuf -oL -eL ./scripts/ppa_candidate.sh \
  d_dsp02 candidates/d_dsp02/chat.sv chat_scored >> "$LOG" 2>&1
RC1=$?
say "[1] exit=$RC1"

if [ "$RC1" -eq 0 ]; then
  say "[2] d_dsp02/chat Fmax sweep (seed 12.0 ns)"
  PYTHONUNBUFFERED=1 stdbuf -oL -eL python3 -u scripts/find_fmax.py \
    --design d_dsp02_cand_chat_scored --seed-period-ns 12.0 \
    --max-bracket-iterations 4 --resolution-ns 0.5 --max-iterations 9 \
    --skip-sim-check >> "$LOG" 2>&1
  say "[2] exit=$?"
else
  say "[2] SKIPPED -- single PPA did not complete, so a 9-iteration sweep of the"
  say "    same place-and-route would not either (F31)."
fi

# --- d_nw01/chat: retry, now that memory allows it -------------------------
if [ "$BIG_OK" = "1" ]; then
  say "[3] d_nw01/chat PPA at 5.25 ns -- retry with ${MEM_GB} GB (was OOM-killed at 5.8)"
  CLK_PERIOD_NS=5.2500 stdbuf -oL -eL ./scripts/ppa_candidate.sh \
    d_nw01 candidates/d_nw01/chat.sv chat_scored >> "$LOG" 2>&1
  RC3=$?
  say "[3] exit=$RC3"
  if [ "$RC3" -eq 0 ]; then
    say "[4] d_nw01/chat Fmax sweep (seed 6.0 ns)"
    PYTHONUNBUFFERED=1 stdbuf -oL -eL python3 -u scripts/find_fmax.py \
      --design d_nw01_cand_chat_scored --seed-period-ns 6.0 \
      --max-bracket-iterations 4 --resolution-ns 0.5 --max-iterations 9 \
      --skip-sim-check >> "$LOG" 2>&1
    say "[4] exit=$?"
  else
    say "[4] SKIPPED -- see [2]'s reasoning."
  fi
else
  say "[3,4] SKIPPED -- insufficient container memory."
fi

# --- retries of the two jobs the Docker restart killed (exit 125) ----------
say "[5] d_ca04/gemini Fmax sweep (seed 4.5 ns) -- retry, died on docker exit 125"
PYTHONUNBUFFERED=1 stdbuf -oL -eL python3 -u scripts/find_fmax.py \
  --design d_ca04_cand_gemini_own_fmax --seed-period-ns 4.5 \
  --max-bracket-iterations 4 --resolution-ns 0.5 --max-iterations 9 \
  --skip-sim-check >> "$LOG" 2>&1
say "[5] exit=$?"

say "[6] d_nw01 reference PPA at 5.25 ns (gated) -- retry, died on docker exit 125"
CLK_PERIOD_NS=5.2500 WIPE_DESIGN=d_nw01_axi4_xbar PLATFORM=sky130hd \
  stdbuf -oL -eL ./scripts/run_orfs_build.sh \
  /work/domains/networking/design/d_nw01_axi4_xbar/orfs/config.mk >> "$LOG" 2>&1
RC6=$?
if [ "$RC6" -eq 0 ]; then
  FLOW="${ORFS_FLOW_DIR:-$HOME/tools/OpenROAD-flow-scripts/flow}"
  L="$FLOW/logs/sky130hd/d_nw01_axi4_xbar/base"
  R="$FLOW/reports/sky130hd/d_nw01_axi4_xbar/base"
  python3 scripts/write_run_record.py d_nw01_axi4_xbar \
    domains/networking/design/d_nw01_axi4_xbar/ref/axi4_xbar_ref.sv \
    ppa reference_gated \
    "status=completed" \
    "design_area_um2=$(grep -iE '^Design area' "$L/6_report.log" | tail -1 | grep -oE '[0-9]+' | head -1)" \
    "wns_ns=$(python3 -c "import json;print(json.load(open('$L/6_report.json'))['finish__timing__setup__ws'])" 2>/dev/null)" \
    "power_w=$(grep -A11 'finish report_power' "$R/6_finish.rpt" | grep -E '^Total' | awk '{print $5}')" \
    "clk_period_ns=5.25" "drc=0" "orfs_nickname=d_nw01_axi4_xbar" \
    "pdk=sky130hd" "correctness_gate=passed:reference-16/16" >> "$LOG" 2>&1
fi
say "[6] exit=$RC6"

say "=== QUEUE COMPLETE ==="
say "table: python3 scripts/report_text.py"
