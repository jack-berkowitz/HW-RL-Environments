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

  typedef struct packed {
    logic        valid;
    logic        global;
    logic [15:0] asid;
    logic [26:0] vpn;
    logic [43:0] ppn;
    logic [1:0]  level;
    logic        r;
    logic        w;
    logic        x;
    logic        u;
    logic        d;
  } tlb_entry_t;

  tlb_entry_t itlb [0:15];
  tlb_entry_t dtlb [0:15];

  logic [3:0] itlb_ptr, dtlb_ptr;
  logic [3:0] itlb_victim, dtlb_victim;
  logic       itlb_victim_found, dtlb_victim_found;

  logic [15:0] itlb_match, dtlb_match;
  logic        itlb_hit_any, dtlb_hit_any;
  logic        itlb_sel_found, dtlb_sel_found;
  tlb_entry_t  itlb_sel, dtlb_sel;
  logic [55:0] itlb_pa, dtlb_pa;
  logic        itlb_priv_ok, dtlb_priv_ok;
  logic        itlb_perm_ok, dtlb_perm_ok;

  logic        fetch_need_walk, lsu_need_walk;

  typedef enum logic [1:0] {
    S_IDLE,
    S_MEM_REQ,
    S_MEM_WAIT,
    S_RESPOND
  } state_t;

  state_t state;

  logic        walk_fetch;
  logic        walk_is_store;
  logic [63:0] walk_va;
  logic [1:0]  walk_priv;
  logic        walk_sum;
  logic        walk_mxr;
  logic [15:0] walk_asid;
  logic [1:0]  walk_level;
  logic [55:0] walk_addr;

  logic        resp_success;
  logic [55:0] resp_paddr;
  logic [63:0] resp_cause;

  logic        pte_bad;
  logic        pte_leaf;
  logic        pte_misaligned;
  logic        walk_priv_ok;
  logic        walk_perm_ok;
  logic        walk_success;
  logic [55:0] walk_leaf_pa;
  logic [63:0] walk_page_cause;
  logic [63:0] walk_access_cause;
  logic        tlb_install;

  logic [7:0][53:0] pmp_napot_mask;
  logic [7:0][55:0] pmp_tor_low;
  logic [7:0][55:0] pmp_tor_high;
  logic [7:0]       pmp_match;
  logic             pmp_seen;
  logic             pmp_allow;

  /* Fully associative TLB lookups and permission checks. */
  always_comb begin
    for (int i = 0; i < 16; i++) begin
      dtlb_match[i] = dtlb[i].valid &&
                      (dtlb[i].global || (dtlb[i].asid == asid_i)) &&
                      (((dtlb[i].level == 2'd0) &&
                        (dtlb[i].vpn == lsu_vaddr_i[38:12])) ||
                       ((dtlb[i].level == 2'd1) &&
                        (dtlb[i].vpn[26:9] == lsu_vaddr_i[38:21])) ||
                       ((dtlb[i].level == 2'd2) &&
                        (dtlb[i].vpn[26:18] == lsu_vaddr_i[38:30])));

      itlb_match[i] = itlb[i].valid &&
                      (itlb[i].global || (itlb[i].asid == asid_i)) &&
                      (((itlb[i].level == 2'd0) &&
                        (itlb[i].vpn == fetch_vaddr_i[38:12])) ||
                       ((itlb[i].level == 2'd1) &&
                        (itlb[i].vpn[26:9] == fetch_vaddr_i[38:21])) ||
                       ((itlb[i].level == 2'd2) &&
                        (itlb[i].vpn[26:18] == fetch_vaddr_i[38:30])));
    end

    dtlb_hit_any = |dtlb_match;
    itlb_hit_any = |itlb_match;

    dtlb_sel       = '0;
    itlb_sel       = '0;
    dtlb_sel_found = 1'b0;
    itlb_sel_found = 1'b0;

    for (int i = 0; i < 16; i++) begin
      if (dtlb_match[i] && !dtlb_sel_found) begin
        dtlb_sel       = dtlb[i];
        dtlb_sel_found = 1'b1;
      end
      if (itlb_match[i] && !itlb_sel_found) begin
        itlb_sel       = itlb[i];
        itlb_sel_found = 1'b1;
      end
    end

    dtlb_pa = {dtlb_sel.ppn, lsu_vaddr_i[11:0]};
    case (dtlb_sel.level)
      2'd1: dtlb_pa = {dtlb_sel.ppn[43:9],
                       lsu_vaddr_i[20:12], lsu_vaddr_i[11:0]};
      2'd2: dtlb_pa = {dtlb_sel.ppn[43:18],
                       lsu_vaddr_i[29:12], lsu_vaddr_i[11:0]};
      default: ;
    endcase

    itlb_pa = {itlb_sel.ppn, fetch_vaddr_i[11:0]};
    case (itlb_sel.level)
      2'd1: itlb_pa = {itlb_sel.ppn[43:9],
                       fetch_vaddr_i[20:12], fetch_vaddr_i[11:0]};
      2'd2: itlb_pa = {itlb_sel.ppn[43:18],
                       fetch_vaddr_i[29:12], fetch_vaddr_i[11:0]};
      default: ;
    endcase

    dtlb_priv_ok = 1'b1;
    if (ld_st_priv_lvl_i == 2'b00)
      dtlb_priv_ok = dtlb_sel.u;
    else if ((ld_st_priv_lvl_i == 2'b01) && dtlb_sel.u)
      dtlb_priv_ok = sum_i;

    if (lsu_is_store_i)
      dtlb_perm_ok = dtlb_priv_ok && dtlb_sel.w && dtlb_sel.d;
    else
      dtlb_perm_ok = dtlb_priv_ok &&
                     (dtlb_sel.r || (dtlb_sel.x && mxr_i));

    itlb_priv_ok = 1'b1;
    if (priv_lvl_i == 2'b00)
      itlb_priv_ok = itlb_sel.u;
    else if ((priv_lvl_i == 2'b01) && itlb_sel.u)
      itlb_priv_ok = 1'b0;

    itlb_perm_ok = itlb_priv_ok && itlb_sel.x;
  end

  assign lsu_dtlb_hit_o = dtlb_hit_any;
  assign lsu_dtlb_ppn_o = dtlb_sel.ppn;
  assign dtlb_miss_o = lsu_req_i && en_ld_st_translation_i && !dtlb_hit_any;
  assign itlb_miss_o = fetch_req_i && enable_translation_i && !itlb_hit_any;

  assign lsu_need_walk = lsu_req_i && en_ld_st_translation_i &&
                         (!dtlb_hit_any || flush_tlb_i);
  assign fetch_need_walk = fetch_req_i && enable_translation_i &&
                           (!itlb_hit_any || flush_tlb_i);

  /* Prefer invalid entries, then use round-robin replacement. */
  always_comb begin
    dtlb_victim       = dtlb_ptr;
    itlb_victim       = itlb_ptr;
    dtlb_victim_found = 1'b0;
    itlb_victim_found = 1'b0;

    for (int i = 0; i < 16; i++) begin
      if (!dtlb[i].valid && !dtlb_victim_found) begin
        dtlb_victim       = i[3:0];
        dtlb_victim_found = 1'b1;
      end
      if (!itlb[i].valid && !itlb_victim_found) begin
        itlb_victim       = i[3:0];
        itlb_victim_found = 1'b1;
      end
    end
  end

  /* PMP check for the walker's current eight-byte read. */
  always_comb begin
    for (int i = 0; i < 8; i++) begin
      pmp_napot_mask[i][0] = 1'b1;
      for (int j = 1; j < 54; j++)
        pmp_napot_mask[i][j] = pmp_napot_mask[i][j-1] &&
                               pmpaddr_i[i][j-1];

      pmp_tor_high[i] = {pmpaddr_i[i], 2'b00};
      if (i == 0)
        pmp_tor_low[i] = 56'b0;
      else
        pmp_tor_low[i] = {pmpaddr_i[i-1], 2'b00};

      pmp_match[i] = 1'b0;
      case (pmpcfg_i[i][4:3])
        2'd1: pmp_match[i] =
                (walk_addr >= pmp_tor_low[i]) &&
                (({1'b0, walk_addr} + 57'd7) <
                 {1'b0, pmp_tor_high[i]});

        /* An aligned eight-byte read cannot fit in a four-byte region. */
        2'd2: pmp_match[i] = 1'b0;

        2'd3: pmp_match[i] =
                ((pmpaddr_i[i] & ~pmp_napot_mask[i]) ==
                 (walk_addr[55:2] & ~pmp_napot_mask[i]));

        default: pmp_match[i] = 1'b0;
      endcase
    end

    /* Lowest-numbered matching entry wins; no match denies. */
    pmp_allow = 1'b0;
    pmp_seen  = 1'b0;
    for (int i = 0; i < 8; i++) begin
      if (pmp_match[i] && !pmp_seen) begin
        pmp_allow = pmpcfg_i[i][0];
        pmp_seen  = 1'b1;
      end
    end
  end

  assign mem_addr_o      = walk_addr;
  assign mem_req_o       = rst_ni && !flush_i &&
                           (state == S_MEM_REQ) && pmp_allow;
  assign mem_tag_valid_o = 1'b0;
  assign mem_kill_o      = flush_i &&
                           ((state == S_MEM_REQ) || (state == S_MEM_WAIT));

  /* Leaf decoding, permission checking, and physical-address formation. */
  always_comb begin
    pte_bad  = !mem_rdata[0] || (mem_rdata[2] && !mem_rdata[1]);
    pte_leaf = mem_rdata[1] || mem_rdata[3];

    pte_misaligned = 1'b0;
    if ((walk_level == 2'd1) && (mem_rdata[18:10] != 9'b0))
      pte_misaligned = 1'b1;
    if ((walk_level == 2'd2) && (mem_rdata[27:10] != 18'b0))
      pte_misaligned = 1'b1;

    walk_priv_ok = 1'b1;
    if (walk_priv == 2'b00)
      walk_priv_ok = mem_rdata[4];
    else if ((walk_priv == 2'b01) && mem_rdata[4]) begin
      if (walk_fetch)
        walk_priv_ok = 1'b0;
      else
        walk_priv_ok = walk_sum;
    end

    if (walk_fetch)
      walk_perm_ok = walk_priv_ok && mem_rdata[3] && mem_rdata[6];
    else if (walk_is_store)
      walk_perm_ok = walk_priv_ok && mem_rdata[2] &&
                     mem_rdata[6] && mem_rdata[7];
    else
      walk_perm_ok = walk_priv_ok &&
                     (mem_rdata[1] || (mem_rdata[3] && walk_mxr)) &&
                     mem_rdata[6];

    walk_success = !pte_bad && pte_leaf && !pte_misaligned && walk_perm_ok;

    walk_leaf_pa = {mem_rdata[53:10], walk_va[11:0]};
    case (walk_level)
      2'd1: walk_leaf_pa = {mem_rdata[53:19], walk_va[20:12],
                            walk_va[11:0]};
      2'd2: walk_leaf_pa = {mem_rdata[53:28], walk_va[29:12],
                            walk_va[11:0]};
      default: ;
    endcase

    if (walk_fetch)
      walk_page_cause = 64'd12;
    else if (walk_is_store)
      walk_page_cause = 64'd15;
    else
      walk_page_cause = 64'd13;

    if (walk_fetch)
      walk_access_cause = 64'd1;
    else if (walk_is_store)
      walk_access_cause = 64'd7;
    else
      walk_access_cause = 64'd5;
  end

  assign tlb_install = (state == S_MEM_WAIT) && mem_rvalid &&
                       walk_success && !flush_i && !flush_tlb_i;

  /* Walker sequencing. */
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      state         <= S_IDLE;
      walk_fetch    <= 1'b0;
      walk_is_store <= 1'b0;
      walk_va       <= 64'b0;
      walk_priv     <= 2'b0;
      walk_sum      <= 1'b0;
      walk_mxr      <= 1'b0;
      walk_asid     <= 16'b0;
      walk_level    <= 2'b0;
      walk_addr     <= 56'b0;
      resp_success  <= 1'b0;
      resp_paddr    <= 56'b0;
      resp_cause    <= 64'b0;
    end else if (flush_i) begin
      state <= S_IDLE;
    end else begin
      case (state)
        S_IDLE: begin
          /* Fetch has priority if both ports miss in the same cycle. */
          if (fetch_need_walk) begin
            walk_fetch    <= 1'b1;
            walk_is_store <= 1'b0;
            walk_va       <= fetch_vaddr_i;
            walk_priv     <= priv_lvl_i;
            walk_sum      <= sum_i;
            walk_mxr      <= mxr_i;
            walk_asid     <= asid_i;
            walk_level    <= 2'd2;
            walk_addr     <= {satp_ppn_i, 12'b0} +
                             {44'b0, fetch_vaddr_i[38:30], 3'b000};
            state         <= S_MEM_REQ;
          end else if (lsu_need_walk) begin
            walk_fetch    <= 1'b0;
            walk_is_store <= lsu_is_store_i;
            walk_va       <= lsu_vaddr_i;
            walk_priv     <= ld_st_priv_lvl_i;
            walk_sum      <= sum_i;
            walk_mxr      <= mxr_i;
            walk_asid     <= asid_i;
            walk_level    <= 2'd2;
            walk_addr     <= {satp_ppn_i, 12'b0} +
                             {44'b0, lsu_vaddr_i[38:30], 3'b000};
            state         <= S_MEM_REQ;
          end
        end

        S_MEM_REQ: begin
          if (!pmp_allow) begin
            resp_success <= 1'b0;
            resp_paddr   <= 56'b0;
            resp_cause   <= walk_access_cause;
            state        <= S_RESPOND;
          end else if (mem_gnt_i) begin
            state <= S_MEM_WAIT;
          end
        end

        S_MEM_WAIT: begin
          if (mem_rvalid) begin
            if (pte_bad) begin
              resp_success <= 1'b0;
              resp_paddr   <= 56'b0;
              resp_cause   <= walk_page_cause;
              state        <= S_RESPOND;
            end else if (pte_leaf) begin
              resp_paddr <= walk_leaf_pa;
              resp_cause <= walk_page_cause;
              if (walk_success) begin
                resp_success <= 1'b1;
                resp_cause   <= 64'b0;
              end else begin
                resp_success <= 1'b0;
                resp_paddr   <= 56'b0;
              end
              state <= S_RESPOND;
            end else if (walk_level == 2'd0) begin
              resp_success <= 1'b0;
              resp_paddr   <= 56'b0;
              resp_cause   <= walk_page_cause;
              state        <= S_RESPOND;
            end else begin
              if (walk_level == 2'd2)
                walk_addr <= {mem_rdata[53:10], 12'b0} +
                             {44'b0, walk_va[29:21], 3'b000};
              else
                walk_addr <= {mem_rdata[53:10], 12'b0} +
                             {44'b0, walk_va[20:12], 3'b000};
              walk_level <= walk_level - 2'd1;
              state      <= S_MEM_REQ;
            end
          end
        end

        default: state <= S_IDLE;
      endcase
    end
  end

  /* TLB installation and full-flush handling. */
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      itlb_ptr <= 4'b0;
      dtlb_ptr <= 4'b0;
      for (int i = 0; i < 16; i++) begin
        itlb[i].valid <= 1'b0;
        dtlb[i].valid <= 1'b0;
      end
    end else if (flush_tlb_i) begin
      itlb_ptr <= 4'b0;
      dtlb_ptr <= 4'b0;
      for (int i = 0; i < 16; i++) begin
        itlb[i].valid <= 1'b0;
        dtlb[i].valid <= 1'b0;
      end
    end else if (tlb_install) begin
      if (walk_fetch) begin
        itlb[itlb_victim].valid  <= 1'b1;
        itlb[itlb_victim].global <= mem_rdata[5];
        itlb[itlb_victim].asid   <= walk_asid;
        itlb[itlb_victim].vpn    <= walk_va[38:12];
        itlb[itlb_victim].ppn    <= mem_rdata[53:10];
        itlb[itlb_victim].level  <= walk_level;
        itlb[itlb_victim].r      <= mem_rdata[1];
        itlb[itlb_victim].w      <= mem_rdata[2];
        itlb[itlb_victim].x      <= mem_rdata[3];
        itlb[itlb_victim].u      <= mem_rdata[4];
        itlb[itlb_victim].d      <= mem_rdata[7];
        itlb_ptr                 <= itlb_victim + 4'd1;
      end else begin
        dtlb[dtlb_victim].valid  <= 1'b1;
        dtlb[dtlb_victim].global <= mem_rdata[5];
        dtlb[dtlb_victim].asid   <= walk_asid;
        dtlb[dtlb_victim].vpn    <= walk_va[38:12];
        dtlb[dtlb_victim].ppn    <= mem_rdata[53:10];
        dtlb[dtlb_victim].level  <= walk_level;
        dtlb[dtlb_victim].r      <= mem_rdata[1];
        dtlb[dtlb_victim].w      <= mem_rdata[2];
        dtlb[dtlb_victim].x      <= mem_rdata[3];
        dtlb[dtlb_victim].u      <= mem_rdata[4];
        dtlb[dtlb_victim].d      <= mem_rdata[7];
        dtlb_ptr                 <= dtlb_victim + 4'd1;
      end
    end
  end

  /* Bare-mode and TLB-hit responses, with walker responses taking priority. */
  always_comb begin
    lsu_valid_o      = 1'b0;
    lsu_paddr_o      = 56'b0;
    lsu_exc_valid_o  = 1'b0;
    lsu_exc_cause_o  = 64'b0;
    lsu_exc_tval_o   = 64'b0;

    fetch_valid_o     = 1'b0;
    fetch_paddr_o     = 56'b0;
    fetch_exc_valid_o = 1'b0;
    fetch_exc_cause_o = 64'b0;
    fetch_exc_tval_o  = 64'b0;

    if (rst_ni) begin
      if (lsu_req_i) begin
        if (!en_ld_st_translation_i) begin
          lsu_valid_o  = 1'b1;
          lsu_paddr_o  = lsu_vaddr_i[55:0];
        end else if (dtlb_hit_any && !flush_tlb_i) begin
          lsu_valid_o     = 1'b1;
          lsu_paddr_o     = dtlb_pa;
          lsu_exc_valid_o = !dtlb_perm_ok;
          if (!dtlb_perm_ok) begin
            lsu_exc_cause_o = lsu_is_store_i ? 64'd15 : 64'd13;
            lsu_exc_tval_o  = lsu_vaddr_i;
          end
        end
      end

      if (fetch_req_i) begin
        if (!enable_translation_i) begin
          fetch_valid_o = 1'b1;
          fetch_paddr_o = fetch_vaddr_i[55:0];
        end else if (itlb_hit_any && !flush_tlb_i) begin
          fetch_valid_o     = 1'b1;
          fetch_paddr_o     = itlb_pa;
          fetch_exc_valid_o = !itlb_perm_ok;
          if (!itlb_perm_ok) begin
            fetch_exc_cause_o = 64'd12;
            fetch_exc_tval_o  = fetch_vaddr_i;
          end
        end
      end

      if (state == S_RESPOND) begin
        if (walk_fetch) begin
          fetch_valid_o     = 1'b1;
          fetch_paddr_o     = resp_paddr;
          fetch_exc_valid_o = !resp_success;
          fetch_exc_cause_o = resp_cause;
          fetch_exc_tval_o  = resp_success ? 64'b0 : walk_va;
        end else begin
          lsu_valid_o      = 1'b1;
          lsu_paddr_o      = resp_paddr;
          lsu_exc_valid_o  = !resp_success;
          lsu_exc_cause_o  = resp_cause;
          lsu_exc_tval_o   = resp_success ? 64'b0 : walk_va;
        end
      end
    end
  end

  /* Narrowing inputs are intentionally unused: every flush is a full flush. */
  logic unused_flush_inputs;
  assign unused_flush_inputs = ^{asid_to_be_flushed_i,
                                vaddr_to_be_flushed_i};

endmodule
