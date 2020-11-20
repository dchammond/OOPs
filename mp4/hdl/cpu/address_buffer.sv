// ECE411 Final Project: OOPs
// Caleb Gerth cdgerth2
// Dillon Hammond dillonh2
// Jonathan Paulson paulson5

import rv32i_types::*;
import oops_structs::*;


module address_buffer
#(
    DEPTH = 15
)
(
    input                           clk,
    input                           rst,

    input  logic                    vld_i,
    output logic                    rdy_i,
    input  address_buffer_element_t address_data_i,

    output logic                    vld_o,
    input  logic                    rdy_o,
    output address_buffer_element_t address_data_o
);

queue
#(
    .WIDTH ($bits(address_buffer_element_t)), 
    .DEPTH (DEPTH)
)
address_buffer_queue
(
    .clk    (clk),
    .rst    (rst),
    .vld_i  (vld_i),
    .rdy_i  (rdy_i),
    .data_i (address_data_i),
    .vld_o  (vld_o),
    .rdy_o  (rdy_o),
    .data_o (address_data_o)
); 

endmodule : address_buffer
