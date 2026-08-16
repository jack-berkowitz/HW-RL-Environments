# Model answers for d_dsp02 fp32_fma_ii1.

RTL submissions, module name `fp32_fma_ii1` from `spec/fp32_fma_ii1_iface.sv`.

**HOLDING PEN — nothing runs against these yet.** The task has no
`ref/sim_flags_verilator.txt` and is not registered with `sim_candidate.sh`
(FINDINGS.md F22), so it is unscoreable until the plumbing is rebuilt.

Do not sweep this directory meanwhile: `sim_candidate.sh` refuses correctly, but
`run_submissions.sh` relabels any refusal as `correctness gate failed` and counts
it against the pass rate. See the warning in `candidates/README.md`.
