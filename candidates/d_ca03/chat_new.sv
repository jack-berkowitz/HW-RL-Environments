// Sv39 MMU: separate 16-entry fully associative ITLB/DTLB, one walker.
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
    logic [26:0] vpn;
    logic [43:0] ppn;
    logic [15:0] asid;
    logic [7:0] flags;
    logic [1:0] level;
    logic global_page;
  } entry_t;
  entry_t itlb[16], dtlb[16];
  logic [15:0] iv, dv;
  logic [3:0] inext, dnext;
  typedef enum logic [2:0] {IDLE, READ_REQ, READ_WAIT, CHECK_PTE,
                           DRAIN, RESTART} walk_state_t;
  walk_state_t state_q;
  logic active_fetch, active_store;
  logic [63:0] active_va, pte_q;
  logic [15:0] active_asid;
  logic [1:0] active_priv, level_q;
  logic active_sum, active_mxr, global_q;
  logic [55:0] walk_addr;
  logic prefer_fetch;

  logic selected_fetch, selected_present, selected_enable, hit;
  logic [63:0] selected_va;
  logic [1:0] selected_priv;
  logic selected_store;
  entry_t hit_entry;
  logic [3:0] insert_index;
  logic empty_found;
  logic pmp_allowed;
  logic leaf, invalid_pte, misaligned, permission_ok;
  logic [55:0] leaf_pa;

  function automatic logic vpn_match(input entry_t e, input logic [63:0] va);
    case (e.level)
      2'd2: return e.vpn[26:18] == va[38:30];
      2'd1: return e.vpn[26:9] == va[38:21];
      default: return e.vpn == va[38:12];
    endcase
  endfunction
  function automatic logic [55:0] physical_address(
    input logic [43:0] ppn, input logic [1:0] level,
    input logic [63:0] va);
    case (level)
      2'd2: return {ppn[43:18],va[29:0]};
      2'd1: return {ppn[43:9],va[20:0]};
      default: return {ppn,va[11:0]};
    endcase
  endfunction
  function automatic logic permissions(
    input logic [7:0] flags, input logic fetch, input logic store_access,
    input logic [1:0] privilege, input logic sum_enable, input logic mxr_enable);
    logic ok;
    begin
      ok = flags[0] && !(flags[2] && !flags[1]) && flags[6];
      if (fetch) ok = ok && flags[3];
      else if (store_access) ok = ok && flags[2] && flags[7];
      else ok = ok && (flags[1] || (flags[3] && mxr_enable));
      if (privilege == 2'b00) ok = ok && flags[4];
      if (privilege == 2'b01 && flags[4]) ok = ok && !fetch && sum_enable;
      return ok;
    end
  endfunction
  function automatic logic [63:0] fault_cause(
    input logic fetch, input logic store_access, input logic access_fault);
    if (fetch) return access_fault ? 64'd1 : 64'd12;
    if (store_access) return access_fault ? 64'd7 : 64'd15;
    return access_fault ? 64'd5 : 64'd13;
  endfunction

  // The walk is a read, regardless of the initiating instruction type.
  // PMP priority is lowest entry number. The contract checks the read address;
  // it does not apply PMP to the final translated address or to TLB hits.
  always_comb begin : pmp_lookup
    logic matched, region_match;
    logic [55:0] lower_bound, upper_bound;
    logic [53:0] compare_mask;
    matched = 1'b0;
    pmp_allowed = 1'b0;
    lower_bound = '0;
    upper_bound = '0;
    compare_mask = '0;
    region_match = 1'b0;
    for (int unsigned n=0;n<8;n++) begin
      upper_bound = {pmpaddr_i[n],2'b0};
      // p XOR (p+1) covers its trailing ones AND their next zero.
      // Ignoring these address/4 bits produces the NAPOT region mask.
      compare_mask = ~(pmpaddr_i[n] ^ (pmpaddr_i[n]+54'd1));
      case (pmpcfg_i[n][4:3])
        2'd1: region_match = walk_addr >= lower_bound && walk_addr < upper_bound;
        2'd2: region_match = walk_addr[55:2] == pmpaddr_i[n];
        2'd3: region_match = (walk_addr[55:2] & compare_mask) == (pmpaddr_i[n] & compare_mask);
        default: region_match = 1'b0;
      endcase
      if (!matched && region_match) begin
        matched = 1'b1;
        pmp_allowed = pmpcfg_i[n][0];
      end
      lower_bound = upper_bound;
    end
  end

  always_comb begin : tlb_lookup
    selected_fetch = fetch_req_i && !fetch_valid_o &&
                     (!(lsu_req_i && !lsu_valid_o) || prefer_fetch);
    selected_present = selected_fetch ? fetch_req_i && !fetch_valid_o : lsu_req_i && !lsu_valid_o;
    selected_va = selected_fetch ? fetch_vaddr_i : lsu_vaddr_i;
    selected_enable = selected_fetch ? enable_translation_i : en_ld_st_translation_i;
    selected_priv = selected_fetch ? priv_lvl_i : ld_st_priv_lvl_i;
    selected_store = !selected_fetch && lsu_is_store_i;
    hit = 1'b0;
    hit_entry = '0;
    for (int unsigned n=0;n<16;n++) begin
      if (selected_fetch) begin
        if (iv[n] && (itlb[n].global_page || itlb[n].asid == asid_i) && vpn_match(itlb[n],selected_va)) begin
          hit = 1'b1; hit_entry = itlb[n];
        end
      end else begin
        if (dv[n] && (dtlb[n].global_page || dtlb[n].asid == asid_i) && vpn_match(dtlb[n],selected_va)) begin
          hit = 1'b1; hit_entry = dtlb[n];
        end
      end
    end
    insert_index = active_fetch ? inext : dnext;
    empty_found = 1'b0;
    for (int unsigned n=0;n<16;n++) begin
      if (!(active_fetch ? iv[n] : dv[n]) && !empty_found) begin
        insert_index = 4'(n); empty_found = 1'b1;
      end
    end
  end

  assign leaf = pte_q[1] || pte_q[3];
  assign invalid_pte = !pte_q[0] || (pte_q[2] && !pte_q[1]);
  assign misaligned = (level_q == 2 && |pte_q[27:10]) ||
                      (level_q == 1 && |pte_q[18:10]);
  assign permission_ok = permissions(pte_q[7:0],active_fetch,active_store,active_priv,active_sum,active_mxr);
  assign leaf_pa = physical_address(pte_q[53:10],level_q,active_va);
  assign mem_req_o = rst_ni && !flush_i && !flush_tlb_i && state_q == READ_REQ && pmp_allowed;
  assign mem_addr_o = walk_addr;
  assign mem_tag_valid_o = mem_req_o;
  // Granted reads are drained, not cancelled through an unspecified sideband.
  assign mem_kill_o = 1'b0;

  task automatic retire(
    input logic fetch, input logic [63:0] va, input logic [55:0] pa,
    input logic exception, input logic [63:0] cause);
    begin
      if (fetch) begin
        fetch_valid_o <= 1'b1; fetch_paddr_o <= pa;
        fetch_exc_valid_o <= exception;
        fetch_exc_cause_o <= exception ? cause : 64'b0;
        fetch_exc_tval_o <= exception ? va : 64'b0;
      end else begin
        lsu_valid_o <= 1'b1; lsu_paddr_o <= pa;
        lsu_exc_valid_o <= exception;
        lsu_exc_cause_o <= exception ? cause : 64'b0;
        lsu_exc_tval_o <= exception ? va : 64'b0;
        lsu_dtlb_ppn_o <= pa[55:12];
      end
    end
  endtask

  always_ff @(posedge clk_i or negedge rst_ni) begin : sequencer
    entry_t new_entry;
    if (!rst_ni) begin
      iv <= '0; dv <= '0; inext <= '0; dnext <= '0;
      state_q <= IDLE; prefer_fetch <= 1'b0;
      active_fetch <= 0; active_store <= 0; active_va <= 0;
      active_asid <= 0; active_priv <= 0; active_sum <= 0; active_mxr <= 0;
      level_q <= 2; walk_addr <= 0; pte_q <= 0; global_q <= 0;
      lsu_valid_o <= 0; lsu_paddr_o <= 0; lsu_dtlb_hit_o <= 0; lsu_dtlb_ppn_o <= 0;
      lsu_exc_valid_o <= 0; lsu_exc_cause_o <= 0; lsu_exc_tval_o <= 0;
      fetch_valid_o <= 0; fetch_paddr_o <= 0;
      fetch_exc_valid_o <= 0; fetch_exc_cause_o <= 0; fetch_exc_tval_o <= 0;
      itlb_miss_o <= 0; dtlb_miss_o <= 0;
    end else begin
      lsu_valid_o <= 0; fetch_valid_o <= 0;
      lsu_exc_valid_o <= 0; fetch_exc_valid_o <= 0;
      lsu_exc_cause_o <= 0; fetch_exc_cause_o <= 0;
      lsu_dtlb_hit_o <= 0; itlb_miss_o <= 0; dtlb_miss_o <= 0;
      if (flush_tlb_i) begin
        iv <= '0; dv <= '0; inext <= '0; dnext <= '0;
      end
      if (flush_i || flush_tlb_i) begin
        if (state_q != IDLE) begin
          if ((state_q == READ_WAIT || state_q == DRAIN) && !mem_rvalid_i)
            state_q <= DRAIN;
          else state_q <= RESTART;
        end
      end else begin
        case (state_q)
          IDLE: if (selected_present) begin
            prefer_fetch <= !selected_fetch;
            if (!selected_enable) begin
              retire(selected_fetch,selected_va,selected_va[55:0],1'b0,64'b0);
            end else if (hit) begin
              retire(selected_fetch,selected_va,physical_address(hit_entry.ppn,hit_entry.level,selected_va),
                     !permissions(hit_entry.flags,selected_fetch,selected_store,selected_priv,sum_i,mxr_i),
                     fault_cause(selected_fetch,selected_store,1'b0));
              if (!selected_fetch) lsu_dtlb_hit_o <= 1'b1;
            end else begin
              active_fetch <= selected_fetch; active_store <= selected_store;
              active_va <= selected_va; active_asid <= asid_i;
              active_priv <= selected_priv; active_sum <= sum_i; active_mxr <= mxr_i;
              global_q <= 0; level_q <= 2;
              walk_addr <= {satp_ppn_i,selected_va[38:30],3'b0};
              state_q <= READ_REQ;
              if (selected_fetch) itlb_miss_o <= 1'b1; else dtlb_miss_o <= 1'b1;
            end
          end
          READ_REQ: begin
            if (!pmp_allowed) begin
              retire(active_fetch,active_va,56'b0,1'b1,fault_cause(active_fetch,active_store,1'b1));
              state_q <= IDLE;
            end else if (mem_gnt_i) begin
              if (mem_rvalid_i) begin pte_q <= mem_rdata_i; state_q <= CHECK_PTE; end
              else state_q <= READ_WAIT;
            end
          end
          READ_WAIT: if (mem_rvalid_i) begin pte_q <= mem_rdata_i; state_q <= CHECK_PTE; end
          CHECK_PTE: begin
            if (invalid_pte || (leaf && (misaligned || !permission_ok)) || (!leaf && level_q == 0)) begin
              retire(active_fetch,active_va,56'b0,1'b1,fault_cause(active_fetch,active_store,1'b0));
              state_q <= IDLE;
            end else if (leaf) begin
              new_entry.vpn = active_va[38:12]; new_entry.ppn = pte_q[53:10];
              new_entry.asid = active_asid; new_entry.flags = pte_q[7:0];
              new_entry.level = level_q; new_entry.global_page = global_q || pte_q[5];
              if (active_fetch) begin
                itlb[insert_index] <= new_entry; iv[insert_index] <= 1'b1; inext <= insert_index+4'd1;
              end else begin
                dtlb[insert_index] <= new_entry; dv[insert_index] <= 1'b1; dnext <= insert_index+4'd1;
              end
              retire(active_fetch,active_va,leaf_pa,1'b0,64'b0);
              state_q <= IDLE;
            end else begin
              global_q <= global_q || pte_q[5];
              if (level_q == 2) walk_addr <= {pte_q[53:10],active_va[29:21],3'b0};
              else walk_addr <= {pte_q[53:10],active_va[20:12],3'b0};
              level_q <= level_q-2'd1; state_q <= READ_REQ;
            end
          end
          DRAIN: if (mem_rvalid_i) state_q <= RESTART;
          RESTART: begin
            // Restart the held request without requiring a request edge.
            active_asid <= asid_i;
            active_priv <= active_fetch ? priv_lvl_i : ld_st_priv_lvl_i;
            active_sum <= sum_i; active_mxr <= mxr_i;
            walk_addr <= {satp_ppn_i,active_va[38:30],3'b0};
            global_q <= 0; level_q <= 2; state_q <= READ_REQ;
          end
          default: state_q <= IDLE;
        endcase
      end
    end
  end
endmodule
