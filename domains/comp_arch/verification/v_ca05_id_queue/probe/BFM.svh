// =============================================================================
// v_ca05 PROVIDED PLUMBING -- shipped inside the task text.
// =============================================================================
// Clock, reset and watchdog only.
//
// *** NO TRANSACTOR IS PROVIDED FOR THE REQUEST/GRANT PORTS, AND THAT IS
// DELIBERATE. *** Deciding when a request has actually completed is part of
// what this task measures, and a driver that answered it would answer the
// question instead of asking it. The specification states the rule; read it.
//
// What is provided is the timing discipline, because that is what breaks
// testbenches without telling you anything: reset is asserted and released off
// the sampling edge, and the helper below changes stimulus at the negative edge
// so nothing you drive moves in the same timestep the design samples it.
// =============================================================================

  // ---- clock -----------------------------------------------------------------
  logic clk;
  initial begin clk = 1'b0; forever #5 clk = ~clk; end

  // ---- reset (active low) ----------------------------------------------------
  logic rst_n;
  initial rst_n = 1'b0;

  task automatic bfm_reset(input int cycles = 4);
    @(negedge clk);
    rst_n = 1'b0;
    repeat (cycles) @(posedge clk);
    @(negedge clk);
    rst_n = 1'b1;
  endtask

  // ---- timing discipline -----------------------------------------------------
  // Advance to the point in the cycle where it is safe to change stimulus.
  // Drive your inputs immediately after calling this, never straight after a
  // @(posedge clk): an assignment in the same timestep as the sampling edge
  // races the design and makes correct hardware look inert.
  task automatic bfm_drive_point();
    @(negedge clk);
  endtask

  // Advance one full cycle and return after the design has sampled.
  task automatic bfm_tick();
    @(posedge clk);
  endtask

  // ---- watchdog --------------------------------------------------------------
  initial begin
    #20_000_000;
    $display("RESULT: FAIL (watchdog: no forward progress)");
    $finish;
  end
