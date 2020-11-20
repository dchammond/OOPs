// ECE411 Final Project: OOPs
// Caleb Gerth cdgerth2
// Dillon Hammond dillonh2
// Jonathan Paulson paulson5

module pipeline
#(
    DATA_WIDTH = 32,
    DEPTH      = 1
)
(
    input                         clk,
    input                         rst,

    input  logic [DATA_WIDTH-1:0] data_i,

    output logic [DATA_WIDTH-1:0] data_o
);

generate
if(DEPTH == 0) begin
    assign data_o = data_i;
end else begin
    logic [DATA_WIDTH-1:0] data_q [DEPTH];

    assign data_o = data_q[DEPTH-1];

    always_ff @(posedge clk) begin
        data_q[0] <= data_i;
        for(int i = 1; i < DEPTH; i++) begin
            data_q[i] <= data_q[i-1];
        end
        if(rst) begin
            for(int i = 0; i < DEPTH; i++) begin
                data_q[i] <= '0;
            end
        end
    end
end
endgenerate

endmodule : pipeline
