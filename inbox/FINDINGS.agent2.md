# Findings — Agent 2 (verification tasks)

Staged here rather than written into `FINDINGS.md` directly, which is not this
agent's to edit. Each entry is ready to land as-is or to be merged into an
existing finding by whoever owns the file.


---

## Candidate — two instruments sharing a conversion are one instrument, and a mechanism that explains a wrong number removes the motive to recheck it

**The headline finding of v_ca07.** Two parts, both general, and the second is
the sharper one.

### The instance

`clk_int_div`'s header says it "always generates clean 50% duty cycle output
clock". I measured the duty at every divisor and concluded the header was wrong:
`high = floor(div/2)`, `low = ceil(div/2)`, so 33% at divisor 3. That went into
the specification as clause P2, into the second source, and into the reference
testbench's own check.

**It was wrong. The duty is exactly 50% at every divisor.** At odd divisors the
split is a **half-integer** — divisor 3 is 1.5 high and 1.5 low — because the
transitions use the input clock's falling edges as well as its rising ones. That
is what a 50%-duty odd divider is.

### Part one — independent measurements are only independent if their DEFECTS are

Two measurements produced the wrong answer: the step-1 probe, and, later and
separately, the reference testbench's P2 check. They were written days apart, in
different files, for different purposes, and they **agreed**.

They agreed because both **divided each endpoint by the clock period before
subtracting**. `1.5` truncates to `1`, and the low phase then appears to be `2`.
The same conversion, written twice, is not two measurements — it is one
measurement with two copies, and the agreement between them carries no
information at all.

The trap is that agreement is exactly what corroboration looks like. Two
instruments concurring is the ordinary reason to believe a number, and here it
was the reason the number survived.

**Rule:** before treating agreement between two measurements as confirmation, ask
what conversion, assumption or library they share. Independence is a property of
the failure modes, not of the source files. Two implementations of the same
wrong conversion corroborate; they do not check.

### Part two — a plausible mechanism ratifying a measurement is a reason to recheck it, not evidence for it

Having measured 33% at divisor 3, I wrote that this was *"arithmetically
necessary, since an odd number of input cycles cannot be split evenly"*.

That is true only if the split must land on whole cycles. It need not. But the
argument was clean, it was short, and it explained the observation exactly — and
so it **removed the motive to look again**. A number that looks odd invites a
second measurement. A number with a proof attached does not: the proof is read as
having already done the checking.

This is the same shape as the distinction between a suppressed and an inverted
measurement — the failure that looks like data is worse than the one that looks
like a bug. An **explained** failure looks most like data of all, because the
explanation is doing work that resembles verification while being downstream of
the very number it justifies.

**Rule:** when a mechanism is constructed to explain a measurement, it is not
support for the measurement — it is a reason to re-measure. The order matters: an
argument derived after an observation cannot test that observation, and its
persuasiveness is uncorrelated with the observation being right.

### The count, which is the least interesting part

Three claims that the anchor's documentation was wrong were made about this one
module. All three were defects in my own instruments: a sampling phase that
aliased the pass-through case, an interval measured from the wrong origin, and
this truncation. **Zero defects were found in the anchor.**

The count is worth recording only because it calibrates a prior: on this module,
every disagreement between the documentation and my measurement was mine.

### What it cost, concretely

The wrong rule reached the specification, the second source (which had to be
rebuilt to use both clock edges), and the reference testbench's own checker. It
was caught only because the corrected checker failed against the anchor while
printing "high phase 1, expected 1" — two numbers that were equal as printed and
unequal underneath, because the printing truncated the same way the comparison
had. A submission measuring the way I did would reject conforming hardware at
every odd divisor.

---

## Candidate — a control whose two arms produce identical observables measures nothing, and reports cleanly while doing it

**Proposed as an instance of the existing "instrument reports a different
observable than the claim" class** (Agent 3's F74 and its instances), not as a
new class. It is the *control-selection* form of it.

**The instance.** While measuring `clk_int_div` for v_ca07, I needed to know
whether a divisor change takes effect when `div_valid_i` is held high across it —
a handshake question. The measurement compared **div=4 against div=8** and
counted how many input edges saw `clk_o` high.

Both divisors have a **50% duty cycle**. So the count was 40 of 80 under either
hypothesis: if the change took effect, and if it did not. The comparison had no
discriminating power regardless of what the design did, and it returned a clean,
plausible, symmetric-looking result while having measured nothing at all.

**Why it belongs with the class.** The other instances are an instrument reading
the wrong observable. This one reads the right observable through a **control
that cannot fail** — the two arms are indistinguishable in the quantity being
counted. It is the same failure moved one step earlier, into the choice of what
to compare rather than what to look at.

**What makes it dangerous specifically.** A broken instrument usually produces an
implausible number that invites a recheck. A degenerate control produces a
*clean* one. Nothing about "40 and 40" looks wrong; it looks like a null result.

**Detection.** Before running a comparison, ask what each arm predicts. If the
two predictions are the same number, the comparison is not a control. This is
cheap and it is not automatic — nothing flagged it, and I only noticed because I
went to write down what the result meant and could not.

**Resolution, which is not "measure it better".** The question was converted into
**H2, an obligation on the source**: hold `div_i` stable while `div_valid_i` is
high until `div_ready_o` rises. That is the standard handshake rule, it is what
the contract should have said, and it removes the need for the measurement
entirely. A characterisation of behaviour after a protocol violation is not worth
having.

**Rule:** a control must be chosen so its arms predict different observables. A
control whose arms predict the same number is not weak evidence, it is none —
and unlike a broken instrument, it will not look broken.

**Related, same task, same shape at a different level:** two of the three "the
anchor's header is wrong" claims I made about this same module were mine rather
than the header's — one from sampling a clock at a phase that aliases
pass-through, one from measuring an interval from the wrong origin. Three
measurement-basis defects on one module, none of them in the design.

---

## Candidate — "conservative is safe" is a reflex calibrated for lower bounds, and it silently produces non-conforming artifacts against upper bounds

**A different class from the control-selection instance above.** That one is a
measurement reporting the wrong observable. This one is a **conformance reflex**
producing a wrong artifact — nothing is mismeasured, the thing built is simply
out of spec, and it looks careful while being so.

**The instance.** v_ca07's clause G1 is an upper bound: after a divisor change
the output clock is gated for **at most** 3 × the new period. Writing the
independent second source, I chose to gate for two cycles — deliberately
generous, on the reasoning that holding the output down a little longer is the
cautious thing to do.

It gated for **four**, against a bound of three, on every transition to
pass-through. Non-conforming.

**Two things made it happen, and the second is the interesting one.**

The reflex: *more gating is safer*. That is correct for a setup margin, a hold
time, a settling window — every bound most hardware intuition is trained on is a
**lower** bound, where overshooting costs performance and nothing else. Against
an **upper** bound the same instinct walks straight out of the contract, and it
does not feel like risk-taking while you do it.

The mechanism: the author chose two cycles. **The implementation delivered
three.** The negedge-registered clock enable — present for a good reason, so
gating cannot truncate a high phase — added a cycle that was never in the count.
Nothing in the source says "three"; the number is distributed across a
constant and a register, and only the measurement showed the sum.

**Why second sourcing is where it does damage.** A second source exists to be an
independent reading of the contract. One built on this reflex is *worse than a
careless one*: it is out of spec in a direction its author believes is safe, so
it attracts no scrutiny, and if it is used to validate anything else the error
propagates as agreement. Mine would have been accepted as a conforming variant
that the reference must PASS — encoding a violation as a requirement.

**Detection.** Measure the artifact against the bound rather than reasoning about
the constant. The gap here is between a number the author chose and a number the
implementation produces, and no amount of reading finds it.

**Rule:** when a clause is an upper bound, "generous" is the failing direction.
Every margin deliberately added against an upper bound must be measured end to
end, because the implemented total is not the constant the author wrote.
