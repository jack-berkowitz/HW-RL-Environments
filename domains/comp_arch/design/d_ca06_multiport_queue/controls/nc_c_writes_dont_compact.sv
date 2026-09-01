
module queue #(
    parameter type T         = logic[63:0],
    parameter int  PTR_WIDTH = 7,
    parameter type PTR       = logic[PTR_WIDTH-1:0],
    parameter int  CNT_WIDTH = PTR_WIDTH + 1,
    parameter type CNT       = logic[CNT_WIDTH-1:0],
    parameter int  DEPTH     = 1 << PTR_WIDTH,
    parameter int  PORTS     = 3,
    parameter type PORT_CNT  = logic[$clog2(PORTS+1)-1:0]
) (
    input logic clk,
    input logic rst_n,
    
    input  T     [PORTS-1:0] write_data,
    input  logic [PORTS-1:0] write_valid,
    output logic [PORTS-1:0] write_accept,

    output T     [PORTS-1:0] read_data,
    output logic [PORTS-1:0] read_valid,
    input  logic [PORTS-1:0] read_accept
);

    T [DEPTH-1:0] mem, mem_next;
    PTR head, head_next;  // head = read side
    PTR tail, tail_next;  // tail = write side
    CNT occupancy, vacancy;
    logic last_op_write, last_op_write_next;
    PTR [PORTS:0] read_ptrs, write_ptrs;


    assign occupancy = (tail == head)? (last_op_write? CNT'(DEPTH) : CNT'('0)) : CNT'(PTR'(tail - head));
    assign vacancy = CNT'(DEPTH) - occupancy;

    PORT_CNT write_count, read_count;

    // Reading + writing logic
    always_comb begin
        write_count = '0;
        read_count = '0;
        for (int i = 0; i < PORTS; i++) begin
            write_accept[i] = CNT'(i) < vacancy;
            if (write_valid[i] && write_accept[i]) begin
                write_count = write_count + PORT_CNT'(1);
            end

            read_valid[i] = CNT'(i) < occupancy;
            if (read_valid[i] && read_accept[i]) begin
                read_count = read_count + PORT_CNT'(1);
            end

            read_data[i] = mem[head + PTR'(i)]; 
        end
    end

    always_comb begin
        mem_next = mem;
        head_next = head;

        write_ptrs[0] = tail;
        for (int i = 0; i < PORTS; i++) begin
            // NEGATIVE CONTROL nc_c: writes land at tail+i rather than compacting,
            // so an idle low port leaves a gap. Violates F4.
            if (write_valid[i] && write_accept[i]) begin
                mem_next[tail + PTR'(i)] = write_data[i];
            end
            write_ptrs[i+1] = write_ptrs[i] + (write_valid[i] && write_accept[i] ? PTR'(1) : PTR'(0));
        end
        tail_next = write_ptrs[PORTS];

        read_ptrs[0] = head;
        for (int i = 0; i < PORTS; i++) begin
            read_ptrs[i+1] = read_ptrs[i] + PTR'(1);
            if (read_accept[i] && read_valid[i]) begin
                head_next = read_ptrs[i+1];
            end 
        end

        last_op_write_next = write_count == read_count ? last_op_write : write_count > read_count;
    end

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            mem <= '0;
            head <= '0;
            tail <= '0;
            last_op_write <= 1'b0;
        end else begin
            mem <= mem_next;
            head <= head_next;
            tail <= tail_next;
            last_op_write <= last_op_write_next;
        end
    end

endmodule