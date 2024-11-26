# Revision History

## 2024.1 Changes

* Removed VVAS multiscaler accelerator from all designs (Xilinx has no support for 2024.1)
* Added AXI4-Streaming Data FIFO to MIPI video pipes, between MIPI CSI2 RX and ISP Pipeline IPs
* Improved documentation, centralized target design info to JSON file
* RPi camera IOs are properly driven
* ISP Pipeline IP updated to version v2023.2_update1 of the Vitis_Libraries repo
* ISP Pipeline now uses built-in Linux driver (linux-xlnx/drivers/media/platform/xilinx/xilinx-isppipeline.c)
* Removed all Vitis-AI and VVAS recipes from BSPs
* Improved example scripts: use max res of connected display, display only connected cameras

## 2022.1 Changes

* First revision

