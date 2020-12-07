// ECE411 Final Project: OOPs
// Caleb Gerth cdgerth2
// Dillon Hammond dillonh2
// Jonathan Paulson paulson5

// Tests to Choose From: (Might not be deterministic if you choose more than one.)
// `define generic_queue
// `define address_unit
// `define reg_file
// `define data_interface
`define reservation_station


import rv32i_types::*;
import oops_structs::*;

module unit_tests;
    `timescale 1ns/10ps

    bit clk;
    always #0.5 clk = clk === 1'b0;

    logic  rst;


    function common_data_bus_t makeResultAvailableCDB
    (
        bit [           31:0] data_i,
        bit [ROB_IDX_LEN-1:0] ROB_dest_i,
        int lane_i
    );
        common_data_bus_t cdb_o;
        cdb_o.data_lanes[lane_i].data       = data_i;
        cdb_o.data_lanes[lane_i].ROB_dest   = ROB_dest_i;
        cdb_o.data_lanes[lane_i].valid      = 1'b1;
        return cdb_o;
    endfunction 


`ifdef generic_queue    
    parameter WIDTH = 32;

    // Unit Test the Generic Queue:
    logic             rdy_i;
    logic             vld_i;
    logic [WIDTH-1:0] data_i;

    logic             vld_o;
    logic             rdy_o;
    logic [WIDTH-1:0] data_o;

    // Instantiate Queue:
    queue queue (.*);


    initial begin : QUEUE_TEST_VECTORS

        rst   = 1'b1;
        vld_i = 1'b0;
        rdy_o = 1'b0;
        #4;
        rst   = 1'b0;
        #4;

        for (int i = 0; i < 16; i++) begin
            assert(rdy_i == 1'b1);
            data_i = i;
            vld_i = 1'b1;
            #2;
            vld_i = 1'b0; // This is most likely redundant
        end

        assert(rdy_i == 1'b0);
        // Try to enqueue something past max.
        data_i = 32'hdeadbeef;
        vld_i = 1'b1;
        #2;
        vld_i = 1'b0;
        #2;

        for (int i = 0; i < 16; i++) begin
            assert(vld_o == 1'b1);
            rdy_o = 1'b1;
            assert(data_o == i);
            #2;
            rdy_o = 1'b0; // This is most likely redundant
        end

        assert (vld_o == 1'b0); // Make sure we know it's empty.

        // Single Element Test:
        #6;
        data_i = 32'd34;
        vld_i = 1'b1;
        #2;
        vld_i = 1'b0;
        #2;
        rdy_o = 1'b1;
        assert(data_o == 32'd34);
        #2;
        rdy_o = 1'b0;
        #6;

        // Simultaneous Read-Write Tests
        // No Elements:
        data_i = 32'd25;
        vld_i = 1'b1;
        rdy_o = 1'b1;
        #2;
        assert(data_o == 32'd25);
        vld_i = 1'b0;
        rdy_o = 1'b0;
        assert (vld_o == 1'b1); // Make sure we know it's not empty (bc the read should have failed).
        assert (rdy_i == 1'b1); // Make sure we know it is ready to accept input.
        #6;

        // One Element:
        data_i = 32'd26;
        vld_i = 1'b1;
        #2;
        vld_i = 1'b0;

        data_i = 32'd27;
        vld_i = 1'b1;
        rdy_o = 1'b1;
        #2;
        assert(data_o == 32'd26);
        vld_i = 1'b0;
        rdy_o = 1'b0;
        assert (vld_o == 1'b1); // Make sure we know it's got one element.
        assert (rdy_i == 1'b1); // Make sure we know it is ready to accept input.
        #6;

        // One Less Than Full:
        for (int i = 0; i < 14; i++) begin
            assert(rdy_i == 1'b1);
            data_i = i;
            vld_i = 1'b1;
            #2;
            vld_i = 1'b0; // This is most likely redundant
        end

        data_i = 32'd28;
        vld_i = 1'b1;
        rdy_o = 1'b1;
        #2;
        assert(data_o == 32'd27);
        vld_i = 1'b0;
        rdy_o = 1'b0;
        assert (vld_o == 1'b1); // Make sure we know it still has elements.
        assert (rdy_i == 1'b1); // Make sure we know it is ready to accept input.
        #6;

        // Full:
        data_i = 32'd33;
        vld_i = 1'b1;
        #2;
        vld_i = 1'b0;

        data_i = 32'd29;
        vld_i = 1'b1;
        rdy_o = 1'b1;
        assert(data_o == 32'd27);
        #2;
        vld_i = 1'b0;
        rdy_o = 1'b0;
        assert (vld_o == 1'b1); // Make sure we know it's got elements.
        assert (rdy_i == 1'b1); // Make sure we know it is ready to accept input because it denied the input that we just gave it.
        #6;

        $display("DONE!");
        $finish();

    end : QUEUE_TEST_VECTORS

`endif 

`ifdef address_unit

    // Address Unit Inputs:
    logic                    BR_commit_i;
    common_data_bus_t        common_data_bus_i;
    logic                    vld_i;
    logic                    rdy_i;
    address_unit_element_t   address_data_i;
    logic                    vld_o;
    logic                    rdy_o;
    address_buffer_element_t address_data_o;

    // Address unit instantiation:
    address_unit au (.*);

    // Intermediate values:
    address_unit_element_t input0, input1, input2, input3, input4;

    initial begin : init_test_vars
        input0 = setAddressUnitElement(0, 11, 0, 1,  10, w, 0, 7, st);
        input1 = setAddressUnitElement(1,  2, 0, 20, 12, w, 1, 8, ld);
        input2 = setAddressUnitElement(1,  3, 1, 3,  13, w, 2, 9, ld);
        input3 = setAddressUnitElement(1,  4, 1, 5,  14, w, 2, 6, st);
        input4 = setAddressUnitElement(1,  5, 1, 5,  15, w, 3, 5, ld);
    end

    // Helpful Functions
    function address_unit_element_t setAddressUnitElement
    (
        bit                     CB1_i,
        bit [           31:0]   val1_i,
        bit                     CB2_i,
        bit [           31:0]   val2_i,
        bit [           31:0]   imm_i,
        load_store_funct3_t     funct_3_i,
        bit [ROB_IDX_LEN-1:0]   BR_cnt_i,
        bit [ROB_IDX_LEN-1:0]   ROB_dest_i,
        mem_op_t                mem_op_i
    );
        address_unit_element_t data_o;
        data_o.CB1      = CB1_i;
        data_o.CB2      = CB2_i;
        data_o.val1     = val1_i;
        data_o.val2     = val2_i;
        data_o.imm      = imm_i;
        data_o.funct_3  = funct_3_i;
        data_o.BR_cnt   = BR_cnt_i;
        data_o.ROB_dest = ROB_dest_i;
        data_o.mem_op   = mem_op_i;
        return data_o;
    endfunction

    function void printAddressBufferElement
    (
        address_buffer_element_t data_i       
    );
        $display("Address: ",   data_i.addr);
        $display("Data: ",      data_i.data);
        $display("ROB Dest: ",  data_i.ROB_dest);
        $display("Funct3: ",    data_i.funct_3);
        $display("Mem OP: ",    data_i.mem_op);
    endfunction

    function void verifyInOut
    (
        address_buffer_element_t    buffer_data_i,
        address_unit_element_t      unit_data_i
    );
        assert(buffer_data_i.addr       == unit_data_i.imm + unit_data_i.val1);
        assert(buffer_data_i.data       == unit_data_i.val2);
        assert(buffer_data_i.ROB_dest   == unit_data_i.ROB_dest);
        assert(buffer_data_i.funct_3    == unit_data_i.funct_3);
        assert(buffer_data_i.mem_op     == unit_data_i.mem_op);
    endfunction






    initial begin : ADDRESS_UNIT_TEST_VECTORS
        rst = 1'b1;
        BR_commit_i = 1'b0;
        common_data_bus_i = '0;
        vld_i = 1'b0;
        address_data_i = '0;
        rdy_o = 1'b0;
        #2; // Align everything to rising edge.
        rst = 1'b0;
        #8;
        
        // One in, one out test:
        address_data_i = input0;
        vld_i = 1'b1;
        #2;
        vld_i = 1'b0;
        rdy_o = 1'b1;
        verifyInOut(address_data_o, input0);
        #2;
        rdy_o = 1'b0;
        #8;

        // Speculation / ROB Test:
        address_data_i = input0;
        vld_i = 1'b1;
        #2;
        address_data_i = input1;
        #2;
        address_data_i = input2;
        #2;
        address_data_i = input3;
        #2;
        address_data_i = input4;
        #2
        vld_i = 1'b0;
        rdy_o = 1'b1;
        verifyInOut(address_data_o, input0);
        #2;
        rdy_o = 1'b0;
        #2;
        BR_commit_i = 1'b1;
        assert (vld_o == 1'b0); // We shouldn't be able to read since we are speculating.
        #2;
        BR_commit_i = 1'b0;
        rdy_o = 1'b1;
        verifyInOut(address_data_o, input1);
        #2;
        rdy_o = 1'b0;
        assert (vld_o == 1'b0);
        #2;
        // Make the data available.
        common_data_bus_i = makeResultAvailableCDB(31, 2, 0);
        #2;
        common_data_bus_i = '0;
        assert (vld_o == 1'b1);
        rdy_o = 1'b1;
        #2;
        rdy_o = 1'b0;
        assert (vld_o == 1'b0);
        verifyInOut(address_data_o, input2);
        #2;
        common_data_bus_i = makeResultAvailableCDB(31, 3, 0);
        BR_commit_i = 1'b1;
        #2;
        common_data_bus_i = '0;
        BR_commit_i = 1'b0;
        assert (vld_o == 1'b1);
        rdy_o = 1'b1;
        #2;
        rdy_o = 1'b0;
        assert (vld_o == 1'b0);
        verifyInOut(address_data_o, input3);
        #2;
        common_data_bus_i = makeResultAvailableCDB(31, 4, 0);
        common_data_bus_i = makeResultAvailableCDB(31, 5, 1);
        BR_commit_i = 1'b1;
        #2;
        common_data_bus_i = '0;
        BR_commit_i = 1'b0;
        assert (vld_o == 1'b1);
    
    
        #8;

        $display("DONE!");
        $finish();
      
    end : ADDRESS_UNIT_TEST_VECTORS
  
`endif
 
`ifdef reg_file

    parameter ISSUE_WIDTH = 2;
    parameter ROB_IDX_LEN = 4;

    logic                                       fls;

    logic [ISSUE_WIDTH-1:0]                     commit_i;
    logic [ISSUE_WIDTH-1:0]                     speculate_i;
    
    logic [ISSUE_WIDTH-1:0] [ 4:0]              commit_idx_i;
    logic [ISSUE_WIDTH-1:0] [ 4:0]              speculate_idx_i;

    logic [ISSUE_WIDTH-1:0] [31:0]              commit_data_i;
    logic [ISSUE_WIDTH-1:0] [ROB_IDX_LEN-1:0]   speculate_data_i;

    reg_bus_t                                   reg_bus_o;


    register_file 
    #(
        .ISSUE_WIDTH (ISSUE_WIDTH)
    ) regfile 
    (
        .*
    );


    initial begin : REGFILE_TEST_VECTORS

        rst                 = 1'b1;
        fls                 = 1'b0;
        commit_i            = '0;
        speculate_i         = '0;
        commit_idx_i        = '0;
        commit_data_i       = '0;
        speculate_idx_i     = '0;
        speculate_data_i    = '0;
        #2;
        rst                 = 1'b0;
        #2;

        // Single commit_i
        for (int i = 0; i < 32; i++) begin
            commit_idx_i[0]     = 5'(i);
            commit_data_i[0]    = 32'(i*5);
            commit_i[0]         = 1'b1;
            #2;
            assert(reg_bus_o.reg_data[i].data == 32'(i*5));
            assert(reg_bus_o.reg_data[i].CB   == 1'b0);
            commit_i[0]         = 1'b0;
            #2;
        end

        // Double Commit:
        commit_idx_i[0]     = 5'd0;
        commit_idx_i[1]     = 5'd1;
        commit_data_i[0]    = 32'd21;
        commit_data_i[1]    = 32'd31;
        commit_i[0]         = 1'b1;
        commit_i[1]         = 1'b1;
        #2;
        assert(reg_bus_o.reg_data[0].data == 32'd21);
        assert(reg_bus_o.reg_data[0].CB   == 1'b0);
        assert(reg_bus_o.reg_data[1].data == 32'd31);
        assert(reg_bus_o.reg_data[1].CB   == 1'b0);

        commit_i[0]         = 1'b0;
        commit_i[1]         = 1'b0;
        #2;

        // Commit & Speculate the Same Register
        commit_idx_i[0]     = 5'd0;
        commit_idx_i[1]     = 5'd1;
        speculate_idx_i[0]  = 5'd0;
        speculate_idx_i[1]  = 5'd3;
        commit_data_i[0]    = 32'd21;
        commit_data_i[1]    = 32'd31;
        speculate_data_i[0] = 4'd15;
        speculate_data_i[1] = 4'd3;
        commit_i[0]         = 1'b1;
        commit_i[1]         = 1'b1;
        speculate_i[0]      = 1'b1;
        speculate_i[1]      = 1'b1;
        #2;
        assert(reg_bus_o.reg_data[0].CB   == 1'b1  );
        assert(reg_bus_o.reg_data[1].CB   == 1'b0  );
        assert(reg_bus_o.reg_data[3].CB   == 1'b1  );
        assert(reg_bus_o.reg_data[0].data == 32'd15);
        assert(reg_bus_o.reg_data[1].data == 32'd31);
        assert(reg_bus_o.reg_data[3].data == 32'd3 );

        commit_i[0]         = 1'b0;
        commit_i[1]         = 1'b0;
        speculate_i[0]      = 1'b0;
        speculate_i[1]      = 1'b0;

        #2;

        fls = 1'b1;
        #2;
        fls = 1'b0;
        for (int i = 0; i < 32; i++) begin
            assert(reg_bus_o.reg_data[i].CB == 1'b0);
        end

        #8;

        $display("DONE!");
        $finish();
      
    end : REGFILE_TEST_VECTORS
`endif

function instruction_element_t setInstructionElement
(
    input instruction_t           instruction_i,
    input bit                     CB1_i,
    input bit [           31:0]   val1_i,
    input bit                     CB2_i,
    input bit [           31:0]   val2_i,
    input bit [            4:0]   dest_reg_i,
    input bit [ROB_IDX_LEN-1:0]   ROB_dest_i,
    input bit                     branch_i,
    input bit [           31:0]   imm_i,
    input bit [           31:0]   pc_i
);
    automatic instruction_element_t data_o;
    data_o.instruction  = instruction_i;
    data_o.CB1          = CB1_i;
    data_o.CB2          = CB2_i;
    data_o.val1         = val1_i;
    data_o.val2         = val2_i;
    data_o.dest_reg     = dest_reg_i;
    data_o.ROB_dest     = ROB_dest_i;
    data_o.branch       = branch_i;
    data_o.b_imm        = imm_i;
    data_o.pc           = pc_i;
    return data_o;
endfunction


`ifdef data_interface
    parameter MULTIPLE_ISSUE = 1;
    parameter BUFFER_DEPTH   = 15;
    parameter UNIT_DEPTH     = 15;
    parameter ROB_IDX_LEN    = 4;
    parameter NUM_CDB_INPUTS = 5;
    parameter MEM_CDB_IDX    = 0;

    logic                    BR_commit_i;
    logic [ROB_IDX_LEN-1:0]  BR_cnt_i;
    logic                    instr_vld_i;
    logic                    instr_rdy_o;
    instruction_element_t    instr_i;
    logic                    mem_resp_i;
    logic                    mem_read_o;
    logic                    mem_write_o;
    logic [           31:0]  mem_addr_o;
    logic [           31:0]  mem_data_i;
    logic [           31:0]  mem_data_o;
    logic [            3:0]  mem_byte_en_o;
    reg_bus_t                reg_bus_i;
    common_data_bus_t        common_data_bus_i;
    common_data_lane_t       common_data_lane_o;

    data_interface
    #(
        .MULTIPLE_ISSUE (MULTIPLE_ISSUE),
        .BUFFER_DEPTH   (BUFFER_DEPTH  ),
        .UNIT_DEPTH     (UNIT_DEPTH    )
    )
    di
    (
        .*
    );

    instruction_element_t input0, input1, input2, input3, input4;

    initial begin : init_test_vars
        input0 = setInstructionElement(ld_lw, 0, 31, 0, 28, 3, 7, 0, 12, 'h60);
        input1 = setInstructionElement(st_sw, 0, 20, 0, 21, 2, 8, 0, 10, 'h64);
        input2 = setInstructionElement(ld_lw, 0, 20, 0, 21, 2, 8, 0, 10, 'h68);
        input3 = setInstructionElement(st_sw, 0, 31, 0, 28, 3, 7, 0, 12, 'h6c);
        input4 = setInstructionElement(st_sw, 0, 31, 1, 28, 3, 7, 0, 12, 'h70);
        // Could not tell you why this does't work above...
        input0.instruction = ld_lw;
        input1.instruction = st_sw;
        input2.instruction = ld_lw;
        input3.instruction = st_sw;
        input4.instruction = st_sw;
        input4.CB2 = 1'b1;
    end

    initial begin : DATA_INTERFACE_TEST_VECTORS
        BR_commit_i         = 1'b0;
        BR_cnt_i            = ROB_IDX_LEN'(0);
        instr_vld_i         = 1'b0;
        instr_i             = '0;
        mem_resp_i          = 1'b0;
        mem_data_i          = '0;
        reg_bus_i           = '0;
        common_data_bus_i   = '0;
        rst                 = 1'b1;
        #2;
        rst                 = 1'b0;
        #2;
        
        // Test a single load with no deps:
        instr_i     = input0;
        instr_vld_i = 1'b1;
        #2;
        instr_vld_i = 1'b0;
        #3; 
        mem_data_i  = 32'hdeadbeef;
        mem_resp_i  = 1'b1;
        #1;
        assert(common_data_lane_o.valid    == 1'b1);
        assert(common_data_lane_o.ROB_dest == input0.ROB_dest);
        assert(common_data_lane_o.data     == 32'hdeadbeef);
        #1;
        mem_resp_i  = 1'b0;
        #1;

        // Test a single store with no deps:
        instr_i     = input1;
        instr_vld_i = 1'b1;
        #2;
        instr_vld_i = 1'b0;
        #2; 
        assert(mem_write_o == 1'b1);
        assert(mem_data_o  == input1.val2);
        assert(mem_addr_o  == (((input1.val1 + input1.b_imm) >> 2) << 2)); // #ELEGANT #DILLONDONTKILLME
        #3;
        mem_resp_i = 1'b1;
        #2;
        mem_resp_i = 1'b0;
        #3;

        // Test a load-store in quick succession:
        instr_i     = input0;
        instr_vld_i = 1'b1;
        #2;
        instr_i     = input1;
        #2;
        instr_vld_i = 1'b0;
        #1;
        mem_data_i  = 32'hecebeceb;
        mem_resp_i  = 1'b1;
        #1;
        assert(common_data_lane_o.valid    == 1'b1);
        assert(common_data_lane_o.ROB_dest == input0.ROB_dest);
        assert(common_data_lane_o.data     == 32'hecebeceb);
        #1;
        mem_resp_i = 1'b0;
        #1;
        assert(mem_write_o == 1'b1);
        assert(mem_data_o  == input1.val2);
        assert(mem_addr_o  == (((input1.val1 + input1.b_imm) >> 2) << 2));
        #7;
        mem_resp_i = 1'b1;
        #2; 
        mem_resp_i = 1'b0;
        #3;


        // Test a load-load in quick succession:
        instr_i     = input0;
        instr_vld_i = 1'b1;
        #2;
        instr_i     = input2;
        #2;
        instr_vld_i = 1'b0;
        #1;
        mem_data_i  = 32'hdeadbeef;
        mem_resp_i  = 1'b1;
        #1;
        assert(common_data_lane_o.valid    == 1'b1);
        assert(common_data_lane_o.ROB_dest == input0.ROB_dest);
        assert(common_data_lane_o.data     == 32'hdeadbeef);
        #1;
        mem_resp_i = 1'b0;
        #2;
        mem_data_i  = 32'hecebeceb;
        mem_resp_i  = 1'b1;
        #1;
        assert(common_data_lane_o.valid    == 1'b1);
        assert(common_data_lane_o.ROB_dest == input2.ROB_dest);
        assert(common_data_lane_o.data     == 32'hecebeceb);
        #1;
        mem_resp_i = 1'b0;
        #3;

        // Overflow the system:
        instr_i     = input0;
        instr_vld_i = 1'b1;
        #66; // 16 buffer + 16 queue + 1 pending transaction * 2 half cycles.
        instr_i = input1; // Try to push a different instruction
        #1;
        instr_vld_i = 1'b0;
        assert(instr_rdy_o == 1'b0); // Ensure we cannot push more.
        for (int i = 0; i < 33; i++) begin
            mem_data_i = i;
            mem_resp_i = 1'b1;
            #1;
            assert(common_data_lane_o.valid    == 1'b1);
            assert(common_data_lane_o.ROB_dest == input0.ROB_dest);
            assert(common_data_lane_o.data     == i);
            #1;
            mem_resp_i = 1'b0;
            #2;
        end
        #3;

        // Wait on pending reference.
        instr_i     = input4;
        instr_vld_i = 1'b1;
        #2;
        instr_vld_i = 1'b0;
        #6;
        common_data_bus_i = makeResultAvailableCDB(456, 28, 1);
        #2;
        common_data_bus_i = '0;
        #2;
        assert(mem_write_o == 1'b1);
        assert(mem_data_o  == 456);
        #2;
        mem_resp_i = 1'b1;
        #2;
        mem_resp_i = 1'b0;
        #4;

        // Wait on branch speculation.
        instr_i     = input0;
        BR_cnt_i    = 1'b1;
        instr_vld_i = 1'b1;
        #2;
        instr_vld_i = 1'b0;
        #13;
        BR_commit_i = 1'b1;
        #2;
        BR_commit_i = 1'b0;
        #2;
        mem_data_i  = 32'hdeadbeef;
        mem_resp_i  = 1'b1;
        #1;
        assert(common_data_lane_o.valid    == 1'b1);
        assert(common_data_lane_o.ROB_dest == input0.ROB_dest);
        assert(common_data_lane_o.data     == 32'hdeadbeef);
        #1;
        mem_resp_i  = 1'b0;
        #1;


        // Still to be done.
        #50;

        $display("DONE!");
        $stop();

    end : DATA_INTERFACE_TEST_VECTORS

`endif

`ifdef reservation_station
    parameter DEPTH       = 4;
    parameter WRITE_COUNT = 1;
    parameter READ_COUNT  = 5;

    common_data_bus_t common_data_bus_i;
    logic [WRITE_COUNT-1:0] vld_i;
    logic [WRITE_COUNT-1:0] rdy_i;
    instruction_element_t data_i [WRITE_COUNT];
    logic [ READ_COUNT-1:0] vld_o;
    logic [ READ_COUNT-1:0] rdy_o;
    reservation_station_element_t data_o [READ_COUNT];

    reservation_station
    #(
        .DEPTH       (DEPTH),
        .WRITE_COUNT (WRITE_COUNT),
        .READ_COUNT  (READ_COUNT)
    )
    rs
    (.*);

    instruction_element_t inst00, inst01, inst10, inst11;

    initial begin : init_test_vars
        common_data_bus_i = '0;
        inst00 = setInstructionElement(rr_add , 0, 2, 0, 2, 1, 1, 0, 0, 'h60);
        inst01 = setInstructionElement(rr_aor , 0, 4, 0, 4, 2, 2, 0, 0, 'h64);
        inst10 = setInstructionElement(rr_axor, 0, 6, 0, 6, 3, 3, 0, 0, 'h68);
        inst11 = setInstructionElement(rr_aand, 0, 8, 0, 8, 4, 4, 0, 0, 'h6C);
    end

    initial begin : DATA_INTERFACE_TEST_VECTORS
        vld_i = '0;
        rdy_o = '0;
        rst = 1'b1;
        
        repeat(2) @(posedge clk);
        
        data_i[0] = inst00;
        rst = 1'b0;
        
        repeat(2) @(posedge clk);
        
        @(negedge clk);
        
        vld_i = 1'b1;
        
        @(negedge clk);
        
        data_i[0] = inst01;
        
        @(negedge clk);
        
        data_i[0] = inst10;
        
        @(negedge clk);
        
        data_i[0] = inst11;

        @(negedge clk);

        vld_i = 1'b0;
        
        repeat(2) @(posedge clk);
        
        @(negedge clk);
        
        rdy_o = 6'b111111;
        
        repeat(4) @(posedge clk);
        
        $display("DONE!");
        $stop();
    end
`endif

endmodule
