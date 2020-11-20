// ECE411 Final Project: OOPs
// Caleb Gerth cdgerth2
// Dillon Hammond dillonh2
// Jonathan Paulson paulson5

import rv32i_types::*;
import oops_structs::*;

module data_interface
#(
    MULTIPLE_ISSUE = 1,
    BUFFER_DEPTH   = 15,
    UNIT_DEPTH     = 15
)
(
    input                           clk,
    input                           rst,

    // From ROB:
    input  logic                    BR_commit_i,
    input  logic [ROB_IDX_LEN-1:0]  BR_cnt_i,

    // To / From Instruction Queue
    // TODO: Support CPU_ISSUE_WIDTH
    input  logic                    instr_vld_i,
    output logic                    instr_rdy_o,
    input  instruction_element_t    instr_i,

    // To / From D-Cache
    input  logic                    mem_resp_i,
    output logic                    mem_read_o,
    output logic                    mem_write_o,
    output logic [           31:0]  mem_addr_o,
    input  logic [           31:0]  mem_data_i,
    output logic [           31:0]  mem_data_o,
    output logic [            3:0]  mem_byte_en_o,

    // To / From the datapath
    input  common_data_bus_t        common_data_bus_i,
    output common_data_lane_t       common_data_lane_o
);

// Rearrangement of the instruction for better processing:
address_unit_element_t address_data_in;

// Logic between the address unit and the address buffer:
logic                    commit_rdy_d, commit_vld_d;
address_buffer_element_t commitable_address_data_d;

// Logic to interact with the D-Cache:
logic                    mem_trans_rdy_d, mem_trans_vld_d;
address_buffer_element_t current_transaction_o, current_transaction_d, current_transaction_q;

// Logic to put the data on the CDB:
logic [31:0] shifted_mem_data_d;

// State machine logic:
enum int unsigned {
    IDLE,
    MEM // Ineract with memory and forward to CDB.
} state_d, state_q;

function bit [3:0] calculateByteEn
(
    input load_store_funct3_t   funct_3_i,
    input bit [1:0]             shift_i
);
    unique case (funct_3_i)
        b, bu: begin // Byte
            unique case (shift_i)
                2'b11 : return 4'b1000;
                2'b10 : return 4'b0100;
                2'b01 : return 4'b0010;
                2'b00 : return 4'b0001;
            endcase
        end
        h, hu: begin // Half
            unique case (shift_i)
                2'b10   : return 4'b1100;
                default : return 4'b0011;
            endcase
        end
        default: begin // Word
            return 4'b1111;
        end
    endcase
endfunction


function logic [31:0] shiftData
(
    input load_store_funct3_t   funct_3_i,
    input logic [1:0]           shift_i,
    input mem_op_t              mem_op,
    input logic [31:0]          data_i
);

    if (mem_op == st) begin // Store
        unique case (funct_3_i)
            b, bu : begin
                unique case (shift_i)
                    2'b11 : return data_i << (3 * 8);
                    2'b10 : return data_i << (2 * 8);
                    2'b01 : return data_i << (1 * 8);
                    2'b00 : return data_i           ;
                endcase
            end
            h, hu : begin
                unique case (shift_i)
                    2'b10   : return data_i << (2 * 8);
                    default : return data_i           ;
                endcase
            end
            default: begin return data_i; end
        endcase
    end else begin // Load
        unique case (funct_3_i)
            b  : begin
                unique case (shift_i)
                    2'b11 : return 32'(signed'(8'(data_i >> (3 * 8))));
                    2'b10 : return 32'(signed'(8'(data_i >> (2 * 8))));
                    2'b01 : return 32'(signed'(8'(data_i >> (1 * 8))));
                    2'b00 : return 32'(signed'(8'(data_i           )));
                endcase
            end
            bu : begin
                unique case (shift_i)
                    2'b11 : return 32'(unsigned'(8'(data_i >> (3 * 8))));
                    2'b10 : return 32'(unsigned'(8'(data_i >> (2 * 8))));
                    2'b01 : return 32'(unsigned'(8'(data_i >> (1 * 8))));
                    2'b00 : return 32'(unsigned'(8'(data_i           )));
                endcase
            end
            h  : begin
                unique case (shift_i)
                    2'b10   : return 32'(signed'(16'(data_i >> (2 * 8))));
                    default : return 32'(signed'(16'(data_i           )));
                endcase
            end
            hu : begin
                unique case (shift_i)
                    2'b10   : return 32'(unsigned'(16'(data_i >> (2 * 8))));
                    default : return 32'(unsigned'(16'(data_i           )));
                endcase
            end
            default: begin return data_i; end
        endcase
    end
endfunction

address_unit
#(
    .DEPTH          (UNIT_DEPTH),
    .ROB_IDX_LEN    (ROB_IDX_LEN)
)
au
(
    .clk                (clk),
    .rst                (rst),
    .BR_commit_i        (BR_commit_i),
    .common_data_bus_i  (common_data_bus_i),
    .vld_i              (instr_vld_i),
    .rdy_i              (instr_rdy_o),
    .address_data_i     (address_data_in),
    .vld_o              (commit_vld_d),
    .rdy_o              (commit_rdy_d),
    .address_data_o     (commitable_address_data_d)
);

address_buffer
#(
    .DEPTH  (BUFFER_DEPTH)
)
ab
(
    .clk            (clk),
    .rst            (rst),
    .vld_i          (commit_vld_d),
    .rdy_i          (commit_rdy_d),
    .address_data_i (commitable_address_data_d),
    .vld_o          (mem_trans_vld_d),
    .rdy_o          (mem_trans_rdy_d),
    .address_data_o (current_transaction_o)
);

always_comb begin : convert_incoming_instr
    address_data_in.CB1      = instr_i.CB1;
    address_data_in.val1     = instr_i.val1;
    address_data_in.CB2      = instr_i.CB2;
    address_data_in.val2     = instr_i.val2;
    address_data_in.imm      = instr_i.b_imm;
    address_data_in.ROB_dest = instr_i.ROB_dest;
    address_data_in.BR_cnt   = BR_cnt_i;

    unique case (instr_i.instruction)
        ld_lb  : begin
            address_data_in.mem_op  = ld;
            address_data_in.funct_3 = b;
        end
        ld_lh  : begin
            address_data_in.mem_op  = ld;
            address_data_in.funct_3 = h;
        end
        ld_lw  : begin
            address_data_in.mem_op  = ld;
            address_data_in.funct_3 = w;
        end
        ld_lbu : begin
            address_data_in.mem_op  = ld;
            address_data_in.funct_3 = bu;
        end
        ld_lhu : begin
            address_data_in.mem_op  = ld;
            address_data_in.funct_3 = hu;
        end
        st_sb  : begin
            address_data_in.mem_op  = st;
            address_data_in.funct_3 = b;
        end
        st_sh  : begin
            address_data_in.mem_op  = st;
            address_data_in.funct_3 = h;
        end
        st_sw  : begin
            address_data_in.mem_op  = st;
            address_data_in.funct_3 = w;
        end
        default : begin
            // $error("Invalid memory operation!"); // This gets thrown at time 0, so I commented it out.
            // A latch gets inferred if we don't assign values here:
            address_data_in.mem_op  = ld;
            address_data_in.funct_3 = b;
        end
    endcase
end : convert_incoming_instr

always_comb begin : handleShifts
    shifted_mem_data_d = shiftData(current_transaction_q.funct_3, current_transaction_q.addr[1:0], ld, mem_data_i);
end : handleShifts

always_comb begin : next_state_logic
    state_d = state_q;
    unique case (state_q)
        IDLE: begin
            if (mem_trans_vld_d) begin
                state_d = MEM;
            end
        end
        MEM : begin
            if (mem_resp_i) begin
                state_d = IDLE;
            end
        end
    endcase
end : next_state_logic

always_comb begin : state_actions
    mem_trans_rdy_d       = 1'b0;
    mem_read_o            = 1'b0;
    mem_write_o           = 1'b0;
    mem_addr_o            = 32'd0;
    common_data_lane_o    = '0;
    current_transaction_d = current_transaction_q;

    unique case (state_q)
        IDLE: begin
            mem_trans_rdy_d = 1'b1;
            current_transaction_d = current_transaction_o;
            // Use combinational values to start memory operation on cycle that data is available.
            mem_byte_en_o = calculateByteEn(current_transaction_d.funct_3, current_transaction_d.addr[1:0]);
            mem_data_o    =       shiftData(current_transaction_d.funct_3, current_transaction_d.addr[1:0], st, current_transaction_d.data);
            mem_addr_o    =                {current_transaction_d.addr[31:2], 2'b0};
            // When data becomes valid, immediately assert read or write.
            if (mem_trans_vld_d) begin
                mem_read_o    = (current_transaction_d.mem_op == ld) ? 1'b1 : 1'b0;
                mem_write_o   = (current_transaction_d.mem_op == st) ? 1'b1 : 1'b0;
            end
        end
        MEM : begin
            // Hold all the memory values using the register values.
            mem_byte_en_o = calculateByteEn(current_transaction_q.funct_3, current_transaction_q.addr[1:0]);
            mem_data_o    =       shiftData(current_transaction_q.funct_3, current_transaction_q.addr[1:0], st, current_transaction_q.data);
            mem_addr_o    = {current_transaction_q.addr[31:2], 2'b0};
            mem_read_o    = (current_transaction_q.mem_op == ld) ? 1'b1 : 1'b0;
            mem_write_o   = (current_transaction_q.mem_op == st) ? 1'b1 : 1'b0;

            common_data_lane_o.data     = shifted_mem_data_d;
            common_data_lane_o.ROB_dest = current_transaction_q.ROB_dest;
            common_data_lane_o.valid    = mem_resp_i;
        end
    endcase
end : state_actions

always_ff @(posedge clk) begin : next_state_assignment
    if (rst) begin
        state_q <= IDLE;
    end else begin
        state_q               <= state_d;
        current_transaction_q <= current_transaction_d;
    end
end : next_state_assignment

endmodule : data_interface
