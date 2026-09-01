module softmax #(
    parameter int unsigned          DATALENGTH  = 32,
    parameter int unsigned          INPUTMAX    = 4,
    parameter int unsigned          COUNT       = 8
) (
    input   logic                           clk,
    input   logic                           rst_n,

    input   logic                                       start,
    input   logic   [INPUTMAX-1:0][DATALENGTH-1:0]      data_in,
    input   logic   [INPUTMAX-1:0]                      data_valid,
    output  logic   [INPUTMAX-1:0]                      data_ready,

    output  logic   [DATALENGTH-1:0]        Dataout
);

    typedef enum logic [1:0] {IDLE, ACC, DONE} ACCSTATETYPE;
    ACCSTATETYPE acc_ns, acc_cs;
    logic [$clog2(COUNT)-1:0] acc_cnt_reg, acc_cnt;

    logic   [INPUTMAX-1:0][DATALENGTH-1:0]  exp_data_out;
    logic   [INPUTMAX-1:0]                  exp_data_out_vld;                  

    genvar exp_units;
    generate
        for (exp_units = 0; exp_units < INPUTMAX; exp_units++) begin
            exp_unit exp_unit_child (
                .clk        (clk),
                .rst_n      (rst_n),
                .din        (data_in[i]),
                .in_vld     (data_valid[i]),
                .in_rdy     (data_ready[i]),
                .dout       (exp_data_out[i]),
                .out_vld    (exp_data_out_vld[i]),
                .out_acpt   (exp_data_out_rdy[i])
            );
        end
    endgenerate


    always_comb begin
        case (add_cs) 
            IDLE: begin
                add_a <= 
            end
        endcase
    end

    always

    always_ff @(posedge clk) begin
        case (add_cs)
            IDLE: begin
                add_z_reg <= '0;
                if (queue_to_exp_vld[0] && queue_to_exp_vld[1]) begin
                    add_ns <= FIRST;
                    acc_cnt_reg <= 2;
                end
            end
            ACC: begin
                if (acc_cnt_reg == COUNT-1) begin
                    add_ns <= DONE;
                end else begin
                    add_ns <= ACC;
                    acc_cnt_reg <= (add_b_vld && add_b_ack)? acc_cnt_reg + 1: acc_cnt_reg;
                    add_z_reg <= (add_z_vld)? add_z : add_z_reg;
                end
            end
            DONE: begin
                if (add_z_vld) begin
                    total_sum <= add_z;
                end
            end
        endcase
    end

    adder sum_adder (
        .clk          (clk),
        .rst_n        (rst_n),
        .input_a      (add_a),
        .input_a_vld  (add_a_vld),
        .input_a_ack  (add_a_ack),
        .input_b      (add_b),
        .input_b_vld  (add_b_vld),
        .input_b_ack  (add_b_ack),
        .output_z     (add_z),
        .output_z_vld (add_z_vld),
        .output_z_ack (add_z_ack)
    );

    always_comb begin
        case(cs)
            IDLE: begin

            end
            GATHER: begin

            end
            EXP: begin

            end
            ADD: begin

            end
            DIV: begin

            end
            PUSH: begin

            end
            default: 
        endcase
    end

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            Dataout <= '0;
        end else begin

        end
    end


endmodule

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
            if (write_valid[i] && write_accept[i]) begin
                mem_next[write_ptrs[i]] = write_data[i];
                write_ptrs[i+1] = write_ptrs[i] + PTR'(1);
            end else begin
                write_ptrs[i+1] = write_ptrs[i];
            end
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