module fp_noncomp_tb;

    // Signals
    logic        clk;
    logic        rst_n;
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

    // DUT instantiation
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
    // PROVIDED PLUMBING
    // ---------------------------------------------------------------------------
    initial begin clk = 1'b0; forever #5 clk = ~clk; end

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

    // Reference model helpers
    function automatic bit is_snan(input logic [31:0] val);
        return (val[30:23] == 8'hFF) && (val[22:0] != 23'h0) && (val[22] == 1'b0);
    endfunction

    function automatic bit is_qnan(input logic [31:0] val);
        return (val[30:23] == 8'hFF) && (val[22:0] != 23'h0) && (val[22] == 1'b1);
    endfunction

    function automatic bit is_nan(input logic [31:0] val);
        return is_snan(val) || is_qnan(val);
    endfunction

    function automatic bit is_zero(input logic [31:0] val);
        return (val[30:23] == 8'h00) && (val[22:0] == 23'h0);
    endfunction

    function automatic bit is_inf(input logic [31:0] val);
        return (val[30:23] == 8'hFF) && (val[22:0] == 23'h0);
    endfunction

    function automatic bit is_subnormal(input logic [31:0] val);
        return (val[30:23] == 8'h00) && (val[22:0] != 23'h0);
    endfunction

    function automatic bit is_normal(input logic [31:0] val);
        return (val[30:23] > 8'h00) && (val[30:23] < 8'hFF);
    endfunction

    function automatic int compare_fp(input logic [31:0] a, input logic [31:0] b);
        if (is_zero(a) && is_zero(b)) begin
            if (a[31] == 1'b1 && b[31] == 1'b0) return -1;
            if (a[31] == 1'b0 && b[31] == 1'b1) return 1;
            return 0;
        end
        if (a[31] != b[31]) begin
            return a[31] ? -1 : 1;
        end
        if (a[31] == 1'b0) begin
            if (a > b) return 1;
            if (a < b) return -1;
        end else begin
            if (a > b) return -1;
            if (a < b) return 1;
        end
        return 0;
    endfunction

    function automatic logic [31:0] expected_sgnj(input logic [31:0] a, input logic [31:0] b, input logic [2:0] mode);
        logic [31:0] res;
        res[30:0] = a[30:0];
        case (mode)
            3'd0: res[31] = b[31];
            3'd1: res[31] = ~b[31];
            3'd2: res[31] = a[31] ^ b[31];
            default: res[31] = a[31];
        endcase
        return res;
    endfunction

    function automatic logic [31:0] expected_minmax(input logic [31:0] a, input logic [31:0] b, input logic [2:0] mode, output logic nv);
        logic [31:0] res;
        nv = is_snan(a) || is_snan(b);
        if (is_nan(a) && is_nan(b)) begin
            res = 32'h7FC0_0000;
        end else if (is_nan(a)) begin
            res = b;
        end else if (is_nan(b)) begin
            res = a;
        end else begin
            int cmp = compare_fp(a, b);
            if (mode == 3'd0) begin
                if (cmp <= 0) res = a;
                else res = b;
            end else begin
                if (cmp >= 0) res = a;
                else res = b;
            end
        end
        return res;
    endfunction

    function automatic logic [31:0] expected_cmp(input logic [31:0] a, input logic [31:0] b, input logic [2:0] mode, output logic nv);
        logic [31:0] res = 32'h0000_0000;
        if (is_nan(a) || is_nan(b)) begin
            if (mode == 3'd2) begin
                nv = is_snan(a) || is_snan(b);
            end else begin
                nv = 1'b1;
            end
            res = 32'h0000_0000;
        end else begin
            nv = 1'b0;
            int cmp = compare_fp(a, b);
            case (mode)
                3'd0: if (cmp <= 0) res = 32'h0000_0001;
                3'd1: if (cmp < 0) res = 32'h0000_0001;
                3'd2: if (cmp == 0) res = 32'h0000_0001;
            endcase
        end
        return res;
    endfunction

    function automatic logic [9:0] expected_classify(input logic [31:0] a);
        logic [9:0] mask = 10'b0;
        if (is_inf(a)) begin
            if (a[31]) mask[0] = 1'b1;
            else mask[7] = 1'b1;
        end else if (is_normal(a)) begin
            if (a[31]) mask[1] = 1'b1;
            else mask[6] = 1'b1;
        end else if (is_subnormal(a)) begin
            if (a[31]) mask[2] = 1'b1;
            else mask[5] = 1'b1;
        end else if (is_zero(a)) begin
            if (a[31]) mask[3] = 1'b1;
            else mask[4] = 1'b1;
        end else if (is_snan(a)) begin
            mask[8] = 1'b1;
        end else if (is_qnan(a)) begin
            mask[9] = 1'b1;
        end
        return mask;
    endfunction

    function automatic logic [4:0] expected_status(input logic nv);
        return {nv, 4'b0000};
    endfunction

    typedef struct {
        logic [1:0]  op;
        logic [31:0] result;
        logic [9:0]  class_mask;
        logic [4:0]  status;
    } expected_t;

    expected_t expected_queue[$];
    logic test_failed = 1'b0;

    always @(posedge clk) begin
        if (rst_n) begin
            if (out_valid_o && out_ready_i) begin
                if (expected_queue.size() == 0) begin
                    $display("FAIL: H2 - Result delivered but no operation was accepted");
                    test_failed = 1'b1;
                end else begin
                    automatic expected_t exp = expected_queue.pop_front();
                    
                    if (exp.op != 2'd3) begin
                        if (result_o !== exp.result) begin
                            $display("FAIL: S1/S3/S4/S5/S7 - result_o mismatch. Expected %h, got %h", exp.result, result_o);
                            test_failed = 1'b1;
                        end
                    end
                    
                    if (exp.op == 2'd3) begin
                        if (class_mask_o !== exp.class_mask) begin
                            $display("FAIL: S12 - class_mask_o mismatch. Expected %b, got %b", exp.class_mask, class_mask_o);
                            test_failed = 1'b1;
                        end
                    end
                    
                    if (status_o !== exp.status) begin
                        $display("FAIL: S6/S9/S11/S13/S14 - status_o mismatch. Expected %b, got %b", exp.status, status_o);
                        test_failed = 1'b1;
                    end
                end
            end
        end
    end

    task automatic check_issue(input logic [31:0] a,
                               input logic [31:0] b,
                               input logic [1:0]  op,
                               input logic [2:0]  mode);
        expected_t exp;
        logic nv = 1'b0;
        
        bfm_issue(a, b, op, mode);
        
        exp.op = op;
        if (op == 2'd0) begin
            exp.result = expected_sgnj(a, b, mode);
            exp.status = expected_status(1'b0);
        end else if (op == 2'd1) begin
            exp.result = expected_minmax(a, b, mode, nv);
            exp.status = expected_status(nv);
        end else if (op == 2'd2) begin
            exp.result = expected_cmp(a, b, mode, nv);
            exp.status = expected_status(nv);
        end else if (op == 2'd3) begin
            exp.result = 32'h0;
            exp.class_mask = expected_classify(a);
            exp.status = expected_status(1'b0);
        end
        
        expected_queue.push_back(exp);
    endtask

    initial begin
        operand_a_i = 0;
        operand_b_i = 0;
        op_i = 0;
        op_mode_i = 0;
        in_valid_i = 0;
        out_ready_i = 0;

        @(negedge clk);
        bfm_reset(4);

        bfm_out_ready(1);

        $display("Running SGNJ tests...");
        check_issue(32'h3F800000, 32'hBF800000, 2'd0, 3'd0);
        check_issue(32'h3F800000, 32'hBF800000, 2'd0, 3'd1);
        check_issue(32'h3F800000, 32'hBF800000, 2'd0, 3'd2);
        check_issue(32'h7FC00000, 32'hBF800000, 2'd0, 3'd0);

        $display("Running MINMAX tests...");
        check_issue(32'h80000000, 32'h00000000, 2'd1, 3'd0);
        check_issue(32'h80000000, 32'h00000000, 2'd1, 3'd1);
        check_issue(32'h7FC00000, 32'h3F800000, 2'd1, 3'd0);
        check_issue(32'h7F800001, 32'h3F800000, 2'd1, 3'd0);
        check_issue(32'h7FC00000, 32'hFFC00000, 2'd1, 3'd0);
        check_issue(32'h7F800001, 32'hFF800001, 2'd1, 3'd0);

        $display("Running CMP tests...");
        check_issue(32'h80000000, 32'h00000000, 2'd2, 3'd0);
        check_issue(32'h80000000, 32'h00000000, 2'd2, 3'd1);
        check_issue(32'h80000000, 32'h00000000, 2'd2, 3'd2);
        check_issue(32'h7FC00000, 32'h3F800000, 2'd2, 3'd0);
        check_issue(32'h7F800001, 32'h3F800000, 2'd2, 3'd0);
        check_issue(32'h7FC00000, 32'h3F800000, 2'd2, 3'd2);
        check_issue(32'h7F800001, 32'h3F800000, 2'd2, 3'd2);

        $display("Running CLASSIFY tests...");
        check_issue(32'hFF800000, 0, 2'd3, 0);
        check_issue(32'hBF800001, 0, 2'd3, 0);
        check_issue(32'h80000001, 0, 2'd3, 0);
        check_issue(32'h80000000, 0, 2'd3, 0);
        check_issue(32'h00000000, 0, 2'd3, 0);
        check_issue(32'h00000001, 0, 2'd3, 0);
        check_issue(32'h3F800001, 0, 2'd3, 0);
        check_issue(32'h7F800000, 0, 2'd3, 0);
        check_issue(32'h7F800001, 0, 2'd3, 0);
        check_issue(32'h7FC00000, 0, 2'd3, 0);

        $display("Running reset during operation test (S15)...");
        bfm_out_ready(0);
        @(negedge clk);
        operand_a_i = 32'h3F800000;
        operand_b_i = 32'h40000000;
        op_i = 2'd1;
        op_mode_i = 3'd0;
        in_valid_i = 1'b1;
        
        while (!in_ready_o) begin
            @(posedge clk);
        end
        
        @(negedge clk);
        rst_n = 1'b0;
        in_valid_i = 1'b0;
        
        repeat (2) @(posedge clk);
        @(negedge clk);
        rst_n = 1'b1;
        
        bfm_out_ready(1);
        repeat (10) @(posedge clk);
        
        if (out_valid_o) begin
            $display("FAIL: S15 - Result produced after reset for operation accepted before reset");
            test_failed = 1'b1;
        end

        $display("Running back-to-back tests...");
        bfm_out_ready(1);
        check_issue(32'h3F800000, 32'h40000000, 2'd1, 3'd0);
        check_issue(32'h40000000, 32'h3F800000, 2'd1, 3'd1);
        
        int wait_count = 0;
        while (expected_queue.size() > 0) begin
            @(posedge clk);
            wait_count++;
            if (wait_count > 100) begin
                $display("FAIL: H2/H3 - Timeout waiting for results to be delivered");
                test_failed = 1'b1;
                break;
            end
        end
        
        if (expected_queue.size() != 0) begin
            $display("FAIL: H2 - Not all results were delivered");
            test_failed = 1'b1;
        end

        $display("RESULT: %s", test_failed ? "FAIL" : "PASS");
        $finish;
    end

endmodule