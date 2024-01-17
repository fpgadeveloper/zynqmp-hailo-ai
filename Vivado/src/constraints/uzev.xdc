# I2C signals for MIPI 0
set_property PACKAGE_PIN AF18 [get_ports iic_0_scl_io]; # LA03_N
set_property PACKAGE_PIN AE18 [get_ports iic_0_sda_io]; # LA03_P
set_property IOSTANDARD LVCMOS12 [get_ports iic_0_*]
set_property SLEW SLOW [get_ports iic_0_*]
set_property DRIVE 4 [get_ports iic_0_*]

# I2C signals for MIPI 1
set_property PACKAGE_PIN AE19 [get_ports iic_1_scl_io]; # LA05_N
set_property PACKAGE_PIN AD19 [get_ports iic_1_sda_io]; # LA05_P
set_property IOSTANDARD LVCMOS12 [get_ports iic_1_*]
set_property SLEW SLOW [get_ports iic_1_*]
set_property DRIVE 4 [get_ports iic_1_*]

# I2C signals for MIPI 2
set_property PACKAGE_PIN AJ1 [get_ports iic_2_scl_io]; # LA30_N
set_property PACKAGE_PIN AJ2 [get_ports iic_2_sda_io]; # LA30_P
set_property IOSTANDARD LVCMOS12 [get_ports iic_2_*]
set_property SLEW SLOW [get_ports iic_2_*]
set_property DRIVE 4 [get_ports iic_2_*]

# I2C signals for MIPI 3
set_property PACKAGE_PIN AJ9 [get_ports iic_3_scl_io]; # LA32_N
set_property PACKAGE_PIN AH9 [get_ports iic_3_sda_io]; # LA32_P
set_property IOSTANDARD LVCMOS12 [get_ports iic_3_*]
set_property SLEW SLOW [get_ports iic_3_*]
set_property DRIVE 4 [get_ports iic_3_*]

# CAM1 and CAM3 CLK_SEL signals
set_property PACKAGE_PIN AF5 [get_ports {clk_sel[0]}]; # LA25_N
set_property IOSTANDARD LVCMOS12 [get_ports {clk_sel[0]}]

set_property PACKAGE_PIN AF6 [get_ports {clk_sel[1]}]; # LA25_P
set_property IOSTANDARD LVCMOS12 [get_ports {clk_sel[1]}]

# GPIOs for MIPI camera 0
set_property PACKAGE_PIN AK14 [get_ports {gpio_0_tri_o[0]}]; # LA12_N
set_property PACKAGE_PIN AJ14 [get_ports {gpio_0_tri_o[1]}]; # LA12_P
set_property IOSTANDARD LVCMOS12 [get_ports {gpio_0_tri_o[*]}]

# GPIOs for MIPI camera 1
set_property PACKAGE_PIN AK18 [get_ports {gpio_1_tri_o[0]}]; # LA09_N
set_property PACKAGE_PIN AK17 [get_ports {gpio_1_tri_o[1]}]; # LA09_P
set_property IOSTANDARD LVCMOS12 [get_ports {gpio_1_tri_o[*]}]

# GPIOs for MIPI camera 2
set_property PACKAGE_PIN AG10 [get_ports {gpio_2_tri_o[0]}]; # LA19_N
set_property PACKAGE_PIN AF10 [get_ports {gpio_2_tri_o[1]}]; # LA19_P
set_property IOSTANDARD LVCMOS12 [get_ports {gpio_2_tri_o[*]}]

# GPIOs for MIPI camera 3
set_property PACKAGE_PIN AK10 [get_ports {gpio_3_tri_o[0]}]; # LA20_N
set_property PACKAGE_PIN AJ10 [get_ports {gpio_3_tri_o[1]}]; # LA20_P
set_property IOSTANDARD LVCMOS12 [get_ports {gpio_3_tri_o[*]}]

# Reserved GPIOs
set_property PACKAGE_PIN AH17 [get_ports {rsvd_gpio_tri_o[0]}]; # LA04_P
set_property PACKAGE_PIN AJ17 [get_ports {rsvd_gpio_tri_o[1]}]; # LA04_N
set_property PACKAGE_PIN AA16 [get_ports {rsvd_gpio_tri_o[2]}]; # LA07_P
set_property PACKAGE_PIN AB16 [get_ports {rsvd_gpio_tri_o[3]}]; # LA07_N
set_property PACKAGE_PIN AJ15 [get_ports {rsvd_gpio_tri_o[4]}]; # LA13_P
set_property PACKAGE_PIN AK15 [get_ports {rsvd_gpio_tri_o[5]}]; # LA13_N
set_property PACKAGE_PIN AG8 [get_ports {rsvd_gpio_tri_o[6]}]; # LA27_P
set_property PACKAGE_PIN AH8 [get_ports {rsvd_gpio_tri_o[7]}]; # LA27_N
set_property PACKAGE_PIN AJ4 [get_ports {rsvd_gpio_tri_o[8]}]; # LA29_P
set_property PACKAGE_PIN AK4 [get_ports {rsvd_gpio_tri_o[9]}]; # LA29_N
set_property IOSTANDARD LVCMOS12 [get_ports {rsvd_gpio_tri_o[*]}]

# MIPI interface 0
set_property PACKAGE_PIN AF16 [get_ports {mipi_phy_if_0_clk_p}]; # LA00_CC_P
set_property PACKAGE_PIN AF17 [get_ports {mipi_phy_if_0_clk_n}]; # LA00_CC_N
set_property PACKAGE_PIN AC17 [get_ports {mipi_phy_if_0_data_p[0]}]; # LA06_P
set_property PACKAGE_PIN AC18 [get_ports {mipi_phy_if_0_data_n[0]}]; # LA06_N
set_property PACKAGE_PIN AG18 [get_ports {mipi_phy_if_0_data_p[1]}]; # LA02_P
set_property PACKAGE_PIN AH18 [get_ports {mipi_phy_if_0_data_n[1]}]; # LA02_N

set_property IOSTANDARD MIPI_DPHY_DCI [get_ports mipi_phy_if_0_clk_p]
set_property IOSTANDARD MIPI_DPHY_DCI [get_ports mipi_phy_if_0_clk_n]
set_property IOSTANDARD MIPI_DPHY_DCI [get_ports mipi_phy_if_0_data_p[*]]
set_property IOSTANDARD MIPI_DPHY_DCI [get_ports mipi_phy_if_0_data_n[*]]

set_property DIFF_TERM_ADV TERM_100 [get_ports mipi_phy_if_0_clk_p]
set_property DIFF_TERM_ADV TERM_100 [get_ports mipi_phy_if_0_clk_n]
set_property DIFF_TERM_ADV TERM_100 [get_ports mipi_phy_if_0_data_p[*]]
set_property DIFF_TERM_ADV TERM_100 [get_ports mipi_phy_if_0_data_n[*]]

# MIPI interface 1
set_property PACKAGE_PIN AG13 [get_ports {mipi_phy_if_1_clk_p}]; # LA16_P
set_property PACKAGE_PIN AH13 [get_ports {mipi_phy_if_1_clk_n}]; # LA16_N
set_property PACKAGE_PIN AK13 [get_ports {mipi_phy_if_1_data_p[0]}]; # LA15_P
set_property PACKAGE_PIN AK12 [get_ports {mipi_phy_if_1_data_n[0]}]; # LA15_N
set_property PACKAGE_PIN AF15 [get_ports {mipi_phy_if_1_data_p[1]}]; # LA14_P
set_property PACKAGE_PIN AG15 [get_ports {mipi_phy_if_1_data_n[1]}]; # LA14_N

set_property IOSTANDARD MIPI_DPHY_DCI [get_ports mipi_phy_if_1_clk_p]
set_property IOSTANDARD MIPI_DPHY_DCI [get_ports mipi_phy_if_1_clk_n]
set_property IOSTANDARD MIPI_DPHY_DCI [get_ports mipi_phy_if_1_data_p[*]]
set_property IOSTANDARD MIPI_DPHY_DCI [get_ports mipi_phy_if_1_data_n[*]]

set_property DIFF_TERM_ADV TERM_100 [get_ports mipi_phy_if_1_clk_p]
set_property DIFF_TERM_ADV TERM_100 [get_ports mipi_phy_if_1_clk_n]
set_property DIFF_TERM_ADV TERM_100 [get_ports mipi_phy_if_1_data_p[*]]
set_property DIFF_TERM_ADV TERM_100 [get_ports mipi_phy_if_1_data_n[*]]

# MIPI interface 2
set_property PACKAGE_PIN AH6 [get_ports {mipi_phy_if_2_clk_p}]; # LA18_CC_P
set_property PACKAGE_PIN AJ6 [get_ports {mipi_phy_if_2_clk_n}]; # LA18_CC_N
set_property PACKAGE_PIN AK7 [get_ports {mipi_phy_if_2_data_p[0]}]; # LA24_P
set_property PACKAGE_PIN AK6 [get_ports {mipi_phy_if_2_data_n[0]}]; # LA24_N
set_property PACKAGE_PIN AG6 [get_ports {mipi_phy_if_2_data_p[1]}]; # LA17_CC_P
set_property PACKAGE_PIN AG5 [get_ports {mipi_phy_if_2_data_n[1]}]; # LA17_CC_N

set_property IOSTANDARD MIPI_DPHY_DCI [get_ports mipi_phy_if_2_clk_p]
set_property IOSTANDARD MIPI_DPHY_DCI [get_ports mipi_phy_if_2_clk_n]
set_property IOSTANDARD MIPI_DPHY_DCI [get_ports mipi_phy_if_2_data_p[*]]
set_property IOSTANDARD MIPI_DPHY_DCI [get_ports mipi_phy_if_2_data_n[*]]

set_property DIFF_TERM_ADV TERM_100 [get_ports mipi_phy_if_2_clk_p]
set_property DIFF_TERM_ADV TERM_100 [get_ports mipi_phy_if_2_clk_n]
set_property DIFF_TERM_ADV TERM_100 [get_ports mipi_phy_if_2_data_p[*]]
set_property DIFF_TERM_ADV TERM_100 [get_ports mipi_phy_if_2_data_n[*]]

# MIPI interface 3
set_property PACKAGE_PIN AK9 [get_ports {mipi_phy_if_3_clk_p}]; # LA26_P
set_property PACKAGE_PIN AK8 [get_ports {mipi_phy_if_3_clk_n}]; # LA26_N
set_property PACKAGE_PIN AG11 [get_ports {mipi_phy_if_3_data_p[0]}]; # LA33_P
set_property PACKAGE_PIN AH11 [get_ports {mipi_phy_if_3_data_n[0]}]; # LA33_N
set_property PACKAGE_PIN AJ11 [get_ports {mipi_phy_if_3_data_p[1]}]; # LA28_P
set_property PACKAGE_PIN AK11 [get_ports {mipi_phy_if_3_data_n[1]}]; # LA28_N

set_property IOSTANDARD MIPI_DPHY_DCI [get_ports mipi_phy_if_3_clk_p]
set_property IOSTANDARD MIPI_DPHY_DCI [get_ports mipi_phy_if_3_clk_n]
set_property IOSTANDARD MIPI_DPHY_DCI [get_ports mipi_phy_if_3_data_p[*]]
set_property IOSTANDARD MIPI_DPHY_DCI [get_ports mipi_phy_if_3_data_n[*]]

set_property DIFF_TERM_ADV TERM_100 [get_ports mipi_phy_if_3_clk_p]
set_property DIFF_TERM_ADV TERM_100 [get_ports mipi_phy_if_3_clk_n]
set_property DIFF_TERM_ADV TERM_100 [get_ports mipi_phy_if_3_data_p[*]]
set_property DIFF_TERM_ADV TERM_100 [get_ports mipi_phy_if_3_data_n[*]]

# These constraints apply to the UltraZed-EV Carrier with FPGA Drive FMC using 1x SSDs
# ------------------------------------------------------------------------------------

# SSD1 PCI Express reset LA00_P_CC (AF16) (perst_0) (HP_DP_12_GC_P) - IOSTANDARD determined by VADJ
# Changed this to LA04_P temporarily to permit build
set_property PACKAGE_PIN AH17 [get_ports {perst_0[0]}]
set_property IOSTANDARD LVCMOS18 [get_ports {perst_0[0]}]

# SSD2 PCI Express reset LA04_P (perst_1) (HP_DP_02_P) - IOSTANDARD determined by VADJ
#set_property PACKAGE_PIN AH17 [get_ports {perst_1[0]}]
#set_property IOSTANDARD LVCMOS18 [get_ports {perst_1[0]}]

# PEDET_0 - LA00_N_CC - F16 - IOSTANDARD determined by VADJ
# PEDET_1 - LA04_N - L16 - IOSTANDARD determined by VADJ

# Disable signal for 3.3V power supply for SSD2 - LA07_P (disable_ssd2_pwr) (HP_DP_05_P)
set_property PACKAGE_PIN AA16 [get_ports disable_ssd2_pwr]
set_property IOSTANDARD LVCMOS18 [get_ports disable_ssd2_pwr]

# PCI Express reference clock 100MHz
# IOSTANDARD for GT reference clock does not need to be specified
# SSD1 ref clock connects to MGT bank 225, CLK0 input
set_property PACKAGE_PIN L8 [get_ports {ref_clk_0_clk_p[0]}]
set_property PACKAGE_PIN L7 [get_ports {ref_clk_0_clk_n[0]}]
create_clock -period 10.000 -name ref_clk_0_clk_p -waveform {0.000 5.000} [get_ports ref_clk_0_clk_p]
# SSD2 ref clock connects to MGT bank 224, CLK0 input
#set_property PACKAGE_PIN R8 [get_ports {ref_clk_1_clk_p[0]}]
#set_property PACKAGE_PIN R7 [get_ports {ref_clk_1_clk_n[0]}]
#create_clock -period 10.000 -name ref_clk_1_clk_p -waveform {0.000 5.000} [get_ports ref_clk_1_clk_p]

# MGT locations
# The GT LOCs are specified in a post hook Tcl file for this design
# SSD1 HPC0_DP0-3 (PCIe lanes 0-3) are connected to MGT bank 225 (X0Y8-X0Y11) in this order: 0->0, 1->1, 2->2, 3->3
#set_property LOC GTHE4_CHANNEL_X0Y8  [get_cells {*_i/xdma_0/inst/pcie4_ip_i/inst/*_gt_top_i/diablo_gt.diablo_gt_phy_wrapper/gt_wizard.gtwizard_top_i/*_xdma_0_0_pcie4_ip_gt_i/inst/gen_gtwizard_gthe4_top.*_xdma_0_0_pcie4_ip_gt_gtwizard_gthe4_inst/gen_gtwizard_gthe4.gen_channel_container[2].gen_enabled_channel.gthe4_channel_wrapper_inst/channel_inst/gthe4_channel_gen.gen_gthe4_channel_inst[3].GTHE4_CHANNEL_PRIM_INST}]
#set_property LOC GTHE4_CHANNEL_X0Y9  [get_cells {*_i/xdma_0/inst/pcie4_ip_i/inst/*_gt_top_i/diablo_gt.diablo_gt_phy_wrapper/gt_wizard.gtwizard_top_i/*_xdma_0_0_pcie4_ip_gt_i/inst/gen_gtwizard_gthe4_top.*_xdma_0_0_pcie4_ip_gt_gtwizard_gthe4_inst/gen_gtwizard_gthe4.gen_channel_container[2].gen_enabled_channel.gthe4_channel_wrapper_inst/channel_inst/gthe4_channel_gen.gen_gthe4_channel_inst[2].GTHE4_CHANNEL_PRIM_INST}]
#set_property LOC GTHE4_CHANNEL_X0Y10 [get_cells {*_i/xdma_0/inst/pcie4_ip_i/inst/*_gt_top_i/diablo_gt.diablo_gt_phy_wrapper/gt_wizard.gtwizard_top_i/*_xdma_0_0_pcie4_ip_gt_i/inst/gen_gtwizard_gthe4_top.*_xdma_0_0_pcie4_ip_gt_gtwizard_gthe4_inst/gen_gtwizard_gthe4.gen_channel_container[2].gen_enabled_channel.gthe4_channel_wrapper_inst/channel_inst/gthe4_channel_gen.gen_gthe4_channel_inst[1].GTHE4_CHANNEL_PRIM_INST}]
#set_property LOC GTHE4_CHANNEL_X0Y11 [get_cells {*_i/xdma_0/inst/pcie4_ip_i/inst/*_gt_top_i/diablo_gt.diablo_gt_phy_wrapper/gt_wizard.gtwizard_top_i/*_xdma_0_0_pcie4_ip_gt_i/inst/gen_gtwizard_gthe4_top.*_xdma_0_0_pcie4_ip_gt_gtwizard_gthe4_inst/gen_gtwizard_gthe4.gen_channel_container[2].gen_enabled_channel.gthe4_channel_wrapper_inst/channel_inst/gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST}]

# SSD2 HPC0_DP4-7 (PCIe lanes 0-3) are connected to MGT bank 224 (X0Y4-X0Y7) in this order: 0->0, 1->1, 2->2, 3->3
#set_property LOC GTHE4_CHANNEL_X0Y4 [get_cells {*_i/xdma_1/inst/pcie4_ip_i/inst/*_gt_top_i/diablo_gt.diablo_gt_phy_wrapper/gt_wizard.gtwizard_top_i/*_xdma_1_0_pcie4_ip_gt_i/inst/gen_gtwizard_gthe4_top.*_xdma_1_0_pcie4_ip_gt_gtwizard_gthe4_inst/gen_gtwizard_gthe4.gen_channel_container[1].gen_enabled_channel.gthe4_channel_wrapper_inst/channel_inst/gthe4_channel_gen.gen_gthe4_channel_inst[3].GTHE4_CHANNEL_PRIM_INST}]
#set_property LOC GTHE4_CHANNEL_X0Y5 [get_cells {*_i/xdma_1/inst/pcie4_ip_i/inst/*_gt_top_i/diablo_gt.diablo_gt_phy_wrapper/gt_wizard.gtwizard_top_i/*_xdma_1_0_pcie4_ip_gt_i/inst/gen_gtwizard_gthe4_top.*_xdma_1_0_pcie4_ip_gt_gtwizard_gthe4_inst/gen_gtwizard_gthe4.gen_channel_container[1].gen_enabled_channel.gthe4_channel_wrapper_inst/channel_inst/gthe4_channel_gen.gen_gthe4_channel_inst[2].GTHE4_CHANNEL_PRIM_INST}]
#set_property LOC GTHE4_CHANNEL_X0Y6 [get_cells {*_i/xdma_1/inst/pcie4_ip_i/inst/*_gt_top_i/diablo_gt.diablo_gt_phy_wrapper/gt_wizard.gtwizard_top_i/*_xdma_1_0_pcie4_ip_gt_i/inst/gen_gtwizard_gthe4_top.*_xdma_1_0_pcie4_ip_gt_gtwizard_gthe4_inst/gen_gtwizard_gthe4.gen_channel_container[1].gen_enabled_channel.gthe4_channel_wrapper_inst/channel_inst/gthe4_channel_gen.gen_gthe4_channel_inst[1].GTHE4_CHANNEL_PRIM_INST}]
#set_property LOC GTHE4_CHANNEL_X0Y7 [get_cells {*_i/xdma_1/inst/pcie4_ip_i/inst/*_gt_top_i/diablo_gt.diablo_gt_phy_wrapper/gt_wizard.gtwizard_top_i/*_xdma_1_0_pcie4_ip_gt_i/inst/gen_gtwizard_gthe4_top.*_xdma_1_0_pcie4_ip_gt_gtwizard_gthe4_inst/gen_gtwizard_gthe4.gen_channel_container[1].gen_enabled_channel.gthe4_channel_wrapper_inst/channel_inst/gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST}]

# UltraZed-EV FMC transceivers for SSD1 are best aligned with PCIE_X0Y1
set_property LOC PCIE40E4_X0Y1 [get_cells *_i/xdma_0/inst/pcie4_ip_i/inst/*_pcie_4_0_pipe_inst/pcie_4_0_e4_inst]

# UltraZed-EV FMC transceivers for SSD2 are best aligned with PCIE_X0Y0
#set_property LOC PCIE40E4_X0Y0 [get_cells *_i/xdma_1/inst/pcie4_ip_i/inst/*_pcie_4_0_pipe_inst/pcie_4_0_e4_inst]

