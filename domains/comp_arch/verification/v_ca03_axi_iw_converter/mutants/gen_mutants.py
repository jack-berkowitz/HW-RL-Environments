#!/usr/bin/env python3
"""Generate the v_ca03 mutant set -- GUARDED.

Every mutant WRAPS the unmodified golden. Two hooks:

  * the slave-side handshake, gated so that valid into the golden and ready out
    of it move together -- no cycle exists in which one side believes a
    transaction was accepted and the other does not;
  * the slave-side RESPONSE channels, intercepted on the way out.

EVERY DEFECT IS GUARDED:

    wrong_behaviour AND rare_predicate over contract-level state

The occupancy tracker reads the SLAVE PORT HANDSHAKES and the golden's own
response stream -- never anything inside the golden's table -- so a mutant
cannot inherit the golden's blind spots, and every guard can be restated
against an independent implementation.

Run:  python3 mutants/gen_mutants.py
"""
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
TASK = os.path.dirname(HERE)
GOLD = open(os.path.join(TASK, "dut", "id_width_conv.sv"), encoding="utf-8").read()

m = re.search(r"^module id_width_conv #\(.*?^\);", GOLD, re.S | re.M)
if not m:
    sys.exit("could not find the golden's module header")
HEADER = m.group(0)

TRACKER = """
  // ---- occupancy and guard state -------------------------------------------
  // Counted from the SLAVE PORT HANDSHAKES and the golden's own response
  // stream. Nothing inside the golden's table is read, so these quantities are
  // the contract's, not the implementation's, and every guard below can be
  // restated against a different design.
  localparam int unsigned NID = 1 << SLV_ID_W;
  int unsigned rcnt [NID];
  int unsigned wcnt [NID];
  int unsigned g_fullage_r, g_fullage_w;   // cycles the table has been FULL
  int unsigned g_rbeat_q;                  // read data beats delivered
  int unsigned g_rbi_q;                    // beat index within the current burst
  int unsigned g_bdone_q;                  // write responses delivered
  int unsigned g_free_r_q;                 // cycles left in a retirement blackout
  logic [SLV_ID_W-1:0] g_lastbid_q;
  logic g_extra_q;

  function automatic int unsigned n_distinct_r();
    n_distinct_r = 0;
    for (int i = 0; i < NID; i++) if (rcnt[i] != 0) n_distinct_r++;
  endfunction
  function automatic int unsigned n_distinct_w();
    n_distinct_w = 0;
    for (int i = 0; i < NID; i++) if (wcnt[i] != 0) n_distinct_w++;
  endfunction

  wire i_rdone = i_rvalid && s_rready && i_rlast;
  wire i_bdone = i_bvalid && s_bready;

  always_ff @(posedge clk_i) begin
    if (!rst_ni) begin
      for (int i = 0; i < NID; i++) begin rcnt[i] <= 0; wcnt[i] <= 0; end
      g_fullage_r <= 0; g_fullage_w <= 0; g_rbeat_q <= 0; g_rbi_q <= 0;
      g_bdone_q <= 0; g_free_r_q <= 0; g_lastbid_q <= '0; g_extra_q <= 1'b0;
    end else begin
      if (s_arvalid && s_arready)  rcnt[s_arid] <= rcnt[s_arid] + 1;
      if (i_rdone)                 rcnt[i_rid]  <= rcnt[i_rid]  - 1;
      if (s_awvalid && s_awready)  wcnt[s_awid] <= wcnt[s_awid] + 1;
      if (i_bdone)                 wcnt[i_bid]  <= wcnt[i_bid]  - 1;

      g_fullage_r <= (n_distinct_r() >= MAX_UNIQ_IDS) ? g_fullage_r + 1 : 0;
      g_fullage_w <= (n_distinct_w() >= MAX_UNIQ_IDS) ? g_fullage_w + 1 : 0;

      if (i_rvalid && s_rready) begin
        g_rbeat_q <= g_rbeat_q + 1;
        g_rbi_q   <= i_rlast ? 0 : g_rbi_q + 1;
      end
      // A retirement out of a BUSY table -- three or more identifiers were
      // outstanding when this one completed.
      if (i_rdone && (rcnt[i_rid] == 1) && (n_distinct_r() >= 3)) g_free_r_q <= 4;
      else if (g_free_r_q != 0)                                   g_free_r_q <= g_free_r_q - 1;

      g_extra_q <= 1'b0;
      if (i_bdone) begin
        g_bdone_q   <= g_bdone_q + 1;
        g_lastbid_q <= i_bid;
        if (g_bdone_q == 15) g_extra_q <= 1'b1;
      end
    end
  end
"""

BODY = """
  wire blk_r = %(BLK_R)s;
  wire blk_w = %(BLK_W)s;

  wire g_arvalid = s_arvalid & ~blk_r;
  wire g_awvalid = s_awvalid & ~blk_w;
  wire g_arready, g_awready;
  assign s_arready = g_arready & ~blk_r;
  assign s_awready = g_awready & ~blk_w;

  // the golden's slave-side response stream, before any transform
  wire [SLV_ID_W-1:0] i_bid;  wire [1:0] i_bresp; wire i_bvalid;
  wire [SLV_ID_W-1:0] i_rid;  wire [DATA_W-1:0] i_rdata;
  wire [1:0] i_rresp; wire i_rlast; wire i_rvalid;

%(RESP)s

  id_width_conv #(
      .SLV_ID_W(SLV_ID_W), .MST_ID_W(MST_ID_W), .ADDR_W(ADDR_W), .DATA_W(DATA_W),
      .MAX_UNIQ_IDS(MAX_UNIQ_IDS), .MAX_TXNS_PER_ID(MAX_TXNS_PER_ID)
  ) i_g (
      .clk_i, .rst_ni,
      .s_awid, .s_awaddr, .s_awlen, .s_awvalid(g_awvalid), .s_awready(g_awready),
      .s_wdata, .s_wstrb, .s_wlast, .s_wvalid, .s_wready,
      .s_bid(i_bid), .s_bresp(i_bresp), .s_bvalid(i_bvalid), .s_bready(s_bready),
      .s_arid, .s_araddr, .s_arlen, .s_arvalid(g_arvalid), .s_arready(g_arready),
      .s_rid(i_rid), .s_rdata(i_rdata), .s_rresp(i_rresp), .s_rlast(i_rlast),
      .s_rvalid(i_rvalid), .s_rready(s_rready),
      .m_awid, .m_awaddr, .m_awlen, .m_awvalid, .m_awready,
      .m_wdata, .m_wstrb, .m_wlast, .m_wvalid, .m_wready,
      .m_bid, .m_bresp, .m_bvalid, .m_bready,
      .m_arid, .m_araddr, .m_arlen, .m_arvalid, .m_arready,
      .m_rid, .m_rdata, .m_rresp, .m_rlast, .m_rvalid, .m_rready
  );
endmodule
"""

RESP_PLAIN = """  assign s_bid   = i_bid;   assign s_bresp = i_bresp; assign s_bvalid = i_bvalid;
  assign s_rid   = i_rid;   assign s_rdata = i_rdata; assign s_rresp  = i_rresp;
  assign s_rlast = i_rlast; assign s_rvalid = i_rvalid;"""

NOBLK = "1'b0"

MUTANTS = [
 ("m1_blocks_one_early_on_long_bursts", "A3",
  "a new identifier is refused one entry BELOW the boundary",
  "the arriving request's burst is four beats or longer -- short bursts are exact",
  "s_arvalid && (n_distinct_r() >= (MAX_UNIQ_IDS-1)) && (rcnt[s_arid] == 0) && (s_arlen >= 8'd4)",
  "s_awvalid && (n_distinct_w() >= (MAX_UNIQ_IDS-1)) && (wcnt[s_awid] == 0) && (s_awlen >= 8'd4)",
  RESP_PLAIN),
 ("m2_depth_one_short_when_two_ids", "A5",
  "the per-identifier depth stalls one transaction early",
  "two or more distinct identifiers are outstanding on that side",
  "s_arvalid && (rcnt[s_arid] >= (MAX_TXNS_PER_ID-1)) && (n_distinct_r() >= 2)",
  "s_awvalid && (wcnt[s_awid] >= (MAX_TXNS_PER_ID-1)) && (n_distinct_w() >= 2)",
  RESP_PLAIN),
 ("m3_entry_freed_late_after_busy_retire", "A4",
  "the freed entry stays blocked for four cycles, past A4's two-cycle window",
  "the identifier retired out of a table holding three or more of them",
  "s_arvalid && (g_free_r_q != 0) && (rcnt[s_arid] == 0)", NOBLK, RESP_PLAIN),
 ("m4_blocks_known_id_when_full_has_aged", "A3",
  "a request carrying an ALREADY-outstanding identifier is refused",
  "the table has been full for four consecutive cycles",
  "s_arvalid && (n_distinct_r() >= MAX_UNIQ_IDS) && (rcnt[s_arid] != 0) && (g_fullage_r >= 4)",
  "s_awvalid && (n_distinct_w() >= MAX_UNIQ_IDS) && (wcnt[s_awid] != 0) && (g_fullage_w >= 4)",
  RESP_PLAIN),
 ("m5_reads_and_writes_share_when_deep", "A1",
  "reads and writes are counted against ONE table instead of separately",
  "two or more distinct write identifiers are outstanding",
  "s_arvalid && ((n_distinct_r() + n_distinct_w()) >= MAX_UNIQ_IDS) && (rcnt[s_arid] == 0) && (n_distinct_w() >= 2)",
  NOBLK, RESP_PLAIN),
 ("m6_rid_wrong_deep_in_burst", "C1",
  "a read response beat carries the wrong slave identifier",
  "the fourth beat of a burst and every beat after it -- shorter bursts are exact",
  NOBLK, NOBLK,
  """  assign s_bid   = i_bid;   assign s_bresp = i_bresp; assign s_bvalid = i_bvalid;
  assign s_rid   = (i_rvalid && (g_rbi_q >= 3)) ? (i_rid ^ 1) : i_rid;
  assign s_rdata = i_rdata; assign s_rresp  = i_rresp;
  assign s_rlast = i_rlast; assign s_rvalid = i_rvalid;"""),
 ("m7_rdata_corrupt_every_thirty_second", "E1",
  "a read data beat has its low bit flipped",
  "the thirty-second beat delivered, and every thirty-second after it",
  NOBLK, NOBLK,
  """  assign s_bid   = i_bid;   assign s_bresp = i_bresp; assign s_bvalid = i_bvalid;
  assign s_rid   = i_rid;
  assign s_rdata = ((g_rbeat_q % 32) == 31) ? (i_rdata ^ 1) : i_rdata;
  assign s_rresp = i_rresp;
  assign s_rlast = i_rlast; assign s_rvalid = i_rvalid;"""),
 ("m8_bresp_wrong_when_full", "E1",
  "the write response carries an altered resp field",
  "the write table is full when the response is presented",
  NOBLK, NOBLK,
  """  assign s_bid   = i_bid;
  assign s_bresp = (n_distinct_w() >= MAX_UNIQ_IDS) ? (i_bresp ^ 2'b01) : i_bresp;
  assign s_bvalid = i_bvalid;
  assign s_rid   = i_rid;   assign s_rdata = i_rdata; assign s_rresp  = i_rresp;
  assign s_rlast = i_rlast; assign s_rvalid = i_rvalid;"""),
 ("m9_rlast_early_on_long_bursts", "D4",
  "rlast is asserted on a beat that is not the burst's last, splitting one "
  "slave response into two",
  "the burst runs to a seventh beat -- anything shorter never reaches the mark",
  NOBLK, NOBLK,
  """  assign s_bid   = i_bid;   assign s_bresp = i_bresp; assign s_bvalid = i_bvalid;
  assign s_rid   = i_rid;   assign s_rdata = i_rdata; assign s_rresp  = i_rresp;
  assign s_rlast = i_rlast | (i_rvalid && (g_rbi_q == 5));
  assign s_rvalid = i_rvalid;"""),
 ("m10_extra_b_after_sixteen", "C2",
  "an extra write response is presented for a transaction that is not outstanding",
  "sixteen write responses have already been delivered",
  NOBLK, NOBLK,
  """  assign s_bid   = (g_extra_q && !i_bvalid) ? g_lastbid_q : i_bid;
  assign s_bresp = i_bresp; assign s_bvalid = i_bvalid | g_extra_q;
  assign s_rid   = i_rid;   assign s_rdata = i_rdata; assign s_rresp  = i_rresp;
  assign s_rlast = i_rlast; assign s_rvalid = i_rvalid;"""),
 ("m11_decerr_normalised_to_slverr_from_second", "E1",
  "a DECERR arriving on the master port is presented upstream as SLVERR -- an error, of the wrong kind, so the response is still an error and only the CODE is wrong",
  "the second DECERR since reset and every one after it -- the first is preserved correctly",
  NOBLK, NOBLK,
  """  // E1's newest half: `resp` on BOTH response channels is forwarded
  // unmodified. iw_m8 already perturbs bresp, but it produces a WRONG RESPONSE;
  // CODE PRESERVATION is a different property, and letting iw_m8 stand for both
  // credits a submission that checks "is this the right response" with checking
  // "is this the right KIND of error", which it does not.
  //
  // This one leaves the response an ERROR and changes only which error, so a
  // checker that only asks "did an error arrive" cannot see it.
  int e_n = 0;
  always_ff @(posedge clk_i or negedge rst_ni)
    if (!rst_ni) e_n <= 0;
    else e_n <= e_n + ((i_rvalid && s_rready && (i_rresp == 2'b11)) ? 1 : 0)
                    + ((i_bvalid && s_bready && (i_bresp == 2'b11)) ? 1 : 0);
  wire dn = (e_n >= 1);
  assign s_bid   = i_bid;
  assign s_bresp = (dn && (i_bresp == 2'b11)) ? 2'b10 : i_bresp;
  assign s_bvalid = i_bvalid;
  assign s_rid   = i_rid;   assign s_rdata = i_rdata;
  assign s_rresp = (dn && (i_rresp == 2'b11)) ? 2'b10 : i_rresp;
  assign s_rlast = i_rlast; assign s_rvalid = i_rvalid;"""),
]

HDR = ("// GENERATED by mutants/gen_mutants.py -- do not edit by hand.\n"
       "// The v_ca03 mutant set: every defect GUARDED by a rare predicate over\n"
       "// contract-level state. Scoring only, never shipped to a submission.\n")

out = [HDR]
for tag, clause, note, guard, blk_r, blk_w, resp in MUTANTS:
    name = "iw_%s" % tag
    out.append("\n// %s\n// iw_%s -- violates %s.\n//   defect: %s\n//   guard : fires only when %s\n// %s\n%s%s%s"
               % ("-" * 74, tag, clause, note, guard, "-" * 74,
                  HEADER.replace("module id_width_conv #(", "module %s #(" % name, 1),
                  TRACKER, BODY % {"BLK_R": blk_r, "BLK_W": blk_w, "RESP": resp}))
open(os.path.join(HERE, "mutants.sv"), "w", encoding="utf-8").write("".join(out))
print("wrote mutants.sv: %d mutants" % len(MUTANTS))
