// =============================================================================
// bpred.sv -- REFERENCE SOLUTION (harness validation only, NOT a candidate)
// =============================================================================
// Implements interfaces/TierTwo/bpred_iface.sv exactly. Exists to prove the
// testbench passes something correct and fails deliberate mutants; it must
// never be placed in candidates/.
//
// The interesting part is not the gshare hash -- it is that ALL speculative
// state (GHR and the RAS pointer) lives behind one checkpoint word, and that
// restore takes priority over the speculative update in the same cycle. The RAS
// is a plain wrapping circular array with no full/empty tracking precisely so
// that the pointer alone is a complete checkpoint.
// =============================================================================

module bpred #(
    parameter int PC_W        = 32,
    parameter int GHR_W       = 8,
    parameter int PHT_ENTRIES = 256,
    parameter int BTB_SETS    = 16,
    parameter int BTB_WAYS    = 2,
    parameter int RAS_DEPTH   = 8,
    // derived -- do not override
    parameter int RAS_PTR_W   = $clog2(RAS_DEPTH),
    parameter int SNAP_W      = GHR_W + RAS_PTR_W
) (
    input  logic              clk,
    input  logic              rst_n,

    input  logic [PC_W-1:0]   predict_pc,
    output logic              predict_valid,
    output logic              predict_taken,
    output logic [PC_W-1:0]   predict_target,
    output logic              predict_is_return,
    output logic [SNAP_W-1:0] ghr_snapshot,

    input  logic              update_valid,
    input  logic [PC_W-1:0]   update_pc,
    input  logic              update_taken,
    input  logic [PC_W-1:0]   update_target,
    input  logic              update_is_branch,
    input  logic              update_is_call,
    input  logic              update_is_return,

    input  logic              restore_valid,
    input  logic [SNAP_W-1:0] restore_ghr_value
);

    localparam int SET_W = $clog2(BTB_SETS);
    localparam int TAG_W = PC_W - 2 - SET_W;

    localparam logic [1:0] T_BRANCH = 2'd0;
    localparam logic [1:0] T_CALL   = 2'd1;
    localparam logic [1:0] T_RETURN = 2'd2;

    // ---------------------------------------------------------------------
    // state
    // ---------------------------------------------------------------------
    logic [GHR_W-1:0]     ghr;
    logic [RAS_PTR_W-1:0] ras_sp;
    logic [PC_W-1:0]      ras [RAS_DEPTH];
    logic [1:0]           pht [PHT_ENTRIES];

    // BTB, flattened to set*WAYS+way so it stays a simple 1-D array
    logic                 btb_val  [BTB_SETS*BTB_WAYS];
    logic [TAG_W-1:0]     btb_tag  [BTB_SETS*BTB_WAYS];
    logic [PC_W-1:0]      btb_tgt  [BTB_SETS*BTB_WAYS];
    logic [1:0]           btb_type [BTB_SETS*BTB_WAYS];
    logic                 btb_rr   [BTB_SETS];   // round-robin victim, not graded

    // ---------------------------------------------------------------------
    // address decomposition
    // ---------------------------------------------------------------------
    function automatic int set_of(input logic [PC_W-1:0] pc);
        return int'(pc[2 +: SET_W]);
    endfunction

    function automatic logic [TAG_W-1:0] tag_of(input logic [PC_W-1:0] pc);
        return pc[2+SET_W +: TAG_W];
    endfunction

    function automatic int pht_idx(input logic [PC_W-1:0] pc, input logic [GHR_W-1:0] h);
        return int'(pc[2 +: GHR_W] ^ h);
    endfunction

    // ---------------------------------------------------------------------
    // BTB lookup (combinational)
    // ---------------------------------------------------------------------
    logic             hit;
    logic [1:0]       hit_type;
    logic [PC_W-1:0]  hit_tgt;

    always_comb begin
        int s;
        hit      = 1'b0;
        hit_type = T_BRANCH;
        hit_tgt  = '0;
        s = set_of(predict_pc);
        for (int w = 0; w < BTB_WAYS; w++)
            if (btb_val[s*BTB_WAYS + w] && btb_tag[s*BTB_WAYS + w] == tag_of(predict_pc)) begin
                hit      = 1'b1;
                hit_type = btb_type[s*BTB_WAYS + w];
                hit_tgt  = btb_tgt [s*BTB_WAYS + w];
            end
    end

    // ---------------------------------------------------------------------
    // prediction outputs
    // ---------------------------------------------------------------------
    logic [RAS_PTR_W-1:0] ras_top_ptr;
    assign ras_top_ptr = ras_sp - RAS_PTR_W'(1);

    assign predict_valid     = hit;
    assign predict_is_return = hit && (hit_type == T_RETURN);
    assign predict_taken     = hit ? ((hit_type == T_BRANCH)
                                       ? pht[pht_idx(predict_pc, ghr)][1]
                                       : 1'b1)
                                   : 1'b0;
    assign predict_target    = predict_is_return ? ras[ras_top_ptr] : hit_tgt;
    assign ghr_snapshot      = {ras_sp, ghr};

    // ---------------------------------------------------------------------
    // update-side decode
    // ---------------------------------------------------------------------
    logic       upd_ctrl;
    logic [1:0] upd_type;
    always_comb begin
        upd_ctrl = 1'b0;
        upd_type = T_BRANCH;
        if (update_valid) begin
            if (update_is_call)        begin upd_ctrl = 1'b1; upd_type = T_CALL;   end
            else if (update_is_return) begin upd_ctrl = 1'b1; upd_type = T_RETURN; end
            else if (update_is_branch) begin upd_ctrl = 1'b1; upd_type = T_BRANCH; end
        end
    end

    // effective history for training: a same-cycle restore applies first, so a
    // recovery trains with the branch's own pre-branch history
    logic [GHR_W-1:0] eff_ghr;
    assign eff_ghr = restore_valid ? restore_ghr_value[GHR_W-1:0] : ghr;

    // way to write in the BTB: refresh on tag match, else the round-robin victim
    logic [31:0] wr_way;
    always_comb begin
        int s;
        s      = set_of(update_pc);
        wr_way = {31'b0, btb_rr[s]};
        for (int w = 0; w < BTB_WAYS; w++)
            if (btb_val[s*BTB_WAYS + w] && btb_tag[s*BTB_WAYS + w] == tag_of(update_pc))
                wr_way = w[31:0];
    end

    // ---------------------------------------------------------------------
    // sequential
    // ---------------------------------------------------------------------
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            ghr    <= '0;
            ras_sp <= '0;
            for (int i = 0; i < PHT_ENTRIES; i++)      pht[i]     <= 2'd1;
            for (int i = 0; i < RAS_DEPTH; i++)         ras[i]     <= '0;
            for (int i = 0; i < BTB_SETS*BTB_WAYS; i++) btb_val[i] <= 1'b0;
            for (int i = 0; i < BTB_SETS; i++)          btb_rr[i]  <= 1'b0;
        end else begin
            // ---- speculative state: restore beats the speculative update ----
            if (restore_valid) begin
                // Fold the resolved outcome into the recovered history when the
                // branch's own update lands in the same cycle, so recovery ends
                // architecturally correct rather than one branch short.
                if (upd_ctrl && upd_type == T_BRANCH)
                    ghr <= {restore_ghr_value[GHR_W-2:0], update_taken};
                else
                    ghr <= restore_ghr_value[GHR_W-1:0];
                ras_sp <= restore_ghr_value[GHR_W +: RAS_PTR_W];
            end else if (predict_valid) begin
                case (hit_type)
                    T_BRANCH: ghr <= {ghr[GHR_W-2:0], predict_taken};
                    T_CALL: begin
                        ras[ras_sp] <= predict_pc + PC_W'(4);
                        ras_sp      <= ras_sp + RAS_PTR_W'(1);
                    end
                    default: ras_sp <= ras_sp - RAS_PTR_W'(1);   // T_RETURN
                endcase
            end

            // ---- non-speculative training, independent of restore ----
            if (upd_ctrl) begin
                int s, wi;
                s  = set_of(update_pc);
                wi = s*BTB_WAYS + int'(wr_way);
                btb_val [wi] <= 1'b1;
                btb_tag [wi] <= tag_of(update_pc);
                btb_tgt [wi] <= update_target;
                btb_type[wi] <= upd_type;
                // only advance the victim pointer when actually allocating
                if (!btb_val[wi] || btb_tag[wi] != tag_of(update_pc))
                    btb_rr[s] <= ~btb_rr[s];

                if (upd_type == T_BRANCH) begin
                    int pi;
                    pi = pht_idx(update_pc, eff_ghr);
                    if (update_taken) begin
                        if (pht[pi] != 2'd3) pht[pi] <= pht[pi] + 2'd1;
                    end else begin
                        if (pht[pi] != 2'd0) pht[pi] <= pht[pi] - 2'd1;
                    end
                end
            end
        end
    end

endmodule
