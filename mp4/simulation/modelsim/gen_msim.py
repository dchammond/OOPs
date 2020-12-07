#!/usr/bin/env python3

import os, sys
import pathlib

vsim_str = \
"""
transcript on
if {{[file exists rtl_work]}} {{
	vdel -lib rtl_work -all
}}
vlib rtl_work
vmap work rtl_work

vlog -sv -work work +incdir+{0}/mp4/hdl/common {{{0}/mp4/hdl/common/rv32i_types.sv}}
vlog -sv -work work +incdir+{0}/mp4/hdl/common {{{0}/mp4/hdl/common/oops_structs.sv}}
vlog -sv -work work +incdir+{0}/mp4/hdl/common {{{0}/mp4/hdl/common/queue.sv}}
vlog -sv -work work +incdir+{0}/mp4/hdl/common {{{0}/mp4/hdl/common/pipeline.sv}}
vlog -sv -work work +incdir+{0}/mp4/hdl/common {{{0}/mp4/hdl/common/alu.sv}}
vlog -sv -work work +incdir+{0}/mp4/hdl/cache  {{{0}/mp4/hdl/cache/cache_mux_types.sv}}
vlog -sv -work work +incdir+{0}/mp4/hdl/cache  {{{0}/mp4/hdl/cache/arbiter.sv}}
vlog -sv -work work +incdir+{0}/mp4/hdl/cache  {{{0}/mp4/hdl/cache/array.sv}}
vlog -sv -work work +incdir+{0}/mp4/hdl/cache  {{{0}/mp4/hdl/cache/data_array.sv}}
vlog -sv -work work +incdir+{0}/mp4/hdl/cache  {{{0}/mp4/hdl/cache/cache_control.sv}}
vlog -sv -work work +incdir+{0}/mp4/hdl/cache  {{{0}/mp4/hdl/cache/cache_datapath.sv}}
vlog -sv -work work +incdir+{0}/mp4/hdl/cache  {{{0}/mp4/hdl/cache/line_adapter.sv}}
vlog -sv -work work +incdir+{0}/mp4/hdl/cache  {{{0}/mp4/hdl/cache/cache.sv}}
vlog -sv -work work +incdir+{0}/mp4/hdl/cache  {{{0}/mp4/hdl/cache/cacheline_adaptor.sv}}
vlog -sv -work work +incdir+{0}/mp4/hdl/cache  {{{0}/mp4/hdl/cache/cache_interface.sv}}
vlog -sv -work work +incdir+{0}/mp4/hdl/cpu    {{{0}/mp4/hdl/cpu/program_counter.sv}}
vlog -sv -work work +incdir+{0}/mp4/hdl/cpu {{{0}/mp4/hdl/cpu/instruction_register.sv}}
vlog -sv -work work +incdir+{0}/mp4/hdl/cpu {{{0}/mp4/hdl/cpu/instruction_fetcher.sv}}
vlog -sv -work work +incdir+{0}/mp4/hdl/cpu {{{0}/mp4/hdl/cpu/data_interface.sv}}
vlog -sv -work work +incdir+{0}/mp4/hdl/cpu {{{0}/mp4/hdl/cpu/address_unit.sv}}
vlog -sv -work work +incdir+{0}/mp4/hdl/cpu {{{0}/mp4/hdl/cpu/register_file.sv}}
vlog -sv -work work +incdir+{0}/mp4/hdl/cpu {{{0}/mp4/hdl/cpu/reorder_buffer.sv}}
vlog -sv -work work +incdir+{0}/mp4/hdl/cpu {{{0}/mp4/hdl/cpu/instruction_decoder.sv}}
vlog -sv -work work +incdir+{0}/mp4/hdl/cpu {{{0}/mp4/hdl/cpu/instruction_queue.sv}}
vlog -sv -work work +incdir+{0}/mp4/hdl/cpu {{{0}/mp4/hdl/cpu/instruction_datapath.sv}}
vlog -sv -work work +incdir+{0}/mp4/hdl/cpu {{{0}/mp4/hdl/cpu/address_buffer.sv}}
vlog -sv -work work +incdir+{0}/mp4/hdl/cpu {{{0}/mp4/hdl/cpu/reservation_station.sv}}
vlog -sv -work work +incdir+{0}/mp4/hdl/cpu {{{0}/mp4/hdl/cpu/execution_unit.sv}}
vlog -sv -work work +incdir+{0}/mp4/hdl/cpu {{{0}/mp4/hdl/cpu/cpu.sv}}
vlog -sv -work work +incdir+{0}/mp4/hdl        {{{0}/mp4/hdl/mp4.sv}}

vlog -sv -work work +incdir+{0}/mp4/hvl {{{0}/mp4/hvl/magic_dual_port.sv}}
vlog -sv -work work +incdir+{0}/mp4/hvl {{{0}/mp4/hvl/param_memory.sv}}
vlog -sv -work work +incdir+{0}/mp4/hvl {{{0}/mp4/hvl/rvfi_itf.sv}}
vlog -vlog01compat -work work +incdir+{0}/mp4/hvl {{{0}/mp4/hvl/rvfimon.v}}
vlog -sv -work work +incdir+{0}/mp4/hvl {{{0}/mp4/hvl/shadow_memory.sv}}
vlog -sv -work work +incdir+{0}/mp4/hvl {{{0}/mp4/hvl/source_tb.sv}}
vlog -sv -work work +incdir+{0}/mp4/hvl {{{0}/mp4/hvl/tb_itf.sv}}
vlog -sv -work work +incdir+{0}/mp4/hvl {{{0}/mp4/hvl/top.sv}}

vsim -t 1ps -L altera_ver -L lpm_ver -L sgate_ver -L altera_mf_ver -L altera_lnsim_ver -L arriaiigz_hssi_ver -L arriaiigz_pcie_hip_ver -L arriaiigz_ver -L rtl_work -L work -voptargs="+acc"  mp4_tb

add wave dut/*
add wave dut/oops_cpu/*
add wave dut/oops_cache/*
radix hex
view structure
view signals
run 25000ns

quit
"""

def write_file(arg):
    if arg[-1] == "/":
        arg = arg[:-1]
    print("Using {} as OOPs repository".format(arg))
    s = vsim_str.format(arg)
    out_file = pathlib.Path(__file__)
    out_file = out_file.parent
    with open("{}/mp4_run_msim_rtl_verilog_static.do".format(out_file), "w") as f:
        f.write(s)

def read_from_cmd():
    arg = sys.argv[1]
    write_file(arg)

def read_from_env():
    arg = os.getenv("OOPS_DIR", "")
    if arg == "":
        print("$OOPS_DIR not set!")
        return
    write_file(arg)

if __name__ == "__main__":
    if len(sys.argv) > 1:
        read_from_cmd()
    else:
        read_from_env()

