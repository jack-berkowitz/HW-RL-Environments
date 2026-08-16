# d_dsp02 conformant perturbations — must PASS, not be killed

**I previously concluded this set was empty. That was wrong** — I had not
enumerated the spec, I had listed the candidates that came to mind. The
enumeration below is the correction, and it found a viable perturbation.

## The set

| id | perturbation | licence | witness | checker |
|---|---|---|---|---|
| `cRESBUS` | result and flag buses carry LFSR garbage whenever `out_valid` is low | **H3 scope** — H3 pins stability only when `out_valid` is HIGH; the spec says nothing about the buses when it is low | `result c03448d2 vs 00000000` @ t=46000, `out_valid=0` | **1/1 PASS** |

Direct analogue of `v_ca05`'s `c2`. It survives the pinning of latency because
its licence is H3's *scope*, not the latency clause.

**Confirmed conformant, not merely different:** whenever `out_valid` is high the
two designs produce identical results, and `out_valid` itself never differs. It
diverges only where the contract is silent.

## Full enumeration — every behaviour the spec touches

An empty conformant set is only evidence of a complete spec if you can show
every behaviour is either pinned or perturbed. Here it is not empty, but the
enumeration is what establishes that.

| behaviour | clause | status |
|---|---|---|
| single rounding, no double-round | A1 | pinned |
| five rounding modes | A2 | pinned |
| subnormals in-pipeline | A3 | pinned |
| canonical NaN payload | A4 | pinned |
| underflow/overflow semantics | A4b | pinned |
| signed zero | A5 | pinned |
| tininess after rounding | A6 | pinned |
| inexact on subnormal | A7 | pinned |
| initiation interval | C3 | pinned |
| **pipeline depth** | **S1** | **pinned (rule 18)** — was open, was `cPIPE3`'s licence |
| register placement within the 3 stages | S1a | **open, PPA-observable only** — not usable as a simulation control |
| `in_ready` combinational dependence | H1 | pinned |
| producer holds valid/operands | H2 | pinned |
| output stability while `out_valid` high | H3 | pinned |
| result ordering | H4 | pinned |
| reset polarity and synchronicity | R1 | pinned |
| `out_valid` during reset | R2 | pinned |
| in-flight work at reset (flush vs drain) | R3 | **pinned** — "reset discards work in flight" |
| **result/flag buses while `out_valid` low** | **none** | **OPEN → `cRESBUS`** |
| acceptance under sustained backpressure | C3, partially | **not perturbed** — see below |

Two rows deserve the detail:

**Reset mid-flight is pinned, and a depth-3 pipeline makes that a live question.**
R3 settles it explicitly: work in flight is discarded. Had R3 been silent,
flush-versus-drain would have been a strong conformant candidate.

**Backpressure acceptance is deliberately not perturbed.** Varying how long the
design keeps accepting while the output is stalled is simulation-observable, but
I could not establish it is conformant rather than a C3 violation. **Shipping a
violation labelled conformant would break the set's premise**, since a failure
here is supposed to indict the spec — a mislabelled member would indict it for a
real defect. Left as a known gap rather than a guess.

## What `cPIPE3` became

Retired and deleted. Its licence clause — *"latency is not constrained"* — no
longer exists, and at depth 3 it **is** the reference, so keeping it would have
shipped a perturbation identical to the design it perturbs: the purest form of
the no-op control this project keeps finding (F25).

## A bug this set caught in itself

The first `cRESBUS` **failed the checker**, which would have read as a checker
defect — the checker sampling `result` while `out_valid` is low. It was my
wiring: `inner_result` was left implicitly declared and became a **1-bit wire**,
silently truncating the 32-bit result. The design elaborated and ran; it just
returned garbage.

Caught by neutralising the perturbation and finding the file failed anyway. That
control costs one run and is the difference between reporting a checker defect
and finding your own. The first version also used an asynchronous reset, which
would have made it a violation of R1 rather than a conformant variant.
