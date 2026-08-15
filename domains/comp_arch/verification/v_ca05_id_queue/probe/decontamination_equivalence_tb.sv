// Equivalence harness: the decontaminated DUT against the untouched anchor.
// Identical stimulus into both, every output compared every cycle. If
// decontamination changed behaviour, this is where it shows up.
`timescale 1ns/1ps

module decon_equiv_tb;
    localparam int IDW = 4, CAP = 8, DW = 32;

    logic clk = 0, rst_n;
    always #5 clk = ~clk;

    logic [IDW-1:0] in_id, out_id;
    logic [DW-1:0]  in_data, ex_data, ex_mask;
    logic           in_req, ex_req, out_pop, out_req;

    // reference (untouched anchor)
    logic a_in_gnt, a_ex, a_ex_gnt, a_out_valid, a_out_gnt, a_full, a_empty;
    logic [DW-1:0] a_out_data;
    id_queue #(.ID_WIDTH(IDW), .CAPACITY(CAP), .data_t(logic[DW-1:0])) u_ref (
        .clk_i(clk), .rst_ni(rst_n),
        .inp_id_i(in_id), .inp_data_i(in_data), .inp_req_i(in_req), .inp_gnt_o(a_in_gnt),
        .exists_data_i(ex_data), .exists_mask_i(ex_mask), .exists_req_i(ex_req),
        .exists_o(a_ex), .exists_gnt_o(a_ex_gnt),
        .oup_id_i(out_id), .oup_pop_i(out_pop), .oup_req_i(out_req),
        .oup_data_o(a_out_data), .oup_data_valid_o(a_out_valid), .oup_gnt_o(a_out_gnt),
        .full_o(a_full), .empty_o(a_empty));

    // decontaminated (the file that would ship)
    logic b_in_gnt, b_ex, b_ex_gnt, b_out_valid, b_out_gnt, b_full, b_empty;
    logic [DW-1:0] b_out_data;
    tag_tracker #(.TAG_W(IDW), .SLOTS(CAP), .payload_t(logic[DW-1:0])) u_dec (
        .clk_i(clk), .rst_ni(rst_n),
        .push_tag_i(in_id), .push_data_i(in_data), .push_req_i(in_req), .push_gnt_o(b_in_gnt),
        .match_data_i(ex_data), .match_mask_i(ex_mask), .match_req_i(ex_req),
        .match_hit_o(b_ex), .match_gnt_o(b_ex_gnt),
        .pop_tag_i(out_id), .pop_en_i(out_pop), .pop_req_i(out_req),
        .pop_data_o(b_out_data), .pop_data_valid_o(b_out_valid), .pop_gnt_o(b_out_gnt),
        .full_o(b_full), .empty_o(b_empty));

    int errors = 0, checks = 0;
    task automatic cmp(input string nm, input logic x, input logic y);
        checks++;
        if (x !== y) begin
            errors++;
            if (errors <= 10) $display("[DIFF] t=%0t %s: ref=%b decon=%b", $time, nm, x, y);
        end
    endtask

    always @(negedge clk) if (rst_n) begin
        cmp("in_gnt", a_in_gnt, b_in_gnt);
        cmp("exists", a_ex, b_ex);
        cmp("ex_gnt", a_ex_gnt, b_ex_gnt);
        cmp("out_valid", a_out_valid, b_out_valid);
        cmp("out_gnt", a_out_gnt, b_out_gnt);
        cmp("full", a_full, b_full);
        cmp("empty", a_empty, b_empty);
        checks++;
        if (a_out_data !== b_out_data) begin
            errors++;
            if (errors <= 10) $display("[DIFF] t=%0t out_data: ref=%0h decon=%0h", $time, a_out_data, b_out_data);
        end
    end

    initial begin
        in_id='0; in_data='0; in_req=0; ex_data='0; ex_mask='0; ex_req=0;
        out_id='0; out_pop=0; out_req=0;
        rst_n=0; repeat (6) @(posedge clk); rst_n=1;
        for (int i = 0; i < 20000; i++) begin
            @(posedge clk);
            in_id   <= $urandom_range(0, (1<<IDW)-1);
            in_data <= $urandom;
            in_req  <= ($urandom_range(0,99) < 60);
            out_id  <= $urandom_range(0, (1<<IDW)-1);
            out_req <= ($urandom_range(0,99) < 45);
            out_pop <= ($urandom_range(0,99) < 70);
            ex_data <= $urandom;
            ex_mask <= ($urandom_range(0,99) < 50) ? '0 : $urandom;
            ex_req  <= ($urandom_range(0,99) < 30);
        end
        $display("METRIC: comparisons=%0d differences=%0d", checks, errors);
        if (errors == 0) $display("TEST_RESULT: PASS");
        else $display("TEST_RESULT: FAIL: %0d differences", errors);
        $finish;
    end
endmodule
