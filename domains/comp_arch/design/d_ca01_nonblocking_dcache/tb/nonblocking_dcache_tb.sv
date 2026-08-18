// =============================================================================
// nonblocking_dcache_tb.sv  --  SCORING TESTBENCH  ***SKELETON, STEP 2***
// =============================================================================
// *** THIS IS NOT THE SCORING CHECKER YET. IT CHECKS FOUR THINGS. ***
//
// It exists so that the scored path can be proven to run end to end on this
// task BEFORE the interesting work is built on top of it -- d_dsp02 read as
// finished for days while being unscoreable, because the plumbing was deferred
// and every result came from hand-assembled invocations. This file is the
// plumbing, landed first on purpose.
//
// What it checks today, and nothing else:
//   A  the parameters are legal (illegal combination fails loudly, not silently)
//   B  a request is accepted within a bounded number of cycles after reset
//   C  the FIRST access to a line goes to memory rather than hitting -- this is
//      spec clause P1 VERIFIED rather than assumed, and it is checked on every
//      run precisely because P1 is otherwise only a build flag
//   D  exactly one response comes back, carrying the request's id and the word
//      the memory supplied
//
// What it does NOT check yet, and must not be read as checking: C1 outstanding
// capacity, C2 hit-under-miss, C3 forward progress, R4/R5 ordering, writeback,
// masked stores, or any coverage floor. Those are step 3. A submission passing
// this file has been shown to do one fill correctly and nothing more.
//
// HANDSHAKE DISCIPLINE, and it is not stylistic. Every transfer is observed by
// a MONOTONIC COUNTER clocked on the same edge the DUT uses, never by polling a
// combinational `ready` and never by testing a level flag that describes a
// completed transfer. Both of those produced a working design that looked
// jammed during step 1, neither errored, and one of them made two builds
// differing only by a debug process disagree. Stimulus moves on negedge only.
// =============================================================================

module nonblocking_dcache_tb #(
  parameter int unsigned DATA_W     = 32,
  parameter int unsigned SETS       = 16,
  parameter int unsigned WAYS       = 4,
  parameter int unsigned MAX_MISSES = 8
);

  localparam int unsigned ADDR_W      = 32;
  localparam int unsigned ID_W        = 4;
  localparam int unsigned BLOCK_WORDS = 4;
  localparam int unsigned BYTES_W     = DATA_W/8;
  localparam int unsigned WORD_SEL_W  = $clog2(BYTES_W);
  localparam int unsigned BLK_OFF_W   = WORD_SEL_W + $clog2(BLOCK_WORDS);

  // Watchdog. The longest thing this skeleton does is one fill: request
  // acceptance, a memory request, BLOCK_WORDS beats and a response -- under 40
  // cycles for any sane design. 20 000 cycles is a margin of roughly 500x,
  // chosen so a slow-but-correct design is never killed by it; the watchdog is
  // here to convert a hang into a verdict, not to measure speed.
  localparam int unsigned WATCHDOG_CYCLES = 20_000;

  // ---------------------------------------------------------------- bookkeeping
  int          errors, checks, phase;
  string       fail_reason;

  task automatic chk(input logic cond, input string msg);
    checks++;
    if (!cond) begin
      errors++;
      if (fail_reason == "") fail_reason = msg;
      $display("[FAIL] phase %0d: %s", phase, msg);
    end
  endtask

  // ---------------------------------------------------------------- clock/reset
  logic clk, rst_n;
  initial begin clk = 1'b0; forever #5 clk = ~clk; end

  // ---------------------------------------------------------------- DUT wiring
  logic                  req_valid, req_ready;
  logic [ID_W-1:0]       req_id;
  logic                  req_op;
  logic [ADDR_W-1:0]     req_addr;
  logic [DATA_W-1:0]     req_data;
  logic [BYTES_W-1:0]    req_mask;

  logic                  rsp_valid, rsp_ready;
  logic [ID_W-1:0]       rsp_id;
  logic [DATA_W-1:0]     rsp_data;

  logic                  mem_req_valid, mem_req_ready, mem_req_we;
  logic [ADDR_W-1:0]     mem_req_addr;
  logic                  mem_rd_valid, mem_rd_ready;
  logic [DATA_W-1:0]     mem_rd_data;
  logic                  mem_wr_valid, mem_wr_ready;
  logic [DATA_W-1:0]     mem_wr_data;

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

  // Responses are always taken. Driven CONSTANT rather than from rsp_valid: a
  // testbench input derived combinationally from a DUT output is an
  // evaluation-order dependency that produces no warning and can change
  // behaviour between builds.
  assign rsp_ready     = 1'b1;
  assign mem_req_ready = 1'b1;
  assign mem_wr_ready  = 1'b1;

  // ---------------------------------------------------------------- observation
  int req_accepts_r, rsp_count_r, mem_req_count_r;
  logic [ID_W-1:0]   rsp_id_r;
  logic [DATA_W-1:0] rsp_data_r;
  logic              rsp_taken_r;
  logic              mem_req_we_r;
  logic [ADDR_W-1:0] mem_req_addr_r;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      req_accepts_r <= 0; rsp_count_r <= 0; mem_req_count_r <= 0; rsp_taken_r <= 1'b0;
    end
    else begin
      if (req_valid     & req_ready)     req_accepts_r   <= req_accepts_r + 1;
      if (rsp_valid     & rsp_ready)     rsp_count_r     <= rsp_count_r + 1;
      if (mem_req_valid & mem_req_ready) begin
        mem_req_count_r <= mem_req_count_r + 1;
        mem_req_we_r    <= mem_req_we;
        mem_req_addr_r  <= mem_req_addr;
      end
      rsp_taken_r <= rsp_valid & rsp_ready;
      if (rsp_valid & rsp_ready) begin rsp_id_r <= rsp_id; rsp_data_r <= rsp_data; end
    end
  end

  // ---------------------------------------------------------------- memory model
  // Deterministic and never zero, so a fill that never happened cannot look
  // correct by returning 0.
  function automatic [DATA_W-1:0] pattern (input int unsigned word_addr);
    pattern = DATA_W'({~word_addr[15:0], word_addr[15:0]} ^ 32'hA5A5_0001);
  endfunction

  int unsigned fill_base_word;
  int          beat;

  initial begin
    mem_rd_valid = 1'b0; mem_rd_data = '0;
    forever begin
      @(negedge clk);
      if (mem_req_valid && mem_req_ready && !mem_req_we && rst_n) begin
        fill_base_word = mem_req_addr >> WORD_SEL_W;
        @(negedge clk);                       // request consumed at the posedge
        for (beat = 0; beat < BLOCK_WORDS; beat++) begin
          int f0;
          mem_rd_data  = pattern(fill_base_word + beat);
          mem_rd_valid = 1'b1;
          f0 = mem_fill_beats_r;
          while (mem_fill_beats_r == f0) @(negedge clk);
        end
        mem_rd_valid = 1'b0;
      end
    end
  end

  int mem_fill_beats_r;
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n)                            mem_fill_beats_r <= 0;
    else if (mem_rd_valid & mem_rd_ready)  mem_fill_beats_r <= mem_fill_beats_r + 1;
  end

  // ---------------------------------------------------------------- stimulus
  task automatic send_req (input [ID_W-1:0] id, input logic op,
                           input [ADDR_W-1:0] addr, input [DATA_W-1:0] data,
                           input [BYTES_W-1:0] mask, output logic accepted);
    int w, a0;
    @(negedge clk);
    req_valid = 1'b1; req_id = id; req_op = op;
    req_addr = addr; req_data = data; req_mask = mask;
    a0 = req_accepts_r; w = 0;
    while ((req_accepts_r == a0) && (w < 500)) begin @(negedge clk); w++; end
    accepted  = (req_accepts_r != a0);
    req_valid = 1'b0;
  endtask

  logic accepted;
  int   w;
  localparam [ADDR_W-1:0] A0 = 32'h0000_2100;

  initial begin
    errors = 0; checks = 0; phase = 0; fail_reason = "";
    req_valid = 1'b0; req_id = '0; req_op = 1'b0;
    req_addr = '0; req_data = '0; req_mask = '1;

    // ---- A: illegal-parameter guard -------------------------------------
    phase = 0;
    if (!((DATA_W == 32 || DATA_W == 64) && (SETS == 8 || SETS == 16) &&
          (WAYS  == 2  || WAYS  == 4)   && (MAX_MISSES == 2 || MAX_MISSES == 8))) begin
      $display("TEST_RESULT: FAIL: illegal parameter combination DATA_W=%0d SETS=%0d WAYS=%0d MAX_MISSES=%0d",
               DATA_W, SETS, WAYS, MAX_MISSES);
      $finish;
    end

    rst_n = 1'b0;
    repeat (8) @(negedge clk);
    rst_n = 1'b1;
    repeat (4) @(negedge clk);

    // ---- B: a request is accepted ---------------------------------------
    phase = 1;
    send_req(4'd5, 1'b0, A0, '0, '1, accepted);
    chk(accepted, "no request accepted within 500 cycles after reset");

    if (accepted) begin
      // ---- C: P1 -- the first access to a line goes to memory ------------
      phase = 2;
      w = 0;
      while ((mem_req_count_r == 0) && (w < 2000)) begin @(negedge clk); w++; end
      chk(mem_req_count_r >= 1,
          "first access to a line issued no memory request (spec P1: lines start invalid)");
      if (mem_req_count_r >= 1) begin
        chk(mem_req_we_r == 1'b0, "first memory request was a writeback, not a fill");
        chk(mem_req_addr_r[BLK_OFF_W-1:0] == '0, "fill address is not block aligned");
        chk(mem_req_addr_r[ADDR_W-1:BLK_OFF_W] == A0[ADDR_W-1:BLK_OFF_W],
            "fill address is not the block containing the request");
      end

      // ---- D: exactly one response, right id, right data -----------------
      phase = 3;
      w = 0;
      while ((rsp_count_r == 0) && (w < 4000)) begin @(negedge clk); w++; end
      chk(rsp_count_r >= 1, "no response to the accepted request");
      if (rsp_count_r >= 1) begin
        chk(rsp_id_r == 4'd5, "response id does not match the request id");
        chk(rsp_data_r == pattern(A0 >> WORD_SEL_W), "response data is not the word memory supplied");
        repeat (200) @(negedge clk);
        chk(rsp_count_r == 1, "more than one response for a single request");
      end
    end

    // ---- verdict ---------------------------------------------------------
    $display("METRIC: skeleton_checks n=%0d", checks);
    if (checks < 4) begin
      $display("TEST_RESULT: FAIL: only %0d checks ran -- the run did not reach the contract", checks);
    end
    else if (errors == 0) $display("TEST_RESULT: PASS");
    else                  $display("TEST_RESULT: FAIL: %s", fail_reason);
    $finish;
  end

  // Watchdog: a wedged harness and a dead design emit exactly the same thing.
  initial begin
    repeat (WATCHDOG_CYCLES) @(posedge clk);
    $display("TEST_RESULT: FAIL: watchdog at %0d cycles, phase %0d", WATCHDOG_CYCLES, phase);
    $finish;
  end

endmodule
