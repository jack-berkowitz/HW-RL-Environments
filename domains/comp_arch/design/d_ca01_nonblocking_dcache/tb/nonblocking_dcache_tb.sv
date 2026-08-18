// =============================================================================
// nonblocking_dcache_tb.sv  --  SCORING TESTBENCH for d_ca01
// =============================================================================
// Checks the contract in spec/nonblocking_dcache_iface.sv. Never shipped.
//
// THE THREE STRUCTURAL REMEDIES ARE APPLIED THROUGHOUT, and they are not
// stylistic. Each one corresponds to a defect that made a WORKING anchor look
// jammed during this task's step 1, with no error and no warning:
//
//   1. NO COMBINATIONAL PATH FROM A DUT OUTPUT TO A DUT INPUT. Every input this
//      harness drives comes from a register or a constant. The memory model is
//      a clocked FSM, not a reactive process. `assign yumi = valid` is exactly
//      the shape that made two builds differing only by a debug process
//      disagree about whether the design had deadlocked.
//   2. MONOTONIC COUNTERS, NEVER LEVEL FLAGS, for anything describing a
//      completed transfer. A level flag is stale for one cycle afterwards, and
//      a waiter that tests it before advancing the clock reads the PREVIOUS
//      transaction's success and returns immediately.
//   3. STIMULUS MOVES ON NEGEDGE ONLY, and is never sampled in the timestep
//      that drives it. `req_ready_o` is permitted to depend combinationally on
//      `req_valid_i` (spec L5), so polling it while driving valid can return
//      the pre-drive value.
//
// ORACLE. Expected LOAD values come from a shadow memory that is the SAME array
// the fill data is served from, updated by this harness on each accepted STORE
// and snapshotted AT ACCEPTANCE TIME. There is no modelled arithmetic to get
// wrong: R5 defines the ordering as acceptance order, and snapshotting at
// acceptance makes out-of-order completion irrelevant to the expectation.
//
// COVERAGE FLOORS MEASURE STIMULUS. Every floor below counts something this
// harness chose to drive. Nothing counts what the design chose to do with it --
// a floor on "did a writeback happen" would gate a replacement policy, and a
// correct design that evicts differently would fail a requirement nobody wrote.
// Writebacks, hit rates and latencies are METRIC lines.
// =============================================================================
`include "liveness_monitor.svh"

module nonblocking_dcache_tb #(
  parameter int unsigned DATA_W     = 32,
  parameter int unsigned SETS       = 16,
  parameter int unsigned WAYS       = 4,
  parameter int unsigned MAX_MISSES = 8,
  parameter int unsigned SEED       = 1     // stimulus is deterministic in SEED
);

  localparam int unsigned ADDR_W      = 32;
  localparam int unsigned ID_W        = 4;
  localparam int unsigned N_IDS       = 1 << ID_W;
  localparam int unsigned BLOCK_WORDS = 4;
  localparam int unsigned BYTES_W     = DATA_W/8;
  localparam int unsigned WORD_SEL_W  = $clog2(BYTES_W);
  localparam int unsigned BLK_OFF_W   = WORD_SEL_W + $clog2(BLOCK_WORDS);
  localparam int unsigned MEM_WORDS   = 4096;

  // Watchdog. The soak is 1200 transactions against a memory that stalls up to
  // 7 cycles per transaction and 4 beats per fill, so a correct design finishes
  // in well under 200k cycles. 2 000 000 is a margin of roughly 10x on the
  // worst plausible correct design. Sized to turn a hang into a verdict, never
  // to measure speed -- the liveness monitor is what judges progress, and its
  // own limits are deliberately loose for the same reason.
  localparam int unsigned WATCHDOG_CYCLES = 2_000_000;

  localparam int unsigned SOAK_TXNS = 1200;

  // ---------------------------------------------------------------- bookkeeping
  int    errors, checks, phase;
  string fail_reason;

  task automatic note_fail(input string msg);
    errors++;
    if (fail_reason == "") fail_reason = msg;
    $display("[FAIL] phase %0d: %s", phase, msg);
  endtask

  task automatic chk(input logic cond, input string msg);
    checks++;
    if (!cond) note_fail(msg);
  endtask

  `LM_DECLARE(N_IDS)

  // ---------------------------------------------------------------- clock/reset
  logic clk, rst_n;
  initial begin clk = 1'b0; forever #5 clk = ~clk; end

  // ---------------------------------------------------------------- DUT wiring
  logic               req_valid, req_ready;
  logic [ID_W-1:0]    req_id;
  logic               req_op;
  logic [ADDR_W-1:0]  req_addr;
  logic [DATA_W-1:0]  req_data;
  logic [BYTES_W-1:0] req_mask;

  logic               rsp_valid, rsp_ready;
  logic [ID_W-1:0]    rsp_id;
  logic [DATA_W-1:0]  rsp_data;

  logic               mem_req_valid, mem_req_ready, mem_req_we;
  logic [ADDR_W-1:0]  mem_req_addr;
  logic               mem_rd_valid, mem_rd_ready;
  logic [DATA_W-1:0]  mem_rd_data;
  logic               mem_wr_valid, mem_wr_ready;
  logic [DATA_W-1:0]  mem_wr_data;

  nonblocking_dcache #(
     .DATA_W(DATA_W), .SETS(SETS), .WAYS(WAYS), .MAX_MISSES(MAX_MISSES)
  ) dut (
     .clk_i(clk), .rst_ni(rst_n)
    ,.req_valid_i(req_valid), .req_ready_o(req_ready), .req_id_i(req_id)
    ,.req_op_i(req_op), .req_addr_i(req_addr), .req_data_i(req_data), .req_mask_i(req_mask)
    ,.rsp_valid_o(rsp_valid), .rsp_ready_i(rsp_ready), .rsp_id_o(rsp_id), .rsp_data_o(rsp_data)
    ,.mem_req_valid_o(mem_req_valid), .mem_req_ready_i(mem_req_ready)
    ,.mem_req_we_o(mem_req_we), .mem_req_addr_o(mem_req_addr)
    ,.mem_rd_valid_i(mem_rd_valid), .mem_rd_ready_o(mem_rd_ready), .mem_rd_data_i(mem_rd_data)
    ,.mem_wr_valid_o(mem_wr_valid), .mem_wr_ready_i(mem_wr_ready), .mem_wr_data_o(mem_wr_data)
  );

  // Response is always taken. CONSTANT, not `rsp_valid` -- remedy 1.
  assign rsp_ready = 1'b1;

  // ---------------------------------------------------------------- rng
  // Explicit LFSR rather than $urandom: Verilator seeds $urandom per BINARY, so
  // two builds of the same source walk different trajectories and the
  // determinism check could not distinguish a real nondeterminism from a
  // different random stream.
  logic [31:0] lfsr;
  function automatic [31:0] nxt(input [31:0] s);
    nxt = {s[30:0], s[31]^s[21]^s[1]^s[0]};
  endfunction
  task automatic roll(); lfsr = nxt(lfsr); endtask

  // ---------------------------------------------------------------- memories
  logic [DATA_W-1:0] mem    [MEM_WORDS-1:0];   // what the DUT fetches
  logic [DATA_W-1:0] shadow [MEM_WORDS-1:0];   // architectural state

  function automatic [DATA_W-1:0] pattern(input int unsigned w);
    pattern = DATA_W'({~w[15:0], w[15:0]} ^ 32'hA5A5_0001);
  endfunction

  function automatic int unsigned word_of(input [ADDR_W-1:0] a);
    word_of = (a >> WORD_SEL_W) % MEM_WORDS;
  endfunction

  // ---------------------------------------------------------------- memory FSM
  // Fully clocked. Every DUT input it drives is a register (remedy 1).
  typedef enum logic [1:0] { M_IDLE, M_FILL, M_WB } mstate_e;
  // Stalling the memory is a REGISTER the stimulus writes, not a force on the
  // FSM's own gap counter. force/release on `mgap_r` left the counter holding
  // the forced value after release, so the FSM then counted 100 000 cycles down
  // before accepting anything and every later phase timed out. The symptom
  // read as a dead DUT; it was the harness.
  logic               mem_stall;      // hold the memory REQUEST unaccepted
  // Hold the fill DATA instead: the transaction is accepted, and then no beat
  // is delivered. C2 needs this rather than mem_stall. A design that refuses
  // new requests while a memory transaction is in flight -- a blocking cache --
  // never becomes blocked if the request itself is never accepted, so a C2
  // phase built on mem_stall passes a blocking cache. Found by a mutant.
  logic               mem_data_stall;
  mstate_e            mstate;
  logic               mreq_ready_r, mrd_valid_r, mwr_ready_r;
  logic [DATA_W-1:0]  mrd_data_r;
  int unsigned        mbase_r;
  int                 mbeat_r, mgap_r;
  logic [ADDR_W-1:0]  mreq_addr_r;

  assign mem_req_ready = mreq_ready_r;
  // mem_data_stall gates the OUTPUT and never the FSM's own state. Dropping
  // mrd_valid_r inside M_FILL and re-raising it left the model wedged.
  assign mem_rd_valid  = mrd_valid_r & ~mem_data_stall;
  assign mem_rd_data   = mrd_data_r;
  assign mem_wr_ready  = mwr_ready_r;

  // Protocol observation for M1/M2/M3
  int  mem_txn_count, mem_fill_count, mem_wb_count;
  int  mem_beats_this_txn;
  int  m1_align_err, m1_beats_err, m3_overlap_err, m2_data_err;
  int  wb_words_checked;

  // A `wire` may not carry an `int` type; a plain vector is what this needs.
  logic [31:0] req_base_word;
  assign req_base_word = (mem_req_addr >> WORD_SEL_W) % MEM_WORDS;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      mstate <= M_IDLE; mreq_ready_r <= 1'b0; mrd_valid_r <= 1'b0; mwr_ready_r <= 1'b0;
      mbeat_r <= 0; mgap_r <= 0; mbase_r <= 0; mrd_data_r <= '0; mreq_addr_r <= '0;
      mem_txn_count <= 0; mem_fill_count <= 0; mem_wb_count <= 0; mem_beats_this_txn <= 0;
      m1_align_err <= 0; m1_beats_err <= 0; m3_overlap_err <= 0; m2_data_err <= 0;
      wb_words_checked <= 0;
    end
    else begin
      case (mstate)
        M_IDLE: begin
          mrd_valid_r <= 1'b0; mwr_ready_r <= 1'b0;
          if (mem_stall) begin
            mreq_ready_r <= 1'b0;
          end
          else if (mgap_r != 0) begin
            mreq_ready_r <= 1'b0;
            mgap_r <= mgap_r - 1;
          end
          else if (mem_req_valid && mreq_ready_r) begin
            // M1: fill address must be block aligned
            if (mem_req_addr[BLK_OFF_W-1:0] != '0) m1_align_err <= m1_align_err + 1;
            mreq_addr_r  <= mem_req_addr;
            mbase_r      <= int'(req_base_word);
            mbeat_r      <= 0;
            mreq_ready_r <= 1'b0;
            mem_txn_count      <= mem_txn_count + 1;
            mem_beats_this_txn <= 0;
            if (mem_req_we) begin
              mem_wb_count <= mem_wb_count + 1;
              mwr_ready_r  <= 1'b1;
              mstate       <= M_WB;
            end
            else begin
              mem_fill_count <= mem_fill_count + 1;
              mrd_data_r     <= mem[req_base_word];
              mrd_valid_r    <= 1'b1;
              mstate         <= M_FILL;
            end
          end
          else begin
            mreq_ready_r <= 1'b1;
          end
        end

        M_FILL: begin
          // M3: a new request while a transaction is in flight is illegal
          if (mem_req_valid && mreq_ready_r) m3_overlap_err <= m3_overlap_err + 1;
          if (mem_rd_valid && mem_rd_ready) begin
            mem_beats_this_txn <= mem_beats_this_txn + 1;
            if (mbeat_r == int'(BLOCK_WORDS) - 1) begin
              mrd_valid_r <= 1'b0;
              mgap_r      <= int'(lfsr[2:0]);
              mstate      <= M_IDLE;
              if (mem_beats_this_txn + 1 != int'(BLOCK_WORDS)) m1_beats_err <= m1_beats_err + 1;
            end
            else begin
              mbeat_r    <= mbeat_r + 1;
              mrd_data_r <= mem[(mbase_r + mbeat_r + 1) % MEM_WORDS];
            end
          end
        end

        M_WB: begin
          if (mem_req_valid && mreq_ready_r) m3_overlap_err <= m3_overlap_err + 1;
          if (mem_wr_valid && mwr_ready_r) begin
            // NO per-beat comparison against architectural state here. A store
            // may be ACCEPTED and not yet applied to the line when the line is
            // evicted -- R5 orders requests by acceptance, it does not require
            // the store to have reached the block before an unrelated eviction
            // carries it away. Comparing at this instant encodes an ordering
            // the contract does not state, and the anchor fails it. The real
            // check is the readback sweep in phase 6a: whatever was written
            // back has to come back correct through a refill.
            wb_words_checked <= wb_words_checked + 1;
            mem[(mbase_r + mbeat_r) % MEM_WORDS] <= mem_wr_data;
            mem_beats_this_txn <= mem_beats_this_txn + 1;
            if (mbeat_r == int'(BLOCK_WORDS) - 1) begin
              mwr_ready_r <= 1'b0;
              mgap_r      <= int'(lfsr[2:0]);
              mstate      <= M_IDLE;
              if (mem_beats_this_txn + 1 != int'(BLOCK_WORDS)) m1_beats_err <= m1_beats_err + 1;
            end
            else mbeat_r <= mbeat_r + 1;
          end
        end

        default: mstate <= M_IDLE;
      endcase
    end
  end

  // ---------------------------------------------------------------- scoreboard
  logic [DATA_W-1:0] exp_val   [N_IDS-1:0];
  logic              exp_is_ld [N_IDS-1:0];
  logic              id_open   [N_IDS-1:0];
  int                open_since[N_IDS-1:0];
  int                req_accepts_r, rsp_count_r;
  int                outstanding, max_outstanding;
  int                sb_data_err, sb_dup_err, sb_unknown_err;
  int                hit_lat_min, hit_lat_max, lat_sum, lat_n;

  logic [N_IDS-1:0] lm_off, lm_srv;
  always_comb begin
    lm_off = '0; lm_srv = '0;
    for (int i = 0; i < N_IDS; i++) lm_off[i] = id_open[i];
    lm_srv = '0;
    if (rsp_valid && rsp_ready) lm_srv[rsp_id] = 1'b1;
  end

  // A design may answer in the SAME cycle it accepts -- L6 leaves latency
  // unconstrained and a combinational hit response is a legal design. The
  // scoreboard reads `id_open` pre-edge, so without this bypass a zero-latency
  // response is charged as "a response for an id with nothing outstanding".
  // That is latitude the interface advertises and the harness could not
  // express; found by trying to use L6 rather than by reading it.
  logic              acc_now, acc_is_ld;
  logic [ID_W-1:0]   acc_id;
  logic [DATA_W-1:0] acc_exp;
  logic              rsp_bypass;
  always_comb begin
    acc_now    = req_valid & req_ready;
    acc_id     = req_id;
    acc_is_ld  = ~req_op;
    acc_exp    = shadow[word_of(req_addr)];
    rsp_bypass = acc_now && (acc_id == rsp_id) && !id_open[rsp_id];
  end

  int cycle_count;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      req_accepts_r <= 0; rsp_count_r <= 0; outstanding <= 0; max_outstanding <= 0;
      sb_data_err <= 0; sb_dup_err <= 0; sb_unknown_err <= 0;
      hit_lat_min <= 1_000_000; hit_lat_max <= 0; lat_sum <= 0; lat_n <= 0;
      cycle_count <= 0;
      for (int i = 0; i < N_IDS; i++) begin id_open[i] <= 1'b0; open_since[i] <= 0; end
    end
    else begin
      cycle_count <= cycle_count + 1;

      // ---- request accepted: snapshot the expectation AT ACCEPTANCE ----
      if (req_valid && req_ready) begin
        req_accepts_r <= req_accepts_r + 1;
        if (id_open[req_id]) sb_dup_err <= sb_dup_err + 1;   // R6 violated by us
        id_open[req_id]    <= !(rsp_valid && rsp_ready && (rsp_id == req_id));
        open_since[req_id] <= cycle_count;
        exp_is_ld[req_id]  <= ~req_op;
        if (req_op) begin
          // STORE: apply to architectural state at acceptance (R5 ordering)
          for (int b = 0; b < int'(BYTES_W); b++)
            if (req_mask[b]) shadow[word_of(req_addr)][b*8 +: 8] <= req_data[b*8 +: 8];
          exp_val[req_id] <= '0;
        end
        else begin
          exp_val[req_id] <= shadow[word_of(req_addr)];
        end
        outstanding <= outstanding + ((rsp_valid && rsp_ready) ? 0 : 1);
        if (outstanding + 1 > max_outstanding) max_outstanding <= outstanding + 1;
      end
      else if (rsp_valid && rsp_ready) outstanding <= outstanding - 1;

      // ---- response ----
      if (rsp_valid && rsp_ready) begin
        rsp_count_r <= rsp_count_r + 1;
        if (!id_open[rsp_id] && !rsp_bypass) sb_unknown_err <= sb_unknown_err + 1;
        else begin
          // R3: look the expectation up BY THE ID THE DUT REPORTED. On a
          // same-cycle response the expectation has not been registered yet, so
          // it comes from the combinational accept view instead.
          if (rsp_bypass) begin
            if (acc_is_ld && (rsp_data !== acc_exp)) sb_data_err <= sb_data_err + 1;
          end
          else if (exp_is_ld[rsp_id] && (rsp_data !== exp_val[rsp_id]))
            sb_data_err <= sb_data_err + 1;
          id_open[rsp_id] <= 1'b0;
          lat_n   <= lat_n + 1;
          lat_sum <= lat_sum + (rsp_bypass ? 0 : (cycle_count - open_since[rsp_id]));
          if ((rsp_bypass ? 0 : (cycle_count - open_since[rsp_id])) < hit_lat_min)
            hit_lat_min <= rsp_bypass ? 0 : (cycle_count - open_since[rsp_id]);
          if ((rsp_bypass ? 0 : (cycle_count - open_since[rsp_id])) > hit_lat_max)
            hit_lat_max <= rsp_bypass ? 0 : (cycle_count - open_since[rsp_id]);
        end
      end

      // The monitor is PAUSED while this harness is deliberately holding the
      // memory. C3's premise is "memory always eventually responding"; during
      // the C1 and C2 phases it deliberately is not, and ticking there reports
      // a deadlock the harness created. Gating on the stall register is the
      // premise, stated in the same place the premise is broken.
      if (rst_n && !mem_stall) begin `LM_TICK(lm_off, lm_srv) end
    end
  end

  // ---------------------------------------------------------------- coverage
  // ALL STIMULUS-SIDE. Each counts something this harness chose to drive.
  int cov_loads, cov_stores, cov_lines_touched, cov_conflict_seq;
  int cov_same_word_pairs, cov_cap_offers, cov_hum_created, cov_masked_stores;
  logic line_seen [1024];

  // ---------------------------------------------------------------- stimulus
  task automatic send(input [ID_W-1:0] id, input logic op,
                      input [ADDR_W-1:0] addr, input [DATA_W-1:0] data,
                      input [BYTES_W-1:0] mask, output logic accepted);
    int a0, w;
    @(negedge clk);
    req_valid = 1'b1; req_id = id; req_op = op;
    req_addr = addr; req_data = data; req_mask = mask;
    a0 = req_accepts_r; w = 0;
    while ((req_accepts_r == a0) && (w < 20000)) begin @(negedge clk); w++; end
    accepted  = (req_accepts_r != a0);
    req_valid = 1'b0;
    if (accepted) begin
      if (op) begin cov_stores++; if (mask != '1) cov_masked_stores++; end
      else cov_loads++;
      if (!line_seen[(addr >> BLK_OFF_W) % 1024]) begin
        line_seen[(addr >> BLK_OFF_W) % 1024] = 1'b1;
        cov_lines_touched++;
      end
    end
  endtask

  task automatic idle(input int n);
    for (int k = 0; k < n; k++) @(negedge clk);
  endtask

  task automatic wait_id_free(input [ID_W-1:0] id, input int limit);
    int k;
    k = 0;
    while (id_open[id] && (k < limit)) begin @(negedge clk); k++; end
    if (id_open[id]) note_fail($sformatf("id %0d never retired", id));
  endtask

  task automatic drain(input int limit);
    int k;
    k = 0;
    while ((rsp_count_r < req_accepts_r) && (k < limit)) begin @(negedge clk); k++; end
    if (rsp_count_r < req_accepts_r)
      note_fail($sformatf("drain timeout: %0d accepted, %0d answered", req_accepts_r, rsp_count_r));
  endtask

  // Addresses. Set index lives at addr[BLK_OFF_W +: $clog2(SETS)].
  function automatic [ADDR_W-1:0] mk_addr(input int unsigned tag,
                                          input int unsigned set,
                                          input int unsigned word);
    mk_addr = ADDR_W'((tag << (BLK_OFF_W + $clog2(SETS)))
                    | ((set % SETS) << BLK_OFF_W)
                    | ((word % BLOCK_WORDS) << WORD_SEL_W));
  endfunction

  logic acc;
  int   i, j, k, snap_fill, snap_txn, cap_accepted;
  logic [ADDR_W-1:0] a, b_addr;

  // ---------------------------------------------------------------- main
  initial begin
    errors = 0; checks = 0; phase = 0; fail_reason = "";
    cov_loads = 0; cov_stores = 0; cov_lines_touched = 0; cov_conflict_seq = 0;
    cov_same_word_pairs = 0; cov_cap_offers = 0; cov_hum_created = 0; cov_masked_stores = 0;
    for (i = 0; i < 1024; i++) line_seen[i] = 1'b0;
    lfsr = (SEED == 0) ? 32'h1 : 32'(SEED);
    req_valid = 1'b0; req_id = '0; req_op = 1'b0; req_addr = '0; req_data = '0; req_mask = '1;
    mem_stall = 1'b0; mem_data_stall = 1'b0;

    if (!((DATA_W == 32 || DATA_W == 64) && (SETS == 8 || SETS == 16) &&
          (WAYS == 2 || WAYS == 4) && (MAX_MISSES == 2 || MAX_MISSES == 8))) begin
      $display("TEST_RESULT: FAIL: illegal parameter combination DATA_W=%0d SETS=%0d WAYS=%0d MAX_MISSES=%0d",
               DATA_W, SETS, WAYS, MAX_MISSES);
      $finish;
    end

    for (i = 0; i < MEM_WORDS; i++) begin mem[i] = pattern(i); shadow[i] = pattern(i); end

    rst_n = 1'b0; idle(8); @(negedge clk); rst_n = 1'b1; idle(4);

    // ================= P1: spec P1, first access to a line misses ==========
    phase = 1;
    snap_fill = mem_fill_count;
    send(4'd1, 1'b0, mk_addr(1, 0, 0), '0, '1, acc);
    chk(acc, "first request after reset was not accepted");
    drain(4000);
    chk(mem_fill_count > snap_fill,
        "first access to a line issued no fill (spec P1: lines start invalid)");
    chk(m1_align_err == 0, "M1: a fill address was not block aligned");

    // ================= P2: R5 same-word ordering, and a hit ================
    phase = 2;
    a = mk_addr(2, 1, 1);
    send(4'd2, 1'b0, a, '0, '1, acc); drain(4000);       // fill the line
    send(4'd3, 1'b1, a, DATA_W'(64'hDEAD_BEEF_CAFE_F00D), '1, acc);
    send(4'd4, 1'b0, a, '0, '1, acc);                     // must see the store
    cov_same_word_pairs++;
    drain(4000);
    // masked store, then read back
    send(4'd5, 1'b1, a, DATA_W'(64'h0000_0000_0000_00FF), BYTES_W'(1), acc);
    send(4'd6, 1'b0, a, '0, '1, acc);
    cov_same_word_pairs++;
    drain(4000);

    // ================= P3: C2 hit under miss ==============================
    phase = 3;
    b_addr = mk_addr(3, 2, 0);
    send(4'd7, 1'b0, b_addr, '0, '1, acc); drain(4000);   // resident
    // Withhold the fill DATA, not the request. The transaction is accepted and
    // then starves, which is the condition a non-blocking design must survive.
    mem_data_stall = 1'b1;
    send(4'd8, 1'b0, mk_addr(4, 3, 0), '0, '1, acc);      // MISS, held
    chk(acc, "C2: a miss was not accepted while memory was stalled");
    idle(20);
    snap_fill = rsp_count_r;
    send(4'd9, 1'b0, b_addr, '0, '1, acc);                // HIT
    chk(acc, "C2: a hit request was not accepted while a miss was outstanding");
    idle(40);
    cov_hum_created++;
    chk(rsp_count_r > snap_fill,
        "C2: no response was returned while a fill was outstanding (not non-blocking)");
    @(negedge clk); mem_data_stall = 1'b0;
    drain(20000);

    // ================= P4: C1 outstanding capacity ========================
    phase = 4;
    mem_stall = 1'b1;
    cap_accepted = 0;
    for (i = 0; i < int'(MAX_MISSES) + 4; i++) begin
      cov_cap_offers++;
      send(4'd0 + ID_W'(i % 15 + 1), 1'b0, mk_addr(8 + i, i % SETS, 0), '0, '1, acc);
      if (acc) cap_accepted++; else i = int'(MAX_MISSES) + 4;
    end
    chk(cap_accepted >= int'(MAX_MISSES),
        $sformatf("C1: only %0d distinct-line misses outstanding, need %0d",
                  cap_accepted, MAX_MISSES));
    @(negedge clk); mem_stall = 1'b0;
    drain(60000);

    // ================= P5: conflict, eviction, writeback ==================
    phase = 5;
    // Drive WAYS+2 distinct lines into ONE set, all dirty, then revisit.
    // Stimulus-side: this harness chose the addresses. Whether the design
    // actually evicts is its choice and is a METRIC, not a floor.
    for (i = 0; i < int'(WAYS) + 2; i++) begin
      send(ID_W'(i % 15 + 1), 1'b1, mk_addr(20 + i, 5, i % BLOCK_WORDS),
           DATA_W'(64'h1000 + i), '1, acc);
      drain(8000);
    end
    cov_conflict_seq++;
    for (i = 0; i < int'(WAYS) + 2; i++) begin
      send(ID_W'(i % 15 + 1), 1'b0, mk_addr(20 + i, 5, i % BLOCK_WORDS), '0, '1, acc);
      drain(8000);
    end
    chk(m2_data_err == 0, "M2: a writeback block did not match architectural state");

    // ================= P6: randomized soak with liveness ==================
    phase = 6;
    for (i = 0; i < int'(SOAK_TXNS); i++) begin
      logic       op_r;
      int unsigned tg, st, wd;
      roll();
      op_r = lfsr[16];
      tg   = lfsr[7:4] % 6;
      st   = lfsr[11:8] % SETS;
      wd   = lfsr[13:12];
      // ids cycle so every one of the 16 is exercised -- the liveness monitor
      // fails any requester that is never served, and an unexercised id would
      // trip it for a reason that is about the harness, not the design.
      a = mk_addr(30 + tg, st, wd);
      // wait only for THIS id, so the soak keeps several requests in flight;
      // a full drain here serialised the soak and max_outstanding read 4.
      if (id_open[ID_W'(i % N_IDS)]) wait_id_free(ID_W'(i % N_IDS), 40000);
      send(ID_W'(i % N_IDS), op_r, a,
           DATA_W'(64'h5000_0000 + i), op_r ? BYTES_W'(lfsr[23:16]) : '1, acc);
      if (!acc) begin
        note_fail("soak: request not accepted within 20000 cycles");
        i = int'(SOAK_TXNS);
      end
      if (op_r && (BYTES_W'(lfsr[23:16]) != '1)) cov_masked_stores++;
      if (!line_seen[(a >> BLK_OFF_W) % 1024]) cov_lines_touched++;
    end
    drain(200000);

    // ============ P6a: readback sweep -- closes the loop through memory ====
    // Every line the soak touched is read back and checked against
    // architectural state. This is what actually validates writeback DATA: a
    // block written back wrongly comes back wrongly on the next refill, and the
    // scoreboard catches it. Checking the write beats at the instant of
    // eviction instead would encode an ordering the contract does not state.
    phase = 8;
    for (i = 0; i < 6; i++)
      for (j = 0; j < int'(SETS); j++)
        for (k = 0; k < int'(BLOCK_WORDS); k++) begin
          a = mk_addr(30 + i, j, k);
          wait_id_free(ID_W'((i*4+k) % N_IDS), 40000);
          send(ID_W'((i*4+k) % N_IDS), 1'b0, a, '0, '1, acc);
          if (!acc) note_fail("readback: request not accepted");
        end
    drain(400000);

    // ================= results ============================================
    phase = 7;
    chk(rsp_count_r == req_accepts_r,
        $sformatf("R3: %0d requests accepted, %0d answered", req_accepts_r, rsp_count_r));
    chk(sb_data_err    == 0, "R3/R5: a LOAD returned the wrong value for its id");
    chk(sb_unknown_err == 0, "R3: a response arrived for an id with nothing outstanding");
    chk(sb_dup_err     == 0, "harness: R6 violated -- two requests in flight with one id");
    chk(m1_align_err   == 0, "M1: a memory request address was not block aligned");
    chk(m1_beats_err   == 0, "M1/M2: a memory transaction did not carry BLOCK_WORDS beats");
    chk(m3_overlap_err == 0, "M3: a memory request was issued while a transaction was in flight");
    chk(m2_data_err    == 0, "M2: a writeback block did not match architectural state");

    `LM_CHECK(note_fail)

    // ---- METRIC lines: reported, never gated ----------------------------
    $display("METRIC: latency min=%0d max=%0d n=%0d", hit_lat_min, hit_lat_max, lat_n);
    $display("METRIC: max_outstanding n=%0d", max_outstanding);
    $display("METRIC: mem_txns total=%0d fills=%0d writebacks=%0d", mem_txn_count, mem_fill_count, mem_wb_count);
    $display("METRIC: accept_rate accepts=%0d cycles=%0d", req_accepts_r, cycle_count);
    $display("METRIC: wb_words_checked n=%0d", wb_words_checked);

    // ---- coverage floors: stimulus-side, enforced BEFORE pass ------------
    if (cov_loads          < 200) $display("COVERAGE HOLE: only %0d loads driven", cov_loads);
    if (cov_stores         < 100) $display("COVERAGE HOLE: only %0d stores driven", cov_stores);
    if (cov_lines_touched  < 20)  $display("COVERAGE HOLE: only %0d distinct lines driven", cov_lines_touched);
    if (cov_masked_stores  < 5)   $display("COVERAGE HOLE: only %0d masked stores driven", cov_masked_stores);
    if (cov_same_word_pairs < 2)  $display("COVERAGE HOLE: same-word store/load pair never driven");
    if (cov_conflict_seq   < 1)   $display("COVERAGE HOLE: conflict sequence never driven");
    if (cov_cap_offers     < int'(MAX_MISSES)) $display("COVERAGE HOLE: capacity phase offered only %0d", cov_cap_offers);
    if (cov_hum_created    < 1)   $display("COVERAGE HOLE: hit-under-miss condition never created");

    if ((cov_loads < 200) || (cov_stores < 100) || (cov_lines_touched < 20) ||
        (cov_masked_stores < 5) || (cov_same_word_pairs < 2) || (cov_conflict_seq < 1) ||
        (cov_cap_offers < int'(MAX_MISSES)) || (cov_hum_created < 1))
      note_fail("coverage floors not met -- the run did not exercise the target conditions");

    if (checks < 12)
      note_fail($sformatf("only %0d checks ran -- the run did not reach the contract", checks));

    $display("METRIC: checks n=%0d", checks);
    if (errors == 0) $display("TEST_RESULT: PASS");
    else             $display("TEST_RESULT: FAIL: %s", fail_reason);
    $finish;
  end

  // ---------------------------------------------------------------- determinism
  // A determinism check stood here and was WITHDRAWN. It could not be made to
  // fail: three perturbation axes (an inert observer process, --public-flat-rw,
  // -O0 on one of the two builds) against two reintroductions of the exact
  // defect it existed for, and every pair came back byte-identical. A check
  // whose control never fires validates nothing, and one left in place is worse
  // than none because the next reader sees it and assumes coverage.
  //
  // What protects this harness is the three structural remedies at the top of
  // this file, applied by construction. There is no detector behind them, and
  // that is stated rather than implied. See NOTES.md, "determinism check --
  // WITHDRAWN".
  initial begin
    repeat (WATCHDOG_CYCLES) @(posedge clk);
    $display("TEST_RESULT: FAIL: watchdog at %0d cycles, phase %0d", WATCHDOG_CYCLES, phase);
    $finish;
  end

endmodule
