#!/usr/bin/env python3
"""Generate the v_ai02 mutant set.

Every mutant is a MECHANICAL edit of the golden shim, and where the defect is
internal, of a renamed copy of the anchor. Each edit is an exact old -> new
string pair asserted to match EXACTLY ONCE, so a silent no-op cannot produce a
mutant identical to the golden that every testbench "kills" by doing nothing.

Run:  python3 mutants/gen_mutants.py
"""
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
TASK = os.path.dirname(HERE)
DUT = os.path.join(TASK, "dut")
SHIM = open(os.path.join(DUT, "stream_realign.sv"), encoding="utf-8").read()
ANCHOR = open(os.path.join(DUT, "hwpe_stream_source_realign.sv"), encoding="utf-8").read()
BODY = SHIM[SHIM.index("module stream_realign ("):]


def sub1(text, old, new, what):
    n = text.count(old)
    if n != 1:
        sys.exit("MUTATION %s: pattern occurs %d times, expected exactly 1:\n  %s"
                 % (what, n, old))
    return text.replace(old, new)


# internal defects: a renamed copy of the anchor with one edit
INTERNAL = {
 "m1_rotation_off_by_one": ("R2/R5",
   "the rotation is one byte more than the strobe calls for",
   [("    strb_rotate_d = '0;", "    strb_rotate_d = 1;")]),
 "m2_first_beat_emitted": ("R1",
   "the first beat of a line produces an output beat instead of being retained",
   [("push_i.valid & ~int_first & (int_last | (|int_strb));",
     "push_i.valid & (int_last | (|int_strb));")]),
 "m3_first_beat_not_retained": ("R2/R5",
   "the first beat of a line is not retained, so the next beat joins stale data",
   [("else if (~int_last_packet & push_i.valid & push_i.ready)",
     "else if (~int_last_packet & push_i.valid & push_i.ready & ~int_first)")]),
 "m4_rotation_reversed": ("R2",
   "the two halves are joined the wrong way round",
   [("pop_o.data = push_i.data << strb_rotate_q_shifted | stream_data_q >> strb_rotate_inv_q_shifted;",
     "pop_o.data = push_i.data >> strb_rotate_q_shifted | stream_data_q << strb_rotate_inv_q_shifted;")]),
 "m6_rotation_recaptured": ("R4",
   "the rotation is recaptured every cycle instead of only at a line's first beat",
   [("else if (~int_last_packet & int_first) begin", "else if (~int_last_packet) begin")]),
 "m8_last_ignored": ("R6",
   "a final beat with an empty strobe produces no output",
   [("(int_last | (|int_strb));", "((|int_strb));")]),
}

# shim-level defects
SHIMLEVEL = {
 "m5_strobe_passed_through": ("R3",
   "the output strobe carries the input strobe instead of all ones",
   [("  assign pop_strb_o  = pop.strb;", "  assign pop_strb_o  = push_strb_i;")]),
 "m7_always_realigns": ("P1",
   "the unit realigns even when realign_i is low, so pass-through is not transparent",
   [("    ctrl.realign     = realign_i;", "    ctrl.realign     = 1'b1;")]),
}

blocks = []
for tag, (clause, note, edits) in sorted(INTERNAL.items()):
    txt = ANCHOR
    for old, new in edits:
        txt = sub1(txt, old, new, "%s/anchor" % tag)
    txt = re.sub(r"\bhwpe_stream_source_realign\b", "hwpe_stream_source_realign_%s" % tag, txt)
    open(os.path.join(DUT, "hwpe_stream_source_realign_%s.sv" % tag), "w",
         encoding="utf-8").write(txt)
    b = sub1(BODY, "module stream_realign (", "module sr_%s (" % tag, "%s/rename" % tag)
    b = sub1(b, "  hwpe_stream_source_realign #(",
             "  // MUTANT sr_%s -- violates %s: %s\n  hwpe_stream_source_realign_%s #("
             % (tag, clause, note, tag), "%s/inst" % tag)
    blocks.append(b)

for tag, (clause, note, edits) in sorted(SHIMLEVEL.items()):
    b = BODY
    for old, new in edits:
        b = sub1(b, old, new, tag)
    b = sub1(b, "module stream_realign (", "module sr_%s (" % tag, "%s/rename" % tag)
    b = sub1(b, "  hwpe_stream_source_realign #(",
             "  // MUTANT sr_%s -- violates %s: %s\n  hwpe_stream_source_realign #("
             % (tag, clause, note), "%s/mark" % tag)
    blocks.append(b)

# ---------------------------------------------------------------------------
# TIER-B 5c: the same eight defects re-derived on the POLICY-DIVERGENT
# implementation, which makes every beat wait for the sink and drives a fixed
# pattern while pop_valid_o is low. A verdict that differs between the two bases
# means the mutant perturbs latitude rather than contract. The perturbation also
# serves as dut2, generated here so the two cannot drift.
# ---------------------------------------------------------------------------
CONF = os.path.join(TASK, "conformant", "conformant_perturbations.sv")
conf = open(CONF, encoding="utf-8").read()

CASE = """      3'd0:    joined = cur;
      3'd1:    joined = {cur[23:0], prev[31:24]};
      3'd2:    joined = {cur[15:0], prev[31:16]};
      3'd3:    joined = {cur[7:0],  prev[31:8]};
      default: joined = prev;                     // r == 4: a whole beat"""
CASE_REV = """      3'd0:    joined = prev;
      3'd1:    joined = {prev[23:0], cur[31:24]};
      3'd2:    joined = {prev[15:0], cur[31:16]};
      3'd3:    joined = {prev[7:0],  cur[31:8]};
      default: joined = cur;"""
PRODUCE = "  wire produce = realign_i ? (push_valid_i && !first_i && (last_i || (|strb_i)))"

POLICY = {
 "p1_rotation_off_by_one": [("      if (first_i) rot_q <= popcnt(strb_i);",
                             "      if (first_i) rot_q <= popcnt(strb_i) + 3'd1;")],
 "p2_first_beat_emitted":  [(PRODUCE,
   "  wire produce = realign_i ? (push_valid_i && (last_i || (|strb_i)))")],
 "p3_first_beat_not_retained": [
   ("      held_q <= push_data_i;                       // R2: retained for the next join",
    "      if (!first_i) held_q <= push_data_i;")],
 "p4_rotation_reversed":   [(CASE, CASE_REV)],
 "p5_strobe_passed_through": [
   ("  assign pop_strb_o  = !produce ? 4'h0 : (realign_i ? 4'hF : push_strb_i);",
    "  assign pop_strb_o  = !produce ? 4'h0 : push_strb_i;")],
 "p6_rotation_recaptured": [("      if (first_i) rot_q <= popcnt(strb_i);",
                             "      rot_q <= popcnt(strb_i);")],
 "p7_always_realigns":     [(PRODUCE,
   "  wire produce = 1'b1 ? (push_valid_i && !first_i && (last_i || (|strb_i)))")],
 "p8_last_ignored":        [(PRODUCE,
   "  wire produce = realign_i ? (push_valid_i && !first_i && ((|strb_i)))")],
}
os.makedirs(os.path.join(TASK, "mutants", "policy"), exist_ok=True)
for tag, edits in POLICY.items():
    txt = conf
    for old, new in edits:
        txt = sub1(txt, old, new, "policy/%s" % tag)
    txt = sub1(txt, "module sr_c1_first_beat_waits", "module stream_realign",
               "policy/%s rename" % tag)
    open(os.path.join(TASK, "mutants", "policy", "sr_%s.sv" % tag), "w",
         encoding="utf-8").write(txt)

os.makedirs(os.path.join(TASK, "dut2"), exist_ok=True)
alt = sub1(conf, "module sr_c1_first_beat_waits", "module stream_realign_alt", "dut2/rename")
open(os.path.join(TASK, "dut2", "stream_realign_alt.sv"), "w", encoding="utf-8").write(
    "// GENERATED from conformant/conformant_perturbations.sv by mutants/gen_mutants.py.\n"
    "// Same artefact, two roles: the policy-divergent perturbation that must be\n"
    "// ACCEPTED, and the independent second implementation. Do not edit by hand.\n" + alt)

HEAD = """// v_ai02 mutant set -- these MUST BE CAUGHT. Scoring only, never shipped.
//
// GENERATED by mutants/gen_mutants.py. Do not edit by hand; edit the generator
// so that every defect stays a named, single, auditable change.
"""
open(os.path.join(HERE, "mutants.sv"), "w", encoding="utf-8").write(HEAD + "\n" + "\n".join(blocks))
print("wrote mutants.sv with %d mutants (%d internal, %d shim-level)"
      % (len(blocks), len(INTERNAL), len(SHIMLEVEL)))
