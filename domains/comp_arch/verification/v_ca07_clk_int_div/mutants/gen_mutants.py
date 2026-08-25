#!/usr/bin/env python3
"""Generate the v_ca07 mutant set -- GUARDED.

Every mutant WRAPS the unmodified golden and reads its guards from the PORTS
only, so each can be restated against any implementation of the contract.

    defect := wrong_behaviour AND rare_predicate over contract-level state

Seven of the ten are ORDINAL or DEPTH conditions -- the Nth reconfiguration, the
Nth same-value request, the Nth reset, divisors above a size, odd divisors only.
That weighting is measured, not assumed: v_nw01 and the incognito v_ai02
submission both show that conditions which are a property of a SINGLE event get
caught and ordinal ones get missed.

Run:  python3 mutants/gen_mutants.py
"""
import os
import re

HERE = os.path.dirname(os.path.abspath(__file__))
TASK = os.path.dirname(HERE)
PORTS = re.search(r"module clk_ratio_div \(.*?^\);",
                  open(os.path.join(TASK, "dut", "clk_ratio_div.sv"),
                       encoding="utf-8").read(), re.S | re.M).group(0)

GUARD = r'''
  // ---- guard state: contract-level only ----------------------------------
  // Counted from this module's PORTS -- the handshake, en_i, rst_ni and the
  // divisor in force. Nothing inside the golden is read.
  logic [3:0] g_div;            // divisor currently in force
  int g_nchange, g_nsame, g_ndefer, g_nen, g_nrst, g_nodd;
  logic g_en_q, g_defer_q;
  int   g_bcnt;
  wire  g_busy = (g_bcnt != 0);
  wire  g_same = div_valid_i && (div_i == g_div);

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      g_div <= 4'd0;            // R2: reset restores the default
      g_nchange <= 0; g_nsame <= 0; g_ndefer <= 0; g_nen <= 0; g_nodd <= 0;
      g_en_q <= 1'b1; g_bcnt <= 0; g_defer_q <= 1'b0;
    end else begin
      g_en_q <= en_i;
      if (en_i != g_en_q) g_nen <= g_nen + 1;
      if (div_valid_i && div_ready_o) begin
        if (g_same) g_nsame <= g_nsame + 1;
        else begin
          g_nchange <= g_nchange + 1;
          g_div     <= div_i;
          g_bcnt    <= 8;
          if (div_i[0] && div_i >= 4'd3) g_nodd <= g_nodd + 1;
        end
      end else if (div_valid_i && g_busy && !g_defer_q) begin
        g_ndefer <= g_ndefer + 1;   // one per EVENT, not per cycle held
      end
      g_defer_q <= div_valid_i && g_busy;
      if (g_bcnt != 0) g_bcnt <= g_bcnt - 1;
    end
  end
  // resets seen, deliberately NOT cleared by reset
  int g_nrst_q = 0;
  always_ff @(negedge rst_ni) g_nrst_q <= g_nrst_q + 1;
'''

def build(name, clause, defect, guard, decls, conn):
    base = {"clk_i":"clk_i","rst_ni":"rst_ni","en_i":"en_i",
            "test_mode_en_i":"test_mode_en_i","div_i":"div_i",
            "div_valid_i":"div_valid_i","div_ready_o":"div_ready_o",
            "clk_o":"clk_o","cycl_count_o":"cycl_count_o"}
    base.update(conn)
    inst = ",\n".join("    .%s(%s)" % (k, v) for k, v in base.items())
    return ("\n// %s\n// %s -- violates %s\n//   defect: %s\n//   guard : fires only when %s\n// %s\n%s%s\n%s\n"
            "  clk_ratio_div i_g (\n%s\n  );\nendmodule\n"
            % ("-"*74, name, clause, defect, guard, "-"*74,
               PORTS.replace("module clk_ratio_div (", "module %s (" % name, 1),
               GUARD, decls, inst))

M = []

M.append(build("cd_m1_period_short_on_large_divisors", "P1",
  "the period is one clk_i cycle shorter than the divisor asks for",
  "the divisor is 8 or more -- every smaller divisor is exact",
  "  wire [3:0] m_div = (div_i >= 4'd8) ? (div_i - 4'd1) : div_i;",
  {"div_i":"m_div"}))

M.append(build("cd_m2_duty_stretched_on_odd", "P2",
  "the high phase is extended by half a clk_i cycle, so an odd divisor is no "
  "longer 50% -- this is the WRONG DUTY RULE this task's own specification "
  "carried until the reference caught it",
  "the divisor is odd AND it is the third odd divisor used or later",
  """  logic g_clk, clk_half;
  always_ff @(negedge clk_i or negedge rst_ni)
    if (!rst_ni) clk_half <= 1'b0; else clk_half <= g_clk;
  wire m_bad = g_div[0] && (g_div >= 4'd3) && (g_nodd >= 3);
  assign clk_o = m_bad ? (g_clk | clk_half) : g_clk;""",
  {"clk_o":"g_clk"}))

M.append(build("cd_m3_one_not_passthrough_after_large", "P3",
  "divisor 1 divides by two instead of passing through",
  "the divisor in force when 1 is requested was 8 or more",
  "  wire [3:0] m_div = ((div_i == 4'd1) && (g_div >= 4'd8)) ? 4'd2 : div_i;",
  {"div_i":"m_div"}))

M.append(build("cd_m4_same_value_gates_from_second", "H3",
  "a same-value request gates the clock, where H3 says it must not",
  "the second same-value request since reset, and every one after it",
  """  logic g_clk; logic [1:0] m_hold;
  wire m_fire = g_same && div_ready_o && (g_nsame >= 1);
  always_ff @(negedge clk_i or negedge rst_ni)
    if (!rst_ni) m_hold <= 2'd0;
    else if (m_fire) m_hold <= 2'd2;
    else if (m_hold != 2'd0) m_hold <= m_hold - 2'd1;
  assign clk_o = g_clk & (m_hold == 2'd0);""",
  {"clk_o":"g_clk"}))

M.append(build("cd_m5_second_request_refused", "H4",
  "a request offered during a transition is REFUSED rather than deferred: its "
  "ready never rises and the requester must offer again",
  "the fourth reconfiguration since reset, and every one after it",
  """  logic g_ready, m_refuse;
  // A REFUSAL, not a delay. Holding valid and ready low together merely defers
  // the offer, and H4 permits deferral -- an earlier version did exactly that
  // and was indistinguishable from correct behaviour. This latches on the
  // offer and holds ready low until the requester GIVES UP and drops valid, so
  // the request must be made again.
  always_ff @(posedge clk_i or negedge rst_ni)
    if (!rst_ni) m_refuse <= 1'b0;
    else if (div_valid_i && g_busy && !g_same && (g_nchange >= 4)) m_refuse <= 1'b1;
    else if (!div_valid_i) m_refuse <= 1'b0;
  assign div_ready_o = g_ready & ~m_refuse;""",
  {"div_ready_o":"g_ready", "div_valid_i":"div_valid_i & ~m_refuse"}))

M.append(build("cd_m6_gate_over_bound_to_passthrough", "G1",
  "the clock is gated one clk_i cycle longer than G1 permits",
  "the change is TO pass-through, where the bound is exactly 3 and therefore "
  "tight -- every other transition has slack and hides it",
  """  logic g_clk; logic [1:0] m_ext; logic m_fire_q;
  // The acceptance is captured on the POSEDGE. Sampling div_ready_o on the
  // negedge races a testbench that deasserts div_valid_i at that same edge, and
  // the latch simply never fired -- the mutant behaved exactly like the golden.
  always_ff @(posedge clk_i or negedge rst_ni)
    if (!rst_ni) m_fire_q <= 1'b0;
    else m_fire_q <= div_valid_i && div_ready_o && !g_same && (div_i < 4'd2);
  always_ff @(negedge clk_i or negedge rst_ni)
    if (!rst_ni) m_ext <= 2'd0;
    else if (m_fire_q) m_ext <= 2'd3;   // 2 expired one negedge too early
    else if (m_ext != 2'd0) m_ext <= m_ext - 2'd1;
  assign clk_o = g_clk & (m_ext == 2'd0);""",
  {"clk_o":"g_clk"}))

M.append(build("cd_m7_idle_high_when_disabled_on_odd", "E3",
  "while DISABLED the output idles HIGH instead of low",
  "the divisor in force is odd -- an even divisor disables cleanly",
  """  logic g_clk;
  // The DISABLED state, not the gated one: how long a gate lasts is L2 latitude,
  // so a defect only visible during it is only visible on implementations that
  // gate slowly. The testbench controls how long en_i stays low.
  assign clk_o = (!en_i && g_div[0]) ? 1'b1 : g_clk;""",
  {"clk_o":"g_clk"}))

M.append(build("cd_m8_disable_late_after_four_toggles", "E1",
  "disabling takes two extra clk_i cycles, so edges appear after en_i falls",
  "the fourth en_i transition since reset, and every one after it",
  """  logic m_en_d1, m_en_d2;
  always_ff @(posedge clk_i or negedge rst_ni)
    if (!rst_ni) begin m_en_d1 <= 1'b1; m_en_d2 <= 1'b1; end
    else begin m_en_d1 <= en_i; m_en_d2 <= m_en_d1; end
  wire m_en = (g_nen >= 4) ? m_en_d2 : en_i;""",
  {"en_i":"m_en"}))

M.append(build("cd_m9_counter_wraps_late_on_large", "C1",
  "cycl_count_o reaches div_i instead of wrapping at div_i - 1",
  "the divisor in force is 6 or more",
  """  logic [3:0] g_cnt;
  wire m_bad = (g_div >= 4'd6);
  assign cycl_count_o = (m_bad && (g_cnt == g_div - 4'd1)) ? g_div : g_cnt;""",
  {"cycl_count_o":"g_cnt"}))

M.append(build("cd_m10_reset_keeps_divisor_from_second", "R2",
  "reset leaves the last configured divisor in force instead of restoring the "
  "default",
  "the second reset since power-up, and every one after it",
  """  logic [3:0] m_keep; logic m_restore;
  always_ff @(posedge clk_i) begin
    if (!rst_ni) m_restore <= (g_nrst_q >= 2);
    else if (m_restore && div_ready_o) m_restore <= 1'b0;
  end
  always_ff @(posedge clk_i or negedge rst_ni)
    if (!rst_ni) ; else if (div_valid_i && div_ready_o) m_keep <= div_i;
  wire [3:0] m_div = m_restore ? m_keep : div_i;
  wire       m_val = m_restore ? 1'b1   : div_valid_i;""",
  {"div_i":"m_div", "div_valid_i":"m_val"}))

HDR = ("// GENERATED by mutants/gen_mutants.py -- do not edit by hand.\n"
       "// The v_ca07 mutant set: every defect GUARDED by a rare predicate over\n"
       "// contract-level state. Scoring only, never shipped to a submission.\n")
open(os.path.join(HERE, "mutants.sv"), "w", encoding="utf-8").write(HDR + "".join(M))
print("wrote mutants.sv: %d mutants" % len(M))

# --------------------------------------------------------------------------
# TIER-B step 5c -- IN-SOURCE RE-DERIVATION.
#
# Each of the ten defects is written INTO dut2's OWN SOURCE, as an edit to its
# logic in its own terms -- not as the same wrapper pointed at it. dut2 is an
# independent implementation: a counter and a half-cycle-delayed phase, where
# the anchor is a state machine with its own clock gate.
#
# This is the method that CAN FAIL. A guard that depends on something only the
# anchor has cannot be expressed here, and shows up as a defect the divergent
# base does not catch. v_ca06 used the wrapper method, which holds by
# construction and cannot fail that way; this task was chosen partly because
# dut2 is small enough to make the stronger method affordable.
# --------------------------------------------------------------------------
ALT = open(os.path.join(TASK, "dut2", "clk_ratio_div_alt.sv"), encoding="utf-8").read()

P_GUARD = """  // ---- guard state, in this design's own terms ----------------------------
  int p_nsame, p_nodd, p_ndefer, p_nen, p_nrst, p_nchange;
  logic p_en_q, p_def_q;
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      p_nsame<=0; p_nodd<=0; p_ndefer<=0; p_nen<=0; p_nchange<=0;
      p_en_q<=1'b1; p_def_q<=1'b0;
    end else begin
      p_en_q <= en_i;
      if (en_i != p_en_q) p_nen <= p_nen + 1;
      if ((st == RUN) && div_valid_i) begin
        if (same) p_nsame <= p_nsame + 1;
        else begin
          p_nchange <= p_nchange + 1;
          if (div_i[0] && div_i >= 4'd3) p_nodd <= p_nodd + 1;
        end
      end
      if ((st == GATE) && div_valid_i && !p_def_q) p_ndefer <= p_ndefer + 1;
      p_def_q <= (st == GATE) && div_valid_i;
    end
  end
  int p_nrst_q = 0;
  always_ff @(negedge rst_ni) p_nrst_q <= p_nrst_q + 1;

  // "in transition", READ FROM THE PORTS rather than from st. How long this
  // design's own GATE state lasts is L2 latitude, and keying a defect on it
  // made the defect UNREACHABLE here, because this design leaves GATE almost
  // at once. The window from accepting a change to the first rising edge of
  // the new clock is the CONTRACT's notion and both bases have it.
  logic p_busy, p_clk_q;
  always_ff @(posedge clk_i or negedge rst_ni)
    if (!rst_ni) begin p_busy <= 1'b0; p_clk_q <= 1'b0; end
    else begin
      p_clk_q <= clk_o;
      if (div_valid_i && div_ready_o && !same) p_busy <= 1'b1;
      else if (clk_o && !p_clk_q)              p_busy <= 1'b0;
    end

"""

ANCHOR = "  assign div_ready_o = (st == RUN) && div_valid_i;"

POLICY = {
 "p1_period_short_on_large_divisors": [
   ("          cnt <= (pass || (cnt >= div_q - 4'd1)) ? '0 : cnt + 4'd1;",
    "          cnt <= (pass || (cnt >= (div_q >= 4'd8 ? div_q - 4'd2 : div_q - 4'd1)))\n"
    "                 ? '0 : cnt + 4'd1;")],
 "p2_duty_stretched_on_odd": [
   ("  wire divided  = odd ? (phase_p & phase_n) : phase_p;",
    "  wire divided  = odd ? ((p_nodd >= 3) ? (phase_p | phase_n) : (phase_p & phase_n))\n"
    "                     : phase_p;")],
 "p3_one_not_passthrough_after_large": [
   ("            div_q     <= div_i;",
    "            div_q     <= ((div_i == 4'd1) && (div_q >= 4'd8)) ? 4'd2 : div_i;")],
 "p4_same_value_gates_from_second": [
   ("          if (div_valid_i && !same) begin",
    "          if (div_valid_i && (!same || (p_nsame >= 1))) begin")],
 "p5_second_request_refused": [
   (ANCHOR,
    "  logic p_refuse;\n"
    "  always_ff @(posedge clk_i or negedge rst_ni)\n"
    "    if (!rst_ni) p_refuse <= 1'b0;\n"
    "    else if (p_busy && div_valid_i && !same && (p_nchange >= 4)) p_refuse <= 1'b1;\n"
    "    else if (!div_valid_i) p_refuse <= 1'b0;\n"
    "  assign div_ready_o = (st == RUN) && div_valid_i && !p_refuse;")],
 "p6_gate_over_bound_to_passthrough": [
   ("            gate_left <= 2'd0;                  // L2: resume as early as legal",
    "            gate_left <= (div_i < 4'd2) ? 2'd2 : 2'd0;")],
 "p7_idle_high_when_disabled_on_odd": [
   ("  assign clk_o  = run_en & gate_src;",
    "  assign clk_o  = (!en_i && odd) ? 1'b1 : (run_en & gate_src);")],
 "p8_disable_late_after_four_toggles": [
   ("    else if (!gate_src) run_en <= en_i && (st == RUN);",
    "    else if (!gate_src) run_en <= ((p_nen >= 4) ? p_en_d2 : en_i) && (st == RUN);")],
 "p9_counter_wraps_late_on_large": [
   ("  assign cycl_count_o = pass ? 4'd0 : cnt;",
    "  assign cycl_count_o = pass ? 4'd0\n"
    "                      : (((div_q >= 4'd6) && (cnt == div_q - 4'd1)) ? div_q : cnt);")],
 "p10_reset_keeps_divisor_from_second": [
   ("      st <= RUN; div_q <= 4'd0; cnt <= '0; gate_left <= '0;   // R2: default divisor",
    "      st <= RUN; cnt <= '0; gate_left <= '0;\n"
    "      if (p_nrst_q < 1) div_q <= 4'd0;   // R2 honoured only the first time")],
}

POL = os.path.join(HERE, "policy")
os.makedirs(POL, exist_ok=True)

# THE GENERATOR OWNS THE DIRECTORY THE 5c RUNNER ENUMERATES. check_policy_
# independence.sh globs policy/*.sv, so a file left behind by an earlier naming
# is graded exactly like a current one and nothing distinguishes them. It happened:
# a re-keyed mutant was renamed, both names were present, and the stale copy had
# been built against a dut2 that has since been corrected. Wiping first means a
# failed generation leaves a file MISSING -- which the runner counts and refuses
# on -- rather than leaving one stale, which it cannot see.
for f in os.listdir(POL):
    if f.endswith(".sv"):
        os.remove(os.path.join(POL, f))

# And every tag is checked BEFORE anything is written, so one bad pattern does
# not stop the loop and leave the tags after it unwritten.
bad = []
for tag, edits in POLICY.items():
    txt = ALT
    if tag.startswith("p8"):
        txt = txt.replace("  logic run_en;", "  logic run_en, p_en_d1, p_en_d2;", 1)
    for old_s, _ in edits:
        n = txt.count(old_s)
        if n != 1:
            bad.append("policy/%s: pattern occurs %d times, expected 1:\n    %s" % (tag, n, old_s))
if bad:
    raise SystemExit("\n".join(bad))

for tag, edits in sorted(POLICY.items(), key=lambda kv: int(kv[0].split("_")[0][1:])):
    txt = ALT.replace(ANCHOR, P_GUARD + ANCHOR, 1)
    if tag.startswith("p8"):
        txt = txt.replace("  logic run_en;",
                          "  logic run_en, p_en_d1, p_en_d2;\n"
                          "  always_ff @(posedge clk_i or negedge rst_ni)\n"
                          "    if (!rst_ni) begin p_en_d1 <= 1'b1; p_en_d2 <= 1'b1; end\n"
                          "    else begin p_en_d1 <= en_i; p_en_d2 <= p_en_d1; end", 1)
    for old_s, new_s in edits:
        txt = txt.replace(old_s, new_s, 1)
    txt = txt.replace("module clk_ratio_div_alt (", "module clk_ratio_div (", 1)
    open(os.path.join(POL, "cd_%s.sv" % tag), "w", encoding="utf-8").write(
        "// step 5c: this defect re-derived IN dut2's OWN SOURCE, not as a wrapper.\n" + txt)
print("wrote policy/: %d in-source re-derivations" % len(POLICY))
