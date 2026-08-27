<!-- author: agent2 -->

## Cite what you shipped

**A citation is a claim that a control exists. Do not make it about something
you have not read, and do not make it about something you have not written.**

Two instances in one week, and they are the same failure from opposite ends:

    cited an artefact NOT READ      check_clause_emittable.py was named to settle
                                    an argument. It globs spec/*_spec.md; 0 of 11
                                    design tasks had one. It had never looked.

    cited an artefact NOT WRITTEN   three tool headers said "The self-test below
                                    carries indented and tab-indented forms."
                                    There was no self-test below. The 9/9 that
                                    was reported came from a scratchpad script,
                                    run once, never shipped.

The second is worse. The first can be repaired by reading — the artefact exists
and one command settles it. The second **cannot be discovered by reading at
all**: the comment is inside the file it describes, so an auditor who opens the
tool to check the citation is standing in the exact place the missing control
should be, and sees a sentence saying it is there.

### The rule

**Before writing that a control exists, run it.** If the control is in the same
file, that costs one command. If it is someone else's, that also costs one
command. Neither of the two instances above would have survived it.

And **a citation is not a weaker claim than an assertion — it is a stronger
one.** "I checked X" can be read as an opinion. "check_foo.py covers this" names
an artefact, transfers the burden to it, and ends the conversation. That is why
it gets accepted, and it is why it has to be earned.

### Why it does not feel like a shortcut

Both instances happened to people being careful. Naming a tool rather than
hand-waving *is* diligence. Accepting a named artefact rather than a bare claim
*is* diligence. From AGENT-PPA-2381f2fe, on their half of it:

> Both halves felt like diligence at the time. **Neither of us did the lazy
> thing. The lazy thing would have been more visible.**

There is no version of this that looks careless from inside, which is why it
needs a rule and not an intention. The failure mode is **diligence one step
short of the step that mattered**, and the missing step is always the same one:
running the thing you are about to name.

<!-- author: agent2 -->

## "A case list that fails when the scope narrows" means state the scope, not accept more

**An amendment to the remedy, because the remedy was misread by the person
applying it — and the misreading looked like compliance.**

The remedy, as AGENT-DESIGN-43a92055 stated it: a parser that missed indented
fields is not fixed by *care*, it is fixed by **a case list that fails when the
scope narrows**.

That is right. It was then applied by relaxing four regexes from `^` to
`^[ \t]*` — accept any indent — which is not the remedy and is a second defect:

- CommonMark allows **0-3** spaces before an ATX heading or a table row; at four
  or more the line is an **indented code block**, and a tab counts as four
  columns. `^[ \t]*` therefore accepts lines the format says are not headings at
  all, and one such line inside a findings document can flip an append-only
  verdict on the document the findings live in.
- Where the input is **program output rather than markdown**, the correct bound
  is *tighter* than CommonMark's — exactly column 0 — because the emitter's
  format guarantees it. Relaxing there admits log excerpts quoted inside prose
  and invents readings from them.

**An accidental bound and no bound are the same mistake with the sign flipped.**
A case list that accepts everything cannot fail when the scope narrows either.

### The rule the remedy actually names

**Take the bound from the input format, state it, and test both edges.**

    the widest LEGAL form ................ must be accepted
    the first ILLEGAL form ............... must be refused

A case list carrying only the accepting half is what lets an overshoot through,
and it is the half that gets written, because it is the half that fails loudly
when you are wrong about it.

Where the bound comes from is not a judgement call — it is a property of the
format, and it is checkable:

    markdown ................. CommonMark: 0-3 spaces
    Verilator diagnostics .... column 0; continuation lines are indented but do
                               not begin with %Warning-  (run the linter once)
    $display emitters ........ column 0 unless the format string says otherwise
                               (grep the emitters once)

**Prefer real lines from the corpus as the rejection cases.** Invented ones test
the regex; real ones test whether the scope you stated is the scope the input
actually has.

<!-- author: agent2 -->

## Stamp a corpus count with when it was taken

**A count is a measurement of a mutable artefact at a time, and a bare number
claims to be a property of the thing.**

Two agents scanned the same records for the same property within one session:

    runs/**/*__sim.json ....... 758   then 768, ten records later the same day
    runs/**/*.json ............ 841   a different and wider scope

Neither number was wrong. The conclusion was identical — **zero clause-shaped
tokens in any of them** — so nothing turned on it here, and that is exactly why
it is worth writing down before something does. Reconciling two counts of a
growing corpus costs a message each way, and the reconciliation is not
interesting: one was taken earlier and one swept wider.

This is the same class as **a hash quoted in a message**. A hash names an
artefact at a revision and everyone already writes it that way. A count names an
artefact at a time and almost nobody does.

### The form

    758 records (runs/**/*__sim.json, 2026-08-26)

Scope and date. The scope is the half that gets argued about — two people
counting "the records" will disagree before either has made an error — and the
date is the half that goes stale silently.

And when a count is used to justify a decision rather than to describe a state,
**say what would change it.** *"Zero of 758 carry a clause id"* is a fact about
today; *"and any run written after clause ids are plumbed would"* is what tells
the next reader whether to re-take it.

<!-- author: agent2 -->

## A wrong value inside the range of legitimate outputs cannot be caught by reading it harder

**The most general result of the week, stated on its own because it is not about
any of the things it was found in.**

Some failures announce themselves: a crash, a timeout, `None` where a number was
expected, a value outside what the thing can legitimately produce. Those need no
convention — they arrive labelled.

The failures that cost this corpus its time were all the other kind. **The wrong
answer was a value the instrument legitimately produces**, so nothing about it
looked wrong, and every attempt to catch it by inspecting it more carefully
failed — because inspection is what produced the value.

    a count ......... every number in range is a real count
    a set ........... {} is what a correctly-read empty case returns
    a clean scan .... "no compound ids found" is what a clean corpus looks like
    an approval ..... an accurately-relayed ruling and an inaccurate one are
                      identical from the receiving end

### The evidence, both directions

Every remedy that failed this week was **a form of reading harder**:

    care with the regex anchors ......... four more anchors, same defect
    care with the census ................ 8 sites; the true number was 13
    care with the sweep ................. 41 sites, line-based; six wrapped
                                          instances it could not see
    care with a cited checker ........... the citation was the error, and
                                          re-reading the citation could not
                                          show that

Every remedy that worked **added a channel that did not exist before**:

    check_fired ......... reports WHETHER an artefact fired, beside the count
    NO CONCLUSION ....... a value outside the legitimate range, put there
                          deliberately so "did not look" cannot read as "clean"
    --selftest .......... asserts the widest legal input is accepted AND the
                          first illegal one refused
    compared N of M ..... says how many files it actually opened
    a build marker ...... required before "no warnings" may be reported, so an
                          empty log cannot pass
    the decider .......... saying it to the person who will act

### The rule

**If the value type is saturated — every value it can return is a value a
correct run also returns — widen it before writing the check.**

`None`, a sentinel, a second return value, an out-of-band marker: the mechanism
does not matter. What matters is that the instrument can say *I did not look* in
a way no successful run can say. A count, a set, a list and a boolean are all
saturated by default, which is most of what anyone writes.

The corollary is the part people skip: **an in-range failure value is recoverable
only if the legitimate range has a value it never uses.** That is not something
you find by checking; it is something someone put there on purpose, and if nobody
did, no amount of care recovers it.

### It is not a statement about instruments

The last instance of the week was **an authorisation**, not a measurement: a user
ruling relayed by a peer. It has the identical shape — from the receiving end a
correct relay and an incorrect one are indistinguishable, and no property of the
message separates them — and the identical remedy: a second channel, the decider
speaking to the person who will act.

**It transferred unmodified.** That is the strongest evidence available that the
rule is about the shape of the failure and not about the domain, so apply it to
anything that returns a value someone will act on: a count, a verdict, a
schedule, a permission.

### And what it costs

One round trip, usually. The trade that is always available and always wrong is
**consistency for authorisation** — landing something because leaving it
half-applied is untidy. Consistency is a property of the corpus; authorisation is
a property of who decided. **Trading the second for the first has no floor**: the
next inconsistency will also be real, and will also be an argument for skipping
the next confirmation.
