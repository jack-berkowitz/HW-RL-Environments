// =============================================================================
// lsq_tb.sv -- self-checking testbench for `lsq` (see lsq_iface.sv)
// =============================================================================
// Reference model: a SHADOW of the queue, not a predictor. It never tries to
// guess which cycle the DUT will answer a load -- scheduling is implementation
// defined. It tracks entry state from testbench-driven inputs plus OBSERVED DUT
// events (load results, memory transactions), and grades each event as it
// happens. The golden memory (testbenches/common/golden_mem.sv) carries
// architectural state.
//
// THE CHECK THAT MATTERS: ISSUE LEGALITY IS GRADED SEPARATELY FROM DATA.
// The conservative rule is a TIMING contract -- a load that fires while an older
// store's address is still unknown is wrong even when the value it returns is
// right. Data-only checking would pass that bug on most seeds, so:
//
//   L1  at every load result, no older store still in the queue may have an
//       unresolved address. This is evaluated on the shadow, independently of
//       whether the returned data happened to be correct.
//   L2  whenever the DUT starts a memory READ, at least one live load must
//       actually be legal and memory-bound. Attribution-free, so it catches a
//       DUT that speculates a read for a load it had no right to issue.
//   L3  a load whose nearest older overlapping store is a PARTIAL overlap must
//       not produce a result at all until that store has left the queue.
//
// Data and provenance are then checked on top:
//   D1  value equals forward-from-nearest-older-exact-match, else golden memory
//   D2  load_result_source must honestly say which of those two it was
//   D3  exactly one result per load; every unsquashed load eventually answers
//   D4  committed stores reach memory in program order, and the final memory
//       image matches the golden model byte for byte
//
// Stimulus uses a deliberately tiny, overlapping address pool (two 16-byte
// windows) with mixed 1/2/4-byte accesses, so exact matches, partial overlaps
// and disjoint accesses all occur constantly rather than by luck. Store address
// resolution is frequently delayed for long stretches, which is what makes L1
// bite: an illegally-early load fires while the blocking store is still unknown.
//
// SystemVerilog subset: procedural scoreboard (module-level arrays), no classes,
// so this runs under Verilator AND Icarus. See testbenches/TierTwo/NOTES.md.
//
// Run:
//   $ verilator --binary --timing -j 0 -Wno-fatal --x-assign unique --x-initial unique --top-module lsq_tb -Mdir obj_dir -o sim -Itestbenches/common testbenches/TierTwo/lsq_tb.sv reference_solutions/TierTwo/lsq.sv
//   $ obj_dir/sim
//
// Final line is exactly one of:
//   TEST_RESULT: PASS
//   TEST_RESULT: FAIL: <reason>
// =============================================================================

`timescale 1ns/1ps
`include "mem_stub.sv"

module lsq_tb;

    // ---------------- configuration ----------------
    parameter int DEPTH               = 16;    // 8 / 16 / 32
    parameter int ADDR_W              = 10;
    parameter int DATA_W              = 32;
    parameter int AGE_W               = 16;
    parameter int RANDOM_CYCLES       = 24000; // >= 10000 required
    parameter int MAX_ERRORS_REPORTED = 20;
    parameter int MEM_MIN_LAT         = 2;
    parameter int MEM_MAX_LAT         = 7;

    localparam int IDX_W = $clog2(DEPTH);

    // ---------------- DUT connections ----------------
    logic                clk = 1'b0;
    logic                rst_n;

    logic                alloc_valid, alloc_is_store, alloc_addr_known;
    logic [IDX_W-1:0]    lsq_idx;

    logic                addr_valid;
    logic [IDX_W-1:0]    addr_lsq_idx;
    logic [ADDR_W-1:0]   addr_value;
    logic [1:0]          addr_size;

    logic                store_data_valid;
    logic [IDX_W-1:0]    store_data_lsq_idx;
    logic [DATA_W-1:0]   store_data_value;

    logic                load_result_valid;
    logic [IDX_W-1:0]    load_result_lsq_idx;
    logic [DATA_W-1:0]   load_result_value;
    logic                load_result_source;

    logic                mem_req_valid, mem_req_we;
    logic [ADDR_W-1:0]   mem_req_addr;
    logic [DATA_W-1:0]   mem_req_wdata;
    logic [1:0]          mem_req_size;
    logic                mem_resp_valid;
    logic [DATA_W-1:0]   mem_resp_rdata;

    logic                store_commit_valid;
    logic [IDX_W-1:0]    store_commit_lsq_idx;

    logic                flush_valid;
    logic [AGE_W-1:0]    flush_age_threshold;

    logic                mem_busy, mem_err_overlap;
    int                  mem_err_count;

    lsq #(.DEPTH(DEPTH), .ADDR_W(ADDR_W), .DATA_W(DATA_W), .AGE_W(AGE_W)) dut (
        .clk(clk), .rst_n(rst_n),
        .alloc_valid(alloc_valid), .alloc_is_store(alloc_is_store),
        .alloc_addr_known(alloc_addr_known), .lsq_idx(lsq_idx),
        .addr_valid(addr_valid), .addr_lsq_idx(addr_lsq_idx),
        .addr_value(addr_value), .addr_size(addr_size),
        .store_data_valid(store_data_valid), .store_data_lsq_idx(store_data_lsq_idx),
        .store_data_value(store_data_value),
        .load_result_valid(load_result_valid), .load_result_lsq_idx(load_result_lsq_idx),
        .load_result_value(load_result_value), .load_result_source(load_result_source),
        .mem_req_valid(mem_req_valid), .mem_req_addr(mem_req_addr),
        .mem_req_we(mem_req_we), .mem_req_wdata(mem_req_wdata),
        .mem_req_size(mem_req_size),
        .mem_resp_valid(mem_resp_valid), .mem_resp_rdata(mem_resp_rdata),
        .store_commit_valid(store_commit_valid), .store_commit_lsq_idx(store_commit_lsq_idx),
        .flush_valid(flush_valid), .flush_age_threshold(flush_age_threshold)
    );

    mem_stub #(.ADDR_W(ADDR_W), .DATA_W(DATA_W),
               .MIN_LAT(MEM_MIN_LAT), .MAX_LAT(MEM_MAX_LAT)) mem (
        .clk(clk), .rst_n(rst_n),
        .req_valid(mem_req_valid), .req_addr(mem_req_addr), .req_we(mem_req_we),
        .req_wdata(mem_req_wdata), .req_size(mem_req_size),
        .resp_valid(mem_resp_valid), .resp_rdata(mem_resp_rdata),
        .busy(mem_busy), .err_overlap(mem_err_overlap), .err_overlap_count(mem_err_count)
    );

    golden_mem #(.ADDR_W(ADDR_W), .DATA_W(DATA_W)) gm ();

    always #5 clk = ~clk;

    // ---------------- bookkeeping ----------------
    int    errors = 0, checks = 0, d_errors = 0, cyc = 0;
    string fail_reason = "";
    string phase = "init";
    string why   = "";        // scratch for composed diagnostics

    task automatic note_fail(input string why);
        errors++;
        if (fail_reason == "") fail_reason = why;
        if (errors <= MAX_ERRORS_REPORTED)
            $display("[FAIL] cyc=%0d t=%0t phase=%s : %s", cyc, $time, phase, why);
        else if (errors == MAX_ERRORS_REPORTED + 1)
            $display("[FAIL] ... further failures suppressed");
    endtask

    localparam int NPOOL = 24;   // 16 word / 4 half / 4 byte
    int pool_addr [0:NPOOL-1];
    int pool_size [0:NPOOL-1];

    logic want_same_cycle_addr;
    int   sc_slot;
    int   obs_lsq_idx;        // lsq_idx sampled at settle, before the edge
    int   last_result_slot;   // slot answered this cycle, -1 if none
    int   last_slot;          // slot the most recent do_alloc landed in
    int   pend_p;             // pool entry planned for the pending allocation
    logic pend_is_store;

    // ---------------- coverage counters ----------------
    // (populated at the events named in each comment)
    int cov_fwd;            // load answered by forwarding
    int cov_memld;          // load answered from memory
    int cov_stall_partial;  // cycles a load was blocked by a partial overlap
    int cov_stall_unknown;  // cycles a load was blocked by an unknown older store
    int cov_stall_nodata;   // cycles a load waited on an exact store's data
    int cov_samecycle_addr; // alloc with alloc_addr_known
    int cov_flush_squash;   // entries squashed by flush
    int cov_flush_midreplay;// flush while a load was blocked
    int cov_stores_written; // stores that reached memory
    int cov_loads_done;     // loads completed

    // =========================================================================
    // Shadow model
    // =========================================================================
    logic        m_val    [DEPTH];
    logic        m_store  [DEPTH];
    logic        m_addr_k [DEPTH];
    int          m_addr   [DEPTH];
    int          m_size   [DEPTH];
    logic        m_data_k [DEPTH];
    logic [31:0] m_data   [DEPTH];
    int          m_age    [DEPTH];
    logic        m_commit [DEPTH];
    logic        m_sent   [DEPTH];
    logic        m_result [DEPTH];   // load already answered (dup detection)
    // Frozen expectation, captured the first cycle a load becomes legally
    // answerable. Necessary because the DUT decides from cycle C-1 state and
    // reports in cycle C: grading against cycle-C state would mis-flag a
    // perfectly legal forward whose source store retired in between. Once a
    // load is answerable its correct value is fixed -- no older store can be
    // added, and the retire rule stops any younger store reaching memory first
    // -- so freezing is sound as well as convenient.
    logic        x_ready  [DEPTH];
    logic [31:0] x_value  [DEPTH];
    logic        x_source [DEPTH];   // 1 = forwarded at freeze time
    int          x_fwdsrc [DEPTH];   // slot forwarded from, -1 if memory
    int          m_wait   [DEPTH];   // cycles since becoming answerable (liveness)

    int age_ctr;
    int live_count;

    // planned (not yet applied) resolution schedule, testbench side
    logic sc_addr_pend [DEPTH];
    int   sc_addr_del  [DEPTH];
    int   sc_addr_val  [DEPTH];
    int   sc_size_val  [DEPTH];
    logic sc_data_pend [DEPTH];
    int   sc_data_del  [DEPTH];
    logic [31:0] sc_data_val [DEPTH];

    task automatic model_reset();
        for (int i = 0; i < DEPTH; i++) begin
            m_val[i]=0; m_addr_k[i]=0; m_data_k[i]=0; m_commit[i]=0;
            m_sent[i]=0; m_result[i]=0; m_wait[i]=0; x_ready[i]=0; x_fwdsrc[i]=-1;
            sc_addr_pend[i]=0; sc_data_pend[i]=0;
        end
        age_ctr = 0; live_count = 0;
    endtask

    function automatic int nbytes(input int s);
        case (s) 0: return 1; 1: return 2; default: return 4; endcase
    endfunction

    function automatic bit ovl(input int a0, input int s0, input int a1, input int s1);
        return (a0 < a1 + nbytes(s1)) && (a1 < a0 + nbytes(s0));
    endfunction

    function automatic bit exact_m(input int a0, input int s0, input int a1, input int s1);
        return (a0 == a1) && (s0 == s1);
    endfunction

    function automatic logic [31:0] zext(input logic [31:0] v, input int s);
        case (s)
            0:       return {24'b0, v[7:0]};
            1:       return {16'b0, v[15:0]};
            default: return v;
        endcase
    endfunction

    // is any older store still in the queue with an unresolved address?
    function automatic bit older_unknown(input int ld);
        for (int j = 0; j < DEPTH; j++)
            if (m_val[j] && m_store[j] && m_age[j] < m_age[ld] && !m_addr_k[j])
                return 1'b1;
        return 1'b0;
    endfunction

    // youngest older store whose range overlaps the load's; -1 if none
    function automatic int nearest_ovl(input int ld);
        int best;
        best = -1;
        for (int j = 0; j < DEPTH; j++)
            if (m_val[j] && m_store[j] && m_addr_k[j] && m_age[j] < m_age[ld]
                && ovl(m_addr[j], m_size[j], m_addr[ld], m_size[ld]))
                if (best < 0 || m_age[j] > m_age[best]) best = j;
        return best;
    endfunction

    // classify a live load right now: 0=not answerable, 1=forwardable, 2=memory
    function automatic int load_state(input int i);
        int s;
        if (!m_val[i] || m_store[i] || !m_addr_k[i]) return 0;
        if (older_unknown(i)) return 0;
        s = nearest_ovl(i);
        if (s < 0) return 2;
        if (exact_m(m_addr[s], m_size[s], m_addr[i], m_size[i]) && m_data_k[s]) return 1;
        return 0;
    endfunction

    // oldest committed store not yet written -- the only one allowed to go next
    function automatic int oldest_undrained();
        int best;
        best = -1;
        for (int i = 0; i < DEPTH; i++)
            if (m_val[i] && m_store[i] && m_commit[i] && !m_sent[i])
                if (best < 0 || m_age[i] < m_age[best]) best = i;
        return best;
    endfunction

    // =========================================================================
    // Checking on observed DUT events
    // =========================================================================
    int  exp_state, nov;
    logic [31:0] exp_val;

    task automatic check_load_result();
        int i, s;
        if (load_result_valid !== 1'b1) return;
        i = int'(load_result_lsq_idx);
        checks++;
        cov_loads_done++;

        if (!m_val[i]) begin
            note_fail($sformatf("load result for slot %0d which is not live (double result or stale)", i));
            return;
        end
        if (m_store[i]) begin
            note_fail($sformatf("load result delivered for slot %0d, which is a STORE", i));
            return;
        end
        if (m_result[i]) begin
            note_fail($sformatf("slot %0d produced a SECOND load result", i));
            return;
        end
        if (!m_addr_k[i]) begin
            note_fail($sformatf("load slot %0d answered before its own address resolved", i));
            return;
        end

        // ---- L1/L3: the load must have been LEGALLY ANSWERABLE before now ----
        // x_ready is frozen from the state the DUT itself decided on, so this
        // grades issue timing rather than whether the value happened to be right.
        if (!x_ready[i]) begin
            s = nearest_ovl(i);
            if (older_unknown(i))
                why = "an older store still has an UNKNOWN address";
            else if (s < 0)
                why = "no blocking store found now, so it was issued before the block cleared";
            else if (exact_m(m_addr[s], m_size[s], m_addr[i], m_size[i]))
                why = $sformatf("exact-match older store slot %0d has no data yet", s);
            else
                why = $sformatf("PARTIAL overlap with older store slot %0d (addr %0d size %0d) still in the queue",
                                s, m_addr[s], m_size[s]);
            note_fail($sformatf("L1/L3 ILLEGAL ISSUE: load slot %0d (age %0d addr %0d size %0d) answered before it was legally answerable -- %s",
                                i, m_age[i], m_addr[i], m_size[i], why));
            return;
        end

        // ---- D1/D2: value and provenance, against the frozen expectation ----
        exp_val   = x_value[i];
        exp_state = x_source[i] ? 1 : 2;

        if (load_result_value !== exp_val)
            note_fail($sformatf("D1 load slot %0d (addr %0d size %0d) value=0x%08h expected 0x%08h (%s)",
                                i, m_addr[i], m_size[i], load_result_value, exp_val,
                                exp_state == 1 ? "forwarded" : "from memory"));

        // A forward that became a memory read because the source store retired
        // in the meantime is legitimate -- the value is identical either way.
        if (load_result_source !== (exp_state == 1 ? 1'b1 : 1'b0)) begin
            if (!(exp_state == 1 && load_result_source === 1'b0
                  && x_fwdsrc[i] >= 0 && !m_val[x_fwdsrc[i]]))
                note_fail($sformatf("D2 load slot %0d source=%0b (says %s) but should be %s",
                                    i, load_result_source,
                                    load_result_source ? "forwarded" : "memory",
                                    exp_state == 1 ? "forwarded" : "memory"));
        end

        if (exp_state == 1) cov_fwd++; else cov_memld++;
    endtask

    // memory request acceptance is observable: valid && !busy at the edge
    task automatic check_mem_request();
        int od, nlegal;
        if (!(mem_req_valid === 1'b1 && mem_busy === 1'b0)) return;
        checks++;
        if (mem_req_we === 1'b1) begin
            // ---- D4: stores drain in program order ----
            od = oldest_undrained();
            if (od < 0) begin
                note_fail("memory WRITE issued with no committed, undrained store in the queue");
                return;
            end
            if (int'(mem_req_addr) != m_addr[od] || int'(mem_req_size) != m_size[od])
                note_fail($sformatf("D4 store write out of order: wrote addr %0d size %0d, but the oldest undrained committed store is slot %0d addr %0d size %0d",
                                    int'(mem_req_addr), int'(mem_req_size), od, m_addr[od], m_size[od]));
            if (mem_req_wdata !== m_data[od])
                note_fail($sformatf("store slot %0d wrote 0x%08h, expected 0x%08h", od, mem_req_wdata, m_data[od]));
        end else begin
            // ---- L2: a read must be on behalf of some genuinely legal load ----
            nlegal = 0;
            for (int i = 0; i < DEPTH; i++)
                if (load_state(i) == 2 && m_addr[i] == int'(mem_req_addr)
                    && m_size[i] == int'(mem_req_size)) nlegal++;
            if (nlegal == 0)
                note_fail($sformatf("L2 ILLEGAL READ: memory read of addr %0d size %0d, but no live load is both legal and memory-bound at that address",
                                    int'(mem_req_addr), int'(mem_req_size)));
        end
    endtask

    // =========================================================================
    // Model advance at the edge, from inputs and observed events
    // =========================================================================
    int mem_txn_owner;     // slot of the in-flight store, -1 if read/none
    logic mem_txn_active;

    task automatic model_update();
        int od, ls, sfz;

        // ---- freeze expectations for loads that just became answerable ----
        // First, before any state moves: m_* here is exactly the state the DUT
        // used to decide the result it will present next cycle.
        for (int i = 0; i < DEPTH; i++) begin
            if (!m_val[i] || m_store[i] || m_result[i] || x_ready[i]) continue;
            ls = load_state(i);
            if (ls == 0) continue;
            x_ready[i] = 1'b1;
            if (ls == 1) begin
                sfz          = nearest_ovl(i);
                x_value[i]   = zext(m_data[sfz], m_size[i]);
                x_source[i]  = 1'b1;
                x_fwdsrc[i]  = sfz;
            end else begin
                x_value[i]   = zext(gm.rd_sized(m_addr[i], m_size[i]), m_size[i]);
                x_source[i]  = 1'b0;
                x_fwdsrc[i]  = -1;
            end
        end

        // ---- coverage on stall reasons, before anything changes ----
        for (int i = 0; i < DEPTH; i++) begin
            if (!m_val[i] || m_store[i] || !m_addr_k[i] || m_result[i]) continue;
            if (older_unknown(i)) cov_stall_unknown++;
            else begin
                ls = nearest_ovl(i);
                if (ls >= 0 && !exact_m(m_addr[ls], m_size[ls], m_addr[i], m_size[i]))
                    cov_stall_partial++;
                else if (ls >= 0 && !m_data_k[ls])
                    cov_stall_nodata++;
            end
            m_wait[i]++;
            if (m_wait[i] == 4000) begin
                int bs;
                bs = nearest_ovl(i);
                if (older_unknown(i))
                    why = "an older store with an unknown address";
                else if (bs < 0)
                    why = "nothing -- it is legal and memory-bound, the DUT is simply not issuing it";
                else if (exact_m(m_addr[bs], m_size[bs], m_addr[i], m_size[i]))
                    why = $sformatf("an exact-match older store (slot %0d) whose data is unresolved", bs);
                else
                    why = $sformatf("a partial-overlap older store (slot %0d addr %0d size %0d commit=%0b sent=%0b) that has not retired",
                                    bs, m_addr[bs], m_size[bs], m_commit[bs], m_sent[bs]);
                note_fail($sformatf("D3 LIVENESS: load slot %0d (age %0d addr %0d size %0d) unanswered for %0d cycles -- blocked by %s",
                                    i, m_age[i], m_addr[i], m_size[i], m_wait[i], why));
            end
        end

        // ---- observed load result frees the slot ----
        if (load_result_valid === 1'b1) begin
            int i;
            i = int'(load_result_lsq_idx);
            if (m_val[i] && !m_store[i]) begin
                m_result[i] = 1'b1;
                m_val[i]    = 1'b0;
                live_count--;
            end
        end

        // ---- observed memory request acceptance ----
        if (mem_req_valid === 1'b1 && mem_busy === 1'b0) begin
            mem_txn_active = 1'b1;
            if (mem_req_we === 1'b1) begin
                od = oldest_undrained();
                mem_txn_owner = od;
                if (od >= 0) begin
                    m_sent[od] = 1'b1;
                    // memory applies the write at accept; keep golden in step
                    gm.wr_sized(m_addr[od], m_size[od], m_data[od]);
                    cov_stores_written++;
                end
            end else begin
                mem_txn_owner = -1;
            end
        end

        // ---- observed memory response frees an in-flight store ----
        if (mem_resp_valid === 1'b1) begin
            if (mem_txn_active && mem_txn_owner >= 0) begin
                if (m_val[mem_txn_owner]) begin
                    m_val[mem_txn_owner] = 1'b0;
                    live_count--;
                end
            end
            mem_txn_active = 1'b0;
            mem_txn_owner  = -1;
        end

        // ---- testbench-driven inputs ----
        if (addr_valid) begin
            m_addr_k[int'(addr_lsq_idx)] = 1'b1;
            m_addr  [int'(addr_lsq_idx)] = int'(addr_value);
            m_size  [int'(addr_lsq_idx)] = int'(addr_size);
        end
        if (store_data_valid) begin
            m_data_k[int'(store_data_lsq_idx)] = 1'b1;
            m_data  [int'(store_data_lsq_idx)] = store_data_value;
        end
        if (store_commit_valid)
            m_commit[int'(store_commit_lsq_idx)] = 1'b1;

        if (alloc_valid) begin
            int i;
            i = obs_lsq_idx;
            if (m_val[i])
                note_fail($sformatf("DUT allocated slot %0d which is already occupied", i));
            m_val[i]    = 1'b1;
            m_store[i]  = alloc_is_store;
            m_age[i]    = age_ctr;
            m_data_k[i] = 1'b0;
            m_commit[i] = 1'b0;
            m_sent[i]   = 1'b0;
            m_result[i] = 1'b0;
            m_wait[i]   = 0;
            x_ready[i]  = 1'b0;
            x_fwdsrc[i] = -1;
            if (alloc_addr_known && addr_valid && int'(addr_lsq_idx) == i) begin
                m_addr_k[i] = 1'b1;
                cov_samecycle_addr++;
            end else begin
                m_addr_k[i] = 1'b0;
            end
            age_ctr++;
            live_count++;
            last_slot = i;
            if (pend_p >= 0) schedule_for_slot(i);
        end

        // ---- flush last: it overrides same-cycle allocation/resolution ----
        if (flush_valid) begin
            for (int i = 0; i < DEPTH; i++)
                if (m_val[i] && m_age[i] > int'(flush_age_threshold)) begin
                    if (m_store[i] && m_sent[i]) continue;   // write already away
                    m_val[i]    = 1'b0;
                    m_addr_k[i] = 1'b0;
                    m_data_k[i] = 1'b0;
                    m_commit[i] = 1'b0;
                    x_ready[i]  = 1'b0;
                    sc_addr_pend[i] = 1'b0;
                    sc_data_pend[i] = 1'b0;
                    live_count--;
                    cov_flush_squash++;
                end
        end
    endtask

    // =========================================================================
    // Cycle
    // =========================================================================

    task automatic step();
        #1;
        obs_lsq_idx     = int'(lsq_idx);
        last_result_slot = -1;
        // same-cycle address supply needs the DUT's combinational lsq_idx first
        if (want_same_cycle_addr && alloc_valid) begin
            sc_slot            = int'(lsq_idx);
            // Take the address straight from the pending pool entry. Reading a
            // per-slot value here would be wrong: the shadow lags the DUT by one
            // cycle on load frees, so a slot the DUT has already freed can still
            // look occupied to the testbench and carry a stale address -- which
            // is exactly how the driven address and the modelled address drifted
            // apart and produced phantom forwarding mismatches.
            if (pend_p >= 0) begin
                sc_addr_val[sc_slot] = pool_addr[pend_p];
                sc_size_val[sc_slot] = pool_size[pend_p];
            end
            addr_valid         = 1'b1;
            addr_lsq_idx       = lsq_idx;
            addr_value         = ADDR_W'(sc_addr_val[sc_slot]);
            addr_size          = 2'(sc_size_val[sc_slot]);
            sc_addr_pend[sc_slot] = 1'b0;
            #1;
        end
        if (load_result_valid === 1'b1) last_result_slot = int'(load_result_lsq_idx);
        check_load_result();
        check_mem_request();
        @(posedge clk);
        model_update();
        cyc++;
        want_same_cycle_addr = 1'b0;
        #1;
    endtask

    task automatic idle_inputs();
        alloc_valid = 0; alloc_is_store = 0; alloc_addr_known = 0;
        addr_valid = 0; addr_lsq_idx = '0; addr_value = '0; addr_size = 2'd2;
        store_data_valid = 0; store_data_lsq_idx = '0; store_data_value = '0;
        store_commit_valid = 0; store_commit_lsq_idx = '0;
        flush_valid = 0; flush_age_threshold = '0;
        want_same_cycle_addr = 0;
    endtask

    task automatic do_reset();
        idle_inputs();
        rst_n = 1'b0;
        repeat (3) @(posedge clk);
        #1;
        if (load_result_valid !== 1'b0) note_fail("load_result_valid set during reset");
        if (mem_req_valid !== 1'b0) note_fail("mem_req_valid set during reset");
        rst_n = 1'b1;
        @(posedge clk);
        model_reset();
        mem_txn_active = 1'b0; mem_txn_owner = -1;
        cyc++;
        #1;
    endtask

    // =========================================================================
    // Address pool -- two tight 16-byte windows so overlap is the norm
    // =========================================================================

    task automatic build_pool();
        int k, base;
        k = 0;
        for (int w = 0; w < 2; w++) begin
            base = (w == 0) ? 0 : 64;
            // Word entries dominate: they exact-match each other (forwarding)
            // and never partially overlap each other. The sub-word minority is
            // what manufactures partial overlaps -- enough to hit the hazard
            // constantly, not so many that every load stalls behind a retire
            // and the queue stops flowing.
            for (int i = 0; i < 4; i++) begin pool_addr[k]=base+i*4;   pool_size[k]=2; k++; end
            for (int i = 0; i < 4; i++) begin pool_addr[k]=base+i*4;   pool_size[k]=2; k++; end
            for (int i = 0; i < 2; i++) begin pool_addr[k]=base+i*4+2; pool_size[k]=1; k++; end
            for (int i = 0; i < 2; i++) begin pool_addr[k]=base+i*4+1; pool_size[k]=0; k++; end
        end
    endtask

    // resolution delay; the long tail is what makes L1 bite
    function automatic int addr_delay();
        int r;
        r = $urandom_range(0, 99);
        if (r < 45) return $urandom_range(0, 2);
        if (r < 85) return $urandom_range(3, 12);
        return $urandom_range(15, 45);
    endfunction

    // install the resolution schedule for a slot the DUT just allocated
    task automatic schedule_for_slot(input int i);
        sc_addr_val[i] = pool_addr[pend_p];
        sc_size_val[i] = pool_size[pend_p];
        if (m_addr_k[i]) begin                    // supplied same-cycle
            m_addr[i] = pool_addr[pend_p];
            m_size[i] = pool_size[pend_p];
        end else begin
            sc_addr_pend[i] = 1'b1;
            sc_addr_del[i]  = addr_delay();
        end
        if (pend_is_store) begin
            sc_data_pend[i] = 1'b1;
            sc_data_del[i]  = $urandom_range(0, 10);
            sc_data_val[i]  = 32'($urandom());
        end
        pend_p = -1;
    endtask

    // A store may retire only when its address and data are known, every older
    // store has already retired, and every older LOAD has already been answered.
    // That last clause is what a real in-order retire guarantees, and it is what
    // makes the golden memory a well-defined reference: no younger store can
    // reach memory ahead of an older load's read.
    function automatic bit commitable(input int i);
        if (!m_val[i] || !m_store[i] || m_commit[i]) return 1'b0;
        if (!m_addr_k[i] || !m_data_k[i]) return 1'b0;
        for (int j = 0; j < DEPTH; j++) begin
            if (!m_val[j] || m_age[j] >= m_age[i]) continue;
            if (m_store[j] && !m_commit[j]) return 1'b0;
            if (!m_store[j])                return 1'b0;
        end
        return 1'b1;
    endfunction

    // =========================================================================
    // Directed primitives
    // =========================================================================
    task automatic idle_steps(input int n);
        for (int k = 0; k < n; k++) begin idle_inputs(); step(); end
    endtask

    task automatic do_alloc(input bit is_store, input int a, input int sz,
                            input logic [31:0] d);
        idle_inputs();
        alloc_valid    = 1'b1;
        alloc_is_store = is_store;
        pend_p         = -1;              // directed tests set state explicitly
        pend_is_store  = is_store;
        step();
        // model_update recorded the slot in last_slot; fill its plan by hand
        sc_addr_val[last_slot] = a;
        sc_size_val[last_slot] = sz;
        sc_data_val[last_slot] = d;
    endtask

    task automatic do_addr(input int slot, input int a, input int sz);
        idle_inputs();
        addr_valid = 1'b1; addr_lsq_idx = IDX_W'(slot);
        addr_value = ADDR_W'(a); addr_size = 2'(sz);
        step();
    endtask

    task automatic do_sdata(input int slot, input logic [31:0] d);
        idle_inputs();
        store_data_valid = 1'b1; store_data_lsq_idx = IDX_W'(slot);
        store_data_value = d;
        step();
    endtask

    task automatic do_commit_slot(input int slot);
        idle_inputs();
        store_commit_valid = 1'b1; store_commit_lsq_idx = IDX_W'(slot);
        step();
    endtask

    // step until the named load answers, or give up
    task automatic await_load(input int slot, input int maxc, input string ctx);
        int k;
        k = 0;
        while (m_val[slot] && k < maxc) begin idle_inputs(); step(); k++; end
        if (m_val[slot])
            note_fail($sformatf("%s: load slot %0d never produced a result in %0d cycles",
                                ctx, slot, maxc));
    endtask

    // step until nothing is live, or give up
    task automatic drain(input string ctx);
        int k;
        k = 0;
        while (live_count > 0 && k < 400*DEPTH) begin
            drive_resolutions_and_commits();
            step();
            k++;
        end
        idle_inputs();
        if (live_count > 0)
            note_fail($sformatf("%s: queue failed to drain in %0d cycles (%0d entries live)",
                                ctx, k, live_count));
    endtask

    // drive only the pending resolutions and one eligible commit (no new allocs)
    task automatic drive_resolutions_and_commits();
        int cand;
        idle_inputs();
        for (int i = 0; i < DEPTH; i++)
            if (sc_addr_pend[i] && m_val[i]) begin
                if (sc_addr_del[i] > 0) sc_addr_del[i]--;
                else if (!addr_valid) begin
                    addr_valid   = 1'b1; addr_lsq_idx = IDX_W'(i);
                    addr_value   = ADDR_W'(sc_addr_val[i]); addr_size = 2'(sc_size_val[i]);
                    sc_addr_pend[i] = 1'b0;
                end
            end
        for (int i = 0; i < DEPTH; i++)
            if (sc_data_pend[i] && m_val[i]) begin
                if (sc_data_del[i] > 0) sc_data_del[i]--;
                else if (!store_data_valid) begin
                    store_data_valid   = 1'b1; store_data_lsq_idx = IDX_W'(i);
                    store_data_value   = sc_data_val[i];
                    sc_data_pend[i]    = 1'b0;
                end
            end
        cand = -1;
        for (int i = 0; i < DEPTH; i++)
            if (commitable(i) && (cand < 0 || m_age[i] < m_age[cand])) cand = i;
        if (cand >= 0) begin
            store_commit_valid   = 1'b1;
            store_commit_lsq_idx = IDX_W'(cand);
        end
    endtask

    // =========================================================================
    // Directed corner-case suite
    // =========================================================================
    task automatic directed_suite();
        int st, ld, st2, ld2;

        // ---- C1: exact-match forward from an in-flight (uncommitted) store ----
        phase = "C1-exact-forward";
        do_reset();
        do_alloc(1'b1, 16, 2, 32'hAABBCCDD); st = last_slot;
        do_addr(st, 16, 2);
        do_sdata(st, 32'hAABBCCDD);
        do_alloc(1'b0, 16, 2, 32'h0);        ld = last_slot;
        do_addr(ld, 16, 2);
        await_load(ld, 60, "C1");
        drain("C1");

        // ---- C2: partial overlap must STALL until the store retires ----
        phase = "C2-partial-overlap-stall";
        do_reset();
        do_alloc(1'b1, 16, 2, 32'h11223344); st = last_slot;   // word at 16
        do_addr(st, 16, 2);
        do_sdata(st, 32'h11223344);
        do_alloc(1'b0, 18, 1, 32'h0);        ld = last_slot;   // half at 18: partial
        do_addr(ld, 18, 1);
        idle_steps(25);
        if (!m_val[ld])
            note_fail("C2: load answered despite a partial overlap with a live older store");
        // retiring the store unblocks it
        do_commit_slot(st);
        await_load(ld, 120, "C2");
        drain("C2");

        // ---- C3: older store with an UNKNOWN address blocks the load ----
        phase = "C3-unknown-older-store";
        do_reset();
        do_alloc(1'b1, 64, 2, 32'hDEADBEEF); st = last_slot;   // address withheld
        do_alloc(1'b0, 0,  2, 32'h0);        ld = last_slot;   // disjoint address
        do_addr(ld, 0, 2);
        idle_steps(30);
        if (!m_val[ld])
            note_fail("C3: load answered while an older store's address was still unknown");
        do_addr(st, 64, 2);                                    // now it resolves
        do_sdata(st, 32'hDEADBEEF);
        await_load(ld, 120, "C3");
        drain("C3");

        // ---- C4: two stores to the same address, forward from the NEAREST ----
        phase = "C4-nearest-older-store";
        do_reset();
        do_alloc(1'b1, 32, 2, 32'h11111111); st  = last_slot;
        do_addr(st, 32, 2);  do_sdata(st, 32'h11111111);
        do_alloc(1'b1, 32, 2, 32'h22222222); st2 = last_slot;  // younger, same addr
        do_addr(st2, 32, 2); do_sdata(st2, 32'h22222222);
        do_alloc(1'b0, 32, 2, 32'h0);        ld  = last_slot;
        do_addr(ld, 32, 2);
        await_load(ld, 60, "C4");            // must see 0x22222222, checked in D1
        drain("C4");

        // ---- C5: exact match whose DATA is not yet resolved must stall ----
        phase = "C5-exact-no-data";
        do_reset();
        do_alloc(1'b1, 8, 2, 32'h5A5A5A5A); st = last_slot;
        do_addr(st, 8, 2);                                     // address only
        do_alloc(1'b0, 8, 2, 32'h0);        ld = last_slot;
        do_addr(ld, 8, 2);
        idle_steps(20);
        if (!m_val[ld])
            note_fail("C5: load forwarded from a store whose data was not resolved");
        do_sdata(st, 32'h5A5A5A5A);
        await_load(ld, 60, "C5");
        drain("C5");

        // ---- C6: same-cycle alloc + address (alloc_addr_known) ----
        phase = "C6-same-cycle-addr";
        do_reset();
        idle_inputs();
        alloc_valid = 1'b1; alloc_is_store = 1'b0; alloc_addr_known = 1'b1;
        pend_p = -1; pend_is_store = 1'b0;
        want_same_cycle_addr = 1'b1;
        sc_addr_val[0]=0; sc_size_val[0]=2;
        for (int i = 0; i < DEPTH; i++) begin sc_addr_val[i]=0; sc_size_val[i]=2; end
        step();
        ld = last_slot;
        if (!m_addr_k[ld])
            note_fail("C6: alloc_addr_known entry did not end the cycle address-resolved");
        await_load(ld, 60, "C6");
        drain("C6");

        // ---- C7: flush while a load is blocked mid-replay ----
        phase = "C7-flush-mid-replay";
        do_reset();
        do_alloc(1'b1, 16, 2, 32'h9); st = last_slot;
        do_addr(st, 16, 2); do_sdata(st, 32'h9);
        do_alloc(1'b0, 18, 1, 32'h0); ld = last_slot;          // partial -> stalls
        do_addr(ld, 18, 1);
        idle_steps(6);
        idle_inputs();
        flush_valid = 1'b1; flush_age_threshold = AGE_W'(m_age[st]);  // squash the load
        step();
        idle_steps(4);
        if (m_val[ld]) note_fail("C7: flush did not squash the blocked younger load");
        drain("C7");
    endtask

    // =========================================================================
    // Randomized suite
    // =========================================================================
    task automatic random_suite();
        int oldest_age, cand, p;
        phase = "R1-random";
        do_reset();
        for (int v = 0; v < RANDOM_CYCLES; v++) begin
            drive_resolutions_and_commits();     // sets idle_inputs() first

            // allocate
            if (live_count < DEPTH - 1 && $urandom_range(0, 9) < 6) begin
                p = $urandom_range(0, NPOOL-1);
                alloc_valid    = 1'b1;
                alloc_is_store = ($urandom_range(0, 9) < 3);
                pend_p         = p;
                pend_is_store  = alloc_is_store;
                // Only claim the address channel for a same-cycle supply if it
                // is still free this cycle. Otherwise step() would overwrite a
                // resolution that drive_resolutions_and_commits() has already
                // marked delivered, and that entry's address would never arrive.
                if (!addr_valid && $urandom_range(0, 9) == 0) begin
                    alloc_addr_known     = 1'b1;
                    want_same_cycle_addr = 1'b1;
                end
            end

            // flush occasionally, keeping a couple of the oldest entries
            if ($urandom_range(0, 299) == 0 && live_count > 2) begin
                // Threshold floor: never squash a store the testbench has
                // already committed -- the interface promises that, and a
                // squashed-after-commit store has undefined memory semantics.
                oldest_age = 1 << 30;
                for (int i = 0; i < DEPTH; i++)
                    if (m_val[i] && m_age[i] < oldest_age) oldest_age = m_age[i];
                for (int i = 0; i < DEPTH; i++)
                    if (m_val[i] && m_store[i] && m_commit[i] && m_age[i] > oldest_age)
                        oldest_age = m_age[i];
                for (int i = 0; i < DEPTH; i++)
                    if (m_val[i] && !m_store[i] && m_addr_k[i] && load_state(i) == 0)
                        cov_flush_midreplay++;
                flush_valid         = 1'b1;
                flush_age_threshold = AGE_W'(oldest_age + $urandom_range(0, 3));
                alloc_valid         = 1'b0;   // do not allocate into a flush cycle
                want_same_cycle_addr = 1'b0;
            end

            step();
        end
        drain("R1");
    endtask

    // =========================================================================
    // End-of-test checks
    // =========================================================================
    task automatic final_checks();
        int bad;
        phase = "final";
        checks++;
        if (mem_err_overlap === 1'b1)
            note_fail($sformatf("single-outstanding memory contract violated %0d times", mem_err_count));
        if (live_count != 0)
            note_fail($sformatf("%0d entries still live at end of test", live_count));
        bad = 0;
        for (int a = 0; a < (1 << ADDR_W); a++)
            if (mem.peek_byte(a) !== gm.rd_byte(a)) bad++;
        checks++;
        if (bad != 0)
            note_fail($sformatf("D4 final memory image differs from the golden model in %0d bytes", bad));
    endtask

    // =========================================================================
    // Report
    // =========================================================================
    task automatic report();
        int cov_missing;
        $display("// ---- functional coverage ----");
        $display("//   loads answered: forwarded=%0d from-memory=%0d", cov_fwd, cov_memld);
        $display("//   load-cycles stalled by: unknown older store=%0d partial overlap=%0d awaiting store data=%0d",
                 cov_stall_unknown, cov_stall_partial, cov_stall_nodata);
        $display("//   same-cycle alloc+addr=%0d", cov_samecycle_addr);
        $display("//   flush: entries squashed=%0d squashed while blocked=%0d",
                 cov_flush_squash, cov_flush_midreplay);
        $display("//   stores written to memory=%0d  loads completed=%0d",
                 cov_stores_written, cov_loads_done);

        cov_missing = 0;
        if (cov_fwd            == 0) begin cov_missing++; $display("// COVERAGE HOLE: no load was ever forwarded"); end
        if (cov_memld          == 0) begin cov_missing++; $display("// COVERAGE HOLE: no load ever read memory"); end
        if (cov_stall_unknown  == 0) begin cov_missing++; $display("// COVERAGE HOLE: no load ever blocked on an unknown older store"); end
        if (cov_stall_partial  == 0) begin cov_missing++; $display("// COVERAGE HOLE: no partial-overlap stall"); end
        if (cov_stall_nodata   == 0) begin cov_missing++; $display("// COVERAGE HOLE: no wait on unresolved store data"); end
        if (cov_samecycle_addr == 0) begin cov_missing++; $display("// COVERAGE HOLE: alloc_addr_known never exercised"); end
        if (cov_flush_squash   == 0) begin cov_missing++; $display("// COVERAGE HOLE: flush never squashed anything"); end
        if (cov_stores_written == 0) begin cov_missing++; $display("// COVERAGE HOLE: no store reached memory"); end
        if (cov_missing > 0)
            note_fail($sformatf("%0d coverage holes -- the run did not exercise the target hazards", cov_missing));

        if (checks < 5000)
            note_fail($sformatf("insufficient coverage: only %0d graded events", checks));

        if (errors == 0) begin
            $display("// info: %0d graded events, %0d loads, %0d stores written",
                     checks, cov_loads_done, cov_stores_written);
            $display("TEST_RESULT: PASS");
        end else
            $display("TEST_RESULT: FAIL: %s (%0d failing checks of %0d; directed=%0d randomized=%0d)",
                     fail_reason, errors, checks, d_errors, errors - d_errors);
    endtask



    // =========================================================================
    // Main
    // =========================================================================
    initial begin
        if (DEPTH < 8 || (DEPTH & (DEPTH-1)) != 0) begin
            $display("TEST_RESULT: FAIL: illegal DEPTH=%0d (must be a power of 2, >= 8)", DEPTH);
            $finish;
        end
        if (RANDOM_CYCLES < 10000) begin
            $display("TEST_RESULT: FAIL: RANDOM_CYCLES=%0d below the required 10000", RANDOM_CYCLES);
            $finish;
        end

        cov_fwd=0; cov_memld=0; cov_stall_partial=0; cov_stall_unknown=0;
        cov_stall_nodata=0; cov_samecycle_addr=0; cov_flush_squash=0;
        cov_flush_midreplay=0; cov_stores_written=0; cov_loads_done=0;
        pend_p = -1; pend_is_store = 1'b0; last_slot = 0;

        build_pool();
        gm.init_pattern(7);
        mem.init_pattern(7);
        model_reset();
        mem_txn_active = 1'b0; mem_txn_owner = -1;

        directed_suite();
        d_errors = errors;
        $display("// directed suite: %0d checks, %0d failing", checks, d_errors);

        random_suite();
        $display("// randomized suite: %0d cycles, %0d failing checks",
                 RANDOM_CYCLES, errors - d_errors);

        final_checks();
        report();
        $finish;
    end

    initial begin
        #(40 * 10 * (RANDOM_CYCLES + 4000));
        $display("// timeout state: phase=%s cyc=%0d live=%0d checks=%0d",
                 phase, cyc, live_count, checks);
        $display("TEST_RESULT: FAIL: timeout -- testbench did not complete (phase %s)", phase);
        $finish;
    end

endmodule
