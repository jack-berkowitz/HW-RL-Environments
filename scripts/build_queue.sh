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

say "=== QUEUE START ==="
say "NOT queued, and why:"
say "  d_dsp02 -- both submissions are BYTE-IDENTICAL (same sha256), so at most"
say "    one model's answer is present, and both carry transport damage at line"
say "    388 ('1 me0' where a literal belongs). Needs re-pasting before scoring."
[ "$BIG_OK" = "1" ] || say "  d_nw01/chat PPA+Fmax -- daemon still at ${MEM_GB} GB; needs >= 8 GB (F31)."

# ---------------------------------------------------------------------------
say "[1] d_ca04/gemini Fmax sweep (seed 4.5 ns) -- fills an empty cell"
PYTHONUNBUFFERED=1 stdbuf -oL -eL python3 -u scripts/find_fmax.py \
  --design d_ca04_cand_gemini_own_fmax --seed-period-ns 4.5 \
  --max-bracket-iterations 4 --resolution-ns 0.5 --max-iterations 9 \
  --skip-sim-check >> "$LOG" 2>&1
say "[1] exit=$?"

# ---------------------------------------------------------------------------
say "[2] d_nw01 reference PPA at 5.25 ns (gated) -- removes the last pre-gate marker"
CLK_PERIOD_NS=5.2500 WIPE_DESIGN=d_nw01_axi4_xbar PLATFORM=sky130hd \
  stdbuf -oL -eL ./scripts/run_orfs_build.sh \
  /work/domains/networking/design/d_nw01_axi4_xbar/orfs/config.mk >> "$LOG" 2>&1
RC=$?
if [ "$RC" -eq 0 ]; then
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
say "[2] exit=$RC"

# ---------------------------------------------------------------------------
if [ "$BIG_OK" = "1" ]; then
  say "[3] d_nw01/chat PPA at 5.25 ns -- retry with ${MEM_GB} GB available"
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
    say "[4] SKIPPED -- the single PPA build did not complete, so a 9-iteration"
    say "    sweep of the same place-and-route would not either. F31: the cost of"
    say "    queueing a sweep whose every iteration fails is ~15 hours for nothing."
  fi
else
  say "[3,4] SKIPPED -- d_nw01/chat needs >= 8 GB, daemon reports ${MEM_GB} GB."
  say "    Docker Desktop's saved setting can be raised without the running"
  say "    daemon picking it up. Restart Docker Desktop, then re-run this queue."
fi

say "=== QUEUE COMPLETE ==="
say "table: python3 scripts/report_text.py"
