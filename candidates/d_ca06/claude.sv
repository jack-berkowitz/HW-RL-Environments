// =============================================================================
// d_ca06 -- CONCURRENT MULTI-PORT QUEUE
//
// PORTS write ports and PORTS read ports, all active in the same cycle.
// Global ordering. Writes compact; reads do NOT (F6: head advances to one past
// the highest accepted+valid read port, discarding skipped entries).
// =============================================================================

module queue #(
    parameter int  DW        = 64,
    parameter type T         = logic [DW-1:0],
    parameter int  PTR_WIDTH = 7,
    parameter int  PORTS     = 3
) (
    input  logic             clk,
    input  logic             rst_n,

    input  T     [PORTS-1:0] write_data,
    input  logic [PORTS-1:0] write_valid,
    output logic [PORTS-1:0] write_accept,

    output T     [PORTS-1:0] read_data,
    output logic [PORTS-1:0] read_valid,
    input  logic [PORTS-1:0] read_accept
);

    // -------------------------------------------------------------------------
    // Derived geometry (P2: DEPTH entries of T, all registers, no second level)
    // -------------------------------------------------------------------------
    localparam int DEPTH  = 1 << PTR_WIDTH;   // array is exactly full at wrap
    localparam int CNT_W  = PTR_WIDTH + 1;    // holds 0 .. DEPTH inclusive
    localparam int PORT_W = $clog2(PORTS+1);  // holds 0 .. PORTS inclusive

    // -------------------------------------------------------------------------
    // State
    // -------------------------------------------------------------------------
    T                     mem [DEPTH-1:0];
    logic [PTR_WIDTH-1:0] head_q, tail_q;
    logic                 full_q;            // F2: disambiguates tail == head

    // -------------------------------------------------------------------------
    // F1/F2 -- occupancy and vacancy
    //
    // Pointers are exactly PTR_WIDTH wide, so the wrap-bit trick is unavailable;
    // the full/empty distinction is carried in full_q, which per F7 is only
    // touched on cycles where the write and read counts differ.
    // -------------------------------------------------------------------------
    logic [CNT_W-1:0] occupancy, vacancy;

    always_comb begin
        if (tail_q != head_q)
            occupancy = CNT_W'(tail_q - head_q);        // modulo DEPTH for free
        else
            occupancy = full_q ? CNT_W'(DEPTH) : CNT_W'(0);
    end

    assign vacancy = CNT_W'(DEPTH) - occupancy;

    // -------------------------------------------------------------------------
    // F3 -- write acceptance is a function of space alone.
    //       Independent of write_valid: empty queue advertises all ones.
    //       Port i needs i+1 free slots even if every lower port is idle.
    // F5 -- read validity, from occupancy as it stands before the edge (A1).
    // -------------------------------------------------------------------------
    always_comb begin
        for (int i = 0; i < PORTS; i++) begin
            write_accept[i] = (CNT_W'(i) < vacancy);
            read_valid[i]   = (CNT_W'(i) < occupancy);
        end
    end

    // -------------------------------------------------------------------------
    // F4 -- writes compact: prefix sum over the accepted-and-valid mask gives
    //       each port its slot offset from tail, with no gap for an idle port.
    // -------------------------------------------------------------------------
    logic [PORTS-1:0]     wr_en;
    logic [PORT_W-1:0]    wr_prefix [PORTS+1];   // wr_prefix[i] = offset of port i
    logic [PORT_W-1:0]    wr_count;
    logic [PTR_WIDTH-1:0] wr_addr   [PORTS];

    assign wr_en = write_valid & write_accept;

    always_comb begin
        wr_prefix[0] = PORT_W'(0);
        for (int i = 0; i < PORTS; i++)
            wr_prefix[i+1] = wr_prefix[i] + PORT_W'(wr_en[i]);
    end

    assign wr_count = wr_prefix[PORTS];

    always_comb begin
        for (int i = 0; i < PORTS; i++)
            wr_addr[i] = tail_q + PTR_WIDTH'(wr_prefix[i]);
    end

    // -------------------------------------------------------------------------
    // F5 -- read_data[i] is the entry i positions after head, combinational.
    // -------------------------------------------------------------------------
    always_comb begin
        for (int i = 0; i < PORTS; i++)
            read_data[i] = mem[head_q + PTR_WIDTH'(i)];
    end

    // -------------------------------------------------------------------------
    // F6 -- reads do NOT compact. head advances to one past the HIGHEST-numbered
    //       port that both asserted read_accept and had read_valid set; entries
    //       skipped below it are destroyed, silently and without a flag.
    //       The ascending loop leaves the highest match as the final write.
    // -------------------------------------------------------------------------
    logic [PORT_W-1:0] rd_count;

    always_comb begin
        rd_count = PORT_W'(0);
        for (int i = 0; i < PORTS; i++)
            if (read_accept[i] && read_valid[i])
                rd_count = PORT_W'(i + 1);
    end

    // -------------------------------------------------------------------------
    // V3 -- synchronous, active-low reset: pointers, flag and every entry.
    // A2 -- read-before-write ordering falls out of sampling mem before the edge.
    // F7 -- the fullness flag moves only when the two counts differ.
    // -------------------------------------------------------------------------
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            head_q <= '0;
            tail_q <= '0;
            full_q <= 1'b0;
            for (int i = 0; i < DEPTH; i++)
                mem[i] <= '0;
        end else begin
            for (int i = 0; i < PORTS; i++)
                if (wr_en[i])
                    mem[wr_addr[i]] <= write_data[i];

            tail_q <= tail_q + PTR_WIDTH'(wr_count);
            head_q <= head_q + PTR_WIDTH'(rd_count);

            if (wr_count != rd_count)
                full_q <= (wr_count > rd_count);
        end
    end

endmodule