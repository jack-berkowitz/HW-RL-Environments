module trivial_test (
    input  logic clk,
    input  logic a,
    input  logic b,
    output logic q
);
    logic and_out;
    assign and_out = a & b;

    always_ff @(posedge clk) begin
        q <= and_out;
    end
endmodule
