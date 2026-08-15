// =============================================================================
// axis_width_adapter_diff.sv -- diff-rate harness. NEVER SHIPPED.
// =============================================================================
// Reference and mutant side by side under IDENTICAL stimulus; reports the
// fraction of observed cycles on which their observable interfaces diverge.
// Mutant-quality measurement only -- it never decides pass or fail.
//
// Diff rate measures divergence UNDER THIS STIMULUS. It is not the same thing
// as difficulty for a checker that has to detect the divergence. Read it as
// "how much signal is available", not "how hard this is".
//
// The stimulus honours the spec's input contract (H2): data is held stable
// while s_valid is high and unaccepted, and s_valid is never withdrawn from an
// unaccepted beat. A zero-storage pass-through propagates its input directly,
// so a harness that broke H2 would manufacture divergence that is really its
// own misbehaviour.
//
// s_ready is compared too: a mutant that mishandles backpressure diverges in
// which beats it accepts, which is a real behavioural difference.
//
// Prints:  DIFF_RATE: <diverging> / <observed> = <ppm>
// =============================================================================

`timescale 1ns/1ps

module axis_width_adapter_diff;

    parameter int S_BYTES = 1;
    parameter int M_BYTES = 4;
    parameter int USER_W  = 1;
    parameter int PACKETS = 1500;

    logic                 clk = 1'b0;
    logic                 rst_n;
    logic                 s_valid, s_last, m_ready;
    logic [S_BYTES*8-1:0] s_data;
    logic [S_BYTES-1:0]   s_keep;
    logic [USER_W-1:0]    s_user;

    logic                 ref_sready, ref_mvalid, ref_mlast;
    logic [M_BYTES*8-1:0] ref_mdata;
    logic [M_BYTES-1:0]   ref_mkeep;
    logic [USER_W-1:0]    ref_muser;

    logic                 mut_sready, mut_mvalid, mut_mlast;
    logic [M_BYTES*8-1:0] mut_mdata;
    logic [M_BYTES-1:0]   mut_mkeep;
    logic [USER_W-1:0]    mut_muser;

    axis_width_adapter #(.S_BYTES(S_BYTES), .M_BYTES(M_BYTES), .USER_W(USER_W)) u_ref (
        .clk(clk), .rst_n(rst_n), .s_valid(s_valid), .s_ready(ref_sready),
        .s_data(s_data), .s_keep(s_keep), .s_last(s_last), .s_user(s_user),
        .m_valid(ref_mvalid), .m_ready(m_ready), .m_data(ref_mdata),
        .m_keep(ref_mkeep), .m_last(ref_mlast), .m_user(ref_muser));

    axis_width_adapter_mut #(.S_BYTES(S_BYTES), .M_BYTES(M_BYTES), .USER_W(USER_W)) u_mut (
        .clk(clk), .rst_n(rst_n), .s_valid(s_valid), .s_ready(mut_sready),
        .s_data(s_data), .s_keep(s_keep), .s_last(s_last), .s_user(s_user),
        .m_valid(mut_mvalid), .m_ready(m_ready), .m_data(mut_mdata),
        .m_keep(mut_mkeep), .m_last(mut_mlast), .m_user(mut_muser));

    always #5 clk = ~clk;

    longint observed = 0, diverged = 0;

    always_ff @(posedge clk) begin
        if (rst_n) begin
            observed++;
            if ((ref_sready !== mut_sready) || (ref_mvalid !== mut_mvalid) ||
                (ref_mvalid && mut_mvalid &&
                 ((ref_mdata !== mut_mdata) || (ref_mkeep !== mut_mkeep) ||
                  (ref_mlast !== mut_mlast) || (ref_muser !== mut_muser))))
                diverged++;
        end
    end

    // Send one packet, holding each beat until BOTH DUTs have accepted it, so
    // the two never see different input streams.
    task automatic send_packet(input int nbytes, input logic [USER_W-1:0] user);
        int remaining, n, guard;
        remaining = nbytes;
        while (remaining > 0) begin
            n = (remaining > S_BYTES) ? S_BYTES : remaining;
            s_data = '0; s_keep = '0;
            for (int i = 0; i < S_BYTES; i++)
                if (i < n) begin
                    s_data[i*8 +: 8] = 8'($urandom_range(0,255));
                    s_keep[i] = 1'b1;
                end
            s_last  = (remaining - n == 0);
            s_user  = user;
            s_valid = 1'b1;
            guard = 0;
            while (!(ref_sready && mut_sready) && guard < 500) begin
                @(posedge clk); #1; guard++;
            end
            @(posedge clk); #1;
            s_valid = 1'b0;
            remaining -= n;
        end
    endtask

    initial begin
        s_valid = 0; s_data = '0; s_keep = '0; s_last = 0; s_user = '0;
        m_ready = 1; rst_n = 0;
        repeat (4) begin @(posedge clk); #1; end
        rst_n = 1;
        @(posedge clk); #1;

        for (int p = 0; p < PACKETS; p++) begin
            m_ready = ((p % 5) != 0);
            send_packet(1 + $urandom_range(0, 8*S_BYTES), USER_W'($urandom_range(0,(1<<USER_W)-1)));
            if ((p % 7) == 6) begin
                s_valid = 1'b0;
                repeat (1 + $urandom_range(0,2)) begin @(posedge clk); #1; end
            end
            // Periodic mid-stream reset, so a reset-scoped bug has any
            // opportunity at all to diverge. Without it the stimulus, not the
            // mutant, is the reason nothing shows up.
            if ((p % 200) == 199) begin
                s_valid = 1'b0; m_ready = 1'b0;
                @(posedge clk); #1;
                rst_n = 1'b0;
                repeat (3) begin @(posedge clk); #1; end
                rst_n = 1'b1; m_ready = 1'b1;
                repeat (2) begin @(posedge clk); #1; end
            end
        end
        s_valid = 0; m_ready = 1;
        repeat (60) begin @(posedge clk); #1; end

        $display("DIFF_RATE: %0d / %0d = %0d ppm", diverged, observed,
                 (observed == 0) ? 64'd0 : (diverged * 64'd1000000) / observed);
        $finish;
    end

    initial begin
        #40_000_000;
        $display("DIFF_RATE: timeout");
        $finish;
    end

endmodule
