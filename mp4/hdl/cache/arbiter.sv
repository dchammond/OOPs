
module arbiter
(
    input                clk,
    input                rst,
    input                fls,

    // To Cacheline Adaptor
    input  logic [255:0] arbiter_rdata_i,
    output logic [255:0] arbiter_wdata_o,
    output logic [ 31:0] arbiter_addr_o,
    output logic         arbiter_read_o,
    output logic         arbiter_write_o,
    input  logic         arbiter_resp_i,

    // To D-Cache
    output logic [255:0] d_mem_rdata_o,
    input  logic [255:0] d_mem_wdata_i,
    input  logic [ 31:0] d_mem_addr_i,
    input  logic         d_mem_read_i,
    input  logic         d_mem_write_i,
    output logic         d_mem_resp_o,

    // To I-Cache
    output logic [255:0] i_mem_rdata_o,
    input  logic [ 31:0] i_mem_addr_i,
    input  logic         i_mem_read_i,
    output logic         i_mem_resp_o
);

logic [255:0] arbiter_data_d, d_mem_data_d, i_mem_data_d;
logic [255:0] arbiter_data_q, d_mem_data_q, i_mem_data_q;
logic [31:0] arbiter_addr_d;
logic [31:0] arbiter_addr_q;

enum logic [2:0] {
    BEGIN,
    IDLE,
    D_MEM_READ,
    D_MEM_WRITE,
    I_MEM
} state_d, state_q;


always_comb begin : state_actions
    arbiter_wdata_o = arbiter_data_q;
    arbiter_addr_o  = arbiter_addr_q;
    arbiter_read_o  = 1'b0;
    arbiter_write_o = 1'b0;

    d_mem_rdata_o = d_mem_data_q;
    d_mem_resp_o  = 1'b0;

    i_mem_rdata_o = i_mem_data_q;
    i_mem_resp_o  = 1'b0;

    arbiter_data_d = arbiter_data_q;
    arbiter_addr_d = arbiter_addr_q;
    d_mem_data_d   = d_mem_data_q;
    i_mem_data_d   = i_mem_data_q;

    case (state_q)
        BEGIN: begin

        end
        IDLE: begin

        end
        D_MEM_READ: begin
            arbiter_addr_d = d_mem_addr_i;
            arbiter_addr_o = arbiter_addr_d;
            d_mem_rdata_o  = arbiter_rdata_i;
            d_mem_data_d   = arbiter_rdata_i;
            arbiter_read_o = 1'b1;

            d_mem_resp_o = arbiter_resp_i;
        end
        D_MEM_WRITE: begin
            arbiter_addr_d = d_mem_addr_i;
            arbiter_addr_o = arbiter_addr_d;
            arbiter_wdata_o = d_mem_wdata_i;
            arbiter_write_o = 1'b1;

            d_mem_resp_o = arbiter_resp_i;
        end
        I_MEM: begin
            arbiter_addr_d = i_mem_addr_i;
            arbiter_addr_o = arbiter_addr_d; 
            i_mem_rdata_o  = arbiter_rdata_i;
            i_mem_data_d   = arbiter_rdata_i;
            i_mem_resp_o   = arbiter_resp_i;
            arbiter_read_o = 1'b1;
        end
    endcase


end

always_comb begin : next_state_logic
    state_d = state_q;

    case (state_q)
        BEGIN: begin
            if (arbiter_resp_i) begin
                state_d = IDLE;
            end
        end
        IDLE: begin
            if (i_mem_read_i) begin
                state_d = I_MEM;
            end else if (d_mem_read_i) begin
                state_d = D_MEM_READ;
            end else if (d_mem_write_i) begin
                state_d = D_MEM_WRITE;
            end
        end
        D_MEM_READ, D_MEM_WRITE: begin
            if (arbiter_resp_i) begin
                if (i_mem_read_i) begin
                    state_d = I_MEM;
                end else begin
                    state_d = IDLE;
                end
            end
        end
        I_MEM: begin
            if (arbiter_resp_i) begin
                if (d_mem_read_i) begin
                    state_d = D_MEM_READ;
                end else if (d_mem_write_i) begin
                    state_d = D_MEM_WRITE;
                end else begin
                    state_d = IDLE;
                end
            end
        end
    endcase
end

always_ff @(posedge clk) begin
    state_q        <= state_d;
    arbiter_data_q <= arbiter_data_d;
    arbiter_addr_q <= arbiter_addr_d;
    d_mem_data_q   <= d_mem_data_d;
    i_mem_data_q   <= i_mem_data_d;
    if(fls) begin
        if(state_q != IDLE) begin
            state_q <= BEGIN; // State where we throw away the current memory that is being fetched.
        end
    end
    if (rst) begin
        state_q        <= IDLE;
        arbiter_data_q <= '0;
        arbiter_addr_q <= '0;
        d_mem_data_q   <= '0;
        i_mem_data_q   <= '0;
    end
end

endmodule : arbiter
