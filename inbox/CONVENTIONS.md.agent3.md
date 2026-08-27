
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
