module queue #(
    parameter int  DW         = 64,
    parameter type T          = logic [DW-1:0],
    parameter int  PTR_WIDTH  = 7,
    parameter int  PORTS      = 3
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

    localparam int DEPTH   = 1 << PTR_WIDTH;
    localparam int COUNT_W = (PORTS < 2) ? 1 : $clog2(PORTS + 1);

    // -------------------------------------------------------------------------
    // Storage
    // -------------------------------------------------------------------------
    T storage [0:DEPTH-1];

    // PTR_WIDTH-bit pointers intentionally wrap naturally at DEPTH.
    logic [PTR_WIDTH-1:0] head;
    logic [PTR_WIDTH-1:0] tail;

    // head == tail means either empty or full.  full_q distinguishes the two.
    logic full_q;

    // -------------------------------------------------------------------------
    // Derived queue state
    // -------------------------------------------------------------------------
    logic [PTR_WIDTH-1:0] ptr_delta;
    logic [PTR_WIDTH:0]   occupancy;
    logic [PTR_WIDTH:0]   vacancy;

    // Number of actual accepted writes this cycle.
    logic [COUNT_W-1:0] write_count;

    // Number of queue positions destroyed by reads this cycle.
    //
    // This is NOT popcount(read_accept & read_valid).  It is one plus the
    // highest-numbered accepted valid read port.
    logic [COUNT_W-1:0] read_advance;

    logic [PTR_WIDTH-1:0] write_addr [PORTS-1:0];
    logic [PTR_WIDTH-1:0] read_addr  [PORTS-1:0];

    integer ci;
    integer si;

    // -------------------------------------------------------------------------
    // Combinational interface/state derivation
    // -------------------------------------------------------------------------
    always_comb begin
        // tail-head in PTR_WIDTH bits gives the modulo-DEPTH distance.
        ptr_delta = tail - head;

        if (tail == head) begin
            if (full_q)
                occupancy = DEPTH;
            else
                occupancy = '0;
        end else begin
            occupancy = {1'b0, ptr_delta};
        end

        vacancy = DEPTH - occupancy;

        write_accept = '0;
        read_valid    = '0;
        write_count   = '0;
        read_advance  = '0;

        for (ci = 0; ci < PORTS; ci = ci + 1) begin
            // -------------------------------------------------------------
            // Write acceptance depends ONLY on vacancy.
            //
            // Port ci needs at least ci+1 vacancies, regardless of whether
            // any lower-numbered ports are valid.
            // -------------------------------------------------------------
            write_accept[ci] = (ci < vacancy);

            // -------------------------------------------------------------
            // Read ports expose consecutive positions from head.
            // -------------------------------------------------------------
            read_valid[ci] = (ci < occupancy);

            read_addr[ci] = head + ci;
            read_data[ci] = storage[read_addr[ci]];

            // -------------------------------------------------------------
            // Writes compact.
            //
            // write_count is a running prefix count here.  Therefore each
            // accepted valid write is placed immediately after all lower-
            // numbered accepted valid writes.
            // -------------------------------------------------------------
            write_addr[ci] = tail + write_count;

            if (write_valid[ci] && write_accept[ci])
                write_count = write_count + 1'b1;

            // -------------------------------------------------------------
            // Reads DO NOT compact.
            //
            // Overwriting read_advance while scanning upward leaves it equal
            // to one plus the highest accepted, valid read port.
            // -------------------------------------------------------------
            if (read_accept[ci] && read_valid[ci])
                read_advance = ci + 1;
        end
    end

    // -------------------------------------------------------------------------
    // Sequential state
    // -------------------------------------------------------------------------
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            head   <= '0;
            tail   <= '0;
            full_q <= 1'b0;

            for (si = 0; si < DEPTH; si = si + 1)
                storage[si] <= '0;

        end else begin
            // Accepted writes are committed in ascending port order into
            // their compacted addresses.
            for (si = 0; si < PORTS; si = si + 1) begin
                if (write_valid[si] && write_accept[si])
                    storage[write_addr[si]] <= write_data[si];
            end

            // Natural truncation implements modulo-DEPTH pointer arithmetic.
            head <= head + read_advance;
            tail <= tail + write_count;

            // The full/empty discriminator changes only when occupancy changes.
            // Equal movement preserves its previous value.
            if (write_count > read_advance)
                full_q <= 1'b1;
            else if (write_count < read_advance)
                full_q <= 1'b0;
        end
    end

endmodule