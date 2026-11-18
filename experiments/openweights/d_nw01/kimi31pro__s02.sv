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

  localparam int ID_NUM    = (1 << SLV_ID_W);
  localparam int SRC_N     = NUM_SLV + 1;
  localparam int MST_PTR_W = (NUM_MST > 1) ? $clog2(NUM_MST) : 1;
  localparam int SRC_W     = (SRC_N > 1) ? $clog2(SRC_N) : 1;
  localparam int CNT_W     = (MAX_TRANS > 1) ? $clog2(MAX_TRANS + 1) : 1;
  localparam int WPTR_W    = (MAX_TRANS > 1) ? $clog2(MAX_TRANS) : 1;
  localparam int WCNT_W    = (MAX_TRANS > 1) ? $clog2(MAX_TRANS + 1) : 1;
  localparam int SCNT_W    = (NUM_MST > 1) ? $clog2(NUM_MST + 1) : 1;

  localparam logic [CNT_W-1:0]  MAX_TRANS_C  = MAX_TRANS;
  localparam logic [WCNT_W-1:0] MAX_TRANS_WC = MAX_TRANS;
  localparam logic [SCNT_W-1:0] NUM_MST_SC   = NUM_MST;
  localparam logic [SRC_W-1:0]  LOCAL_SRC    = NUM_SLV;

  function automatic mst_aw_t widen_aw(input slv_aw_t a, input integer m);
    mst_aw_t t;
    begin
      t = '0;
      t.id[SLV_ID_W-1:0] = a.id;
      t.id[MST_ID_W-1:SLV_ID_W] = m[MST_IDX_W-1:0];
      t.addr   = a.addr;
      t.len    = a.len;
      t.size   = a.size;
      t.burst  = a.burst;
      t.lock   = a.lock;
      t.cache  = a.cache;
      t.prot   = a.prot;
      t.qos    = a.qos;
      t.region = a.region;
      t.atop   = a.atop;
      t.user   = a.user;
      widen_aw = t;
    end
  endfunction

  function automatic mst_ar_t widen_ar(input slv_ar_t a, input integer m);
    mst_ar_t t;
    begin
      t = '0;
      t.id[SLV_ID_W-1:0] = a.id;
      t.id[MST_ID_W-1:SLV_ID_W] = m[MST_IDX_W-1:0];
      t.addr   = a.addr;
      t.len    = a.len;
      t.size   = a.size;
      t.burst  = a.burst;
      t.lock   = a.lock;
      t.cache  = a.cache;
      t.prot   = a.prot;
      t.qos    = a.qos;
      t.region = a.region;
      t.user   = a.user;
      widen_ar = t;
    end
  endfunction

  // One-entry input registers make every master-side ready independent of valid.
  slv_aw_t aw_buf [NUM_MST-1:0];
  slv_ar_t ar_buf [NUM_MST-1:0];
  w_t      w_buf  [NUM_MST-1:0];
  logic aw_buf_v [NUM_MST-1:0];
  logic ar_buf_v [NUM_MST-1:0];
  logic w_buf_v  [NUM_MST-1:0];

  // Registered output channels.
  mst_aw_t aw_out [NUM_SLV-1:0];
  mst_ar_t ar_out [NUM_SLV-1:0];
  w_t      w_out  [NUM_SLV-1:0];
  logic aw_out_v [NUM_SLV-1:0];
  logic ar_out_v [NUM_SLV-1:0];
  logic w_out_v  [NUM_SLV-1:0];

  slv_b_t b_out [NUM_MST-1:0];
  slv_r_t r_out [NUM_MST-1:0];
  logic b_out_v [NUM_MST-1:0];
  logic r_out_v [NUM_MST-1:0];

  // Outstanding-transaction tracking.  An ID is kept busy until its response
  // is accepted by the master, which also gives per-ID ordering end to end.
  logic [CNT_W-1:0] outstanding [NUM_MST-1:0];
  logic id_busy  [NUM_MST-1:0][ID_NUM-1:0];
  logic rd_valid [NUM_MST-1:0][ID_NUM-1:0];
  logic rd_decerr[NUM_MST-1:0][ID_NUM-1:0];
  logic [7:0] rd_len [NUM_MST-1:0][ID_NUM-1:0];
  logic wr_valid [NUM_MST-1:0][ID_NUM-1:0];

  // Write requests are tracked in AW acceptance order.  Only the head request
  // is presented to a slave; subsequent requests still count as outstanding.
  slv_aw_t wr_aw_fifo [NUM_MST-1:0][MAX_TRANS-1:0];
  logic [2:0] wr_route_fifo [NUM_MST-1:0][MAX_TRANS-1:0];
  logic wr_decerr_fifo [NUM_MST-1:0][MAX_TRANS-1:0];
  logic wr_aw_sent_fifo [NUM_MST-1:0][MAX_TRANS-1:0];
  logic [WPTR_W-1:0] wr_head [NUM_MST-1:0];
  logic [WPTR_W-1:0] wr_tail [NUM_MST-1:0];
  logic [WCNT_W-1:0] wr_count [NUM_MST-1:0];

  // At each slave this FIFO records AW handshake order.  W bursts follow that
  // order, so bursts from different masters are never interleaved or mispaired.
  logic [MST_IDX_W-1:0] swq_master [NUM_SLV-1:0][NUM_MST-1:0];
  logic [MST_PTR_W-1:0] swq_head [NUM_SLV-1:0];
  logic [MST_PTR_W-1:0] swq_tail [NUM_SLV-1:0];
  logic [SCNT_W-1:0] swq_count [NUM_SLV-1:0];

  // Locally generated decode-error write responses.
  logic err_b_valid [NUM_MST-1:0];
  slv_id_t err_b_id [NUM_MST-1:0];

  // Request arbitration.
  logic req_turn [NUM_MST-1:0]; // 0: AW, 1: AR
  logic [MST_PTR_W-1:0] aw_rr [NUM_SLV-1:0];
  logic [MST_PTR_W-1:0] ar_rr [NUM_SLV-1:0];

  logic aw_dec_ok [NUM_MST-1:0];
  logic ar_dec_ok [NUM_MST-1:0];
  logic [2:0] aw_dec_route [NUM_MST-1:0];
  logic [2:0] ar_dec_route [NUM_MST-1:0];
  logic aw_eligible [NUM_MST-1:0];
  logic ar_eligible [NUM_MST-1:0];
  logic aw_try [NUM_MST-1:0];
  logic ar_try [NUM_MST-1:0];
  logic aw_alloc [NUM_MST-1:0];
  logic ar_alloc [NUM_MST-1:0];
  logic ar_grant [NUM_MST-1:0];

  logic aw_gvalid [NUM_SLV-1:0];
  logic ar_gvalid [NUM_SLV-1:0];
  logic [MST_PTR_W-1:0] aw_gmaster [NUM_SLV-1:0];
  logic [MST_PTR_W-1:0] ar_gmaster [NUM_SLV-1:0];

  // Combinational views of each write-FIFO head.
  slv_aw_t head_aw [NUM_MST-1:0];
  logic head_valid [NUM_MST-1:0];
  logic head_decerr [NUM_MST-1:0];
  logic head_aw_sent [NUM_MST-1:0];
  logic [2:0] head_route [NUM_MST-1:0];
  logic [MST_IDX_W-1:0] aw_out_master [NUM_SLV-1:0];
  logic [MST_IDX_W-1:0] swq_head_master [NUM_SLV-1:0];

  // B response arbitration.
  logic [SRC_W-1:0] b_rr [NUM_MST-1:0];
  logic b_load [NUM_MST-1:0];
  logic b_load_local [NUM_MST-1:0];
  logic [SRC_W-1:0] b_src [NUM_MST-1:0];
  logic [NUM_SLV-1:0] slv_b_ready;

  // R response arbitration.  A source is held for the whole burst.
  logic [SRC_W-1:0] r_rr [NUM_MST-1:0];
  logic r_lock_v [NUM_MST-1:0];
  logic [SRC_W-1:0] r_lock_src [NUM_MST-1:0];
  slv_id_t local_r_id [NUM_MST-1:0];
  logic [7:0] local_r_pos [NUM_MST-1:0];

  logic local_any [NUM_MST-1:0];
  slv_id_t local_pick [NUM_MST-1:0];
  logic r_load [NUM_MST-1:0];
  logic r_load_local [NUM_MST-1:0];
  logic r_start [NUM_MST-1:0];
  logic [SRC_W-1:0] r_src [NUM_MST-1:0];
  slv_id_t r_local_pick [NUM_MST-1:0];
  logic [NUM_SLV-1:0] slv_r_ready;

  // W movement and queue push/pop controls.
  logic w_load [NUM_SLV-1:0];
  logic [MST_IDX_W-1:0] w_load_m [NUM_SLV-1:0];
  logic w_consume_err [NUM_MST-1:0];
  logic w_pop [NUM_MST-1:0];
  logic swq_push [NUM_SLV-1:0];
  logic swq_pop [NUM_SLV-1:0];

  logic alloc [NUM_MST-1:0];
  logic rd_retire [NUM_MST-1:0];
  logic wr_retire [NUM_MST-1:0];

  genvar gm;
  genvar gs;
  generate
    for (gm = 0; gm < NUM_MST; gm = gm + 1) begin : gen_mst_outputs
      always_comb begin
        mst_resp[gm] = '0;
        mst_resp[gm].aw_ready = ~aw_buf_v[gm];
        mst_resp[gm].ar_ready = ~ar_buf_v[gm];
        mst_resp[gm].w_ready  = ~w_buf_v[gm];
        mst_resp[gm].b_valid  = b_out_v[gm] & rst_n;
        mst_resp[gm].b        = b_out[gm];
        mst_resp[gm].r_valid  = r_out_v[gm] & rst_n;
        mst_resp[gm].r        = r_out[gm];
      end
    end

    for (gs = 0; gs < NUM_SLV; gs = gs + 1) begin : gen_slv_outputs
      always_comb begin
        slv_req[gs] = '0;
        slv_req[gs].aw       = aw_out[gs];
        slv_req[gs].aw_valid = aw_out_v[gs] & rst_n;
        slv_req[gs].w        = w_out[gs];
        slv_req[gs].w_valid  = w_out_v[gs] & rst_n;
        slv_req[gs].b_ready  = slv_b_ready[gs];
        slv_req[gs].ar       = ar_out[gs];
        slv_req[gs].ar_valid = ar_out_v[gs] & rst_n;
        slv_req[gs].r_ready  = slv_r_ready[gs];
      end
    end
  endgenerate

  always_comb begin : decode_logic
    integer m;
    integer s;
    for (m = 0; m < NUM_MST; m = m + 1) begin
      aw_dec_ok[m] = 1'b0;
      ar_dec_ok[m] = 1'b0;
      aw_dec_route[m] = '0;
      ar_dec_route[m] = '0;
      for (s = 0; s < NUM_SLV; s = s + 1) begin
        if (!aw_dec_ok[m] &&
            (aw_buf[m].addr >= addr_map[s].start_addr) &&
            (aw_buf[m].addr <  addr_map[s].end_addr)) begin
          aw_dec_ok[m] = 1'b1;
          aw_dec_route[m] = addr_map[s].mst_port;
        end
        if (!ar_dec_ok[m] &&
            (ar_buf[m].addr >= addr_map[s].start_addr) &&
            (ar_buf[m].addr <  addr_map[s].end_addr)) begin
          ar_dec_ok[m] = 1'b1;
          ar_dec_route[m] = addr_map[s].mst_port;
        end
      end
    end
  end

  always_comb begin : head_logic
    integer m;
    integer s;
    for (m = 0; m < NUM_MST; m = m + 1) begin
      head_aw[m] = '0;
      head_valid[m] = 1'b0;
      head_decerr[m] = 1'b0;
      head_aw_sent[m] = 1'b0;
      head_route[m] = '0;
      if (wr_count[m] != '0) begin
        head_aw[m] = wr_aw_fifo[m][wr_head[m]];
        head_valid[m] = 1'b1;
        head_decerr[m] = wr_decerr_fifo[m][wr_head[m]];
        head_aw_sent[m] = wr_aw_sent_fifo[m][wr_head[m]];
        head_route[m] = wr_route_fifo[m][wr_head[m]];
      end
    end
    for (s = 0; s < NUM_SLV; s = s + 1) begin
      aw_out_master[s] = aw_out[s].id[MST_ID_W-1:SLV_ID_W];
      swq_head_master[s] = '0;
      if (swq_count[s] != '0)
        swq_head_master[s] = swq_master[s][swq_head[s]];
    end
  end

  always_comb begin : request_select_logic
    integer m;
    for (m = 0; m < NUM_MST; m = m + 1) begin
      aw_eligible[m] = aw_buf_v[m] &&
                       (outstanding[m] < MAX_TRANS_C) &&
                       (wr_count[m] < MAX_TRANS_WC) &&
                       !id_busy[m][aw_buf[m].id];
      ar_eligible[m] = ar_buf_v[m] &&
                       (outstanding[m] < MAX_TRANS_C) &&
                       !id_busy[m][ar_buf[m].id];
      aw_try[m] = 1'b0;
      ar_try[m] = 1'b0;
      if (aw_eligible[m] &&
          (!ar_eligible[m] || (req_turn[m] == 1'b0))) begin
        aw_try[m] = 1'b1;
      end else if (ar_eligible[m]) begin
        ar_try[m] = 1'b1;
      end
    end
  end

  always_comb begin : request_arbitration
    integer m;
    integer s;
    integer k;
    integer idx;
    for (m = 0; m < NUM_MST; m = m + 1) begin
      ar_grant[m] = 1'b0;
      aw_alloc[m] = 1'b0;
      ar_alloc[m] = 1'b0;
    end
    for (s = 0; s < NUM_SLV; s = s + 1) begin
      aw_gvalid[s] = 1'b0;
      ar_gvalid[s] = 1'b0;
      aw_gmaster[s] = '0;
      ar_gmaster[s] = '0;

      if (!ar_out_v[s]) begin
        for (k = 0; k < NUM_MST; k = k + 1) begin
          idx = (ar_rr[s] + k) % NUM_MST;
          if (!ar_gvalid[s] && ar_try[idx] && ar_dec_ok[idx] &&
              (ar_dec_route[idx] == s[2:0])) begin
            ar_gvalid[s] = 1'b1;
            ar_gmaster[s] = idx[MST_PTR_W-1:0];
          end
        end
      end
      if (ar_gvalid[s])
        ar_grant[ar_gmaster[s]] = 1'b1;

      if (!aw_out_v[s] && (swq_count[s] < NUM_MST_SC)) begin
        for (k = 0; k < NUM_MST; k = k + 1) begin
          idx = (aw_rr[s] + k) % NUM_MST;
          if (!aw_gvalid[s] && head_valid[idx] &&
              !head_aw_sent[idx] && !head_decerr[idx] &&
              (head_route[idx] == s[2:0])) begin
            aw_gvalid[s] = 1'b1;
            aw_gmaster[s] = idx[MST_PTR_W-1:0];
          end
        end
      end
    end

    for (m = 0; m < NUM_MST; m = m + 1) begin
      aw_alloc[m] = aw_try[m];
      ar_alloc[m] = ar_try[m] && (!ar_dec_ok[m] || ar_grant[m]);
    end
  end

  always_comb begin : b_arbitration
    integer m;
    integer k;
    integer idx;
    slv_b_ready = '0;
    for (m = 0; m < NUM_MST; m = m + 1) begin
      b_load[m] = 1'b0;
      b_load_local[m] = 1'b0;
      b_src[m] = '0;
      if (!b_out_v[m]) begin
        for (k = 0; k < SRC_N; k = k + 1) begin
          idx = (b_rr[m] + k) % SRC_N;
          if (!b_load[m]) begin
            if (idx < NUM_SLV) begin
              if (slv_resp[idx].b_valid &&
                  (slv_resp[idx].b.id[MST_ID_W-1:SLV_ID_W]
                     == m[MST_IDX_W-1:0])) begin
                b_load[m] = 1'b1;
                b_src[m] = idx[SRC_W-1:0];
                slv_b_ready[idx] = 1'b1;
              end
            end else if (err_b_valid[m]) begin
              b_load[m] = 1'b1;
              b_load_local[m] = 1'b1;
              b_src[m] = LOCAL_SRC;
            end
          end
        end
      end
    end
  end

  always_comb begin : r_arbitration
    integer m;
    integer i;
    integer k;
    integer idx;
    slv_r_ready = '0;
    for (m = 0; m < NUM_MST; m = m + 1) begin
      local_any[m] = 1'b0;
      local_pick[m] = '0;
      for (i = 0; i < ID_NUM; i = i + 1) begin
        if (!local_any[m] && rd_valid[m][i] && rd_decerr[m][i]) begin
          local_any[m] = 1'b1;
          local_pick[m] = i[SLV_ID_W-1:0];
        end
      end

      r_load[m] = 1'b0;
      r_load_local[m] = 1'b0;
      r_start[m] = 1'b0;
      r_src[m] = '0;
      r_local_pick[m] = '0;

      if (!r_out_v[m]) begin
        if (r_lock_v[m]) begin
          r_src[m] = r_lock_src[m];
          if (r_lock_src[m] == LOCAL_SRC) begin
            r_load[m] = 1'b1;
            r_load_local[m] = 1'b1;
            r_local_pick[m] = local_r_id[m];
          end else if (slv_resp[r_lock_src[m]].r_valid &&
                       (slv_resp[r_lock_src[m]].r.id[MST_ID_W-1:SLV_ID_W]
                          == m[MST_IDX_W-1:0])) begin
            r_load[m] = 1'b1;
            slv_r_ready[r_lock_src[m]] = 1'b1;
          end
        end else begin
          for (k = 0; k < SRC_N; k = k + 1) begin
            idx = (r_rr[m] + k) % SRC_N;
            if (!r_load[m]) begin
              if (idx < NUM_SLV) begin
                if (slv_resp[idx].r_valid &&
                    (slv_resp[idx].r.id[MST_ID_W-1:SLV_ID_W]
                       == m[MST_IDX_W-1:0])) begin
                  r_load[m] = 1'b1;
                  r_start[m] = 1'b1;
                  r_src[m] = idx[SRC_W-1:0];
                  slv_r_ready[idx] = 1'b1;
                end
              end else if (local_any[m]) begin
                r_load[m] = 1'b1;
                r_load_local[m] = 1'b1;
                r_start[m] = 1'b1;
                r_src[m] = LOCAL_SRC;
                r_local_pick[m] = local_pick[m];
              end
            end
          end
        end
      end
    end
  end

  always_comb begin : w_movement
    integer m;
    integer s;
    for (m = 0; m < NUM_MST; m = m + 1) begin
      w_consume_err[m] = 1'b0;
      w_pop[m] = 1'b0;
      if (w_buf_v[m] && head_valid[m] && head_aw_sent[m] &&
          head_decerr[m] && !err_b_valid[m]) begin
        w_consume_err[m] = 1'b1;
        if (w_buf[m].last)
          w_pop[m] = 1'b1;
      end
    end

    for (s = 0; s < NUM_SLV; s = s + 1) begin
      w_load[s] = 1'b0;
      w_load_m[s] = '0;
      swq_push[s] = aw_out_v[s] && slv_resp[s].aw_ready;
      swq_pop[s] = 1'b0;

      if (!w_out_v[s] && (swq_count[s] != '0) &&
          w_buf_v[swq_head_master[s]] &&
          head_valid[swq_head_master[s]] &&
          head_aw_sent[swq_head_master[s]] &&
          !head_decerr[swq_head_master[s]] &&
          (head_route[swq_head_master[s]] == s[2:0])) begin
        w_load[s] = 1'b1;
        w_load_m[s] = swq_head_master[s];
      end

      if (w_out_v[s] && slv_resp[s].w_ready && w_out[s].last) begin
        swq_pop[s] = 1'b1;
        w_pop[swq_head_master[s]] = 1'b1;
      end
    end
  end

  always_comb begin : retire_logic
    integer m;
    for (m = 0; m < NUM_MST; m = m + 1) begin
      alloc[m] = aw_alloc[m] || ar_alloc[m];
      rd_retire[m] = r_out_v[m] && mst_req[m].r_ready && r_out[m].last;
      wr_retire[m] = b_out_v[m] && mst_req[m].b_ready;
    end
  end

  always_ff @(posedge clk) begin : state_update
    integer m;
    integer s;
    integer i;
    if (!rst_n) begin
      for (m = 0; m < NUM_MST; m = m + 1) begin
        aw_buf_v[m] <= 1'b0;
        ar_buf_v[m] <= 1'b0;
        w_buf_v[m] <= 1'b0;
        outstanding[m] <= '0;
        req_turn[m] <= 1'b0;
        wr_head[m] <= '0;
        wr_tail[m] <= '0;
        wr_count[m] <= '0;
        err_b_valid[m] <= 1'b0;
        err_b_id[m] <= '0;
        b_out_v[m] <= 1'b0;
        r_out_v[m] <= 1'b0;
        b_rr[m] <= '0;
        r_rr[m] <= '0;
        r_lock_v[m] <= 1'b0;
        r_lock_src[m] <= '0;
        local_r_id[m] <= '0;
        local_r_pos[m] <= '0;
        for (i = 0; i < ID_NUM; i = i + 1) begin
          id_busy[m][i] <= 1'b0;
          rd_valid[m][i] <= 1'b0;
          rd_decerr[m][i] <= 1'b0;
          rd_len[m][i] <= '0;
          wr_valid[m][i] <= 1'b0;
        end
      end
      for (s = 0; s < NUM_SLV; s = s + 1) begin
        aw_out_v[s] <= 1'b0;
        ar_out_v[s] <= 1'b0;
        w_out_v[s] <= 1'b0;
        aw_rr[s] <= '0;
        ar_rr[s] <= '0;
        swq_head[s] <= '0;
        swq_tail[s] <= '0;
        swq_count[s] <= '0;
      end
    end else begin
      // Input registers.
      for (m = 0; m < NUM_MST; m = m + 1) begin
        if (mst_req[m].aw_valid && !aw_buf_v[m]) begin
          aw_buf[m] <= mst_req[m].aw;
          aw_buf_v[m] <= 1'b1;
        end
        if (mst_req[m].ar_valid && !ar_buf_v[m]) begin
          ar_buf[m] <= mst_req[m].ar;
          ar_buf_v[m] <= 1'b1;
        end
        if (mst_req[m].w_valid && !w_buf_v[m]) begin
          w_buf[m] <= mst_req[m].w;
          w_buf_v[m] <= 1'b1;
        end
      end

      // Output handshakes.
      for (s = 0; s < NUM_SLV; s = s + 1) begin
        if (aw_out_v[s] && slv_resp[s].aw_ready)
          aw_out_v[s] <= 1'b0;
        if (ar_out_v[s] && slv_resp[s].ar_ready)
          ar_out_v[s] <= 1'b0;
        if (w_out_v[s] && slv_resp[s].w_ready)
          w_out_v[s] <= 1'b0;
      end
      for (m = 0; m < NUM_MST; m = m + 1) begin
        if (b_out_v[m] && mst_req[m].b_ready)
          b_out_v[m] <= 1'b0;
        if (r_out_v[m] && mst_req[m].r_ready)
          r_out_v[m] <= 1'b0;
      end

      // Retire responses only when the originating master accepts them.
      for (m = 0; m < NUM_MST; m = m + 1) begin
        if (rd_retire[m]) begin
          id_busy[m][r_out[m].id] <= 1'b0;
          rd_valid[m][r_out[m].id] <= 1'b0;
          rd_decerr[m][r_out[m].id] <= 1'b0;
        end
        if (wr_retire[m]) begin
          id_busy[m][b_out[m].id] <= 1'b0;
          wr_valid[m][b_out[m].id] <= 1'b0;
        end
      end

      // Allocate at most one new AW or AR transaction per master per cycle.
      for (m = 0; m < NUM_MST; m = m + 1) begin
        if (aw_alloc[m]) begin
          aw_buf_v[m] <= 1'b0;
          id_busy[m][aw_buf[m].id] <= 1'b1;
          wr_valid[m][aw_buf[m].id] <= 1'b1;
          req_turn[m] <= 1'b1;
          wr_aw_fifo[m][wr_tail[m]] <= aw_buf[m];
          wr_route_fifo[m][wr_tail[m]] <= aw_dec_route[m];
          wr_decerr_fifo[m][wr_tail[m]] <= !aw_dec_ok[m];
          wr_aw_sent_fifo[m][wr_tail[m]] <= !aw_dec_ok[m];
          wr_tail[m] <= wr_tail[m] + 1'b1;
        end
        if (ar_alloc[m]) begin
          ar_buf_v[m] <= 1'b0;
          id_busy[m][ar_buf[m].id] <= 1'b1;
          rd_valid[m][ar_buf[m].id] <= 1'b1;
          rd_decerr[m][ar_buf[m].id] <= !ar_dec_ok[m];
          rd_len[m][ar_buf[m].id] <= ar_buf[m].len;
          req_turn[m] <= 1'b0;
        end

        case ({aw_alloc[m], w_pop[m]})
          2'b10: wr_count[m] <= wr_count[m] + 1'b1;
          2'b01: wr_count[m] <= wr_count[m] - 1'b1;
          default: wr_count[m] <= wr_count[m];
        endcase

        if (w_pop[m]) begin
          wr_aw_sent_fifo[m][wr_head[m]] <= 1'b0;
          wr_head[m] <= wr_head[m] + 1'b1;
        end

        case ({alloc[m], rd_retire[m], wr_retire[m]})
          3'b100: outstanding[m] <= outstanding[m] + 1'b1;
          3'b010,
          3'b001: outstanding[m] <= outstanding[m] - 1'b1;
          3'b011: outstanding[m] <= outstanding[m] - CNT_W'(2);
          3'b111: outstanding[m] <= outstanding[m] - 1'b1;
          default: outstanding[m] <= outstanding[m];
        endcase
      end

      // Load registered AW and AR outputs.
      for (s = 0; s < NUM_SLV; s = s + 1) begin
        if (aw_gvalid[s]) begin
          aw_out[s] <= widen_aw(head_aw[aw_gmaster[s]], aw_gmaster[s]);
          aw_out_v[s] <= 1'b1;
          aw_rr[s] <= aw_gmaster[s] + 1'b1;
        end
        if (ar_gvalid[s]) begin
          ar_out[s] <= widen_ar(ar_buf[ar_gmaster[s]], ar_gmaster[s]);
          ar_out_v[s] <= 1'b1;
          ar_rr[s] <= ar_gmaster[s] + 1'b1;
        end
      end

      // Record AW order at each slave and release the corresponding W burst.
      for (s = 0; s < NUM_SLV; s = s + 1) begin
        if (swq_push[s]) begin
          swq_master[s][swq_tail[s]] <= aw_out_master[s];
          swq_tail[s] <= swq_tail[s] + 1'b1;
          wr_aw_sent_fifo[aw_out_master[s]][wr_head[aw_out_master[s]]]
            <= 1'b1;
        end
        if (swq_pop[s])
          swq_head[s] <= swq_head[s] + 1'b1;

        case ({swq_push[s], swq_pop[s]})
          2'b10: swq_count[s] <= swq_count[s] + 1'b1;
          2'b01: swq_count[s] <= swq_count[s] - 1'b1;
          default: swq_count[s] <= swq_count[s];
        endcase

        if (w_load[s]) begin
          w_out[s] <= w_buf[w_load_m[s]];
          w_out_v[s] <= 1'b1;
          w_buf_v[w_load_m[s]] <= 1'b0;
        end
      end

      // Decode-error writes discard their W beats and generate one B beat.
      for (m = 0; m < NUM_MST; m = m + 1) begin
        if (w_consume_err[m]) begin
          w_buf_v[m] <= 1'b0;
          if (w_buf[m].last) begin
            err_b_valid[m] <= 1'b1;
            err_b_id[m] <= head_aw[m].id;
          end
        end
      end

      // Load B outputs using round-robin source selection.
      for (m = 0; m < NUM_MST; m = m + 1) begin
        if (b_load[m]) begin
          b_out_v[m] <= 1'b1;
          if (b_load_local[m]) begin
            b_out[m].id <= err_b_id[m];
            b_out[m].resp <= RESP_DECERR;
            b_out[m].user <= '0;
            err_b_valid[m] <= 1'b0;
          end else begin
            b_out[m].id <= slv_resp[b_src[m]].b.id[SLV_ID_W-1:0];
            b_out[m].resp <= slv_resp[b_src[m]].b.resp;
            b_out[m].user <= slv_resp[b_src[m]].b.user;
          end
          if (b_src[m] == LOCAL_SRC)
            b_rr[m] <= '0;
          else
            b_rr[m] <= b_src[m] + 1'b1;
        end
      end

      // Load R outputs.  Local DECERR reads are generated one beat at a time.
      for (m = 0; m < NUM_MST; m = m + 1) begin
        if (r_load[m]) begin
          r_out_v[m] <= 1'b1;
          if (r_load_local[m]) begin
            r_out[m].id <= r_local_pick[m];
            r_out[m].data <= '0;
            r_out[m].resp <= RESP_DECERR;
            r_out[m].user <= '0;
            if (r_start[m]) begin
              local_r_id[m] <= r_local_pick[m];
              if (rd_len[m][r_local_pick[m]] == 8'd0) begin
                r_out[m].last <= 1'b1;
                r_lock_v[m] <= 1'b0;
              end else begin
                r_out[m].last <= 1'b0;
                r_lock_v[m] <= 1'b1;
                r_lock_src[m] <= LOCAL_SRC;
                local_r_pos[m] <= 8'd1;
              end
            end else begin
              if (local_r_pos[m] == rd_len[m][local_r_id[m]]) begin
                r_out[m].last <= 1'b1;
                r_lock_v[m] <= 1'b0;
              end else begin
                r_out[m].last <= 1'b0;
                r_lock_v[m] <= 1'b1;
                r_lock_src[m] <= LOCAL_SRC;
                local_r_pos[m] <= local_r_pos[m] + 1'b1;
              end
            end
          end else begin
            r_out[m].id <= slv_resp[r_src[m]].r.id[SLV_ID_W-1:0];
            r_out[m].data <= slv_resp[r_src[m]].r.data;
            r_out[m].resp <= slv_resp[r_src[m]].r.resp;
            r_out[m].last <= slv_resp[r_src[m]].r.last;
            r_out[m].user <= slv_resp[r_src[m]].r.user;
            if (slv_resp[r_src[m]].r.last) begin
              r_lock_v[m] <= 1'b0;
            end else begin
              r_lock_v[m] <= 1'b1;
              r_lock_src[m] <= r_src[m];
            end
          end

          if (r_start[m]) begin
            if (r_src[m] == LOCAL_SRC)
              r_rr[m] <= '0;
            else
              r_rr[m] <= r_src[m] + 1'b1;
          end
        end
      end
    end
  end

endmodule
