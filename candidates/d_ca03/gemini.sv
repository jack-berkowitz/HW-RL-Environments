// =============================================================================
// sv39_mmu.sv
//
// A synthesizable RISC-V Sv39 memory management unit satisfying d_ca03.
// Features a cycle-efficient parallel TLB lookup for LSU and Fetch, a 
// dynamically multiplexed page-table walker, precise PMP checking, and 
// complete fault tracking.
// =============================================================================

module sv39_mmu (
  input  logic        clk_i,
  input  logic        rst_ni,
  input  logic        flush_i,

  input  logic        enable_translation_i,
  input  logic        en_ld_st_translation_i,

  input  logic        lsu_req_i,
  input  logic [63:0] lsu_vaddr_i,
  input  logic        lsu_is_store_i,
  output logic        lsu_valid_o,
  output logic [55:0] lsu_paddr_o,
  output logic        lsu_dtlb_hit_o,
  output logic [43:0] lsu_dtlb_ppn_o,
  output logic        lsu_exc_valid_o,
  output logic [63:0] lsu_exc_cause_o,
  output logic [63:0] lsu_exc_tval_o,

  input  logic        fetch_req_i,
  input  logic [63:0] fetch_vaddr_i,
  output logic        fetch_valid_o,
  output logic [55:0] fetch_paddr_o,
  output logic        fetch_exc_valid_o,
  output logic [63:0] fetch_exc_cause_o,
  output logic [63:0] fetch_exc_tval_o,

  input  logic [1:0]  priv_lvl_i,
  input  logic [1:0]  ld_st_priv_lvl_i,
  input  logic        sum_i,
  input  logic        mxr_i,
  input  logic [43:0] satp_ppn_i,
  input  logic [15:0] asid_i,

  input  logic        flush_tlb_i,
  input  logic [15:0] asid_to_be_flushed_i,
  input  logic [63:0] vaddr_to_be_flushed_i,
  output logic        itlb_miss_o,
  output logic        dtlb_miss_o,

  output logic        mem_req_o,
  output logic [55:0] mem_addr_o,
  output logic        mem_tag_valid_o,
  output logic        mem_kill_o,
  input  logic        mem_gnt_i,
  input  logic        mem_rvalid_i,
  input  logic [63:0] mem_rdata_i,

  input  logic [7:0][7:0]  pmpcfg_i,
  input  logic [7:0][53:0] pmpaddr_i
);

  // ---------------------------------------------------------------------------
  // Functions
  // ---------------------------------------------------------------------------
  
  // PMP byte-matching logic
  function automatic logic [3:0] pmp_match_byte(
      input logic [55:0] byte_addr,
      input logic [7:0][7:0] pmpcfg,
      input logic [7:0][53:0] pmpaddr
  );
      logic [55:0] prev_pmpaddr;
      logic [55:0] cur_pmpaddr;
      logic [1:0] mode;
      logic [55:0] mask;
      logic [55:0] base;
      int i, j;
      
      for (i = 0; i < 8; i++) begin
          mode = pmpcfg[i][4:3];
          prev_pmpaddr = (i == 0) ? 56'b0 : {pmpaddr[i-1], 2'b00};
          cur_pmpaddr = {pmpaddr[i], 2'b00};
          
          if (mode == 1) begin // TOR
              if (byte_addr >= prev_pmpaddr && byte_addr < cur_pmpaddr) return i[3:0];
          end else if (mode == 2) begin // NA4
              if (byte_addr >= cur_pmpaddr && byte_addr < (cur_pmpaddr + 4)) return i[3:0];
          end else if (mode == 3) begin // NAPOT
              mask = ~56'h7;
              for (j = 0; j < 53; j++) begin
                  if (pmpaddr[i][j]) mask[j+3] = 1'b0;
                  else break;
              end
              base = cur_pmpaddr & mask;
              if ((byte_addr & mask) == base) return i[3:0];
          end
      end
      return 4'd8; // No match
  endfunction

  // PTE permission checking
  function automatic logic check_perms(
      input logic r, w, x, u, a, d,
      input logic is_store,
      input logic is_fetch,
      input logic [1:0] priv,
      input logic sum,
      input logic mxr
  );
      // User mode check
      if (priv == 2'b00 && !u) return 0;
      
      // Supervisor mode check
      if (priv == 2'b01) begin
          if (u && !sum) return 0;
          if (u && is_fetch) return 0;
      end
      
      // Base access type checks
      if (is_fetch) begin
          if (!x) return 0;
      end else if (is_store) begin
          if (!w) return 0;
      end else begin // load
          if (!r && !(x && mxr)) return 0;
      end
      
      // Fault on A/D unset (A5 choice)
      if (!a) return 0;
      if (is_store && !d) return 0;
      
      return 1;
  endfunction


  // ---------------------------------------------------------------------------
  // TLB Storage and Lookup
  // ---------------------------------------------------------------------------

  logic [26:0] lsu_vpn;
  logic [26:0] fetch_vpn;
  assign lsu_vpn = lsu_vaddr_i[38:12];
  assign fetch_vpn = fetch_vaddr_i[38:12];

  // DTLB structures
  logic [15:0] dtlb_valid;
  logic [15:0] dtlb_is_1g;
  logic [15:0] dtlb_is_2m;
  logic [15:0] dtlb_entry_g;
  logic [15:0][26:0] dtlb_vpn;
  logic [15:0][15:0] dtlb_entry_asid;
  logic [15:0][43:0] dtlb_entry_ppn;
  logic [15:0] dtlb_entry_r, dtlb_entry_w, dtlb_entry_x, dtlb_entry_u, dtlb_entry_a, dtlb_entry_d;
  logic [3:0] dtlb_rep_ptr;
  
  // ITLB structures
  logic [15:0] itlb_valid;
  logic [15:0] itlb_is_1g;
  logic [15:0] itlb_is_2m;
  logic [15:0] itlb_entry_g;
  logic [15:0][26:0] itlb_vpn;
  logic [15:0][15:0] itlb_entry_asid;
  logic [15:0][43:0] itlb_entry_ppn;
  logic [15:0] itlb_entry_r, itlb_entry_w, itlb_entry_x, itlb_entry_u, itlb_entry_a, itlb_entry_d;
  logic [3:0] itlb_rep_ptr;

  // TLB match evaluation (Combinational)
  logic dtlb_hit;
  logic [43:0] dtlb_ppn;
  logic dtlb_r, dtlb_w, dtlb_x, dtlb_u, dtlb_a, dtlb_d, dtlb_g;
  logic [1:0] dtlb_level;

  always_comb begin
      int i;
      logic match_vpn;
      logic match_asid;
      
      dtlb_hit = 0;
      dtlb_ppn = 0;
      dtlb_r = 0; dtlb_w = 0; dtlb_x = 0; dtlb_u = 0; dtlb_a = 0; dtlb_d = 0; dtlb_g = 0;
      dtlb_level = 0;
      
      for (i = 0; i < 16; i++) begin
          if (dtlb_valid[i]) begin
              if (dtlb_is_1g[i]) match_vpn = (lsu_vpn[26:18] == dtlb_vpn[i][26:18]);
              else if (dtlb_is_2m[i]) match_vpn = (lsu_vpn[26:9] == dtlb_vpn[i][26:9]);
              else match_vpn = (lsu_vpn == dtlb_vpn[i]);
              
              match_asid = dtlb_entry_g[i] | (dtlb_entry_asid[i] == asid_i);
              
              if (match_vpn && match_asid) begin
                  dtlb_hit = 1;
                  dtlb_ppn = dtlb_entry_ppn[i];
                  dtlb_r = dtlb_entry_r[i]; dtlb_w = dtlb_entry_w[i]; dtlb_x = dtlb_entry_x[i];
                  dtlb_u = dtlb_entry_u[i]; dtlb_a = dtlb_entry_a[i]; dtlb_d = dtlb_entry_d[i];
                  dtlb_g = dtlb_entry_g[i];
                  dtlb_level = dtlb_is_1g[i] ? 2'd2 : (dtlb_is_2m[i] ? 2'd1 : 2'd0);
              end
          end
      end
  end

  logic itlb_hit;
  logic [43:0] itlb_ppn;
  logic itlb_r, itlb_w, itlb_x, itlb_u, itlb_a, itlb_d, itlb_g;
  logic [1:0] itlb_level;

  always_comb begin
      int i;
      logic match_vpn;
      logic match_asid;
      
      itlb_hit = 0;
      itlb_ppn = 0;
      itlb_r = 0; itlb_w = 0; itlb_x = 0; itlb_u = 0; itlb_a = 0; itlb_d = 0; itlb_g = 0;
      itlb_level = 0;
      
      for (i = 0; i < 16; i++) begin
          if (itlb_valid[i]) begin
              if (itlb_is_1g[i]) match_vpn = (fetch_vpn[26:18] == itlb_vpn[i][26:18]);
              else if (itlb_is_2m[i]) match_vpn = (fetch_vpn[26:9] == itlb_vpn[i][26:9]);
              else match_vpn = (fetch_vpn == itlb_vpn[i]);
              
              match_asid = itlb_entry_g[i] | (itlb_entry_asid[i] == asid_i);
              
              if (match_vpn && match_asid) begin
                  itlb_hit = 1;
                  itlb_ppn = itlb_entry_ppn[i];
                  itlb_r = itlb_entry_r[i]; itlb_w = itlb_entry_w[i]; itlb_x = itlb_entry_x[i];
                  itlb_u = itlb_entry_u[i]; itlb_a = itlb_entry_a[i]; itlb_d = itlb_entry_d[i];
                  itlb_g = itlb_entry_g[i];
                  itlb_level = itlb_is_1g[i] ? 2'd2 : (itlb_is_2m[i] ? 2'd1 : 2'd0);
              end
          end
      end
  end


  // ---------------------------------------------------------------------------
  // Fast Combinational Return Paths (TLB Hit or BARE mode)
  // ---------------------------------------------------------------------------

  logic [55:0] lsu_hit_pa;
  always_comb begin
      lsu_hit_pa = {dtlb_ppn, lsu_vaddr_i[11:0]};
      if (dtlb_level == 1) lsu_hit_pa[20:12] = lsu_vpn[8:0];
      if (dtlb_level == 2) lsu_hit_pa[29:12] = lsu_vpn[17:0];
  end

  logic [55:0] fetch_hit_pa;
  always_comb begin
      fetch_hit_pa = {itlb_ppn, fetch_vaddr_i[11:0]};
      if (itlb_level == 1) fetch_hit_pa[20:12] = fetch_vpn[8:0];
      if (itlb_level == 2) fetch_hit_pa[29:12] = fetch_vpn[17:0];
  end

  logic lsu_hit_perm_ok;
  logic fetch_hit_perm_ok;
  always_comb begin
      lsu_hit_perm_ok = check_perms(dtlb_r, dtlb_w, dtlb_x, dtlb_u, dtlb_a, dtlb_d, lsu_is_store_i, 1'b0, ld_st_priv_lvl_i, sum_i, mxr_i);
      fetch_hit_perm_ok = check_perms(itlb_r, itlb_w, itlb_x, itlb_u, itlb_a, itlb_d, 1'b0, 1'b1, priv_lvl_i, sum_i, mxr_i);
  end

  logic lsu_comb_valid, lsu_comb_exc;
  logic [55:0] lsu_comb_pa;
  logic [63:0] lsu_comb_cause;
  
  always_comb begin
      lsu_comb_valid = 0; lsu_comb_exc = 0; lsu_comb_cause = 0; lsu_comb_pa = 0;
      if (lsu_req_i) begin
          if (!en_ld_st_translation_i) begin
              lsu_comb_valid = 1;
              lsu_comb_pa = lsu_vaddr_i[55:0];
          end else if (dtlb_hit) begin
              lsu_comb_valid = 1;
              lsu_comb_pa = lsu_hit_pa;
              if (!lsu_hit_perm_ok) begin
                  lsu_comb_exc = 1;
                  lsu_comb_cause = lsu_is_store_i ? 64'd15 : 64'd13;
              end
          end
      end
  end

  logic fetch_comb_valid, fetch_comb_exc;
  logic [55:0] fetch_comb_pa;
  logic [63:0] fetch_comb_cause;
  
  always_comb begin
      fetch_comb_valid = 0; fetch_comb_exc = 0; fetch_comb_cause = 0; fetch_comb_pa = 0;
      if (fetch_req_i) begin
          if (!enable_translation_i) begin
              fetch_comb_valid = 1;
              fetch_comb_pa = fetch_vaddr_i[55:0];
          end else if (itlb_hit) begin
              fetch_comb_valid = 1;
              fetch_comb_pa = fetch_hit_pa;
              if (!fetch_hit_perm_ok) begin
                  fetch_comb_exc = 1;
                  fetch_comb_cause = 64'd12;
              end
          end
      end
  end


  // ---------------------------------------------------------------------------
  // Page Table Walker
  // ---------------------------------------------------------------------------

  typedef enum logic [3:0] {
      IDLE,
      WALK_REQ,
      WALK_WAIT,
      WALK_DRAIN
  } state_t;

  state_t state;
  logic mem_inflight;
  logic walking_for_fetch;
  logic [1:0] walk_level;
  logic [55:0] walk_addr;

  logic lsu_needs_walk, fetch_needs_walk;
  assign lsu_needs_walk = lsu_req_i && en_ld_st_translation_i && !dtlb_hit;
  assign fetch_needs_walk = fetch_req_i && enable_translation_i && !itlb_hit;

  logic [26:0] cur_vpn;
  assign cur_vpn = walking_for_fetch ? fetch_vpn : lsu_vpn;

  logic [8:0] next_vpn_part;
  always_comb begin
      if (walk_level == 2) next_vpn_part = cur_vpn[17:9];
      else next_vpn_part = cur_vpn[8:0];
  end

  // PMP Check for the walker's physical memory request
  logic [3:0] pmp_match0, pmp_match7;
  logic pmp_deny;
  
  always_comb begin
      pmp_match0 = pmp_match_byte(walk_addr, pmpcfg_i, pmpaddr_i);
      pmp_match7 = pmp_match_byte(walk_addr + 56'd7, pmpcfg_i, pmpaddr_i);
      pmp_deny = 0;
      if (pmp_match0 != pmp_match7) pmp_deny = 1;
      else if (pmp_match0 == 4'd8) pmp_deny = 1;
      else pmp_deny = ~(pmpcfg_i[pmp_match0][0]);
  end

  assign mem_req_o = (state == WALK_REQ) && !pmp_deny && !flush_i;
  assign mem_addr_o = walk_addr;
  assign mem_tag_valid_o = 0;
  assign mem_kill_o = 0;

  logic pte_ready;
  assign pte_ready = !flush_i && ((state == WALK_WAIT && mem_rvalid_i) || 
                     (state == WALK_REQ && !pmp_deny && mem_req_o && mem_gnt_i && mem_rvalid_i));

  logic [63:0] pte;
  assign pte = mem_rdata_i;
  
  logic pte_v, pte_r, pte_w, pte_x, pte_u, pte_g, pte_a, pte_d;
  logic [43:0] pte_ppn;
  assign {pte_d, pte_a, pte_g, pte_u, pte_x, pte_w, pte_r, pte_v} = pte[7:0];
  assign pte_ppn = pte[53:10];
  
  logic is_leaf;
  assign is_leaf = pte_r | pte_x;
  
  logic pte_invalid;
  assign pte_invalid = !pte_v || (pte_w && !pte_r);
  
  logic pte_misaligned;
  always_comb begin
      pte_misaligned = 0;
      if (walk_level == 2 && pte_ppn[17:0] != 0) pte_misaligned = 1;
      if (walk_level == 1 && pte_ppn[8:0] != 0) pte_misaligned = 1;
  end
  
  logic walk_fault;
  assign walk_fault = pte_invalid || (is_leaf && pte_misaligned) || (!is_leaf && (walk_level == 0));
  
  logic leaf_perm_ok;
  always_comb begin
      leaf_perm_ok = check_perms(pte_r, pte_w, pte_x, pte_u, pte_a, pte_d, 
                                 walking_for_fetch ? 1'b0 : lsu_is_store_i, 
                                 walking_for_fetch, 
                                 walking_for_fetch ? priv_lvl_i : ld_st_priv_lvl_i, 
                                 sum_i, mxr_i);
  end

  logic walk_ret_valid, walk_ret_exc, walk_tlb_we;
  logic [63:0] walk_ret_cause;
  
  always_comb begin
      walk_ret_valid = 0; walk_ret_exc = 0; walk_ret_cause = 0; walk_tlb_we = 0;
      
      if (!flush_i) begin
          if (state == WALK_REQ && pmp_deny) begin
              walk_ret_valid = 1; walk_ret_exc = 1;
              if (walking_for_fetch) walk_ret_cause = 1;
              else if (lsu_is_store_i) walk_ret_cause = 7;
              else walk_ret_cause = 5;
          end else if (pte_ready) begin
              if (walk_fault || (is_leaf && !leaf_perm_ok)) begin
                  walk_ret_valid = 1; walk_ret_exc = 1;
                  if (walking_for_fetch) walk_ret_cause = 12;
                  else if (lsu_is_store_i) walk_ret_cause = 15;
                  else walk_ret_cause = 13;
              end else if (is_leaf && leaf_perm_ok) begin
                  walk_ret_valid = 1;
                  walk_tlb_we = 1;
              end
          end
      end
  end

  logic [55:0] walk_final_pa;
  always_comb begin
      walk_final_pa = {pte_ppn, (walking_for_fetch ? fetch_vaddr_i[11:0] : lsu_vaddr_i[11:0])};
      if (walk_level == 1) walk_final_pa[20:12] = cur_vpn[8:0];
      if (walk_level == 2) walk_final_pa[29:12] = cur_vpn[17:0];
  end


  // ---------------------------------------------------------------------------
  // State Machine Updates
  // ---------------------------------------------------------------------------
  
  always_ff @(posedge clk) begin
      if (!rst_ni) begin
          state <= IDLE;
      end else if (flush_i) begin
          if ((mem_inflight && !mem_rvalid_i) || (state == WALK_REQ && mem_req_o && mem_gnt_i && !mem_rvalid_i)) begin
              state <= WALK_DRAIN;
          end else begin
              state <= IDLE;
          end
      end else begin
          case (state)
              IDLE: begin
                  if (lsu_needs_walk) begin
                      walking_for_fetch <= 0;
                      walk_level <= 2;
                      walk_addr <= {satp_ppn_i, lsu_vpn[26:18], 3'b000};
                      state <= WALK_REQ;
                  end else if (fetch_needs_walk) begin
                      walking_for_fetch <= 1;
                      walk_level <= 2;
                      walk_addr <= {satp_ppn_i, fetch_vpn[26:18], 3'b000};
                      state <= WALK_REQ;
                  end
              end
              
              WALK_REQ: begin
                  if (pmp_deny) begin
                      state <= IDLE;
                  end else if (mem_req_o && mem_gnt_i) begin
                      if (mem_rvalid_i) begin
                          if (is_leaf || walk_fault) state <= IDLE;
                          else begin
                              walk_level <= walk_level - 1;
                              walk_addr <= {pte_ppn, next_vpn_part, 3'b000};
                          end
                      end else begin
                          state <= WALK_WAIT;
                      end
                  end
              end
              
              WALK_WAIT: begin
                  if (mem_rvalid_i) begin
                      if (is_leaf || walk_fault) state <= IDLE;
                      else begin
                          walk_level <= walk_level - 1;
                          walk_addr <= {pte_ppn, next_vpn_part, 3'b000};
                          state <= WALK_REQ;
                      end
                  end
              end
              
              WALK_DRAIN: begin
                  if (mem_rvalid_i || !mem_inflight) begin
                      state <= IDLE;
                  end
              end
          endcase
      end
  end

  always_ff @(posedge clk) begin
      if (!rst_ni) mem_inflight <= 0;
      else begin
          if (mem_rvalid_i) mem_inflight <= 0;
          else if (mem_req_o && mem_gnt_i) mem_inflight <= 1;
      end
  end


  // ---------------------------------------------------------------------------
  // TLB Writing logic (Eviction and Installation)
  // ---------------------------------------------------------------------------

  logic tlb_we_dtlb;
  logic tlb_we_itlb;
  assign tlb_we_dtlb = walk_tlb_we && !walking_for_fetch;
  assign tlb_we_itlb = walk_tlb_we && walking_for_fetch;

  logic dtlb_has_inv, itlb_has_inv;
  logic [3:0] dtlb_inv_idx, itlb_inv_idx;
  logic [3:0] dtlb_alloc_idx, itlb_alloc_idx;

  always_comb begin
      int i;
      dtlb_has_inv = 0; dtlb_inv_idx = 0;
      itlb_has_inv = 0; itlb_inv_idx = 0;
      for (i = 15; i >= 0; i--) begin
          if (!dtlb_valid[i]) begin dtlb_has_inv = 1; dtlb_inv_idx = i[3:0]; end
          if (!itlb_valid[i]) begin itlb_has_inv = 1; itlb_inv_idx = i[3:0]; end
      end
  end
  assign dtlb_alloc_idx = dtlb_has_inv ? dtlb_inv_idx : dtlb_rep_ptr;
  assign itlb_alloc_idx = itlb_has_inv ? itlb_inv_idx : itlb_rep_ptr;

  always_ff @(posedge clk) begin
      if (!rst_ni || flush_tlb_i) begin
          dtlb_valid <= 0; dtlb_rep_ptr <= 0;
      end else if (tlb_we_dtlb) begin
          dtlb_valid[dtlb_alloc_idx] <= 1;
          dtlb_is_1g[dtlb_alloc_idx] <= (walk_level == 2);
          dtlb_is_2m[dtlb_alloc_idx] <= (walk_level == 1);
          dtlb_entry_g[dtlb_alloc_idx] <= pte_g;
          dtlb_vpn[dtlb_alloc_idx] <= lsu_vpn;
          dtlb_entry_asid[dtlb_alloc_idx] <= asid_i;
          dtlb_entry_ppn[dtlb_alloc_idx] <= pte_ppn;
          dtlb_entry_r[dtlb_alloc_idx] <= pte_r; dtlb_entry_w[dtlb_alloc_idx] <= pte_w;
          dtlb_entry_x[dtlb_alloc_idx] <= pte_x; dtlb_entry_u[dtlb_alloc_idx] <= pte_u;
          dtlb_entry_a[dtlb_alloc_idx] <= pte_a; dtlb_entry_d[dtlb_alloc_idx] <= pte_d;
          if (!dtlb_has_inv) dtlb_rep_ptr <= dtlb_rep_ptr + 1;
      end
  end

  always_ff @(posedge clk) begin
      if (!rst_ni || flush_tlb_i) begin
          itlb_valid <= 0; itlb_rep_ptr <= 0;
      end else if (tlb_we_itlb) begin
          itlb_valid[itlb_alloc_idx] <= 1;
          itlb_is_1g[itlb_alloc_idx] <= (walk_level == 2);
          itlb_is_2m[itlb_alloc_idx] <= (walk_level == 1);
          itlb_entry_g[itlb_alloc_idx] <= pte_g;
          itlb_vpn[itlb_alloc_idx] <= fetch_vpn;
          itlb_entry_asid[itlb_alloc_idx] <= asid_i;
          itlb_entry_ppn[itlb_alloc_idx] <= pte_ppn;
          itlb_entry_r[itlb_alloc_idx] <= pte_r; itlb_entry_w[itlb_alloc_idx] <= pte_w;
          itlb_entry_x[itlb_alloc_idx] <= pte_x; itlb_entry_u[itlb_alloc_idx] <= pte_u;
          itlb_entry_a[itlb_alloc_idx] <= pte_a; itlb_entry_d[itlb_alloc_idx] <= pte_d;
          if (!itlb_has_inv) itlb_rep_ptr <= itlb_rep_ptr + 1;
      end
  end


  // ---------------------------------------------------------------------------
  // Output Routing
  // ---------------------------------------------------------------------------

  assign lsu_valid_o       = (lsu_req_i && (!en_ld_st_translation_i || dtlb_hit)) ? 1'b1 : ((state != IDLE && state != WALK_DRAIN && !walking_for_fetch) ? walk_ret_valid : 1'b0);
  assign lsu_paddr_o       = (state == IDLE || lsu_comb_valid) ? lsu_comb_pa : walk_final_pa;
  assign lsu_dtlb_hit_o    = dtlb_hit;
  assign lsu_dtlb_ppn_o    = dtlb_ppn;
  assign lsu_exc_valid_o   = (state == IDLE || lsu_comb_valid) ? lsu_comb_exc : ((!walking_for_fetch) ? walk_ret_exc : 0);
  assign lsu_exc_cause_o   = (state == IDLE || lsu_comb_valid) ? lsu_comb_cause : walk_ret_cause;
  assign lsu_exc_tval_o    = lsu_vaddr_i;

  assign fetch_valid_o     = (fetch_req_i && (!enable_translation_i || itlb_hit)) ? 1'b1 : ((state != IDLE && state != WALK_DRAIN && walking_for_fetch) ? walk_ret_valid : 1'b0);
  assign fetch_paddr_o     = (state == IDLE || fetch_comb_valid) ? fetch_comb_pa : walk_final_pa;
  assign fetch_exc_valid_o = (state == IDLE || fetch_comb_valid) ? fetch_comb_exc : ((walking_for_fetch) ? walk_ret_exc : 0);
  assign fetch_exc_cause_o = (state == IDLE || fetch_comb_valid) ? fetch_comb_cause : walk_ret_cause;
  assign fetch_exc_tval_o  = fetch_vaddr_i;

  assign itlb_miss_o       = fetch_req_i && enable_translation_i && !itlb_hit;
  assign dtlb_miss_o       = lsu_req_i && en_ld_st_translation_i && !dtlb_hit;

endmodule