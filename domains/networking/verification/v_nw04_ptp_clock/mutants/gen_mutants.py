#!/usr/bin/env python3
"""Generate the v_nw04 mutant set.

Every mutant is a MECHANICAL edit of a renamed copy of the anchor, wrapped by a
renamed copy of the golden shim. Each edit is an exact old -> new string pair
asserted to match EXACTLY ONCE: a silent no-op would produce a mutant identical
to the golden that every testbench "kills" by doing nothing, so the count is
checked rather than assumed.

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


def sub1(text, old, new, what):
    n = text.count(old)
    if n != 1:
        sys.exit("MUTATION %s: pattern occurs %d times, expected exactly 1:\n  %s"
                 % (what, n, old))
    return text.replace(old, new)


# tag -> (clause, one-line note, [(old, new), ...])
MUT = [
 ("m1_drift_period_off_by_one", "D2",
  "drift lands every drift_rate+1 increments, not every drift_rate",
  [("drift_cnt <= drift_rate_reg-1;", "drift_cnt <= drift_rate_reg;")]),

 ("m2_adjust_one_short", "A2",
  "the offset adjustment is applied adj_count-1 times",
  [("if (adj_count_reg > 0) begin", "if (adj_count_reg > 1) begin")]),

 ("m3_adj_active_one_long", "A3",
  "adj_active_o is asserted for adj_count+1 cycles while adj_count increments are adjusted",
  [("assign input_adj_active = adj_active_reg;",
    "assign input_adj_active = adj_active_reg || (adj_count_reg > 0);")]),

 ("m4_wrap_one_ns_early", "W1",
  "the one-second wrap happens one nanosecond early",
  [("{ts_inc_ns_ovf_reg, ts_inc_fns_ovf_reg} <= {NS_PER_S, {FNS_WIDTH{1'b0}}} - "
    "{ts_inc_ns_reg, ts_inc_fns_reg};",
    "{ts_inc_ns_ovf_reg, ts_inc_fns_ovf_reg} <= {NS_PER_S - 31'd1, {FNS_WIDTH{1'b0}}} - "
    "{ts_inc_ns_reg, ts_inc_fns_reg};")]),

 ("m5_pps_two_cycles", "W3",
  "pps_o is asserted for two cycles per wrap instead of one",
  [("reg pps_reg = 0;", "reg pps_reg = 0;\nreg pps_prev_reg = 0;"),
   ("pps_reg <= !ts_96_ns_ovf_reg[30];",
    "pps_prev_reg <= !ts_96_ns_ovf_reg[30];\n"
    "    pps_reg <= (!ts_96_ns_ovf_reg[30]) || pps_prev_reg;")]),

 ("m6_fns_truncated_in_ts96", "I1/F3",
  "the 96-bit base drops the bottom four fractional bits of every increment",
  [("{ts_96_ns_inc_reg, ts_96_fns_inc_reg} <= {ts_96_ns_inc_reg, ts_96_fns_inc_reg} + "
    "{ts_inc_ns_delay_reg, ts_inc_fns_delay_reg};",
    "{ts_96_ns_inc_reg, ts_96_fns_inc_reg} <= {ts_96_ns_inc_reg, ts_96_fns_inc_reg} + "
    "{ts_inc_ns_delay_reg, ts_inc_fns_delay_reg & ~16'hF};")]),

 ("m7_adjust_unsigned", "A5",
  "the offset adjustment is treated as unsigned, so a negative one advances the clock",
  [("(adj_active_reg ? $signed({adj_ns_reg, adj_fns_reg}) : 0) +",
    "(adj_active_reg ? $signed({1'b0, adj_ns_reg, adj_fns_reg}) : 0) +")]),

 ("m8_reset_keeps_period", "R2",
  "reset leaves the last programmed period in place instead of restoring the default",
  [("        period_ns_reg <= PERIOD_NS;\n        period_fns_reg <= PERIOD_FNS;",
    "        // MUTANT: the default period is NOT restored on reset")]),
]

blocks = []
for tag, clause, note, edits in MUT:
    txt = ANCHOR
    for old, new in edits:
        txt = sub1(txt, old, new, "%s/anchor" % tag)
    txt = re.sub(r"\bptp_clock\b", "ptp_clock_%s" % tag, txt)
    open(os.path.join(DUT, "ptp_clock_%s.sv" % tag), "w", encoding="utf-8").write(txt)

    body = SHIM[SHIM.index("module ptp_time_base ("):]
    body = body.replace("module ptp_time_base (", "module pt_%s (" % tag, 1)
    body = sub1(body, "ptp_clock #(", "ptp_clock_%s #(" % tag, "%s/inst" % tag)
    body = body.replace("  ) i_clock (",
                        "  ) i_clock (   // MUTANT pt_%s -- violates %s: %s" % (tag, clause, note))
    blocks.append(body)

# ---------------------------------------------------------------------------
# TIER-B 5c: the same eight defects re-derived on the POLICY-DIVERGENT
# implementation. If a mutant's verdict changes between the two bases it is
# perturbing latitude rather than contract and does not belong in the set.
# The perturbation also serves as dut2, generated here so the two cannot drift.
# ---------------------------------------------------------------------------
CONF_PATH = os.path.join(TASK, "conformant", "conformant_perturbations.sv")
conf = open(CONF_PATH, encoding="utf-8").read()

POLICY = {
 "p1_drift_period_off_by_one": [
   ("drift_cnt_q <= drift_on ? (rate_now - 16'd1) : (drift_cnt_q - 16'd1);",
    "drift_cnt_q <= drift_on ? rate_now : (drift_cnt_q - 16'd1);")],
 "p2_adjust_one_short": [
   ("wire adj_on   = (cnt_now != 16'd0);", "wire adj_on   = (cnt_now > 16'd1);")],
 "p3_adj_active_one_long": [
   ("  logic        pps_q;", "  logic        pps_q;\n  logic        adj_was_on_q;"),
   ("assign adj_active_o = adj_on;", "assign adj_active_o = adj_on || adj_was_on_q;"),
   ("    pps_q <= wrap_now;", "    pps_q <= wrap_now;\n    adj_was_on_q <= adj_on;")],
 "p4_wrap_one_ns_early": [
   ("wire        wrap_now   = (nsfns_next >= {1'b0, FNS_PER_SEC});",
    "wire        wrap_now   = (nsfns_next >= ({1'b0, FNS_PER_SEC} - 47'd65536));")],
 "p5_pps_two_cycles": [
   ("  logic        pps_q;", "  logic        pps_q;\n  logic        pps_prev_q;"),
   ("assign pps_o        = pps_q;", "assign pps_o        = pps_q || pps_prev_q;"),
   ("    pps_q <= wrap_now;", "    pps_q <= wrap_now;\n    pps_prev_q <= pps_q;")],
 "p6_fns_truncated_in_ts96": [
   ("wire [46:0] nsfns_next = {1'b0, nsfns_q} + {{24{inc[22]}}, inc};",
    "wire [46:0] nsfns_next = {1'b0, nsfns_q} + {{24{inc[22]}}, (inc & 23'sh7FFFF0)};")],
 "p7_adjust_unsigned": [
   ("(adj_on   ? $signed({{3{adj_now[19]}},   adj_now})   : 23'sd0)",
    "(adj_on   ? $signed({3'b000, adj_now})   : 23'sd0)")],
 "p8_reset_keeps_period": [
   ("      period_q <= DEF_PERIOD; adj_q <= 20'd0; drift_q <= DEF_DRIFT;",
    "      adj_q <= 20'd0; drift_q <= DEF_DRIFT;  // MUTANT: period not restored")],
}
os.makedirs(os.path.join(TASK, "mutants", "policy"), exist_ok=True)
for tag, edits in POLICY.items():
    txt = conf
    for old, new in edits:
        txt = sub1(txt, old, new, "policy/%s" % tag)
    txt = sub1(txt, "module pt_c1_zero_latency", "module ptp_time_base", "policy/%s rename" % tag)
    open(os.path.join(TASK, "mutants", "policy", "pt_%s.sv" % tag), "w",
         encoding="utf-8").write(txt)

os.makedirs(os.path.join(TASK, "dut2"), exist_ok=True)
alt = sub1(conf, "module pt_c1_zero_latency", "module ptp_time_base_alt", "dut2/rename")
open(os.path.join(TASK, "dut2", "ptp_time_base_alt.sv"), "w", encoding="utf-8").write(
    "// GENERATED from conformant/conformant_perturbations.sv by mutants/gen_mutants.py.\n"
    "// Same artefact, two roles: the policy-divergent perturbation that must be\n"
    "// ACCEPTED, and the independent second implementation. Do not edit by hand.\n" + alt)

HEAD = """// v_nw04 mutant set -- these MUST BE CAUGHT. Scoring only, never shipped.
//
// GENERATED by mutants/gen_mutants.py. Do not edit by hand; edit the generator
// so that every defect stays a named, single, auditable change.
"""
open(os.path.join(HERE, "mutants.sv"), "w", encoding="utf-8").write(HEAD + "\n" + "\n".join(blocks))
print("wrote mutants.sv with %d mutants and %d mutated anchor copies" % (len(MUT), len(MUT)))
