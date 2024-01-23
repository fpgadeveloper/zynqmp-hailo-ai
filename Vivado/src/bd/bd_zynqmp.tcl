################################################################
# Block diagram build script for Zynq MP designs
################################################################

################################################################
# EMIO GPIOs are connected as follows:
################################################################
# 0  - VCU (all except PYNQ-ZU)
# 1  - Video Mixer IP
# 1-7 Reserved
# 8  - CAM0 ISPPipeline IP reset
# 9  - CAM0 Vproc IP reset
# 10 - CAM0 Frame Buffer Write IP reset
# 11-15 Reserved
# 16 - CAM1 ISPPipeline IP reset
# 17 - CAM1 Vproc IP reset
# 18 - CAM1 Frame Buffer Write IP reset
# 19-23 Reserved
# 24 - CAM2 ISPPipeline IP reset
# 25 - CAM2 Vproc IP reset
# 26 - CAM2 Frame Buffer Write IP reset
# 28-31 Reserved
# 32 - CAM3 ISPPipeline IP reset
# 33 - CAM3 Vproc IP reset
# 34 - CAM3 Frame Buffer Write IP reset

# CHECKING IF PROJECT EXISTS
if { [get_projects -quiet] eq "" } {
   puts "ERROR: Please open or create a project!"
   return 1
}

set cur_design [current_bd_design -quiet]
set list_cells [get_bd_cells -quiet]

create_bd_design $block_name

current_bd_design $block_name

set parentCell [get_bd_cells /]

# Get object for parentCell
set parentObj [get_bd_cells $parentCell]
if { $parentObj == "" } {
   puts "ERROR: Unable to find parent cell <$parentCell>!"
   return
}

# Make sure parentObj is hier blk
set parentType [get_property TYPE $parentObj]
if { $parentType ne "hier" } {
   puts "ERROR: Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."
   return
}

# Save current instance; Restore later
set oldCurInst [current_bd_instance .]

# Set parent object as current
current_bd_instance $parentObj

# Board specific PCIe and GT LOCs
if {$board_name == "zcu104"} {
  set select_quad_0 "GTH_Quad_226"
  set pcie_blk_locn_0 "X0Y0"
} elseif {$board_name == "zcu106" && $pcie_fmc == "hpc0"} {
  set select_quad_0 "GTH_Quad_226"
  set select_quad_1 "GTH_Quad_227"
  set pcie_blk_locn_0 "X0Y1"
  set pcie_blk_locn_1 "X0Y0"
} elseif {$board_name == "zcu106" && $pcie_fmc == "hpc1"} {
  set select_quad_0 "GTH_Quad_223"
  set pcie_blk_locn_0 "X0Y0"
} elseif {$board_name == "pynqzu"} {
  set select_quad_0 "GTH_Quad_224"
  set pcie_blk_locn_0 "X0Y1"
} elseif {$board_name == "ultrazed_7ev_cc"} {
  set select_quad_0 "GTH_Quad_225"
  set select_quad_1 "GTH_Quad_224"
  set pcie_blk_locn_0 "X0Y1"
  set pcie_blk_locn_1 "X0Y0"
}

dict set dp_dict zcu104 dpaux "MIO 27 .. 30"
dict set dp_dict zcu104 lane_sel "Dual Lower"
dict set dp_dict zcu104 ref_clk_freq "27"
dict set dp_dict zcu104 ref_clk_sel "Ref Clk3"
dict set dp_dict zcu104 dp_lane0 "GT Lane1"
dict set dp_dict zcu104 dp_lane1 "GT Lane0"
dict set dp_dict zcu102 dpaux "MIO 27 .. 30"
dict set dp_dict zcu102 lane_sel "Single Lower"
dict set dp_dict zcu102 ref_clk_freq "27"
dict set dp_dict zcu102 ref_clk_sel "Ref Clk3"
dict set dp_dict zcu102 dp_lane0 "GT Lane1"
dict set dp_dict zcu102 dp_lane1 ""
dict set dp_dict zcu106 dpaux "MIO 27 .. 30"
dict set dp_dict zcu106 lane_sel "Dual Lower"
dict set dp_dict zcu106 ref_clk_freq "27"
dict set dp_dict zcu106 ref_clk_sel "Ref Clk3"
dict set dp_dict zcu106 dp_lane0 "GT Lane1"
dict set dp_dict zcu106 dp_lane1 "GT Lane0"
dict set dp_dict ultrazed_7ev_cc dpaux "MIO 27 .. 30"
dict set dp_dict ultrazed_7ev_cc lane_sel "Single Higher"
dict set dp_dict ultrazed_7ev_cc ref_clk_freq "27"
dict set dp_dict ultrazed_7ev_cc ref_clk_sel "Ref Clk3"
dict set dp_dict ultrazed_7ev_cc dp_lane0 "GT Lane3"
dict set dp_dict ultrazed_7ev_cc dp_lane1 ""
dict set dp_dict pynqzu dpaux "MIO 27 .. 30"
dict set dp_dict pynqzu lane_sel "Dual Lower"
dict set dp_dict pynqzu ref_clk_freq "27"
dict set dp_dict pynqzu ref_clk_sel "Ref Clk1"
dict set dp_dict pynqzu dp_lane0 "GT Lane1"
dict set dp_dict pynqzu dp_lane1 "GT Lane0"
dict set dp_dict gzu_5ev dpaux "EMIO"
dict set dp_dict gzu_5ev lane_sel "Dual Higher"
dict set dp_dict gzu_5ev ref_clk_freq "108"
dict set dp_dict gzu_5ev ref_clk_sel "Ref Clk2"
dict set dp_dict gzu_5ev dp_lane0 "GT Lane3"
dict set dp_dict gzu_5ev dp_lane1 "GT Lane2"

# Video pipe max res has impact on resource usage
set max_cols 1920
set max_rows 1232

# Set the samples-per-clock for the video pipelines (1)
# Set this to 2 to double the throughput at the cost of higher resource usage
set samples_pc 1

# Procedure for creating a MIPI pipe for one camera
proc create_mipi_pipe { index loc_dict } {
  set hier_obj [create_bd_cell -type hier mipi_$index]
  current_bd_instance $hier_obj
  global samples_pc
  global target
  global max_cols
  global max_rows
  
  # Create pins of the block
  create_bd_pin -dir I dphy_clk_200M
  create_bd_pin -dir I s_axi_lite_aclk
  create_bd_pin -dir I aresetn
  create_bd_pin -dir I video_aclk
  create_bd_pin -dir I video_aresetn
  create_bd_pin -dir O mipi_sub_irq
  create_bd_pin -dir O isppipeline_irq
  create_bd_pin -dir O frmbufwr_irq
  create_bd_pin -dir O iic2intc_irpt
  create_bd_pin -dir I emio_gpio
  
  # Create the interfaces of the block
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI_CTRL
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI_VIDEO
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 m_axi_mm_video
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:mipi_phy_rtl:1.0 mipi_phy_if
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:iic_rtl:1.0 IIC
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:gpio_rtl:1.0 GPIO
  
  # Add and configure the MIPI Subsystem IP
  set clk_pin [dict get $loc_dict clk pin]
  set clk_pin_name [dict get $loc_dict clk pin_name]
  set data0_pin [dict get $loc_dict data0 pin]
  set data0_pin_name [dict get $loc_dict data0 pin_name]
  set data1_pin [dict get $loc_dict data1 pin]
  set data1_pin_name [dict get $loc_dict data1 pin_name]
  set bank [dict get $loc_dict bank]
  set mipi_csi2_rx_subsyst [ create_bd_cell -type ip -vlnv xilinx.com:ip:mipi_csi2_rx_subsystem mipi_csi2_rx_subsyst_0 ]
  set_property -dict [ list \
    CONFIG.SupportLevel {1} \
    CONFIG.CMN_NUM_LANES {2} \
    CONFIG.CMN_PXL_FORMAT {RAW10} \
    CONFIG.C_DPHY_LANES {2} \
    CONFIG.CMN_NUM_PIXELS $samples_pc \
    CONFIG.C_EN_CSI_V2_0 {true} \
    CONFIG.C_HS_LINE_RATE {420} \
    CONFIG.C_HS_SETTLE_NS {158} \
    CONFIG.DPY_LINE_RATE {420} \
    CONFIG.CLK_LANE_IO_LOC $clk_pin \
    CONFIG.CLK_LANE_IO_LOC_NAME $clk_pin_name \
    CONFIG.DATA_LANE0_IO_LOC $data0_pin \
    CONFIG.DATA_LANE0_IO_LOC_NAME $data0_pin_name \
    CONFIG.DATA_LANE1_IO_LOC $data1_pin \
    CONFIG.DATA_LANE1_IO_LOC_NAME $data1_pin_name \
    CONFIG.HP_IO_BANK_SELECTION $bank \
  ] $mipi_csi2_rx_subsyst
 
  # Add and configure the AXI Interconnect (LPD)
  set axi_int_ctrl [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect axi_int_ctrl ]
  set_property -dict [list \
  CONFIG.NUM_MI {3} \
  ] $axi_int_ctrl
  
  # Add and configure the AXI Interconnect (HPD)
  set axi_int_video [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect axi_int_video ]
  set_property -dict [list \
  CONFIG.NUM_MI {3} \
  ] $axi_int_video
  
  # Add the ISPPipeline
  set isppipeline [ create_bd_cell -type ip -vlnv xilinx.com:hls:ISPPipeline_accel:1.0 isppipeline ]

  # Add and configure the Video Processor subsystem
  set v_proc [ create_bd_cell -type ip -vlnv xilinx.com:ip:v_proc_ss v_proc ]
  set_property -dict [ list \
    CONFIG.C_MAX_COLS $max_cols \
    CONFIG.C_MAX_ROWS $max_rows \
    CONFIG.C_ENABLE_DMA {false} \
    CONFIG.C_MAX_DATA_WIDTH {8} \
    CONFIG.C_TOPOLOGY {0} \
    CONFIG.C_SCALER_ALGORITHM {2} \
    CONFIG.C_ENABLE_CSC {true} \
    CONFIG.C_SAMPLES_PER_CLK $samples_pc \
  ] $v_proc
 
  # Add and configure the Video Frame Buffer Write
  set v_frmbuf_wr [create_bd_cell -type ip -vlnv xilinx.com:ip:v_frmbuf_wr v_frmbuf_wr]
  set_property -dict [list \
   CONFIG.C_M_AXI_MM_VIDEO_DATA_WIDTH {128} \
   CONFIG.SAMPLES_PER_CLOCK $samples_pc \
   CONFIG.AXIMM_DATA_WIDTH {128} \
   CONFIG.HAS_BGR8 {1} \
   CONFIG.HAS_Y_UV8_420 {1} \
   CONFIG.HAS_YUYV8 {1} \
   CONFIG.MAX_NR_PLANES {2} \
   CONFIG.MAX_COLS $max_cols \
   CONFIG.MAX_ROWS $max_rows \
  ] $v_frmbuf_wr
  
  # Slice for ISPPipeline reset signal
  set emio_gpio_index [expr {8*($index+1)+0}]
  set reset_isppipeline [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice reset_isppipeline ]
  set_property -dict [ list \
  CONFIG.DIN_WIDTH {95} \
  CONFIG.DIN_TO $emio_gpio_index \
  CONFIG.DIN_FROM $emio_gpio_index \
  CONFIG.DOUT_WIDTH {1} \
  ] $reset_isppipeline

  connect_bd_net -net reset_isppipeline_Dout [get_bd_pins reset_isppipeline/Dout] [get_bd_pins isppipeline/ap_rst_n]
  connect_bd_net [get_bd_pins emio_gpio] [get_bd_pins reset_isppipeline/Din]

  # Slice for Vproc reset signal
  set emio_gpio_index [expr {8*($index+1)+1}]
  set reset_v_proc [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice reset_v_proc ]
  set_property -dict [ list \
  CONFIG.DIN_WIDTH {95} \
  CONFIG.DIN_TO $emio_gpio_index \
  CONFIG.DIN_FROM $emio_gpio_index \
  CONFIG.DOUT_WIDTH {1} \
  ] $reset_v_proc

  connect_bd_net -net reset_v_proc_Dout [get_bd_pins reset_v_proc/Dout] [get_bd_pins v_proc/aresetn_ctrl]
  connect_bd_net [get_bd_pins emio_gpio] [get_bd_pins reset_v_proc/Din]

  # Slice for Frmbuf WR reset signal
  set emio_gpio_index [expr {8*($index+1)+2}]
  set reset_frmbuf_wr [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice reset_frmbuf_wr ]
  set_property -dict [ list \
  CONFIG.DIN_WIDTH {95} \
  CONFIG.DIN_TO $emio_gpio_index \
  CONFIG.DIN_FROM $emio_gpio_index \
  CONFIG.DOUT_WIDTH {1} \
  ] $reset_frmbuf_wr

  connect_bd_net -net reset_frmbuf_wr_Dout [get_bd_pins reset_frmbuf_wr/Dout] [get_bd_pins v_frmbuf_wr/ap_rst_n]
  connect_bd_net [get_bd_pins emio_gpio] [get_bd_pins reset_frmbuf_wr/Din]

  # Add and configure AXI IIC
  set axi_iic [create_bd_cell -type ip -vlnv xilinx.com:ip:axi_iic axi_iic_0]
  
  # Add and configure AXI GPIO
  set axi_gpio [create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio axi_gpio_0]
  set_property -dict [list CONFIG.C_GPIO_WIDTH {2} CONFIG.C_ALL_OUTPUTS {1}] $axi_gpio
  
  # Connect the 200M D-PHY clock
  connect_bd_net [get_bd_pins dphy_clk_200M] [get_bd_pins mipi_csi2_rx_subsyst_0/dphy_clk_200M]
  # Connect the 300M video clock
  connect_bd_net [get_bd_pins video_aclk] [get_bd_pins mipi_csi2_rx_subsyst_0/video_aclk]
  connect_bd_net [get_bd_pins video_aclk] [get_bd_pins v_frmbuf_wr/ap_clk]
  connect_bd_net [get_bd_pins video_aclk] [get_bd_pins v_proc/aclk_axis]
  connect_bd_net [get_bd_pins video_aclk] [get_bd_pins v_proc/aclk_ctrl]
  connect_bd_net [get_bd_pins video_aclk] [get_bd_pins isppipeline/ap_clk]
  connect_bd_net [get_bd_pins video_aclk] [get_bd_pins axi_int_video/ACLK]
  connect_bd_net [get_bd_pins video_aclk] [get_bd_pins axi_int_video/S00_ACLK]
  connect_bd_net [get_bd_pins video_aclk] [get_bd_pins axi_int_video/M00_ACLK]
  connect_bd_net [get_bd_pins video_aclk] [get_bd_pins axi_int_video/M01_ACLK]
  connect_bd_net [get_bd_pins video_aclk] [get_bd_pins axi_int_video/M02_ACLK]
  # Connect the 100M AXI-Lite clock
  connect_bd_net [get_bd_pins s_axi_lite_aclk] [get_bd_pins axi_int_ctrl/ACLK]
  connect_bd_net [get_bd_pins s_axi_lite_aclk] [get_bd_pins axi_int_ctrl/S00_ACLK]
  connect_bd_net [get_bd_pins s_axi_lite_aclk] [get_bd_pins axi_int_ctrl/M00_ACLK]
  connect_bd_net [get_bd_pins s_axi_lite_aclk] [get_bd_pins axi_int_ctrl/M01_ACLK]
  connect_bd_net [get_bd_pins s_axi_lite_aclk] [get_bd_pins axi_int_ctrl/M02_ACLK]
  connect_bd_net [get_bd_pins s_axi_lite_aclk] [get_bd_pins mipi_csi2_rx_subsyst_0/lite_aclk]
  connect_bd_net [get_bd_pins s_axi_lite_aclk] [get_bd_pins axi_iic_0/s_axi_aclk]
  connect_bd_net [get_bd_pins s_axi_lite_aclk] [get_bd_pins axi_gpio_0/s_axi_aclk]
  # Connect the video resets
  connect_bd_net [get_bd_pins video_aresetn] [get_bd_pins axi_int_video/ARESETN] -boundary_type upper
  connect_bd_net [get_bd_pins video_aresetn] [get_bd_pins axi_int_video/S00_ARESETN] -boundary_type upper
  connect_bd_net [get_bd_pins video_aresetn] [get_bd_pins axi_int_video/M00_ARESETN] -boundary_type upper
  connect_bd_net [get_bd_pins video_aresetn] [get_bd_pins axi_int_video/M01_ARESETN] -boundary_type upper
  connect_bd_net [get_bd_pins video_aresetn] [get_bd_pins axi_int_video/M02_ARESETN] -boundary_type upper
  connect_bd_net [get_bd_pins video_aresetn] [get_bd_pins mipi_csi2_rx_subsyst_0/video_aresetn]
  # Connect the AXI-Lite resets
  connect_bd_net [get_bd_pins aresetn] [get_bd_pins axi_int_ctrl/ARESETN] -boundary_type upper
  connect_bd_net [get_bd_pins aresetn] [get_bd_pins axi_int_ctrl/S00_ARESETN] -boundary_type upper
  connect_bd_net [get_bd_pins aresetn] [get_bd_pins axi_int_ctrl/M00_ARESETN] -boundary_type upper
  connect_bd_net [get_bd_pins aresetn] [get_bd_pins axi_int_ctrl/M01_ARESETN] -boundary_type upper
  connect_bd_net [get_bd_pins aresetn] [get_bd_pins axi_int_ctrl/M02_ARESETN] -boundary_type upper
  connect_bd_net [get_bd_pins aresetn] [get_bd_pins mipi_csi2_rx_subsyst_0/lite_aresetn]
  connect_bd_net [get_bd_pins aresetn] [get_bd_pins axi_iic_0/s_axi_aresetn]
  connect_bd_net [get_bd_pins aresetn] [get_bd_pins axi_gpio_0/s_axi_aresetn]
  # Connect AXI Lite CTRL interfaces
  connect_bd_intf_net -boundary_type upper [get_bd_intf_pins S_AXI_CTRL] [get_bd_intf_pins axi_int_ctrl/S00_AXI]
  connect_bd_intf_net -boundary_type upper [get_bd_intf_pins axi_int_ctrl/M00_AXI] [get_bd_intf_pins mipi_csi2_rx_subsyst_0/csirxss_s_axi]
  connect_bd_intf_net -boundary_type upper [get_bd_intf_pins axi_int_ctrl/M01_AXI] [get_bd_intf_pins axi_iic_0/S_AXI]
  connect_bd_intf_net -boundary_type upper [get_bd_intf_pins axi_int_ctrl/M02_AXI] [get_bd_intf_pins axi_gpio_0/S_AXI]
  # Connect AXI Lite VIDEO interfaces
  connect_bd_intf_net -boundary_type upper [get_bd_intf_pins S_AXI_VIDEO] [get_bd_intf_pins axi_int_video/S00_AXI]
  connect_bd_intf_net -boundary_type upper [get_bd_intf_pins axi_int_video/M00_AXI] [get_bd_intf_pins isppipeline/s_axi_CTRL]
  connect_bd_intf_net -boundary_type upper [get_bd_intf_pins axi_int_video/M01_AXI] [get_bd_intf_pins v_frmbuf_wr/s_axi_CTRL]
  connect_bd_intf_net -boundary_type upper [get_bd_intf_pins axi_int_video/M02_AXI] [get_bd_intf_pins v_proc/s_axi_ctrl]
  # Connect the AXI Streaming interfaces
  connect_bd_intf_net [get_bd_intf_pins mipi_csi2_rx_subsyst_0/video_out] [get_bd_intf_pins isppipeline/s_axis_video]
  connect_bd_intf_net [get_bd_intf_pins isppipeline/m_axis_video] [get_bd_intf_pins v_proc/s_axis]
  connect_bd_intf_net [get_bd_intf_pins v_proc/m_axis] [get_bd_intf_pins v_frmbuf_wr/s_axis_video]
  # Connect the MIPI D-PHY interface
  connect_bd_intf_net -boundary_type upper [get_bd_intf_pins mipi_phy_if] [get_bd_intf_pins mipi_csi2_rx_subsyst_0/mipi_phy_if]
  # Connect the Frame Buffer MM interface
  connect_bd_intf_net [get_bd_intf_pins m_axi_mm_video] [get_bd_intf_pins v_frmbuf_wr/m_axi_mm_video]
  # Connect the I2C interface
  connect_bd_intf_net [get_bd_intf_pins IIC] [get_bd_intf_pins axi_iic_0/IIC]
  # Connect the GPIO interface
  connect_bd_intf_net [get_bd_intf_pins GPIO] [get_bd_intf_pins axi_gpio_0/GPIO]
  # Connect interrupts
  connect_bd_net [get_bd_pins mipi_sub_irq] [get_bd_pins mipi_csi2_rx_subsyst_0/csirxss_csi_irq]
  connect_bd_net [get_bd_pins isppipeline_irq] [get_bd_pins isppipeline/interrupt]
  connect_bd_net [get_bd_pins frmbufwr_irq] [get_bd_pins v_frmbuf_wr/interrupt]
  connect_bd_net [get_bd_pins iic2intc_irpt] [get_bd_pins axi_iic_0/iic2intc_irpt]
  
  current_bd_instance \
}

# AXI Lite ports
set hpm0_fpd_ports {}
set hpm0_lpd_ports {}

# List of interrupt pins (AXI Intc and direct PL-PS-IRQ1)
set intr_list {}
set priority_intr_list {}

# Number of cameras
set num_cams [llength $cams]

# Add the Processor System and apply board preset
create_bd_cell -type ip -vlnv xilinx.com:ip:zynq_ultra_ps_e zynq_ultra_ps_e_0
apply_bd_automation -rule xilinx.com:bd_rule:zynq_ultra_ps_e -config {apply_board_preset "1" }  [get_bd_cells zynq_ultra_ps_e_0]

# Configure the PS
set_property -dict [list \
  CONFIG.PSU__USE__S_AXI_GP0 {1} \
  CONFIG.PSU__USE__S_AXI_GP1 {1} \
  CONFIG.PSU__USE__S_AXI_GP2 {1} \
  CONFIG.PSU__USE__S_AXI_GP3 {1} \
  CONFIG.PSU__USE__S_AXI_GP4 {1} \
  CONFIG.PSU__USE__S_AXI_GP5 {1} \
  CONFIG.PSU__USE__S_AXI_GP6 {1} \
  CONFIG.PSU__USE__M_AXI_GP0 {1} \
  CONFIG.PSU__USE__M_AXI_GP1 {1} \
  CONFIG.PSU__USE__M_AXI_GP2 {1} \
  CONFIG.PSU__USE__S_AXI_GP6 {1} \
  CONFIG.PSU__USE__IRQ0 {1} \
  CONFIG.PSU__USE__IRQ1 {1} \
  CONFIG.PSU__DISPLAYPORT__LANE0__ENABLE [expr {[dict get $dp_dict $board_name dp_lane0] ne ""}] \
  CONFIG.PSU__DISPLAYPORT__LANE0__IO [dict get $dp_dict $board_name dp_lane0] \
  CONFIG.PSU__DISPLAYPORT__LANE1__ENABLE [expr {[dict get $dp_dict $board_name dp_lane1] ne ""}] \
  CONFIG.PSU__DISPLAYPORT__LANE1__IO [dict get $dp_dict $board_name dp_lane1] \
  CONFIG.PSU__DISPLAYPORT__PERIPHERAL__ENABLE {1} \
  CONFIG.PSU__DPAUX__PERIPHERAL__ENABLE {1} \
  CONFIG.PSU__DPAUX__PERIPHERAL__IO [dict get $dp_dict $board_name dpaux] \
  CONFIG.PSU__DP__LANE_SEL [dict get $dp_dict $board_name lane_sel] \
  CONFIG.PSU__DP__REF_CLK_FREQ [dict get $dp_dict $board_name ref_clk_freq] \
  CONFIG.PSU__DP__REF_CLK_SEL [dict get $dp_dict $board_name ref_clk_sel] \
  CONFIG.PSU__USE__VIDEO {1} \
  CONFIG.PSU__GPIO_EMIO__PERIPHERAL__ENABLE {1} \
  CONFIG.PSU__GPIO_EMIO__PERIPHERAL__IO {95} \
] [get_bd_cells zynq_ultra_ps_e_0]

# Add a processor system reset
create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset rst_ps_100M
connect_bd_net [get_bd_pins zynq_ultra_ps_e_0/pl_clk0] [get_bd_pins rst_ps_100M/slowest_sync_clk]
connect_bd_net [get_bd_pins zynq_ultra_ps_e_0/pl_resetn0] [get_bd_pins rst_ps_100M/ext_reset_in]

# Add and configure the clock wizard
set clk_wiz_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:clk_wiz clk_wiz_0 ]
set_property -dict [list \
  CONFIG.OPTIMIZE_CLOCKING_STRUCTURE_EN {true} \
  CONFIG.CLKOUT1_JITTER {85.183} \
  CONFIG.CLKOUT1_PHASE_ERROR {76.968} \
  CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {200.000} \
  CONFIG.CLKOUT2_JITTER {96.285} \
  CONFIG.CLKOUT2_PHASE_ERROR {76.968} \
  CONFIG.CLKOUT2_REQUESTED_OUT_FREQ {100.000} \
  CONFIG.CLKOUT2_USED {true} \
  CONFIG.CLKOUT3_JITTER {79.342} \
  CONFIG.CLKOUT3_PHASE_ERROR {76.968} \
  CONFIG.CLKOUT3_REQUESTED_OUT_FREQ {300.000} \
  CONFIG.CLKOUT3_USED {true} \
  CONFIG.CLKOUT4_JITTER {108.953} \
  CONFIG.CLKOUT4_PHASE_ERROR {76.968} \
  CONFIG.CLKOUT4_REQUESTED_OUT_FREQ {50} \
  CONFIG.CLKOUT4_USED {true} \
  CONFIG.CLKOUT5_JITTER {81.912} \
  CONFIG.CLKOUT5_PHASE_ERROR {76.968}\
  CONFIG.CLKOUT5_REQUESTED_OUT_FREQ {250} \
  CONFIG.CLKOUT5_USED {true} \
  CONFIG.MMCM_CLKFBOUT_MULT_F {15.000} \
  CONFIG.MMCM_CLKOUT0_DIVIDE_F {7.500} \
  CONFIG.MMCM_CLKOUT1_DIVIDE {15} \
  CONFIG.MMCM_CLKOUT2_DIVIDE {5} \
  CONFIG.MMCM_CLKOUT3_DIVIDE {30} \
  CONFIG.MMCM_CLKOUT4_DIVIDE {6} \
  CONFIG.RESET_PORT {resetn} \
  CONFIG.RESET_TYPE {ACTIVE_LOW} \
  CONFIG.CLK_OUT1_PORT {clk_200M} \
  CONFIG.CLK_OUT2_PORT {clk_100M} \
  CONFIG.CLK_OUT3_PORT {clk_300M} \
  CONFIG.CLK_OUT4_PORT {clk_50M} \
  CONFIG.CLK_OUT5_PORT {clk_250M} \
  CONFIG.NUM_OUT_CLKS {5} \
] $clk_wiz_0
connect_bd_net [get_bd_pins zynq_ultra_ps_e_0/pl_clk0] [get_bd_pins clk_wiz_0/clk_in1]
connect_bd_net [get_bd_pins rst_ps_100M/peripheral_aresetn] [get_bd_pins clk_wiz_0/resetn]

# Connect PS interface clocks
connect_bd_net [get_bd_pins clk_wiz_0/clk_250M] [get_bd_pins zynq_ultra_ps_e_0/saxihpc0_fpd_aclk]
connect_bd_net [get_bd_pins clk_wiz_0/clk_300M] [get_bd_pins zynq_ultra_ps_e_0/saxihpc1_fpd_aclk]
connect_bd_net [get_bd_pins clk_wiz_0/clk_300M] [get_bd_pins zynq_ultra_ps_e_0/saxihp1_fpd_aclk]
connect_bd_net [get_bd_pins clk_wiz_0/clk_300M] [get_bd_pins zynq_ultra_ps_e_0/saxihp2_fpd_aclk]
connect_bd_net [get_bd_pins clk_wiz_0/clk_250M] [get_bd_pins zynq_ultra_ps_e_0/saxihp3_fpd_aclk]

# Add and configure reset processor system for the AXI clock
set rst_ps_axi_100M [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset rst_ps_axi_100M ]
connect_bd_net [get_bd_pins clk_wiz_0/clk_100M] [get_bd_pins rst_ps_axi_100M/slowest_sync_clk]
connect_bd_net [get_bd_pins rst_ps_100M/peripheral_aresetn] [get_bd_pins rst_ps_axi_100M/ext_reset_in]
connect_bd_net [get_bd_pins clk_wiz_0/locked] [get_bd_pins rst_ps_axi_100M/dcm_locked]

# Add and configure reset processor system for the video clock
set rst_video_300M [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset rst_video_300M ]
connect_bd_net [get_bd_pins clk_wiz_0/clk_300M] [get_bd_pins rst_video_300M/slowest_sync_clk]
connect_bd_net [get_bd_pins rst_ps_100M/peripheral_aresetn] [get_bd_pins rst_video_300M/ext_reset_in]
connect_bd_net [get_bd_pins clk_wiz_0/locked] [get_bd_pins rst_video_300M/dcm_locked]

# Add and configure reset processor system for the RPi video clock
set rst_video_250M [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset rst_video_250M ]
connect_bd_net [get_bd_pins clk_wiz_0/clk_250M] [get_bd_pins rst_video_250M/slowest_sync_clk]
connect_bd_net [get_bd_pins rst_ps_100M/peripheral_aresetn] [get_bd_pins rst_video_250M/ext_reset_in]
connect_bd_net [get_bd_pins clk_wiz_0/locked] [get_bd_pins rst_video_250M/dcm_locked]

# Add AXI Intc
set axi_intc_0 [create_bd_cell -type ip -vlnv xilinx.com:ip:axi_intc axi_intc_0]
set_property -dict [list CONFIG.C_IRQ_CONNECTION {1}] $axi_intc_0
set concat_0 [create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat xlconcat_0]
connect_bd_net [get_bd_pins clk_wiz_0/clk_100M] [get_bd_pins axi_intc_0/s_axi_aclk]
connect_bd_net [get_bd_pins xlconcat_0/dout] [get_bd_pins axi_intc_0/intr]
connect_bd_net [get_bd_pins axi_intc_0/irq] [get_bd_pins zynq_ultra_ps_e_0/pl_ps_irq0]
connect_bd_net [get_bd_pins rst_ps_axi_100M/peripheral_aresetn] [get_bd_pins axi_intc_0/s_axi_aresetn]
lappend hpm0_lpd_ports [list "axi_intc_0/s_axi" "clk_wiz_0/clk_100M" "rst_ps_axi_100M/peripheral_aresetn"]

# Add constant for the CAM1 and CAM3 CLK_SEL pin (01b for UltraZed-EV Carrier and 00b for Genesys ZU, 10b for all other boards)
set clk_sel [create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant clk_sel]
set_property -dict [list CONFIG.CONST_WIDTH {2}] $clk_sel
if { $target == "uzev" } {
  set_property -dict [list CONFIG.CONST_VAL {0x01}] $clk_sel
} elseif { $target == "genesyszu" } {
  set_property -dict [list CONFIG.CONST_VAL {0x00}] $clk_sel
} else {
  set_property -dict [list CONFIG.CONST_VAL {0x02}] $clk_sel
}
create_bd_port -dir O clk_sel
connect_bd_net [get_bd_ports clk_sel] [get_bd_pins clk_sel/dout]

# Add and configure GPIO for the reserved GPIOs
set rsvd_gpio [create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio rsvd_gpio]
set_property -dict [list CONFIG.C_GPIO_WIDTH {10} CONFIG.C_ALL_OUTPUTS {1}] $rsvd_gpio
connect_bd_net [get_bd_pins clk_wiz_0/clk_100M] [get_bd_pins rsvd_gpio/s_axi_aclk]
connect_bd_net [get_bd_pins rst_ps_axi_100M/peripheral_aresetn] [get_bd_pins rsvd_gpio/s_axi_aresetn]
lappend hpm0_lpd_ports [list "rsvd_gpio/S_AXI" "clk_wiz_0/clk_100M" "rst_ps_axi_100M/peripheral_aresetn"]
create_bd_intf_port -mode Master -vlnv xilinx.com:interface:gpio_rtl:1.0 rsvd_gpio
connect_bd_intf_net [get_bd_intf_pins rsvd_gpio/GPIO] [get_bd_intf_ports rsvd_gpio]

# Add the AXI SmartConnect for the Frame Buffer Writes A
create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect smartconnect_cams
connect_bd_net [get_bd_pins clk_wiz_0/clk_250M] [get_bd_pins smartconnect_cams/aclk]
connect_bd_net [get_bd_pins rst_video_250M/peripheral_aresetn] [get_bd_pins smartconnect_cams/aresetn]
connect_bd_intf_net [get_bd_intf_pins smartconnect_cams/M00_AXI] [get_bd_intf_pins zynq_ultra_ps_e_0/S_AXI_HPC0_FPD]
set_property -dict [list CONFIG.NUM_SI $num_cams] [get_bd_cells smartconnect_cams]

# Add the MIPI pipes
set cam_index 0
foreach i $cams {
  # Create the MIPI pipe block
  create_mipi_pipe $i [dict get $mipi_loc_dict $target $i]
  # Externalize all of the strobe propagation pins
  set strobe_pins [get_bd_pins mipi_$i/mipi_csi2_rx_subsyst_0/bg*_nc]
  foreach strobe $strobe_pins {
    set strobe_pin_name [file tail $strobe]
    create_bd_port -dir I mipi_${i}_$strobe_pin_name
    connect_bd_net [get_bd_ports mipi_${i}_$strobe_pin_name] [get_bd_pins $strobe]
  }
  # Connect clocks
  connect_bd_net [get_bd_pins clk_wiz_0/clk_200M] [get_bd_pins mipi_$i/dphy_clk_200M]
  connect_bd_net [get_bd_pins clk_wiz_0/clk_100M] [get_bd_pins mipi_$i/s_axi_lite_aclk]
  connect_bd_net [get_bd_pins clk_wiz_0/clk_250M] [get_bd_pins mipi_$i/video_aclk]
  # Connect resets
  connect_bd_net [get_bd_pins rst_ps_axi_100M/peripheral_aresetn] [get_bd_pins mipi_$i/aresetn]
  connect_bd_net [get_bd_pins rst_video_250M/peripheral_aresetn] [get_bd_pins mipi_$i/video_aresetn]
  # Connect EMIO GPIO
  connect_bd_net [get_bd_pins zynq_ultra_ps_e_0/emio_gpio_o] [get_bd_pins mipi_$i/emio_gpio]
  # Add interrupts to the interrupt list to be connected later
  lappend intr_list "mipi_$i/mipi_sub_irq"
  lappend intr_list "mipi_$i/isppipeline_irq"
  lappend intr_list "mipi_$i/frmbufwr_irq"
  lappend intr_list "mipi_$i/iic2intc_irpt"
  
  # AXI Lite interfaces to be connected later
  lappend hpm0_lpd_ports [list "mipi_$i/S_AXI_CTRL" "clk_wiz_0/clk_100M" "rst_ps_axi_100M/peripheral_aresetn"]
  lappend hpm0_fpd_ports [list "mipi_$i/S_AXI_VIDEO" "clk_wiz_0/clk_250M" "rst_video_250M/peripheral_aresetn"]
  # Connect the MIPI D-Phy interface
  create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:mipi_phy_rtl:1.0 mipi_phy_if_$i
  connect_bd_intf_net [get_bd_intf_ports mipi_phy_if_$i] -boundary_type upper [get_bd_intf_pins mipi_$i/mipi_phy_if]
  # Connect the I2C interface
  create_bd_intf_port -mode Master -vlnv xilinx.com:interface:iic_rtl:1.0 iic_$i
  connect_bd_intf_net [get_bd_intf_ports iic_$i] [get_bd_intf_pins mipi_$i/IIC]
  # Connect the GPIO interface
  create_bd_intf_port -mode Master -vlnv xilinx.com:interface:gpio_rtl:1.0 gpio_$i
  connect_bd_intf_net [get_bd_intf_ports gpio_$i] [get_bd_intf_pins mipi_$i/GPIO]
  # Connect the AXI MM interfaces of the Frame Buffers
  connect_bd_intf_net -boundary_type upper [get_bd_intf_pins mipi_$i/m_axi_mm_video] [get_bd_intf_pins smartconnect_cams/S0${cam_index}_AXI]
  # Increment the cam index
  set cam_index [expr {$cam_index+1}]
}

# Connect DP Auxiliary channel on targets that route it via EMIO
if {[dict get $dp_dict $board_name dpaux] == "EMIO"} {
  # Inverter for the dp_aux_data_oe_n signal
  set invert_dp_aux_doe [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic invert_dp_aux_doe ]
  set_property -dict [ list \
    CONFIG.C_OPERATION {not} \
    CONFIG.C_SIZE {1} \
    CONFIG.LOGO_FILE {data/sym_notgate.png} \
  ] $invert_dp_aux_doe
  # Create the external ports
  set dp_aux_din [ create_bd_port -dir I dp_aux_din ]
  set dp_aux_doe [ create_bd_port -dir O -from 0 -to 0 dp_aux_doe ]
  set dp_aux_dout [ create_bd_port -dir O dp_aux_dout ]
  set dp_aux_hotplug_detect [ create_bd_port -dir I dp_aux_hotplug_detect ]
  # Connect the ports
  connect_bd_net [get_bd_ports dp_aux_din] [get_bd_pins zynq_ultra_ps_e_0/dp_aux_data_in]
  connect_bd_net [get_bd_ports dp_aux_hotplug_detect] [get_bd_pins zynq_ultra_ps_e_0/dp_hot_plug_detect]
  connect_bd_net [get_bd_ports dp_aux_doe] [get_bd_pins invert_dp_aux_doe/Res]
  connect_bd_net [get_bd_pins invert_dp_aux_doe/Op1] [get_bd_pins zynq_ultra_ps_e_0/dp_aux_data_oe_n]  
  connect_bd_net [get_bd_ports dp_aux_dout] [get_bd_pins zynq_ultra_ps_e_0/dp_aux_data_out]
}

# Add PCIe system for FPGA Drive FMC
# For now we set it up for ZCU106 HPC1 only (single SSD, single lane)
set dual_design 0
set num_lanes { X1 }

# Add the DMA/Bridge Subsystem for PCIe IPs
create_bd_cell -type ip -vlnv xilinx.com:ip:xdma xdma_0
if {$dual_design} {
  create_bd_cell -type ip -vlnv xilinx.com:ip:xdma xdma_1
}

# ZCU106 HPC0 has enough MGTs for all 4-lanes for SSD1 and SSD2
# ZCU106 HPC1 has only 1x MGT for SSD1 (cannot support SSD2)
# ZCU104 LPC has only 1x MGT for SSD1
if {[lindex $num_lanes 0] == "X4"} {
  # 4-lane PCIe config
  set max_link_width X4
  set axi_data_width 128_bit
  set axisten_freq 250
  set pf_device_id 9134
} else {
  # 1-lane PCIe config
  set max_link_width X1
  set axi_data_width 64_bit
  set axisten_freq 125
  set pf_device_id 9131
}

# ##########################################################
# Configure DMA/Bridge Subsystem for PCIe IP
# ##########################################################
# Notes:
# (1) The high speed PCIe traces on the FPGA Drive FMC are very
#    short, so there is very low signal loss between the FPGA
#    and the SSD. For this reason, it is best to use the
#    "Chip-to-Chip" loss profile in the "GT Settings" (the
#    default is "Add-on card"). Also, the "Chip-to-Chip"
#    profile is the only one that disables the DFE, a feature
#    that is better suited for longer and more lossy traces.
# (2) Answer record 70854 was important in getting the settings
#    right in this design:
#    https://www.xilinx.com/support/answers/70854.html
# (3) On Zynq Ultrascale+ designs, we have found that at least
#    one BAR had to be assigned in the lower 32-bit address space,
#    or the SSD would not be properly enumerated.
# (4) To further the above point, we have also found that if BAR0
#    is placed at address 0x10_0000_0000 (the default value),
#    the NVMe driver crashes on boot. This occurs even when we
#    enable "High Address" in ZynqMP settings "PS-PL Configuration"->
#    "Address Fragmentation": CONFIG.PSU__HIGH_ADDRESS__ENABLE {1}
#    and even when the SSD's BARs are assigned to the lower 32-bit
#    address space via another BAR (eg. BAR1 @ 0xA0000000).
#    It seems that BAR0 must be assigned in the lower 32-bit
#    address space for this to work, which is in line with the
#    answer record mentioned above (although the images in that
#    document do not align with what is written).
#    
set_property -dict [list CONFIG.functional_mode {AXI_Bridge} \
CONFIG.mode_selection {Advanced} \
CONFIG.device_port_type {Root_Port_of_PCI_Express_Root_Complex} \
CONFIG.pl_link_cap_max_link_width $max_link_width \
CONFIG.pl_link_cap_max_link_speed {8.0_GT/s} \
CONFIG.axi_addr_width {49} \
CONFIG.axi_data_width $axi_data_width \
CONFIG.axisten_freq $axisten_freq \
CONFIG.dedicate_perst {false} \
CONFIG.sys_reset_polarity {ACTIVE_LOW} \
CONFIG.pf0_device_id $pf_device_id \
CONFIG.pf0_base_class_menu {Bridge_device} \
CONFIG.pf0_class_code_base {06} \
CONFIG.pf0_sub_class_interface_menu {PCI_to_PCI_bridge} \
CONFIG.pf0_class_code_sub {04} \
CONFIG.pf0_class_code_interface {00} \
CONFIG.pf0_class_code {060400} \
CONFIG.xdma_axilite_slave {true} \
CONFIG.pcie_blk_locn $pcie_blk_locn_0 \
CONFIG.en_gt_selection {true} \
CONFIG.select_quad $select_quad_0 \
CONFIG.INS_LOSS_NYQ {5} \
CONFIG.plltype {QPLL1} \
CONFIG.ins_loss_profile {Chip-to-Chip} \
CONFIG.type1_membase_memlimit_enable {Enabled} \
CONFIG.type1_prefetchable_membase_memlimit {64bit_Enabled} \
CONFIG.axibar_num {1} \
CONFIG.axibar2pciebar_0 {0x00000000A0000000} \
CONFIG.BASEADDR {0x00000000} \
CONFIG.HIGHADDR {0x001FFFFF} \
CONFIG.pf0_bar0_enabled {false} \
CONFIG.pf1_class_code {060700} \
CONFIG.pf1_base_class_menu {Bridge_device} \
CONFIG.pf1_class_code_base {06} \
CONFIG.pf1_class_code_sub {07} \
CONFIG.pf1_sub_class_interface_menu {CardBus_bridge} \
CONFIG.pf1_class_code_interface {00} \
CONFIG.pf1_bar2_enabled {false} \
CONFIG.pf1_bar2_64bit {false} \
CONFIG.pf1_bar4_enabled {false} \
CONFIG.pf1_bar4_64bit {false} \
CONFIG.dma_reset_source_sel {Phy_Ready} \
CONFIG.pf0_bar0_type_mqdma {Memory} \
CONFIG.pf1_bar0_type_mqdma {Memory} \
CONFIG.pf2_bar0_type_mqdma {Memory} \
CONFIG.pf3_bar0_type_mqdma {Memory} \
CONFIG.pf0_sriov_bar0_type {Memory} \
CONFIG.pf1_sriov_bar0_type {Memory} \
CONFIG.pf2_sriov_bar0_type {Memory} \
CONFIG.pf3_sriov_bar0_type {Memory} \
CONFIG.PF0_DEVICE_ID_mqdma $pf_device_id \
CONFIG.PF2_DEVICE_ID_mqdma $pf_device_id \
CONFIG.PF3_DEVICE_ID_mqdma $pf_device_id \
CONFIG.pf0_base_class_menu_mqdma {Bridge_device} \
CONFIG.pf0_class_code_base_mqdma {06} \
CONFIG.pf0_class_code_mqdma {068000} \
CONFIG.pf1_base_class_menu_mqdma {Bridge_device} \
CONFIG.pf1_class_code_base_mqdma {06} \
CONFIG.pf1_class_code_mqdma {068000} \
CONFIG.pf2_base_class_menu_mqdma {Bridge_device} \
CONFIG.pf2_class_code_base_mqdma {06} \
CONFIG.pf2_class_code_mqdma {068000} \
CONFIG.pf3_base_class_menu_mqdma {Bridge_device} \
CONFIG.pf3_class_code_base_mqdma {06} \
CONFIG.pf3_class_code_mqdma {068000}] [get_bd_cells xdma_0]

if {$dual_design} {
  # Create xdma_1 and place it at PCIe block X0Y0
  set_property -dict [list CONFIG.functional_mode {AXI_Bridge} \
  CONFIG.mode_selection {Advanced} \
  CONFIG.device_port_type {Root_Port_of_PCI_Express_Root_Complex} \
  CONFIG.pl_link_cap_max_link_width $max_link_width \
  CONFIG.pl_link_cap_max_link_speed {8.0_GT/s} \
  CONFIG.axi_addr_width {49} \
  CONFIG.axi_data_width $axi_data_width \
  CONFIG.axisten_freq $axisten_freq \
  CONFIG.dedicate_perst {false} \
  CONFIG.sys_reset_polarity {ACTIVE_LOW} \
  CONFIG.pf0_device_id $pf_device_id \
  CONFIG.pf0_base_class_menu {Bridge_device} \
  CONFIG.pf0_class_code_base {06} \
  CONFIG.pf0_sub_class_interface_menu {PCI_to_PCI_bridge} \
  CONFIG.pf0_class_code_sub {04} \
  CONFIG.pf0_class_code_interface {00} \
  CONFIG.pf0_class_code {060400} \
  CONFIG.xdma_axilite_slave {true} \
  CONFIG.pcie_blk_locn $pcie_blk_locn_1 \
  CONFIG.en_gt_selection {true} \
  CONFIG.select_quad $select_quad_1 \
  CONFIG.INS_LOSS_NYQ {5} \
  CONFIG.plltype {QPLL1} \
  CONFIG.ins_loss_profile {Chip-to-Chip} \
  CONFIG.type1_membase_memlimit_enable {Enabled} \
  CONFIG.type1_prefetchable_membase_memlimit {64bit_Enabled} \
  CONFIG.axibar_num {1} \
  CONFIG.axibar2pciebar_0 {0x00000000B0000000} \
  CONFIG.BASEADDR {0x00000000} \
  CONFIG.HIGHADDR {0x001FFFFF} \
  CONFIG.pf0_bar0_enabled {false} \
  CONFIG.pf1_class_code {060700} \
  CONFIG.pf1_base_class_menu {Bridge_device} \
  CONFIG.pf1_class_code_base {06} \
  CONFIG.pf1_class_code_sub {07} \
  CONFIG.pf1_sub_class_interface_menu {CardBus_bridge} \
  CONFIG.pf1_class_code_interface {00} \
  CONFIG.pf1_bar2_enabled {false} \
  CONFIG.pf1_bar2_64bit {false} \
  CONFIG.pf1_bar4_enabled {false} \
  CONFIG.pf1_bar4_64bit {false} \
  CONFIG.dma_reset_source_sel {Phy_Ready} \
  CONFIG.pf0_bar0_type_mqdma {Memory} \
  CONFIG.pf1_bar0_type_mqdma {Memory} \
  CONFIG.pf2_bar0_type_mqdma {Memory} \
  CONFIG.pf3_bar0_type_mqdma {Memory} \
  CONFIG.pf0_sriov_bar0_type {Memory} \
  CONFIG.pf1_sriov_bar0_type {Memory} \
  CONFIG.pf2_sriov_bar0_type {Memory} \
  CONFIG.pf3_sriov_bar0_type {Memory} \
  CONFIG.PF0_DEVICE_ID_mqdma $pf_device_id \
  CONFIG.PF2_DEVICE_ID_mqdma $pf_device_id \
  CONFIG.PF3_DEVICE_ID_mqdma $pf_device_id \
  CONFIG.pf0_base_class_menu_mqdma {Bridge_device} \
  CONFIG.pf0_class_code_base_mqdma {06} \
  CONFIG.pf0_class_code_mqdma {068000} \
  CONFIG.pf1_base_class_menu_mqdma {Bridge_device} \
  CONFIG.pf1_class_code_base_mqdma {06} \
  CONFIG.pf1_class_code_mqdma {068000} \
  CONFIG.pf2_base_class_menu_mqdma {Bridge_device} \
  CONFIG.pf2_class_code_base_mqdma {06} \
  CONFIG.pf2_class_code_mqdma {068000} \
  CONFIG.pf3_base_class_menu_mqdma {Bridge_device} \
  CONFIG.pf3_class_code_base_mqdma {06} \
  CONFIG.pf3_class_code_mqdma {068000}] [get_bd_cells xdma_1]
}

# Answer record 71106: Zynq Ultrascale+ MPSoC - PL PCIe Root Port Bridge (Vivado 2018.1)
# - MSI Interrupt handling causes downstream devices to time out
# https://www.xilinx.com/support/answers/71106.html
set_property -dict [list CONFIG.msi_rx_pin_en {true}] [get_bd_cells xdma_0]
if {$dual_design} {
  set_property -dict [list CONFIG.msi_rx_pin_en {true}] [get_bd_cells xdma_1]
}

# Create AXI Interconnect for the XDMA slave interfaces
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect periph_intercon_0
if {$dual_design} {
  create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect periph_intercon_1
}

# Use connection automation after configuration of the PCIe block - so it will assign 512MB to the S_AXI_CTL interfaces
apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/xdma_0/axi_aclk (250 MHz)} Clk_slave {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Clk_xbar {Auto} Master {/xdma_0/M_AXI_B} Slave {/zynq_ultra_ps_e_0/S_AXI_HP0_FPD} intc_ip {New AXI Interconnect} master_apm {0}}  [get_bd_intf_pins zynq_ultra_ps_e_0/S_AXI_HP0_FPD]
apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Clk_slave {/xdma_0/axi_aclk (250 MHz)} Clk_xbar {Auto} Master {/zynq_ultra_ps_e_0/M_AXI_HPM1_FPD} Slave {/xdma_0/S_AXI_B} intc_ip {periph_intercon_0} master_apm {0}}  [get_bd_intf_pins xdma_0/S_AXI_B]
apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Clk_slave {/xdma_0/axi_aclk (250 MHz)} Clk_xbar {Auto} Master {/zynq_ultra_ps_e_0/M_AXI_HPM1_FPD} Slave {/xdma_0/S_AXI_LITE} intc_ip {periph_intercon_0} master_apm {0}}  [get_bd_intf_pins xdma_0/S_AXI_LITE]
if {$dual_design} {
  apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/xdma_1/axi_aclk (250 MHz)} Clk_slave {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Clk_xbar {Auto} Master {/xdma_1/M_AXI_B} Slave {/zynq_ultra_ps_e_0/S_AXI_HP1_FPD} intc_ip {New AXI Interconnect} master_apm {0}}  [get_bd_intf_pins zynq_ultra_ps_e_0/S_AXI_HP1_FPD]
  apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Clk_slave {/xdma_1/axi_aclk (250 MHz)} Clk_xbar {Auto} Master {/zynq_ultra_ps_e_0/M_AXI_HPM1_FPD} Slave {/xdma_1/S_AXI_B} intc_ip {periph_intercon_1} master_apm {0}}  [get_bd_intf_pins xdma_1/S_AXI_B]
  apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Clk_slave {/xdma_1/axi_aclk (250 MHz)} Clk_xbar {Auto} Master {/zynq_ultra_ps_e_0/M_AXI_HPM1_FPD} Slave {/xdma_1/S_AXI_LITE} intc_ip {periph_intercon_1} master_apm {0}}  [get_bd_intf_pins xdma_1/S_AXI_LITE]
}

# Set the BAR0 offsets and sizes
set_property offset 0x00B0000000 [get_bd_addr_segs {zynq_ultra_ps_e_0/Data/SEG_xdma_0_BAR0}]
set_property range 256M [get_bd_addr_segs {zynq_ultra_ps_e_0/Data/SEG_xdma_0_BAR0}]
if {$dual_design} {
  set_property offset 0x00B0000000 [get_bd_addr_segs {zynq_ultra_ps_e_0/Data/SEG_xdma_1_BAR0}]
  set_property range 256M [get_bd_addr_segs {zynq_ultra_ps_e_0/Data/SEG_xdma_1_BAR0}]
}

# Add MGT external port for PCIe (SSD1)
create_bd_intf_port -mode Master -vlnv xilinx.com:interface:pcie_7x_mgt_rtl:1.0 pci_exp_0
connect_bd_intf_net [get_bd_intf_pins xdma_0/pcie_mgt] [get_bd_intf_ports pci_exp_0]

# Add MGT external port for PCIe (SSD2)
if {$dual_design} {
  create_bd_intf_port -mode Master -vlnv xilinx.com:interface:pcie_7x_mgt_rtl:1.0 pci_exp_1
  connect_bd_intf_net [get_bd_intf_pins xdma_1/pcie_mgt] [get_bd_intf_ports pci_exp_1]
}

# Add differential buffer for the 100MHz PCIe reference clock (SSD1)
create_bd_cell -type ip -vlnv xilinx.com:ip:util_ds_buf ref_clk_0_buf
set_property -dict [list CONFIG.C_BUF_TYPE {IBUFDSGTE}] [get_bd_cells ref_clk_0_buf]
# sys_clk and sys_clk_gt connected as per DMA/Bridge Subsystem for PCIe Product guide PG195
# https://www.xilinx.com/support/documentation/ip_documentation/xdma/v2_0/pg195-pcie-dma.pdf
connect_bd_net [get_bd_pins ref_clk_0_buf/IBUF_DS_ODIV2] [get_bd_pins xdma_0/sys_clk]
connect_bd_net [get_bd_pins ref_clk_0_buf/IBUF_OUT] [get_bd_pins xdma_0/sys_clk_gt]
create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 ref_clk_0
connect_bd_intf_net [get_bd_intf_pins ref_clk_0_buf/CLK_IN_D] [get_bd_intf_ports ref_clk_0]

# Add differential buffer for the 100MHz PCIe reference clock (SSD2)
if {$dual_design} {
  create_bd_cell -type ip -vlnv xilinx.com:ip:util_ds_buf ref_clk_1_buf
  set_property -dict [list CONFIG.C_BUF_TYPE {IBUFDSGTE}] [get_bd_cells ref_clk_1_buf]
  # sys_clk and sys_clk_gt connected as per DMA/Bridge Subsystem for PCIe Product guide PG195
  # https://www.xilinx.com/support/documentation/ip_documentation/xdma/v2_0/pg195-pcie-dma.pdf
  connect_bd_net [get_bd_pins ref_clk_1_buf/IBUF_DS_ODIV2] [get_bd_pins xdma_1/sys_clk]
  connect_bd_net [get_bd_pins ref_clk_1_buf/IBUF_OUT] [get_bd_pins xdma_1/sys_clk_gt]
  create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 ref_clk_1
  connect_bd_intf_net [get_bd_intf_pins ref_clk_1_buf/CLK_IN_D] [get_bd_intf_ports ref_clk_1]
}

# Connect interrupts
if {$dual_design} {
  lappend priority_intr_list "xdma_0/interrupt_out"
  lappend priority_intr_list "xdma_1/interrupt_out"
  lappend priority_intr_list "xdma_0/interrupt_out_msi_vec0to31"
  lappend priority_intr_list "xdma_0/interrupt_out_msi_vec32to63"
  lappend priority_intr_list "xdma_1/interrupt_out_msi_vec0to31"
  lappend priority_intr_list "xdma_1/interrupt_out_msi_vec32to63"
} else {
  lappend priority_intr_list "xdma_0/interrupt_out"
  lappend priority_intr_list "xdma_0/interrupt_out_msi_vec0to31"
  lappend priority_intr_list "xdma_0/interrupt_out_msi_vec32to63"
}

# Add proc system reset for xdma_0/axi_ctl_aresetn
create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset rst_pcie_0_axi_aclk
connect_bd_net [get_bd_pins xdma_0/axi_aclk] [get_bd_pins rst_pcie_0_axi_aclk/slowest_sync_clk]
connect_bd_net [get_bd_pins xdma_0/axi_ctl_aresetn] [get_bd_pins rst_pcie_0_axi_aclk/ext_reset_in]
disconnect_bd_net /xdma_0_axi_aresetn [get_bd_pins periph_intercon_0/M01_ARESETN]
connect_bd_net [get_bd_pins xdma_0/axi_ctl_aresetn] [get_bd_pins periph_intercon_0/M01_ARESETN]

# Add proc system reset for xdma_1/axi_ctl_aresetn
if {$dual_design} {
  create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset rst_pcie_1_axi_aclk
  connect_bd_net [get_bd_pins xdma_1/axi_aclk] [get_bd_pins rst_pcie_1_axi_aclk/slowest_sync_clk]
  connect_bd_net [get_bd_pins xdma_1/axi_ctl_aresetn] [get_bd_pins rst_pcie_1_axi_aclk/ext_reset_in]
  disconnect_bd_net /xdma_1_axi_aresetn [get_bd_pins periph_intercon_1/M01_ARESETN]
  connect_bd_net [get_bd_pins xdma_1/axi_ctl_aresetn] [get_bd_pins periph_intercon_1/M01_ARESETN]
}

# Create PERST ports
create_bd_port -dir O -from 0 -to 0 -type rst perst_0
connect_bd_net [get_bd_pins /rst_pcie_0_axi_aclk/peripheral_reset] [get_bd_ports perst_0]
if {$dual_design} {
  create_bd_port -dir O -from 0 -to 0 -type rst perst_1
  connect_bd_net [get_bd_pins /rst_pcie_1_axi_aclk/peripheral_reset] [get_bd_ports perst_1]
}

# Connect AXI PCIe reset
connect_bd_net [get_bd_pins zynq_ultra_ps_e_0/pl_resetn0] [get_bd_pins xdma_0/sys_rst_n]
if {$dual_design} {
  connect_bd_net [get_bd_pins zynq_ultra_ps_e_0/pl_resetn0] [get_bd_pins xdma_1/sys_rst_n]
}

# Constant to enable/disable 3.3V power supply of SSD2 and clock source
set const_dis_ssd2_pwr [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant const_dis_ssd2_pwr ]
create_bd_port -dir O disable_ssd2_pwr
connect_bd_net [get_bd_pins const_dis_ssd2_pwr/dout] [get_bd_ports disable_ssd2_pwr]
if {$dual_design} {
  # LOW to enable SSD2
  set_property -dict [list CONFIG.CONST_VAL {0}] $const_dis_ssd2_pwr
} else {
  # HIGH to disable SSD2
  set_property -dict [list CONFIG.CONST_VAL {1}] $const_dis_ssd2_pwr
}

###################################################################
# VCU
###################################################################

# Create the VCU sub-block
proc create_vcu_block { } {

  set hier_obj [create_bd_cell -type hier vcu]
  current_bd_instance $hier_obj
  
  # Create interface pins
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M00_AXI_VCU_DEC
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M00_AXI_VCU_EN
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M_AXI_VCU_MCU
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI_LITE

  # Create pins
  create_bd_pin -dir I -from 91 -to 0 Din
  create_bd_pin -dir I -type rst aresetn
  create_bd_pin -dir I -type clk m_axi_dec_aclk
  create_bd_pin -dir I -type clk pll_ref_clk
  create_bd_pin -dir I -type clk s_axi_lite_aclk
  create_bd_pin -dir O -type intr vcu_host_interrupt

  # Create instance: axi_ic_vcu_dec, and set properties
  set axi_ic_vcu_dec [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect axi_ic_vcu_dec ]
  set_property -dict [ list \
   CONFIG.M00_HAS_REGSLICE {1} \
   CONFIG.NUM_MI {1} \
   CONFIG.NUM_SI {2} \
   CONFIG.S00_HAS_REGSLICE {1} \
   CONFIG.S01_HAS_REGSLICE {1} \
 ] $axi_ic_vcu_dec

  # Create instance: axi_ic_vcu_enc, and set properties
  set axi_ic_vcu_enc [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect axi_ic_vcu_enc ]
  set_property -dict [ list \
   CONFIG.M00_HAS_REGSLICE {1} \
   CONFIG.NUM_MI {1} \
   CONFIG.NUM_SI {2} \
   CONFIG.S00_HAS_REGSLICE {1} \
   CONFIG.S01_HAS_REGSLICE {1} \
 ] $axi_ic_vcu_enc

  # Create instance: axi_reg_slice_vmcu, and set properties
  set axi_reg_slice_vmcu [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_register_slice axi_reg_slice_vmcu ]

  # Create instance: vcu_0, and set properties
  set vcu_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:vcu vcu_0 ]
  set_property -dict [ list \
   CONFIG.DEC_CODING_TYPE {0} \
   CONFIG.DEC_COLOR_DEPTH {0} \
   CONFIG.DEC_COLOR_FORMAT {0} \
   CONFIG.DEC_FPS {1} \
   CONFIG.DEC_FRAME_SIZE {4} \
   CONFIG.ENABLE_DECODER {true} \
   CONFIG.ENC_BUFFER_EN {true} \
   CONFIG.ENC_BUFFER_MANUAL_OVERRIDE {1} \
   CONFIG.ENC_BUFFER_SIZE {253} \
   CONFIG.ENC_BUFFER_SIZE_ACTUAL {284} \
   CONFIG.ENC_BUFFER_TYPE {0} \
   CONFIG.ENC_CODING_TYPE {1} \
   CONFIG.ENC_COLOR_DEPTH {0} \
   CONFIG.ENC_COLOR_FORMAT {0} \
   CONFIG.ENC_FPS {1} \
   CONFIG.ENC_FRAME_SIZE {4} \
   CONFIG.ENC_MEM_BRAM_USED {0} \
   CONFIG.ENC_MEM_URAM_USED {284} \
   CONFIG.NO_OF_DEC_STREAMS {1} \
   CONFIG.NO_OF_STREAMS {1} \
   CONFIG.TABLE_NO {2} \
 ] $vcu_0

  # Create instance: xlslice_0, and set properties
  set xlslice_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice xlslice_0 ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {0} \
   CONFIG.DIN_TO {0} \
   CONFIG.DIN_WIDTH {95} \
   CONFIG.DOUT_WIDTH {1} \
 ] $xlslice_0

  # Create interface connections
  connect_bd_intf_net -intf_net S00_AXI_1 [get_bd_intf_pins axi_ic_vcu_enc/S00_AXI] [get_bd_intf_pins vcu_0/M_AXI_ENC0]
  connect_bd_intf_net -intf_net S00_AXI_2 [get_bd_intf_pins axi_ic_vcu_dec/S00_AXI] [get_bd_intf_pins vcu_0/M_AXI_DEC0]
  connect_bd_intf_net -intf_net S01_AXI_1 [get_bd_intf_pins axi_ic_vcu_enc/S01_AXI] [get_bd_intf_pins vcu_0/M_AXI_ENC1]
  connect_bd_intf_net -intf_net S01_AXI_2 [get_bd_intf_pins axi_ic_vcu_dec/S01_AXI] [get_bd_intf_pins vcu_0/M_AXI_DEC1]
  connect_bd_intf_net -intf_net axi_ic_vcu_dec_M00_AXI [get_bd_intf_pins M00_AXI_VCU_DEC] [get_bd_intf_pins axi_ic_vcu_dec/M00_AXI]
  connect_bd_intf_net -intf_net axi_ic_vcu_enc_M00_AXI [get_bd_intf_pins M00_AXI_VCU_EN] [get_bd_intf_pins axi_ic_vcu_enc/M00_AXI]
  connect_bd_intf_net -intf_net axi_register_slice_0_M_AXI [get_bd_intf_pins M_AXI_VCU_MCU] [get_bd_intf_pins axi_reg_slice_vmcu/M_AXI]
  connect_bd_intf_net -intf_net smartconnect_0_M02_AXI [get_bd_intf_pins S_AXI_LITE] [get_bd_intf_pins vcu_0/S_AXI_LITE]
  connect_bd_intf_net -intf_net vcu_0_M_AXI_MCU [get_bd_intf_pins axi_reg_slice_vmcu/S_AXI] [get_bd_intf_pins vcu_0/M_AXI_MCU]

  # Create port connections
  connect_bd_net -net Din_1 [get_bd_pins Din] [get_bd_pins xlslice_0/Din]
  connect_bd_net -net clk_wiz_0_clk_100M [get_bd_pins s_axi_lite_aclk] [get_bd_pins vcu_0/s_axi_lite_aclk]
  connect_bd_net -net clk_wiz_0_clk_300M [get_bd_pins m_axi_dec_aclk] [get_bd_pins axi_ic_vcu_dec/ACLK] [get_bd_pins axi_ic_vcu_dec/M00_ACLK] [get_bd_pins axi_ic_vcu_dec/S00_ACLK] [get_bd_pins axi_ic_vcu_dec/S01_ACLK] [get_bd_pins axi_ic_vcu_enc/ACLK] [get_bd_pins axi_ic_vcu_enc/M00_ACLK] [get_bd_pins axi_ic_vcu_enc/S00_ACLK] [get_bd_pins axi_ic_vcu_enc/S01_ACLK] [get_bd_pins axi_reg_slice_vmcu/aclk] [get_bd_pins vcu_0/m_axi_dec_aclk] [get_bd_pins vcu_0/m_axi_enc_aclk] [get_bd_pins vcu_0/m_axi_mcu_aclk]
  connect_bd_net -net clk_wiz_0_clk_50M [get_bd_pins pll_ref_clk] [get_bd_pins vcu_0/pll_ref_clk]
  connect_bd_net -net proc_sys_reset_1_peripheral_aresetn [get_bd_pins aresetn] [get_bd_pins axi_ic_vcu_dec/ARESETN] [get_bd_pins axi_ic_vcu_dec/M00_ARESETN] [get_bd_pins axi_ic_vcu_dec/S00_ARESETN] [get_bd_pins axi_ic_vcu_dec/S01_ARESETN] [get_bd_pins axi_ic_vcu_enc/ARESETN] [get_bd_pins axi_ic_vcu_enc/M00_ARESETN] [get_bd_pins axi_ic_vcu_enc/S00_ARESETN] [get_bd_pins axi_ic_vcu_enc/S01_ARESETN] [get_bd_pins axi_reg_slice_vmcu/aresetn]
  connect_bd_net -net vcu_0_vcu_host_interrupt [get_bd_pins vcu_host_interrupt] [get_bd_pins vcu_0/vcu_host_interrupt]
  connect_bd_net -net xlslice_0_Dout [get_bd_pins vcu_0/vcu_resetn] [get_bd_pins xlslice_0/Dout]

  # Restore current instance
  current_bd_instance \
}

# Connect SAXI LPD clock whether we use a VCU or not
connect_bd_net [get_bd_pins clk_wiz_0/clk_300M] [get_bd_pins zynq_ultra_ps_e_0/saxi_lpd_aclk]

# Add VCU if this target has one
if {$has_vcu} {
  create_vcu_block
  lappend hpm0_lpd_ports [list "vcu/S_AXI_LITE" "clk_wiz_0/clk_100M" "rst_ps_axi_100M/peripheral_aresetn"]
  connect_bd_net [get_bd_pins clk_wiz_0/clk_100M] [get_bd_pins vcu/s_axi_lite_aclk]
  connect_bd_net [get_bd_pins clk_wiz_0/clk_300M] [get_bd_pins vcu/m_axi_dec_aclk]
  connect_bd_net [get_bd_pins clk_wiz_0/clk_50M] [get_bd_pins vcu/pll_ref_clk]
  connect_bd_net [get_bd_pins rst_video_300M/peripheral_aresetn] [get_bd_pins vcu/aresetn]
  connect_bd_net [get_bd_pins zynq_ultra_ps_e_0/emio_gpio_o] [get_bd_pins vcu/Din]
  set axi_ic_mcu [create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect axi_ic_mcu]
  set_property -dict [list CONFIG.NUM_MI {1}] $axi_ic_mcu
  connect_bd_net [get_bd_pins clk_wiz_0/clk_300M] [get_bd_pins axi_ic_mcu/ACLK]
  connect_bd_net [get_bd_pins clk_wiz_0/clk_300M] [get_bd_pins axi_ic_mcu/S00_ACLK]
  connect_bd_net [get_bd_pins clk_wiz_0/clk_300M] [get_bd_pins axi_ic_mcu/M00_ACLK]
  connect_bd_net [get_bd_pins rst_video_300M/interconnect_aresetn] [get_bd_pins axi_ic_mcu/ARESETN]
  connect_bd_net [get_bd_pins rst_video_300M/peripheral_aresetn] [get_bd_pins axi_ic_mcu/S00_ARESETN]
  connect_bd_net [get_bd_pins rst_video_300M/peripheral_aresetn] [get_bd_pins axi_ic_mcu/M00_ARESETN]
  connect_bd_intf_net -boundary_type upper [get_bd_intf_pins axi_ic_mcu/M00_AXI] [get_bd_intf_pins zynq_ultra_ps_e_0/S_AXI_LPD]
  connect_bd_intf_net -boundary_type upper [get_bd_intf_pins vcu/M_AXI_VCU_MCU] [get_bd_intf_pins axi_ic_mcu/S00_AXI]
  lappend priority_intr_list "vcu/vcu_host_interrupt"
  connect_bd_intf_net -boundary_type upper [get_bd_intf_pins vcu/M00_AXI_VCU_DEC] [get_bd_intf_pins zynq_ultra_ps_e_0/S_AXI_HP2_FPD]
  connect_bd_intf_net -boundary_type upper [get_bd_intf_pins vcu/M00_AXI_VCU_EN] [get_bd_intf_pins zynq_ultra_ps_e_0/S_AXI_HP1_FPD]
}

####################################################
# Display pipeline - to DisplayPort live interface
####################################################
proc create_display_pipeline { } {

  set hier_obj [create_bd_cell -type hier display_pipeline]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M00_AXI
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 s_axi_ctrl_clk_wiz
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 s_axi_ctrl_v_tc
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 s_axi_ctrl_vmix

  # Create pins
  create_bd_pin -dir I -from 91 -to 0 Din
  create_bd_pin -dir I -type clk clk
  create_bd_pin -dir I -type rst ext_reset_in
  create_bd_pin -dir O -type intr irq_v_tc
  create_bd_pin -dir O -type intr irq_vmix
  create_bd_pin -dir I -type rst resetn
  create_bd_pin -dir I -type clk s_axi_aclk
  create_bd_pin -dir I -type rst s_axi_aresetn
  create_bd_pin -dir O vid_active_video
  create_bd_pin -dir O -from 35 -to 0 vid_data
  create_bd_pin -dir O vid_hsync
  create_bd_pin -dir O vid_vsync
  create_bd_pin -dir O video_clk

  # Create instance: axi_interconnect_0, and set properties
  set axi_interconnect_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect axi_interconnect_0 ]
  set_property -dict [ list \
   CONFIG.NUM_MI {1} \
   CONFIG.NUM_SI {5} \
 ] $axi_interconnect_0

  # Create instance: axis_subset_converter_0, and set properties
  set axis_subset_converter_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_subset_converter axis_subset_converter_0 ]
  set_property -dict [ list \
   CONFIG.M_TDATA_NUM_BYTES {2} \
   CONFIG.S_TDATA_NUM_BYTES {3} \
   CONFIG.TDATA_REMAP {tdata[15:0]} \
 ] $axis_subset_converter_0

  # Create instance: clk_wiz_0, and set properties
  set clk_wiz_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:clk_wiz clk_wiz_0 ]
  set_property -dict [ list \
   CONFIG.AUTO_PRIMITIVE {MMCM} \
   CONFIG.CLKOUT1_DRIVES {Buffer} \
   CONFIG.CLKOUT1_JITTER {160.489} \
   CONFIG.CLKOUT1_PHASE_ERROR {282.343} \
   CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {262.75} \
   CONFIG.CLKOUT2_DRIVES {Buffer} \
   CONFIG.CLKOUT3_DRIVES {Buffer} \
   CONFIG.CLKOUT4_DRIVES {Buffer} \
   CONFIG.CLKOUT5_DRIVES {Buffer} \
   CONFIG.CLKOUT6_DRIVES {Buffer} \
   CONFIG.CLKOUT7_DRIVES {Buffer} \
   CONFIG.FEEDBACK_SOURCE {FDBK_AUTO} \
   CONFIG.MMCM_BANDWIDTH {OPTIMIZED} \
   CONFIG.MMCM_CLKFBOUT_MULT_F {59.000} \
   CONFIG.MMCM_CLKOUT0_DIVIDE_F {4.750} \
   CONFIG.MMCM_COMPENSATION {AUTO} \
   CONFIG.MMCM_DIVCLK_DIVIDE {13} \
   CONFIG.PRIMITIVE {MMCM} \
   CONFIG.PRIM_SOURCE {Global_buffer} \
   CONFIG.USE_DYN_RECONFIG {true} \
   CONFIG.USE_LOCKED {true} \
   CONFIG.USE_RESET {true} \
 ] $clk_wiz_0

  # Create instance: proc_sys_reset_0, and set properties
  set proc_sys_reset_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset proc_sys_reset_0 ]

  # Create instance: v_axi4s_vid_out_0, and set properties
  set v_axi4s_vid_out_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:v_axi4s_vid_out v_axi4s_vid_out_0 ]
  set_property -dict [ list \
   CONFIG.C_HAS_ASYNC_CLK {1} \
   CONFIG.C_NATIVE_COMPONENT_WIDTH {8} \
   CONFIG.C_S_AXIS_VIDEO_FORMAT {0} \
   CONFIG.C_VTG_MASTER_SLAVE {1} \
 ] $v_axi4s_vid_out_0

  # Create instance: v_mix_0, and set properties
  set v_mix_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:v_mix v_mix_0 ]
  set_property -dict [ list \
   CONFIG.LAYER1_VIDEO_FORMAT {12} \
   CONFIG.LAYER2_VIDEO_FORMAT {12} \
   CONFIG.LAYER3_VIDEO_FORMAT {12} \
   CONFIG.LAYER4_VIDEO_FORMAT {12} \
   CONFIG.LAYER5_ALPHA {true} \
   CONFIG.LAYER5_VIDEO_FORMAT {26} \
   CONFIG.MAX_COLS {3840} \
   CONFIG.MAX_ROWS {2160} \
   CONFIG.NR_LAYERS {6} \
   CONFIG.VIDEO_FORMAT {2} \
 ] $v_mix_0

  # Create instance: v_tc_0, and set properties
  set v_tc_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:v_tc v_tc_0 ]
  set_property -dict [ list \
   CONFIG.GEN_F0_VBLANK_HEND {960} \
   CONFIG.GEN_F0_VBLANK_HSTART {960} \
   CONFIG.GEN_F0_VFRAME_SIZE {1125} \
   CONFIG.GEN_F0_VSYNC_HEND {1004} \
   CONFIG.GEN_F0_VSYNC_HSTART {1004} \
   CONFIG.GEN_F0_VSYNC_VEND {1088} \
   CONFIG.GEN_F0_VSYNC_VSTART {1083} \
   CONFIG.GEN_F1_VBLANK_HEND {960} \
   CONFIG.GEN_F1_VBLANK_HSTART {960} \
   CONFIG.GEN_F1_VFRAME_SIZE {1125} \
   CONFIG.GEN_F1_VSYNC_HEND {1004} \
   CONFIG.GEN_F1_VSYNC_HSTART {1004} \
   CONFIG.GEN_F1_VSYNC_VEND {1088} \
   CONFIG.GEN_F1_VSYNC_VSTART {1083} \
   CONFIG.GEN_HACTIVE_SIZE {1920} \
   CONFIG.GEN_HFRAME_SIZE {2200} \
   CONFIG.GEN_HSYNC_END {2052} \
   CONFIG.GEN_HSYNC_START {2008} \
   CONFIG.GEN_VACTIVE_SIZE {1080} \
   CONFIG.VIDEO_MODE {1080p} \
   CONFIG.enable_detection {false} \
   CONFIG.max_clocks_per_line {8192} \
 ] $v_tc_0

  # Create instance: xlconcat_0, and set properties
  set xlconcat_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat xlconcat_0 ]
  set_property -dict [ list \
   CONFIG.IN0_WIDTH {16} \
   CONFIG.IN1_WIDTH {8} \
   CONFIG.IN2_WIDTH {4} \
   CONFIG.IN3_WIDTH {8} \
   CONFIG.NUM_PORTS {4} \
 ] $xlconcat_0

  # Create instance: xlconstant_0, and set properties
  set xlconstant_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant xlconstant_0 ]
  set_property -dict [ list \
   CONFIG.CONST_VAL {0} \
   CONFIG.CONST_WIDTH {24} \
 ] $xlconstant_0

  # Create instance: xlconstant_1, and set properties
  set xlconstant_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant xlconstant_1 ]

  # Create instance: xlconstant_2, and set properties
  set xlconstant_2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant xlconstant_2 ]
  set_property -dict [ list \
   CONFIG.CONST_VAL {0} \
   CONFIG.CONST_WIDTH {16} \
 ] $xlconstant_2

  # Create instance: reset_vmix, and set properties
  set reset_vmix [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice reset_vmix ]
  set_property -dict [ list \
   CONFIG.DIN_WIDTH {95} \
   CONFIG.DIN_TO {1} \
   CONFIG.DIN_FROM {1} \
   CONFIG.DOUT_WIDTH {1} \
 ] $reset_vmix

  # Create instance: xlslice_15to8, and set properties
  set xlslice_15to8 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice xlslice_15to8 ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {15} \
   CONFIG.DIN_TO {8} \
   CONFIG.DIN_WIDTH {16} \
   CONFIG.DOUT_WIDTH {8} \
 ] $xlslice_15to8

  # Create instance: xlslice_7to0, and set properties
  set xlslice_7to0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice xlslice_7to0 ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {7} \
   CONFIG.DIN_TO {0} \
   CONFIG.DIN_WIDTH {16} \
   CONFIG.DOUT_WIDTH {8} \
 ] $xlslice_7to0

  # Create interface connections
  connect_bd_intf_net -intf_net Conn1 [get_bd_intf_pins s_axi_ctrl_v_tc] [get_bd_intf_pins v_tc_0/ctrl]
  connect_bd_intf_net -intf_net Conn2 [get_bd_intf_pins s_axi_ctrl_vmix] [get_bd_intf_pins v_mix_0/s_axi_CTRL]
  connect_bd_intf_net -intf_net Conn3 [get_bd_intf_pins M00_AXI] [get_bd_intf_pins axi_interconnect_0/M00_AXI]
  connect_bd_intf_net -intf_net Conn4 [get_bd_intf_pins s_axi_ctrl_clk_wiz] [get_bd_intf_pins clk_wiz_0/s_axi_lite]
  connect_bd_intf_net -intf_net S00_AXI_1 [get_bd_intf_pins axi_interconnect_0/S00_AXI] [get_bd_intf_pins v_mix_0/m_axi_mm_video1]
  connect_bd_intf_net -intf_net S01_AXI_1 [get_bd_intf_pins axi_interconnect_0/S01_AXI] [get_bd_intf_pins v_mix_0/m_axi_mm_video2]
  connect_bd_intf_net -intf_net S02_AXI_1 [get_bd_intf_pins axi_interconnect_0/S02_AXI] [get_bd_intf_pins v_mix_0/m_axi_mm_video3]
  connect_bd_intf_net -intf_net S03_AXI_1 [get_bd_intf_pins axi_interconnect_0/S03_AXI] [get_bd_intf_pins v_mix_0/m_axi_mm_video4]
  connect_bd_intf_net -intf_net S04_AXI_1 [get_bd_intf_pins axi_interconnect_0/S04_AXI] [get_bd_intf_pins v_mix_0/m_axi_mm_video5]
  connect_bd_intf_net -intf_net axis_subset_converter_0_M_AXIS [get_bd_intf_pins axis_subset_converter_0/M_AXIS] [get_bd_intf_pins v_axi4s_vid_out_0/video_in]
  connect_bd_intf_net -intf_net v_mix_0_m_axis_video [get_bd_intf_pins axis_subset_converter_0/S_AXIS] [get_bd_intf_pins v_mix_0/m_axis_video]
  connect_bd_intf_net -intf_net v_tc_0_vtiming_out [get_bd_intf_pins v_axi4s_vid_out_0/vtiming_in] [get_bd_intf_pins v_tc_0/vtiming_out]

  # Create port connections
  connect_bd_net -net Din_1 [get_bd_pins Din] [get_bd_pins reset_vmix/Din]
  connect_bd_net -net clk_1 [get_bd_pins clk] [get_bd_pins axi_interconnect_0/ACLK] -boundary_type upper
  connect_bd_net -net clk_1 [get_bd_pins clk] [get_bd_pins axi_interconnect_0/M00_ACLK] -boundary_type upper
  connect_bd_net -net clk_1 [get_bd_pins clk] [get_bd_pins axi_interconnect_0/S00_ACLK] -boundary_type upper
  connect_bd_net -net clk_1 [get_bd_pins clk] [get_bd_pins axi_interconnect_0/S01_ACLK] -boundary_type upper
  connect_bd_net -net clk_1 [get_bd_pins clk] [get_bd_pins axi_interconnect_0/S02_ACLK] -boundary_type upper
  connect_bd_net -net clk_1 [get_bd_pins clk] [get_bd_pins axi_interconnect_0/S03_ACLK] -boundary_type upper
  connect_bd_net -net clk_1 [get_bd_pins clk] [get_bd_pins axi_interconnect_0/S04_ACLK] -boundary_type upper
  connect_bd_net -net clk_1 [get_bd_pins clk] [get_bd_pins axis_subset_converter_0/aclk] -boundary_type upper
  connect_bd_net -net clk_1 [get_bd_pins clk] [get_bd_pins clk_wiz_0/clk_in1] -boundary_type upper
  connect_bd_net -net clk_1 [get_bd_pins clk] [get_bd_pins v_axi4s_vid_out_0/aclk] -boundary_type upper
  connect_bd_net -net clk_1 [get_bd_pins clk] [get_bd_pins v_mix_0/ap_clk] -boundary_type upper
  connect_bd_net -net clk_wiz_0_clk_out1 [get_bd_pins video_clk] [get_bd_pins clk_wiz_0/clk_out1] -boundary_type upper
  connect_bd_net -net clk_wiz_0_clk_out1 [get_bd_pins video_clk] [get_bd_pins proc_sys_reset_0/slowest_sync_clk] -boundary_type upper
  connect_bd_net -net clk_wiz_0_clk_out1 [get_bd_pins video_clk] [get_bd_pins v_axi4s_vid_out_0/vid_io_out_clk] -boundary_type upper
  connect_bd_net -net clk_wiz_0_clk_out1 [get_bd_pins video_clk] [get_bd_pins v_tc_0/clk] -boundary_type upper
  connect_bd_net -net clk_wiz_0_locked [get_bd_pins clk_wiz_0/locked] [get_bd_pins proc_sys_reset_0/dcm_locked]
  connect_bd_net -net ext_reset_in_1 [get_bd_pins ext_reset_in] [get_bd_pins proc_sys_reset_0/ext_reset_in]
  connect_bd_net -net proc_sys_reset_0_peripheral_aresetn [get_bd_pins proc_sys_reset_0/peripheral_aresetn] [get_bd_pins v_tc_0/resetn]
  connect_bd_net -net proc_sys_reset_0_peripheral_reset [get_bd_pins proc_sys_reset_0/peripheral_reset] [get_bd_pins v_axi4s_vid_out_0/vid_io_out_reset]
  connect_bd_net -net resetn_1 [get_bd_pins resetn] [get_bd_pins axi_interconnect_0/ARESETN] -boundary_type upper
  connect_bd_net -net resetn_1 [get_bd_pins resetn] [get_bd_pins axi_interconnect_0/M00_ARESETN] -boundary_type upper
  connect_bd_net -net resetn_1 [get_bd_pins resetn] [get_bd_pins axi_interconnect_0/S00_ARESETN] -boundary_type upper
  connect_bd_net -net resetn_1 [get_bd_pins resetn] [get_bd_pins axi_interconnect_0/S01_ARESETN] -boundary_type upper
  connect_bd_net -net resetn_1 [get_bd_pins resetn] [get_bd_pins axi_interconnect_0/S02_ARESETN] -boundary_type upper
  connect_bd_net -net resetn_1 [get_bd_pins resetn] [get_bd_pins axi_interconnect_0/S03_ARESETN] -boundary_type upper
  connect_bd_net -net resetn_1 [get_bd_pins resetn] [get_bd_pins axi_interconnect_0/S04_ARESETN] -boundary_type upper
  connect_bd_net -net resetn_1 [get_bd_pins resetn] [get_bd_pins axis_subset_converter_0/aresetn] -boundary_type upper
  connect_bd_net -net resetn_1 [get_bd_pins resetn] [get_bd_pins v_axi4s_vid_out_0/aresetn] -boundary_type upper
  connect_bd_net -net s_axi_aclk_1 [get_bd_pins s_axi_aclk] [get_bd_pins clk_wiz_0/s_axi_aclk] -boundary_type upper
  connect_bd_net -net s_axi_aclk_1 [get_bd_pins s_axi_aclk] [get_bd_pins v_tc_0/s_axi_aclk] -boundary_type upper
  connect_bd_net -net s_axi_aresetn_1 [get_bd_pins s_axi_aresetn] [get_bd_pins clk_wiz_0/s_axi_aresetn] -boundary_type upper
  connect_bd_net -net s_axi_aresetn_1 [get_bd_pins s_axi_aresetn] [get_bd_pins v_tc_0/s_axi_aresetn] -boundary_type upper
  connect_bd_net -net v_axi4s_vid_out_0_sof_state_out [get_bd_pins v_axi4s_vid_out_0/sof_state_out] [get_bd_pins v_tc_0/sof_state]
  connect_bd_net -net v_axi4s_vid_out_0_vid_active_video [get_bd_pins vid_active_video] [get_bd_pins v_axi4s_vid_out_0/vid_active_video]
  connect_bd_net -net v_axi4s_vid_out_0_vid_data [get_bd_pins v_axi4s_vid_out_0/vid_data] [get_bd_pins xlslice_15to8/Din] -boundary_type upper
  connect_bd_net -net v_axi4s_vid_out_0_vid_data [get_bd_pins v_axi4s_vid_out_0/vid_data] [get_bd_pins xlslice_7to0/Din] -boundary_type upper
  connect_bd_net -net v_axi4s_vid_out_0_vid_hsync [get_bd_pins vid_hsync] [get_bd_pins v_axi4s_vid_out_0/vid_hsync]
  connect_bd_net -net v_axi4s_vid_out_0_vid_vsync [get_bd_pins vid_vsync] [get_bd_pins v_axi4s_vid_out_0/vid_vsync]
  connect_bd_net -net v_axi4s_vid_out_0_vtg_ce [get_bd_pins v_axi4s_vid_out_0/vtg_ce] [get_bd_pins v_tc_0/gen_clken]
  connect_bd_net -net v_mix_0_interrupt [get_bd_pins irq_vmix] [get_bd_pins v_mix_0/interrupt]
  connect_bd_net -net v_tc_0_irq [get_bd_pins irq_v_tc] [get_bd_pins v_tc_0/irq]
  connect_bd_net -net xlconcat_0_dout [get_bd_pins vid_data] [get_bd_pins xlconcat_0/dout]
  connect_bd_net -net xlconstant_0_dout [get_bd_pins v_mix_0/s_axis_video_TDATA] [get_bd_pins v_mix_0/s_axis_video_TVALID] -boundary_type upper
  connect_bd_net -net xlconstant_0_dout [get_bd_pins v_mix_0/s_axis_video_TDATA] [get_bd_pins xlconstant_0/dout] -boundary_type upper
  connect_bd_net -net xlconstant_1_dout [get_bd_pins v_axi4s_vid_out_0/aclken] [get_bd_pins v_axi4s_vid_out_0/vid_io_out_ce] -boundary_type upper
  connect_bd_net -net xlconstant_1_dout [get_bd_pins v_axi4s_vid_out_0/aclken] [get_bd_pins v_tc_0/clken] -boundary_type upper
  connect_bd_net -net xlconstant_1_dout [get_bd_pins v_axi4s_vid_out_0/aclken] [get_bd_pins v_tc_0/s_axi_aclken] -boundary_type upper
  connect_bd_net -net xlconstant_1_dout [get_bd_pins v_axi4s_vid_out_0/aclken] [get_bd_pins xlconstant_1/dout] -boundary_type upper
  connect_bd_net -net xlconstant_2_dout [get_bd_pins xlconcat_0/In0] [get_bd_pins xlconcat_0/In2] -boundary_type upper
  connect_bd_net -net xlconstant_2_dout [get_bd_pins xlconcat_0/In0] [get_bd_pins xlconstant_2/dout] -boundary_type upper
  connect_bd_net -net reset_vmix_Dout [get_bd_pins v_mix_0/ap_rst_n] [get_bd_pins reset_vmix/Dout]
  connect_bd_net -net xlslice_15to8_Dout [get_bd_pins xlconcat_0/In3] [get_bd_pins xlslice_15to8/Dout]
  connect_bd_net -net xlslice_7to0_Dout [get_bd_pins xlconcat_0/In1] [get_bd_pins xlslice_7to0/Dout]

  # Restore current instance
  current_bd_instance \
}

# Create the display pipeline
create_display_pipeline

# Connect to HP3 port
connect_bd_intf_net -boundary_type upper [get_bd_intf_pins display_pipeline/M00_AXI] [get_bd_intf_pins zynq_ultra_ps_e_0/S_AXI_HP3_FPD]

# Connect the AXI Lite interfaces
lappend hpm0_lpd_ports [list "display_pipeline/s_axi_ctrl_clk_wiz" "clk_wiz_0/clk_100M" "rst_ps_axi_100M/peripheral_aresetn"]
lappend hpm0_lpd_ports [list "display_pipeline/s_axi_ctrl_v_tc" "clk_wiz_0/clk_100M" "rst_ps_axi_100M/peripheral_aresetn"]
lappend hpm0_fpd_ports [list "display_pipeline/s_axi_ctrl_vmix" "clk_wiz_0/clk_250M" "rst_video_250M/peripheral_aresetn"]

# Connect EMIO GPIO
connect_bd_net [get_bd_pins zynq_ultra_ps_e_0/emio_gpio_o] [get_bd_pins display_pipeline/Din]

# Clock and reset
connect_bd_net [get_bd_pins clk_wiz_0/clk_250M] [get_bd_pins display_pipeline/clk]
connect_bd_net [get_bd_pins rst_ps_100M/peripheral_aresetn] [get_bd_pins display_pipeline/ext_reset_in]
connect_bd_net [get_bd_pins rst_video_250M/peripheral_aresetn] [get_bd_pins display_pipeline/resetn]
connect_bd_net [get_bd_pins clk_wiz_0/clk_100M] [get_bd_pins display_pipeline/s_axi_aclk]
connect_bd_net [get_bd_pins rst_ps_axi_100M/peripheral_aresetn] [get_bd_pins display_pipeline/s_axi_aresetn]

# Interrupts
lappend priority_intr_list "display_pipeline/irq_v_tc"
lappend priority_intr_list "display_pipeline/irq_vmix"

# Connect DP signals
connect_bd_net [get_bd_pins display_pipeline/vid_active_video] [get_bd_pins zynq_ultra_ps_e_0/dp_live_video_in_de]
connect_bd_net [get_bd_pins display_pipeline/vid_data] [get_bd_pins zynq_ultra_ps_e_0/dp_live_video_in_pixel1]
connect_bd_net [get_bd_pins display_pipeline/vid_hsync] [get_bd_pins zynq_ultra_ps_e_0/dp_live_video_in_hsync]
connect_bd_net [get_bd_pins display_pipeline/vid_vsync] [get_bd_pins zynq_ultra_ps_e_0/dp_live_video_in_vsync]
connect_bd_net [get_bd_pins display_pipeline/video_clk] [get_bd_pins zynq_ultra_ps_e_0/dp_video_in_clk]


#########################################################
# AXI Interfaces and interrupts
#########################################################

# Add AXI Interconnect for the AXI Lite interfaces

proc create_axi_ic {label clk proc_rst master master_clk ports} {
  # Connect the master clock
  connect_bd_net [get_bd_pins $clk] [get_bd_pins $master_clk]
  # Create the AXI interconnect
  set n_periph_ports [llength $ports]
  set axi_ic [create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect $label]
  set_property -dict [list CONFIG.NUM_MI $n_periph_ports] $axi_ic
  connect_bd_net [get_bd_pins $clk] [get_bd_pins $label/ACLK]
  connect_bd_net [get_bd_pins $clk] [get_bd_pins $label/S00_ACLK]
  connect_bd_net [get_bd_pins $proc_rst/interconnect_aresetn] [get_bd_pins $label/ARESETN]
  connect_bd_net [get_bd_pins $proc_rst/peripheral_aresetn] [get_bd_pins $label/S00_ARESETN]
  connect_bd_intf_net [get_bd_intf_pins $master] -boundary_type upper [get_bd_intf_pins $label/S00_AXI]
  # Attach all of the ports, their clocks and resets
  set port_num 0
  foreach port $ports {
    set port_label [lindex $port 0]
    connect_bd_intf_net -boundary_type upper [get_bd_intf_pins $label/M0${port_num}_AXI] [get_bd_intf_pins $port_label]
    set port_clk [lindex $port 1]
    connect_bd_net [get_bd_pins $port_clk] [get_bd_pins $label/M0${port_num}_ACLK]
    set port_rst [lindex $port 2]
    connect_bd_net [get_bd_pins $port_rst] [get_bd_pins $label/M0${port_num}_ARESETN]
    set port_num [expr {$port_num+1}]
  }
}

# HPM0 FPD
create_axi_ic "axi_ic_ctrl_250" "clk_wiz_0/clk_250M" "rst_video_250M" \
  "zynq_ultra_ps_e_0/M_AXI_HPM0_FPD" "zynq_ultra_ps_e_0/maxihpm0_fpd_aclk" $hpm0_fpd_ports

# HPM0 LPD
create_axi_ic "axi_ic_ctrl_100" "clk_wiz_0/clk_100M" "rst_ps_axi_100M" \
  "zynq_ultra_ps_e_0/M_AXI_HPM0_LPD" "zynq_ultra_ps_e_0/maxihpm0_lpd_aclk" $hpm0_lpd_ports

# Connect the interrupts to AXI Intc to pl_ps_irq0 (max 32 interrupts)
set n_interrupts [llength $intr_list]
set_property -dict [list CONFIG.NUM_PORTS $n_interrupts] $concat_0
set intr_index 0
foreach intr $intr_list {
  connect_bd_net [get_bd_pins $intr] [get_bd_pins ${concat_0}/In$intr_index]
  set intr_index [expr {$intr_index+1}]
}

# Connect the "priority" interrupts (direct to PL-PS interrupt) to pl_ps_irq1
set p_intr_concat [create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat p_intr_concat]
connect_bd_net [get_bd_pins p_intr_concat/dout] [get_bd_pins zynq_ultra_ps_e_0/pl_ps_irq1]
set_property -dict [list CONFIG.NUM_PORTS 8] $p_intr_concat
set n_interrupts [llength $priority_intr_list]
set intr_index 0
foreach intr $priority_intr_list {
  connect_bd_net [get_bd_pins $intr] [get_bd_pins ${p_intr_concat}/In$intr_index]
  set intr_index [expr {$intr_index+1}]
}

# Enable ports, clocks and interrupts for accelerators
set n_periph_ports [llength $hpm0_lpd_ports]
set param_list {}
for {set i $n_periph_ports} {$i <= 15} {incr i} {
  set paddedIndex [format "%02d" $i]
  lappend param_list "M${paddedIndex}_AXI"
  lappend param_list {memport "M_AXI_GP"}
}
set_property PFM.AXI_PORT $param_list [get_bd_cells /axi_ic_ctrl_100]

set_property PFM.AXI_PORT { \
  S_AXI_HPC1_FPD {memport "S_AXI_HP" sptag "HPC1" memory "HPC1_DDR_LOW" is_range "false"} \
  } [get_bd_cells /zynq_ultra_ps_e_0]
  
set_property PFM.CLOCK { \
  clk_100M {id "3" is_default "false" proc_sys_reset "/rst_ps_axi_100M" status "fixed" freq_hz "149985000"} \
  clk_300M {id "4" is_default "true" proc_sys_reset "/rst_video_300M" status "fixed" freq_hz "299970000"} \
  } [get_bd_cells /clk_wiz_0]

set_property PFM.IRQ { \
  In6 {id "0" is_range "true"} \
  In7 {id "1" is_range "true"} \
  } $p_intr_concat

set_property pfm_name "xilinx:$board_name:$target:1.0" [get_files -all "$block_name.bd"]

# Assign addresses
assign_bd_address

# Restore current instance
current_bd_instance $oldCurInst

save_bd_design
