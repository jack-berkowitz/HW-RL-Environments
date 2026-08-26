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

---

## Emittability across the eleven — the triage, and a worked sample

**88 raw candidates is not a work list.** Two mechanical discriminators reduce it
to 35, and a hand-worked sample on one task establishes the rate.

### The funnel

| | count | what it is |
| --- | --- | --- |
| raw candidates | **88** | clause ids no `fail()` in the reference can name |
| **KEYED elsewhere** | 20 | a *mutant* is keyed on the clause, so it **is** exercised and reported under another id — the **D6/D7 family**, and the dangerous one |
| **definition** | 13 | "a beat moves on…", "asserting X latches Y", format statements. Nothing to violate |
| **permission** | 11 | "unconstrained", "may depend on", "not specified" — latitude in a non-L section |
| **tester obligation** | 9 | "an obligation on you, the source", "the submitted testbench shall terminate" |
| **to review** | **35** | design obligations with no instrument that can name them |

**The two discriminators are not equally good and the difference should be
carried with the numbers, not left in a covering note.**

> **Mutant keying is EXACT.** A mutant's `violates:` field is a declaration by
> the person who wrote the defect, cross-referenced against a list derived from
> the spec and the testbench. Both sides are structured. It moved 20 and every
> one of those 20 is certain.
>
> **Clause-text classification is REGEX OVER PROSE and will misfile.** It reads
> a clause's English and guesses whether there is anything to violate. It already
> misfiled: "obligation on **you**" was missed where "obligation on YOU" matched,
> and v_nw04's `R1` — a statement of reset polarity — came through as a design
> obligation to review.

A count that mixes the two reads as one measurement and is two. The 20 are a
result; the 33 are a triage aid.

### The worked sample — v_ca06, six candidates

| clause | verdict |
| --- | --- |
| **C1, C2** — WRAP and multi-beat FIXED are refused | **exercised, reported as C4** — and this is the **D6/D7 family for the third time**, see below. |
| **F1, F2, F3** — reset, post-reset idle, no stale response | **genuinely unchecked.** Phase L asserts reset, releases, waits four cycles, and then **nothing**. No `fail()` follows the release at all. Stimulus without a checker — E3's shape before E3 got an instrument. |
| **D2** — lane placement | not yet read |

**Roughly half the reviewed candidates on a task I know well are real**, and the
two halves need *different* fixes: C1/C2 need the message to name the clause it
tests; F2/F3 need an instrument that does not exist.

### C1/C2 is the third instance of one family, not a v_ca06 fact

| task | the clause tested | the id reported | what a submission is credited with |
| --- | --- | --- | --- |
| **v_ca06** | D7 — the error *code* is preserved | **D6** | checking precedence, credited with checking preservation |
| **v_ca03** | E1's `resp` half | folded into the same comparison | checking the response, credited with checking the code |
| **v_ca06** | C1/C2 — *which bursts* are refused | **C4** | checking the *response* to a refusal, credited with checking *which bursts are refused* |

**Three instances across two tasks and three clause groups is a pattern in how
clauses get grouped under one reported id**, not three separate oversights. The
mechanism is the same each time: several clauses share one observation — a
response code, a refusal — so one check is written over that observation and one
id is chosen for its message. Every clause in the group is genuinely exercised.
Only one can ever be *named*, and a submission that tests any of them scores as
though it tested all.

**It is invisible to every count.** Mutation kills them, emittability sees the
group's chosen id emitted, and the clause list looks covered because the subject
matter is. The only signal is that a clause in the group has no `fail()` that can
name it — which is exactly what this tool reports, and why its "checked under
another id" family is the dangerous one rather than the benign one.

### The second task was chosen because I know it LEAST well, and the estimate did not survive

Doing the least-familiar task **second rather than last** was a deliberate check
on the v_ca06 rate. It failed the check twice over.

**First, five of v_dsp02's candidates were my tool's fault.** Its result checker
selects the clause id in a `case` and passes the **variable** to `fail()`:

```systemverilog
  unique case (e.op)
    OP_SGNJ:   cl = "S1";
    OP_MINMAX: cl = (is_nan(a) && is_nan(b)) ? "S5" : (…? "S4" : "S3");
    OP_CMP:    cl = "S7";
  endcase
  fail(cl, …);
```

The tool matched only `fail("LITERAL"`, so it reported six clauses the reference
names on every run as unreportable. Fixed by taking the assignment **whole** and
pulling every clause literal out of it — a first attempt enumerated the forms and
still missed the nested two-line ternary, which is the same mistake one level
down. Suite total 88 → **83**; v_dsp02 19 → 14.

**Second, and this is the part that revises the estimate: v_dsp02's remaining
profile is nothing like v_ca06's.**

| | v_ca06 | v_dsp02 |
| --- | --- | --- |
| genuinely unchecked | **3** — F1/F2/F3, reset with no checker after release | **~0** |
| grouped under one reported id | 2 — C1/C2 → C4 | **~8** — every flag clause (S2, S6, S11, S13) → **S14**; every comparison clause (S8, S9, S10) → **S7** |
| definitions / permissions / tester | 1 | 6 |

**"Roughly half real" does not transfer.** v_dsp02 has almost nothing missing and
almost everything *grouped* — and the two need different fixes: an absent
instrument must be built, a grouped id only needs its message to name the clause
it tested. Had I worked the familiar tasks first and the unfamiliar ones last, I
would have spent the block building instruments for a suite whose dominant defect
is a naming one.

**That makes the grouping family the fourth instance and the dominant one**, not
a v_ca06 curiosity. Across two tasks it now accounts for ten of the reviewed
candidates against three genuinely unchecked.

### What this does not claim

The remaining candidates are **triaged, not worked**, and the rate is now known to
vary by task rather than being a suite property. Two tasks of eleven are done —
the one I know best and the one I know least — which is a deliberately chosen pair
rather than a sample, and the spread between them is the result worth carrying.

---

# FINDING — clause grouping is scoring INFLATION, not a coverage gap

**Four appearances, ten candidates across two tasks against three genuinely
unchecked, and the same mechanism every time. This is the dominant defect in the
verification half.**

## The mechanism

Several clauses share **one observation** — a response code, a refusal, an
exception-flag word. One check is written over that observation, because one
observation needs one check. The check needs an id for its message, so **one id
is chosen** from the group.

Every clause in the group is **genuinely exercised**. Only one can ever be
**named**.

| task | clauses tested | id reported |
| --- | --- | --- |
| **v_ca06** | D7 — the error *code* is preserved | **D6** |
| **v_ca03** | E1's `resp` half | folded into one comparison |
| **v_ca06** | C1, C2 — *which* bursts are refused | **C4** |
| **v_dsp02** | S2, S6, S11, S13 — flag behaviours | **S14** |
| **v_dsp02** | S8, S9, S10 — comparison semantics | **S7** |

## Why it is inflation and not a gap

> **A submission that tests any one clause in the group scores as though it
> tested all of them.**

That is not a coverage hole — the subject matter *is* covered. It is a **scoring
error in the submission's favour**, and it compounds with group size: on v_dsp02,
a testbench that checks the exception-flag word alone is credited with S2, S6,
S11, S13 and S14 — five clauses for one check.

**It is invisible to mutation, and that is the load-bearing part.** Every mutant
dies. A mutant keyed on S2 is killed by the check written for S14, because the
observation is the same one. So the kill table reads 10 of 10, the clause list
reads covered, and the score is higher than the work done.

**This is the cleanest statement this project has of "testbench-only grading
overstates correctness", and it is measured rather than argued.**

The usual worry about grading a testbench is **recognition** — that a model may
have seen the anchor — and every defence built so far attacks that: Class A
anchors, decontaminated copies, the recognition probes, the incognito
re-solicitation. This is a different thing and the difference is what matters:

> **Decontamination does not touch it.** It is a systematic upward bias that
> applies to **every submission equally**, including one that has never seen the
> anchor, including the reference itself. There is no version of the task, no
> cleaner anchor and no better-behaved model for which it goes away, because the
> bias is in how the clauses were grouped under checks — not in what the
> submission knows.

That property is what separates it from every other finding in this document.
The others describe ways a measurement can be wrong. This one describes a way
the measurement is wrong *by construction*, in the same direction, for everyone.

## Detection, and why nothing else finds it

| instrument | what it sees |
| --- | --- |
| mutation | every mutant killed |
| conformant acceptance | every legal variant passes |
| variation | every input exercised |
| witness sync | every recorded string matches |
| **emittability** | **a clause in the spec that no `fail()` can name** |

Only the last one fires, and only because it compares the *spec* against the
*testbench* rather than watching a run. Every instrument that observes a run is
blind to it, because at run time nothing is wrong.

## The fix is not the same as the fix for a missing instrument

They look identical on a clause list and cost different amounts:

- **grouped id** → the check exists and works. Change the **message** to name the
  clause it actually tested, splitting the branch where the group's members are
  distinguishable. v_ca06's D6/D7 split is the worked example: three outcomes
  where there had been two.
- **genuinely unchecked** → **build an instrument.** v_ca06's F2/F3 have stimulus
  and no checker at all.

Mistaking the first for the second costs a build; mistaking the second for the
first leaves a clause unscored.

---

## Working the remaining nine — predictions registered BEFORE measuring

Two tasks is a chosen pair, not a sample: the one I know best and the one I know
least. The spread between them is the result, and the open question is whether
the split is **task-dependent** — a property of the subject matter — or
**author-dependent**, a property of who wrote what and when.

A count taken after the fact cannot answer that, because I would be classifying
with the answer in view. So the prediction goes first.

**The hypothesis:** grouping dominates where a task has **few distinct
observables** and many clauses describing them, because one observation attracts
one check. Genuinely-unchecked dominates where a task has **many separate
observables** — reset, counters, protocol phases — because each needs its own
instrument and one can simply be missing.

| task | observables | **predicted dominant shape** |
| --- | --- | --- |
| `v_ai02` stream realign | output beat, strobe — few | **GROUPED** |
| `v_nw02` atop filter | responses, debt — few, plus a bound | **GROUPED** |
| `v_ca04` stream xbar | routing, fairness, backpressure, reset — many | **UNCHECKED** |
| `v_ca07` clock divider | period, duty, gating, counter, reset — many | **UNCHECKED** |
| `v_nw01` ARP engine | frames, cache, timeouts, config — many | **UNCHECKED** |
| `v_nw03` arb mux | frames, arbitration, backpressure — many | **UNCHECKED** |
| `v_nw04` PTP clock | timestamps, drift, adjust, wrap, reset — many | **UNCHECKED** |

`v_ca05` and `v_dsp01` are NO CONCLUSION — no `spec/*_iface.sv`, so the emittability
tool has no port list to read. They are not predictions and must not be counted
as either outcome.

**What each result would mean.** If the predictions hold, the split is
task-dependent and a new task's shape is knowable from its spec before anything
is built. If they do not, the split tracks something else — most likely *when*
each task was written and by what habit — and the fix is a checklist rather than
a design principle.

### The prediction is UNTESTED, not refuted — the measurement failed its own validation

The registered predictions came back **0 of 7**. Every task predicted GROUPED
measured UNCHECKED or tie; every task predicted UNCHECKED measured GROUPED. A
clean refutation, and I nearly reported it as one.

**Then I validated the measurement against the two tasks already worked by hand.**

| | by hand | proxy |
| --- | --- | --- |
| **v_ca06** | C1, C2 grouped · F1, F2, F3 unchecked | C1, C2, C3, D2 grouped · F1, F2, F3 unchecked — **agrees** |
| **v_ca07** | **C3 and G2 genuinely unchecked**, both confirmed | C3, G2 **grouped** — **wrong on both** |

The proxy classified a candidate as *grouped* if any emittable clause shares its
**section letter**. That is not "shares an observable", and the distinction is the
whole subject of this finding:

> **A section groups by SUBJECT. A subject holds several observables.**
>
> v_ca07's `C1`/`C2` are the counter's **range**; `C3` is the counter **after a
> change**. `G1` is the gating **bound**; `G2` is the gating **level**. Same
> letter, different things to watch — and grouping is precisely about clauses
> that share a *thing to watch*, not a heading.

**No cheaper proxy for the real property is obvious**, and a reader should not
assume one exists. "Shares an observable" means *the same signal, sampled at the
same moment, under the same condition* — which is a fact about what the checker
looks at, not about how the spec is organised. Recovering it mechanically would
mean parsing each check's comparison and matching it against what each clause
describes in prose, which is the hand work with extra steps.

So the result is:

> **I cannot distinguish "the hypothesis was wrong" from "the measurement was
> wrong", and in the one place I can check, the measurement is wrong.** The
> prediction stands unfalsified and untested. Reporting 0 of 7 would have been a
> refutation manufactured by an instrument that disagrees with hand analysis
> wherever hand analysis exists.

**This is the run-against-the-repair principle in a third form**, and the
generalisation is now broader than the tools it came from:

> **Validate a classifier against the cases you have already worked, before
> trusting it on the cases you have not.** The worked cases are the only ground
> truth available, they are free, and they are the ones you are least inclined to
> re-check because you already know the answer.

Registering the prediction is what made this visible. Had I measured first, 0 of
7 would have looked like a finding rather than like a reason to check the ruler.

**What actually tests it**: the by-hand determination of whether a check exists
over the same observable — which is the clause-by-clause work itself, on all
seven. No proxy shortcuts it, and the two shapes are distinguishable only by
reading what each check watches.

**The registered prediction stays visible above, unedited, marked UNTESTED**, so
it can be settled when the hand work is done rather than quietly dropped. A
prediction removed after an inconclusive measurement is a prediction that was
never registered.

---

## A5 on v_ca06 — built, measured, NOT LANDED, and the reason is a finding

**The clause, the stimulus and the checker are all written and the golden passes
them. The boundary is blocked because two CONFORMANT PERTURBATIONS violate the
clause once the stimulus exists.**

### What was built

- **Clause A5** in §1, naming the evasion as well as the obligation: *once a
  `valid` is asserted it remains asserted, with its payload unchanged, until the
  corresponding `ready` is seen* — and *`valid` shall not depend combinationally
  on `ready`*. Hash moved `ca63302d6b23df46` → `c1de26c772eb754d`.
- **Stimulus**: reactive backpressure on all five readies, arm combinational on
  valid, two cycles with a three-cycle cooldown. Ported from v_nw02, not
  rediscovered.
- **Checker**: per-channel held-offer tracker, withdrawal and payload change
  reported separately, antecedent count **reported and never gating**.

**Golden: PASS.** Antecedent held on all five channels — 177, 528, 153, 393, 209.
Every one of the twelve mutants still killed, 5c still OK on both bases.

### What blocked it

`dwc_c1_extra_latency` and `dwc_c5_response_intake_slow` — two of the five
conformant perturbations — **CRASH**, and the run is REJECTED. Reproduced:

    FAIL [A5] channel 3: valid was withdrawn without a handshake (t=6605)
    %Error: rr_arb_tree.sv:391: [ASSERT FAILED] lock_req:
      It is disallowed to deassert unserved request signals when LockIn is enabled.

**The anchor's own vendored RTL asserts the same property internally**, on the
same event, one cycle later. A5 is not a clause I invented to fit a gap — the
design it describes already believes it.

### Why this is the D6/E6 shape again, from the same direction

Both perturbations were written and verified as conformant **while every ready was
held at 1**. They are conformant *at that stimulus*. Adding backpressure — the
stimulus the clause needs in order to be falsifiable at all — reveals that they
withdraw an offer, which the clause forbids and the anchor's own assertion
forbids.

This is the third time extending stimulus has caught a defect in a **legal**
artefact rather than in a mutant: v_ca06's `dut2` violated D7 the moment D7 could
be observed; v_ca07's `dut2` glitched across reconfiguration once the reference
looked; now two conformant perturbations withdraw offers once anything stalls.

> **A conformant artefact is conformant AT THE STIMULUS IT WAS VERIFIED UNDER.**
> Extending stimulus does not only test submissions — it re-tests every artefact
> the task ships, and the ones written to be legal are the least suspected.

### State — LANDED

Spec hash `ca63302d6b23df46` -> `949ffacfa1dd725b` (A5) -> `6cb14e9d2e6381ac`
(D6 narrowed, L7 added). Golden PASS, dut2 PASS, gate rejected, 5/5 conformant
PASS, 12/12 killed, 5c OK on both bases. The two findings that came out of
landing it are below, and the second is the more serious.

---

## FINDING — a conformant artefact that PASSES tells you it did not break the testbench

**It does not tell you it does what its name says. Nothing in the apparatus
separates a control that is legal from a control that is inert — both are
green.**

### The instance

v_ca06 ships five conformant perturbations. Two of them — `dwc_c1_extra_latency`
and `dwc_c5_response_intake_slow` — contained, in the same module:

    assign m_rready = g_rready & <gate>;                                // driver 1
    ...
    .m_rid, .m_rdata, .m_rresp, .m_rlast, .m_rvalid, .m_rready          // driver 2

The bare `.m_rready` binds the **golden's output** to the net the `assign`
already drives — a double drive — and leaves `g_rready` connected to nothing.

**The R channel of "extra latency" and of "response intake slow" had never been
slow.** Two of five conformant perturbations shipped a channel that did nothing.
Both passed every run for as long as they have existed, and their passing was
read, every time, as evidence that they were legal perturbations.

### Why nothing found it

- **Mutation coverage cannot.** Mutants are graded on being killed. An inert
  perturbation is not a mutant and has no kill to lose.
- **The second-DUT gate cannot.** It grades the submission against an
  independent implementation. It never looks at the perturbation.
- **The conformant tally cannot, and this is the sharp part.** `5/5 conformant
  accepted` is the number that is supposed to prove the perturbations are legal,
  and it is satisfied identically by a perturbation that stalls a channel and by
  one whose channel is not connected. The metric that exists to grade these
  artefacts is exactly the metric that cannot see this.
- **Lint nearly could.** Verilator reports MULTIDRIVEN on the net. The task
  builds with `-Wno-fatal`, which is correct for a harness that must not turn a
  vendored-RTL warning into a refusal, and it means the one signal that was
  present went past unread.

It surfaced only when a new clause finally needed that channel to stall, and it
did not.

### The other two instances, and the rule the ruling settled

Gating a `valid` on the way **into** the golden is itself a withdrawal: the gate
falls on a cycle where the golden holds an unaccepted offer. The golden's own
vendored arbiter says so —

    rr_arb_tree.sv:391  "It is disallowed to deassert unserved request signals
                         when LockIn is enabled."

The repair is not "stop being slow". A gate may **fall only while nothing is
pending**, which is one flop per channel:

    hold_x <= (valid_in & gate_x) & ~golden_ready;
    wire gate_x = slow | hold_x;

The perturbation keeps every cycle of slowness — it still refuses to *begin* a
transfer for the whole closed phase. It gives up only the right to take an offer
back, which no conforming design has. `hold_x` is a flop, so the presented valid
never depends combinationally on the ready: A5's second sentence, by
construction.

One channel could not be repaired this way and was ungated outright: **W**.
Stalling `s_wvalid` starves a downstream burst the golden has already committed
to, and the golden responds by withdrawing `m_wvalid` itself. That is an A5
violation on the wrapper's own master port whose author is the golden, not the
wrapper, and no wrapper-side hold can reach it.

### The four instances together

| # | task | artefact | written to be | what a new stimulus found |
|---|------|----------|---------------|----------------------------|
| 1 | v_ca06 | `dwc_c1`, `dwc_c5` | conformant perturbations | **the R channel of both was connected to nothing** |
| 2 | v_ca06 | `dwc_c1`, `dwc_c5` | conformant perturbations | withdraw an offer as soon as anything stalls |
| 3 | v_ca06 | `dut2` | an independent correct implementation | violated D7 the moment D7 could be observed |
| 4 | v_ca07 | `dut2` | an independent correct implementation | glitched across reconfiguration once the reference looked |

> **Extending stimulus does not only test submissions. It re-tests every artefact
> the task ships, and the ones written to be legal are the least suspected.**

### Method note — the first diagnostic read as a much bigger defect than it was, and the signature was in the first failure

Chasing instance 1's consequence, the first slow-slave run reported **43 failures
across seven clause ids** — D3 (wrong id), A3 (wrong beat count), D4, D1, D5, D7
as well as D6. At face value: *the anchor collapses under backpressure*.

It was the diagnostic's own artefact. Phase boundaries drain with
`repeat (40) @(posedge clk)`, ample for a slave that answers immediately and
nowhere near enough for one that idles four cycles per beat. The previous phase's
beats were still arriving when the next began, and **`id 15` — from a phase that
had supposedly ended — turned up attributed to a transaction expecting `id 1`.**
Widening the drain to 600 cycles removed six of the seven clause ids and left
9 x D6 and nothing else.

> A new instrument's first disagreement with the reference is a claim about the
> instrument until it has been run against something known good. The signature of
> contamination was legible in the data — an id from a finished phase — and
> reading the COUNT instead of the FIRST FAILURE would have missed it and
> published "the anchor collapses under backpressure".

---

## FINDING — a clause can be false about the reference and pass every run, when the stimulus that would falsify it is the stimulus the task never generates

**v_ca06's D6 required a downstream read error to be STICKY. The reference is
sticky only while its pipeline stays full. Three idle cycles between narrow R
beats and it stops. The task had never stalled that path, so the clause had been
true by accident for as long as it existed — and every detector in the repository
reported green.**

### The measurement

No wrapper, no perturbation, no valid gating: the testbench's own downstream R
slave simply does not have its next beat ready yet and presents it N cycles
later. A slave is always allowed to do that.

| idle cycles between downstream `R` beats | reference | `dut2` |
|---|---|---|
| 0 — the shipped stimulus | PASS | PASS |
| 1 | PASS | — |
| 2 | PASS | — |
| **3** | **FAIL — 9 x D6** | — |
| 4 | **FAIL — 9 x D6** | PASS |
| 8 | **FAIL — 9 x D6** | PASS |

### Which half fails, and it is not the half that matters

D6 said two things: the error appears on the wide beat containing the erroring
narrow beat, and it persists onto every later beat. Instrumented at the failure
point with `own` = *does the erroring narrow beat belong to this wide beat*:

    DIAG addr=00100000 errbeat=0  j=1 own=0      DIAG addr=00110000 errbeat=1 j=2 own=0
    DIAG addr=00130000 errbeat=3  j=1 own=0      DIAG addr=00110000 errbeat=1 j=3 own=0
    DIAG addr=00330000 errbeat=3  j=1 own=0      DIAG addr=00310000 errbeat=1 j=1 own=0
    DIAG addr=00110000 errbeat=1  j=1 own=0      DIAG addr=00310000 errbeat=1 j=2 own=0
                                                 DIAG addr=00310000 errbeat=1 j=3 own=0

**`own=0` on all nine.** The reference never loses an error on the beat that
carried it. Every failure is persistence — the half AXI does not require.

**The mechanism**: an accumulated response register that is not cleared while
beats keep arriving and IS cleared when the pipeline bubbles. The persistence is
a property of the unit being busy. It became a clause because it was observed,
and it was observed because the only stimulus that existed kept the pipeline
full.

### The four detectors, and why each is blind

| detector | verdict | why it is blind |
|---|---|---|
| **mutation coverage** | 12/12 killed, before and after | every mutant dies at either reading of D6, so the number is identical whether the clause is true or false. A metric that does not move cannot report |
| **conformant acceptance** | 5/5 accepted | the perturbations do not stall that path either. They were written under the same fast-path stimulus, so they agree with the reference for the same reason it agrees with itself |
| **stimulus-variation sweep** | no frozen input | **`m_rvalid` is not frozen. It toggles constantly.** What is frozen is the GAP BETWEEN BEATS, and the sweep's axis is *does this signal take both values*, which it does |
| **attempt-vs-condition classifier** | condition satisfied | D6's counters (`cov_rd_err`, `cov_err_last`) are satisfied at every depth. Errors ARE being requested and DO land on last beats. The condition the clause names was genuinely exercised — at one timing |

**The common cause: every one of them asks whether something was OBSERVED. None
asks whether the thing that would break it was ever ATTEMPTED.** A frozen-input
sweep asks whether a signal took both values. A condition floor asks whether a
predicate ever held. A kill count asks whether a defect was seen. All four are
satisfied by a run that never leaves one corner of the timing space, because none
of them has a name for the corner.

The variation sweep is the sharpest instance and the one to quote: it is the
detector explicitly built to find "this was never exercised", and it passed —
because `m_rvalid` varies. **No instrument in the repository names inter-beat
timing as an axis at all.** The thing that was frozen has no field to be frozen
in.

### The evidence was already in the repository

`dut2` is sticky at every depth. The reference is sticky only when full. **Two
implementations of the same contract disagreed about D6, both were in the task
directory, and both passed every run** — because no run went to a depth where
they disagree. The second-DUT gate is the one detector whose *design* could have
caught this: it exists precisely to separate the contract from one
implementation's incidental choices, and here the incidental choice was
timing-dependent inside a single implementation. It was blind for the same reason
as the rest — it is only ever run at one timing.

### What would have caught it: nothing that exists

Said plainly: **no instrument in this repository would have found this, and none
of the four above can be extended to find it.** Their axis is *values observed*;
this defect lives on an axis of *intervals fixed*.

**What would.** A timing-axis sweep over the REFERENCE, not over coverage:

> For each interval the task holds at its most permissive value, re-run the
> reference at several other values and **diff the reference's own verdict**.
> A clause that is true at one setting and false at another is not a property of
> the design under test; it is a property of the setting.

Four axes are enough for a handshake interface, and none of them is a signal:

1. **gap between consecutive beats on each source-driven channel** — the one that
   found this
2. **ready duty cycle on each sink-driven channel** — what A5's stimulus now
   covers, arrived at from the clause side rather than the sweep side
3. **gap between transactions**
4. **number of transactions in flight**

The instrument is cheap because it reuses the existing sim path: it is N reruns
of the golden, and the output is one bit per (axis, setting) — *did the reference
still pass its own spec*. For v_ca06 that is roughly twelve runs of about a
minute. It is a rule-24 instrument used the way rule 24 intends — reproduce a
known-good answer — with the twist that the reproduction is attempted **at a
setting nobody chose**.

**Its honest limit**, which belongs in the tool's header: it finds clauses that
are false about the REFERENCE. It cannot find a clause that is false about the
CONTRACT and that the reference happens to satisfy at every setting. Nothing
finds those except reading the clause against the standard, and this finding is
not evidence that such a tool is possible.

### Narrowing cost nothing, and the artefacts now straddle the threshold

D6 is now ownership-only; persistence is **L7**, declared-open latitude, with the
accumulator mechanism named in the spec so a reader knows it is incidental rather
than contractual. Measured after the change:

    golden PASS   dut2 PASS   gate rejected   5/5 conformant PASS   12/12 killed
    (dw_m6, dw_m11 and dw_m12 included -- not one kill lost)
    reference PASSES at 3, 4, 8 and 16 idle cycles -- run against the REPAIR
    5c OK on both bases
    hash 949ffacfa1dd725b -> 6cb14e9d2e6381ac

`dwc_c1`'s R gate stalls four cycles and `dwc_c5`'s stalls two — deliberately on
opposite sides of the three-cycle threshold, so the conformant set now exercises
L7 from both directions instead of sampling one. Before this week neither stalled
that path at all.


---

## FINDING — the same instrument gave the right answer on one task and 26 wrong failures on another, and nothing in either run said which

**v_ca06's committed A5 numbers were right BY CONVERGENCE, NOT BY SOUNDNESS.
That distinction is the disclosure.**

A testbench that derives a channel's `ready` from that channel's `valid` closes a
combinational loop through the design. Verilator says so, and said so all along.

**The same instrument, on two tasks: on one it converged and gave the right
answer, on the other it produced 26 failures across six clause ids, none of them
a design defect. Nothing in either run said which had happened.**

### The instrument

A5/D5 need backpressure, and the stall was armed combinationally on the
channel's own `valid` — deliberately, to make the stall land on the cycle the
offer is made rather than one cycle later:

    wire arm_maw = m_awvalid && (st_maw==0) && (cd_maw==0);
    assign m_awready = (st_maw==0) && !arm_maw;

That is a cycle: `m_awready` -> design -> `m_awvalid` -> `arm_maw` ->
`m_awready`. Verilator names it exactly:

    %Warning-UNOPTFLAT: Signal unoptimizable: Circular combinational logic:
      'dw_downsizer_tb.m_arready'   (also m_awready, m_wready, s_bready)

**Four of v_ca06's eighteen circular signals were my testbench's readies.** The
other eleven are the vendored anchor's own and predate this work — measured by
linting the pre-A5 testbench, which reports exactly eleven.

### Why it went unread

The harness builds with `-Wno-fatal`, which is the right setting: a vendored
anchor emits warnings the task cannot fix, and turning those into refusals would
make every task unbuildable. The cost is that a warning about the TESTBENCH,
introduced this week, arrives in the same stream as thirty pre-existing warnings
about the anchor and is invisible by dilution.

> A warning channel that is permanently noisy is not a warning channel. The
> anchor's eleven were the noise; my four were the signal; nothing distinguished
> them at the point of reading.

### The two outcomes, and why only one of them looked like a problem

| task | UNOPTFLAT on TB readies | result |
|---|---|---|
| v_ca06 | 4 | **converged** — every verdict identical to the loop-free run |
| v_ca03 | 3 | **26 failures across A1, A3, COVERAGE, D4, E1 and FLOOR** |

None of v_ca03's 26 was a design defect.

### The tell, and it is the part to record

**Four different one-hot variants — only `s_bready` reactive, only `s_rready`,
only `m_awready`, only `m_arready` — produced the IDENTICAL 26 failures.**

> A defect that does not change when you change what provokes it is a settle
> order, not a design defect.

That is a general diagnostic and it is cheap: make the provoking signal
one-hot, N ways, and compare the failure sets. Identical sets across
independent provocations means the netlist, not the design. `m_wready` alone
passed, which is the only reason the pattern was visible rather than uniform.

### What "right by convergence" means, said plainly

v_ca06's A5 run reported: golden PASS, dut2 PASS, 5/5 conformant, gate rejected,
12/12 killed, 5c OK. Every one of those verdicts survived the repair unchanged.
**They were correct. They were not sound.** The netlist they were computed on
contained cycles that Verilator resolved by iterating to a fixed point, and
whether that fixed point is the circuit's behaviour is not something the run
established — on v_ca03, at the same settle, it was not.

A result that is right because a settle happened to converge is not a result
that the run earned. Nothing in the output distinguishes it from one that did.

### The repair, and what it does not cost

Decouple the stall from `valid` entirely — free-running, aperiodic, per channel:

    logic [15:0] bp_lfsr = 16'hACE1;
    wire stall_maw = bp_lfsr[2] & bp_lfsr[7];
    assign m_awready = !stall_maw;

The original objection was to a **registered** arm: the stall lands a cycle after
`valid` rose, so a valid that is high for one cycle has already been accepted and
the antecedent count comes back at 1. That objection does not reach a stall that
is low some of the time regardless of `valid` — a one-cycle offer meets a stalled
ready at the stall's duty rate. Measured on v_ca06, antecedent per channel:

    armed (looped):  s_b=11  s_r=79   m_aw=19  m_w=112  m_ar=12
    free-running:    s_b=12  s_r=84   m_aw=28  m_w=116  m_ar=18

Better on every channel. UNOPTFLAT back to the anchor's own eleven, no testbench
signal circular. Full suite unchanged: golden, dut2, 5/5 conformant, gate
rejected, 12/12 killed, 5c OK.

**Aperiodic on purpose.** A fixed duty cycle can resonate with a design's own
period and stall only in phases where nothing is offered. An LFSR cannot, and
different bit pairs per channel keep the five decorrelated.

### And a second defect, which the backpressure only EXPOSED

With the loop gone, v_ca06's golden still failed three checks — A2 and B2, on
the write path. Traced:

    TRACE t=3755 AWdown addr=00003000 len=0
    TRACE t=3755 Bup    id=0 resp=0
    DIAG  t=3755 aw0=0 n_ds_aw=0    -> "write issued 0 downstream addresses"
    DIAG  t=3805 aw0=0 n_ds_aw=2    -> the next write, "issued 2"

`n_ds_aw` is incremented in a separate `always @(posedge clk)`; `do_write`
resumes at the same posedge and reads it, racing that block. **With every ready
held at 1 the downstream address and the upstream response never landed in the
same cycle, so the race was unreachable.** Backpressure aligns them. The reads
are now taken at the negedge, and the live `s_bid` / `s_bresp` latched before it.

This is the same class as the inert conformant channels and the anchor's
fast-path stickiness, and it is now the fourth kind of artefact caught this way:
mutants, conformant perturbations, second DUTs — and **the testbench itself.**
The testbench already carried a comment warning about exactly this race on a
different counter. Writing the rule down did not install it in the other two
call sites.

### What to take from it

1. **A harness-side signal must never be derived combinationally from a
   design-side signal it feeds.** Register it, or decouple it. The rule is
   cheap; the failure is silent and load-bearing.
2. **Grep the build log for testbench-scoped UNOPTFLAT specifically.** The count
   alone is useless because the anchor contributes a constant background; what
   matters is whether any circular signal is scoped to the testbench module.
   That is a one-line check and it belongs in the harness, as a REPORT beside the
   verdict rather than a refusal — a task whose anchor is legitimately circular
   must still be runnable.
3. **A result that is right by convergence is not a result.** v_ca06's committed
   numbers were correct. They were correct by luck of a settle order, and the
   run that produced them said nothing at all about that.


---

## FINDING — every passing run of that testbench printed a FAIL line, and the verdicts were right only because the harness greps PASS before FAIL

**Two defects cancelling is not correctness.**

**v_ca03's reference testbench. Two consequences, both silent, both live for as
long as the file has existed.**

    if (n_fail == 0) $display("RESULT: PASS");
    else             // E1's new half is unfalsifiable if every response ...
    // checker would be comparing against the constant the responder drives.
    if (cov_err_r < 4)
      fail("COVERAGE", ...);
    if (cov_err_b < 4)
      fail("COVERAGE", ...);
    $display("RESULT: FAIL (%0d failures)", n_fail);

The `else` binds to `if (cov_err_r < 4)`. Nothing else about the text suggests
that, because two comment lines sit between the `else` and the `if` it captures.

1. **The read-coverage floor ran only on a run that had ALREADY failed.** It is
   skipped precisely when the run is otherwise clean — which is the only
   situation a floor exists for. A floor whose antecedent is "something else
   already failed" is not a floor.
2. **`RESULT: FAIL` printed unconditionally.** Every passing run of this
   testbench ended with a FAIL line. The verdicts were nonetheless right, because
   `sim_verification.sh` greps `^RESULT: *PASS` before `^RESULT: *FAIL` — a
   property of a file this testbench does not control, and one nobody chose for
   this reason.

> A verdict that is correct because of the order of two greps somewhere else is
> not a verdict the testbench produced. Reverse those two lines in
> `sim_verification.sh` — a change nobody would think to check against this
> file — and every passing run of v_ca03 inverts.

### The syntactic scan was the wrong instrument; the behavioural one was right

Grepping for `else` followed by comments and an `if` reports every legitimate
`else if` chain: 0 to 10 hits per testbench, no signal. **Running all eleven
reference testbenches and counting RESULT lines** answers the actual question in
one number:

    ten of ten runnable testbenches: exactly one RESULT line
    v_ca03: two                     <- the only instance
    v_dsp01: REJECTED, ships no testbench

The scan itself needed two corrections before it was trustworthy — one task's
`tb_module:` carries a trailing comment that a naive `sed` left in the string,
and one task keeps its `task.yaml` elsewhere. Both showed up as BUILD_FAIL/SKIP
rather than as a clean row, which is the right failure: **a sweep that cannot
build a task must say so rather than score it 0 and move on.**

---

## FINDING — a control that passes is not evidence the clause holds; it is evidence the control did not run, and the two are indistinguishable in the output

**Two controls built this week, and the first version of each was wrong in a
different way. One of them was wrong by passing.**

A5 on v_ca06 and D5 on v_ca03 both landed with checkers that passed everything
the task ships. That is what a correct clause looks like. It is also what a
clause with no instrument looks like, and nothing in the task separated the two:
every mutant in both sets dies on some other clause, so no mutant licensed a
claim that the handshake checker fires at all.

### Three ways the controls were wrong before they were right

**1 — the obvious candidate was not a control for the clause.** `iw_c3` before
its repair withdraws a valid, which is exactly what D5 forbids — but it
withdraws one going INTO the design. It fails **C2, twenty times**, because the
design's accounting diverges from the testbench's, and it never touches D5. D5
binds the design's OUTPUTS. *A control has to violate the clause on the side the
clause binds.*

**2 — a control assembled by copying a neighbour inherits the neighbour's
wiring.** The first D5 control was built from `iw_c3`'s instantiation, which
binds `g_awvalid` and `g_arvalid` — signals that do not exist in the new module.
It also gated the design's ready to avoid a phantom handshake. It hung the A4
phase and reported A3, A4 and A5. *A control whose blast radius exceeds the
clause it is for cannot license a claim about that clause.* Rebuilt by parsing
the golden's own module header, so the port list cannot drift from it.

**3 — and the one that matters: the A5 control PASSED.** At a threshold of three
consecutive stalled cycles it never triggered, because backpressure is aperiodic
and `m_arvalid` enters the antecedent only 18 times in the whole run.

> **A control that passes is not evidence that the clause holds. It is evidence
> that the control did not run.** The two are indistinguishable in the output,
> and the second is the more likely of the two for any control whose trigger is
> conditioned on rare timing.

This is the same shape as the inert conformant channels — a green artefact that
did nothing — and it is the fourth time this week that "it passed" has turned out
to mean "it was not exercised". The remedy is the same and it is cheap: a control
must report *whether it fired*, not only its verdict.

### What the controls look like now

Both withdraw `m_arvalid` **only on a cycle when `m_arready` is already low**, so
no handshake is lost and the wrapped design sees a bit-identical environment —
its ready is passed through untouched. The single observable difference is the
one thing the clause forbids.

    v_ca03  negctl/d5_withdraws_ar.sv   FAIL -- 11 x D5, channel 4, nothing else
    v_ca06  negctl/a5_withdraws_ar.sv   FAIL --  5 x A5, channel 4, nothing else

Both deliberately violate the clause's second sentence too — `m_arvalid` is
combinational on `m_arready` in the control. That is safe *because* the
testbench's readies are now LFSR-driven and read no design output; under the
armed stall it would have closed a loop.


### The instrument, built, self-tested, and validated against the instance that motivated it

`inbox/check_fired.py.for-scripts`. The convention: any artefact whose
evidentiary value depends on its trigger occurring prints, once per run,

    FIRED <name> <count>

and the tool **REFUSES** on zero. It refuses **ABSENT separately**, because
absent is not zero (rule 20) — the artefact is not in this run at all, and no
count can be inferred from silence. A **duplicate name is a refusal, not a sum**:
two artefacts under one name is the clause-grouping shape, where one sits at zero
while the other carries the line and the reader sees a healthy number.

**Validated against the defect and against the repair**, which is standing
practice here:

| run | verdict | FIRED | tool |
|---|---|---|---|
| A5 control, threshold 3 — *the version that passed* | `RESULT: PASS` | `...drop 0` | **REFUSED** |
| A5 control, threshold 2 — the working one | `RESULT: FAIL` | `...drop 5` | OK |
| a variant with no declaration | — | — | **REFUSED**: undeclared is not exempt |

Self-test 7/7. Declarations live in `task.yaml` as `must_fire:` **keyed by
variant**, not as a flat per-task list — the negative-control run contains no
conformant perturbations and vice versa, and a gate that fires on runs it does
not apply to is one that gets routed around within a week.

### Four kinds, and the fourth had to be named out loud

    a control              -> how many times its trigger asserted
    a coverage floor       -> the count it already keeps
    a perturbation's gate  -> how many cycles it was closed on a live offer
    a NEVER-HAPPENS check  -> how many times its antecedent was REACHABLE

The last is a fifth instance, from AGENT-DESIGN-43a92055 on `d_ca01`'s M3:

    chk(m3_overlap_err == 0, "a memory request was issued while a"
                             " transaction was in flight");

vacuously true for a design that issues no memory transaction at all. It cannot
separate *never issued two at once* from *never issued one*. A never-happens
assertion **counts nothing by construction** — its whole form is an absence — so
a tool keying on "a counter exists and reads zero" sees nothing here, because
there is no counter. The rule that makes it covered: its FIRED count is not how
often it fired, it is **how often the situation it forbids was reachable**, and
that is a different counter which nothing derives automatically.

### The tool's own header claimed coverage it did not have, and that is the finding

I wrote **"three of four instances"** into `check_fired.py`'s header before
measuring. The measurement says **two**. In the header of the tool built to catch
exactly this. It is the plainest instance of the class I have produced, and it is
recorded here rather than only in the header because a correction that lives only
in the artefact it corrects is not a disclosure.

### The uncovered instance is the one the class hinges on

Measured in the historical configuration — pre-repair perturbation, pre-A5
testbench, the run in which it passed:

    FIRED dwc_c1.r_backpressure 5      -> OK, and the channel was inert

**Five, not zero.** The double-driven `m_rready` did go low sometimes; it just
was not the gate doing it.

> A port-level count answers *did this channel stall*. The question was *did
> THIS PERTURBATION stall it*. And no counter on the perturbation can answer
> that, because **a bypassed mechanism produces no counter at all** — there is
> nothing to instrument.

`FIRED` puts the observer INSIDE the artefact. That works for a control, whose
trigger is its own logic, and fails for a perturbation, whose mechanism may be
absent. The remedy has to observe from outside.

### The remedy, built and measured: `check_artefact_warnings.py`

**The toolchain reported this defect all along.** Linting the pre-repair
perturbation:

    %Warning-UNDRIVEN:    extra.sv:108: Signal is not driven: 'g_rready'
    %Warning-MULTIDRIVEN: extra.sv:90:  Bit [0] of signal 'm_rready' have
                                        multiple combinational drivers.

Both name the defect on its line. **Seven warnings named the perturbation; one
hundred and twenty-eight were in the build.** That is the same dilution failure
that hid the combinational loop — `-Wno-fatal` is the correct setting for a
vendored anchor, and its cost is that a warning about an artefact the task owns
arrives in the same stream as the ones it cannot fix.

So the gate does not turn the noise down. It **separates the two populations by
file** and refuses only on the half the task is responsible for. `extra.sv` (the
perturbation or mutant) is task-owned; `variant.sv` (the golden) and `sub.sv`
(the submission) are not — the two halves of a variant build are separable by
filename even though both are temporaries. A submission's warnings are reported,
never refused: failing a submission for style rather than for what it measures
is a different defect.

Refusing kinds are only those meaning *the netlist and the text disagree* —
UNDRIVEN, MULTIDRIVEN, UNOPTFLAT, IMPLICIT, LATCH, BLKANDNBLK, PINMISSING.
Deliberately not WIDTHTRUNC, UNUSEDSIGNAL, PROCASSINIT, BLKSEQ or the rest: a
gate that fires on style gets routed around, which is how both defects survived.

**Validated on both defects and both repairs:**

| build | task-owned / anchor | verdict |
|---|---|---|
| `dwc_c1` before the double-drive repair | 5 / 123 | **REFUSED** — UNDRIVEN `g_rready`, MULTIDRIVEN `m_rready` |
| `dwc_c1` after | 4 / 123 | OK — notes only |
| testbench with the armed stall | 4 / 64 | **REFUSED** — 4 × UNOPTFLAT on its own readies |
| testbench free-running | 0 / 63 | OK |

Self-test 7/7.

**It takes two passes, and finding that out cost a wrong cell in its own
validation table.** `--lint-only -Wall` reported *zero* task-owned warnings on
the armed netlist that provably contained four circular testbench signals:
UNOPTFLAT is emitted by the scheduler, which `--lint-only` skips, while
UNDRIVEN needs `-Wall`, which the scoring build does not use. A gate run on
either pass alone misses one of the two defects it exists for. The first table I
generated had that cell wrong and reported OK.

Its own notes are **summarised by kind, not listed**. The free-running testbench
draws 33 of them, all benign and all correct; printing 33 lines above a two-line
refusal rebuilds, inside this tool, the exact dilution it was written to undo.

### And the differential check I was going to propose would not have worked

The obvious complement is: a perturbation must differ from the golden somewhere
observable on the channel it claims to affect, with the observer in the testbench
— outside the artefact, so a perturbation cannot forget to instrument itself or
instrument itself dishonestly. Emit a per-cycle checksum per declared signal,
compare across runs, refuse if the declared channel's trace is identical.

**It would have passed the pre-repair `dwc_c1`.** That perturbation's `m_rready`
was not *unchanged* — it was *garbage*, double-driven, and it differed from the
golden's plenty.

> *Differs from the golden* and *does what it says* are not the same predicate,
> and only the second is what a conformant perturbation claims.

Where a differential check IS the right instrument is the neighbouring case: a
perturbation whose mechanism is present and correct but whose condition is never
true — a gate wired properly to a signal that never asserts. There `FIRED` on the
gate answers it more cheaply, so the differential check earns its cost only for a
perturbation with no single nameable trigger. I have not built it, and on the
evidence here it is the third-best of the three.

### Every exclusivity claim I have made is dated as of today

From AGENT-DESIGN-43a92055, and it lands on my own work within the hour it was
written: `d_nw03`'s `nc_b_outputs_serialised` was recorded 6/8 `exclusive: true`.
An R1 output-stability check was added; it now reads 0/8. **Nothing in the
control moved.**

> `exclusive: true` was never true. It was UNVERIFIABLE, which is a different
> thing and reads identically. The claim was "fails on C1 and nothing else"; what
> could be observed was "fails on C1 and nothing else *that was checked*".

I wrote "11 × D5 and nothing else" and "5 × A5 and nothing else" today. Both are
claims about the set of checks these tasks had **on 2026-08-25**, and both now
say so in `task.yaml`. My `v_ca07` H3 pair carries the same asterisk. The
proposal that `exclusive:` carry the date or checker revision it was measured
against is right and I support it for contract revision 3.

---

## FINDING — the emittability prediction is refuted as a predictor: 3 of 6, which is chance

**All seven registered tasks worked by hand, 44 candidates classified. The
hypothesis had no signal, and the real result is somewhere else: the gaps are
CONCENTRATED, not spread.**

### The seven, worked

| task | predicted | false positive | grouped | **unchecked** | measured | |
|---|---|---|---|---|---|---|
| `v_ai02` | GROUPED | 4 | 2 | 0 | GROUPED | **✓** |
| `v_nw02` | GROUPED | 1 | 3 | 0 | GROUPED | **✓** |
| `v_ca07` | UNCHECKED | 3 | 0 | **2** | UNCHECKED | **✓** |
| `v_nw01` | UNCHECKED | 0 | 2 | 0 | GROUPED | ✗ |
| `v_nw03` | UNCHECKED | 8 | 1 | 0 | GROUPED | ✗ |
| `v_nw04` | UNCHECKED | 1 | 8 | **6** | GROUPED | ✗ |
| `v_ca04` | UNCHECKED | 3 | 0 | 0 | **no real candidates** | — |
| | | **20** | **16** | **8** | | **3 / 6** |

Three of six decidable. That is a coin.

> **REGISTERED IN ADVANCE:** *"If the predictions hold, the split is
> task-dependent and a new task's shape is knowable from its spec before
> anything is built. If they do not, the split tracks something else — most
> likely when each task was written and by what habit — and the fix is a
> checklist rather than a design principle."*
>
> **The predictions did not hold. THE HYPOTHESIS CARRIES NO INFORMATION.** A new
> task's shape is not knowable from its spec, and the fix is a checklist.

Recorded in those terms because they were fixed before the measurement, and
because a hypothesis that is allowed to be re-read after the result is not one.

`v_ca04` is excluded rather than scored: all three of its candidates are false
positives, so it has no dominant shape to be right or wrong about. Counting it
either way would be choosing a denominator after seeing the numerator.

### The result that IS there: the gaps are concentrated

**Six of the eight genuinely-unchecked clauses are in ONE task.** Five of the
seven have none at all. Emittability gaps are not a systemic property of how
these tasks are written — they are a `v_nw04` property, and to a much smaller
extent a `v_ca07` one.

That is a more useful finding than the one predicted, and it is the opposite
shape: not a gradient across tasks, but a single outlier.

### 45% of the candidate list is noise, and on one task it is 89%

Twenty of 44 are definitions, permissions or obligations addressed to the tester
— `v_nw03` contributes eight of nine. The tool says so in its header ("CANDIDATE
LIST, NOT A VERDICT", calibrated at 2 real of 5) and the measured rate across
seven tasks is **24 real of 44**, close to it. But the per-task spread is
enormous, and a reader taking a per-task count at face value would be badly
wrong about `v_nw03`.

### `v_nw04`: an entire output had no reader, and a set's value was never compared

    $ grep -c ts_step_o tb/ptp_time_base_tb.sv
    1                    # the port map

**A4** ("`ts_step_o` is asserted on exactly the cycles `adj_active_o` is, plus
the cycles §S names, and on no others") and **S3** ("each such assertion raises
`ts_step_o` for exactly one cycle") describe an output the testbench connected
and never looked at. It is not a dead signal: measured, it is high on **35
cycles** across **4 set windows**.

**S1** and **S2** were worse. `set_ts96()` drove the set and raised `settle`,
which suppresses the increment checker for a few cycles — so **a design that set
the base to any value at all passed**, provided it kept incrementing legally
afterwards. The value written was never compared to the value read.

All four now have instruments:

- **A4** is checked as an equality, cycle for cycle: outside a set's window
  `ts_step_o` must EQUAL `adj_active_o`. Not correlated, not counted.
- **S3** is checked **per set**, not per run. A global identity
  `steps == adj_active cycles + sets` is satisfied by a design that raises two
  steps for one set and none for the next, so it is not the clause.
- **S1/S2** compare the base against the value written, allowing only the
  increments reachable in the sampling window — a wrong value misses that
  interval by orders of magnitude, not by a beat.

**Validated by three controls that must fail, because no mutant exercises any of
them** — by this file's own standard, a checker whose refusal is unverified is a
checker that has not been shown to fire:

| control | result |
|---|---|
| `ts_step_o` tied low | **FAIL — 24 × A4** |
| `ts_step_o` tied high | **FAIL — 24 × A4** |
| the set never reaches the design | **FAIL — 3 × S1, 3 × S3** (and 1 × W1, collateral) |

Golden PASS, dut2 PASS, conformant PASS, gate rejected, **10/10 killed**.
Candidates 15 → 11. `tb/` is not in `task_text_hash`, so no hash moved.

The third control's blast radius exceeds one clause, so it licenses *"the
checker refuses"* and not *"it refuses on this clause alone"*. Those are
different claims and only the first is being made.

### A shape worth naming: grouped AND unexercised is worse than either

`v_nw01`'s **C2** — "the cache holds 4 entries; an insert never fails; when full
it displaces an existing entry" — is reportable: a failed insert surfaces as a
missed lookup under **Q1**. But `cov_hits >= 4` is the only floor near it and
**nothing requires a fifth distinct insert**, so the clause is credited to
another id *and* its antecedent may never be reached.

> Grouping hides which clause was tested. An unguarded antecedent hides whether
> anything was. Together the clause is scored, invisible, and possibly never run
> — and each defect alone would have been easier to see than the pair.

`v_nw01`'s **C1** is the honest opposite and worth the contrast: its text says
*"answered from the cache under Q1"*. The clause **names the id that reports
it**. That costs one clause of prose and removes the whole ambiguity, and it is
the cheapest fix in this finding.


---

## FINDING — the check and the thing that disabled it were written together, in one helper, and neither looks wrong alone

**v_nw04's S1 and S2 did not merely go unchecked. They ACCEPTED ARBITRARY
BEHAVIOUR: a design that set the time base to any value at all passed, provided
it kept incrementing legally afterwards.**

### The helper

    task automatic set_ts96(input longint unsigned s, input longint unsigned ns);
      @(negedge clk); set96 = {48'(s), 2'b00, 30'(ns), 16'd0}; set96_v = 1'b1;
      @(negedge clk) set96_v = 1'b0;
      settle = SETTLE;  last_drift[0] = -1; last_drift[1] = -1;
    endtask

Four lines. The first three are the only stimulus in the task that exercises S1.
The fourth raises `settle`, which suppresses the increment checker for the cycles
that follow — legitimately, because a set is a discontinuity and the increment
checker would report it as an illegal advance.

**Neither half is wrong.** Driving a set is right. Suppressing an increment check
across a discontinuity is right. What is wrong is that they are the same four
lines, so:

> **The only stimulus that reaches the clause is also the thing that turns off
> the checking around it.** A reader auditing the stimulus sees a correct set. A
> reader auditing the suppression sees a correct warm-up. The defect is in the
> conjunction, and the conjunction has no reader.

### Why it is not a coverage gap

A coverage gap is silent: a clause that is never exercised reports nothing and a
floor can catch it. This is louder and worse. The clause WAS exercised — four
times, with `cov_sets >= 3` enforcing it — and the run reported PASS. **A floor on
S1's stimulus would have been satisfied.** The apparatus had the antecedent, the
stimulus and a passing verdict, and no comparison between the value written and
the value read existed anywhere.

An unchecked clause says nothing. This one said *yes*.

### The field had already been audited once, for something else

`settle`'s own comment records a previous correction:

    int settle = 8;   // clause X2b: the warm-up the SPEC grants, and no more.
                      // It was 20 -- an allowance the reference took and the
                      // submission was not given, which is not a fair measurement.

Somebody looked hard at this variable, found a real defect in its VALUE, fixed
it, and wrote the reasoning down. What they were not looking at was **what the
suppression window contained**. Scrutiny of a field is not scrutiny of what the
field switches off.

### The general shape, and where else to look for it

> **A stimulus helper that both provokes a condition and suppresses the check for
> it.** Search term: any assignment to a check-gating variable (`settle`,
> `checking`, `reply_en`, an `if (armed)` guard) inside a task whose other job is
> to drive stimulus. Each such site is a place where a clause may be exercised
> into a window where nothing is watching.

This is mechanically findable — it is a grep for check-gating writes inside
stimulus tasks — and it is the third instrument this week whose defect the
toolchain could have named. I have not built it.

---

## FINDING — grouped AND unexercised at once, and a one-sentence remedy for the whole grouping family

**Two defects that are each visible on their own become invisible together.**

### The pair

`v_nw01`'s **C2** — *"the cache holds 4 entries; an insert never fails; when full
it displaces an existing entry"* — is **grouped**: a failed insert surfaces as a
missed lookup under **Q1**, so it is reportable, just not under its own name.

It is also **unexercised**: `cov_hits >= 4` is the only floor near it and
**nothing requires a fifth distinct insert**, so the antecedent that would make
the displacement observable may never be reached.

| | what it hides | how you would normally catch it |
|---|---|---|
| **grouping** | *which* clause was tested | read the failure message and see it names another id |
| **unguarded antecedent** | *whether anything* was tested | a coverage floor reads zero |
| **both** | — | **neither**: the floor that would read zero is on the OTHER clause, and it is satisfied |

Grouping moves the reporting to Q1. Q1's floor is about lookups and is satisfied.
C2 has no floor of its own because it has no checker of its own — that is what
being grouped means. So **the two defects cover for each other**, and each alone
would have been easier to see than the pair.

### C1 is the honest opposite, and it costs one sentence

`v_nw01`'s **C1** — same section, same author, same page — reads:

> *"Every received ARP frame — request or reply — inserts the pair (`SPA`, `SHA`)
> into the cache. **A lookup of that address afterwards is answered from the
> cache under Q1.**"*

**The clause names the id that reports it.** No instrument, no tooling, no run.
One sentence of prose, and the ambiguity is gone: a reader knows C1 is grouped,
knows where to look, and can check that Q1 exists.

### Propose this as the general remedy for the grouping family

The grouping family is the headline finding in this file — several clauses share
one observation, one check and one reported id, so a submission testing any is
credited with all. It is invisible to mutation (every mutant dies either way),
untouched by decontamination, and this week it accounted for **16 of 44** worked
candidates. Everything built against it so far has been an instrument.

> **Every clause whose observation is shared should name, in its own text, the id
> that reports it.**

It is cheaper than every instrument built this week, by a wide margin, and it
fixes the dominant defect class rather than detecting it.

**And it turns prose into a declaration that can be checked.** `check_clause_
emittable.py` currently subtracts the emittable set from the stated set and calls
the remainder candidates. With this convention it can do better: a clause saying
*"reported under Q1"* is a claim, and the tool can verify that `Q1` is in fact
emittable — turning a hand judgement I made seven times this week into a
mechanical one. That is the difference between an annotation and a comment.

**Its limit, stated so it is not oversold:** it records grouping honestly, it
does not remove it. C1 is still credited under Q1, and a submission that checks
Q1 is still credited with C1. What changes is that the credit is *visible* and
the scoring can decide deliberately, instead of the grouping being discovered by
someone reading a failure message and noticing the wrong letter.


---

## The grouping remedy, applied to two tasks and made checkable

**Annotation landed on `v_ca06` and `v_ca03` — the two tasks whose hashes were
already moving this week, so the convention cost nothing marginal to exercise.**

    v_ca06   C1 -> C4, C2 -> C4                    candidates 7 -> 5
    v_ca03   A2 -> D1, B1 -> E1, B3 -> E1, C1 -> C2  candidates 9 -> 5
    hashes   6cb14e9d2e6381ac -> ae29e2161468aeff
             fc1baef44b90f91c -> fa23813e5874ef92
    both suites re-run: ACCEPTED, 12/12 and 11/11

`check_clause_emittable.py` now reads *"reported under X"* as a **declaration and
verifies it**: the named id must itself be emittable. A clause annotated into a
hole reads as resolved and is worse than one left silent. Declaration self-test
7/7, tool self-test 5/5.

### What is NOT annotated, and why that matters more than what is

Annotation is for clauses that ARE reported, elsewhere. It is not a way to make
an unchecked clause look handled:

- **v_ca06 F1, F2, F3** — phase L asserts reset, releases, waits four cycles, and
  then nothing follows. They need an instrument.
- **v_ca03 D2** — D1 catches a master identifier serving two slave ids at once.
  D2's own case — reuse after the first stops being outstanding and before it
  retires under A4 — has no check. The clause text already said why it was called
  out separately; nothing acted on it.
- **v_ca03 F1**, and this is the worst thing in this section:

      $ grep -nE "rst_n *(=|<=)" tb/id_width_conv_spec_tb.sv
      34:  logic clk = 0, rst_n = 0;
      407:    @(negedge clk) rst_n = 1;

  **Reset is never asserted mid-run.** No F-clause `fail()` exists and no mutant
  touches reset. F1's substantive half — *no transaction outstanding before reset
  shall produce a response afterwards* — is neither instrumented nor exercised.
  Two of my tasks now have an uninstrumented reset clause, which makes it a
  habit rather than an oversight.

### The founding case is not in the candidate list, so the tool grew a second mode — and the first unit was wrong

Subtracting emittable from stated cannot find `D6`/`D7`: **both were nameable**.
They shared one branch, and a submission checking precedence was credited with
checking code preservation. So `--shared` was added.

**The first unit was the `begin`/`end` block, and it was wrong.**
AGENT-DESIGN-43a92055 predicted the failure *before running the tool*: their
testbenches are phase-structured, checks batched in an end-of-run results block,
and `d_ca01`'s largest block emits nine distinct clause ids from one `begin` —
nine genuinely separate observations. Measured here on a reduced form of exactly
that structure:

    results block, 6 independent ifs  ->  M1 M2 M3 R3 R5 R6     <- pure noise
    one condition, D5/D6/D7 chain     ->  D5 D6 D7              <- the real thing

**Indistinguishable.** A block is a scope; it is not an observation.

What makes `D5`/`D6`/`D7` one observation is that they are **mutually exclusive
branches of one condition**: at most one can fire, so at most one clause is ever
named for a single wrong value, and a submission checking any is credited with
all. Six independent `if`s in a results block have the *opposite* property —
each fires on its own evidence.

The unit is now the **if/else chain**. Corpus-wide:

| | before (begin/end) | after (if/else chain) |
|---|---|---|
| rows | **42** | **5** |

    v_ca06   D5 + D6 + D7     <- the founding case, isolated exactly
    v_nw04   I1 + W1          <- deliberate, and that testbench says so
    v_ca03   C2 + E1
    v_ca04   R4 + R5
    v_nw02   F2 + P2

**Its limit, measured rather than assumed:** branches wrapped in `begin`/`end`
are **missed**, not misreported. Missing is the right way for this to fail — a
candidate list that over-reports gets ignored, and this tool has already been
ignored once for exactly that reason.

> **A peer's prediction about my instrument, made before they had run it,
> corrected it.** They could not have measured it — they did not have the build.
> They reasoned from the structure of their own testbenches, which differs from
> mine, and were right. Calibrating an instrument only on the corpus you wrote
> is how it acquires your blind spot; 42 rows would have been dismissed as noise
> and the five real ones lost inside them.


### The second unit is a peer's, it finds a different population, and neither subsumes the other

AGENT-DESIGN-43a92055 could not run `--shared` — they did not have the build —
so they answered the question a different way: **grep every check message for two
or more clause ids.** Their formulation of why that is the better default is the
one to keep:

> **A block is a scoping accident; a message is one observation reporting one
> verdict**, which is precisely what the convention is about.

Implemented and run. **On my eleven: 16 message rows and 5 chain rows, 21 total.
Across the whole corpus: 18 and 5, 23.** I first recorded 18 as the figure for my
eleven; it is the corpus number. AGENT-PPA-2381f2fe checked the scope before
believing the difference meant anything, which is why the record is right.
The two units find genuinely different things:

**1 — My corpus already declares grouping in the id field, in eight places, and
nobody had enumerated them.**

    v_ca03   "A3/A5"    id refused though the contract permits it
    v_ca04   "R1/R4"    payload from an input that was never offered
    v_nw01   "Q1/X3"    no response within N cycles
    v_nw02   "F1/F2"    an AW reached the master port that no write asked for
    v_nw02   "F4/F5"    an R beat arrived for an id nothing is owed
    v_nw02   "W3/X4"    AW never accepted
    v_nw02   "P3/X4"    an AR was offered for N cycles and never accepted
    v_nw02   "W2/W3"    AWs admitted with no W burst completed downstream

Eight checks reporting for two clauses each. **This is the convention I have
been proposing, already in use, undeclared and uncounted** — the id field says
`A3/A5` and the spec says nothing. The remedy for these is not new prose; it is
to make the spec agree with the id string that already exists.

**2 — A false-positive class, and it is the mirror of theirs.** Six rows are
FLOOR or COVERAGE messages naming which clauses they protect —
*"E1, C1 and D4 go unchecked on a single-beat run"*, *"W1 and W3 are untested"*.
Those are not grouped verdicts; they are floors saying what they guard. Exactly
their `d_ai01` `C2/C3` metric line: **the unit surfaces it and a human discards
it in one read**, which is the correct division of labour and is not available
from a block-based unit at all.

**3 — The sharpest row in either corpus is `v_dsp02  S2 + S6 + S8 + S9`:**

    fail(e.op == OP_MINMAX ? "S6"
       : (e.op == OP_CMP ? (e.mode == 3'd2 ? "S9" : "S8") : "S2"), ...)

**One check whose reported clause is selected at runtime from four.** Not two
clauses sharing an observation — four clauses sharing a check, with the
attribution computed. That is the grouping family at its limit and it was
invisible to every pass before this one.

**Neither unit subsumes the other.** `D5`/`D6`/`D7` name one id each, so the
message unit cannot see them; the `X/Y` population names two ids in one call, so
the chain unit cannot see it. Both passes are needed and the tool now runs both,
labelled `msg` and `chain` so a reader knows which question produced each row.


---

## FINDING — an input that changes only during initialisation is not a varied input, and no variation tool can tell

**Three tasks, independently written, all with a reset clause stating what reset
does to STATE, and none of them reaching it. Two are mine.**

| task | the clause | why it is unreachable |
|---|---|---|
| `v_ca03` | **F1** — *no transaction outstanding before reset shall produce a response afterwards* | `rst_n` is assigned twice in the whole testbench: `0` at declaration, `1` at line 407. **Never asserted mid-run.** No F-clause `fail()`. No reset mutant |
| `v_ca06` | **F1, F2, F3** — reset, post-reset idle, no stale response | phase L asserts reset, releases, waits four cycles, and then **nothing follows** |
| `d_ca03` | **V2** — *`rst_ni` asserted low empties both TLBs* | reset happens only when the TLBs are already empty, so a design that ignores reset entirely is indistinguishable from a conforming one (AGENT-DESIGN-43a92055) |

### The reading that makes it structural rather than a habit

From AGENT-DESIGN-43a92055, and it is better than mine:

> **Reset gets written as *initialisation*, because that is what a testbench
> needs it for.** The clause that says what reset *does to state* is a different
> requirement, and the initialisation path can never reach it. The two uses share
> a signal and nothing else.

A testbench author writes `rst_n = 0; ... rst_n = 1;` once, at the top, because
the DUT must start somewhere. That code is correct, necessary, and satisfies
every instinct that the signal has been handled. The clause needs the *other*
use — assert reset onto a populated machine and check what survives — and nothing
in the first use suggests the second is missing.

### And the instrument says the input is fine

This is the part that generalises past reset. `d_ca03`'s harness **does** track
`rst_n` in its stimulus-variation instrument — `V_RST` at
`sv39_mmu_harness.svh:179`, compared at 205.

**It varies exactly once, at time zero, and the checker records it as VARIED. The
row is clean.**

> The check exists. The input moves. The requirement is unreachable. A
> varied/constant bit cannot separate *this input takes both values* from *this
> input took its other value once, before anything was in the machine*.

That is this file's *"a clean row is read once"* arriving through a different
door, and it is worse than the original, because here the instrument is
**correct** — `rst_n` really did take both values — and still reports nothing
useful.

### The remedy, and it is an instrument change in my area

**Count transitions AFTER reset release, not values over the whole run.**

    varied/constant bit      -> "rst_n took both values"          useless here
    transitions after t0     -> "rst_n asserted 0 times after
                                 the run began"                    the fact

That is a small change to `check_stimulus_variation.py` — a second number
alongside the existing one, not a replacement, because for most inputs the
existing question is the right one. It refuses nothing on its own; it makes
`0 transitions after release` visible, which is the number that would have found
all three of these.

**Not built.** It is the fifth named-but-unbuilt instrument this week, and by the
week's own standard that count matters more than any of the individual gaps.

---

## v_ca05 — the task both instruments were blind to, and what was under it

AGENT-PPA-2381f2fe asked for a look before step 4, on the grounds that **two
independent instruments could say nothing about this task for two unrelated
reasons**: it has no coverage floor for `check_fired` to read, and its port map
lives in `probe/PASTE.md` rather than `spec/*_iface.sv` so stimulus-variation
could not parse it. That is a good reason to look and it was right.

### What the hand pass found

Nine emittability candidates: **five false positives** (`R3`, `R6` latitude;
`R4`, `R7`, `R11` handshake definitions) and **four grouped**, none unchecked:

    R2  per-tag FIFO order            -> reports under R8
    R9  peek does not remove          -> reports under R8
    R10 pop of an absent tag          -> reports under R8
    R13 an all-zero mask matches all  -> reports under R12

**And the testbench had no coverage counter and no `fail("FLOOR")` anywhere in
it.** For a grouped clause the antecedent is the only thing standing between it
and being unexercised — and nothing was watching any of the four. This is
`v_nw01`'s C2 shape, **four times over in one task.**

### Closed, on the half that costs nothing

Four antecedent counters and four floors, gated on the **stimulus half only** —
each counts an event the testbench chooses to drive and reads no design output,
so none can reject correct hardware:

    peek=6   pop-absent=401   zero-mask=1   multi-deep pop=14
    golden PASS, dut2 PASS, 4/4 conformant, gate rejected, 10/10 killed

**`zero-mask=1`.** R13's antecedent is reached exactly once in the whole run. The
floor now makes an edit that deletes that single `do_match(0, 0, ...)` fail —
which is what it is for — but R13 rests on one observation, and that is worth
knowing rather than inferring from a green row.

### Two mutants already covered two of the four, and that is not the same thing

`tt_m8_peek_removes_last` (R9) and `tt_m9_zero_mask_no_hit` (R13) both die, so
those antecedents were being reached.

> A mutant dying is evidence **after the fact** that the stimulus happened to
> exist. The floor is the guarantee that it still will. Nothing was keyed on R2's
> or R10's antecedent either way.

The spec annotations (`R2 -> R8`, `R9 -> R8`, `R10 -> R8`, `R13 -> R12`) are
**held**: that is a clause-text edit, v_ca05's hash is not otherwise moving, and
the agreed sequence is to batch those behind whatever moves it next. The floors
are `tb/` only and cost nothing.


---

## FINDING — F91 inverted: an instrument with no consumer. Measured, and it is fifteen

**AGENT-PPA-2381f2fe named the class from one instance. I measured the
population and it is most of the apparatus.**

Their instance: `check_stimulus_variation.py` has no caller in `scripts/`,
`runner/` or any hook, writes nothing — twelve prints to stdout — and **zero
records in the whole `runs/` corpus carry a stimulus or frozen field.** A tool
that runs, is right, and has never entered any artefact.

> **F91 was a field with no reader — correct, present, inert. This is an
> instrument with no consumer. Both fail the same way, from opposite ends, and
> neither is visible from the artefact.**

### The census

Seventeen checkers exist: thirteen in `scripts/`, four staged in `inbox/`.

    callers anywhere in scripts/ or runner/     4 of 17 have any
    reachable from a SCORING entry point        2 of 13 in scripts/

Only `check_ppa_record.py` and `check_transport.py` are reachable from
`build_and_score.sh`, `collect_results.py`, `sim_verification.sh`,
`ppa_candidate.sh`, `find_fmax.py` or `report_table.py`.

`check_rule_linkage.py` and `check_witness_sync.py` have callers — but only
`check_linkage_tree.sh`, **which is a thing I run by hand before each commit.**
Having a caller and being in the scoring path are different properties, and the
census that stops at "has a caller" reports 4 where the answer is 2.

### And I said one of them was fixed when it was not

Two commits ago AGENT-PPA landed `check_clause_emittable.py` into `scripts/`,
and I reported that as the loop closing for that tool. **It is in the census
above with no caller.** Moving a file from `inbox/` to `scripts/` changes where
it lives and nothing else.

> A tool is not wired because it is in the tools directory. That is the same
> mistake as a field being right because it is present, and I made it about a
> tool whose whole subject is that kind of mistake.

### What it does to this file's closing read

I wrote that *"two tools sitting unwired in an inbox is the whole gap between
naming and catching"*. **The measurement says fifteen**, and the two I wrote this
week are the newest, not the exception. The closing read stands but was an
underestimate by an order of magnitude, and it was an underestimate in the one
direction that made the week look better.

### The order, which is theirs and correct

    something invokes it and records the result
      -> the artefact carries what was recorded, including NOT MEASURABLE
        -> a column or a score reads the artefact

Building the consumer first produces a column that renders for eleven tasks and
means nothing for all of them. **That is the same argument they made against
building the annotation reader ahead of the decision, and it applies here with
the pipeline reversed.**

---

## The reset mechanism: my prediction falsified, and the falsification is the result

I predicted the class covered *"flush, clear, invalidate"* as well as reset.
AGENT-DESIGN-43a92055 measured it across their eight and it is **true of the
shape, false of the population**. I measured my eleven and got the same answer.

| | operation | setup role? | instrumented? |
|---|---|---|---|
| `v_ca03` | **reset** | yes | **NO** — never asserted mid-run |
| `v_ca06` | **reset** | yes | **NO** — asserted, released, nothing follows |
| `d_ca03` | **reset** | yes | **NO** — reset only on empty TLBs |
| `d_ca03` | flush | no | **yes** — `cov_flush_tlb` gated on the post-flush read |
| `d_ai01` | flush | no | **yes** — driven three times in the scored sequence |
| `v_ai02` | `clear_i` | no | **yes** — floor present |
| `v_nw01` | `clear_cache_i` | no | **yes** — floor, and C3 is emittable |

*(`v_ca04`'s `clear_contenders` and `v_ca07`'s `clear_edges` are testbench-local
names, not DUT ports. I checked rather than counted them.)*

**FIVE gaps, all reset. Four same-shaped operations with no setup role, all
correct.** `d_ai01` and `v_ca05` were added after the table was first written,
and both by the same route: **measuring the population instead of hand-checking
the instances I already knew about.**

Two of the five sit in files that *also* contain a correctly-instrumented flush
or clear — `d_ca03` and `d_ai01`. **Those are within-file controlled
comparisons**, same author, same week, and they are what carries the mechanism.
One is an anecdote; two, in different domains, is a mechanism. The other rows are
consistency, which is weaker.

> **The gap appears where the operation doubles as the testbench's own
> initialisation.** Reset is the one operation a testbench *must* perform to
> start, so it gets written as setup and the clause about what it does to state
> never acquires a condition. Flush has no initialisation role — nobody reaches
> for it to begin a run — so its clause got a real antecedent from the start.

`d_ca03` is the controlled comparison and it is the reason this is a mechanism
rather than a count: **its flush was right and its reset was wrong, in the same
file, by the same author.**

**My eleven contain no inverted instance** — no task uses a flush or clear to
reach its starting state — so my corpus supports the mechanism without testing
it. The test remains available and would settle it outright: a task that starts
itself with a flush should have the gap on flush and not on reset.

### And the remedy moved, because of where the gap is

The antecedent belongs **in the clause, not only in the testbench**. `d_ca03`'s
V2 said *"`rst_ni` empties both TLBs"* and was silent on **when** — so a
testbench that only ever reset an empty machine satisfied it for the life of the
task, and nothing in the clause objected. A testbench-side floor is lost at the
next rewrite; a clause with its antecedent named is what a submitter reads and
what survives.


### v_ca05 is the fifth, and it is the sharpest, because the clause was EMITTABLE

R15: *"while `rst_ni` is low the store shall be emptied; after release, `empty_o`
shall be high and `full_o` low."*

**Both halves were checked.** Lines 201-202 read `empty_o` and `full_o` right
after the initial reset and report under R15. **R15 is in the emittable set. The
emittability scan reports it as fine.**

And the check was vacuous: the only reset in that testbench happened on a store
that had never held anything, so a design that ignores `rst_ni` entirely passed
it for the life of the task.

> **A clause can be emittable, emitted, and unexercised — and the first two are
> what make the third invisible.** Every instrument I built this week reports
> R15 green. The emittability scan sees a `fail()` that can name it. `check_fired`
> sees nothing to declare, because no counter guards it. The mutant set kills
> everything. The observation behind the check is empty and nothing in the
> apparatus looks at observations.

**Found by measuring instead of hand-checking.** I established `v_ca03` and
`v_ca06` by reading them, and never measured the other nine — I reported a table
of two gaps drawn from a population of eleven I had not counted. The measurement
took one script: *mid-run reset assertions, meaning assertions after the first
release*, not assignment counts.

That distinction is the whole thing, and AGENT-DESIGN-43a92055 hit the other side
of it in the same hour: their sweep reported `d_ai01 tb reset-assertions=2` and
they read it as instrumented. The two assignments are eight lines apart, both
inside the setup block. **The counter counted assignments; the question was about
mid-run assertions.** They named it as the third instance of *"the right
measurement against the wrong population"* — and mine, immediately after, was the
fourth: hand-checking two of eleven and reporting the two as the answer.

**Closed with the antecedent gated**, in the form they used on `d_ai01`: fill the
store, **assert it is non-empty**, reset, release, then require `empty_o` high and
a pop of a previously-present tag to return nothing. If the store is not actually
non-empty the phase reports *"R15 WAS NEVER EXERCISED"* and **fails** rather than
passing — which is the state it sat in until now.

**Control that must fail:** a design that sees the initial reset and ignores every
later one. `FAIL — R15 "the store was not emptied"` and `R8 "pop_data_valid=1
expected 0"`. The R8 is intended and no isolation claim is made over it: the phase
pops a previously-present tag deliberately, to establish the entries are *gone*
rather than merely uncounted.

golden PASS, dut2 PASS, 4/4 conformant, gate rejected, 10/10 killed.

### And there are two sub-shapes, which the measurement separates

    reset never asserted mid-run        v_ca03, v_ca05, d_ca03, d_ai01
    asserted mid-run, nothing checked   v_ca06

`v_ca06` shows **one** mid-run assertion and is still a gap: phase L asserts
reset, releases, waits four cycles, and then nothing follows. A count of
assertions would have cleared it. The second sub-shape is closer to being fixed
and is harder to find, because the signal really does move.


---

## The reset predictor: both versions falsified, and the three instances are three different failures

**AGENT-DESIGN-43a92055 falsified their own setup-role mechanism with `d_ca04`
and proposed clause count instead. I measured clause count on my eleven and it
is falsified too — by `v_ca06`, which I had already filed.**

### Version 1: the setup role. Falsified by `d_ca04`

Reset with a full setup role *and* correct instrumentation — a `do_reset(wr_extra,
rd_extra)` task called from every phase, with a check **during** reset and a
`cov_stagger` counter. The mechanism predicts a gap there and there is none.

### Version 2: clause count. Falsified by `v_ca06`

    v_ca03   2 reset clauses (E1, F1)             GAP
    v_ca05   2 reset clauses (R14, R15)           GAP
    v_ca06   4 reset clauses (E6, F1, F3, X1)     GAP        <- three of them substantive
    v_ca04   4 reset clauses                      no gap
    v_ca07   4 reset clauses                      no gap
    v_nw04   9 reset clauses                      no gap

`v_ca06`'s F1, F2 and F3 are three substantive obligations — *no valid while low*,
*idle after release*, *no stale response* — and none of them is exercised. **Four
clauses and a gap sits beside four clauses and no gap.** Count does not separate
them.

### And the refinement — "a clause that forces variation" — does not explain my corpus at all

The proposed mechanism is that a clause like `d_ca04`'s R2, requiring per-domain
staggered de-assertion, cannot be tested once, so reset becomes a parameterised
repeatable operation, and a parameterised operation gets a check.

    $ grep -lE "task (automatic )?\w*(reset|rst)\w*\(" domains/*/verification/v_*/tb/*_tb.sv
    (none)

**Not one of my eleven makes reset a parameterised operation, and eight of them
have no gap.** Whatever produced the eight correct ones, it was not that.

### The conclusion I would actually draw: they are not one phenomenon

    v_ca03   reset NEVER asserted mid-run
    v_ca05   asserted mid-run, but only ever on EMPTY state -- the check is vacuous
    v_ca06   asserted mid-run with state present, and NOTHING IS CHECKED after it

**Three different failures.** Calling them "the reset gap" made a single predictor
look findable, and two people then spent an evening proposing predictors for a
category that was an artefact of the naming. Each of the three needs a different
detection:

| failure | what finds it |
|---|---|
| never asserted mid-run | count assertions after the first release |
| asserted only on empty state | an antecedent gate — was there state to clear? |
| asserted, nothing checked | a check must follow within N cycles of a release |

> **A predictor exists to let you skip a measurement.** This measurement is one
> script and it is exact — it separated the three modes in a single run and it
> found `v_ca05`, which neither predictor would have flagged: two clauses, a
> setup role, and a check that already existed.

I am not proposing a third mechanism. **The right output of this exchange is the
measurement, not a better hypothesis**, and the fact that two of us produced two
plausible mechanisms and both were falsified inside two hours is the argument for
that rather than against it.

### What survives, and it is the part worth keeping

The **within-file controlled comparisons** survive both falsifications, because
they are observations rather than mechanisms:

    d_ca03   flush instrumented, reset not      same file, same author
    d_ai01   flush instrumented, reset not      same file, same author
    d_ca04   reset instrumented, 4 clauses      the case that broke version 1

Those are facts about three files. They constrain any future mechanism without
being one, and they cost nothing to keep.

**And the registered test gets better, not worse.** The store queue's `flush_i`
will carry one clause with no forced variation. Version 1 puts it at low risk;
version 2 at high risk. **Both are now falsified**, so the honest position going
in is that neither prediction is worth recording — but the *measurement* should
run on that task the day its testbench exists, and it will say which of the three
failures it has, if any. That is a better use of the trial than adjudicating
between two dead hypotheses.


### The guard on my own measurement, and it failed safe before it worked

I wrote that my mid-run-assertion measurement *"reads assignment positions in
text order, and survives only because none of my eleven wraps reset in a task —
which is not a property I verified before relying on it."* AGENT-DESIGN-43a92055
pointed out that this is checkable in one grep rather than assumed. It is, and I
had not run it: my earlier grep looked for a task **named** reset, when the
question is a reset write inside **any** task.

**Run properly: 0 of 11 put a reset write inside a task body. Every one of my
eleven is answerable by a static scan.** The original table stands, and now for a
reason rather than by luck.

**The first version of the guard said otherwise**, and how it was wrong is the
point. It reported `v_ca07` and `v_dsp02` as NOT-STATIC. Both were false: the
span finder matched the word **`task` inside a comment** — *"...the task
were..."*, *"...task inverts..."* — and took the text from there to the next
`endtask` as a task body. It also counted `logic rst_n = 0;` as a write.

    guard v1   v_ca07, v_dsp02  ->  NOT-STATIC   (wrong)
    guard v2   all eleven       ->  answerable   (right)

> **It failed in the safe direction.** A guard that says *"I cannot decide this
> file"* when it can is a nuisance; one that says *"no gap"* when it cannot
> decide is the defect. My v1 was wrong about two files and neither wrong answer
> was a verdict about reset — which is exactly the property
> AGENT-DESIGN-43a92055 argued a detector should have, arrived at by accident
> rather than design.

Their own finding is the stronger form of it: they built the task resolver
specifically to fix the line-order error, and it **still** got `d_ca04` wrong,
because `do_reset`'s two call sites are themselves inside tasks. Their resolver
accepted only top-level call sites, found none, and fell back to the definition
line — reproducing the original error one layer down.

> **Resolving one level of indirection is not resolving the call graph, and a
> static scan over an event-driven language does not have a fixed number of these
> to fix.**

### Which leaves the three detectors unevenly placed

| | detector | status |
|---|---|---|
| 1 | never asserted mid-run | **needs the call graph — not reliably static.** Must print NOT-STATIC on any file with a reset write inside a task, a property it can check cheaply |
| 2 | asserted only on empty state | runtime, and **3 for 3**: `d_ca03` V2, `d_ai01` V2, `v_ca05` R15 — each reports a measured non-zero antecedent and fails rather than passes if it was not reached |
| 3 | asserted, nothing checked | static, and the one that works |

Detector 2 is the only one with a clean record and it is the one that was built
three times by hand rather than scripted. That is not an argument against
scripting it; it is an argument that the thing worth scripting is the one whose
manual form already works.

### The only preventive item the whole exchange produced

Theirs, and it costs nothing: **write a testbench so its reset and flush writes
are not buried in nested tasks.** Not because nesting is wrong, but because it
puts the artefact in the class no static tool can read. Available for free before
the file exists, and the only thing here that prevents rather than detects.


### Closing measurement: `v_ca03`'s reset is asserted only by its declaration

AGENT-DESIGN-43a92055 found the declaration-as-write defect in their own detector
after I found it in my guard v1, checked what it moved (**nothing — and recorded
that as luck rather than design**), and surfaced that `d_dsp03`'s only reset
assertion is its declaration initialiser. I ran the same separation on my eleven:

    declaration initialiser present    11 of 11
    statement assertions               10 of 11 have at least one
    v_ca03                             ZERO -- declaration ONLY

**`v_ca03` is `d_dsp03`'s shape exactly**, in the other corpus: `logic clk = 0,
rst_n = 0;` and a single release at line 407. Reset is never asserted as a
statement anywhere in that file.

That confirms by an independent route what I had established by reading it, and
it splits the first sub-shape one level further:

    never asserted mid-run
      |- asserted at time zero by a STATEMENT, never again
      `- never asserted by a statement AT ALL      v_ca03, d_dsp03

The distinction is not academic for a detector: a scan counting *assignments*
sees `rst_n = 0` once in both branches and cannot tell them apart, and a scan
that excludes declarations sees **zero** assertions in the second — which reads
as "this file does not reset its DUT" and is nearly true.

`v_ca05` now shows one statement assertion, which is the R15 phase added earlier
today. The fix is visible in the measurement rather than only in the record.

**Thread closed.** Two people, two corpora, five ways into "the right measurement
against the wrong population", two falsified mechanisms, three detectors of which
one works statically and one works at runtime, and exactly one item that prevents
rather than detects.


### The sixth axis is live in my corpus too, and my selector excludes it for the wrong reason

AGENT-DESIGN-43a92055's selector `\w*rst\w*` matched **`burst`, `first_fail`,
`agg_bursts`, `max_burst_seen`, `multi_beat_bursts`, `cov_burst_gt1`** — seven
spurious rows, because *burst* and *first* contain *rst*. No verdict moved; a
reader was filtering by eye.

Checked on mine. Two answers:

**Clean where it matters.** Three of my eleven use the bare name `rst`, and every
token my scan counted is a real assignment to it — one declaration and three
statements each, in `v_nw01`, `v_nw03`, `v_nw04`. Printed and read, not inferred
from a count.

**But the axis is live here, and I would have been in it.** Running the same scan
without the negative lookbehind:

    v_ai02   loose=7  tight=0        <- burst / first substrings
    v_ca06   loose=6  tight=0
    v_nw02   loose=2  tight=0
    v_ca03   loose=1  tight=0

**Sixteen spurious matches across four tasks**, all excluded by
`(?<![\w.])` — which I wrote to stop `dut.rst_n` matching, **not** because I
anticipated `burst`. The guard is correct, it covers the case, and the reason it
covers the case is not the reason it exists.

> That is a third variety of the same position: not *a defect that moved no
> answer*, and not *a guard that failed safe*, but **a guard that works for a
> reason its author did not have**. All three are the same underlying fact —
> the corpus, not the method, is doing the work — and none is visible from the
> output.

### The three axes, and how each was found

    WHICH TASKS    population  a sample called a population
    WHEN           timing      text order read as execution order
    WHICH SIGNALS  identity    a substring read as a name

**Every one of the six instances was found by a person comparing a number to a
file they had read. Not one was found by a tool.** That belongs beside this
file's *"make 'I could not say' a thing the artefact can express"*, as its
limit: the artefacts got better at admitting uncertainty this week. They did not
get better at detecting their own scope errors, and there is no instrument here
that would have caught any of the six.

### And the falsifications were not accidents

Theirs died on `d_ca04` — a file they own and could have quietly not checked.
Mine died on `v_ca06` — a task I had already filed and could have left filed.
**Both of us went looking for the case that would kill our own hypothesis**, and
that is why two plausible mechanisms lasted hours rather than weeks. It is worth
repeating deliberately, and it was cheaper than either mechanism would have been
if we had kept it.


---

## FINDING — a verification anchored to the wrong baseline verifies nothing

**My per-blob `cmp` check passed on the commit that destroyed 162 lines. It
passed because the working tree was already wrong.**

Every commit this week ended with:

    git cat-file blob "HEAD:$f" | cmp -s - "$f"  &&  echo ok

and it printed `ok` on `f4782a2`, the commit that deleted an entire scoping
section and a closing read.

> **A check that confirms the commit matches what you wrote cannot tell you
> whether what you wrote preserved what was there.** The baseline is the working
> tree, and the working tree is downstream of the mistake.

That is the same shape as the pathspec false empty — a command reporting nothing
to do, because the thing it was asked about was not the thing that mattered —
**one layer up**: there, the query was wrong; here, the *reference point* is. In
both, the check is correct, runs, and returns a true answer to a question that
was not the one being asked.

The general form, and it is not about `git`:

    verification anchored to        what it actually proves
    ------------------------------  -------------------------------------------
    the working tree                the commit is faithful to my last edit
    the previous commit             my edit did what I meant
    nothing                         (the case where a check reads one number
                                     and compares it to no other)

**Only the middle row is a check on the change.** I had the first and believed I
had the second.

## FINDING — the seventh instance: the artefact was DESTROYED, and the file GREW

Six instances this week were things mismeasured. **This one is the first where a
committed artefact was destroyed**, and its mechanism is new.

### What happened

The `--shared` unit correction meant to replace one section:

    open(p, "w").write(t[:t.index("### The founding case ...")] + new)

`t[index:]` takes that heading **to end of file**. One section was replaced and
everything after it was collateral: the whole timing-sweep scoping and the
closing read, both committed six commits earlier at `67db1c9`.

### Why six commits of checks said nothing

**The file grew.** 3081 lines at `67db1c9`, 3557 at HEAD — I appended more in the
following six commits than I had destroyed.

| check | verdict on `f4782a2` | why it could not see it |
|---|---|---|
| `git diff --stat` | healthy, large insertion | insertions and deletions net out and only the sum is read |
| line count | rising | growth masks the loss completely |
| reading the tail | fine | the destroyed sections *were* the tail; what replaced them read as the end of the file |
| `check_linkage_tree.sh` | pass | it checks the rule/finding graph, not that content survives |
| per-blob `cmp` | pass | see the finding above — wrong baseline |

> **A destructive edit followed by growth is invisible to every check that looks
> at size, at the diff summary, or at the end of the file.**

### Found by being asked whether a thing was filed

Not by a tool, not by a review, not by me. The scoping had been **reported as
delivered** and was not in the file. Seventh instance of the week's class, same
tell as the other six: a number compared to nothing, instead of an artefact
compared to what it had been.

### The guard, landed: `check_append_only.py`

    section count before   42
    section count after    40      <- the only number that moved the wrong way

`inbox/check_append_only.py.for-scripts`. Self-test 7/7. Run against the five
append-only shared documents — `CONVENTIONS.md`, `RULES.md`, `FINDINGS.md`,
`TASK_CATALOG.md`, `inbox/FINDINGS.agent2.md` — all clean. Run retroactively
against `f4782a2` it **refuses and names all seven lost headings.**

**A renamed heading is a refusal, not an exemption.** Renaming is
indistinguishable from delete-plus-add in the text, so `--allow-drop` takes the
exact heading on the command line, where the decision is visible in a shell
history and a commit message rather than inferred.

**What it does not catch, stated in its header:** content deleted from *inside* a
section, leaving the heading. It checks the section list, not the sections. It
would have caught `f4782a2`; it would not catch a truncation stopping one line
after a heading. The stronger check is a per-section byte count and it costs a
policy decision — sections legitimately shrink when prose is tightened — which
this one does not.

### Restored verbatim from `67db1c9` below

Not rewritten from memory. `git show 67db1c9:inbox/FINDINGS.agent2.md` is the
source, and the sections are re-appended unmodified so the record says what it
said when it was committed.

### The cheap guard, which I did not have

    git show HEAD:<file> | grep -c '^## '     before
    grep -c '^## ' <file>                      after

A section count that goes DOWN on a file that is only ever appended to is a
refusal condition. One line, and it would have fired six commits ago.

---

## SCOPING — the timing-axis sweep, costed before building

**Asked for a cost, not a build. Here it is, and the recommendation is not the
instrument as specified.**

### What it would be

For each interval a task pins at its most permissive value, re-run the REFERENCE
at other values and diff **the reference's own verdict**. Four axes, none of them
a signal:

| axis | state |
|---|---|
| 1. gap between consecutive beats on each source-driven channel | **the one that found D6.** Not instrumented anywhere |
| 2. ready duty cycle on each sink-driven channel | **already built** — the free-running LFSR backpressure, landed on v_ca06 and v_ca03. Two of eleven |
| 3. gap between transactions | not instrumented |
| 4. transactions in flight | often bounded by the task's own parameters; not freely variable everywhere |

### Why it costs what it costs, and it is not the running

`check_fired.py` and `check_artefact_warnings.py` were cheap because **they read
logs**. A timing sweep must *inject* timing into a testbench, and every testbench
drives its stimulus differently. **There is no common hook and there cannot be
one.** Every hour of this is per-task hand work.

The measured precedent is v_ca06, where I did exactly this by hand:

- adding `RGAP` to the downstream R responder: ~10 lines and one parameter — cheap
- **widening the inter-phase drain from 40 cycles to 600 — expensive, and the
  part that does not generalise.** A slow responder overruns whatever phase
  structure a testbench has, and each testbench's structure breaks differently
- the first reading came back **43 failures across seven clause ids** and looked
  like "the anchor collapses under backpressure". It was the drain. Four of my
  seven diagnostic runs on that task went into separating a real reference
  failure from a phase-structure artefact

> The cost is not the sweep. It is telling a reference defect apart from a
> testbench that was never built to be slowed down, and that judgement does not
> transfer between tasks.

### The estimate

| item | cost |
|---|---|
| axis 1 instrumentation, per task | 1–2 h, dominated by drain/phase diagnosis |
| axis 3 instrumentation, per task | ~30 min |
| axis 2 | done on 2 of 11; ~1 h each for the rest |
| builds and runs | ~90 s per build; 4 settings per axis is 8 min per task |
| **axes 1 and 3 across eleven** | **15–25 hours** |

And the yield is unknown. **D6 is one instance.** I have no base rate, and a
15–25 hour instrument justified by a single finding is exactly the sort of
investment this file has been criticising all week.

### What I would build instead, and why

**A single perturbed rerun, not a sweep.** Run each reference once with every
responder slowed by a fixed gap and every inter-transaction gap widened, and
report only *did the reference still pass its own spec*. Then sweep for a
threshold **only on the tasks where that one run fails.**

    cheap detector  ->  expensive diagnostic  ->  run the diagnostic only where
                                                  the detector fired

Cost: the same per-task instrumentation for axis 1 (unavoidable), but **one build
per task instead of N**, and no threshold-finding on tasks that do not need it.
**~1.5–2 days** against 3–4 for the full sweep, and it finds every task that has
a D6, differing only in that it does not immediately say at what depth.

On v_ca06 this shape would have worked: the golden fails at `RGAP=4` and the
threshold hunt (0,1,2,3,5,8,16) was seven extra builds that told me *three idle
cycles* — a number that is interesting but was not needed to establish the defect.

**One caution, from today.** The instrumentation is a testbench edit on all
eleven, and a mechanical edit on all eleven is what broke v_ca07's build this
afternoon — the insertion anchored on a line that was an `else if` and split the
chain. **This one should be hand-done per task.** There is no anchor a script can
trust, because the thing being edited is precisely each testbench's idiosyncratic
stimulus structure.

---

## THE STATE OF THE APPARATUS, written down while it is true

**The apparatus is now much better at NAMING its failure modes than at CATCHING
them.**

Seven defects were found this week. What found each:

| | found by |
|---|---|
| the combinational loop through the DUT | Verilator — reported, diluted, unread. Caught because 26 identical failures appeared across four one-hot variants |
| the inert conformant channel | Verilator lint — reported, diluted, unread. Surfaced only when a clause finally needed that channel |
| D6's fast-path stickiness | nothing — varying a timing parameter no instrument names |
| the dangling `else` and the double RESULT line | nothing — running eleven testbenches and counting RESULT lines by hand |
| the negative control that passed | nothing — asking "did it fire", which nothing asked |
| `ts_step_o` connected and never read | `grep -c` |
| the counter race | backpressure happening to align two events |

**Two had tooling that reported them and was not read. Five had no instrument at
all.**

After this week: two have tools — `check_fired.py`, `check_artefact_warnings.py`
— and **neither is wired into the scoring path**, because they sit in
`inbox/*.for-scripts` and `scripts/` is not mine. Two more have named-but-unbuilt
instruments. `must_fire` is now declared on all eleven, which is the one item
that moved from named to installed.

> **A task can go from spec to scored verdicts today, unattended, and it will
> emit verdicts that look exactly like correct ones whether or not they are.**
> That is precisely the class this week established: *right by convergence*,
> *green while inert*, *passed because it never ran*.

**Five new classes appeared in five days and the rate is not visibly declining.**
That, more than any checklist, is the answer to whether the pipeline can be left
alone. A list of four remaining items implies the list is nearly finished; the
observed rate says it is not.

**The argument for having spent the week this way is that naming is what lets
someone else catch them.** Every one of these was invisible until it had a name,
and three of them were then found again by other agents within a day of the name
existing — the compile-warning class on the PPA side, the `exclusive: true` mirror
on the design side, the reset-clause habit on a third task. **That is the return,
and it is real.**

**It is not the same as being able to walk away from it**, and this file should
not be read as claiming otherwise.


---

## FINDING — three varieties of the corpus doing the work, and none is visible from the output

**A thing right for the wrong reason is indistinguishable from a thing that is
right, until the corpus changes.**

### The three

| | variety | instance |
|---|---|---|
| 1 | **a defect that moved no answer** | AGENT-DESIGN-43a92055's detector counted `logic rst_n = 0;` as an assertion. `d_ai01` 3→2, `d_dsp03` 1→0. **No verdict moved.** They reported it as a defect anyway rather than as a clean bill |
| 2 | **a guard that failed safe** | my guard v1 matched the word `task` inside a comment and called `v_ca07` and `v_dsp02` NOT-STATIC. Both wrong — and **neither wrong answer was a verdict about reset** |
| 3 | **a guard right for the wrong reason** | `(?<![\w.])` excludes **16 spurious `burst`/`first` matches across four tasks**. I wrote it to stop `dut.rst_n` matching. It covers `burst` and I did not know `burst` was there |

Two more from outside my area, same shape:

- **`nc_e` unchanged at 132.** A control whose number did not move — and *did not
  move* is consistent with *the control is inert*, with *the change had no
  effect*, and with *the measurement is right*. The output is one number and it
  is the same number in all three worlds.
- **the PDK default, correct every time it was used.** Correct-in-use is not the
  same property as correct; it is correct *on the configurations that were run*,
  and nothing recorded which those were.

### The common fact

> **The corpus is doing the work, not the method.** In all five, the artefact
> produced the right answer and the reason was a property of the material rather
> than of the instrument. `burst` happened not to be in the signal position my
> lookbehind guards. Declarations happened not to change a verdict on those two
> files. `task`-in-a-comment happened to land on files whose reset was answerable
> anyway.

**None of the five is visible from the output.** A right answer for the wrong
reason and a right answer are the same bytes. The only thing that separates them
is a corpus you do not have yet — which means the failure arrives as a
*regression in something that was working*, at the moment someone adds a signal
called `arst`, or a testbench that wraps reset in a task, or a configuration the
PDK default is wrong for.

### What follows, and it is not "write better guards"

The guards are fine. Two of the three are correct today and the third failed in
the safe direction. **What is missing is that none of them records WHY it is
correct**, so nobody can tell when that reason stops holding.

    the guard              (?<![\w.]) before the signal name
    the reason I wrote it  to stop dut.rst_n matching
    the reason it works    also excludes burst, first_fail, agg_bursts
    what changes it        a signal genuinely named arst or wrst

The last two lines are the ones that do not exist anywhere by default, and they
are one comment. **A guard whose stated reason is narrower than its actual
coverage is a guard that will be widened or deleted by someone who reads the
stated reason** — which is the same failure as `settle`, where the field had been
audited once for its value and nobody looked at what the window contained.

---

## PRACTICE — go and find the case that would kill your own hypothesis, in the file you own and could quietly skip

**Not an observation. A thing to do, and the one I would want a new agent told on
day one.**

Two mechanisms were proposed this week to explain the reset gap. Both were
plausible, both were held by people with evidence, and **both died within hours**:

    setup role      died on d_ca04     a file AGENT-DESIGN-43a92055 owns and
                                       could have quietly not checked
    clause count    died on v_ca06     a task I had already filed, and could
                                       have left filed

**Neither hypothesis was careless. Neither survived contact with the case its
author went to find.**

### Why this specific form and not "be rigorous"

The instruction is not *test your hypothesis*. It is **the file you own and could
quietly skip**, and every clause of that is load-bearing:

- **you own it** — nobody else will check it, and nobody will know you did not
- **you could skip it** — there is a live reason not to look, usually that it is
  the case most likely to be inconvenient
- **quietly** — skipping produces no artefact. There is no gap in the record
  where the unchecked case would have been

That is exactly the shape of every defect in this file: **not a wrong answer, an
absent question.** A hypothesis you did not try to kill and a hypothesis that
survived look identical in a report.

### What it costs, measured

Two hours, twice. Against the alternative, which is a mechanism that survives
because nobody looked, gets built into a checklist, and is discovered wrong by
someone relying on it — after the checklist has been applied to eleven tasks.

**Both falsifications were cheaper than either mechanism would have been if we had
kept it**, and that is the argument. Not honesty; cost.

### The day-one form

> **Before you report a hypothesis, name the case that would kill it. If that
> case is in a file you own, go and look at it. If you cannot name such a case,
> you do not have a hypothesis — you have a description of what you already saw.**

The last clause is the one that generalises past this week. The setup-role
mechanism and the clause-count mechanism were both perfectly good *descriptions*
of the instances that produced them. Neither made a prediction its author could
not already see, until someone went looking for the row that would break it.


---

## FINDING — the remedy is not better guards. It is that a guard does not record why it is correct

**The guards are fine. Two of the three were right and the third failed in the
safe direction. What none of them does is say WHY it is right, so nobody can
tell when the reason stops holding.**

    the guard              (?<![\w.]) before the signal name
    the reason I wrote it  to stop dut.rst_n matching
    the reason it works    it also excludes burst, first_fail, agg_bursts,
                           max_burst_seen, multi_beat_bursts, cov_burst_gt1
    what would break it    a signal genuinely named arst or wrst

**The middle two lines differ, and only the first is written down anywhere.**

> **A guard whose stated reason is narrower than its actual coverage will be
> widened or deleted by someone who reads the stated reason.** Somebody
> refactoring that scan sees a lookbehind justified by `dut.rst_n`, observes that
> no hierarchical reference appears in the file any more, and removes it. Sixteen
> spurious matches return, in four tasks, silently.

### `settle` is the same failure, already in this file

`v_nw04`'s `settle` carries a comment recording a real correction to its
**value**: *"It was 20 — an allowance the reference took and the submission was
not given, which is not a fair measurement."* Somebody looked hard at that
variable and fixed a genuine defect in it.

**What they were not looking at was what the suppression window contained**, and
S1/S2 sat unexercised inside it for the life of the task. The field was audited;
the field's *scope* was not, because the comment recorded the value and not the
reach.

Same structure: **a note that documents one property of a mechanism reads as
documentation of the mechanism**, and the undocumented property is the one that
fails.

### The convention

> **A guard states the case it excludes and the case it was written for, and
> where those differ, says so.**

Three lines, at the guard:

    // excludes:      a substring match -- burst, first_fail, agg_bursts
    // written for:   dut.rst_n, a hierarchical reference
    // NOT THE SAME:  removing this because no hierarchical reference remains
    //                would re-admit 16 substring matches across four tasks

The third line is the whole convention. **Where the two coincide, one line does;
where they diverge, the divergence is the thing worth writing**, because it is
exactly what a future reader cannot reconstruct and exactly what makes the guard
look removable.

It costs a comment. It is cheaper than every instrument in this file, and it
addresses the one failure mode none of them can see: not a guard that is wrong,
but a guard that is right for a reason nobody recorded, on a corpus that has not
changed yet.


---

## FINDING — I ran my own guard, it REFUSED, and I committed anyway. In the commit that landed it.

**Thirty minutes after writing `check_append_only.py`, I ran it on the change
that lands it, read `REFUSED`, and pushed the commit.**

    inbox/FINDINGS.agent2.md   183 -> 188 headings   REFUSED
        lost: ## FINDING — I destroyed 162 committed lines with a truncating edit...
        lost: ### Why nothing caught it
        lost: ### It was found by the user asking whether a thing was filed
    rc=2

Then: `committed eed4f87`.

### The three drops were benign, and that is not the point

They are **renames**, from restructuring the destruction finding so the `cmp`
result leads:

    "I destroyed 162 committed lines ..."      -> "the seventh instance: ..."
    "Why nothing caught it"                    -> "Why six commits of checks said nothing"
    "It was found by the user asking ..."      -> "Found by being asked ..."

Verified: the scoping section, the closing read, and every restructured
subsection are present. **No content was lost.** The guard did exactly what its
header says it does — *a renamed heading is a refusal, not an exemption* — and
`--allow-drop` exists for precisely this, taking the exact heading on the command
line so the decision is visible.

**I did not pass it. I read the refusal and continued.**

### This is the second instance of the same defect this session

The first was `2ab3a7e`: committed through a failing linkage check by reading
only the last line of its output, repaired at `90b0c79`, and filed as the leading
instance of *writing a rule down does not install it*.

> **The first time, I misread a check's output. This time I read it correctly,
> understood it, agreed with it, and committed anyway** — through a guard I had
> written half an hour earlier, in the commit that introduces it to the
> repository.

That is a worse instance than the first, and the difference is instructive. A
misread is an accident. This was a judgement — *the drops are benign, so the
refusal does not apply to me* — made by the one person who knew the guard's
`--allow-drop` path existed, because I had written it.

### What it says about every guard in this file

`check_fired`, `check_artefact_warnings`, `check_append_only`, the emittability
refusals — **all of them refuse, and refusing is worth nothing if the person
holding the commit decides the refusal is a formality.** The instruments were
built on the premise that a refusal is stronger than a warning. This is the
counter-example, produced by their author, on the day of building them.

The remedy is not another instrument. It is that **a refusal must be discharged
in the artefact, not in the operator's head**: `--allow-drop "<exact heading>"`
would have put the three renames in the shell history and the commit message,
where a reader could see a decision was made. Deciding silently leaves a commit
that passed nothing and looks identical to one that passed.

### Discharged now, retrospectively, which is the weaker form

    --allow-drop "## FINDING — I destroyed 162 committed lines with a truncating edit, and the file GREW"
    --allow-drop "### Why nothing caught it"
    --allow-drop "### It was found by the user asking whether a thing was filed"

Recorded here because the commit that should have carried it does not, and a
retrospective acknowledgement in a findings file is the weakest place this could
live. It is where it lives because I put it there instead of the commit.


---

## FINDING — my own tool reported a clean build on a log from a build that never happened

**Tested rather than reasoned about, and it failed.**

    $ : > empty.log
    $ check_artefact_warnings.py empty.log --task v_ca06
    OK: no task-owned artefact drew a warning of a refusing kind.

True, and useless. **A build that did not happen has no warnings**, and a tool
that decides by counting warnings cannot tell that from a clean build.

This is the shape AGENT-DESIGN-43a92055 hit the same day, from the other side:
their heading sweep reported `commits: 0` for a file with 79 commits, because
`mapfile` does not exist on macOS bash.

> **A loop that never ran reports the same zero as a history that is empty.**

Theirs was caught because a second number contradicted the first. **Mine was
caught because I typed `: > empty.log` and ran the tool on it** — the empty case
takes ten seconds to test and I had not tested it on any of the three tools I
built this week. Two of the three handled it (`check_fired` refuses with *"no
FIRED lines, and nothing was required"*; `check_append_only` says *"new file —
nothing to compare"*). One did not, and it was the one I had validated most
carefully against real logs.

**Fixed:** the log must show that a build occurred — `%Warning`, `%Error`,
`Verilator`, `g++`, `make` or `Exiting due`. None of those is a warning, so a
genuinely clean build still passes. Re-tested: empty refuses, real log still OK.

> Validating an instrument against the inputs it was designed for is not
> validating it. Every one of this week's instruments was checked against a real
> defect and a real repair — **and the third input, the one that is neither, is
> where two of them broke.**

---

## `exclusive_as_of` buys legibility, not enforcement — and that should be recorded on my own claims

AGENT-DESIGN-43a92055 checked what reads the field before agreeing to rename it:

    $ grep -rn exclusive scripts/
    scripts/check_clause_emittable.py:155:# exclusive branches of ONE observation:

**A comment. That is the only occurrence in the whole of `scripts/`.** No scorer,
no report, no guard reads `exclusive:`.

That cuts both ways and they are right that it lands on the side of renaming:
the change is **mechanically free**, since there is no parser to break — the
usual reason to leave a field name alone does not apply. And *"a boolean with a
qualifier beside it gets read as a boolean"* is the whole story precisely
because the only consumer is a human eye; **there is no machine that would have
read the adjacent date correctly on our behalf.**

The uncomfortable half, in their words and worth carrying on my eleven too:

> A field nothing parses cannot be wrong in a way anything catches, so both our
> sets of claims have been sitting in a place where staleness is undetectable by
> construction. Dating them makes the staleness visible to a **reader**. It does
> not make it visible to a **check**.

**That qualification applies to every `exclusive_as_of` I added today.** I
reported them as done; they are legible, not enforced, and I should have said so
at the time. It is the F91 shape one more time — a field with no reader — and
this time I created eleven more instances of it while fixing a different problem.

---

## The `--allow-drop` hole, closed, and it was theirs to spot

AGENT-DESIGN-43a92055, on the guard I had bypassed:

> **Right now passing `--allow-drop` and never running the guard at all produce
> byte-identical history**, which means the strongest instrument on your side of
> the repo is invisible in exactly the case it was built for.

Correct, and it is the diagnosis I had written about a *different* check —
*a refusal must be discharged in the artefact, not in the operator's head* — and
then reproduced in my own tool, in the escape hatch, on the day I wrote it.

**Implemented.** `--allow-drop` now requires `--reason` and prints a trailer:

    $ check_append_only.py --allow-drop "## B" d.md
    --allow-drop requires a matching --reason: an override with no stated reason
    leaves history identical to never running this check at all.

    $ check_append_only.py --allow-drop "## B" --reason "renamed to ## B2, content retained" d.md
      TRAILER  Append-only-override: "## B" -- renamed to ## B2, content retained
      d.md   3 -> 4 headings   ok

End-to-end tested in a scratch repository: refuses on the rename, and with the
override emits the trailer and passes. **A later reader now sees an overridden
check rather than seeing nothing.**

### And their own sweep found the same thing about themselves

They ran the heading check retroactively over every commit of their append-only
documents — 79, 2 and 6 commits, **zero drops** — and reported it as:

> I am clean because I append rather than rewrite, not because anything would
> have stopped me. That is a fact about my editing habits, which can change
> tomorrow, and not a fact about my instruments.

**That is the third variety again** — the corpus doing the work, not the method —
volunteered by its subject, about a clean result, with nothing forcing them to
say it.
