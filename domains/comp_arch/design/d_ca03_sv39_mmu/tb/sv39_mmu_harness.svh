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

  // A5 forbids the unit from ever writing a page table entry. An earlier version
  // of this rig declared `wr_attempts`, compared it in the verdict, incremented
  // errs on it and printed a message -- and NOTHING ANYWHERE ASSIGNED IT, so the
  // clause reported PASS on a property it never tested, for every design, in
  // every run. See F75.
  //
  // Two things replace it, because the property has two halves.
  //   STRUCTURAL: a write is not expressible on this port list at all. V1 gives
  //     mem_req_o, mem_addr_o, mem_tag_valid_o and mem_kill_o outward and
  //     mem_gnt_i, mem_rvalid_i, mem_rdata_i inward -- no write data, no write
  //     enable. No conforming design CAN write, so a counter of attempts could
  //     only ever read zero. That half is guaranteed by the interface and is
  //     stated in the spec rather than checked here.
  //   BEHAVIOURAL: the table must still be byte-identical at the end, which is
  //     what A5 actually measured. That is checked below and CAN fail --
  //     +mutate_pte proves it fires.
  logic [63:0] mem_gold [bit [55:0]];
  int unsigned pte_mutations = 0;

  task automatic snapshot_table();
    begin
      mem_gold.delete();
      foreach (mem[a]) mem_gold[a] = mem[a];
    end
  endtask

  task automatic verify_table_unchanged();
    begin
      pte_mutations = 0;
      foreach (mem_gold[a])
        if (!mem.exists(a) || mem[a] !== mem_gold[a]) pte_mutations++;
      foreach (mem[a])
        if (!mem_gold.exists(a)) pte_mutations++;
    end
  endtask
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
      // VPN2=6 -> a GLOBAL 1 GiB leaf (G=1). A10's global half had no stimulus at
      // all until mk_pte gained its g argument; every planted entry was G=0.
      mem[64'h1000 + 6*8] = mk_pte(44'hC0000, 1,1,1,1,1,1,1, 1'b1);
      // VPN2=7 -> an EXECUTE-ONLY 1 GiB leaf (R=0, W=0, X=1). A4 makes a load
      // through it legal only when mxr_i is set, and mxr_i was frozen at 0.
      mem[64'h1000 + 7*8] = mk_pte(44'h100000, 1,0,0,1,1,1,1);
    end
  endtask


  // ===========================================================================
  // STIMULUS VARIATION MONITOR
  //
  // WHY VARIATION AND NOT ASSIGNMENT. The first version of this idea was "assert
  // every scored port was DRIVEN at least once", and it would have caught only
  // one of this task's two instances. fetch_req was initialised to zero and
  // never assigned -- never driven, caught. asid_i is driven every single cycle,
  // at the constant zero, so a driven-at-least-once check passes it while A10's
  // entire ASID and global-page clause goes unexercised. THE OBSERVABLE IS
  // VARIATION. An input that never changes value has not been tested, however
  // continuously it was assigned.
  //
  // Absence-shaped, so it is validated against known-failing input before it is
  // trusted: +freeze_fetch reconstructs the fetch_req defect, and asid_i fires
  // on the live tree with no modification at all.
  // ===========================================================================
  localparam int unsigned NVAR = 23;
  localparam int V_RST=0,  V_FLUSH=1,  V_ENTR=2,   V_ENLDST=3, V_LREQ=4,
                 V_LVA=5,  V_LSTORE=6, V_FREQ=7,   V_FVA=8,    V_PRIV=9,
                 V_LDPRIV=10, V_SUM=11, V_MXR=12,  V_SATP=13,  V_ASID=14,
                 V_FTLB=15, V_ASIDF=16, V_VAF=17,  V_GNT=18,   V_RV=19,
                 V_RDATA=20, V_PMPCFG=21, V_PMPADDR=22;

  string vw_name  [NVAR];
  bit    vw_varied[NVAR];
  bit    vw_primed = 1'b0;

  logic        vf_rst, vf_flush, vf_entr, vf_enldst, vf_lreq, vf_lstore;
  logic        vf_freq, vf_ftlb, vf_gnt, vf_rv, vf_sum, vf_mxr;
  logic [63:0] vf_lva, vf_fva, vf_rdata, vf_vaf;
  logic [1:0]  vf_priv, vf_ldpriv;
  logic [43:0] vf_satp;
  logic [15:0] vf_asid, vf_asidf;
  logic [7:0][7:0]  vf_pmpcfg;
  logic [7:0][53:0] vf_pmpaddr;

  initial begin
    vw_name[V_RST]="rst_ni";                  vw_name[V_FLUSH]="flush_i";
    vw_name[V_ENTR]="enable_translation_i";   vw_name[V_ENLDST]="en_ld_st_translation_i";
    vw_name[V_LREQ]="lsu_req_i";              vw_name[V_LVA]="lsu_vaddr_i";
    vw_name[V_LSTORE]="lsu_is_store_i";       vw_name[V_FREQ]="fetch_req_i";
    vw_name[V_FVA]="fetch_vaddr_i";           vw_name[V_PRIV]="priv_lvl_i";
    vw_name[V_LDPRIV]="ld_st_priv_lvl_i";     vw_name[V_SUM]="sum_i";
    vw_name[V_MXR]="mxr_i";                   vw_name[V_SATP]="satp_ppn_i";
    vw_name[V_ASID]="asid_i";                 vw_name[V_FTLB]="flush_tlb_i";
    vw_name[V_ASIDF]="asid_to_be_flushed_i";  vw_name[V_VAF]="vaddr_to_be_flushed_i";
    vw_name[V_GNT]="mem_gnt_i";               vw_name[V_RV]="mem_rvalid_i";
    vw_name[V_RDATA]="mem_rdata_i";           vw_name[V_PMPCFG]="pmpcfg_i";
    vw_name[V_PMPADDR]="pmpaddr_i";
  end

  always @(posedge clk) begin
    if (!vw_primed) begin
      vw_primed = 1'b1;
      vf_rst=rst_n;   vf_flush=flush;      vf_entr=en_tr;     vf_enldst=en_ldst;
      vf_lreq=lsu_req; vf_lva=lsu_vaddr;   vf_lstore=lsu_is_store;
      vf_freq=fetch_req; vf_fva=fetch_vaddr;
      vf_priv=priv;   vf_ldpriv=ld_st_priv; vf_sum=sum_b;     vf_mxr=mxr_b;
      vf_satp=satp_ppn; vf_asid=asid;      vf_ftlb=flush_tlb;
      vf_asidf=asid_flush; vf_vaf=vaddr_flush;
      vf_gnt=mem_gnt; vf_rv=mem_rvalid;    vf_rdata=mem_rdata;
      vf_pmpcfg=pmpcfg; vf_pmpaddr=pmpaddr;
    end else begin
      if (rst_n       !== vf_rst)     vw_varied[V_RST]     = 1'b1;
      if (flush       !== vf_flush)   vw_varied[V_FLUSH]   = 1'b1;
      if (en_tr       !== vf_entr)    vw_varied[V_ENTR]    = 1'b1;
      if (en_ldst     !== vf_enldst)  vw_varied[V_ENLDST]  = 1'b1;
      if (lsu_req     !== vf_lreq)    vw_varied[V_LREQ]    = 1'b1;
      if (lsu_vaddr   !== vf_lva)     vw_varied[V_LVA]     = 1'b1;
      if (lsu_is_store!== vf_lstore)  vw_varied[V_LSTORE]  = 1'b1;
      if (fetch_req   !== vf_freq)    vw_varied[V_FREQ]    = 1'b1;
      if (fetch_vaddr !== vf_fva)     vw_varied[V_FVA]     = 1'b1;
      if (priv        !== vf_priv)    vw_varied[V_PRIV]    = 1'b1;
      if (ld_st_priv  !== vf_ldpriv)  vw_varied[V_LDPRIV]  = 1'b1;
      if (sum_b       !== vf_sum)     vw_varied[V_SUM]     = 1'b1;
      if (mxr_b       !== vf_mxr)     vw_varied[V_MXR]     = 1'b1;
      if (satp_ppn    !== vf_satp)    vw_varied[V_SATP]    = 1'b1;
      if (asid        !== vf_asid)    vw_varied[V_ASID]    = 1'b1;
      if (flush_tlb   !== vf_ftlb)    vw_varied[V_FTLB]    = 1'b1;
      if (asid_flush  !== vf_asidf)   vw_varied[V_ASIDF]   = 1'b1;
      if (vaddr_flush !== vf_vaf)     vw_varied[V_VAF]     = 1'b1;
      if (mem_gnt     !== vf_gnt)     vw_varied[V_GNT]     = 1'b1;
      if (mem_rvalid  !== vf_rv)      vw_varied[V_RV]      = 1'b1;
      if (mem_rdata   !== vf_rdata)   vw_varied[V_RDATA]   = 1'b1;
      if (pmpcfg      !== vf_pmpcfg)  vw_varied[V_PMPCFG]  = 1'b1;
      if (pmpaddr     !== vf_pmpaddr) vw_varied[V_PMPADDR] = 1'b1;
    end
  end

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
      // MACHINE STATE FIRST, then the control event. Applied every step from the
      // step's own fields, so a constant is a property of the sequence rather
      // than of the rig -- and the variation monitor can see it either way.
      priv       = st.priv;
      ld_st_priv = st.priv;
      sum_b      = st.sum;
      mxr_b      = st.mxr;
      asid       = st.asid;
      case (st.pmp)
        PMP_NONE[1:0]: begin pmpcfg = '0; pmpaddr = '0; end
        PMP_NOX[1:0]:  begin pmpcfg = '0; pmpaddr = '0;
                             pmpcfg[0]  = 8'b0_00_11_011;   // NAPOT, R+W, no X
                             pmpaddr[0] = '1; end
        default:       begin pmpcfg = '0; pmpaddr = '0;
                             pmpcfg[0]  = 8'b0_00_11_111;   // NAPOT, RWX
                             pmpaddr[0] = '1; end
      endcase
      repeat (2) @(posedge clk);

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
      if (st.is_fetch && !$test$plusargs("freeze_fetch")) begin
        fetch_vaddr = st.va; fetch_req = 1;
      end else if (!st.is_fetch) begin
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
