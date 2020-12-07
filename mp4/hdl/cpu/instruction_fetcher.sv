// ECE411 Final Project: OOPs
// Caleb Gerth cdgerth2
// Dillon Hammond dillonh2
// Jonathan Paulson paulson5

import rv32i_types::*;

module instruction_fetcher
#(
    READ_WIDTH = 32
)
(
    input                           clk,
    input                           rst,
    input                           fls,

    input rv32i_word                pc_i,
    input logic [READ_WIDTH-1:0]    mem_rdata_i,
    input logic                     mem_resp_i,
    input logic                     decoder_rdy_i,

    output logic                    load_decoder_o,

    output rv32i_word               mem_address_o,
    output logic                    mem_read_o,

    output logic [2:0]              funct3,
    output logic [6:0]              funct7,
    output rv32i_opcode_t           opcode,
    output logic [31:0]             i_imm,
    output logic [31:0]             s_imm,
    output logic [31:0]             b_imm,
    output logic [31:0]             u_imm,
    output logic [31:0]             j_imm,
    output logic [4:0]              rs1,
    output logic [4:0]              rs2,
    output logic [4:0]              rd,
    output rv32i_word               pc_o,

    output logic                    load_pc_plus_four_o
);

logic       load_ir;
rv32i_word  mem_address_d;

enum int unsigned {
    FETCH1,
    FETCH2,
    FETCH3
} state_d, state_q;

instruction_register ir(
    .clk    (clk),
    .rst    (rst),
    .load   (load_ir),
    .in     (mem_rdata_i),
    .funct3 (funct3),
    .funct7 (funct7),
    .opcode (opcode),
    .i_imm  (i_imm),
    .s_imm  (s_imm),
    .b_imm  (b_imm),
    .u_imm  (u_imm),
    .j_imm  (j_imm),
    .rs1    (rs1),
    .rs2    (rs2),
    .rd     (rd)
);

always_comb begin : state_actions
    mem_address_d   = mem_address_o;
    mem_read_o      = '0;
    load_ir         = '0;
    load_decoder_o  = '0;
    load_pc_plus_four_o = '0;
	 pc_o				  = mem_address_o;

    case(state_q)
        FETCH1:
            mem_address_d = pc_i;
        FETCH2: begin
            load_ir = 1'b1;
            mem_read_o = 1'b1;
        end
        FETCH3: begin
            load_decoder_o = 1'b1;
            if(decoder_rdy_i) begin
                load_pc_plus_four_o = 1'b1;
                // For multi-fetch, we would keep track of number of instructions
                // and raise the load_offset_i input of the program_counter with
                // the necessary offset for the number of instructions fetched.
            end
        end
        default: begin end
            
    endcase
end

always_comb begin : next_state_logic
    state_d = state_q;
    unique case(state_q)
        FETCH1: begin
            state_d = FETCH2;
        end
        FETCH2: begin
            if(~mem_resp_i)
                state_d = FETCH2;
            else
                state_d = FETCH3;
        end
        FETCH3: begin
            if(~decoder_rdy_i)
                state_d = FETCH3;
            else
                state_d = FETCH1;
        end
    endcase
end

always_ff @(posedge clk) begin: next_state_assignment
	/* Assignment of next state on clock edge */
	if(rst | fls)
		state_q <= FETCH1;
	else
		state_q <= state_d;
end

always_ff @(posedge clk) begin: register_assignments
	mem_address_o <= mem_address_d;

    if(rst) begin
        mem_address_o <= '0;
    end
end

endmodule : instruction_fetcher
