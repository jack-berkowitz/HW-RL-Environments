#!/usr/bin/env python3
"""Generate the v_ai02 mutant set -- GUARDED.

Every mutant is a MECHANICAL edit of the golden shim, and where the defect is
internal, of a renamed copy of the anchor. Each edit is an exact old -> new
string pair asserted to match EXACTLY ONCE, so a silent no-op cannot produce a
mutant identical to the golden that every testbench "kills" by doing nothing.

EVERY DEFECT IS GUARDED. Each is a pair

    wrong_behaviour AND rare_predicate over contract-level state

so it fires only in a configuration a testbench has to CONSTRUCT. A total
defect fires on the first transaction of its class and is therefore caught by
any testbench that exercises the class, whether or not it checks the clause --
it measures coverage, not checking.

Guards read contract-level state ONLY: how many lines have started, how many
beats into the current line, the line's rotation, how long the sink has held
off, how many output beats have been delivered, how many clears have been
seen. Never a register private to the anchor -- step 5c re-derives every defect
on an independently written implementation that has no such registers.

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


# --------------------------------------------------------------------------
# Guard state, inside a renamed copy of the anchor. Counted from this module's
# own PORTS -- ctrl_i.first, the two handshakes, strb_i -- so each guard can be
# restated on any implementation of the same contract.
# --------------------------------------------------------------------------
A_DECL = "  logic int_last_packet;"
A_GUARD = A_DECL + """

  // ---- mutant guard state (contract-level only) ----
  logic [7:0] g_line_q;   // lines started since reset or clear
  logic [7:0] g_beat_q;   // beats accepted so far in the current line
  logic [7:0] g_stall_q;  // consecutive cycles the sink has held off
  logic [1:0] g_rel_q;    // counts down over the cycles just after a long stall
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (~rst_ni) begin
      g_line_q <= '0; g_beat_q <= '0; g_stall_q <= '0; g_rel_q <= 2'd0;
    end else if (clear_i) begin
      g_line_q <= '0; g_beat_q <= '0; g_stall_q <= '0; g_rel_q <= 2'd0;
    end else begin
      if ((g_stall_q >= 8'd4) && !(pop_o.valid & ~pop_o.ready)) g_rel_q <= 2'd3;
      else if (g_rel_q != 2'd0)                                 g_rel_q <= g_rel_q - 2'd1;
      if (pop_o.valid & ~pop_o.ready) g_stall_q <= g_stall_q + 8'd1;
      else                            g_stall_q <= '0;
      if (push_i.valid & push_i.ready) begin
        if (int_first) begin g_line_q <= g_line_q + 8'd1; g_beat_q <= 8'd1; end
        else                 g_beat_q <= g_beat_q + 8'd1;
      end
    end
  end"""

A_OUTGATE = "push_i.valid & ~int_first & (int_last | (|int_strb));"
A_RETAIN  = "else if (~int_last_packet & push_i.valid & push_i.ready)"
A_RECAP   = "else if (~int_last_packet & int_first) begin"
A_LASTOR  = "(int_last | (|int_strb));"
A_ROTCAP  = ("      strb_rotate_q <= strb_rotate_d;\n"
             "      strb_rotate_inv_q <= strb_rotate_inv_d;")

INTERNAL = {
 "m1_rotation_four_when_three": ("R2/R4/R5",
   "a line whose rotation is exactly THREE is realigned at rotation four instead",
   "the line's rotation is exactly 3 -- 0, 1, 2 and 4 are all exact",
   [(A_ROTCAP,
     "      strb_rotate_q <= (strb_rotate_d == 3'd3) ? 3'd4 : strb_rotate_d;\n"
     "      strb_rotate_inv_q <= (strb_rotate_d == 3'd3) ? 3'd4 : strb_rotate_inv_d;")]),
 "m2_first_beat_emitted_from_third_line": ("R1",
   "a line's first beat produces an output beat instead of being retained",
   "the third line since reset or clear, and every line after it",
   [(A_OUTGATE,
     "push_i.valid & (~int_first | (g_line_q >= 8'd2)) & (int_last | (|int_strb));")]),
 "m3_rotation_recaptured_deep_in_line": ("R4",
   "the rotation is recaptured from the current beat's strobe",
   "the fifth beat of a line and every beat after it",
   [(A_RECAP,
     "else if (~int_last_packet & (int_first | (g_beat_q >= 8'd4))) begin")]),
 "m4_retain_skipped_after_stall": ("R5",
   "the beat is not retained, so the next output joins stale data",
   "a beat accepted in the first cycles after the sink held off for four or more",
   [(A_RETAIN,
     "else if (~int_last_packet & push_i.valid & push_i.ready & (g_rel_q == 2'd0))")]),
 "m9_extra_beat_on_late_empty_strobe": ("R2",
   "a beat with an entirely clear strobe produces an output beat anyway",
   "that beat is the fourth or later in its line -- earlier ones are correctly suppressed",
   [(A_OUTGATE,
     "push_i.valid & ~int_first & (int_last | (|int_strb) | (g_beat_q >= 8'd3));")]),
 "m5_last_dropped_on_long_line": ("R6",
   "a final beat with an entirely clear strobe produces no output beat",
   "the line is five beats or longer",
   [(A_LASTOR, "((int_last & (g_beat_q < 8'd5)) | (|int_strb));")]),
}

# --------------------------------------------------------------------------
# Shim-level defects. The mutant shim keeps the golden anchor untouched and
# intercepts its ports, so its guards read the same contract-level state from
# the outside.
# --------------------------------------------------------------------------
S_OUT = """  assign pop_data_o  = pop.data;
  assign pop_strb_o  = pop.strb;
  assign pop_valid_o = pop.valid;
  assign pop.ready   = pop_ready_i;"""

S_GUARD = """  // ---- mutant guard state (contract-level only) ----
  // Read from the INNER instance's handshakes, so transforming an output
  // cannot feed back into the predicate that gates it.
  logic [7:0] g_out_q;    // output beats delivered since reset
  logic [7:0] g_stall_q;  // consecutive cycles the sink has held off
  logic [7:0] g_hold_q;   // cycles of admission still being withheld
  logic [7:0] g_clr_q;    // clears seen -- deliberately NOT cleared by clear_i
  logic       g_realigned_q;
  logic       g_lastbeat_q;
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (~rst_ni) begin
      g_out_q <= '0; g_stall_q <= '0; g_hold_q <= '0; g_clr_q <= '0;
      g_realigned_q <= 1'b0; g_lastbeat_q <= 1'b0;
    end else begin
      if (clear_i)   g_clr_q <= g_clr_q + 8'd1;
      if (realign_i) g_realigned_q <= 1'b1;
      if (push_valid_i & push.ready) g_lastbeat_q <= last_i;
      if (pop.valid & pop.ready) g_out_q <= g_out_q + 8'd1;
      if (pop.valid & ~pop.ready) g_stall_q <= g_stall_q + 8'd1;
      else                        g_stall_q <= '0;
      if ((g_stall_q >= 8'd8) && !(pop.valid & ~pop.ready)) g_hold_q <= 8'd20;
      else if (g_hold_q != 8'd0)                            g_hold_q <= g_hold_q - 8'd1;
    end
  end

"""

SHIMLEVEL = {
 "m6_strb_from_input_on_last_beat": ("R3",
   "pop_strb_o carries push_strb_i instead of all ones",
   "the output beat of a line's LAST beat -- every earlier beat is all ones",
   S_GUARD + """  assign pop_data_o  = pop.data;
  assign pop_strb_o  = (realign_i && last_i && push_valid_i) ? push_strb_i : pop.strb;
  assign pop_valid_o = pop.valid;
  assign pop.ready   = pop_ready_i;"""),
 "m7_drop_every_thirty_second": ("R2/R5",
   "an output beat is consumed internally and never shown to the sink",
   "the thirty-second output beat, and every thirty-second after it",
   S_GUARD + """  wire g_drop = (g_out_q != 8'd0) && (g_out_q % 8'd32 == 8'd31);
  assign pop_data_o  = pop.data;
  assign pop_strb_o  = pop.strb;
  assign pop_valid_o = pop.valid & ~g_drop;
  assign pop.ready   = pop_ready_i | g_drop;"""),
 "m8_passthrough_rotates_after_realign": ("P1",
   "with realign_i low the data path is not transparent -- it is rotated one byte",
   "realign_i has been high at least once since reset",
   S_GUARD + """  assign pop_data_o  = (~realign_i && g_realigned_q)
                       ? {pop.data[23:0], pop.data[31:24]} : pop.data;
  assign pop_strb_o  = pop.strb;
  assign pop_valid_o = pop.valid;
  assign pop.ready   = pop_ready_i;"""),
 "m10_admission_withheld_after_long_stall": ("X3",
   "admission is withheld for twenty cycles although pop_ready_i is high",
   "the sink has just held off for eight or more consecutive cycles",
   S_GUARD + S_OUT),
}

S_PUSHR = "  assign push_ready_o = push.ready;"
S_CLEAR = "    .clk_i, .rst_ni, .test_mode_i (1'b0), .clear_i,"

blocks = []
for tag, (clause, note, guard, edits) in sorted(INTERNAL.items(),
                                                key=lambda kv: int(kv[0].split("_")[0][1:])):
    txt = sub1(ANCHOR, A_DECL, A_GUARD, "%s/guard" % tag)
    for old, new in edits:
        txt = sub1(txt, old, new, "%s/anchor" % tag)
    txt = re.sub(r"\bhwpe_stream_source_realign\b", "hwpe_stream_source_realign_%s" % tag, txt)
    open(os.path.join(DUT, "hwpe_stream_source_realign_%s.sv" % tag), "w",
         encoding="utf-8").write(txt)
    b = sub1(BODY, "module stream_realign (", "module sr_%s (" % tag, "%s/rename" % tag)
    b = sub1(b, "  hwpe_stream_source_realign #(",
             "  // MUTANT sr_%s -- violates %s\n  //   defect: %s\n  //   guard : fires only when %s\n"
             "  hwpe_stream_source_realign_%s #(" % (tag, clause, note, guard, tag), "%s/inst" % tag)
    blocks.append(b)

for tag, (clause, note, guard, outblock) in sorted(SHIMLEVEL.items(),
                                                  key=lambda kv: int(kv[0].split("_")[0][1:])):
    b = sub1(BODY, "module stream_realign (", "module sr_%s (" % tag, "%s/rename" % tag)
    b = sub1(b, S_OUT, outblock, "%s/out" % tag)
    if tag.startswith("m10"):
        b = sub1(b, S_PUSHR,
                 "  assign push_ready_o = push.ready & (g_hold_q == 8'd0);", "%s/pushr" % tag)
    b = sub1(b, "  hwpe_stream_source_realign #(",
             "  // MUTANT sr_%s -- violates %s\n  //   defect: %s\n  //   guard : fires only when %s\n"
             "  hwpe_stream_source_realign #(" % (tag, clause, note, guard), "%s/mark" % tag)
    blocks.append(b)

HDR = ("// GENERATED by mutants/gen_mutants.py -- do not edit by hand.\n"
       "// The v_ai02 mutant set: every defect GUARDED by a rare predicate over\n"
       "// contract-level state. Scoring only, never shipped to a submission.\n\n")
open(os.path.join(HERE, "mutants.sv"), "w", encoding="utf-8").write(HDR + "\n".join(blocks))
print("wrote mutants.sv: %d mutants" % len(blocks))

# --------------------------------------------------------------------------
# TIER-B step 5c. Every defect above is RE-DERIVED on the policy-divergent
# implementation, which is an independent design: an explicit popcount and a
# case-selected join, every beat waiting for the sink (opposite choice on L1),
# and a fixed pattern driven while pop_valid_o is low (opposite choice on L2).
#
# This is the reason guards may only read contract-level state. This base has
# no barrel shifter, no strb FIFO and no int_first -- a guard written over any
# of those could not be restated here, and the defect would be untestable on
# the base that matters most.
# --------------------------------------------------------------------------
POLICY_SRC = open(os.path.join(TASK, "conformant", "conformant_perturbations.sv"),
                  encoding="utf-8").read()

P_PRODUCE = """  wire produce = realign_i ? (push_valid_i && !first_i && (last_i || (|strb_i)))
                           : push_valid_i;"""

P_GUARD = P_PRODUCE + """

  // ---- mutant guard state: the SAME contract-level quantities as the golden
  // base, recomputed from this implementation's own ports.
  logic [7:0] g_line_q, g_beat_q, g_stall_q, g_out_q, g_hold_q;
  logic [1:0] g_rel_q;
  logic       g_realigned_q;
  wire        g_deliver = produce && push_ready_o;
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      g_line_q <= '0; g_beat_q <= '0; g_stall_q <= '0; g_out_q <= '0;
      g_hold_q <= '0; g_rel_q <= 2'd0; g_realigned_q <= 1'b0;
    end else begin
      if (realign_i) g_realigned_q <= 1'b1;
      if ((g_stall_q >= 8'd8) && !(pop_valid_o && !pop_ready_i)) g_hold_q <= 8'd20;
      else if (g_hold_q != 8'd0)                                 g_hold_q <= g_hold_q - 8'd1;
      if (clear_i) begin
        g_line_q <= '0; g_beat_q <= '0; g_stall_q <= '0; g_rel_q <= 2'd0;
      end else begin
        if (pop_valid_o && !pop_ready_i) g_stall_q <= g_stall_q + 8'd1;
        else                             g_stall_q <= '0;
        if ((g_stall_q >= 8'd4) && !(pop_valid_o && !pop_ready_i)) g_rel_q <= 2'd3;
        else if (g_rel_q != 2'd0)                                  g_rel_q <= g_rel_q - 2'd1;
        if (g_deliver) g_out_q <= g_out_q + 8'd1;
        if (push_valid_i && push_ready_o) begin
          if (first_i) begin g_line_q <= g_line_q + 8'd1; g_beat_q <= 8'd1; end
          else                g_beat_q <= g_beat_q + 8'd1;
        end
      end
    end
  end"""

P_ROTCAP  = "      if (first_i) rot_q <= popcnt(strb_i);        // R4: captured at the first beat only"
P_HELD    = "      held_q <= push_data_i;                       // R2: retained for the next join"
P_LASTOR  = "(last_i || (|strb_i))"
P_STRB    = "  assign pop_strb_o  = !produce ? 4'h0 : (realign_i ? 4'hF : push_strb_i);"
P_PASS    = """  assign pop_data_o  = !produce ? 32'hDEAD_BEEF
                     : realign_i ? joined(push_data_i, held_q, rot_q)
                                 : push_data_i;"""
P_PUSHR   = "  assign push_ready_o = pop_ready_i;"
P_VALID   = "  assign pop_valid_o = produce;"

POLICY = {
 "p1_rotation_four_when_three":
   [(P_ROTCAP, "      if (first_i) rot_q <= (popcnt(strb_i) == 3'd3) ? 3'd4 : popcnt(strb_i);")],
 "p2_first_beat_emitted_from_third_line":
   [(P_PRODUCE,
     "  wire produce = realign_i ? (push_valid_i && (!first_i || (g_line_q >= 8'd2))\n"
     "                             && (last_i || (|strb_i)))\n"
     "                           : push_valid_i;")],
 "p3_rotation_recaptured_deep_in_line":
   [(P_ROTCAP, "      if (first_i || (g_beat_q >= 8'd4)) rot_q <= popcnt(strb_i);")],
 "p4_retain_skipped_after_stall":
   [(P_HELD, "      if (g_rel_q == 2'd0) held_q <= push_data_i;")],
 "p5_last_dropped_on_long_line":
   [(P_LASTOR, "((last_i && (g_beat_q < 8'd5)) || (|strb_i))")],
 "p6_strb_from_input_on_last_beat":
   [(P_STRB,
     "  assign pop_strb_o  = !produce ? 4'h0\n"
     "                     : (realign_i && last_i && push_valid_i) ? push_strb_i\n"
     "                     : (realign_i ? 4'hF : push_strb_i);")],
 "p7_drop_every_thirty_second":
   [(P_VALID,
     "  wire g_drop = (g_out_q != 8'd0) && (g_out_q % 8'd32 == 8'd31);\n"
     "  assign pop_valid_o = produce && !g_drop;"),
    (P_PUSHR, "  assign push_ready_o = pop_ready_i || g_drop;")],
 "p8_passthrough_rotates_after_realign":
   [(P_PASS,
     "  assign pop_data_o  = !produce ? 32'hDEAD_BEEF\n"
     "                     : realign_i ? joined(push_data_i, held_q, rot_q)\n"
     "                     : g_realigned_q ? {push_data_i[23:0], push_data_i[31:24]}\n"
     "                                     : push_data_i;")],
 "p9_extra_beat_on_late_empty_strobe":
   [(P_LASTOR, "(last_i || (|strb_i) || (g_beat_q >= 8'd3))")],
 "p10_admission_withheld_after_long_stall":
   [(P_PUSHR, "  assign push_ready_o = pop_ready_i && (g_hold_q == 8'd0);")],
}

os.makedirs(os.path.join(HERE, "policy"), exist_ok=True)
for tag, edits in sorted(POLICY.items(), key=lambda kv: int(kv[0].split("_")[0][1:])):
    txt = sub1(POLICY_SRC, P_PRODUCE, P_GUARD, "policy/%s guard" % tag)
    for old, new in edits:
        txt = sub1(txt, old, new, "policy/%s" % tag)
    txt = sub1(txt, "module sr_c1_first_beat_waits", "module stream_realign",
               "policy/%s rename" % tag)
    open(os.path.join(HERE, "policy", "sr_%s.sv" % tag), "w", encoding="utf-8").write(txt)
print("wrote policy/: %d re-derived defects" % len(POLICY))
