// ECE411 Final Project: OOPs
// Caleb Gerth cdgerth2
// Dillon Hammond dillonh2
// Jonathan Paulson paulson5

import rv32i_types::*;
import oops_structs::*;

module cpu
#(
    CPU_ISSUE_WIDTH       = 1,
    CPU_IQ_DEPTH          = 15,
    CPU_ADDR_BUFFER_DEPTH = 15,
    CPU_ADDR_UNIT_DEPTH   = 15,
    CPU_RS_DEPTH          = 2,
    CPU_EXE_UNIT_COUNT    = 6,
    CPU_REG_EXE_UNIT_IN   = 0,
    CPU_REG_EXE_UNIT_OUT  = 0
)
(
    input                 clk,
    input                 rst,

    input  logic          inst_resp,
    input  logic [32-1:0] inst_rdata,
    output logic [32-1:0] inst_addr,
    output logic          inst_read,

    input  logic          data_resp,
    input  logic [32-1:0] data_rdata,
    output logic          data_read,
    output logic          data_write,
    output logic [ 4-1:0] data_mbe,
    output logic [32-1:0] data_addr,
    output logic [32-1:0] data_wdata
);

reg_bus_t reg_bus_o;
common_data_bus_t common_data_bus_o;

logic [CPU_ISSUE_WIDTH-1:0] rob_rdy_i;
logic [CPU_ISSUE_WIDTH-1:0] res_station_rdy_i;
logic [CPU_ISSUE_WIDTH-1:0] data_intr_rdy_i;

logic [32-1:0] pc;
logic [32-1:0] inst_address_o;
logic          load_branch_o;
logic [32-1:0] branch_pc_o;
logic [ROB_IDX_LEN-1:0] rob_dest_o;
logic [CPU_ISSUE_WIDTH-1:0] instr_queue_vld_o;
logic [CPU_ISSUE_WIDTH-1:0] instr_queue_vld_mem_o;
logic [CPU_ISSUE_WIDTH-1:0] instr_queue_vld_alu_o;
logic [CPU_ISSUE_WIDTH-1:0] instr_queue_rdy_o;
logic [CPU_ISSUE_WIDTH-1:0] rob_instr_vld_i;
instruction_element_t instr_queue_o [CPU_ISSUE_WIDTH];
logic [CPU_ISSUE_WIDTH-1:0] mem_inst;

assign inst_addr = {inst_address_o[2+:30], 2'b00};

assign instr_queue_rdy_o = rob_rdy_i & ((res_station_rdy_i & ~mem_inst) | (data_intr_rdy_i & mem_inst));
assign instr_queue_vld_mem_o = instr_queue_vld_o & mem_inst;
assign instr_queue_vld_alu_o = instr_queue_vld_o & ~mem_inst;
assign rob_instr_vld_i = instr_queue_vld_o & ((res_station_rdy_i & ~mem_inst) | (data_intr_rdy_i & mem_inst));

always_comb begin : determine_mem_inst
    for(int i = 0; i < CPU_ISSUE_WIDTH; i++) begin
        mem_inst[i] = instr_queue_o[i].instruction[5:3] == 3'b111;
    end
end

instruction_datapath
#(
    .IQ_DEPTH (CPU_IQ_DEPTH)
)
instr_dp
(
    .clk               (clk),
    .rst               (rst),
    .flush_i           (common_data_bus_o.fls),
    .pc_o              (pc),
    .mem_resp_i        (inst_resp),
    .mem_rdata_i       (inst_rdata),
    .mem_read_o        (inst_read),
    .mem_address_o     (inst_address_o),
    .load_branch_i     (load_branch_o),
    .branch_pc_i       (branch_pc_o),
    .rob_dest_i        (rob_dest_o),
    .reg_bus_i         (reg_bus_o),
    .instr_queue_vld_o (instr_queue_vld_o[0]), // TODO
    .instr_queue_rdy_o (instr_queue_rdy_o[0]), // TODO
    .instr_queue_o     (instr_queue_o[0]) // TODO: Support CPU_ISSUE_WIDTH
);

logic [CPU_ISSUE_WIDTH-1:0] commit_o;
logic [CPU_ISSUE_WIDTH-1:0] speculate_o;
logic [CPU_ISSUE_WIDTH-1:0] [          5-1:0] commit_idx_o;
logic [CPU_ISSUE_WIDTH-1:0] [          5-1:0] speculate_idx_o;
logic [CPU_ISSUE_WIDTH-1:0] [         32-1:0] commit_data_o;
logic [CPU_ISSUE_WIDTH-1:0] [ROB_IDX_LEN-1:0] speculate_data_o;
logic                   br_commit_o;
logic [ROB_IDX_LEN-1:0] br_count_o;
rob_element_t rob_data_i [CPU_ISSUE_WIDTH];

always_comb begin : instr_to_rob
    for(int i = 0; i < CPU_ISSUE_WIDTH; i++) begin
        rob_data_i[i].dest_reg        = instr_queue_o[i].dest_reg;
        rob_data_i[i].pc              = instr_queue_o[i].pc;
        rob_data_i[i].br              = instr_queue_o[i].branch;
        rob_data_i[i].expected_result = 1'b0;
        rob_data_i[i].val             = '0;
        rob_data_i[i].b_imm           = instr_queue_o[i].b_imm;
        rob_data_i[i].rdy             = 1'b0;
    end
end

reorder_buffer
#(
    .ISSUE_WIDTH (CPU_ISSUE_WIDTH),
    .WRITE_COUNT (CPU_ISSUE_WIDTH),
    .WIDTH       (32)
)
rob
(
    .clk               (clk),
    .rst               (rst),
    .common_data_bus_i (common_data_bus_o),
    .vld_i             (rob_instr_vld_i),
    .rdy_i             (rob_rdy_i),
    .data_i            (rob_data_i),
    .fls_o             (common_data_bus_o.fls),
    .rob_dest_o        (rob_dest_o),
    .commit_o          (commit_o),
    .speculate_o       (speculate_o),
    .commit_idx_o      (commit_idx_o),
    .speculate_idx_o   (speculate_idx_o),
    .commit_val_o      (commit_data_o),
    .speculate_val_o   (speculate_data_o),
    .br_count_o        (br_count_o),
    .br_commit_o       (br_commit_o),
    .load_branch_o     (load_branch_o),
    .branch_pc_o       (branch_pc_o)
);

data_interface
#(
    .MULTIPLE_ISSUE (CPU_ISSUE_WIDTH),
    .BUFFER_DEPTH   (CPU_ADDR_BUFFER_DEPTH),
    .UNIT_DEPTH     (CPU_ADDR_UNIT_DEPTH)
)
data_intr
(
    .clk                (clk),
    .rst                (rst),
    .BR_commit_i        (br_commit_o),
    .BR_cnt_i           (br_count_o),
    .instr_vld_i        (instr_queue_vld_mem_o[0]), // TODO CPU_ISSUE_WIDTH
    .instr_rdy_o        (data_intr_rdy_i[0]),
    .instr_i            (instr_queue_o[0]),
    .mem_resp_i         (data_resp),
    .mem_read_o         (data_read),
    .mem_write_o        (data_write),
    .mem_addr_o         (data_addr),
    .mem_data_i         (data_rdata),
    .mem_data_o         (data_wdata),
    .mem_byte_en_o      (data_mbe),
    .common_data_bus_i  (common_data_bus_o),
    .common_data_lane_o (common_data_bus_o.data_lanes[CPU_EXE_UNIT_COUNT])
);

register_file
#(
    .ISSUE_WIDTH (CPU_ISSUE_WIDTH),
    .ROB_IDX_LEN (ROB_IDX_LEN)
)
reg_file
(
    .clk              (clk),
    .rst              (rst),
    .fls              (common_data_bus_o.fls),
    .commit_i         (commit_o),
    .speculate_i      (speculate_o),
    .commit_idx_i     (commit_idx_o),
    .speculate_idx_i  (speculate_idx_o),
    .commit_data_i    (commit_data_o),
    .speculate_data_i (speculate_data_o),
    .reg_bus_o        (reg_bus_o)
);

logic [CPU_EXE_UNIT_COUNT-1:0] res_station_vld_o;
logic [CPU_EXE_UNIT_COUNT-1:0] res_station_rdy_o;
reservation_station_element_t res_station_element_o [CPU_EXE_UNIT_COUNT];

reservation_station
#(
    .DEPTH       (CPU_RS_DEPTH),
    .WRITE_COUNT (CPU_ISSUE_WIDTH),
    .READ_COUNT  (CPU_EXE_UNIT_COUNT)
)
res_station
(
    .clk               (clk),
    .rst               (rst),
    .common_data_bus_i (common_data_bus_o),
    .vld_i             (instr_queue_vld_alu_o),
    .rdy_i             (res_station_rdy_i),
    .data_i            (instr_queue_o),
    .vld_o             (res_station_vld_o),
    .rdy_o             (res_station_rdy_o),
    .data_o            (res_station_element_o)
);

generate
genvar i;
for(i = 0; i < CPU_EXE_UNIT_COUNT; i++) begin : def_exe_units
    execution_unit
    #(
        .REG_IN  (CPU_REG_EXE_UNIT_IN),
        .REG_OUT (CPU_REG_EXE_UNIT_OUT)
    )
    exec_unit
    (
        .clk    (clk),
        .rst    (rst),
        .vld_i  (res_station_vld_o[i]),
        .rdy_i  (res_station_rdy_o[i]),
        .data_i (res_station_element_o[i]),
        .data_o (common_data_bus_o.data_lanes[i])
    );
end
endgenerate

endmodule : cpu
