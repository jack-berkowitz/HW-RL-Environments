// ---------------------------------------------------------------------------
// PROVIDED PLUMBING -- moves beats, checks nothing.
// ---------------------------------------------------------------------------
// This exists so you spend your effort on checking rather than on handshake
// mechanics. It has been compiled and run against a correct implementation.
//
// What it does: generates the clock, sequences reset, offers one beat at a
// time on a chosen input and returns once that beat has transferred, and lets
// you set the output-side ready.
//
// What it does NOT do: it has no notion of a frame, keeps no model of the
// design's contents, and draws no conclusion from any signal. Framing,
// ordering, integrity, fairness and every check are yours to write.
// ---------------------------------------------------------------------------
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
