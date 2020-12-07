
module cache_interface
(
    input clk,
    input rst,
    input fls_i,

    // To Physical Memory:
    output        pmem_read,
    output        pmem_write,
    input         pmem_resp,
    output [31:0] pmem_addr,
    output [63:0] pmem_wdata,
    input  [63:0] pmem_rdata,

    // To CPU:
    input         data_read,
    input         data_write,
    input  [ 3:0] data_mbe,
    input  [31:0] data_addr,
    input  [31:0] data_wdata,
    output        data_resp,
    output [31:0] data_rdata,

    input         inst_read,
    input  [31:0] inst_addr,
    output        inst_resp,
    output [31:0] inst_rdata
);

logic [255:0] arbiter_rdata, arbiter_wdata;
logic [31:0] arbiter_addr;
logic arbiter_read, arbiter_write, arbiter_resp;

logic [255:0] d_mem_rdata, d_mem_wdata;
logic [ 31:0] d_mem_addr;
logic d_mem_read, d_mem_write, d_mem_resp;

logic [255:0] i_mem_rdata;
logic [ 31:0] i_mem_addr;
logic i_mem_read, i_mem_resp;

cacheline_adaptor cla
(
    .clk        (clk),
    .rst        (rst),

    .line_i     (arbiter_wdata),
    .line_o     (arbiter_rdata),
    .address_i  (arbiter_addr),
    .read_i     (arbiter_read),
    .write_i    (arbiter_write),
    .resp_o     (arbiter_resp),

    .burst_i    (pmem_rdata),
    .burst_o    (pmem_wdata),
    .address_o  (pmem_addr),
    .read_o     (pmem_read),
    .write_o    (pmem_write),
    .resp_i     (pmem_resp)
);

arbiter oops_arb
(
    .clk            (clk),
    .rst            (rst),
    .fls            (fls_i),

    .arbiter_rdata_i  (arbiter_rdata),
    .arbiter_wdata_o  (arbiter_wdata),
    .arbiter_addr_o   (arbiter_addr),
    .arbiter_read_o   (arbiter_read),
    .arbiter_write_o  (arbiter_write),
    .arbiter_resp_i   (arbiter_resp),

    .d_mem_rdata_o    (d_mem_rdata),
    .d_mem_wdata_i    (d_mem_wdata),
    .d_mem_addr_i     (d_mem_addr),
    .d_mem_read_i     (d_mem_read),
    .d_mem_write_i    (d_mem_write),
    .d_mem_resp_o     (d_mem_resp),

    .i_mem_rdata_o    (i_mem_rdata),
    .i_mem_addr_i     (i_mem_addr),
    .i_mem_read_i     (i_mem_read),
    .i_mem_resp_o     (i_mem_resp)
);

cache d_cache
(
    .clk                    (clk),
    .rst                    (rst),
    .pmem_resp              (d_mem_resp),
    .pmem_rdata             (d_mem_rdata),
    .pmem_address           (d_mem_addr),
    .pmem_wdata             (d_mem_wdata),
    .pmem_read              (d_mem_read),
    .pmem_write             (d_mem_write),

    .mem_read               (data_read),
    .mem_write              (data_write),
    .mem_byte_enable        (data_mbe),
    .mem_address            (data_addr),
    .mem_wdata              (data_wdata),
    .mem_resp               (data_resp),
    .mem_rdata              (data_rdata)
);

cache i_cache
(
    .clk                    (clk),
    .rst                    (rst),
    .pmem_resp              (i_mem_resp),
    .pmem_rdata             (i_mem_rdata),
    .pmem_address           (i_mem_addr),
    .pmem_wdata             (),
    .pmem_read              (i_mem_read),
    .pmem_write             (),

    .mem_read               (inst_read),
    .mem_write              ('0),
    .mem_byte_enable        ('1),
    .mem_address            (inst_addr),
    .mem_wdata              ('0),
    .mem_resp               (inst_resp),
    .mem_rdata              (inst_rdata)
);

endmodule : cache_interface
