## I2C signals for MIPI 0
#set_property PACKAGE_PIN J9 [get_ports iic_0_scl_io]; # LA03_N
#set_property PACKAGE_PIN K9 [get_ports iic_0_sda_io]; # LA03_P
#set_property IOSTANDARD LVCMOS12 [get_ports iic_0_*]
#set_property SLEW SLOW [get_ports iic_0_*]
#set_property DRIVE 4 [get_ports iic_0_*]

# I2C signals for MIPI 1
set_property PACKAGE_PIN H1 [get_ports iic_1_scl_io]; # LA05_N
set_property PACKAGE_PIN J1 [get_ports iic_1_sda_io]; # LA05_P
set_property IOSTANDARD LVCMOS12 [get_ports iic_1_*]
set_property SLEW SLOW [get_ports iic_1_*]
set_property DRIVE 4 [get_ports iic_1_*]

# I2C signals for MIPI 2
set_property PACKAGE_PIN AE8 [get_ports iic_2_scl_io]; # LA30_N
set_property PACKAGE_PIN AE9 [get_ports iic_2_sda_io]; # LA30_P
set_property IOSTANDARD LVCMOS12 [get_ports iic_2_*]
set_property SLEW SLOW [get_ports iic_2_*]
set_property DRIVE 4 [get_ports iic_2_*]

## I2C signals for MIPI 3
#set_property PACKAGE_PIN AG8 [get_ports iic_3_scl_io]; # LA32_N
#set_property PACKAGE_PIN AF8 [get_ports iic_3_sda_io]; # LA32_P
#set_property IOSTANDARD LVCMOS12 [get_ports iic_3_*]
#set_property SLEW SLOW [get_ports iic_3_*]
#set_property DRIVE 4 [get_ports iic_3_*]

# CAM1 and CAM3 CLK_SEL signals
set_property PACKAGE_PIN AH1 [get_ports {clk_sel[0]}]; # LA25_N
set_property IOSTANDARD LVCMOS12 [get_ports {clk_sel[0]}]

set_property PACKAGE_PIN AH2 [get_ports {clk_sel[1]}]; # LA25_P
set_property IOSTANDARD LVCMOS12 [get_ports {clk_sel[1]}]

## GPIOs for MIPI camera 0
#set_property PACKAGE_PIN L5 [get_ports {gpio_0_tri_o[0]}]; # LA12_N
#set_property PACKAGE_PIN M6 [get_ports {gpio_0_tri_o[1]}]; # LA12_P
#set_property IOSTANDARD LVCMOS12 [get_ports {gpio_0_tri_o[*]}]

# GPIOs for MIPI camera 1
set_property PACKAGE_PIN K1 [get_ports {gpio_1_tri_o[0]}]; # LA09_N
set_property PACKAGE_PIN L1 [get_ports {gpio_1_tri_o[1]}]; # LA09_P
set_property IOSTANDARD LVCMOS12 [get_ports {gpio_1_tri_o[*]}]

# GPIOs for MIPI camera 2
set_property PACKAGE_PIN AC2 [get_ports {gpio_2_tri_o[0]}]; # LA19_N
set_property PACKAGE_PIN AB2 [get_ports {gpio_2_tri_o[1]}]; # LA19_P
set_property IOSTANDARD LVCMOS12 [get_ports {gpio_2_tri_o[*]}]

## GPIOs for MIPI camera 3
#set_property PACKAGE_PIN AB3 [get_ports {gpio_3_tri_o[0]}]; # LA20_N
#set_property PACKAGE_PIN AB4 [get_ports {gpio_3_tri_o[1]}]; # LA20_P
#set_property IOSTANDARD LVCMOS12 [get_ports {gpio_3_tri_o[*]}]

# Reserved GPIOs
set_property PACKAGE_PIN H9 [get_ports {rsvd_gpio_tri_o[0]}]; # LA04_P
set_property PACKAGE_PIN H8 [get_ports {rsvd_gpio_tri_o[1]}]; # LA04_N
set_property PACKAGE_PIN J6 [get_ports {rsvd_gpio_tri_o[2]}]; # LA07_P
set_property PACKAGE_PIN H6 [get_ports {rsvd_gpio_tri_o[3]}]; # LA07_N
set_property PACKAGE_PIN R6 [get_ports {rsvd_gpio_tri_o[4]}]; # LA13_P
set_property PACKAGE_PIN T6 [get_ports {rsvd_gpio_tri_o[5]}]; # LA13_N
set_property PACKAGE_PIN AE3 [get_ports {rsvd_gpio_tri_o[6]}]; # LA27_P
set_property PACKAGE_PIN AF3 [get_ports {rsvd_gpio_tri_o[7]}]; # LA27_N
set_property PACKAGE_PIN AG4 [get_ports {rsvd_gpio_tri_o[8]}]; # LA29_P
set_property PACKAGE_PIN AH4 [get_ports {rsvd_gpio_tri_o[9]}]; # LA29_N
set_property IOSTANDARD LVCMOS12 [get_ports {rsvd_gpio_tri_o[*]}]

## MIPI interface 0
#set_property PACKAGE_PIN L7 [get_ports {mipi_phy_if_0_clk_p}]; # LA00_CC_P
#set_property PACKAGE_PIN L6 [get_ports {mipi_phy_if_0_clk_n}]; # LA00_CC_N
#set_property PACKAGE_PIN J7 [get_ports {mipi_phy_if_0_data_p[0]}]; # LA06_P
#set_property PACKAGE_PIN H7 [get_ports {mipi_phy_if_0_data_n[0]}]; # LA06_N
#set_property PACKAGE_PIN K8 [get_ports {mipi_phy_if_0_data_p[1]}]; # LA02_P
#set_property PACKAGE_PIN K7 [get_ports {mipi_phy_if_0_data_n[1]}]; # LA02_N

#set_property IOSTANDARD MIPI_DPHY_DCI [get_ports mipi_phy_if_0_clk_p]
#set_property IOSTANDARD MIPI_DPHY_DCI [get_ports mipi_phy_if_0_clk_n]
#set_property IOSTANDARD MIPI_DPHY_DCI [get_ports mipi_phy_if_0_data_p[*]]
#set_property IOSTANDARD MIPI_DPHY_DCI [get_ports mipi_phy_if_0_data_n[*]]

#set_property DIFF_TERM_ADV TERM_100 [get_ports mipi_phy_if_0_clk_p]
#set_property DIFF_TERM_ADV TERM_100 [get_ports mipi_phy_if_0_clk_n]
#set_property DIFF_TERM_ADV TERM_100 [get_ports mipi_phy_if_0_data_p[*]]
#set_property DIFF_TERM_ADV TERM_100 [get_ports mipi_phy_if_0_data_n[*]]

# MIPI interface 1
set_property PACKAGE_PIN P7 [get_ports {mipi_phy_if_1_clk_p}]; # LA01_CC_P
set_property PACKAGE_PIN P6 [get_ports {mipi_phy_if_1_clk_n}]; # LA01_CC_N
set_property PACKAGE_PIN N9 [get_ports {mipi_phy_if_1_data_p[0]}]; # LA15_P
set_property PACKAGE_PIN N8 [get_ports {mipi_phy_if_1_data_n[0]}]; # LA15_N
set_property PACKAGE_PIN R7 [get_ports {mipi_phy_if_1_data_p[1]}]; # LA14_P
set_property PACKAGE_PIN T7 [get_ports {mipi_phy_if_1_data_n[1]}]; # LA14_N

set_property IOSTANDARD MIPI_DPHY_DCI [get_ports mipi_phy_if_1_clk_p]
set_property IOSTANDARD MIPI_DPHY_DCI [get_ports mipi_phy_if_1_clk_n]
set_property IOSTANDARD MIPI_DPHY_DCI [get_ports mipi_phy_if_1_data_p[*]]
set_property IOSTANDARD MIPI_DPHY_DCI [get_ports mipi_phy_if_1_data_n[*]]

set_property DIFF_TERM_ADV TERM_100 [get_ports mipi_phy_if_1_clk_p]
set_property DIFF_TERM_ADV TERM_100 [get_ports mipi_phy_if_1_clk_n]
set_property DIFF_TERM_ADV TERM_100 [get_ports mipi_phy_if_1_data_p[*]]
set_property DIFF_TERM_ADV TERM_100 [get_ports mipi_phy_if_1_data_n[*]]

# MIPI interface 2
set_property PACKAGE_PIN AD2 [get_ports {mipi_phy_if_2_clk_p}]; # LA18_CC_P
set_property PACKAGE_PIN AD1 [get_ports {mipi_phy_if_2_clk_n}]; # LA18_CC_N
set_property PACKAGE_PIN AG3 [get_ports {mipi_phy_if_2_data_p[0]}]; # LA24_P
set_property PACKAGE_PIN AH3 [get_ports {mipi_phy_if_2_data_n[0]}]; # LA24_N
set_property PACKAGE_PIN AC4 [get_ports {mipi_phy_if_2_data_p[1]}]; # LA17_CC_P
set_property PACKAGE_PIN AC3 [get_ports {mipi_phy_if_2_data_n[1]}]; # LA17_CC_N

set_property IOSTANDARD MIPI_DPHY_DCI [get_ports mipi_phy_if_2_clk_p]
set_property IOSTANDARD MIPI_DPHY_DCI [get_ports mipi_phy_if_2_clk_n]
set_property IOSTANDARD MIPI_DPHY_DCI [get_ports mipi_phy_if_2_data_p[*]]
set_property IOSTANDARD MIPI_DPHY_DCI [get_ports mipi_phy_if_2_data_n[*]]

set_property DIFF_TERM_ADV TERM_100 [get_ports mipi_phy_if_2_clk_p]
set_property DIFF_TERM_ADV TERM_100 [get_ports mipi_phy_if_2_clk_n]
set_property DIFF_TERM_ADV TERM_100 [get_ports mipi_phy_if_2_data_p[*]]
set_property DIFF_TERM_ADV TERM_100 [get_ports mipi_phy_if_2_data_n[*]]

## MIPI interface 3
#set_property PACKAGE_PIN AG9 [get_ports {mipi_phy_if_3_clk_p}]; # LA31_P
#set_property PACKAGE_PIN AH9 [get_ports {mipi_phy_if_3_clk_n}]; # LA31_N
#set_property PACKAGE_PIN AD7 [get_ports {mipi_phy_if_3_data_p[0]}]; # LA33_P
#set_property PACKAGE_PIN AE7 [get_ports {mipi_phy_if_3_data_n[0]}]; # LA33_N
#set_property PACKAGE_PIN AG6 [get_ports {mipi_phy_if_3_data_p[1]}]; # LA28_P
#set_property PACKAGE_PIN AG5 [get_ports {mipi_phy_if_3_data_n[1]}]; # LA28_N

#set_property IOSTANDARD MIPI_DPHY_DCI [get_ports mipi_phy_if_3_clk_p]
#set_property IOSTANDARD MIPI_DPHY_DCI [get_ports mipi_phy_if_3_clk_n]
#set_property IOSTANDARD MIPI_DPHY_DCI [get_ports mipi_phy_if_3_data_p[*]]
#set_property IOSTANDARD MIPI_DPHY_DCI [get_ports mipi_phy_if_3_data_n[*]]

#set_property DIFF_TERM_ADV TERM_100 [get_ports mipi_phy_if_3_clk_p]
#set_property DIFF_TERM_ADV TERM_100 [get_ports mipi_phy_if_3_clk_n]
#set_property DIFF_TERM_ADV TERM_100 [get_ports mipi_phy_if_3_data_p[*]]
#set_property DIFF_TERM_ADV TERM_100 [get_ports mipi_phy_if_3_data_n[*]]

# These constraints apply to the PYNQ-ZU LPC with M2 M-key Stack FMC
# ------------------------------------------------------------------
# NOTE: The PYNQ-ZU LPC cannot support two M2 slots, because LPC connectors are limited to
#       1x MGT. Consequently, it can only support 1-lane PCIe.
# NOTE2: The FMC GBTCLK0 routes through Si5324 clock multiplier so it must be programmed
#        appropriately or the 100MHz clock will not be available.

# PCI Express reference clock 100MHz
# IOSTANDARD for GT reference clock does not need to be specified
# M2 slot 1 ref clock connects to MGT bank 224, CLK0 input
set_property PACKAGE_PIN Y6 [get_ports {ref_clk_0_clk_p[0]}]
set_property PACKAGE_PIN Y5 [get_ports {ref_clk_0_clk_n[0]}]
create_clock -period 10.000 -name ref_clk_0_clk_p -waveform {0.000 5.000} [get_ports ref_clk_0_clk_p]

# MGT locations
# M2 slot 1 LPC_DP0 (PCIe lane 0) is connected to MGT bank 224 (X0Y4-X0Y7), specifically X0Y7
set_property LOC GTHE4_CHANNEL_X0Y7 [get_cells -hierarchical -filter { PRIMITIVE_TYPE =~ ADVANCED.GT.GTHE4_CHANNEL && NAME =~ "*xdma_0*channel_inst[0]*" }]

# PYNQ-ZU LPC transceiver for M2 slot 1 is best aligned with PCIE_X0Y1
set_property LOC PCIE40E4_X0Y1 [get_cells *_i/xdma_0/inst/pcie4_ip_i/inst/*_pcie_4_0_pipe_inst/pcie_4_0_e4_inst]

# HDMI I2C
set_property PACKAGE_PIN A15 [get_ports HDMI_IIC_scl_io];
set_property PACKAGE_PIN B15 [get_ports HDMI_IIC_sda_io];
set_property IOSTANDARD LVCMOS33 [get_ports HDMI_IIC_*]
set_property SLEW SLOW [get_ports HDMI_IIC_*]
set_property DRIVE 4 [get_ports HDMI_IIC_*]
