# Open-weight sweep: PPA builds

One build per model×task: the lowest-numbered passing sample, at the task's pinned clock (`ppa_plan.sh`).
Built serially on the PC with `LEC_CHECK=0 HWRL_NO_README_REGEN=1`. Every record below was checked with
`scripts/check_ppa_record.py` immediately after its own build (23/23 ok, 0 mismatched). Numbers are from the
run records only. A build that misses timing shows "timing missed" in place of area and power (rule 22).
Reference = newest completed `reference*` PPA record for the task at the same clock.

| model | task | sample | pin (ns) | WNS (ns) | area (µm²) | power | ref WNS | ref area | ref power |
|---|---|---|---|---|---|---|---|---|---|
| DeepSeek V4.1 Flash | d_ai04 | s02 | 33.75 | +2.296 | 182,219 | 292 mW | +1.912 | 179,943 | 230 mW |
| DeepSeek V4.1 Flash | d_ca01 | s01 | 15 | +2.474 | 742,166 | 136 mW | +2.200 | 573,055 | 76 mW |
| DeepSeek V4.1 Flash | d_ca03 | s01 | 12.5 | -34.542 (missed) | timing missed | timing missed | +0.989 | 279,456 | 32.6 mW |
| DeepSeek V4.1 Flash | d_ca04 | s02 | 4.25 | +1.625 | 16,089 | 9.35 mW | +0.606 | 19,837 | 13.4 mW |
| DeepSeek V4.1 Flash | d_ca05 | s02 | 8.75 | +1.635 | 108,559 | 25.3 mW | +0.720 | 141,187 | 40.6 mW |
| DeepSeek V4.1 Flash | d_dsp02 | s01 | 19.25 | -14.960 (missed) | timing missed | timing missed | +2.710 | 60,031 | 74.7 mW |
| DeepSeek V4.1 Flash | d_dsp03 | s01 | 70.5 | not built | — | — | +1.995 | 177,557 | 91.1 mW |
| DeepSeek V4.1 Flash | d_nw01 | s01 | 8 | +0.304 | 414,770 | 128 mW | +1.148 | 147,144 | 54.7 mW |
| DeepSeek V4.1 Flash | d_nw03 | s01 | 4.25 | -0.457 (missed) | timing missed | timing missed | +0.337 | 26,340 | 10.2 mW |
| GLM 5.3 | d_ai04 | s01 | 33.75 | +3.909 | 142,304 | 468 mW | +1.912 | 179,943 | 230 mW |
| GLM 5.3 | d_ca01 | s01 | 15 | +1.063 | 811,237 | 90.7 mW | +2.200 | 573,055 | 76 mW |
| GLM 5.3 | d_ca03 | s01 | 12.5 | +0.099 | 307,389 | 46.2 mW | +0.989 | 279,456 | 32.6 mW |
| GLM 5.3 | d_ca04 | s02 | 4.25 | +0.481 | 14,434 | 7.76 mW | +0.606 | 19,837 | 13.4 mW |
| GLM 5.3 | d_nw01 | s01 | 8 | +0.229 | 90,803 | 20.3 mW | +1.148 | 147,144 | 54.7 mW |
| GLM 5.3 | d_nw03 | s02 | 4.25 | -1.260 (missed) | timing missed | timing missed | +0.337 | 26,340 | 10.2 mW |
| Kimi K3.1 Pro | d_ai01 | s03 | 16.75 | not built | — | — | +2.368 | 708,442 | 278 mW |
| Kimi K3.1 Pro | d_ai04 | s01 | 33.75 | +4.362 | 162,343 | 215 mW | +1.912 | 179,943 | 230 mW |
| Kimi K3.1 Pro | d_ca01 | s01 | 15 | +1.519 | 781,137 | 179 mW | +2.200 | 573,055 | 76 mW |
| Kimi K3.1 Pro | d_ca03 | s01 | 12.5 | +0.320 | 224,859 | 41 mW | +0.989 | 279,456 | 32.6 mW |
| Kimi K3.1 Pro | d_ca04 | s01 | 4.25 | +0.498 | 14,524 | 7.78 mW | +0.606 | 19,837 | 13.4 mW |
| Kimi K3.1 Pro | d_ca05 | s03 | 8.75 | +0.804 | 208,461 | 30.6 mW | +0.720 | 141,187 | 40.6 mW |
| Kimi K3.1 Pro | d_dsp02 | s01 | 19.25 | -7.748 (missed) | timing missed | timing missed | +2.710 | 60,031 | 74.7 mW |
| Kimi K3.1 Pro | d_dsp03 | s01 | 70.5 | -46.017 (missed) | timing missed | timing missed | +1.995 | 177,557 | 91.1 mW |
| Kimi K3.1 Pro | d_nw01 | s03 | 8 | +0.098 | 154,426 | 30.8 mW | +1.148 | 147,144 | 54.7 mW |
| Kimi K3.1 Pro | d_nw03 | s01 | 4.25 | -0.702 (missed) | timing missed | timing missed | +0.337 | 26,340 | 10.2 mW |

## Not built (2 of 25)

- **d_dsp03 / DeepSeek V4.1 Flash s01 (70.5 ns):** never finished synthesis. About 4.5 h in Yosys passes before ABC,
  then 4 h 53 min in ABC at 100% CPU (Yosys 9 GB RSS). Stopped by hand after 9.5 h. Other d_dsp03 builds
  take 15–70 min. No record.
- **d_ai01 / Kimi K3.1 Pro s03 (16.75 ns):** OpenROAD detailed routing reached 14.7 GB RSS (PC has 15.5 GB), and
  the build runner was killed for memory pressure about 1 h 55 min in. No record.

Both are to be retried.

## Logs

- `_logs/ppa_20261117_002041.log`: builds 1–16 of `ppa_plan.sh` (build 16 interrupted).
- `_logs/ppa_20261117_155832.log`: the remaining 9 Kimi builds (plan lines 17–25), run after the interruption.
