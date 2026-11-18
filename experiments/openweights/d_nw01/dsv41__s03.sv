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

  localparam int MST_IDX_W = 2;
  localparam int SLV_ID_W = 4;
  localparam int MST_ID_W = 6;

  typedef struct packed {
    slv_aw_t aw;
    logic [1:0] slave_idx;
    logic dec_err;
    logic aw_sent;
    logic [7:0] w_count;
  } wr_entry_t;

  typedef struct packed {
    slv_b_t b;
  } b_entry_t;

  typedef struct packed {
    slv_ar_t ar;
    logic [1:0] slave_idx;
    logic dec_err;
  } rd_entry_t;

  typedef struct packed {
    slv_r_t r;
  } r_entry_t;

  wr_entry_t wr_q [NUM_MST-1:0][MAX_TRANS-1:0];
  logic [3:0] wr_head [NUM_MST-1:0];
  logic [3:0] wr_tail [NUM_MST-1:0];
  logic [3:0] wr_count [NUM_MST-1:0];
  logic [3:0] wr_outstanding [NUM_MST-1:0];
  logic [15:0] wr_busy [NUM_MST-1:0];

  b_entry_t b_q [NUM_MST-1:0][MAX_TRANS-1:0];
  logic [3:0] b_head [NUM_MST-1:0];
  logic [3:0] b_tail [NUM_MST-1:0];
  logic [3:0] b_count [NUM_MST-1:0];

  rd_entry_t rd_q [NUM_MST-1:0][MAX_TRANS-1:0];
  logic [3:0] rd_head [NUM_MST-1:0];
  logic [3:0] rd_tail [NUM_MST-1:0];
  logic [3:0] rd_count [NUM_MST-1:0];
  logic [3:0] rd_outstanding [NUM_MST-1:0];
  logic [15:0] rd_busy [NUM_MST-1:0];

  r_entry_t r_q [NUM_MST-1:0][3:0];
  logic [1:0] r_head [NUM_MST-1:0];
  logic [1:0] r_tail [NUM_MST-1:0];
  logic [2:0] r_count [NUM_MST-1:0];

  logic dec_rd_active [NUM_MST-1:0];
  slv_ar_t dec_rd_ar [NUM_MST-1:0];
  logic [7:0] dec_rd_count [NUM_MST-1:0];
  logic r_local_prio [NUM_MST-1:0];

  logic [1:0] slv_aw_fifo [NUM_SLV-1:0][3:0];
  logic [2:0] slv_aw_head [NUM_SLV-1:0];
  logic [2:0] slv_aw_tail [NUM_SLV-1:0];
  logic [2:0] slv_aw_count [NUM_SLV-1:0];

  logic [1:0] aw_rr [NUM_SLV-1:0];
  logic [1:0] ar_rr [NUM_SLV-1:0];
  logic [1:0] b_rr [NUM_MST-1:0];
  logic [1:0] r_rr [NUM_MST-1:0];

  logic [1:0] aw_slave_idx [NUM_MST-1:0];
  logic aw_dec_err [NUM_MST-1:0];
  logic [1:0] ar_slave_idx [NUM_MST-1:0];
  logic ar_dec_err [NUM_MST-1:0];

  logic aw_valid_sel [NUM_SLV-1:0];
  logic [1:0] aw_mst_sel [NUM_SLV-1:0];
  logic ar_valid_sel [NUM_SLV-1:0];
  logic [1:0] ar_mst_sel [NUM_SLV-1:0];

  logic b_sel_valid [NUM_MST-1:0];
  logic [1:0] b_mst_sel [NUM_MST-1:0];
  logic r_sel_valid [NUM_MST-1:0];
  logic [1:0] r_mst_sel [NUM_MST-1:0];

  logic b_ready_sel [NUM_SLV-1:0];
  logic r_ready_sel [NUM_SLV-1:0];

  logic w_ready_m [NUM_MST-1:0];

  logic local_r_avail [NUM_MST-1:0];
  logic local_b_avail [NUM_MST-1:0];
  logic r_push_valid [NUM_MST-1:0];
  logic r_push_local [NUM_MST-1:0];
  logic b_push_valid [NUM_MST-1:0];
  logic b_push_local [NUM_MST-1:0];

  logic aw_hs [NUM_MST-1:0];
  logic ar_hs [NUM_MST-1:0];
  logic w_hs [NUM_MST-1:0];
  logic b_hs [NUM_MST-1:0];
  logic r_hs [NUM_MST-1:0];
  logic slv_aw_hs [NUM_SLV-1:0];
  logic slv_ar_hs [NUM_SLV-1:0];
  logic slv_w_hs [NUM_SLV-1:0];
  logic slv_b_hs [NUM_SLV-1:0];
  logic slv_r_hs [NUM_SLV-1:0];

  logic w_last [NUM_MST-1:0];
  logic r_last_hs [NUM_MST-1:0];
  logic start_dec_rd [NUM_MST-1:0];
  logic rd_pop_comb [NUM_MST-1:0];
  logic w_last_slv [NUM_SLV-1:0];

  function automatic void decode_addr(input addr_t addr, output logic [1:0] slave_idx, output logic dec_err);
    dec_err = 1'b1;
    slave_idx = 2'b0;
    for (int i = 0; i < NUM_SLV; i++) begin
      if (addr >= addr_map[i].start_addr && addr < addr_map[i].end_addr) begin
        dec_err = 1'b0;
        slave_idx = addr_map[i].mst_port;
      end
    end
  endfunction

  always_comb begin
    int m;
    for (m = 0; m < NUM_MST; m++) begin
      decode_addr(mst_req[m].aw.addr, aw_slave_idx[m], aw_dec_err[m]);
      decode_addr(mst_req[m].ar.addr, ar_slave_idx[m], ar_dec_err[m]);
    end
  end

  always_comb begin
    int m;
    for (m = 0; m < NUM_MST; m++) begin
      mst_resp[m].aw_ready = (wr_outstanding[m] < MAX_TRANS) && (wr_count[m] < MAX_TRANS) && !wr_busy[m][mst_req[m].aw.id] && rst_n;
      mst_resp[m].ar_ready = (rd_outstanding[m] < MAX_TRANS) && (rd_count[m] < MAX_TRANS) && !rd_busy[m][mst_req[m].ar.id] && rst_n;
      mst_resp[m].w_ready = w_ready_m[m] && rst_n;
      mst_resp[m].b_valid = (b_count[m] > 0) && rst_n;
      mst_resp[m].b = b_q[m][b_head[m]].b;
      mst_resp[m].r_valid = (r_count[m] > 0) && rst_n;
      mst_resp[m].r = r_q[m][r_head[m]].r;
    end
  end

  always_comb begin
    int s, m;
    for (s = 0; s < NUM_SLV; s++) begin
      slv_req[s].aw_valid = aw_valid_sel[s] && rst_n;
      slv_req[s].aw = '0;
      if (aw_valid_sel[s]) begin
        m = aw_mst_sel[s];
        slv_req[s].aw.id = {m[1:0], mst_req[m].aw.id};
        slv_req[s].aw.addr = mst_req[m].aw.addr;
        slv_req[s].aw.len = mst_req[m].aw.len;
        slv_req[s].aw.size = mst_req[m].aw.size;
        slv_req[s].aw.burst = mst_req[m].aw.burst;
        slv_req[s].aw.lock = mst_req[m].aw.lock;
        slv_req[s].aw.cache = mst_req[m].aw.cache;
        slv_req[s].aw.prot = mst_req[m].aw.prot;
        slv_req[s].aw.qos = mst_req[m].aw.qos;
        slv_req[s].aw.region = mst_req[m].aw.region;
        slv_req[s].aw.atop = mst_req[m].aw.atop;
        slv_req[s].aw.user = mst_req[m].aw.user;
      end

      slv_req[s].ar_valid = ar_valid_sel[s] && rst_n;
      slv_req[s].ar = '0;
      if (ar_valid_sel[s]) begin
        m = ar_mst_sel[s];
        slv_req[s].ar.id = {m[1:0], mst_req[m].ar.id};
        slv_req[s].ar.addr = mst_req[m].ar.addr;
        slv_req[s].ar.len = mst_req[m].ar.len;
        slv_req[s].ar.size = mst_req[m].ar.size;
        slv_req[s].ar.burst = mst_req[m].ar.burst;
        slv_req[s].ar.lock = mst_req[m].ar.lock;
        slv_req[s].ar.cache = mst_req[m].ar.cache;
        slv_req[s].ar.prot = mst_req[m].ar.prot;
        slv_req[s].ar.qos = mst_req[m].ar.qos;
        slv_req[s].ar.region = mst_req[m].ar.region;
        slv_req[s].ar.user = mst_req[m].ar.user;
      end

      if (slv_aw_count[s] > 0) begin
        m = slv_aw_fifo[s][slv_aw_head[s]];
        slv_req[s].w_valid = mst_req[m].w_valid && rst_n;
        slv_req[s].w = mst_req[m].w;
      end else begin
        slv_req[s].w_valid = 1'b0;
        slv_req[s].w = '0;
      end

      slv_req[s].b_ready = b_ready_sel[s] && rst_n;
      slv_req[s].r_ready = r_ready_sel[s] && rst_n;
    end
  end

  always_comb begin
    int s, i, m;
    for (s = 0; s < NUM_SLV; s++) begin
      aw_valid_sel[s] = 0;
      aw_mst_sel[s] = 0;
    end
    for (s = 0; s < NUM_SLV; s++) begin
      for (i = 0; i < NUM_MST; i++) begin
        m = (aw_rr[s] + i) % NUM_MST;
        if (!aw_valid_sel[s] && wr_count[m] > 0 && !wr_q[m][wr_head[m]].dec_err && !wr_q[m][wr_head[m]].aw_sent && wr_q[m][wr_head[m]].slave_idx == s) begin
          aw_valid_sel[s] = 1;
          aw_mst_sel[s] = m[1:0];
        end
      end
    end
  end

  always_comb begin
    int s, i, m;
    for (s = 0; s < NUM_SLV; s++) begin
      ar_valid_sel[s] = 0;
      ar_mst_sel[s] = 0;
    end
    for (s = 0; s < NUM_SLV; s++) begin
      for (i = 0; i < NUM_MST; i++) begin
        m = (ar_rr[s] + i) % NUM_MST;
        if (!ar_valid_sel[s] && rd_count[m] > 0 && !rd_q[m][rd_head[m]].dec_err && rd_q[m][rd_head[m]].slave_idx == s) begin
          ar_valid_sel[s] = 1;
          ar_mst_sel[s] = m[1:0];
        end
      end
    end
  end

  always_comb begin
    int m, i, s;
    for (m = 0; m < NUM_MST; m++) begin
      b_sel_valid[m] = 0;
      b_mst_sel[m] = 0;
    end
    for (m = 0; m < NUM_MST; m++) begin
      if (b_count[m] < MAX_TRANS) begin
        for (i = 0; i < NUM_SLV; i++) begin
          s = (b_rr[m] + i) % NUM_SLV;
          if (!b_sel_valid[m] && slv_resp[s].b_valid && slv_resp[s].b.id[MST_ID_W-1:SLV_ID_W] == m[1:0]) begin
            b_sel_valid[m] = 1;
            b_mst_sel[m] = s[1:0];
          end
        end
      end
    end
  end

  always_comb begin
    int m, i, s;
    for (m = 0; m < NUM_MST; m++) begin
      r_sel_valid[m] = 0;
      r_mst_sel[m] = 0;
    end
    for (m = 0; m < NUM_MST; m++) begin
      if (r_count[m] < 4) begin
        for (i = 0; i < NUM_SLV; i++) begin
          s = (r_rr[m] + i) % NUM_SLV;
          if (!r_sel_valid[m] && slv_resp[s].r_valid && slv_resp[s].r.id[MST_ID_W-1:SLV_ID_W] == m[1:0]) begin
            r_sel_valid[m] = 1;
            r_mst_sel[m] = s[1:0];
          end
        end
      end
    end
  end

  always_comb begin
    int m;
    for (m = 0; m < NUM_MST; m++) begin
      local_r_avail[m] = dec_rd_active[m] && (r_count[m] < 4);
      local_b_avail[m] = (mst_req[m].w_valid && mst_resp[m].w_ready && wr_count[m] > 0 && wr_q[m][wr_head[m]].dec_err && (wr_q[m][wr_head[m]].w_count == wr_q[m][wr_head[m]].aw.len));

      if (local_r_avail[m] && r_sel_valid[m]) begin
        if (r_local_prio[m]) begin
          r_push_valid[m] = 1;
          r_push_local[m] = 1;
        end else begin
          r_push_valid[m] = 1;
          r_push_local[m] = 0;
        end
      end else if (local_r_avail[m]) begin
        r_push_valid[m] = 1;
        r_push_local[m] = 1;
      end else if (r_sel_valid[m]) begin
        r_push_valid[m] = 1;
        r_push_local[m] = 0;
      end else begin
        r_push_valid[m] = 0;
        r_push_local[m] = 0;
      end

      if (local_b_avail[m]) begin
        b_push_valid[m] = 1;
        b_push_local[m] = 1;
      end else if (b_sel_valid[m]) begin
        b_push_valid[m] = 1;
        b_push_local[m] = 0;
      end else begin
        b_push_valid[m] = 0;
        b_push_local[m] = 0;
      end
    end
  end

  always_comb begin
    int s, m;
    for (s = 0; s < NUM_SLV; s++) begin
      b_ready_sel[s] = 0;
      if (slv_resp[s].b_valid) begin
        m = slv_resp[s].b.id[MST_ID_W-1:SLV_ID_W];
        if (b_push_valid[m] && !b_push_local[m] && b_mst_sel[m] == s) begin
          b_ready_sel[s] = 1;
        end
      end
      r_ready_sel[s] = 0;
      if (slv_resp[s].r_valid) begin
        m = slv_resp[s].r.id[MST_ID_W-1:SLV_ID_W];
        if (r_push_valid[m] && !r_push_local[m] && r_mst_sel[m] == s) begin
          r_ready_sel[s] = 1;
        end
      end
    end
  end

  always_comb begin
    int m, s;
    for (m = 0; m < NUM_MST; m++) begin
      w_ready_m[m] = 0;
      if (wr_count[m] > 0) begin
        if (wr_q[m][wr_head[m]].dec_err) begin
          w_ready_m[m] = 1;
        end else if (wr_q[m][wr_head[m]].aw_sent) begin
          s = wr_q[m][wr_head[m]].slave_idx;
          if (slv_aw_count[s] > 0 && slv_aw_fifo[s][slv_aw_head[s]] == m[1:0]) begin
            w_ready_m[m] = slv_resp[s].w_ready;
          end
        end
      end
    end
  end

  always_comb begin
    int m, s;
    for (m = 0; m < NUM_MST; m++) begin
      aw_hs[m] = mst_req[m].aw_valid && mst_resp[m].aw_ready;
      ar_hs[m] = mst_req[m].ar_valid && mst_resp[m].ar_ready;
      w_hs[m] = mst_req[m].w_valid && mst_resp[m].w_ready;
      b_hs[m] = mst_resp[m].b_valid && mst_req[m].b_ready;
      r_hs[m] = mst_resp[m].r_valid && mst_req[m].r_ready;
    end
    for (s = 0; s < NUM_SLV; s++) begin
      slv_aw_hs[s] = slv_req[s].aw_valid && slv_resp[s].aw_ready;
      slv_ar_hs[s] = slv_req[s].ar_valid && slv_resp[s].ar_ready;
      slv_w_hs[s] = slv_req[s].w_valid && slv_resp[s].w_ready;
      slv_b_hs[s] = slv_resp[s].b_valid && slv_req[s].b_ready;
      slv_r_hs[s] = slv_resp[s].r_valid && slv_req[s].r_ready;
    end
  end

  always_comb begin
    int m, s;
    for (m = 0; m < NUM_MST; m++) begin
      w_last[m] = w_hs[m] && (wr_count[m] > 0) && (wr_q[m][wr_head[m]].w_count == wr_q[m][wr_head[m]].aw.len);
      r_last_hs[m] = r_hs[m] && (r_count[m] > 0) && r_q[m][r_head[m]].r.last;
      start_dec_rd[m] = (!dec_rd_active[m] && rd_count[m] > 0 && rd_q[m][rd_head[m]].dec_err);
      rd_pop_comb[m] = start_dec_rd[m];
      for (s = 0; s < NUM_SLV; s++) begin
        if (slv_ar_hs[s] && ar_mst_sel[s] == m) rd_pop_comb[m] = 1;
      end
    end
    for (s = 0; s < NUM_SLV; s++) begin
      w_last_slv[s] = 0;
      for (m = 0; m < NUM_MST; m++) begin
        if (w_last[m] && !wr_q[m][wr_head[m]].dec_err && wr_q[m][wr_head[m]].slave_idx == s) begin
          w_last_slv[s] = 1;
        end
      end
    end
  end

  always_ff @(posedge clk) begin
    int m, s, i;
    if (!rst_n) begin
      for (m = 0; m < NUM_MST; m++) begin
        wr_head[m] <= 0;
        wr_tail[m] <= 0;
        wr_count[m] <= 0;
        wr_outstanding[m] <= 0;
        wr_busy[m] <= '0;
        b_head[m] <= 0;
        b_tail[m] <= 0;
        b_count[m] <= 0;
        rd_head[m] <= 0;
        rd_tail[m] <= 0;
        rd_count[m] <= 0;
        rd_outstanding[m] <= 0;
        rd_busy[m] <= '0;
        r_head[m] <= 0;
        r_tail[m] <= 0;
        r_count[m] <= 0;
        dec_rd_active[m] <= 0;
        dec_rd_ar[m] <= '0;
        dec_rd_count[m] <= 0;
        r_local_prio[m] <= 0;
        b_rr[m] <= 0;
        r_rr[m] <= 0;
        for (i = 0; i < MAX_TRANS; i++) begin
          wr_q[m][i] <= '0;
          b_q[m][i] <= '0;
          rd_q[m][i] <= '0;
        end
        for (i = 0; i < 4; i++) begin
          r_q[m][i] <= '0;
        end
      end
      for (s = 0; s < NUM_SLV; s++) begin
        slv_aw_head[s] <= 0;
        slv_aw_tail[s] <= 0;
        slv_aw_count[s] <= 0;
        aw_rr[s] <= 0;
        ar_rr[s] <= 0;
        for (i = 0; i < 4; i++) begin
          slv_aw_fifo[s][i] <= '0;
        end
      end
    end else begin
      for (m = 0; m < NUM_MST; m++) begin
        if (aw_hs[m]) begin
          wr_q[m][wr_tail[m]].aw <= mst_req[m].aw;
          wr_q[m][wr_tail[m]].slave_idx <= aw_slave_idx[m];
          wr_q[m][wr_tail[m]].dec_err <= aw_dec_err[m];
          wr_q[m][wr_tail[m]].aw_sent <= 0;
          wr_q[m][wr_tail[m]].w_count <= 0;
          wr_tail[m] <= (wr_tail[m] + 1) % MAX_TRANS;
          wr_busy[m][mst_req[m].aw.id] <= 1;
        end
      end

      for (m = 0; m < NUM_MST; m++) begin
        if (ar_hs[m]) begin
          rd_q[m][rd_tail[m]].ar <= mst_req[m].ar;
          rd_q[m][rd_tail[m]].slave_idx <= ar_slave_idx[m];
          rd_q[m][rd_tail[m]].dec_err <= ar_dec_err[m];
          rd_tail[m] <= (rd_tail[m] + 1) % MAX_TRANS;
          rd_busy[m][mst_req[m].ar.id] <= 1;
        end
      end

      for (s = 0; s < NUM_SLV; s++) begin
        if (slv_aw_hs[s]) begin
          m = aw_mst_sel[s];
          wr_q[m][wr_head[m]].aw_sent <= 1;
          slv_aw_fifo[s][slv_aw_tail[s]] <= m[1:0];
          slv_aw_tail[s] <= (slv_aw_tail[s] + 1) % 4;
          aw_rr[s] <= (m + 1) % NUM_MST;
        end
      end

      for (s = 0; s < NUM_SLV; s++) begin
        if (slv_ar_hs[s]) begin
          m = ar_mst_sel[s];
          rd_head[m] <= (rd_head[m] + 1) % MAX_TRANS;
          ar_rr[s] <= (m + 1) % NUM_MST;
        end
      end

      for (m = 0; m < NUM_MST; m++) begin
        if (w_hs[m]) begin
          if (wr_q[m][wr_head[m]].dec_err) begin
            if (wr_q[m][wr_head[m]].w_count == wr_q[m][wr_head[m]].aw.len) begin
              wr_head[m] <= (wr_head[m] + 1) % MAX_TRANS;
            end else begin
              wr_q[m][wr_head[m]].w_count <= wr_q[m][wr_head[m]].w_count + 1;
            end
          end else begin
            if (wr_q[m][wr_head[m]].w_count == wr_q[m][wr_head[m]].aw.len) begin
              wr_head[m] <= (wr_head[m] + 1) % MAX_TRANS;
              s = wr_q[m][wr_head[m]].slave_idx;
              slv_aw_head[s] <= (slv_aw_head[s] + 1) % 4;
            end else begin
              wr_q[m][wr_head[m]].w_count <= wr_q[m][wr_head[m]].w_count + 1;
            end
          end
        end
      end

      for (m = 0; m < NUM_MST; m++) begin
        if (b_hs[m]) begin
          wr_busy[m][b_q[m][b_head[m]].b.id] <= 0;
          b_head[m] <= (b_head[m] + 1) % MAX_TRANS;
        end
      end

      for (m = 0; m < NUM_MST; m++) begin
        if (r_hs[m]) begin
          if (r_q[m][r_head[m]].r.last) begin
            rd_busy[m][r_q[m][r_head[m]].r.id] <= 0;
          end
          r_head[m] <= (r_head[m] + 1) % 4;
        end
      end

      for (m = 0; m < NUM_MST; m++) begin
        if (aw_hs[m] && w_last[m]) wr_count[m] <= wr_count[m];
        else if (aw_hs[m]) wr_count[m] <= wr_count[m] + 1;
        else if (w_last[m]) wr_count[m] <= wr_count[m] - 1;

        if (aw_hs[m] && b_hs[m]) wr_outstanding[m] <= wr_outstanding[m];
        else if (aw_hs[m]) wr_outstanding[m] <= wr_outstanding[m] + 1;
        else if (b_hs[m]) wr_outstanding[m] <= wr_outstanding[m] - 1;

        if (b_push_valid[m] && b_hs[m]) b_count[m] <= b_count[m];
        else if (b_push_valid[m]) b_count[m] <= b_count[m] + 1;
        else if (b_hs[m]) b_count[m] <= b_count[m] - 1;

        if (b_push_valid[m]) b_tail[m] <= (b_tail[m] + 1) % MAX_TRANS;

        if (ar_hs[m] && rd_pop_comb[m]) rd_count[m] <= rd_count[m];
        else if (ar_hs[m]) rd_count[m] <= rd_count[m] + 1;
        else if (rd_pop_comb[m]) rd_count[m] <= rd_count[m] - 1;

        if (ar_hs[m] && r_last_hs[m]) rd_outstanding[m] <= rd_outstanding[m];
        else if (ar_hs[m]) rd_outstanding[m] <= rd_outstanding[m] + 1;
        else if (r_last_hs[m]) rd_outstanding[m] <= rd_outstanding[m] - 1;

        if (r_push_valid[m] && r_hs[m]) r_count[m] <= r_count[m];
        else if (r_push_valid[m]) r_count[m] <= r_count[m] + 1;
        else if (r_hs[m]) r_count[m] <= r_count[m] - 1;

        if (r_push_valid[m]) r_tail[m] <= (r_tail[m] + 1) % 4;

        if (local_r_avail[m] && r_sel_valid[m]) r_local_prio[m] <= ~r_local_prio[m];
      end

      for (m = 0; m < NUM_MST; m++) begin
        if (b_push_valid[m]) begin
          if (b_push_local[m]) begin
            b_q[m][b_tail[m]].b.id <= wr_q[m][wr_head[m]].aw.id;
            b_q[m][b_tail[m]].b.resp <= RESP_DECERR;
            b_q[m][b_tail[m]].b.user <= wr_q[m][wr_head[m]].aw.user;
          end else begin
            s = b_mst_sel[m];
            b_q[m][b_tail[m]].b.id <= slv_resp[s].b.id[SLV_ID_W-1:0];
            b_q[m][b_tail[m]].b.resp <= slv_resp[s].b.resp;
            b_q[m][b_tail[m]].b.user <= slv_resp[s].b.user;
            b_rr[m] <= (s + 1) % NUM_SLV;
          end
        end
      end

      for (m = 0; m < NUM_MST; m++) begin
        if (r_push_valid[m]) begin
          if (r_push_local[m]) begin
            r_q[m][r_tail[m]].r.id <= dec_rd_ar[m].id;
            r_q[m][r_tail[m]].r.data <= '0;
            r_q[m][r_tail[m]].r.resp <= RESP_DECERR;
            r_q[m][r_tail[m]].r.last <= (dec_rd_count[m] == dec_rd_ar[m].len);
            r_q[m][r_tail[m]].r.user <= dec_rd_ar[m].user;
            if (dec_rd_count[m] == dec_rd_ar[m].len) begin
              dec_rd_active[m] <= 0;
            end else begin
              dec_rd_count[m] <= dec_rd_count[m] + 1;
            end
          end else begin
            s = r_mst_sel[m];
            r_q[m][r_tail[m]].r.id <= slv_resp[s].r.id[SLV_ID_W-1:0];
            r_q[m][r_tail[m]].r.data <= slv_resp[s].r.data;
            r_q[m][r_tail[m]].r.resp <= slv_resp[s].r.resp;
            r_q[m][r_tail[m]].r.last <= slv_resp[s].r.last;
            r_q[m][r_tail[m]].r.user <= slv_resp[s].r.user;
            r_rr[m] <= (s + 1) % NUM_SLV;
          end
        end
      end

      for (m = 0; m < NUM_MST; m++) begin
        if (start_dec_rd[m]) begin
          dec_rd_active[m] <= 1;
          dec_rd_ar[m] <= rd_q[m][rd_head[m]].ar;
          dec_rd_count[m] <= 0;
          rd_head[m] <= (rd_head[m] + 1) % MAX_TRANS;
        end
      end

      for (s = 0; s < NUM_SLV; s++) begin
        if (w_last_slv[s] && slv_aw_hs[s]) slv_aw_count[s] <= slv_aw_count[s];
        else if (w_last_slv[s]) slv_aw_count[s] <= slv_aw_count[s] - 1;
        else if (slv_aw_hs[s]) slv_aw_count[s] <= slv_aw_count[s] + 1;
      end
    end
  end

endmodule
