`define BAD_MUX_SEL $fatal("%0t %s %0d: Illegal mux select", $time, `__FILE__, `__LINE__)

import rv32i_types::*;

module cache_datapath #(
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

    /* Control to Datapath */
    input data_in_mux::datainmux_sel_t data_in_mux_sel,
    input data_out_mux::dataoutmux_sel_t data_out_mux_sel,
    input mem_address_mux::memaddressmux_sel_t mem_address_mux_sel,
    input logic [31:0] mem_en0,
    input logic [31:0] mem_en1,
    input logic d_bit,
    input logic v_bit,
    input logic read_lru,
    input logic load_lru,
    input logic read_tag,
    input logic load_tag0,
    input logic load_tag1,
    input logic read_dirty,
    input logic load_dirty0,
    input logic load_dirty1,
    input logic read_valid,
    input logic load_valid0,
    input logic load_valid1,
    input logic read_data,
    //input logic load_pmar,

    /* Datapath to Control */
    output logic way0_dirty,
    output logic way0_valid,
    output logic way1_dirty,
    output logic way1_valid,
    output logic lru_out,
    output logic hit_out,
    output logic way1_hit,

    /* CPU to Datapath */
    input rv32i_word mem_address,
    input logic [255:0] mem_wdata256,

    /* Datapath to CPU */
    output logic [255:0] line_out,

    /* Memory to Datapath */
    input logic [255:0] pmem_rdata,

    /* Datapath to Memory */
    output logic [255:0] pmem_wdata,
    output rv32i_word pmem_address
);

/********************* Internal Signal Declaration ***************************/
//logic [4:0] offset;
//logic [2:0] index;
logic [23:0] way0_tag, way1_tag;
logic way0_hit;
logic [255:0] way0_line, way1_line, data_in_mux_out;
logic [31:0] mem_address_mux_out;


//assign tag = mem_address[31:8];
//assign index = mem_address[7:5];
//assign offset = mem_address[4:0];


/*************************** Array Declaration *******************************/
array lru_arr
(
    .clk(clk),
    .rst(rst),
    .read(read_lru),
    .load(load_lru),
    .rindex(mem_address[7:5]),
    .windex(mem_address[7:5]),
    .datain(way0_hit),
    .dataout(lru_out)
);

array dirty0_arr
(
    .clk(clk),
    .rst(rst),
    .read(read_dirty),
    .load(load_dirty0),
    .rindex(mem_address[7:5]),
    .windex(mem_address[7:5]),
    .datain(d_bit),
    .dataout(way0_dirty)
);

array dirty1_arr
(
    .clk(clk),
    .rst(rst),
    .read(read_dirty),
    .load(load_dirty1),
    .rindex(mem_address[7:5]),
    .windex(mem_address[7:5]),
    .datain(d_bit),
    .dataout(way1_dirty)
);

array valid0_arr
(
    .clk(clk),
    .rst(rst),
    .read(read_valid),
    .load(load_valid0),
    .rindex(mem_address[7:5]),
    .windex(mem_address[7:5]),
    .datain(v_bit),
    .dataout(way0_valid)
);

array valid1_arr
(
    .clk(clk),
    .rst(rst),
    .read(read_valid),
    .load(load_valid1),
    .rindex(mem_address[7:5]),
    .windex(mem_address[7:5]),
    .datain(v_bit),
    .dataout(way1_valid)
);

array #(3,24)tag0_arr
(
    .clk(clk),
    .rst(rst),
    .read(read_tag),
    .load(load_tag0),
    .rindex(mem_address[7:5]),
    .windex(mem_address[7:5]),
    .datain(mem_address[31:8]),
    .dataout(way0_tag)
);

array #(3,24)tag1_arr
(
    .clk(clk),
    .rst(rst),
    .read(read_tag),
    .load(load_tag1),
    .rindex(mem_address[7:5]),
    .windex(mem_address[7:5]),
    .datain(mem_address[31:8]),
    .dataout(way1_tag)
);

data_array data0_arr
(
    .clk(clk),
    .rst(rst),
    .read(read_data),
    .write_en(mem_en0),
    .rindex(mem_address[7:5]),
    .windex(mem_address[7:5]),
    .datain(data_in_mux_out),
    .dataout(way0_line)
);

data_array data1_arr
(
    .clk(clk),
    .rst(rst),
    .read(read_data),
    .write_en(mem_en1),
    .rindex(mem_address[7:5]),
    .windex(mem_address[7:5]),
    .datain(data_in_mux_out),
    .dataout(way1_line)
);

always_comb begin: HITS
    way0_hit = way0_valid & (way0_tag == mem_address[31:8]);
    way1_hit = way1_valid & (way1_tag == mem_address[31:8]);
    hit_out = way0_hit | way1_hit;
end
//assign way0_hit = way0_valid & (way0_tag == mem_address[31:8]);
//assign way1_hit = way1_valid & (way1_tag == mem_address[31:8]);
//assign hit_out = way0_hit | way1_hit;


always_comb begin : MUXES
    data_in_mux_out = mem_wdata256;
    unique case (data_in_mux_sel)
        data_in_mux::cpu_in: data_in_mux_out = mem_wdata256;
        data_in_mux::pmem_in: data_in_mux_out = pmem_rdata;
        default: `BAD_MUX_SEL;
    endcase

    pmem_wdata = way0_line;
    unique case (data_out_mux_sel)
        data_out_mux::way0: pmem_wdata = way0_line;
        data_out_mux::way1: pmem_wdata = way1_line;
        default: `BAD_MUX_SEL;
    endcase

    pmem_address = mem_address;
    unique case (mem_address_mux_sel)
        mem_address_mux::way0: pmem_address = {way0_tag, mem_address[7:5], 5'b0};
        mem_address_mux::way1: pmem_address = {way1_tag, mem_address[7:5], 5'b0};
        mem_address_mux::mem_in: pmem_address = mem_address;
        default: `BAD_MUX_SEL;
    endcase

    line_out = way0_line;
    unique case(line_out_cpu_mux::lineoutcpumux_sel_t'(way1_hit))
        line_out_cpu_mux::way0: line_out = way0_line;
        line_out_cpu_mux::way1: line_out = way1_line;
        default: `BAD_MUX_SEL;
    endcase

end

endmodule : cache_datapath
