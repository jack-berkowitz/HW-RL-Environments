module axis_width_adapter #(
    parameter int S_BYTES = 1,      // 1 / 2 / 4 / 8
    parameter int M_BYTES = 4,      // 1 / 2 / 4 / 8
    parameter int USER_W  = 1       // 1..8
) (
    input  logic                    clk,
    input  logic                    rst_n,

    // input stream
    input  logic                    s_valid,
    output logic                    s_ready,
    input  logic [S_BYTES*8-1:0]    s_data,
    input  logic [S_BYTES-1:0]      s_keep,
    input  logic                    s_last,
    input  logic [USER_W-1:0]       s_user,

    // output stream
    output logic                    m_valid,
    input  logic                    m_ready,
    output logic [M_BYTES*8-1:0]    m_data,
    output logic [M_BYTES-1:0]      m_keep,
    output logic                    m_last,
    output logic [USER_W-1:0]       m_user
);

    // At most one input-width beat must be buffered when downsizing,
    // and at most one output-width beat must be accumulated when upsizing.
    localparam int BUF_BYTES =
        (S_BYTES > M_BYTES) ? S_BYTES : M_BYTES;

    localparam int COUNT_W = $clog2(BUF_BYTES + 1);

    logic [BUF_BYTES*8-1:0] byte_buf;
    logic [COUNT_W-1:0]     byte_count;

    // Set once the input packet's s_last beat has been accepted.
    // While set, no beat from the following packet may be accepted.
    logic                    packet_ended;
    logic [USER_W-1:0]       packet_user;

    // Reset-release holdoff required by R1.
    logic active;

    // Number of live bytes in the current input beat.
    logic [COUNT_W-1:0] input_nbytes;

    integer i;

    // -------------------------------------------------------------------------
    // Count s_keep bits.
    //
    // P1 guarantees they are contiguous from bit zero, so the live bytes are
    // exactly s_data byte lanes [0 .. input_nbytes-1].
    // -------------------------------------------------------------------------
    always_comb begin
        input_nbytes = '0;

        for (i = 0; i < S_BYTES; i = i + 1)
            input_nbytes = input_nbytes + s_keep[i];
    end


    // -------------------------------------------------------------------------
    // Output availability
    //
    // Emit when:
    //   * at least one complete M_BYTES output beat is buffered, or
    //   * the packet has ended, in which case any remaining bytes must be
    //     flushed as the final partial beat.
    // -------------------------------------------------------------------------
    always_comb begin
        m_valid = 1'b0;
        m_data  = byte_buf[M_BYTES*8-1:0];
        m_keep  = '0;
        m_last  = 1'b0;
        m_user  = packet_user;

        if (active) begin
            if ((byte_count >= M_BYTES) ||
                (packet_ended && (byte_count != 0))) begin
                m_valid = 1'b1;
            end
        end

        // Live bytes always occupy the lowest lanes of byte_buf.
        for (i = 0; i < M_BYTES; i = i + 1) begin
            if (i < byte_count)
                m_keep[i] = 1'b1;
        end

        // packet_ended means no bytes belonging to a later packet can be in
        // the buffer. Therefore this is the last output beat exactly when all
        // remaining packet bytes fit in the current beat.
        if (m_valid &&
            packet_ended &&
            (byte_count <= M_BYTES)) begin
            m_last = 1'b1;
        end
    end


    // -------------------------------------------------------------------------
    // Input ready
    //
    // Intentionally conservative:
    //
    // Do not accept an input beat while an output beat is available.
    //
    // This means enqueue and dequeue never occur on the same clock edge,
    // greatly simplifying buffer accounting. Throughput is lower than an
    // optimized elastic implementation, but the specification explicitly
    // permits this.
    //
    // s_ready has NO combinational dependence on s_valid, satisfying H1.
    // -------------------------------------------------------------------------
    always_comb begin
        s_ready = active &&
                  !packet_ended &&
                  !m_valid;
    end


    // -------------------------------------------------------------------------
    // Buffer / packet state
    // -------------------------------------------------------------------------
    always_ff @(posedge clk) begin : adapter_state
        integer b;

        if (!rst_n) begin
            active       <= 1'b0;
            byte_buf     <= '0;
            byte_count   <= '0;
            packet_ended <= 1'b0;
            packet_user  <= '0;
        end
        else if (!active) begin
            // First cycle after reset release.
            //
            // Keep all previous in-flight state discarded and ensure there
            // can be no output in this cycle.
            active       <= 1'b1;
            byte_buf     <= '0;
            byte_count   <= '0;
            packet_ended <= 1'b0;
            packet_user  <= '0;
        end
        else begin

            // -----------------------------------------------------------------
            // OUTPUT TRANSFER
            //
            // s_ready is false whenever m_valid is true, so this cannot occur
            // simultaneously with an input transfer.
            // -----------------------------------------------------------------
            if (m_valid && m_ready) begin

                if (m_last) begin
                    // Entire packet has now left the adapter.
                    byte_buf     <= '0;
                    byte_count   <= '0;
                    packet_ended <= 1'b0;
                end
                else begin
                    // Remove the lowest M_BYTES from the byte stream.
                    //
                    // The next byte becomes lane zero.
                    byte_buf   <= byte_buf >> (M_BYTES * 8);
                    byte_count <= byte_count - M_BYTES;
                end
            end

            // -----------------------------------------------------------------
            // INPUT TRANSFER
            // -----------------------------------------------------------------
            else if (s_valid && s_ready) begin

                // Append all enabled input bytes to the current byte stream.
                //
                // P1 guarantees keep is contiguous starting at zero, so byte
                // lane b belongs at position byte_count+b.
                for (b = 0; b < S_BYTES; b = b + 1) begin
                    if (s_keep[b]) begin
                        byte_buf[(byte_count + b)*8 +: 8]
                            <= s_data[b*8 +: 8];
                    end
                end

                byte_count <= byte_count + input_nbytes;

                // Once the packet-ending input beat is accepted, stop
                // accepting input until all of this packet has been emitted.
                // This prevents bytes from adjacent packets ever coexisting
                // in the buffer.
                if (s_last) begin
                    packet_ended <= 1'b1;
                    packet_user  <= s_user;
                end
            end
        end
    end

endmodule