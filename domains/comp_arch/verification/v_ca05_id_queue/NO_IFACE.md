> **Location note.** This file sits at the task root, NOT in `spec/`.
> `scripts/task_text_hash.py` hashes every `.sv`, `.svh` and `.md` under
> `spec/`, so a note placed there changes the task-text hash and invalidates
> every landed result. Writing this note in `spec/` did exactly that, moving
> the hash from `7e7f9d22bce28ef5` to `cfbae64438bd951d`, which is the very
> failure the note describes.

# No `*_iface.sv` for this task, deliberately

This task has a `probe/PASTE.md` but no `spec/*_iface.sv`. It is the inverse of
the gap recorded in the three design tasks' `probe/NO_PASTE.md`: the prompt
exists, the separately-checkable interface file does not.

## What this costs

`scripts/check_paste_sync.py` verifies that the interface embedded in a prompt
still matches the interface the harness compiles. With no `*_iface.sv` there is
nothing to compare against, so **this task's prompt can never be checked for
drift**. The interface exists only inside `PASTE.md`, which makes that document
the source of truth by default rather than by decision.

That is the same single-copy-with-no-checker shape that let d_dsp03's prompt go
stale after clause T5 was added to its spec. Here it cannot even be detected.

## Why it has not been extracted

Extracting the interface into `spec/tag_tracker_iface.sv` changes nothing a
model sees, but `scripts/task_text_hash.py` hashes every `.sv`, `.svh` and `.md`
under `spec/`, so adding the file **changes this task's task-text hash** and
renders every landed v_ca05 result as *"not scored against this prompt"* until
re-run. v_ca05 has already been re-prompted once; doing it again for a file
whose contents the models never see is not worth it today.

## When this should be fixed

Alongside the OpenRouter scripted benchmark, when submissions are re-collected
anyway. Extract the interface verbatim from `probe/PASTE.md` (never retype it),
then extend `check_paste_sync.py` to verification prompts so this task and the
other eight are covered.
