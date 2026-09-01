# d_ca06 — concurrent multi-port queue

Implement `queue` in synthesisable SystemVerilog.

A FIFO with three write ports and three read ports that may all be active in the
same cycle. Ordering is global: entries leave in the order they entered,
regardless of which port carried them.

Five things about this contract are worth reading before choosing an
architecture:

* **The G clauses set out how you are graded**, in what order, and which
  optimisation levers are already closed. Read them first.
* **Reads do not compact, and the skipped entry is destroyed.** `head` advances
  to one past the *highest-numbered* accepted read, not by the number of reads.
  With `[11,22,33,44]` and `read_accept = 3'b101`, head moves by **three** and
  the entry `22` is discarded having never been read. A non-prefix accept is
  legal, loses data silently, and is not flagged. The obvious design — one that
  compacts reads and loses nothing — is wrong here.
* **Writes do compact.** Accepted writes land in consecutive slots from `tail`
  with no gap for an idle port. Writes compacting while reads do not is the
  asymmetry the task is built on; a design that treats the two directions alike
  fails whichever one it gets wrong.
* **Write acceptance does not depend on `write_valid`.** It is a function of
  space alone: `write_accept[i] = (i < vacancy)`. With the queue empty and
  nothing offered on any port, `write_accept` is all ones. Note the consequence
  — port *i* needs *i+1* free slots even when every lower port is idle.
* **Full and empty are the same pointer state.** `PTR_WIDTH` fixes the pointer
  width and `DEPTH` is `1 << PTR_WIDTH`, so the array is exactly full at wrap
  and you may not tell the two apart by widening the pointers and comparing wrap
  bits. How you carry the distinction is otherwise yours.

Everything asserted below about acceptance, compaction, discard and the fullness
flag was **measured** against the reference rather than assumed from convention.
The two clauses that contradict the usual design are marked where they appear.

**One self-contained file** containing only `module queue`, with the exact
parameter list and port list below. Declare nothing else outside the module.

`T` is **derived** from `DW` and must stay that way — the build sets the scored
width through `DW`, and a design that declares `T` as a free type parameter
cannot be pinned by the flow.

The contract cites a few repository file names in passing; those are provenance
notes for maintainers, not documents you need.

```systemverilog
// =============================================================================
// d_ca06 -- CONCURRENT MULTI-PORT QUEUE
//
// A FIFO with PORTS write ports and PORTS read ports that may all be active in
// the same cycle. Ordering is global: entries leave in the order they entered,
// regardless of which port carried them.
//
// EVERY CLAUSE BELOW WAS MEASURED against the reference, not inferred from what
// a multi-port queue usually does. Two of them contradict the usual design and
// are marked where they appear.
// =============================================================================

// -----------------------------------------------------------------------------
// V -- PORTS, exactly
// -----------------------------------------------------------------------------
// V1. The module is named `queue` and takes these parameters:
//
//       parameter int  DW        = 64            entry width in bits
//       parameter type T         = logic[DW-1:0] entry type, DERIVED from DW
//       parameter int  PTR_WIDTH = 7             DEPTH = 1 << PTR_WIDTH
//       parameter int  PORTS     = 3             write ports AND read ports
//
//     T IS DERIVED, NOT INDEPENDENT. A submission must keep it that way: the
//     build sets the scored width through DW, and a design that declares T as a
//     free type parameter cannot be pinned by the flow.
//
//     A submission may declare additional derived parameters. It may not add a
//     parameter that changes behaviour, and it may not rename these three.
//
// V2. Ports, exactly:
//
//       input  logic             clk
//       input  logic             rst_n
//       input  T     [PORTS-1:0] write_data
//       input  logic [PORTS-1:0] write_valid
//       output logic [PORTS-1:0] write_accept
//       output T     [PORTS-1:0] read_data
//       output logic [PORTS-1:0] read_valid
//       input  logic [PORTS-1:0] read_accept
//
// V3. RESET IS SYNCHRONOUS and active low. rst_n low at a rising clk edge
//     clears head, tail and the fullness flag, and zeroes every storage entry.
//     There is no asynchronous reset path.

// -----------------------------------------------------------------------------
// F -- FUNCTION
// -----------------------------------------------------------------------------
// F1. OCCUPANCY. The queue holds `occupancy` entries, 0 <= occupancy <= DEPTH.
//     head indexes the oldest entry; tail indexes the next free slot.
//
// F2. FULL AND EMPTY ARE THE SAME POINTER STATE and are told apart by the last
//     operation, not by a spare bit of pointer.
//
//       tail != head          occupancy = tail - head, modulo DEPTH
//       tail == head          occupancy = DEPTH if the last cycle that changed
//                             occupancy wrote more than it read, else 0
//
//     A submission may carry that distinction however it likes. It may NOT
//     resolve it by widening the pointers by one bit and comparing wrap bits,
//     because that changes the port list: PTR_WIDTH fixes the pointer width and
//     DEPTH is 1 << PTR_WIDTH, so the array is exactly full at wrap.
//
// F3. WRITE ACCEPTANCE IS A FUNCTION OF SPACE ALONE.
//
//       write_accept[i] = (i < vacancy)        vacancy = DEPTH - occupancy
//
//     NOT USUAL, AND MEASURED: write_accept does NOT depend on write_valid. A
//     port advertises acceptance whenever the queue could take an i-th entry
//     this cycle, whether or not anything is offered on any port. With the
//     queue empty and nothing offered, write_accept is all ones.
//
//     Note the consequence: port i requires i+1 free slots even if ports below
//     it are idle. One free slot accepts on port 0 only.
//
// F4. WRITES COMPACT. Accepted writes are stored in ascending port order into
//     consecutive slots starting at tail, with no gap for a port that did not
//     assert write_valid.
//
//       write_valid = 3'b101, queue empty
//         -> port 0's data at tail, port 2's data at tail+1, tail advances by 2
//
//     A port that is valid and accepted is always stored. Its POSITION depends
//     on how many lower-numbered ports were also stored this cycle.
//
// F5. READ VALIDITY.
//
//       read_valid[i] = (i < occupancy)
//       read_data[i]  = the entry i positions after head
//
//     read_data[i] is combinational from storage and is valid to sample only
//     when read_valid[i] is high. read_data for a port whose read_valid is low
//     is unconstrained and is not checked.
//
// F6. READS DO NOT COMPACT -- THE SKIPPED ENTRY IS DISCARDED. This is the
//     clause that separates this design from the obvious one, and it is
//     measured rather than argued.
//
//     head advances to one past the HIGHEST-numbered port that both asserted
//     read_accept and had read_valid set. It does not advance by the count of
//     accepted reads.
//
//       occupancy 4, entries [11,22,33,44], read_accept = 3'b101
//         -> head advances by THREE
//         -> 11 and 33 were read, 22 WAS NEVER READ AND IS GONE
//         -> the queue now holds [44]
//
//     So read_accept must be a PREFIX -- 3'b000, 3'b001, 3'b011, 3'b111 -- for
//     every entry to be observed. A non-prefix accept is legal, silently loses
//     the skipped entries, and the reference does not flag it. A submission
//     must reproduce that loss exactly; a design that compacts reads instead,
//     or that ignores a non-prefix accept, is wrong on this surface.
//
// F7. THE FULLNESS FLAG UPDATES ONLY WHEN THE COUNTS DIFFER. Writing and
//     reading the same number of entries in one cycle leaves the flag as it
//     was, which is what keeps a full queue full across a balanced cycle and an
//     empty queue empty.

// -----------------------------------------------------------------------------
// A -- TIMING
// -----------------------------------------------------------------------------
// A1. All state settles on the rising edge of clk. write_accept, read_valid and
//     read_data are combinational functions of the state as it stands BEFORE
//     that edge -- they reflect the queue's contents at the start of the cycle,
//     not the contents after the cycle's own writes.
//
// A2. A write and a read of the same entry in one cycle are ordered
//     read-before-write. An entry written this cycle is not readable until the
//     next.
//
// A3. THROUGHPUT IS PINNED. Up to PORTS entries in and PORTS entries out per
//     cycle, with no recovery cycle after any combination. There is no
//     handshake stall the design may introduce of its own.

// -----------------------------------------------------------------------------
// P -- PINNED, AND WHAT IS FREE
// -----------------------------------------------------------------------------
// P1. NOT DESIGN CHOICES: the port list (V2), the acceptance rule (F3), the
//     write compaction order (F4), the head-advance rule (F6), and synchronous
//     reset (V3). These are the observable contract.
//
// P2. THE STORAGE GEOMETRY IS PINNED BY PARAMETER. DEPTH is 1 << PTR_WIDTH
//     entries of T, all of them registers. A submission may not add a second
//     storage level, spill registers, or an output buffer: those change
//     occupancy as observed at the ports, which F1 and F5 pin.
//
// P3. FREE, AND IT MOVES PPA. How the read multiplexers are built -- one mux
//     per port across the whole array, a shared rotator, or a barrel shifter on
//     head; how the pointer arithmetic is shared between the accept and valid
//     comparators; whether the fullness flag is one bit or is recomputed; and
//     how the write address chain is formed. These are CHOICE metrics in G5's
//     sense: a submission choosing differently from the reference is disclosed,
//     not penalised.

// -----------------------------------------------------------------------------
// T -- WHAT IS CHECKED
// -----------------------------------------------------------------------------
// T1. THE SCORED SURFACE, bit-exact against the reference every cycle:
//       write_accept, read_valid, and read_data on ports where read_valid is high.
// T2. Random traffic at every legal combination of write_valid and read_accept,
//     including non-prefix accepts (F6) and all-ports-active cycles.
// T3. The empty and full boundaries, entered and left in both directions,
//     including the balanced cycle of F7.
// T4. Wrap: pointers crossing DEPTH while the queue stays partly occupied.
// T5. Reset asserted mid-traffic, and the queue's behaviour on the cycles after.

// -----------------------------------------------------------------------------
// G -- HOW THIS IS GRADED
// -----------------------------------------------------------------------------
// G1. THE ORDER, and correctness is a GATE rather than a weighting.
//     1. CORRECTNESS. Bit-exact on the T1 surface against the reference across
//        every scored configuration. There is no partial credit and no
//        tolerance.
//     2. THE GATE. A submission that fails correctness, OR THAT FAILS TO BUILD,
//        produces NO PPA NUMBER AT ALL, recorded as a failure rather than as a
//        large area.
//     3. PPA, measured only for submissions that passed, ONCE AT A PINNED
//        CLOCK.
//
//        THE PINNED PERIOD IS 7.0 ns on sky130hd. It is derived as 1.5x the
//        reference implementation's own measured period (4.5312 ns,
//        220.69 MHz), rounded up to the next 0.25 ns:
//
//            ceil(1.5 x 4.5312 / 0.25) x 0.25  =  28 x 0.25  =  7.0 ns
//
//        ONE SWEEP, ON ONE MACHINE, WITH A CONFIRMING RE-RUN. Eight
//        place-and-route runs over four bisection steps, bracketed by a pass at
//        4.5312 ns against a fail at 4.375 ns; DRC 0 at every iteration. The
//        eighth run repeated 4.5312 ns, passed, and did not fall back. The
//        correctness gate was FULL 6/6 at the scored configurations.
//
//        ON THE SLACK AT THE CONVERGED POINT, because it is a zero and zeroes
//        here are not all alike. The converged run reports WNS 0.00 ns. That
//        figure is recovered from `6_finish.rpt`, which prints two decimals, so
//        it does not mean the slack was exactly zero -- it means the slack fell
//        in a half-open interval. Which interval depends on the SIGN, and the
//        sign was checked rather than read past: it is a POSITIVE zero, so the
//        true slack lies in [0, +0.005) ns and the period is met. A true slack
//        in (-0.005, 0) prints "-0.00", parses to negative zero, and compares
//        as >= 0 in Python -- the corpus carries one converged point that is
//        exactly that (d_ca03), and `find_fmax` now rejects negative zero.
//        See FINDINGS.md F124. The margin is thin, which is an argument for
//        the 1.5x derating rule doing its job, not against the pin.
//
// G2. WHAT IS COMPARED: area post-synthesis and post-place-and-route, and power
//     at the pinned period.
//
//     TIMING CLOSURE IS A GATE, NOT AN AXIS, AND SLACK IS NOT SCORED. A build
//     that misses the pinned period yields no comparable area or power figure --
//     slack is bought with area, so a design that missed and one that closed are
//     not describing the same circuit.
//
//     THERE IS NO CAPABILITY AXIS. A3 pins throughput at PORTS entries per
//     cycle each way, and P2 pins the storage geometry, so there is no quantity
//     where more is better and area buys it. Raw area is compared directly,
//     and it is like-for-like because the only free things are structural.
//
// G3. WHAT IS NOT AVAILABLE TO OPTIMISE.
//       * THE ACCEPTANCE RULE. F3 pins write_accept to a function of vacancy
//         alone. Making it depend on write_valid would accept more traffic and
//         is a specification violation, not an improvement.
//       * THE READ SEMANTICS. F6 pins the discard. A design that compacts reads
//         loses no data and is WRONG.
//       * THE STORAGE. P2 pins DEPTH entries of registers. Inferring a RAM
//         macro changes the read timing that F5 and A1 pin.
//
// G4. WHAT IS ACTUALLY LEFT. The read multiplexer structure and the pointer
//     arithmetic:
//       * PORTS independent DEPTH:1 muxes, or one rotator shared across ports.
//         Both conform and they are not the same area.
//       * The accept and valid comparators both compare a port index against a
//         count. Sharing that silicon or building it twice are both conforming.
//       * The write address chain is a prefix sum over PORTS bits. Ripple,
//         lookahead, and a decoded form all conform.
//
// G5. THERE IS NO SINGLE COMBINED SCORE, and that is deliberate rather than
//     unfinished. Nothing in this project establishes what a unit of capability
//     is worth in square micrometres, so no weighted sum is computed. Each axis
//     is reported separately, and a submission that wins on one and loses on
//     another is reported as exactly that.

// =============================================================================

module queue #(
    parameter int  DW        = 64,
    parameter type T         = logic [DW-1:0],
    parameter int  PTR_WIDTH = 7,
    parameter int  PORTS     = 3
) (
    input  logic             clk,
    input  logic             rst_n,

    input  T     [PORTS-1:0] write_data,
    input  logic [PORTS-1:0] write_valid,
    output logic [PORTS-1:0] write_accept,

    output T     [PORTS-1:0] read_data,
    output logic [PORTS-1:0] read_valid,
    input  logic [PORTS-1:0] read_accept
);

    // IMPLEMENTATION INTENTIONALLY OMITTED.

endmodule
```
