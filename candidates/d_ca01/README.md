# candidates/d_ca01 — `nonblocking_dcache`

Model answers for `domains/comp_arch/design/d_ca01_nonblocking_dcache`.

One file per attempt, `<label>.sv`, containing **only** `module nonblocking_dcache`
with the exact port list from `spec/nonblocking_dcache_iface.sv`.

Solicit with `probe/PASTE.md` in the task directory — it carries the framing and
the full interface.

Score with:

```
./scripts/sim_candidate.sh d_ca01 candidates/d_ca01/<label>.sv
```

16 configurations, full cross of `DATA_W {32,64}` x `SETS {8,16}` x
`WAYS {2,4}` x `MAX_MISSES {2,8}`. The scored configuration for PPA, latency and
throughput is `DATA_W=32 SETS=16 WAYS=4 MAX_MISSES=8` — and `MAX_MISSES=8` is
load-bearing: the capability mutant survives all eight `MAX_MISSES=2`
configurations and dies at all eight of the 8s, so a pass at the low setting is
not capability evidence.
