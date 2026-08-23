#!/bin/bash
# PC SWEEP QUEUE -- four Fmax sweeps. SWEEPS ONLY, NO COMMON-CLOCK REBUILDS.
#
# OWNERSHIP, AND WHY IT IS NARROW. The Mac takes the other three outstanding
# sweeps: d_dsp02/chat, d_dsp02/claude, d_ca01/chat. Do NOT add them here. The
# d_nw03 duplication cost about eight hours of wall time and produced numbers
# that were stale anyway.
#
# NO REBUILDS (rule 18). d_dsp02 and d_ca01 already have a scored configuration
# with every candidate built at it. Deriving a second common clock would put two
# configurations on a row that carries one.
#
# ONE CONTAINER PER HOST. These run strictly in sequence. d_nw01/chat already hit
# the 5.8 GB container ceiling, and nine sweeps died to a disk-full crash.
#
# WHY A SWEEP RATHER THAN A FIXED-CLOCK PROBE for d_dsp03/chat: it missed 46.875
# with WNS -3.211, so under rule 22 that cell currently has no reportable area or
# power at all. A single probe at 53.0 was an 80-minute guess that could miss and
# cost another 80. A sweep is a bounded binary search that converges AND leaves a
# passing build at the converged period -- it closes the timing gap and fills the
# Fmax column in one pass.
set -uo pipefail
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"; cd "$REPO"
export LEC_CHECK="${LEC_CHECK:-0}"   # kepler-formal is AVX-512; this host is not
LOG="$REPO/fmax_results/pcsweep_$(date +%Y%m%d_%H%M%S).log"
PLAN=0; [ "${1:-}" = "--plan" ] && PLAN=1
say () { echo "$(date '+%H:%M:%S') $*" | tee -a "$LOG"; }

FLOW="${ORFS_FLOW_DIR:-}"
if [ ! -f "$FLOW/Makefile" ] || [ ! -d "$FLOW/platforms" ]; then
  echo "ERROR: ORFS_FLOW_DIR is not a flow/ directory: '${FLOW:-<unset>}'" >&2; exit 2
fi

converged () {   # a sweep is done only if it CONVERGED, not if its file exists
  python3 - "$1" <<'PY'
import json, sys
try: d = json.load(open(sys.argv[1]))
except Exception: raise SystemExit(1)
raise SystemExit(0 if d.get("converged_period_ns") is not None
                      and not d.get("aborted_reason") else 1)
PY
}

buildable () {   # candidates/<task>/<model>.sv -> yes | no | stale
  python3 - "$1" <<'PY'
import glob, json, subprocess, sys
sub = sys.argv[1]; best = None
for f in glob.glob("runs/*/*__sim.json"):
    try: r = json.load(open(f))
    except Exception: continue
    if r.get("submission") != sub: continue
    if best is None or r.get("timestamp_utc","") >= best.get("timestamp_utc",""): best = r
if not best or best.get("all_passed") is not True:
    print("no"); raise SystemExit
task = best.get("task") or ""
d = glob.glob(f"domains/*/*/{task}")
if d:
    rr = subprocess.run(["python3","scripts/task_text_hash.py",d[0]],
                        capture_output=True, text=True)
    cur = rr.stdout.strip().split("\n")[0] if rr.returncode == 0 else None
    rh = best.get("task_text_hash")
    if cur and rh not in (None,"","unknown") and rh != cur:
        print("stale"); raise SystemExit
print("yes")
PY
}

# Reclaim ONLY against a converged sweep. Unconditional reclaim turns a failed
# extraction into a lost build -- the shape that cost the Mac three references.
flow_clean () {   # $1 = ORFS nickname
  local n="$1" d
  [ -n "$n" ] || return 0
  for d in results objects logs reports; do rm -rf "${FLOW}/${d}/sky130hd/${n}"; done
  say "  cleared flow outputs for ${n}"
}

sweep () {   # task, model, seed, nick
  local task="$1" model="$2" seed="$3" nick="$4"
  local cand="candidates/${task}/${model}.sv"
  local j="$REPO/fmax_results/${nick}_fmax.json"
  [ -f "$cand" ] || { say "MISSING $cand"; return 0; }
  local ok; ok="$(buildable "$cand")"
  [ "$ok" = "yes" ] || { say "SKIP $nick -- correctness gate: $ok"; return 0; }
  if converged "$j"; then say "SKIP $nick (already converged)"; return 0; fi
  [ -f "$j" ] && { say "REDO $nick -- previous attempt did not converge, discarding"; rm -f "$j"; }
  say "SWEEP $nick (seed ${seed}ns) <- ${cand}"
  [ "$PLAN" = "1" ] && return 0
  # stale-snapshot guard: compare the TRANSFORMED candidate (NBSP -> space plus a
  # trailing newline, as ppa_candidate.sh writes it), never the raw bytes
  local want have="" f
  want="$( { LC_ALL=C sed $'s/\xc2\xa0/ /g' "$cand"; printf '\n'; } | sha256sum | cut -d' ' -f1 )"
  if [ -f "orfs_runs/$nick/config.mk" ]; then
    for f in "orfs_runs/$nick"/*.sv; do
      [ -f "$f" ] || continue
      [ "$(sha256sum "$f" | cut -d' ' -f1)" = "$want" ] && { have=1; break; }
    done
  fi
  if [ -z "$have" ]; then
    say "  REGEN orfs_runs/$nick (snapshot missing or stale)"
    rm -rf "orfs_runs/$nick"
    bash scripts/ppa_candidate.sh "$task" "$cand" "${nick#${task}_cand_}" >>"$LOG" 2>&1 || true
  fi
  python3 scripts/find_fmax.py --design "$nick" --seed-period-ns "$seed" \
      --resolution-ns 0.5 --skip-sim-check >>"$LOG" 2>&1
  if converged "$j"; then
    say "  CONVERGED $nick -> $(python3 -c "import json;d=json.load(open('$j'));print(f\"{d['converged_period_ns']} ns / {d['achieved_fmax_mhz']} MHz, {d['total_pnr_runs']} runs, {round(d['total_wall_time_s']/60,1)} min\")")"
    flow_clean "$nick"
  else
    say "  DID NOT CONVERGE $nick -- keeping flow outputs for inspection"
  fi
}

say "=== PC SWEEP QUEUE START ==="
# seed 53.0: chat missed 46.875 by 3.211 ns, so 53.0 should PASS and bracket down
sweep d_dsp03 chat   53.0 d_dsp03_cand_chat_v2
# seed 45.0: claude closed 46.875 with +1.661 margin, so its Fmax is tighter
sweep d_dsp03 claude 45.0 d_dsp03_cand_claude_v2
# seed 10.0: the scored clock for d_ca01
sweep d_ca01  claude 10.0 d_ca01_cand_claude_v2
sweep d_ca01  gemini 10.0 d_ca01_cand_gemini_v2
say "=== PC SWEEP QUEUE DONE ==="
