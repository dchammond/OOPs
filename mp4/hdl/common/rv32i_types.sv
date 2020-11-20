// ECE411 Final Project: OOPs
// Caleb Gerth cdgerth2
// Dillon Hammond dillonh2
// Jonathan Paulson paulson5

/* Re-used from MP3 */

package rv32i_types;

typedef logic [31:0] rv32i_word;

typedef enum bit [6:0] {
    op_lui   = 7'b0110111, //load upper immediate (U type)
    op_auipc = 7'b0010111, //add upper immediate PC (U type)
    op_jal   = 7'b1101111, //jump and link (J type)
    op_jalr  = 7'b1100111, //jump and link register (I type)
    op_br    = 7'b1100011, //branch (B type)
    op_load  = 7'b0000011, //load (I type)
    op_store = 7'b0100011, //store (S type)
    op_imm   = 7'b0010011, //arith ops with register/immediate operands (I type)
    op_reg   = 7'b0110011, //arith ops with register operands (R type)
    op_csr   = 7'b1110011  //control and status register (I type)
} rv32i_opcode_t;

typedef enum bit [2:0] {
    beq  = 3'b000,
    bne  = 3'b001,
    blt  = 3'b100,
    bge  = 3'b101,
    bltu = 3'b110,
    bgeu = 3'b111
} branch_funct3_t;

typedef enum bit [2:0] {
     b = 3'b000,
     h = 3'b001,
     w = 3'b010,
    bu = 3'b100,
    hu = 3'b101
} load_store_funct3_t;

typedef enum bit [2:0] {
    add  = 3'b000, //check bit30 for sub if op_reg opcode
    sll  = 3'b001,
    slt  = 3'b010,
    sltu = 3'b011,
    axor = 3'b100,
    sr   = 3'b101, //check bit30 for logical/arithmetic
    aor  = 3'b110,
    aand = 3'b111
} arith_funct3_t;

typedef enum bit [2:0] {
    alu_add = 3'b000,
    alu_sll = 3'b001,
    alu_sra = 3'b010,
    alu_sub = 3'b011,
    alu_xor = 3'b100,
    alu_srl = 3'b101,
    alu_or  = 3'b110,
    alu_and = 3'b111
} alu_op_t;

typedef enum bit [5:0] {
    imm_slt =   6'b000000,
    imm_sltu =  6'b000001,
    imm_srai =  6'b000010,
    imm_srli =  6'b000011,
    imm_add =   6'b000100,
    imm_sll =   6'b000101,
    imm_axor =  6'b000110,
    imm_aor =   6'b000111,
    imm_aand =  6'b001000,
    rr_slt =    6'b001001,
    rr_sltu =   6'b001010,
    rr_sra =    6'b001011,
    rr_srl =    6'b001100,
    rr_add =    6'b001101,
    rr_sub =    6'b001110,
    rr_sll =    6'b001111,
    rr_axor =   6'b010000,
    rr_aor =    6'b010001,
    rr_aand =   6'b010010,
    auipc =     6'b010011,
    lui =       6'b010100,
    jal =       6'b010101,
    jalr =      6'b010110,
    br_beq =    6'b100000,
    br_bne =    6'b100001,
    br_blt =    6'b100010,
    br_bge =    6'b100011,
    br_bltu =   6'b100100,
    br_bgeu =   6'b100101,
    ld_lb =     6'b111000,
    ld_lh =     6'b111001,
    ld_lw =     6'b111010,
    ld_lbu =    6'b111011,
    ld_lhu =    6'b111100,
    st_sb =     6'b111101,
    st_sh =     6'b111110,
    st_sw =     6'b111111
} instruction_t;

typedef enum bit {
    ld = 1'b0,
    st = 1'b1
} mem_op_t;

endpackage : rv32i_types
