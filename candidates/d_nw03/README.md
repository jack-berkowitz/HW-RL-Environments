# candidates/d_nw03 — `axis_switch_oq`

One file per attempt, `<label>.sv`, containing only `module axis_switch_oq` with
the exact port list from `spec/axis_switch_oq_iface.sv`.

Solicit with `probe/PASTE.md` in the task directory.

```
./scripts/sim_candidate.sh d_nw03 candidates/d_nw03/<label>.sv
```

8 configurations. The scored one is `S_COUNT=4 M_COUNT=4 DATA_W=32`, and 4x4 is
load-bearing: C1 is enforced only there, because at 2x2 the ceiling is the floor
and a serialised design cannot be told from a correct one.
