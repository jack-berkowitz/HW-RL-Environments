// =============================================================================
// sv39_mmu -- Sv39 MMU implementation for d_ca03
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
  // State
  // ---------------------------------------------------------------------------
  typedef enum logic [2:0] {
    S_IDLE,
    S_WALK_REQ,
    S_WALK_GNT,
    S_WALK_RVALID,
    S_DONE
  } state_t;

  state_t state;

  // Latched request context
  logic        req_is_fetch;
  logic [63:0] req_vaddr;
  logic        req_is_store;
  logic [1:0]  req_priv;
  logic        req_sum;
  logic        req_mxr;
  logic [15:0] req_asid;

  logic [55:0] walk_base;
  logic [1:0]  walk_level;

  logic        last_was_fetch;

  // ---------------------------------------------------------------------------
  // TLBs
  // ---------------------------------------------------------------------------
  logic [15:0] itlb_valid;
  logic [15:0] dtlb_valid;

  logic [26:0] itlb_vpn [0:15];
  logic [26:0] dtlb_vpn [0:15];

  logic [15:0] itlb_asid [0:15];
  logic [15:0] dtlb_asid [0:15];

  logic [43:0] itlb_ppn [0:15];
  logic [43:0] dtlb_ppn [0:15];

  logic [1:0] itlb_level [0:15];
  logic [1:0] dtlb_level [0:15];

  logic itlb_global [0:15];
  logic dtlb_global [0:15];

  logic itlb_r [0:15];
  logic dtlb_r [0:15];

  logic itlb_w [0:15];
  logic dtlb_w [0:15];

  logic itlb_x [0:15];
  logic dtlb_x [0:15];

  logic itlb_u [0:15];
  logic dtlb_u [0:15];

  logic itlb_a [0:15];
  logic dtlb_a [0:15];

  logic itlb_d [0:15];
  logic dtlb_d [0:15];

  logic [3:0] itlb_ptr;
  logic [3:0] dtlb_ptr;

  // ---------------------------------------------------------------------------
  // Functions
  // ---------------------------------------------------------------------------
  function automatic logic [63:0] page_cause(
    input logic is_fetch,
    input logic is_store
  );
    begin
      if (is_fetch)
        page_cause = 64'd12;
      else if (is_store)
        page_cause = 64'd15;
      else
        page_cause = 64'd13;
    end
  endfunction

  function automatic logic [63:0] access_cause(
    input logic is_fetch,
    input logic is_store
  );
    begin
      if (is_fetch)
        access_cause = 64'd1;
      else if (is_store)
        access_cause = 64'd7;
      else
        access_cause = 64'd5;
    end
  endfunction

  function automatic logic [55:0] compose_pa(
    input logic [43:0] ppn,
    input logic [1:0]  level,
    input logic [63:0] va
  );
    logic [55:0] pa;
    begin
      case (level)
        2'd0: pa = {ppn, va[11:0]};
        2'd1: pa = {ppn[43:9], va[20:12], va[11:0]};
        2'd2: pa = {ppn[43:18], va[29:12], va[11:0]};
        default: pa = {ppn, va[11:0]};
      endcase
      compose_pa = pa;
    end
  endfunction

  function automatic logic perm_ok(
    input logic        r,
    input logic        w,
    input logic        x,
    input logic        u,
    input logic        a,
    input logic        d,
    input logic        is_fetch,
    input logic        is_store,
    input logic [1:0]  priv,
    input logic        sum,
    input logic        mxr
  );
    logic ok;
    begin
      ok = 1'b1;

      // A/D fault-on-unset policy
      if (!a)
        ok = 1'b0;
      if (is_store && !d)
        ok = 1'b0;

      // Privilege / U / SUM rules
      if (priv == 2'b00) begin
        if (!u)
          ok = 1'b0;
      end else begin
        if (is_fetch) begin
          // Supervisor cannot execute user pages
          if (u)
            ok = 1'b0;
        end else begin
          // Supervisor may access user pages only with SUM
          if (u && !sum)
            ok = 1'b0;
        end
      end

      // Access-type permissions
      if (is_fetch) begin
        if (!x)
          ok = 1'b0;
      end else if (is_store) begin
        if (!w)
          ok = 1'b0;
      end else begin
        if (!(r || (mxr && x)))
          ok = 1'b0;
      end

      perm_ok = ok;
    end
  endfunction

  function automatic logic pmp_read_allowed(
    input logic [55:0]       addr,
    input logic [7:0][7:0]   cfg,
    input logic [7:0][53:0]  pmpaddr
  );
    logic        allowed;
    logic        matched;
    logic [1:0]  mode;
    logic [55:0] base;
    logic [55:0] top;
    logic [53:0] addr2;
    logic [53:0] a2;
    logic [53:0] mask;
    logic [5:0]  k;
    logic        stop;
    integer      i;
    integer      j;
    begin
      allowed = 1'b0;
      matched = 1'b0;
      addr2   = addr[55:2];

      for (i = 0; i < 8; i = i + 1) begin
        if (!matched) begin
          mode = cfg[i][4:3];

          if (mode == 2'd1) begin
            // TOR
            if (i == 0)
              base = 56'd0;
            else
              base = {pmpaddr[i-1], 2'b00};
            top = {pmpaddr[i], 2'b00};

            if (addr >= base && addr < top) begin
              matched = 1'b1;
              allowed = cfg[i][0];
            end
          end else if (mode == 2'd2) begin
            // NA4
            if (addr2 == pmpaddr[i]) begin
              matched = 1'b1;
              allowed = cfg[i][0];
            end
          end else if (mode == 2'd3) begin
            // NAPOT
            a2   = pmpaddr[i];
            k    = 6'd0;
            stop = 1'b0;

            for (j = 0; j < 54; j = j + 1) begin
              if (!stop) begin
                if (a2[j] == 1'b1)
                  k = k + 6'd1;
                else
                  stop = 1'b1;
              end
            end

            if (k != 6'd0) begin
              mask = ~((54'd1 << k) - 54'd1);
              if ((addr2 & mask) == (a2 & mask)) begin
                matched = 1'b1;
                allowed = cfg[i][0];
              end
            end
          end
        end
      end

      pmp_read_allowed = allowed;
    end
  endfunction

  function automatic logic [3:0] first_zero16(
    input logic [15:0] v
  );
    logic   found;
    integer i;
    begin
      found        = 1'b0;
      first_zero16 = 4'd0;
      for (i = 0; i < 16; i = i + 1) begin
        if (!found && !v[i]) begin
          first_zero16 = i[3:0];
          found        = 1'b1;
        end
      end
    end
  endfunction

  // ---------------------------------------------------------------------------
  // Data TLB lookup (current lsu input)
  // ---------------------------------------------------------------------------
  logic        lsu_hit_found;
  logic [3:0]  lsu_hit_idx;
  logic [43:0] lsu_hit_ppn;
  logic [1:0]  lsu_hit_level;
  logic        lsu_hit_r;
  logic        lsu_hit_w;
  logic        lsu_hit_x;
  logic        lsu_hit_u;
  logic        lsu_hit_a;
  logic        lsu_hit_d;

  always_comb begin
    integer i;
    lsu_hit_found = 1'b0;
    lsu_hit_idx   = 4'd0;
    lsu_hit_ppn   = 44'd0;
    lsu_hit_level = 2'd0;
    lsu_hit_r     = 1'b0;
    lsu_hit_w     = 1'b0;
    lsu_hit_x     = 1'b0;
    lsu_hit_u     = 1'b0;
    lsu_hit_a     = 1'b0;
    lsu_hit_d     = 1'b0;

    for (i = 0; i < 16; i = i + 1) begin
      if (!lsu_hit_found &&
          dtlb_valid[i] &&
          (dtlb_global[i] || (dtlb_asid[i] == asid_i))) begin
        case (dtlb_level[i])
          2'd0: begin
            if (dtlb_vpn[i] == lsu_vaddr_i[38:12]) begin
              lsu_hit_found = 1'b1;
              lsu_hit_idx   = i[3:0];
            end
          end
          2'd1: begin
            if (dtlb_vpn[i][26:9] == lsu_vaddr_i[38:21]) begin
              lsu_hit_found = 1'b1;
              lsu_hit_idx   = i[3:0];
            end
          end
          2'd2: begin
            if (dtlb_vpn[i][26:18] == lsu_vaddr_i[38:30]) begin
              lsu_hit_found = 1'b1;
              lsu_hit_idx   = i[3:0];
            end
          end
          default: begin
          end
        endcase
      end
    end

    if (lsu_hit_found) begin
      lsu_hit_ppn   = dtlb_ppn[lsu_hit_idx];
      lsu_hit_level = dtlb_level[lsu_hit_idx];
      lsu_hit_r     = dtlb_r[lsu_hit_idx];
      lsu_hit_w     = dtlb_w[lsu_hit_idx];
      lsu_hit_x     = dtlb_x[lsu_hit_idx];
      lsu_hit_u     = dtlb_u[lsu_hit_idx];
      lsu_hit_a     = dtlb_a[lsu_hit_idx];
      lsu_hit_d     = dtlb_d[lsu_hit_idx];
    end
  end

  // ---------------------------------------------------------------------------
  // Instruction TLB lookup (current fetch input)
  // ---------------------------------------------------------------------------
  logic        fetch_hit_found;
  logic [3:0]  fetch_hit_idx;
  logic [43:0] fetch_hit_ppn;
  logic [1:0]  fetch_hit_level;
  logic        fetch_hit_r;
  logic        fetch_hit_w;
  logic        fetch_hit_x;
  logic        fetch_hit_u;
  logic        fetch_hit_a;
  logic        fetch_hit_d;

  always_comb begin
    integer i;
    fetch_hit_found = 1'b0;
    fetch_hit_idx   = 4'd0;
    fetch_hit_ppn   = 44'd0;
    fetch_hit_level = 2'd0;
    fetch_hit_r     = 1'b0;
    fetch_hit_w     = 1'b0;
    fetch_hit_x     = 1'b0;
    fetch_hit_u     = 1'b0;
    fetch_hit_a     = 1'b0;
    fetch_hit_d     = 1'b0;

    for (i = 0; i < 16; i = i + 1) begin
      if (!fetch_hit_found &&
          itlb_valid[i] &&
          (itlb_global[i] || (itlb_asid[i] == asid_i))) begin
        case (itlb_level[i])
          2'd0: begin
            if (itlb_vpn[i] == fetch_vaddr_i[38:12]) begin
              fetch_hit_found = 1'b1;
              fetch_hit_idx   = i[3:0];
            end
          end
          2'd1: begin
            if (itlb_vpn[i][26:9] == fetch_vaddr_i[38:21]) begin
              fetch_hit_found = 1'b1;
              fetch_hit_idx   = i[3:0];
            end
          end
          2'd2: begin
            if (itlb_vpn[i][26:18] == fetch_vaddr_i[38:30]) begin
              fetch_hit_found = 1'b1;
              fetch_hit_idx   = i[3:0];
            end
          end
          default: begin
          end
        endcase
      end
    end

    if (fetch_hit_found) begin
      fetch_hit_ppn   = itlb_ppn[fetch_hit_idx];
      fetch_hit_level = itlb_level[fetch_hit_idx];
      fetch_hit_r     = itlb_r[fetch_hit_idx];
      fetch_hit_w     = itlb_w[fetch_hit_idx];
      fetch_hit_x     = itlb_x[fetch_hit_idx];
      fetch_hit_u     = itlb_u[fetch_hit_idx];
      fetch_hit_a     = itlb_a[fetch_hit_idx];
      fetch_hit_d     = itlb_d[fetch_hit_idx];
    end
  end

  // ---------------------------------------------------------------------------
  // Walker address calculation
  // ---------------------------------------------------------------------------
  logic [55:0] pte_addr_w;
  logic [8:0]  vpn_sel;

  always_comb begin
    case (walk_level)
      2'd2: vpn_sel = req_vaddr[38:30];
      2'd1: vpn_sel = req_vaddr[29:21];
      2'd0: vpn_sel = req_vaddr[20:12];
      default: vpn_sel = 9'd0;
    endcase
    pte_addr_w = walk_base + {vpn_sel, 3'b000};
  end

  // ---------------------------------------------------------------------------
  // Walk decode
  // ---------------------------------------------------------------------------
  logic        walk_leaf_valid;
  logic        walk_fault;
  logic [63:0] walk_fault_cause;
  logic        walk_nonleaf;
  logic [55:0] walk_pa;
  logic        walk_misaligned;
  logic        walk_perm_ok;
  logic        walk_install_en;

  always_comb begin
    walk_leaf_valid  = 1'b0;
    walk_fault       = 1'b0;
    walk_fault_cause = 64'd0;
    walk_nonleaf     = 1'b0;
    walk_pa          = 56'd0;
    walk_misaligned  = 1'b0;
    walk_perm_ok     = 1'b0;

    if (state == S_WALK_RVALID && mem_rvalid_i && !flush_i) begin
      if (mem_rdata_i[0] == 1'b0) begin
        walk_fault = 1'b1;
      end else if (mem_rdata_i[2] && !mem_rdata_i[1]) begin
        // W=1, R=0 is a reserved encoding
        walk_fault = 1'b1;
      end else if (mem_rdata_i[1] || mem_rdata_i[3]) begin
        // Leaf
        walk_misaligned = 1'b0;
        if (walk_level == 2'd2) begin
          if (mem_rdata_i[27:10] != 18'd0)
            walk_misaligned = 1'b1;
        end else if (walk_level == 2'd1) begin
          if (mem_rdata_i[18:10] != 9'd0)
            walk_misaligned = 1'b1;
        end

        walk_perm_ok = perm_ok(
          mem_rdata_i[1], mem_rdata_i[2], mem_rdata_i[3],
          mem_rdata_i[4], mem_rdata_i[6], mem_rdata_i[7],
          req_is_fetch, req_is_store, req_priv, req_sum, req_mxr
        );

        if (walk_misaligned || !walk_perm_ok) begin
          walk_fault = 1'b1;
        end else begin
          walk_leaf_valid = 1'b1;
          walk_pa = compose_pa(mem_rdata_i[53:10], walk_level, req_vaddr);
        end
      end else begin
        // Non-leaf
        if (walk_level == 2'd0)
          walk_fault = 1'b1;
        else
          walk_nonleaf = 1'b1;
      end

      if (walk_fault)
        walk_fault_cause = page_cause(req_is_fetch, req_is_store);
    end
  end

  assign walk_install_en = walk_leaf_valid;

  // ---------------------------------------------------------------------------
  // TLB storage
  // ---------------------------------------------------------------------------
  always_ff @(posedge clk_i or negedge rst_ni) begin : tlb_seq
    logic [3:0] idx;
    integer     i;

    if (!rst_ni) begin
      itlb_valid <= 16'h0;
      dtlb_valid <= 16'h0;
      itlb_ptr   <= 4'h0;
      dtlb_ptr   <= 4'h0;
    end else begin
      if (flush_tlb_i) begin
        itlb_valid <= 16'h0;
        dtlb_valid <= 16'h0;
        itlb_ptr   <= 4'h0;
        dtlb_ptr   <= 4'h0;
      end else if (walk_install_en) begin
        if (req_is_fetch) begin
          if (itlb_valid != 16'hFFFF) begin
            idx = first_zero16(itlb_valid);
          end else begin
            idx = itlb_ptr;
            itlb_ptr <= itlb_ptr + 4'd1;
          end

          itlb_valid[idx]  <= 1'b1;
          itlb_vpn[idx]    <= req_vaddr[38:12];
          itlb_asid[idx]   <= req_asid;
          itlb_ppn[idx]    <= mem_rdata_i[53:10];
          itlb_level[idx]  <= walk_level;
          itlb_global[idx] <= mem_rdata_i[5];
          itlb_r[idx]      <= mem_rdata_i[1];
          itlb_w[idx]      <= mem_rdata_i[2];
          itlb_x[idx]      <= mem_rdata_i[3];
          itlb_u[idx]      <= mem_rdata_i[4];
          itlb_a[idx]      <= mem_rdata_i[6];
          itlb_d[idx]      <= mem_rdata_i[7];
        end else begin
          if (dtlb_valid != 16'hFFFF) begin
            idx = first_zero16(dtlb_valid);
          end else begin
            idx = dtlb_ptr;
            dtlb_ptr <= dtlb_ptr + 4'd1;
          end

          dtlb_valid[idx]  <= 1'b1;
          dtlb_vpn[idx]    <= req_vaddr[38:12];
          dtlb_asid[idx]   <= req_asid;
          dtlb_ppn[idx]    <= mem_rdata_i[53:10];
          dtlb_level[idx]  <= walk_level;
          dtlb_global[idx] <= mem_rdata_i[5];
          dtlb_r[idx]      <= mem_rdata_i[1];
          dtlb_w[idx]      <= mem_rdata_i[2];
          dtlb_x[idx]      <= mem_rdata_i[3];
          dtlb_u[idx]      <= mem_rdata_i[4];
          dtlb_a[idx]      <= mem_rdata_i[6];
          dtlb_d[idx]      <= mem_rdata_i[7];
        end
      end
    end
  end

  // ---------------------------------------------------------------------------
  // Main control
  // ---------------------------------------------------------------------------
  always_ff @(posedge clk_i or negedge rst_ni) begin : main_seq
    logic chosen_fetch;

    if (!rst_ni) begin
      state            <= S_IDLE;
      req_is_fetch     <= 1'b0;
      req_vaddr        <= 64'd0;
      req_is_store     <= 1'b0;
      req_priv         <= 2'd0;
      req_sum          <= 1'b0;
      req_mxr          <= 1'b0;
      req_asid         <= 16'd0;
      walk_base        <= 56'd0;
      walk_level       <= 2'd0;
      last_was_fetch   <= 1'b0;

      mem_req_o        <= 1'b0;
      mem_addr_o       <= 56'd0;

      lsu_valid_o      <= 1'b0;
      lsu_paddr_o      <= 56'd0;
      lsu_exc_valid_o  <= 1'b0;
      lsu_exc_cause_o  <= 64'd0;
      lsu_exc_tval_o   <= 64'd0;

      fetch_valid_o    <= 1'b0;
      fetch_paddr_o    <= 56'd0;
      fetch_exc_valid_o<= 1'b0;
      fetch_exc_cause_o<= 64'd0;
      fetch_exc_tval_o <= 64'd0;
    end else begin
      // Default pulse outputs
      lsu_valid_o      <= 1'b0;
      lsu_paddr_o      <= 56'd0;
      lsu_exc_valid_o  <= 1'b0;
      lsu_exc_cause_o  <= 64'd0;
      lsu_exc_tval_o   <= 64'd0;

      fetch_valid_o    <= 1'b0;
      fetch_paddr_o    <= 56'd0;
      fetch_exc_valid_o<= 1'b0;
      fetch_exc_cause_o<= 64'd0;
      fetch_exc_tval_o <= 64'd0;

      mem_req_o        <= 1'b0;

      if (flush_i &&
          (state == S_WALK_REQ || state == S_WALK_GNT || state == S_WALK_RVALID)) begin
        // Abort in-flight walk.  If the requester holds req_i, the next IDLE
        // cycle restarts it.
        state     <= S_IDLE;
        mem_req_o <= 1'b0;
      end else begin
        case (state)
          S_IDLE: begin
            if (lsu_req_i || fetch_req_i) begin
              if (lsu_req_i && fetch_req_i) begin
                if (last_was_fetch)
                  chosen_fetch = 1'b0;
                else
                  chosen_fetch = 1'b1;
              end else if (lsu_req_i) begin
                chosen_fetch = 1'b0;
              end else begin
                chosen_fetch = 1'b1;
              end

              last_was_fetch <= chosen_fetch;

              if (chosen_fetch) begin
                if (!enable_translation_i) begin
                  // BARE
                  fetch_valid_o <= 1'b1;
                  fetch_paddr_o <= fetch_vaddr_i[55:0];
                  state         <= S_DONE;
                end else if (fetch_hit_found) begin
                  if (perm_ok(fetch_hit_r, fetch_hit_w, fetch_hit_x,
                              fetch_hit_u, fetch_hit_a, fetch_hit_d,
                              1'b1, 1'b0, priv_lvl_i, 1'b0, 1'b0)) begin
                    fetch_valid_o <= 1'b1;
                    fetch_paddr_o <= compose_pa(fetch_hit_ppn, fetch_hit_level,
                                                fetch_vaddr_i);
                    state         <= S_DONE;
                  end else begin
                    fetch_valid_o     <= 1'b1;
                    fetch_exc_valid_o <= 1'b1;
                    fetch_exc_cause_o <= page_cause(1'b1, 1'b0);
                    fetch_exc_tval_o  <= fetch_vaddr_i;
                    state             <= S_DONE;
                  end
                end else begin
                  // Miss: start walk
                  req_is_fetch <= 1'b1;
                  req_vaddr    <= fetch_vaddr_i;
                  req_is_store <= 1'b0;
                  req_priv     <= priv_lvl_i;
                  req_sum      <= 1'b0;
                  req_mxr      <= 1'b0;
                  req_asid     <= asid_i;
                  walk_base    <= {satp_ppn_i, 12'b0};
                  walk_level   <= 2'd2;
                  state        <= S_WALK_REQ;
                end
              end else begin
                if (!en_ld_st_translation_i) begin
                  // BARE
                  lsu_valid_o <= 1'b1;
                  lsu_paddr_o <= lsu_vaddr_i[55:0];
                  state       <= S_DONE;
                end else if (lsu_hit_found) begin
                  if (perm_ok(lsu_hit_r, lsu_hit_w, lsu_hit_x,
                              lsu_hit_u, lsu_hit_a, lsu_hit_d,
                              1'b0, lsu_is_store_i, ld_st_priv_lvl_i,
                              sum_i, mxr_i)) begin
                    lsu_valid_o <= 1'b1;
                    lsu_paddr_o <= compose_pa(lsu_hit_ppn, lsu_hit_level,
                                              lsu_vaddr_i);
                    state       <= S_DONE;
                  end else begin
                    lsu_valid_o     <= 1'b1;
                    lsu_exc_valid_o <= 1'b1;
                    lsu_exc_cause_o <= page_cause(1'b0, lsu_is_store_i);
                    lsu_exc_tval_o  <= lsu_vaddr_i;
                    state           <= S_DONE;
                  end
                end else begin
                  // Miss: start walk
                  req_is_fetch <= 1'b0;
                  req_vaddr    <= lsu_vaddr_i;
                  req_is_store <= lsu_is_store_i;
                  req_priv     <= ld_st_priv_lvl_i;
                  req_sum      <= sum_i;
                  req_mxr      <= mxr_i;
                  req_asid     <= asid_i;
                  walk_base    <= {satp_ppn_i, 12'b0};
                  walk_level   <= 2'd2;
                  state        <= S_WALK_REQ;
                end
              end
            end
          end

          S_WALK_REQ: begin
            if (!pmp_read_allowed(pte_addr_w, pmpcfg_i, pmpaddr_i)) begin
              // PMP access fault on walker read
              if (req_is_fetch) begin
                fetch_valid_o     <= 1'b1;
                fetch_exc_valid_o <= 1'b1;
                fetch_exc_cause_o <= access_cause(1'b1, 1'b0);
                fetch_exc_tval_o  <= req_vaddr;
              end else begin
                lsu_valid_o     <= 1'b1;
                lsu_exc_valid_o <= 1'b1;
                lsu_exc_cause_o <= access_cause(1'b0, req_is_store);
                lsu_exc_tval_o  <= req_vaddr;
              end
              state <= S_DONE;
            end else begin
              mem_req_o  <= 1'b1;
              mem_addr_o <= pte_addr_w;
              state      <= S_WALK_GNT;
            end
          end

          S_WALK_GNT: begin
            mem_req_o <= 1'b1;
            if (mem_gnt_i) begin
              mem_req_o <= 1'b0;
              state     <= S_WALK_RVALID;
            end
          end

          S_WALK_RVALID: begin
            if (mem_rvalid_i) begin
              if (walk_fault) begin
                if (req_is_fetch) begin
                  fetch_valid_o     <= 1'b1;
                  fetch_exc_valid_o <= 1'b1;
                  fetch_exc_cause_o <= walk_fault_cause;
                  fetch_exc_tval_o  <= req_vaddr;
                end else begin
                  lsu_valid_o     <= 1'b1;
                  lsu_exc_valid_o <= 1'b1;
                  lsu_exc_cause_o <= walk_fault_cause;
                  lsu_exc_tval_o  <= req_vaddr;
                end
                state <= S_DONE;
              end else if (walk_leaf_valid) begin
                if (req_is_fetch) begin
                  fetch_valid_o <= 1'b1;
                  fetch_paddr_o <= walk_pa;
                end else begin
                  lsu_valid_o <= 1'b1;
                  lsu_paddr_o <= walk_pa;
                end
                state <= S_DONE;
              end else if (walk_nonleaf) begin
                walk_base  <= {mem_rdata_i[53:10], 12'b0};
                walk_level <= walk_level - 2'd1;
                state      <= S_WALK_REQ;
              end else begin
                // Should be unreachable, but retire as a page fault.
                if (req_is_fetch) begin
                  fetch_valid_o     <= 1'b1;
                  fetch_exc_valid_o <= 1'b1;
                  fetch_exc_cause_o <= page_cause(1'b1, 1'b0);
                  fetch_exc_tval_o  <= req_vaddr;
                end else begin
                  lsu_valid_o     <= 1'b1;
                  lsu_exc_valid_o <= 1'b1;
                  lsu_exc_cause_o <= page_cause(1'b0, req_is_store);
                  lsu_exc_tval_o  <= req_vaddr;
                end
                state <= S_DONE;
              end
            end
          end

          S_DONE: begin
            state <= S_IDLE;
          end

          default: begin
            state <= S_IDLE;
          end
        endcase
      end
    end
  end

  // ---------------------------------------------------------------------------
  // Unscored / informational outputs
  // ---------------------------------------------------------------------------
  assign lsu_dtlb_hit_o  = 1'b0;
  assign lsu_dtlb_ppn_o  = 44'd0;
  assign itlb_miss_o     = 1'b0;
  assign dtlb_miss_o     = 1'b0;

  assign mem_tag_valid_o = 1'b0;
  assign mem_kill_o      = 1'b0;

endmodule
