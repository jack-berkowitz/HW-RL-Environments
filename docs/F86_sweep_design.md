# F86 conditional-clause sweep — the eight design specs

**AGENT-DESIGN-43a92055.** The design half of the catalog-wide sweep scoped in
F86. `AGENT-VERIF-A2` holds the eleven verification specs. `d_dsp01` is withdrawn
under F54 and out of scope.

**Status: the denominator is established and two hits are closed by measurement.
Everything marked CANDIDATE is a reading, not a verdict** — F86's own rule is
that a clause is declared unfalsifiable by a control that passes, never by
inspection, and the two accusations that went wrong here went wrong exactly that
way.

---

## The instrument, and why it is validated before it is trusted

**107 conditional clauses** across the eight specs — every normative clause whose
text carries a condition rather than an unconditional requirement.

Narrowing them uses `AGENT-VERIF-A2`'s test, made mechanical: **is there latitude
between the stimulus and the condition?** Where the antecedent is a driven input
the harness owns it, no conforming design can decline to receive it, and the
clause is forced by construction. Where the antecedent references a signal the
**design** drives, the design decides whether the state is ever entered.

**The first version of that filter found 2 candidates and missed `d_ca01` R1 — a
confirmed instance.** It searched only a window after the conditional marker, and
R1's design-driven reference sits later in the sentence. A filter that cannot
find a case already proven is not evidence about cases that are not, so it was
widened to the whole clause body and **validated against both measured instances
before being run on anything else.** It now over-includes, which is the safe
direction: a candidate that reads as forced costs a reading; a missed one leaves
a live gap.

    107 conditional clauses
     94  no design-driven signal              -> FORCED by construction
     13  design-driven antecedent             -> a control decides each

---

## The thirteen

### Closed by measurement — 2

| task | clause | evidence |
|---|---|---|
| `d_dsp02` | **H3** | `nc_h3_evades_antecedent` passed the whole suite under the old contract while driving `h3_guard_true` to 0. Closed by **H1b**. |
| `d_ca01` | **R1** | `nc_r1_evades_antecedent` fails 0/16 on the condition floor and nothing else. Closed by **R1b**. |

### UNREPORTABLE — 2, and they are the fix, not the problem

`d_dsp02` **H1b** and `d_ca01` **R1b** are themselves conditional on a
combinational dependency the testbench cannot observe. They have force and no
instrument — the D7 class. Already recorded as the enforceability caveat in both
`version_boundary` blocks and both candidate READMEs. **The sweep rediscovering
them independently is the check working**, not a new finding.

### CANDIDATE HIT — 1, and it is the same shape

**`d_nw03` R1.** *"Once valid is asserted it stays asserted, with data, keep,
last and dest held stable, until the transfer completes."* It governs **the
stream's** valid and ready — which includes `m_valid_o`, the design's own output.

**There is no mirror clause and no licence.** That is `d_dsp02` H3 and `d_ca01`
R1 exactly: a design gating `m_valid_o` on `m_ready_i` empties the antecedent
rather than violating the consequent.

**Not confirmed. It needs `nc_r1_evades_antecedent`'s equivalent built and run**,
and until then it is a reading. Two readings of this kind have been wrong here
before.

### DELIBERATE LICENCE, in tension with its own clause — 1

**`d_dsp03` L4**, and it is the most interesting result in the sweep:

> `in_ready_o` MAY DEPEND COMBINATIONALLY ON `in_valid_i`, and `out_valid_o` may
> depend combinationally on `out_ready_i`. The harness drives neither from the
> other, so a design that gates either way cannot deadlock against it. **A fully
> combinational unit is conformant.**

`d_dsp03` is the **only one of the eight that addressed the output side
deliberately** — and it decided the *opposite* way from H1b and R1b.

So this is not a gap. It is a decision, with a consequence nobody appears to have
drawn: **d_dsp03's own output stability clause is emptied by the construction L4
licenses.** A design gating `out_valid_o` on `out_ready_i` never has valid high
while ready is low, so *"once asserted, `out_valid_o` stays asserted"* has no
antecedent — **and that design is conforming, by explicit licence.**

The stability sentence is therefore decorative on this task rather than wrong.
**Two coherent resolutions, and it is a decision, not a defect:**

1. **Narrow L4** to the input side only, matching H1b/R1b, and the stability
   clause regains force.
2. **Keep L4 and drop the output stability sentence** as non-normative, since a
   fully combinational unit being conformant means output-side stability is
   genuinely not required here.

Doing neither leaves a clause that reads as a requirement and is not one.
`d_ca04` already carries a mirror clause, so of the eight: two now closed, one
already mirrored, one deliberately licensed, one candidate hit, three not
applicable.

### Needs a firing count, not a control — 1

**`d_ca01` M3.** *"At most one memory transaction is outstanding."* The check is
`m3_overlap_err == 0` — a **never-happens** assertion, which is vacuously true
for a design that issues no memory requests at all. The harness drives misses so
a conforming design must issue them, but **nothing measures that it did.** Rule
36's remedy applies directly: count the memory transactions and gate on non-zero.
Cheaper than a control and it settles the question.

### FORCED by reading — 6

`d_ai01` C1, C2, C3, C4 — the antecedents are `reg_enable_i`, `flush_i`,
`accumulate_i`, `row_clk_gate_en_i`, all driven; `z_o` appears in the consequent,
which is why the widened filter caught them. `d_ca03` A11 — a design that never
retires satisfies it vacuously, and **L2 forces retirement**, which is the "name
the clause that forces it" test passing. `d_ca03` L2 and `d_dsp02` R2 — driven
antecedents.

---

## What this sweep has not done

**No control has been built for `d_nw03` R1**, so its status is a reading and is
labelled as one throughout. The two closed entries are closed because a control
was built and run, and that is the only difference between them.

The 94 clauses classed FORCED were classed by a mechanical filter plus a reading,
not by measurement. The filter over-includes deliberately, so a false negative
there would have to be a clause whose antecedent is design-controlled while
mentioning no design-driven signal anywhere in its body. That is possible and it
is the sweep's known blind spot.
