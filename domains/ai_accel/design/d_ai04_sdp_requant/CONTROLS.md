# d_ai04 — the negative controls, and what they proved about the testbench

Nine controls, each the reference with **exactly one** defect. Run through
`tb/sdp_requant_tb.sv` unchanged.

| control | the one change | verdict | failures | clauses tripped |
|---|---|---|---|---|
| *(reference)* | — | **PASS** | 0 | — |
| `nc_a_add_offset` | `x + offset` instead of `x - offset` (F3) | FAIL | 476 | F2, F3, F5, sweep-int |
| `nc_b_round_half_up` | `(v + (1<<(t-1))) >>> t` in the signed domain (F4) | FAIL | **10** | F4 |
| `nc_c_narrow_product` | 32-bit intermediate, saturated before the shift (F5) | FAIL | 376 | F5, sweep-int |
| `nc_d_single_register` | one output register, `in_ready` tied high (A3) | FAIL | 101 | **stall (T5)** |
| `nc_e_flush_subnormals` | binary16 subnormals flushed to zero (F7) | FAIL | 51 | F7, sweep-flt |
| `nc_f_propagate_inf` | infinity propagated instead of clamped (F8) | FAIL | **3** | F8, T4 |
| `nc_g_alias_modes` | `cfg_precision` ignored; everything integer (F2) | FAIL | 425 | F7, F8, F9, T4 |
| `nc_h_bypass_in_float` | `cfg_bypass` honoured in float mode (T4) | FAIL | 101 | **T4** |
| `nc_i_stale_config` | configuration applied at emit, not at accept (A5) | FAIL | **23** | **cfgpipe (T6) alone** |

## What the controls found, which is the reason to build them

**`nc_i_stale_config` PASSED the first time, and T6 was the reason.**

As first written, T6 changed the configuration between words and let each word
flow straight through. With a one-deep pipeline the configuration presented at
EMIT was always still the configuration presented at ACCEPT, so a design reading
the live pins at the output was **indistinguishable** from one carrying the
configuration alongside the data. The check ran, reported an exercise count of
24, and tested nothing.

That is rule 36's case exactly, and no amount of the reference passing would have
shown it. The control is what showed it.

T6 now stalls the consumer, fills the buffer with two words under **different**
configurations, and then moves the configuration to a **third** value — one
belonging to neither buffered word — before releasing the stall. Every buffered
word is emitted while a configuration that is not its own sits on the pins.
`nc_i` now fails on `cfgpipe` and on nothing else.

## Reading the localisation column

A control that fails **nothing** means the clause is not checked. A control that
fails **everything** means the testbench cannot localise the defect. Both are
findings about the testbench rather than about the control.

Four are tight enough to name a single clause — `nc_f` at 3 failures, `nc_b` at
10, `nc_i` at 23, `nc_h` on T4 and float sweep words only. `nc_a` and `nc_g` are
broad, and legitimately so: `cfg_offset` participates in every integer vector and
`cfg_precision` selects the whole float half, so a defect in either cannot be
local. `nc_c` fails 376 words but **no F3 and no F4 vector**, which is the
evidence that the wide-intermediate clause is separable from the arithmetic
around it.

`nc_d` is the one that matters most for the task's premise. It satisfies **A2**
— `in_ready` is constant, so there is trivially no combinational path from
`out_ready` — and fails **A3**, losing a word when the consumer stalls in the
cycle a second word arrives. On open flow it is byte-identical to the reference.
That is the "invisible on the delivered surface" claim from the step-0 audit,
now demonstrated rather than asserted.
