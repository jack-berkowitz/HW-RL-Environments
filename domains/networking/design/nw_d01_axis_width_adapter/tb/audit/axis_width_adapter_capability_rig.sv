// =============================================================================
// axis_width_adapter_capability_rig.sv -- CAPABILITY AUDIT for nw_d01.
// NEVER SHIPPED. Measurement only: emits CAPABILITY: lines, decides nothing.
// =============================================================================
// The same three-way decomposition applied to d_nw01: off-spec configuration,
// capability gap, genuine optimisation. For a width adapter the capability axis
// is SUSTAINED THROUGHPUT -- a design with less internal storage is smaller and
// stalls more, and every correctness test still passes because stalling is
// legal. The spec deliberately permits a zero-storage bypass, so this measures
// rather than gates.
//
//   PHASE A  saturated throughput: both sides always ready/valid.
//   PHASE B  bubble count: cycles where the input stalls with data offered.
// =============================================================================
`timescale 1ns/1ps

module axis_width_adapter_capability_rig #(
    parameter int S_BYTES = 1,
    parameter int M_BYTES = 4,
    parameter int USER_W  = 1,
    parameter int WINDOW  = 20000
);
    logic clk = 1'b0, rst_n;
    always #5 clk = ~clk;

    logic                 s_valid, s_ready, s_last, m_valid, m_ready, m_last;
    logic [S_BYTES*8-1:0] s_data;
    logic [S_BYTES-1:0]   s_keep;
    logic [USER_W-1:0]    s_user, m_user;
    logic [M_BYTES*8-1:0] m_data;
    logic [M_BYTES-1:0]   m_keep;

    axis_width_adapter #(.S_BYTES(S_BYTES), .M_BYTES(M_BYTES), .USER_W(USER_W)) dut (
        .clk(clk), .rst_n(rst_n),
        .s_valid(s_valid), .s_ready(s_ready), .s_data(s_data), .s_keep(s_keep),
        .s_last(s_last), .s_user(s_user),
        .m_valid(m_valid), .m_ready(m_ready), .m_data(m_data), .m_keep(m_keep),
        .m_last(m_last), .m_user(m_user));

    int in_beats, out_beats, in_bytes, out_bytes, stall_cycles;
    int beat_in_frame;
    localparam int FRAME_BEATS = 8;

    always_comb begin
        s_valid = 1'b1;                       // always offering
        s_keep  = '1;
        s_user  = '0;
        s_last  = (beat_in_frame == FRAME_BEATS - 1);
        s_data  = {(S_BYTES*8){1'b0}} | S_BYTES'(beat_in_frame + 1);
    end

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            in_beats <= 0; out_beats <= 0; in_bytes <= 0; out_bytes <= 0;
            stall_cycles <= 0; beat_in_frame <= 0;
        end else begin
            if (s_valid && s_ready) begin
                in_beats <= in_beats + 1;
                in_bytes <= in_bytes + S_BYTES;
                beat_in_frame <= (beat_in_frame == FRAME_BEATS - 1) ? 0 : beat_in_frame + 1;
            end else if (s_valid) stall_cycles <= stall_cycles + 1;
            if (m_valid && m_ready) begin
                out_beats <= out_beats + 1;
                for (int b = 0; b < M_BYTES; b++) if (m_keep[b]) out_bytes <= out_bytes + 1;
            end
        end
    end

    initial begin
        m_ready = 1'b1;                       // never backpressure: DUT is the limit
        rst_n = 1'b0;
        repeat (12) @(posedge clk);
        rst_n = 1'b1;
        repeat (WINDOW) @(posedge clk);
        $display("CAPABILITY: S=%0d M=%0d in_bytes=%0d out_bytes=%0d bytes_per_1000cyc=%0d input_stall_cycles=%0d",
                 S_BYTES, M_BYTES, in_bytes, out_bytes,
                 (in_bytes * 1000) / WINDOW, stall_cycles);
        $finish;
    end

    initial begin
        #20_000_000;
        $display("CAPABILITY: TIMEOUT");
        $finish;
    end
endmodule
