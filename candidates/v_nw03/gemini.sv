module frame_arb_mux_tb;

  parameter int S_COUNT    = 4;
  parameter int DATA_WIDTH = 32;
  parameter int USER_WIDTH = 1;

  // ---- clock -----------------------------------------------------------------
  logic clk;
  initial begin clk = 1'b0; forever #5 clk = ~clk; end

  // ---- reset -----------------------------------------------------------------
  logic rst;
  initial rst = 1'b1;

  task automatic bfm_reset(input int cycles = 4);
    @(negedge clk);
    rst = 1'b1;
    repeat (cycles) @(posedge clk);
    @(negedge clk);
    rst = 1'b0;
    check_s12 = 1'b1;
  endtask

  // ---- input side ------------------------------------------------------------
  logic [S_COUNT-1:0][DATA_WIDTH-1:0]       s_tdata;
  logic [S_COUNT-1:0][(DATA_WIDTH/8)-1:0]   s_tkeep;
  logic [S_COUNT-1:0]                       s_tvalid;
  logic [S_COUNT-1:0]                       s_tready;
  logic [S_COUNT-1:0]                       s_tlast;
  logic [S_COUNT-1:0][USER_WIDTH-1:0]       s_tuser;

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

  task automatic bfm_idle(input int k);
    @(negedge clk);
    s_tvalid[k] = 1'b0;
  endtask

  // ---- output side -----------------------------------------------------------
  logic [DATA_WIDTH-1:0]                    m_tdata;
  logic [(DATA_WIDTH/8)-1:0]                m_tkeep;
  logic                                     m_tvalid;
  logic                                     m_tready;
  logic                                     m_tlast;
  logic [USER_WIDTH-1:0]                    m_tuser;

  task automatic bfm_ready(input logic value);
    @(negedge clk);
    m_tready = value;
  endtask

  // ---- watchdog (S13) --------------------------------------------------------
  initial begin
    #20_000_000;
    $display("RESULT: FAIL (watchdog: no forward progress)");
    $finish;
  end

  // ---- DUT Instantiation -----------------------------------------------------
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

  // ---- Testbench State & Scoreboard ------------------------------------------
  typedef struct packed {
      logic [31:0] data;
      logic [3:0]  keep;
      logic        user;
      logic        last;
  } beat_t;

  beat_t in_progress_frame[S_COUNT][$];
  beat_t completed_in_frames[S_COUNT][$][$];

  int current_k = -1;
  beat_t expected_out_frame[$];
  
  logic check_s12 = 0;
  logic continuous_load_active = 0;
  int completed_output_frames = 0;
  int last_start_completed_count[S_COUNT];
  int frame_seq[S_COUNT];

  task automatic fail(string msg);
      $display("%s", msg);
      $display("RESULT: FAIL");
      $finish;
  endtask

  // ---- Input Monitor ---------------------------------------------------------
  always @(posedge clk) begin
      if (rst) begin
          for (int i = 0; i < S_COUNT; i++) begin
              in_progress_frame[i].delete();
              completed_in_frames[i].delete();
          end
      end else begin
          for (int i = 0; i < S_COUNT; i++) begin
              if (s_tvalid[i] && s_tready[i]) begin
                  automatic beat_t b;
                  b.data = s_tdata[i];
                  b.keep = s_tkeep[i];
                  b.user = s_tuser[i];
                  b.last = s_tlast[i];
                  in_progress_frame[i].push_back(b);
                  if (b.last) begin
                      completed_in_frames[i].push_back(in_progress_frame[i]);
                      in_progress_frame[i].delete();
                  end
              end
          end
      end
  end

  // ---- Output Monitor --------------------------------------------------------
  always @(posedge clk) begin
      if (rst) begin
          current_k = -1;
          expected_out_frame.delete();
          completed_output_frames = 0;
          for (int i = 0; i < S_COUNT; i++) last_start_completed_count[i] = 0;
      end else begin
          if (check_s12) begin
              if (m_tvalid) fail("S12: m_tvalid_o high on first cycle after reset");
              check_s12 = 1'b0;
          end
          
          if (m_tvalid && m_tready) begin
              if (current_k == -1) begin
                  automatic int k_est = int'(m_tdata[31:24]);
                  if (k_est < 0 || k_est >= S_COUNT) fail("S4: corrupted data, k out of range");
                  if (completed_in_frames[k_est].size() == 0) fail("S5: unexpected or ghost frame started");
                  
                  expected_out_frame = completed_in_frames[k_est].pop_front();
                  current_k = k_est;
                  last_start_completed_count[k_est] = completed_output_frames;
              end
              
              if (expected_out_frame.size() == 0) fail("S4: output frame longer than input frame");
              
              begin
                  automatic beat_t exp_beat = expected_out_frame.pop_front();
                  if (m_tdata !== exp_beat.data || m_tkeep !== exp_beat.keep || m_tuser !== exp_beat.user || m_tlast !== exp_beat.last) begin
                      fail("S4: payload mismatch");
                  end
              end
              
              if (m_tlast) begin
                  if (expected_out_frame.size() > 0) fail("S4: early tlast");
                  current_k = -1;
                  
                  if (continuous_load_active) begin
                      completed_output_frames++;
                      for (int i = 0; i < S_COUNT; i++) begin
                          if (completed_output_frames - last_start_completed_count[i] >= 16) fail("S10: bounded fairness violated");
                      end
                  end
              end
          end
      end
  end

  // ---- Stimulus Tasks --------------------------------------------------------
  task automatic send_frame(input int k, input int length);
      for (int i = 0; i < length; i++) begin
          automatic logic [7:0] k_logic = k;
          automatic logic [11:0] f_logic = frame_seq[k][11:0];
          automatic logic [11:0] b_logic = i[11:0];
          automatic logic [31:0] data = {k_logic, f_logic, b_logic};
          automatic logic [3:0] keep = $urandom;
          automatic logic user = $urandom;
          automatic logic last = (i == length - 1);
          bfm_send(k, data, keep, last, user);
      end
      frame_seq[k]++;
  endtask

  task automatic parallel_random_frames();
      fork
          begin repeat(10) begin send_frame(0, $urandom_range(1,5)); bfm_idle(0); repeat($urandom_range(0,5)) @(posedge clk); end end
          begin repeat(10) begin send_frame(1, $urandom_range(1,5)); bfm_idle(1); repeat($urandom_range(0,5)) @(posedge clk); end end
          begin repeat(10) begin send_frame(2, $urandom_range(1,5)); bfm_idle(2); repeat($urandom_range(0,5)) @(posedge clk); end end
          begin repeat(10) begin send_frame(3, $urandom_range(1,5)); bfm_idle(3); repeat($urandom_range(0,5)) @(posedge clk); end end
      join
  endtask

  task automatic backpressure_test();
      fork
          parallel_random_frames();
          begin
              repeat(50) begin
                  bfm_ready($urandom_range(0, 1));
                  repeat($urandom_range(1, 5)) @(posedge clk);
              end
              bfm_ready(1);
          end
      join
  endtask

  task automatic continuous_load_test();
      bfm_ready(1); // m_tready_i held high throughout
      
      completed_output_frames = 0;
      for (int i = 0; i < S_COUNT; i++) last_start_completed_count[i] = 0;
      continuous_load_active = 1;

      fork
          begin repeat(30) send_frame(0, $urandom_range(1, 4)); bfm_idle(0); end
          begin repeat(30) send_frame(1, $urandom_range(1, 4)); bfm_idle(1); end
          begin repeat(30) send_frame(2, $urandom_range(1, 4)); bfm_idle(2); end
          begin repeat(30) send_frame(3, $urandom_range(1, 4)); bfm_idle(3); end
      join
      
      continuous_load_active = 0;
  endtask

  task automatic wait_drain();
      automatic int timeout = 10000;
      while (timeout > 0) begin
          automatic bit all_empty = 1;
          for (int i = 0; i < S_COUNT; i++) begin
              if (completed_in_frames[i].size() > 0) all_empty = 0;
          end
          if (current_k != -1) all_empty = 0;
          
          if (all_empty) break;
          @(posedge clk);
          timeout--;
      end
      if (timeout == 0) fail("S5: Timeout waiting for frames to drain");
  endtask

  // ---- Main Execution Sequence -----------------------------------------------
  initial begin
      for (int i = 0; i < S_COUNT; i++) begin
          s_tvalid[i] = 0;
          s_tdata[i] = 0;
          s_tkeep[i] = 0;
          s_tlast[i] = 0;
          s_tuser[i] = 0;
          frame_seq[i] = 0;
      end
      m_tready = 1;
      
      // Phase 1: Reset test with interrupted frame
      fork
          begin : reset_stim
              send_frame(0, 5); 
          end
          begin
              repeat(3) @(posedge clk);
          end
      join_any
      disable fork;
      
      for (int i = 0; i < S_COUNT; i++) bfm_idle(i);
      bfm_reset();
      
      // Allow check_s12 to clear exactly at the first posedge after reset
      @(posedge clk); 
      
      // Phase 2: Arbitrated frames with random backpressure and gaps
      backpressure_test();
      
      // Phase 3: Continuous offered load to test Bounded Fairness (S10)
      continuous_load_test();
      
      // Wait for completion
      wait_drain();
      
      // Final scoreboard integrity check
      for (int i = 0; i < S_COUNT; i++) begin
          if (completed_in_frames[i].size() > 0) fail("S5: Frame loss detected");
      end
      
      $display("RESULT: PASS");
      $finish;
  end

endmodule