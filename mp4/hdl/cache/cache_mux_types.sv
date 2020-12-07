/**** Mux definitions for the cache ****/

package data_in_mux;
typedef enum bit [0:0] {
    cpu_in  = 1'b0
    ,pmem_in  = 1'b1
} datainmux_sel_t;
endpackage

package data_out_mux;
typedef enum bit [0:0] {
    way0  = 1'b0
    ,way1  = 1'b1
} dataoutmux_sel_t;
endpackage

package mem_address_mux;
typedef enum bit [1:0] {
    way0  = 2'b00
    ,way1  = 2'b01
    ,mem_in = 2'b10
} memaddressmux_sel_t;
endpackage

package line_out_cpu_mux;
typedef enum bit [0:0] {
    way0  = 1'b0
    ,way1  = 1'b1
} lineoutcpumux_sel_t;
endpackage
