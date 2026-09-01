# Rows withheld from the README results tables, with the reason

Read by `scripts/make_readme_tables.py`. One row per line:

    <task_short> <model> :: <reason>

A row listed here renders as **withheld — <reason>** instead of its number.

WHY THIS FILE EXISTS. The generator had no concept of *withheld with a stated
reason*. A row a human deliberately held back was byte-identical, to the
generator, to a row nobody had got round to — both rendered as an empty dash. So
a withholding decision could not survive a regeneration, and because
`make_readme_tables --check` is wired into the commit gate, the gate then
COMPELLED the regeneration by blocking every agent until someone ran it.

It got worse before it got better: write_run_record.py was changed to regenerate
automatically when a record lands, to stop successful builds red-gating the
repo. That removed the human from the loop entirely — two numbers a person had
decided to withhold were published within the hour by the tooling, with nobody
choosing to publish them.

The empty dash was the hazard, not the number. An unexplained gap in a results
table gets filled by whoever finds it next, and what found it next was the
generator.

# UPDATED 2026-08-29 after the emit landed. The metrics now exist, so the
# "declares five, produces none" clause is discharged -- and the row still does
# not publish, for a reason the emit made visible rather than removed:
# buffer_slots is a CHOICE, not a capability, and gemini spent 4 where the
# reference, chat and claude spent 2. Per-unit normalisation is the wrong
# instrument for a choice axis; like-for-like grouping is, and nothing renders
# that yet.
#
# CORRECTION, 2026-08-29. The three d_ai04 reasons previously said the precision
# axis made a smaller design and a less complete one indistinguishable. The
# catalog sentence behind that is true and the inference from it was FALSE.
# Verified against the contract and the controls, not argued:
#
#   spec F2, line 60: "The three integer codes are INDISTINGUISHABLE from one
#   another ... A submission may not use 2'd1 or 2'd3 to select any behaviour of
#   its own." So collapsing 0/1/3 is CONFORMING, not incomplete.
#
#   controls/nc_g_alias_modes.sv scores 0/1 -- the collapse that WOULD make a
#   design less complete, aliasing float into the integer path, is caught.
#
#   The scoring tb carries coverage floors (n_sub, n_inf, n_nan, n_n2z,
#   n_disjoint) that fail a run leaving float mode unexercised.
#
# Raised by AGENT-DESIGN-43a92055, who measured it rather than arguing it. A
# withheld reason is the only thing a reader gets in place of a number, it reads
# as deliberate, and "the apparatus cannot tell these apart" is exactly the
# claim that stops anyone checking whether it can. Same shape as an attribution
# field carrying no attribution, with more force.
#
# The other two clauses were and remain sufficient on their own.

# RELEASED 2026-08-29 on the user's instruction. The blocker recorded below was
# that tlb_hits is pinned by P2 and no valid free axis was rendered.
# AGENT-DESIGN-43a92055 removed the tlb_hits role and declared
# requests_per_1000cyc, which P2 does not pin; the candidate sim was re-run so
# the metric exists on both sides (reference 163, claude 192); and the row now
# publishes raw ALONGSIDE per unit, which is what G2 prescribed from the start.
# The history below is kept because the reason was wrong twice before it was
# discharged.
#
# CORRECTION, 2026-08-29, second one. The d_ca03 reason previously said the task
# "declares no capability metric". That was true of the TOOLING and false of the
# CONTRACT, and I asserted it of the contract. Spec G2 line 719 declares
# capability explicitly, task.yaml carries a CAPABILITY-REDUCED control whose
# evidentiary value is the pass/fail split, and the metrics are emitted on every
# run. Raised and measured by AGENT-DESIGN-43a92055 after I said I EXPECTED the
# line held.
#
# The gap is a schema mismatch and is d_ca03's to close, not scripts/:
#   d_ca04  scored_metrics: - {metric: capacity_beats_accepted, role: capability}
#   d_ca03  - axis: total_cycles / kind: reported / where: ...   (no role: key)
# metric_roles() reads the first form only.

