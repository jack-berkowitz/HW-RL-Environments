// =============================================================================
// lsq.sv
// =============================================================================
// Load / Store Queue
//
//   - One allocation per cycle
//   - Loads issue out of order
//   - Conservative memory disambiguation
//   - Exact-match store-to-load forwarding
//   - Partial-overlap stalls
//   - One outstanding memory transaction
//   - Stores retire to memory in program order
//   - Flush support
// =============================================================================

module lsq #(
    parameter int DEPTH  = 16,
    parameter int ADDR_W = 10,
    parameter int DATA_W = 32,
    parameter int AGE_W  = 16,
    parameter int IDX_W  = $clog2(DEPTH)
) (
    input  logic                clk,
    input  logic                rst_n,

    // ---- allocate ----
    input  logic                alloc_valid,
    input  logic                alloc_is_store,
    input  logic                alloc_addr_known,
    output logic [IDX_W-1:0]    lsq_idx,

    // ---- address resolution ----
    input  logic                addr_valid,
    input  logic [IDX_W-1:0]    addr_lsq_idx,
    input  logic [ADDR_W-1:0]   addr_value,
    input  logic [1:0]          addr_size,

    // ---- store data resolution ----
    input  logic                store_data_valid,
    input  logic [IDX_W-1:0]    store_data_lsq_idx,
    input  logic [DATA_W-1:0]   store_data_value,

    // ---- load result ----
    output logic                load_result_valid,
    output logic [IDX_W-1:0]    load_result_lsq_idx,
    output logic [DATA_W-1:0]   load_result_value,
    output logic                load_result_source,

    // ---- memory interface ----
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

    // =========================================================================
    // ENTRY
    // =========================================================================

    typedef struct packed {
        logic                    allocated;
        logic                    is_store;

        logic [AGE_W-1:0]        age;

        logic                    addr_known;
        logic [ADDR_W-1:0]       addr;
        logic [1:0]              size;

        logic                    data_known;
        logic [DATA_W-1:0]       data;

        logic                    store_committed;

        logic                    load_inflight;
        logic                    load_done;
    } lsq_entry_t;

    lsq_entry_t entries [0:DEPTH-1];

    logic [AGE_W-1:0] next_age;

    // =========================================================================
    // MEMORY TRANSACTION
    // =========================================================================

    logic             mem_busy;
    logic             mem_busy_is_store;
    logic [IDX_W-1:0] mem_busy_lsq_idx;

    // =========================================================================
    // ALLOCATION
    // =========================================================================

    logic             alloc_slot_found;
    logic [IDX_W-1:0] alloc_slot;

    // =========================================================================
    // LOAD CANDIDATE
    // =========================================================================

    logic             load_found;
    logic [IDX_W-1:0] load_issue_idx;
    logic [AGE_W-1:0] load_issue_age;

    logic             load_issue_forward;
    logic [DATA_W-1:0] load_forward_value;

    // =========================================================================
    // STORE CANDIDATE
    // =========================================================================

    logic             store_found;
    logic [IDX_W-1:0] store_issue_idx;
    logic [AGE_W-1:0] store_issue_age;

    // =========================================================================
    // HELPERS
    // =========================================================================

    function automatic int unsigned size_bytes(
        input logic [1:0] size
    );
        case (size)
            2'b00: size_bytes = 1;
            2'b01: size_bytes = 2;
            2'b10: size_bytes = 4;
            default: size_bytes = 1;
        endcase
    endfunction


    function automatic logic ranges_overlap(
        input logic [ADDR_W-1:0] a_addr,
        input logic [1:0]        a_size,
        input logic [ADDR_W-1:0] b_addr,
        input logic [1:0]        b_size
    );

        logic [ADDR_W:0] a_start;
        logic [ADDR_W:0] a_end;
        logic [ADDR_W:0] b_start;
        logic [ADDR_W:0] b_end;

        begin
            a_start = {1'b0, a_addr};
            b_start = {1'b0, b_addr};

            a_end = a_start + size_bytes(a_size);
            b_end = b_start + size_bytes(b_size);

            ranges_overlap =
                (a_start < b_end) &&
                (b_start < a_end);
        end
    endfunction


    function automatic logic exact_match(
        input logic [ADDR_W-1:0] a_addr,
        input logic [1:0]        a_size,
        input logic [ADDR_W-1:0] b_addr,
        input logic [1:0]        b_size
    );
        begin
            exact_match =
                (a_addr == b_addr) &&
                (a_size == b_size);
        end
    endfunction


    function automatic logic [DATA_W-1:0] zero_extend_data(
        input logic [DATA_W-1:0] value,
        input logic [1:0]        size
    );
        begin
            case (size)
                2'b00:
                    zero_extend_data =
                        {{(DATA_W-8){1'b0}}, value[7:0]};

                2'b01:
                    zero_extend_data =
                        {{(DATA_W-16){1'b0}}, value[15:0]};

                2'b10:
                    zero_extend_data = value;

                default:
                    zero_extend_data = '0;
            endcase
        end
    endfunction


    // =========================================================================
    // COMBINATIONAL ALLOCATION SLOT
    // =========================================================================
    //
    // LSQ slots are reusable. Program ordering comes from age, NOT slot number.
    // =========================================================================

    always_comb begin
        alloc_slot_found = 1'b0;
        alloc_slot       = '0;

        for (int i = 0; i < DEPTH; i++) begin
            if (!alloc_slot_found && !entries[i].allocated) begin
                alloc_slot_found = 1'b1;
                alloc_slot       = i[IDX_W-1:0];
            end
        end

        lsq_idx = alloc_slot;
    end


    // =========================================================================
    // LOAD SELECTION
    // =========================================================================
    //
    // Find the oldest legal load.
    //
    // Every older store:
    //   - unknown address -> blocks
    //
    // Youngest older overlapping store:
    //   - exact + data ready -> forward
    //   - exact + data unavailable -> block
    //   - partial overlap -> block
    //
    // This follows the conservative rule in the specification. 
    // =========================================================================

    always_comb begin

        load_found         = 1'b0;
        load_issue_idx     = '0;
        load_issue_age     = '0;
        load_issue_forward = 1'b0;
        load_forward_value = '0;

        if (!mem_busy) begin

            for (int l = 0; l < DEPTH; l++) begin

                if (entries[l].allocated &&
                    !entries[l].is_store &&
                    entries[l].addr_known &&
                    !entries[l].load_inflight &&
                    !entries[l].load_done) begin

                    logic blocked;
                    logic overlap_found;

                    logic [IDX_W-1:0] nearest_store;
                    logic [AGE_W-1:0] nearest_store_age;
                    logic candidate_forward;
                    logic [DATA_W-1:0] candidate_value;

                    blocked           = 1'b0;
                    overlap_found     = 1'b0;
                    nearest_store     = '0;
                    nearest_store_age = '0;

                    // ---------------------------------------------------------
                    // Find older stores.
                    // ---------------------------------------------------------

                    for (int s = 0; s < DEPTH; s++) begin

                        if (entries[s].allocated &&
                            entries[s].is_store &&
                            (entries[s].age < entries[l].age)) begin

                            // Any older unresolved store address blocks.
                            if (!entries[s].addr_known) begin
                                blocked = 1'b1;
                            end

                            else if (ranges_overlap(
                                entries[s].addr,
                                entries[s].size,
                                entries[l].addr,
                                entries[l].size
                            )) begin

                                // Youngest older overlapping store.
                                if (!overlap_found ||
                                    entries[s].age > nearest_store_age) begin

                                    overlap_found     = 1'b1;
                                    nearest_store     = s[IDX_W-1:0];
                                    nearest_store_age = entries[s].age;
                                end
                            end
                        end
                    end

                    candidate_forward = 1'b0;
                    candidate_value   = '0;

                    if (overlap_found && !blocked) begin

                        if (exact_match(
                            entries[nearest_store].addr,
                            entries[nearest_store].size,
                            entries[l].addr,
                            entries[l].size
                        )) begin

                            if (entries[nearest_store].data_known) begin
                                candidate_forward = 1'b1;

                                candidate_value =
                                    zero_extend_data(
                                        entries[nearest_store].data,
                                        entries[l].size
                                    );
                            end
                            else begin
                                blocked = 1'b1;
                            end
                        end
                        else begin
                            // Partial overlap must wait until store leaves.
                            blocked = 1'b1;
                        end
                    end

                    if (!blocked) begin

                        if (!load_found ||
                            entries[l].age < load_issue_age) begin

                            load_found         = 1'b1;
                            load_issue_idx     = l[IDX_W-1:0];
                            load_issue_age     = entries[l].age;
                            load_issue_forward = candidate_forward;
                            load_forward_value = candidate_value;
                        end
                    end
                end
            end
        end
    end


    // =========================================================================
    // STORE SELECTION
    // =========================================================================
    //
    // Only committed stores may reach memory.
    //
    // Among committed stores, oldest age wins.
    // =========================================================================

    always_comb begin

        store_found     = 1'b0;
        store_issue_idx = '0;
        store_issue_age = '0;

        if (!mem_busy) begin

            for (int s = 0; s < DEPTH; s++) begin

                if (entries[s].allocated &&
                    entries[s].is_store &&
                    entries[s].store_committed &&
                    entries[s].addr_known &&
                    entries[s].data_known) begin

                    if (!store_found ||
                        entries[s].age < store_issue_age) begin

                        store_found     = 1'b1;
                        store_issue_idx = s[IDX_W-1:0];
                        store_issue_age = entries[s].age;
                    end
                end
            end
        end
    end


    // =========================================================================
    // SEQUENTIAL LOGIC
    // =========================================================================

    always_ff @(posedge clk) begin

        if (!rst_n) begin

            next_age <= '0;

            mem_busy          <= 1'b0;
            mem_busy_is_store <= 1'b0;
            mem_busy_lsq_idx  <= '0;

            load_result_valid   <= 1'b0;
            load_result_lsq_idx <= '0;
            load_result_value   <= '0;
            load_result_source  <= 1'b0;

            mem_req_valid <= 1'b0;
            mem_req_addr  <= '0;
            mem_req_we    <= 1'b0;
            mem_req_wdata <= '0;
            mem_req_size  <= '0;

            for (int i = 0; i < DEPTH; i++) begin

                entries[i].allocated       <= 1'b0;
                entries[i].is_store        <= 1'b0;

                entries[i].age             <= '0;

                entries[i].addr_known      <= 1'b0;
                entries[i].addr            <= '0;
                entries[i].size            <= '0;

                entries[i].data_known      <= 1'b0;
                entries[i].data            <= '0;

                entries[i].store_committed <= 1'b0;

                entries[i].load_inflight   <= 1'b0;
                entries[i].load_done       <= 1'b0;
            end
        end

        else begin

            // =================================================================
            // DEFAULT ONE-CYCLE OUTPUTS
            // =================================================================

            load_result_valid <= 1'b0;
            mem_req_valid     <= 1'b0;


            // =================================================================
            // 1. ADDRESS RESOLUTION
            // =================================================================

            if (addr_valid &&
                entries[addr_lsq_idx].allocated) begin

                entries[addr_lsq_idx].addr_known <= 1'b1;
                entries[addr_lsq_idx].addr       <= addr_value;
                entries[addr_lsq_idx].size       <= addr_size;
            end


            // =================================================================
            // 2. STORE DATA RESOLUTION
            // =================================================================

            if (store_data_valid &&
                entries[store_data_lsq_idx].allocated &&
                entries[store_data_lsq_idx].is_store) begin

                entries[store_data_lsq_idx].data_known <= 1'b1;
                entries[store_data_lsq_idx].data       <= store_data_value;
            end


            // =================================================================
            // 3. STORE COMMIT
            // =================================================================

            if (store_commit_valid &&
                entries[store_commit_lsq_idx].allocated &&
                entries[store_commit_lsq_idx].is_store) begin

                entries[store_commit_lsq_idx].store_committed <= 1'b1;
            end


            // =================================================================
            // 4. MEMORY RESPONSE
            // =================================================================
            //
            // A transaction that has already been accepted cannot be recalled
            // by a later flush.
            // =================================================================

            if (mem_resp_valid && mem_busy) begin

                if (mem_busy_is_store) begin

                    // ---------------------------------------------------------
                    // STORE WRITE COMPLETED
                    // ---------------------------------------------------------

                    if (entries[mem_busy_lsq_idx].allocated) begin
                        entries[mem_busy_lsq_idx].allocated <= 1'b0;
                    end

                end
                else begin

                    // ---------------------------------------------------------
                    // LOAD READ COMPLETED
                    // ---------------------------------------------------------

                    // Flush wins if it squashes this load in the same cycle.
                    if (entries[mem_busy_lsq_idx].allocated &&
                        !(flush_valid &&
                          (entries[mem_busy_lsq_idx].age >
                           flush_age_threshold))) begin

                        load_result_valid   <= 1'b1;
                        load_result_lsq_idx <= mem_busy_lsq_idx;
                        load_result_value   <=
                            zero_extend_data(
                                mem_resp_rdata,
                                entries[mem_busy_lsq_idx].size
                            );
                        load_result_source  <= 1'b0;

                        entries[mem_busy_lsq_idx].allocated     <= 1'b0;
                        entries[mem_busy_lsq_idx].load_inflight <= 1'b0;
                        entries[mem_busy_lsq_idx].load_done     <= 1'b1;

                    end
                    else begin

                        // Squashed load.
                        if (entries[mem_busy_lsq_idx].allocated) begin
                            entries[mem_busy_lsq_idx].allocated     <= 1'b0;
                            entries[mem_busy_lsq_idx].load_inflight <= 1'b0;
                            entries[mem_busy_lsq_idx].load_done     <= 1'b0;
                        end
                    end
                end

                mem_busy <= 1'b0;
            end


            // =================================================================
            // 5. FLUSH
            // =================================================================
            //
            // Do not squash an already accepted memory transaction.
            //
            // For everything else, age > threshold is squashed.
            // =================================================================

            if (flush_valid) begin

                for (int f = 0; f < DEPTH; f++) begin

                    if (entries[f].allocated &&
                        (entries[f].age > flush_age_threshold) &&
                        !(mem_busy &&
                          (mem_busy_lsq_idx == f[IDX_W-1:0]))) begin

                        entries[f].allocated     <= 1'b0;
                        entries[f].load_inflight <= 1'b0;
                        entries[f].load_done     <= 1'b0;
                    end
                end
            end


            // =================================================================
            // 6. MEMORY ARBITRATION
            // =================================================================
            //
            // IMPORTANT:
            //
            // This MUST be one mutually-exclusive decision.
            //
            // The previous implementation had independent load/store "if"
            // statements. Both observed the same old mem_busy value and could
            // therefore launch two transactions in one cycle.
            //
            // Priority:
            //   1. forwarded load (doesn't consume memory)
            //   2. legal load memory request
            //   3. committed store memory request
            //
            // Exactly one memory transaction can therefore be launched.
            // =================================================================

            if (!mem_busy) begin

                // -------------------------------------------------------------
                // 6A. FORWARDED LOAD
                // -------------------------------------------------------------

                if (load_found && load_issue_forward) begin

                    // Flush wins in the same cycle.
                    if (entries[load_issue_idx].allocated &&
                        !(flush_valid &&
                          (entries[load_issue_idx].age >
                           flush_age_threshold))) begin

                        load_result_valid   <= 1'b1;
                        load_result_lsq_idx <= load_issue_idx;
                        load_result_value   <= load_forward_value;
                        load_result_source  <= 1'b1;

                        entries[load_issue_idx].allocated <= 1'b0;
                        entries[load_issue_idx].load_done <= 1'b1;
                    end
                    else if (entries[load_issue_idx].allocated) begin

                        entries[load_issue_idx].allocated <= 1'b0;
                        entries[load_issue_idx].load_done <= 1'b0;
                    end
                end

                // -------------------------------------------------------------
                // 6B. LOAD MEMORY REQUEST
                // -------------------------------------------------------------

                else if (load_found && !load_issue_forward) begin

                    if (entries[load_issue_idx].allocated &&
                        !(flush_valid &&
                          (entries[load_issue_idx].age >
                           flush_age_threshold))) begin

                        mem_req_valid <= 1'b1;
                        mem_req_addr  <= entries[load_issue_idx].addr;
                        mem_req_we    <= 1'b0;
                        mem_req_wdata <= '0;
                        mem_req_size  <= entries[load_issue_idx].size;

                        mem_busy          <= 1'b1;
                        mem_busy_is_store <= 1'b0;
                        mem_busy_lsq_idx  <= load_issue_idx;

                        entries[load_issue_idx].load_inflight <= 1'b1;
                    end
                end

                // -------------------------------------------------------------
                // 6C. STORE MEMORY REQUEST
                // -------------------------------------------------------------

                else if (store_found) begin

                    if (entries[store_issue_idx].allocated &&
                        !(flush_valid &&
                          (entries[store_issue_idx].age >
                           flush_age_threshold))) begin

                        mem_req_valid <= 1'b1;
                        mem_req_addr  <= entries[store_issue_idx].addr;
                        mem_req_we    <= 1'b1;
                        mem_req_wdata <= entries[store_issue_idx].data;
                        mem_req_size  <= entries[store_issue_idx].size;

                        mem_busy          <= 1'b1;
                        mem_busy_is_store <= 1'b1;
                        mem_busy_lsq_idx  <= store_issue_idx;
                    end
                end
            end


            // =================================================================
            // 7. ALLOCATION
            // =================================================================
            //
            // The combinational lsq_idx is guaranteed to point at a free slot
            // at the beginning of this cycle.
            // =================================================================

            if (alloc_valid && alloc_slot_found) begin

                entries[alloc_slot].allocated       <= 1'b1;
                entries[alloc_slot].is_store        <= alloc_is_store;

                entries[alloc_slot].age             <= next_age;

                entries[alloc_slot].addr_known      <= 1'b0;
                entries[alloc_slot].addr            <= '0;
                entries[alloc_slot].size            <= '0;

                entries[alloc_slot].data_known      <= 1'b0;
                entries[alloc_slot].data            <= '0;

                entries[alloc_slot].store_committed <= 1'b0;

                entries[alloc_slot].load_inflight   <= 1'b0;
                entries[alloc_slot].load_done       <= 1'b0;

                // Same-cycle address resolution.
                if (alloc_addr_known &&
                    addr_valid &&
                    (addr_lsq_idx == alloc_slot)) begin

                    entries[alloc_slot].addr_known <= 1'b1;
                    entries[alloc_slot].addr       <= addr_value;
                    entries[alloc_slot].size       <= addr_size;
                end

                next_age <= next_age + 1'b1;
            end

        end
    end

endmodule