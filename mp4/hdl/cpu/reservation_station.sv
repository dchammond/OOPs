// ECE411 Final Project: OOPs
// Caleb Gerth cdgerth2
// Dillon Hammond dillonh2
// Jonathan Paulson paulson5

import rv32i_types::*;
import oops_structs::*;

module reservation_station
#(
    DEPTH       = 2,
    WRITE_COUNT = 2,
    READ_COUNT  = 6
)
(
    input                          clk,
    input                          rst,

    input  common_data_bus_t       common_data_bus_i,

    input  logic [WRITE_COUNT-1:0] vld_i,
    output logic [WRITE_COUNT-1:0] rdy_i,
    input  instruction_element_t   data_i [WRITE_COUNT],

    output logic [ READ_COUNT-1:0] vld_o,
    input  logic [ READ_COUNT-1:0] rdy_o,
    output reservation_station_element_t data_o [READ_COUNT]
);

// If we have more readers than writers, readers
// will have to be saturated by additional DEPTH
localparam MAX_COUNT = WRITE_COUNT;

generate
    if(READ_COUNT < WRITE_COUNT) begin
        greater_than_or_equal_to_write_count cannot_have_read_count();
    end
endgenerate

// MAX_COUNT rows
// DEPTH columns
reservation_station_element_t [DEPTH-1:0] memory_d [MAX_COUNT];
reservation_station_element_t [DEPTH-1:0] memory_q [MAX_COUNT];

reservation_station_element_t data_d [READ_COUNT];

logic [DEPTH-1:0] used_mask_d [MAX_COUNT];
logic [DEPTH-1:0] used_mask_q [MAX_COUNT];

logic [WRITE_COUNT-1:0] rdy_d, rdy_q;
logic [ READ_COUNT-1:0] vld_d, vld_q;

/* not sure if we will need these */
logic [MAX_COUNT-1:0] empty;
logic [MAX_COUNT-1:0] full;

logic [DEPTH-1:0] ready_instr [MAX_COUNT];

function void update_from_bus;
    for(int i = 0; i < MAX_COUNT; i++) begin
        for(int j = 0; j < DEPTH; j++) begin
            if(common_data_bus_i.fls) begin
                // For now we flush everything
                //if(used_mask_q[i][j] && common_data_bus_i.fls_vector[memory_q[i][j].rob_dest]) begin
                used_mask_d[i][j]   = 1'b0;
                //end
            end
        end
    end
    for(int i = 0; i < MAX_COUNT; i++) begin
        for(int j = 0; j < DEPTH; j++) begin
            if(used_mask_q[i][j]) begin
                if(memory_q[i][j].CB1) begin
                    for(int k = 0; k < NUM_CDB_INPUTS; k++) begin
                        if(common_data_bus_i.data_lanes[k].valid) begin
                            if(common_data_bus_i.data_lanes[k].ROB_dest == memory_q[i][j].val1[ROB_IDX_LEN-1:0]) begin
                                memory_d[i][j].val1[31:0] = common_data_bus_i.data_lanes[k].data[31:0];
                                memory_d[i][j].CB1  = 1'b0;
                            end
                        end
                    end
                end
                if(memory_q[i][j].CB2) begin
                    for(int k = 0; k < NUM_CDB_INPUTS; k++) begin
                        if(common_data_bus_i.data_lanes[k].valid) begin
                            if(common_data_bus_i.data_lanes[k].ROB_dest == memory_q[i][j].val2[ROB_IDX_LEN-1:0]) begin
                                memory_d[i][j].val2[31:0] = common_data_bus_i.data_lanes[k].data[31:0];
                                memory_d[i][j].CB2  = 1'b0;
                            end
                        end
                    end
                end
            end
        end
    end
endfunction

function void setup_common_signals;
    for(int i = 0; i < MAX_COUNT; i++) begin
        full[i]  = ~(&(used_mask_q[i]));
        empty[i] = ~(|(used_mask_q[i]));
        for(int j = 0; j < DEPTH; j++) begin
            ready_instr[i][j] = used_mask_q[i][j] && (!memory_q[i][j].CB1 && !memory_q[i][j].CB2);
        end
    end
endfunction

function void do_reads;
    /* do order based scan to find instructions to issue */
    /* right now this is doing some very linear logic */
    /* if it becomes a chokepoint I'll need to optimize it */
    /* also the way this is traversing our matrix of instructions */
    /* is definitely not "fair" so we may leave some rows full with */
    /* ready instructions until they are what's blocking new */
    /* instructions from being issued */
    /* ideally we have so many readers/execution units that we don't */
    /* stall out on executing */
    for(int i = 0; i < MAX_COUNT; i++) begin
        for(int j = 0; j < DEPTH; j++) begin
            if(ready_instr[i][j]) begin
                for(int k = 0; k < READ_COUNT; k++) begin
                    /* yes I'm reading vld_d */
                    /* it's the only way to know if a reader is used */
                    /* because we have to decide which instruction */
                    /* will be sent to the reader, we cannot respond */
                    /* to a rdy request until the next cycle */
                    if(rdy_o[k] && !vld_d[k]) begin
                        vld_d[k] = 1'b1;
                        used_mask_d[i][j] = 1'b0;
                        data_d[k] = memory_q[i][j];
                    end
                end
            end
        end
    end
endfunction

function void do_writes;
    /* we always have the same number of writers and rows */
    /* keep it simple, if a writer's row has a free space */
    /* then that means it can write, else block the writer */
    /* if writers tend to get stalled, increase DEPTH */
    for(int i = 0; i < MAX_COUNT; i++) begin
        if(vld_i[i] && !rdy_d[i]) begin
            for(int j = 0; j < DEPTH; j++) begin
                if(!used_mask_q[i][j]) begin
                    automatic reservation_station_element_t e;
                    e.CB1                       = data_i[i].CB1;
                    e.CB2                       = data_i[i].CB2;
                    e.val1[31:0]                = data_i[i].val1[31:0];
                    e.val2[31:0]                = data_i[i].val2[31:0];
                    e.op                        = data_i[i].instruction;
                    e.rob_dest[ROB_IDX_LEN-1:0] = data_i[i].ROB_dest[ROB_IDX_LEN-1:0];
                    rdy_d[i]                    = 1'b1;
                    used_mask_d[i][j]           = 1'b1;
                    memory_d[i][j]              = e;
                    break;
                end
            end
        end
    end
endfunction

always_comb begin
    memory_d    = memory_q;
    used_mask_d = used_mask_q;
    rdy_d       = '0;
    vld_d       = '0;
    
    for(int i = 0; i < READ_COUNT; i++) begin
        data_d[i] = '0;
    end

    update_from_bus();
    if(!common_data_bus_i.fls) begin
        setup_common_signals();
        do_reads();
        do_writes();
    end

    /* if we get a flush, we are either flushing an instruction that was */
    /* going to be read (so used_mask is already 0) or flushing an */
    /* instruction in the memory which is handled in update_from_bus */
    /* so we do not need special logic on used_mask here */
    for(int i = 0; i < READ_COUNT; i++) begin
        //vld_o[i] = vld_q[i] && ~(common_data_bus_i.fls && common_data_bus_i.fls_vector[data_o[i].rob_dest]);
        vld_o[i] = vld_q[i] && ~(common_data_bus_i.fls);
    end

    /* if we have a flush on this cycle, we have already latched in the */
    /* write data that this set of rdy_i signals is referring too */
    /* therefore we should still tell the writers that we acknowledge */
    /* the write they were trying to make, used_mask will be cleared in */
    /* update_from_bus */
    rdy_i = rdy_q;
end

always_ff @(posedge clk) begin
    memory_q    <= memory_d;
    used_mask_q <= used_mask_d;
    rdy_q       <= rdy_d;
    vld_q       <= vld_d;
    data_o      <= data_d;
    if(rst) begin
        for(int i = 0; i < MAX_COUNT; i++) begin
            used_mask_q[i] <= '0;
        end
        rdy_q       <= '0;
        vld_q       <= '0;
    end
end

endmodule : reservation_station
