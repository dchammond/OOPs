// ECE411 Final Project: OOPs
// Caleb Gerth cdgerth2
// Dillon Hammond dillonh2
// Jonathan Paulson paulson5

import rv32i_types::*;
import oops_structs::*;

module register_file
#(
    ISSUE_WIDTH = 1,
    ROB_IDX_LEN = 4
)
(
    input                                       clk,
    input                                       rst,
    
    input logic                                 fls,

    input logic [ISSUE_WIDTH-1:0]               commit_i, // Which lanes are committing.
    input logic [ISSUE_WIDTH-1:0]               speculate_i, // Which lanes are speculating.

    input logic [ 4:0]        commit_idx_i [ISSUE_WIDTH], // which register to write to
    input logic [ROB_IDX_LEN-1:0] commit_rob_idx_i [ISSUE_WIDTH],
    input logic [ 4:0]        speculate_idx_i [ISSUE_WIDTH], // which register to write to

    input logic [31:0]        commit_data_i [ISSUE_WIDTH], // What to put in that register (either ROB reference or actual val depending on commit_i or speculate_i)
    input logic [ROB_IDX_LEN-1:0] speculate_data_i [ISSUE_WIDTH], // What to put in that register (either ROB reference or actual val depending on commit_i or speculate_i)
    
    output reg_bus_t                            reg_bus_o // Always outputting the entire reg_bus
);

reg_file_element_t [31:0] reg_file_d;
reg_file_element_t [31:0] reg_file_q;

always_comb begin : register_updates
    reg_file_d = reg_file_q;

    for (int i = 0; i < ISSUE_WIDTH; i = i + 1) begin
        if (commit_i[i] == 1'b1 && commit_idx_i[i] != '0) begin
            reg_file_d[commit_idx_i[i]].data = commit_data_i[i];
            if (commit_rob_idx_i[i] == reg_file_q[commit_idx_i[i]].ROB_ref) begin
                reg_file_d[commit_idx_i[i]].CB = 1'b0;
            end
        end
    end
    for (int i = 0; i < ISSUE_WIDTH; i = i + 1) begin 
        if (speculate_i[i] == 1'b1 && speculate_idx_i[i] != '0) begin
            reg_file_d[speculate_idx_i[i]].ROB_ref  = speculate_data_i[i];
            reg_file_d[speculate_idx_i[i]].CB       = 1'b1;
        end
    end

    if (fls) begin
        for (int i = 0; i < 32; i++) begin
            reg_file_d[i].CB = 1'b0;
        end
    end
end : register_updates

always_comb begin : connect_to_bus
    for (int i = 0; i < 32; i++) begin
        reg_bus_o.reg_data[i].CB   = reg_file_q[i].CB;
        reg_bus_o.reg_data[i].data = reg_file_q[i].CB ? reg_file_q[i].ROB_ref : reg_file_q[i].data;
    end
end :connect_to_bus

always_ff @(posedge clk) begin
    reg_file_q <= reg_file_d;
    if (rst) begin
            reg_file_q <= '0;
    end
end


endmodule : register_file
