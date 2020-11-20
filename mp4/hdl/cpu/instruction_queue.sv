// ECE411 Final Project: OOPs
// Caleb Gerth cdgerth2
// Dillon Hammond dillonh2
// Jonathan Paulson paulson5

import rv32i_types::*;
import oops_structs::*;

module instruction_queue
#(
    WIDTH = $bits(instruction_element_t),
    DEPTH = 15
)
(
    input                           clk,
    input                           rst,
    input                           flush,

    input  logic [ROB_IDX_LEN-1:0]  rob_dest_i,

    input  reg_bus_t                reg_bus_i,

    input  logic                    vld_i,
    output logic                    rdy_i,
    input  instruction_element_t    instruction_i,

    output logic                    vld_o,
    input  logic                    rdy_o,
    output instruction_element_t    instruction_o
);

instruction_element_t temp_instruction;

queue
#(
    .WIDTH (WIDTH),
    .DEPTH (DEPTH)
)
iq
(
    .clk    (clk),
    .rst    (rst | flush),
    .vld_i  (vld_i),
    .rdy_i  (rdy_i),
    .data_i (instruction_i),
    .vld_o  (vld_o),
    .rdy_o  (rdy_o),
    .data_o (temp_instruction)
); 

always_comb begin
    instruction_o = temp_instruction;

    instruction_o.ROB_dest = rob_dest_i;

    if(temp_instruction.CB1 == 1'b1) begin
        automatic reg_bus_lane_t e = reg_bus_i.reg_data[temp_instruction.val1[4:0]];
        instruction_o.val1[31:0] = e.data[31:0];
        instruction_o.CB1 = e.CB;
    end

    if(temp_instruction.CB2 == 1'b1) begin
        automatic reg_bus_lane_t e = reg_bus_i.reg_data[temp_instruction.val2[4:0]];
        instruction_o.val2[31:0] = e.data[31:0];
        instruction_o.CB2 = e.CB;
    end
end

endmodule : instruction_queue
