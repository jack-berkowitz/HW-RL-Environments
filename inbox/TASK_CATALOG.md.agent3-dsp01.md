<!-- author: agent3 -->
<!-- received: 2026-08-24, via cross-session message; staged by the owner on the author's behalf -->

## Block — d_dsp01 row correction

Status LANDED.

Author's text, from `domains/dsp/design/d_dsp01_fp_divsqrt_srt/NOTES.md:104-108`
and the covering message:

> Row `d_dsp01` reads `| B | not started |`. Two corrections:
>
> 1. **Class A, not B** -- both modules are vendored and elaborate clean. The
>    difficulty was never availability.
> 2. **It should be marked withdrawn with a pointer to F54**, so it is not
>    re-attempted. The anchor is not fixable from inside this repo.
>
> The reference is a genuine thin port shim -- "NO BEHAVIOUR: parameter binding,
> rename, and enum decode only" -- instantiating vendored `fpnew_divsqrt_multi`.
> Disqualified as a golden reference under F54 because the anchor implements none
> of the five rounding modes correctly. Disqualified for rounding-mode failure,
> not for lacking RTL.
>
> A "Class B" row is exactly the signal that sends a future audit hunting for a
> local model of record where vendored RTL exists. A wrong class in a shared file
> propagates into every audit that trusts the catalog instead of the tree.

## Owner's note

Landed. The project owner independently confirmed d_dsp01 is a dropped task, so
the withdrawal is recorded on both authorities.

Verified before landing: NOTES.md line 1 reads "**WITHDRAWN**" and states the
task "has no `task.yaml` and must never acquire one"; the directory has no
task.yaml; F54 exists at FINDINGS.md:2540 and is about a vendored dependency one
version out of step producing a golden reference that is wrong.
