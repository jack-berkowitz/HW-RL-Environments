// =============================================================================
// lsq.sv -- Load/Store Queue with out-of-order load issue, conservative memory
//           disambiguation and store-to-load forwarding.
//           Implements interfaces/TierTwo/lsq_iface.sv.
// =============================================================================
// Adapted from the user's `storequeue`. What carries over is its disambiguation
// microarchitecture, which is the real content of that module:
//   * a per-load CAM sweep over the queue building the age-relative masks --
//     older_store_mask / addr_unknown ("ambiguous store") / addr_match -- and
//     then selecting the YOUNGEST older overlapping store as the forwarding
//     source. Same O(DEPTH^2) compare array, same one-hot select shape.
//   * the "load is delayed for forward" stall, split here into the three cases
//     the contract distinguishes (unknown-older / exact-no-data / partial).
//   * a single-outstanding memory port with writes prioritised over reads, so a
//     load stalled on a partial overlap cannot wait forever on the store that
//     blocks it.
//
// What could NOT carry over: the original's container. `storequeue` holds only
// stores, in the FIFO `queue` primitive, with loads querying it from outside.
// Here loads and stores share one slot space and entries are freed OUT OF ORDER
// (a load's entry frees when its result is delivered, and results are by
// definition unordered), which a head/tail FIFO cannot express. The container is
// therefore a flat slot array with a valid bit and an explicit age tag -- the
// age tag being what the iface specifies as the module's own ordering, rather
// than the ROB pointer the original borrowed.
//
// TIMING: lsq_idx is combinational; every other output is registered. Memory
// requests are a ONE-CYCLE pulse issued only when this module knows the port is
// idle, which is what keeps the single-outstanding contract legal without a
// busy input.
// =============================================================================

module lsq #(
    parameter int DEPTH  = 8,    // 8 / 16 / 32, power of 2
    parameter int ADDR_W = 10,
    parameter int DATA_W = 32,
    parameter int AGE_W  = 16,
    // derived -- do not override
    parameter int IDX_W  = $clog2(DEPTH)
) (
    input  logic                clk,
    input  logic                rst_n,

    // ---- allocate (one per cycle, program order) ----
    input  logic                alloc_valid,
    input  logic                alloc_is_store,
    input  logic                alloc_addr_known,
    output logic [IDX_W-1:0]    lsq_idx,

    // ---- address resolution (from AGU / execute) ----
    input  logic                addr_valid,
    input  logic [IDX_W-1:0]    addr_lsq_idx,
    input  logic [ADDR_W-1:0]   addr_value,
    input  logic [1:0]          addr_size,

    // ---- store data resolution ----
    input  logic                store_data_valid,
    input  logic [IDX_W-1:0]    store_data_lsq_idx,
    input  logic [DATA_W-1:0]   store_data_value,

    // ---- load result (LSQ-internally triggered once legal) ----
    output logic                load_result_valid,
    output logic [IDX_W-1:0]    load_result_lsq_idx,
    output logic [DATA_W-1:0]   load_result_value,
    output logic                load_result_source,   // 0 = memory, 1 = forwarded

    // ---- memory interface (single outstanding) ----
    output logic                mem_req_valid,
    output logic [ADDR_W-1:0]   mem_req_addr,
    output logic                mem_req_we,
    output logic [DATA_W-1:0]   mem_req_wdata,
    output logic [1:0]          mem_req_size,
    input  logic                mem_resp_valid,
    input  logic [DATA_W-1:0]   mem_resp_rdata,

    // ---- store retire ----
    input  logic                store_commit_valid,
    input  logic [IDX_W-1:0]    store_commit_lsq_idx,

    // ---- flush ----
    input  logic                flush_valid,
    input  logic [AGE_W-1:0]    flush_age_threshold
);

    // -----------------------------------------------------------------------
    // entry state
    // -----------------------------------------------------------------------
    logic              e_val    [0:DEPTH-1], e_val_n    [0:DEPTH-1];
    logic              e_store  [0:DEPTH-1], e_store_n  [0:DEPTH-1];
    logic              e_addr_k [0:DEPTH-1], e_addr_k_n [0:DEPTH-1];
    logic [ADDR_W-1:0] e_addr   [0:DEPTH-1], e_addr_n   [0:DEPTH-1];
    logic [1:0]        e_size   [0:DEPTH-1], e_size_n   [0:DEPTH-1];
    logic              e_data_k [0:DEPTH-1], e_data_k_n [0:DEPTH-1];
    logic [DATA_W-1:0] e_data   [0:DEPTH-1], e_data_n   [0:DEPTH-1];
    logic [AGE_W-1:0]  e_age    [0:DEPTH-1], e_age_n    [0:DEPTH-1];
    logic              e_commit [0:DEPTH-1], e_commit_n [0:DEPTH-1];
    logic              e_sent   [0:DEPTH-1], e_sent_n   [0:DEPTH-1];

    logic [AGE_W-1:0]  age_ctr, age_ctr_n;

    // -----------------------------------------------------------------------
    // AGE-ORDER MATRIX.  older[i][j] == 1 means "entry j is older than entry i".
    //
    // Every ordering rule in lsq_iface.sv is relative ("every older store", "the
    // youngest older overlapping store", "the oldest committed store"), and none
    // of them needs the numeric age -- only the order. Comparing e_age directly
    // put an AGE_W-wide magnitude comparator in every cell of the DEPTH*DEPTH
    // disambiguation sweep, plus more in the store/load selectors: ~160
    // 16-bit comparators in a module that is otherwise only 651 flops. That is
    // both the bulk of the area and the reason Yosys's SAT-based `share` pass
    // (cost quadratic in arithmetic-operator count) dominated synthesis.
    //
    // The matrix is the standard fix: order is decided ONCE, at allocation, and
    // every later query is a single-bit lookup. It costs DEPTH*DEPTH = 64 bits.
    //
    // Maintenance is entirely at allocation: the entry being allocated is by
    // construction the youngest, so its row is "every currently-live entry is
    // older than me" and its column is all-zero. Rewriting the COLUMN matters as
    // much as the row -- without it a reused slot would still be recorded as
    // older than entries allocated before it was freed.
    //
    // e_age itself is kept, but is now used only where a real number is required:
    // the external flush threshold compare, and identifying an in-flight memory
    // transaction across slot reuse. That is ~9 comparators instead of ~160.
    logic older [0:DEPTH-1][0:DEPTH-1], older_n [0:DEPTH-1][0:DEPTH-1];

    // memory port bookkeeping. The owner is identified by slot AND AGE: a slot
    // freed by a flush can be reallocated while its read is still in flight, and
    // the slot number alone would then deliver stale data to the new occupant.
    logic              mem_infl,  mem_infl_n;
    logic              mem_iswr,  mem_iswr_n;
    logic [IDX_W-1:0]  mem_own,   mem_own_n;
    logic [AGE_W-1:0]  mem_age,   mem_age_n;

    logic              mem_rv_n;
    logic [ADDR_W-1:0] mem_ra_n;
    logic              mem_rw_n;
    logic [DATA_W-1:0] mem_rd_n;
    logic [1:0]        mem_rs_n;

    // registered request outputs
    logic              mem_rv_q;
    logic [ADDR_W-1:0] mem_ra_q;
    logic              mem_rw_q;
    logic [DATA_W-1:0] mem_rd_q;
    logic [1:0]        mem_rs_q;

    assign mem_req_valid = mem_rv_q;
    assign mem_req_addr  = mem_ra_q;
    assign mem_req_we    = mem_rw_q;
    assign mem_req_wdata = mem_rd_q;
    assign mem_req_size  = mem_rs_q;

    // registered result outputs
    logic              lr_v_n;
    logic [IDX_W-1:0]  lr_i_n;
    logic [DATA_W-1:0] lr_d_n;
    logic              lr_s_n;

    // -----------------------------------------------------------------------
    // byte-range helpers (size 2'b00=1B, 2'b01=2B, 2'b10=4B, naturally aligned)
    // -----------------------------------------------------------------------
    // Byte-range arithmetic is done in ADDR_W+1 bits, NOT in `int`.
    //
    // rng_ovl is instantiated DEPTH*DEPTH times inside the disambiguation sweep
    // below, twice per call. Returning `int` from nb_of and casting with int'()
    // made every one of those a 32-bit adder feeding a 32-bit magnitude
    // comparator, when the widest value involved is addr + 4 <= 1027. That one
    // detail is the largest single area term in this module. ADDR_W+1 = 11 bits
    // covers the sum exactly, with no change in behaviour.
    localparam int AW1 = ADDR_W + 1;

    // Overlap test with NO arithmetic.
    //
    // The iface guarantees accesses are NATURALLY ALIGNED and sizes are 1/2/4
    // bytes, so a smaller access always lies wholly inside one block of the
    // larger size. Two accesses therefore overlap iff their addresses agree
    // above the coarser of the two size granularities. The 2-bit size encoding
    // is exactly log2(nbytes) (00->1, 01->2, 10->4), so that granularity is
    // just max(s0,s1) and the whole test collapses to a masked equality:
    //
    //     overlap  <=>  (a0 >> k) == (a1 >> k),   k = max(s0,s1)
    //
    // This replaces two adders and two magnitude comparators -- instantiated
    // DEPTH*DEPTH times in the sweep below -- with an XOR and a zero test.
    // Yosys's SAT-based SHARE pass is quadratic in the number of arithmetic
    // operators it has to consider, and this removes them from the module
    // entirely, which is what makes lsq synthesise in reasonable time.
    function automatic logic rng_ovl(input logic [ADDR_W-1:0] a0, input logic [1:0] s0,
                                     input logic [ADDR_W-1:0] a1, input logic [1:0] s1);
        logic [1:0] k;
        begin
            k = (s0 > s1) ? s0 : s1;
            rng_ovl = ((a0 ^ a1) >> k) == '0;
        end
    endfunction

    function automatic logic rng_exact(input logic [ADDR_W-1:0] a0, input logic [1:0] s0,
                                       input logic [ADDR_W-1:0] a1, input logic [1:0] s1);
        rng_exact = (a0 == a1) && (s0 == s1);
    endfunction

    function automatic logic [DATA_W-1:0] zext(input logic [DATA_W-1:0] v,
                                               input logic [1:0]        s);
        case (s)
            2'b00:   zext = {{(DATA_W-8 ){1'b0}}, v[7:0]};
            2'b01:   zext = {{(DATA_W-16){1'b0}}, v[15:0]};
            default: zext = v;
        endcase
    endfunction

    // -----------------------------------------------------------------------
    // lsq_idx -- COMBINATIONAL: the slot an allocation this cycle would take
    // -----------------------------------------------------------------------
    always_comb begin
        lsq_idx = '0;
        for (int i = DEPTH-1; i >= 0; i--)
            if (!e_val[i]) lsq_idx = IDX_W'(i);
    end

    // =======================================================================
    // Per-load disambiguation.
    //   ld_legal : every older store still in the queue has a KNOWN address
    //   ld_fwd   : legal, and the nearest older overlapping store is an EXACT
    //              match whose data has resolved  -> forward from ld_src
    //   ld_mem   : legal, and no older store overlaps at all -> read memory
    //   neither  : stall (exact match without data, or a partial overlap)
    // =======================================================================
    logic             ld_legal [0:DEPTH-1];
    logic             ld_fwd   [0:DEPTH-1];
    logic             ld_mem   [0:DEPTH-1];
    logic [IDX_W-1:0] ld_src   [0:DEPTH-1];

    always_comb begin
        for (int i = 0; i < DEPTH; i++) begin
            logic unknown_older;             // "ambiguous store" older than this load
            // Youngest older overlapping store, as valid+index. "j is younger
            // than the incumbent" is older[j][best_idx] -- a one-bit lookup,
            // where this used to be an AGE_W magnitude compare.
            logic             best_v;
            logic [IDX_W-1:0] best_idx;

            ld_legal[i] = 1'b0;
            ld_fwd  [i] = 1'b0;
            ld_mem  [i] = 1'b0;
            ld_src  [i] = '0;

            if (e_val[i] && !e_store[i] && e_addr_k[i]) begin
                unknown_older = 1'b0;
                best_v        = 1'b0;
                best_idx      = '0;

                for (int j = 0; j < DEPTH; j++) begin
                    if (e_val[j] && e_store[j] && older[i][j]) begin
                        if (!e_addr_k[j]) begin
                            unknown_older = 1'b1;
                        end else if (rng_ovl(e_addr[j], e_size[j],
                                             e_addr[i], e_size[i])) begin
                            if (!best_v || older[j][best_idx]) begin
                                best_v   = 1'b1;
                                best_idx = IDX_W'(j);
                            end
                        end
                    end
                end

                // conservative: ONE unknown older store blocks the load outright
                if (!unknown_older) begin
                    ld_legal[i] = 1'b1;
                    if (!best_v) begin
                        ld_mem[i] = 1'b1;                       // -> SRC_MEM
                    end else if (rng_exact(e_addr[best_idx], e_size[best_idx],
                                           e_addr[i], e_size[i]) &&
                                 e_data_k[best_idx]) begin
                        ld_fwd[i] = 1'b1;                       // -> SRC_FWD
                        ld_src[i] = best_idx;
                    end
                    // else: exact-match-without-data or PARTIAL overlap -> stall
                end
            end
        end
    end

    // oldest committed store that has not yet been handed to memory: the only
    // store allowed to go next, which is what keeps writes in program order
    logic             st_v;
    logic [IDX_W-1:0] st_idx;
    always_comb begin
        st_v   = 1'b0;
        st_idx = '0;
        for (int i = 0; i < DEPTH; i++)
            if (e_val[i] && e_store[i] && e_commit[i] && !e_sent[i])
                // "i is older than the incumbent" -> older[st_idx][i]
                if (!st_v || older[st_idx][i]) begin
                    st_v   = 1'b1;
                    st_idx = IDX_W'(i);
                end
    end

    // ...but a store may not reach memory ahead of ANY older load that has not
    // been answered yet. An unanswered older load's value is architecturally
    // fixed the moment it clears disambiguation; letting a younger store land
    // in memory first would make it read data it must never see.
    //
    // The test is deliberately "any older live load", not "any older load that
    // is legal RIGHT NOW". A request is decided one cycle before memory accepts
    // it, so gating on present legality leaves a one-cycle hole: a load that
    // becomes legal in between has its value fixed against pre-write memory and
    // then reads post-write memory.
    //
    // This cannot deadlock: whatever blocks a load -- an older store with an
    // unknown address, an unresolved exact-match store, or a partial overlap
    // waiting to retire -- is by definition OLDER than that load, so it is never
    // one of the stores this rule holds back.
    logic st_ok;
    always_comb begin
        st_ok = st_v;
        if (st_v)
            for (int j = 0; j < DEPTH; j++)
                if (e_val[j] && !e_store[j] && older[st_idx][j]) st_ok = 1'b0;
    end

    // oldest forwardable load, and oldest memory-bound load with no read yet
    logic             ldf_v, ldm_v;
    logic [IDX_W-1:0] ldf_idx, ldm_idx;
    always_comb begin
        ldf_v = 1'b0; ldf_idx = '0;
        ldm_v = 1'b0; ldm_idx = '0;
        for (int i = 0; i < DEPTH; i++) begin
            if (ld_fwd[i])
                if (!ldf_v || older[ldf_idx][i]) begin
                    ldf_v = 1'b1; ldf_idx = IDX_W'(i);
                end
            if (ld_mem[i] && !(mem_infl && !mem_iswr && mem_own == IDX_W'(i) &&
                               mem_age == e_age[i]))
                if (!ldm_v || older[ldm_idx][i]) begin
                    ldm_v = 1'b1; ldm_idx = IDX_W'(i);
                end
        end
    end

    // =======================================================================
    // Next state
    // =======================================================================
    always_comb begin : NEXT_STATE
        logic              mem_ld_done;
        logic [AGE_W-1:0]  res_age;
        logic              res_pick;

        // ---- defaults: hold ----
        for (int i = 0; i < DEPTH; i++) begin
            e_val_n[i]=e_val[i];       e_store_n[i]=e_store[i];
            e_addr_k_n[i]=e_addr_k[i]; e_addr_n[i]=e_addr[i];
            e_size_n[i]=e_size[i];     e_data_k_n[i]=e_data_k[i];
            e_data_n[i]=e_data[i];     e_age_n[i]=e_age[i];
            e_commit_n[i]=e_commit[i]; e_sent_n[i]=e_sent[i];
            for (int j = 0; j < DEPTH; j++) older_n[i][j] = older[i][j];
        end
        age_ctr_n  = age_ctr;
        mem_infl_n = mem_infl;
        mem_iswr_n = mem_iswr;
        mem_own_n  = mem_own;
        mem_age_n  = mem_age;
        mem_rv_n = 1'b0; mem_ra_n = mem_ra_q; mem_rw_n = mem_rw_q;
        mem_rd_n = mem_rd_q; mem_rs_n = mem_rs_q;
        lr_v_n = 1'b0; lr_i_n = '0; lr_d_n = '0; lr_s_n = 1'b0;
        res_age  = '0;
        res_pick = 1'b0;

        // ---- memory response ----
        mem_ld_done = 1'b0;
        if (mem_resp_valid && mem_infl) begin
            mem_infl_n = 1'b0;
            if (mem_iswr) begin
                // the committed store's write has reached memory: free it
                if (e_val[mem_own] && e_age[mem_own] == mem_age)
                    e_val_n[mem_own] = 1'b0;
            end else if (e_val[mem_own] && !e_store[mem_own] &&
                         e_age[mem_own] == mem_age) begin
                mem_ld_done = 1'b1;    // its load is still live -> answer it
            end
        end

        // ---- pick this cycle's load result (at most one) ----
        // A returning memory read wins; a forward simply retries next cycle,
        // which is safe because a load that is answerable stays answerable.
        if (mem_ld_done) begin
            lr_v_n = 1'b1;
            lr_i_n = mem_own;
            lr_d_n = zext(mem_resp_rdata, e_size[mem_own]);
            lr_s_n = 1'b0;                       // SRC_MEM
            e_val_n[mem_own] = 1'b0;             // freed as the result is given
            res_age  = e_age[mem_own];
            res_pick = 1'b1;
        end else if (ldf_v) begin
            lr_v_n = 1'b1;
            lr_i_n = ldf_idx;
            lr_d_n = zext(e_data[ld_src[ldf_idx]], e_size[ldf_idx]);
            lr_s_n = 1'b1;                       // SRC_FWD
            e_val_n[ldf_idx] = 1'b0;
            res_age  = e_age[ldf_idx];
            res_pick = 1'b1;
        end

        // ---- memory arbitration: single outstanding, WRITES FIRST ----
        // Writes go first so a load stalled on a partial overlap cannot be
        // starved by the very store it is waiting to see leave the queue.
        if (!mem_infl && !mem_rv_q) begin
            if (st_v && st_ok) begin
                mem_rv_n = 1'b1; mem_rw_n = 1'b1;
                mem_ra_n = e_addr[st_idx];
                mem_rs_n = e_size[st_idx];
                mem_rd_n = e_data[st_idx];
                mem_infl_n = 1'b1; mem_iswr_n = 1'b1; mem_own_n = st_idx;
                mem_age_n  = e_age[st_idx];
                e_sent_n[st_idx] = 1'b1;
            end else if (ldm_v && !res_pick) begin
                mem_rv_n = 1'b1; mem_rw_n = 1'b0;
                mem_ra_n = e_addr[ldm_idx];
                mem_rs_n = e_size[ldm_idx];
                mem_infl_n = 1'b1; mem_iswr_n = 1'b0; mem_own_n = ldm_idx;
                mem_age_n  = e_age[ldm_idx];
            end
        end

        // ---- allocate ----
        if (alloc_valid) begin
            e_val_n   [lsq_idx] = 1'b1;
            e_store_n [lsq_idx] = alloc_is_store;
            e_addr_k_n[lsq_idx] = 1'b0;
            e_data_k_n[lsq_idx] = 1'b0;
            e_commit_n[lsq_idx] = 1'b0;
            e_sent_n  [lsq_idx] = 1'b0;
            e_age_n   [lsq_idx] = age_ctr;
            age_ctr_n           = age_ctr + AGE_W'(1);

            // The allocated entry is by construction the YOUNGEST live entry:
            // its row records every currently-live entry as older, and its
            // column is cleared so nothing regards it as older. Clearing the
            // column is what makes slot reuse safe -- without it, an entry
            // allocated before this slot was freed would still see the fresh
            // occupant as older than itself.
            for (int j = 0; j < DEPTH; j++) begin
                older_n[lsq_idx][j] = e_val[j] && (IDX_W'(j) != lsq_idx);
                older_n[j][lsq_idx] = 1'b0;
            end
        end

        // ---- address / data / commit resolution ----
        // after allocation, so alloc_addr_known lands on the new entry
        if (addr_valid) begin
            e_addr_k_n[addr_lsq_idx] = 1'b1;
            e_addr_n  [addr_lsq_idx] = addr_value;
            e_size_n  [addr_lsq_idx] = addr_size;
        end
        if (store_data_valid) begin
            e_data_k_n[store_data_lsq_idx] = 1'b1;
            e_data_n  [store_data_lsq_idx] = store_data_value;
        end
        if (store_commit_valid)
            e_commit_n[store_commit_lsq_idx] = 1'b1;

        // ---- flush LAST: it overrides same-cycle allocation and resolution --
        // Everything strictly younger than the threshold is squashed, except a
        // store whose write memory has already accepted -- that cannot be
        // recalled, so it completes and frees on its response.
        if (flush_valid) begin
            for (int i = 0; i < DEPTH; i++) begin
                if (e_val_n[i] && (e_age_n[i] > flush_age_threshold) &&
                    !(e_store_n[i] && e_sent_n[i])) begin
                    e_val_n   [i] = 1'b0;
                    e_addr_k_n[i] = 1'b0;
                    e_data_k_n[i] = 1'b0;
                    e_commit_n[i] = 1'b0;
                end
            end

            // the flush wins over a result for a load it squashes
            if (res_pick && (res_age > flush_age_threshold)) begin
                lr_v_n = 1'b0;
                lr_i_n = '0; lr_d_n = '0; lr_s_n = 1'b0;
            end

            // never present a request on behalf of an entry squashed this
            // cycle -- it would be a read with no legal load behind it
            if (mem_rv_n && (e_age_n[mem_own_n] > flush_age_threshold) &&
                !(mem_iswr_n && e_sent[mem_own_n])) begin
                mem_rv_n   = 1'b0;
                mem_infl_n = mem_infl;
                mem_iswr_n = mem_iswr;
                mem_own_n  = mem_own;
                mem_age_n  = mem_age;
        mem_age_n  = mem_age;
                if (!mem_rw_n) begin
                    // read: nothing else to undo
                end else begin
                    e_sent_n[mem_own_n] = e_sent[mem_own_n];
                end
            end
        end
    end

    // =======================================================================
    // Registers -- rst_n is ACTIVE-LOW and SYNCHRONOUS
    // =======================================================================
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            for (int i = 0; i < DEPTH; i++) begin
                e_val[i] <= 1'b0; e_store[i] <= 1'b0; e_addr_k[i] <= 1'b0;
                e_addr[i] <= '0;  e_size[i] <= 2'b10; e_data_k[i] <= 1'b0;
                e_data[i] <= '0;  e_age[i] <= '0;
                e_commit[i] <= 1'b0; e_sent[i] <= 1'b0;
                for (int j = 0; j < DEPTH; j++) older[i][j] <= 1'b0;
            end
            age_ctr  <= '0;
            mem_infl <= 1'b0; mem_iswr <= 1'b0; mem_own <= '0; mem_age <= '0;
            mem_rv_q <= 1'b0; mem_ra_q <= '0; mem_rw_q <= 1'b0;
            mem_rd_q <= '0;   mem_rs_q <= 2'b10;
            load_result_valid   <= 1'b0;
            load_result_lsq_idx <= '0;
            load_result_value   <= '0;
            load_result_source  <= 1'b0;
        end else begin
            for (int i = 0; i < DEPTH; i++) begin
                e_val[i] <= e_val_n[i]; e_store[i] <= e_store_n[i];
                e_addr_k[i] <= e_addr_k_n[i]; e_addr[i] <= e_addr_n[i];
                e_size[i] <= e_size_n[i]; e_data_k[i] <= e_data_k_n[i];
                e_data[i] <= e_data_n[i]; e_age[i] <= e_age_n[i];
                e_commit[i] <= e_commit_n[i]; e_sent[i] <= e_sent_n[i];
                for (int j = 0; j < DEPTH; j++) older[i][j] <= older_n[i][j];
            end
            age_ctr  <= age_ctr_n;
            mem_infl <= mem_infl_n; mem_iswr <= mem_iswr_n; mem_own <= mem_own_n;
            mem_age  <= mem_age_n;
            mem_rv_q <= mem_rv_n;
            if (mem_rv_n) begin
                mem_ra_q <= mem_ra_n; mem_rw_q <= mem_rw_n;
                mem_rd_q <= mem_rd_n; mem_rs_q <= mem_rs_n;
            end
            load_result_valid   <= lr_v_n;
            load_result_lsq_idx <= lr_i_n;
            load_result_value   <= lr_d_n;
            load_result_source  <= lr_s_n;
        end
    end

endmodule
