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
  localparam int SLV_IDX_W = (NUM_SLV > 1) ? $clog2(NUM_SLV) : 1;

  localparam logic [PTR_W-1:0] PTR_LAST  = MAX_TRANS - 1;
  localparam logic [CNT_W-1:0] COUNT_MAX = MAX_TRANS;

  // Request storage is transaction tracking, not R/W data buffering.  The
  // oldest request remains at the head until its response has retired.
  slv_ar_t ar_mem [NUM_MST-1:0][MAX_TRANS-1:0];
  slv_aw_t aw_mem [NUM_MST-1:0][MAX_TRANS-1:0];

  slv_ar_t ar_head [NUM_MST-1:0];
  slv_aw_t aw_head [NUM_MST-1:0];

  logic [PTR_W-1:0] ar_rp [NUM_MST-1:0];
  logic [PTR_W-1:0] ar_wp [NUM_MST-1:0];
  logic [PTR_W-1:0] aw_rp [NUM_MST-1:0];
  logic [PTR_W-1:0] aw_wp [NUM_MST-1:0];

  logic [CNT_W-1:0] ar_count [NUM_MST-1:0];
  logic [CNT_W-1:0] aw_count [NUM_MST-1:0];

  logic [NUM_MST-1:0] ar_issued;
  logic [NUM_MST-1:0] aw_issued;
  logic [NUM_MST-1:0] w_done;

  logic [7:0] error_r_pos [NUM_MST-1:0];
  logic [7:0] w_pos       [NUM_MST-1:0];

  logic [NUM_MST-1:0] ar_mapped;
  logic [NUM_MST-1:0] aw_mapped;
  logic [SLV_IDX_W-1:0] ar_target [NUM_MST-1:0];
  logic [SLV_IDX_W-1:0] aw_target [NUM_MST-1:0];

  logic [NUM_MST-1:0] ar_req [NUM_SLV-1:0];
  logic [NUM_MST-1:0] aw_req [NUM_SLV-1:0];

  logic [NUM_SLV-1:0] ar_gnt_v;
  logic [NUM_SLV-1:0] aw_gnt_v;
  logic [MST_IDX_W-1:0] ar_gnt_m [NUM_SLV-1:0];
  logic [MST_IDX_W-1:0] aw_gnt_m [NUM_SLV-1:0];
  logic [MST_IDX_W-1:0] ar_rr    [NUM_SLV-1:0];
  logic [MST_IDX_W-1:0] aw_rr    [NUM_SLV-1:0];

  // A slave accepts only one write's AW/W sequence at a time.  The lock is
  // released after WLAST, not after B, so a stalled B cannot block other
  // masters from using that slave.
  logic [NUM_SLV-1:0] wr_busy;
  logic [MST_IDX_W-1:0] wr_owner [NUM_SLV-1:0];

  logic [NUM_MST-1:0] ar_push;
  logic [NUM_MST-1:0] aw_push;
  logic [NUM_MST-1:0] ar_pop;
  logic [NUM_MST-1:0] aw_pop;
  logic [NUM_MST-1:0] w_take;
  logic [NUM_SLV-1:0] ar_fire;
  logic [NUM_SLV-1:0] aw_fire;

  function automatic logic [MST_IDX_W-1:0] rr_pick(
      input logic [NUM_MST-1:0] req,
      input logic [MST_IDX_W-1:0] start
  );
    integer k;
    integer idx;
    logic found;
    begin
      rr_pick = start;
      found = 1'b0;
      for (k = 0; k < NUM_MST; k = k + 1) begin
        idx = start + k;
        if (idx >= NUM_MST)
          idx = idx - NUM_MST;
        if (!found && req[idx]) begin
          rr_pick = idx[MST_IDX_W-1:0];
          found = 1'b1;
        end
      end
    end
  endfunction

  function automatic logic [MST_IDX_W-1:0] rr_next(
      input logic [MST_IDX_W-1:0] current
  );
    integer idx;
    begin
      idx = current + 1;
      if (idx >= NUM_MST)
        idx = 0;
      rr_next = idx[MST_IDX_W-1:0];
    end
  endfunction

  // Address decode and request formation.
  always_comb begin : p_decode
    integer m;
    integer s;
    for (m = 0; m < NUM_MST; m = m + 1) begin
      ar_head[m] = ar_mem[m][ar_rp[m]];
      aw_head[m] = aw_mem[m][aw_rp[m]];

      ar_mapped[m] = 1'b0;
      aw_mapped[m] = 1'b0;
      ar_target[m] = '0;
      aw_target[m] = '0;

      for (s = 0; s < NUM_SLV; s = s + 1) begin
        if (!ar_mapped[m] &&
            (ar_head[m].addr >= addr_map[s].start_addr) &&
            (ar_head[m].addr <  addr_map[s].end_addr)) begin
          ar_mapped[m] = 1'b1;
          ar_target[m] = addr_map[s].mst_port[SLV_IDX_W-1:0];
        end
        if (!aw_mapped[m] &&
            (aw_head[m].addr >= addr_map[s].start_addr) &&
            (aw_head[m].addr <  addr_map[s].end_addr)) begin
          aw_mapped[m] = 1'b1;
          aw_target[m] = addr_map[s].mst_port[SLV_IDX_W-1:0];
        end
      end
    end

    for (s = 0; s < NUM_SLV; s = s + 1) begin
      ar_req[s] = '0;
      aw_req[s] = '0;
      for (m = 0; m < NUM_MST; m = m + 1) begin
        if ((ar_count[m] != '0) && ar_mapped[m] && !ar_issued[m] &&
            (ar_target[m] == s[SLV_IDX_W-1:0]))
          ar_req[s][m] = 1'b1;

        if ((aw_count[m] != '0) && aw_mapped[m] && !aw_issued[m] &&
            !wr_busy[s] && (aw_target[m] == s[SLV_IDX_W-1:0]))
          aw_req[s][m] = 1'b1;
      end
    end
  end

  // All channel routing.  R and W are cut through without data storage; when
  // the consumer stalls, the corresponding producer is stalled as well.
  always_comb begin : p_outputs
    integer m;
    integer s;

    for (m = 0; m < NUM_MST; m = m + 1)
      mst_resp[m] = '0;
    for (s = 0; s < NUM_SLV; s = s + 1)
      slv_req[s] = '0;

    if (rst_n) begin
      for (m = 0; m < NUM_MST; m = m + 1) begin
        // These depend only on registered occupancy, never on valid.
        mst_resp[m].aw_ready = (aw_count[m] != COUNT_MAX);
        mst_resp[m].ar_ready = (ar_count[m] != COUNT_MAX);

        // Write data and response routing.
        if (aw_count[m] != '0) begin
          if (!aw_mapped[m]) begin
            mst_resp[m].w_ready = !w_done[m];
            mst_resp[m].b_valid = w_done[m];
            mst_resp[m].b.id    = aw_head[m].id;
            mst_resp[m].b.resp  = RESP_DECERR;
            mst_resp[m].b.user  = aw_head[m].user;
          end else begin
            for (s = 0; s < NUM_SLV; s = s + 1) begin
              if (aw_target[m] == s[SLV_IDX_W-1:0]) begin
                if (aw_issued[m] && wr_busy[s] &&
                    (wr_owner[s] == m[MST_IDX_W-1:0]) && !w_done[m])
                  mst_resp[m].w_ready = slv_resp[s].w_ready;

                if (aw_issued[m] && w_done[m] && slv_resp[s].b_valid &&
                    (slv_resp[s].b.id[MST_ID_W-1 -: MST_IDX_W]
                       == m[MST_IDX_W-1:0])) begin
                  mst_resp[m].b_valid = 1'b1;
                  mst_resp[m].b.id =
                      slv_resp[s].b.id[SLV_ID_W-1:0];
                  mst_resp[m].b.resp = slv_resp[s].b.resp;
                  mst_resp[m].b.user = slv_resp[s].b.user;
                end
              end
            end
          end
        end

        // Read response routing.
        if (ar_count[m] != '0) begin
          if (!ar_mapped[m]) begin
            mst_resp[m].r_valid = 1'b1;
            mst_resp[m].r.id    = ar_head[m].id;
            mst_resp[m].r.data  = '0;
            mst_resp[m].r.resp  = RESP_DECERR;
            mst_resp[m].r.last  = (error_r_pos[m] == ar_head[m].len);
            mst_resp[m].r.user  = ar_head[m].user;
          end else if (ar_issued[m]) begin
            for (s = 0; s < NUM_SLV; s = s + 1) begin
              if ((ar_target[m] == s[SLV_IDX_W-1:0]) &&
                  slv_resp[s].r_valid &&
                  (slv_resp[s].r.id[MST_ID_W-1 -: MST_IDX_W]
                     == m[MST_IDX_W-1:0])) begin
                mst_resp[m].r_valid = 1'b1;
                mst_resp[m].r.id =
                    slv_resp[s].r.id[SLV_ID_W-1:0];
                mst_resp[m].r.data = slv_resp[s].r.data;
                mst_resp[m].r.resp = slv_resp[s].r.resp;
                mst_resp[m].r.last = slv_resp[s].r.last;
                mst_resp[m].r.user = slv_resp[s].r.user;
              end
            end
          end
        end
      end

      for (s = 0; s < NUM_SLV; s = s + 1) begin
        // Registered grants make AW/AR payload stable throughout a stall.
        if (ar_gnt_v[s]) begin
          slv_req[s].ar_valid = 1'b1;
          for (m = 0; m < NUM_MST; m = m + 1) begin
            if (ar_gnt_m[s] == m[MST_IDX_W-1:0]) begin
              slv_req[s].ar.id     = {ar_gnt_m[s], ar_head[m].id};
              slv_req[s].ar.addr   = ar_head[m].addr;
              slv_req[s].ar.len    = ar_head[m].len;
              slv_req[s].ar.size   = ar_head[m].size;
              slv_req[s].ar.burst  = ar_head[m].burst;
              slv_req[s].ar.lock   = ar_head[m].lock;
              slv_req[s].ar.cache  = ar_head[m].cache;
              slv_req[s].ar.prot   = ar_head[m].prot;
              slv_req[s].ar.qos    = ar_head[m].qos;
              slv_req[s].ar.region = ar_head[m].region;
              slv_req[s].ar.user   = ar_head[m].user;
            end
          end
        end

        if (aw_gnt_v[s]) begin
          slv_req[s].aw_valid = 1'b1;
          for (m = 0; m < NUM_MST; m = m + 1) begin
            if (aw_gnt_m[s] == m[MST_IDX_W-1:0]) begin
              slv_req[s].aw.id     = {aw_gnt_m[s], aw_head[m].id};
              slv_req[s].aw.addr   = aw_head[m].addr;
              slv_req[s].aw.len    = aw_head[m].len;
              slv_req[s].aw.size   = aw_head[m].size;
              slv_req[s].aw.burst  = aw_head[m].burst;
              slv_req[s].aw.lock   = aw_head[m].lock;
              slv_req[s].aw.cache  = aw_head[m].cache;
              slv_req[s].aw.prot   = aw_head[m].prot;
              slv_req[s].aw.qos    = aw_head[m].qos;
              slv_req[s].aw.region = aw_head[m].region;
              slv_req[s].aw.atop   = aw_head[m].atop;
              slv_req[s].aw.user   = aw_head[m].user;
            end
          end
        end

        if (wr_busy[s]) begin
          for (m = 0; m < NUM_MST; m = m + 1) begin
            if ((wr_owner[s] == m[MST_IDX_W-1:0]) &&
                aw_issued[m] && !w_done[m]) begin
              slv_req[s].w_valid = mst_req[m].w_valid;
              slv_req[s].w       = mst_req[m].w;
            end
          end
        end

        // Response ready is selected by the widened response ID.
        for (m = 0; m < NUM_MST; m = m + 1) begin
          if ((ar_count[m] != '0) && ar_mapped[m] && ar_issued[m] &&
              (ar_target[m] == s[SLV_IDX_W-1:0]) &&
              (slv_resp[s].r.id[MST_ID_W-1 -: MST_IDX_W]
                 == m[MST_IDX_W-1:0]))
            slv_req[s].r_ready = mst_req[m].r_ready;

          if ((aw_count[m] != '0) && aw_mapped[m] && aw_issued[m] &&
              w_done[m] && (aw_target[m] == s[SLV_IDX_W-1:0]) &&
              (slv_resp[s].b.id[MST_ID_W-1 -: MST_IDX_W]
                 == m[MST_IDX_W-1:0]))
            slv_req[s].b_ready = mst_req[m].b_ready;
        end
      end
    end
  end

  always_comb begin : p_events
    integer m;
    integer s;
    for (m = 0; m < NUM_MST; m = m + 1) begin
      ar_push[m] = mst_req[m].ar_valid && mst_resp[m].ar_ready;
      aw_push[m] = mst_req[m].aw_valid && mst_resp[m].aw_ready;
      ar_pop[m]  = mst_resp[m].r_valid && mst_req[m].r_ready &&
                   mst_resp[m].r.last;
      aw_pop[m]  = mst_resp[m].b_valid && mst_req[m].b_ready;
      w_take[m]  = mst_req[m].w_valid && mst_resp[m].w_ready;
    end
    for (s = 0; s < NUM_SLV; s = s + 1) begin
      ar_fire[s] = slv_req[s].ar_valid && slv_resp[s].ar_ready;
      aw_fire[s] = slv_req[s].aw_valid && slv_resp[s].aw_ready;
    end
  end

  // Per-master transaction queues and active-transaction state.
  always_ff @(posedge clk) begin : p_master_state
    integer m;
    integer s;
    if (!rst_n) begin
      for (m = 0; m < NUM_MST; m = m + 1) begin
        ar_rp[m]       <= '0;
        ar_wp[m]       <= '0;
        aw_rp[m]       <= '0;
        aw_wp[m]       <= '0;
        ar_count[m]    <= '0;
        aw_count[m]    <= '0;
        ar_issued[m]   <= 1'b0;
        aw_issued[m]   <= 1'b0;
        w_done[m]      <= 1'b0;
        error_r_pos[m] <= '0;
        w_pos[m]       <= '0;
      end
    end else begin
      for (m = 0; m < NUM_MST; m = m + 1) begin
        if (ar_push[m]) begin
          ar_mem[m][ar_wp[m]] <= mst_req[m].ar;
          if (ar_wp[m] == PTR_LAST)
            ar_wp[m] <= '0;
          else
            ar_wp[m] <= ar_wp[m] + 1'b1;
        end

        if (aw_push[m]) begin
          aw_mem[m][aw_wp[m]] <= mst_req[m].aw;
          if (aw_wp[m] == PTR_LAST)
            aw_wp[m] <= '0;
          else
            aw_wp[m] <= aw_wp[m] + 1'b1;
        end

        case ({ar_push[m], ar_pop[m]})
          2'b10: ar_count[m] <= ar_count[m] + 1'b1;
          2'b01: ar_count[m] <= ar_count[m] - 1'b1;
          default: begin end
        endcase

        case ({aw_push[m], aw_pop[m]})
          2'b10: aw_count[m] <= aw_count[m] + 1'b1;
          2'b01: aw_count[m] <= aw_count[m] - 1'b1;
          default: begin end
        endcase

        for (s = 0; s < NUM_SLV; s = s + 1) begin
          if (ar_fire[s] && (ar_gnt_m[s] == m[MST_IDX_W-1:0]))
            ar_issued[m] <= 1'b1;
          if (aw_fire[s] && (aw_gnt_m[s] == m[MST_IDX_W-1:0]))
            aw_issued[m] <= 1'b1;
        end

        if ((ar_count[m] != '0) && !ar_mapped[m] &&
            mst_resp[m].r_valid && mst_req[m].r_ready && !ar_pop[m])
          error_r_pos[m] <= error_r_pos[m] + 1'b1;

        if (w_take[m] && !w_done[m]) begin
          if (w_pos[m] == aw_head[m].len)
            w_done[m] <= 1'b1;
          else
            w_pos[m] <= w_pos[m] + 1'b1;
        end

        if (ar_pop[m]) begin
          if (ar_rp[m] == PTR_LAST)
            ar_rp[m] <= '0;
          else
            ar_rp[m] <= ar_rp[m] + 1'b1;
          ar_issued[m]   <= 1'b0;
          error_r_pos[m] <= '0;
        end

        if (aw_pop[m]) begin
          if (aw_rp[m] == PTR_LAST)
            aw_rp[m] <= '0;
          else
            aw_rp[m] <= aw_rp[m] + 1'b1;
          aw_issued[m] <= 1'b0;
          w_done[m]    <= 1'b0;
          w_pos[m]     <= '0;
        end
      end
    end
  end

  // Independent round-robin arbiters on every slave port.
  always_ff @(posedge clk) begin : p_slave_state
    integer m;
    integer s;
    if (!rst_n) begin
      for (s = 0; s < NUM_SLV; s = s + 1) begin
        ar_gnt_v[s] <= 1'b0;
        aw_gnt_v[s] <= 1'b0;
        ar_gnt_m[s] <= '0;
        aw_gnt_m[s] <= '0;
        ar_rr[s]    <= '0;
        aw_rr[s]    <= '0;
        wr_busy[s]  <= 1'b0;
        wr_owner[s] <= '0;
      end
    end else begin
      for (s = 0; s < NUM_SLV; s = s + 1) begin
        if (ar_gnt_v[s]) begin
          if (ar_fire[s]) begin
            ar_gnt_v[s] <= 1'b0;
            ar_rr[s]    <= rr_next(ar_gnt_m[s]);
          end
        end else if (|ar_req[s]) begin
          ar_gnt_v[s] <= 1'b1;
          ar_gnt_m[s] <= rr_pick(ar_req[s], ar_rr[s]);
        end

        if (aw_gnt_v[s]) begin
          if (aw_fire[s]) begin
            aw_gnt_v[s] <= 1'b0;
            aw_rr[s]    <= rr_next(aw_gnt_m[s]);
          end
        end else if (|aw_req[s]) begin
          aw_gnt_v[s] <= 1'b1;
          aw_gnt_m[s] <= rr_pick(aw_req[s], aw_rr[s]);
        end

        for (m = 0; m < NUM_MST; m = m + 1) begin
          if (w_take[m] && aw_mapped[m] &&
              (aw_target[m] == s[SLV_IDX_W-1:0]) &&
              (w_pos[m] == aw_head[m].len) && wr_busy[s] &&
              (wr_owner[s] == m[MST_IDX_W-1:0]))
            wr_busy[s] <= 1'b0;
        end

        if (aw_fire[s]) begin
          wr_busy[s]  <= 1'b1;
          wr_owner[s] <= aw_gnt_m[s];
        end
      end
    end
  end

endmodule
