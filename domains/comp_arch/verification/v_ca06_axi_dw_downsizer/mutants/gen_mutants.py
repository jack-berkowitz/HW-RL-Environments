#!/usr/bin/env python3
"""Generate the v_ca06 mutant set -- GUARDED.

Every mutant WRAPS the unmodified golden and reads its guards from the PORTS
only, so each can be restated against any implementation of the contract.

EVERY DEFECT IS GUARDED:

    wrong_behaviour AND rare_predicate over contract-level state

WHY THESE GUARDS. Two independent measurements -- v_nw01 and the incognito
v_ai02 submission -- show the same split. Conditions that are a property of a
SINGLE transaction get caught: a value, a last beat, a mode. Conditions that are
ORDINAL or DEPTH-based get missed: the third line, the fifth beat, the 32nd
delivery, the eight-cycle stall. So this set is weighted toward ordinals, burst
depth, and repetition.

HOW THE DEFECTS ARE INJECTED. Where a defect concerns the ADDRESS TRANSFORM it
modifies the request PRESENTED TO THE GOLDEN rather than the golden's output.
Rewriting an output would leave the golden internally inconsistent with the
downstream burst it then has to service, and it would HANG rather than fail --
and a hang is not a detection. Modifying the input keeps the golden
self-consistent while the observable transform is wrong against the real
upstream request.

Run:  python3 mutants/gen_mutants.py
"""
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
TASK = os.path.dirname(HERE)
PORTS = re.search(r"module dw_downsizer #\(.*?^\);",
                  open(os.path.join(TASK, "spec", "dw_downsizer_iface.sv"),
                       encoding="utf-8").read(), re.S | re.M).group(0)

GUARD = r'''
  // ---- guard state: contract-level only -----------------------------------
  // Every quantity is counted from this module's PORTS -- transactions
  // accepted, refusals, FIXED single-beat requests, beat indices, downstream
  // beats forwarded. Nothing inside the golden is read.
  localparam int SBY = SLV_DATA_W/8, MBY = MST_DATA_W/8, MSZ = 1;
  function automatic logic [31:0] algn(input logic [31:0] a, input logic [2:0] sz);
    algn = a & ~((32'd1 << sz) - 32'd1);
  endfunction
  function automatic bit is_ref(input logic [1:0] b, input logic [7:0] l);
    is_ref = (b == 2'b10) || ((b == 2'b00) && (l != 8'd0));
  endfunction

  // g_dwbeat is the index WITHIN the current downstream burst and resets with
  // each AW. g_dwtot is CUMULATIVE since reset. A guard that wants "every
  // thirty-second beat delivered" needs the cumulative one: the per-burst index
  // never reaches 31 unless a single burst is that long, and it never is here.
  int g_nread, g_nwrite, g_nref, g_nfix1, g_rbeat, g_dwbeat, g_dwtot, g_upwbeat;
  logic [1:0] g_rburst, g_wburst;
  logic [7:0] g_rlen,  g_wlen;
  logic [2:0] g_rsize, g_wsize;
  logic [31:0] g_raddr, g_waddr;
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      g_nread<=0; g_nwrite<=0; g_nref<=0; g_nfix1<=0; g_rbeat<=0; g_dwbeat<=0; g_dwtot<=0;
      g_upwbeat<=0; g_rburst<='0; g_wburst<='0; g_rlen<='0; g_wlen<='0;
      g_rsize<='0; g_wsize<='0; g_raddr<='0; g_waddr<='0;
    end else begin
      if (s_arvalid && s_arready) begin
        g_nread<=g_nread+1; g_rbeat<=0;
        g_rburst<=s_arburst; g_rlen<=s_arlen; g_rsize<=s_arsize; g_raddr<=s_araddr;
        if (is_ref(s_arburst, s_arlen)) g_nref<=g_nref+1;
        if (s_arburst==2'b00 && s_arlen==8'd0) g_nfix1<=g_nfix1+1;
      end
      if (s_awvalid && s_awready) begin
        g_nwrite<=g_nwrite+1; g_dwbeat<=0; g_upwbeat<=0;
        g_wburst<=s_awburst; g_wlen<=s_awlen; g_wsize<=s_awsize; g_waddr<=s_awaddr;
        if (is_ref(s_awburst, s_awlen)) g_nref<=g_nref+1;
        if (s_awburst==2'b00 && s_awlen==8'd0) g_nfix1<=g_nfix1+1;
      end
      if (s_rvalid && s_rready) g_rbeat <= s_rlast ? 0 : g_rbeat + 1;
      if (m_wvalid && m_wready) begin g_dwbeat <= g_dwbeat + 1; g_dwtot <= g_dwtot + 1; end
      if (s_wvalid && s_wready) g_upwbeat <= s_wlast ? 0 : g_upwbeat + 1;
    end
  end
'''

INST_DEFAULT = {
 "s_awid":"s_awid","s_awaddr":"s_awaddr","s_awlen":"s_awlen","s_awsize":"s_awsize",
 "s_awburst":"s_awburst","s_awvalid":"s_awvalid","s_awready":"s_awready",
 "s_wdata":"s_wdata","s_wstrb":"s_wstrb","s_wlast":"s_wlast","s_wvalid":"s_wvalid",
 "s_wready":"s_wready","s_bid":"s_bid","s_bresp":"s_bresp","s_bvalid":"s_bvalid",
 "s_bready":"s_bready","s_arid":"s_arid","s_araddr":"s_araddr","s_arlen":"s_arlen",
 "s_arsize":"s_arsize","s_arburst":"s_arburst","s_arvalid":"s_arvalid",
 "s_arready":"s_arready","s_rid":"s_rid","s_rdata":"s_rdata","s_rresp":"s_rresp",
 "s_rlast":"s_rlast","s_rvalid":"s_rvalid","s_rready":"s_rready",
 "m_awid":"m_awid","m_awaddr":"m_awaddr","m_awlen":"m_awlen","m_awsize":"m_awsize",
 "m_awburst":"m_awburst","m_awvalid":"m_awvalid","m_awready":"m_awready",
 "m_wdata":"m_wdata","m_wstrb":"m_wstrb","m_wlast":"m_wlast","m_wvalid":"m_wvalid",
 "m_wready":"m_wready","m_bid":"m_bid","m_bresp":"m_bresp","m_bvalid":"m_bvalid",
 "m_bready":"m_bready","m_arid":"m_arid","m_araddr":"m_araddr","m_arlen":"m_arlen",
 "m_arsize":"m_arsize","m_arburst":"m_arburst","m_arvalid":"m_arvalid",
 "m_arready":"m_arready","m_rid":"m_rid","m_rdata":"m_rdata","m_rresp":"m_rresp",
 "m_rlast":"m_rlast","m_rvalid":"m_rvalid","m_rready":"m_rready",
}

def build(name, clause, defect, guard, decls, in_over=None, out_rw=None):
    """in_over: inputs of the GOLDEN rewritten on the way in.
       out_rw : outputs of THIS MODULE rewritten on the way out. The golden's
                value arrives on an inner wire <sig>_i and an assign drives the
                port. Putting the expression in the instance connection instead
                cannot drive a module output -- it leaves the port UNDRIVEN, and
                --lint-only without -Wall does not say so."""
    in_over = in_over or {}
    out_rw  = out_rw  or {}
    conn = dict(INST_DEFAULT)
    conn.update(in_over)
    for sig in out_rw:
        conn[sig] = sig + "_i"
    body = ",\n".join("    .%s(%s)" % (k, v) for k, v in conn.items())
    wires = "\n".join("  %s %s_i;" % (WIDTH[sig], sig) for sig in sorted(out_rw))
    assigns = "\n".join("  assign %s = %s;" % (sig, expr) for sig, expr in out_rw.items())
    return ("\n// %s\n// %s -- violates %s\n//   defect: %s\n//   guard : fires only when %s\n// %s\n%s%s\n%s\n%s\n%s\n"
            "  dw_downsizer #(.ADDR_W(ADDR_W), .ID_W(ID_W), .SLV_DATA_W(SLV_DATA_W),\n"
            "                 .MST_DATA_W(MST_DATA_W), .MAX_READS(MAX_READS)) i_g (\n"
            "    .clk_i, .rst_ni,\n%s\n  );\nendmodule\n"
            % ("-"*74, name, clause, defect, guard, "-"*74,
               PORTS.replace("module dw_downsizer #(", "module %s #(" % name, 1),
               GUARD, decls, wires, assigns, body))

WIDTH = {
  "s_rresp":  "logic [1:0]",
  "s_bresp":  "logic [1:0]",
  "s_rdata":  "logic [SLV_DATA_W-1:0]",
  "s_rlast":  "logic",
  "m_wstrb":  "logic [MST_DATA_W/8-1:0]",
  "m_wlast":  "logic",
  "m_wvalid": "logic",
}

M = []

M.append(build("dw_m1_len_simple_formula_when_unaligned", "B2",
  "the downstream length is computed by dividing the byte count instead of counting the blocks spanned",
  "the request's address is NOT aligned to its own size -- every aligned request is exact",
  "  wire ar_un = (s_araddr != algn(s_araddr, s_arsize));\n"
  "  wire aw_un = (s_awaddr != algn(s_awaddr, s_awsize));",
  in_over={"s_araddr":"ar_un ? algn(s_araddr, s_arsize) : s_araddr",
           "s_awaddr":"aw_un ? algn(s_awaddr, s_awsize) : s_awaddr"}))

M.append(build("dw_m2_size_raised_when_narrow", "B1",
  "the downstream size is forced to the downstream width instead of min(size, width)",
  "the upstream size is NARROWER than the downstream bus -- size 1 and above are exact",
  "  wire ar_n = (s_arsize < 3'(MSZ));\n  wire aw_n = (s_awsize < 3'(MSZ));",
  in_over={"s_arsize":"ar_n ? 3'(MSZ) : s_arsize", "s_awsize":"aw_n ? 3'(MSZ) : s_awsize"}))

M.append(build("dw_m3_len_short_from_eighth_read", "B2",
  "the downstream burst is one beat short",
  "the eighth read since reset and every read after it -- the first seven are exact",
  "  wire ar_sh = (g_nread >= 7) && (s_arlen != 8'd0);",
  in_over={"s_arlen":"ar_sh ? (s_arlen - 8'd1) : s_arlen"}))

M.append(build("dw_m4_fixed_single_refused_from_second", "C3",
  "a FIXED burst of exactly one beat is REFUSED, where C3 says it is served",
  "the second such request and every one after it -- the first is served correctly",
  "  wire ar_f = (s_arburst == 2'b00) && (s_arlen == 8'd0) && (g_nfix1 >= 1);\n"
  "  wire aw_f = (s_awburst == 2'b00) && (s_awlen == 8'd0) && (g_nfix1 >= 1);",
  in_over={"s_arlen":"ar_f ? 8'd1 : s_arlen", "s_awlen":"aw_f ? 8'd1 : s_awlen"}))

M.append(build("dw_m5_refused_served_from_third", "C4",
  "a refused burst is SERVED instead: it issues a downstream transaction and answers OKAY",
  "the third refused burst and every one after it -- the first two are refused correctly",
  "  wire ar_r = is_ref(s_arburst, s_arlen) && (g_nref >= 2);\n"
  "  wire aw_r = is_ref(s_awburst, s_awlen) && (g_nref >= 2);",
  in_over={"s_arburst":"ar_r ? 2'b01 : s_arburst", "s_awburst":"aw_r ? 2'b01 : s_awburst"}))

M.append(build("dw_m6_slverr_only_on_last_beat", "C4",
  "a refused read carries SLVERR only on its FINAL beat; every earlier beat says OKAY",
  "the refused read is three beats or longer, so it HAS earlier beats",
  "  wire r_ref = is_ref(g_rburst, g_rlen) && (g_rlen >= 8'd2);",
  out_rw={"s_rresp":"(r_ref && !s_rlast) ? 2'b00 : s_rresp_i"}))

M.append(build("dw_m7_zero_strobe_beat_dropped_midburst", "E3",
  "a downstream beat whose lanes are all unstrobed is SUPPRESSED instead of emitted",
  "that beat is neither the first nor the last of its burst",
  "  wire w_drop = (m_wstrb_i == '0) && (g_dwbeat != 0) && !m_wlast_i;",
  in_over={"m_wready":"m_wready | w_drop"},
  out_rw={"m_wvalid":"m_wvalid_i & ~w_drop", "m_wstrb":"m_wstrb_i", "m_wlast":"m_wlast_i"}))

M.append(build("dw_m8_strb_wrong_every_thirty_second", "E2",
  "a downstream beat carries the complement of its strobe",
  "the thirty-second downstream write beat, and every thirty-second after it",
  "  wire w_bad = (g_dwtot != 0) && ((g_dwtot % 32) == 31);",
  out_rw={"m_wstrb":"w_bad ? ~m_wstrb_i : m_wstrb_i"}))

M.append(build("dw_m9_rdata_lanes_swapped_deep_in_burst", "D1",
  "two byte lanes of the upstream read data are exchanged",
  "the fifth upstream beat of a response and every beat after it",
  "  wire r_deep = (g_rbeat >= 4);",
  out_rw={"s_rdata":"r_deep ? {s_rdata_i[SLV_DATA_W-1:16], s_rdata_i[7:0], s_rdata_i[15:8]} : s_rdata_i"}))

M.append(build("dw_m10_rlast_withheld_from_sixteenth_read", "D4",
  "the final upstream beat of a response does not carry rlast",
  "the sixteenth read since reset and every read after it",
  "  wire r_no_last = (g_nread >= 15);",
  out_rw={"s_rlast":"r_no_last ? 1'b0 : s_rlast_i"}))

# ---------------------------------------------------------------------------
# THE ELEVENTH. Added to close D6, E6 and D7 -- three contract clauses that were
# exercised by the reference and keyed on by no mutant, so a submission was
# neither rewarded for checking them nor penalised for ignoring them.
#
# It keys on the error the SLAVE returned (m_rresp / m_bresp), never on the
# SLVERR the design manufactures for a refused burst, which never appears on the
# downstream response channels at all. That separation is what keeps this off
# C4's ground, where dw_m5 and dw_m6 already live.
# ---------------------------------------------------------------------------
M.append(build("dw_m11_downstream_error_dropped_from_second", "D6",
  "a downstream error is not propagated: the upstream response says OKAY where the slave returned SLVERR or DECERR",
  "the second downstream error since reset and every one after it -- the first is propagated correctly",
  """  // Counted from the DOWNSTREAM response channels, which carry only errors the
  // slave returned. A refusal's SLVERR is manufactured inside the design and
  // never appears here.
  int   e_n = 0;
  logic e_pr, e_pb;
  always_ff @(posedge clk_i or negedge rst_ni)
    if (!rst_ni) begin e_n <= 0; e_pr <= 1'b0; e_pb <= 1'b0; end
    else begin
      e_n <= e_n + ((m_rvalid && m_rready && (m_rresp != 2'b00)) ? 1 : 0)
                 + ((m_bvalid && m_bready && (m_bresp != 2'b00)) ? 1 : 0);
      if (m_rvalid && m_rready && (m_rresp != 2'b00)) e_pr <= 1'b1;
      else if (s_rvalid && s_rready && s_rlast)       e_pr <= 1'b0;
      if (m_bvalid && m_bready && (m_bresp != 2'b00)) e_pb <= 1'b1;
      else if (s_bvalid && s_bready)                  e_pb <= 1'b0;
    end
  wire e_ar = e_pr && (e_n >= 2);
  wire e_ab = e_pb && (e_n >= 2);""",
  out_rw={"s_rresp":"e_ar ? 2'b00 : s_rresp_i",
          "s_bresp":"e_ab ? 2'b00 : s_bresp_i"}))

# ---------------------------------------------------------------------------
# THE TWELFTH, and it exists because an INDEPENDENT READING OF THIS SPEC GOT IT
# WRONG. dut2 -- written from the specification alone, by a different route --
# forced SLVERR for any downstream error rather than preserving the code, and
# violated D7 the moment D7 became observable. A clause a real independent
# reading got wrong is a clause submissions will get wrong.
#
# It cannot be folded into dw_m11. That mutant ERASES the error, so the beat
# carries no error and cannot test WHICH error it carries -- D6 and E6 fire
# first, on the very beat that would have tested D7. This one leaves an error
# present and changes only its KIND, which is the disjoint behaviour D7 needs.
# ---------------------------------------------------------------------------
M.append(build("dw_m12_error_code_normalised_from_second", "D7",
  "a downstream DECERR is reported upstream as SLVERR -- an error, of the wrong kind, so precedence holds and only the CODE is wrong",
  "the second downstream DECERR since reset and every one after it -- the first is preserved correctly",
  """  // DECERR only, and only where the golden was already going to report an
  // error. Rewriting an OKAY would be dw_m11's defect and would fire D6 first.
  int   d_n = 0;
  logic d_pr, d_pb;
  always_ff @(posedge clk_i or negedge rst_ni)
    if (!rst_ni) begin d_n <= 0; d_pr <= 1'b0; d_pb <= 1'b0; end
    else begin
      d_n <= d_n + ((m_rvalid && m_rready && (m_rresp == 2'b11)) ? 1 : 0)
                 + ((m_bvalid && m_bready && (m_bresp == 2'b11)) ? 1 : 0);
      if (m_rvalid && m_rready && (m_rresp == 2'b11)) d_pr <= 1'b1;
      else if (s_rvalid && s_rready && s_rlast)       d_pr <= 1'b0;
      if (m_bvalid && m_bready && (m_bresp == 2'b11)) d_pb <= 1'b1;
      else if (s_bvalid && s_bready)                  d_pb <= 1'b0;
    end
  wire d_ar = d_pr && (d_n >= 2);
  wire d_ab = d_pb && (d_n >= 2);""",
  out_rw={"s_rresp":"(d_ar && (s_rresp_i == 2'b11)) ? 2'b10 : s_rresp_i",
          "s_bresp":"(d_ab && (s_bresp_i == 2'b11)) ? 2'b10 : s_bresp_i"}))

HDR = ("// GENERATED by mutants/gen_mutants.py -- do not edit by hand.\n"
       "// The v_ca06 mutant set: every defect GUARDED by a rare predicate over\n"
       "// contract-level state. Scoring only, never shipped to a submission.\n")
open(os.path.join(HERE, "mutants.sv"), "w", encoding="utf-8").write(HDR + "".join(M))
print("wrote mutants.sv: %d mutants" % len(M))

# --------------------------------------------------------------------------
# TIER-B step 5c. Every defect above is RE-DERIVED on the policy-divergent
# implementation in dut2/ -- an independent design written from the spec, which
# holds one transaction at a time per direction, registers every path, buffers a
# whole upstream W beat before emitting any downstream beat of it, and drives a
# fixed pattern on payloads while their valid is low. The anchor does the
# opposite on all four.
#
# The re-derivation is the SAME WRAPPER pointed at the other implementation. It
# is available only because every guard reads the PORTS: transactions accepted,
# refusals, beat indices, downstream beats forwarded. A guard that read the
# anchor's internal state could not be restated here at all.
#
# ORDER MATTERS. The inner instantiation is rewritten BEFORE the module
# declaration. Doing it the other way renames the declaration to `dw_downsizer`
# and the instantiation rewrite then catches the declaration too, producing a
# module that instantiates itself -- see FINDINGS F66 for the same hazard from
# the other direction.
# --------------------------------------------------------------------------
POL = os.path.join(HERE, "policy")
os.makedirs(POL, exist_ok=True)

# THE GENERATOR OWNS THE DIRECTORY THE 5c RUNNER ENUMERATES.
# check_policy_independence.sh globs policy/*.sv and grades every file it finds,
# so a file left behind by an earlier naming is graded exactly like a current one
# and nothing in the output distinguishes them. On v_ca07 that happened and it
# turned a reported 22/22 into a real 21/22. It was never reachable HERE -- these
# are wrappers that instantiate dw_downsizer_alt by name rather than embedding
# it, and no mutant on this task was ever re-keyed -- but "not reachable today"
# is a property of the history, not of the apparatus.
#
# Wiping first means a failed generation leaves a file MISSING, which the runner
# counts and refuses on, rather than STALE, which it cannot see.
for f in os.listdir(POL):
    if f.endswith(".sv"):
        os.remove(os.path.join(POL, f))

# And every block is checked BEFORE anything is written, so one bad substitution
# cannot stop the loop and leave the blocks after it unwritten.
built = []
for blk in M:
    name = re.search(r"^module (dw_m\d+_\w+)", blk, re.M).group(1)
    pid  = re.sub(r"^dw_m(\d+)_", r"dw_p\1_", name)
    t = re.sub(r"\bdw_downsizer(\s*)#\(", r"dw_downsizer_alt\1#(", blk)   # inner FIRST
    t = t.replace("module %s #(" % name, "module dw_downsizer #(", 1)     # then the decl
    if "dw_downsizer_alt #(" not in t or t.count("module dw_downsizer #(") != 1:
        raise SystemExit("policy/%s: substitution did not land as expected" % pid)
    built.append((pid, t, name))
for pid, t, name in built:
    open(os.path.join(POL, pid + ".sv"), "w", encoding="utf-8").write(
        "// step 5c: %s re-derived on the policy-divergent implementation.\n" % name + t)
print("wrote policy/: %d re-derived defects" % len(built))
