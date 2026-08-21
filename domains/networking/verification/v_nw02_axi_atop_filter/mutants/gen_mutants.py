#!/usr/bin/env python3
"""Generate the v_nw02 mutant set.

Every mutant is a MECHANICAL edit of the golden shim, and where the defect is
internal, of a renamed copy of the anchor. Nothing is hand-written, so a mutant
cannot fail for an incidental reason that has nothing to do with its clause.

Each edit is an exact old -> new string pair, asserted to match exactly once.
A silent no-op here would produce a mutant identical to the golden that every
testbench "kills" by doing nothing, so the count is checked, not assumed.

Run:  python3 mutants/gen_mutants.py     (from the task directory)
"""
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
TASK = os.path.dirname(HERE)
DUT = os.path.join(TASK, "dut")

SHIM = open(os.path.join(DUT, "atop_filter.sv"), encoding="utf-8").read()
ANCHOR = open(os.path.join(DUT, "axi_atop_filter.sv"), encoding="utf-8").read()

# The anchor's interface wrapper is unused here and it `include`s an unguarded
# macro header. Five copies of it in one compilation redefine every macro, so
# the copies keep only the module the shim actually instantiates.
cut = ANCHOR.index('`include "axi/assign.svh"')
ANCHOR_CORE = ANCHOR[:cut].rstrip() + "\n"
assert ANCHOR_CORE.count("endmodule") == 1, "expected exactly one module in the core"


def sub1(text, old, new, what):
    n = text.count(old)
    if n != 1:
        sys.exit("MUTATION %s: pattern occurs %d times, expected exactly 1:\n  %s"
                 % (what, n, old))
    return text.replace(old, new)


def shim_body(name, note):
    """The golden shim, renamed, with its scoring header replaced."""
    body = SHIM[SHIM.index("module atop_filter #("):]
    body = body.replace("module atop_filter #(", "module %s #(" % name, 1)
    return body.replace(
        "  localparam int unsigned MAX_WRITE_TXNS = 4;   // pinned -- see header",
        "  localparam int unsigned MAX_WRITE_TXNS = 4;\n  // MUTANT %s: %s" % (name, note))


# ---------------------------------------------------------------------------
# Internal defects: a renamed copy of the anchor with one edit.
# ---------------------------------------------------------------------------
INTERNAL = {
    "m2": [("if (mst_req_o.w_valid && mst_resp_i.w_ready && mst_req_o.w.last) begin",
            "if (mst_resp_i.b_valid && mst_req_o.b_ready) begin")],
    "m5": [("slv_resp_o.r.last  = (r_beats_q == '0);",
            "slv_resp_o.r.last  = (r_beats_q == '0) || (r_beats_q == r_resp_cmd_pop.len);"),
           ("if (slv_resp_o.r.last) begin",
            "if (r_beats_q == '0) begin")],
    "m6": [("slv_resp_o.r.resp  = axi_pkg::RESP_SLVERR;",
            "slv_resp_o.r.resp  = axi_pkg::RESP_OKAY;")],
    "m7": [("mst_req_o.w_valid  = 1'b0; // Do not let W beats pass to master port.",
            "mst_req_o.w_valid  = slv_req_i.w_valid;"),
           ("        // Absorb all W beats of the current burst.\n"
            "        slv_resp_o.w_ready = 1'b1;",
            "        // Absorb all W beats of the current burst.\n"
            "        slv_resp_o.w_ready = 1'b1;\n"
            "        mst_req_o.w_valid  = slv_req_i.w_valid;")],
    "m8": [("id_d = slv_req_i.aw.id; // Store ID for B response.",
            "id_d = id_q; // MUTANT: the id of this atomic write is never captured")],
}

for tag, edits in INTERNAL.items():
    txt = ANCHOR_CORE
    for old, new in edits:
        txt = sub1(txt, old, new, "%s/anchor" % tag)
    txt = re.sub(r"\baxi_atop_filter\b", "axi_atop_filter_%s" % tag, txt)
    out = os.path.join(DUT, "axi_atop_filter_%s.sv" % tag)
    open(out, "w", encoding="utf-8").write(txt)

# ---------------------------------------------------------------------------
# The eight mutants.
# ---------------------------------------------------------------------------
MUT = []

# W2 -- the bound itself, off by one upward.
m = shim_body("af_m1_budget_off_by_one",
              "W2: admits a FIFTH outstanding downstream write")
MUT.append(sub1(m, "localparam int unsigned MAX_WRITE_TXNS = 4;",
                "localparam int unsigned MAX_WRITE_TXNS = 5;", "m1"))

# W4 -- the debt is freed by the wrong event.
m = shim_body("af_m2_debt_frees_on_b",
              "W4: the debt falls when a B arrives, not when a W burst completes")
MUT.append(sub1(m, "axi_atop_filter #(", "axi_atop_filter_m2 #(", "m2/inst"))

# C2/F5 -- the read-response obligation read from the wrong bit.
m = shim_body("af_m3_rresp_class_on_bit4",
              "C2: the read-response obligation is taken from atop[4], not atop[5]")
MUT.append(sub1(m, "slv_req.aw.atop   = s_awatop_i;",
                "slv_req.aw.atop   = {s_awatop_i[4], s_awatop_i[5], s_awatop_i[3:0]};", "m3"))

# F4 -- one R beat short, and ONLY when the burst is longer than one beat.
m = shim_body("af_m4_rbeats_short_by_one",
              "F4: a multi-beat atomic write receives awlen R beats, not awlen+1")
MUT.append(sub1(m, "slv_req.aw.len    = s_awlen_i;",
                "slv_req.aw.len    = (s_awatop_i[5:4] != 2'b00 && s_awlen_i != 8'd0)\n"
                "                        ? s_awlen_i - 8'd1 : s_awlen_i;", "m4"))

# F4 -- rlast on the first injected beat as well as the last.
m = shim_body("af_m5_rlast_also_on_first",
              "F4: rlast is asserted on the first injected beat as well as the last")
MUT.append(sub1(m, "axi_atop_filter #(", "axi_atop_filter_m5 #(", "m5/inst"))

# F4 -- the manufactured R beats carry the wrong response code.
m = shim_body("af_m6_rinject_okay",
              "F4: manufactured R beats carry OKAY; the B still carries SLVERR")
MUT.append(sub1(m, "axi_atop_filter #(", "axi_atop_filter_m6 #(", "m6/inst"))

# F2 -- the absorbed W beats are not absorbed.
m = shim_body("af_m7_absorbed_w_forwarded",
              "F2: the W beats of a filtered write also reach the master port")
MUT.append(sub1(m, "axi_atop_filter #(", "axi_atop_filter_m7 #(", "m7/inst"))

# F3/F4 -- the manufactured responses carry a stale id.
m = shim_body("af_m8_stale_response_id",
              "F3/F4: manufactured responses carry the PREVIOUS atomic write's id")
MUT.append(sub1(m, "axi_atop_filter #(", "axi_atop_filter_m8 #(", "m8/inst"))

# ---------------------------------------------------------------------------
# The policy-divergent perturbation is an INDEPENDENT implementation, so it also
# serves as the second DUT. Generated from the one source so the two copies
# cannot drift apart and quietly stop being the same artefact.
# ---------------------------------------------------------------------------
conf_path = os.path.join(TASK, "conformant", "conformant_perturbations.sv")
conf = open(conf_path, encoding="utf-8").read()
alt = sub1(conf, "module af_c1_b_before_r", "module atop_filter_alt", "dut2/rename")
os.makedirs(os.path.join(TASK, "dut2"), exist_ok=True)
open(os.path.join(TASK, "dut2", "atop_filter_alt.sv"), "w", encoding="utf-8").write(
    "// GENERATED from conformant/conformant_perturbations.sv by mutants/gen_mutants.py.\n"
    "// Same artefact, two roles: the policy-divergent perturbation that must be\n"
    "// ACCEPTED, and the independent second implementation. Do not edit by hand.\n" + alt)

# ---------------------------------------------------------------------------
# TIER-B 5c: the same eight defects, re-derived on top of the POLICY-DIVERGENT
# implementation. If a mutant's verdict changes between the two bases, that
# mutant is perturbing latitude rather than contract and does not belong in the
# set. Each file declares `atop_filter` directly and delegates to nothing.
# ---------------------------------------------------------------------------
POLICY = {
    "p1_budget_off_by_one": [("localparam int unsigned MAXW = 4;          // clause W2",
                              "localparam int unsigned MAXW = 5;")],
    "p2_debt_frees_on_b": [("if (m_wvalid_o && m_wready_i && m_wlast_o) debt <= debt - 1;   // clause W4",
                            "if (m_bvalid_i && m_bready_o) debt <= debt - 1;")],
    "p3_rresp_class_on_bit4": [("cap_owes_r <= s_awatop_i[5];        // clause C2",
                                "cap_owes_r <= s_awatop_i[4];")],
    "p4_rbeats_short_by_one": [("RSP_IDLE: if (cap_valid) begin rsp <= RSP_B; rbeat <= 9'(cap_len); end",
                                "RSP_IDLE: if (cap_valid) begin rsp <= RSP_B;\n"
                                "          rbeat <= (cap_len > 0) ? 9'(cap_len) - 9'd1 : 9'd0; end")],
    "p5_rlast_also_on_first": [("s_rlast_o  = (rbeat == 9'd0);",
                                "s_rlast_o  = (rbeat == 9'd0) || (rbeat == 9'(cap_len));")],
    "p6_rinject_okay": [("s_rvalid_o = 1'b1; s_rid_o = cap_id; s_rresp_o = SLVERR;",
                         "s_rvalid_o = 1'b1; s_rid_o = cap_id; s_rresp_o = 2'b00;")],
    "p7_absorbed_w_forwarded": [("assign m_wvalid_o = s_wvalid_i && head_valid && !head_atom;",
                                 "assign m_wvalid_o = s_wvalid_i && head_valid;")],
    "p8_stale_response_id": [("cap_id  <= s_awid_i;", "cap_id  <= cap_id;")],
}
os.makedirs(os.path.join(TASK, "mutants", "policy"), exist_ok=True)
for tag, edits in POLICY.items():
    txt = conf
    for old, new in edits:
        txt = sub1(txt, old, new, "policy/%s" % tag)
    txt = sub1(txt, "module af_c1_b_before_r", "module atop_filter", "policy/%s rename" % tag)
    open(os.path.join(TASK, "mutants", "policy", "af_%s.sv" % tag), "w",
         encoding="utf-8").write(txt)

HEAD = """// v_nw02 mutant set -- these MUST BE CAUGHT. Scoring only, never shipped.
//
// GENERATED by mutants/gen_mutants.py. Do not edit by hand; edit the generator
// so that every defect stays a named, single, auditable change.
"""
open(os.path.join(HERE, "mutants.sv"), "w", encoding="utf-8").write(HEAD + "\n" + "\n".join(MUT))
print("wrote mutants.sv with %d mutants, %d mutated anchor copies, and dut2/atop_filter_alt.sv"
      % (len(MUT), len(INTERNAL)))
