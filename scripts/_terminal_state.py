#!/usr/bin/env python3
"""Does a task DECLARE itself terminal -- withdrawn or rejected?

SHARED BECAUSE TWO CHECKERS NEED IT AND A SECOND COPY WOULD DRIFT. check_tb_module
learned this at bdb512c; check_pin had the identical blindness, reported by the
design session. Both ask the same question -- "is this absence deliberate?" -- and
a marker rule that lives in two files is one edit away from meaning two things.

THE TWO STATES THIS SEPARATES look identical to a tool and mean opposite things:
"deliberately absent, and recorded" versus "missing, nobody noticed". Collapsing
them makes a checker's red uninformative, because one of its reasons can never be
cleared by anyone.

THE MARKER IS DELIBERATELY TIGHT, AND THE LOOSE ONE WAS MEASURED FIRST. Six
NOTES.md files in this corpus contain the word "withdrawn" -- d_ca01, d_ca04,
d_dsp02, d_dsp03, v_ca04 and d_dsp01 -- and only the last is withdrawn; the rest
discuss it. A grep for the word would have exempted five LIVE tasks from a check,
which is a worse failure than the one being fixed. So a declaration must sit in
the FIRST HEADING LINE, where a task states what it is rather than discusses it,
or be a REJECTED.md file.

Two forms are accepted because two exist: d_dsp01 says WITHDRAWN in NOTES.md,
v_dsp01 ships REJECTED.md. Settling on one is the task owners' call, not a tool's.

REPORT, DO NOT SKIP. Every caller should print what it excluded and count it, so a
task that quietly loses a task.yaml or a pin cannot land in the same bucket as one
deliberately without either.
"""
import os
import re

_WITHDRAWN = re.compile(r"^#.*\bWITHDRAWN\b", re.I)


def terminal_state(task_dir):
    """-> a short reason string if the task declares itself terminal, else None."""
    if os.path.isfile(os.path.join(task_dir, "REJECTED.md")):
        return "REJECTED.md"
    notes = os.path.join(task_dir, "NOTES.md")
    if os.path.isfile(notes):
        with open(notes, encoding="utf-8", errors="replace") as fh:
            if _WITHDRAWN.match(fh.readline()):
                return "NOTES.md declares WITHDRAWN"
    return None
