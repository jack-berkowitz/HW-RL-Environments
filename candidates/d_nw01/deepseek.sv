`timescale 1ns/1ps

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

    input  slv_req_t  [NUM_MST-1:0] mst_req,
    output slv_resp_t [NUM_MST-1:0] mst_resp,

    output mst_req_t  [NUM_SLV-1:0] slv_req,
    input  mst_resp_t [NUM_SLV-1:0] slv_resp,

    input  xbar_rule_t [NUM_SLV-1:0] addr_map
);

    // -------------------------------------------------------------------------
    // Local parameters
    // -------------------------------------------------------------------------
    localparam int IDX_W     = $clog2(NUM_MST);
    localparam int SLV_IDX_W = $clog2(NUM_SLV);
    localparam int NUM_IDS   = 1 << SLV_ID_W;

    localparam int CMD_DEPTH  = MAX_TRANS;
    localparam int CMD_PTR_W  = $clog2(CMD_DEPTH);
    localparam int CMD_CNT_W  = $clog2(CMD_DEPTH + 1);

    localparam int W_DEPTH    = MAX_TRANS * (MAX_BURST_LEN + 1);
    localparam int W_PTR_W    = $clog2(W_DEPTH);
    localparam int W_CNT_W    = $clog2(W_DEPTH + 1);

    localparam int DEST_W     = $clog2(NUM_SLV + 1);      // 0..NUM_SLV-1 valid, NUM_SLV means decode error
    localparam int INVALID_DEST = NUM_SLV;

    localparam int RESP_SRC_W = $clog2(NUM_SLV + 1);      // response source: slaves + error

    // -------------------------------------------------------------------------
    // Types
    // -------------------------------------------------------------------------
    typedef struct packed {
        logic [DEST_W-1:0] dest;
        slv_aw_t           aw;
    } aw_cmd_t;

    typedef struct packed {
        logic [DEST_W-1:0] dest;
        slv_ar_t           ar;
    } ar_cmd_t;

    typedef struct packed {
        logic [DEST_W-1:0] dest;
        w_t                w;
    } w_cmd_t;

    typedef struct packed {
        slv_id_t id;
        logic [1:0] resp;
        user_t  user;
    } werr_entry_t;

    typedef struct packed {
        slv_id_t id;
        logic [7:0] len;
        user_t  user;
    } rerr_desc_t;

    // -------------------------------------------------------------------------
    // FIFO memories
    // -------------------------------------------------------------------------
    aw_cmd_t  aw_mem [NUM_MST][CMD_DEPTH];
    ar_cmd_t  ar_mem [NUM_MST][CMD_DEPTH];
    w_cmd_t   w_mem  [NUM_MST][W_DEPTH];

    logic [CMD_PTR_W-1:0] aw_wr [NUM_MST];
    logic [CMD_PTR_W-1:0] aw_rd [NUM_MST];
    logic [CMD_CNT_W-1:0] aw_cnt [NUM_MST];

    logic [CMD_PTR_W-1:0] ar_wr [NUM_MST];
    logic [CMD_PTR_W-1:0] ar_rd [NUM_MST];
    logic [CMD_CNT_W-1:0] ar_cnt [NUM_MST];

    logic [W_PTR_W-1:0] w_wr [NUM_MST];
    logic [W_PTR_W-1:0] w_rd [NUM_MST];
    logic [W_CNT_W-1:0] w_cnt [NUM_MST];

    // Write destination queue (one entry per accepted AW)
    logic [DEST_W-1:0] aw_dest_q_mem [NUM_MST][CMD_DEPTH];
    logic [CMD_PTR_W-1:0] aw_dest_q_wr [NUM_MST];
    logic [CMD_PTR_W-1:0] aw_dest_q_rd [NUM_MST];
    logic [CMD_CNT_W-1:0] aw_dest_q_cnt [NUM_MST];

    // Decode-error response FIFOs
    werr_entry_t werr_mem [NUM_MST][CMD_DEPTH];
    logic [CMD_PTR_W-1:0] werr_wr [NUM_MST];
    logic [CMD_PTR_W-1:0] werr_rd [NUM_MST];
    logic [CMD_CNT_W-1:0] werr_cnt [NUM_MST];

    rerr_desc_t  rerr_mem [NUM_MST][CMD_DEPTH];
    logic [CMD_PTR_W-1:0] rerr_wr [NUM_MST];
    logic [CMD_PTR_W-1:0] rerr_rd [NUM_MST];
    logic [CMD_CNT_W-1:0] rerr_cnt [NUM_MST];

    // -------------------------------------------------------------------------
    // Outstanding tracking
    // -------------------------------------------------------------------------
    logic [NUM_MST-1:0][NUM_IDS-1:0] outstanding_ids;
    logic [CMD_CNT_W-1:0]            out_cnt [NUM_MST];   // max MAX_TRANS

    // -------------------------------------------------------------------------
    // Address decode
    // -------------------------------------------------------------------------
    function automatic int decode_slv(input addr_t addr,
                                      input xbar_rule_t [NUM_SLV-1:0] map);
        for (int i = 0; i < NUM_SLV; i++) begin
            if (addr >= map[i].start_addr && addr < map[i].end_addr)
                return int'(map[i].mst_port);
        end
        return -1;
    endfunction

    int decode_aw [NUM_MST];
    int decode_ar [NUM_MST];

    always_comb begin
        for (int m = 0; m < NUM_MST; m++) begin
            decode_aw[m] = decode_slv(mst_req[m].aw.addr, addr_map);
            decode_ar[m] = decode_slv(mst_req[m].ar.addr, addr_map);
        end
    end

    // -------------------------------------------------------------------------
    // FIFO empty/full/head signals
    // -------------------------------------------------------------------------
    logic aw_full [NUM_MST];
    logic aw_empty [NUM_MST];
    logic ar_full [NUM_MST];
    logic ar_empty [NUM_MST];
    logic w_full [NUM_MST];
    logic w_empty [NUM_MST];
    logic aw_dest_q_full [NUM_MST];
    logic aw_dest_q_empty [NUM_MST];
    logic werr_full [NUM_MST];
    logic werr_empty [NUM_MST];
    logic rerr_full [NUM_MST];
    logic rerr_empty [NUM_MST];

    always_comb begin
        for (int m = 0; m < NUM_MST; m++) begin
            aw_full[m]        = (aw_cnt[m] == CMD_DEPTH);
            aw_empty[m]       = (aw_cnt[m] == 0);
            ar_full[m]        = (ar_cnt[m] == CMD_DEPTH);
            ar_empty[m]       = (ar_cnt[m] == 0);
            w_full[m]         = (w_cnt[m] == W_DEPTH);
            w_empty[m]        = (w_cnt[m] == 0);
            aw_dest_q_full[m]  = (aw_dest_q_cnt[m] == CMD_DEPTH);
            aw_dest_q_empty[m] = (aw_dest_q_cnt[m] == 0);
            werr_full[m]      = (werr_cnt[m] == CMD_DEPTH);
            werr_empty[m]     = (werr_cnt[m] == 0);
            rerr_full[m]      = (rerr_cnt[m] == CMD_DEPTH);
            rerr_empty[m]     = (rerr_cnt[m] == 0);
        end
    end

    // -------------------------------------------------------------------------
    // Master-side ready signals
    // -------------------------------------------------------------------------
    logic [NUM_MST-1:0] mst_aw_ready;
    logic [NUM_MST-1:0] mst_ar_ready;
    logic [NUM_MST-1:0] mst_w_ready;

    always_comb begin
        for (int m = 0; m < NUM_MST; m++) begin
            mst_aw_ready[m] = !aw_full[m] && !aw_dest_q_full[m] &&
                              (out_cnt[m] < MAX_TRANS) &&
                              !outstanding_ids[m][mst_req[m].aw.id];

            mst_ar_ready[m] = !ar_full[m] &&
                              (out_cnt[m] < MAX_TRANS) &&
                              !outstanding_ids[m][mst_req[m].ar.id];

            if (aw_dest_q_empty[m])
                mst_w_ready[m] = 1'b0;
            else if (aw_dest_q_mem[m][aw_dest_q_rd[m]] == INVALID_DEST)
                mst_w_ready[m] = 1'b1;   // discard W for decode-error write
            else
                mst_w_ready[m] = !w_full[m];
        end
    end

    genvar i;
    generate
        for (i = 0; i < NUM_MST; i++) begin : g_assign_mst_resp
            assign mst_resp[i].aw_ready = mst_aw_ready[i];
            assign mst_resp[i].ar_ready = mst_ar_ready[i];
            assign mst_resp[i].w_ready  = mst_w_ready[i];
        end
    endgenerate

    // -------------------------------------------------------------------------
    // Master handshakes
    // -------------------------------------------------------------------------
    logic [NUM_MST-1:0] aw_hs, ar_hs, w_hs;
    always_comb begin
        for (int m = 0; m < NUM_MST; m++) begin
            aw_hs[m] = mst_req[m].aw_valid && mst_aw_ready[m];
            ar_hs[m] = mst_req[m].ar_valid && mst_ar_ready[m];
            w_hs[m]  = mst_req[m].w_valid && mst_w_ready[m];
        end
    end

    // -------------------------------------------------------------------------
    // Command FIFO push/pop signals
    // -------------------------------------------------------------------------
    logic [NUM_MST-1:0] aw_push, aw_pop, ar_push, ar_pop;
    logic [NUM_MST-1:0] w_push, w_pop;

    always_comb begin
        for (int m = 0; m < NUM_MST; m++) begin
            aw_push[m] = aw_hs[m] && (decode_aw[m] != -1);
            ar_push[m] = ar_hs[m] && (decode_ar[m] != -1);

            // W is pushed only for valid destinations
            if (aw_dest_q_empty[m])
                w_push[m] = 1'b0;
            else
                w_push[m] = w_hs[m] && (aw_dest_q_mem[m][aw_dest_q_rd[m]] != INVALID_DEST);
        end
    end

    // -------------------------------------------------------------------------
    // Input FIFO data
    // -------------------------------------------------------------------------
    aw_cmd_t aw_din [NUM_MST];
    ar_cmd_t ar_din [NUM_MST];
    w_cmd_t  w_din  [NUM_MST];

    always_comb begin
        for (int m = 0; m < NUM_MST; m++) begin
            aw_din[m].dest = decode_aw[m];
            aw_din[m].aw   = mst_req[m].aw;

            ar_din[m].dest = decode_ar[m];
            ar_din[m].ar   = mst_req[m].ar;

            w_din[m].w = mst_req[m].w;
            if (!aw_dest_q_empty[m])
                w_din[m].dest = aw_dest_q_mem[m][aw_dest_q_rd[m]];
            else
                w_din[m].dest = INVALID_DEST;
        end
    end

    // -------------------------------------------------------------------------
    // Command FIFO processes
    // -------------------------------------------------------------------------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int m = 0; m < NUM_MST; m++) begin
                aw_wr[m] <= '0;
                aw_rd[m] <= '0;
                aw_cnt[m] <= '0;
            end
        end else begin
            for (int m = 0; m < NUM_MST; m++) begin
                if (aw_push[m] && !aw_pop[m] && aw_cnt[m] < CMD_DEPTH) begin
                    aw_mem[m][aw_wr[m]] <= aw_din[m];
                    aw_wr[m] <= aw_wr[m] + 1'b1;
                    aw_cnt[m] <= aw_cnt[m] + 1'b1;
                end
                else if (!aw_push[m] && aw_pop[m] && aw_cnt[m] > 0) begin
                    aw_rd[m] <= aw_rd[m] + 1'b1;
                    aw_cnt[m] <= aw_cnt[m] - 1'b1;
                end
                else if (aw_push[m] && aw_pop[m]) begin
                    aw_mem[m][aw_wr[m]] <= aw_din[m];
                    aw_wr[m] <= aw_wr[m] + 1'b1;
                    aw_rd[m] <= aw_rd[m] + 1'b1;
                end
            end
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int m = 0; m < NUM_MST; m++) begin
                ar_wr[m] <= '0;
                ar_rd[m] <= '0;
                ar_cnt[m] <= '0;
            end
        end else begin
            for (int m = 0; m < NUM_MST; m++) begin
                if (ar_push[m] && !ar_pop[m] && ar_cnt[m] < CMD_DEPTH) begin
                    ar_mem[m][ar_wr[m]] <= ar_din[m];
                    ar_wr[m] <= ar_wr[m] + 1'b1;
                    ar_cnt[m] <= ar_cnt[m] + 1'b1;
                end
                else if (!ar_push[m] && ar_pop[m] && ar_cnt[m] > 0) begin
                    ar_rd[m] <= ar_rd[m] + 1'b1;
                    ar_cnt[m] <= ar_cnt[m] - 1'b1;
                end
                else if (ar_push[m] && ar_pop[m]) begin
                    ar_mem[m][ar_wr[m]] <= ar_din[m];
                    ar_wr[m] <= ar_wr[m] + 1'b1;
                    ar_rd[m] <= ar_rd[m] + 1'b1;
                end
            end
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int m = 0; m < NUM_MST; m++) begin
                w_wr[m] <= '0;
                w_rd[m] <= '0;
                w_cnt[m] <= '0;
            end
        end else begin
            for (int m = 0; m < NUM_MST; m++) begin
                if (w_push[m] && !w_pop[m] && w_cnt[m] < W_DEPTH) begin
                    w_mem[m][w_wr[m]] <= w_din[m];
                    w_wr[m] <= w_wr[m] + 1'b1;
                    w_cnt[m] <= w_cnt[m] + 1'b1;
                end
                else if (!w_push[m] && w_pop[m] && w_cnt[m] > 0) begin
                    w_rd[m] <= w_rd[m] + 1'b1;
                    w_cnt[m] <= w_cnt[m] - 1'b1;
                end
                else if (w_push[m] && w_pop[m]) begin
                    w_mem[m][w_wr[m]] <= w_din[m];
                    w_wr[m] <= w_wr[m] + 1'b1;
                    w_rd[m] <= w_rd[m] + 1'b1;
                end
            end
        end
    end

    // -------------------------------------------------------------------------
    // Write destination queue
    // -------------------------------------------------------------------------
    logic [NUM_MST-1:0] aw_dest_q_push;
    logic [NUM_MST-1:0] aw_dest_q_pop;

    always_comb begin
        for (int m = 0; m < NUM_MST; m++) begin
            aw_dest_q_push[m] = aw_hs[m];
            aw_dest_q_pop[m]  = w_hs[m] && mst_req[m].w.last;
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int m = 0; m < NUM_MST; m++) begin
                aw_dest_q_wr[m] <= '0;
                aw_dest_q_rd[m] <= '0;
                aw_dest_q_cnt[m] <= '0;
            end
        end else begin
            for (int m = 0; m < NUM_MST; m++) begin
                if (aw_dest_q_push[m] && !aw_dest_q_pop[m] && aw_dest_q_cnt[m] < CMD_DEPTH) begin
                    aw_dest_q_mem[m][aw_dest_q_wr[m]] <= (decode_aw[m] == -1) ? INVALID_DEST : decode_aw[m];
                    aw_dest_q_wr[m] <= aw_dest_q_wr[m] + 1'b1;
                    aw_dest_q_cnt[m] <= aw_dest_q_cnt[m] + 1'b1;
                end
                else if (!aw_dest_q_push[m] && aw_dest_q_pop[m] && aw_dest_q_cnt[m] > 0) begin
                    aw_dest_q_rd[m] <= aw_dest_q_rd[m] + 1'b1;
                    aw_dest_q_cnt[m] <= aw_dest_q_cnt[m] - 1'b1;
                end
                else if (aw_dest_q_push[m] && aw_dest_q_pop[m]) begin
                    aw_dest_q_mem[m][aw_dest_q_wr[m]] <= (decode_aw[m] == -1) ? INVALID_DEST : decode_aw[m];
                    aw_dest_q_wr[m] <= aw_dest_q_wr[m] + 1'b1;
                    aw_dest_q_rd[m] <= aw_dest_q_rd[m] + 1'b1;
                end
            end
        end
    end

    // -------------------------------------------------------------------------
    // Slave-side request arbiters
    // -------------------------------------------------------------------------
    logic [NUM_SLV-1:0][NUM_MST-1:0] aw_src_valid;
    logic [NUM_SLV-1:0]              aw_any_valid;
    logic [NUM_SLV-1:0]              aw_hs_slv;
    int                               aw_ptr [NUM_SLV];

    logic [NUM_SLV-1:0][NUM_MST-1:0] ar_src_valid;
    logic [NUM_SLV-1:0]              ar_any_valid;
    logic [NUM_SLV-1:0]              ar_hs_slv;
    int                               ar_ptr [NUM_SLV];

    logic [NUM_SLV-1:0][NUM_MST-1:0] w_src_valid;
    logic [NUM_SLV-1:0]              w_any_valid;
    logic [NUM_SLV-1:0]              w_hs_slv;
    int                               w_ptr [NUM_SLV];

    always_comb begin
        for (int s = 0; s < NUM_SLV; s++) begin
            for (int m = 0; m < NUM_MST; m++) begin
                aw_src_valid[s][m] = !aw_empty[m] && (aw_mem[m][aw_rd[m]].dest == s);
                ar_src_valid[s][m] = !ar_empty[m] && (ar_mem[m][ar_rd[m]].dest == s);
                w_src_valid[s][m]  = !w_empty[m]  && (w_mem[m][w_rd[m]].dest == s);
            end
            aw_any_valid[s] = |aw_src_valid[s];
            ar_any_valid[s] = |ar_src_valid[s];
            w_any_valid[s]  = |w_src_valid[s];

            // Default selected master = current pointer
            aw_hs_slv[s] = aw_src_valid[s][aw_ptr[s]] && slv_resp[s].aw_ready;
            ar_hs_slv[s] = ar_src_valid[s][ar_ptr[s]] && slv_resp[s].ar_ready;
            w_hs_slv[s]  = w_src_valid[s][w_ptr[s]]  && slv_resp[s].w_ready;
        end
    end

    // Pop signals to master FIFOs
    always_comb begin
        aw_pop = '0;
        ar_pop = '0;
        w_pop  = '0;
        for (int s = 0; s < NUM_SLV; s++) begin
            if (aw_hs_slv[s])
                aw_pop[aw_ptr[s]] = 1'b1;
            if (ar_hs_slv[s])
                ar_pop[ar_ptr[s]] = 1'b1;
            if (w_hs_slv[s])
                w_pop[w_ptr[s]] = 1'b1;
        end
    end

    // Slave request outputs
    always_comb begin
        for (int s = 0; s < NUM_SLV; s++) begin
            slv_req[s].aw_valid = aw_src_valid[s][aw_ptr[s]];
            slv_req[s].aw       = aw_mem[aw_ptr[s]][aw_rd[aw_ptr[s]]].aw;

            slv_req[s].ar_valid = ar_src_valid[s][ar_ptr[s]];
            slv_req[s].ar       = ar_mem[ar_ptr[s]][ar_rd[ar_ptr[s]]].ar;

            slv_req[s].w_valid  = w_src_valid[s][w_ptr[s]];
            slv_req[s].w        = w_mem[w_ptr[s]][w_rd[w_ptr[s]]].w;
        end
    end

    // Round-robin pointer updates for slave request arbiters
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int s = 0; s < NUM_SLV; s++) begin
                aw_ptr[s] <= 0;
                ar_ptr[s] <= 0;
                w_ptr[s]  <= 0;
            end
        end else begin
            for (int s = 0; s < NUM_SLV; s++) begin
                if (aw_hs_slv[s])
                    aw_ptr[s] <= (aw_ptr[s] == NUM_MST-1) ? 0 : aw_ptr[s] + 1;
                else if (!aw_src_valid[s][aw_ptr[s]] && aw_any_valid[s])
                    aw_ptr[s] <= (aw_ptr[s] == NUM_MST-1) ? 0 : aw_ptr[s] + 1;

                if (ar_hs_slv[s])
                    ar_ptr[s] <= (ar_ptr[s] == NUM_MST-1) ? 0 : ar_ptr[s] + 1;
                else if (!ar_src_valid[s][ar_ptr[s]] && ar_any_valid[s])
                    ar_ptr[s] <= (ar_ptr[s] == NUM_MST-1) ? 0 : ar_ptr[s] + 1;

                if (w_hs_slv[s])
                    w_ptr[s] <= (w_ptr[s] == NUM_MST-1) ? 0 : w_ptr[s] + 1;
                else if (!w_src_valid[s][w_ptr[s]] && w_any_valid[s])
                    w_ptr[s] <= (w_ptr[s] == NUM_MST-1) ? 0 : w_ptr[s] + 1;
            end
        end
    end

    // -------------------------------------------------------------------------
    // Decode-error write response FIFO
    // -------------------------------------------------------------------------
    logic [NUM_MST-1:0] werr_push, werr_pop;
    always_comb begin
        for (int m = 0; m < NUM_MST; m++) begin
            werr_push[m] = aw_hs[m] && (decode_aw[m] == -1);
            // pop is assigned from B response arbiter later
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int m = 0; m < NUM_MST; m++) begin
                werr_wr[m] <= '0;
                werr_rd[m] <= '0;
                werr_cnt[m] <= '0;
            end
        end else begin
            for (int m = 0; m < NUM_MST; m++) begin
                if (werr_push[m] && !werr_pop[m] && werr_cnt[m] < CMD_DEPTH) begin
                    werr_mem[m][werr_wr[m]] <= '{id: mst_req[m].aw.id,
                                                  resp: RESP_DECERR,
                                                  user: mst_req[m].aw.user};
                    werr_wr[m] <= werr_wr[m] + 1'b1;
                    werr_cnt[m] <= werr_cnt[m] + 1'b1;
                end
                else if (!werr_push[m] && werr_pop[m] && werr_cnt[m] > 0) begin
                    werr_rd[m] <= werr_rd[m] + 1'b1;
                    werr_cnt[m] <= werr_cnt[m] - 1'b1;
                end
                else if (werr_push[m] && werr_pop[m]) begin
                    werr_mem[m][werr_wr[m]] <= '{id: mst_req[m].aw.id,
                                                  resp: RESP_DECERR,
                                                  user: mst_req[m].aw.user};
                    werr_wr[m] <= werr_wr[m] + 1'b1;
                    werr_rd[m] <= werr_rd[m] + 1'b1;
                end
            end
        end
    end

    // -------------------------------------------------------------------------
    // Decode-error read descriptor FIFO
    // -------------------------------------------------------------------------
    logic [NUM_MST-1:0] rerr_push, rerr_pop;
    always_comb begin
        for (int m = 0; m < NUM_MST; m++) begin
            rerr_push[m] = ar_hs[m] && (decode_ar[m] == -1);
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int m = 0; m < NUM_MST; m++) begin
                rerr_wr[m] <= '0;
                rerr_rd[m] <= '0;
                rerr_cnt[m] <= '0;
            end
        end else begin
            for (int m = 0; m < NUM_MST; m++) begin
                if (rerr_push[m] && !rerr_pop[m] && rerr_cnt[m] < CMD_DEPTH) begin
                    rerr_mem[m][rerr_wr[m]] <= '{id: mst_req[m].ar.id,
                                                  len: mst_req[m].ar.len,
                                                  user: mst_req[m].ar.user};
                    rerr_wr[m] <= rerr_wr[m] + 1'b1;
                    rerr_cnt[m] <= rerr_cnt[m] + 1'b1;
                end
                else if (!rerr_push[m] && rerr_pop[m] && rerr_cnt[m] > 0) begin
                    rerr_rd[m] <= rerr_rd[m] + 1'b1;
                    rerr_cnt[m] <= rerr_cnt[m] - 1'b1;
                end
                else if (rerr_push[m] && rerr_pop[m]) begin
                    rerr_mem[m][rerr_wr[m]] <= '{id: mst_req[m].ar.id,
                                                  len: mst_req[m].ar.len,
                                                  user: mst_req[m].ar.user};
                    rerr_wr[m] <= rerr_wr[m] + 1'b1;
                    rerr_rd[m] <= rerr_rd[m] + 1'b1;
                end
            end
        end
    end

    // -------------------------------------------------------------------------
    // Response arbitration (B and R)
    // -------------------------------------------------------------------------
    // Master index extraction from wide IDs
    function automatic int mst_from_b(input mst_b_t b);
        return int'(b.id[SLV_ID_W + IDX_W - 1 : SLV_ID_W]);
    endfunction

    function automatic int mst_from_r(input mst_r_t r);
        return int'(r.id[SLV_ID_W + IDX_W - 1 : SLV_ID_W]);
    endfunction

    // B response source valid flags
    logic [NUM_MST-1:0][NUM_SLV-1:0] b_slave_valid;
    logic [NUM_MST-1:0]              b_err_valid;
    logic [NUM_MST-1:0]              b_any_valid;
    logic [NUM_MST-1:0]              b_hs_mst;

    int b_ptr [NUM_MST];

    always_comb begin
        for (int m = 0; m < NUM_MST; m++) begin
            for (int s = 0; s < NUM_SLV; s++)
                b_slave_valid[m][s] = slv_resp[s].b_valid && (mst_from_b(slv_resp[s].b) == m);

            b_err_valid[m] = !werr_empty[m];
            b_any_valid[m] = |b_slave_valid[m] | b_err_valid[m];
        end
    end

    // Drive B ready to each slave and B output to each master
    always_comb begin
        for (int s = 0; s < NUM_SLV; s++) begin
            slv_req[s].b_ready = 1'b0;
            for (int m = 0; m < NUM_MST; m++) begin
                if (b_ptr[m] == s)
                    slv_req[s].b_ready = mst_resp[m].b_ready && (mst_from_b(slv_resp[s].b) == m);
            end
        end

        for (int m = 0; m < NUM_MST; m++) begin
            if (b_ptr[m] == NUM_SLV) begin
                mst_resp[m].b_valid = b_err_valid[m];
                if (!werr_empty[m])
                    mst_resp[m].b = '{id: werr_mem[m][werr_rd[m]].id,
                                       resp: werr_mem[m][werr_rd[m]].resp,
                                       user: werr_mem[m][werr_rd[m]].user};
                else
                    mst_resp[m].b = '{id: '0, resp: RESP_DECERR, user: '0};
            end else begin
                mst_resp[m].b_valid = b_slave_valid[m][b_ptr[m]];
                if (b_slave_valid[m][b_ptr[m]])
                    mst_resp[m].b = '{id: slv_resp[b_ptr[m]].b.id[SLV_ID_W-1:0],
                                       resp: slv_resp[b_ptr[m]].b.resp,
                                       user: slv_resp[b_ptr[m]].b.user};
                else
                    mst_resp[m].b = '{id: '0, resp: RESP_DECERR, user: '0};
            end
        end
    end

    always_comb begin
        for (int m = 0; m < NUM_MST; m++)
            b_hs_mst[m] = mst_resp[m].b_valid && mst_resp[m].b_ready;
    end

    // R response source valid flags
    logic [NUM_MST-1:0][NUM_SLV-1:0] r_slave_valid;
    logic [NUM_MST-1:0]              r_err_valid;
    logic [NUM_MST-1:0]              r_any_valid;
    logic [NUM_MST-1:0]              r_hs_mst;

    int r_ptr [NUM_MST];

    // Read error current beat generation
    logic [NUM_MST-1:0] rerr_active;
    logic [7:0]         rerr_cnt [NUM_MST];

    always_comb begin
        for (int m = 0; m < NUM_MST; m++) begin
            for (int s = 0; s < NUM_SLV; s++)
                r_slave_valid[m][s] = slv_resp[s].r_valid && (mst_from_r(slv_resp[s].r) == m);

            r_err_valid[m] = !rerr_empty[m];
            r_any_valid[m] = |r_slave_valid[m] | r_err_valid[m];
        end
    end

    always_comb begin
        for (int s = 0; s < NUM_SLV; s++) begin
            slv_req[s].r_ready = 1'b0;
            for (int m = 0; m < NUM_MST; m++) begin
                if (r_ptr[m] == s)
                    slv_req[s].r_ready = mst_resp[m].r_ready && (mst_from_r(slv_resp[s].r) == m);
            end
        end

        for (int m = 0; m < NUM_MST; m++) begin
            if (r_ptr[m] == NUM_SLV) begin
                mst_resp[m].r_valid = r_err_valid[m];
                if (!rerr_empty[m]) begin
                    automatic logic [7:0] len = rerr_mem[m][rerr_rd[m]].len;
                    mst_resp[m].r = '{id: rerr_mem[m][rerr_rd[m]].id,
                                       data: '0,
                                       resp: RESP_DECERR,
                                       last: (rerr_cnt[m] == len),
                                       user: rerr_mem[m][rerr_rd[m]].user};
                end else begin
                    mst_resp[m].r = '{id: '0, data: '0, resp: RESP_DECERR,
                                       last: 1'b0, user: '0};
                end
            end else begin
                mst_resp[m].r_valid = r_slave_valid[m][r_ptr[m]];
                if (r_slave_valid[m][r_ptr[m]])
                    mst_resp[m].r = '{id: slv_resp[r_ptr[m]].r.id[SLV_ID_W-1:0],
                                       data: slv_resp[r_ptr[m]].r.data,
                                       resp: slv_resp[r_ptr[m]].r.resp,
                                       last: slv_resp[r_ptr[m]].r.last,
                                       user: slv_resp[r_ptr[m]].r.user};
                else
                    mst_resp[m].r = '{id: '0, data: '0, resp: RESP_DECERR,
                                       last: 1'b0, user: '0};
            end
        end
    end

    always_comb begin
        for (int m = 0; m < NUM_MST; m++)
            r_hs_mst[m] = mst_resp[m].r_valid && mst_resp[m].r_ready;
    end

    // -------------------------------------------------------------------------
    // Response source pointer updates and error FIFO pops
    // -------------------------------------------------------------------------
    logic [NUM_MST-1:0] werr_pop_temp;
    logic [NUM_MST-1:0] rerr_pop_temp;

    always_comb begin
        werr_pop_temp = '0;
        rerr_pop_temp = '0;

        for (int m = 0; m < NUM_MST; m++) begin
            if (b_hs_mst[m] && b_ptr[m] == NUM_SLV)
                werr_pop_temp[m] = 1'b1;

            if (r_hs_mst[m] && r_ptr[m] == NUM_SLV) begin
                // Pop read-error descriptor only when last beat is accepted
                if (!rerr_empty[m] && (rerr_cnt[m] == rerr_mem[m][rerr_rd[m]].len))
                    rerr_pop_temp[m] = 1'b1;
            end
        end
    end
    assign werr_pop = werr_pop_temp;
    assign rerr_pop = rerr_pop_temp;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int m = 0; m < NUM_MST; m++) begin
                b_ptr[m] <= 0;
                r_ptr[m] <= 0;
                rerr_cnt[m] <= '0;
            end
        end else begin
            for (int m = 0; m < NUM_MST; m++) begin
                // B pointer
                if (b_hs_mst[m])
                    b_ptr[m] <= (b_ptr[m] == NUM_SLV) ? 0 : b_ptr[m] + 1;
                else if (!((b_ptr[m] == NUM_SLV) ? b_err_valid[m] : b_slave_valid[m][b_ptr[m]])
                         && b_any_valid[m])
                    b_ptr[m] <= (b_ptr[m] == NUM_SLV) ? 0 : b_ptr[m] + 1;

                // R pointer
                if (r_hs_mst[m]) begin
                    if (r_ptr[m] == NUM_SLV && !rerr_empty[m]) begin
                        if (rerr_cnt[m] == rerr_mem[m][rerr_rd[m]].len)
                            rerr_cnt[m] <= '0;
                        else
                            rerr_cnt[m] <= rerr_cnt[m] + 1'b1;
                    end
                    r_ptr[m] <= (r_ptr[m] == NUM_SLV) ? 0 : r_ptr[m] + 1;
                end
                else if (!((r_ptr[m] == NUM_SLV) ? r_err_valid[m] : r_slave_valid[m][r_ptr[m]])
                         && r_any_valid[m])
                    r_ptr[m] <= (r_ptr[m] == NUM_SLV) ? 0 : r_ptr[m] + 1;
            end
        end
    end

    // -------------------------------------------------------------------------
    // Outstanding count and ID tracking
    // -------------------------------------------------------------------------
    logic [NUM_MST-1:0] b_complete;
    logic [NUM_MST-1:0] r_complete;
    logic [NUM_MST-1:0][SLV_ID_W-1:0] b_complete_id;
    logic [NUM_MST-1:0][SLV_ID_W-1:0] r_complete_id;

    always_comb begin
        b_complete = '0;
        r_complete = '0;
        b_complete_id = '0;
        r_complete_id = '0;

        for (int m = 0; m < NUM_MST; m++) begin
            if (b_hs_mst[m]) begin
                b_complete[m] = 1'b1;
                if (b_ptr[m] == NUM_SLV)
                    b_complete_id[m] = werr_mem[m][werr_rd[m]].id;
                else
                    b_complete_id[m] = slv_resp[b_ptr[m]].b.id[SLV_ID_W-1:0];
            end

            if (r_hs_mst[m]) begin
                if (r_ptr[m] == NUM_SLV) begin
                    if (!rerr_empty[m] && (rerr_cnt[m] == rerr_mem[m][rerr_rd[m]].len))
                        r_complete[m] = 1'b1;
                end else if (r_slave_valid[m][r_ptr[m]] && slv_resp[r_ptr[m]].r.last)
                    r_complete[m] = 1'b1;

                if (r_complete[m]) begin
                    if (r_ptr[m] == NUM_SLV)
                        r_complete_id[m] = rerr_mem[m][rerr_rd[m]].id;
                    else
                        r_complete_id[m] = slv_resp[r_ptr[m]].r.id[SLV_ID_W-1:0];
                end
            end
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int m = 0; m < NUM_MST; m++) begin
                out_cnt[m] <= '0;
                for (int id = 0; id < NUM_IDS; id++)
                    outstanding_ids[m][id] <= 1'b0;
            end
        end else begin
            for (int m = 0; m < NUM_MST; m++) begin
                out_cnt[m] <= out_cnt[m] + (aw_hs[m] ? 1'b1 : 1'b0)
                                        + (ar_hs[m] ? 1'b1 : 1'b0)
                                        - (b_complete[m] ? 1'b1 : 1'b0)
                                        - (r_complete[m] ? 1'b1 : 1'b0);

                if (aw_hs[m])
                    outstanding_ids[m][mst_req[m].aw.id] <= 1'b1;
                if (ar_hs[m])
                    outstanding_ids[m][mst_req[m].ar.id] <= 1'b1;
                if (b_complete[m])
                    outstanding_ids[m][b_complete_id[m]] <= 1'b0;
                if (r_complete[m])
                    outstanding_ids[m][r_complete_id[m]] <= 1'b0;
            end
        end
    end

    // -------------------------------------------------------------------------
    // Reset: output valid low while rst_n low
    // -------------------------------------------------------------------------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int m = 0; m < NUM_MST; m++) begin
                mst_resp[m].b_valid <= 1'b0;
                mst_resp[m].r_valid <= 1'b0;
            end
        end
    end

endmodule