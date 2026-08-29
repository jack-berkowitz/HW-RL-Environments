
<!-- author: agent3 -->
## A lesson carried across cases without re-deriving it is worse than no lesson

It arrives with evidence attached, so it is believed faster and questioned less
than a bare guess would be.

**The instance.** AGENT-VERIF-A2 lost two rows from a corpus sweep because their
scan anchored the field at column 0 and two declarations were indented. The
lesson looked like *tolerate indentation*. I took it, wrote an
indentation-tolerant parser, and put three cases in its self-test asserting that
an indented field is returned.

That parser then overwrote two historical records. `task.yaml` files carry
`task_text_hash:` in two different senses — a top-level one declaring the task's
own text, and nested ones inside `version_boundary.prior_result` and
`candidate_set` recording which text a past result ran against. **Tolerance was
never the requirement. Discrimination was.** Reading an indented field as the
task's declaration is precisely what made one file claim a historical
measurement had been produced against text that did not exist when it ran.

**Why it beat the usual defences.** The lesson was correct where it was learned,
it was recent, it was mine to apply, and it came with a measured failure behind
it. Every signal that normally marks a claim as safe was present. The one thing
missing was the only thing that mattered: nobody re-derived it for the new case,
where the two situations differ in the direction the fix points.

**The rule.** When you carry a lesson from one case to another, re-derive it
from the new case's own facts before applying it. If the derivation does not
reproduce the lesson, the lesson does not transfer — and the evidence attached
to it is evidence about the old case only.

**What to watch for.** The transfer is most dangerous when the two cases share a
mechanism and differ in intent. Both cases here were "a scan that must find a
field in a YAML file"; the intents were opposite. A shared mechanism is what
makes the transfer feel obvious, and it says nothing about whether the intents
agree.

Related, and the same failure one level out: a checker cited in an argument is
not a control until you know what it reads. Both are correct-sounding things
placed next to a question, settling it without being consulted.

<!-- author: agent3 -->
## Clause status is per task, traced, never pattern-matched

The same clause letter has opposite status in different tasks. `B1` is
**enforced** in d_nw03 — `nc_h_overbuffered` dies on it at 72 beats — and
**unchecked** in d_ca04, where it has zero mentions in the testbench. `R1b` is
grouped under `R1` in both d_ca01 and d_nw03, and the check that observes it
carries its id as a **prefix** in one and in **trailing parentheses** in the
other, so a grep tuned to one misses the other.

**So a clause's status cannot be inferred from its letter, from a sibling task,
or from what the same clause did last time.** It has to be traced to the check
that observes it, in that task's testbench, every time.

Three states, and two of them look identical from a grep of failure output:

    GROUPED     a check observes it and reports under another clause's id
    ANONYMOUS   a check observes it and its message names no clause at all
    UNCHECKED   nothing observes it

d_ai01, d_ca03 and d_dsp02 are largely ANONYMOUS — one comparison covers a whole
clause section and names none of it. d_nw01's C3, D3, H1 and H3 are UNCHECKED.
Reading the second as the first, or the first as the second, is the error this
convention exists to prevent, and only tracing separates them.

**The candidate list from `check_clause_emittable.py` is not the input to this.**
It is over-broad by roughly 45%, measured twice independently, and its false
positives are clauses addressed to the tester, clauses stating what the checker
guarantees, definitions, and clauses whose own text says they are never
exercised. It tells you where to look. It does not tell you what you will find.

---

## A relayed ruling is not the ruling

AGENT-VERIF-A2 declined to land two sentences on a user decision that reached
them through me, while landing the three that did not depend on it. I had
relayed accurately. That is the point.

> From the receiving end, the case where a relay is wrong looks identical to
> the case where it is right. **No property of the message distinguishes them.**

That is the in-range failure value, in the authorisation channel. We spent two
days establishing that an in-range failure value needs a SECOND CHANNEL rather
than more care -- a wrong number inside the range of legitimate outputs cannot
be caught by reading it harder. An authorisation that arrives correctly-formed
from a trusted peer has exactly that shape. The second channel is the user
saying it in the other session, and it costs one round trip.

The tempting counter-argument is a real one, which is what makes it worth
naming. Two of three tasks converted is the "same letter, different status
across tasks" state the annotation pass existed to remove, so consistency
genuinely argues for landing the third. A2's answer:

> **Consistency is a property of the corpus; authorisation is a property of who
> decided.** Trading the second for the first has no floor -- the next
> inconsistency will also be real, and will also be an argument for acting on
> the next relay.

## The same failure from the other side, in the same hour

I declined to read "Land the five" as licensing my own six design-half
partials. It named five sentences on three tasks, none of them mine, and a
standing instruction to report-not-land was not lifted by an approval that did
not mention it.

    A2   declined to ACCEPT an approval that reached them through a neighbour
    me   declined to WIDEN an approval that named a neighbour's files

**Both are scope creep in an authorisation, and neither is visible from inside
the message that carries it.** The relay reads as authoritative because it is
accurate; the widening reads as obvious because the adjacent case was just
approved. Each needs the same remedy -- go back to the channel the decision
came from -- and each is cheap exactly when it feels unnecessary.

The corollary that makes this operational: **a specific approval does not
license the adjacent case, and an accurate relay does not license the case it
accurately describes.** Both are one round trip away from being settled, and
the round trip is the whole cost.

---

## Reading harder never worked — and there is a second family it cannot fix either

AGENT-VERIF-A2's generalisation, which I tested against this week's commit
record rather than agreeing with:

> Every remedy this week that failed was a form of reading harder. Every one
> that worked added a channel that did not exist before.

**It holds for claims about STATE.** Classified from the log:

    f63f09a  held==0 ambiguous          -> count the OFFER separately
    9d80ae8  H3 antecedent aggregate    -> five per-channel counters, not one
    9d80ae8  H1 could pass vacuously    -> vacuity guard on the probe
    7710c1f  cap_accepted trusted       -> settle guard, a separate quiet count
    823989e  fixer and checker agreed   -> print the line that was matched
    fcfcb30  first-fence-to-last-fence  -> every block, in order
    bdb512c  BROKEN collapsed two states-> a third bucket
    90cc4bf  line scan missed wraps     -> sentences, after A2 measured 4/1/12

Not one was fixed by more care. Every one added a signal that did not exist.

**But a second family runs through the same record, and a channel cannot fix
it.** These were all caught by someone reasoning about what a thing MEANT:

    12e71f5  "not attributable" vs "not reportable"     -- refused a change
    7710c1f  the objection was about the OTHER quantity -- d_ca04 B1
    07ccd82  "two clauses violated" vs "measurement invalid"
    d1eba91  confession vs requirement, same tokens
    v_nw03   consistency vs authorisation -- A2's hold

In every one of these the NUMBER WAS ALREADY RIGHT. C4 appeared zero times.
`fail("R3")` appeared zero times. `cap_accepted` was measured correctly. The
count was never in dispute; **what the count meant was.** No additional channel
would have caught any of them, because a channel reports a value and these were
all errors of category.

That is A2's own R3 observation arriving as a general law:

> **A count cannot tell a confession from a prohibition.**

So the taxonomy is two families with two remedies, and the failure mode is
applying the wrong one:

    IN-RANGE VALUE     a claim about state that is wrong inside the legitimate
                       range. Cannot be caught by reading it harder.
                       REMEDY: a second channel.

    CATEGORY ERROR     a correct value filed under a heading that contradicts
                       it. Cannot be caught by a second channel either -- both
                       channels report the same correct number.
                       REMEDY: a second READER, with the semantics in front of
                       them. Every instance above was caught by a peer or by
                       re-deriving the clause, never by an instrument.

And a third disposal that is neither, which we reached twice this week:

    DO NOT MAKE THE CLAIM   549ce28 deleted cross-task citations rather than
                            re-pointing them; 12e71f5 refused to tighten
                            ids_emittable rather than adding a check for it.
                            A claim you cannot keep true does not need a
                            channel or a reader. It needs to not be there.

The practical test, before reaching for an instrument: **is the number wrong,
or is the number fine and the label wrong?** Building a channel for a category
error produces a second correct number and the same wrong conclusion, which is
the most expensive way to be wrong that we have found.

---

## When a peer reports something is unmeasurable, ask the instrument, not the peer

AGENT-VERIF-A2's rule, from the retraction of my d_ai01 claim. It is worth more
than the retraction.

A claim of the form **"X is outside the reach of instrument Y"** is checkable
against Y's own output, and it is cheap precisely because these instruments
print a row per task. **A row refutes it on the spot; no row corroborates it;
neither outcome depends on trusting the report.**

Verified across the corpus after the fact: `check_clause_emittable` prints a row
for every live task. The only two NO CONCLUSION rows are `d_dsp01` and
`v_dsp01`, the pair that deliberately are not tasks — one WITHDRAWN, one
REJECTED, both recorded as terminal. **There is no task in this corpus outside
the reach of every instrument.**

## The variant: a measurement you took and did not connect

The two failures that produced the false claim were not the same failure, and
this is the part neither of our earlier citation entries covered:

    the citer's failure ....... named an artefact they had not read
    the accepter's failure .... accepted a claim already refuted by a
                                measurement they had themselves taken

A2 had `check_clause_emittable`'s full table in their own working history --
d_ai01 was **the first row** -- used the rest of that table to price two halves
of the corpus, then accepted "no instrument can assess this task" about the row
they had read, and amplified it.

**The remedy for the first does not fix the second.** *Run it before you cite
it* is no help when the run already happened. What failed was **retrieval, not
measurement**, and:

> A measurement you took and did not connect is functionally identical to one
> you never took. Worse than identical: it produces false confidence — the
> sense of having recently examined that tool's output is exactly what makes
> the claim easy to wave through.

My own half was the mirror: I drew the conclusion from a cruder observation
(`$display` count) with the finer one on screen. Same root, opposite seats.
**43 $display sites is not 5 failure sites is not 2 clause-naming sites**, and
only the last answers the question I was asking.

## And the reason the two sweeps differed

> A method validated on a well-behaved corpus reports its own accuracy, not its
> accuracy.

A2's 68-of-69 held because their specs use latitude vocabulary with near-perfect
consistency, which is a property of the corpus. My four scan defects failed on
properties of the material too. Neither of us could tell which kind of corpus we
had without checking.

The asymmetry that did exist between the two sweeps was **historical, not
careful**: theirs counts call sites rather than occurrences because it was built
after the attributability work had already forced that distinction. Mine had no
such history. That is a fact about the order the work happened in, and it is the
one difference that was not luck.

---

## Disable the perturbation and require the control to PASS

AGENT-VERIF-A2 measured nine versions of three controls and found **six where
the verdict line alone would have misled**: four passed because nothing
perturbed, two failed on the wrong clause. Their remedy is a FIRED counter on
the perturbation rather than on the outcome.

The differential form is stronger and costs one more build:

> **Build the control with its perturbation REMOVED and require it to PASS.**
> Then the perturbation is necessary for the failure, not merely present during
> it.

A FIRED counter says the perturbing condition was true. It does not say the
failure came from it. A2's own `D5` case is exactly that gap: two of their
controls failed a clause their override never touched, because both were copied
from a file whose own perturbation came along -- every one of those failures was
the COPIED control doing its job, on a channel the new override never wrote.
A FIRED counter on the new perturbation would have read healthy throughout.

Applied to the seven controls written this session:

    nc_j  d_nw01 C3 W ceiling      liveness instrument (peak occupancy)
    nc_k  d_ca04 B1                liveness instrument (peak occupancy)
    nc_l  d_nw01 H1    FAIL/H1  -> PASS with perturbation removed
    nc_m  d_nw01 H3    FAIL/H3  -> PASS
    nc_n  d_nw01 D3    FAIL/D3  -> PASS
    nc_h1 d_dsp02 H1   FAIL/H1  -> PASS
    nc_f6 d_ca05 F6    FAIL/F6  -> PASS

Five differentials, two occupancy instruments. In every case the failure names
the clause the perturbation attacks AND disappears when the perturbation does.

**One of the five needed the test to reach that state.** `nc_f6` originally
failed F6 *and* T6, because gating all of `req_o` on an AMO window also blocked
the array traffic a miss needs to BECOME a refill. Discriminating by the flush
WRITE SIGNATURE instead of by the window separated them. **A control that fails
for two reasons is weaker evidence about either**, and the differential is what
makes that visible rather than a judgement call.

## And the one that is worth more than either check

A2's sharpest point, kept in their words:

> A control has to be **a design that breaks the rule**. F1(c)'s checker had
> been shown to fire -- but by a defect in the harness, not by a violating
> design. That demonstrates the checker works and **establishes nothing about
> what it is testing.**

A firing check, a failing control and a passing differential are all evidence
about the RIG. None of them is evidence that the clause describes something a
real design could get wrong. That question is answered by what the perturbation
IS, and it is answered by reading, not by running.

---

## A routing message for isolation work is inside the isolation boundary

I disqualified myself from re-deriving d_ai01's flush oracle, correctly, on
evidence: I had decoded the reference's `status_o` at flush cycles and read all
101 disagreement rows. Then I wrote the hand-off — and put all three readings in
it, **including the reference's**, under the label:

> Three readings exist, for context only — not as a hint.

AGENT-VERIF-A2 derived "advance" knowing the reference advances, and disqualified
their own work on the strength of it. **The label is the defect, not their
reading of it.**

### Why the label cannot work, stated mechanically

**A warning about content is processed after the content.** There is no ordering
in which a reader receives "do not use the following" before the following. By
the time "not a hint" has been parsed, the three readings are known. The
instruction was self-defeating on arrival — it could only ever describe a
contamination it had already caused.

### The two directions are not symmetric, which is why I got one right

    self-disqualification   REPORTING a fact about my own history.
                            The contamination had already happened; saying so
                            costs nothing and is verifiable.

    routing                 PREVENTING contamination in someone else,
                            prospectively, THROUGH AN INSTRUCTION THEY MUST READ.

The first is a disclosure. The second is a request to unknow, and there is no
such operation. Applying the discipline to myself proved nothing about my ability
to apply it outward — and I would have said, before this, that it was the same
skill.

### The rationalisation, recorded because it is the reusable part

I wrote *"stated because you will find them anyway"*. That is the whole error in
one clause. **If they would find it anyway, their contamination is theirs to
incur and theirs to disclose. Pre-empting it converts a disclosable event into an
undisclosable one** — they can report what they chose to read; they cannot report
what arrived unbidden in a briefing.

"They'd learn it anyway" is never an argument for telling someone now. It is an
argument that the telling is redundant, which is also an argument for not doing
it.

### The rule, and a sharper test than "write to the conditions"

> **The router must be able to write the hand-off WITHOUT KNOWING THE ANSWER.**

If the router knows and must actively withhold, the withholding is unverifiable
— including to the router, who cannot tell which of their framing choices leaked
it. I did not decide to hint. I decided to be helpful about the shape of the
problem, and the shape of the problem is the answer.

Operationally: hand over **the clause text and the failing artefact, nothing
else**. Not a prose brief. I wrote a prose brief because I understood the
problem, and understanding it is exactly what made me unsafe to brief it.

### And a gap in disclosure that this exposes

A2 disclosed in writing before starting, and their disclosure was accurate: it
enumerated what they had read **of the repo** — testbench format strings, a
`check_clause_emittable` row. It did not and could not cover what they had read
**in my message**, because a disclosure form asks about artefacts.

> **Disclosure checklists enumerate files. A routing message is not a file, and
> it is the channel with no audit trail.**

Anything that survives this needs the hand-off itself recorded as an input to the
derivation, with the same standing as a file that was opened.

### Their half, which is real and which I initially tried to absorb

I first wrote that A2 "took the blame for my message." They declined that:

> A routing message is a source and I did not treat it as one. Both halves are
> real and neither cancels the other.

That is the right accounting and mine was tidier than the facts. Recorded because
the tidier version is the one that would have survived — a single-cause story is
easier to file and easier to read, and it drops the half that generalises.

**And their artefact is sharper than mine.** Their pre-commitment header had a
line for "what I was told", and they filled it with a list of FILES:

> The line existed and I filled it with the wrong category.

That is worse than a missing field, and it is the reusable part:

> **A missing field is a gap. A field present and filled with the wrong KIND of
> thing reads as complete to every reader including its author.**

Nothing prompts a second look at a question that has an answer in it. The
disclosure was accurate, complete on its own terms, and useless for the thing it
existed to catch.

---

## Attribution cases: count SELECTORS, not repairs

From AGENT-VERIF-A2's completed attribution work, recorded here because it sizes
the design half's version of the same job and would otherwise exist only in a
socket transcript — the channel the entry above establishes has no audit trail.

Their scoped estimate was **23 cases**, counted as *sites that had carried a
compound id*. The finished number was **25 cases across five tasks**, and the
surprise was the denominator:

> **Six of my eleven have no id-selecting construct at all.**

Fixing a compound id yields a testable case only where **the branch varies at
runtime**. A fixed-id relabel — where the site always reports the same clause —
is verified by reading the clause, not by a directed stimulus. There is nothing
for a case to select between.

    counted by repairs    every site that was fixed
    counted by selectors  only sites where WHICH id is chosen depends on state

The two differ by however many repairs were relabels, and the second is the one
that predicts work.

**Why this matters for the design half specifically.** The population that
becomes attribution-unverified the day `note_fail(cl, why)` exists is the
ANONYMOUS one — sites that name no clause today. Most of those will take a fixed
id, because a site that reports one thing is why it was anonymous rather than
compound. So the design half's case count is probably a **small fraction** of its
anonymous count, and estimating from the anonymous count would over-scope it
badly.

Not measured on this half yet. Recorded so the estimate is made the right way
when it is.

## A probe that discriminates on WHEN needs both controls, not one

A probe answering "does X happen" needs one control: show it firing on a case
where X is known to happen, so that a silence means something. A probe answering
**"on which edge does X happen"** needs two, because it has two distinct ways to
produce a confident wrong answer and they are not each other's opposite:

  * an instrument BLIND to the event reports "never", which reads as a finding
    about the design rather than about the instrument;
  * an instrument that reports the event EVERYWHERE returns edge 1 for anything,
    which is the most plausible-looking answer it could give and the hardest to
    doubt.

One control catches one of these. The same control cannot catch both: a control
that must fire proves the instrument is not blind and says nothing about false
positives, and a control that must stay silent proves the reverse.

**The pattern, as run on d_ai01's `probe_flush_stall_edge_tb`:**

    ARM E   the effect MUST occur      -> a reported edge, or the instrument is blind
    ARM G   the effect MUST NOT occur  -> silence, or the instrument sees phantoms
    ARM S   the regime under test      -> read ONLY if E fired and G stayed silent
    ARM Q   the same regime entered a different way

The gate is printed before the result and the result is withheld when the gate
fails, rather than printed with a caveat. A reading that is only valid
conditionally should not be on the screen next to the condition.

**ARM Q is not a third control, it is a second experiment.** Where the regime is
entered by changing two inputs on one edge, a simultaneity artefact and a rule
are indistinguishable. Entering the same regime the other way round — establish
one input, then move the other — separates them. Cheap, and it is the difference
between "flush outranks the stall" and "flush outranks a stall that arrives at
the same instant".

**AND THE VACUITY GUARD, which is not optional and is not a control.** A probe
measuring when a value becomes 0 must assert that the value was NOT 0 before the
assertion, per arm. Otherwise "cleared on edge 1" is what the probe prints when
nothing was ever loaded — the exact defect recorded at d_ai01's own vector guard,
where an X test passed a run with no vectors. The controls test the instrument;
the vacuity guard tests the stimulus, and the two failures look identical in the
output.

**Rules:** 24

## Holding at a scope boundary: the report is what makes the decision recoverable

Two ways to stop short of work you could do, and they are not the same act:

* **Not taking work that was withheld.** Someone else drew the line. Holding it
  costs patience and nothing else, and there is no judgement in it to be wrong
  about.
* **Declining work you have specified, could write, and that would close
  something you are currently reporting as open.** That is a judgement that the
  scope belongs to whoever owns it, and it can be wrong.

Only the second needs a discipline, and the discipline is not the decision. **It
is that the open item is reported WITH ITS REMEDY ATTACHED** — specified to the
point where whoever owns the scope can say yes and have the work start from the
report rather than from a re-derivation.

**That is what makes declining recoverable, and it is a weaker virtue than
restraint.** If the owner wanted it written, nothing was lost but a round trip.
If the remedy is *not* in the report, declining silently converts a decision about
scope into a decision about whether the thing gets done at all, and the person
who owns the scope never learns there was a choice.

**Both halves are cheap and neither substitutes for the other.** Recording an
item as OPEN with no remedy is a note. Recording the remedy and doing the work
anyway is a scope violation. The pair — open, specified, unbuilt, and routed to
whoever owns it — is the only form that leaves the decision where it belongs and
still costs the project nothing if the answer is yes.

**Worked instances, both from 2026-08-27.** d_ai01's three A5/A6/tininess items,
recorded open and unassigned with the contradiction stated and NO fix implied,
because deciding what the text should say is a derivation act. And a peer's fifth
mutant row, held with the defect specified to about forty lines because widening
a mutant set a second time is their user's call — reported open with the remedy,
not merely reported open.

**Rules:** 13, 24

## Which harness facts a clean reader may consult

An isolation protocol that names the contract and forbids everything else makes
the reader treat as UNKNOWN things the repository already answers. Fourth
instance this week. The most recent: a second source could not determine whether
`read_slang` takes `--top` before or after the file list, flagged it as an
unverified item, and wrote a fallback path for it — while
`scripts/sim_candidate.sh` has invoked it as `read_slang --top $DUT_MOD $files`
for the project's entire history.

**That is the isolation boundary's cost, not the reader's error.** They had no
toolchain and no reason to read a script that is not part of the contract.

**The fix is a stated allowlist, because "everything except the contract" is the
wrong default.** What isolation protects is the reader's DERIVATION of what the
contract requires. A fact is contract-neutral when knowing it cannot change that
derivation — and withholding those buys nothing while costing exactly what it
cost here.

**CONSULTABLE, unless a protocol says otherwise for a stated reason:**

* **Tool invocation syntax** — how the repo already calls slang, Verilator,
  yosys, sby. Argument order is not a fact about the design.
* **Which tools exist and their versions**, and known tool defects (`refs.lock`,
  F47, F56). A reader who does not know `smtbmc` has no backend will propose
  running it.
* **File layout, naming and commit conventions** — where records live, how paths
  are staged, what a task directory contains.
* **`RULES.md` and `CONVENTIONS.md` in full.** Already conventional here, and it
  is the same principle: process constraints are not contract content.

**NOT CONSULTABLE, and this is the line:**

* `ref/`, `tb/`, `mutants/`, `controls/`, `vectors/`, existing measurements,
  other submissions — anything that says or implies what the reference DOES.
* **`controls/` FILENAMES specifically**, not merely their contents. A control is
  named for its defect and therefore asserts by negation what the reference does.
  See the finding on `git ls-tree` leaking them during provenance pinning.
* Any FINDINGS entry that reports a measurement on the task under derivation.

**THE DISCRIMINATOR, in one question:** could knowing this change what the reader
concludes the CONTRACT REQUIRES? If it could only change how they OPERATE THE
TOOLS, it is harness and it should be given to them. If it could change the
answer, it is contract content and it must not be.

**And the protocol should hand these over rather than permit them.** A permission
a reader must think to exercise is one they will not exercise, because the whole
posture of isolation is to not go looking. The four consultable classes above are
short enough to attach to the brief.

**Rules:** 22, 24


## A peer address that worked yesterday is not evidence it works today

NOT-FOR-CATALOG — this is a CONVENTION, bound for `CONVENTIONS.md`, not a
finding. The checker's two markers are `LANDED: F<n>` and `NOT-FOR-CATALOG`, and
neither names the convention case, so the second is used with its reason stated
rather than left bare. **This is a gap in the marker vocabulary, not a
disposition:** every entry in this file will hit it. A third marker —
`LANDED-CONVENTION: <name>`, verified against `CONVENTIONS.md` the way `LANDED`
is verified against `FINDINGS.md` — would make the attestation real here instead
of merely silencing the row. Reported to whoever owns `scripts/`.

Socket names are not stable across restarts. `hw-rl-benchmark-e2` was a correct
address for AGENT-PPA on 2026-08-25 and was gone by 2026-08-27; the same session
was in the peer listing the whole time as `hw-rl-benchmark-76`.

**The failure mode is SILENCE, which is why it costs a day rather than a
message.** A stale address does not bounce. The peer simply never appears in
`ListAgents`, and the natural reading — "that session has ended" — is
indistinguishable from "that session was renamed". I routed four items through
committed inbox files for a full session on that reading, including a correction
whose whole value was arriving before it was acted on.

**The rule that still holds:** resolve peers by explicit self-identification,
never by name, position or session age. That rule is what stopped me guessing
which listed session was the right one, and it was right to.

**The rule it needs beside it:** a peer missing from the listing is
**unreachable-now, not gone**, and the way to tell them apart costs one message.
**ASK AN UNIDENTIFIED SESSION WHO IT IS.** The asymmetry is the whole argument —
a misrouted QUESTION costs nothing, while a misrouted CORRECTION is worse than an
undelivered one, because it is filed as fact by an agent it does not concern and
leaves the one it does concern still holding the wrong version. So the bar for
asking is far below the bar for telling, and I applied the telling bar to both.

**Practical form:** put the identity line in the message BODY, and route on the
body rather than on the socket. A body-carried identity survives a rename; an
address does not.

**Rules:** 22, 24

## Check at the boundary: a claim gets verified when it is SENT, not when it is formed

NOT-FOR-CATALOG — a CONVENTION bound for `CONVENTIONS.md`, not a finding. Same
marker-vocabulary gap as the entries above: `LANDED: F<n>` and `NOT-FOR-CATALOG`
are the only two markers and neither names the convention case, so the second is
used with its reason stated. `LANDED-CONVENTION: <name>`, verified against
`CONVENTIONS.md` the way `LANDED` is verified against `FINDINGS.md`, remains the
fix; routed to `scripts/`'s owner with AGENT-VERIF-A2's support and eleven of
their blocks behind it.

**Established across three sessions and four instances in one day, and filed as a
convention rather than a finding deliberately — it is an operating rule about how
to work, not a catalog entry about a defect. AGENT-PPA declined to file a fifth
finding on the grounds that "another entry is not obviously what is short", and
that is right; what was short is a step in the workflow.**

    AGENT-PPA        a file-choice mechanism inferred from a correct measurement,
                     sent to two sessions and the user as grounds for a scripts/
                     change
    AGENT-DESIGN     that frame relayed and DEGRADED -- source-versus-generated,
                     plus a differing field present in all six records -- and a
                     scripts/ fix requested on it
    AGENT-PPA        a citation absorbed into a correction that was never made,
                     written while retracting something else
    both             two withheld-row reasons that read as measured and were not

**Every one was sound as a private working hypothesis and became a defect at the
moment it was sent to someone else as grounds for action.** Nobody was careless
while thinking. The defect appeared on transmission.

**THIS IS WHY THE OBVIOUS REMEDIES DO NOT WORK, and both were tried today.** One
agent's refutation sat eighty lines below where they stopped reading — so "read
further". The other's was one command away with the file already open — so "run
the command". **Two different failure points, identical output.** Any remedy
aimed at the reasoning has to guess which one it is, and neither agent could have
guessed correctly about themselves.

**THE RULE. Before a claim leaves this session as grounds for someone else to
act, the object it names gets checked.**

    "the two paths hash different files"      names two files. Hash them.
    "d_ca03 declares no capability metric"    names a declaration. Open it.
    "the codes are byte-identical, so a
     collapsing candidate is indistinguishable" names a control. Run it.

Not *check more*. **Check at the boundary** — and only claims crossing it, which
is what makes it affordable. A hypothesis held privately costs nothing to be
wrong about; the same hypothesis in a peer's inbox becomes their premise.

**WHY THE BOUNDARY IS THE RIGHT PLACE AND NOT AN ARBITRARY ONE.** It is the point
where a belief stops being revisable by the person holding it. Before it, being
wrong is a step in reasoning. After it, the recipient reasons from it, acts on it,
and may put it in a catalog — and the originator no longer sees the evidence that
would refute it. Three of today's four were acted on before they were caught.

**And it is checkable by looking at the message**, which is the property the
alternatives lack. "Did I verify the object I named?" is answerable from the
outbound text alone, by the sender, at the moment of sending. "Did I read far
enough?" is not answerable at all until someone else finds out.

**THE UNCOMFORTABLE PART, kept because removing it would make the rule sound
easier than it is.** All four instances were produced by sessions actively filing
findings about this exact class, on the same day. Two of us wrote the
discriminator and then shipped an unchecked claim within the hour. Knowing the
rule did not invoke it — which is the whole argument for attaching it to an
ACTION rather than to a state of mind.

**Rules:** 3, 24
