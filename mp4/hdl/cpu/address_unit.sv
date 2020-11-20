// ECE411 Final Project: OOPs
// Caleb Gerth cdgerth2
// Dillon Hammond dillonh2
// Jonathan Paulson paulson5

import rv32i_types::*;
import oops_structs::*;

module address_unit
#(
    DEPTH = 15,
    ROB_IDX_LEN = 4 
)
(
    input                           clk,
    input                           rst,

    input  logic                    BR_commit_i, // when a branch is correctly predicted.
    input  common_data_bus_t        common_data_bus_i,
    
    input  logic                    vld_i,
    output logic                    rdy_i,
    input  address_unit_element_t   address_data_i,

    output logic                    vld_o,
    input  logic                    rdy_o,
    output address_buffer_element_t address_data_o
);

localparam WIDTH  = $bits(address_unit_element_t); 
localparam DEPTH2 = 2 ** ($clog2(DEPTH));

address_unit_element_t data_d [DEPTH2];
address_unit_element_t data_q [DEPTH2];
logic [DEPTH2-1:0] used_mask_d, used_mask_q;

logic [$clog2(DEPTH2)-1:0] read_addr_d,  read_addr_q;
logic [$clog2(DEPTH2)-1:0] write_addr_d, write_addr_q;

logic almost_empty, empty;
logic almost_full, full;

logic read, write;

logic commitable; // Bit that determines if the tail of the queue is commitable to memory.

logic rdy_d, vld_d;

assign almost_empty = (read_addr_q  + 1'b1 == write_addr_q) && (used_mask_q[write_addr_q] == 1'b0);
assign almost_full  = (write_addr_q + 1'b1 == read_addr_q ) && (used_mask_q[ read_addr_q] == 1'b1);

assign empty = (write_addr_q == read_addr_q) && (used_mask_q[read_addr_q] == 1'b0);
assign full  = (write_addr_q == read_addr_q) && (used_mask_q[read_addr_q] == 1'b1);

// Commitable if: not speculative, the cb1 is 0 and either (we are storing or cb2 is also 0).
assign commitable = (data_d[read_addr_d].BR_cnt == '0 || (data_d[read_addr_d].BR_cnt == ROB_IDX_LEN'(1) && BR_commit_i)) 
                 && (data_d[read_addr_d].CB1    == 1'b0) 
                 && (data_d[read_addr_d].mem_op == ld || data_d[read_addr_d].CB2 == 1'b0);

assign read  = !empty && rdy_o && vld_o;
assign write = !full  && vld_i && rdy_i;

assign rdy_d =               !( (almost_full  && write && !read)  || (full  && !read) );  // We cannot accept  data after this cycle
assign vld_d = commitable && !( (almost_empty && read  && !write) || (empty && !write) ); // We cannot provide data after this cycle

// Translate the structures:
assign address_data_o.addr     = data_q[read_addr_q].val1 + data_q[read_addr_q].imm; // Perform address calculation
assign address_data_o.data     = data_q[read_addr_q].val2; // This only matters in a store.
assign address_data_o.ROB_dest = data_q[read_addr_q].ROB_dest;
assign address_data_o.funct_3  = data_q[read_addr_q].funct_3;
assign address_data_o.mem_op   = data_q[read_addr_q].mem_op;

function void readsWrites();
    if(read) begin
        read_addr_d = read_addr_q + 1'b1;
        // Mark this element as free
        used_mask_d[read_addr_q] = 1'b0;
    end

    if(write) begin
        write_addr_d = write_addr_q + 1'b1;
        // Read in the data and mark the spot as full
        data_d[write_addr_q]      = address_data_i;
        used_mask_d[write_addr_q] = 1'b1;
    end
endfunction

function void busUpdates();
    for(int i = 0; i < DEPTH2; i++) begin
        if(used_mask_q[i]) begin
            if(data_q[i].CB1) begin
                for(int k = 0; k < NUM_CDB_INPUTS; k++) begin
                    if(common_data_bus_i.data_lanes[k].valid) begin
                        if(common_data_bus_i.data_lanes[k].ROB_dest == data_q[i].val1[ROB_IDX_LEN-1:0]) begin
                            data_d[i].val1[31:0] = common_data_bus_i.data_lanes[k].data[31:0];
                            data_d[i].CB1        = 1'b0;
                        end
                    end
                end
            end
            if(data_q[i].CB2) begin
                for(int k = 0; k < NUM_CDB_INPUTS; k++) begin
                    if(common_data_bus_i.data_lanes[k].valid) begin
                        if(common_data_bus_i.data_lanes[k].ROB_dest == data_q[i].val2[ROB_IDX_LEN-1:0]) begin
                            data_d[i].val2[31:0] = common_data_bus_i.data_lanes[k].data[31:0];
                            data_d[i].CB2        = 1'b0;
                        end
                    end
                end
            end
        end
    end
endfunction

always_ff @(posedge clk) begin : queue_sequential_functionality
    data_q       <= data_d;
    used_mask_q  <= used_mask_d;
    read_addr_q  <= read_addr_d;
    write_addr_q <= write_addr_d;
    rdy_i        <= rdy_d;
    vld_o        <= vld_d;
    if (rst | common_data_bus_i.fls) begin
        used_mask_q  <= '0;
        read_addr_q  <= '0;
        write_addr_q <= '0;
        rdy_i        <= '0;
        vld_o        <= '0;
    end
end

function void BrUpdates();
    if (BR_commit_i) begin
        for (int i = 0; i < DEPTH2; i++) begin
            if (data_d[i].BR_cnt != '0) begin
                data_d[i].BR_cnt--;
            end
        end
    end
endfunction

always_comb begin : address_buffer_sequential_functionality
    data_d       = data_q;
    used_mask_d  = used_mask_q;
    read_addr_d  = read_addr_q;
    write_addr_d = write_addr_q;
    readsWrites();
    BrUpdates();
    busUpdates();
end

endmodule : address_unit
