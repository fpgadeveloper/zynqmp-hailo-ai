# Multi-camera YOLOv5 on the Zynq UltraScale+ and Hailo-8 AI accelerator

## Description

This project demonstrates the combined power of the Zynq UltraScale+ and the Hailo-8 AI accelerator
when used in multi-camera vision applications. The repo contains designs for several Zynq UltraScale+
development boards and connects to 4x Raspberry Pi cameras via the Opsero [RPi Camera FMC][3]. 
The Hailo-8 AI accelerator connects to the development board via the [FPGA Drive FMC Gen4][1]
or the [M.2 M-key Stack FMC][2] depending on the target design (see list of target designs below).

![RPi Camera FMC](https://www.fpgadeveloper.com/camera-fmc-connecting-mipi-cameras-to-fpgas/images/rpi-camera-fmc-pynq-zu-1.jpg "RPi Camera FMC")

Important links:
* The [user guide](https://hailo.camerafmc.com) for these reference designs
* The RPi Camera FMC [datasheet][3]
* The FPGA Drive FMC Gen4 [datasheet][1] (for the `zcu106` target design only)
* The M.2 M-key Stack FMC [datasheet][2]
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
* 1x [Hailo-8 M.2 AI Acceleration Module](https://hailo.ai/products/ai-accelerators/hailo-8-m2-ai-acceleration-module/)
* 4x [Raspberry Pi Camera Module 2](https://www.raspberrypi.com/products/camera-module-v2/)
* 1x [RPi Camera FMC][3]
* 1x [FPGA Drive FMC Gen4][1] (for `zcu106` target design)
* 1x [M.2 M-key Stack FMC][2] (for all other designs)
* 1x DisplayPort monitor that supports 2560 x 1440 resolution video
* Alternatively, 1x HDMI monitor that supports 2560 x 1440 resolution and DP-to-HDMI adapter
* 1x of the supported target boards listed below

### Target designs

| Target board             | Target design | FMC slot | Cameras | M.2 adapter for Hailo | M.2 active slots |
|--------------------------|---------------|----------|---------|-------------|------------------|
| [ZCU104][4]              | `zcu104`      | LPC       | 4 | [M.2 M-key Stack FMC][2] | 1 |
| [ZCU106][5]              | `zcu106`      | HPC0+HPC1 | 4 | [FPGA Drive FMC Gen4][1] | 1 |
| [ZCU106][5]              | `zcu106_hpc0` | HPC0      | 4 | [M.2 M-key Stack FMC][2] | 2 |
| [PYNQ-ZU][6]             | `pynqzu`      | LPC       | 2 | [M.2 M-key Stack FMC][2] | 1 |
| [Genesys-ZU][7]          | `genesyszu`   | LPC       | 2 | [M.2 M-key Stack FMC][2] | 1 |
| [UltraZed EV carrier][8] | `uzev`        | HPC       | 4 | [M.2 M-key Stack FMC][2] | 2 |

Note that the `zcu106` target design uses the [FPGA Drive FMC Gen4][1] as the M.2 adapter for the Hailo-8.
In that design, the [FPGA Drive FMC Gen4][1] connects to HPC1 while the [RPi Camera FMC][3] connects
to the HPC0 connector.

In all other designs, the [M.2 M-key Stack FMC][2] is used as the M.2 adapter for the Hailo-8, with the
[RPi Camera FMC][3] stacked on top of it.

## Build instructions

This repo contains submodules. To clone this repo, run:
```
git clone --recursive https://github.com/fpgadeveloper/zynqmp-hailo-ai.git
```

Source Vivado and PetaLinux tools:

```
source <path-to-petalinux>/2022.1/settings.sh
source <path-to-vivado>/2022.1/settings64.sh
```

Build all (Vivado project, accelerator kernel and PetaLinux):

```
cd zynqmp-hailo-ai/PetaLinux
make petalinux TARGET=uzev
```

Build the Vivado project only:

```
cd zynqmp-hailo-ai/Vivado
make project TARGET=uzev
```

## Contribute

We strongly encourage community contribution to these projects. Please make a pull request if you
would like to share your work:
* if you've spotted and fixed any issues
* if you've added designs for other target platforms
* if you've added software support for other cameras

Thank you to everyone who supports us!

### The TODO list

* Test all M.2 M-key Stack FMC based designs on hardware

## About us

[Opsero Inc.](https://opsero.com "Opsero Inc.") is a team of FPGA developers delivering FPGA products and 
design services to start-ups and tech companies. Follow our blog, 
[FPGA Developer](https://www.fpgadeveloper.com "FPGA Developer"), for news, tutorials and
updates on the awesome projects we work on.

[1]: https://www.fpgadrive.com/docs/fpga-drive-fmc-gen4/overview/
[2]: https://www.fpgadrive.com/docs/m2-mkey-stack-fmc/overview/
[3]: https://camerafmc.com/docs/rpi-camera-fmc/overview/
[4]: https://www.xilinx.com/zcu104
[5]: https://www.xilinx.com/zcu106
[6]: https://www.tulembedded.com/FPGA/ProductsPYNQ-ZU.html
[7]: https://digilent.com/shop/genesys-zu-zynq-ultrascale-mpsoc-development-board/
[8]: https://www.xilinx.com/products/boards-and-kits/1-y3n9v1.html

