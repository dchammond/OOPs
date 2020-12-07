import rv32i_types::*;

module cache #(
    parameter s_offset = 5,
    parameter s_index  = 3,
    parameter s_tag    = 32 - s_offset - s_index,
    parameter s_mask   = 2**s_offset,
    parameter s_line   = 8*s_mask,
    parameter num_sets = 2**s_index
)
(
    input clk,
    input rst,
    input logic mem_read,
    input logic mem_write,
    input rv32i_word mem_address,
    input logic [3:0] mem_byte_enable,
    input rv32i_word mem_wdata,
    output logic mem_resp,
    output rv32i_word mem_rdata,
    output rv32i_word pmem_address,
    input logic [255:0] pmem_rdata,
    output logic [255:0] pmem_wdata,
    output logic pmem_read,
    output logic pmem_write,
    input logic pmem_resp
);

logic [255:0] mem_wdata256;
logic [31:0] mem_byte_enable256;
logic [255:0] line_out;

/* Datapath to Control Signals */
logic way0_dirty;
logic way0_valid;
logic way1_dirty;
logic way1_valid;
logic lru_out;
logic hit_out;
logic way1_hit;

/* Control to Datapath Signals */
data_in_mux::datainmux_sel_t data_in_mux_sel;
data_out_mux::dataoutmux_sel_t data_out_mux_sel;
mem_address_mux::memaddressmux_sel_t mem_address_mux_sel;
logic [31:0] mem_en0;
logic [31:0] mem_en1;
logic d_bit;
logic v_bit;
logic read_lru;
logic load_lru;
logic read_tag;
logic load_tag0;
logic load_tag1;
logic read_dirty;
logic load_dirty0;
logic load_dirty1;
logic read_valid;
logic load_valid0;
logic load_valid1;
logic read_data;

cache_control control(.*);

cache_datapath datapath(.*);

bus_adapter bus_adapter
(
    .mem_wdata256(mem_wdata256),
    .mem_rdata256(line_out),
    .mem_wdata(mem_wdata),
    .mem_rdata(mem_rdata),
    .mem_byte_enable(mem_byte_enable),
    .mem_byte_enable256(mem_byte_enable256),
    .address(mem_address)
);

endmodule : cache
