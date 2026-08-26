// ============================================================================
// nc_i_overbuffered_r -- d_nw01 CAPABILITY-EXCEEDED CONTROL. Never shipped.
// ============================================================================
// C3 says a design may hold AT MOST 4 R beats and 4 W beats per master port in
// flight inside the crossbar, and that "storage beyond that is NON-CONFORMING,
// not a design choice." This holds SIXTEEN TIMES the R allowance.
//
// WHY C3 EXISTS, in its own words: without a ceiling, buffering is an unpriced
// axis, and "one did exactly that -- a 256-entry per-master read buffer,
// 2 x 256 x ~40 bits of flip-flops, which is 14x the reference's total area on
// a design that is otherwise correct on every axis. It was not a bad answer to
// this specification. It was an answer this specification failed to constrain."
// That is F62, and it happened on THIS TASK. C3 is the clause written to stop
// it from happening again.
//
// THE PERTURBATION. The vendored reference verbatim, renamed, with a 64-deep
// FIFO interposed on each master's R channel. Ports are full width, every
// transaction is routed, ordered and returned to the master that issued it, and
// per-ID order is preserved because a FIFO cannot reorder. THE ONLY THING WRONG
// WITH IT IS THAT IT HOLDS 64 R BEATS PER MASTER WHERE C3 PERMITS 4.
//
// PREDICTION, stated before running.
//   THIS COMMENT ONCE NAMED THE SCORING TESTBENCH BY FILENAME and that made
//   check_transport.py REJECT the whole control before it ever simulated -- the
//   scanner matches the token in a COMMENT exactly as it would in code. So this
//   control had never run through the scored path at all, and the verdict
//   recorded for it came from a hand run. Named without the token now.
//
//   BOTH configurations SHOULD PASS. Grepping the scoring testbench for an
//   occupancy or beats-held counter finds nothing: the only C3-adjacent text is
//   a comment inside C1's FLOOR explaining pipeline-depth tolerance. If that
//   reading is right, C3 is a clause the contract states and the harness does
//   not enforce -- and the submission that motivated it would pass today.
//
//   IF IT FAILS, my reading is wrong and C3 is enforced by something I did not
//   recognise, most likely indirectly through a latency or liveness consequence
//   of the deeper queue. That is the better outcome.
//
// POLARITY: NO CROSSOVER, the same as d_nw03's nc_h. C3's ceiling is a CONSTANT,
// not a parameter, so 64 exceeds it at every configuration and the expected
// verdict is the same at both. The two configurations are run to show the result
// is not a configuration artefact.
// ============================================================================
`timescale 1ns/1ps

// =============================================================================
// axi4_xbar_ref.sv -- THIN PORT SHIM for d_nw01.
// =============================================================================
// Wraps vendored upstream RTL:
//   refs/axi/src/axi_xbar.sv
//   pulp-platform/axi @ 4da15979747f326bde2f9869c64e587ce599772c (SHL-0.51)
//
// CLASS A. The behaviour under test is PULP's. This file contains NO logic: no
// state, no arbitration, no decode, nothing that could change what the crossbar
// does. It is type binding and struct pack/unpack, which is exactly what the
// shim rule permits.
//
// THE ONE NON-TRIVIAL MAPPING: ID WIDTH.
// The spec fixes the slave-side id field at MST_ID_W = SLV_ID_W + 2, sized for
// the largest legal NUM_MST, because a SystemVerilog package cannot be
// parameterised and one fixed layout has to serve every configuration.
// Upstream instead computes its width as SLV_ID_W + $clog2(NoSlvPorts), which
// is 5 bits at NUM_MST == 2 and 6 at NUM_MST == 4. So the id field is resized
// rather than assigned straight through: zero-extended outbound, truncated
// inbound. That is bit placement, not behaviour -- the upper bits are the
// master index and are zero at NUM_MST == 2 by construction.
//
// Every other field is assigned one-for-one. The spec's struct field ORDER was
// deliberately written to match upstream's AXI_DECL_*_CHAN_T macros, so the
// mapping below is mechanical.
// =============================================================================

`include "axi/typedef.svh"
`timescale 1ns/1ps

module axi4_xbar_ovbuf_inner
  import axi4_xbar_pkg::*;
#(
    parameter int NUM_MST   = 2,
    parameter int NUM_SLV   = 2,
    parameter int MAX_TRANS = 8
) (
    input  logic clk,
    input  logic rst_n,
    input  slv_req_t  [NUM_MST-1:0] mst_req,
    output slv_resp_t [NUM_MST-1:0] mst_resp,
    output mst_req_t  [NUM_SLV-1:0] slv_req,
    input  mst_resp_t [NUM_SLV-1:0] slv_resp,
    input  xbar_rule_t [NUM_SLV-1:0] addr_map
);

    // Elaboration-time guard. The spec caps NUM_MST at 4 because the fixed
    // MST_IDX_W = 2 index field cannot name more masters than that. Catching it
    // here as well as in the checker means a bad geometry fails at build time
    // rather than as a mysterious response-misrouting failure at run time.
    if (NUM_MST > 4)
        $error("NUM_MST=%0d exceeds the cap of 4 imposed by MST_IDX_W=%0d",
               NUM_MST, MST_IDX_W);

    // ---- upstream's own types, built from the spec's widths ----------------
    localparam int U_MST_ID_W = SLV_ID_W + ((NUM_MST == 1) ? 1 : $clog2(NUM_MST));

    typedef logic [SLV_ID_W-1:0]   u_sid_t;
    typedef logic [U_MST_ID_W-1:0] u_mid_t;

    `AXI_TYPEDEF_ALL(u_slv, addr_t, u_sid_t, data_t, strb_t, user_t)
    `AXI_TYPEDEF_ALL(u_mst, addr_t, u_mid_t, data_t, strb_t, user_t)

    localparam axi_pkg::xbar_cfg_t Cfg = '{
        NoSlvPorts:         NUM_MST,
        NoMstPorts:         NUM_SLV,
        MaxMstTrans:        MAX_TRANS,
        MaxSlvTrans:        MAX_TRANS,
        FallThrough:        1'b0,
        LatencyMode:        axi_pkg::CUT_ALL_AX,
        PipelineStages:     0,
        AxiIdWidthSlvPorts: SLV_ID_W,
        AxiIdUsedSlvPorts:  SLV_ID_W,
        UniqueIds:          1'b0,
        AxiAddrWidth:       ADDR_W,
        AxiDataWidth:       DATA_W,
        NoAddrRules:        NUM_SLV
    };

    u_slv_req_t  [NUM_MST-1:0] u_sreq;
    u_slv_resp_t [NUM_MST-1:0] u_sresp;
    u_mst_req_t  [NUM_SLV-1:0] u_mreq;
    u_mst_resp_t [NUM_SLV-1:0] u_mresp;
    axi_pkg::xbar_rule_32_t [NUM_SLV-1:0] u_map;

    // ---- master side: spec -> upstream (narrow id, same width) -------------
    for (genvar i = 0; i < NUM_MST; i++) begin : g_slv
        always_comb begin
            u_sreq[i].aw.id     = mst_req[i].aw.id;
            u_sreq[i].aw.addr   = mst_req[i].aw.addr;
            u_sreq[i].aw.len    = mst_req[i].aw.len;
            u_sreq[i].aw.size   = mst_req[i].aw.size;
            u_sreq[i].aw.burst  = mst_req[i].aw.burst;
            u_sreq[i].aw.lock   = mst_req[i].aw.lock;
            u_sreq[i].aw.cache  = mst_req[i].aw.cache;
            u_sreq[i].aw.prot   = mst_req[i].aw.prot;
            u_sreq[i].aw.qos    = mst_req[i].aw.qos;
            u_sreq[i].aw.region = mst_req[i].aw.region;
            u_sreq[i].aw.atop   = mst_req[i].aw.atop;
            u_sreq[i].aw.user   = mst_req[i].aw.user;
            u_sreq[i].aw_valid  = mst_req[i].aw_valid;

            u_sreq[i].w.data    = mst_req[i].w.data;
            u_sreq[i].w.strb    = mst_req[i].w.strb;
            u_sreq[i].w.last    = mst_req[i].w.last;
            u_sreq[i].w.user    = mst_req[i].w.user;
            u_sreq[i].w_valid   = mst_req[i].w_valid;
            u_sreq[i].b_ready   = mst_req[i].b_ready;

            u_sreq[i].ar.id     = mst_req[i].ar.id;
            u_sreq[i].ar.addr   = mst_req[i].ar.addr;
            u_sreq[i].ar.len    = mst_req[i].ar.len;
            u_sreq[i].ar.size   = mst_req[i].ar.size;
            u_sreq[i].ar.burst  = mst_req[i].ar.burst;
            u_sreq[i].ar.lock   = mst_req[i].ar.lock;
            u_sreq[i].ar.cache  = mst_req[i].ar.cache;
            u_sreq[i].ar.prot   = mst_req[i].ar.prot;
            u_sreq[i].ar.qos    = mst_req[i].ar.qos;
            u_sreq[i].ar.region = mst_req[i].ar.region;
            u_sreq[i].ar.user   = mst_req[i].ar.user;
            u_sreq[i].ar_valid  = mst_req[i].ar_valid;
            u_sreq[i].r_ready   = mst_req[i].r_ready;

            mst_resp[i].aw_ready = u_sresp[i].aw_ready;
            mst_resp[i].ar_ready = u_sresp[i].ar_ready;
            mst_resp[i].w_ready  = u_sresp[i].w_ready;
            mst_resp[i].b_valid  = u_sresp[i].b_valid;
            mst_resp[i].b.id     = u_sresp[i].b.id;
            mst_resp[i].b.resp   = u_sresp[i].b.resp;
            mst_resp[i].b.user   = u_sresp[i].b.user;
            mst_resp[i].r_valid  = u_sresp[i].r_valid;
            mst_resp[i].r.id     = u_sresp[i].r.id;
            mst_resp[i].r.data   = u_sresp[i].r.data;
            mst_resp[i].r.resp   = u_sresp[i].r.resp;
            mst_resp[i].r.last   = u_sresp[i].r.last;
            mst_resp[i].r.user   = u_sresp[i].r.user;
        end
    end

    // ---- slave side: upstream -> spec (id RESIZED, see header) -------------
    for (genvar j = 0; j < NUM_SLV; j++) begin : g_mst
        always_comb begin
            slv_req[j].aw.id     = mst_id_t'(u_mreq[j].aw.id);   // zero-extend
            slv_req[j].aw.addr   = u_mreq[j].aw.addr;
            slv_req[j].aw.len    = u_mreq[j].aw.len;
            slv_req[j].aw.size   = u_mreq[j].aw.size;
            slv_req[j].aw.burst  = u_mreq[j].aw.burst;
            slv_req[j].aw.lock   = u_mreq[j].aw.lock;
            slv_req[j].aw.cache  = u_mreq[j].aw.cache;
            slv_req[j].aw.prot   = u_mreq[j].aw.prot;
            slv_req[j].aw.qos    = u_mreq[j].aw.qos;
            slv_req[j].aw.region = u_mreq[j].aw.region;
            slv_req[j].aw.atop   = u_mreq[j].aw.atop;
            slv_req[j].aw.user   = u_mreq[j].aw.user;
            slv_req[j].aw_valid  = u_mreq[j].aw_valid;

            slv_req[j].w.data    = u_mreq[j].w.data;
            slv_req[j].w.strb    = u_mreq[j].w.strb;
            slv_req[j].w.last    = u_mreq[j].w.last;
            slv_req[j].w.user    = u_mreq[j].w.user;
            slv_req[j].w_valid   = u_mreq[j].w_valid;
            slv_req[j].b_ready   = u_mreq[j].b_ready;

            slv_req[j].ar.id     = mst_id_t'(u_mreq[j].ar.id);
            slv_req[j].ar.addr   = u_mreq[j].ar.addr;
            slv_req[j].ar.len    = u_mreq[j].ar.len;
            slv_req[j].ar.size   = u_mreq[j].ar.size;
            slv_req[j].ar.burst  = u_mreq[j].ar.burst;
            slv_req[j].ar.lock   = u_mreq[j].ar.lock;
            slv_req[j].ar.cache  = u_mreq[j].ar.cache;
            slv_req[j].ar.prot   = u_mreq[j].ar.prot;
            slv_req[j].ar.qos    = u_mreq[j].ar.qos;
            slv_req[j].ar.region = u_mreq[j].ar.region;
            slv_req[j].ar.user   = u_mreq[j].ar.user;
            slv_req[j].ar_valid  = u_mreq[j].ar_valid;
            slv_req[j].r_ready   = u_mreq[j].r_ready;

            u_mresp[j].aw_ready  = slv_resp[j].aw_ready;
            u_mresp[j].ar_ready  = slv_resp[j].ar_ready;
            u_mresp[j].w_ready   = slv_resp[j].w_ready;
            u_mresp[j].b_valid   = slv_resp[j].b_valid;
            u_mresp[j].b.id      = u_mid_t'(slv_resp[j].b.id);   // truncate
            u_mresp[j].b.resp    = slv_resp[j].b.resp;
            u_mresp[j].b.user    = slv_resp[j].b.user;
            u_mresp[j].r_valid   = slv_resp[j].r_valid;
            u_mresp[j].r.id      = u_mid_t'(slv_resp[j].r.id);
            u_mresp[j].r.data    = slv_resp[j].r.data;
            u_mresp[j].r.resp    = slv_resp[j].r.resp;
            u_mresp[j].r.last    = slv_resp[j].r.last;
            u_mresp[j].r.user    = slv_resp[j].r.user;
        end
        always_comb begin
            u_map[j].idx        = addr_map[j].mst_port;
            u_map[j].start_addr = addr_map[j].start_addr;
            u_map[j].end_addr   = addr_map[j].end_addr;
        end
    end

    axi_xbar #(
        .Cfg(Cfg), .ATOPs(1'b0), .Connectivity('1),
        .slv_aw_chan_t(u_slv_aw_chan_t), .mst_aw_chan_t(u_mst_aw_chan_t),
        .w_chan_t(u_slv_w_chan_t),
        .slv_b_chan_t(u_slv_b_chan_t),  .mst_b_chan_t(u_mst_b_chan_t),
        .slv_ar_chan_t(u_slv_ar_chan_t), .mst_ar_chan_t(u_mst_ar_chan_t),
        .slv_r_chan_t(u_slv_r_chan_t),  .mst_r_chan_t(u_mst_r_chan_t),
        .slv_req_t(u_slv_req_t), .slv_resp_t(u_slv_resp_t),
        .mst_req_t(u_mst_req_t), .mst_resp_t(u_mst_resp_t),
        .rule_t(axi_pkg::xbar_rule_32_t)
    ) u_xbar (
        .clk_i(clk), .rst_ni(rst_n), .test_i(1'b0),
        .slv_ports_req_i(u_sreq), .slv_ports_resp_o(u_sresp),
        .mst_ports_req_o(u_mreq), .mst_ports_resp_i(u_mresp),
        .addr_map_i(u_map),
        .en_default_mst_port_i('0), .default_mst_port_i('0)
    );

endmodule


// ---------------------------------------------------------------------------
// The wrapper: reference behaviour, C3-violating storage.
// ---------------------------------------------------------------------------
module axi4_xbar
  import axi4_xbar_pkg::*;
#(
    parameter int NUM_MST   = 2,
    parameter int NUM_SLV   = 2,
    parameter int MAX_TRANS = 8,
    parameter int MAX_BURST_LEN = 3
) (
    input  logic clk,
    input  logic rst_n,
    input  slv_req_t  [NUM_MST-1:0] mst_req,
    output slv_resp_t [NUM_MST-1:0] mst_resp,
    output mst_req_t  [NUM_SLV-1:0] slv_req,
    input  mst_resp_t [NUM_SLV-1:0] slv_resp,
    input  xbar_rule_t [NUM_SLV-1:0] addr_map
);
    localparam int DEEP = 64;          // C3 permits 4

    slv_req_t  [NUM_MST-1:0] inner_req;
    slv_resp_t [NUM_MST-1:0] inner_resp;

    slv_r_t q_mem  [NUM_MST][DEEP];
    int     q_wr   [NUM_MST];
    int     q_rd   [NUM_MST];
    int     q_cnt  [NUM_MST];

    // the inner crossbar sees a ready that reflects the deep queue, not the master
    always_comb begin
        for (int m = 0; m < NUM_MST; m++) begin
            inner_req[m]         = mst_req[m];
            inner_req[m].r_ready = (q_cnt[m] < DEEP);
        end
    end

    always_comb begin
        for (int m = 0; m < NUM_MST; m++) begin
            mst_resp[m]         = inner_resp[m];
            mst_resp[m].r_valid = (q_cnt[m] != 0);
            mst_resp[m].r       = q_mem[m][q_rd[m]];
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int m = 0; m < NUM_MST; m++) begin
                q_wr[m] <= 0; q_rd[m] <= 0; q_cnt[m] <= 0;
            end
        end else begin
            for (int m = 0; m < NUM_MST; m++) begin
                automatic logic push = inner_resp[m].r_valid && (q_cnt[m] < DEEP);
                automatic logic pop  = (q_cnt[m] != 0) && mst_req[m].r_ready;
                if (push) begin
                    q_mem[m][q_wr[m]] <= inner_resp[m].r;
                    q_wr[m] <= (q_wr[m] + 1) % DEEP;
                end
                if (pop) q_rd[m] <= (q_rd[m] + 1) % DEEP;
                case ({push, pop})
                    2'b10: q_cnt[m] <= q_cnt[m] + 1;
                    2'b01: q_cnt[m] <= q_cnt[m] - 1;
                    default: ;
                endcase
            end
        end
    end

    // ---------------------------------------------------------------------
    // LIVENESS INSTRUMENT. A CONTROL THAT PASSES MAY BE INERT.
    //
    // This is the only control in the design set that never fails anywhere, and
    // its entire claim is "I hold 64 R beats per master and C3 does not catch
    // me". If the queue never actually exceeds C3's ceiling of 4, it passes for
    // the same reason a CONFORMING design passes, and the conclusion drawn from
    // it -- that C3 is unenforced -- rests on nothing.
    //
    // A control's verdict tells you it did not break the harness. It does not
    // tell you it exercised the capability its name claims. So the capability is
    // measured here rather than assumed: peak occupancy, per master, printed.
    // (AGENT-VERIF-A2's warning, from two v_ca06 perturbations whose R channel
    // had never been slow because a double drive left the gate connected to
    // nothing. Both passed every run for as long as they existed.)
    int q_peak [NUM_MST];
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int m = 0; m < NUM_MST; m++) q_peak[m] <= 0;
        end else begin
            for (int m = 0; m < NUM_MST; m++)
                if (q_cnt[m] > q_peak[m]) q_peak[m] <= q_cnt[m];
        end
    end
    final begin
        automatic int worst = 0;
        for (int m = 0; m < NUM_MST; m++) if (q_peak[m] > worst) worst = q_peak[m];
        $display("METRIC: nc_i peak_r_occupancy=%0d over %0d masters (C3 ceiling is 4, DEEP=%0d)",
                 worst, NUM_MST, DEEP);
        if (worst <= 4)
            $display("  NC_I IS INERT: it never held more than C3 permits, so its PASS is not evidence that C3 is unenforced.");
        else
            $display("  NC_I IS LIVE: it held %0d beats against C3's ceiling of 4 and still passed.",
                     worst);
    end

    axi4_xbar_ovbuf_inner #(
        .NUM_MST(NUM_MST), .NUM_SLV(NUM_SLV),
        .MAX_TRANS(MAX_TRANS)
    ) u_inner (
        .clk(clk), .rst_n(rst_n),
        .mst_req(inner_req), .mst_resp(inner_resp),
        .slv_req(slv_req), .slv_resp(slv_resp),
        .addr_map(addr_map)
    );
endmodule
