#!/usr/bin/env python3
"""Generate the v_nw02 mutant set.

EVERY MUTANT IS GUARDED. The defect is `wrong_behaviour AND a narrow predicate
on contract-level state`, never the behaviour alone. An unguarded defect fires
on the first transaction of its class, so it measures whether the testbench
exercised the feature -- not whether it checks it. The first version of this set
was unguarded and both submissions that cleared the validity gate scored 8/8.

Guards are written against state the CONTRACT names: the downstream write debt
of clause W1, the burst length of F4, how many atomic writes have been seen, how
close together they arrived. Never an implementation-private encoding -- that
keeps each defect re-derivable on the policy-divergent implementation, which
Tier-B step 5c requires.

Run:  python3 mutants/gen_mutants.py
"""
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
TASK = os.path.dirname(HERE)
DUT = os.path.join(TASK, "dut")
SHIM = open(os.path.join(DUT, "atop_filter.sv"), encoding="utf-8").read()
ANCHOR = open(os.path.join(DUT, "axi_atop_filter.sv"), encoding="utf-8").read()

cut = ANCHOR.index('`include "axi/assign.svh"')
CORE = ANCHOR[:cut].rstrip() + "\n"

DECL = "  id_t  id_d, id_q;"
RBEATS = "          r_beats_d = r_resp_cmd_pop.len;"
RLAST = "        slv_resp_o.r.last  = (r_beats_q == '0);"
RRESP = "        slv_resp_o.r.resp  = axi_pkg::RESP_SLVERR;"
BRESP = "        slv_resp_o.b.resp = axi_pkg::RESP_SLVERR;"
IDCAP = "          id_d = slv_req_i.aw.id; // Store ID for B response."
WDEC = "    if (mst_req_o.w_valid && mst_resp_i.w_ready && mst_req_o.w.last) begin"
AWGATE = "        if (complete_w_without_aw_downstream || (w_cnt_q.cnt < AxiMaxWriteTxns)) begin"
ABSORB = ("        // Absorb all W beats of the current burst.\n"
          "        slv_resp_o.w_ready = 1'b1;")
RRESPBIT = "          if (slv_req_i.aw.atop[axi_pkg::ATOP_R_RESP]) begin"

# helper counters, all derived from things the contract talks about
HELPERS = """  // ---- MUTANT bookkeeping: all of this counts things the CONTRACT names ----
  logic [7:0] atomic_seen_q;     // how many filtered writes so far
  logic [7:0] since_atomic_q;    // cycles since the last filtered write began
  logic [7:0] full_aged_q;       // cycles the write debt has sat at its bound
  wire        aw_is_atomic = slv_req_i.aw_valid
                             && (slv_req_i.aw.atop[5:4] != axi_pkg::ATOP_NONE)
                             && slv_resp_o.aw_ready;
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      atomic_seen_q <= '0; since_atomic_q <= '0; full_aged_q <= '0;
    end else begin
      if (aw_is_atomic) begin
        atomic_seen_q  <= atomic_seen_q + 8'd1;
        since_atomic_q <= '0;
      end else if (since_atomic_q != 8'hFF) since_atomic_q <= since_atomic_q + 8'd1;
      full_aged_q <= (w_cnt_q.cnt == AxiMaxWriteTxns) ? (full_aged_q + 8'd1) : 8'd0;
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
 ("m1_admits_fifth_once_full_has_aged", "W2",
  "a fifth outstanding write is admitted, but only once the debt has sat at its bound for eight cycles",
  [(AWGATE, "        if (complete_w_without_aw_downstream || (w_cnt_q.cnt < AxiMaxWriteTxns)\n"
            "            || (full_aged_q >= 8'd8)) begin")]),

 ("m2_debt_frees_on_b_when_deep", "W4",
  "the debt falls on a B arriving rather than a W burst completing, but only while three or more are outstanding",
  [(WDEC, "    if ((w_cnt_q.cnt >= 3) ? (mst_resp_i.b_valid && mst_req_o.b_ready)\n"
          "                           : (mst_req_o.w_valid && mst_resp_i.w_ready && mst_req_o.w.last)) begin")]),

 ("m3_rresp_class_on_bit4_multibeat", "C2/F5",
  "the read-response obligation is read from atop[4] instead of atop[5], but only for multi-beat writes",
  [(RRESPBIT, "          if ((slv_req_i.aw.len != 8'd0)\n"
              "              ? slv_req_i.aw.atop[4] : slv_req_i.aw.atop[axi_pkg::ATOP_R_RESP]) begin")]),

 ("m4_rbeats_short_on_long_bursts", "F4",
  "a burst of four beats or more receives one beat too few; shorter bursts are exact",
  [(RBEATS, "          r_beats_d = (r_resp_cmd_pop.len >= 8'd3)\n"
            "                      ? (r_resp_cmd_pop.len - 8'd1) : r_resp_cmd_pop.len;")]),

 ("m5_rlast_early_from_second_atomic", "F4",
  "rlast is also asserted on the first injected beat, but only from the second filtered write onward",
  [(RLAST, "        slv_resp_o.r.last  = (r_beats_q == '0)\n"
           "                             || ((atomic_seen_q >= 8'd2)\n"
           "                                 && (r_beats_q == r_resp_cmd_pop.len));"),
   ("        if (slv_req_i.r_ready) begin\n          if (slv_resp_o.r.last) begin",
    "        if (slv_req_i.r_ready) begin\n          if (r_beats_q == '0) begin")]),

 ("m6_rresp_okay_on_final_beat", "F4",
  "the LAST injected R beat carries OKAY; every earlier beat of the same burst is correct",
  [(RRESP, "        slv_resp_o.r.resp  = (r_beats_q == '0)\n"
           "                             ? axi_pkg::RESP_OKAY : axi_pkg::RESP_SLVERR;")]),

 ("m7_last_absorbed_w_leaks", "F2",
  "only the FINAL W beat of a filtered write reaches the master port; the rest are absorbed correctly",
  [(ABSORB, "        // Absorb all W beats of the current burst.\n"
            "        slv_resp_o.w_ready = 1'b1;\n"
            "        mst_req_o.w_valid  = slv_req_i.w_valid & slv_req_i.w.last;")]),

 ("m8_stale_id_when_atomics_close", "F3/F4",
  "the id is not captured when a filtered write follows the previous one within twelve cycles",
  [(IDCAP, "          if (since_atomic_q >= 8'd12) id_d = slv_req_i.aw.id;")]),

 ("m9_b_okay_on_first_atomic", "F3",
  "the manufactured B carries OKAY, but only for the first filtered write after reset",
  [(BRESP, "        slv_resp_o.b.resp = (atomic_seen_q == 8'd1)\n"
           "                            ? axi_pkg::RESP_OKAY : axi_pkg::RESP_SLVERR;")]),

 ("m10_extra_rbeat_on_two_beat_burst", "F4",
  "a two-beat burst receives three beats; every other length is exact",
  [(RBEATS, "          r_beats_d = (r_resp_cmd_pop.len == 8'd1)\n"
            "                      ? (r_resp_cmd_pop.len + 8'd1) : r_resp_cmd_pop.len;")]),
]

blocks = []
for tag, clause, note, edits in MUT:
    txt = sub1(CORE, DECL, DECL + "\n" + HELPERS, tag + "/helpers")
    for old, new in edits:
        txt = sub1(txt, old, new, tag + "/anchor")
    txt = re.sub(r"\baxi_atop_filter\b", "axi_atop_filter_%s" % tag, txt)
    open(os.path.join(DUT, "axi_atop_filter_%s.sv" % tag), "w", encoding="utf-8").write(txt)

    b = SHIM[SHIM.index("module atop_filter #("):]
    b = sub1(b, "module atop_filter #(", "module af_%s #(" % tag, tag + "/rename")
    b = sub1(b, "  axi_atop_filter #(",
             "  // MUTANT af_%s -- violates %s: %s\n  axi_atop_filter_%s #(" % (tag, clause, note, tag),
             tag + "/inst")
    blocks.append(b)

HEAD = """// v_nw02 mutant set -- these MUST BE CAUGHT. Scoring only, never shipped.
//
// GENERATED by mutants/gen_mutants.py. Every defect is GUARDED: it fires only
// under a narrow predicate on contract-level state, so exercising the feature
// is not enough to find it. Do not edit by hand; edit the generator.
"""
open(os.path.join(HERE, "mutants.sv"), "w", encoding="utf-8").write(HEAD + "\n" + "\n".join(blocks))
print("wrote mutants.sv with %d guarded mutants" % len(blocks))

# ---------------------------------------------------------------------------
# TIER-B 5c: the same ten guarded defects re-derived on the POLICY-DIVERGENT
# implementation, which emits the B before the R beats and makes every beat wait
# for the sink. A verdict that differs between the two bases means the mutant is
# keyed to an implementation choice rather than to the contract.
# ---------------------------------------------------------------------------
CONF = os.path.join(TASK, "conformant", "conformant_perturbations.sv")
conf = open(CONF, encoding="utf-8").read()

ALT_HELPERS = """  logic [8:0] rbeat;
  // ---- MUTANT bookkeeping, on contract-level state only -------------------
  logic [7:0] a_seen_q, a_gap_q, a_full_q;
  wire        a_took = s_awvalid_i && s_awready_o && is_atomic;
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin a_seen_q <= '0; a_gap_q <= '0; a_full_q <= '0; end
    else begin
      if (a_took) begin a_seen_q <= a_seen_q + 8'd1; a_gap_q <= '0; end
      else if (a_gap_q != 8'hFF) a_gap_q <= a_gap_q + 8'd1;
      a_full_q <= (debt >= MAXW) ? (a_full_q + 8'd1) : 8'd0;
    end
  end
"""

A_RBEAT = "  logic [8:0] rbeat;"
A_CANFWD = "  wire can_fwd_aw = (debt < MAXW);"
A_DEBTDEC = "      if (m_wvalid_o && m_wready_i && m_wlast_o) debt <= debt - 1;   // clause W4"
A_OWESR = "          cap_owes_r <= s_awatop_i[5];        // clause C2"
A_IDLE = "        RSP_IDLE: if (cap_valid) begin rsp <= RSP_B; rbeat <= 9'(cap_len); end"
A_RLAST = "      s_rlast_o  = (rbeat == 9'd0);"
A_RRESP = "      s_rvalid_o = 1'b1; s_rid_o = cap_id; s_rresp_o = SLVERR;"
A_MW = "  assign m_wvalid_o = s_wvalid_i && head_valid && !head_atom;"
A_CAPID = "          cap_id  <= s_awid_i;"
A_BRESP = "      s_bvalid_o = 1'b1; s_bid_o = cap_id; s_bresp_o = SLVERR;"

POLICY = {
 "p1_admits_fifth_once_full_has_aged":
   [(A_CANFWD, "  wire can_fwd_aw = (debt < MAXW) || (a_full_q >= 8'd8);")],
 "p2_debt_frees_on_b_when_deep":
   [(A_DEBTDEC, "      if ((debt >= 3) ? (s_bvalid_o && s_bready_i)\n"
                "                      : (m_wvalid_o && m_wready_i && m_wlast_o)) debt <= debt - 1;")],
 "p3_rresp_class_on_bit4_multibeat":
   [(A_OWESR, "          cap_owes_r <= (s_awlen_i != 8'd0) ? s_awatop_i[4] : s_awatop_i[5];")],
 "p4_rbeats_short_on_long_bursts":
   [(A_IDLE, "        RSP_IDLE: if (cap_valid) begin rsp <= RSP_B;\n"
             "          rbeat <= (cap_len >= 8'd3) ? (9'(cap_len) - 9'd1) : 9'(cap_len); end")],
 "p5_rlast_early_from_second_atomic":
   [(A_RLAST, "      s_rlast_o  = (rbeat == 9'd0)\n"
              "                   || ((a_seen_q >= 8'd2) && (rbeat == 9'(cap_len)));")],
 "p6_rresp_okay_on_final_beat":
   [(A_RRESP, "      s_rvalid_o = 1'b1; s_rid_o = cap_id;\n"
              "      s_rresp_o  = (rbeat == 9'd0) ? 2'b00 : SLVERR;")],
 "p7_last_absorbed_w_leaks":
   [(A_MW, "  assign m_wvalid_o = s_wvalid_i && head_valid\n"
           "                      && (!head_atom || s_wlast_i);")],
 "p8_stale_id_when_atomics_close":
   [(A_CAPID, "          if (a_gap_q >= 8'd12) cap_id <= s_awid_i;")],
 "p9_b_okay_on_first_atomic":
   [(A_BRESP, "      s_bvalid_o = 1'b1; s_bid_o = cap_id;\n"
              "      s_bresp_o  = (a_seen_q == 8'd1) ? 2'b00 : SLVERR;")],
 "p10_extra_rbeat_on_two_beat_burst":
   [(A_IDLE, "        RSP_IDLE: if (cap_valid) begin rsp <= RSP_B;\n"
             "          rbeat <= (cap_len == 8'd1) ? (9'(cap_len) + 9'd1) : 9'(cap_len); end")],
}

os.makedirs(os.path.join(TASK, "mutants", "policy"), exist_ok=True)
for tag, edits in POLICY.items():
    txt = sub1(conf, A_RBEAT, ALT_HELPERS, "policy/%s helpers" % tag)
    for old, new in edits:
        txt = sub1(txt, old, new, "policy/%s" % tag)
    txt = sub1(txt, "module af_c1_b_before_r", "module atop_filter", "policy/%s rename" % tag)
    open(os.path.join(TASK, "mutants", "policy", "af_%s.sv" % tag), "w",
         encoding="utf-8").write(txt)
print("wrote %d policy-base mutants" % len(POLICY))
