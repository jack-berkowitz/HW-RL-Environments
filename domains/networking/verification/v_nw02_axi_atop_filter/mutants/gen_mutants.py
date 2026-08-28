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
A_M11_AT = '        r_resp_cmd_pop_valid,   r_resp_cmd_pop_ready;\n\n'
A_M11_BLOCK = '  // ---- MUTANT bookkeeping: all of this counts things the CONTRACT names -------\n  // W3 says: while the debt is STRICTLY BELOW AxiMaxWriteTxns, this bound alone\n  // does not stall a non-atomic AW. This mutant stalls one anyway, guarded.\n  //\n  // THE FIRST GUARD WAS MEASURED UNREACHABLE AND IS RECORDED HERE RATHER THAN\n  // QUIETLY REPLACED. It required the debt to sit at exactly bound-1 for eight\n  // CONSECUTIVE cycles. Measured on the reference run: the debt is at bound-1 for\n  // NINE cycles in total, never eight in a row, so the stall was applied ZERO\n  // times and the mutant produced no difference. The witness reported "NO\n  // DIFFERENCE OBSERVED -- treat the HARNESS as suspect" and the harness was\n  // fine. Only the FIRED counters below separated "wrong defect" from "guard the\n  // stimulus never reaches", and d5_withdraws_ar.sv\'s header records the same\n  // failure from the same cause one task over.\n  //\n  // THE GUARD NOW COUNTS THE DEFECT\'S OWN CLASS, which is the shape v_dsp02\'s\n  // mutants use: how many non-atomic AWs have been accepted while the debt was\n  // below the bound. Reachable by construction wherever that class occurs at\n  // all, and still guarded -- a total version would stall the first AW of every\n  // run and any testbench offering an AW would catch it, which measures coverage\n  // rather than checking.\n  wire mut_class = slv_req_i.aw_valid\n                   && (slv_req_i.aw.atop[5:4] == axi_pkg::ATOP_NONE)\n                   && (w_cnt_q.cnt < AxiMaxWriteTxns);\n  // THE COUNTER MUST NOT DEPEND ON THE DEFECT\'S OWN EFFECT. A first version\n  // counted `mut_class && slv_resp_o.aw_ready` -- acceptances -- and stalling\n  // drives aw_ready low, so once the guard fired the counter could never advance\n  // again. It read 0 at the end of a run in which the stall had been applied 184\n  // times. A guard whose own effect suppresses its trigger cannot be reasoned\n  // about from its threshold, so this counts the CLASS OCCURRING, which the\n  // defect does not influence.\n  int unsigned mut_hit_q = 0;\n  always_ff @(posedge clk_i or negedge rst_ni) begin\n    if (!rst_ni)                mut_hit_q <= 0;\n    else if (mut_class)         mut_hit_q <= mut_hit_q + 1;\n  end\n  // THE THRESHOLD IS BOUNDED FROM TWO SIDES AND THE TIGHTER SIDE IS THE WITNESS.\n  // Measured, both with the counters below:\n  //     reference testbench   18 class-cycles with the defect never firing\n  //     nonequiv_tb           5  class-cycles -- it fills the write budget\n  //                              deliberately, and once the debt is AT the bound\n  //                              `mut_class` is false by construction\n  // A guard calibrated on the long random stimulus is unreachable by the short\n  // directed one, and a mutant the equivalence witness cannot distinguish is not\n  // licensable under rule 16 however clearly the reference testbench catches it.\n  // Thresholds of 150 and of 8 both fired ZERO times under nonequiv_tb.\n  //\n  // FOUR IS THE ONLY VALUE THAT SATISFIES BOTH SIDES, and the sweep is recorded\n  // because the two axes are not monotone together:\n  //     threshold 3   witness: difference     reference: 17 violations, 5 ids\n  //     threshold 4   witness: difference     reference: 10 violations, 4 ids\n  //     threshold 5   witness: NO DIFFERENCE  reference: 11 violations, 5 ids\n  //     threshold 6   witness: NO DIFFERENCE  reference: 11 violations, 5 ids\n  // Raising the threshold past four LOSES the witness while making the reference\n  // failure broader, so "tighter guard" and "narrower defect" are not the same\n  // direction here and a value picked on either axis alone is wrong.\n  //\n  // Four is an ORDINAL guard -- the fifth non-atomic AW offered while the debt\n  // is below the bound -- which is the kind the mutant README names as legitimate\n  // alongside counts, run lengths and occupancies. It is reachable by both\n  // stimuli and still requires a testbench to construct the configuration.\n  wire mut_stall_aw = mut_class && (mut_hit_q >= 4);\n\n  // DID THE GUARD EVER FIRE? A mutant that produces no difference is either a\n  // wrong defect or a guard the stimulus never reaches, and the verdict cannot\n  // tell them apart. These counters can, and on the first guard they did.\n  int unsigned n_class = 0, n_fire = 0;\n  always_ff @(posedge clk_i) if (rst_ni) begin\n    if (mut_class)     n_class <= n_class + 1;\n    if (mut_stall_aw)  n_fire  <= n_fire + 1;\n  end\n  final $display("FIRED nc_m11.class_seen %0d", n_class);\n  final $display("FIRED nc_m11.class_accepted %0d", mut_hit_q);\n  final $display("FIRED nc_m11.stall_applied %0d", n_fire);\n\n'
A_M11_GATE = '        // MUTANT: `&& !mut_stall_aw` is the whole defect. The debt is BELOW the\n        // bound, so W3 says this bound alone must not stall the AW -- and it does.\n        if ((complete_w_without_aw_downstream || (w_cnt_q.cnt < AxiMaxWriteTxns))\n            && !mut_stall_aw) begin\n'
A_M12_AT = '  assign aw_without_complete_w_downstream = !w_cnt_q.underflow && (w_cnt_q.cnt > 0);\n'
A_M12_BLOCK = '  localparam int unsigned MUT_ORDINAL = 1;\n\n  // ---- MUTANT bookkeeping: all of this counts things the CONTRACT names -------\n  // W3 says: while the debt is STRICTLY BELOW AxiMaxWriteTxns, this bound alone\n  // does not stall a non-atomic AW. This mutant stalls one anyway, guarded --\n  // and it stalls it at the FURTHEST POINT FROM THE BOUND THERE IS.\n  //\n  // WHY THIS EXISTS WHEN af_m11 ALREADY VIOLATES W3. It does, but only at ONE of\n  // W3\'s two reporting sites. Measured: af_m11 drives W3 from gov_admitted and\n  // NEVER from gov_aw_timeout, which reports X4 instead. The reason is\n  // arithmetic. AxiMaxWriteTxns is 4 and af_m11 fires from the FIFTH non-atomic\n  // AW offered while the debt is below the bound -- by which point four writes\n  // are outstanding, so the debt is AT the bound when the AW finally times out,\n  // and gov_aw_timeout\'s `(debt_now < bound_) ? "W3" : "X4"` takes the other\n  // branch. The stall was below the bound; the TIMEOUT was at it.\n  //\n  // So this guard requires the debt to be EMPTY, not merely below the bound of\n  // four. RELAXING IT TO `<= 1` WAS TRIED AND LOST THE BRANCH: measured, the\n  // stall then begins at a different point in the stimulus, the AW is eventually\n  // accepted, and gov_aw_timeout is never reached at all (W3@aw_timeout 1 -> 0)\n  // while gov_admitted still fires. The exact debt the guard admits is not a\n  // tuning knob here -- it selects WHICH of W3\'s two sites reports. Stalling then keeps it empty -- no\n  // AW is admitted, so nothing can become outstanding -- and the condition\n  // sustains itself through the reference\'s 4000-cycle try_aw window. The debt\n  // is 0 when the timeout fires, which is unambiguously `debt_now < bound_`.\n  //\n  // The guard counts the CLASS OCCURRING, never the defect\'s own effect. af_m11\'s\n  // first counter counted acceptances, and stalling drives aw_ready low, so once\n  // the guard fired the counter could never advance again -- it read 0 at the end\n  // of a run in which the stall had been applied 184 times.\n  wire mut_class = slv_req_i.aw_valid\n                   && (slv_req_i.aw.atop[5:4] == axi_pkg::ATOP_NONE)\n                   && !w_cnt_q.underflow\n                   && (w_cnt_q.cnt == \'0);\n\n  // COUNT PRESENTATIONS, NOT CYCLES. `mut_class` is a CYCLE predicate: aw_valid\n  // is held until the AW is accepted, so an ordinal over cycles counts how long\n  // one AW waited, not how many arrived. Measured on the first version: 8\n  // class-CYCLES in a clean run, and 4304 once the stall held aw_valid high --\n  // and ordinals of 1, 2 and 3 produced byte-identical runs, because all three\n  // are reached inside the first presentation. That is an UNGUARDED defect\n  // wearing an ordinal, and this set exists to avoid exactly that.\n  //\n  // The rising edge counts each presentation once, however long it is held. It\n  // is also not self-suppressing, which is the other trap here: af_m11\'s first\n  // counter counted ACCEPTANCES, and stalling drives aw_ready low, so the guard\n  // silenced its own trigger and read 0 after firing 184 times. Stalling holds\n  // `mut_class` HIGH, so the edge is taken once and the count simply stops --\n  // wrong in the safe direction, and visible in the FIRED counters below.\n  logic mut_class_q = 1\'b0;\n  always_ff @(posedge clk_i or negedge rst_ni)\n    if (!rst_ni) mut_class_q <= 1\'b0; else mut_class_q <= mut_class;\n  wire mut_pres = mut_class && !mut_class_q;\n  int unsigned mut_hit_q = 0;\n  always_ff @(posedge clk_i or negedge rst_ni) begin\n    if (!rst_ni)       mut_hit_q <= 0;\n    else if (mut_pres) mut_hit_q <= mut_hit_q + 1;\n  end\n  // THE ORDINAL IS ONE, AND ONE IS THE ONLY VALUE THAT WORKS. Swept, with the\n  // reference testbench, reading the two W3 sites apart by their message text:\n  //\n  //   ordinal   result            ids                 W3@aw_timeout  W3@admitted\n  //   (none)    PASS              --                       0              0     <- supply probe\n  //   0         FAIL 16           P2 W3 W4 X4              1              1\n  //   1         FAIL 17           P2 W3 W4 X3 X4           1              1     <- chosen\n  //   2         FAIL 11           P2 W3 W4 X3 X4           0              1\n  //   3         PASS              --                       0              0\n  //\n  // CLEAN-RUN SUPPLY IS TWO PRESENTATIONS. That is the whole constraint. Ordinal\n  // 0 is unguarded -- it fires on the first AW of its class, which measures\n  // whether a testbench exercised the class rather than whether it checks. Ordinal\n  // 2 still fires (the stall itself manufactures more presentations, 8 of them)\n  // but LOSES gov_aw_timeout, the branch this mutant exists for. Ordinal 3 is out\n  // of reach entirely. One is the only value that is guarded at all AND reaches\n  // the target site.\n  //\n  // THIS IS SHALLOWER THAN THE REST OF THE SET, which runs 4th to 10th, and the\n  // reason is supply rather than choice: the reference offers exactly two\n  // non-atomic AWs with an empty debt. This set\'s README says the fix for a guard\n  // out of reach is to EXTEND THE REFERENCE and that dialling the guard back is\n  // the fallback -- and that is the right order. It is not taken here because\n  // extending the reference changes the supply for the other eleven mutants,\n  // whose ordinals were calibrated against the current stimulus, and trading a\n  // recalibration of eleven working guards for depth on one is not a judgement to\n  // make unasked. Recorded as a known shallow guard, not as a calibrated one.\n  //\n  // Rule 16, the other side of the bound: nonequiv_tb distinguishes this mutant\n  // from the golden at cycle 139 on s_awready, so it is licensable.\n  wire mut_stall_aw = mut_class && (mut_hit_q >= MUT_ORDINAL);\n\n  // DID THE GUARD EVER FIRE? A mutant that produces no difference is either a\n  // wrong defect or a guard the stimulus never reaches, and the verdict cannot\n  // tell them apart. These counters can, and on af_m11\'s first guard they did.\n  // n_pres has NO reset clause on purpose. mut_hit_q does, and the reference\n  // pulses reset once, late -- so mut_hit_q reads 0 at $finish however many\n  // times it counted. That cost a wrong supply reading on v_dsp02 before it was\n  // understood, and it is the number this measurement depends on.\n  int unsigned n_class = 0, n_fire = 0, n_pres = 0;\n  always_ff @(posedge clk_i) if (rst_ni) begin\n    if (mut_class)    n_class <= n_class + 1;\n    if (mut_pres)     n_pres  <= n_pres  + 1;\n    if (mut_stall_aw) n_fire  <= n_fire  + 1;\n  end\n  final $display("FIRED nc_m12.presentations %0d", n_pres);\n  final $display("FIRED nc_m12.class_seen %0d", n_class);\n  final $display("FIRED nc_m12.class_accepted %0d", mut_hit_q);\n  final $display("FIRED nc_m12.stall_applied %0d", n_fire);\n\n'
A_M12_GATE = '        // MUTANT: `&& !mut_stall_aw` is the whole defect. The debt is EMPTY,\n        // so W3 says this bound alone must not stall the AW -- and it does.\n        if ((complete_w_without_aw_downstream || (w_cnt_q.cnt < AxiMaxWriteTxns))\n            && !mut_stall_aw) begin\n'

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

 ("m11_stalls_aw_below_bound", "W3",
  "a non-atomic AW is stalled while the write debt is strictly below the bound, from the fifth such AW",
  [(A_M11_AT, A_M11_AT + A_M11_BLOCK),
   (AWGATE, A_M11_GATE)]),

 ("m12_stalls_aw_with_no_debt", "W3",
  "a non-atomic AW is stalled with no downstream write outstanding at all, from the second such AW",
  [(A_M12_AT, A_M12_AT + A_M12_BLOCK),
   (AWGATE, A_M12_GATE)]),
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
# ---------------------------------------------------------------------------
# REFUSE TO DELETE MUTANTS THIS GENERATOR DOES NOT KNOW ABOUT.
#
# This line overwrites mutants.sv wholesale from MUT. Any mutant added BY HAND
# is destroyed by it -- silently, and the file it lands in still says "GENERATED
# by mutants/gen_mutants.py" afterwards, so nothing looks wrong.
#
# That is not hypothetical. af_m11 was hand-written on 2026-08-27 to give clause
# W3 a witness, and af_m12 after it to reach W3's second reporting site. Neither
# is in MUT. Worse, mutants/check_policy_independence.sh refuses when the anchor
# and policy sets differ in size and ADVISES "Re-run gen_mutants.py" -- which is
# exactly the mismatch two hand-written mutants create, and running it would
# "fix" the count by deleting them. The advised remedy destroys the work that
# triggered the advice.
#
# So: refuse, loudly, rather than silently drop. Measured before writing this --
# regenerating reproduces all ten generated dut files byte-for-byte, so the fix
# is to ADD the hand-written mutants to MUT, not to work around this check.
_existing = os.path.join(HERE, "mutants.sv")
if os.path.exists(_existing):
    _have = set(re.findall(r"^module (af_m[a-z0-9_]+)", open(_existing, encoding="utf-8").read(), re.M))
    _known = {"af_%s" % t for t, _c, _n, _e in MUT}
    _orphan = sorted(_have - _known)
    if _orphan:
        sys.exit(
            "REFUSING TO REGENERATE: mutants.sv contains %d mutant(s) this\n"
            "generator does not define, and rewriting it would DELETE them:\n"
            "  %s\n"
            "Add them to MUT (and their counterparts to POLICY) rather than\n"
            "removing this check. check_policy_independence.sh's advice to\n"
            "'Re-run gen_mutants.py' on a count mismatch is what this guards."
            % (len(_orphan), "\n  ".join(_orphan)))

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
  // ---- guards for the two W3 re-derivations -------------------------------
  // p11 counts CYCLES of its class, as af_m11 does. p12 counts PRESENTATIONS
  // -- the rising edge -- because af_m12 does: s_awvalid_i is HELD until the AW
  // is accepted, so a cycle ordinal counts how long ONE AW waited rather than
  // how many arrived, and on the anchor that made ordinals 1, 2 and 3
  // indistinguishable. Neither counter reads the defect's own effect.
  wire        b_cls = s_awvalid_i && !is_atomic && (debt < MAXW);
  wire        z_cls = s_awvalid_i && !is_atomic && (debt == 0);
  logic [7:0] b_hit_q, z_hit_q;
  logic       z_cls_q;
  wire        z_pres = z_cls && !z_cls_q;
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin b_hit_q <= '0; z_hit_q <= '0; z_cls_q <= 1'b0; end
    else begin
      z_cls_q <= z_cls;
      if (b_cls)  b_hit_q <= b_hit_q + 8'd1;
      if (z_pres) z_hit_q <= z_hit_q + 8'd1;
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

 # W3 re-derivations. The anchor stalls a non-atomic AW that the debt does not
 # license; here the same defect is expressed on can_fwd_aw, which is this
 # implementation's whole write-admission gate. p11 stalls below the bound from
 # the fifth class-cycle; p12 stalls with the debt EMPTY from the second
 # presentation -- which is the distinction that decides WHICH of W3's two
 # reporting sites fires, not a tuning choice.
 "p11_stalls_aw_below_bound":
   [(A_CANFWD, "  wire can_fwd_aw = (debt < MAXW) && !(b_cls && (b_hit_q >= 8'd4));")],
 "p12_stalls_aw_with_no_debt":
   [(A_CANFWD, "  wire can_fwd_aw = (debt < MAXW) && !(z_cls && (z_hit_q >= 8'd1));")],
}

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
    txt = sub1(conf, A_RBEAT, ALT_HELPERS, "policy/%s helpers" % tag)
    for old, new in edits:
        txt = sub1(txt, old, new, "policy/%s" % tag)
    txt = sub1(txt, "module af_c1_b_before_r", "module atop_filter", "policy/%s rename" % tag)
    open(os.path.join(TASK, "mutants", "policy", "af_%s.sv" % tag), "w",
         encoding="utf-8").write(txt)
print("wrote %d policy-base mutants" % len(POLICY))
