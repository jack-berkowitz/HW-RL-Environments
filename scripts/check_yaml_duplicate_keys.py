#!/usr/bin/env python3
"""REFUSE a duplicate key anywhere in any task.yaml.

WHY THIS IS NOT A LINT.

A duplicate key is valid YAML. No parser errors on it. But the readers pointed
at these files resolve it in OPPOSITE DIRECTIONS:

    scripts/mutant_evidence.py   regex, FIRST match wins
    scripts/report_table.py      re.search, FIRST match wins
    any real YAML parser         LAST key wins

Measured on `d_ca01`'s duplicated `mutants:` before it was repaired -- same file,
same moment:

    mutant_evidence.py  ->  7 mutants, every cex_depth
    a YAML parser       ->  status: NOT_STARTED

Neither warns. The repository is currently correct BY ACCIDENT OF TOOLING:
pyyaml is not installed here, so everything reads first-wins. `pip install
pyyaml` silently inverts every duplicate in the tree, and the stale copy is the
one that wins, because stale content sits LATER in a file -- scaffold tails go
uncleaned and new material is inserted above them. Last-wins selects for the
obsolete version systematically.

So this check exists to remove the accident, not to tidy the files. See F87.

NO PYYAML. Deliberately: a checker that depends on the library whose absence is
the hazard would not run in the environment that has the hazard. This is a
dependency-free structural scan.

    python3 scripts/check_yaml_duplicate_keys.py            # every task.yaml
    python3 scripts/check_yaml_duplicate_keys.py FILE ...   # named files

Exit 0 clean, 1 on any duplicate, 2 on a usage error.

SCOPE, stated rather than implied: this finds repeated keys in BLOCK MAPPINGS at
any depth, and repeated keys inside a single flow mapping `{...}`. It does not
model anchors, merge keys or multi-document files, none of which appear in this
repository. It does not check that a file PARSES -- that is a different question
with a different answer, and a file can parse cleanly and still be lossy here.

A TOOL THAT CANNOT FAIL ON A GIVEN INPUT IS NOT EVIDENCE ABOUT THAT INPUT.
That is why every clean line below carries the number of keys the scan actually
walked, and why a file it could not walk is reported as NO CONCLUSION rather
than as clean. "Found no duplicates" and "could not look" are different results
and only one of them is reassuring; a checker that renders them with the same
word has the defect it was written to catch. (Rule 36, in the checker's own
output. The observation is AGENT-VERIF-A2's, from the sibling case where a
variation tool reported a clean row for a signal it had nothing to compare
against.)
"""

import os
import re
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# A block-mapping key at the start of a line: bare, "double" or 'single' quoted.
_KEY = re.compile(r"""^(?P<ind>[ ]*)(?P<key>[A-Za-z_][\w.\-]*|"[^"]*"|'[^']*')[ \t]*:(?P<rest>[ \t].*|)$""")
# A sequence item.
_ITEM = re.compile(r"^(?P<ind>[ ]*)-(?P<rest>[ \t].*|)$")
# A block scalar introducer: `>`, `|`, with optional chomp/indent indicators.
_BLOCK_SCALAR = re.compile(r"^[|>][+-]?\d?[+-]?[ \t]*(#.*)?$")
# Keys inside a flow mapping, e.g. `{name: x, clause: C2}`.
_FLOW_KEY = re.compile(r"(?:^|[{,])[ \t]*([A-Za-z_][\w.\-]*)[ \t]*:")


def _strip_comment(line):
    """Drop a trailing `#` comment, respecting quotes. Not a full lexer -- it
    only needs to keep `#` inside quoted scalars from truncating a line."""
    out, quote = [], None
    for i, ch in enumerate(line):
        if quote:
            out.append(ch)
            if ch == quote and (i == 0 or line[i - 1] != "\\"):
                quote = None
            continue
        if ch in "\"'":
            quote = ch
            out.append(ch)
            continue
        if ch == "#" and (not out or out[-1] in " \t"):
            break
        out.append(ch)
    return "".join(out).rstrip()


def _unbalanced(text):
    """Net bracket depth of `text`, ignoring brackets inside quotes."""
    depth, quote = 0, None
    for i, ch in enumerate(text):
        if quote:
            if ch == quote and (i == 0 or text[i - 1] != "\\"):
                quote = None
            continue
        if ch in "\"'":
            quote = ch
        elif ch in "{[":
            depth += 1
        elif ch in "}]":
            depth -= 1
    return depth


def _logical_lines(raw):
    """Yield (lineno, indent, text) for each LOGICAL line.

    Two things collapse here, and both are load-bearing:

      * BLOCK SCALAR BODIES ARE DROPPED. `overlap_resolved: >` is followed by
        prose, and prose contains colons. Without this the scanner reads
        `REAL SEMANTIC OVERLAP, not a mutant defect. A design that refuses:` as
        a key and the whole scan is noise.
      * MULTI-LINE FLOW COLLECTIONS ARE JOINED. `- {name: m05, \\n clause: C2}`
        is one logical entry; its continuation lines are not keys of anything.
    """
    lines = raw.split("\n")
    i = 0
    while i < len(lines):
        raw_line = lines[i]
        lineno = i + 1
        if not raw_line.strip() or raw_line.lstrip().startswith("#"):
            i += 1
            continue
        text = _strip_comment(raw_line)
        if not text.strip():
            i += 1
            continue
        indent = len(text) - len(text.lstrip(" "))

        # Join a flow collection that continues onto later lines.
        depth = _unbalanced(text)
        while depth > 0 and i + 1 < len(lines):
            i += 1
            nxt = _strip_comment(lines[i])
            text += " " + nxt.strip()
            depth += _unbalanced(nxt)

        yield lineno, indent, text.strip()

        # If this line introduced a block scalar, swallow its body.
        m = _KEY.match(text) or _ITEM.match(text)
        if m and _BLOCK_SCALAR.match(m.group("rest").strip()):
            i += 1
            while i < len(lines):
                nxt = lines[i]
                if nxt.strip() and (len(nxt) - len(nxt.lstrip(" "))) <= indent:
                    break
                i += 1
            continue
        i += 1


def duplicates(path, stats=None):
    """[(path_to_key, first_lineno, second_lineno)] for every repeated key.

    `stats`, if given, is filled with what the scan actually walked -- so that a
    clean result carries its own evidence instead of asserting itself.
    """
    raw = open(path, encoding="utf-8", errors="replace").read()
    # stack of [indent, {key: lineno}, parent_path]
    stack = []
    found = []
    keys_seen = 0
    max_depth = 0

    def flow_dupes(text, lineno, prefix):
        if "{" not in text:
            return
        seen = {}
        for m in _FLOW_KEY.finditer(text):
            k = m.group(1)
            if k in seen:
                found.append((".".join(prefix + [k]) + " (flow mapping)",
                              lineno, lineno))
            seen[k] = lineno

    for lineno, indent, text in _logical_lines(raw):
        item = _ITEM.match(text if indent == 0 else " " * indent + text)
        if text.startswith("- "):
            # A sequence entry. Every item gets its OWN mapping scope: two items
            # may of course carry the same keys as each other.
            while stack and stack[-1][0] >= indent + 2:
                stack.pop()
            inner = text[2:].strip()
            path_prefix = [p for p in (stack[-1][2] if stack else [])]
            stack.append([indent + 2, {}, path_prefix + ["[]"]])
            flow_dupes(inner, lineno, stack[-1][2])
            km = _KEY.match(inner)
            if km:
                stack[-1][1][km.group("key").strip("\"'")] = lineno
                keys_seen += 1
                max_depth = max(max_depth, len(stack))
            continue

        km = _KEY.match(" " * indent + text)
        if not km:
            continue
        key = km.group("key").strip("\"'")

        while stack and stack[-1][0] > indent:
            stack.pop()
        if not stack or stack[-1][0] < indent:
            parent = stack[-1][2] if stack else []
            stack.append([indent, {}, parent + ([] if not stack else [])])
        scope = stack[-1]
        if key in scope[1]:
            found.append((".".join(scope[2] + [key]), scope[1][key], lineno))
        scope[1][key] = lineno
        keys_seen += 1
        max_depth = max(max_depth, len(stack))
        flow_dupes(km.group("rest"), lineno, scope[2] + [key])

    if stats is not None:
        stats["keys"] = keys_seen
        stats["depth"] = max_depth
        stats["lines"] = raw.count("\n") + 1
    return found


def task_yaml_files():
    """The nineteen record files: 8 design + 11 verification.

    NINETEEN IS NOT TWENTY. `domains/dsp/design/d_dsp01_fp_divsqrt_srt/` is a
    ninth design directory and has no task.yaml BY DESIGN -- the task is
    withdrawn under F54 and the directory is kept as the evidence. Its absence
    from this sweep is correct. Stated here so that a later reader does not read
    "19 files scanned" as "every task covered" and does not add a task.yaml to
    d_dsp01 to make the count tidy.
    """
    import glob
    out = []
    for kind in ("design", "verification"):
        out += sorted(glob.glob(os.path.join(REPO, "domains", "*", kind,
                                             "*", "task.yaml")))
    return out


def self_test():
    """Prove the detector against REAL historical duplicates, not synthetic ones.

    Both cases below were live in this repository and were found by hand. A
    detector validated only on a fixture someone wrote to be caught proves that
    the fixture matches the detector, which is not the same claim.

    The third case IS synthetic and is here for the opposite reason: it guards a
    false NEGATIVE in the hardest scope, a repeated key inside a sequence item.
    """
    import subprocess
    cases = [
        # (commit, path, key, first_line, second_line, what it was)
        ("f616803", "domains/ai_accel/design/d_ai01_fp16_gemm_array/task.yaml",
         "what_changed_this_boundary", 131, 159,
         "the superseded boundary narrative replaced the current one"),
        ("7575a41", "domains/comp_arch/design/d_ca01_nonblocking_dcache/task.yaml",
         "mutants", 144, 195,
         "a NOT_STARTED scaffold stub replaced seven built mutants"),
    ]
    failures = 0
    ran = 0
    for commit, path, key, first, second, what in cases:
        try:
            blob = subprocess.run(["git", "show", f"{commit}:{path}"],
                                  cwd=REPO, capture_output=True, text=True,
                                  check=True).stdout
        except (subprocess.CalledProcessError, FileNotFoundError) as e:
            print(f"  SKIP    {commit} {os.path.basename(path)}: {e}")
            failures += 1
            continue
        tmp = os.path.join(REPO, ".dupkey_selftest.yaml")
        open(tmp, "w", encoding="utf-8").write(blob)
        try:
            got = duplicates(tmp)
        finally:
            os.unlink(tmp)
        ran += 1
        want = (key, first, second)
        if any(d[0].split(".")[-1] == key and d[1] == first and d[2] == second
               for d in got):
            print(f"  caught  {commit} {key} @ {first}/{second} -- {what}")
        else:
            print(f"  MISSED  {commit} {key} @ {first}/{second}; got {got}")
            failures += 1

    # False-negative guard: a duplicate inside a sequence item, the deepest and
    # most easily skipped scope.
    src = os.path.join(REPO,
                       "domains/comp_arch/design/d_ca01_nonblocking_dcache/task.yaml")
    lines = open(src, encoding="utf-8").read().split("\n")
    idx = [i for i, l in enumerate(lines) if l.strip().startswith("- name: m05_")]
    if len(idx) != 1:
        print(f"  MISSED  sequence-item guard could not run: "
              f"{len(idx)} anchors matched, expected 1")
        failures += 1
    else:
        j = idx[0]
        tmp = os.path.join(REPO, ".dupkey_selftest.yaml")
        open(tmp, "w", encoding="utf-8").write(
            "\n".join(lines[:j + 1] + ["      probe_k: 1", "      probe_k: 2"]
                      + lines[j + 1:]))
        try:
            got = duplicates(tmp)
        finally:
            os.unlink(tmp)
        ran += 1
        if any(d[0].endswith("probe_k") for d in got):
            print("  caught  synthetic duplicate INSIDE a sequence item")
        else:
            print(f"  MISSED  synthetic duplicate inside a sequence item; got {got}")
            failures += 1

    print()
    print(f"{ran} case(s) exercised, {failures} failure(s)")
    if ran != 3:
        print("REFUSED: a case did not run. A self-test that skips a case and "
              "reports PASS is the defect this repository calls rule 36.")
        return 1
    return 1 if failures else 0


def main(argv):
    if "--self-test" in argv:
        return self_test()
    targets = argv[1:] or task_yaml_files()
    if not targets:
        print("no task.yaml files found", file=sys.stderr)
        return 2
    bad = 0
    unwalked = 0
    for f in targets:
        if not os.path.isfile(f):
            print(f"REFUSED: no such file: {f}", file=sys.stderr)
            return 2
        rel = os.path.relpath(f, REPO)
        if rel.startswith(".."):        # a file from outside the repo, e.g. a
            rel = f                     # historical copy under validation
        st = {}
        dupes = duplicates(f, st)
        if not dupes:
            # "no duplicate found" and "could not look" are different results.
            # A scan that walked no keys concluded nothing; say so and fail.
            if st.get("keys", 0) == 0:
                print(f"  NO CONCLUSION  {rel}")
                print(f"                 walked 0 keys in {st.get('lines', 0)} "
                      f"lines -- the scan did not look, it did not pass")
                unwalked += 1
                continue
            print(f"  ok         {rel}   "
                  f"({st['keys']} keys walked, depth {st['depth']})")
            continue
        bad += len(dupes)
        for keypath, first, second in dupes:
            print(f"  DUPLICATE  {rel}")
            print(f"             `{keypath}` at line {first} and line {second}")
            print(f"             first-wins readers take line {first}; "
                  f"a YAML parser takes line {second}")
    print()
    print(f"{len(targets)} file(s) scanned, {bad} duplicate key(s)"
          + (f", {unwalked} INCONCLUSIVE" if unwalked else ""))
    if unwalked:
        print()
        print("REFUSED: a file was scanned and no key was walked. That is not a")
        print("clean result, it is the absence of one, and reporting it as `ok`")
        print("would be this checker committing the defect it exists to catch.")
        return 1
    if bad:
        print()
        print("REFUSED. A duplicate key is valid YAML and silently drops one of")
        print("the two values. Which one survives depends on the reader, and the")
        print("readers in scripts/ disagree with any YAML parser. Delete the")
        print("stale copy or rename it -- do not leave the choice to the tool.")
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
