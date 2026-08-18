// =============================================================================
// v_dsp02 PROVIDED PLUMBING -- shipped inside the task text.
// =============================================================================
// This issues operations and collects results. It checks nothing and scores
// nothing.
//
// WHAT IT DOES NOT HAND OVER
// --------------------------
// This task's difficulty is the corner space -- signed zeros, quiet versus
// signalling NaNs, payload preservation, the minNum/maxNum question -- and none
// of that is touched here. The handshake it encodes (H1, H2, H3, H4) is stated
// verbatim in the specification, so nothing is given away that a reader does not
// already have. Deciding WHICH operations to issue, and what each one should
// return, is the entire task and is untouched.
// =============================================================================

  // ---- clock -----------------------------------------------------------------
  logic clk;
  initial begin clk = 1'b0; forever #5 clk = ~clk; end

  // ---- reset (active low, synchronous) ---------------------------------------
  logic rst_n;
  initial rst_n = 1'b0;

  task automatic bfm_reset(input int cycles = 4);
    @(negedge clk);
    rst_n = 1'b0;
    repeat (cycles) @(posedge clk);
    @(negedge clk);
    rst_n = 1'b1;
  endtask

  // ---- issue -----------------------------------------------------------------
  // Presents one operation at the negative edge, holds every input stable until
  // it is accepted (the obligation H4 states), and returns on acceptance.
  // Calling it again immediately presents the next operation with valid still
  // high, so back-to-back issue is available.
  task automatic bfm_issue(input logic [31:0] a,
                           input logic [31:0] b,
                           input logic [1:0]  op,
                           input logic [2:0]  mode);
    @(negedge clk);
    operand_a_i = a;
    operand_b_i = b;
    op_i        = op;
    op_mode_i   = mode;
    in_valid_i  = 1'b1;
    forever begin
      @(posedge clk);
      if (in_ready_o) break;
    end
  endtask

  // Stops issuing.
  task automatic bfm_idle();
    @(negedge clk);
    in_valid_i = 1'b0;
  endtask

  // ---- result side -----------------------------------------------------------
  // Sets the sink's ready, at the negative edge only.
  task automatic bfm_out_ready(input logic value);
    @(negedge clk);
    out_ready_i = value;
  endtask

  // ---- watchdog (S16) --------------------------------------------------------
  initial begin
    #200_000_000;
    $display("RESULT: FAIL (watchdog: no forward progress)");
    $finish;
  end
