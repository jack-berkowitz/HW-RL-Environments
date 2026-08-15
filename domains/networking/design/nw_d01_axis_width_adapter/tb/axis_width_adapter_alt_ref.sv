// =============================================================================
// axis_width_adapter_alt_ref.sv -- SECOND SOURCE for nw_d01. NEVER SHIPPED.
// =============================================================================
// A FALSIFIER, not an oracle. Written by us, on purpose, to make DIFFERENT free
// choices from Forencich's axis_adapter and thereby try to break the checker.
// It never grades a submission and the spec is never validated against it. Its
// only job is to fail -- and if it does, the checker is over-constrained.
//
// Deliberate structural differences from the upstream reference:
//
//   upstream                          | this
//   ----------------------------------|--------------------------------------
//   three separate code paths         | ONE path for every ratio, including
//   (bypass / upsize / downsize)      | pass-through
//   segment counter + segment-indexed | circular BYTE FIFO with a per-byte
//   assembly registers                | end-of-packet tag
//   registered output (latency >= 1)  | combinational output off FIFO state
//                                     | (can present a beat the same cycle)
//   tlast tracked as a beat attribute | tlast tracked as a BYTE attribute
//
// If the checker encodes upstream's beat-level pipelining anywhere, this design
// fails it. That is the whole point.
// =============================================================================

`timescale 1ns/1ps

module axis_width_adapter #(
    parameter int S_BYTES = 1,
    parameter int M_BYTES = 4,
    parameter int USER_W  = 1
) (
    input  logic                    clk,
    input  logic                    rst_n,

    input  logic                    s_valid,
    output logic                    s_ready,
    input  logic [S_BYTES*8-1:0]    s_data,
    input  logic [S_BYTES-1:0]      s_keep,
    input  logic                    s_last,
    input  logic [USER_W-1:0]       s_user,

    output logic                    m_valid,
    input  logic                    m_ready,
    output logic [M_BYTES*8-1:0]    m_data,
    output logic [M_BYTES-1:0]      m_keep,
    output logic                    m_last,
    output logic [USER_W-1:0]       m_user
);

    localparam int DEPTH = 32;                 // > 2*(max S + max M)
    localparam int CW    = $clog2(DEPTH+1);

    // Unpacked, memory-style storage -- a packed 2D array here would infer
    // flip-flops and blow up the instance count at synthesis.
    logic [7:0]        fb   [0:DEPTH-1];       // byte
    logic              fl   [0:DEPTH-1];       // this byte ends a packet
    logic [USER_W-1:0] fu   [0:DEPTH-1];       // tuser, meaningful when fl

    logic [CW-1:0] rptr, wptr, cnt;

    // ---- how many input bytes are live this beat -------------------------
    int unsigned s_live;
    always_comb begin
        s_live = 0;
        for (int i = 0; i < S_BYTES; i++) if (s_keep[i]) s_live++;
    end

    // s_ready depends on occupancy only, never on s_valid (spec H1).
    assign s_ready = (cnt + CW'(S_BYTES) <= CW'(DEPTH));

    // ---- output window ----------------------------------------------------
    // Emit up to M_BYTES bytes, stopping early at (and including) a byte tagged
    // end-of-packet. Because the tag lives on the BYTE, the same expression
    // handles upsizing, downsizing and pass-through with no case split.
    int unsigned win, emit_n;
    logic        win_last;
    always_comb begin
        win      = (cnt > CW'(M_BYTES)) ? M_BYTES : int'(cnt);
        win_last = 1'b0;
        emit_n   = 0;
        for (int i = 0; i < M_BYTES; i++) begin
            if (!win_last && i < win) begin
                emit_n = i + 1;
                if (fl[(rptr + CW'(i)) % CW'(DEPTH)]) win_last = 1'b1;
            end
        end
        // Without a packet tail in the window we must wait for a full beat.
        if (!win_last && win < M_BYTES) emit_n = 0;
    end

    assign m_valid = (emit_n != 0);
    assign m_last  = win_last;
    assign m_user  = fu[(rptr + CW'(emit_n == 0 ? 0 : emit_n - 1)) % CW'(DEPTH)];

    always_comb begin
        m_data = '0;
        m_keep = '0;
        for (int i = 0; i < M_BYTES; i++)
            if (i < emit_n) begin
                m_data[i*8 +: 8] = fb[(rptr + CW'(i)) % CW'(DEPTH)];
                m_keep[i]        = 1'b1;
            end
    end

    // ---- state ------------------------------------------------------------
    logic [CW-1:0] wr_n, rd_n;
    always_comb begin
        wr_n = (s_valid && s_ready) ? CW'(s_live) : '0;
        rd_n = (m_valid && m_ready) ? CW'(emit_n) : '0;
    end

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            rptr <= '0;
            wptr <= '0;
            cnt  <= '0;
        end else begin
            if (s_valid && s_ready) begin
                int unsigned k;
                k = 0;
                for (int i = 0; i < S_BYTES; i++) begin
                    if (s_keep[i]) begin
                        fb[(wptr + CW'(k)) % CW'(DEPTH)] <= s_data[i*8 +: 8];
                        fl[(wptr + CW'(k)) % CW'(DEPTH)] <= s_last && (CW'(k) == CW'(s_live) - 1);
                        fu[(wptr + CW'(k)) % CW'(DEPTH)] <= s_user;
                        k++;
                    end
                end
                wptr <= (wptr + wr_n) % CW'(DEPTH);
            end
            if (m_valid && m_ready)
                rptr <= (rptr + rd_n) % CW'(DEPTH);
            cnt <= cnt + wr_n - rd_n;
        end
    end

endmodule
