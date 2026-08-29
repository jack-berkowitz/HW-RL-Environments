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

d_ai04 chat :: pinned at one configuration and declares no capability metric; its own catalog records three of four precision codes as byte-identical on the scored stimulus, so a smaller design and a less complete one are indistinguishable here
d_ai04 claude :: pinned at one configuration and declares no capability metric; its own catalog records three of four precision codes as byte-identical on the scored stimulus, so a smaller design and a less complete one are indistinguishable here
d_ai04 gemini :: pinned at one configuration and declares no capability metric; its own catalog records three of four precision codes as byte-identical on the scored stimulus, so a smaller design and a less complete one are indistinguishable here
d_ca03 claude :: declares no capability metric, so a 0.76x raw-area result cannot be separated from a design that implements less
