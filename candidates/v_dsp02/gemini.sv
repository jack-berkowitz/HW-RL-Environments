`timescale 1ns/1ps

module fp_noncomp_tb;

    // --------------------------------------------------------
    // Signals
    // --------------------------------------------------------
    logic        clk_i;
    logic        rst_ni;
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

    // --------------------------------------------------------
    // Clock Generation
    // --------------------------------------------------------
    initial begin
        clk_i = 0;
        forever #5 clk_i = ~clk_i;
    end

    // --------------------------------------------------------
    // Watchdog Timer (S16)
    // --------------------------------------------------------
    initial begin
        #5000000; // Generous timeout
        $display("RESULT: FAIL");
        $display("S16: Watchdog timeout. Testbench stalled.");
        $finish;
    end

    // --------------------------------------------------------
    // DUT Instantiation
    // --------------------------------------------------------
    fp_noncomp dut (
        .clk_i(clk_i),
        .rst_ni(rst_ni),
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

    // --------------------------------------------------------
    // Helper Functions: Floating Point Properties (A1, A3)
    // --------------------------------------------------------
    function automatic logic is_nan(logic [31:0] v);
        return (v[30:23] == 8'hFF) && (v[22:0] != 0);
    endfunction

    function automatic logic is_snan(logic [31:0] v);
        return (v[30:23] == 8'hFF) && (v[22:0] != 0) && (v[22] == 0);
    endfunction

    function automatic logic is_qnan(logic [31:0] v);
        return (v[30:23] == 8'hFF) && (v[22] == 1);
    endfunction

    function automatic logic is_inf(logic [31:0] v);
        return (v[30:23] == 8'hFF) && (v[22:0] == 0);
    endfunction

    function automatic logic is_zero(logic [31:0] v);
        return (v[30:23] == 0) && (v[22:0] == 0);
    endfunction

    function automatic logic is_subnorm(logic [31:0] v);
        return (v[30:23] == 0) && (v[22:0] != 0);
    endfunction

    function automatic logic is_norm(logic [31:0] v);
        return (v[30:23] > 0) && (v[30:23] < 8'hFF);
    endfunction

    // --------------------------------------------------------
    // Helper Functions: Comparison Predicates
    // --------------------------------------------------------
    function automatic logic fp_less_minmax(logic [31:0] a, logic [31:0] b);
        // S3: -0.0 is less than +0.0
        logic sign_a = a[31]; logic sign_b = b[31];
        logic [30:0] abs_a = a[30:0]; logic [30:0] abs_b = b[30:0];
        if (sign_a != sign_b) return sign_a; 
        if (sign_a) return abs_a > abs_b;
        return abs_a < abs_b;
    endfunction

    function automatic logic fp_less_cmp(logic [31:0] a, logic [31:0] b);
        // S10: -0.0 equals +0.0, neither is less
        logic sign_a = a[31]; logic sign_b = b[31];
        logic [30:0] abs_a = a[30:0]; logic [30:0] abs_b = b[30:0];
        if (abs_a == 0 && abs_b == 0) return 0; 
        if (sign_a != sign_b) return sign_a;
        if (sign_a) return abs_a > abs_b;
        return abs_a < abs_b;
    endfunction

    function automatic logic fp_eq_cmp(logic [31:0] a, logic [31:0] b);
        // S10: -0.0 equals +0.0
        logic [30:0] abs_a = a[30:0]; logic [30:0] abs_b = b[30:0];
        if (abs_a == 0 && abs_b == 0) return 1;
        return (a == b);
    endfunction

    // --------------------------------------------------------
    // Transaction & Scoreboard
    // --------------------------------------------------------
    typedef struct {
        logic [31:0] a;
        logic [31:0] b;
        logic [1:0]  op;
        logic [2:0]  mode;
        logic [31:0] exp_res;
        logic [9:0]  exp_class;
        logic [4:0]  exp_status;
    } xact_t;

    xact_t expected_q[$];

    task automatic fail_with(string msg);
        $display("RESULT: FAIL");
        $display("%s", msg);
        $finish;
    endtask

    // Generate expected outputs based on specification
    function automatic xact_t get_expected(logic [31:0] a, logic [31:0] b, logic [1:0] op, logic [2:0] mode);
        xact_t res;
        logic a_snan = is_snan(a), b_snan = is_snan(b);
        logic a_nan = is_nan(a), b_nan = is_nan(b);

        res.a = a; res.b = b; res.op = op; res.mode = mode;
        res.exp_status = 5'b00000;
        res.exp_res = 32'b0;
        res.exp_class = 10'b0;

        case (op)
            2'd0: begin // SGNJ (S1, S2)
                res.exp_res[30:0] = a[30:0];
                if (mode == 0) res.exp_res[31] = b[31];
                else if (mode == 1) res.exp_res[31] = ~b[31];
                else if (mode == 2) res.exp_res[31] = a[31] ^ b[31];
            end

            2'd1: begin // MINMAX
                if (a_snan || b_snan) res.exp_status[4] = 1; // S6: NV iff sNaN

                if (a_nan && b_nan) begin
                    res.exp_res = 32'h7FC0_0000; // S5: canonical qNaN
                end else if (a_nan) begin
                    res.exp_res = b; // S4: other operand
                end else if (b_nan) begin
                    res.exp_res = a; // S4: other operand
                end else begin
                    logic a_less = fp_less_minmax(a, b);
                    if (mode == 0) res.exp_res = a_less ? a : b; // S3: min
                    else           res.exp_res = a_less ? b : a; // S3: max
                end
            end

            2'd2: begin // CMP
                logic is_lt = fp_less_cmp(a, b);
                logic is_eq = fp_eq_cmp(a, b);
                
                if (mode == 0) begin // LE
                    if (a_nan || b_nan) begin
                        res.exp_res = 32'h0;
                        res.exp_status[4] = 1; // S8: Signalling cmp
                    end else begin
                        res.exp_res = (is_lt || is_eq) ? 32'h1 : 32'h0;
                    end
                end else if (mode == 1) begin // LT
                    if (a_nan || b_nan) begin
                        res.exp_res = 32'h0;
                        res.exp_status[4] = 1; // S8: Signalling cmp
                    end else begin
                        res.exp_res = is_lt ? 32'h1 : 32'h0;
                    end
                end else if (mode == 2) begin // EQ
                    if (a_nan || b_nan) begin
                        res.exp_res = 32'h0;
                        if (a_snan || b_snan) res.exp_status[4] = 1; // S9: Quiet cmp
                    end else begin
                        res.exp_res = is_eq ? 32'h1 : 32'h0;
                    end
                end
            end

            2'd3: begin // CLASSIFY (S12, S13)
                res.exp_class[0] = a[31] && is_inf(a);
                res.exp_class[1] = a[31] && is_norm(a);
                res.exp_class[2] = a[31] && is_subnorm(a);
                res.exp_class[3] = a[31] && is_zero(a);
                res.exp_class[4] = !a[31] && is_zero(a);
                res.exp_class[5] = !a[31] && is_subnorm(a);
                res.exp_class[6] = !a[31] && is_norm(a);
                res.exp_class[7] = !a[31] && is_inf(a);
                res.exp_class[8] = is_snan(a);
                res.exp_class[9] = is_qnan(a);
            end
        endcase

        return res;
    endfunction

    // --------------------------------------------------------
    // Driver
    // --------------------------------------------------------
    task automatic send_xact(xact_t xact);
        expected_q.push_back(xact);

        operand_a_i <= xact.a;
        operand_b_i <= xact.b;
        op_i <= xact.op;
        op_mode_i <= xact.mode;
        in_valid_i <= 1'b1;

        do begin
            @(posedge clk_i);
        end while (!(in_valid_i && in_ready_o));

        in_valid_i <= 1'b0;

        // Randomly stall to exercise ready/valid (H1)
        if (($random % 4) == 0) begin
            repeat ($random % 4) @(posedge clk_i);
        end
    endtask

    logic [31:0] test_vals [] = '{
        32'h0000_0000, // +0.0
        32'h8000_0000, // -0.0
        32'h3F80_0000, // +1.0
        32'hBF80_0000, // -1.0
        32'h7F80_0000, // +Inf
        32'hFF80_0000, // -Inf
        32'h7FC0_0000, // canonical qNaN
        32'h7FD0_0000, // other qNaN
        32'h7F80_0001, // sNaN
        32'hFF80_0001, // -sNaN
        32'h0000_0001, // +subnorm
        32'h8000_0001  // -subnorm
    };

    task automatic run_tests();
        xact_t exp;
        
        // Exhaustive cross of corner case values
        foreach (test_vals[i]) begin
            foreach (test_vals[j]) begin
                // SGNJ
                for (int m=0; m<3; m++) begin
                    exp = get_expected(test_vals[i], test_vals[j], 2'd0, m);
                    send_xact(exp);
                end
                // MINMAX
                for (int m=0; m<2; m++) begin
                    exp = get_expected(test_vals[i], test_vals[j], 2'd1, m);
                    send_xact(exp);
                end
                // CMP
                for (int m=0; m<3; m++) begin
                    exp = get_expected(test_vals[i], test_vals[j], 2'd2, m);
                    send_xact(exp);
                end
                // CLASSIFY (only depends on A, but tested across loops to stress B independence)
                if (j == 0) begin
                    exp = get_expected(test_vals[i], test_vals[j], 2'd3, 0);
                    send_xact(exp);
                end
            end
        end

        // Random sequence
        for (int k=0; k<200; k++) begin
            logic [31:0] a = $random;
            logic [31:0] b = $random;
            logic [1:0]  op = $random % 4;
            logic [2:0]  mode;
            
            if (op == 0 || op == 2) mode = $random % 3;
            else if (op == 1)       mode = $random % 2;
            else                    mode = $random % 8; 

            exp = get_expected(a, b, op, mode);
            send_xact(exp);
        end
    endtask

    // --------------------------------------------------------
    // Monitor & Checkers
    // --------------------------------------------------------
    logic [31:0] saved_result;
    logic [9:0]  saved_class;
    logic [4:0]  saved_status;
    logic        was_valid;

    always @(posedge clk_i) begin
        if (rst_ni) begin
            // H3: Output stability when valid but not ready
            if (was_valid && !out_ready_i) begin
                if (!out_valid_o) 
                    fail_with("H3: out_valid_o dropped before out_ready_i was asserted");
                if (result_o !== saved_result || class_mask_o !== saved_class || status_o !== saved_status)
                    fail_with("H3: Output data changed while waiting for out_ready_i");
            end

            was_valid <= out_valid_o;
            saved_result <= result_o;
            saved_class <= class_mask_o;
            saved_status <= status_o;

            if (out_valid_o && out_ready_i) begin
                if (expected_q.size() == 0) begin
                    fail_with("H2: Unexpected result delivered (no operation in flight)");
                end else begin
                    xact_t exp = expected_q.pop_front();
                    
                    if (exp.op != 2'd3 && result_o !== exp.exp_res)
                        fail_with($sformatf("S1-S11: Result mismatch. Op %d mode %d. a=%h b=%h. Expected %h, got %h", exp.op, exp.mode, exp.a, exp.b, exp.exp_res, result_o));
                    
                    if (exp.op == 2'd3 && class_mask_o !== exp.exp_class)
                        fail_with($sformatf("S12: Class mismatch. a=%h. Expected %h, got %h", exp.a, exp.exp_class, class_mask_o));
                    
                    if (status_o !== exp.exp_status)
                        fail_with($sformatf("S6/S8/S9/S14: Status mismatch. Expected %h, got %h", exp.exp_status, status_o));
                end
            end
        end else begin
            was_valid <= 0;
        end
    end

    // --------------------------------------------------------
    // Main Test Sequence
    // --------------------------------------------------------
    initial begin
        clk_i = 0;
        rst_ni = 0;
        in_valid_i = 0;
        out_ready_i = 0;
        operand_a_i = 0; operand_b_i = 0; op_i = 0; op_mode_i = 0;

        #20;
        @(posedge clk_i);

        // Feed operation during reset (S15 check)
        in_valid_i = 1;
        operand_a_i = test_vals[2];
        op_i = 2'd0;
        @(posedge clk_i);
        in_valid_i = 0;

        @(posedge clk_i);
        rst_ni = 1; // Release reset

        // Verify out_valid_o is low directly after reset (S15)
        @(negedge clk_i);
        if (out_valid_o !== 1'b0) begin
            fail_with("S15: out_valid_o not low immediately after reset release");
        end

        fork
            // Random ready modulation thread
            begin
                forever begin
                    @(posedge clk_i);
                    out_ready_i <= ($random % 2) == 0;
                end
            end
            
            // Stimulus thread
            begin
                run_tests();
                
                // Wait for all in-flight ops to complete
                while (expected_q.size() > 0) @(posedge clk_i);
                
                repeat(10) @(posedge clk_i); // Grace period
                
                $display("RESULT: PASS");
                $finish;
            end
        join_any
    end

endmodule