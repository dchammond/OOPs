module cacheline_adaptor
(
    input                   clk,
    input                   rst,

    // Port to LLC (Lowest Level Cache)
    input  logic [   255:0] line_i,
    output logic [   255:0] line_o,
    input  logic [    31:0] address_i,
    input                   read_i,
    input                   write_i,
    output logic            resp_o,

    // Port to memory
    input  logic [    63:0] burst_i,
    output logic [    63:0] burst_o,
    output logic [    31:0] address_o,
    output logic            read_o,
    output logic            write_o,
    input                   resp_i
);

typedef enum {
    IDLE,
    READ_LINE1,
    READ_LINE2,
    READ_LINE3,
    READ_LINE4,
    READ_FINISH,
    WRITE_START,
    WRITE_LINE1,
    WRITE_LINE2,
    WRITE_LINE3,
    WRITE_LINE4,
    WRITE_FINISH
} state_t;

state_t            state_d, state_q;

logic [3:0][ 63:0] line_build_d;
logic [3:0][ 63:0] line_build_q;

assign address_o = address_i;
assign line_o = { line_build_q[3], line_build_q[2], line_build_q[1], line_build_q[0] };

always_comb begin
    state_d      = state_q;
    line_build_d = line_build_q;
    resp_o       = '0;
    burst_o      = '0;
    read_o       = '0;
    write_o      = '0;
    
    case(state_q)
    IDLE, READ_FINISH, WRITE_FINISH : begin
        if(state_q == READ_FINISH || state_q == WRITE_FINISH) begin
            resp_o   = 1'b1;
            state_d  = IDLE;
        end else begin
            if(read_i) begin
                read_o       = 1'b1;
                line_build_d = '0;
                state_d      = READ_LINE1;
            end else if(write_i) begin
                write_o         = 1'b1;
                line_build_d[0] = line_i[64*0+:64];
                line_build_d[1] = line_i[64*1+:64];
                line_build_d[2] = line_i[64*2+:64];
                line_build_d[3] = line_i[64*3+:64];
                state_d         = WRITE_LINE1;
            end
        end
    end
    READ_LINE1 : begin
        if(resp_i) begin
            state_d = READ_LINE2;
        end
        read_o          = 1'b1;
        line_build_d[0] = burst_i;
    end
    READ_LINE2 : begin
        if(resp_i) begin
            state_d = READ_LINE3;
        end
        read_o          = 1'b1;
        line_build_d[1] = burst_i;
    end
    READ_LINE3 : begin
        if(resp_i) begin
            state_d = READ_LINE4;
        end
        read_o          = 1'b1;
        line_build_d[2] = burst_i;
    end
    READ_LINE4 : begin
        if(resp_i) begin
            state_d = READ_FINISH;
        end
        read_o          = 1'b1;
        line_build_d[3] = burst_i;
    end
    WRITE_LINE1 : begin
        if(resp_i) begin
            state_d = WRITE_LINE2;
        end
        write_o     = 1'b1;
        burst_o     = line_build_q[0];
    end
    WRITE_LINE2 : begin
        if(resp_i) begin
            state_d = WRITE_LINE3;
        end
        write_o     = 1'b1;
        burst_o     = line_build_q[1];
    end
    WRITE_LINE3 : begin
        if(resp_i) begin
            state_d = WRITE_LINE4;
        end
        write_o     = 1'b1;
        burst_o     = line_build_q[2];
    end
    WRITE_LINE4 : begin
        if(resp_i) begin
            state_d = WRITE_FINISH;
        end
        write_o     = 1'b1;
        burst_o     = line_build_q[3];
    end
    endcase
end

always_ff @(posedge clk) begin
    state_q      <= state_d;
    line_build_q <= line_build_d;
    if(rst) begin
        state_q <= IDLE;
    end
end

endmodule : cacheline_adaptor
