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
