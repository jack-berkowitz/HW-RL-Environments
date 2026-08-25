#!/usr/bin/env python3
"""Generate the v_nw04 mutant set.

EVERY MUTANT IS GUARDED. The defect is `wrong_behaviour AND a narrow predicate
on contract-level state`, never the behaviour alone. An unguarded defect fires
on the first transaction of its class, so it measures whether a testbench
exercised the feature rather than whether it checks it: the first version of
this set was unguarded and the submissions that cleared the gate scored 8/8.

Guards count things the CONTRACT names -- how many adjustments have been asked
for, how many wraps have happened, how large an adjustment is, whether a drift
and an adjustment land on the same increment. Never an implementation-private
encoding, so each defect stays re-derivable on the policy-divergent
implementation that Tier-B step 5c requires.

Run:  python3 mutants/gen_mutants.py
"""
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
TASK = os.path.dirname(HERE)
DUT = os.path.join(TASK, "dut")
SHIM = open(os.path.join(DUT, "ptp_time_base.sv"), encoding="utf-8").read()
ANCHOR = open(os.path.join(DUT, "ptp_clock.sv"), encoding="utf-8").read()

DECL = "reg pps_reg = 0;"
DRIFT_TERM = "((DRIFT_ENABLE && drift_cnt == 0) ? $signed({drift_ns_reg, drift_fns_reg}) : 0);"
ADJ_TERM = "(adj_active_reg ? $signed({adj_ns_reg, adj_fns_reg}) : 0) +"
ADJ_GUARD = "if (adj_count_reg > 0) begin"
ACTIVE = "assign input_adj_active = adj_active_reg;"
OVF = "{ts_inc_ns_ovf_reg, ts_inc_fns_ovf_reg} <= {NS_PER_S, {FNS_WIDTH{1'b0}}} - {ts_inc_ns_reg, ts_inc_fns_reg};"
PPS = "pps_reg <= !ts_96_ns_ovf_reg[30];"
ACC96 = "{ts_96_ns_inc_reg, ts_96_fns_inc_reg} <= {ts_96_ns_inc_reg, ts_96_fns_inc_reg} + {ts_inc_ns_delay_reg, ts_inc_fns_delay_reg};"
RSTPER = "        period_ns_reg <= PERIOD_NS;\n        period_fns_reg <= PERIOD_FNS;"
DRIFTCNT = "drift_cnt <= drift_rate_reg-1;"

HELPERS = """reg pps_reg = 0;
// ---- MUTANT bookkeeping: every counter below counts something the CONTRACT
// names -- adjustments asked for, wraps seen, periods programmed, drifts applied.
reg [7:0] adj_seen_q  = 8'd0;   // how many offset adjustments have been started
reg [7:0] wrap_seen_q = 8'd0;   // how many one-second wraps have happened
reg [7:0] per_prog_q  = 8'd0;   // how many times a new period has been latched
reg [7:0] drift_app_q = 8'd0;   // how many drift applications so far
reg       adj_long_q   = 1'b0;  // this adjustment was asked for 8+ increments
reg       rate_new_q   = 1'b0;  // the drift rate changed and its next window is the first
reg [2:0] drift_win_q  = 3'd0;  // drift windows completed since the rate changed
wire      drift_now   = (DRIFT_ENABLE && drift_cnt == 0);
wire      adj_now     = adj_active_reg;
always @(posedge clk) begin
    if (input_adj_valid) begin
        adj_seen_q  <= adj_seen_q + 8'd1;
        adj_long_q  <= (input_drift_valid ? adj_long_q : (input_adj_count >= 16'd8));
    end
    if (input_adj_valid) adj_long_q <= (input_adj_count >= 16'd8);
    if (input_drift_valid) begin rate_new_q <= 1'b1; drift_win_q <= 3'd0; end
    else if (drift_cnt == 0) begin
        rate_new_q  <= 1'b0;
        drift_win_q <= (drift_win_q == 3'd7) ? 3'd7 : (drift_win_q + 3'd1);
    end
    if (input_period_valid)                  per_prog_q  <= per_prog_q + 8'd1;
    if (drift_now)                           drift_app_q <= drift_app_q + 8'd1;
    if (!ts_96_ns_ovf_reg[30])               wrap_seen_q <= wrap_seen_q + 8'd1;
    if (rst) begin
        adj_seen_q <= 8'd0; wrap_seen_q <= 8'd0;
        drift_app_q <= 8'd0; drift_win_q <= 3'd0;
        adj_long_q <= 1'b0; rate_new_q <= 1'b0;
        // per_prog_q deliberately NOT cleared: it counts programmings since
        // power-on, and clearing it here would let the defect undo itself
        // while reset is still being held.
    end
end
"""


def sub1(text, old, new, what):
    n = text.count(old)
    if n != 1:
        sys.exit("MUTATION %s: pattern occurs %d times, expected exactly 1:\n  %s"
                 % (what, n, old))
    return text.replace(old, new)


MUT = [
 ("m1_drift_skipped_one_in_eight", "D2",
  "one drift application in every eight is skipped; the other seven are exact",
  [(DRIFT_TERM, "((DRIFT_ENABLE && drift_cnt == 0 && (drift_app_q[2:0] != 3'd7))\n"
                "         ? $signed({drift_ns_reg, drift_fns_reg}) : 0);")]),

 ("m2_adjust_short_when_long", "A2",
  "an adjustment of eight or more increments is applied one short; shorter ones are exact",
  [(ADJ_GUARD, "if (adj_count_reg > (adj_long_q ? 16'd1 : 16'd0)) begin")]),

 ("m3_adj_active_long_from_second", "A3",
  "adj_active_o runs one cycle past the adjustment, but only from the second adjustment onward",
  [(ACTIVE, "assign input_adj_active = adj_active_reg\n"
            "                          || ((adj_seen_q >= 8'd2) && (adj_count_reg > 0));")]),

 ("m4_wrap_early_when_fraction_carried", "W1",
  "the wrap happens one nanosecond early, but only when the boundary is crossed mid-nanosecond",
  [(OVF, "{ts_inc_ns_ovf_reg, ts_inc_fns_ovf_reg} <= {NS_PER_S, {FNS_WIDTH{1'b0}}}\n"
         "        - {ts_inc_ns_reg, ts_inc_fns_reg}\n"
         "        - ((ts_96_fns_reg != 0) ? {31'd1, {FNS_WIDTH{1'b0}}} : '0);")]),

 ("m5_pps_two_cycles_on_later_wraps", "W3",
  "pps_o lasts two cycles, but only from the second wrap onward",
  [(DECL, "reg pps_reg = 0;\nreg pps_prev_q = 1'b0;"),
   (PPS, "pps_prev_q <= !ts_96_ns_ovf_reg[30];\n"
         "    pps_reg <= (!ts_96_ns_ovf_reg[30])\n"
         "               || (pps_prev_q && (wrap_seen_q >= 8'd2));")]),

 ("m6_fns_truncated_on_drift_cycles", "I1/F3",
  "the 96-bit base drops four fractional bits, but only on the increments that carry the drift",
  [(ACC96, "{ts_96_ns_inc_reg, ts_96_fns_inc_reg} <= {ts_96_ns_inc_reg, ts_96_fns_inc_reg}\n"
           "        + {ts_inc_ns_delay_reg, drift_now ? (ts_inc_fns_delay_reg & ~16'hF)\n"
           "                                          : ts_inc_fns_delay_reg};")]),

 ("m7_adjust_unsigned_for_small_magnitudes", "A5",
  "a NEGATIVE adjustment is treated as unsigned, but only when its magnitude is under one nanosecond",
  [(ADJ_TERM, "(adj_active_reg ? ((adj_ns_reg == 4'hF)\n"
              "                    ? $signed({1'b0, adj_ns_reg, adj_fns_reg})\n"
              "                    : $signed({adj_ns_reg, adj_fns_reg})) : 0) +")]),

 ("m8_reset_keeps_reprogrammed_period", "R2",
  "reset restores the default period the first time, but not once a period has been programmed twice",
  [(RSTPER, "        if (per_prog_q < 8'd2) period_ns_reg <= PERIOD_NS;\n"
            "        if (per_prog_q < 8'd2) period_fns_reg <= PERIOD_FNS;")]),

 ("m9_fourth_window_after_rate_change", "D2",
  "the FOURTH drift window after a rate change is one cycle long; the ones around it are exact",
  [(DRIFTCNT, "drift_cnt <= (drift_win_q == 3'd3) ? drift_rate_reg : (drift_rate_reg-1);")]),

 ("m10_drift_dropped_when_adjustment_active", "I1",
  "when an adjustment and a drift fall on the SAME increment only the adjustment is applied",
  [(DRIFT_TERM, "((DRIFT_ENABLE && drift_cnt == 0 && !adj_active_reg)\n"
                "         ? $signed({drift_ns_reg, drift_fns_reg}) : 0);")]),
]

blocks = []
for tag, clause, note, edits in MUT:
    txt = ANCHOR
    if DECL in txt and tag != "m5_pps_two_cycles_on_later_wraps":
        txt = sub1(txt, DECL, HELPERS, tag + "/helpers")
    else:
        txt = sub1(txt, DECL, HELPERS.replace("reg pps_reg = 0;\n", "reg pps_reg = 0;\nreg pps_prev_q = 1'b0;\n", 1), tag + "/helpers")
    for old, new in edits:
        if old == DECL:
            continue          # already folded into the helper block
        txt = sub1(txt, old, new, tag + "/anchor")
    txt = re.sub(r"\bptp_clock\b", "ptp_clock_%s" % tag, txt)
    open(os.path.join(DUT, "ptp_clock_%s.sv" % tag), "w", encoding="utf-8").write(txt)

    b = SHIM[SHIM.index("module ptp_time_base ("):]
    b = sub1(b, "module ptp_time_base (", "module pt_%s (" % tag, tag + "/rename")
    b = sub1(b, "  ptp_clock #(",
             "  // MUTANT pt_%s -- violates %s: %s\n  ptp_clock_%s #(" % (tag, clause, note, tag),
             tag + "/inst")
    blocks.append(b)

HEAD = """// v_nw04 mutant set -- these MUST BE CAUGHT. Scoring only, never shipped.
//
// GENERATED by mutants/gen_mutants.py. Every defect is GUARDED: it fires only
// under a narrow predicate on contract-level state, so exercising the feature
// is not enough to find it. Do not edit by hand; edit the generator.
"""
open(os.path.join(HERE, "mutants.sv"), "w", encoding="utf-8").write(HEAD + "\n" + "\n".join(blocks))
print("wrote mutants.sv with %d guarded mutants" % len(blocks))

# ---------------------------------------------------------------------------
# TIER-B 5c: the same ten guarded defects re-derived on the POLICY-DIVERGENT
# implementation, which acts on every control input in its own cycle and drives
# both bases from the same increment. A verdict that differs between the two
# bases means the mutant is keyed to an implementation choice, not the contract.
# ---------------------------------------------------------------------------
CONF = os.path.join(TASK, "conformant", "conformant_perturbations.sv")
conf = open(CONF, encoding="utf-8").read()

A_ADJON  = "  wire adj_on   = (cnt_now != 16'd0);"
A_DRIFTON = "  wire drift_on = drift_valid_i ? 1'b1 : (drift_cnt_q == 16'd0);"
A_INC    = "  wire signed [22:0] inc = $signed({3'b000, period_now})"
A_NEXT   = "  wire [46:0] nsfns_next = {1'b0, nsfns_q} + {{24{inc[22]}}, inc};"
A_WRAP   = "  wire        wrap_now   = (nsfns_next >= {1'b0, FNS_PER_SEC});"
A_ACTIVE = "  assign adj_active_o = adj_on;"
A_PPS    = "    pps_q <= wrap_now;                                            // W3"
A_DCNT   = "    drift_cnt_q <= drift_on ? (rate_now - 16'd1) : (drift_cnt_q - 16'd1);  // D2"
A_RSTPER = "      period_q <= DEF_PERIOD; adj_q <= 20'd0; drift_q <= DEF_DRIFT;"

ALT_HELPERS = """  wire adj_on   = (cnt_now != 16'd0);
  // ---- MUTANT bookkeeping, on contract-level state only -------------------
  logic [7:0] h_adj_q, h_wrap_q, h_per_q, h_drift_q;
  logic [2:0] h_win_q;
  logic       h_long_q, h_ratenew_q, h_pps_q, h_prevon_q;
  always_ff @(posedge clk_i) begin
    if (rst_i) begin
      h_adj_q <= '0; h_wrap_q <= '0; h_drift_q <= '0;
      h_win_q <= '0; h_long_q <= 1'b0; h_ratenew_q <= 1'b0; h_pps_q <= 1'b0;
      h_prevon_q <= 1'b0;
    end else begin
      if (adj_valid_i)   begin h_adj_q <= h_adj_q + 8'd1; h_long_q <= (adj_count_i >= 16'd8); end
      if (period_valid_i) h_per_q <= h_per_q + 8'd1;   // NOT cleared by reset, on purpose
      if (drift_on)       h_drift_q <= h_drift_q + 8'd1;
      if (wrap_now)       h_wrap_q <= h_wrap_q + 8'd1;
      h_pps_q <= wrap_now;
      h_prevon_q <= adj_on;
      if (drift_valid_i) begin h_ratenew_q <= 1'b1; h_win_q <= 3'd0; end
      else if (drift_cnt_q == 16'd0) begin
        h_ratenew_q <= 1'b0;
        h_win_q <= (h_win_q == 3'd7) ? 3'd7 : (h_win_q + 3'd1);
      end
    end
  end
"""

POLICY = {
 "p1_drift_skipped_one_in_eight":
   [(A_DRIFTON, "  wire drift_on = (drift_valid_i ? 1'b1 : (drift_cnt_q == 16'd0))\n"
                "                  && (h_drift_q[2:0] != 3'd7);")],
 "p2_adjust_short_when_long":
   [(A_ADJON, "  wire adj_on   = (cnt_now > (h_long_q ? 16'd1 : 16'd0));")],
 "p3_adj_active_long_from_second":
   [(A_ACTIVE, "  assign adj_active_o = adj_on || ((h_adj_q >= 8'd2) && h_prevon_q);")],
 "p4_wrap_early_when_fraction_carried":
   [("      nsfns_q <= nsfns_next[45:0] - FNS_PER_SEC;                 // W1",
      "      nsfns_q <= nsfns_next[45:0] - FNS_PER_SEC\n"
      "                 + ((nsfns_q[15:0] != 16'd0) ? 46'd65536 : 46'd0);")],
 "p5_pps_two_cycles_on_later_wraps":
   [(A_PPS, "    pps_q <= wrap_now || (h_pps_q && (h_wrap_q >= 8'd2));")],
 "p6_fns_truncated_on_drift_cycles":
   [(A_NEXT, "  wire [46:0] nsfns_next = {1'b0, nsfns_q}\n"
             "        + (drift_on ? ({{24{inc[22]}}, inc} & ~47'hF) : {{24{inc[22]}}, inc});")],
 "p7_adjust_unsigned_for_small_magnitudes":
   [(A_INC, "  wire signed [22:0] inc = $signed({3'b000, period_now})")],
 "p8_reset_keeps_reprogrammed_period":
   [(A_RSTPER, "      if (h_per_q < 8'd2) period_q <= DEF_PERIOD;\n"
               "      adj_q <= 20'd0; drift_q <= DEF_DRIFT;")],
 "p9_fourth_window_after_rate_change":
   [(A_DCNT, "    drift_cnt_q <= drift_on ? ((h_win_q == 3'd3) ? rate_now : (rate_now - 16'd1))\n"
             "                            : (drift_cnt_q - 16'd1);")],
 "p10_drift_dropped_when_adjustment_active":
   [(A_DRIFTON, "  wire drift_on = (drift_valid_i ? 1'b1 : (drift_cnt_q == 16'd0)) && !adj_on;")],
}

# p7 needs the adj term itself changed, which lives on the line after A_INC
P7_ADJ = "                         + (adj_on   ? $signed({{3{adj_now[19]}},   adj_now})   : 23'sd0)"
P7_NEW = ("                         + (adj_on   ? ((adj_now[19:16] == 4'hF)\n"
          "                                        ? $signed({3'b000, adj_now})\n"
          "                                        : $signed({{3{adj_now[19]}}, adj_now})) : 23'sd0)")

os.makedirs(os.path.join(TASK, "mutants", "policy"), exist_ok=True)
# THE GENERATOR OWNS THE DIRECTORY THE 5c RUNNER ENUMERATES. That runner globs
# policy/*.sv and grades every file it finds, so a file left behind by an
# earlier naming is graded exactly like a current one and nothing in the output
# distinguishes them. On v_ca07 that happened and turned a reported 22/22 into a
# real 21/22. Wiping first means a failed generation leaves a file MISSING --
# which the runner counts and refuses on -- rather than STALE, which it cannot
# see.
_POL = os.path.join(TASK, "mutants", "policy")
os.makedirs(_POL, exist_ok=True)
for _f in os.listdir(_POL):
    if _f.endswith(".sv"):
        os.remove(os.path.join(_POL, _f))

for tag, edits in POLICY.items():
    txt = sub1(conf, A_ADJON, ALT_HELPERS, "policy/%s helpers" % tag)
    if tag == "p7_adjust_unsigned_for_small_magnitudes":
        txt = sub1(txt, P7_ADJ, P7_NEW, "policy/%s adj" % tag)
    else:
        for old, new in edits:
            if old == A_ADJON:
                txt = sub1(txt, "  wire adj_on   = (cnt_now != 16'd0);", new, "policy/%s" % tag)
            else:
                txt = sub1(txt, old, new, "policy/%s" % tag)
    txt = sub1(txt, "module pt_c1_zero_latency", "module ptp_time_base", "policy/%s rename" % tag)
    open(os.path.join(TASK, "mutants", "policy", "pt_%s.sv" % tag), "w",
         encoding="utf-8").write(txt)
print("wrote %d policy-base mutants" % len(POLICY))
