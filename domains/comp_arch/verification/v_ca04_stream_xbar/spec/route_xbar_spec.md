# `route_xbar` — specification

A fully connected crossbar for a valid/ready stream. Each input carries a
payload and a selector naming the output it is bound for; each output reports
which input its current beat came from. Several inputs may be bound for the
same output at once, and the crossbar decides between them.

Clauses marked **latitude** are choices the implementation is free to make;
your testbench must not require either answer.

---

## 0. Configuration — pinned

| parameter | value |
|---|---|
| `N_IN` | 4 |
| `N_OUT` | 4 |
| `DATA_W` | 32 |
| `SEL_W` | 2 |
| `IDX_W` | 2 |

`rst_ni` is **asynchronous**, **active low**. Per-port fields are packed
low-index first: input `k`'s payload is `in_data_i[k*DATA_W +: DATA_W]`, its
selector is `in_sel_i[k*SEL_W +: SEL_W]`, and output `j`'s source index is
`out_idx_o[j*IDX_W +: IDX_W]`.

## H. The handshake

- **H1.** A beat moves on input `k` in any cycle where `in_valid_i[k]` and
  `in_ready_o[k]` are both high at the rising edge. A beat moves on output `j`
  in any cycle where `out_valid_o[j]` and `out_ready_i[j]` are both high.
- **H2.** This is an obligation on **you**, the source: once `in_valid_i[k]` is
  asserted, `in_valid_i[k]`, `in_data_i[k]` and `in_sel_i[k]` must all be held
  unchanged until that beat has moved. A testbench that withdraws an offer is
  driving something this contract does not describe.
- **H3.** `in_ready_o[k]` **may depend on** `in_valid_i[k]`. It carries no
  meaning in a cycle where input `k` is not offering, and you must not read one
  into it.

## R. Routing

- **R1.** A beat accepted on input `k` while `in_sel_i[k]` is `j` is delivered
  on output `j`, and on no other output.
- **R2.** The payload is delivered **unmodified**.
- **R3.** On the cycle a beat moves on output `j`, `out_idx_o[j]` names the
  input that beat was accepted from.
- **R4.** Every accepted beat is delivered **exactly once**. None is lost and
  none is delivered twice.
- **R5.** Beats accepted from the **same input** and bound for the **same
  output** are delivered in the order they were accepted.

Nothing is promised about the relative order of beats from *different* inputs.

## A. Arbitration

- **A1.** In any cycle at most one input's beat moves on a given output.
- **A2 (the fairness bound).** Let *S* be a set of inputs that are all
  continuously offering beats bound for output `j`. Then **every member of *S*
  is served at least once in every |*S*| consecutive transfers on output `j`.**
  This is a bound, not a promise that each is served eventually.
- **A3.** Once `out_valid_o[j]` is asserted it stays asserted, and
  `out_data_o[j]` and `out_idx_o[j]` stay unchanged, until `out_ready_i[j]` is
  seen. The crossbar may not withdraw or re-aim a beat it has already offered.

## I. Independence

- **I1.** An output that is not ready does not prevent beats moving on any
  other output.
- **I2.** An input whose bound output is not ready does not prevent any other
  input from being accepted. There is **no head-of-line blocking across
  inputs**.

## X. Reset and liveness

- **X1.** `rst_ni` is asynchronous and active low. While it is low the crossbar
  accepts nothing and completes nothing.

  Reset governs what the unit **originates**, not what it merely passes
  through. A purely combinational path from an input to an output is not
  gated by reset, so driving that input while reset is asserted will drive
  the output too. To observe reset behaviour, hold the inputs quiet.
  **This applies from the first rising clock edge onward.** Before any clock
  edge has occurred the design's registers hold no defined value, so its
  outputs are unknown rather than low. Sampling them at time zero, before
  the first edge, tests nothing this contract promises.
- **X2.** After reset is released the crossbar holds no beat and owes no
  delivery.
- **X3 (liveness bound).** A beat offered on input `k` whose bound output is
  continuously ready, and which is competing with at most the other `N_IN-1`
  inputs, is accepted within **32** cycles.

---

## L. Latitude — named, and deliberately unconstrained

- **L1.** The **latency** from a beat being accepted on an input to its
  appearing on an output is unconstrained, subject to X3.
- **L2.** The **starting rotation** of the arbiter after reset — which member
  of a tied set is served first — is unconstrained. A2 fixes the window, not
  the phase.
- **L3.** Whether an output's `valid` and payload are combinational in the
  inputs or come from a register.

These three are the whole of the latitude in this contract.

---

## What this contract does not say

It says nothing about the relative order of beats from different inputs to the
same output beyond A2, and nothing about the order in which distinct outputs
deliver. It places no requirement on `out_data_o[j]` or `out_idx_o[j]` in a
cycle where `out_valid_o[j]` is low.
