module fp_noncomp_tb;

    // ---------------------------------------------------------------------------
    // Interface signals
    // ---------------------------------------------------------------------------
    logic [31:0] operand_a_i;
    logic [31:0] operand_b_i;
    logic [1:0]  op_i;
    logic [2:0]  op_mode_i;
    logic        in_valid_i;
    logic        in_ready_o;
    logic [31:0] result_o;
    logic [9:0]  class_mask_o;
    logic [4:0]  status_o;
    logic        out_valid_o;
    logic        out_ready_i;

    // ---------------------------------------------------------------------------
    // DUT Instantiation
    // ---------------------------------------------------------------------------
    fp_noncomp dut (
        .clk_i(clk),
        .rst_ni(rst_n),
        .operand_a_i(operand_a_i),
        .operand_b_i(operand_b_i),
        .op_i(op_i),
        .op_mode_i(op_mode_i),
        .in_valid_i(in_valid_i),
        .in_ready_o(in_ready_o),
        .result_o(result_o),
        .class_mask_o(class_mask_o),
        .status_o(status_o),
        .out_valid_o(out_valid_o),
        .out_ready_i(out_ready_i)
    );

    // ---------------------------------------------------------------------------
    // PROVIDED PLUMBING -- issues operations, checks nothing.
    // ---------------------------------------------------------------------------
    logic clk;
    initial begin clk = 1'b0; forever #5 clk = ~clk; end

    logic rst_n;
    initial rst_n = 1'b0;

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

    // ---------------------------------------------------------------------------
    // TESTBENCH IMPLEMENTATION
    // ---------------------------------------------------------------------------

    typedef struct {
        logic [31:0] res;
        logic [9:0]  mask;
        logic [4:0]  status;
        logic [1:0]  op;
        logic [2:0]  mode;
        bit          a_is_nan;
        bit          b_is_nan;
        bit          a_is_zero;
        bit          b_is_zero;
        bit          a_sign;
        bit          b_sign;
    } expected_t;

    expected_t expected_q[$];

    task automatic fail(string msg);
        $display("RESULT: FAIL (%s)", msg);
        $finish;
    endtask

    // IEEE 754 float operation predictor
    function automatic expected_t predict(logic [31:0] a, logic [31:0] b, logic [1:0] op, logic [2:0] mode);
        automatic expected_t exp;
        automatic logic a_sign, b_sign;
        automatic logic [7:0] a_exp, b_exp;
        automatic logic [22:0] a_sig, b_sig;
        automatic bit a_is_snan, a_is_qnan;
        automatic bit b_is_snan, b_is_qnan;
        automatic bit a_lt_b, a_eq_b;
        automatic bit minmax_a_lt_b;

        a_sign = a[31]; a_exp = a[30:23]; a_sig = a[22:0];
        b_sign = b[31]; b_exp = b[30:23]; b_sig = b[22:0];

        exp.a_is_nan = (a_exp == 255 && a_sig != 0);
        a_is_snan    = (exp.a_is_nan && a_sig[22] == 0);
        a_is_qnan    = (exp.a_is_nan && a_sig[22] == 1);
        exp.a_is_zero = (a_exp == 0 && a_sig == 0);

        exp.b_is_nan = (b_exp == 255 && b_sig != 0);
        b_is_snan    = (exp.b_is_nan && b_sig[22] == 0);
        b_is_qnan    = (exp.b_is_nan && b_sig[22] == 1);
        exp.b_is_zero = (b_exp == 0 && b_sig == 0);

        exp.a_sign = a_sign;
        exp.b_sign = b_sign;

        // Ordering Logic
        if (exp.a_is_zero && exp.b_is_zero) begin
            a_eq_b = 1;
            a_lt_b = 0; 
            minmax_a_lt_b = (a_sign == 1 && b_sign == 0);
        end else if (a_sign != b_sign) begin
            a_eq_b = 0;
            a_lt_b = (a_sign == 1);
            minmax_a_lt_b = a_lt_b;
        end else begin
            a_eq_b = (a[30:0] == b[30:0]);
            if (a_sign == 0) begin
                a_lt_b = (a[30:0] < b[30:0]);
                minmax_a_lt_b = a_lt_b;
            end else begin
                // Both negative: larger magnitude means smaller value
                a_lt_b = (a[30:0] > b[30:0]);
                minmax_a_lt_b = a_lt_b;
            end
        end

        exp.op     = op;
        exp.mode   = mode;
        exp.status = 5'b0;
        exp.res    = 32'h0;
        exp.mask   = 10'h0;

        case (op)
            2'd0: begin // SGNJ (S1, S2)
                if (mode == 3'd0) exp.res = {b_sign, a[30:0]};
                else if (mode == 3'd1) exp.res = {~b_sign, a[30:0]};
                else if (mode == 3'd2) exp.res = {a_sign ^ b_sign, a[30:0]};
            end
            2'd1: begin // MINMAX (S3, S4, S5, S6)
                if (a_is_snan || b_is_snan) exp.status[4] = 1;

                if (exp.a_is_nan && exp.b_is_nan) begin
                    exp.res = 32'h7FC0_0000;
                end else if (exp.a_is_nan) begin
                    exp.res = b;
                end else if (exp.b_is_nan) begin
                    exp.res = a;
                end else begin
                    if (mode == 3'd0) begin // MIN
                        exp.res = minmax_a_lt_b ? a : b;
                    end else if (mode == 3'd1) begin // MAX
                        exp.res = minmax_a_lt_b ? b : a;
                    end
                end
            end
            2'd2: begin // CMP (S7, S8, S9, S10, S11)
                if (mode == 3'd0 || mode == 3'd1) begin // LE, LT
                    if (exp.a_is_nan || exp.b_is_nan) begin
                        exp.res = 32'h0;
                        exp.status[4] = 1; 
                    end else begin
                        if (mode == 3'd0) exp.res = (a_lt_b || a_eq_b) ? 32'h1 : 32'h0;
                        else exp.res = (a_lt_b) ? 32'h1 : 32'h0;
                    end
                end else if (mode == 3'd2) begin // EQ
                    if (a_is_snan || b_is_snan) exp.status[4] = 1; 
                    if (exp.a_is_nan || exp.b_is_nan) begin
                        exp.res = 32'h0;
                    end else begin
                        exp.res = (a_eq_b) ? 32'h1 : 32'h0;
                    end
                end
            end
            2'd3: begin // CLASSIFY (S12, S13)
                exp.mask[0] = (a_sign == 1 && a_exp == 255 && a_sig == 0); // -inf
                exp.mask[1] = (a_sign == 1 && a_exp > 0 && a_exp < 255); // -norm
                exp.mask[2] = (a_sign == 1 && a_exp == 0 && a_sig != 0); // -sub
                exp.mask[3] = (a_sign == 1 && a_exp == 0 && a_sig == 0); // -0
                exp.mask[4] = (a_sign == 0 && a_exp == 0 && a_sig == 0); // +0
                exp.mask[5] = (a_sign == 0 && a_exp == 0 && a_sig != 0); // +sub
                exp.mask[6] = (a_sign == 0 && a_exp > 0 && a_exp < 255); // +norm
                exp.mask[7] = (a_sign == 0 && a_exp == 255 && a_sig == 0); // +inf
                exp.mask[8] = a_is_snan; // sNaN
                exp.mask[9] = a_is_qnan; // qNaN
            end
        endcase

        return exp;
    endfunction

    task automatic issue_and_predict(logic [31:0] a, logic [31:0] b, logic [1:0] op, logic [2:0] mode);
        automatic expected_t exp = predict(a, b, op, mode);
        expected_q.push_back(exp);
        bfm_issue(a, b, op, mode);
    endtask

    // Output Checker
    bit was_reset;
    initial was_reset = 0;

    always @(posedge clk) begin
        if (!rst_n) begin
            expected_q.delete();
            was_reset = 1;
        end else begin
            if (was_reset) begin
                if (out_valid_o) begin
                    fail("S15 - valid high immediately after reset");
                end
                was_reset = 0;
            end

            if (out_valid_o && out_ready_i) begin
                if (expected_q.size() == 0) begin
                    fail("H2 - unexpected result (more outputs than accepted operations)");
                end
                
                begin
                    automatic expected_t exp = expected_q.pop_front();

                    if (status_o[3:0] != 4'b0000) begin
                        fail("S14 - DZ, OF, UF, NX must be 0");
                    end

                    if (status_o[4] != exp.status[4]) begin
                        if (exp.op == 2'd1) fail("S6 - MINMAX NV mismatch");
                        else if (exp.op == 2'd2) begin
                            if (exp.mode == 3'd2) fail("S9 - CMP EQ NV mismatch");
                            else fail("S8 - CMP LE/LT NV mismatch");
                        end else if (exp.op == 2'd0) fail("S2 - SGNJ raised flag");
                        else if (exp.op == 2'd3) fail("S13 - CLASSIFY raised flag");
                        else fail("Exception flags mismatch");
                    end

                    if (exp.op == 2'd3) begin
                        if (class_mask_o !== exp.mask) fail("S12 - CLASSIFY mask mismatch");
                    end else begin
                        if (result_o !== exp.res) begin
                            if (exp.op == 2'd0) fail("S1 - SGNJ result mismatch");
                            else if (exp.op == 2'd1) begin
                                if (exp.a_is_nan && exp.b_is_nan) fail("S5 - MINMAX both NaN mismatch");
                                else if (exp.a_is_nan || exp.b_is_nan) fail("S4 - MINMAX one NaN mismatch");
                                else fail("S3 - MINMAX result mismatch");
                            end else if (exp.op == 2'd2) begin
                                if ((exp.a_is_zero && exp.b_is_zero) && (exp.a_sign != exp.b_sign)) fail("S10 - CMP -0/+0 mismatch");
                                else if (exp.mode == 3'd2) fail("S9 - CMP EQ result mismatch");
                                else fail("S8 - CMP LE/LT result mismatch");
                            end else begin
                                fail("Result mismatch");
                            end
                        end
                    end
                end
            end
        end
    end

    // Toggler to apply backpressure continuously for H3
    bit out_ready_i_override;
    bit override_val;
    int tog_cnt;
    
    initial begin
        out_ready_i_override = 0;
        override_val = 0;
        tog_cnt = 0;
    end

    always @(negedge clk) begin
        if (out_ready_i_override) begin
            out_ready_i = override_val;
        end else if (rst_n) begin
            tog_cnt++;
            out_ready_i = (tog_cnt % 5 != 0); // stall 1 out of 5 cycles
        end else begin
            out_ready_i = 1;
        end
    end

    logic [31:0] test_vals [15];
    
    initial begin
        test_vals[0]  = 32'h0000_0000; // +0.0
        test_vals[1]  = 32'h8000_0000; // -0.0
        test_vals[2]  = 32'h0000_0001; // +min sub
        test_vals[3]  = 32'h8000_0001; // -min sub
        test_vals[4]  = 32'h007F_FFFF; // +max sub
        test_vals[5]  = 32'h807F_FFFF; // -max sub
        test_vals[6]  = 32'h3F80_0000; // +1.0
        test_vals[7]  = 32'hBF80_0000; // -1.0
        test_vals[8]  = 32'h7F80_0000; // +inf
        test_vals[9]  = 32'hFF80_0000; // -inf
        test_vals[10] = 32'h7F80_0001; // +sNaN
        test_vals[11] = 32'hFF80_0001; // -sNaN
        test_vals[12] = 32'h7FC0_0000; // +qNaN (canonical)
        test_vals[13] = 32'hFFC0_0000; // -qNaN
        test_vals[14] = 32'h7FDF_FFFF; // +qNaN (other)

        in_valid_i = 0;
        bfm_reset(4);

        // 1. Reset abort test (S15)
        out_ready_i_override = 1;
        override_val = 0; // Force stall to ensure op gets stuck in pipeline
        issue_and_predict(test_vals[6], test_vals[7], 2'd0, 3'd0);
        bfm_reset(4);     // Flush it
        out_ready_i_override = 0; // Resume toggler for normal execution

        // 2. Exhaustive test (Corner Cases combinations)
        for (int i = 0; i < 15; i++) begin
            for (int j = 0; j < 15; j++) begin
                automatic logic [31:0] a = test_vals[i];
                automatic logic [31:0] b = test_vals[j];

                // SGNJ
                issue_and_predict(a, b, 2'd0, 3'd0);
                issue_and_predict(a, b, 2'd0, 3'd1);
                issue_and_predict(a, b, 2'd0, 3'd2);

                // MINMAX
                issue_and_predict(a, b, 2'd1, 3'd0);
                issue_and_predict(a, b, 2'd1, 3'd1);

                // CMP
                issue_and_predict(a, b, 2'd2, 3'd0);
                issue_and_predict(a, b, 2'd2, 3'd1);
                issue_and_predict(a, b, 2'd2, 3'd2);

                // CLASSIFY
                issue_and_predict(a, b, 2'd3, 3'd0);
            end
        end

        bfm_idle();

        // Wait for all expected results to drain
        while (expected_q.size() > 0) begin
            @(posedge clk);
        end
        
        $display("RESULT: PASS");
        $finish;
    end

endmodule