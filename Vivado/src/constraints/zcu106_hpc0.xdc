
# DCI_CASCADE is required since banks 67 does not have 240 ohm resistor on VRP pin
# https://support.xilinx.com/s/article/67565?language=en_US
set_property DCI_CASCADE {67} [get_iobanks 68] 

# I2C signals for MIPI 0
set_property PACKAGE_PIN K18 [get_ports iic_0_scl_io]; # LA03_N
set_property PACKAGE_PIN K19 [get_ports iic_0_sda_io]; # LA03_P
set_property IOSTANDARD LVCMOS12 [get_ports iic_0_*]
set_property SLEW SLOW [get_ports iic_0_*]
set_property DRIVE 4 [get_ports iic_0_*]

# I2C signals for MIPI 1
set_property PACKAGE_PIN J17 [get_ports iic_1_scl_io]; # LA05_N
set_property PACKAGE_PIN K17 [get_ports iic_1_sda_io]; # LA05_P
set_property IOSTANDARD LVCMOS12 [get_ports iic_1_*]
set_property SLEW SLOW [get_ports iic_1_*]
set_property DRIVE 4 [get_ports iic_1_*]

# I2C signals for MIPI 2
set_property PACKAGE_PIN D9 [get_ports iic_2_scl_io]; # LA30_N
set_property PACKAGE_PIN E9 [get_ports iic_2_sda_io]; # LA30_P
set_property IOSTANDARD LVCMOS12 [get_ports iic_2_*]
set_property SLEW SLOW [get_ports iic_2_*]
set_property DRIVE 4 [get_ports iic_2_*]

# I2C signals for MIPI 3
set_property PACKAGE_PIN E8 [get_ports iic_3_scl_io]; # LA32_N
set_property PACKAGE_PIN F8 [get_ports iic_3_sda_io]; # LA32_P
set_property IOSTANDARD LVCMOS12 [get_ports iic_3_*]
set_property SLEW SLOW [get_ports iic_3_*]
set_property DRIVE 4 [get_ports iic_3_*]

# CAM1 and CAM3 CLK_SEL signals
set_property PACKAGE_PIN C6 [get_ports {clk_sel[0]}]; # LA25_N
set_property IOSTANDARD LVCMOS12 [get_ports {clk_sel[0]}]

set_property PACKAGE_PIN C7 [get_ports {clk_sel[1]}]; # LA25_P
set_property IOSTANDARD LVCMOS12 [get_ports {clk_sel[1]}]

# GPIOs for MIPI camera 0
set_property PACKAGE_PIN F18 [get_ports {gpio_0_tri_o[0]}]; # LA12_N
set_property PACKAGE_PIN G18 [get_ports {gpio_0_tri_o[1]}]; # LA12_P
set_property IOSTANDARD LVCMOS12 [get_ports {gpio_0_tri_o[*]}]

# GPIOs for MIPI camera 1
set_property PACKAGE_PIN G16 [get_ports {gpio_1_tri_o[0]}]; # LA09_N
set_property PACKAGE_PIN H16 [get_ports {gpio_1_tri_o[1]}]; # LA09_P
set_property IOSTANDARD LVCMOS12 [get_ports {gpio_1_tri_o[*]}]

# GPIOs for MIPI camera 2
set_property PACKAGE_PIN C11 [get_ports {gpio_2_tri_o[0]}]; # LA19_N
set_property PACKAGE_PIN D12 [get_ports {gpio_2_tri_o[1]}]; # LA19_P
set_property IOSTANDARD LVCMOS12 [get_ports {gpio_2_tri_o[*]}]

# GPIOs for MIPI camera 3
set_property PACKAGE_PIN E12 [get_ports {gpio_3_tri_o[0]}]; # LA20_N
set_property PACKAGE_PIN F12 [get_ports {gpio_3_tri_o[1]}]; # LA20_P
set_property IOSTANDARD LVCMOS12 [get_ports {gpio_3_tri_o[*]}]

# Reserved GPIOs
set_property PACKAGE_PIN L17 [get_ports {rsvd_gpio_tri_o[0]}]; # LA04_P
set_property PACKAGE_PIN L16 [get_ports {rsvd_gpio_tri_o[1]}]; # LA04_N
set_property PACKAGE_PIN J16 [get_ports {rsvd_gpio_tri_o[2]}]; # LA07_P
set_property PACKAGE_PIN J15 [get_ports {rsvd_gpio_tri_o[3]}]; # LA07_N
set_property PACKAGE_PIN G15 [get_ports {rsvd_gpio_tri_o[4]}]; # LA13_P
set_property PACKAGE_PIN F15 [get_ports {rsvd_gpio_tri_o[5]}]; # LA13_N
set_property PACKAGE_PIN A8 [get_ports {rsvd_gpio_tri_o[6]}]; # LA27_P
set_property PACKAGE_PIN A7 [get_ports {rsvd_gpio_tri_o[7]}]; # LA27_N
set_property PACKAGE_PIN K10 [get_ports {rsvd_gpio_tri_o[8]}]; # LA29_P
set_property PACKAGE_PIN J10 [get_ports {rsvd_gpio_tri_o[9]}]; # LA29_N
set_property IOSTANDARD LVCMOS12 [get_ports {rsvd_gpio_tri_o[*]}]

# MIPI interface 0
set_property PACKAGE_PIN F17 [get_ports {mipi_phy_if_0_clk_p}]; # LA00_CC_P
set_property PACKAGE_PIN F16 [get_ports {mipi_phy_if_0_clk_n}]; # LA00_CC_N
set_property PACKAGE_PIN H19 [get_ports {mipi_phy_if_0_data_p[0]}]; # LA06_P
set_property PACKAGE_PIN G19 [get_ports {mipi_phy_if_0_data_n[0]}]; # LA06_N
set_property PACKAGE_PIN L20 [get_ports {mipi_phy_if_0_data_p[1]}]; # LA02_P
set_property PACKAGE_PIN K20 [get_ports {mipi_phy_if_0_data_n[1]}]; # LA02_N

set_property IOSTANDARD MIPI_DPHY_DCI [get_ports mipi_phy_if_0_clk_p]
set_property IOSTANDARD MIPI_DPHY_DCI [get_ports mipi_phy_if_0_clk_n]
set_property IOSTANDARD MIPI_DPHY_DCI [get_ports mipi_phy_if_0_data_p[*]]
set_property IOSTANDARD MIPI_DPHY_DCI [get_ports mipi_phy_if_0_data_n[*]]

set_property DIFF_TERM_ADV TERM_100 [get_ports mipi_phy_if_0_clk_p]
set_property DIFF_TERM_ADV TERM_100 [get_ports mipi_phy_if_0_clk_n]
set_property DIFF_TERM_ADV TERM_100 [get_ports mipi_phy_if_0_data_p[*]]
set_property DIFF_TERM_ADV TERM_100 [get_ports mipi_phy_if_0_data_n[*]]

# MIPI interface 1
set_property PACKAGE_PIN H18 [get_ports {mipi_phy_if_1_clk_p}]; # LA01_CC_P
set_property PACKAGE_PIN H17 [get_ports {mipi_phy_if_1_clk_n}]; # LA01_CC_N
set_property PACKAGE_PIN D16 [get_ports {mipi_phy_if_1_data_p[0]}]; # LA15_P
set_property PACKAGE_PIN C16 [get_ports {mipi_phy_if_1_data_n[0]}]; # LA15_N
set_property PACKAGE_PIN C13 [get_ports {mipi_phy_if_1_data_p[1]}]; # LA14_P
set_property PACKAGE_PIN C12 [get_ports {mipi_phy_if_1_data_n[1]}]; # LA14_N

set_property IOSTANDARD MIPI_DPHY_DCI [get_ports mipi_phy_if_1_clk_p]
set_property IOSTANDARD MIPI_DPHY_DCI [get_ports mipi_phy_if_1_clk_n]
set_property IOSTANDARD MIPI_DPHY_DCI [get_ports mipi_phy_if_1_data_p[*]]
set_property IOSTANDARD MIPI_DPHY_DCI [get_ports mipi_phy_if_1_data_n[*]]

set_property DIFF_TERM_ADV TERM_100 [get_ports mipi_phy_if_1_clk_p]
set_property DIFF_TERM_ADV TERM_100 [get_ports mipi_phy_if_1_clk_n]
set_property DIFF_TERM_ADV TERM_100 [get_ports mipi_phy_if_1_data_p[*]]
set_property DIFF_TERM_ADV TERM_100 [get_ports mipi_phy_if_1_data_n[*]]

# MIPI interface 2
set_property PACKAGE_PIN D11 [get_ports {mipi_phy_if_2_clk_p}]; # LA18_CC_P
set_property PACKAGE_PIN D10 [get_ports {mipi_phy_if_2_clk_n}]; # LA18_CC_N
set_property PACKAGE_PIN B6 [get_ports {mipi_phy_if_2_data_p[0]}]; # LA24_P
set_property PACKAGE_PIN A6 [get_ports {mipi_phy_if_2_data_n[0]}]; # LA24_N
set_property PACKAGE_PIN F11 [get_ports {mipi_phy_if_2_data_p[1]}]; # LA17_CC_P
set_property PACKAGE_PIN E10 [get_ports {mipi_phy_if_2_data_n[1]}]; # LA17_CC_N

set_property IOSTANDARD MIPI_DPHY_DCI [get_ports mipi_phy_if_2_clk_p]
set_property IOSTANDARD MIPI_DPHY_DCI [get_ports mipi_phy_if_2_clk_n]
set_property IOSTANDARD MIPI_DPHY_DCI [get_ports mipi_phy_if_2_data_p[*]]
set_property IOSTANDARD MIPI_DPHY_DCI [get_ports mipi_phy_if_2_data_n[*]]

set_property DIFF_TERM_ADV TERM_100 [get_ports mipi_phy_if_2_clk_p]
set_property DIFF_TERM_ADV TERM_100 [get_ports mipi_phy_if_2_clk_n]
set_property DIFF_TERM_ADV TERM_100 [get_ports mipi_phy_if_2_data_p[*]]
set_property DIFF_TERM_ADV TERM_100 [get_ports mipi_phy_if_2_data_n[*]]

# MIPI interface 3
set_property PACKAGE_PIN F7 [get_ports {mipi_phy_if_3_clk_p}]; # LA31_P
set_property PACKAGE_PIN E7 [get_ports {mipi_phy_if_3_clk_n}]; # LA31_N
set_property PACKAGE_PIN C9 [get_ports {mipi_phy_if_3_data_p[0]}]; # LA33_P
set_property PACKAGE_PIN C8 [get_ports {mipi_phy_if_3_data_n[0]}]; # LA33_N
set_property PACKAGE_PIN M13 [get_ports {mipi_phy_if_3_data_p[1]}]; # LA28_P
set_property PACKAGE_PIN L13 [get_ports {mipi_phy_if_3_data_n[1]}]; # LA28_N

set_property IOSTANDARD MIPI_DPHY_DCI [get_ports mipi_phy_if_3_clk_p]
set_property IOSTANDARD MIPI_DPHY_DCI [get_ports mipi_phy_if_3_clk_n]
set_property IOSTANDARD MIPI_DPHY_DCI [get_ports mipi_phy_if_3_data_p[*]]
set_property IOSTANDARD MIPI_DPHY_DCI [get_ports mipi_phy_if_3_data_n[*]]

set_property DIFF_TERM_ADV TERM_100 [get_ports mipi_phy_if_3_clk_p]
set_property DIFF_TERM_ADV TERM_100 [get_ports mipi_phy_if_3_clk_n]
set_property DIFF_TERM_ADV TERM_100 [get_ports mipi_phy_if_3_data_p[*]]
set_property DIFF_TERM_ADV TERM_100 [get_ports mipi_phy_if_3_data_n[*]]

# These constraints apply to the ZCU106 HPC1 with FPGA Drive FMC (single or dual version)
# ---------------------------------------------------------------------------------------
# NOTE: The ZCU106 HPC1 cannot support two SSDs, because it only has one MGT routed to
#       the FMC (HPC1) connector. Consequently, it can only support 1-lane PCIe.

# SSD1 PCI Express reset LA00_P_CC (perst_0) - IOSTANDARD determined by VADJ
set_property PACKAGE_PIN B18 [get_ports {perst_0[0]}]
set_property IOSTANDARD LVCMOS18 [get_ports {perst_0[0]}]

# SSD2 PCI Express reset LA04_P (perst_1) - IOSTANDARD determined by VADJ
# set_property PACKAGE_PIN J24 [get_ports {perst_1[0]}]
# set_property IOSTANDARD LVCMOS18 [get_ports {perst_1[0]}]

# PEDET_0 - LA00_N_CC - B19 - IOSTANDARD determined by VADJ
# PEDET_1 - LA04_N - H24 - IOSTANDARD determined by VADJ

# Disable signal for 3.3V power supply for SSD2 - LA07_P (disable_ssd2_pwr)
set_property PACKAGE_PIN D22 [get_ports disable_ssd2_pwr]
set_property IOSTANDARD LVCMOS18 [get_ports disable_ssd2_pwr]

# PCI Express reference clock 100MHz
# IOSTANDARD for GT reference clock does not need to be specified
# SSD1 ref clock connects to MGT bank 225, CLK0 input
set_property PACKAGE_PIN Y8 [get_ports {ref_clk_0_clk_p[0]}]
set_property PACKAGE_PIN Y7 [get_ports {ref_clk_0_clk_n[0]}]
create_clock -period 10.000 -name ref_clk_0_clk_p -waveform {0.000 5.000} [get_ports ref_clk_0_clk_p]
# SSD2 ref clock is left unconnected on the ZCU106 HPC1 connector

# MGT locations
# SSD1 HPC1_DP0 (PCIe lane 0) is connected to MGT bank 223 (X0Y0-X0Y3), specifically X0Y3
set_property LOC GTHE4_CHANNEL_X0Y3 [get_cells {*_i/xdma_0/inst/pcie4_ip_i/inst/*_gt_top_i/diablo_gt.diablo_gt_phy_wrapper/gt_wizard.gtwizard_top_i/*_xdma_0_0_pcie4_ip_gt_i/inst/gen_gtwizard_gthe4_top.*_xdma_0_0_pcie4_ip_gt_gtwizard_gthe4_inst/gen_gtwizard_gthe4.gen_channel_container[0].gen_enabled_channel.gthe4_channel_wrapper_inst/channel_inst/gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST}]

# ZCU106 HPC1 transceivers for SSD1 are best aligned with PCIE_X0Y0
set_property LOC PCIE40E4_X0Y0 [get_cells *_i/xdma_0/inst/pcie4_ip_i/inst/*_pcie_4_0_pipe_inst/pcie_4_0_e4_inst]

