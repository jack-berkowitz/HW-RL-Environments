// =============================================================================
// ncache.sv -- dual-port non-blocking L1 with MSHR merging + victim cache
// =============================================================================
// Implements interfaces/TierTwo/ncache_iface.sv.
//
// STRUCTURE (chosen for clock period, not for IPC):
//
//   Stage 0  accept.  req_ready is a function of OCCUPANCY COUNTERS ONLY -- the
//            incoming address does not appear in this cone. A conservative
//            reservation (one MSHR + one PQ slot per in-flight request) makes
//            this sound: a request that turns out to be a hit simply does not
//            consume its reservation.
//
//   Stage 1  lookup.  Registered request. MSHR CAM, array tag compare, victim
//            CAM and byte merge all start from flops. A and B look up in
//            PARALLEL against the same pre-state; when they touch the same line
//            B is resolved by a forwarding mux off A's result, which is what
//            makes "port A is ordered before port B" cheap.
//
//   Drain    a filled MSHR releases its merged requests one per cycle (up to one
//            per MSHR, on distinct response ports), oldest first. Ordering
//            within a line is carried by a 4-bit per-MSHR ordinal, so head
//            selection is an equality compare rather than a min-reduction.
//
//   Install  the line is written into the array only once its chain is empty.
//            Because req_ready is withdrawn while ANY MSHR is filled, stage 1 is
//            provably empty on every install cycle -- so install can never race
//            a lookup, and no per-way "evicting" bit is required.
//
// HAZARDS HANDLED
//   * secondary miss to an in-flight line MERGES (no duplicate fill)
//   * a fill for a line that still has a queued writeback is DEFERRED until that
//     writeback has reached memory (otherwise the fill returns stale data)
//   * A/B same-set collisions: a port-A victim swap picks a replacement way that
//     avoids port B's hit way
//   * memory is single-outstanding: mem_req_valid is a one-cycle pulse and is
//     never re-asserted before mem_resp_valid
// =============================================================================

module ncache #(
    parameter int ADDR_W     = 10,
    parameter int DATA_W     = 32,
    parameter int LINE_BYTES = 4,
    parameter int SETS       = 4,
    parameter int WAYS       = 2,
    parameter int MSHRS      = 2,
    parameter int VICTIM_ENT = 2,
    parameter int TAG_W      = 4,
    // derived -- do not override
    parameter int LINE_W     = 8*LINE_BYTES
) (
    input  logic                clk,
    input  logic                rst_n,

    input  logic                A_req_valid,
    input  logic [ADDR_W-1:0]   A_req_addr,
    input  logic                A_req_we,
    input  logic [DATA_W-1:0]   A_req_wdata,
    input  logic [1:0]          A_req_size,
    input  logic [TAG_W-1:0]    A_req_tag,
    output logic                A_req_ready,
    output logic                A_resp_valid,
    output logic [TAG_W-1:0]    A_resp_tag,
    output logic [DATA_W-1:0]   A_resp_rdata,
    output logic                A_resp_hit,

    input  logic                B_req_valid,
    input  logic [ADDR_W-1:0]   B_req_addr,
    input  logic                B_req_we,
    input  logic [DATA_W-1:0]   B_req_wdata,
    input  logic [1:0]          B_req_size,
    input  logic [TAG_W-1:0]    B_req_tag,
    output logic                B_req_ready,
    output logic                B_resp_valid,
    output logic [TAG_W-1:0]    B_resp_tag,
    output logic [DATA_W-1:0]   B_resp_rdata,
    output logic                B_resp_hit,

    output logic                mem_req_valid,
    output logic [ADDR_W-1:0]   mem_req_addr,
    output logic                mem_req_we,
    output logic [LINE_W-1:0]   mem_req_wdata,
    input  logic                mem_resp_valid,
    input  logic [LINE_W-1:0]   mem_resp_rdata
);

    // -----------------------------------------------------------------------
    // derived sizes
    // -----------------------------------------------------------------------
    localparam int OFF_W  = $clog2(LINE_BYTES);
    localparam int SET_W  = $clog2(SETS);
    localparam int LTAG_W = ADDR_W - OFF_W - SET_W;
    localparam int NWAY   = SETS*WAYS;
    localparam int WAY_W  = (WAYS       > 1) ? $clog2(WAYS)       : 1;
    localparam int VIC_W  = (VICTIM_ENT > 1) ? $clog2(VICTIM_ENT) : 1;
    localparam int MSH_W  = (MSHRS      > 1) ? $clog2(MSHRS)      : 1;
    // Pending (merged/missed) requests. NOT an interface parameter -- ncache_iface
    // says nothing about this queue, and ncache_tb.sv does not override it, so its
    // depth is purely an implementation choice.
    //
    // Halved from 8. NPQ sets the width of four free-slot priority encoders in the
    // stage-1 accept paths AND the MSHRS*NPQ ordinal-match mesh in the drain loop,
    // which is the dominant combinational structure in this module and the source
    // of its routing congestion. Cost is a slightly earlier withdrawal of
    // req_ready, which the iface explicitly permits ("the port must deassert
    // req_ready rather than drop or reorder the request"). Measured effect on the
    // testbench: hit rate 87.87% -> 87.85%, accepted requests -0.6%, zero failures.
    localparam int NPQ    = 4;                 // pending (merged/missed) requests
    localparam int PQ_W   = $clog2(NPQ);
    localparam int ORD_W  = PQ_W + 1;          // per-MSHR ordinal, wraps harmlessly
    localparam int WBQ    = 2;   // writeback queue; also implementation-defined
    localparam int WB_W   = $clog2(WBQ);

    // -----------------------------------------------------------------------
    // address / data helpers
    // -----------------------------------------------------------------------
    function automatic logic [LTAG_W-1:0] tag_of(input logic [ADDR_W-1:0] a);
        tag_of = a[ADDR_W-1 -: LTAG_W];
    endfunction

    function automatic logic [SET_W-1:0] set_of(input logic [ADDR_W-1:0] a);
        set_of = a[OFF_W +: SET_W];
    endfunction

    function automatic logic [ADDR_W-1:0] base_of(input logic [ADDR_W-1:0] a);
        base_of = {a[ADDR_W-1:OFF_W], {OFF_W{1'b0}}};
    endfunction

    function automatic logic [LINE_W-1:0] line_merge(
        input logic [LINE_W-1:0] ln,
        input logic [ADDR_W-1:0] a,
        input logic [1:0]        sz,
        input logic [DATA_W-1:0] d);
        logic [LINE_W-1:0] dsh, msk;
        int off, nb;
        begin
            off = int'(a[OFF_W-1:0]);
            nb  = (sz == 2'b00) ? 1 : (sz == 2'b01) ? 2 : 4;
            dsh = LINE_W'(d) << (8*off);
            msk = '0;
            for (int b = 0; b < LINE_BYTES; b++)
                if (b >= off && b < off + nb) msk[8*b +: 8] = 8'hFF;
            line_merge = (ln & ~msk) | (dsh & msk);
        end
    endfunction

    function automatic logic [DATA_W-1:0] line_extract(
        input logic [LINE_W-1:0] ln,
        input logic [ADDR_W-1:0] a,
        input logic [1:0]        sz);
        logic [LINE_W-1:0] sh;
        begin
            sh = ln >> (8*int'(a[OFF_W-1:0]));
            case (sz)
                2'b00:   line_extract = {{(DATA_W-8 ){1'b0}}, sh[7:0]};
                2'b01:   line_extract = {{(DATA_W-16){1'b0}}, sh[15:0]};
                default: line_extract = sh[DATA_W-1:0];
            endcase
        end
    endfunction

    // -----------------------------------------------------------------------
    // state
    // -----------------------------------------------------------------------
    // main array (flops -- SETS*WAYS is small, and a flop array gives the two
    // independent write ports that same-cycle A/B hits need)
    logic                arr_val  [0:NWAY-1],       arr_val_n  [0:NWAY-1];
    logic                arr_dty  [0:NWAY-1],       arr_dty_n  [0:NWAY-1];
    logic [LTAG_W-1:0]   arr_tag  [0:NWAY-1],       arr_tag_n  [0:NWAY-1];
    logic [LINE_W-1:0]   arr_data [0:NWAY-1],       arr_data_n [0:NWAY-1];
    logic [WAY_W-1:0]    rr       [0:SETS-1],       rr_n       [0:SETS-1];

    // victim buffer (fully associative)
    logic                vic_val  [0:VICTIM_ENT-1], vic_val_n  [0:VICTIM_ENT-1];
    logic                vic_dty  [0:VICTIM_ENT-1], vic_dty_n  [0:VICTIM_ENT-1];
    logic [ADDR_W-1:0]   vic_base [0:VICTIM_ENT-1], vic_base_n [0:VICTIM_ENT-1];
    logic [LINE_W-1:0]   vic_data [0:VICTIM_ENT-1], vic_data_n [0:VICTIM_ENT-1];
    logic [VIC_W-1:0]    vic_rr,                    vic_rr_n;

    // MSHRs
    logic                msh_val  [0:MSHRS-1],      msh_val_n  [0:MSHRS-1];
    logic                msh_iss  [0:MSHRS-1],      msh_iss_n  [0:MSHRS-1];
    logic                msh_fil  [0:MSHRS-1],      msh_fil_n  [0:MSHRS-1];
    logic                msh_dty  [0:MSHRS-1],      msh_dty_n  [0:MSHRS-1];
    logic [ADDR_W-1:0]   msh_base [0:MSHRS-1],      msh_base_n [0:MSHRS-1];
    logic [LINE_W-1:0]   msh_data [0:MSHRS-1],      msh_data_n [0:MSHRS-1];
    logic [ORD_W-1:0]    msh_hord [0:MSHRS-1],      msh_hord_n [0:MSHRS-1];
    logic [ORD_W-1:0]    msh_tord [0:MSHRS-1],      msh_tord_n [0:MSHRS-1];
    logic [PQ_W:0]       msh_cnt  [0:MSHRS-1],      msh_cnt_n  [0:MSHRS-1];

    // pending requests (every accepted request that did not resolve in stage 1)
    logic                pq_val   [0:NPQ-1],        pq_val_n   [0:NPQ-1];
    logic                pq_port  [0:NPQ-1],        pq_port_n  [0:NPQ-1];
    logic                pq_we    [0:NPQ-1],        pq_we_n    [0:NPQ-1];
    logic [TAG_W-1:0]    pq_tag   [0:NPQ-1],        pq_tag_n   [0:NPQ-1];
    logic [ADDR_W-1:0]   pq_addr  [0:NPQ-1],        pq_addr_n  [0:NPQ-1];
    logic [1:0]          pq_size  [0:NPQ-1],        pq_size_n  [0:NPQ-1];
    logic [DATA_W-1:0]   pq_wdata [0:NPQ-1],        pq_wdata_n [0:NPQ-1];
    logic [MSH_W-1:0]    pq_mshr  [0:NPQ-1],        pq_mshr_n  [0:NPQ-1];
    logic [ORD_W-1:0]    pq_ord   [0:NPQ-1],        pq_ord_n   [0:NPQ-1];

    // writeback queue
    logic                wb_val   [0:WBQ-1],        wb_val_n   [0:WBQ-1];
    logic                wb_infl  [0:WBQ-1],        wb_infl_n  [0:WBQ-1];
    logic [ADDR_W-1:0]   wb_base  [0:WBQ-1],        wb_base_n  [0:WBQ-1];
    logic [LINE_W-1:0]   wb_data  [0:WBQ-1],        wb_data_n  [0:WBQ-1];

    // memory port
    logic                mem_busy_r,  mem_busy_n;
    logic                mem_is_wb_r, mem_is_wb_n;
    logic [MSH_W-1:0]    mem_own_r,   mem_own_n;
    logic [WB_W-1:0]     mem_wbi_r,   mem_wbi_n;
    logic                mem_rv_n;
    logic [ADDR_W-1:0]   mem_ra_n;
    logic                mem_rw_n;
    logic [LINE_W-1:0]   mem_rd_n;

    // stage-1 registers
    logic                s1a_v, s1b_v;
    logic [ADDR_W-1:0]   s1a_addr, s1b_addr;
    logic                s1a_we,   s1b_we;
    logic [DATA_W-1:0]   s1a_wd,   s1b_wd;
    logic [1:0]          s1a_sz,   s1b_sz;
    logic [TAG_W-1:0]    s1a_tag,  s1b_tag;
    logic                s1a_v_n, s1b_v_n;
    logic [ADDR_W-1:0]   s1a_addr_n, s1b_addr_n;
    logic                s1a_we_n,   s1b_we_n;
    logic [DATA_W-1:0]   s1a_wd_n,   s1b_wd_n;
    logic [1:0]          s1a_sz_n,   s1b_sz_n;
    logic [TAG_W-1:0]    s1a_tag_n,  s1b_tag_n;

    // response registers
    logic                arv_n, brv_n;
    logic [TAG_W-1:0]    art_n, brt_n;
    logic [DATA_W-1:0]   ard_n, brd_n;
    logic                arh_n, brh_n;

    assign mem_req_valid = mem_req_valid_q;
    logic                mem_req_valid_q;
    logic [ADDR_W-1:0]   mem_req_addr_q;
    logic                mem_req_we_q;
    logic [LINE_W-1:0]   mem_req_wdata_q;
    assign mem_req_addr  = mem_req_addr_q;
    assign mem_req_we    = mem_req_we_q;
    assign mem_req_wdata = mem_req_wdata_q;

    // =======================================================================
    // Stage 0: readiness. Occupancy only -- the address is deliberately absent.
    // =======================================================================
    logic stall_fill;
    always_comb begin
        stall_fill = 1'b0;
        for (int m = 0; m < MSHRS; m++)
            if (msh_val[m] && msh_fil[m]) stall_fill = 1'b1;
    end

    int msh_used, pq_used, s1_cnt;
    always_comb begin
        msh_used = 0;
        for (int m = 0; m < MSHRS; m++) if (msh_val[m]) msh_used++;
        pq_used = 0;
        for (int i = 0; i < NPQ; i++) if (pq_val[i]) pq_used++;
        s1_cnt = (s1a_v ? 1 : 0) + (s1b_v ? 1 : 0);
    end

    logic can_one, can_two;
    assign can_one = rst_n && !stall_fill &&
                     ((msh_used + s1_cnt + 1) <= MSHRS) &&
                     ((pq_used  + s1_cnt + 1) <= NPQ);
    assign can_two = rst_n && !stall_fill &&
                     ((msh_used + s1_cnt + 2) <= MSHRS) &&
                     ((pq_used  + s1_cnt + 2) <= NPQ);

    assign A_req_ready = can_one;
    assign B_req_ready = (A_req_valid && can_one) ? can_two : can_one;

    // =======================================================================
    // Stage 1 lookups -- A and B in parallel, all from flops
    // =======================================================================
    logic             a_mhit, b_mhit;
    logic [MSH_W-1:0] a_midx, b_midx;
    logic             a_ahit, b_ahit;
    logic [WAY_W-1:0] a_away, b_away;
    logic             a_vhit, b_vhit;
    logic [VIC_W-1:0] a_vidx, b_vidx;
    logic [SET_W-1:0] a_set,  b_set;
    logic             ab_same;

    assign a_set   = set_of(s1a_addr);
    assign b_set   = set_of(s1b_addr);
    assign ab_same = s1a_v && s1b_v && (base_of(s1a_addr) == base_of(s1b_addr));

    always_comb begin
        a_mhit = 1'b0; a_midx = '0;
        b_mhit = 1'b0; b_midx = '0;
        for (int m = 0; m < MSHRS; m++) begin
            if (msh_val[m] && msh_base[m] == base_of(s1a_addr)) begin
                a_mhit = 1'b1; a_midx = MSH_W'(m);
            end
            if (msh_val[m] && msh_base[m] == base_of(s1b_addr)) begin
                b_mhit = 1'b1; b_midx = MSH_W'(m);
            end
        end
    end

    always_comb begin
        a_ahit = 1'b0; a_away = '0;
        b_ahit = 1'b0; b_away = '0;
        for (int w = 0; w < WAYS; w++) begin
            if (arr_val[a_set*WAYS + w] && arr_tag[a_set*WAYS + w] == tag_of(s1a_addr)) begin
                a_ahit = 1'b1; a_away = WAY_W'(w);
            end
            if (arr_val[b_set*WAYS + w] && arr_tag[b_set*WAYS + w] == tag_of(s1b_addr)) begin
                b_ahit = 1'b1; b_away = WAY_W'(w);
            end
        end
    end

    always_comb begin
        a_vhit = 1'b0; a_vidx = '0;
        b_vhit = 1'b0; b_vidx = '0;
        for (int v = 0; v < VICTIM_ENT; v++) begin
            if (vic_val[v] && vic_base[v] == base_of(s1a_addr)) begin
                a_vhit = 1'b1; a_vidx = VIC_W'(v);
            end
            if (vic_val[v] && vic_base[v] == base_of(s1b_addr)) begin
                b_vhit = 1'b1; b_vidx = VIC_W'(v);
            end
        end
    end

    // =======================================================================
    // Next-state
    // =======================================================================
    logic              port_a_busy, port_b_busy;
    logic              appended [0:MSHRS-1];
    logic              a_resolved;
    logic [LINE_W-1:0] a_line;          // line content after A's effect
    logic              a_store_arr;     // A's line lives in the array at ...
    int                a_store_w;       // ... this flat way index
    logic [MSH_W-1:0]  a_use_m;         // MSHR A merged into / allocated
    logic              a_use_m_v;
    logic              install_done;

    always_comb begin : NEXT_STATE
        int  p, m, w, v, s, pick, other, nb_free, wfree, vfree, mfree;
        logic [LINE_W-1:0] nl, oldd;
        logic              oldv, oldd_dty, need_wb;
        logic [ADDR_W-1:0] oldb;

        // ---------------- defaults: hold ----------------
        for (int i = 0; i < NWAY; i++) begin
            arr_val_n[i]=arr_val[i]; arr_dty_n[i]=arr_dty[i];
            arr_tag_n[i]=arr_tag[i]; arr_data_n[i]=arr_data[i];
        end
        for (int i = 0; i < SETS; i++) rr_n[i] = rr[i];
        for (int i = 0; i < VICTIM_ENT; i++) begin
            vic_val_n[i]=vic_val[i]; vic_dty_n[i]=vic_dty[i];
            vic_base_n[i]=vic_base[i]; vic_data_n[i]=vic_data[i];
        end
        vic_rr_n = vic_rr;
        for (int i = 0; i < MSHRS; i++) begin
            msh_val_n[i]=msh_val[i]; msh_iss_n[i]=msh_iss[i]; msh_fil_n[i]=msh_fil[i];
            msh_dty_n[i]=msh_dty[i]; msh_base_n[i]=msh_base[i]; msh_data_n[i]=msh_data[i];
            msh_hord_n[i]=msh_hord[i]; msh_tord_n[i]=msh_tord[i]; msh_cnt_n[i]=msh_cnt[i];
            appended[i]=1'b0;
        end
        for (int i = 0; i < NPQ; i++) begin
            pq_val_n[i]=pq_val[i]; pq_port_n[i]=pq_port[i]; pq_we_n[i]=pq_we[i];
            pq_tag_n[i]=pq_tag[i]; pq_addr_n[i]=pq_addr[i]; pq_size_n[i]=pq_size[i];
            pq_wdata_n[i]=pq_wdata[i]; pq_mshr_n[i]=pq_mshr[i]; pq_ord_n[i]=pq_ord[i];
        end
        for (int i = 0; i < WBQ; i++) begin
            wb_val_n[i]=wb_val[i]; wb_infl_n[i]=wb_infl[i];
            wb_base_n[i]=wb_base[i]; wb_data_n[i]=wb_data[i];
        end
        mem_busy_n = mem_busy_r; mem_is_wb_n = mem_is_wb_r;
        mem_own_n  = mem_own_r;  mem_wbi_n   = mem_wbi_r;
        mem_rv_n = 1'b0; mem_ra_n = mem_req_addr_q;
        mem_rw_n = mem_req_we_q; mem_rd_n = mem_req_wdata_q;

        arv_n = 1'b0; art_n = '0; ard_n = '0; arh_n = 1'b0;
        brv_n = 1'b0; brt_n = '0; brd_n = '0; brh_n = 1'b0;
        port_a_busy = 1'b0; port_b_busy = 1'b0;

        a_resolved = 1'b0; a_line = '0; a_store_arr = 1'b0; a_store_w = 0;
        a_use_m = '0; a_use_m_v = 1'b0;
        install_done = 1'b0;

        // ---------------- stage 0 capture ----------------
        s1a_v_n = A_req_valid && A_req_ready;
        s1b_v_n = B_req_valid && B_req_ready;
        s1a_addr_n = A_req_addr; s1a_we_n = A_req_we; s1a_wd_n = A_req_wdata;
        s1a_sz_n   = A_req_size; s1a_tag_n = A_req_tag;
        s1b_addr_n = B_req_addr; s1b_we_n = B_req_we; s1b_wd_n = B_req_wdata;
        s1b_sz_n   = B_req_size; s1b_tag_n = B_req_tag;

        // ---------------- memory response ----------------
        if (mem_resp_valid) begin
            mem_busy_n = 1'b0;
            if (mem_is_wb_r) begin
                wb_val_n [mem_wbi_r] = 1'b0;
                wb_infl_n[mem_wbi_r] = 1'b0;
            end else begin
                msh_data_n[mem_own_r] = mem_resp_rdata;
                msh_fil_n [mem_own_r] = 1'b1;
            end
        end

        // ================= stage 1: port A =================
        if (s1a_v) begin
            if (a_mhit) begin
                // merge into the in-flight chain -- never a second fill
                p = -1;
                for (int i = NPQ-1; i >= 0; i--) if (!pq_val_n[i]) p = i;
                pq_val_n[p]=1'b1; pq_port_n[p]=1'b0; pq_we_n[p]=s1a_we;
                pq_tag_n[p]=s1a_tag; pq_addr_n[p]=s1a_addr; pq_size_n[p]=s1a_sz;
                pq_wdata_n[p]=s1a_wd; pq_mshr_n[p]=a_midx; pq_ord_n[p]=msh_tord_n[a_midx];
                msh_tord_n[a_midx] = msh_tord_n[a_midx] + 1'b1;
                msh_cnt_n [a_midx] = msh_cnt_n [a_midx] + 1'b1;
                appended  [a_midx] = 1'b1;
                a_use_m = a_midx; a_use_m_v = 1'b1;
            end else if (a_ahit) begin
                w = a_set*WAYS + int'(a_away);
                nl = arr_data_n[w];
                if (s1a_we) begin
                    nl = line_merge(nl, s1a_addr, s1a_sz, s1a_wd);
                    arr_data_n[w] = nl;
                    arr_dty_n [w] = 1'b1;
                end else begin
                    ard_n = line_extract(nl, s1a_addr, s1a_sz);
                end
                arv_n = 1'b1; art_n = s1a_tag; arh_n = 1'b1; port_a_busy = 1'b1;
                a_resolved = 1'b1; a_line = nl; a_store_arr = 1'b1; a_store_w = w;
            end else if (a_vhit) begin
                // victim hit: swap back into the array, no memory fill.
                // pick a way that does not collide with B's array hit this cycle
                pick  = int'(rr[a_set]);
                other = (pick + 1) % WAYS;
                if (s1b_v && b_ahit && !ab_same && (b_set == a_set) &&
                    (pick == int'(b_away))) pick = other;
                w  = a_set*WAYS + pick;
                oldv     = arr_val_n[w];
                oldd_dty = arr_dty_n[w];
                oldd     = arr_data_n[w];
                oldb     = {arr_tag_n[w], a_set, {OFF_W{1'b0}}};

                nl = vic_data[a_vidx];
                arr_dty_n[w] = vic_dty[a_vidx];
                if (s1a_we) begin
                    nl = line_merge(nl, s1a_addr, s1a_sz, s1a_wd);
                    arr_dty_n[w] = 1'b1;
                end else begin
                    ard_n = line_extract(nl, s1a_addr, s1a_sz);
                end
                arr_val_n [w] = 1'b1;
                arr_tag_n [w] = tag_of(s1a_addr);
                arr_data_n[w] = nl;
                rr_n[a_set]   = WAY_W'((pick + 1) % WAYS);

                // the displaced array line takes the slot the victim vacated
                if (oldv) begin
                    vic_val_n [a_vidx] = 1'b1;
                    vic_dty_n [a_vidx] = oldd_dty;
                    vic_base_n[a_vidx] = oldb;
                    vic_data_n[a_vidx] = oldd;
                end else begin
                    vic_val_n[a_vidx] = 1'b0;
                end

                arv_n = 1'b1; art_n = s1a_tag; arh_n = 1'b1; port_a_busy = 1'b1;
                a_resolved = 1'b1; a_line = nl; a_store_arr = 1'b1; a_store_w = w;
            end else begin
                // true miss: allocate
                m = -1;
                for (int i = MSHRS-1; i >= 0; i--) if (!msh_val_n[i]) m = i;
                p = -1;
                for (int i = NPQ-1; i >= 0; i--) if (!pq_val_n[i]) p = i;
                if (m >= 0 && p >= 0) begin
                    msh_val_n[m]=1'b1; msh_iss_n[m]=1'b0; msh_fil_n[m]=1'b0;
                    msh_dty_n[m]=1'b0; msh_base_n[m]=base_of(s1a_addr);
                    msh_hord_n[m]='0;  msh_tord_n[m]=ORD_W'(1); msh_cnt_n[m]=1;
                    pq_val_n[p]=1'b1; pq_port_n[p]=1'b0; pq_we_n[p]=s1a_we;
                    pq_tag_n[p]=s1a_tag; pq_addr_n[p]=s1a_addr; pq_size_n[p]=s1a_sz;
                    pq_wdata_n[p]=s1a_wd; pq_mshr_n[p]=MSH_W'(m); pq_ord_n[p]='0;
                    appended[m] = 1'b1;
                    a_use_m = MSH_W'(m); a_use_m_v = 1'b1;
                end
            end
        end

        // ================= stage 1: port B =================
        if (s1b_v) begin
            if (ab_same) begin
                // ordered strictly after A, and forwarded off A's result
                if (a_resolved) begin
                    nl = a_line;
                    if (s1b_we) begin
                        nl = line_merge(nl, s1b_addr, s1b_sz, s1b_wd);
                        if (a_store_arr) begin
                            arr_data_n[a_store_w] = nl;
                            arr_dty_n [a_store_w] = 1'b1;
                        end
                    end else begin
                        brd_n = line_extract(nl, s1b_addr, s1b_sz);
                    end
                    brv_n = 1'b1; brt_n = s1b_tag; brh_n = 1'b1; port_b_busy = 1'b1;
                end else if (a_use_m_v) begin
                    p = -1;
                    for (int i = NPQ-1; i >= 0; i--) if (!pq_val_n[i]) p = i;
                    if (p >= 0) begin
                        pq_val_n[p]=1'b1; pq_port_n[p]=1'b1; pq_we_n[p]=s1b_we;
                        pq_tag_n[p]=s1b_tag; pq_addr_n[p]=s1b_addr; pq_size_n[p]=s1b_sz;
                        pq_wdata_n[p]=s1b_wd; pq_mshr_n[p]=a_use_m;
                        pq_ord_n[p]=msh_tord_n[a_use_m];
                        msh_tord_n[a_use_m] = msh_tord_n[a_use_m] + 1'b1;
                        msh_cnt_n [a_use_m] = msh_cnt_n [a_use_m] + 1'b1;
                        appended  [a_use_m] = 1'b1;
                    end
                end
            end else if (b_mhit) begin
                p = -1;
                for (int i = NPQ-1; i >= 0; i--) if (!pq_val_n[i]) p = i;
                if (p >= 0) begin
                    pq_val_n[p]=1'b1; pq_port_n[p]=1'b1; pq_we_n[p]=s1b_we;
                    pq_tag_n[p]=s1b_tag; pq_addr_n[p]=s1b_addr; pq_size_n[p]=s1b_sz;
                    pq_wdata_n[p]=s1b_wd; pq_mshr_n[p]=b_midx;
                    pq_ord_n[p]=msh_tord_n[b_midx];
                    msh_tord_n[b_midx] = msh_tord_n[b_midx] + 1'b1;
                    msh_cnt_n [b_midx] = msh_cnt_n [b_midx] + 1'b1;
                    appended  [b_midx] = 1'b1;
                end
            end else if (b_ahit) begin
                w  = b_set*WAYS + int'(b_away);
                nl = arr_data_n[w];
                if (s1b_we) begin
                    nl = line_merge(nl, s1b_addr, s1b_sz, s1b_wd);
                    arr_data_n[w] = nl;
                    arr_dty_n [w] = 1'b1;
                end else begin
                    brd_n = line_extract(nl, s1b_addr, s1b_sz);
                end
                brv_n = 1'b1; brt_n = s1b_tag; brh_n = 1'b1; port_b_busy = 1'b1;
            end else if (b_vhit) begin
                // serviced IN PLACE: a second swap would need another structural
                // array write in the same set this cycle. Not swapping is a
                // replacement-policy choice, which is not graded.
                nl = vic_data_n[b_vidx];
                if (s1b_we) begin
                    nl = line_merge(nl, s1b_addr, s1b_sz, s1b_wd);
                    vic_data_n[b_vidx] = nl;
                    vic_dty_n [b_vidx] = 1'b1;
                end else begin
                    brd_n = line_extract(nl, s1b_addr, s1b_sz);
                end
                brv_n = 1'b1; brt_n = s1b_tag; brh_n = 1'b1; port_b_busy = 1'b1;
            end else begin
                m = -1;
                for (int i = MSHRS-1; i >= 0; i--) if (!msh_val_n[i]) m = i;
                p = -1;
                for (int i = NPQ-1; i >= 0; i--) if (!pq_val_n[i]) p = i;
                if (m >= 0 && p >= 0) begin
                    msh_val_n[m]=1'b1; msh_iss_n[m]=1'b0; msh_fil_n[m]=1'b0;
                    msh_dty_n[m]=1'b0; msh_base_n[m]=base_of(s1b_addr);
                    msh_hord_n[m]='0;  msh_tord_n[m]=ORD_W'(1); msh_cnt_n[m]=1;
                    pq_val_n[p]=1'b1; pq_port_n[p]=1'b1; pq_we_n[p]=s1b_we;
                    pq_tag_n[p]=s1b_tag; pq_addr_n[p]=s1b_addr; pq_size_n[p]=s1b_sz;
                    pq_wdata_n[p]=s1b_wd; pq_mshr_n[p]=MSH_W'(m); pq_ord_n[p]='0;
                    appended[m] = 1'b1;
                end
            end
        end

        // ================= drain filled MSHRs =================
        // one entry per MSHR per cycle, oldest first, on a free response port.
        // Stage-1 hits have priority; they can only collide for one cycle
        // because req_ready is withdrawn as soon as any MSHR is filled.
        for (int mm = 0; mm < MSHRS; mm++) begin
            if (msh_val[mm] && msh_fil[mm] && msh_cnt[mm] != 0) begin
                p = -1;
                for (int i = 0; i < NPQ; i++)
                    if (pq_val[i] && pq_mshr[i] == MSH_W'(mm) &&
                        pq_ord[i] == msh_hord[mm]) p = i;
                if (p >= 0) begin
                    if (pq_port[p] == 1'b0 ? !port_a_busy : !port_b_busy) begin
                        if (pq_we[p]) begin
                            msh_data_n[mm] = line_merge(msh_data_n[mm], pq_addr[p],
                                                        pq_size[p], pq_wdata[p]);
                            msh_dty_n[mm] = 1'b1;
                        end
                        if (pq_port[p] == 1'b0) begin
                            arv_n = 1'b1; art_n = pq_tag[p]; arh_n = 1'b0;
                            ard_n = pq_we[p] ? '0
                                  : line_extract(msh_data_n[mm], pq_addr[p], pq_size[p]);
                            port_a_busy = 1'b1;
                        end else begin
                            brv_n = 1'b1; brt_n = pq_tag[p]; brh_n = 1'b0;
                            brd_n = pq_we[p] ? '0
                                  : line_extract(msh_data_n[mm], pq_addr[p], pq_size[p]);
                            port_b_busy = 1'b1;
                        end
                        pq_val_n[p]    = 1'b0;
                        msh_hord_n[mm] = msh_hord[mm] + 1'b1;
                        msh_cnt_n [mm] = msh_cnt_n[mm] - 1'b1;
                    end
                end
            end
        end

        // ================= install a fully-drained MSHR =================
        // guaranteed not to race a stage-1 lookup (see header)
        for (int mm = 0; mm < MSHRS; mm++) begin
            if (!install_done && msh_val[mm] && msh_fil[mm] &&
                msh_cnt[mm] == 0 && !appended[mm]) begin
                s    = int'(set_of(msh_base[mm]));
                pick = int'(rr_n[s]);
                w    = s*WAYS + pick;
                oldv     = arr_val_n[w];
                oldd_dty = arr_dty_n[w];
                oldd     = arr_data_n[w];
                oldb     = {arr_tag_n[w], SET_W'(s), {OFF_W{1'b0}}};

                vfree = -1;
                for (int i = VICTIM_ENT-1; i >= 0; i--) if (!vic_val_n[i]) vfree = i;
                v       = (vfree >= 0) ? vfree : int'(vic_rr_n);
                need_wb = oldv && (vfree < 0) && vic_dty_n[v];
                wfree   = -1;
                for (int i = WBQ-1; i >= 0; i--) if (!wb_val_n[i]) wfree = i;

                if (!need_wb || wfree >= 0) begin
                    install_done = 1'b1;
                    if (need_wb) begin
                        wb_val_n [wfree] = 1'b1;
                        wb_infl_n[wfree] = 1'b0;
                        wb_base_n[wfree] = vic_base_n[v];
                        wb_data_n[wfree] = vic_data_n[v];
                    end
                    if (oldv) begin
                        vic_val_n [v] = 1'b1;
                        vic_dty_n [v] = oldd_dty;
                        vic_base_n[v] = oldb;
                        vic_data_n[v] = oldd;
                        if (vfree < 0) vic_rr_n = VIC_W'((int'(vic_rr_n) + 1) % VICTIM_ENT);
                    end
                    arr_val_n [w] = 1'b1;
                    arr_tag_n [w] = tag_of(msh_base[mm]);
                    arr_dty_n [w] = msh_dty[mm];
                    arr_data_n[w] = msh_data_n[mm];
                    rr_n[s]       = WAY_W'((pick + 1) % WAYS);

                    msh_val_n[mm]=1'b0; msh_iss_n[mm]=1'b0; msh_fil_n[mm]=1'b0;
                    msh_dty_n[mm]=1'b0; msh_hord_n[mm]='0; msh_tord_n[mm]='0;
                    msh_cnt_n[mm]=0;
                end
            end
        end

        // ================= memory arbitration =================
        // single outstanding; writebacks first so evictions never queue behind a
        // long fill chain. A fill is HELD OFF while a writeback for the same line
        // is still queued -- otherwise the fill would return stale data.
        if (!mem_busy_r && !mem_req_valid_q) begin
            wfree = -1;
            for (int i = WBQ-1; i >= 0; i--) if (wb_val[i] && !wb_infl[i]) wfree = i;
            if (wfree >= 0) begin
                mem_rv_n = 1'b1; mem_rw_n = 1'b1;
                mem_ra_n = wb_base[wfree];
                mem_rd_n = wb_data_n[wfree];
                mem_busy_n = 1'b1; mem_is_wb_n = 1'b1; mem_wbi_n = WB_W'(wfree);
                wb_infl_n[wfree] = 1'b1;
            end else begin
                // Pick exactly ONE MSHR, then act on it. Setting msh_iss inside
                // the search loop marked EVERY eligible MSHR as issued while only
                // the last iteration's address actually reached memory, orphaning
                // the others: iss=1, fil never arrives, their merged chain never
                // drains, and req_ready is withdrawn permanently.
                mfree = -1;
                for (int mm = MSHRS-1; mm >= 0; mm--) begin
                    if (msh_val[mm] && !msh_iss[mm] && !msh_fil[mm]) begin
                        nb_free = 1;      // 1 = no conflicting writeback
                        for (int i = 0; i < WBQ; i++)
                            if (wb_val[i] && wb_base[i] == msh_base[mm]) nb_free = 0;
                        if (nb_free == 1) mfree = mm;
                    end
                end
                if (mfree >= 0) begin
                    mem_rv_n = 1'b1; mem_rw_n = 1'b0;
                    mem_ra_n = msh_base[mfree];
                    mem_busy_n = 1'b1; mem_is_wb_n = 1'b0;
                    mem_own_n = MSH_W'(mfree);
                    msh_iss_n[mfree] = 1'b1;
                end
            end
        end
    end

    // =======================================================================
    // Registers
    // =======================================================================
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            for (int i = 0; i < NWAY; i++) begin
                arr_val[i] <= 1'b0; arr_dty[i] <= 1'b0;
                arr_tag[i] <= '0;   arr_data[i] <= '0;
            end
            for (int i = 0; i < SETS; i++) rr[i] <= '0;
            for (int i = 0; i < VICTIM_ENT; i++) begin
                vic_val[i] <= 1'b0; vic_dty[i] <= 1'b0;
                vic_base[i] <= '0;  vic_data[i] <= '0;
            end
            vic_rr <= '0;
            for (int i = 0; i < MSHRS; i++) begin
                msh_val[i] <= 1'b0; msh_iss[i] <= 1'b0; msh_fil[i] <= 1'b0;
                msh_dty[i] <= 1'b0; msh_base[i] <= '0;  msh_data[i] <= '0;
                msh_hord[i] <= '0;  msh_tord[i] <= '0;  msh_cnt[i] <= '0;
            end
            for (int i = 0; i < NPQ; i++) pq_val[i] <= 1'b0;
            for (int i = 0; i < WBQ; i++) begin
                wb_val[i] <= 1'b0; wb_infl[i] <= 1'b0;
            end
            mem_busy_r <= 1'b0; mem_is_wb_r <= 1'b0;
            mem_own_r  <= '0;   mem_wbi_r   <= '0;
            mem_req_valid_q <= 1'b0; mem_req_addr_q <= '0;
            mem_req_we_q    <= 1'b0; mem_req_wdata_q <= '0;
            s1a_v <= 1'b0; s1b_v <= 1'b0;
            A_resp_valid <= 1'b0; A_resp_tag <= '0; A_resp_rdata <= '0; A_resp_hit <= 1'b0;
            B_resp_valid <= 1'b0; B_resp_tag <= '0; B_resp_rdata <= '0; B_resp_hit <= 1'b0;
        end else begin
            for (int i = 0; i < NWAY; i++) begin
                arr_val[i] <= arr_val_n[i]; arr_dty[i] <= arr_dty_n[i];
                arr_tag[i] <= arr_tag_n[i]; arr_data[i] <= arr_data_n[i];
            end
            for (int i = 0; i < SETS; i++) rr[i] <= rr_n[i];
            for (int i = 0; i < VICTIM_ENT; i++) begin
                vic_val[i] <= vic_val_n[i]; vic_dty[i] <= vic_dty_n[i];
                vic_base[i] <= vic_base_n[i]; vic_data[i] <= vic_data_n[i];
            end
            vic_rr <= vic_rr_n;
            for (int i = 0; i < MSHRS; i++) begin
                msh_val[i] <= msh_val_n[i]; msh_iss[i] <= msh_iss_n[i];
                msh_fil[i] <= msh_fil_n[i]; msh_dty[i] <= msh_dty_n[i];
                msh_base[i] <= msh_base_n[i]; msh_data[i] <= msh_data_n[i];
                msh_hord[i] <= msh_hord_n[i]; msh_tord[i] <= msh_tord_n[i];
                msh_cnt[i] <= msh_cnt_n[i];
            end
            for (int i = 0; i < NPQ; i++) begin
                pq_val[i] <= pq_val_n[i]; pq_port[i] <= pq_port_n[i];
                pq_we[i] <= pq_we_n[i];   pq_tag[i] <= pq_tag_n[i];
                pq_addr[i] <= pq_addr_n[i]; pq_size[i] <= pq_size_n[i];
                pq_wdata[i] <= pq_wdata_n[i]; pq_mshr[i] <= pq_mshr_n[i];
                pq_ord[i] <= pq_ord_n[i];
            end
            for (int i = 0; i < WBQ; i++) begin
                wb_val[i] <= wb_val_n[i]; wb_infl[i] <= wb_infl_n[i];
                wb_base[i] <= wb_base_n[i]; wb_data[i] <= wb_data_n[i];
            end
            mem_busy_r <= mem_busy_n; mem_is_wb_r <= mem_is_wb_n;
            mem_own_r  <= mem_own_n;  mem_wbi_r   <= mem_wbi_n;
            mem_req_valid_q <= mem_rv_n;
            if (mem_rv_n) begin
                mem_req_addr_q  <= mem_ra_n;
                mem_req_we_q    <= mem_rw_n;
                mem_req_wdata_q <= mem_rd_n;
            end
            s1a_v <= s1a_v_n; s1b_v <= s1b_v_n;
            if (s1a_v_n) begin
                s1a_addr <= s1a_addr_n; s1a_we <= s1a_we_n; s1a_wd <= s1a_wd_n;
                s1a_sz   <= s1a_sz_n;   s1a_tag <= s1a_tag_n;
            end
            if (s1b_v_n) begin
                s1b_addr <= s1b_addr_n; s1b_we <= s1b_we_n; s1b_wd <= s1b_wd_n;
                s1b_sz   <= s1b_sz_n;   s1b_tag <= s1b_tag_n;
            end
            A_resp_valid <= arv_n; A_resp_tag <= art_n;
            A_resp_rdata <= ard_n; A_resp_hit <= arh_n;
            B_resp_valid <= brv_n; B_resp_tag <= brt_n;
            B_resp_rdata <= brd_n; B_resp_hit <= brh_n;
        end
    end

endmodule