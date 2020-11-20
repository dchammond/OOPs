
import rv32i_types::*;
import oops_structs::*;

module iq_tests;
    `timescale 1ns/10ps

    bit clk;
    always #0.5 clk = clk === 1'b0;
    default clocking tb_clk @(posedge clk); endclocking

    logic  rst;

    parameter WIDTH = 32;

    logic flush;

    // Unit Test the Instruction Queue:
    logic [3:0] rob_dest_i;

    reg_bus_t   reg_bus_i;
    regfile_element_t e1;
    regfile_element_t e2;

    logic             rdy_i;
    logic             vld_i;
    instruction_element_t instruction_i;

    logic             vld_o;
    logic             rdy_o;
    instruction_element_t instruction_o;

    // Instantiate Queue:
    instruction_queue iq (.*);


    initial begin : QUEUE_TEST_VECTORS

        rst   = 1'b1;
        vld_i = 1'b0;
        rdy_o = 1'b0;
        ##1;
        rst   = 1'b0;
        ##1;
        rob_dest_i = 4'b0001;
        e1.data = 32'h0000000E;
        e1.CB = 1'b0;
        reg_bus_i.reg_data[1] = e1;
        e2.data = 32'hDEADBEEF;
        e2.CB = 1'b1;
        reg_bus_i.reg_data[2] = e2;

        instruction_i.instruction = imm_add;
        instruction_i.CB1 = 1'b1;
        instruction_i.CB2 = 1'b1;
        instruction_i.val1 = 32'h00000002;
        instruction_i.val2 = 32'h00000001;
        instruction_i.dest_reg = 5'b00100;
        instruction_i.ROB_dest = '0;
        instruction_i.branch = '0;
        instruction_i.b_imm = '0;
        instruction_i.pc = 32'h00000060;

        vld_i = 1'b1;
        ##1;
        vld_i = 1'b0;


        rdy_o = 1'b1;
        #1
        assert(instruction_o.val1 == 32'hDEADBEEF);
        ##1;
        rdy_o = 1'b0;
        ##1
        assert (vld_o == 1'b0);


        $display("DONE!");
        $finish();

    end : QUEUE_TEST_VECTORS

endmodule
