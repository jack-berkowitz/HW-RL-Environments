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

  localparam int PTR_W = (MAX_TRANS <= 2) ? 1 : $clog2(MAX_TRANS);
  localparam int CNT_W = $clog2(MAX_TRANS + 1);
  localparam int SLV_IDX_W = (NUM_SLV <= 2) ? 1 : $clog2(NUM_SLV);

  // Requests are tracked up to MAX_TRANS independently on each master port.
  // Only the oldest request of each kind is exposed to the slave side at a
  // time. This preserves ordering without having to buffer response data.
  mst_aw_t aw_q [NUM_MST-1:0][MAX_TRANS-1:0];
  mst_ar_t ar_q [NUM_MST-1:0][MAX_TRANS-1:0];

  logic [SLV_IDX_W-1:0] aw_target [NUM_MST-1:0][MAX_TRANS-1:0];
  logic [SLV_IDX_W-1:0] ar_target [NUM_MST-1:0][MAX_TRANS-1:0];
  logic aw_decerr [NUM_MST-1:0][MAX_TRANS-1:0];
  logic ar_decerr [NUM_MST-1:0][MAX_TRANS-1:0];
  logic aw_sent [NUM_MST-1:0][MAX_TRANS-1:0];
  logic ar_sent [NUM_MST-1:0][MAX_TRANS-1:0];
  logic aw_local_b [NUM_MST-1:0][MAX_TRANS-1:0];

  logic [PTR_W-1:0] aw_tail [NUM_MST-1:0];
  logic [PTR_W-1:0] aw_w_ptr [NUM_MST-1:0];
  logic [PTR_W-1:0] aw_b_ptr [NUM_MST-1:0];
  logic [PTR_W-1:0] ar_tail [NUM_MST-1:0];
  logic [PTR_W-1:0] ar_r_ptr [NUM_MST-1:0];

  logic [CNT_W-1:0] aw_count [NUM_MST-1:0];
  logic [CNT_W-1:0] ar_count [NUM_MST-1:0];

  logic [7:0] w_beat [NUM_MST-1:0];
  logic [7:0] dec_r_beat [NUM_MST-1:0];

  // Registered request outputs. A slave has one active write burst, which
  // fixes the untagged W-channel association and prevents W-order inversions.
  mst_aw_t aw_out [NUM_SLV-1:0];
  mst_ar_t ar_out [NUM_SLV-1:0];
  logic aw_out_valid [NUM_SLV-1:0];
  logic ar_out_valid [NUM_SLV-1:0];
  logic [MST_IDX_W-1:0] aw_out_src [NUM_SLV-1:0];

  logic wr_active [NUM_SLV-1:0];
  logic [MST_IDX_W-1:0] wr_owner [NUM_SLV-1:0];
  logic [7:0] wr_len [NUM_SLV-1:0];
  logic [7:0] wr_beat [NUM_SLV-1:0];

  logic [MST_IDX_W-1:0] rr_aw [NUM_SLV-1:0];
  logic [MST_IDX_W-1:0] rr_ar [NUM_SLV-1:0];

  logic aw_sel_valid [NUM_SLV-1:0];
  logic ar_sel_valid [NUM_SLV-1:0];
  logic [MST_IDX_W-1:0] aw_sel_m [NUM_SLV-1:0];
  logic [MST_IDX_W-1:0] ar_sel_m [NUM_SLV-1:0];

  logic [SLV_IDX_W:0] aw_decode [NUM_MST-1:0];
  logic [SLV_IDX_W:0] ar_decode [NUM_MST-1:0];
  logic aw_w_active [NUM_MST-1:0];

  logic aw_accept [NUM_MST-1:0];
  logic ar_accept [NUM_MST-1:0];
  logic w_fire [NUM_MST-1:0];
  logic w_last_fire [NUM_MST-1:0];
  logic b_fire [NUM_MST-1:0];
  logic r_fire [NUM_MST-1:0];
  logic r_last_fire [NUM_MST-1:0];

  function automatic logic [SLV_IDX_W:0] decode_addr(input addr_t addr);
    integer k;
    logic [SLV_IDX_W:0] d;
    begin
      d = {1'b1, {SLV_IDX_W{1'b0}}};
      for (k = 0; k < NUM_SLV; k = k + 1) begin
        if ((addr >= addr_map[k].start_addr) &&
            (addr < addr_map[k].end_addr)) begin
          d = {1'b0, addr_map[k].mst_port[SLV_IDX_W-1:0]};
        end
      end
      decode_addr = d;
    end
  endfunction

  function automatic mst_aw_t widen_aw(
      input slv_aw_t a,
      input logic [MST_IDX_W-1:0] mid
  );
    mst_aw_t t;
    begin
      t = '0;
      t.id = {mid, a.id};
      t.addr = a.addr;
      t.len = a.len;
      t.size = a.size;
      t.burst = a.burst;
      t.lock = a.lock;
      t.cache = a.cache;
      t.prot = a.prot;
      t.qos = a.qos;
      t.region = a.region;
      t.atop = a.atop;
      t.user = a.user;
      widen_aw = t;
    end
  endfunction

  function automatic mst_ar_t widen_ar(
      input slv_ar_t a,
      input logic [MST_IDX_W-1:0] mid
  );
    mst_ar_t t;
    begin
      t = '0;
      t.id = {mid, a.id};
      t.addr = a.addr;
      t.len = a.len;
      t.size = a.size;
      t.burst = a.burst;
      t.lock = a.lock;
      t.cache = a.cache;
      t.prot = a.prot;
      t.qos = a.qos;
      t.region = a.region;
      t.user = a.user;
      widen_ar = t;
    end
  endfunction

  always_comb begin : decode_and_activity
    integer m;
    for (m = 0; m < NUM_MST; m = m + 1) begin
      aw_decode[m] = decode_addr(mst_req[m].aw.addr);
      ar_decode[m] = decode_addr(mst_req[m].ar.addr);

      // Before W completion, w_ptr and b_ptr name the same transaction.
      // After W completion they differ until that transaction's B retires.
      aw_w_active[m] = (aw_count[m] != 0) &&
                       (aw_w_ptr[m] == aw_b_ptr[m]);
    end
  end

  // Round-robin selection is performed only when the corresponding output
  // register can be loaded. Once loaded, valid and payload remain stable.
  always_comb begin : request_arbitration
    integer s;
    integer off;
    integer idx;
    for (s = 0; s < NUM_SLV; s = s + 1) begin
      aw_sel_valid[s] = 1'b0;
      aw_sel_m[s] = '0;
      if (!aw_out_valid[s] && !wr_active[s]) begin
        for (off = 0; off < NUM_MST; off = off + 1) begin
          idx = rr_aw[s] + off;
          if (idx >= NUM_MST)
            idx = idx - NUM_MST;
          if (!aw_sel_valid[s] &&
              aw_w_active[idx] &&
              !aw_decerr[idx][aw_w_ptr[idx]] &&
              !aw_sent[idx][aw_w_ptr[idx]] &&
              (aw_target[idx][aw_w_ptr[idx]] == SLV_IDX_W'(s))) begin
            aw_sel_valid[s] = 1'b1;
            aw_sel_m[s] = MST_IDX_W'(idx);
          end
        end
      end

      ar_sel_valid[s] = 1'b0;
      ar_sel_m[s] = '0;
      if (!ar_out_valid[s]) begin
        for (off = 0; off < NUM_MST; off = off + 1) begin
          idx = rr_ar[s] + off;
          if (idx >= NUM_MST)
            idx = idx - NUM_MST;
          if (!ar_sel_valid[s] &&
              (ar_count[idx] != 0) &&
              !ar_decerr[idx][ar_r_ptr[idx]] &&
              !ar_sent[idx][ar_r_ptr[idx]] &&
              (ar_target[idx][ar_r_ptr[idx]] == SLV_IDX_W'(s))) begin
            ar_sel_valid[s] = 1'b1;
            ar_sel_m[s] = MST_IDX_W'(idx);
          end
        end
      end
    end
  end

  always_comb begin : channel_mux
    integer m;
    integer s;
    integer t;

    for (m = 0; m < NUM_MST; m = m + 1) begin
      mst_resp[m] = '0;
      mst_resp[m].aw_ready = rst_n && (aw_count[m] < MAX_TRANS);
      mst_resp[m].ar_ready = rst_n && (ar_count[m] < MAX_TRANS);
    end

    for (s = 0; s < NUM_SLV; s = s + 1) begin
      slv_req[s] = '0;
      slv_req[s].aw = aw_out[s];
      slv_req[s].aw_valid = rst_n && aw_out_valid[s];
      slv_req[s].ar = ar_out[s];
      slv_req[s].ar_valid = rst_n && ar_out_valid[s];
    end

    for (m = 0; m < NUM_MST; m = m + 1) begin
      // An unmapped write's W burst is consumed locally.
      if (rst_n && aw_w_active[m] &&
          aw_decerr[m][aw_w_ptr[m]]) begin
        mst_resp[m].w_ready = 1'b1;
      end

      if (rst_n && (aw_count[m] != 0)) begin
        if (aw_decerr[m][aw_b_ptr[m]]) begin
          if (aw_local_b[m][aw_b_ptr[m]]) begin
            mst_resp[m].b_valid = 1'b1;
            mst_resp[m].b.id =
                aw_q[m][aw_b_ptr[m]].id[SLV_ID_W-1:0];
            mst_resp[m].b.resp = RESP_DECERR;
            mst_resp[m].b.user = '0;
          end
        end else if (aw_sent[m][aw_b_ptr[m]]) begin
          t = aw_target[m][aw_b_ptr[m]];
          if (slv_resp[t].b.id == aw_q[m][aw_b_ptr[m]].id) begin
            slv_req[t].b_ready = mst_req[m].b_ready;
            mst_resp[m].b_valid = slv_resp[t].b_valid;
            mst_resp[m].b.id =
                aw_q[m][aw_b_ptr[m]].id[SLV_ID_W-1:0];
            mst_resp[m].b.resp = slv_resp[t].b.resp;
            mst_resp[m].b.user = slv_resp[t].b.user;
          end
        end
      end

      if (rst_n && (ar_count[m] != 0)) begin
        if (ar_decerr[m][ar_r_ptr[m]]) begin
          mst_resp[m].r_valid = 1'b1;
          mst_resp[m].r.id =
              ar_q[m][ar_r_ptr[m]].id[SLV_ID_W-1:0];
          mst_resp[m].r.data = '0;
          mst_resp[m].r.resp = RESP_DECERR;
          mst_resp[m].r.last =
              (dec_r_beat[m] == ar_q[m][ar_r_ptr[m]].len);
          mst_resp[m].r.user = '0;
        end else if (ar_sent[m][ar_r_ptr[m]]) begin
          t = ar_target[m][ar_r_ptr[m]];
          if (slv_resp[t].r.id == ar_q[m][ar_r_ptr[m]].id) begin
            slv_req[t].r_ready = mst_req[m].r_ready;
            mst_resp[m].r_valid = slv_resp[t].r_valid;
            mst_resp[m].r.id =
                ar_q[m][ar_r_ptr[m]].id[SLV_ID_W-1:0];
            mst_resp[m].r.data = slv_resp[t].r.data;
            mst_resp[m].r.resp = slv_resp[t].r.resp;
            mst_resp[m].r.last = slv_resp[t].r.last;
            mst_resp[m].r.user = slv_resp[t].r.user;
          end
        end
      end
    end

    // W is routed directly. Consequently no W data is stored in the xbar.
    for (s = 0; s < NUM_SLV; s = s + 1) begin
      for (m = 0; m < NUM_MST; m = m + 1) begin
        if (rst_n && wr_active[s] &&
            (wr_owner[s] == MST_IDX_W'(m)) &&
            aw_w_active[m] &&
            !aw_decerr[m][aw_w_ptr[m]] &&
            (aw_target[m][aw_w_ptr[m]] == SLV_IDX_W'(s))) begin
          slv_req[s].w = mst_req[m].w;
          slv_req[s].w_valid = mst_req[m].w_valid;
          mst_resp[m].w_ready = slv_resp[s].w_ready;
        end
      end
    end
  end

  always_comb begin : handshake_events
    integer m;
    for (m = 0; m < NUM_MST; m = m + 1) begin
      aw_accept[m] = mst_req[m].aw_valid && mst_resp[m].aw_ready;
      ar_accept[m] = mst_req[m].ar_valid && mst_resp[m].ar_ready;
      w_fire[m] = mst_req[m].w_valid && mst_resp[m].w_ready;
      b_fire[m] = mst_resp[m].b_valid && mst_req[m].b_ready;
      r_fire[m] = mst_resp[m].r_valid && mst_req[m].r_ready;
      w_last_fire[m] = w_fire[m] &&
          (w_beat[m] == aw_q[m][aw_w_ptr[m]].len);
      r_last_fire[m] = r_fire[m] && mst_resp[m].r.last;
    end
  end

  always_ff @(posedge clk) begin : state
    integer m;
    integer s;
    if (!rst_n) begin
      for (m = 0; m < NUM_MST; m = m + 1) begin
        aw_tail[m] <= '0;
        aw_w_ptr[m] <= '0;
        aw_b_ptr[m] <= '0;
        ar_tail[m] <= '0;
        ar_r_ptr[m] <= '0;
        aw_count[m] <= '0;
        ar_count[m] <= '0;
        w_beat[m] <= '0;
        dec_r_beat[m] <= '0;
      end
      for (s = 0; s < NUM_SLV; s = s + 1) begin
        aw_out_valid[s] <= 1'b0;
        ar_out_valid[s] <= 1'b0;
        aw_out_src[s] <= '0;
        wr_active[s] <= 1'b0;
        wr_owner[s] <= '0;
        wr_len[s] <= '0;
        wr_beat[s] <= '0;
        rr_aw[s] <= '0;
        rr_ar[s] <= '0;
      end
    end else begin
      for (m = 0; m < NUM_MST; m = m + 1) begin
        if (aw_accept[m]) begin
          aw_q[m][aw_tail[m]] <=
              widen_aw(mst_req[m].aw, MST_IDX_W'(m));
          aw_target[m][aw_tail[m]] <= aw_decode[m][SLV_IDX_W-1:0];
          aw_decerr[m][aw_tail[m]] <= aw_decode[m][SLV_IDX_W];
          aw_sent[m][aw_tail[m]] <= 1'b0;
          aw_local_b[m][aw_tail[m]] <= 1'b0;
          aw_tail[m] <= aw_tail[m] + 1'b1;
        end

        if (w_fire[m]) begin
          if (w_last_fire[m]) begin
            if (aw_decerr[m][aw_w_ptr[m]])
              aw_local_b[m][aw_w_ptr[m]] <= 1'b1;
            aw_w_ptr[m] <= aw_w_ptr[m] + 1'b1;
            w_beat[m] <= '0;
          end else begin
            w_beat[m] <= w_beat[m] + 1'b1;
          end
        end

        if (b_fire[m]) begin
          aw_local_b[m][aw_b_ptr[m]] <= 1'b0;
          aw_b_ptr[m] <= aw_b_ptr[m] + 1'b1;
        end

        case ({aw_accept[m], b_fire[m]})
          2'b10: aw_count[m] <= aw_count[m] + 1'b1;
          2'b01: aw_count[m] <= aw_count[m] - 1'b1;
          default: aw_count[m] <= aw_count[m];
        endcase

        if (ar_accept[m]) begin
          ar_q[m][ar_tail[m]] <=
              widen_ar(mst_req[m].ar, MST_IDX_W'(m));
          ar_target[m][ar_tail[m]] <= ar_decode[m][SLV_IDX_W-1:0];
          ar_decerr[m][ar_tail[m]] <= ar_decode[m][SLV_IDX_W];
          ar_sent[m][ar_tail[m]] <= 1'b0;
          ar_tail[m] <= ar_tail[m] + 1'b1;
        end

        if (r_last_fire[m]) begin
          ar_r_ptr[m] <= ar_r_ptr[m] + 1'b1;
          dec_r_beat[m] <= '0;
        end else if (r_fire[m] && ar_decerr[m][ar_r_ptr[m]]) begin
          dec_r_beat[m] <= dec_r_beat[m] + 1'b1;
        end

        case ({ar_accept[m], r_last_fire[m]})
          2'b10: ar_count[m] <= ar_count[m] + 1'b1;
          2'b01: ar_count[m] <= ar_count[m] - 1'b1;
          default: ar_count[m] <= ar_count[m];
        endcase
      end

      for (s = 0; s < NUM_SLV; s = s + 1) begin
        if (slv_req[s].aw_valid && slv_resp[s].aw_ready) begin
          aw_out_valid[s] <= 1'b0;
          wr_active[s] <= 1'b1;
          wr_owner[s] <= aw_out_src[s];
          wr_len[s] <= aw_out[s].len;
          wr_beat[s] <= '0;
        end

        if (aw_sel_valid[s]) begin
          aw_out_valid[s] <= 1'b1;
          aw_out[s] <=
              aw_q[aw_sel_m[s]][aw_w_ptr[aw_sel_m[s]]];
          aw_out_src[s] <= aw_sel_m[s];
          aw_sent[aw_sel_m[s]][aw_w_ptr[aw_sel_m[s]]] <= 1'b1;
          if (aw_sel_m[s] == MST_IDX_W'(NUM_MST-1))
            rr_aw[s] <= '0;
          else
            rr_aw[s] <= aw_sel_m[s] + 1'b1;
        end

        if (slv_req[s].w_valid && slv_resp[s].w_ready) begin
          if (wr_beat[s] == wr_len[s]) begin
            wr_active[s] <= 1'b0;
            wr_beat[s] <= '0;
          end else begin
            wr_beat[s] <= wr_beat[s] + 1'b1;
          end
        end

        if (slv_req[s].ar_valid && slv_resp[s].ar_ready)
          ar_out_valid[s] <= 1'b0;

        if (ar_sel_valid[s]) begin
          ar_out_valid[s] <= 1'b1;
          ar_out[s] <=
              ar_q[ar_sel_m[s]][ar_r_ptr[ar_sel_m[s]]];
          ar_sent[ar_sel_m[s]][ar_r_ptr[ar_sel_m[s]]] <= 1'b1;
          if (ar_sel_m[s] == MST_IDX_W'(NUM_MST-1))
            rr_ar[s] <= '0;
          else
            rr_ar[s] <= ar_sel_m[s] + 1'b1;
        end
      end
    end
  end

endmodule
