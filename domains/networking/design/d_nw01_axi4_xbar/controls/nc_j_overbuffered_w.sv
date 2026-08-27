// ============================================================================
// nc_j_overbuffered_w -- d_nw01 CAPABILITY-EXCEEDED CONTROL. Never shipped.
// ============================================================================
// The W-channel twin of nc_i_overbuffered_r, and it exists for a reason nc_i
// does not cover: C3 bounds "4 R beats AND 4 W beats per master port", and a
// ceiling check written for only one of those directions leaves the other half
// of the clause enforced by nothing while LOOKING enforced from the results.
// That is the same defect the clause itself was written against, one level up.
//
// C3, in full: a design may hold AT MOST 4 R beats and 4 W beats per master
// port in flight inside the crossbar, and "storage beyond that is
// NON-CONFORMING, not a design choice." This holds SIXTEEN TIMES the W
// allowance.
//
// THE PERTURBATION. The vendored reference verbatim, renamed, with a 64-deep
// FIFO interposed on each master's W channel. The direction is the mirror of
// nc_i's: R beats flow slave->master, so nc_i buffers what comes BACK; W beats
// flow master->slave, so this buffers what goes IN. The wrapper answers
// w_ready itself and feeds the inner crossbar from the queue. Every beat is
// delivered, in order, to the slave the address decodes to -- W beats cannot
// even be reordered, since AXI4 has no WID and the queue is per master.
// THE ONLY THING WRONG WITH IT IS THAT IT HOLDS 64 W BEATS PER MASTER WHERE
// C3 PERMITS 4.
//
// PREDICTION, stated before running. Unlike nc_i -- which was written to prove
// a gap and correctly predicted a PASS -- this one is written to validate a
// check that now exists, so the prediction is the opposite:
//
//   BOTH configurations SHOULD FAIL, in phase w-ceiling, naming C3, with a
//   held count far above the allowance of 4*NUM_MST.
//
//   IF IT PASSES, the W ceiling check does not actually observe W storage and
//   the clause is still half-unenforced. A check that cannot refuse this is
//   not a check, and that is the whole reason the control is run.
//
// NAMING: this comment does not name the scoring testbench by filename.
// check_transport.py matches the token in a COMMENT exactly as it would in
// code, and nc_i spent its whole first life rejected before it ever simulated
// for precisely that reason.
//
// POLARITY: NO CROSSOVER, the same as nc_i. C3's ceiling is a CONSTANT, not a
// parameter, so 64 exceeds it at every configuration.
// ============================================================================
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

module axi4_xbar_ovbufw_inner
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
// The wrapper: reference behaviour, C3-violating W storage.
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

    w_t q_mem [NUM_MST][DEEP];
    int q_wr  [NUM_MST];
    int q_rd  [NUM_MST];
    int q_cnt [NUM_MST];

    // The master's W beats land in the deep queue, not in the crossbar: this
    // wrapper answers w_ready itself, and the inner crossbar is offered beats
    // out of the queue instead.
    always_comb begin
        for (int m = 0; m < NUM_MST; m++) begin
            inner_req[m]         = mst_req[m];
            inner_req[m].w_valid = (q_cnt[m] != 0);
            inner_req[m].w       = q_mem[m][q_rd[m]];
        end
    end

    always_comb begin
        for (int m = 0; m < NUM_MST; m++) begin
            mst_resp[m]         = inner_resp[m];
            mst_resp[m].w_ready = (q_cnt[m] < DEEP);
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int m = 0; m < NUM_MST; m++) begin
                q_wr[m] <= 0; q_rd[m] <= 0; q_cnt[m] <= 0;
            end
        end else begin
            for (int m = 0; m < NUM_MST; m++) begin
                automatic logic push = mst_req[m].w_valid && (q_cnt[m] < DEEP);
                automatic logic pop  = (q_cnt[m] != 0) && inner_resp[m].w_ready;
                if (push) begin
                    q_mem[m][q_wr[m]] <= mst_req[m].w;
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
    // LIVENESS INSTRUMENT. A CONTROL'S VERDICT ONLY TELLS YOU IT DID NOT BREAK
    // THE HARNESS -- it does not tell you it exercised the capability its name
    // claims. nc_i carries the same instrument for the same reason, after
    // AGENT-VERIF-A2's two v_ca06 perturbations whose R channel had never been
    // slow because a double drive left the gate connected to nothing.
    //
    // Here it matters in the other direction too: this control is expected to
    // FAIL, and a failure for the WRONG reason -- a protocol violation the
    // queue introduced, say -- would look like a validated check while proving
    // nothing. Peak occupancy says the queue really did exceed the ceiling.
    // ---------------------------------------------------------------------
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
        $display("METRIC: nc_j peak_w_occupancy=%0d over %0d masters (C3 ceiling is 4, DEEP=%0d)",
                 worst, NUM_MST, DEEP);
        if (worst <= 4)
            $display("  NC_J IS INERT: it never held more than C3 permits, so its verdict is not evidence about C3.");
        else
            $display("  NC_J IS LIVE: it held %0d W beats against C3's ceiling of 4.", worst);
    end

    axi4_xbar_ovbufw_inner #(
        .NUM_MST(NUM_MST), .NUM_SLV(NUM_SLV),
        .MAX_TRANS(MAX_TRANS)
    ) u_inner (
        .clk(clk), .rst_n(rst_n),
        .mst_req(inner_req), .mst_resp(inner_resp),
        .slv_req(slv_req), .slv_resp(slv_resp),
        .addr_map(addr_map)
    );
endmodule
