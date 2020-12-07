import oops_structs::*;

module mp4
#(
    CPU_ISSUE_WIDTH       = oops_structs::CPU_ISSUE_WIDTH,
    CPU_IQ_DEPTH          = oops_structs::CPU_IQ_DEPTH,
    CPU_ADDR_BUFFER_DEPTH = oops_structs::CPU_ADDR_BUFFER_DEPTH,
    CPU_ADDR_UNIT_DEPTH   = oops_structs::CPU_ADDR_UNIT_DEPTH,
    CPU_RS_DEPTH          = oops_structs::CPU_RS_DEPTH,
    CPU_EXE_UNIT_COUNT    = oops_structs::CPU_EXE_UNIT_COUNT,
    CPU_REG_EXE_UNIT_IN   = oops_structs::CPU_REG_EXE_UNIT_IN,
    CPU_REG_EXE_UNIT_OUT  = oops_structs::CPU_REG_EXE_UNIT_OUT
)
(
    input         clk,
    input         rst,

    output        pmem_read,
    output        pmem_write,
    input         pmem_resp,
    output [31:0] pmem_addr,
    output [63:0] pmem_wdata,
    input  [63:0] pmem_rdata
);

// Port connections between CPU and Cache:
logic        fls;
logic        data_read;
logic        data_write;
logic [ 3:0] data_mbe;
logic [31:0] data_addr;
logic [31:0] data_wdata;
logic        data_resp;
logic [31:0] data_rdata;
logic        inst_read;
logic [31:0] inst_addr;
logic        inst_resp;
logic [31:0] inst_rdata;

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
    .fls_o      (fls),

    .data_read  (data_read),
    .data_write (data_write),
    .data_mbe   (data_mbe),
    .data_addr  (data_addr),
    .data_wdata (data_wdata),
    .data_resp  (data_resp),
    .data_rdata (data_rdata),

    .inst_read  (inst_read),
    .inst_addr  (inst_addr),
    .inst_resp  (inst_resp),
    .inst_rdata (inst_rdata)
);

cache_interface oops_cache
(
    .clk                (clk),
    .rst                (rst),
    .fls_i              (fls),

    .pmem_read          (pmem_read),
    .pmem_write         (pmem_write),
    .pmem_resp          (pmem_resp),
    .pmem_addr          (pmem_addr),
    .pmem_wdata         (pmem_wdata),
    .pmem_rdata         (pmem_rdata),

    .data_read          (data_read),
    .data_write         (data_write),
    .data_mbe           (data_mbe),
    .data_addr          (data_addr),
    .data_wdata         (data_wdata),
    .data_resp          (data_resp),
    .data_rdata         (data_rdata),

    .inst_read          (inst_read),
    .inst_addr          (inst_addr),
    .inst_resp          (inst_resp),
    .inst_rdata         (inst_rdata)
);

endmodule : mp4
