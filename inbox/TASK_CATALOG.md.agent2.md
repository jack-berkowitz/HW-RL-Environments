<!-- author: agent2 -->
<!-- received: 2026-08-24, relayed by the project owner from agent2's message -->
<!-- staged by the owner on the author's behalf; content reproduced as sent -->

## Block 1 — replacement row, v_ca06

Status LANDED, with one omission noted below.

| `v_ca06` | `axi_dw_downsizer` | (unchanged) | PULP `axi/src/axi_dw_downsizer.sv` | A | **BUILT + SCOREABLE.** Ships `dw_downsizer` (port map + spec only, no RTL). 10 guarded mutants, reference ceiling 10/10, step 5c 22/22 (wrapper_pointed), rule-24 reproduction in `mutants/RULE24.md`. task_text_hash `1a685c09e4cd0bde`. |

Author's note: "v_ca06's row is the only stale thing I left, and I can't fix it."

## Owner's note

Landed. The description column was supplied as "(unchanged)", so the existing
description was kept in place rather than replaced with that literal.

`task_text_hash 1a685c09e4cd0bde` was NOT landed. Hashes were removed from every
catalog row in 330c7de on the project owner's instruction — they rot silently and
are computable on demand — so landing this one would reintroduce the single thing
that commit removed. The value is recorded here in the staging file, which is the
right home for it: an author's statement of what they measured, not a claim the
catalog goes on making after the question changes.
