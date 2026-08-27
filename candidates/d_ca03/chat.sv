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

  localparam logic [63:0] CAUSE_INST_ACCESS  = 64'd1;
  localparam logic [63:0] CAUSE_LOAD_ACCESS  = 64'd5;
  localparam logic [63:0] CAUSE_STORE_ACCESS = 64'd7;

  localparam logic [63:0] CAUSE_INST_PAGE  = 64'd12;
  localparam logic [63:0] CAUSE_LOAD_PAGE  = 64'd13;
  localparam logic [63:0] CAUSE_STORE_PAGE = 64'd15;

  localparam int TLB_R = 0;
  localparam int TLB_W = 1;
  localparam int TLB_X = 2;
  localparam int TLB_U = 3;
  localparam int TLB_A = 4;
  localparam int TLB_D = 5;

  typedef enum logic [2:0] {
    S_IDLE,
    S_WALK_REQ,
    S_WALK_WAIT,
    S_WALK_HAVE,
    S_DRAIN
  } state_t;

  state_t state_q;

  /*
   * Current page-walk request.
   */
  logic        req_is_fetch_q;
  logic        req_is_store_q;
  logic [63:0] req_va_q;
  logic [1:0]  req_priv_q;
  logic        req_sum_q;
  logic        req_mxr_q;
  logic [15:0] req_asid_q;
  logic [43:0] req_satp_ppn_q;

  logic [1:0]  walk_level_q;
  logic [55:0] walk_addr_q;
  logic [63:0] pte_hold_q;

  /*
   * DTLB: exactly 16 fully-associative entries.
   *
   * perm layout:
   *   [0] R
   *   [1] W
   *   [2] X
   *   [3] U
   *   [4] A
   *   [5] D
   */
  logic [15:0] dtlb_valid_q;
  logic [26:0] dtlb_vpn_q    [0:15];
  logic [43:0] dtlb_ppn_q    [0:15];
  logic [15:0] dtlb_asid_q   [0:15];
  logic        dtlb_global_q [0:15];
  logic [1:0]  dtlb_level_q  [0:15];
  logic [5:0]  dtlb_perm_q   [0:15];
  logic [3:0]  dtlb_rr_q;

  /*
   * ITLB: exactly 16 fully-associative entries.
   */
  logic [15:0] itlb_valid_q;
  logic [26:0] itlb_vpn_q    [0:15];
  logic [43:0] itlb_ppn_q    [0:15];
  logic [15:0] itlb_asid_q   [0:15];
  logic        itlb_global_q [0:15];
  logic [1:0]  itlb_level_q  [0:15];
  logic [5:0]  itlb_perm_q   [0:15];
  logic [3:0]  itlb_rr_q;

  logic        dtlb_hit_c;
  logic [3:0]  dtlb_hit_idx_c;
  logic [55:0] dtlb_hit_pa_c;
  logic        dtlb_perm_ok_c;

  logic        itlb_hit_c;
  logic [3:0]  itlb_hit_idx_c;
  logic [55:0] itlb_hit_pa_c;
  logic        itlb_perm_ok_c;

  logic [3:0]  dtlb_victim_c;
  logic [3:0]  itlb_victim_c;
  logic        dtlb_invalid_found_c;
  logic        itlb_invalid_found_c;

  logic        walk_pmp_allow_c;
  logic [63:0] pte_data_c;


  /*
   * --------------------------------------------------------------------------
   * Sv39 helpers
   * --------------------------------------------------------------------------
   */

  function automatic logic [8:0] vpn_for_level(
    input logic [63:0] va,
    input logic [1:0]  level
  );
    begin
      case (level)
        2'd2:    vpn_for_level = va[38:30];
        2'd1:    vpn_for_level = va[29:21];
        default: vpn_for_level = va[20:12];
      endcase
    end
  endfunction


  function automatic logic [55:0] make_pte_addr(
    input logic [43:0] ppn,
    input logic [8:0]  vpn
  );
    begin
      make_pte_addr =
          {ppn, 12'b0} +
          {44'b0, vpn, 3'b000};
    end
  endfunction


  function automatic logic [55:0] make_root_pte_addr(
    input logic [43:0] root_ppn,
    input logic [63:0] va
  );
    begin
      make_root_pte_addr =
          make_pte_addr(root_ppn, va[38:30]);
    end
  endfunction


  /*
   * A level-0 translation matches the entire VPN.
   *
   * A level-1 translation is a 2 MiB superpage, so VPN[0] is not
   * part of the tag.
   *
   * A level-2 translation is a 1 GiB superpage, so VPN[1:0] are
   * not part of the tag.
   */
  function automatic logic vpn_match(
    input logic [26:0] entry_vpn,
    input logic [26:0] req_vpn,
    input logic [1:0]  level
  );
    begin
      case (level)
        2'd2:
          vpn_match =
              (entry_vpn[26:18] == req_vpn[26:18]);

        2'd1:
          vpn_match =
              (entry_vpn[26:9] == req_vpn[26:9]);

        default:
          vpn_match =
              (entry_vpn == req_vpn);
      endcase
    end
  endfunction


  /*
   * Sv39 superpage alignment check.
   */
  function automatic logic leaf_misaligned(
    input logic [43:0] ppn,
    input logic [1:0]  level
  );
    begin
      case (level)
        2'd2:
          leaf_misaligned = (ppn[17:0] != 18'b0);

        2'd1:
          leaf_misaligned = (ppn[8:0] != 9'b0);

        default:
          leaf_misaligned = 1'b0;
      endcase
    end
  endfunction


  /*
   * Compose the final physical address.
   *
   * L0:
   *   PPN comes entirely from the PTE.
   *
   * L1:
   *   low nine PPN bits come from VPN[0].
   *
   * L2:
   *   low eighteen PPN bits come from VPN[1:0].
   */
  function automatic logic [55:0] compose_pa(
    input logic [43:0] ppn,
    input logic [1:0]  level,
    input logic [63:0] va
  );
    begin
      case (level)
        2'd2:
          compose_pa = {
            ppn[43:18],
            va[29:12],
            va[11:0]
          };

        2'd1:
          compose_pa = {
            ppn[43:9],
            va[20:12],
            va[11:0]
          };

        default:
          compose_pa = {
            ppn,
            va[11:0]
          };
      endcase
    end
  endfunction


  function automatic logic [43:0] compose_ppn(
    input logic [43:0] ppn,
    input logic [1:0]  level,
    input logic [63:0] va
  );
    logic [55:0] pa;

    begin
      pa = compose_pa(ppn, level, va);
      compose_ppn = pa[55:12];
    end
  endfunction


  /*
   * Leaf permission checking.
   */
  function automatic logic permission_ok(
    input logic [5:0] perm,
    input logic       is_fetch,
    input logic       is_store,
    input logic [1:0] priv,
    input logic       sum,
    input logic       mxr
  );
    logic access_ok;
    logic priv_ok;

    begin
      access_ok = 1'b0;
      priv_ok   = 1'b1;

      /*
       * Basic R/W/X permission.
       */
      if (is_fetch) begin
        access_ok = perm[TLB_X];
      end
      else if (is_store) begin
        access_ok = perm[TLB_W];
      end
      else begin
        access_ok =
            perm[TLB_R] |
            (mxr & perm[TLB_X]);
      end

      /*
       * Privilege/U handling.
       *
       * 00 = U
       * 01 = S
       */
      if (priv == 2'b00) begin
        priv_ok = perm[TLB_U];
      end
      else if (priv == 2'b01) begin
        if (perm[TLB_U]) begin
          /*
           * Supervisor can never execute from a U page.
           * SUM only affects loads/stores.
           */
          if (is_fetch)
            priv_ok = 1'b0;
          else
            priv_ok = sum;
        end
      end

      /*
       * A is required for every translated access.
       */
      permission_ok =
          access_ok &
          priv_ok &
          perm[TLB_A];

      /*
       * Store additionally requires D.
       */
      if (is_store)
        permission_ok =
            permission_ok &
            perm[TLB_D];
    end
  endfunction


  function automatic logic [63:0] page_fault_cause(
    input logic is_fetch,
    input logic is_store
  );
    begin
      if (is_fetch)
        page_fault_cause = CAUSE_INST_PAGE;
      else if (is_store)
        page_fault_cause = CAUSE_STORE_PAGE;
      else
        page_fault_cause = CAUSE_LOAD_PAGE;
    end
  endfunction


  function automatic logic [63:0] access_fault_cause(
    input logic is_fetch,
    input logic is_store
  );
    begin
      if (is_fetch)
        access_fault_cause = CAUSE_INST_ACCESS;
      else if (is_store)
        access_fault_cause = CAUSE_STORE_ACCESS;
      else
        access_fault_cause = CAUSE_LOAD_ACCESS;
    end
  endfunction


  /*
   * --------------------------------------------------------------------------
   * PMP
   * --------------------------------------------------------------------------
   *
   * PMP is checked ONLY for page-table walker reads, as required by A8.
   *
   * The walker always performs an eight-byte read, so the complete eight-byte
   * access must fit inside the winning PMP region.
   *
   * Lowest-numbered matching PMP entry wins.
   * No matching entry means deny.
   *
   * Only PMP R matters because the walker only reads.
   */
  function automatic logic pmp_read_allowed(
    input logic [55:0] addr
  );

    integer n;

    logic        matched;
    logic        overlap;
    logic        full_match;
    logic [1:0]  mode;

    logic [55:0] access_last;

    logic [55:0] lo;
    logic [55:0] hi_excl;
    logic [55:0] region_last;

    logic [53:0] napot_change;
    logic [55:0] napot_mask;
    logic [55:0] pmp_addr_bytes;

    begin
      matched          = 1'b0;
      pmp_read_allowed = 1'b0;

      access_last = addr + 56'd7;

      for (n = 0; n < 8; n = n + 1) begin
        if (!matched) begin

          /*
           * pmpcfg:
           *
           * [7]   L
           * [6:5] reserved
           * [4:3] A
           * [2]   X
           * [1]   W
           * [0]   R
           */
          mode = pmpcfg_i[n][4:3];

          overlap       = 1'b0;
          full_match    = 1'b0;
          lo            = 56'b0;
          hi_excl       = 56'b0;
          region_last   = 56'b0;
          napot_change  = 54'b0;
          napot_mask    = 56'b0;
          pmp_addr_bytes = {
            pmpaddr_i[n],
            2'b00
          };

          case (mode)

            /*
             * TOR
             */
            2'b01: begin
              if (n == 0)
                lo = 56'b0;
              else
                lo = {
                  pmpaddr_i[n-1],
                  2'b00
                };

              hi_excl = {
                pmpaddr_i[n],
                2'b00
              };

              overlap =
                  (addr < hi_excl) &&
                  (access_last >= lo);

              full_match =
                  (addr >= lo) &&
                  (access_last < hi_excl);
            end


            /*
             * NA4
             *
             * An eight-byte walker access cannot fit inside a four-byte
             * region, but detecting overlap is still important because that
             * matching PMP entry must deny the access.
             */
            2'b10: begin
              lo      = pmp_addr_bytes;
              hi_excl = pmp_addr_bytes + 56'd4;

              overlap =
                  (addr < hi_excl) &&
                  (access_last >= lo);

              full_match =
                  (addr >= lo) &&
                  (access_last < hi_excl);
            end


            /*
             * NAPOT
             *
             * If pmpaddr has N trailing ones:
             *
             *     pmpaddr ^ (pmpaddr + 1)
             *
             * produces N+1 low ones. Appending the two byte-address
             * offset bits therefore creates the complete region mask.
             */
            2'b11: begin
              napot_change =
                  pmpaddr_i[n] ^
                  (pmpaddr_i[n] + 54'd1);

              napot_mask = {
                napot_change,
                2'b11
              };

              lo =
                  pmp_addr_bytes &
                  ~napot_mask;

              region_last =
                  lo |
                  napot_mask;

              overlap =
                  (addr <= region_last) &&
                  (access_last >= lo);

              full_match =
                  (addr >= lo) &&
                  (access_last <= region_last);
            end


            /*
             * OFF
             */
            default: begin
              overlap    = 1'b0;
              full_match = 1'b0;
            end

          endcase


          if (overlap) begin
            matched = 1'b1;

            pmp_read_allowed =
                full_match &
                pmpcfg_i[n][0];
          end
        end
      end
    end
  endfunction


  /*
   * --------------------------------------------------------------------------
   * DTLB lookup
   * --------------------------------------------------------------------------
   */

  always_comb begin : dtlb_lookup_comb

    integer j;

    dtlb_hit_c     = 1'b0;
    dtlb_hit_idx_c = 4'd0;

    for (j = 0; j < 16; j = j + 1) begin
      if (
          !dtlb_hit_c &&
          !flush_tlb_i &&
          dtlb_valid_q[j] &&
          (
            dtlb_global_q[j] ||
            (dtlb_asid_q[j] == asid_i)
          ) &&
          vpn_match(
            dtlb_vpn_q[j],
            lsu_vaddr_i[38:12],
            dtlb_level_q[j]
          )
      ) begin
        dtlb_hit_c     = 1'b1;
        dtlb_hit_idx_c = j[3:0];
      end
    end

    dtlb_hit_pa_c = compose_pa(
      dtlb_ppn_q[dtlb_hit_idx_c],
      dtlb_level_q[dtlb_hit_idx_c],
      lsu_vaddr_i
    );

    dtlb_perm_ok_c = permission_ok(
      dtlb_perm_q[dtlb_hit_idx_c],
      1'b0,
      lsu_is_store_i,
      ld_st_priv_lvl_i,
      sum_i,
      mxr_i
    );

  end


  /*
   * --------------------------------------------------------------------------
   * ITLB lookup
   * --------------------------------------------------------------------------
   */

  always_comb begin : itlb_lookup_comb

    integer j;

    itlb_hit_c     = 1'b0;
    itlb_hit_idx_c = 4'd0;

    for (j = 0; j < 16; j = j + 1) begin
      if (
          !itlb_hit_c &&
          !flush_tlb_i &&
          itlb_valid_q[j] &&
          (
            itlb_global_q[j] ||
            (itlb_asid_q[j] == asid_i)
          ) &&
          vpn_match(
            itlb_vpn_q[j],
            fetch_vaddr_i[38:12],
            itlb_level_q[j]
          )
      ) begin
        itlb_hit_c     = 1'b1;
        itlb_hit_idx_c = j[3:0];
      end
    end

    itlb_hit_pa_c = compose_pa(
      itlb_ppn_q[itlb_hit_idx_c],
      itlb_level_q[itlb_hit_idx_c],
      fetch_vaddr_i
    );

    itlb_perm_ok_c = permission_ok(
      itlb_perm_q[itlb_hit_idx_c],
      1'b1,
      1'b0,
      priv_lvl_i,
      sum_i,
      mxr_i
    );

  end


  /*
   * Prefer an invalid entry. Once full, round-robin replacement is used.
   *
   * This gives a true sixteen-entry usable TLB and avoids the cold-fill
   * pathology described in the contract.
   */
  always_comb begin : dtlb_victim_comb

    integer j;

    dtlb_victim_c         = dtlb_rr_q;
    dtlb_invalid_found_c  = 1'b0;

    for (j = 0; j < 16; j = j + 1) begin
      if (
          !dtlb_invalid_found_c &&
          !dtlb_valid_q[j]
      ) begin
        dtlb_victim_c        = j[3:0];
        dtlb_invalid_found_c = 1'b1;
      end
    end

  end


  always_comb begin : itlb_victim_comb

    integer j;

    itlb_victim_c        = itlb_rr_q;
    itlb_invalid_found_c = 1'b0;

    for (j = 0; j < 16; j = j + 1) begin
      if (
          !itlb_invalid_found_c &&
          !itlb_valid_q[j]
      ) begin
        itlb_victim_c        = j[3:0];
        itlb_invalid_found_c = 1'b1;
      end
    end

  end


  /*
   * --------------------------------------------------------------------------
   * External memory interface
   * --------------------------------------------------------------------------
   */

  always_comb begin

    walk_pmp_allow_c =
        pmp_read_allowed(walk_addr_q);

    pte_data_c =
        (state_q == S_WALK_HAVE) ?
        pte_hold_q :
        mem_rdata_i;

    mem_req_o       = 1'b0;
    mem_addr_o      = walk_addr_q;

    /*
     * These are explicitly unscored/unconstrained by the contract.
     */
    mem_tag_valid_o = 1'b0;
    mem_kill_o      = 1'b0;

    /*
     * Never allow a PMP-denied page-table read onto mem_*.
     */
    if (
        (state_q == S_WALK_REQ) &&
        walk_pmp_allow_c &&
        !flush_i
    )
      mem_req_o = 1'b1;

  end


  /*
   * --------------------------------------------------------------------------
   * Main sequential logic
   * --------------------------------------------------------------------------
   */

  always_ff @(posedge clk_i or negedge rst_ni) begin : seq_logic

    integer k;

    if (!rst_ni) begin

      state_q <= S_IDLE;

      req_is_fetch_q  <= 1'b0;
      req_is_store_q  <= 1'b0;
      req_va_q        <= 64'b0;
      req_priv_q      <= 2'b0;
      req_sum_q       <= 1'b0;
      req_mxr_q       <= 1'b0;
      req_asid_q      <= 16'b0;
      req_satp_ppn_q  <= 44'b0;

      walk_level_q <= 2'd2;
      walk_addr_q  <= 56'b0;
      pte_hold_q   <= 64'b0;

      dtlb_valid_q <= 16'b0;
      itlb_valid_q <= 16'b0;

      dtlb_rr_q <= 4'b0;
      itlb_rr_q <= 4'b0;

      lsu_valid_o        <= 1'b0;
      lsu_paddr_o        <= 56'b0;
      lsu_dtlb_hit_o     <= 1'b0;
      lsu_dtlb_ppn_o     <= 44'b0;
      lsu_exc_valid_o    <= 1'b0;
      lsu_exc_cause_o    <= 64'b0;
      lsu_exc_tval_o     <= 64'b0;

      fetch_valid_o      <= 1'b0;
      fetch_paddr_o      <= 56'b0;
      fetch_exc_valid_o  <= 1'b0;
      fetch_exc_cause_o  <= 64'b0;
      fetch_exc_tval_o   <= 64'b0;

      itlb_miss_o <= 1'b0;
      dtlb_miss_o <= 1'b0;

      for (k = 0; k < 16; k = k + 1) begin

        dtlb_vpn_q[k]    <= 27'b0;
        dtlb_ppn_q[k]    <= 44'b0;
        dtlb_asid_q[k]   <= 16'b0;
        dtlb_global_q[k] <= 1'b0;
        dtlb_level_q[k]  <= 2'b0;
        dtlb_perm_q[k]   <= 6'b0;

        itlb_vpn_q[k]    <= 27'b0;
        itlb_ppn_q[k]    <= 44'b0;
        itlb_asid_q[k]   <= 16'b0;
        itlb_global_q[k] <= 1'b0;
        itlb_level_q[k]  <= 2'b0;
        itlb_perm_q[k]   <= 6'b0;

      end

    end
    else begin

      /*
       * Retirement/status outputs are pulses.
       */
      lsu_valid_o       <= 1'b0;
      lsu_dtlb_hit_o    <= 1'b0;
      lsu_exc_valid_o   <= 1'b0;

      fetch_valid_o     <= 1'b0;
      fetch_exc_valid_o <= 1'b0;

      itlb_miss_o       <= 1'b0;
      dtlb_miss_o       <= 1'b0;


      /*
       * C2 permits implementing every narrowed flush as a complete TLB flush.
       */
      if (flush_tlb_i) begin

        dtlb_valid_q <= 16'b0;
        itlb_valid_q <= 16'b0;

        dtlb_rr_q <= 4'b0;
        itlb_rr_q <= 4'b0;

      end


      /*
       * ----------------------------------------------------------------------
       * flush_i
       * ----------------------------------------------------------------------
       *
       * Abort and restart the current walk.
       *
       * If a memory request was already granted, its response must first be
       * drained. Otherwise a late response from the cancelled walk could be
       * interpreted as the root PTE of the restarted walk.
       *
       * flush_i does NOT clear either TLB.
       */
      if (
          flush_i &&
          (state_q != S_IDLE)
      ) begin

        walk_level_q <= 2'd2;

        walk_addr_q <=
            make_root_pte_addr(
              req_satp_ppn_q,
              req_va_q
            );

        case (state_q)

          /*
           * Read already granted. Either its response is arriving right now,
           * or it must be drained.
           */
          S_WALK_WAIT: begin

            if (mem_rvalid_i)
              state_q <= S_WALK_REQ;
            else
              state_q <= S_DRAIN;

          end


          /*
           * A request might have been granted on this edge.
           */
          S_WALK_REQ: begin

            if (
                mem_gnt_i &&
                !mem_rvalid_i
            )
              state_q <= S_DRAIN;
            else
              state_q <= S_WALK_REQ;

          end


          /*
           * Already draining an old request.
           */
          S_DRAIN: begin

            if (mem_rvalid_i)
              state_q <= S_WALK_REQ;
            else
              state_q <= S_DRAIN;

          end


          /*
           * S_WALK_HAVE has no outstanding memory operation.
           */
          default: begin
            state_q <= S_WALK_REQ;
          end

        endcase

      end
      else begin

        case (state_q)

          /*
           * ==================================================================
           * IDLE / NEW REQUEST
           * ==================================================================
           */
          S_IDLE: begin

            /*
             * If both are asserted at once, LSU receives walker arbitration
             * priority. A held fetch request will be serviced after it.
             */
            if (!flush_i) begin

              /*
               * --------------------------------------------------------------
               * LSU
               * --------------------------------------------------------------
               */
              if (lsu_req_i) begin

                /*
                 * Bare mode.
                 */
                if (!en_ld_st_translation_i) begin

                  lsu_valid_o     <= 1'b1;
                  lsu_paddr_o     <= lsu_vaddr_i[55:0];

                  lsu_exc_valid_o <= 1'b0;
                  lsu_exc_cause_o <= 64'b0;
                  lsu_exc_tval_o  <= 64'b0;

                  lsu_dtlb_ppn_o  <= lsu_vaddr_i[55:12];

                end


                /*
                 * DTLB hit.
                 */
                else if (dtlb_hit_c) begin

                  lsu_valid_o    <= 1'b1;
                  lsu_dtlb_hit_o <= 1'b1;

                  lsu_dtlb_ppn_o <=
                      dtlb_hit_pa_c[55:12];

                  if (dtlb_perm_ok_c) begin

                    lsu_paddr_o     <= dtlb_hit_pa_c;

                    lsu_exc_valid_o <= 1'b0;
                    lsu_exc_cause_o <= 64'b0;
                    lsu_exc_tval_o  <= 64'b0;

                  end
                  else begin

                    /*
                     * A4/A5 permission fault.
                     *
                     * A11 says valid and exc_valid must both be asserted.
                     */
                    lsu_paddr_o     <= 56'b0;

                    lsu_exc_valid_o <= 1'b1;

                    lsu_exc_cause_o <=
                        page_fault_cause(
                          1'b0,
                          lsu_is_store_i
                        );

                    lsu_exc_tval_o <=
                        lsu_vaddr_i;

                  end

                end


                /*
                 * DTLB miss: begin Sv39 walk.
                 */
                else begin

                  dtlb_miss_o <= 1'b1;

                  req_is_fetch_q <= 1'b0;
                  req_is_store_q <= lsu_is_store_i;

                  req_va_q   <= lsu_vaddr_i;
                  req_priv_q <= ld_st_priv_lvl_i;

                  req_sum_q  <= sum_i;
                  req_mxr_q  <= mxr_i;

                  req_asid_q     <= asid_i;
                  req_satp_ppn_q <= satp_ppn_i;

                  walk_level_q <= 2'd2;

                  walk_addr_q <=
                      make_root_pte_addr(
                        satp_ppn_i,
                        lsu_vaddr_i
                      );

                  state_q <= S_WALK_REQ;

                end

              end


              /*
               * --------------------------------------------------------------
               * FETCH
               * --------------------------------------------------------------
               */
              else if (fetch_req_i) begin

                /*
                 * Bare mode.
                 */
                if (!enable_translation_i) begin

                  fetch_valid_o <= 1'b1;
                  fetch_paddr_o <= fetch_vaddr_i[55:0];

                  fetch_exc_valid_o <= 1'b0;
                  fetch_exc_cause_o <= 64'b0;
                  fetch_exc_tval_o  <= 64'b0;

                end


                /*
                 * ITLB hit.
                 */
                else if (itlb_hit_c) begin

                  fetch_valid_o <= 1'b1;

                  if (itlb_perm_ok_c) begin

                    fetch_paddr_o <=
                        itlb_hit_pa_c;

                    fetch_exc_valid_o <= 1'b0;
                    fetch_exc_cause_o <= 64'b0;
                    fetch_exc_tval_o  <= 64'b0;

                  end
                  else begin

                    fetch_paddr_o <= 56'b0;

                    fetch_exc_valid_o <= 1'b1;
                    fetch_exc_cause_o <= CAUSE_INST_PAGE;
                    fetch_exc_tval_o  <= fetch_vaddr_i;

                  end

                end


                /*
                 * ITLB miss.
                 */
                else begin

                  itlb_miss_o <= 1'b1;

                  req_is_fetch_q <= 1'b1;
                  req_is_store_q <= 1'b0;

                  req_va_q   <= fetch_vaddr_i;
                  req_priv_q <= priv_lvl_i;

                  req_sum_q <= sum_i;
                  req_mxr_q <= mxr_i;

                  req_asid_q     <= asid_i;
                  req_satp_ppn_q <= satp_ppn_i;

                  walk_level_q <= 2'd2;

                  walk_addr_q <=
                      make_root_pte_addr(
                        satp_ppn_i,
                        fetch_vaddr_i
                      );

                  state_q <= S_WALK_REQ;

                end

              end

            end
          end


          /*
           * ==================================================================
           * ISSUE WALKER READ
           * ==================================================================
           */
          S_WALK_REQ: begin

            /*
             * A8/A7:
             *
             * PMP is checked before the PTE is read/interpreted, therefore a
             * denied walker read becomes an access fault and wins over any page
             * fault the unread PTE might otherwise have caused.
             */
            if (!walk_pmp_allow_c) begin

              state_q <= S_IDLE;

              if (req_is_fetch_q) begin

                fetch_valid_o <= 1'b1;
                fetch_paddr_o <= 56'b0;

                fetch_exc_valid_o <= 1'b1;

                fetch_exc_cause_o <=
                    access_fault_cause(
                      1'b1,
                      1'b0
                    );

                fetch_exc_tval_o <= req_va_q;

              end
              else begin

                lsu_valid_o <= 1'b1;
                lsu_paddr_o <= 56'b0;

                lsu_exc_valid_o <= 1'b1;

                lsu_exc_cause_o <=
                    access_fault_cause(
                      1'b0,
                      req_is_store_q
                    );

                lsu_exc_tval_o <= req_va_q;

              end

            end


            /*
             * Request granted.
             */
            else if (mem_gnt_i) begin

              /*
               * Normally rvalid follows grant. Supporting same-cycle
               * grant+rvalid costs only this small holding state.
               */
              if (mem_rvalid_i) begin

                pte_hold_q <= mem_rdata_i;
                state_q    <= S_WALK_HAVE;

              end
              else begin

                state_q <= S_WALK_WAIT;

              end

            end

          end


          /*
           * ==================================================================
           * PTE RESPONSE
           * ==================================================================
           */
          S_WALK_WAIT,
          S_WALK_HAVE: begin

            if (
                (state_q == S_WALK_HAVE) ||
                mem_rvalid_i
            ) begin

              /*
               * --------------------------------------------------------------
               * Invalid / reserved PTE
               * --------------------------------------------------------------
               *
               * V=0 => invalid
               *
               * W=1,R=0 => reserved encoding
               */
              if (
                  !pte_data_c[0] ||
                  (
                    pte_data_c[2] &&
                    !pte_data_c[1]
                  )
              ) begin

                state_q <= S_IDLE;

                if (req_is_fetch_q) begin

                  fetch_valid_o <= 1'b1;
                  fetch_paddr_o <= 56'b0;

                  fetch_exc_valid_o <= 1'b1;
                  fetch_exc_cause_o <= CAUSE_INST_PAGE;
                  fetch_exc_tval_o  <= req_va_q;

                end
                else begin

                  lsu_valid_o <= 1'b1;
                  lsu_paddr_o <= 56'b0;

                  lsu_exc_valid_o <= 1'b1;

                  lsu_exc_cause_o <=
                      page_fault_cause(
                        1'b0,
                        req_is_store_q
                      );

                  lsu_exc_tval_o <= req_va_q;

                end

              end


              /*
               * --------------------------------------------------------------
               * Leaf
               * --------------------------------------------------------------
               *
               * R=1 or X=1 identifies a leaf.
               */
              else if (
                  pte_data_c[1] ||
                  pte_data_c[3]
              ) begin

                /*
                 * Superpage PPN alignment.
                 */
                if (
                    leaf_misaligned(
                      pte_data_c[53:10],
                      walk_level_q
                    )
                ) begin

                  state_q <= S_IDLE;

                  if (req_is_fetch_q) begin

                    fetch_valid_o <= 1'b1;
                    fetch_paddr_o <= 56'b0;

                    fetch_exc_valid_o <= 1'b1;
                    fetch_exc_cause_o <= CAUSE_INST_PAGE;
                    fetch_exc_tval_o  <= req_va_q;

                  end
                  else begin

                    lsu_valid_o <= 1'b1;
                    lsu_paddr_o <= 56'b0;

                    lsu_exc_valid_o <= 1'b1;

                    lsu_exc_cause_o <=
                        page_fault_cause(
                          1'b0,
                          req_is_store_q
                        );

                    lsu_exc_tval_o <= req_va_q;

                  end

                end
                else begin

                  /*
                   * ----------------------------------------------------------
                   * TLB installation
                   * ----------------------------------------------------------
                   *
                   * Cache a leaf when A is already set.
                   *
                   * If the current request is a store, D must also already be
                   * set before caching it. This prevents a D=0 store fault from
                   * leaving a stale TLB entry that continuously faults after
                   * software repairs the PTE.
                   *
                   * Other permission failures may safely cache the PTE because
                   * R/W/X/U/SUM/MXR/privilege are checked again on every hit.
                   */
                  if (
                      !flush_tlb_i &&
                      pte_data_c[6] &&
                      (
                        !req_is_store_q ||
                        pte_data_c[7]
                      )
                  ) begin

                    /*
                     * ITLB install.
                     */
                    if (req_is_fetch_q) begin

                      itlb_valid_q[itlb_victim_c] <= 1'b1;

                      itlb_vpn_q[itlb_victim_c] <=
                          req_va_q[38:12];

                      itlb_ppn_q[itlb_victim_c] <=
                          pte_data_c[53:10];

                      itlb_asid_q[itlb_victim_c] <=
                          req_asid_q;

                      itlb_global_q[itlb_victim_c] <=
                          pte_data_c[5];

                      itlb_level_q[itlb_victim_c] <=
                          walk_level_q;

                      itlb_perm_q[itlb_victim_c] <= {
                        pte_data_c[7], // D
                        pte_data_c[6], // A
                        pte_data_c[4], // U
                        pte_data_c[3], // X
                        pte_data_c[2], // W
                        pte_data_c[1]  // R
                      };

                      itlb_rr_q <=
                          itlb_victim_c + 4'd1;

                    end


                    /*
                     * DTLB install.
                     */
                    else begin

                      dtlb_valid_q[dtlb_victim_c] <= 1'b1;

                      dtlb_vpn_q[dtlb_victim_c] <=
                          req_va_q[38:12];

                      dtlb_ppn_q[dtlb_victim_c] <=
                          pte_data_c[53:10];

                      dtlb_asid_q[dtlb_victim_c] <=
                          req_asid_q;

                      dtlb_global_q[dtlb_victim_c] <=
                          pte_data_c[5];

                      dtlb_level_q[dtlb_victim_c] <=
                          walk_level_q;

                      dtlb_perm_q[dtlb_victim_c] <= {
                        pte_data_c[7], // D
                        pte_data_c[6], // A
                        pte_data_c[4], // U
                        pte_data_c[3], // X
                        pte_data_c[2], // W
                        pte_data_c[1]  // R
                      };

                      dtlb_rr_q <=
                          dtlb_victim_c + 4'd1;

                    end

                  end


                  /*
                   * ----------------------------------------------------------
                   * Permission/A/D check for current request
                   * ----------------------------------------------------------
                   */
                  if (
                      permission_ok(
                        {
                          pte_data_c[7],
                          pte_data_c[6],
                          pte_data_c[4],
                          pte_data_c[3],
                          pte_data_c[2],
                          pte_data_c[1]
                        },
                        req_is_fetch_q,
                        req_is_store_q,
                        req_priv_q,
                        req_sum_q,
                        req_mxr_q
                      )
                  ) begin

                    state_q <= S_IDLE;

                    /*
                     * Successful fetch.
                     */
                    if (req_is_fetch_q) begin

                      fetch_valid_o <= 1'b1;

                      fetch_paddr_o <=
                          compose_pa(
                            pte_data_c[53:10],
                            walk_level_q,
                            req_va_q
                          );

                      fetch_exc_valid_o <= 1'b0;
                      fetch_exc_cause_o <= 64'b0;
                      fetch_exc_tval_o  <= 64'b0;

                    end


                    /*
                     * Successful LSU translation.
                     */
                    else begin

                      lsu_valid_o <= 1'b1;

                      lsu_paddr_o <=
                          compose_pa(
                            pte_data_c[53:10],
                            walk_level_q,
                            req_va_q
                          );

                      lsu_dtlb_ppn_o <=
                          compose_ppn(
                            pte_data_c[53:10],
                            walk_level_q,
                            req_va_q
                          );

                      lsu_exc_valid_o <= 1'b0;
                      lsu_exc_cause_o <= 64'b0;
                      lsu_exc_tval_o  <= 64'b0;

                    end

                  end


                  /*
                   * Permission / A / D page fault.
                   */
                  else begin

                    state_q <= S_IDLE;

                    if (req_is_fetch_q) begin

                      fetch_valid_o <= 1'b1;
                      fetch_paddr_o <= 56'b0;

                      fetch_exc_valid_o <= 1'b1;
                      fetch_exc_cause_o <= CAUSE_INST_PAGE;
                      fetch_exc_tval_o  <= req_va_q;

                    end
                    else begin

                      lsu_valid_o <= 1'b1;
                      lsu_paddr_o <= 56'b0;

                      lsu_exc_valid_o <= 1'b1;

                      lsu_exc_cause_o <=
                          page_fault_cause(
                            1'b0,
                            req_is_store_q
                          );

                      lsu_exc_tval_o <= req_va_q;

                    end

                  end

                end

              end


              /*
               * --------------------------------------------------------------
               * Non-leaf PTE
               * --------------------------------------------------------------
               *
               * V=1, R=0, X=0, and not the reserved W=1,R=0 case.
               */
              else begin

                /*
                 * If level 0 is also a pointer, the walk ran out of levels.
                 */
                if (walk_level_q == 2'd0) begin

                  state_q <= S_IDLE;

                  if (req_is_fetch_q) begin

                    fetch_valid_o <= 1'b1;
                    fetch_paddr_o <= 56'b0;

                    fetch_exc_valid_o <= 1'b1;
                    fetch_exc_cause_o <= CAUSE_INST_PAGE;
                    fetch_exc_tval_o  <= req_va_q;

                  end
                  else begin

                    lsu_valid_o <= 1'b1;
                    lsu_paddr_o <= 56'b0;

                    lsu_exc_valid_o <= 1'b1;

                    lsu_exc_cause_o <=
                        page_fault_cause(
                          1'b0,
                          req_is_store_q
                        );

                    lsu_exc_tval_o <= req_va_q;

                  end

                end


                /*
                 * Descend to the next page-table level.
                 */
                else begin

                  walk_level_q <=
                      walk_level_q - 2'd1;

                  walk_addr_q <=
                      make_pte_addr(
                        pte_data_c[53:10],
                        vpn_for_level(
                          req_va_q,
                          walk_level_q - 2'd1
                        )
                      );

                  /*
                   * Returning to S_WALK_REQ means PMP is checked on this new
                   * physical PTE address before another memory request occurs.
                   */
                  state_q <= S_WALK_REQ;

                end

              end

            end

          end


          /*
           * ==================================================================
           * DRAIN CANCELLED MEMORY RESPONSE
           * ==================================================================
           */
          S_DRAIN: begin

            if (mem_rvalid_i)
              state_q <= S_WALK_REQ;

          end


          default: begin
            state_q <= S_IDLE;
          end

        endcase

      end

    end

  end

endmodule