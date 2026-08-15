#!/bin/bash
# Run the full gate over many submissions -- the cross-model fan-out.
#
#   ./scripts/run_submissions.sh                     every task, every submission, sim only
#   ./scripts/run_submissions.sh --ppa               ... and place-and-route each one
#   ./scripts/run_submissions.sh d_ca04              one task
#   ./scripts/run_submissions.sh d_ca04 d_nw01 --ppa
#
# "One row per model per task" falls out of the layout: a submission lives at
# candidates/<task_id>/<label>.sv and the label carries the model identity, so
# the run records are already keyed the right way. This script is orchestration
# and a safety interlock -- it adds no measurement of its own.
#
# WHAT IT DOES NOT DO. It does not call a model API. Submissions are placed in
# candidates/<task>/ by hand or by whatever produced them, and this runs the
# gate over what is there. Soliciting and evaluating are deliberately separate:
# a re-run must never depend on a model being reachable, and an evaluation must
# be reproducible from files in the repo.
set -u

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO" || exit 2

DO_PPA=0
TASKS=()
for a in "$@"; do
  case "$a" in
    --ppa) DO_PPA=1 ;;
    --*)   echo "unknown argument: $a" >&2; exit 2 ;;
    *)     TASKS+=("$a") ;;
  esac
done

# Every task with a candidates/ directory, if none named.
if [ "${#TASKS[@]}" -eq 0 ]; then
  for d in candidates/*/; do
    t="$(basename "$d")"
    [ "$t" = "README.md" ] && continue
    ls "$d"*.sv >/dev/null 2>&1 && TASKS+=("$t")
  done
fi
[ "${#TASKS[@]}" -gt 0 ] || { echo "no tasks with submissions under candidates/" >&2; exit 2; }

# --- INTERLOCK ---------------------------------------------------------------
# An ORFS build already running means a sweep or another evaluation is using the
# shared flow directory. Starting a second one corrupts both: ORFS keys its
# output on DESIGN_NICKNAME and two builds of the same design overwrite each
# other's reports. This is the same shared-mutable-state defect that made the
# results table report a stale row, so it is refused rather than warned about.
if [ "$DO_PPA" = "1" ] && docker ps --format '{{.Image}}' 2>/dev/null | grep -q 'orfs'; then
  echo "REFUSED: an ORFS container is already running." >&2
  echo "  A concurrent build shares the flow directory and the two overwrite each" >&2
  echo "  other's reports. Wait for it to finish, or re-run without --ppa." >&2
  exit 2
fi

echo "tasks:       ${TASKS[*]}"
echo "place-and-route: $([ "$DO_PPA" = 1 ] && echo yes || echo 'no (--ppa to enable)')"
echo

NSUB=0; NOK=0
for task in "${TASKS[@]}"; do
  subs=()
  for f in candidates/"$task"/*.sv; do [ -f "$f" ] && subs+=("$f"); done
  [ "${#subs[@]}" -gt 0 ] || { echo "$task: no submissions"; continue; }

  echo "================ $task (${#subs[@]} submission(s)) ================"
  for f in "${subs[@]}"; do
    NSUB=$((NSUB+1))
    label="$(basename "$f" .sv)"
    echo "---- $task / $label ----"
    if ./scripts/sim_candidate.sh "$task" "$f"; then
      NOK=$((NOK+1))
      if [ "$DO_PPA" = "1" ]; then
        # PPA only for a submission that passed correctness. A PPA number for a
        # design that fails its contract is not a result, and producing one
        # invites it being quoted next to numbers that are.
        ./scripts/ppa_candidate.sh "$task" "$f" "$label" || \
          echo "  note: place-and-route did not complete for $label -- recorded as such"
      fi
    else
      echo "  correctness gate failed; place-and-route skipped"
    fi
    echo
  done
done

echo "================================================================================"
echo "$NOK of $NSUB submission(s) passed the correctness gate."
echo
echo "Results are in the immutable run records under runs/. To see the table:"
echo "    python3 scripts/collect_results.py            # one row per task per submission"
echo "    python3 scripts/collect_results.py --metrics  # with capability numbers"
echo
echo "Collection is NOT run automatically here: it reads run records, and running it"
echo "mid-fan-out would report a partial sweep as though it were complete."
