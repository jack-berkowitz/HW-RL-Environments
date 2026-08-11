// =============================================================================
// bpred.sv  --  Branch Predictor Implementation
// =============================================================================

module bpred #(
    parameter int PC_W        = 32,
    parameter int GHR_W       = 8,
    parameter int PHT_ENTRIES = 256,   // must be 2**GHR_W
    parameter int BTB_SETS    = 16,
    parameter int BTB_WAYS    = 2,
    parameter int RAS_DEPTH   = 8,
    // derived -- do not override
    parameter int RAS_PTR_W   = $clog2(RAS_DEPTH),
    parameter int SNAP_W      = GHR_W + RAS_PTR_W
) (
    input  logic              clk,
    input  logic              rst_n,

    // ---- predict (combinational) ----
    input  logic [PC_W-1:0]   predict_pc,
    output logic              predict_valid,       // BTB hit
    output logic              predict_taken,
    output logic [PC_W-1:0]   predict_target,
    output logic              predict_is_return,
    output logic [SNAP_W-1:0] ghr_snapshot,        // { ras_sp, ghr }, pre-update

    // ---- update (ground truth) ----
    input  logic              update_valid,
    input  logic [PC_W-1:0]   update_pc,
    input  logic              update_taken,
    input  logic [PC_W-1:0]   update_target,
    input  logic              update_is_branch,
    input  logic              update_is_call,
    input  logic              update_is_return,

    // ---- speculative-state recovery ----
    input  logic              restore_valid,
    input  logic [SNAP_W-1:0] restore_ghr_value    // same packing as ghr_snapshot
);

    // =========================================================================
    // PARAMETERS & CONSTANTS
    // =========================================================================
    localparam int SET_W = $clog2(BTB_SETS);
    localparam int TAG_W = PC_W - 2 - SET_W;
    localparam int WAY_W = $clog2(BTB_WAYS) > 0 ? $clog2(BTB_WAYS) : 1;

    localparam logic [1:0] TYPE_BRANCH = 2'd0;
    localparam logic [1:0] TYPE_CALL   = 2'd1;
    localparam logic [1:0] TYPE_RETURN = 2'd2;
    localparam logic [1:0] TYPE_NONE   = 2'd3;

    // =========================================================================
    // STATE STRUCTURES
    // =========================================================================
    // BTB
    logic             btb_valid  [BTB_SETS][BTB_WAYS];
    logic [TAG_W-1:0] btb_tag    [BTB_SETS][BTB_WAYS];
    logic [PC_W-1:0]  btb_target [BTB_SETS][BTB_WAYS];
    logic [1:0]       btb_type   [BTB_SETS][BTB_WAYS];
    logic [WAY_W-1:0] btb_lru    [BTB_SETS]; // Pseudo-LRU pointer for replacement

    // PHT
    logic [1:0]       pht [PHT_ENTRIES];

    // GHR & RAS
    logic [GHR_W-1:0]     ghr;
    logic [RAS_PTR_W-1:0] ras_sp;
    logic [PC_W-1:0]      ras [RAS_DEPTH];

    // =========================================================================
    // SNAPSHOT PACKING / UNPACKING
    // =========================================================================
    logic [RAS_PTR_W-1:0] restore_ras_sp;
    logic [GHR_W-1:0]     restore_ghr;
    
    assign ghr_snapshot   = {ras_sp, ghr};
    assign restore_ras_sp = restore_ghr_value[SNAP_W-1 : GHR_W];
    assign restore_ghr    = restore_ghr_value[GHR_W-1 : 0];

    // =========================================================================
    // PREDICTION LOGIC (COMBINATIONAL)
    // =========================================================================
    logic [SET_W-1:0] pred_set;
    logic [TAG_W-1:0] pred_tag;
    assign pred_set = predict_pc[2 +: SET_W];
    assign pred_tag = predict_pc[2 + SET_W +: TAG_W];

    logic             pred_hit;
    logic [WAY_W-1:0] pred_way;
    
    always_comb begin
        pred_hit = 1'b0;
        pred_way = '0;
        for (int w = 0; w < BTB_WAYS; w++) begin
            if (btb_valid[pred_set][w] && btb_tag[pred_set][w] == pred_tag) begin
                pred_hit = 1'b1;
                pred_way = w[WAY_W-1:0];
            end
        end
    end

    logic [1:0]      pred_type;
    logic [PC_W-1:0] pred_btb_target;
    
    assign pred_type       = btb_type[pred_set][pred_way];
    assign pred_btb_target = btb_target[pred_set][pred_way];

    // PHT Lookup
    logic [GHR_W-1:0] pred_pht_idx;
    logic [1:0]       pred_pht_val;
    assign pred_pht_idx = predict_pc[2 +: GHR_W] ^ ghr;
    assign pred_pht_val = pht[pred_pht_idx];

    // Output assignments
    assign predict_valid     = pred_hit;
    assign predict_is_return = pred_hit && (pred_type == TYPE_RETURN);
    assign predict_taken     = pred_hit ? ((pred_type == TYPE_BRANCH) ? pred_pht_val[1] : 1'b1) : 1'b0;
    assign predict_target    = predict_is_return ? ras[ras_sp - 1'b1] : pred_btb_target;

    // =========================================================================
    // UPDATE LOGIC (COMBINATIONAL PREP)
    // =========================================================================
    logic [1:0] upd_type;
    assign upd_type = update_is_call   ? TYPE_CALL :
                      update_is_return ? TYPE_RETURN :
                      update_is_branch ? TYPE_BRANCH : TYPE_NONE;

    logic [SET_W-1:0] upd_set;
    logic [TAG_W-1:0] upd_tag;
    assign upd_set = update_pc[2 +: SET_W];
    assign upd_tag = update_pc[2 + SET_W +: TAG_W];

    logic             upd_hit;
    logic [WAY_W-1:0] upd_way;

    always_comb begin
        upd_hit = 1'b0;
        upd_way = '0;
        for (int w = 0; w < BTB_WAYS; w++) begin
            if (btb_valid[upd_set][w] && btb_tag[upd_set][w] == upd_tag) begin
                upd_hit = 1'b1;
                upd_way = w[WAY_W-1:0];
            end
        end
    end

    logic [WAY_W-1:0] upd_replace_way;
    always_comb begin
        upd_replace_way = btb_lru[upd_set]; // Default to LRU pointer
        if (!upd_hit) begin
            // If miss, try to find an invalid entry first
            for (int w = 0; w < BTB_WAYS; w++) begin
                if (!btb_valid[upd_set][w]) begin
                    upd_replace_way = w[WAY_W-1:0];
                    break;
                end
            end
        end else begin
            // If hit, replace the matching way
            upd_replace_way = upd_way;
        end
    end

    // PHT Training
    logic [GHR_W-1:0] eff_ghr;
    logic [GHR_W-1:0] train_idx;
    logic [1:0]       pht_val;
    logic [1:0]       pht_next;

    assign eff_ghr   = restore_valid ? restore_ghr : ghr;
    assign train_idx = update_pc[2 +: GHR_W] ^ eff_ghr;
    assign pht_val   = pht[train_idx];

    assign pht_next  = update_taken ? (pht_val == 2'd3 ? 2'd3 : pht_val + 1'b1) :
                                      (pht_val == 2'd0 ? 2'd0 : pht_val - 1'b1);

    // =========================================================================
    // SEQUENTIAL STATE UPDATES
    // =========================================================================
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            ghr    <= '0;
            ras_sp <= '0;
            
            for (int i = 0; i < RAS_DEPTH; i++) begin
                ras[i] <= '0;
            end
            
            for (int i = 0; i < PHT_ENTRIES; i++) begin
                pht[i] <= 2'd1; // Weakly not-taken
            end
            
            for (int s = 0; s < BTB_SETS; s++) begin
                btb_lru[s] <= '0;
                for (int w = 0; w < BTB_WAYS; w++) begin
                    btb_valid[s][w] <= 1'b0;
                end
            end
        end else begin
            // -----------------------------------------------------------------
            // 1. Speculative State (GHR & RAS)
            // -----------------------------------------------------------------
            if (restore_valid) begin
                ras_sp <= restore_ras_sp;
                if (update_valid && update_is_branch) begin
                    ghr <= {restore_ghr[GHR_W-2:0], update_taken};
                end else begin
                    ghr <= restore_ghr;
                end
            end else if (predict_valid) begin
                if (pred_type == TYPE_BRANCH) begin
                    ghr <= {ghr[GHR_W-2:0], predict_taken};
                end else if (pred_type == TYPE_CALL) begin
                    ras[ras_sp] <= predict_pc + 32'd4;
                    ras_sp      <= ras_sp + 1'b1;
                end else if (pred_type == TYPE_RETURN) begin
                    ras_sp      <= ras_sp - 1'b1;
                end
            end

            // -----------------------------------------------------------------
            // 2. Ground-Truth State (BTB & PHT)
            // -----------------------------------------------------------------
            if (update_valid) begin
                if (upd_type != TYPE_NONE) begin
                    btb_valid[upd_set][upd_replace_way]  <= 1'b1;
                    btb_tag[upd_set][upd_replace_way]    <= upd_tag;
                    btb_target[upd_set][upd_replace_way] <= update_target;
                    btb_type[upd_set][upd_replace_way]   <= upd_type;
                    
                    // Simple deterministic toggle/increment for LRU/Replacement
                    btb_lru[upd_set] <= (upd_replace_way + 1'b1);
                end
                
                if (update_is_branch) begin
                    pht[train_idx] <= pht_next;
                end
            end

            // BTB LRU update on predict hit (if not overwritten by a commit)
            if (predict_valid) begin
                if (!(update_valid && (upd_type != TYPE_NONE) && (upd_set == pred_set))) begin
                    btb_lru[pred_set] <= (pred_way + 1'b1);
                end
            end
        end
    end

endmodule