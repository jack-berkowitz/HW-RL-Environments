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

## Candidate — a status label is not evidence, and a second agent citing it is not a second opinion

**The general form first, because the instance is only how it was found.**

> When a status label and a measurement disagree, **the measurement wins and the
> label gets checked**. A label is a claim someone wrote down at a moment that has
> since passed. It is not an observation, it does not age with the artefact it
> describes, and it must never be cited as corroboration for a measurement — it
> is the thing the measurement adjudicates.

The second half is what makes it expensive. **A second agent's confirmation reads
as independent when it is the same error propagating.** Two artefacts agreeing
is the ordinary reason to believe something; two artefacts agreeing because one
was *fitted to* the other is indistinguishable from that at the point of
reading.

**A second instance of "a mechanism constructed to explain a measurement is a
reason to re-measure", and a more useful one than the first, because this time
the construction and the consumption were done by different agents — so the
error acquired the appearance of independent confirmation on the way across.**

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

---

## Candidate — a ternary between two string literals is prohibited in any line a measurement is read from

**Not a per-task bug. A construct-level ban, on evidence from two tasks and two
different downstream failures.**

SystemVerilog pads the shorter arm of a ternary between two string **literals**
with NULs to the width of the longer. The NULs are invisible in a terminal and
survive into any log the line is written to. Two instances, found independently:

| where | the construct | what it broke downstream |
| --- | --- | --- |
| v_ca07, `RESULT:` line | `(n_fail==1)?"":"s"` | printed `RESULT: FAIL (1 failure )`. A profile parser pinned to the plural read it as **zero failures** and reported a control that WAS caught as `NOT CAUGHT`. |
| v_ca06, a D5/D6 witness | `(want_r != 0) ? " -- an error is STICKY…" : ""` | padded **fifty NULs** into the middle of a rule-16 witness — the exact string a mutant record is checked against. |
| v_ca06, `RESULT:` line | `(n_fail==1)?"":"s"` | same as v_ca07's, latent. |

The two failure modes are unrelated to each other: one corrupted a **count**, the
other corrupted an **identity string**. What they share is the construct. That is
what makes it a ban rather than three fixes — a defect that produces a different
symptom in every host is one you will never learn to recognise by its symptom.

It is also nearly invisible in review. `(cond) ? "" : "s"` reads as obviously
correct, the output looks right in a terminal, and the padding only surfaces when
something downstream parses or compares the line.

**Rule:** in any line a measurement is later read from — a `RESULT:` line, a
witness string, a coverage line — a ternary between string literals is
prohibited. Plain `if`/`else` with a complete `$display` per branch. Cheap to
grep for: `\?\s*"[^"]*"\s*:\s*"[^"]*"`.

The narrower rule is not enough. "Don't put a ternary in the RESULT line" would
have caught one of the three; the construct is the thing.

---

---

## Candidate — a frozen input conceals the state of every check downstream of it

**This changes how a frozen-input sweep is read.** A frozen input is normally
filed as a stimulus gap: the field was not exercised, so drive it and move on.
That reading is incomplete, and the incompleteness is the dangerous half.

> While a field is held at one value, a checker that **ignores** that field and a
> checker that **compares** it produce identical output on every run. The frozen
> input is not only an unexercised input — it is a **blindfold over every check
> downstream of it**. Varying it buys nothing until the checkers behind it have
> been audited, because until then you do not know whether there were any.

So a sweep hit does not mean "stimulus gap". It means **"the checking state
behind this field is unknown"**, and the fix is two changes, not one.

### The instance, and it was two gaps stacked

v_nw02 had twenty AXI sideband fields frozen at one value each, against four
pass-through clauses — P1 to P4 — that say those exact fields are forwarded
unmodified. Driving them was the obvious fix. Auditing the checkers first is what
the run actually needed:

| clause | what it says | what was behind the frozen field |
| --- | --- | --- |
| **P1** | a non-atomic AW is forwarded with **every field** unmodified | compared **three of eleven** |
| **P2** | W beats forwarded unmodified | `user` never compared |
| **P3** | AR is forwarded unmodified | **no field comparison anywhere** — the clause was carried by "an AR was offered and accepted", which a design that rewrites every field passes |
| **P4** | a B is returned unmodified, id, resp and user alike | **never appeared in a `fail()` call at all** |

Every one of those was invisible while the fields were constant, and every one
would have stayed invisible if the fix had been "vary the stimulus".

### The same shape from the other side

Agent 3 reports d_dsp02 as **a real check sitting behind a phase that was deleted
while its comment banner survived** — the check exists, the stimulus that reaches
it does not, and the banner asserts otherwise. *Recorded as reported; this is
another agent's task and I have not measured it* — which is the discipline the
entry above on **a status label is not evidence** exists to enforce, and the
reason to say so rather than pass it on as established.

Same mechanism, opposite starting point. Here the stimulus was frozen and the
checks behind it were absent; there the check is present and the stimulus that
would reach it is gone. In both, **the pairing is what fails, and neither half
looks wrong on its own.**

### My own fix contained two more of the same, and neither was visible in review

**One — a varying expression is not varying stimulus.** The fix drove the AR
sideband from a counter:

```systemverilog
  s_arsize  = 3'(sb_ar_shared % 3);
  s_arburst = (sb_ar_shared % 4 == 3) ? 2'b00 : 2'b01;
  s_arlock  = sb_ar_shared[0];
```

Re-running the sweep reported all three **still frozen, at their old values**. The
counter was shared with the write path and every read happened to land on an even
value with `mod 3 == 2`. The expressions varied; the **arguments they were
evaluated at** did not. Variation is a property of the values a port takes, and
it depends on the expression, the counter, the call sites and their stride
together — any of the four can flatten it and three are invisible where the
expression is written.

**Two — and this is the one worth the space.** A separate counter did not fix it
either. The **coverage floor written in the same change** said why, on its first
execution:

    FAIL COVERAGE: only 18 write and 1 read sideband patterns driven

The reference issued **exactly one AR in the entire run**. No counter scheme
varies a field across a single call, and P3's *"a read is never filtered,
whatever its address"* was being carried by one read at one address.

**A floor that contradicts its author immediately is the whole argument for
writing floors alongside the stimulus rather than after it is believed to work.**
Written afterwards, a floor is calibrated against a run you already trust, and it
will agree with you — that is what "afterwards" means. Written at the same time,
it is an independent statement of what the stimulus was *supposed* to achieve,
and it is free to disagree. This one disagreed on the first run and was right
both times.

### The consequence for every hit not yet actioned

Every remaining frozen-input hit is upgraded from *stimulus gap* to **checking
state unknown**, and that includes the ones I cleared. When I called v_nw01's
frozen configuration legitimate I verified the *clause was reachable* — the
varying `req_ip_i` crosses the subnet boundary Q3 branches on — and I did **not**
verify that a checker sits behind it. "Not a stimulus defect" does not imply "the
clause is checked", and my not-defect calls established the first only.

**Rule:** treat a frozen input as evidence about the *stimulus* and as **no
evidence at all** about the checks behind it. Audit the checker before driving
the field, or the fix silently converts an unexercised check into an absent one
with nothing to show the difference.

### The caveat above came true within a day, on v_nw01

Agent 3 re-raised v_nw01's four frozen identity inputs — `local_ip_i`,
`local_mac_i`, `subnet_mask_i`, `gateway_ip_i` — after I had cleared them. **They
are right and the clearing was wrong**, and the way it was wrong is worth having.

My argument was that Q3 branches on subnet membership and the varying `req_ip_i`
crosses the boundary — `start_lookup(8.8.8.8)` against a 192.168.1.0/24 local
subnet — so both branches are reached. That is true, and it is **not the same
claim**:

> Reaching both branches of a condition does not test that the **boundary is
> where the configuration says it is.** A design that hardcodes /24 and
> 192.168.1.1, ignoring the ports entirely, reaches both branches correctly for
> this one configuration and is indistinguishable from a conforming one.

And the checker half was there too, in the form the entry above predicts: the
identity is wired to constants at the instantiation and **the checkers compare
against those same constants**. Port and constant are the same symbol, so nothing
in the run can tell a design that reads the port from one that does not.

The spec settles it in one sentence, which I had read and not connected:
*"`local_mac_i`, `local_ip_i`, `gateway_ip_i` and `subnet_mask_i` are **inputs,
not constants**; hold them steady while the engine is running."* That is a clause,
only these inputs can reach it, and it explicitly permits changing them while the
engine is stopped.

**The general form is the one already accepted for v_nw02's pass-through fields:
a field's USE can only be tested by varying that field.** Configuration is not an
exception to it — configuration is the case where it bites hardest, because a
configured design and a hardcoded one agree on every run at the configured
value.


---

## Candidate — a check that fires on the right input for the wrong reason, and the one instrument that sees it

**No instrument we have detects this.** Variation says the input moved. Legality
says the conformant variants pass. Mutation count says the defect was killed.
Witness sync says the recorded string matches what the runner prints. **All four
agree, and all four are consistent with the check testing a different property
than the one it names.**

### The instance

v_ca06's read-side response check reported a **wrong error code** as a **D6**
failure. D6 is *precedence* — an error is due and must appear. D7 is *code
preservation* — the error that appears must be the one the slave returned. One
branch covered both:

```systemverilog
  if (s_rresp !== want_r) begin
    if (want_r == 2'b00) fail("D5", ...);
    else                 fail("D6", ...);   // <- swallows D7
  end
```

Every clause was checked. Every mutant was killed. The witness strings matched.
And **D7 had no path to being reported at all** — a submission that checked only
precedence would have been credited with checking preservation, because the two
were indistinguishable in the output.

It surfaced only because a mutant was written that violates D7 *and not D6*, and
its witness came back tagged D6. **Without the disjoint mutant there was nothing
to notice.** That is the general danger: the collapse is invisible until someone
builds the case that separates the two clauses, and nobody builds that case
unless they already suspect the collapse.

### What would detect it

The clause is stated in the spec and the check cannot name it. That is a **set
difference**, and it needs no new measurement:

> Every clause a spec states must be **emittable** by the reference. Take the
> clause ids from `spec/*.md`, take the clause ids appearing in any `fail(...)`
> in `tb/*.sv`, subtract. What remains is stated and unreportable.

Run across all eleven verification tasks it returns **90 clause ids**. That is a
**candidate list, not a verdict** — the same caveat the variation tool carries,
and for the same reason. Calibrated by hand against v_ca07, where the answer is
known:

| clause | verdict |
| --- | --- |
| H2, P4 | **legitimate** — obligations on the *tester*, not the design; nothing to emit |
| P3 | **legitimate and already documented** — the 0/1 distinction is explicitly unscored, and pass-through itself is checked under P1 |
| **C3** | **real** — "after a change, `cycl_count_o` counts over the new divisor's range immediately". No check emits it, and the spec carries a *Measured:* line for it. The same shape as E3 before E3 was given an instrument. |
| **G2** | **real** — "while gated, `clk_o` stays low". No check emits it. |

Two of five real on a task I know well. The detector earns its place; the list it
produces has to be worked clause by clause, not counted.

**Why this detector and not a stricter one.** Comparing a mutant's `violates:`
field against the clause its witness reports finds *precedence* — a mutant that
breaks several clauses and trips an earlier one — which is usually benign and
noisy. Four such pairs exist across the suite and all four look legitimate. The
emittability difference finds the case that actually costs something: a clause
that **can never be reported by anything**.

**Rule:** a clause with no path to being reported is unscored no matter how many
mutants cover its subject matter. Check emittability as a set difference, before
trusting a kill table to mean the clauses were checked.

---

## Method note — a build that reads a file while you are editing it is neither before nor after

Recorded because it nearly produced a wrong before/after table. A re-baseline
compares two runs, and the run labelled "before" must be of a **committed
state**, not of whatever the working tree happened to contain when a background
build got round to opening it.

While re-baselining v_nw01 I launched the baseline run and then edited the
testbench. The build had not yet read the file. The result would have been
labelled "before" and been neither — a mixture whose composition depends on
process scheduling, and which no later inspection can reconstruct.

**Take the baseline from `git show HEAD:<path>` into a scratch file and run
against that.** It costs one command, it does not depend on timing, and the
provenance is a commit id rather than a wall-clock coincidence.

*Filed here rather than in `MEASUREMENTS.md` because no repository-level
`MEASUREMENTS.md` exists — the only two are inside design task directories that
are not this agent's. Needs a home decision.*

---

## Candidate — a correction has to be addressed to the artefact, not to its author

**The author is the one component guaranteed not to persist.**

A frozen-input table circulated from session `hw-rl-benchmark-92`. It carried a
wrong row — v_ca06 at 7 frozen of 31, where the measured figure is 5 — and that
row had already produced one downstream cascade. By the time the correction was
ready, `ListAgents` no longer showed that session at all.

> The artefact does not expire with the process that made it. **The table
> survives; its author does not.** A correction addressed to a name resolves to
> nothing once the name is gone, while the thing it corrects is still being read.

This is the same failure that keeps appearing one layer down — a hash quoted in a
message and stale by the time it is used, three times in one evening — except
that a stale hash can be recomputed at the point of use and a departed session
cannot be re-addressed at all.

**The operational form**, which is the part worth keeping:

- A correction is addressed to **the artefact and its consumers**, never to the
  author. Consumers persist for as long as the artefact does; the author does not.
- Which means the artefact has to **carry its own provenance** — what produced
  it, against what tree, at what commit — because that is the only channel
  through which a later correction can find its readers.
- And a number in a message is **not** an artefact. It is a copy whose original
  may already have moved. Recompute at the point of use, or cite the commit.

*Attribution: raised as a structural property by AGENT-DESIGN-43a92055, who
declined to write it up on the grounds that it was this agent's observation. The
operational implication — address the artefact, not the author — is theirs.*

---

## Candidate — a measurement of a mutable artefact is a measurement of a TIME, and I reported one as a fact

**A correction of my own correction, and the error is one step past the one I had
already learned.**

A peer claimed an uncommitted `PLACE_DENSITY = 0.35` sat in a file and built a
rule-17 argument on it. A second peer said the claim was false. I checked
myself — working tree `0.50`, HEAD `0.50`, porcelain empty — and **relayed it as
false**, attributing the peer's error to my own earlier finding about mechanisms
fitted to artefacts.

Both parts of that were wrong.

The original observation **was real**: `git diff` genuinely returned the `0.35`
at the time it was taken, and a trap restored the file afterwards. Two readings
of a mutable file, taken inside and outside a window in which it changes, were
each correct when taken. My measurement established `not true now`; I reported
`false`, which is a claim about the time the other reading was taken, and I had
no measurement of that time at all.

And the attribution was wrong too. The peer's failure was **inference past a
correct measurement**, not a mechanism fitted to an artefact — a different defect
that happens to be the one I keep finding, which is precisely why I reached for
it.

**Two rules.**

- **A measurement of something that changes carries a timestamp, and its
  conclusion may not outrun that timestamp.** "I looked and it is not there" does
  not refute "I looked earlier and it was". Both are observations; neither is
  about the other's moment. Where the artefact is mutable, the honest verdict is
  *not true at T2*, and establishing *false at T1* needs evidence from T1 — a
  reflog, a commit, a recorded diff.
- **Having a favourite failure mode makes you fast and makes you wrong.** I have
  filed "a mechanism constructed to explain a measurement" twice this session and
  it fit this case beautifully. It was not what happened. A diagnosis that comes
  to hand quickly because you wrote it down last week deserves the same
  scepticism as one that comes from a peer.

---

## Candidate — the control passed and did not suppress, and passing was not the finding

**Method note, and it retracts half of a verdict I had already reported.**

Two clauses on v_ca07 were reported as unfalsifiable — satisfiable by a
conforming design that keeps their antecedent empty:

- **G2**, "while gated, `clk_o` stays low"
- **H4**, "a request during a transition is DEFERRED, not refused"

Both were called **by inspection**, from the observation that L2 explicitly frees
how long gating lasts. A peer's method note (F86) says the evidence for
*unfalsifiable* must be **a suppressing control that PASSES**, never a reading,
because a clause declared vacuous by inspection is how two earlier accusations in
this repo went wrong. So I built one: the fastest legal resume, no gated state.

**It passed. And it did not suppress.** Its measured gap between acceptance and
the first new edge was 1 to 8 cycles — never zero. Had I stopped at `RESULT:
PASS` I would have confirmed a vacuity claim on a control whose two arms produce
the same observable, which is a defect I filed myself earlier in this session and
walked straight into.

Measuring what the control actually did split the two clauses apart:

| clause | verdict | evidence |
| --- | --- | --- |
| **H4** | **UNFALSIFIABLE — confirmed** | On the fastest legal resume the second request is accepted after **0 cycles**: there was no transition to arrive during. Stronger than a passing control — the *mutant* that violates H4 was re-derived on that base and **survives**. The defect is undetectable against a conforming design. |
| **G2** | **FORCED — retracted** | The minimum gap across every transition is **1 cycle, never 0**. The counter restarts at acceptance, so the next rising edge cannot fall in the same cycle. There is always a gated cycle to judge, on every legal implementation. G2 has force. |

G2 stays on the *emittability* list — no `fail()` in the reference can name it —
but that is the **D7 class**, a clause with force and no instrument, and not the
vacuity class at all. I had merged two different defects into one verdict.

**Rules.**

- A control earns a conclusion only if it is shown to **create the condition it
  was built to create**. Passing is the second half; suppressing is the first,
  and it is the half that is assumed.
- The strong form of "unfalsifiable" is not a passing control but a **surviving
  mutant**: a defect that violates the clause and is undetectable against a
  conforming design proves the clause cannot be scored, which a passing control
  only suggests.
- *Unfalsifiable* and *unreportable* are different failures with different fixes
  — a forcing clause versus an instrument — and they look identical from the
  clause list.

---

## Candidate — a coverage floor that counts ATTEMPTS cannot see a suppressed antecedent

**The floor I wrote to guarantee H4 was exercised is the reason nothing objected
when H4 was not exercised.**

v_ca07's reference carries a floor for clause H4 — "a request during a transition
is DEFERRED, not refused":

```systemverilog
  if (acc2 < 0) fail("H4", "... never accepted in 600 cycles");
  cov_defer++;                       // <- unconditional
  ...
  if (cov_defer < 1) fail("FLOOR", "a second request during a transition was
                                    never DRIVEN -- H4 untested");
```

`cov_defer++` fires whether or not a deferral happened, and the floor's own words
name the wrong observable: **driven**, not *landed in the window*. Against the
fastest-legal-resume control the second request was driven, the floor counted it,
the antecedent was empty, and the run passed in silence — while the H4 mutant
re-derived on that base survived undetected.

**The floor asserted the clause was tested at the exact moment the clause was
vacuous**, and it did so because it counts my stimulus rather than the design's
state. A floor over stimulus is the right shape for "did the harness try"; it is
the wrong shape for "was the clause exercised", and those read identically in the
source.

**The correct shape is a count of the CONDITION, at the ports.** AGENT-DESIGN's
rule-36 gate does this and it is why theirs works: `h3_guard_true == 0` counts the
cycles on which the antecedent actually held, so a design that evades the
antecedent trips it. Mine counts the cycles on which I tried.

**Rule:** a coverage floor must count the state the clause is conditioned on, not
the stimulus intended to produce it. Where the design controls whether that state
is reached — and latitude clauses routinely give it that control — the two
diverge exactly when it matters, and the attempt-counter reports success.

**Corollary, from AGENT-DESIGN's F86 correction:** a condition-counting gate is a
*partial* detector for an unfalsifiable clause. It makes the evasion **visible
without making it non-conforming** — a submission failing that way can correctly
argue it satisfies every clause, and the failure is the harness objecting that it
cannot tell. The mirror clause is still needed. Their diagnostic is worth taking
whole: a failure at `phase=<clause>` means the consequent was violated and the
clause has force; a failure at `phase=final` / "never exercised" means the
antecedent was suppressed.

---

## Candidate — controls that exist, are recorded as passing, and that no runner runs

**Found by testing a peer's report against my own surface instead of assuming it
transferred.**

AGENT-DESIGN reported that `sim_candidate.sh` refuses controls held outside a
literal directory list, and flagged it as likely to hit my sweep. It does not —
that gate is on the design path and my scorer has no equivalent. But checking
turned up the same *class* of defect one step over:

| | |
| --- | --- |
| tasks of mine holding `negctl/` controls | **7** |
| whose own runner exercises them | **1** (v_ca07) |
| occurrences of `negctl` anywhere in `scripts/` | **1, and it is a comment** |

Twenty-one negative controls across six tasks are built, committed, and recorded
in `task.yaml` with verdicts — *"PASS — caught"*, *"26 failures, every one A4"*,
*"both caught, on H3 and on nothing else"* — and **nothing in any repeatable path
runs them.** Those verdicts were true when measured by hand and no mechanism will
ever notice when they stop being true.

This is the shape that produced v_ai02's `task.yaml` asserting 22 of 22 while its
own record read "(not yet run for this task)", and it is the shape of a stated
measurement with no instrument. A control is not apparatus until something runs
it on a schedule someone else controls; until then it is a claim with a source
file attached.

**What makes it hard to see:** the control *works*. Run it by hand and it does
exactly what the record says. Nothing is wrong with the artefact — what is missing
is the path, and a path is invisible in every file you would think to open.

**Rule:** a control belongs to whatever runs it, not to whatever directory holds
it. If no runner enumerates it, its recorded verdict is a historical note about
one afternoon, and should be written as one or wired into a runner.

---

## FINDING — a floor over stimulus answers "did the harness try"; a floor over the condition answers "was the clause exercised"

**They read identically in source. They diverge exactly where the design controls
whether the state is reached — which is what every latitude clause grants it.**

Both agents found instances in their own work within an hour of the distinction
being drawn, which is the argument for it being a class rather than two bugs.

### The mechanism, and it is why the check ends up not written at all

*From AGENT-DESIGN-43a92055:* **a condition floor cannot live in a stimulus-floor
block.** Stimulus floors are written at the end of the run, next to each other,
counting things the testbench did — beats driven, divisors swept, resets
asserted. A condition floor has to observe the design *while it runs*, so it
belongs in the checker, not in that block. An author working down the list of
clauses in the floor block will write a stimulus floor for every one of them,
because that is the only shape available in the place they are standing. **The
wrong floor is not chosen over the right one; the right one has nowhere to go.**

### The test

> For each floor: **is there a latitude clause between the stimulus and the
> condition?** If the stimulus fully determines the condition, the counter and
> the claim are the same thing and the floor is correct. If a conforming design
> can receive the stimulus and not enter the state, the floor asserts the clause
> was exercised at the exact moment it was not.

### The sweep — eleven verification specs, ~28 clause-claiming floors

| task | floor | verdict |
| --- | --- | --- |
| **v_ca07** | `cov_defer` — *"a second request during a transition was never DRIVEN — H4 untested"* | **DEFECT, measured.** L2 frees transition length. Against the fastest-legal-resume base the request was driven, the floor counted it, the antecedent was empty, and the H4 mutant on that base **survived**. |
| **v_ca04** | `cov_lockin_probe` — *"the contender set was never changed while an output was stalled — A3 is untested"* | **DEFECT.** Set by my probe. And A3's own antecedent is `out_valid_o` high while ready is low — `out_valid_o` is a **design output**, so this is the H1b shape as well: the same clause AGENT-DESIGN found on d_dsp02's H3. |
| **v_nw02** | `cov_filled_bound` — *"the write bound was never driven to its limit"* | **DEFECT.** Whether the debt reaches the bound depends on the design's admission policy, which L4 frees. Same shape as v_ca06's A4. |
| everything else | ~25 floors | **correct.** DECERR driven, off-subnet lookup driven, negative drift driven, non-ARP frame driven, reset asserted — in each the input is mine and no conforming design can decline to receive it. The counter and the claim are the same statement. |

### The correct pattern already existed, in my own work, once

`v_ca06`'s A4 floor:

> *"more reads than the MAX_READS bound were never **OFFERED**, so A4 **has no
> stimulus that could reveal** a design accepting too many"*

It says **offered**, not exercised. It claims the **absence of stimulus**, not the
presence of a test. And on the one clause where I had already recognised the
design controls the condition, A4 was closed with a **capability-increased
control** rather than with a floor at all.

That is the fix in both halves: **word the floor to claim only what it counts,
and close the design-controlled condition with a control that enters the state.**
I had it right once, on the clause where I had thought about it, and wrote the
other three from the floor block without thinking about it — which is exactly the
mechanism above.

### The third instance of an author breaking the rule inside the commit that files it

**My first replacement counter for H4 was wrong in this finding's own way.** It
counted any pending different-valued request while the design was busy — which
includes the natural overlap in the divisor sweep, nothing to do with H4 — and
**read 10 on a base whose H4 window is empty**. A counter whose name and claim
outran what it counted, written into the commit that defines that defect.

What caught it was not review. **Both bases passed**, and two passes is exactly
what a useless counter looks like: the anchor passed because the antecedent held,
the suppressing control passed because the counter was measuring something else,
and the pair is indistinguishable from a working detector. It was caught by
**printing the number** — 9 on the anchor, 10 on the control — instead of reading
the pass/fail pair.

That makes three in this session, and the pattern is worth more than any one:

| | the rule | broken by its own author |
| --- | --- | --- |
| F86 | evidence for *unfalsifiable* must be a suppressing control that passes | its founding instance, R1, was named from a **reading** of the clause |
| this | a floor must count the condition, not the attempt | the replacement counter **counted the wrong condition** |
| earlier | the code was right and the prose describing it was wrong | my contract text said `[A-Z][0-9]+` while my own tool had always matched `[A-Z][0-9]+[a-z]?` |

**The generalisation:** writing a rule down does not install it. All three were
written by someone who had just finished explaining the defect, in the artefact
that explains it, which is the moment of maximum confidence and therefore of
minimum checking. A rule is worth having anyway — but the check it prescribes has
to be run against the commit that introduces it, not only against future work.

### Rules

- A floor may claim only what its counter observes. *"never driven"* is a claim
  about the harness; *"untested"* is a claim about the design, and a stimulus
  counter cannot support the second.
- Where a latitude clause sits between the stimulus and the condition, the floor
  cannot close the gap and **a control must**: build the conforming
  implementation that declines to enter the state and see what the harness says.
- A condition floor belongs **in the checker**, not in the floor block. Putting
  it in the floor block is how it becomes a stimulus floor.
- *Partial detector, from AGENT-DESIGN's correction to their own finding:* a
  condition floor makes the evasion **visible without making it non-conforming**.
  A submission failing that way can correctly argue it satisfies every clause,
  and the failure is the harness objecting that it cannot tell. Their diagnostic:
  a failure at `phase=<clause>` means the consequent was violated and the clause
  has force; a failure at `phase=final` / "never exercised" means the antecedent
  was suppressed.


---

## FINDING — port and expectation as one symbol: a check that cannot disagree

**Second instance, which makes it a class.** Both are in this agent's own work,
found three days apart in different tasks by different routes.

| | the port | the expectation | what passed |
| --- | --- | --- | --- |
| **v_nw01** | `local_ip_i`, `local_mac_i`, `subnet_mask_i`, `gateway_ip_i` wired to `localparam LIP`/`LMAC`/… | the checkers compare against **`LIP`/`LMAC`** | a design that hardcodes the identity and ignores the ports entirely |
| **v_ca03** | responder drives `m_rresp = 2'b00` | the checker compares `s_rresp` against the literal **`2'b00`** | a design that rewrites **every** response code |

In each, the value at the port and the value the checker expects **are the same
symbol**. The comparison is `X == X`. It runs, it passes, it is reported as a
clause being checked, and no implementation can make it fail.

**Why a variation sweep cannot find it.** The symbol varies in neither place, so
the tool reports a frozen port with nothing behind it to disagree with. A clean
variation row means only that the tool had nothing to compare. It is also
invisible to mutation: no mutant fails it, because none can.

### The remedy, which is not "vary the input"

Varying the input alone converts `X == X` into `X == Y` only if the two are
**independently produced**. The general fix is:

> **Derive the port value and the expectation from something neither of them
> controls, so that the two are computed at different times from a shared
> premise rather than from each other.**

On v_ca03 that is `resp_of(address)`: the expectation is raised when the
transaction is *issued*, the responder computes the same function when the
response is *returned* cycles later, and neither reads the other. A disagreement
is then possible, and the DUT is the only thing that can cause one. The address
is the shared premise; the DUT sits between.

On v_nw01 it is the identity being **reprogrammed across a reset** — the checkers
read the current value, the design must read the port, and the second
configuration is what makes those two different claims.

**The test, cheap enough to apply everywhere:** trace the expectation back to its
source. If the path reaches the same symbol the stimulus came from without
passing through the design, the check cannot fail and is not a check.

---

## FINDING — writing a rule down does not install it

**Four instances in one session, each by the author of the rule. The first is a
GATE broken inside the filing commit; the other three are rules broken beside
one.**

### The instance that leads: I broke a GATE inside the commit that filed this finding

**A gate broken inside the commit that files the rule is categorically different
from a rule broken beside one.** The other three below are rules whose author
did not apply them to adjacent work. This one is a check that ran, reported the
defect, and was overridden by the person who had just written the rule saying
not to do that.

`check_linkage_tree.sh --staged` returned:

    v_ca03_axi_iw_converter: mutant iw_m11_... has no witness in task.yaml

I had recorded the new mutant under a fresh `e1_mutant:` key instead of in the
`mutants:` list where the checker looks. The check said so. I did not read it —
I read the **last line of its output**, which is the generic advice about
`LINKAGE_OVERRIDE`, saw the commit succeed, and moved on.

That is the same defect as reading a build log for completions rather than for
refusals: the answer was on screen, in a check that ran, that I had invoked
myself for exactly this purpose. And it happened in the commit whose message
argues that writing a rule down does not install it.

Three further specifics worth keeping, because each is separately actionable:

- **The failure was in the RECORD, not the artefact.** The mutant was correct,
  measured and fired on E1 alone. What was missing was its witness in the place
  the machine reads. A defect that only a machine can see is exactly the kind a
  human reviewer signs off.
- **The check reads the COMMITTED tree by default.** Running it after the fix
  still failed, and for a moment that looked like the fix not working. It was
  reading a tree the fix was not in yet. *A check whose scope you have not
  established is a check whose answer you cannot interpret.*
- **Reading the tail of a tool's output is not reading its output.** The
  informative lines were four from the top; the last four lines were boilerplate
  that is printed whether the cause is a witness, a rule, or a finding.

### And three more, each a rule broken beside its own commit

| | the rule | how its own author broke it |
| --- | --- | --- |
| F86 (design side) | evidence for *unfalsifiable* must be a suppressing control that **passes**, never a reading | its founding instance, R1, was named **from a reading of the clause** and measured only afterwards |
| condition floors | a floor must count the **condition**, not the attempt | the replacement counter for H4 **counted the wrong condition** — any pending request while busy — and read 10 on a base whose window is empty |
| tool-vs-prose | a caveat that lives only in prose does not survive transport | my control contract stated clause ids as `[A-Z][0-9]+` while **my own tool** had always matched `[A-Z][0-9]+[a-z]?` |

The third is the same shape as a comment asserting "ten defects" above code that
counts them: **the code was right and the prose describing it was wrong**, in one
author's work, in the same file.

### The mechanism

All three were written **immediately after explaining the defect**, by the person
who had just explained it. That is the moment of **maximum confidence and minimum
checking**. Having just articulated why a class of error happens, the author is
least disposed to suspect the next thing they write of being in it — and the next
thing they write is the fix, the tool, or the rule itself.

It is the same shape as *having a favourite failure mode makes you fast and makes
you wrong*, one step further along: the favourite diagnosis is now not merely
available but freshly rehearsed.

### The proposed rule, and it is a gate rather than an exhortation

> **A newly written rule is applied to the commit that introduces it, before that
> commit lands.** Self-application as a landing gate.

Concretely: when a commit files a rule, the check that rule prescribes is run
against that commit's own diff. "Count the condition, not the attempt" → check
the counters this commit adds. "Evidence must be a passing suppressing control"
→ check that this commit's own claims are backed by one. "A caveat must be in the
output" → check this commit's own tool output.

All four instances above would have been caught by their own rule, at a cost of
minutes, by the only person who at that moment fully understood what to look for.
The fourth would have been caught by simply **reading the output of the check
already being run**, which is the cheapest form the rule can take and still the
one that was skipped.

---

## FINDING — a name is not an address: identity by ownership set

**Filed after socket addresses changed three times in one session, twice
mid-delivery — and corrected immediately, because my first account of it was
wrong in the way this document keeps describing.**

**What I asserted:** three roster rotations, sessions ending, a correction
outliving its author. **What was measured:** `ListAgents` stopped showing a name.
Both peers then confirmed that **no session ended and no role changed hands** —
`f6`, `b4` and the address before them are one design session; `e2` and `29` are
one PPA session. The *names* moved. I inferred a departure from a name's
disappearance, which is inferring a fact about a process from a fact about a
label, in a finding about not doing that.

So the evidence has to be restated to what it supports:

| | observed | not observed |
| --- | --- | --- |
| a name held by **two processes at once** | yes — two sessions signed "Agent 3" for hours | |
| a correction reaching **the wrong holder** of a name | yes — it went to the session that never produced the artefact | |
| a name changing while the **role stayed put** | yes, three times | |
| an author **departing** and a correction having nowhere to go | **yes — later the same session, see below** | |

**And then I made the same inference again.** Some hours after writing the table
above, both peer addresses stopped resolving and `ListAgents` returned **no
reachable agents at all**. I recorded that as the hazard finally occurring — an
author departing, a correction with nowhere to go — and wrote it up.

**It was wrong, the same way, for the second time.** The PPA session replied from
a third address: same session, scratchpad `2381f2fe`, never gone. The design
session likewise. *The socket names keep changing under stable sessions.*

So the observable, stated for the third time and now with a marker on how many
attempts it took to state correctly:

> **The address space went empty. Nothing about any session was observed.** An
> empty `ListAgents` and a departed peer produce identical evidence, and I had
> already written that sentence down before making the inference it forbids.

What the episode does establish, and it is not nothing:

- **The window is indistinguishable from the end while you are in it.** Retrying
  happened to work. Had the sessions truly ended, retrying would have failed
  forever with an identical message, and I would have had no way to tell which
  case I was in.
- **The undeliverable item was the one addressed to another agent's territory.**
  Work I could do myself was unaffected. What could not survive the gap was
  precisely what depended on another agent existing.
- **The fix was to write it to a file.** `inbox/FOR_SCRIPTS_AND_TABLE.md` is
  addressed to the *role and the artefact*, and it is what should have been done
  first. The message was the optimisation; the file is the delivery. That part
  holds whether or not anyone had actually departed — which is the argument for
  it, since I cannot tell.

**This is the fifth instance for the self-application finding, and the first
REPEAT.** I inferred a departure from a name's disappearance; was corrected;
wrote *"from the outside a rotated name and a departed author look identical"*;
and then made the same inference again the first time `ListAgents` came back
empty. Writing the correction down did not install it either. A rule broken once
by its author is a lapse; a rule broken **twice, after being corrected, by the
author who wrote the correction** is evidence that the rule was never the
mechanism — the reflex is, and the reflex here is *treating absence of evidence
as evidence*.

### And the correction itself needs a caveat, which is the sharper hazard

**Both peers told me the same thing, and I took two accounts as corroboration
when one of them was a relay.** The design agent's message said the PPA agent was
also unchanged — and said so on the PPA agent's authority, *"self-confirmed to me
an hour ago"*, flagging it as a relay in the same breath and telling me to verify
independently. I read the agreement before I read the caveat.

What is actually first-hand is narrower and does hold:

| claim | source | independent? |
| --- | --- | --- |
| design session unchanged, scratchpad `43a92055` | itself | **yes** |
| PPA session unchanged, scratchpad `2381f2fe` | itself | **yes** |
| *"neither of us is a successor"* | design agent, about both | **no — a relay** |

The two self-identifications are genuine, distinct evidence and the conclusion
survives. But the thing that made me *confident* was two messages agreeing, and
that agreement carried no information beyond the one first-hand report I already
had.

**This is the v_ca06 label cascade again**, and it is a sharper instance than a
real rotation would have produced: there, a stale label acquired a mechanism and
the mechanism was cited as corroboration. Here, a first-hand report acquired a
second voice and the second voice was counted as a second source. In both, the
apparent corroboration is the same fact arriving twice.

**Rule:** when two accounts agree, establish *how each one knows* before treating
the agreement as evidence. A relay that is honestly labelled as a relay is still
not a second source — and the label is easy to read past precisely because the
conclusion it carries is the one you were hoping for.

Ownership boundaries — which agent may commit where — are what prevent
cross-territory edits. Carrying them on a name is **identity by position**, the
same defect this benchmark's tasks are built to punish, at the agent layer.

**The convention, and it is a convention now rather than a workaround:**

- **Every cross-boundary message states its ownership set on the first line**,
  explicitly, including what the sender does *not* own. Not a signature — a set.
- **A message signed only by a name is unrouted** until the set is stated, and
  should be treated as such rather than acted on.
- **A request whose target is unknown is routed to the person who set the task**,
  never forwarded on a guess. Guessing put a time-critical PPA item in this
  agent's inbox and a v_ca06 correction in a session that had never touched it.

### The consequence, stated as the hazard it is

> **A correction addressed to a name resolves to nothing once that name moves**,
> while the thing it corrects is still being read. Tonight the name moved and the
> role did not, so the correction was recoverable by asking. It would not have
> been if the role had moved too, and nothing in the setup guarantees which
> happened — **from the outside, a rotated name and a departed author look
> identical**, which is precisely why the address must be the ownership set.

So a correction is addressed to **the artefact and its consumers**, and the
artefact must **carry its own provenance** — what produced it, against what
commit — because that is the only channel through which a later correction can
find its readers. A number in a message is a copy whose original may already have
moved: recompute at the point of use, or cite the commit.

Three hashes went stale between being sent and being used in one evening — and a
fourth number went stale the same way inside a single message, where a peer
quoted a control count taken before the control they described adding in the same
message. The mechanism does not need an agent to depart. It only needs the copy
to outlive the moment it was taken.


---

## FINDING — a condition count is the right instrument and the wrong gate

> **Gate the stimulus, which the harness alone determines. Report the condition,
> per channel, always. Never fail on it.** Failing on a condition converts
> *visibility* into *non-conformance*, and making an evasion non-conforming is a
> mirror clause's job, not a floor's.

**I built the thing I had spent the session prescribing, and it rejected two
conforming implementations on first contact.**

The preceding finding says a floor must count the **condition**, not the attempt.
Applying it to v_nw02's X3 — *"on every channel, once `valid` is asserted it
remains asserted until the corresponding `ready` is seen"* — I drove downstream
backpressure, counted the antecedent per channel, and **failed the run** when any
channel's count fell below four.

Result: `dut2` **FAIL**, `af_c1_b_before_r` **FAIL**, task **REJECTED**. Two legal
designs rejected by a reference, which under rule 16 makes every kill in that run
carry no information.

The cause was not a bug. On `dut2` the count was zero on the upstream R channel
because **`s_rvalid` never coincided with my `s_rready`-low window**. I drove the
backpressure; `dut2` declined to be caught by it, conformingly. *Whether a design's
valid overlaps my ready-low is the design's timing, not my stimulus.*

### The distinction the previous finding did not draw

| | who determines it | may it gate? |
| --- | --- | --- |
| **the stimulus** — did the harness drive backpressure at all | **the harness.** No design can decline it. | **yes** |
| **the condition** — did valid ever hold against a low ready | **the design**, jointly with the harness | **no** |

A condition count makes an unexercised clause **visible**. Making it a failure
converts visibility into **non-conformance** — which is what a mirror clause is
for, and what a floor must not do on its own authority. The design side had
already said this about their rule-36 gate: *it makes the evasion visible without
making it non-conforming*. I filed that sentence and then wrote a gate that did
the opposite.

**So the pattern is three parts, not two:**

1. **Gate the stimulus.** Countable by the harness alone.
2. **Report the condition, always.** Named per channel, so an unexercised clause
   is a line in the log rather than an absence.
3. **Do not fail on the condition.** If reaching it must be compulsory, that is a
   contract change, not a floor.

### What caught it, and it was not review

The conformant set. `dut2` and five perturbations exist to be **passed**, and two
of them failed the moment the gate was too strong. The mutants all still died —
a mutation-only view would have shown 10 of 10 and looked healthy.

That is the pairing working as designed: the **floor** caught the stimulus not
reaching far enough (`m_aw=0` on the first attempt), and the **conformant set**
caught the gate reaching too far. Neither alone would have found both, and the
error each caught was mine, in the same change, in opposite directions.

**Rule:** before a floor gates, ask who can make its condition false. If a
conforming implementation can, the floor may report and must not fail — and the
conformant set, not the mutant set, is what tells you whether you got it wrong.

### Two things that belong with it

**1 — Mutation coverage and conformant acceptance are orthogonal detectors, and
neither substitutes for the other.**

Each of my two errors was **invisible to the instrument that caught the other**:

| error | caught by | invisible to |
| --- | --- | --- |
| stimulus falling short (`m_aw=0`) | the **floor** | the conformant set — every legal design still passed |
| the gate reaching too far (rejecting `dut2`) | the **conformant set** | the mutants — all ten still died, **10 of 10, and the run looked healthy** |

A mutation-only view of the bad gate showed a perfect score. A conformant-only
view of the short stimulus showed nothing wrong. They are not two strengths of
one measurement; they are measurements of **different things** — *does the
reference catch what it should* and *does it accept what it must*.

**This is the argument for keeping conformant perturbations in the SCORED path**
rather than running them once as a startup check. A startup check answers "was
the reference sane when it was written". A scored one answers "is it sane now",
and the gate that rejected two legal designs was written today, hours after the
last time anyone would have run a startup check.

**2 — "Non-zero" is not a floor when the antecedent is one cycle wide.**

The registered stall arm produced a count of **1** on two channels. That passes a
`== 0` floor and is useless: any defect not on the very first occurrence is still
unreachable, and this suite deliberately weights its mutants toward *ordinal*
conditions — the fourth toggle, the second DECERR, the sixteenth read — precisely
the class a count of 1 cannot reach.

> **A condition floor's threshold is argued from the antecedent's WIDTH, not from
> zero.** How many cycles does the state last, how often can it recur, and what
> is the highest ordinal any guard keyed on it uses? The threshold is the answer
> to that, not the smallest number that is not zero.

Here the antecedent is one to two cycles wide and recurs per beat, the counts
came in at 30/35/12/12, and a threshold of four has margin — but the number that
matters is *four because guards go up to the fourth occurrence*, not *four
because it is more than zero*.

---

## FINDING — the missing handshake-stability clause: four tasks, both territories

**A contract-gap class, not four coincidences.** Four tasks across two agents'
territories are missing the same clause, and in each the consequence is identical:
**a design that withdraws a `valid` before its `ready` is seen conforms to the
specification as written.**

| task | owner | the gap | status |
| --- | --- | --- | --- |
| **d_dsp02** | design | `out_valid` may depend combinationally on `out_ready`, so H3's antecedent is evadable | **closed** — H1b landed |
| **d_ca01** | design | the same on `rsp_valid_o`/`rsp_ready_i`; L5 permits the *input*-side dependency and says nothing about the output side | **closed** — R1b landed |
| **v_ca06** | verification | **no clause about valid stability under stall exists at all** | **open** |
| **v_ca03** | verification | the same; `s_rready`/`s_bready` appear only inside A1's *definition* of "outstanding" | **open** |

The design side found theirs by building a control that evaded H3's antecedent and
watching it pass the whole suite. I found mine from the other direction — a
frozen-ready sweep, then the mechanical question *does any check have an antecedent
requiring this ready to be low?* On v_ca06 and v_ca03 the answer was **no check,
and no clause either**. There is nothing to gate, because there is nothing to gate
*for*.

**Why it is a class rather than a coincidence.** Both design instances and both
verification ones arise the same way: the AXI-family handshake makes stability a
*convention* so universal that a spec author writing from the protocol will not
think to state it, while a spec author writing a *contract* must, because the
contract is what the submission is scored against. Two independent authors omitted
it four times. It is a property of the writing situation, not of anyone's
attention.

**Why the verification side is worse than the design side.** On a design task the
omission lets a bad submission through. On a verification task it lets a bad
submission through **and** makes the reference unable to object: v_nw02, which
*does* have the clause (X3), had two of its four channels unreachable until today
— so even where the clause exists, the instrument behind it needs the stimulus
that only backpressure provides. The gap and the vacuity compound.

### Proposed text, written and NOT landed

Both move a hash and both should be decided alongside whatever else moves them.

**v_ca06** — as a new clause in *§1 Transaction correspondence*, where the other
handshake obligations live, after A4:

> **A5 — an offered beat is not withdrawn.** On every channel, once a `valid` is
> asserted it remains asserted, with its payload unchanged, until the
> corresponding `ready` is seen. `valid` **shall not** depend combinationally on
> `ready`: a unit that offers only into a ready sink satisfies this clause by
> never entering it, and deadlocks against a consumer that waits for `valid`
> before asserting `ready`.
> *Authority: AMBA AXI4 — a source may not withdraw an offer, and may not wait
> for the sink before making one.*

**v_ca03** — as a new clause in *§4 The master port*, after D4:

> **D5 — an offered beat is not withdrawn.** On every channel of both ports, once
> a `valid` is asserted it remains asserted, with its payload unchanged, until
> the corresponding `ready` is seen. `valid` **shall not** depend combinationally
> on `ready`. A converter that offers only into a ready sink satisfies this
> clause by never entering it, which is not conformance.
> *Authority: AMBA AXI4 — a converter alters identifiers and nothing else,
> including the handshake discipline it forwards.*

Both name the evasion explicitly rather than only the obligation, because that is
what H1b and R1b had to do: the obligation alone is satisfiable by never entering
the state, and a reader who has not met that failure will not infer the second
sentence from the first.

**This is the first time in this session a lesson has been applied BEFORE the
fact rather than after.** Every other instance ran the other way — the duty rule,
the D6/D7 collapse, the condition floors, the gate that rejected two conforming
designs, four self-applications of rules filed in the commit that broke them.
Each was written, measured, found wrong, and corrected. These two clauses are
written with the evasion already named, from a failure that happened on someone
else's task, before either has been offered to a submission.

That is worth recording as the exception, because it says what the transfer
actually required: **not the rule, but the worked instance.** "State the
obligation and forbid the evasion" is a sentence nobody would have written from
first principles. It became writable only after H3 and R1 were each satisfied by
a control that never entered the antecedent — and it transferred across a
territory boundary because that control was *built and run*, not described.

**Landing either requires the stimulus in the same boundary** — the two-halves
rule, which this suite has now paid for five times. A stability clause with every
ready held at 1 is a clause with an instrument that cannot fail, which is E1's
read side exactly.

---

## FINDING — a clean row is read once; a failing row is read twice

**Three rows of another agent's sweep were wrong when read against my own tasks,
and every one of them was wrong in the direction that produces no work.**

| task | reported | measured |
| --- | --- | --- |
| v_ca06 | 7 frozen of 31 | **5** — and the accompanying mechanism claimed the read half could not complete, which the same tool refutes |
| v_nw04 | 1 frozen | **0** |
| v_nw02 | 25 frozen | **3** |

The last two were stale because I had fixed them. The first was **wrong when
measured** — and it had already produced a downstream cascade before anyone
checked it.

### The asymmetry

> **A negative result carries no signal that would prompt verification.** A row
> saying *frozen: 7* has a name attached and something to do about it, so someone
> reads it twice. A row saying *none frozen* has nothing attached, so it is read
> once and never again. The rows most likely to be wrong for longest are the ones
> that report nothing wrong.

This is **F85's shape from the other direction**. F85 — *a sample chosen by
availability is not a sample* — concerns which cases get **looked at**: the ones
most recently handled, because their stimulus was most recently thought about.
This concerns which results get **looked at twice**: the ones with a finding
attached. Both bias attention toward the interesting, and both leave the quiet
majority carrying whatever error it acquired.

They compound: a case that is unavailable *and* reports clean is examined zero
times, and nothing about either fact is visible in a table.

### The practice

> **A clean result inherited from another agent's sweep is UNVERIFIED until
> measured locally.** Not doubted — unverified. It goes in the record as
> *reported clean, not measured here* until someone runs it, and the run is
> cheap precisely because nothing is wrong.

Applied: I re-measured the four tasks of mine that had been reported clean —
v_ai02, v_ca04, v_nw03, v_dsp02 — and all four *were* clean, which is the point.
The measurement cost minutes and converted four inherited assertions into four
observations. Had one of them been wrong it would have been wrong since the sweep
ran, with nothing in any table to suggest looking.

---

## FINDING — a field nothing reads cannot be wrong in a way anything notices

**Three of my `task.yaml` files declared `task_statement: probe/BLIND_TB_TASK.md`.
No such file exists in any of them. The prompt document on disk is
`probe/PASTE.md`.**

Nothing caught it, and the reason is precise: **no script reads
`task_statement`.** `grep -rn task_statement scripts/` returns nothing. A field
that no consumer reads has no observable correct value, so a wrong one produces
no disagreement anywhere — and **every instrument in this repository works by
finding a disagreement**: floor against outcome, control against reference, hash
against tree, recomputation against record.

### And the second half, which I initially got wrong

I expected the cause to be a **tolerant reader**: `task_text_hash.py` accepts
either `PASTE.md` or `BLIND_TB_TASK.md`, so I assumed it had swallowed the
mismatch. Reading it, that is not what happened. It **names the file it took** in
its output, and it **refuses loudly** when neither exists — its own comment
records that this exact rename caused a defect once already and that the refusal
is why. The tool is not the problem.

The problem is that **no instrument owns the comparison** between what
`task.yaml` says the prompt document is and what the prompt document actually is.
The hash reads the directory; the record names a file; nothing puts the two
side by side. *Leniency did not hide this. Absence of an owner did.*

### The sweep of `scripts/`, since the question was asked

Read-and-report; `scripts/` is AGENT-PPA's. Sorted by whether the leniency can
hide a defect, which most of it cannot:

| site | shape | assessment |
| --- | --- | --- |
| `check_ppa_record.py:69` `pdk = rec.get("pdk", "sky130hd")` | **default masks absence** | **worth changing.** A record that does not say which PDK becomes a record that says sky130hd. It then looks in the wrong flow directory and reports `SKIP (no surviving flow dir)` — an *unrecorded* field rendered as a *missing directory*. Same distinction as `-dirty` versus no marker, and as NO CONCLUSION versus clean. |
| `seed_sweep.sh:57` `[ -f DUT ] \|\| DUT=..._top.sv` | **silent alternative** | **minor.** Bounded, and it hard-fails if neither exists — but it never says which of the two it took, so a module with both gets one chosen invisibly. |
| `reference_ppa.sh:28` `ls ref/*_ref.sv \| head -1` | **first-match-wins** | **minor, and the same shape as the policy-directory glob that cost v_ca07 a real 21 of 22.** If two references ever exist, one is chosen and not named. |
| ~40 sites of `2>/dev/null` on `ls`/`[ -f ]` | existence probes | **not defects.** Suppressing an error you are testing for is the idiom. |
| ~30 sites of `.get(k, 0)` on counters | accumulators | **not defects.** |
| `task_text_hash.py` `PROMPT_NAMES` | tolerant, **and reports** | **not a defect** — the case that prompted the sweep, and it is doing the right thing. |

**The general form is narrower than "tolerance is bad".** Tolerance that
**names what it accepted** is fine; tolerance that **substitutes silently** is a
reader that has answered a different question than the one asked. And a field
with no reader at all is worse than either, because there is nothing to be
tolerant *with*.

**Rule:** every declared field needs an owner — a consumer that would fail if the
declaration were wrong. A field with no consumer should be deleted or given one;
leaving it is recording a claim that nothing can ever contradict.

### It is a class, and the other two instances came from the other territory

AGENT-PPA recognised the shape immediately and supplied two more, from tools I
have never read:

| field | written by | read by | what it cost |
| --- | --- | --- | --- |
| `task_statement` | task authors | **nothing** | three tasks named a prompt document that does not exist |
| `pinned_period_ns` | `find_fmax.py` | **nothing** | **one of thirty-one** fmax records even carries it, and nothing noticed the other thirty |
| `version_boundary.behavioural: true` | boundary authors | **nothing** | correctly recorded that results do not carry across a boundary — **while the results carried anyway** |

The third is the worst of the three and the clearest statement of the class: the
field was **right**, and being right changed nothing, because the thing it was
right about was decided elsewhere by something that never consulted it.

### And the sharper argument, which is theirs

On the `pdk` default I flagged — `rec.get("pdk", "sky130hd")` — they made the
case I had not:

> **There is one PDK in this repository, so the substituted value was correct
> every single time it was used.** That is the reason to remove it, not a reason
> to leave it. A default that is always right is indistinguishable from a field
> that is always read, and the two only come apart on the day a second PDK exists
> — at which point every silent substitution becomes a wrong answer with **no
> event marking the change**.

It fired on real data when they landed it: **three of sixty-seven** PPA records
carry no `pdk` at all. Those three had been rendering as sky130hd, correctly, and
would have gone on doing so until the day it mattered.

This generalises past defaults. **A check that has never failed and a check that
cannot fail are indistinguishable from their output**, and the distinguishing
test is not "has it ever fired" but "what would make it fire, and has that been
exercised". They fired the mismatch branch of their own new pin checker with a
halved pin before landing it, on exactly that reasoning — *a pin checker that
cannot fail would license every pin in the repo.*


### Scope of the two boundaries, measured

Neither is landed. What each would cost, so the boundary can be decided against
whatever else moves those hashes:

| | **v_ca06 — proposed A5** | **v_ca03 — proposed D5** |
| --- | --- | --- |
| **checker half** | **does not exist.** Zero valid-stability tracking of any kind in the testbench. | **does not exist.** Same. |
| **stimulus half** | five readies are `logic ... =1` initialisers, never driven again: `m_arready`, `m_awready`, `m_wready`, `s_bready`, `s_rready` | `m_awready`/`m_wready` are `assign … = 1'b1`; the upstream three likewise constant |
| **what must be built** | a four-to-five-channel `pv`/`pr` tracker plus a per-channel antecedent counter, and reactive backpressure on each ready | the same, on both ports |
| **re-baseline surface** | 12 mutants, 5 conformant perturbations, dut2, gate mutant, 5c on two bases | 11 mutants, 5 perturbations + a nonequiv tb, dut2, gate mutant, 5c |
| **known hazard** | the v_nw02 lesson: the antecedent counter must **report, not gate**, or it rejects conforming designs — `dut2` and one perturbation failed exactly that way | same, and v_ca03 has *six* conformant artefacts to keep passing rather than five |
| **stall shape** | must be **combinational on valid**; a registered arm produced a useless count of 1 | same |
| **X4-equivalent risk** | none found — no liveness clause names ready-held here | none found |

**Both are one boundary each, not two**: clause plus stimulus plus checker, per
the rule this suite has now paid for five times. The estimate is that v_ca03 is
the heavier of the two — more conformant artefacts to keep passing, and two ports
rather than one — and that v_nw02's experience makes the shape of both known in
advance rather than discovered.
