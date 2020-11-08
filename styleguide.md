# Style Guide
Basic layout of a module:

```verilog
`include "library.sv"

module mp4
#(
    .PARAM     = 1,
    .LONG_NAME = 2,
    .SHORT     = 3
)
(
    input                    clk,
    input                    rst,

    input  logic             data_read_i,
    input  logic [SHORT-1:0] something_else_i,
    output logic [   32-1:0] related_signal_o,

    output logic             okay_o
);

enum unsigned {
    STATE1,
    STATE2,
    STATE3
} state_d, state_q;

// _d indicates combinational values
// _q indicates register values
logic combinational_d, combinational_q;
logic related_comb_d,  related_comb_q;

logic [SHORT-1:0] unrelated_comb_d,  unrelated_comb_q;
logic             related_control_d, related_control_q;

generate : helpful_name
    // If you have code that only exists in certain cases of PARAMTER values,
    // set it up in a generate block
    if(LONG_NAME != 7) begin
        // ..
    end
endgenerate : helpful_name

// Outputs should typically be assigned to a register value
// It is also okay to directly assign to the output value in
// the always_ff block, but I prefer this method
// Small logic is also okay, but only read from _q variables
assign okay_o = related_control_q & related_comb_q;

// If there is only one always_comb block, a name is not necessary
always_comb begin : state_logic
    // 1. Set up defaults to prevent latching
    state_d           = state_q;
    combinational_d   = combinational_q;
    related_comb_d    = related_comb_q;
    unrelated_comb_d  = '0;
    related_control_d = related_control_q;

    // 2. switch-case
    unique case(state_d)
    STATE1 : begin
        combinational_d  = data_read_i;
        something_else_i = 3'd2;
        state_d          = STATE2;    // ONLY write to _d signals in always_comb
    end
    STATE2 : begin
        if(unrelated_comb_q) begin    // ONLY read from _q signals and inputs in always_comb
            related_control_d = 1'b1; // used sized values in non-zeroing cases
        end
    end
    STATE3 : begin
        for(int i = 0; i < SHORT; i++) begin
            unrelated_comb_d[i] = i < PARAM; // this is valid code
        end
    end
    endcase
    // 3. you are done
end

// If you have entirely unrelated logic from the normal state-controlled logic
// make another always_comb block to signify this
always_comb begin : helpful_name
    // ...
end

// If you are using other modules they should either go here or before the always_comb blocks
// depending on what you think makes sense
cache_controller
#(
    .PARAM      (PARAM)
)
cache_control
(
    .clk        (clk),
    .rst        (rst),

    // ...
    // Avoid using .* notation, it makes grep not work
);

always_ff @(posedge clk) begin
    // NO LOGIC should occur in the always_ff block
    // (sometimes a small if statement is acceptable)
    state_q          <= state_d;

    combinational_q  <= combinational_d;
    related_comb_q   <= related_comb_d;

    unrelated_comb_q <= unrelated_comb_d;
    related_comb_q   <= related_comb_d;

    // Put rst case at end to override earlier lines of code
    if(rst) begin
        state_q           <= STATE1;
        related_control_q <= '0;
        // only "control" signals should need to be reset
        // always reset with '0 unless its an enum
    end
end

endmodule : mp4
```
