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
  # WHICH checker failed is emitted as a marker line, because check_tree runs
  # inside a command substitution and cannot set a variable the caller sees.
  # The caller strips the markers and uses them to print advice that applies.
  ( cd "$d" && python3 scripts/check_rule_linkage.py 2>&1 )
  rc=$?
  [ $rc -ne 0 ] && echo "__FAILED__ rule_linkage"
  # A tree that PREDATES this check is not a failing tree. --audit walks history,
  # and treating "the checker did not exist yet" as a violation would report every
  # commit before it as broken -- which is how a gate earns a reputation for
  # crying wolf and gets bypassed.
  if [ -f "$d/scripts/check_witness_sync.py" ]; then
    ( cd "$d" && python3 scripts/check_witness_sync.py 2>&1 )
    if [ $? -ne 0 ]; then rc=1; echo "__FAILED__ witness_sync"; fi
  fi
  # THREE LOAD-BEARING CHECKERS WERE IN NO INVOCATION PATH AT ALL, and that is one
  # missing convention rather than three oversights. check_paste_sync guards the
  # prompt against its spec, check_pin guards a stated pin against its own sweep,
  # and check_unread_fields finds fields written and consulted by nothing. Each was
  # run only when somebody remembered.
  #
  # THE COST IS MEASURED, NOT HYPOTHETICAL. check_unread_fields' own header already
  # named configs_no_verdict as its CONCRETE BITE -- it had FOUND the field and
  # nothing acted on the finding. Eight days later that field still had no reader
  # and the table rendered "16 built, 0 build failures, 4 no verdict" as 0/16 FAIL.
  # Then I added expected_verdict with no reader in the same week I wrote the
  # detector, and the detector did not object because nobody ran it.
  #
  # An unwired checker is not a weaker gate. It is a record of a defect nobody
  # read -- the same shape as an unread field, one level up.
  # EACH EXIT CODE MEANS SOMETHING DIFFERENT AND THE GATE HAS TO HONOUR THAT.
  # My first wiring failed the gate on any non-zero, which made it fail on
  # INFORMATIONAL output -- check_unread_fields' own header calls its result "a
  # CANDIDATE LIST, NOT A VERDICT", and check_pin returns 2 for NO CONCLUSION,
  # which is a task whose sweep has not run rather than a task with a wrong pin.
  # A gate that blocks a commit on either is the "cries wolf and gets bypassed"
  # failure this file warns about three comments up, built in the same edit.
  #
  #   check_paste_sync   non-zero = the prompt disagrees with its spec   -> FAIL
  #   check_pin          1 = stated pin contradicts the sweep            -> FAIL
  #                      2 = NO CONCLUSION, no sweep to check against    -> report
  #   check_unread_fields  always report, never fail; a field being unread
  #                        is a candidate for a human, not a violation
  #   make_readme_tables --check  1 = README tables disagree with the records
  #                               2 = README and results_table.md disagree
  #                               both FAIL; the README is the published face
  #                               of the results and it drifted for two rounds
  #                               with nothing able to say so.
  if [ -f "$d/scripts/make_readme_tables.py" ]; then
    ( cd "$d" && python3 scripts/make_readme_tables.py --check 2>&1 )
    if [ $? -ne 0 ]; then rc=1; echo "__FAILED__ readme_tables"; fi
  fi
  if [ -f "$d/scripts/check_paste_sync.py" ]; then
    ( cd "$d" && python3 scripts/check_paste_sync.py 2>&1 )
    if [ $? -ne 0 ]; then rc=1; echo "__FAILED__ paste_sync"; fi
  fi
  if [ -f "$d/scripts/check_pin.py" ]; then
    ( cd "$d" && python3 scripts/check_pin.py 2>&1 )
    _pinrc=$?
    if [ $_pinrc -eq 1 ]; then rc=1; echo "__FAILED__ pin"; fi
  fi
  # check_unread_fields IS DELIBERATELY NOT HERE, and the reason is this gate's
  # own design. It prints nothing on success -- report_failure is the only path
  # that emits the body -- so a REPORT-ONLY checker wired here is swallowed in
  # exactly the case where it has something to say. It would run on every commit
  # and be invisible on every passing one, which is worse than not running it: it
  # would look wired.
  #
  # It belongs in an audit path with the slow checks, not in a commit gate. That
  # path does not exist yet and this comment is the record that it is owed --
  # which is the finding itself, one level up: a checker outside any invocation
  # path is a defect waiting to be rediscovered, and writing "it should be wired"
  # into a comment is how it stays that way. Named here so the next reader sees
  # the gap rather than assuming the list above is complete.
  # APPEND-ONLY DOCUMENTS MUST NOT LOSE A HEADING, and this is the only place a
  # check of that kind can be anchored correctly.
  #
  # MY OWN VERIFICATION HAD THE WRONG ANCHOR. Every commit this week ended with
  # `git show HEAD:$f | cmp - $f` -- the committed blob against the WORKING TREE.
  # That proves the commit is faithful to my last edit. It cannot prove the edit
  # did what I meant, because if the working tree was already truncated the
  # comparison passes on two copies of the damage. AGENT-VERIF-A2 lost 162
  # committed lines of their findings file to exactly that, and their per-blob
  # verification passed on the destroying commit.
  #
  #   anchored to the working tree     the commit matches my last edit
  #   anchored to the PREVIOUS COMMIT  my edit did what I meant
  #   anchored to nothing              one number compared to no other
  #
  # Only the middle row is a check on the change. This runs against the tree
  # being committed and compares it to HEAD, which is that row.
  #
  # Wired HERE rather than left in scripts/ because F96 counted nineteen checkers
  # and found two reachable from a scored run. A tool is not wired by living in
  # the tools directory; three of the unwired ones were mine, built the same day
  # I filed the finding about inert annotations.
  # The append-only check is NOT run here. check_tree extracts an arbitrary
  # tree-ish into a temp directory with no git repository in it, and this check
  # is inherently a COMPARISON BETWEEN TWO REFS -- there is nothing to compare
  # against inside an extracted tree. It runs in the --staged branch, where the
  # index and HEAD both exist. A check placed where it cannot see its own
  # reference point would run, pass, and mean nothing: the third row of the table
  # below.
  rm -rf "$d"
  return $rc
}

short () { git -C "$REPO" rev-parse --short "$1" 2>/dev/null || echo "$1"; }

# WHAT THIS FUNCTION EXISTS TO PREVENT
# ------------------------------------
# Every failure used to end with the same two paragraphs -- "the usual cause is
# committing a finding without the rule it cites ... stage both", then the
# LINKAGE_OVERRIDE instructions -- whatever had actually failed. A reader
# reported reading exactly those lines, seeing the commit succeed, and shipping
# a mutant with no witness: the informative output was four lines from the top
# and the last line said something about rules and findings that was not true of
# their failure and pointed at the wrong file.
#
# A TRAILING LINE THAT DOES NOT VARY WITH THE OUTCOME TRAINS THE READER TO STOP
# READING IT. That is a property of the tool, not of the reader, and no amount
# of "read the whole output" fixes an output whose last line is uninformative by
# construction -- the last line is where the eye lands.
#
# So: generic remedies print only when they apply, and the LAST line names THIS
# run's cause. It also names WHICH TREE was read, because this script reads the
# COMMITTED tree by default -- a reader fixed a defect, re-ran, saw it still
# fail, and briefly concluded the fix had not worked, when the check was reading
# a tree the fix was not in. A check whose scope you have not established is a
# check whose answer you cannot interpret.
report_failure () {   # $1 = checker output (with markers)  $2 = what was read
  local out="$1" what="$2" body fails
  fails="$(printf '%s\n' "$out" | sed -n 's/^__FAILED__ //p' | tr '\n' ' ')"
  body="$(printf '%s\n' "$out" | grep -v '^__FAILED__ ')"
  echo "CHECK FAILED on $what:"
  printf '%s\n' "$body" | sed 's/^/  /'
  case " $fails " in
    *" rule_linkage "*)
      echo
      echo "The usual cause of a RULE/FINDING failure is committing a finding"
      echo "without the rule it cites, or a rule without its finding. They are"
      echo "ONE UNIT -- stage both."
      echo
      echo "To proceed anyway, re-run with a reason and paste the trailer:"
      echo "    LINKAGE_OVERRIDE=\"why\" $0 ${1:+--staged}" ;;
  esac
  echo
  # THE LAST LINE. It names what failed in THIS run and nothing else.
  case " $fails " in
    *" rule_linkage "*" witness_sync "*|*" witness_sync "*" rule_linkage "*)
      echo "FAILED: rule/finding linkage AND witness sync, on $what." ;;
    *" append_only "*)
      echo "FAILED: APPEND-ONLY on $what -- a heading disappeared from a document"
      echo "        that is only ever added to. A growing file hides a destructive"
      echo "        edit from every size check; the heading count is the one signal"
      echo "        it cannot hide. Pass --allow-drop with the exact heading if the"
      echo "        removal is deliberate, so the decision lands in the artefact." ;;
    *" witness_sync "*)
      echo "FAILED: WITNESS SYNC on $what -- a mutant or rule-24 control has no"
      echo "        witness recorded in its task.yaml. This is NOT a rule/finding"
      echo "        problem and RULES.md/FINDINGS.md are not the files to look at." ;;
    *" rule_linkage "*)
      echo "FAILED: RULE/FINDING LINKAGE on $what -- see the lines above for the"
      echo "        specific rule or finding whose counterpart is missing." ;;
    *)
      echo "FAILED on $what -- see the output above; no checker reported which," ;;
  esac
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
          # the __FAILED__ markers are for report_failure, not for a reader
          _f="$(printf '%s\n' "$out" | sed -n 's/^__FAILED__ //p' | tr '\n' ' ')"
          printf '               (failed: %s)\n' "${_f:-unspecified}"
          printf '%s\n' "$out" | grep -v '^__FAILED__ ' | sed 's/^/               /'
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
    # APPEND-ONLY, AND MY OWN VERIFICATION HAD THE WRONG ANCHOR ALL WEEK.
    # Every commit ended with `git show HEAD:$f | cmp - $f` -- the committed blob
    # against the WORKING TREE. That proves the commit is faithful to my last
    # edit. It cannot prove the edit did what I meant, because if the working
    # tree was already truncated the comparison passes on two copies of the
    # damage. AGENT-VERIF-A2 lost 162 committed lines of their findings file to
    # exactly that shape, and their per-blob verification passed on the
    # destroying commit.
    #
    #   anchored to the working tree     the commit matches my last edit
    #   anchored to the PREVIOUS COMMIT  my edit did what I meant
    #   anchored to nothing              one number compared to no other
    #
    # Only the middle row is a check on the change. --staged is that row: the
    # index against HEAD.
    #
    # Wired here rather than left sitting in scripts/ because F96 counted
    # nineteen checkers and two reachable from a scored run. A tool is not wired
    # by living in the tools directory, and three of the unwired ones were mine.
    # A MISSING DEPENDENCY IS A REFUSAL, NOT A SKIP. This was
    # `if [ -f ... ]; then` with NO else, so a clone where nobody landed the
    # script and a clone where the check ran and passed printed byte-identical
    # `ok`. That is the defect this whole file is about -- declaring nothing,
    # refusing nothing -- sitting inside the guard whose own header carries the
    # anchoring table. Found by AGENT-DESIGN-43a92055.
    if [ ! -f "$REPO/scripts/check_append_only.py" ]; then
      echo "NO CONCLUSION -- scripts/check_append_only.py is not present, so the"
      echo "append-only invariant was NOT checked. That is not the same as clean."
      echo "Restore it, or say explicitly that you are proceeding without it."
      exit 2
    fi
    # NO FILENAMES HERE, DELIBERATELY. The list used to be four names written
    # inline on this line, and it went stale silently: docs/ documents and every
    # MEASUREMENTS.md were outside it, so their appends passed only when someone
    # ran the checker by hand. The set is declared in check_append_only.py, next
    # to the code that says what append-only means, and adding a document is a
    # one-line edit there rather than a change to this caller.
    if true; then
      if ! ao="$(cd "$REPO" && python3 scripts/check_append_only.py --staged 2>&1)"; then
        echo "APPEND-ONLY REFUSED, on the tree the index would commit:"
        printf '%s\n' "$ao" | sed 's/^/  /'
        echo
        echo "A heading disappeared from a document that is only added to. A"
        echo "growing file hides a destructive edit from every size check; the"
        echo "heading count is the one signal it cannot hide."
        echo "If deliberate, re-run check_append_only.py with --allow-drop and the"
        echo "exact heading, so the decision lands in the artefact rather than in"
        echo "your head."
        exit 1
      fi
    fi
    tree="$(git -C "$REPO" write-tree)" || { echo "cannot write-tree"; exit 2; }
    if out="$(check_tree "$tree")"; then
      echo "ok -- read THE TREE THE INDEX WOULD COMMIT (tree $(short "$tree"))"
      exit 0
    fi
    report_failure "$out" "the tree the index would commit (tree $(short "$tree"))"
    if [ -n "${LINKAGE_OVERRIDE:-}" ]; then
      echo
      echo "Override accepted. PASTE THIS INTO THE COMMIT MESSAGE -- this script"
      echo "cannot write it for you, and --audit reports a failing tree without"
      echo "it as unexplained:"
      echo
      echo "    $TRAILER ${LINKAGE_OVERRIDE}"
      exit 0
    fi
    exit 1 ;;
  *)
    if out="$(check_tree "$1")"; then
      echo "ok -- read THE COMMITTED TREE at $1 ($(short "$1"))"
      exit 0
    fi
    report_failure "$out" "the committed tree at $1 ($(short "$1"))"
    exit 1 ;;
esac
