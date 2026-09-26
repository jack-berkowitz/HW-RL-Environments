module queue #(
    parameter int DW = 64,
    parameter type T = logic [DW-1:0],
    parameter int PTR_WIDTH = 7,
    parameter int PORTS = 3
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
    localparam int DEPTH = 1 << PTR_WIDTH;
    localparam int STEP_WIDTH = $clog2(PORTS + 1);
    typedef logic [PTR_WIDTH-1:0] ptr_t;
    typedef logic [PTR_WIDTH:0] count_t;
    typedef logic [STEP_WIDTH-1:0] step_t;

    T storage [0:DEPTH-1];
    ptr_t head, tail;
    logic last_was_write;
    ptr_t distance;
    count_t occupancy, vacancy;
    step_t write_count, read_advance;
    step_t prefix [0:PORTS];
    ptr_t write_address [0:PORTS-1];
    logic [PORTS-1:0] write_enable;

    // Pointers remain PTR_WIDTH bits. The extra count bit represents DEPTH,
    // not a pointer wrap bit; equality is resolved by the direction flag.
    assign distance = tail - head;
    assign occupancy = (tail == head)
                     ? (last_was_write ? count_t'(DEPTH) : '0)
                     : {1'b0, distance};
    assign vacancy = count_t'(DEPTH) - occupancy;
    assign prefix[0] = '0;
    assign write_count = prefix[PORTS];

    for (genvar p = 0; p < PORTS; p++) begin : ports
        // Acceptance depends on the port index, even if lower ports are idle.
        assign write_accept[p] = (p < int'(vacancy));
        assign read_valid[p] = (p < int'(occupancy));
        assign write_enable[p] = write_valid[p] & write_accept[p];
        assign prefix[p+1] = prefix[p] + step_t'(write_enable[p]);
        assign write_address[p] = tail + ptr_t'(prefix[p]);
        assign read_data[p] = storage[ptr_t'(head + ptr_t'(p))];
    end

    // Highest accepted read consumes its entire prefix, including holes.
    always_comb begin
        read_advance = '0;
        for (int p = 0; p < PORTS; p++) begin
            if (read_valid[p] && read_accept[p])
                read_advance = step_t'(p + 1);
        end
    end

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            head <= '0;
            tail <= '0;
            last_was_write <= 1'b0;
        end else begin
            head <= head + ptr_t'(read_advance);
            tail <= tail + ptr_t'(write_count);
            if (write_count != read_advance)
                last_was_write <= (write_count > read_advance);
        end
    end

    // Explicit, synchronously cleared register array. Compacted writes have
    // distinct addresses, so no two enabled ports target the same entry.
    for (genvar s = 0; s < DEPTH; s++) begin : entries
        always_ff @(posedge clk) begin
            if (!rst_n) begin
                storage[s] <= '0;
            end else begin
                for (int p = 0; p < PORTS; p++) begin
                    if (write_enable[p] && write_address[p] == ptr_t'(s))
                        storage[s] <= write_data[p];
                end
            end
        end
    end
endmodule
