Write a parameterized Tcl script (synth_and_time.tcl) for a single-module
synthesis + static timing analysis flow, using Yosys and OpenSTA. Also write
one hand-crafted candidate implementation by hand (not scaffolded/templated)
for the FIFO module specifically, to serve as the first real test case for
this script before it's pointed at anything else.

REPO LAYOUT (already exists):
  ~/projects/HW-RL-Environments/interfaces/<module>_iface.sv   (port-only stubs)
  ~/projects/HW-RL-Environments/testbenches/<module>_tb.sv     (SV testbenches)
  ~/projects/HW-RL-Environments/candidates/<module>.sv          (create this dir —
      this is where a module implementation gets dropped in for the build
      script to actually synthesize; the _iface.sv files are just the spec,
      not something to synthesize directly)

PART 1 — HAND-WRITTEN CANDIDATE (candidates/fifo.sv):
  - Read interfaces/fifo_iface.sv for the exact port list and parameters —
    do not invent a different interface.
  - Implement a correct, straightforward synchronous FIFO matching that
    interface: standard read/write pointers, full/empty flags, the
    almost-full/almost-empty threshold parameters from the iface file.
  - This should be a real, working, non-trivial implementation — not a stub
    — since the whole point is to have something with actual internal
    structure (registers, comparators, pointer logic) to synthesize and time,
    not something so simple it doesn't exercise the flow meaningfully.
  - Before anything else, run it against testbenches/fifo_tb.sv (Verilator or
    Icarus, whichever is set up) and confirm it passes — a candidate that
    fails its own testbench is not a valid test case for the build script,
    since a script that "succeeds" against broken RTL doesn't prove anything.

PART 2 — THE BUILD SCRIPT (synth_and_time.tcl):

TOOL LOCATIONS (already built and verified working):
  Yosys       — on PATH via oss-cad-suite (sourced from ~/tools/oss-cad-suite/environment)
  OpenSTA     — ~/tools/OpenSTA/build/sta
  sky130 lib  — ~/tools/OpenROAD-flow-scripts/flow/platforms/sky130hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib

CRITICAL SYNTAX NOTE, confirmed by hand already:
  Yosys run via `yosys -c script.tcl` uses REAL Tcl interpreter mode — every
  single Yosys command must be prefixed with `yosys`, e.g. `yosys read_verilog`,
  `yosys synth -top ...`, NOT bare `read_verilog`. Bare commands fail with
  "invalid command name" errors. Use this prefixed form throughout, since we
  need real Tcl control flow (variables/args) for parameterization, not the
  simpler unprefixed .ys script format.

SCOPE: process exactly ONE module per invocation — do not batch across
modules. The script takes the module name as a command-line argument and
derives all paths from the repo layout above.

Usage should look like:
  yosys -c synth_and_time.tcl -- fifo 5.0
  (module name, target clock period in ns)

The script should:

1. SYNTHESIS (Yosys, Tcl-mode, `yosys`-prefixed commands):
   - yosys read_verilog -sv candidates/<module>.sv
   - yosys synth -top <module>
   - yosys dfflibmap -liberty <sky130 lib path above>
   - yosys abc -liberty <sky130 lib path above>
   - yosys write_verilog candidates/<module>_synth.v
   - yosys stat  (capture this output — need real cell names like
     sky130_fd_sc_hd__and2_1 as confirmation the Liberty mapping worked,
     not just that Yosys ran without erroring)

2. STATIC TIMING ANALYSIS (OpenSTA, separate script or same invocation):
   - read_liberty <sky130 lib path above>
   - read_verilog candidates/<module>_synth.v
   - link_design <module>
   - create_clock -name clk -period <target period arg> [get_ports clk]
   - set_input_delay 0.5 -clock clk [remove_from_list [all_inputs] [get_ports clk]]
     (NOTE: must exclude the clock port itself here — applying input delay
     to the clock port relative to itself throws Warning 441, confirmed by
     hand already)
   - set_output_delay 0.5 -clock clk [all_outputs]
   - report_checks
   - report_wns  (worst negative slack, as a single parseable number)
   - report_tns  (total negative slack)

3. Emit ONE structured JSON result line containing: module name, target
   clock period, WNS, TNS, cell count (from synthesis stat), pass/fail on
   timing closure (WNS >= 0), and a note that this is SYNTHESIS-STAGE
   timing (wireload-model-based), not post-route — do not let this get
   reported or logged as if it were signoff-quality.

Requirements:
   - Fail loudly and exit non-zero if candidates/<module>.sv doesn't exist,
     if synthesis produces zero cells, or if the Liberty file path doesn't
     resolve — don't silently emit a garbage report.
   - Before trusting this on fifo.sv, run it against
     sandbox/trivial_test/trivial_test.sv (already verified working by hand
     — same synth+STA pattern, real sky130_fd_sc_hd__dfxtp_1 cell mapped,
     real timing report with 4.24ns slack MET) as a regression check that
     the generalized script reproduces that known-good result.
   - Only after both trivial_test and fifo.sv produce clean results should
     this be considered validated for use on the remaining 4 modules.
