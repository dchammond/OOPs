// ECE411 Final Project: OOPs
// Caleb Gerth cdgerth2
// Dillon Hammond dillonh2
// Jonathan Paulson paulson5

import rv32i_types::*;
import oops_structs::*;

module program_counter
#(
    WIDTH = 32
)
(
    input                       clk,
    input                       rst,

    input logic                 load_plus_four_i,

    input logic                 load_offset_i,
    input logic [WIDTH-1:0]     offset_i,

    input logic                 load_branch_i,
    input logic [WIDTH-1:0]     branch_pc_i,

    input logic                 load_alu_mod2_i,
    input logic [WIDTH-1:0]     jalr_alu_out_i,

    output logic [WIDTH-1:0]    out
);

/*
* PC needs to start at 0x60
 */
logic [WIDTH-1:0] data;

always_ff @(posedge clk)
begin
    if (rst) begin
        data <= 32'h00000060;
    end
    else if (load_branch_i) begin
        data <= branch_pc_i;
    end
    else if (load_offset_i) begin
        data <= data + offset_i;
    end
    else if (load_alu_mod2_i) begin
        data <= jalr_alu_out_i & 32'hFFFFFFFE;
    end
    else if (load_plus_four_i) begin
        data <= data + 32'h00000004;
    end
    else begin
        data <= data;
    end
end

always_comb
begin
    out = data;
end

endmodule : program_counter