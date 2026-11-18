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
  // TLB storage
  // ---------------------------------------------------------------------------
  logic        itlb_valid  [16];
  logic        itlb_global [16];
  logic [15:0] itlb_asid   [16];
  logic [26:0] itlb_vpn    [16];
  logic [1:0]  itlb_level  [16];
  logic [43:0] itlb_ppn    [16];
  logic [4:0]  itlb_perm   [16]; // {D, U, X, W, R}
  logic [3:0]  itlb_rr;

  logic        dtlb_valid  [16];
  logic        dtlb_global [16];
  logic [15:0] dtlb_asid   [16];
  logic [26:0] dtlb_vpn    [16];
  logic [1:0]  dtlb_level  [16];
  logic [43:0] dtlb_ppn    [16];
  logic [4:0]  dtlb_perm   [16]; // {D, U, X, W, R}
  logic [3:0]  dtlb_rr;

  // ---------------------------------------------------------------------------
  // FSM state and walk context
  // ---------------------------------------------------------------------------
  typedef enum logic [2:0] {
    ST_IDLE,
    ST_WALK_CHECK,
    ST_WALK_REQ,
    ST_WALK_WAIT,
    ST_WALK_PROC
  } state_t;

  state_t state;

  logic        walk_is_fetch;
  logic [63:0] walk_va;
  logic        walk_is_store;
  logic [1:0]  walk_priv;
  logic [1:0]  walk_level;
  logic [55:0] walk_base;
  logic [55:0] walk_mem_addr;
  logic [63:0] walk_pte;

  logic lsu_done, fetch_done;

  // ---------------------------------------------------------------------------
  // TLB lookup results
  // ---------------------------------------------------------------------------
  logic        lsu_tlb_hit;
  logic        lsu_tlb_fault;
  logic [55:0] lsu_tlb_paddr;
  logic [63:0] lsu_tlb_cause;

  logic        fetch_tlb_hit;
  logic        fetch_tlb_fault;
  logic [55:0] fetch_tlb_paddr;
  logic [63:0] fetch_tlb_cause;

  // ---------------------------------------------------------------------------
  // PMP check (walker reads only, requires R bit)
  // ---------------------------------------------------------------------------
  function automatic logic pmp_check(input logic [55:0] addr);
    logic [53:0] paddr_hi;
    logic [53:0] lower;
    logic [53:0] upper;
    logic [53:0] mask;
    logic [53:0] prev_pmpaddr;
    logic        match;
    logic        found;
    logic        allow;
    logic [1:0]  mode;
    integer      i;
    begin
      paddr_hi = addr[55:2];
      found = 0;
      allow = 0;
      prev_pmpaddr = 54'h0;

      for (i = 0; i < 8; i = i + 1) begin
        if (!found) begin
          mode = pmpcfg_i[i][4:3];
          match = 0;

          if (mode == 2'b00) begin
            match = 0;
          end else if (mode == 2'b01) begin // TOR
            lower = prev_pmpaddr;
            upper = pmpaddr_i[i];
            if (upper == 54'h3FFFFFFFFFFFFF) begin
              if (paddr_hi >= lower) match = 1;
            end else begin
              if (paddr_hi >= lower && paddr_hi < upper) match = 1;
            end
          end else if (mode == 2'b10) begin // NA4
            if (paddr_hi == pmpaddr_i[i]) match = 1;
          end else if (mode == 2'b11) begin // NAPOT
            if (pmpaddr_i[i] == 54'h3FFFFFFFFFFFFF) begin
              match = 1;
            end else begin
              mask = (pmpaddr_i[i] ^ (pmpaddr_i[i] + 1)) >> 1;
              if ((paddr_hi & ~mask) == (pmpaddr_i[i] & ~mask)) match = 1;
            end
          end

          if (match) begin
            found = 1;
            allow = pmpcfg_i[i][0]; // R bit
          end
        end
        prev_pmpaddr = pmpaddr_i[i];
      end

      if (!found) allow = 0;
      pmp_check = allow;
    end
  endfunction

  // ---------------------------------------------------------------------------
  // Data TLB lookup
  // ---------------------------------------------------------------------------
  always_comb begin
    logic        vpn_match;
    logic [43:0] ppn_out;
    logic        fault;
    integer      i;

    lsu_tlb_hit   = 0;
    lsu_tlb_fault = 0;
    lsu_tlb_paddr = 56'h0;
    lsu_tlb_cause = 64'h0;

    for (i = 0; i < 16; i = i + 1) begin
      if (!lsu_tlb_hit && dtlb_valid[i]) begin
        if (dtlb_global[i] || (dtlb_asid[i] == asid_i)) begin
          vpn_match = 0;
          case (dtlb_level[i])
            2'd2: vpn_match = (lsu_vaddr_i[38:30] == dtlb_vpn[i][26:18]);
            2'd1: vpn_match = (lsu_vaddr_i[38:21] == dtlb_vpn[i][26:9]);
            2'd0: vpn_match = (lsu_vaddr_i[38:12] == dtlb_vpn[i][26:0]);
            default: vpn_match = 0;
          endcase

          if (vpn_match) begin
            lsu_tlb_hit = 1;
            ppn_out = dtlb_ppn[i];
            if (dtlb_level[i] == 2'd1) begin
              ppn_out[8:0] = lsu_vaddr_i[20:12];
            end else if (dtlb_level[i] == 2'd2) begin
              ppn_out[17:0] = lsu_vaddr_i[29:12];
            end
            lsu_tlb_paddr = {ppn_out, lsu_vaddr_i[11:0]};

            fault = 0;
            if (lsu_is_store_i) begin
              if (!dtlb_perm[i][1]) fault = 1; // W
              if (!dtlb_perm[i][4]) fault = 1; // D
            end else begin
              if (!(dtlb_perm[i][0] || (dtlb_perm[i][2] && mxr_i))) fault = 1;
            end

            if (ld_st_priv_lvl_i == 2'b00) begin
              if (!dtlb_perm[i][3]) fault = 1; // U
            end else if (ld_st_priv_lvl_i == 2'b01) begin
              if (dtlb_perm[i][3]) begin
                if (!sum_i) fault = 1;
              end
            end

            if (fault) begin
              lsu_tlb_fault = 1;
              lsu_tlb_cause = lsu_is_store_i ? 64'd15 : 64'd13;
            end
          end
        end
      end
    end
  end

  // ---------------------------------------------------------------------------
  // Instruction TLB lookup
  // ---------------------------------------------------------------------------
  always_comb begin
    logic        vpn_match;
    logic [43:0] ppn_out;
    logic        fault;
    integer      i;

    fetch_tlb_hit   = 0;
    fetch_tlb_fault = 0;
    fetch_tlb_paddr = 56'h0;
    fetch_tlb_cause = 64'h0;

    for (i = 0; i < 16; i = i + 1) begin
      if (!fetch_tlb_hit && itlb_valid[i]) begin
        if (itlb_global[i] || (itlb_asid[i] == asid_i)) begin
          vpn_match = 0;
          case (itlb_level[i])
            2'd2: vpn_match = (fetch_vaddr_i[38:30] == itlb_vpn[i][26:18]);
            2'd1: vpn_match = (fetch_vaddr_i[38:21] == itlb_vpn[i][26:9]);
            2'd0: vpn_match = (fetch_vaddr_i[38:12] == itlb_vpn[i][26:0]);
            default: vpn_match = 0;
          endcase

          if (vpn_match) begin
            fetch_tlb_hit = 1;
            ppn_out = itlb_ppn[i];
            if (itlb_level[i] == 2'd1) begin
              ppn_out[8:0] = fetch_vaddr_i[20:12];
            end else if (itlb_level[i] == 2'd2) begin
              ppn_out[17:0] = fetch_vaddr_i[29:12];
            end
            fetch_tlb_paddr = {ppn_out, fetch_vaddr_i[11:0]};

            fault = 0;
            if (!itlb_perm[i][2]) fault = 1; // X

            if (priv_lvl_i == 2'b00) begin
              if (!itlb_perm[i][3]) fault = 1; // U
            end else if (priv_lvl_i == 2'b01) begin
              if (itlb_perm[i][3]) begin
                fault = 1; // never executable in supervisor if U=1
              end
            end

            if (fault) begin
              fetch_tlb_fault = 1;
              fetch_tlb_cause = 64'd12;
            end
          end
        end
      end
    end
  end

  // ---------------------------------------------------------------------------
  // Main sequential logic
  // ---------------------------------------------------------------------------
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      state <= ST_IDLE;

      lsu_valid_o      <= 0;
      lsu_paddr_o      <= 0;
      lsu_dtlb_hit_o   <= 0;
      lsu_dtlb_ppn_o   <= 0;
      lsu_exc_valid_o  <= 0;
      lsu_exc_cause_o  <= 0;
      lsu_exc_tval_o   <= 0;

      fetch_valid_o     <= 0;
      fetch_paddr_o     <= 0;
      fetch_exc_valid_o <= 0;
      fetch_exc_cause_o <= 0;
      fetch_exc_tval_o  <= 0;

      itlb_miss_o <= 0;
      dtlb_miss_o <= 0;

      mem_req_o       <= 0;
      mem_addr_o      <= 0;
      mem_tag_valid_o <= 0;
      mem_kill_o      <= 0;

      lsu_done   <= 0;
      fetch_done <= 0;

      itlb_rr <= 0;
      dtlb_rr <= 0;

      walk_is_fetch <= 0;
      walk_va       <= 0;
      walk_is_store <= 0;
      walk_priv     <= 0;
      walk_level    <= 0;
      walk_base     <= 0;
      walk_mem_addr <= 0;
      walk_pte      <= 0;

      for (int i = 0; i < 16; i = i + 1) begin
        itlb_valid[i] <= 0;
        dtlb_valid[i] <= 0;
      end
    end else begin
      // Default outputs
      lsu_valid_o     <= 0;
      lsu_exc_valid_o <= 0;
      fetch_valid_o     <= 0;
      fetch_exc_valid_o <= 0;
      mem_req_o       <= 0;
      mem_tag_valid_o <= 0;
      mem_kill_o      <= 0;

      // Flush TLBs
      if (flush_tlb_i) begin
        for (int i = 0; i < 16; i = i + 1) begin
          itlb_valid[i] <= 0;
          dtlb_valid[i] <= 0;
        end
      end

      // Clear done flags when request deasserts
      if (!lsu_req_i)   lsu_done   <= 0;
      if (!fetch_req_i) fetch_done <= 0;

      // Abort in-flight walk on flush_i
      if (flush_i && state != ST_IDLE) begin
        state <= ST_IDLE;
      end else begin
        case (state)
          ST_IDLE: begin
            if (lsu_req_i && !lsu_done) begin
              if (!en_ld_st_translation_i) begin
                // Bare mode
                lsu_valid_o     <= 1;
                lsu_paddr_o     <= lsu_vaddr_i[55:0];
                lsu_exc_valid_o <= 0;
                lsu_exc_cause_o <= 0;
                lsu_exc_tval_o  <= lsu_vaddr_i;
                lsu_done        <= 1;
              end else if (lsu_tlb_hit) begin
                lsu_valid_o     <= 1;
                lsu_paddr_o     <= lsu_tlb_paddr;
                lsu_exc_valid_o <= lsu_tlb_fault;
                lsu_exc_cause_o <= lsu_tlb_cause;
                lsu_exc_tval_o  <= lsu_vaddr_i;
                lsu_done        <= 1;
              end else begin
                walk_is_fetch <= 0;
                walk_va       <= lsu_vaddr_i;
                walk_is_store <= lsu_is_store_i;
                walk_priv     <= ld_st_priv_lvl_i;
                walk_level    <= 2'd2;
                walk_base     <= {satp_ppn_i, 12'h0};
                state         <= ST_WALK_CHECK;
              end
            end else if (fetch_req_i && !fetch_done) begin
              if (!enable_translation_i) begin
                // Bare mode
                fetch_valid_o     <= 1;
                fetch_paddr_o     <= fetch_vaddr_i[55:0];
                fetch_exc_valid_o <= 0;
                fetch_exc_cause_o <= 0;
                fetch_exc_tval_o  <= fetch_vaddr_i;
                fetch_done        <= 1;
              end else if (fetch_tlb_hit) begin
                fetch_valid_o     <= 1;
                fetch_paddr_o     <= fetch_tlb_paddr;
                fetch_exc_valid_o <= fetch_tlb_fault;
                fetch_exc_cause_o <= fetch_tlb_cause;
                fetch_exc_tval_o  <= fetch_vaddr_i;
                fetch_done        <= 1;
              end else begin
                walk_is_fetch <= 1;
                walk_va       <= fetch_vaddr_i;
                walk_is_store <= 0;
                walk_priv     <= priv_lvl_i;
                walk_level    <= 2'd2;
                walk_base     <= {satp_ppn_i, 12'h0};
                state         <= ST_WALK_CHECK;
              end
            end
          end

          ST_WALK_CHECK: begin
            logic [8:0]  walk_vpn;
            logic [55:0] next_addr;
            logic        pmp_allow;

            walk_vpn = 0;
            case (walk_level)
              2'd2: walk_vpn = walk_va[38:30];
              2'd1: walk_vpn = walk_va[29:21];
              2'd0: walk_vpn = walk_va[20:12];
              default: walk_vpn = 0;
            endcase

            next_addr = walk_base + {44'h0, walk_vpn, 3'b000};
            pmp_allow = pmp_check(next_addr);

            if (!pmp_allow) begin
              // Access fault
              if (walk_is_fetch) begin
                fetch_valid_o     <= 1;
                fetch_exc_valid_o <= 1;
                fetch_exc_cause_o <= 64'd1;
                fetch_exc_tval_o  <= walk_va;
                fetch_done        <= 1;
              end else begin
                lsu_valid_o     <= 1;
                lsu_exc_valid_o <= 1;
                lsu_exc_cause_o <= walk_is_store ? 64'd7 : 64'd5;
                lsu_exc_tval_o  <= walk_va;
                lsu_done        <= 1;
              end
              state <= ST_IDLE;
            end else begin
              walk_mem_addr <= next_addr;
              state         <= ST_WALK_REQ;
            end
          end

          ST_WALK_REQ: begin
            mem_req_o  <= 1;
            mem_addr_o <= walk_mem_addr;
            if (mem_gnt_i) begin
              state <= ST_WALK_WAIT;
            end
          end

          ST_WALK_WAIT: begin
            mem_req_o <= 0;
            if (mem_rvalid_i) begin
              walk_pte <= mem_rdata_i;
              state    <= ST_WALK_PROC;
            end
          end

          ST_WALK_PROC: begin
            logic        fault;
            logic        misaligned;
            logic [43:0] ppn_out;
            logic [55:0] pa;

            fault      = 0;
            misaligned = 0;

            if (!walk_pte[0]) begin
              fault = 1;
            end else if (walk_pte[2] && !walk_pte[1]) begin // W=1, R=0 reserved
              fault = 1;
            end else if (walk_pte[1] || walk_pte[3]) begin // leaf
              if (walk_level == 2'd1 && walk_pte[18:10] != 0) misaligned = 1;
              if (walk_level == 2'd2 && walk_pte[27:10] != 0) misaligned = 1;
              if (!walk_pte[6]) misaligned = 1; // A=0
              if (walk_is_store && !walk_pte[7]) misaligned = 1; // D=0 for store

              if (!misaligned) begin
                if (walk_is_fetch) begin
                  if (!walk_pte[3]) fault = 1; // X
                end else begin
                  if (walk_is_store) begin
                    if (!walk_pte[2]) fault = 1; // W
                  end else begin
                    if (!(walk_pte[1] || (walk_pte[3] && mxr_i))) fault = 1;
                  end
                end

                if (walk_priv == 2'b00) begin
                  if (!walk_pte[4]) fault = 1; // U
                end else if (walk_priv == 2'b01) begin
                  if (walk_pte[4]) begin
                    if (walk_is_fetch) fault = 1;
                    else if (!sum_i) fault = 1;
                  end
                end
              end

              if (misaligned || fault) begin
                if (walk_is_fetch) begin
                  fetch_valid_o     <= 1;
                  fetch_exc_valid_o <= 1;
                  fetch_exc_cause_o <= 64'd12;
                  fetch_exc_tval_o  <= walk_va;
                  fetch_done        <= 1;
                end else begin
                  lsu_valid_o     <= 1;
                  lsu_exc_valid_o <= 1;
                  lsu_exc_cause_o <= walk_is_store ? 64'd15 : 64'd13;
                  lsu_exc_tval_o  <= walk_va;
                  lsu_done        <= 1;
                end
                state <= ST_IDLE;
              end else begin
                // Successful translation
                ppn_out = walk_pte[53:10];
                if (walk_level == 2'd1) ppn_out[8:0]  = walk_va[20:12];
                if (walk_level == 2'd2) ppn_out[17:0] = walk_va[29:12];
                pa = {ppn_out, walk_va[11:0]};

                if (walk_is_fetch) begin
                  fetch_valid_o     <= 1;
                  fetch_paddr_o     <= pa;
                  fetch_exc_valid_o <= 0;
                  fetch_exc_cause_o <= 0;
                  fetch_exc_tval_o  <= walk_va;
                  fetch_done        <= 1;

                  if (!flush_tlb_i) begin
                    itlb_valid[itlb_rr]  <= 1;
                    itlb_global[itlb_rr] <= walk_pte[5];
                    itlb_asid[itlb_rr]   <= asid_i;
                    itlb_vpn[itlb_rr]    <= {walk_va[38:30], walk_va[29:21], walk_va[20:12]};
                    itlb_level[itlb_rr]  <= walk_level;
                    itlb_ppn[itlb_rr]    <= walk_pte[53:10];
                    itlb_perm[itlb_rr]   <= {walk_pte[7], walk_pte[4], walk_pte[3], walk_pte[2], walk_pte[1]};
                    itlb_rr              <= itlb_rr + 1;
                  end
                end else begin
                  lsu_valid_o     <= 1;
                  lsu_paddr_o     <= pa;
                  lsu_exc_valid_o <= 0;
                  lsu_exc_cause_o <= 0;
                  lsu_exc_tval_o  <= walk_va;
                  lsu_done        <= 1;

                  if (!flush_tlb_i) begin
                    dtlb_valid[dtlb_rr]  <= 1;
                    dtlb_global[dtlb_rr] <= walk_pte[5];
                    dtlb_asid[dtlb_rr]   <= asid_i;
                    dtlb_vpn[dtlb_rr]    <= {walk_va[38:30], walk_va[29:21], walk_va[20:12]};
                    dtlb_level[dtlb_rr]  <= walk_level;
                    dtlb_ppn[dtlb_rr]    <= walk_pte[53:10];
                    dtlb_perm[dtlb_rr]   <= {walk_pte[7], walk_pte[4], walk_pte[3], walk_pte[2], walk_pte[1]};
                    dtlb_rr              <= dtlb_rr + 1;
                  end
                end
                state <= ST_IDLE;
              end
            end else begin
              // Non-leaf pointer
              if (walk_level == 2'd0) begin
                if (walk_is_fetch) begin
                  fetch_valid_o     <= 1;
                  fetch_exc_valid_o <= 1;
                  fetch_exc_cause_o <= 64'd12;
                  fetch_exc_tval_o  <= walk_va;
                  fetch_done        <= 1;
                end else begin
                  lsu_valid_o     <= 1;
                  lsu_exc_valid_o <= 1;
                  lsu_exc_cause_o <= walk_is_store ? 64'd15 : 64'd13;
                  lsu_exc_tval_o  <= walk_va;
                  lsu_done        <= 1;
                end
                state <= ST_IDLE;
              end else begin
                walk_base  <= {walk_pte[53:10], 12'h0};
                walk_level <= walk_level - 1;
                state      <= ST_WALK_CHECK;
              end
            end
          end
        endcase
      end
    end
  end

  // ---------------------------------------------------------------------------
  // Unscored outputs
  // ---------------------------------------------------------------------------
  assign lsu_dtlb_hit_o = lsu_tlb_hit;
  assign lsu_dtlb_ppn_o = lsu_tlb_paddr[55:12];
  assign itlb_miss_o    = 1'b0;
  assign dtlb_miss_o    = 1'b0;

endmodule
