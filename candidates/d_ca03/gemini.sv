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

  // Unused output tie-offs
  assign mem_tag_valid_o = 1'b0;
  assign mem_kill_o = 1'b0;
  assign lsu_exc_tval_o = lsu_vaddr_i;
  assign fetch_exc_tval_o = fetch_vaddr_i;

  // BARE mode enables
  logic lsu_bare;
  logic fetch_bare;
  assign lsu_bare = !en_ld_st_translation_i;
  assign fetch_bare = !enable_translation_i;

  // TLB Storage (16 entries each, fully associative)
  typedef struct packed {
    logic        valid;
    logic [1:0]  level;     // 0: 4KB, 1: 2MB, 2: 1GB
    logic [26:0] vpn;
    logic [15:0] asid;
    logic        G;
    logic [43:0] ppn;
    logic [6:0]  pte_perms; // [6] D, [5] A, [4] U, [3] X, [2] W, [1] R
  } tlb_entry_t;

  tlb_entry_t itlb [16];
  tlb_entry_t dtlb [16];
  logic [3:0] itlb_alloc_ptr;
  logic [3:0] dtlb_alloc_ptr;

  // ---------------------------------------------------------------------------
  // TLB Hit & Permission Logic (Combinational)
  // ---------------------------------------------------------------------------
  logic lsu_tlb_hit;
  logic [3:0] lsu_hit_idx;
  tlb_entry_t lsu_hit_entry;
  
  always_comb begin
    lsu_tlb_hit = 1'b0;
    lsu_hit_idx = 4'd0;
    for (int i = 15; i >= 0; i--) begin
      if (dtlb[i].valid && (dtlb[i].G || dtlb[i].asid == asid_i)) begin
        logic match = 1'b0;
        if (dtlb[i].level == 2) match = (dtlb[i].vpn[26:18] == lsu_vaddr_i[38:30]);
        else if (dtlb[i].level == 1) match = (dtlb[i].vpn[26:9] == lsu_vaddr_i[38:21]);
        else match = (dtlb[i].vpn == lsu_vaddr_i[38:12]);
        
        if (match) begin
          lsu_tlb_hit = 1'b1;
          lsu_hit_idx = i[3:0];
        end
      end
    end
  end
  assign lsu_hit_entry = dtlb[lsu_hit_idx];

  logic lsu_perm_fault;
  logic [63:0] lsu_perm_cause;
  always_comb begin
    lsu_perm_fault = 1'b0;
    lsu_perm_cause = 64'd0;
    
    logic R = lsu_hit_entry.pte_perms[1];
    logic W = lsu_hit_entry.pte_perms[2];
    logic X = lsu_hit_entry.pte_perms[3];
    logic U = lsu_hit_entry.pte_perms[4];
    logic A = lsu_hit_entry.pte_perms[5];
    logic D = lsu_hit_entry.pte_perms[6];
    
    if (!A) lsu_perm_fault = 1'b1;
    if (lsu_is_store_i && !D) lsu_perm_fault = 1'b1;
    
    if (ld_st_priv_lvl_i == 2'b00 && !U) lsu_perm_fault = 1'b1;
    if (ld_st_priv_lvl_i == 2'b01 && U && !sum_i) lsu_perm_fault = 1'b1;
    
    if (lsu_is_store_i) begin
      if (!W) lsu_perm_fault = 1'b1;
    end else begin
      if (!(R || (mxr_i && X))) lsu_perm_fault = 1'b1;
    end
    
    if (lsu_perm_fault) lsu_perm_cause = lsu_is_store_i ? 64'd15 : 64'd13;
  end

  logic [55:0] lsu_tlb_pa;
  always_comb begin
    if (lsu_hit_entry.level == 2) lsu_tlb_pa = {lsu_hit_entry.ppn[43:18], lsu_vaddr_i[29:0]};
    else if (lsu_hit_entry.level == 1) lsu_tlb_pa = {lsu_hit_entry.ppn[43:9], lsu_vaddr_i[20:0]};
    else lsu_tlb_pa = {lsu_hit_entry.ppn[43:0], lsu_vaddr_i[11:0]};
  end

  // Fetch TLB Logic
  logic fetch_tlb_hit;
  logic [3:0] fetch_hit_idx;
  tlb_entry_t fetch_hit_entry;
  
  always_comb begin
    fetch_tlb_hit = 1'b0;
    fetch_hit_idx = 4'd0;
    for (int i = 15; i >= 0; i--) begin
      if (itlb[i].valid && (itlb[i].G || itlb[i].asid == asid_i)) begin
        logic match = 1'b0;
        if (itlb[i].level == 2) match = (itlb[i].vpn[26:18] == fetch_vaddr_i[38:30]);
        else if (itlb[i].level == 1) match = (itlb[i].vpn[26:9] == fetch_vaddr_i[38:21]);
        else match = (itlb[i].vpn == fetch_vaddr_i[38:12]);
        
        if (match) begin
          fetch_tlb_hit = 1'b1;
          fetch_hit_idx = i[3:0];
        end
      end
    end
  end
  assign fetch_hit_entry = itlb[fetch_hit_idx];

  logic fetch_perm_fault;
  always_comb begin
    fetch_perm_fault = 1'b0;
    logic X = fetch_hit_entry.pte_perms[3];
    logic U = fetch_hit_entry.pte_perms[4];
    logic A = fetch_hit_entry.pte_perms[5];
    
    if (!A) fetch_perm_fault = 1'b1;
    if (priv_lvl_i == 2'b00 && !U) fetch_perm_fault = 1'b1;
    if (priv_lvl_i == 2'b01 && U) fetch_perm_fault = 1'b1;
    if (!X) fetch_perm_fault = 1'b1;
  end

  logic [55:0] fetch_tlb_pa;
  always_comb begin
    if (fetch_hit_entry.level == 2) fetch_tlb_pa = {fetch_hit_entry.ppn[43:18], fetch_vaddr_i[29:0]};
    else if (fetch_hit_entry.level == 1) fetch_tlb_pa = {fetch_hit_entry.ppn[43:9], fetch_vaddr_i[20:0]};
    else fetch_tlb_pa = {fetch_hit_entry.ppn[43:0], fetch_vaddr_i[11:0]};
  end

  // ---------------------------------------------------------------------------
  // Page Table Walker & Round-Robin Arbitration
  // ---------------------------------------------------------------------------
  logic lsu_wants_walk;
  logic fetch_wants_walk;
  assign lsu_wants_walk = lsu_req_i && !lsu_bare && !lsu_tlb_hit;
  assign fetch_wants_walk = fetch_req_i && !fetch_bare && !fetch_tlb_hit;

  logic arb_last_was_lsu;
  logic walk_start;
  logic walk_req_is_lsu;
  logic [38:0] walk_va;

  always_comb begin
    walk_start = 1'b0;
    walk_req_is_lsu = 1'b0;
    walk_va = 39'd0;
    
    if (arb_last_was_lsu) begin
      if (fetch_wants_walk) begin
        walk_start = 1'b1; walk_req_is_lsu = 1'b0; walk_va = fetch_vaddr_i[38:0];
      end else if (lsu_wants_walk) begin
        walk_start = 1'b1; walk_req_is_lsu = 1'b1; walk_va = lsu_vaddr_i[38:0];
      end
    end else begin
      if (lsu_wants_walk) begin
        walk_start = 1'b1; walk_req_is_lsu = 1'b1; walk_va = lsu_vaddr_i[38:0];
      end else if (fetch_wants_walk) begin
        walk_start = 1'b1; walk_req_is_lsu = 1'b0; walk_va = fetch_vaddr_i[38:0];
      end
    end
  end

  typedef enum logic [1:0] { W_IDLE, W_REQ, W_WAIT, W_EVAL } walk_state_t;
  walk_state_t w_state;
  logic walk_done_q;

  logic [1:0] outstanding_reads;
  always_ff @(posedge clk_i) begin
    if (!rst_ni) outstanding_reads <= 2'd0;
    else outstanding_reads <= outstanding_reads + (mem_req_o && mem_gnt_i) - mem_rvalid_i;
  end

  logic walker_idle;
  assign walker_idle = (w_state == W_IDLE) && !walk_done_q && (outstanding_reads == 2'd0);

  always_ff @(posedge clk_i) begin
    if (!rst_ni) arb_last_was_lsu <= 1'b0;
    else if (walker_idle && walk_start) arb_last_was_lsu <= walk_req_is_lsu;
  end

  logic active_is_lsu, active_is_store;
  logic [38:0] active_va;
  logic [1:0] walk_level;
  logic [43:0] walk_ppn;

  always_ff @(posedge clk_i) begin
    if (!rst_ni) begin
      active_is_lsu <= 1'b0;
      active_va <= 39'd0;
      active_is_store <= 1'b0;
    end else if (walker_idle && walk_start) begin
      active_is_lsu <= walk_req_is_lsu;
      active_va <= walk_va;
      active_is_store <= walk_req_is_lsu ? lsu_is_store_i : 1'b0;
    end
  end

  logic [55:0] walk_pa;
  always_comb begin
    logic [8:0] vpn_part;
    if (walk_level == 2) vpn_part = active_va[38:30];
    else if (walk_level == 1) vpn_part = active_va[29:21];
    else vpn_part = active_va[20:12];
    walk_pa = {walk_ppn, vpn_part, 3'b000};
  end

  // PMP Evaluator for walk_pa (8-byte read check)
  logic pmp_deny_combo;
  logic pmp_allow;
  assign pmp_deny_combo = !pmp_allow;

  always_comb begin
    logic [53:0] pa_word = walk_pa[55:2];
    logic [54:0] p_start = {1'b0, pa_word};
    logic [54:0] p_end   = {1'b0, pa_word} + 55'd1;
    
    logic [7:0] m_start = 8'd0;
    logic [7:0] m_end = 8'd0;

    for (int i = 0; i < 8; i++) begin
      logic [53:0] prev = (i == 0) ? 54'd0 : pmpaddr_i[i-1];
      logic [54:0] prev_ext = {1'b0, prev};
      logic [54:0] curr_ext = {1'b0, pmpaddr_i[i]};
      logic [1:0] A = pmpcfg_i[i][4:3];
      
      if (A == 2'b01) begin // TOR
        m_start[i] = (p_start >= prev_ext) && (p_start < curr_ext);
        m_end[i]   = (p_end >= prev_ext) && (p_end < curr_ext);
      end else if (A == 2'b10) begin // NA4
        m_start[i] = (p_start[53:0] == pmpaddr_i[i]);
        m_end[i]   = (p_end[53:0] == pmpaddr_i[i]);
      end else if (A == 2'b11) begin // NAPOT
        logic [53:0] mask = pmpaddr_i[i] ^ (pmpaddr_i[i] + 54'd1);
        logic [53:0] base = pmpaddr_i[i] & ~mask;
        m_start[i] = ((p_start[53:0] & ~mask) == base);
        m_end[i]   = ((p_end[53:0] & ~mask) == base);
      end
    end

    automatic logic [3:0] hit_start = 4'd8;
    automatic logic [3:0] hit_end = 4'd8;
    for (int i = 7; i >= 0; i--) begin
      if (m_start[i]) hit_start = i[3:0];
      if (m_end[i]) hit_end = i[3:0];
    end
    
    if (hit_start == hit_end && hit_start < 4'd8) begin
      pmp_allow = pmpcfg_i[hit_start[2:0]][0];
    end else begin
      pmp_allow = 1'b0;
    end
  end

  assign mem_req_o = (w_state == W_REQ) && !pmp_deny_combo;
  assign mem_addr_o = walk_pa;

  logic walk_fault_q;
  logic [63:0] walk_cause_q;
  logic [63:0] walk_pte_q;
  logic [1:0] walk_level_q;
  logic [63:0] pte_q;

  always_ff @(posedge clk_i) begin
    if (!rst_ni) begin
      w_state <= W_IDLE;
      walk_done_q <= 1'b0;
    end else if (flush_i) begin
      w_state <= W_IDLE;
      walk_done_q <= 1'b0;
    end else begin
      walk_done_q <= 1'b0;
      case (w_state)
        W_IDLE: begin
          if (walker_idle && walk_start) begin
            w_state <= W_REQ;
            walk_level <= 2'd2;
            walk_ppn <= satp_ppn_i;
          end
        end
        W_REQ: begin
          if (pmp_deny_combo) begin
            walk_done_q <= 1'b1;
            walk_fault_q <= 1'b1;
            walk_cause_q <= active_is_lsu ? (active_is_store ? 64'd7 : 64'd5) : 64'd1;
            w_state <= W_IDLE;
          end else if (mem_gnt_i) begin
            w_state <= W_WAIT;
          end
        end
        W_WAIT: begin
          if (mem_rvalid_i) begin
            pte_q <= mem_rdata_i;
            w_state <= W_EVAL;
          end
        end
        W_EVAL: begin
          if (!pte_q[0] || (!pte_q[1] && pte_q[2])) begin
            walk_done_q <= 1'b1; walk_fault_q <= 1'b1;
            walk_cause_q <= active_is_lsu ? (active_is_store ? 64'd15 : 64'd13) : 64'd12;
            w_state <= W_IDLE;
          end else if (pte_q[1] || pte_q[3]) begin // Leaf found
            logic misaligned = (walk_level == 2'd2 && pte_q[27:10] != 18'd0) || 
                               (walk_level == 2'd1 && pte_q[18:10] != 9'd0);
            if (misaligned) begin
              walk_done_q <= 1'b1; walk_fault_q <= 1'b1;
              walk_cause_q <= active_is_lsu ? (active_is_store ? 64'd15 : 64'd13) : 64'd12;
              w_state <= W_IDLE;
            end else begin
              logic R = pte_q[1]; logic W = pte_q[2]; logic X = pte_q[3];
              logic U = pte_q[4]; logic A = pte_q[6]; logic D = pte_q[7];
              logic perm_fault = 1'b0;
              
              if (!A) perm_fault = 1'b1;
              if (active_is_lsu) begin
                if (active_is_store && !D) perm_fault = 1'b1;
                if (ld_st_priv_lvl_i == 2'b00 && !U) perm_fault = 1'b1;
                if (ld_st_priv_lvl_i == 2'b01 && U && !sum_i) perm_fault = 1'b1;
                if (active_is_store) begin
                  if (!W) perm_fault = 1'b1;
                end else begin
                  if (!(R || (mxr_i && X))) perm_fault = 1'b1;
                end
              end else begin
                if (priv_lvl_i == 2'b00 && !U) perm_fault = 1'b1;
                if (priv_lvl_i == 2'b01 && U) perm_fault = 1'b1;
                if (!X) perm_fault = 1'b1;
              end
              
              if (perm_fault) begin
                walk_done_q <= 1'b1; walk_fault_q <= 1'b1;
                walk_cause_q <= active_is_lsu ? (active_is_store ? 64'd15 : 64'd13) : 64'd12;
                w_state <= W_IDLE;
              end else begin
                walk_done_q <= 1'b1; walk_fault_q <= 1'b0;
                walk_pte_q <= pte_q; walk_level_q <= walk_level;
                w_state <= W_IDLE;
              end
            end
          end else begin
            if (walk_level == 2'd0) begin
              walk_done_q <= 1'b1; walk_fault_q <= 1'b1;
              walk_cause_q <= active_is_lsu ? (active_is_store ? 64'd15 : 64'd13) : 64'd12;
              w_state <= W_IDLE;
            end else begin
              walk_ppn <= pte_q[53:10];
              walk_level <= walk_level - 2'd1;
              w_state <= W_REQ;
            end
          end
        end
      endcase
    end
  end

  // ---------------------------------------------------------------------------
  // TLB Writing and Retirement Handshake
  // ---------------------------------------------------------------------------
  always_ff @(posedge clk_i) begin
    if (!rst_ni) begin
      for (int i = 0; i < 16; i++) begin
        itlb[i].valid <= 1'b0;
        dtlb[i].valid <= 1'b0;
      end
      itlb_alloc_ptr <= 4'd0;
      dtlb_alloc_ptr <= 4'd0;
    end else if (flush_tlb_i) begin
      for (int i = 0; i < 16; i++) begin
        itlb[i].valid <= 1'b0;
        dtlb[i].valid <= 1'b0;
      end
    end else if (walk_done_q && !walk_fault_q) begin
      if (active_is_lsu) begin
        dtlb[dtlb_alloc_ptr].valid <= 1'b1;
        dtlb[dtlb_alloc_ptr].level <= walk_level_q;
        dtlb[dtlb_alloc_ptr].vpn <= active_va[38:12];
        dtlb[dtlb_alloc_ptr].asid <= asid_i;
        dtlb[dtlb_alloc_ptr].G <= walk_pte_q[5];
        dtlb[dtlb_alloc_ptr].ppn <= walk_pte_q[53:10];
        dtlb[dtlb_alloc_ptr].pte_perms <= {walk_pte_q[7], walk_pte_q[6], walk_pte_q[4:1]};
        dtlb_alloc_ptr <= dtlb_alloc_ptr + 4'd1;
      end else begin
        itlb[itlb_alloc_ptr].valid <= 1'b1;
        itlb[itlb_alloc_ptr].level <= walk_level_q;
        itlb[itlb_alloc_ptr].vpn <= active_va[38:12];
        itlb[itlb_alloc_ptr].asid <= asid_i;
        itlb[itlb_alloc_ptr].G <= walk_pte_q[5];
        itlb[itlb_alloc_ptr].ppn <= walk_pte_q[53:10];
        itlb[itlb_alloc_ptr].pte_perms <= {walk_pte_q[7], walk_pte_q[6], walk_pte_q[4:1]};
        itlb_alloc_ptr <= itlb_alloc_ptr + 4'd1;
      end
    end
  end

  logic lsu_retire_tlb, lsu_retire_walk_fault;
  logic fetch_retire_tlb, fetch_retire_walk_fault;

  assign lsu_retire_tlb = lsu_req_i && !lsu_bare && lsu_tlb_hit;
  assign fetch_retire_tlb = fetch_req_i && !fetch_bare && fetch_tlb_hit;

  assign lsu_retire_walk_fault = walk_done_q && walk_fault_q && active_is_lsu;
  assign fetch_retire_walk_fault = walk_done_q && walk_fault_q && !active_is_lsu;

  assign lsu_valid_o = lsu_bare ? lsu_req_i : (lsu_retire_tlb || lsu_retire_walk_fault);
  assign lsu_exc_valid_o = lsu_bare ? 1'b0 : (lsu_retire_tlb ? lsu_perm_fault : lsu_retire_walk_fault);
  assign lsu_exc_cause_o = lsu_retire_walk_fault ? walk_cause_q : lsu_perm_cause;
  assign lsu_paddr_o = lsu_bare ? lsu_vaddr_i[55:0] : (lsu_retire_tlb ? lsu_tlb_pa : 56'd0);
  assign lsu_dtlb_hit_o = lsu_tlb_hit;
  assign lsu_dtlb_ppn_o = lsu_hit_entry.ppn;
  assign dtlb_miss_o = lsu_wants_walk;

  assign fetch_valid_o = fetch_bare ? fetch_req_i : (fetch_retire_tlb || fetch_retire_walk_fault);
  assign fetch_exc_valid_o = fetch_bare ? 1'b0 : (fetch_retire_tlb ? fetch_perm_fault : fetch_retire_walk_fault);
  assign fetch_exc_cause_o = fetch_retire_walk_fault ? walk_cause_q : (fetch_perm_fault ? 64'd12 : 64'd0);
  assign fetch_paddr_o = fetch_bare ? fetch_vaddr_i[55:0] : (fetch_retire_tlb ? fetch_tlb_pa : 56'd0);
  assign itlb_miss_o = fetch_wants_walk;

endmodule