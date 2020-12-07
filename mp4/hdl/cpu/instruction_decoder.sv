// ECE411 Final Project: OOPs
// Caleb Gerth cdgerth2
// Dillon Hammond dillonh2
// Jonathan Paulson paulson5

import rv32i_types::*;
import oops_structs::*;

module instruction_decoder
(
    input                          clk,
    input                          rst,
    input                          fls,

    input logic                    load_decoder_i,

    input [2:0]                    funct3_i,
    input [6:0]                    funct7_i,
    input rv32i_opcode_t           opcode_i,
    input [31:0]                   i_imm_i,
    input [31:0]                   s_imm_i,
    input [31:0]                   b_imm_i,
    input [31:0]                   u_imm_i,
    input [31:0]                   j_imm_i,
    input [4:0]                    rs1_i,
    input [4:0]                    rs2_i,
    input [4:0]                    rd_i,
    input [31:0]                   pc_i,

    input logic                    rdy_i,

    output logic                   decoder_rdy_o,
    output instruction_element_t   instruction_o,
    output logic                   vld_i
);

logic [2:0]     funct3_q, funct3_d;
logic [6:0]     funct7_q, funct7_d;
rv32i_opcode_t  opcode_q, opcode_d;
logic [31:0]    i_imm_q, i_imm_d;
logic [31:0]    s_imm_q, s_imm_d;
logic [31:0]    b_imm_q, b_imm_d;
logic [31:0]    u_imm_q, u_imm_d;
logic [31:0]    j_imm_q, j_imm_d;
logic [4:0]     rs1_q, rs1_d;
logic [4:0]     rs2_q, rs2_d;
logic [4:0]     rd_q, rd_d;
logic [31:0]    pc_q, pc_d;

instruction_element_t instruction_d;

enum int unsigned {
    DECODE1,
    DECODE2,
    DECODE3
} state_d, state_q;

always_comb begin : state_actions
    funct3_d = funct3_q;
    funct7_d = funct7_q;
    opcode_d = opcode_q;
    i_imm_d = i_imm_q;
    s_imm_d = s_imm_q;
    b_imm_d = b_imm_q;
    u_imm_d = u_imm_q;
    j_imm_d = j_imm_q;
    rs1_d = rs1_q;
    rs2_d = rs2_q;
    rd_d = rd_q;
    pc_d = pc_q;

    instruction_d = instruction_o;

    decoder_rdy_o = '0;
    vld_i = '0;

    case(state_q)
        DECODE1: begin
            funct3_d = funct3_i;
            funct7_d = funct7_i;
            opcode_d = opcode_i;
            i_imm_d = i_imm_i;
            s_imm_d = s_imm_i;
            b_imm_d = b_imm_i;
            u_imm_d = u_imm_i;
            j_imm_d = j_imm_i;
            rs1_d = rs1_i;
            rs2_d = rs2_i;
            rd_d = rd_i;
            pc_d = pc_i;

            decoder_rdy_o = 1'b1;
        end
        DECODE2: begin
            instruction_d.pc = pc_q;
            instruction_d.b_imm = '0;
            instruction_d.jal = '0;
            instruction_d.jalr = '0;

            case(opcode_q)
                op_lui: begin
                    instruction_d.instruction = lui;
                    instruction_d.CB1 = '0;
                    instruction_d.CB2 = '0;
                    instruction_d.val1 = '0;
                    instruction_d.val2 = u_imm_q;
                    instruction_d.dest_reg = rd_q;
                    instruction_d.branch = '0;
                end
                op_auipc: begin
                    instruction_d.instruction = auipc;
                    instruction_d.CB1 = '0;
                    instruction_d.CB2 = '0;
                    instruction_d.val1 = pc_q;
                    instruction_d.val2 = u_imm_q;
                    instruction_d.dest_reg = rd_q;
                    instruction_d.branch = '0;
                end
                op_br: begin
                    unique case(funct3_q)
                        beq: instruction_d.instruction = br_beq;
                        bne: instruction_d.instruction = br_bne;
                        blt: instruction_d.instruction = br_blt;
                        bge: instruction_d.instruction = br_bge;
                        bltu: instruction_d.instruction = br_bltu;
                        bgeu: instruction_d.instruction = br_bgeu;
                        default: ;
                    endcase
                    instruction_d.CB1 = 1'b1;
                    instruction_d.CB2 = 1'b1;
                    instruction_d.val1 = rs1_q;
                    instruction_d.val2 = rs2_q;
                    instruction_d.dest_reg = '0;
                    instruction_d.branch = 1'b1;
                    instruction_d.b_imm = b_imm_q;
                end
                op_load: begin
                    unique case(funct3_q)
                        b: instruction_d.instruction = ld_lb;
                        h: instruction_d.instruction = ld_lh;
                        w: instruction_d.instruction = ld_lw;
                        bu: instruction_d.instruction = ld_lbu;
                        hu: instruction_d.instruction = ld_lhu;
                        default: ;
                    endcase
                    instruction_d.CB1 = 1'b1;
                    instruction_d.CB2 = '0;
                    instruction_d.val1 = rs1_q;
                    instruction_d.val2 = rs2_q;
                    instruction_d.b_imm = i_imm_q;
                    instruction_d.dest_reg = rd_q;
                    instruction_d.branch = '0;
                end
                op_store: begin
                    unique case(funct3_q)
                        b: instruction_d.instruction = st_sb;
                        h: instruction_d.instruction = st_sh;
                        w: instruction_d.instruction = st_sw;
                        default: ;
                    endcase
                    instruction_d.CB1 = 1'b1;
                    instruction_d.CB2 = 1'b1;
                    instruction_d.val1 = rs1_q;
                    instruction_d.val2 = rs2_q;
                    instruction_d.b_imm = s_imm_q;
                    instruction_d.dest_reg = '0;
                    instruction_d.branch = '0;
                end
                op_imm: begin
                    unique case(funct3_q)
                        slt: begin
                            instruction_d.instruction = imm_slt;
                        end
                        sltu: begin
                            instruction_d.instruction = imm_sltu;
                        end
                        sr: begin
                            if(funct7_q[5]) begin
                                instruction_d.instruction = imm_srai;
                            end
                            else begin
                                instruction_d.instruction = imm_srli;
                            end
                        end
                        add: begin
                            instruction_d.instruction = imm_add;
                        end
                        sll: begin
                            instruction_d.instruction = imm_sll;
                        end
                        axor: begin
                            instruction_d.instruction = imm_axor;
                        end
                        aor: begin
                            instruction_d.instruction = imm_aor;
                        end
                        aand: begin
                            instruction_d.instruction = imm_aand;
                        end
                        default: ;
                    endcase

                    instruction_d.CB1 = 1'b1;
                    instruction_d.CB2 = '0;
                    instruction_d.val1 = rs1_q;
                    instruction_d.val2 = i_imm_q;
                    instruction_d.dest_reg = rd_q;
                    instruction_d.branch = '0;
                end
                op_reg: begin
                    unique case(funct3_q)
                        slt: begin
                            instruction_d.instruction = rr_slt;
                        end
                        sltu: begin
                            instruction_d.instruction = rr_sltu;
                        end
                        sr: begin
                            if(funct7_q[5]) begin
                                instruction_d.instruction = rr_sra;
                            end
                            else begin
                                instruction_d.instruction = rr_srl;
                            end
                        end
                        add: begin
                            if(funct7_q[5]) begin
                                instruction_d.instruction = rr_sub;
                            end
                            else begin
                                instruction_d.instruction = rr_add;
                            end
                        end
                        sll: begin
                            instruction_d.instruction = rr_sll;
                        end
                        axor: begin
                            instruction_d.instruction = rr_axor;
                        end
                        aor: begin
                            instruction_d.instruction = rr_aor;
                        end
                        aand: begin
                            instruction_d.instruction = rr_aand;
                        end
                        default: ;
                    endcase

                    instruction_d.CB1 = 1'b1;
                    instruction_d.CB2 = 1'b1;
                    instruction_d.val1 = rs1_q;
                    instruction_d.val2 = rs2_q;
                    instruction_d.dest_reg = rd_q;
                    instruction_d.branch = '0;
                end
                op_jal: begin
                    instruction_d.instruction = jal;
                    instruction_d.CB1 = '0;
                    instruction_d.CB2 = '0;
                    instruction_d.val1 = pc_q;
                    instruction_d.val2 = j_imm_q;
                    instruction_d.dest_reg = rd_q;
                    instruction_d.branch = 1'b1;
                    instruction_d.jal = 1'b1;
                end
                op_jalr: begin
                    instruction_d.instruction = jalr;
                    instruction_d.CB1 = 1'b1;
                    instruction_d.CB2 = '0;
                    instruction_d.val1 = rs1_q;
                    instruction_d.val2 = i_imm_q;
                    instruction_d.dest_reg = rd_q;
                    instruction_d.branch = 1'b1;
                    instruction_d.jalr = 1'b1;
                end
                default: ;
            endcase
        end
        DECODE3: begin
            vld_i = 1'b1;
        end
            
    endcase
end

always_comb begin : next_state_logic
    state_d = state_q;
    unique case(state_q)
        DECODE1: begin
            if(~load_decoder_i)
                state_d = DECODE1;
            else
                state_d = DECODE2;
        end
        DECODE2: begin
            state_d = DECODE3;
        end
        DECODE3: begin
            if(~rdy_i)
                state_d = DECODE3;
            else
                state_d = DECODE1;
        end
            
    endcase
end

always_ff @(posedge clk) begin: next_state_assignment
	/* Assignment of next state on clock edge */
	if(rst | fls)
		state_q <= DECODE1;
	else
		state_q <= state_d;
end

always_ff @(posedge clk) begin: register_assignments
    funct3_q <= funct3_d;
    funct7_q <= funct7_d;
    opcode_q <= opcode_d;
    i_imm_q <= i_imm_d;
    s_imm_q <= s_imm_d;
    b_imm_q <= b_imm_d;
    u_imm_q <= u_imm_d;
    j_imm_q <= j_imm_d;
    rs1_q <= rs1_d;
    rs2_q <= rs2_d;
    rd_q <= rd_d;
    pc_q <= pc_d;

    instruction_o <= instruction_d;
end

endmodule : instruction_decoder
