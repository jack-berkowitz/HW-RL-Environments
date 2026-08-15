# Recognition probe — result

**Decontamination did not work for this anchor. Recognition was complete.**

Sample: one model, both probes, answers pasted verbatim. **Not labelled by model,
so this is a single observation, not a rate.**

## Scores

| | Probe A (shipped) | Probe B (original) |
|---|---|---|
| **Q2 project + file** | `pulp-platform/common_cells`, `src/id_queue.sv` — **correct** | correct |
| **Q3 original module name** | **`id_queue` — correct** | correct |
| stated confidence | **>99 %** | ~100 % |

**A-versus-B delta: approximately zero.** The primary number — A-Q3, pure recall,
since the name appears nowhere in the shipped file — is **a hit**.

## The reasoning rules out the notice confound

Q4 existed to separate *reading the corpus notice* from *recall*. The answer
cites neither the notice nor any shipped text. Every piece of evidence it gives
is structural, and it **reconstructed the upstream identifier set from that
structure**:

| the model produced | occurrences in the shipped file |
|---|---|
| `HtCapacity = min(2**ID_WIDTH, CAPACITY)` | **0** |
| `head_tail_t` (id, head, tail, free) | **0** |
| `linked_data_t` (data, next, free) | **0** |
| `ID_WIDTH`, `CAPACITY` | **0** |
| `inp_*`, `oup_*`, `exists_*` port prefixes | **0** |
| `id_queue` | **0** |

It also gave the complete rename mapping in the correct direction
(`TAG_W → ID_WIDTH`, `push_* → inp_*`, `match_* → exists_*`, …), identified the
`FULL_BW` simultaneous pop/push reuse path as "nearly dispositive", and dated
upstream repository changes it claims occurred after this file's revision.

**Renaming and comment-stripping did not reduce recognition at all.** The
structure is the fingerprint, and the structure is what the task requires us to
ship.

## Caveat that must be resolved before generalising

**It is not established whether the model had web search enabled.** The answer
cites specific upstream commit dates, which is either detailed pretraining
knowledge or a live lookup. The distinction matters a great deal:

- **Pretraining recall** is mitigated by choosing less-reproduced anchors.
- **Live retrieval is not mitigated by obscurity at all** — any public code is
  findable, and no anchor choice helps.

If the second, the problem is strictly worse than this result already suggests,
and it applies to the design half too, where a model could look up the reference
implementation rather than solve the spec.

## What this does and does not establish

**Establishes:** for `id_queue`, licence-bounded decontamination provides no
protection. One capable model identified the project, the file and the original
module name from structure alone, with >99 % stated confidence.

**Does not establish:** a rate across models, or that every anchor behaves this
way. `id_queue` is a small, distinctive, widely-vendored module. A larger or more
generic DUT may be less identifiable — that is now a question to measure per
anchor rather than assume either way.

## Recommendation

1. **Run the probe per anchor**, not once for the corpus. It is cheap — two
   pastes — and the result clearly varies with how distinctive the module is.
2. **Resolve the web-search question first.** It changes what the number means
   and whether anchor selection can help at all.
3. **Report the recognition rate as a published property of the benchmark.** A
   benchmark that measures and reports its own contamination is more credible
   than one that claims none, and after this result claiming none is not
   available.
4. **Do not treat verification-task scores as pure capability measurements**
   until this is understood. A model that recognises the DUT can recall its
   upstream testbench, which is precisely the deliverable being scored.
