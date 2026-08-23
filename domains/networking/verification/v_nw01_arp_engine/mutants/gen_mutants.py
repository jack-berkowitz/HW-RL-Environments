#!/usr/bin/env python3
"""Generate the v_nw01 mutant set -- GUARDED.

Every mutant is a MECHANICAL edit of a renamed copy of the anchor. Each edit is
an exact old -> new pair asserted to match EXACTLY ONCE, so a silent no-op
cannot produce a mutant identical to the golden that every testbench "kills" by
doing nothing.

EVERY DEFECT IS GUARDED:

    wrong_behaviour AND rare_predicate over contract-level state

Guards read this module's own PORTS -- lookups accepted, frames received,
frames transmitted, responses taken, clears -- never a private register of the
design. Step 5c re-derives every defect on an independent implementation that
does not have those registers.

Run:  python3 mutants/gen_mutants.py
"""
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
TASK = os.path.dirname(HERE)
DUT = os.path.join(TASK, "dut")
ANCHOR = open(os.path.join(DUT, "arp.sv"), encoding="utf-8").read()
SHIM = open(os.path.join(DUT, "arp_engine.sv"), encoding="utf-8").read()
BODY = SHIM[SHIM.index("module arp_engine ("):]


def sub1(text, old, new, what):
    n = text.count(old)
    if n != 1:
        sys.exit("MUTATION %s: pattern occurs %d times, expected exactly 1:\n  %s"
                 % (what, n, old))
    return text.replace(old, new)


DECL = "reg [5:0] arp_request_retry_cnt_reg = 6'd0, arp_request_retry_cnt_next;"
GUARD = DECL + """

// ---- mutant guard state: contract-level only -----------------------------
// Every quantity here is counted from this module's PORTS, so each guard can
// be restated against any implementation of the same contract.
reg [7:0] g_lookup_q  = 8'd0;   // lookups accepted since reset
reg [7:0] g_timeout_q = 8'd0;   // lookups answered with an error
reg [7:0] g_rx_q      = 8'd0;   // ARP frames received since reset or clear
reg [7:0] g_tx_q      = 8'd0;   // frames transmitted since reset
reg [7:0] g_att_q     = 8'd0;   // request frames sent for the CURRENT lookup
reg       g_out_q     = 1'b0;   // a lookup of ours is outstanding
reg [7:0] g_clr_q     = 8'd0;   // clears seen
reg [7:0] g_occ_q     = 8'd0;   // frames learned since the last EFFECTIVE clear

// A clear that only counts once it has taken effect. Resetting the occupancy
// on the first cycle of the pulse would let the rest of the pulse through, so
// the predicate would defeat itself on any clear longer than one cycle.
wire g_clr_eff = clear_cache && !(g_occ_q >= 8'd4);

always @(posedge clk) begin
    if (rst) begin
        g_lookup_q <= 8'd0; g_timeout_q <= 8'd0; g_rx_q <= 8'd0;
        g_tx_q <= 8'd0; g_att_q <= 8'd0; g_out_q <= 1'b0; g_clr_q <= 8'd0;
    end else begin
        if (clear_cache) begin g_clr_q <= g_clr_q + 8'd1; g_rx_q <= 8'd0; end
        else if (s_eth_hdr_valid && s_eth_hdr_ready) g_rx_q <= g_rx_q + 8'd1;
        if (g_clr_eff) g_occ_q <= 8'd0;
        else if (s_eth_hdr_valid && s_eth_hdr_ready) g_occ_q <= g_occ_q + 8'd1;
        if (m_eth_hdr_valid && m_eth_hdr_ready) begin
            g_tx_q <= g_tx_q + 8'd1;
            if (g_out_q) g_att_q <= g_att_q + 8'd1;
        end
        if (arp_request_valid && arp_request_ready) begin
            g_lookup_q <= g_lookup_q + 8'd1; g_out_q <= 1'b1; g_att_q <= 8'd0;
        end
        if (arp_response_valid && arp_response_ready) begin
            g_out_q <= 1'b0;
            if (arp_response_error) g_timeout_q <= g_timeout_q + 8'd1;
        end
    end
end"""

E_INITRETRY = "                    arp_request_retry_cnt_next = REQUEST_RETRY_COUNT-1;"
E_RETRYTPA = """                outgoing_arp_tpa_next = arp_request_ip_reg;
                arp_request_retry_cnt_next = arp_request_retry_cnt_reg - 1;"""
E_MACHIT = """                    cache_query_request_valid_next = 1'b0;
                    arp_response_valid_next = 1'b1;
                    arp_response_error_next = 1'b0;
                    arp_response_mac_next = cache_query_response_mac;"""
E_INSERT = "            cache_write_request_valid_next = 1'b1;"
E_REPLYTHA = """                    outgoing_arp_oper_next = ARP_OPER_ARP_REPLY;
                    outgoing_arp_tha_next = incoming_arp_sha;"""
E_TPAMATCH = "                if (incoming_arp_tpa == local_ip) begin"
E_ETHTYPE = ("        if (incoming_eth_type == 16'h0806 && incoming_arp_htype == 16'h0001 "
             "&& incoming_arp_ptype == 16'h0800) begin")
E_CLEAR = "    .clear_cache(clear_cache)"

MUTANTS = {
 "m1_three_requests_from_second_lookup": ("Q4",
   "only THREE request frames are transmitted instead of four",
   "the second unanswered lookup, and every one after it -- the first is exact",
   [(E_INITRETRY,
     "                    arp_request_retry_cnt_next = REQUEST_RETRY_COUNT-1\n"
     "                                                 - ((g_timeout_q >= 8'd1) ? 1 : 0);")]),
 "m2_last_request_wrong_target": ("Q3",
   "the request frame asks for an address one off from the one looked up",
   "the LAST of the four requests -- the first three carry the right address",
   [(E_RETRYTPA,
     "                outgoing_arp_tpa_next = (arp_request_retry_cnt_reg == 1)\n"
     "                                        ? (arp_request_ip_reg ^ 32'h0000_0001)\n"
     "                                        : arp_request_ip_reg;\n"
     "                arp_request_retry_cnt_next = arp_request_retry_cnt_reg - 1;")]),
 "m3_cached_mac_wrong_when_full": ("Q1",
   "the MAC answered from the cache has its low byte corrupted",
   "four or more frames have been learned since the last clear -- the cache is full",
   [(E_MACHIT,
     "                    cache_query_request_valid_next = 1'b0;\n"
     "                    arp_response_valid_next = 1'b1;\n"
     "                    arp_response_error_next = 1'b0;\n"
     "                    arp_response_mac_next = (g_rx_q >= 8'd4)\n"
     "                        ? (cache_query_response_mac ^ 48'h0000_0000_0001)\n"
     "                        : cache_query_response_mac;")]),
 "m4_insert_dropped_when_full": ("C2",
   "the insert silently fails, so the address stays unknown",
   "four frames have already been learned since the last clear",
   [(E_INSERT, "            cache_write_request_valid_next = (g_rx_q < 8'd4);")]),
 "m5_requests_not_learned_after_two": ("C1",
   "a received ARP REQUEST does not insert its sender pair; replies still do",
   "two or more frames have already been learned since the last clear",
   [(E_INSERT,
     "            cache_write_request_valid_next =\n"
     "                !((incoming_arp_oper == ARP_OPER_ARP_REQUEST) && (g_rx_q >= 8'd2));")]),
 "m6_reply_target_wrong_while_busy": ("A1",
   "the reply names the wrong target hardware address",
   "one of our own lookups is outstanding when the request arrives",
   [(E_REPLYTHA,
     "                    outgoing_arp_oper_next = ARP_OPER_ARP_REPLY;\n"
     "                    outgoing_arp_tha_next = g_out_q ? 48'h0000_0000_0000\n"
     "                                                    : incoming_arp_sha;")]),
 "m7_answers_foreign_target_while_busy": ("A2",
   "a request whose TPA is not local_ip_i is answered anyway",
   "one of our own lookups is outstanding when the request arrives",
   [(E_TPAMATCH, "                if ((incoming_arp_tpa == local_ip) || g_out_q) begin")]),
 "m8_ethtype_low_nibble_ignored": ("A3",
   "a frame whose eth_type is not 0x0806 is processed as ARP",
   "the eth_type differs from 0x0806 only in its low nibble, and two frames "
   "have already been received",
   [(E_ETHTYPE,
     "        if (((incoming_eth_type == 16'h0806)\n"
     "             || ((g_rx_q >= 8'd2) && (incoming_eth_type[15:4] == 12'h080)))\n"
     "            && incoming_arp_htype == 16'h0001 && incoming_arp_ptype == 16'h0800) begin")]),
 "m9_clear_ignored_when_full": ("C3",
   "clear_cache_i does not reach the cache, so every entry survives it",
   "the cache holds four entries when the clear arrives -- a clear on a partly filled cache works",
   [(E_CLEAR, "    .clear_cache(g_clr_eff)")]),
 "m10_five_requests_on_third_lookup": ("Q4",
   "FIVE request frames are transmitted instead of four",
   "the third lookup since reset, and every one after it",
   [(E_INITRETRY,
     "                    arp_request_retry_cnt_next = REQUEST_RETRY_COUNT-1\n"
     "                                                 + ((g_lookup_q >= 8'd3) ? 1 : 0);")]),
}

blocks = []
for tag, (clause, note, guard, edits) in sorted(MUTANTS.items(),
                                                key=lambda kv: int(kv[0].split("_")[0][1:])):
    txt = sub1(ANCHOR, DECL, GUARD, "%s/guard" % tag)
    for old, new in edits:
        txt = sub1(txt, old, new, "%s/anchor" % tag)
    txt = re.sub(r"\barp\b(?=\s*#\()", "arp_%s" % tag, txt)
    txt = sub1(txt, "module arp #", "module arp_%s #" % tag, "%s/modrename" % tag)
    open(os.path.join(DUT, "arp_%s.sv" % tag), "w", encoding="utf-8").write(txt)
    b = sub1(BODY, "module arp_engine (", "module ae_%s (" % tag, "%s/rename" % tag)
    b = sub1(b, "  arp #(",
             "  // MUTANT ae_%s -- violates %s\n  //   defect: %s\n  //   guard : fires only when %s\n"
             "  arp_%s #(" % (tag, clause, note, guard, tag), "%s/inst" % tag)
    blocks.append(b)

HDR = ("// GENERATED by mutants/gen_mutants.py -- do not edit by hand.\n"
       "// The v_nw01 mutant set: every defect GUARDED by a rare predicate over\n"
       "// contract-level state. Scoring only, never shipped to a submission.\n\n")
open(os.path.join(HERE, "mutants.sv"), "w", encoding="utf-8").write(HDR + "\n".join(blocks))
print("wrote mutants.sv: %d mutants" % len(blocks))
