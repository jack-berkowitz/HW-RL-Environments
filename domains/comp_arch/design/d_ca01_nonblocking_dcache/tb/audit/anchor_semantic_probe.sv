// ---------------------------------------------------------------------------
// d_ca01 STEP 1 -- directed semantic probe against the v3 anchor.
//
// NOT a scoring testbench. Never scored, never shipped. It exists to answer one
// question: is `bsg_cache_non_blocking` (the whole module, with its closure) the
// thing TASK_CATALOG.md says it is? Elaboration is a separate result and is
// recorded separately in NOTES.md -- "it compiles" and "it is the module the
// catalog claims" are different findings.
//
// The three claims under test, each with its own negative control:
//
//   S1  a HIT is returned while a MISS is outstanding
//   S2  a SECONDARY miss merges against an in-flight line (one fill, two
//       responses)
//   S3  responses are tagged by id and correct under OUT-OF-ORDER completion
//
// Every claim here is a confirmation -- it asserts the anchor DOES something.
// A confirmation probe that never fires is indistinguishable from one that
// passes, so each claim carries a control that drives the anchor into the state
// where the claim is FALSE and requires the detector to say so. A clean pass is
// not believed until its control has failed.
//
// Handshake observation is REGISTERED, never sampled at the edge it describes.
// bsg's `_ready_and_o` / `_yumi_i` outputs may depend combinationally on the
// valid they answer, so reading them at the posedge they act on is racy. Every
// transfer is captured by a flop clocked on the same edge the DUT uses, and the
// stimulus process moves only on negedge -- CONVENTIONS.md, never change
// stimulus in the same timestep as the sampling edge.
// ---------------------------------------------------------------------------
`include "bsg_cache_non_blocking.svh"

module anchor_semantic_probe
  import bsg_cache_non_blocking_pkg::*;
 #(parameter id_width_p             = 4
  ,parameter addr_width_p           = 32
  ,parameter data_width_p           = 32
  ,parameter sets_p                 = 8
  ,parameter ways_p                 = 2
  ,parameter block_size_in_words_p  = 4
  ,parameter miss_fifo_els_p        = 8
  );

  localparam cache_pkt_width_lp = `bsg_cache_non_blocking_pkt_width(id_width_p,addr_width_p,data_width_p);
  localparam dma_pkt_width_lp   = `bsg_cache_non_blocking_dma_pkt_width(addr_width_p);

  localparam byte_sel_w_lp      = `BSG_SAFE_CLOG2(data_width_p>>3);          // 2
  localparam lg_block_lp        = `BSG_SAFE_CLOG2(block_size_in_words_p);    // 2
  localparam block_off_w_lp     = byte_sel_w_lp + lg_block_lp;               // 4
  localparam lg_sets_lp         = `BSG_SAFE_CLOG2(sets_p);                   // 3

  localparam MEM_WORDS_LP       = 1024;   // backing store, word-addressed

  // ---------------------------------------------------------------- clock/reset
  logic clk, reset;
  initial begin clk = 1'b0; forever #5 clk = ~clk; end

  // ---------------------------------------------------------------- DUT wiring
  logic                          v_i, ready_o;
  logic [cache_pkt_width_lp-1:0] cache_pkt_i;
  logic                          v_o, yumi_i;
  logic [id_width_p-1:0]         id_o;
  logic [data_width_p-1:0]       data_o;

  logic [dma_pkt_width_lp-1:0]   dma_pkt_o;
  logic                          dma_pkt_v_o, dma_pkt_yumi_i;
  logic [data_width_p-1:0]       dma_data_i, dma_data_o;
  logic                          dma_data_v_i, dma_data_ready_and_o;
  logic                          dma_data_v_o, dma_data_yumi_i;

  bsg_cache_non_blocking #(
     .id_width_p(id_width_p)
    ,.addr_width_p(addr_width_p)
    ,.data_width_p(data_width_p)
    ,.sets_p(sets_p)
    ,.ways_p(ways_p)
    ,.block_size_in_words_p(block_size_in_words_p)
    ,.miss_fifo_els_p(miss_fifo_els_p)
  ) dut (
     .clk_i(clk), .reset_i(reset)
    ,.v_i(v_i), .cache_pkt_i(cache_pkt_i), .ready_o(ready_o)
    ,.v_o(v_o), .id_o(id_o), .data_o(data_o), .yumi_i(yumi_i)
    ,.dma_pkt_o(dma_pkt_o), .dma_pkt_v_o(dma_pkt_v_o), .dma_pkt_yumi_i(dma_pkt_yumi_i)
    ,.dma_data_i(dma_data_i), .dma_data_v_i(dma_data_v_i)
    ,.dma_data_ready_and_o(dma_data_ready_and_o)
    ,.dma_data_o(dma_data_o), .dma_data_v_o(dma_data_v_o), .dma_data_yumi_i(dma_data_yumi_i)
  );

  // Response is taken whenever offered.
  //
  // Driven CONSTANT rather than as `yumi_i = v_o`, and the reason is not
  // cosmetic. `yumi_i` is read in exactly one place in the anchor --
  // `wire stall = v_o & ~yumi_i` (bsg_cache_non_blocking.sv:78) -- so a
  // constant 1 and a mirror of v_o produce an identical `stall` (always 0).
  // But the mirror creates a combinational path DUT-output -> TB -> DUT-input
  // that Verilator is free to evaluate in either order within a settle pass;
  // it is not a loop, so nothing warns. Builds of this probe that differed
  // only in an added debug process disagreed about whether `stall` was 1,
  // and the anchor consequently jammed after one management op in some builds
  // and ran normally in others. Removing the TB's combinational dependency on
  // a DUT output removes the ordering question entirely.
  assign yumi_i = 1'b1;

  // ---------------------------------------------------------------- backing memory
  logic [data_width_p-1:0] mem [MEM_WORDS_LP-1:0];

  function automatic [data_width_p-1:0] pattern (input int unsigned word_addr);
    // Deterministic and NEVER zero, so a fill that did not happen cannot look
    // correct by returning 0 -- same reasoning as golden_mem's init_pattern.
    pattern = {~word_addr[15:0], word_addr[15:0]} ^ 32'hA5A5_0001;
  endfunction

  // ---------------------------------------------------------------- DMA observation
  // dma_hold freezes the memory model BEFORE it accepts a request packet, so a
  // miss stays outstanding for as long as the stimulus wants it to.
  logic dma_hold;

  int   dma_rd_pkts, dma_wr_pkts;
  logic [addr_width_p-1:0] dma_rd_addr_q [$];   // read addresses, in order
  logic dma_busy;                               // a request is accepted and unfinished

  wire                     dma_pkt_wnr  = dma_pkt_o[addr_width_p];
  wire [addr_width_p-1:0]  dma_pkt_addr = dma_pkt_o[addr_width_p-1:0];

  // Registered handshake observation -- clocked on the edge the DUT acts on.
  //
  // WHY THIS IS REGISTERED RATHER THAN POLLED, recorded because the first
  // version of this probe polled and hung: the anchor's `ready_o` depends
  // COMBINATIONALLY on `v_i`
  //   (bsg_cache_non_blocking_tl_stage.sv:437, ready_o = mgmt_op_v ? mhu_idle_i : 1'b1,
  //    with mgmt_op_v = v_i & decode_i.mgmt_op)
  // so a driver that assigns v_i and reads ready_o in the same timestep can
  // read the value from before its own drive. The symptom was a probe that
  // spun forever on the second TAGST while the anchor was in fact accepting
  // requests every other cycle -- a dead-looking DUT that was working.
  // Observing the transfer with a flop clocked on the same edge the DUT uses
  // removes the race entirely: `*_taken_r` is true at the negedge AFTER the
  // posedge on which the transfer happened.
  // Transfers are counted, not flagged. A LEVEL flag is stale for one cycle
  // after the transfer it describes, and a waiter that tests it before
  // advancing the clock reads the PREVIOUS transaction's success and returns
  // immediately -- which is what the first version of this probe did. The
  // request was then dropped without ever being presented at a posedge, and
  // the anchor looked like it had jammed after one accepted operation.
  // A monotonically increasing count cannot be stale: the waiter snapshots it
  // and waits for it to CHANGE.
  int req_accepts_r, resp_count_r, dma_fills_r, dma_evicts_r;
  logic resp_taken_r;
  logic [id_width_p-1:0]   resp_id_r;
  logic [data_width_p-1:0] resp_data_r;

  always_ff @(posedge clk) begin
    if (reset) begin
      req_accepts_r <= 0; resp_count_r <= 0; dma_fills_r <= 0; dma_evicts_r <= 0;
      resp_taken_r  <= 1'b0;
    end
    else begin
      if (v_i & ready_o)                       req_accepts_r <= req_accepts_r + 1;
      if (v_o & yumi_i)                        resp_count_r  <= resp_count_r  + 1;
      if (dma_data_v_i & dma_data_ready_and_o) dma_fills_r   <= dma_fills_r   + 1;
      if (dma_data_v_o & dma_data_yumi_i)      dma_evicts_r  <= dma_evicts_r  + 1;
      resp_taken_r <= v_o & yumi_i;
    end
    resp_id_r   <= id_o;
    resp_data_r <= data_o;
  end

  // ---------------------------------------------------------------- scoreboard
  logic [data_width_p-1:0] exp_data  [(1<<id_width_p)-1:0];
  logic                    exp_valid [(1<<id_width_p)-1:0];
  int                      issue_seq [(1<<id_width_p)-1:0];
  int                      done_seq  [(1<<id_width_p)-1:0];
  int                      n_issued, n_done;
  int                      errors, checks;
  int                      reorderings;      // completed while an older id was still open
  logic                    open [(1<<id_width_p)-1:0];

  // Detector state for the three claims, per phase.
  int   hit_under_miss_events;
  int   resp_while_dma_outstanding;

  task automatic sb_reset();
    int i;
    for (i = 0; i < (1<<id_width_p); i++) begin
      exp_valid[i] = 1'b0; open[i] = 1'b0;
      issue_seq[i] = 0;    done_seq[i] = 0;
    end
    n_issued = 0; n_done = 0; reorderings = 0;
    hit_under_miss_events = 0; resp_while_dma_outstanding = 0;
  endtask

  // ---------------------------------------------------------------- response monitor
  always_ff @(posedge clk) begin
    if (resp_taken_r) begin
      int i;
      n_done++;
      done_seq[resp_id_r] = n_done;
      // Look the expectation up BY THE ID THE DUT REPORTED. The scoreboard must
      // not grade itself by assuming which transaction this is.
      if (exp_valid[resp_id_r]) begin
        checks++;
        if (resp_data_r !== exp_data[resp_id_r]) begin
          errors++;
          $display("[FAIL] id=%0d data=%08x expected=%08x", resp_id_r, resp_data_r, exp_data[resp_id_r]);
        end
      end
      // reordering: some id issued EARLIER is still open at this completion
      for (i = 0; i < (1<<id_width_p); i++)
        if (open[i] && (i != int'(resp_id_r)) && (issue_seq[i] < issue_seq[resp_id_r]))
          reorderings++;
      open[resp_id_r] = 1'b0;
      // "outstanding" must include a fill the anchor is ASKING for and has not
      // been given. `dma_busy` alone covers only a transfer the memory model
      // already accepted, so while the model is held it reads zero -- a
      // counter that looks like evidence for S1 and is measuring something
      // else. dma_pkt_v_o is the anchor with an unserved fill request.
      if (dma_busy || dma_pkt_v_o) resp_while_dma_outstanding++;
    end
  end

  // ---------------------------------------------------------------- DMA memory model
  int unsigned dma_base_word;
  int          dma_i;
  logic        pkt_wnr_r;

  initial begin
    dma_pkt_yumi_i = 1'b0; dma_data_v_i = 1'b0; dma_data_i = '0; dma_data_yumi_i = 1'b0;
    dma_rd_pkts = 0; dma_wr_pkts = 0; dma_busy = 1'b0;
    forever begin
      @(negedge clk);
      if (dma_pkt_v_o && !dma_hold && !reset) begin
        pkt_wnr_r     = dma_pkt_wnr;
        dma_base_word = dma_pkt_addr[byte_sel_w_lp+:($clog2(MEM_WORDS_LP))];
        if (pkt_wnr_r) dma_wr_pkts++;
        else begin dma_rd_pkts++; dma_rd_addr_q.push_back(dma_pkt_addr); end
        dma_busy       = 1'b1;
        dma_pkt_yumi_i = 1'b1;
        @(negedge clk);
        dma_pkt_yumi_i = 1'b0;

        if (pkt_wnr_r) begin
          // EVICT: take block_size_in_words_p words out of the cache.
          // dma_data_v_o is a VALID and does not depend on our yumi, so it is
          // safe to read directly; the transfer itself is still confirmed by a
          // registered observation.
          for (dma_i = 0; dma_i < block_size_in_words_p; dma_i++) begin
            int e0;
            while (!dma_data_v_o) @(negedge clk);
            mem[(dma_base_word + dma_i) % MEM_WORDS_LP] = dma_data_o;
            e0 = dma_evicts_r;
            dma_data_yumi_i = 1'b1;
            while (dma_evicts_r == e0) @(negedge clk);
            dma_data_yumi_i = 1'b0;
          end
        end
        else begin
          // REFILL: hand block_size_in_words_p words to the cache. Never poll
          // dma_data_ready_and_o in the timestep that drives dma_data_v_i --
          // it is a `ready_and`, i.e. it may depend on the valid it answers.
          for (dma_i = 0; dma_i < block_size_in_words_p; dma_i++) begin
            int f0;
            dma_data_i   = mem[(dma_base_word + dma_i) % MEM_WORDS_LP];
            dma_data_v_i = 1'b1;
            f0 = dma_fills_r;
            while (dma_fills_r == f0) @(negedge clk);
          end
          dma_data_v_i = 1'b0;
        end
        dma_busy = 1'b0;
      end
    end
  end

  // ---------------------------------------------------------------- stimulus helpers
  function automatic [cache_pkt_width_lp-1:0] mk_pkt
    (input [id_width_p-1:0] id, input bsg_cache_non_blocking_opcode_e op,
     input [addr_width_p-1:0] addr, input [data_width_p-1:0] data,
     input [(data_width_p>>3)-1:0] mask);
    mk_pkt = {id, op, addr, data, mask};
  endfunction

  task automatic send (input [id_width_p-1:0] id, input bsg_cache_non_blocking_opcode_e op,
                       input [addr_width_p-1:0] addr, input [data_width_p-1:0] data,
                       input [(data_width_p>>3)-1:0] mask, input logic expect_resp,
                       input [data_width_p-1:0] edata);
    @(negedge clk);
    v_i         = 1'b1;
    cache_pkt_i = mk_pkt(id, op, addr, data, mask);
    // Bookkeeping BEFORE the wait: the response monitor runs on the same clock
    // and can observe a completion in the very cycle the request is accepted.
    n_issued++;
    issue_seq[id] = n_issued;
    open[id]      = 1'b1;
    exp_valid[id] = expect_resp;
    exp_data[id]  = edata;
    // Hold v_i until the accept COUNT moves. Never poll ready_o here: it
    // depends combinationally on v_i, so reading it in the timestep that
    // drives v_i can return the pre-drive value.
    // BOUNDED: an unbounded wait turns any acceptance problem into a watchdog
    // kill with no information, which is the same failure the liveness work
    // keeps recording -- a wedged rig and a dead DUT emit the same thing.
    begin
      int w, a0;
      a0 = req_accepts_r; w = 0;
      while ((req_accepts_r == a0) && (w < 200)) begin @(negedge clk); w++; end
      if (req_accepts_r == a0) begin
        errors++;
        $display("[FAIL] request id=%0d op=%0d addr=%08x not accepted in 200 cycles (ready_o=%b)",
                 id, op, addr, ready_o);
      end
    end
    v_i = 1'b0;
  endtask

  task automatic idle (input int n);
    int k;
    for (k = 0; k < n; k++) @(negedge clk);
  endtask

  task automatic drain (input int max_cycles);
    int k;
    k = 0;
    while ((n_done < n_issued) && (k < max_cycles)) begin @(negedge clk); k++; end
    if (n_done < n_issued)
      $display("[FAIL] drain timeout: %0d issued, %0d completed", n_issued, n_done);
  endtask

  // ---------------------------------------------------------------- addresses
  // Four lines on four DIFFERENT indices, so nothing evicts anything else and a
  // result is never explained by a conflict the probe did not intend.
  localparam [addr_width_p-1:0] LINE_A = 32'h0000_0100;   // index 0
  localparam [addr_width_p-1:0] LINE_B = 32'h0000_0210;   // index 1
  localparam [addr_width_p-1:0] LINE_C = 32'h0000_0320;   // index 2
  localparam [addr_width_p-1:0] LINE_D = 32'h0000_0430;   // index 3

  function automatic [data_width_p-1:0] mem_at (input [addr_width_p-1:0] a);
    mem_at = mem[a[byte_sel_w_lp+:($clog2(MEM_WORDS_LP))] % MEM_WORDS_LP];
  endfunction

  task automatic tagst_init();
    int idx, way;
    for (idx = 0; idx < sets_p; idx++)
      for (way = 0; way < ways_p; way++)
        // TAGST addr carries {way, index} above the block offset; data[31] is
        // the valid bit. Written invalid: the tag SRAM has no reset, so without
        // this the probe would read whatever 2-state init produced.
        send(4'd0, TAGST, (way << (block_off_w_lp+lg_sets_lp)) | (idx << block_off_w_lp),
             32'h0000_0000, 4'hF, 1'b0, 32'h0);
    drain(500);
  endtask

  // ---------------------------------------------------------------- report
  int phase;
  string phase_name;

  task automatic banner(input string s);
    phase_name = s;
    $display("---- %s", s);
  endtask

  // ---------------------------------------------------------------- main
  int i;
  int dma_rd_before;
  int line_c_reads;
  int snap_errors;

  initial begin
    for (i = 0; i < MEM_WORDS_LP; i++) mem[i] = pattern(i);
    errors = 0; checks = 0; dma_hold = 1'b0;
    v_i = 1'b0; cache_pkt_i = '0;
    sb_reset();

    reset = 1'b1; idle(8); @(negedge clk); reset = 1'b0; idle(4);

    $display("================ d_ca01 anchor semantic probe ================");
    $display("anchor = bsg_cache_non_blocking  sets=%0d ways=%0d block=%0d id_w=%0d",
             sets_p, ways_p, block_size_in_words_p, id_width_p);

    banner("init: TAGST all lines invalid");
    tagst_init();
    sb_reset();

    // =====================================================================
    // S1 + S3 : hit returned while a miss is outstanding, out-of-order,
    //           each response tagged by its own id
    // =====================================================================
    banner("S1/S3: warm LINE_A, then miss LINE_B held, then hit LINE_A");
    send(4'd1, LW, LINE_A, 32'h0, 4'hF, 1'b1, mem_at(LINE_A));  // warms LINE_A
    drain(400);

    dma_hold = 1'b1;                                            // freeze the memory
    send(4'd2, LW, LINE_B,       32'h0, 4'hF, 1'b1, mem_at(LINE_B));       // MISS, held
    idle(6);
    send(4'd3, LW, LINE_A + 4,   32'h0, 4'hF, 1'b1, mem_at(LINE_A + 4));   // HIT
    idle(20);
    // id=3 must be complete while id=2 is still open and the DMA unfinished
    if ((done_seq[3] != 0) && (done_seq[2] == 0)) hit_under_miss_events++;
    $display("     id3 done_seq=%0d  id2 done_seq=%0d  dma_rd_pkts=%0d  resp_while_dma_outstanding=%0d",
             done_seq[3], done_seq[2], dma_rd_pkts, resp_while_dma_outstanding);
    dma_hold = 1'b0;
    drain(600);
    $display("     after release: id2 done_seq=%0d  id3 done_seq=%0d", done_seq[2], done_seq[3]);
    $display("     S1 hit_under_miss_events=%0d (want >=1)", hit_under_miss_events);
    $display("     S3 reorderings=%0d (want >=1)  data errors so far=%0d", reorderings, errors);
    if (hit_under_miss_events       < 1) begin errors++; $display("[FAIL] S1 not demonstrated"); end
    if (resp_while_dma_outstanding  < 1) begin errors++; $display("[FAIL] S1 no response observed with a fill unserved"); end
    if (reorderings                 < 1) begin errors++; $display("[FAIL] S3 out-of-order completion not demonstrated"); end

    // ---- NC1: control for S1 -------------------------------------------
    // Same shape, but the second request targets a line that is NOT resident.
    // Nothing can be returned while the DMA is held, so the detector MUST read
    // zero. If it still counts an event, it is not measuring what it claims.
    banner("NC1 (control for S1): second request targets a NON-resident line");
    sb_reset();
    dma_hold = 1'b1;
    send(4'd4, LW, LINE_C, 32'h0, 4'hF, 1'b1, mem_at(LINE_C));   // MISS, held
    idle(6);
    send(4'd5, LW, LINE_D, 32'h0, 4'hF, 1'b1, mem_at(LINE_D));   // also a MISS
    idle(20);
    if ((done_seq[5] != 0) && (done_seq[4] == 0)) hit_under_miss_events++;
    $display("     id5 done_seq=%0d  id4 done_seq=%0d", done_seq[5], done_seq[4]);
    $display("     NC1 hit_under_miss_events=%0d (want 0)", hit_under_miss_events);
    if (hit_under_miss_events != 0) begin
      errors++;
      $display("[FAIL] NC1: detector fired with no resident line -- S1 result is not trustworthy");
    end
    dma_hold = 1'b0;
    drain(800);

    // =====================================================================
    // S2 : secondary miss merges against the in-flight line
    // =====================================================================
    banner("S2: two requests to the SAME non-resident line while the fill is held");
    sb_reset();
    // LINE_C and LINE_D are resident after NC1; use fresh lines on the same
    // indices so the probe is measuring a fill, not a hit.
    begin
      logic [addr_width_p-1:0] line_e, line_f;
      line_e = 32'h0000_1000;   // index 0, different tag from LINE_A
      line_f = 32'h0000_1210;   // index 1, different tag from LINE_B
      dma_rd_before = dma_rd_pkts;
      dma_hold = 1'b1;
      send(4'd6, LW, line_e,     32'h0, 4'hF, 1'b1, mem_at(line_e));       // primary miss
      idle(6);
      send(4'd7, LW, line_e + 8, 32'h0, 4'hF, 1'b1, mem_at(line_e + 8));   // SECONDARY, same line
      idle(20);
      dma_hold = 1'b0;
      drain(800);
      line_c_reads = dma_rd_pkts - dma_rd_before;
      $display("     dma READ packets issued for the pair = %0d (want 1)", line_c_reads);
      $display("     id6 done_seq=%0d  id7 done_seq=%0d  data errors so far=%0d",
               done_seq[6], done_seq[7], errors);
      if (line_c_reads != 1) begin
        errors++;
        $display("[FAIL] S2: secondary miss did not merge -- %0d fills for one line", line_c_reads);
      end

      // ---- NC2: control for S2 --------------------------------------
      // Identical shape, second request on a DIFFERENT line. The counter must
      // read 2. A counter that can only ever say "1" would have passed S2 for
      // free.
      banner("NC2 (control for S2): second request targets a DIFFERENT line");
      sb_reset();
      dma_rd_before = dma_rd_pkts;
      dma_hold = 1'b1;
      send(4'd8, LW, line_f,          32'h0, 4'hF, 1'b1, mem_at(line_f));
      idle(6);
      send(4'd9, LW, 32'h0000_1320,   32'h0, 4'hF, 1'b1, mem_at(32'h0000_1320)); // index 2
      idle(20);
      dma_hold = 1'b0;
      drain(800);
      $display("     dma READ packets issued for the pair = %0d (want 2)", dma_rd_pkts - dma_rd_before);
      if ((dma_rd_pkts - dma_rd_before) != 2) begin
        errors++;
        $display("[FAIL] NC2: fill counter cannot distinguish one line from two -- S2 is not trustworthy");
      end
    end

    // =====================================================================
    // NC3 : control for the id/data checker itself
    // =====================================================================
    // Everything above rests on "the response carried the right data for the id
    // it reported". That check has never been observed to FAIL, so it has not
    // been shown to be capable of failing. Point one expectation at a value the
    // anchor cannot produce and require exactly one new error.
    banner("NC3 (control for S3): one expectation deliberately falsified");
    sb_reset();
    snap_errors = errors;
    send(4'd10, LW, LINE_A, 32'h0, 4'hF, 1'b1, 32'hDEAD_BEEF);   // wrong on purpose
    drain(400);
    $display("     new errors from one falsified expectation = %0d (want exactly 1)", errors - snap_errors);
    if ((errors - snap_errors) != 1) begin
      $display("[FAIL] NC3: id/data checker did not fire on a known-wrong expectation");
      errors = snap_errors + 99;
    end
    else begin
      errors = snap_errors;   // the injected error was the point; do not carry it
      $display("     id/data checker confirmed capable of failing");
    end

    // =====================================================================
    $display("================ probe summary ================");
    $display("checks=%0d  errors=%0d", checks, errors);
    if (errors == 0) $display("PROBE_RESULT: CONFIRMED");
    else             $display("PROBE_RESULT: NOT_CONFIRMED errors=%0d", errors);
    $finish;
  end

  // watchdog -- a wedged probe and a dead anchor emit the same thing: nothing
  initial begin
    #2_000_000;
    $display("[FAIL] watchdog: probe did not terminate");
    $display("PROBE_RESULT: NOT_CONFIRMED watchdog");
    $finish;
  end

endmodule
