# Per-task commentary for the README's design results

Edited by hand. `scripts/make_readme_tables.py` emits each task's generated
table and then the matching block below.

THIS FILE EXISTS BECAUSE THE COMMENTARY WAS ONCE DELETED. The README's design
section interleaved generated-able tables with hand-written analysis. When the
tables were put behind generator sentinels, the region replaced covered both,
and five paragraphs went with it silently -- a generator overwriting prose it
did not author. Separating them means the generator can only rewrite what it
owns, and a note that goes stale is visible here rather than absent there.

Any statement here is a claim about numbers in the table above it. When a
result moves, the note moves with it or it is wrong.

## d_ca04
The only task where every submission closed timing, and all three are 26–27%
smaller than the reference. Two of them reach that partly by a design choice
rather than better implementation — see the like-for-like note below.

## d_nw03
`claude` closes at **+0.117 ns** and comes in at **0.99×** the reference's area
— the only submission in this table to land under a reference. On the previous
bytes it missed by 78 ps and was withheld; the re-solicited version clears the
pin. `chat` and `gemini` still miss, and close is still missed: the numbers they
would report describe circuits that cannot run at 4.25 ns.

## d_dsp03
`chat` closes the pin but at **3.28×** the reference's area — the largest
comparable submission on the page, and a reminder that closing timing and
spending area are separate axes. `claude` is at 1.28×.

## d_nw01
Both submissions that build now close the pin, at 1.17× and 1.23×, and both draw
**0.90×** the reference's power. `claude` clears by 9 ps, which counts.

## d_ca01
`claude` is 1.32× the reference's area and **4.29× its power** — the widest
divergence between the two axes anywhere in these results. `chat` misses the pin
by 49 ps and is withheld.

## d_ca03
`claude` is **0.76×** the reference's area raw and **0.65×** per unit of
throughput — the only submission on this page that improves in the *same*
direction on both. It delivers 192 requests per 1000 cycles against the
reference's 163 while using a quarter less area, so normalisation widens its
lead rather than narrowing it. The contrast with d_ca04 is the point: there, per
unit closed most of the raw gap.

A caution on reading it: the same submission looks *worse* per TLB hit
(0.84× against 0.76× raw), because it retains fewer entries. That axis is not
scored — P2 pins translation storage at 16+16 fully associative, so hit rate is
not a design choice and area-per-hit divides by a constant. Throughput is the
axis the design is free on, and it is the one shown.

`chat` is correct — it passes the scored configuration — and needs roughly 48 ns
to do it, against a 12.5 ns pin. That is not a near miss like d_nw03's 78 ps; it
is a design that works and is nearly four times too slow.

`gemini` is a distinct outcome from a correctness failure: slang rejects it with
ten diagnostics, none of them internal errors, and Verilator rejects the same
construct at the same line. Two independent frontends agreeing makes it a
genuine build failure rather than a host problem.
