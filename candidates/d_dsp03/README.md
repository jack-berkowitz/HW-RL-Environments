# candidates/d_dsp03

Drop model answers here as `<model>.sv`, one file each. Score with:

    scripts/sim_candidate.sh domains/dsp/design/d_dsp03_multifmt_fma candidates/d_dsp03

Two configs, WIDTH=32 and WIDTH=64. A candidate must pass both; WIDTH=64 is the
scored configuration and is the only one where the lane-count capability can
discriminate -- a design that hardcodes two lanes passes WIDTH=32 and fails
WIDTH=64. See `nc_b_two_lanes` in the task's `controls/`.

The task text to paste is `domains/dsp/design/d_dsp03_multifmt_fma/probe/PASTE.md`.
It is the contract and nothing else: no reference, no vectors, no testbench.
