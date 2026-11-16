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
    logic [15:0] gen;
    logic [15:0] asid;
    logic        g;
    logic [1:0]  level;
    logic [26:0] vpn;
    logic [43:0] ppn;
    logic        r;
    logic        w;
    logic        x;
    logic        u;
    logic        d;
  } tlb_entry_t;

  typedef enum logic [2:0] {
    W_IDLE,
    W_CALC,
    W_PMP_CHECK,
    W_MEM_REQ,
    W_MEM_WAIT,
    W_PROCESS
  } walk_state_t;

  tlb_entry_t itlb [0:15];
  tlb_entry_t dtlb [0:15];
  logic [15:0] tlb_gen;
  logic [3:0]  itlb_rr;
  logic [3:0]  dtlb_rr;

  logic        lsu_seen;
  logic        fetch_seen;
  logic        lsu_pending;
  logic        fetch_pending;

  logic [63:0] lsu_pend_va;
  logic        lsu_pend_is_store;
  logic [1:0]  lsu_pend_ld_st_priv;
  logic        lsu_pend_sum;
  logic        lsu_pend_mxr;
  logic [15:0] lsu_pend_asid;

  logic [63:0] fetch_pend_va;
  logic [1:0]  fetch_pend_priv;
  logic [15:0] fetch_pend_asid;

  logic        active_valid;
  logic        active_port;
  logic [63:0] active_va;
  logic        active_is_store;
  logic [1:0]  active_priv;
  logic [1:0]  active_ld_st_priv;
  logic        active_sum;
  logic        active_mxr;
  logic [15:0] active_asid;

  walk_state_t walk_state;
  logic [1:0]  walk_level;
  logic [55:0] walk_a;
  logic [55:0] walk_addr;
  logic [63:0] walk_pte;

  logic        lsu_hit;
  tlb_entry_t  lsu_hit_entry;
  logic [55:0] lsu_hit_pa;
  logic        lsu_hit_perm_fault;

  logic        fetch_hit;
  tlb_entry_t  fetch_hit_entry;
  logic [55:0] fetch_hit_pa;
  logic        fetch_hit_perm_fault;

  function automatic logic perm_fault(
    input logic is_fetch,
    input logic is_store,
    input logic [1:0] priv,
    input logic sum,
    input logic mxr,
    input logic r,
    input logic w,
    input logic x,
    input logic u,
    input logic a,
    input logic d
  );
    logic fault;
    begin
      fault = 1'b0;

      if (!a) fault = 1'b1;
      if (is_store && !d) fault = 1'b1;

      if (is_fetch) begin
        if (!x) fault = 1'b1;
        if (priv == 2'b00 && !u) fault = 1'b1;
        if (priv == 2'b01 && u) fault = 1'b1;
      end else begin
        if (is_store) begin
          if (!w) fault = 1'b1;
        end else begin
          if (!(r || (mxr && x))) fault = 1'b1;
        end

        if (priv == 2'b00 && !u) fault = 1'b1;
        if (priv == 2'b01 && u && !sum) fault = 1'b1;
      end

      perm_fault = fault;
    end
  endfunction

  function automatic logic [55:0] compute_pa(
    input tlb_entry_t e,
    input logic [63:0] va
  );
    logic [55:0] pa;
    begin
      case (e.level)
        2'd0: pa = {e.ppn, va[11:0]};
        2'd1: pa = {e.ppn[43:9], va[20:12], va[11:0]};
        2'd2: pa = {e.ppn[43:18], va[29:12], va[11:0]};
        default: pa = 56'd0;
      endcase
      compute_pa = pa;
    end
  endfunction

  always_comb begin
    logic [26:0] vpn;
    logic        match;

    lsu_hit = 1'b0;
    lsu_hit_entry = '0;
    vpn = {lsu_vaddr_i[38:30], lsu_vaddr_i[29:21], lsu_vaddr_i[20:12]};

    for (int i = 0; i < 16; i++) begin
      match = 1'b0;
      if (dtlb[i].valid && dtlb[i].gen == tlb_gen &&
          (dtlb[i].g || dtlb[i].asid == asid_i)) begin
        case (dtlb[i].level)
          2'd0: match = (dtlb[i].vpn == vpn);
          2'd1: match = (dtlb[i].vpn[26:9] == vpn[26:9]);
          2'd2: match = (dtlb[i].vpn[26:18] == vpn[26:18]);
          default: match = 1'b0;
        endcase
      end

      if (match && !lsu_hit) begin
        lsu_hit = 1'b1;
        lsu_hit_entry = dtlb[i];
      end
    end

    lsu_hit_pa = compute_pa(lsu_hit_entry, lsu_vaddr_i);
    lsu_hit_perm_fault = perm_fault(
      1'b0, lsu_is_store_i, ld_st_priv_lvl_i, sum_i, mxr_i,
      lsu_hit_entry.r, lsu_hit_entry.w, lsu_hit_entry.x,
      lsu_hit_entry.u, 1'b1, lsu_hit_entry.d
    );
  end

  always_comb begin
    logic [26:0] vpn;
    logic        match;

    fetch_hit = 1'b0;
    fetch_hit_entry = '0;
    vpn = {fetch_vaddr_i[38:30], fetch_vaddr_i[29:21], fetch_vaddr_i[20:12]};

    for (int i = 0; i < 16; i++) begin
      match = 1'b0;
      if (itlb[i].valid && itlb[i].gen == tlb_gen &&
          (itlb[i].g || itlb[i].asid == asid_i)) begin
        case (itlb[i].level)
          2'd0: match = (itlb[i].vpn == vpn);
          2'd1: match = (itlb[i].vpn[26:9] == vpn[26:9]);
          2'd2: match = (itlb[i].vpn[26:18] == vpn[26:18]);
          default: match = 1'b0;
        endcase
      end

      if (match && !fetch_hit) begin
        fetch_hit = 1'b1;
        fetch_hit_entry = itlb[i];
      end
    end

    fetch_hit_pa = compute_pa(fetch_hit_entry, fetch_vaddr_i);
    fetch_hit_perm_fault = perm_fault(
      1'b1, 1'b0, priv_lvl_i, sum_i, mxr_i,
      fetch_hit_entry.r, fetch_hit_entry.w, fetch_hit_entry.x,
      fetch_hit_entry.u, 1'b1, fetch_hit_entry.d
    );
  end

  assign mem_req_o       = rst_ni && (walk_state == W_MEM_REQ) && !flush_i;
  assign mem_addr_o      = walk_addr;
  assign mem_tag_valid_o = 1'b0;
  assign mem_kill_o      = rst_ni && flush_i && active_valid;

  always_ff @(posedge clk_i) begin
    logic        started;
    logic        started_port;
    logic        walker_busy_next;
    logic [3:0]  victim;
    logic        found;
    logic [55:0] pa;
    logic        fault;
    logic [63:0] cause;
    logic [8:0]  vpn_cur;
    logic [1:0]  mode;
    logic [55:0] tor_low;
    logic [55:0] tor_high;
    logic [53:0] napot_mask;
    logic [5:0]  trailing_ones;
    logic        still_ones;
    logic [55:0] addr;
    logic        pmp_matched;
    logic        pmp_allow;
    logic        pmp_ok;
    logic [63:0] new_pte;
    logic [43:0] new_ppn;
    logic [1:0]  new_level;
    logic [26:0] new_vpn;
    tlb_entry_t  new_entry;

    lsu_valid_o       <= 1'b0;
    lsu_exc_valid_o   <= 1'b0;
    lsu_exc_cause_o   <= 64'd0;
    lsu_exc_tval_o    <= 64'd0;
    lsu_paddr_o       <= 56'd0;
    lsu_dtlb_hit_o    <= 1'b0;
    lsu_dtlb_ppn_o    <= 44'd0;

    fetch_valid_o     <= 1'b0;
    fetch_exc_valid_o <= 1'b0;
    fetch_exc_cause_o <= 64'd0;
    fetch_exc_tval_o  <= 64'd0;
    fetch_paddr_o     <= 56'd0;

    itlb_miss_o       <= 1'b0;
    dtlb_miss_o       <= 1'b0;

    if (!rst_ni) begin
      tlb_gen  <= 16'd0;
      itlb_rr  <= 4'd0;
      dtlb_rr  <= 4'd0;

      for (int i = 0; i < 16; i++) begin
        itlb[i] <= '0;
        dtlb[i] <= '0;
      end

      lsu_seen      <= 1'b0;
      fetch_seen    <= 1'b0;
      lsu_pending   <= 1'b0;
      fetch_pending <= 1'b0;

      active_valid     <= 1'b0;
      active_port      <= 1'b0;
      walk_state       <= W_IDLE;
      walk_level       <= 2'd0;
      walk_a           <= 56'd0;
      walk_addr        <= 56'd0;
      walk_pte         <= 64'd0;

      lsu_pend_va        <= 64'd0;
      lsu_pend_is_store  <= 1'b0;
      lsu_pend_ld_st_priv<= 2'd0;
      lsu_pend_sum       <= 1'b0;
      lsu_pend_mxr       <= 1'b0;
      lsu_pend_asid      <= 16'd0;

      fetch_pend_va      <= 64'd0;
      fetch_pend_priv    <= 2'd0;
      fetch_pend_asid    <= 16'd0;

      active_va          <= 64'd0;
      active_is_store    <= 1'b0;
      active_priv        <= 2'd0;
      active_ld_st_priv  <= 2'd0;
      active_sum         <= 1'b0;
      active_mxr         <= 1'b0;
      active_asid        <= 16'd0;
    end else begin
      if (flush_tlb_i) begin
        tlb_gen <= tlb_gen + 16'd1;
      end

      if (!lsu_req_i)   lsu_seen   <= 1'b0;
      if (!fetch_req_i) fetch_seen <= 1'b0;

      if (flush_i && active_valid) begin
        walk_state <= W_CALC;
        walk_level <= 2'd2;
        walk_a     <= {satp_ppn_i, 12'd0};
      end

      started          = 1'b0;
      started_port     = 1'b0;
      walker_busy_next = active_valid;

      if (!active_valid && (lsu_pending || fetch_pending)) begin
        if (lsu_pending) begin
          active_valid      <= 1'b1;
          active_port       <= 1'b0;
          active_va         <= lsu_pend_va;
          active_is_store   <= lsu_pend_is_store;
          active_priv       <= 2'd0;
          active_ld_st_priv <= lsu_pend_ld_st_priv;
          active_sum        <= lsu_pend_sum;
          active_mxr        <= lsu_pend_mxr;
          active_asid       <= lsu_pend_asid;
          lsu_pending       <= 1'b0;
          walk_state        <= W_CALC;
          walk_level        <= 2'd2;
          walk_a            <= {satp_ppn_i, 12'd0};
          started           = 1'b1;
          started_port      = 1'b0;
          walker_busy_next  = 1'b1;
        end else begin
          active_valid      <= 1'b1;
          active_port       <= 1'b1;
          active_va         <= fetch_pend_va;
          active_is_store   <= 1'b0;
          active_priv       <= fetch_pend_priv;
          active_ld_st_priv <= 2'd0;
          active_sum        <= 1'b0;
          active_mxr        <= 1'b0;
          active_asid       <= fetch_pend_asid;
          fetch_pending     <= 1'b0;
          walk_state        <= W_CALC;
          walk_level        <= 2'd2;
          walk_a            <= {satp_ppn_i, 12'd0};
          started           = 1'b1;
          started_port      = 1'b1;
          walker_busy_next  = 1'b1;
        end
      end

      if (lsu_req_i && !lsu_seen && !lsu_pending &&
          !(active_valid && active_port == 1'b0) &&
          !(started && started_port == 1'b0)) begin
        if (!en_ld_st_translation_i) begin
          lsu_valid_o     <= 1'b1;
          lsu_paddr_o     <= lsu_vaddr_i[55:0];
          lsu_exc_valid_o <= 1'b0;
          lsu_seen        <= 1'b1;
        end else if (lsu_hit) begin
          if (lsu_hit_perm_fault) begin
            lsu_valid_o     <= 1'b1;
            lsu_exc_valid_o <= 1'b1;
            lsu_exc_cause_o <= lsu_is_store_i ? 64'd15 : 64'd13;
            lsu_exc_tval_o  <= lsu_vaddr_i;
            lsu_seen        <= 1'b1;
          end else begin
            lsu_valid_o     <= 1'b1;
            lsu_paddr_o     <= lsu_hit_pa;
            lsu_exc_valid_o <= 1'b0;
            lsu_seen        <= 1'b1;
          end
        end else begin
          if (!walker_busy_next) begin
            active_valid      <= 1'b1;
            active_port       <= 1'b0;
            active_va         <= lsu_vaddr_i;
            active_is_store   <= lsu_is_store_i;
            active_priv       <= 2'd0;
            active_ld_st_priv <= ld_st_priv_lvl_i;
            active_sum        <= sum_i;
            active_mxr        <= mxr_i;
            active_asid       <= asid_i;
            walk_state        <= W_CALC;
            walk_level        <= 2'd2;
            walk_a            <= {satp_ppn_i, 12'd0};
            started           = 1'b1;
            started_port      = 1'b0;
            walker_busy_next  = 1'b1;
            lsu_seen          <= 1'b1;
          end else begin
            lsu_pending        <= 1'b1;
            lsu_pend_va        <= lsu_vaddr_i;
            lsu_pend_is_store  <= lsu_is_store_i;
            lsu_pend_ld_st_priv<= ld_st_priv_lvl_i;
            lsu_pend_sum       <= sum_i;
            lsu_pend_mxr       <= mxr_i;
            lsu_pend_asid      <= asid_i;
            lsu_seen           <= 1'b1;
          end
        end
      end

      if (fetch_req_i && !fetch_seen && !fetch_pending &&
          !(active_valid && active_port == 1'b1) &&
          !(started && started_port == 1'b1)) begin
        if (!enable_translation_i) begin
          fetch_valid_o     <= 1'b1;
          fetch_paddr_o     <= fetch_vaddr_i[55:0];
          fetch_exc_valid_o <= 1'b0;
          fetch_seen        <= 1'b1;
        end else if (fetch_hit) begin
          if (fetch_hit_perm_fault) begin
            fetch_valid_o     <= 1'b1;
            fetch_exc_valid_o <= 1'b1;
            fetch_exc_cause_o <= 64'd12;
            fetch_exc_tval_o  <= fetch_vaddr_i;
            fetch_seen        <= 1'b1;
          end else begin
            fetch_valid_o     <= 1'b1;
            fetch_paddr_o     <= fetch_hit_pa;
            fetch_exc_valid_o <= 1'b0;
            fetch_seen        <= 1'b1;
          end
        end else begin
          if (!walker_busy_next) begin
            active_valid      <= 1'b1;
            active_port       <= 1'b1;
            active_va         <= fetch_vaddr_i;
            active_is_store   <= 1'b0;
            active_priv       <= priv_lvl_i;
            active_ld_st_priv <= 2'd0;
            active_sum        <= 1'b0;
            active_mxr        <= 1'b0;
            active_asid       <= asid_i;
            walk_state        <= W_CALC;
            walk_level        <= 2'd2;
            walk_a            <= {satp_ppn_i, 12'd0};
            started           = 1'b1;
            started_port      = 1'b1;
            walker_busy_next  = 1'b1;
            fetch_seen        <= 1'b1;
          end else begin
            fetch_pending     <= 1'b1;
            fetch_pend_va     <= fetch_vaddr_i;
            fetch_pend_priv   <= priv_lvl_i;
            fetch_pend_asid   <= asid_i;
            fetch_seen        <= 1'b1;
          end
        end
      end

      if (active_valid && !flush_i) begin
        case (walk_state)
          W_IDLE: begin
          end

          W_CALC: begin
            case (walk_level)
              2'd2: vpn_cur = active_va[38:30];
              2'd1: vpn_cur = active_va[29:21];
              2'd0: vpn_cur = active_va[20:12];
              default: vpn_cur = 9'd0;
            endcase
            walk_addr  <= walk_a + {44'd0, vpn_cur, 3'b000};
            walk_state <= W_PMP_CHECK;
          end

          W_PMP_CHECK: begin
            pmp_ok      = 1'b0;
            pmp_matched = 1'b0;
            pmp_allow   = 1'b0;
            addr        = walk_addr;

            for (int i = 0; i < 8; i++) begin
              if (!pmp_matched) begin
                mode = pmpcfg_i[i][4:3];

                if (mode == 2'b01) begin
                  if (i == 0) tor_low = 56'd0;
                  else        tor_low = {pmpaddr_i[i-1], 2'b00};
                  tor_high = {pmpaddr_i[i], 2'b00};

                  if (addr >= tor_low && addr < tor_high && tor_high > tor_low) begin
                    pmp_matched = 1'b1;
                    pmp_allow   = pmpcfg_i[i][0];
                  end
                end else if (mode == 2'b10) begin
                  if (addr[55:2] == pmpaddr_i[i]) begin
                    pmp_matched = 1'b1;
                    pmp_allow   = pmpcfg_i[i][0];
                  end
                end else if (mode == 2'b11) begin
                  trailing_ones = 6'd0;
                  still_ones    = 1'b1;

                  for (int j = 0; j < 54; j++) begin
                    if (still_ones && pmpaddr_i[i][j])
                      trailing_ones = trailing_ones + 6'd1;
                    else
                      still_ones = 1'b0;
                  end

                  napot_mask = 54'd0;
                  for (int j = 0; j < 54; j++) begin
                    if (j >= trailing_ones)
                      napot_mask[j] = 1'b1;
                  end

                  if ((addr[55:2] & napot_mask) == (pmpaddr_i[i] & napot_mask)) begin
                    pmp_matched = 1'b1;
                    pmp_allow   = pmpcfg_i[i][0];
                  end
                end
              end
            end

            pmp_ok = pmp_matched && pmp_allow;

            if (!pmp_ok) begin
              fault = 1'b1;
              if (active_port == 1'b1)
                cause = 64'd1;
              else if (active_is_store)
                cause = 64'd7;
              else
                cause = 64'd5;

              if (active_port == 1'b1) begin
                fetch_valid_o     <= 1'b1;
                fetch_exc_valid_o <= 1'b1;
                fetch_exc_cause_o <= cause;
                fetch_exc_tval_o  <= active_va;
              end else begin
                lsu_valid_o       <= 1'b1;
                lsu_exc_valid_o   <= 1'b1;
                lsu_exc_cause_o   <= cause;
                lsu_exc_tval_o    <= active_va;
              end

              active_valid <= 1'b0;
              walk_state   <= W_IDLE;
            end else begin
              walk_state <= W_MEM_REQ;
            end
          end

          W_MEM_REQ: begin
            if (mem_gnt_i) begin
              if (mem_rvalid_i) begin
                walk_pte   <= mem_rdata_i;
                walk_state <= W_PROCESS;
              end else begin
                walk_state <= W_MEM_WAIT;
              end
            end
          end

          W_MEM_WAIT: begin
            if (mem_rvalid_i) begin
              walk_pte   <= mem_rdata_i;
              walk_state <= W_PROCESS;
            end
          end

          W_PROCESS: begin
            new_pte = walk_pte;

            if (!new_pte[0]) begin
              fault = 1'b1;
              if (active_port == 1'b1)
                cause = 64'd12;
              else if (active_is_store)
                cause = 64'd15;
              else
                cause = 64'd13;

              if (active_port == 1'b1) begin
                fetch_valid_o     <= 1'b1;
                fetch_exc_valid_o <= 1'b1;
                fetch_exc_cause_o <= cause;
                fetch_exc_tval_o  <= active_va;
              end else begin
                lsu_valid_o       <= 1'b1;
                lsu_exc_valid_o   <= 1'b1;
                lsu_exc_cause_o   <= cause;
                lsu_exc_tval_o    <= active_va;
              end

              active_valid <= 1'b0;
              walk_state   <= W_IDLE;
            end else if (new_pte[2] && !new_pte[1]) begin
              fault = 1'b1;
              if (active_port == 1'b1)
                cause = 64'd12;
              else if (active_is_store)
                cause = 64'd15;
              else
                cause = 64'd13;

              if (active_port == 1'b1) begin
                fetch_valid_o     <= 1'b1;
                fetch_exc_valid_o <= 1'b1;
                fetch_exc_cause_o <= cause;
                fetch_exc_tval_o  <= active_va;
              end else begin
                lsu_valid_o       <= 1'b1;
                lsu_exc_valid_o   <= 1'b1;
                lsu_exc_cause_o   <= cause;
                lsu_exc_tval_o    <= active_va;
              end

              active_valid <= 1'b0;
              walk_state   <= W_IDLE;
            end else if (new_pte[1] || new_pte[3]) begin
              fault = 1'b0;

              if (walk_level == 2'd1) begin
                if (new_pte[18:10] != 9'd0)
                  fault = 1'b1;
              end else if (walk_level == 2'd2) begin
                if (new_pte[27:10] != 18'd0)
                  fault = 1'b1;
              end

              if (!fault) begin
                if (active_port == 1'b1) begin
                  fault = perm_fault(
                    1'b1, 1'b0, active_priv, active_sum, active_mxr,
                    new_pte[1], new_pte[2], new_pte[3], new_pte[4],
                    new_pte[6], new_pte[7]
                  );
                end else begin
                  fault = perm_fault(
                    1'b0, active_is_store, active_ld_st_priv, active_sum, active_mxr,
                    new_pte[1], new_pte[2], new_pte[3], new_pte[4],
                    new_pte[6], new_pte[7]
                  );
                end
              end

              if (fault) begin
                if (active_port == 1'b1)
                  cause = 64'd12;
                else if (active_is_store)
                  cause = 64'd15;
                else
                  cause = 64'd13;

                if (active_port == 1'b1) begin
                  fetch_valid_o     <= 1'b1;
                  fetch_exc_valid_o <= 1'b1;
                  fetch_exc_cause_o <= cause;
                  fetch_exc_tval_o  <= active_va;
                end else begin
                  lsu_valid_o       <= 1'b1;
                  lsu_exc_valid_o   <= 1'b1;
                  lsu_exc_cause_o   <= cause;
                  lsu_exc_tval_o    <= active_va;
                end

                active_valid <= 1'b0;
                walk_state   <= W_IDLE;
              end else begin
                new_ppn   = new_pte[53:10];
                new_level = walk_level;
                new_vpn   = {active_va[38:30], active_va[29:21], active_va[20:12]};

                case (new_level)
                  2'd0: pa = {new_ppn, active_va[11:0]};
                  2'd1: pa = {new_ppn[43:9], active_va[20:12], active_va[11:0]};
                  2'd2: pa = {new_ppn[43:18], active_va[29:12], active_va[11:0]};
                  default: pa = 56'd0;
                endcase

                if (!flush_tlb_i) begin
                  new_entry.valid = 1'b1;
                  new_entry.gen   = tlb_gen;
                  new_entry.asid  = active_asid;
                  new_entry.g     = new_pte[5];
                  new_entry.level = new_level;
                  new_entry.vpn   = new_vpn;
                  new_entry.ppn   = new_ppn;
                  new_entry.r     = new_pte[1];
                  new_entry.w     = new_pte[2];
                  new_entry.x     = new_pte[3];
                  new_entry.u     = new_pte[4];
                  new_entry.d     = new_pte[7];

                  if (active_port == 1'b1) begin
                    found  = 1'b0;
                    victim = itlb_rr;
                    for (int i = 0; i < 16; i++) begin
                      if (!found && (!itlb[i].valid || itlb[i].gen != tlb_gen)) begin
                        victim = i[3:0];
                        found  = 1'b1;
                      end
                    end
                    itlb[victim] <= new_entry;
                    itlb_rr      <= victim + 4'd1;
                  end else begin
                    found  = 1'b0;
                    victim = dtlb_rr;
                    for (int i = 0; i < 16; i++) begin
                      if (!found && (!dtlb[i].valid || dtlb[i].gen != tlb_gen)) begin
                        victim = i[3:0];
                        found  = 1'b1;
                      end
                    end
                    dtlb[victim] <= new_entry;
                    dtlb_rr      <= victim + 4'd1;
                  end
                end

                if (active_port == 1'b1) begin
                  fetch_valid_o     <= 1'b1;
                  fetch_paddr_o     <= pa;
                  fetch_exc_valid_o <= 1'b0;
                end else begin
                  lsu_valid_o       <= 1'b1;
                  lsu_paddr_o       <= pa;
                  lsu_exc_valid_o   <= 1'b0;
                end

                active_valid <= 1'b0;
                walk_state   <= W_IDLE;
              end
            end else begin
              if (walk_level == 2'd0) begin
                fault = 1'b1;
                if (active_port == 1'b1)
                  cause = 64'd12;
                else if (active_is_store)
                  cause = 64'd15;
                else
                  cause = 64'd13;

                if (active_port == 1'b1) begin
                  fetch_valid_o     <= 1'b1;
                  fetch_exc_valid_o <= 1'b1;
                  fetch_exc_cause_o <= cause;
                  fetch_exc_tval_o  <= active_va;
                end else begin
                  lsu_valid_o       <= 1'b1;
                  lsu_exc_valid_o   <= 1'b1;
                  lsu_exc_cause_o   <= cause;
                  lsu_exc_tval_o    <= active_va;
                end

                active_valid <= 1'b0;
                walk_state   <= W_IDLE;
              end else begin
                walk_a     <= {new_pte[53:10], 12'd0};
                walk_level <= walk_level - 2'd1;
                walk_state <= W_CALC;
              end
            end
          end

          default: walk_state <= W_IDLE;
        endcase
      end
    end
  end

endmodule
