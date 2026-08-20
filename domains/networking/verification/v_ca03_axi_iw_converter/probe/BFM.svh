// ---------------------------------------------------------------------------
// PROVIDED PLUMBING -- moves transactions, checks nothing.
// ---------------------------------------------------------------------------
// This exists so you spend your effort on checking rather than on handshake
// mechanics. It has been compiled and run against a correct implementation.
//
// What it does: generates the clock, sequences reset, offers one address
// request at a time and REPORTS whether it was accepted and after how many
// cycles, and lets you present responses on the downstream port.
//
// What it does NOT do: it never decides whether a request SHOULD have been
// accepted, never tracks what is outstanding, and never chooses a response
// order. Those are the task.
// ---------------------------------------------------------------------------

  logic clk;
  initial begin clk = 1'b0; forever #5 clk = ~clk; end

  logic rst_n;
  initial rst_n = 1'b0;

  // Asserted and released away from the sampling edge.
  task automatic bfm_reset(input int cycles = 4);
    @(negedge clk);
    rst_n = 1'b0;
    repeat (cycles) @(posedge clk);
    @(negedge clk);
    rst_n = 1'b1;
  endtask

  // Offer a read address and hold it stable until accepted or the budget runs
  // out. Reports BOTH facts: whether it went, and how many cycles it waited.
  // Interpreting a refusal is yours.
  task automatic bfm_ar(input  logic [SLV_ID_W-1:0] id,
                        input  logic [ADDR_W-1:0]   addr,
                        input  logic [7:0]          len,
                        input  int                  budget,
                        output bit                  accepted,
                        output int                  waited);
    accepted = 1'b0; waited = 0;
    @(negedge clk);
    s_arid = id; s_araddr = addr; s_arlen = len; s_arvalid = 1'b1;
    while (waited < budget) begin
      @(posedge clk);
      if (s_arready) begin accepted = 1'b1; break; end
      waited++;
    end
    @(negedge clk) s_arvalid = 1'b0;
  endtask

  // The same for a write address.
  task automatic bfm_aw(input  logic [SLV_ID_W-1:0] id,
                        input  logic [ADDR_W-1:0]   addr,
                        input  logic [7:0]          len,
                        input  int                  budget,
                        output bit                  accepted,
                        output int                  waited);
    accepted = 1'b0; waited = 0;
    @(negedge clk);
    s_awid = id; s_awaddr = addr; s_awlen = len; s_awvalid = 1'b1;
    while (waited < budget) begin
      @(posedge clk);
      if (s_awready) begin accepted = 1'b1; break; end
      waited++;
    end
    @(negedge clk) s_awvalid = 1'b0;
  endtask

  // One write data beat.
  task automatic bfm_w(input logic [DATA_W-1:0]   data,
                       input logic [DATA_W/8-1:0] strb,
                       input logic                last);
    @(negedge clk);
    s_wdata = data; s_wstrb = strb; s_wlast = last; s_wvalid = 1'b1;
    forever begin @(posedge clk); if (s_wready) break; end
    @(negedge clk) s_wvalid = 1'b0;
  endtask

  // Present one downstream read response beat with the given master identifier.
  // WHICH identifier, and in what order, is yours to decide.
  task automatic bfm_rbeat(input logic [MST_ID_W-1:0] mid,
                           input logic [DATA_W-1:0]   data,
                           input logic                last);
    @(negedge clk);
    m_rid = mid; m_rdata = data; m_rlast = last; m_rresp = 2'b00; m_rvalid = 1'b1;
    forever begin @(posedge clk); if (m_rready) break; end
    @(negedge clk) m_rvalid = 1'b0;
  endtask

  // Present one downstream write response.
  task automatic bfm_bbeat(input logic [MST_ID_W-1:0] mid);
    @(negedge clk);
    m_bid = mid; m_bresp = 2'b00; m_bvalid = 1'b1;
    forever begin @(posedge clk); if (m_bready) break; end
    @(negedge clk) m_bvalid = 1'b0;
  endtask

  // Watchdog. Fires regardless of what the design does -- one of the faulty
  // implementations refuses a request it should accept.
  initial begin
    #4_000_000;
    $display("RESULT: FAIL (watchdog: no forward progress)");
    $finish;
  end
