// ECE411 Final Project: OOPs
// Caleb Gerth cdgerth2
// Dillon Hammond dillonh2
// Jonathan Paulson paulson5

import rv32i_types::*;
import oops_structs::*;

module instruction_datapath
#(
    IQ_DEPTH    = 15,
    ISSUE_WIDTH = 1
)
(
    input                                   clk,
    input                                   rst,

    input  logic                            flush_i,

    output logic [32-1:0]                   pc_o,

    input  logic                            mem_resp_i,
    input  logic [32-1:0]                   mem_rdata_i,

    output logic                            mem_read_o,
    output logic [32-1:0]                   mem_address_o,

    input  logic                            load_branch_i,
    input  logic [32-1:0]                   branch_pc_i,

    input  logic                            load_jalr_i,
    input  logic [32-1:0]                   jalr_pc_i,

    input  logic [ROB_IDX_LEN-1:0]          rob_dest_i,
    input  reg_bus_t                        reg_bus_i,
    input common_data_bus_t                 common_data_bus_i,

    input rob_element_t [ROB_ENTRIES-1:0]       rob_bus_i,

    output logic                            instr_queue_vld_o,
    input  logic                            instr_queue_rdy_o,
    output instruction_element_t            instr_queue_o
);

logic          load_plus_four_o;
logic          load_offset_o;
logic [32-1:0] offset_o;

program_counter
#(
    .WIDTH (32)
)
pc_calc
(
    .clk              (clk),
    .rst              (rst),
    .load_plus_four_i (load_plus_four_o),
    .load_offset_i    (load_offset_o),
    .offset_i         (offset_o),
    .load_branch_i    (load_branch_i),
    .branch_pc_i      (branch_pc_i),
    .load_alu_mod2_i  (load_jalr_i),
    .jalr_alu_out_i   (jalr_pc_i),
    .out              (pc_o)
);

logic          decoder_rdy_o;
logic          load_decoder_o;
logic [ 3-1:0] funct3_o;
logic [ 7-1:0] funct7_o;
rv32i_opcode_t opcode_o;
logic [32-1:0] i_imm_o;
logic [32-1:0] s_imm_o;
logic [32-1:0] b_imm_o;
logic [32-1:0] u_imm_o;
logic [32-1:0] j_imm_o;
logic [ 5-1:0] rs1_o;
logic [ 5-1:0] rs2_o;
logic [ 5-1:0] rd_o;
logic [32-1:0] instr_pc;

instruction_fetcher
#(
    .READ_WIDTH (32)
)
inst_fetch
(
    .clk                 (clk),
    .rst                 (rst),
    .fls                 (flush_i),
    .pc_i                (pc_o), // might need to be "previous pc"?
    .mem_rdata_i         (mem_rdata_i),
    .mem_resp_i          (mem_resp_i),
    .decoder_rdy_i       (decoder_rdy_o),
    .load_decoder_o      (load_decoder_o),
    .mem_address_o       (mem_address_o),
    .mem_read_o          (mem_read_o),
    .funct3              (funct3_o),
    .funct7              (funct7_o),
    .opcode              (opcode_o),
    .i_imm               (i_imm_o),
    .s_imm               (s_imm_o),
    .b_imm               (b_imm_o),
    .u_imm               (u_imm_o),
    .j_imm               (j_imm_o),
    .rs1                 (rs1_o),
    .rs2                 (rs2_o),
    .rd                  (rd_o),
    .pc_o                (instr_pc),
    .load_pc_plus_four_o (load_plus_four_o)
);

logic instr_rdy_o;
logic instr_vld_o;
instruction_element_t instruction_o;

instruction_decoder
inst_decode
(
    .clk            (clk),
    .rst            (rst),
    .fls            (flush_i),
    .load_decoder_i (load_decoder_o),
    .funct3_i       (funct3_o),
    .funct7_i       (funct7_o),
    .opcode_i       (opcode_o),
    .i_imm_i        (i_imm_o),
    .s_imm_i        (s_imm_o),
    .b_imm_i        (b_imm_o),
    .u_imm_i        (u_imm_o),
    .j_imm_i        (j_imm_o),
    .rs1_i          (rs1_o),
    .rs2_i          (rs2_o),
    .rd_i           (rd_o),
    .pc_i           (instr_pc),
    .rdy_i          (instr_rdy_o),
    .decoder_rdy_o  (decoder_rdy_o),
    .instruction_o  (instruction_o),
    .vld_i          (instr_vld_o)
);

instruction_queue
#(
    .ISSUE_WIDTH (ISSUE_WIDTH),
    .WIDTH       ($bits(instruction_element_t)),
    .DEPTH       (IQ_DEPTH)
)
inst_queue
(
    .clk                (clk),
    .rst                (rst),
    .flush              (flush_i),
    .rob_dest_i         (rob_dest_i),
    .rob_bus_i          (rob_bus_i),
    .reg_bus_i          (reg_bus_i),
    .common_data_bus_i  (common_data_bus_i),
    .vld_i              (instr_vld_o),
    .rdy_i              (instr_rdy_o),
    .instruction_i      (instruction_o),
    .vld_o              (instr_queue_vld_o),
    .rdy_o              (instr_queue_rdy_o),
    .instruction_o      (instr_queue_o)
);

endmodule : instruction_datapath
