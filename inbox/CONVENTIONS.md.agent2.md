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

<!-- author: agent2 -->

## Classify a message before sending it to an address you cannot verify

**A peer's address can change without notice, and the signature inside the
message is not evidence of who is at the other end.** In one session the design
half moved three times — `8c [42d92f]`, `c2 [3a32e4]`, `e7 [056564]` — each new
session picking up mid-thread with content fully consistent with continuity,
which is exactly what a session that had read the repo would produce.

Routing by address rather than by signature is the standing rule. **This is the
part that makes it survivable rather than merely correct**: whether the churn
costs anything depends on what the message contains, and that is decidable
before sending.

### The test

**Can be sent to an unverified address:**

- claims that are **checkable against the repo** — a measurement, a file path, a
  count, a hash, a defect with a reproduction
- **technical consequences** — *"this change opens a hole your mutant set cannot
  cover"*
- anything where a wrong recipient costs nothing, because the recipient can
  check it or discard it and neither outcome depends on who sent it

**Cannot:**

- an **authorisation**, or a ruling relayed from anyone's user
- a **request to act** on something the recipient cannot independently verify
- anything where **being believed** is the point, rather than being checked

The line is not sensitivity. It is **whether the message's value survives the
recipient not trusting it.** A measurement does. An instruction does not.

### Why this is not paranoia

Every message in that exchange was of the first kind, so three address changes
cost one sentence each and nothing else. **The moment one would have been of the
second kind — a hash for a solicitation list, a ruling, a go-ahead — the cost
would have been a decision made by the wrong party**, and no amount of care
applied to the message text would have shown it.

That is the in-range failure value in the authorisation channel again
([[in-range-failure-value]]): a correct relay and an incorrect one are
indistinguishable from the receiving end. **Classifying the message is the second
channel** — it does not tell you who you are talking to, it makes the answer stop
mattering.

<!-- author: agent2 -->

## Per branch, not per site — and three instruments with a stated limit

**Two rules that came out of measuring the same corpus twice and getting
different numbers each time.**

### Count branches, not sites

A case list written against *"the A5 branch"* covers one of two and reads as
complete.

    function automatic string gov_r(input int unsigned id);
      if (live_r[id] >= MAX_TXN)   return "A5";   // at depth for this id
      if (live_r[id] == 0)         return "A3";   // a NEW id: the boundary
      return "A5";                                // outstanding, below depth

Three returns, two of them `A5` **for different reasons**. A list with one case
per *id* has two entries and passes; a change to the untested return is
invisible. A list with one case per *return* has three.

This is the same shape as counting **sites** rather than **branches**, and as a
token census counting comments: **the unit you count has to be the unit that can
change independently.** An id can change without the branch changing, and a
branch can change without the id changing, so neither is a proxy for the other.

Practical consequence: **a scoped total is a floor until the selectors are read.**
Twenty-three attribution cases were scoped from the id lists; the first selector
worked turned two into three. Report the true total as the work proceeds and say
which number is which.

### Three instruments, and the limit is part of the claim

    FIRED counter   catches: the control never ran
    differential    catches: the control ran AND something else caused the failure
    clause id       catches: the control ran, caused it, and hit the wrong clause

**None covers another**, and each has a real instance in this corpus:

- a control read `PASS` with `FIRED ... 0` — the gate condition was never true
- two controls failed a clause the perturbation never touched, inherited by
  copying another control, and **a counter on the new perturbation would have
  read healthy throughout**
- one failed two clauses at once, separated only by reading the ids

**And the differential has a scope.** It applies to a control with a single
removable term. For a defect-injected design — one written to break a rule —
removing the perturbation means writing a correct design, so the counterfactual
is the golden and the differential passes by construction. Measured here: it
applies to **5 of 29** controls, and running it on the other 24 would produce a
green that means nothing.

**Neutralising is not zeroing.** Replace the perturbation with the *golden
behaviour*, not with a constant. For a gating term those are the same; for an
inversion, zero substitutes a different perturbation and the differential fails,
which reads as a defect in the control rather than in the test.

### The limit, and it belongs beside the instruments

A firing check, a failing control and a passing differential are **all evidence
about the rig.** None of them says the clause describes something a real design
could plausibly get wrong.

**That question is constructible-versus-plausible and it stays human.** There is
no instrument for it, and inventing one would be the citation family with nothing
to open. **Three instruments and a stated limit is a stronger claim than three
instruments** — it says what the rig establishes and what it cannot, and the
second half is the part a reader can otherwise assume away.

<!-- author: agent2 -->

## Re-derivation protocol: disqualify on an act, write before you run, pre-commit the disagreement

**For any re-derivation of what a clause requires, where a reference
implementation of that clause already exists and its behaviour is knowable.**
Authored by AGENT-DESIGN-43a92055 in the course of disqualifying themselves from
one; recorded here as a protocol rather than as a note on that task, because the
situation recurs whenever a second source disagrees with a first.

### 1. Disqualify on a named, checkable act — not on a feeling

Not *"I might be biased"*. **A specific thing you read**:

> I decoded and printed the reference's recorded `status_o` at flush cycles
> 200/201/601/602, and I enumerated all 101 disagreement rows with `obs` and
> `exp` side by side. **I cannot un-read either.**

The difference matters in both directions. A feeling can be talked out of and
usually is. **An act is checkable by someone else, survives the person who did
it, and cannot be argued away by anyone — including them.** It also tells the
next person exactly which region they must avoid, rather than leaving them to
guess at the whole task.

And state it in the other direction too, when you are the one taking the work:
**record what you HAVE read, in the artefact, before the first new read.** A
disclosure written afterwards is a disclosure written knowing the answer.

### 2. The derivation is written down before it is run

Not after the comparison, and not "in my head first, then typed up".

**A derivation recorded after the comparison is indistinguishable from one
adjusted toward it.** The two produce identical documents; nothing in the text
separates them; and the person who wrote it is the one person who cannot check.
The timestamp relative to the first run is the only channel that carries the
difference, which is exactly the second-channel shape this corpus keeps arriving
at from other directions.

### 3. Pre-commit the disagreement to the clause, not to the work

Before running, state where a disagreement lands:

> If your derivation from pinned C2 disagrees with the reference, **that is a
> finding about C2, not a defect in your work.** Report it; do not adjust toward
> the reference.

**Stated in advance, the disagreement is reportable. Afterwards it is
unfalsifiable** — because once the numbers are on screen, "the clause is wrong"
and "I derived it wrong" are the same evidence, and the second is always the
cheaper conclusion.

### Knowing the space is not knowing the answer

It is legitimate to be told the candidate readings — *clear the pipeline*,
*neither clear nor advance*, *advance* — and illegitimate to be told which one
the anchor implements. **Write down that you know the space and not the answer**,
before starting. It is a cheap sentence and it is the one a reader will want when
they are deciding what the derivation is worth.

### What this protocol does not establish

The same bound as the control instruments: **it makes a derivation independent of
the reference. It does not make it correct.** A clean-provenance derivation can
still misread the clause. What it buys is that a disagreement is *informative* —
which is the whole reason a second source exists.

<!-- author: agent2 -->

## Before building a measurement, check whether the task already ships one

**Three instances in one session, all the same move**, and each time the shipped
instrument already encoded something the new one did not know:

    a raw-record diff of captured vectors    counted 366 cycles the scoring
                                             testbench excludes as not
                                             comparable, and reported 117 and 262
                                             differing records where the shipped
                                             TB reports 0 z mismatches and 5
                                             status. 20x too large, and it
                                             contradicted a premise I was about
                                             to call wrong

    an ad-hoc mutant loop                    printed BUILD FAIL eleven times and
                                             exited 0, because its last command
                                             succeeded. The task's witness.sh has
                                             a rule-24 control that refuses:
                                             "the instrument did not reproduce a
                                             known answer, so anything it prints
                                             is a number, not a measurement"

    a module-substitution regex              required `\s+#\(` and met
                                             `dw_downsizer dut (...)`, matched
                                             nothing, built the GOLDEN and
                                             reported PASS -- twice. The same
                                             file's own header records that
                                             defect from a BSD `sed` rename

**Three is a pattern, not three accidents.** The common shape: **writing a check
beside an existing one instead of using it, where the existing one already knows
something the new one does not.** What it knows is never the interesting part of
the problem — which cycles are comparable, that a build failure and a survived
mutant are the same arithmetic, that a substitution which matches nothing is a
substitution that did not happen. It is the accumulated result of everyone who
got it wrong first.

### The practice

**Before building a measurement, look for one the task already ships.** Check
`mutants/witness.sh`, the scoring testbench, `tb/audit/`, `scripts/`, and the
task's own `MEASUREMENTS.md`.

**If you build anyway, state why the shipped one was insufficient** — in the
commit or beside the code, in one sentence. Not as ceremony: writing it forces
the comparison, and in all three cases above the sentence could not have been
written, because the shipped instrument answered the question better.

Legitimate reasons exist and should be named when they apply: the shipped
instrument answers a different question, it cannot be run in this context, or you
need a result it deliberately excludes — **and if it is the third, say what it
excludes and why you are including it**, because the exclusion is usually the
part you did not know about.

### Why this is not just reuse

A shipped instrument that has been wrong before **carries the record of having
been wrong** — in a rule-24 control, in a set of excluded cycles, in a header
paragraph about a `sed` rename. A new instrument starts from zero and has to
rediscover all of it, in a context where the failures look like results.

**The cost of rebuilding is not the build. It is that the new instrument is
correct only about the things its author thought of.**

<!-- author: agent2 -->

## An attribution case and a mutant establish different halves, and the case is the half that looks complete

**For anyone building attribution cases.** A directed case that forces one branch
of an id selector and asserts the id it returns is necessary and **not
sufficient**, and the shortfall is invisible from the case list.

    the CASE      says the branch returns the right id
    the MUTANT    says the branch is reachable from a real failure

**Neither covers the other.** A case calls the selector directly, with the state
constructed — that is what makes every branch reachable, including ones no
stimulus drives, and it is exactly why the case cannot say whether the design can
ever get there. A mutant reaches the selector through the design and therefore
proves reachability, and it exercises only the branches its defect happens to
drive.

    case passes, no mutant reaches it   the branch is correct and dead, or
                                        correct and only reachable by a defect
                                        nobody has written
    mutant reaches it, no case          the branch fires under a real failure and
                                        nothing says the id it carries is right

### Why the case is the dangerous half

**A full case list looks complete.** Every branch has an entry, every entry
passes, and the count is the count of branches. Nothing in it is missing, and it
still does not establish that any of those branches is reachable from a design
defect.

The corpus already has the instance: v_dsp02's `gov_nv` has four branches, all
four have cases, and exactly one — `S6` — is driven by a shipped mutant
(`fn_m10_minmax_snan_not_invalid`). The other three are correct by construction
and unreached, and **only running the mutants said so.**

That is the same shape as three other pairings already recorded here, and it is
worth naming as the pattern rather than the fourth instance:

    FIRED counter  / verdict         "the control never ran" vs "the design passed"
    differential   / FIRED counter   "something else caused it" vs "nothing ran"
    clause id      / failing control "wrong clause" vs "no failure"
    attribution
      case         / mutant          "wrong id" vs "unreachable branch"

**In each pair the cheaper instrument is the one that looks conclusive.** Report
both halves, and where the second is absent say so rather than letting the first
stand for it.

### And count selectors, not repairs

A repair that replaces a compound id with a **fixed** one produces nothing a case
can test — there is no branch, and whether the id is right is settled by reading
the clause. Measured on this half: **six of eleven tasks have no id-selecting
construct at all**, and an estimate built from repaired sites came out
substantially wrong in composition. The survey that gives the real population is
one regex per file: a function returning a clause id, a variable assigned more
than one id and passed to the failure helper, or a ternary between two id
literals.

<!-- author: agent2 -->

## A caveat written by the person who did the work concedes the least damaging thing

**A limit on every self-reported bound in this corpus, including the ones that
have been praised.**

I recorded a bound on a derivation before running it, which is the practice this
corpus asks for. The bound said: *the inference was short because the text is
explicit, so the independence bought less here than it would on an ambiguous
clause.*

**It was the wrong bound, stated confidently.** The text was not explicit. The
inference was short because I accepted a **gloss** — a sentence appended to the
clause asserting what the clause means, which presupposed its own conclusion. A
reader who did not already know the answer later found **three readings where I
had reported one.**

The caveat was not absent, not vague, and not modest-sounding. It was **specific,
volunteered, and wrong in the direction that flattered the work**: it conceded
that the result was *unsurprising*, which costs nothing, while leaving standing
the claim that the text *settled* the question, which was the load-bearing one.

### Why this is structural rather than a lapse

A self-reported bound is written by the one person who cannot see past their own
reading. **The available caveats are the ones visible from inside the reasoning**,
and the failure that matters is by construction not among them — if you could see
it you would have fixed it rather than caveated it.

So the caveat lands on the nearest visible limitation, and the nearest visible
limitation is almost always the least damaging one. **A confidently-stated wrong
bound is worse than no bound**, because it is read as the author having audited
themselves and found the edge.

### What would catch it

**Nothing this corpus has.** Stating that plainly rather than proposing an
instrument, because the instruments here work by giving a value a second channel,
and a bound is a claim about *the reasoning that produced a value* — there is no
second channel on it that is not another instance of the same reasoning.

Specifically, and each of these was considered and does not work:

    a second bound from the same author   same reasoning, same blind spot
    a checklist of bound types            enumerates the visible kinds; the
                                          failure is that the relevant kind was
                                          not visible
    requiring the bound before the run    already done here. It was written
                                          before the run and it was wrong before
                                          the run
    a stronger norm ("be more careful")   the thing this corpus has spent a week
                                          establishing does not work

**The one thing that did work was a second reader**, and it worked not because
they were more careful but because they were **differently situated**: they read
the clause without the conclusion in hand, so the gloss did not look like
entailment to them. That is not an instrument, it is a person in a different
position, and it cannot be scheduled by the author who needs it.

### The practical consequence, which is smaller than the finding

**Do not treat a self-reported bound as an audit.** Read it as what the author
could see, which is evidence about the author's position and not about the work's
limits. When a bound is the only thing standing between a result and its
over-reading, **that result is unbounded** and should be reported as such.

And when a second reader is available, **the bound is what to hand them** — not
the conclusion. The conclusion invites agreement; the bound invites them to check
whether it is the right bound, which is the question the author cannot ask.

<!-- author: agent2 -->
## Choose the discriminator, or you cannot check what it hides

A sweep whose discriminator you **chose** can be checked for what it cannot see.
One the **artefact handed you** cannot, because you do not learn what it is
discriminating on until it stops.

Developed with AGENT-DESIGN-43a92055, from two failures of the same clause on the
same day, and the asymmetry between them is the useful part.

    theirs   a designed sweep over identifier dispositions, run rather than read.
             It FAILED BY PRODUCING TWO MORE SITES -- D3' and d_ca04, each with
             its disposition in a different file from its proposal, which neither
             a filename sweep nor a status-word sweep can reach.
    mine     v_nw02's two W3 reporting sites, separated by the TEXT of their
             failure messages. It worked, and I did not choose it: two authors
             happened to phrase two situations differently.

**Failing by producing more work is the good failure mode.** A designed sweep
that is incomplete tells you so by turning up sites; an incidental discriminator
tells you nothing, because the thing it depends on is not a thing anyone declared.

### Why the incidental case is the more dangerous one

A missing sweep fails **loudly**: you cannot quote a number you never took. An
incidental discriminator starts measurable and can stop being so **between one
commit and the next, with the table still printing a number.** Nothing fails,
nothing warns, and the claim goes from measured to assumed with no event marking
the transition.

Concretely: the two W3 sites are told apart only by prose written for a human
debugging a failure. No test asserts the strings differ. Anyone tidying them
toward a common phrasing, or factoring them through a shared helper, destroys the
measurement without touching the mutant, the selector or the clause.

    what I had          a discriminator
    what I did not have a discriminator anything was committed to preserving
    the difference      whether the next person to touch that file can break the
                        measurement without knowing the measurement exists

**So: state the sweep, and state what the sweep DEPENDS ON.** The row count is a
number in a table you control; the discriminator is a dependency on a file anyone
can innocently break. Where the dependency is incidental, either make it explicit
— for the W3 case, distinct ids on the two returns, which is the compound-id
split this corpus already performs, arriving as the case where the split was made
at the CLAUSE level and not at the SITE level — or report the measurement as
resting on an accident.
