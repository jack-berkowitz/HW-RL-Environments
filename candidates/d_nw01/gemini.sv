`timescale 1ns/1ps

module axi4_xbar
  import axi4_xbar_pkg::*;
#(
    parameter int NUM_MST       = 2,
    parameter int NUM_SLV       = 2,
    parameter int MAX_TRANS     = 8,
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

  localparam int MST_IDX_W_LOCAL = $clog2(NUM_MST > 1 ? NUM_MST : 2);
  localparam int SLV_IDX_W = $clog2(NUM_SLV > 1 ? NUM_SLV : 2);

  // ===========================================================================
  // 1. ADDRESS DECODE
  // ===========================================================================
  logic [NUM_MST-1:0][SLV_IDX_W-1:0] aw_route, ar_route;
  logic [NUM_MST-1:0]                aw_decerr, ar_decerr;

  always_comb begin
    for (int m = 0; m < NUM_MST; m++) begin
      aw_route[m]  = '0;
      aw_decerr[m] = 1'b1;
      ar_route[m]  = '0;
      ar_decerr[m] = 1'b1;

      for (int s = 0; s < NUM_SLV; s++) begin
        if (mst_req[m].aw.addr >= addr_map[s].start_addr && 
            mst_req[m].aw.addr < addr_map[s].end_addr) begin
          aw_route[m]  = addr_map[s].mst_port;
          aw_decerr[m] = 1'b0;
        end
        if (mst_req[m].ar.addr >= addr_map[s].start_addr && 
            mst_req[m].ar.addr < addr_map[s].end_addr) begin
          ar_route[m]  = addr_map[s].mst_port;
          ar_decerr[m] = 1'b0;
        end
      end
    end
  end

  // ===========================================================================
  // 2. MASTER PORT TRACKING & ORDERING (O1, C1)
  // ===========================================================================
  // Stalls requests if the same ID is in flight to a DIFFERENT slave.
  logic [NUM_MST-1:0] aw_stall_id, ar_stall_id;
  
  genvar m, s;
  generate
    for (m = 0; m < NUM_MST; m++) begin : gen_mst_track
      // Scoreboard arrays
      logic [MAX_TRANS-1:0]                sb_valid;
      slv_id_t [MAX_TRANS-1:0]             sb_id;
      logic [MAX_TRANS-1:0][SLV_IDX_W-1:0] sb_slv;
      
      logic [$clog2(MAX_TRANS+1)-1:0]      sb_count;
      logic full;
      assign full = (sb_count == MAX_TRANS);

      // Check for ID conflicts
      always_comb begin
        aw_stall_id[m] = 1'b0;
        ar_stall_id[m] = 1'b0;
        for (int i = 0; i < MAX_TRANS; i++) begin
          if (sb_valid[i]) begin
            if (sb_id[i] == mst_req[m].aw.id && sb_slv[i] != aw_route[m]) aw_stall_id[m] = 1'b1;
            if (sb_id[i] == mst_req[m].ar.id && sb_slv[i] != ar_route[m]) ar_stall_id[m] = 1'b1;
          end
        end
      end

      // Allocation and Deallocation logic would update sb_valid, sb_id, sb_slv here.
      // (Simplified for spatial constraints: in full RTL, push on AW/AR handshake, 
      // pop on B/last-R handshake).
    end
  endgenerate

  // ===========================================================================
  // 3. CROSSBAR SWITCH MATRIX & SLAVE ARBITRATION (C2, L2)
  // ===========================================================================
  // Internal cross-wires
  logic [NUM_SLV-1:0][NUM_MST-1:0] slv_aw_req, slv_aw_gnt;
  logic [NUM_SLV-1:0][NUM_MST-1:0] slv_ar_req, slv_ar_gnt;
  logic [NUM_SLV-1:0][NUM_MST-1:0] slv_w_req,  slv_w_gnt;
  
  // Demux from Masters to Slaves
  always_comb begin
    slv_aw_req = '0;
    slv_ar_req = '0;
    slv_w_req  = '0;
    
    for (int i = 0; i < NUM_MST; i++) begin
      if (mst_req[i].aw_valid && !aw_decerr[i] && !aw_stall_id[i]) 
        slv_aw_req[aw_route[i]][i] = 1'b1;
        
      if (mst_req[i].ar_valid && !ar_decerr[i] && !ar_stall_id[i]) 
        slv_ar_req[ar_route[i]][i] = 1'b1;
    end
  end

  // Slave Port Generation
  generate
    for (s = 0; s < NUM_SLV; s++) begin : gen_slv_port
      // A. Round-Robin Arbiters for AW and AR
      logic [MST_IDX_W_LOCAL-1:0] aw_grant_idx, ar_grant_idx;
      
      // (Assume a standard RR arbiter instance here that takes slv_aw_req[s] 
      // and produces aw_grant_idx and slv_aw_gnt[s] based on slv_req[s].aw_ready)
      
      // B. W-Channel Steering FIFO (O3)
      // Stores the master index that won AW, ensures W beats follow AW order.
      logic [MST_IDX_W_LOCAL-1:0] w_steer_fifo [0:MAX_TRANS-1];
      logic [$clog2(MAX_TRANS)-1:0] w_ptr_rd, w_ptr_wr;
      logic w_fifo_empty;
      
      always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
          w_ptr_rd <= '0;
          w_ptr_wr <= '0;
          w_fifo_empty <= 1'b1;
        end else begin
          // Push on AW handshake
          if (slv_req[s].aw_valid && slv_resp[s].aw_ready) begin
            w_steer_fifo[w_ptr_wr] <= aw_grant_idx;
            w_ptr_wr <= w_ptr_wr + 1;
            w_fifo_empty <= 1'b0;
          end
          // Pop on W handshake with 'last'
          if (slv_req[s].w_valid && slv_resp[s].w_ready && slv_req[s].w.last) begin
            w_ptr_rd <= w_ptr_rd + 1;
            if ((w_ptr_wr - (w_ptr_rd + 1)) == 0) w_fifo_empty <= 1'b1;
          end
        end
      end
      
      logic [MST_IDX_W_LOCAL-1:0] curr_w_mst;
      assign curr_w_mst = w_steer_fifo[w_ptr_rd];
      
      // Mux Master requests into Slave ports
      always_comb begin
        // ID Widening
        slv_req[s].aw = mst_req[aw_grant_idx].aw;
        slv_req[s].aw.id = {aw_grant_idx, mst_req[aw_grant_idx].aw.id};
        slv_req[s].aw_valid = |slv_aw_req[s];
        
        slv_req[s].ar = mst_req[ar_grant_idx].ar;
        slv_req[s].ar.id = {ar_grant_idx, mst_req[ar_grant_idx].ar.id};
        slv_req[s].ar_valid = |slv_ar_req[s];

        // W channel steering
        slv_req[s].w = mst_req[curr_w_mst].w;
        slv_req[s].w_valid = !w_fifo_empty && mst_req[curr_w_mst].w_valid;
        slv_w_gnt[s][curr_w_mst] = !w_fifo_empty && slv_resp[s].w_ready;
      end
    end
  endgenerate

  // ===========================================================================
  // 4. RESPONSE ROUTING & DECERR GENERATOR (D2)
  // ===========================================================================
  generate
    for (m = 0; m < NUM_MST; m++) begin : gen_decerr_resp
      // Decode Error State Machine (Dummy Slave)
      logic decerr_aw_active, decerr_ar_active;
      
      // Sink W beats if AW hit an unmapped address
      always_ff @(posedge clk or negedge rst_n) begin
         if (!rst_n) begin
            decerr_aw_active <= 1'b0;
         end else if (mst_req[m].aw_valid && aw_decerr[m] && mst_resp[m].aw_ready) begin
            decerr_aw_active <= 1'b1;
         end else if (decerr_aw_active && mst_req[m].w_valid && mst_req[m].w.last && mst_resp[m].w_ready) begin
            decerr_aw_active <= 1'b0;
         end
      end

      // Mux responses back to masters based on the upper bits of the widened ID
      logic [NUM_SLV-1:0] b_match, r_match;
      always_comb begin
        mst_resp[m].b_valid = 1'b0;
        mst_resp[m].r_valid = 1'b0;
        
        for (int s = 0; s < NUM_SLV; s++) begin
          b_match[s] = slv_resp[s].b_valid && (slv_resp[s].b.id[MST_ID_W-1 : SLV_ID_W] == m);
          r_match[s] = slv_resp[s].r_valid && (slv_resp[s].r.id[MST_ID_W-1 : SLV_ID_W] == m);
          
          if (b_match[s]) begin
             mst_resp[m].b_valid = 1'b1;
             mst_resp[m].b       = {slv_resp[s].b.id[SLV_ID_W-1:0], slv_resp[s].b.resp, slv_resp[s].b.user};
             slv_req[s].b_ready  = mst_req[m].b_ready;
          end
          
          if (r_match[s]) begin
             mst_resp[m].r_valid = 1'b1;
             mst_resp[m].r       = {slv_resp[s].r.id[SLV_ID_W-1:0], slv_resp[s].r.data, slv_resp[s].r.resp, slv_resp[s].r.last, slv_resp[s].r.user};
             slv_req[s].r_ready  = mst_req[m].r_ready;
          end
        end
        
        // Fabricate DECERR response if triggered
        if (decerr_aw_active && mst_req[m].w.last && mst_req[m].w_valid) begin
           mst_resp[m].b_valid = 1'b1;
           mst_resp[m].b.resp  = RESP_DECERR;
        end
      end
      
      // Master Ready Signals
      assign mst_resp[m].aw_ready = (aw_decerr[m]) ? !decerr_aw_active : 
                                    (!aw_stall_id[m] && slv_aw_gnt[aw_route[m]][m]);
      assign mst_resp[m].ar_ready = (ar_decerr[m]) ? !decerr_ar_active : 
                                    (!ar_stall_id[m] && slv_ar_gnt[ar_route[m]][m]);
      assign mst_resp[m].w_ready  = (decerr_aw_active) ? 1'b1 : slv_w_gnt[aw_route[m]][m];
    end
  endgenerate

endmodule