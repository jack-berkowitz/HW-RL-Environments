# Open-weight sweep

## Design

| model | answers | API errors | extracted | built | pass@1 | tasks with ≥1 pass |
|---|---|---|---|---|---|---|
| DeepSeek V4.1 Flash 1017 (reasoning high) | 10 | 0 | 4/10 | 4/10 | 0.30 | 3/10 |
| GLM 5.3 (reasoning high) | 10 | 0 | 1/10 | 1/10 | 0.10 | 1/10 |
| Kimi K3.1 Pro | 10 | 0 | 10/10 | 10/10 | 0.60 | 6/10 |

pass / answers, per task:

| task | DeepSeek V4.1 Flash 1017 (reasoning high) | GLM 5.3 (reasoning high) | Kimi K3.1 Pro |
|---|---|---|---|
| d_ai01 | 0/1 | 0/1 | 0/1 |
| d_ai04 | 1/1 | 0/1 | 1/1 |
| d_ca01 | 0/1 | 0/1 | 1/1 |
| d_ca03 | 0/1 | 0/1 | 1/1 |
| d_ca04 | 1/1 | 0/1 | 1/1 |
| d_ca05 | 0/1 | 0/1 | 0/1 |
| d_dsp02 | 0/1 | 0/1 | 1/1 |
| d_dsp03 | 0/1 | 0/1 | 0/1 |
| d_nw01 | 0/1 | 0/1 | 0/1 |
| d_nw03 | 1/1 | 1/1 | 1/1 |

## Verification

| model | answers | API errors | extracted | built | valid@1 | tasks with ≥1 valid | faults caught (valid only) |
|---|---|---|---|---|---|---|---|
| DeepSeek V4.1 Flash 1017 (reasoning high) | 11 | 0 | 6/11 | 4/11 | 0.18 | 2/11 | 55% mean |
| GLM 5.3 (reasoning high) | 11 | 0 | 1/11 | 1/11 | 0.09 | 1/11 | 92% mean |
| Kimi K3.1 Pro | 11 | 0 | 10/11 | 10/11 | 0.45 | 5/11 | 68% mean |

valid / answers, per task:

| task | DeepSeek V4.1 Flash 1017 (reasoning high) | GLM 5.3 (reasoning high) | Kimi K3.1 Pro |
|---|---|---|---|
| v_ai02 | 0/1 | 0/1 | 1/1 |
| v_ca03 | 0/1 | 0/1 | 0/1 |
| v_ca04 | 0/1 | 0/1 | 0/1 |
| v_ca05 | 1/1 | 0/1 | 1/1 |
| v_ca06 | 0/1 | 0/1 | 0/1 |
| v_ca07 | 0/1 | 0/1 | 0/1 |
| v_dsp02 | 0/1 | 1/1 | 1/1 |
| v_nw01 | 1/1 | 0/1 | 1/1 |
| v_nw02 | 0/1 | 0/1 | 0/1 |
| v_nw03 | 0/1 | 0/1 | 1/1 |
| v_nw04 | 0/1 | 0/1 | 0/1 |

Outcome counts: did not build=2, fail=5, invalid=6, pass=10, rejects correct design=1, truncated=30, valid=8, wrong module=1
