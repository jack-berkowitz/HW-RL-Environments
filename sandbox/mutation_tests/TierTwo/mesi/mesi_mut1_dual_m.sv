// =============================================================================
// mesi_top.sv -- MUTANT 1: peer not invalidated on RdX/Upgr (throwaway) (harness validation only, NOT a candidate)
// =============================================================================
// Implements interfaces/TierTwo/mesi_iface.sv. Never a candidate.
//
// Both caches, the arbiter and the bus live in one module and one FSM. That is
// deliberate: the protocol is a sequence of globally-ordered steps (snoop, flush,
// evict, fetch, install) and expressing it as one explicit sequence is far
// easier to argue correct than two independently-snooping state machines racing
// on a shared wire. The spec only constrains observable behaviour plus
// debug_state, so this is a legitimate implementation of it.
//
// The transaction sequence, in order, is:
//     SNOOP -> FLUSHWB -> EVICT -> FETCH -> INSTALL
// Every step that touches memory waits for its own response, because memory is
// single-outstanding and shared with everything else.
// =============================================================================

module mesi_top #(
    parameter int ADDR_W     = 10,
    parameter int DATA_W     = 32,
    parameter int LINE_BYTES = 16,
    parameter int SETS       = 4,
    parameter int WAYS       = 2,
    // derived -- do not override
    parameter int LINE_W     = 8*LINE_BYTES,
    parameter int LTAG_W     = ADDR_W - $clog2(LINE_BYTES) - $clog2(SETS),
    parameter int ENT_W      = LTAG_W + 2,
    parameter int NSTATE     = 2*SETS*WAYS
) (
    input  logic                clk,
    input  logic                rst_n,

    input  logic                c0_req_valid,
    input  logic [ADDR_W-1:0]   c0_req_addr,
    input  logic                c0_req_we,
    input  logic [DATA_W-1:0]   c0_req_wdata,
    output logic                c0_resp_valid,
    output logic [DATA_W-1:0]   c0_resp_rdata,

    input  logic                c1_req_valid,
    input  logic [ADDR_W-1:0]   c1_req_addr,
    input  logic                c1_req_we,
    input  logic [DATA_W-1:0]   c1_req_wdata,
    output logic                c1_resp_valid,
    output logic [DATA_W-1:0]   c1_resp_rdata,

    output logic                bus_req_valid,
    output logic [1:0]          bus_req_type,
    output logic [ADDR_W-1:0]   bus_req_addr,
    output logic                bus_req_core_id,
    output logic                bus_grant,
    output logic                bus_snoop_hit,
    output logic                bus_snoop_hitm,
    output logic [LINE_W-1:0]   bus_data,
    output logic                bus_data_valid,

    output logic                mem_req_valid,
    output logic [ADDR_W-1:0]   mem_req_addr,
    output logic                mem_req_we,
    output logic [LINE_W-1:0]   mem_req_wdata,
    input  logic                mem_resp_valid,
    input  logic [LINE_W-1:0]   mem_resp_rdata,

    output logic [NSTATE*ENT_W-1:0] debug_state
);

    localparam int OFF_W  = $clog2(LINE_BYTES);
    localparam int SET_W  = $clog2(SETS);
    localparam int NL     = SETS*WAYS;          // lines per core

    localparam logic [1:0] ST_I = 2'd0, ST_S = 2'd1, ST_E = 2'd2, ST_M = 2'd3;
    localparam logic [1:0] BUS_RD = 2'd0, BUS_RDX = 2'd1, BUS_UPGR = 2'd2;

    // ---------------------------------------------------------------------
    // per-core cache arrays, core index first
    // ---------------------------------------------------------------------
    logic [1:0]        st  [0:1][0:NL-1];
    logic [LTAG_W-1:0] tg  [0:1][0:NL-1];
    logic [LINE_W-1:0] dat [0:1][0:NL-1];

    // ---------------------------------------------------------------------
    // per-core CPU request latch
    // ---------------------------------------------------------------------
    logic              q_busy [0:1];
    logic [ADDR_W-1:0] q_addr [0:1];
    logic              q_we   [0:1];
    logic [DATA_W-1:0] q_wd   [0:1];
    logic              q_wait [0:1];   // waiting on a bus transaction

    // ---------------------------------------------------------------------
    // helpers
    // ---------------------------------------------------------------------
    function automatic logic [ADDR_W-1:0] base_of(input logic [ADDR_W-1:0] a);
        return a & ~ADDR_W'(LINE_BYTES-1);
    endfunction
    function automatic int set_of(input logic [ADDR_W-1:0] a);
        return int'(a[OFF_W +: SET_W]);
    endfunction
    function automatic logic [LTAG_W-1:0] tag_of(input logic [ADDR_W-1:0] a);
        return a[OFF_W+SET_W +: LTAG_W];
    endfunction

    function automatic int find_line(input int c, input logic [ADDR_W-1:0] a);
        int s;
        s = set_of(a);
        for (int w = 0; w < WAYS; w++)
            if (st[c][s*WAYS+w] != ST_I && tg[c][s*WAYS+w] == tag_of(a))
                return s*WAYS+w;
        return -1;
    endfunction

    function automatic logic [DATA_W-1:0] ln_get(input logic [LINE_W-1:0] ln,
                                                 input logic [ADDR_W-1:0] a);
        logic [DATA_W-1:0] v;
        int off;
        off = int'(a[OFF_W-1:0]);
        v = '0;
        for (int i = 0; i < 4; i++) v[8*i +: 8] = ln[8*(off+i) +: 8];
        return v;
    endfunction

    function automatic logic [LINE_W-1:0] ln_put(input logic [LINE_W-1:0] ln,
                                                 input logic [ADDR_W-1:0] a,
                                                 input logic [DATA_W-1:0] d);
        logic [LINE_W-1:0] r;
        int off;
        r = ln;
        off = int'(a[OFF_W-1:0]);
        for (int i = 0; i < 4; i++) r[8*(off+i) +: 8] = d[8*i +: 8];
        return r;
    endfunction

    // debug hook: flattened {core, set, way} -> {tag, state}
    always_comb begin
        for (int c = 0; c < 2; c++)
            for (int l = 0; l < NL; l++)
                debug_state[(c*NL + l)*ENT_W +: ENT_W] = {tg[c][l], st[c][l]};
    end

    // ---------------------------------------------------------------------
    // bus transaction FSM
    // ---------------------------------------------------------------------
    localparam logic [2:0] B_IDLE=3'd0, B_SNOOP=3'd1, B_FLUSHWB=3'd2,
                           B_EVICT=3'd3, B_FETCH=3'd4, B_INSTALL=3'd5;

    logic [2:0]        bst;
    logic              rr;              // round-robin arbiter pointer
    logic              req_core;
    logic [1:0]        req_type;
    logic [ADDR_W-1:0] req_addr;
    logic [LINE_W-1:0] line_buf;
    logic              have_data;
    logic              need_flushwb;
    logic              need_evict;
    logic [31:0]       victim_way;
    logic [ADDR_W-1:0] victim_addr;
    logic [LINE_W-1:0] victim_data;
    logic              mem_pending;
    logic              mem_pulse;    // req_valid is a ONE-CYCLE pulse: holding it
                                     // high for the whole transaction makes the
                                     // memory re-accept the same request the
                                     // cycle its response lands

    // what a core wants from the bus, if anything
    function automatic logic wants_bus(input int c);
        int l;
        if (!q_busy[c] || !q_wait[c]) return 1'b0;
        l = find_line(c, q_addr[c]);
        if (!q_we[c]) return (l < 0);                       // read miss
        if (l < 0)    return 1'b1;                          // write miss
        return (st[c][l] == ST_S);                          // write hit in S
    endfunction

    function automatic logic [1:0] want_type(input int c);
        int l;
        l = find_line(c, q_addr[c]);
        if (!q_we[c]) return BUS_RD;
        if (l < 0)    return BUS_RDX;
        return BUS_UPGR;
    endfunction

    assign bus_req_valid   = (bst != B_IDLE);
    assign bus_req_type    = req_type;
    assign bus_req_addr    = req_addr;
    assign bus_req_core_id = req_core;

    assign mem_req_valid = mem_pulse;

    // ---------------------------------------------------------------------
    // sequential -- one procedure per edge, all blocking (reference model)
    // ---------------------------------------------------------------------
    task automatic serve_local(input int c);
        int l;
        l = find_line(c, q_addr[c]);
        if (q_we[c]) begin
            dat[c][l] = ln_put(dat[c][l], q_addr[c], q_wd[c]);
            st [c][l] = ST_M;                      // E->M silent, M stays M
            if (c == 0) c0_resp_rdata = '0; else c1_resp_rdata = '0;
        end else begin
            if (c == 0) c0_resp_rdata = ln_get(dat[c][l], q_addr[c]);
            else        c1_resp_rdata = ln_get(dat[c][l], q_addr[c]);
        end
        if (c == 0) c0_resp_valid = 1'b1; else c1_resp_valid = 1'b1;
        q_busy[c] = 1'b0;
        q_wait[c] = 1'b0;
    endtask

    // can core c complete without the bus?
    function automatic logic can_serve_local(input int c);
        int l;
        if (!q_busy[c]) return 1'b0;
        l = find_line(c, q_addr[c]);
        if (l < 0) return 1'b0;
        if (!q_we[c]) return 1'b1;                 // any valid state serves a read
        return (st[c][l] == ST_M || st[c][l] == ST_E);
    endfunction

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            for (int c = 0; c < 2; c++) begin
                for (int l = 0; l < NL; l++) st[c][l] = ST_I;
                q_busy[c] = 1'b0;
                q_wait[c] = 1'b0;
            end
            bst = B_IDLE; rr = 1'b0; mem_pending = 1'b0; mem_pulse = 1'b0;
            have_data = 1'b0; need_flushwb = 1'b0; need_evict = 1'b0;
            c0_resp_valid = 1'b0; c1_resp_valid = 1'b0;
            bus_grant = 1'b0; bus_snoop_hit = 1'b0; bus_snoop_hitm = 1'b0;
            bus_data_valid = 1'b0; mem_req_we = 1'b0; mem_req_addr = '0;
            mem_req_wdata = '0; bus_data = '0;
            req_core = 1'b0; req_type = BUS_RD; req_addr = '0;
        end else begin
            c0_resp_valid  = 1'b0;
            c1_resp_valid  = 1'b0;
            bus_grant      = 1'b0;
            bus_data_valid = 1'b0;

            // ---- latch new CPU requests ----
            if (!q_busy[0] && c0_req_valid) begin
                q_busy[0] = 1'b1; q_addr[0] = c0_req_addr;
                q_we[0]   = c0_req_we; q_wd[0] = c0_req_wdata; q_wait[0] = 1'b1;
            end
            if (!q_busy[1] && c1_req_valid) begin
                q_busy[1] = 1'b1; q_addr[1] = c1_req_addr;
                q_we[1]   = c1_req_we; q_wd[1] = c1_req_wdata; q_wait[1] = 1'b1;
            end

            // ---- anything servable without the bus completes immediately ----
            for (int c = 0; c < 2; c++)
                if (q_busy[c] && q_wait[c] && can_serve_local(c)) serve_local(c);

            // ---- bus FSM ----
            case (bst)
                B_IDLE: begin
                    logic w0, w1;
                    int    pick;
                    w0 = wants_bus(0);
                    w1 = wants_bus(1);
                    pick = -1;
                    if (w0 && w1)      pick = rr ? 1 : 0;     // round robin
                    else if (w0)       pick = 0;
                    else if (w1)       pick = 1;
                    if (pick >= 0) begin
                        req_core  = pick[0];
                        req_addr  = base_of(q_addr[pick]);
                        req_type  = want_type(pick);
                        rr        = ~pick[0];                 // other core next
                        bus_grant = 1'b1;
                        have_data = 1'b0;
                        bst       = B_SNOOP;
                    end
                end

                B_SNOOP: begin
                    int pc, pl, rl, s;
                    pc = req_core ? 0 : 1;                    // the peer
                    pl = find_line(pc, req_addr);
                    bus_snoop_hit  = 1'b0;
                    bus_snoop_hitm = 1'b0;
                    need_flushwb   = 1'b0;
                    need_evict     = 1'b0;

                    if (pl >= 0) begin
                        bus_snoop_hit = 1'b1;
                        if (st[pc][pl] == ST_M) begin
                            // flush: supply the line and write it back
                            bus_snoop_hitm = 1'b1;
                            bus_data       = dat[pc][pl];
                            bus_data_valid = 1'b1;
                            line_buf       = dat[pc][pl];
                            have_data      = 1'b1;
                            need_flushwb   = 1'b1;
                        end
                        // MUTANT 1: the peer is downgraded to S on EVERY
                        // transaction and never invalidated, so after a BusRdX
                        // both caches can end up believing they own the line.
                        st[pc][pl] = ST_S;
                    end

                    // the requester's own way: pick or evict
                    rl = find_line(int'(req_core), req_addr);
                    if (rl < 0) begin
                        s = set_of(req_addr);
                        victim_way = 32'hFFFF_FFFF;
                        for (int w = 0; w < WAYS; w++)
                            if (st[int'(req_core)][s*WAYS+w] == ST_I)
                                begin victim_way = (s*WAYS+w); break; end
                        if (victim_way == 32'hFFFF_FFFF) begin
                            victim_way = s*WAYS + (int'(req_addr) % WAYS);
                            if (st[int'(req_core)][victim_way] == ST_M) begin
                                need_evict  = 1'b1;
                                victim_addr = {tg[int'(req_core)][victim_way],
                                               SET_W'(s), OFF_W'(0)};
                                victim_data = dat[int'(req_core)][victim_way];
                            end
                        end
                    end else begin
                        victim_way = rl[31:0];                // BusUpgr: keep it
                    end

                    bst = need_flushwb ? B_FLUSHWB
                        : (need_evict  ? B_EVICT
                        : ((!have_data && req_type != BUS_UPGR) ? B_FETCH : B_INSTALL));
                end

                B_FLUSHWB: begin
                    mem_pulse = 1'b0;
                    if (!mem_pending) begin
                        mem_pending = 1'b1; mem_pulse = 1'b1; mem_req_we = 1'b1;
                        mem_req_addr = req_addr; mem_req_wdata = line_buf;
                    end else if (mem_resp_valid) begin
                        mem_pending  = 1'b0;
                        need_flushwb = 1'b0;
                        bst = need_evict ? B_EVICT : B_INSTALL;
                    end
                end

                B_EVICT: begin
                    mem_pulse = 1'b0;
                    if (!mem_pending) begin
                        mem_pending = 1'b1; mem_pulse = 1'b1; mem_req_we = 1'b1;
                        mem_req_addr = victim_addr; mem_req_wdata = victim_data;
                    end else if (mem_resp_valid) begin
                        mem_pending = 1'b0;
                        need_evict  = 1'b0;
                        st[int'(req_core)][victim_way] = ST_I;
                        bst = (!have_data && req_type != BUS_UPGR) ? B_FETCH : B_INSTALL;
                    end
                end

                B_FETCH: begin
                    mem_pulse = 1'b0;
                    if (!mem_pending) begin
                        mem_pending = 1'b1; mem_pulse = 1'b1; mem_req_we = 1'b0;
                        mem_req_addr = req_addr; mem_req_wdata = '0;
                    end else if (mem_resp_valid) begin
                        mem_pending = 1'b0;
                        line_buf    = mem_resp_rdata;
                        have_data   = 1'b1;
                        bst         = B_INSTALL;
                    end
                end

                B_INSTALL: begin
                    int c, l;
                    c = int'(req_core);
                    l = int'(victim_way);
                    if (req_type != BUS_UPGR) begin
                        dat[c][l] = line_buf;
                        tg [c][l] = tag_of(req_addr);
                    end
                    // BusRd with no sharer -> E, which is what allows the later
                    // silent E->M upgrade; with a sharer -> S
                    if (req_type == BUS_RD)
                        st[c][l] = bus_snoop_hit ? ST_S : ST_E;
                    else
                        st[c][l] = ST_M;
                    bus_snoop_hit  = 1'b0;
                    bus_snoop_hitm = 1'b0;
                    bst = B_IDLE;
                    // the requester can now finish locally
                    if (q_busy[c] && q_wait[c] && can_serve_local(c)) serve_local(c);
                end

                default: bst = B_IDLE;
            endcase
        end
    end

endmodule
