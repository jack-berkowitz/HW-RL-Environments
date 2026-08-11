// =============================================================================
// lsq.sv -- MUTANT 3: partial overlap treated as exact match (throwaway) (harness validation only, NOT a candidate)
// =============================================================================
// Implements interfaces/TierTwo/lsq_iface.sv exactly. Exists to prove the
// testbench passes something correct and fails deliberate mutants; it must
// never be placed in candidates/.
//
// Structure: one flat entry table (loads and stores share the slot space) with a
// monotonic age per entry. Slots are allocated round-robin from a free list
// rather than as a strict circular buffer, because loads retire out of order and
// a head/tail pair would false-block.
//
// The scheduler picks at most one action per cycle, in this priority order:
//   1. drain a committed store to memory (in program order among stores)
//   2. return a forwardable load
//   3. start a memory read for a load that has to go to memory
// Memory is single-outstanding, so 1 and 3 contend for the same resource.
//
// The subtle part is the legality gate. `older_store_unknown` is a full scan of
// the table each cycle rather than an incremental flag, because an allocation, a
// squash, or an address resolution can all change it, and getting it wrong is
// exactly the bug this module exists to expose.
// =============================================================================

module lsq #(
    parameter int DEPTH  = 16,
    parameter int ADDR_W = 10,
    parameter int DATA_W = 32,
    parameter int AGE_W  = 16,
    // derived -- do not override
    parameter int IDX_W  = $clog2(DEPTH)
) (
    input  logic                clk,
    input  logic                rst_n,

    input  logic                alloc_valid,
    input  logic                alloc_is_store,
    input  logic                alloc_addr_known,
    output logic [IDX_W-1:0]    lsq_idx,

    input  logic                addr_valid,
    input  logic [IDX_W-1:0]    addr_lsq_idx,
    input  logic [ADDR_W-1:0]   addr_value,
    input  logic [1:0]          addr_size,

    input  logic                store_data_valid,
    input  logic [IDX_W-1:0]    store_data_lsq_idx,
    input  logic [DATA_W-1:0]   store_data_value,

    output logic                load_result_valid,
    output logic [IDX_W-1:0]    load_result_lsq_idx,
    output logic [DATA_W-1:0]   load_result_value,
    output logic                load_result_source,

    output logic                mem_req_valid,
    output logic [ADDR_W-1:0]   mem_req_addr,
    output logic                mem_req_we,
    output logic [DATA_W-1:0]   mem_req_wdata,
    output logic [1:0]          mem_req_size,
    input  logic                mem_resp_valid,
    input  logic [DATA_W-1:0]   mem_resp_rdata,

    input  logic                store_commit_valid,
    input  logic [IDX_W-1:0]    store_commit_lsq_idx,

    input  logic                flush_valid,
    input  logic [AGE_W-1:0]    flush_age_threshold
);

    localparam logic SRC_MEM = 1'b0;
    localparam logic SRC_FWD = 1'b1;

    // ---------------------------------------------------------------------
    // entry table
    // ---------------------------------------------------------------------
    logic              e_val    [DEPTH];   // slot occupied
    logic              e_store  [DEPTH];
    logic              e_addr_k [DEPTH];
    logic [ADDR_W-1:0] e_addr   [DEPTH];
    logic [1:0]        e_size   [DEPTH];
    logic              e_data_k [DEPTH];
    logic [DATA_W-1:0] e_data   [DEPTH];
    logic [AGE_W-1:0]  e_age    [DEPTH];
    logic              e_commit [DEPTH];   // store: retire received
    logic              e_sent   [DEPTH];   // store: its write was accepted

    logic [AGE_W-1:0]  age_ctr;

    // in-flight memory transaction
    logic              mem_busy;
    logic              mem_is_store;
    logic [IDX_W-1:0]  mem_owner;
    logic [AGE_W-1:0]  mem_owner_age;   // generation tag: the slot may be
                                        // squashed and reused while in flight

    // ---------------------------------------------------------------------
    // free-slot pick (lowest free index)
    // ---------------------------------------------------------------------
    always_comb begin
        lsq_idx = '0;
        for (int i = DEPTH-1; i >= 0; i--)
            if (!e_val[i]) lsq_idx = IDX_W'(i);
    end

    // ---------------------------------------------------------------------
    // byte-range helpers
    // ---------------------------------------------------------------------
    function automatic int nbytes(input logic [1:0] s);
        case (s)
            2'b00:   return 1;
            2'b01:   return 2;
            default: return 4;
        endcase
    endfunction

    function automatic logic overlaps(input logic [ADDR_W-1:0] a0, input logic [1:0] s0,
                                      input logic [ADDR_W-1:0] a1, input logic [1:0] s1);
        int lo0, hi0, lo1, hi1;
        lo0 = int'(a0); hi0 = lo0 + nbytes(s0);
        lo1 = int'(a1); hi1 = lo1 + nbytes(s1);
        return (lo0 < hi1) && (lo1 < hi0);
    endfunction

    function automatic logic exact(input logic [ADDR_W-1:0] a0, input logic [1:0] s0,
                                   input logic [ADDR_W-1:0] a1, input logic [1:0] s1);
        return (a0 == a1) && (s0 == s1);
    endfunction

    function automatic logic [DATA_W-1:0] zext(input logic [DATA_W-1:0] v, input logic [1:0] s);
        case (s)
            2'b00:   return {{(DATA_W-8){1'b0}},  v[7:0]};
            2'b01:   return {{(DATA_W-16){1'b0}}, v[15:0]};
            default: return v;
        endcase
    endfunction

    // ---------------------------------------------------------------------
    // scheduling decisions (combinational, from registered state)
    // ---------------------------------------------------------------------

    // oldest committed store that still has to be written to memory
    logic             have_st_drain;
    logic [IDX_W-1:0] st_drain_idx;
    always_comb begin
        have_st_drain = 1'b0;
        st_drain_idx  = '0;
        for (int i = 0; i < DEPTH; i++)
            if (e_val[i] && e_store[i] && e_commit[i] && !e_sent[i])
                if (!have_st_drain || e_age[i] < e_age[st_drain_idx]) begin
                    have_st_drain = 1'b1;
                    st_drain_idx  = IDX_W'(i);
                end
    end

    // is any older store than `ld` still address-unknown?
    function automatic logic older_store_unknown(input int ld);
        for (int j = 0; j < DEPTH; j++)
            if (e_val[j] && e_store[j] && (e_age[j] < e_age[ld]) && !e_addr_k[j])
                return 1'b1;
        return 1'b0;
    endfunction

    // nearest older overlapping store (youngest older store that overlaps)
    function automatic int nearest_overlap(input int ld);
        int best;
        best = -1;
        for (int j = 0; j < DEPTH; j++)
            if (e_val[j] && e_store[j] && e_addr_k[j] && (e_age[j] < e_age[ld])
                && overlaps(e_addr[j], e_size[j], e_addr[ld], e_size[ld]))
                if (best < 0 || e_age[j] > e_age[best]) best = j;
        return best;
    endfunction

    // Load readiness as a returned code rather than output arguments, which
    // Icarus rejects -- keeping this file runnable under both simulators.
    //   0 = not answerable, 1 = forwardable now, 2 = needs a memory read
    function automatic int load_state(input int i);
        int s;
        if (!e_val[i] || e_store[i] || !e_addr_k[i]) return 0;
        if (older_store_unknown(i)) return 0;          // conservative gate
        s = nearest_overlap(i);
        if (s < 0) return 2;                           // nothing older overlaps
        // MUTANT 3: any overlap counts as an exact match, so a partial overlap
        // forwards the store's whole word instead of stalling -- wrong bytes.
        if (e_data_k[s])
            return 1;
        return 0;                                      // partial overlap, or no data yet
    endfunction

    // pick the oldest forwardable load, and the oldest memory-bound load
    logic             have_fwd, have_ldmem;
    logic [IDX_W-1:0] fwd_idx, ldmem_idx;
    logic [DATA_W-1:0] fwd_data;
    always_comb begin
        int st;
        have_fwd = 1'b0; fwd_idx = '0; fwd_data = '0;
        have_ldmem = 1'b0; ldmem_idx = '0;
        for (int i = 0; i < DEPTH; i++) begin
            st = load_state(i);
            if (st == 1)
                if (!have_fwd || e_age[i] < e_age[fwd_idx]) begin
                    have_fwd = 1'b1;
                    fwd_idx  = IDX_W'(i);
                end
            if (st == 2)
                if (!have_ldmem || e_age[i] < e_age[ldmem_idx]) begin
                    have_ldmem = 1'b1;
                    ldmem_idx  = IDX_W'(i);
                end
        end
        if (have_fwd) begin
            int s;
            s = nearest_overlap(int'(fwd_idx));
            fwd_data = zext(e_data[s], e_size[fwd_idx]);
        end
    end

    // memory arbitration: stores drain first, then memory-bound loads
    logic issue_st, issue_ld;
    assign issue_st = !mem_busy && have_st_drain;
    assign issue_ld = !mem_busy && !have_st_drain && have_ldmem;

    assign mem_req_valid = issue_st || issue_ld;
    assign mem_req_we    = issue_st;
    assign mem_req_addr  = issue_st ? e_addr[st_drain_idx] : e_addr[ldmem_idx];
    assign mem_req_size  = issue_st ? e_size[st_drain_idx] : e_size[ldmem_idx];
    assign mem_req_wdata = issue_st ? e_data[st_drain_idx] : '0;

    // ---------------------------------------------------------------------
    // A returning memory read and a ready forward can both want the single
    // load-result port in the same cycle. Only one result may be emitted per
    // cycle, so they must be arbitrated -- emitting one while retiring both
    // entries would silently drop a load.
    // ---------------------------------------------------------------------
    logic mem_ld_deliver;

    // ---------------------------------------------------------------------
    // squash predicate
    // ---------------------------------------------------------------------
    function automatic logic squashed(input int i);
        return flush_valid && e_val[i] && (e_age[i] > flush_age_threshold);
    endfunction

    // ---------------------------------------------------------------------
    // sequential
    // ---------------------------------------------------------------------
    always_ff @(posedge clk) begin
        // Evaluated here, at the edge, rather than as a continuous assign.
        // A continuous assign whose RHS calls a function that indexes arrays by
        // a variable relies on the tool's sensitivity inference; Icarus left it
        // stale across a flush and delivered a result for a squashed load.
        // Computing it in the same process that consumes it is unambiguous in
        // every simulator.
        mem_ld_deliver = mem_resp_valid && mem_busy && !mem_is_store
                       && e_val[mem_owner] && (e_age[mem_owner] == mem_owner_age)
                       && !squashed(int'(mem_owner));

        if (!rst_n) begin
            for (int i = 0; i < DEPTH; i++) begin
                e_val[i]    <= 1'b0;
                e_addr_k[i] <= 1'b0;
                e_data_k[i] <= 1'b0;
                e_commit[i] <= 1'b0;
                e_sent[i]   <= 1'b0;
            end
            age_ctr           <= '0;
            mem_busy          <= 1'b0;
            load_result_valid <= 1'b0;
        end else begin
            load_result_valid <= 1'b0;

            // ---- forwarded load result (a flush this cycle wins over it) ----
            // Yields the port to a returning memory read; the load stays live
            // and is re-offered next cycle.
            if (have_fwd && !squashed(int'(fwd_idx)) && !mem_ld_deliver) begin
                load_result_valid   <= 1'b1;
                load_result_lsq_idx <= fwd_idx;
                load_result_value   <= fwd_data;
                load_result_source  <= SRC_FWD;
                e_val[fwd_idx]      <= 1'b0;      // load leaves on result
            end

            // ---- launch a memory transaction ----
            if (issue_st) begin
                mem_busy      <= 1'b1;
                mem_is_store  <= 1'b1;
                mem_owner     <= st_drain_idx;
                mem_owner_age <= e_age[st_drain_idx];
                e_sent[st_drain_idx] <= 1'b1;
            end else if (issue_ld) begin
                mem_busy      <= 1'b1;
                mem_is_store  <= 1'b0;
                mem_owner     <= ldmem_idx;
                mem_owner_age <= e_age[ldmem_idx];
            end

            // ---- memory response ----
            if (mem_resp_valid) begin
                mem_busy <= 1'b0;
                if (mem_is_store) begin
                    if (e_val[mem_owner] && e_age[mem_owner] == mem_owner_age)
                        e_val[mem_owner] <= 1'b0; // store leaves once written
                end else begin
                    // deliver only if the slot still holds the SAME load: it may
                    // have been squashed and reallocated while the read was away
                    if (mem_ld_deliver) begin
                        load_result_valid   <= 1'b1;
                        load_result_lsq_idx <= mem_owner;
                        load_result_value   <= zext(mem_resp_rdata, e_size[mem_owner]);
                        load_result_source  <= SRC_MEM;
                        e_val[mem_owner]    <= 1'b0;
                    end
                end
            end

            // ---- address resolution ----
            if (addr_valid) begin
                e_addr_k[addr_lsq_idx] <= 1'b1;
                e_addr  [addr_lsq_idx] <= addr_value;
                e_size  [addr_lsq_idx] <= addr_size;
            end

            // ---- store data resolution ----
            if (store_data_valid) begin
                e_data_k[store_data_lsq_idx] <= 1'b1;
                e_data  [store_data_lsq_idx] <= store_data_value;
            end

            // ---- store retire ----
            if (store_commit_valid)
                e_commit[store_commit_lsq_idx] <= 1'b1;

            // ---- allocate ----
            if (alloc_valid) begin
                e_val   [lsq_idx] <= 1'b1;
                e_store [lsq_idx] <= alloc_is_store;
                e_age   [lsq_idx] <= age_ctr;
                e_data_k[lsq_idx] <= 1'b0;
                e_commit[lsq_idx] <= 1'b0;
                e_sent  [lsq_idx] <= 1'b0;
                // same-cycle address supply
                if (alloc_addr_known && addr_valid && addr_lsq_idx == lsq_idx) begin
                    e_addr_k[lsq_idx] <= 1'b1;
                    e_addr  [lsq_idx] <= addr_value;
                    e_size  [lsq_idx] <= addr_size;
                end else begin
                    e_addr_k[lsq_idx] <= 1'b0;
                end
                age_ctr <= age_ctr + AGE_W'(1);
            end

            // ---- flush: squash everything younger than the threshold ----
            // Last, so it overrides allocation/resolution in the same cycle. A
            // store whose write was already accepted keeps its slot until the
            // response lands -- the transaction cannot be recalled.
            if (flush_valid) begin
                for (int i = 0; i < DEPTH; i++)
                    if (squashed(i)) begin
                        if (!(e_store[i] && e_sent[i])) begin
                            e_val[i]    <= 1'b0;
                            e_addr_k[i] <= 1'b0;
                            e_data_k[i] <= 1'b0;
                            e_commit[i] <= 1'b0;
                        end
                    end
                if (have_fwd && !mem_ld_deliver && squashed(int'(fwd_idx)))
                    load_result_valid <= 1'b0;
            end
        end
    end

endmodule
