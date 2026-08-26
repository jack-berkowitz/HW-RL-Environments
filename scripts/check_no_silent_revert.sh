#!/usr/bin/env bash
# Refuse a push that silently returns a file to an older committed state.
#
# WHAT THIS CATCHES, and it is not hypothetical. A commit made from a working
# copy that predated someone else's fix will happily re-commit the old content.
# Git records it as an ordinary change -- there is no conflict, no warning, and
# the diff looks like authorship rather than loss. 537700e replaced the README's
# design results with the "withheld pending re-solicitation" text it had carried
# two commits earlier, and it reached origin. It was found by a person reading
# the published file.
#
# Five times in one day, stale state in a working copy silently undid committed
# work. Four were caught in the INDEX before a commit was taken, by the
# explicit-path protocol -- temp index, read-tree HEAD, name every path,
# cmp-verify. That protocol does nothing here, because it protects against
# committing the wrong INDEX, not against committing from a different COPY of
# the tree. The gap was never containment. It was detection.
#
# THE TEST: for every file the range touches, does its NEW content byte-match a
# PREVIOUS committed state of that same file? Forward progress essentially never
# reproduces an earlier blob exactly. A revert does, every time.
#
# IT IS NOT A BAN. A deliberate revert is legitimate and this is not trying to
# out-argue the author -- it exists so that a revert is a decision rather than an
# accident. Set REVERT_OK with a reason to proceed; the reason is printed and is
# meant for the commit message.
#
#   usage:  check_no_silent_revert.sh [range]     default: origin/main..HEAD
#           REVERT_OK="why" check_no_silent_revert.sh
set -uo pipefail
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO" || exit 2
RANGE="${1:-origin/main..HEAD}"
DEPTH="${REVERT_SCAN_DEPTH:-40}"

# WHICH FILES. Defaults to the artefacts where a silent revert is expensive and
# invisible: the shared documents, the published table, and scripts/. A reverted
# candidate .sv is caught by its sha256 in the run records; a reverted README is
# caught by nobody.
matches_scope () {
  case "$1" in
    README.md|FINDINGS.md|RULES.md|CONVENTIONS.md|TASK_CATALOG.md|results_table.md) return 0 ;;
    scripts/*) return 0 ;;
    *) [ -n "${REVERT_SCAN_ALL:-}" ] && return 0 || return 1 ;;
  esac
}

if ! git rev-parse "${RANGE%%..*}" >/dev/null 2>&1; then
  echo "NO CONCLUSION -- '${RANGE%%..*}' does not resolve, so no range was scanned." >&2
  echo "That is not the same as 'no reverts found'." >&2
  exit 2
fi

tip="${RANGE##*..}"; [ -z "$tip" ] && tip=HEAD
files="$(git diff --name-only "$RANGE" 2>/dev/null)"
[ -z "$files" ] && { echo "no files in $RANGE; nothing to check"; exit 0; }

found=0; scanned=0
while IFS= read -r f; do
  [ -n "$f" ] || continue
  matches_scope "$f" || continue
  new="$(git rev-parse "$tip:$f" 2>/dev/null)" || continue
  scanned=$((scanned+1))
  base="${RANGE%%..*}"
  # walk this file's history BEFORE the range and look for the same blob
  while IFS= read -r c; do
    [ -n "$c" ] || continue
    old="$(git rev-parse "$c:$f" 2>/dev/null)" || continue
    if [ "$old" = "$new" ]; then
      echo "SILENT REVERT: $f"
      echo "    the content being pushed is byte-identical to an EARLIER state:"
      echo "      $(git log -1 --format='%h %ad  %s' --date=format:'%m-%d %H:%M' "$c" | cut -c1-100)"
      echo "    and differs from the state it is replacing:"
      echo "      $(git log -1 --format='%h %ad  %s' --date=format:'%m-%d %H:%M' "$base" -- "$f" | cut -c1-100)"
      found=$((found+1))
      break
    fi
  done < <(git log --format=%H -"$DEPTH" "$base" -- "$f" 2>/dev/null | tail -n +2)
done <<< "$files"

echo
if [ "$found" -eq 0 ]; then
  echo "ok -- $scanned in-scope file(s) checked over $RANGE; none returns to an earlier committed state."
  exit 0
fi
echo "$found file(s) in $RANGE return to an earlier committed state."
if [ -n "${REVERT_OK:-}" ]; then
  echo "REVERT_OK is set, so this is recorded as deliberate:"
  echo "    ${REVERT_OK}"
  echo "Put that reason in the commit or push message -- this script cannot."
  exit 0
fi
echo "If that is deliberate, re-run with a reason:"
echo "    REVERT_OK=\"why\" $0 $RANGE"
echo "A revert should be a decision. This exists so it cannot be an accident."
exit 1
