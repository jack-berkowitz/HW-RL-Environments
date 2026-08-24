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
  "the second deferral since reset, and every one after it",
  """  logic g_ready, m_refuse;
  // A REFUSAL, not a delay. Holding valid and ready low together merely defers
  // the offer, and H4 permits deferral -- an earlier version did exactly that
  // and was indistinguishable from correct behaviour. This latches on the
  // offer and holds ready low until the requester GIVES UP and drops valid, so
  // the request must be made again.
  always_ff @(posedge clk_i or negedge rst_ni)
    if (!rst_ni) m_refuse <= 1'b0;
    else if (div_valid_i && g_busy && !g_same && (g_ndefer >= 2)) m_refuse <= 1'b1;
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

M.append(build("cd_m7_gate_idles_high_on_odd", "G2",
  "while gated the output idles HIGH instead of low",
  "the divisor in force is odd",
  """  logic g_clk; logic m_gated, m_seen;
  // gated is inferred from the ports: a change was accepted and no edge has
  // arrived yet
  always_ff @(posedge clk_i or negedge rst_ni)
    if (!rst_ni) begin m_gated <= 1'b0; m_seen <= 1'b0; end
    else begin
      if (div_valid_i && div_ready_o && !g_same) begin m_gated <= 1'b1; m_seen <= 1'b0; end
      if (g_clk) begin m_gated <= 1'b0; m_seen <= 1'b1; end
    end
  assign clk_o = (m_gated && g_div[0]) ? 1'b1 : g_clk;""",
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
