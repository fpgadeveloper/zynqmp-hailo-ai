# (C) Copyright 2020 - 2022 Xilinx, Inc.
# SPDX-License-Identifier: Apache-2.0

set board_name [lindex $argv 2]

source "build/${board_name}/settings.tcl"

# Work out absolute paths for IP sources and include files
set curr_dir [pwd]
set vision_dir "../../submodules/Vitis_Libraries/vision"
set VITIS_LIBS [file normalize [file join $curr_dir $vision_dir]]
set include_dir "isppipeline/include"
set INCLUDE_PATH [file normalize [file join $curr_dir $include_dir]]

set PROJ "isppipeline.prj"
set SOLN "sol1"

if {![info exists CLKP]} {
  set CLKP 3.3
}

# Change directory to create the IP project inside the build folder for this board
cd build/$board_name

open_project -reset $PROJ

add_files "${VITIS_LIBS}/L1/examples/isppipeline/xf_isp_accel.cpp" -cflags "-I${VITIS_LIBS}/L1/include -I ${INCLUDE_PATH} -I ./ -D__SDSVHLS__ -std=c++0x" -csimflags "-I${VITIS_LIBS}/L1/include -I ${INCLUDE_PATH} -I ./ -D__SDSVHLS__ -std=c++0x"
set_top ISPPipeline_accel

open_solution -reset $SOLN

set_part $XPART
create_clock -period $CLKP

csynth_design
export_design -rtl verilog -format ip_catalog

cd ../..

exit
