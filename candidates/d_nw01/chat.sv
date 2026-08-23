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

    localparam int ID_COUNT  = (1 << SLV_ID_W);
    localparam int MSEL_W    = $clog2(NUM_MST);
    localparam int SSEL_W    = $clog2(NUM_SLV);
    localparam int ROUTE_W   = $clog2(NUM_SLV + 1);
    localparam int ERR_ROUTE = NUM_SLV;

    localparam int QPTR_W = $clog2(MAX_TRANS);
    localparam int QCNT_W = $clog2(MAX_TRANS + 1);

    localparam int OWN_DEPTH = NUM_MST * MAX_TRANS;
    localparam int OWN_PTR_W = $clog2(OWN_DEPTH);
    localparam int OWN_CNT_W = $clog2(OWN_DEPTH + 1);

    // B/R arbitration has NUM_SLV real slave sources plus one local DECERR
    // source.
    localparam int SRC_N = NUM_SLV + 1;
    localparam int SRC_W = $clog2(SRC_N);

    // =========================================================================
    // Helper functions
    // =========================================================================

    function automatic mst_id_t widen_id(
        input int unsigned m,
        input slv_id_t     id
    );
        mst_id_t t;
        begin
            t = '0;
            t[SLV_ID_W-1:0] = id;
            t[MST_ID_W-1:SLV_ID_W] = m;
            widen_id = t;
        end
    endfunction


    function automatic mst_aw_t widen_aw(
        input slv_aw_t     a,
        input int unsigned m
    );
        mst_aw_t t;
        begin
            t.id     = widen_id(m, a.id);
            t.addr   = a.addr;
            t.len    = a.len;
            t.size   = a.size;
            t.burst  = a.burst;
            t.lock   = a.lock;
            t.cache  = a.cache;
            t.prot   = a.prot;
            t.qos    = a.qos;
            t.region = a.region;
            t.atop   = a.atop;
            t.user   = a.user;
            widen_aw = t;
        end
    endfunction


    function automatic mst_ar_t widen_ar(
        input slv_ar_t     a,
        input int unsigned m
    );
        mst_ar_t t;
        begin
            t.id     = widen_id(m, a.id);
            t.addr   = a.addr;
            t.len    = a.len;
            t.size   = a.size;
            t.burst  = a.burst;
            t.lock   = a.lock;
            t.cache  = a.cache;
            t.prot   = a.prot;
            t.qos    = a.qos;
            t.region = a.region;
            t.user   = a.user;
            widen_ar = t;
        end
    endfunction


    function automatic slv_b_t narrow_b(input mst_b_t b);
        slv_b_t t;
        begin
            t.id   = b.id[SLV_ID_W-1:0];
            t.resp = b.resp;
            t.user = b.user;
            narrow_b = t;
        end
    endfunction


    function automatic slv_r_t narrow_r(input mst_r_t r);
        slv_r_t t;
        begin
            t.id   = r.id[SLV_ID_W-1:0];
            t.data = r.data;
            t.resp = r.resp;
            t.last = r.last;
            t.user = r.user;
            narrow_r = t;
        end
    endfunction


    // =========================================================================
    // Address decode
    // =========================================================================

    logic [NUM_MST-1:0] aw_mapped;
    logic [NUM_MST-1:0] ar_mapped;

    logic [SSEL_W-1:0] aw_tgt [NUM_MST-1:0];
    logic [SSEL_W-1:0] ar_tgt [NUM_MST-1:0];

    integer dm;
    integer dr;

    always_comb begin
        aw_mapped = '0;
        ar_mapped = '0;

        for (dm = 0; dm < NUM_MST; dm = dm + 1) begin
            aw_tgt[dm] = '0;
            ar_tgt[dm] = '0;

            for (dr = 0; dr < NUM_SLV; dr = dr + 1) begin

                if (!aw_mapped[dm] &&
                    (mst_req[dm].aw.addr >= addr_map[dr].start_addr) &&
                    (mst_req[dm].aw.addr <  addr_map[dr].end_addr) &&
                    (addr_map[dr].mst_port < NUM_SLV)) begin

                    aw_mapped[dm] = 1'b1;
                    aw_tgt[dm] =
                        addr_map[dr].mst_port[SSEL_W-1:0];
                end

                if (!ar_mapped[dm] &&
                    (mst_req[dm].ar.addr >= addr_map[dr].start_addr) &&
                    (mst_req[dm].ar.addr <  addr_map[dr].end_addr) &&
                    (addr_map[dr].mst_port < NUM_SLV)) begin

                    ar_mapped[dm] = 1'b1;
                    ar_tgt[dm] =
                        addr_map[dr].mst_port[SSEL_W-1:0];
                end
            end
        end
    end


    // =========================================================================
    // Outstanding-ID tracking
    //
    // Only one transaction of a particular ID is allowed outstanding in a
    // given direction for a given master.  Different IDs remain fully
    // concurrent.  This is sufficient to enforce per-ID response ordering
    // across different slaves without a data reorder buffer.
    // =========================================================================

    logic [ID_COUNT-1:0] wr_id_busy [NUM_MST-1:0];
    logic [ID_COUNT-1:0] rd_id_busy [NUM_MST-1:0];

    logic [QCNT_W-1:0] wr_outstanding [NUM_MST-1:0];
    logic [QCNT_W-1:0] rd_outstanding [NUM_MST-1:0];


    // =========================================================================
    // Per-master AW routing FIFO
    //
    // AXI W has no transaction ID.  Therefore W follows accepted AWs in
    // acceptance order.  Only route/ID metadata is stored; W data itself is
    // never buffered.
    // =========================================================================

    logic [ROUTE_W-1:0]
        wr_route_q [NUM_MST-1:0][MAX_TRANS-1:0];

    slv_id_t
        wr_id_q [NUM_MST-1:0][MAX_TRANS-1:0];

    logic [QPTR_W-1:0] wrq_wptr  [NUM_MST-1:0];
    logic [QPTR_W-1:0] wrq_rptr  [NUM_MST-1:0];
    logic [QCNT_W-1:0] wrq_count [NUM_MST-1:0];


    // =========================================================================
    // Per-slave AW-owner FIFO
    //
    // This records the global AW acceptance order at each slave.  The W
    // channel to that slave is allowed to come only from the master at the
    // head of this FIFO.
    // =========================================================================

    logic [MSEL_W-1:0]
        owner_q [NUM_SLV-1:0][OWN_DEPTH-1:0];

    logic [OWN_PTR_W-1:0] owner_wptr  [NUM_SLV-1:0];
    logic [OWN_PTR_W-1:0] owner_rptr  [NUM_SLV-1:0];
    logic [OWN_CNT_W-1:0] owner_count [NUM_SLV-1:0];


    // =========================================================================
    // Local DECERR write-response FIFO
    // =========================================================================

    slv_id_t
        berr_q [NUM_MST-1:0][MAX_TRANS-1:0];

    logic [QPTR_W-1:0] berr_wptr  [NUM_MST-1:0];
    logic [QPTR_W-1:0] berr_rptr  [NUM_MST-1:0];
    logic [QCNT_W-1:0] berr_count [NUM_MST-1:0];


    // =========================================================================
    // Local DECERR read FIFO
    //
    // Only metadata is stored.  Error R data is generated directly when the
    // response is selected.
    // =========================================================================

    slv_id_t
        rerr_id_q [NUM_MST-1:0][MAX_TRANS-1:0];

    logic [7:0]
        rerr_len_q [NUM_MST-1:0][MAX_TRANS-1:0];

    logic [QPTR_W-1:0] rerr_wptr  [NUM_MST-1:0];
    logic [QPTR_W-1:0] rerr_rptr  [NUM_MST-1:0];
    logic [QCNT_W-1:0] rerr_count [NUM_MST-1:0];

    logic [7:0] rerr_beat [NUM_MST-1:0];


    // =========================================================================
    // Registered round-robin request grants
    //
    // Grants are registered deliberately.  Therefore READY is determined from
    // previously selected state rather than combinationally from the current
    // corresponding VALID.
    // =========================================================================

    logic aw_gnt_v [NUM_SLV-1:0];
    logic [MSEL_W-1:0] aw_gnt_m [NUM_SLV-1:0];
    logic [MSEL_W-1:0] aw_rr    [NUM_SLV-1:0];

    logic aw_pick_v [NUM_SLV-1:0];
    logic [MSEL_W-1:0] aw_pick_m [NUM_SLV-1:0];


    logic ar_gnt_v [NUM_SLV-1:0];
    logic [MSEL_W-1:0] ar_gnt_m [NUM_SLV-1:0];
    logic [MSEL_W-1:0] ar_rr    [NUM_SLV-1:0];

    logic ar_pick_v [NUM_SLV-1:0];
    logic [MSEL_W-1:0] ar_pick_m [NUM_SLV-1:0];


    // =========================================================================
    // Registered B/R response grants
    //
    // Source NUM_SLV is the local DECERR generator.
    // =========================================================================

    logic b_gnt_v [NUM_MST-1:0];
    logic [SRC_W-1:0] b_gnt_src [NUM_MST-1:0];
    logic [SRC_W-1:0] b_rr      [NUM_MST-1:0];

    logic b_pick_v [NUM_MST-1:0];
    logic [SRC_W-1:0] b_pick_src [NUM_MST-1:0];


    logic r_gnt_v [NUM_MST-1:0];
    logic [SRC_W-1:0] r_gnt_src [NUM_MST-1:0];
    logic [SRC_W-1:0] r_rr      [NUM_MST-1:0];

    logic r_pick_v [NUM_MST-1:0];
    logic [SRC_W-1:0] r_pick_src [NUM_MST-1:0];


    logic b_src_valid [NUM_MST-1:0][SRC_N-1:0];
    logic r_src_valid [NUM_MST-1:0][SRC_N-1:0];


    // =========================================================================
    // Round-robin candidate selection
    // =========================================================================

    integer ps;
    integer po;
    integer pm;
    integer pidx;

    always_comb begin

        // ---------------------------------------------------------------------
        // AW / AR candidates for each slave
        // ---------------------------------------------------------------------

        for (ps = 0; ps < NUM_SLV; ps = ps + 1) begin

            aw_pick_v[ps] = 1'b0;
            aw_pick_m[ps] = aw_rr[ps];

            ar_pick_v[ps] = 1'b0;
            ar_pick_m[ps] = ar_rr[ps];


            for (po = 0; po < NUM_MST; po = po + 1) begin

                pidx = (aw_rr[ps] + po) % NUM_MST;

                if (!aw_pick_v[ps] &&
                    mst_req[pidx].aw_valid &&
                    aw_mapped[pidx] &&
                    (aw_tgt[pidx] == ps) &&
                    (wr_outstanding[pidx] < MAX_TRANS) &&
                    (wrq_count[pidx] < MAX_TRANS) &&
                    (owner_count[ps] < OWN_DEPTH) &&
                    !wr_id_busy[pidx][mst_req[pidx].aw.id]) begin

                    aw_pick_v[ps] = 1'b1;
                    aw_pick_m[ps] = pidx[MSEL_W-1:0];
                end
            end


            for (po = 0; po < NUM_MST; po = po + 1) begin

                pidx = (ar_rr[ps] + po) % NUM_MST;

                if (!ar_pick_v[ps] &&
                    mst_req[pidx].ar_valid &&
                    ar_mapped[pidx] &&
                    (ar_tgt[pidx] == ps) &&
                    (rd_outstanding[pidx] < MAX_TRANS) &&
                    !rd_id_busy[pidx][mst_req[pidx].ar.id]) begin

                    ar_pick_v[ps] = 1'b1;
                    ar_pick_m[ps] = pidx[MSEL_W-1:0];
                end
            end
        end


        // ---------------------------------------------------------------------
        // B / R response-source candidates for each master
        // ---------------------------------------------------------------------

        for (pm = 0; pm < NUM_MST; pm = pm + 1) begin

            for (ps = 0; ps < NUM_SLV; ps = ps + 1) begin

                b_src_valid[pm][ps] =
                    slv_resp[ps].b_valid &&
                    (slv_resp[ps].b.id[MST_ID_W-1:SLV_ID_W] == pm) &&
                    wr_id_busy[pm]
                        [slv_resp[ps].b.id[SLV_ID_W-1:0]];

                r_src_valid[pm][ps] =
                    slv_resp[ps].r_valid &&
                    (slv_resp[ps].r.id[MST_ID_W-1:SLV_ID_W] == pm) &&
                    rd_id_busy[pm]
                        [slv_resp[ps].r.id[SLV_ID_W-1:0]];
            end

            // Local decode-error response source.
            b_src_valid[pm][NUM_SLV] = (berr_count[pm] != 0);
            r_src_valid[pm][NUM_SLV] = (rerr_count[pm] != 0);


            b_pick_v[pm]   = 1'b0;
            b_pick_src[pm] = b_rr[pm];

            r_pick_v[pm]   = 1'b0;
            r_pick_src[pm] = r_rr[pm];


            for (po = 0; po < SRC_N; po = po + 1) begin

                pidx = (b_rr[pm] + po) % SRC_N;

                if (!b_pick_v[pm] &&
                    b_src_valid[pm][pidx]) begin

                    b_pick_v[pm] = 1'b1;
                    b_pick_src[pm] = pidx[SRC_W-1:0];
                end
            end


            for (po = 0; po < SRC_N; po = po + 1) begin

                pidx = (r_rr[pm] + po) % SRC_N;

                if (!r_pick_v[pm] &&
                    r_src_valid[pm][pidx]) begin

                    r_pick_v[pm] = 1'b1;
                    r_pick_src[pm] = pidx[SRC_W-1:0];
                end
            end
        end
    end


    // =========================================================================
    // Handshake/event signals
    // =========================================================================

    logic aw_accept [NUM_MST-1:0];
    logic [ROUTE_W-1:0] aw_accept_route [NUM_MST-1:0];

    logic ar_accept     [NUM_MST-1:0];
    logic ar_accept_err [NUM_MST-1:0];

    logic aw_fire_s [NUM_SLV-1:0];
    logic ar_fire_s [NUM_SLV-1:0];

    logic owner_pop [NUM_SLV-1:0];
    logic [MSEL_W-1:0] owner_enq_m [NUM_SLV-1:0];

    logic wrq_pop  [NUM_MST-1:0];
    logic berr_enq [NUM_MST-1:0];

    logic b_fire       [NUM_MST-1:0];
    logic b_fire_local [NUM_MST-1:0];

    logic r_fire       [NUM_MST-1:0];
    logic r_fire_local [NUM_MST-1:0];
    logic r_fire_last  [NUM_MST-1:0];


    // =========================================================================
    // Main combinational datapath
    // =========================================================================

    integer cm;
    integer cs;

    always_comb begin

        // ---------------------------------------------------------------------
        // Defaults
        // ---------------------------------------------------------------------

        for (cm = 0; cm < NUM_MST; cm = cm + 1) begin

            mst_resp[cm] = '0;

            aw_accept[cm]       = 1'b0;
            aw_accept_route[cm] =
                ERR_ROUTE[ROUTE_W-1:0];

            ar_accept[cm]     = 1'b0;
            ar_accept_err[cm] = 1'b0;

            wrq_pop[cm]  = 1'b0;
            berr_enq[cm] = 1'b0;

            b_fire[cm]       = 1'b0;
            b_fire_local[cm] = 1'b0;

            r_fire[cm]       = 1'b0;
            r_fire_local[cm] = 1'b0;
            r_fire_last[cm]  = 1'b0;
        end


        for (cs = 0; cs < NUM_SLV; cs = cs + 1) begin

            slv_req[cs] = '0;

            aw_fire_s[cs] = 1'b0;
            ar_fire_s[cs] = 1'b0;

            owner_pop[cs]   = 1'b0;
            owner_enq_m[cs] = '0;
        end


        // All output VALIDs remain zero during synchronous active-low reset.
        if (rst_n) begin

            // =================================================================
            // Local acceptance for unmapped addresses
            //
            // READY depends on address/space/ID state, but not on current VALID.
            // =================================================================

            for (cm = 0; cm < NUM_MST; cm = cm + 1) begin

                if (!aw_mapped[cm] &&
                    (wr_outstanding[cm] < MAX_TRANS) &&
                    (wrq_count[cm] < MAX_TRANS) &&
                    !wr_id_busy[cm][mst_req[cm].aw.id]) begin

                    mst_resp[cm].aw_ready = 1'b1;
                end


                if (!ar_mapped[cm] &&
                    (rd_outstanding[cm] < MAX_TRANS) &&
                    (rerr_count[cm] < MAX_TRANS) &&
                    !rd_id_busy[cm][mst_req[cm].ar.id]) begin

                    mst_resp[cm].ar_ready = 1'b1;
                end
            end


            // =================================================================
            // Mapped AW / AR forwarding
            // =================================================================

            for (cs = 0; cs < NUM_SLV; cs = cs + 1) begin

                if (aw_gnt_v[cs]) begin

                    slv_req[cs].aw =
                        widen_aw(
                            mst_req[aw_gnt_m[cs]].aw,
                            aw_gnt_m[cs]
                        );

                    slv_req[cs].aw_valid =
                        mst_req[aw_gnt_m[cs]].aw_valid;

                    mst_resp[aw_gnt_m[cs]].aw_ready =
                        slv_resp[cs].aw_ready;
                end


                if (ar_gnt_v[cs]) begin

                    slv_req[cs].ar =
                        widen_ar(
                            mst_req[ar_gnt_m[cs]].ar,
                            ar_gnt_m[cs]
                        );

                    slv_req[cs].ar_valid =
                        mst_req[ar_gnt_m[cs]].ar_valid;

                    mst_resp[ar_gnt_m[cs]].ar_ready =
                        slv_resp[cs].ar_ready;
                end
            end


            // =================================================================
            // W channel
            //
            // A master's current W transaction is the head of its accepted-AW
            // FIFO.  For a mapped transaction the corresponding slave owner
            // FIFO must also name this master.
            // =================================================================

            for (cm = 0; cm < NUM_MST; cm = cm + 1) begin

                if (wrq_count[cm] != 0) begin

                    if (wr_route_q[cm][wrq_rptr[cm]]
                        == ERR_ROUTE) begin

                        // Consume all W beats locally.  B DECERR is generated
                        // only after the final W beat.
                        mst_resp[cm].w_ready = 1'b1;

                    end else begin

                        cs =
                            wr_route_q[cm][wrq_rptr[cm]];

                        if ((owner_count[cs] != 0) &&
                            (owner_q[cs][owner_rptr[cs]]
                                == cm)) begin

                            slv_req[cs].w =
                                mst_req[cm].w;

                            slv_req[cs].w_valid =
                                mst_req[cm].w_valid;

                            mst_resp[cm].w_ready =
                                slv_resp[cs].w_ready;
                        end
                    end
                end
            end


            // =================================================================
            // B response routing
            // =================================================================

            for (cm = 0; cm < NUM_MST; cm = cm + 1) begin

                if (b_gnt_v[cm]) begin

                    if (b_gnt_src[cm] == NUM_SLV) begin

                        mst_resp[cm].b_valid =
                            (berr_count[cm] != 0);

                        mst_resp[cm].b.id =
                            berr_q[cm][berr_rptr[cm]];

                        mst_resp[cm].b.resp =
                            RESP_DECERR;

                        mst_resp[cm].b.user = '0;

                    end else begin

                        cs = b_gnt_src[cm];

                        mst_resp[cm].b_valid =
                            slv_resp[cs].b_valid;

                        mst_resp[cm].b =
                            narrow_b(slv_resp[cs].b);

                        slv_req[cs].b_ready =
                            mst_req[cm].b_ready;
                    end
                end
            end


            // =================================================================
            // R response routing
            // =================================================================

            for (cm = 0; cm < NUM_MST; cm = cm + 1) begin

                if (r_gnt_v[cm]) begin

                    if (r_gnt_src[cm] == NUM_SLV) begin

                        mst_resp[cm].r_valid =
                            (rerr_count[cm] != 0);

                        mst_resp[cm].r.id =
                            rerr_id_q[cm][rerr_rptr[cm]];

                        mst_resp[cm].r.data = '0;
                        mst_resp[cm].r.resp = RESP_DECERR;

                        mst_resp[cm].r.last =
                            (rerr_beat[cm] ==
                             rerr_len_q[cm][rerr_rptr[cm]]);

                        mst_resp[cm].r.user = '0;

                    end else begin

                        cs = r_gnt_src[cm];

                        mst_resp[cm].r_valid =
                            slv_resp[cs].r_valid;

                        mst_resp[cm].r =
                            narrow_r(slv_resp[cs].r);

                        slv_req[cs].r_ready =
                            mst_req[cm].r_ready;
                    end
                end
            end


            // =================================================================
            // Request acceptance events
            // =================================================================

            for (cm = 0; cm < NUM_MST; cm = cm + 1) begin

                if (mst_req[cm].aw_valid &&
                    mst_resp[cm].aw_ready) begin

                    aw_accept[cm] = 1'b1;

                    if (aw_mapped[cm])
                        aw_accept_route[cm] = aw_tgt[cm];
                    else
                        aw_accept_route[cm] =
                            ERR_ROUTE[ROUTE_W-1:0];
                end


                if (mst_req[cm].ar_valid &&
                    mst_resp[cm].ar_ready) begin

                    ar_accept[cm] = 1'b1;
                    ar_accept_err[cm] = !ar_mapped[cm];
                end
            end


            for (cs = 0; cs < NUM_SLV; cs = cs + 1) begin

                aw_fire_s[cs] =
                    slv_req[cs].aw_valid &&
                    slv_resp[cs].aw_ready;

                ar_fire_s[cs] =
                    slv_req[cs].ar_valid &&
                    slv_resp[cs].ar_ready;

                if (aw_fire_s[cs])
                    owner_enq_m[cs] = aw_gnt_m[cs];
            end


            // =================================================================
            // W transaction completion
            // =================================================================

            for (cm = 0; cm < NUM_MST; cm = cm + 1) begin

                if ((wrq_count[cm] != 0) &&
                    mst_req[cm].w_valid &&
                    mst_resp[cm].w_ready &&
                    mst_req[cm].w.last) begin

                    wrq_pop[cm] = 1'b1;

                    if (wr_route_q[cm][wrq_rptr[cm]]
                        == ERR_ROUTE) begin

                        berr_enq[cm] = 1'b1;

                    end else begin

                        cs =
                            wr_route_q[cm][wrq_rptr[cm]];

                        owner_pop[cs] = 1'b1;
                    end
                end
            end


            // =================================================================
            // Response completion
            // =================================================================

            for (cm = 0; cm < NUM_MST; cm = cm + 1) begin

                b_fire[cm] =
                    mst_resp[cm].b_valid &&
                    mst_req[cm].b_ready;

                b_fire_local[cm] =
                    b_fire[cm] &&
                    b_gnt_v[cm] &&
                    (b_gnt_src[cm] == NUM_SLV);


                r_fire[cm] =
                    mst_resp[cm].r_valid &&
                    mst_req[cm].r_ready;

                r_fire_local[cm] =
                    r_fire[cm] &&
                    r_gnt_v[cm] &&
                    (r_gnt_src[cm] == NUM_SLV);

                r_fire_last[cm] =
                    r_fire[cm] &&
                    mst_resp[cm].r.last;
            end
        end
    end


    // =========================================================================
    // Sequential state
    // =========================================================================

    integer i;
    integer j;

    always_ff @(posedge clk) begin

        if (!rst_n) begin

            // -----------------------------------------------------------------
            // Master state
            // -----------------------------------------------------------------

            for (i = 0; i < NUM_MST; i = i + 1) begin

                wr_id_busy[i] <= '0;
                rd_id_busy[i] <= '0;

                wr_outstanding[i] <= '0;
                rd_outstanding[i] <= '0;

                wrq_wptr[i]  <= '0;
                wrq_rptr[i]  <= '0;
                wrq_count[i] <= '0;

                berr_wptr[i]  <= '0;
                berr_rptr[i]  <= '0;
                berr_count[i] <= '0;

                rerr_wptr[i]  <= '0;
                rerr_rptr[i]  <= '0;
                rerr_count[i] <= '0;
                rerr_beat[i]  <= '0;

                b_gnt_v[i]   <= 1'b0;
                b_gnt_src[i] <= '0;
                b_rr[i]      <= '0;

                r_gnt_v[i]   <= 1'b0;
                r_gnt_src[i] <= '0;
                r_rr[i]      <= '0;
            end


            // -----------------------------------------------------------------
            // Slave state
            // -----------------------------------------------------------------

            for (j = 0; j < NUM_SLV; j = j + 1) begin

                owner_wptr[j]  <= '0;
                owner_rptr[j]  <= '0;
                owner_count[j] <= '0;

                aw_gnt_v[j] <= 1'b0;
                aw_gnt_m[j] <= '0;
                aw_rr[j]    <= '0;

                ar_gnt_v[j] <= 1'b0;
                ar_gnt_m[j] <= '0;
                ar_rr[j]    <= '0;
            end

        end else begin

            // =================================================================
            // AW / AR arbitration state
            // =================================================================

            for (j = 0; j < NUM_SLV; j = j + 1) begin

                // -------------------------------------------------------------
                // AW
                // -------------------------------------------------------------

                if (aw_gnt_v[j]) begin

                    if (aw_fire_s[j]) begin

                        aw_gnt_v[j] <= 1'b0;

                        if (aw_gnt_m[j] == NUM_MST-1)
                            aw_rr[j] <= '0;
                        else
                            aw_rr[j] <= aw_gnt_m[j] + 1'b1;
                    end

                end else if (aw_pick_v[j]) begin

                    aw_gnt_v[j] <= 1'b1;
                    aw_gnt_m[j] <= aw_pick_m[j];
                end


                // -------------------------------------------------------------
                // AR
                // -------------------------------------------------------------

                if (ar_gnt_v[j]) begin

                    if (ar_fire_s[j]) begin

                        ar_gnt_v[j] <= 1'b0;

                        if (ar_gnt_m[j] == NUM_MST-1)
                            ar_rr[j] <= '0;
                        else
                            ar_rr[j] <= ar_gnt_m[j] + 1'b1;
                    end

                end else if (ar_pick_v[j]) begin

                    ar_gnt_v[j] <= 1'b1;
                    ar_gnt_m[j] <= ar_pick_m[j];
                end
            end


            // =================================================================
            // B / R arbitration state
            // =================================================================

            for (i = 0; i < NUM_MST; i = i + 1) begin

                // -------------------------------------------------------------
                // B
                // -------------------------------------------------------------

                if (b_gnt_v[i]) begin

                    if (b_fire[i]) begin

                        b_gnt_v[i] <= 1'b0;

                        if (b_gnt_src[i] == SRC_N-1)
                            b_rr[i] <= '0;
                        else
                            b_rr[i] <= b_gnt_src[i] + 1'b1;
                    end

                end else if (b_pick_v[i]) begin

                    b_gnt_v[i]   <= 1'b1;
                    b_gnt_src[i] <= b_pick_src[i];
                end


                // -------------------------------------------------------------
                // R
                // -------------------------------------------------------------

                if (r_gnt_v[i]) begin

                    if (r_fire[i]) begin

                        r_gnt_v[i] <= 1'b0;

                        if (r_gnt_src[i] == SRC_N-1)
                            r_rr[i] <= '0;
                        else
                            r_rr[i] <= r_gnt_src[i] + 1'b1;
                    end

                end else if (r_pick_v[i]) begin

                    r_gnt_v[i]   <= 1'b1;
                    r_gnt_src[i] <= r_pick_src[i];
                end
            end


            // =================================================================
            // Per-master queues/counters
            // =================================================================

            for (i = 0; i < NUM_MST; i = i + 1) begin

                // -------------------------------------------------------------
                // Busy write IDs
                // -------------------------------------------------------------

                if (aw_accept[i])
                    wr_id_busy[i]
                        [mst_req[i].aw.id] <= 1'b1;

                if (b_fire[i])
                    wr_id_busy[i]
                        [mst_resp[i].b.id] <= 1'b0;


                // -------------------------------------------------------------
                // Busy read IDs
                // -------------------------------------------------------------

                if (ar_accept[i])
                    rd_id_busy[i]
                        [mst_req[i].ar.id] <= 1'b1;

                if (r_fire_last[i])
                    rd_id_busy[i]
                        [mst_resp[i].r.id] <= 1'b0;


                // -------------------------------------------------------------
                // Outstanding write transaction count
                // -------------------------------------------------------------

                case ({aw_accept[i], b_fire[i]})

                    2'b10:
                        wr_outstanding[i] <=
                            wr_outstanding[i] + 1'b1;

                    2'b01:
                        wr_outstanding[i] <=
                            wr_outstanding[i] - 1'b1;

                    default:
                        wr_outstanding[i] <=
                            wr_outstanding[i];

                endcase


                // -------------------------------------------------------------
                // Outstanding read transaction count
                // -------------------------------------------------------------

                case ({ar_accept[i], r_fire_last[i]})

                    2'b10:
                        rd_outstanding[i] <=
                            rd_outstanding[i] + 1'b1;

                    2'b01:
                        rd_outstanding[i] <=
                            rd_outstanding[i] - 1'b1;

                    default:
                        rd_outstanding[i] <=
                            rd_outstanding[i];

                endcase


                // -------------------------------------------------------------
                // Per-master AW route FIFO enqueue
                // -------------------------------------------------------------

                if (aw_accept[i]) begin

                    wr_route_q[i][wrq_wptr[i]] <=
                        aw_accept_route[i];

                    wr_id_q[i][wrq_wptr[i]] <=
                        mst_req[i].aw.id;

                    if (wrq_wptr[i] == MAX_TRANS-1)
                        wrq_wptr[i] <= '0;
                    else
                        wrq_wptr[i] <=
                            wrq_wptr[i] + 1'b1;
                end


                // -------------------------------------------------------------
                // AW route FIFO pop at WLAST
                // -------------------------------------------------------------

                if (wrq_pop[i]) begin

                    if (wrq_rptr[i] == MAX_TRANS-1)
                        wrq_rptr[i] <= '0;
                    else
                        wrq_rptr[i] <=
                            wrq_rptr[i] + 1'b1;
                end


                case ({aw_accept[i], wrq_pop[i]})

                    2'b10:
                        wrq_count[i] <=
                            wrq_count[i] + 1'b1;

                    2'b01:
                        wrq_count[i] <=
                            wrq_count[i] - 1'b1;

                    default:
                        wrq_count[i] <=
                            wrq_count[i];

                endcase


                // -------------------------------------------------------------
                // Local DECERR B FIFO enqueue
                //
                // The ID is the ID of the AW entry whose WLAST is being
                // consumed this cycle.
                // -------------------------------------------------------------

                if (berr_enq[i]) begin

                    berr_q[i][berr_wptr[i]] <=
                        wr_id_q[i][wrq_rptr[i]];

                    if (berr_wptr[i] == MAX_TRANS-1)
                        berr_wptr[i] <= '0;
                    else
                        berr_wptr[i] <=
                            berr_wptr[i] + 1'b1;
                end


                if (b_fire_local[i]) begin

                    if (berr_rptr[i] == MAX_TRANS-1)
                        berr_rptr[i] <= '0;
                    else
                        berr_rptr[i] <=
                            berr_rptr[i] + 1'b1;
                end


                case ({
                    berr_enq[i],
                    b_fire_local[i]
                })

                    2'b10:
                        berr_count[i] <=
                            berr_count[i] + 1'b1;

                    2'b01:
                        berr_count[i] <=
                            berr_count[i] - 1'b1;

                    default:
                        berr_count[i] <=
                            berr_count[i];

                endcase


                // -------------------------------------------------------------
                // Local DECERR read FIFO enqueue
                // -------------------------------------------------------------

                if (ar_accept[i] &&
                    ar_accept_err[i]) begin

                    rerr_id_q[i][rerr_wptr[i]] <=
                        mst_req[i].ar.id;

                    rerr_len_q[i][rerr_wptr[i]] <=
                        mst_req[i].ar.len;

                    if (rerr_wptr[i] == MAX_TRANS-1)
                        rerr_wptr[i] <= '0;
                    else
                        rerr_wptr[i] <=
                            rerr_wptr[i] + 1'b1;
                end


                // -------------------------------------------------------------
                // Local DECERR read beat advancement
                // -------------------------------------------------------------

                if (r_fire_local[i]) begin

                    if (mst_resp[i].r.last) begin

                        if (rerr_rptr[i] == MAX_TRANS-1)
                            rerr_rptr[i] <= '0;
                        else
                            rerr_rptr[i] <=
                                rerr_rptr[i] + 1'b1;

                        rerr_beat[i] <= '0;

                    end else begin

                        rerr_beat[i] <=
                            rerr_beat[i] + 1'b1;
                    end
                end


                case ({
                    (ar_accept[i] && ar_accept_err[i]),
                    (r_fire_local[i] &&
                     mst_resp[i].r.last)
                })

                    2'b10:
                        rerr_count[i] <=
                            rerr_count[i] + 1'b1;

                    2'b01:
                        rerr_count[i] <=
                            rerr_count[i] - 1'b1;

                    default:
                        rerr_count[i] <=
                            rerr_count[i];

                endcase
            end


            // =================================================================
            // Per-slave AW owner queues
            // =================================================================

            for (j = 0; j < NUM_SLV; j = j + 1) begin

                if (aw_fire_s[j]) begin

                    owner_q[j][owner_wptr[j]] <=
                        owner_enq_m[j];

                    if (owner_wptr[j] == OWN_DEPTH-1)
                        owner_wptr[j] <= '0;
                    else
                        owner_wptr[j] <=
                            owner_wptr[j] + 1'b1;
                end


                if (owner_pop[j]) begin

                    if (owner_rptr[j] == OWN_DEPTH-1)
                        owner_rptr[j] <= '0;
                    else
                        owner_rptr[j] <=
                            owner_rptr[j] + 1'b1;
                end


                case ({aw_fire_s[j], owner_pop[j]})

                    2'b10:
                        owner_count[j] <=
                            owner_count[j] + 1'b1;

                    2'b01:
                        owner_count[j] <=
                            owner_count[j] - 1'b1;

                    default:
                        owner_count[j] <=
                            owner_count[j];

                endcase
            end
        end
    end


    // =========================================================================
    // Parameter legality
    // =========================================================================

    initial begin

        if (!((NUM_MST == 2) ||
              (NUM_MST == 4)))
            $fatal(
                1,
                "axi4_xbar: NUM_MST must be 2 or 4"
            );

        if (!((NUM_SLV == 2) ||
              (NUM_SLV == 4)))
            $fatal(
                1,
                "axi4_xbar: NUM_SLV must be 2 or 4"
            );

        if (!((MAX_TRANS == 2) ||
              (MAX_TRANS == 8)))
            $fatal(
                1,
                "axi4_xbar: MAX_TRANS must be 2 or 8"
            );

        if (!((MAX_BURST_LEN == 3) ||
              (MAX_BURST_LEN == 255)))
            $fatal(
                1,
                "axi4_xbar: MAX_BURST_LEN must be 3 or 255"
            );
    end

endmodule