// ECE411 Final Project: OOPs
// Caleb Gerth cdgerth2
// Dillon Hammond dillonh2
// Jonathan Paulson paulson5

import rv32i_types::*;
import oops_structs::*;

// `define DEBUG_MSG

module reorder_buffer
#(
    ISSUE_WIDTH = 1,
    WIDTH = 32
)
(
    input                                               clk,
    input                                               rst,

    input common_data_bus_t                             common_data_bus_i,

    input  logic [ISSUE_WIDTH-1:0]                      vld_i,
    output logic [ISSUE_WIDTH-1:0]                      rdy_i,
    input rob_element_t                                 data_i [ISSUE_WIDTH],

    output logic                                        fls_o,
	 
    output logic [ROB_IDX_LEN-1:0]                      rob_dest_o,

    output logic [ISSUE_WIDTH-1:0]                      commit_o,
    output logic [ISSUE_WIDTH-1:0]                      speculate_o,

    output logic [$clog2(32)-1:0]                       commit_idx_o [ISSUE_WIDTH],
    output logic [ROB_IDX_LEN-1:0]                      commit_rob_idx_o [ISSUE_WIDTH],
    output logic [$clog2(32)-1:0]                       speculate_idx_o [ISSUE_WIDTH],
    
    output logic [31:0]                                 commit_val_o [ISSUE_WIDTH],
    output logic [ROB_IDX_LEN-1:0]                      speculate_val_o [ISSUE_WIDTH],

    output logic [ROB_IDX_LEN-1:0]                      br_count_o,
    output logic                                        br_commit_o,

    output logic                                        load_branch_o,
    output logic [WIDTH-1:0]                            branch_pc_o,

    output rob_element_t [ROB_ENTRIES-1:0]              rob_bus_o,

    output logic                                        load_jalr_o,
    output logic [WIDTH-1:0]                            jalr_pc_o
);

rob_element_t [ROB_ENTRIES-1:0] memory_d;
rob_element_t [ROB_ENTRIES-1:0] memory_q;


logic [ROB_IDX_LEN-1:0] br_count_d;
logic br_count_inc;
logic br_count_dec;

logic [ROB_ENTRIES-1:0] used_mask_d, used_mask_q;

logic [ROB_IDX_LEN-1:0] read_addr_d,  read_addr_q;
logic [ROB_IDX_LEN-1:0] write_addr_d, write_addr_q;

logic empty;
logic almost_full, full;

logic read, write;

logic rdy_d;

assign rob_bus_o = memory_q;

assign rob_dest_o = write_addr_q;

assign almost_full  = (write_addr_q + 1'b1 == read_addr_q ) && (used_mask_q[ read_addr_q] == 1'b1);

assign empty = (write_addr_q == read_addr_q) && (used_mask_q[read_addr_q] == 1'b0);
assign full  = (write_addr_q == read_addr_q) && (used_mask_q[read_addr_q] == 1'b1);

assign read  = !empty && memory_q[read_addr_q].rdy;
assign write = !full  && vld_i[0] && rdy_i[0]; // TODO width

assign rdy_d = !( (almost_full  && write && !read)  || (full  && !read) );  // We cannot accept  data after this cycle

function void update_from_bus;
    for(int i = 0; i < ROB_ENTRIES; i++) begin
        if(used_mask_q[i]) begin
            for(int k = 0; k < NUM_CDB_INPUTS; k++) begin
                if(common_data_bus_i.data_lanes[k].valid && common_data_bus_i.data_lanes[k].ROB_dest == i) begin
                    memory_d[i].val = common_data_bus_i.data_lanes[k].data;
                    memory_d[i].rdy = 1'b1;
                    break;
                end
            end
        end
    end
endfunction

`ifdef DEBUG_MSG
// use negedge to wait for logic to be
// calculated for this clock cycle
always @(negedge clk) begin
    if(read && memory_q[read_addr_q].br) begin
        $display("[%t]: (%m): committing branch from PC %X (%X), Destination %X (%X)",
                 $time,
                 memory_q[read_addr_q].pc, memory_q[read_addr_q].pc + 32'h80000000 - 32'h60,
                 branch_pc_o, branch_pc_o + 32'h80000000 - 32'h60);
        if(fls_o) begin
            $display("[%t]: (%m): Branch is being TAKEN, FLUSHING", $time);
        end else begin
            $display("[%t]: (%m): Branch is NOT TAKEN", $time);
        end
    end
    if(write) begin
        automatic logic [32-1:0] calc_pc = memory_d[write_addr_q].pc + memory_d[write_addr_q].b_imm;
        $display("[%t]: (%m): receiving branch from PC %X (%X), Destination %X (%X)",
                 $time,
                 memory_d[write_addr_q].pc, memory_d[write_addr_q].pc + 32'h80000000 - 32'h60,
                 calc_pc, calc_pc + 32'h80000000 - 32'h60);
    end
end
always @(negedge clk) begin
    if(branch_pc_o != 0 || (br_count_o != br_count_d)) begin
        $display("[%t]: (%m): Branch Count == %d", $time, br_count_o);
        $display("[%t]: (%m): Count Will Be   %d", $time, fls_o ? '0 : br_count_d);
    end
end
`endif

always_comb begin
    memory_d     = memory_q;
    used_mask_d  = used_mask_q;
    read_addr_d  = read_addr_q;
    write_addr_d = write_addr_q;
    br_count_d   = br_count_o;
    branch_pc_o = '0;
    jalr_pc_o = '0;
    br_count_inc = '0;
    br_count_dec = '0;
    br_commit_o  = '0;
    commit_o     = '0;
    speculate_o  = '0;
    load_branch_o = '0;
    load_jalr_o = '0;
    fls_o        = '0;
    for(int i = 0; i < ISSUE_WIDTH; i++) begin
        commit_idx_o[i] = '0;
        speculate_val_o[i] = '0;
        speculate_idx_o[i] = '0;
        commit_val_o[i] = '0;
        commit_rob_idx_o[i] = '0;
    end

    update_from_bus();

    if(read) begin
        // Tell the RegFile which entry we are committing:
        commit_rob_idx_o[0] = read_addr_q;

        read_addr_d = read_addr_q + 1'b1;
        // Mark this element as free
        used_mask_d[read_addr_q] = 1'b0;

        if(memory_q[read_addr_q].br) begin
            br_count_dec = 1'b1;
            br_commit_o = 1'b1;


            if(memory_q[read_addr_q].jal) begin
                commit_idx_o[0] = memory_q[read_addr_q].dest_reg;
                commit_val_o[0] = memory_q[read_addr_q].pc + 3'd4;
                commit_o[0] = 1'b1;
                
                branch_pc_o = memory_q[read_addr_q].val;
                load_branch_o = 1'b1;

                fls_o = 1'b1;
            end
            else if(memory_q[read_addr_q].jalr) begin
                commit_idx_o[0] = memory_q[read_addr_q].dest_reg;
                commit_val_o[0] = memory_q[read_addr_q].pc + 3'd4;
                commit_o[0] = 1'b1;

                jalr_pc_o = memory_q[read_addr_q].val;
                load_jalr_o = 1'b1;

                fls_o = 1'b1;
            end
            else begin
                if(memory_q[read_addr_q].val[0] == 1'b1) begin
                    branch_pc_o = memory_q[read_addr_q].pc + memory_q[read_addr_q].b_imm;
                    load_branch_o = 1'b1;
                end

                if(memory_q[read_addr_q].val[0] != memory_q[read_addr_q].expected_result) begin
                    //set_flush_vector();
                    fls_o = 1'b1;
                end
            end
        end
        else begin
            commit_idx_o[0] = memory_q[read_addr_q].dest_reg;
            commit_val_o[0] = memory_q[read_addr_q].val;
            commit_o[0] = 1'b1;
        end
    end

    if(write) begin
        // TODO: Add multi-issue support, currently just single issue

        write_addr_d = write_addr_q + 1'b1;
        // Read in the data and mark the spot as full
        memory_d[write_addr_q] = data_i[0];
        used_mask_d[write_addr_q] = 1'b1;

        if(data_i[0].br && ~data_i[0].jal) begin
            br_count_inc = 1'b1;
        end
        else begin
            speculate_idx_o[0] = data_i[0].dest_reg;
            speculate_val_o[0] = write_addr_q; // This should be the current ROB index
            speculate_o[0] = 1'b1;
        end
    end

    br_count_d = br_count_o + br_count_inc - br_count_dec;

end

always_ff @(posedge clk) begin
    memory_q     <= memory_d;
    used_mask_q  <= used_mask_d;
    read_addr_q  <= read_addr_d;
    write_addr_q <= write_addr_d;
    rdy_i[0]     <= rdy_d; // TODO: Width
    br_count_o   <= br_count_d;
    if(rst | fls_o) begin
        used_mask_q  <= '0;
        read_addr_q  <= '0;
        write_addr_q <= '0;
        rdy_i        <= '0;
        br_count_o   <= '0;
    end
end

endmodule : reorder_buffer
