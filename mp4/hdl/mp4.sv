import oops_structs::*;

module mp4
#(
    CPU_ISSUE_WIDTH       = 1,
    CPU_IQ_DEPTH          = 15,
    CPU_ADDR_BUFFER_DEPTH = 15,
    CPU_ADDR_UNIT_DEPTH   = 15,
    CPU_RS_DEPTH          = 8,
    CPU_EXE_UNIT_COUNT    = CPU_EXE_UNIT_COUNT,
    CPU_REG_EXE_UNIT_IN   = 0,
    CPU_REG_EXE_UNIT_OUT  = 0
)
(
    input         clk,
    input         rst,

    // CP3:
    // output        pmem_read,
    // output        pmem_write,
    // output        pmem_byte_enable,
    // input         pmem_resp,
    // output [31:0] pmem_addr,
    // output [63:0] pmem_wdata,
    // input  [63:0] pmem_rdata

    output          mm_data_read,
    output          mm_data_write,
    output [3:0]    mm_data_mbe,
    output [31:0]   mm_data_addr,
    output [31:0]   mm_data_wdata,
    input           mm_data_resp,
    input  [31:0]   mm_data_rdata,

    output          mm_inst_read,
    output [31:0]   mm_inst_addr,
    input           mm_inst_resp,
    input  [31:0]   mm_inst_rdata
);

cpu
#(
    .CPU_ISSUE_WIDTH       (CPU_ISSUE_WIDTH),
    .CPU_IQ_DEPTH          (CPU_IQ_DEPTH),
    .CPU_ADDR_BUFFER_DEPTH (CPU_ADDR_BUFFER_DEPTH),
    .CPU_ADDR_UNIT_DEPTH   (CPU_ADDR_UNIT_DEPTH),
    .CPU_RS_DEPTH          (CPU_RS_DEPTH),
    .CPU_EXE_UNIT_COUNT    (CPU_EXE_UNIT_COUNT),
    .CPU_REG_EXE_UNIT_IN   (CPU_REG_EXE_UNIT_IN),
    .CPU_REG_EXE_UNIT_OUT  (CPU_REG_EXE_UNIT_OUT)
)
oops_cpu
(
    .clk        (clk),
    .rst        (rst),

    // Change these for CP3:
    .data_read  (mm_data_read   ),
    .data_write (mm_data_write  ),
    .data_mbe   (mm_data_mbe    ),
    .data_addr  (mm_data_addr   ),
    .data_wdata (mm_data_wdata  ),
    .data_resp  (mm_data_resp   ),
    .data_rdata (mm_data_rdata  ),

    .inst_read  (mm_inst_read   ),
    .inst_addr  (mm_inst_addr   ),
    .inst_resp  (mm_inst_resp   ),
    .inst_rdata (mm_inst_rdata  )
);

// TODO: CP3
// cache
// #(
// )
// oops_cache
// (
// );

endmodule : mp4
