# ca_d08 `tiny_core` — provenance

## Oracle class: **B — local model of record**

Per `DESIGN_CATALOG.md` § Oracle classes. **No external RTL oracle runs for
this task, and none is claimed.** The statement "the testbench passes
known-correct external RTL" is *not available here* and appears nowhere in this
task's artifacts.

The substitute guarantee is the three things the catalog requires:

1. **The model is derived from the documented ISA, not transcribed from an
   implementation.** `ref/model/rv32i_iss.py` implements the RV32I base integer
   instruction set from the published RISC-V unprivileged specification — the
   instruction formats and the defined behaviour of each opcode. It was not
   transcribed from SERV, darkriscv, picorv32, Spike, or any other source.
2. **The model, its generator, and the traces are committed**, so the oracle is
   reproducible and auditable. Regenerate with
   `python3 ref/model/rv32i_iss.py --emit tb/vectors`, and check it against its
   own property suite with `--selftest`.
3. **Mutation testing carries the sharpness argument alone.** See `NOTES.md`.

## What each file is

| file | role | authority |
|---|---|---|
| `model/rv32i_iss.py` | ISS + program generator + trace emitter | **ORACLE OF RECORD** |
| `../tb/vectors/prog*.hex` | committed programs | derived from the generator |
| `../tb/vectors/trace*.hex` | committed retire traces | derived from the ISS |
| `tiny_core_ref.sv` | locally-authored RTL | **NO authority** — see below |

### `tiny_core_ref.sv` is not upstream RTL and not a port shim

Class B tasks have no shim; there is no upstream module to bridge. This file
exists so that (a) a checker PASS proves the harness runs rather than merely
compiles, and (b) the mutants have a base to be derived from.

Where this file and the Python ISS disagree, **the ISS is right by definition
and the RTL is broken.** That is not hypothetical: the first full run caught a
real `sra` bug in this file, where SystemVerilog signedness propagation had
silently demoted an arithmetic shift to a logical one. The ISS was right.

## Cross-check performed (never authoritative)

| repo | SHA | licence | mode |
|---|---|---|---|
| `darklife/darkriscv` | `4aa437997cd35253c9111f10a449de13ccaeee78` | BSD | `cross_check_only` |
| `olofk/serv` | `41e8aeedfd1e9ad5f95902c5b0dfc83d1c99e5d2` | ISC | `cross_check_only` |

Both are pinned in `refs.lock`, cloned to the external scratch directory, and
**never vendored**. Neither defines an expected value.

**What was checked, and it passed:** every instruction encoding this project
generates was compared against darkriscv's independently-written decoder.

* All **9 opcodes** match bit-for-bit (`LUI` `0110111`, `AUIPC` `0010111`,
  `JAL` `1101111`, `JALR` `1100111`, branch `1100011`, load `0000011`,
  store `0100011`, imm-ALU `0010011`, reg-ALU `0110011`).
* All three **scrambled immediate formats** match bit-for-bit — S-type, and
  critically the B-type and J-type field permutations, which are the easiest
  thing in RV32I to get subtly wrong. darkriscv assembles the B-type immediate
  as `{instr[31], instr[7], instr[30:25], instr[11:8], 0}` and this ISS builds
  exactly the same field order, as does J-type.
* Encode→decode round-trips exactly at the offset boundaries (±4096 for B-type,
  ±1048576 for J-type).

**What was NOT checked, stated plainly:** no co-simulation was run. darkriscv
and SERV were not executed against these programs, so their agreement on
*execution semantics* — ALU results, `x0` hardwiring, the `jalr` LSB clear — is
not established. Standing up either core needs a bus wrapper (darkriscv) or the
servant SoC (SERV, which is additionally bit-serial and has no cleanly
observable retire point), and `DESIGN_CATALOG.md` is explicit that neither is a
usable structural template.

The encoding cross-check is therefore real but partial: it rules out a whole
class of silent error — programs that do not mean what they are named — while
leaving execution semantics resting on the ISS self-test and the specification.

## Second source

`ca_d08` is on the **mandatory second-source list**.
`tb/tiny_core_alt_ref.sv` is a multi-cycle FSM implementation, deliberately
retiring every 3–4 cycles against the reference's every-cycle cadence. **It is a
falsifier, not an oracle** — its only job is to fail, and if it does, the
checker is over-constrained. It passes; see `NOTES.md`.
