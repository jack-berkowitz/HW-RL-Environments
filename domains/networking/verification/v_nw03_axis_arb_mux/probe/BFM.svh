// =============================================================================
// v_nw03 PROVIDED PLUMBING -- shipped inside the task text.
// =============================================================================
// This moves beats. It checks nothing, scores nothing, and decides nothing.
//
// WHAT IT DELIBERATELY DOES NOT DO, and why
// -----------------------------------------
// S6 -- "ready is not a grant" -- is this task's load-bearing clause, and the
// whole point of the exercise is whether a submission reads it. So this file:
//
//   * never inspects s_tready_o except to detect that the beat it is currently
//     offering has transferred, which is S1 and is stated in the specification;
//   * never reports, returns, counts or names a "grant", a "selection", or an
//     "acceptance" of anything larger than one beat;
//   * has no notion of a frame. bfm_send moves ONE beat. Framing, ordering,
//     atomicity, fairness and the whole scoreboard are the submission's job.
//
// A submission can still get S6 wrong in exactly the way the clause warns
// about, because nothing here tells it what a transferred input beat implies
// about the output.
//
// The three defects this replaces were all plumbing and none was about
// checking: a reset asserted in the same timestep as the edge it was sampled
// on, operands driven and sampled in one timestep, and a testbench that never
// gave the design a stable beat to take.
// =============================================================================

  // ---- clock -----------------------------------------------------------------
  logic clk;
  initial begin clk = 1'b0; forever #5 clk = ~clk; end

  // ---- reset -----------------------------------------------------------------
  logic rst;
  initial rst = 1'b1;

  // Asserts reset, holds it, and releases it OFF the sampling edge so nothing
  // you or the design samples changes in the same timestep as the change.
  task automatic bfm_reset(input int cycles = 4);
    @(negedge clk);
    rst = 1'b1;
    repeat (cycles) @(posedge clk);
    @(negedge clk);
    rst = 1'b0;
  endtask

  // ---- input side ------------------------------------------------------------
  // Offers ONE beat on input k and returns once that beat has transferred.
  // Every field is presented at the negative edge and held stable until the
  // transfer, which is the source obligation S7 states.
  //
  // Calling bfm_send again immediately presents the next beat with valid still
  // high, so back-to-back beats and continuous offered load are available.
  task automatic bfm_send(input int                          k,
                          input logic [DATA_WIDTH-1:0]       data,
                          input logic [(DATA_WIDTH/8)-1:0]   keep,
                          input logic                        last,
                          input logic [USER_WIDTH-1:0]       user);
    @(negedge clk);
    s_tdata[k]  = data;
    s_tkeep[k]  = keep;
    s_tlast[k]  = last;
    s_tuser[k]  = user;
    s_tvalid[k] = 1'b1;
    forever begin
      @(posedge clk);
      if (s_tready[k]) break;
    end
  endtask

  // Stops offering on input k.
  task automatic bfm_idle(input int k);
    @(negedge clk);
    s_tvalid[k] = 1'b0;
  endtask

  // ---- output side -----------------------------------------------------------
  // Sets the sink's ready. Changed at the negative edge, never at the edge the
  // design samples it on.
  task automatic bfm_ready(input logic value);
    @(negedge clk);
    m_tready = value;
  endtask

  // ---- watchdog (S13) --------------------------------------------------------
  // Yours to keep. It fires regardless of what the design does, which is what
  // S13 requires; one of the faulty designs never selects an input that a
  // correct one would.
  initial begin
    #20_000_000;
    $display("RESULT: FAIL (watchdog: no forward progress)");
    $finish;
  end
