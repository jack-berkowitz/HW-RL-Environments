#!/usr/bin/env python3
"""What verdict does a task DECLARE for this submission, and at which config?

    _expected_verdict.py <task_dir> <label> [config]

Prints "PASS", "FAIL", or nothing when the task declares nothing. Exit 0 either
way -- an undeclared submission is not an error, it is an absence, and the caller
records it as absent rather than guessing.

WHY A FIELD AND NOT A CONVENTION. Controls are expected to FAIL, so a reader
applies that rule and moves on. d_ai01's `nc_h_echo_band_only` is INVERTED: it
corrupts z_o only inside C3's newly-widened exclusion band, so it is expected to
PASS, and the PASS is the measurement -- detected before the window widened, not
detected after, and that pair is what sizes the excluded region.

That makes it the one row in the corpus where losing the verdict does not look
wrong. Every other control reads as a false pass and gets noticed; this one reads
as an ordinary failing control and does not. Reported by the design session, who
declared the data in task.yaml so it could be read instead of assumed.

So the expectation travels with the record, from the task's own declaration --
identity carried by an identifier, never by position, filename, or the reader
remembering which one is backwards.

Parsed with a narrow regex rather than a YAML library because task.yaml is not
importable here and the entries are single-line flow mappings; a parse that finds
nothing yields nothing, which is the honest failure for this.
"""
import os
import re
import sys


def expected(task_dir, label, config=None):
    path = os.path.join(task_dir, "task.yaml")
    if not os.path.isfile(path):
        return None
    text = open(path, encoding="utf-8", errors="replace").read()
    # ENTRIES NEST. `detected_pre_widening: {H4: 123, H8: 196}` sits inside the
    # control's own mapping, so a non-greedy {...} match finds the INNER brace and
    # the entry is never seen. Scan by brace balance from each list item instead.
    entries = []
    i = 0
    while True:
        i = text.find("- {", i)
        if i < 0:
            break
        depth, j = 0, i + 2
        while j < len(text):
            if text[j] == "{":
                depth += 1
            elif text[j] == "}":
                depth -= 1
                if depth == 0:
                    break
            j += 1
        entries.append(text[i + 3:j])
        i = j + 1
    for raw in entries:
        body = " ".join(raw.split())
        nm = re.search(r"\bname:\s*([A-Za-z0-9_.-]+)", body)
        if not nm or nm.group(1) != label:
            continue
        if config:
            key = re.search(r"\bexpect_at_%s:\s*(PASS|FAIL)\b" % re.escape(config), body)
            if key:
                return key.group(1)
        gen = re.search(r"\bexpect(?:ed)?:\s*(PASS|FAIL)\b", body)
        if gen:
            return gen.group(1)
        # a single expect_at_* with no config asked for is still a declaration,
        # but only when the entry declares exactly one -- otherwise it is ambiguous
        alls = re.findall(r"\bexpect_at_[A-Za-z0-9_]+:\s*(PASS|FAIL)\b", body)
        if alls and len(set(alls)) == 1:
            return alls[0]
        return None
    return None


if __name__ == "__main__":
    if len(sys.argv) < 3:
        sys.exit(0)
    v = expected(sys.argv[1], sys.argv[2], sys.argv[3] if len(sys.argv) > 3 else None)
    if v:
        print(v)
