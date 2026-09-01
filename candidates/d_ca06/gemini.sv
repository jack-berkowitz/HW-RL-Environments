// =============================================================================
// d_ca06 -- CONCURRENT MULTI-PORT QUEUE
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

    localparam int DEPTH = 1 << PTR_WIDTH;

    // The storage array.
    T mem [0 : DEPTH-1];

    // Core pointers and state.
    logic [PTR_WIDTH-1:0] head;
    logic [PTR_WIDTH-1:0] tail;
    logic                 is_full;

    // Derived states: occupancy and vacancy.
    logic [PTR_WIDTH-1:0] diff_occ;
    logic [PTR_WIDTH-1:0] diff_vac;
    logic [PTR_WIDTH:0]   occupancy;
    logic [PTR_WIDTH:0]   vacancy;

    assign diff_occ = tail - head;
    assign diff_vac = head - tail;

    always_comb begin
        if (head == tail) begin
            occupancy = is_full ? DEPTH : '0;
            vacancy   = is_full ? '0 : DEPTH;
        end else begin
            // Relies on unsigned wraparound of the subtraction to give the correct modulo arithmetic.
            occupancy = {1'b0, diff_occ};
            vacancy   = {1'b0, diff_vac};
        end
    end

    // Combinational evaluation of operations.
    logic [31:0]      num_writes;
    logic [31:0]      num_reads;
    logic [31:0]      write_offset [PORTS];
    logic [PORTS-1:0] write_enable;

    always_comb begin
        // Write logic: accepted based purely on space; addresses compacted consecutively.
        num_writes = 0;
        for (int i = 0; i < PORTS; i++) begin
            write_accept[i] = (i < vacancy);
            write_enable[i] = write_valid[i] && write_accept[i];
            write_offset[i] = num_writes;
            
            if (write_enable[i]) begin
                num_writes = num_writes + 1;
            end
        end

        // Read logic: head advances to one past the highest-numbered accepted valid read.
        num_reads = 0;
        for (int i = 0; i < PORTS; i++) begin
            read_valid[i] = (i < occupancy);
            if (read_accept[i] && read_valid[i]) begin
                num_reads = i + 1;
            end
        end
    end

    // Addressing for data access.
    logic [PTR_WIDTH-1:0] read_addr  [PORTS];
    logic [PTR_WIDTH-1:0] write_addr [PORTS];

    always_comb begin
        for (int i = 0; i < PORTS; i++) begin
            read_addr[i]  = (head + i) & (DEPTH - 1);
            read_data[i]  = mem[read_addr[i]];
            
            write_addr[i] = (tail + write_offset[i]) & (DEPTH - 1);
        end
    end

    // Synchronous state updates.
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            head    <= '0;
            tail    <= '0;
            is_full <= 1'b0;
            for (int i = 0; i < DEPTH; i++) begin
                mem[i] <= '0;
            end
        end else begin
            head <= (head + num_reads) & (DEPTH - 1);
            tail <= (tail + num_writes) & (DEPTH - 1);

            // Fullness tracks the direction of the last operation that changed occupancy.
            if (num_writes > num_reads) begin
                is_full <= 1'b1;
            end else if (num_writes < num_reads) begin
                is_full <= 1'b0;
            end

            // Process accepted writes.
            for (int i = 0; i < PORTS; i++) begin
                if (write_enable[i]) begin
                    mem[write_addr[i]] <= write_data[i];
                end
            end
        end
    end

endmodule