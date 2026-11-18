module fp_noncomp_tb;

    // ---- clock and reset ----
    logic clk;
    initial begin clk = 1'b0; forever #5 clk = ~clk; end

    logic rst_n;
    initial rst_n = 1'b0;

    // ---- DUT connections ----
    logic [31:0] operand_a_i, operand_b_i;
    logic [1:0]  op_i;
    logic [2:0]  op_mode_i;
    logic        in_valid_i;
    logic        in_ready_o;
    logic [31:0] result_o;
    logic [9:0]  class_mask_o;
    logic [4:0]  status_o;
    logic        out_valid_o;
    logic        out_ready_i;

    fp_noncomp dut (
        .clk_i       (clk),
        .rst_ni      (rst_n),
        .operand_a_i (operand_a_i),
        .operand_b_i (operand_b_i),
        .op_i        (op_i),
        .op_mode_i   (op_mode_i),
        .in_valid_i  (in_valid_i),
        .in_ready_o  (in_ready_o),
        .result_o    (result_o),
        .class_mask_o(class_mask_o),
        .status_o    (status_o),
        .out_valid_o (out_valid_o),
        .out_ready_i (out_ready_i)
    );

    // ---- provided plumbing ----
    task automatic bfm_reset(input int cycles = 4);
        @(negedge clk);
        rst_n = 1'b0;
        repeat (cycles) @(posedge clk);
        @(negedge clk);
        rst_n = 1'b1;
    endtask

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

    task automatic bfm_idle();
        @(negedge clk);
        in_valid_i = 1'b0;
    endtask

    task automatic bfm_out_ready(input logic value);
        @(negedge clk);
        out_ready_i = value;
    endtask

    initial begin
        #200_000_000;
        $display("RESULT: FAIL (watchdog: no forward progress)");
        $finish;
    end

    // ---- testbench state ----
    typedef struct {
        logic [31:0] a;
        logic [31:0] b;
        logic [1:0]  op;
        logic [2:0]  mode;
    } op_t;

    typedef struct {
        logic [31:0] result;
        logic [9:0]  class_mask;
        logic [4:0]  status;
        logic        check_result;
        logic        check_class;
        logic        check_status;
    } expected_t;

    op_t       pending_q[$];
    int        error_count;
    int        issue_count;
    int        check_count;
    int        stall_cycles;

    logic        cap_valid, cap_ready;
    logic [31:0] cap_result;
    logic [9:0]  cap_class;
    logic [4:0]  cap_status;

    always @(posedge clk) begin
        cap_valid  <= out_valid_o;
        cap_ready  <= out_ready_i;
        cap_result <= result_o;
        cap_class  <= class_mask_o;
        cap_status <= status_o;
        if (rst_n && out_valid_o && !out_ready_i)
            stall_cycles <= stall_cycles + 1;
    end

    // ---- helpers ----
    function automatic logic is_nan_f(input logic [31:0] v);
        is_nan_f = (v[30:23] == 8'hFF) && (v[22:0] != 23'd0);
    endfunction

    function automatic logic is_snan_f(input logic [31:0] v);
        is_snan_f = (v[30:23] == 8'hFF) && (v[22:0] != 23'd0) && !v[22];
    endfunction

    function automatic logic [31:0] order_key_f(input logic [31:0] v);
        order_key_f = v[31] ? ~v : (v | 32'h8000_0000);
    endfunction

    function automatic logic [31:0] norm_zero_f(input logic [31:0] v);
        norm_zero_f = (v == 32'h8000_0000) ? 32'h0000_0000 : v;
    endfunction

    function automatic logic [9:0] classify_f(input logic [31:0] v);
        logic        s;
        logic [7:0]  ef;
        logic [22:0] fr;
        s  = v[31];
        ef = v[30:23];
        fr = v[22:0];
        if (ef == 8'hFF) begin
            if (fr == 23'd0)      classify_f = s ? 10'h001 : 10'h080;
            else if (fr[22])      classify_f = 10'h200;
            else                  classify_f = 10'h100;
        end else if (ef == 8'h00) begin
            if (fr == 23'd0)      classify_f = s ? 10'h008 : 10'h010;
            else                  classify_f = s ? 10'h004 : 10'h020;
        end else begin
            classify_f = s ? 10'h002 : 10'h040;
        end
    endfunction

    function automatic expected_t compute_expected(
        input logic [31:0] a,
        input logic [31:0] b,
        input logic [1:0]  op,
        input logic [2:0]  mode
    );
        expected_t   e;
        logic        a_nan, b_nan, a_snan, b_snan;
        logic [31:0] a_n, b_n, ka, kb;

        a_nan  = is_nan_f(a);
        b_nan  = is_nan_f(b);
        a_snan = is_snan_f(a);
        b_snan = is_snan_f(b);
        a_n    = norm_zero_f(a);
        b_n    = norm_zero_f(b);
        ka     = order_key_f(a);
        kb     = order_key_f(b);

        e.check_result = 1'b0;
        e.check_class  = 1'b0;
        e.check_status = 1'b0;
        e.result       = 32'hxxxx_xxxx;
        e.class_mask   = 10'hxxx;
        e.status       = 5'd0;

        case (op)
            2'd0: begin // SGNJ
                e.check_status = 1'b1;
                e.status       = 5'd0;
                if (mode == 3'd0) begin
                    e.check_result = 1'b1;
                    e.result = {b[31], a[30:0]};
                end else if (mode == 3'd1) begin
                    e.check_result = 1'b1;
                    e.result = {~b[31], a[30:0]};
                end else if (mode == 3'd2) begin
                    e.check_result = 1'b1;
                    e.result = {a[31] ^ b[31], a[30:0]};
                end
            end
            2'd1: begin // MINMAX
                e.check_result = 1'b1;
                e.check_status = 1'b1;
                if (a_nan && b_nan)      e.result = 32'h7FC0_0000;
                else if (a_nan)          e.result = b;
                else if (b_nan)          e.result = a;
                else if (mode == 3'd0)   e.result = (ka <= kb) ? a : b;
                else if (mode == 3'd1)   e.result = (ka >= kb) ? a : b;
                else                     e.check_result = 1'b0;
                e.status = (a_snan || b_snan) ? 5'b10000 : 5'd0;
            end
            2'd2: begin // CMP
                e.check_result = 1'b1;
                e.check_status = 1'b1;
                if (mode == 3'd2) begin
                    // EQ: quiet comparison
                    e.result = (a_nan || b_nan) ? 32'd0 :
                               ((a_n == b_n) ? 32'd1 : 32'd0);
                    e.status = (a_snan || b_snan) ? 5'b10000 : 5'd0;
                end else if (mode == 3'd0) begin
                    // LE: signalling comparison
                    e.result = (a_nan || b_nan) ? 32'd0 :
                               ((order_key_f(a_n) <= order_key_f(b_n)) ? 32'd1 : 32'd0);
                    e.status = (a_nan || b_nan) ? 5'b10000 : 5'd0;
                end else if (mode == 3'd1) begin
                    // LT: signalling comparison
                    e.result = (a_nan || b_nan) ? 32'd0 :
                               ((order_key_f(a_n) < order_key_f(b_n)) ? 32'd1 : 32'd0);
                    e.status = (a_nan || b_nan) ? 5'b10000 : 5'd0;
                end else begin
                    e.check_result = 1'b0;
                    e.check_status = 1'b0;
                end
            end
            2'd3: begin // CLASSIFY
                e.check_class  = 1'b1;
                e.check_status = 1'b1;
                e.class_mask   = classify_f(a);
                e.status       = 5'd0;
            end
            default: begin end
        endcase

        compute_expected = e;
    endfunction

    // ---- checker ----
    always @(negedge clk) begin
        automatic op_t       o;
        automatic expected_t e;

        if (rst_n && cap_valid && cap_ready) begin
            if (pending_q.size() == 0) begin
                $display("FAIL H2: unexpected output, empty queue (r=0x%08h cls=0x%03h st=0x%02h)",
                          cap_result, cap_class, cap_status);
                error_count = error_count + 1;
            end else begin
                o = pending_q[0];
                pending_q.pop_front();
                e = compute_expected(o.a, o.b, o.op, o.mode);
                check_count = check_count + 1;
                if (e.check_result && e.result !== cap_result) begin
                    $display("FAIL S1/S4/S5/S7/S9/S10: result got 0x%08h exp 0x%08h",
                              cap_result, e.result);
                    error_count = error_count + 1;
                end
                if (e.check_class && e.class_mask !== cap_class) begin
                    $display("FAIL S12: class_mask got 0x%03h exp 0x%03h",
                              cap_class, e.class_mask);
                    error_count = error_count + 1;
                end
                if (e.check_status && e.status !== cap_status) begin
                    $display("FAIL S2/S6/S8/S11/S13/S14: status got 0x%02h exp 0x%02h",
                              cap_status, e.status);
                    error_count = error_count + 1;
                end
            end
        end
        if (!rst_n) pending_q.delete();
    end

    task automatic issue_and_record(input logic [31:0] a, input logic [31:0] b,
                                     input logic [1:0]  op, input logic [2:0]  mode);
        op_t o;
        bfm_issue(a, b, op, mode);
        o.a = a; o.b = b; o.op = op; o.mode = mode;
        pending_q.push_back(o);
        issue_count = issue_count + 1;
    endtask

    // ---- main test flow ----
    initial begin
        int          i, j, m;
        logic [31:0] vals [21];

        error_count  = 0;
        issue_count  = 0;
        check_count  = 0;
        stall_cycles = 0;

        in_valid_i  = 1'b0;
        out_ready_i = 1'b0;
        operand_a_i = 32'd0;
        operand_b_i = 32'd0;
        op_i        = 2'd0;
        op_mode_i   = 3'd0;

        vals[0]  = 32'h0000_0000; // +0
        vals[1]  = 32'h8000_0000; // -0
        vals[2]  = 32'h3F80_0000; // +1
        vals[3]  = 32'hBF80_0000; // -1
        vals[4]  = 32'h4000_0000; // +2
        vals[5]  = 32'hC000_0000; // -2
        vals[6]  = 32'h3F00_0000; // +0.5
        vals[7]  = 32'hBF00_0000; // -0.5
        vals[8]  = 32'h7F80_0000; // +inf
        vals[9]  = 32'hFF80_0000; // -inf
        vals[10] = 32'h0000_0001; // +min subnormal
        vals[11] = 32'h8000_0001; // -min subnormal
        vals[12] = 32'h7F7F_FFFF; // +max normal
        vals[13] = 32'hFF7F_FFFF; // -max normal
        vals[14] = 32'h7FC0_0000; // +canonical quiet NaN
        vals[15] = 32'hFFC0_0000; // -quiet NaN
        vals[16] = 32'h7F80_0001; // +signalling NaN
        vals[17] = 32'hFF80_0001; // -signalling NaN
        vals[18] = 32'h7FC0_1234; // +quiet NaN payload
        vals[19] = 32'h7F80_5678; // +signalling NaN payload
        vals[20] = 32'h3FC0_0000; // +1.5

        bfm_reset(4);
        bfm_out_ready(1);

        // =====================================================
        // S15: reset discards pre-reset operations
        // =====================================================
        bfm_out_ready(0);
        issue_and_record(32'h3F80_0000, 32'h4000_0000, 2'd0, 3'd0);
        bfm_idle();
        @(negedge clk);
        rst_n = 1'b0;
        repeat (4) @(posedge clk);
        @(negedge clk);
        if (out_valid_o) begin
            $display("FAIL S15: out_valid_o high during reset");
            error_count = error_count + 1;
        end
        rst_n = 1'b1;
        @(posedge clk);
        @(negedge clk);
        if (out_valid_o) begin
            $display("FAIL S15: out_valid_o high on first cycle after reset");
            error_count = error_count + 1;
        end
        bfm_out_ready(1);
        for (m = 0; m < 100; m = m + 1) begin
            @(negedge clk);
            if (out_valid_o) begin
                $display("FAIL S15: stale result after reset");
                error_count = error_count + 1;
            end
        end

        // =====================================================
        // S1/S2: SGNJ — all modes, all value pairs
        // =====================================================
        for (i = 0; i < 21; i = i + 1) begin
            for (j = 0; j < 21; j = j + 1) begin
                for (m = 0; m < 3; m = m + 1) begin
                    issue_and_record(vals[i], vals[j], 2'd0, m[2:0]);
                end
            end
        end
        bfm_idle();

        // =====================================================
        // S3/S4/S5/S6: MINMAX — all value pairs
        // =====================================================
        for (i = 0; i < 21; i = i + 1) begin
            for (j = 0; j < 21; j = j + 1) begin
                for (m = 0; m < 2; m = m + 1) begin
                    issue_and_record(vals[i], vals[j], 2'd1, m[2:0]);
                end
            end
        end
        bfm_idle();

        // =====================================================
        // S7/S8/S9/S10/S11: CMP — all value pairs, all modes
        // =====================================================
        for (i = 0; i < 21; i = i + 1) begin
            for (j = 0; j < 21; j = j + 1) begin
                for (m = 0; m < 3; m = m + 1) begin
                    issue_and_record(vals[i], vals[j], 2'd2, m[2:0]);
                end
            end
        end
        bfm_idle();

        // =====================================================
        // S12/S13: CLASSIFY — all values (b ignored)
        // =====================================================
        for (i = 0; i < 21; i = i + 1) begin
            issue_and_record(vals[i], 32'hDEAD_BEEF, 2'd3, 3'd0);
        end
        bfm_idle();

        // =====================================================
        // H3: backpressure — hold out_ready low for many cycles
        // =====================================================
        bfm_out_ready(0);
        for (m = 0; m < 5; m = m + 1) begin
            issue_and_record(32'h3F80_0000, 32'h4000_0000, 2'd0, (m % 3));
        end
        bfm_idle();
        repeat (40) @(posedge clk);
        bfm_out_ready(1);

        if (stall_cycles < 20) begin
            $display("FAIL H3: only %0d stall cycles, need >=20", stall_cycles);
            error_count = error_count + 1;
        end

        // =====================================================
        // Drain remaining results
        // =====================================================
        bfm_idle();
        bfm_out_ready(1);
        for (m = 0; m < 500; m = m + 1) begin
            @(posedge clk);
            if (pending_q.size() == 0) break;
        end
        if (pending_q.size() > 0) begin
            $display("FAIL H2: pending queue not drained (%0d remain)", pending_q.size());
            error_count = error_count + 1;
        end
        for (m = 0; m < 30; m = m + 1) begin
            @(negedge clk);
            if (out_valid_o) begin
                $display("FAIL H2: spurious out_valid after drain");
                error_count = error_count + 1;
            end
        end

        if (error_count == 0) begin
            $display("RESULT: PASS");
        end else begin
            $display("RESULT: FAIL (%0d errors, %0d checks, %0d issues)",
                      error_count, check_count, issue_count);
        end
        $finish;
    end

endmodule
