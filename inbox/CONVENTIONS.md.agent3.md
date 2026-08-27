
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
