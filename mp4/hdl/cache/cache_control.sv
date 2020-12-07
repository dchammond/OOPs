module cache_control (
    input clk,
    input rst,

    /* CPU to Control */
    input logic mem_read,
    input logic mem_write,
    input logic [31:0] mem_byte_enable256,
    
    /* Control to CPU */
    output logic mem_resp,

    /* Control to Memory */
    output logic pmem_read,
    output logic pmem_write,

    /* Memory to Control */
    input logic pmem_resp,

    /* Datapath to Control */
    input logic way0_dirty,
    input logic way0_valid,
    input logic way1_dirty,
    input logic way1_valid,
    input logic lru_out,
    input logic hit_out,
    input logic way1_hit,

    /* Control to Datapath */
    output data_in_mux::datainmux_sel_t data_in_mux_sel,
    output data_out_mux::dataoutmux_sel_t data_out_mux_sel,
    output mem_address_mux::memaddressmux_sel_t mem_address_mux_sel,
    output logic [31:0] mem_en0,
    output logic [31:0] mem_en1,
    output logic d_bit,
    output logic v_bit,
    output logic read_lru,
    output logic load_lru,
    output logic read_tag,
    output logic load_tag0,
    output logic load_tag1,
    output logic read_dirty,
    output logic load_dirty0,
    output logic load_dirty1,
    output logic read_valid,
    output logic load_valid0,
    output logic load_valid1,
    output logic read_data
    //output logic load_pmar
);

enum int unsigned {
    /* List of states */
    lookup_1,
    lookup_2,
    evict,
    miss
} state, next_states;

function void set_defaults();
    mem_resp = 0;
    pmem_read = 1'b0;
    pmem_write = 1'b0;
    data_in_mux_sel = data_in_mux::cpu_in;
    data_out_mux_sel = data_out_mux::way0;
    mem_address_mux_sel = mem_address_mux::mem_in;
    mem_en0 = 31'b0;
    mem_en1 = 31'b0;
    read_lru = 1'b0;
    load_lru = 1'b0;
    read_tag = 1'b0;
    load_tag0 = 1'b0;
    load_tag1 = 1'b0;
    read_dirty = 1'b0;
    load_dirty0 = 1'b0;
    load_dirty1 = 1'b0;
    read_valid = 1'b0;
    load_valid0 = 1'b0;
    load_valid1 = 1'b0;
    read_data = 1'b0;
    d_bit = 1'b0;
    v_bit = 1'b0;
    //load_pmar = 1'b0;
endfunction

/*
function void loadPMAR(mem_address_mux::memaddressmux_sel_t sel);
	 load_pmar = 1'b1;
	 mem_address_mux_sel = sel;
endfunction
*/

always_comb
begin : state_actions
    /* Default output assignments */
	set_defaults();

    /* Actions for each state */
	case (state)
        lookup_1:
        begin
            read_lru = 1'b1;
            read_tag = 1'b1;
            read_valid = 1'b1;
            read_dirty = 1'b1;
            read_data = 1'b1;
        end
        lookup_2:
        begin
            if(hit_out==1 && mem_read==1) begin
                load_lru = 1'b1;
                mem_resp = 1'b1;
            end else if(hit_out==1 && mem_write==1) begin
                load_lru = 1'b1;
                data_in_mux_sel = data_in_mux::cpu_in;
                d_bit = 1'b1;
                mem_resp = 1'b1;
                if(way1_hit==0) begin
                    mem_en0 = mem_byte_enable256;
                    load_tag0 = 1'b1;
                    load_dirty0 = 1'b1;
                end else begin
                    mem_en1 = mem_byte_enable256;
                    load_tag1 = 1'b1;
                    load_dirty1 = 1'b1;
                end
            end
        end
        evict:
        begin
            mem_address_mux_sel = mem_address_mux::memaddressmux_sel_t'({1'b0, lru_out});
            data_out_mux_sel = data_out_mux::dataoutmux_sel_t'(lru_out);
            pmem_write = ~pmem_resp;
        end
        miss:
        begin
            mem_address_mux_sel = mem_address_mux::mem_in;
            pmem_read = ~pmem_resp;
            data_in_mux_sel = data_in_mux::pmem_in;
            d_bit = 1'b0;
            v_bit = 1'b1;
            if(pmem_resp==1) begin
                if(lru_out==0) begin
                    mem_en0 = 32'hFFFFFFFF;
                    load_tag0 = 1'b1;
                    load_dirty0 = 1'b1;
                    load_valid0 = 1'b1;
                end else begin
                    mem_en1 = 32'hFFFFFFFF;
                    load_tag1 = 1'b1;
                    load_dirty1 = 1'b1;
                    load_valid1 = 1'b1;
                end
            end
        end
    endcase
end

always_comb
begin : next_state_logic
    /* Next state information and conditions (if any)
     * for transitioning between states */
	next_states = state;
	unique case (state)
        lookup_1:
        begin
            if((mem_read==0 && mem_write==0) || pmem_resp==1)
                next_states = lookup_1;
            else
                next_states = lookup_2;
        end
        lookup_2:
        begin
            if(hit_out==1) begin
                next_states = lookup_1;
            end else if(lru_out==1'b0) begin
                if(way0_valid==1'b1 && way0_dirty==1'b1) begin
                    next_states = evict;
                end else if(way0_valid==1'b0 || (way0_valid==1'b1 && way0_dirty==1'b0)) begin
                    next_states = miss;
                end
            end else if(lru_out==1'b1) begin
                if(way1_valid==1'b1 && way1_dirty==1'b1) begin
                    next_states = evict;
                end else if(way1_valid==1'b0 || (way1_valid==1'b1 && way1_dirty==1'b0)) begin
                    next_states = miss;
                end
            end
        end
        evict:
        begin
            if(pmem_resp != 1)
                next_states = evict;
            else
                next_states = miss;
        end
        miss:
        begin
            if(pmem_resp != 1)
                next_states = miss;
            else
                next_states = lookup_1;
        end
        default: ;
	endcase
end

always_ff @(posedge clk)
begin: next_state_assignment
	/* Assignment of next state on clock edge */
	if (rst)
		state <= lookup_1;
	else
		state <= next_states;
end

endmodule : cache_control
