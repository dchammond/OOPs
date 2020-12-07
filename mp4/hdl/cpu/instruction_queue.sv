// ECE411 Final Project: OOPs
// Caleb Gerth cdgerth2
// Dillon Hammond dillonh2
// Jonathan Paulson paulson5

import rv32i_types::*;
import oops_structs::*;

module instruction_queue
#(
    ISSUE_WIDTH = 1,
    WIDTH = $bits(instruction_element_t),
    DEPTH = 15
)
(
    input                              clk,
    input                              rst,
    input                              flush,

    input  logic [ROB_IDX_LEN-1:0]     rob_dest_i,

    input  rob_element_t [ROB_ENTRIES-1:0] rob_bus_i,
    input  reg_bus_t                   reg_bus_i,
    input  common_data_bus_t           common_data_bus_i,

    input  logic                       vld_i,
    output logic                       rdy_i,
    input  instruction_element_t       instruction_i,

    output logic                       vld_o,
    input  logic                       rdy_o,
    output instruction_element_t       instruction_o
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
        // If necessary, override reg bus with forwarded ROB Data
        if(instruction_o.CB1) begin
            if(rob_bus_i[instruction_o.val1[ROB_IDX_LEN-1:0]].rdy) begin
                instruction_o.val1[31:0] = rob_bus_i[instruction_o.val1[ROB_IDX_LEN-1:0]].val;
                instruction_o.CB1        = 1'b0;
            end
        end
        // If necessary, override reg bus and forwarded commit with CDB
        if(instruction_o.CB1) begin
            for(int i = 0; i < NUM_CDB_INPUTS; i++) begin
                if(common_data_bus_i.data_lanes[i].valid) begin
                    if(common_data_bus_i.data_lanes[i].ROB_dest == reg_bus_i.reg_data[temp_instruction.val1[4:0]].data) begin
                        instruction_o.val1[31:0] = common_data_bus_i.data_lanes[i].data[31:0];
                        instruction_o.CB1        = 1'b0;
                    end
                end
            end
        end
    end

    if(temp_instruction.CB2 == 1'b1) begin
        automatic reg_bus_lane_t e = reg_bus_i.reg_data[temp_instruction.val2[4:0]];
        instruction_o.val2[31:0] = e.data[31:0];
        instruction_o.CB2 = e.CB;
        // If necessary, override reg bus with forwarded commit data
        if(instruction_o.CB2) begin
            if(rob_bus_i[instruction_o.val2[ROB_IDX_LEN-1:0]].rdy) begin
                instruction_o.val2[31:0] = rob_bus_i[instruction_o.val2[ROB_IDX_LEN-1:0]].val;
                instruction_o.CB2        = 1'b0;
            end
        end
        // If necessary, override reg bus and forwarded commit with CDB
        if(instruction_o.CB2) begin
            for(int i = 0; i < NUM_CDB_INPUTS; i++) begin
                if(common_data_bus_i.data_lanes[i].valid) begin
                    if(common_data_bus_i.data_lanes[i].ROB_dest == reg_bus_i.reg_data[temp_instruction.val2[4:0]].data) begin
                        instruction_o.val2[31:0] = common_data_bus_i.data_lanes[i].data[31:0];
                        instruction_o.CB2        = 1'b0;
                    end
                end
            end
        end
    end
end

endmodule : instruction_queue
