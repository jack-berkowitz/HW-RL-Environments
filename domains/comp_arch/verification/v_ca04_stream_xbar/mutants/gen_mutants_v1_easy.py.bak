#!/usr/bin/env python3
"""Generate the v_ca04 mutant set.

Every mutant is a MECHANICAL edit of the golden shim. Each edit is an exact
old -> new string pair asserted to match EXACTLY ONCE: a silent no-op would
produce a mutant identical to the golden that every testbench "kills" by doing
nothing, so the count is checked rather than assumed.

Three of the eight are pure PARAMETER changes on the arbiter. Those are the
honest way to build an arbitration defect: a hand-written faulty crossbar fails
for incidental reasons and isolates nothing.

Run:  python3 mutants/gen_mutants.py
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
TASK = os.path.dirname(HERE)
SHIM = open(os.path.join(TASK, "dut", "route_xbar.sv"), encoding="utf-8").read()
BODY = SHIM[SHIM.index("module route_xbar #("):]

DECL_ANCHOR = "  payload_t [N_IN-1:0]  d_i;"


def sub1(text, old, new, what):
    n = text.count(old)
    if n != 1:
        sys.exit("MUTATION %s: pattern occurs %d times, expected exactly 1:\n  %s"
                 % (what, n, old))
    return text.replace(old, new)


# tag -> (clause, note, [(old,new)...])
MUT = [
 ("m1_fixed_priority", "A2",
  "fixed priority instead of round robin: the lowest-numbered contender always wins",
  [(".ExtPrio     (1'b0),      // internal round robin",
    ".ExtPrio     (1'b1),      // MUTANT: external priority, tied to zero")]),

 ("m2_marginal_starvation", "A2",
  "every input is eventually served, but the rotation only advances every 64 cycles",
  [(".ExtPrio     (1'b0),      // internal round robin",
    ".ExtPrio     (1'b1),      // MUTANT: external, very slowly rotating priority"),
   (".rr_i    ('0),", ".rr_i    ({N_OUT{slow_rr}}),"),
   (DECL_ANCHOR,
    "  logic [7:0] slow_cnt;\n"
    "  logic [1:0] slow_rr;\n"
    "  always_ff @(posedge clk_i or negedge rst_ni)\n"
    "    if (!rst_ni) slow_cnt <= '0; else slow_cnt <= slow_cnt + 8'd1;\n"
    "  assign slow_rr = slow_cnt[7:6];\n" + DECL_ANCHOR)]),

 ("m3_idx_off_by_one", "R3",
  "out_idx_o names the input one place along from the one the beat came from",
  [("      out_idx_o [j*IDX_W  +: IDX_W]  = x_o[j];",
    "      out_idx_o [j*IDX_W  +: IDX_W]  = x_o[j] + IDX_W'(1);")]),

 ("m4_sel_top_bit_dropped", "R1",
  "the top bit of the selector is ignored, so outputs 2 and 3 are unreachable",
  [("      s_i[k] = in_sel_i[k*SEL_W  +: SEL_W];",
    "      s_i[k] = in_sel_i[k*SEL_W  +: SEL_W] & SEL_W'(1);")]),

 ("m5_lockin_off", "A3",
  "an arbitration decision is not locked in: the offered beat can be re-aimed before it moves",
  [(".LockIn      (1'b1)       // an arbitration decision is held until it completes",
    ".LockIn      (1'b0)       // MUTANT: the decision is not held")]),

 ("m6_duplicate_delivery", "R4",
  "the core advances on every SECOND acceptance, so each beat is delivered twice",
  [(".ready_i (out_ready_i)", ".ready_i (core_ready)"),
   (DECL_ANCHOR,
    "  logic [N_OUT-1:0] dup_tog, core_ready;\n"
    "  always_ff @(posedge clk_i or negedge rst_ni)\n"
    "    if (!rst_ni) dup_tog <= '0;\n"
    "    else for (int unsigned j = 0; j < N_OUT; j++)\n"
    "      if (out_valid_o[j] && out_ready_i[j]) dup_tog[j] <= ~dup_tog[j];\n"
    "  assign core_ready = out_ready_i & dup_tog;\n" + DECL_ANCHOR)]),

 ("m7_payload_from_neighbour", "R2",
  "each input's payload is taken from the next input along",
  [("      d_i[k] = in_data_i[k*DATA_W +: DATA_W];",
    "      d_i[k] = in_data_i[((k+1)%N_IN)*DATA_W +: DATA_W];")]),

 ("m8_head_of_line", "I2",
  "no input is accepted unless EVERY output is ready",
  [(".ready_o (in_ready_o),", ".ready_o (core_in_ready),"),
   (DECL_ANCHOR,
    "  logic [N_IN-1:0] core_in_ready;\n"
    "  assign in_ready_o = core_in_ready & {N_IN{&out_ready_i}};\n" + DECL_ANCHOR)]),
]

blocks = []
for tag, clause, note, edits in MUT:
    b = BODY
    for old, new in edits:
        b = sub1(b, old, new, tag)
    b = sub1(b, "module route_xbar #(", "module xb_%s #(" % tag, "%s/rename" % tag)
    b = b.replace("  ) i_xbar (",
                  "  ) i_xbar (   // MUTANT xb_%s -- violates %s: %s" % (tag, clause, note))
    # the mutant shims drive in_ready_o / out_idx_o themselves where they must
    blocks.append(b)

# ---------------------------------------------------------------------------
# TIER-B 5c: the same eight defects re-derived on the POLICY-DIVERGENT
# implementation, which rotates downward and registers its outputs. A verdict
# that differs between the two bases means the mutant perturbs latitude rather
# than contract. The perturbation also serves as dut2, generated here so the
# two cannot drift.
# ---------------------------------------------------------------------------
CONF = os.path.join(TASK, "conformant", "conformant_perturbations.sv")
conf = open(CONF, encoding="utf-8").read()

ROT = "          rot[j]    <= IDX_W'((grant_k[j] + int'(N_IN) - 1) % int'(N_IN));"
CANTAKE = "      can_take[j] = !held_v[j] || out_ready_i[j];"
CLEAR = "        if (held_v[j] && out_ready_i[j]) held_v[j] <= 1'b0;"
CNTDECL = "  logic [N_OUT-1:0]      grant_v;"

POLICY = {
 "p1_fixed_priority": [(ROT, "          rot[j]    <= IDX_W'(N_IN - 1);")],
 "p2_marginal_starvation": [
   (CNTDECL, "  logic [7:0] slow_cnt;\n"
             "  always_ff @(posedge clk_i or negedge rst_ni)\n"
             "    if (!rst_ni) slow_cnt <= '0; else slow_cnt <= slow_cnt + 8'd1;\n" + CNTDECL),
   (ROT, "          rot[j]    <= (slow_cnt == 8'd0)\n"
         "                       ? IDX_W'((grant_k[j] + int'(N_IN) - 1) % int'(N_IN))\n"
         "                       : rot[j];")],
 "p3_idx_off_by_one": [
   ("          held_x[j] <= IDX_W'(grant_k[j]);",
    "          held_x[j] <= IDX_W'(grant_k[j] + 1);")],
 "p4_sel_top_bit_dropped": [
   ("    return int'(in_sel_i[k*SEL_W +: SEL_W]);",
    "    return int'(in_sel_i[k*SEL_W +: SEL_W] & SEL_W'(1));")],
 "p5_reaim_before_transfer": [(CANTAKE, "      can_take[j] = 1'b1;")],
 "p6_duplicate_delivery": [
   (CNTDECL, "  logic [N_OUT-1:0]      dup_t;\n" + CNTDECL),
   (CANTAKE, "      can_take[j] = !held_v[j] || (out_ready_i[j] && dup_t[j]);"),
   (CLEAR, "        if (held_v[j] && out_ready_i[j]) begin\n"
           "          dup_t[j] <= ~dup_t[j];\n"
           "          if (dup_t[j]) held_v[j] <= 1'b0;\n"
           "        end"),
   ("      held_v <= '0;", "      held_v <= '0; dup_t <= '0;")],
 "p7_payload_from_neighbour": [
   ("          held_d[j] <= in_data_i[grant_k[j]*DATA_W +: DATA_W];",
    "          held_d[j] <= in_data_i[((grant_k[j]+1)%int'(N_IN))*DATA_W +: DATA_W];")],
 "p8_head_of_line": [
   ("        in_ready_o[k] = 1'b1;", "        in_ready_o[k] = &out_ready_i;")],
}
os.makedirs(os.path.join(TASK, "mutants", "policy"), exist_ok=True)
for tag, edits in POLICY.items():
    txt = conf
    for old, new in edits:
        txt = sub1(txt, old, new, "policy/%s" % tag)
    txt = sub1(txt, "module xb_c1_registered_down_rotation", "module route_xbar",
               "policy/%s rename" % tag)
    open(os.path.join(TASK, "mutants", "policy", "xb_%s.sv" % tag), "w",
         encoding="utf-8").write(txt)

os.makedirs(os.path.join(TASK, "dut2"), exist_ok=True)
alt = sub1(conf, "module xb_c1_registered_down_rotation", "module route_xbar_alt", "dut2/rename")
open(os.path.join(TASK, "dut2", "route_xbar_alt.sv"), "w", encoding="utf-8").write(
    "// GENERATED from conformant/conformant_perturbations.sv by mutants/gen_mutants.py.\n"
    "// Same artefact, two roles: the policy-divergent perturbation that must be\n"
    "// ACCEPTED, and the independent second implementation. Do not edit by hand.\n" + alt)

HEAD = """// v_ca04 mutant set -- these MUST BE CAUGHT. Scoring only, never shipped.
//
// GENERATED by mutants/gen_mutants.py. Do not edit by hand; edit the generator
// so that every defect stays a named, single, auditable change.
"""
open(os.path.join(HERE, "mutants.sv"), "w", encoding="utf-8").write(
    HEAD + "\n" + "\n".join(blocks))
print("wrote mutants.sv with %d mutants" % len(MUT))
