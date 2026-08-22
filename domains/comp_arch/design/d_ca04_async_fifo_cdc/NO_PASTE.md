> **Location note.** This file sits at the task root, NOT in `probe/`.
> This task has no `probe/` directory at all, and it must stay that way:
> `scripts/task_text_hash.py` REFUSES to hash a task that has a `probe/`
> directory without a recognised prompt document. Creating `probe/` just to
> hold this note broke the hash for this task until the directory was
> removed again. An empty-handed `probe/` is worse than none.

# No `PASTE.md` for this task, deliberately

This task predates the paste-prompt convention. Its submissions were obtained
before `probe/PASTE.md` existed, so there is no single document that is *the
text the model was handed*. The specification in `../spec/` is authoritative and
complete; what is missing is only the packaged prompt.

## Why one has not simply been added

`scripts/task_text_hash.py` hashes the prompt document along with the spec, so
**adding a `PASTE.md` here changes this task's task-text hash**. Every existing
submission was scored against the text as it stands today, and the report
refuses to show a result whose recorded hash does not match the current one
(rule 17 / F38). Adding the file would therefore render every landed result for
this task as *"not scored against this prompt"* until each one is re-run.

That is the correct behaviour and it is not worth triggering right now. The
established numbers here are among the most solid in the project, and the only
thing a reconstructed prompt would buy today is folder symmetry.

## When this should be fixed

When these tasks are driven through OpenRouter for a scripted benchmark run.
At that point every task needs a machine-readable prompt anyway, submissions
will be re-collected against it, and the hash change costs nothing because
nothing is being carried over.

At that point:

1. Write `PASTE.md` with its interface block GENERATED from `../spec/*_iface.sv`
   rather than retyped. The interface currently appears in both places on 11 of
   12 tasks that have a prompt, and it has already drifted once: d_dsp03's
   `PASTE.md` was generated before clause T5 was added to the spec.
2. Extend `scripts/check_paste_sync.py` to cover this task. It checks design
   prompts today and skips all nine verification prompts.
3. Re-run the task's submissions so their recorded hash matches the new text.

Until then this file exists so the gap is a recorded decision rather than an
oversight, and so nobody adds a `PASTE.md` here without knowing it invalidates
the task's results.
