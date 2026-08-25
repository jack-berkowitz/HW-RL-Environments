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

### It happened a second time on the same module, which makes it a property

**Clause E3, found later and independently.** E3 says disabling must not truncate
a pulse. Written the way the specification stated it — one cycle of grace after
`en_i` falls, then low on every input edge — the check **failed the anchor** at
divisor 5. At an odd divisor the high phase is a half-integer, so its tail runs
past any whole-cycle grace. The forty-edge figure in the spec had been
generalised from an even-divisor observation, exactly as the duty rule had been.

Same module, same quantisation, two different clauses, arrived at from opposite
directions — P2 by an instrument that truncated, E3 by a bound expressed in the
wrong units. Once is a mistake in a clause. **Twice is a property of the module**:
this design's contract is half-integral wherever the divisor is odd, and any
quantity written in whole `clk_i` cycles is wrong at half its domain and right
everywhere an even divisor is used, which is everywhere one is likely to look
first.

The fix in both cases was to stop expressing the quantity in cycles. P2 became a
comparison in raw time units; E3 became a **width** — the final high pulse is a
full half-period — which is correct at every divisor and needs no constant.

**Rule:** where a contract quantity can be half-integral, treat every
whole-unit expression of it as a defect until measured at the odd cases. Not a
clause-level review — a module-level one, because the hazard is in the domain,
not in the sentence.

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

---

## Candidate — a clause with a stated measurement and no instrument, and the same half-integer that broke P2 breaking it again

**Same class as the P2 finding above, arrived at from the opposite end.** There
the instrument existed and measured the wrong thing. Here the *measurement was
stated in the specification* and no instrument existed at all.

**The instance.** v_ca07's clause E3 read: *"Disabling does not truncate a pulse.
`clk_o` is not observed high after `en_i` falls. Measured at input-edge
resolution: low on all 40 input edges after `en_i` fell."* That italic line is a
claim that a measurement was taken. The reference testbench contained **no E3
check of any kind** — a grep for the clause id returned nothing. The clause had
been exercised only by E1, which counts *rising edges*, and an output stuck
permanently high has none. E1 reports such an output as a clean disable.

It surfaced in step 5c: a mutant keyed on "idles high while disabled" **passed**,
against an anchor that does not idle high. A defect passing on a correct design
is a statement about the reference, not the design.

**Then the same hazard as P2 bit the new instrument on its first run.** Written
as the spec said — one cycle of grace, then low on every input edge — it failed
**the anchor**, at divisor 5. At an odd divisor the high phase is a
*half-integer*, so its tail runs past any whole-cycle grace. The forty-edge
number in the spec had been generalised from an even-divisor observation, exactly
as P2's duty rule had been.

**The fix was to stop measuring a deadline and measure a width.** What E3 is
about is that the final high pulse is a *full half-period* and the output then
stays low. That quantity is correct at every divisor and needs no grace constant.

**Two rules, and the first is the one I would not have written before this.**

- A *stated measurement* in a specification is a claim, and it is not
  self-executing. Every italic "Measured:" line is either backed by a check in
  the reference or it is decoration that reads as evidence. Grep the clause ids
  against the reference; the ones with no match are the exposure.
- Where a quantity can be half-integral, a bound expressed in whole units is
  wrong at the odd cases and right everywhere you are likely to look. This is now
  **two clauses on one module** — P2's duty and E3's tail — broken the same way.
  A half-integer in the contract is a spec hazard, not a fact about one clause.

---

## Candidate — a generator that writes into a directory a runner enumerates must own that directory

**Instance, and it invalidated a published number before anyone read it.**

v_ca07's step-5c runner globs `mutants/policy/*.sv` and grades every file it
finds. `gen_mutants.py` wrote into that directory but never cleaned it. Two
things followed, and each on its own is enough:

- A mutant was **re-keyed and renamed**. The generator wrote the new name; the
  old file stayed. Both were graded. The stale one had been built against a
  `dut2` since corrected, so it was measuring a design that no longer exists.
- The generator **raised on the first failed substitution**, so tags after it
  were never rewritten — and their previous outputs, built against the old
  `dut2`, remained in place and were graded as current.

The run reported **22 of 22** and every row read "as expected". Nothing in the
output distinguishes a stale artefact from a current one, because the runner has
no way to know what should be there. That number is void; the honest re-run was
21 of 22.

**Why it is worth a finding rather than a fix.** The failure is not "I forgot to
clean up". It is that the *set being measured was inferred from the filesystem*
rather than declared, so the measurement silently redefined itself. Any runner
that enumerates a directory has this exposure, and the more careful the naming
discipline the more likely a rename leaves a plausible-looking orphan.

**Three defences, in order of strength.**

1. The generator **wipes** the directory before writing. A failed generation then
   leaves a file *missing*, which is loud, instead of *stale*, which is silent.
2. The generator **validates every substitution before writing anything**, so one
   bad pattern cannot leave the tags after it untouched.
3. The runner **checks the two halves are the same size** and refuses otherwise.
   Defence 1 makes short sets possible; this is what makes them visible.

**Rule:** a set inferred from a directory listing is not a declared set. Either
the producer owns the directory outright, or the consumer verifies the count
against something declared elsewhere — and preferably both, because they fail in
opposite directions.

---

## Candidate — stimulus that spends the one cycle it needed, and a survivor blamed on the guard twice before the stimulus was suspected

**A sharpening of "a survivor is a question about the apparatus".** The rule is
right; this instance is about *which part* of the apparatus, and how a plausible
first answer can hold up a diagnosis through two rounds.

**The instance.** v_ca07's mutant `m5` violates H4: a request arriving *during a
transition* is refused rather than deferred. It was killed on the anchor and
survived on the independent second implementation.

- **First reading — the guard.** It counted *deferrals*, and how often a deferral
  happens is a consequence of latitude L2/L4, not a contract quantity. True, and
  a real defect. Re-keyed. Still survived.
- **Second reading — the guard again.** It used the second design's own FSM state
  for "in transition", which is implementation-private; re-derived from the ports
  as *accepted a change, no new rising edge yet*. Also true, also a real defect.
  **Still survived.**
- **Third reading — the stimulus.** Instrumenting the mutant showed the guard
  **armed four times** and the reference still passed. The reference's H4 phase
  dropped `div_valid_i` for one cycle between the two requests. That one cycle is
  the *whole* of a fast implementation's transition, so by the time the second
  request was offered there was no transition left to offer during.

**The general shape.** Phase D did not fail to detect the defect — it stopped
*exercising the clause at all*, and only on the implementations that resume
fastest. A latitude clause (L2, how long gating lasts) silently determined
whether an unrelated hard clause (H4) was tested. Coverage that depends on the
implementation's choices is coverage you do not have, and it is invisible from
the anchor, where the window happens to be wide.

**Why the guard was blamed twice.** Both guard diagnoses were *correct* — they
were real defects, worth fixing, and each had a clean causal story ending in
"and that is why it cannot fire". Neither was checked against the question *did
it fire?* before being acted on. One `$display` on the arming condition answered
in a single run what two rounds of reasoning had not.

**Rule:** when a defect survives, instrument the guard's *arming* before
rewriting it. "The guard cannot fire" and "the guard fires and nothing happens"
are different failures with different fixes, they are indistinguishable from the
verdict alone, and the first explanation is cheap to construct for either.

**Corollary for stimulus design.** Where a clause is about behaviour *during* a
window whose length is latitude, the stimulus must enter the window at the
earliest legal instant, not at a convenient one. Convenience here cost exactly
one cycle and it was the only cycle that mattered.

---

## Candidate — a stale label acquires a mechanism, and the mechanism crosses an agent boundary as fact

**A second instance of "a mechanism constructed to explain a measurement is a
reason to re-measure", and a more useful one than the first, because this time
the construction and the consumption were done by different agents.**

**The instance.** A stimulus-variation sweep reported v_ca06 with frozen inputs,
and the report explained: *"read half of the contract cannot complete.
`s_arvalid` asserted at three sites, `m_rvalid` never driven, appears only in
mutant port lists. Reads launch and no response ever returns."* It closed by
tying this to the task's catalog row — *"row already says not yet scoreable —
this is the mechanism behind that label."*

Every load-bearing part of that is wrong, and **the same tool on the shipped
reference says so**:

- `m_rvalid` is in the VARIED list, with `m_rdata`, `m_rid`, `m_rlast`, `m_rresp`.
- It is driven by a registered downstream responder, `assign m_rvalid =
  m_rvalid_q`, off a request queue.
- The golden's own coverage line reports **70 reads and 191 R beats**, a peak of
  4 reads outstanding against a bound of 4, and downstream errors on both paths.
- The frozen count is **5 of 31, not 7** — the two extra were read-path signals.

**The catalog row was stale.** It read "not yet scoreable" because the correction
to BUILT + SCOREABLE was being deliberately held pending a separate decision, not
because anything was unscoreable. So the sequence was: a label goes stale, a
sweep produces an ambiguous signal, a mechanism gets constructed that explains
both — and the mechanism is then *reported as the finding*, with the stale label
cited as corroboration.

**Why the boundary matters.** When I did this to myself on v_ca07's duty rule, the
argument and the measurement were in one head and one file, and re-measuring was
one command away. Here the mechanism arrived as a **report from elsewhere**,
already reconciled with a second artefact, in a format that invites action rather
than re-measurement. Nothing in it is dishonest. It is simply much more expensive
to disbelieve, because disbelieving it means re-running someone else's work.

**Rule.** A peer report that arrives already explaining a second artefact has not
been corroborated by that artefact — it has been *fitted* to it. Check the
artefact's freshness before the report's plausibility. A stale label is a magnet
for a mechanism, and the mechanism will be a good one.

**Corollary, for the tool rather than the reporter.** This tool documents that an
absent signal yields "cannot conclude" rather than "frozen", and that its output
is a candidate list. Both caveats were honoured in the tool and lost in the
report. **A caveat that lives only in the tool's docstring does not survive
transport**; if the distinction matters it has to be in the output line, next to
the number, where a reader who never opens the source will still meet it.
