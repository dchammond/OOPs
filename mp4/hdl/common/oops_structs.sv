// ECE411 Final Project: OOPs
// Caleb Gerth cdgerth2
// Dillon Hammond dillonh2
// Jonathan Paulson paulson5

package oops_structs;

import rv32i_types::*;

parameter ROB_IDX_LEN = 4;
parameter ROB_ENTRIES = 2**ROB_IDX_LEN;
parameter CPU_EXE_UNIT_COUNT = 6;
// Note that this is number of ALU's + 1 (because of the D-Cache)
parameter NUM_CDB_INPUTS = CPU_EXE_UNIT_COUNT + 1; // If we can make this an input that's better, because we will probably need it elsewhere.

typedef struct packed {
    bit [           31:0]  addr;
    bit [           31:0]  data;
    bit [ROB_IDX_LEN-1:0]  ROB_dest;
    load_store_funct3_t    funct_3;
    mem_op_t               mem_op;
} address_buffer_element_t;

typedef struct packed {
    bit                     CB1;
    bit                     CB2;
    bit [           31:0]   val1;
    bit [           31:0]   val2;
    bit [           31:0]   imm;
    load_store_funct3_t     funct_3;
    bit [ROB_IDX_LEN-1:0]   BR_cnt; // Current depth of speculation
    bit [ROB_IDX_LEN-1:0]   ROB_dest;
    mem_op_t                mem_op;
} address_unit_element_t;

typedef struct packed {
    instruction_t           instruction;
    bit                     CB1;
    bit                     CB2;
    bit [31:0]              val1;
    bit [31:0]              val2;
    bit [ 4:0]              dest_reg;
    bit [ROB_IDX_LEN-1:0]   ROB_dest;
    bit                     branch;
    bit [31:0]              b_imm;
    bit [31:0]              pc;
} instruction_element_t;

typedef struct packed {
    bit                   CB1;
    bit                   CB2;
    bit [31:0]            val1;
    bit [31:0]            val2;
    instruction_t         op;
    bit [ROB_IDX_LEN-1:0] rob_dest;
} reservation_station_element_t;

typedef struct packed {
    bit [           31:0] data;
    bit [ROB_IDX_LEN-1:0] ROB_dest;
    bit                   valid;
} common_data_lane_t;

typedef struct packed {
    common_data_lane_t [NUM_CDB_INPUTS-1:0] data_lanes;
    bit                                     fls;
} common_data_bus_t;

typedef struct packed {
    bit [31:0]              data;
    bit                     CB;
    bit [ROB_IDX_LEN-1:0]   ROB_ref;
} reg_file_element_t;

typedef struct packed {
    bit [31:0]              data;
    bit                     CB;
} reg_bus_lane_t;

typedef struct packed {
    reg_bus_lane_t [31:0] reg_data;
} reg_bus_t;

typedef struct packed {
    bit [4:0] dest_reg;
    bit [31:0] pc;
    bit br;
    bit expected_result;
    bit [31:0] val;
    bit [31:0] b_imm;
    bit rdy;
} rob_element_t;

endpackage : oops_structs
