import axi4_xbar_pkg::*;

module axi4_xbar #(
    parameter int NUM_MST   = 2,   
    parameter int NUM_SLV   = 2,   
    parameter int MAX_TRANS = 8,   
    parameter int MAX_BURST_LEN = 3 
) (
    input  logic clk,
    input  logic rst_n,

    input  slv_req_t  [NUM_MST-1:0] mst_req,
    output slv_resp_t [NUM_MST-1:0] mst_resp,

    output mst_req_t  [NUM_SLV-1:0] slv_req,
    input  mst_resp_t [NUM_SLV-1:0] slv_resp,

    input  xbar_rule_t [NUM_SLV-1:0] addr_map
);

    // =========================================================================
    // Module-Level Variable Declarations (T2 Compliance)
    // =========================================================================
    int m_aw, s_aw, i_aw, idx_aw;
    int m_w, s_w;
    int m_b, s_b, i_b, idx_b;
    int m_ar, s_ar, i_ar, idx_ar;
    int m_r, s_r, i_r, idx_r;
    int m_out, s_out, i_out;

    // =========================================================================
    // Skid Buffers for Master Inputs/Outputs
    // =========================================================================
    logic M_aw_valid[NUM_MST];
    logic M_aw_ready[NUM_MST];
    slv_aw_t M_aw[NUM_MST];

    logic M_w_valid[NUM_MST];
    logic M_w_ready[NUM_MST];
    w_t M_w[NUM_MST];

    logic M_ar_valid[NUM_MST];
    logic M_ar_ready[NUM_MST];
    slv_ar_t M_ar[NUM_MST];

    logic M_b_valid[NUM_MST];
    logic M_b_ready[NUM_MST];
    slv_b_t M_b[NUM_MST];

    logic M_r_valid[NUM_MST];
    logic M_r_ready[NUM_MST];
    slv_r_t M_r[NUM_MST];

    genvar g_m, g_s;
    generate
        for (g_m = 0; g_m < NUM_MST; g_m++) begin : gen_mst_skid
            // M_AW
            logic [2:0] aw_cnt;
            logic [1:0] aw_wptr, aw_rptr;
            slv_aw_t aw_mem[2];
            assign mst_resp[g_m].aw_ready = (aw_cnt < 2);
            assign M_aw_valid[g_m] = (aw_cnt > 0);
            assign M_aw[g_m] = aw_mem[aw_rptr[0]];

            always_ff @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    aw_wptr <= '0; aw_rptr <= '0; aw_cnt <= '0;
                end else begin
                    logic push, pop;
                    push = mst_req[g_m].aw_valid && (aw_cnt < 2);
                    pop  = M_aw_valid[g_m] && M_aw_ready[g_m];
                    if (push) begin aw_mem[aw_wptr[0]] <= mst_req[g_m].aw; aw_wptr <= aw_wptr + 1; end
                    if (pop) begin aw_rptr <= aw_rptr + 1; end
                    if (push && !pop) aw_cnt <= aw_cnt + 1;
                    else if (!push && pop) aw_cnt <= aw_cnt - 1;
                end
            end

            // M_W
            logic [2:0] w_cnt;
            logic [1:0] w_wptr, w_rptr;
            w_t w_mem[2];
            assign mst_resp[g_m].w_ready = (w_cnt < 2);
            assign M_w_valid[g_m] = (w_cnt > 0);
            assign M_w[g_m] = w_mem[w_rptr[0]];

            always_ff @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    w_wptr <= '0; w_rptr <= '0; w_cnt <= '0;
                end else begin
                    logic push, pop;
                    push = mst_req[g_m].w_valid && (w_cnt < 2);
                    pop  = M_w_valid[g_m] && M_w_ready[g_m];
                    if (push) begin w_mem[w_wptr[0]] <= mst_req[g_m].w; w_wptr <= w_wptr + 1; end
                    if (pop) begin w_rptr <= w_rptr + 1; end
                    if (push && !pop) w_cnt <= w_cnt + 1;
                    else if (!push && pop) w_cnt <= w_cnt - 1;
                end
            end

            // M_AR
            logic [2:0] ar_cnt;
            logic [1:0] ar_wptr, ar_rptr;
            slv_ar_t ar_mem[2];
            assign mst_resp[g_m].ar_ready = (ar_cnt < 2);
            assign M_ar_valid[g_m] = (ar_cnt > 0);
            assign M_ar[g_m] = ar_mem[ar_rptr[0]];

            always_ff @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    ar_wptr <= '0; ar_rptr <= '0; ar_cnt <= '0;
                end else begin
                    logic push, pop;
                    push = mst_req[g_m].ar_valid && (ar_cnt < 2);
                    pop  = M_ar_valid[g_m] && M_ar_ready[g_m];
                    if (push) begin ar_mem[ar_wptr[0]] <= mst_req[g_m].ar; ar_wptr <= ar_wptr + 1; end
                    if (pop) begin ar_rptr <= ar_rptr + 1; end
                    if (push && !pop) ar_cnt <= ar_cnt + 1;
                    else if (!push && pop) ar_cnt <= ar_cnt - 1;
                end
            end

            // M_B
            logic [2:0] b_cnt;
            logic [1:0] b_wptr, b_rptr;
            slv_b_t b_mem[2];
            assign M_b_ready[g_m] = (b_cnt < 2);
            assign mst_resp[g_m].b_valid = (b_cnt > 0);
            assign mst_resp[g_m].b = b_mem[b_rptr[0]];

            always_ff @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    b_wptr <= '0; b_rptr <= '0; b_cnt <= '0;
                end else begin
                    logic push, pop;
                    push = M_b_valid[g_m] && M_b_ready[g_m];
                    pop  = mst_resp[g_m].b_valid && mst_req[g_m].b_ready;
                    if (push) begin b_mem[b_wptr[0]] <= M_b[g_m]; b_wptr <= b_wptr + 1; end
                    if (pop) begin b_rptr <= b_rptr + 1; end
                    if (push && !pop) b_cnt <= b_cnt + 1;
                    else if (!push && pop) b_cnt <= b_cnt - 1;
                end
            end

            // M_R
            logic [2:0] r_cnt;
            logic [1:0] r_wptr, r_rptr;
            slv_r_t r_mem[2];
            assign M_r_ready[g_m] = (r_cnt < 2);
            assign mst_resp[g_m].r_valid = (r_cnt > 0);
            assign mst_resp[g_m].r = r_mem[r_rptr[0]];

            always_ff @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    r_wptr <= '0; r_rptr <= '0; r_cnt <= '0;
                end else begin
                    logic push, pop;
                    push = M_r_valid[g_m] && M_r_ready[g_m];
                    pop  = mst_resp[g_m].r_valid && mst_req[g_m].r_ready;
                    if (push) begin r_mem[r_wptr[0]] <= M_r[g_m]; r_wptr <= r_wptr + 1; end
                    if (pop) begin r_rptr <= r_rptr + 1; end
                    if (push && !pop) r_cnt <= r_cnt + 1;
                    else if (!push && pop) r_cnt <= r_cnt - 1;
                end
            end
        end
    endgenerate

    // =========================================================================
    // Address Decoding & Routing
    // =========================================================================
    logic [$clog2(NUM_SLV+1)-1:0] aw_target[NUM_MST];
    logic [$clog2(NUM_SLV+1)-1:0] ar_target[NUM_MST];

    always_comb begin
        for (m_out = 0; m_out < NUM_MST; m_out++) begin
            aw_target[m_out] = NUM_SLV; 
            ar_target[m_out] = NUM_SLV; 
            for (i_out = 0; i_out < NUM_SLV; i_out++) begin
                if (M_aw[m_out].addr >= addr_map[i_out].start_addr && M_aw[m_out].addr < addr_map[i_out].end_addr) begin
                    aw_target[m_out] = addr_map[i_out].mst_port;
                end
                if (M_ar[m_out].addr >= addr_map[i_out].start_addr && M_ar[m_out].addr < addr_map[i_out].end_addr) begin
                    ar_target[m_out] = addr_map[i_out].mst_port;
                end
            end
        end
    end

    // =========================================================================
    // Transaction Tracking & Ordering
    // =========================================================================
    logic [4:0] aw_out_cnt [NUM_MST][16];
    logic [$clog2(NUM_SLV+1)-1:0] aw_out_target [NUM_MST][16];
    logic [4:0] aw_total_cnt [NUM_MST];

    logic [4:0] ar_out_cnt [NUM_MST][16];
    logic [$clog2(NUM_SLV+1)-1:0] ar_out_target [NUM_MST][16];
    logic [4:0] ar_total_cnt [NUM_MST];

    // =========================================================================
    // Routing Tracking FIFOs
    // =========================================================================
    typedef struct packed {
        logic [$clog2(NUM_SLV+1)-1:0] target;
        slv_id_t id;
    } m_w_target_t;

    m_w_target_t m_w_target_data[NUM_MST];
    logic m_w_target_valid[NUM_MST];
    logic m_w_target_ready[NUM_MST];
    logic pop_m_w_target[NUM_MST];

    slv_id_t m_decerr_b_data[NUM_MST];
    logic m_decerr_b_valid[NUM_MST];
    logic m_decerr_b_ready[NUM_MST];
    logic pop_m_decerr_b[NUM_MST];

    typedef struct packed {
        slv_id_t id;
        logic [7:0] len;
    } decerr_ar_t;

    decerr_ar_t m_decerr_ar_data[NUM_MST];
    logic m_decerr_ar_valid[NUM_MST];
    logic m_decerr_ar_ready[NUM_MST];
    logic pop_m_decerr_ar[NUM_MST];

    logic [$clog2(NUM_MST)-1:0] s_w_arb_data[NUM_SLV];
    logic s_w_arb_valid[NUM_SLV];
    logic s_w_arb_ready[NUM_SLV];
    logic pop_s_w_arb[NUM_SLV];
    logic push_s_w_arb[NUM_SLV];
    logic [$clog2(NUM_MST)-1:0] s_w_arb_din[NUM_SLV];

    logic m_aw_accepted[NUM_MST];
    logic m_ar_accepted[NUM_MST];

    generate
        for (g_m = 0; g_m < NUM_MST; g_m++) begin : gen_m_track
            // m_w_target_fifo
            logic [5:0] w_tgt_cnt;
            logic [4:0] w_tgt_wptr, w_tgt_rptr;
            m_w_target_t w_tgt_mem [32]; // Max depth 32
            
            logic push_w_tgt;
            m_w_target_t w_tgt_din;
            assign push_w_tgt = m_aw_accepted[g_m];
            assign w_tgt_din = '{target: aw_target[g_m], id: M_aw[g_m].id};
            
            assign m_w_target_ready[g_m] = (w_tgt_cnt < 32);
            assign m_w_target_valid[g_m] = (w_tgt_cnt > 0);
            assign m_w_target_data[g_m] = w_tgt_mem[w_tgt_rptr];
            
            always_ff @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    w_tgt_wptr <= '0; w_tgt_rptr <= '0; w_tgt_cnt <= '0;
                end else begin
                    logic push, pop;
                    push = push_w_tgt && m_w_target_ready[g_m];
                    pop  = pop_m_w_target[g_m] && m_w_target_valid[g_m];
                    if (push) begin w_tgt_mem[w_tgt_wptr] <= w_tgt_din; w_tgt_wptr <= (w_tgt_wptr == 31) ? 0 : w_tgt_wptr + 1; end
                    if (pop) begin w_tgt_rptr <= (w_tgt_rptr == 31) ? 0 : w_tgt_rptr + 1; end
                    if (push && !pop) w_tgt_cnt <= w_tgt_cnt + 1;
                    else if (!push && pop) w_tgt_cnt <= w_tgt_cnt - 1;
                end
            end

            // m_decerr_b_fifo
            logic [5:0] db_cnt;
            logic [4:0] db_wptr, db_rptr;
            slv_id_t db_mem [32];
            
            logic push_db;
            slv_id_t db_din;
            assign push_db = m_w_target_valid[g_m] && m_w_target_data[g_m].target == NUM_SLV && M_w_ready[g_m] && M_w[g_m].last;
            assign db_din = m_w_target_data[g_m].id;
            
            assign m_decerr_b_ready[g_m] = (db_cnt < 32);
            assign m_decerr_b_valid[g_m] = (db_cnt > 0);
            assign m_decerr_b_data[g_m] = db_mem[db_rptr];
            
            always_ff @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    db_wptr <= '0; db_rptr <= '0; db_cnt <= '0;
                end else begin
                    logic push, pop;
                    push = push_db && m_decerr_b_ready[g_m];
                    pop  = pop_m_decerr_b[g_m] && m_decerr_b_valid[g_m];
                    if (push) begin db_mem[db_wptr] <= db_din; db_wptr <= (db_wptr == 31) ? 0 : db_wptr + 1; end
                    if (pop) begin db_rptr <= (db_rptr == 31) ? 0 : db_rptr + 1; end
                    if (push && !pop) db_cnt <= db_cnt + 1;
                    else if (!push && pop) db_cnt <= db_cnt - 1;
                end
            end
            
            // m_decerr_ar_fifo
            logic [5:0] dar_cnt;
            logic [4:0] dar_wptr, dar_rptr;
            decerr_ar_t dar_mem [32];
            
            logic push_dar;
            decerr_ar_t dar_din;
            assign push_dar = m_ar_accepted[g_m] && ar_target[g_m] == NUM_SLV;
            assign dar_din = '{id: M_ar[g_m].id, len: M_ar[g_m].len};
            
            assign m_decerr_ar_ready[g_m] = (dar_cnt < 32);
            assign m_decerr_ar_valid[g_m] = (dar_cnt > 0);
            assign m_decerr_ar_data[g_m] = dar_mem[dar_rptr];
            
            always_ff @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    dar_wptr <= '0; dar_rptr <= '0; dar_cnt <= '0;
                end else begin
                    logic push, pop;
                    push = push_dar && m_decerr_ar_ready[g_m];
                    pop  = pop_m_decerr_ar[g_m] && m_decerr_ar_valid[g_m];
                    if (push) begin dar_mem[dar_wptr] <= dar_din; dar_wptr <= (dar_wptr == 31) ? 0 : dar_wptr + 1; end
                    if (pop) begin dar_rptr <= (dar_rptr == 31) ? 0 : dar_rptr + 1; end
                    if (push && !pop) dar_cnt <= dar_cnt + 1;
                    else if (!push && pop) dar_cnt <= dar_cnt - 1;
                end
            end
        end

        for (g_s = 0; g_s < NUM_SLV; g_s++) begin : gen_s_track
            // s_w_arb_fifo
            logic [6:0] sw_cnt;
            logic [5:0] sw_wptr, sw_rptr;
            logic [$clog2(NUM_MST)-1:0] sw_mem [64];
            
            assign s_w_arb_ready[g_s] = (sw_cnt < 64);
            assign s_w_arb_valid[g_s] = (sw_cnt > 0);
            assign s_w_arb_data[g_s] = sw_mem[sw_rptr];
            
            always_ff @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    sw_wptr <= '0; sw_rptr <= '0; sw_cnt <= '0;
                end else begin
                    logic push, pop;
                    push = push_s_w_arb[g_s] && s_w_arb_ready[g_s];
                    pop  = pop_s_w_arb[g_s] && s_w_arb_valid[g_s];
                    if (push) begin sw_mem[sw_wptr] <= s_w_arb_din[g_s]; sw_wptr <= (sw_wptr == 63) ? 0 : sw_wptr + 1; end
                    if (pop) begin sw_rptr <= (sw_rptr == 63) ? 0 : sw_rptr + 1; end
                    if (push && !pop) sw_cnt <= sw_cnt + 1;
                    else if (!push && pop) sw_cnt <= sw_cnt - 1;
                end
            end
        end
    endgenerate

    // =========================================================================
    // AW Routing & Arbitration
    // =========================================================================
    logic aw_req [NUM_MST][NUM_SLV+1];
    logic [$clog2(NUM_MST)-1:0] aw_rr_ptr[NUM_SLV];
    logic aw_gnt [NUM_MST][NUM_SLV];
    logic aw_gnt_decerr[NUM_MST];

    always_comb begin
        for (m_aw = 0; m_aw < NUM_MST; m_aw++) begin
            for (s_aw = 0; s_aw <= NUM_SLV; s_aw++) aw_req[m_aw][s_aw] = 1'b0;
            if (M_aw_valid[m_aw]) begin
                int tgt = aw_target[m_aw];
                if (aw_out_cnt[m_aw][M_aw[m_aw].id] == 0 || aw_out_target[m_aw][M_aw[m_aw].id] == tgt) begin
                    if (aw_total_cnt[m_aw] < MAX_TRANS) begin
                        aw_req[m_aw][tgt] = 1'b1;
                    end
                end
            end
        end

        for (s_aw = 0; s_aw < NUM_SLV; s_aw++) begin
            for (m_aw = 0; m_aw < NUM_MST; m_aw++) aw_gnt[m_aw][s_aw] = 1'b0;
            for (i_aw = 0; i_aw < NUM_MST; i_aw++) begin
                int idx = (aw_rr_ptr[s_aw] + i_aw) % NUM_MST;
                if (aw_req[idx][s_aw] && m_w_target_ready[idx] && s_w_arb_ready[s_aw]) begin
                    aw_gnt[idx][s_aw] = 1'b1;
                    break;
                end
            end
        end

        for (m_aw = 0; m_aw < NUM_MST; m_aw++) begin
            aw_gnt_decerr[m_aw] = 1'b0;
            if (aw_req[m_aw][NUM_SLV] && m_w_target_ready[m_aw]) begin
                aw_gnt_decerr[m_aw] = 1'b1;
            end
        end

        for (m_aw = 0; m_aw < NUM_MST; m_aw++) begin
            m_aw_accepted[m_aw] = 1'b0;
            int tgt = aw_target[m_aw];
            if (aw_req[m_aw][tgt]) begin
                if (tgt < NUM_SLV) begin
                    if (aw_gnt[m_aw][tgt] && slv_resp[tgt].aw_ready) m_aw_accepted[m_aw] = 1'b1;
                end else begin
                    if (aw_gnt_decerr[m_aw]) m_aw_accepted[m_aw] = 1'b1;
                end
            end
            M_aw_ready[m_aw] = m_aw_accepted[m_aw];
        end

        for (s_aw = 0; s_aw < NUM_SLV; s_aw++) begin
            slv_req[s_aw].aw_valid = 1'b0;
            slv_req[s_aw].aw = '0;
            push_s_w_arb[s_aw] = 1'b0;
            s_w_arb_din[s_aw] = '0;
            for (m_aw = 0; m_aw < NUM_MST; m_aw++) begin
                if (aw_gnt[m_aw][s_aw]) begin
                    slv_req[s_aw].aw_valid = 1'b1;
                    slv_req[s_aw].aw.id = { MST_IDX_W'(m_aw), M_aw[m_aw].id };
                    slv_req[s_aw].aw.addr = M_aw[m_aw].addr;
                    slv_req[s_aw].aw.len = M_aw[m_aw].len;
                    slv_req[s_aw].aw.size = M_aw[m_aw].size;
                    slv_req[s_aw].aw.burst = M_aw[m_aw].burst;
                    slv_req[s_aw].aw.lock = M_aw[m_aw].lock;
                    slv_req[s_aw].aw.cache = M_aw[m_aw].cache;
                    slv_req[s_aw].aw.prot = M_aw[m_aw].prot;
                    slv_req[s_aw].aw.qos = M_aw[m_aw].qos;
                    slv_req[s_aw].aw.region = M_aw[m_aw].region;
                    slv_req[s_aw].aw.atop = '0;
                    slv_req[s_aw].aw.user = M_aw[m_aw].user;
                    if (m_aw_accepted[m_aw]) begin
                        push_s_w_arb[s_aw] = 1'b1;
                        s_w_arb_din[s_aw] = m_aw[$clog2(NUM_MST)-1:0];
                    end
                end
            end
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int s = 0; s < NUM_SLV; s++) aw_rr_ptr[s] <= '0;
        end else begin
            for (int s = 0; s < NUM_SLV; s++) begin
                for (int m = 0; m < NUM_MST; m++) begin
                    if (aw_gnt[m][s] && m_aw_accepted[m]) begin
                        aw_rr_ptr[s] <= (m + 1) % NUM_MST;
                    end
                end
            end
        end
    end

    // =========================================================================
    // W Routing
    // =========================================================================
    always_comb begin
        for (m_w = 0; m_w < NUM_MST; m_w++) M_w_ready[m_w] = 1'b0;
        for (s_w = 0; s_w < NUM_SLV; s_w++) begin
            slv_req[s_w].w_valid = 1'b0;
            slv_req[s_w].w = '0;
            pop_s_w_arb[s_w] = 1'b0;
        end
        for (m_w = 0; m_w < NUM_MST; m_w++) pop_m_w_target[m_w] = 1'b0;

        for (s_w = 0; s_w < NUM_SLV; s_w++) begin
            if (s_w_arb_valid[s_w]) begin
                int exp_m = s_w_arb_data[s_w];
                if (m_w_target_valid[exp_m] && m_w_target_data[exp_m].target == s_w) begin
                    if (M_w_valid[exp_m]) begin
                        slv_req[s_w].w_valid = 1'b1;
                        slv_req[s_w].w = M_w[exp_m];
                        if (slv_resp[s_w].w_ready) begin
                            M_w_ready[exp_m] = 1'b1;
                            if (M_w[exp_m].last) begin
                                pop_m_w_target[exp_m] = 1'b1;
                                pop_s_w_arb[s_w] = 1'b1;
                            end
                        end
                    end
                end
            end
        end

        for (m_w = 0; m_w < NUM_MST; m_w++) begin
            if (m_w_target_valid[m_w] && m_w_target_data[m_w].target == NUM_SLV) begin
                if (M_w_valid[m_w]) begin
                    if (!M_w[m_w].last || m_decerr_b_ready[m_w]) begin
                        M_w_ready[m_w] = 1'b1;
                        if (M_w[m_w].last) begin
                            pop_m_w_target[m_w] = 1'b1;
                        end
                    end
                end
            end
        end
    end

    // =========================================================================
    // AR Routing & Arbitration
    // =========================================================================
    logic ar_req [NUM_MST][NUM_SLV+1];
    logic [$clog2(NUM_MST)-1:0] ar_rr_ptr[NUM_SLV];
    logic ar_gnt [NUM_MST][NUM_SLV];
    logic ar_gnt_decerr[NUM_MST];

    always_comb begin
        for (m_ar = 0; m_ar < NUM_MST; m_ar++) begin
            for (s_ar = 0; s_ar <= NUM_SLV; s_ar++) ar_req[m_ar][s_ar] = 1'b0;
            if (M_ar_valid[m_ar]) begin
                int tgt = ar_target[m_ar];
                if (ar_out_cnt[m_ar][M_ar[m_ar].id] == 0 || ar_out_target[m_ar][M_ar[m_ar].id] == tgt) begin
                    if (ar_total_cnt[m_ar] < MAX_TRANS) begin
                        ar_req[m_ar][tgt] = 1'b1;
                    end
                end
            end
        end

        for (s_ar = 0; s_ar < NUM_SLV; s_ar++) begin
            for (m_ar = 0; m_ar < NUM_MST; m_ar++) ar_gnt[m_ar][s_ar] = 1'b0;
            for (i_ar = 0; i_ar < NUM_MST; i_ar++) begin
                int idx = (ar_rr_ptr[s_ar] + i_ar) % NUM_MST;
                if (ar_req[idx][s_ar]) begin
                    ar_gnt[idx][s_ar] = 1'b1;
                    break;
                end
            end
        end

        for (m_ar = 0; m_ar < NUM_MST; m_ar++) begin
            ar_gnt_decerr[m_ar] = 1'b0;
            if (ar_req[m_ar][NUM_SLV] && m_decerr_ar_ready[m_ar]) begin
                ar_gnt_decerr[m_ar] = 1'b1;
            end
        end

        for (m_ar = 0; m_ar < NUM_MST; m_ar++) begin
            m_ar_accepted[m_ar] = 1'b0;
            int tgt = ar_target[m_ar];
            if (ar_req[m_ar][tgt]) begin
                if (tgt < NUM_SLV) begin
                    if (ar_gnt[m_ar][tgt] && slv_resp[tgt].ar_ready) m_ar_accepted[m_ar] = 1'b1;
                end else begin
                    if (ar_gnt_decerr[m_ar]) m_ar_accepted[m_ar] = 1'b1;
                end
            end
            M_ar_ready[m_ar] = m_ar_accepted[m_ar];
        end

        for (s_ar = 0; s_ar < NUM_SLV; s_ar++) begin
            slv_req[s_ar].ar_valid = 1'b0;
            slv_req[s_ar].ar = '0;
            for (m_ar = 0; m_ar < NUM_MST; m_ar++) begin
                if (ar_gnt[m_ar][s_ar]) begin
                    slv_req[s_ar].ar_valid = 1'b1;
                    slv_req[s_ar].ar.id = { MST_IDX_W'(m_ar), M_ar[m_ar].id };
                    slv_req[s_ar].ar.addr = M_ar[m_ar].addr;
                    slv_req[s_ar].ar.len = M_ar[m_ar].len;
                    slv_req[s_ar].ar.size = M_ar[m_ar].size;
                    slv_req[s_ar].ar.burst = M_ar[m_ar].burst;
                    slv_req[s_ar].ar.lock = M_ar[m_ar].lock;
                    slv_req[s_ar].ar.cache = M_ar[m_ar].cache;
                    slv_req[s_ar].ar.prot = M_ar[m_ar].prot;
                    slv_req[s_ar].ar.qos = M_ar[m_ar].qos;
                    slv_req[s_ar].ar.region = M_ar[m_ar].region;
                    slv_req[s_ar].ar.user = M_ar[m_ar].user;
                end
            end
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int s = 0; s < NUM_SLV; s++) ar_rr_ptr[s] <= '0;
        end else begin
            for (int s = 0; s < NUM_SLV; s++) begin
                for (int m = 0; m < NUM_MST; m++) begin
                    if (ar_gnt[m][s] && m_ar_accepted[m]) begin
                        ar_rr_ptr[s] <= (m + 1) % NUM_MST;
                    end
                end
            end
        end
    end

    // =========================================================================
    // DECERR R Response Generation
    // =========================================================================
    logic m_decerr_r_active[NUM_MST];
    logic [7:0] m_decerr_r_cnt[NUM_MST];
    logic m_decerr_r_valid[NUM_MST];
    logic m_decerr_r_last[NUM_MST];
    slv_id_t m_decerr_r_id[NUM_MST];
    logic pop_m_decerr_r[NUM_MST];

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int m = 0; m < NUM_MST; m++) begin
                m_decerr_r_active[m] <= 1'b0;
                m_decerr_r_cnt[m] <= '0;
            end
        end else begin
            for (int m = 0; m < NUM_MST; m++) begin
                if (m_decerr_r_active[m]) begin
                    if (pop_m_decerr_r[m]) begin
                        if (m_decerr_r_cnt[m] == 0) begin
                            m_decerr_r_active[m] <= 1'b0;
                        end else begin
                            m_decerr_r_cnt[m] <= m_decerr_r_cnt[m] - 1;
                        end
                    end
                end else begin
                    if (m_decerr_ar_valid[m]) begin
                        m_decerr_r_active[m] <= 1'b1;
                        m_decerr_r_cnt[m] <= m_decerr_ar_data[m].len;
                    end
                end
            end
        end
    end

    always_comb begin
        for (int m = 0; m < NUM_MST; m++) begin
            m_decerr_r_valid[m] = m_decerr_r_active[m];
            m_decerr_r_last[m]  = (m_decerr_r_cnt[m] == 0);
            m_decerr_r_id[m]    = m_decerr_ar_data[m].id;
            pop_m_decerr_ar[m]  = m_decerr_r_active[m] && pop_m_decerr_r[m] && m_decerr_r_last[m];
        end
    end

    // =========================================================================
    // B Routing & Arbitration
    // =========================================================================
    logic b_req[NUM_MST][NUM_SLV+1];
    mst_b_t b_data[NUM_MST][NUM_SLV+1];
    logic [$clog2(NUM_SLV+1)-1:0] b_rr_ptr[NUM_MST];
    logic b_gnt[NUM_MST][NUM_SLV+1];
    logic m_b_accepted[NUM_MST];
    logic [3:0] pop_b_id[NUM_MST];

    always_comb begin
        for (m_b = 0; m_b < NUM_MST; m_b++) begin
            for (s_b = 0; s_b <= NUM_SLV; s_b++) begin
                b_req[m_b][s_b] = 1'b0;
                b_data[m_b][s_b] = '0;
                b_gnt[m_b][s_b] = 1'b0;
            end
            
            for (s_b = 0; s_b < NUM_SLV; s_b++) begin
                if (slv_resp[s_b].b_valid) begin
                    int dst_m = slv_resp[s_b].b.id[SLV_ID_W + MST_IDX_W - 1 : SLV_ID_W];
                    if (dst_m == m_b) begin
                        b_req[m_b][s_b] = 1'b1;
                        b_data[m_b][s_b] = slv_resp[s_b].b;
                    end
                end
            end
            
            if (m_decerr_b_valid[m_b]) begin
                b_req[m_b][NUM_SLV] = 1'b1;
                b_data[m_b][NUM_SLV].id = '0;
                b_data[m_b][NUM_SLV].resp = RESP_DECERR;
                b_data[m_b][NUM_SLV].user = '0;
            end

            M_b_valid[m_b] = 1'b0;
            M_b[m_b] = '0;
            pop_b_id[m_b] = '0;
            m_b_accepted[m_b] = 1'b0;
            pop_m_decerr_b[m_b] = 1'b0;
            
            for (i_b = 0; i_b <= NUM_SLV; i_b++) begin
                int idx = (b_rr_ptr[m_b] + i_b) % (NUM_SLV + 1);
                if (b_req[m_b][idx]) begin
                    b_gnt[m_b][idx] = 1'b1;
                    M_b_valid[m_b] = 1'b1;
                    if (idx < NUM_SLV) begin
                        M_b[m_b].id = b_data[m_b][idx].id[SLV_ID_W-1:0];
                        M_b[m_b].resp = b_data[m_b][idx].resp;
                        M_b[m_b].user = b_data[m_b][idx].user;
                    end else begin
                        M_b[m_b].id = m_decerr_b_data[m_b];
                        M_b[m_b].resp = RESP_DECERR;
                        M_b[m_b].user = '0;
                    end
                    pop_b_id[m_b] = M_b[m_b].id;
                    if (M_b_ready[m_b]) begin
                        m_b_accepted[m_b] = 1'b1;
                        if (idx == NUM_SLV) pop_m_decerr_b[m_b] = 1'b1;
                    end
                    break;
                end
            end
        end

        for (s_b = 0; s_b < NUM_SLV; s_b++) begin
            slv_req[s_b].b_ready = 1'b0;
            if (slv_resp[s_b].b_valid) begin
                int dst_m = slv_resp[s_b].b.id[SLV_ID_W + MST_IDX_W - 1 : SLV_ID_W];
                if (dst_m < NUM_MST && b_gnt[dst_m][s_b] && M_b_ready[dst_m]) begin
                    slv_req[s_b].b_ready = 1'b1;
                end
            end
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int m = 0; m < NUM_MST; m++) b_rr_ptr[m] <= '0;
        end else begin
            for (int m = 0; m < NUM_MST; m++) begin
                if (m_b_accepted[m]) begin
                    for (int s = 0; s <= NUM_SLV; s++) begin
                        if (b_gnt[m][s]) b_rr_ptr[m] <= (s + 1) % (NUM_SLV + 1);
                    end
                end
            end
        end
    end

    // =========================================================================
    // R Routing & Arbitration
    // =========================================================================
    logic r_req[NUM_MST][NUM_SLV+1];
    mst_r_t r_data[NUM_MST][NUM_SLV+1];
    logic [$clog2(NUM_SLV+1)-1:0] r_rr_ptr[NUM_MST];
    logic r_gnt[NUM_MST][NUM_SLV+1];
    logic m_r_accepted[NUM_MST];
    logic m_r_accepted_last[NUM_MST];
    logic [3:0] pop_r_id[NUM_MST];
    logic r_lock[NUM_MST];
    logic [$clog2(NUM_SLV+1)-1:0] r_lock_src[NUM_MST];

    always_comb begin
        for (m_r = 0; m_r < NUM_MST; m_r++) begin
            for (s_r = 0; s_r <= NUM_SLV; s_r++) begin
                r_req[m_r][s_r] = 1'b0;
                r_data[m_r][s_r] = '0;
                r_gnt[m_r][s_r] = 1'b0;
            end
            
            for (s_r = 0; s_r < NUM_SLV; s_r++) begin
                if (slv_resp[s_r].r_valid) begin
                    int dst_m = slv_resp[s_r].r.id[SLV_ID_W + MST_IDX_W - 1 : SLV_ID_W];
                    if (dst_m == m_r) begin
                        r_req[m_r][s_r] = 1'b1;
                        r_data[m_r][s_r] = slv_resp[s_r].r;
                    end
                end
            end
            
            if (m_decerr_r_valid[m_r]) begin
                r_req[m_r][NUM_SLV] = 1'b1;
                r_data[m_r][NUM_SLV].id = '0;
                r_data[m_r][NUM_SLV].data = '0;
                r_data[m_r][NUM_SLV].resp = RESP_DECERR;
                r_data[m_r][NUM_SLV].last = m_decerr_r_last[m_r];
                r_data[m_r][NUM_SLV].user = '0;
            end

            M_r_valid[m_r] = 1'b0;
            M_r[m_r] = '0;
            pop_r_id[m_r] = '0;
            m_r_accepted[m_r] = 1'b0;
            m_r_accepted_last[m_r] = 1'b0;
            pop_m_decerr_r[m_r] = 1'b0;
            
            if (r_lock[m_r]) begin
                int src = r_lock_src[m_r];
                if (r_req[m_r][src]) begin
                    r_gnt[m_r][src] = 1'b1;
                    M_r_valid[m_r] = 1'b1;
                    if (src < NUM_SLV) begin
                        M_r[m_r].id = r_data[m_r][src].id[SLV_ID_W-1:0];
                        M_r[m_r].data = r_data[m_r][src].data;
                        M_r[m_r].resp = r_data[m_r][src].resp;
                        M_r[m_r].last = r_data[m_r][src].last;
                        M_r[m_r].user = r_data[m_r][src].user;
                    end else begin
                        M_r[m_r].id = m_decerr_r_id[m_r];
                        M_r[m_r].data = '0;
                        M_r[m_r].resp = RESP_DECERR;
                        M_r[m_r].last = r_data[m_r][src].last;
                        M_r[m_r].user = '0;
                    end
                    pop_r_id[m_r] = M_r[m_r].id;
                    if (M_r_ready[m_r]) begin
                        m_r_accepted[m_r] = 1'b1;
                        if (M_r[m_r].last) m_r_accepted_last[m_r] = 1'b1;
                        if (src == NUM_SLV) pop_m_decerr_r[m_r] = 1'b1;
                    end
                end
            end else begin
                for (i_r = 0; i_r <= NUM_SLV; i_r++) begin
                    int idx = (r_rr_ptr[m_r] + i_r) % (NUM_SLV + 1);
                    if (r_req[m_r][idx]) begin
                        r_gnt[m_r][idx] = 1'b1;
                        M_r_valid[m_r] = 1'b1;
                        if (idx < NUM_SLV) begin
                            M_r[m_r].id = r_data[m_r][idx].id[SLV_ID_W-1:0];
                            M_r[m_r].data = r_data[m_r][idx].data;
                            M_r[m_r].resp = r_data[m_r][idx].resp;
                            M_r[m_r].last = r_data[m_r][idx].last;
                            M_r[m_r].user = r_data[m_r][idx].user;
                        end else begin
                            M_r[m_r].id = m_decerr_r_id[m_r];
                            M_r[m_r].data = '0;
                            M_r[m_r].resp = RESP_DECERR;
                            M_r[m_r].last = r_data[m_r][idx].last;
                            M_r[m_r].user = '0;
                        end
                        pop_r_id[m_r] = M_r[m_r].id;
                        if (M_r_ready[m_r]) begin
                            m_r_accepted[m_r] = 1'b1;
                            if (M_r[m_r].last) m_r_accepted_last[m_r] = 1'b1;
                            if (idx == NUM_SLV) pop_m_decerr_r[m_r] = 1'b1;
                        end
                        break;
                    end
                end
            end
        end

        for (s_r = 0; s_r < NUM_SLV; s_r++) begin
            slv_req[s_r].r_ready = 1'b0;
            if (slv_resp[s_r].r_valid) begin
                int dst_m = slv_resp[s_r].r.id[SLV_ID_W + MST_IDX_W - 1 : SLV_ID_W];
                if (dst_m < NUM_MST && r_gnt[dst_m][s_r] && M_r_ready[dst_m]) begin
                    slv_req[s_r].r_ready = 1'b1;
                end
            end
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int m = 0; m < NUM_MST; m++) begin
                r_rr_ptr[m] <= '0;
                r_lock[m] <= 1'b0;
                r_lock_src[m] <= '0;
            end
        end else begin
            for (int m = 0; m < NUM_MST; m++) begin
                if (m_r_accepted[m]) begin
                    for (int s = 0; s <= NUM_SLV; s++) begin
                        if (r_gnt[m][s]) begin
                            if (!M_r[m].last) begin
                                r_lock[m] <= 1'b1;
                                r_lock_src[m] <= s[$clog2(NUM_SLV+1)-1:0];
                            end else begin
                                r_lock[m] <= 1'b0;
                                r_rr_ptr[m] <= (s + 1) % (NUM_SLV + 1);
                            end
                        end
                    end
                end
            end
        end
    end

    // =========================================================================
    // Master Outstanding Tracking State Update
    // =========================================================================
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int m = 0; m < NUM_MST; m++) begin
                aw_total_cnt[m] <= '0;
                ar_total_cnt[m] <= '0;
                for (int i = 0; i < 16; i++) begin
                    aw_out_cnt[m][i] <= '0;
                    ar_out_cnt[m][i] <= '0;
                    aw_out_target[m][i] <= '0;
                    ar_out_target[m][i] <= '0;
                end
            end
        end else begin
            for (int m = 0; m < NUM_MST; m++) begin
                // AW Tracking
                logic push_aw; logic pop_aw;
                logic [3:0] push_aw_id; logic [3:0] pop_aw_id;
                push_aw = m_aw_accepted[m];
                pop_aw  = m_b_accepted[m];
                push_aw_id = M_aw[m].id;
                pop_aw_id  = pop_b_id[m];
                
                if (push_aw && !pop_aw) aw_total_cnt[m] <= aw_total_cnt[m] + 1;
                else if (!push_aw && pop_aw) aw_total_cnt[m] <= aw_total_cnt[m] - 1;
                
                if (push_aw) aw_out_target[m][push_aw_id] <= aw_target[m];
                
                if (push_aw && pop_aw && push_aw_id == pop_aw_id) begin
                    // unchanged
                end else begin
                    if (push_aw) aw_out_cnt[m][push_aw_id] <= aw_out_cnt[m][push_aw_id] + 1;
                    if (pop_aw)  aw_out_cnt[m][pop_aw_id]  <= aw_out_cnt[m][pop_aw_id] - 1;
                end

                // AR Tracking
                logic push_ar; logic pop_ar;
                logic [3:0] push_ar_id; logic [3:0] pop_ar_id;
                push_ar = m_ar_accepted[m];
                pop_ar  = m_r_accepted_last[m];
                push_ar_id = M_ar[m].id;
                pop_ar_id  = pop_r_id[m];
                
                if (push_ar && !pop_ar) ar_total_cnt[m] <= ar_total_cnt[m] + 1;
                else if (!push_ar && pop_ar) ar_total_cnt[m] <= ar_total_cnt[m] - 1;
                
                if (push_ar) ar_out_target[m][push_ar_id] <= ar_target[m];
                
                if (push_ar && pop_ar && push_ar_id == pop_ar_id) begin
                    // unchanged
                end else begin
                    if (push_ar) ar_out_cnt[m][push_ar_id] <= ar_out_cnt[m][push_ar_id] + 1;
                    if (pop_ar)  ar_out_cnt[m][pop_ar_id]  <= ar_out_cnt[m][pop_ar_id] - 1;
                end
            end
        end
    end

endmodule