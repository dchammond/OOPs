// ECE411 Final Project: OOPs
// Caleb Gerth cdgerth2
// Dillon Hammond dillonh2
// Jonathan Paulson paulson5

import rv32i_types::*;
import oops_structs::*;

module alu
(
    input  logic [32-1:0] val1_i,
    input  logic [32-1:0] val2_i,
    input  instruction_t  inst_i,

    output logic [32-1:0] out_o
);

always_comb begin
    out_o = '0;
    unique case(inst_i)
    imm_slt,  rr_slt,  br_blt  : begin out_o = $signed(val1_i) < $signed(val2_i) ? 32'd1 : 32'd0;  end
    imm_sltu, rr_sltu, br_bltu : begin out_o = val1_i < val2_i ? 32'd1 : 32'd0;                    end
    imm_srai, rr_sra           : begin out_o = $signed(val1_i) >>> val2_i[0+:5];                   end
    imm_srli, rr_srl           : begin out_o = val1_i >> val2_i[0+:5];                             end
    imm_add,  rr_add           : begin out_o = val1_i + val2_i;                                    end
    imm_sll,  rr_sll           : begin out_o = val1_i << val2_i[0+:5];                             end
    imm_axor, rr_axor          : begin out_o = val1_i ^ val2_i;                                    end
    imm_aor,  rr_aor           : begin out_o = val1_i | val2_i;                                    end
    imm_aand, rr_aand          : begin out_o = val1_i & val2_i;                                    end
              rr_sub           : begin out_o = val1_i - val2_i;                                    end
                       br_beq  : begin out_o = val1_i == val2_i ? 32'd1 : 32'd0;                   end
                       br_bne  : begin out_o = val1_i != val2_i ? 32'd1 : 32'd0;                   end
                       br_bge  : begin out_o = $signed(val1_i) >= $signed(val2_i) ? 32'd1 : 32'd0; end
                       br_bgeu : begin out_o = val1_i >= val2_i ? 32'd1 : 32'd0;                   end
    auipc, jal, jalr           : begin out_o = val1_i + val2_i;                                    end
    lui                        : begin out_o = val2_i;                                             end
    endcase
end

endmodule : alu
