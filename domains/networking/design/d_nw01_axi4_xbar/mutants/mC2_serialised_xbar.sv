// =============================================================================
// mC2_serialised_xbar -- MUTANT. NEVER SHIPPED.
// class: concurrency (C2)
// injected bug: a single global grant lets only ONE slave port receive a read
//               address in any cycle, so the crossbar has one shared datapath
//               instead of N independent ones. Disjoint master/slave pairs
//               cannot proceed in parallel.
//
// WHY THIS EXISTS. C2's failure mode is silence. A crossbar that serialises is
// correct on every individual transaction -- right data, right order, right
// beat counts, no deadlock, no starvation -- so every data check in the suite
// passes. It is simply not a crossbar. Per the standing procedure in
// FINDINGS.md a check whose failure mode is absence must be validated
// against a known-failing input, and nothing else available fails C2: the
// vendored reference and the candidate both serve disjoint pairs in parallel.
//
// THE GRANT IS ON THE SLAVE SIDE, DOWNSTREAM OF THE CROSSBAR'S ID QUEUES, SO
// THIS MUTANT STILL PASSES C1. That isolation is the point: it fails C2 and
// only C2. An earlier version gated the master side instead and failed both,
// which would have proved nothing about C2 specifically.
//
// Derived from ref/axi4_xbar_ref.sv by adding the rotating grant. The vendored
// axi_xbar instance is untouched.
// =============================================================================
`include "axi/typedef.svh"
`timescale 1ns/1ps

module axi4_xbar
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
    // ---- INJECTED: ONE shared read-address datapath for the whole crossbar --
    // Demand-driven, not blind round-robin. A blind rotating grant throttles a
    // solo pair just as much as a concurrent one, so the one-pair/two-pair
    // RATIO stays at 2x and C2 cannot see it (measured: 199 %). This grants to
    // whichever slave port is actually asking, one per cycle, rotating only on
    // use -- so a single pair gets the full rate and two pairs SHARE it. That
    // is what a shared datapath really does, and it is what C2 must catch.
    logic [NUM_SLV-1:0] gs_req, gs_grant;
    int                 gs_ptr;
    always_comb begin
        automatic bit found = 1'b0;
        gs_grant = '0;
        for (int k = 0; k < NUM_SLV; k++) begin
            automatic int j = (gs_ptr + k) % NUM_SLV;
            if (!found && gs_req[j]) begin gs_grant[j] = 1'b1; found = 1'b1; end
        end
    end
    always_ff @(posedge clk) begin
        if (!rst_n) gs_ptr <= 0;
        else if (|gs_grant) begin
            for (int j = 0; j < NUM_SLV; j++)
                if (gs_grant[j]) gs_ptr <= (j + 1) % NUM_SLV;
        end
    end

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
            gs_req[j]            = u_mreq[j].ar_valid;                  // INJECTED
            slv_req[j].ar_valid  = u_mreq[j].ar_valid && gs_grant[j];   // INJECTED
            slv_req[j].r_ready   = u_mreq[j].r_ready;

            u_mresp[j].aw_ready  = slv_resp[j].aw_ready;
            u_mresp[j].ar_ready  = slv_resp[j].ar_ready && gs_grant[j];   // INJECTED
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
