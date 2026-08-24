module frame_arb_mux_tb;

  localparam int S_COUNT    = 4;
  localparam int DATA_WIDTH = 32;
  localparam int USER_WIDTH = 1;

  // ---- Port signals --------------------------------------------------------
  logic [S_COUNT-1:0][DATA_WIDTH-1:0]       s_tdata;
  logic [S_COUNT-1:0][(DATA_WIDTH/8)-1:0]   s_tkeep;
  logic [S_COUNT-1:0]                       s_tvalid;
  logic [S_COUNT-1:0]                       s_tready;
  logic [S_COUNT-1:0]                       s_tlast;
  logic [S_COUNT-1:0][USER_WIDTH-1:0]       s_tuser;

  logic [DATA_WIDTH-1:0]                    m_tdata;
  logic [(DATA_WIDTH/8)-1:0]                m_tkeep;
  logic                                     m_tvalid;
  logic                                     m_tready;
  logic                                     m_tlast;
  logic [USER_WIDTH-1:0]                    m_tuser;

  // ---- DUT Instantiation ---------------------------------------------------
  frame_arb_mux #(
      .S_COUNT(S_COUNT),
      .DATA_WIDTH(DATA_WIDTH),
      .USER_WIDTH(USER_WIDTH)
  ) dut (
      .clk_i(clk),
      .rst_i(rst),
      .s_tdata_i(s_tdata),
      .s_tkeep_i(s_tkeep),
      .s_tvalid_i(s_tvalid),
      .s_tready_o(s_tready),
      .s_tlast_i(s_tlast),
      .s_tuser_i(s_tuser),
      .m_tdata_o(m_tdata),
      .m_tkeep_o(m_tkeep),
      .m_tvalid_o(m_tvalid),
      .m_tready_i(m_tready),
      .m_tlast_o(m_tlast),
      .m_tuser_o(m_tuser)
  );

// ---------------------------------------------------------------------------
// PROVIDED PLUMBING -- moves beats, checks nothing.
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

// ---------------------------------------------------------------------------
// TESTBENCH IMPLEMENTATION
// ---------------------------------------------------------------------------

  typedef enum {IDLE, BACKPRESSURE, FAIRNESS} test_phase_e;
  test_phase_e test_phase = IDLE;
  int bp_counter = 0;

  typedef struct packed {
      logic [DATA_WIDTH-1:0]       data;
      logic [(DATA_WIDTH/8)-1:0]   keep;
      logic                        last;
      logic [USER_WIDTH-1:0]       user;
  } beat_t;

  beat_t ref_queues[S_COUNT][$];
  int active_source = -1;
  int fairness_window[$];
  logic was_rst;

  // Payload Encoders/Decoders for unique identification per beat
  function automatic logic [31:0] build_data(int src, int fseq, int bseq);
      return {8'hA5, 8'(src), 8'(fseq), 8'(bseq)};
  endfunction

  function automatic int extract_source(logic [31:0] d);
      if (d[31:24] != 8'hA5) return -1;
      return int'(d[23:16]);
  endfunction

  // Background task to toggle m_tready_i for backpressure scenario
  task automatic run_backpressure();
      forever begin
          if (test_phase == BACKPRESSURE) begin
              bp_counter++;
              bfm_ready((bp_counter % 3) != 0); // 66% ready duty cycle
          end else begin
              bfm_ready(1'b1);
          end
      end
  endtask

  // Wait until all strictly fully-submitted frames have transferred out
  task automatic wait_for_complete_frames();
      int count = 0;
      while (count < 1000) begin
          bit has_complete = 0;
          for (int i=0; i<S_COUNT; i++) begin
              foreach (ref_queues[i][j]) begin
                  if (ref_queues[i][j].last) has_complete = 1'b1;
              end
          end
          if (!has_complete) return;
          @(posedge clk);
          count++;
      end
  endtask

  // Stimulus task to submit full multi-beat frames
  task automatic send_frame(int src, int fseq, int num_beats);
      for (int b = 0; b < num_beats; b++) begin
          logic last = (b == num_beats - 1);
          bfm_send(src, build_data(src, fseq, b), 4'hF, last, 1'b1);
      end
      bfm_idle(src);
  endtask

  // Main Checker Block
  always @(posedge clk) begin : checker_block
      if (was_rst && !rst) begin
          if (m_tvalid) begin
              $display("RESULT: FAIL (S12: m_tvalid_o not low on the first cycle after reset release)");
              $finish;
          end
      end
      was_rst <= rst;

      if (rst) begin
          for (int i=0; i<S_COUNT; i++) ref_queues[i].delete();
          active_source <= -1;
          fairness_window.delete();
      end else begin
          
          // 1. Observe input queues
          for (int i=0; i<S_COUNT; i++) begin
              if (s_tvalid[i] && s_tready[i]) begin
                  automatic beat_t b;
                  b.data = s_tdata[i];
                  b.keep = s_tkeep[i];
                  b.last = s_tlast[i];
                  b.user = s_tuser[i];
                  ref_queues[i].push_back(b);
              end
          end

          // 2. Observe and verify outputs
          if (m_tvalid && m_tready) begin
              automatic beat_t out_b;
              automatic int beat_src;
              
              out_b.data = m_tdata;
              out_b.keep = m_tkeep;
              out_b.last = m_tlast;
              out_b.user = m_tuser;
              beat_src = extract_source(out_b.data);

              if (active_source == -1) begin
                  active_source = beat_src;
                  if (active_source < 0 || active_source >= S_COUNT) begin
                      $display("RESULT: FAIL (S4: Output data payload corrupt or originated from unknown source)");
                      $finish;
                  end
                  
                  // Track S10 fairness constraint
                  if (test_phase == FAIRNESS) begin
                      fairness_window.push_back(active_source);
                      if (fairness_window.size() > 16) void'(fairness_window.pop_front());
                      if (fairness_window.size() == 16) begin
                          automatic bit [S_COUNT-1:0] seen = '0;
                          foreach (fairness_window[j]) seen[fairness_window[j]] = 1'b1;
                          if (seen != {S_COUNT{1'b1}}) begin
                              $display("RESULT: FAIL (S10: Fairness violated. A source was starved within 16 consecutive output frames under continuous load)");
                              $finish;
                          end
                      end
                  end
              end else begin
                  if (beat_src != active_source) begin
                      $display("RESULT: FAIL (S3: Frame atomicity violated. Interleaved beat from %0d during frame from %0d)", beat_src, active_source);
                      $finish;
                  end
              end

              if (ref_queues[active_source].size() == 0) begin
                  $display("RESULT: FAIL (S4: Output beat transferred but none expected from source %0d)", active_source);
                  $finish;
              end
              
              begin
                  automatic beat_t exp_b = ref_queues[active_source].pop_front();
                  if (out_b.data !== exp_b.data || out_b.keep !== exp_b.keep || 
                      out_b.user !== exp_b.user || out_b.last !== exp_b.last) begin
                      $display("RESULT: FAIL (S4: Payload integrity mismatch on output)");
                      $finish;
                  end
              end

              if (out_b.last) begin
                  active_source = -1;
              end
          end
      end
  end

  // Test Sequencer
  initial begin
      // Initialize variables
      for (int i=0; i<S_COUNT; i++) begin
          s_tvalid[i] = 1'b0;
          s_tdata[i] = '0;
          s_tkeep[i] = '0;
          s_tlast[i] = '0;
          s_tuser[i] = '0;
      end
      m_tready = 1'b0;
      
      fork run_backpressure(); join_none

      #100;
      bfm_reset();

      // Phase 1: Basic Sequential Transfers
      send_frame(0, 1, 3);
      send_frame(1, 1, 1);
      send_frame(2, 1, 4);
      send_frame(3, 1, 2);
      wait_for_complete_frames();

      // Phase 2: Concurrent Multi-Input Transfers
      fork
          send_frame(0, 2, 4);
          send_frame(1, 2, 5);
          send_frame(2, 2, 2);
          send_frame(3, 2, 3);
      join
      wait_for_complete_frames();

      // Phase 3: Backpressure Verification (S8)
      @(negedge clk);
      test_phase = BACKPRESSURE;
      fork
          send_frame(0, 3, 5);
          send_frame(1, 3, 3);
          send_frame(2, 3, 7);
          send_frame(3, 3, 2);
      join
      wait_for_complete_frames();

      // Phase 4: Abandoned Frame and Reset (S5a, S12)
      @(negedge clk);
      test_phase = IDLE;
      
      // Submit an incomplete frame to input 0 (2 out of 4 expected beats)
      bfm_send(0, build_data(0, 4, 0), 4'hF, 1'b0, 1'b0);
      bfm_send(0, build_data(0, 4, 1), 4'hF, 1'b0, 1'b0);
      bfm_idle(0);

      // Submit a complete frame to input 1 to ensure system routes it correctly while 0 is stalled
      send_frame(1, 4, 3);
      wait_for_complete_frames();
      
      bfm_reset(); // This tests S12 & clears queues preventing S5 failure on abandoned frame

      // Phase 5: Continuous Load Fairness (S10)
      @(negedge clk);
      test_phase = FAIRNESS;
      fork
          for(int i=0; i<30; i++) send_frame(0, 10+i, 2);
          for(int i=0; i<30; i++) send_frame(1, 10+i, 2);
          for(int i=0; i<30; i++) send_frame(2, 10+i, 2);
          for(int i=0; i<30; i++) send_frame(3, 10+i, 2);
      join
      wait_for_complete_frames();

      // Final Drain and S5 Verification
      // Ensure there are absolutely no frames containing a `tlast` that got stuck
      begin
          automatic int timeout = 0;
          while (timeout < 2000) begin
              automatic bit has_complete = 0;
              for (int i=0; i<S_COUNT; i++) begin
                  foreach (ref_queues[i][j]) begin
                      if (ref_queues[i][j].last) has_complete = 1'b1;
                  end
              end
              if (!has_complete) break;
              @(posedge clk);
              timeout++;
          end

          for (int i=0; i<S_COUNT; i++) begin
              automatic bit frame_found = 0;
              foreach (ref_queues[i][j]) begin
                  if (ref_queues[i][j].last) frame_found = 1'b1;
              end
              if (frame_found) begin
                  $display("RESULT: FAIL (S5: Frame completed on input but never fully outputted)");
                  $finish;
              end
          end
      end

      $display("RESULT: PASS");
      $finish;
  end

endmodule