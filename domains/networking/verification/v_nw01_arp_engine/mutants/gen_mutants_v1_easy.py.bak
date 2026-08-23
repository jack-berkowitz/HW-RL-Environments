#!/usr/bin/env python3
"""Generate the v_nw01 mutant set.

Every mutant is a MECHANICAL edit of the golden shim, and where the defect is
internal, of a renamed copy of the anchor. Each edit is an exact old -> new
string pair asserted to match EXACTLY ONCE, so a silent no-op cannot produce a
mutant identical to the golden.

Three are pure changes to the pinned timers. That is the honest way to build a
retry or timeout defect: a hand-written faulty engine fails for incidental
reasons and isolates nothing.

Run:  python3 mutants/gen_mutants.py
"""
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
TASK = os.path.dirname(HERE)
DUT = os.path.join(TASK, "dut")
SHIM = open(os.path.join(DUT, "arp_engine.sv"), encoding="utf-8").read()
ANCHOR = open(os.path.join(DUT, "arp.sv"), encoding="utf-8").read()
BODY = SHIM[SHIM.index("module arp_engine ("):]


def sub1(text, old, new, what):
    n = text.count(old)
    if n != 1:
        sys.exit("MUTATION %s: pattern occurs %d times, expected exactly 1:\n  %s"
                 % (what, n, old))
    return text.replace(old, new)


SHIMLEVEL = {
 "m1_one_retry_short": ("Q4", "only three request frames are sent, not four",
   [(".REQUEST_RETRY_COUNT    (4),", ".REQUEST_RETRY_COUNT    (3),")]),
 "m2_retry_interval_long": ("Q4", "requests are spaced 96 cycles apart, not 64",
   [(".REQUEST_RETRY_INTERVAL (64),", ".REQUEST_RETRY_INTERVAL (96),")]),
 "m3_timeout_short": ("Q5", "the lookup gives up 128 cycles after the last request, not 256",
   [(".REQUEST_TIMEOUT        (256)", ".REQUEST_TIMEOUT        (128)")]),
 "m4_subnet_ignored": ("Q3", "every address looks local, so an off-subnet lookup asks for the target instead of the gateway",
   [(".subnet_mask (subnet_mask_i),", ".subnet_mask (32'd0),")]),
}

INTERNAL = {
 "m5_replies_not_learned": ("C1", "only requests are learned from; a reply teaches the cache nothing",
   [("            cache_write_request_valid_next = 1'b1;",
     "            cache_write_request_valid_next = (incoming_arp_oper == ARP_OPER_ARP_REQUEST);")]),
 "m6_answers_any_target": ("A2", "a request for somebody else's address is answered too",
   [("                if (incoming_arp_tpa == local_ip) begin",
     "                if (1'b1) begin")]),
 "m7_reply_target_is_us": ("A1", "the reply names our own address as the target instead of the requester's",
   [("""                    outgoing_arp_oper_next = ARP_OPER_ARP_REPLY;
                    outgoing_arp_tha_next = incoming_arp_sha;
                    outgoing_arp_tpa_next = incoming_arp_spa;""",
     """                    outgoing_arp_oper_next = ARP_OPER_ARP_REPLY;
                    outgoing_arp_tha_next = incoming_arp_sha;
                    outgoing_arp_tpa_next = local_ip;""")]),
 "m8_ethtype_ignored": ("A3", "a frame that is not ARP is processed anyway",
   [("        if (incoming_eth_type == 16'h0806 && incoming_arp_htype == 16'h0001 && incoming_arp_ptype == 16'h0800) begin",
     "        if (incoming_arp_htype == 16'h0001 && incoming_arp_ptype == 16'h0800) begin")]),
}

blocks = []
for tag, (clause, note, edits) in sorted(SHIMLEVEL.items()):
    b = BODY
    for old, new in edits:
        b = sub1(b, old, new, tag)
    b = sub1(b, "module arp_engine (", "module ae_%s (" % tag, "%s/rename" % tag)
    b = sub1(b, "  arp #(", "  // MUTANT ae_%s -- violates %s: %s\n  arp #(" % (tag, clause, note),
             "%s/mark" % tag)
    blocks.append(b)

for tag, (clause, note, edits) in sorted(INTERNAL.items()):
    txt = ANCHOR
    for old, new in edits:
        txt = sub1(txt, old, new, "%s/anchor" % tag)
    txt = re.sub(r"\barp\b(?=\s*#\(|\s*$)", "arp_%s" % tag, txt, count=0)
    txt = txt.replace("module arp #", "module arp_%s #" % tag, 1)
    open(os.path.join(DUT, "arp_%s.sv" % tag), "w", encoding="utf-8").write(txt)
    b = sub1(BODY, "module arp_engine (", "module ae_%s (" % tag, "%s/rename" % tag)
    b = sub1(b, "  arp #(", "  // MUTANT ae_%s -- violates %s: %s\n  arp_%s #("
             % (tag, clause, note, tag), "%s/inst" % tag)
    blocks.append(b)

# ---------------------------------------------------------------------------
# TIER-B 5c: the same eight defects re-derived on the POLICY-DIVERGENT engine,
# which uses a fully associative round-robin cache and different timing inside
# the windows. A verdict that differs between the two bases means the mutant
# perturbs latitude rather than contract. The perturbation also serves as dut2.
# ---------------------------------------------------------------------------
CONF = os.path.join(TASK, "conformant", "conformant_perturbations.sv")
conf = open(CONF, encoding="utf-8").read()

ARPOK = """  wire arp_ok = rx_valid && rx_eth_type == 16'h0806
                && rx_htype == 16'h0001 && rx_ptype == 16'h0800;   // clause A3"""
LEARN = "      if (arp_ok && rx_ready) begin"

POLICY = {
 "p1_one_retry_short":     [("  localparam int RETRIES  = 4;", "  localparam int RETRIES  = 3;")],
 "p2_retry_interval_long": [("  localparam int INTERVAL = 70;", "  localparam int INTERVAL = 96;")],
 "p3_timeout_short":       [("  localparam int TIMEOUT  = 270;", "  localparam int TIMEOUT  = 128;")],
 "p4_subnet_ignored":      [("  wire in_subnet = (req_ip_i & subnet_mask_i) == (local_ip_i & subnet_mask_i);",
                             "  wire in_subnet = 1'b1;")],
 "p5_replies_not_learned": [(LEARN, "      if (arp_ok && rx_ready && rx_oper == 16'd1) begin")],
 "p6_answers_any_target":  [("        if (rx_oper == 16'd1 && rx_tpa == local_ip_i) begin",
                             "        if (rx_oper == 16'd1) begin")],
 "p7_reply_target_is_us":  [("          pend_sha <= rx_sha; pend_spa <= rx_spa; st <= REPLY;",
                             "          pend_sha <= rx_sha; pend_spa <= local_ip_i; st <= REPLY;")],
 "p8_ethtype_ignored":     [(ARPOK, """  wire arp_ok = rx_valid
                && rx_htype == 16'h0001 && rx_ptype == 16'h0800;""")],
}
os.makedirs(os.path.join(TASK, "mutants", "policy"), exist_ok=True)
for tag, edits in POLICY.items():
    txt = conf
    for old, new in edits:
        txt = sub1(txt, old, new, "policy/%s" % tag)
    txt = sub1(txt, "module ae_c1_assoc_cache_rr", "module arp_engine", "policy/%s rename" % tag)
    open(os.path.join(TASK, "mutants", "policy", "ae_%s.sv" % tag), "w",
         encoding="utf-8").write(txt)

os.makedirs(os.path.join(TASK, "dut2"), exist_ok=True)
alt = sub1(conf, "module ae_c1_assoc_cache_rr", "module arp_engine_alt", "dut2/rename")
open(os.path.join(TASK, "dut2", "arp_engine_alt.sv"), "w", encoding="utf-8").write(
    "// GENERATED from conformant/conformant_perturbations.sv by mutants/gen_mutants.py.\n"
    "// Same artefact, two roles: the policy-divergent perturbation that must be\n"
    "// ACCEPTED, and the independent second implementation. Do not edit by hand.\n" + alt)

HEAD = """// v_nw01 mutant set -- these MUST BE CAUGHT. Scoring only, never shipped.
//
// GENERATED by mutants/gen_mutants.py. Do not edit by hand; edit the generator
// so that every defect stays a named, single, auditable change.
"""
open(os.path.join(HERE, "mutants.sv"), "w", encoding="utf-8").write(HEAD + "\n" + "\n".join(blocks))
print("wrote mutants.sv with %d mutants (%d shim-level, %d internal)"
      % (len(blocks), len(SHIMLEVEL), len(INTERNAL)))
