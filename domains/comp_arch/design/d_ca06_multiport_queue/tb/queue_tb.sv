// d_ca06 scoring testbench -- queue.
//
// Drives the candidate and a behavioural model with identical stimulus and
// compares the T1 surface every cycle. The model is written from the SPEC, not
// from the reference RTL, so a shared misreading cannot pass both.
//
// THE SURFACE IS write_accept, read_valid, AND read_data WHERE read_valid IS
// HIGH. read_data on a port whose read_valid is low is explicitly unconstrained
// (F5) and comparing it would fail conforming designs that leave it dangling.

`timescale 1ns/1ps

module queue_tb;

  // ---- scored geometry, overridable for the sweep ---------------------------
  parameter int PW    = 4;            // PTR_WIDTH -> DEPTH = 16
  parameter int DW    = 32;           // $bits(T)
  parameter int PORTS = 3;
  localparam int DEPTH = 1 << PW;

  logic clk = 0, rst_n = 0;
  always #5 clk = ~clk;

  logic [PORTS-1:0][DW-1:0] wdata;
  logic [PORTS-1:0]         wvalid, waccept;
  logic [PORTS-1:0][DW-1:0] rdata;
  logic [PORTS-1:0]         rvalid;
  logic [PORTS-1:0]         raccept;

  queue #(.DW(DW), .PTR_WIDTH(PW), .PORTS(PORTS)) dut (
    .clk(clk), .rst_n(rst_n),
    .write_data(wdata), .write_valid(wvalid), .write_accept(waccept),
    .read_data(rdata),  .read_valid(rvalid),  .read_accept(raccept)
  );

  // ---- behavioural model, written from the spec -----------------------------
  logic [DW-1:0] m_mem [DEPTH];
  int            m_head, m_tail;
  bit            m_full_flag;          // F2: the last-op-write distinction
  int            m_occ, m_vac;

  function automatic int occupancy();
    if (m_tail != m_head) return (m_tail - m_head + DEPTH) % DEPTH;
    return m_full_flag ? DEPTH : 0;
  endfunction

  // Expected combinational outputs from the state BEFORE this edge (A1).
  logic [PORTS-1:0]         e_waccept, e_rvalid;
  logic [PORTS-1:0][DW-1:0] e_rdata;

  always_comb begin
    m_occ = occupancy();
    m_vac = DEPTH - m_occ;
    for (int i = 0; i < PORTS; i++) begin
      e_waccept[i] = (i < m_vac);               // F3: space alone
      e_rvalid[i]  = (i < m_occ);               // F5
      e_rdata[i]   = m_mem[(m_head + i) % DEPTH];
    end
  end

  // ---- scoring --------------------------------------------------------------
  int errors = 0, cycles = 0, checks = 0;
  int n_nonprefix = 0, n_full = 0, n_empty = 0, n_wrap = 0, n_allports = 0;
  string first_fail = "";

  task automatic record(string what);
    if (errors == 0) first_fail = what;
    errors++;
  endtask

  task automatic compare();
    checks++;
    if (waccept !== e_waccept)
      record($sformatf("write_accept: got %b expected %b at cycle %0d (occ=%0d)",
                       waccept, e_waccept, cycles, m_occ));
    if (rvalid !== e_rvalid)
      record($sformatf("read_valid: got %b expected %b at cycle %0d (occ=%0d)",
                       rvalid, e_rvalid, cycles, m_occ));
    for (int i = 0; i < PORTS; i++)
      if (e_rvalid[i] && rdata[i] !== e_rdata[i])
        record($sformatf("read_data[%0d]: got %0h expected %0h at cycle %0d",
                         i, rdata[i], e_rdata[i], cycles));
  endtask

  // Advance the model exactly as F4, F6 and F7 prescribe.
  task automatic model_step();
    int wr_n = 0, rd_last = -1;
    int occ_before = occupancy();
    for (int i = 0; i < PORTS; i++) begin
      if (wvalid[i] && e_waccept[i]) begin
        m_mem[(m_tail + wr_n) % DEPTH] = wdata[i];   // F4: compaction
        wr_n++;
      end
      if (raccept[i] && e_rvalid[i]) rd_last = i;    // F6: highest, not count
    end
    if (rd_last >= 0) begin
      m_head = (m_head + rd_last + 1) % DEPTH;
      n_nonprefix += ($countones(raccept & e_rvalid) != rd_last + 1);
    end
    m_tail = (m_tail + wr_n) % DEPTH;
    begin
      int rd_n = (rd_last >= 0) ? rd_last + 1 : 0;   // entries actually removed
      if (wr_n != rd_n) m_full_flag = (wr_n > rd_n); // F7
    end
    if (occ_before == DEPTH) n_full++;
    if (occ_before == 0)     n_empty++;
    if (m_tail < wr_n)       n_wrap++;
    if (&wvalid && &raccept) n_allports++;
  endtask

  task automatic do_reset();
    rst_n = 0; wvalid = '0; raccept = '0; wdata = '0;
    @(posedge clk); #1;
    for (int i = 0; i < DEPTH; i++) m_mem[i] = '0;
    m_head = 0; m_tail = 0; m_full_flag = 0;
    rst_n = 1; @(posedge clk); #1;
  endtask

  task automatic drive(logic [PORTS-1:0] wv, logic [PORTS-1:0] ra);
    for (int i = 0; i < PORTS; i++) wdata[i] = $urandom();
    wvalid = wv; raccept = ra;
    #1 compare();                 // outputs reflect pre-edge state (A1)
    model_step();
    @(posedge clk); #1;
    cycles++;
  endtask

  initial begin
    do_reset();

    // T3/T4: fill to full, drain to empty, exercising wrap on the way.
    repeat (3) begin
      for (int n = 0; n < DEPTH + 4; n++) drive(3'b111, 3'b000);
      for (int n = 0; n < DEPTH + 4; n++) drive(3'b000, 3'b111);
    end

    // T3: the balanced cycle at both boundaries (F7).
    for (int n = 0; n < DEPTH; n++) drive(3'b111, 3'b000);
    repeat (6) drive(3'b111, 3'b111);          // full, balanced
    for (int n = 0; n < DEPTH; n++) drive(3'b000, 3'b111);
    repeat (6) drive(3'b000, 3'b000);          // empty, balanced

    // T2: every legal combination against a partly filled queue.
    for (int wv = 0; wv < (1<<PORTS); wv++)
      for (int ra = 0; ra < (1<<PORTS); ra++) begin
        do_reset();
        for (int n = 0; n < PORTS + 1; n++) drive(3'b111, 3'b000);
        drive(wv[PORTS-1:0], ra[PORTS-1:0]);
        repeat (2) drive(3'b000, 3'b000);
      end

    // T2: random traffic, non-prefix accepts included by construction.
    do_reset();
    repeat (4000) drive($urandom_range(0, (1<<PORTS)-1),
                        $urandom_range(0, (1<<PORTS)-1));

    // T5: reset mid-traffic.
    repeat (20) drive(3'b101, 3'b001);
    do_reset();
    repeat (20) drive(3'b011, 3'b011);

    $display("METRIC: cycles=%0d checks=%0d nonprefix_accepts=%0d full_cycles=%0d empty_cycles=%0d wrap_events=%0d allports_cycles=%0d",
             cycles, checks, n_nonprefix, n_full, n_empty, n_wrap, n_allports);

    // RULE 36 FLOORS. A run that never reached these states proved nothing
    // about them, and a pass would be a statement about the stimulus.
    // TEST_RESULT: is the verdict token the harness reads. A testbench that
    // prints its own wording is scored NO_VERDICT -- the run happens, nothing
    // records what it concluded, and absence renders as absence.
    if (n_nonprefix < 50)
      $display("COVERAGE HOLE: only %0d non-prefix accepts, need >= 50 (F6 unexercised)", n_nonprefix);
    if (n_full < 10)
      $display("COVERAGE HOLE: only %0d full cycles, need >= 10 (F2 unexercised)", n_full);
    if (n_empty < 10)
      $display("COVERAGE HOLE: only %0d empty cycles, need >= 10 (F2 unexercised)", n_empty);
    if (n_allports < 10)
      $display("COVERAGE HOLE: only %0d all-ports cycles, need >= 10 (A3 unexercised)", n_allports);

    if (errors == 0)
      $display("TEST_RESULT: PASS -- %0d checks over %0d cycles, 0 mismatches", checks, cycles);
    else
      $display("TEST_RESULT: FAIL: %0d mismatches over %0d cycles -- first: %s",
               errors, cycles, first_fail);

    $finish;
  end

endmodule
