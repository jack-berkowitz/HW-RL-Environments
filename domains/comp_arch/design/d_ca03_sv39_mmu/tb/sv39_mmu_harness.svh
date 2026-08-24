// sv39_mmu_harness.svh -- signals, DUT, memory model and the request task,
// shared by the capture rig and the scoring testbench. Included inside a module.
//
// PER-REQUEST MEMORY VISIBILITY is the capability two separate requirements need:
// T4's capacity check ("this replay must issue no page-table read") and L1's
// cycle axis. Counting mem_gnt pulses gives both, so the cost is shared rather
// than additive.

  logic clk = 1'b0, rst_n = 1'b0;
  always #5 clk = ~clk;

  logic        flush = 0, en_tr = 1, en_ldst = 1;
  logic        lsu_req = 0, lsu_is_store = 0, lsu_valid, lsu_dtlb_hit;
  logic [63:0] lsu_vaddr = 0;
  logic [55:0] lsu_paddr;
  logic [43:0] lsu_dtlb_ppn;
  logic        lsu_exc_valid;
  logic [63:0] lsu_exc_cause, lsu_exc_tval;
  logic        fetch_req = 0, fetch_valid, fetch_exc_valid;
  logic [63:0] fetch_vaddr = 0, fetch_exc_cause, fetch_exc_tval;
  logic [55:0] fetch_paddr;
  logic [1:0]  priv = 2'b00, ld_st_priv = 2'b00;
  logic        sum_b = 0, mxr_b = 0;
  logic [43:0] satp_ppn = 44'd1;
  logic [15:0] asid = 0, asid_flush = 0;
  logic        flush_tlb = 0;
  logic [63:0] vaddr_flush = 0;
  logic        itlb_miss, dtlb_miss;
  logic        mem_req, mem_tag_valid, mem_kill;
  logic [55:0] mem_addr;
  logic        mem_gnt = 0, mem_rvalid = 0;
  logic [63:0] mem_rdata = 0;
  logic [7:0][7:0]  pmpcfg;
  logic [7:0][53:0] pmpaddr;

  sv39_mmu dut (
    .clk_i(clk), .rst_ni(rst_n), .flush_i(flush),
    .enable_translation_i(en_tr), .en_ld_st_translation_i(en_ldst),
    .lsu_req_i(lsu_req), .lsu_vaddr_i(lsu_vaddr), .lsu_is_store_i(lsu_is_store),
    .lsu_valid_o(lsu_valid), .lsu_paddr_o(lsu_paddr),
    .lsu_dtlb_hit_o(lsu_dtlb_hit), .lsu_dtlb_ppn_o(lsu_dtlb_ppn),
    .lsu_exc_valid_o(lsu_exc_valid), .lsu_exc_cause_o(lsu_exc_cause),
    .lsu_exc_tval_o(lsu_exc_tval),
    .fetch_req_i(fetch_req), .fetch_vaddr_i(fetch_vaddr),
    .fetch_valid_o(fetch_valid), .fetch_paddr_o(fetch_paddr),
    .fetch_exc_valid_o(fetch_exc_valid), .fetch_exc_cause_o(fetch_exc_cause),
    .fetch_exc_tval_o(fetch_exc_tval),
    .priv_lvl_i(priv), .ld_st_priv_lvl_i(ld_st_priv), .sum_i(sum_b), .mxr_i(mxr_b),
    .satp_ppn_i(satp_ppn), .asid_i(asid),
    .flush_tlb_i(flush_tlb), .asid_to_be_flushed_i(asid_flush),
    .vaddr_to_be_flushed_i(vaddr_flush),
    .itlb_miss_o(itlb_miss), .dtlb_miss_o(dtlb_miss),
    .mem_req_o(mem_req), .mem_addr_o(mem_addr),
    .mem_tag_valid_o(mem_tag_valid), .mem_kill_o(mem_kill),
    .mem_gnt_i(mem_gnt), .mem_rvalid_i(mem_rvalid), .mem_rdata_i(mem_rdata),
    .pmpcfg_i(pmpcfg), .pmpaddr_i(pmpaddr)
  );

  // ---- testbench-hosted physical memory. Read-only: A5 forbids the unit from
  // ---- writing a page-table entry, and a write here would hide that.
  logic [63:0] mem [bit [55:0]];
  int unsigned acc_count = 0;
  int unsigned wr_attempts = 0;
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin mem_gnt <= 0; mem_rvalid <= 0; mem_rdata <= '0; end
    else begin
      mem_gnt    <= mem_req;
      mem_rvalid <= mem_gnt;
      if (mem_gnt) begin
        acc_count <= acc_count + 1;
        mem_rdata <= mem.exists({mem_addr[55:3],3'd0}) ? mem[{mem_addr[55:3],3'd0}] : 64'd0;
      end
    end
  end

  // ---- the page table. Both rigs must plant exactly this. ----
  task automatic plant_table();
    begin
      pmpcfg = '0; pmpaddr = '0;
      pmpcfg[0]  = 8'b0_00_11_111;      // NAPOT over everything, RWX
      pmpaddr[0] = '1;
      // root @0x1000 (satp_ppn=1): VPN2=2 -> L1 @0x2000 ; VPN1=0 -> L0 @0x3000
      mem[64'h1000 + 2*8] = mk_pte(44'h2, 1,0,0,0,0,1,0);
      mem[64'h2000 + 0*8] = mk_pte(44'h3, 1,0,0,0,0,1,0);
      for (int i = 0; i < 20; i++)
        mem[64'h3000 + i*8] = mk_pte(44'h100 + i[43:0], 1,1,1,1,1,1,1);
      mem[64'h1000 + 3*8] = mk_pte(44'h0,     0,0,0,0,0,0,0);  // invalid
      mem[64'h1000 + 1*8] = mk_pte(44'h40000, 1,1,1,1,1,1,1);  // 1 GiB superpage
      mem[64'h1000 + 0*8] = mk_pte(44'h80000, 1,1,1,1,0,1,1);  // no U
      // VPN2=4 -> leaf with A=0 ; VPN2=5 -> leaf A=1 D=0
      mem[64'h1000 + 4*8] = mk_pte(44'h6, 1,0,0,0,0,1,0);
      mem[64'h6000 + 0*8] = mk_pte(44'h7, 1,0,0,0,0,1,0);
      mem[64'h7000 + 0*8] = mk_pte(44'h9, 1,1,1,1,1,0,0);
      mem[64'h1000 + 5*8] = mk_pte(44'hA, 1,0,0,0,0,1,0);
      mem[64'hA000 + 0*8] = mk_pte(44'hB, 1,0,0,0,0,1,0);
      mem[64'hB000 + 0*8] = mk_pte(44'hC, 1,1,1,1,1,1,0);
    end
  endtask

  // ---- apply a control event, then issue one request and retire it ----
  // Retirement is LATCHED, not polled. lsu_valid_o / lsu_exc_valid_o can be a
  // narrow pulse -- a flush_i-cancelled walk produces one -- and sampling the
  // level once per cycle misses it. That is not hypothetical: it made the
  // recorded reference for the flush-mid step read valid=0 when the design had
  // in fact asserted valid, and a control that latched internally then
  // "disagreed" with a vector that was itself wrong.
  int unsigned last_acc, last_cyc;
  logic        saw_v, saw_e;
  logic [55:0] saw_paddr;
  logic [63:0] saw_cause;
  logic        early_exc;      // exc_valid_o seen with valid_o low
  logic [63:0] early_cause;
  task automatic do_step(input step_t st);
    int t, a0;
    begin
      // a bare-mode event applies to the enable of THIS STEP'S OWN PORT, so C1
      // is reachable on both sides with one event encoding
      case (st.ev)
        EV_FLUSH_TLB: begin flush_tlb = 1; @(posedge clk); flush_tlb = 0;
                            repeat (200) @(posedge clk); end
        EV_BARE_ON:   begin if (st.is_fetch) en_tr = 0; else en_ldst = 0;
                            repeat (2) @(posedge clk); end
        EV_BARE_OFF:  begin if (st.is_fetch) en_tr = 1; else en_ldst = 1;
                            repeat (2) @(posedge clk); end
        default: ;
      endcase

      lsu_req = 0; fetch_req = 0; repeat (2) @(posedge clk);
      a0 = acc_count;
      if (st.is_fetch) begin
        fetch_vaddr = st.va; fetch_req = 1;
      end else begin
        lsu_vaddr = st.va; lsu_is_store = st.is_store; lsu_req = 1;
      end

      if (st.ev == EV_FLUSH_MID) begin
        repeat (3) @(posedge clk);
        flush = 1; @(posedge clk); flush = 0;
      end

      // RETIREMENT IS valid_o, ON BOTH PORTS, per A11. exc_valid_o is sampled in
      // that same cycle and is NOT a retirement signal in its own right.
      //
      // This is the third level-versus-event defect in this task and the second
      // in this rig, so it is written out rather than just fixed. The reference
      // holds fetch_exc_valid_o asserted for the WHOLE of an in-flight walk --
      // its instruction-side PMP check runs against a fetch_paddr that is not
      // valid yet, so it reports "not permitted" for twelve cycles and then
      // retires correctly on the thirteenth. An earlier version of this task
      // latched whichever output went high first, so it recorded EVERY
      // instruction fetch as an access fault at cycle 0, including the ones that
      // translate. Measured with tb/audit/probe_fetch_tb.sv. See rule 27: the
      // instrument must take retirement from the defined retirement condition,
      // not from whichever signal moves first.
      saw_v = 1'b0; saw_e = 1'b0; saw_paddr = '0; saw_cause = '0;
      early_exc = 1'b0; early_cause = '0;
      t = 0;
      while (t < 600 && !saw_v) begin
        @(posedge clk); #1;
        if (st.is_fetch) begin
          if (fetch_exc_valid) begin early_exc = 1'b1; early_cause = fetch_exc_cause; end
          if (fetch_valid) begin
            saw_v = 1'b1; saw_paddr = fetch_paddr;
            if (fetch_exc_valid) begin saw_e = 1'b1; saw_cause = fetch_exc_cause; end
          end
        end else begin
          if (lsu_exc_valid) begin early_exc = 1'b1; early_cause = lsu_exc_cause; end
          if (lsu_valid) begin
            saw_v = 1'b1; saw_paddr = lsu_paddr;
            if (lsu_exc_valid) begin saw_e = 1'b1; saw_cause = lsu_exc_cause; end
          end
        end
        t++;
      end
      // A design that raises the exception and never asserts valid_o violates
      // A11. Report the cause it did raise, so the mismatch reads as "valid=0,
      // expected 1" instead of as a 600-cycle timeout with no diagnosis.
      if (!saw_v && early_exc) begin saw_e = 1'b1; saw_cause = early_cause; end
      last_acc = acc_count - a0;
      last_cyc = t;
      lsu_req = 0; fetch_req = 0; lsu_is_store = 0; @(posedge clk);
    end
  endtask
