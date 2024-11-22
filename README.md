# Multi-camera YOLOv5 on the Zynq UltraScale+ and Hailo-8 AI accelerator

## Description

This project demonstrates the combined power of the Zynq UltraScale+ and the Hailo-8 AI accelerator
when used in multi-camera vision applications. The repo contains designs for several Zynq UltraScale+
development boards and connects to 4x Raspberry Pi cameras via the Opsero [RPi Camera FMC]. 
The Hailo-8 AI accelerator connects to the development board via the [FPGA Drive FMC Gen4]
or the [M.2 M-key Stack FMC] depending on the target design (see list of target designs below).

A detailed description of this design and how to use it was written up in this blog post:
[Multi-camera YOLOv5 on Zynq UltraScale+ with Hailo-8 AI Acceleration](https://www.fpgadeveloper.com/multi-camera-yolov5-on-zynq-ultrascale-with-hailo-8-ai-acceleration/)

![Multi-camera YOLOv5 on ZynqMP and Hailo-8](https://www.fpgadeveloper.com/multi-camera-yolov5-on-zynq-ultrascale-with-hailo-8-ai-acceleration/images/zynqmp-hailo-ai-front.jpg "Multi-camera YOLOv5 on ZynqMP and Hailo-8")

Important links:
* The [user guide](https://hailo.camerafmc.com) for these reference designs
* Datasheet of the [RPi Camera FMC]
* Datasheet of the [FPGA Drive FMC Gen4] (for the `zcu106` target design only)
* Datasheet of the [M.2 M-key Stack FMC]
* To [report an issue](https://github.com/fpgadeveloper/zynqmp-hailo-ai/issues)
* For technical support: [Contact Opsero](https://opsero.com/contact-us)

## Requirements

This project is designed for version 2022.1 of the Xilinx tools (Vivado/Vitis/PetaLinux). 
If you are using an older version of the Xilinx tools, then refer to the 
[release tags](https://github.com/fpgadeveloper/zynqmp-hailo-ai/tags "releases")
to find the version of this repository that matches your version of the tools.

In order to test this design on hardware, you will need the following:

* Vivado 2024.1
* Vitis 2024.1
* PetaLinux Tools 2024.1
* 1x [Hailo-8 M.2 AI Acceleration Module]
* 4x [Raspberry Pi Camera Module 2](https://www.raspberrypi.com/products/camera-module-v2/)
* 1x [RPi Camera FMC]
* 1x [FPGA Drive FMC Gen4] (for `zcu106` target design)
* 1x [M.2 M-key Stack FMC] (for all other designs)
* 1x DisplayPort monitor that supports 2560 x 1440 resolution video
* Alternatively, 1x HDMI monitor that supports 2560 x 1440 resolution and DP-to-HDMI adapter
* 1x of the supported target boards listed below

## Target designs

Note that there are two target designs for the [ZCU106] board: `zcu106` and `zcu106_hpc0`, and the
differences are explained in the table below.
All target designs except `zcu106` require the [M.2 M-key Stack FMC] as the M.2 adapter for the Hailo-8, with the
[RPi Camera FMC] stacked on top of it.

<!-- updater start -->
### Zynq UltraScale+ designs

| Target board          | Target design   | FMC Slot(s) | Cameras | Active M.2 Slots | VCU   | Accelerator | Stack Design | Vivado<br> Edition |
|-----------------------|-----------------|-------------|---------|------------------|-------|-------------|--------------|-------|
| [ZCU104]              | `zcu104`        | LPC         | 4     | 1     | :white_check_mark: | :x:                | :white_check_mark: | Standard :free: |
| [ZCU106]              | `zcu106`        | HPC0+HPC1   | 4     | 1     | :white_check_mark: | :x:                | :x:                | Standard :free: |
| [ZCU106]              | `zcu106_hpc0`   | HPC0        | 4     | 2     | :white_check_mark: | :x:                | :white_check_mark: | Standard :free: |
| [PYNQ-ZU]             | `pynqzu`        | LPC         | 2     | 1     | :x:                | :x:                | :white_check_mark: | Standard :free: |
| [UltraZed-EV Carrier] | `uzev`          | HPC         | 4     | 2     | :white_check_mark: | :x:                | :white_check_mark: | Standard :free: |

[ZCU104]: https://www.xilinx.com/zcu104
[ZCU106]: https://www.xilinx.com/zcu106
[PYNQ-ZU]: https://www.tulembedded.com/FPGA/ProductsPYNQ-ZU.html
[UltraZed-EV Carrier]: https://www.xilinx.com/products/boards-and-kits/1-1s78dxb.html
<!-- updater end -->

#### Notes:
1. The Vivado Edition column indicates which designs are supported by the Vivado *Standard* Edition, the
   FREE edition which can be used without a license. Vivado *Enterprise* Edition requires
   a license however a 30-day evaluation license is available from the AMD Xilinx Licensing site.
2. The Stack Designs use the [M.2 M-key Stack FMC] with the [RPi Camera FMC] stacked on top of it. The non-stack
   designs use the [FPGA Drive FMC Gen4] on one FMC connector, and the [RPi Camera FMC] on another.
3. The `zcu106` target design uses the [FPGA Drive FMC Gen4] as the M.2 adapter for the Hailo-8.
   In that design, the [FPGA Drive FMC Gen4] connects to HPC1 while the [RPi Camera FMC] connects
   to the HPC0 connector.
4. The `pynqzu` target design has video pipelines for only 2 cameras (CAM1 and CAM2 as
   labelled on the RPi Camera FMC). This is due to the resource limitations of the devices on these boards.
5. The `zcu106_hpc0` and `uzev` target designs have support for 2x M.2 modules. To use the Hailo demo scripts,
   at least one of these modules must be the [Hailo-8 M.2 AI Acceleration Module]. The second slot can be used
   for a second Hailo module, or an NVMe SSD for storage.

## Build instructions

This repo contains submodules. To clone this repo, run:
```
git clone --recursive https://github.com/fpgadeveloper/zynqmp-hailo-ai.git
```

Source Vivado and PetaLinux tools:

```
source <path-to-petalinux>/2024.1/settings.sh
source <path-to-vivado>/2024.1/settings64.sh
```

Build all (Vivado project, accelerator kernel and PetaLinux):

```
cd zynqmp-hailo-ai/PetaLinux
make petalinux TARGET=uzev
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
* Add 2x camera script for PYNQ-ZU board
* Add some demo scripts for VVAS and VCU

## About us

[Opsero Inc.](https://opsero.com "Opsero Inc.") is a team of FPGA developers delivering FPGA products and 
design services to start-ups and tech companies. Follow our blog, 
[FPGA Developer](https://www.fpgadeveloper.com "FPGA Developer"), for news, tutorials and
updates on the awesome projects we work on.

[FPGA Drive FMC Gen4]: https://www.fpgadrive.com/docs/fpga-drive-fmc-gen4/overview/
[M.2 M-key Stack FMC]: https://www.fpgadrive.com/docs/m2-mkey-stack-fmc/overview/
[RPi Camera FMC]: https://camerafmc.com/docs/rpi-camera-fmc/overview/
[Hailo-8 M.2 AI Acceleration Module]: https://hailo.ai/products/ai-accelerators/hailo-8-m2-ai-acceleration-module/

