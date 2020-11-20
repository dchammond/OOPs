// ECE411 Final Project: OOPs
// Caleb Gerth cdgerth2
// Dillon Hammond dillonh2
// Jonathan Paulson paulson5

import rv32i_types::*;
import oops_structs::*;

module execution_unit
#(
    REG_IN  = 0, // We can optionally pipeline the execution unit
    REG_OUT = 0  // If we do this, we may need to think about flushing
)
(
    input                                clk,
    input                                rst,

    input  logic                         vld_i,
    output logic                         rdy_i,
    input  reservation_station_element_t data_i,

    output common_data_lane_t            data_o
);

logic vld_i_q, rdy_i_q;

reservation_station_element_t data_i_q;

common_data_lane_t data_o_d;

// We never have backpressure
assign rdy_i_q = 1'b1;

assign data_o_d.ROB_dest = data_i_q.rob_dest;
assign data_o_d.valid    = vld_i_q;

alu exec_alu
(
    .val1_i     (data_i_q.val1),
    .val2_i     (data_i_q.val2),
    .inst_i     (data_i_q.op),
    .out_o      (data_o_d.data)
);

pipeline
#(
    .DATA_WIDTH($bits(vld_i) + $bits(data_i)),
    .DEPTH     (REG_IN)
)
pipe_in
(
    .clk    (clk),
    .rst    (rst),
    .data_i ({vld_i, data_i}),
    .data_o ({vld_i_q, data_i_q})
);

pipeline
#(
    .DATA_WIDTH($bits(rdy_i_q)),
    .DEPTH     (REG_IN)
)
pipe_in_rdy
(
    .clk    (clk),
    .rst    (rst),
    .data_i (rdy_i_q),
    .data_o (rdy_i)
);

pipeline
#(
    .DATA_WIDTH($bits(data_o_d)),
    .DEPTH     (REG_OUT)
)
pipe_out
(
    .clk    (clk),
    .rst    (rst),
    .data_i (data_o_d),
    .data_o (data_o)
);

endmodule : execution_unit
