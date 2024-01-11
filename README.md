# Reference design combining the Zynq UltraScale+ with the Hailo AI accelerator

## UNDER DEVELOPMENT

This project is still in development and undergoing major changes. The only target design that is currently in a 
buildable state is the `zcu106_hpc0` design. All other designs are early stages and waiting on a new hardware
adapter that we are currently designing.

## Description

This project demonstrates the combined power of the Zynq UltraScale+ and the Hailo AI accelerator
when used in multi-camera vision applications. The repo contains designs for several Zynq UltraScale+
development boards and connects to 4x Raspberry Pi cameras via the Opsero 
[RPi Camera FMC](https://camerafmc.com/docs/rpi-camera-fmc/overview/). The Hailo AI accelerator
connects to the development board via the [FPGA Drive FMC Gen4](https://www.fpgadrive.com/docs/fpga-drive-fmc-gen4/overview/).

![RPi Camera FMC](https://www.fpgadeveloper.com/camera-fmc-connecting-mipi-cameras-to-fpgas/images/rpi-camera-fmc-pynq-zu-1.jpg "RPi Camera FMC")

Important links:
* The RPi Camera FMC [datasheet](https://camerafmc.com/docs/rpi-camera-fmc/overview/)
* To [report an issue](https://github.com/fpgadeveloper/zynqmp-hailo-ai/issues)
* For technical support: [Contact Opsero](https://opsero.com/contact-us)

## Requirements

This project is designed for version 2022.1 of the Xilinx tools (Vivado/Vitis/PetaLinux). 
If you are using an older version of the Xilinx tools, then refer to the 
[release tags](https://github.com/fpgadeveloper/zynqmp-hailo-ai/tags "releases")
to find the version of this repository that matches your version of the tools.

In order to test this design on hardware, you will need the following:

* Vivado 2022.1
* Vitis 2022.1
* PetaLinux Tools 2022.1
* One [Hailo-8 M.2 AI Acceleration Module](https://hailo.ai/products/ai-accelerators/hailo-8-m2-ai-acceleration-module/)
* One or more [Raspberry Pi Camera Module 2](https://www.raspberrypi.com/products/camera-module-v2/) and/or 
  [Digilent Pcam 5C](https://digilent.com/shop/pcam-5c-5-mp-fixed-focus-color-camera-module/) cameras
* One [RPi Camera FMC](https://camerafmc.com/buy/ "RPi Camera FMC")
* One [FPGA Drive FMC Gen4](https://fpgadrive.com/buy/ "FPGA Drive FMC Gen4")
* One DisplayPort monitor that supports 2560 x 1440 resolution video
* One of the supported target boards listed below

### Target boards

* [ZCU104](https://www.xilinx.com/zcu104) (LPC: 4x cameras)
* [ZCU106](https://www.xilinx.com/zcu106) (HPC0: 4x cameras)
* [PYNQ-ZU](https://www.tulembedded.com/FPGA/ProductsPYNQ-ZU.html) (LPC: 4x cameras)
* [Genesys-ZU](https://digilent.com/shop/genesys-zu-zynq-ultrascale-mpsoc-development-board/) (LPC: 4x cameras)
* [UltraZed EV carrier](https://www.xilinx.com/products/boards-and-kits/1-y3n9v1.html) (HPC: 4x cameras)

## Contribute

We strongly encourage community contribution to these projects. Please make a pull request if you
would like to share your work:
* if you've spotted and fixed any issues
* if you've added designs for other target platforms
* if you've added software support for other cameras

Thank you to everyone who supports us!

### The TODO list

* Add Hailo required packages
* Add PCIe constraints to all designs
* Test all designs on hardware

## About us

[Opsero Inc.](https://opsero.com "Opsero Inc.") is a team of FPGA developers delivering FPGA products and 
design services to start-ups and tech companies. Follow our blog, 
[FPGA Developer](https://www.fpgadeveloper.com "FPGA Developer"), for news, tutorials and
updates on the awesome projects we work on.

