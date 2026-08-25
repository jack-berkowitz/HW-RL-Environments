#!/usr/bin/env bash
# Assert that a COMMIT'S RESULTING TREE passes the document-level checks:
# check_rule_linkage.py (rule/finding graph) and check_witness_sync.py
# (structural: every mutant has a witness, every rule-24 control recorded).
#
# WHY A TREE AND NOT A FILE STATE
# -------------------------------
# check_rule_linkage.py enforces a BIDIRECTIONAL invariant across RULES.md and
# FINDINGS.md: every finding cites a rule that exists, every rule cites a finding
# that exists. Any commit boundary cutting between a finding and the rule it
# cites yields a tree that fails its own check -- however carefully either half
# was staged, attributed, or diff-checked. That is d6d3423, which was all three
# and still broke the invariant.
#
# So this refuses to look at whether a file is "dirty". An uncommitted change to
# RULES.md that does not break linkage is not a reason to block anything, and a
# check that fires on file state rather than on the invariant will fire on
# unrelated edits and be routed around within a week. It builds the tree you
# would actually create and runs the REAL checker against it -- not a
# reimplementation, which would drift from the thing it is supposed to mirror.
#
# THE HOOK IS A CONVENIENCE. THE AUDIT IS THE CHECK.
# --------------------------------------------------
# --staged can be wired to a pre-commit hook, and that covers ordinary
# `git commit`. It does NOT cover `git commit --no-verify`, it does not cover a
# clone where nobody installed the hook (.git/hooks is not versioned), and most
# importantly it does not cover `git commit-tree` + `git update-ref` -- which
# runs no hooks at all and IS THE PATH THAT PRODUCED d6d3423. The gate would
# have missed the one instance we have.
#
# --audit reads what actually happened and cannot be routed around. Run it over
# origin/main..HEAD before pushing; that is the authoritative check.
#
# Usage:
#   check_linkage_tree.sh --staged            # the tree the index would commit
#   check_linkage_tree.sh <tree-ish>          # any commit or tree
#   check_linkage_tree.sh --audit <range>     # every commit in a range
#
# Override (never silent):
#   LINKAGE_OVERRIDE="reason" check_linkage_tree.sh --staged
# prints the trailer to paste into the commit message. --audit reports a failing
# tree WITHOUT that trailer as UNEXPLAINED.
set -uo pipefail
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TRAILER="LINKAGE-OVERRIDE:"

check_tree () {   # $1 = tree-ish; echoes checker output; returns its status
  local t="$1" d rc
  d="$(mktemp -d)"
  git -C "$REPO" archive "$t" 2>/dev/null | tar -x -C "$d" 2>/dev/null || {
    echo "cannot extract tree $t"; rm -rf "$d"; return 2; }
  # Two document-level invariants, both cheap enough for a commit gate:
  #   check_rule_linkage.py    the rule/finding graph, both directions
  #   check_witness_sync.py    every mutant has a witness, every control is
  #                            recorded (rule 24's second half)
  # check_witness_sync.py runs in its STRUCTURAL mode here. Its --fresh mode
  # re-runs every witness runner and is the one that can catch a string that is
  # stale rather than missing; that takes tens of minutes and belongs in the
  # audit path, not in a gate. Same split, and the same reason, as this file's
  # own: a gate too slow to run gets routed around.
  ( cd "$d" && python3 scripts/check_rule_linkage.py 2>&1 )
  rc=$?
  # A tree that PREDATES this check is not a failing tree. --audit walks history,
  # and treating "the checker did not exist yet" as a violation would report every
  # commit before it as broken -- which is how a gate earns a reputation for
  # crying wolf and gets bypassed.
  if [ -f "$d/scripts/check_witness_sync.py" ]; then
    ( cd "$d" && python3 scripts/check_witness_sync.py 2>&1 )
    [ $? -ne 0 ] && rc=1
  fi
  rm -rf "$d"
  return $rc
}

case "${1:---staged}" in
  --audit)
    range="${2:?usage: --audit <range>}"
    bad=0; n=0
    for c in $(git -C "$REPO" rev-list --reverse "$range"); do
      n=$((n+1))
      short="$(git -C "$REPO" rev-parse --short "$c")"
      subj="$(git -C "$REPO" log -1 --format=%s "$c" | cut -c1-52)"
      if out="$(check_tree "$c")"; then
        printf '  ok         %s  %s\n' "$short" "$subj"
      else
        if git -C "$REPO" log -1 --format=%B "$c" | grep -q "^$TRAILER"; then
          why="$(git -C "$REPO" log -1 --format=%B "$c" | grep "^$TRAILER" | head -1)"
          printf '  OVERRIDDEN %s  %s\n             %s\n' "$short" "$subj" "$why"
        else
          printf '  BROKEN     %s  %s\n' "$short" "$subj"
          echo "$out" | sed 's/^/               /'
          bad=$((bad+1))
        fi
      fi
    done
    echo
    if [ "$bad" -eq 0 ]; then
      echo "$n commit(s) audited; every tree passes linkage or carries a recorded override."
      exit 0
    fi
    echo "$n commit(s) audited; $bad with a BROKEN tree and no $TRAILER trailer."
    echo "A broken tree is not fixed by a later commit -- the tree that was"
    echo "published still fails its own check for anyone who fetched it."
    exit 1 ;;
  --staged)
    tree="$(git -C "$REPO" write-tree)" || { echo "cannot write-tree"; exit 2; }
    if out="$(check_tree "$tree")"; then
      echo "linkage ok for the tree the index would commit"
      exit 0
    fi
    echo "LINKAGE WOULD BREAK IN THE COMMITTED TREE:"
    echo "$out" | sed 's/^/  /'
    echo
    echo "The usual cause is committing a finding without the rule it cites, or"
    echo "a rule without its finding. They are ONE UNIT -- stage both."
    if [ -n "${LINKAGE_OVERRIDE:-}" ]; then
      echo
      echo "Override accepted. PASTE THIS INTO THE COMMIT MESSAGE -- this script"
      echo "cannot write it for you, and --audit reports a failing tree without"
      echo "it as unexplained:"
      echo
      echo "    $TRAILER ${LINKAGE_OVERRIDE}"
      exit 0
    fi
    echo
    echo "To proceed anyway, re-run with a reason and paste the trailer it prints:"
    echo "    LINKAGE_OVERRIDE=\"why\" $0 --staged"
    exit 1 ;;
  *)
    if out="$(check_tree "$1")"; then echo "linkage ok for $1"; exit 0; fi
    echo "LINKAGE BROKEN in $1:"; echo "$out" | sed 's/^/  /'; exit 1 ;;
esac
