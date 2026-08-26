// =============================================================================
// axi4_xbar
// =============================================================================

module axi4_xbar
  import axi4_xbar_pkg::*;
#(
    parameter int NUM_MST   = 2,
    parameter int NUM_SLV   = 2,
    parameter int MAX_TRANS = 8,
    parameter int MAX_BURST_LEN = 3
) (
    input  logic clk,
    input  logic rst_n,

    // ---- master side: NUM_MST masters drive these -------------------------
    input  slv_req_t  [NUM_MST-1:0] mst_req,
    output slv_resp_t [NUM_MST-1:0] mst_resp,

    // ---- slave side: NUM_SLV slaves are driven by these --------------------
    output mst_req_t  [NUM_SLV-1:0] slv_req,
    input  mst_resp_t [NUM_SLV-1:0] slv_resp,

    // ---- address map ------------------------------------------------------
    input  xbar_rule_t [NUM_SLV-1:0] addr_map
);

    localparam int SLV_ID_W = $bits(mst_req[0].aw.id);
    localparam int MST_ID_W = SLV_ID_W + 2;

    // =========================================================================
    // Address Decoding
    // =========================================================================
    logic [NUM_SLV:0] dec_aw [NUM_MST];
    logic [NUM_SLV:0] dec_ar [NUM_MST];
    
    for (genvar m=0; m<NUM_MST; m++) begin : g_dec
        always_comb begin
            logic aw_matched;
            logic ar_matched;
            dec_aw[m] = '0;
            dec_ar[m] = '0;
            aw_matched = 1'b0;
            ar_matched = 1'b0;
            
            for (int s=0; s<NUM_SLV; s++) begin
                if (mst_req[m].aw.addr >= addr_map[s].start_addr && mst_req[m].aw.addr < addr_map[s].end_addr) begin
                    dec_aw[m][addr_map[s].mst_port] = 1'b1;
                    aw_matched = 1'b1;
                end
                if (mst_req[m].ar.addr >= addr_map[s].start_addr && mst_req[m].ar.addr < addr_map[s].end_addr) begin
                    dec_ar[m][addr_map[s].mst_port] = 1'b1;
                    ar_matched = 1'b1;
                end
            end
            
            if (!aw_matched) dec_aw[m][NUM_SLV] = 1'b1; // DECERR Dummy Slave
            if (!ar_matched) dec_ar[m][NUM_SLV] = 1'b1;
        end
    end

    // =========================================================================
    // W-Channel Routing FIFOs
    // =========================================================================
    logic [2:0] mst_w_fifo_din  [NUM_MST];
    logic [2:0] mst_w_fifo_dout [NUM_MST];
    logic mst_w_fifo_push [NUM_MST];
    logic mst_w_fifo_pop  [NUM_MST];
    logic mst_w_fifo_full [NUM_MST];
    logic mst_w_fifo_empty[NUM_MST];

    int mst_w_fifo_count [NUM_MST];
    int mst_w_fifo_wr_ptr [NUM_MST];
    int mst_w_fifo_rd_ptr [NUM_MST];
    logic [2:0] mst_w_fifo_mem [NUM_MST][MAX_TRANS+2];

    for (genvar m=0; m<NUM_MST; m++) begin : g_mst_fifo
        assign mst_w_fifo_full[m] = (mst_w_fifo_count[m] == MAX_TRANS+2);
        assign mst_w_fifo_empty[m] = (mst_w_fifo_count[m] == 0);
        assign mst_w_fifo_dout[m] = mst_w_fifo_mem[m][mst_w_fifo_rd_ptr[m]];
        
        always_ff @(posedge clk) begin
            if (!rst_n) begin
                mst_w_fifo_count[m] <= 0;
                mst_w_fifo_wr_ptr[m] <= 0;
                mst_w_fifo_rd_ptr[m] <= 0;
            end else begin
                logic push; logic pop;
                push = mst_w_fifo_push[m] && !mst_w_fifo_full[m];
                pop = mst_w_fifo_pop[m] && !mst_w_fifo_empty[m];
                
                if (push && !pop) begin
                    mst_w_fifo_count[m] <= mst_w_fifo_count[m] + 1;
                    mst_w_fifo_mem[m][mst_w_fifo_wr_ptr[m]] <= mst_w_fifo_din[m];
                    mst_w_fifo_wr_ptr[m] <= (mst_w_fifo_wr_ptr[m] + 1 == MAX_TRANS+2) ? 0 : mst_w_fifo_wr_ptr[m] + 1;
                end else if (!push && pop) begin
                    mst_w_fifo_count[m] <= mst_w_fifo_count[m] - 1;
                    mst_w_fifo_rd_ptr[m] <= (mst_w_fifo_rd_ptr[m] + 1 == MAX_TRANS+2) ? 0 : mst_w_fifo_rd_ptr[m] + 1;
                end else if (push && pop) begin
                    mst_w_fifo_mem[m][mst_w_fifo_wr_ptr[m]] <= mst_w_fifo_din[m];
                    mst_w_fifo_wr_ptr[m] <= (mst_w_fifo_wr_ptr[m] + 1 == MAX_TRANS+2) ? 0 : mst_w_fifo_wr_ptr[m] + 1;
                    mst_w_fifo_rd_ptr[m] <= (mst_w_fifo_rd_ptr[m] + 1 == MAX_TRANS+2) ? 0 : mst_w_fifo_rd_ptr[m] + 1;
                end
            end
        end
    end

    logic [2:0] slv_w_fifo_din  [NUM_SLV+1];
    logic [2:0] slv_w_fifo_dout [NUM_SLV+1];
    logic slv_w_fifo_push [NUM_SLV+1];
    logic slv_w_fifo_pop  [NUM_SLV+1];
    logic slv_w_fifo_full [NUM_SLV+1];
    logic slv_w_fifo_empty[NUM_SLV+1];

    int slv_w_fifo_count [NUM_SLV+1];
    int slv_w_fifo_wr_ptr [NUM_SLV+1];
    int slv_w_fifo_rd_ptr [NUM_SLV+1];
    logic [2:0] slv_w_fifo_mem [NUM_SLV+1][NUM_MST*MAX_TRANS+2];

    for (genvar s=0; s<=NUM_SLV; s++) begin : g_slv_fifo
        assign slv_w_fifo_full[s] = (slv_w_fifo_count[s] == NUM_MST*MAX_TRANS+2);
        assign slv_w_fifo_empty[s] = (slv_w_fifo_count[s] == 0);
        assign slv_w_fifo_dout[s] = slv_w_fifo_mem[s][slv_w_fifo_rd_ptr[s]];
        
        always_ff @(posedge clk) begin
            if (!rst_n) begin
                slv_w_fifo_count[s] <= 0;
                slv_w_fifo_wr_ptr[s] <= 0;
                slv_w_fifo_rd_ptr[s] <= 0;
            end else begin
                logic push; logic pop;
                push = slv_w_fifo_push[s] && !slv_w_fifo_full[s];
                pop = slv_w_fifo_pop[s] && !slv_w_fifo_empty[s];
                
                if (push && !pop) begin
                    slv_w_fifo_count[s] <= slv_w_fifo_count[s] + 1;
                    slv_w_fifo_mem[s][slv_w_fifo_wr_ptr[s]] <= slv_w_fifo_din[s];
                    slv_w_fifo_wr_ptr[s] <= (slv_w_fifo_wr_ptr[s] + 1 == NUM_MST*MAX_TRANS+2) ? 0 : slv_w_fifo_wr_ptr[s] + 1;
                end else if (!push && pop) begin
                    slv_w_fifo_count[s] <= slv_w_fifo_count[s] - 1;
                    slv_w_fifo_rd_ptr[s] <= (slv_w_fifo_rd_ptr[s] + 1 == NUM_MST*MAX_TRANS+2) ? 0 : slv_w_fifo_rd_ptr[s] + 1;
                end else if (push && pop) begin
                    slv_w_fifo_mem[s][slv_w_fifo_wr_ptr[s]] <= slv_w_fifo_din[s];
                    slv_w_fifo_wr_ptr[s] <= (slv_w_fifo_wr_ptr[s] + 1 == NUM_MST*MAX_TRANS+2) ? 0 : slv_w_fifo_wr_ptr[s] + 1;
                    slv_w_fifo_rd_ptr[s] <= (slv_w_fifo_rd_ptr[s] + 1 == NUM_MST*MAX_TRANS+2) ? 0 : slv_w_fifo_rd_ptr[s] + 1;
                end
            end
        end
    end

    // =========================================================================
    // AW Channel
    // =========================================================================
    logic [NUM_MST-1:0] aw_req_matrix [NUM_SLV+1];
    logic [NUM_MST-1:0] aw_gnt_matrix [NUM_SLV+1];
    logic slv_aw_valid [NUM_SLV+1];
    logic slv_aw_ready [NUM_SLV+1];
    
    logic [NUM_MST-1:0] aw_mask [NUM_SLV+1];

    for (genvar s=0; s<=NUM_SLV; s++) begin : g_aw_arb
        logic [NUM_MST-1:0] masked_req;
        logic [NUM_MST-1:0] masked_gnt;
        logic [NUM_MST-1:0] unmasked_gnt;
        
        for (genvar m=0; m<NUM_MST; m++) begin
            assign aw_req_matrix[s][m] = mst_req[m].aw_valid & dec_aw[m][s] & !mst_w_fifo_full[m] & !slv_w_fifo_full[s];
        end
        
        assign masked_req = aw_req_matrix[s] & aw_mask[s];
        
        always_comb begin
            masked_gnt = '0;
            unmasked_gnt = '0;
            for (int i=0; i<NUM_MST; i++) begin
                if (masked_req[i]) begin masked_gnt[i] = 1'b1; break; end
            end
            for (int i=0; i<NUM_MST; i++) begin
                if (aw_req_matrix[s][i]) begin unmasked_gnt[i] = 1'b1; break; end
            end
            aw_gnt_matrix[s] = (|masked_req) ? masked_gnt : unmasked_gnt;
        end
        
        always_ff @(posedge clk) begin
            if (!rst_n) begin
                aw_mask[s] <= '1;
            end else if (slv_aw_ready[s] && slv_aw_valid[s]) begin
                for (int i=0; i<NUM_MST; i++) begin
                    if (aw_gnt_matrix[s][i]) begin
                        aw_mask[s] <= ~((1 << (i + 1)) - 1);
                        break;
                    end
                end
            end
        end
    end

    // =========================================================================
    // AR Channel
    // =========================================================================
    logic [NUM_MST-1:0] ar_req_matrix [NUM_SLV+1];
    logic [NUM_MST-1:0] ar_gnt_matrix [NUM_SLV+1];
    logic slv_ar_valid [NUM_SLV+1];
    logic slv_ar_ready [NUM_SLV+1];
    
    logic [NUM_MST-1:0] ar_mask [NUM_SLV+1];

    for (genvar s=0; s<=NUM_SLV; s++) begin : g_ar_arb
        logic [NUM_MST-1:0] masked_req;
        logic [NUM_MST-1:0] masked_gnt;
        logic [NUM_MST-1:0] unmasked_gnt;
        
        for (genvar m=0; m<NUM_MST; m++) begin
            assign ar_req_matrix[s][m] = mst_req[m].ar_valid & dec_ar[m][s];
        end
        
        assign masked_req = ar_req_matrix[s] & ar_mask[s];
        
        always_comb begin
            masked_gnt = '0;
            unmasked_gnt = '0;
            for (int i=0; i<NUM_MST; i++) begin
                if (masked_req[i]) begin masked_gnt[i] = 1'b1; break; end
            end
            for (int i=0; i<NUM_MST; i++) begin
                if (ar_req_matrix[s][i]) begin unmasked_gnt[i] = 1'b1; break; end
            end
            ar_gnt_matrix[s] = (|masked_req) ? masked_gnt : unmasked_gnt;
        end
        
        always_ff @(posedge clk) begin
            if (!rst_n) begin
                ar_mask[s] <= '1;
            end else if (slv_ar_ready[s] && slv_ar_valid[s]) begin
                for (int i=0; i<NUM_MST; i++) begin
                    if (ar_gnt_matrix[s][i]) begin
                        ar_mask[s] <= ~((1 << (i + 1)) - 1);
                        break;
                    end
                end
            end
        end
    end

    // =========================================================================
    // DECERR Dummy Slave logic (s = NUM_SLV)
    // =========================================================================
    logic dummy_aw_valid, dummy_aw_ready;
    logic dummy_w_valid, dummy_w_ready, dummy_w_last;
    logic dummy_ar_valid, dummy_ar_ready;
    logic dummy_b_valid, dummy_b_ready;
    logic dummy_r_valid, dummy_r_ready, dummy_r_last;
    
    logic [MST_ID_W-1:0] dummy_aw_id;
    logic [MST_ID_W-1:0] dummy_ar_id;
    logic [7:0] dummy_ar_len;

    logic [MST_ID_W-1:0] dummy_b_fifo_mem [NUM_MST*MAX_TRANS+2];
    int dummy_b_fifo_count, dummy_b_fifo_wr_ptr, dummy_b_fifo_rd_ptr;
    logic dummy_b_fifo_full, dummy_b_fifo_empty, dummy_b_fifo_push, dummy_b_fifo_pop;
    logic [MST_ID_W-1:0] dummy_b_fifo_dout;

    assign dummy_b_fifo_full = (dummy_b_fifo_count == NUM_MST*MAX_TRANS+2);
    assign dummy_b_fifo_empty = (dummy_b_fifo_count == 0);
    assign dummy_b_fifo_dout = dummy_b_fifo_mem[dummy_b_fifo_rd_ptr];

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            dummy_b_fifo_count <= 0;
            dummy_b_fifo_wr_ptr <= 0;
            dummy_b_fifo_rd_ptr <= 0;
        end else begin
            logic push; logic pop;
            push = dummy_b_fifo_push && !dummy_b_fifo_full;
            pop = dummy_b_fifo_pop && !dummy_b_fifo_empty;
            if (push && !pop) begin
                dummy_b_fifo_count <= dummy_b_fifo_count + 1;
                dummy_b_fifo_mem[dummy_b_fifo_wr_ptr] <= dummy_aw_id;
                dummy_b_fifo_wr_ptr <= (dummy_b_fifo_wr_ptr + 1 == NUM_MST*MAX_TRANS+2) ? 0 : dummy_b_fifo_wr_ptr + 1;
            end else if (!push && pop) begin
                dummy_b_fifo_count <= dummy_b_fifo_count - 1;
                dummy_b_fifo_rd_ptr <= (dummy_b_fifo_rd_ptr + 1 == NUM_MST*MAX_TRANS+2) ? 0 : dummy_b_fifo_rd_ptr + 1;
            end else if (push && pop) begin
                dummy_b_fifo_mem[dummy_b_fifo_wr_ptr] <= dummy_aw_id;
                dummy_b_fifo_wr_ptr <= (dummy_b_fifo_wr_ptr + 1 == NUM_MST*MAX_TRANS+2) ? 0 : dummy_b_fifo_wr_ptr + 1;
                dummy_b_fifo_rd_ptr <= (dummy_b_fifo_rd_ptr + 1 == NUM_MST*MAX_TRANS+2) ? 0 : dummy_b_fifo_rd_ptr + 1;
            end
        end
    end

    logic [MST_ID_W+8-1:0] dummy_r_fifo_mem [NUM_MST*MAX_TRANS+2];
    int dummy_r_fifo_count, dummy_r_fifo_wr_ptr, dummy_r_fifo_rd_ptr;
    logic dummy_r_fifo_full, dummy_r_fifo_empty, dummy_r_fifo_push, dummy_r_fifo_pop;
    logic [MST_ID_W+8-1:0] dummy_r_fifo_dout;

    assign dummy_r_fifo_full = (dummy_r_fifo_count == NUM_MST*MAX_TRANS+2);
    assign dummy_r_fifo_empty = (dummy_r_fifo_count == 0);
    assign dummy_r_fifo_dout = dummy_r_fifo_mem[dummy_r_fifo_rd_ptr];

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            dummy_r_fifo_count <= 0;
            dummy_r_fifo_wr_ptr <= 0;
            dummy_r_fifo_rd_ptr <= 0;
        end else begin
            logic push; logic pop;
            push = dummy_r_fifo_push && !dummy_r_fifo_full;
            pop = dummy_r_fifo_pop && !dummy_r_fifo_empty;
            if (push && !pop) begin
                dummy_r_fifo_count <= dummy_r_fifo_count + 1;
                dummy_r_fifo_mem[dummy_r_fifo_wr_ptr] <= {dummy_ar_len, dummy_ar_id};
                dummy_r_fifo_wr_ptr <= (dummy_r_fifo_wr_ptr + 1 == NUM_MST*MAX_TRANS+2) ? 0 : dummy_r_fifo_wr_ptr + 1;
            end else if (!push && pop) begin
                dummy_r_fifo_count <= dummy_r_fifo_count - 1;
                dummy_r_fifo_rd_ptr <= (dummy_r_fifo_rd_ptr + 1 == NUM_MST*MAX_TRANS+2) ? 0 : dummy_r_fifo_rd_ptr + 1;
            end else if (push && pop) begin
                dummy_r_fifo_mem[dummy_r_fifo_wr_ptr] <= {dummy_ar_len, dummy_ar_id};
                dummy_r_fifo_wr_ptr <= (dummy_r_fifo_wr_ptr + 1 == NUM_MST*MAX_TRANS+2) ? 0 : dummy_r_fifo_wr_ptr + 1;
                dummy_r_fifo_rd_ptr <= (dummy_r_fifo_rd_ptr + 1 == NUM_MST*MAX_TRANS+2) ? 0 : dummy_r_fifo_rd_ptr + 1;
            end
        end
    end

    int w_done_cnt, b_sent_cnt;
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            w_done_cnt <= 0;
            b_sent_cnt <= 0;
        end else begin
            if (dummy_w_valid && dummy_w_ready && dummy_w_last) w_done_cnt <= w_done_cnt + 1;
            if (dummy_b_valid && dummy_b_ready) b_sent_cnt <= b_sent_cnt + 1;
        end
    end
    
    logic [7:0] dummy_r_beat;
    always_ff @(posedge clk) begin
        if (!rst_n) dummy_r_beat <= 0;
        else if (dummy_r_valid && dummy_r_ready) begin
            if (dummy_r_last) dummy_r_beat <= 0;
            else dummy_r_beat <= dummy_r_beat + 1;
        end
    end

    assign dummy_aw_valid = (|aw_req_matrix[NUM_SLV]);
    assign dummy_aw_ready = !dummy_b_fifo_full;
    assign slv_aw_ready[NUM_SLV] = dummy_aw_ready;
    assign dummy_b_fifo_push = dummy_aw_valid && dummy_aw_ready;
    
    assign dummy_w_valid = (!slv_w_fifo_empty[NUM_SLV]) ? mst_req[slv_w_fifo_dout[NUM_SLV]].w_valid : 1'b0;
    assign dummy_w_last = mst_req[slv_w_fifo_empty[NUM_SLV] ? 0 : slv_w_fifo_dout[NUM_SLV]].w.last;
    assign dummy_w_ready = 1'b1;

    assign dummy_b_valid = !dummy_b_fifo_empty && (w_done_cnt > b_sent_cnt);
    assign dummy_b_fifo_pop = dummy_b_valid && dummy_b_ready;

    assign dummy_ar_valid = (|ar_req_matrix[NUM_SLV]);
    assign dummy_ar_ready = !dummy_r_fifo_full;
    assign slv_ar_ready[NUM_SLV] = dummy_ar_ready;
    assign dummy_r_fifo_push = dummy_ar_valid && dummy_ar_ready;

    assign dummy_r_valid = !dummy_r_fifo_empty;
    assign dummy_r_fifo_pop = dummy_r_valid && dummy_r_ready && dummy_r_last;
    assign dummy_r_last = (dummy_r_beat == dummy_r_fifo_dout[MST_ID_W+8-1 : MST_ID_W]);

    always_comb begin
        dummy_aw_id = '0;
        for (int m=0; m<NUM_MST; m++) begin
            if (aw_gnt_matrix[NUM_SLV][m]) dummy_aw_id = {2'(m), mst_req[m].aw.id};
        end
        dummy_ar_id = '0;
        dummy_ar_len = '0;
        for (int m=0; m<NUM_MST; m++) begin
            if (ar_gnt_matrix[NUM_SLV][m]) begin
                dummy_ar_id = {2'(m), mst_req[m].ar.id};
                dummy_ar_len = mst_req[m].ar.len;
            end
        end
    end

    // =========================================================================
    // Write FIFO Control
    // =========================================================================
    for (genvar s=0; s<=NUM_SLV; s++) begin : g_slv_w_ctrl
        always_comb begin
            slv_w_fifo_din[s] = '0;
            for (int m=0; m<NUM_MST; m++) begin
                if (aw_gnt_matrix[s][m] && slv_aw_valid[s]) slv_w_fifo_din[s] = m[2:0];
            end
        end
        assign slv_w_fifo_push[s] = slv_aw_valid[s] && slv_aw_ready[s];
        assign slv_w_fifo_pop[s]  = (s == NUM_SLV) ? (dummy_w_valid && dummy_w_ready && dummy_w_last) : (slv_req[s].w_valid && slv_req[s].w_ready && slv_req[s].w.last);
    end

    for (genvar m=0; m<NUM_MST; m++) begin : g_mst_w_ctrl
        always_comb begin
            mst_w_fifo_din[m] = '0;
            for (int s=0; s<=NUM_SLV; s++) begin
                if (aw_gnt_matrix[s][m] && slv_aw_ready[s]) mst_w_fifo_din[m] = s[2:0];
            end
        end
        assign mst_w_fifo_push[m] = mst_req[m].aw_valid && mst_resp[m].aw_ready;
        assign mst_w_fifo_pop[m]  = mst_req[m].w_valid && mst_resp[m].w_ready && mst_req[m].w.last;
    end

    // =========================================================================
    // Crossbar outputs to Real Slaves
    // =========================================================================
    for (genvar s=0; s<NUM_SLV; s++) begin : g_slv_out
        assign slv_aw_ready[s] = slv_resp[s].aw_ready;
        assign slv_ar_ready[s] = slv_resp[s].ar_ready;
        
        always_comb begin
            slv_req[s] = mst_req[0]; // Struct base to carry unchanged fields
            
            slv_aw_valid[s] = (|aw_req_matrix[s]);
            slv_req[s].aw_valid = slv_aw_valid[s] & rst_n;
            for (int m=0; m<NUM_MST; m++) begin
                if (aw_gnt_matrix[s][m]) begin
                    slv_req[s].aw = mst_req[m].aw;
                    slv_req[s].aw.id = {2'(m), mst_req[m].aw.id};
                end
            end
            
            slv_req[s].w_valid = (!slv_w_fifo_empty[s] ? mst_req[slv_w_fifo_dout[s]].w_valid : 1'b0) & rst_n;
            slv_req[s].w = mst_req[!slv_w_fifo_empty[s] ? slv_w_fifo_dout[s] : 0].w;
            
            slv_ar_valid[s] = (|ar_req_matrix[s]);
            slv_req[s].ar_valid = slv_ar_valid[s] & rst_n;
            for (int m=0; m<NUM_MST; m++) begin
                if (ar_gnt_matrix[s][m]) begin
                    slv_req[s].ar = mst_req[m].ar;
                    slv_req[s].ar.id = {2'(m), mst_req[m].ar.id};
                end
            end
            
            slv_req[s].b_ready = 1'b0;
            slv_req[s].r_ready = 1'b0;
        end
    end

    // =========================================================================
    // B and R Channel Aggregation
    // =========================================================================
    logic [NUM_SLV:0] slv_b_valid, slv_b_ready;
    logic [NUM_SLV:0] slv_r_valid, slv_r_ready, slv_r_last;
    logic [MST_ID_W-1:0] slv_b_id [NUM_SLV:0];
    logic [MST_ID_W-1:0] slv_r_id [NUM_SLV:0];

    for (genvar s=0; s<NUM_SLV; s++) begin : g_resp_agg
        assign slv_b_valid[s] = slv_resp[s].b_valid;
        assign slv_b_id[s]    = slv_resp[s].b.id;
        assign slv_r_valid[s] = slv_resp[s].r_valid;
        assign slv_r_id[s]    = slv_resp[s].r.id;
        assign slv_r_last[s]  = slv_resp[s].r.last;
    end
    assign slv_b_valid[NUM_SLV] = dummy_b_valid;
    assign slv_b_id[NUM_SLV]    = dummy_b_fifo_dout;
    assign dummy_b_ready        = slv_b_ready[NUM_SLV];
    
    assign slv_r_valid[NUM_SLV] = dummy_r_valid;
    assign slv_r_id[NUM_SLV]    = dummy_r_fifo_dout[MST_ID_W-1:0];
    assign slv_r_last[NUM_SLV]  = dummy_r_last;
    assign dummy_r_ready        = slv_r_ready[NUM_SLV];

    // =========================================================================
    // B Channel Routing to Masters
    // =========================================================================
    logic [NUM_SLV:0] b_req_matrix [NUM_MST];
    logic [NUM_SLV:0] b_gnt_matrix [NUM_MST];
    logic [NUM_SLV:0] b_mask [NUM_MST];

    for (genvar m=0; m<NUM_MST; m++) begin : g_b_arb
        logic [NUM_SLV:0] masked_req;
        logic [NUM_SLV:0] masked_gnt;
        logic [NUM_SLV:0] unmasked_gnt;
        
        for (genvar s=0; s<=NUM_SLV; s++) begin
            assign b_req_matrix[m][s] = slv_b_valid[s] && (slv_b_id[s][MST_ID_W-1 : SLV_ID_W] == m);
        end
        
        assign masked_req = b_req_matrix[m] & b_mask[m];
        
        always_comb begin
            masked_gnt = '0;
            unmasked_gnt = '0;
            for (int i=0; i<=NUM_SLV; i++) begin
                if (masked_req[i]) begin masked_gnt[i] = 1'b1; break; end
            end
            for (int i=0; i<=NUM_SLV; i++) begin
                if (b_req_matrix[m][i]) begin unmasked_gnt[i] = 1'b1; break; end
            end
            b_gnt_matrix[m] = (|masked_req) ? masked_gnt : unmasked_gnt;
        end
        
        always_ff @(posedge clk) begin
            if (!rst_n) begin
                b_mask[m] <= '1;
            end else if (mst_req[m].b_ready && (|b_req_matrix[m])) begin
                for (int i=0; i<=NUM_SLV; i++) begin
                    if (b_gnt_matrix[m][i]) begin
                        b_mask[m] <= ~((1 << (i + 1)) - 1);
                        break;
                    end
                end
            end
        end
    end

    // =========================================================================
    // R Channel Routing to Masters
    // =========================================================================
    logic [NUM_SLV:0] r_req_matrix [NUM_MST];
    logic [NUM_SLV:0] r_gnt_matrix [NUM_MST];
    logic [NUM_SLV:0] r_mask [NUM_MST];
    logic r_locked [NUM_MST];
    logic [$clog2(NUM_SLV+1)-1:0] r_locked_sel [NUM_MST];

    for (genvar m=0; m<NUM_MST; m++) begin : g_r_arb
        logic [NUM_SLV:0] r_arb_req;
        logic [NUM_SLV:0] masked_req;
        logic [NUM_SLV:0] masked_gnt;
        logic [NUM_SLV:0] unmasked_gnt;
        logic r_advance;
        
        for (genvar s=0; s<=NUM_SLV; s++) begin
            assign r_req_matrix[m][s] = slv_r_valid[s] && (slv_r_id[s][MST_ID_W-1 : SLV_ID_W] == m);
        end
        
        always_comb begin
            r_arb_req = r_req_matrix[m];
            if (r_locked[m]) begin
                r_arb_req = '0;
                r_arb_req[r_locked_sel[m]] = r_req_matrix[m][r_locked_sel[m]];
            end
        end
        
        assign masked_req = r_arb_req & r_mask[m];
        
        always_comb begin
            masked_gnt = '0;
            unmasked_gnt = '0;
            for (int i=0; i<=NUM_SLV; i++) begin
                if (masked_req[i]) begin masked_gnt[i] = 1'b1; break; end
            end
            for (int i=0; i<=NUM_SLV; i++) begin
                if (r_arb_req[i]) begin unmasked_gnt[i] = 1'b1; break; end
            end
            r_gnt_matrix[m] = (|masked_req) ? masked_gnt : unmasked_gnt;
        end
        
        assign r_advance = mst_req[m].r_ready && mst_resp[m].r_valid;
        
        always_ff @(posedge clk) begin
            if (!rst_n) begin
                r_mask[m] <= '1;
                r_locked[m] <= 1'b0;
                r_locked_sel[m] <= '0;
            end else if (r_advance) begin
                if (mst_resp[m].r.last) begin
                    r_locked[m] <= 1'b0;
                    for (int i=0; i<=NUM_SLV; i++) begin
                        if (r_gnt_matrix[m][i]) begin
                            r_mask[m] <= ~((1 << (i + 1)) - 1);
                            break;
                        end
                    end
                end else if (!r_locked[m]) begin
                    r_locked[m] <= 1'b1;
                    for (int i=0; i<=NUM_SLV; i++) begin
                        if (r_gnt_matrix[m][i]) r_locked_sel[m] <= i[$clog2(NUM_SLV+1)-1:0];
                    end
                end
            end
        end
    end

    // =========================================================================
    // Crossbar outputs to Masters
    // =========================================================================
    for (genvar m=0; m<NUM_MST; m++) begin : g_mst_out
        always_comb begin
            mst_resp[m] = slv_resp[0]; // Base struct
            
            mst_resp[m].aw_ready = 1'b0;
            for (int s=0; s<=NUM_SLV; s++) begin
                if (aw_gnt_matrix[s][m] && slv_aw_ready[s]) mst_resp[m].aw_ready = 1'b1;
            end
            
            mst_resp[m].w_ready = (!mst_w_fifo_empty[m] && (mst_w_fifo_dout[m] == NUM_SLV) ? dummy_w_ready : (!mst_w_fifo_empty[m] ? slv_resp[mst_w_fifo_dout[m]].w_ready : 1'b0));
            
            mst_resp[m].ar_ready = 1'b0;
            for (int s=0; s<=NUM_SLV; s++) begin
                if (ar_gnt_matrix[s][m] && slv_ar_ready[s]) mst_resp[m].ar_ready = 1'b1;
            end
            
            mst_resp[m].b_valid = (|b_req_matrix[m]) & rst_n;
            mst_resp[m].b = slv_resp[0].b; // Default
            for (int s=0; s<NUM_SLV; s++) begin
                if (b_gnt_matrix[m][s]) mst_resp[m].b = slv_resp[s].b;
            end
            if (b_gnt_matrix[m][NUM_SLV]) mst_resp[m].b.resp = 2'b11;
            mst_resp[m].b.id = '0;
            for (int s=0; s<=NUM_SLV; s++) begin
                if (b_gnt_matrix[m][s]) mst_resp[m].b.id = slv_b_id[s][SLV_ID_W-1:0];
            end
            
            mst_resp[m].r_valid = 1'b0;
            for (int s=0; s<=NUM_SLV; s++) begin
                if (r_gnt_matrix[m][s]) mst_resp[m].r_valid = 1'b1;
            end
            mst_resp[m].r_valid &= rst_n;
            
            mst_resp[m].r = slv_resp[0].r; // Default
            for (int s=0; s<NUM_SLV; s++) begin
                if (r_gnt_matrix[m][s]) mst_resp[m].r = slv_resp[s].r;
            end
            if (r_gnt_matrix[m][NUM_SLV]) begin
                mst_resp[m].r.resp = 2'b11;
                mst_resp[m].r.data = '0;
                mst_resp[m].r.last = dummy_r_last;
            end
            mst_resp[m].r.id = '0;
            for (int s=0; s<=NUM_SLV; s++) begin
                if (r_gnt_matrix[m][s]) mst_resp[m].r.id = slv_r_id[s][SLV_ID_W-1:0];
            end
        end
    end

    for (genvar s=0; s<NUM_SLV; s++) begin : g_slv_ready_b_r
        always_comb begin
            slv_req[s].b_ready = 1'b0;
            for (int m=0; m<NUM_MST; m++) begin
                if (b_gnt_matrix[m][s] && mst_req[m].b_ready) slv_req[s].b_ready = 1'b1;
            end
            
            slv_req[s].r_ready = 1'b0;
            for (int m=0; m<NUM_MST; m++) begin
                if (r_gnt_matrix[m][s] && mst_req[m].r_ready) slv_req[s].r_ready = 1'b1;
            end
        end
    end
    
    always_comb begin
        slv_b_ready[NUM_SLV] = 1'b0;
        for (int m=0; m<NUM_MST; m++) begin
            if (b_gnt_matrix[m][NUM_SLV] && mst_req[m].b_ready) slv_b_ready[NUM_SLV] = 1'b1;
        end
        slv_r_ready[NUM_SLV] = 1'b0;
        for (int m=0; m<NUM_MST; m++) begin
            if (r_gnt_matrix[m][NUM_SLV] && mst_req[m].r_ready) slv_r_ready[NUM_SLV] = 1'b1;
        end
    end

endmodule