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

  localparam int PTR_W = (MAX_TRANS > 1) ? $clog2(MAX_TRANS) : 1;
  localparam int CNT_W = $clog2(MAX_TRANS + 1);
  localparam logic [CNT_W-1:0] MAX_TRANS_COUNT = MAX_TRANS;

  localparam logic [2:0] ST_W_AW    = 3'd0;
  localparam logic [2:0] ST_W_DATA  = 3'd1;
  localparam logic [2:0] ST_W_B     = 3'd2;
  localparam logic [2:0] ST_W_DEC_W = 3'd3;
  localparam logic [2:0] ST_W_DEC_B = 3'd4;

  localparam logic [1:0] ST_R_AR    = 2'd0;
  localparam logic [1:0] ST_R_DATA  = 2'd1;
  localparam logic [1:0] ST_R_DEC   = 2'd2;

  typedef struct packed {
    slv_aw_t    aw;
    logic [1:0] route;
    logic       decerr;
  } aw_entry_t;

  typedef struct packed {
    slv_ar_t    ar;
    logic [1:0] route;
    logic       decerr;
  } ar_entry_t;

  aw_entry_t aw_q [NUM_MST-1:0][MAX_TRANS-1:0];
  ar_entry_t ar_q [NUM_MST-1:0][MAX_TRANS-1:0];
  w_t        w_q  [NUM_MST-1:0][3:0];

  logic [PTR_W-1:0] aw_rptr [NUM_MST-1:0];
  logic [PTR_W-1:0] aw_wptr [NUM_MST-1:0];
  logic [PTR_W-1:0] ar_rptr [NUM_MST-1:0];
  logic [PTR_W-1:0] ar_wptr [NUM_MST-1:0];
  logic [CNT_W-1:0] aw_count [NUM_MST-1:0];
  logic [CNT_W-1:0] ar_count [NUM_MST-1:0];

  logic [1:0] w_rptr [NUM_MST-1:0];
  logic [1:0] w_wptr [NUM_MST-1:0];
  logic [2:0] w_count [NUM_MST-1:0];

  aw_entry_t wr_active [NUM_MST-1:0];
  ar_entry_t rd_active [NUM_MST-1:0];
  logic [NUM_MST-1:0] wr_active_valid;
  logic [NUM_MST-1:0] rd_active_valid;
  logic [2:0] wr_state [NUM_MST-1:0];
  logic [1:0] rd_state [NUM_MST-1:0];
  logic [7:0] wr_beat [NUM_MST-1:0];
  logic [7:0] rd_beat [NUM_MST-1:0];

  logic [1:0] aw_dec_route [NUM_MST-1:0];
  logic [1:0] ar_dec_route [NUM_MST-1:0];
  logic       aw_decerr [NUM_MST-1:0];
  logic       ar_decerr [NUM_MST-1:0];

  logic [NUM_MST-1:0] aw_ready_int;
  logic [NUM_MST-1:0] ar_ready_int;
  logic [NUM_MST-1:0] w_ready_int;
  logic [NUM_MST-1:0] aw_push;
  logic [NUM_MST-1:0] ar_push;
  logic [NUM_MST-1:0] w_push;
  logic [NUM_MST-1:0] aw_pop;
  logic [NUM_MST-1:0] ar_pop;
  logic [NUM_MST-1:0] w_pop;
  logic [NUM_MST-1:0] w_pop_normal;
  logic [NUM_MST-1:0] w_pop_dec;
  logic [NUM_MST-1:0] r_hs;
  logic [NUM_MST-1:0] b_hs;

  mst_aw_t aw_out [NUM_SLV-1:0];
  mst_ar_t ar_out [NUM_SLV-1:0];
  logic [NUM_SLV-1:0] aw_out_valid;
  logic [NUM_SLV-1:0] ar_out_valid;
  logic [MST_IDX_W-1:0] aw_out_owner [NUM_SLV-1:0];
  logic [MST_IDX_W-1:0] ar_out_owner [NUM_SLV-1:0];

  logic [NUM_SLV-1:0] wr_busy;
  logic [NUM_SLV-1:0] rd_busy;
  logic [MST_IDX_W-1:0] wr_owner [NUM_SLV-1:0];
  logic [MST_IDX_W-1:0] rd_owner [NUM_SLV-1:0];

  logic [MST_IDX_W-1:0] rr_aw [NUM_SLV-1:0];
  logic [MST_IDX_W-1:0] rr_ar [NUM_SLV-1:0];
  logic [NUM_SLV-1:0] aw_sel_valid;
  logic [NUM_SLV-1:0] ar_sel_valid;
  logic [MST_IDX_W-1:0] aw_sel_owner [NUM_SLV-1:0];
  logic [MST_IDX_W-1:0] ar_sel_owner [NUM_SLV-1:0];

  function automatic mst_aw_t widen_aw(
      input slv_aw_t a,
      input logic [MST_IDX_W-1:0] owner
  );
    mst_aw_t tmp;
    begin
      tmp = '0;
      tmp.id     = {owner, a.id};
      tmp.addr   = a.addr;
      tmp.len    = a.len;
      tmp.size   = a.size;
      tmp.burst  = a.burst;
      tmp.lock   = a.lock;
      tmp.cache  = a.cache;
      tmp.prot   = a.prot;
      tmp.qos    = a.qos;
      tmp.region = a.region;
      tmp.atop   = a.atop;
      tmp.user   = a.user;
      widen_aw = tmp;
    end
  endfunction

  function automatic mst_ar_t widen_ar(
      input slv_ar_t a,
      input logic [MST_IDX_W-1:0] owner
  );
    mst_ar_t tmp;
    begin
      tmp = '0;
      tmp.id     = {owner, a.id};
      tmp.addr   = a.addr;
      tmp.len    = a.len;
      tmp.size   = a.size;
      tmp.burst  = a.burst;
      tmp.lock   = a.lock;
      tmp.cache  = a.cache;
      tmp.prot   = a.prot;
      tmp.qos    = a.qos;
      tmp.region = a.region;
      tmp.user   = a.user;
      widen_ar = tmp;
    end
  endfunction

  always_comb begin : decode_comb
    integer m;
    integer s;
    for (m = 0; m < NUM_MST; m = m + 1) begin
      aw_dec_route[m] = 2'b00;
      ar_dec_route[m] = 2'b00;
      aw_decerr[m] = 1'b1;
      ar_decerr[m] = 1'b1;
      for (s = 0; s < NUM_SLV; s = s + 1) begin
        if ((mst_req[m].aw.addr >= addr_map[s].start_addr) &&
            (mst_req[m].aw.addr <  addr_map[s].end_addr)) begin
          aw_dec_route[m] = addr_map[s].mst_port[1:0];
          aw_decerr[m] = 1'b0;
        end
        if ((mst_req[m].ar.addr >= addr_map[s].start_addr) &&
            (mst_req[m].ar.addr <  addr_map[s].end_addr)) begin
          ar_dec_route[m] = addr_map[s].mst_port[1:0];
          ar_decerr[m] = 1'b0;
        end
      end
    end
  end

  genvar gm;
  generate
    for (gm = 0; gm < NUM_MST; gm = gm + 1) begin : g_master_handshakes
      assign aw_ready_int[gm] = (aw_count[gm] != MAX_TRANS_COUNT);
      assign ar_ready_int[gm] = (ar_count[gm] != MAX_TRANS_COUNT);
      assign w_ready_int[gm]  = (w_count[gm] != 3'd4);

      assign aw_push[gm] = mst_req[gm].aw_valid && aw_ready_int[gm];
      assign ar_push[gm] = mst_req[gm].ar_valid && ar_ready_int[gm];
      assign w_push[gm]  = mst_req[gm].w_valid  && w_ready_int[gm];

      assign aw_pop[gm] = !wr_active_valid[gm] && (aw_count[gm] != '0);
      assign ar_pop[gm] = !rd_active_valid[gm] && (ar_count[gm] != '0);
      assign w_pop[gm]  = w_pop_normal[gm] || w_pop_dec[gm];

      assign r_hs[gm] = mst_resp[gm].r_valid && mst_req[gm].r_ready;
      assign b_hs[gm] = mst_resp[gm].b_valid && mst_req[gm].b_ready;
    end
  endgenerate

  always_comb begin : aw_arbitration_comb
    integer s;
    integer off;
    integer idx;
    for (s = 0; s < NUM_SLV; s = s + 1) begin
      aw_sel_valid[s] = 1'b0;
      aw_sel_owner[s] = '0;
      for (off = 0; off < NUM_MST; off = off + 1) begin
        idx = rr_aw[s] + off;
        if (idx >= NUM_MST)
          idx = idx - NUM_MST;
        if (!aw_sel_valid[s] &&
            wr_active_valid[idx] &&
            (wr_state[idx] == ST_W_AW) &&
            !wr_active[idx].decerr &&
            (wr_active[idx].route == s[1:0])) begin
          aw_sel_valid[s] = 1'b1;
          aw_sel_owner[s] = idx[MST_IDX_W-1:0];
        end
      end
    end
  end

  always_comb begin : ar_arbitration_comb
    integer s;
    integer off;
    integer idx;
    for (s = 0; s < NUM_SLV; s = s + 1) begin
      ar_sel_valid[s] = 1'b0;
      ar_sel_owner[s] = '0;
      for (off = 0; off < NUM_MST; off = off + 1) begin
        idx = rr_ar[s] + off;
        if (idx >= NUM_MST)
          idx = idx - NUM_MST;
        if (!ar_sel_valid[s] &&
            rd_active_valid[idx] &&
            (rd_state[idx] == ST_R_AR) &&
            !rd_active[idx].decerr &&
            (rd_active[idx].route == s[1:0])) begin
          ar_sel_valid[s] = 1'b1;
          ar_sel_owner[s] = idx[MST_IDX_W-1:0];
        end
      end
    end
  end

  always_comb begin : slave_output_comb
    integer m;
    integer s;
    integer owner;

    for (m = 0; m < NUM_MST; m = m + 1) begin
      w_pop_normal[m] = 1'b0;
      w_pop_dec[m] = 1'b0;
      if (rst_n && wr_active_valid[m] &&
          (wr_state[m] == ST_W_DEC_W) && (w_count[m] != '0)) begin
        w_pop_dec[m] = 1'b1;
      end
    end

    for (s = 0; s < NUM_SLV; s = s + 1) begin
      slv_req[s] = '0;
      slv_req[s].aw = aw_out[s];
      slv_req[s].aw_valid = aw_out_valid[s] && rst_n;
      slv_req[s].ar = ar_out[s];
      slv_req[s].ar_valid = ar_out_valid[s] && rst_n;

      if (rst_n && wr_busy[s] && !aw_out_valid[s]) begin
        owner = wr_owner[s];
        if ((owner < NUM_MST) &&
            wr_active_valid[owner] &&
            (wr_state[owner] == ST_W_DATA) &&
            (wr_active[owner].route == s[1:0]) &&
            (w_count[owner] != '0)) begin
          slv_req[s].w = w_q[owner][w_rptr[owner]];
          slv_req[s].w_valid = 1'b1;
          if (slv_resp[s].w_ready)
            w_pop_normal[owner] = 1'b1;
        end
      end

      if (rst_n && rd_busy[s] && !ar_out_valid[s]) begin
        owner = rd_owner[s];
        if ((owner < NUM_MST) &&
            rd_active_valid[owner] &&
            (rd_state[owner] == ST_R_DATA) &&
            (rd_active[owner].route == s[1:0])) begin
          slv_req[s].r_ready = mst_req[owner].r_ready;
        end
      end

      if (rst_n && slv_resp[s].b_valid) begin
        owner = slv_resp[s].b.id[MST_ID_W-1 -: MST_IDX_W];
        if ((owner < NUM_MST) &&
            wr_active_valid[owner] &&
            (wr_state[owner] == ST_W_B) &&
            !wr_active[owner].decerr &&
            (wr_active[owner].route == s[1:0])) begin
          slv_req[s].b_ready = mst_req[owner].b_ready;
        end
      end
    end
  end

  always_comb begin : master_output_comb
    integer m;
    integer s;

    for (m = 0; m < NUM_MST; m = m + 1) begin
      mst_resp[m] = '0;
      mst_resp[m].aw_ready = aw_ready_int[m];
      mst_resp[m].ar_ready = ar_ready_int[m];
      mst_resp[m].w_ready  = w_ready_int[m];

      if (rst_n) begin
        if (rd_active_valid[m]) begin
          if (rd_state[m] == ST_R_DEC) begin
            mst_resp[m].r_valid = 1'b1;
            mst_resp[m].r.id    = rd_active[m].ar.id;
            mst_resp[m].r.data  = '0;
            mst_resp[m].r.resp  = RESP_DECERR;
            mst_resp[m].r.last  = (rd_beat[m] == rd_active[m].ar.len);
            mst_resp[m].r.user  = rd_active[m].ar.user;
          end else if (rd_state[m] == ST_R_DATA) begin
            s = rd_active[m].route;
            if ((s < NUM_SLV) && rd_busy[s] && !ar_out_valid[s] &&
                (rd_owner[s] == m[MST_IDX_W-1:0])) begin
              mst_resp[m].r_valid = slv_resp[s].r_valid;
              mst_resp[m].r.id   = slv_resp[s].r.id[SLV_ID_W-1:0];
              mst_resp[m].r.data = slv_resp[s].r.data;
              mst_resp[m].r.resp = slv_resp[s].r.resp;
              mst_resp[m].r.last = slv_resp[s].r.last;
              mst_resp[m].r.user = slv_resp[s].r.user;
            end
          end
        end

        if (wr_active_valid[m]) begin
          if (wr_state[m] == ST_W_DEC_B) begin
            mst_resp[m].b_valid = 1'b1;
            mst_resp[m].b.id    = wr_active[m].aw.id;
            mst_resp[m].b.resp  = RESP_DECERR;
            mst_resp[m].b.user  = wr_active[m].aw.user;
          end else if (wr_state[m] == ST_W_B) begin
            s = wr_active[m].route;
            if ((s < NUM_SLV) && slv_resp[s].b_valid &&
                (slv_resp[s].b.id[MST_ID_W-1 -: MST_IDX_W]
                   == m[MST_IDX_W-1:0])) begin
              mst_resp[m].b_valid = 1'b1;
              mst_resp[m].b.id   = slv_resp[s].b.id[SLV_ID_W-1:0];
              mst_resp[m].b.resp = slv_resp[s].b.resp;
              mst_resp[m].b.user = slv_resp[s].b.user;
            end
          end
        end
      end
    end
  end

  always_ff @(posedge clk) begin : request_queue_seq
    integer m;
    if (!rst_n) begin
      for (m = 0; m < NUM_MST; m = m + 1) begin
        aw_rptr[m] <= '0;
        aw_wptr[m] <= '0;
        ar_rptr[m] <= '0;
        ar_wptr[m] <= '0;
        aw_count[m] <= '0;
        ar_count[m] <= '0;
        w_rptr[m] <= '0;
        w_wptr[m] <= '0;
        w_count[m] <= '0;
      end
    end else begin
      for (m = 0; m < NUM_MST; m = m + 1) begin
        if (aw_push[m]) begin
          aw_q[m][aw_wptr[m]].aw <= mst_req[m].aw;
          aw_q[m][aw_wptr[m]].route <= aw_dec_route[m];
          aw_q[m][aw_wptr[m]].decerr <= aw_decerr[m];
          aw_wptr[m] <= aw_wptr[m] + 1'b1;
        end
        if (aw_pop[m])
          aw_rptr[m] <= aw_rptr[m] + 1'b1;
        case ({aw_push[m], aw_pop[m]})
          2'b10: aw_count[m] <= aw_count[m] + 1'b1;
          2'b01: aw_count[m] <= aw_count[m] - 1'b1;
          default: aw_count[m] <= aw_count[m];
        endcase

        if (ar_push[m]) begin
          ar_q[m][ar_wptr[m]].ar <= mst_req[m].ar;
          ar_q[m][ar_wptr[m]].route <= ar_dec_route[m];
          ar_q[m][ar_wptr[m]].decerr <= ar_decerr[m];
          ar_wptr[m] <= ar_wptr[m] + 1'b1;
        end
        if (ar_pop[m])
          ar_rptr[m] <= ar_rptr[m] + 1'b1;
        case ({ar_push[m], ar_pop[m]})
          2'b10: ar_count[m] <= ar_count[m] + 1'b1;
          2'b01: ar_count[m] <= ar_count[m] - 1'b1;
          default: ar_count[m] <= ar_count[m];
        endcase

        if (w_push[m]) begin
          w_q[m][w_wptr[m]] <= mst_req[m].w;
          w_wptr[m] <= w_wptr[m] + 1'b1;
        end
        if (w_pop[m])
          w_rptr[m] <= w_rptr[m] + 1'b1;
        case ({w_push[m], w_pop[m]})
          2'b10: w_count[m] <= w_count[m] + 1'b1;
          2'b01: w_count[m] <= w_count[m] - 1'b1;
          default: w_count[m] <= w_count[m];
        endcase
      end
    end
  end

  always_ff @(posedge clk) begin : active_transaction_seq
    integer m;
    integer s;
    if (!rst_n) begin
      for (m = 0; m < NUM_MST; m = m + 1) begin
        wr_active_valid[m] <= 1'b0;
        rd_active_valid[m] <= 1'b0;
        wr_state[m] <= ST_W_AW;
        rd_state[m] <= ST_R_AR;
        wr_beat[m] <= '0;
        rd_beat[m] <= '0;
      end
    end else begin
      for (m = 0; m < NUM_MST; m = m + 1) begin
        if (!wr_active_valid[m]) begin
          if (aw_pop[m]) begin
            wr_active[m] <= aw_q[m][aw_rptr[m]];
            wr_active_valid[m] <= 1'b1;
            wr_beat[m] <= '0;
            if (aw_q[m][aw_rptr[m]].decerr)
              wr_state[m] <= ST_W_DEC_W;
            else
              wr_state[m] <= ST_W_AW;
          end
        end else begin
          case (wr_state[m])
            ST_W_AW: begin
              for (s = 0; s < NUM_SLV; s = s + 1) begin
                if (aw_out_valid[s] &&
                    (aw_out_owner[s] == m[MST_IDX_W-1:0]) &&
                    slv_resp[s].aw_ready) begin
                  wr_state[m] <= ST_W_DATA;
                end
              end
            end
            ST_W_DATA: begin
              if (w_pop_normal[m] && w_q[m][w_rptr[m]].last)
                wr_state[m] <= ST_W_B;
            end
            ST_W_B: begin
              if (b_hs[m])
                wr_active_valid[m] <= 1'b0;
            end
            ST_W_DEC_W: begin
              if (w_pop_dec[m]) begin
                if (wr_beat[m] == wr_active[m].aw.len) begin
                  wr_state[m] <= ST_W_DEC_B;
                end else begin
                  wr_beat[m] <= wr_beat[m] + 1'b1;
                end
              end
            end
            ST_W_DEC_B: begin
              if (b_hs[m])
                wr_active_valid[m] <= 1'b0;
            end
            default: wr_active_valid[m] <= 1'b0;
          endcase
        end

        if (!rd_active_valid[m]) begin
          if (ar_pop[m]) begin
            rd_active[m] <= ar_q[m][ar_rptr[m]];
            rd_active_valid[m] <= 1'b1;
            rd_beat[m] <= '0;
            if (ar_q[m][ar_rptr[m]].decerr)
              rd_state[m] <= ST_R_DEC;
            else
              rd_state[m] <= ST_R_AR;
          end
        end else begin
          case (rd_state[m])
            ST_R_AR: begin
              for (s = 0; s < NUM_SLV; s = s + 1) begin
                if (ar_out_valid[s] &&
                    (ar_out_owner[s] == m[MST_IDX_W-1:0]) &&
                    slv_resp[s].ar_ready) begin
                  rd_state[m] <= ST_R_DATA;
                end
              end
            end
            ST_R_DATA: begin
              if (r_hs[m] && mst_resp[m].r.last)
                rd_active_valid[m] <= 1'b0;
            end
            ST_R_DEC: begin
              if (r_hs[m]) begin
                if (rd_beat[m] == rd_active[m].ar.len) begin
                  rd_active_valid[m] <= 1'b0;
                end else begin
                  rd_beat[m] <= rd_beat[m] + 1'b1;
                end
              end
            end
            default: rd_active_valid[m] <= 1'b0;
          endcase
        end
      end
    end
  end

  always_ff @(posedge clk) begin : slave_port_seq
    integer s;
    if (!rst_n) begin
      for (s = 0; s < NUM_SLV; s = s + 1) begin
        aw_out_valid[s] <= 1'b0;
        ar_out_valid[s] <= 1'b0;
        aw_out_owner[s] <= '0;
        ar_out_owner[s] <= '0;
        wr_busy[s] <= 1'b0;
        rd_busy[s] <= 1'b0;
        wr_owner[s] <= '0;
        rd_owner[s] <= '0;
        rr_aw[s] <= '0;
        rr_ar[s] <= '0;
      end
    end else begin
      for (s = 0; s < NUM_SLV; s = s + 1) begin
        if (aw_out_valid[s]) begin
          if (slv_resp[s].aw_ready)
            aw_out_valid[s] <= 1'b0;
        end else if (!wr_busy[s] && aw_sel_valid[s]) begin
          aw_out[s] <= widen_aw(wr_active[aw_sel_owner[s]].aw,
                                aw_sel_owner[s]);
          aw_out_valid[s] <= 1'b1;
          aw_out_owner[s] <= aw_sel_owner[s];
          wr_busy[s] <= 1'b1;
          wr_owner[s] <= aw_sel_owner[s];
          if (aw_sel_owner[s] == (NUM_MST-1))
            rr_aw[s] <= '0;
          else
            rr_aw[s] <= aw_sel_owner[s] + 1'b1;
        end

        if (wr_busy[s] && !aw_out_valid[s] &&
            w_pop_normal[wr_owner[s]] &&
            w_q[wr_owner[s]][w_rptr[wr_owner[s]]].last) begin
          wr_busy[s] <= 1'b0;
        end

        if (ar_out_valid[s]) begin
          if (slv_resp[s].ar_ready)
            ar_out_valid[s] <= 1'b0;
        end else if (!rd_busy[s] && ar_sel_valid[s]) begin
          ar_out[s] <= widen_ar(rd_active[ar_sel_owner[s]].ar,
                                ar_sel_owner[s]);
          ar_out_valid[s] <= 1'b1;
          ar_out_owner[s] <= ar_sel_owner[s];
          rd_busy[s] <= 1'b1;
          rd_owner[s] <= ar_sel_owner[s];
          if (ar_sel_owner[s] == (NUM_MST-1))
            rr_ar[s] <= '0;
          else
            rr_ar[s] <= ar_sel_owner[s] + 1'b1;
        end

        if (rd_busy[s] && !ar_out_valid[s] &&
            r_hs[rd_owner[s]] && mst_resp[rd_owner[s]].r.last) begin
          rd_busy[s] <= 1'b0;
        end
      end
    end
  end

endmodule
