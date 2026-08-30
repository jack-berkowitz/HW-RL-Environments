module tag_tracker_tb;

  localparam int TAG_W   = 3;
  localparam int SLOTS   = 8;
  localparam int N_MATCH = 1;

  localparam int TAG_COUNT = (1 << TAG_W);

  /*
   * Generous local request timeout.  The global watchdog remains the
   * unconditional termination mechanism.
   */
  localparam int REQ_BUDGET = 10000;

  typedef logic [31:0] tb_payload_t;


  // ---------------------------------------------------------------------------
  // Clock / reset
  // ---------------------------------------------------------------------------

  logic clk;

  initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
  end

  logic rst_n;

  initial rst_n = 1'b0;


  task automatic bfm_reset(input int cycles = 4);
    @(negedge clk);
    rst_n = 1'b0;

    repeat (cycles)
      @(posedge clk);

    @(negedge clk);
    rst_n = 1'b1;
  endtask


  task automatic bfm_drive_point();
    @(negedge clk);
  endtask


  task automatic bfm_tick();
    @(posedge clk);
  endtask


  // ---------------------------------------------------------------------------
  // DUT signals
  // ---------------------------------------------------------------------------

  logic [TAG_W-1:0] push_tag;
  tb_payload_t      push_data;
  logic             push_req;
  logic             push_gnt;

  /*
   * These dimensions are PACKED, exactly matching the DUT port form.
   */
  tb_payload_t [N_MATCH-1:0] match_data;
  tb_payload_t [N_MATCH-1:0] match_mask;
  logic        [N_MATCH-1:0] match_req;
  logic        [N_MATCH-1:0] match_hit;
  logic        [N_MATCH-1:0] match_gnt;

  logic [TAG_W-1:0] pop_tag;
  logic             pop_en;
  logic             pop_req;

  tb_payload_t      pop_data;
  logic             pop_data_valid;
  logic             pop_gnt;

  logic             full;
  logic             empty;


  tag_tracker #(
      .TAG_W        (TAG_W),
      .SLOTS        (SLOTS),
      .FULL_RATE    (1'b0),
      .CUT_POP_PATH (1'b0),
      .N_MATCH      (N_MATCH),
      .payload_t    (tb_payload_t)
  ) dut (
      .clk_i              (clk),
      .rst_ni             (rst_n),

      .push_tag_i         (push_tag),
      .push_data_i        (push_data),
      .push_req_i         (push_req),
      .push_gnt_o         (push_gnt),

      .match_data_i       (match_data),
      .match_mask_i       (match_mask),
      .match_req_i        (match_req),
      .match_hit_o        (match_hit),
      .match_gnt_o        (match_gnt),

      .pop_tag_i          (pop_tag),
      .pop_en_i           (pop_en),
      .pop_req_i          (pop_req),
      .pop_data_o         (pop_data),
      .pop_data_valid_o   (pop_data_valid),
      .pop_gnt_o          (pop_gnt),

      .full_o             (full),
      .empty_o            (empty)
  );


  // ---------------------------------------------------------------------------
  // Reference model
  // ---------------------------------------------------------------------------

  tb_payload_t model_mem [0:TAG_COUNT-1][0:SLOTS-1];

  integer model_head  [0:TAG_COUNT-1];
  integer model_tail  [0:TAG_COUNT-1];
  integer model_count [0:TAG_COUNT-1];

  integer model_total;

  integer fail_count;


  task automatic report_fail(
      input string req_name,
      input string detail
  );
    begin
      fail_count = fail_count + 1;
      $display("FAIL %s: %s", req_name, detail);
    end
  endtask


  task automatic model_clear;
    integer t;
    integer n;

    begin
      model_total = 0;

      for (t = 0; t < TAG_COUNT; t = t + 1) begin

        model_head[t]  = 0;
        model_tail[t]  = 0;
        model_count[t] = 0;

        for (n = 0; n < SLOTS; n = n + 1)
          model_mem[t][n] = '0;

      end
    end
  endtask


  task automatic model_push(
      input logic [TAG_W-1:0] tag_v,
      input tb_payload_t      data_v
  );
    integer t;

    begin
      t = tag_v;

      model_mem[t][model_tail[t]] =
          data_v;

      if (model_tail[t] == (SLOTS - 1))
        model_tail[t] = 0;
      else
        model_tail[t] =
            model_tail[t] + 1;

      model_count[t] =
          model_count[t] + 1;

      model_total =
          model_total + 1;
    end
  endtask


  task automatic model_remove(
      input logic [TAG_W-1:0] tag_v
  );
    integer t;

    begin
      t = tag_v;

      if (model_count[t] > 0) begin

        if (model_head[t] == (SLOTS - 1))
          model_head[t] = 0;
        else
          model_head[t] =
              model_head[t] + 1;

        model_count[t] =
            model_count[t] - 1;

        model_total =
            model_total - 1;

      end
    end
  endtask


  function automatic tb_payload_t model_oldest(
      input logic [TAG_W-1:0] tag_v
  );
    integer t;

    begin
      t = tag_v;

      if (model_count[t] > 0)
        model_oldest =
            model_mem[t][model_head[t]];
      else
        model_oldest =
            '0;
    end
  endfunction


  function automatic logic model_search(
      input tb_payload_t data_v,
      input tb_payload_t mask_v
  );
    integer t;
    integer n;
    integer idx;
    logic hit_v;

    begin
      hit_v = 1'b0;

      for (t = 0; t < TAG_COUNT; t = t + 1) begin

        for (n = 0; n < SLOTS; n = n + 1) begin

          if (n < model_count[t]) begin

            idx =
                model_head[t] + n;

            if (idx >= SLOTS)
              idx = idx - SLOTS;

            if (
                (model_mem[t][idx] & mask_v) ==
                (data_v           & mask_v)
            )
              hit_v = 1'b1;

          end

        end

      end

      model_search = hit_v;
    end
  endfunction


  // ---------------------------------------------------------------------------
  // Status checks
  // ---------------------------------------------------------------------------

  task automatic check_status;
    logic exp_empty;
    logic exp_full;

    begin
      exp_empty =
          (model_total == 0);

      exp_full =
          (model_total == SLOTS);

      if (empty !== exp_empty)
        report_fail(
            "R14",
            "empty_o does not exactly reflect whether zero entries are stored"
        );

      if (full !== exp_full)
        report_fail(
            "R14",
            "full_o does not exactly reflect whether SLOTS entries are stored"
        );
    end
  endtask


  task automatic check_reset_status;
    begin
      if (empty !== 1'b1)
        report_fail(
            "R15",
            "empty_o was not high after reset emptied the store"
        );

      if (full !== 1'b0)
        report_fail(
            "R15",
            "full_o was not low after reset emptied the store"
        );
    end
  endtask


  // ---------------------------------------------------------------------------
  // Push BFM
  // ---------------------------------------------------------------------------

  task automatic do_push(
      input logic [TAG_W-1:0] tag_v,
      input tb_payload_t      data_v
  );
    integer n;
    bit granted;

    begin
      granted = 1'b0;

      bfm_drive_point();

      push_tag  = tag_v;
      push_data = data_v;
      push_req  = 1'b1;

      for (n = 0; n < REQ_BUDGET; n = n + 1) begin

        bfm_tick();

        if (push_gnt) begin
          granted = 1'b1;
          break;
        end

      end

      if (!granted) begin

        report_fail(
            "R1",
            "push was never granted even though the capacity test required another entry to be accepted"
        );

      end
      else begin

        /*
         * R4: the model changes only on push_req && push_gnt.
         */
        model_push(
            tag_v,
            data_v
        );

      end

      bfm_drive_point();
      push_req = 1'b0;

      check_status();
    end
  endtask


  /*
   * R5 probe: while full, a push grant must remain low.
   */
  task automatic probe_push_while_full;
    integer n;
    bit bad_grant;

    begin
      bad_grant = 1'b0;

      bfm_drive_point();

      push_tag  = 3'd7;
      push_data = 32'hDEAD_0008;
      push_req  = 1'b1;

      for (n = 0; n < 8; n = n + 1) begin

        bfm_tick();

        if (push_gnt)
          bad_grant = 1'b1;

      end

      bfm_drive_point();
      push_req = 1'b0;

      if (bad_grant)
        report_fail(
            "R5",
            "push_gnt_o asserted while the store already held SLOTS entries"
        );
    end
  endtask


  // ---------------------------------------------------------------------------
  // Pop / peek BFM
  // ---------------------------------------------------------------------------

  task automatic do_pop(
      input logic [TAG_W-1:0] tag_v,
      input logic             remove_v
  );
    integer n;
    bit granted;

    logic expected_valid;
    tb_payload_t expected_data;

    begin
      granted = 1'b0;

      expected_valid =
          (model_count[tag_v] != 0);

      expected_data =
          model_oldest(tag_v);

      bfm_drive_point();

      pop_tag = tag_v;
      pop_en  = remove_v;
      pop_req = 1'b1;

      for (n = 0; n < REQ_BUDGET; n = n + 1) begin

        bfm_tick();

        if (pop_gnt) begin

          granted = 1'b1;

          /*
           * R8 / R10.
           */
          if (pop_data_valid !== expected_valid)
            report_fail(
                "R8",
                "pop_data_valid_o did not reflect whether the requested tag had an entry"
            );

          if (
              expected_valid &&
              (pop_data !== expected_data)
          )
            report_fail(
                "R8",
                "pop_data_o was not the oldest stored payload for the requested tag"
            );

          break;
        end

      end

      if (!granted)
        report_fail(
            "R7",
            "pop request did not complete within the generous request budget"
        );
      else if (
          remove_v &&
          expected_valid
      ) begin

        /*
         * R9: only a completing pop with pop_en_i removes the entry.
         */
        model_remove(tag_v);

      end

      bfm_drive_point();
      pop_req = 1'b0;
      pop_en  = 1'b0;

      check_status();
    end
  endtask


  // ---------------------------------------------------------------------------
  // Search BFM
  // ---------------------------------------------------------------------------

  task automatic do_search(
      input tb_payload_t data_v,
      input tb_payload_t mask_v
  );
    integer n;
    bit granted;
    logic expected_hit;

    begin
      granted =
          1'b0;

      expected_hit =
          model_search(
              data_v,
              mask_v
          );

      bfm_drive_point();

      match_data[0] =
          data_v;

      match_mask[0] =
          mask_v;

      match_req[0] =
          1'b1;

      for (n = 0; n < REQ_BUDGET; n = n + 1) begin

        bfm_tick();

        if (match_gnt[0]) begin

          granted =
              1'b1;

          if (
              match_hit[0] !==
              expected_hit
          )
            report_fail(
                "R12",
                "search hit did not match the masked comparison over all stored payloads"
            );

          break;
        end

      end

      if (!granted)
        report_fail(
            "R11",
            "search request did not complete within the generous request budget"
        );

      bfm_drive_point();

      match_req[0] =
          1'b0;

      check_status();
    end
  endtask


  // ---------------------------------------------------------------------------
  // Common reset
  // ---------------------------------------------------------------------------

  task automatic clean_reset;
    begin
      /*
       * Stop all requests before reset.
       */
      bfm_drive_point();

      push_req     = 1'b0;
      pop_req      = 1'b0;
      pop_en       = 1'b0;
      match_req    = '0;

      model_clear();

      bfm_reset(4);

      /*
       * Wait through a sampled post-reset cycle before inspecting status.
       */
      bfm_tick();
      bfm_drive_point();

      check_reset_status();
      check_status();
    end
  endtask


  // ---------------------------------------------------------------------------
  // Reset while live entries exist
  // ---------------------------------------------------------------------------

  task automatic test_live_reset;
    integer n;

    begin
      do_push(
          3'd1,
          32'hAB01_0001
      );

      do_push(
          3'd2,
          32'hAB02_0002
      );

      do_push(
          3'd1,
          32'hAB01_0003
      );

      if (model_total != 3)
        report_fail(
            "R1",
            "testbench model expected three live entries before reset"
        );


      /*
       * Assert reset away from the sampling edge.
       */
      bfm_drive_point();

      push_req  = 1'b0;
      pop_req   = 1'b0;
      match_req = '0;

      rst_n =
          1'b0;

      /*
       * Give the active-low reset sampled clock edges.
       */
      for (n = 0; n < 3; n = n + 1)
        bfm_tick();

      model_clear();

      bfm_drive_point();

      /*
       * Still in reset here.
       */
      check_reset_status();


      /*
       * Release reset, again away from the sampling edge.
       */
      rst_n =
          1'b1;

      bfm_tick();
      bfm_drive_point();

      check_reset_status();
      check_status();


      /*
       * Old contents must really be gone, not merely hidden by status bits.
       */
      do_pop(
          3'd1,
          1'b1
      );

      do_pop(
          3'd2,
          1'b1
      );

    end
  endtask


  // ---------------------------------------------------------------------------
  // Main test
  // ---------------------------------------------------------------------------

  initial begin : main_test
    integer i;

    fail_count =
        0;

    push_tag =
        '0;

    push_data =
        '0;

    push_req =
        1'b0;

    match_data =
        '0;

    match_mask =
        '0;

    match_req =
        '0;

    pop_tag =
        '0;

    pop_en =
        1'b0;

    pop_req =
        1'b0;

    model_clear();


    // ========================================================================
    // R15 / initial empty state
    // ========================================================================

    clean_reset();


    // ========================================================================
    // R8 / R10: pop of an absent tag must complete with VALID low.
    // ========================================================================

    do_pop(
        3'd5,
        1'b1
    );


    // ========================================================================
    // R12: empty-store searches.
    // ========================================================================

    do_search(
        32'h1234_5678,
        32'hFFFF_FFFF
    );

    /*
     * Zero mask on an EMPTY store must still miss according to R12:
     * there is no stored entry satisfying the predicate.
     */
    do_search(
        32'hFFFF_FFFF,
        32'h0000_0000
    );


    // ========================================================================
    // R2 / R8 / R9: FIFO and peek semantics on one tag.
    // ========================================================================

    do_push(
        3'd3,
        32'h3300_0001
    );

    do_push(
        3'd3,
        32'h3300_0002
    );

    do_push(
        3'd3,
        32'h3300_0003
    );

    do_push(
        3'd3,
        32'h3300_0004
    );


    /*
     * Peek: must report entry 1, but must not remove it.
     */
    do_pop(
        3'd3,
        1'b0
    );


    /*
     * Actual removal must still return entry 1.
     */
    do_pop(
        3'd3,
        1'b1
    );

    do_pop(
        3'd3,
        1'b1
    );

    do_pop(
        3'd3,
        1'b1
    );

    do_pop(
        3'd3,
        1'b1
    );


    /*
     * Tag now absent.
     */
    do_pop(
        3'd3,
        1'b1
    );


    // ========================================================================
    // R2/R3: interleaved insertion, but FIFO is independently maintained
    // for each tag.
    // ========================================================================

    do_push(
        3'd1,
        32'h1100_0001
    );

    do_push(
        3'd2,
        32'h2200_0001
    );

    do_push(
        3'd1,
        32'h1100_0002
    );

    do_push(
        3'd2,
        32'h2200_0002
    );


    /*
     * Pop tag 1 twice even though tag 2 was interposed in insertion order.
     * This checks per-tag FIFO without imposing cross-tag ordering.
     */
    do_pop(
        3'd1,
        1'b1
    );

    do_pop(
        3'd1,
        1'b1
    );

    do_pop(
        3'd2,
        1'b1
    );

    do_pop(
        3'd2,
        1'b1
    );


    // ========================================================================
    // R12/R13: content-addressed search over all tags.
    // ========================================================================

    do_push(
        3'd0,
        32'h1234_5678
    );

    do_push(
        3'd4,
        32'hABCD_00EF
    );

    do_push(
        3'd7,
        32'hFFFF_0000
    );


    /*
     * Exact hit.
     */
    do_search(
        32'hABCD_00EF,
        32'hFFFF_FFFF
    );


    /*
     * Exact miss.
     */
    do_search(
        32'hABCD_00EE,
        32'hFFFF_FFFF
    );


    /*
     * Masked hit across all tags.
     */
    do_search(
        32'h0000_00EF,
        32'h0000_00FF
    );


    /*
     * Masked miss.
     */
    do_search(
        32'h0000_00AA,
        32'h0000_00FF
    );


    /*
     * R13: zero mask must hit whenever non-empty.
     */
    do_search(
        32'hDEAD_BEEF,
        32'h0000_0000
    );


    clean_reset();


    // ========================================================================
    // R1: all SLOTS entries may use THE SAME TAG.
    // ========================================================================

    for (i = 0; i < SLOTS; i = i + 1) begin

      do_push(
          3'd6,
          32'h6000_0000 + i
      );

    end


    if (model_total != SLOTS)
      report_fail(
          "R1",
          "model did not reach SLOTS entries in the same-tag capacity phase"
      );


    /*
     * Search must still work while full.
     */
    do_search(
        32'h6000_0003,
        32'hFFFF_FFFF
    );


    /*
     * R5: no ninth push.
     */
    probe_push_while_full();


    clean_reset();


    // ========================================================================
    // R1: storage is shared across tags.  Fill with one entry on each tag.
    // ========================================================================

    for (i = 0; i < SLOTS; i = i + 1) begin

      do_push(
          i[TAG_W-1:0],
          32'h7000_0000 + i
      );

    end


    if (model_total != SLOTS)
      report_fail(
          "R1",
          "store failed to accept SLOTS entries distributed across tags"
      );


    /*
     * R13 again at full occupancy.
     */
    do_search(
        32'hCAFE_BABE,
        32'h0000_0000
    );


    probe_push_while_full();


    clean_reset();


    // ========================================================================
    // R15: reset destroys live contents.
    // ========================================================================

    test_live_reset();


    // ========================================================================
    // Final sanity: capacity remains usable after reset.
    // ========================================================================

    for (i = 0; i < SLOTS; i = i + 1) begin

      do_push(
          3'd0,
          32'h8000_0000 + i
      );

    end

    for (i = 0; i < SLOTS; i = i + 1) begin

      do_pop(
          3'd0,
          1'b1
      );

    end


    check_status();


    /*
     * Exactly one final RESULT line.
     */
    if (fail_count == 0)
      $display("RESULT: PASS");
    else
      $display("RESULT: FAIL");

    $finish;
  end


  // ---------------------------------------------------------------------------
  // Unconditional watchdog
  // ---------------------------------------------------------------------------

  initial begin
    #20_000_000;

    $display(
        "FAIL R1: watchdog expired before the testbench reached a verdict"
    );

    $display("RESULT: FAIL");

    $finish;
  end

endmodule