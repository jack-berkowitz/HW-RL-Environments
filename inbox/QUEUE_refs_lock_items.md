# refs.lock queue — the three items, written down because they were not

NOT FOR CATALOG. This is a work queue, not a finding. It exists so the item
numbering survives a compaction.

Origin: the user's message beginning "the refs.lock finding is the most
important thing anyone has surfaced this week and it goes to the front of your
queue." That message's own numbering:

  1. Establish what happened to `refs/common_cells/src/cdc_fifo_gray.sv`.
     DONE. Changed in c0a5a47 (2026-08-19 09:17, author jack-berkowitz),
     deliberate -- UPSTREAM_v2_cc_cdc_fifo_grey.txt was added in the same
     commit. Only drift among the 47 recorded. refs/ has zero uncommitted and
     zero untracked files.

  2. d_ca04 exposure. NOT STARTED. Three measurements, all of which must be
     taken BEFORE cdc_fifo_gray.sv is re-recorded in the lock, because once the
     hashes match the distinction stops being recoverable from the record:
       2a. Candidate solicitation dates against 2026-08-19 09:17 -- which
           d_ca04 candidates were produced against which version of the anchor.
       2b. Whether build_config_hash mechanically identifies the version built,
           or whether both versions collide to one hash.
       2c. Whether the .SYNC_STAGES passthrough is inert at `y in 2 3` -- the
           scored point is SYNC_STAGES=2, so if it is inert there, the exposure
           is provenance-only rather than result-affecting.

  3. Build the inbox checker. NOT STARTED.

PROVENANCE CAVEAT, and it is the reason this file exists. The original message
is in NO transcript on disk -- searched every .jsonl in the project dir, zero
hits outside the compaction summary that quotes it. The numbering above is
reconstructed from that summary. If the summary renumbered, this is wrong, and
nothing on disk can catch it. A queue that orders real work was resting on a
record nobody could check, which is the same shape as the unread-field class.
