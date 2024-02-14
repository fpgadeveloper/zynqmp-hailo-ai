# Requirements

In order to test this design on hardware, you will need the following:

* Vivado 2022.1
* Vitis 2022.1
* PetaLinux Tools 2022.1
* Linux PC or Virtual machine (for build)
* 1x [Hailo-8 M.2 AI Acceleration Module](https://hailo.ai/products/ai-accelerators/hailo-8-m2-ai-acceleration-module/)
* One or more [Raspberry Pi Camera Module 2]
* 1x [RPi Camera FMC]
* 1x [FPGA Drive FMC Gen4] (for `zcu106` target design only)
* 1x [M.2 M-key Stack FMC] (for all other designs)
* One DisplayPort monitor supporting 2K (2560 x 1440) resolution
* Alternatively: HDMI monitor supporting 2K resolution and a DP-to-HDMI adapter
* One of the supported [target boards](supported_carriers)

## Supported cameras

The [RPi Camera FMC] is designed to support all cameras with the standard
[15-pin Raspberry Pi camera interface](https://camerafmc.com/docs/rpi-camera-fmc/detailed-description/#camera-connectors),
however these example designs currently only have the software support for the [Raspberry Pi Camera Module 2].

```{tip} We're working on developing software support for more cameras. If you'd like to help with
this effort, your pull requests are more than welcome.
```

[RPi Camera FMC]: https://camerafmc.com/docs/rpi-camera-fmc/overview/
[Digilent Pcam 5C]: https://digilent.com/shop/pcam-5c-5-mp-fixed-focus-color-camera-module/
[Raspberry Pi Camera Module 2]: https://www.raspberrypi.com/products/camera-module-v2/
[FPGA Drive FMC Gen4]: https://www.fpgadrive.com/docs/fpga-drive-fmc-gen4/overview/
[M.2 M-key Stack FMC]: https://www.fpgadrive.com/docs/m2-mkey-stack-fmc/overview/

