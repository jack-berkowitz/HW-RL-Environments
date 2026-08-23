#!/usr/bin/env python3
"""Generate the v_ca04 mutant set.

EVERY MUTANT IS GUARDED. The defect is not `wrong_behaviour`; it is
`wrong_behaviour AND a narrow predicate on contract-level state`. An unguarded
defect applies on every transaction of its class, so the first transaction that
touches the feature kills it -- which measures COVERAGE, not checking. Measured
on the first version of this set: seven of eight unguarded mutants were caught
by every submission that cleared the validity gate, and the single guarded one
was the only mutant in the project to discriminate.

Guards are stated in terms of state the CONTRACT names -- how many inputs are
contending, how long an output has been stalled, whether an output was idle,
what a payload carries -- never an implementation-private register. That keeps
each defect re-derivable on the policy-divergent implementation, which Tier-B
step 5c requires.

Four mutants edit the arbiter source directly; six add state to the shim and
transform the core's outputs. Both are real design changes; neither is input
remapping, which cannot express a guard at all.

Run:  python3 mutants/gen_mutants.py
"""
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
TASK = os.path.dirname(HERE)
DUT = os.path.join(TASK, "dut")

SHIM = open(os.path.join(DUT, "route_xbar.sv"), encoding="utf-8").read()
ARB = open(os.path.join(DUT, "rr_arb_tree.sv"), encoding="utf-8").read()
XBAR = open(os.path.join(DUT, "stream_xbar.sv"), encoding="utf-8").read()
BODY = SHIM[SHIM.index("module route_xbar #("):]

RR_D = "        assign rr_d     = (gnt_i && req_o) ? next_idx  : rr_q;"
LOCK_D = "        assign lock_d     = req_o & ~gnt_i;"


def sub1(text, old, new, what):
    n = text.count(old)
    if n != 1:
        sys.exit("MUTATION %s: pattern occurs %d times, expected exactly 1:\n  %s"
                 % (what, n, old))
    return text.replace(old, new)


# ---------------------------------------------------------------------------
# Shim template: the core's outputs land on core_* wires, and a per-mutant
# block computes the module outputs from them. The identity transform below
# reproduces the golden exactly; each mutant replaces one line of it.
# ---------------------------------------------------------------------------
IDENTITY = """
  // ---- interception point -------------------------------------------------
  logic [N_IN-1:0]      core_in_ready;
  payload_t [N_OUT-1:0] core_d_o;
  idx_t     [N_OUT-1:0] core_x_o;
  logic [N_OUT-1:0]     core_valid_o;
  logic [N_OUT-1:0]     core_ready_i;

  // observable state the guards are written against
  logic [N_OUT-1:0][7:0] stall_cnt;      // cycles this output has been stalled
  logic [N_OUT-1:0]      was_idle;       // this output was idle last cycle
  int                    n_target [N_OUT];  // inputs currently targeting each output

  always_comb begin
    for (int unsigned j = 0; j < N_OUT; j++) begin
      n_target[j] = 0;
      for (int unsigned k = 0; k < N_IN; k++)
        if (in_valid_i[k] && int'(in_sel_i[k*SEL_W +: SEL_W]) == int'(j)) n_target[j]++;
    end
  end

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      stall_cnt <= '0; was_idle <= '1;
    end else begin
      for (int unsigned j = 0; j < N_OUT; j++) begin
        if (core_valid_o[j] && !out_ready_i[j]) stall_cnt[j] <= stall_cnt[j] + 8'd1;
        else                                    stall_cnt[j] <= 8'd0;
        was_idle[j] <= !core_valid_o[j];
      end
    end
  end

  assign in_ready_o   = core_in_ready;
  assign core_ready_i = out_ready_i;
  always_comb begin
    for (int unsigned j = 0; j < N_OUT; j++) begin
      out_valid_o[j] = core_valid_o[j];
      mo_d[j] = core_d_o[j];
      mo_x[j] = core_x_o[j];
    end
  end
"""

# the shim's own output unpack, rewritten to read the (possibly corrupted) mo_*
UNPACK_OLD = """  always_comb begin
    for (int unsigned j = 0; j < N_OUT; j++) begin
      out_data_o[j*DATA_W +: DATA_W] = d_o[j];
      out_idx_o [j*IDX_W  +: IDX_W]  = x_o[j];
    end
  end"""
UNPACK_NEW = """  payload_t [N_OUT-1:0] mo_d;
  idx_t     [N_OUT-1:0] mo_x;
  always_comb begin
    for (int unsigned j = 0; j < N_OUT; j++) begin
      out_data_o[j*DATA_W +: DATA_W] = mo_d[j];
      out_idx_o [j*IDX_W  +: IDX_W]  = mo_x[j];
    end
  end"""

CONN_OLD = """    .data_o  (d_o),
    .idx_o   (x_o),
    .valid_o (out_valid_o),
    .ready_i (out_ready_i)"""
CONN_NEW = """    .data_o  (core_d_o),
    .idx_o   (core_x_o),
    .valid_o (core_valid_o),
    .ready_i (core_ready_i)"""


def shim_mutant(tag, clause, note, transforms, extra=""):
    b = BODY
    b = sub1(b, ".ready_o (in_ready_o),", ".ready_o (core_in_ready),", tag + "/ready")
    b = sub1(b, CONN_OLD, CONN_NEW, tag + "/conn")
    b = sub1(b, UNPACK_OLD, UNPACK_NEW, tag + "/unpack")
    b = sub1(b, "  payload_t [N_OUT-1:0] d_o;\n  idx_t     [N_OUT-1:0] x_o;",
             "  payload_t [N_OUT-1:0] d_o;   // unused in this variant\n"
             "  idx_t     [N_OUT-1:0] x_o;", tag + "/decl")
    b = b.replace("endmodule", IDENTITY + extra + "\nendmodule")
    for i, (told, tnew) in enumerate(transforms):
        b = sub1(b, told, tnew, "%s/transform%d" % (tag, i))
    b = sub1(b, "module route_xbar #(", "module xb_%s #(" % tag, tag + "/rename")
    return b.replace("  ) i_xbar (",
                     "  ) i_xbar (   // MUTANT xb_%s -- violates %s: %s" % (tag, clause, note))


def arb_mutant(tag, clause, note, edits):
    a = ARB
    for old, new in edits:
        a = sub1(a, old, new, tag + "/arb")
    a = re.sub(r"\brr_arb_tree\b", "rr_arb_tree_%s" % tag, a)
    open(os.path.join(DUT, "rr_arb_tree_%s.sv" % tag), "w", encoding="utf-8").write(a)
    x = re.sub(r"\bstream_xbar\b", "stream_xbar_%s" % tag, XBAR)
    x = sub1(x, "rr_arb_tree #(", "rr_arb_tree_%s #(" % tag, tag + "/xbar")
    open(os.path.join(DUT, "stream_xbar_%s.sv" % tag), "w", encoding="utf-8").write(x)
    b = sub1(BODY, "  stream_xbar #(", "  stream_xbar_%s #(" % tag, tag + "/inst")
    b = sub1(b, "module route_xbar #(", "module xb_%s #(" % tag, tag + "/rename")
    return b.replace("  ) i_xbar (",
                     "  ) i_xbar (   // MUTANT xb_%s -- violates %s: %s" % (tag, clause, note))


BLOCKS = []

# ---- arbiter-source mutants ------------------------------------------------
BLOCKS.append(arb_mutant(
    "m1_fairness_freeze_at_three", "A2",
    "the rotation freezes when EXACTLY three inputs contend; four-way is perfect",
    [(RR_D, "        // MUTANT: the rotation does not advance at three contenders\n"
            "        assign rr_d     = (gnt_i && req_o && ($countones(req_d) != 3))\n"
            "                          ? next_idx  : rr_q;")]))

BLOCKS.append(arb_mutant(
    "m2_rotation_skips_on_fourth_wrap", "A2",
    "every FOURTH wrap of the rotation lands one place past input 0, skipping its turn",
    [("      idx_t rr_d;",
      "      idx_t rr_d;\n"
      "      logic [1:0] wrap_q;   // MUTANT: which wrap of the rotation we are in\n"
      "      always_ff @(posedge clk_i or negedge rst_ni)\n"
      "        if (!rst_ni) wrap_q <= '0;\n"
      "        else if (gnt_i && req_o && (next_idx == '0)) wrap_q <= wrap_q + 2'd1;"),
     (RR_D, "        // MUTANT: one wrap in four lands past where it should\n"
            "        assign rr_d     = (gnt_i && req_o)\n"
            "                          ? (((next_idx == '0) && (wrap_q == 2'd3))\n"
            "                             ? idx_t'(1) : next_idx) : rr_q;")]))

BLOCKS.append(arb_mutant(
    "m3_lock_released_after_long_stall", "A3",
    "an offered beat may be re-aimed, but only once its output has stalled eight cycles",
    [("        logic  lock_d, lock_q;",
      "        logic  lock_d, lock_q;\n"
      "        logic [7:0] stall_q;   // MUTANT: how long this decision has waited"),
     (LOCK_D,
      "        // MUTANT: the decision stops being held after eight stalled cycles\n"
      "        assign lock_d     = req_o & ~gnt_i & (stall_q < 8'd8);"),
     ("        always_ff @(posedge clk_i or negedge rst_ni) begin : p_lock_reg",
      "        always_ff @(posedge clk_i or negedge rst_ni)\n"
      "          if (!rst_ni) stall_q <= '0;\n"
      "          else stall_q <= (req_o & ~gnt_i) ? stall_q + 8'd1 : 8'd0;\n"
      "        always_ff @(posedge clk_i or negedge rst_ni) begin : p_lock_reg")]))

BLOCKS.append(arb_mutant(
    "m4_starves_input_two_every_eleventh_turn", "A2",
    "input 2 loses its turn once in every eleven rotations",
    [("      idx_t rr_d;",
      "      idx_t rr_d;\n"
      "      logic [3:0] turn_q;   // MUTANT: which rotation we are in\n"
      "      always_ff @(posedge clk_i or negedge rst_ni)\n"
      "        if (!rst_ni) turn_q <= '0;\n"
      "        else if (gnt_i && req_o && (next_idx == '0))\n"
      "          turn_q <= (turn_q == 4'd10) ? 4'd0 : turn_q + 4'd1;"),
     (RR_D, "        // MUTANT: every fifth rotation, priority jumps past input 2\n"
            "        assign rr_d     = (gnt_i && req_o)\n"
            "                          ? (((turn_q == 4'd10) && (next_idx == idx_t'(2)))\n"
            "                             ? idx_t'(3) : next_idx) : rr_q;"),
     ]))

# ---- shim-logic mutants ----------------------------------------------------
BLOCKS.append(shim_mutant(
    "m5_idx_stale_after_long_idle", "R3",
    "out_idx_o names the PREVIOUS source, but only after that output has been idle eight cycles",
    [("      mo_x[j] = core_x_o[j];",
      "      mo_x[j] = (idle_cnt[j] >= 8'd8 && core_valid_o[j]) ? last_x[j] : core_x_o[j];")],
    extra="""
  idx_t [N_OUT-1:0] last_x;
  logic [N_OUT-1:0][7:0] idle_cnt;
  always_ff @(posedge clk_i or negedge rst_ni)
    if (!rst_ni) idle_cnt <= '0;
    else for (int unsigned j = 0; j < N_OUT; j++)
      idle_cnt[j] <= core_valid_o[j] ? 8'd0 : (idle_cnt[j] + 8'd1);
  always_ff @(posedge clk_i or negedge rst_ni)
    if (!rst_ni) last_x <= '0;
    else for (int unsigned j = 0; j < N_OUT; j++)
      if (core_valid_o[j] && out_ready_i[j]) last_x[j] <= core_x_o[j];
"""))

BLOCKS.append(shim_mutant(
    "m6_swap_pair_under_backpressure", "R5",
    "two beats from one input to one output arrive swapped, but only across a stall",
    [("      mo_d[j] = core_d_o[j];",
      "      mo_d[j] = swap_arm[j] ? held_d[j] : core_d_o[j];")],
    extra="""
  // Holds one beat back across a stall and releases it after the next one, so
  // the pair leaves in the wrong order. Counts, idx and protocol stay correct.
  payload_t [N_OUT-1:0] held_d;
  logic [N_OUT-1:0]     swap_arm;
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin held_d <= '0; swap_arm <= '0; end
    else for (int unsigned j = 0; j < N_OUT; j++) begin
      if (core_valid_o[j] && out_ready_i[j]) begin
        if (swap_arm[j]) swap_arm[j] <= 1'b0;
        else if (stall_cnt[j] >= 8'd2) begin held_d[j] <= core_d_o[j]; swap_arm[j] <= 1'b1; end
      end
    end
  end
"""))

BLOCKS.append(shim_mutant(
    "m7_drop_every_sixty_fourth", "R4",
    "every sixty-fourth beat on an output is silently dropped -- counts, not payloads",
    [("      out_valid_o[j] = core_valid_o[j];",
      "      out_valid_o[j] = core_valid_o[j] && !drop_now[j];"),
     ("  assign core_ready_i = out_ready_i;",
      "  assign core_ready_i = out_ready_i | drop_now;   // consumed, never delivered")],
    extra="""
  logic [N_OUT-1:0] drop_now;
  logic [N_OUT-1:0][6:0] deliv_cnt;
  always_comb begin
    for (int unsigned j = 0; j < N_OUT; j++)
      drop_now[j] = core_valid_o[j] && (deliv_cnt[j] == 7'd63);
  end
  always_ff @(posedge clk_i or negedge rst_ni)
    if (!rst_ni) deliv_cnt <= '0;
    else for (int unsigned j = 0; j < N_OUT; j++)
      if (core_valid_o[j] && (out_ready_i[j] || drop_now[j]))
        deliv_cnt[j] <= (deliv_cnt[j] == 7'd63) ? 7'd0 : deliv_cnt[j] + 7'd1;
"""))

BLOCKS.append(shim_mutant(
    "m8_duplicate_on_stall_release", "R4",
    "the beat released after a stall of four or more cycles is delivered twice",
    [("  assign core_ready_i = out_ready_i;",
      "  assign core_ready_i = out_ready_i & ~dup_hold;")],
    extra="""
  logic [N_OUT-1:0] dup_hold;
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) dup_hold <= '0;
    else for (int unsigned j = 0; j < N_OUT; j++) begin
      if (dup_hold[j]) dup_hold[j] <= 1'b0;
      else if (core_valid_o[j] && out_ready_i[j] && (stall_cnt[j] >= 8'd4))
        dup_hold[j] <= 1'b1;   // withhold the core's ready once, so the sink takes it twice
    end
  end
"""))

BLOCKS.append(shim_mutant(
    "m9_misroute_under_full_collision", "R1",
    "a beat lands on the next output along, but only while ALL FOUR inputs target one output",
    [("      s_i[k] = in_sel_i[k*SEL_W  +: SEL_W];",
      "      s_i[k] = (n_target[in_sel_i[k*SEL_W +: SEL_W]] == N_IN)\n"
      "               ? SEL_W'((in_sel_i[k*SEL_W +: SEL_W] + 1) % N_OUT)\n"
      "               : in_sel_i[k*SEL_W  +: SEL_W];")]))

BLOCKS.append(shim_mutant(
    "m10_ready_glitch_when_all_stalled", "I2",
    "input 0 is accepted for one cycle although nothing can take its beat, when every output is stalled",
    [("  assign in_ready_o   = core_in_ready;",
      "  assign in_ready_o   = core_in_ready | N_IN'(glitch);")],
    extra="""
  logic glitch;
  always_ff @(posedge clk_i or negedge rst_ni)
    if (!rst_ni) glitch <= 1'b0;
    else glitch <= (&(core_valid_o & ~out_ready_i)) && !glitch;
"""))

HEAD = """// v_ca04 mutant set -- these MUST BE CAUGHT. Scoring only, never shipped.
//
// GENERATED by mutants/gen_mutants.py. Every defect is GUARDED: it fires only
// under a narrow predicate on contract-level state, so exercising the feature
// is not enough to find it. Do not edit by hand; edit the generator.
"""
open(os.path.join(HERE, "mutants.sv"), "w", encoding="utf-8").write(
    HEAD + "\n" + "\n".join(BLOCKS))
print("wrote mutants.sv with %d guarded mutants" % len(BLOCKS))

# ---------------------------------------------------------------------------
# TIER-B 5c: the same ten guarded defects re-derived on the POLICY-DIVERGENT
# crossbar, which rotates DOWNWARD and REGISTERS its outputs. A verdict that
# differs between the two bases means the mutant is keyed to an implementation
# choice rather than to the contract. The guards below are written against the
# same contract-level state -- contender count, stall length, idle length,
# delivery count -- which is what makes them expressible on both.
# ---------------------------------------------------------------------------
CONF = os.path.join(TASK, "conformant", "conformant_perturbations.sv")
conf = open(CONF, encoding="utf-8").read()

ALT_HELPERS = """  // ---- MUTANT bookkeeping, on contract-level state only -------------------
  logic [N_OUT-1:0][7:0] mstall, midle;
  logic [N_OUT-1:0][6:0] mdeliv;
  logic [N_OUT-1:0][3:0] mturn;
  int mtarget [N_OUT];
  always_comb begin
    for (int unsigned j = 0; j < N_OUT; j++) begin
      mtarget[j] = 0;
      for (int unsigned k = 0; k < N_IN; k++)
        if (in_valid_i[k] && sel_of(int'(k)) == int'(j)) mtarget[j]++;
    end
  end
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin mstall <= '0; midle <= '0; mdeliv <= '0; mturn <= '0; end
    else for (int unsigned j = 0; j < N_OUT; j++) begin
      mstall[j] <= (held_v[j] && !out_ready_i[j]) ? (mstall[j] + 8'd1) : 8'd0;
      midle[j]  <= held_v[j] ? 8'd0 : (midle[j] + 8'd1);
      if (held_v[j] && out_ready_i[j]) begin
        mdeliv[j] <= (mdeliv[j] == 7'd63) ? 7'd0 : (mdeliv[j] + 7'd1);
        mturn[j]  <= (mturn[j] == 4'd10) ? 4'd0 : (mturn[j] + 4'd1);
      end
    end
  end

"""

ROT   = "          rot[j]    <= IDX_W'((grant_k[j] + int'(N_IN) - 1) % int'(N_IN));"
CANT  = "      can_take[j] = !held_v[j] || out_ready_i[j];"
HELDX = "          held_x[j] <= IDX_W'(grant_k[j]);"
HELDD = "          held_d[j] <= in_data_i[grant_k[j]*DATA_W +: DATA_W];"
CLEAR = "        if (held_v[j] && out_ready_i[j]) held_v[j] <= 1'b0;"
SELOF = "    return int'(in_sel_i[k*SEL_W +: SEL_W]);"
INRDY = "        in_ready_o[k] = 1'b1;"
OUTV  = "  assign out_valid_o = held_v;"
DECL  = "  logic [31:0] held_q_unused_marker;"

POLICY = {
 "p1_fairness_freeze_at_three":
   [(ROT, "          if (mtarget[j] != 3)\n" + ROT)],
 "p2_rotation_skips_on_fourth_wrap":
   [(ROT, "          rot[j]    <= ((grant_k[j] == 0) && (mturn[j][1:0] == 2'd3))\n"
          "                       ? IDX_W'(N_IN - 2)\n"
          "                       : IDX_W'((grant_k[j] + int'(N_IN) - 1) % int'(N_IN));")],
 "p3_lock_released_after_long_stall":
   [(CANT, "      can_take[j] = !held_v[j] || out_ready_i[j] || (mstall[j] >= 8'd8);")],
 "p4_starves_input_two_every_eleventh_turn":
   [(ROT, "          rot[j]    <= ((mturn[j] == 4'd10) && (grant_k[j] == 3))\n"
          "                       ? IDX_W'(1)\n"
          "                       : IDX_W'((grant_k[j] + int'(N_IN) - 1) % int'(N_IN));")],
 "p5_idx_stale_after_long_idle":
   [(HELDX, "          held_x[j] <= (midle[j] >= 8'd8) ? held_x[j] : IDX_W'(grant_k[j]);")],
 "p6_swap_pair_under_backpressure":
   [(HELDD, "          held_d[j] <= (mstall[j] >= 8'd2) ? held_d[j]\n"
            "                       : in_data_i[grant_k[j]*DATA_W +: DATA_W];")],
 "p7_drop_every_sixty_fourth":
   [(OUTV, "  assign out_valid_o = held_v & ~mdrop;\n"
           "  logic [N_OUT-1:0] mdrop;\n"
           "  always_comb for (int unsigned j = 0; j < N_OUT; j++)\n"
           "    mdrop[j] = held_v[j] && (mdeliv[j] == 7'd63);"),
    (CLEAR, "        if (held_v[j] && (out_ready_i[j] || mdrop[j])) held_v[j] <= 1'b0;")],
 "p8_duplicate_on_stall_release":
   [(CANT, "      // mdup is a REGISTER, so on the very cycle the duplicate is decided it\n"
           "      // is still low. Without the combinational term below, a fresh beat\n"
           "      // overwrites the one that was supposed to be repeated and the defect\n"
           "      // silently undoes itself.\n"
           "      can_take[j] = (!held_v[j] || out_ready_i[j]) && !mdup[j] && !mdup_now[j];"),
    (CLEAR, "        if (held_v[j] && out_ready_i[j]) begin\n"
            "          if (mdup[j]) begin held_v[j] <= 1'b0; mdup[j] <= 1'b0; end\n"
            "          else if (mstall[j] >= 8'd4) mdup[j] <= 1'b1;\n"
            "          else held_v[j] <= 1'b0;\n"
            "        end"),
    (OUTV, OUTV + "\n"
           "  logic [N_OUT-1:0] mdup;\n"
           "  logic [N_OUT-1:0] mdup_now;\n"
           "  always_comb for (int unsigned j = 0; j < N_OUT; j++)\n"
           "    mdup_now[j] = held_v[j] && out_ready_i[j] && (mstall[j] >= 8'd4) && !mdup[j];")],
 "p9_misroute_under_full_collision":
   [(SELOF, "    if (mtarget[int'(in_sel_i[k*SEL_W +: SEL_W])] == int'(N_IN))\n"
            "      return (int'(in_sel_i[k*SEL_W +: SEL_W]) + 1) % int'(N_OUT);\n"
            "    return int'(in_sel_i[k*SEL_W +: SEL_W]);")],
 "p10_ready_glitch_when_all_stalled":
   [(INRDY, "        in_ready_o[k] = 1'b1;"),
    (OUTV, OUTV + "\n"
           "  logic mglitch;\n"
           "  always_ff @(posedge clk_i or negedge rst_ni)\n"
           "    if (!rst_ni) mglitch <= 1'b0;\n"
           "    else mglitch <= (&(held_v & ~out_ready_i)) && !mglitch;")],
}

os.makedirs(os.path.join(TASK, "mutants", "policy"), exist_ok=True)
for tag, edits in POLICY.items():
    txt = conf
    # the helper block goes just before the cache/engine state it observes
    txt = sub1(txt, "  logic [31:0] held_q_unused;" if "held_q_unused" in txt
                    else "  logic [N_OUT-1:0]      grant_v;",
               ALT_HELPERS + "  logic [N_OUT-1:0]      grant_v;", "policy/%s helpers" % tag)
    for old, new in edits:
        txt = sub1(txt, old, new, "policy/%s" % tag)
    if tag == "p10_ready_glitch_when_all_stalled":
        txt = txt.replace("  assign in_ready_o = '0;", "  assign in_ready_o = '0;")
        txt = sub1(txt, "    in_ready_o = '0;",
                   "    in_ready_o = '0;\n    in_ready_o[0] = mglitch;", "policy/%s glitch" % tag)
    txt = sub1(txt, "module xb_c1_registered_down_rotation", "module route_xbar",
               "policy/%s rename" % tag)
    open(os.path.join(TASK, "mutants", "policy", "xb_%s.sv" % tag), "w",
         encoding="utf-8").write(txt)
print("wrote %d policy-base mutants" % len(POLICY))
