// =============================================================================
// ncache.sv -- MUTANT 3: crossed response tags under concurrency (throwaway) (harness validation only, NOT a candidate)
// =============================================================================
// Implements interfaces/TierTwo/ncache_iface.sv. Exists to prove the testbench
// passes something correct and fails deliberate mutants; never a candidate.
//
// The organising idea that makes the ordering rules fall out:
//
//   EVERY accepted request goes into one pending queue, hit or miss.
//     * a HIT captures its read data (or applies its write) AT ACCEPT, and is
//       immediately ready -- which is exactly the "value as of its own accept
//       edge" rule, for free
//     * a MISS is tied to an MSHR and becomes ready when the fill lands
//   Any request to a line with an outstanding MSHR MERGES rather than hitting,
//   so all accesses to one line stay in a single ordered chain.
//   An entry may only be serviced when it is the OLDEST unserviced entry for
//   its line, which keeps merged writes and reads in program order even though
//   the two ports are serviced independently.
//
// Memory is single-outstanding and shared by fills and writebacks, so there is a
// small writeback queue and a fixed arbitration (writebacks first, so evictions
// can never back up behind a long fill chain).
// =============================================================================
//
// SIZING NOTE (why these defaults are small)
//   The geometry below is chosen so the design still contains every hazard the
//   module exists to test -- MSHR merging, backpressure when none is free,
//   eviction, a dirty writeback, a victim hit, dual-port same-line conflict --
//   while staying small enough to synthesise and place-and-route in a sane time.
//   The earlier 16-byte / 8-set / 4-way / PQ-8 version unrolled the merged-drain
//   logic MSHRS x (PQ+1) = 36 times over a 128-bit line and pushed Yosys past
//   4 GB. Halving the line and cutting the queues gives ~7x less of that logic.
//   Note 2 MSHRs and 2 victim entries exercise the "none free" paths MORE often
//   than 4 did, so this is not a weaker test -- just a cheaper one.
// =============================================================================

module ncache #(
    parameter int ADDR_W     = 10,
    parameter int DATA_W     = 32,
    parameter int LINE_BYTES = 8,
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

    localparam int OFF_W  = $clog2(LINE_BYTES);
    localparam int SET_W  = $clog2(SETS);
    localparam int LTAG_W = ADDR_W - OFF_W - SET_W;
    localparam int NLINE  = SETS*WAYS;
    localparam int PQ     = 4;      // pending requests in flight
    localparam int WBQ    = 4;      // queued writebacks

    // ---------------------------------------------------------------------
    // state
    // ---------------------------------------------------------------------
    logic              arr_val  [NLINE];
    logic              arr_dty  [NLINE];
    logic [LTAG_W-1:0] arr_tag  [NLINE];
    logic [LINE_W-1:0] arr_data [NLINE];
    logic [31:0]       rr       [SETS];

    logic              vic_val  [VICTIM_ENT];
    logic              vic_dty  [VICTIM_ENT];
    logic [ADDR_W-1:0] vic_base [VICTIM_ENT];
    logic [LINE_W-1:0] vic_data [VICTIM_ENT];
    logic [31:0]       vic_rr;

    logic              msh_val    [MSHRS];
    logic              msh_issued [MSHRS];
    logic              msh_filled [MSHRS];
    logic [ADDR_W-1:0] msh_base   [MSHRS];
    logic [LINE_W-1:0] msh_data   [MSHRS];

    logic              pq_val   [PQ];
    logic              pq_port  [PQ];      // 0 = A, 1 = B
    logic [TAG_W-1:0]  pq_tag   [PQ];
    logic [ADDR_W-1:0] pq_addr  [PQ];
    logic              pq_we    [PQ];
    logic [1:0]        pq_size  [PQ];
    logic [DATA_W-1:0] pq_wdata [PQ];
    logic [DATA_W-1:0] pq_rdata [PQ];
    logic              pq_ready [PQ];      // data captured / fill landed
    logic              pq_hit   [PQ];
    logic [31:0]       pq_mshr  [PQ];      // MSHRS = none
    logic [31:0]       pq_seq   [PQ];

    logic              wb_val   [WBQ];
    logic [ADDR_W-1:0] wb_base  [WBQ];
    logic [LINE_W-1:0] wb_data  [WBQ];

    logic [31:0]       seq_ctr;
    logic              mem_busy;
    logic              mem_is_wb;
    logic [31:0]       mem_owner;          // MSHR index for a fill

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
    function automatic int nbytes(input logic [1:0] s);
        case (s) 2'b00: return 1; 2'b01: return 2; default: return 4; endcase
    endfunction

    function automatic logic [DATA_W-1:0] line_extract(input logic [LINE_W-1:0] ln,
                                                       input logic [ADDR_W-1:0] a,
                                                       input logic [1:0] s);
        logic [DATA_W-1:0] v;
        int off;
        v   = '0;
        off = int'(a[OFF_W-1:0]);
        for (int i = 0; i < 4; i++)
            if (i < nbytes(s)) v[8*i +: 8] = ln[8*(off+i) +: 8];
        return v;
    endfunction

    function automatic logic [LINE_W-1:0] line_merge(input logic [LINE_W-1:0] ln,
                                                     input logic [ADDR_W-1:0] a,
                                                     input logic [1:0] s,
                                                     input logic [DATA_W-1:0] d);
        logic [LINE_W-1:0] r;
        int off;
        r   = ln;
        off = int'(a[OFF_W-1:0]);
        for (int i = 0; i < 4; i++)
            if (i < nbytes(s)) r[8*(off+i) +: 8] = d[8*i +: 8];
        return r;
    endfunction

    // ---------------------------------------------------------------------
    // lookup (combinational, over registered state)
    // ---------------------------------------------------------------------
    function automatic int find_way(input logic [ADDR_W-1:0] a);
        int s;
        s = set_of(a);
        for (int w = 0; w < WAYS; w++)
            if (arr_val[s*WAYS+w] && arr_tag[s*WAYS+w] == tag_of(a)) return s*WAYS+w;
        return -1;
    endfunction
    function automatic int find_vic(input logic [ADDR_W-1:0] a);
        for (int v = 0; v < VICTIM_ENT; v++)
            if (vic_val[v] && vic_base[v] == base_of(a)) return v;
        return -1;
    endfunction
    function automatic int find_mshr(input logic [ADDR_W-1:0] a);
        for (int m = 0; m < MSHRS; m++)
            if (msh_val[m] && msh_base[m] == base_of(a)) return m;
        return -1;
    endfunction
    function automatic int free_mshr();
        for (int m = 0; m < MSHRS; m++) if (!msh_val[m]) return m;
        return -1;
    endfunction
    function automatic int free_pq();
        for (int p = 0; p < PQ; p++) if (!pq_val[p]) return p;
        return -1;
    endfunction
    function automatic int free_wb();
        for (int w = 0; w < WBQ; w++) if (!wb_val[w]) return w;
        return -1;
    endfunction

    // a port can accept when there is a PQ slot and either the access resolves
    // without a new MSHR, or an MSHR is free
    // Does this access need a NEW MSHR, or does it resolve without one?
    function automatic logic needs_new_mshr(input logic [ADDR_W-1:0] a);
        if (find_mshr(a) >= 0) return 1'b0;               // merges into one
        if (find_way(a)  >= 0) return 1'b0;               // array hit
        if (find_vic(a)  >= 0) return 1'b0;               // victim hit
        return 1'b1;
    endfunction

    function automatic logic can_accept(input logic [ADDR_W-1:0] a,
                                        input int pq_free_cnt,
                                        input int mshr_free_cnt);
        if (pq_free_cnt <= 0) return 1'b0;
        if (!needs_new_mshr(a)) return 1'b1;
        return (mshr_free_cnt > 0);
    endfunction

    int pq_free_n, mshr_free_n;
    always_comb begin
        pq_free_n = 0;
        for (int p = 0; p < PQ; p++) if (!pq_val[p]) pq_free_n++;
        mshr_free_n = 0;
        for (int m = 0; m < MSHRS; m++) if (!msh_val[m]) mshr_free_n++;
    end

    assign A_req_ready = rst_n && can_accept(A_req_addr, pq_free_n, mshr_free_n);

    // B is ordered after A this cycle, so it must budget for whatever A takes:
    // a PQ slot, AND an MSHR when A is a true miss. Budgeting only the PQ slot
    // was the bug -- with one MSHR free and both ports missing to DIFFERENT
    // lines, both ports were told ready, A took the last MSHR, and B was left
    // accepted-but-unallocatable: never answered, and its data never written.
    // (If both miss to the SAME line B will actually merge into the MSHR A is
    // about to allocate, so this is conservative there -- it may refuse a
    // request it could have taken, which is safe; the reverse never is.)
    assign B_req_ready = rst_n && can_accept(
        B_req_addr,
        pq_free_n   - ((A_req_valid && A_req_ready) ? 1 : 0),
        mshr_free_n - ((A_req_valid && A_req_ready && needs_new_mshr(A_req_addr)) ? 1 : 0));

    // ---------------------------------------------------------------------
    // service selection: oldest ready entry per port that is also the oldest
    // unserviced entry for its line
    // ---------------------------------------------------------------------
    function automatic logic is_oldest_for_line(input int p);
        for (int q = 0; q < PQ; q++)
            if (q != p && pq_val[q] && base_of(pq_addr[q]) == base_of(pq_addr[p])
                && pq_seq[q] < pq_seq[p]) return 1'b0;
        return 1'b1;
    endfunction

    function automatic int pick_service(input logic port);
        int best;
        best = -1;
        for (int p = 0; p < PQ; p++)
            if (pq_val[p] && pq_ready[p] && pq_port[p] == port && is_oldest_for_line(p))
                if (best < 0 || pq_seq[p] < pq_seq[best]) best = p;
        return best;
    endfunction

    int svc_a, svc_b;
    always_comb begin
        svc_a = pick_service(1'b0);
        svc_b = pick_service(1'b1);
    end

    // ---------------------------------------------------------------------
    // memory arbitration: drain writebacks first, then issue a fill
    // ---------------------------------------------------------------------
    int wb_pick, fill_pick;
    always_comb begin
        wb_pick = -1;
        for (int w = 0; w < WBQ; w++) if (wb_val[w]) begin wb_pick = w; break; end
        fill_pick = -1;
        for (int m = 0; m < MSHRS; m++)
            if (msh_val[m] && !msh_issued[m]) begin fill_pick = m; break; end
    end

    logic do_wb, do_fill;
    assign do_wb   = !mem_busy && (wb_pick >= 0);
    assign do_fill = !mem_busy && (wb_pick < 0) && (fill_pick >= 0);

    assign mem_req_valid = do_wb || do_fill;
    assign mem_req_we    = do_wb;
    assign mem_req_addr  = do_wb ? wb_base[wb_pick]  : (do_fill ? msh_base[fill_pick] : '0);
    assign mem_req_wdata = do_wb ? wb_data[wb_pick]  : '0;

    // ---------------------------------------------------------------------
    // sequential
    // ---------------------------------------------------------------------
    task automatic accept_req(input logic port, input logic [ADDR_W-1:0] a,
                              input logic we, input logic [DATA_W-1:0] wd,
                              input logic [1:0] sz, input logic [TAG_W-1:0] tg);
        int p, m, w, v;
        p = free_pq();
        if (p < 0) return;
        pq_val[p]   = 1'b1;
        pq_port[p]  = port;
        pq_tag[p]   = tg;
        pq_addr[p]  = a;
        pq_we[p]    = we;
        pq_size[p]  = sz;
        pq_wdata[p] = wd;
        pq_seq[p]   = seq_ctr;
        pq_rdata[p] = '0;
        seq_ctr     = seq_ctr + 1;

        m = find_mshr(a);
        if (m >= 0) begin                       // merge into an in-flight miss
            pq_mshr[p]  = m[31:0];
            pq_ready[p] = 1'b0;
            pq_hit[p]   = 1'b0;
            return;
        end
        w = find_way(a);
        if (w >= 0) begin                       // array hit: resolve now
            pq_mshr[p]  = MSHRS[31:0];
            pq_ready[p] = 1'b1;
            pq_hit[p]   = 1'b1;
            if (we) begin
                arr_data[w] = line_merge(arr_data[w], a, sz, wd);
                arr_dty[w]  = 1'b1;
            end else begin
                pq_rdata[p] = line_extract(arr_data[w], a, sz);
            end
            return;
        end
        v = find_vic(a);
        if (v >= 0) begin                       // victim hit: swap back, no fill
            int s, way;
            logic              ov, od;
            logic [ADDR_W-1:0] ob;
            logic [LINE_W-1:0] odata, newline;
            s   = set_of(a);
            way = s*WAYS + (rr[s] % WAYS);
            ov = arr_val[way]; od = arr_dty[way]; odata = arr_data[way];
            ob = {arr_tag[way], SET_W'(s), OFF_W'(0)};

            newline = vic_data[v];
            pq_mshr[p]  = MSHRS[31:0];
            pq_ready[p] = 1'b1;
            pq_hit[p]   = 1'b1;
            if (we) newline = line_merge(newline, a, sz, wd);
            else    pq_rdata[p] = line_extract(newline, a, sz);

            arr_val [way] = 1'b1;
            arr_tag [way] = tag_of(a);
            arr_dty [way] = vic_dty[v] || we;
            arr_data[way] = newline;
            rr[s]         = (rr[s] + 1) % WAYS;

            // the displaced line takes the slot the victim just vacated
            if (ov) begin
                vic_val[v] = 1'b1; vic_dty[v] = od; vic_base[v] = ob; vic_data[v] = odata;
            end else begin
                vic_val[v] = 1'b0;
            end
            return;
        end
        // true miss: allocate an MSHR. req_ready guarantees one is free, but
        // never index with -1 -- silently corrupting an entry is far worse than
        // refusing, and this is exactly the path that used to do it.
        m = free_mshr();
        if (m < 0) begin
            pq_val[p] = 1'b0;      // withdraw; must be unreachable
            return;
        end
        msh_val[m]    = 1'b1;
        msh_issued[m] = 1'b0;
        msh_filled[m] = 1'b0;
        msh_base[m]   = base_of(a);
        pq_mshr[p]    = m[31:0];
        pq_ready[p]   = 1'b0;
        pq_hit[p]     = 1'b0;
    endtask

    // -----------------------------------------------------------------
    // Install a filled line AND resolve every request merged into it, in
    // sequence order, right here. Doing it in one step is what makes the
    // ordering rules hold: merged writes are applied to the line in order, each
    // merged read captures the line as it stood at its own position, and by the
    // time any later request can hit this line the whole chain is already
    // applied. It also means an entry never has to go looking for its line
    // afterwards -- which would be a bug if a later fill had evicted it.
    // -----------------------------------------------------------------
    task automatic install_and_drain(input int m);
        int s, way, v, oldest;
        logic [LINE_W-1:0] ln;
        logic              dirty;
        logic              ov, od;
        logic [ADDR_W-1:0] ob;
        logic [LINE_W-1:0] odata;
        logic              done [PQ];

        ln    = msh_data[m];
        dirty = 1'b0;

        for (int i = 0; i < PQ; i++) done[i] = 1'b0;
        forever begin
            oldest = -1;
            for (int p = 0; p < PQ; p++)
                if (pq_val[p] && !done[p] && pq_mshr[p] == m[31:0])
                    if (oldest < 0 || pq_seq[p] < pq_seq[oldest]) oldest = p;
            if (oldest < 0) break;
            if (pq_we[oldest]) begin
                ln    = line_merge(ln, pq_addr[oldest], pq_size[oldest], pq_wdata[oldest]);
                dirty = 1'b1;
            end else begin
                pq_rdata[oldest] = line_extract(ln, pq_addr[oldest], pq_size[oldest]);
            end
            pq_ready[oldest] = 1'b1;
            pq_hit[oldest]   = 1'b0;
            pq_mshr[oldest]  = MSHRS[31:0];   // resolved; no longer tied to an MSHR
            done[oldest]     = 1'b1;
        end

        s   = set_of(msh_base[m]);
        way = s*WAYS + (rr[s] % WAYS);
        ov = arr_val[way]; od = arr_dty[way]; odata = arr_data[way];
        ob = {arr_tag[way], SET_W'(s), OFF_W'(0)};

        arr_val [way] = 1'b1;
        arr_tag [way] = tag_of(msh_base[m]);
        arr_dty [way] = dirty;
        arr_data[way] = ln;
        rr[s]         = (rr[s] + 1) % WAYS;

        if (ov) begin
            v = -1;
            for (int i = 0; i < VICTIM_ENT; i++) if (!vic_val[i]) begin v = i; break; end
            if (v < 0) begin
                v      = vic_rr % VICTIM_ENT;
                vic_rr = vic_rr + 1;
                // the line being displaced OUT of the victim buffer leaves the
                // cache entirely -- if it is dirty it must reach memory
                if (vic_dty[v]) begin
                    int wq;
                    wq = free_wb();
                    if (wq >= 0) begin
                        wb_val[wq]  = 1'b1;
                        wb_base[wq] = vic_base[v];
                        wb_data[wq] = vic_data[v];
                    end
                end
            end
            vic_val[v]  = 1'b1;
            vic_dty[v]  = od;
            vic_base[v] = ob;
            vic_data[v] = odata;
        end

        msh_val[m] = 1'b0;
    endtask

    logic [TAG_W-1:0] pq_tag_saved_a, pq_tag_saved_b;

    task automatic emit(input logic port, input int p);
        if (port == 1'b0) pq_tag_saved_a = pq_tag[p];
        else              pq_tag_saved_b = pq_tag[p];
        if (port == 1'b0) begin
            A_resp_valid = 1'b1;
            A_resp_tag   = pq_tag[p];
            A_resp_hit   = pq_hit[p];
            A_resp_rdata = pq_we[p] ? '0 : pq_rdata[p];
        end else begin
            B_resp_valid = 1'b1;
            B_resp_tag   = pq_tag[p];
            B_resp_hit   = pq_hit[p];
            B_resp_rdata = pq_we[p] ? '0 : pq_rdata[p];
        end
        pq_val[p] = 1'b0;
    endtask

    // -----------------------------------------------------------------
    // One procedure per edge, entirely in blocking assignments. Mixing
    // blocking and non-blocking over the same arrays here would be a race;
    // this is a reference model, so a well-ordered procedure is both simpler
    // and easier to argue about than a synthesis-shaped one.
    //
    // Order matters and is:
    //   1. respond to ready entries        (uses pre-edge selection)
    //   2. memory request / response bookkeeping
    //   3. accept new requests, A ordered before B
    //   4. install any filled MSHR and drain its merged chain
    //
    // ACCEPT MUST COME BEFORE INSTALL. req_ready is combinational from pre-edge
    // state; if install ran first it could evict the very line that made the
    // access a hit, or drain and free the MSHR that made it a merge, turning it
    // into a true miss that then has no MSHR to allocate. That handed the entry
    // an out-of-range MSHR index, so it never became ready (a request that is
    // never answered) and its data was never written (a wrong read). Accepting
    // first makes accept_req see exactly the state req_ready was computed from.
    // A just-accepted entry carries the highest seq, so if it merges into an
    // MSHR that fills in this same cycle, step 4 still drains it last -- program
    // order is preserved.
    // -----------------------------------------------------------------
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            for (int i = 0; i < NLINE; i++)      begin arr_val[i] = 1'b0; arr_dty[i] = 1'b0; end
            for (int i = 0; i < SETS; i++)       rr[i] = 32'd0;
            for (int i = 0; i < VICTIM_ENT; i++) begin vic_val[i] = 1'b0; vic_dty[i] = 1'b0; end
            for (int i = 0; i < MSHRS; i++)      msh_val[i] = 1'b0;
            for (int i = 0; i < PQ; i++)         pq_val[i]  = 1'b0;
            for (int i = 0; i < WBQ; i++)        wb_val[i]  = 1'b0;
            vic_rr       = 32'd0;
            seq_ctr      = 32'd0;
            mem_busy     = 1'b0;
            mem_is_wb    = 1'b0;
            mem_owner    = 32'd0;
            A_resp_valid = 1'b0;
            B_resp_valid = 1'b0;
        end else begin
            A_resp_valid = 1'b0;
            B_resp_valid = 1'b0;

            // 1. respond
            // MUTANT 3: with two responses in flight in the same cycle the tags
            // are crossed between the ports -- the classic concurrent-response
            // mix-up. Each port still answers, with the other's tag.
            if (svc_a >= 0 && svc_b >= 0 && svc_b != svc_a) begin
                emit(1'b0, svc_a);
                emit(1'b1, svc_b);
                A_resp_tag = pq_tag_saved_b;
                B_resp_tag = pq_tag_saved_a;
            end else begin
                if (svc_a >= 0)                  emit(1'b0, svc_a);
                if (svc_b >= 0 && svc_b != svc_a) emit(1'b1, svc_b);
            end

            // 2. memory
            if (do_wb) begin
                mem_busy  = 1'b1;
                mem_is_wb = 1'b1;
                wb_val[wb_pick] = 1'b0;
            end else if (do_fill) begin
                mem_busy   = 1'b1;
                mem_is_wb  = 1'b0;
                mem_owner  = fill_pick[31:0];
                msh_issued[fill_pick] = 1'b1;
            end
            if (mem_resp_valid) begin
                mem_busy = 1'b0;
                if (!mem_is_wb) begin
                    msh_data  [mem_owner] = mem_resp_rdata;
                    msh_filled[mem_owner] = 1'b1;
                end
            end

            // 3. accept, A before B
            if (A_req_valid && A_req_ready)
                accept_req(1'b0, A_req_addr, A_req_we, A_req_wdata, A_req_size, A_req_tag);
            if (B_req_valid && B_req_ready)
                accept_req(1'b1, B_req_addr, B_req_we, B_req_wdata, B_req_size, B_req_tag);

            // 4. install + drain
            for (int m = 0; m < MSHRS; m++)
                if (msh_val[m] && msh_filled[m]) install_and_drain(m);
        end
    end

endmodule
