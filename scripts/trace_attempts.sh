#!/bin/bash
# Collect INDEPENDENT Claude Code attempts at a design task, with the model's
# reasoning and tool calls recorded.
#
#   ./scripts/trace_attempts.sh d_dsp03 10 ~/dsp03_traces
#
# Each attempt runs in its own scratch directory OUTSIDE this repo, gets only
# the task's probe/PASTE.md, and is scored afterwards by the normal path.
#
# WHY OUTSIDE THE REPO. `claude -p` without --bare loads CLAUDE.md, hooks, auto
# memory, MCP servers and plugins from the working directory and ~/.claude --
# that is exactly what makes it bill the SUBSCRIPTION rather than an API key.
# Run it in this repo and the model inherits the benchmark's own context and can
# read ref/ with Bash, which is the answer key. A clean directory keeps the
# subscription billing and removes the leak.
#
# WHAT THE MODEL IS NOT GIVEN: the scoring testbench (tb/), the reference (ref/),
# the mutants or the controls. It gets the same PASTE.md a solicited model gets,
# and Verilator. Writing its own testbench is the work.
set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TASK="${1:-}"; N="${2:-}"; OUT="${3:-}"
if [ -z "$TASK" ] || [ -z "$N" ] || [ -z "$OUT" ]; then
  echo "usage: $0 <task> <n_attempts> <output_dir>" >&2
  echo "   eg: $0 d_dsp03 10 ~/dsp03_traces" >&2
  exit 2
fi

# ---- preflight. Every one of these is a way the run silently produces nothing.
fail=0
command -v claude >/dev/null   || { echo "MISSING: claude CLI not on PATH"; fail=1; }
command -v verilator >/dev/null|| { echo "MISSING: verilator not on PATH"; fail=1; }
TASKDIR="$(ls -d "$REPO"/domains/*/design/"${TASK}"_* 2>/dev/null | head -1)"
[ -n "$TASKDIR" ] || { echo "MISSING: no task dir for '$TASK'"; fail=1; }
PASTE="$TASKDIR/probe/PASTE.md"
[ -f "$PASTE" ] || { echo "MISSING: $PASTE"; fail=1; }
case "$OUT" in "$REPO"|"$REPO"/*) echo "REFUSING: output dir is inside the repo -- attempts must run outside it"; fail=1;; esac
[ "$fail" = 0 ] || exit 1

# ---- AUTH, BEFORE ANY ATTEMPT. Eleven attempts once ran and failed in 72ms
# each with "Not logged in - Please run /login", reporting as eleven model
# failures: rc=1, no submission, zero thinking blocks, and a clean contamination
# scan. Every one of those readings was true and none of them was about the
# model. One cheap call up front, and the run refuses rather than producing a
# directory of confident-looking nothing.
probe_json="$(cd /tmp && claude -p "ok" --output-format json 2>/dev/null)"
if printf '%s' "$probe_json" | python3 -c "
import json,sys
try: e=json.load(sys.stdin)
except Exception: print('unparseable'); raise SystemExit(1)
raise SystemExit(0 if e.get('is_error') else 1)" 2>/dev/null; then
  echo "REFUSING: the claude CLI is not usable. Its reply was:"
  printf '%s' "$probe_json" | python3 -c "
import json,sys
try: print('   ', json.load(sys.stdin).get('result'))
except Exception: print('    (no parseable result)')"
  echo "  If it says 'Not logged in', run 'claude' once interactively and /login."
  exit 1
fi
echo "auth     : ok"

# REASONING DEPTH. Claude Code has no --thinking flag; --effort is the control,
# and at the default a short task may emit no thinking blocks at all. These
# traces exist to show the reasoning, so the depth is set deliberately rather
# than inherited. Override with EFFORT=max.
EFFORT="${EFFORT:-high}"

# PIN THE MODEL. Left unset, a headless run picked up claude-opus-5[1m], the
# 1M-context variant, and its thinking blocks came back with an empty `thinking`
# field and a 373,876-character signature. Every session on this machine that
# DID record reasoning text -- eight of them, 247k to 1,098k characters -- ran
# plain claude-opus-5. The [1m] variant is the only thing separating them.
# Correlation, not documentation, but it is the one variable that differs and it
# is free to test. Override with MODEL=.
MODEL="${MODEL:-opus}"

# OUTPUT CAP. Thinking tokens count toward the output budget, so high effort on
# a 590-line spec hits the 64,000 default and the run dies with
# "Claude's response exceeded the 64000 output token maximum" -- after minutes of
# work, with nothing written. Raised here; override with MAX_OUT.
export CLAUDE_CODE_MAX_OUTPUT_TOKENS="${MAX_OUT:-200000}"

DUT="$(grep -m1 -E '^(module|dut_module|synthesis_top):' "$TASKDIR/task.yaml" | awk '{print $2}')"
[ -n "$DUT" ] && DUT="$DUT" || DUT="(not declared in task.yaml)"
echo "task     : $TASK  ($(basename "$TASKDIR"))"
echo "module   : $DUT"
echo "prompt   : $PASTE  ($(wc -c < "$PASTE" | tr -d ' ') bytes)"
echo "model    : $MODEL"
echo "max out  : $CLAUDE_CODE_MAX_OUTPUT_TOKENS tokens"
echo "effort   : $EFFORT"
echo "attempts : $N"
echo "output   : $OUT"
mkdir -p "$OUT"

for i in $(seq 1 "$N"); do
  i=$(printf '%02d' "$i")      # seq -w pads by the WIDTH OF N, so n=1 gave
                               # attempt_1 and n=10 gave attempt_01..10 -- the
                               # same attempt under two names, and the rerun
                               # made a duplicate instead of skipping.
  d="$OUT/attempt_$i"
  if [ -e "$d" ]; then echo "[$i] exists, skipping"; continue; fi
  mkdir -p "$d/work"
  cp "$PASTE" "$d/work/TASK.md"
  echo "[$i] running..."
  ( cd "$d/work" && claude -p "$(cat TASK.md)

Write your final answer to a file named submission.sv in this directory. \
Verilator is available if you want to compile or test your work." \
      --model "$MODEL" --effort "$EFFORT" \
      --output-format stream-json --verbose --include-partial-messages \
      --allowedTools "Write,Read,Edit,Bash" \
      --permission-mode acceptEdits \
  ) > "$d/trace.jsonl" 2> "$d/stderr.log"
  rc=$?
  echo "$rc" > "$d/exit_code"

  # ---- THE SESSION TRANSCRIPT IS THE TRACE, NOT STDOUT. Measured on this
  # machine: a `claude -p` stdout stream carried only text blocks, while an
  # interactive session's transcript under ~/.claude/projects held 51 thinking
  # blocks beside 163 tool_use. stdout is a delivery channel; the transcript is
  # the record. Located by session id across all project dirs rather than by
  # rebuilding Claude Code's path encoding, which mangles _ . and / alike.
  sid=$(python3 - "$d/trace.jsonl" <<'PYEOF'
import json,sys
sid=""
for ln in open(sys.argv[1],errors="replace"):
    try: e=json.loads(ln)
    except Exception: continue
    sid=e.get("session_id") or sid
print(sid)
PYEOF
)
  if [ -n "$sid" ]; then
    src=$(ls "$HOME"/.claude/projects/*/"$sid".jsonl 2>/dev/null | head -1)
    [ -n "$src" ] && cp "$src" "$d/session.jsonl" && echo "$sid" > "$d/session_id"
  fi

  # ---- contamination scan. A trace that reached the repo measures nothing.
  # SCAN THE READABLE FIELDS, NOT THE RAW BYTES. Grepping whole lines
  # case-insensitively flagged a clean run CONTAMINATED on a single "/Tb/" that
  # occurred inside a base64 signature -- thinking blocks carry 189KB of base64
  # each, so a three-character pattern appearing by chance is not unlikely, it is
  # expected. A false CONTAMINATED discards a good attempt; a false clean ships a
  # leaked reference. Parse, then scan only text, thinking, tool inputs and tool
  # results, which are the only places a real leak can appear.
  python3 - "$d/trace.jsonl" "$d/session.jsonl" > "$d/STATUS" <<'PYEOF'
import json,re,sys,os
pat=re.compile(r"hw_rl_benchmark|fp_multifmt_fma_ref|/ref/|/tb/|/mutants/|/controls/",re.I)
hits=[]
def walk(v):
    if isinstance(v,str):
        m=pat.search(v)
        if m: hits.append(v[max(0,m.start()-60):m.start()+60])
    elif isinstance(v,list):
        for x in v: walk(x)
    elif isinstance(v,dict):
        for k,x in v.items():
            if k in ("signature","data"): continue      # opaque base64, not prose
            walk(x)
for p in sys.argv[1:]:
    if not os.path.isfile(p): continue
    for ln in open(p,errors="replace"):
        ln=ln.strip()
        if not ln: continue
        try: e=json.loads(ln)
        except Exception: continue
        for b in (e.get("message") or {}).get("content") or []:
            if isinstance(b,dict) and b.get("type") in ("text","thinking","tool_use","tool_result"):
                walk({k:v for k,v in b.items() if k!="signature"})
print("CONTAMINATED" if hits else "clean")
if hits: print(hits[0], file=sys.stderr)
PYEOF
  if [ "$(cat "$d/STATUS")" = "CONTAMINATED" ]; then
    echo "[$i] *** CONTAMINATED -- trace references the benchmark repo, do not use ***"
  fi

  if [ -f "$d/work/submission.sv" ]; then
    cp "$d/work/submission.sv" "$d/submission.sv"
    echo "[$i] rc=$rc  submission.sv $(wc -l < "$d/submission.sv" | tr -d ' ') lines  $(cat "$d/STATUS")"
  else
    echo "[$i] rc=$rc  NO submission.sv produced  $(cat "$d/STATUS")"
  fi
done

echo
echo "=== summary ==="
for d in "$OUT"/attempt_*; do
  [ -d "$d" ] || continue
  n=$(basename "$d")
  # PARSED, NOT GREPPED. A byte-pattern like '"type":"thinking"' fails on any
  # whitespace or key-order the emitter chooses, and reports 0 -- which reads as
  # "the model did not think" when it means "the probe did not match". This
  # counts content blocks by type from the parsed JSON.
  # Prefer the session transcript; stdout is a fallback that under-reports.
  # trace.jsonl FIRST. The assembled thinking blocks in both the stream and the
  # transcript carry an empty `thinking` field and a large signature -- measured
  # 373,876 signature chars against 0 text chars. If the reasoning text exists
  # anywhere it is in the partial-message thinking_delta events, which only the
  # stdout stream carries.
  rec="$d/trace.jsonl"; [ -s "$rec" ] || rec="$d/session.jsonl"
  read -r th tu tx <<<"$(python3 - "$rec" <<'PYEOF'
import json,sys,collections
c=collections.Counter()
for ln in open(sys.argv[1],errors="replace"):
    ln=ln.strip()
    if not ln: continue
    try: ev=json.loads(ln)
    except Exception: continue
    msg=ev.get("message") or {}
    for b in (msg.get("content") or []):
        if isinstance(b,dict): c[b.get("type")]+=1
    inner=ev.get("event") or {}
    d=(inner.get("delta") or {})
    if d.get("type")=="thinking_delta": c["think_text"]+=len(d.get("thinking") or "")
    for b in (msg.get("content") or []):
        if isinstance(b,dict) and b.get("type")=="thinking":
            c["think_text"]+=len(b.get("thinking") or "")
print(c.get("thinking",0)+c.get("redacted_thinking",0), c.get("tool_use",0), c.get("think_text",0))
PYEOF
)"
  sub=$([ -f "$d/submission.sv" ] && echo yes || echo NO)
  printf "  %-12s thinking=%-4s reasoning_chars=%-8s tools=%-4s submission=%-4s %s\n" \
         "$n" "$th" "$tx" "$tu" "$sub" "$(cat "$d/STATUS" 2>/dev/null)"
done
echo
echo "Next: score them with"
echo "  for d in $OUT/attempt_*; do [ -f \"\$d/submission.sv\" ] && \\"
echo "    $REPO/scripts/sim_candidate.sh $TASK \"\$d/submission.sv\"; done"
