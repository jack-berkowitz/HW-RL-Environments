# Open-weight sweep

## Design

| model | answers | API errors | extracted | built | pass@1 | pass@3 | tasks with ≥1 pass |
|---|---|---|---|---|---|---|---|
| DeepSeek V4.1 Flash 1017 | 30 | 0 | 29/30 | 28/30 | 0.57 | 0.90 | 9/10 |
| GLM 5.3 | 30 | 0 | 25/30 | 21/30 | 0.37 | 0.60 | 6/10 |
| Kimi K3.1 Pro | 30 | 0 | 30/30 | 28/30 | 0.77 | 1.00 | 10/10 |

pass / answers, per task:

| task | DeepSeek V4.1 Flash 1017 | GLM 5.3 | Kimi K3.1 Pro |
|---|---|---|---|
| d_ai01 | 0/3 | 0/3 | 1/3 |
| d_ai04 | 2/3 | 2/3 | 3/3 |
| d_ca01 | 2/3 | 3/3 | 3/3 |
| d_ca03 | 2/3 | 1/3 | 2/3 |
| d_ca04 | 2/3 | 1/3 | 3/3 |
| d_ca05 | 2/3 | 0/3 | 1/3 |
| d_dsp02 | 1/3 | 0/3 | 3/3 |
| d_dsp03 | 1/3 | 0/3 | 3/3 |
| d_nw01 | 2/3 | 2/3 | 1/3 |
| d_nw03 | 3/3 | 2/3 | 3/3 |

## Verification

| model | answers | API errors | extracted | built | valid@1 | valid@3 | tasks with ≥1 valid | faults caught (valid only) |
|---|---|---|---|---|---|---|---|---|
| DeepSeek V4.1 Flash 1017 | 27 | 0 | 22/27 | 19/27 | 0.19 | 0.44 | 4/9 | 52% mean |
| GLM 5.3 | 27 | 0 | 27/27 | 20/27 | 0.33 | 0.56 | 5/9 | 64% mean |
| Kimi K3.1 Pro | 27 | 0 | 27/27 | 24/27 | 0.48 | 0.67 | 6/9 | 70% mean |

valid / answers, per task:

| task | DeepSeek V4.1 Flash 1017 | GLM 5.3 | Kimi K3.1 Pro |
|---|---|---|---|
| v_ai02 | 2/3 | 3/3 | 3/3 |
| v_ca03 | 0/3 | 2/3 | 0/3 |
| v_ca04 | 1/3 | 1/3 | 1/3 |
| v_ca05 | 1/3 | 0/3 | 1/3 |
| v_dsp02 | 0/3 | 0/3 | 3/3 |
| v_nw01 | 0/3 | 0/3 | 2/3 |
| v_nw02 | 0/3 | 1/3 | 0/3 |
| v_nw03 | 1/3 | 2/3 | 3/3 |
| v_nw04 | 0/3 | 0/3 | 0/3 |

Outcome counts: did not build=20, fail=26, invalid=29, no code=2, pass=51, rejects correct design=7, truncated=9, valid=27

Excluded from this comparison: v_ca06 (prompt names id_width_conv_tb; harness expects dw_downsizer_tb); v_ca07 (prompt names id_width_conv_tb; harness expects clk_ratio_div_tb)
