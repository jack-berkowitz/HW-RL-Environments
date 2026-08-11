// =============================================================================
// lsq.sv  --  Load/Store Queue Implementation
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

    // =========================================================================
    // STATE REGISTERS
    // =========================================================================
    logic [DEPTH-1:0]  entry_valid;
    logic [DEPTH-1:0]  entry_is_store;
    logic [AGE_W-1:0]  entry_age [0:DEPTH-1];
    logic [DEPTH-1:0]  entry_addr_known;
    logic [ADDR_W-1:0] entry_addr [0:DEPTH-1];
    logic [1:0]        entry_size [0:DEPTH-1];
    logic [DEPTH-1:0]  entry_data_known;
    logic [DATA_W-1:0] entry_data [0:DEPTH-1];
    logic [DEPTH-1:0]  entry_committed;
    logic [DEPTH-1:0]  entry_issued;

    logic [IDX_W-1:0]  alloc_ptr;
    logic [AGE_W-1:0]  next_age;

    // Memory tracking
    logic              mem_inflight;
    logic              mem_inflight_is_store;
    logic [IDX_W-1:0]  mem_inflight_idx;
    logic [AGE_W-1:0]  mem_inflight_age;
    logic              mem_inflight_flushed;

    // Output assignment for allocation
    assign lsq_idx = alloc_ptr;

    // =========================================================================
    // LOAD LEGALITY & FORWARDING LOGIC
    // =========================================================================
    logic [DEPTH-1:0] load_is_legal;
    logic [DEPTH-1:0] load_needs_mem;
    logic [DEPTH-1:0] load_can_fwd;
    logic [IDX_W-1:0] load_fwd_idx [0:DEPTH-1];

    always_comb begin
        for (int i = 0; i < DEPTH; i++) begin
            load_is_legal[i]  = 1'b0;
            load_needs_mem[i] = 1'b0;
            load_can_fwd[i]   = 1'b0;
            load_fwd_idx[i]   = '0;

            if (entry_valid[i] && !entry_is_store[i] && !entry_issued[i]) begin
                logic blocked;
                logic overlap_found;
                logic exact_match;
                logic [AGE_W-1:0] max_age;
                logic [IDX_W-1:0] max_idx;
                
                blocked       = 1'b0;
                overlap_found = 1'b0;
                exact_match   = 1'b0;
                max_age       = '0;
                max_idx       = '0;

                for (int j = 0; j < DEPTH; j++) begin
                    if (entry_valid[j] && entry_is_store[j] && (entry_age[j] < entry_age[i])) begin
                        if (!entry_addr_known[j]) begin
                            blocked = 1'b1;
                        end else begin
                            // Check byte overlap
                            logic [ADDR_W:0] start_i = {1'b0, entry_addr[i]};
                            logic [ADDR_W:0] end_i   = start_i + (1 << entry_size[i]) - 1;
                            logic [ADDR_W:0] start_j = {1'b0, entry_addr[j]};
                            logic [ADDR_W:0] end_j   = start_j + (1 << entry_size[j]) - 1;

                            logic overlap = (start_i <= end_j) && (start_j <= end_i);
                            logic exact   = (start_i == start_j) && (entry_size[i] == entry_size[j]);

                            if (overlap) begin
                                if (!overlap_found || (entry_age[j] > max_age)) begin
                                    overlap_found = 1'b1;
                                    max_age       = entry_age[j];
                                    max_idx       = j[IDX_W-1:0];
                                    exact_match   = exact;
                                end
                            end
                        end
                    end
                end

                if (!blocked) begin
                    load_is_legal[i] = 1'b1;
                    if (!overlap_found) begin
                        load_needs_mem[i] = 1'b1;
                    end else if (exact_match && entry_data_known[max_idx]) begin
                        load_can_fwd[i] = 1'b1;
                        load_fwd_idx[i] = max_idx;
                    end
                end
            end
        end
    end

    // =========================================================================
    // ARBITRATION LOGIC (Oldest First)
    // =========================================================================
    function automatic logic [IDX_W:0] find_oldest(
        input logic [DEPTH-1:0] mask, 
        input logic [AGE_W-1:0] ages [0:DEPTH-1]
    );
        logic [IDX_W:0] oldest_idx = '0; // MSB represents 'valid'
        logic [AGE_W-1:0] min_age = {AGE_W{1'b1}};
        for (int i = 0; i < DEPTH; i++) begin
            if (mask[i]) begin
                if (!oldest_idx[IDX_W] || (ages[i] < min_age)) begin
                    oldest_idx[IDX_W]     = 1'b1;
                    oldest_idx[IDX_W-1:0] = i[IDX_W-1:0];
                    min_age               = ages[i];
                end
            end
        end
        return oldest_idx;
    endfunction

    logic [DEPTH-1:0] store_ready_mem;
    always_comb begin
        for (int i = 0; i < DEPTH; i++) begin
            store_ready_mem[i] = entry_valid[i] && entry_is_store[i] && entry_committed[i] && !entry_issued[i];
        end
    end

    logic [IDX_W:0] oldest_store_mem;
    logic [IDX_W:0] oldest_load_mem;
    logic [IDX_W:0] oldest_load_fwd;

    assign oldest_store_mem = find_oldest(store_ready_mem, entry_age);
    assign oldest_load_mem  = find_oldest(load_needs_mem, entry_age);
    assign oldest_load_fwd  = find_oldest(load_can_fwd, entry_age);

    // =========================================================================
    // MEMORY REQUEST
    // =========================================================================
    logic do_store_req;
    logic do_load_req;
    assign do_store_req = !mem_inflight && oldest_store_mem[IDX_W];
    assign do_load_req  = !mem_inflight && !do_store_req && oldest_load_mem[IDX_W];

    assign mem_req_valid = do_store_req || do_load_req;
    
    logic [IDX_W-1:0] req_idx;
    assign req_idx       = do_store_req ? oldest_store_mem[IDX_W-1:0] : oldest_load_mem[IDX_W-1:0];
    
    assign mem_req_addr  = entry_addr[req_idx];
    assign mem_req_we    = do_store_req;
    assign mem_req_wdata = entry_data[req_idx];
    assign mem_req_size  = entry_size[req_idx];

    // =========================================================================
    // RESULT EMISSION
    // =========================================================================
    logic inflight_is_flushed_now;
    assign inflight_is_flushed_now = mem_inflight_flushed || (flush_valid && (mem_inflight_age > flush_age_threshold));

    logic mem_resp_is_valid_load;
    assign mem_resp_is_valid_load = mem_resp_valid && !mem_inflight_is_store && !inflight_is_flushed_now;

    logic do_fwd;
    logic actual_do_fwd;
    logic fwd_is_flushed_now;
    
    assign do_fwd = oldest_load_fwd[IDX_W];
    assign actual_do_fwd = do_fwd && !mem_resp_is_valid_load;
    assign fwd_is_flushed_now = flush_valid && (entry_age[oldest_load_fwd[IDX_W-1:0]] > flush_age_threshold);

    assign load_result_valid   = mem_resp_is_valid_load || (actual_do_fwd && !fwd_is_flushed_now);
    assign load_result_lsq_idx = mem_resp_is_valid_load ? mem_inflight_idx : oldest_load_fwd[IDX_W-1:0];
    assign load_result_source  = mem_resp_is_valid_load ? 1'b0 : 1'b1;
    assign load_result_value   = mem_resp_is_valid_load ? mem_resp_rdata : entry_data[load_fwd_idx[oldest_load_fwd[IDX_W-1:0]]];

    // =========================================================================
    // SEQUENTIAL UPDATES
    // =========================================================================
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            entry_valid          <= '0;
            alloc_ptr            <= '0;
            next_age             <= '0;
            mem_inflight         <= 1'b0;
            mem_inflight_flushed <= 1'b0;
        end else begin

            // Memory inflight tracking
            if (flush_valid && mem_inflight && (mem_inflight_age > flush_age_threshold)) begin
                mem_inflight_flushed <= 1'b1;
            end

            if (mem_resp_valid) begin
                mem_inflight         <= 1'b0;
                mem_inflight_flushed <= 1'b0;
            end else if (mem_req_valid) begin
                mem_inflight          <= 1'b1;
                mem_inflight_is_store <= do_store_req;
                mem_inflight_idx      <= req_idx;
                mem_inflight_age      <= entry_age[req_idx];
                mem_inflight_flushed  <= 1'b0;
            end

            // Main entry array updates
            for (int i = 0; i < DEPTH; i = i + 1) begin
                
                // 1. Flush (Highest priority for clearing)
                if (flush_valid && entry_valid[i] && (entry_age[i] > flush_age_threshold)) begin
                    entry_valid[i] <= 1'b0;
                end else begin
                    // 2. Freeing Logic
                    if (mem_resp_is_valid_load && (i[IDX_W-1:0] == mem_inflight_idx)) begin
                        entry_valid[i] <= 1'b0;
                    end else if (actual_do_fwd && !fwd_is_flushed_now && (i[IDX_W-1:0] == oldest_load_fwd[IDX_W-1:0])) begin
                        entry_valid[i] <= 1'b0;
                    end else if (mem_resp_valid && mem_inflight_is_store && (i[IDX_W-1:0] == mem_inflight_idx)) begin
                        entry_valid[i] <= 1'b0;
                    end
                    
                    // 3. Allocation (Overrides freeing if same slot re-allocated, but won't happen if DEPTH handled correctly)
                    if (alloc_valid && (i[IDX_W-1:0] == alloc_ptr)) begin
                        entry_valid[i]     <= 1'b1;
                        entry_is_store[i]  <= alloc_is_store;
                        entry_age[i]       <= next_age;
                        entry_issued[i]    <= 1'b0;
                        entry_committed[i] <= 1'b0;
                        
                        // Handle potential same-cycle address resolution
                        if (addr_valid && (addr_lsq_idx == i[IDX_W-1:0])) begin
                            entry_addr_known[i] <= 1'b1;
                            entry_addr[i]       <= addr_value;
                            entry_size[i]       <= addr_size;
                        end else begin
                            entry_addr_known[i] <= 1'b0;
                        end

                        // Handle potential same-cycle data resolution
                        if (store_data_valid && (store_data_lsq_idx == i[IDX_W-1:0])) begin
                            entry_data_known[i] <= 1'b1;
                            entry_data[i]       <= store_data_value;
                        end else begin
                            entry_data_known[i] <= 1'b0;
                        end
                    end else begin
                        // 4. Updates to existing valid entries
                        if (addr_valid && (addr_lsq_idx == i[IDX_W-1:0])) begin
                            entry_addr_known[i] <= 1'b1;
                            entry_addr[i]       <= addr_value;
                            entry_size[i]       <= addr_size;
                        end
                        
                        if (store_data_valid && (store_data_lsq_idx == i[IDX_W-1:0])) begin
                            entry_data_known[i] <= 1'b1;
                            entry_data[i]       <= store_data_value;
                        end

                        if (store_commit_valid && (store_commit_lsq_idx == i[IDX_W-1:0])) begin
                            entry_committed[i] <= 1'b1;
                        end
                        
                        if (mem_req_valid && (req_idx == i[IDX_W-1:0])) begin
                            entry_issued[i] <= 1'b1;
                        end
                    end
                end
            end

            // Allocation pointer advance
            if (alloc_valid) begin
                alloc_ptr <= alloc_ptr + 1'b1;
                next_age  <= next_age + 1'b1;
            end
        end
    end

endmodule